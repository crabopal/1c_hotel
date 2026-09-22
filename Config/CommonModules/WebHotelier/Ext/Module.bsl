
Procedure SyncData(pInteractionParameters, pHotelCode, pAmountOfDaysToUpdate = 100, pSkipPricesCacheUpdate = False, pFullUpdate = False, pLoadReservations, pUpdateAvailability, pUpdatePrices, pGetVacantRoomsAtMidnight = False) Export
	Try
		vUpdateCachedPrices = False;
		If pFullUpdate And Not pSkipPricesCacheUpdate Then
			vUpdateCachedPrices = True;
		EndIf;
		
		// Get reservations
		If pLoadReservations Then
			GetAndLoadReservations(pInteractionParameters, pHotelCode);
		EndIf;

		// Sync data
		vCurrentSessionDate = CurrentSessionDate();
		
		If pUpdateAvailability Or pFullUpdate Then
			UpdateAvailability(pInteractionParameters, pHotelCode, pAmountOfDaysToUpdate, pFullUpdate, pGetVacantRoomsAtMidnight);
		EndIf;
		
		If pUpdatePrices Or pFullUpdate Then
			UpdateRates(pInteractionParameters, pHotelCode, pAmountOfDaysToUpdate, pFullUpdate, vUpdateCachedPrices, , pGetVacantRoomsAtMidnight);
		EndIf;
		
		// Update Intercation parameters times
		ChannelManagers.UpdateLastSyncTime(pInteractionParameters, pFullUpdate, vCurrentSessionDate, "", pUpdateAvailability, pUpdatePrices, pUpdatePrices);
	Except
		vError			= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SyncData", vLogEventType, , , vError);
	EndTry;
EndProcedure

Function GetAndLoadReservations(pInteractionParameters, pHotelCode) Export
	
	vResult = New Structure("Success, Error, Raw, Result", True, "", "", Undefined);
	
	vBookingsList = GetPendingBookingsList(pInteractionParameters, pHotelCode);
	
	If vBookingsList.Success Then
		If vBookingsList.Result <> Undefined Then
			For each vBookingRow in vBookingsList.Result Do
				vBookingID		= vBookingRow.Get("id");
				If vBookingID <> Undefined Then
					vBookingID 		= Format(vBookingID, "NFD=0; NGS=; NG=");
					vBookingData 	= RetrieveBooking(pInteractionParameters, vBookingID);
					If vBookingData.Success Then
						If vBookingData.Result <> Undefined AND vBookingData.Result["property"] = pHotelCode Then 
							vLoadingResult 	= LoadReservation(pInteractionParameters, vBookingData.Result);
							If vLoadingResult.Success Then
								vSyncResult = SyncBooking(pInteractionParameters, vBookingID);
							Else
								vResult.Success = False;
								vResult.Error 	= "Failed to load reservation: " + vLoadingResult.Error + Chars.LF;	
							EndIf;
						EndIf;
					Else
						vResult.Success = False;
						vResult.Error 	= "Failed to receive booking data: " + vBookingData.Error + Chars.LF;
					EndIf;
				Else
					vResult.Success = False;
					vResult.Error 	= "Failed to receive booking ID from data" + Chars.LF;
				EndIf;
			EndDo;
		EndIf;
	Else			
		vResult.Success = False;
		vResult.Error 	= "Failed to get bookings list: " + vBookingsList.Error;
	EndIf;
	
	If NOT vResult.Success Then
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "GetAndLoadReservations", vLogEventType, , , vResult.Error);	
	EndIf;
	
	Return vResult;
	
EndFunction

#Region API

Function GetRoomListing(pInteractionParameters, pHotelCode, pGetRaw = False) Export
	
	vResult 		= New Structure("Success, Error, Raw, Result", False, "", "", Undefined);
	vMessageName 	= "/room/";
	vResponse		= Undefined;
	vMethod 		= "GET";	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Empty InterectionParameters";
			Return vResult;
		EndIf;
		
		vRequestHeaders 				= New Structure("Accept, Authorization");
		vRequestHeaders.Accept 			= "application/json";
		vRequestHeaders.Authorization 	= Catalogs.ExternalSystemInteractions.GetBase64Auth(pInteractionParameters.Login, pInteractionParameters.Password);

		vURL			= pInteractionParameters.HttpAddress + vMessageName + pHotelCode;
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, vRequestHeaders, vURL, vMethod, vMessageName, , "application/json");

		vResponseStatus = CheckResponseStatus(vResponse);
		
		If vResponseStatus.Success = False Then
			vResult.Error 	= vResponseStatus.StatusDescription;
			vResult.Success = vResponseStatus.Success;
		Else
			vResponseMap 		= Catalogs.DataConvertationRules.JSONtoMap(vResponse.Body);
			vBodyCheckResult 	= CheckResultBody(vResponseMap);
			vResult.Success 	= vBodyCheckResult.Success;
			vResult.Error		= vBodyCheckResult.Error;
			If vResult.Success Then
				vPathArray		= New Array;
				vPathArray.Add("data");
				vPathArray.Add("rooms");
				vResult.Result	= Catalogs.DataConvertationRules.GetMapValueByArrayPath(vResponseMap,vPathArray ); 
			EndIf;
		EndIf;	
						
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, ,vRawValue , vResult.Error);
	EndTry;
	
	If pGetRaw = True Then
		vRawValue = Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		vResult.Raw = vRawValue;	
	EndIf;
	
	Return vResult;
	
EndFunction

Function GetRatesListing(pInteractionParameters, pHotelCode, pGetRaw = False) Export
	
	vResult 		= New Structure("Success, Error, Raw, Result", False, "", "", Undefined);
	vMessageName 	= "/rate/";
	vResponse		= Undefined;
	vMethod 		= "GET";	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Empty InterectionParameters";
			Return vResult;
		EndIf;
		
		vRequestHeaders 				= New Structure("Accept, Authorization");
		vRequestHeaders.Accept 			= "application/json";
		vRequestHeaders.Authorization 	= Catalogs.ExternalSystemInteractions.GetBase64Auth(pInteractionParameters.Login, pInteractionParameters.Password);

		vURL			= pInteractionParameters.HttpAddress + vMessageName + pHotelCode;
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, vRequestHeaders, vURL, vMethod, vMessageName, , "application/json");

		vResponseStatus = CheckResponseStatus(vResponse);
		
		If vResponseStatus.Success = False Then
			vResult.Error 	= vResponseStatus.StatusDescription;
			vResult.Success = vResponseStatus.Success;
		Else
			vResponseMap 		= Catalogs.DataConvertationRules.JSONtoMap(vResponse.Body);
			vBodyCheckResult 	= CheckResultBody(vResponseMap);
			vResult.Success 	= vBodyCheckResult.Success;
			vResult.Error		= vBodyCheckResult.Error;
			If vResult.Success Then
				vPathArray		= New Array;
				vPathArray.Add("data");
				vPathArray.Add("rates");
				vResult.Result	= Catalogs.DataConvertationRules.GetMapValueByArrayPath(vResponseMap,vPathArray ); 
			EndIf;
		EndIf;	
						
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, ,vRawValue , vResult.Error);
	EndTry;
	
	If pGetRaw = True Then
		vRawValue = Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		vResult.Raw = vRawValue;	
	EndIf;
	
	Return vResult;
	
EndFunction

Function GetExtrasListing(pInteractionParameters, pHotelCode, pGetRaw = False) Export
	
	vResult 		= New Structure("Success, Error, Raw, Result", False, "", "", Undefined);
	vMessageName 	= "/extra/";
	vResponse		= Undefined;
	vMethod 		= "GET";	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Empty InterectionParameters";
			Return vResult;
		EndIf;
		
		vRequestHeaders 				= New Structure("Accept, Authorization");
		vRequestHeaders.Accept 			= "application/json";
		vRequestHeaders.Authorization 	= Catalogs.ExternalSystemInteractions.GetBase64Auth(pInteractionParameters.Login, pInteractionParameters.Password);

		vURL			= pInteractionParameters.HttpAddress + vMessageName + pHotelCode;
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, vRequestHeaders, vURL, vMethod, vMessageName, , "application/json");

		vResponseStatus = CheckResponseStatus(vResponse);
		
		If vResponseStatus.Success = False Then
			vResult.Error 	= vResponseStatus.StatusDescription;
			vResult.Success = vResponseStatus.Success;
		Else
			vResponseMap 		= Catalogs.DataConvertationRules.JSONtoMap(vResponse.Body);
			vBodyCheckResult 	= CheckResultBody(vResponseMap);
			vResult.Success 	= vBodyCheckResult.Success;
			vResult.Error		= vBodyCheckResult.Error;
			If vResult.Success Then
				vPathArray		= New Array;
				vPathArray.Add("data");
				vPathArray.Add("extras");
				vResult.Result	= Catalogs.DataConvertationRules.GetMapValueByArrayPath(vResponseMap, vPathArray);
			EndIf;
		EndIf;	
						
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, ,vRawValue , vResult.Error);
	EndTry;
	
	If pGetRaw = True Then
		vRawValue = Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		vResult.Raw = vRawValue;	
	EndIf;
	
	Return vResult;
	
EndFunction

Function GetSourcesListing(pInteractionParameters, pGetRaw = False) Export
	
	vResult 		= New Structure("Success, Error, Raw, Result", False, "", "", Undefined);
	vMessageName 	= "/sources";
	vResponse		= Undefined;
	vMethod 		= "GET";	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Empty InterectionParameters";
			Return vResult;
		EndIf;
		
		vRequestHeaders 				= New Structure("Accept, Authorization");
		vRequestHeaders.Accept 			= "application/json";
		vRequestHeaders.Authorization 	= Catalogs.ExternalSystemInteractions.GetBase64Auth(pInteractionParameters.Login, pInteractionParameters.Password);

		vURL			= pInteractionParameters.HttpAddress + vMessageName;
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, vRequestHeaders, vURL, vMethod, vMessageName, , "application/json");

		vResponseStatus = CheckResponseStatus(vResponse);
		
		If vResponseStatus.Success = False Then
			vResult.Error 	= vResponseStatus.StatusDescription;
			vResult.Success = vResponseStatus.Success;
		Else
			vResponseMap 		= Catalogs.DataConvertationRules.JSONtoMap(vResponse.Body);
			vBodyCheckResult 	= CheckResultBody(vResponseMap);
			vResult.Success 	= vBodyCheckResult.Success;
			vResult.Error		= vBodyCheckResult.Error;
			If vResult.Success Then
				vPathArray		= New Array;
				vPathArray.Add("data");
				vPathArray.Add("sources");
				vResult.Result	= Catalogs.DataConvertationRules.GetMapValueByArrayPath(vResponseMap,vPathArray ); 
			EndIf;
		EndIf;	
						
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, ,vRawValue , vResult.Error);
	EndTry;
	
	If pGetRaw = True Then
		vRawValue = Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		vResult.Raw = vRawValue;	
	EndIf;
	
	Return vResult;
	
EndFunction

Function UpdateAvailability(pInteractionParameters, pHotelCode, pAmountOfDaysToUpdate = 100, pFullUpdate = False, pGetRaw = False, pGetVacantRoomsAtMidnight = False) Export
	
	vResult 		= New Structure("Success, Error, RawResponse, RawRequest", True, "", "", "", pGetVacantRoomsAtMidnight = False);
	vMessageName 	= "/manage/availability";
	vResponse		= Undefined;
	vMethod 		= "POST";	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Empty InterectionParameters";
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, , , vResult.Error);
			Return vResult;
		EndIf;
		
		vPeriodFrom = CurrentDate();
		vPeriodTo	= vPeriodFrom + 24*60*60*pAmountOfDaysToUpdate;
		
		vAvailability 		= ChannelManagers.GetAvailability(pInteractionParameters, vPeriodFrom, vPeriodTo, pFullUpdate, , pGetVacantRoomsAtMidnight);
		
		If vAvailability = Undefined Then
			vResult.Success = False;
			vResult.Error 	= "Failed to get availability table!";
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, , , vResult.Error);
			Return vResult;	
		ElsIf vAvailability.Count() = 0 Then
			Return vResult;
		EndIf;

		vParametersMap		= GetAvailabilityMap(pInteractionParameters, vAvailability); 
								
		vRequestHeaders 				= New Structure("Accept, Authorization");
		vRequestHeaders.Accept 			= "application/json";
		vRequestHeaders.Authorization 	= Catalogs.ExternalSystemInteractions.GetBase64Auth(pInteractionParameters.Login, pInteractionParameters.Password);

		vURL			= pInteractionParameters.HttpAddress + vMessageName;
		vRequestBody	= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, vRequestHeaders, vURL, vMethod, vMessageName, vRequestBody, "application/json");
		vResponseStatus = CheckResponseStatus(vResponse);
		
		vResult.Success = vResponseStatus.Success;
		If vResponseStatus.Success = False Then
			vResult.Error 	= vResponseStatus.StatusDescription;
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vResponse.Body, vResult.Error);
		EndIf;
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vRawValue, vResult.Error);
	EndTry;
	
	If pGetRaw = True Then
		vRawValue = Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		vResult.RawResponse = vRawValue;
		vResult.RawRequest 	= vRequestBody
	EndIf;

	Return vResult;
	
EndFunction

Function UpdateRates(pInteractionParameters, pHotelCode, pAmountOfDaysToUpdate = 100, pFullUpdate = False, pUpdateCachedPrices = False, pGetRaw = False, pGetVacantRoomsAtMidnight = False) Export
	
	vResult 		= New Structure("Success, Error, RawResponse, RawRequest", True, "", "", "");
	vMessageName 	= "/manage/rates";
	vResponse		= Undefined;
	vMethod 		= "POST";	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Empty InterectionParameters";
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, , , vResult.Error);
			Return vResult;
		EndIf;
		
		vPeriodFrom = CurrentDate();
		vPeriodTo	= vPeriodFrom + 24*60*60*pAmountOfDaysToUpdate;
		
		vAvailability 		= ChannelManagers.GetAvailability(pInteractionParameters, vPeriodFrom, vPeriodTo, pFullUpdate, , pGetVacantRoomsAtMidnight);
		
		If vAvailability = Undefined Then
			vResult.Success = False;
			vResult.Error 	= "Failed to get availability table!";
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, , , vResult.Error);
			Return vResult;	
		ElsIf vAvailability.Count() = 0 Then
			Return vResult;
		EndIf;

		vRoomTypes		= Undefined;
		vRoomRates		= Undefined;
		vParametersMap	= GetRatesMap(pInteractionParameters, pHotelCode, vPeriodFrom, vPeriodTo, pFullUpdate, pUpdateCachedPrices, vRoomTypes, vRoomRates); 
								
		vRequestHeaders 				= New Structure("Accept, Authorization");
		vRequestHeaders.Accept 			= "application/json";
		vRequestHeaders.Authorization 	= Catalogs.ExternalSystemInteractions.GetBase64Auth(pInteractionParameters.Login, pInteractionParameters.Password);

		vURL			= pInteractionParameters.HttpAddress + vMessageName;
		vRequestBody	= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, vRequestHeaders, vURL, vMethod, vMessageName, vRequestBody, "application/json");
		vResponseStatus = CheckResponseStatus(vResponse);
		
		vResult.Success = vResponseStatus.Success;
		If vResponseStatus.Success = False Then
			vResult.Error 	= vResponseStatus.StatusDescription;
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vResponse.Body, vResult.Error);
		EndIf;
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vRawValue, vResult.Error);
	EndTry;
	
	If pGetRaw = True Then
		vRawValue = Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		vResult.RawResponse = vRawValue;
		vResult.RawRequest 	= vRequestBody
	EndIf;

	Return vResult;
	
EndFunction

Function GetPendingBookingsList(pInteractionParameters, pHotelCode, pGetRaw = False) Export
	
	vResult 		= New Structure("Success, Error, Raw, Result", False, "", "", Undefined);
	vMessageName 	= "/reservation/new";
	vResponse		= Undefined;
	vMethod 		= "GET";	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Empty InterectionParameters";
			Return vResult;
		EndIf;
		
		vRequestHeaders 				= New Structure("Accept, Authorization");
		vRequestHeaders.Accept 			= "application/json";
		vRequestHeaders.Authorization 	= Catalogs.ExternalSystemInteractions.GetBase64Auth(pInteractionParameters.Login, pInteractionParameters.Password);

		vURL			= pInteractionParameters.HttpAddress + vMessageName;
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, vRequestHeaders, vURL, vMethod, vMessageName, , "application/json");

		vResponseStatus = CheckResponseStatus(vResponse);
		
		If vResponseStatus.Success = False Then
			vResult.Error 	= vResponseStatus.StatusDescription;
			vResult.Success = vResponseStatus.Success;
		Else
			vResponseMap 		= Catalogs.DataConvertationRules.JSONtoMap(vResponse.Body);
			vBodyCheckResult 	= CheckResultBody(vResponseMap);
			vResult.Success 	= vBodyCheckResult.Success;
			vResult.Error		= vBodyCheckResult.Error;
			If vResult.Success Then
				vPathArray		= New Array;
				vPathArray.Add("data");
				vPathArray.Add("reservations");
				vResult.Result	= Catalogs.DataConvertationRules.GetMapValueByArrayPath(vResponseMap,vPathArray); 
			EndIf;
		EndIf;	
						
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, ,vRawValue , vResult.Error);
	EndTry;
	
	If pGetRaw = True Then
		vRawValue = Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		vResult.Raw = vRawValue;	
	EndIf;
	
	Return vResult;
	
EndFunction

Function RetrieveBooking(pInteractionParameters, pBookingID, pGetRaw = False) Export
	
	vResult 		= New Structure("Success, Error, Raw, Result", False, "", "", Undefined);
	vMessageName 	= "/reservation/";
	vResponse		= Undefined;
	vMethod 		= "GET";	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Empty InterectionParameters";
			Return vResult;
		EndIf;
		
		vRequestHeaders 				= New Structure("Accept, Authorization");
		vRequestHeaders.Accept 			= "application/json";
		vRequestHeaders.Authorization 	= Catalogs.ExternalSystemInteractions.GetBase64Auth(pInteractionParameters.Login, pInteractionParameters.Password);

		vURL			= pInteractionParameters.HttpAddress + vMessageName + pBookingID;
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, vRequestHeaders, vURL, vMethod, vMessageName, , "application/json");

		vResponseStatus = CheckResponseStatus(vResponse);
		
		If vResponseStatus.Success = False Then
			vResult.Error 	= vResponseStatus.StatusDescription;
			vResult.Success = vResponseStatus.Success;
		Else
			vResponseMap 		= Catalogs.DataConvertationRules.JSONtoMap(vResponse.Body);
			vBodyCheckResult 	= CheckResultBody(vResponseMap);
			vResult.Success 	= vBodyCheckResult.Success;
			vResult.Error		= vBodyCheckResult.Error;
			If vResult.Success Then
				vPathArray		= New Array;
				vPathArray.Add("data");
				vResult.Result	= Catalogs.DataConvertationRules.GetMapValueByArrayPath(vResponseMap,vPathArray); 
			EndIf;
		EndIf;	
						
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, ,vRawValue , vResult.Error);
	EndTry;
	
	If pGetRaw = True Then
		vRawValue = Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		vResult.Raw = vRawValue;	
	EndIf;
	
	Return vResult;
	
EndFunction

Function SyncBooking(pInteractionParameters, pBookingID, pGetRaw = False) Export
	
	vResult 		= New Structure("Success, Error, Raw, Result", False, "", "", False);
	vMessageName 	= "/reservation/sync/";
	vResponse		= Undefined;
	vMethod 		= "GET";	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Empty InterectionParameters";
			Return vResult;
		EndIf;
		
		vRequestHeaders 				= New Structure("Accept, Authorization");
		vRequestHeaders.Accept 			= "application/json";
		vRequestHeaders.Authorization 	= Catalogs.ExternalSystemInteractions.GetBase64Auth(pInteractionParameters.Login, pInteractionParameters.Password);

		vURL			= pInteractionParameters.HttpAddress + vMessageName + pBookingID;
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, vRequestHeaders, vURL, vMethod, vMessageName, , "application/json");

		vResponseStatus = CheckResponseStatus(vResponse);
		
		If vResponseStatus.Success = False Then
			vResult.Error 	= vResponseStatus.StatusDescription;
			vResult.Success = vResponseStatus.Success;
		Else
			vResponseMap 		= Catalogs.DataConvertationRules.JSONtoMap(vResponse.Body);
			vBodyCheckResult 	= CheckResultBody(vResponseMap);
			vResult.Success 	= vBodyCheckResult.Success;
			vResult.Error		= vBodyCheckResult.Error;
			If vResult.Success Then
				vResult.Result	= True;; 
			EndIf;
		EndIf;	
						
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, ,vRawValue , vResult.Error);
	EndTry;
	
	If pGetRaw = True Then
		vRawValue = Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		vResult.Raw = vRawValue;	
	EndIf;
	
	Return vResult;
	
EndFunction

#EndRegion

Function GetAvailabilityMap(pInteractionParameters, pAvailability)
	
	vResult 	= New Map;
	
	vRoomTypes 	= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "roomtypes", "code");
	
	If vRoomTypes.Columns.Find("code") <> Undefined Then		
		For each vRoomType in vRoomTypes Do
			vAvailabilityArray		= New Array;
			vRoomTypeAvailability 	= pAvailability.FindRows(New Structure("RoomType", vRoomType.RefKey1));
			For each vRoomTypeAvailabilityRow in vRoomTypeAvailability Do
				vAvailabilityMap		= New Map;
				vAvailabilityMap.Insert("from", 	Format(vRoomTypeAvailabilityRow.PeriodFrom, "DF=yyyy-MM-dd"));
				vAvailabilityMap.Insert("to", 		Format(vRoomTypeAvailabilityRow.PeriodTo, "DF=yyyy-MM-dd"));
				vAvailabilityMap.Insert("allot", 	vRoomTypeAvailabilityRow.VacantRooms);
				vAvailabilityArray.Add(vAvailabilityMap);
			EndDo;
			vResult.Insert(vRoomType.code, vAvailabilityArray);
		EndDo;
	EndIf;

	Return vResult;
	
EndFunction

Function GetRatesMap(pInteractionParameters, pHotelCode, pPeriodFrom, pPeriodTo, pFullUpdate, pUpdateCachedPrices, rRoomTypesTable = Undefined, rRoomRatesTable = Undefined)
	
	vResult = New Map;
	
	vRoomTypes 			= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "roomtypes");
	vRoomRates 			= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "roomrates");
	vAccommodations 	= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "accommodationtemplates");
	vAvailability 		= Undefined;
	
	vPricesByAccTypes 	= Undefined;
	vRestrictions		= Undefined;
	
	vRoomRatesData	= New ValueTable;
	vRoomRatesData.Columns.Add("RoomRate");
	vRoomRatesData.Columns.Add("Prices");
	vRoomRatesData.Columns.Add("Restrictions");
	For each vRoomRate in vRoomRates Do
		If vRoomRate.parent = 0 Then
			If vRoomRatesData.Find(vRoomRate.RefKey1, "RoomRate") = Undefined Then
				vPricesByAccTypes 	= ChannelManagers.GetPrices(pInteractionParameters, vRoomRate.RefKey1, pPeriodFrom, pPeriodTo, pFullUpdate, pUpdateCachedPrices);
				vRestrictions 		= ChannelManagers.GetRestrictions(pInteractionParameters, vRoomRate.RefKey1, pPeriodFrom, pPeriodTo, pFullUpdate);
				
				vNewRow 				= vRoomRatesData.Add();
				vNewRow.RoomRate		= vRoomRate.RefKey1;
				vNewRow.Prices			= vPricesByAccTypes;
				vNewRow.Restrictions	= vRestrictions;
			EndIf;
		EndIf;
	EndDo;
	
	For each vRoomRateRow in vRoomRates Do
		If vRoomRateRow.parent = 0 Then
			vPricesArray				= New Array;
			vRoomRateDataRow 			= vRoomRatesData.Find(vRoomRate.RefKey1, "RoomRate");
			vAccommodationTemplates 	= vAccommodations.FindRows(New Structure("RefKey2, id", vRoomRateRow.RefKey1, vRoomRateRow.id));
			If vRoomRateDataRow <> Undefined AND vAccommodationTemplates.Count() > 0 Then						
				vPeriodArray	= New Array;
				For each vPricesRow in vRoomRateDataRow.Prices Do				
					If vPeriodArray.Find(vPricesRow.Period) = Undefined Then
						vPricesMap		= New Map;
						vPricingArray 	= New Array;
						For each vAccommodationTemplateRow in vAccommodationTemplates Do
							vPricingMap		= New Map;
							vAccTemplate	= vAccommodationTemplateRow.RefKey1;
							vAccTypes 		= vAccTemplate.AccommodationTypes;
							
							vOverrides = cmGetRoomRateOverrides(vRoomRate.RefKey1, vRoomRateRow.RefKey2.Owner, vAccTemplate, vRoomRateRow.RefKey2);
							
							// Prices
							vPrice 	= 0;
 							For each vAccTypeRow in vAccTypes Do
								vAccommodationTypeRef = vAccTypeRow.AccommodationType;
								vAccommodationTypeIndex = vAccTypes.IndexOf(vAccTypeRow);
								
								If vOverrides.Count() > 0 Then
									vOverrideRows = vOverrides.FindRows(New Structure("AccommodationType, TemplateLineNumber", vAccommodationTypeRef, vAccommodationTypeIndex + 1));
									If vOverrideRows.Count() > 0 And ValueIsFilled(vOverrideRows.Get(0).ToAccommodationType) Then
										vAccommodationTypeRef = vOverrideRows.Get(0).ToAccommodationType;
									EndIf;
								EndIf;
															
								
								vPricesByAccType = vRoomRateDataRow.Prices.FindRows(New Structure("Period, RoomType, AccommodationType", vPricesRow.Period, vRoomRateRow.RefKey2, vAccommodationTypeRef));
								If vPricesByAccType.Count() > 0 Then
									vPrice = vPrice + vPricesByAccType[0].Price;
									vPeriodArray.Add(vPricesRow.Period);
								EndIf;
							EndDo;
							
							vPricingMap.Insert("adults",	vAccTemplate.NumberOfAdults);
							vPricingMap.Insert("children", 	vAccTemplate.NumberOfChildren + vAccTemplate.NumberOfTeenagers);
							vPricingMap.Insert("price", 	vPrice);
							vPricingArray.Add(vPricingMap);
						EndDo;
						vPricesMap.Insert("pricing", vPricingArray);
						vPricesMap.Insert("date", Format(vPricesRow.Period, "DF=yyyy-MM-dd"));
						
						vRoomTypeRestrictions = vRoomRateDataRow.Restrictions.FindRows(New Structure("RoomType, Period", vRoomRateRow.RefKey2, vPricesRow.Period));
						If vRoomTypeRestrictions.Count() = 0 Then
							vRoomTypeRestrictions = vRoomRateDataRow.Restrictions.FindRows(New Structure("RoomType, Period", Catalogs.RoomTypes.EmptyRef(), vPricesRow.Period));
						EndIf;
						If vRoomTypeRestrictions.Count() > 0 Then
							vRoomTypeRestrictionsRow = vRoomTypeRestrictions[vRoomTypeRestrictions.Count() - 1]; 						
							If vRoomTypeRestrictionsRow.StopSale Then
								vPricesMap.Insert("closeout", 1);
							Else
								vPricesMap.Insert("closeout", 0);	
							EndIf;
							vPricesMap.Insert("min_stay", vRoomTypeRestrictionsRow.MLOS);
						Else
							vPricesMap.Insert("closeout", 0);
							vPricesMap.Insert("min_stay", 0);
						EndIf;
						vPricesArray.Add(vPricesMap);
					EndIf;				
				EndDo;
			EndIf;
			vUnitedArray = UnitePricesPeriods(vPricesArray);
			vResult.Insert(vRoomRateRow.id, vUnitedArray);
		EndIf;		
	EndDo;
	
	rRoomRatesTable 	= vRoomRates;
	rRoomTypesTable		= vRoomTypes;

	Return vResult;
	
EndFunction

Function CheckResultBody(pResonseMap)
	
	vResult = New Structure("Success, Error", False, "");
	
	If pResonseMap <> Undefined Then
		If pResonseMap["http_code"] = 200 Then
			vResult.Success = True;
		Else
			vResult.Error = pResonseMap["error_code"] + " " + pResonseMap["error_msg"];	
		EndIf;
	Else
		vResult.Error = "Response body is empty!";
	EndIf;
	
	Return vResult;
	
EndFunction

Function CheckResponseStatus(pResponse)
	
	vResult = New Structure("Success, StatusDescription");
	
	If pResponse.StatusCode = 200 Then
		vResult.Success 			= True;
		vResult.StatusDescription 	= "OK";
	ElsIf pResponse.StatusCode = 401 Then
		vResult.Success 			= False;
		vResult.StatusDescription 	= "Error 401";
	ElsIf pResponse.StatusCode = 403 Then
		vResult.Success 			= False;
		vResult.StatusDescription 	= "Error 403. Bad auth.";
	ElsIf pResponse.StatusCode = 404 Then
		vResult.Success 			= False;
		vResult.StatusDescription 	= "Error 404";
	ElsIf pResponse.StatusCode = 406 Then
		vResult.Success 			= False;
		vResult.StatusDescription 	= "Error 406";
	ElsIf pResponse.StatusCode = 500 Then
		vResult.Success 			= False;
		vResult.StatusDescription 	= "Error 500";
	Else
		vResult.Success 			= False;
		vResult.StatusDescription 	= "Unknown status";
	EndIf;
	
	Return vResult;
	
EndFunction

Function UnitePricesPeriods(pPricesArray)
	
	vResult			= New Array;
	vNewMap			= New Map;
	vPricesCount 	= pPricesArray.Count();
	If vPricesCount > 1 Then
		i = 0;
		vUnite	 	= True;
		vUnited 	= False;
		While i < vPricesCount - 1 Do
			
			vUnite		= True;
			vFirstMap 	= pPricesArray[i];
			vSecondMap 	= pPricesArray[i + 1];
			If vFirstMap["closeout"] <> vSecondMap["closeout"] Then
				vUnite	= False;
				vResult.Add(vFirstMap);
			EndIf;
			
			If vFirstMap["min_stay"] <> vSecondMap["min_stay"] Then
				vUnite	= False;
				vResult.Add(vFirstMap);
			EndIf;
			
			vFirstPricesArray 	= vFirstMap["pricing"];
			vSecondPricesArray 	= vSecondMap["pricing"];
			vPricingCount = vFirstPricesArray.Count();
			If vPricingCount = 0 OR vPricingCount <> vSecondPricesArray.Count() Then
				vUnite	= False;
				vResult.Add(vFirstMap);
			EndIf;
			
			j = 0;
			While j < vPricingCount Do
				vFirstPricingMap 	= vFirstPricesArray[j];
				vSecondPricingMap 	= vSecondPricesArray[j];
				
				If vFirstPricingMap["adults"] <> vSecondPricingMap["adults"] Then
					vUnite	= False;
					Break;
				EndIf;
				
				If vFirstPricingMap["children"] <> vSecondPricingMap["children"] Then
					vUnite	= False;
					Break;
				EndIf;
				
				If vFirstPricingMap["price"] <> vSecondPricingMap["price"] Then
					vUnite	= False;
					Break;
				EndIf;
				
				j = j + 1;
			EndDo;
			
			If vUnite Then														
				If NOT vUnited Then
					vNewMap.Insert("closeout", 	vFirstMap["closeout"]);
					vNewMap.Insert("min_stay", 	vFirstMap["min_stay"]);
					vNewMap.Insert("pricing", 	vFirstMap["pricing"]);
					vNewMap.Insert("from", 		vFirstMap["date"]);
				EndIf;
				vNewMap.Insert("to", 		vSecondMap["date"]);
				
				vUnited = True;
			Else
				
				If vUnited Then
					vResult.Add(vNewMap);
					vNewMap = New Map;
				EndIf;
				
				vResult.Add(vFirstMap);
			EndIf;
			
			i = i + 1;
		EndDo;
		
		If vUnite AND vUnited Then
			vResult.Add(vNewMap);
		EndIf;
	Else
		vResult = pPricesArray;
	EndIf;
	
	Return vResult;
	
EndFunction

Function LoadReservation(pInteractionParameters, pReservationData) Export
	
	vResult = New Structure("Success, Error, Result", False, "", Undefined);
	
	Try
		//Main data  
		vReservationID 			= Format(pReservationData.Get("id"), "NFD=0; NGS=; NG=");			// String
		vReservationAgentID 	= Format(pReservationData.Get("external_id"), "NFD=0; NGS=; NG=");	// String
		vReservationStatusID 	= pReservationData.Get("status");       							// 1 or 0
		vRoomStay				= pReservationData.Get("roomStay");     							// Map
		vCustomer				= pReservationData.Get("clientInfo");   							// Map
		vGuestNames				= pReservationData.Get("guest_names"); 								// Array of strings
		vRooms					= pReservationData.Get("rooms"); 									// Array of maps
		vExtras					= pReservationData.Get("extras"); 									// Array of maps
		vBookInfo				= pReservationData.Get("bookInfo"); 								// Map
		vExternalGroupCode		= vReservationAgentID + "/" + vReservationID;
		
		vReservationStatus		= Undefined;
		vRoomType				= Undefined;
		vRoomRate				= Undefined;
		vPeriodFrom				= Undefined;
		vPeriodTo				= Undefined;	
		vMainGuest				= Undefined;
		vRemarks				= Undefined;
		vCheckOutTime 			= Undefined;
		vCheckInTime 			= Undefined;
		vBoardType				= Undefined;
		vSource					= Undefined;
		vContract				= Undefined;
		
		#Region Data_check
		
		//Reservation ID check
		If vReservationID = Undefined OR IsBlankString(vReservationID) Then
			vResult.Success = False;
			vResult.Error	= "Reservation ID is empty!";
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation", vLogEventType, , , vResult.Error);
			Return vResult;
		EndIf;
		
		If vReservationStatusID = 1 Then 
			//Room stay check
			If vRoomStay = Undefined Then
				vResult.Success = False;
				vResult.Error	= vReservationID + ": Room stay is empty!";
				vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation", vLogEventType, , , vResult.Error);
				Return vResult;
			EndIf;
			
			//Rooms check
			If vRooms = Undefined OR vRooms.Count() = 0 Then
				vResult.Success = False;
				vResult.Error	= vReservationID + ": Rooms is empty!";
				vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation", vLogEventType, , , vResult.Error);
				Return vResult;
			EndIf;
		EndIf;
		
		#EndRegion
		
		If vReservationStatusID = 1 Then //New reservation or modification
			
			#Region Data_get
			
			//Get reservation status
			vReservationStatuses 	= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "reservationstatuses", "ID",,, vReservationStatusID);	
			If vReservationStatuses = Undefined OR vReservationStatuses.Count() = 0 Then
				vResult.Success = False;
				vResult.Error	= "Failed to find reservation status by ID:" + vReservationStatusID + "; Booking №:" + vReservationID;
				vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation", vLogEventType, , , vResult.Error);
				Return vResult;
			Else
				vReservationStatus = vReservationStatuses[0].RefKey1;
			EndIf;
			
			//Get room type	
			vBoardID	= vRoomStay.Get("roomType");
			vRoomTypes 		= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "roomtypes",,,, vBoardID);
			If vRoomTypes.Count() = 0 Then
				vResult.Success = False;
				vResult.Error	= "Failed to find roomtypes data by ID:" + vBoardID + "; Booking №:" + vReservationID;
				vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation", vLogEventType, , , vResult.Error);
				Return vResult;
			Else
				vRoomType = vRoomTypes[0].RefKey1;
			EndIf;
			
			//Get room rate
			vRoomRateID		= vRoomStay.Get("rateID");
			vRoomRates 		= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "roomrates",,, vRoomType, vRoomRateID);
			If vRoomRates.Count() = 0 Then
				vResult.Success = False;
				vResult.Error	= "Failed to find roomrates data by ID:" + vRoomRateID + "; Booking №:" + vReservationID;;
				vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation", vLogEventType, , , vResult.Error);
				Return vResult;
			Else
				vRoomRate 		= vRoomRates[0].RefKey1;
				vCheckOutTime 	= vRoomRate.ReferenceHour;
				vCheckInTime 	= vRoomRate.DefaultCheckInTime;
			EndIf;
			
			//Get periods
			vPeriodFrom		= GetDateFromISO8601(vRoomStay.Get("from"));
			vPeriodTo		= GetDateFromISO8601(vRoomStay.Get("to"));
			
			//Periods check
			If NOT ValueIsFilled(vPeriodFrom) OR NOT ValueIsFilled(vPeriodTo) Then
				vResult.Success = False;
				vResult.Error	= vReservationID + ": Period is empty!";
				vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation", vLogEventType, , , vResult.Error);
				Return vResult;
			EndIf;
			
			//Get customer data
			vMainGuest 					= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
			vMainGuest.ClientFirstName 	= vCustomer.Get("firstName");
			vMainGuest.ClientLastName 	= vCustomer.Get("lastName");
			vMainGuest.ClientPhone 		= vCustomer.Get("tel");
			vMainGuest.ClientEMail 		= vCustomer.Get("email");
			vRemarks					= vCustomer.Get("remarks");
			
			//Get extras data
			vChargeExtraServicesXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "ChargeExtraServices")); 
			If vExtras <> Undefined Then
				For each vExtra in vExtras Do
					vService		= Undefined;
					vServiceID		= vExtra.Get("id");
					vServicesData 	= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "services",,,, vServiceID);
					If vServicesData.Count() = 0 Then
						vError					= "Failed to find services data by ID:" + vServiceID + "; Booking №:" + vReservationID;
						vLogEventType 			= Enums.ExternalSystemEventTypes.Error;
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation", vLogEventType, , , vError);
						Continue;;
					Else
						vService = vServicesData[0].RefKey1;
					EndIf;

					vChargeExtraServiceRow 				= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "ChargeExtraServiceRow"));
					vChargeExtraServiceRow.ChargeDate 	= vPeriodFrom;
					vChargeExtraServiceRow.Price 		= vExtra.Get("price");
					vChargeExtraServiceRow.Quantity 	= vExtra.Get("quantity");;
					vChargeExtraServiceRow.Service 		= vService.Code;
					vChargeExtraServiceRow.Currency 	= pInteractionParameters.Currency.Code;
					vChargeExtraServicesXDTO.ChargeExtraServiceRow.Add(vChargeExtraServiceRow);
				EndDo;
			EndIf;
			
			//Get board type data
			vBoardID		= vRoomStay.Get("board");
			If vBoardID = Undefined Then
				vBoardID = 0;
			EndIf;
			
			vBoardTypes 		= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "boardtypes",,,, vBoardID);
			If vBoardTypes.Count() = 0 Then
				vError			= "Failed to find board data by ID:" + vBoardID + "; Booking №:" + vReservationID;
				vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation", vLogEventType, , , vError);
			Else
				vBoardType = vBoardTypes[0].RefKey1;
			EndIf;

			//Get source data
			If vBookInfo <> Undefined Then
				vSourceID = vBookInfo.Get("source_id");
				If Not ValueIsFilled(vSourceID) Then
					vSourceID = -99;
				EndIf;
				vSources = InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "sources",,,, vSourceID);
				If vSources.Count() = 0 Then
					vError			= "Failed to find sources data by ID:" + vSourceID + "; Booking №:" + vReservationID;
					vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation", vLogEventType, , , vError);
				Else
					vSource = vSources[0].RefKey1;
				EndIf;
			EndIf;
			
			If vSource <> Undefined Then
				vContract = vSource.Contract;
				If Not ValueIsFilled(vContract) Then
					vValidContracts = cmGetListOfValidContracts(vSource, vPeriodFrom, vPeriodTo, CurrentSessionDate());
					If vValidContracts.Count() = 1 Then
						vContract = vValidContracts.Get(0).Value;
					EndIf;
				EndIf;
			EndIf;
			#EndRegion
			
			
			vGuestNamesID 	= 0;
			vExtrasCharged 	= False;
			vCustomerPlaced	= False;
			For each vRoom in vRooms Do
				vRoomID		= vRoom.Get("roomNo");
				vAdults		= vRoom.Get("adults");
				vChildrens 	= vRoom.Get("children");
				vInfants	= vRoom.Get("infants");
				vPrices		= vRoom.Get("rates");
				
				vRoomUUID	= String(New UUID);
				
				//Get guests count
				If vAdults = Undefined Then
					vAdults = 0;
				EndIf;;
				
				If vChildrens = Undefined Then
					vChildrens = 0;
				EndIf;;
				
				If vInfants = Undefined Then
					vInfants = 0;
				EndIf;;
				
				vTotalGuests = vAdults + vChildrens + vInfants;
				
				//Get prices
				vPricesXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "PricesPerDate"));
				If vPrices <> Undefined Then
					For each vPricesRow in vPrices Do 
						vPricePerDateRow 			= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "PricePerDateRow"));
						vPricePerDateRow.Date 		= GetDateFromISO8601(vPricesRow.Get("date"));
						vPricePerDateRow.Price 		= Number(vPricesRow.Get("price_with_tax"));
						vPricePerDateRow.Currency 	= pInteractionParameters.Currency.Code;
						vPricesXDTO.PricePerDateRow.Add(vPricePerDateRow);
					EndDo;		
				EndIf;
				
				//Get accommodation template and types
				vChildAge		= pInteractionParameters.Hotel.ChildrenMaxAge;
				vInfantAge		= pInteractionParameters.Hotel.InfantsMaxAge;

				vAgesArray 		= New Array;
				
				vChildsCount 	= 1;
				While vChildsCount <= vChildrens Do
					vAgesArray.Add(vChildAge);
					vChildsCount = vChildsCount + 1;
				EndDo;
				
				vInfantsCount	= 1;
				While vInfantsCount <= vInfants Do
					vAgesArray.Add(vInfantAge);
					vInfantsCount = vInfantsCount + 1;
				EndDo;
				
				//Seearch template by ages
				vAccomodationTemplateList = cmGetAccommodationTemplateDetailsByGuestsQuantity(vAdults, vChildrens + vInfants, vAgesArray, pInteractionParameters.Hotel);
				//Filter Templates by roomType
				vClearArray = New Array;
				For each vTemplateRow in vAccomodationTemplateList Do
					If vTemplateRow.AccommodationTemplate.RoomTypes.Count() > 0 Then
						If vTemplateRow.AccommodationTemplate.RoomTypes.Find(vRoomType, "RoomType") = Undefined Then
							If ValueIsFilled(vRoomType) And Not vRoomType.IsFolder And ValueIsFilled(vRoomType.RoomClass) And vTemplateRow.AccommodationTemplate.RoomTypes.Find(vRoomType.RoomClass, "RoomClass") <> Undefined Then
								Continue;
							Else
								vClearArray.Add(vTemplateRow);
							EndIf;
						EndIf;
					EndIf;
				EndDo;
				For each vClearRow in vClearArray Do
					vAccomodationTemplateList.Delete(vClearRow);
				EndDo;
				
				// Get default template
				vAccommodationTemplate 		= Undefined;
				If vAccomodationTemplateList = Undefined or vAccomodationTemplateList.Count() = 0 Then
					vAgesAsString = "";
					For Each vAgeVal In vAgesArray Do
						vAgesAsString = vAgesAsString + ?(IsBlankString(vAgesAsString), "", ", ") + vAgeVal;
					EndDo;
					vResult.Success = False;
					vResult.Error	= "Failed to find accommodation template! " + "Adults: " + vAdults + ", Children: " + (vChildrens + vInfants) + ", Ages: " + vAgesAsString + "; Booking №:" + vReservationID + "; Room ID:" + vRoomID;
					vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation", vLogEventType, , , vResult.Error);
					Return vResult;		
				EndIf;
				
				vAccommodationTemplate 	= vAccomodationTemplateList[0].AccommodationTemplate;
				vAccomodationTypes		= vAccommodationTemplate.AccommodationTypes;
				If vAccomodationTypes.Count() = 0 Then
					vResult.Success = False;
					vResult.Error	= "Empty accomodation template! " + vAccommodationTemplate + "; Booking №:" + vReservationID + "; Room ID:" + vRoomID;
					vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation", vLogEventType, , , vResult.Error);
					Return vResult;
				EndIf;
				
				//Create reservations for each guest
				vExternalGroupReservation 	= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalGroupReservation"));
				vGuestIndex	= 1;
				vAgesIndex	= 0;
				While vGuestIndex <= vTotalGuests Do
					
					If vCustomerPlaced Then
						vNoName = False;
						vClientXDTO	= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
						If vGuestNames <> Undefined AND vGuestNames.Count() > vGuestNamesID Then
							If vGuestNames[vGuestNamesID] = vMainGuest.ClientFirstName + " " + vMainGuest.ClientLastName Then
								If vGuestNames.Count() > vGuestNamesID + 1 Then
									vGuestNamesID = vGuestNamesID + 1;
								Else
									vNoName = True;
								EndIf;
							EndIf;
							If NOT vNoName Then
								vClientXDTO.ClientLastName = vGuestNames[vGuestNamesID];
								vGuestNamesID = vGuestNamesID + 1;
							EndIf;
						EndIf;
					Else
						vClientXDTO		= ChannelManagers.CopyXDTO(vMainGuest, XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
						vCustomerPlaced = True;
					EndIf;
					
					If vGuestIndex <= vAccomodationTypes.Count() Then 
						vAccomodationType = vAccomodationTypes[vGuestIndex-1].AccommodationType.Code;
					Else 
						vAccomodationType = vAccomodationTypes[vAccomodationTypes.Count()-1].AccommodationType.Code		
					EndIf;
					
					vExternalGroupReservationRow 					= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/","WriteExternalGroupReservationRow"));
					vExternalGroupReservationRow.ReservationCode 	= vReservationID + "/" + vRoomID + "/" + String(vGuestIndex);
					vExternalGroupReservationRow.GroupCode 			= vExternalGroupCode;
					vExternalGroupReservationRow.GroupClient 		= ChannelManagers.CopyXDTO(vMainGuest, XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
					vExternalGroupReservationRow.ReservationStatus	= vReservationStatus.Code;
					vExternalGroupReservationRow.PeriodFrom			= vPeriodFrom + (vCheckInTime - BegOfDay(vCheckInTime));
					vExternalGroupReservationRow.PeriodTo			= vPeriodTo + (vCheckOutTime - BegOfDay(vCheckOutTime));;
					vExternalGroupReservationRow.Hotel				= pInteractionParameters.Hotel.Code;
					vExternalGroupReservationRow.RoomType			= TrimAll(vRoomType.Code);
					vExternalGroupReservationRow.AccommodationType	= TrimAll(vAccomodationType);
					vExternalGroupReservationRow.NumberOfRooms		= 1;
					vExternalGroupReservationRow.NumberOfPersons	= 1;
					vExternalGroupReservationRow.ExternalSystemCode	= pInteractionParameters.InteractionID;
					vExternalGroupReservationRow.DoPosting			= True;
					vExternalGroupReservationRow.RoomRate			= TrimAll(vRoomRate.Code);
					vExternalGroupReservationRow.ReservationRemarks = vRemarks; 
					vExternalGroupReservationRow.Room 				= vRoomUUID;
					vExternalGroupReservationRow.Client				= vClientXDTO;
					
					If vGuestIndex = 1 And ValueIsFilled(vAccommodationTemplate) Then
						vExternalGroupReservationRow.AccommodationTemplate = TrimR(vAccommodationTemplate.Code);
					EndIf;
					
					If (vTotalGuests - vGuestIndex) < (vChildrens + vInfants) Then
						vExternalGroupReservationRow.GuestAge		= vAgesArray[vAgesIndex];
						vAgesIndex = vAgesIndex + 1;
					EndIf;
					
					If vSource <> Undefined Then
						vExternalGroupReservationRow.Agent			= TrimAll(vSource.Code);
						vExternalGroupReservationRow.Customer		= TrimAll(vSource.Code);
						//vExternalGroupReservationRow.Contract		= TrimAll(vContract.Code);
					EndIf;
					
					If vBoardType <> Undefined Then
						vExternalGroupReservationRow.MealBoardTerm	= TrimAll(vBoardType.Code);
					EndIf;

					
					If vGuestIndex = 1 Then
						vExternalGroupReservationRow.PricesPerDate	= vPricesXDTO;
					Else					
						vPricesCopy = ChannelManagers.CopyXDTO(vPricesXDTO, XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "PricesPerDate"));
						vPricesCopy = ResetXDTOPrices(vPricesCopy);					
						vExternalGroupReservationRow.PricesPerDate	= vPricesCopy;
					EndIf;
					
					If NOT vExtrasCharged Then
						vExternalGroupReservationRow.ChargeExtraServices = vChargeExtraServicesXDTO;
						vExtrasCharged = True;
					EndIf;
					
					vExternalGroupReservation.WriteExternalGroupReservationRow.Add(vExternalGroupReservationRow);
					vGuestIndex = vGuestIndex + 1;			
				EndDo;
				
				vAnswerXDTO = cmWriteExternalGroupReservation(vExternalGroupReservation, , True);
				If ValueIsFilled(vAnswerXDTO.ErrorDescription) Then
					vResult.Success = False;
					vResult.Error	= "Failed to create reservation: " + vAnswerXDTO.ErrorDescription + "; Booking №:" + vReservationID + "; Room ID:" + vRoomID;
					vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation", vLogEventType, , , vResult.Error);
					Continue;
				Else
					vResult.Success = True;	
				EndIf;
			EndDo;
			
			
		Else //Cancellation
			
			//Get reservation status
			vReservationStatuses 	= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "reservationstatuses", "ID",,, vReservationStatusID);
			vReservationStatus		= Undefined;
			If vReservationStatuses = Undefined OR vReservationStatuses.Count() = 0 Then
				vResult.Success = False;
				vResult.Error	= "Failed to find reservation status by ID:" + vReservationStatusID + "; Booking №:" + vReservationID;
				vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation", vLogEventType, , , vResult.Error);
				Return vResult;
			Else
				For each vRow in vReservationStatuses Do
					If vRow.ID = vReservationStatusID Then
						vReservationStatus = vRow.RefKey1;
					EndIf;
				EndDo;
			EndIf;
			
			If vReservationStatus = Undefined Then
				vResult.Success = False;
				vResult.Error	= "Failed to find reservation status by ID:" + vReservationStatusID + "; Booking №:" + vReservationID;
				vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation", vLogEventType, , , vResult.Error);
				Return vResult;
			EndIf;
			
			vCancelResult 	= cmCancelGroupReservation(vExternalGroupCode, TrimAll(pInteractionParameters.Hotel.Code), pInteractionParameters.Code,,,,vReservationStatus);
			vResult.Success = True;
			
		EndIf;
		
	Except
		vError			= ErrorDescription();
		vResult.Success = False;
		vResult.Error	= "Unexpected error! " + vError;
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation", vLogEventType, , , vResult.Error);
		Return vResult;
	EndTry;

	Return vResult;
	
EndFunction

Function GetDateFromISO8601(pDateString)
	
	vResult = Date("00010101");
	
	vDateString	= StrReplace(pDateString, "-", "");
	vDateString	= StrReplace(vDateString, ":", "");
	vDateString	= StrReplace(vDateString, "T", "");

	vResult	= Date(vDateString);
	
	Return vResult;
	
EndFunction

Function ResetXDTOPrices(pPrices)
	
	For each vPricePerDate in pPrices.PricePerDateRow Do 
		vPricePerDate.Price 		= 0;
	EndDo;
	
	Return pPrices;
	
EndFunction
