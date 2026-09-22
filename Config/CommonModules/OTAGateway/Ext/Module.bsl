
Procedure SyncData(pInteractionParameters, pAccountID, pAmountOfDaysToUpdate = 100, pSkipPricesCacheUpdate = True, pFullUpdate = False, pLoadAdultGuestsAmountFromExtraDataArray = False, pLoadChildGuestsAmountFromExtraDataArray = False, pGetPrices = True) Export
	// Time when processing has started
	vCurrentSessionDate = CurrentSessionDate();
	
	vUpdateCachedPrices = False;
	If pFullUpdate And Not pSkipPricesCacheUpdate Then
		vUpdateCachedPrices = True;
	EndIf;

	If pAmountOfDaysToUpdate = 0 Then
		pAmountOfDaysToUpdate = 100;
	EndIf;

	// Lock external integration to be sure that it could be updated
	vExternalInteractionObj = pInteractionParameters.GetObject();
	While True Do
		Try
			vExternalInteractionObj.Lock();
			// Time when processing has started
			vCurrentSessionDate = CurrentSessionDate();
			Break;
		Except
			If Not pFullUpdate Then
				Break;
			Else
				If (CurrentSessionDate() - vCurrentSessionDate) > (18*3600) Then
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SyncData", Enums.ExternalSystemEventTypes.Warning, , , 
					                                                            NStr("en='It was not possible to block the interaction with the external system to perform the exchange for 18 hours long!'; 
					                                                                 |ru='За 18 часов не удалось установить блокировку на взаимодействие с внешней системой для выполнения обмена!'; 
																					 |de='18 Stunden lang war es nicht möglich, die Interaktion mit dem externen System zu blockieren, um den Austausch durchzuführen!'"));
					Return;
				Else
					cmWait(30);
				EndIf;
			EndIf;
		EndTry;
	EndDo;
	
	Try
		// Get reservations
		If vExternalInteractionObj.IsLocked() Then
			vExternalInteractionObj.Read();
			vExternalInteractionObj.Status = Enums.IntegrationStatuses.Warning;
			vExternalInteractionObj.ErrorDescription = NStr("en = 'Bookings are being loaded...'; de = 'Buchungen werden heruntergeladen...'; ru = 'Загружаются бронирования...'");
			vExternalInteractionObj.Write();
		EndIf;

		GetBookings(pInteractionParameters, pAccountID, pLoadAdultGuestsAmountFromExtraDataArray, pLoadChildGuestsAmountFromExtraDataArray, pGetPrices);
		
		// Sync availability
		If vExternalInteractionObj.IsLocked() Then
			vExternalInteractionObj.Read();
			vExternalInteractionObj.Status = Enums.IntegrationStatuses.Warning;
			vExternalInteractionObj.ErrorDescription = NStr("en = 'The remaining available rooms are being unloaded...'; de = 'Reste von freien Zimmern werden ausgelagert...'; ru = 'Выгружаются остатки свободных номеров...'");
			vExternalInteractionObj.Write();
		EndIf;

		UpdateAvailability(pInteractionParameters, ,  pAccountID, pAmountOfDaysToUpdate, pFullUpdate);
		
		If vExternalInteractionObj.IsLocked() Then
			If pFullUpdate Then
				// Sync prices
				vExternalInteractionObj.Read();
				vExternalInteractionObj.Status = Enums.IntegrationStatuses.Warning;
				vExternalInteractionObj.ErrorDescription = NStr("en = 'Prices are being uploaded...'; de = 'Die Preise werden ausgelagert...'; ru = 'Выгружаются цены...'");
				vExternalInteractionObj.Write();     

				CreateAndUpdatePrices(pInteractionParameters, , pAccountID, pAmountOfDaysToUpdate, pFullUpdate, vUpdateCachedPrices);
				
				// Sync restrictions
				vRoomRatesData = InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "roomrates");
				If vRoomRatesData.Columns.Find("ID") <> Undefined Then
					vExternalInteractionObj.Read();
					vExternalInteractionObj.Status = Enums.IntegrationStatuses.Warning;
					vExternalInteractionObj.ErrorDescription = NStr("en = 'Restrictions are being uploaded...'; de = 'Einschränkungen werden entladen...'; ru = 'Выгружаются ограничения...'");
					vExternalInteractionObj.Write();

					For each vRoomRateDataRow in vRoomRatesData Do
						If ValueIsFilled(vRoomRateDataRow.ID) Then
							CreateAndUpdateRestrictionPlans(pInteractionParameters, , vRoomRateDataRow.RefKey1, vRoomRateDataRow.ID, pAccountID, pAmountOfDaysToUpdate, pFullUpdate);
						EndIf;
					EndDo;
				EndIf;
			EndIf;
		EndIf;
		
		// Update session and last activity times
		If vExternalInteractionObj.IsLocked() Then
			vLastSyncTimeUpdateError = ChannelManagers.UpdateLastSyncTime(pInteractionParameters, pFullUpdate, vCurrentSessionDate, "", True, pFullUpdate, pFullUpdate);
			If Not IsBlankString(vLastSyncTimeUpdateError) Then
				Raise vLastSyncTimeUpdateError;
			EndIf;
		EndIf;
	Except
		vErrorText = cmGetRootErrorDescription(ErrorInfo());
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SyncData", Enums.ExternalSystemEventTypes.Error, , , vErrorText, pInteractionParameters.MaxLogLenght);
	EndTry;
	
	// Unlock interaction
	If vExternalInteractionObj.IsLocked() Then
		vExternalInteractionObj.Unlock();
	EndIf;
EndProcedure // SyncData

#Region API

Function Ping(pInteractionParameters, pGetRaw = False) Export
	
	vResult 		= New Structure("Success, Error, Raw", False, "");
	vMessageName 	= "ping";
	vResponse		= Undefined;
	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Interaction parameters item should be created and setup in the Integrations/External system interactions catalog!";
			Return vResult;
		EndIf;
		
		vURL			= pInteractionParameters.HttpAddress + vMessageName;
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "POST", vMessageName);
		vResponseStatus = CheckResponseStatus(vResponse);
		
		If vResponseStatus.Success = False Then
			vResult.Error = vResponseStatus.StatusDescription;
		EndIf;
		
		vResult.Success = vResponseStatus.Success;
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, ,vRawValue , vResult.Error, pInteractionParameters.MaxLogLenght);
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

#Region Auth

Function GetNewToken(pInteractionParameters, pGetRaw = False) Export
	
	vResult 		= New Structure("Success, Error, Raw", False, "");
	vMessageName 	= "auth";
	vResponse		= Undefined;
	vParametersMap  = New Map;
	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error = "Interaction parameters item should be created and setup in the Integrations/External system interactions catalog!";
			Return vResult;
		EndIf;
		
		vParametersMap.Insert("username", pInteractionParameters.Login);
		vParametersMap.Insert("password", pInteractionParameters.Password);

		vURL			= pInteractionParameters.HttpAddress + vMessageName;
		vRequestBody	= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "POST", vMessageName, vRequestBody, "application/json");
		vResponseStatus = CheckResponseStatus(vResponse);
		
		vNewToken		= Undefined;
		vResult.Success = vResponseStatus.Success;
		If vResponseStatus.Success = False Then
			vResult.Error = vResponseStatus.StatusDescription;
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vRequestBody, vResponse.Body, vResult.Error, pInteractionParameters.MaxLogLenght);
			Return vResult;
		Else
			vResponseMap = Catalogs.DataConvertationRules.JSONtoMap(vResponse.Body);
			For each vKeyAndValue in vResponseMap Do
				If vKeyAndValue.Key = "token" Then
					vNewToken = vKeyAndValue.Value;	
				EndIf;
			EndDo;
		EndIf;
		
		If ValueIsFilled(vNewToken) Then
			vInterectionParametersObj 					= pInteractionParameters.GetObject();
			vInterectionParametersObj.SessionID 		= vNewToken;
			vInterectionParametersObj.SessionStartTime 	= CurrentSessionDate();
			vInterectionParametersObj.Write();
		Else
			vResult.Success = False;
			vResult.Error 	= "Didnt recieve new token from API";
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vRequestBody, vResponse.Body, vResult.Error, pInteractionParameters.MaxLogLenght);
		EndIf;
		
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vRawValue, vResult.Error, pInteractionParameters.MaxLogLenght);
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

Function GetUserInfo(pInteractionParameters, pGetRaw = False) Export
	
	vResult 		= New Structure("Success, ResultMap, Error, Raw", False, Undefined, "");
	vMessageName 	= "auth";
	vResponse		= Undefined;
	vParametersMap  = New Map;
	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error = "Interaction parameters item should be created and setup in the Integrations/External system interactions catalog!";
			Return vResult;
		EndIf;
		
		// Check token
		If IsBlankString(pInteractionParameters.SessionID) Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error; 
				Return vResult;
			EndIf;
		EndIf;
		
		vParametersMap.Insert("token", pInteractionParameters.SessionID);

		vURL			= pInteractionParameters.HttpAddress + vMessageName;
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "GET", vMessageName, , , ,vParametersMap);
		vResponseStatus = CheckResponseStatus(vResponse);
		
		//Check if token needs to be updated and update it if needed
		If vResponse.StatusCode = 401 Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error; 
				Return vResult;
			EndIf;
			
			vParametersMap.Insert("token", pInteractionParameters.SessionID);
			vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "GET", vMessageName, , , ,vParametersMap);
			vResponseStatus = CheckResponseStatus(vResponse);
		EndIf;

		vResult.Success = vResponseStatus.Success;
		If vResponseStatus.Success = False Then
			vResult.Error = vResponseStatus.StatusDescription;
			Return vResult;
		Else
			vResponseMap 		= Catalogs.DataConvertationRules.JSONtoMap(vResponse.Body);
			vResult.ResultMap 	= vResponseMap;
		EndIf;
			
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vRawValue, vResult.Error, pInteractionParameters.MaxLogLenght);
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

Function DeleteToken(pInteractionParameters, pGetRaw = False) Export
	
	vResult 		= New Structure("Success, Error, Raw", False, "");
	vMessageName 	= "auth";
	vResponse		= Undefined;
	vParametersMap  = New Map;
	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error = "Interaction parameters item should be created and setup in the Integrations/External system interactions catalog!";
			Return vResult;
		EndIf;
		If IsBlankString(pInteractionParameters.SessionID) Then
			vResult.Success = True;
			Return vResult;
		EndIf;
		
		If IsBlankString(pInteractionParameters.SessionID) Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error; 
				Return vResult;
			EndIf;
		EndIf;
		
		vParametersMap.Insert("token", pInteractionParameters.SessionID);

		vURL			= pInteractionParameters.HttpAddress + vMessageName;
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "DELETE", vMessageName,,,, vParametersMap);
		vResponseStatus = CheckResponseStatus(vResponse);
		
		//Check if token needs to be updated and update it if needed
		If vResponse.StatusCode = 401 Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error; 
				Return vResult;
			EndIf;
			
			vParametersMap.Insert("token", pInteractionParameters.SessionID);
			vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "DELETE", vMessageName, , , ,vParametersMap);
			vResponseStatus = CheckResponseStatus(vResponse);
		EndIf;

		vResult.Success = vResponseStatus.Success;
		If vResponseStatus.Success = False Then
			vResult.Error = vResponseStatus.StatusDescription;
			Return vResult;
		EndIf;
			
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vRawValue, vResult.Error, pInteractionParameters.MaxLogLenght);
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

#Region Room_types

Function CreateAndUpdateRoomTypes(pInteractionParameters, pGetRaw = False, rRoomTypesTable, pParentID = Undefined,  pAccountID, pFullUpdate = False) Export
	
	vResult 		= New Structure("Success, Error, Raw", True, "");
	vMessageName 	= "roomtypes";
	vResponse		= Undefined;
	vParametersMap  = New Map;
	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Interaction parameters item should be created and setup in the Integrations/External system interactions catalog!";
			Return vResult;
		EndIf;
		
		// Check token
		If IsBlankString(pInteractionParameters.SessionID) Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error; 
				Return vResult;
			EndIf;
		EndIf;
		
		For each vRoomType in rRoomTypesTable Do
			
			If NOT ValueIsFilled(vRoomType.ID) OR vRoomType.isModified OR pFullUpdate Then
				
				//Mandatory
				vParametersMap  = New Map;
				vParametersMap.Insert("token", 				pInteractionParameters.SessionID);
				vParametersMap.Insert("account_id", 		pAccountID);
				vParametersMap.Insert("name", 				vRoomType.Name);
				vParametersMap.Insert("adults", 			vRoomType.AccommodationTemplate.NumberOfAdults);
				vParametersMap.Insert("price", 				vRoomType.DefaultPrice);
				
				If NOT ValueIsFilled(vRoomType.ID) Then 
					vMethod = "POST";
				Else
					vMethod = "PUT";
					vParametersMap.Insert("roomtype_id", 	vRoomType.ID);
				EndIf;
				
				If vRoomType.AccommodationTemplate.IsForFolioSplit Then
					vParametersMap.Insert("accommodation_type", 2);
				Else
					vParametersMap.Insert("accommodation_type", 0);
				EndIf;
				
				//Additional
				vParametersMap.Insert("children", 		vRoomType.AccommodationTemplate.NumberOfChildren);
				vParametersMap.Insert("enabled",		Number(vRoomType.Enabled));
				vParametersMap.Insert("enabled_ota",	Number(vRoomType.EnabledOTA));
				vParametersMap.Insert("description",	vRoomType.Description);
				
				If ValueIsFilled(pParentID) Then
					vParametersMap.Insert("parent_id",	pParentID);
				EndIf;

				vURL			= pInteractionParameters.HttpAddress + vMessageName;
				vRequestBody	= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
				vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, vMethod, vMessageName, vRequestBody, "application/json");
				vResponseStatus = CheckResponseStatus(vResponse);
				
				//Check if token needs to be updated and update it if needed
				If vResponse.StatusCode = 401 Then
					vTokenUpdateResult = GetNewToken(pInteractionParameters);
					If NOT vTokenUpdateResult.Success Then
						vResult.Success = False;
						vResult.Error = vTokenUpdateResult.Error;
						Return vResult;
					EndIf;
					
					vParametersMap.Insert("token", pInteractionParameters.SessionID);
					vRequestBody			= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
					vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, vMethod, vMessageName, vRequestBody, "application/json");
					vResponseStatus 		= CheckResponseStatus(vResponse);
				EndIf;
				
				vRoomTypeID		= Undefined;
				vResult.Success = vResponseStatus.Success;
				If vResponseStatus.Success = False Then
					vResult.Error = vResponseStatus.StatusDescription;
					Return vResult;
				Else
					vResponseMap = Catalogs.DataConvertationRules.JSONtoMap(vResponse.Body);
					For each vKeyAndValue in vResponseMap Do
						If vKeyAndValue.Key = "roomtype_id" Then
							vRoomTypeID = vKeyAndValue.Value;	
						EndIf;
					EndDo;
				EndIf;
				
				If ValueIsFilled(vRoomTypeID) Then
					vRoomType.ID = vRoomTypeID; 	
				Else
					vResult.Success = False;
					vResult.Error 	= "Didnt recieve roomtype_id from API";
				EndIf;
			EndIf;
			
		EndDo;
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vRawValue, vResult.Error, pInteractionParameters.MaxLogLenght);
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

Function GetRoomTypes(pInteractionParameters, pGetRaw = False, pAccountID) Export
	
	vResult 		= New Structure("Success, ResultMap, Error, Raw", False, Undefined, "");
	vMessageName 	= "roomtypes";
	vResponse		= Undefined;
	vParametersMap  = New Map;
	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error = "Interaction parameters item should be created and setup in the Integrations/External system interactions catalog!";
			Return vResult;
		EndIf;
		
		// Check token
		If IsBlankString(pInteractionParameters.SessionID) Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error; 
				Return vResult;
			EndIf;
		EndIf;
		
		vParametersMap.Insert("token", 		pInteractionParameters.SessionID);
		vParametersMap.Insert("account_id", pAccountID);

		vURL			= pInteractionParameters.HttpAddress + vMessageName;
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "GET", vMessageName, , , , vParametersMap);
		vResponseStatus = CheckResponseStatus(vResponse);
		
		//Check if token needs to be updated and update it if needed
		If vResponse.StatusCode = 401 Then
			vTokenUpdateResult 	= GetNewToken(pInteractionParameters);
			
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error	= vTokenUpdateResult.Error;
				Return vResult;
			EndIf;
			
			vParametersMap.Insert("token", pInteractionParameters.SessionID);
			vRequestBody			= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
			vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "GET", vMessageName, , , , vParametersMap);
			vResponseStatus 		= CheckResponseStatus(vResponse);
		EndIf;
		
		vResult.Success = vResponseStatus.Success;
		If vResponseStatus.Success = False Then
			vResult.Error = vResponseStatus.StatusDescription;
			Return vResult;
		Else
			vResponseMap 		= Catalogs.DataConvertationRules.JSONtoMap(vResponse.Body);
			vResult.ResultMap 	= vResponseMap;
		EndIf;
			
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vRawValue, vResult.Error, pInteractionParameters.MaxLogLenght);
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

Function DeleteRoomType(pInteractionParameters, pGetRaw = False, pAccountID, pID) Export
	
	vResult 		= New Structure("Success, ResultMap, Error, Raw", False, Undefined, "");
	vMessageName 	= "roomtypes";
	vResponse		= Undefined;
	vParametersMap  = New Map;
	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error = "Interaction parameters item should be created and setup in the Integrations/External system interactions catalog!";
			Return vResult;
		EndIf;
		
		// Check token
		If IsBlankString(pInteractionParameters.SessionID) Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error; 
				Return vResult;
			EndIf;
		EndIf;
		
		vParametersMap.Insert("token", pInteractionParameters.SessionID);
		vParametersMap.Insert("account_id", pAccountID);
		vRequestBody	= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);

		vURL			= pInteractionParameters.HttpAddress + vMessageName + "/" + pID;
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "DELETE", vMessageName, vRequestBody, "application/json");
		vResponseStatus = CheckResponseStatus(vResponse);
		
		//Check if token needs to be updated and update it if needed
		If vResponse.StatusCode = 401 Then
			vTokenUpdateResult 	= GetNewToken(pInteractionParameters);
			
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error	= vTokenUpdateResult.Error;
				Return vResult;
			EndIf;
			
			vParametersMap.Insert("token", pInteractionParameters.SessionID);
			vRequestBody			= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
			vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "DELETE", vMessageName, vRequestBody, "application/json");
			vResponseStatus 		= CheckResponseStatus(vResponse);
		EndIf;
		
		vResult.Success = vResponseStatus.Success;
		If vResponseStatus.Success = False Then
			vResult.Error = vResponseStatus.StatusDescription;
			Return vResult;
		Else
			vResponseMap 		= Catalogs.DataConvertationRules.JSONtoMap(vResponse.Body);
			vResult.ResultMap 	= vResponseMap;
		EndIf;
			
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vRawValue, vResult.Error, pInteractionParameters.MaxLogLenght);
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

#Region Room_rates

Function CreateAndUpdateRoomRates(pInteractionParameters, pGetRaw = False, rRoomRatesTable,  pAccountID, pFullUpdate = False, pUpdateCachedPrices = False, pAmountOfDaysToUpdate = 100, pUpdateRestrictionsPlansAfterLoad = True) Export
	
	vResult 		= New Structure("Success, Error, Raw", True, "");
	vMessageName 	= "plans";
	vResponse		= Undefined;
	vParametersMap  = New Map;
	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Interaction parameters item should be created and setup in the Integrations/External system interactions catalog!";
			Return vResult;
		EndIf;
		
		// Check token
		If IsBlankString(pInteractionParameters.SessionID) Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error; 
				Return vResult;
			EndIf;
		EndIf;
		
		For each vRoomRate in rRoomRatesTable Do
			
			vFullUpdateRestrictions = pFullUpdate;
			
			If NOT ValueIsFilled(vRoomRate.ID) OR vRoomRate.isModified OR pFullUpdate Then
				
				//Mandatory
				vParametersMap  = New Map;
				vParametersMap.Insert("token", 				pInteractionParameters.SessionID);
				vParametersMap.Insert("account_id", 		pAccountID);
				vParametersMap.Insert("name", 				vRoomRate.Name);
				vParametersMap.Insert("warranty_type", 		"no");
				
				If NOT ValueIsFilled(vRoomRate.ID) Then 
					vMethod 	= "POST";
					vPricesMap	= GetPricesMap(pInteractionParameters, vRoomRate.RoomRate,,, True, True, pUpdateCachedPrices);
					vParametersMap.Insert("default_price", 	vPricesMap);
					vFullUpdateRestrictions = True;
				Else
					vMethod 	= "PUT";
					vParametersMap.Insert("plan_id", 	vRoomRate.ID);
				EndIf;			
				
				//Additional
				vParametersMap.Insert("enabled",				Number(vRoomRate.Enabled));
				vParametersMap.Insert("enabled_ota",			Number(vRoomRate.EnabledOTA));
				vParametersMap.Insert("description",			vRoomRate.Description);
				vParametersMap.Insert("order",					vRoomRate.IndexNumber);
				vParametersMap.Insert("cancellation_rules",		vRoomRate.CancellationRules);
				vParametersMap.Insert("default",				Number(vRoomRate.Default));
				
				
				vRestrictionPlanID	= Undefined;
				vRestrictionsData		=  InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "restrictionplans", "ID", vRoomRate.RoomRate, , , vRoomRate.ID);
				If vRestrictionsData.Columns.Find("ID") <> Undefined AND vRestrictionsData.Count() > 0 Then
					vRestrictionPlanID = vRestrictionsData[0].ID;	
				EndIf;

				If ValueIsFilled(vRestrictionPlanID) Then
					vParametersMap.Insert("restriction_plan_id", 	Number(vRestrictionPlanID));
				EndIf;
				
				vNutrition = String(Number(vRoomRate.Breakfast)) + String(Number(vRoomRate.Lunch)) + String(Number(vRoomRate.Dinner));				
				vParametersMap.Insert("nutrition", vNutrition);
				
				vURL			= pInteractionParameters.HttpAddress + vMessageName;
				vRequestBody	= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
				vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, vMethod, vMessageName, vRequestBody, "application/json");
				vResponseStatus = CheckResponseStatus(vResponse);
				
				//Check if token needs to be updated and update it if needed
				If vResponse.StatusCode = 401 Then
					vTokenUpdateResult = GetNewToken(pInteractionParameters);
					If NOT vTokenUpdateResult.Success Then
						vResult.Success = False;
						vResult.Error = vTokenUpdateResult.Error;
						Return vResult;
					EndIf;
					
					vParametersMap.Insert("token", pInteractionParameters.SessionID);
					vRequestBody			= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
					vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, vMethod, vMessageName, vRequestBody, "application/json");
					vResponseStatus 		= CheckResponseStatus(vResponse);
				EndIf;
				
				vRoomRateID		= Undefined;
				vResult.Success = vResponseStatus.Success;
				If vResponseStatus.Success = False Then
					vResult.Error = vResponseStatus.StatusDescription;
					Return vResult;
				Else
					vResponseMap = Catalogs.DataConvertationRules.JSONtoMap(vResponse.Body);
					For each vKeyAndValue in vResponseMap Do
						If vKeyAndValue.Key = "plan_id" Then
							vRoomRateID = vKeyAndValue.Value;	
						EndIf;
					EndDo;
				EndIf;
				
				If ValueIsFilled(vRoomRateID) Then
					vRoomRate.ID = vRoomRateID; 	
				Else
					vResult.Success = False;
					vResult.Error 	= "Didnt recieve plan_id from API";
				EndIf;
			EndIf;
			
			If ValueIsFilled(vRoomRate.ID) Then
				vRestrictionsResult = CreateAndUpdateRestrictionPlans(pInteractionParameters,, vRoomRate.RoomRate, vRoomRate.ID, pAccountID, pAmountOfDaysToUpdate, vFullUpdateRestrictions, vRoomRate.RestrictionPlanID);
				If vRestrictionsResult.Success = False Then
					vResult.Success = False;
					vResult.Error 	= vRestrictionsResult.Error;
				ElsIf ValueIsFilled(vRestrictionsResult.RestrictionPlanID) Then
					vRoomRate.RestrictionPlanID = vRestrictionsResult.RestrictionPlanID;
					If pUpdateRestrictionsPlansAfterLoad Then
						 CreateAndUpdateRoomRates(pInteractionParameters, pGetRaw, rRoomRatesTable,  pAccountID, False, False, pAmountOfDaysToUpdate, False);
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vRawValue, vResult.Error, pInteractionParameters.MaxLogLenght);
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

Function GetRoomRates(pInteractionParameters, pGetRaw = False, pAccountID) Export
	
	vResult 		= New Structure("Success, ResultMap, Error, Raw", False, Undefined, "");
	vMessageName 	= "plans";
	vResponse		= Undefined;
	vParametersMap  = New Map;
	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Interaction parameters item should be created and setup in the Integrations/External system interactions catalog!";
			Return vResult;
		EndIf;
		
		// Check token
		If IsBlankString(pInteractionParameters.SessionID) Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error; 
				Return vResult;
			EndIf;
		EndIf;
		
		vParametersMap.Insert("token", 		pInteractionParameters.SessionID);
		vParametersMap.Insert("account_id", pAccountID);

		vURL			= pInteractionParameters.HttpAddress + vMessageName;
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "GET", vMessageName, , , , vParametersMap);
		vResponseStatus = CheckResponseStatus(vResponse);
		
		//Check if token needs to be updated and update it if needed
		If vResponse.StatusCode = 401 Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error;
				Return vResult;
			EndIf;
			
			vParametersMap.Insert("token", pInteractionParameters.SessionID);
			vRequestBody			= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
			vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "GET", vMessageName, , , , vParametersMap);
			vResponseStatus 		= CheckResponseStatus(vResponse);
		EndIf;
		
		vResult.Success = vResponseStatus.Success;
		If vResponseStatus.Success = False Then
			vResult.Error = vResponseStatus.StatusDescription;
			Return vResult;
		Else
			vResponseMap 		= Catalogs.DataConvertationRules.JSONtoMap(vResponse.Body);
			vResult.ResultMap 	= vResponseMap;
		EndIf;
			
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vRawValue, vResult.Error, pInteractionParameters.MaxLogLenght);
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

Function DeleteRoomRate(pInteractionParameters, pGetRaw = False, pAccountID, pRoomRate) Export
	
	vResult 		= New Structure("Success, ResultMap, Error, Raw", True, Undefined, "");
	vMessageName 	= "plans";
	vResponse		= Undefined;
	vParametersMap  = New Map;
	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Interaction parameters item should be created and setup in the Integrations/External system interactions catalog!";
			Return vResult;
		EndIf;
		
		// Check token
		If IsBlankString(pInteractionParameters.SessionID) Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error; 
				Return vResult;
			EndIf;
		EndIf;
		
		vParametersMap.Insert("token", 		pInteractionParameters.SessionID);
		vParametersMap.Insert("account_id", pAccountID);
		vRequestBody	= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);

		vRestrictionPlanID		= Undefined;
		vRestrictionsData		=  InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "restrictionplans", "ID", pRoomRate);
		If vRestrictionsData.Columns.Find("ID") <> Undefined AND vRestrictionsData.Count() > 0 Then
			vRestrictionPlanID = vRestrictionsData[0].ID;	
		EndIf;
		
		vRoomRateID			= Undefined;
		vRoomRateData		=  InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "roomrates", "ID", pRoomRate);
		If vRoomRateData.Columns.Find("ID") <> Undefined AND vRoomRateData.Count() > 0 Then
			vRoomRateID = vRoomRateData[0].ID;
		Else
			Return vResult;
		EndIf;

		If vRoomRateID = Undefined Then
			Return vResult;
		EndIf;
		
		vURL			= pInteractionParameters.HttpAddress + vMessageName + "/" + vRoomRateID;
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "DELETE", vMessageName, vRequestBody, "application/json");
		vResponseStatus = CheckResponseStatus(vResponse);
		
		//Check if token needs to be updated and update it if needed
		If vResponse.StatusCode = 401 Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error;
				vLogEventType = Enums.ExternalSystemEventTypes.Error;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, , , vResult.Error, pInteractionParameters.MaxLogLenght);
				Return vResult;
			EndIf;
			
			vParametersMap.Insert("token", pInteractionParameters.SessionID);
			vRequestBody			= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
			vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "DELETE", vMessageName, vRequestBody, "application/json");
			vResponseStatus 		= CheckResponseStatus(vResponse);
		EndIf;
		
		vResult.Success = vResponseStatus.Success;
		If vResponseStatus.Success = False Then
			vResult.Error = vResponseStatus.StatusDescription;
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vRequestBody, vResponse.Body, vResult.Error, pInteractionParameters.MaxLogLenght);
			Return vResult;
		Else
			vResponseMap 		= Catalogs.DataConvertationRules.JSONtoMap(vResponse.Body);
			vResult.ResultMap 	= vResponseMap;
			
			If vRestrictionPlanID <> Undefined Then
				DeleteRestrictionPlan(pInteractionParameters, , pAccountID, vRestrictionPlanID); 
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
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vRawValue, vResult.Error, pInteractionParameters.MaxLogLenght);
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

#Region Prices

Function CreateAndUpdatePrices(pInteractionParameters, pGetRaw = False,  pAccountID, pAmountOfDaysToUpdate = 100, pFullUpdate = False, pUpdateCachedPrices = False) Export
	
	vResult 		= New Structure("Success, Error, Raw", True, "");
	vMessageName 	= "prices";
	vResponse		= Undefined;
	vParametersMap  = New Map;
	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Interaction parameters item should be created and setup in the Integrations/External system interactions catalog!";
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, , , vResult.Error, pInteractionParameters.MaxLogLenght);
			Return vResult;
		EndIf;
		
		// Check token
		If IsBlankString(pInteractionParameters.SessionID) Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error; 
				Return vResult;
			EndIf;
		EndIf;
		
		vRoomRates = New ValueTable;
		vRoomRates.Columns.Add("RoomRate");
		vRoomRates.Columns.Add("ID");
		
		vRoomRateData	= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "roomrates", "ID");
		If vRoomRateData.Columns.Find("ID") <> Undefined Then
			For each vRoomRate in vRoomRateData Do
				vNewRow 			= vRoomRates.Add();
				vNewRow.RoomRate 	= vRoomRate.RefKey1;
				vNewRow.ID 			= vRoomRate.ID;
			EndDo;
		EndIf;
		
		For each vRoomRate in vRoomRates Do
			
			If ValueIsFilled(vRoomRate.ID) Then
				
				//Mandatory
				vParametersMap  = New Map;
				vParametersMap.Insert("token", 				pInteractionParameters.SessionID);
				vParametersMap.Insert("account_id", 		pAccountID);
				vParametersMap.Insert("plan_id", 			vRoomRate.ID);
				
				vPeriodFrom = BegOfDay(CurrentDate());
				vPeriodTo	= vPeriodFrom + 24*60*60*pAmountOfDaysToUpdate;
				
				vNothingToUpdate 	= True;
				vPricesMap			= GetPricesMap(pInteractionParameters, vRoomRate.RoomRate, vPeriodFrom, vPeriodTo, False, pFullUpdate, pUpdateCachedPrices, vNothingToUpdate); 
				vParametersMap.Insert("price", vPricesMap);
				
				If vPricesMap = Undefined Then
					vResult.Success = False;
					vResult.Error 	= "Failed to get prices table!";
					vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, , , vResult.Error, pInteractionParameters.MaxLogLenght);
					Return vResult;	
				ElsIf vNothingToUpdate Then
					Continue;
				EndIf;
				
				vURL			= pInteractionParameters.HttpAddress + vMessageName;
				vRequestBody	= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
				vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "POST", vMessageName, vRequestBody, "application/json");
				vResponseStatus = CheckResponseStatus(vResponse);
				
				//Check if token needs to be updated and update it if needed
				If vResponse.StatusCode = 401 Then
					vTokenUpdateResult 	= GetNewToken(pInteractionParameters);
					
					If NOT vTokenUpdateResult.Success Then
						vResult.Success = False;
						vResult.Error	= vTokenUpdateResult.Error;
						vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, , , vResult.Error, pInteractionParameters.MaxLogLenght);
						Return vResult;
					EndIf;
					
					vParametersMap.Insert("token", pInteractionParameters.SessionID);
					vRequestBody			= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
					vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "POST", vMessageName, vRequestBody, "application/json");
					vResponseStatus 		= CheckResponseStatus(vResponse);
				EndIf;
				
				vRoomTypeID		= Undefined;
				vResult.Success = vResponseStatus.Success;
				If vResponseStatus.Success = False Then
					vResult.Error 	= vResponseStatus.StatusDescription;
					vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vResponse.Body, vResult.Error, pInteractionParameters.MaxLogLenght);
					Return vResult;
				EndIf;
				
			EndIf;
			
		EndDo;
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vRawValue, vResult.Error, pInteractionParameters.MaxLogLenght);
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

Function GetPrices(pInteractionParameters, pGetRaw = False, pAccountID, pRoomRate, pPeriodFrom, pPeriodTo) Export
	
	vResult 		= New Structure("Success, ResultMap, Error, Raw", False, Undefined, "");
	vMessageName 	= "prices";
	vResponse		= Undefined;
	vParametersMap  = New Map;
	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Interaction parameters item should be created and setup in the Integrations/External system interactions catalog!";
			Return vResult;
		EndIf;
		
		// Check token
		If IsBlankString(pInteractionParameters.SessionID) Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error; 
				Return vResult;
			EndIf;
		EndIf;
		
		vRoomRateID 	= Undefined;
		vRoomRateData 	= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "roomrates", "ID", pRoomRate);
		If vRoomRateData.Columns.Find("ID") <> Undefined  AND vRoomRateData.Count() > 0 Then
			vRoomRateID = vRoomRateData[0].ID;	
		EndIf;
		
		If NOT ValueIsFilled(vRoomRateID) Then
			vResult.Success = False;
			vResult.Error 	= "Failed to find room rate external ID";
			Return vResult;		
		EndIf;
		
		vParametersMap.Insert("token", 		pInteractionParameters.SessionID);
		vParametersMap.Insert("account_id", pAccountID);
		vParametersMap.Insert("plan_id", 	vRoomRateID);
		vParametersMap.Insert("dfrom", 		DateToTimestamp(pPeriodFrom));
		vParametersMap.Insert("dto", 		DateToTimestamp(pPeriodTo));

		vURL			= pInteractionParameters.HttpAddress + vMessageName;
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "GET", vMessageName, , , , vParametersMap);
		vResponseStatus = CheckResponseStatus(vResponse);
		
		//Check if token needs to be updated and update it if needed
		If vResponse.StatusCode = 401 Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error;
				Return vResult;
			EndIf;
			
			vParametersMap.Insert("token", pInteractionParameters.SessionID);
			vRequestBody			= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
			vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "GET", vMessageName, , , , vParametersMap);
			vResponseStatus 		= CheckResponseStatus(vResponse);
		EndIf;
		
		vResult.Success = vResponseStatus.Success;
		If vResponseStatus.Success = False Then
			vResult.Error = vResponseStatus.StatusDescription;
			Return vResult;
		Else
			vResponseMap 		= Catalogs.DataConvertationRules.JSONtoMap(vResponse.Body);
			vResult.ResultMap 	= vResponseMap;
		EndIf;
			
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vRawValue, vResult.Error, pInteractionParameters.MaxLogLenght);
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

#Region Restriction_plans

Function CreateAndUpdateRestrictionPlans(pInteractionParameters, pGetRaw = False, pRoomRate, pRoomRateID,  pAccountID, pAmountOfDaysToUpdate = 100, pFullUpdate = False, pRestrictionPlanID = Undefined) Export
	
	vResult 		= New Structure("Success, Error, Raw, RestrictionPlanID", True, "", "", "");
	vMessageName 	= "restriction_plans";
	vResponse		= Undefined;
	vParametersMap  = New Map;
	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Interaction parameters item should be created and setup in the Integrations/External system interactions catalog!";
			Return vResult;
		EndIf;
		
		// Check token
		If IsBlankString(pInteractionParameters.SessionID) Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error; 
				Return vResult;
			EndIf;
		EndIf;
		
		If NOT ValueIsFilled(pRestrictionPlanID) Then
			vRestrictionPlanID	= Undefined;
			vRestrictionsData		=  InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "restrictionplans", "ID", pRoomRate, , , pRoomRateID);
			If vRestrictionsData.Columns.Find("ID") <> Undefined AND vRestrictionsData.Count() > 0 Then
				vRestrictionPlanID = Format(vRestrictionsData[0].ID,"NG=");	
			EndIf;
		Else			
			vRestrictionPlanID = Format(pRestrictionPlanID,"NG=");	
			InformationRegisters.ExternalSystemIntegrationData.WriteData(pInteractionParameters, "restrictionplans", "ID", pRoomRate, , vRestrictionPlanID, pRoomRateID);
		EndIf;
		
		vMinHoursBeforeArrival	= 0;
		vMaxHoursBeforeArrival	= 0;
		
		vRoomRateData		=  InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "roomrates", , pRoomRate,,, pRoomRateID);
		If vRoomRateData.Columns.Find("MinHoursBeforeArrival") <> Undefined  AND vRoomRateData.Count() > 0 Then
			vMinHoursBeforeArrival = vRoomRateData[0].MinHoursBeforeArrival;	
		EndIf;

		If vRoomRateData.Columns.Find("MaxHoursBeforeArrival") <> Undefined  AND vRoomRateData.Count() > 0 Then
			vMaxHoursBeforeArrival = vRoomRateData[0].MaxHoursBeforeArrival;	
		EndIf;

		//Mandatory
		vParametersMap  = New Map;
		vParametersMap.Insert("token", 				pInteractionParameters.SessionID);
		vParametersMap.Insert("account_id", 		pAccountID);
		
		vFullUpdate = pFullUpdate;
		If NOT ValueIsFilled(vRestrictionPlanID) Then 
			vMethod 	= "POST";
			vFullUpdate = True;
		Else
			vRestrictionPlanID = StrReplace(String(vRestrictionPlanID)," ","");
			vMethod = "PUT";
			vParametersMap.Insert("restriction_plan_id", vRestrictionPlanID);
		EndIf;
				
		//Additional
		vParametersMap.Insert("name", pRoomRate.Description);
		vParametersMap.Insert("min_hours_before_arrival", vMinHoursBeforeArrival); //Минимальное количество часов до заезда. 
		vParametersMap.Insert("max_hours_before_arrival", vMaxHoursBeforeArrival); //Максимальное количество часов до заезда.
		
		vPeriodFrom = BegOfDay(CurrentDate());
		vPeriodTo	= vPeriodFrom + 24*60*60*pAmountOfDaysToUpdate;

		vNothingToUpdate 	= True;
		vRestrictionsTable 	= Undefined;
		vRestrictionsMap 	= GetRestrictionsMap(pInteractionParameters, pRoomRate, vPeriodFrom, vPeriodTo, vFullUpdate, vNothingToUpdate, vRestrictionsTable);
		vParametersMap.Insert("restrictions", vRestrictionsMap);
		
		If vRestrictionsMap = Undefined Then
			vResult.Success = False;
			vResult.Error 	= "Failed to get restrictions table!";
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, , , vResult.Error, pInteractionParameters.MaxLogLenght);
			Return vResult;	
		ElsIf vNothingToUpdate Then
			Return vResult;
		EndIf;
		
		vURL			= pInteractionParameters.HttpAddress + vMessageName;
		vRequestBody	= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, vMethod, vMessageName, vRequestBody, "application/json");
		vResponseStatus = CheckResponseStatus(vResponse);
		
		//Check if token needs to be updated and update it if needed
		If vResponse.StatusCode = 401 Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error;
				Return vResult;
			EndIf;
			
			vParametersMap.Insert("token", pInteractionParameters.SessionID);
			vRequestBody			= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
			vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, vMethod, vMessageName, vRequestBody, "application/json");
			vResponseStatus 		= CheckResponseStatus(vResponse);
		EndIf;
		
		vRestrictionPlanID		= Undefined;
		vResult.Success = vResponseStatus.Success;
		If vResponseStatus.Success = False Then
			vResult.Error = vResponseStatus.StatusDescription;
			Return vResult;
		Else
			vResponseMap = Catalogs.DataConvertationRules.JSONtoMap(vResponse.Body);
			For each vKeyAndValue in vResponseMap Do
				If vKeyAndValue.Key = "restriction_plan_id" Then
					vRestrictionPlanID = Format(vKeyAndValue.Value, "NG=");	
				EndIf;
			EndDo;
		EndIf;
		
		If ValueIsFilled(vRestrictionPlanID) Then
			vResult.RestrictionPlanID = vRestrictionPlanID;
			InformationRegisters.ExternalSystemIntegrationData.WriteData(pInteractionParameters, "restrictionplans", "ID", pRoomRate, , vRestrictionPlanID, pRoomRateID);
		Else
			vResult.Success = False;
			vResult.Error 	= "Didnt recieve restriction_plan_id from API";
		EndIf;
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vRawValue, vResult.Error, pInteractionParameters.MaxLogLenght);
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

Function GetRestrictionPlans(pInteractionParameters, pGetRaw = False, pAccountID, pRestrictionPlanID = Undefined) Export
	
	vResult 		= New Structure("Success, ResultMap, Error, Raw", False, Undefined, "");
	vMessageName 	= "restriction_plans";
	vResponse		= Undefined;
	vParametersMap  = New Map;
	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Interaction parameters item should be created and setup in the Integrations/External system interactions catalog!";
			Return vResult;
		EndIf;
		
		// Check token
		If IsBlankString(pInteractionParameters.SessionID) Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error; 
				Return vResult;
			EndIf;
		EndIf;
		
		vParametersMap.Insert("token", 		pInteractionParameters.SessionID);
		vParametersMap.Insert("account_id", pAccountID);

		vURL			= pInteractionParameters.HttpAddress + vMessageName;
		If pRestrictionPlanID <> Undefined Then
			vURL = vURL + "/" + Format(pRestrictionPlanID, "NG=");
		EndIf;
		
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "GET", vMessageName, , , , vParametersMap);
		vResponseStatus = CheckResponseStatus(vResponse);
		
		//Check if token needs to be updated and update it if needed
		If vResponse.StatusCode = 401 Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error;
				Return vResult;
			EndIf;
			
			vParametersMap.Insert("token", pInteractionParameters.SessionID);
			vRequestBody			= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
			vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "GET", vMessageName, , , , vParametersMap);
			vResponseStatus 		= CheckResponseStatus(vResponse);
		EndIf;
		
		vResult.Success = vResponseStatus.Success;
		If vResponseStatus.Success = False Then
			vResult.Error = vResponseStatus.StatusDescription;
			Return vResult;
		Else
			vResponseMap 		= Catalogs.DataConvertationRules.JSONtoMap(vResponse.Body);
			vResult.ResultMap 	= vResponseMap;
		EndIf;
			
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vRawValue, vResult.Error, pInteractionParameters.MaxLogLenght);
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

Function DeleteRestrictionPlan(pInteractionParameters, pGetRaw = False, pAccountID, pID) Export
	
	vResult 		= New Structure("Success, ResultMap, Error, Raw", False, Undefined, "");
	vMessageName 	= "restriction_plans";
	vResponse		= Undefined;
	vParametersMap  = New Map;
	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Interaction parameters item should be created and setup in the Integrations/External system interactions catalog!";
			Return vResult;
		EndIf;
		
		// Check token
		If IsBlankString(pInteractionParameters.SessionID) Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error; 
				Return vResult;
			EndIf;
		EndIf;
		
		vParametersMap.Insert("token", 		pInteractionParameters.SessionID);
		vParametersMap.Insert("account_id", pAccountID);
		vRequestBody	= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);

		vURL			= pInteractionParameters.HttpAddress + vMessageName + "/" + pID;
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "DELETE", vMessageName, vRequestBody, "application/json");
		vResponseStatus = CheckResponseStatus(vResponse);
		
		//Check if token needs to be updated and update it if needed
		If vResponse.StatusCode = 401 Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error;
				vLogEventType = Enums.ExternalSystemEventTypes.Error;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, , , vResult.Error, pInteractionParameters.MaxLogLenght);
				Return vResult;
			EndIf;
			
			vParametersMap.Insert("token", pInteractionParameters.SessionID);
			vRequestBody			= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
			vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "DELETE", vMessageName, vRequestBody, "application/json");
			vResponseStatus 		= CheckResponseStatus(vResponse);
		EndIf;
		
		vResult.Success = vResponseStatus.Success;
		If vResponseStatus.Success = False Then
			vResult.Error = vResponseStatus.StatusDescription;
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vRequestBody, vResponse.Body, vResult.Error, pInteractionParameters.MaxLogLenght);
			Return vResult;
		Else
			vResponseMap 		= Catalogs.DataConvertationRules.JSONtoMap(vResponse.Body);
			vResult.ResultMap 	= vResponseMap;
		EndIf;
			
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vRawValue, vResult.Error, pInteractionParameters.MaxLogLenght);
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

Function GetRestrictions(pInteractionParameters, pGetRaw = False, pAccountID, pPeriodFrom, pPeriodTo) Export
	
	vResult 		= New Structure("Success, ResultMap, Error, Raw", False, Undefined, "");
	vMessageName 	= "restrictions";
	vResponse		= Undefined;
	vParametersMap  = New Map;
	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Interaction parameters item should be created and setup in the Integrations/External system interactions catalog!";
			Return vResult;
		EndIf;
		
		// Check token
		If IsBlankString(pInteractionParameters.SessionID) Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error; 
				Return vResult;
			EndIf;
		EndIf;
				
		vParametersMap.Insert("token", 		pInteractionParameters.SessionID);
		vParametersMap.Insert("account_id", pAccountID);
		vParametersMap.Insert("dfrom", 		Format(pPeriodFrom, "DF=yyyy-MM-dd"));
		vParametersMap.Insert("dto", 		Format(pPeriodTo, "DF=yyyy-MM-dd"));

		vURL			= pInteractionParameters.HttpAddress + vMessageName;
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "GET", vMessageName, , , , vParametersMap);
		vResponseStatus = CheckResponseStatus(vResponse);
		
		//Check if token needs to be updated and update it if needed
		If vResponse.StatusCode = 401 Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error;
				Return vResult;
			EndIf;
			
			vParametersMap.Insert("token", pInteractionParameters.SessionID);
			vRequestBody			= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
			vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "GET", vMessageName, , , , vParametersMap);
			vResponseStatus 		= CheckResponseStatus(vResponse);
		EndIf;
		
		vResult.Success = vResponseStatus.Success;
		If vResponseStatus.Success = False Then
			vResult.Error = vResponseStatus.StatusDescription;
			Return vResult;
		Else
			vResponseMap 		= Catalogs.DataConvertationRules.JSONtoMap(vResponse.Body);
			vResult.ResultMap 	= vResponseMap;
		EndIf;
			
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vRawValue, vResult.Error, pInteractionParameters.MaxLogLenght);
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

#Region Availability

Function UpdateAvailability(pInteractionParameters, pGetRaw = False,  pAccountID, pAmountOfDaysToUpdate = 100, pFullUpdate = False) Export
	
	vResult 		= New Structure("Success, Error, Raw", True, "");
	vMessageName 	= "availability";
	vResponse		= Undefined;
	vParametersMap  = New Map;
	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Interaction parameters item should be created and setup in the Integrations/External system interactions catalog!";
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, , , vResult.Error, pInteractionParameters.MaxLogLenght);
			Return vResult;
		EndIf;
		
		// Check token
		If IsBlankString(pInteractionParameters.SessionID) Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error; 
				Return vResult;
			EndIf;
		EndIf;
				
		// Mandatory
		vParametersMap  = New Map;
		vParametersMap.Insert("token", 				pInteractionParameters.SessionID);
		vParametersMap.Insert("account_id", 		pAccountID);
		
		vPeriodFrom = BegOfDay(CurrentDate());
		vPeriodTo	= vPeriodFrom + 24*60*60*pAmountOfDaysToUpdate;
		
		vDailyAvailability 	= Undefined;
		vPricesMap			= GetAvailabilityMap(pInteractionParameters, vPeriodFrom, vPeriodTo, pFullUpdate, vDailyAvailability); 
		vParametersMap.Insert("availability", vPricesMap);
		
		If vDailyAvailability = Undefined Then
			vResult.Success = False;
			vResult.Error 	= "Failed to get availability table!";
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, , , vResult.Error, pInteractionParameters.MaxLogLenght);
			Return vResult;	
		ElsIf vDailyAvailability.Count() = 0 Then
			Return vResult;
		EndIf;
		
		vURL			= pInteractionParameters.HttpAddress + vMessageName;
		vRequestBody	= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "POST", vMessageName, vRequestBody, "application/json");
		vResponseStatus = CheckResponseStatus(vResponse);
		
		// Check if token needs to be updated and update it if needed
		If vResponse.StatusCode = 401 Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error;
				vLogEventType = Enums.ExternalSystemEventTypes.Error;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, , , vResult.Error, pInteractionParameters.MaxLogLenght);
				Return vResult;
			EndIf;
			
			vParametersMap.Insert("token", pInteractionParameters.SessionID);
			vRequestBody			= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
			vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "POST", vMessageName, vRequestBody, "application/json");
			vResponseStatus 		= CheckResponseStatus(vResponse);
		EndIf;
		
		vRoomTypeID		= Undefined;
		vResult.Success = vResponseStatus.Success;
		If vResponseStatus.Success = False Then
			vResult.Error 	= vResponseStatus.StatusDescription;
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vResponse.Body, vResult.Error, pInteractionParameters.MaxLogLenght);
			Return vResult;
		EndIf;
		
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vRawValue, vResult.Error, pInteractionParameters.MaxLogLenght);
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

Function GetAvailability(pInteractionParameters, pGetRaw = False, pAccountID, pPeriodFrom, pPeriodTo) Export
	
	vResult 		= New Structure("Success, ResultMap, Error, Raw", False, Undefined, "");
	vMessageName 	= "availability";
	vResponse		= Undefined;
	vParametersMap  = New Map;
	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Interaction parameters item should be created and setup in the Integrations/External system interactions catalog!";
			Return vResult;
		EndIf;
		
		// Check token
		If IsBlankString(pInteractionParameters.SessionID) Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error; 
				Return vResult;
			EndIf;
		EndIf;
						
		vParametersMap.Insert("token", 		pInteractionParameters.SessionID);
		vParametersMap.Insert("account_id", pAccountID);
		vParametersMap.Insert("dfrom", 		DateToTimestamp(pPeriodFrom));
		vParametersMap.Insert("dto", 		DateToTimestamp(pPeriodTo));

		vURL			= pInteractionParameters.HttpAddress + vMessageName;
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "GET", vMessageName, , , , vParametersMap);
		vResponseStatus = CheckResponseStatus(vResponse);
		
		//Check if token needs to be updated and update it if needed
		If vResponse.StatusCode = 401 Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error;
				Return vResult;
			EndIf;
			
			vParametersMap.Insert("token", pInteractionParameters.SessionID);
			vRequestBody			= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
			vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "GET", vMessageName, , , , vParametersMap);
			vResponseStatus 		= CheckResponseStatus(vResponse);
		EndIf;
		
		vResult.Success = vResponseStatus.Success;
		If vResponseStatus.Success = False Then
			vResult.Error = vResponseStatus.StatusDescription;
			Return vResult;
		Else
			vResponseMap 		= Catalogs.DataConvertationRules.JSONtoMap(vResponse.Body);
			vResult.ResultMap 	= vResponseMap;
		EndIf;
			
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vRawValue, vResult.Error, pInteractionParameters.MaxLogLenght);
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

#Region Bookings

Function GetBookings(pInteractionParameters, pAccountID, pLoadAdultGuestsAmountFromExtraDataArray = False, pLoadChildGuestsAmountFromExtraDataArray = False, pGetPrices = True) Export
	
	vResult 		= New Structure("Success, Error, Raw", False, Undefined, "");
	vMessageName 	= "bookings";
	vResponse		= Undefined;
	vParametersMap  = New Map;
	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Interaction parameters item should be created and setup in the Integrations/External system interactions catalog!";
			Return vResult;
		EndIf;
		
		// Check token
		If IsBlankString(pInteractionParameters.SessionID) Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error; 
				Return vResult;
			EndIf;
		EndIf;
				
		vParametersMap.Insert("token", 			pInteractionParameters.SessionID);
		vParametersMap.Insert("account_id", 	pAccountID);
		vParametersMap.Insert("not_fetched", 	1);

		vURL			= pInteractionParameters.HttpAddress + vMessageName;
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "GET", vMessageName, , , , vParametersMap);
		vResponseStatus = CheckResponseStatus(vResponse);
		
		// Check if token needs to be updated and update it if needed
		If vResponse.StatusCode = 401 Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error;
				Return vResult;
			EndIf;
			
			vParametersMap.Insert("token", pInteractionParameters.SessionID);
			vRequestBody			= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
			vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "GET", vMessageName, , , , vParametersMap);
			vResponseStatus 		= CheckResponseStatus(vResponse);
		EndIf;
		
		vResult.Success = vResponseStatus.Success;
		If vResponseStatus.Success = False Then
			vResult.Error = vResponseStatus.StatusDescription;
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vResponse.Body, vResult.Error, pInteractionParameters.MaxLogLenght);
			Return vResult;			
		Else
			vResponseMap 	= Catalogs.DataConvertationRules.JSONtoMap(vResponse.Body);
			vLoadResult		= LoadReservations(pInteractionParameters, vResponseMap, pLoadAdultGuestsAmountFromExtraDataArray, pLoadChildGuestsAmountFromExtraDataArray, pGetPrices);
			vResult.Success = vLoadResult.Success;
			vResult.Error 	= vLoadResult.Error;
			If vLoadResult.FetchedReservations.Count() > 0 Then
				MarkBookings(pInteractionParameters, pAccountID, vLoadResult.FetchedReservations);
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
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vRawValue, vResult.Error, pInteractionParameters.MaxLogLenght);
	EndTry;
	
	Return vResult;
	
EndFunction

Function GetBookingsFromFile(pInteractionParameters, pFilePath, pAccountID, pLoadAdultGuestsAmountFromExtraDataArray = False, pLoadChildGuestsAmountFromExtraDataArray = False, pGetPrices = True) Export
	vResult 		= New Structure("Success, Error, Raw", False, Undefined, "");
	vMessageName 	= "bookings";
	vFile = New File(pFilePath);
	If tcCommonFunctionOnClientServer.cmExists(vFile) And vFile.IsFile Then
		vTextReader = New TextReader(vFile.Path, TextEncoding.UTF8);
		vJSON = vTextReader.Read();
		If ValueIsFilled(TrimAll(vJSON)) Then
			vResponseMap 	= Catalogs.DataConvertationRules.JSONtoMap(TrimAll(vJSON));
			vLoadResult		= LoadReservations(pInteractionParameters, vResponseMap, pLoadAdultGuestsAmountFromExtraDataArray, pLoadChildGuestsAmountFromExtraDataArray, pGetPrices);
			vResult.Success = vLoadResult.Success;
			vResult.Error 	= vLoadResult.Error;
			If vLoadResult.FetchedReservations.Count() > 0 Then
				MarkBookings(pInteractionParameters, pAccountID, vLoadResult.FetchedReservations);
			EndIf;
		Else
			vResult.Success = False;
			vResult.Error = NStr("en = 'File is empty'; de = 'Datei ist leer'; ru = 'Файл пустой'"); 
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType,,, vResult.Error, pInteractionParameters.MaxLogLenght);
		EndIf;
	Else
		vResult.Success = False;
		vResult.Error = NStr("en = 'The file does not exist'; de = 'Die Datei existiert nicht'; ru = 'Файл не существует'"); 
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType,,, vResult.Error, pInteractionParameters.MaxLogLenght);
	EndIf;
	
	Return vResult;
EndFunction // GetBookingsFromFile

Function MarkBookings(pInteractionParameters, pAccountID, pBookingsArray) Export
	
	vResult 		= New Structure("Success, Error, Raw", False, Undefined, "");
	vMessageName 	= "bookings_fetched";
	vResponse		= Undefined;
	vParametersMap  = New Map;
	
	If pBookingsArray = Undefined OR pBookingsArray.Count() = 0 Then
		Return vResult;
	EndIf;
	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Interaction parameters item should be created and setup in the Integrations/External system interactions catalog!";
			Return vResult;
		EndIf;
		
		// Check token
		If IsBlankString(pInteractionParameters.SessionID) Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error; 
				Return vResult;
			EndIf;
		EndIf;
				
		vParametersMap.Insert("token", 				pInteractionParameters.SessionID);
		vParametersMap.Insert("account_id", 		pAccountID);
		vParametersMap.Insert("booking_numbers",	pBookingsArray);
		vRequestBody	= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
		vURL			= pInteractionParameters.HttpAddress + vMessageName;
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "PUT", vMessageName, vRequestBody, "application/json");
		vResponseStatus = CheckResponseStatus(vResponse);
		
		//Check if token needs to be updated and update it if needed
		If vResponse.StatusCode = 401 Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error;
				Return vResult;
			EndIf;
			
			vParametersMap.Insert("token", pInteractionParameters.SessionID);
			vRequestBody			= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
			vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "PUT", vMessageName, vRequestBody, "application/json");
			vResponseStatus 		= CheckResponseStatus(vResponse);
		EndIf;
		
		vResult.Success = vResponseStatus.Success;
		If vResponseStatus.Success = False Then
			vResult.Error 	= vResponseStatus.StatusDescription;
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vResponse.Body, vResult.Error, pInteractionParameters.MaxLogLenght);
			Return vResult;			
		EndIf;
		
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vRawValue, vResult.Error, pInteractionParameters.MaxLogLenght);
	EndTry;
	
	Return vResult;
	
EndFunction

#EndRegion

#Region OTAs

Function GetOTAsList(pInteractionParameters, pGetRaw = False) Export
	
	vResult 		= New Structure("Success, ResultMap, Error, Raw", True, Undefined, "");
	vMessageName 	= "ota";
	vResponse		= Undefined;
	vParametersMap  = New Map;
	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Interaction parameters item should be created and setup in the Integrations/External system interactions catalog!";
			Return vResult;
		EndIf;
		
		// Check token
		If IsBlankString(pInteractionParameters.SessionID) Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error; 
				Return vResult;
			EndIf;
		EndIf;
		
		vParametersMap.Insert("token", 		pInteractionParameters.SessionID);

		vURL			= pInteractionParameters.HttpAddress + vMessageName;
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "GET", vMessageName, , , , vParametersMap);
		vResponseStatus = CheckResponseStatus(vResponse);
		
		//Check if token needs to be updated and update it if needed
		If vResponse.StatusCode = 401 Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error;
				Return vResult;
			EndIf;
			
			vParametersMap.Insert("token", pInteractionParameters.SessionID);
			vRequestBody			= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
			vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "GET", vMessageName, , , , vParametersMap);
			vResponseStatus 		= CheckResponseStatus(vResponse);
		EndIf;
		
		vResult.Success = vResponseStatus.Success;
		If vResponseStatus.Success = False Then
			vResult.Error = vResponseStatus.StatusDescription;
			Return vResult;
		Else
			vResponseMap 		= Catalogs.DataConvertationRules.JSONtoMap(vResponse.Body);
			vResult.ResultMap 	= vResponseMap;
		EndIf;
			
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vRawValue, vResult.Error, pInteractionParameters.MaxLogLenght);
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

Function CreateNewChannel(pInteractionParameters, pGetRaw = False, pAccountID, pOTAID, pOTACredentials, pExtra = Undefined) Export
	
	vResult 		= New Structure("Success, Error, Raw, Result", True, "");
	vMessageName 	= "ota_settings";
	vResponse		= Undefined;
	vParametersMap  = New Map;
	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Interaction parameters item should be created and setup in the Integrations/External system interactions catalog!";
			Return vResult;
		EndIf;
		
		// Check token
		If IsBlankString(pInteractionParameters.SessionID) Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error; 
				Return vResult;
			EndIf;
		EndIf;
		
		//Mandatory
		vParametersMap  = New Map;
		vParametersMap.Insert("token", 				pInteractionParameters.SessionID);
		vParametersMap.Insert("account_id", 		pAccountID);
		vParametersMap.Insert("ota_id", 			pOTAID);
		vParametersMap.Insert("credentials", 		pOTACredentials);
				
		//Additional
		If ValueIsFilled(pExtra) Then
			vParametersMap.Insert("extra", 			pExtra);
		EndIf;

		vURL			= pInteractionParameters.HttpAddress + vMessageName;
		vRequestBody	= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "POST", vMessageName, vRequestBody, "application/json");
		vResponseStatus = CheckResponseStatus(vResponse);
		
		//Check if token needs to be updated and update it if needed
		If vResponse.StatusCode = 401 Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error;
				Return vResult;
			EndIf;
			
			vParametersMap.Insert("token", pInteractionParameters.SessionID);
			vRequestBody			= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
			vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "POST", vMessageName, vRequestBody, "application/json");
			vResponseStatus 		= CheckResponseStatus(vResponse);
		EndIf;
		
		vRoomTypeID		= Undefined;
		vResult.Success = vResponseStatus.Success;
		If vResponseStatus.Success = False Then
			vResult.Error = vResponseStatus.StatusDescription;
			Return vResult;
		Else
			vResponseMap 		= Catalogs.DataConvertationRules.JSONtoMap(vResponse.Body);
			vResult.Result 		= vResponseMap.Get("ota_settings_id");
		EndIf;
		
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vRawValue, vResult.Error, pInteractionParameters.MaxLogLenght);
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

Function DeleteChannel(pInteractionParameters, pGetRaw = False, pAccountID, pOTAID, pOTASettingsID, pExtra = Undefined) Export
	
	vResult 		= New Structure("Success, Error, Raw", True, "");
	vMessageName 	= "ota_settings";
	vResponse		= Undefined;
	vParametersMap  = New Map;
	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Interaction parameters item should be created and setup in the Integrations/External system interactions catalog!";
			Return vResult;
		EndIf;
		
		// Check token
		If IsBlankString(pInteractionParameters.SessionID) Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error; 
				Return vResult;
			EndIf;
		EndIf;
		
		//Mandatory
		vParametersMap  = New Map;
		vParametersMap.Insert("token", 				pInteractionParameters.SessionID);
		vParametersMap.Insert("account_id", 		pAccountID);
		vParametersMap.Insert("ota_id", 			pOTAID);
		vParametersMap.Insert("ota_settings_id", 	pOTASettingsID);
				
		//Additional
		If ValueIsFilled(pExtra) Then
			vParametersMap.Insert("extra", 			pExtra);
		EndIf;

		vURL			= pInteractionParameters.HttpAddress + vMessageName;
		vRequestBody	= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "DELETE", vMessageName, vRequestBody, "application/json");
		vResponseStatus = CheckResponseStatus(vResponse);
		
		//Check if token needs to be updated and update it if needed
		If vResponse.StatusCode = 401 Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error;
				Return vResult;
			EndIf;
			
			vParametersMap.Insert("token", pInteractionParameters.SessionID);
			vRequestBody			= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
			vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "DELETE", vMessageName, vRequestBody, "application/json");
			vResponseStatus 		= CheckResponseStatus(vResponse);
		EndIf;
		
		vRoomTypeID		= Undefined;
		vResult.Success = vResponseStatus.Success;
		If vResponseStatus.Success = False Then
			vResult.Error = vResponseStatus.StatusDescription;
			Return vResult;
		Else
			vResponseMap 		= Catalogs.DataConvertationRules.JSONtoMap(vResponse.Body);
		EndIf;
		
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vRawValue, vResult.Error, pInteractionParameters.MaxLogLenght);
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

Function CheckNewChannel(pInteractionParameters, pGetRaw = False, pAccountID, pOTASettingsID) Export
	
	vResult 		= New Structure("Success, ResultMap, Error, Raw", True, Undefined, "");
	vMessageName 	= "ota_settings";
	vResponse		= Undefined;
	vParametersMap  = New Map;
	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Interaction parameters item should be created and setup in the Integrations/External system interactions catalog!";
			Return vResult;
		EndIf;
		
		// Check token
		If IsBlankString(pInteractionParameters.SessionID) Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error; 
				Return vResult;
			EndIf;
		EndIf;
		
		//Mandatory
		vParametersMap  = New Map;
		vParametersMap.Insert("token", 				pInteractionParameters.SessionID);
		vParametersMap.Insert("account_id", 		pAccountID);
		vParametersMap.Insert("ota_settings_id", 	pOTASettingsID);

		vURL			= pInteractionParameters.HttpAddress + vMessageName;
		vRequestBody	= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "PUT", vMessageName, vRequestBody, "application/json");
		vResponseStatus = CheckResponseStatus(vResponse);
		
		//Check if token needs to be updated and update it if needed
		If vResponse.StatusCode = 401 Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error;
				Return vResult;
			EndIf;
			
			vParametersMap.Insert("token", pInteractionParameters.SessionID);
			vRequestBody			= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
			vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "PUT", vMessageName, vRequestBody, "application/json");
			vResponseStatus 		= CheckResponseStatus(vResponse);
		EndIf;
		
		vRoomTypeID		= Undefined;
		vResult.Success = vResponseStatus.Success;
		If vResponseStatus.Success = False Then
			vResult.Error = vResponseStatus.StatusDescription;
			Return vResult;
		Else
			vResponseMap 		= Catalogs.DataConvertationRules.JSONtoMap(vResponse.Body);
			vResult.ResultMap 	= vResponseMap;
		EndIf;
		
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vRawValue, vResult.Error, pInteractionParameters.MaxLogLenght);
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

Function GetMappedOTAsList(pInteractionParameters, pGetRaw = False, pAccountID) Export
	
	vResult 		= New Structure("Success, ResultMap, Error, Raw", True, Undefined, "");
	vMessageName 	= "ota_settings";
	vResponse		= Undefined;
	vParametersMap  = New Map;
	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Interaction parameters item should be created and setup in the Integrations/External system interactions catalog!";
			Return vResult;
		EndIf;
		
		// Check token
		If IsBlankString(pInteractionParameters.SessionID) Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error; 
				Return vResult;
			EndIf;
		EndIf;
		
		//Mandatory
		vParametersMap  = New Map;
		vParametersMap.Insert("token", 				pInteractionParameters.SessionID);
		vParametersMap.Insert("account_id", 		pAccountID);

		vURL			= pInteractionParameters.HttpAddress + vMessageName;
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "GET", vMessageName, , , , vParametersMap);
		vResponseStatus = CheckResponseStatus(vResponse);
		
		//Check if token needs to be updated and update it if needed
		If vResponse.StatusCode = 401 Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error;
				Return vResult;
			EndIf;
			
			vParametersMap.Insert("token", pInteractionParameters.SessionID);
			vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "GET", vMessageName, , , , vParametersMap);
			vResponseStatus 		= CheckResponseStatus(vResponse);
		EndIf;
		
		vRoomTypeID		= Undefined;
		vResult.Success = vResponseStatus.Success;
		If vResponseStatus.Success = False Then
			vResult.Error = vResponseStatus.StatusDescription;
			Return vResult;
		Else
			vResponseMap 		= Catalogs.DataConvertationRules.JSONtoMap(vResponse.Body);
			vResult.ResultMap 	= vResponseMap;
		EndIf;
		
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vRawValue, vResult.Error, pInteractionParameters.MaxLogLenght);
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

Function GetOTAData(pInteractionParameters, pAccountID, pOTASettingsID, pGetRaw = False) Export
	
	vResult 		= New Structure("Success, ResultMap, Error, Raw", False, Undefined, "");
	vMessageName 	= "ota_data";
	vResponse		= Undefined;
	vParametersMap  = New Map;
	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Interaction parameters item should be created and setup in the Integrations/External system interactions catalog!";
			Return vResult;
		EndIf;
		
		// Check token
		If IsBlankString(pInteractionParameters.SessionID) Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error; 
				Return vResult;
			EndIf;
		EndIf;
		
		vParametersMap.Insert("token", 				pInteractionParameters.SessionID);
		vParametersMap.Insert("account_id", 		pAccountID);
		vParametersMap.Insert("ota_settings_id", 	pOTASettingsID);
	
		vURL			= pInteractionParameters.HttpAddress + vMessageName;
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "GET", vMessageName, , , , vParametersMap);
		vResponseStatus = CheckResponseStatus(vResponse);
		
		//Check if token needs to be updated and update it if needed
		If vResponse.StatusCode = 401 Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error;
				Return vResult;
			EndIf;
			
			vParametersMap.Insert("token", pInteractionParameters.SessionID);
			vRequestBody			= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
			vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "GET", vMessageName, , , , vParametersMap);
			vResponseStatus 		= CheckResponseStatus(vResponse);
		EndIf;
		
		vResult.Success = vResponseStatus.Success;
		If vResponseStatus.Success = False Then
			vResult.Error = vResponseStatus.StatusDescription;
			Return vResult;
		Else
			vResponseMap 		= Catalogs.DataConvertationRules.JSONtoMap(vResponse.Body);
			vResult.ResultMap 	= vResponseMap;
		EndIf;
			
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vRawValue, vResult.Error, pInteractionParameters.MaxLogLenght);
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

Function SaveOTADataMappings(pInteractionParameters, pAccountID, pAgent, pGetRaw = False) Export
	
	vResult 		= New Structure("Success, ResultMap, Error, Raw", False, Undefined, "");
	vMessageName 	= "ota_external_data";
	vResponse		= Undefined;
	vParametersMap  = New Map;
	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Interaction parameters item should be created and setup in the Integrations/External system interactions catalog!";
			Return vResult;
		EndIf;
		
		// Check token
		If IsBlankString(pInteractionParameters.SessionID) Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error; 
				Return vResult;
			EndIf;
		EndIf;
		
		vAgentIDTable = InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "agents", "OTAGatewayID", pAgent);

		vOTASettingsID = Undefined;
		If vAgentIDTable <> Undefined AND vAgentIDTable.Count() > 0 Then 	
			vOTASettingsID 	= vAgentIDTable[0].OTAGatewayID;
		EndIf;
		
		If NOT ValueIsFilled(vOTASettingsID) Then
			vResult.Success = False;
			vResult.Error	= "Failed to find agent OTA Gateway ID";
			Return vResult;
		EndIf;
		
		vRoomRatesMappings 		= GetAgentsRoomRatesMap(pInteractionParameters, pAgent);
		vRoomTypesMappings 		= GetAgentsRoomTypesMap(pInteractionParameters, pAgent);
		vOccupanciesMappings 	= GetAgentsOccupanciesMap(pInteractionParameters, pAgent);
		
		vParametersMap.Insert("token", 				pInteractionParameters.SessionID);
		vParametersMap.Insert("account_id", 		pAccountID);
		vParametersMap.Insert("ota_settings_id", 	vOTASettingsID);
	    vParametersMap.Insert("plans",				vRoomRatesMappings);
		vParametersMap.Insert("room_types",			vRoomTypesMappings);
		vParametersMap.Insert("occupancies",		vOccupanciesMappings);

		vRequestBody	= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
		vURL			= pInteractionParameters.HttpAddress + vMessageName;
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "POST", vMessageName, vRequestBody, "application/json");
		vResponseStatus = CheckResponseStatus(vResponse);
		
		//Check if token needs to be updated and update it if needed
		If vResponse.StatusCode = 401 Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error;
				Return vResult;
			EndIf;
			
			vParametersMap.Insert("token", pInteractionParameters.SessionID);
			vRequestBody			= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
			vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "POST", vMessageName, vRequestBody, "application/json");
			vResponseStatus 		= CheckResponseStatus(vResponse);
		EndIf;
		
		vResult.Success = vResponseStatus.Success;
		If vResponseStatus.Success = False Then
			vResult.Error = vResponseStatus.StatusDescription;
			Return vResult;
		Else
			vResponseMap 		= Catalogs.DataConvertationRules.JSONtoMap(vResponse.Body);
			vResult.ResultMap 	= vResponseMap;
		EndIf;
			
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vRawValue, vResult.Error, pInteractionParameters.MaxLogLenght);
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

Function GetMappedOTARoomRates(pInteractionParameters, pAccountID, pAgent, pGetRaw = False) Export
	
	vResult 		= New Structure("Success, ResultMap, Error, Raw", False, Undefined, "");
	vMessageName 	= "ota_external_plans";
	vResponse		= Undefined;
	vParametersMap  = New Map;
	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Interaction parameters item should be created and setup in the Integrations/External system interactions catalog!";
			Return vResult;
		EndIf;
		
		// Check token
		If IsBlankString(pInteractionParameters.SessionID) Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error; 
				Return vResult;
			EndIf;
		EndIf;
		
		vAgentIDTable = InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "agents", "OTAGatewayID", pAgent);

		vOTASettingsID = Undefined;
		If vAgentIDTable <> Undefined AND vAgentIDTable.Count() > 0 Then 	
			vOTASettingsID 	= vAgentIDTable[0].OTAGatewayID;
		EndIf;
		
		If NOT ValueIsFilled(vOTASettingsID) Then
			vResult.Success = False;
			vResult.Error	= "Failed to find agent OTA Gateway ID";
			Return vResult;
		EndIf;
		
		vParametersMap.Insert("token", 				pInteractionParameters.SessionID);
		vParametersMap.Insert("account_id", 		pAccountID);
		vParametersMap.Insert("ota_settings_id", 	vOTASettingsID);
	
		vURL			= pInteractionParameters.HttpAddress + vMessageName;
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "GET", vMessageName, , , , vParametersMap);
		vResponseStatus = CheckResponseStatus(vResponse);
		
		//Check if token needs to be updated and update it if needed
		If vResponse.StatusCode = 401 Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error;
				Return vResult;
			EndIf;
			
			vParametersMap.Insert("token", pInteractionParameters.SessionID);
			vRequestBody			= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
			vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "GET", vMessageName, , , , vParametersMap);
			vResponseStatus 		= CheckResponseStatus(vResponse);
		EndIf;
		
		vResult.Success = vResponseStatus.Success;
		If vResponseStatus.Success = False Then
			vResult.Error = vResponseStatus.StatusDescription;
			Return vResult;
		Else
			vResponseMap 		= Catalogs.DataConvertationRules.JSONtoMap(vResponse.Body);
			vResult.ResultMap 	= vResponseMap;
		EndIf;
			
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vRawValue, vResult.Error, pInteractionParameters.MaxLogLenght);
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

Function GetMappedOTARoomTypes(pInteractionParameters, pAccountID, pAgent, pGetRaw = False) Export
	
	vResult 		= New Structure("Success, ResultMap, Error, Raw", False, Undefined, "");
	vMessageName 	= "ota_external_room_types";
	vResponse		= Undefined;
	vParametersMap  = New Map;
	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Interaction parameters item should be created and setup in the Integrations/External system interactions catalog!";
			Return vResult;
		EndIf;
		
		// Check token
		If IsBlankString(pInteractionParameters.SessionID) Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error; 
				Return vResult;
			EndIf;
		EndIf;
		
		vAgentIDTable = InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "agents", "OTAGatewayID", pAgent);

		vOTASettingsID = Undefined;
		If vAgentIDTable <> Undefined AND vAgentIDTable.Count() > 0 Then 	
			vOTASettingsID 	= vAgentIDTable[0].OTAGatewayID;
		EndIf;
		
		If NOT ValueIsFilled(vOTASettingsID) Then
			vResult.Success = False;
			vResult.Error	= "Failed to find agent OTA Gateway ID";
			Return vResult;
		EndIf;
		
		vParametersMap.Insert("token", 				pInteractionParameters.SessionID);
		vParametersMap.Insert("account_id", 		pAccountID);
		vParametersMap.Insert("ota_settings_id", 	vOTASettingsID);
	
		vURL			= pInteractionParameters.HttpAddress + vMessageName;
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "GET", vMessageName, , , , vParametersMap);
		vResponseStatus = CheckResponseStatus(vResponse);
		
		//Check if token needs to be updated and update it if needed
		If vResponse.StatusCode = 401 Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error;
				Return vResult;
			EndIf;
			
			vParametersMap.Insert("token", pInteractionParameters.SessionID);
			vRequestBody			= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
			vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "GET", vMessageName, , , , vParametersMap);
			vResponseStatus 		= CheckResponseStatus(vResponse);
		EndIf;
		
		vResult.Success = vResponseStatus.Success;
		If vResponseStatus.Success = False Then
			vResult.Error = vResponseStatus.StatusDescription;
			Return vResult;
		Else
			vResponseMap 		= Catalogs.DataConvertationRules.JSONtoMap(vResponse.Body);
			vResult.ResultMap 	= vResponseMap;
		EndIf;
			
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vRawValue, vResult.Error, pInteractionParameters.MaxLogLenght);
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

Function GetMappedOTAOccupancies(pInteractionParameters, pAccountID, pAgent, pGetRaw = False) Export
	
	vResult 		= New Structure("Success, ResultMap, Error, Raw", False, Undefined, "");
	vMessageName 	= "ota_external_occupancies";
	vResponse		= Undefined;
	vParametersMap  = New Map;
	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Interaction parameters item should be created and setup in the Integrations/External system interactions catalog!";
			Return vResult;
		EndIf;
		
		// Check token
		If IsBlankString(pInteractionParameters.SessionID) Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error; 
				Return vResult;
			EndIf;
		EndIf;
		
		vAgentIDTable = InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "agents", "OTAGatewayID", pAgent);

		vOTASettingsID = Undefined;
		If vAgentIDTable <> Undefined AND vAgentIDTable.Count() > 0 Then 	
			vOTASettingsID 	= vAgentIDTable[0].OTAGatewayID;
		EndIf;
		
		If NOT ValueIsFilled(vOTASettingsID) Then
			vResult.Success = False;
			vResult.Error	= "Failed to find agent OTA Gateway ID";
			Return vResult;
		EndIf;
		
		vParametersMap.Insert("token", 				pInteractionParameters.SessionID);
		vParametersMap.Insert("account_id", 		pAccountID);
		vParametersMap.Insert("ota_settings_id", 	vOTASettingsID);
	
		vURL			= pInteractionParameters.HttpAddress + vMessageName;
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "GET", vMessageName, , , , vParametersMap);
		vResponseStatus = CheckResponseStatus(vResponse);
		
		//Check if token needs to be updated and update it if needed
		If vResponse.StatusCode = 401 Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error;
				Return vResult;
			EndIf;
			
			vParametersMap.Insert("token", pInteractionParameters.SessionID);
			vRequestBody			= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
			vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "GET", vMessageName, , , , vParametersMap);
			vResponseStatus 		= CheckResponseStatus(vResponse);
		EndIf;
		
		vResult.Success = vResponseStatus.Success;
		If vResponseStatus.Success = False Then
			vResult.Error = vResponseStatus.StatusDescription;
			Return vResult;
		Else
			vResponseMap 		= Catalogs.DataConvertationRules.JSONtoMap(vResponse.Body);
			vResult.ResultMap 	= vResponseMap;
		EndIf;
			
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vRawValue, vResult.Error, pInteractionParameters.MaxLogLenght);
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

#Region Accounts

Function GetAccount(pInteractionParameters, pGetRaw = False, pAccountID) Export
	
	vResult 		= New Structure("Success, ResultMap, Error, Raw", False, Undefined, "");
	vMessageName 	= "accounts";
	vResponse		= Undefined;
	vParametersMap  = New Map;
	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Interaction parameters item should be created and setup in the Integrations/External system interactions catalog!";
			Return vResult;
		EndIf;
		
		// Check token
		If IsBlankString(pInteractionParameters.SessionID) Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error; 
				Return vResult;
			EndIf;
		EndIf;
		
		vParametersMap.Insert("token", 		pInteractionParameters.SessionID);
		vParametersMap.Insert("account_id", pAccountID);

		vURL			= pInteractionParameters.HttpAddress + vMessageName;		
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "GET", vMessageName, , , , vParametersMap);
		vResponseStatus = CheckResponseStatus(vResponse);
		
		//Check if token needs to be updated and update it if needed
		If vResponse.StatusCode = 401 Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error;
				Return vResult;
			EndIf;
			
			vParametersMap.Insert("token", pInteractionParameters.SessionID);
			vRequestBody			= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
			vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "GET", vMessageName, , , , vParametersMap);
			vResponseStatus 		= CheckResponseStatus(vResponse);
		EndIf;
		
		vResult.Success = vResponseStatus.Success;
		If vResponseStatus.Success = False Then
			vResult.Error = vResponseStatus.StatusDescription;
			Return vResult;
		Else
			vResponseMap 		= Catalogs.DataConvertationRules.JSONtoMap(vResponse.Body);
			vResult.ResultMap 	= vResponseMap;
		EndIf;
			
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vRawValue, vResult.Error, pInteractionParameters.MaxLogLenght);
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

Function UpdateAccount(pInteractionParameters, pGetRaw = False, pAccountID, pUpdateStructure) Export
	
	vResult 		= New Structure("Success, Error, Raw, Result", True, "");
	vMessageName 	= "accounts";
	vResponse		= Undefined;
	vParametersMap  = New Map;
	
	Try
		If NOT ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Interaction parameters item should be created and setup in the Integrations/External system interactions catalog!";
			Return vResult;
		EndIf;
		
		// Check token
		If IsBlankString(pInteractionParameters.SessionID) Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error; 
				Return vResult;
			EndIf;
		EndIf;
		
		//Mandatory
		vParametersMap  = New Map;
		vParametersMap.Insert("token", 				pInteractionParameters.SessionID);
		vParametersMap.Insert("account_id", 		pAccountID);
				
		//Additional
		If ValueIsFilled(pUpdateStructure) Then
			For each vKeyAndValue in pUpdateStructure Do
				vParametersMap.Insert(vKeyAndValue.Key, vKeyAndValue.Value);
			EndDo;
		EndIf;

		vURL			= pInteractionParameters.HttpAddress + vMessageName;
		vRequestBody	= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "PUT", vMessageName, vRequestBody, "application/json");
		vResponseStatus = CheckResponseStatus(vResponse);
		
		//Check if token needs to be updated and update it if needed
		If vResponse.StatusCode = 401 Then
			vTokenUpdateResult = GetNewToken(pInteractionParameters);
			If NOT vTokenUpdateResult.Success Then
				vResult.Success = False;
				vResult.Error = vTokenUpdateResult.Error;
				Return vResult;
			EndIf;
			
			vParametersMap.Insert("token", pInteractionParameters.SessionID);
			vRequestBody			= Catalogs.DataConvertationRules.MapToJSON(vParametersMap);
			vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, , vURL, "PUT", vMessageName, vRequestBody, "application/json");
			vResponseStatus 		= CheckResponseStatus(vResponse);
		EndIf;
		
		vRoomTypeID		= Undefined;
		vResult.Success = vResponseStatus.Success;
		If vResponseStatus.Success = False Then
			vResult.Error = vResponseStatus.StatusDescription;
			Return vResult;
		Else
			vResponseMap 		= Catalogs.DataConvertationRules.JSONtoMap(vResponse.Body);
			vResult.Result 		= vResponseMap.Get("ota_settings_id");
		EndIf;
		
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vMessageName, vLogEventType, vParametersMap, vRawValue, vResult.Error, pInteractionParameters.MaxLogLenght);
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

#EndRegion

Function GetAgentsRoomRatesMap(pInteractionParameters, pAgent)
	
	vResult		= New Array;
	vRoomRates 	= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "agentsRoomRates",, pAgent);

	For each vRow in vRoomRates Do
		If ValueIsFilled(vRow.RoomRateID) Then
			vRoomRateStructure = New Structure;
			vRoomRateStructure.Insert("external_plan_id", 	vRow.RoomRateID);
			vRoomRateStructure.Insert("ota_plan_id", 		vRow.OTARoomRateID);
			vResult.Add(vRoomRateStructure);
		EndIf;
	EndDo;
	
	Return vResult;
	
EndFunction

Function GetAgentsRoomTypesMap(pInteractionParameters, pAgent)
	
	vResult		= New Array;
	vRoomTypes 	= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "agentsRoomTypes",, pAgent);

	For each vRow in vRoomTypes Do
		If ValueIsFilled(vRow.OTARoomTypeID) Then
			vRoomTypeStructure = New Structure;
			vRoomTypeStructure.Insert("external_room_type_id", 	vRow.RoomTypeID);
			vRoomTypeStructure.Insert("ota_room_type_id", 		vRow.OTARoomTypeID);
			vResult.Add(vRoomTypeStructure);
		EndIf;
	EndDo;
	
	Return vResult;
	
EndFunction

Function GetAgentsOccupanciesMap(pInteractionParameters, pAgent)
	
	vResult		= New Array;
	vOccupancies 	= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "agentsOccupancies",, pAgent);

	For each vRow in vOccupancies Do
		If ValueIsFilled(vRow.OTARoomTypeID) Then
			vRoomTypeStructure = New Structure;
			vRoomTypeStructure.Insert("external_occupancy_id", 	vRow.RoomTypeID);
			vRoomTypeStructure.Insert("ota_occupancy_id", 		vRow.OTARoomOccupancyID);
			vRoomTypeStructure.Insert("ota_room_type_id", 		vRow.OTARoomTypeID);
			vResult.Add(vRoomTypeStructure);
		EndIf;
	EndDo;
	
	Return vResult;
	
EndFunction

Function DateToTimestamp(pDate)
	
	Return Format(Number(pDate - Date('19700101')), "NG=");
	
EndFunction

Function CheckResponseStatus(pResponse)
	
	vResult = New Structure("Success, StatusDescription"); //#TODO Переводы статусов
	
	If pResponse.StatusCode = 200 Then
		vResult.Success 			= True;
		vResult.StatusDescription 	= "Удачное выполнение команды";
	ElsIf pResponse.StatusCode = 401 Then
		vResult.Success 			= False;
		vResult.StatusDescription 	= "Ошибка авторизации, передан невалидный токен авторизации";
	ElsIf pResponse.StatusCode = 404 Then
		vResult.Success 			= False;
		vResult.StatusDescription 	= "Метод API, либо какая-то сущность, необходимая для обработки запроса не найдена";
	ElsIf pResponse.StatusCode = 406 Then
		vResult.Success 			= False;
		vResult.StatusDescription 	= "Ошибка валидации. В теле ответа возвращаются параметры запроса, вызвавшего ошибку";
	ElsIf pResponse.StatusCode = 500 Then
		vResult.Success 			= False;
		vResult.StatusDescription 	= "Запрос не может быть выполнен по причине внутренней ошибки в API";
	Else
		vResult.Success 			= False;
		vResult.StatusDescription 	= "Неизвестный статус ответа";
	EndIf;
	
	Return vResult;
	
EndFunction

Function GetPricesMap(pInteractionParameters, pRoomRate, pPeriodFrom = Undefined, pPeriodTo = Undefined, pWeekOnly = False, pFullUpdate = False, pUpdateCachedPrices = False, rNothingToUpdate = True)
	
	vResult	= New Map;
	
	If NOT ValueIsFilled(pPeriodFrom) OR pWeekOnly Then
		vPeriodFrom = BegOfWeek(CurrentSessionDate());
	Else
		vPeriodFrom = pPeriodFrom;
	EndIf;
	
	If NOT ValueIsFilled(pPeriodTo) OR pWeekOnly Then
		vPeriodTo =  EndOfWeek(CurrentSessionDate());
	Else
		vPeriodTo = pPeriodTo;
	EndIf;
		
	vRoomTypes = InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "roomtypes", "ID");
	
	If vRoomTypes.Columns.Find("ID") <> Undefined Then
		
		vPricesByAccTypes 	= ChannelManagers.GetPrices(pInteractionParameters, pRoomRate, vPeriodFrom, vPeriodTo, pFullUpdate, pUpdateCachedPrices);
		
		If vPricesByAccTypes = Undefined Then
			Return Undefined;
		EndIf;
		
		For each vRoomType in vRoomTypes Do
			If ValueIsFilled(vRoomType.ID) Then
				vPricesMap = New Map;
												
				vPrices = New ValueTable;
				vPrices.Columns.Add("Period");
				vPrices.Columns.Add("Price");
				
				vAccTypes		= vRoomType.RefKey2.AccommodationTypes;
				vRoomTypePrices = vPricesByAccTypes.FindRows(New Structure("RoomType", vRoomType.RefKey1));

				// Read room rate accommodation type overrides
				vOverrides = cmGetRoomRateOverrides(pRoomRate, pInteractionParameters.Hotel, vRoomType.RefKey2, vRoomType.RefKey1);
				For each vRoomTypePriceRow in vRoomTypePrices Do
					If vPrices.Find(vRoomTypePriceRow.Period, "Period") = Undefined Then
						vNewPriceRow 		= vPrices.Add();
						vNewPriceRow.Period = vRoomTypePriceRow.Period;
						vNewPriceRow.Price 	= 0;
						For each vAccTypeRow in vAccTypes Do
							vAccommodationType = vAccTypeRow.AccommodationType;
							vTemplateLineNumber = vAccTypes.IndexOf(vAccTypeRow) + 1;
							If vOverrides.Count() > 0 Then
								vOverrideRows = vOverrides.FindRows(New Structure("AccommodationType, TemplateLineNumber", vAccommodationType, vTemplateLineNumber));
								If vOverrideRows.Count() > 0 Then
									vAccommodationType = vOverrideRows.Get(0).ToAccommodationType;
								EndIf;
							EndIf;
							vPricesByAccType = vPricesByAccTypes.FindRows(New Structure("Period, RoomType, AccommodationType", vRoomTypePriceRow.Period, vRoomType.RefKey1, vAccommodationType));
							If vPricesByAccType.Count() > 0 Then
								vNewPriceRow.Price = vNewPriceRow.Price + vPricesByAccType[0].Price;	
							EndIf;
						EndDo;
					EndIf;
				EndDo;
				
				If pWeekOnly Then
					i = 1;
					While i <= 7 Do
						vPrice = 0;
						For each vPriceRow in vPrices Do
							If i = WeekDay(vPriceRow.Period) Then
								vPrice = vPriceRow.Price;
								Break;
							EndIf;
						EndDo;
						rNothingToUpdate = False;
						vPricesMap.Insert(i, Format(vPrice,"NFD=2; NDS=.; NG="));
						i = i + 1;
					EndDo;					
				Else
					For each vPriceRow in vPrices Do
						vPrices.Sort("Period ASC");
						rNothingToUpdate = False;
						vPricesMap.Insert(Format(vPriceRow.Period, "DF=yyyy-MM-dd"), Format(vPriceRow.Price,"NFD=2; NDS=.; NG="));	
					EndDo;
				EndIf;
				
				vResult.Insert(vRoomType.ID, vPricesMap);
			EndIf;
		EndDo;
	EndIf;
	
	Return vResult;
	
EndFunction

Function GetRestrictionsMap(pInteractionParameters, pRoomRate, pPeriodFrom, pPeriodTo, pFullUpdate = False, rNothingToUpdate = True, rRestrictionsTable = Undefined)
	
	vResult				= New Map;
	rRestrictionsTable 	= New ValueTable;
	rRestrictionsTable.Columns.Add("RoomType");
	rRestrictionsTable.Columns.Add("PeriodFrom");
	rRestrictionsTable.Columns.Add("PeriodTo");
	
	vRoomTypes = InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "roomtypes", "ID");
	
	If vRoomTypes.Columns.Find("ID") <> Undefined Then
		
		vRestrictions 	= ChannelManagers.GetRestrictions(pInteractionParameters, pRoomRate, pPeriodFrom, pPeriodTo, pFullUpdate);
		
		If vRestrictions = Undefined Then
			Return Undefined;
		EndIf;
		
		For each vRoomType in vRoomTypes Do
			If ValueIsFilled(vRoomType.ID) Then
				vPeriodsMap = New Map;
				vPeriodFrom = Undefined;
				vPeriodTo	= Undefined;
				
				vRoomTypeRestrictions = vRestrictions.FindRows(New Structure("RoomType", vRoomType.RefKey1));
				If vRoomTypeRestrictions.Count() = 0 Then
					vRoomTypeRestrictions = vRestrictions.FindRows(New Structure("RoomType", Catalogs.RoomTypes.EmptyRef()));
				EndIf;
				
				For each vRoomTypeRestrictionsRow in vRoomTypeRestrictions Do
					vRestrictionsMap = New Map;
					vRestrictionsMap.Insert("min_stay", 			vRoomTypeRestrictionsRow.MLOS);
					vRestrictionsMap.Insert("min_stay_arrival", 	vRoomTypeRestrictionsRow.MLOS);
					vRestrictionsMap.Insert("max_stay", 			vRoomTypeRestrictionsRow.MaxLOS);
					vRestrictionsMap.Insert("closed", 				Number(vRoomTypeRestrictionsRow.StopSale));
					vRestrictionsMap.Insert("closed_arrival", 		Number(vRoomTypeRestrictionsRow.CTA));
					vRestrictionsMap.Insert("closed_departure", 	Number(vRoomTypeRestrictionsRow.CTD));
					vPeriodsMap.Insert(Format(vRoomTypeRestrictionsRow.Period, "DF=yyyy-MM-dd"), vRestrictionsMap);
					
					rNothingToUpdate = False;
					
					If vPeriodFrom = Undefined Then
						vPeriodFrom = vRoomTypeRestrictionsRow.Period;
					ElsIf vPeriodFrom > vRoomTypeRestrictionsRow.Period Then 
						vPeriodFrom = vRoomTypeRestrictionsRow.Period;
					EndIf;
					
					If vPeriodTo = Undefined Then
						vPeriodTo = vRoomTypeRestrictionsRow.Period;
					ElsIf vPeriodTo < vRoomTypeRestrictionsRow.Period Then 
						vPeriodTo = vRoomTypeRestrictionsRow.Period;
					EndIf;
					
				EndDo;
				
				If vPeriodFrom <> Undefined Then					
					vNewRow 			= rRestrictionsTable.Add();
					vNewRow.RoomType 	= vRoomType.RefKey1;
					vNewRow.PeriodFrom 	= vPeriodFrom;
					vNewRow.PeriodTo 	= vPeriodTo;
				EndIf;
				
				vResult.Insert(vRoomType.ID, vPeriodsMap);
			EndIf;
		EndDo;
	EndIf;
	
	Return vResult;
	
EndFunction

Function GetAvailabilityMap(pInteractionParameters, pPeriodFrom, pPeriodTo, pFullUpdate = False, rRawTable = Undefined)
	
	vResult = New Map;
		
	vRoomTypes = InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "roomtypes");
	
	If vRoomTypes.Columns.Find("ID") <> Undefined Then
		
		vAvailability 	= ChannelManagers.GetAvailability(pInteractionParameters, pPeriodFrom, pPeriodTo, pFullUpdate);
		rRawTable		= vAvailability;
		
		vCheckVirtuals = False;
		If vRoomTypes.Columns.Find("parentid") <> Undefined Then
			vCheckVirtuals = True;
		EndIf;
		
		For each vRoomType in vRoomTypes Do
			
			If vCheckVirtuals Then
				If ValueIsFilled(vRoomType.parentid) Then
					Continue;
				EndIf;
			EndIf;
			
			vIsForFolioSplit		= vRoomType.RefKey2.IsForFolioSplit;
			vAvailabilityMap 		= New Map;
			vRoomTypeAvailability 	= vAvailability.FindRows(New Structure("RoomType", vRoomType.RefKey1));
			For each vRoomTypeAvailabilityRow in vRoomTypeAvailability Do
				
				If vIsForFolioSplit = True Then
					vBalance = vRoomTypeAvailabilityRow.VacantBeds;	
				Else
					vBalance = vRoomTypeAvailabilityRow.VacantRooms;			
				EndIf;
				
				vCurrentPeriod = vRoomTypeAvailabilityRow.PeriodFrom;
				While vCurrentPeriod <= vRoomTypeAvailabilityRow.PeriodTo Do					
					vAvailabilityMap.Insert(Format(vCurrentPeriod, "DF=yyyy-MM-dd"), vBalance);
					vCurrentPeriod = vCurrentPeriod + 24*60*60;	
				EndDo;
			EndDo;
			vResult.Insert(vRoomType.ID, vAvailabilityMap);
		EndDo;
	EndIf;
		
	Return vResult;
	
EndFunction

Function LoadReservations(pInteractionParameters, pReservationsMap, pLoadAdultGuestsAmountFromExtraDataArray, pLoadChildGuestsAmountFromExtraDataArray, pGetPrices = True) Export
	
	vResult = New Structure("Success, FetchedReservations, Error", True, New Array, "");
	
	If pReservationsMap = Undefined Then
		Return vResult;
	EndIf;
	
	vBookings = pReservationsMap.Get("bookings");
	If vBookings = Undefined Then
		Return vResult;
	EndIf;
	
	vDefaultLanguageCode = Undefined;
	If ValueIsFilled(pInteractionParameters.Hotel) And ValueIsFilled(pInteractionParameters.Hotel.Language) Then
		vDefaultLanguageCode = Upper(TrimAll(pInteractionParameters.Hotel.Language.Code));
	EndIf;
	
	vReservationStatuses		= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "reservationstatuses", "ID");
	If vReservationStatuses.Columns.Find("ID") = Undefined OR vReservationStatuses.Count() = 0 Then
		vResult.Success = False;
		vResult.Error	= "Failed to find reservation statuses mappings!";
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservations", vLogEventType, , , vResult.Error, pInteractionParameters.MaxLogLenght);
		Return vResult;
	EndIf;

	For s = 1 To 2 Do
		For each vBooking in vBookings Do
			vResNumber		= vBooking.Get("number");
			vNewResNumber	= "";
			vResNumberFrom	= vBooking.Get("modified_from");
			vResNumberTo	= vBooking.Get("modified_to");
			If s = 1 Then
				// Process reservations where modified_to is filled only
				If Not ValueIsFilled(vResNumberTo) Then
					Continue;
				EndIf;
			Else
				If ValueIsFilled(vResNumberTo) Then
					Continue;
				ElsIf ValueIsFilled(vResNumberFrom) Then
					vNewResNumber = vResNumber;
					vResNumber = vResNumberFrom;
					// Check what numbers are available in database
					If StrFind(vResNumber, ",") > 0 Then
						vResNumbers = StrSplit(vResNumber, ",", False);
						For Each vResNumbersItem In vResNumbers Do
							If Not IsBlankString(vResNumbersItem) Then
								If ValueIsFilled(cmGetReservationByExternalCode(pInteractionParameters.Hotel, vResNumbersItem + "/1")) Then
									vResNumber = vResNumbersItem;
									Break;
								EndIf;
							EndIf;
						EndDo;
					Endif;
				EndIf;
			EndIf;
				
			vOTAID			= vBooking.Get("ota_id");		
			vOTABookingID	= vBooking.Get("ota_booking_id");
			vRoomTypeID 	= Format(vBooking.Get("roomtype_id"), "NG=");
			vRoomRateID		= Format(vBooking.Get("plan_id"), "NG=");
			vAgesArray 		= New Array;

			vAdults 		= 0;
			vChildren 		= 0;
			
			If pLoadAdultGuestsAmountFromExtraDataArray OR pLoadChildGuestsAmountFromExtraDataArray Then
				vPathArray	= New Array;
				vPathArray.Add("extra_array");
				vPathArray.Add("Guests");
				vPathArray.Add("Requested occupancy");
				vRequestedOccupancy = Catalogs.DataConvertationRules.GetMapValueByArrayPath(vBooking, vPathArray);

				If vRequestedOccupancy <> Undefined Then
					
					For each vGuest in vRequestedOccupancy Do
						vGuestType 	= vGuest.Get("type");	
						vGuestCount = vGuest.Get("count");
						If cmIsNumber(vGuestCount) Then
							vGuestCount = Number(vGuestCount);
						Else
							vGuestCount = 0;		
						EndIf;
						vGuestAge 	= vGuest.Get("age");
						If vGuestType = "adult" Then
							vAdults = vAdults + vGuestCount;	
						ElsIf vGuestType = "child" Then
							vChildren = vChildren + vGuestCount;
							If ValueIsFilled(vGuestAge) Then
								For i = 1 to vGuestCount Do
									vAgesArray.Add(vGuestAge);
								EndDo;
							EndIf;
						Else
							vAdults 		= vAdults + vGuestCount;
							vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
							InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservations", vLogEventType, , ,  "Unknown guest type, added as adult: " + vGuestType + "; Booking №:" + vResNumber, pInteractionParameters.MaxLogLenght);	
						EndIf; 
					EndDo;
				EndIf;
			EndIf;
			
			If NOT pLoadAdultGuestsAmountFromExtraDataArray OR vAdults = 0 Then 
				vAdults   = vBooking.Get("adults");
				If cmIsNumber(vAdults) Then
					vAdults = Number(vAdults);	
				Else
					vAdults = 0; 	
				EndIf;
			EndIf;
			
			If NOT pLoadChildGuestsAmountFromExtraDataArray OR vChildren = 0 Then 
				vChildren 	= vBooking.Get("children");
				If cmIsNumber(vChildren) Then
					vChildren = Number(vChildren);	
				Else
					vChildren = 0;
				EndIf;
			EndIf;
			
			vStatusID				= vBooking.Get("status_id");
			vReservationStatusRow 	= vReservationStatuses.Find(vStatusID, "ID");
			If vReservationStatusRow = Undefined Then
				vResult.Success = False;
				vResult.Error	= "Failed to find reservation status by ID:" + vStatusID + "; Booking №:" + vResNumber;
				vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservations", vLogEventType, , , vResult.Error, pInteractionParameters.MaxLogLenght);
				Continue;
			Else
				vReservationStatus = vReservationStatusRow.RefKey1;
			EndIf;
			
			If vReservationStatus.IsActive OR vReservationStatus.IsPreliminary Then
				
				If NOT ValueIsFilled(vRoomTypeID) Then
					vResult.Success = False;
					vResult.Error	= "Missing parameters roomtype_id or plan_id in booking №:" + vResNumber;
					vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservations", vLogEventType, , , vResult.Error, pInteractionParameters.MaxLogLenght);
					Continue;
				EndIf;
				
				vRoomTypesData = InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "roomtypes",,,, vRoomTypeID);
				If vRoomTypesData.Count() = 0 Then
					vResult.Success = False;
					vResult.Error	= "Failed to find roomtypes data by ID:" + vRoomTypeID + "; Booking №:" + vResNumber;
					vLogEventType	= Enums.ExternalSystemEventTypes.Error;
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservations", vLogEventType, , , vResult.Error, pInteractionParameters.MaxLogLenght);
					Continue;
				Else
					vRoomType = vRoomTypesData[0].RefKey1;
					//Get accommodation template and types
					vChildAge = pInteractionParameters.Hotel.ChildrenMaxAge;
					
					While vAgesArray.Count() < vChildren Do
						vAgesArray.Add(vChildAge);
					EndDo;
					
					//Seearch template by ages
					vAccomodationTemplateList = cmGetAccommodationTemplateDetailsByGuestsQuantity(vAdults, vChildren, vAgesArray, pInteractionParameters.Hotel);
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
						vResult.Error	= "Failed to find accommodation template! " + "Adults: " + vAdults + ", Children: " + vChildren + ", Ages: " + vAgesAsString + "; Booking №:" + vResNumber;
						vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation", vLogEventType, , , vResult.Error, pInteractionParameters.MaxLogLenght);
						Continue;		
					EndIf;
					
					vAccommodationTemplate 	= vAccomodationTemplateList[0].AccommodationTemplate;	
					vAccomodationTypes		= vAccommodationTemplate.AccommodationTypes;
					If vAccomodationTypes.Count() = 0 Then
						vResult.Success = False;
						vResult.Error	= "Empty accomodation template! " + vAccommodationTemplate + "; Booking №:" + vResNumber;
						vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservations", vLogEventType, , , vResult.Error, pInteractionParameters.MaxLogLenght);
						Continue;
					EndIf;
				EndIf;
				
				If ValueIsFilled(vRoomRateID) Then
					vRoomRatesData = InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "roomrates",,,, vRoomRateID);
					If vRoomRatesData.Count() > 0 Then
						vRoomRate = vRoomRatesData[0].RefKey1; 
					EndIf;
				Else
					vRoomRate = pInteractionParameters.Hotel.RoomRate;
				EndIf;
				
				If Not ValueIsFilled(vRoomRate) Then
					vResult.Success = False;
					vResult.Error	= "Failed to find roomrates data by ID:" + vRoomRateID;
					vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservations", vLogEventType, , , vResult.Error, pInteractionParameters.MaxLogLenght);
					Continue;					
				EndIf;
				
				If ValueIsFilled(vOTAID) Then
					vAgentsData = InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "agents",,,, vOTAID);
					If vAgentsData.Count() = 0 Then
						vResult.Success = False;
						vResult.Error	= "Failed to find agents data by ID:" + vOTAID;
						vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservations", vLogEventType, , , vResult.Error, pInteractionParameters.MaxLogLenght);
					Else
						vAgent = vAgentsData[0].RefKey1; 
					EndIf;
				 EndIf;
				
				vExternalGroupReservation 	= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalGroupReservation"));
				
				vMainGuest 					= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
				vMainGuest.ClientFirstName 	= vBooking.Get("name");
				vMainGuest.ClientLastName 	= vBooking.Get("surname");
				vMainGuest.ClientPhone 		= vBooking.Get("phone");
				vMainGuest.ClientEMail 		= vBooking.Get("email");		
				
				vPeriodFrom	= StrReplace(vBooking.Get("arrival"), "-", "");
				vPeriodFrom	= StrReplace(vPeriodFrom, " ", "");
				vPeriodFrom	= StrReplace(vPeriodFrom, ":", "");
				vPeriodFrom	= Date(vPeriodFrom);
				
				vPeriodTo	= StrReplace(vBooking.Get("departure"), "-", "");
				vPeriodTo	= StrReplace(vPeriodTo, " ", "");
				vPeriodTo	= StrReplace(vPeriodTo, ":", "");
				vPeriodTo	= Date(vPeriodTo);
				
				vGuestCount = vAdults + vChildren;
				
				vGuestsIndex 	= 1;
				vRoomUUID		= String(New UUID);
				While vGuestsIndex <= vGuestCount Do
					If vGuestsIndex <= vAccomodationTypes.Count() Then 
						vAccomodationType = vAccomodationTypes[vGuestsIndex-1].AccommodationType.Code;
					EndIf;
					vExternalGroupReservationRow 					= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/","WriteExternalGroupReservationRow"));
					vExternalGroupReservationRow.ReservationCode 	= String(vResNumber) + "/" + String(vGuestsIndex);
					If ValueIsFilled(vNewResNumber) Then
						vExternalGroupReservationRow.NewReservationCode = String(vNewResNumber) + "/" + String(vGuestsIndex);
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservations", Enums.ExternalSystemEventTypes.Info, , , "New reservation code, from: " + vExternalGroupReservationRow.ReservationCode + " to: " + vExternalGroupReservationRow.NewReservationCode, pInteractionParameters.MaxLogLenght);
					EndIf;
					vExternalGroupReservationRow.GroupCode 			= String(vOTABookingID) + "/" + vResNumber;
					If ValueIsFilled(vNewResNumber) Then
						vExternalGroupReservationRow.NewGroupCode 	= String(vOTABookingID) + "/" + vNewResNumber;
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservations", Enums.ExternalSystemEventTypes.Info, , , "New group code, from: " + vExternalGroupReservationRow.GroupCode + " to: " + vExternalGroupReservationRow.NewGroupCode, pInteractionParameters.MaxLogLenght);
					EndIf;
					vExternalGroupReservationRow.GroupClient 		= ChannelManagers.CopyXDTO(vMainGuest, XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));;
					vExternalGroupReservationRow.ReservationStatus	= vReservationStatus.Code;
					vExternalGroupReservationRow.PeriodFrom			= vPeriodFrom;
					vExternalGroupReservationRow.PeriodTo			= vPeriodTo;
					vExternalGroupReservationRow.Hotel				= pInteractionParameters.Hotel.Code;
					vExternalGroupReservationRow.RoomType			= TrimAll(vRoomType.Code);
					vExternalGroupReservationRow.AccommodationType	= TrimAll(vAccomodationType);
					vExternalGroupReservationRow.NumberOfRooms		= 1;
					vExternalGroupReservationRow.NumberOfPersons	= 1;
					vExternalGroupReservationRow.ExternalSystemCode	= pInteractionParameters.InteractionID;
					vExternalGroupReservationRow.DoPosting			= True;
					vExternalGroupReservationRow.RoomRate			= TrimAll(vRoomRate.Code);
					vExternalGroupReservationRow.ReservationRemarks = vBooking.Get("comment"); 
					vExternalGroupReservationRow.Room 				= vRoomUUID; 
					vExternalGroupReservationRow.RoomQuota 			= ?(ValueIsFilled(pInteractionParameters.Allotment), XMLString(pInteractionParameters.Allotment.Code),"");
					
					If vAgent <> Undefined Then
						vExternalGroupReservationRow.Agent			= TrimAll(vAgent.Code);
						vExternalGroupReservationRow.Customer		= TrimAll(vAgent.Code);
					EndIf;
					
					vPrices = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "PricesPerDate"));
					
					vPricesJSON =  vBooking.Get("prices");
					If ValueIsFilled(vPricesJSON) Then
						If pGetPrices = True Then
							vPricesMap 	= Catalogs.DataConvertationRules.JSONtoMap(vPricesJSON);
							For each vPricesMapRow in vPricesMap Do
								vPricePerDateRow 			= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "PricePerDateRow"));
								vPricePerDateRow.Date 		= Date(StrReplace(vPricesMapRow.Key, "-", ""));
								vPricePerDateRow.Price 		= Number(vPricesMapRow.Value);
								vPricePerDateRow.Currency 	= pInteractionParameters.Currency.Code;
								vPrices.PricePerDateRow.Add(vPricePerDateRow);
							EndDo;
						Else   
							vPrices = Undefined;
						EndIf;
					Else
						vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservations", vLogEventType, , , "Missing prices parameter in booking №:" + vResNumber, pInteractionParameters.MaxLogLenght);
					EndIf;
					
					If vGuestsIndex = 1 Then
						vExternalGroupReservationRow.AccommodationTemplate 	= vAccommodationTemplate.Code;
						vExternalGroupReservationRow.Client	= ChannelManagers.CopyXDTO(vMainGuest, XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
						If Not vPrices = Undefined And pGetPrices = True Then
							vExternalGroupReservationRow.PricesPerDate = vPrices;
						EndIf;
					Else
						vExternalGroupReservationRow.Client			= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
						If Not vPrices = Undefined And pGetPrices = True Then
							vPricesCopy = ChannelManagers.CopyXDTO(vPrices, XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "PricesPerDate"));
							vPricesCopy = ResetXDTOPrices(vPricesCopy);					
							vExternalGroupReservationRow.PricesPerDate = vPricesCopy;
						EndIf;
					EndIf;
					
					vExternalGroupReservation.WriteExternalGroupReservationRow.Add(vExternalGroupReservationRow);
					vGuestsIndex = vGuestsIndex + 1;
				EndDo;
				vAnswerXDTO = cmWriteExternalGroupReservation(vExternalGroupReservation, vDefaultLanguageCode, True);
				If ValueIsFilled(vAnswerXDTO.ErrorDescription) Then
					vResult.Success = False;
					vResult.Error	= "ru = 'Неудалось создать бронь по причине: '" + vAnswerXDTO.ErrorDescription;;
					vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservations", vLogEventType, , , vResult.Error, pInteractionParameters.MaxLogLenght);
					Continue;
				Else
					If ValueIsFilled(vNewResNumber) Then
						vResult.FetchedReservations.Add(vNewResNumber);
					Else
						vResult.FetchedReservations.Add(vResNumber);
					EndIf;
				EndIf;
				
			Else
				vCancelResult 	= cmCancelGroupReservation(String(vOTABookingID) + "/" + vResNumber, TrimAll(pInteractionParameters.Hotel.Code), pInteractionParameters.Code,,,,vReservationStatus);
				If ValueIsFilled(vNewResNumber) Then
					vResult.FetchedReservations.Add(vNewResNumber);
				Else
					vResult.FetchedReservations.Add(vResNumber);
				EndIf;			
			EndIf;
			
		EndDo;
	EndDo;
	
	Return vResult;
	
EndFunction

Function ResetXDTOPrices(pPrices)
	
	For each vPricePerDate in pPrices.PricePerDateRow Do 
		vPricePerDate.Price 		= 0;
	EndDo;
	
	Return pPrices;
	
EndFunction

