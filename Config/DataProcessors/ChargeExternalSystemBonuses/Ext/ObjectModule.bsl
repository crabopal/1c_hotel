
#Region Public

// -----------------------------------------------------------------------------
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

// -----------------------------------------------------------------------------
// Initialize attributes with default values
// Attention: This procedure could be called AFTER some attributes initialization
// routine, so it SHOULD NOT reset attributes being set before
// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// NOTHING SO FAR
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	#If Client Then
		OpenForm("DataProcessor.ChargeExternalSystemBonuses.Form",New Structure("DataProcessor",ThisObject.DataProcessor));
	#Else
		Sync();	
	#EndIf
EndProcedure // pmRun

// -----------------------------------------------------------------------------
Procedure Sync() Export
	If Not (ValueIsFilled(Hotel) and ValueIsFilled(DiscountType) And ValueIsFilled(HotelBIToken) and ValueIsFilled(HotelBIBaseName) And ValueIsFilled(HotelBIHost)) Then
		WriteLogEvent("CalculateBonuses", EventLogLevel.Error,,CurrentSessionDate(), "Not all settings are filled! Cant sync bonuses!");
		Return;
	EndIf;
	vDocs 	= GetDocumentsToSync(Hotel, DiscountType);
	vResult = SyncDocuments(Hotel, vDocs, HotelBIToken, HotelBIHost, HotelBIBaseName);
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function GetDocumentsToSync(pHotel, pDiscountType)
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
        |   InputAccumulatingDiscountBalancesBalances.Ref AS Ref,
        |   InputAccumulatingDiscountBalancesBalances.Ref.ExternalCode AS ExternalCode,
        |   InputAccumulatingDiscountBalancesBalances.DiscountDimension AS DiscountDimension,
        |   InputAccumulatingDiscountBalancesBalances.Bonus AS Bonus,
        |   InputAccumulatingDiscountBalancesBalances.Ref.Author AS Author,
        |   InputAccumulatingDiscountBalancesBalances.Ref.ChangeAuthor AS ChangeAuthor,
        |   InputAccumulatingDiscountBalancesBalances.Ref.Remarks AS Remarks,
        |   InputAccumulatingDiscountBalancesBalances.Ref.Date AS Date
        |FROM
        |   Document.InputAccumulatingDiscountBalances.Balances AS InputAccumulatingDiscountBalancesBalances
        |WHERE
        |   NOT InputAccumulatingDiscountBalancesBalances.Ref.DeletionMark
        |   AND InputAccumulatingDiscountBalancesBalances.Ref.Hotel = &qHotel
        |   AND InputAccumulatingDiscountBalancesBalances.Ref.DiscountType = &qDiscountType
        |   AND InputAccumulatingDiscountBalancesBalances.Ref.IsChanged";
	
	vQuery.SetParameter("qDiscountType", pDiscountType);
	vQuery.SetParameter("qHotel", pHotel);
	
	vQueryResult = vQuery.Execute().Unload();
	Return vQueryResult;
EndFunction

// -----------------------------------------------------------------------------
Function SyncDocuments(pHotel, pDocuments, pToken, pHotelBIHost, pHotelBIBaseName)
	vResult = New ValueTable;
	vResult.Columns.Add("Success");
	vResult.Columns.Add("Errors");
	vResult.Columns.Add("InputAccumulatingDiscountBalancesBalancesRef");
	vResult.Columns.Add("BonusesOperationID");
	For Each vDoc in pDocuments Do
		vSuccess 			= True;
		vErrors				= New Array;
		vBonusesOperationID = Undefined;
		If TypeOf(vDoc.DiscountDimension) = Type("CatalogRef.Clients") OR TypeOf(vDoc.DiscountDimension) = Type("CatalogRef.Customers") Then
			vRequest 	= GenerateJSONRequest(pHotel, vDoc, pToken);
			vResponse 	= SendQuery(vRequest, pHotelBIHost, pHotelBIBaseName + "/hs/bonuses/AddBonuses", pHotelBIHost + "/" + pHotelBIBaseName + "/hs/bonuses/AddBonuses");
			If vResponse <> Undefined Then
				vJSON = New JSONReader;
				vJSON.SetString(vResponse);
				Try
					vTable = ReadJSON(vJSON);
				Except
					vSuccess = False;
					vErrors.Add("Cant read request body as JSON");
				EndTry;
				
				If vSuccess And vTable <> Undefined And TypeOf(vTable) = Type("Structure") Then
					If Not vTable.Property("Success") Then
						vSuccess = False;
						vErrors.Add("Not correct response! Missing ""Success"" parameter!");
					Else
						vSuccess = vTable.Success;	
					EndIf;
					If Not vTable.Property("Amount") Then
						vSuccess = False;
						vErrors.Add("Not correct response! Missing ""Amount"" parameter!");
					EndIf;
					If Not vTable.Property("DocumentID") Then
						vSuccess = False;
						vErrors.Add("Not correct response! Missing ""DocumentID"" parameter!");
					Else
						vBonusesOperationID = vTable.DocumentID; 
					EndIf;
					If Not vTable.Property("Errors") Then
						vSuccess = False;
						vErrors.Add("Not correct response! Missing ""Errors"" parameter!");
					Else
						For Each vErrorRow In vTable.Errors Do
							vErrors.Add(vErrorRow);
						EndDo;
					EndIf;
				EndIf;
			Else
				vSuccess = False;
				vErrors.Add("Request body is empty!");
			EndIf;
		Else
			vSuccess = False;
			vErrors.Add("DiscountDimension isn't client or customer ref!");	
		EndIf;
		If vSuccess = True Then
			If Not ValueIsFilled(vBonusesOperationID) Then
				vSuccess = False;
				vErrors.Add("BonusesOperationID is empty!");
			EndIf;	
		EndIf;
		If vSuccess = True Then
			Try
				vDocObj 				= vDoc.Ref.GetObject();
				vDocObj.IsChanged 		= False;
				vDocObj.ExternalCode 	= vBonusesOperationID;
				vDocObj.Write(DocumentWriteMode.Posting);
			Except
				vSuccess 	= False;
				vError		= ErrorDescription();
				vErrors.Add(vError);
			EndTry;
		EndIf;
		vNewRow 		= vResult.Add();
		vNewRow.Success = vSuccess;
		vNewRow.Errors 	= vErrors;
		vNewRow.InputAccumulatingDiscountBalancesBalancesRef = vDoc.Ref;
		vNewRow.BonusesOperationID = vBonusesOperationID;
		

		For Each vErrorRow In vErrors Do
			WriteLogEvent("ChargeExternalSystemBonuses_SyncDocuments", EventLogLevel.Error, , CurrentSessionDate(), String(vDoc.Ref) + "; " + vErrorRow);
		EndDo;
	EndDo;  
	Return vResult;
EndFunction

// -----------------------------------------------------------------------------
Function GenerateJSONRequest(pHotel, pDoc, pToken)
	vAuthor = "";
	If ValueIsFilled(pDoc.ChangeAuthor) Then
		vAuthor = pDoc.ChangeAuthor.Description;
	Else
		vAuthor = pDoc.Author.Description;
	EndIf;

	vGuest = "";
	vGuestID = "";
	If TypeOf(pDoc.DiscountDimension) = Type("CatalogRef.Clients") Then
		vGuest = pDoc.DiscountDimension.FullName;
		vGuestID = pDoc.DiscountDimension.Code;
	ElsIf TypeOf(pDoc.DiscountDimension) = Type("CatalogRef.Customers") Then
		If pDoc.DiscountDimension.IsIndividual And ValueIsFilled(pDoc.DiscountDimension.Client) Then 
			vGuest = pDoc.DiscountDimension.Client.FullName;
			vGuestID = pDoc.DiscountDimension.Client.Code;
		ElsIf pDoc.DiscountDimension.IsIndividual Then 
			vGuest = pDoc.DiscountDimension.Description;
			vGuestID = pDoc.DiscountDimension.Code;	
		Else	
			vGuest = pDoc.DiscountDimension.LegacyName;
		EndIf;
	EndIf;
	
	vGuestGroup = "";
	If pDoc.Ref.Balances.Count() > 0 Then
		vGuestGroup = XMLString(pDoc.Ref.Balances[0].GuestGroup.Code);
	EndIf;	
    
    vParams = New Structure;
    vParams.Insert("Source", pHotel.Description);
    vParams.Insert("Token", XMLString(pToken));
    vParams.Insert("Card", XMLString(pDoc.DiscountDimension.Phone));
    vParams.Insert("Amount", XMLString(pDoc.Bonus));
    vParams.Insert("Room", "");
    vParams.Insert("GuestGroup", XMLString(vGuestGroup));
    vParams.Insert("Guest", XMLString(vGuest));
    vParams.Insert("GuestID", XMLString(vGuestID));
    vParams.Insert("DocumentDate", pDoc.Date);
    vParams.Insert("DocumentID", XMLString(pDoc.ExternalCode));
    vParams.Insert("CreateDiscountCards", XMLString(CreateDiscountCards));
    vParams.Insert("Remarks", XMLString(pDoc.Remarks));
    vParams.Insert("Author", XMLString(vAuthor));
    
    vJSONText = Catalogs.DataConvertationRules.MapToJSON(vParams);              
   	
	Return vJSONText; 
EndFunction

Function SendQuery(pJSON, pHTTPHost, pResourceAddress, pSOAPAction)
	Try
		// HTTP
		vHTTPHeader = New Map;
		vHTTPHeader.Insert("Content-Type", "application/json;charset=utf-8");
		vHTTPHeader.Insert("POST", pSOAPAction);
		vHTTPHeader.Insert("Host", pHTTPHost);
		
		// HTTP connection
		If IsBlankString(UserBIHost) Then 
			vHTTPConnection = New HTTPConnection(pHTTPHost);
		Else
			vHTTPConnection = New HTTPConnection(pHTTPHost, , UserBIHost,PasswordBIHost);
		EndIf;
		// Send query
		vHTTPRequest = New HTTPRequest(pResourceAddress,vHTTPHeader);
		vHTTPRequest.SetBodyFromString(pJSON);
		rs = vHTTPConnection.Post(vHTTPRequest);
		vHTTPConnection = Undefined;
		Return rs.GetBodyAsString();
	Except
		vError = ErrorDescription();
		WriteLogEvent("ChargeExternalSystemBonuses_SendQuery", EventLogLevel.Error, , CurrentSessionDate(), "Failed to send post query to the HotelBI! " + vError);
		Return vError;
	EndTry;
	
	Return Undefined;	
EndFunction // Hotel365_SendQuery

#EndRegion
