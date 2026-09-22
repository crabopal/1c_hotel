#Region CommonFunction

// -------------------------------------------------------------------------
//
// Parameters:
//  pExtSysParams	 - CatalogRef.ExternalSystemInteractions	 - Catalog ref
// 
// Returns:
//  String - Version
//
Function Version(pExtSysParams = Undefined) Export
	vVersion = "1.16";
	If pExtSysParams = Undefined Then
		Return vVersion;
	EndIf;	
	vVersions = InformationRegisters.ExternalSystemIntegrationData.GetData(pExtSysParams, "Version");
	If vVersions.Count() > 0 Then
		If ValueIsFilled(vVersions[0].RefKey1) Then
			vVersion = vVersions[0].RefKey1;
		EndIf;
	EndIf; 
	Return vVersion;
EndFunction

#EndRegion

#Region API

// -------------------------------------------------------------------------
Procedure SyncData(pInteractionParameters, pHotelCode, pAmountOfDaysToUpdate = 100, pSkipPricesCacheUpdate = True, pFullUpdate = False, pLoadReservations, pUpdateAvailability, pUpdatePrices, pGetPrices, pUsePriceTags = False, pGetVacantRoomsAtMidnight = False, pReceiveBonuses = False) Export
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
		If pLoadReservations Then
			If vExternalInteractionObj.IsLocked() Then
				vExternalInteractionObj.Read();
				vExternalInteractionObj.Status = Enums.IntegrationStatuses.Warning;
				vExternalInteractionObj.ErrorDescription = NStr("en = 'Bookings are being loaded...'; de = 'Buchungen werden heruntergeladen...'; ru = 'Загружаются бронирования...'");
				vExternalInteractionObj.Write();
			EndIf;

			vReservationsResult = GetReservations(pInteractionParameters, pHotelCode, , , , , pGetPrices, , pReceiveBonuses);
		EndIf;
		
		If pUpdateAvailability Then   
			// Export availability
			If vExternalInteractionObj.IsLocked() Then
				vExternalInteractionObj.Read();
				vExternalInteractionObj.Status = Enums.IntegrationStatuses.Warning;
				vExternalInteractionObj.ErrorDescription = NStr("en = 'The remaining available rooms are being unloaded...'; de = 'Reste von freien Zimmern werden ausgelagert...'; ru = 'Выгружаются остатки свободных номеров...'");
				vExternalInteractionObj.Write();
			EndIf;

			SendAvailability(pInteractionParameters, pHotelCode, , , pAmountOfDaysToUpdate, pFullUpdate, , , , , pGetVacantRoomsAtMidnight);
			If vReservationsResult.AvailabilityUpdateDates <> Undefined And vReservationsResult.AvailabilityUpdateDates.PeriodFrom <> Undefined Then
				SendAvailability(pInteractionParameters, pHotelCode, , , , False, , vReservationsResult.AvailabilityUpdateDates.PeriodFrom, vReservationsResult.AvailabilityUpdateDates.PeriodTo, , pGetVacantRoomsAtMidnight);
			EndIf;
			
			// Export restrictions
			If vExternalInteractionObj.IsLocked() Then
				vExternalInteractionObj.Read();
				vExternalInteractionObj.Status = Enums.IntegrationStatuses.Warning;
				vExternalInteractionObj.ErrorDescription = NStr("en = 'Restrictions are being uploaded...'; de = 'Einschränkungen werden entladen...'; ru = 'Выгружаются ограничения...'");
				vExternalInteractionObj.Write();

				SendRestrictions(pInteractionParameters, pHotelCode, , , pAmountOfDaysToUpdate, pFullUpdate);
			EndIf;
		EndIf;
		
		If pUpdatePrices Then
			// Update interaction info
			If vExternalInteractionObj.IsLocked() Then
				vExternalInteractionObj.Read();
				vExternalInteractionObj.Status = Enums.IntegrationStatuses.Warning;
				vExternalInteractionObj.ErrorDescription = NStr("en = 'Prices are being uploaded...'; de = 'Die Preise werden ausgelagert...'; ru = 'Выгружаются цены...'");
				vExternalInteractionObj.Write();     

				SendPrices(pInteractionParameters, pHotelCode, , , pAmountOfDaysToUpdate, pFullUpdate, vUpdateCachedPrices, , , , , , pUsePriceTags);
			EndIf;
		EndIf; 

		// Update interaction parameters
		If vExternalInteractionObj.IsLocked() Then
			vLastSyncTimeUpdateError = ChannelManagers.UpdateLastSyncTime(vExternalInteractionObj, pFullUpdate, vCurrentSessionDate, "", pUpdateAvailability, pUpdatePrices, pUpdateAvailability);
			If Not IsBlankString(vLastSyncTimeUpdateError) Then
				Raise vLastSyncTimeUpdateError;
			EndIf;
		EndIf;
	Except
		vErrorText = cmGetRootErrorDescription(ErrorInfo());
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SyncData", Enums.ExternalSystemEventTypes.Error, , , vErrorText);
	EndTry;
	
	// Unlock interaction
	If vExternalInteractionObj.IsLocked() Then
		vExternalInteractionObj.Unlock();
	EndIf;
EndProcedure // SyncData

// -------------------------------------------------------------------------
Function LoadReservations(pInteractionParameters, pReservationsMap, pGetPrices, pReceiveBonuses = False) Export
	
	vResult 					= New Structure("Success, Error, LoadedReservationsArray, AvailabilityUpdateDates", True, "", New Array, Undefined);
	vAvailabilityUpdatePeriod 	= New Structure("PeriodFrom, PeriodTo", Undefined, Undefined);
	
	vDefaultAllotmentCode	= Undefined;
	vDefaultAllotments 		= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "DefaultAllotment");
	If vDefaultAllotments.Count() > 0 Then
		vDefaultAllotmentCode = vDefaultAllotments[0].RefKey1.Code; 	
	EndIf;
	
	vSourceOfBusiness = Undefined;
	vSourceOfBusinessCode = Undefined;
	vSourcesOfBusiness 	= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "SourceOfBusiness");
	If vSourcesOfBusiness.Count() > 0 Then
		vSourceOfBusiness = vSourcesOfBusiness[0].RefKey1; 
		vSourceOfBusinessCode = vSourceOfBusiness.Code; 
	EndIf;
	
	vMarketingCode		= Undefined;
	vMarketingCodeCode	= Undefined;
	vMarketingCodes 	= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "MarketingCode");	
	If vMarketingCodes.Count() > 0 Then
		vMarketingCode = vMarketingCodes[0].RefKey1; 
		vMarketingCodeCode = vMarketingCode.Code; 
	EndIf;
	
	vHotel = pInteractionParameters.Hotel;
	
	vReservationMapsArray = PropertyToArray(pReservationsMap.Get("HotelReservation"));
	For Each vReservationMap In vReservationMapsArray Do
		
		vExternalGroupReservation = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalGroupReservation"));
		
		vSuccess				= True;
		vReservationID			= "";
		vExternalID				= "";
		vReservationStatusID 	= "";
		vAgentID				= "";
		vComment				= "";
		vAgent					= Undefined;
		vRoomRate				= Catalogs.RoomRates.EmptyRef();
		
		vReservationIDs = PropertyToArray(vReservationMap.Get("UniqueID"));
		For Each vReservationIDRow In vReservationIDs Do
			vID_Context = vReservationIDRow.Get("ID_Context");
			If Not ValueIsFilled(vID_Context) Or vID_Context = "TL" Then
				vReservationID = vReservationIDRow.Get("ID");
			ElsIf vID_Context = "External" Then
				vExternalID = vReservationIDRow.Get("ID");
			EndIf;
		EndDo;	
		vReservationID	= Format(vReservationID, "NDS=; NGS=; NZ=0; NG=");
		
		If Not ValueIsFilled(vReservationID) Then
			vResult.Success = False;
			vResult.Error	= "Critical error! Failed to get Booking №!";
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation", vLogEventType, , , vResult.Error);
			Continue;
		EndIf;  
		
		// Check status
		vGuestGroup = cmGetGuestGroupByExternalCode(vHotel, vReservationID, "", "", False); 
		If ValueIsFilled(vGuestGroup) Then  
			vStatus = vGuestGroup.Status;
			If TypeOf(vStatus) = Type("CatalogRef.ReservationStatuses") 
				And vStatus.IsCheckIn Or TypeOf(vStatus) = Type("CatalogRef.AccommodationStatuses") Then
				
				vResult.Success = False;
				vResult.Error	= "Critical error! Reservation is CheckIn";
				vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation", vLogEventType, , , vResult.Error);
				
				Continue;
			EndIf;	
		EndIf;	    
		
		vReservationStatusID 	= vReservationMap.Get("ResStatus");
		vLastModifyDateTime 	= vReservationMap.Get("LastModifyDateTime");
		
		vPathArray	= New Array;
		vPathArray.Add("POS");
		vPathArray.Add("Source");
		vPathArray.Add("BookingChannel");	
		vPathArray.Add("CompanyName");
		vPathArray.Add("Code");
		vAgentID = Catalogs.DataConvertationRules.GetMapValueByArrayPath(vReservationMap, vPathArray);
		
		If Not ValueIsFilled(vAgentID) Then		
			vPathArray	= New Array;
			vPathArray.Add("POS");
			vPathArray.Add("Source");
			vPathArray.Add("BookingChannel");	
			vPathArray.Add("TPA_Extensions");
			vPathArray.Add("BookingWebSource");
			vBookingWebSource = Catalogs.DataConvertationRules.GetMapValueByArrayPath(vReservationMap, vPathArray);
			If vBookingWebSource <> Undefined Then 
				vAgentID = "TRAVELLINE";
			EndIf;
		EndIf;
		
		vPathArray	= New Array;
		vPathArray.Add("POS");
		vPathArray.Add("Source");
		vPathArray.Add("BookingChannel");	
		vPathArray.Add("TPA_Extensions");
		vPathArray.Add("BookingWebSource");
		vPathArray.Add("Url");
		vBookingUrl 	= Catalogs.DataConvertationRules.GetMapValueByArrayPath(vReservationMap, vPathArray);
		If ValueIsFilled(vBookingUrl) Then
			vUTMStructure 			= GetUTMStructureFromURL(vBookingUrl);
			vRequestAttributesXDTO 	= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "RequestAttributes"));
			vRequestAttributesXDTO.utm_source 	= vUTMStructure.utm_source;
			vRequestAttributesXDTO.utm_medium 	= vUTMStructure.utm_medium;
			vRequestAttributesXDTO.utm_campaign = vUTMStructure.utm_campaign;
		EndIf;
		vExternalGroupReservation.RequestAttributes = vRequestAttributesXDTO;
		vResGuests 			= vReservationMap.Get("ResGuests");
		vGuestsDataTable	= GetGuestTable(vResGuests);
		
		vGlobalInfoMap		= vReservationMap.Get("ResGlobalInfo");
		
		vPayment			= GetPaymentDetails(pInteractionParameters, vGlobalInfoMap);
		
		vCommentsMap		= vGlobalInfoMap.Get("Comments");
		vComment			= GetReservationComment(vCommentsMap);
		
		vPathArray	= New Array;
		vPathArray.Add("Profiles");
		vPathArray.Add("ProfileInfo");
		vPathArray.Add("Profile");	
		vPathArray.Add("Customer");
		vCustomerMap = Catalogs.DataConvertationRules.GetMapValueByArrayPath(vGlobalInfoMap, vPathArray);
		
		// Get customer data
		vCustomerData				= GetCustomerData(vCustomerMap);
		vMainGuest 					= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
		vMainGuest.ClientFirstName 	= vCustomerData.FirstName;
		vMainGuest.ClientSecondName = vCustomerData.SecondName;
		vMainGuest.ClientLastName 	= vCustomerData.LastName;
		vMainGuest.ClientPhone 		= vCustomerData.Phone;
		vMainGuest.ClientEMail 		= vCustomerData.Email;
		
		vWriteContactsToTheFirstGuest = True;
		For Each vGuestRow In vGuestsDataTable Do
			If vGuestRow.LastName = vCustomerData.LastName 
				And vGuestRow.SecondName = vCustomerData.SecondName And vGuestRow.FirstName = vCustomerData.FirstName Then
				vWriteContactsToTheFirstGuest = False;
				Break;
			EndIf;
		EndDo;
		
		// Get reservation status
		vReservationStatus		= Undefined;
		vReservationStatuses 	= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "reservationstatuses", "ID",,, vReservationStatusID);	
		If vReservationStatuses = Undefined Or vReservationStatuses.Count() = 0 Then
			vResult.Success = False;
			vResult.Error	= "Failed to find reservation status by ID:" + vReservationStatusID + "; Booking №:" + vReservationID;
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation", vLogEventType, , , vResult.Error);
			Continue;
		Else
			vReservationStatus = vReservationStatuses[0].RefKey1;
		EndIf;
		
		If vReservationStatus.IsActive Or vReservationStatus.IsPreliminary Then
			If ValueIsFilled(vAgentID) Then
				vAgentsData = InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "sources",,,, vAgentID);
				If vAgentsData.Count() = 0 Then
					vResult.Error	= "Failed to find agents data by ID:" + vAgentID;
					vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservations", vLogEventType, , , vResult.Error);
				Else
					vAgent = vAgentsData[0].RefKey1; 
				EndIf;
			Else
				vResult.Error	= "Failed to get agent ID from booking:" + vReservationID;
				vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservations", vLogEventType, , , vResult.Error);
			EndIf;
			
			vServices	= GetServicesTable(pInteractionParameters, vReservationMap.Get("Services"));
			vRoomStays 	= vReservationMap.Get("RoomStays");
			If vRoomStays <> Undefined Then
				vRoomStayArray = PropertyToArray(vRoomStays.Get("RoomStay"));
				For Each vRoomStay In vRoomStayArray Do
					If vRoomStay <> Undefined Then
						
						vGuestGroupCode = vReservationID + "/" + vRoomStay.Get("IndexNumber");
						vRoomUUID		= String(New UUID);
						
						vPathArray	= New Array;
						vPathArray.Add("RoomTypes");
						vPathArray.Add("RoomType");
						vPathArray.Add("RoomTypeCode");
						vRoomTypeID = Catalogs.DataConvertationRules.GetMapValueByArrayPath(vRoomStay, vPathArray);
						
						// Get reservation status
						vRoomType	= Undefined;
						vRoomTypes 	= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "roomtypes", "ID",,, vRoomTypeID);	
						If vRoomTypes = Undefined Or vRoomTypes.Count() = 0 Then
							vResult.Success = False;
							vResult.Error	= "Failed to find room type by ID:" + vRoomTypeID + "; Booking №:" + vReservationID;
							vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
							InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation", vLogEventType, , , vResult.Error);
							vSuccess = False;
							Break;
						Else
							vRoomType = vRoomTypes[0].RefKey1;
						EndIf;
						
						vAllotmentCode	= Undefined;
						
						vPathArray	= New Array;
						vPathArray.Add("RoomTypes");
						vPathArray.Add("RoomType");
						vPathArray.Add("InvBlockCode");
						vInvBlockCode = Catalogs.DataConvertationRules.GetMapValueByArrayPath(vRoomStay, vPathArray);
						
						If ValueIsFilled(vInvBlockCode) Then
							vAllotments 	= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "allotments", "ID",,, vInvBlockCode);	
							If Not (vAllotments = Undefined Or vAllotments.Count() = 0) Then
								vAllotmentCode = vAllotments[0].RefKey1.Code;
							EndIf;
						Else
							vAllotmentCode = vDefaultAllotmentCode;
						EndIf;
						
						vTimeSpan	= vRoomStay.Get("TimeSpan");
						vStart		= vTimeSpan.Get("Start");
						vEnd		= vTimeSpan.Get("End");
						vStart		= StrReplace(vStart,"T","");
						vEnd		= StrReplace(vEnd,"T","");
						vStart		= StrReplace(vStart,"-","");
						vEnd		= StrReplace(vEnd,"-","");
						vStart		= StrReplace(vStart,":","");
						vEnd		= StrReplace(vEnd,":","");
						vPeriodFrom = Date(vStart);
						vPeriodTo 	= Date(vEnd);
						
						If vAvailabilityUpdatePeriod.PeriodFrom = Undefined Or vAvailabilityUpdatePeriod.PeriodFrom > vPeriodFrom Then
							vAvailabilityUpdatePeriod.PeriodFrom = vPeriodFrom;	
						EndIf;
						
						If vAvailabilityUpdatePeriod.PeriodTo = Undefined Or vAvailabilityUpdatePeriod.PeriodTo < vPeriodTo Then
							vAvailabilityUpdatePeriod.PeriodTo = vPeriodTo;	
						EndIf;

						
						vGuestCountsMap = vRoomStay.Get("GuestCounts");
						vGuestCountArray = PropertyToArray(vGuestCountsMap.Get("GuestCount"));
						vGuestPrices = GetPricesXDTO(pInteractionParameters, vRoomStay.Get("RoomRates"));		

						// Get basic room rate
						If Not ValueIsFilled(vRoomRate) Then
							vRoomRateID	= Undefined;

							i = 1;
							For Each vGuest In vGuestCountArray Do
								vGuestsNumber = Number(vGuest.Get("Count"));
								vResGuestRPH = vGuest.Get("ResGuestRPH");
								
								For j = 1 To vGuestsNumber Do 
									If vResGuestRPH <> Undefined Then 
										vPricesRow = vGuestPrices.Find(vResGuestRPH, "ResGuestRPH");
									Else
										vPricesRow = Undefined;
									EndIf;
									
									If vPricesRow = Undefined Then
										vPricesRow = vGuestPrices.Find(Undefined, "ResGuestRPH");
										If vPricesRow <> Undefined Then
											vRoomRateID	= vPricesRow.RatePlanCode;
										EndIf;
									Else
										vRoomRateID	= vPricesRow.RatePlanCode;
									EndIf;
									
									If vRoomRateID <> Undefined Then
										vRoomRates = InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "roomrates", , , , vRoomRateID);
										If vRoomRates.Count() > 0 Then
											vRoomRate = vRoomRates[0].RefKey1;
										EndIf;
										If ValueIsFilled(vRoomRate) Then
											Break;
										EndIf;
									EndIf;

									i = i + 1;
								EndDo;
								If ValueIsFilled(vRoomRate) Then
									Break;
								EndIf;
							EndDo;
						EndIf;
						
						// Children ages
						vChildrenAgesStruct = Undefined;
						If ValueIsFilled(vRoomType) Then
							vHotel = vRoomType.Owner;
							vChildrenAgesStruct = vHotel;
						EndIf;
						// Try to override children ages from the contract
						If ValueIsFilled(vAgent) And ValueIsFilled(vAgent.Contract) Then
							vAgentContract = vAgent.Contract;
							If ValueIsFilled(vAgentContract) Then
								If vAgentContract.TeenagersMaxAge <> 0 Or vAgentContract.ChildrenMaxAge <> 0 Or vAgentContract.InfantsMaxAge <> 0 Then
									vChildrenAgesStruct = vAgentContract;
								EndIf;
							EndIf;
						EndIf;
						// Try to override children ages from the special offer
						If ValueIsFilled(vHotel) And ValueIsFilled(vRoomRate) Then
							vOffers = cmGetConfirmedSpecialOffersForReservation(Undefined, vHotel, vRoomRate, vRoomRate.RoomRateType, Undefined, Undefined, vAgent, ?(ValueIsFilled(vAgent), vAgent.CustomerType, Undefined), Undefined, vSourceOfBusiness, vMarketingCode, Undefined, vPeriodFrom, cmCalculateDuration(vRoomRate, vPeriodFrom, vPeriodTo), vPeriodTo, CurrentSessionDate(), vRoomType);
							For Each vOffersRow In vOffers Do
								vOffer = vOffersRow.SpecialOffer;
								If vOffer.TeenagersMaxAge <> 0 Or vOffer.ChildrenMaxAge <> 0 Or vOffer.InfantsMaxAge <> 0 Then
									vChildrenAgesStruct = vOffer;
									Break;
								EndIf;
							EndDo;
						EndIf;
						
						// Search template by ages
						vGuestCount = GetGuestCount(pInteractionParameters, vGuestCountsMap, vChildrenAgesStruct);
						vAccomodationTemplateList = cmGetAccommodationTemplateDetailsByGuestsQuantity(vGuestCount.Adults, vGuestCount.Childs + vGuestCount.Infants + vGuestCount.Teenagers, vGuestCount.Ages, pInteractionParameters.Hotel, , vChildrenAgesStruct);
						// Filter Templates by roomType
						vClearArray = New Array;
						For Each vTemplateRow In vAccomodationTemplateList Do
							If vTemplateRow.AccommodationTemplate.RoomTypes.Count() > 0 Then
								If vTemplateRow.AccommodationTemplate.RoomTypes.Find(vRoomType, "RoomType") = Undefined Then
									If ValueIsFilled(vRoomType) 
										And vRoomType.IsFolder = False 
										And ValueIsFilled(vRoomType.RoomClass) 
										And vTemplateRow.AccommodationTemplate.RoomTypes.Find(vRoomType.RoomClass, "RoomClass") <> Undefined Then
										
										Continue;
									Else
										vClearArray.Add(vTemplateRow);
									EndIf;
								EndIf;
							EndIf;
						EndDo;
						
						For Each vClearRow In vClearArray Do
							vAccomodationTemplateList.Delete(vClearRow);
						EndDo;
						If vAccomodationTemplateList = Undefined Or vAccomodationTemplateList.Count() = 0 Then
							// Try to find an accommodation template for any number of guests 
							// Step 1. Without children
							vAccomodationTemplateList = cmGetAllAccommodationTemplates(pInteractionParameters.Hotel);
							i = 0;
							While i < vAccomodationTemplateList.Count() Do
								vAccTemplatesRow = vAccomodationTemplateList.Get(i);
								vAccTemplateRef = vAccTemplatesRow.AccommodationTemplate;
								If vGuestCount.Adults <> vAccTemplateRef.NumberOfAdults Then
									vAccomodationTemplateList.Delete(i);
									Continue;
								EndIf;
								i = i + 1;
							EndDo;
							// Filter templates by roomType
							vClearArray = New Array;
							For Each vTemplateRow In vAccomodationTemplateList Do
								If vTemplateRow.AccommodationTemplate.RoomTypes.Count() > 0 Then
									If vTemplateRow.AccommodationTemplate.RoomTypes.Find(vRoomType, "RoomType") = Undefined Then
										If ValueIsFilled(vRoomType) 
											And vRoomType.IsFolder = False 
											And ValueIsFilled(vRoomType.RoomClass) 
											And vTemplateRow.AccommodationTemplate.RoomTypes.Find(vRoomType.RoomClass, "RoomClass") <> Undefined Then
											
											Continue;
										Else
											vClearArray.Add(vTemplateRow);
										EndIf;
									EndIf;
								EndIf;
							EndDo;
							For Each vClearRow In vClearArray Do
								vAccomodationTemplateList.Delete(vClearRow);
							EndDo;
							
							// Step 2. Adults -1
							If vAccomodationTemplateList = Undefined or vAccomodationTemplateList.Count() = 0 And vGuestCount.Adults > 1 Then
								vAccomodationTemplateList = cmGetAllAccommodationTemplates(pInteractionParameters.Hotel);
								i = 0;
								vAdultsQt = vGuestCount.Adults - 1;
								While i < vAccomodationTemplateList.Count() Do
									vAccTemplatesRow = vAccomodationTemplateList.Get(i);
									vAccTemplateRef = vAccTemplatesRow.AccommodationTemplate;
									If vAdultsQt <> vAccTemplateRef.NumberOfAdults Then
										vAccomodationTemplateList.Delete(i);
										Continue;
									EndIf;
									i = i + 1;
								EndDo;
								// Filter Templates by roomType
								vClearArray = New Array;
								For Each vTemplateRow In vAccomodationTemplateList Do
									If vTemplateRow.AccommodationTemplate.RoomTypes.Count() > 0 Then
										If vTemplateRow.AccommodationTemplate.RoomTypes.Find(vRoomType, "RoomType") = Undefined Then
											If ValueIsFilled(vRoomType) 
												And vRoomType.IsFolder = False
												And ValueIsFilled(vRoomType.RoomClass) 
												And vTemplateRow.AccommodationTemplate.RoomTypes.Find(vRoomType.RoomClass, "RoomClass") <> Undefined Then
												
												Continue;
											Else
												vClearArray.Add(vTemplateRow);
											EndIf;
										EndIf;
									EndIf;
								EndDo;
								For Each vClearRow In vClearArray Do
									vAccomodationTemplateList.Delete(vClearRow);
								EndDo;
							EndIf;	
						EndIf;	
						
						// Get default template
						vAccommodationTemplate 		= Undefined;
						If vAccomodationTemplateList = Undefined or vAccomodationTemplateList.Count() = 0 Then
							vAgesAsString = "";
							For Each vAgeVal In vGuestCount.Ages Do
								vAgesAsString = vAgesAsString + ?(IsBlankString(vAgesAsString), "", ", ") + vAgeVal;
							EndDo;
							vResult.Success = False;
							vResult.Error	= "Failed to find accommodation template! " + "Adults: " + vGuestCount.Adults + ", Children: " + (vGuestCount.Childs + vGuestCount.Infants + vGuestCount.Teenagers) + ", Ages: " + vAgesAsString + "; Booking №: " + vGuestGroupCode;
							vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
							InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation", vLogEventType, , , vResult.Error);
							vSuccess = False;
							Break;		
						EndIf;
						
						vAccommodationTemplate 	= vAccomodationTemplateList[0].AccommodationTemplate;	
						vAccomodationTypes		= vAccommodationTemplate.AccommodationTypes;
						If vAccomodationTypes.Count() = 0 Then
							vResult.Success = False;
							vResult.Error	= "Empty accomodation types in template! " + vAccommodationTemplate + "; Booking №:" + vGuestGroupCode;
							vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
							InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservations", vLogEventType, , , vResult.Error);
							vSuccess = False;
							Break;
						EndIf;
						
						If vGuestCountArray.Count() > vAccomodationTypes.Count() Then
							vResult.Success = False;
							vResult.Error	= "More guests than accommodation types in template! " + vAccommodationTemplate + "; Booking №:" + vGuestGroupCode;
							vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
							InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservations", vLogEventType, , , vResult.Error);
							vSuccess = False;
							Break;
						EndIf;
						
						vGuestPrices 		= GetPricesXDTO(pInteractionParameters, vRoomStay.Get("RoomRates"));		
						vServiceRPHs		= vRoomStay.Get("ServiceRPHs");
						vServiceRPHArray	= New Array;
						If vServiceRPHs <> Undefined Then
							vServiceRPHArray = PropertyToArray(vServiceRPHs.Get("ServiceRPH"));
						EndIf;
						
						i = 1;
						vPreviousRateID = Undefined;
						For Each vGuest In vGuestCountArray Do
							If vSuccess = False Then
								Break;
							EndIf;
							vGuestsNumber	= Number(vGuest.Get("Count"));
							vAge			= vGuest.Get("Age");
							vResGuestRPH	= vGuest.Get("ResGuestRPH");
							
							For j = 1 To vGuestsNumber Do 
								vAccomodationType = vAccomodationTypes[i-1].AccommodationType.Code;
								
								vExternalGroupReservationRow 					= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/","WriteExternalGroupReservationRow"));
								vExternalGroupReservationRow.ReservationCode 	= vGuestGroupCode + "/" + String(i);
								vExternalGroupReservationRow.GroupCode 			= vReservationID;
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
								vExternalGroupReservationRow.ReservationRemarks = Left(vComment, 4095);
								vExternalGroupReservationRow.Room 				= vRoomUUID;
								vExternalGroupReservationRow.ID					= vExternalID;
								
								// Get discount from "Discounts" field or from "Comments" field
								vHotelDiscounts = InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "Discounts");
								vDiscounts = vRoomStay.Get("Discounts");
								If ValueIsFilled(vDiscounts) Then
									If vHotelDiscounts.Count() > 0 Then
										vDiscountCode = "";
										If TypeOf(vDiscounts) = Type("Array") And vDiscounts.Count() > 0 Then 
											vDiscountCode = vDiscounts[0].Get("DiscountCode");
											vExternalGroupReservationRow.DiscountConfirmationText = GetDiscountText(vDiscounts[0]);
										ElsIf TypeOf(vDiscounts) = Type("Map") Then
											vDiscountCode = vDiscounts.Get("DiscountCode");
											vExternalGroupReservationRow.DiscountConfirmationText = GetDiscountText(vDiscounts);
										EndIf;
										If vDiscountCode <> Undefined And Not IsBlankString(vDiscountCode) Then
											vDiscRow = vHotelDiscounts.Find(TrimAll(vDiscountCode), "ID");
											If Not vDiscRow = Undefined Then
												vDiscountRef = vDiscRow.RefKey1;
												If ValueIsFilled(vDiscountRef) Then
													vExternalGroupReservationRow.DiscountType = vDiscountRef.Description;
												EndIf;	
											EndIf;
										EndIf;
									EndIf;
								ElsIf Not ValueIsFilled(vDiscounts) Or Not ValueIsFilled(vExternalGroupReservationRow.DiscountType) Then
									If vHotelDiscounts.Count() > 0 And Not IsBlankString(vComment) And StrFind(vComment, "#DiscountsStart#") > 0 Then
										vIdStart = StrFind(vComment, "#DiscountsStart#") + 16;
										vIdEnd   = StrFind(vComment, "#DiscountsEnd#");
										vDiscRow = TrimAll(Mid(vComment, vIdStart, vIdEnd - vIdStart));
										vDisc =  TrimAll(Mid(vDiscRow, 1, StrFind(vDiscRow, ":") - 1));
										If Not IsBlankString(vDisc) Then
											vDiscRow = vHotelDiscounts.Find(vDisc, "ID");
											If Not vDiscRow = Undefined Then
												vDiscountRef = vDiscRow.RefKey1;
												If ValueIsFilled(vDiscountRef) Then
													vExternalGroupReservationRow.DiscountType = vDiscountRef.Description;
												EndIf;	
											EndIf;	
										EndIf;	
									EndIf;
								EndIf;
								
								If vSourceOfBusinessCode <> Undefined Then
									vExternalGroupReservationRow.SourceOfBusiness 	= vSourceOfBusinessCode;
								EndIf;
								
								If vMarketingCodeCode <> Undefined Then
									vExternalGroupReservationRow.MarketingCode 	= vMarketingCodeCode;
								EndIf;
								
								If vAge <> Undefined And cmIsNumber(vAge) Then
									vGuestAge =  Number(vAge);
									If vGuestAge = 0 Then
										vGuestAge = 1;
									EndIf;
									vExternalGroupReservationRow.GuestAge 		= vGuestAge;
								EndIf;
								
								If vAgent <> Undefined Then
									If ValueIsFilled(vAgent.Agent) Then
										vExternalGroupReservationRow.Agent = TrimAll(vAgent.Agent.Code);
									Else	
										vExternalGroupReservationRow.Agent = TrimAll(vAgent.Code);
									EndIf;
									vExternalGroupReservationRow.Customer		= TrimAll(vAgent.Code);
								EndIf;
								
								vCustomerPays = False;
								If vPayment <> Undefined And ValueIsFilled(vPayment.PaymentMethod) And vPayment.PaymentMethod.IsByBankTransfer Then
									vCustomerPays = True;
								EndIf;
								If pInteractionParameters.UseClient And Not vCustomerPays Then
									vExternalGroupReservationRow.Customer = "USE_CLIENT";
								EndIf;
								
								vExternalGroupReservationRow.ContactPerson 	= vCustomerData.FirstName + " " + vCustomerData.SecondName + " " + vCustomerData.LastName + " " + vCustomerData.Email + " " + vCustomerData.Phone;
								
								If vAllotmentCode <> Undefined Then
									vExternalGroupReservationRow.RoomQuota = vAllotmentCode;
								EndIf;
								
								vThereIsGuestPrices = False;
								If vResGuestRPH <> Undefined Then 
									vPricesRow = vGuestPrices.Find(vResGuestRPH, "ResGuestRPH");
								Else
									vPricesRow = Undefined;
								EndIf;
								
								If vPricesRow = Undefined Then
									vPricesRow = vGuestPrices.Find(Undefined, "ResGuestRPH");
									If vPricesRow = Undefined Then
										vPricesXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "PricesPerDate"));
										vRatesXDTO	= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "RoomRatePlan"));
									Else
										vPricesXDTO = vPricesRow.PricesXDTO;
										vRoomRateID	= vPricesRow.RatePlanCode;
										vRatesXDTO 	= vPricesRow.RatePlanXDTO;
									EndIf;
								Else
									vThereIsGuestPrices = True;
									vPricesXDTO 		= vPricesRow.PricesXDTO;
									vRoomRateID			= vPricesRow.RatePlanCode;
									vRatesXDTO 			= vPricesRow.RatePlanXDTO;
								EndIf;
								
								If vPreviousRateID <> vRoomRateID Then
									vRoomRates 		= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "roomrates", , , , vRoomRateID);
									If vRoomRates.Count() = 0 Then
										vResult.Success = False;
										vResult.Error	= "Failed to find roomrates data by ID:" + vRoomRateID + "; Booking №:" + vReservationID;;
										vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
										InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation", vLogEventType, , , vResult.Error);
										vSuccess = False;
										Break;
									Else
										vRoomRate 		= vRoomRates[0].RefKey1;
									EndIf;
								EndIf;
								
								vExternalGroupReservationRow.RoomRate = TrimAll(vRoomRate.Code);
								
								vGuestXDTO = Undefined;
								vGuestRow = vGuestsDataTable.Find(vResGuestRPH, "ResGuestRPH");
								If vGuestRow <> Undefined Then
									vGuestXDTO 						= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
									vGuestXDTO.ClientFirstName 		= vGuestRow.FirstName;
									vGuestXDTO.ClientSecondName 	= vGuestRow.SecondName;
									vGuestXDTO.ClientLastName 		= vGuestRow.LastName;
									vGuestXDTO.ClientCitizenship 	= vGuestRow.Citizenship;
									vGuestXDTO.ClientSex 			= Left(vGuestRow.Gender, 1);
									vGuestXDTO.ClientBirthDate		= vGuestRow.BirthDate;
									vGuestXDTO.ClientCode 			= vGuestRow.GuestID;
									If (i = 1  And vWriteContactsToTheFirstGuest) 
										Or (vGuestRow.LastName = vCustomerData.LastName 
										And vGuestRow.SecondName = vCustomerData.SecondName 
										And vGuestRow.FirstName = vCustomerData.FirstName) Then  
										
										vGuestXDTO.ClientPhone 		= vCustomerData.Phone;
										vGuestXDTO.ClientEMail 		= vCustomerData.Email;
									EndIf;  
								EndIf;
								
								vExternalGroupReservationRow.RoomRatePlan 	= ChannelManagers.CopyXDTO(vRatesXDTO, XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "RoomRatePlan"));
								
								If i = 1 Then
									vExternalGroupReservationRow.AccommodationTemplate 	= vAccommodationTemplate.Code;
									If vGuestXDTO = Undefined Then
										vExternalGroupReservationRow.Client	= ChannelManagers.CopyXDTO(vMainGuest, XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
									Else
										vExternalGroupReservationRow.Client = vGuestXDTO;	
									EndIf;
									
									If pGetPrices = True Then
										vExternalGroupReservationRow.PricesPerDate	= ChannelManagers.CopyXDTO(vPricesXDTO, XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "PricesPerDate"));
									EndIf;
									
								Else
									If vGuestXDTO = Undefined Then
										vExternalGroupReservationRow.Client	= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
									Else
										vExternalGroupReservationRow.Client = vGuestXDTO;	
									EndIf;
									
									If pGetPrices = True Then
										If Not vThereIsGuestPrices Then
											vPricesCopy 								= ChannelManagers.CopyXDTO(vPricesXDTO, XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "PricesPerDate"));
											vPricesCopy 								= ResetXDTOPrices(vPricesCopy);					
											vExternalGroupReservationRow.PricesPerDate	= vPricesCopy;											
										Else
											vExternalGroupReservationRow.PricesPerDate	= ChannelManagers.CopyXDTO(vPricesXDTO, XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "PricesPerDate"));
										EndIf;
									EndIf;
								EndIf;
								
								vServicesXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "ChargeExtraServices"));
								
								vPreviousPersonServiceID = Undefined;
								vRPHClearArray = New Array;
								For Each vServiceRPHRow In vServiceRPHArray Do
									vRPH = vServiceRPHRow.Get("RPH");
									vServiceRows = vServices.FindRows(New Structure("ServiceRPH", vRPH));
									
									If vServiceRows.Count() > 0 Then
										If Not pGetPrices Then
											vFirstServiceRow = vServiceRows[0];
											vServicePricingType = StrReplace((Title(vFirstServiceRow.ServicePricingType)), " ", "");
											If vPreviousPersonServiceID <> vFirstServiceRow.Service Then
												If Enums.TLPricingTypes[vServicePricingType] = Enums.TLPricingTypes.PerPerson Or
													Enums.TLPricingTypes[vServicePricingType] = Enums.TLPricingTypes.PerPersonPerNight Or
													Enums.TLPricingTypes[vServicePricingType] = Enums.TLPricingTypes.PerOccupancyPerNight Then
													vPreviousPersonServiceID = vFirstServiceRow.Service;
												EndIf;
												vRPHClearArray.Add(vServiceRPHRow);
											Else
												Continue;
											EndIf;
										EndIf;
										
										For Each vServiceRow In vServiceRows Do
											If Not ValueIsFilled(vServiceRow.Service) Or vServiceRow.Inclusive = True Then
												Continue;
											EndIf;
											
											vExtraServicePackage = cmGetObjectRefByExternalSystemCode(pInteractionParameters.Hotel, pInteractionParameters.Code, "ServicePackages", vServiceRow.Service);
											If Not ValueIsFilled(vExtraServicePackage) And ValueIsFilled(pInteractionParameters) Then
												vServicePackageMapping = InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "servicepackages", "id", , , , vServiceRow.Service);
												For Each vServicePackageMappingRow In vServicePackageMapping Do
													vExtraServicePackage = vServicePackageMappingRow.RefKey1;
													Break;
												EndDo;
											EndIf;
											
											vServiceRowXDTO 			= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "ChargeExtraServiceRow"));
											vServiceRowXDTO.Service 	= vServiceRow.Service;
											vServiceRowXDTO.Price 		= vServiceRow.Price;
											If ValueIsFilled(vExtraServicePackage) Then
												vServiceRowXDTO.Quantity 	= 1;
											Else
												vServiceRowXDTO.Quantity 	= vServiceRow.Quantity;
											EndIf;
											vServiceRowXDTO.Remarks 	= vServiceRow.Remarks;
											vServiceRowXDTO.Currency 	= pInteractionParameters.Currency.Code;
											vServiceRowXDTO.ChargeDate 	= vServiceRow.ChargeDate;
											
											vServicesXDTO.ChargeExtraServiceRow.Add(vServiceRowXDTO);
										EndDo;
									EndIf;
								EndDo;
								
								If Not pGetPrices Then
									For Each vRPHIdx In vRPHClearArray Do
										vServiceRPHArray.Delete(vServiceRPHArray.Find(vRPHIdx));
									EndDo;
								Else
									vServiceRPHArray.Clear();
								EndIf;
								
								If vServicesXDTO.GetList("ChargeExtraServiceRow").Count() > 0 Then
									vExternalGroupReservationRow.ChargeExtraServices = vServicesXDTO;								
								EndIf;								
								
								If ValueIsFilled(vPayment.GuaranteeType) Then
									vExternalGroupReservationRow.GuaranteeType = vPayment.GuaranteeType.Code; 
								EndIf;
								
								If ValueIsFilled(vPayment.PaymentMethod) Then
									vExternalGroupReservationRow.PlannedPaymentMethod = vPayment.PaymentMethod.Code; 
								EndIf;
								
								vExternalGroupReservation.WriteExternalGroupReservationRow.Add(vExternalGroupReservationRow);
								i = i + 1;
								vPreviousRateID = vRoomRateID; 
							EndDo;
						EndDo;
					EndIf;
				EndDo;
			EndIf;
			
			If vSuccess = True Then
				vAnswerXDTO = cmWriteExternalGroupReservation(vExternalGroupReservation, , True);
				If ValueIsFilled(vAnswerXDTO.ErrorDescription) Then
					vResult.Success = False;
					vResult.Error	= "Failed to create reservation: " + vAnswerXDTO.ErrorDescription + "; Booking №:" + vReservationID;
					vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation", vLogEventType, , , vResult.Error);
					
					vLoadedResStructure = New Structure("CreateDateTime, ResStatus, LastModifyDateTime, UniqueID, Error, GuestGroupCode", CurrentSessionDate(), "Requestdenied", vLastModifyDateTime, vReservationID, vAnswerXDTO.ErrorDescription, "");
					vResult.LoadedReservationsArray.Add(vLoadedResStructure);
					Continue;
				Else
					vLoadedResStructure = New Structure("CreateDateTime, ResStatus, LastModifyDateTime, UniqueID, Error, GuestGroupCode", CurrentSessionDate(), "Reserved", vLastModifyDateTime, vReservationID, "", vAnswerXDTO.GuestGroup);
					vResult.LoadedReservationsArray.Add(vLoadedResStructure);
					
					If vPayment.Amount > 0 Then
						vPaymentMethodCode = Undefined;
						If ValueIsFilled(vPayment.PaymentMethod) Then
							vPaymentMethodCode = vPayment.PaymentMethod.Code; 
						EndIf;
						vPaymentExtCode = ?(IsBlankString(vPayment.PaymentExtCode),vReservationID, vPayment.PaymentExtCode);
						vPaymentXDTO = cmWriteExternalPayment("",vReservationID,,,,,,vPaymentMethodCode,vPayment.Amount, pInteractionParameters.Currency.Code, ,pInteractionParameters.Hotel.Code, pInteractionParameters.InteractionID,,,vPayment.PaymentSystemTitle,,,,vPaymentExtCode,"XDTO",);
						vPaymentError = TrimAll(vPaymentXDTO.ErrorDescription);
						If Not vPaymentError = "" Then
							vResult.Error	= "Failed to create payment: " + vAnswerXDTO.ErrorDescription + "; Booking №:" + vReservationID;
							vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
							InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation", vLogEventType, , , vResult.Error);
						EndIf;
					EndIf;
					// Loyalty payment
					If pReceiveBonuses And vPayment.LoyaltyAmount > 0 Then
						vLoyaltyPaymentMethodCode = Undefined;
						If ValueIsFilled(vPayment.LoyaltyPaymentMethod) Then
							vLoyaltyPaymentMethodCode = vPayment.LoyaltyPaymentMethod.Code; 
						EndIf;
						vLoyaltyPaymentExtCode = vPayment.LoyaltyPaymentExtCode + "_" + vReservationID;
						vPaymentXDTO = cmWriteExternalPayment("", vReservationID, , , , , , vLoyaltyPaymentMethodCode,vPayment.LoyaltyAmount, pInteractionParameters.Currency.Code, ,pInteractionParameters.Hotel.Code, pInteractionParameters.InteractionID, , , vPayment.LoyaltyPaymentSystemTitle, , , , vLoyaltyPaymentExtCode, "XDTO");
						vPaymentError = TrimAll(vPaymentXDTO.ErrorDescription);
						If Not vPaymentError = "" Then
							vResult.Error	= "Failed to create loyalty payment: " + vAnswerXDTO.ErrorDescription + "; Booking №:" + vReservationID;
							vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
							InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation", vLogEventType, , , vResult.Error);
						EndIf;
					EndIf;
					
				EndIf;
			Else
				vLoadedResStructure = New Structure("CreateDateTime, ResStatus, LastModifyDateTime, UniqueID, Error, GuestGroupCode", CurrentSessionDate(), "Requestdenied", vLastModifyDateTime, vReservationID, vResult.Error, "");
				vResult.LoadedReservationsArray.Add(vLoadedResStructure);
				Continue;	
			EndIf;
		Else
			vGuestGroupCode = "";
			vCancelResult 	= cmCancelGroupReservation(vReservationID, TrimAll(pInteractionParameters.Hotel.Code), pInteractionParameters.Code,,,,vReservationStatus, , vGuestGroupCode);
			If Not vCancelResult = "" Then
				vResult.Error	= "Failed to cancel reservation: " + vCancelResult + "; Booking №:" + vReservationID;
				vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation", vLogEventType, , , vResult.Error);
			EndIf;
			If Not ValueIsFilled(vGuestGroupCode) Then
				vGuestGroupCode = vReservationID;	
			EndIf;
			vLoadedResStructure = New Structure("CreateDateTime, ResStatus, LastModifyDateTime, UniqueID, Error, GuestGroupCode", CurrentSessionDate(), "Reserved", vLastModifyDateTime, vReservationID, "", vGuestGroupCode);
			vResult.LoadedReservationsArray.Add(vLoadedResStructure);
			
			vPathArray	= New Array;
			vPathArray.Add("TimeSpan");
			vPathArray.Add("Start");
			vStart = Catalogs.DataConvertationRules.GetMapValueByArrayPath(vGlobalInfoMap, vPathArray);
			
			vPathArray	= New Array;
			vPathArray.Add("TimeSpan");
			vPathArray.Add("End");
			vEnd = Catalogs.DataConvertationRules.GetMapValueByArrayPath(vGlobalInfoMap, vPathArray);
			
			vStart		= StrReplace(vStart, "T", "");
			vEnd		= StrReplace(vEnd, "T", "");
			vStart		= StrReplace(vStart, "-", "");
			vEnd		= StrReplace(vEnd, "-", "");
			vStart		= StrReplace(vStart, ":", "");
			vEnd		= StrReplace(vEnd, ":", "");
			vPeriodFrom = Date(vStart);
			vPeriodTo 	= Date(vEnd);
			
			If vAvailabilityUpdatePeriod.PeriodFrom = Undefined Or vAvailabilityUpdatePeriod.PeriodFrom > vPeriodFrom Then
				vAvailabilityUpdatePeriod.PeriodFrom = vPeriodFrom;	
			EndIf;
			
			If vAvailabilityUpdatePeriod.PeriodTo = Undefined Or vAvailabilityUpdatePeriod.PeriodTo < vPeriodTo Then
				vAvailabilityUpdatePeriod.PeriodTo = vPeriodTo;	
			EndIf;
		EndIf;
	EndDo;
	
	If vAvailabilityUpdatePeriod.PeriodFrom <> Undefined Then
		vResult.AvailabilityUpdateDates = vAvailabilityUpdatePeriod; 	
	EndIf;
	
	Return vResult;
EndFunction // LoadReservations

// -------------------------------------------------------------------------
Function GetHotelData(pInteractionParameters, pHotelCode, pLanguageID = Undefined, pVersion = Undefined, pGetRaw = False) Export
	
	vResult 		= New Structure("Success, Error, Raw, Result", False, "", "", Undefined);
	vMessageName 	= "OTA_HotelAvailRQ";
	vMessageNameRS 	= "OTA_HotelAvailRS";
	vResponse		= Undefined;
	vMethod 		= "POST";
	
	If pLanguageID = Undefined Then
		pLanguageID = "RU";
	EndIf;
	
	If pVersion = Undefined Then
		pVersion = Version(pInteractionParameters);
	EndIf;
	
	Try
		If Not ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Empty InterectionParameters";
			Return vResult;
		EndIf;
		
		vRequestHeaders 			= New Structure("SOAPAction");
		vRequestHeaders.SOAPAction 	= "https://www.travelline.ru/Api/TLConnect/HotelAvailRQ";
		vRequestBody 	= GetHotelDataRequest(pInteractionParameters, pHotelCode, pLanguageID, pVersion);
		
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, vRequestHeaders, , vMethod, vMessageName, vRequestBody, "text/xml;charset=utf-8",,,,,,,,, "GetHotelData");

		vResponseStatus = CheckResponseStatus(vResponse);
		
		If vResponseStatus.Success = False Then
			vResult.Error 	= vResponseStatus.StatusDescription;
			vResult.Success = vResponseStatus.Success;
		Else
			vResponseMap 		= Catalogs.DataConvertationRules.XMLtoMap(vResponse.Body);
			vBodyCheckResult 	= CheckResultBody(vResponseMap, vMessageNameRS);
			vResult.Success 	= vBodyCheckResult.Success;
			vResult.Error		= vBodyCheckResult.Error;
			If vResult.Success Then
				vPathArray		= New Array;
				vPathArray.Add("s:Envelope");
				vPathArray.Add("s:Body");
				vPathArray.Add(vMessageNameRS);			
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
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "GetHotelData", vLogEventType, ,vRawValue , vResult.Error);
	EndTry;
	
	If pGetRaw = True Then
		vRawValue = Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		vResult.Raw = vRawValue;	
	EndIf;
	
	Return vResult;
	
EndFunction // GetHotelData

// -------------------------------------------------------------------------
Function SendAvailability(pInteractionParameters, pHotelCode, pLanguageID = Undefined, pVersion = Undefined, pAmountOfDaysToUpdate = 100, pFullUpdate = False, pGetRaw = False, pPeriodFrom = Undefined, pPeriodTo = Undefined, pRoomTypes = Undefined, pGetVacantRoomsAtMidnight = False) Export
	
	vResult 		= New Structure("Success, Error, Raw, Result", False, "", "", Undefined);
	vMessageName 	= "OTA_HotelAvailNotifRQ";
	vMessageNameRS 	= "OTA_HotelAvailNotifRS";
	vResponse		= Undefined;
	vMethod 		= "POST";
	
	If pLanguageID = Undefined Then
		pLanguageID = "RU";
	EndIf;
	
	If pVersion = Undefined Then
		pVersion = Version(pInteractionParameters);
	EndIf;

	Try
		If Not ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Empty InterectionParameters";
			Return vResult;
		EndIf;
		
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
		
		vAvailability 	= Undefined;
		
		vRequestHeaders 			= New Structure("SOAPAction");
		vRequestHeaders.SOAPAction 	= "https://www.travelline.ru/Api/TLConnect/HotelAvailNotifRQ";
		
		vRequestBody = GetAvailabilityRequest(pInteractionParameters, pHotelCode, pLanguageID, pVersion, vPeriodFrom, vPeriodTo, pFullUpdate, vAvailability, pRoomTypes, pGetVacantRoomsAtMidnight);
		
		If vRequestBody = "" Then
			vResult.Success = True;
			Return vResult;
		EndIf;

		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, vRequestHeaders, , vMethod, vMessageName, vRequestBody, "text/xml;charset=utf-8",,,,,,,,,"SendAvailability");

		vResponseStatus = CheckResponseStatus(vResponse);
		
		If vResponseStatus.Success = False Then
			vResult.Error 	= vResponseStatus.StatusDescription;
			vResult.Success = vResponseStatus.Success;
		Else
			vResponseMap 		= Catalogs.DataConvertationRules.XMLtoMap(vResponse.Body);
			vBodyCheckResult 	= CheckResultBody(vResponseMap, vMessageNameRS);
			vResult.Success 	= vBodyCheckResult.Success;
			vResult.Error		= vBodyCheckResult.Error;
			If NOT IsBlankString(vBodyCheckResult.Warning) Then
				vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SendAvailability", vLogEventType, vRequestBody, vResponse.Body, vBodyCheckResult.Warning);
			EndIf;
			If NOT IsBlankString(vBodyCheckResult.Error) Then
				vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SendAvailability", vLogEventType,vRequestBody ,vResponse.Body, vBodyCheckResult.Error);
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
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SendAvailability", vLogEventType, ,vRawValue , vResult.Error);
	EndTry;
	
	If pGetRaw = True Then
		vRawValue = Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		vResult.Raw = vRawValue;	
	EndIf;
	
	Return vResult;
	
EndFunction // SendAvailability

// -------------------------------------------------------------------------
Function SendRestrictions(pInteractionParameters, pHotelCode, pLanguageID = Undefined, pVersion = Undefined, pAmountOfDaysToUpdate = 100, pFullUpdate = False, pGetRaw = False, pPeriodFrom = Undefined, pPeriodTo = Undefined, pRoomTypes = Undefined, pRoomRates = Undefined) Export
	
	vResult 		= New Structure("Success, Error, Raw, Result", False, "", "", Undefined);
	vMessageName 	= "OTA_HotelAvailNotifRQ";
	vMessageNameRS 	= "OTA_HotelAvailNotifRS";
	vResponse		= Undefined;
	vMethod 		= "POST";
	
	If pLanguageID = Undefined Then
		pLanguageID = "RU";
	EndIf;
	
	If pVersion = Undefined Then
		pVersion = Version(pInteractionParameters);
	EndIf;

	Try
		If Not ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Empty InterectionParameters";
			Return vResult;
		EndIf;
		
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

		vRoomRates 		= Undefined;
		vRoomTypes		= Undefined;
		
		vRequestHeaders 			= New Structure("SOAPAction");
		vRequestHeaders.SOAPAction 	= "https://www.travelline.ru/Api/TLConnect/HotelAvailNotifRQ";
		vRequestBody 	= GetRestrictionsRequest(pInteractionParameters, pHotelCode, pLanguageID, pVersion, vPeriodFrom, vPeriodTo, pFullUpdate, vRoomRates, vRoomTypes, pRoomTypes, pRoomRates);
		
		If vRequestBody = "" Then
			vResult.Success = True;
			Return vResult;
		EndIf;
		
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, vRequestHeaders, , vMethod, vMessageName, vRequestBody, "text/xml;charset=utf-8",,,,,,,,, "SendRestrictions");

		vResponseStatus = CheckResponseStatus(vResponse);
		
		If vResponseStatus.Success = False Then
			vResult.Error 	= vResponseStatus.StatusDescription;
			vResult.Success = vResponseStatus.Success;
		Else
			vResponseMap 		= Catalogs.DataConvertationRules.XMLtoMap(vResponse.Body);
			vBodyCheckResult 	= CheckResultBody(vResponseMap, vMessageNameRS);
			vResult.Success 	= vBodyCheckResult.Success;
			vResult.Error		= vBodyCheckResult.Error;
			If NOT IsBlankString(vBodyCheckResult.Warning) Then
				vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SendRestrictions", vLogEventType,vRequestBody, vResponse.Body, vBodyCheckResult.Warning);
			EndIf;
			If NOT IsBlankString(vBodyCheckResult.Error) Then
				vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SendRestrictions", vLogEventType,vRequestBody, vResponse.Body, vBodyCheckResult.Error);
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
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SendRestrictions.Error", vLogEventType, ,vRawValue , vResult.Error);
	EndTry;
	
	If pGetRaw = True Then
		vRawValue = Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		vResult.Raw = vRawValue;	
	EndIf;
	
	Return vResult;
	
EndFunction // SendRestrictions

// -------------------------------------------------------------------------
Function SendPrices(pInteractionParameters, pHotelCode, pLanguageID = Undefined, pVersion = Undefined, pAmountOfDaysToUpdate = 100, pFullUpdate = False, pUpdateCachedPrices = False, pGetRaw = False, pPeriodFrom = Undefined, pPeriodTo = Undefined, pRoomTypes = Undefined, pRoomRates = Undefined, pUsePriceTags = False) Export
	
	vResult 		= New Structure("Success, Error, Raw, Result", False, "", "", Undefined);
	vMessageName 	= "OTA_HotelRateAmountNotifRQ";
	vMessageNameRS 	= "OTA_HotelRateAmountNotifRS";
	vResponse		= Undefined;
	vMethod 		= "POST";
	
	If pLanguageID = Undefined Then
		pLanguageID = "RU";
	EndIf;
	
	If pVersion = Undefined Then
		pVersion = Version(pInteractionParameters);
	EndIf;

	Try
		If Not ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Empty InterectionParameters";
			Return vResult;
		EndIf;
		
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

		vRoomRates 		= Undefined;
		vRoomTypes		= Undefined;
		
		vRequestHeaders 			= New Structure("SOAPAction");
		vRequestHeaders.SOAPAction 	= "https://www.travelline.ru/Api/TLConnect/HotelRateAmountNotifRQ";
		vRequestBody 				= GetPricesRequest(pInteractionParameters, pHotelCode, pLanguageID, pVersion, vPeriodFrom, vPeriodTo, pFullUpdate, pUpdateCachedPrices, vRoomRates, vRoomTypes, pRoomTypes, pRoomRates, pUsePriceTags);
		
		If vRequestBody = "" Then
			vResult.Success = True;
			Return vResult;
		EndIf;
		
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, vRequestHeaders, , vMethod, vMessageName, vRequestBody, "text/xml;charset=utf-8", , , , , , , , , "SendPrices");

		vResponseStatus = CheckResponseStatus(vResponse);
		
		If vResponseStatus.Success = False Then
			vResult.Error 	= vResponseStatus.StatusDescription;
			vResult.Success = vResponseStatus.Success;
		Else
			vResponseMap 		= Catalogs.DataConvertationRules.XMLtoMap(vResponse.Body);
			vBodyCheckResult 	= CheckResultBody(vResponseMap, vMessageNameRS);
			vResult.Success 	= vBodyCheckResult.Success;
			vResult.Error		= vBodyCheckResult.Error;
			If NOT IsBlankString(vBodyCheckResult.Warning) Then
				vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SendPrices", vLogEventType,vRequestBody, vResponse.Body, vBodyCheckResult.Warning);
			EndIf;
			If NOT IsBlankString(vBodyCheckResult.Error) Then
				vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SendPrices", vLogEventType,vRequestBody, vResponse.Body, vBodyCheckResult.Error);
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
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SendPrices", vLogEventType, ,vRawValue , vResult.Error);
	EndTry;
	
	If pGetRaw = True Then
		vRawValue = Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		vResult.Raw = vRawValue;	
	EndIf;
	
	Return vResult;
	
EndFunction // SendPrices

// -------------------------------------------------------------------------
Function GetReservations(pInteractionParameters, pHotelCode, pLanguageID = Undefined, pVersion = Undefined, pGetRaw = False, pAllotmentCode = Undefined, pGetPrices, pXMLString=Undefined, pReceiveBonuses = False) Export
	
	vResult 		= New Structure("Success, Error, Raw, ConfirmationResult, AvailabilityUpdateDates", False, "", "", Undefined, Undefined);
	vMessageName 	= "OTA_ReadRQ";
	vMessageNameRS 	= "OTA_ResRetrieveRS";
	vResponse		= Undefined;
	vMethod 		= "POST";
	
	If pLanguageID = Undefined Then
		pLanguageID = "RU";
	EndIf;
	
	If pVersion = Undefined Then
		pVersion = Version(pInteractionParameters);
	EndIf;
	
	Try
		If Not ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Empty InterectionParameters";
			Return vResult;
		EndIf;
		
		vRequestHeaders 			= New Structure("SOAPAction");
		vRequestHeaders.SOAPAction 	= "https://www.travelline.ru/Api/TLConnect/HotelReadReservationRQ";
		vRequestBody = GetReservationsRequest(pInteractionParameters, pHotelCode, pVersion);
		If pXMLString = Undefined Then
			vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, vRequestHeaders, , vMethod, vMessageName, vRequestBody, "text/xml;charset=utf-8", , , , , , , , , "GetReservations");

			vResponseStatus = CheckResponseStatus(vResponse);
			
			If vResponseStatus.Success = False Then
				vResult.Error 	= vResponseStatus.StatusDescription;
				vResult.Success = vResponseStatus.Success;
			Else
				vResponseBody = vResponse.Body;
			EndIf;
		Else
				vResponseBody = pXMLString;
		EndIf;
		If ValueIsFilled(vResponseBody) Then
			vResponseMap 		= Catalogs.DataConvertationRules.XMLtoMap(vResponseBody);
			vBodyCheckResult 	= CheckResultBody(vResponseMap, vMessageNameRS);
			vResult.Success 	= vBodyCheckResult.Success;
			vResult.Error		= vBodyCheckResult.Error;
			If vResult.Success Then
				vPathArray		= New Array;
				vPathArray.Add("s:Envelope");
				vPathArray.Add("s:Body");
				vPathArray.Add(vMessageNameRS);	
				vPathArray.Add("ReservationsList");
				vReservationsMap		= Catalogs.DataConvertationRules.GetMapValueByArrayPath(vResponseMap, vPathArray);
				If vReservationsMap <> Undefined Then
					vReservationLoadResult			= LoadReservations(pInteractionParameters, vReservationsMap, pGetPrices, pReceiveBonuses);
					vResult.Success					= vReservationLoadResult.Success;
					vResult.Error					= vReservationLoadResult.Error;
					vResult.AvailabilityUpdateDates = vReservationLoadResult.AvailabilityUpdateDates; 
					vResult.ConfirmationResult		= ConfirmReservations(pInteractionParameters, pHotelCode, vReservationLoadResult.LoadedReservationsArray, pVersion, pGetRaw);
				EndIf;
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
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "GetReservations", vLogEventType, ,vRawValue , vResult.Error);
	EndTry;
	
	If pGetRaw = True Then
		vRawValue = Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		vResult.Raw = vRawValue;	
	EndIf;
	
	Return vResult;
	
EndFunction // GetReservations

// -------------------------------------------------------------------------
Function ConfirmReservations(pInteractionParameters, pHotelCode, pReservations, pVersion = Undefined, pGetRaw = False) 
	
	vResult 		= New Structure("Success, Error, Raw", False, "", "");
	vMessageName 	= "OTA_NotifReportRQ";
	vMessageNameRS 	= "OTA_NotifReportRS";
	vResponse		= Undefined;
	vMethod 		= "POST";
		
	If pVersion = Undefined Then
		pVersion = Version(pInteractionParameters);
	EndIf;
	
	Try
		If Not ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Empty InterectionParameters";
			Return vResult;
		EndIf;
		
		vRequestHeaders 			= New Structure("SOAPAction");
		vRequestHeaders.SOAPAction 	= "https://www.travelline.ru/Api/TLConnect/NotifReportRQRequest";
		vRequestBody 				= GetConfirmReservationsRequest(pInteractionParameters, pHotelCode, pVersion, pReservations);
		
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, vRequestHeaders, , vMethod, vMessageName, vRequestBody, "text/xml;charset=utf-8", , , , , , , , , "ConfirmReservations");

		vResponseStatus = CheckResponseStatus(vResponse);
		
		If vResponseStatus.Success = False Then
			vResult.Error 	= vResponseStatus.StatusDescription;
			vResult.Success = vResponseStatus.Success;
		Else
			vResponseMap 		= Catalogs.DataConvertationRules.XMLtoMap(vResponse.Body);
			vBodyCheckResult 	= CheckResultBody(vResponseMap, vMessageNameRS);
			vResult.Success 	= vBodyCheckResult.Success;
			vResult.Error		= vBodyCheckResult.Error;
			If NOT IsBlankString(vBodyCheckResult.Warning) Then
				vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "ConfirmReservations", vLogEventType,vRequestBody,vResponse.Body, vBodyCheckResult.Warning);
			EndIf;
			If NOT IsBlankString(vBodyCheckResult.Error) Then
				vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "ConfirmReservations", vLogEventType,vRequestBody,vResponse.Body, vBodyCheckResult.Error);
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
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "ConfirmReservations", vLogEventType, ,vRawValue , vResult.Error);
	EndTry;
	
	If pGetRaw = True Then
		vRawValue = Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		vResult.Raw = vRawValue;	
	EndIf;
	
	Return vResult;
	
EndFunction // ConfirmReservations

#EndRegion

#Region API_requests

// -------------------------------------------------------------------------
Function GetHotelDataRequest(pInteractionParameters, pHotelCode, pLanguageID, pVersion)
	
	vResult = "";
	
	vXMLDocument = New XMLWriter;
	
	vXMLDocument.SetString();
	
	vXMLDocument.WriteStartElement("soapenv:Envelope");
	vXMLDocument.WriteAttribute("xmlns:soapenv", "http://schemas.xmlsoap.org/soap/envelope/");
	vXMLDocument.WriteAttribute("xmlns:tlc", "https://www.travelline.ru/Api/TLConnect");
	vXMLDocument.WriteAttribute("xmlns:ns", "http://www.opentravel.org/OTA/2003/05");
		vXMLDocument.WriteStartElement("soapenv:Header");
			vXMLDocument.WriteStartElement("tlc:Security");
				vXMLDocument.WriteAttribute("Username",	pInteractionParameters.Login);
				vXMLDocument.WriteAttribute("Password",	pInteractionParameters.Password);
			vXMLDocument.WriteEndElement(); // Security
		vXMLDocument.WriteEndElement(); // Header
		vXMLDocument.WriteStartElement("soapenv:Body");		
			vXMLDocument.WriteStartElement("ns:OTA_HotelAvailRQ");
			vXMLDocument.WriteAttribute("Version", pVersion); 
			vXMLDocument.WriteAttribute("PrimaryLangID", pLanguageID);
			vXMLDocument.WriteAttribute("TimeStamp", Format(CurrentSessionDate(), "DF=yyyy-MM-ddTHH:mm:ss"));		
				vXMLDocument.WriteStartElement("ns:AvailRequestSegments");
					vXMLDocument.WriteStartElement("ns:AvailRequestSegment");
						vXMLDocument.WriteStartElement("ns:HotelSearchCriteria");
							vXMLDocument.WriteStartElement("ns:Criterion");
								vXMLDocument.WriteStartElement("ns:HotelRef");
								vXMLDocument.WriteAttribute("HotelCode", pHotelCode);
								vXMLDocument.WriteEndElement();
							vXMLDocument.WriteEndElement();
						vXMLDocument.WriteEndElement(); // HotelSearchCriteria
					vXMLDocument.WriteEndElement(); // AvailRequestSegment
				vXMLDocument.WriteEndElement(); // AvailRequestSegments
			vXMLDocument.WriteEndElement(); // ns:OTA_HotelAvailRQ
		vXMLDocument.WriteEndElement(); // soapenv:Body
	vXMLDocument.WriteEndElement(); // soapenv:Envelope
	
	vResult = vXMLDocument.Close();

	Return vResult;
	
EndFunction // GetHotelDataRequest

// -------------------------------------------------------------------------
Function GetAvailabilityRequest(pInteractionParameters, pHotelCode, pLanguageID, pVersion, pPeriodFrom, pPeriodTo, pFullUpdate = False, rRawTable = Undefined, pRoomTypes = Undefined, pGetVacantRoomsAtMidnight = False)
	
	vResult = "";
	vEmpty	= True;
	
	vXMLDocument = New XMLWriter;
	vXMLDocument.SetString();
	
	vXMLDocument.WriteStartElement("soapenv:Envelope");
	vXMLDocument.WriteAttribute("xmlns:soapenv","http://schemas.xmlsoap.org/soap/envelope/");
	vXMLDocument.WriteAttribute("xmlns:tlc","https://www.travelline.ru/Api/TLConnect");
	vXMLDocument.WriteAttribute("xmlns:ns","http://www.opentravel.org/OTA/2003/05");
	vXMLDocument.WriteStartElement("soapenv:Header");
	vXMLDocument.WriteStartElement("tlc:Security");
	vXMLDocument.WriteAttribute("Username", pInteractionParameters.Login);
	vXMLDocument.WriteAttribute("Password", pInteractionParameters.Password);
	vXMLDocument.WriteEndElement(); // Security
	vXMLDocument.WriteEndElement(); // Header
	vXMLDocument.WriteStartElement("soapenv:Body");
	
	vXMLDocument.WriteStartElement("ns:OTA_HotelAvailNotifRQ");
	vXMLDocument.WriteAttribute("Version", pVersion);
	vXMLDocument.WriteAttribute("PrimaryLangID", pLanguageID);
	vXMLDocument.WriteAttribute("TimeStamp", Format(CurrentSessionDate(), "DF=yyyy-MM-ddTHH:mm:ss"));
	
	vXMLDocument.WriteStartElement("ns:AvailStatusMessages");
	vXMLDocument.WriteAttribute("HotelCode", pHotelCode);
	
	vRoomTypes 			= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "roomtypes", 	"ID");
	vAllotments 		= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "allotments");
	vDefaultAllotments 	= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "DefaultAllotment");
	
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
			
			vAvailability = ChannelManagers.GetAvailability(pInteractionParameters, pPeriodFrom, pPeriodTo, pFullUpdate, vDefaultAllotment, pGetVacantRoomsAtMidnight);
			
			For Each vRoomType In vRoomTypes Do
				vRoomTypeAvailability = vAvailability.FindRows(New Structure("RoomType", vRoomType.RefKey1));
				For Each vRoomTypeAvailabilityRow In vRoomTypeAvailability Do
					
					vEmpty		= False;
					
					vBalance 	= vRoomTypeAvailabilityRow.VacantRooms;			
					If vRoomTypeAvailabilityRow.StopSale Then
						vBalance = 0;
					EndIf;
					
					vXMLDocument.WriteStartElement("ns:AvailStatusMessage");
					vXMLDocument.WriteAttribute("BookingLimit", Format(vBalance, "ND=12; NFD=0; NZ=0; NG="));
					vXMLDocument.WriteStartElement("ns:StatusApplicationControl");
					vXMLDocument.WriteAttribute("Start", Format(vRoomTypeAvailabilityRow.PeriodFrom, "DF=yyyy-MM-ddTHH:mm:ss"));
					vXMLDocument.WriteAttribute("End", Format(vRoomTypeAvailabilityRow.PeriodTo, "DF=yyyy-MM-ddTHH:mm:ss"));
										
					vXMLDocument.WriteAttribute("InvTypeCode", vRoomType.ID);
					vXMLDocument.WriteEndElement(); // StatusApplicationControl
					vXMLDocument.WriteEndElement(); // AvailStatusMessage
				EndDo;
			EndDo;
		EndIf;
		
		If vAvailability <> Undefined Then
			rRawTable = vAvailability;
		EndIf;
		
		If vAllotments <> Undefined Then
			For Each vAllotment In vAllotments Do
				
				vAvailability 	= ChannelManagers.GetAvailability(pInteractionParameters, pPeriodFrom, pPeriodTo, pFullUpdate, vAllotment.RefKey1);
				
				If rRawTable <> Undefined Then
					For Each vRow In vAvailability Do
						vNewRow = rRawTable.Add();
						FillPropertyValues(vNewRow, vRow);
					EndDo;
				Else
					rRawTable = vAvailability;
				EndIf;
				
				For Each vRoomType In vRoomTypes Do
					vRoomTypeAvailability 	= vAvailability.FindRows(New Structure("RoomType", vRoomType.RefKey1));
					For Each vRoomTypeAvailabilityRow In vRoomTypeAvailability Do
						
						vEmpty		= False;
						
						vBalance 	= vRoomTypeAvailabilityRow.VacantRooms;			
						If vRoomTypeAvailabilityRow.StopSale Then
							vBalance = 0;
						EndIf; 
						
						vXMLDocument.WriteStartElement("ns:AvailStatusMessage");
						vXMLDocument.WriteAttribute("BookingLimit", Format(vBalance, "ND=12; NFD=0; NZ=0; NG="));
						vXMLDocument.WriteStartElement("ns:StatusApplicationControl");
						vXMLDocument.WriteAttribute("Start", Format(vRoomTypeAvailabilityRow.PeriodFrom, "DF=yyyy-MM-ddTHH:mm:ss"));
						vXMLDocument.WriteAttribute("End", Format(vRoomTypeAvailabilityRow.PeriodTo, "DF=yyyy-MM-ddTHH:mm:ss"));
						
						vXMLDocument.WriteAttribute("InvBlockCode", vAllotment.id);
						
						vXMLDocument.WriteAttribute("InvTypeCode", vRoomType.ID);
						vXMLDocument.WriteEndElement(); // StatusApplicationControl
						vXMLDocument.WriteEndElement(); // AvailStatusMessage
					EndDo;
				EndDo;			
			EndDo;
		EndIf;
	EndIf;
	

	vXMLDocument.WriteEndElement(); // AvailStatusMessages
	vXMLDocument.WriteEndElement(); // OTA_HotelAvailNotifRQ
	vXMLDocument.WriteEndElement(); // Body				
	vXMLDocument.WriteEndElement(); // Envelope
	
	If Not vEmpty Then
		vResult = vXMLDocument.Close();
	EndIf;
	
	Return vResult;
	
EndFunction // GetAvailabilityRequest

// -------------------------------------------------------------------------
Function GetRestrictionsRequest(pInteractionParameters, pHotelCode, pLanguageID, pVersion, pPeriodFrom, pPeriodTo, pFullUpdate = False, rRoomRates = Undefined, rRoomTypes = Undefined, pRoomTypes = Undefined, pRoomRates = Undefined)
	
	vResult = "";
	vEmpty	= True;
	
	vRoomTypes 	= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "roomtypes");
	vRoomRates 	= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "roomrates");
	
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

	vXMLDocument = New XMLWriter;
	vXMLDocument.SetString();
	
	vXMLDocument.WriteStartElement("soapenv:Envelope");
	vXMLDocument.WriteAttribute("xmlns:soapenv", "http://schemas.xmlsoap.org/soap/envelope/");
	vXMLDocument.WriteAttribute("xmlns:tlc", "https://www.travelline.ru/Api/TLConnect");
	vXMLDocument.WriteAttribute("xmlns:ns", "http://www.opentravel.org/OTA/2003/05");
	vXMLDocument.WriteStartElement("soapenv:Header");
	vXMLDocument.WriteStartElement("tlc:Security");
	vXMLDocument.WriteAttribute("Username", pInteractionParameters.Login);
	vXMLDocument.WriteAttribute("Password", pInteractionParameters.Password);
	vXMLDocument.WriteEndElement(); // Security
	vXMLDocument.WriteEndElement(); // Header
	vXMLDocument.WriteStartElement("soapenv:Body");
	
	vXMLDocument.WriteStartElement("ns:OTA_HotelAvailNotifRQ");
	vXMLDocument.WriteAttribute("Version", pVersion);
	vXMLDocument.WriteAttribute("PrimaryLangID", pLanguageID);
	vXMLDocument.WriteAttribute("TimeStamp", Format(CurrentSessionDate(), "DF=yyyy-MM-ddTHH:mm:ss"));
	
	vXMLDocument.WriteStartElement("ns:AvailStatusMessages");
	vXMLDocument.WriteAttribute("HotelCode",pHotelCode);

	For Each vRoomRate In vRoomRates Do
		
		vRestrictions 	= ChannelManagers.GetRestrictions(pInteractionParameters, vRoomRate.RefKey1, pPeriodFrom, pPeriodTo, pFullUpdate);
		vRestrictions.Sort("RoomType, Period");
		vRestrictions	= CollapsePeriodTable(vRestrictions);
		
		For Each vRoomType In vRoomTypes Do
			
			vRoomTypeRestrictions = vRestrictions.FindRows(New Structure("RoomType", vRoomType.RefKey1));
			If vRoomTypeRestrictions.Count() = 0 Then
				vRoomTypeRestrictions = vRestrictions.FindRows(New Structure("RoomType", Catalogs.RoomTypes.EmptyRef()));
			EndIf;
			
			If vRoomTypeRestrictions.Count() > 0 Then
				vEmpty = False;
				For Each vRoomTypeRestriction In vRoomTypeRestrictions Do
					vXMLDocument.WriteStartElement("ns:AvailStatusMessage");
					vXMLDocument.WriteStartElement("ns:StatusApplicationControl");
					vXMLDocument.WriteAttribute("Start",			Format(vRoomTypeRestriction.PeriodFrom,"DF=yyyy-MM-ddTHH:mm:ss"));
					vXMLDocument.WriteAttribute("End",				Format(vRoomTypeRestriction.PeriodTo,"DF=yyyy-MM-ddTHH:mm:ss"));
					vXMLDocument.WriteAttribute("RatePlanCode",		vRoomRate.id);
					vXMLDocument.WriteAttribute("InvTypeCode",		vRoomType.id);                                                            
					vXMLDocument.WriteEndElement(); // StatusApplicationControl
					
					vXMLDocument.WriteStartElement("ns:LengthsOfStay"); // LengthsOfStay
					vXMLDocument.WriteStartElement("ns:LengthOfStay");
					vXMLDocument.WriteAttribute("MinMaxMessageType","SetMinLOS");
					vXMLDocument.WriteAttribute("Time",Format(vRoomTypeRestriction.MLOS,"ND=12; NFD=; NG="));
					vXMLDocument.WriteEndElement();
		
					vXMLDocument.WriteStartElement("ns:LengthOfStay");
					vXMLDocument.WriteAttribute("MinMaxMessageType","SetMaxLOS");
					vXMLDocument.WriteAttribute("Time",Format(vRoomTypeRestriction.MaxLOS,"ND=12; NFD=; NG="));
					vXMLDocument.WriteEndElement();
					vXMLDocument.WriteEndElement(); // LengthsOfStay
									
					vXMLDocument.WriteStartElement("ns:RestrictionStatus");
					If vRoomTypeRestriction.StopSale Then
						vXMLDocument.WriteAttribute("Status", "Close");
					ElsIf vRoomTypeRestriction.CTA Or vRoomTypeRestriction.CTD Then
						vXMLDocument.WriteAttribute("Status", "Close");
						If vRoomTypeRestriction.CTD Then
							vXMLDocument.WriteAttribute("Restriction", "Departure");
						Else
							vXMLDocument.WriteAttribute("Restriction", "Arrival");
						EndIf;
					Else
						vXMLDocument.WriteAttribute("Status", "Open");	
					EndIf;
									
					If vRoomTypeRestriction.MinDaysBeforeCheckIn > 0 Then
						vXMLDocument.WriteAttribute("MinAdvancedBookingOffset", String(vRoomTypeRestriction.MinDaysBeforeCheckIn));
					Else
						vXMLDocument.WriteAttribute("MinAdvancedBookingOffset", "-1");	
					EndIf;
					
					If vRoomTypeRestriction.MaxDaysBeforeCheckIn > 0 Then
						vXMLDocument.WriteAttribute("MaxAdvancedBookingOffset", String(vRoomTypeRestriction.MaxDaysBeforeCheckIn));
					Else
						vXMLDocument.WriteAttribute("MaxAdvancedBookingOffset", "-1");	
					EndIf;
					
					vXMLDocument.WriteEndElement(); // RestrictionStatus
									
					vXMLDocument.WriteEndElement(); // AvailStatusMessage
				EndDo;
			EndIf;
		EndDo;
	EndDo;
	
	vXMLDocument.WriteEndElement(); // AvailStatusMessages
	vXMLDocument.WriteEndElement(); // OTA_HotelAvailNotifRQ
	vXMLDocument.WriteEndElement(); // Body				
	vXMLDocument.WriteEndElement(); // Envelope
	
	rRoomRates 	= vRoomRates;
	rRoomTypes	= vRoomTypes;
	
	If Not vEmpty Then
		vResult = vXMLDocument.Close();
	EndIf;
	
	Return vResult;
	
EndFunction // GetRestrictionsRequest

// -------------------------------------------------------------------------
Function GetPricesRequest(pInteractionParameters, pHotelCode, pLanguageID, pVersion, pPeriodFrom, pPeriodTo, pFullUpdate = False, pUpdateCachedPrices = False, rRoomRates = Undefined, rRoomTypes = Undefined, pRoomTypes = Undefined, pRoomRates = Undefined, pUsePriceTags = False)
	
	vResult = "";
	vEmpty	= True;
	
	vRoomTypes 				= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "roomtypes");
	vRoomRates 				= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "roomrates");
	vBaseByGuestAmt 		= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "BaseByGuestAmt");
	vAdditionalGuestAmount 	= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "AdditionalGuestAmount");
	vCurrencies				= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "Currencies");
	
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
	
	vAccTemplates = New ValueTable();
	vAccTemplates.Columns.Add("AccommodationTemplate", cmGetCatalogTypeDescription("AccommodationTemplates"));
	vAccTemplates.Columns.Add("AccommodationTemplateCode", cmGetStringTypeDescription(10));
	For Each vRow In vBaseByGuestAmt Do
		If vAccTemplates.Find(vRow.RefKey1, "AccommodationTemplate") = Undefined Then
			vAccTemplatesRow = vAccTemplates.Add();
			vAccTemplatesRow.AccommodationTemplate = vRow.RefKey1;
			vAccTemplatesRow.AccommodationTemplateCode = TrimR(vRow.RefKey1.Code);
		EndIf;
	EndDo;
	
	vAccTypes = New Array;
	For Each vRow In vAdditionalGuestAmount Do
		If vAccTypes.Find(vRow.RefKey1) = Undefined Then
			vAccTypes.Add(vRow.RefKey1);	
		EndIf;
	EndDo;
	
	vXMLDocument = New XMLWriter;
	vXMLDocument.SetString();
	
	vXMLDocument.WriteStartElement("soapenv:Envelope");
	vXMLDocument.WriteAttribute("xmlns:soapenv", "http://schemas.xmlsoap.org/soap/envelope/");
	vXMLDocument.WriteAttribute("xmlns:tlc", "https://www.travelline.ru/Api/TLConnect");
	vXMLDocument.WriteAttribute("xmlns:ns", "http://www.opentravel.org/OTA/2003/05");
	vXMLDocument.WriteStartElement("soapenv:Header");
	vXMLDocument.WriteStartElement("tlc:Security");
	vXMLDocument.WriteAttribute("Username", pInteractionParameters.Login);
	vXMLDocument.WriteAttribute("Password", pInteractionParameters.Password);
	vXMLDocument.WriteEndElement(); // Security
	vXMLDocument.WriteEndElement(); // Header
	vXMLDocument.WriteStartElement("soapenv:Body");
	
	vXMLDocument.WriteStartElement("ns:OTA_HotelRateAmountNotifRQ");
	vXMLDocument.WriteAttribute("Version", pVersion);
	vXMLDocument.WriteAttribute("PrimaryLangID",pLanguageID);
	vXMLDocument.WriteAttribute("TimeStamp", Format(CurrentSessionDate(), "DF=yyyy-MM-ddTHH:mm:ss"));
	
	vXMLDocument.WriteStartElement("ns:RateAmountMessages");
	vXMLDocument.WriteAttribute("HotelCode",pHotelCode);
		   
	For Each vRoomRate In vRoomRates Do
		If Not vRoomRates.Columns.Find("Unload") = Undefined Then
			If vRoomRate.Unload = False Then
				Continue;
			EndIf;	
		EndIf;
		vPricesByAccTypes 		= ChannelManagers.GetPrices(pInteractionParameters, vRoomRate.RefKey1, pPeriodFrom, pPeriodTo, pFullUpdate, pUpdateCachedPrices, , ?(pUsePriceTags, vRoomRate.RefKey2, Undefined));
		vPricesByAccTemplates	= CalculatePricesByAccommodationTemplates(vPricesByAccTypes, vAccTemplates, vRoomRate.RefKey1, pInteractionParameters.Hotel);
		vPricesByAccTemplates	= CollapsePeriodTable(vPricesByAccTemplates);
		vPricesByAccTypes.Sort("RoomTypeSortCode, AccommodationTypeSortCode, CurrencyCode, Period");
		vPricesByAccTypes	= CollapsePeriodTable(vPricesByAccTypes);
		vPricesByAccTypes	= FilterPricesTableByTypes(vPricesByAccTypes, vAccTypes);
		
		For Each vRoomType In vRoomTypes Do	
			// By accommodation templates
			vPricesByRoomTypeByAccTmp = vPricesByAccTemplates.FindRows(New Structure("RoomType", vRoomType.RefKey1));

			// By accommodation types
			vPricesByRoomTypeByAccTypes = vPricesByAccTypes.FindRows(New Structure("RoomType", vRoomType.RefKey1));
			
			If vPricesByRoomTypeByAccTmp.Count() = 0 And vPricesByRoomTypeByAccTypes.Count() = 0 Then
				Continue;
			EndIf;
			
			vXMLDocument.WriteStartElement("ns:RateAmountMessage");
			
			vXMLDocument.WriteStartElement("ns:StatusApplicationControl");				
			vXMLDocument.WriteAttribute("InvTypeCode",	vRoomType.id);
			vXMLDocument.WriteAttribute("RatePlanCode",	vRoomRate.id);
			vXMLDocument.WriteEndElement(); // StatusApplicationControl
			
			vXMLDocument.WriteStartElement("ns:Rates");
						
			For Each vPrices In vPricesByRoomTypeByAccTmp Do
				vEmpty = False;
				
				If Not ValueIsFilled(vPrices.PeriodFrom) Or Not ValueIsFilled(vPrices.PeriodTo) Then
					Continue;
				EndIf;
				
				If vCurrencies.Count() > 0 Then
					vCurrencyRow 	= vCurrencies.Find(vPrices.Currency, "RefKey1");
					vCurrencyCode 	= vCurrencyRow.id;
				Else
					vCurrencyCode	= vDefaultCurrencyCode;
				EndIf;
				
				vXMLDocument.WriteStartElement("ns:Rate");
				
				vXMLDocument.WriteAttribute("Start",Format(vPrices.PeriodFrom, "DF=yyyy-MM-dd")); 
				vXMLDocument.WriteAttribute("End",Format(vPrices.PeriodTo, "DF=yyyy-MM-dd"));
				
				vXMLDocument.WriteStartElement("ns:BaseByGuestAmts");
				For Each vBaseByGuestAmtRow In vBaseByGuestAmt Do
					If vPrices.AccommodationTemplate = vBaseByGuestAmtRow.RefKey1 Then
						vXMLDocument.WriteStartElement("ns:BaseByGuestAmt");						
						vXMLDocument.WriteAttribute("AmountAfterTax", Format(vPrices.Price, "ND=15; NFD=2; NDS=.; NZ=0; NG="));
						vXMLDocument.WriteAttribute("CurrencyCode", vCurrencyCode);
						vXMLDocument.WriteAttribute("NumberOfGuests", Format(vBaseByGuestAmtRow.GuestAmount, "NG="));					
						vXMLDocument.WriteEndElement(); // BaseByGuestAmt  SinglePrice
					EndIf;
				EndDo;
								
				vXMLDocument.WriteEndElement(); // BaseByGuestAmts
				vXMLDocument.WriteEndElement(); // Rate
			EndDo;
			
			For Each vPrices In vPricesByRoomTypeByAccTypes Do
				vEmpty = False;
				
				If Not ValueIsFilled(vPrices.PeriodFrom) Or Not ValueIsFilled(vPrices.PeriodTo) Then
					Continue;
				EndIf;

				If vCurrencies.Count() > 0 Then
					vCurrencyRow 	= vCurrencies.Find(vPrices.Currency, "RefKey1");
					vCurrencyCode 	= vCurrencyRow.id;
				Else
					vCurrencyCode	= vDefaultCurrencyCode;
				EndIf;
		
				vXMLDocument.WriteStartElement("ns:Rate");
				
				vXMLDocument.WriteAttribute("Start",Format(vPrices.PeriodFrom,"DF=yyyy-MM-dd"));
				vXMLDocument.WriteAttribute("End",Format(vPrices.PeriodTo,"DF=yyyy-MM-dd"));
				
				vThereisBase = False;				
				For Each vAdditionalGuestAmountRow In vAdditionalGuestAmount Do
					If vAdditionalGuestAmountRow.isBaseBedAmount = True Then						
						If vPrices.AccommodationType = vAdditionalGuestAmountRow.RefKey1 Then
							
							If Not vThereisBase Then
								vThereisBase = True;
								vXMLDocument.WriteStartElement("ns:BaseByGuestAmts");
							EndIf;
							
							vXMLDocument.WriteStartElement("ns:BaseByGuestAmt");
							
							vXMLDocument.WriteAttribute("AmountAfterTax", Format(vPrices.Price, "ND=15; NFD=2; NDS=.; NZ=0; NG="));
							vXMLDocument.WriteAttribute("CurrencyCode",	vCurrencyCode);
							
							If vAdditionalGuestAmountRow.MinAge > 0 Or vAdditionalGuestAmountRow.MaxAge > 0 Then
								vXMLDocument.WriteAttribute("MinAge", Format(vAdditionalGuestAmountRow.MinAge, "NZ=0; NG="));
								vXMLDocument.WriteAttribute("MaxAge", Format(vAdditionalGuestAmountRow.MaxAge, "NZ=0; NG="));
							EndIf;
							
							vXMLDocument.WriteEndElement(); // BaseByGuestAmt  InfantPrice
						EndIf;
					EndIf;
				EndDo;	
				
				If vThereisBase Then
					vXMLDocument.WriteEndElement(); // BaseByGuestAmts
				EndIf;
				
				vThereisAdd = False;				
				For Each vAdditionalGuestAmountRow In vAdditionalGuestAmount Do
					If vAdditionalGuestAmountRow.isBaseBedAmount = False Then
						If vPrices.AccommodationType = vAdditionalGuestAmountRow.RefKey1 Then
							
							If Not vThereisAdd Then
								vThereisAdd = True;
								vXMLDocument.WriteStartElement("ns:AdditionalGuestAmounts");
							EndIf;

							vXMLDocument.WriteStartElement("ns:AdditionalGuestAmount");
							
							vXMLDocument.WriteAttribute("AmountAfterTax", Format(vPrices.Price, "ND=15; NFD=2; NDS=.; NZ=0; NG="));
							vXMLDocument.WriteAttribute("CurrencyCode", vCurrencyCode);
							
							If vAdditionalGuestAmountRow.MinAge > 0 Or vAdditionalGuestAmountRow.MaxAge > 0 Then 
								vXMLDocument.WriteAttribute("MinAge", Format(vAdditionalGuestAmountRow.MinAge, "NZ=0; NG="));
								vXMLDocument.WriteAttribute("MaxAge", Format(vAdditionalGuestAmountRow.MaxAge, "NZ=0; NG="));
							EndIf;

							If vAdditionalGuestAmountRow.MaxAdditionalGuests > 0 Then 
								vXMLDocument.WriteAttribute("MaxAdditionalGuests",Format(vAdditionalGuestAmountRow.MaxAdditionalGuests, "NG="));
							EndIf;
							If vAdditionalGuestAmountRow.isBedRequired = True Then 
								vXMLDocument.WriteAttribute("BedRequired", "1");
							Else
								vXMLDocument.WriteAttribute("BedRequired","0");	
							EndIf;

							vXMLDocument.WriteEndElement(); // AdditionalGuestAmount  ExtraInfantPrice
						EndIf;
					EndIf;
				EndDo;
				If vThereisAdd Then
					vXMLDocument.WriteEndElement(); // AdditionalGuestAmounts
				EndIf;
				vXMLDocument.WriteEndElement(); // Rate
			EndDo;
			vXMLDocument.WriteEndElement(); // Rates
			vXMLDocument.WriteEndElement(); // RateAmountMessage
		EndDo;
	EndDo;
	
	vXMLDocument.WriteEndElement(); // RateAmountMessages
	vXMLDocument.WriteEndElement(); // OTA_HotelRateAmountNotifRQ
	vXMLDocument.WriteEndElement(); // Body				
	vXMLDocument.WriteEndElement(); // Envelope
	
	rRoomRates 	= vRoomRates;
	rRoomTypes	= vRoomTypes;
	
	If Not vEmpty Then
		vResult = vXMLDocument.Close();
	EndIf;
	
	Return vResult;
EndFunction // GetPricesRequest

// -------------------------------------------------------------------------
Function GetReservationsRequest(pInteractionParameters, pHotelCode, pVersion)
	
	vResult = "";

	vXMLDocument = New XMLWriter;
	vXMLDocument.SetString();
		
	vXMLDocument.WriteStartElement("soapenv:Envelope");
	vXMLDocument.WriteAttribute("xmlns:soapenv", "http://schemas.xmlsoap.org/soap/envelope/");
	vXMLDocument.WriteAttribute("xmlns:tlc", "https://www.travelline.ru/Api/TLConnect");
	vXMLDocument.WriteAttribute("xmlns:ns", "http://www.opentravel.org/OTA/2003/05");
		vXMLDocument.WriteStartElement("soapenv:Header");
			vXMLDocument.WriteStartElement("tlc:Security");
				vXMLDocument.WriteAttribute("Username",	pInteractionParameters.Login);
				vXMLDocument.WriteAttribute("Password",	pInteractionParameters.Password);
			vXMLDocument.WriteEndElement(); // Security
		vXMLDocument.WriteEndElement(); // Header
		vXMLDocument.WriteStartElement("soapenv:Body");		
			vXMLDocument.WriteStartElement("ns:OTA_ReadRQ");
			vXMLDocument.WriteAttribute("Version", pVersion);
			vXMLDocument.WriteAttribute("xmlns:ns", "http://www.opentravel.org/OTA/2003/05");
				vXMLDocument.WriteStartElement("ns:ReadRequests");
					vXMLDocument.WriteStartElement("ns:HotelReadRequest");
					vXMLDocument.WriteAttribute("HotelCode", pHotelCode);
						vXMLDocument.WriteStartElement("ns:SelectionCriteria");
						vXMLDocument.WriteAttribute("SelectionType","Undelivered");
						vXMLDocument.WriteEndElement(); // SelectionCriteria
					vXMLDocument.WriteEndElement(); // HotelReadRequest
				vXMLDocument.WriteEndElement(); // ReadRequests
			vXMLDocument.WriteEndElement(); // ReadRQ
		vXMLDocument.WriteEndElement(); // Body				
	vXMLDocument.WriteEndElement(); // Envelope
		
	vResult = vXMLDocument.Close();

	Return vResult;
EndFunction // GetReservationsRequest

// -------------------------------------------------------------------------
Function GetConfirmReservationsRequest(pInteractionParameters, pHotelCode, pVersion, pReservations)
	
	vResult = "";

	vXMLDocument = New XMLWriter;
	vXMLDocument.SetString();
		
	vXMLDocument.WriteStartElement("soapenv:Envelope");
	vXMLDocument.WriteAttribute("xmlns:soapenv", "http://schemas.xmlsoap.org/soap/envelope/");
	vXMLDocument.WriteAttribute("xmlns:tlc", "https://www.travelline.ru/Api/TLConnect");
	vXMLDocument.WriteAttribute("xmlns:ns", "http://www.opentravel.org/OTA/2003/05");
		vXMLDocument.WriteStartElement("soapenv:Header");
			vXMLDocument.WriteStartElement("tlc:Security");
				vXMLDocument.WriteAttribute("Username",	pInteractionParameters.Login);
				vXMLDocument.WriteAttribute("Password",	pInteractionParameters.Password);
			vXMLDocument.WriteEndElement(); // Security
		vXMLDocument.WriteEndElement(); // Header
	vXMLDocument.WriteStartElement("soapenv:Body");
	
	vXMLDocument.WriteStartElement("OTA_NotifReportRQ"); // OTA_HotelAvailRQ    OTA_NotifReportRQ
	vXMLDocument.WriteAttribute("Version", Version(pInteractionParameters));
	vXMLDocument.WriteAttribute("xmlns", "http://www.opentravel.org/OTA/2003/05");
	vXMLDocument.WriteAttribute("EchoToken", "echo");
	
	vXMLDocument.WriteStartElement("Success");
	vXMLDocument.WriteEndElement(); // Success    
	
	vXMLDocument.WriteStartElement("ns:NotifDetails");
	vXMLDocument.WriteAttribute("HotelCode", pHotelCode);
	vXMLDocument.WriteStartElement("ns:HotelNotifReport");
	vXMLDocument.WriteStartElement("ns:HotelReservations");
	
	For Each vReservation In pReservations Do
		
		vXMLDocument.WriteStartElement("ns:HotelReservation");
			
		vXMLDocument.WriteAttribute("CreateDateTime", 		Format(vReservation.CreateDateTime, "DF=yyyy-MM-ddTHH:mm:ss"));
		vXMLDocument.WriteAttribute("LastModifyDateTime", 	vReservation.LastModifyDateTime);		
		vXMLDocument.WriteAttribute("ResStatus", 			vReservation.ResStatus);
		
		vXMLDocument.WriteStartElement("ns:UniqueID");
		vXMLDocument.WriteAttribute("Type", "14");
		vXMLDocument.WriteAttribute("ID", vReservation.UniqueID);
		vXMLDocument.WriteEndElement(); // UniqueID
				
		vXMLDocument.WriteStartElement("ns:ResGlobalInfo");
		If IsBlankString(vReservation.Error) Then
			vXMLDocument.WriteStartElement("ns:HotelReservationIDs");
			
			vXMLDocument.WriteStartElement("ns:HotelReservationID");
			vXMLDocument.WriteAttribute("ResID_Type", "14");
			vXMLDocument.WriteAttribute("ResID_Value", String(vReservation.GuestGroupCode));
			vXMLDocument.WriteEndElement(); // HotelReservationID
			
			vXMLDocument.WriteEndElement(); // HotelReservationIDs
		Else
			vXMLDocument.WriteStartElement("ns:Comments");
			
			vXMLDocument.WriteStartElement("ns:Comment");
			vXMLDocument.WriteStartElement("ns:Text");
			vXMLDocument.WriteText(vReservation.Error);
			vXMLDocument.WriteEndElement(); // Text
			vXMLDocument.WriteEndElement(); // Comment
			
			vXMLDocument.WriteEndElement(); // Comments
		EndIf;
		vXMLDocument.WriteEndElement(); // ResGlobalInfo
		vXMLDocument.WriteEndElement(); // HotelReservation
	EndDo;	
	vXMLDocument.WriteEndElement(); // HotelReservations
	vXMLDocument.WriteEndElement(); // HotelNotifReport
	vXMLDocument.WriteEndElement(); // NotifDetails
	vXMLDocument.WriteEndElement(); // Ns:OTA_NotifReportRQ
	vXMLDocument.WriteEndElement(); // Soapenv:Body
	vXMLDocument.WriteEndElement(); // Soapenv:Envelope
	
	vResult = vXMLDocument.Close();

	Return vResult;
EndFunction // GetConfirmReservationsRequest

// -------------------------------------------------------------------------
Function CheckResultBody(pResonseMap, pMessageName)
	
	vResult = New Structure("Success, Error, Warning", False, "", "");
	
	If pResonseMap <> Undefined Then
		vPathArray		= New Array;
		vPathArray.Add("s:Envelope");
		vPathArray.Add("s:Body");
		vPathArray.Add(pMessageName);		
		vResultBody	= Catalogs.DataConvertationRules.GetMapValueByArrayPath(pResonseMap, vPathArray);
		If vResultBody <> Undefined Then
			
			vSuccess 	= vResultBody.Get("Success");
			If vSuccess <> Undefined Then
				vResult.Success = True;
			EndIf;
			
			vWarnings 	= vResultBody.Get("Warnings");
			If vWarnings <> Undefined Then
				vWarningsArray = PropertyToArray(vWarnings.Get("Warning"));
				For Each vWarning In vWarningsArray Do
					vText = vWarning.Get("__TextValue");
					vResult.Warning = vResult.Warning + vText + Chars.LF;	
				EndDo;
			EndIf;

			vErrors = vResultBody.Get("Errors");
			If vErrors <> Undefined Then
				vErrorsArray = PropertyToArray(vErrors.Get("Error"));
				For Each vError In vErrorsArray Do
					vText = vError.Get("__TextValue");
					vResult.Error = vResult.Error + vText + Chars.LF;	
				EndDo;
			EndIf;
		Else
			vResult.Error = "Response body is empty!";
		EndIf;
	Else
		vResult.Error = "Response body is empty!";
	EndIf;
	
	Return vResult;
EndFunction // CheckResultBody

// -------------------------------------------------------------------------
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
EndFunction // CheckResponseStatus

// -------------------------------------------------------------------------
Function PropertyToArray(pValue)
	
	vResult  = New Array;
	
	If TypeOf(pValue) = Type("Array") Then
		vResult = pValue;
	Else
		vResult.Add(pValue);
	EndIf;
	
	Return vResult;
	
EndFunction // PropertyToArray

// -------------------------------------------------------------------------
Function CollapsePeriodTable(pTable, pPeriodColumnName = "Period")
	
	pTable.Columns.Add("PeriodFrom");	
	pTable.Columns.Add("PeriodTo");
	
	vInd = 0;
	While vInd + 1 < pTable.Count() Do
		If Not ValueIsFilled(pTable[vInd].PeriodFrom) Then
			pTable[vInd].PeriodFrom 	= pTable[vInd][pPeriodColumnName];
			pTable[vInd].PeriodTo 		= pTable[vInd][pPeriodColumnName];
		EndIf; 
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
Function CalculatePricesByAccommodationTemplates(pPricesTable, pAccommodationTemplates, pRoomRate, pHotel)
	// Initialize result table
	vResult = New ValueTable;
	vResult.Columns.Add("AccommodationTemplate", cmGetCatalogTypeDescription("AccommodationTemplates"));
	vResult.Columns.Add("AccommodationTemplateCode", cmGetStringTypeDescription(10));
	vResult.Columns.Add("Period", cmGetDateTimeTypeDescription());
	vResult.Columns.Add("Price", cmGetSumTypeDescription());
	vResult.Columns.Add("RoomType", cmGetCatalogTypeDescription("RoomTypes"));
	vResult.Columns.Add("RoomTypeSortCode", cmGetNumberTypeDescription(8, 0));
	vResult.Columns.Add("Currency", cmGetCatalogTypeDescription("Currencies"));
	vResult.Columns.Add("CurrencyCode", cmGetNumberTypeDescription(3, 0));
	
	vResult.Indexes.Add("RoomType, AccommodationTemplate, Currency, Period");
	vResult.Indexes.Add("RoomTypeSortCode, AccommodationTemplateCode, CurrencyCode, Period");
	
	// Initialize accommodation type overrides cache
	vOvrCache = New ValueTable();
	vOvrCache.Columns.Add("RoomRate", cmGetCatalogTypeDescription("RoomRates"));
	vOvrCache.Columns.Add("Hotel", cmGetCatalogTypeDescription("Hotels"));
	vOvrCache.Columns.Add("AccommodationTemplate", cmGetCatalogTypeDescription("AccommodationTemplates"));
	vOvrCache.Columns.Add("RoomType", cmGetCatalogTypeDescription("RoomTypes"));
	vOvrCache.Columns.Add("Overrides");

	vOvrCache.Indexes.Add("RoomRate, Hotel, AccommodationTemplate, RoomType");
	
	For Each vAccTemplateRow In pAccommodationTemplates Do
		vAccTemplate = vAccTemplateRow.AccommodationTemplate;
		vAccTemplateCode = vAccTemplateRow.AccommodationTemplateCode;
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
				vNewRow 							= vResult.Add();
				vNewRow.AccommodationTemplate 		= vAccTemplate;
				vNewRow.AccommodationTemplateCode 	= vAccTemplateCode;
				vNewRow.Period 						= vPrices.Period;
				vNewRow.RoomType 					= vPrices.RoomType;
				vNewRow.RoomTypeSortCode			= vPrices.RoomTypeSortCode;
				vNewRow.Currency 					= vPrices.Currency;
				vNewRow.CurrencyCode				= vPrices.CurrencyCode;
				vNewRow.Price						= 0;
				
				// Read room rate accommodation type overrides
				vOverrides = New ValueTable();
				vOvrCacheRows = vOvrCache.FindRows(New Structure("RoomRate, Hotel, AccommodationTemplate, RoomType", pRoomRate, pHotel, vNewRow.AccommodationTemplate, vNewRow.RoomType));
				If vOvrCacheRows.Count() = 0 Then
					vOverrides = cmGetRoomRateOverrides(pRoomRate, pHotel, vNewRow.AccommodationTemplate, vNewRow.RoomType);
					
					vOvrCacheRow = vOvrCache.Add();
					vOvrCacheRow.RoomRate = pRoomRate;
					vOvrCacheRow.Hotel = pHotel;
					vOvrCacheRow.AccommodationTemplate = vNewRow.AccommodationTemplate;
					vOvrCacheRow.RoomType = vNewRow.RoomType;
					vOvrCacheRow.Overrides = vOverrides.Copy();
				Else
					vOvrCacheRow = vOvrCacheRows.Get(0);
					vOverrides = vOvrCacheRow.Overrides;
				EndIf;
				
				// Calculate price
				For Each vAccType In vAccTemplate.AccommodationTypes Do
					vAccommodationType = vAccType.AccommodationType;
					If vOverrides.Count() > 0 Then
						vOverrideRows = vOverrides.FindRows(New Structure("AccommodationType, TemplateLineNumber", vAccommodationType, vAccTemplate.AccommodationTypes.IndexOf(vAccType) + 1));
						If vOverrideRows.Count() > 0 And ValueIsFilled(vOverrideRows.Get(0).ToAccommodationType) Then
							vAccommodationType = vOverrideRows.Get(0).ToAccommodationType;
						EndIf;
					EndIf;
					vPricesRows = pPricesTable.FindRows(New Structure("Period, RoomType, AccommodationType, Currency", vPrices.Period, vPrices.RoomType, vAccommodationType, vPrices.Currency));
					For Each vPriceRow In vPricesRows Do
						vNewRow.Price = vNewRow.Price + vPriceRow.Price; 
					EndDo;
				EndDo;
			EndIf;
		EndDo;	
	EndDo;

	vResult.Sort("RoomTypeSortCode, AccommodationTemplateCode, CurrencyCode, Period");
	
	Return vResult;
EndFunction // CalculatePricesByAccommodationTemplates

// -------------------------------------------------------------------------
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

// -------------------------------------------------------------------------
Function GetGuestTable(pResGuests)
	
	vResult	= New ValueTable;
	vResult.Columns.Add("ResGuestRPH");
	vResult.Columns.Add("FirstName");
	vResult.Columns.Add("SecondName");
	vResult.Columns.Add("LastName");
	vResult.Columns.Add("Citizenship");
	vResult.Columns.Add("Gender");
	vResult.Columns.Add("BirthDate"); 
	vResult.Columns.Add("GuestID");

	vGuestsArray = PropertyToArray(pResGuests.Get("ResGuest"));
	For Each vGuest In vGuestsArray Do
		If vGuest <> Undefined Then
			vNewRow = vResult.Add();
			vNewRow.ResGuestRPH = vGuest.Get("ResGuestRPH");
			
			vPathArray	= New Array;
			vPathArray.Add("Profiles");
			vPathArray.Add("ProfileInfo");
			vPathArray.Add("Profile");	
			vPathArray.Add("Customer");
			vGuestDetailsMap = Catalogs.DataConvertationRules.GetMapValueByArrayPath(vGuest, vPathArray);
			
			vNewRow.Gender = vGuestDetailsMap.Get("Gender");
			vNewRow.BirthDate = vGuestDetailsMap.Get("BirthDate");
			
			vPathArray	= New Array;
			vPathArray.Add("CitizenCountryName");
			vPathArray.Add("Code");
			vNewRow.Citizenship = Catalogs.DataConvertationRules.GetMapValueByArrayPath(vGuestDetailsMap, vPathArray);
			
			vPathArray	= New Array;
			vPathArray.Add("PersonName");
			vPathArray.Add("GivenName");
			vPathArray.Add("__TextValue");
			vNewRow.FirstName = Catalogs.DataConvertationRules.GetMapValueByArrayPath(vGuestDetailsMap, vPathArray);
			
			vPathArray	= New Array;
			vPathArray.Add("PersonName");
			vPathArray.Add("MiddleName");
			vPathArray.Add("__TextValue");
			vNewRow.SecondName = Catalogs.DataConvertationRules.GetMapValueByArrayPath(vGuestDetailsMap, vPathArray);
			
			vPathArray	= New Array;
			vPathArray.Add("PersonName");
			vPathArray.Add("Surname");
			vPathArray.Add("__TextValue");
			vNewRow.LastName = Catalogs.DataConvertationRules.GetMapValueByArrayPath(vGuestDetailsMap, vPathArray);	
			
			vPathArray	= New Array;   
			vPathArray.Add("Profiles");
			vPathArray.Add("ProfileInfo");
			vPathArray.Add("UniqueID");
			vPathArray.Add("ID");     
			vNewRow.GuestID = Catalogs.DataConvertationRules.GetMapValueByArrayPath(vGuest, vPathArray);
		EndIf;
	EndDo;
	
	Return vResult;
EndFunction // GetGuestTable

// -------------------------------------------------------------------------
Function GetReservationComment(pCommentsMap)
	
	vResult = "";
	
	If pCommentsMap <> Undefined Then
		vCommentsArray	= PropertyToArray(pCommentsMap.Get("Comment"));
		For Each vCommentData In vCommentsArray Do
			If vCommentData <> Undefined Then
				vPathArray	= New Array;
				vPathArray.Add("Text");
				vPathArray.Add("__TextValue");
				vCommentText = Catalogs.DataConvertationRules.GetMapValueByArrayPath(vCommentData, vPathArray);
				If vCommentText <> Undefined Then
					vResult = vResult + vCommentText + Chars.LF;
				EndIf;
			EndIf;
		EndDo;		
	EndIf;
	
	Return vResult;
EndFunction // GetReservationComment

// -------------------------------------------------------------------------
Function GetDiscountText(pDiscountsMap)
	
	vResult = "";
	
	If pDiscountsMap <> Undefined Then
		vDiscountReason = pDiscountsMap.Get("DiscountReason");
		If vDiscountReason <> Undefined Then
			vPathArray	= New Array;
			vPathArray.Add("Text");
			vPathArray.Add("__TextValue");
			vDiscountText = Catalogs.DataConvertationRules.GetMapValueByArrayPath(vDiscountReason, vPathArray);
			If vDiscountText <> Undefined Then
				vResult = vResult + vDiscountText + Chars.LF;
			EndIf;
		EndIf;
	EndIf;
	
	Return vResult;
EndFunction // GetDiscountText

// -------------------------------------------------------------------------
Function GetCustomerData(pCustomerMap)

	vResult = New Structure;
	vResult.Insert("FirstName", "");
	vResult.Insert("SecondName", "");
	vResult.Insert("LastName", "");
	vResult.Insert("Email", "");
	vResult.Insert("Phone", "");
	
	vPathArray	= New Array;
	vPathArray.Add("PersonName");
	vPathArray.Add("GivenName");
	vPathArray.Add("__TextValue");
	vResult.FirstName = Catalogs.DataConvertationRules.GetMapValueByArrayPath(pCustomerMap, vPathArray);
		
	vPathArray	= New Array;
	vPathArray.Add("PersonName");
	vPathArray.Add("MiddleName");
	vPathArray.Add("__TextValue");
	vResult.SecondName = Catalogs.DataConvertationRules.GetMapValueByArrayPath(pCustomerMap, vPathArray);
	
	vPathArray	= New Array;
	vPathArray.Add("PersonName");
	vPathArray.Add("Surname");
	vPathArray.Add("__TextValue");
	vResult.LastName = Catalogs.DataConvertationRules.GetMapValueByArrayPath(pCustomerMap, vPathArray);
	
	vPathArray	= New Array;
	vPathArray.Add("Email");
	vPathArray.Add("__TextValue");
	vResult.Email = Catalogs.DataConvertationRules.GetMapValueByArrayPath(pCustomerMap, vPathArray);

	vPathArray	= New Array;
	vPathArray.Add("Telephone");
	vPathArray.Add("PhoneNumber");
	vResult.Phone = Catalogs.DataConvertationRules.GetMapValueByArrayPath(pCustomerMap, vPathArray);

	If vResult.FirstName = Undefined Then
		vResult.FirstName = "";	
	EndIf;

	If vResult.SecondName = Undefined Then
		vResult.SecondName = "";	
	EndIf;

	If vResult.LastName = Undefined Then
		vResult.LastName = "";	
	EndIf;

	If vResult.Email = Undefined Then
		vResult.Email = "";	
	EndIf;

	If vResult.Phone = Undefined Then
		vResult.Phone = "";	
	EndIf;

	Return vResult;
EndFunction // GetCustomerData

// -------------------------------------------------------------------------
Function GetGuestCount(pInteractionParameters, pGuestCounts, pChildrenAgesStruct = Undefined)
	
	vResult = New Structure;
	vResult.Insert("Adults", 0);
	vResult.Insert("Childs", 0);
	vResult.Insert("Infants", 0);
	vResult.Insert("Teenagers", 0);
	vResult.Insert("Ages", New Array);
	
	If pChildrenAgesStruct = Undefined Then
		pChildrenAgesStruct = pInteractionParameters.Hotel;
	EndIf;
	
	vChildAge	  = pChildrenAgesStruct.ChildrenMaxAge;
	vInfantAge	  = pChildrenAgesStruct.InfantsMaxAge;
	vTeenagersAge = pChildrenAgesStruct.TeenagersMaxAge;
	
	vGuestCountArray = PropertyToArray(pGuestCounts.Get("GuestCount"));
	
	For Each vGuest In vGuestCountArray Do
		vAgeQualifier 	= vGuest.Get("AgeQualifyingCode");
		vCount			= Number(vGuest.Get("Count"));
		vAge			= vGuest.Get("Age");
		If vAgeQualifier = "AdultBed" Or vAgeQualifier = "AdultExtraBed" Then
			vResult.Adults = vResult.Adults + vCount;
		ElsIf vAgeQualifier = "ChildBandBed" Or vAgeQualifier = "ChildBandExtraBed" Or vAgeQualifier = "ChildBandWithoutBed" Then
			If vAge = Undefined Then
				vResult.Childs = vResult.Childs + vCount;
				vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation.GetGuestCount", vLogEventType, , , "Failed to get child age");
			Else
				vAge = Number(vAge);
				If vAge = 0 Then
					vAge = 1;
				EndIf;
				If vAge <= vInfantAge Then
					vResult.Infants = vResult.Infants + vCount;
					For i = 1 To vCount Do 
						vResult.Ages.Add(vAge);
					EndDo;
				ElsIf vAge <= vChildAge Then
					vResult.Childs = vResult.Childs + vCount;
					For i = 1 To vCount Do
						vResult.Ages.Add(vAge);
					EndDo;
				ElsIf vAge <= vTeenagersAge Then
					vResult.Teenagers = vResult.Teenagers + vCount;
					For i = 1 To vCount Do
						vResult.Ages.Add(vAge);
					EndDo;
				Else
					vResult.Childs = vResult.Childs + vCount;
					For i = 1 To vCount Do
						vResult.Ages.Add(vAge);
					EndDo;
					vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation.GetGuestCount", vLogEventType, , , "Unknown child age: " + vAge);	
				EndIf;
			EndIf;
		Else
			vResult.Adults = vResult.Adults + vCount;
			vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation.GetGuestCount", vLogEventType, , , "Unknown age qualifier: " + vAgeQualifier);
		EndIf;
	EndDo;
	
	Return vResult;
EndFunction // GetGuestCount

// -------------------------------------------------------------------------
Function ResetXDTOPrices(pPrices)
	
	For Each vPricePerDate In pPrices.PricePerDateRow Do 
		vPricePerDate.Price = 0;
	EndDo;
	
	Return pPrices;
EndFunction // ResetXDTOPrices

// -------------------------------------------------------------------------
Function GetPricesXDTO(pInteractionParameters, pPricesMap)
	
	vResult = New ValueTable;
	vResult.Columns.Add("ResGuestRPH");
	vResult.Columns.Add("PricesXDTO");
	vResult.Columns.Add("RatePlanXDTO");
	vResult.Columns.Add("RatePlanCode");

	vRoomRates = InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "roomrates");
	
	vPricesArray = PropertyToArray(pPricesMap.Get("RoomRate"));
	
	For Each vPrice In vPricesArray Do
		If vPrice <> Undefined Then
			vEffectiveDate 	= vPrice.Get("EffectiveDate");
			vEffectiveDate	= StrReplace(vEffectiveDate, "-", "");
			vPeriodFrom 	= Date(vEffectiveDate);
			
			vExpireDate 	= vPrice.Get("ExpireDate");
			vExpireDate		= StrReplace(vExpireDate, "-", "");
			vPeriodTo 		= Date(vExpireDate); 
			While vPeriodFrom <= vPeriodTo Do
								
				vRatePlanCode	= vPrice.Get("RatePlanCode");
				vTotal			= vPrice.Get("Total");
				vAmountAfterTax	= Round(Number(vTotal.Get("AmountAfterTax")), 2);
								
				vMainPricesRow = vResult.Find(Undefined, "ResGuestRPH");
				If vMainPricesRow = Undefined Then
					vMainPricesRow 				= vResult.Add();
					vMainPricesRow.ResGuestRPH 	= Undefined;
					vMainPricesRow.RatePlanCode = vRatePlanCode;
					vMainPricesRow.PricesXDTO 	= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "PricesPerDate"));
					vMainPricesRow.RatePlanXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "RoomRatePlan"));
				EndIf;

				vPricePerDateRow 			= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "PricePerDateRow"));
				vPricePerDateRow.Date 		= vPeriodFrom;
				vPricePerDateRow.Price 		= vAmountAfterTax;
				vPricePerDateRow.Currency 	= pInteractionParameters.Currency.Code;
				vMainPricesRow.PricesXDTO.PricePerDateRow.Add(vPricePerDateRow);

				vRoomRateRow 	= vRoomRates.Find(vRatePlanCode, "id");
				If vRoomRateRow <> Undefined Then
					vRoomRatePlanPerDate 				= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "RoomRatePlanRow"));	
					vRoomRatePlanPerDate.RoomRateCode 	= vRoomRateRow.RefKey1.Code;
					vRoomRatePlanPerDate.Period 		= vPeriodFrom;		
					vMainPricesRow.RatePlanXDTO.RoomRatePlanRows.Add(vRoomRatePlanPerDate);
				Else
					vError			= "Failed to find roomrates data by ID:" + vRatePlanCode;
					vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation.GetPricesXDTO", vLogEventType, , , vError);
				EndIf;
				
				// Multi rates
				vTPA_Extensions = vPrice.Get("TPA_Extensions");
				If vTPA_Extensions <> Undefined Then
					vPlacementRates = vTPA_Extensions.Get("PlacementRates");
					If vPlacementRates <> Undefined Then
						vPlacementRateArray = PropertyToArray(vPlacementRates.Get("PlacementRate"));
						For Each vPlacementRate In vPlacementRateArray Do
							If vPlacementRate <> Undefined Then
								vResGuestRPH 	= vPlacementRate.Get("ResGuestRPH");
								vRatePlanCode	= vPlacementRate.Get("RatePlanCode");
								vTotal			= vPlacementRate.Get("Total");
								vAmountAfterTax	= Round(Number(vTotal.Get("AmountAfterTax")), 2);
								
								vGuestPricesRow = vResult.Find(vResGuestRPH, "ResGuestRPH");
								If vGuestPricesRow = Undefined Then
									vGuestPricesRow 				= vResult.Add();
									vGuestPricesRow.ResGuestRPH 	= vResGuestRPH;
									vGuestPricesRow.RatePlanCode 	= vRatePlanCode; 
									vGuestPricesRow.PricesXDTO 		= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "PricesPerDate"));
									vGuestPricesRow.RatePlanXDTO 	= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "RoomRatePlan"));									
								EndIf;
								
								vPricePerDateRow 			= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "PricePerDateRow"));
								vPricePerDateRow.Date 		= vPeriodFrom;
								vPricePerDateRow.Price 		= vAmountAfterTax;
								vPricePerDateRow.Currency 	= pInteractionParameters.Currency.Code;
								vGuestPricesRow.PricesXDTO.PricePerDateRow.Add(vPricePerDateRow);
								
								vRoomRateRow 	= vRoomRates.Find(vRatePlanCode, "id");
								If vRoomRateRow <> Undefined Then
									vRoomRatePlanPerDate 				= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "RoomRatePlanRow"));	
									vRoomRatePlanPerDate.RoomRateCode 	= vRoomRateRow.RefKey1.Code;
									vRoomRatePlanPerDate.Period 		= vPeriodFrom;		
									vGuestPricesRow.RatePlanXDTO.RoomRatePlanRows.Add(vRoomRatePlanPerDate);
								Else
									vError			= "Failed to find roomrates data by ID:" + vRatePlanCode;
									vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
									InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation.GetPricesXDTO", vLogEventType, , , vError);
								EndIf;							
							EndIf;
						EndDo;
					EndIf;
				EndIf;
				vPeriodFrom = vPeriodFrom + 24 * 60 * 60;	
			EndDo;
		EndIf;
	EndDo;
	
	Return vResult;
EndFunction // GetPricesXDTO

// -------------------------------------------------------------------------
Function GetServicesTable(pInteractionParameters, pServicesMap)
	
	vResult = New ValueTable;
	vResult.Columns.Add("ServiceRPH");
	vResult.Columns.Add("Service");
	vResult.Columns.Add("Quantity");
	vResult.Columns.Add("Remarks");
	vResult.Columns.Add("ChargeDate");
	vResult.Columns.Add("Price");
	vResult.Columns.Add("ServicePricingType");
	vResult.Columns.Add("Inclusive");

	If pServicesMap = Undefined Then
		Return vResult;
	EndIf;
	
	vServices 	 		= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "services");
	vServicePackages 	= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "servicepackages");
		
	For Each vServPack In vServicePackages Do
		If vServices.Count() > 0 Then
			FillPropertyValues(vServices.Add(), vServPack);
		Else
			vServices = vServicePackages.Copy();
		EndIf;
	EndDo;
	
	vServicesMapArray 	= PropertyToArray(pServicesMap.Get("Service"));
	
	If vServices.Count() = 0 And vServicesMapArray.Count() > 0 Then
		vError			= "Services table mapping is empty! Cant load services.";
		vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation.GetServicesTable", vLogEventType, , , vError);
		Return vResult;
	EndIf;
	
	For Each vServiceMap In vServicesMapArray Do
		vServiceID 			= Format(vServiceMap.Get("ID"), "NG=");
		vService 			= vServices.Find(vServiceID, "id");
		If vService <> Undefined Then
			vServiceRPH			= vServiceMap.Get("ServiceRPH");
			vServicePricingType	= vServiceMap.Get("ServicePricingType");
			vInclusive			= vServiceMap.Get("Inclusive");
			If vInclusive = "true" Then
				vInclusive = True;
			Else
				vInclusive = False
			EndIf;			
			vQuantity			= Number(vServiceMap.Get("Quantity"));
			vServiceDetails 	= vServiceMap.Get("ServiceDetails");
			vServiceTimeSpan 	= vServiceDetails.Get("TimeSpan");
			vChargeDate			= vServiceTimeSpan.Get("Start");
			vChargeDate			= StrReplace(vChargeDate, ".", "");
			vChargeDate			= StrReplace(vChargeDate, "-", "");
			vChargeDate			= Date(Left(vChargeDate, 8));
			vDuration			= Number(vServiceTimeSpan.Get("Duration"));
			
			vPathArray		= New Array;
			vPathArray.Add("Total");
			vPathArray.Add("AmountAfterTax");
			vPrice = Catalogs.DataConvertationRules.GetMapValueByArrayPath(vServiceDetails, vPathArray);

			If vPrice <> Undefined Then
				vPrice = Round(Number(vPrice), 2);
				If vQuantity <> 0 And vDuration <> 0 Then
					vPrice = Round(vPrice/vQuantity/vDuration, 2);
				EndIf;
			Else
				vPrice = 0;
			EndIf;
			
			vRemarks			= "";
			vComments			= vServiceDetails.Get("Comments");
			If vComments <> Undefined Then
				vCommentsArray	= vComments.Get("Comment"); 
				vCommentsArray	= PropertyToArray(vCommentsArray);
				For Each vComment In vCommentsArray Do
					vCommentName 	= vComment.Get("Name"); 
					vPathArray		= New Array;
					vPathArray.Add("Text");
					vPathArray.Add("__TextValue");
					vCommentText = Catalogs.DataConvertationRules.GetMapValueByArrayPath(vComment, vPathArray);
					
					If ValueIsFilled(vCommentName) Then
						vRemarks = vRemarks + "[" + vCommentName + "] ";
					EndIf;
					
					If ValueIsFilled(vCommentText) Then
						vRemarks = vRemarks + vCommentText;
					EndIf;
					
					vRemarks = vRemarks + Chars.LF; 
				EndDo;
			EndIf;
			vOneDay = 24 * 60 * 60;
			For i = 1 To vDuration Do
				vNewRow 					= vResult.Add();
				vNewRow.ServiceRPH			= vServiceRPH;
				vNewRow.Service				= vService.id;
				vNewRow.Quantity			= vQuantity;
				vNewRow.Remarks				= vRemarks;
				vNewRow.ChargeDate			= vChargeDate;
				vNewRow.ServicePricingType	= vServicePricingType;
				vNewRow.Inclusive			= vInclusive;
				vNewRow.Price				= vPrice;
				
				vChargeDate = vChargeDate + vOneDay;
			EndDo;
		Else
			vError			= "Failed to find service by ID: " + vServiceID;
			vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation.GetServicesTable", vLogEventType, , , vError);
			Continue;
		EndIf;
	EndDo;
	
	Return vResult;
EndFunction // GetServicesTable

// -------------------------------------------------------------------------
Function GetPaymentDetails(pInteractionParameters, pResGlobalInfoMap)

	vResult = New Structure;
	vResult.Insert("GuaranteeType", Undefined);
	vResult.Insert("PaymentMethod", Undefined);
	vResult.Insert("LoyaltyPaymentMethod", Undefined);
	vResult.Insert("CurrencyCode", "");
	vResult.Insert("LoyaltyCurrencyCode", "");
	vResult.Insert("Amount", 0);
	vResult.Insert("LoyaltyAmount", 0);
	vResult.Insert("PaymentSystemTitle", "");
	vResult.Insert("LoyaltyPaymentSystemTitle", "");
	vResult.Insert("PaymentExtCode", "");
	vResult.Insert("LoyaltyPaymentExtCode", ""); 
	
	If pResGlobalInfoMap = Undefined Then
		Return vResult;
	EndIf;
	
	vGuarantee 			= pResGlobalInfoMap.Get("Guarantee");	
	If vGuarantee <> Undefined Then
		vGuaranteeCode	= vGuarantee.Get("GuaranteeCode");
		vGuaranteeType 	= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "guarantees", "id", , , vGuaranteeCode); 
		If vGuaranteeType <> Undefined And vGuaranteeType.Count() > 0 Then 
			vResult.GuaranteeType = vGuaranteeType[0].RefKey1;
		ElsIf vGuaranteeCode <> "None" Then
			vError			= "Failed to find guarantee type by id: " + vGuaranteeCode;
			vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation.GetPaymentDetails", vLogEventType, , , vError);	
		EndIf;
		
		vPaymentMethodCode	= Undefined;
		vComments 		= vGuarantee.Get("Comments");
		If vComments <> Undefined Then
			vCommentsArray	= PropertyToArray(vComments.Get("Comment"));
			
			For Each vComment In vCommentsArray Do
				vCommentName = vComment.Get("Name");
				If vCommentName = "PaymentSystemName" Then
					vPathArray	= New Array;
					vPathArray.Add("Text");
					vPathArray.Add("__TextValue");
					vPaymentMethodCode = Catalogs.DataConvertationRules.GetMapValueByArrayPath(vComment, vPathArray);
				ElsIf vCommentName = "PaymentSystemTitle" Then
					vPathArray	= New Array;
					vPathArray.Add("Text");
					vPathArray.Add("__TextValue");
					vResult.PaymentSystemTitle = Catalogs.DataConvertationRules.GetMapValueByArrayPath(vComment, vPathArray);
				ElsIf vCommentName = "PaymentTransactionId" Then
					vPathArray	= New Array;
					vPathArray.Add("Text");
					vPathArray.Add("__TextValue");
					vResult.PaymentExtCode = Catalogs.DataConvertationRules.GetMapValueByArrayPath(vComment, vPathArray);
				EndIf;
			EndDo;
		EndIf;
		If vPaymentMethodCode <> Undefined Then
			vResult.PaymentMethod = GetPaymentMethod(pInteractionParameters, vPaymentMethodCode, vResult.PaymentSystemTitle);
		EndIf;
	EndIf;
	
	vDepositPayments 	= pResGlobalInfoMap.Get("DepositPayments");
	If vDepositPayments <> Undefined Then
		vGuaranteePayment = PropertyToArray(vDepositPayments.Get("GuaranteePayment"));
		For Each vGPayment In vGuaranteePayment Do
			vPaymentType = vGPayment.Get("Type");
			
			If vPaymentType = "ReceivedPayment" Then
				vPathArray	= New Array;
				vPayment = vGPayment.Get("AmountPercent");
				
				vResult.CurrencyCode 	= vPayment.Get("CurrencyCode");
				vResult.Amount 			= Round(Number(vPayment.Get("Amount")), 2);
			ElsIf vPaymentType = "ReceivedLoyaltyPayment" Then
				vPathArray	= New Array;
				vPayment = vGPayment.Get("AmountPercent");
				
				vResult.LoyaltyPaymentSystemTitle = NStr("en = 'Payment of bonuses to the channel manager'; de = 'Auszahlung von Boni an den Channel Manager'; ru = 'Оплата бонусами ченнел менеджеру'");
				vResult.LoyaltyPaymentExtCode 	  = "loyalty";
				vResult.LoyaltyPaymentMethod 	  = GetPaymentMethod(pInteractionParameters, vResult.LoyaltyPaymentExtCode, vResult.LoyaltyPaymentSystemTitle);
				vResult.LoyaltyCurrencyCode 	  = vPayment.Get("CurrencyCode");
				vResult.LoyaltyAmount 			  = Round(Number(vPayment.Get("Amount")), 2);
			EndIf;	
		EndDo;
	EndIf;
	
	Return vResult;
EndFunction // GetPaymentDetails

// -------------------------------------------------------------------------
Function GetPaymentMethod(pInteractionParameters, pPaymentMethodCode, pPaymentSystemTitle)
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
				vExtPM_Obj.Description = "TravelLine " + TrimAll(pPaymentSystemTitle); 
				vExtPM_Obj.ExternalCode = TrimAll(pPaymentMethodCode);    
				vExtPM_Obj.Write();     
				vExtPM = vExtPM_Obj.Ref;
			Except
				vError			= "Failed to create new payment method by id: " + pPaymentMethodCode + Chars.LF + ErrorDescription();
				vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "LoadReservation.GetPaymentDetails", vLogEventType, , , vError);
			EndTry;
		EndIf;
	EndIf;
	
	Return vExtPM;
EndFunction // GetPaymentMethod

// -------------------------------------------------------------------------
Function GetUTMStructureFromURL(pURL)
	
	vResult = New Structure("utm_source, utm_medium, utm_campaign", Undefined, Undefined, Undefined);
	
	vURL	= DecodeString(pURL, StringEncodingMethod.URLEncoding);
	If ValueIsFilled(vURL) Then
		vResult.utm_source 		= GetURLParameter(vURL, "utm_source");	
		vResult.utm_campaign 	= GetURLParameter(vURL, "utm_medium");
		vResult.utm_medium 		= GetURLParameter(vURL, "utm_campaign");
	EndIf;
	
	Return vResult;
EndFunction // GetUTMStructureFromURL

// -------------------------------------------------------------------------
Function GetURLParameter(pURL, pParameterName) 
	
	vResult = Undefined;
	
	vParameterLenght 	= StrLen(pParameterName);
	vParameterStarPos 	= StrFind(pURL, pParameterName);
	If vParameterStarPos > 0 Then
		vValueStartPos 	= vParameterStarPos + vParameterLenght + 1;
		vCurrentCharPos	= vValueStartPos;
		vValueCharCount	= 0;
		vCurrentChar 	= Mid(pURL, vCurrentCharPos, 1);
		While vCurrentChar <> "?" And vCurrentChar <> "&" And vCurrentChar <> "" Do
			vCurrentChar = Mid(pURL, vCurrentCharPos, 1);
			vCurrentCharPos = vCurrentCharPos + 1;
			vValueCharCount = vValueCharCount + 1;
		EndDo;
		
		vResult = Mid(pURL, vValueStartPos, vValueCharCount - 1); 
	EndIf;
	
	Return vResult;
EndFunction // GetURLParameter

#EndRegion
