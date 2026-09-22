
#Region Public

// --------------------------------------------------------------------------------
// 
// Returns:
//  Structure - Settings structure
//
Function GetSettings() Export
	vResult = New Structure("ExternalSystemCode, WSHost, ResourceAddress, EchoToken, TimeStamp, Version");
	vResult.ExternalSystemCode	= "Hoteza";
	vResult.WSHost				= "api.hoteza.com";
	vResult.ResourceAddress		= "xrws";
	vResult.EchoToken			= String(New UUID);
	vResult.TimeStamp			= Format(CurrentSessionDate(),"DF=yyyy-MM-ddTHH:mm:ss+03:00");
	vResult.Version				= "p 2.27";
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
//
// Parameters:
//  pHotel					 - CatalogRef.Hotel						 - Hotel
//  pHotelID				 - String								 - HotelID
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - External system interactions
//
Procedure Sync(pHotel, pHotelID, pInteractionParameters) Export
	vDocs = GetDocsToSync(pHotel);
	For Each vDoc In vDocs Do
		vSuccess = True;
		vRequestMethodName = "";
		vRequestJSON = "";
		vErrorDescription = "";
		vResponse = "";
		
		Try
			vRequest = GetRequest(pInteractionParameters, vDoc, pHotelID);
			vRequestMethodName = vRequest.MethodName;
			vRequestJSON = vRequest.JSON;
			
			If ValueIsFilled(vRequest.JSON) Then
				vResponse = ChannelManagers.SendQuery(vRequest.JSON, pInteractionParameters.WSHost, vRequest.MethodName, vRequest.MethodName);
				
				vJSON = New JSONReader;
				vJSON.SetString(vResponse);
				Try
					vTable = ReadJSON(vJSON);
				Except
					vSuccess = False;
					vErrorDescription = "Cant read request body as JSON";
					WriteLogEvent(pInteractionParameters.InteractionID + "_Hoteza_Sync", EventLogLevel.Warning, , CurrentSessionDate(), "Response error! " + vErrorDescription);
				EndTry;
				
				If vSuccess And vTable <> Undefined And TypeOf(vTable) = Type("Structure") Then
					If vTable.Property("result") Then
						If String(vTable.result) <> "0" Then	
							vSuccess = False;
							vErrorDescription = GetResponseCodeDescription(vRequest.MethodName, String(vTable.result));
							WriteLogEvent(pInteractionParameters.InteractionID + "_Hoteza_Sync", EventLogLevel.Warning, , CurrentSessionDate(), "Response error! " + vErrorDescription);
						EndIf;
					Else
						vSuccess = False;
						vErrorDescription = "Missing result in response from hoteza";
						WriteLogEvent(pInteractionParameters.InteractionID + "_Hoteza_Sync", EventLogLevel.Warning, , CurrentSessionDate(), "Response error! " + vErrorDescription);				
					EndIf;	
				EndIf;
			Else
				vSuccess = False;
				vErrorDescription = "Cant create JSON request for document: " + String(vDoc.Ref);
				WriteLogEvent(pInteractionParameters.InteractionID + "_Hoteza_Sync", EventLogLevel.Warning, , CurrentSessionDate(), "Response error! " + vErrorDescription);	
			EndIf;
		Except
			vSuccess = False;
			vErrorDescription = ErrorDescription();
			WriteLogEvent(pInteractionParameters.InteractionID + "_Hoteza_Sync", EventLogLevel.Warning, , CurrentSessionDate(), "Error! " + vErrorDescription);
		EndTry;

		// Log data exchange in debug mode
		If vSuccess Then
			If pInteractionParameters.DebugMode Then
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vRequestMethodName, Enums.ExternalSystemEventTypes.Success, vRequestJSON, vResponse, vErrorDescription);
			EndIf;
		Else
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vRequestMethodName, Enums.ExternalSystemEventTypes.Warning, vRequestJSON, vResponse, vErrorDescription);
		EndIf;
		
		vObj = vDoc.Ref.GetObject();
		If Not vDoc.IsCanceled Then
			vObj.Message = vRequest.JSON;
		Else
			vObj.CancellationMessage = vRequest.JSON;
		EndIf;
		vObj.IsProcessed = vSuccess;
		vObj.Write();
	EndDo;
EndProcedure

// --------------------------------------------------------------------------------
//
// Parameters:
//  pMethodName				 - String								 - Method name
//  pParameters				 - Structure							 - Parameters
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - External system interactions
// 
// Returns:
//  String - Result
//
Function ProcessRequest(pMethodName, pParameters, pInteractionParameters) Export
	vSettings = GetSettings();
	vParamText = NStr("en = 'Method name: '; ru = 'Наименование метода: '; de = 'Methodenname: '") + pMethodName + Chars.LF;
	vParamText = vParamText + NStr("en = 'External system interactions: '; ru = 'Взаимодействия с внешними системами: '; de = 'Kommunikationen mit externen Systemen: '") + String(pInteractionParameters) + Chars.LF;
	For Each vParam In pParameters Do
		vParamText = vParamText + String(vParam.Key) + ":" + String(vParam.Value) + Chars.LF;  	
	EndDo;
	WriteLogEvent(NStr("en = 'Process Hoteza request'; ru = 'Обработать запрос Hoteza'; de = 'Um Hoteza Anfrage zu bearbeiten'"), EventLogLevel.Information, , , vParamText);
	If pInteractionParameters.DebugMode Then
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, NStr("en = 'Process Hoteza request'; ru = 'Обработать запрос Hoteza'; de = 'Um Hoteza Anfrage zu bearbeiten'"), Enums.ExternalSystemEventTypes.Info, vParamText);
	EndIf;
	
	vSuccess		= True;
	vErrorCode		= 1;
	vAccommodation 	= Undefined;
	vDate 			= Undefined;
	If pParameters.Property("dateTime") Then
		Try
			vdateTime = StrReplace(pParameters.dateTime, "-", "");
			vdateTime = StrReplace(vdateTime, ":", "");
			vdateTime = StrReplace(vdateTime, " ", "");
			vDate = Date(vdateTime);
		Except
			WriteLogEvent(NStr("en = 'Process Hoteza request'; ru = 'Обработать запрос Hoteza'; de = 'Um Hoteza Anfrage zu bearbeiten'"), EventLogLevel.Error, , , "Failed to convert string to date: " + pParameters.dateTime);
			vDate = Undefined;
		EndTry;
	EndIf;
	If pParameters.Property("pmsRegNum") Then
		vAccommodation = Documents.Accommodation.EmptyRef();
		vQ = New Query;
		vQ.Text =
		"SELECT
		|	Accommodation.Ref AS Ref
		|FROM
		|	Document.Accommodation AS Accommodation
		|WHERE
		|	NOT Accommodation.DeletionMark
		|	AND Accommodation.Posted
		|	AND Accommodation.AccommodationStatus.IsActive
		|	AND Accommodation.Number = &qDocNumber
		|	AND (Accommodation.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
		|			OR Accommodation.AccommodationTemplate = VALUE(Catalog.AccommodationTemplates.EmptyRef)
		|				AND (Accommodation.AccommodationType.Type = VALUE(Enum.AccomodationTypes.Room)
		|					OR Accommodation.AccommodationType.Type = VALUE(Enum.AccomodationTypes.Beds)))
		|	AND Accommodation.Hotel = &qHotel";
		vQ.SetParameter("qHotel", pInteractionParameters.Hotel);
		vQ.SetParameter("qDocNumber", TrimAll(pParameters.pmsRegNum));
		vAccommodationsList = vQ.Execute().Unload();
		For Each vAccommodationRow In vAccommodationsList Do
			vAccommodation = vAccommodationRow.Ref;	
			Break;
		EndDo;
		If Not ValueIsFilled(vAccommodation) Then
			WriteLogEvent(NStr("en = 'Process Hoteza request'; ru = 'Обработать запрос Hoteza'; de = 'Um Hoteza Anfrage zu bearbeiten'"), EventLogLevel.Error, , , "Failed to find Accommodation by number: " + pParameters.pmsRegNum);
			If pParameters.Property("roomNumber") Then
				vAccommodation = GetAccommodationByRoomAndDate(pInteractionParameters, pParameters.roomNumber, vDate);
			EndIf;
		EndIf;
	ElsIf pParameters.Property("roomNumber") Then
		vAccommodation = GetAccommodationByRoomAndDate(pInteractionParameters, pParameters.roomNumber, vDate);
	EndIf;
	
	Try		
		If pMethodName = "sendmessage" And ValueIsFilled(vAccommodation) And pParameters.Property("messageText") Then
			vMessageObj 				= Documents.Message.CreateDocument();
			vMessageObj.Type			= Enums.MessageTypes.Message;
			vMessageObj.Date			= CurrentSessionDate();
			vMessageObj.ByObject 		= vAccommodation;
			If ValueIsFilled(vAccommodation.Hotel.ReservationDepartment) Then
				vMessageObj.ForDepartment = vAccommodation.Hotel.ReservationDepartment;
			EndIf;
			vMessageObj.Remarks = pParameters.messageText;
			vMessageObj.Write(DocumentWriteMode.Posting);
		ElsIf pMethodName = "wakeupcall" And ValueIsFilled(vAccommodation) And ValueIsFilled(vDate) Then
			vRoomInterfaceStatusObj 					= Documents.RoomInterfaceStatus.CreateDocument();
			vRoomInterfaceStatusObj.Date				= CurrentSessionDate();
			vRoomInterfaceStatusObj.Hotel				= vAccommodation.Hotel;
			vRoomInterfaceStatusObj.ParentDoc 			= vAccommodation;
			vRoomInterfaceStatusObj.Room				= vAccommodation.Room;
			vRoomInterfaceStatusObj.MessageDateTime		= vDate;
			vRoomInterfaceStatusObj.IsProcessed 		= True;
			vRoomInterfaceStatusObj.InterfaceType 		= Enums.InterfaceTypes.TV;
			vRoomInterfaceStatusObj.RoomInterfaceType 	= FindRoomInterfaceTypes("WakeUpCall", "", vAccommodation.Hotel); 
			vRoomInterfaceStatusObj.Write();
		ElsIf pMethodName = "clearwakeupcall" And ValueIsFilled(vAccommodation) And ValueIsFilled(vDate) Then
			vRoomInterfaceStatusRef = GetRoomInterfaceStatus(vAccommodation, "WakeUpCall", "ClearWakeUpCall", vDate);
			If ValueIsFilled(vRoomInterfaceStatusRef) Then
				vRoomInterfaceStatusObj 			= vRoomInterfaceStatusRef.GetObject();
				vRoomInterfaceStatusObj.IsCanceled 	= True;
				vRoomInterfaceStatusObj.IsProcessed = True;
				vRoomInterfaceStatusObj.Write();
			Else
				WriteLogEvent(NStr("en = 'Process Hoteza request'; ru = 'Обработать запрос Hoteza'; de = 'Um Hoteza Anfrage zu bearbeiten'"), EventLogLevel.Warning, , , "Failed to find RoomInterfaceStatus: Turn on parameters:WakeUpCall, Turn off parameters:ClearWakeUpCall, MessageDateTime:" + vDate);
				vSuccess 	= False;
				vErrorCode 	= 2;
			EndIf;
		ElsIf pMethodName = "bill" And ValueIsFilled(vAccommodation) Then
			If Not pInteractionParameters.DebugMode Then
				vAsyncParams = New Array;
				vAsyncParams.Add(vAccommodation);
				vAsyncParams.Add(pInteractionParameters);
				AsyncCalls.StartBackgroundJob("Hoteza.Bill", vAsyncParams);
			Else
				Bill(vAccommodation, pInteractionParameters);
			EndIf;
		ElsIf  pMethodName = "dnd" And ValueIsFilled(vAccommodation) And pParameters.Property("dnd") Then
			If pParameters.dnd = "0" Then
				vRoomInterfaceStatuses = GetDNDRoomInterfaceStatus(vAccommodation);
				For Each vRow In vRoomInterfaceStatuses Do
					vRoomInterfaceStatusObj 					= vRow.Ref.GetObject();
					vRoomInterfaceStatusObj.IsProcessed 		= True;
					vRoomInterfaceStatusObj.IsCanceled 			= True;
					vRoomInterfaceStatusObj.Write();	
				EndDo;
			Else
				vRoomInterfaceStatusObj 					= Documents.RoomInterfaceStatus.CreateDocument();
				vRoomInterfaceStatusObj.Date				= CurrentSessionDate();
				vRoomInterfaceStatusObj.Hotel				= vAccommodation.Hotel;
				vRoomInterfaceStatusObj.ParentDoc 			= vAccommodation;
				vRoomInterfaceStatusObj.Room				= vAccommodation.Room;
				vRoomInterfaceStatusObj.MessageDateTime		= vDate;
				vRoomInterfaceStatusObj.IsProcessed 		= True;
				vRoomInterfaceStatusObj.InterfaceType 		= Enums.InterfaceTypes.TV;
				vRoomInterfaceStatusObj.RoomInterfaceType 	= FindRoomInterfaceTypes("DND", "", vAccommodation.Hotel);
				vRoomInterfaceStatusObj.Write();
			EndIf;
		ElsIf  pMethodName = "roomstatus" And pParameters.Property("roomNumber") And pParameters.Property("status") Then
			vRoomRef = cmGetObjectRefByExternalSystemCode(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, "Rooms", pParameters.roomNumber);
			If ValueIsFilled(vRoomRef) Then
				vRoomStatus = cmGetObjectRefByExternalSystemCode(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, "RoomStatuses", pParameters.status);
				If ValueIsFilled(vRoomStatus) Then
					vRoomObj 			= vRoomRef.GetObject();
					vRoomObj.RoomStatus = vRoomStatus;
					vRoomObj.Write();
					vRoomObj.pmWriteToRoomStatusChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser, "Hoteza");
				Else
					vSuccess 	= False;
					vErrorCode 	= 1;
					WriteLogEvent(NStr("en = 'Process Hoteza request'; ru = 'Обработать запрос Hoteza'; de = 'Um Hoteza Anfrage zu bearbeiten'"), EventLogLevel.Error, , , "Failed to find room status: " + pParameters.status);
				EndIf;
			Else
				vSuccess 	= False;
				vErrorCode 	= 2;
				WriteLogEvent(NStr("en = 'Process Hoteza request'; ru = 'Обработать запрос Hoteza'; de = 'Um Hoteza Anfrage zu bearbeiten'"), EventLogLevel.Error, , , "Failed to find room by description: " + pParameters.roomNumber);
			EndIf;
		ElsIf  pMethodName = "sale" And pParameters.Property("roomNumber") And pParameters.Property("posId") And pParameters.Property("checkNum") And pParameters.Property("type") Then
			If pParameters.type = "M" Then
				If pParameters.Property("article") And pParameters.Property("amount") Then
					If Not pInteractionParameters.DebugMode Then
						vAsyncParams = New Array;
						vAsyncParams.Add(pParameters.roomNumber);
						vAsyncParams.Add(pParameters.posId);
						vAsyncParams.Add(pParameters.checkNum);
						vAsyncParams.Add(pParameters.article);
						vAsyncParams.Add(pParameters.amount);
						vAsyncParams.Add(Undefined);
						vAsyncParams.Add(Undefined);
						vAsyncParams.Add(pInteractionParameters);
						AsyncCalls.StartBackgroundJob("Hoteza.Sale", vAsyncParams);
					Else
						Sale(pParameters.roomNumber, pParameters.posId, pParameters.checkNum, pParameters.article,  pParameters.amount, , , pInteractionParameters);
					EndIf;
				Else
					vSuccess 	= False;
					vErrorCode 	= 1;
					WriteLogEvent(NStr("en = 'Process Hoteza request'; ru = 'Обработать запрос Hoteza'; de = 'Um Hoteza Anfrage zu bearbeiten'"), EventLogLevel.Error, , , "Missing amount or article fields for sale method");
				EndIf;
			ElsIf pParameters.type = "C" Then
				If pParameters.Property("totalAmount") And pParameters.Property("text") Then
					If Not pInteractionParameters.DebugMode Then
						vAsyncParams = New Array;
						vAsyncParams.Add(pParameters.roomNumber);
						vAsyncParams.Add(pParameters.posId);
						vAsyncParams.Add(pParameters.checkNum);
						vAsyncParams.Add(Undefined);
						vAsyncParams.Add(Undefined);
						vAsyncParams.Add(pParameters.totalAmount);
						vAsyncParams.Add(pParameters.text);
						vAsyncParams.Add(pInteractionParameters);
						AsyncCalls.StartBackgroundJob("Hoteza.Sale", vAsyncParams);
					Else
						Sale(pParameters.roomNumber, pParameters.posId, pParameters.checkNum, , ,pParameters.totalAmount, pParameters.text, pInteractionParameters);
					EndIf;
				Else
					vSuccess 	= False;
					vErrorCode 	= 1;
					WriteLogEvent(NStr("en = 'Process Hoteza request'; ru = 'Обработать запрос Hoteza'; de = 'Um Hoteza Anfrage zu bearbeiten'"), EventLogLevel.Error, , , "Missing totalAmount or text fields for sale method");
				EndIf;
			Else
				vSuccess 	= False;
				vErrorCode 	= 1;
				WriteLogEvent(NStr("en = 'Process Hoteza request'; ru = 'Обработать запрос Hoteza'; de = 'Um Hoteza Anfrage zu bearbeiten'"), EventLogLevel.Error, , , "Wrong type of sale: " + pParameters.type);
			EndIf;		
		ElsIf  pMethodName = "wakeupcallanswer" And ValueIsFilled(vAccommodation) And ValueIsFilled(vDate) And pParameters.Property("code") Then
			vRoomInterfaceStatusRef = GetRoomInterfaceStatus(vAccommodation, "WakeUpCall", "ClearWakeUpCall", vDate);
			If ValueIsFilled(vRoomInterfaceStatusRef) Then
				vCodeDescription = "";
				If pParameters.code = "OK" Then
					vCodeDescription = "Request is OK, guest wake up";
				ElsIf pParameters.code = "BY" Then
					vCodeDescription = "Guest busy";
				ElsIf pParameters.code = "DE" Then
					vCodeDescription = "Wakeup Call service was removed early";
				ElsIf pParameters.code = "NR" Then
					vCodeDescription = "No response from guest";
				ElsIf pParameters.code = "UR" Then
					vCodeDescription = "Can not setup Wakeup Call service, service is unavailable";
				EndIf;
				
				vRoomInterfaceStatusObj = vRoomInterfaceStatusRef.GetObject();
				vRoomInterfaceStatusObj.Remarks = vRoomInterfaceStatusObj.Remarks + Chars.LF + "wakeupcallanswer code: " + pParameters.code + "; description: " + vCodeDescription;
				If pParameters.code = "OK" or  pParameters.code = "BY" Then
					vRoomInterfaceStatusObj.MessageIsDelivered 		= True;
					vRoomInterfaceStatusObj.MessageDeliveryDateTime = CurrentSessionDate();
				EndIf;
				vRoomInterfaceStatusObj.Write();
			Else
				WriteLogEvent(NStr("en = 'Process Hoteza request'; ru = 'Обработать запрос Hoteza'; de = 'Um Hoteza Anfrage zu bearbeiten'"), EventLogLevel.Error, , , "Failed to find RoomInterfaceStatus: Turn on parameters:WakeUpCall, Turn off parameters:ClearWakeUpCall, MessageDateTime: " + vDate);
				vSuccess 	= False;
				vErrorCode 	= 1;
			EndIf;	
		ElsIf  pMethodName = "swaprequest" And pParameters.Property("startDateTime") And pParameters.Property("endDateTime") Then
			Try
				vPeriodFrom = StrReplace(pParameters.startDateTime, "-", "");
				vPeriodFrom = StrReplace(vPeriodFrom, ":", "");
				vPeriodFrom = StrReplace(vPeriodFrom, " ", "");
				vPeriodFrom = Date(vPeriodFrom);
				
				vPeriodTo = StrReplace(pParameters.endDateTime, "-", "");
				vPeriodTo = StrReplace(vPeriodTo, ":", "");
				vPeriodTo = StrReplace(vPeriodTo, " ", "");
				vPeriodTo = Date(vPeriodTo);
			Except
				WriteLogEvent(NStr("en = 'Process Hoteza request'; ru = 'Обработать запрос Hoteza'; de = 'Um Hoteza Anfrage zu bearbeiten'"), EventLogLevel.Error, , , "Failed to convert string to date. Start date: " + pParameters.startDateTime + "; End date: " + pParameters.endDateTime);
				vPeriodFrom = Undefined;
				vPeriodTo	= Undefined;
			EndTry;
			
			If ValueIsFilled(vPeriodFrom) And ValueIsFilled(vPeriodTo) Then
				If Not pInteractionParameters.DebugMode Then
					vAsyncParams = New Array;
					vAsyncParams.Add(vPeriodFrom);
					vAsyncParams.Add(vPeriodTo);
					vAsyncParams.Add(pInteractionParameters);
					AsyncCalls.StartBackgroundJob("Hoteza.SwapRequest", vAsyncParams);
				Else	
					SwapRequest(vPeriodFrom, vPeriodTo, pInteractionParameters);
				EndIf;
			Else
				vSuccess 	= False;
				vErrorCode 	= 1;
			EndIf;
		ElsIf  pMethodName = "ping" Then
			vJSONResponse 	= New JSONWriter;
			vJSONResponse.ValidateStructure = False;
			vJSONResponse.SetString();
			
			vJSONResponse.WriteStartObject();			
			vJSONResponse.WritePropertyName("result");
			vJSONResponse.WriteValue(0);
			vJSONResponse.WritePropertyName("version");
			vJSONResponse.WriteValue(vSettings.Version);

			vJSONResponse.WriteEndObject();
			
			vResult = vJSONResponse.Close();
			
			Return vResult;
			
		ElsIf  pMethodName = "xprscheckout" Then
	     	vSuccess = True;
		Else
			vSuccess 	= False;
			WriteLogEvent(NStr("en = 'Process Hoteza request'; ru = 'Обработать запрос Hoteza'; de = 'Um Hoteza Anfrage zu bearbeiten'"), EventLogLevel.Error, , , "Unknown method or some parameters are missing!");
		EndIf;
	Except
		vErrorDescription = ErrorDescription();
		WriteLogEvent(NStr("en = 'Process Hoteza request'; ru = 'Обработать запрос Hoteza'; de = 'Um Hoteza Anfrage zu bearbeiten'"), EventLogLevel.Error, , , vErrorDescription);
		vSuccess = False;	
	EndTry;
	
	vJSONResponse 	= New JSONWriter;
	vJSONResponse.ValidateStructure = False;
	vJSONResponse.SetString();
	
	vJSONResponse.WriteStartObject();			
	vJSONResponse.WritePropertyName("result");
	If vSuccess Then 
		vJSONResponse.WriteValue(0);
	Else
		vJSONResponse.WriteValue(vErrorCode);
	EndIf;
	vJSONResponse.WriteEndObject();
	
	vResult = vJSONResponse.Close();
	
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
//
// Parameters:
//  pAccommodation			 - DocumentRef.Accommodation			 - Accommodation
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - External system interactions
//
Procedure Bill(pAccommodation, pInteractionParameters) Export
	vHotelID = cmGetObjectExternalSystemCodeByRef(pAccommodation.Hotel, pInteractionParameters.InteractionID, "Hotels", pAccommodation.Hotel);
	If ValueIsFilled(vHotelID) Then
		vRequest 			= New Structure("JSON, MethodName");
		vRequest.MethodName = "pmsconnect/bill";
		vRequest.JSON 	= GetJSON_Bill(pInteractionParameters, vHotelID, pAccommodation, pInteractionParameters.InteractionID, pInteractionParameters.MultiplyFactor);
		vResponse 		= ChannelManagers.SendQuery(vRequest.JSON, pInteractionParameters.WSHost, vRequest.MethodName, vRequest.MethodName);
		ReadResponse(vRequest, vResponse, pInteractionParameters);	
	Else
		WriteLogEvent("Hoteza Bill", EventLogLevel.Error, , , "HotelID not found for accommodation:" + pAccommodation);	
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
//
// Parameters:
//  pPeriodFrom				 - Date									 - Period from
//  pPeriodTo				 - Date									 - Period to
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - External system interactions
//
Procedure SwapRequest(pPeriodFrom, pPeriodTo, pInteractionParameters) Export
	vDocs = GetDocsToSync(pInteractionParameters.Hotel, pPeriodFrom, pPeriodTo);
	For Each vDoc In vDocs Do
		If ValueIsFilled(vDoc.Message) Then
			vRequest 	= GetRequest(pInteractionParameters, vDoc, , True);
			vResponse 	= ChannelManagers.SendQuery(vDoc.Message, pInteractionParameters.WSHost, vRequest.MethodName, vRequest.MethodName);
			ReadResponse(vRequest, vResponse, pInteractionParameters);
		EndIf;
		If ValueIsFilled(vDoc.CancellationMessage) Then
			vRequest 	= GetRequest(pInteractionParameters, vDoc, , True);
			vResponse 	= ChannelManagers.SendQuery(vDoc.CancellationMessage, pInteractionParameters.WSHost, vRequest.CancelMethodName, vRequest.CancelMethodName);
			ReadResponse(vRequest, vResponse, pInteractionParameters);
		EndIf;
	EndDo;	
EndProcedure

// --------------------------------------------------------------------------------
//
// Parameters:
//  pRoomNumber				 - String								 - Room number
//  pPosId					 - String								 - Pos Id
//  pCheckNum				 - String								 - Check num
//  pArticle				 - String								 - Article
//  pAmount					 - Number								 - Amount
//  pTotalAmount			 - Number								 - Total amount
//  pText					 - String						 		 - Text
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - External system interactions
//
Procedure Sale(pRoomNumber, pPosId, pCheckNum, pArticle = Undefined, pAmount = Undefined, pTotalAmount = Undefined, pText = Undefined, pInteractionParameters) Export
	vHotelID = cmGetObjectExternalSystemCodeByRef(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, "Hotels", pInteractionParameters.Hotel);
	If ValueIsFilled(vHotelID) Then
		vSale 				= New Structure("roomNumber, status, posId, dateTime, checkNum, text");
		vSale.roomNumber 	= pRoomNumber;
		vSale.posId 		= pPosId;
		vDate 				= CurrentSessionDate();
		vSale.dateTime 		= vDate;
		vSale.checkNum 		= pCheckNum;
		If ValueIsFilled(pArticle) And ValueIsFilled(pAmount) Then
			vResult = cmChargeRoomService(pRoomNumber, vDate, 0, , , pArticle, pAmount, , , , pInteractionParameters.Hotel.Description, pInteractionParameters.InteractionID, , pCheckNum);
			If IsBlankString(vResult) Then
				vSale.status 	= 0;
				vSale.text 		= "Posting successful.";
			Else
				vSale.status = 9;
				vSale.text 		= vResult;
			EndIf;
		ElsIf ValueIsFilled(pTotalAmount) And ValueIsFilled(pText) Then
			vResult = cmChargeRoomService(pRoomNumber, vDate, pTotalAmount, , ,pPosId , 1, , pText, , pInteractionParameters.Hotel.Description, pInteractionParameters.InteractionID, , pCheckNum);
			If IsBlankString(vResult) Then
				vSale.status 	= 0;
				vSale.text 		= "Posting successful.";
			Else
				vSale.status = 9;
				vSale.text 		= vResult;
			EndIf;
		Else
			vSale.status 	= 9;
			vSale.text 		= "Article, amount, totalAmount or text parameters are missing!";
		EndIf;
		
		vRequest 			= New Structure("JSON, MethodName");
		vRequest.MethodName = "pmsconnect/saledone";
		vRequest.JSON 		= GetJSON_SaleDone(pInteractionParameters, vHotelID, vSale);
		vResponse 			= ChannelManagers.SendQuery(vRequest.JSON, pInteractionParameters.WSHost, vRequest.MethodName, vRequest.MethodName);
		ReadResponse(vRequest, vResponse, pInteractionParameters);
	Else
		WriteLogEvent("Hoteza Sale", EventLogLevel.Error, , , "HotelID not found for hotel:" + String(pInteractionParameters.Hotel));		
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
//
// Parameters:
//  pAccommodation			 - DocumentRef.Accommodation			 - Accommodation
//  pBalance				 - Number								 - Balance
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - External system interactions
//  pDateTime				 - Date									 - Date time
//  pRoomNumber				 - String								 - Room number
//
Procedure Xprscheckout(pAccommodation, pBalance, pInteractionParameters, pDateTime, pRoomNumber) Export
	vHotelID = cmGetObjectExternalSystemCodeByRef(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, "Hotels", pInteractionParameters.Hotel);
	If ValueIsFilled(vHotelID) Then
		vCheckOutStatus 		= cmGetObjectRefByExternalSystemCode(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, "AccommodationStatuses", "Hoteza");
		vCheckOut				= New Structure("hotelId, roomNumber, pmsRegNum, status, balance, text, datetime");
		vCheckOut.hotelId 		= vHotelID;
		vCheckOut.roomNumber 	= Left(cmGetObjectExternalSystemCodeByRef(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, "Rooms", pAccommodation.Room), 10);
		vCheckOut.pmsRegNum 	= pAccommodation.Number;
		vCheckOut.datetime 		= pDateTime;
		If ValueIsFilled(vCheckOutStatus) Then
			If BegOfDay(pAccommodation.CheckOutDate) = BegOfDay(CurrentSessionDate()) Then
				vBills = GetGuestFoliosWithTransactions(pAccommodation, pInteractionParameters.InteractionID);
				If vBills.billTotal = Number(pBalance) And vBills.billTotal <= 0 Then
					Try
						vDocObj 					= pAccommodation.GetObject();
						vDocObj.AccommodationStatus = vCheckOutStatus;
						vDocObj.Write(DocumentWriteMode.Posting);
						vCheckOut.status 	= "0";
						vCheckOut.text 		= "Success";
					Except
						vErrorDescription	= ErrorDescription();
						vCheckOut.status 	= "9";
						vCheckOut.text 		= vErrorDescription;
					EndTry;
				Else
					vCheckOut.status 	= "1";
					vCheckOut.text 		= "Balance mismatch";	
				EndIf;
			Else
				vCheckOut.status 	= "2";
				vCheckOut.text 		= "Check‑out date is not today";	
			EndIf;
		Else
			vCheckOut.status 	= "3";
			vCheckOut.text 		= "Feature not enabled";
		EndIf;
		
		vRequest 			= New Structure("JSON, MethodName");
		vRequest.MethodName = "pmsconnect/xprscheckout";
		vRequest.JSON 	= GetJSON_XprsCheckOut(pInteractionParameters, vHotelID, pAccommodation, vCheckOut);
		vResponse 		= ChannelManagers.SendQuery(vRequest.JSON, pInteractionParameters.WSHost, vRequest.MethodName, vRequest.MethodName);
		ReadResponse(vRequest, vResponse, pInteractionParameters);
	Else
		WriteLogEvent("Hoteza Xprscheckout", EventLogLevel.Error, , , "HotelID not found for hotel:" + String(pInteractionParameters.Hotel));		
	EndIf;
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
Function ReadResponse(pRequest, pResponse, pInteractionParameters)
	vErrorDescription = "";
	
	vJSON = New JSONReader;
	vJSON.SetString(pResponse);
	Try
		vTable = ReadJSON(vJSON);
	Except
		vErrorDescription 	= "Cant read request body as JSON";
		WriteLogEvent(pInteractionParameters.InteractionID + "_Hoteza_Sync", EventLogLevel.Warning,,CurrentSessionDate(), "Response error!" + vErrorDescription);
	EndTry;
	
	If vTable <> Undefined And TypeOf(vTable) = Type("Structure") Then
		If vTable.Property("result") Then
			If String(vTable.result) <> "0" Then	
				vSuccess 			= False;
				vErrorDescription 	= GetResponseCodeDescription(pRequest.MethodName, String(vTable.result));
				WriteLogEvent(pInteractionParameters.InteractionID + "_Hoteza_" + pRequest.MethodName, EventLogLevel.Warning,,CurrentSessionDate(), "Response error!" + vErrorDescription);
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, pRequest.MethodName, Enums.ExternalSystemEventTypes.Warning, pRequest.JSON, pResponse, vErrorDescription);	
			Else
				WriteLogEvent(pInteractionParameters.InteractionID +  "_Hoteza_" + pRequest.MethodName, EventLogLevel.Information,,CurrentSessionDate(), "Success");
				If pInteractionParameters.DebugMode Then
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, pRequest.MethodName, Enums.ExternalSystemEventTypes.Success, pRequest.JSON, pResponse);
				EndIf;
			EndIf;
		Else
			vSuccess 			= False;
			vErrorDescription 	= "Missing result in response from hoteza";
			WriteLogEvent(pInteractionParameters.InteractionID + "_Hoteza_" + pRequest.MethodName, EventLogLevel.Warning,,CurrentSessionDate(), "Response error!" + vErrorDescription);
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, pRequest.MethodName, Enums.ExternalSystemEventTypes.Warning, pRequest.JSON, pResponse, vErrorDescription);
		EndIf;	
	EndIf;
	
	Return vErrorDescription;
EndFunction

// --------------------------------------------------------------------------------
Function GetRequest(pInteractionParameters, pDocRow, pHotelID = Undefined, pOnlyMethodName = False)
	vResult = New Structure("MethodName, JSON, CancelMethodName");
	If Not pOnlyMethodName And Not ValueIsFilled(pHotelID) Then
		Return vResult;
	EndIf;
		
	If pOnlyMethodName = True Then 
		If pDocRow.TurnOnParameters 	= "CheckIn" Then
			vResult.MethodName 	= "pmsconnect/checkin";
		ElsIf pDocRow.TurnOnParameters 	= "ClientDataChange" Then
			vResult.MethodName 	= "pmsconnect/clientdatachange";
		ElsIf pDocRow.TurnOnParameters 	= "ClientDataChange_Room" Then
			vResult.MethodName 	= "pmsconnect/clientdatachange";
		ElsIf pDocRow.TurnOnParameters 	= "ClientDataChange_Name" Then
			vResult.MethodName 	= "pmsconnect/clientdatachange";
		ElsIf pDocRow.TurnOnParameters 	= "ClientDataChange_CheckOutDate" Then
			vResult.MethodName 	= "pmsconnect/clientdatachange";
		ElsIf pDocRow.TurnOnParameters 	= "ClientDataChange_NoPost" Then	
			vResult.MethodName 	= "pmsconnect/clientdatachange";
		ElsIf pDocRow.TurnOnParameters 	= "Message" Then	
			vResult.MethodName 	= "pmsconnect/readmessages";
		ElsIf pDocRow.TurnOnParameters 	= "WakeUpCall" Then	
			vResult.MethodName 	= "pmsconnect/wakeupcall";
		ElsIf pDocRow.TurnOnParameters 	= "DND" Then
			vResult.MethodName 	= "pmsconnect/dnd"; 
		ElsIf pDocRow.TurnOnParameters 	= "Rights_TV" Then
			vResult.MethodName 	= "pmsconnect/tvrights";
		ElsIf pDocRow.TurnOnParameters 	= "Rights_TV_Full" Then
			vResult.MethodName 	= "pmsconnect/tvrights";
		ElsIf pDocRow.TurnOnParameters 	= "Rights_TV_NoPayable" Then
			vResult.MethodName 	= "pmsconnect/tvrights";
		ElsIf pDocRow.TurnOnParameters 	= "Rights_TV_NoXXX" Then
			vResult.MethodName 	= "pmsconnect/tvrights";
		ElsIf pDocRow.TurnOnParameters 	= "Rights_TV_Unavailable" Then
			vResult.MethodName 	= "pmsconnect/tvrights"; 
		ElsIf pDocRow.TurnOnParameters 	= "Rights_Minibar" Then
			vResult.MethodName 	= "pmsconnect/minibarrights";
		ElsIf pDocRow.TurnOnParameters 	= "Rights_Minibar_Available" Then
			vResult.MethodName 	= "pmsconnect/minibarrights";
		ElsIf pDocRow.TurnOnParameters 	= "Rights_Minibar_Vending" Then
			vResult.MethodName 	= "pmsconnect/minibarrights";
		ElsIf pDocRow.TurnOnParameters 	= "Rights_Minibar_Unavailable" Then
			vResult.MethodName 	= "pmsconnect/minibarrights";
		EndIf;
		
		If pDocRow.IsCanceled Then
			If pDocRow.TurnOffParameters 	= "CheckOut" Then
				vResult.CancelMethodName 	= "pmsconnect/checkout";
			ElsIf pDocRow.TurnOffParameters = "ClientDataChange_NoPost" Then	
				vResult.CancelMethodName 	= "pmsconnect/clientdatachange";
			ElsIf pDocRow.TurnOffParameters = "ClearWakeUpCall" Then
				vResult.CancelMethodName 	= "pmsconnect/clearwakeupcall";
			ElsIf pDocRow.TurnOffParameters = "DND" Then
				vResult.CancelMethodName 	= "pmsconnect/dnd";
			EndIf;
		EndIf;	
	Else
		vParameterName = "";
		If Not pDocRow.IsCanceled And pDocRow.PeriodOfStayExtensionIsRequested Then
			vParameterName = pDocRow.PeriodOfStayExtentionParameters; 	
		ElsIf Not pDocRow.IsCanceled And pDocRow.GuestNameChangeIsRequested Then 
			vParameterName = pDocRow.GuestNameChangeParameters;	
		ElsIf Not pDocRow.IsCanceled And pDocRow.RoomChangeIsRequested Then
			vParameterName = pDocRow.RoomChangeParameters;
		ElsIf Not pDocRow.IsCanceled And pDocRow.ExtraParametersChangeIsRequested Then
			vParameterName = pDocRow.CommandToChangeExtraParameters;
		ElsIf Not pDocRow.IsCanceled Then	
			vParameterName = pDocRow.TurnOnParameters;	
		ElsIf pDocRow.IsCanceled Then	
			vParameterName = pDocRow.TurnOffParameters;
		EndIf;
		
		vExtraParameters = JSONToMap(pDocRow.ExtraParameters);
		
		If Not pDocRow.IsCanceled Then 
			If vParameterName 	= "CheckIn" Then
				vResult.MethodName 	= "pmsconnect/checkin";
				vResult.JSON 		= GetJSON_CheckIn(pInteractionParameters, pHotelID, pDocRow.ParentDoc, vExtraParameters);
			ElsIf vParameterName 	= "ClientDataChange" Then 
				vResult.MethodName 	= "pmsconnect/clientdatachange";
				vResult.JSON 		= GetJSON_ClientDataChange(pInteractionParameters, pHotelID, pDocRow.ParentDoc, pDocRow.OldRoom, ?(vExtraParameters["NoPost"] = Undefined Or Not vExtraParameters["NoPost"], "0", "1"), vExtraParameters);
			ElsIf vParameterName 	= "ClientDataChange_Room" Then
				vOldRoom			= GetOldRoom(pDocRow.ParentDoc, pDocRow.Date);
				vResult.MethodName 	= "pmsconnect/clientdatachange";
				vResult.JSON 		= GetJSON_ClientDataChange(pInteractionParameters, pHotelID, pDocRow.ParentDoc, vOldRoom, Undefined, vExtraParameters);
			ElsIf vParameterName 	= "ClientDataChange_Name" Then
				vResult.MethodName 	= "pmsconnect/clientdatachange";
				vResult.JSON 		= GetJSON_ClientDataChange(pInteractionParameters, pHotelID, pDocRow.ParentDoc, Undefined, Undefined, vExtraParameters);
			ElsIf vParameterName 	= "ClientDataChange_CheckOutDate" Then
				vResult.MethodName 	= "pmsconnect/clientdatachange";
				vResult.JSON 		= GetJSON_ClientDataChange(pInteractionParameters, pHotelID, pDocRow.ParentDoc, Undefined, Undefined, vExtraParameters);
			ElsIf vParameterName 	= "ClientDataChange_NoPost" Then	
				vResult.MethodName 	= "pmsconnect/clientdatachange";
				vResult.JSON 		= GetJSON_ClientDataChange(pInteractionParameters, pHotelID, pDocRow.ParentDoc, Undefined, "1", vExtraParameters);
			ElsIf vParameterName 	= "Message" Then
				vMessages = New Array;
				vMessages.Add(New Structure("text, dateTime", pDocRow.Remarks, pDocRow.MessageDateTime));	
				vResult.MethodName 	= "pmsconnect/readmessages";
				vResult.JSON 		= GetJSON_ReadMessages(pInteractionParameters, pHotelID, pDocRow.ParentDoc, vMessages);
			ElsIf vParameterName 	= "WakeUpCall" Then	
				vResult.MethodName 	= "pmsconnect/wakeupcall";
				vResult.JSON 		= GetJSON_WakeUpCall(pInteractionParameters, pHotelID, pDocRow.ParentDoc, pDocRow.MessageDateTime);
			ElsIf vParameterName 	= "DND" Then
				vResult.MethodName 	= "pmsconnect/dnd";
				vResult.JSON 		= GetJSON_DND(pInteractionParameters, pHotelID, pDocRow.ParentDoc, "1");
			ElsIf vParameterName 	= "Rights_TV" Then
				vResult.MethodName 	= "pmsconnect/tvrights";
				vResult.JSON 		= GetJSON_Rights(pInteractionParameters, pHotelID, pDocRow.ParentDoc, ?(vExtraParameters["TVRights"] = Undefined Or IsBlankString(vExtraParameters["TVRights"]), "3", vExtraParameters["TVRights"]));
			ElsIf vParameterName 	= "Rights_TV_Full" Then
				vResult.MethodName 	= "pmsconnect/tvrights";
				vResult.JSON 		= GetJSON_Rights(pInteractionParameters, pHotelID, pDocRow.ParentDoc, "0");
			ElsIf vParameterName 	= "Rights_TV_NoPayable" Then
				vResult.MethodName 	= "pmsconnect/tvrights";
				vResult.JSON 		= GetJSON_Rights(pInteractionParameters, pHotelID, pDocRow.ParentDoc, "1");
			ElsIf vParameterName 	= "Rights_TV_NoXXX" Then
				vResult.MethodName 	= "pmsconnect/tvrights";
				vResult.JSON 		= GetJSON_Rights(pInteractionParameters, pHotelID, pDocRow.ParentDoc, "2");
			ElsIf vParameterName 	= "Rights_TV_Unavailable" Then
				vResult.MethodName 	= "pmsconnect/tvrights";
				vResult.JSON 		= GetJSON_Rights(pInteractionParameters, pHotelID, pDocRow.ParentDoc, "3");  
			ElsIf vParameterName 	= "Rights_Minibar" Then
				vResult.MethodName 	= "pmsconnect/minibarrights";
				vResult.JSON 		= GetJSON_Rights(pInteractionParameters, pHotelID, pDocRow.ParentDoc, ?(vExtraParameters["MinibarRights"] = Undefined Or IsBlankString(vExtraParameters["MinibarRights"]), "2", vExtraParameters["MinibarRights"]));
			ElsIf vParameterName 	= "Rights_Minibar_Available" Then
				vResult.MethodName 	= "pmsconnect/minibarrights";
				vResult.JSON 		= GetJSON_Rights(pInteractionParameters, pHotelID, pDocRow.ParentDoc, "0");
			ElsIf vParameterName 	= "Rights_Minibar_Vending" Then
				vResult.MethodName 	= "pmsconnect/minibarrights";
				vResult.JSON 		= GetJSON_Rights(pInteractionParameters, pHotelID, pDocRow.ParentDoc, "1");
			ElsIf vParameterName 	= "Rights_Minibar_Unavailable" Then
				vResult.MethodName 	= "pmsconnect/minibarrights";
				vResult.JSON 		= GetJSON_Rights(pInteractionParameters, pHotelID, pDocRow.ParentDoc, "2");
			EndIf;
		Else
			If pDocRow.TurnOffParameters 	= "CheckOut" Then
				vResult.MethodName 	= "pmsconnect/checkout";
				vResult.JSON 		= GetJSON_CheckOut(pInteractionParameters, pHotelID, pDocRow.ParentDoc);
			ElsIf pDocRow.TurnOffParameters = "ClientDataChange_NoPost" Then	
				vResult.MethodName 	= "pmsconnect/clientdatachange";
				vResult.JSON 		= GetJSON_ClientDataChange(pInteractionParameters, pHotelID, pDocRow.ParentDoc, Undefined, "0", vExtraParameters);
			ElsIf pDocRow.TurnOffParameters = "ClearWakeUpCall" Then
				vResult.MethodName 	= "pmsconnect/clearwakeupcall";
				vResult.JSON 		= GetJSON_WakeUpCall(pInteractionParameters, pHotelID, pDocRow.ParentDoc, pDocRow.MessageDateTime);
			ElsIf pDocRow.TurnOffParameters = "DND" Then
				vResult.MethodName 	= "pmsconnect/dnd";
				vResult.JSON 		= GetJSON_DND(pInteractionParameters, pHotelID, pDocRow.ParentDoc, "0");
			EndIf;
		EndIf; 
	EndIf;
	
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
Function GetJSON_CheckIn(pInteractionParameters, pHotelID, pAccommodation, pAdditional = Undefined)
	vResult = "";	
	vGuestCount = GetGuestsCount(pAccommodation);
	If vGuestCount > 0 Then
		vRoomShare 	= "1";
	Else
		vRoomShare 	= "0";	
	EndIf;
	
	vNoPost = "0";

	vJSON 					= New JSONWriter;
	vJSON.ValidateStructure = False;
	vJSON.SetString();
	
	vJSON.WriteStartObject();
		vJSON.WritePropertyName("hotelId");
		vJSON.WriteValue(pHotelID);
		vJSON.WritePropertyName("roomNumber");
		vJSON.WriteValue(Left(cmGetObjectExternalSystemCodeByRef(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, "Rooms", pAccommodation.Room), 10));
		vJSON.WritePropertyName("guestName");
		vJSON.WriteValue(Left(pAccommodation.Guest.LastName, 40));
		vJSON.WritePropertyName("guestFirstName");
		vJSON.WriteValue(Left(pAccommodation.Guest.FirstName, 40));
		vJSON.WritePropertyName("guestTitle");
		vJSON.WriteValue(Left(pAccommodation.Guest.Salutation.Title, 10));
		vJSON.WritePropertyName("pmsRegNum");
		vJSON.WriteValue(Left(pAccommodation.Number, 20));
		vJSON.WritePropertyName("arrivalDate");
		vJSON.WriteValue(Format(pAccommodation.CheckInDate, "DF=yyyy-MM-dd"));
		vJSON.WritePropertyName("departureDate");
		vJSON.WriteValue(Format(pAccommodation.CheckOutDate, "DF=yyyy-MM-dd"));
		vJSON.WritePropertyName("guestLanguage");
		vJSON.WriteValue(pAccommodation.Guest.Language.Code);
		vJSON.WritePropertyName("roomShare");
		vJSON.WriteValue(vRoomShare);
		vJSON.WritePropertyName("swapFlag");
		vJSON.WriteValue("0");
		vJSON.WritePropertyName("nopost");
		vJSON.WriteValue(vNoPost);
		vJSON.WritePropertyName("profileNum");
		vJSON.WriteValue(Left(pAccommodation.Guest.Code,10));
		If pAdditional <> Undefined Then
			vJSON.WritePropertyName("additional");
			vJSON.WriteStartObject();
			vJSON.WritePropertyName("a0");
			vJSON.WriteValue(GetExtraParameters(pAdditional["a0"], pAccommodation));
			vJSON.WritePropertyName("a1");
			vJSON.WriteValue(GetExtraParameters(pAdditional["a1"], pAccommodation));
			vJSON.WritePropertyName("a2");
			vJSON.WriteValue(GetExtraParameters(pAdditional["a2"], pAccommodation));
			vJSON.WritePropertyName("a3");
			vJSON.WriteValue(GetExtraParameters(pAdditional["a3"], pAccommodation));
			vJSON.WritePropertyName("a4");
			vJSON.WriteValue(GetExtraParameters(pAdditional["a4"], pAccommodation)); 
			vJSON.WritePropertyName("a5");
			vJSON.WriteValue(GetExtraParameters(pAdditional["a5"], pAccommodation)); 
			vJSON.WritePropertyName("a6");
			vJSON.WriteValue(GetExtraParameters(pAdditional["a6"], pAccommodation)); 
			vJSON.WritePropertyName("a7");
			vJSON.WriteValue(GetExtraParameters(pAdditional["a7"], pAccommodation)); 
			vJSON.WritePropertyName("a8");
			vJSON.WriteValue(GetExtraParameters(pAdditional["a8"], pAccommodation)); 
			vJSON.WritePropertyName("a9");
			vJSON.WriteValue(GetExtraParameters(pAdditional["a9"], pAccommodation));
			vJSON.WriteEndObject();
		EndIf;	
	vJSON.WriteEndObject();
	
	vResult = vJSON.Close();

	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
Function GetJSON_CheckOut(pInteractionParameters, pHotelID, pAccommodation)
	vResult = "";	
	vGuestCount = GetGuestsCount(pAccommodation);
	If vGuestCount > 0 Then
		vRoomShare 	= "1";
	Else
		vRoomShare 	= "0";	
	EndIf;
		
	vJSON 					= New JSONWriter;
	vJSON.ValidateStructure = False;
	vJSON.SetString();
	
	vJSON.WriteStartObject();
		vJSON.WritePropertyName("hotelId");
		vJSON.WriteValue(pHotelID);
		vJSON.WritePropertyName("roomNumber");
		vJSON.WriteValue(Left(cmGetObjectExternalSystemCodeByRef(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, "Rooms", pAccommodation.Room), 10));
		vJSON.WritePropertyName("pmsRegNum");
		vJSON.WriteValue(Left(pAccommodation.Number, 20));
		vJSON.WritePropertyName("roomShare");
		vJSON.WriteValue(vRoomShare);
		vJSON.WritePropertyName("swapFlag");
		vJSON.WriteValue("0");	
	vJSON.WriteEndObject();
	
	vResult = vJSON.Close();

	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
Function GetJSON_ClientDataChange(pInteractionParameters, pHotelID, pAccommodation, pOldRoom = Undefined, pNoPost = Undefined, pAdditional = Undefined)
	vResult = "";	
	vGuestCount = GetGuestsCount(pAccommodation);
	If vGuestCount > 0 Then
		vRoomShare 	= "1";
	Else
		vRoomShare 	= "0";	
	EndIf;
	
	If pNoPost <> Undefined And pNoPost = "0" Then 
		vActiveFolios = GetActiveFolios(pAccommodation);
		If vActiveFolios.Count() > 0 Then 
			vNoPost = "0";
		Else
			vNoPost = "1";
		EndIf;
	ElsIf pNoPost = "1" Then
		vNoPost = "1";
	Else
		vNoPost = Undefined;
	EndIf;
	
	vJSON = New JSONWriter;
	vJSON.ValidateStructure = False;
	vJSON.SetString();
	
	vJSON.WriteStartObject();
		vJSON.WritePropertyName("hotelId");
		vJSON.WriteValue(pHotelID);
		vJSON.WritePropertyName("roomNumber");
		vJSON.WriteValue(Left(cmGetObjectExternalSystemCodeByRef(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, "Rooms", pAccommodation.Room), 10));  
		If pOldRoom <> Undefined Then 
			vJSON.WritePropertyName("oldRoom");
			vJSON.WriteValue(Left(cmGetObjectExternalSystemCodeByRef(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, "Rooms", pOldRoom), 10));
		EndIf;
		
		vJSON.WritePropertyName("guestName");
		vJSON.WriteValue(Left(pAccommodation.Guest.LastName, 40));
		vJSON.WritePropertyName("guestFirstName");
		vJSON.WriteValue(Left(pAccommodation.Guest.FirstName, 40));
		vJSON.WritePropertyName("guestTitle");
		vJSON.WriteValue(Left(pAccommodation.Guest.Salutation.Description, 10));
		vJSON.WritePropertyName("guestLanguage");
		vJSON.WriteValue(pAccommodation.Guest.Language.Code);

		vJSON.WritePropertyName("pmsRegNum");
		vJSON.WriteValue(Left(pAccommodation.Number, 20));
		vJSON.WritePropertyName("departureDate");
		vJSON.WriteValue(Format(pAccommodation.CheckOutDate, "DF=yyyy-MM-dd"));
		vJSON.WritePropertyName("roomShare");
		vJSON.WriteValue(vRoomShare);
		vJSON.WritePropertyName("swapFlag");
		vJSON.WriteValue("0");
		If vNoPost <> Undefined Then
			vJSON.WritePropertyName("nopost");
			vJSON.WriteValue(vNoPost);
		EndIf;
		vJSON.WritePropertyName("profileNum");
		vJSON.WriteValue(Left(pAccommodation.Guest.Code,10));
		If pAdditional <> Undefined Then
			vJSON.WritePropertyName("additional");
			vJSON.WriteStartObject();
			vJSON.WritePropertyName("a0");
			vJSON.WriteValue(GetExtraParameters(pAdditional["a0"], pAccommodation));
			vJSON.WritePropertyName("a1");
			vJSON.WriteValue(GetExtraParameters(pAdditional["a1"], pAccommodation));
			vJSON.WritePropertyName("a2");
			vJSON.WriteValue(GetExtraParameters(pAdditional["a2"], pAccommodation));
			vJSON.WritePropertyName("a3");
			vJSON.WriteValue(GetExtraParameters(pAdditional["a3"], pAccommodation));
			vJSON.WritePropertyName("a4");
			vJSON.WriteValue(GetExtraParameters(pAdditional["a4"], pAccommodation)); 
			vJSON.WritePropertyName("a5");
			vJSON.WriteValue(GetExtraParameters(pAdditional["a5"], pAccommodation)); 
			vJSON.WritePropertyName("a6");
			vJSON.WriteValue(GetExtraParameters(pAdditional["a6"], pAccommodation)); 
			vJSON.WritePropertyName("a7");
			vJSON.WriteValue(GetExtraParameters(pAdditional["a7"], pAccommodation)); 
			vJSON.WritePropertyName("a8");
			vJSON.WriteValue(GetExtraParameters(pAdditional["a8"], pAccommodation)); 
			vJSON.WritePropertyName("a9");
			vJSON.WriteValue(GetExtraParameters(pAdditional["a9"], pAccommodation));
			vJSON.WriteEndObject();
		EndIf;
	vJSON.WriteEndObject();
	
	vResult = vJSON.Close();
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
Function GetJSON_ReadMessages(pInteractionParameters, pHotelID, pAccommodation, pMessages)
	vResult 				= "";		
	vJSON 					= New JSONWriter;
	vJSON.ValidateStructure = False;
	vJSON.SetString();
	
	vJSON.WriteStartObject();
		vJSON.WritePropertyName("hotelId");
		vJSON.WriteValue(pHotelID);
		vJSON.WritePropertyName("roomNumber");
		vJSON.WriteValue(Left(cmGetObjectExternalSystemCodeByRef(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, "Rooms", pAccommodation.Room), 10));
		vJSON.WritePropertyName("pmsRegNum");
		vJSON.WriteValue(Left(pAccommodation.Number, 20));
		vJSON.WriteStartObject();
		vJSON.WritePropertyName("messages");
			vJSON.WriteStartArray();
			For Each vMessage In pMessages Do
				vJSON.WriteStartObject();
				vJSON.WritePropertyName("text");
				vJSON.WriteValue(vMessage.Text);
				vJSON.WritePropertyName("dateTime");
				vJSON.WriteValue(Format(vMessage.dateTime, "DF='yyyy-MM-dd HH:mm:ss'"));
				vJSON.WriteEndObject();
			EndDo;
			vJSON.WriteEndArray();
		vJSON.WriteEndObject();
	vJSON.WriteEndObject();
	
	vResult = vJSON.Close();
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
Function GetJSON_WakeUpCall(pInteractionParameters, pHotelID, pAccommodation, pDate)
	vResult 				= "";		
	vJSON 					= New JSONWriter;
	vJSON.ValidateStructure = False;
	vJSON.SetString();
	
	vJSON.WriteStartObject();
		vJSON.WritePropertyName("hotelId");
		vJSON.WriteValue(pHotelID);
		vJSON.WritePropertyName("roomNumber");
		vJSON.WriteValue(Left(cmGetObjectExternalSystemCodeByRef(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, "Rooms", pAccommodation.Room), 10));
		vJSON.WritePropertyName("dateTime");
		vJSON.WriteValue(Format(pDate, "DF='yyyy-MM-dd HH:mm:ss'"));			
	vJSON.WriteEndObject();
	
	vResult = vJSON.Close();
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
Function GetJSON_Bill(pInteractionParameters, pHotelID, pAccommodation, pExtSystemCode, pMultiplyFactor)
	vResult 				= "";
	vBills 					= GetGuestFoliosWithTransactions(pAccommodation, pExtSystemCode);
	vMultiplyFactor = pMultiplyFactor;
	If vMultiplyFactor = 0 Then
		vMultiplyFactor = 1;		
	EndIf;
	vJSON 					= New JSONWriter;
	vJSON.ValidateStructure = False;
	vJSON.SetString();
	
	vJSON.WriteStartObject();
		vJSON.WritePropertyName("hotelId");
		vJSON.WriteValue(pHotelID);
		vJSON.WritePropertyName("roomNumber");
		vJSON.WriteValue(Left(cmGetObjectExternalSystemCodeByRef(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, "Rooms", pAccommodation.Room), 10));
		vJSON.WritePropertyName("pmsRegNum");
		vJSON.WriteValue(Left(pAccommodation.Number, 20));
		vJSON.WritePropertyName("billTotal");
		vJSON.WriteValue(Format(vBills.billTotal * vMultiplyFactor, "NG="));
		vJSON.WritePropertyName("billItems");
		vJSON.WriteStartArray();
			For Each vBill In vBills.billItems Do
				vJSON.WriteStartObject();
				vJSON.WritePropertyName("posId");
				vJSON.WriteValue(Left(vBill.posId, 10));
				vJSON.WritePropertyName("itemAmount");
				vJSON.WriteValue(vBill.itemAmount * vMultiplyFactor);
				vJSON.WritePropertyName("itemDateTime");
				vJSON.WriteValue(Format(vBill.itemDateTime, "DF='yyyy-MM-dd HH:mm:ss'"));
				vJSON.WritePropertyName("itemDescription");
				vJSON.WriteValue(vBill.itemDescription);
				vJSON.WriteEndObject();
			EndDo;
		vJSON.WriteEndArray();
	vJSON.WriteEndObject();
	
	vResult = vJSON.Close();
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
Function GetJSON_DND(pInteractionParameters, pHotelID, pAccommodation, pDND)
	vResult 				= "";	
	vJSON 					= New JSONWriter;
	vJSON.ValidateStructure = False;
	vJSON.SetString();
	
	vJSON.WriteStartObject();
		vJSON.WritePropertyName("hotelId");
		vJSON.WriteValue(pHotelID);
		vJSON.WritePropertyName("roomNumber");
		vJSON.WriteValue(Left(cmGetObjectExternalSystemCodeByRef(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, "Rooms", pAccommodation.Room), 10));
		vJSON.WritePropertyName("pmsRegNum");
		vJSON.WriteValue(Left(pAccommodation.Number, 20));
		vJSON.WritePropertyName("dnd");
		vJSON.WriteValue(pDND);			
	vJSON.WriteEndObject();
	
	vResult = vJSON.Close();
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
Function GetJSON_Rights(pInteractionParameters, pHotelID, pAccommodation, pRights)
	vResult 				= "";	
	vJSON 					= New JSONWriter;
	vJSON.ValidateStructure = False;
	vJSON.SetString();
	
	vJSON.WriteStartObject();
		vJSON.WritePropertyName("hotelId");
		vJSON.WriteValue(pHotelID);
		vJSON.WritePropertyName("roomNumber");
		vJSON.WriteValue(Left(cmGetObjectExternalSystemCodeByRef(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, "Rooms", pAccommodation.Room), 10));
		vJSON.WritePropertyName("pmsRegNum");
		vJSON.WriteValue(Left(pAccommodation.Number, 20));
		vJSON.WritePropertyName("rights");
		vJSON.WriteValue(pRights);			
	vJSON.WriteEndObject();
	
	vResult = vJSON.Close();
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
Function GetJSON_SaleDone(pInteractionParameters, pHotelID, pSale)
	vResult 				= "";	
	vJSON 					= New JSONWriter;
	vJSON.ValidateStructure = False;
	vJSON.SetString();
	
	vJSON.WriteStartObject();
		vJSON.WritePropertyName("hotelId");
		vJSON.WriteValue(pHotelID);
		vJSON.WritePropertyName("roomNumber");
		vJSON.WriteValue(Left(cmGetObjectExternalSystemCodeByRef(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, "Rooms", pSale.Room), 10));
		vJSON.WritePropertyName("status");
		vJSON.WriteValue(pSale.status);
		vJSON.WritePropertyName("posId");
		vJSON.WriteValue(pSale.posId);
		vJSON.WritePropertyName("dateTime");
		vJSON.WriteValue(Format(pSale.dateTime, "DF='yyyy-MM-dd  hh:mm:ss'"));
		vJSON.WritePropertyName("checkNum");
		vJSON.WriteValue(pSale.checkNum);
		vJSON.WritePropertyName("text");
		vJSON.WriteValue(pSale.text);
	vJSON.WriteEndObject();
	
	vResult = vJSON.Close();
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
Function GetJSON_XprsCheckOut(pInteractionParameters, pHotelID, pAccommodation, pCheckOut)
	vResult 				= "";	
	vJSON 					= New JSONWriter;
	vJSON.ValidateStructure = False;
	vJSON.SetString();
	
	vJSON.WriteStartObject();
		vJSON.WritePropertyName("hotelId");
		vJSON.WriteValue(pHotelID);
		vJSON.WritePropertyName("roomNumber");
		vJSON.WriteValue(Left(cmGetObjectExternalSystemCodeByRef(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, "Rooms", pAccommodation.Room), 10));
		vJSON.WritePropertyName("pmsRegNum");
		vJSON.WriteValue(Left(pCheckOut.pmsRegNum, 20));
		vJSON.WritePropertyName("status");
		vJSON.WriteValue(pCheckOut.status);
		vJSON.WritePropertyName("balance");
		vJSON.WriteValue(pCheckOut.balance);
		vJSON.WritePropertyName("text");
		vJSON.WriteValue(pCheckOut.text);
		vJSON.WritePropertyName("datetime");
		vJSON.WriteValue(pCheckOut.datetime);
	vJSON.WriteEndObject();
	
	vResult = vJSON.Close();
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
Function FindRoomInterfaceTypes(pTurnOnParameters, pTurnOffParameters, pHotel)

	vResult = Undefined;
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT TOP 1
		|	RoomInterfaceTypes.Ref AS Ref
		|FROM
		|	Catalog.RoomInterfaceTypes AS RoomInterfaceTypes
		|WHERE
		|	CASE
		|			WHEN &qTurnOnFilled
		|				THEN RoomInterfaceTypes.TurnOnParameters LIKE &qTurnOnParameters
		|			ELSE TRUE
		|		END
		|	AND CASE
		|			WHEN &qTurnOffFilled
		|				THEN RoomInterfaceTypes.TurnOffParameters LIKE &qTurnOffParameters
		|			ELSE TRUE
		|		END
		|	AND NOT RoomInterfaceTypes.DeletionMark
		|	AND (RoomInterfaceTypes.Hotel = &qEmptyHotel
		|			OR RoomInterfaceTypes.Hotel = &qHotel)";
	
	vQuery.SetParameter("qTurnOffFilled", 		ValueIsFilled(pTurnOffParameters));
	vQuery.SetParameter("qTurnOffParameters", 	pTurnOffParameters);
	vQuery.SetParameter("qTurnOnFilled", 		ValueIsFilled(pTurnOnParameters));
	vQuery.SetParameter("qTurnOnParameters", 	pTurnOnParameters);
	vQuery.SetParameter("qHotel", 	pHotel);
	vQuery.SetParameter("qEmptyHotel", 	Catalogs.Hotels.EmptyRef());

	vQueryResult = vQuery.Execute().Unload();
	
	For Each vRow In vQueryResult Do
		vResult = vRow.Ref;
	EndDo;
	
	Return vResult;
EndFunction

// -------------------------------------------------------------------------------- 
Function GetDNDRoomInterfaceStatus(pAccommodation)
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	RoomInterfaceStatus.Ref AS Ref
		|FROM
		|	Document.RoomInterfaceStatus AS RoomInterfaceStatus
		|WHERE
		|	NOT RoomInterfaceStatus.DeletionMark
		|	AND RoomInterfaceStatus.RoomInterfaceType.TurnOnParameters LIKE ""DND""
		|	AND RoomInterfaceStatus.ParentDoc = &qParentDoc
		|	AND RoomInterfaceStatus.IsProcessed
		|	AND NOT RoomInterfaceStatus.IsCanceled";
	
	vQuery.SetParameter("qParentDoc", pAccommodation);
	
	Return vQuery.Execute().Unload();
EndFunction

// --------------------------------------------------------------------------------
Function GetRoomInterfaceStatus(pAccommodation, pTurnOnParameters = Undefined, pTurnOffParameters = Undefined, pMessageTime = Undefined)
	vResult = Undefined;
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	RoomInterfaceStatus.Ref AS Ref
		|FROM
		|	Document.RoomInterfaceStatus AS RoomInterfaceStatus
		|WHERE
		|	CASE
		|			WHEN &qDateTimeFilled
		|				THEN RoomInterfaceStatus.MessageDateTime = &qMessageDateTime
		|			ELSE TRUE
		|		END
		|	AND RoomInterfaceStatus.ParentDoc = &qParentDoc
		|	AND CASE
		|			WHEN &qTurnOnFilled
		|				THEN RoomInterfaceStatus.RoomInterfaceType.TurnOnParameters LIKE &qTurnOnParameters
		|			ELSE TRUE
		|		END
		|	AND CASE
		|			WHEN &qTurnOffFilled
		|				THEN RoomInterfaceStatus.RoomInterfaceType.TurnOffParameters LIKE &qTurnOffParameters
		|			ELSE TRUE
		|		END
		|	AND NOT RoomInterfaceStatus.DeletionMark";
	
	vQuery.SetParameter("qParentDoc", 			pAccommodation);
	vQuery.SetParameter("qMessageDateTime", 	pMessageTime);
	vQuery.SetParameter("qTurnOnParameters", 	pTurnOnParameters);
	vQuery.SetParameter("qTurnOffParameters", 	pTurnOffParameters);
	vQuery.SetParameter("qDateTimeFilled", 		ValueIsFilled(pMessageTime));
	vQuery.SetParameter("qTurnOnFilled", 		ValueIsFilled(pTurnOnParameters));
	vQuery.SetParameter("qTurnOffFilled", 		ValueIsFilled(pTurnOffParameters));
	vQueryResult = vQuery.Execute().Unload();
	
	For Each vRow In vQueryResult Do
		vResult = vRow.Ref;
	EndDo;
	
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
Function GetAccommodationByRoomAndDate(pInteractionParameters, pRoom, pDate = Undefined)
	vResult = Undefined;
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT TOP 1
		|	Accommodation.Ref AS Ref
		|FROM
		|	Document.Accommodation AS Accommodation
		|WHERE
		|	NOT Accommodation.DeletionMark
		|	AND Accommodation.Posted
		|	AND Accommodation.Room = &qRoom
		|	AND Accommodation.AccommodationStatus.IsActive
		|	AND Accommodation.AccommodationStatus.IsInHouse
		|	AND CASE
		|			WHEN &qDateFilled
		|				THEN &qDate BETWEEN Accommodation.CheckInDate AND Accommodation.CheckOutDate
		|			ELSE TRUE
		|		END
		|
		|ORDER BY
		|	Accommodation.Date DESC";
	
	vQuery.SetParameter("qDate", pDate);
	vQuery.SetParameter("qDateFilled", ValueIsFilled(pDate));
	vQuery.SetParameter("qRoom", cmGetObjectRefByExternalSystemCode(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, "Rooms", pRoom));
	
	vQueryResult = vQuery.Execute().Unload();
	For Each vRow In vQueryResult Do
		vResult = vRow.Ref;	
	EndDo;
	
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
Function GetOldRoom(pAccommodation, pChangeDate)
	vResult = pAccommodation.Room.Description;
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	AccommodationChangeHistory.Date AS Date,
		|	AccommodationChangeHistory.Room AS Room
		|FROM
		|	InformationRegister.AccommodationChangeHistory AS AccommodationChangeHistory
		|WHERE
		|	AccommodationChangeHistory.Accommodation = &qAccommodation
		|	AND AccommodationChangeHistory.Date <= &qDate
		|
		|ORDER BY
		|	Date";
	
	vQuery.SetParameter("qAccommodation", pAccommodation);
	vQuery.SetParameter("qDate", pChangeDate);

	vQueryResult = vQuery.Execute().Unload();
	For Each vRow In vQueryResult Do
		If vRow.Room <> pAccommodation.Room Then
			vResult = vRow.Room.Description; 
		EndIf;
	EndDo;
	
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
Function GetResponseCodeDescription(pMethodName, pCode)
	vResult = "";
	If pMethodName = "pmsconnect/saledone" Then
		If	pCode = "0" Then
			vResult = "Success (OK)";
		ElsIf pCode = "1" Then
			vResult = "Posting denied because overwriting the CreditLimit is not allowed (CO)";
		ElsIf pCode = "2" Then
			vResult = "Sum of subtotals doesn't match TotalAmount (DM)";
		ElsIf pCode = "3" Then
			vResult = "Posting denied for this guest (NoPost flag has been set) (NP)";
		ElsIf pCode = "4" Then
			vResult = "Retry (RY)";
		ElsIf pCode = "9" Then 
			vResult = "Unprocessable request, this request cannot be carried out, no retry (UR)";
		Else
			vResult = "Unknown response code";
		EndIf;
	ElsIf pMethodName = "pmsconnect/clearwakeupcall" Then 
		If pCode = "3" Then
			vResult = "Wakeup Call service not found";
		EndIf;
	ElsIf pMethodName = "pmsconnect/xprscheckout" Then
		If	pCode = "0" Then
			vResult = "Success (OK)";
		ElsIf pCode = "1" Then
			vResult = "Balance mismatch (BM)";
		ElsIf pCode = "2" Then
			vResult = "Check‑out date is not today (CD)";
		ElsIf pCode = "3" Then
			vResult = "Feature not enabled or Check‑out process not running (NF)";
		ElsIf pCode = "4" Then
			vResult = "Guest not found (NG)";
		ElsIf pCode = "5" Then
			vResult = "Retry (RY)";
		ElsIf pCode = "6" Then
			vResult = "Guest not allowed this feature (FX)";
		ElsIf pCode = "7" Then
			vResult = "Invalid account (IA)";
			
		ElsIf pCode = "9" Then 
			vResult = "Unprocessable request, this request cannot be carried out, no retry (UR)";
		Else
			vResult = "Unknown response code";
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(vResult) Then
		If	pCode = "0" Then
	    	vResult = "Success";
		ElsIf pCode = "1" Then
			vResult = "Hotel not found";
		ElsIf pCode = "2" Then
			vResult = "Guest not found";
		ElsIf pCode = "3" Then
			vResult = "Incorrect request data";
		ElsIf pCode = "9" Then 
			vResult = "Incorrect data";
		Else
			vResult = "Unknown response code";
		EndIf;
	EndIf;
	
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
Function GetDocsToSync(pHotel, pPeriodFrom = Undefined, pPeriodTo = Undefined)
	
	If ValueIsFilled(pPeriodFrom) And Not ValueIsFilled(pPeriodTo) Then
		pPeriodTo = CurrentSessionDate();
	EndIf;
	
	vQ = New Query;
	vQ.Text = "SELECT
	          |	RoomInterfaceStatus.Ref AS Ref,
	          |	RoomInterfaceStatus.RoomInterfaceType.TurnOnParameters AS TurnOnParameters,
	          |	RoomInterfaceStatus.RoomInterfaceType.TurnOffParameters AS TurnOffParameters,
	          |	RoomInterfaceStatus.ParentDoc AS ParentDoc,
	          |	RoomInterfaceStatus.Hotel AS Hotel,
	          |	RoomInterfaceStatus.Room AS Room,
	          |	RoomInterfaceStatus.Remarks AS Remarks,
	          |	RoomInterfaceStatus.IsProcessed AS IsProcessed,
	          |	RoomInterfaceStatus.IsCanceled AS IsCanceled,
	          |	RoomInterfaceStatus.Message AS Message,
	          |	RoomInterfaceStatus.CancellationMessage AS CancellationMessage,
	          |	RoomInterfaceStatus.Date AS Date,
	          |	RoomInterfaceStatus.InterfaceType AS InterfaceType,
	          |	RoomInterfaceStatus.MessageDateTime AS MessageDateTime,
	          |	RoomInterfaceStatus.RoomInterfaceType.PeriodOfStayExtentionParameters AS PeriodOfStayExtentionParameters,
	          |	RoomInterfaceStatus.RoomInterfaceType.GuestNameChangeParameters AS GuestNameChangeParameters,
	          |	RoomInterfaceStatus.PeriodOfStayExtensionIsRequested AS PeriodOfStayExtensionIsRequested,
	          |	RoomInterfaceStatus.GuestNameChangeIsRequested AS GuestNameChangeIsRequested,
	          |	RoomInterfaceStatus.ExtraParameters AS ExtraParameters,
	          |	CASE
	          |		WHEN RoomInterfaceStatus.RoomChangeIsRequested
	          |			THEN RoomInterfaceStatus.OldRoom
	          |		ELSE UNDEFINED
	          |	END AS OldRoom,
	          |	RoomInterfaceStatus.RoomChangeIsRequested AS RoomChangeIsRequested,
	          |	RoomInterfaceStatus.ExtraParametersChangeIsRequested AS ExtraParametersChangeIsRequested,
	          |	RoomInterfaceStatus.RoomInterfaceType.CommandToChangeExtraParameters AS CommandToChangeExtraParameters,
	          |	RoomInterfaceStatus.RoomInterfaceType.RoomChangeParameters AS RoomChangeParameters
	          |FROM
	          |	Document.RoomInterfaceStatus AS RoomInterfaceStatus
	          |WHERE
	          |	RoomInterfaceStatus.IsProcessed = &qIsProcessed
	          |	AND NOT RoomInterfaceStatus.DeletionMark
	          |	AND RoomInterfaceStatus.RoomInterfaceType.InterfaceType = &qInterfaceType
	          |	AND RoomInterfaceStatus.Hotel = &qHotel
	          |	AND CASE
	          |			WHEN &qIsProcessed
	          |				THEN RoomInterfaceStatus.Date BETWEEN &qPeriodFrom AND &qPeriodTo
	          |						OR RoomInterfaceStatus.CancellationDate BETWEEN &qPeriodFrom AND &qPeriodTo
	          |			ELSE TRUE
	          |		END
	          |
	          |ORDER BY
	          |	Date";
	vQ.SetParameter("qInterfaceType", Enums.InterfaceTypes.TV);
	vQ.SetParameter("qHotel", pHotel);
	vQ.SetParameter("qIsProcessed", ValueIsFilled(pPeriodFrom));
	vQ.SetParameter("qPeriodFrom", pPeriodFrom);
	vQ.SetParameter("qPeriodTo", pPeriodTo);
	Return vQ.Execute().Unload();
EndFunction

// --------------------------------------------------------------------------------
Function GetGuestsCount(pAccommodation)
	vQry = New Query;
	vQry.Text = "SELECT
	            |	Accommodation.Ref AS Ref,
	            |	Accommodation.Guest AS GuestRef,
	            |	Accommodation.Guest.FullName AS Guest,
	            |	Accommodation.AccommodationType AS AccommodationType,
	            |	Accommodation.HotelProduct AS HotelProduct,
	            |	0 AS AnnulReserv,
	            |	FALSE AS IsStatusChanged,
	            |	FALSE AS IsAnnulation,
	            |	TRUE AS IsGuest,
	            |	&qEmptyAccommodationStatusRef AS AccommodationStatus,
	            |	Accommodation.Guest.FullName AS LastGuestFullName,
	            |	Accommodation.GuestCitizenship AS GuestCitizenship,
	            |	FALSE AS RoomRateIsDifferent,
	            |	FALSE AS DiscountsAreDifferent,
	            |	FALSE AS ManualPricesAreDifferent,
	            |	FALSE AS ServicePackagesAreDifferent,
	            |	FALSE AS RoomRatesAreDifferent,
	            |	FALSE AS CheckInDateIsDifferent,
	            |	FALSE AS CheckOutDateIsDifferent,
	            |	&qEmptyString AS ChangesDescription
	            |FROM
	            |	Document.Accommodation AS Accommodation
	            |WHERE
	            |	Accommodation.GuestGroup = &qGroup
	            |	AND (Accommodation.Room = &qRoom
	            |				AND &qRoomIsFilled
	            |			OR Accommodation.Number = &qNumber
	            |				AND NOT &qRoomIsFilled)
	            |	AND Accommodation.Ref <> &qAccRef
	            |	AND Accommodation.Posted
	            |	AND (Accommodation.AccommodationStatus.IsActive
	            |			OR Accommodation.AccommodationStatus = &qAccStatus)
	            |	AND Accommodation.CheckOutDate > &qAccCheckIn
	            |	AND Accommodation.CheckInDate < &qAccCheckOut
	            |
	            |ORDER BY
	            |	Accommodation.AccommodationType.SortCode";
	vQry.SetParameter("qGroup", pAccommodation.GuestGroup);
	vQry.SetParameter("qRoom", pAccommodation.Room);
	vQry.SetParameter("qAccRef", pAccommodation.Ref);
	vQry.SetParameter("qAccCheckIn", pAccommodation.CheckInDate);
	vQry.SetParameter("qAccCheckOut", pAccommodation.CheckOutDate);
	vQry.SetParameter("qAccStatus", pAccommodation.AccommodationStatus);
	vQry.SetParameter("qRoomIsFilled", ValueIsFilled(pAccommodation.Room));
	vQry.SetParameter("qNumber", pAccommodation.Number);
	vQry.SetParameter("qEmptyAccommodationStatusRef", Catalogs.AccommodationStatuses.EmptyRef());
	vQry.SetParameter("qEmptyString", "");
	vQryResult = vQry.Execute().Unload();
	
	Return vQryResult.Count(); 
EndFunction

// --------------------------------------------------------------------------------
Function GetActiveFolios(pAccommodation)
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	Folio.Ref AS Ref
		|FROM
		|	Document.Folio AS Folio
		|WHERE
		|	NOT Folio.IsClosed
		|	AND NOT Folio.DeletionMark
		|	AND Folio.Posted
		|	AND Folio.ParentDoc = &qParentDoc";
	
	vQuery.SetParameter("qParentDoc", pAccommodation);
	
	vQueryResult = vQuery.Execute().Unload();
	Return vQueryResult; 
EndFunction

// --------------------------------------------------------------------------------
Function GetGuestFoliosWithTransactions(pAccommodation, pExtSystemCode)
	// Check that accommodation is in-house or check-out was today
	If TypeOf(pAccommodation) = Type("DocumentRef.Accommodation") Then
		If Not pAccommodation.Posted Or Not pAccommodation.AccommodationStatus.IsActive Or Not pAccommodation.AccommodationStatus.IsInHouse 
			And BegOfDay(pAccommodation.CheckOutDate) < BegOfDay(CurrentSessionDate()) Then
			Raise NStr("en='Guest is not in-house!'; ru='Гость не проживает!'; de='Gast nicht in-house!'");
		EndIf;
		vGuest = pAccommodation.Guest;
	ElsIf TypeOf(pAccommodation) = Type("DocumentRef.Reservation") Then
		If Not pAccommodation.Posted Or Not pAccommodation.ReservationStatus.IsActive Then
			Raise NStr("en='Reservation is canceled!'; ru='Бронь не активна!'; de='Die Reservierung ist storniert!'");
		EndIf;
		vGuest = pAccommodation.Guest;
	ElsIf TypeOf(pAccommodation) = Type("DocumentRef.ResourceReservation") Then
		If Not pAccommodation.Posted Or Not pAccommodation.ResourceReservationStatus.IsActive Or pAccommodation.ResourceReservationStatus.ServicesAreDelivered 
			And BegOfDay(pAccommodation.DateTimeTo) < BegOfDay(CurrentSessionDate()) Then
			Raise NStr("en='Clinet is not in-house!'; ru='Мероприятие уже закончено!'; de='Kunde nicht in-house!'");
		EndIf;
		vGuest = pAccommodation.Client;
	EndIf;
	If Not ValueIsFilled(vGuest) Then
		Raise NStr("en='Guest info is not in the system yet! Please wait a bit and try again...'; 
		           |ru='Данные гостя еще не занесены в систему! Пожалуйста подождите немного и попробуйте еще раз...'; 
				   |de='Gäste-Info ist nicht im System noch nicht! Bitte warten Sie ein wenig und versuchen Sie es erneut...'");
	EndIf;
	
	vResult 				= New Structure("billTotal, billItems", 0, Undefined);
	vFolioTransactionItems 	= New ValueTable;
	vFolioTransactionItems.Columns.Add("posId");
	vFolioTransactionItems.Columns.Add("itemAmount");
	vFolioTransactionItems.Columns.Add("itemDateTime");
	vFolioTransactionItems.Columns.Add("itemDescription");
	
	vLanguage = vGuest.Language;
	// Fill guest info
	vClientBalance = 0;
	vCreditLimit = 0;
	vRepCurrencyCode = "";
	If ValueIsFilled(pAccommodation.ReportingCurrency) Then
		vRepCurrencyCode = TrimAll(pAccommodation.ReportingCurrency.Code);
	EndIf;

	// Get document folios
	// Build and run query
	vFoliosCounter = 0;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Folio.Ref AS Folio
	|FROM
	|	Document.Folio AS Folio
	|WHERE
	|	Folio.ParentDoc.Number = &qDocNumber
	|	AND Folio.GuestGroup = &qGuestGroup
	|	AND NOT Folio.DeletionMark
	|
	|ORDER BY
	|	Folio.PointInTime";
	vQry.SetParameter("qDocNumber", pAccommodation.Number);
	vQry.SetParameter("qGuestGroup", pAccommodation.GuestGroup);
	vAccFolios = vQry.Execute().Unload();
	For Each vAccFoliosRow In vAccFolios Do
		
		vFolioRef = vAccFoliosRow.Folio;
		If TypeOf(pAccommodation) = Type("DocumentRef.Accommodation") Or TypeOf(pAccommodation) = Type("DocumentRef.Reservation") Then
			If ValueIsFilled(vFolioRef.Customer) And Not vFolioRef.Customer.IsIndividual Then
				Continue;
			EndIf;
		EndIf;
		
		vFolioObj = vFolioRef.GetObject();
		vFolioPreauthLimit = 0;
		vFolioBalance = vFolioObj.pmGetBalance(Undefined, pAccommodation.Hotel, Undefined, vFolioPreauthLimit);
		vFolioBalance = 0;
		vFoliosCounter = vFoliosCounter + 1;
		
		vTrans = vFolioObj.pmGetAllFolioTransactions();
		For Each vTransRow In vTrans Do
			If vTransRow.RecordType = AccumulationRecordType.Receipt And vTransRow.Sum = 0 Then
				Continue;
			ElsIf vTransRow.RecordType = AccumulationRecordType.Expense And vTransRow.PaymentMethod = Catalogs.PaymentMethods.Settlement Then
				Continue;
			EndIf;
				
			vFolioTransactionItem = New Structure("Type, Date, Description, Quantity, Unit, Price, Discount, DiscountSum, Sum, Details");
			
			If vTransRow.RecordType = AccumulationRecordType.Expense Then
				If vTransRow.PaymentMethod = Catalogs.PaymentMethods.Settlement Then
					vFolioTransactionItem.Type = "Settlement";
				ElsIf vTransRow.Limit <> 0 Then
					vFolioTransactionItem.Type = "Preauthorization";
				ElsIf TypeOf(vTransRow.Document) = Type("DocumentRef.DepositTransfer") Then
					vFolioTransactionItem.Type = "DepositTransfer";
				ElsIf vTransRow.Sum < 0 Then
					vFolioTransactionItem.Type = "Return";
				Else
					vFolioTransactionItem.Type = "Payment";
				EndIf;
			Else
				If vTransRow.Sum < 0 Then
					vFolioTransactionItem.Type = "Storno";
				Else
					vFolioTransactionItem.Type = "Charge";
				EndIf;
			EndIf;
			vFolioTransactionItem.Date = vTransRow.Period;
			vFolioTransactionItem.Description = "";
			If vTransRow.RecordType = AccumulationRecordType.Expense Then
				If vTransRow.Limit <> 0 Then
					vFolioTransactionItem.Description = vFolioTransactionItem.Description + cmNStr("en='Preauthorization - '; ru='Преавторизация - '; de='Preauthorization - '", vLanguage);
					vFolioTransactionItem.Description = vFolioTransactionItem.Description + Catalogs.PaymentMethods.pmGetPaymentMethodDescription(vTransRow.PaymentMethod, vLanguage);
				ElsIf vFolioTransactionItem.Type = "DepositTransfer" Then
					vFolioTransactionItem.Description = vFolioTransactionItem.Description + cmNStr("en='Money transfer'; ru='Перенос денег'; de='Geldtransfer'", vLanguage);
				ElsIf vTransRow.Sum < 0 Then
					vFolioTransactionItem.Description = vFolioTransactionItem.Description + cmNStr("en='Return - '; ru='Возврат - '; de='Rückzahlung - '", vLanguage);
					vFolioTransactionItem.Description = vFolioTransactionItem.Description + Catalogs.PaymentMethods.pmGetPaymentMethodDescription(vTransRow.PaymentMethod, vLanguage);
				Else
					vFolioTransactionItem.Description = vFolioTransactionItem.Description + Catalogs.PaymentMethods.pmGetPaymentMethodDescription(vTransRow.PaymentMethod, vLanguage);
				EndIf;
				vFolioTransactionItem.Description = vFolioTransactionItem.Description + ?(IsBlankString(vTransRow.Remarks), "", " - " + TrimAll(vTransRow.Remarks));
				vFolioTransactionItem.Quantity = 0;
				vFolioTransactionItem.Unit = "";
				vFolioTransactionItem.Price = 0;
				vFolioTransactionItem.Discount = 0;
				vFolioTransactionItem.DiscountSum = 0;
				vFolioTransactionItem.Sum = ?(vTransRow.Limit <> 0, -vTransRow.Limit, -vTransRow.Sum);
				If vFolioTransactionItem.Type <> "DepositTransfer" Then
					vFolioTransactionItem.Details = ?(vTransRow.PaymentSum <> 0, ?(Not IsBlankString(vTransRow.Document.SlipText), TrimAll(vTransRow.Document.SlipText), ""), "");
				EndIf;
			Else
				If vTransRow.Sum < 0 Then
					vFolioTransactionItem.Description = vFolioTransactionItem.Description + cmNStr("en='Cancel - '; ru='Отмена - '; de='Storno - '", vLanguage);
				EndIf;
				vFolioTransactionItem.Description = vFolioTransactionItem.Description + Catalogs.Services.pmGetServiceDescription(vTransRow.Service, vLanguage);
				vFolioTransactionItem.Description = vFolioTransactionItem.Description + ?(IsBlankString(vTransRow.Remarks), "", " - " + TrimAll(vTransRow.Remarks));
				vFolioTransactionItem.Quantity = vTransRow.Quantity;
				vFolioTransactionItem.Unit = Catalogs.Services.pmGetServiceUnitDescription(vTransRow.Service, vLanguage);
				vFolioTransactionItem.Price = vTransRow.Price;
				vFolioTransactionItem.Discount = ?(ValueIsFilled(vTransRow.Charge), vTransRow.Charge.Discount, 0);
				vFolioTransactionItem.DiscountSum = vTransRow.Discount;
				vFolioTransactionItem.Sum = vTransRow.Sum;
				vFolioTransactionItem.Details = ?(ValueIsFilled(vTransRow.Charge), TrimAll(vTransRow.Charge.Details), "");
			EndIf;
			
			vNewResultRow = vFolioTransactionItems.Add();
			 
			If vTransRow.RecordType = AccumulationRecordType.Expense Then
				vNewResultRow.posId = "1"; // cmGetObjectExternalSystemCodeByRef(vFolioRef.Hotel, pExtSystemCode, "PaymentMethods", vTransRow.PaymentMethod); Hoteza сказали что не используют больше и слать 1. 
				If vTransRow.Limit <> 0 Then
					vFolioBalance = vFolioBalance - vTransRow.Limit;
					vNewResultRow.itemAmount = - vTransRow.Limit;
				Else
					vFolioBalance = vFolioBalance - vTransRow.Sum;
					vNewResultRow.itemAmount = - vTransRow.Sum;
				EndIf;
			Else
				vNewResultRow.posId = "1"; // cmGetObjectExternalSystemCodeByRef(vFolioRef.Hotel, pExtSystemCode, "Services", vTransRow.Service); Hoteza сказали что не используют больше и слать 1.
				vFolioBalance = vFolioBalance + vTransRow.Sum;
				vNewResultRow.itemAmount = vTransRow.Sum;
			EndIf;
			
			vNewResultRow.itemDateTime = vFolioTransactionItem.Date;
			vNewResultRow.itemDescription = vFolioTransactionItem.Description;
		EndDo;
		
		vFolioBalanceInRepCur = cmConvertCurrencies(vFolioBalance, vFolioObj.FolioCurrency, , pAccommodation.ReportingCurrency, , pAccommodation.ExchangeRateDate, pAccommodation.Hotel);
		vFolioCreditLimitInRepCur = cmConvertCurrencies(vFolioObj.CreditLimit, vFolioObj.FolioCurrency, , pAccommodation.ReportingCurrency, , pAccommodation.ExchangeRateDate, pAccommodation.Hotel);
		
		vClientBalance = vClientBalance + vFolioBalanceInRepCur;
		vCreditLimit = vCreditLimit + vFolioCreditLimitInRepCur;
	EndDo;
	vResult.billItems = vFolioTransactionItems;
	vResult.billTotal = vClientBalance;

	Return vResult;
EndFunction // GetGuestFoliosWithTransactions

// --------------------------------------------------------------------------------
Function GetExtraParameters(pExtraParameters, pAccommodation)
	If pExtraParameters <> Undefined Then
		If pExtraParameters = "Phone" Then
			If Not IsBlankString(pAccommodation.Phone) Then
				Return TrimAll(pAccommodation.Phone);	
			Else 
				vGuest = pAccommodation.Guest;
				If ValueIsFilled(vGuest) And Not IsBlankString(vGuest.Phone) Then
					Return TrimAll(vGuest.Phone);	
				Else
					Return "";	
				EndIf;
			EndIf;
		ElsIf pExtraParameters = "EMail" Then
			If Not IsBlankString(pAccommodation.EMail) Then
				Return TrimAll(pAccommodation.EMail);	
			Else 
				vGuest = pAccommodation.Guest;
				If ValueIsFilled(vGuest) And Not IsBlankString(vGuest.EMail) Then
					Return TrimAll(vGuest.EMail);	
				Else
					Return "";	
				EndIf;
			EndIf;	
		ElsIf pExtraParameters = "a4" Then // CheckOut time	 
			Return Format(pAccommodation.CheckOutDate, "DF=HH:MM");
		Else
			Return "";	
		EndIf;
	Else
		Return "";	
	EndIf;
EndFunction // GetExtraParameters

// ----------------------------------------------------------------------------
Function JSONToMap(pJSON)
	Try
		vJSONReader = New JSONReader();
		vJSONReader.SetString(pJSON);
		Return ReadJSON(vJSONReader, True);	
	Except
		Return New Map;	
	EndTry;	
EndFunction // MapToJSON

#EndRegion
 