#Region EventHandlers

// -------------------------------------------------------------------------
Function ppvstatusGET(pRequest)
	vBody = "";
	vInteractionParameters = Catalogs.ExternalSystemInteractions.EmptyRef();
	vInteractionParametersRows = cmGetInteractionByID("SamsungLYNK", False);	
	If vInteractionParametersRows.Count() > 0 Then
		vInteractionParameters = vInteractionParametersRows.Get(0).Ref; 	
	EndIf;
	If ValueIsFilled(vInteractionParameters) Then
		If vInteractionParameters.IsActive Then
			If ValueIsFilled(vInteractionParameters.Hotel) Then
				If ValueIsFilled(vInteractionParameters) And vInteractionParameters.DebugMode Then
					vMessage = NStr("en = 'Request'; de = 'Anfrage'; ru = 'Запрос'");
					If TypeOf(pRequest.Headers) = Type("FixedMap") Then
						vHeadersRequest = New Map(pRequest.Headers);
					Else
						vHeadersRequest = pRequest.Headers;		
					EndIf;
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteractionParameters, "SamsungLYNK.ppvstatusGET", Enums.ExternalSystemEventTypes.Info, vHeadersRequest, , vMessage);
				EndIf;
				vRoom = Catalogs.Rooms.EmptyRef();
				vRoomNumber = pRequest.Headers.Get("roomnumber");
				If vRoomNumber <> Undefined Then 
					vRoom = cmGetRoomByCode(vRoomNumber, vInteractionParameters.Hotel.Code, "SamsungLYNK");
					If ValueIsFilled(vRoom) Then
						vBody = SamsungLYNK.PPVStatus(vInteractionParameters, vRoom);
					Else
						vMsg = Nstr("en = 'Room not found'; de = 'Zimmer nicht gefunden'; ru = 'Номер не найден'");
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteractionParameters, "SamsungLYNK.Start", Enums.ExternalSystemEventTypes.Warning, , , vMsg);
						WriteLogEvent("HTTPServices.openapi.ppvstatusGET", EventLogLevel.Error,,CurrentSessionDate(), vMsg);	
					EndIf;
				Else
					vMsg = Nstr("en = 'Room code not transmitted'; de = 'Zimmer nicht übertragen'; ru = 'Не передан код номера'");
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteractionParameters, "SamsungLYNK.Start", Enums.ExternalSystemEventTypes.Warning, , , vMsg);
					WriteLogEvent("HTTPServices.openapi.ppvstatusGET", EventLogLevel.Error,,CurrentSessionDate(), vMsg);	
				EndIf;
			Else
				vMsg = Nstr("en = 'It is necessary to fill the hotel'; de = 'Es ist notwendig, das hotel zu füllen'; ru = 'Необходимо заполнить гостиницу'");
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteractionParameters, "SamsungLYNK.Start", Enums.ExternalSystemEventTypes.Warning, , , vMsg);
				WriteLogEvent("HTTPServices.openapi.ppvstatusGET", EventLogLevel.Error,,CurrentSessionDate(), vMsg);
			EndIf;	
		Else
			vMsg = Nstr("en = 'Interaction system is off, synchronization failed'; de = 'Interaktionssystem ist ausgeschaltet, Synchronisation fehlgeschlagen'; ru = 'Cистема взаимодействия выключена'");
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteractionParameters, "SamsungLYNK.Start", Enums.ExternalSystemEventTypes.Warning, , , vMsg);
			WriteLogEvent("HTTPServices.openapi.ppvstatusGET", EventLogLevel.Error,,, vMsg);
		EndIf;	
	Else
		vMsg = Nstr("en = 'Interaction system not found'; de = 'Interaktionssystem nicht gefunden'; ru = 'Система взаимодействия не найдена'");
		WriteLogEvent("HTTPServices.openapi.ppvstatusGET", EventLogLevel.Error,,, vMsg);
	EndIf;
	If Not ValueIsFilled(vBody) Then
		vBody = SamsungLYNK.GetErrorResponseXML("ppvstatus");	
	EndIf;
	If ValueIsFilled(vInteractionParameters) And vInteractionParameters.DebugMode Then
		vMessage = NStr("en = 'Response'; de = 'Antwort'; ru = 'Ответ'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteractionParameters, "SamsungLYNK.ppvstatusGET", Enums.ExternalSystemEventTypes.Info, , vBody, vMessage);
	EndIf;
	vResponse = New HTTPServiceResponse(200); 
	vHeaders = New Map();
	vHeaders.Insert("Content-Type", "text/html; charset=utf-8");
	vResponse.Headers = vHeaders;
	vResponse.SetBodyFromString(vBody);
	Return vResponse;
EndFunction // PpvstatusGET

// -------------------------------------------------------------------------
Function displayGET(pRequest)
	vBody = "";
	vInteractionParameters = Catalogs.ExternalSystemInteractions.EmptyRef();
	vInteractionParametersRows = cmGetInteractionByID("SamsungLYNK", False);	
	If vInteractionParametersRows.Count() > 0 Then
		vInteractionParameters = vInteractionParametersRows.Get(0).Ref; 	
	EndIf;
	If ValueIsFilled(vInteractionParameters) Then
		If vInteractionParameters.IsActive Then
			If ValueIsFilled(vInteractionParameters.Hotel) Then
				If ValueIsFilled(vInteractionParameters) And vInteractionParameters.DebugMode Then
					vMessage = NStr("en = 'Request'; de = 'Anfrage'; ru = 'Запрос'");
					If TypeOf(pRequest.Headers) = Type("FixedMap") Then
						vHeadersRequest = New Map(pRequest.Headers);
					Else
						vHeadersRequest = pRequest.Headers;		
					EndIf;
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteractionParameters, "SamsungLYNK.displayGET", Enums.ExternalSystemEventTypes.Info, vHeadersRequest, , vMessage);
				EndIf;
				vRoom = Catalogs.Rooms.EmptyRef();
				vRoomNumber = pRequest.Headers.Get("roomnumber");
				If vRoomNumber <> Undefined Then 
					vRoom = cmGetRoomByCode(vRoomNumber, vInteractionParameters.Hotel.Code, "SamsungLYNK");
					If ValueIsFilled(vRoom) Then
						vBody = SamsungLYNK.Display(vInteractionParameters, vRoom);	
					Else
						vMsg = Nstr("en = 'Room not found'; de = 'Zimmer nicht gefunden'; ru = 'Номер не найден'");
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteractionParameters, "SamsungLYNK.Start", Enums.ExternalSystemEventTypes.Warning, , , vMsg);
						WriteLogEvent("HTTPServices.openapi.displayGET", EventLogLevel.Error,,CurrentSessionDate(), vMsg);	
					EndIf;
				Else
					vMsg = Nstr("en = 'Room code not transmitted'; de = 'Zimmer nicht übertragen'; ru = 'Не передан код номера'");
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteractionParameters, "SamsungLYNK.Start", Enums.ExternalSystemEventTypes.Warning, , , vMsg);
					WriteLogEvent("HTTPServices.openapi.displayGET", EventLogLevel.Error,,CurrentSessionDate(), vMsg);	
				EndIf;
			Else
				vMsg = Nstr("en = 'It is necessary to fill the hotel'; de = 'Es ist notwendig, das hotel zu füllen'; ru = 'Необходимо заполнить гостиницу'");
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteractionParameters, "SamsungLYNK.Start", Enums.ExternalSystemEventTypes.Warning, , , vMsg);
				WriteLogEvent("HTTPServices.openapi.displayGET", EventLogLevel.Error,,CurrentSessionDate(), vMsg);
			EndIf;	
		Else
			vMsg = Nstr("en = 'Interaction system is off, synchronization failed'; de = 'Interaktionssystem ist ausgeschaltet, Synchronisation fehlgeschlagen'; ru = 'Cистема взаимодействия выключена'");
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteractionParameters, "SamsungLYNK.Start", Enums.ExternalSystemEventTypes.Warning, , , vMsg);
			WriteLogEvent("HTTPServices.openapi.displayGET", EventLogLevel.Error,,, vMsg);
		EndIf;	
	Else
		vMsg = Nstr("en = 'Interaction system not found'; de = 'Interaktionssystem nicht gefunden'; ru = 'Система взаимодействия не найдена'");
		WriteLogEvent("HTTPServices.openapi.displayGET", EventLogLevel.Error,,, vMsg);
	EndIf;
	If Not ValueIsFilled(vBody) Then
		vBody = SamsungLYNK.GetErrorResponseXML("display");	
	EndIf;
	If ValueIsFilled(vInteractionParameters) And vInteractionParameters.DebugMode Then
		vMessage = NStr("en = 'Response'; de = 'Antwort'; ru = 'Ответ'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteractionParameters, "SamsungLYNK.displayGET", Enums.ExternalSystemEventTypes.Info, , vBody, vMessage);
	EndIf;
	vResponse = New HTTPServiceResponse(200); 
	vResponse.Headers = New Map();
	vResponse.SetBodyFromString(vBody);
	Return vResponse;
EndFunction // DisplayGET

// -------------------------------------------------------------------------
Function informationGET(pRequest)
	vBody = "";
	vInteractionParameters = Catalogs.ExternalSystemInteractions.EmptyRef();
	vInteractionParametersRows = cmGetInteractionByID("SamsungLYNK", False);	
	If vInteractionParametersRows.Count() > 0 Then
		vInteractionParameters = vInteractionParametersRows.Get(0).Ref; 	
	EndIf;
	If ValueIsFilled(vInteractionParameters) Then
		If vInteractionParameters.IsActive Then
			If ValueIsFilled(vInteractionParameters.Hotel) Then
				If ValueIsFilled(vInteractionParameters) And vInteractionParameters.DebugMode Then
					vMessage = NStr("en = 'Request'; de = 'Anfrage'; ru = 'Запрос'");
					If TypeOf(pRequest.Headers) = Type("FixedMap") Then
						vHeadersRequest = New Map(pRequest.Headers);
					Else
						vHeadersRequest = pRequest.Headers;		
					EndIf;
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteractionParameters, "SamsungLYNK.informationGET", Enums.ExternalSystemEventTypes.Info, vHeadersRequest, , vMessage);
				EndIf;
				vRoom = Catalogs.Rooms.EmptyRef();
				vRoomNumber = pRequest.Headers.Get("roomnumber");
				If vRoomNumber <> Undefined Then 
					vRoom = cmGetRoomByCode(vRoomNumber, vInteractionParameters.Hotel.Code, "SamsungLYNK");
					If ValueIsFilled(vRoom) Then
						vBody = SamsungLYNK.Information(vInteractionParameters, vRoom);	
					Else
						vMsg = Nstr("en = 'Room not found'; de = 'Zimmer nicht gefunden'; ru = 'Номер не найден'");
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteractionParameters, "SamsungLYNK.Start", Enums.ExternalSystemEventTypes.Warning, , , vMsg);
						WriteLogEvent("HTTPServices.openapi.informationGET", EventLogLevel.Error,,CurrentSessionDate(), vMsg);	
					EndIf;
				Else
					vMsg = Nstr("en = 'Room code not transmitted'; de = 'Zimmer nicht übertragen'; ru = 'Не передан код номера'");
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteractionParameters, "SamsungLYNK.Start", Enums.ExternalSystemEventTypes.Warning, , , vMsg);
					WriteLogEvent("HTTPServices.openapi.informationGET", EventLogLevel.Error,,CurrentSessionDate(), vMsg);	
				EndIf;
			Else
				vMsg = Nstr("en = 'It is necessary to fill the hotel'; de = 'Es ist notwendig, das hotel zu füllen'; ru = 'Необходимо заполнить гостиницу'");
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteractionParameters, "SamsungLYNK.Start", Enums.ExternalSystemEventTypes.Warning, , , vMsg);
				WriteLogEvent("HTTPServices.openapi.informationGET", EventLogLevel.Error,,CurrentSessionDate(), vMsg);
			EndIf;	
		Else
			vMsg = Nstr("en = 'Interaction system is off, synchronization failed'; de = 'Interaktionssystem ist ausgeschaltet, Synchronisation fehlgeschlagen'; ru = 'Cистема взаимодействия выключена'");
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteractionParameters, "SamsungLYNK.Start", Enums.ExternalSystemEventTypes.Warning, , , vMsg);
			WriteLogEvent("HTTPServices.openapi.informationGET", EventLogLevel.Error,,, vMsg);
		EndIf;	
	Else
		vMsg = Nstr("en = 'Interaction system not found'; de = 'Interaktionssystem nicht gefunden'; ru = 'Система взаимодействия не найдена'");
		WriteLogEvent("HTTPServices.openapi.informationGET", EventLogLevel.Error,,, vMsg);
	EndIf;					
	If Not ValueIsFilled(vBody) Then
		vBody = SamsungLYNK.GetErrorResponseXML("information");	
	EndIf;
	If ValueIsFilled(vInteractionParameters) And vInteractionParameters.DebugMode Then
		vMessage = NStr("en = 'Response'; de = 'Antwort'; ru = 'Ответ'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteractionParameters, "SamsungLYNK.informationGET", Enums.ExternalSystemEventTypes.Info, , vBody, vMessage);
	EndIf;
	vResponse = New HTTPServiceResponse(200);
	vResponse.Headers = New Map();
	vResponse.SetBodyFromString(vBody);
	Return vResponse;
EndFunction // InformationGET

// -------------------------------------------------------------------------
Function roomslistGET(pRequest)
	vBody = "";
	vInteractionParameters = Catalogs.ExternalSystemInteractions.EmptyRef();
	vInteractionParametersRows = cmGetInteractionByID("SamsungLYNK", False);	
	If vInteractionParametersRows.Count() > 0 Then
		vInteractionParameters = vInteractionParametersRows.Get(0).Ref; 	
	EndIf;
	If ValueIsFilled(vInteractionParameters) Then
		If vInteractionParameters.IsActive Then
			If ValueIsFilled(vInteractionParameters.Hotel) Then
				If ValueIsFilled(vInteractionParameters) And vInteractionParameters.DebugMode Then
					vMessage = NStr("en = 'Request'; de = 'Anfrage'; ru = 'Запрос'");
					If TypeOf(pRequest.Headers) = Type("FixedMap") Then
						vHeadersRequest = New Map(pRequest.Headers);
					Else
						vHeadersRequest = pRequest.Headers;		
					EndIf;
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteractionParameters, "SamsungLYNK.roomslistGET", Enums.ExternalSystemEventTypes.Info, vHeadersRequest, , vMessage);
				EndIf;
				vBody = SamsungLYNK.RoomsList(vInteractionParameters);	
			Else
				vMsg = Nstr("en = 'It is necessary to fill the hotel'; de = 'Es ist notwendig, das hotel zu füllen'; ru = 'Необходимо заполнить гостиницу'");
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteractionParameters, "SamsungLYNK.Start", Enums.ExternalSystemEventTypes.Warning, , , vMsg);
				WriteLogEvent("HTTPServices.openapi.roomslistGET", EventLogLevel.Error,,CurrentSessionDate(), vMsg);
			EndIf;	
		Else
			vMsg = Nstr("en = 'Interaction system is off, synchronization failed'; de = 'Interaktionssystem ist ausgeschaltet, Synchronisation fehlgeschlagen'; ru = 'Cистема взаимодействия выключена'");
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteractionParameters, "SamsungLYNK.Start", Enums.ExternalSystemEventTypes.Warning, , , vMsg);
			WriteLogEvent("HTTPServices.openapi.roomslistGET", EventLogLevel.Error,,, vMsg);
		EndIf;	
	Else
		vMsg = Nstr("en = 'Interaction system not found'; de = 'Interaktionssystem nicht gefunden'; ru = 'Система взаимодействия не найдена'");
		WriteLogEvent("HTTPServices.openapi.roomslistGET", EventLogLevel.Error,,, vMsg);
	EndIf;
	If Not ValueIsFilled(vBody) Then
		vBody = SamsungLYNK.GetErrorResponseXML("roomslist");	
	EndIf;
	If ValueIsFilled(vInteractionParameters) And vInteractionParameters.DebugMode Then
		vMessage = NStr("en = 'Response'; de = 'Antwort'; ru = 'Ответ'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteractionParameters, "SamsungLYNK.roomslistGET", Enums.ExternalSystemEventTypes.Info, , vBody, vMessage);
	EndIf;
	vResponse = New HTTPServiceResponse(200);
	vResponse.Headers = New Map();
	vResponse.SetBodyFromString(vBody);
	Return vResponse;
EndFunction // RoomslistGET

#EndRegion