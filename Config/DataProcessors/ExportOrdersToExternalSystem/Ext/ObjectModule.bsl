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
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	WriteLogEvent("DataProcessors.ExportOrdersToExternalSystem.StartSync", EventLogLevel.Information);
	#IF CLIENT THEN
		OpenForm("DataProcessor.ExportOrdersToExternalSystem.Form", New Structure("DataProcessor", ThisObject.DataProcessor));
	#ELSE
		Sync();	
	#ENDIF
EndProcedure // pmRun

// -----------------------------------------------------------------------------
// Data processors framework end
// -----------------------------------------------------------------------------

Procedure Sync() Export
	vStartDate = CurrentDate();
	If NOT ValueIsFilled(ExternalInteraction) Then
		vMsg = Nstr("en = 'It is necessary to fill the interaction system'; de = 'Es ist notwendig, das Interaktionssystem zu füllen'; ru = 'Необходимо заполнить систему взаимодействия'");
		WriteLogEvent("DataProcessors.ExportOrdersToExternalSystem.Sync", EventLogLevel.Error,,, vMsg);
		Raise vMsg;
	EndIf;
	If Not ExternalInteraction.IsActive Then
		vMsg = Nstr("en = 'Interaction system is off, synchronization failed'; de = 'Interaktionssystem ist ausgeschaltet, Synchronisation fehlgeschlagen'; ru = 'Cистема взаимодействия выключена, синхронизация не выполнена'");
		WriteLogEvent("DataProcessors.ExportOrdersToExternalSystem.Sync", EventLogLevel.Error,,, vMsg);
		Raise vMsg;
	EndIf;
	
	vDocs 	= GetDocumentsToSync();
	vResult = SyncDocuments(vDocs);
	
	//Update interaction state
	vFilter = vResult.FindRows(New Structure("Success",False));
	vExternalInteractionObj = ExternalInteraction.GetObject();
	If vFilter.Count() = 0 Then
		vExternalInteractionObj = ExternalInteraction.GetObject();
		vExternalInteractionObj.LastFullSynchronizationTime = vStartDate;
		vExternalInteractionObj.Status = Enums.IntegrationStatuses.Success;
		vExternalInteractionObj.ErrorDescription = "";
		vExternalInteractionObj.Write();
	Else
		//Save error to the interaction object
		vExternalInteractionObj = ExternalInteraction.GetObject();
		vExternalInteractionObj.Status = Enums.IntegrationStatuses.Warning;
		vExternalInteractionObj.ErrorDescription = "";
		vExternalInteractionObj.Write();
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
Function GetDocumentsToSync()
	vDateFrom = ExternalInteraction.LastFullSynchronizationTime;
	If Not ValueIsFilled(vDateFrom) Then
		vDateFrom = BegOfDay(CurrentSessionDate());
	EndIf;	

	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	OrderStatusHistory.Order.Ref AS Order,
		|	ISNULL(ExternalOrderCodes.ExternalOrderCode, """") AS ExternalOrderCode
		|FROM
		|	InformationRegister.OrderStatusHistory AS OrderStatusHistory
		|		LEFT JOIN InformationRegister.ExternalOrderCodes AS ExternalOrderCodes
		|		ON OrderStatusHistory.Order = ExternalOrderCodes.Order
		|			AND (ExternalOrderCodes.ExternalSystemCode = &qExternalSystemCode)
		|WHERE
		|	OrderStatusHistory.Date >= &qDateFrom
		|	AND CASE
		|			WHEN &qHotelIsEmpty
		|				THEN TRUE
		|			ELSE OrderStatusHistory.Order.Hotel = &qHotel
		|					OR OrderStatusHistory.Order.Hotel = VALUE(Catalog.Hotels.EmptyRef)
		|		END
		|	AND CASE
		|			WHEN &qDoNotUseOrderTime
		|				THEN TRUE
		|			ELSE CASE
		|						WHEN &qActiveDaysIsEmpty
		|							THEN TRUE
		|						ELSE OrderStatusHistory.Order.OrderTime <= &qDateTo
		|					END
		|					AND OrderStatusHistory.Order.OrderTime >= &qCurDate
		|		END
		|	AND CASE
		|			WHEN &qOrderTypeIsEmpty
		|				THEN TRUE
		|			ELSE OrderStatusHistory.Order.Type = &qOrderType
		|		END
		|	AND OrderStatusHistory.Status <> &qSkipStatus
		|	AND NOT(OrderStatusHistory.Status.isOrderCancel
		|				AND ExternalOrderCodes.ExternalOrderCode = """")
		|	AND NOT OrderStatusHistory.Order.ParentDoc.Number IS NULL
		|
		|GROUP BY
		|	OrderStatusHistory.Order.Ref,
		|	ISNULL(ExternalOrderCodes.ExternalOrderCode, """")";
	
	vQuery.SetParameter("qDateFrom", vDateFrom);
	vQuery.SetParameter("qDateTo", EndOfDay(BegOfDay(CurrentSessionDate()) + ExternalInteraction.ActiveDays*86400));
	vQuery.SetParameter("qActiveDaysIsEmpty", Not ValueIsFilled(ExternalInteraction.ActiveDays));
	vQuery.SetParameter("qOrderType", OrderType);
	vQuery.SetParameter("qOrderTypeIsEmpty",  Not ValueIsFilled(OrderType));
	vQuery.SetParameter("qCurDate", BegOfDay(CurrentSessionDate()));
	vQuery.SetParameter("qHotel", ExternalInteraction.Hotel);
	vQuery.SetParameter("qSkipStatus", SkipStatus);
	vQuery.SetParameter("qHotelIsEmpty", NOt ValueIsFilled(ExternalInteraction.Hotel));
	vQuery.SetParameter("qExternalSystemCode", ExternalInteraction.InteractionID);
	vQuery.SetParameter("qDoNotUseOrderTime", DoNotUseOrderTime);

	vQueryResult = vQuery.Execute().Unload();
	Return vQueryResult;
EndFunction

// -----------------------------------------------------------------------------
Function SyncDocuments(pDocuments)
	vResult = New ValueTable;
	vResult.Columns.Add("Success");
	vResult.Columns.Add("Errors");
	vResult.Columns.Add("Order");
	vResult.Columns.Add("ExternalOrderID");
	For each vDoc in pDocuments Do
		vSuccess 			= True;
		vErrors				= New Array;
		vRequest 	= GenerateJSONRequest(vDoc.Order, vDoc.ExternalOrderCode);
		vResponse 	= SendQuery(vRequest);
		
		If ExternalInteraction.DebugMode Then 
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, "SyncDocuments", Enums.ExternalSystemEventTypes.Warning, vRequest, vResponse,""); 
		EndIf;
			
		If vResponse <> Undefined Then
			vJSON = new JSONReader;
			vJSON.SetString(vResponse);
			Try
				vTable = ReadJSON(vJSON);
			Except
				vSuccess = False;
				vErrors.Add("Cant read request body as JSON");
			EndTry;
			
			If vSuccess and vTable <> Undefined and TypeOf(vTable) = Type("Structure") Then
				If NOT vTable.Property("Success") Then
					vSuccess = False;
					vErrors.Add("Not correct response! Missing ""Success"" parameter!");
				Else
					vSuccess = vTable.Success;	
				EndIf;
				If NOT vTable.Property("DocumentID") Then
					vSuccess = False;
					vErrors.Add("Not correct response! Missing ""DocumentID"" parameter!");
				Else
					vExternalOrderID = vTable.DocumentID; 
				EndIf;
				If NOT vTable.Property("Errors") Then
					vSuccess = False;
					vErrors.Add("Not correct response! Missing ""Errors"" parameter!");
				Else
					For each vErrorRow in vTable.Errors Do
						vErrors.Add(vErrorRow);
					EndDo;
				EndIf;
			EndIf;
		Else
			vSuccess = False;
			vErrors.Add("Request body is empty!");
		EndIf;
		If vSuccess = True Then
			If NOT ValueIsFilled(vExternalOrderID) Then
				vSuccess = False;
				vErrors.Add("DocumentID is empty!");
			EndIf;	
		EndIf;
		If vSuccess = True Then
			// Save mapping
			Try
				If ValueIsFilled(StatusAfterUnloading) And vDoc.Order.Status = Catalogs.OrderStatuses.New Then
					Documents.Order.SetStatus(vDoc.Order, StatusAfterUnloading);
				EndIf;	
				Orders.SaveCodeMapping(ExternalInteraction.InteractionID, vExternalOrderID, vDoc.Order); 
			Except
				vSuccess 	= False;
				vError		= ErrorDescription();
				vErrors.Add(vError);
			EndTry;
		Else
			If ValueIsFilled(StatusErrorUnloading) And vDoc.Order.Status = Catalogs.OrderStatuses.New Then
				Documents.Order.SetStatus(vDoc.Order, StatusErrorUnloading);
			EndIf;
		EndIf;
		vNewRow 		= vResult.Add();
		vNewRow.Success = vSuccess;
		vNewRow.Errors 	= vErrors;
		vNewRow.Order = vDoc.Order;
		vNewRow.ExternalOrderID = vExternalOrderID;
		For each vErrorRow in vErrors Do
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, "SyncDocuments", Enums.ExternalSystemEventTypes.Error, vRequest,vResponse, String(vDoc.Order) + "; " + vErrorRow); 
		EndDo;
	EndDo;
	Return vResult;
EndFunction

// -----------------------------------------------------------------------------
Function GenerateJSONRequest(pDoc, pExternalOrderCode)
	#Region FillVariables
	
	vInteractionID = ExternalInteraction.InteractionID;
	
	vGuest = "";
	vGuestID = "";
	If ValueIsFilled(pDoc.Client) Then
		vGuest = pDoc.Client.FullName;	
		vGuestID = TrimAll(pDoc.Client.Code);
	EndIf;
	
	vParentDoc = pDoc.ParentDoc;
	
	//Period of stay
	vCheckInDate  		= Date(1,1,1);
	vCheckOutDate  		= Date(1,1,1);
	If ValueIsFilled(vParentDoc) And (TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vParentDoc) = Type("DocumentRef.Reservation")) Then
		vCheckInDate  		=  vParentDoc.CheckInDate;
		vCheckOutDate  		=  vParentDoc.CheckOutDate;
	EndIf;	
	
	vHotel 				= pDoc.Hotel;
	vHotelDescription 	= "";
	vHotelExtCode 		= "";
	vCompanyDescription = "";
	vCompanyExtCode 	= "";
	
	If ValueIsFilled(vHotel) Then
		//Hotel
		vHotelDescription = vHotel.Description;
		vHotelExtCode = cmGetObjectExternalSystemCodeByRef(vHotel, vInteractionID, "Hotels", vHotel, True);
		//Company
		vCompanyDescription = vHotel.Company.LegacyName;
		vCompanyExtCode = cmGetObjectExternalSystemCodeByRef(vHotel, vInteractionID, "Companies", vHotel.Company, True);
	EndIf;	
	
	vAuthor = "";
	If ValueIsFilled(pDoc.Author) Then
		vAuthor = pDoc.Author.Description;
	EndIf;
	
	vTransferTypeExtCode = cmGetObjectExternalSystemCodeByRef(vHotel, vInteractionID, "TransferTypes", pDoc.TransferType, True);
	vServiceExtCode = cmGetObjectExternalSystemCodeByRef(vHotel, vInteractionID, "Services", pDoc.Service, True);
	#EndRegion
	
	#Region GenerateJSON
	
	vJSONResponse 	= New JSONWriter;
	vJSONResponse.ValidateStructure = False;
	vJSONResponse.SetString();
	
	//Hotel
	vJSONResponse.WriteStartObject();
	vJSONResponse.WritePropertyName("Hotel");
	vJSONResponse.WriteValue(String(vHotelDescription));
	vJSONResponse.WritePropertyName("HotelExtCode");
	vJSONResponse.WriteValue(String(vHotelExtCode));
	
	//Company
	vJSONResponse.WritePropertyName("Company");
	vJSONResponse.WriteValue(String(vCompanyDescription));
	vJSONResponse.WritePropertyName("CompanyExtCode");
	vJSONResponse.WriteValue(String(vCompanyExtCode));
	
	//Order date
	vJSONResponse.WritePropertyName("Date");
	vJSONResponse.WriteValue(TrimAll(pDoc.Date));
	
	//Order number
	vJSONResponse.WritePropertyName("Number");
	vJSONResponse.WriteValue(TrimAll(pDoc.Number));
	
	//Period of stay
	vJSONResponse.WritePropertyName("CheckInDate");
	vJSONResponse.WriteValue(XMLString(vCheckInDate));
	vJSONResponse.WritePropertyName("CheckOutDate");
	vJSONResponse.WriteValue(XMLString(vCheckOutDate));
	
	//Status
	vJSONResponse.WritePropertyName("Status");
	vJSONResponse.WriteValue(TrimAll(pDoc.Status.Description));
	vJSONResponse.WritePropertyName("StatusCode");
	vJSONResponse.WriteValue(TrimAll(pDoc.Status.Code));
	vJSONResponse.WritePropertyName("StatusExtCode");
	vJSONResponse.WriteValue(cmGetObjectExternalSystemCodeByRef(vHotel, vInteractionID, "OrderStatuses", pDoc.Status, True));
	vJSONResponse.WritePropertyName("isOrderCancel");
	vJSONResponse.WriteValue(XMLString(pDoc.Status.isOrderCancel));

	//Param
	vJSONResponse.WritePropertyName("DeletionMark");
	vJSONResponse.WriteValue(XMLString(pDoc.DeletionMark));
	
	vJSONResponse.WritePropertyName("Posted");
	vJSONResponse.WriteValue(XMLString(pDoc.Posted));
	
	vJSONResponse.WritePropertyName("GuestGroup");
	vJSONResponse.WriteValue(TrimAll(pDoc.GuestGroup.Code));
	
	vJSONResponse.WritePropertyName("ExecuteDate");
	vJSONResponse.WriteValue(TrimAll(pDoc.OrderTime));
	
	vJSONResponse.WritePropertyName("Guest");
	vJSONResponse.WriteValue(vGuest);
	
	vJSONResponse.WritePropertyName("GuestID");
	vJSONResponse.WriteValue(vGuestID);
	
	vJSONResponse.WritePropertyName("Phone");
	vJSONResponse.WriteValue(String(pDoc.Phone));
	
	vJSONResponse.WritePropertyName("Amount");
	vJSONResponse.WriteValue(pDoc.Sum);
	
	vJSONResponse.WritePropertyName("Quantity");
	vJSONResponse.WriteValue(pDoc.Quantity);
	
	vJSONResponse.WritePropertyName("ChildSeatsNumber");
	vJSONResponse.WriteValue(pDoc.ChildSeatsNumber);
	
	vJSONResponse.WritePropertyName("GuestQuantity");
	vJSONResponse.WriteValue(pDoc.GuestsQuantity);
	
	vJSONResponse.WritePropertyName("TransferType");
	vJSONResponse.WriteValue(TrimAll(pDoc.TransferType));
	
	vJSONResponse.WritePropertyName("TransferTypeExtCode");
	vJSONResponse.WriteValue(vTransferTypeExtCode);
	
	vJSONResponse.WritePropertyName("PickupFrom");
	vJSONResponse.WriteValue(TrimAll(pDoc.PickupFrom));
	
	vJSONResponse.WritePropertyName("Destination");
	vJSONResponse.WriteValue(TrimAll(pDoc.Destination));
	
	vJSONResponse.WritePropertyName("Service");
	vJSONResponse.WriteValue(TrimAll(pDoc.Service.Description));
	
	vJSONResponse.WritePropertyName("ServiceExtCode");
	vJSONResponse.WriteValue(vServiceExtCode);
	
	vJSONResponse.WritePropertyName("Room");
	vJSONResponse.WriteValue(TrimAll(pDoc.Room.Description));
	
	vJSONResponse.WritePropertyName("Author");
	vJSONResponse.WriteValue(vAuthor);
	
	vJSONResponse.WritePropertyName("Remarks");
	vJSONResponse.WriteValue(TrimAll(pDoc.Remarks));
	
	vJSONResponse.WritePropertyName("DocumentID");
	vJSONResponse.WriteValue(pExternalOrderCode);
	
	//Agreement code
	vJSONResponse.WritePropertyName("AgreementCode");
	vJSONResponse.WriteValue(AgreementCode);
	
	vJSONResponse.WriteEndObject();
	
	vJSONText = vJSONResponse.Close();
	#EndRegion
	
	Return vJSONText; 
EndFunction

// -----------------------------------------------------------------------------
Function SendQuery(pJSON)
	vHTTPServer = TrimAll(ExternalInteraction.HTTPServer);
	vPort		= ExternalInteraction.HttpPort;
	vHTTPUser 	= TrimAll(ExternalInteraction.Login);
	vHTTPPwd 	= TrimAll(ExternalInteraction.Password);
	vUseSSL 	= ExternalInteraction.HTTPUseSSL;
	vWebhookURL = TrimAll(ExternalInteraction.WebhookURL);
	Try
		//HTTP
		vHTTPHeader = New Map;
		vHTTPHeader.Insert("Content-Type", "application/json;charset=utf-8");
		vHTTPHeader.Insert("POST", vHTTPServer + "/" + vWebhookURL);
		vHTTPHeader.Insert("Host", vHTTPServer);
		
		// HTTP connection
		vSSL = Undefined;
		If vUseSSL Then
			vSSL = New OpenSSLSecureConnection(Undefined, Undefined);       	
		EndIf;
		vHTTPConnection = New HTTPConnection(vHTTPServer, ?(vPort = 0, Undefined, vPort), vHTTPUser, vHTTPPwd, , , vSSL);

		//Send query
		vHTTPRequest = New HTTPRequest(vWebhookURL, vHTTPHeader);
		vHTTPRequest.SetBodyFromString(pJSON);
		rs = vHTTPConnection.Post(vHTTPRequest);
		vHTTPConnection = Undefined;
		Return rs.GetBodyAsString();
	Except
		vError = ErrorDescription();
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, "SendQuery", Enums.ExternalSystemEventTypes.Error, pJSON,"","Failed to send post query! " + vError); 
		Return vError;
	EndTry;
	
	Return Undefined;	
EndFunction // Hotel365_SendQuery


