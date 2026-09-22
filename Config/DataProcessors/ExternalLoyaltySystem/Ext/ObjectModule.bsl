// -----------------------------------------------------------------------------
// Data processors framework start
// -----------------------------------------------------------------------------

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
Function GetCardBalance(pIdentifier, pDocument, pExternalCardBalance, pExternalCardTotalBalance) Export
	If ExternalInteraction.DebugMode Then
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, "GetCardBalance", Enums.ExternalSystemEventTypes.Info, ,, "Start"); 
	EndIf;

	vParam = New Structure;
	vParam.Insert("Token", ExternalInteraction.InteractionID);
	vParam.Insert("Card", TrimAll(pIdentifier));
	
	vJson = Catalogs.DataConvertationRules.MapToJSON(vParam);
	
	vResponse = SendQuery(vJson, "GetBonusesAmount");
	
	If TypeOf(vResponse) = Type("Structure") Then
		vResponse.Insert("DiscountType", DiscountType);
		If vResponse.Success Then 
			pDocument.DiscountCard = GetCardByIdentifier(pIdentifier, DiscountType);
			pExternalCardBalance = vResponse.Amount;
		EndIf;
		Return vResponse;
	Else
		Raise vResponse;
	EndIf;	
EndFunction //  GetCardBalance()

// -----------------------------------------------------------------------------
Function StartExternalPayment(pDocument) Export
	If ExternalInteraction.DebugMode Then
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, "StartBonusesPayment", Enums.ExternalSystemEventTypes.Info, ,, "Start"); 
	EndIf;
	
	vParam = New Structure;
	
	vParam.Insert("Token", ExternalInteraction.InteractionID);
	vParam.Insert("Card", pDocument.DiscountCard.Identifier);
	vParam.Insert("Amount", pDocument.Sum);
	vParam.Insert("Author", SessionParameters.CurrentUser);
	vParam.Insert("Room", pDocument.Folio.Room);
	vParam.Insert("GuestGroup", pDocument.GuestGroup);
	vParam.Insert("Guest", TrimAll(pDocument.Payer));
	vParam.Insert("Remarks", pDocument.Remarks);
	
	vJson = Catalogs.DataConvertationRules.MapToJSON(vParam);
	
	vResponse = SendQuery(vJson, "StartBonusesPayment");
	
	If TypeOf(vResponse) = Type("Structure") Then
		If vResponse.Success Then
			pDocument.ExternalCode = vResponse.TransactionID;	
		EndIf;
		Return vResponse;
	Else
		Raise vResponse;
	EndIf;	
EndFunction //  StartExternalPayment()

// -----------------------------------------------------------------------------
Function FinishExternalPayment(pAuthorizationCode, pDocument, pDocumentRef, pSkipAuthorization) Export
	If ExternalInteraction.DebugMode Then
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, "FinishBonusesPayment", Enums.ExternalSystemEventTypes.Info, ,, "Start"); 
	EndIf;
	
	vParam = New Structure;
	
	vParam.Insert("Token", ExternalInteraction.InteractionID);
	vParam.Insert("TransactionID", pDocument.ExternalCode);
	vParam.Insert("AuthorizationCode", pAuthorizationCode);
	
	vJson = Catalogs.DataConvertationRules.MapToJSON(vParam);
	
	vResponse = SendQuery(vJson, "FinishBonusesPayment");
	
	If TypeOf(vResponse) = Type("Structure") Then
		Return vResponse;
	Else
		Raise vResponse;
	EndIf;	
EndFunction //  FinishExternalPayment()

// -----------------------------------------------------------------------------
Function ReturnExternalPayment(pDocument, pDocumentRef) Export
	Return New Structure("Success", True);	
EndFunction //  ReturnExternalPayment

// -----------------------------------------------------------------------------
Function SendQuery(pJSON, pType)
	vHTTPServer = TrimAll(ExternalInteraction.HTTPServer);
	vPort		= ExternalInteraction.HttpPort;
	vHTTPUser 	= TrimAll(ExternalInteraction.Login);
	vHTTPPwd 	= TrimAll(ExternalInteraction.Password);
	vUseSSL 	= ExternalInteraction.HTTPUseSSL;
	vBaseName   = TrimAll(ExternalInteraction.HttpAddress);
	vHttpAddress = vBaseName + "/hs/bonuses/" + TrimAll(pType);
	Try
		//HTTP
		vHTTPHeader = New Map;
		vHTTPHeader.Insert("Content-Type", "application/json;charset=utf-8");
		vHTTPHeader.Insert("POST", vHTTPServer + "/" + vHttpAddress);
		vHTTPHeader.Insert("Host", vHTTPServer);
		
		// HTTP connection
		vSSL = Undefined;
		If vUseSSL Then
			vSSL = New OpenSSLSecureConnection(Undefined, Undefined);       	
		EndIf;
		vHTTPConnection = New HTTPConnection(vHTTPServer, ?(vPort = 0, Undefined, vPort), vHTTPUser, vHTTPPwd, , , vSSL);
		
		//Send query
		vHTTPRequest = New HTTPRequest(vHttpAddress, vHTTPHeader);
		vHTTPRequest.SetBodyFromString(pJSON);
		vRS = vHTTPConnection.Post(vHTTPRequest);
		vRSString = vRS.GetBodyAsString();
		If ExternalInteraction.DebugMode Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, pType, Enums.ExternalSystemEventTypes.Info, pJSON, vRSString, "End", 9999999); 
		EndIf;

		Return Catalogs.DataConvertationRules.JSONtoStructure(vRSString);
	Except
		vError = ErrorDescription();
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, pType+".SendQuery", Enums.ExternalSystemEventTypes.Error, pJSON,"","Failed to send post query! " + vError, 9999999); 
		Return vError;
	EndTry;
	
	Return Undefined;	
EndFunction // Hotel365_SendQuery

// -----------------------------------------------------------------------------
Function GetCardByIdentifier(pIdentifier, pDiscountType)
	vCard = Undefined;
	vCards = Catalogs.DiscountCards.GetActiveBonusesCards(pIdentifier);
	For Each vRow In vCards Do
		If vRow.Ref.DiscountType = pDiscountType Then
			vCard = vRow.Ref;
			Break;
		EndIf;	
	EndDo; 
	// Issue card
	If vCard = Undefined Then
		vDCObj = Catalogs.DiscountCards.CreateItem();
		vDCObj.DiscountType = pDiscountType;
		vDCObj.LoyaltyType = vDCObj.DiscountType.LoyaltyType;
		If vDCObj.DiscountType.Validity > 0 Then
			vDCObj.ValidFrom = BegOfDay(CurrentSessionDate());
			vDCObj.ValidTo = vDCObj.ValidFrom + vDCObj.DiscountType.Validity * 86400;
		EndIf;
		vDCObj.CreateHotel = ExternalInteraction.Hotel;
		vDCObj.Description = pIdentifier;
		vDCObj.Identifier = pIdentifier;
		vDCObj.Remarks = "Created from external loyalty system";
		// Save discount card
		vDCObj.Write();
		vCard = vDCObj.Ref;
	ElsIf vCard.Identifier <> pIdentifier Then
		vDCObj = vCard.GetObject();
		vDCObj.Description = pIdentifier;
		vDCObj.Write();
	EndIf;	
	Return vCard;
EndFunction // GetCardByIdentifier

// -----------------------------------------------------------------------------
Procedure GetBonusesTransactions(pDiscountCard, pAddressStorage) Export	
	PutToTempStorage(New Structure("Balance, Transactions", 0, NewPropertiesForBonusesTransactions()), pAddressStorage);
EndProcedure //  GetBonusesTransactions

// -----------------------------------------------------------------------------
Function NewPropertiesForBonusesTransactions()	
	
	vNewTable = New ValueTable();
	vNewTable.Columns.Add("Date",				New TypeDescription("Date"));
	vNewTable.Columns.Add("Status",				New TypeDescription("String"));
	vNewTable.Columns.Add("Operation",			New TypeDescription("String"));
	vNewTable.Columns.Add("SalePoint",			New TypeDescription("String"));
	vNewTable.Columns.Add("Author",				New TypeDescription("String"));
	vNewTable.Columns.Add("PurchaseAmount",		New TypeDescription("Number"));
	vNewTable.Columns.Add("PaymentAmount",		New TypeDescription("Number"));
	vNewTable.Columns.Add("BonusesSum",			New TypeDescription("Number"));
	vNewTable.Columns.Add("BonusAccumulated",	New TypeDescription("Number"));
	vNewTable.Columns.Add("BonusPresent",		New TypeDescription("Number"));
	vNewTable.Columns.Add("BonusAction",		New TypeDescription("Number"));
	
	Return vNewTable;
EndFunction // NewPropertiesForBonusesTransactions