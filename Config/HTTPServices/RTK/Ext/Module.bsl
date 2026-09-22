#Region EventHandlers

// -----------------------------------------------------------------------------
Function billPOST(pRequest)
	Return ProcessRequest("bill", pRequest.GetBodyAsString());
EndFunction // BillPOST

// -----------------------------------------------------------------------------
Function chargePOST(pRequest)
	Return ProcessRequest("charge", pRequest.GetBodyAsString());
EndFunction // ChargePOST

// -----------------------------------------------------------------------------
Function messageretrievedPOST(pRequest)
	Return ProcessRequest("messageretrieved", pRequest.GetBodyAsString());
EndFunction // MessageretrievedPOST

// -----------------------------------------------------------------------------
Function resyncrequestPOST(pRequest)
	Return ProcessRequest("resyncrequest", pRequest.GetBodyAsString());
EndFunction // ResyncrequestPOST

// -----------------------------------------------------------------------------
Function sendmessagePOST(pRequest)
	Return ProcessRequest("sendmessage", pRequest.GetBodyAsString());
EndFunction // SendmessagePOST 

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function ProcessRequest(pName, pJSON)
	vResponseCode = 200; 
	vResponseJSON = "{ """"code"""":""""9"""" }";
	vInteractionParameters = Catalogs.ExternalSystemInteractions.EmptyRef();
	Try
		vInteractionParametersRows = cmGetInteractionByID("RTK", False); 	
		If vInteractionParametersRows.Count() > 0 Then
			vInteractionParameters = vInteractionParametersRows[0].Ref; 	
		EndIf;
		If ValueIsFilled(vInteractionParameters) Then
			vDataProcessors = vInteractionParameters.DataProcessor;
			vMessage = "";
			If ValueIsFilled(vDataProcessors) Then
				vObjDataProcessors = Catalogs.DataProcessors.CreateDataProcessorByProcessing(vDataProcessors, True);
				If vObjDataProcessors <> Undefined Then
					vResponseJSON = vObjDataProcessors.pmHTTPRequest(pName, pJSON, vResponseCode, vMessage);
				Else
					vResponseCode = 401;
					vMessage = Nstr("en = 'Failed to initialize processing'; de = 'Fehler beim Initialisieren der Verarbeitung'; ru = 'Не удалось инициализировать обработку'"); 
					WriteLogEvent("RTK." + pName, EventLogLevel.Error,,, vMessage);
				EndIf;
			Else
				vResponseCode = 401;
				vMessage = Nstr("en = 'Interaction has no service handling specified'; de = 'Für die Interaktion ist keine Servicebehandlung angegeben'; ru = 'У взаимодействия не указана обработка обслуживания'"); 
				WriteLogEvent("RTK." + pName, EventLogLevel.Error,,, vMessage);
			EndIf;        
			If vInteractionParameters.DebugMode Or vResponseCode <> 200 Then 
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteractionParameters, pName, ?(vResponseCode <> 200, Enums.ExternalSystemEventTypes.Error, Enums.ExternalSystemEventTypes.Info), pJSON, vResponseJSON, vMessage); 
			EndIf;
		Else
			vResponseCode = 401;                 
			vMessage = Nstr("en = 'Failed to find interaction parameters'; de = 'Interaktionsparameter konnten nicht gefunden werden'; ru = 'Не удалось найти параметры взаимодействия'");
			WriteLogEvent("RTK." + pName, EventLogLevel.Error,,, vMessage);
		EndIf;
	Except
		vResponseCode = 400;
		vMessage = ErrorDescription(); 
		WriteLogEvent("RTK." + pName, EventLogLevel.Error,,, vMessage);
	EndTry;
	vResponse = New HTTPServiceResponse(vResponseCode);
	vResponse.Headers = GetHeaders();
	vResponse.SetBodyFromString(vResponseJSON);
	Return vResponse;	
EndFunction // ProcessRequest    

// -----------------------------------------------------------------------------
Function GetHeaders()
	vResult = New Map;
	vResult.Insert("Content-Type", "application/json");
	Return vResult;
EndFunction // GetHeaders

#EndRegion