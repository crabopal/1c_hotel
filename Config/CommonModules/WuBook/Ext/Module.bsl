 
#Region Public

// --------------------------------------------------------------------------------
//  Sync change
//
// Parameters:
//  pUsername					 - String	 - Channel manager login
//  pPassword					 - String	 - Channel manager password
//  pHTTPHost					 - String	 - Channel manager WS-host
//  pRequestorID				 - String	 - Channel manager requestor ID
//  pHotelCode					 - String	 - Hotel code in channel manager system
//  pInteractionParameters		 - CatalogRef.ExternalSystemInteractions - ExternalSystemInteractions ref
//  pSyncInventory				 - Boolean	 - 
//  pSyncRates					 - Boolean	 - 
//  pSyncRestrictions			 - Boolean	 - 
//  pSyncPeriod					 - Boolean	 - 
//  pGetReservations			 - Boolean	 - 
//  pGetVacantRoomsAtMidnight	 - Boolean	 - 
// 
// Returns:
//  Structure - Structure of arrays RoomInventory
//
Function SyncChanges(pUsername, pPassword, pHTTPHost, pRequestorID, pHotelCode, pInteractionParameters, pSyncInventory, pSyncRates, pSyncRestrictions, pSyncPeriod, pGetReservations, pGetVacantRoomsAtMidnight = False) Export
	WriteLogEvent(pInteractionParameters.InteractionID + "SyncChanges", EventLogLevel.Information, , CurrentSessionDate(), "Started only changes and reservations sync");
	vResult = New Structure("RoomInventory, RoomRates, RoomRestrictions, Reservations", New Array, New Array, New Array, New Array);
	
	vSyncTable = ChannelManagers.GetDateTablesToSync(pInteractionParameters, pSyncRates, False, pSyncPeriod, pGetVacantRoomsAtMidnight);
	vReservationError = "";
	vRoomInventoryError = "";
	vRoomRateError = "";
	vLastSyncDate = CurrentSessionDate();
	
	#Region Reservations
	Try
		If pGetReservations Then
			FetchBookings(pInteractionParameters, pHotelCode, False);
		EndIf;
	Except
		vReservationError = ErrorDescription();	
	EndTry;
	#EndRegion
		
	#Region RoomInventory
	Try
		If pSyncInventory Then 
			vSyncTable.RoomInventory = FilterRoomTypesTable(vSyncTable.RoomInventory, pInteractionParameters.Hotel, pInteractionParameters.InteractionID);
			If vSyncTable.RoomInventory.Count() > 0 Then
				vBalanceResult = Undefined;
				For Each vRoomInventoryRow In vSyncTable.RoomInventory Do
					If vBalanceResult = Undefined Then 
						vBalanceResult = GetBalances(vRoomInventoryRow.Hotel, pInteractionParameters.Allotment, vRoomInventoryRow.PeriodFrom, vRoomInventoryRow.PeriodTo, pInteractionParameters.InteractionID, vRoomInventoryRow.RoomType, pGetVacantRoomsAtMidnight);
					Else
						vBalance = GetBalances(vRoomInventoryRow.Hotel, pInteractionParameters.Allotment, vRoomInventoryRow.PeriodFrom, vRoomInventoryRow.PeriodTo, pInteractionParameters.InteractionID, vRoomInventoryRow.RoomType, pGetVacantRoomsAtMidnight);
						For Each vBalanceRow In vBalance Do
							vNewRow = vBalanceResult.Add();
							FillPropertyValues(vNewRow,vBalanceRow);
						EndDo;
					EndIf;
				EndDo;
				
				vAvailability = New ValueTable;
				vAvailability.Columns.Add("Hotel");
				vAvailability.Columns.Add("RoomType");
				vAvailability.Columns.Add("RoomTypeCode");
				vAvailability.Columns.Add("Period");
				vAvailability.Columns.Add("BookingLimit");
				vAvailability.Columns.Add("RoomsVacant");
				vAvailability.Columns.Add("BedsVacant");
				
				For Each vBalanceResultRow In vBalanceResult Do
					vCurrentDate			= BegOfDay(vBalanceResultRow.PeriodFrom);
					vRoomTypeCodes			= GetAllExternalRoomTypesCodes(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, vBalanceResultRow.RoomType);
					While BegOfDay(vCurrentDate) <= BegOfDay(vBalanceResultRow.PeriodTo) Do
						For Each vRoomTypeRow In vRoomTypeCodes Do
							vNewRow 				= vAvailability.Add();
							vNewRow.Hotel			= pInteractionParameters.Hotel; 					
							vNewRow.RoomType	 	= vBalanceResultRow.RoomType;
							vNewRow.RoomTypeCode 	= vRoomTypeRow.ObjectExternalCode; 					
							vNewRow.Period 			= vCurrentDate;
							vNewRow.BookingLimit 	= vBalanceResultRow.VacantRooms;
							vNewRow.RoomsVacant 	= vBalanceResultRow.VacantRooms;
							vNewRow.BedsVacant 		= vBalanceResultRow.VacantBeds;
						EndDo;
						
						vCurrentDate = vCurrentDate + 24 * 60 * 60;
					EndDo;
				EndDo;
				
				vVirtualCodes = GetVirtualObjects(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, "RoomTypes");
				vClearArray = New Array;
				For Each vAvailRow In vAvailability Do
					For Each vVirtualRow In vVirtualCodes Do
						If vAvailRow.RoomTypeCode = vVirtualRow.ObjectExternalCode Then
							vClearArray.Add(vAvailRow);
							Break;
						EndIf;
					EndDo;
				EndDo;
				For Each vClearRow In vClearArray Do
					vAvailability.Delete(vClearRow);
				EndDo;
				vClearArray = Undefined;
				
				vAvailability.Sort("RoomTypeCode, Period");
				
				If vAvailability.Count() > 0 Then
					UpdateRoomsValues(pInteractionParameters, pHotelCode, vAvailability, vResult.RoomInventory);
				EndIf;
			EndIf;
		EndIf;
	Except
		vRoomInventoryError = ErrorDescription();	
	EndTry;
	#EndRegion
		
	#Region RoomRate   
	vDaySec = 24 * 60 * 60;
	Try
		If pSyncRates Then 
			vSyncTable.RoomRate = FilterRatesTable(vSyncTable.RoomRate, pInteractionParameters.Hotel, pInteractionParameters.InteractionID);
			If vSyncTable.RoomRate.Count() > 0 Then
				vRatesResult = Undefined;
				For Each vRoomRateRow In vSyncTable.RoomRate Do
					FillDailyPrices(pInteractionParameters, vRoomRateRow.Hotel, vRoomRateRow.RoomRate, Undefined, vRoomRateRow.PeriodFrom, vRoomRateRow.PeriodTo + vDaySec);
					vAccommodationsToSync = GetAllExternalRoomTypesCodes(vRoomRateRow.Hotel, pInteractionParameters.InteractionID, vRoomRateRow.RoomType);
					For Each vAccTemplate In vAccommodationsToSync Do
						vRateArray = New Array;
						vRateArray.Add(vRoomRateRow.RoomRate);
						If vRatesResult = Undefined Then
							If vAccTemplate.IsVirtual Then
								vRatesResult = GetRates(vRoomRateRow.Hotel, vRateArray, pInteractionParameters, vRoomRateRow.PeriodFrom, vRoomRateRow.PeriodTo + vDaySec, pInteractionParameters.InteractionID, vRoomRateRow.RoomType, "VirtualRoomTypes", vAccTemplate.ObjectExternalCode);
							Else
								vRatesResult = GetRates(vRoomRateRow.Hotel, vRateArray, pInteractionParameters, vRoomRateRow.PeriodFrom, vRoomRateRow.PeriodTo + vDaySec, pInteractionParameters.InteractionID, vRoomRateRow.RoomType, "RoomTypes", vAccTemplate.ObjectExternalCode);
							EndIf;
						Else
							If vAccTemplate.IsVirtual Then
								vRates = GetRates(vRoomRateRow.Hotel, vRateArray, pInteractionParameters, vRoomRateRow.PeriodFrom, vRoomRateRow.PeriodTo + vDaySec, pInteractionParameters.InteractionID, vRoomRateRow.RoomType, "VirtualRoomTypes", vAccTemplate.ObjectExternalCode);
							Else
								vRates = GetRates(vRoomRateRow.Hotel, vRateArray, pInteractionParameters, vRoomRateRow.PeriodFrom, vRoomRateRow.PeriodTo + vDaySec, pInteractionParameters.InteractionID, vRoomRateRow.RoomType, "RoomTypes", vAccTemplate.ObjectExternalCode);
							EndIf;
							For Each vRateRow In vRates Do
								vNewRow = vRatesResult.Add();
								FillPropertyValues(vNewRow,vRateRow);
							EndDo;
						EndIf;
					EndDo;
				EndDo;
				
				If vRatesResult <> Undefined And vRatesResult.Count() > 0 Then 
					vRatesResult.Sort("RateCode, RoomTypeCode, Period");
					vRoomRates = New ValueTable;
					vRoomRates.Columns.Add("RoomTypeCode");
					vRoomRates.Columns.Add("RateCode");
					vRoomRates.Columns.Add("Price");
					
					vRateCode 	= Undefined;
					vPeriodFrom = Undefined;
					vVirtualCodes = GetVirtualObjects(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, "RoomRates");
					For Each vRatesResultRow In vRatesResult Do
						If vRateCode <> Undefined And vRoomRates.Count() > 0 And vRateCode <> vRatesResultRow.RateCode Then
							IsVirtual = False;
							For Each vVirtualRow In vVirtualCodes Do
								If vRateCode = vVirtualRow.ObjectExternalCode Then
									IsVirtual = True;
									Break;
								EndIf;
							EndDo;
							If NOT IsVirtual Then
								UpdatePlanPrices(pInteractionParameters, pHotelCode, vRateCode, vPeriodFrom, vRoomRates, vResult.RoomRates);
							EndIf;
							vRoomRates.Clear();
							vPeriodFrom = Undefined;
						EndIf;
						vNewRow = vRoomRates.Add();
						FillPropertyValues(vNewRow, vRatesResultRow); 
						vRateCode	= vRatesResultRow.RateCode;	
						If vPeriodFrom = Undefined Then
							vPeriodFrom = vRatesResultRow.Period;
						EndIf;
					EndDo;
					If vRateCode <> Undefined And vRoomRates.Count() > 0 Then
						IsVirtual = False;
						For Each vVirtualRow In vVirtualCodes Do
							If vRateCode = vVirtualRow.ObjectExternalCode Then
								IsVirtual = True;
								Break;
							EndIf;
						EndDo;
						If NOT IsVirtual Then
							UpdatePlanPrices(pInteractionParameters, pHotelCode, vRateCode, vPeriodFrom, vRoomRates, vResult.RoomRates);
						EndIf;
						
						vRoomRates.Clear();
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	Except
		vRoomRateError = ErrorDescription();	
	EndTry;

	#EndRegion	

	vSuccess = True;
	vError = "";
	If ValueIsFilled(vReservationError) or ValueIsFilled(vRoomInventoryError) or ValueIsFilled(vRoomRateError) Then
		vSuccess = False;
		If ValueIsFilled(vReservationError) Then
			vError = "Reservation sync failed:" + vReservationError + Chars.LF;
		EndIf;
		
		If ValueIsFilled(vRoomInventoryError) Then
			vError = vError + "Room inventory sync failed:" + vRoomInventoryError + Chars.LF;
		EndIf;
		
		If ValueIsFilled(vRoomRateError) Then
			vError = vError + "Room rates sync failed:" + vRoomRateError + Chars.LF;
		EndIf;
	EndIf;
	
	#Region OnSuccess

	If IsBlankString(vError) Then
		For Each vRow In vResult.RoomInventory Do
			If NOT vRow.Success Then
				vSuccess = False;
			EndIf;
		EndDo;
		For Each vRow In vResult.RoomRates Do
			If NOT vRow.Success Then
				vSuccess = False;
			EndIf;
		EndDo;
		For Each vRow In vResult.RoomRestrictions Do
			If NOT vRow.Success Then
				vSuccess = False;
			EndIf;
		EndDo;
	EndIf;

	#EndRegion
	
	ChannelManagers.UpdateLastSyncTime(pInteractionParameters, False, vLastSyncDate, vError, pSyncInventory, pSyncRates, pSyncRates);
	If Not IsBlankString(vError) Then
		Raise vError;
	EndIf;
	
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
//  Function - Sync all for period
//
// Parameters:
//  pUsername					 - String	 - 
//  pPassword					 - String	 - 
//  pHTTPHost					 - String	 - 
//  pRequestorID				 - String	 - 
//  pHotelCode					 - String	 - 
//  pInteractionParameters		 - CatalogRef.ExternalSystemInteractions	 - 
//  pPeriodFrom					 - Date	 - 
//  pPeriodTo					 - Date	 - 
//  pSyncRates					 - Boolean	 - 
//  pSyncInventory				 - Boolean	 - 
//  pGetVacantRoomsAtMidnight	 - Boolean	 - 
// 
// Returns:
//  Structure - of arrays RoomInventory
//
Function SyncAllForPeriod(pUsername, pPassword, pHTTPHost, pRequestorID, pHotelCode, pInteractionParameters, pPeriodFrom, pPeriodTo, pSyncRates, pSyncInventory = True, pGetVacantRoomsAtMidnight = False) Export
	WriteLogEvent(pInteractionParameters.InteractionID + "_SyncAllForPeriod", EventLogLevel.Information,,CurrentSessionDate(), "Started full sync");
	vResult 		= New Structure("RoomInventory, RoomRates, RoomRestrictions, Reservations", New Array, New Array, New Array, New Array);
	vRoomTypesArray = GetAllObjects(pInteractionParameters, pInteractionParameters.Hotel, "RoomTypes");
	vRoomRatesArray = GetAllObjects(pInteractionParameters, pInteractionParameters.Hotel, "RoomRates");
	
	vRoomInventoryError = "";
	vRoomRateError = "";
	vLastSyncDate = CurrentSessionDate();
	
	#Region RoomInventory
	vBalanceResult = Undefined;
	If pSyncInventory Then
		Try
			For Each vRoomTypeRow In vRoomTypesArray Do 
				If vBalanceResult = Undefined Then 
					vBalanceResult = GetBalances(pInteractionParameters.Hotel, pInteractionParameters.Allotment, pPeriodFrom, pPeriodTo, pInteractionParameters.InteractionID, vRoomTypeRow, pGetVacantRoomsAtMidnight);
				Else
					vBalance = GetBalances(pInteractionParameters.Hotel, pInteractionParameters.Allotment, pPeriodFrom, pPeriodTo, pInteractionParameters.InteractionID, vRoomTypeRow, pGetVacantRoomsAtMidnight);
					For Each vBalanceRow In vBalance Do
						vNewRow = vBalanceResult.Add();
						FillPropertyValues(vNewRow,vBalanceRow);
					EndDo;
				EndIf;
			EndDo;
			
			If vBalanceResult <> Undefined Then 
				vAvailability = New ValueTable;
				vAvailability.Columns.Add("Hotel");
				vAvailability.Columns.Add("RoomType");
				vAvailability.Columns.Add("RoomTypeCode");
				vAvailability.Columns.Add("Period");
				vAvailability.Columns.Add("BookingLimit");
				vAvailability.Columns.Add("RoomsVacant");
				vAvailability.Columns.Add("BedsVacant");
				
				For Each vBalanceResultRow In vBalanceResult Do
					vCurrentDate			= BegOfDay(vBalanceResultRow.PeriodFrom);
					vRoomTypeCodes			= GetAllExternalRoomTypesCodes(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, vBalanceResultRow.RoomType);
					While BegOfDay(vCurrentDate) <= BegOfDay(vBalanceResultRow.PeriodTo) Do
						For Each vRoomTypeRow In vRoomTypeCodes Do
							vNewRow 				= vAvailability.Add();
							vNewRow.Hotel		 	= pInteractionParameters.Hotel; 					
							vNewRow.RoomType 		= vBalanceResultRow.RoomType;
							vNewRow.RoomTypeCode 	= vRoomTypeRow.ObjectExternalCode; 					
							vNewRow.Period 			= vCurrentDate;
							vNewRow.BookingLimit 	= vBalanceResultRow.VacantRooms;
							vNewRow.RoomsVacant 	= vBalanceResultRow.VacantRooms;
							vNewRow.BedsVacant 		= vBalanceResultRow.VacantBeds;
						EndDo;
						
						vCurrentDate = vCurrentDate + 24 * 60 * 60;
					EndDo;
				EndDo;
				
				vVirtualCodes = GetVirtualObjects(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, "RoomTypes");
				vClearArray = New Array;
				For Each vAvailRow In vAvailability Do
					For Each vVirtualRow In vVirtualCodes Do
						If vAvailRow.RoomTypeCode = vVirtualRow.ObjectExternalCode Then
							vClearArray.Add(vAvailRow);
							Break;
						EndIf;
					EndDo;
				EndDo;
				For Each vClearRow In vClearArray Do
					vAvailability.Delete(vClearRow);
				EndDo;
				vClearArray = Undefined;

				vAvailability.Sort("RoomTypeCode, Period");
				
				UpdateRoomsValues(pInteractionParameters, pHotelCode, vAvailability, vResult.RoomInventory);
			EndIf;
		Except
			vRoomInventoryError = ErrorDescription();
		EndTry;
	EndIf;
	#EndRegion
	
	#Region RoomRate
	Try
		If pSyncRates Then
			vVirtualRoomTypesArray = GetAllObjects(pInteractionParameters, pInteractionParameters.Hotel, "VirtualRoomTypes");
			For Each vVirtualRoomType In vVirtualRoomTypesArray Do
				vRoomTypesArray.Add(vVirtualRoomType);
			EndDo;
			
			vRatesResult = Undefined;	
			vTotal = vRoomTypesArray.Count();
			i = 0;
			
			While i < vTotal Do
				j = i + 1;
				While j < vTotal Do
					If vRoomTypesArray[i] = vRoomTypesArray[j] Then
						vRoomTypesArray.Delete(j);
						vTotal = vTotal - 1;
					Else
						j = j + 1;
					EndIf;
				EndDo;
				i = i + 1;
			EndDo;
			
			vTotal = vRoomRatesArray.Count();
			i = 0;
			
			While i < vTotal Do
				j = i + 1;
				While j < vTotal Do
					If vRoomRatesArray[i] = vRoomRatesArray[j] Then
						vRoomRatesArray.Delete(j);
						vTotal = vTotal - 1;
					Else
						j = j + 1;
					EndIf;
				EndDo;
				i = i + 1;
			EndDo;
			vDaySec = 24 * 60 * 60;
			For Each vRoomRate In vRoomRatesArray Do
				FillDailyPrices(pInteractionParameters, pInteractionParameters.Hotel, vRoomRate, Undefined, pPeriodFrom, pPeriodTo + vDaySec);
			EndDo;
			
			For Each vRoomTypeRow In vRoomTypesArray Do
				vAccommodationsToSync = GetAllExternalRoomTypesCodes(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, vRoomTypeRow);
				For Each vAccTemplate In vAccommodationsToSync Do 
					If vRatesResult = Undefined Then 
						If vAccTemplate.IsVirtual Then 
							vRatesResult = GetRates(pInteractionParameters.Hotel, vRoomRatesArray, pInteractionParameters, pPeriodFrom, pPeriodTo + vDaySec, pInteractionParameters.InteractionID, vRoomTypeRow, "VirtualRoomTypes", vAccTemplate.ObjectExternalCode);
						Else
							vRatesResult = GetRates(pInteractionParameters.Hotel, vRoomRatesArray, pInteractionParameters, pPeriodFrom, pPeriodTo + vDaySec, pInteractionParameters.InteractionID, vRoomTypeRow, "RoomTypes", vAccTemplate.ObjectExternalCode);
						EndIf;
					Else
						If vAccTemplate.IsVirtual Then 
							vRates = GetRates(pInteractionParameters.Hotel, vRoomRatesArray, pInteractionParameters, pPeriodFrom, pPeriodTo + vDaySec, pInteractionParameters.InteractionID, vRoomTypeRow, "VirtualRoomTypes", vAccTemplate.ObjectExternalCode);
						Else
							vRates = GetRates(pInteractionParameters.Hotel, vRoomRatesArray, pInteractionParameters, pPeriodFrom, pPeriodTo + vDaySec, pInteractionParameters.InteractionID, vRoomTypeRow, "RoomTypes", vAccTemplate.ObjectExternalCode);
						EndIf;
						For Each vRateRow In vRates Do
							vNewRow = vRatesResult.Add();
							FillPropertyValues(vNewRow,vRateRow);
						EndDo;
					EndIf;
				EndDo;
			EndDo;
			
			If vRatesResult <> Undefined Then 
				vRatesResult.Sort("RateCode, RoomTypeCode, Period");
				vRoomRates = New ValueTable;
				vRoomRates.Columns.Add("RoomTypeCode");
				vRoomRates.Columns.Add("RateCode");
				vRoomRates.Columns.Add("Price");
				
				vRateCode 	= Undefined;
				vPeriodFrom = Undefined;
				vVirtualCodes = GetVirtualObjects(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, "RoomRates");
				For Each vRatesResultRow In vRatesResult Do
					If vRateCode <> Undefined And vRoomRates.Count() > 0 And vRateCode <> vRatesResultRow.RateCode Then
						IsVirtual = False;
						For Each vVirtualRow In vVirtualCodes Do
							If vRateCode = vVirtualRow.ObjectExternalCode Then
								IsVirtual = True;
								Break;
							EndIf;
						EndDo;
						If NOT IsVirtual Then
							UpdatePlanPrices(pInteractionParameters, pHotelCode, vRateCode, vPeriodFrom, vRoomRates, vResult.RoomRates);
						EndIf;
						
						vRoomRates.Clear();
						vPeriodFrom = Undefined;
					EndIf;
					vNewRow = vRoomRates.Add();
					FillPropertyValues(vNewRow, vRatesResultRow); 
					vRateCode	= vRatesResultRow.RateCode;	
					If vPeriodFrom = Undefined Then
						vPeriodFrom = vRatesResultRow.Period;
					EndIf;
				EndDo;
				If vRateCode <> Undefined And vRoomRates.Count() > 0 Then
					IsVirtual = False;
					For Each vVirtualRow In vVirtualCodes Do
						If vRateCode = vVirtualRow.ObjectExternalCode Then
							IsVirtual = True;
							Break;
						EndIf;
					EndDo;
					If NOT IsVirtual Then
						UpdatePlanPrices(pInteractionParameters, pHotelCode, vRateCode, vPeriodFrom, vRoomRates, vResult.RoomRates);
					EndIf;
					
					vRoomRates.Clear();
				EndIf;
			EndIf;
		EndIf;
	Except
		vRoomRateError = ErrorDescription();
	EndTry;
	#EndRegion
	
	vError = "";
	If ValueIsFilled(vRoomInventoryError) or ValueIsFilled(vRoomRateError) Then
		If ValueIsFilled(vRoomInventoryError) Then
			vError = vError + "Room inventory sync failed:" + vRoomInventoryError + Chars.LF;
		EndIf;
		
		If ValueIsFilled(vRoomRateError) Then
			vError = vError + "Room rates sync failed:" + vRoomRateError + Chars.LF;
		EndIf;
	EndIf;
	
	ChannelManagers.UpdateLastSyncTime(pInteractionParameters, True, vLastSyncDate, vError, pSyncInventory, pSyncRates, pSyncRates);
	If Not IsBlankString(vError) Then
		Raise vError;
	EndIf;
	
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
//  Function - Get active token
//
// Parameters:
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions	 - 
//  pForceNew				 - Boolean	 - 
// 
// Returns:
//  Structure - Params
//
Function GetActiveToken(pInteractionParameters, pForceNew = False) Export
	vResult = New Structure("Token, Error");
	If ValueIsFilled(pInteractionParameters.SessionID) Then
		If pInteractionParameters.SessionStartTime + 50*60 < CurrentSessionDate() And pInteractionParameters.SessionTimeout > 5 Then
			vResult.Token 	= pInteractionParameters.SessionID; 
		EndIf;
	EndIf;
	
	If vResult.Token = Undefined or pForceNew Then
		vTokenResult = CreateToken(pInteractionParameters.WSHost, "xrws", pInteractionParameters.Login, pInteractionParameters.Password, pInteractionParameters);
		If TypeOf(vTokenResult) = Type("String") Then
			vResult.Error = vTokenResult;
		Else
			If vTokenResult.StatusID <> "0" Then
				vResult.Error = vTokenResult.Value;
			Else
				vResult.Token = vTokenResult.Value;
				UpdateInteractionParametersSession(pInteractionParameters, vTokenResult.Value, 5)
			EndIf;
		EndIf;
	EndIf;
	
	Return vResult;	
EndFunction

// --------------------------------------------------------------------------------
//
// Parameters:
//  pExternalInteractionRef	 - CatalogRef.ExternalSystemInteractions - Ref
// 
// Returns:
//  String - Token
//
Function RefreshToken(pExternalInteractionRef) Export
	vTokenResult = GetToken(pExternalInteractionRef.WSHost, "xrws", pExternalInteractionRef.Login, pExternalInteractionRef.Password, pExternalInteractionRef);
	If TypeOf(vTokenResult) = Type("String") Then
		Return vTokenResult;
	Else
		If vTokenResult.StatusID <> "0" Then
			Return vTokenResult.Value;
		Else
			vExtObj = pExternalInteractionRef.GetObject();
			vExtObj.SessionID = vTokenResult.Value;
		EndIf;
	EndIf;
	BeginTransaction(DataLockControlMode.Managed);
	Try
		vExtObj.SessionTimeout = 60;
		vExtObj.SessionStartTime = CurrentSessionDate();
		vExtObj.SessionLastActivityTime = CurrentSessionDate();
		vExtObj.Write();
		CommitTransaction();
	Except
		RollbackTransaction();
	EndTry;
	Return "";
EndFunction // RefreshToken

// --------------------------------------------------------------------------------
//
// Parameters:
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions	 - 
//  pNewSession				 - String	 - 
//  pAttempts				 - Number	 - 
//
Procedure UpdateInteractionParametersSession(pInteractionParameters, pNewSession = Undefined, pAttempts = 2) Export
	vAttempt 	= 1;
	vSuccess 	= True;
	BeginTransaction(DataLockControlMode.Managed);
	While vAttempt <= pAttempts do
		Try
			vObj 					= pInteractionParameters.GetObject();
			If pNewSession <> Undefined Then 
				vObj.SessionID 			= pNewSession;
				vObj.SessionStartTime 	= CurrentSessionDate();
				vObj.SessionTimeout 	= 60;
			Else
				vObj.SessionTimeout 	= vObj.SessionTimeout - 1;	
			EndIf;
			vObj.Write();
			vSuccess = True;
			Break;
		Except
			vSuccess = False;
			cmWait(5);
		EndTry;
		vAttempt = vAttempt + 1;
	EndDo;
	If vSuccess Then
		CommitTransaction();
	Else
		RollbackTransaction();
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
//  =======USE ONLY AT SERVER========
//  Return: Structure:
//  - StatusID: Status ID (0 - OK, <0 - Error)
//  - Value: If Status ID <0 - Human Readable string of current error, else OK
//
// Parameters:
//  pServerHost				 - String	 - 
//  pServerResource			 - String	 - 
//  pLogin					 - String	 - 
//  pPassword				 - String	 - 
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions	 - 
// 
// Returns:
//  Structure - Params
//
Function GetToken(pServerHost, pServerResource, pLogin, pPassword, pInteractionParameters) Export
	If Not ValueIsFilled(pLogin) Or Not ValueIsFilled(pPassword) Then
		Return NStr("en='Login error! Check login/password';ru='Ошибка соединения! Проверьте правильность ввода логина/пароля';de='Verbindungsfehler! Prüfen Sie das Login/Passwort'");
	EndIf;
	
	//XML
	
	vXMLDocument = New XMLWriter;
	vXMLDocument.SetString();
	vXMLDocument.WriteXMLDeclaration();
	vXMLDocument.WriteStartElement("methodCall");
		vXMLDocument.WriteStartElement("methodName");
			vXMLDocument.WriteText("acquire_token");
		vXMLDocument.WriteEndElement();	
		vXMLDocument.WriteStartElement("params");
			vXMLDocument.WriteStartElement("param");
				vXMLDocument.WriteStartElement("value");
			        vXMLDocument.WriteStartElement("string");
			        	vXMLDocument.WriteText(pLogin);
					vXMLDocument.WriteEndElement();
				vXMLDocument.WriteEndElement();
			vXMLDocument.WriteEndElement();
			vXMLDocument.WriteStartElement("param");
				vXMLDocument.WriteStartElement("value");
			    	vXMLDocument.WriteStartElement("string");
			        	vXMLDocument.WriteText(pPassword);                                    
					vXMLDocument.WriteEndElement();
				vXMLDocument.WriteEndElement();
			vXMLDocument.WriteEndElement();
			vXMLDocument.WriteStartElement("param");
				vXMLDocument.WriteStartElement("value");
			    	vXMLDocument.WriteStartElement("string");
			        	vXMLDocument.WriteText("clx,m.$#%#$/,.sdm22");                                    
					vXMLDocument.WriteEndElement();
				vXMLDocument.WriteEndElement();
			vXMLDocument.WriteEndElement();
		vXMLDocument.WriteEndElement();	
	vXMLDocument.WriteEndElement();
	vXML = vXMLDocument.Close();
	
	vRequestHeaders = New Map;
	vRequestHeaders.Insert("Content-Type", "text/xml;charset=utf-8");
	vRequestHeaders.Insert("Content-Lenght", StrLen(vXML));
	
	vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, vRequestHeaders, pServerResource, "POST", "acquire_token", vXML, "text/xml;charset=utf-8");
	
	// XML Read
	vReadXML = New XMLReader;
	vReadXML.SetString(vResponse.Body);
	
	vDOMBuilder = New DOMBuilder;
	vDOMDocument = vDOMBuilder.Read(vReadXML);
	vStatusIDPostion = vDOMDocument.GetElementByTagName("int");
	If vStatusIDPostion.Count() > 0 Then
		vStatusID = vStatusIDPostion[0].TextContent;
		
		vValuePostion = vDOMDocument.GetElementByTagName("string");
		If vValuePostion.Count() > 0 Then
			vValue = vValuePostion[0].TextContent;
		Else
			Return NStr("en='XML is wrong';ru='Неправильное форматирование XML';de='Falsche XML-Formatierung'");
		EndIf;
	Else
		Return NStr("en='XML is wrong';ru='Неправильное форматирование XML';de='Falsche XML-Formatierung'");
	EndIf;
	
	vReturnStructure = New Structure("StatusID, Value", vStatusID, vValue);
	
	Return vReturnStructure;
EndFunction // GetToken

// --------------------------------------------------------------------------------
// Function - Get settings
// 
// Returns:
//  Structure - Params: ExternalSystemCode, WSHost, ResourceAddress, EchoToken, TimeStamp, Version
//
Function GetSettings() Export
	vResult = new Structure("ExternalSystemCode, WSHost, ResourceAddress, EchoToken, TimeStamp, Version");
	vResult.ExternalSystemCode	= "WuBook";
	vResult.WSHost				= "wired.wubook.net";
	vResult.ResourceAddress		= "xrws";
	vResult.EchoToken			= String(New UUID);
	vResult.TimeStamp			= Format(CurrentSessionDate(),"DF=yyyy-MM-ddTHH:mm:ss+03:00");
	vResult.Version				= "2.0";
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
//  =======USE ONLY AT SERVER========
//  Returns the following params:
//  ID: the plan id (use this to identify the plan)
//  Name: the plan name
//  Daily: daily = 1 means the plan is a daily pricing plan
//  Vpid: is the ID of the linked pricing plan (Only if a pricing plan is virtual)
//  Variation: is a float, the value of the derivation (Only if a pricing plan is virtual)
//  Variation_type: can be -2, -1, 1, 2 (Only if a pricing plan is virtual)
//  -2: This plan is a discount. Value is a fixed amount
//  -1: This plan is a discount. Value is a percentage
//  1: This plan increases prices. Value is a percentage
//  2: This plan increases prices. Value is a fixed amount
//
// Parameters:
//  pExternalInteractionRef	 - CatalogRef.ExternalSystemInteractions	 - 
//  pLodgingCode			 - String	 - 
//  pDoRepeat				 - Boolean	 - 
// 
// Returns:
//  Structure - Params 
//
Function GetRestrictionPlans(pExternalInteractionRef, pLodgingCode, pDoRepeat = True) Export
	GetActiveToken(pExternalInteractionRef);
	
	If Not ValueIsFilled(pExternalInteractionRef) Or Not ValueIsFilled(pLodgingCode) Then
		Return NStr("en='Check parameters';ru='Проверьте правильность ввода данных';de='Überprüfen Sie die Richtigkeit der Dateneingabe'");
	EndIf;
	//XML
	
	vXMLDocument = New XMLWriter;
	vXMLDocument.SetString();
	vXMLDocument.WriteXMLDeclaration();
	vXMLDocument.WriteStartElement("methodCall");
		vXMLDocument.WriteStartElement("methodName");
			vXMLDocument.WriteText("rplan_rplans");
		vXMLDocument.WriteEndElement();	
		vXMLDocument.WriteStartElement("params");
			vXMLDocument.WriteStartElement("param");
				vXMLDocument.WriteStartElement("value");
			        vXMLDocument.WriteStartElement("string");
			        	vXMLDocument.WriteText(pExternalInteractionRef.SessionID);
					vXMLDocument.WriteEndElement();
				vXMLDocument.WriteEndElement();
			vXMLDocument.WriteEndElement();
			vXMLDocument.WriteStartElement("param");
				vXMLDocument.WriteStartElement("value");
			    	vXMLDocument.WriteStartElement("int");
			        	vXMLDocument.WriteText(pLodgingCode);                                    
					vXMLDocument.WriteEndElement();
				vXMLDocument.WriteEndElement();
			vXMLDocument.WriteEndElement();
		vXMLDocument.WriteEndElement();	
	vXMLDocument.WriteEndElement();
	vXML = vXMLDocument.Close();
	
	vRequestHeaders = New Map;
	vRequestHeaders.Insert("Content-Type", "text/xml;charset=utf-8");
	vRequestHeaders.Insert("Content-Lenght", StrLen(vXML));
	
	vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pExternalInteractionRef, vRequestHeaders, "xrws", "POST", "rplan_rplans", vXML, "text/xml;charset=utf-8");
	
	// XML Read
	vReadXML = New XMLReader;
	vReadXML.SetString(vResponse.Body);
	
	vDOMBuilder = New DOMBuilder;
	vDOMDocument = vDOMBuilder.Read(vReadXML);
	
	vReturnStructure = New Structure("StatusID, Value");
	
	vStatusIDPostion = vDOMDocument.GetElementByTagName("int");
	If vStatusIDPostion.Count() > 0 Then
		vStatusID = vStatusIDPostion[0].TextContent;
		vReturnStructure.StatusID = vStatusID;
		
		If vStatusID <> "0" Then
			vRefreshTokenResult = RefreshToken(pExternalInteractionRef);
			If ValueIsFilled(vRefreshTokenResult) Then
				vReturnStructure.Value = vRefreshTokenResult;
			Else
				If pDoRepeat Then
					// Try again
					vReturnStructure = GetPricingPlans(pExternalInteractionRef, pLodgingCode, False);
				Else
					vValuePostion = vDOMDocument.GetElementByTagName("string");
					vValue = vValuePostion[0].TextContent;
					vReturnStructure.Value = vValue;
				EndIf;
			EndIf;
		Else
			//Return table
			vReturnTable = New ValueTable;
			vReturnTable.Columns.Add("ID");
			vReturnTable.Columns.Add("Name");
			
			vValuePostion = vDOMDocument.GetElementByTagName("struct");
			For Each vStruct In vValuePostion Do
				vElements = vStruct.GetElementByTagName("name");
				vNewRow = vReturnTable.Add();
				For Each vElement In vElements Do
					If vElement.TextContent = "id" Then
						vNewRow.ID = vElement.NextSibling.TextContent;
					EndIf;
					If vElement.TextContent = "name" Then
						vNewRow.Name = vElement.NextSibling.TextContent;
					EndIf;
				EndDo;
			EndDo;
			vReturnStructure.Value = vReturnTable;
		EndIf;
	Else
		Return NStr("en='XML is wrong';ru='Неправильное форматирование XML';de='Falsche XML-Formatierung'");
	EndIf;
	
	Return vReturnStructure;
EndFunction // GetPricingPlans

/// --------------------------------------------------------------------------------
//  You can assigned prizes for one or more periods
//  Note: If you insert a period with a date that's already existing, the old period will be deletes
//  It returns standard output: (code, human readable string).
//  pRoomRateID is the room rate ID.
//  pPeriodsTable is a value table containing a list of periods with parameters.
//  !!!Days lists must have the same lenght for each room.!!!
//  Columns:
//  PeriodFrom
//  PeriodTo
//  RoomRateID
//  Price
//  -----------------------------------------------------------------------------
//  ----!!!!All values are optional: passing a void item, nothing is updated. Only specified values are updated.!!!!!----
//  -----------------------------------------------------------------------------
//  Return: Structure:
//  - StatusID: Status ID (0 - OK, <0 - Error)
//  - Value: If Status ID <0 - Human Readable string of current error, else OK
//  -----------------------------------------------------------------------------
//
// Parameters:
//  pExternalInteractionRef	 - CatalogRef.ExternalSystemInteractions	 - 
//  pLodgingCode			 - String	 - 
//  pPlanID					 - String	 - 
//  pDateFrom				 - Date	 - 
//  pPricesTable			 - ValueTable	 - 
//  pResult					 - Structure	 - 
// 
// Returns:
//  Structure - Params 
//
Function UpdatePlanPrices(pExternalInteractionRef, pLodgingCode, pPlanID, pDateFrom, pPricesTable, pResult) Export
	GetActiveToken(pExternalInteractionRef);
	vSuccess	= True;
	vError 		= Undefined;
	vValue 		= Undefined;
	vStatusID 	= Undefined;

	If Not ValueIsFilled(pExternalInteractionRef) Or Not ValueIsFilled(pLodgingCode) Or Not ValueIsFilled(pPlanID) Or Not ValueIsFilled(pDateFrom) 
		Or TypeOf(pPricesTable) <> Type("ValueTable") Or pPricesTable.Count() = 0 Then
		Return NStr("en='Check parameters';ru='Проверьте правильность ввода данных';de='Überprüfen Sie die Richtigkeit der Dateneingabe'");
	EndIf;
	vLastRT = "";
	// XML
	
	vXMLDocument 		= New XMLWriter;
	vXMLDocument.Indent = False;

	vXMLDocument.SetString();
	vXMLDocument.WriteXMLDeclaration();
	vXMLDocument.WriteStartElement("methodCall");
		vXMLDocument.WriteStartElement("methodName");
			vXMLDocument.WriteText("update_plan_prices");
		vXMLDocument.WriteEndElement(); // MethodName	
		vXMLDocument.WriteStartElement("params");
			vXMLDocument.WriteStartElement("param");
				vXMLDocument.WriteStartElement("value");
					vXMLDocument.WriteStartElement("string");
						vXMLDocument.WriteText(TrimAll(pExternalInteractionRef.SessionID));
					vXMLDocument.WriteEndElement(); // String
				vXMLDocument.WriteEndElement(); // Value
			vXMLDocument.WriteEndElement(); // Param
			vXMLDocument.WriteStartElement("param");
				vXMLDocument.WriteStartElement("value");
					vXMLDocument.WriteStartElement("int");
						vXMLDocument.WriteText(pLodgingCode);                                    
					vXMLDocument.WriteEndElement(); // Int
				vXMLDocument.WriteEndElement(); // Value
			vXMLDocument.WriteEndElement(); // Param
			vXMLDocument.WriteStartElement("param");
				vXMLDocument.WriteStartElement("value");
					vXMLDocument.WriteStartElement("int");
						vXMLDocument.WriteText(String(pPlanID));                                    
					vXMLDocument.WriteEndElement(); // Int
				vXMLDocument.WriteEndElement(); // Value
			vXMLDocument.WriteEndElement(); // Param
			vXMLDocument.WriteStartElement("param");
				vXMLDocument.WriteStartElement("value");
					vXMLDocument.WriteStartElement("string");
						vXMLDocument.WriteText(Format(pDateFrom, "DF=dd/MM/yyyy"));                                    
					vXMLDocument.WriteEndElement(); // String
				vXMLDocument.WriteEndElement(); // Value
			vXMLDocument.WriteEndElement(); // Param
			vXMLDocument.WriteStartElement("param");
				vXMLDocument.WriteStartElement("value"); 
					vXMLDocument.WriteStartElement("struct");
						For Each vRow In pPricesTable Do
							If vLastRT <> vRow.RoomTypeCode Then
								If vLastRT <> "" Then
									vXMLDocument.WriteEndElement();	// Data
									vXMLDocument.WriteEndElement();	// Array
									vXMLDocument.WriteEndElement();	// Value
									vXMLDocument.WriteEndElement();	// Member
								EndIf;
								vXMLDocument.WriteStartElement("member");
									vXMLDocument.WriteStartElement("name");
										vXMLDocument.WriteText(TrimAll(vRow.RoomTypeCode));
									vXMLDocument.WriteEndElement();	// Name
			                    	vXMLDocument.WriteStartElement("value");
										vXMLDocument.WriteStartElement("array");
											vXMLDocument.WriteStartElement("data");
								vLastRT = vRow.RoomTypeCode;
							EndIf;
							vXMLDocument.WriteStartElement("value");
								vXMLDocument.WriteStartElement("double");
								If ValueIsFilled(vRow.Price) Then
									vXMLDocument.WriteText(Format(vRow.Price,"NDS=.; NG="));
								Else
									vXMLDocument.WriteText("0");
								EndIf;
								vXMLDocument.WriteEndElement();	// String
							vXMLDocument.WriteEndElement();	// Value			
						EndDo;
					vXMLDocument.WriteEndElement();	// Data
					vXMLDocument.WriteEndElement();	// Array
					vXMLDocument.WriteEndElement();	// Value
					vXMLDocument.WriteEndElement();	// Member
					vXMLDocument.WriteEndElement();	// Struct
				vXMLDocument.WriteEndElement(); // Value
			vXMLDocument.WriteEndElement(); // Param
		vXMLDocument.WriteEndElement();	// Params
	vXMLDocument.WriteEndElement(); // MethodCall
	vXML = vXMLDocument.Close();
	
	vRequestHeaders = New Map;
	vRequestHeaders.Insert("Content-Type", "text/xml;charset=utf-8");
	vRequestHeaders.Insert("Content-Lenght", StrLen(vXML));
	
	vResponse 	= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pExternalInteractionRef, vRequestHeaders, "xrws", "POST", "update_plan_prices", vXML, "text/xml;charset=utf-8");
		
	vSuccess = IsBlankString(vResponse.Error);
	
	If vSuccess Then
		// XML Read
		vReadXML = New XMLReader;
		vReadXML.SetString(vResponse.Body);
		
		vDOMBuilder = New DOMBuilder;
		vDOMDocument = vDOMBuilder.Read(vReadXML);
		
		
		vStatusIDPostion = vDOMDocument.GetElementByTagName("int");
		If vStatusIDPostion.Count() > 0 Then
			vStatusID = vStatusIDPostion[0].TextContent;
			
			Try
				vValuePostion = vDOMDocument.GetElementByTagName("string");
				vValue = vValuePostion[0].TextContent;
			Except
			EndTry;
					
			If vStatusID <> "0" Then
				vSuccess = False;
				vError = NStr("en='XML is wrong';ru='Неправильное форматирование XML';de='Falsche XML-Formatierung'");
			EndIf;
		Else
			vSuccess = False;
			vError = NStr("en='XML is wrong';ru='Неправильное форматирование XML';de='Falsche XML-Formatierung'");
		EndIf;
	EndIf;
		
	pResult.Add(New Structure("RawRequest, RawResponse, Success, Error, Result, ResultStatus", vXML, vResponse.Body, vSuccess, vError, vValue, vStatusID));
	
	Return pResult; 
EndFunction // UpdatePlanPrices

// --------------------------------------------------------------------------------
//  Returns the rooms for the property identified by lcode. For Each room Wired! returns the following params:
//  ID: the room id (use this to identify the room)
//  Name: the room name
//  Shortname: the room shortname: unique between the facility
//  Occupancy: the room occupancy
//  Men: adults (note: adults + children = occupancy)
//  Children: children (note: adults + children = occupancy)
//  Subroom: room mother
//  Board: Room board
//  When subroom is 0 (zero), the returned room is a true, independent room.
//  When subroom is not 0, his value is a room id. 
//  This means this room is sharing the availability with the room identified by subroom. 
//  Only availability is shared: you can update the other values (price, restrictions and so on) in a free way.
//  When you try to update a subroom availability, nothing happens.
//  -----------------------------------------------------------------------------
//
// Parameters:
//  pExternalInteractionRef	 - CatalogRef.ExternalSystemInteractions 	 - 
//  pLodgingCode			 - String	 - 
//  pIsInteractive			 - Boolean	 - 
//  pDateFrom				 - Date	 - 
//  pDateTo					 - Date	 - 
//  pRCode					 - String	 - 
// 
// Returns:
//  Structure - Params 
//
Function FetchBookings(pExternalInteractionRef, pLodgingCode, pIsInteractive = True, pDateFrom = Undefined, pDateTo = Undefined, pRCode = Undefined) Export
	
	WriteLogEvent(NStr("en='Fetch bookings (WuBook)';ru='Получение бронирований (WuBook)';de='Fetch bookings (WuBook)'"), EventLogLevel.Information, , Undefined,
		"Fetch bookings" + Chars.LF 
		+ "Lodging code: " + TrimAll(pLodgingCode) + Chars.LF 
		+ "Is interactive: " + TrimAll(pIsInteractive) + Chars.LF
		+ "Reservation code: " + TrimAll(pRCode) + Chars.LF
		+ "Date from: " + TrimAll(pDateFrom) + Chars.LF
		+ "Date to: " + TrimAll(pDateTo));
	If Not ValueIsFilled(pExternalInteractionRef) Or Not ValueIsFilled(TrimAll(pExternalInteractionRef.SessionID)) Or Not ValueIsFilled(pLodgingCode) Then
		Return NStr("ru='Проверьте правильность ввода данных (FB)'; 
					|en='Check parameters (FB)';
					|de='Check parameters (FB)'");
	EndIf;
	
	vLogTag = NStr("en='Fetch bookings (WuBook)';ru='Получение бронирований (WuBook)';de='Fetch bookings (WuBook)'");

	vDefaultLanguageCode = Undefined;
	If ValueIsFilled(pExternalInteractionRef.Hotel) And ValueIsFilled(pExternalInteractionRef.Hotel.Language) Then
		vDefaultLanguageCode = Upper(TrimAll(pExternalInteractionRef.Hotel.Language.Code));
	EndIf;
	
	vDOMDocument = Fetch_new_bookings(pExternalInteractionRef, pLodgingCode);
	
	vReturnStructure = New Structure("StatusID, Value");
	
	vStatusIDPostion = vDOMDocument.GetElementByTagName("int");
	If vStatusIDPostion.Count() > 0 Then
		vStatusID = vStatusIDPostion[0].TextContent;
		vReturnStructure.StatusID = vStatusID;
		
		If vStatusID <> "0" Then
			vValuePostion = vDOMDocument.GetElementByTagName("string");
			vValue = vValuePostion[0].TextContent;
			vReturnStructure.Value = vValue;
		Else
			//Return table
			vReturnTable = New ValueTable;
			vReturnTable.Columns.Add("ReservationCode"); //
			vReturnTable.Columns.Add("ChannelReservationCode"); //
			vReturnTable.Columns.Add("Amount"); //
			vReturnTable.Columns.Add("OrigAmount");  //
			vReturnTable.Columns.Add("AmountReason");  //
			vReturnTable.Columns.Add("ChannelID"); //
			vReturnTable.Columns.Add("DateReceived"); //
			vReturnTable.Columns.Add("DateArrival");  //
			vReturnTable.Columns.Add("DateDeparture"); //
			vReturnTable.Columns.Add("ArrivalHour"); //
			vReturnTable.Columns.Add("Status");   //
			vReturnTable.Columns.Add("StatusDescription");   //
			vReturnTable.Columns.Add("StatusReason"); //
			vReturnTable.Columns.Add("RoomsOccupancies"); //
			vReturnTable.Columns.Add("Men"); //
			vReturnTable.Columns.Add("Children"); //
			vReturnTable.Columns.Add("CustomerCity"); //
			vReturnTable.Columns.Add("CustomerCountry"); //
			vReturnTable.Columns.Add("CustomerMail"); //
			vReturnTable.Columns.Add("CustomerName"); //
			vReturnTable.Columns.Add("CustomerLastname"); //
			vReturnTable.Columns.Add("CustomerRemarks");  //
			vReturnTable.Columns.Add("CustomerPhone");  //
			vReturnTable.Columns.Add("CustomerAddress"); //
			vReturnTable.Columns.Add("CustomerLanguage"); //
			vReturnTable.Columns.Add("Rooms"); //
			vReturnTable.Columns.Add("RoomNight"); //
			vReturnTable.Columns.Add("RoomOpportunities"); //
			vReturnTable.Columns.Add("Opportunities"); //
			vReturnTable.Columns.Add("DayPrices");  //
			vReturnTable.Columns.Add("SpecialOffer"); //
			vReturnTable.Columns.Add("AddonsList"); //
			vReturnTable.Columns.Add("DiscountType"); //
			vReturnTable.Columns.Add("DiscountSum"); //
			vReturnTable.Columns.Add("booked_rate"); //

			// Main query
			vQry = New Query;
			vQry.Text = 
			"SELECT
			|	ExternalSystemsObjectCodesMappings.ObjectTypeName,
			|	ExternalSystemsObjectCodesMappings.ObjectExternalCode,
			|	ExternalSystemsObjectCodesMappings.ObjectRef
			|FROM
			|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
			|WHERE
			|	ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
			|	AND ExternalSystemsObjectCodesMappings.Hotel = &qHotel";
			vQry.SetParameter("qExternalSystemCode", pExternalInteractionRef.InteractionID);
			vQry.SetParameter("qHotel", pExternalInteractionRef.Hotel);
			vQryResult = vQry.Execute().Unload();

			// XDTO
			vRetXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalGroupReservation"));

			vReservationsAray = New Array;
			vDepartureDate = "";
			vArrivalDate = "";
			vIsSubRoom = False;
			vValuePostion = vDOMDocument.GetElementByTagName("struct");
			
			vTimeCheckTable = New ValueTable;
			vTimeCheckTable.Columns.Add("ReservationID");
			vTimeCheckTable.Columns.Add("Time");
			
			For Each vStruct In vValuePostion Do
				If StrLen(TrimAll(vStruct.TextContent)) > 50 And Not cmIsNumber(Left(vStruct.TextContent, 1)) Then
					vGReservRow = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalGroupReservationRow"));
					vClientInfo = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
					vTimeCheckRow = vTimeCheckTable.Add();
					vNumberOfPersons = 0;
					vNewRow = vReturnTable.Add();
					vMembersPosition = vStruct.GetElementByTagName("member");
					vRetString = "";
					For Each vElement In vMembersPosition Do
						vValueID = vElement.ChildNodes[0].TextContent;
						vValuePosition = vElement.ChildNodes[1];
						vValueText = vValuePosition.TextContent;
						vRetString = vRetString + vValueID + " = " + vValueText + Chars.LF;
						If vValueID = "id_channel" Then
							vNewRow.ChannelID = vValueText;
							vGReservRow.Customer = vValueText;
						EndIf;
						If vValueID = "special_offer" Then
							vNewRow.SpecialOffer = vValueText;
							if ValueIsFilled(vValueText) Then
								
							EndIf;
						EndIf;
						If vValueID = "reservation_code" Then
							vNewRow.ReservationCode = vValueText;
							vGReservRow.GroupCode = vValueText;
							vGReservRow.ReservationCode = TrimAll(vValueText);
							If ValueIsFilled(vGReservRow.ReservationRemarks) Then
								vGReservRow.ReservationRemarks = vGReservRow.ReservationRemarks + Chars.LF + "W" + vValueText + Chars.LF + NStr("en='Reservation details: ';ru='Данные брони: ';de='Reservierungsdaten:'") + "https://wubook.net/bookings/" + TrimAll(vValueText) + "/";
							Else
								vGReservRow.ReservationRemarks = "W" + vValueText + Chars.LF + NStr("en='Reservation details: ';ru='Данные брони: ';de='Reservierungsdaten:'")+"https://wubook.net/bookings/" + TrimAll(vValueText) + "/";
							EndIf;
							vTimeCheckRow.ReservationID = vValueText;
						EndIf;
						If vValueID = "dayprices" Then  
							vDaysWithPrices = New ValueTable;
							vDaysWithPrices.Columns.Add("RoomID");
							vDaysWithPrices.Columns.Add("Price");
							vPricesPositions = vValuePosition.GetElementByTagName("member");
							For Each vPricePosition In vPricesPositions Do
								vPriceRoomID = vPricePosition.ChildNodes[0].TextContent;
								vPrices = vPricePosition.ChildNodes[1].GetElementByTagName("double");
								For Each vPriceItem In vPrices Do
									vPrice = vPriceItem.TextContent;
									vNewPriceRow = vDaysWithPrices.Add();
									vNewPriceRow.RoomID = vPriceRoomID;
									vNewPriceRow.Price = vPrice;
								EndDo;
							EndDo;
							vNewRow.DayPrices = vDaysWithPrices;
						EndIf;
						
						If vValueID = "arrival_hour" Then
							vNewRow.ArrivalHour = vValueText;
							If vValueText <> "--" Then 
								vTimeCheckRow.Time 	= vValueText;
							EndIf;
						EndIf;
						If vValueID = "booked_rate" Then
							vNewRow.booked_rate 	= vValueText;
							vGReservRow.RoomRate 	= vValueText;
						EndIf;
						If vValueID = "rooms" Then
							vNewRow.Rooms = vValueText;
							vGReservRow.RoomType = vValueText;
							vGReservRow.NumberOfRooms = 1;
							vGReservRow.NumberOfPersons = 1;
						EndIf;
						If vValueID = "customer_mail" Then
							vNewRow.CustomerMail = vValueText;
							vClientInfo.ClientEMail = StrReplace(vValueText, "--", "");
						EndIf;
						If vValueID = "customer_country" Then
							vNewRow.CustomerCountry = vValueText;
							vClientInfo.ClientCitizenship = StrReplace(vValueText, "--", "");
						EndIf;
						If vValueID = "children" Then
							vNewRow.Children = vValueText;
							vNumberOfPersons = vNumberOfPersons + Number(vValueText);
						EndIf;
						If vValueID = "customer_name" Then
							vNewRow.CustomerName = vValueText;
							vClientInfo.ClientFirstName = StrReplace(vValueText, "--", "");
						EndIf;
						If vValueID = "customer_surname" Then
							vNewRow.CustomerLastname = vValueText;
							vClientInfo.ClientLastName = StrReplace(vValueText, "--", "");
						EndIf;
						If vValueID = "date_departure" Then
							vNewRow.DateDeparture = vValueText;
							vDepartureDate = vValueText;
						EndIf;
						If vValueID = "amount_reason" Then
							vNewRow.AmountReason = vValueText;
						EndIf;
						If vValueID = "customer_city" Then
							vNewRow.CustomerCity = vValueText;
						EndIf;
						If vValueID = "opportunities" Then
							vNewRow.Opportunities = vValueText;
						EndIf;
						If vValueID = "date_received" Then
							vNewRow.DateReceived = vValueText;
						EndIf;
						If vValueID = "rooms_occupancies" Then  //
							vRoomOccuppationsTable = New ValueTable;
							vRoomOccuppationsTable.Columns.Add("RoomID");
							vRoomOccuppationsTable.Columns.Add("Occupancy");
							vRoomsOccupPositions = vValuePosition.GetElementByTagName("struct");
							For Each vRoomsOccupPosition In vRoomsOccupPositions Do
								vRoomsOccupValues = vRoomsOccupPosition.GetElementByTagName("int");
								If vRoomsOccupValues.Count() = 2 Then
									vRoomOccupID = vRoomsOccupValues[0].TextContent;
									vRoomOccupancy = vRoomsOccupValues[1].TextContent;
									vNewRoomOccupRow = vRoomOccuppationsTable.Add();
									vNewRoomOccupRow.RoomID = vRoomOccupID;
									vNewRoomOccupRow.Occupancy = vRoomOccupancy;
								EndIf;
							EndDo;
							vNewRow.RoomsOccupancies = vRoomOccuppationsTable;
						EndIf;
						If vValueID = "date_arrival" Then
							vNewRow.DateArrival = vValueText;
							vArrivalDate = vValueText;
						EndIf;
						If vValueID = "status" Then
							vNewRow.Status = vValueText;							
							If vValueText = "1" Then
								vNewRow.StatusDescription = "Confirmed";
							ElsIf vValueText = "2" Then
								vNewRow.StatusDescription = "Waiting for approval";
							ElsIf vValueText = "3" Then
								vNewRow.StatusDescription = "Refused";
							ElsIf vValueText = "4" Then
								vNewRow.StatusDescription = "Accepted";
							ElsIf vValueText = "5" Then
								vNewRow.StatusDescription = "Deleted";
							ElsIf vValueText = "6" Then
								vNewRow.StatusDescription = "Deleted with penalty";
							EndIf;
							vGReservRow.ReservationStatus = vValueText;
						EndIf;
						If vValueID = "channel_reservation_code" Then
							vNewRow.ChannelReservationCode = vValueText;
						EndIf;
						If vValueID = "customer_phone" Then
							vNewRow.CustomerPhone = Left(vValueText, 50);
							vClientInfo.ClientPhone = Left(StrReplace(vValueText, "--", ""), 50);
						EndIf;
						If vValueID = "orig_amount" Then
							vNewRow.OrigAmount = vValueText;
						EndIf;
						If vValueID = "men" Then
							vNewRow.Men = vValueText;  
							vNumberOfPersons = vNumberOfPersons + Number(vValueText);
						EndIf;
						If vValueID = "customer_notes" Then
							If ValueIsFilled(vGReservRow.ReservationRemarks) Then
								vGReservRow.ReservationRemarks = vGReservRow.ReservationRemarks + Chars.LF + StrReplace(vValueText, "--", "");
							Else
								vGReservRow.ReservationRemarks = StrReplace(vValueText, "--", "");
							EndIf;
						EndIf;
						If vValueID = "customer_address" Then
							vNewRow.CustomerAddress = vValueText;
						EndIf;
						If vValueID = "addons_list" Then  //
							vNewRow.AddonsList = vValueText;
						EndIf;
						If vValueID = "status_reason" Then
							vNewRow.StatusReason = vValueText;
						EndIf;
						If vValueID = "roomnight" Then
							vNewRow.Roomnight = vValueText;
						EndIf;
						If vValueID = "customer_language" Then
							vNewRow.CustomerLanguage = vValueText;
						EndIf;
						If vValueID = "amount" Then
							vNewRow.Amount = vValueText;
							If ValueIsFilled(vGReservRow.ReservationRemarks) Then
								vGReservRow.ReservationRemarks = vGReservRow.ReservationRemarks + Chars.LF + NStr("en='WuBook Amount: ';ru='Общая стоимость в WuBook: ';de='WuBook Betrag: '")+TrimAll(vValueText);
							Else
								vGReservRow.ReservationRemarks = NStr("en='WuBook Amount: ';ru='Общая стоимость в WuBook: ';de='WuBook Betrag: '")+TrimAll(vValueText);
							EndIf;
						EndIf;
						If vValueID = "room_opportunities" Then
							vNewRow.RoomOpportunities = vValueText;
						EndIf;
						If vValueID = "discount" Then
							vDiscountMembers = vValuePosition.GetElementByTagName("member");
							For Each vDiscountMember In vDiscountMembers Do
								vDiscountMemberName = vDiscountMember.GetElementByTagName("name");
								If vDiscountMemberName.Count() = 1 Then
									If vDiscountMemberName[0].TextContent = "value" Then
										
									ElsIf vDiscountMemberName[0].TextContent = "type" Then
										
									EndIf;
								EndIf;
							EndDo;
						EndIf;
					EndDo;
					WriteLogEvent(vLogTag, EventLogLevel.Information, , Undefined, vRetString);
					vGReservRow.NumberOfPersons = vNumberOfPersons;
					vGReservRow.AccommodationType = "";
					vGReservRow.Client = vClientInfo;
					vGReservRow.DoPosting = True;
					vGReservRow.ExternalSystemCode = pExternalInteractionRef.InteractionID;
					vArrivalTextDate = StrReplace(vArrivalDate, "/", "");
					vDepartureTextDate = StrReplace(vDepartureDate, "/", "");
					vGReservRow.PeriodFrom = Date(Number(Mid(vArrivalTextDate, 5, 4)), Number(Mid(vArrivalTextDate, 3, 2)), Number(Mid(vArrivalTextDate, 1, 2)));
					vGReservRow.PeriodTo = Date(Number(Mid(vDepartureTextDate, 5, 4)), Number(Mid(vDepartureTextDate, 3, 2)), Number(Mid(vDepartureTextDate, 1, 2)));
					vAdd = True;
					If BegOfDay(vGReservRow.PeriodFrom) < BegOfDay(CurrentSessionDate()) And pDateFrom = Undefined And pDateTo = Undefined Then
						vAdd = False;
					EndIf;
					If vAdd Then
						If ValueIsFilled(vGReservRow.RoomType) Then
							vRoomTypes = vGReservRow.RoomType;
							vCommaPosition = Find(vRoomTypes, ",");
							If vCommaPosition > 0 Then
								vRoomType = Mid(vRoomTypes, 1, vCommaPosition-1); 
							Else
								vRoomType = vRoomTypes;
							EndIf;
							vRTNumberOfPersons = 0;
							If TypeOf(vRoomOccuppationsTable) = Type("ValueTable") And vRoomOccuppationsTable.Count() > 0 Then
								vFindedRow = vRoomOccuppationsTable.Find(vRoomType, "RoomID");
								If vFindedRow <> Undefined Then
									vRTNumberOfPersons = vFindedRow.Occupancy;
								EndIf;
							EndIf;
							vGReservRow.RoomType = TrimAll(vRoomType);
							vRetXDTORow = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalGroupReservationRow"));
							vInsertedClientInfo = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
							FillPropertyValues(vRetXDTORow, vGReservRow,,"CustomerData");
							FillPropertyValues(vInsertedClientInfo, vRetXDTORow.Client);
							vInd = 1;
							vRetXDTORow.ReservationCode = vRetXDTORow.ReservationCode + String(vInd);
							// Find RT subroom
							Try
								vRoomTypeRows = vQryResult.FindRows(New Structure("ObjectExternalCode, ObjectTypeName", vRetXDTORow.RoomType, "RoomTypes"));
								If vRoomTypeRows.Count() > 0 Then
									vRoomTypeRow = vRoomTypeRows.Get(0);
								Else
									vRoomTypeRows = vQryResult.FindRows(New Structure("ObjectExternalCode, ObjectTypeName", vRetXDTORow.RoomType, "VirtualRoomTypes"));
									If vRoomTypeRows.Count() > 0 Then
										vRoomTypeRow = vRoomTypeRows.Get(0);
									Else
										Raise "No room type found!";
									EndIf;
								EndIf;
							Except
								Raise "No room type found!";
							EndTry;
							Try
								vAccTemplateRows = vQryResult.FindRows(New Structure("ObjectExternalCode, ObjectTypeName", vRetXDTORow.RoomType, "AccommodationTemplates"));
								If vAccTemplateRows.Count() > 0 Then
									vAccTemplateRow = vAccTemplateRows.Get(0);
								Else
									vAccTemplateRows = vQryResult.FindRows(New Structure("ObjectExternalCode, ObjectTypeName", vRetXDTORow.RoomType, "VirtualAccommodationTemplates"));
									If vAccTemplateRows.Count() > 0 Then
										vAccTemplateRow = vAccTemplateRows.Get(0);
									Else
										Raise "No accommodation template found!";
									EndIf;
								EndIf;
							Except
								Raise "No accommodation template found!";
							EndTry;
							If vAccTemplateRow <> Undefined Then
								If vAccTemplateRow.ObjectRef.AccommodationTypes.Count() > 1 Then
									vIsSubRoom = True;
								EndIf;
								vRetXDTORow.AccommodationType = vAccTemplateRow.ObjectRef.AccommodationTypes.Get(0).AccommodationType.Code;
							EndIf;
							If Number(vRTNumberOfPersons) > 0 Then
								vRetXDTORow.NumberOfPersons = Number(vRTNumberOfPersons);
							EndIf;
							vRetXDTO.WriteExternalGroupReservationRow.Add(vRetXDTORow);
							While vCommaPosition > 0 Do
								vRoomTypes = Mid(vRoomTypes, vCommaPosition+1);
								vCommaPosition = Find(vRoomTypes, ",");
								If vCommaPosition > 0 Then
									vRoomType = Mid(vRoomTypes, 1, vCommaPosition-1); 
								Else
									vRoomType = vRoomTypes;
								EndIf;
								vRTNumberOfPersons = 0;
								If TypeOf(vRoomOccuppationsTable) = Type("ValueTable") And vRoomOccuppationsTable.Count() > 0 Then
									vFindedRow = vRoomOccuppationsTable.Find(vRoomType, "RoomID");
									If vFindedRow <> Undefined Then
										vRTNumberOfPersons = vFindedRow.Occupancy;
									EndIf;
								EndIf;
								vGReservRow.RoomType = TrimAll(vRoomType);
								vRetXDTORow = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalGroupReservationRow"));
								vInsClientInfo = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
								FillPropertyValues(vInsClientInfo, vInsertedClientInfo);
								vGReservRow.Client = vInsClientInfo;
								FillPropertyValues(vRetXDTORow, vGReservRow,,"CustomerData");
								vInd = vInd + 1;
								vRetXDTORow.ReservationCode = vRetXDTORow.ReservationCode + String(vInd);
								// Find RT subroom
								Try
									vRoomTypeRows = vQryResult.FindRows(New Structure("ObjectExternalCode, ObjectTypeName", vRetXDTORow.RoomType, "RoomTypes"));
									If vRoomTypeRows.Count() > 0 Then
										vRoomTypeRow = vRoomTypeRows.Get(0);
									Else
										vRoomTypeRows = vQryResult.FindRows(New Structure("ObjectExternalCode, ObjectTypeName", vRetXDTORow.RoomType, "VirtualRoomTypes"));
										If vRoomTypeRows.Count() > 0 Then
											vRoomTypeRow = vRoomTypeRows.Get(0);
										Else
											Raise "No room type found!";
										EndIf;
									EndIf;
								Except
									Raise "No room type found!";
								EndTry;
								
								Try
									vAccTemplateRows = vQryResult.FindRows(New Structure("ObjectExternalCode, ObjectTypeName", vRetXDTORow.RoomType, "AccommodationTemplates"));
									If vAccTemplateRows.Count() > 0 Then
										vAccTemplateRow = vAccTemplateRows.Get(0);
									Else
										vAccTemplateRows = vQryResult.FindRows(New Structure("ObjectExternalCode, ObjectTypeName", vRetXDTORow.RoomType, "VirtualAccommodationTemplates"));
										If vAccTemplateRows.Count() > 0 Then
											vAccTemplateRow = vAccTemplateRows.Get(0);
										Else
											Raise "No accommodation template found!";
										EndIf;
									EndIf;
								Except
									Raise "No accommodation template found!";
								EndTry;
								If vAccTemplateRow <> Undefined Then
									If vAccTemplateRow.ObjectRef.AccommodationTypes.Count() > 1 Then
										vIsSubRoom = True;
									EndIf;
									vRetXDTORow.AccommodationType = vAccTemplateRow.ObjectRef.AccommodationTypes.Get(0).AccommodationType.Code;
								EndIf;
								If Number(vRTNumberOfPersons) > 0 Then
									vRetXDTORow.NumberOfPersons = Number(vRTNumberOfPersons);
								EndIf;
								vRetXDTO.WriteExternalGroupReservationRow.Add(vRetXDTORow);
							EndDo;
						EndIf;
					EndIf;
				EndIf;
			EndDo;
			vReturnStructure.Value = vReturnTable;
		EndIf;
	Else
		Return NStr("en='XML is wrong';ru='Неправильное форматирование XML';de='Falsche XML-Formatierung'");
	EndIf;
	
	UpdateInteractionParametersSession(pExternalInteractionRef);
	
	vAllotment = pExternalInteractionRef.Allotment;
	If vRetXDTO <> Undefined Then	
		vAnnulationIndexesList = New ValueList;
		vInd = 0;
		vRetRowsToAddArray = New Array;
		For Each vXDTORow In vRetXDTO.WriteExternalGroupReservationRow Do
			// Room quota
			If ValueIsFilled(vAllotment) Then
				vXDTORow.RoomQuota = TrimAll(vAllotment.Code);
			EndIf;
			vAnnul = False;
			// HOTEL
			vXDTORow.Hotel = TrimAll(pExternalInteractionRef.Hotel.Code);
			// CUSTOMERS
			vCustomerRows = vQryResult.FindRows(New Structure("ObjectExternalCode, ObjectTypeName", vXDTORow.Customer, "Customers"));
			vXDTORow.Customer = "";
			vCustomer = Catalogs.Customers.EmptyRef();
			If vCustomerRows.Count() > 0 Then
				For Each vRow In vCustomerRows Do
					vCustomer = vRow.ObjectRef;
					vXDTORow.Customer = TrimAll(vRow.ObjectRef.Code);
					If ValueIsFilled(vRow.ObjectRef.AgentCommissionType) Then
						vXDTORow.Agent = TrimAll(vRow.ObjectRef.Code);
					EndIf;
				EndDo;
			EndIf;
			If pExternalInteractionRef.UseClient Then
				vXDTORow.Customer = "USE_CLIENT";
			EndIf;
			
			If ValueIsFilled(vXDTORow.RoomRate) Then
				If vXDTORow.RoomRate = "-1" Then
					vXDTORow.RoomRate = "0"
				EndIf;
				// Temporary time check
				vTimeWas = False;
				For Each vTimeCheckRow In vTimeCheckTable Do
					If vTimeCheckRow.ReservationID = vXDTORow.GroupCode Then
						If ValueIsFilled(vTimeCheckRow.Time) Then
							Try
								vXDTORow.PeriodFrom = BegOfDay(vXDTORow.PeriodFrom) + (Number(Left(vTimeCheckRow.Time,2))*60*60) + (Number(Right(vTimeCheckRow.Time,2))*60);
								vTimeWas = True;
								Break;
							Except
								vTimeWas 	= False;
								vError 		= ErrorDescription();
								WriteLogEvent(pExternalInteractionRef.InteractionID + "_TimeCheck", EventLogLevel.Warning,,CurrentSessionDate(), "Error! Cant set time from XML " + vError);
							EndTry;
						EndIf;
					EndIf;
				EndDo;
				Try
					vRoomRate = cmGetObjectRefByExternalSystemCode(pExternalInteractionRef.Hotel, pExternalInteractionRef.InteractionID, "RoomRates", vXDTORow.RoomRate);
					
					If NOT ValueIsFilled(vRoomRate) Then
						vRoomRate = cmGetObjectRefByExternalSystemCode(pExternalInteractionRef.Hotel, pExternalInteractionRef.InteractionID, "VirtualRoomRates", vXDTORow.RoomRate);	 
					EndIf;
				Except
					vRoomRate = Undefined;
				EndTry;
				
				If ValueIsFilled(vRoomRate) Then
					vXDTORow.RoomRate = vRoomRate.Code;
					If NOT vTimeWas Then 				 
						If ValueIsFilled(vRoomRate.DefaultCheckInTime) Or ValueIsFilled(vRoomRate.DefaultCheckOutTime) Then
							vXDTORow.PeriodFrom = BegOfDay(vXDTORow.PeriodFrom) + (vRoomRate.DefaultCheckInTime - BegOfDay(vRoomRate.DefaultCheckInTime));
						Else
							vXDTORow.PeriodFrom = BegOfDay(vXDTORow.PeriodFrom) + 43200;
						EndIf;
					EndIf;
					
					If ValueIsFilled(vRoomRate.ReferenceHour) Then
						vXDTORow.PeriodTo = BegOfDay(vXDTORow.PeriodTo) + (vRoomRate.ReferenceHour - BegOfDay(vRoomRate.ReferenceHour));
					Else
						If ValueIsFilled(vRoomRate.DefaultCheckInTime) Or ValueIsFilled(vRoomRate.DefaultCheckOutTime) Then
							vXDTORow.PeriodTo = BegOfDay(vXDTORow.PeriodTo) + (vRoomRate.DefaultCheckOutTime - BegOfDay(vRoomRate.DefaultCheckOutTime));
						Else
							vXDTORow.PeriodTo = BegOfDay(vXDTORow.PeriodTo) + 43200;
						EndIf;
					EndIf;
				ElsIf NOT vTimeWas Then
					vXDTORow.PeriodFrom 	= BegOfDay(vXDTORow.PeriodFrom) + 43200;
					vXDTORow.PeriodTo		= BegOfDay(vXDTORow.PeriodTo) + 43200;
				EndIf;
				
			EndIf;
			vReservationStatusRow = vQryResult.FindRows(New Structure("ObjectExternalCode, ObjectTypeName", vXDTORow.ReservationStatus, "ReservationStatuses"));
			If vReservationStatusRow.Count() > 0 Then
				If vXDTORow.ReservationStatus = "3" Or vXDTORow.ReservationStatus = "5" Or vXDTORow.ReservationStatus = "6" Then
					vAnnulationIndexesList.Add(vInd);
					vAnnulationStatus = vReservationStatusRow[0].ObjectRef;
					cmCancelGroupReservation(vXDTORow.GroupCode, vXDTORow.Hotel, pExternalInteractionRef.InteractionID, , , , vAnnulationStatus);
					vReservationsAray.Add(vXDTORow.GroupCode);
					vAnnul = True;
					Continue;
				EndIf;
				vXDTORow.ReservationStatus = TrimAll(vReservationStatusRow[0].ObjectRef.Code);
			EndIf;
			vAccTemplateRows = vQryResult.FindRows(New Structure("ObjectExternalCode, ObjectTypeName", vXDTORow.RoomType, "AccommodationTemplates"));
			If vAccTemplateRows.Count() > 0 Then
				vAccTemplate = vAccTemplateRows.Get(0).ObjectRef;
			Else
				vAccTemplateRows = vQryResult.FindRows(New Structure("ObjectExternalCode, ObjectTypeName", vXDTORow.RoomType, "VirtualAccommodationTemplates"));
				If vAccTemplateRows.Count() > 0 Then
					vAccTemplate = vAccTemplateRows.Get(0).ObjectRef;
				EndIf;
			EndIf;			
			vRoom = New UUID;
			vXDTORow.Room = String(vRoom);
			vXDTORow.NumberOfPersons = 1;
			vLastReservationCode = vXDTORow.ReservationCode;
			For Each vAccTypesRow In vAccTemplate.AccommodationTypes Do
				If vAccTemplate.AccommodationTypes.IndexOf(vAccTypesRow) > 0 Then
					vRetInsertRow = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalGroupReservationRow"));
					vInsClientInfo = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
					FillPropertyValues(vRetInsertRow, vXDTORow,,"Client, CustomerData");
					vRetInsertRow.Client = vInsClientInfo;
					vRetInsertRow.AccommodationType = TrimAll(vAccTypesRow.AccommodationType.Code);
					vRetInsertRow.ReservationCode = vLastReservationCode+String(vAccTemplate.AccommodationTypes.IndexOf(vAccTypesRow));
					vRetRowsToAddArray.Add(vRetInsertRow);
				EndIf;
			EndDo;
			vInd = vInd + 1;
		EndDo;
		vAnnulationIndexesList.SortByValue(SortDirection.Desc);
		For Each vRowsIndexes In vAnnulationIndexesList Do
			vRetXDTO.WriteExternalGroupReservationRow.Delete(vRowsIndexes.Value);
		EndDo;
		For Each vRetRowsToAddArrayItem In vRetRowsToAddArray Do
			vRetXDTO.WriteExternalGroupReservationRow.Add(vRetRowsToAddArrayItem);
		EndDo;
		If vRetXDTO.WriteExternalGroupReservationRow.Count() > 0 Then
			vXDTOArray 		= New Array;
			vGroupsArray 	= New Array;
			For Each vRow In vRetXDTO.WriteExternalGroupReservationRow Do
				vGroupWas = False;
				For Each vGroup In vGroupsArray Do
					If vGroup = vRow.GroupCode Then
						vGroupWas = True;
						Break;
					EndIf;
				EndDo;
				If NOT vGroupWas Then
					vNewXDTO 	= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalGroupReservation"));
					vGroupsArray.Add(vRow.GroupCode);
					For Each vRow2 In vRetXDTO.WriteExternalGroupReservationRow Do
						If vRow.GroupCode = vRow2.GroupCode Then
							vNewRow 	= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalGroupReservationRow"));
							vClient 	= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
							FillPropertyValues(vNewRow, vRow2,,"Client, CustomerData");
							FillPropertyValues(vClient, vRow2.Client);
							vNewRow.Client = vClient;	
							If ValueIsFilled(vNewRow.RoomType) Then
								Try
									vRoomType = cmGetObjectRefByExternalSystemCode(pExternalInteractionRef.Hotel, pExternalInteractionRef.InteractionID, "RoomTypes", vNewRow.RoomType);
									
									If NOT ValueIsFilled(vRoomType) Then
										vRoomType = cmGetObjectRefByExternalSystemCode(pExternalInteractionRef.Hotel, pExternalInteractionRef.InteractionID, "VirtualRoomTypes", vNewRow.RoomType);	 
									EndIf;
								Except
									vRoomType = Undefined;
								EndTry;
								
								If ValueIsFilled(vRoomType) Then
									vNewRow.RoomType = vRoomType.Code;
								EndIf;
							EndIf;
							vNewXDTO.WriteExternalGroupReservationRow.Add(vNewRow);
						EndIf;
					EndDo;
					vXDTOArray.Add(vNewXDTO);
				EndIf;	
			EndDo;
			For Each vXDTO In vXDTOArray Do
				vXDTOObj = cmWriteExternalGroupReservation(vXDTO, vDefaultLanguageCode, True);
				If NOT ValueIsFilled(vXDTOObj.ErrorDescription) Then
					For Each vXDTORow In vXDTO.WriteExternalGroupReservationRow Do 
						vReservationsAray.Add(vXDTORow.GroupCode);
						Break;
					EndDo;
				EndIf;
			EndDo;				
		EndIf;
		If vReservationsAray.Count() > 0 Then
			Mark_bookings(pExternalInteractionRef, pLodgingCode, vReservationsAray);
		EndIf;
	EndIf;
	Return vReturnStructure;
EndFunction // FetchBookings

// --------------------------------------------------------------------------------
// Function - Mark all bookings
//
// Parameters:
//  pExternalInteractionRef	 - CatalogRef.ExternalSystemInteractions	 - 
//  pLodgingCode			 - String	 - 
// 
// Returns:
//  Structure - Params 
//
Procedure MarkAllBookings(pExternalInteractionRef, pLodgingCode) Export	
	Mark_bookings(pExternalInteractionRef, pLodgingCode, New Array);
EndProcedure

// --------------------------------------------------------------------------------
//  =======USE ONLY AT SERVER========
//  Returns the following params:
//  ID: the plan id (use this to identify the plan)
//  Name: the plan name
//  Daily: daily = 1 means the plan is a daily pricing plan
//  Vpid: is the ID of the linked pricing plan (Only if a pricing plan is virtual)
//  Variation: is a float, the value of the derivation (Only if a pricing plan is virtual)
//  Variation_type: can be -2, -1, 1, 2 (Only if a pricing plan is virtual)
//  -2: This plan is a discount. Value is a fixed amount
//  -1: This plan is a discount. Value is a percentage
//  1: This plan increases prices. Value is a percentage
//  2: This plan increases prices. Value is a fixed amount
//  -----------------------------------------------------------------------------
//
// Parameters:
//  pExternalInteractionRef	 - CatalogRef.ExternalSystemInteractions	 - 
//  pLodgingCode			 - String	 - 
//  pDoRepeat				 - String	 - 
// 
// Returns:
//  Structure - Params 
//
Function GetPricingPlans(pExternalInteractionRef, pLodgingCode, pDoRepeat = True) Export
	If Not ValueIsFilled(pExternalInteractionRef) Or Not ValueIsFilled(pLodgingCode) Then
		Return NStr("en='Check parameters';ru='Проверьте правильность ввода данных';de='Überprüfen Sie die Richtigkeit der Dateneingabe'");
	EndIf;
	// XML
	
	vXMLDocument = New XMLWriter;
	vXMLDocument.SetString();
	vXMLDocument.WriteXMLDeclaration();
	vXMLDocument.WriteStartElement("methodCall");
		vXMLDocument.WriteStartElement("methodName");
			vXMLDocument.WriteText("get_pricing_plans");
		vXMLDocument.WriteEndElement();	
		vXMLDocument.WriteStartElement("params");
			vXMLDocument.WriteStartElement("param");
				vXMLDocument.WriteStartElement("value");
			        vXMLDocument.WriteStartElement("string");
			        	vXMLDocument.WriteText(pExternalInteractionRef.SessionID);
					vXMLDocument.WriteEndElement();
				vXMLDocument.WriteEndElement();
			vXMLDocument.WriteEndElement();
			vXMLDocument.WriteStartElement("param");
				vXMLDocument.WriteStartElement("value");
			    	vXMLDocument.WriteStartElement("int");
			        	vXMLDocument.WriteText(pLodgingCode);                                    
					vXMLDocument.WriteEndElement();
				vXMLDocument.WriteEndElement();
			vXMLDocument.WriteEndElement();
		vXMLDocument.WriteEndElement();	
	vXMLDocument.WriteEndElement();
	vXML = vXMLDocument.Close();
	
	vRequestHeaders = New Map;
	vRequestHeaders.Insert("Content-Type", "text/xml;charset=utf-8");
	vRequestHeaders.Insert("Content-Lenght", StrLen(vXML));
	
	vResponse 	= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pExternalInteractionRef, vRequestHeaders, "xrws", "POST", "get_pricing_plans", vXML, "text/xml;charset=utf-8");
	
	// XML Read
	vReadXML = New XMLReader;
	vReadXML.SetString(vResponse.Body);
	
	vDOMBuilder = New DOMBuilder;
	vDOMDocument = vDOMBuilder.Read(vReadXML);
	
	vReturnStructure = New Structure("StatusID, Value");
	
	vStatusIDPostion = vDOMDocument.GetElementByTagName("int");
	If vStatusIDPostion.Count() > 0 Then
		vStatusID = vStatusIDPostion[0].TextContent;
		vReturnStructure.StatusID = vStatusID;
		
		If vStatusID <> "0" Then
			vRefreshTokenResult = RefreshToken(pExternalInteractionRef);
			If ValueIsFilled(vRefreshTokenResult) Then
				vReturnStructure.Value = vRefreshTokenResult;
			Else
				If pDoRepeat Then
					// Try again
					vReturnStructure = GetPricingPlans(pExternalInteractionRef, pLodgingCode, False);
				Else
					vValuePostion = vDOMDocument.GetElementByTagName("string");
					vValue = vValuePostion[0].TextContent;
					vReturnStructure.Value = vValue;
				EndIf;
			EndIf;
		Else
			// Return table
			vReturnTable = New ValueTable;
			vReturnTable.Columns.Add("ID");
			vReturnTable.Columns.Add("Name");
			vReturnTable.Columns.Add("Daily");
			vReturnTable.Columns.Add("Vpid");
			vReturnTable.Columns.Add("Variation");
			vReturnTable.Columns.Add("VariationType");
			
			vValuePostion = vDOMDocument.GetElementByTagName("struct");
			For Each vStruct In vValuePostion Do
				vElements = vStruct.GetElementByTagName("name");
				vNewRow = vReturnTable.Add();
				For Each vElement In vElements Do
					If vElement.TextContent = "id" Then
						vNewRow.ID = vElement.NextSibling.TextContent;
					EndIf;
					If vElement.TextContent = "daily" Then
						vNewRow.Daily = vElement.NextSibling.TextContent;
					EndIf;
					If vElement.TextContent = "name" Then
						vNewRow.Name = vElement.NextSibling.TextContent;
					EndIf;
					If vElement.TextContent = "vpid" Then
						vNewRow.Vpid = vElement.NextSibling.TextContent;
					EndIf;
					If vElement.TextContent = "variation" Then
						vNewRow.Variation = vElement.NextSibling.TextContent;
					EndIf;
					If vElement.TextContent = "variation_type" Then
						vNewRow.VariationType = vElement.NextSibling.TextContent;
					EndIf;
				EndDo;
			EndDo;
			vReturnStructure.Value = vReturnTable;
		EndIf;
	Else
		Return NStr("en='XML is wrong';ru='Неправильное форматирование XML';de='Falsche XML-Formatierung'");
	EndIf;
	
	Return vReturnStructure;
EndFunction // GetPricingPlans

// --------------------------------------------------------------------------------
//  Returns the rooms for the property identified by lcode. For Each room Wired! returns the following params:
//  ID: the room id (use this to identify the room)
//  Name: the room name
//  Shortname: the room shortname: unique between the facility
//  Occupancy: the room occupancy
//  Men: adults (note: adults + children = occupancy)
//  Children: children (note: adults + children = occupancy)
//  Subroom: room mother
//  Board: Room board
//  When subroom is 0 (zero), the returned room is a true, independent room.
//  When subroom is not 0, his value is a room id. 
//  This means this room is sharing the availability with the room identified by subroom. 
//  Only availability is shared: you can update the other values (price, restrictions and so on) in a free way.
//  When you try to update a subroom availability, nothing happens.
//  -----------------------------------------------------------------------------
//
// Parameters:
//  pExternalInteractionRef	 - CatalogRef.ExternalSystemInteractions 
//  pLodgingCode			 - String	  
//  pDoRepeat				 - Boolean	  
// 
// Returns:
//  Structure - Params 
//
Function FetchRooms(pExternalInteractionRef, pLodgingCode, pDoRepeat = True) Export
	If Not ValueIsFilled(pExternalInteractionRef) Or Not ValueIsFilled(pLodgingCode) Then
		Return NStr("en='Check parameters';ru='Проверьте правильность ввода данных';de='Überprüfen Sie die Richtigkeit der Dateneingabe'");
	EndIf;
	
	// XML
	
	vXMLDocument = New XMLWriter;
	vXMLDocument.SetString();
	vXMLDocument.WriteXMLDeclaration();
	vXMLDocument.WriteStartElement("methodCall");
		vXMLDocument.WriteStartElement("methodName");
			vXMLDocument.WriteText("fetch_rooms");
		vXMLDocument.WriteEndElement();	
		vXMLDocument.WriteStartElement("params");
			vXMLDocument.WriteStartElement("param");
				vXMLDocument.WriteStartElement("value");
			        vXMLDocument.WriteStartElement("string");
			        	vXMLDocument.WriteText(TrimAll(pExternalInteractionRef.SessionID));
					vXMLDocument.WriteEndElement();
				vXMLDocument.WriteEndElement();
			vXMLDocument.WriteEndElement();
			vXMLDocument.WriteStartElement("param");
				vXMLDocument.WriteStartElement("value");
			    	vXMLDocument.WriteStartElement("int");
			        	vXMLDocument.WriteText(pLodgingCode);                                    
					vXMLDocument.WriteEndElement();
				vXMLDocument.WriteEndElement();
			vXMLDocument.WriteEndElement();
		vXMLDocument.WriteEndElement();	
	vXMLDocument.WriteEndElement();
	vXML = vXMLDocument.Close();
	
	vRequestHeaders = New Map;
	vRequestHeaders.Insert("Content-Type", "text/xml;charset=utf-8");
	vRequestHeaders.Insert("Content-Lenght", StrLen(vXML));
	
	vResponse 	= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pExternalInteractionRef, vRequestHeaders, "xrws", "POST", "fetch_rooms", vXML, "text/xml;charset=utf-8");
	
	// XML Read
	vReadXML = New XMLReader;
	vReadXML.SetString(vResponse.Body);
	
	vDOMBuilder = New DOMBuilder;
	vDOMDocument = vDOMBuilder.Read(vReadXML);
	
	vReturnStructure = New Structure("StatusID, Value");
	
	vStatusIDPostion = vDOMDocument.GetElementByTagName("int");
	If vStatusIDPostion.Count() > 0 Then
		vStatusID = vStatusIDPostion[0].TextContent;
		vReturnStructure.StatusID = vStatusID;
		
		If vStatusID <> "0" Then
			vValuePostion = vDOMDocument.GetElementByTagName("string");
			vValue = vValuePostion[0].TextContent;
			vReturnStructure.Value = vValue;
			
			vRefreshTokenResult = RefreshToken(pExternalInteractionRef);
			If ValueIsFilled(vRefreshTokenResult) Then
				vReturnStructure.Value = vRefreshTokenResult;
			Else
				If pDoRepeat Then
					// Try again
					vReturnStructure = FetchRooms(pExternalInteractionRef, pLodgingCode, False);
				Else
					vValuePostion = vDOMDocument.GetElementByTagName("string");
					vValue = vValuePostion[0].TextContent;
					vReturnStructure.Value = vValue;
				EndIf;
			EndIf;
		Else
			// Return table
			vReturnTable = New ValueTable;
			vReturnTable.Columns.Add("ID");
			vReturnTable.Columns.Add("Name");
			vReturnTable.Columns.Add("Shortname");
			vReturnTable.Columns.Add("Occupancy");
			vReturnTable.Columns.Add("Men");
			vReturnTable.Columns.Add("Children");
			vReturnTable.Columns.Add("Subroom");
			vReturnTable.Columns.Add("Board");
			vReturnTable.Columns.Add("Boards");
			
			vValuePostion = vDOMDocument.GetElementByTagName("struct");
			For Each vStruct In vValuePostion Do
				vNewRow = vReturnTable.Add();
				For Each vElement In vStruct.ChildNodes Do
					vValueID = vElement.ChildNodes[0].TextContent;
					vValue = vElement.ChildNodes[1].TextContent;
					Try
						vNewRow[vValueID] = vValue;
					Except
					EndTry;
				EndDo;
			EndDo;
			vReturnStructure.Value = vReturnTable;
		EndIf;
	Else
		Return NStr("en='XML is wrong';ru='Неправильное форматирование XML';de='Falsche XML-Formatierung'");
	EndIf;
	
	Return vReturnStructure;
EndFunction // FetchRooms

#EndRegion
 
#Region Private

// --------------------------------------------------------------------------------
//  Prepare balances table to upload to channel
//
Function GetBalances(pHotel, pAllotment, pPeriodFrom, pPeriodTo, pExtSystemCode = Undefined, pRoomType, pGetVacantRoomsAtMidnight = False)
	TRooms = New ValueTable;
	TRooms.Columns.Add("RoomType");
	TRooms.Columns.Add("Allotment");
	TRooms.Columns.Add("PeriodFrom");
	TRooms.Columns.Add("PeriodTo");
	TRooms.Columns.Add("VacantRooms");
	TRooms.Columns.Add("VacantBeds");
	TRooms.Columns.Add("StopSale");
	
	// Call API to get value table with balances
	vBalances = cmGetRoomQuotaBalances(pHotel,pRoomType , , , , pAllotment, pPeriodFrom, pPeriodTo, pGetVacantRoomsAtMidnight);
	
	// Check for stop internet sales
	For Each vRow In vBalances Do
		r = TRooms.Add();
		r.RoomType = vRow.RoomType;
		If vRow.Period = Null Then
			r.PeriodFrom = BegOfDay(pPeriodFrom);
			r.PeriodTo = BegOfDay(pPeriodTo);
			r.VacantRooms = 0;
			r.VacantBeds = 0;
		Else
			r.PeriodFrom = BegOfDay(vRow.Period);
			r.PeriodTo = r.PeriodFrom;
			If ValueIsFilled(pAllotment) Then
				r.VacantRooms = ?(vRow.RoomsRemains=Null,0,?(vRow.RoomsRemains>0,vRow.RoomsRemains,0));
				r.VacantBeds = ?(vRow.BedsRemains=Null,0,?(vRow.BedsRemains>0,vRow.BedsRemains,0));
			Else
				r.VacantRooms = ?(vRow.RoomsVacant=Null,0,?(vRow.RoomsVacant>0,vRow.RoomsVacant,0));
				r.VacantBeds = ?(vRow.BedsVacant=Null,0,?(vRow.BedsVacant>0,vRow.BedsVacant,0));
			EndIf;
		EndIf;
	EndDo;
	TRooms.Sort("RoomType, Allotment, PeriodFrom, PeriodTo");
	
	// Merge identical values in consequent days to one row
	If TRooms.Count() > 1 Then
		prev = TRooms.Get(0);
		vInd = 1;
		While vInd < TRooms.Count() Do
			curr = TRooms.Get(vInd);
			If curr.RoomType = prev.RoomType Then
				If curr.VacantRooms = prev.VacantRooms 
					And curr.VacantBeds = prev.VacantBeds 
					And curr.StopSale = prev.StopSale
					And curr.PeriodFrom - prev.PeriodTo >= 0 Then
					// Nothing has changed but period,then merge rows - just move PeriodTo to next date
					prev.PeriodTo = curr.PeriodFrom;
					TRooms.Delete(curr);
				Else
					If prev.PeriodFrom = prev.PeriodTo Or prev.PeriodFrom < prev.PeriodTo And prev.PeriodTo < (curr.PeriodFrom - 24 * 3600) Then
						prev.PeriodTo = curr.PeriodFrom - 24 * 3600;
					EndIf;
					// Move previous row 
					prev = curr;
					vInd = vInd + 1;
				EndIf;
			Else
				// Move previous row 
				prev = curr;
				vInd = vInd + 1;
			EndIf;				
		EndDo;
	EndIf;
	
	// Remove room types without mappings
	vRoomTypesWithoutMappings = New ValueList();
	If pExtSystemCode <> Undefined Then
		vInd = 0;
		While vInd < TRooms.Count() Do
			row = TRooms.Get(vInd);
			If vRoomTypesWithoutMappings.FindByValue(row.RoomType) <> Undefined Then
				TRooms.Delete(vInd);
			ElsIf Not cmCheckExternalSystemCodeMapping(pHotel, pExtSystemCode, row.RoomType, "RoomTypes") Then
				vRoomTypesWithoutMappings.Add(row.RoomType);
				TRooms.Delete(vInd);
			Else
				vInd = vInd + 1;
			EndIf;
		EndDo;
	EndIf;
	
	// Check for stop internet sales
	For Each row In TRooms Do
		vRemarks = "";
		row.StopSale = cmIsStopInternetSalePeriod(row.RoomType, row.PeriodFrom, EndOfDay(row.PeriodTo), vRemarks);
	EndDo;
	
	Return TRooms;
EndFunction // GetBalances

// --------------------------------------------------------------------------------
Function GetAllExternalRoomTypesCodes(pHotel, pInteractionID, pRoomType)
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode,
		|	ExternalSystemsObjectCodesMappings.ObjectRef AS ObjectRef,
		|	CASE
		|		WHEN ExternalSystemsObjectCodesMappings.ObjectTypeName = ""VirtualRoomTypes""
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS IsVirtual
		|FROM
		|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
		|WHERE
		|	ExternalSystemsObjectCodesMappings.Hotel = &qHotel
		|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
		|	AND (ExternalSystemsObjectCodesMappings.ObjectTypeName = ""RoomTypes""
		|			OR ExternalSystemsObjectCodesMappings.ObjectTypeName = ""VirtualRoomTypes"")
		|	AND ExternalSystemsObjectCodesMappings.ObjectRef = &qObjectRef";
	
	vQuery.SetParameter("qExternalSystemCode", pInteractionID);
	vQuery.SetParameter("qHotel", pHotel);
	vQuery.SetParameter("qObjectRef", pRoomType);
	
	vQueryResult = vQuery.Execute().Unload();
	
	Return vQueryResult; 	
EndFunction

// --------------------------------------------------------------------------------
Function GetRates(pHotel, pRoomRates, pInteractionParameters, pPeriodFrom, pPeriodTo, pExternalSystemCode, pRoomType, pRoomTypesMappingName = "RoomTypes", pAccTemplate)
	vResult = New ValueTable;
	vResult.Columns.Add("RateCode");
	vResult.Columns.Add("RoomTypeCode");
	vResult.Columns.Add("Period");
	vResult.Columns.Add("Price");
	vHotel = cmGetObjectExternalSystemCodeByRef(pHotel, pExternalSystemCode, "Hotels", pHotel);
	Try
		vRoomType = cmGetObjectExternalSystemCodeByRef(pHotel, pExternalSystemCode, pRoomTypesMappingName, pRoomType);		
	Except
		vRoomType = Undefined;
	EndTry;
	
	vRoomRateArray = New Array;
	For Each vRate In pRoomRates Do
		vRoomRateArray.Add(cmGetObjectExternalSystemCodeByRef(pHotel, pExternalSystemCode, "RoomRates", vRate));
	EndDo;
	vExtraParameters = New Structure("AccTemplateCode, ForSiteminder", pAccTemplate, False);
	Try
		vNewPrices = cmGetAvailableRoomsWithDailyPrices(vHotel, vRoomType, pInteractionParameters.Allotment, pPeriodFrom, pPeriodTo, , vRoomRateArray, 0, 0, New Array , , pExternalSystemCode, , vExtraParameters);
	Except
		vError = ErrorDescription();
		WriteLogEvent(pInteractionParameters.InteractionID + "_cmGetAvailableRoomsWithDailyPrices", EventLogLevel.Error,,CurrentSessionDate(), "Error! " + vError);
		Raise vError; 
	EndTry;
	vCurrentRoomRate = Undefined;
	vRoomRatesTable = New ValueTable;
	For Each vRow In vNewPrices.RoomTypeDailyAvailabilityAndPricesRow Do
		For Each vPriceRow In vRow.RoomTypeDailyPrices.RoomRateDailyPriceRow Do
			If vPriceRow.Price <> Undefined And vPriceRow.Price > 0 Then
				If vPriceRow.RoomRateCode <> vCurrentRoomRate Then
					vRoomRatesTable = GetAllExternalCodesByRoomRate(pHotel, pExternalSystemCode, Catalogs.RoomRates.FindByCode(vPriceRow.RoomRateCode)); 
				EndIf;
				For Each vRoomRateRow In vRoomRatesTable Do
					vNewRow 						= vResult.Add();
					vNewRow.RateCode 				= vRoomRateRow.ObjectExternalCode;
					vNewRow.RoomTypeCode 			= pAccTemplate;
					vNewRow.Period 					= vRow.Period;
					vNewRow.Price 					= vPriceRow.Price;
				EndDo;		
				vCurrentRoomRate = vPriceRow.RoomRateCode; 
			EndIf;
		EndDo;
	EndDo;
	
	vResult.Sort("RateCode, RoomTypeCode, Period");
	Return vResult; 
EndFunction

// --------------------------------------------------------------------------------
Function GetAllExternalCodesByRoomRate(pHotel, pInteractionID, pRoomRate)
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode,
		|	ExternalSystemsObjectCodesMappings.ObjectRef AS ObjectRef
		|FROM
		|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
		|WHERE
		|	ExternalSystemsObjectCodesMappings.Hotel = &qHotel
		|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
		|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = ""RoomRates""
		|	AND ExternalSystemsObjectCodesMappings.ObjectRef = &qObjectRef";
	
	vQuery.SetParameter("qExternalSystemCode", pInteractionID);
	vQuery.SetParameter("qHotel", pHotel);
	vQuery.SetParameter("qObjectRef", pRoomRate);
	
	vQueryResult = vQuery.Execute().Unload();
	
	Return vQueryResult;
EndFunction

// --------------------------------------------------------------------------------
Procedure FillDailyPrices(pInteractionParameters, pHotel, pRoomRate, pRoomType = Undefined, pPeriodFrom, pPeriodTo)
	Try
		vObj 			= DataProcessors.FillRoomRateDailyPrices.Create();
		vObj.Hotel 		= pHotel;
		vObj.RoomType 	= pRoomType;
		vObj.RoomRate 	= pRoomRate;
		vObj.PeriodFrom = BegOfDay(pPeriodFrom);
		vObj.PeriodTo 	= EndOfDay(pPeriodTo);
		vObj.pmDoFill(True);
	Except
		tcCommonFunctionOnClientServer.UserMessage("Error! Failed to fill room rate daily prices
													|Hotel: " + pHotel + " 
													|RoomRate:" + pRoomRate + "
													|RoomType:" + pRoomType + "
													|PeriodFrom:" + BegOfDay(pPeriodFrom) + "
													|PeriodTo:" + EndOfDay(pPeriodTo));
		WriteLogEvent(pInteractionParameters.InteractionID + "_FillDailyPrices", EventLogLevel.Error,,CurrentSessionDate(), "Error! Failed to fill room rate daily prices
						|Hotel: " + pHotel + " 
						|RoomRate:" + pRoomRate + "
						|RoomType:" + pRoomType + "
						|PeriodFrom:" + BegOfDay(pPeriodFrom) + "
						|PeriodTo:" + EndOfDay(pPeriodTo));	
	EndTry;
EndProcedure

// --------------------------------------------------------------------------------
Function GetVirtualObjects(pHotel, pInteractionID, pObjectType)
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode,
		|	ExternalSystemsObjectCodesMappings.ObjectRef AS ObjectRef,
		|	ExternalSystemsObjectCodesMappings.ObjectTypeName AS ObjectTypeName
		|FROM
		|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
		|WHERE
		|	ExternalSystemsObjectCodesMappings.Hotel = &qHotel
		|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
		|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = &qObjectTypeName";
	
	vQuery.SetParameter("qExternalSystemCode", 	pInteractionID);
	vQuery.SetParameter("qHotel", 				pHotel);
	vQuery.SetParameter("qObjectTypeName", 		"Virtual" + pObjectType);
	
	vQueryResult = vQuery.Execute().Unload();
	
	Return vQueryResult;	
EndFunction

// --------------------------------------------------------------------------------
Function FilterRatesTable(pTable, pHotel, pInteractionID)
	vClearArray = New Array;
	For Each vRow In pTable Do
		vQuery = New Query;
		vQuery.Text = 
			"SELECT
			|	RoomRatesTable.ObjectRef AS RoomRate,
			|	RoomTypesTable.ObjectRef AS RoomType
			|FROM
			|	(SELECT
			|		ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode,
			|		ExternalSystemsObjectCodesMappings.ObjectRef AS ObjectRef,
			|		ExternalSystemsObjectCodesMappings.ExternalSystemCode AS ExternalSystemCode
			|	FROM
			|		InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
			|	WHERE
			|		ExternalSystemsObjectCodesMappings.Hotel = &qHotel
			|		AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
			|		AND ExternalSystemsObjectCodesMappings.ObjectRef = &qRoomType
			|		AND ExternalSystemsObjectCodesMappings.ObjectTypeName = ""RoomTypes"") AS RoomTypesTable
			|		INNER JOIN (SELECT
			|			ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode,
			|			ExternalSystemsObjectCodesMappings.ObjectRef AS ObjectRef,
			|			ExternalSystemsObjectCodesMappings.ExternalSystemCode AS ExternalSystemCode
			|		FROM
			|			InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
			|		WHERE
			|			ExternalSystemsObjectCodesMappings.Hotel = &qHotel
			|			AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
			|			AND ExternalSystemsObjectCodesMappings.ObjectRef = &qRoomRate
			|			AND ExternalSystemsObjectCodesMappings.ObjectTypeName = ""RoomRates"") AS RoomRatesTable
			|		ON RoomTypesTable.ExternalSystemCode = RoomRatesTable.ExternalSystemCode";
		
		vQuery.SetParameter("qHotel", pHotel);
		vQuery.SetParameter("qExternalSystemCode", pInteractionID);
		vQuery.SetParameter("qRoomRate", vRow.RoomRate);
		vQuery.SetParameter("qRoomType", vRow.RoomType);
		vQueryResult = vQuery.Execute().Unload();
		If vQueryResult.Count() = 0 Then
			vClearArray.Add(vRow);	
		EndIf;
	EndDo;
	
	For Each vRow In vClearArray Do
		pTable.Delete(vRow);
	EndDo;
	
	Return pTable;
EndFunction

// --------------------------------------------------------------------------------
Function FilterRoomTypesTable(pTable, pHotel, pInteractionID)
	vClearArray = New Array;
	For Each vRow In pTable Do
		vQuery = New Query;
		vQuery.Text = 
			"SELECT
			|	RoomTypesTable.ObjectRef AS RoomType
			|FROM
			|	(SELECT
			|		ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode,
			|		ExternalSystemsObjectCodesMappings.ObjectRef AS ObjectRef,
			|		ExternalSystemsObjectCodesMappings.ExternalSystemCode AS ExternalSystemCode
			|	FROM
			|		InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
			|	WHERE
			|		ExternalSystemsObjectCodesMappings.Hotel = &qHotel
			|		AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
			|		AND ExternalSystemsObjectCodesMappings.ObjectRef = &qRoomType
			|		AND ExternalSystemsObjectCodesMappings.ObjectTypeName = ""RoomTypes"") AS RoomTypesTable";
		
		vQuery.SetParameter("qHotel", pHotel);
		vQuery.SetParameter("qExternalSystemCode", pInteractionID);
		vQuery.SetParameter("qRoomType", vRow.RoomType);
		vQueryResult = vQuery.Execute().Unload();
		If vQueryResult.Count() = 0 Then
			vClearArray.Add(vRow);	
		EndIf;
	EndDo;
	
	For Each vRow In vClearArray Do
		pTable.Delete(vRow);
	EndDo;
	
	Return pTable;
EndFunction

// --------------------------------------------------------------------------------
Function GetAllObjects(pInteractionParameters, pHotel, pObjectType)
	vResult = New Array;
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ExternalSystemsObjectCodesMappings.ObjectRef AS ObjectRef
		|FROM
		|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
		|WHERE
		|	ExternalSystemsObjectCodesMappings.Hotel = &qHotel
		|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = &qObjectTypeName
		|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode";
	
	vQuery.SetParameter("qExternalSystemCode", pInteractionParameters.InteractionID);
	vQuery.SetParameter("qHotel", pHotel);
	vQuery.SetParameter("qObjectTypeName", pObjectType);	
	
	vQueryResult = vQuery.Execute().Unload();	
	For Each vRow In vQueryResult Do
		vResult.Add(vRow.ObjectRef);
	EndDo;
	
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
//  =======USE ONLY AT SERVER========
//  Return: Structure:
//  - StatusID: Status ID (0 - OK, <0 - Error)
//  - Value: If Status ID <0 - Human Readable string of current error, else OK
//  -----------------------------------------------------------------------------
//
Function CreateToken(pServerHost, pServerResource, pLogin, pPassword, pInteractionParameters)
	If Not ValueIsFilled(pLogin) Or Not ValueIsFilled(pPassword) Then
		Return NStr("en='Login error! Check login/password';ru='Ошибка соединения! Проверьте правильность ввода логина/пароля';de='Verbindungsfehler! Prüfen Sie das Login/Passwort'");
	EndIf;
	
	// XML
	
	vXMLDocument = New XMLWriter;
	vXMLDocument.SetString();
	vXMLDocument.WriteXMLDeclaration();
	vXMLDocument.WriteStartElement("methodCall");
		vXMLDocument.WriteStartElement("methodName");
			vXMLDocument.WriteText("acquire_token");
		vXMLDocument.WriteEndElement();	
		vXMLDocument.WriteStartElement("params");
			vXMLDocument.WriteStartElement("param");
				vXMLDocument.WriteStartElement("value");
			        vXMLDocument.WriteStartElement("string");
			        	vXMLDocument.WriteText(pLogin);
					vXMLDocument.WriteEndElement();
				vXMLDocument.WriteEndElement();
			vXMLDocument.WriteEndElement();
			vXMLDocument.WriteStartElement("param");
				vXMLDocument.WriteStartElement("value");
			    	vXMLDocument.WriteStartElement("string");
			        	vXMLDocument.WriteText(pPassword);                                    
					vXMLDocument.WriteEndElement();
				vXMLDocument.WriteEndElement();
			vXMLDocument.WriteEndElement();
			vXMLDocument.WriteStartElement("param");
				vXMLDocument.WriteStartElement("value");
			    	vXMLDocument.WriteStartElement("string");
			        	vXMLDocument.WriteText("clx,m.$#%#$/,.sdm22");                                    
					vXMLDocument.WriteEndElement();
				vXMLDocument.WriteEndElement();
			vXMLDocument.WriteEndElement();
		vXMLDocument.WriteEndElement();	
	vXMLDocument.WriteEndElement();
	vXML = vXMLDocument.Close();
	
	vRequestHeaders = New Map;
	vRequestHeaders.Insert("Content-Type", "text/xml;charset=utf-8");
	vRequestHeaders.Insert("Content-Lenght", StrLen(vXML));
	
	vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, vRequestHeaders, pServerResource, "POST", "acquire_token", vXML, "text/xml;charset=utf-8");
	
	// XML Read
	vReadXML = New XMLReader;
	vReadXML.SetString(vResponse.Body);
	
	vDOMBuilder = New DOMBuilder;
	vDOMDocument = vDOMBuilder.Read(vReadXML);
	vStatusIDPostion = vDOMDocument.GetElementByTagName("int");
	If vStatusIDPostion.Count() > 0 Then
		vStatusID = vStatusIDPostion[0].TextContent;
		
		vValuePostion = vDOMDocument.GetElementByTagName("string");
		If vValuePostion.Count() > 0 Then
			vValue = vValuePostion[0].TextContent;
		Else
			Return NStr("en='XML is wrong';ru='Неправильное форматирование XML';de='Falsche XML-Formatierung'");
		EndIf;
	Else
		Return NStr("en='XML is wrong';ru='Неправильное форматирование XML';de='Falsche XML-Formatierung'");
	EndIf;
	
	vReturnStructure = New Structure("StatusID, Value", vStatusID, vValue);
	
	Return vReturnStructure;
EndFunction // GetToken

// --------------------------------------------------------------------------------
//  This call is really powerful and can be used to modify each room values, for each day.
//  This call modifies the rooms values for the facility identified by pLodgingCode.
//  It returns standard output: (code, human readable string).
//  pDateFrom is the start date. Days will be passed as ordered lists.
//  pRoomsWithDaysTable is a value table containing a list of rooms with parameters.
//  !!!Days lists must have the same lenght for each room.!!!
//  Columns:
//  RoomID   --   Room ID
//  Available
//  Price
//  MinStay - Minimum Stay: if set to 5, the room won't be sold for reservations with a number of nights less than 5
//  MinStayArrival - Minimum Stay Arrival: it's like the min stay, but it depends from the arrival day.
//  MaxStay - Maximum Stay: if set to 5, the room won't be sold for reservations with a number of nights more than 5
//  Closed   --   can be 0, 1 or 2. If 0, room is open. 
//  If 1, room is closed. If 2, room is closed to check-in (close to arrival).
//  ClosedDeparture
//  NoOta   --   can be 0 or 1. If 1, connected channels are closed. 
//  Close OTAs: when active, your connected OTAs (booking, expedia and so on) will be closed!
//  -----------------------------------------------------------------------------
//  ----!!!!All values are optional: passing a void item, nothing is updated. Only specified values are updated.!!!!!----
//  -----------------------------------------------------------------------------
//  Return: Structure:
//  - StatusID: Status ID (0 - OK, <0 - Error)
//  - Value: If Status ID <0 - Human Readable string of current error, else OK
//  -----------------------------------------------------------------------------
//
Function UpdateRoomsValues(pInteractionParameters, pLodgingCode, pRoomsWithDaysTable, pResult)
	GetActiveToken(pInteractionParameters);
	vSuccess	= True;
	vError 		= Undefined;
	vValue 		= Undefined;
	vStatusID 	= Undefined;
	
	vResource = GetSettings().ResourceAddress;
	WriteLogEvent(NStr("en='DataProcessor.WuBookSystemInventorySynchronization';ru='Обработка.СинхронизацияОстатковСвободныхНомеровССистемойWuBook';de='DataProcessor.WuBookSystemInventorySynchronization'"), EventLogLevel.Information, , Undefined,
		"Update rooms values"+Chars.LF+
		"Server host: "+TrimAll(pInteractionParameters.WSHost)+Chars.LF+
		"Server resource: "+TrimAll(vResource)+Chars.LF+
		"Token: "+TrimAll(pInteractionParameters.SessionID)+Chars.LF+
		"Lodging code: "+TrimAll(pLodgingCode)+Chars.LF+
		"Rooms with days table rows count: "+String(pRoomsWithDaysTable.Count()));
	
	vLastRoomID = "";
	
	// XML
	
	vXMLDocument 		= New XMLWriter;
	vXMLDocument.Indent = False;
	
	vXMLDocument.SetString();
	vXMLDocument.WriteXMLDeclaration();
	vXMLDocument.WriteStartElement("methodCall");
		vXMLDocument.WriteStartElement("methodName");
			vXMLDocument.WriteText("update_sparse_avail");
		vXMLDocument.WriteEndElement(); // MethodName	
		vXMLDocument.WriteStartElement("params");
			vXMLDocument.WriteStartElement("param");
				vXMLDocument.WriteStartElement("value");
					vXMLDocument.WriteStartElement("string");
						vXMLDocument.WriteText(pInteractionParameters.SessionID);
					vXMLDocument.WriteEndElement(); // String
				vXMLDocument.WriteEndElement(); // Value
			vXMLDocument.WriteEndElement(); // Param
			vXMLDocument.WriteStartElement("param");
				vXMLDocument.WriteStartElement("value");
					vXMLDocument.WriteStartElement("int");
						vXMLDocument.WriteText(pLodgingCode);                                    
					vXMLDocument.WriteEndElement(); // Int
				vXMLDocument.WriteEndElement(); // Value
			vXMLDocument.WriteEndElement(); // Param
			vXMLDocument.WriteStartElement("param");
				vXMLDocument.WriteStartElement("value");
					vXMLDocument.WriteStartElement("array");
						vXMLDocument.WriteStartElement("data");
						vIsEmptyRoomID = True;
						For Each vRow In pRoomsWithDaysTable Do
							If ValueIsFilled(vRow.RoomTypeCode) Then
								vIsEmptyRoomID = False;
								If vLastRoomID <> vRow.RoomTypeCode Then
									If vLastRoomID <> "" Then
										vXMLDocument.WriteEndElement();	// Data
										vXMLDocument.WriteEndElement();	// Array
										vXMLDocument.WriteEndElement();	// Value
										vXMLDocument.WriteEndElement();	// Member
										vXMLDocument.WriteEndElement();	// Struct
										vXMLDocument.WriteEndElement();	// Value
									EndIf;
									vXMLDocument.WriteStartElement("value");
									vXMLDocument.WriteStartElement("struct");
									vXMLDocument.WriteStartElement("member");
										vXMLDocument.WriteStartElement("name");
											vXMLDocument.WriteText("id");
										vXMLDocument.WriteEndElement();	// Name
										vXMLDocument.WriteStartElement("value");
											vXMLDocument.WriteStartElement("int");
												vXMLDocument.WriteText(vRow.RoomTypeCode);
											vXMLDocument.WriteEndElement();	// Int
										vXMLDocument.WriteEndElement();	// Value
									vXMLDocument.WriteEndElement();	// Member
									
									vXMLDocument.WriteStartElement("member");
										vXMLDocument.WriteStartElement("name");
											vXMLDocument.WriteText("days");
										vXMLDocument.WriteEndElement();	// Name
										vXMLDocument.WriteStartElement("value");
											vXMLDocument.WriteStartElement("array");
												vXMLDocument.WriteStartElement("data");
									vLastRoomID = vRow.RoomTypeCode;
								EndIf;
								vXMLDocument.WriteStartElement("value");
									vXMLDocument.WriteStartElement("struct");
										If vRow.BookingLimit <> Undefined Then
											vXMLDocument.WriteStartElement("member");
												vXMLDocument.WriteStartElement("name");
													vXMLDocument.WriteText("avail");
												vXMLDocument.WriteEndElement();	// Name
												vXMLDocument.WriteStartElement("value");
													vXMLDocument.WriteStartElement("int");
													If Not ValueIsFilled(vRow.BookingLimit) Then
														vXMLDocument.WriteText("0");
													Else
														vXMLDocument.WriteText(Format(vRow.BookingLimit, "ND=10; NFD=0; NZ=; NG="));
													EndIf;
													vXMLDocument.WriteEndElement();	// Int
												vXMLDocument.WriteEndElement();	// Value
											vXMLDocument.WriteEndElement();	// Member
										Else
											vXMLDocument.WriteStartElement("member");
												vXMLDocument.WriteStartElement("name");
													vXMLDocument.WriteText("avail");
												vXMLDocument.WriteEndElement();	// Name
												vXMLDocument.WriteStartElement("value");
													vXMLDocument.WriteStartElement("int");
														vXMLDocument.WriteText("0");
													vXMLDocument.WriteEndElement();	// Int
												vXMLDocument.WriteEndElement();	// Value
											vXMLDocument.WriteEndElement();	// Member
										EndIf;
										
											vXMLDocument.WriteStartElement("member");
												vXMLDocument.WriteStartElement("name");
													vXMLDocument.WriteText("date");
												vXMLDocument.WriteEndElement();	// Name
												vXMLDocument.WriteStartElement("value");
													vXMLDocument.WriteStartElement("string");
														vXMLDocument.WriteText(Format(vRow.Period, "DF=dd/MM/yyyy"));
													vXMLDocument.WriteEndElement();	// Int
												vXMLDocument.WriteEndElement();	// Value
											vXMLDocument.WriteEndElement();	// Member
										vXMLDocument.WriteEndElement();	// Struct
								vXMLDocument.WriteEndElement(); // Value
								EndIf;
							EndDo;
							If Not vIsEmptyRoomID Then
								vXMLDocument.WriteEndElement();	// Data
								vXMLDocument.WriteEndElement();	// Array
								vXMLDocument.WriteEndElement();	// Value
								vXMLDocument.WriteEndElement();	// Member
								vXMLDocument.WriteEndElement();	// Struct
								vXMLDocument.WriteEndElement(); // Value
							EndIf;
						vXMLDocument.WriteEndElement();	// Data
					vXMLDocument.WriteEndElement(); // Array
				vXMLDocument.WriteEndElement(); // Value
			vXMLDocument.WriteEndElement(); // Param
		vXMLDocument.WriteEndElement();	// Params
	vXMLDocument.WriteEndElement(); // MethodCall
	vXML = vXMLDocument.Close();
	
	vRequestHeaders = New Map;
	vRequestHeaders.Insert("Content-Type", "text/xml;charset=utf-8");
	vRequestHeaders.Insert("Content-Lenght", StrLen(vXML));
	
	vResponse 	= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, vRequestHeaders, "xrws", "POST", "update_sparse_avail", vXML, "text/xml;charset=utf-8");
		
	vSuccess = IsBlankString(vResponse.Error);
	
	If vSuccess Then
		// XML Read
		vReadXML = New XMLReader;
		vReadXML.SetString(vResponse.Body);
				
		vDOMBuilder = New DOMBuilder;
		vDOMDocument = vDOMBuilder.Read(vReadXML);
		vStatusIDPostion = vDOMDocument.GetElementByTagName("int");

		If vStatusIDPostion.Count() > 0 Then
			vStatusID = vStatusIDPostion[0].TextContent;
			
			vValuePostion = vDOMDocument.GetElementByTagName("string");
			If vValuePostion.Count() > 0 Then
				vValue = vValuePostion[0].TextContent;
			Else
				vSuccess 	= False;
				vError 		= NStr("en='XML is wrong';ru='Неправильное форматирование XML';de='Falsche XML-Formatierung'");
			EndIf;
		Else
			vSuccess 	= False;
			vError 		= NStr("en='XML is wrong';ru='Неправильное форматирование XML';de='Falsche XML-Formatierung'");
		EndIf;
	EndIf;	
	
	UpdateInteractionParametersSession(pInteractionParameters);
		
	pResult.Add(New Structure("RawRequest, RawResponse, Success, Error, Result, ResultStatus", vXML, vResponse.Body, vSuccess, vError, vValue, vStatusID));
	
	Return pResult; 
EndFunction // UpdateRoomsValues

// --------------------------------------------------------------------------------
Function Fetch_new_bookings(pExternalInteractionRef, pLodgingCode)
	
	GetActiveToken(pExternalInteractionRef);
	
	// XML
	
	vXMLDocument = New XMLWriter;
	vXMLDocument.SetString();
	vXMLDocument.WriteXMLDeclaration();
	vXMLDocument.WriteStartElement("methodCall");
		vXMLDocument.WriteStartElement("methodName");
		vXMLDocument.WriteText("fetch_new_bookings");
		vXMLDocument.WriteEndElement();	
		vXMLDocument.WriteStartElement("params");
		
			vXMLDocument.WriteStartElement("param");
				vXMLDocument.WriteStartElement("value");
			        vXMLDocument.WriteStartElement("string");
			        	vXMLDocument.WriteText(TrimAll(pExternalInteractionRef.SessionID));
					vXMLDocument.WriteEndElement();
				vXMLDocument.WriteEndElement();
			vXMLDocument.WriteEndElement();
			
			vXMLDocument.WriteStartElement("param");
				vXMLDocument.WriteStartElement("value");
			    	vXMLDocument.WriteStartElement("int");
			        	vXMLDocument.WriteText(pLodgingCode);                                    
					vXMLDocument.WriteEndElement();
				vXMLDocument.WriteEndElement();
			vXMLDocument.WriteEndElement();

			vXMLDocument.WriteStartElement("param");
				vXMLDocument.WriteStartElement("value");
					vXMLDocument.WriteStartElement("int");
						vXMLDocument.WriteText("0");
					vXMLDocument.WriteEndElement();
				vXMLDocument.WriteEndElement();
			vXMLDocument.WriteEndElement();
					
			vXMLDocument.WriteStartElement("param");
				vXMLDocument.WriteStartElement("value");
					vXMLDocument.WriteStartElement("int");
						vXMLDocument.WriteText("0");
					vXMLDocument.WriteEndElement();
				vXMLDocument.WriteEndElement();
			vXMLDocument.WriteEndElement();
			
		vXMLDocument.WriteEndElement();	
	vXMLDocument.WriteEndElement();
	vXML = vXMLDocument.Close();
	
	vRequestHeaders = New Map;
	vRequestHeaders.Insert("Content-Type", "text/xml;charset=utf-8");
	vRequestHeaders.Insert("Content-Lenght", StrLen(vXML));
	
	vResponse 	= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pExternalInteractionRef, vRequestHeaders, "xrws", "POST", "fetch_new_bookings", vXML, "text/xml;charset=utf-8",,,,,,,pExternalInteractionRef.WSHOST);
	
	// XML Read
	vReadXML = New XMLReader;
	vReadXML.SetString(vResponse.Body);

	vDOMBuilder = New DOMBuilder;
	vDOMDocument = vDOMBuilder.Read(vReadXML);
		
	Return vDOMDocument; 
EndFunction

// --------------------------------------------------------------------------------
Function Mark_bookings(pExternalInteractionRef, pLodgingCode, pReservationsAray)
	
	GetActiveToken(pExternalInteractionRef);
	
	// XML
	
	vXMLDocument = New XMLWriter;
	vXMLDocument.SetString();
	vXMLDocument.WriteXMLDeclaration();
	vXMLDocument.WriteStartElement("methodCall");
		vXMLDocument.WriteStartElement("methodName");
		vXMLDocument.WriteText("mark_bookings");
		vXMLDocument.WriteEndElement();	
		vXMLDocument.WriteStartElement("params");
		
			vXMLDocument.WriteStartElement("param");
				vXMLDocument.WriteStartElement("value");
			        vXMLDocument.WriteStartElement("string");
			        	vXMLDocument.WriteText(TrimAll(pExternalInteractionRef.SessionID));
					vXMLDocument.WriteEndElement();
				vXMLDocument.WriteEndElement();
			vXMLDocument.WriteEndElement();
			
			vXMLDocument.WriteStartElement("param");
				vXMLDocument.WriteStartElement("value");
			    	vXMLDocument.WriteStartElement("int");
			        	vXMLDocument.WriteText(pLodgingCode);                                    
					vXMLDocument.WriteEndElement();
				vXMLDocument.WriteEndElement();
			vXMLDocument.WriteEndElement();

			vXMLDocument.WriteStartElement("param");
				vXMLDocument.WriteStartElement("value");
					vXMLDocument.WriteStartElement("array");
						vXMLDocument.WriteStartElement("data");
						For Each vReservation In pReservationsAray Do 
							vXMLDocument.WriteStartElement("value");
								vXMLDocument.WriteStartElement("string");
									vXMLDocument.WriteText(String(vReservation));
								vXMLDocument.WriteEndElement();
							vXMLDocument.WriteEndElement();
						EndDo;
						vXMLDocument.WriteEndElement();
					vXMLDocument.WriteEndElement();
				vXMLDocument.WriteEndElement();
			vXMLDocument.WriteEndElement();
								
		vXMLDocument.WriteEndElement();	
	vXMLDocument.WriteEndElement();
	vXML = vXMLDocument.Close();
	
	vRequestHeaders = New Map;
	vRequestHeaders.Insert("Content-Type", "text/xml;charset=utf-8");
	vRequestHeaders.Insert("Content-Lenght", StrLen(vXML));
	
	vResponse 	= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pExternalInteractionRef, vRequestHeaders, "xrws", "POST", "mark_bookings", vXML, "text/xml;charset=utf-8");
	
	// XML Read
	vReadXML = New XMLReader;
	vReadXML.SetString(vResponse.Body);
	
	vDOMBuilder = New DOMBuilder;
	vDOMDocument = vDOMBuilder.Read(vReadXML);
	
	Return vDOMDocument; 
EndFunction

#EndRegion 
 