
#Region Public

// -------------------------------------------------------------------------
//
// Parameters:
//  pInteractionParameters		 - CatalogRef.ExternalSystemInteractions - Interaction parameters
//  pAmountOfDaysToUpdate		 - Number								 - Days rto unload update
//  pSkipPricesCacheUpdate		 - Boolean								 - Skip prices cache update
//  pFullUpdate					 - Boolean								 - Full update
//  pLoadReservations			 - Boolean								 - Load reservations
//  pUpdateAvailability			 - Boolean								 - Update availability
//  pUpdatePrices				 - Boolean								 - Update prices
//  pUsePriceTags				 - Boolean								 - Use price tags
//  pGetVacantRoomsAtMidnight	 - Boolean								 - Get vacant rooms at midnight
//
Procedure SyncData(pInteractionParameters, pAmountOfDaysToUpdate = 100, pSkipPricesCacheUpdate = True,
				   pFullUpdate = False, pLoadReservations, pUpdateAvailability, pUpdatePrices,
				   pUsePriceTags = False, pGetVacantRoomsAtMidnight = False) Export
				   
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
				If (CurrentSessionDate() - vCurrentSessionDate) > (18 * 3600) Then
					vMessage = NStr("en='It was not possible to block the interaction with the external system
									| to perform the exchange for 18 hours long!'; 
                                    |ru='За 18 часов не удалось установить блокировку на взаимодействие с внешней
									| системой для выполнения обмена!';
								    |de='18 Stunden lang war es nicht möglich, die Interaktion mit dem externen
									| System zu blockieren, um den Austausch durchzuführen!'");
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SyncData",
																				Enums.ExternalSystemEventTypes.Warning, , , vMessage);
					Return;
				Else
					cmWait(30);
				EndIf;
			EndIf;
		EndTry;
	EndDo;

	Try
		// Get reservations
		If pLoadReservations Then
			If vExternalInteractionObj.IsLocked() Then
				vExternalInteractionObj.Read();
				vExternalInteractionObj.Status = Enums.IntegrationStatuses.Warning;
				vExternalInteractionObj.ErrorDescription = NStr("en = 'Bookings are being loaded...';
																|de = 'Buchungen werden heruntergeladen...';
																|ru = 'Загружаются бронирования...'");
				vExternalInteractionObj.Write();
			EndIf;
			vReservationsResult = GetReservations(pInteractionParameters,
												  pInteractionParameters.SessionLastActivityTime, CurrentSessionDate());
		EndIf;
		
		If pUpdateAvailability Then   
			// Export availability
			If vExternalInteractionObj.IsLocked() Then
				vExternalInteractionObj.Read();
				vExternalInteractionObj.Status = Enums.IntegrationStatuses.Warning;
				vExternalInteractionObj.ErrorDescription = NStr("en = 'The remaining available rooms are being unloaded...';
																|de = 'Reste von freien Zimmern werden ausgelagert...';
																|ru = 'Выгружаются остатки свободных номеров...'");
				vExternalInteractionObj.Write();
			EndIf;
			
			SendAvailability(pInteractionParameters, pAmountOfDaysToUpdate, pFullUpdate, , , , pGetVacantRoomsAtMidnight);
			If vReservationsResult.AvailabilityUpdateDates <> Undefined
			   And vReservationsResult.AvailabilityUpdateDates.PeriodFrom <> Undefined Then
				SendAvailability(pInteractionParameters, pAmountOfDaysToUpdate, False,
								 vReservationsResult.AvailabilityUpdateDates.PeriodFrom,
								 vReservationsResult.AvailabilityUpdateDates.PeriodTo, , pGetVacantRoomsAtMidnight);
			EndIf;
			
			// Export restrictions
			If vExternalInteractionObj.IsLocked() Then
				vExternalInteractionObj.Read();
				vExternalInteractionObj.Status = Enums.IntegrationStatuses.Warning;
				vExternalInteractionObj.ErrorDescription = NStr("en = 'Restrictions are being uploaded...';
																|de = 'Einschränkungen werden entladen...';
																|ru = 'Выгружаются ограничения...'");
				vExternalInteractionObj.Write();
				SendRestrictions(pInteractionParameters, pAmountOfDaysToUpdate, pFullUpdate);
			EndIf;
		EndIf;
		
		If pUpdatePrices Then
			// Update interaction info
			If vExternalInteractionObj.IsLocked() Then
				vExternalInteractionObj.Read();
				vExternalInteractionObj.Status = Enums.IntegrationStatuses.Warning;
				vExternalInteractionObj.ErrorDescription = NStr("en = 'Prices are being uploaded...';
																|de = 'Die Preise werden ausgelagert...';
																|ru = 'Выгружаются цены...'");
				vExternalInteractionObj.Write();     
				SendPrices(pInteractionParameters, pAmountOfDaysToUpdate, pFullUpdate, vUpdateCachedPrices, , , , , pUsePriceTags);
			EndIf;
		EndIf; 

		// Update interaction parameters
		If vExternalInteractionObj.IsLocked() Then
			vLastSyncTimeUpdateError = ChannelManagers.UpdateLastSyncTime(vExternalInteractionObj, pFullUpdate,
																		  vCurrentSessionDate, "", pUpdateAvailability,
																		  pUpdatePrices, pUpdateAvailability);
			If Not IsBlankString(vLastSyncTimeUpdateError) Then
				Raise vLastSyncTimeUpdateError;
			EndIf;
		EndIf;
	Except
		vErrorText = cmGetRootErrorDescription(ErrorInfo());
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SyncData",
																	Enums.ExternalSystemEventTypes.Error, , , vErrorText);
	EndTry;
	
	// Unlock interaction
	If vExternalInteractionObj.IsLocked() Then
		vExternalInteractionObj.Unlock();
	EndIf;
	
EndProcedure // SyncData

// -----------------------------------------------------------------------------
//
// Parameters:
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - Interaction parameters
//  rErr					 - String								 - Error message
// 
// Returns:
//  Structure - HTTP request result
//
Function GetServicesData(pInteractionParameters, rErr) Export
	
	vParameters = New Structure;
	vParameters.Insert("Method", "GET");
	vParameters.Insert("MethodURL", "/services");
	vParameters.Insert("Function", "GetServicesData");
	
	Return HTTPQuery(pInteractionParameters, vParameters, , rErr);

EndFunction // GetServicesData

// -----------------------------------------------------------------------------
//
// Parameters:
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - Interaction parameters
//  rErr					 - String								 - Error message
// 
// Returns:
//  Structure - HTTP request result
//
Function GetCategoriesData(pInteractionParameters, rErr) Export
	
	vParameters = New Structure;
	vParameters.Insert("Method", "GET");
	vParameters.Insert("MethodURL", "/categories");
	vParameters.Insert("Function", "GetCategoriesData");
	
	Return HTTPQuery(pInteractionParameters, vParameters, , rErr);

EndFunction // GetCategoriesData

// -----------------------------------------------------------------------------
//
// Parameters:
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - Interaction parameters
//  rErr					 - String								 - Error message
// 
// Returns:
//  Structure - HTTP request result
//
Function GetRatePlansData(pInteractionParameters, rErr) Export
	
	vParameters = New Structure;
	vParameters.Insert("Method", "GET");
	vParameters.Insert("MethodURL", "/rate-plans");
	vParameters.Insert("Function", "GetRatePlansData");
	
	Return HTTPQuery(pInteractionParameters, vParameters, , rErr);

EndFunction // GetRatePlansData

// -----------------------------------------------------------------------------
//
// Parameters:
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - Interaction parameters
//  rErr					 - String								 - Error message
// 
// Returns:
//  Structure - HTTP request result
//
Function GetSourcesData(pInteractionParameters, rErr) Export
	
	vParameters = New Structure;
	vParameters.Insert("Method", "GET");
	vParameters.Insert("MethodURL", "/channels-map");
	vParameters.Insert("Function", "GetSourcesData");
	
	Return HTTPQuery(pInteractionParameters, vParameters, , rErr);

EndFunction // GetSourcesData

// -------------------------------------------------------------------------
//
// Parameters:
//  pInteractionParameters		 - CatalogRef.ExternalSystemInteractions - Interaction parameters
//  pAmountOfDaysToUpdate		 - Number								 - Amount of days to update
//  pFullUpdate					 - Boolean								 - Full update
//  pPeriodFrom					 - Date									 - Start date of unloading
//  pPeriodTo					 - Date									 - End date of unloading
//  pRoomTypes					 - Array								 - Room types to update
//  pGetVacantRoomsAtMidnight	 - Boolean								 - Get vacant rooms at midnight
// 
// Returns:
//  String - Error message
//
Function SendAvailability(pInteractionParameters, pAmountOfDaysToUpdate = 100, pFullUpdate = False,
						  pPeriodFrom = Undefined, pPeriodTo = Undefined, pRoomTypes = Undefined, pGetVacantRoomsAtMidnight = False) Export
	
	vRawValue = "";	
	vRequestBody = "";
	vError = "";
	
	Try		
		If pPeriodFrom = Undefined Then
			vPeriodFrom = BegOfDay(CurrentSessionDate());
		Else
			vPeriodFrom	= pPeriodFrom;
		EndIf;
		
		If pPeriodTo = Undefined Then
			vPeriodTo = vPeriodFrom + 24 * 60 * 60 * pAmountOfDaysToUpdate;
		Else
			vPeriodTo = pPeriodTo;
		EndIf;
		
		vAvailability = Undefined;
		vRequestBody = GetAvailabilityRequest(pInteractionParameters, vPeriodFrom, vPeriodTo,
											  pFullUpdate, vAvailability, pRoomTypes, pGetVacantRoomsAtMidnight);

		vParameters = New Structure;
		vParameters.Insert("Method", "POST");
		vParameters.Insert("MethodURL", "/availability");
		vParameters.Insert("RequestBody", vRequestBody);
		vParameters.Insert("Function", "SendAvailability");
		
		vResponseMap = HTTPQuery(pInteractionParameters, vParameters, vRawValue);
		
		If vResponseMap.Get("message") <> Undefined Then
			vMessage = vResponseMap.Get("message");
			If vMessage <> "success" Then
				Raise vMessage;
			EndIf;
		EndIf;
	Except
		vError = ErrorDescription();
		vLogEventType = Enums.ExternalSystemEventTypes.Error;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vParameters.Function,
																	vLogEventType, vRequestBody, vRawValue, vError);
	EndTry;
	
	Return vError;
	
EndFunction // SendAvailability

// -------------------------------------------------------------------------
//
// Parameters:
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - Interaction parameters
//  pAmountOfDaysToUpdate	 - Number								 - Amount of days to update
//  pFullUpdate				 - Boolean								 - Full update
//  pPeriodFrom				 - Date									 - Start date of unloading
//  pPeriodTo				 - Date									 - End date of unloading
//  pRoomTypes				 - Array								 - Room types to update
//  pRoomRates				 - Array								 - Room rates to update
// 
// Returns:
//  String - Error message 
//
Function SendRestrictions(pInteractionParameters, pAmountOfDaysToUpdate = 100, pFullUpdate = False,
					      pPeriodFrom = Undefined, pPeriodTo = Undefined, pRoomTypes = Undefined, pRoomRates = Undefined) Export
	
	vRawValue = "";	
	vRequestBody = "";
	vError = "";
	
	Try		
		If pPeriodFrom = Undefined Then
			vPeriodFrom = BegOfDay(CurrentSessionDate());
		Else
			vPeriodFrom	= pPeriodFrom;
		EndIf;
		
		If pPeriodTo = Undefined Then
			vPeriodTo = vPeriodFrom + 24 * 60 * 60 * pAmountOfDaysToUpdate;
		Else
			vPeriodTo = pPeriodTo;
		EndIf;
		
		vRequestBody = GetRestrictionsRequest(pInteractionParameters, vPeriodFrom, vPeriodTo,
											  pFullUpdate, pRoomTypes, pRoomRates);
		vParameters = New Structure;
		vParameters.Insert("Method", "POST");
		vParameters.Insert("MethodURL", "/restrictions");
		vParameters.Insert("RequestBody", vRequestBody);
		vParameters.Insert("Function", "SendRestrictions");
		
		vResponseMap = HTTPQuery(pInteractionParameters, vParameters, vRawValue);
		
		If vResponseMap.Get("message") <> Undefined Then
			vMessage = vResponseMap.Get("message");
			If vMessage <> "success" Then
				Raise vMessage;
			EndIf;
		EndIf;
	Except
		vError = ErrorDescription();
		vLogEventType = Enums.ExternalSystemEventTypes.Error;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vParameters.Function,
																	vLogEventType, vRequestBody, vRawValue, vError);
	EndTry;
	
	Return vError;
	
EndFunction // SendRestrictions

// -------------------------------------------------------------------------
//
// Parameters:
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - Interaction parameters
//  pAmountOfDaysToUpdate	 - Number								 - Amount of days to update
//  pFullUpdate				 - Boolean								 - Full update
//  pUpdateCachedPrices		 - Boolean								 - Update cached prices
//  pPeriodFrom				 - Date									 - Start date of unloading
//  pPeriodTo				 - Date									 - End date of unloading
//  pRoomTypes				 - Array								 - Room types to update
//  pRoomRates				 - Array								 - Room rates to update
//  pUsePriceTags			 - Boolean								 - Use price tags
// 
// Returns:
//  String - Error message 
//
Function SendPrices(pInteractionParameters, pAmountOfDaysToUpdate = 100, pFullUpdate = False,
					pUpdateCachedPrices = False, pPeriodFrom = Undefined, pPeriodTo = Undefined,
					pRoomTypes = Undefined, pRoomRates = Undefined, pUsePriceTags = False) Export
	
	vRawValue = "";	
	vRequestBody = "";
	vError = "";
	
	Try		
		If pPeriodFrom = Undefined Then
			vPeriodFrom = BegOfDay(CurrentSessionDate());
		Else
			vPeriodFrom	= pPeriodFrom;
		EndIf;
		vOneDay = 24 * 60 * 60;
		If pPeriodTo = Undefined Then
			vPeriodTo = vPeriodFrom + vOneDay * pAmountOfDaysToUpdate;
		Else
			vPeriodTo = pPeriodTo;
		EndIf;

		vRequestBody = GetPricesRequest(pInteractionParameters, vPeriodFrom, vPeriodTo, pFullUpdate,
										pUpdateCachedPrices, pRoomTypes, pRoomRates, pUsePriceTags);
										
		vParameters = New Structure;
		vParameters.Insert("Method", "POST");
		vParameters.Insert("MethodURL", "/rates");
		vParameters.Insert("RequestBody", vRequestBody);
		vParameters.Insert("Function", "SendPrices");
		
		vResponseMap = HTTPQuery(pInteractionParameters, vParameters, vRawValue);
		
		If vResponseMap.Get("message") <> Undefined Then
			vMessage = vResponseMap.Get("message");
			If vMessage <> "success" Then
				Raise vMessage;
			EndIf;
		EndIf;
		
	Except
		vError = ErrorDescription();
		vLogEventType = Enums.ExternalSystemEventTypes.Error;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vParameters.Function,
																	vLogEventType, vRequestBody, vRawValue, vError);
	EndTry;
	
	Return vError;
	
EndFunction // SendPrices

// -------------------------------------------------------------------------
//
// Parameters:
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - Interaction parameters
//  pPeriodFrom				 - Date									 - Start date of unloading
//  pPeriodTo				 - Date									 - End date of unloading
// 
// Returns:
//  Structure - Result of writing reservations from channel manager
//
Function GetReservations(pInteractionParameters, pPeriodFrom, pPeriodTo) Export
	
	vResult = New Structure("Success, Error, AvailabilityUpdateDates", False, "", Undefined);
	
	vRawValue = "";	
	
	Try
		vParameters = New Structure;
		vParameters.Insert("Method", "GET");
		vRequestString = "/bookings?range_start="
						 + EncodeString(Format(ToUniversalTime(pPeriodFrom), "DF=yyyy-MM-ddTHH:mm:ss+00:00"), StringEncodingMethod.URLEncoding)
						 + "&range_end="
						 + EncodeString(Format(ToUniversalTime(pPeriodTo), "DF=yyyy-MM-ddTHH:mm:ss+00:00"), StringEncodingMethod.URLEncoding);
		vParameters.Insert("MethodURL", vRequestString);
		vParameters.Insert("Function", "GetReservations from " + pPeriodFrom + " to " + pPeriodTo);
		
		vResponseMap = HTTPQuery(pInteractionParameters, vParameters, vRawValue);
		
		If vResponseMap.Count() > 0 Then
			vReservationLoadResult = LoadReservations(pInteractionParameters, vResponseMap);
			If vReservationLoadResult.Success Then
				vIntPObj = pInteractionParameters.GetObject();
				vIntPObj.SessionLastActivityTime = pPeriodTo;
				vIntPObj.Write();
				
				vResult.Success					= vReservationLoadResult.Success;
				vResult.Error					= vReservationLoadResult.Error;
				vResult.AvailabilityUpdateDates = New Structure("PeriodFrom, PeriodTo", pPeriodFrom, pPeriodTo);
			EndIf;
		EndIf;	
	Except
		vResult.Success = False;
		vResult.Error = ErrorDescription();
		vLogEventType = Enums.ExternalSystemEventTypes.Error;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, vParameters.Function,
																	vLogEventType, vRequestString, vRawValue, vResult.Error);
	EndTry;
	
	Return vResult;
	
EndFunction // GetReservations

// -------------------------------------------------------------------------
//
// Parameters:
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - Interaction parameters
//  pReservationsArray		 - Array								 - Reservations, received after HTTP request
// 
// Returns:
//  Structure - Result of writing reservations from channel manager
//
Function LoadReservations(pInteractionParameters, pReservationsArray) Export
	
	vResult = New Structure("Success, Error, AvailabilityUpdateDates", True, "", Undefined);
	vGuestGroupCode = "";
	
	vSourceOfBusiness = Undefined;
	vSourcesOfBusiness = InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "SourceOfBusiness");
	If vSourcesOfBusiness.Count() > 0 Then
		vSourceOfBusiness = vSourcesOfBusiness[0].RefKey1.Code; 
	EndIf;
	
	vMarketingCode = Undefined;
	vMarketingCodes = InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "MarketingCode");	
	If vMarketingCodes.Count() > 0 Then
		vMarketingCode = vMarketingCodes[0].RefKey1.Code; 
	EndIf;
	
	For Each vResMap In pReservationsArray Do
		// RESERVATION
		vExternalGroupReservation = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalGroupReservation"));
		vReservationRows = New Array;
		
		vGuestGroupCode = vResMap.Get("id");
		
		// Source (agent)
		vSource = "";
		vExternalId = "";
		vSourceMap = vResMap.Get("source");
		If vSourceMap.Count() > 0 Then
			vSource = vSourceMap.Get("name");
			If ValueIsFilled(vSource) Then 
				vRes = InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "sources", , , , , vSource);
				If vRes.Count() > 0 Then
					vObjectRef = vRes[0].RefKey1;
					If ValueIsFilled(vObjectRef) Then
						vSource = vObjectRef.Code;
					EndIf;
				EndIf;
			EndIf;
			vExternalId = vSourceMap.Get("external_id");
		EndIf;
			
		// Customer
		vCustomerInfoMap = vResMap.Get("customer_info");
		If vCustomerInfoMap <> Undefined And vCustomerInfoMap.Count() > 0 Then
			vMainClient = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
			vMainClient.ClientFirstName = vCustomerInfoMap.Get("first_name");
			vMainClient.ClientLastName = vCustomerInfoMap.Get("last_name");
			vMainClient.ClientPhone = vCustomerInfoMap.Get("phone");
			vGuestEmail = vCustomerInfoMap.Get("email");
			If vGuestEmail = Undefined Then
				vGuestEmail = "";
			EndIf;
			vMainClient.ClientEMail = vGuestEmail;
		Else
			vErrorMessage =  NStr("en = 'The customer is not filled in! Reservation number in the channel: ';
								  |de = 'Der Kunde ist nicht ausgefüllt! Reservierungsnummer im Kanal: ';
								  |ru = 'Не заполнен заказчик! Номер брони в канале: '") + vExternalId;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation", Enums.ExternalSystemEventTypes.Error, , , vErrorMessage);	
			Raise vErrorMessage;
		EndIf;
		
		vCustomerExternalGroupReservationRow = Undefined;
		vPaymentsArray = New Array;
		
		// Services
		vServicesXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "ChargeExtraServices"));
		// Room stays
		For Each vRoom In vResMap.Get("room_stays") Do
			vResNumber = vRoom.Get("id");
			vResStatus = vRoom.Get("status");
			vRoomRate = vRoom.Get("rate_plan_id");
			vRoomType = vRoom.Get("category_id");
			vRoomUUID = New UUID;
			vCheckInDate = vRoom.Get("check_in");
			vCheckOutDate = vRoom.Get("check_out");
			vCheckInTime = vRoom.Get("check_in_time");
			vCheckOutTime = vRoom.Get("check_out_time");
			vAdultsAmount = vRoom.Get("adults_amount");
			vChildrenAmount = vRoom.Get("children_amount");
			vGuestsAmount = vAdultsAmount + vChildrenAmount;
			
			vMappedStatus = InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "reservationstatuses", "id", , , , vResStatus);
			If vMappedStatus.Count() > 0 Then
				vObjectRef = vMappedStatus[0].RefKey1;
				If ValueIsFilled(vObjectRef) Then
					vResStatus = vObjectRef.Code;
				EndIf;
			EndIf;
			
			vMappedRoomRate = InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "roomrates", "id", , , , vRoomRate);
			If vMappedRoomRate.Count() > 0 Then
				vObjectRef = vMappedRoomRate[0].RefKey1;
				If ValueIsFilled(vObjectRef) Then
					If Not ValueIsFilled(vCheckInTime) Then
						If ValueIsFilled(vObjectRef.DefaultCheckInTime) Then
							vCheckInTime = Format(vObjectRef.DefaultCheckInTime, "DF=HH:mm");
						Else
							vCheckInTime = Format(vObjectRef.ReferenceHour, "DF=HH:mm");
						EndIf;
					EndIf;
					
					If Not ValueIsFilled(vCheckOutTime) Then
						If ValueIsFilled(vObjectRef.DefaultCheckOutTime) Then
							vCheckOutTime = Format(vObjectRef.DefaultCheckOutTime, "DF=HH:mm");
						Else
							vCheckOutTime = Format(vObjectRef.ReferenceHour, "DF=HH:mm");
						EndIf;
					EndIf;
					vRoomRate = vObjectRef.Code;
				EndIf;
			EndIf;
			
			vMappedRoomType = InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "roomtypes", "id", , , , vRoomType);
			If vMappedRoomType.Count() > 0 Then
				vRoomType = vMappedRoomType[0].RefKey1;
				vRoomTypeCode = vRoomType.Code;
			Else
				Raise NStr("en = 'No room type found! Reservation number: ';
						   |de = 'Keine Zimmerkategorie gefunden! Resernvierungsnummer: ';
						   |ru = 'Не найден тип номера! Номер брони: '") + vResNumber; 
			EndIf;
			
			// Children ages
			vChildrenArray = vRoom.Get("children");
			vChildrenAgesStructure = GetGuestCount(pInteractionParameters, vChildrenArray);
			vAgesArray = vChildrenAgesStructure.Ages;
			
			vAccommodationTemplate = cmGetAccommodationTemplateByGuestsQuantityAndRoomType(vAdultsAmount, vChildrenAgesStructure.Teenagers, vChildrenAgesStructure.Childs, vChildrenAgesStructure.Infants, vRoomType,
																						   pInteractionParameters.Hotel, , True);
			vAccommodationTypes	= Undefined;
			If ValueIsFilled(vAccommodationTemplate) Then																				   
				vAccommodationTypes = vAccommodationTemplate.AccommodationTypes;
			EndIf;
			
			// Guests
			vGuestsArray = vRoom.Get("guests");
			If vGuestsArray <> Undefined Then
				vGuestsArrayCount = vGuestsArray.Count();
				If vGuestsArrayCount > 0 Then
					vInd = 0;
					While vInd < vGuestsAmount Do
						// RESERVATION ROW
						vExternalGroupReservationRow = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalGroupReservationRow"));
						vExternalGroupReservationRow.Hotel = pInteractionParameters.Hotel.Code;
						If ValueIsFilled(vSource) Then
							vExternalGroupReservationRow.Customer = vSource;
							vExternalGroupReservationRow.ReservationRemarks = NStr("en = 'Reservation number: ';
																				   |de = 'Reservierungsnummer: ';
																				   |ru = 'Номер брони: '") + vResNumber;
						EndIf;
						
						If vSourceOfBusiness <> Undefined Then
							vExternalGroupReservationRow.SourceOfBusiness = vSourceOfBusiness;
						EndIf;
						
						If vMarketingCode <> Undefined Then
							vExternalGroupReservationRow.MarketingCode = vMarketingCode;
						EndIf;
						
						vGuestEmailIsFilled = False;
						If vInd < vGuestsArrayCount Then
							vClient = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
							vClient.ClientFirstName = vGuestsArray[vInd].Get("first_name");
							vClient.ClientLastName = vGuestsArray[vInd].Get("last_name");
							vClient.ClientPhone = vGuestsArray[vInd].Get("phone");
							vGuestEmail = vGuestsArray[vInd].Get("email");
							If ValueIsFilled(vGuestEmail) Then
								vGuestEmailIsFilled = True;
							EndIf;
							If vGuestEmail = Undefined Then
								vGuestEmail = "";
							EndIf;
							vClient.ClientEMail = vGuestEmail;
							vExternalGroupReservationRow.Client = ChannelManagers.CopyXDTO(vClient, XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
						Else
							vClient = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
							vExternalGroupReservationRow.Client = vClient;
						EndIf;
						
						vExternalGroupReservationRow.RoomRate = TrimAll(vRoomRate);
						vExternalGroupReservationRow.Room = String(vRoomUUID);
						vExternalGroupReservationRow.PeriodFrom	= vCheckInDate + ?(ValueIsFilled(vCheckInTime), "T" + vCheckInTime + ":00", "");
						vExternalGroupReservationRow.PeriodTo = vCheckOutDate + ?(ValueIsFilled(vCheckOutTime), "T" + vCheckOutTime + ":00", "");
						vExternalGroupReservationRow.ReservationStatus = TrimAll(vResStatus);
						vExternalGroupReservationRow.GroupCode = vGuestGroupCode;
						vExternalGroupReservationRow.NumberOfRooms = 1;
						vExternalGroupReservationRow.NumberOfPersons = 1;
						vExternalGroupReservationRow.ExternalSystemCode	= pInteractionParameters.InteractionID;
						vExternalGroupReservationRow.DoPosting = True;
										
						If vInd = 0 Then
							If ValueIsFilled(vAccommodationTemplate) Then
								vExternalGroupReservationRow.AccommodationTemplate = vAccommodationTemplate.Code;
							EndIf;
							vExternalGroupReservationRow.ReservationCode = vResNumber;
						Else
							vAgesArrayCount = vAgesArray.Count();
							If vAgesArrayCount > 0 Then
								If (vAgesArrayCount >= vGuestsAmount - vInd) And Not vGuestEmailIsFilled Then
									vAge = vAgesArray[0];
									vAgesArray.Delete(0);
									vExternalGroupReservationRow.GuestAge = Number(vAge);
								EndIf;
							EndIf;
							vExternalGroupReservationRow.ReservationCode = vResNumber + "/" + vInd;
						EndIf;
						
						vExternalGroupReservationRow.RoomType = TrimAll(vRoomTypeCode);
						
						If vAccommodationTypes <> Undefined And vAccommodationTypes.Count() > 0
						And vAccommodationTypes.Count() = vGuestsAmount Then																									   
							vExternalGroupReservationRow.AccommodationType = vAccommodationTypes[vInd].AccommodationType.Code;
						Else
							vErrorMessage = NStr("en = 'No accommodation template found! Reservation number: ';
												 |de = 'Keine Unterkunftsvorlage gefunden! Reservierungsnummer: ';
												 |ru = 'Не найден шаблон размещения! Номер брони: '") + vResNumber;
							InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation (template search)", Enums.ExternalSystemEventTypes.Error, , , vErrorMessage);	
							Raise vErrorMessage;
						EndIf;
						
						// Skip customer if it is not first room in booking
						If vClient.ClientLastName = vMainClient.ClientLastName And vClient.ClientFirstName = vMainClient.ClientFirstName Then
						    If vCustomerExternalGroupReservationRow = Undefined Then
								vCustomerExternalGroupReservationRow = ChannelManagers.CopyXDTO(vExternalGroupReservationRow, XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalGroupReservationRow"));
							Else
								vGuestsArray.Delete(vInd);
								vGuestsArrayCount = vGuestsArrayCount - 1;
								Continue;
							EndIf;
						Else
							vReservationRows.Add(vExternalGroupReservationRow);
						EndIf;
						vInd = vInd + 1;
					EndDo;
				EndIf;
			EndIf;
			
			vServicesArray = vRoom.Get("services");
			For Each vService In vServicesArray Do
				vServiceID = vService.Get("service_id");
				
				vMappedService = InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "services", "id", , , , vServiceID);
				If vMappedService.Count() > 0 Then
					vObjectRef = vMappedService[0].RefKey1;
					If ValueIsFilled(vObjectRef) Then
						vServiceID = vObjectRef.Code;
					EndIf;
				EndIf;
				
				vServiceStartTime = vService.Get("time_start");
				vServiceEndTime = vService.Get("time_end");
				vServiceStartDate = ReadJSONDate(vService.Get("date_start")
									+ ?(ValueIsFilled(vServiceStartTime), "T00:00:00", "T" + vServiceStartTime + ":00"),
									JSONDateFormat.ISO);
				vServiceEndDate = ReadJSONDate(vService.Get("date_end")
								  + ?(ValueIsFilled(vServiceEndTime), "T00:00:00", "T" + vServiceEndTime + ":00"),
								  JSONDateFormat.ISO);
				vServiceStartTime = vService.Get("time_start");
				vServiceEndTime = vService.Get("time_end");
				vServiceAmount = vService.Get("amount");
				vServicePrice = vService.Get("price"); 
				
				vServiceRowXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "ChargeExtraServiceRow"));
				vServiceRowXDTO.Service 	= TrimAll(vServiceID);
				vServiceRowXDTO.Price 		= vServicePrice;
				vServiceRowXDTO.Quantity 	= vServiceAmount * ((BegOfDay(vServiceEndDate) - BegOfDay(vServiceStartDate)) / (60 * 60 * 24) + 1);
				vServiceRowXDTO.Currency 	= pInteractionParameters.Currency.Code;
				vServiceRowXDTO.ChargeDate 	= vServiceStartDate;
				vServicesXDTO.ChargeExtraServiceRow.Add(vServiceRowXDTO);
				
				// Service payments
				vServicePaymentHistory = vService.Get("payment_history");
				For Each vServicePayment In vServicePaymentHistory Do
					vKindOfOperation = vServicePayment.Get("operation_kind");
					If vKindOfOperation = "PAYMENT" Then
						vServicePaymentStructure = New Structure;
						vServicePaymentStructure.Insert("PaymentExtCode", vServicePayment.Get("id"));
						vServicePaymentStructure.Insert("Amount", vServicePayment.Get("amount"));
						vServicePaymentStructure.Insert("PaymentMethod", vServicePayment.Get("payment_type"));
						vServicePaymentStructure.Insert("CurrencyCode", pInteractionParameters.Currency.Code);
						vServicePaymentStructure.Insert("CreationDate", ReadJSONDate(vServicePayment.Get("created_at") + "T00:00:00", JSONDateFormat.ISO));
						vPaymentsArray.Add(vServicePaymentStructure);
					EndIf;
				EndDo;
			EndDo;
			// Accommodation payments
			vPaymentHistoryArray = vRoom.Get("payment_history");
			For Each vPayment In vPaymentHistoryArray Do
				vKindOfOperation = vPayment.Get("operation_kind");
				If vKindOfOperation = "PAYMENT" Then
					vPaymentStructure = New Structure;
					vPaymentStructure.Insert("PaymentExtCode", vPayment.Get("id"));
					vPaymentStructure.Insert("Amount", vPayment.Get("amount"));
					vPaymentStructure.Insert("PaymentMethod", vPayment.Get("payment_type"));
					vPaymentStructure.Insert("CurrencyCode", pInteractionParameters.Currency.Code);
					vPaymentStructure.Insert("CreationDate", ReadJSONDate(vPayment.Get("created_at") + "T00:00:00", JSONDateFormat.ISO));
					vPaymentsArray.Add(vPaymentStructure);
				EndIf;
			EndDo;
		EndDo;
		If vServicesXDTO.GetList("ChargeExtraServiceRow").Count() > 0 Then  
			If vCustomerExternalGroupReservationRow = Undefined Then
				If vReservationRows.Count() > 0 Then
					vExternalGroupReservationFirst = vReservationRows.Get(0);
					vExternalGroupReservationFirst.ChargeExtraServices = vServicesXDTO;
				EndIf;	
			Else	
				vCustomerExternalGroupReservationRow.ChargeExtraServices = vServicesXDTO;								
			EndIf;	
		EndIf;           
		If vCustomerExternalGroupReservationRow <> Undefined Then
			vReservationRows.Insert(0, vCustomerExternalGroupReservationRow);     
		EndIf;
		For Each vRow In vReservationRows Do
			vExternalGroupReservation.WriteExternalGroupReservationRow.Add(vRow);
		EndDo;
		
		vAnswerXDTO = cmWriteExternalGroupReservation(vExternalGroupReservation, , True);
		If ValueIsFilled(vAnswerXDTO.ErrorDescription) Then
			vErrorMessage = NStr("en = 'Failed to get reservation № ';
								 |de = 'Reservierung fehlgeschlagen № ';
								 |ru = 'Не удалось загрузить бронь № '") + vGuestGroupCode + ": " + vAnswerXDTO.ErrorDescription;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation (template search)", Enums.ExternalSystemEventTypes.Error, , , vErrorMessage);	
			Raise vErrorMessage;
		Else
			vResult.Success = True;
			For Each vPayment In vPaymentsArray Do
				If vPayment.Amount > 0 Then
					vPaymentMethodCode = "";
					If ValueIsFilled(vPayment.PaymentMethod) Then
						vPaymentMethod = GetPaymentMethod(pInteractionParameters, vPayment.PaymentMethod);
						If ValueIsFilled(vPaymentMethod) Then
							vPaymentMethodCode = vPaymentMethod.Code;
						EndIf;
					EndIf;
					vPaymentXDTO = cmWriteExternalPayment("", vGuestGroupCode, , , , , , vPaymentMethodCode, vPayment.Amount,
														  vPayment.CurrencyCode, , pInteractionParameters.Hotel.Code,
														  pInteractionParameters.InteractionID, , , , , vPayment.CreationDate, , vPayment.PaymentExtCode, "XDTO");
					vPaymentError = TrimAll(vPaymentXDTO.ErrorDescription);
					If Not vPaymentError = "" Then
						vErrorMessage = "Failed to create payment: " + vPaymentError + "; Booking №:" + vGuestGroupCode + "; Payment №:" + vPayment.PaymentExtCode;
						vLogEventType = Enums.ExternalSystemEventTypes.Error;
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation (creating payments)", vLogEventType, , , vErrorMessage);
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	If pReservationsArray.Count() = 0 Then
		vResult.Success = True;
	EndIf;
	
	Return vResult;
	
EndFunction // LoadReservations

#EndRegion

#Region Private

// -------------------------------------------------------------------------
//
// Parameters:
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - Interaction parameters
//  pChildrenArray			 - Array								 - Children data
// 
// Returns:
//  Structure - Result of of processing the received data
//
Function GetGuestCount(pInteractionParameters, pChildrenArray)
	
	vResult = New Structure;
	vResult.Insert("Childs", 0);
	vResult.Insert("Infants", 0);
	vResult.Insert("Teenagers", 0);
	vResult.Insert("Ages", New Array);
	
	vChildAge	  = pInteractionParameters.Hotel.ChildrenMaxAge;
	vInfantAge	  = pInteractionParameters.Hotel.InfantsMaxAge;
	vTeenagersAge = pInteractionParameters.Hotel.TeenagersMaxAge;
	
	For Each vChild In pChildrenArray Do
		vAgeFrom = vChild.Get("age_from");
		vAgeFrom = ?(vAgeFrom = 0, 1, vAgeFrom);
		If vAgeFrom <> Undefined Then
			vAmount = vChild.Get("amount");
			If vAmount > 0 Then
				vAgeFrom = Number(vAgeFrom);
				If vAgeFrom <= vInfantAge Then
					vResult.Infants = vResult.Infants + vAmount;
					For i = 1 To vAmount Do 
						vResult.Ages.Add(vAgeFrom);
					EndDo;
				ElsIf vAgeFrom <= vChildAge Then
					vResult.Childs = vResult.Childs + vAmount;
					For i = 1 To vAmount Do
						vResult.Ages.Add(vAgeFrom);
					EndDo;
				ElsIf vAgeFrom <= vTeenagersAge Then
					vResult.Teenagers = vResult.Teenagers + vAmount;
					For i = 1 To vAmount Do
						vResult.Ages.Add(vAgeFrom);
					EndDo;
				Else
					vResult.Childs = vResult.Childs + vAmount;
					For i = 1 To vAmount Do
						vResult.Ages.Add(vAgeFrom);
					EndDo;
					vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation.GetGuestCount", vLogEventType, , , "Unknown child age: " + vAgeFrom);	
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
	Return vResult;
EndFunction // GetGuestCount

// --------------------------------------------------------------------------------
//
// Parameters:
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - Interaction parameters
//  pParameters				 - Structure							 - HTTP request parameters
//  pRawBody				 - String								 - Raw HTTP request body
//  rErr					 - String								 - Error message
// 
// Returns:
//  Map - Result of HTTP request
//
Function HTTPQuery(pInteractionParameters, pParameters, pRawBody = "", rErr = "")
	
	vResMap = New Map;
	
	vRequestBody = Undefined;
	
	vMethod = pParameters.Method;
	vRequestURL = pInteractionParameters.HttpAddress + pParameters.MethodURL;
	If pParameters.Property("RequestBody") Then
		vRequestBody = pParameters.RequestBody;
	EndIf;
	
	vHeaders = New Structure;
	vHeaders.Insert("Authorization", "Bearer " + pInteractionParameters.Password);
	
	vRes = Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, vHeaders, vRequestURL,
															   vMethod, , vRequestBody, "JSON", , , , , , , , False, pParameters.Function);
	
	rErr = "";
	If vRes.Error = Undefined Then
		vStatuscode = vRes.StatusCode;
		If vStatuscode = 200 Then
			Try
				pRawBody = vRes.Body;
				vResMap = Catalogs.DataConvertationRules.JSONtoMap(vRes.Body);				
			Except
				rErr = ErrorDescription();
			EndTry;
		Else
			rErr = GetErrorMessage(vStatuscode);
		EndIf;
	EndIf;
	If Not IsBlankString(rErr) Then
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, pParameters.Function, 
																	Enums.ExternalSystemEventTypes.Error, 
																	?(ValueIsFilled(vRequestBody), vRequestBody, pParameters.MethodURL), vRes, rErr);
	EndIf;
	
	Return vResMap;
	
EndFunction // HTTPQuery

// --------------------------------------------------------------------------------
//
// Parameters:
//  pStatusCode	 - Number	 - Status of HTTP response
// 
// Returns:
//  String - Error message
//
Function GetErrorMessage(pStatusCode)
	
	If pStatusCode = 400 Then
		vMessage = NStr("en='Bad request!';
						|ru='Неверный запрос!';
						|de='Ungültige Anfrage!'");
	ElsIf pStatusCode = 401 Then
		vMessage = NStr("en='Not valid authentication credentials for the operation!';
						|ru='Недопустимые учетные данные для проверки подлинности для операции!';
						|de='Ungültige Authentifizierungsdaten für den Vorgang!'");
	ElsIf pStatusCode = 403 Then
		vMessage = NStr("en='No access the specified operation!';
						|ru='Нет доступа к указанной операции!';
						|de='Kein Zugriff auf die angegebene Operation!'");
	ElsIf pStatusCode = 404 Then
		vMessage = NStr("en='Resource was not found!';
						|ru='Ресурс не найден!';
						|de='Ressource wurde nicht gefunden!'");
	ElsIf pStatusCode = 409 Then
		vMessage = NStr("en='Operation aborted!';
						|ru='Операция прервана!';
						|de='Vorgang abgebrochen!'");
	ElsIf pStatusCode = 429 Then
		vMessage = NStr("en='Too many requests!';
						|ru='Cлишком много запросов!';
						|de='Zu viele Anfragen!'");
	ElsIf pStatusCode = 499 Then
		vMessage = NStr("en='The user canceled the operation!';
						|ru='Пользователь отменил операцию!';
						|de='Der Benutzer hat den Vorgang abgebrochen!'");
	ElsIf pStatusCode = 500 Then
		vMessage = NStr("en='Unknown error!';
						|ru='Неизвестная ошибка!';
						|de='Unbekannter Fehler!'");
	ElsIf pStatusCode = 501 Then
		vMessage = NStr("en='Operation not supported!';
						|ru='Операция не поддерживается!';
						|de='Betrieb wird nicht unterstützt!'");
	ElsIf pStatusCode = 503 Then
		vMessage = NStr("en='Service is unavailable!';
						|ru='Сервис недоступен!';
						|de='Service ist nicht verfügbar!'");
	ElsIf pStatusCode = 504 Then
		vMessage = NStr("en='Timeout expired!';
						|ru='Время ожидания истекло!';
						|de='Timeout abgelaufen!'");
	Else
		vMessage = "";
	EndIf;
	vMessage = NStr("en='Failed to exchange!';
					|ru='Не удалось выполнить обмен!';
					|de='Austausch fehlgeschlagen!'") + ?(Not IsBlankString(vMessage), " " + vMessage, "");
	
	Return vMessage;
	
EndFunction // GetErrorMessage

#Region GetRequest

// -------------------------------------------------------------------------
//
// Parameters:
//  pInteractionParameters		 - CatalogRef.ExternalSystemInteractions - Interaction parameters
//  pPeriodFrom					 - Date									 - Start date of unloading
//  pPeriodTo					 - Date									 - End date of unloading
//  pFullUpdate					 - Boolean								 - Full update
//  rRawTable					 - ValueTable							 - Availability table to return
//  pRoomTypes					 - Array								 - Room types to update
//  pGetVacantRoomsAtMidnight	 - Boolean								 - Get vacant rooms at midnight
// 
// Returns:
//  String - JSON body to HTTP request
//
Function GetAvailabilityRequest(pInteractionParameters, pPeriodFrom, pPeriodTo, pFullUpdate = False,
								rRawTable = Undefined, pRoomTypes = Undefined, pGetVacantRoomsAtMidnight = False)
								
	vJson = "";
	
	vRoomTypes 		   = InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "roomtypes", 	"ID");
	vAllotments 	   = InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "allotments");
	vDefaultAllotments = InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "DefaultAllotment");
	
	If pRoomTypes <> Undefined Then
		vClearArray = New Array;
		For Each vRoomTypeRow In vRoomTypes Do
			If pRoomTypes.Find(vRoomTypeRow.RefKey1) = Undefined Then
				vClearArray.Add(vRoomTypeRow);
			EndIf;
		EndDo;
		For Each vRow In vClearArray Do
			vRoomTypes.Delete(vRow);
		EndDo;
	EndIf;
	
	vDefaultAllotment		= Undefined;
	vUseDefaultAllotment 	= True;
	If vDefaultAllotments <> Undefined And vDefaultAllotments.Count() > 0 Then
		If ValueIsFilled(vDefaultAllotments[0].RefKey1) Then
			vDefaultAllotment = vDefaultAllotments[0].RefKey1;
		EndIf;
		vUseDefaultAllotment = Not vDefaultAllotments[0].Use;	
	EndIf;
	
	If vRoomTypes.Columns.Find("ID") <> Undefined And vRoomTypes.Count() > 0 Then
		vAvailability = Undefined;
		If vUseDefaultAllotment = True Then
			vAvailability = ChannelManagers.GetAvailability(pInteractionParameters, pPeriodFrom, pPeriodTo,
															pFullUpdate, vDefaultAllotment, pGetVacantRoomsAtMidnight);
			// Build JSON
			// Root
			vRoomTypesArray = New Array;
			
			For Each vRoomType In vRoomTypes Do
				vRoomTypeAvailability = vAvailability.FindRows(New Structure("RoomType", vRoomType.RefKey1));
				For Each vRoomTypeAvailabilityRow In vRoomTypeAvailability Do
					vBalance 	= vRoomTypeAvailabilityRow.VacantRooms;			
					// Item array of updates
					vUpdateStructure = New Structure;
					vUpdateStructure.Insert("date_start", Format(vRoomTypeAvailabilityRow.PeriodFrom, "DF=yyyy-MM-dd"));
					vUpdateStructure.Insert("date_end", Format(vRoomTypeAvailabilityRow.PeriodTo, "DF=yyyy-MM-dd"));
					vUpdateStructure.Insert("rooms_available", vBalance);
					
					// Updates array
					vUpdatesArray = New Array;
					vUpdatesArray.Add(vUpdateStructure);
					
					// Root array item
					vRoomTypeStruct = New Structure;
					vRoomTypeStruct.Insert("category_id", vRoomType.ID);
					vRoomTypeStruct.Insert("updates", vUpdatesArray);
					
					vRoomTypesArray.Add(vRoomTypeStruct);
				EndDo;
			EndDo;
			vJson = Catalogs.DataConvertationRules.MapToJSON(vRoomTypesArray);
		EndIf;
		
		If vAvailability <> Undefined Then
			rRawTable = vAvailability;
		EndIf;
		
		If vAllotments <> Undefined Then
			For Each vAllotment In vAllotments Do
				vAvailability 	= ChannelManagers.GetAvailability(pInteractionParameters, pPeriodFrom, 
																  pPeriodTo, pFullUpdate, vAllotment.RefKey1);
				If rRawTable <> Undefined Then
					For Each vRow In vAvailability Do
						vNewRow = rRawTable.Add();
						FillPropertyValues(vNewRow, vRow);
					EndDo;
				Else
					rRawTable = vAvailability;
				EndIf;
				
				// Build JSON
				// Root
				vRoomTypesArray = New Array;
				
				For Each vRoomType In vRoomTypes Do
					vRoomTypeAvailability 	= vAvailability.FindRows(New Structure("RoomType", vRoomType.RefKey1));
					For Each vRoomTypeAvailabilityRow In vRoomTypeAvailability Do
						vBalance 	= vRoomTypeAvailabilityRow.VacantRooms;			
						// Item array of updates
						vUpdateStructure = New Structure;
						vUpdateStructure.Insert("date_start", Format(vRoomTypeAvailabilityRow.PeriodFrom, "DF=yyyy-MM-dd"));
						vUpdateStructure.Insert("date_end", Format(vRoomTypeAvailabilityRow.PeriodTo, "DF=yyyy-MM-dd"));
						vUpdateStructure.Insert("rooms_available", vBalance);
						
						// Updates array
						vUpdatesArray = New Array;
						vUpdatesArray.Add(vUpdateStructure);
						
						// Root array item
						vRoomTypeStruct = New Structure;
						vRoomTypeStruct.Insert("category_id", vRoomType.ID);
						vRoomTypeStruct.Insert("updates", vUpdatesArray);
						
						vRoomTypesArray.Add(vRoomTypeStruct);
					EndDo;
				EndDo;			
			EndDo;
		EndIf;
	EndIf;
	
	Return vJson;
	
EndFunction // GetAvailabilityRequest

// -------------------------------------------------------------------------
//
// Parameters:
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - Interaction parameters
//  pPeriodFrom				 - Date									 - Start date of unloading
//  pPeriodTo				 - Date									 - End date of unloading
//  pFullUpdate				 - Boolean								 - Full update
//  pRoomTypes				 - Array								 - Room types to update
//  pRoomRates				 - Array								 - Room rates to update
// 
// Returns:
//  String - JSON body to HTTP request
//
Function GetRestrictionsRequest(pInteractionParameters, pPeriodFrom, pPeriodTo, 
								pFullUpdate = False, pRoomTypes = Undefined, pRoomRates = Undefined)
	
	vJson = "";
	
	vRoomTypes = InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "roomtypes");
	vRoomRates = InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "roomrates");
	
	// Filter room types
	If pRoomTypes <> Undefined Then
		vClearArray = New Array;
		For Each vRoomTypeRow In vRoomTypes Do
			If pRoomTypes.Find(vRoomTypeRow.RefKey1) = Undefined Then
				vClearArray.Add(vRoomTypeRow);
			EndIf;
		EndDo;
		For Each vRow In vClearArray Do
			vRoomTypes.Delete(vRow);
		EndDo;
	EndIf;
	
	// Filter room rates
	If pRoomRates <> Undefined Then
		vClearArray = New Array;		
		For Each vRoomRatesRow In vRoomRates Do
			If pRoomRates.Find(vRoomRatesRow.RefKey1) = Undefined Then
				vClearArray.Add(vRoomRatesRow);
			EndIf;
		EndDo;	
		For Each vRow In vClearArray Do
			vRoomRates.Delete(vRow);
		EndDo;		
	EndIf;

	// Build JSON
	// Root (mappins between room rates and room types)
	vRRAndRTArray = New Array;
	
	For Each vRoomRate In vRoomRates Do
		vRestrictions 	= ChannelManagers.GetRestrictions(pInteractionParameters, vRoomRate.RefKey1,
														  pPeriodFrom, pPeriodTo, pFullUpdate);
		vRestrictions.Sort("RoomType, Period");
		vRestrictions	= CollapsePeriodTable(vRestrictions);
		
		For Each vRoomType In vRoomTypes Do
			vRoomTypeRestrictions = vRestrictions.FindRows(New Structure("RoomType", vRoomType.RefKey1));
			If vRoomTypeRestrictions.Count() = 0 Then
				vRoomTypeRestrictions = vRestrictions.FindRows(New Structure("RoomType", Catalogs.RoomTypes.EmptyRef()));
			EndIf;
			
			If vRoomTypeRestrictions.Count() > 0 Then
				For Each vRoomTypeRestriction In vRoomTypeRestrictions Do
					// Restrictions
					vRestrictionsStructure = New Structure;
					vRestrictionsStructure.Insert("stop_sale", vRoomTypeRestriction.StopSale);
					vRestrictionsStructure.Insert("disable_checkin", vRoomTypeRestriction.CTA);
					vRestrictionsStructure.Insert("disable_checkout", vRoomTypeRestriction.CTD);
					vRestrictionsStructure.Insert("min_los", ?(vRoomTypeRestriction.MLOS = 0, 1, vRoomTypeRestriction.MLOS));
					vRestrictionsStructure.Insert("max_los", vRoomTypeRestriction.MaxLOS);
					
					// Item array of ranges
					vRangeStructure = New Structure;
					vRangeStructure.Insert("date_start", Format(vRoomTypeRestriction.PeriodFrom, "DF=yyyy-MM-dd"));
					vRangeStructure.Insert("date_end", Format(vRoomTypeRestriction.PeriodTo, "DF=yyyy-MM-dd"));
					vRangeStructure.Insert("restrictions", vRestrictionsStructure);
					
					// Ranges array
					vRangesArray = New Array;
					vRangesArray.Add(vRangeStructure);
					
					// Root array item
					vRoomTypeStruct = New Structure;
					vRoomTypeStruct.Insert("category_id", vRoomType.ID);
					vRoomTypeStruct.Insert("rate_plan_id", vRoomRate.ID);
					vRoomTypeStruct.Insert("ranges", vRangesArray);
					vRRAndRTArray.Add(vRoomTypeStruct);
				EndDo;
			EndIf;
		EndDo;
	EndDo;
	vJson = Catalogs.DataConvertationRules.MapToJSON(vRRAndRTArray);
	
	Return vJson;
	
EndFunction // GetRestrictionsRequest

// -------------------------------------------------------------------------
//
// Parameters:
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - Interaction parameters
//  pPeriodFrom				 - Date									 - Start date of unloading
//  pPeriodTo				 - Date									 - End date of unloading
//  pFullUpdate				 - Boolean								 - Full update
//  pUpdateCachedPrices		 - Boolean								 - Update cached prices
//  pRoomTypes				 - Array								 - Room types to update
//  pRoomRates				 - Array								 - Room rates to update
//  pUsePriceTags			 - Boolean								 - Use price tags
// 
// Returns:
//  String - JSON body to HTTP request
//
Function GetPricesRequest(pInteractionParameters, pPeriodFrom, pPeriodTo, pFullUpdate = False,
						  pUpdateCachedPrices = False,
						  pRoomTypes = Undefined, pRoomRates = Undefined, pUsePriceTags = False)
	
	vJson = "";
	
	vRoomTypes 				= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "roomtypes");
	vRoomRates 				= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "roomrates");
	vBaseByGuestAmt 		= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "BaseByGuestAmt");
	vAdditionalGuestAmount 	= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "AdditionalGuestAmount");
	
	// Filter room types
	If pRoomTypes <> Undefined Then
		vClearArray = New Array;
		For Each  vRoomTypeRow In vRoomTypes Do
			If pRoomTypes.Find(vRoomTypeRow.RefKey1) = Undefined Then
				vClearArray.Add(vRoomTypeRow);
			EndIf;
		EndDo;
		For Each vRow In vClearArray Do
			vRoomTypes.Delete(vRow);
		EndDo;
	EndIf;
	
	// Filter room rates
	If pRoomRates <> Undefined Then
		vClearArray = New Array;		
		For Each vRoomRatesRow In vRoomRates Do
			If pRoomRates.Find(vRoomRatesRow.RefKey1) = Undefined Then
				vClearArray.Add(vRoomRatesRow);
			EndIf;
		EndDo;	
		For Each vRow In vClearArray Do
			vRoomRates.Delete(vRow);
		EndDo;		
	EndIf;

	vDefaultCurrencyCode = pInteractionParameters.Currency.Description; 
	If Not ValueIsFilled(vDefaultCurrencyCode) Then
		vDefaultCurrencyCode = "RUB";
	EndIf;
	
	vAccTemplates = New Array;
	For Each vRow In vBaseByGuestAmt Do
		If vAccTemplates.Find(vRow.RefKey1) = Undefined Then
			vAccTemplates.Add(vRow.RefKey1);	
		EndIf;
	EndDo;
	
	vAccTypes = New Array;
	For Each vRow In vAdditionalGuestAmount Do
		If vAccTypes.Find(vRow.RefKey1) = Undefined Then
			vAccTypes.Add(vRow.RefKey1);	
		EndIf;
	EndDo;

	// Build JSON
	// Root (mappins between room rates and room types)
	vRRAndRTArray = New Array;
	For Each vRoomRate In vRoomRates Do
		If Not vRoomRates.Columns.Find("Unload") = Undefined Then
			If vRoomRate.Unload = False Then
				Continue;
			EndIf;	
		EndIf;
		vPricesByAccTypes 		= ChannelManagers.GetPrices(pInteractionParameters, vRoomRate.RefKey1, pPeriodFrom, pPeriodTo,
															pFullUpdate, pUpdateCachedPrices, , ?(pUsePriceTags, vRoomRate.RefKey2, Undefined));
		vPricesByAccTemplates	= CalculatePricesByAccommodationTemplates(vPricesByAccTypes, vAccTemplates);
		vPricesByAccTemplates.Sort("RoomType, AccommodationTemplate, Currency, Period");
		vPricesByAccTemplates	= CollapsePeriodTable(vPricesByAccTemplates);
		vPricesByAccTemplates.Sort("Period");
		vPricesByAccTypes.Sort("RoomTypeSortCode, AccommodationTypeSortCode, CurrencyCode, Period");
		vPricesByAccTypes		= CollapsePeriodTable(vPricesByAccTypes);
		vPricesByAccTypes		= FilterPricesTableByTypes(vPricesByAccTypes, vAccTypes);
		
		For Each vRoomType In vRoomTypes Do
			vUpdatesArray = New Array;
			
			// By accommodation templates
			vPricesByRoomTypeByAccTmp = vPricesByAccTemplates.FindRows(New Structure("RoomType", vRoomType.RefKey1));

			// By accommodation types
			vPricesByRoomTypeByAccTypes = vPricesByAccTypes.FindRows(New Structure("RoomType", vRoomType.RefKey1));
			
			If vPricesByRoomTypeByAccTmp.Count() = 0 And vPricesByRoomTypeByAccTypes.Count() = 0 Then
				Continue;
			EndIf;
			
			// Root array item
			vRRandRTStruct = New Structure;
			vRRandRTStruct.Insert("category_id", vRoomType.ID);
			vRRandRTStruct.Insert("rate_plan_id", vRoomRate.ID);
			
			vCurPeriodFrom = '00010101';
			vCurPeriodTo = '00010101';
			
			For Each vPrices In vPricesByRoomTypeByAccTmp Do
				If Not ValueIsFilled(vPrices.PeriodFrom) Or Not ValueIsFilled(vPrices.PeriodTo) Then
					Continue;
				EndIf;
				
				// Item array of updates
				If vCurPeriodFrom <> vPrices.PeriodFrom And vCurPeriodTo <> vPrices.PeriodTo Then
					vUpdateStructure = New Structure;
					vUpdateStructure.Insert("date_start", Format(vPrices.PeriodFrom, "DF=yyyy-MM-dd"));
					vUpdateStructure.Insert("date_end", Format(vPrices.PeriodTo, "DF=yyyy-MM-dd"));
					vPricesArray = New Array;
				Else
					vUpdatesArray.Delete(vUpdatesArray.Count() - 1);
				EndIf;
				
				For Each vBaseByGuestAmtRow In vBaseByGuestAmt Do
					If vPrices.AccommodationTemplate = vBaseByGuestAmtRow.RefKey1 Then
						vKind = "MAIN_ADULT";
						// Price
						vPriceStructure = New Structure;
						vPriceStructure.Insert("kind", vKind);
						vPriceStructure.Insert("count", vBaseByGuestAmtRow.GuestAmount);
						vPriceStructure.Insert("age_from", 0);
						vPriceStructure.Insert("age_to", 0);
						vPriceStructure.Insert("amount", vPrices.Price);
						vPricesArray.Add(vPriceStructure);	
					EndIf;
				EndDo;
				If vBaseByGuestAmt.Count() > 0 And vPricesArray.Count() > 0 Then
					vUpdateStructure.Insert("placement_rates", vPricesArray);
				EndIf;
				If vPricesByRoomTypeByAccTmp.Count() > 0 And vUpdateStructure.Count() > 2 Then
					vUpdatesArray.Add(vUpdateStructure);
					vCurPeriodFrom = vPrices.PeriodFrom;
					vCurPeriodTo = vPrices.PeriodTo;
				EndIf;
			EndDo;
			
			For Each vPrices In vPricesByRoomTypeByAccTypes Do
				If Not ValueIsFilled(vPrices.PeriodFrom) Or Not ValueIsFilled(vPrices.PeriodTo) Then
					Continue;
				EndIf;
		
				// Item array of updates
				vUpdateStructure = New Structure;
				vUpdateStructure.Insert("date_start", Format(vPrices.PeriodFrom, "DF=yyyy-MM-dd"));
				vUpdateStructure.Insert("date_end", Format(vPrices.PeriodTo, "DF=yyyy-MM-dd"));
				vPricesArray = New Array;
				
				For Each vAdditionalGuestAmountRow In vAdditionalGuestAmount Do
					If vAdditionalGuestAmountRow.isBaseBedAmount = True Then						
						If vPrices.AccommodationType = vAdditionalGuestAmountRow.RefKey1 Then							
							If vAdditionalGuestAmountRow.MinAge > 0 Or vAdditionalGuestAmountRow.MaxAge > 0 Then 
								vKind = "MAIN_CHILD";
								vMinAge = vAdditionalGuestAmountRow.MinAge;
								vMaxAge = vAdditionalGuestAmountRow.MaxAge;
							Else
								vKind = "MAIN_ADULT";
								vMinAge = 0;
								vMaxAge = 0;
							EndIf;
							
							// Price
							vPriceStructure = New Structure;
							vPriceStructure.Insert("kind", vKind);
							vPriceStructure.Insert("count", vAdditionalGuestAmountRow.MaxAdditionalGuests); // ?
							vPriceStructure.Insert("age_from", vMinAge);
							vPriceStructure.Insert("age_to", vMaxAge);
							vPriceStructure.Insert("amount", vPrices.Price);
							vPricesArray.Add(vPriceStructure);
						EndIf;
					EndIf;
				EndDo;	
				
				For Each vAdditionalGuestAmountRow In vAdditionalGuestAmount Do
					If vAdditionalGuestAmountRow.isBaseBedAmount = False Then
						If vPrices.AccommodationType = vAdditionalGuestAmountRow.RefKey1 Then
							If vAdditionalGuestAmountRow.MinAge > 0 Or vAdditionalGuestAmountRow.MaxAge > 0 Then 
								vKind = "ADDITIONAL_CHILD";
								vMinAge = vAdditionalGuestAmountRow.MinAge;
								vMaxAge = vAdditionalGuestAmountRow.MaxAge;
							Else
								vKind = "ADDITIONAL_ADULT";
								vMinAge = 0;
								vMaxAge = 0;
							EndIf;
							
							// Prices
							vPriceStructure = New Structure;
							vPriceStructure.Insert("kind", vKind);
							vPriceStructure.Insert("count", vAdditionalGuestAmountRow.MaxAdditionalGuests);
							vPriceStructure.Insert("age_from", vMinAge);
							vPriceStructure.Insert("age_to", vMaxAge);
							vPriceStructure.Insert("amount", vPrices.Price);
							vPricesArray.Add(vPriceStructure);
						EndIf;
					EndIf;
				EndDo;
				If vAdditionalGuestAmount.Count() > 0 And vPricesArray.Count() > 0 Then
					vUpdateStructure.Insert("placement_rates", vPricesArray);
				EndIf;
				If vUpdateStructure.Count() > 2 Then
					vUpdatesArray.Add(vUpdateStructure);
				EndIf;
			EndDo;
			If vUpdatesArray.Count() > 0 Then
				vRRandRTStruct.Insert("updates", vUpdatesArray);
				vRRAndRTArray.Add(vRRandRTStruct);
			EndIf;
		EndDo;
	EndDo;
	
	vJson = Catalogs.DataConvertationRules.MapToJSON(vRRAndRTArray);
	
	Return vJson;
	
EndFunction // GetPricesRequest

#EndRegion

// -------------------------------------------------------------------------
//
// Parameters:
//  pTable				 - ValueTable	 - Table to collapse
//  pPeriodColumnName	 - String		 - Period column name
// 
// Returns:
//  ValueTable - Collapsed table
//
Function CollapsePeriodTable(pTable, pPeriodColumnName = "Period")
	
	pTable.Columns.Add("PeriodFrom");	
	pTable.Columns.Add("PeriodTo");
	
	vInd = 0;
	While vInd < pTable.Count() Do
		If Not ValueIsFilled(pTable[vInd].PeriodFrom) Then
			pTable[vInd].PeriodFrom = pTable[vInd][pPeriodColumnName];
			pTable[vInd].PeriodTo = pTable[vInd][pPeriodColumnName];
		EndIf;
	vInd = vInd + 1;
	EndDo;
	vInd = 0;
	While vInd + 1 < pTable.Count() Do
		vOneDay = 24 * 60 * 60; 
		If BegOfDay(pTable[vInd].PeriodTo) + vOneDay = BegOfDay(pTable[vInd + 1][pPeriodColumnName]) Then
			vCollapse = True;
			For Each vColumn In pTable.Columns Do
				If vColumn.Name <> pPeriodColumnName And vColumn.Name <> "PeriodFrom" And vColumn.Name <> "PeriodTo" Then
					If pTable[vInd][vColumn.Name] <> pTable[vInd + 1][vColumn.Name] Then
						vCollapse = False;
						Break;
					EndIf;
				EndIf;
			EndDo;
			If vCollapse Then			
				pTable[vInd].PeriodTo = pTable[vInd + 1][pPeriodColumnName];
				pTable.Delete(pTable[vInd + 1]);
				vInd = vInd - 1;
			EndIf;
		EndIf;
		vInd = vInd + 1;
	EndDo;
	
	Return pTable;
	
EndFunction // CollapsePeriodTable

// -------------------------------------------------------------------------
//
// Parameters:
//  pPricesTable			 - ValueTable	 - Prices table
//  pAccommodationTemplates	 - Array		 - Accommodation templates
// 
// Returns:
//  ValueTable - Calculated prices
//
Function CalculatePricesByAccommodationTemplates(pPricesTable, pAccommodationTemplates)
	
	vResult = New ValueTable;
	vResult.Columns.Add("AccommodationTemplate");
	vResult.Columns.Add("Period");
	vResult.Columns.Add("Price");
	vResult.Columns.Add("RoomType");
	vResult.Columns.Add("Currency");

	vResult.Indexes.Add("RoomType, AccommodationTemplate, Currency, Period");
	
	For Each vAccTemplate In pAccommodationTemplates Do
		For Each vPrices In pPricesTable Do       
			vAccTempIsFind = False;
			If vAccTemplate.RoomTypes.Count() > 0 Then
				If vAccTemplate.RoomTypes.FindRows(New Structure("RoomType", vPrices.RoomType)).Count() > 0 And Not ValueIsFilled(vPrices.RoomType.RoomClass) Then
					vAccTempIsFind = True;  
				ElsIf ValueIsFilled(vPrices.RoomType.RoomClass) And vAccTemplate.RoomTypes.FindRows(New Structure("RoomClass", vPrices.RoomType.RoomClass)).Count() > 0 Then 
					vAccTempIsFind = True;  
				ElsIf vAccTemplate.RoomTypes.FindRows(New Structure("RoomType", vPrices.RoomType)).Count() > 0 Then
					vAccTempIsFind = True;
				EndIf;    
				If vAccTempIsFind = False Then
					Continue;
				EndIf;	
			EndIf;
			vResultRows = vResult.FindRows(New Structure("RoomType, AccommodationTemplate, Currency, Period", vPrices.RoomType, vAccTemplate, vPrices.Currency, vPrices.Period));
			If vResultRows.Count() = 0 Then
				vNewRow 						= vResult.Add();
				vNewRow.AccommodationTemplate 	= vAccTemplate;
				vNewRow.Period 					= vPrices.Period;
				vNewRow.RoomType 				= vPrices.RoomType;
				vNewRow.Currency 				= vPrices.Currency;
				vNewRow.Price					= 0;
				For Each vAccType In vAccTemplate.AccommodationTypes Do
					vPricesRows = pPricesTable.FindRows(New Structure("Period, RoomType, AccommodationType, Currency", vPrices.Period, vPrices.RoomType, vAccType.AccommodationType, vPrices.Currency));
					For Each vPriceRow In vPricesRows Do
						vNewRow.Price = vNewRow.Price + vPriceRow.Price; 
					EndDo;
				EndDo;
			EndIf;
		EndDo;	
	EndDo;
	
	Return vResult;
	
EndFunction // CalculatePricesByAccommodationTemplates

// -------------------------------------------------------------------------
//
// Parameters:
//  pPricesTable		 - ValueTable	 - Prices table
//  pAccommodationTypes	 - Array		 - Accommodation types
// 
// Returns:
//  ValueTable - Filtered prices table
//
Function FilterPricesTableByTypes(pPricesTable, pAccommodationTypes)
	
	vRowsArray = New Array;
	For Each vRow In pPricesTable Do
		For Each vAccType In pAccommodationTypes Do
			If vRow.AccommodationType = vAccType Then
				vRowsArray.Add(vRow);
				Break;
			EndIf;
		EndDo;
	EndDo;
	
	vResult = pPricesTable.Copy(vRowsArray);
	
	Return vResult;
	
EndFunction // FilterPricesTableByTypes

//  -------------------------------------------------------------------------
//
// Parameters:
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - Interaction parameters
//  pPaymentMethodCode		 - String								 - Payment method code
// 
// Returns:
//  CatalogRef.PaymentMethods - Found or created payment method
//
Function GetPaymentMethod(pInteractionParameters, pPaymentMethodCode)
	
	vExtPM = Undefined;
	vPaymentMethod 	= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "paymentMethods", "id", , , pPaymentMethodCode);
	If vPaymentMethod <> Undefined And vPaymentMethod.Count() > 0 Then 
		vExtPM = vPaymentMethod[0].RefKey1;
	Else  
		vExtPM = Catalogs.PaymentMethods.FindByAttribute("ExternalCode", TrimAll(pPaymentMethodCode));  
		If Not ValueIsFilled(vExtPM) Then   
			Try
				// Try to create new payment method
				vExtPM_Obj = Catalogs.PaymentMethods.CreateItem();
				vExtPM_Obj.Code = InformationRegisters.ClientVerificationCodes.GenerateRandomCode(5); 
				vExtPM_Obj.Description = "Bronirui Online" + " " + pPaymentMethodCode; 
				vExtPM_Obj.ExternalCode = TrimAll(pPaymentMethodCode);    
				vExtPM_Obj.Write();     
				vExtPM = vExtPM_Obj.Ref;
			Except
				vError = "Failed to create new payment method by id: " + pPaymentMethodCode + Chars.LF + ErrorDescription();
				vLogEventType = Enums.ExternalSystemEventTypes.Warning;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation.GetPaymentDetails", vLogEventType, , , vError);
			EndTry;
		EndIf;
	EndIf;
	
	Return vExtPM;
	
EndFunction // GetPaymentMethod

#EndRegion