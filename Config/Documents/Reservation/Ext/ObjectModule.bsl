
#Region Variables

Var EffectiveNumberOfRooms;
Var EffectiveNumberOfBeds; 
Var EffectiveNumberOfAddBeds;
Var EffectiveNumberOfPersons;
Var RoomsWriteOff;
Var BedsWriteOff;
Var AdditionalBedsWriteOff;
Var PersonsWriteOff;
Var RoomsWithReservedStatus; 
Var HavePermissionToDoBookingWithoutRooms;
Var StatusHasChanged;
Var ChargesToRepostStorno;
Var WriteOffAllotmentLateCheckOutAndEarlyCheckInFromFreeSaleVacantRooms;

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
Procedure pmPostToInventoryRegisters(pPeriods, pPeriod, pPostForecastSales = True, pCancel = False) Export
	// To the expected preliminary groups
	PostToExpectedGuestGroups(pPeriod, pCancel);
	If pCancel Then
		Return;
	EndIf;
	// If reservation is active
	If ReservationStatus.IsActive Then
		// Calculate the effective number of rooms to write off
		CalculateEffectiveNumberOfRooms(pPeriod);
		// Check if rooms list is filled
		If RoomQuantity > 1 Then
			// Process each room in rooms reserved table
			If Rooms.Count() > 0 Then
				For Each vRoomsRow In Rooms Do
					If vRoomsRow.IsUsed Then
						Continue;
					EndIf;
					If Not ValueIsFilled(vRoomsRow.Room) Then
						Continue;
					EndIf;
					// Check room stop sale flag
					If Not AdditionalProperties.Property("InfoBaseUpdateMode") And Not AdditionalProperties.Property("CloseOfDayMode") Then
						If vRoomsRow.Room.StopSale Then
							vRemarks = "";
							If cmIsRoomStopSalePeriod(vRoomsRow.Room, pPeriod.CheckInDate, pPeriod.CheckOutDate, vRemarks) Then
								If Not cmCheckUserPermissions("HavePermissionToIgnoreStopSaleLimitations") Then
									pCancel = Not Posted; 
									vMessage = "ru='" + "Выбранный номер снят с продажи!" + Chars.LF + ?(IsBlankString(vRemarks), "", vRemarks + Chars.LF) + "';
									           |de='" + "Room choosen is out of sale!" + Chars.LF + ?(IsBlankString(vRemarks), "", vRemarks + Chars.LF) + "';
									           |en='" + "Room choosen is out of sale!" + Chars.LF + ?(IsBlankString(vRemarks), "", vRemarks + Chars.LF) + "';";
									WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
									tcCommonFunctionOnClientServer.UserMessage(NStr(vMessage));
									Raise String(Ref) + " - " + NStr(vMessage);
								EndIf;
							EndIf;
						EndIf;
					EndIf;
					// To the room inventory
					PostToRoomInventory(pCancel, pPeriods, pPeriod, vRoomsRow);
					// Check rooms availability
					vMsgTextRu = ""; vMsgTextEn = ""; vMsgTextDe = "";
					If Not AdditionalProperties.Property("InfoBaseUpdateMode") And Not AdditionalProperties.Property("CloseOfDayMode") Then
						If Max(CurrentSessionDate(), pPeriod.CheckInDate) < pPeriod.CheckOutDate Then
							If Not cmCheckRoomAvailability(Hotel, RoomQuota, pPeriod.RoomType, vRoomsRow.Room, Ref, True, False,
														   PersonsWriteOff, RoomsWriteOff, BedsWriteOff, AdditionalBedsWriteOff, 
														   NumberOfBedsPerRoom, NumberOfPersonsPerRoom, Max(CurrentSessionDate(), pPeriod.CheckInDate), pPeriod.CheckOutDate, 
														   vMsgTextRu, vMsgTextEn, vMsgTextDe) Then
								pCancel = True; 
								vMessage = "ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';";
								WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
								tcCommonFunctionOnClientServer.UserMessage(NStr(vMessage));
								Raise String(Ref) + " - " + NStr(vMessage);
							EndIf;
						EndIf;
					EndIf;
					// To the room quota sales
					If ValueIsFilled(RoomQuota) Then
						PostToRoomQuotaSales(pCancel, pPeriod, vRoomsRow);
					EndIf;
					// To the forecast sales
					If pPostForecastSales And pPeriod.CheckInDate = CheckInDate And pPeriod.RoomType = RoomType Then
						PostToForecastSales(pCancel, vRoomsRow);
					EndIf;
				EndDo;
			Else
				// Check rights to book without room
				vMsgTextRu = ""; vMsgTextEn = ""; vMsgTextDe = "";
				If Not AdditionalProperties.Property("InfoBaseUpdateMode") And Not AdditionalProperties.Property("CloseOfDayMode") Then
					If Not HavePermissionToDoBookingWithoutRooms And Not ValueIsFilled(Room) Then
						pCancel = True;
						vMsgTextRu = "Нет прав на бронирование по категориям номеров без указания номеров комнат!";
						vMsgTextEn = "You do not have right to book by room types without room numbers!";
						vMsgTextDe = "Нет прав на бронирование по категориям номеров без указания номеров комнат!";
						vMessage = "ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';";
						WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
						tcCommonFunctionOnClientServer.UserMessage(NStr(vMessage));
						Raise String(Ref) + " - " + NStr(vMessage);
					EndIf;
				EndIf;
			EndIf;
			// To the room inventory
			PostToRoomInventory(pCancel, pPeriods, pPeriod);
			// To the room quota sales
			If ValueIsFilled(RoomQuota) Then
				PostToRoomQuotaSales(pCancel, pPeriod);
			EndIf;
			// To the forecast sales
			If pPostForecastSales And pPeriod.CheckInDate = CheckInDate And pPeriod.RoomType = RoomType Then
				PostToForecastSales(pCancel);
			EndIf;
		Else
			// Check rights to book without room
			vMsgTextRu = ""; vMsgTextEn = ""; vMsgTextDe = "";
			If Not AdditionalProperties.Property("InfoBaseUpdateMode") And Not AdditionalProperties.Property("CloseOfDayMode") Then
				If Not HavePermissionToDoBookingWithoutRooms And Not ValueIsFilled(Room) Then
					pCancel = True;
					vMsgTextRu = "Нет прав на бронирование по категориям номеров без указания номеров комнат!";
					vMsgTextEn = "You do not have right to book by room types without room numbers!";
					vMsgTextDe = "Нет прав на бронирование по категориям номеров без указания номеров комнат!";
					vMessage = "ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';";
					WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
					tcCommonFunctionOnClientServer.UserMessage(NStr(vMessage));
					Raise String(Ref) + " - " + NStr(vMessage);
				EndIf;
			EndIf;
			// Calculate the effective number of rooms to write off
			vPrevEffectiveNumberOfRoomsRow = Undefined;
			vNextEffectiveNumberOfRoomsRow = Undefined;
			vEffectiveNumberOfRooms = cmCalculateEffectiveNumberOfRoomsForReservation(pPeriod, EffectiveNumberOfRooms, EffectiveNumberOfBeds, EffectiveNumberOfAddBeds, EffectiveNumberOfPersons);
			i = 0;
			While i < vEffectiveNumberOfRooms.Count() Do
				// To the room inventory
				vEffectiveNumberOfRoomsRow = vEffectiveNumberOfRooms.Get(i);
				If i > 0 Then
					vPrevEffectiveNumberOfRoomsRow = vEffectiveNumberOfRooms.Get(i - 1);
				EndIf;
				If i < (vEffectiveNumberOfRooms.Count() - 1) Then
					vNextEffectiveNumberOfRoomsRow = vEffectiveNumberOfRooms.Get(i + 1);
				Else
					vNextEffectiveNumberOfRoomsRow = Undefined;
				EndIf;
				PostToRoomInventoryDetailed(pCancel, pPeriods, pPeriod, vEffectiveNumberOfRoomsRow, vPrevEffectiveNumberOfRoomsRow, vNextEffectiveNumberOfRoomsRow);
				// To the room quota sales
				If ValueIsFilled(pPeriod.RoomQuota) Then
					PostToRoomQuotaSalesDetailed(pCancel, pPeriod, vEffectiveNumberOfRoomsRow);
				EndIf;
				// Next row
				i = i + 1;
			EndDo;
			// To the forecast sales
			If pPostForecastSales And pPeriod.CheckInDate = CheckInDate And pPeriod.RoomType = RoomType Then
				PostToForecastSales(pCancel);
			EndIf;
		EndIf;
		// Write register records
		RegisterRecords.RoomInventory.Write();
		RegisterRecords.RoomQuotaSales.Write();
	Else
		If pPostForecastSales And pPeriod.CheckInDate = CheckInDate And pPeriod.RoomType = RoomType Then
			PersonsWriteOff = NumberOfPersons;
			If Not DoCharging And ReservationStatus.IsPreliminary And Not ReservationStatus.DoNotChargeForecastServices Then
				PostToForecastSales(pCancel);
			Else
				pmClearSalesForecastRegisterRecords();
			EndIf;
		EndIf;
	EndIf;
	If RegisterRecords.ExpectedGuestGroups.Count() > 0 Then
		RegisterRecords.ExpectedGuestGroups.Write();
	EndIf;
	RegisterRecords.ExpectedGuestGroups.Write = False;
EndProcedure // pmPostToInventoryRegisters

// -----------------------------------------------------------------------------
// 
// Returns:
//  Date - Check In Date 
//
Function pmGetCheckInDate() Export
	vCheckInDate = CheckInDate;
	If ParentDoc = Ref Then
		ParentDoc = Undefined;
	EndIf;
	vList = New ValueList();
	vParentDoc = ParentDoc;
	While ValueIsFilled(vParentDoc) Do
		If vList.FindByValue(vParentDoc) = Undefined Then
			vList.Add(vParentDoc);
		Else
			Break;
		EndIf;
		If TypeOf(vParentDoc) = Type("DocumentRef.Reservation") And ValueIsFilled(vParentDoc.ReservationStatus) Then
			If Not vParentDoc.ReservationStatus.IsArrivalSchedule Then
				vCheckInDate = Min(vCheckInDate, vParentDoc.CheckInDate);
				vParentDoc = vParentDoc.ParentDoc;
			Else
				Break;
			EndIf;
		Else
			Break;
		EndIf;
	EndDo;
	Return vCheckInDate;
EndFunction //  pmGetCheckInDate

// -----------------------------------------------------------------------------
// 
// Returns:
//  DocumentRef.Reservation - Ref 
//
Function pmGetFirstReservationInChain() Export
	vList = New ValueList();
	vFirstResInChain = Ref;
	While ValueIsFilled(vFirstResInChain.ParentDoc) Do
		If vList.FindByValue(vFirstResInChain.ParentDoc) = Undefined Then
			vList.Add(vFirstResInChain.ParentDoc);
		Else
			Break;
		EndIf;
		vFirstResInChain = vFirstResInChain.ParentDoc;
	EndDo;
	Return vFirstResInChain;
EndFunction //  pmGetFirstReservationInChain

// -----------------------------------------------------------------------------
//
// Parameters:
//  pReservation - DocumentRef.Reservation - Ref 
// 
// Returns:
//  DocumentRef.Reservation - Ref 
//
Function pmGetNextReservationInChain(pReservation = Undefined) Export
	vNextDoc = Undefined;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reservation.Ref
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	Reservation.Posted
	|	AND Reservation.ParentDoc = &qParentDoc
	|	AND Reservation.CheckInDate > &qCheckInDate
	|	AND (Reservation.ReservationStatus.IsActive
	|			OR Reservation.ReservationStatus.IsCheckIn
	|	        OR Reservation.ReservationStatus.IsPreliminary)";
	If ValueIsFilled(pReservation) Then
		vQry.SetParameter("qParentDoc", pReservation);
		vQry.SetParameter("qCheckInDate", pReservation.CheckInDate);
	Else
		vQry.SetParameter("qParentDoc", Ref);
		vQry.SetParameter("qCheckInDate", CheckInDate);
	EndIf;
	vNextDocs = vQry.Execute().Unload();
	If vNextDocs.Count() > 0 Then
		vNextDoc = vNextDocs.Get(0).Ref;
	EndIf;
	Return vNextDoc;
EndFunction //  pmGetNextReservationInChain

// -----------------------------------------------------------------------------
// 
// Returns:
//  DocumentRef.Reservation - Ref
//
Function pmGetLastReservationInChain() Export
	vLastResInChain = Ref;
	vNextResInChain = pmGetNextReservationInChain();
	While ValueIsFilled(vNextResInChain) Do
		vLastResInChain = vNextResInChain;
		vNextResInChain = pmGetNextReservationInChain(vNextResInChain);
	EndDo;
	If ValueIsFilled(vLastResInChain) And 
	   (Not vLastResInChain.Posted Or Not ValueIsFilled(vLastResInChain.ReservationStatus) Or
		(ValueIsFilled(vLastResInChain.ReservationStatus) And Not vLastResInChain.ReservationStatus.IsActive And Not vLastResInChain.ReservationStatus.IsCheckIn And Not vLastResInChain.ReservationStatus.IsPreliminary)) Then
		// Current reservation is not active and there are no active reservations after it
		// So, try to check previous one
		vParentRes = vLastResInChain.ParentDoc;
		While ValueIsFilled(vParentRes) And TypeOf(vParentRes) = Type("DocumentRef.Reservation") And 
		      (Not vParentRes.Posted Or Not ValueIsFilled(vParentRes.ReservationStatus) Or
		       (ValueIsFilled(vParentRes.ReservationStatus) And Not vParentRes.ReservationStatus.IsActive And Not vParentRes.ReservationStatus.IsCheckIn And Not vParentRes.ReservationStatus.IsPreliminary)) Do
			vParentRes = vParentRes.ParentDoc;
		EndDo;
		If ValueIsFilled(vParentRes) And TypeOf(vParentRes) = Type("DocumentRef.Reservation") And 
		   vParentRes.Posted And ValueIsFilled(vParentRes.ReservationStatus) And (vParentRes.ReservationStatus.IsActive Or vParentRes.ReservationStatus.IsCheckIn Or vParentRes.ReservationStatus.IsPreliminary) Then
			vLastResInChain = vParentRes;
		EndIf;
	EndIf;
	Return vLastResInChain;
EndFunction //  pmGetLastReservationInChain

// -----------------------------------------------------------------------------
//
// Parameters:
//  pPeriod	 - Date	 - Date
// 
// Returns:
//  ValueTable - Reservation history state
//
Function pmGetReservationHistoryState(pPeriod) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	*
	|FROM
	|	InformationRegister.ReservationChangeHistory.SliceLast(&qPeriod, Reservation = &qReservation) AS AccommodationChangeHistorySliceLast";
	vQry.SetParameter("qPeriod", pPeriod);
	vQry.SetParameter("qReservation", Ref);
	vResStates = vQry.Execute().Unload();
	Return vResStates;
EndFunction //  pmGetReservationHistoryState

// -----------------------------------------------------------------------------
Procedure pmUpdateHotelProductData() Export
	If ValueIsFilled(HotelProduct) And Not HotelProduct.IsFolder Then
		// We'll try to update hotel product sum and period here
		vHPSum = 0;
		vHPCurrency = Undefined;
		If ValueIsFilled(HotelProduct) Then
			vHPCurrency = HotelProduct.Currency;
		EndIf;
		// We have to group all amounts by currencies
		vSrv = Services.Unload(, "Service, Sum, DiscountSum, FolioCurrency");
		i = 0;
		While i < vSrv.Count() Do
			vSrvRow = vSrv.Get(i);
			If Not ValueIsFilled(vSrvRow.Service) Then
				vSrv.Delete(i);
				Continue;
			Else
				If Not vSrvRow.Service.IsHotelProductService Then
					vSrv.Delete(i);
					Continue;
				EndIf;
			EndIf;
			i = i + 1;
		EndDo;
		vSrv.GroupBy("FolioCurrency", "Sum, DiscountSum");
		For Each vTotal In vSrv Do
			If vHPCurrency = vTotal.FolioCurrency Then
				vHPSum = vHPSum + vTotal.Sum - vTotal.DiscountSum;
			Else
				vHPCurrency = Undefined;
			EndIf;
		EndDo;
		// Get hotel product payment date and payment method
		vPaymentDate = Undefined;
		vPaymentMethod = Undefined;
		If Not ValueIsFilled(HotelProduct.PaymentDate) Then
			vPaymentDate = HotelProduct.GetObject().pmGetHotelProductPaymentDate(vPaymentMethod);
		EndIf;
		// Update hotel product parameters
		vUpdateSum = False;
		vUpdatePeriod = False;
		vUpdatePaymentDate = False;
		vUpdateClient = False;
		If ValueIsFilled(ReservationStatus) And ReservationStatus.IsActive And RoomQuantity = 1 Then
			If ValueIsFilled(vHPCurrency) And vHPSum > 0 And HotelProduct.Sum <> vHPSum And 
			   Not HotelProduct.FixProductCost Then
				vUpdateSum = True;
			EndIf;
			If (CheckInDate <> HotelProduct.CheckInDate Or CheckOutDate <> HotelProduct.CheckOutDate Or RoomType <> HotelProduct.RoomType) And 
			   Not HotelProduct.FixProductPeriod And Not HotelProduct.FixPlannedPeriod Then
				vUpdatePeriod = True;
			EndIf;
		EndIf;
		If Not ValueIsFilled(HotelProduct.PaymentDate) And ValueIsFilled(vPaymentDate) Then
			vUpdatePaymentDate = True;
		EndIf;
		vClient = Undefined;
		If Not HotelProduct.FixedClient Then
			vClient = HotelProduct.GetObject().pmGetHotelProductClient();
			If ValueIsFilled(vClient) And vClient <> HotelProduct.Client Then
				vUpdateClient = True;
			EndIf;
		EndIf;
		If vUpdateSum Or vUpdatePeriod Or vUpdatePaymentDate Or vUpdateClient Then
			Try
				vHPObj = HotelProduct.GetObject();
				vHPObj.Read();
				If vUpdateSum Then
					vHPObj.Sum = vHPSum;
				EndIf;
				If vUpdatePeriod Then
					vHPObj.CheckInDate = CheckInDate;
					vHPObj.Duration = Duration;
					vHPObj.CheckOutDate = CheckOutDate;
					vHPObj.RoomType = RoomType;
				EndIf;
				If vUpdatePaymentDate Then
					vHPObj.PaymentDate = vPaymentDate;
					If ValueIsFilled(vPaymentMethod) Then
						vHPObj.PaymentMethod = vPaymentMethod;
					EndIf;
				EndIf;
				If vUpdateClient Then
					Client = vClient;
				EndIf;
				vHPObj.Write();
			Except
			EndTry;
		EndIf;
	EndIf;
EndProcedure //  pmUpdateHotelProductData

// -----------------------------------------------------------------------------
//
// Parameters:
//  pAddConnected	 - Boolean	 - Connected
// 
// Returns:
//  ValueTable - Table of accommodation periods
//
Function pmGetAccommodationPeriods(pAddConnected = False) Export
	// Create value table of accommodation periods
	vPeriods = New ValueTable();
	vPeriods.Columns.Add("Ref", cmGetDocumentTypeDescription("Reservation"));
	vPeriods.Columns.Add("Hotel", cmGetCatalogTypeDescription("Hotels"));
	vPeriods.Columns.Add("RoomQuota", cmGetCatalogTypeDescription("RoomQuotas"));
	vPeriods.Columns.Add("CheckInDate", cmGetDateTimeTypeDescription());
	vPeriods.Columns.Add("CheckOutDate", cmGetDateTimeTypeDescription());
	vPeriods.Columns.Add("RoomType", cmGetCatalogTypeDescription("RoomTypes"));
	vPeriods.Columns.Add("Room", cmGetCatalogTypeDescription("Rooms"));
	vPeriods.Columns.Add("AccommodationType", cmGetCatalogTypeDescription("AccommodationTypes"));
	vPeriods.Columns.Add("AccommodationTemplate", cmGetCatalogTypeDescription("AccommodationTemplates"));
	vPeriods.Columns.Add("RoomRate", cmGetCatalogTypeDescription("RoomRates"));
	vPeriods.Columns.Add("ServicePackage", cmGetCatalogTypeDescription("ServicePackages"));
	vPeriods.Columns.Add("NumberOfBedsPerRoom", cmGetNumberTypeDescription(6, 0));
	vPeriods.Columns.Add("NumberOfPersonsPerRoom", cmGetNumberTypeDescription(6, 0));
	vPeriods.Columns.Add("NumberOfPersons", cmGetNumberTypeDescription(6, 0));
	vPeriods.Columns.Add("NumberOfRooms", cmGetNumberTypeDescription(6, 0));
	vPeriods.Columns.Add("NumberOfBeds", cmGetNumberTypeDescription(6, 0));
	vPeriods.Columns.Add("NumberOfAdditionalBeds", cmGetNumberTypeDescription(6, 0));
	vPeriods.Columns.Add("IsRoomChange", cmGetBooleanTypeDescription());
	vPeriods.Columns.Add("IsCheckOut", cmGetBooleanTypeDescription());
	vPeriods.Columns.Add("IsCheckIn", cmGetBooleanTypeDescription());
	vPeriods.Columns.Add("DoNotChangeAvailability", cmGetBooleanTypeDescription());
	vPeriods.Columns.Add("AccountingDate", cmGetDateTimeTypeDescription());
	vPeriods.Columns.Add("IntersectedDocs");
	vPeriods.Columns.Add("NoRoomsInRoomQuota", cmGetBooleanTypeDescription());
	// Unload and sort room rates rows
	vRoomRates = RoomRates.Unload();
	vRoomRates.Sort("AccountingDate, ChangeTime");
	// Fill value table of accommodation periods
	vPeriodsRow = Undefined;
	If vRoomRates.Count() = 0 Then
		vPeriodsRow = vPeriods.Add();
		FillPeriodsRowWithDefaultValues(vPeriodsRow);
	Else
		vIsInBookedOutPeriod = False;
		For Each vRRRow In vRoomRates Do
			If Not ValueIsFilled(vRRRow.AccountingDate) Or 
				BegOfDay(CheckInDate) > BegOfDay(vRRRow.AccountingDate) Or
				BegOfDay(CheckOutDate) <= BegOfDay(vRRRow.AccountingDate) Then
				Continue;
			EndIf;
			If vRRRow.IsBookedOut Then
				If Not vIsInBookedOutPeriod Then
					vIsInBookedOutPeriod = True;
					If vPeriodsRow = Undefined Then
						If BegOfDay(vRRRow.AccountingDate) > BegOfDay(CheckInDate) Then
							vPeriodsRow = vPeriods.Add();
							FillPeriodsRowWithDefaultValues(vPeriodsRow);
							If ValueIsFilled(vRRRow.ChangeTime) Then
								vPeriodsRow.CheckOutDate = cm0SecondShift(BegOfDay(vRRRow.AccountingDate) + (vRRRow.ChangeTime - BegOfDay(vRRRow.ChangeTime)));
							Else
								vPeriodsRow.CheckOutDate = cmMovePeriodToToReferenceHour(vRRRow.AccountingDate, vPeriodsRow.RoomRate);
							EndIf;
							vPeriodsRow.IsCheckOut = True;
							// Add next row
							vPeriodsRow = vPeriods.Add();
							FillPeriodsRowWithDefaultValues(vPeriodsRow);
							If ValueIsFilled(vRRRow.ChangeTime) Then
								vPeriodsRow.CheckInDate = cm1SecondShift(BegOfDay(vRRRow.AccountingDate) + 24*3600 + (vRRRow.ChangeTime - BegOfDay(vRRRow.ChangeTime)));
							Else
								vPeriodsRow.CheckInDate = cmMovePeriodFromToReferenceHour(vRRRow.AccountingDate + 24*3600, vPeriodsRow.RoomRate);
							EndIf;
							vPeriodsRow.IsCheckIn = True;
						Else
							// Add first row
							vPeriodsRow = vPeriods.Add();
							FillPeriodsRowWithDefaultValues(vPeriodsRow);
							If ValueIsFilled(vRRRow.ChangeTime) Then
								vPeriodsRow.CheckInDate = cm1SecondShift(BegOfDay(vRRRow.AccountingDate) + 24*3600 + (vRRRow.ChangeTime - BegOfDay(vRRRow.ChangeTime)));
							Else
								vPeriodsRow.CheckInDate = cmMovePeriodFromToReferenceHour(vRRRow.AccountingDate + 24*3600, vPeriodsRow.RoomRate);
							EndIf;
							vPeriodsRow.IsCheckIn = True;
						EndIf;
					ElsIf BegOfDay(vRRRow.AccountingDate) > BegOfDay(vPeriodsRow.CheckInDate) Then
						vPeriodCheckOutDate = Undefined;
						If ValueIsFilled(vRRRow.ChangeTime) Then
							vPeriodCheckOutDate = cm0SecondShift(BegOfDay(vRRRow.AccountingDate) + (vRRRow.ChangeTime - BegOfDay(vRRRow.ChangeTime)));
						Else
							vPeriodCheckOutDate = cmMovePeriodToToReferenceHour(vRRRow.AccountingDate, vPeriodsRow.RoomRate);
						EndIf;
						If vPeriodCheckOutDate < CheckOutDate Then
							vPeriodsRow.CheckOutDate = vPeriodCheckOutDate;
						Else
							vPeriodsRow.CheckOutDate = CheckOutDate;
						EndIf;
						vPeriodsRow.IsCheckOut = True;
						// Add next row
						vPeriodsRow = vPeriods.Add();
						FillPeriodsRowWithDefaultValues(vPeriodsRow);
						If ValueIsFilled(vRRRow.ChangeTime) Then
							vPeriodsRow.CheckInDate = cm1SecondShift(BegOfDay(vRRRow.AccountingDate) + 24*3600 + (vRRRow.ChangeTime - BegOfDay(vRRRow.ChangeTime)));
						Else
							vPeriodsRow.CheckInDate = cmMovePeriodFromToReferenceHour(vRRRow.AccountingDate + 24*3600, vPeriodsRow.RoomRate);
						EndIf;
						vPeriodsRow.IsCheckIn = True;
					EndIf;
				Else
					// Update check-in date
					If vPeriodsRow <> Undefined Then
						If ValueIsFilled(vRRRow.ChangeTime) Then
							vPeriodsRow.CheckInDate = cm1SecondShift(BegOfDay(vRRRow.AccountingDate) + 24*3600 + (vRRRow.ChangeTime - BegOfDay(vRRRow.ChangeTime)));
						Else
							vPeriodsRow.CheckInDate = cmMovePeriodFromToReferenceHour(vRRRow.AccountingDate + 24*3600, vPeriodsRow.RoomRate);
						EndIf;
					EndIf;
				EndIf;
			Else
				vIsInBookedOutPeriod = False;
				If ValueIsFilled(vRRRow.RoomType) Or 
				   ValueIsFilled(vRRRow.Room) Or 
				   ValueIsFilled(vRRRow.AccommodationType) Or
				   vRRRow.DoNotChangeAvailability Then 
					If vPeriodsRow = Undefined Then
						vPeriodsRow = vPeriods.Add();
						FillPeriodsRowWithDefaultValues(vPeriodsRow);
						If BegOfDay(vRRRow.AccountingDate) > BegOfDay(CheckInDate) Then
							If ValueIsFilled(vRRRow.ChangeTime) Then
								vPeriodsRow.CheckOutDate = cm0SecondShift(BegOfDay(vRRRow.AccountingDate) + (vRRRow.ChangeTime - BegOfDay(vRRRow.ChangeTime)));
							Else
								vPeriodsRow.CheckOutDate = cmMovePeriodToToReferenceHour(vRRRow.AccountingDate, ?(ValueIsFilled(vRRRow.RoomRate), vRRRow.RoomRate, RoomRate));
							EndIf;
							// Add new row
							vPeriodsRow = vPeriods.Add();
							FillPeriodsRowWithDefaultValues(vPeriodsRow);
							If ValueIsFilled(vRRRow.ChangeTime) Then
								vPeriodsRow.CheckInDate = cm1SecondShift(BegOfDay(vRRRow.AccountingDate) + (vRRRow.ChangeTime - BegOfDay(vRRRow.ChangeTime)));
							Else
								vPeriodsRow.CheckInDate = cmMovePeriodFromToReferenceHour(vRRRow.AccountingDate, ?(ValueIsFilled(vRRRow.RoomRate), vRRRow.RoomRate, RoomRate));
							EndIf;
							vPeriodsRow.IsRoomChange = True;
						EndIf;
						If cmMovePeriodToToReferenceHour((vRRRow.AccountingDate + 24*3600), ?(ValueIsFilled(vRRRow.RoomRate), vRRRow.RoomRate, RoomRate)) < CheckOutDate Then
							If ValueIsFilled(vRRRow.ChangeTime) Then
								vPeriodsRow.CheckOutDate = cm0SecondShift(BegOfDay(vRRRow.AccountingDate + 24*3600) + (vRRRow.ChangeTime - BegOfDay(vRRRow.ChangeTime)));
							Else
								vPeriodsRow.CheckOutDate = cmMovePeriodToToReferenceHour((vRRRow.AccountingDate + 24*3600), ?(ValueIsFilled(vRRRow.RoomRate), vRRRow.RoomRate, RoomRate));
							EndIf;
						EndIf;
						UpdatePeriodsRow(vPeriods, vPeriodsRow, vRRRow);
					ElsIf ValueIsFilled(vRRRow.RoomType) And vRRRow.RoomType <> vPeriodsRow.RoomType Or 
						ValueIsFilled(vRRRow.Room) And vRRRow.Room <> vPeriodsRow.Room Or 
						ValueIsFilled(vRRRow.AccommodationType) And vRRRow.AccommodationType <> vPeriodsRow.AccommodationType Or
						vRRRow.DoNotChangeAvailability <> vPeriodsRow.DoNotChangeAvailability Then
						vPeriodCheckOutDate = Undefined;
						If ValueIsFilled(vRRRow.ChangeTime) Then
							vPeriodCheckOutDate = cm0SecondShift(BegOfDay(vRRRow.AccountingDate) + (vRRRow.ChangeTime - BegOfDay(vRRRow.ChangeTime)));
						Else
							vPeriodCheckOutDate = cmMovePeriodToToReferenceHour(vRRRow.AccountingDate, vPeriodsRow.RoomRate);
						EndIf;
						If vPeriodCheckOutDate < CheckOutDate Then
							vPeriodsRow.CheckOutDate = vPeriodCheckOutDate;
							// Add new row
							vPeriodsRow = vPeriods.Add();
							FillPeriodsRowWithDefaultValues(vPeriodsRow);
							If ValueIsFilled(vRRRow.ChangeTime) Then
								vPeriodsRow.CheckInDate = cm1SecondShift(BegOfDay(vRRRow.AccountingDate) + (vRRRow.ChangeTime - BegOfDay(vRRRow.ChangeTime)));
							Else
								vPeriodsRow.CheckInDate = cmMovePeriodFromToReferenceHour(vRRRow.AccountingDate, ?(ValueIsFilled(vRRRow.RoomRate), vRRRow.RoomRate, RoomRate));
							EndIf;
							vPeriodsRow.IsRoomChange = True;
							UpdatePeriodsRow(vPeriods, vPeriodsRow, vRRRow);
						Else
							vPeriodsRow.CheckOutDate = CheckOutDate;
						EndIf;
					Else
						vPeriodCheckOutDate = Undefined;
						If ValueIsFilled(vRRRow.ChangeTime) Then
							vPeriodCheckOutDate = cm0SecondShift(BegOfDay(vRRRow.AccountingDate + 24*3600) + (vRRRow.ChangeTime - BegOfDay(vRRRow.ChangeTime)));
						Else
							vPeriodCheckOutDate = cmMovePeriodToToReferenceHour((vRRRow.AccountingDate + 24*3600), vPeriodsRow.RoomRate);
						EndIf;
						If vPeriodCheckOutDate < CheckOutDate Then
							vPeriodsRow.CheckOutDate = vPeriodCheckOutDate;
						Else
							vPeriodsRow.CheckOutDate = CheckOutDate;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
		If vPeriods.Count() = 0 Then
			vPeriodsRow = vPeriods.Add();
			FillPeriodsRowWithDefaultValues(vPeriodsRow);
		Else
			vLastPeriodsRow = vPeriods.Get(vPeriods.Count() - 1);
			If vLastPeriodsRow.CheckOutDate < CheckOutDate Then
				vLastPeriodsRow.CheckOutDate = CheckOutDate;
			EndIf;
		EndIf;
	EndIf;
	// Check resulting periods
	i = 0; 
	While i < vPeriods.Count() Do
		vPeriodsRow = vPeriods.Get(i);
		If vPeriodsRow.CheckInDate >= vPeriodsRow.CheckOutDate Then
			vPeriods.Delete(i);
		Else
			i = i + 1;
		EndIf;
	EndDo;
	vNewPeriods = vPeriods.Copy();
	If pAddConnected Then
		For Each vPeriod In vPeriods Do
			If ValueIsFilled(vPeriod.Room) Then
				If vPeriod.Room.ConnectedRooms.Count() > 0 Then
					For Each vConnectedRoomsRow In vPeriod.Room.ConnectedRooms Do
						vPeriodsRow = vNewPeriods.Add();
						vPeriodsRow.Ref = vPeriod.Ref;
						vPeriodsRow.Hotel = vPeriod.Hotel;
						vPeriodsRow.RoomQuota = vPeriod.RoomQuota;
						vPeriodsRow.CheckInDate = vPeriod.CheckInDate;
						vPeriodsRow.CheckOutDate = vPeriod.CheckOutDate;
						vRoomAttrs = vConnectedRoomsRow.Room.GetObject().pmGetRoomAttributes(cm1SecondShift(vPeriod.CheckInDate));
						vPeriodsRow.RoomType = vRoomAttrs[0].RoomType;
						vPeriodsRow.Room = vConnectedRoomsRow.Room;
						vPeriodsRow.AccommodationType = vPeriod.AccommodationType;
						vPeriodsRow.AccommodationTemplate = vPeriod.AccommodationTemplate;
						vPeriodsRow.RoomRate = vPeriod.RoomRate;
						vPeriodsRow.NumberOfBedsPerRoom = vRoomAttrs[0].NumberOfBedsPerRoom;
						vPeriodsRow.NumberOfPersonsPerRoom = vRoomAttrs[0].NumberOfPersonsPerRoom;
						vPeriodsRow.NumberOfPersons = 0;
						vPeriodsRow.NumberOfRooms = vPeriod.NumberOfRooms;
						vPeriodsRow.NumberOfBeds = vPeriod.NumberOfRooms * vRoomAttrs[0].NumberOfBedsPerRoom;
						vPeriodsRow.NumberOfAdditionalBeds = 0;
						vPeriodsRow.IsRoomChange = vPeriod.IsRoomChange;
						vPeriodsRow.IsCheckOut = vPeriod.IsCheckOut;
						vPeriodsRow.IsCheckIn = vPeriod.IsCheckIn;
						vPeriodsRow.DoNotChangeAvailability = vPeriod.DoNotChangeAvailability;
						vPeriodsRow.AccountingDate = vPeriod.AccountingDate;
						If vPeriodsRow.DoNotChangeAvailability Then
							vPeriodsRow.NumberOfRooms = 0;
							vPeriodsRow.NumberOfBeds = 0;
							vPeriodsRow.NumberOfAdditionalBeds = 0;
						EndIf;
					EndDo;
				Else
					// Check if this room is in connected
					vConnectRoom = cmGetConnectRoom(vPeriod.Room);
					If ValueIsFilled(vConnectRoom) Then
						// Get vacant periods for this connect room
						vConnectRoomVacantPeriods = cmGetRoomVacantPeriods(vConnectRoom, cm1SecondShift(vPeriod.CheckInDate), cm0SecondShift(vPeriod.CheckOutDate));
						For Each vConnectRoomVacantPeriodsRow In vConnectRoomVacantPeriods Do
							vPeriodsRow = vNewPeriods.Add();
							vPeriodsRow.Ref = vPeriod.Ref;
							vPeriodsRow.Hotel = vPeriod.Hotel;
							vPeriodsRow.RoomQuota = vPeriod.RoomQuota;
							vPeriodsRow.CheckInDate = vConnectRoomVacantPeriodsRow.PeriodFrom;
							vPeriodsRow.CheckOutDate = vConnectRoomVacantPeriodsRow.PeriodTo;
							vPeriodsRow.RoomType = vConnectRoomVacantPeriodsRow.RoomType;
							vPeriodsRow.Room = vConnectRoomVacantPeriodsRow.Room;
							vPeriodsRow.AccommodationType = vPeriod.AccommodationType;
							vPeriodsRow.AccommodationTemplate = vPeriod.AccommodationTemplate;
							vPeriodsRow.RoomRate = vPeriod.RoomRate;
							vRoomAttrs = vConnectRoomVacantPeriodsRow.Room.GetObject().pmGetRoomAttributes(cm1SecondShift(vConnectRoomVacantPeriodsRow.PeriodFrom));
							vPeriodsRow.NumberOfBedsPerRoom = vRoomAttrs[0].NumberOfBedsPerRoom;
							vPeriodsRow.NumberOfPersonsPerRoom = vRoomAttrs[0].NumberOfPersonsPerRoom;
							vPeriodsRow.NumberOfPersons = 0;
							vPeriodsRow.NumberOfRooms = ?(vPeriod.NumberOfRooms <> 0, vConnectRoomVacantPeriodsRow.RoomsVacant, 0);
							vPeriodsRow.NumberOfBeds = ?(vPeriod.NumberOfBeds <> 0, vConnectRoomVacantPeriodsRow.BedsVacant, 0);
							vPeriodsRow.NumberOfAdditionalBeds = 0;
							vPeriodsRow.IsRoomChange = vPeriod.IsRoomChange;
							vPeriodsRow.IsCheckOut = vPeriod.IsCheckOut;
							vPeriodsRow.IsCheckIn = vPeriod.IsCheckIn;
							vPeriodsRow.DoNotChangeAvailability = vPeriod.DoNotChangeAvailability;
							vPeriodsRow.AccountingDate = vPeriod.AccountingDate;
							If vPeriodsRow.DoNotChangeAvailability Then
								vPeriodsRow.NumberOfRooms = 0;
								vPeriodsRow.NumberOfBeds = 0;
								vPeriodsRow.NumberOfAdditionalBeds = 0;
							EndIf;
						EndDo;
					EndIf;
				EndIf;			
			ElsIf ValueIsFilled(vPeriod.RoomType) Then
				If vPeriod.RoomType.ConnectedRoomTypes.Count() > 0 Then
					For Each vConnectedRoomTypesRow In vPeriod.RoomType.ConnectedRoomTypes Do
						vPeriodsRow = vNewPeriods.Add();
						vPeriodsRow.Ref = vPeriod.Ref;
						vPeriodsRow.Hotel = vPeriod.Hotel;
						vPeriodsRow.RoomQuota = vPeriod.RoomQuota;
						vPeriodsRow.CheckInDate = vPeriod.CheckInDate;
						vPeriodsRow.CheckOutDate = vPeriod.CheckOutDate;
						vPeriodsRow.RoomType = vConnectedRoomTypesRow.RoomType;
						vPeriodsRow.AccommodationType = vPeriod.AccommodationType;
						vPeriodsRow.AccommodationTemplate = vPeriod.AccommodationTemplate;
						vPeriodsRow.RoomRate = vPeriod.RoomRate;
						vPeriodsRow.NumberOfBedsPerRoom = vConnectedRoomTypesRow.RoomType.NumberOfBedsPerRoom;
						vPeriodsRow.NumberOfPersonsPerRoom = vConnectedRoomTypesRow.RoomType.NumberOfPersonsPerRoom;
						vPeriodsRow.NumberOfPersons = 0;
						vPeriodsRow.NumberOfRooms = vPeriod.NumberOfRooms;
						vPeriodsRow.NumberOfBeds = vPeriod.NumberOfRooms * vConnectedRoomTypesRow.RoomType.NumberOfBedsPerRoom;
						vPeriodsRow.NumberOfAdditionalBeds = 0;
						vPeriodsRow.IsRoomChange = vPeriod.IsRoomChange;
						vPeriodsRow.IsCheckOut = vPeriod.IsCheckOut;
						vPeriodsRow.IsCheckIn = vPeriod.IsCheckIn;
						vPeriodsRow.DoNotChangeAvailability = vPeriod.DoNotChangeAvailability;
						vPeriodsRow.AccountingDate = vPeriod.AccountingDate;
						If vPeriodsRow.DoNotChangeAvailability Then
							vPeriodsRow.NumberOfRooms = 0;
							vPeriodsRow.NumberOfBeds = 0;
							vPeriodsRow.NumberOfAdditionalBeds = 0;
						EndIf;
					EndDo;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	Return vNewPeriods;
EndFunction // pmGetAccommodationPeriods 

// -----------------------------------------------------------------------------
// 
// Returns:
//  ValueTable - Room rates 
//
Function pmGetAccommodationPlan() Export
	// Unload and sort room rates rows
	vRoomRates = RoomRates.Unload();
	vRoomRates.Sort("AccountingDate, ChangeTime");
	// Do for each date in accommodation period
	vRRRow = Undefined;
	vPrevRRRow = Undefined;
	vCurDate = BegOfDay(CheckInDate);
	
	While vCurDate <= BegOfDay(CheckOutDate) Do
		vRRRow = vRoomRates.Find(vCurDate, "AccountingDate");
		If vRRRow = Undefined Then
			vRRRow = vRoomRates.Add();
			vRRRow.AccountingDate = vCurDate;
		EndIf;
		If vPrevRRRow <> Undefined Then
			If Not ValueIsFilled(vRRRow.RoomRate) Then
				vRRRow.RoomRate = vPrevRRRow.RoomRate;
			EndIf;
			If Not ValueIsFilled(vRRRow.PriceCalculationDate) Then
				vRRRow.PriceCalculationDate = vPrevRRRow.PriceCalculationDate;
			EndIf;
			If Not ValueIsFilled(vRRRow.AccommodationType) Then
				vRRRow.AccommodationType = vPrevRRRow.AccommodationType;
			EndIf;
			If Not ValueIsFilled(vRRRow.RoomType) Then
				vRRRow.RoomType = vPrevRRRow.RoomType;
			EndIf;
			If Not ValueIsFilled(vRRRow.Room) Then
				vRRRow.Room = vPrevRRRow.Room;
			EndIf;
			If Not ValueIsFilled(vRRRow.AccommodationTemplate) Then
				vRRRow.AccommodationTemplate = vPrevRRRow.AccommodationTemplate;
			EndIf;
			If IsBlankString(vRRRow.Discount) Then
				vRRRow.Discount = vPrevRRRow.Discount;
			EndIf;
			If IsBlankString(vRRRow.AgentCommission) Then
				vRRRow.AgentCommission = vPrevRRRow.AgentCommission;
			EndIf;
			If Not ValueIsFilled(vRRRow.ClientType) Then
				vRRRow.ClientType = vPrevRRRow.ClientType;
			EndIf;
			If Not ValueIsFilled(vRRRow.SourceOfBusiness) Then
				vRRRow.SourceOfBusiness = vPrevRRRow.SourceOfBusiness;
			EndIf;
			If Not ValueIsFilled(vRRRow.MarketingCode) Then
				vRRRow.MarketingCode = vPrevRRRow.MarketingCode;
			EndIf;
			If Not ValueIsFilled(vRRRow.ServicePackage) Then
				vRRRow.ServicePackage = vPrevRRRow.ServicePackage;
			EndIf;
			If Not ValueIsFilled(vRRRow.BoardPlace) Then
				vRRRow.BoardPlace = vPrevRRRow.BoardPlace;
			EndIf;
		Else
			If Not ValueIsFilled(vRRRow.RoomRate) Then
				vRRRow.RoomRate = RoomRate;
			EndIf;
			If Not ValueIsFilled(vRRRow.PriceCalculationDate) Then
				vRRRow.PriceCalculationDate = PriceCalculationDate;
			EndIf;
			If Not ValueIsFilled(vRRRow.AccommodationType) Then
				vRRRow.AccommodationType = AccommodationType;
			EndIf;
			If Not ValueIsFilled(vRRRow.RoomType) Then
				vRRRow.RoomType = RoomType;
			EndIf;
			If Not ValueIsFilled(vRRRow.Room) Then
				vRRRow.Room = Room;
			EndIf;
			If Not ValueIsFilled(vRRRow.AccommodationTemplate) Then
				vRRRow.AccommodationTemplate = AccommodationTemplate;
			EndIf;
			If IsBlankString(vRRRow.Discount) Then
				vRRRow.Discount = "";
			EndIf;
			If IsBlankString(vRRRow.AgentCommission) Then
				vRRRow.AgentCommission = Format(AgentCommission, "ND=17; NFD=2; NDS=.; NZ=; NG=");
			EndIf;
			If Not ValueIsFilled(vRRRow.ClientType) Then
				vRRRow.ClientType = ClientType;
			EndIf;
			If Not ValueIsFilled(vRRRow.SourceOfBusiness) Then
				vRRRow.SourceOfBusiness = SourceOfBusiness;
			EndIf;
			If Not ValueIsFilled(vRRRow.MarketingCode) Then
				vRRRow.MarketingCode = MarketingCode;
			EndIf;
			If Not ValueIsFilled(vRRRow.ServicePackage) Then
				If ValueIsFilled(ServicePackage) And ServicePackage.IsMealBoardTerm Then
					vRRRow.ServicePackage = ServicePackage;
				EndIf;
			EndIf;
			If Not ValueIsFilled(vRRRow.BoardPlace) Then
				vRRRow.BoardPlace = BoardPlace;
			EndIf;
		EndIf;
		vPrevRRRow = vRRRow;
		vCurDate = vCurDate + 24*3600;
	EndDo;
	
	vRoomRates.Sort("AccountingDate, ChangeTime");
	Return vRoomRates;
EndFunction //  pmGetAccommodationPlan 

// -----------------------------------------------------------------------------
Procedure pmCheckRoomRates() Export
	vRRAreChanged = False;
	i = 0;
	While i < RoomRates.Count() Do
		vRRRow = RoomRates.Get(i);
		If BegOfDay(vRRRow.AccountingDate) < BegOfDay(CheckInDate) Or 
		   BegOfDay(vRRRow.AccountingDate) > BegOfDay(CheckOutDate) Then
			RoomRates.Delete(i);
			vRRAreChanged = True;
		ElsIf Not ValueIsFilled(vRRRow.AccommodationType) And
		      Not ValueIsFilled(vRRRow.Room) And 
		      Not ValueIsFilled(vRRRow.RoomType) And 
		      Not ValueIsFilled(vRRRow.RoomRate) And 
		      Not ValueIsFilled(vRRRow.PriceCalculationDate) And 
		      Not ValueIsFilled(vRRRow.AccommodationTemplate) And 
		      Not ValueIsFilled(vRRRow.ClientType) And 
		      Not ValueIsFilled(vRRRow.SourceOfBusiness) And 
		      Not ValueIsFilled(vRRRow.MarketingCode) And 
		      Not ValueIsFilled(vRRRow.ServicePackage) And 
		      Not ValueIsFilled(vRRRow.BoardPlace) And 
		      IsBlankString(vRRRow.Discount) And 
		      IsBlankString(vRRRow.AgentCommission) And 
		      Not vRRRow.DoNotChangeAvailability And 
		      Not vRRRow.IsBookedOut Then
			RoomRates.Delete(i);
			vRRAreChanged = True;
		Else
			i = i + 1;
		EndIf;
	EndDo;
	// Add initialization row for the first day
	If RoomRates.Count() > 0 Then
		vAddCheckInRow = True;
		For Each vRRRow In RoomRates Do
			If BegOfDay(vRRRow.AccountingDate) = BegOfDay(CheckInDate) Then
				vAddCheckInRow = False;
			ElsIf BegOfDay(vRRRow.AccountingDate) > BegOfDay(CheckInDate) Then
				Break;
			EndIf;
		EndDo;
		vRRRow = Undefined;
		If vAddCheckInRow Then
			vRRRow = RoomRates.Insert(0);
			vRRRow.AccountingDate = BegOfDay(CheckInDate);
		Else
			vRRRow = RoomRates.Find(BegOfDay(CheckInDate), "AccountingDate");
		EndIf;
		If vRRRow <> Undefined Then
			If Not ValueIsFilled(vRRRow.AccommodationTemplate) Then
				vRRRow.AccommodationTemplate = AccommodationTemplate;
			EndIf;
			If Not ValueIsFilled(vRRRow.AccommodationType) Then
				vRRRow.AccommodationType = AccommodationType;
			EndIf;
			If Not ValueIsFilled(vRRRow.Room) Then
				vRRRow.Room = Room;
			EndIf;
			If Not ValueIsFilled(vRRRow.RoomType) Then
				vRRRow.RoomType = RoomType;
			EndIf;
			If Not ValueIsFilled(vRRRow.RoomRate) Then
				vRRRow.RoomRate = RoomRate;
			EndIf;
			If Not ValueIsFilled(vRRRow.PriceCalculationDate) Then
				vRRRow.PriceCalculationDate = PriceCalculationDate;
			EndIf;
			vRRAreChanged = True;
		EndIf;
	EndIf;
	If vRRAreChanged Then
		RoomRates.Sort("AccountingDate, ChangeTime");
	EndIf;
EndProcedure //  pmCheckRoomRates

// -----------------------------------------------------------------------------
// 
// Returns:
//  Boolean - Check room main folios 
//
Function pmCheckRoomMainFolios() Export
	vDoReloadDefault = False;
	If ValueIsFilled(AccommodationType) Then
		If Not IsForFolioSplit And AccommodationType.PostToRoomMainFolio Then
			vRoomMainDoc = GetRoomMainReservation();
			If ValueIsFilled(vRoomMainDoc) Then
				// Check for personal folios
				vRoomMainDocPersonalFoliosAreFound = False;
				For Each vRMCRRow In vRoomMainDoc.ChargingRules Do
					If vRMCRRow.IsPersonal And Not vRMCRRow.IsTransfer And Not vRMCRRow.IsMaster And 
					   ValueIsFilled(vRMCRRow.ChargingFolio) And Not vRMCRRow.ChargingFolio.IsMaster Then
						vRoomMainDocPersonalFoliosAreFound = True;
						Break;
					EndIf;
				EndDo;
				If vRoomMainDocPersonalFoliosAreFound And AccommodationType.PostToRoomMainFolio And Not AccommodationType.DoNotCreatePersonalFolios Then
					vRuleIsFound = False;
					For Each vCRRow In ChargingRules Do
						If vCRRow.IsPersonal And Not vCRRow.IsTransfer And Not vCRRow.IsMaster And 
						   ValueIsFilled(vCRRow.ChargingFolio) And Not vCRRow.ChargingFolio.IsMaster Then
							vRuleIsFound = True;
							Break;
						EndIf;
					EndDo;
					If Not vRuleIsFound Then
						vDoReloadDefault = True;
					EndIf;
				EndIf;
				// Check for room main person folios
				If Not vDoReloadDefault Then
					For Each vRMCRRow In vRoomMainDoc.ChargingRules Do
						If (Not vRMCRRow.IsPersonal Or AccommodationType.DoNotCreatePersonalFolios) And 
						   Not vRMCRRow.IsTransfer And Not vRMCRRow.IsMaster And 
						   ValueIsFilled(vRMCRRow.ChargingFolio) And Not vRMCRRow.ChargingFolio.IsMaster Then
							vRuleIsFound = False;
							For Each vCRRow In ChargingRules Do
								If vCRRow.IsTransfer And vRMCRRow.ChargingFolio = vCRRow.ChargingFolio Then
									vRuleIsFound = True;
									Break;
								EndIf;
							EndDo;
							If Not vRuleIsFound Then
								vDoReloadDefault = True;
								Break;
							EndIf;
						EndIf;
					EndDo;
				EndIf;
				If vDoReloadDefault Then
					// Load 
					pmReloadDefaultChargingRules(vRoomMainDoc);
					// Automatic services list calculation	
					pmCalculateServices();
					// Set planned payment method
					vPayer = pmSetPlannedPaymentMethod();
				EndIf;
			EndIf;
		Else
			// If all charging rules are transfers to the room main folios then cancel this transfer
			vDoReloadDefault = True;
			For Each vCRRow In ChargingRules Do
				If Not vCRRow.IsTransfer And Not vCRRow.IsMaster And Not vCRRow.IsPersonal And ValueIsFilled(vCRRow.ChargingFolio) And Not vCRRow.ChargingFolio.IsMaster Then
					vDoReloadDefault = False;
					Break;
				EndIf;
			EndDo;
			If vDoReloadDefault Then
				// Load 
				pmLoadDefaultChargingRules();
				// Automatic services list calculation	
				pmCalculateServices();
				// Set planned payment method
				vPayer = pmSetPlannedPaymentMethod();
			EndIf;
		EndIf;
	EndIf;
	Return vDoReloadDefault;
EndFunction // pmCheckRoomMainFolios

// -----------------------------------------------------------------------------
Procedure pmCheckReservationChains() Export
	// Try to find previous reservation to be used as parent one
	vPrevReservation = cmGetPreviousReservation(GuestGroup, CheckInDate, AccommodationType, , Guest, Customer);
	If ValueIsFilled(vPrevReservation) And (Not ValueIsFilled(ParentDoc) Or 
	   ValueIsFilled(ParentDoc) And (TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") And ParentDoc.Reservation <> vPrevReservation)) Then
		If vPrevReservation <> Ref And (vPrevReservation <> ParentDoc Or vPrevReservation = ParentDoc And 
			                            vPrevReservation.ChargingRules.Count() > 0 And ChargingRules.Count() > 0 And 
										vPrevReservation.ChargingRules.Get(vPrevReservation.ChargingRules.Count() - 1).ChargingFolio <> ChargingRules.Get(ChargingRules.Count() - 1).ChargingFolio) Then
			cmFillAttributesFromParentDocument(ThisObject, vPrevReservation, True);
			// Automatic services list calculation	
			pmCalculateServices();
			// Set planned payment method
			vPayer = pmSetPlannedPaymentMethod();
		EndIf;
	Else
		If ValueIsFilled(ParentDoc) And TypeOf(ParentDoc) = Type("DocumentRef.Reservation") And ParentDoc.GuestGroup = GuestGroup Then
			ParentDoc = Undefined;
			pmLoadDefaultChargingRules();
			// Automatic services list calculation	
			pmCalculateServices();
			// Set planned payment method
			vPayer = pmSetPlannedPaymentMethod();
		EndIf;
	EndIf;
	// Try to find next reservation and repost it
	vNextReservation = cmGetNextReservation(GuestGroup, CheckOutDate, AccommodationType, Guest);
	If ValueIsFilled(vNextReservation) And vNextReservation.ParentDoc <> Ref And vNextReservation <> Ref Then
		vNextReservation.GetObject().Write(DocumentWriteMode.Posting);
	EndIf;
EndProcedure //  pmCheckReservationChains

// -----------------------------------------------------------------------------
// 
// Returns:
//  ValueTable - Service 
//
Function pmGetResourceServices() Export
	vRRServices = Services.Unload();
	vRRServices.Clear();
	For Each vSrvRow In Services Do
		If vSrvRow.Quantity = 0 Then
			Continue;
		EndIf;
		If ValueIsFilled(vSrvRow.AccountingDate) And 
		   ValueIsFilled(vSrvRow.ServiceResource) And TypeOf(vSrvRow.ServiceResource) = Type("CatalogRef.Resources") And 
		   vSrvRow.DoResourceReservation Then
			vRRServicesRow = vRRServices.Add();
			FillPropertyValues(vRRServicesRow, vSrvRow);
		EndIf;
	EndDo;
	Return vRRServices;
EndFunction //  pmGetResourceServices

// -----------------------------------------------------------------------------
Procedure pmUndoPosting(pCancel) Export
	// 1. Check should we repost any intersecting accommodations or reservations
	// Build value table of accommodation periods
	vPeriods = pmGetAccommodationPeriods(True);
	// Process each accommodation period separately
	For Each vPeriodsRow In vPeriods Do
		If vPeriodsRow.NumberOfBeds <> 0 Then
			vIntersectedDocs = cmGetTableOfIntersectedDocs(vPeriodsRow);
			If vIntersectedDocs.Count() > 0 Then
				// Clear registry records of the current document
				pmClearInventoryRegisterRecords();
				// Clear registry records for the intersecting documents
				ClearInventoryRecordsForIntersectedDocs(vIntersectedDocs);
				// Repost intersected documents
				RepostIntersectedDocs(vIntersectedDocs, vPeriodsRow, 0);
			EndIf;
		EndIf;
	EndDo;
	// 2. Build table of already charged services and then delete all (or future) chargings 
	vChargesTab = cmGetTableOfAlreadyChargedServices(Ref, Ref.IsForFolioSplit);
	For Each vChargesTabRow In vChargesTab Do
		vChargeRef = vChargesTabRow.Ref;
		vChargeIsInClosedDay = cmIfChargeIsInClosedDay(vChargeRef);
		If Not vChargeIsInClosedDay And ValueIsFilled(vChargesTabRow.RoomRevenueCharge) Then
			vChargeIsInClosedDay = cmIfChargeIsInClosedDay(vChargesTabRow.RoomRevenueCharge);
		EndIf;
		If Not vChargeIsInClosedDay Then
			vChargeObj = vChargeRef.GetObject();
			vChargeObj.SetDeletionMark(True);
		EndIf;
	EndDo;
	// 3. Delete bound resource reservations
	vResourceReservations = cmGetChildResourceReservations(Ref, True);
	For Each vResourceReservationsRow In vResourceReservations Do
		vResourceReservationObj = vResourceReservationsRow.Ref.GetObject();
		vResourceReservationObj.AdditionalProperties.Insert("AllowSetDeletionMark", True);
		vResourceReservationObj.SetDeletionMark(True);
	EndDo;
EndProcedure // pmUndoPosting

// -----------------------------------------------------------------------------
Procedure pmClearInventoryRegisterRecords() Export
	RegisterRecords.RoomInventory.Clear();
	RegisterRecords.RoomQuotaSales.Clear();
	RegisterRecords.ExpectedGuestGroups.Clear();
	// If posted
	If Posted Then
		// Room inventory
	    vRISet = AccumulationRegisters.RoomInventory.CreateRecordSet();
	    vRISet.Filter.Recorder.Set(Ref);
	    vRISet.Read();
	    vRISet.Clear();
	    vRISet.Write(True);
		// Room quota sales
	    vRQSet = AccumulationRegisters.RoomQuotaSales.CreateRecordSet();
	    vRQSet.Filter.Recorder.Set(Ref);
	    vRQSet.Read();
	    vRQSet.Clear();
	    vRQSet.Write(True);
		// Expected guest groups
		RegisterRecords.ExpectedGuestGroups.Write();
	EndIf;
EndProcedure //  pmClearInventoryRegisterRecords

// -----------------------------------------------------------------------------
Procedure pmClearSalesForecastRegisterRecords() Export
	// Clear forecast registers record sets
	RegisterRecords.SalesForecast.Clear();
	RegisterRecords.ServiceRegistration.Clear();
	RegisterRecords.HotelProductLog.Clear();
	// If posted
	If Posted Then
		// Sales forecast
	    vSFSet = AccumulationRegisters.SalesForecast.CreateRecordSet();
	    vSFSet.Filter.Recorder.Set(Ref);
	    vSFSet.Read();
	    vSFSet.Clear();
	    vSFSet.Write(True);
		// Hotel product log
	    vHPLSet = AccumulationRegisters.HotelProductLog.CreateRecordSet();
	    vHPLSet.Filter.Recorder.Set(Ref);
	    vHPLSet.Read();
	    vHPLSet.Clear();
	    vHPLSet.Write(True);
		// Service registration
	    vSFSet = AccumulationRegisters.ServiceRegistration.CreateRecordSet();
	    vSFSet.Filter.Recorder.Set(Ref);
	    vSFSet.Read();
	    vSFSet.Clear();
	    vSFSet.Write(True);
	EndIf;
EndProcedure //  pmClearSalesForecastRegisterRecords

// -----------------------------------------------------------------------------
Procedure FillRChgAttributes(pRChgRec, pPeriod, pUser)
	FillPropertyValues(pRChgRec, ThisObject);
	
	pRChgRec.Period = pPeriod;
	pRChgRec.Reservation = Ref;
	pRChgRec.User = pUser;
	
	// Store tabular parts
	vPrices = New ValueStorage(Prices.Unload());
	pRChgRec.Prices = vPrices;
	vRoomRates = New ValueStorage(RoomRates.Unload());
	pRChgRec.RoomRates = vRoomRates;
	vServicePackages = New ValueStorage(ServicePackages.Unload());
	pRChgRec.ServicePackages = vServicePackages;
	vServices = New ValueStorage(Services.Unload());
	pRChgRec.Services = vServices;
	vChargingRules = New ValueStorage(ChargingRules.Unload());
	pRChgRec.ChargingRules = vChargingRules;
	vRooms = New ValueStorage(Rooms.Unload());
	pRChgRec.Rooms = vRooms;
	vOccupationPercents = New ValueStorage(OccupationPercents.Unload());
	pRChgRec.OccupationPercents = vOccupationPercents;
	vRoomProperties = New ValueStorage(RoomProperties.Unload());
	pRChgRec.RoomProperties = vRoomProperties;
EndProcedure //  FillRChgAttributes

// -----------------------------------------------------------------------------
Procedure pmWriteToReservationChangeHistory(pPeriod, pUser) Export
	// Get channges description
	vChanges = cmGetObjectChanges(ThisObject);
	If Not IsBlankString(vChanges) Then
		// Do movement on current date
		vRChgRec = InformationRegisters.ReservationChangeHistory.CreateRecordManager();
		
		FillRChgAttributes(vRChgRec, pPeriod, pUser);
		vRChgRec.Changes = vChanges;
		
		// Write record
		vRChgRec.Write(True);    
		
		// User activity history
		InformationRegisters.UserActionsHistory.WriteUserActivityRecord(Ref, vChanges, Hotel, pUser, pPeriod);
	EndIf;
EndProcedure //  pmWriteToReservationChangeHistory

// -----------------------------------------------------------------------------
//
// Parameters:
//  pPeriod	 - Date	 - 
// 
// Returns:
//  ValueTable - ValueTable row ReservationChangeHistory
//
Function pmGetPreviousObjectState(pPeriod, pMergeGuestState = False) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	*
	|FROM
	|	InformationRegister.ReservationChangeHistory.SliceLast(&qPeriod, Reservation = &qDoc) AS ReservationChangeHistoryState";
	vQry.SetParameter("qPeriod", pPeriod);
	vQry.SetParameter("qDoc", Ref);
	vStates = vQry.Execute().Unload();
	If pMergeGuestState And vStates.Count() > 0 Then
		vStates.Columns.Add("Citizenship");
		vStates.Columns.Add("Region");
		vStates.Columns.Add("City");
		vStates.Columns.Add("Age");
		
		vDocStateRow = vStates.Get(0);
		If ValueIsFilled(vDocStateRow.Period) And ValueIsFilled(vDocStateRow.Guest) Then
			vCltQry = New Query();
			vCltQry.Text = 
			"SELECT
			|	ClientChangeHistoryState.Citizenship AS Citizenship,
		 	|	ClientChangeHistoryState.Region AS Region,
		 	|	ClientChangeHistoryState.City AS City,
		 	|	ClientChangeHistoryState.Age AS Age
			|FROM
			|	InformationRegister.ClientChangeHistory.SliceLast(&qDocStatePeriod, Client = &qClient) AS ClientChangeHistoryState";
			vCltQry.SetParameter("qDocStatePeriod", vDocStateRow.Period);
			vCltQry.SetParameter("qClient", vDocStateRow.Guest);
			vCltStates = vCltQry.Execute().Unload();
			If vCltStates.Count() > 0 Then
				vCltStateRow = vCltStates.Get(0);
				vDocStateRow.Citizenship = vCltStateRow.Citizenship;
				vDocStateRow.Region = vCltStateRow.Region;
				vDocStateRow.City = vCltStateRow.City;
				vDocStateRow.Age = vCltStateRow.Age;
			EndIf;
		EndIf;
	EndIf;
	If vStates.Count() > 0 Then
		Return vStates.Get(0);
	Else
		Return Undefined;
	EndIf;
EndFunction //  pmGetPreviousObjectState

// -----------------------------------------------------------------------------
Procedure pmRestoreAttributesFromHistory(pRChgRec) Export
	FillPropertyValues(ThisObject, pRChgRec, , "Number, Date, Author");
	If Not IsBlankString(pRChgRec.Number) Then
		Number = pRChgRec.Number;
	EndIf;
	If ValueIsFilled(pRChgRec.Date) Then
		Date = pRChgRec.Date;
	EndIf;
	If ValueIsFilled(pRChgRec.Author) Then
		Author = pRChgRec.Author;
	EndIf;
	// Restore tabular parts
	vPrices = pRChgRec.Prices.Get();
	If vPrices <> Undefined Then
		Prices.Load(vPrices);
	Else
		Prices.Clear();
	EndIf;
	vRoomRates = pRChgRec.RoomRates.Get();
	If vRoomRates <> Undefined Then
		RoomRates.Load(vRoomRates);
	Else
		RoomRates.Clear();
	EndIf;
	vServicePackages = pRChgRec.ServicePackages.Get();
	If vServicePackages <> Undefined Then
		ServicePackages.Load(vServicePackages);
	Else
		ServicePackages.Clear();
	EndIf;
	vServices = pRChgRec.Services.Get();
	If vServices <> Undefined Then
		Services.Load(vServices);
	Else
		Services.Clear();
	EndIf;
	vChargingRules = pRChgRec.ChargingRules.Get();
	If vChargingRules <> Undefined Then
		ChargingRules.Load(vChargingRules);
	Else
		ChargingRules.Clear();
	EndIf;
	vRooms = pRChgRec.Rooms.Get();
	If vRooms <> Undefined Then
		Rooms.Load(vRooms);
	Else
		Rooms.Clear();
	EndIf;
	vOccupationPercents = pRChgRec.OccupationPercents.Get();
	If vOccupationPercents <> Undefined Then
		OccupationPercents.Load(vOccupationPercents);
	Else
		OccupationPercents.Clear();
	EndIf;
	vRoomProperties = pRChgRec.RoomProperties.Get();
	If vRoomProperties <> Undefined Then
		RoomProperties.Load(vRoomProperties);
	Else
		RoomProperties.Clear();
	EndIf;
EndProcedure //  pmRestoreAttributesFromHistory

// -----------------------------------------------------------------------------
// 
// Returns:
//  ValueTable - ValueTable row ReservationChangeHistory
//
Function pmGetLastDocumentState() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	* 
	|FROM
	|	InformationRegister.ReservationChangeHistory AS ReservationChangeHistory
	|WHERE
	|	ReservationChangeHistory.Reservation = &qDoc
	|ORDER BY
	|	Period DESC";
	vQry.SetParameter("qDoc", Ref);
	vStates = vQry.Execute().Unload();
	If vStates.Count() > 0 Then
		Return vStates.Get(0);
	Else
		Return Undefined;
	EndIf;
EndFunction //  pmGetLastDocumentState

// -----------------------------------------------------------------------------
//
// Parameters:
//  pPeriod			 - 	 - 
//  pIsPosted		 - 	 - 
//  pMessage		 - 	 - 
//  pAttributeInErr	 - 	 - 
//  pDoNotCheckRests - 	 - 
//  pDoCheckRests	 - 	 - 
// 
// Returns:
//  Boolean - Has errors 
//
Function pmCheckDocumentAttributes(pPeriod, pIsPosted, pMessage, pAttributeInErr, pDoNotCheckRests = False, pDoCheckRests = False, pNoPermissionForOverbooking = False) Export
 	vHasErrors = False;
	pMessage = "";
	pAttributeInErr = "";
	vMsgTextRu = "";
	vMsgTextEn = "";
	vMsgTextDe = "";
	If AdditionalProperties.Property("InfoBaseUpdateMode") And AdditionalProperties.InfoBaseUpdateMode Then
		Return vHasErrors;
	EndIf;
	If AdditionalProperties.Property("DoNotCheckRests") Then
		pDoNotCheckRests = AdditionalProperties.DoNotCheckRests;
	EndIf;
	If Not ValueIsFilled(Hotel) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Гостиница> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Hotel> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Hotel> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Hotel", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(Company) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Фирма> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Company> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Company> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Company", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(ExchangeRateDate) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Дата курса> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Exchange rate date> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Exchange rate date> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "ExchangeRateDate", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(ReportingCurrency) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Отчетная валюта> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Reporting currency> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Reporting currency> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "ReportingCurrency", pAttributeInErr);
	EndIf;
	If ReportingCurrencyExchangeRate <= 0 Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Курс отчетной валюты> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Reporting currency exchange rate> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Reporting currency exchange rate> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "ReportingCurrencyExchangeRate", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(GuestGroup) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Номер группы> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Guest group> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Guest group> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "GuestGroup", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(ReservationStatus) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Статус брони> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Reservation status> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Reservation status> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "ReservationStatus", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(AccommodationType) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Вид размещения> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Accommodation type> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Accommodation type> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "AccommodationType", pAttributeInErr);
	ElsIf ValueIsFilled(Guest) And ValueIsFilled(CheckInDate) And ValueIsFilled(ReservationStatus) And (ReservationStatus.IsActive Or ReservationStatus.IsPreliminary) Then
		If Not ValueIsFilled(Guest.DateOfBirth) Then
			If AccommodationType.AllowedClientAgeFrom <> 0 Or 
			   AccommodationType.AllowedClientAgeTo <> 0 Or 
			   ValueIsFilled(AccommodationType.AllowedClientAgeRange) Then
				If Not cmCheckUserPermissions("HavePermissionToIgnoreGuestAgeLimitations") Then
					vHasErrors = True; 
					vMsgTextRu = vMsgTextRu + "Не указана дата рождения гостя " + TrimAll(Guest) + "!" + Chars.LF;
					vMsgTextEn = vMsgTextEn + "Date of birth is not specified for guest " + TrimAll(Guest) + "!" + Chars.LF;
					vMsgTextDe = vMsgTextDe + "Date of birth is not specified for guest " + TrimAll(Guest) + "!" + Chars.LF;
					pAttributeInErr = ?(pAttributeInErr = "", "Guest", pAttributeInErr);
				EndIf;
			EndIf;
		EndIf;
		vGuestAge = Guest.GetObject().pmGetClientAge(CheckInDate);
		If Not (AccommodationType.AllowedClientAgeFrom = 0 And vGuestAge = 0) And AccommodationType.AllowedClientAgeFrom >= vGuestAge Then
			If Not cmCheckUserPermissions("HavePermissionToIgnoreGuestAgeLimitations") Then
				vHasErrors = True; 
				vMsgTextRu = vMsgTextRu + "Возраст гостя должен быть больше " + AccommodationType.AllowedClientAgeFrom + "!" + Chars.LF;
				vMsgTextEn = vMsgTextEn + "Guest has to be more then " + AccommodationType.AllowedClientAgeFrom + " years old!" + Chars.LF;
				vMsgTextDe = vMsgTextDe + "Guest has to be more then " + AccommodationType.AllowedClientAgeFrom + " years old!" + Chars.LF;
				pAttributeInErr = ?(pAttributeInErr = "", "Guest", pAttributeInErr);
			EndIf;
		EndIf;
		If AccommodationType.AllowedClientAgeTo > 0 And AccommodationType.AllowedClientAgeTo <= vGuestAge Then
			If Not cmCheckUserPermissions("HavePermissionToIgnoreGuestAgeLimitations") Then
				vHasErrors = True; 
				vMsgTextRu = vMsgTextRu + "Возраст гостя должен быть меньше " + AccommodationType.AllowedClientAgeTo + "!" + Chars.LF;
				vMsgTextEn = vMsgTextEn + "Guest has to be less then " + AccommodationType.AllowedClientAgeTo + " years old!" + Chars.LF;
				vMsgTextDe = vMsgTextDe + "Guest has to be less then " + AccommodationType.AllowedClientAgeTo + " years old!" + Chars.LF;
				pAttributeInErr = ?(pAttributeInErr = "", "Guest", pAttributeInErr);
			EndIf;
		EndIf;
		If ValueIsFilled(AccommodationType.AllowedClientAgeRange) Then
			vGuestAgeRange = Guest.GetObject().pmGetClientAgeRange(vGuestAge);
			If AccommodationType.AllowedClientAgeRange <> vGuestAgeRange Then
				If Not cmCheckUserPermissions("HavePermissionToIgnoreGuestAgeLimitations") Then
					vHasErrors = True; 
					vMsgTextRu = vMsgTextRu + "Возраст гостя должен быть в возрастной группе " + AccommodationType.AllowedClientAgeRange + "!" + Chars.LF;
					vMsgTextEn = vMsgTextEn + "Guest age has to be in " + AccommodationType.AllowedClientAgeRange + " age range group!" + Chars.LF;
					vMsgTextDe = vMsgTextDe + "Guest age has to be in " + AccommodationType.AllowedClientAgeRange + " age range group!" + Chars.LF;
					pAttributeInErr = ?(pAttributeInErr = "", "Guest", pAttributeInErr);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If Not ValueIsFilled(pPeriod.RoomType) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Тип номера> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Room type> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "Реквизит <Тип номера> должен быть заполнен!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "RoomType", pAttributeInErr);
	Else
		If pPeriod.RoomType.IsVirtual Then
			If Not cmCheckUserPermissions("HavePermissionToUseVirtualRooms") Then
				vHasErrors = True; 
				vMsgTextRu = vMsgTextRu + "Нет прав на бронирование виртуальных типов номеров!" + Chars.LF;
				vMsgTextEn = vMsgTextEn + "You do not have rights to reserve virtual room types!" + Chars.LF;
				vMsgTextDe = vMsgTextDe + "Нет прав на бронирование виртуальных типов номеров!" + Chars.LF;
				pAttributeInErr = ?(pAttributeInErr = "", "RoomType", pAttributeInErr);
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(pPeriod.Room) Then
		If pPeriod.Room.IsVirtual Then
			If Not cmCheckUserPermissions("HavePermissionToUseVirtualRooms") Then
				vHasErrors = True; 
				vMsgTextRu = vMsgTextRu + "Нет прав на бронирование виртуальных номеров!" + Chars.LF;
				vMsgTextEn = vMsgTextEn + "You do not have rights to reserve virtual rooms!" + Chars.LF;
				vMsgTextDe = vMsgTextDe + "Нет прав на бронирование виртуальных номеров!" + Chars.LF;
				pAttributeInErr = ?(pAttributeInErr = "", "Room", pAttributeInErr);
			EndIf;
		EndIf;
	EndIf;
	If Not ValueIsFilled(pPeriod.CheckInDate) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Дата заезда> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Check in date> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "Реквизит <Дата заезда> должен быть заполнен!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "CheckInDate", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(pPeriod.CheckOutDate) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Дата выезда> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Check out date> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "Реквизит <Дата выезда> должен быть заполнен!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "CheckOutDate", pAttributeInErr);
	EndIf;
	If ValueIsFilled(pPeriod.CheckInDate) And ValueIsFilled(pPeriod.CheckOutDate) Then
		If pPeriod.CheckInDate > pPeriod.CheckOutDate Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Дата выезда должна быть позже даты заезда!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "Check out date should be after check in date!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "Дата выезда должна быть позже даты заезда!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "CheckOutDate", pAttributeInErr);
		Else
			If ValueIsFilled(Contract) And ValueIsFilled(ReservationStatus) And (ReservationStatus.IsActive Or ReservationStatus.IsPreliminary) Then
				If Contract.PeriodCheckType = 0 Then
					If ValueIsFilled(Contract.ValidFromDate) And 
					   CheckInDate < BegOfDay(Contract.ValidFromDate) Or
					   ValueIsFilled(Contract.ValidToDate) And
					   CheckInDate > EndOfDay(Contract.ValidToDate) Then
						vHasErrors = True; 
						vMsgTextRu = vMsgTextRu + "Выбранный договор не действует на указанном периоде брони! (" + TrimAll(Customer) + "/" + TrimAll(Contract) + ", " + Format(CheckInDate, "DF=dd.MM.yyyy") + " - " + Format(CheckOutDate, "DF=dd.MM.yyyy") + ")" + Chars.LF;
						vMsgTextEn = vMsgTextEn + "Contract is not valid on period selected! (" + TrimAll(Customer) + "/" + TrimAll(Contract) + ", " + Format(CheckInDate, "DF=dd.MM.yyyy") + " - " + Format(CheckOutDate, "DF=dd.MM.yyyy") + ")" + Chars.LF;
						vMsgTextDe = vMsgTextDe + "Выбранный договор не действует на указанном периоде брони! (" + TrimAll(Customer) + "/" + TrimAll(Contract) + ", " + Format(CheckInDate, "DF=dd.MM.yyyy") + " - " + Format(CheckOutDate, "DF=dd.MM.yyyy") + ")" + Chars.LF;
						pAttributeInErr = ?(pAttributeInErr = "", "Contract", pAttributeInErr);
					EndIf;
				ElsIf Contract.PeriodCheckType = 1 Then
					If ValueIsFilled(Contract.ValidFromDate) And 
					   Date < BegOfDay(Contract.ValidFromDate) Or
					   ValueIsFilled(Contract.ValidToDate) And
					   Date > EndOfDay(Contract.ValidToDate) Then
						vHasErrors = True; 
						vMsgTextRu = vMsgTextRu + "Выбранный договор не действует на дату создания брони! (" + TrimAll(Customer) + "/" + TrimAll(Contract) + ", " + Format(CheckInDate, "DF=dd.MM.yyyy") + " - " + Format(CheckOutDate, "DF=dd.MM.yyyy") + ")" + Chars.LF;
						vMsgTextEn = vMsgTextEn + "Contract is not valid on reservation creation date! (" + TrimAll(Customer) + "/" + TrimAll(Contract) + ", " + Format(CheckInDate, "DF=dd.MM.yyyy") + " - " + Format(CheckOutDate, "DF=dd.MM.yyyy") + ")" + Chars.LF;
						vMsgTextDe = vMsgTextDe + "Выбранный договор не действует на дату создания брони! (" + TrimAll(Customer) + "/" + TrimAll(Contract) + ", " + Format(CheckInDate, "DF=dd.MM.yyyy") + " - " + Format(CheckOutDate, "DF=dd.MM.yyyy") + ")" + Chars.LF;
						pAttributeInErr = ?(pAttributeInErr = "", "Contract", pAttributeInErr);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(ReservationStatus) Then
		If ValueIsFilled(pPeriod.RoomType) Then
			If pPeriod.RoomType.StopSale And NumberOfBeds > 0 Then
				vRemarks = "";
				If cmIsStopSalePeriod(pPeriod.RoomType, pPeriod.CheckInDate, pPeriod.CheckOutDate, vRemarks) Then
					If Not cmCheckUserPermissions("HavePermissionToIgnoreStopSaleLimitations") Then
						vHasErrors = Not Posted;
					Else
						vHasErrors = False;
					EndIf;
					vMsgTextRu = vMsgTextRu + "Выбранный тип номера снят с продажи!" + Chars.LF + ?(IsBlankString(vRemarks), "", vRemarks + Chars.LF);
					vMsgTextEn = vMsgTextEn + "Room type choosen is out of sale!" + Chars.LF + ?(IsBlankString(vRemarks), "", vRemarks + Chars.LF);
					vMsgTextDe = vMsgTextDe + "Der ausgewählte Zimmertyp wurde aus dem Verkauf genommen!" + Chars.LF + ?(IsBlankString(vRemarks), "", vRemarks + Chars.LF);
					pAttributeInErr = ?(pAttributeInErr = "", "RoomType", pAttributeInErr);
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(pPeriod.Room) Then
			If pPeriod.Room.StopSale And NumberOfBeds > 0 Then
				vRemarks = "";
				If cmIsRoomStopSalePeriod(pPeriod.Room, pPeriod.CheckInDate, pPeriod.CheckOutDate, vRemarks) Then
					If Not cmCheckUserPermissions("HavePermissionToIgnoreStopSaleLimitations") Then
						vHasErrors = Not Posted;
					Else
						vHasErrors = False;
					EndIf;
					vMsgTextRu = vMsgTextRu + "Выбранный номер снят с продажи!" + Chars.LF + ?(IsBlankString(vRemarks), "", vRemarks + Chars.LF);
					vMsgTextEn = vMsgTextEn + "Room choosen is out of sale!" + Chars.LF + ?(IsBlankString(vRemarks), "", vRemarks + Chars.LF);
					vMsgTextDe = vMsgTextDe + "Ausgewählte Zimmer wird aus dem Verkauf genommen!" + Chars.LF + ?(IsBlankString(vRemarks), "", vRemarks + Chars.LF);
					pAttributeInErr = ?(pAttributeInErr = "", "Room", pAttributeInErr);
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(ReservationStatus) And (ReservationStatus.IsActive Or ReservationStatus.IsPreliminary) And Not ReservationStatus.IsCheckIn And 
		   ValueIsFilled(AccommodationTemplate) And Not ValueIsFilled(CreditCard) And 
		   ValueIsFilled(GuaranteeType) And GuaranteeType.PaymentCardDetailsRequired Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Необходимо указать данные платежной карты!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "Payment card details are required!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "Zahlungskartendaten sind erforderlich!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "GuaranteeType", pAttributeInErr);
		EndIf;
	EndIf;
	If ValueIsFilled(Guest) Then
		If Guest.DoNotCheckIn Then
			If Not cmCheckUserPermissions("HavePermissionToIgnoreBlackListLimitations") Then
				vHasErrors = True; 
				vMsgTextRu = vMsgTextRu + "У гостя установлен режим запрета поселения!" + Chars.LF;
				vMsgTextEn = vMsgTextEn + "Guest check-in is forbidden!" + Chars.LF;
				vMsgTextDe = vMsgTextDe + "У гостя установлен режим запрета поселения!" + Chars.LF;
				pAttributeInErr = ?(pAttributeInErr = "", "Guest", pAttributeInErr);
			EndIf;
		EndIf;
	EndIf;
	If Not ValueIsFilled(BoardPlace) Then
		If Not cmCheckUserPermissions("HavePermissionToSkipBoardPlaceSetting") And Not pDoNotCheckRests Then
			vBoardPlaces = cmGetBoardPlaces(Hotel);
			If vBoardPlaces.Count() > 0 Then
				vHasErrors = True; 
				vMsgTextRu = vMsgTextRu + "Нет прав на бронирование без указания места питания!" + Chars.LF;
				vMsgTextEn = vMsgTextEn + "You do not have rights to do booking with no board place setting!" + Chars.LF;
				vMsgTextDe = vMsgTextDe + "Es gibt kein Rechte auf Nahrung nicht in der Reservierung angeben!" + Chars.LF;
				pAttributeInErr = ?(pAttributeInErr = "", "BoardPlace", pAttributeInErr);
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(ClientType) And ClientType.CustomerIsMandatory And Not ValueIsFilled(Customer) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Заказчик> должен быть заполнен для типа клиента " + TrimAll(ClientType) + "!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Customer> attribute should be filled for client type " + TrimAll(ClientType) + "!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "Das Attribut <Firma> sollte für den Kundentyp ausgefüllt werden " + TrimAll(ClientType) + "!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Customer", pAttributeInErr);
	EndIf;
	If Not pDoNotCheckRests And ValueIsFilled(ReservationStatus) Then 
		vLastDocState = pmGetPreviousObjectState(CurrentSessionDate());
		If ReservationStatus.IsActive Then
			// Check rooms in quota availability
			If ValueIsFilled(RoomQuota) And ValueIsFilled(pPeriod.AccommodationType) And 
			   (pPeriod.AccommodationType.Type = Enums.AccomodationTypes.Beds Or pPeriod.AccommodationType.Type = Enums.AccomodationTypes.Room) Then
				If RoomQuota.CustomerOrContractChangeIsNotAllowed Then
					If RoomQuota.Customer <> Customer Or
					   RoomQuota.Contract <> Contract Then
						vHasErrors = True; 
						vMsgTextRu = vMsgTextRu + "Бронирование с указанием контрагента/договора отличных от них в выбранной квоте запрещено!" + Chars.LF;
						vMsgTextEn = vMsgTextEn + "It is not allowed to do reservation with customer/contract different from them in allotment choosen!" + Chars.LF;
						vMsgTextDe = vMsgTextDe + "Бронирование с указанием контрагента/договора отличных от них в выбранной квоте запрещено!" + Chars.LF;
						pAttributeInErr = ?(pAttributeInErr = "", "RoomQuota", pAttributeInErr);
					EndIf;
				EndIf;
				vRoomType = pPeriod.RoomType;
				If ValueIsFilled(RoomTypeUpgrade) And ValueIsFilled(RoomTypeUpgrade.BaseRoomType) And pPeriod.RoomType = RoomTypeUpgrade.BaseRoomType Then
					vRoomType = RoomTypeUpgrade;
				EndIf;
				If Not vHasErrors Then
					vMsgTextRu = ""; vMsgTextEn = ""; vMsgTextde = "";   
					vAccessibilityAttributesChanged = False;
					If vLastDocState = Undefined Then
						vAccessibilityAttributesChanged = True;
					ElsIf ReservationStatus <> vLastDocState.ReservationStatus And vLastDocState.ReservationStatus.IsActive = False Then	
						vAccessibilityAttributesChanged = True;	
					ElsIf vLastDocState.RoomQuota <> RoomQuota Then
						vAccessibilityAttributesChanged = True;
					ElsIf vLastDocState.CheckInDate <> CheckInDate Or vLastDocState.CheckOutDate <> CheckOutDate Or 
					      vLastDocState.RoomType <> RoomType Or vLastDocState.Room <> Room Or
					      vLastDocState.AccommodationType <> AccommodationType Or
					      vLastDocState.RoomQuantity <> RoomQuantity Or
						  ThereAreChangesInRoomRates(vLastDocState) Then
						vAccessibilityAttributesChanged = True;  
					EndIf;	
					If vAccessibilityAttributesChanged And Max(CurrentSessionDate(), pPeriod.CheckInDate) < pPeriod.CheckOutDate Then
						If Not cmCheckRoomQuotaAvailability(RoomQuota.Agent, RoomQuota.Customer, RoomQuota.Contract, RoomQuota, 
						                                    Hotel, vRoomType, pPeriod.Room, Ref, pIsPosted, True,
						                                    pPeriod.NumberOfRooms, pPeriod.NumberOfBeds, 
						                                    Max(CurrentSessionDate(), pPeriod.CheckInDate), pPeriod.CheckOutDate, 
						                                    vMsgTextRu, vMsgTextEn, vMsgTextDe, ?(pNoPermissionForOverbooking, False, Undefined)) Then
							vHasErrors = True; 
							pAttributeInErr = ?(pAttributeInErr = "", "CheckInDate", pAttributeInErr);
							pPeriod.NoRoomsInRoomQuota = True;
						ElsIf Not IsBlankString(vMsgTextRu) Or Not IsBlankString(vMsgTextEn) Or Not IsBlankString(vMsgTextDe) Then
							vWarning = NStr("ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';");
							If AdditionalProperties.Property("WarningMessage") Then
								AdditionalProperties.WarningMessage = AdditionalProperties.WarningMessage + ?(IsBlankString(AdditionalProperties.WarningMessage), "", Chars.LF) + vWarning;
							EndIf;
							pPeriod.NoRoomsInRoomQuota = True;
						EndIf;
						If (Not IsBlankString(vMsgTextRu) Or Not IsBlankString(vMsgTextEn) Or Not IsBlankString(vMsgTextDe)) And 
						   (pNoPermissionForOverbooking = Undefined Or 
						    TypeOf(pNoPermissionForOverbooking) = Type("Boolean") And Not pNoPermissionForOverbooking) And 
						   Not RoomQuota.OverbookingIsNotAllowed And Not RoomQuota.IsQuotaForRooms And RoomQuota.AllotmentBusinessType = Enums.AllotmentBusinessTypes.BusinessBlock Then
							AdditionalProperties.Insert("AddRoomsToAllotment", True);
							FillAllotmentBalances(pPeriod);
						EndIf;
						If Not vHasErrors Then
							If RoomQuota.IsForCheckInPeriods And pPeriod.CheckInDate = CheckInDate Then
								vMsgTextRu = ""; vMsgTextEn = ""; vMsgTextde = "";
								If Not cmCheckCheckInPeriods(Hotel, RoomQuota, CheckInDate, CheckOutDate) Then
									vHasErrors = True; 
									vMsgTextRu = vMsgTextRu + "Указанный срок проживания не попадает на границы заездов!" + Chars.LF;
									vMsgTextEn = vMsgTextEn + "Accommodation period specified is out from the check-in period dates!" + Chars.LF;
									vMsgTextDe = vMsgTextDe + "Указанный срок проживания не попадает на границы заездов!" + Chars.LF;
									pAttributeInErr = ?(pAttributeInErr = "", "CheckOutDate", pAttributeInErr);
								EndIf;
							EndIf;
						EndIf;
						If Not pPeriod.NoRoomsInRoomQuota And RoomQuota.DoWriteOff Then
							If Not vHasErrors Then
								vPeriodFrom = Max(CurrentSessionDate(), pPeriod.CheckInDate);
								vRHPeriodTo = cmMovePeriodToToReferenceHour(pPeriod.CheckInDate, pPeriod.RoomRate);
								If vPeriodFrom < vRHPeriodTo Then
									If Not cmCheckRoomAvailability(Hotel, Catalogs.RoomQuotas.EmptyRef(), pPeriod.RoomType, Catalogs.Rooms.EmptyRef(), Ref, pIsPosted, True,
									                               pPeriod.NumberOfPersons, pPeriod.NumberOfRooms, pPeriod.NumberOfBeds, pPeriod.NumberOfAdditionalBeds, 
									                               pPeriod.NumberOfBedsPerRoom, pPeriod.NumberOfPersonsPerRoom, 
																   vPeriodFrom, vRHPeriodTo,  
									                               vMsgTextRu, vMsgTextEn, vMsgTextDe, ?(pNoPermissionForOverbooking, False, Undefined), ?(pNoPermissionForOverbooking, False, Undefined)) Then
										vHasErrors = True; 
										pAttributeInErr = ?(pAttributeInErr = "", "CheckInDate", pAttributeInErr);
									ElsIf Not IsBlankString(vMsgTextRu) Or Not IsBlankString(vMsgTextEn) Or Not IsBlankString(vMsgTextDe) Then
										vWarning = NStr("ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';");
										If AdditionalProperties.Property("WarningMessage") Then
											AdditionalProperties.WarningMessage = AdditionalProperties.WarningMessage + ?(IsBlankString(AdditionalProperties.WarningMessage), "", Chars.LF) + vWarning;
										EndIf;
									EndIf;
								EndIf;
							EndIf;
							If Not vHasErrors Then
								vRHPeriodFrom = Max(CurrentSessionDate(), cmMovePeriodFromToReferenceHour(pPeriod.CheckOutDate, pPeriod.RoomRate));
								If pPeriod.CheckOutDate > vRHPeriodFrom Then
									If Not cmCheckRoomAvailability(Hotel, Catalogs.RoomQuotas.EmptyRef(), pPeriod.RoomType, Catalogs.Rooms.EmptyRef(), Ref, pIsPosted, True,
									                               pPeriod.NumberOfPersons, pPeriod.NumberOfRooms, pPeriod.NumberOfBeds, pPeriod.NumberOfAdditionalBeds, 
									                               pPeriod.NumberOfBedsPerRoom, pPeriod.NumberOfPersonsPerRoom, 
																   vRHPeriodFrom, pPeriod.CheckOutDate,  
									                               vMsgTextRu, vMsgTextEn, vMsgTextDe, ?(pNoPermissionForOverbooking, False, Undefined), ?(pNoPermissionForOverbooking, False, Undefined)) Then
										vHasErrors = True; 
										pAttributeInErr = ?(pAttributeInErr = "", "CheckOutDate", pAttributeInErr);
									ElsIf Not IsBlankString(vMsgTextRu) Or Not IsBlankString(vMsgTextEn) Or Not IsBlankString(vMsgTextDe) Then
										vWarning = NStr("ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';");
										If AdditionalProperties.Property("WarningMessage") Then
											AdditionalProperties.WarningMessage = AdditionalProperties.WarningMessage + ?(IsBlankString(AdditionalProperties.WarningMessage), "", Chars.LF) + vWarning;
										EndIf;
									EndIf;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			// Check rooms availability if room quota is not set and room is choosen
			If Not vHasErrors Then
				If Not ValueIsFilled(RoomQuota) Or ValueIsFilled(pPeriod.Room) Or ValueIsFilled(RoomQuota) And Not RoomQuota.DoWriteOff Then
					vMsgTextRu = ""; vMsgTextEn = ""; vMsgTextde = "";
					vAccessibilityAttributesChanged = False;
					If vLastDocState = Undefined Then
						vAccessibilityAttributesChanged = True;    
					ElsIf ReservationStatus <> vLastDocState.ReservationStatus And vLastDocState.ReservationStatus.IsActive = False Then	
						vAccessibilityAttributesChanged = True;	
					ElsIf vLastDocState.RoomQuota <> RoomQuota Then
						vAccessibilityAttributesChanged = True;
					ElsIf vLastDocState.CheckInDate <> CheckInDate Or vLastDocState.CheckOutDate <> CheckOutDate Or 
					      vLastDocState.RoomType <> RoomType Or vLastDocState.Room <> Room Or
					      vLastDocState.AccommodationType <> AccommodationType Or 
					      vLastDocState.RoomQuantity <> RoomQuantity Or 
					      ThereAreChangesInRoomRates(vLastDocState) Then
						vAccessibilityAttributesChanged = True;  
					EndIf;	
					If vAccessibilityAttributesChanged And Max(CurrentSessionDate(), pPeriod.CheckInDate) < pPeriod.CheckOutDate Then
						If Not cmCheckRoomAvailability(Hotel, RoomQuota, pPeriod.RoomType, pPeriod.Room, Ref, pIsPosted, ?(pDoCheckRests, True, IsChangeOfAccommodationConditions(vLastDocState)),
						                               pPeriod.NumberOfPersons, pPeriod.NumberOfRooms, pPeriod.NumberOfBeds, pPeriod.NumberOfAdditionalBeds, 
						                               pPeriod.NumberOfBedsPerRoom, pPeriod.NumberOfPersonsPerRoom, Max(CurrentSessionDate(), pPeriod.CheckInDate), pPeriod.CheckOutDate, 
						                               vMsgTextRu, vMsgTextEn, vMsgTextDe, ?(pNoPermissionForOverbooking, False, Undefined), ?(pNoPermissionForOverbooking, False, Undefined)) Then
							vHasErrors = True; 
							pAttributeInErr = ?(pAttributeInErr = "", "CheckInDate", pAttributeInErr);
						ElsIf Not IsBlankString(vMsgTextRu) Or Not IsBlankString(vMsgTextEn) Or Not IsBlankString(vMsgTextDe) Then
							vWarning = NStr("ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';");
							If AdditionalProperties.Property("WarningMessage") Then
								AdditionalProperties.WarningMessage = AdditionalProperties.WarningMessage + ?(IsBlankString(AdditionalProperties.WarningMessage), "", Chars.LF) + vWarning;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;   
		// Check a rate period available    
		If ValueIsFilled(RoomRate) And (BegOfDay(CheckInDate) < BegOfDay(RoomRate.DateValidFrom) Or ValueIsFilled(RoomRate.DateValidTo) 
			And BegOfDay(RoomRate.DateValidTo) < BegOfDay(CheckOutDate)) Then              
	  			vHasErrors = True; 
				vMsgTextRu = vMsgTextRu + "Выбранный тариф не действует на периоде проживания брони!" + Chars.LF;
				vMsgTextEn = vMsgTextEn + "Room rate choosen is not valid for the reservation period!" + Chars.LF;
				vMsgTextDe = vMsgTextDe + "Der gewählte Tarif gilt nicht für die Dauer der Buchung!" + Chars.LF;
				pAttributeInErr = ?(pAttributeInErr = "", "RoomRate", pAttributeInErr);
		EndIf;
		// Get and check room rate restrictions
		vRoomRateHasChanged = False;
		If vLastDocState <> Undefined Then
			If RoomRate <> vLastDocState.RoomRate Or 
			   BegOfDay(CheckInDate) <> BegOfDay(vLastDocState.CheckInDate) Or 
			   BegOfDay(CheckOutDate) <> BegOfDay(vLastDocState.CheckOutDate) Or 
			   RoomType <> vLastDocState.RoomType Then
				vRoomRateHasChanged = True;
			EndIf;
		Else
			vRoomRateHasChanged = True;
		EndIf;    
		// Check rate LOS
		vRestrStruct = Undefined;  
		vIgnoreLOS = cmCheckUserPermissions("HavePermissionToIgnoreLOS");
		// Fill effective period
		vCheckInDate = CheckInDate;
		vCheckOutDate = CheckOutDate;
		vReservationCheckInDate = vCheckInDate;
		vReservationCheckOutDate = vCheckOutDate;
		
		vRestrStruct = RoomRate.GetObject().pmGetRoomRateRestrictions(vCheckInDate, vCheckOutDate, ?(ValueIsFilled(RoomTypeUpgrade), RoomTypeUpgrade, RoomType), True, PriceCalculationDate);   
		If vRestrStruct.MLOS > 0 And Duration < vRestrStruct.MLOS And RoomRate.MLOSIsBlocking Then
			vHasErrors = Not vIgnoreLOS; 
			vMsgTextRu = vMsgTextRu + "Минимальная продолжительность проживания " + vRestrStruct.MLOS + " дней!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "Minimum length of stay is " + vRestrStruct.MLOS + "!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "Mindestaufenthaltsdauer beträgt " + vRestrStruct.MLOS + " Tage!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "CheckInDate", pAttributeInErr);
		EndIf;
		If vRestrStruct.MaxLOS > 0 And Duration > vRestrStruct.MaxLOS Then
			vHasErrors = Not vIgnoreLOS; 
			vMsgTextRu = vMsgTextRu + "Максимальная продолжительность проживания " + vRestrStruct.MaxLOS + " дней!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "Maximum length of stay is " + vRestrStruct.MaxLOS + "!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "Maximaleaufenthaltsdauer beträgt " + vRestrStruct.MaxLOS + " Tage!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "CheckOutDate", pAttributeInErr);
		EndIf;
		If vRestrStruct.MinDaysBeforeCheckIn > 0 And ValueIsFilled(AccommodationType) And (AccommodationType.Type = Enums.AccomodationTypes.Room Or AccommodationType.Type = Enums.AccomodationTypes.Beds) Then
			vDate = GuestGroup.CreateDate;
			vDaysBeforeCheckIn = Int((BegOfDay(CheckInDate) - BegOfDay(vDate))/(24*3600));
			If vDaysBeforeCheckIn < vRestrStruct.MinDaysBeforeCheckIn Then
				vHasErrors = Not vIgnoreLOS; 
				vMsgTextRu = vMsgTextRu + "Минимальное кол-во дней от даты бронирования до даты заезда " + vRestrStruct.MinDaysBeforeCheckIn + "!" + Chars.LF;
				vMsgTextEn = vMsgTextEn + "Minimum days between booking and check-in dates is " + vRestrStruct.MinDaysBeforeCheckIn + "!" + Chars.LF;
				vMsgTextDe = vMsgTextDe + "Mindest Tage zwischen Buchung und Check-in Daten ist " + vRestrStruct.MinDaysBeforeCheckIn + "!" + Chars.LF;
				pAttributeInErr = ?(pAttributeInErr = "", "CheckInDate", pAttributeInErr);
			EndIf;
		EndIf;
		If vRestrStruct.MaxDaysBeforeCheckIn > 0 And ValueIsFilled(AccommodationType) And (AccommodationType.Type = Enums.AccomodationTypes.Room Or AccommodationType.Type = Enums.AccomodationTypes.Beds) Then
			vDate = GuestGroup.CreateDate;
			vDaysBeforeCheckIn = Int((BegOfDay(CheckInDate) - BegOfDay(vDate)) / (24 * 3600));
			If vDaysBeforeCheckIn > vRestrStruct.MaxDaysBeforeCheckIn Then
				vHasErrors = Not vIgnoreLOS; 
				vMsgTextRu = vMsgTextRu + "Максимальное кол-во дней от даты бронирования до даты заезда " + vRestrStruct.MaxDaysBeforeCheckIn + "!" + Chars.LF;
				vMsgTextEn = vMsgTextEn + "Maximum days between booking and check-in dates is " + vRestrStruct.MaxDaysBeforeCheckIn + "!" + Chars.LF;
				vMsgTextDe = vMsgTextDe + "Maximale Tage zwischen Buchung und Check-in Daten ist " + vRestrStruct.MaxDaysBeforeCheckIn + "!" + Chars.LF;
				pAttributeInErr = ?(pAttributeInErr = "", "CheckInDate", pAttributeInErr);
			EndIf;
		EndIf; 
		
		If (Not Posted Or vRoomRateHasChanged) And (ReservationStatus.IsActive Or ReservationStatus.IsPreliminary Or ReservationStatus.IsInWaitingList) Then
			If ValueIsFilled(RoomRate) And BegOfDay(CheckInDate) >= BegOfDay(CurrentSessionDate()) And Not ReservationStatus.IsCheckIn And Not ReservationStatus.IsNoShow Then   
				If vRestrStruct.StopSale Then
					If Not cmCheckUserPermissions("HavePermissionToIgnoreStopSaleLimitations") Then
						vHasErrors = True;
					Else
						vHasErrors = False;
					EndIf;
					vMsgTextRu = vMsgTextRu + "Продажи по тарифу " + TrimAll(RoomRate) + " остановлены на периоде с " + Format(CheckInDate, "DF=dd.MM.yyyy") + " по " + Format(CheckOutDate, "DF=dd.MM.yyyy") + " в ограничениях тарифа (Stop Sale включен)!" + Chars.LF;
					vMsgTextEn = vMsgTextEn + "Room rate " + TrimAll(RoomRate) + " could not be used for the given period " + Format(CheckInDate, "DF=dd.MM.yyyy") + " - " + Format(CheckOutDate, "DF=dd.MM.yyyy") + " (room rate restriction Stop Sales is turned on)!" + Chars.LF;
					vMsgTextDe = vMsgTextDe + "Tariff " + TrimAll(RoomRate) + " ist geschlossen (Tariff Einschränkung Stop Sale ist auf), periode " + Format(CheckInDate, "DF=dd.MM.yyyy") + " - " + Format(CheckOutDate, "DF=dd.MM.yyyy") + "!" + Chars.LF;
					pAttributeInErr = ?(pAttributeInErr = "", "RoomRate", pAttributeInErr);
				EndIf;
				If vRestrStruct.CTA Then
					vHasErrors = True; 
					vMsgTextRu = vMsgTextRu + "Заезд в выбранную дату " + Format(CheckInDate, "DF=dd.MM.yyyy") + " запрещен в ограничениях указанных у тарифа (CTA включен)!" + Chars.LF;
					vMsgTextEn = vMsgTextEn + "Check-in is closed (CTA is On) for the given check-in date " + Format(CheckInDate, "DF=dd.MM.yyyy") + "!" + Chars.LF;
					vMsgTextDe = vMsgTextDe + "Check-in ist für den Check-in-Datum " + Format(CheckInDate, "DF=dd.MM.yyyy") + " geschlossen (CTA is On)!" + Chars.LF;
					pAttributeInErr = ?(pAttributeInErr = "", "CheckInDate", pAttributeInErr);
				EndIf;
				If vRestrStruct.CTD Then
					vHasErrors = True; 
					vMsgTextRu = vMsgTextRu + "Выезд в выбранную дату " + Format(CheckOutDate, "DF=dd.MM.yyyy") + " запрещен в ограничениях указанных у тарифа (CTD включен)!" + Chars.LF;
					vMsgTextEn = vMsgTextEn + "Check-out is closed (CTD is On) for the given check-out date " + Format(CheckOutDate, "DF=dd.MM.yyyy") + "!" + Chars.LF;
					vMsgTextDe = vMsgTextDe + "Check-out ist für den Check-out-Datum " + Format(CheckOutDate, "DF=dd.MM.yyyy") + " geschlossen (CTD is On)!" + Chars.LF;
					pAttributeInErr = ?(pAttributeInErr = "", "CheckOutDate", pAttributeInErr);
				EndIf;    
			EndIf;
		EndIf;
	EndIf;
	vDoNotCloseMode = Undefined;
	AdditionalProperties.Property("DoNotCloseMode", vDoNotCloseMode);
	If vDoNotCloseMode = Undefined Then
		vDoNotCloseMode = False;
	EndIf;
	If Not vDoNotCloseMode And 
	   Not ValueIsFilled(Customer) And 
	   Not ValueIsFilled(Contract) And 
	   Not ValueIsFilled(Agent) And 
	   IsBlankString(Remarks) And 
	   IsBlankString(ContactPerson) And 
	   Not ValueIsFilled(Guest) And 
	   ValueIsFilled(GuestGroup) And 
	   IsBlankString(GuestGroup.Description) And 
	   Not ValueIsFilled(GuestGroup.Client) And 
	   Not ValueIsFilled(GuestGroup.Customer) And
	 ((ReservationStatus.IsActive Or ReservationStatus.IsPreliminary) And Not ReservationStatus.IsCheckIn) Then
		If ValueIsFilled(AccommodationType) And 
		   AccommodationType.Type <> Enums.AccomodationTypes.AdditionalBed And 
		   AccommodationType.Type <> Enums.AccomodationTypes.Together Then
			If Not cmCheckUserPermissions("HavePermissionToCreateReservationsWithoutContactClientAndCustomerData") Then
				vHasErrors = True; 
				vMsgTextRu = vMsgTextRu + "В брони не указано кто бронирует! Не указаны контрагент, договор, контактное лицо, гость, агент, примечания." + Chars.LF;
				vMsgTextEn = vMsgTextEn + "Customer, contract, contact person, agent, guest and remarks are empty!" + Chars.LF;
				vMsgTextDe = vMsgTextDe + "В брони не указано кто бронирует! Не указаны контрагент, договор, контактное лицо, гость, агент, примечания." + Chars.LF;
				pAttributeInErr = ?(pAttributeInErr = "", "Guest", pAttributeInErr);
			EndIf;
		EndIf;
	EndIf;
	If Not vDoNotCloseMode And 
	   ValueIsFilled(Customer) And 
	   IsBlankString(Customer.Phone) And 
	   IsBlankString(Customer.Fax) And 
	   IsBlankString(Customer.EMail) And 
	   IsBlankString(Customer.ContactPerson) And 
	   Customer.ContactPersons.Count() = 0 And
	 ((ReservationStatus.IsActive Or ReservationStatus.IsPreliminary) And Not ReservationStatus.IsCheckIn) Then
		If ValueIsFilled(AccommodationType) And 
		   AccommodationType.Type <> Enums.AccomodationTypes.AdditionalBed And 
		   AccommodationType.Type <> Enums.AccomodationTypes.Together Then
			If Not cmCheckUserPermissions("HavePermissionToDoBookingWithoutCustomerContactData") Then
				vHasErrors = True; 
				vMsgTextRu = vMsgTextRu + "В карточке заказчика не указана контактная информация! Нет прав бронировать без указания у заказчика хотя бы одного из полей: телефон, факс, e-mail, контактное лицо." + Chars.LF;
				vMsgTextEn = vMsgTextEn + "Customer do not have contact data! You do not have rights to do reservation without customer phone or fax or e-mail or contact person data entered!" + Chars.LF;
				vMsgTextDe = vMsgTextDe + "В карточке заказчика не указана контактная информация! Нет прав бронировать без указания у заказчика хотя бы одного из полей: телефон, факс, e-mail, контактное лицо." + Chars.LF;
				pAttributeInErr = ?(pAttributeInErr = "", "Customer", pAttributeInErr);
			EndIf;
		EndIf;
	EndIf;
	// Check that there is no change room attributes in the period selected
	If ValueIsFilled(pPeriod.Room) And ValueIsFilled(pPeriod.CheckInDate) And ValueIsFilled(pPeriod.CheckOutDate) Then
		If TypeOf(pPeriod) <> Type("DocumentObject.Reservation") Then
			vChangeRoomAttrs = cmGetChangeRoomAttributes(pPeriod.Room, pPeriod.CheckInDate, pPeriod.CheckOutDate);
			If vChangeRoomAttrs.Count() > 0 Then
				vHasErrors = True; 
				vMsgTextRu = vMsgTextRu + "В плане брони не должно быть не учтенных изменений параметров выбранного номера!" + Chars.LF;
				vMsgTextEn = vMsgTextEn + "There should be no missed change room attributes in the reservation plan!" + Chars.LF;
				vMsgTextDe = vMsgTextDe + "В плане брони не должно быть не учтенных изменений параметров выбранного номера!" + Chars.LF;
				pAttributeInErr = ?(pAttributeInErr = "", "Room", pAttributeInErr);
			EndIf;
		EndIf;
	EndIf;
	// Check charging rules
	For Each vCRRow In ChargingRules Do
		If vCRRow.ChargingRule = Enums.ChargingRuleTypes.AllButOne And Not ValueIsFilled(vCRRow.ChargingRuleValue) Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "В правилах начисления в строке " + Format(vCRRow.LineNumber, "ND=4; NFD=0; NG=") + " не указана услуга!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "Service is not filled in the charging rules row number " + Format(vCRRow.LineNumber, "ND=4; NFD=0; NG=") + "!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "В правилах начисления в строке " + Format(vCRRow.LineNumber, "ND=4; NFD=0; NG=") + " не указана услуга!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "ChargingRules", pAttributeInErr);
		ElsIf vCRRow.ChargingRule = Enums.ChargingRuleTypes.InServiceGroup And Not ValueIsFilled(vCRRow.ChargingRuleValue) Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "В правилах начисления в строке " + Format(vCRRow.LineNumber, "ND=4; NFD=0; NG=") + " не указан набор услуг!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "Service group is not filled in the charging rules row number " + Format(vCRRow.LineNumber, "ND=4; NFD=0; NG=") + "!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "В правилах начисления в строке " + Format(vCRRow.LineNumber, "ND=4; NFD=0; NG=") + " не указан набор услуг!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "ChargingRules", pAttributeInErr);
		ElsIf vCRRow.ChargingRule = Enums.ChargingRuleTypes.One And Not ValueIsFilled(vCRRow.ChargingRuleValue) Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "В правилах начисления в строке " + Format(vCRRow.LineNumber, "ND=4; NFD=0; NG=") + " не указана услуга!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "Service is not filled in the charging rules row number " + Format(vCRRow.LineNumber, "ND=4; NFD=0; NG=") + "!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "В правилах начисления в строке " + Format(vCRRow.LineNumber, "ND=4; NFD=0; NG=") + " не указана услуга!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "ChargingRules", pAttributeInErr);
		ElsIf vCRRow.ChargingRule = Enums.ChargingRuleTypes.NotInServiceGroup And Not ValueIsFilled(vCRRow.ChargingRuleValue) Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "В правилах начисления в строке " + Format(vCRRow.LineNumber, "ND=4; NFD=0; NG=") + " не указан набор услуг!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "Service group is not filled in the charging rules row number " + Format(vCRRow.LineNumber, "ND=4; NFD=0; NG=") + "!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "В правилах начисления в строке " + Format(vCRRow.LineNumber, "ND=4; NFD=0; NG=") + " не указан набор услуг!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "ChargingRules", pAttributeInErr);
		EndIf;
		If Not ValueIsFilled(vCRRow.Owner) And ValueIsFilled(vCRRow.ChargingFolio) And ValueIsFilled(vCRRow.ChargingFolio.PaymentMethod) And vCRRow.ChargingFolio.PaymentMethod.IsByBankTransfer Then
			If ValueIsFilled(Hotel) And ValueIsFilled(Hotel.IndividualsCustomer) Then
				vCRRow.Owner = Hotel.IndividualsCustomer;
			Else
				vHasErrors = True; 
				vMsgTextRu = vMsgTextRu + "В правилах начисления в строке " + Format(vCRRow.LineNumber, "ND=4; NFD=0; NG=") + " установлен способ оплаты контрагентом, а контрагент не указан!" + Chars.LF;
				vMsgTextEn = vMsgTextEn + "Customer is not choosen in the charging rule owner in the row number " + Format(vCRRow.LineNumber, "ND=4; NFD=0; NG=") + " but payment method choosen states that folio is paid by customer!" + Chars.LF;
				vMsgTextDe = vMsgTextDe + "В правилах начисления в строке " + Format(vCRRow.LineNumber, "ND=4; NFD=0; NG=") + " установлен способ оплаты контрагентом, а контрагент не указан!" + Chars.LF;
				pAttributeInErr = ?(pAttributeInErr = "", "ChargingRules", pAttributeInErr);
			EndIf;
		EndIf;
	EndDo;
	// Check rights to create group debt
	If ValueIsFilled(Customer) And ValueIsFilled(PlannedPaymentMethod) And PlannedPaymentMethod.IsByBankTransfer And 
	   ValueIsFilled(ReservationStatus) And ReservationStatus.IsActive Then
		If Not pDoNotCheckRests And cmCheckUserPermissions("NoDebtAllowedForGroupInhouseGuests") And ValueIsFilled(GuestGroup) Then
			vGroupObj = GuestGroup.GetObject();
			vGuestGroupBalance = 0;
			vSales = vGroupObj.pmGetSalesTotals();
			vSales.GroupBy("Currency", "Sales, SalesForecast, ExpectedSales");
			For Each vSalesRow In vSales Do
				vSalesInBaseCurrency = cmConvertCurrencies(vSalesRow.Sales + vSalesRow.SalesForecast, vSalesRow.Currency, , Hotel.BaseCurrency, , ExchangeRateDate, Hotel);
				vGuestGroupBalance = vGuestGroupBalance + vSalesInBaseCurrency;
			EndDo;
			vPayments = vGroupObj.pmGetPaymentsTotals();
			vPayments.GroupBy("Currency", "Sum");
			For Each vPaymentsRow In vPayments Do
				vGuestGroupBalance = vGuestGroupBalance - cmConvertCurrencies(vPaymentsRow.Sum, vPaymentsRow.Currency, , Hotel.BaseCurrency, , ExchangeRateDate, Hotel);
			EndDo;
			If vGuestGroupBalance > 0 Then
				vHasErrors = True; 
				vMsgTextRu = vMsgTextRu + "После сохранения изменений по этому гостю по группе будет долг!" + Chars.LF;
				vMsgTextEn = vMsgTextEn + "After the changes are saved for this guest, the group will have a debt!" + Chars.LF;
				vMsgTextDe = vMsgTextDe + "Nachdem die Änderungen für diesen Gast gespeichert wurden, hat die Gruppe eine Verschuldung!" + Chars.LF;
				pAttributeInErr = ?(pAttributeInErr = "", "CheckOutDate", pAttributeInErr);
			EndIf;
		EndIf;
	EndIf;
	If vHasErrors Then
		pMessage = "ru = '" + TrimAll(vMsgTextRu) + "';" + "en = '" + TrimAll(vMsgTextEn) + "';" + "de = '" + TrimAll(vMsgTextDe) + "';";
	EndIf;
	Return vHasErrors;
EndFunction //  pmCheckDocumentAttributes

// -----------------------------------------------------------------------------
Procedure FillAllotmentBalances(pPeriod)
	If Not AdditionalProperties.Property("AllotmentBalances") Or 
	   AdditionalProperties.Property("AllotmentBalances") And TypeOf(AdditionalProperties.AllotmentBalances) <> Type("Array") Then
		AdditionalProperties.Insert("AllotmentBalances", New Array());
	EndIf;
	
	vDays = New ValueTable();
	vDays.Columns.Add("PeriodFrom", cmGetDateTimeTypeDescription());
	vDays.Columns.Add("PeriodTo", cmGetDateTimeTypeDescription());
	vCurDay = cm0SecondShift(cmMovePeriodFromToReferenceHour(pPeriod.CheckInDate, pPeriod.RoomRate));
	While vCurDay < pPeriod.CheckOutDate Do
		vDay = vDays.Add();
		vDay.PeriodFrom = vCurDay;
		vDay.PeriodTo = vCurDay + 24 * 3600;
		vCurDay = vCurDay + 24 * 3600;
	EndDo;
	
	// Build chain of periods with the same number of rooms to write off
	vCurRoomsRemains = Undefined;
	vPeriodsChainRow = Undefined;
	vPeriodsChain = New ValueTable();
	vPeriodsChain.Columns.Add("PeriodFrom", cmGetDateTimeTypeDescription());
	vPeriodsChain.Columns.Add("PeriodTo", cmGetDateTimeTypeDescription());
	vPeriodsChain.Columns.Add("RoomsRemains", cmGetNumberTypeDescription(6, 0));
	For Each vDaysRow In vDays Do
		vRemains = cmCalculateRoomQuotaResources(pPeriod.RoomQuota, pPeriod.RoomType.Owner, pPeriod.RoomType, Undefined, vDaysRow.PeriodFrom, vDaysRow.PeriodTo);
		vRoomsRemains = 0;
		If vRemains <> Undefined And vRemains.Count() > 0 Then
			vRoomsRemains = vRemains.Get(0).RoomsRemains;
		EndIf;
		If vCurRoomsRemains <> vRoomsRemains Then
			If vPeriodsChainRow <> Undefined Then
				vPeriodsChainRow.PeriodTo = vDaysRow.PeriodFrom;
			EndIf;
			vPeriodsChainRow = vPeriodsChain.Add();
			vPeriodsChainRow.PeriodFrom = vDaysRow.PeriodFrom;
			vPeriodsChainRow.RoomsRemains = vRoomsRemains;
			
			vCurRoomsRemains = vRoomsRemains;
		EndIf;
	EndDo;
	If vPeriodsChainRow <> Undefined Then
		vPeriodsChainRow.PeriodTo = vDaysRow.PeriodTo;
	EndIf;
	
	// Fill additional properties attribute
	For Each vPeriodsChainRow In vPeriodsChain Do
		If vPeriodsChainRow.RoomsRemains >= 0 Then
			Continue;
		EndIf;
		
		// Search for the existing row with such parameters
		vRowsUpdated = False;
		i = 0;
		While i < AdditionalProperties.AllotmentBalances.Count() Do
			vBalancesStruct = AdditionalProperties.AllotmentBalances.Get(i);
			If vBalancesStruct.RoomQuota = pPeriod.RoomQuota And vBalancesStruct.RoomType = pPeriod.RoomType Then
				vSavPeriodFrom = vBalancesStruct.PeriodFrom;
				vSavPeriodTo = vBalancesStruct.PeriodTo;
				vSavRoomsRemains = vBalancesStruct.RoomsRemains;

				If vPeriodsChainRow.PeriodFrom < vBalancesStruct.PeriodFrom And vPeriodsChainRow.PeriodTo > vBalancesStruct.PeriodFrom Then
					vRowsUpdated = True;

					AdditionalProperties.AllotmentBalances.Insert(i, New Structure("RoomQuota, RoomRate, RoomType, PeriodFrom, PeriodTo, RoomsRemains", 
					                                                               pPeriod.RoomQuota, pPeriod.RoomRate, pPeriod.RoomType, vPeriodsChainRow.PeriodFrom, vBalancesStruct.PeriodFrom, vPeriodsChainRow.RoomsRemains));
					i = i + 1;

					vBalancesStruct.PeriodTo = vPeriodsChainRow.PeriodTo;
					vBalancesStruct.RoomsRemains = vPeriodsChainRow.RoomsRemains;
					
					If vPeriodsChainRow.PeriodTo < vSavPeriodTo Then
						AdditionalProperties.AllotmentBalances.Insert(i + 1, New Structure("RoomQuota, RoomRate, RoomType, PeriodFrom, PeriodTo, RoomsRemains", 
						                                                                   pPeriod.RoomQuota, pPeriod.RoomRate, pPeriod.RoomType, vPeriodsChainRow.PeriodTo, vSavPeriodTo, vSavRoomsRemains));
						i = i + 1;
					EndIf;
				ElsIf vPeriodsChainRow.PeriodFrom >= vBalancesStruct.PeriodFrom And vPeriodsChainRow.PeriodFrom < vBalancesStruct.PeriodTo Then
					vRowsUpdated = True;
					
					If vPeriodsChainRow.PeriodFrom > vBalancesStruct.PeriodFrom Then
						vBalancesStruct.PeriodTo = vPeriodsChainRow.PeriodFrom;
						
						If vPeriodsChainRow.PeriodTo < vSavPeriodTo Then
							AdditionalProperties.AllotmentBalances.Insert(i + 1, New Structure("RoomQuota, RoomRate, RoomType, PeriodFrom, PeriodTo, RoomsRemains", 
							                                                                   pPeriod.RoomQuota, pPeriod.RoomRate, pPeriod.RoomType, vPeriodsChainRow.PeriodFrom, vPeriodsChainRow.PeriodTo, vPeriodsChainRow.RoomsRemains));
							i = i + 1;

							AdditionalProperties.AllotmentBalances.Insert(i + 1, New Structure("RoomQuota, RoomRate, RoomType, PeriodFrom, PeriodTo, RoomsRemains", 
							                                                                   pPeriod.RoomQuota, pPeriod.RoomRate, pPeriod.RoomType, vPeriodsChainRow.PeriodTo, vSavPeriodTo, vSavRoomsRemains));
							i = i + 1;
						Else
							AdditionalProperties.AllotmentBalances.Insert(i + 1, New Structure("RoomQuota, RoomRate, RoomType, PeriodFrom, PeriodTo, RoomsRemains", 
							                                                                   pPeriod.RoomQuota, pPeriod.RoomRate, pPeriod.RoomType, vPeriodsChainRow.PeriodFrom, vPeriodsChainRow.PeriodTo, vPeriodsChainRow.RoomsRemains));
							i = i + 1;
						EndIf;
					Else
						If vPeriodsChainRow.PeriodTo < vSavPeriodTo Then
							vBalancesStruct.PeriodTo = vPeriodsChainRow.PeriodTo;
							vBalancesStruct.RoomsRemains = vPeriodsChainRow.RoomsRemains;

							AdditionalProperties.AllotmentBalances.Insert(i + 1, New Structure("RoomQuota, RoomRate, RoomType, PeriodFrom, PeriodTo, RoomsRemains", 
							                                                                   pPeriod.RoomQuota, pPeriod.RoomRate, pPeriod.RoomType, vPeriodsChainRow.PeriodTo, vSavPeriodTo, vSavRoomsRemains));
							i = i + 1;
						Else
							vBalancesStruct.PeriodTo = vPeriodsChainRow.PeriodTo;
							vBalancesStruct.RoomsRemains = vPeriodsChainRow.RoomsRemains;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			
			If vRowsUpdated Then
				Break;
			EndIf;
			i = i + 1;
		EndDo;
				
		If Not vRowsUpdated Then
			AdditionalProperties.AllotmentBalances.Add(New Structure("RoomQuota, RoomRate, RoomType, PeriodFrom, PeriodTo, RoomsRemains", 
			                                                         pPeriod.RoomQuota, pPeriod.RoomRate, pPeriod.RoomType, vPeriodsChainRow.PeriodFrom, vPeriodsChainRow.PeriodTo, vPeriodsChainRow.RoomsRemains));
		EndIf;
	EndDo;
EndProcedure // FillAllotmentBalances

// -----------------------------------------------------------------------------
Procedure pmInitializePeriod() Export
	vCoeff = 1;
	If cmCheckUserPermissions("UseCurrentDateAsDefaultReservationCheckInDate") Then
		vCoeff = 0;
	EndIf;
	If ValueIsFilled(Hotel) And ValueIsFilled(RoomRate) Then
		If Duration = 0 Then
			Duration = ?(RoomRate.DefaultDuration = 0, ?(ValueIsFilled(Hotel) And Hotel.Duration <> 0, Hotel.Duration, 1), RoomRate.DefaultDuration);
		EndIf;
		vRRPer = ?(RoomRate.PeriodInHours = 0, 24, RoomRate.PeriodInHours);
		vRRRH = RoomRate.ReferenceHour;
		vDefaultCheckInTime = RoomRate.DefaultCheckInTime;
		vDefaultCheckOutTime = RoomRate.DefaultCheckOutTime;
		If Not ValueIsFilled(CheckInDate) Then
			If ValueIsFilled(vDefaultCheckInTime) Or ValueIsFilled(vDefaultCheckOutTime) Then
				If RoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour Then
					CheckInDate = Date(Year(Date), Month(Date), Day(Date), 
					                   Hour(vDefaultCheckInTime), Minute(vDefaultCheckInTime), 1) + 
					              vCoeff*vRRPer*3600; // + 1 period of room rate
				ElsIf RoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByDays Then
					CheckInDate = Date(Year(Date), Month(Date), Day(Date), 
					                   Hour(vDefaultCheckInTime), Minute(vDefaultCheckInTime), 1) + 
					              vCoeff*vRRPer*3600; // + 1 period of room rate
				ElsIf RoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByNights Then
					CheckInDate = Date(Year(Date), Month(Date), Day(Date), 
					                   Hour(vDefaultCheckInTime), Minute(vDefaultCheckInTime), 1) + 
					              vCoeff*vRRPer*3600; // + 1 period of room rate
				Else
					CheckInDate = (Date + 1) + 
					              vCoeff*vRRPer*3600; // + 1 period of room rate
				EndIf;
			Else
				If RoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour Then
					CheckInDate = Date(Year(Date), Month(Date), Day(Date), 
					                   Hour(vRRRH), Minute(vRRRH), 1) + 
					              vCoeff*vRRPer*3600; // + 1 period of room rate
				ElsIf RoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByDays Then
					CheckInDate = Date(Year(Date), Month(Date), Day(Date), 
					                   8, 0, 1) + 
					              vCoeff*vRRPer*3600; // + 1 period of room rate
				ElsIf RoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByNights Then
					CheckInDate = Date(Year(Date), Month(Date), Day(Date), 
					                   8, 0, 1) + 
					              vCoeff*vRRPer*3600; // + 1 period of room rate
				Else
					CheckInDate = (Date + 1) + 
					              vCoeff*vRRPer*3600; // + 1 period of room rate
				EndIf;
			EndIf;
		EndIf;
		If Not ValueIsFilled(CheckOutDate) Then
			CheckOutDate = cmCalculateCheckOutDate(RoomRate, CheckInDate, Duration);
		EndIf;
	EndIf;
EndProcedure // pmInitializePeriod

// -----------------------------------------------------------------------------
//  Calculates and returns duration for giving check in and check out dates
// 
// Returns:
//  Number - Duration
//
Function pmCalculateDuration() Export
	Return cmCalculateDuration(RoomRate, CheckInDate, CheckOutDate);
EndFunction //  pmCalculateDuration

// -----------------------------------------------------------------------------
//  Calculates and returns check out date based on giving duration and check in date
// 
// Returns:
//  Date - Check out date
//
Function pmCalculateCheckOutDate() Export
	vCheckOutDate = CheckOutDate;
	If ValueIsFilled(RoomRate) And
	   ValueIsFilled(CheckInDate) Then
		vCheckOutDate = cmCalculateCheckOutDate(RoomRate, CheckInDate, Duration);
	EndIf;
	Return vCheckOutDate;
EndFunction //  pmCalculateCheckOutDate

// -----------------------------------------------------------------------------
Procedure pmFillAuthorAndDate() Export
	Date = CurrentSessionDate();
	Author = SessionParameters.CurrentUser;
EndProcedure //  pmFillAuthorAndDate

// -----------------------------------------------------------------------------
Procedure pmCreateGuestGroup(pIsProbe = False, pGuestGroup = Undefined) Export
	If ValueIsFilled(Hotel) Then
		If Not Hotel.AssignReservationGuestGroupsManually Then
			vGuestGroupFolder = Hotel.GetObject().pmGetGuestGroupFolder();
			vGuestGroupRef = Undefined;
			If pIsProbe Then
				vGuestGroupRef = Catalogs.GuestGroups.FindByCode(1, False, vGuestGroupFolder, Hotel);
			EndIf;
			If Not ValueIsFilled(vGuestGroupRef) Then
				vGuestGroupObj = Catalogs.GuestGroups.CreateItem();
			Else
				vGuestGroupObj = vGuestGroupRef.GetObject();
				vGuestGroupObj.Read();
			EndIf;
			vGuestGroupObj.Owner = Hotel;
			If ValueIsFilled(vGuestGroupFolder) Then
				vGuestGroupObj.Parent = vGuestGroupFolder;
				If pIsProbe Then
					vGuestGroupObj.Code = 1;
				Else
					vGuestGroupObj.SetNewCode();
				EndIf;
			Else
				If pIsProbe Then
					vGuestGroupObj.Code = 1;
				EndIf;			
			EndIf;  
			// Fill group type and room quotas
			If ValueIsFilled(pGuestGroup) Then
				vGuestGroupObj.GroupType = pGuestGroup.GroupType;
				vGuestGroupObj.Allotment = pGuestGroup.Allotment;
			EndIf;	
			vGuestGroupObj.OneCustomerPerGuestGroup = Hotel.OneCustomerPerGuestGroup;
			vGuestGroupObj.Write();
			// Fill document attribute
			GuestGroup = vGuestGroupObj.Ref;
		EndIf;
	EndIf;
EndProcedure //  pmCreateGuestGroup

// -----------------------------------------------------------------------------
Procedure pmCreateFolios(pPaymentMethod = Undefined) Export
	vChargingRules = Undefined;
	If ValueIsFilled(Customer) Then
		vParent = Customer.Parent;
		While ValueIsFilled(vParent) Do
			If vParent.ChargingRules.Count() > 0 Then
				vChargingRules = vParent.ChargingRules.Unload();
				Break;
			EndIf;
			vParent = vParent.Parent;
		EndDo;
	EndIf;
	If ValueIsFilled(Hotel) Then
		If Hotel.ChargingRules.Count() > 0 Then
			If vChargingRules <> Undefined Then
				For Each vHCRRow In Hotel.ChargingRules Do
					If vChargingRules.Find(vHCRRow.ChargingRule, "ChargingRule") = Undefined Then
						vCRRow = vChargingRules.Add();
						FillPropertyValues(vCRRow, vHCRRow);
					EndIf;
				EndDo;
			Else
				vChargingRules = Hotel.ChargingRules.Unload();
			EndIf;
		EndIf;
	EndIf;
	// Check list of template rules
	If vChargingRules = Undefined Then
		vCR = ChargingRules.Add();
		
		// Create new folio and take parameters from the hotel
		vOldFolioRef = cmGetChargingRulesRowFolio(GuestGroup, pmGetThisDocumentRef(), ChargingRules.IndexOf(vCR) + 1);
		If ValueIsFilled(vOldFolioRef) Then
			vFolioObj = vOldFolioRef.GetObject();
			vFolioObj.DeletionMark = False;
		Else
			vOldFolioRef = cmGetChargingRulesRowFolio(GuestGroup, pmGetThisDocumentRef(), ChargingRules.IndexOf(vCR) + 1);
			If ValueIsFilled(vOldFolioRef) Then
				vFolioObj = vOldFolioRef.GetObject();
				vFolioObj.DeletionMark = False;
			Else
				vFolioObj = Documents.Folio.CreateDocument();
			EndIf;
		EndIf;
		cmFillFolioFromTemplate(vFolioObj, Undefined, Hotel, Date);
		vFolioObj.ParentDoc = pmGetThisDocumentRef();
		vFolioObj.Company = Company;
		vFolioObj.Client = Guest;
		vFolioObj.GuestGroup = GuestGroup;
		vFolioObj.DateTimeFrom = CheckInDate;
		vFolioObj.DateTimeTo = CheckOutDate;
		vFolioObj.LineNumber = ChargingRules.IndexOf(vCR) + 1;
		If pPaymentMethod <> Undefined Then
			vFolioObj.PaymentMethod = pPaymentMethod;
		EndIf;
		vFolioObj.Write(DocumentWriteMode.Write);
		
		// Add it to the charging rules
		vCR.ChargingRule = Enums.ChargingRuleTypes.Any;
		vCR.ChargingFolio = vFolioObj.Ref;
		If ValueIsFilled(vFolioObj.Contract) Then
			vCR.Owner = vFolioObj.Contract;
		ElsIf ValueIsFilled(vFolioObj.Customer) Then
			vCR.Owner = vFolioObj.Customer;
		EndIf;
	Else
		For Each vRule In vChargingRules Do
			vIsTemplate = True;
			vTemplateFolio = vRule.ChargingFolio;
			If ValueIsFilled(vTemplateFolio) Then
				vIsTemplate = Not vTemplateFolio.IsMaster;
			EndIf;
			If vIsTemplate Then
				vCR = ChargingRules.Add();
				
				// Create new folio from template
				vOldFolioRef = cmGetChargingRulesRowFolio(GuestGroup, pmGetThisDocumentRef(), ChargingRules.IndexOf(vCR) + 1);
				If ValueIsFilled(vOldFolioRef) Then
					vFolioObj = vOldFolioRef.GetObject();
					vFolioObj.DeletionMark = False;
				Else
					vOldFolioRef = cmGetChargingRulesRowFolio(GuestGroup, pmGetThisDocumentRef(), ChargingRules.IndexOf(vCR) + 1);
					If ValueIsFilled(vOldFolioRef) Then
						vFolioObj = vOldFolioRef.GetObject();
						vFolioObj.DeletionMark = False;
					Else
						vFolioObj = Documents.Folio.CreateDocument();
					EndIf;
				EndIf;
				cmFillFolioFromTemplate(vFolioObj, vTemplateFolio, Hotel, Date);
				vFolioObj.ParentDoc = pmGetThisDocumentRef();
				If Not vFolioObj.DoNotUpdateCompany Then
					vFolioObj.Company = Company;
				EndIf;
				vFolioObj.Client = Guest;
				vFolioObj.GuestGroup = GuestGroup;
				vFolioObj.DateTimeFrom = CheckInDate;
				vFolioObj.DateTimeTo = CheckOutDate;
				vFolioObj.LineNumber = ChargingRules.IndexOf(vCR) + 1;
				If pPaymentMethod <> Undefined Then
					vFolioObj.PaymentMethod = pPaymentMethod;
				EndIf;
				vFolioObj.Write(DocumentWriteMode.Write);
				
				// Add it to the charging rules
				FillPropertyValues(vCR, vRule, , "ChargingFolio");
				vCR.ChargingFolio = vFolioObj.Ref;
				If ValueIsFilled(vFolioObj.Contract) Then
					vCR.Owner = vFolioObj.Contract;
				ElsIf ValueIsFilled(vFolioObj.Customer) Then
					vCR.Owner = vFolioObj.Customer;
				EndIf;
			Else
				// Copy charging rule
				vCR = ChargingRules.Add();
				FillPropertyValues(vCR, vRule);
				If ValueIsFilled(vCR.ChargingFolio.Contract) Then
					vCR.Owner = vCR.ChargingFolio.Contract;
				ElsIf ValueIsFilled(vCR.ChargingFolio.Customer) Then
					vCR.Owner = vCR.ChargingFolio.Customer;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
EndProcedure //  pmCreateFolios

// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues(pIsProbe = False, pSkipFoliosCreation = False) Export
	// Fill author and document date
	pmFillAuthorAndDate();
	// Fill from session parameters
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(Hotel) Then
		If Not ValueIsFilled(Company) Then
			Company = Hotel.Company;
		EndIf;
		If ValueIsFilled(Author) And ValueIsFilled(Author.Company) Then
			Company = Author.Company;
		EndIf;
		If Not ValueIsFilled(ReservationStatus) Then
			ReservationStatus = Hotel.NewReservationStatus;
			If Not ValueIsFilled(GuaranteeType) And ReservationStatus.IsGuaranteed And ValueIsFilled(ReservationStatus.GuaranteeType) Then
				GuaranteeType = ReservationStatus.GuaranteeType;
			EndIf;
			// Update DoCharging flag
			pmSetDoCharging();
		EndIf;
		If Not ValueIsFilled(RoomRate) Then
			RoomRate = Hotel.RoomRate;
			If ValueIsFilled(RoomRate) Then
				// Source of business
				If ValueIsFilled(RoomRate.SourceOfBusiness) Then
					SourceOfBusiness = RoomRate.SourceOfBusiness;
				EndIf;
				// Marketing code
				If ValueIsFilled(RoomRate.MarketingCode) Then
					MarketingCode = RoomRate.MarketingCode;
				EndIf;
				// Client type
				If ValueIsFilled(RoomRate.ClientType) Then
					ClientType = RoomRate.ClientType;
					ClientTypeConfirmationText = RoomRate.ClientTypeConfirmationText;
				EndIf;
				// Company
				If ValueIsFilled(RoomRate.Company) Then
					Company = RoomRate.Company;
				EndIf;
			EndIf;
		EndIf;
		If Not ValueIsFilled(RoomRateServiceGroup) Then
			RoomRateServiceGroup = Hotel.RoomRateServiceGroup;
		EndIf;
		If Not ValueIsFilled(PlannedPaymentMethod) Then
			PlannedPaymentMethod = Hotel.PlannedPaymentMethod;
		EndIf;
		If Not ValueIsFilled(ReportingCurrency) Then
			ReportingCurrency = Hotel.ReportingCurrency;
		EndIf;
		ReportingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, ReportingCurrency, Date);
		If Not ValueIsFilled(AccommodationType) Then
			AccommodationType = cmGetDefaultAccommodationType(Hotel, RoomType);
		EndIf;
		// Initialize document period
		pmInitializePeriod();
	EndIf;
	If Not ValueIsFilled(ExchangeRateDate) Then
		ExchangeRateDate = Date;
	EndIf;
	If RoomQuantity = 0 Then
		RoomQuantity = 1;
	EndIf;
	// Create guest group if is new
	If Not ValueIsFilled(GuestGroup) Then
		pmCreateGuestGroup(pIsProbe);
	EndIf;
	// Create document folio if is new
	If ChargingRules.Count() = 0 And Not pSkipFoliosCreation Then
		pmCreateFolios();
	EndIf;
EndProcedure //  pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Procedure pmCalculateResources(pRecalculateNumberOfPersonsInReservation = False) Export
	vIsVirtual = False;
	// Fill room or room type resources
	If ValueIsFilled(Room) Then
		vRoomAttrs = Room.GetObject().pmGetRoomAttributes(cm1SecondShift(CheckInDate));
		For Each vRoomAttrsRow In vRoomAttrs Do
			NumberOfBedsPerRoom = vRoomAttrsRow.NumberOfBedsPerRoom;
			NumberOfPersonsPerRoom = vRoomAttrsRow.NumberOfPersonsPerRoom;
			RoomType = vRoomAttrsRow.RoomType;
			vIsVirtual = vRoomAttrsRow.IsVirtual;
			Break;
		EndDo;
	ElsIf ValueIsFilled(RoomType) Then
		NumberOfBedsPerRoom = RoomType.NumberOfBedsPerRoom;
		NumberOfPersonsPerRoom = RoomType.NumberOfPersonsPerRoom;
		vIsVirtual = RoomType.IsVirtual;
	Else
		NumberOfBedsPerRoom = 0;
		NumberOfPersonsPerRoom = 0;
	EndIf;
	// Fill accommodation type resources
	If ValueIsFilled(AccommodationType) And Not vIsVirtual Then
		If AccommodationType.Type = Enums.AccomodationTypes.Room Then
			NumberOfRooms = RoomQuantity * AccommodationType.NumberOfRooms;
			NumberOfBeds = ?(AccommodationType.NumberOfRooms = 0, 0, RoomQuantity * NumberOfBedsPerRoom);
			NumberOfAdditionalBeds = RoomQuantity * AccommodationType.NumberOfAdditionalBeds;
			If NumberOfPersons = 0 Then
				NumberOfPersons = RoomQuantity * AccommodationType.NumberOfPersons;
			EndIf;
			If pRecalculateNumberOfPersonsInReservation And AccommodationType.NumberOfPersons4Reservation <> 0 Then
				NumberOfPersons = RoomQuantity * AccommodationType.NumberOfPersons4Reservation;
			EndIf;
		ElsIf AccommodationType.Type = Enums.AccomodationTypes.Beds Then
			NumberOfRooms = 0;
			NumberOfBeds = RoomQuantity * AccommodationType.NumberOfBeds;
			NumberOfAdditionalBeds = RoomQuantity * AccommodationType.NumberOfAdditionalBeds;
			If NumberOfPersons = 0 Then
				NumberOfPersons = RoomQuantity * AccommodationType.NumberOfPersons;
			EndIf;
			If pRecalculateNumberOfPersonsInReservation And AccommodationType.NumberOfPersons4Reservation <> 0 Then
				NumberOfPersons = RoomQuantity * AccommodationType.NumberOfPersons4Reservation;
			EndIf;
		ElsIf AccommodationType.Type = Enums.AccomodationTypes.AdditionalBed Then
			NumberOfRooms = 0;
			NumberOfBeds = 0;
			NumberOfAdditionalBeds = RoomQuantity * AccommodationType.NumberOfAdditionalBeds;
			If NumberOfPersons = 0 Then
				NumberOfPersons = RoomQuantity * AccommodationType.NumberOfPersons;
			EndIf;
			If pRecalculateNumberOfPersonsInReservation And AccommodationType.NumberOfPersons4Reservation <> 0 Then
				NumberOfPersons = RoomQuantity * AccommodationType.NumberOfPersons4Reservation;
			EndIf;
		ElsIf AccommodationType.Type = Enums.AccomodationTypes.Together Then
			NumberOfRooms = 0;
			NumberOfBeds = 0;
			NumberOfAdditionalBeds = RoomQuantity * AccommodationType.NumberOfAdditionalBeds;
			If NumberOfPersons = 0 Then
				NumberOfPersons = RoomQuantity * AccommodationType.NumberOfPersons;
			EndIf;
			If pRecalculateNumberOfPersonsInReservation And AccommodationType.NumberOfPersons4Reservation <> 0 Then
				NumberOfPersons = RoomQuantity * AccommodationType.NumberOfPersons4Reservation;
			EndIf;
		EndIf;
		If AccommodationType.NumberOfPersons = 0 Then
			NumberOfPersons = 0;
		EndIf;
	Else
		NumberOfRooms = 0;
		NumberOfBeds = 0;
		NumberOfAdditionalBeds = 0;
	EndIf;
EndProcedure //  pmCalculateResources

// -----------------------------------------------------------------------------
// 
// Returns:
//  ValueTable - Table with resources
//
Function pmGetAccumulatingDiscountResources() Export
	// Initialize map with resources
	vRes = New ValueTable();
	vRes.Columns.Add("DiscountType", cmGetCatalogTypeDescription("DiscountTypes"), "Discount type", 20);
	vRes.Columns.Add("DiscountDimension", cmGetDiscountDimensionTypeDescription(), "Discount dimension", 20);
	vRes.Columns.Add("Resource", cmGetAccumulatingDiscountResourceTypeDescription(), "Discount resource", 20);
	vRes.Columns.Add("Bonus", cmGetAccumulatingDiscountResourceTypeDescription(), "Bonus", 20);
	// Get list of accumulating discount types defined in the catalog
	vDiscountType = Undefined;
	If ValueIsFilled(DiscountType) And DiscountType.IsAccumulatingDiscount Then
		vDiscountType = DiscountType;
	EndIf;
	vAccDisTypes = cmGetAccumulatingDiscountTypes(vDiscountType, Hotel);
	// Get resources
	For Each vAccDisType In vAccDisTypes Do
		vDiscountType = vAccDisType.DiscountType;
		vDiscountTypeObj = vDiscountType.GetObject();
		vAccDisRes = vDiscountTypeObj.pmGetAccumulatingDiscountResources(BegOfDay(CheckInDate),
		                                                                 Customer,
		                                                                 Contract,
		                                                                 Guest,
		                                                                 DiscountCard,
		                                                                 ?(vDiscountType.IsPerVisit, GuestGroup, Undefined));
		If vAccDisRes.Count() = 0 Then
			vResRow = vRes.Add();
			vResRow.DiscountType = vDiscountType;
			vResRow.DiscountDimension = vDiscountTypeObj.pmGetDefaultAccumulatingDiscountDimension();
			vResRow.Resource = 0;
			vResRow.Bonus = 0;
		Else
			For Each vAccDis In vAccDisRes Do
				vResRow = vRes.Add();
				vResRow.DiscountType = vAccDis.DiscountType;
				vResRow.DiscountDimension = vAccDis.DiscountDimension;
				vResRow.Resource = vAccDis.Resource;
				vResRow.Bonus = vAccDis.Bonus;
			EndDo;
		EndIf;
	EndDo;
	// Return
	Return vRes;
EndFunction //  pmGetAccumulatingDiscountResources

// -----------------------------------------------------------------------------
//
// Parameters:
//  pRoomRate	 - CatalogRef.RoomRates	 - 
//  pRoomType	 - CatalogRef.RoomTypes	 - 
// 
// Returns:
//  ValueTable - Table of valid room types
//
Function pmFillTypesTable(pRoomRate = Undefined, pRoomType = Undefined) Export
	// Create table of valid room types and accommodation types
	vTypesTable = New ValueTable();
	vTypesTable.Columns.Add("RoomType", cmGetCatalogTypeDescription("RoomTypes"));
	vTypesTable.Columns.Add("RoomTypeSortCode", cmGetSortCodeTypeDescription());
	vTypesTable.Columns.Add("AccommodationType", cmGetCatalogTypeDescription("AccommodationTypes"));
	vTypesTable.Columns.Add("AccommodationTypeSortCode", cmGetSortCodeTypeDescription());
	// Check room rate
	vRoomRate = RoomRate;
	If ValueIsFilled(pRoomRate) Then
		vRoomRate = pRoomRate;
	EndIf;
	If Not ValueIsFilled(vRoomRate) Then
		Return vTypesTable;
	EndIf;
	// Initialize empty types flags
	vIsEmptyRoomType = False;
	vIsEmptyAccommodationType = False;
	vRoomType = Undefined;
	If ValueIsFilled(pRoomType) Then
		vRoomType = pRoomType;
	ElsIf ValueIsFilled(RoomType) Then
		vRoomType = RoomType;
	EndIf;
	// Get list of price records for the given room rate
	vPrices = vRoomRate.GetObject().pmGetRoomRatePrices(CheckInDate, ?(ValueIsFilled(PriceCalculationDate), PriceCalculationDate, Undefined), ClientType, vRoomType, , , , CheckInDate, ?(CheckOutDate > CheckInDate + 24*3600, CheckInDate + 24*3600, CheckOutDate), True);
	If ValueIsFilled(ClientType) And (vPrices.Count() = 0 Or vPrices.FindRows(New Structure("IsRoomRevenue", True)).Count() = 0) Then
		vPrices = vRoomRate.GetObject().pmGetRoomRatePrices(CheckInDate, ?(ValueIsFilled(PriceCalculationDate), PriceCalculationDate, Undefined), Catalogs.ClientTypes.EmptyRef(), vRoomType, , , , CheckInDate, ?(CheckOutDate > CheckInDate + 24*3600, CheckInDate + 24*3600, CheckOutDate), True);
	EndIf;
	// Fill table with all type combinations from the price records
	For Each vPricesRow In vPrices Do
		If vPricesRow.IsRoomRevenue And vPricesRow.IsInPrice Then
			vTypesTableRow = vTypesTable.Add();
			vTypesTableRow.RoomType = vPricesRow.RoomType;
			vTypesTableRow.AccommodationType = vPricesRow.AccommodationType;
			If Not ValueIsFilled(vTypesTableRow.RoomType) Then
				vIsEmptyRoomType = True;
			Else
				vTypesTableRow.RoomTypeSortCode = vPricesRow.RoomTypeSortCode;
			EndIf;
			If Not ValueIsFilled(vTypesTableRow.AccommodationType) Then
				vIsEmptyAccommodationType = True;
			Else
				vTypesTableRow.AccommodationTypeSortCode = vPricesRow.AccommodationTypeSortCode;
			EndIf;
		EndIf;
	EndDo;
	// Group all types combinations
	vTypesTable.GroupBy("RoomType, RoomTypeSortCode, AccommodationType, AccommodationTypeSortCode",);
	// Detail empty room type records
	If vIsEmptyRoomType Then
		vRoomTypes = cmGetAllRoomTypes(Hotel);
		i = 0;
		While i < vTypesTable.Count() Do
			vTypesTableRow = vTypesTable.Get(i);
			If Not ValueIsFilled(vTypesTableRow.RoomType) Then
				vCurAccommodationType = vTypesTableRow.AccommodationType;
				vCurAccommodationTypeSortCode = vTypesTableRow.AccommodationTypeSortCode;
				vTypesTable.Delete(i);
				For Each vRoomType In vRoomTypes Do
					vTypesTableRow = vTypesTable.Insert(i);
					vTypesTableRow.RoomType = vRoomType.RoomType;
					vTypesTableRow.RoomTypeSortCode = vRoomType.RoomType.SortCode;
					vTypesTableRow.AccommodationType = vCurAccommodationType;
					vTypesTableRow.AccommodationTypeSortCode = vCurAccommodationTypeSortCode;
					i = i + 1;
				EndDo;
			Else
				i = i + 1;
			EndIf;
		EndDo;
	EndIf;
	// Detail empty accommodation type records
	If vIsEmptyAccommodationType Then
		vAccommodationTypes = cmGetAllAccommodationTypes();
		i = 0;
		While i < vTypesTable.Count() Do
			vTypesTableRow = vTypesTable.Get(i);
			If Not ValueIsFilled(vTypesTableRow.AccommodationType) Then
				vCurRoomType = vTypesTableRow.RoomType;
				vCurRoomTypeSortCode = vTypesTableRow.RoomTypeSortCode;
				vTypesTable.Delete(i);
				For Each vAccommodationType In vAccommodationTypes Do
					vTypesTableRow = vTypesTable.Insert(i);
					vTypesTableRow.RoomType = vCurRoomType;
					vTypesTableRow.RoomTypeSortCode = vCurRoomTypeSortCode;
					vTypesTableRow.AccommodationType = vAccommodationType.AccommodationType;
					vTypesTableRow.AccommodationTypeSortCode = vAccommodationType.AccommodationType.SortCode;
					i = i + 1;
				EndDo;
			Else
				i = i + 1;
			EndIf;
		EndDo;
	EndIf;
	// Sort table by sort codes
	vTypesTable.Sort("RoomTypeSortCode, AccommodationTypeSortCode");
	// Return
	Return vTypesTable;
EndFunction //  pmFillTypesTable

// -----------------------------------------------------------------------------
//  Get reservation prices for all day types of room rate
//
// Parameters:
//  pLang	 - CatalogRef.Languages	 - Language
// 
// Returns:
//  String - Price presentation
//
Function pmCalculatePricePresentation(Val pLang = Undefined) Export
	If ValueIsFilled(ReservationStatus) Then
		If Not ReservationStatus.IsActive Then
			If ReservationStatus.DoNoShowCharging Or ReservationStatus.DoLateAnnulationCharging Then
				Return PricePresentation;
			EndIf;
		EndIf;
	EndIf;
	vPricePresentation = "N/A";
	If pLang = Undefined Then
		pLang = SessionParameters.CurrentLanguage;
	EndIf;
	vPrices = pmGetPrices();
	If vPrices.Count() > 0 Then
		If ValueIsFilled(Hotel) And Hotel.UseMaximumPriceInPricePresentation Then
			vMaxPrice = 0;
			vMaxPriceCurrency = Hotel.BaseCurrency;
			For Each vPrice In vPrices Do
				If vPrice.Price > vMaxPrice Then
					vMaxPrice = vPrice.Price;
					vMaxPriceCurrency = vPrice.FolioCurrency;
				EndIf;
			EndDo;
			vPricePresentation = cmFormatSum(vMaxPrice, vMaxPriceCurrency, "NZ=---", pLang);
		ElsIf ValueIsFilled(Hotel) And Hotel.UseCheckInDatePriceInPricePresentation Then
			vCheckInPrice = 0;
			vCheckInPriceCurrency = Hotel.BaseCurrency;
			For Each vPrice In vPrices Do
				vCheckInPrice = vPrice.Price;
				vCheckInPriceCurrency = vPrice.FolioCurrency;
				Break;
			EndDo;
			vPricePresentation = cmFormatSum(vCheckInPrice, vCheckInPriceCurrency, "NZ=---", pLang);
		ElsIf vPrices.Count() > 0 Then
			vPricePresentation = "";
			For Each vPrice In vPrices Do
				If Not IsBlankString(vPricePresentation) Then
					vPricePresentation = vPricePresentation + Chars.LF;
				EndIf;
				If ValueIsFilled(vPrice.AccountingDate) Then
					vPricePresentation = vPricePresentation + cmFormatSum(vPrice.Price, vPrice.FolioCurrency, "NZ=---", pLang) + 
					                     " - " + Format(vPrice.AccountingDate, "DF=dd.MM");
				Else
					vPricePresentation = vPricePresentation + cmFormatSum(vPrice.Price, vPrice.FolioCurrency, "NZ=---", pLang) + 
					                     ?(ValueIsFilled(vPrice.CalendarDayType), " - " + vPrice.CalendarDayType.GetObject().pmGetDayTypeDescription(pLang), "");
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	// Check length of price presentation
	If StrLen(vPricePresentation) > 250 Then
		vPricePresentation = Left(vPricePresentation, 247) + "...";
	EndIf;
	// Return
	Return vPricePresentation;
EndFunction //  pmCalculatePricePresentation

// -----------------------------------------------------------------------------
// 
// Returns:
//  ValueTable - List of commission
//
Function pmGetComplexCommission() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	CommissionSliceLast.Period AS SliceLastPeriod,
	|	CommissionSliceLast.Agent AS SliceLastAgent,
	|	CommissionSliceLast.Contract AS SliceLastContract,
	|	CommissionSliceLast.ServiceGroup AS SliceLastServiceGroup,
	|	CommissionSliceLast.RoomClass AS SliceLastRoomClass,
	|	CommissionSliceLast.RoomType AS SliceLastRoomType,
	|	CommissionSliceLast.Hotel AS SliceLastHotel,
	|	CommissionSliceLast.Commission AS SliceLastCommission,
	|	CommissionSliceLast.CommissionType AS SliceLastCommissionType
	|INTO CommissionSliceLast
	|FROM
	|	InformationRegister.Commission.SliceLast(
	|			&qPeriodFrom,
	|			Agent = &qAgent
	|				AND Contract = &qContract
	|				AND (Hotel = &qHotel
	|					OR Hotel = &qEmptyHotel)) AS CommissionSliceLast
	|
	|ORDER BY
	|	SliceLastPeriod DESC,
	|	CommissionSliceLast.ServiceGroup.Code
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Commissions.Period AS Period,
	|	Commissions.Agent AS Agent,
	|	Commissions.Contract AS Contract,
	|	Commissions.ServiceGroup AS ServiceGroup,
	|	Commissions.RoomClass AS RoomClass,
	|	Commissions.RoomType AS RoomType,
	|	Commissions.Hotel AS Hotel,
	|	Commissions.Commission AS Commission,
	|	Commissions.CommissionType AS CommissionType
	|FROM
	|	(SELECT
	|		ComplexCommission.Period AS Period,
	|		ComplexCommission.Agent AS Agent,
	|		ComplexCommission.Contract AS Contract,
	|		ComplexCommission.ServiceGroup AS ServiceGroup,
	|		ComplexCommission.RoomClass AS RoomClass,
	|		ComplexCommission.RoomType AS RoomType,
	|		ComplexCommission.Hotel AS Hotel,
	|		ComplexCommission.Commission AS Commission,
	|		ComplexCommission.CommissionType AS CommissionType
	|	FROM
	|		InformationRegister.Commission AS ComplexCommission
	|			INNER JOIN CommissionSliceLast AS CommissionSliceLast
	|			ON ComplexCommission.Period = CommissionSliceLast.SliceLastPeriod
	|				AND ComplexCommission.Agent = CommissionSliceLast.SliceLastAgent
	|				AND ComplexCommission.Contract = CommissionSliceLast.SliceLastContract
	|				AND ComplexCommission.Hotel = CommissionSliceLast.SliceLastHotel
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ComplexCommissionChanges.Period,
	|		ComplexCommissionChanges.Agent,
	|		ComplexCommissionChanges.Contract,
	|		ComplexCommissionChanges.ServiceGroup,
	|		ComplexCommissionChanges.RoomClass,
	|		ComplexCommissionChanges.RoomType,
	|		ComplexCommissionChanges.Hotel,
	|		ComplexCommissionChanges.Commission,
	|		ComplexCommissionChanges.CommissionType
	|	FROM
	|		InformationRegister.Commission AS ComplexCommissionChanges
	|	WHERE
	|		ComplexCommissionChanges.Period > &qPeriodFrom
	|		AND ComplexCommissionChanges.Period < &qPeriodTo
	|		AND ComplexCommissionChanges.Agent = &qAgent
	|		AND ComplexCommissionChanges.Contract = &qContract
	|		AND (ComplexCommissionChanges.Hotel = &qHotel
	|				OR ComplexCommissionChanges.Hotel = &qEmptyHotel)) AS Commissions
	|
	|ORDER BY
	|	Commissions.Period DESC,
	|	ISNULL(Commissions.RoomClass.SortCode, 0) DESC,
	|	ISNULL(Commissions.RoomType.SortCode, 0) DESC,
	|	Commissions.ServiceGroup.Code";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qAgent", Agent);
	vQry.SetParameter("qContract", Contract);
	vQry.SetParameter("qPeriodFrom", CheckInDate);
	vQry.SetParameter("qPeriodTo", CheckOutDate);
	vComplexCommission = vQry.Execute().Unload();
	Return vComplexCommission;
EndFunction //  pmGetComplexCommission

// -----------------------------------------------------------------------------
//
// Parameters:
//  pRoomRate				 - 	 - 
//  pAccountingDate			 - 	 - 
//  pPriceCalculationDate	 - 	 - 
//  pService				 - 	 - 
//  rCurrency				 - 	 - 
//  pRoomType				 - 	 - 
//  pPriceTag				 - 	 - 
//  pAccommodationType		 - 	 - 
//  pAccommodationTemplate	 - 	 - 
//  pIsForFolioSplit		 - 	 - 
//  pSplitPackagesByGuests	 - 	 - 
// 
// Returns:
//  ValueTable - List of prices
//
Function pmGetServiceRatePrice(pRoomRate, pAccountingDate, pPriceCalculationDate, pService, rCurrency, pRoomType, pPriceTag = Undefined, pAccommodationType = Undefined, pAccommodationTemplate = Undefined, pIsForFolioSplit = False, pSplitPackagesByGuests = Undefined) Export
	vPrice = 0;
	vSplitPackagesByGuests = pIsForFolioSplit;
	If pSplitPackagesByGuests <> Undefined Then
		vSplitPackagesByGuests = pSplitPackagesByGuests;
	EndIf;
	// Check that room rate is filled
	If Not ValueIsFilled(pRoomRate) Then
		Return vPrice;
	EndIf;
	If Not ValueIsFilled(pRoomRate.Calendar) Then
		Return vPrice;
	EndIf;
	// Get accommodation type
	vAccommodationType = AccommodationType;
	If pAccommodationType <> Undefined Then
		vAccommodationType = pAccommodationType;
	EndIf;
	// Get rate calendar accounting date day type
	vCalendarDayType = Catalogs.CalendarDayTypes.EmptyRef();
	vRoomRateCalendarDays = pRoomRate.Calendar.GetObject().pmGetDays(pAccountingDate, pAccountingDate, , , pRoomType, pPriceCalculationDate);
	For Each vRoomRateCalendarDaysRow In vRoomRateCalendarDays Do
		If ValueIsFilled(vRoomRateCalendarDaysRow.CalendarDayType) Then
			vCalendarDayType = vRoomRateCalendarDaysRow.CalendarDayType;
			Break;
		EndIf;
	EndDo;
	// Get list of price records for the given room rate
	vPrices = pRoomRate.GetObject().pmGetRoomRatePrices(pAccountingDate, pPriceCalculationDate, ClientType, pRoomType, vAccommodationType, , , CheckInDate, CheckOutDate, , , , , pAccommodationTemplate, pIsForFolioSplit, vSplitPackagesByGuests, Not IsBlankString(SharePercent));
	If ValueIsFilled(ClientType) And (vPrices.Count() = 0 Or vPrices.FindRows(New Structure("IsRoomRevenue", True)).Count() = 0) Then
		vPrices = pRoomRate.GetObject().pmGetRoomRatePrices(pAccountingDate, pPriceCalculationDate, Catalogs.ClientTypes.EmptyRef(), pRoomType, vAccommodationType, , , CheckInDate, CheckOutDate, , , , , pAccommodationTemplate, pIsForFolioSplit, vSplitPackagesByGuests, Not IsBlankString(SharePercent));
	EndIf;
	If vPrices.Count() > 0 Then
		If pPriceTag <> Undefined Then
			vServicePrices = vPrices.FindRows(New Structure("Service, PriceTag", pService, pPriceTag));
		Else
			vServicePrices = vPrices.FindRows(New Structure("Service", pService));
		EndIf;
		For Each vPricesRow In vServicePrices Do
			// Check service package period
			If ValueIsFilled(vPricesRow.ServicePackage) And 
			  (BegOfDay(CheckInDate) < vPricesRow.ServicePackageDateValidFrom Or BegOfDay(CheckInDate) > vPricesRow.ServicePackageDateValidTo And ValueIsFilled(vPricesRow.ServicePackageDateValidTo)) Then
				Continue;
			EndIf;
			// Check that service is equal to the input parameter service and calendar day types are the same
			If ValueIsFilled(vPricesRow.CalendarDayType) And vCalendarDayType = vPricesRow.CalendarDayType Or 
			   Not ValueIsFilled(vPricesRow.CalendarDayType) Then
				vPrice = vPricesRow.Price;
				rCurrency = vPricesRow.Currency;
				Break;
			EndIf;
		EndDo;
	EndIf;
	// Check should we divide price by duration
	vRateQuantityCalculationRule = pRoomRate.QuantityCalculationRule;
	If ValueIsFilled(vRateQuantityCalculationRule) And vRateQuantityCalculationRule.Duration > 0 Then
		vPrice = Round(vPrice / vRateQuantityCalculationRule.Duration, 2);
	EndIf;
	// Return price
	Return vPrice;
EndFunction // pmGetServiceRatePrice	

// -----------------------------------------------------------------------------
//  Calculates services for the given document.
//
// Parameters:
//  rWarnings						 - String					 - 
//  pPeriodDiscount					 - Number					 - 
//  pPeriodDiscountType				 - Structure				 - 
//  pPeriodDiscountServiceGroup		 - Structure				 - 
//  pPeriodDiscountConfirmationText	 - Structure				 - 
//  pIsForFolioSplit				 - Boolean					 - 
//  pIgnoreRestrictions				 - Boolean					 - 
//  pAccommodationTemplate			 - CatalogRef.AccommodationTemplates - 
// 
// Returns:
//  Boolean - False if warnings were rised during services calculation. Otherwise
//
Function pmCalculateServices(rWarnings = "", pPeriodDiscount = 0, pPeriodDiscountType = Undefined, 
                                             pPeriodDiscountServiceGroup = Undefined, pPeriodDiscountConfirmationText = "", 
											 pIsForFolioSplit = Undefined, pIgnoreRestrictions = False, pAccommodationTemplate = Undefined) Export
	vWarnings = False;
	If Not ValueIsFilled(RoomType) Then
		Return vWarnings;
	EndIf;

	// Check price calculation date (conversion to 9.1)
	If ValueIsFilled(PriceCalculationDate) And BegOfDay(PriceCalculationDate) = PriceCalculationDate Then
		PriceCalculationDate = EndOfDay(PriceCalculationDate);
		For Each vRRRow In RoomRates Do
			If ValueIsFilled(vRRRow.PriceCalculationDate) And vRRRow.PriceCalculationDate = BegOfDay(vRRRow.PriceCalculationDate) Then
				vRRRow.PriceCalculationDate = EndOfDay(vRRRow.PriceCalculationDate);
			EndIf;
		EndDo;
		For Each vSrvRow In Services Do
			If Not vSrvRow.IsManual And Not vSrvRow.CalendarDayTypeIsChanged Then
				vSrvRow.CalendarDayTypeIsChanged = True;
			EndIf;
		EndDo;
	EndIf;
	If Not ValueIsFilled(PriceCalculationDate) Then
		PriceCalculationDate = CurrentSessionDate();
		If PriceCalculationDate = BegOfDay(PriceCalculationDate) Then
			PriceCalculationDate = PriceCalculationDate + 1;
		EndIf;
	EndIf;
	
	// Reset price calculation date if there is room type change and room rate has appropriate flag ON
	If Not IsNew() And ValueIsFilled(Ref) Then
		vNewPriceCalculationDate = CurrentSessionDate();
		If vNewPriceCalculationDate = BegOfDay(vNewPriceCalculationDate) Then
			vNewPriceCalculationDate = vNewPriceCalculationDate + 1;
		EndIf;
		If ValueIsFilled(RoomRate) And RoomRate.RoomTypeChangeUpdatesPriceCalculationDate Then
			If Ref.RoomType <> RoomType And Ref.PriceCalculationDate = PriceCalculationDate Then
				PriceCalculationDate = vNewPriceCalculationDate;
				For Each vSrvRow In Services Do
					If vSrvRow.CalendarDayTypeIsChanged Then
						vSrvRow.CalendarDayTypeIsChanged = False;
						vSrvRow.CalendarDayType = Undefined;
						vSrvRow.PriceTag = Undefined;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		For Each vRRRow In RoomRates Do
			If ValueIsFilled(vRRRow.AccountingDate) And ValueIsFilled(vRRRow.RoomType) And ValueIsFilled(vRRRow.PriceCalculationDate) Then
				vRRowRoomRate = vRRRow.RoomRate;
				If Not ValueIsFilled(vRRowRoomRate) Then
					vRRowRoomRate = RoomRate;
				EndIf;
				If ValueIsFilled(vRRowRoomRate) And vRRowRoomRate.RoomTypeChangeUpdatesPriceCalculationDate Then
					vOldRRRow = Ref.RoomRates.Find(vRRRow.AccountingDate, "AccountingDate");
					If vOldRRRow <> Undefined Then
						If ValueIsFilled(vOldRRRow.RoomType) And vOldRRRow.RoomType <> vRRRow.RoomType And 
						   ValueIsFilled(vOldRRRow.PriceCalculationDate) And vOldRRRow.PriceCalculationDate = vRRRow.PriceCalculationDate Then
							vRRRow.PriceCalculationDate = vNewPriceCalculationDate;
						EndIf;
					Else
						If vRRRow.RoomType <> RoomType Then
							vRRRow.PriceCalculationDate = vNewPriceCalculationDate;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	// Before upgrade attributes
	If Not ValueIsFilled(RoomTypeBeforeUpgrade) Or Not Posted Then
		If ValueIsFilled(RoomType) Then
			RoomTypeBeforeUpgrade = RoomType;
		EndIf;
	EndIf;
	If Not ValueIsFilled(ServicePackageBeforeUpgrade) Or Not Posted Then
		If ValueIsFilled(ServicePackage) And ServicePackage.IsMealBoardTerm Then
			ServicePackageBeforeUpgrade = ServicePackage;
		EndIf;
	EndIf;
	
	// Remove special offers from discount confirmation text
	vSpecOfferPos = StrFind(DiscountConfirmationText, Char(8226));
	If vSpecOfferPos > 1 Then
		DiscountConfirmationText = TrimAll(Left(DiscountConfirmationText, vSpecOfferPos - 1));
	Else
		DiscountConfirmationText = "";
	EndIf;
	
	// Folio split mode
	vMainRoomGuestAccommodationTemplate = AccommodationTemplate;
	If ValueIsFilled(pAccommodationTemplate) And IsForFolioSplit And Not IsBlankString(SharePercent) Then
		vMainRoomGuestAccommodationTemplate = pAccommodationTemplate;
	EndIf;
	vOneRoomReservations = Undefined;
	vIsForFolioSplit = False;
	If pIsForFolioSplit <> Undefined Then
		vIsForFolioSplit = pIsForFolioSplit;
	ElsIf IsForFolioSplit Then
		vIsForFolioSplit = IsForFolioSplit;
	Else
		// Calculate if it is folio split mode
		If ValueIsFilled(AccommodationType) Then
			If ValueIsFilled(AccommodationTemplate) And AccommodationTemplate.IsForFolioSplit Then
				vIsForFolioSplit = True;
			ElsIf AccommodationType.Type = Enums.AccomodationTypes.Beds Then
				vIsForFolioSplit = True;
			ElsIf AccommodationType.Type = Enums.AccomodationTypes.AdditionalBed Or AccommodationType.Type = Enums.AccomodationTypes.Together Then
				// Try to find reservation/accommodation with type Beds. If yes then assume that this is folio split mode
				vOneRoomReservations = cmGetOneRoomReservations(Number, GuestGroup, CheckInDate, CheckOutDate, Not ReservationStatus.IsActive, Posted);
				If vOneRoomReservations.Count() = 0 Then
					vIsForFolioSplit = True;
				EndIf;
				For Each vOneRoomReservationRow In vOneRoomReservations Do
					If vOneRoomReservationRow.AccommodationTypeType = Enums.AccomodationTypes.Beds Then
						vIsForFolioSplit = True;
					EndIf;
					If Not ValueIsFilled(vMainRoomGuestAccommodationTemplate) And vIsForFolioSplit And Not IsBlankString(SharePercent) And ValueIsFilled(vOneRoomReservationRow.AccommodationTemplate) Then
						vMainRoomGuestAccommodationTemplate = vOneRoomReservationRow.AccommodationTemplate;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	If Not ValueIsFilled(vMainRoomGuestAccommodationTemplate) And vIsForFolioSplit And Not IsBlankString(SharePercent) Then
		If vOneRoomReservations = Undefined Then
			vOneRoomReservations = cmGetOneRoomReservations(Number, GuestGroup, CheckInDate, CheckOutDate, Not ReservationStatus.IsActive);
		EndIf;
		For Each vOneRoomReservationRow In vOneRoomReservations Do
			If ValueIsFilled(vOneRoomReservationRow.AccommodationTemplate) Then
				vMainRoomGuestAccommodationTemplate = vOneRoomReservationRow.AccommodationTemplate;
				Break;
			EndIf;
		EndDo;
	EndIf;
	vIsForFolioSplitForPrices = vIsForFolioSplit;
	vSplitPackagesByGuests = vIsForFolioSplit;
	If vIsForFolioSplit And Not IsBlankString(SharePercent) Then
		vIsForFolioSplitForPrices = False;
	EndIf;

	vUseTemplateWithoutExtraBeds = False;
	If IsForFolioSplit Or pIsForFolioSplit <> Undefined And pIsForFolioSplit Then
		If ValueIsFilled(vMainRoomGuestAccommodationTemplate) Then
			If Not IsBlankString(SharePercent) And Hotel.SkipExtraBedsFromPriceSharing Then
				vNumGuestsByPercent = 0;
				If cmIsNumber(SharePercent) Then
					vShare = Number(SharePercent);
					If vShare <> 0 Then
						vNumGuestsByPercent = Round(100/vShare);
					EndIf;
				Else
					vSlashPos = StrFind(SharePercent, "/");
					If vSlashPos > 0 Then
						vShareStr = TrimAll(Mid(SharePercent, vSlashPos + 1));
						If cmIsNumber(vShareStr) Then
							vShare = Number(vShareStr);
							If vShare <> 0 Then
								vNumGuestsByPercent = Round(vShare, 0);
							EndIf;
						EndIf;
					EndIf;
				EndIf;
				If vNumGuestsByPercent > 0 Then
					If vMainRoomGuestAccommodationTemplate.AccommodationTypes.Count() > vNumGuestsByPercent Then
						vUseTemplateWithoutExtraBeds = True;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	// Internal attributes check
	If ValueIsFilled(AccommodationTemplate) Then
		If NumberOfAdults = 0 And NumberOfTeenagers = 0 And NumberOfChildren = 0 And NumberOfInfants = 0 Then
			NumberOfAdults = RoomQuantity * AccommodationTemplate.NumberOfAdults;
			NumberOfTeenagers = RoomQuantity * AccommodationTemplate.NumberOfTeenagers;
			NumberOfChildren = RoomQuantity * AccommodationTemplate.NumberOfChildren;
			NumberOfInfants = RoomQuantity * AccommodationTemplate.NumberOfInfants;
		EndIf;
	Else
		NumberOfAdults = 0;
		NumberOfTeenagers = 0;
		NumberOfChildren = 0;
		NumberOfInfants = 0;
	EndIf;
	
	// User exit before calculate services
	vBeforeCalculateServicesUserExit = Catalogs.ExternalDataProcessors.ReservationBeforeCalculateServices;
	If vBeforeCalculateServicesUserExit.ExternalProcessingType = Enums.ExternalProcessingTypes.Algorithm And Not IsBlankString(vBeforeCalculateServicesUserExit.Algorithm) Then
		SetSafeMode(True);
		Execute(TrimR(vBeforeCalculateServicesUserExit.Algorithm));
		SetSafeMode(False);
	EndIf;
		
	// Processing
	vWarnings = False;
	vNoAccommodationService = True;
	vCurPriceTag = Undefined;
	// Upgrade service
	vOffer = Undefined;
	vUpgradeService = Hotel.RoomUpgradeService;
	// Create table of charging rules
	vCRTab = ChargingRules.Unload();
	If Not IgnoreGroupChargingRules Then
		cmAddGuestGroupChargingRules(vCRTab, GuestGroup);
	EndIf;
	// Create table of manual prices
	vMPTab = Prices.Unload();
	// Fill period
	vCheckInDate = CheckInDate;
	vCheckOutDate = CheckOutDate;
	If ValueIsFilled(HotelProduct) And Not HotelProduct.IsFolder Then
		If HotelProduct.FixProductPeriod Then
			vCheckInDate = HotelProduct.CheckInDate;
			vCheckOutDate = HotelProduct.CheckOutDate;
		EndIf;
	EndIf;
	// Reservation date
	vReservationDate = Date;
	If ValueIsFilled(GuestGroup) And ValueIsFilled(GuestGroup.CreateDate) Then
		vReservationDate = GuestGroup.CreateDate;
	EndIf;
	// Create table of current services calendar day types for accounting dates
	vDayTypes = Services.Unload();
	vDayTypes.GroupBy("AccountingDate, Service, CalendarDayType, RoomRate, PriceTag, IsRoomRevenue, IsInPrice, CalendarDayTypeIsChanged", );
	i = 0;
	While i < vDayTypes.Count() Do
		vDayTypesRow = vDayTypes.Get(i);
		If Not vDayTypesRow.CalendarDayTypeIsChanged Or 
		  (Not ValueIsFilled(vDayTypesRow.CalendarDayType) And Not ValueIsFilled(vDayTypesRow.PriceTag)) Then
			vDayTypes.Delete(i);
		Else
			i = i + 1;
		EndIf;
	EndDo;
	vCalendarDayTypes = vDayTypes.Copy(, "CalendarDayType");
	vCalendarDayTypes.GroupBy("CalendarDayType", );
	vCalendarDayTypesList = New ValueList();
	vCalendarDayTypesList.LoadValues(vCalendarDayTypes.UnloadColumn("CalendarDayType"));
	// Save services with prices changed manually and manually added services or manually added packages services
	vIsManualServices = Services.Unload(New Array, );
	vMCServices = Services.Unload();
	vMCServices.Columns.Add("PaymentMethod", cmGetCatalogTypeDescription("PaymentMethods"));
	i = 0;
	While i < vMCServices.Count() Do
		vSrv = vMCServices.Get(i);
		If ValueIsFilled(vSrv.IsManualAuthor) And ValueIsFilled(vSrv.IsManualDate) Then
			vIsManualServicesRow = vIsManualServices.Add();
			FillPropertyValues(vIsManualServicesRow, vSrv);
		EndIf;
		If Not vSrv.IsManualPrice Then
			vMCServices.Delete(i);
		Else
			If ValueIsFilled(vSrv.Folio) Then
				vSrv.PaymentMethod = vSrv.Folio.PaymentMethod;
			EndIf;
			i = i + 1;
		EndIf;
	EndDo;
	// First clear room rate services
	i = 0;
	While i < Services.Count() Do
		vSrv = Services.Get(i);
		If Not vSrv.IsManual Then
			Services.Delete(i);
		Else
			vSrv.Company = Company;
			vCurFolio = vSrv.Folio;
			If vSrv.Company <> vCurFolio.Company And vCurFolio.DoNotUpdateCompany Then
				vSrv.Company = vCurFolio.Company;
			EndIf;
			i = i + 1;
		EndIf;
	EndDo;
	// If reservation is not active and no show service should be charged then clear manual services
	If ValueIsFilled(ReservationStatus) Then
		If Not ReservationStatus.IsActive And 
		   ReservationStatus.DoCharging And
		   (ReservationStatus.DoNoShowCharging Or ReservationStatus.DoLateAnnulationCharging) Then
			Services.Clear();
		EndIf;
	EndIf;
	// Check folios for the manual services
	pmSetFolioBasedOnChargingRules(Services, True);
	// Check that room rate is filled
	If Not ValueIsFilled(RoomRate) Then
		PricePresentation = "";
		GoTo ~pmCalculateServicesEnd;
	EndIf;
	If Not ValueIsFilled(RoomRate.Calendar) Then
		PricePresentation = "";
		GoTo ~pmCalculateServicesEnd;
	EndIf;
	// Check if we should do no show charge only
	vCurFeeTerms = Undefined;
	vDoNoShowCharging = False;
	vDoLateAnnulationCharging = False;
	If ValueIsFilled(ReservationStatus) Then
		If Not ReservationStatus.IsActive And 
		  (ReservationStatus.DoNoShowCharging Or ReservationStatus.DoLateAnnulationCharging) Then
			If ValueIsFilled(FeeTerms) Then
				vCurFeeTerms = FeeTerms;
			Else
				If ValueIsFilled(Contract) And ValueIsFilled(Contract.FeeTerms) Then
					vCurFeeTerms = Contract.FeeTerms;
				ElsIf ValueIsFilled(Customer) And ValueIsFilled(Customer.FeeTerms) Then
					vCurFeeTerms = Customer.FeeTerms;
				ElsIf ValueIsFilled(RoomRate) And ValueIsFilled(RoomRate.FeeTerms) Then
					vCurFeeTerms = RoomRate.FeeTerms;
				EndIf;
			EndIf;
			If ValueIsFilled(vCurFeeTerms) Then
				If ReservationStatus.DoNoShowCharging Then
					vDoNoShowCharging = True;
				ElsIf ReservationStatus.DoLateAnnulationCharging Then
					vDoLateAnnulationCharging = True;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	// Save some old values
	vSavCheckInDate = CheckInDate;
	vSavCheckOutDate = CheckOutDate;
	If Not IsNew() Then
		vSavCheckInDate = Ref.CheckInDate;
		vSavCheckOutDate = Ref.CheckOutDate;
	EndIf;
	// Discount confirmation text
	If Not ValueIsFilled(DiscountType) Or ValueIsFilled(DiscountType) And (DiscountType.IsAccumulatingDiscount Or IsBlankString(DiscountType.ConfirmationPattern) And Not DiscountType.IsManualDiscount) Then
		DiscountConfirmationText = "";
	EndIf;
	// Get list of accumulating discount types with actual resources
	vAccDiscounts = pmGetAccumulatingDiscountResources();
	// Initialize value of discount that should be applied to the whole reservation period
	vPeriodDiscount = pPeriodDiscount;
	vPeriodDiscountType = pPeriodDiscountType;
	vPeriodDiscountServiceGroup = pPeriodDiscountServiceGroup;
	vPeriodDiscountConfirmationText = pPeriodDiscountConfirmationText;
	// Build list of service packages
	vServicePackagesList = New ValueList();
	If ValueIsFilled(ServicePackage) Then
		vSkipMealBoardTerm = False;
		If Not vIsForFolioSplit And Not ValueIsFilled(AccommodationTemplate) And ValueIsFilled(RoomRate) And RoomRate.RateChargeDirection = Enums.RateChargeDirections.MergeToTheMainRoomGuest Then
			If ServicePackage.IsMealBoardTerm Then
				vSkipMealBoardTerm = True;
			EndIf;
		EndIf;
		If Not vSkipMealBoardTerm Then
			vServicePackagesList.Add(New Structure("ServicePackage, Quantity, DateFrom, DateTo", ServicePackage, 1, '00010101', '39991231'));
		EndIf;
	EndIf;
	For Each vServicePackagesRow In ServicePackages Do
		If ValueIsFilled(vServicePackagesRow.ServicePackage) Then
			vServicePackagesList.Add(New Structure("ServicePackage, Quantity, DateFrom, DateTo", vServicePackagesRow.ServicePackage, ?(vServicePackagesRow.Quantity <= 0, 1, vServicePackagesRow.Quantity), vServicePackagesRow.DateFrom, ?(ValueIsFilled(vServicePackagesRow.DateTo), vServicePackagesRow.DateTo, '39991231')));
		EndIf;
	EndDo;
	// Get and check room rate restrictions
	vDoCheckRestrictions = False;
	If Not pIgnoreRestrictions Then
		If Not IsNew() Then
			If RoomRate <> Ref.RoomRate Or 
			   BegOfDay(CheckInDate) <> BegOfDay(Ref.CheckInDate) Or 
			   BegOfDay(CheckOutDate) <> BegOfDay(Ref.CheckOutDate) Or 
			   RoomType <> Ref.RoomType Then
				vDoCheckRestrictions = True;
			EndIf;
		Else
			vDoCheckRestrictions = True;
		EndIf;
	EndIf;
	vRestrStruct = RoomRate.GetObject().pmGetRoomRateRestrictions(CheckInDate, CheckOutDate, ?(ValueIsFilled(RoomTypeUpgrade), RoomTypeUpgrade, RoomType), True, PriceCalculationDate);
	If vDoCheckRestrictions And vRestrStruct.StopSale And Not ReservationStatus.IsCheckIn And Not ReservationStatus.IsNoShow And (ReservationStatus.IsActive Or ReservationStatus.IsPreliminary Or ReservationStatus.IsInWaitingList) Then
		vWarnings = True;
		vWarningsEn = "Room rate " + TrimAll(RoomRate) + " could not be used for the given period " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " - " + Format(vCheckOutDate, "DF=dd.MM.yyyy") + " (room rate restriction Stop Sales is turned on)!";
		vWarningsDe = "Tariff " + TrimAll(RoomRate) + " ist geschlossen (Tariff Einschränkung Stop Sale ist auf), periode " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " - " + Format(vCheckOutDate, "DF=dd.MM.yyyy") + "!";
		vWarningsRu = "Продажи по тарифу " + TrimAll(RoomRate) + " остановлены на периоде с " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " по " + Format(vCheckOutDate, "DF=dd.MM.yyyy") + " в ограничениях тарифа (Stop Sale включен)!";
		rWarnings = "ru = '" + vWarningsRu + "'; de = '" + vWarningsDe + "'; en = '" + vWarningsEn + "'";
	EndIf;
	If vDoCheckRestrictions And vRestrStruct.CTA And Not ReservationStatus.IsCheckIn And Not ReservationStatus.IsNoShow And (ReservationStatus.IsActive Or ReservationStatus.IsPreliminary Or ReservationStatus.IsInWaitingList) Then
		vWarnings = True;
		vWarningsEn = "Check-in is closed (CTA is On) for the given check-in date " + Format(CheckInDate, "DF=dd.MM.yyyy") + "!";
		vWarningsDe = "Check-in ist für den Check-in-Datum " + Format(CheckInDate, "DF=dd.MM.yyyy") + " geschlossen (CTA is On)!";
		vWarningsRu = "Заезд в выбранную дату " + Format(CheckInDate, "DF=dd.MM.yyyy") + " запрещен в ограничениях указанных у тарифа (CTA включен)!";
		rWarnings = "ru = '" + vWarningsRu + "'; de = '" + vWarningsDe + "'; en = '" + vWarningsEn + "'";
	EndIf;
	If vDoCheckRestrictions And vRestrStruct.CTD And Not ReservationStatus.IsCheckIn And Not ReservationStatus.IsNoShow And (ReservationStatus.IsActive Or ReservationStatus.IsPreliminary Or ReservationStatus.IsInWaitingList) Then
		vWarnings = True;
		vWarningsEn = "Check-out is closed (CTD is On) for the given check-out date " + Format(CheckOutDate, "DF=dd.MM.yyyy") + "!";
		vWarningsDe = "Check-out ist für den Check-out-Datum " + Format(CheckOutDate, "DF=dd.MM.yyyy") + " geschlossen (CTD is On)!";
		vWarningsRu = "Выезд в выбранную дату " + Format(CheckOutDate, "DF=dd.MM.yyyy") + " запрещен в ограничениях указанных у тарифа (CTD включен)!";
		rWarnings = "ru = '" + vWarningsRu + "'; de = '" + vWarningsDe + "'; en = '" + vWarningsEn + "'";
	EndIf;
	If vRestrStruct.MLOS > 0 And Duration < vRestrStruct.MLOS And ValueIsFilled(RoomRate) Then
		If RoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByDays Then
			If (Int((BegOfDay(vCheckOutDate) - BegOfDay(vCheckInDate))/(24*3600)) + 1) < vRestrStruct.MLOS And Not RoomRate.MLOSIsBlocking Then
				vCheckOutDate = cm0SecondShift(BegOfDay(vCheckInDate) + (vCheckOutDate - BegOfDay(vCheckOutDate)) + 24*3600*(vRestrStruct.MLOS - 1));
			EndIf;
		ElsIf RoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByHours Then
			If Int((BegOfDay(vCheckOutDate) - BegOfDay(vCheckInDate))/3600) < vRestrStruct.MLOS And Not RoomRate.MLOSIsBlocking Then
				vCheckOutDate = cm0SecondShift(BegOfDay(vCheckInDate) + 3600*vRestrStruct.MLOS);
			EndIf;
		Else
			If Int((BegOfDay(vCheckOutDate) - BegOfDay(vCheckInDate))/(24*3600)) < vRestrStruct.MLOS And Not RoomRate.MLOSIsBlocking Then
				vCheckOutDate = cm0SecondShift(BegOfDay(vCheckInDate) + (vCheckOutDate - BegOfDay(vCheckOutDate)) + 24*3600*vRestrStruct.MLOS);
			EndIf;
		EndIf;
		If vDoCheckRestrictions And RoomRate.MLOSIsBlocking Then
			vWarnings = True;
			vWarningsRu = "Минимальная продолжительность проживания " + vRestrStruct.MLOS + " дней!";
			vWarningsEn = "Minimum length of stay is " + vRestrStruct.MLOS + "!";
			vWarningsDe = "Mindestaufenthaltsdauer beträgt " + vRestrStruct.MLOS + " Tage!";
			rWarnings = "ru = '" + vWarningsRu + "'; de = '" + vWarningsDe + "'; en = '" + vWarningsEn + "'";
		EndIf;
	EndIf;
	If vDoCheckRestrictions And vRestrStruct.MaxLOS > 0 And Duration > vRestrStruct.MaxLOS Then
		vWarnings = True;
		vWarningsRu = "Максимальная продолжительность проживания " + vRestrStruct.MaxLOS + " дней!";
		vWarningsEn = "Maximum length of stay is " + vRestrStruct.MaxLOS + "!";
		vWarningsDe = "Maximaleaufenthaltsdauer beträgt " + vRestrStruct.MaxLOS + " Tage!";
		rWarnings = "ru = '" + vWarningsRu + "'; de = '" + vWarningsDe + "'; en = '" + vWarningsEn + "'";
	EndIf;
	If vDoCheckRestrictions And vRestrStruct.MinDaysBeforeCheckIn > 0 And ValueIsFilled(AccommodationType) And (AccommodationType.Type = Enums.AccomodationTypes.Room Or AccommodationType.Type = Enums.AccomodationTypes.Beds) Then
		vDate = GuestGroup.CreateDate;
		vDaysBeforeCheckIn = Int((BegOfDay(vCheckInDate) - BegOfDay(vDate))/(24*3600));
		If vDaysBeforeCheckIn < vRestrStruct.MinDaysBeforeCheckIn Then
			vWarnings = True;
			vWarningsRu = "Минимальное кол-во дней от даты бронирования до даты заезда " + vRestrStruct.MinDaysBeforeCheckIn + "!";
			vWarningsEn = "Minimum days between booking and check-in dates is " + vRestrStruct.MinDaysBeforeCheckIn + "!";
			vWarningsDe = "Mindest Tage zwischen Buchung und Check-in Daten ist " + vRestrStruct.MinDaysBeforeCheckIn + "!";
			rWarnings = "ru = '" + vWarningsRu + "'; de = '" + vWarningsDe + "'; en = '" + vWarningsEn + "'";
		EndIf;
	EndIf;
	If vDoCheckRestrictions And vRestrStruct.MaxDaysBeforeCheckIn > 0 And ValueIsFilled(AccommodationType) And (AccommodationType.Type = Enums.AccomodationTypes.Room Or AccommodationType.Type = Enums.AccomodationTypes.Beds) Then
		vDate = GuestGroup.CreateDate;
		vDaysBeforeCheckIn = Int((BegOfDay(vCheckInDate) - BegOfDay(vDate))/(24*3600));
		If vDaysBeforeCheckIn > vRestrStruct.MaxDaysBeforeCheckIn Then
			vWarnings = True;
			vWarningsRu = "Максимальное кол-во дней от даты бронирования до даты заезда " + vRestrStruct.MaxDaysBeforeCheckIn + "!";
			vWarningsEn = "Maximum days between booking and check-in dates is " + vRestrStruct.MaxDaysBeforeCheckIn + "!";
			vWarningsDe = "Maximale Tage zwischen Buchung und Check-in Daten ist " + vRestrStruct.MaxDaysBeforeCheckIn + "!";
			rWarnings = "ru = '" + vWarningsRu + "'; de = '" + vWarningsDe + "'; en = '" + vWarningsEn + "'";
		EndIf;
	EndIf;
	// Get accommodation condition periods
	vAccommodationPeriods = pmGetAccommodationPeriods(False);
	// Get and check room rate restrictions
	vBegOfCheckInDate = BegOfDay(vCheckInDate);
	vBegOfCheckOutDate = BegOfDay(vCheckOutDate);
	// Fill occupation percents
	vOccupationPercentsAreFilled = Not OccupationPercents.Count() = 0;
	// Get active special offers
	vOffersRoomRate = RoomRate;
	vOffersRoomRateType = RoomRateType;
	vOffersClientType = ClientType;
	vOffersSourceOfBusiness = SourceOfBusiness;
	vOffersMarketingCode = MarketingCode;
	vOffersRoomType = RoomType;
	vOffersAccommodationType = AccommodationType;
	vActiveOffers = New ValueTable();
	If Not TurnOffAutomaticDiscounts Then 
		vActiveOffers = cmGetConfirmedSpecialOffersForReservation(Ref, Hotel, vOffersRoomRate, vOffersRoomRateType, Guest, vOffersClientType, Customer, CustomerType, GuestGroup, vOffersSourceOfBusiness, vOffersMarketingCode, TripPurpose, CheckInDate, Duration, CheckOutDate, ?(ValueIsFilled(GuestGroup), ?(ValueIsFilled(GuestGroup.CreateDate), GuestGroup.CreateDate, Date), Date), vOffersRoomType, vOffersAccommodationType);
	EndIf;
	// Get list of price records for the given room rate
	vCurServicePackage = ServicePackage;
	vRoom = Room;
	vRoomRoomType = RoomType;
	vRoomType = RoomType;
	If ValueIsFilled(RoomTypeUpgrade) Then
		vRoomType = RoomTypeUpgrade;
	EndIf;
	vPricesAccommodationTemplate = AccommodationTemplate;
	If vIsForFolioSplit And Not IsBlankString(SharePercent) And ValueIsFilled(vMainRoomGuestAccommodationTemplate) Then
		If Hotel.SkipExtraBedsFromPriceSharing And vUseTemplateWithoutExtraBeds Then
			vPricesAccommodationTemplate = cmGetAccommodationTemplateForSkippedExtraBeds(vMainRoomGuestAccommodationTemplate);
		Else
			vPricesAccommodationTemplate = vMainRoomGuestAccommodationTemplate;
		EndIf;
	EndIf;
	vBasePrices = RoomRate.GetObject().pmGetRoomRatePrices(vCheckInDate, PriceCalculationDate, ClientType, vRoomType, AccommodationType, vServicePackagesList, , vCheckInDate, vCheckOutDate, , , vCalendarDayTypesList, , vPricesAccommodationTemplate, vIsForFolioSplitForPrices, vSplitPackagesByGuests, Not IsBlankString(SharePercent));
	If ValueIsFilled(ClientType) And (vBasePrices.Count() = 0 Or vBasePrices.FindRows(New Structure("IsRoomRevenue", True)).Count() = 0) Then
		vBasePrices = RoomRate.GetObject().pmGetRoomRatePrices(vCheckInDate, PriceCalculationDate, Catalogs.ClientTypes.EmptyRef(), vRoomType, AccommodationType, vServicePackagesList, , vCheckInDate, vCheckOutDate, , , vCalendarDayTypesList, , vPricesAccommodationTemplate, vIsForFolioSplitForPrices, vSplitPackagesByGuests, Not IsBlankString(SharePercent));
	EndIf;
	// Check if we have other room types specified in the charging rules
	vCRRoomTypePrices = New ValueTable();
	vCRRoomTypePrices.Columns.Add("RoomType", cmGetCatalogTypeDescription("RoomTypes"));
	vCRRoomTypePrices.Columns.Add("Prices");
	For Each vCRRow In vCRTab Do
		If TypeOf(vCRRow.ChargingRuleValue) = Type("CatalogRef.RoomTypes") And 
		   ValueIsFilled(vCRRow.ChargingRuleValue) Then
			If vCRRoomTypePrices.Find(vCRRow.ChargingRuleValue, "RoomType") = Undefined Then
				vCRRoomTypePricesRow = vCRRoomTypePrices.Add();
				vCRRoomTypePricesRow.RoomType = vCRRow.ChargingRuleValue;
				vCRRoomTypePricesTable = RoomRate.GetObject().pmGetRoomRatePrices(vCheckInDate, PriceCalculationDate, ClientType, vCRRoomTypePricesRow.RoomType, AccommodationType, vServicePackagesList, , vCheckInDate, vCheckOutDate, , , vCalendarDayTypesList, , vPricesAccommodationTemplate, vIsForFolioSplitForPrices, vSplitPackagesByGuests, Not IsBlankString(SharePercent));
				If ValueIsFilled(ClientType) And (vCRRoomTypePricesTable.Count() = 0 Or vCRRoomTypePricesTable.FindRows(New Structure("IsRoomRevenue", True)).Count() = 0) Then
					vCRRoomTypePricesTable = RoomRate.GetObject().pmGetRoomRatePrices(vCheckInDate, PriceCalculationDate, Catalogs.ClientTypes.EmptyRef(), vCRRoomTypePricesRow.RoomType, AccommodationType, vServicePackagesList, , vCheckInDate, vCheckOutDate, , , vCalendarDayTypesList, , vPricesAccommodationTemplate, vIsForFolioSplitForPrices, vSplitPackagesByGuests, Not IsBlankString(SharePercent));
				EndIf;
				vCRRoomTypePricesRow.Prices = vCRRoomTypePricesTable;
			EndIf;
		EndIf;
	EndDo;
	// Build value table of room rates per accounting days
	vRoomRates = pmGetAccommodationPlan();
	vRoomRates.Columns.Add("Prices");
	If vRoomRates.Count() > 0 Then
		vRoomRatesDimensions = vRoomRates.Copy();
		vCurAccommodationTemplate = AccommodationTemplate;
		For Each vRoomRatesDimensionsRow In vRoomRatesDimensions Do
			If ValueIsFilled(vRoomRatesDimensionsRow.AccommodationTemplate) Then
				vCurAccommodationTemplate = vRoomRatesDimensionsRow.AccommodationTemplate;
			Else
				vRoomRatesDimensionsRow.AccommodationTemplate = vCurAccommodationTemplate;
			EndIf;
		EndDo;
		vRoomRatesDimensions.GroupBy("RoomRate, ClientType, AccommodationType, RoomType, PriceCalculationDate, AccommodationTemplate, ServicePackage", );
		vRoomRatesDimensions.Columns.Add("Prices");
		For Each vRoomRatesDimensionsRow In vRoomRatesDimensions Do
			vDimensionRoomRate = ?(ValueIsFilled(vRoomRatesDimensionsRow.RoomRate), vRoomRatesDimensionsRow.RoomRate, RoomRate);
			vDimensionClientType = vRoomRatesDimensionsRow.ClientType;
			vDimensionServicePackage = vRoomRatesDimensionsRow.ServicePackage;
			vSkipMealBoardTerm = False;
			If Not vIsForFolioSplit And Not ValueIsFilled(AccommodationTemplate) And ValueIsFilled(RoomRate) And RoomRate.RateChargeDirection = Enums.RateChargeDirections.MergeToTheMainRoomGuest Then
				If ValueIsFilled(vDimensionServicePackage) And vDimensionServicePackage.IsMealBoardTerm Then
					vSkipMealBoardTerm = True;
				EndIf;
			EndIf;
			If Not vSkipMealBoardTerm Then
				vDimensionServicePackageIsFound = False;
				For Each vSPLItem In vServicePackagesList Do
					If TypeOf(vSPLItem.Value) = Type("Structure") Then
						If vSPLItem.Value.ServicePackage = vDimensionServicePackage Then
							vDimensionServicePackageIsFound = True;
							Break;
						EndIf;
					Else
						If vSPLItem.Value = vDimensionServicePackage Then
							vDimensionServicePackageIsFound = True;
							Break;
						EndIf;
					EndIf;
				EndDo;
				If Not vDimensionServicePackageIsFound Then
					s = 0;
					While s < vServicePackagesList.Count() Do
						vSPItem = vServicePackagesList.Get(s);
						vSPRef = Undefined;
						If TypeOf(vSPItem.Value) = Type("Structure") Then
							vSPRef = vSPItem.Value.ServicePackage;
						Else
							vSPRef = vSPItem.Value;
						EndIf;
						If ValueIsFilled(vSPRef) And vSPRef.IsMealBoardTerm Then
							vServicePackagesList.Delete(vSPItem);
						Else
							s = s + 1;
						EndIf;
					EndDo;
					vServicePackagesList.Add(New Structure("ServicePackage, Quantity, DateFrom, DateTo", vDimensionServicePackage, 1, '00010101', '39991231'));
				EndIf;
			EndIf;
			vDimensionAccommodationType = ?(ValueIsFilled(vRoomRatesDimensionsRow.AccommodationType), vRoomRatesDimensionsRow.AccommodationType, AccommodationType);
			vDimensionRoomType = ?(ValueIsFilled(vRoomRatesDimensionsRow.RoomType) And Not ValueIsFilled(RoomTypeUpgrade), vRoomRatesDimensionsRow.RoomType, vRoomType);
			vDimensionPriceCalculationDate = vRoomRatesDimensionsRow.PriceCalculationDate;
			vDimensionAccommodationTemplate = ?(ValueIsFilled(vRoomRatesDimensionsRow.AccommodationTemplate), vRoomRatesDimensionsRow.AccommodationTemplate, vMainRoomGuestAccommodationTemplate);
			If ValueIsFilled(vPricesAccommodationTemplate) And ValueIsFilled(vMainRoomGuestAccommodationTemplate) Then
				If vDimensionAccommodationTemplate = vMainRoomGuestAccommodationTemplate Then
					vDimensionAccommodationTemplate = vPricesAccommodationTemplate;
				Else
					If vIsForFolioSplit And Not IsBlankString(SharePercent) Then
						If Hotel.SkipExtraBedsFromPriceSharing And vUseTemplateWithoutExtraBeds Then
							vWrkDimensionAccommodationTemplate = cmGetAccommodationTemplateForSkippedExtraBeds(vDimensionAccommodationTemplate);
							If ValueIsFilled(vWrkDimensionAccommodationTemplate) Then
								vDimensionAccommodationTemplate = vWrkDimensionAccommodationTemplate;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			If vDimensionRoomRate = RoomRate And 
			   vDimensionPriceCalculationDate = PriceCalculationDate And 
			   vDimensionClientType = ClientType And 
			   vDimensionRoomType = vRoomType And 
			   vDimensionAccommodationType = AccommodationType And 
			   vDimensionAccommodationTemplate = vPricesAccommodationTemplate Then
				vRoomRatesDimensionsRow.Prices = vBasePrices;
				vRoomRatesDimensionsRow.PriceCalculationDate = PriceCalculationDate;
			Else
				vDimensionPrices = vDimensionRoomRate.GetObject().pmGetRoomRatePrices(vCheckInDate, vDimensionPriceCalculationDate, vDimensionClientType, vDimensionRoomType, vDimensionAccommodationType, vServicePackagesList, , vCheckInDate, vCheckOutDate, , , vCalendarDayTypesList, , vDimensionAccommodationTemplate, vIsForFolioSplitForPrices, vSplitPackagesByGuests, Not IsBlankString(SharePercent));
				If ValueIsFilled(vDimensionClientType) And (vDimensionPrices.Count() = 0 Or vDimensionPrices.FindRows(New Structure("IsRoomRevenue", True)).Count() = 0) Then
					vDimensionPrices = vDimensionRoomRate.GetObject().pmGetRoomRatePrices(vCheckInDate, vDimensionPriceCalculationDate, Catalogs.ClientTypes.EmptyRef(), vDimensionRoomType, vDimensionAccommodationType, vServicePackagesList, , vCheckInDate, vCheckOutDate, , , vCalendarDayTypesList, , vDimensionAccommodationTemplate, vIsForFolioSplitForPrices, vSplitPackagesByGuests, Not IsBlankString(SharePercent));
				EndIf;
				vRoomRatesDimensionsRow.Prices = vDimensionPrices;
				vRoomRatesDimensionsRow.PriceCalculationDate = vDimensionPriceCalculationDate;
			EndIf;
		EndDo;
		vCurAccommodationTemplate = AccommodationTemplate;
		For Each vRoomRatesRow In vRoomRates Do
			If ValueIsFilled(vRoomRatesRow.AccommodationTemplate) Then
				vCurAccommodationTemplate = vRoomRatesRow.AccommodationTemplate;
			EndIf;
			vRoomRatesDimensionsRows = vRoomRatesDimensions.FindRows(New Structure("RoomRate, ClientType, AccommodationType, RoomType, AccommodationTemplate, ServicePackage, PriceCalculationDate", vRoomRatesRow.RoomRate, vRoomRatesRow.ClientType, vRoomRatesRow.AccommodationType, vRoomRatesRow.RoomType, vCurAccommodationTemplate, vRoomRatesRow.ServicePackage, vRoomRatesRow.PriceCalculationDate));
			If vRoomRatesDimensionsRows.Count() > 0 Then
				vRoomRatesDimensionsRow = vRoomRatesDimensionsRows.Get(0);
				vRoomRatesRow.Prices = vRoomRatesDimensionsRow.Prices;
			EndIf;
		EndDo;
	EndIf;
	// Get complex commission
	vComplexCommission = pmGetComplexCommission();
	// Create discount type object
	vIsAmountDiscount = False;
	vUseDocumentDiscount = False;
	vFixedDiscount = Discount;
	vFixedDiscountTypeObj = Undefined;
	If ValueIsFilled(DiscountType) Then
		vFixedDiscountTypeObj = DiscountType.GetObject();
		If DiscountType.IsAmountDiscount Then
			vIsAmountDiscount = True;
			vUseDocumentDiscount = True;
		Else
			If Not DiscountType.IsAccumulatingDiscount And Not DiscountType.DifferentDiscountPercentsForServiceGroupsAllowed Then
				vFixedDiscountPercent = vFixedDiscountTypeObj.pmGetDiscount(CheckInDate, , Hotel);
				If vFixedDiscountPercent <> vFixedDiscount Then
					vUseDocumentDiscount = True;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	// Build value table of discount percents per days
	vDiscountPercents = New ValueTable();
	vDiscountPercents.Columns.Add("AccountingDate", cmGetDateTypeDescription());
	vDiscountPercents.Columns.Add("Discount", cmGetDiscountTypeDescription());
	// Build value table of discount percents per services
	vFixedServiceDiscount = 0;
	vFixedDiscountPercents = New ValueTable();
	vFixedDiscountPercents.Columns.Add("AccountingDate", cmGetDateTypeDescription());
	vFixedDiscountPercents.Columns.Add("Service", cmGetCatalogTypeDescription("Services"));
	vFixedDiscountPercents.Columns.Add("Discount", cmGetDiscountTypeDescription());
	vServices = vBasePrices.Copy(, "Service");
	vServices.GroupBy("Service", );
	// Get list of days with day types from room rate calendar
	vDays = RoomRate.Calendar.GetObject().pmGetDays(vCheckInDate, vCheckOutDate, , , vRoomType, PriceCalculationDate);
	If vCheckInDate >= vCheckOutDate Then
		vDays.Clear();
	Else
		If vDays.Count() > 0 And vDays.Count() <> ((BegOfDay(vCheckOutDate) - BegOfDay(vCheckInDate))/(24*3600) + 1) Then
			vDaysDate = BegOfDay(vCheckInDate);
			vPrevDaysRow = Undefined;
			i = 0;
			While vDaysDate <= BegOfDay(vCheckOutDate) Do
				vDaysRow = vDays.Find(vDaysDate, "Period");
				If vDaysRow <> Undefined Then
					vPrevDaysRow = vDaysRow;
					i = i + 1;
				ElsIf vPrevDaysRow <> Undefined Then
					vDaysRow = vDays.Insert(i);
					FillPropertyValues(vDaysRow, vPrevDaysRow);
					vDaysRow.Period = vDaysDate;
					i = i + 1;
				EndIf;
				vDaysDate = vDaysDate + 24*3600;
			EndDo;
		EndIf;
	EndIf;
	// Get contract service package included in the room rate
	vMealBoardTermIncluded = Undefined;
	vMealBoardTermIncludedServices = Undefined;
	If ValueIsFilled(Contract) And ValueIsFilled(Contract.MealBoardTerm) Then
		vMealBoardTermIncluded = Contract.MealBoardTerm;
		vMealBoardTermIncludedServices = Catalogs.ServicePackages.GetServices(vMealBoardTermIncluded, vCheckInDate, PriceCalculationDate);
	ElsIf ValueIsFilled(ServicePackage) And ServicePackage.IsMealBoardTerm Then
		vMealBoardTermIncluded = ServicePackage;
	EndIf;
	// Save contract meal board terms
	vContractMealBoardTerms = New ValueTable();
	vContractMealBoardTerms.Columns.Add("RoomType");
	vContractMealBoardTerms.Columns.Add("MealBoardTerm");
	vContractMealBoardTerms.Columns.Add("PriceCorrection");
	vContractMealBoardTerms.Columns.Add("CheckInDateFrom", cmGetDateTypeDescription());
	vContractMealBoardTerms.Columns.Add("CheckInDateTo", cmGetDateTypeDescription());
	vContractMealBoardTerms.Columns.Add("ReservationDateFrom", cmGetDateTypeDescription());
	vContractMealBoardTerms.Columns.Add("ReservationDateTo", cmGetDateTypeDescription());
	vContractMealBoardTerms.Columns.Add("PeriodOfStayFrom", cmGetDateTypeDescription());
	vContractMealBoardTerms.Columns.Add("PeriodOfStayTo", cmGetDateTypeDescription());
	If ValueIsFilled(Contract) Then
		vContractMealBoardTerms = Contract.MealBoardTerms.Unload();
	EndIf;
	// Active special offers
	vOfferByRoomTypeUpgradeDescription = "";
	vOfferByTermsUpgradeDescription = "";
	// Calculate quantity for each service from room rate
	i = 0;
	vFirstDayWithAccommodationService = True;
	vGuestsCheckedInIsSet = False;
	vFirstPeriod = Undefined;
	vRestOfCurAmount = 0;
	vRestOfServiceSum = 0;
	vChargingRuleAmountIsSet = False;
	vLastOccupationPercentRoomRate = Undefined;
	vLastOccupationPercentRoomType = Undefined;
	For Each vDayRow In vDays Do
		vCurAccountingDate = vDayRow.Period;
		If vFirstPeriod = Undefined Then
			vFirstPeriod = vCurAccountingDate;
		EndIf;
		If vGuestsCheckedInIsSet Then
			vFirstDayWithAccommodationService = False;
		EndIf;
		vCurCalendarDayType = vDayRow.CalendarDayType;
		vFixedPriceTag = vDayRow.PriceTag;
		vCurTimetable = vDayRow.Timetable;
		vCurPriceTag = Catalogs.PriceTags.EmptyRef();
		vCurRoomRateSrv = Undefined;
		vCurRoomRateSrvHasManualPrice = False;
		vCurRestOfRoomRateSrv = Undefined;
		// Build value table of discount percents per services
		If ValueIsFilled(DiscountType) Then
			If vCurAccountingDate >= DiscountType.DateValidFrom And 
			   (Not ValueIsFilled(DiscountType.DateValidTo) Or ValueIsFilled(DiscountType.DateValidTo) And vCurAccountingDate <= DiscountType.DateValidTo) Then
				If DiscountType.DifferentDiscountPercentsForServiceGroupsAllowed Then
					For Each vServicesRow In vServices Do
						If cmIsServiceInServiceGroup(vServicesRow.Service, DiscountServiceGroup) Then
							vFixedDiscountPercentsRow = vFixedDiscountPercents.Add();
							vFixedDiscountPercentsRow.AccountingDate = vCurAccountingDate;
							vFixedDiscountPercentsRow.Service = vServicesRow.Service;
							vFixedDiscountPercentsRow.Discount = vFixedDiscountTypeObj.pmGetDiscount(vCurAccountingDate, vServicesRow.Service, Hotel);
						EndIf;
					EndDo;
				Else
					vDiscountPercentsRow = vDiscountPercents.Add();
					vDiscountPercentsRow.AccountingDate = vCurAccountingDate;
					vDiscountPercentsRow.Discount = vFixedDiscountTypeObj.pmGetDiscount(vCurAccountingDate, , Hotel);
				EndIf;
			EndIf;
		EndIf;
		// Get prices for the current accounting date
		vPrices = vBasePrices;
		vRoomRate = RoomRate;
		vAccommodationType = AccommodationType;
		vAccommodationTemplate = AccommodationTemplate;
		vMealBoardTermServicePackage = Catalogs.ServicePackages.EmptyRef();
		If ValueIsFilled(ServicePackage) And ServicePackage.IsMealBoardTerm Then
			vMealBoardTermServicePackage = ServicePackage;
		EndIf;
		vClientType = ClientType;
		vSourceOfBusiness = SourceOfBusiness;
		vMarketingCode = MarketingCode;
		vBoardPlace = BoardPlace;
		vPriceCalculationDate = PriceCalculationDate;
		vRoomRatesRow = vRoomRates.Find(vCurAccountingDate, "AccountingDate");
		If vRoomRatesRow <> Undefined Then
			If vRoomRatesRow.Prices <> Undefined Then
				vPrices = vRoomRatesRow.Prices;
			EndIf;
			If ValueIsFilled(vRoomRatesRow.RoomType) And Not ValueIsFilled(RoomTypeUpgrade) Then
				vRoomType = vRoomRatesRow.RoomType;
			EndIf;
			If ValueIsFilled(vRoomRatesRow.RoomType) Then
				vRoomRoomType = vRoomRatesRow.RoomType;
			EndIf;
			If ValueIsFilled(vRoomRatesRow.Room) Then
				vRoom = vRoomRatesRow.Room;
			EndIf;
			If ValueIsFilled(vRoomRatesRow.PriceCalculationDate) Then
				vPriceCalculationDate = vRoomRatesRow.PriceCalculationDate;
			EndIf;
			If ValueIsFilled(vRoomRatesRow.RoomRate) Then
				vRoomRate = vRoomRatesRow.RoomRate;
				vFixedPriceTagByRoomType = Undefined;
				vCurCalendarDayType = cmGetCalendarDayType(vRoomRate, vCurAccountingDate, vCheckInDate, vCheckOutDate, vFixedPriceTagByRoomType, ?(ValueIsFilled(RoomTypeUpgrade), RoomTypeUpgrade, vRoomRoomType), vPriceCalculationDate);
				If ValueIsFilled(vFixedPriceTagByRoomType) Then
					vFixedPriceTag = vFixedPriceTagByRoomType;
				EndIf;
			EndIf;
			If ValueIsFilled(vRoomRatesRow.AccommodationType) Then
				vAccommodationType = vRoomRatesRow.AccommodationType;
			EndIf;
			If ValueIsFilled(vRoomRatesRow.AccommodationTemplate) Then
				vAccommodationTemplate = vRoomRatesRow.AccommodationTemplate;
			EndIf;
			If ValueIsFilled(vRoomRatesRow.ServicePackage) And vRoomRatesRow.ServicePackage.IsMealBoardTerm Then
				vMealBoardTermServicePackage = vRoomRatesRow.ServicePackage;
			EndIf;
			If ValueIsFilled(vRoomRatesRow.ClientType) Then
				vClientType = vRoomRatesRow.ClientType;
			EndIf;
			If ValueIsFilled(vRoomRatesRow.SourceOfBusiness) Then
				vSourceOfBusiness = vRoomRatesRow.SourceOfBusiness;
			EndIf;
			If ValueIsFilled(vRoomRatesRow.MarketingCode) Then
				vMarketingCode = vRoomRatesRow.MarketingCode;
			EndIf;
			If ValueIsFilled(vRoomRatesRow.BoardPlace) Then
				vBoardPlace = vRoomRatesRow.BoardPlace;
			EndIf;
			// Get active special offers
			If Not TurnOffAutomaticDiscounts And ValueIsFilled(vRoomRate) And ValueIsFilled(vRoomType) Then
				If vOffersRoomRate <> vRoomRate Or vOffersRoomRateType = vRoomRate.RoomRateType Or vOffersClientType <> vClientType Or
				   vOffersSourceOfBusiness <> vSourceOfBusiness Or vOffersMarketingCode <> vMarketingCode Or 
				   vOffersRoomType <> vRoomType Or vOffersAccommodationType <> vAccommodationType Then
					vOffersRoomRate = vRoomRate;
					vOffersRoomRateType = vRoomRate.RoomRateType;
					vOffersClientType = vClientType;
					vOffersSourceOfBusiness = vSourceOfBusiness;
					vOffersMarketingCode = vMarketingCode;
					vOffersRoomType = vRoomType;
					vOffersAccommodationType = vAccommodationType;
					vActiveOffers = cmGetConfirmedSpecialOffersForReservation(Ref, Hotel, vOffersRoomRate, vOffersRoomRateType, Guest, vOffersClientType, Customer, CustomerType, GuestGroup, vOffersSourceOfBusiness, vOffersMarketingCode, TripPurpose, CheckInDate, Duration, CheckOutDate, ?(ValueIsFilled(GuestGroup), ?(ValueIsFilled(GuestGroup.CreateDate), GuestGroup.CreateDate, Date), Date), vOffersRoomType, vOffersAccommodationType);
				EndIf;
			EndIf;
			// Update manual services for this date
			vMSRows = Services.FindRows(New Structure("AccountingDate, IsManual", vCurAccountingDate, True));
			For Each vMSRow In vMSRows Do
				vMSRow.RoomType = vRoomRoomType;
				vMSRow.Room = vRoom;
				vMSRow.AccommodationType = vAccommodationType;
				vMSRow.ClientType = vClientType;
				vMSRow.SourceOfBusiness = vSourceOfBusiness;
				vMSRow.MarketingCode = vMarketingCode;
			EndDo;
		EndIf;
		vDoesNotAffectRoomRevenueStatistics = False;
		If ValueIsFilled(vRoomRoomType) And vRoomRoomType.DoesNotAffectRoomRevenueStatistics And vRoomRoomType.ConnectedRoomTypes.Count() = 0 Then
			vDoesNotAffectRoomRevenueStatistics = vRoomRoomType.DoesNotAffectRoomRevenueStatistics;
		EndIf;
		// Leave offers active for the current date
		vOffers = vActiveOffers.Copy();
		vSOIdx = 0;
		While vSOIdx < vOffers.Count() Do
			vOffersRow = vOffers.Get(vSOIdx);
			If cmIsSpecialOfferActive(vOffersRow.SpecialOffer, vCurAccountingDate, Hotel) Then
				vSOIdx = vSOIdx + 1;
			Else
				vOffers.Delete(vSOIdx);
			EndIf;
		EndDo;
		// Check should we take price tags into account or not and 
		// try to find appropriate price tag for the current accounting date
		vPriceTagsAreUsed = False;
		vResetPriceTagPrices = False;
		If ValueIsFilled(vRoomRate) Then
			If ValueIsFilled(vRoomRate.BasedOnPriceTag) Then
				vCurPriceTag = vRoomRate.BasedOnPriceTag;
			EndIf;
			If ValueIsFilled(vRoomRate.PriceTagType) Then
				vPriceTagsAreUsed = True;
				If vRoomRate.PriceTagType = Enums.PriceTagTypes.ByDurationOfStayByDays Then
					// Check should we used saved price tags or not
					If BegOfDay(CheckInDate) <> BegOfDay(vSavCheckInDate) Or BegOfDay(CheckOutDate) <> BegOfDay(vSavCheckOutDate) Then
						vResetPriceTagPrices = True;
					EndIf;
					If IsNew() Then
						vResetPriceTagPrices = True;
					EndIf;
				ElsIf vRoomRate.PriceTagType = Enums.PriceTagTypes.ByDurationOfStayByPeriod Then
					// Check should we used saved price tags or not
					If BegOfDay(CheckInDate) <> BegOfDay(vSavCheckInDate) Or BegOfDay(CheckOutDate) <> BegOfDay(vSavCheckOutDate) Then
						vResetPriceTagPrices = True;
					EndIf;
					If IsNew() Then
						vResetPriceTagPrices = True;
					EndIf;
				ElsIf vRoomRate.PriceTagType = Enums.PriceTagTypes.ByOccupancyPercent Or 
					  vRoomRate.PriceTagType = Enums.PriceTagTypes.ByOccupancyPercentPerRoomType Or 
					  vRoomRate.PriceTagType = Enums.PriceTagTypes.ByOccupancyPercentPerRoomClass Or 
					  vRoomRate.PriceTagType = Enums.PriceTagTypes.ByOccupancyPercentPerRoomTypePerDayType Then
					// Check should we used saved price tags or not
					If BegOfDay(CheckInDate) <> BegOfDay(vSavCheckInDate) Or BegOfDay(CheckOutDate) <> BegOfDay(vSavCheckOutDate) Then
						vResetPriceTagPrices = True;
						vOccupationPercentsAreFilled = False;
						If vLastOccupationPercentRoomRate <> vRoomRate Or vLastOccupationPercentRoomType <> vRoomType Then
							If BegOfDay(vSavCheckOutDate) < BegOfDay(CheckOutDate) Then
								vOPRow = OccupationPercents.Find(BegOfDay(vSavCheckOutDate), "AccountingDate");
								If vOPRow <> Undefined Then
									OccupationPercents.Delete(OccupationPercents.IndexOf(vOPRow));
								EndIf;
							EndIf;
						EndIf;
					EndIf;
					If vOccupationPercentsAreFilled Then
						vCurDate = vBegOfCheckInDate;
						While vCurDate <= vBegOfCheckOutDate Do
							If OccupationPercents.Find(vCurDate, "AccountingDate") = Undefined Then
								vOccupationPercentsAreFilled = False;
								Break;
							EndIf;
							vCurDate = vCurDate + 24*3600;
						EndDo;
					EndIf;
					If Not vOccupationPercentsAreFilled And ValueIsFilled(vRoomRate) And ValueIsFilled(vRoomType) Then
						vOccupationPercentsAreFilled = True;
						If vLastOccupationPercentRoomRate <> vRoomRate Or vLastOccupationPercentRoomType <> vRoomType Then
							pmFillOccupationPercents(vBegOfCheckInDate, vBegOfCheckOutDate, vRoomRate, vRoomType);
							vLastOccupationPercentRoomRate = vRoomRate;
							vLastOccupationPercentRoomType = vRoomType;
						EndIf;
					EndIf;
					If IsNew() Then
						vResetPriceTagPrices = True;
					EndIf;
					If OccupationPercents.Count() = 0 Then
						vResetPriceTagPrices = True;
					EndIf;
				EndIf;
				vDayTypesRows = vDayTypes.FindRows(New Structure("AccountingDate, IsInPrice", vCurAccountingDate, True));
				If vResetPriceTagPrices Or vDayTypes.Count() = 0 Or vDayTypesRows.Count() = 0 Or vDayTypesRows.Count() > 0 And Not ValueIsFilled(vDayTypesRows.Get(0).PriceTag) Then
					vPriceTagRanges = cmGetPriceTagRanges(Hotel, vRoomRate.PriceTagType, vPriceCalculationDate);
					If vRoomRate.PriceTagType = Enums.PriceTagTypes.ByDurationOfStayByDays Then
						// Calculate price tag
						vCurDurationInDays = (vCurAccountingDate - vBegOfCheckInDate)/(24*3600) + 1;
						vCurDurationInDays = ?(vCurDurationInDays < 0, 0, vCurDurationInDays);
						For Each vPriceTagRangesRow In vPriceTagRanges Do
							If vPriceTagRangesRow.EndValueNotIncluded Then
								If vCurDurationInDays >= vPriceTagRangesRow.StartValue And vCurDurationInDays < vPriceTagRangesRow.EndValue Then
									vCurPriceTag = vPriceTagRangesRow.PriceTag;
									Break;
								EndIf;
							Else
								If vCurDurationInDays >= vPriceTagRangesRow.StartValue And vCurDurationInDays <= vPriceTagRangesRow.EndValue Then
									vCurPriceTag = vPriceTagRangesRow.PriceTag;
									Break;
								EndIf;
							EndIf;
						EndDo;
					ElsIf vRoomRate.PriceTagType = Enums.PriceTagTypes.ByDurationOfStayByPeriod Then
						// Calculate price tag
						vCurDurationInDays = (vBegOfCheckOutDate - vBegOfCheckInDate)/(24*3600);
						vCurDurationInDays = ?(vCurDurationInDays <= 0, 1, vCurDurationInDays);
						For Each vPriceTagRangesRow In vPriceTagRanges Do
							If vPriceTagRangesRow.EndValueNotIncluded Then
								If vCurDurationInDays >= vPriceTagRangesRow.StartValue And vCurDurationInDays < vPriceTagRangesRow.EndValue Then
									vCurPriceTag = vPriceTagRangesRow.PriceTag;
									Break;
								EndIf;
							Else
								If vCurDurationInDays >= vPriceTagRangesRow.StartValue And vCurDurationInDays <= vPriceTagRangesRow.EndValue Then
									vCurPriceTag = vPriceTagRangesRow.PriceTag;
									Break;
								EndIf;
							EndIf;
						EndDo;
					ElsIf vRoomRate.PriceTagType = Enums.PriceTagTypes.ByOccupancyPercent Or 
						  vRoomRate.PriceTagType = Enums.PriceTagTypes.ByOccupancyPercentPerRoomType Or 
						  vRoomRate.PriceTagType = Enums.PriceTagTypes.ByOccupancyPercentPerRoomClass Or 
						  vRoomRate.PriceTagType = Enums.PriceTagTypes.ByOccupancyPercentPerRoomTypePerDayType Then
						vCurOccupancyPercentRow = OccupationPercents.Find(vCurAccountingDate, "AccountingDate");
						If vCurOccupancyPercentRow <> Undefined Then
							vCurOccupancyPercent = vCurOccupancyPercentRow.OccupationPercent;
							For Each vPriceTagRangesRow In vPriceTagRanges Do
								If vPriceTagRangesRow.EndValueNotIncluded Then
									If vCurOccupancyPercent >= vPriceTagRangesRow.StartValue And vCurOccupancyPercent < vPriceTagRangesRow.EndValue Then
										vCurPriceTag = vPriceTagRangesRow.PriceTag;
										Break;
									EndIf;
								Else
									If vCurOccupancyPercent >= vPriceTagRangesRow.StartValue And vCurOccupancyPercent <= vPriceTagRangesRow.EndValue Then
										vCurPriceTag = vPriceTagRangesRow.PriceTag;
										Break;
									EndIf;
								EndIf;
							EndDo;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		// Fixed price tag
		If ValueIsFilled(vRoomRate) And ValueIsFilled(vRoomRate.BasedOnPriceTag) Then
			vPriceTagsAreUsed = True;
		EndIf;
		If vPriceTagsAreUsed And ValueIsFilled(vFixedPriceTag) Then
			vCurPriceTag = vFixedPriceTag;
		EndIf;
		// Try to restore old calendar day type and old price tag values
		vCalendarDayTypeIsChanged = False;
		If vDayTypes.Count() > 0 And Not vRoomRate.Calendar.IsPerPeriod Then
			// Search old service with the same accounting date
			vDayTypeRows = vDayTypes.FindRows(New Structure("AccountingDate", vCurAccountingDate));
			For Each vDayTypeRow In vDayTypeRows Do
				If vPriceTagsAreUsed And Not vResetPriceTagPrices And ValueIsFilled(vDayTypeRow.PriceTag) Then
					vCurPriceTag = vDayTypeRow.PriceTag;
					If vDayTypeRow.CalendarDayTypeIsChanged Then
						vCalendarDayTypeIsChanged = True;
					EndIf;
				EndIf;
				If ValueIsFilled(vDayTypeRow.CalendarDayType) And vDayTypeRow.RoomRate = vRoomRate Then
					vCurCalendarDayType = vDayTypeRow.CalendarDayType;
					If vDayTypeRow.CalendarDayTypeIsChanged Then
						vCalendarDayTypeIsChanged = True;
					EndIf;
				EndIf;
				If vDayTypeRow.IsRoomRevenue And vDayTypeRow.IsInPrice Then
					Break;
				EndIf;
			EndDo;
		EndIf;
		// Discounts to price correction by terms
		vDoNotApplyDiscountsToPriceCorrection = False;
		If ValueIsFilled(DiscountType) And DiscountType.DoNotApplyToTerms Then
			vDoNotApplyDiscountsToPriceCorrection = True;
		EndIf;
		// Process each row in prices
		If ValueIsFilled(vRoomRate) And vRoomRate.UsePricesFromCalendar Then
			vPricesRowsByDayTypeAndPriceTag = vPrices.FindRows(New Structure("AccountingDate, PriceTag", vDayRow.Period, vCurPriceTag));
			// Add rows with empty accounting date (normally from packages)
			vUsedCalendarDayTypesList = New ValueList();
			For Each vPricesRowsByDayTypeAndPriceTagRow In vPricesRowsByDayTypeAndPriceTag Do
				If ValueIsFilled(vPricesRowsByDayTypeAndPriceTagRow.CalendarDayType) Then
					If vUsedCalendarDayTypesList.FindByValue(vPricesRowsByDayTypeAndPriceTagRow.CalendarDayType) = Undefined Then
						vUsedCalendarDayTypesList.Add(vPricesRowsByDayTypeAndPriceTagRow.CalendarDayType);
					EndIf;
				EndIf;
			EndDo;
			For Each vUsedCalendarDayTypesListItem In vUsedCalendarDayTypesList Do
				vPricesRowsByUsedDayType = vPrices.FindRows(New Structure("CalendarDayType, AccountingDate", vUsedCalendarDayTypesListItem.Value, '00010101'));
				For Each vPricesRowByUsedDayType In vPricesRowsByUsedDayType Do
					vPricesRowsByDayTypeAndPriceTag.Add(vPricesRowByUsedDayType);
				EndDo;
			EndDo;
			vPricesRowsByEmptyDayType = vPrices.FindRows(New Structure("CalendarDayType, AccountingDate", Catalogs.CalendarDayTypes.EmptyRef(), '00010101'));
			For Each vPricesRowByEmptyDayType In vPricesRowsByEmptyDayType Do
				vPricesRowsByDayTypeAndPriceTag.Add(vPricesRowByEmptyDayType);
			EndDo;
		Else
			vPricesRowsByDayTypeAndPriceTag = vPrices.FindRows(New Structure("CalendarDayType, PriceTag", vCurCalendarDayType, vCurPriceTag));
			vPricesRowsByEmptyDayType = vPrices.FindRows(New Structure("CalendarDayType", Catalogs.CalendarDayTypes.EmptyRef()));
			For Each vPricesRowByEmptyDayType In vPricesRowsByEmptyDayType Do
				vPricesRowsByDayTypeAndPriceTag.Add(vPricesRowByEmptyDayType);
			EndDo;
		EndIf;
		For Each vPricesRow In vPricesRowsByDayTypeAndPriceTag Do
			vCurService = vPricesRow.Service;
			vCurIsRoomRevenue = vPricesRow.IsRoomRevenue;
			vCurRoomRevenueAmountsOnly = ?(vDoesNotAffectRoomRevenueStatistics, vDoesNotAffectRoomRevenueStatistics, vPricesRow.RoomRevenueAmountsOnly);
			vCurIsInPrice = vPricesRow.IsInPrice;
			vCurServicePackage = vPricesRow.ServicePackage;
			vCurServicePackageUsageType = vPricesRow.ServicePackageUsageType;
			If vCurIsRoomRevenue And vCurIsInPrice And Not vCurRoomRevenueAmountsOnly And ValueIsFilled(vMealBoardTermServicePackage) Then 
				If ValueIsFilled(vMealBoardTermServicePackage.RoomRevenueService) And vCurService <> vMealBoardTermServicePackage.RoomRevenueService And vCurService.IsInPrice Then
					vCurService = vMealBoardTermServicePackage.RoomRevenueService;
				EndIf;
				vCurServicePackage = vMealBoardTermServicePackage;
				vCurServicePackageUsageType = vMealBoardTermServicePackage.UsageType;
			EndIf;
			vCurAccountingDate = vDayRow.Period;
			vCurNumberOfPersons = vPricesRow.NumberOfPersonsInRoom;
			vCurNumberOfRooms = vPricesRow.NumberOfRooms;
			vCurNumberOfBeds = vPricesRow.NumberOfBeds;
			vCurNumberOfAdditionalBeds = vPricesRow.NumberOfAdditionalBeds;
			vCurAccommodationType = vPricesRow.AccommodationType;
			vPricesRowServicePackage = vPricesRow.ServicePackage;
			// Check price tags
			If vPriceTagsAreUsed Then
				If vCurPriceTag <> vPricesRow.PriceTag And Not ValueIsFilled(vCurServicePackage) 
					Or vCurPriceTag <> vPricesRow.PriceTag And ValueIsFilled(vCurServicePackage) And ValueIsFilled(vPricesRow.PriceTag) Then
					Continue;
				EndIf;
			ElsIf ValueIsFilled(vPricesRow.PriceTag) Then
				Continue;
			EndIf;
			// Retrieve current fixed discount
			vFixedServiceDiscount = 0;
			If Not vUseDocumentDiscount Then
				If vFixedDiscountPercents.Count() > 0 Then
					vFixedDiscountPercentsRows = vFixedDiscountPercents.FindRows(New Structure("Service, AccountingDate", vCurService, vCurAccountingDate));
					If vFixedDiscountPercentsRows.Count() > 0 Then
						vFixedDiscountPercentsRow = vFixedDiscountPercentsRows.Get(0);
						vFixedServiceDiscount = vFixedDiscountPercentsRow.Discount;
					EndIf;
				ElsIf vDiscountPercents.Count() > 0 Then
					vDiscountPercentsRows = vDiscountPercents.FindRows(New Structure("AccountingDate", vCurAccountingDate));
					If vDiscountPercentsRows.Count() > 0 Then
						vDiscountPercentsRow = vDiscountPercentsRows.Get(0);
						vFixedDiscount = vDiscountPercentsRow.Discount;
					Else
						vFixedDiscount = 0;
					EndIf;
				EndIf;
			EndIf;
			// Check if we should do fee charge only
			If ValueIsFilled(vCurFeeTerms) And (vDoNoShowCharging Or vDoLateAnnulationCharging) Then
				If vDoNoShowCharging Then
					If vCurFeeTerms.NoShowChargeInPrice And Not vCurIsInPrice Then
						Continue;
					ElsIf Not vCurFeeTerms.NoShowChargeInPrice And Not vCurIsRoomRevenue Then
						Continue;
					EndIf;
					If Not vCurFeeTerms.NoShowChargeWholePeriod Then
						If vCurFeeTerms.NoShowChargeNDays = 0 Then
							If vFirstPeriod <> vCurAccountingDate Then
								Continue;
							EndIf;
						Else
							If (vCurAccountingDate - vBegOfCheckInDate)/(24*3600) >= vCurFeeTerms.NoShowChargeNDays Then
								Continue;
							EndIf;
						EndIf;
					EndIf;
					If ValueIsFilled(vCurFeeTerms.NoShowService) Then
						vCurService = vCurFeeTerms.NoShowService;
						vCurIsRoomRevenue = vCurService.IsRoomRevenue;
						vCurRoomRevenueAmountsOnly = ?(vDoesNotAffectRoomRevenueStatistics, vDoesNotAffectRoomRevenueStatistics, vCurService.RoomRevenueAmountsOnly);
						vCurIsInPrice = vCurService.IsInPrice;
					EndIf;
				ElsIf vDoLateAnnulationCharging Then
					If vCurFeeTerms.LateAnnulationChargeInPrice And Not vCurIsInPrice Then
						Continue;
					ElsIf Not vCurFeeTerms.LateAnnulationChargeInPrice And Not vCurIsRoomRevenue Then
						Continue;
					EndIf;
					If Not vCurFeeTerms.LateAnnulationChargeWholePeriod And (vFirstPeriod <> vCurAccountingDate) Then
						Continue;
					EndIf;
					If ValueIsFilled(vCurFeeTerms.LateAnnulationService) Then
						vCurService = vCurFeeTerms.LateAnnulationService;
						vCurIsRoomRevenue = vCurService.IsRoomRevenue;
						vCurRoomRevenueAmountsOnly = ?(vDoesNotAffectRoomRevenueStatistics, vDoesNotAffectRoomRevenueStatistics, vCurService.RoomRevenueAmountsOnly);
						vCurIsInPrice = vCurService.IsInPrice;
					EndIf;
				EndIf;
			Else
				If ValueIsFilled(ReservationStatus) And Not ReservationStatus.IsActive And 
				  (ReservationStatus.DoNoShowCharging Or ReservationStatus.DoLateAnnulationCharging) Then
					Break;
				EndIf;
			EndIf;
			// Check that service fit to the room rate service group
			If cmIsServiceInServiceGroup(vCurService, RoomRateServiceGroup) Then
				If (vCurCalendarDayType = vPricesRow.CalendarDayType) 
					Or (vPricesRow.CalendarDayType = Catalogs.CalendarDayTypes.EmptyRef() And (ValueIsFilled(vPricesRow.QuantityCalculationRule) 
						Or vPricesRow.AccountingDayNumber = 0 And vCurAccountingDate = BegOfDay(vPricesRow.AccountingDate) 
						Or vPricesRow.AccountingDayNumber = 9999 And vCurAccountingDate = vBegOfCheckOutDate 
						Or vPricesRow.AccountingDayNumber <> 0 And vCurAccountingDate = (vBegOfCheckInDate + (vPricesRow.AccountingDayNumber - 1) * 24 * 3600) 
						Or Not ValueIsFilled(vPricesRow.QuantityCalculationRule) And Not ValueIsFilled(vPricesRow.AccountingDate) And vPricesRow.AccountingDayNumber = 0)) Then  
					 
					If vPricesRow.AccountingDayNumber <> 0 And vPricesRow.AccountingDayNumber <> 9999 And vCurAccountingDate <> (vBegOfCheckInDate + (vPricesRow.AccountingDayNumber - 1) * 24 * 3600) 
						Or vPricesRow.AccountingDayNumber = 9999 And vCurAccountingDate <> vBegOfCheckOutDate Then
						Continue;
					EndIf; 
					// Check accounting date time for service package
					If ValueIsFilled(vPricesRow.AccountingDate) And vPricesRow.AccountingDate <> BegOfDay(vPricesRow.AccountingDate) Then
						If BegOfDay(CheckInDate) = BegOfDay(vPricesRow.AccountingDate) And vPricesRow.AccountingDate <= CheckInDate Then
							Continue;
						EndIf;
						If BegOfDay(CheckOutDate) = BegOfDay(vPricesRow.AccountingDate) And vPricesRow.AccountingDate >= CheckOutDate Then
							Continue;
						EndIf;
					EndIf;
					// Check service package service period
					If ValueIsFilled(vPricesRow.ServicePackagePeriodFrom) Or ValueIsFilled(vPricesRow.ServicePackagePeriodTo) Then
						If vPricesRow.ServicePackagePeriodFrom > vCurAccountingDate Or (ValueIsFilled(vPricesRow.ServicePackagePeriodTo) And vPricesRow.ServicePackagePeriodTo < vCurAccountingDate) Then
							Continue;
						EndIf;
					EndIf;
					// Save current price
					vCurPrice = vPricesRow.Price;
					vCurCurrency = vPricesRow.Currency;
					vCurUnit = vPricesRow.Unit;
					vRestOfCurPrice = 0;
					// Check manual prices. Use it if one will be found.
					vDoNotRoundPrice = False;
					vIsManualPrice = cmGetManualPrice(vMPTab, vPricesRow.Service, vCurPrice, vCurCurrency, vCurUnit, vCurCalendarDayType, vPricesRow.Remarks);
					If vPricesRow.IsRoomRevenue And vPricesRow.IsInPrice Then
						If vIsManualPrice Then
							vDoNotRoundPrice = True;
						EndIf;							
						If Not vIsManualPrice And ValueIsFilled(vRoomType) And ValueIsFilled(AccommodationTemplate) Then
							vProbeRoomType = vRoomType;
							If ValueIsFilled(RoomTypeUpgrade) Then
								vProbeRoomType = RoomTypeUpgrade;
							EndIf;
							If ValueIsFilled(RoomQuota) And RoomQuota.RoomTypes.Count() > 0 Then
								vWrkPrice = 0;
								vRMPRows = RoomQuota.RoomTypes.FindRows(New Structure("RoomType, NumberOfAdults, NumberOfTeenagers, NumberOfChildren, NumberOfInfants", vProbeRoomType, ?(RoomQuantity > 0, NumberOfAdults/RoomQuantity, NumberOfAdults), ?(RoomQuantity > 0, NumberOfTeenagers/RoomQuantity, NumberOfTeenagers), ?(RoomQuantity > 0, NumberOfChildren/RoomQuantity, NumberOfChildren), ?(RoomQuantity > 0, NumberOfInfants/RoomQuantity, NumberOfInfants)));
								p = vRMPRows.Count() - 1;
								While p >= 0 Do
									vRMPRow = vRMPRows.Get(p);
									If vRMPRow.Price <> 0 Then
										If BegOfDay(vRMPRow.PeriodFrom) <= vCurAccountingDate And BegOfDay(vRMPRow.PeriodTo) > vCurAccountingDate Then
											vWrkPrice = cmConvertCurrencies(vRMPRow.Price, vRMPRow.Currency, , vCurCurrency, , vCurAccountingDate, Hotel);
											vDoNotRoundPrice = True;
											Break;
										EndIf;
									EndIf;
									p = p - 1;
								EndDo;
								// Update main accommodation price if neccessary
								If vWrkPrice <> 0 Then
									If vCurRoomRateSrv = Undefined Then
										vCurPrice = vWrkPrice;
									Else
										vCurRoomRateSrv.Price = vCurRoomRateSrv.Price - vCurPrice;
										vCurRoomRateSrv.Sum = Round(vCurRoomRateSrv.Price * vCurRoomRateSrv.Quantity, 2);
										// Calculate discounts
										pmCalculateServiceDiscounts(vCurRoomRateSrv);
										// Recalculate VAT sum
										vCurRoomRateSrv.VATSum = cmCalculateVATSum(vCurRoomRateSrv.VATRate, vCurRoomRateSrv.Sum, vCurRoomRateSrv.AccountingDate);
										// Calculate commission for this service if applicable
										pmSetServiceCommissions(vCurRoomRateSrv, vRoomRates, vComplexCommission);
									EndIf;
								EndIf;
							EndIf;
							If ValueIsFilled(GuestGroup) And GuestGroup.InitialBlock.Count() > 0 Then
								vWrkPrice = 0;
								vGMPRows = GuestGroup.InitialBlock.FindRows(New Structure("NumberOfAdults, NumberOfTeenagers, NumberOfChildren, NumberOfInfants", ?(RoomQuantity > 0, NumberOfAdults/RoomQuantity, NumberOfAdults), ?(RoomQuantity > 0, NumberOfTeenagers/RoomQuantity, NumberOfTeenagers), ?(RoomQuantity > 0, NumberOfChildren/RoomQuantity, NumberOfChildren), ?(RoomQuantity > 0, NumberOfInfants/RoomQuantity, NumberOfInfants)));
								For Each vGMPRow In vGMPRows Do
									If vGMPRow.Price <> 0 And (Not ValueIsFilled(vGMPRow.RoomType) Or ValueIsFilled(vGMPRow.RoomType) And (vGMPRow.RoomType = vProbeRoomType Or vGMPRow.RoomType.IsFolder And vProbeRoomType.BelongsToItem(vGMPRow.RoomType))) Then
										If BegOfDay(vGMPRow.CheckInDate) = BegOfDay(CheckInDate) And BegOfDay(vGMPRow.CheckOutDate) = BegOfDay(CheckOutDate) Then
											vWrkPrice = cmConvertCurrencies(vGMPRow.Price, vGMPRow.Currency, , vCurCurrency, , vCurAccountingDate, Hotel);
											vDoNotRoundPrice = True;
											Break;
										EndIf;
									EndIf;
								EndDo;
								If vWrkPrice = 0 Then
									For Each vGMPRow In vGMPRows Do
										If vGMPRow.Price <> 0 And (Not ValueIsFilled(vGMPRow.RoomType) Or ValueIsFilled(vGMPRow.RoomType) And (vGMPRow.RoomType = vProbeRoomType Or vGMPRow.RoomType.IsFolder And vProbeRoomType.BelongsToItem(vGMPRow.RoomType))) Then
											If BegOfDay(vGMPRow.CheckInDate) <= vCurAccountingDate And BegOfDay(vGMPRow.CheckOutDate) > vCurAccountingDate Then
												vWrkPrice = cmConvertCurrencies(vGMPRow.Price, vGMPRow.Currency, , vCurCurrency, , vCurAccountingDate, Hotel);
												vDoNotRoundPrice = True;
												Break;
											EndIf;
										EndIf;
									EndDo;
								EndIf;
								// Update main accommodation price if neccessary
								If vWrkPrice <> 0 Then
									If vCurRoomRateSrv = Undefined Then
										vCurPrice = vWrkPrice;
									Else
										vCurRoomRateSrv.Price = vCurRoomRateSrv.Price - vCurPrice;
										vCurRoomRateSrv.Sum = Round(vCurRoomRateSrv.Price * vCurRoomRateSrv.Quantity, 2);
										// Calculate discounts
										pmCalculateServiceDiscounts(vCurRoomRateSrv);
										// Recalculate VAT sum
										vCurRoomRateSrv.VATSum = cmCalculateVATSum(vCurRoomRateSrv.VATRate, vCurRoomRateSrv.Sum, vCurRoomRateSrv.AccountingDate);
										// Calculate commission for this service if applicable
										pmSetServiceCommissions(vCurRoomRateSrv, vRoomRates, vComplexCommission);
									EndIf;
								EndIf;
							EndIf;
						EndIf;
					ElsIf Not vPricesRow.IsInPrice Then
						If ValueIsFilled(vRoomRate) And ValueIsFilled(vCurService) And 
						   vCurService <> vRoomRate.EarlyCheckInService And vCurService <> vRoomRate.LateCheckOutService Then
							vDoNotRoundPrice = True;
						EndIf;
					EndIf;
					// Check charging rules
					vRoomRevenuePriceByRoomType = False;
					For Each vCRRow In vCRTab Do
						vCurAccountingDate = vDayRow.Period;
						vCurIsInRate = True;
						vCurQuantityCalculationRule = vPricesRow.QuantityCalculationRule;
						If ValueIsFilled(vCurQuantityCalculationRule) And 
						  (vCurQuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.ResortFeeRu2018 Or 
						   vCurQuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.ResortFeeRu2018CO Or 
						   vCurQuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.ResortFeeRu2022) Then
							vCurIsInRate = False;
						EndIf;
						vCurIsSplit = False;
						vNoDiscounts = False;
						// Check if current service fit to the current charging rule
						If cmIsServiceFitToTheChargingRule(vCRRow, vCurService, vCurAccountingDate, vCurIsInRate, vCurIsRoomRevenue) Then
							// Check charging rule and do price correction if necessary
							If vCRRow.ChargingRule = Enums.ChargingRuleTypes.RoomRevenuePrice Then
								If TypeOf(vCRRow.ChargingRuleValue) = Type("Number") Then
									If vCRRow.ChargingRuleValue <> 0 Then
										If vCRRow.ChargingRuleValue < vPricesRow.Price Then
											vRestOfCurPrice = vCurPrice - vCRRow.ChargingRuleValue;
											vCurPrice = vCRRow.ChargingRuleValue;
										EndIf;
									Else
										Continue;
									EndIf;
								Else
									Continue;
								EndIf;
							ElsIf vCRRow.ChargingRule = Enums.ChargingRuleTypes.RoomRevenuePricePercent Then
								If TypeOf(vCRRow.ChargingRuleValue) = Type("Number") Then
									If vCRRow.ChargingRuleValue > 0 And vCRRow.ChargingRuleValue < 100 Then
										vSavCurPrice = vCurPrice;	
										vCurPrice = Round(vCurPrice * vCRRow.ChargingRuleValue / 100, 2);
										vRestOfCurPrice = vSavCurPrice - vCurPrice;
									Else
										Continue;
									EndIf;
								Else
									Continue;
								EndIf;
							ElsIf vCRRow.ChargingRule = Enums.ChargingRuleTypes.RoomRevenueAmount Then
								If TypeOf(vCRRow.ChargingRuleValue) = Type("Number") Then
									If vCRRow.ChargingRuleValue > 0 Then
										If Not vChargingRuleAmountIsSet Then
											vChargingRuleAmountIsSet = True;
											vRestOfCurAmount = vCRRow.ChargingRuleValue;
										EndIf;
										If vRestOfCurAmount <= 0 Then
											Continue;
										EndIf;
									Else
										Continue;
									EndIf;
								Else
									Continue;
								EndIf;
							ElsIf vCRRow.ChargingRule = Enums.ChargingRuleTypes.RoomRevenuePriceByRoomType Then
								If TypeOf(vCRRow.ChargingRuleValue) = Type("CatalogRef.RoomTypes") Then
									vCRRoomTypePricesRow = vCRRoomTypePrices.Find(vCRRow.ChargingRuleValue, "RoomType");
									If vCRRoomTypePricesRow <> Undefined Then
										vCRPrices = vCRRoomTypePricesRow.Prices;
										// Process each row in new prices
										vCurCRPrice = 0;
										vCurCRPriceIsFound = False;
										For Each vCRPricesRow In vCRPrices Do
											vCurCRService = vCRPricesRow.Service;
											vCurCRIsRoomRevenue = vCRPricesRow.IsRoomRevenue;
											vCurCRRoomRevenueAmountsOnly = vCRPricesRow.RoomRevenueAmountsOnly;
											vCurCRIsInPrice = vCRPricesRow.IsInPrice;
											// Check service package period
											If ValueIsFilled(vCRPricesRow.ServicePackage) Then
												If BegOfDay(vCheckInDate) < vCRPricesRow.ServicePackageDateValidFrom Or 
												   ValueIsFilled(vCRPricesRow.ServicePackageDateValidTo) And BegOfDay(vCheckInDate) > vCRPricesRow.ServicePackageDateValidTo Then
													Continue;
												EndIf;
												If vCurAccountingDate < vCRPricesRow.ServicePackageDateFrom Or 
												   ValueIsFilled(vCRPricesRow.ServicePackageDateTo) And vCurAccountingDate > vCRPricesRow.ServicePackageDateTo Then
													Continue;
												EndIf;
											EndIf;
											// Check that service fit to the room rate service group
											If cmIsServiceInServiceGroup(vCurCRService, RoomRateServiceGroup) Then
												If (vCurCalendarDayType = vCRPricesRow.CalendarDayType) Or 
												   (vCRPricesRow.CalendarDayType = Catalogs.CalendarDayTypes.EmptyRef() And 
												    (ValueIsFilled(vCRPricesRow.QuantityCalculationRule) Or 
												     vCRPricesRow.AccountingDayNumber = 0 And vCurAccountingDate = BegOfDay(vCRPricesRow.AccountingDate) Or 
												     vCRPricesRow.AccountingDayNumber = 9999 And vCurAccountingDate = vBegOfCheckOutDate Or 
												     vCRPricesRow.AccountingDayNumber <> 0 And vCurAccountingDate = (vBegOfCheckInDate + (vCRPricesRow.AccountingDayNumber - 1)*24*3600) Or 
												     Not ValueIsFilled(vCRPricesRow.QuantityCalculationRule) And Not ValueIsFilled(vCRPricesRow.AccountingDate) And vCRPricesRow.AccountingDayNumber = 0)) Then
													// Check accounting date time for service package
													If ValueIsFilled(vCRPricesRow.AccountingDate) And vCRPricesRow.AccountingDate <> BegOfDay(vCRPricesRow.AccountingDate) Then
														If BegOfDay(CheckInDate) = BegOfDay(vCRPricesRow.AccountingDate) And vCRPricesRow.AccountingDate <= CheckInDate Then
															Continue;
														EndIf;
														If BegOfDay(CheckOutDate) = BegOfDay(vCRPricesRow.AccountingDate) And vCRPricesRow.AccountingDate >= CheckOutDate Then
															Continue;
														EndIf;
													EndIf;
													// Check service package service period
													If ValueIsFilled(vCRPricesRow.ServicePackagePeriodFrom) Or ValueIsFilled(vCRPricesRow.ServicePackagePeriodTo) Then
														If vCRPricesRow.ServicePackagePeriodFrom > vCurAccountingDate Or (ValueIsFilled(vCRPricesRow.ServicePackagePeriodTo) And vCRPricesRow.ServicePackagePeriodTo < vCurAccountingDate) Then
															Continue;
														EndIf;
													EndIf;
													// Save current price
													vCurCRPrice = vCRPricesRow.Price;
													vCurCRPriceIsFound = True;
													Break;
												EndIf;
											EndIf;
										EndDo;
										If vCurCRPriceIsFound Then
											If vCurCRPrice < vPricesRow.Price Then
												vRestOfCurPrice = vCurPrice - vCurCRPrice;
												vCurPrice = vCurCRPrice;
												vRoomRevenuePriceByRoomType = True;
											EndIf;
										EndIf;
									EndIf;
								Else
									Continue;
								EndIf;
							ElsIf vCRRow.ChargingRule = Enums.ChargingRuleTypes.RestOfRoomRevenuePrice Then
								If vChargingRuleAmountIsSet Then
									If vRestOfServiceSum > 0 Then
										Continue;
									EndIf;
								Else
									If vRestOfCurPrice <> 0 Then
										vCurPrice = vRestOfCurPrice;
										vRestOfCurPrice = 0;
										vCurIsSplit = True;
										If vRoomRevenuePriceByRoomType Then
											vNoDiscounts = True;
										EndIf;
									Else
										Continue;
									EndIf;
								EndIf;
							EndIf;
							// Check folio
							vCurFolio = vCRRow.ChargingFolio;
							If Not ValueIsFilled(vCurFolio) Then
								Continue;
							EndIf;
							vCurFolioCurrency = vCurFolio.FolioCurrency;
							vCurFolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, vCurFolioCurrency, ?(ValueIsFilled(vCurAccountingDate), vCurAccountingDate, ExchangeRateDate));
							vCompany = Company;
							If ValueIsFilled(vCurFolio.Company) And vCurFolio.DoNotUpdateCompany Then
								vCompany = vCurFolio.Company;
							EndIf;
							vCurVATRate = ?(vCompany.IsUsingSimpleTaxSystem, vCompany.VATRate, vPricesRow.VATRate);
							vCurMinQuantity = vPricesRow.MinimumQuantity;
							vCurRemarks = "";
							vOccParams = Undefined;
							vSrvAccountingDate = vCurAccountingDate;
							// Calculate quantity
							vCurQuantity = cmCalculateServiceQuantity(vPricesRow.Service, vCurQuantityCalculationRule, 
							                                          vCurAccountingDate, vCheckInDate, vCheckOutDate, 
							                                          ThisObject, ThisObject, True, True, False, False, True, True, 
							                                          vCurPrice, vCurCurrency, vCurRemarks, , vCurMinQuantity, vAccommodationPeriods, vOccParams);
							If vCurCurrency <> vCurFolioCurrency Then
								vCurPriceInFolioCurrency = Round(cmConvertCurrencies(vCurPrice, vCurCurrency, , vCurFolioCurrency, vCurFolioCurrencyExchangeRate, ?(ValueIsFilled(vCurAccountingDate), vCurAccountingDate, ExchangeRateDate), Hotel), 2);
							Else
								vCurPriceInFolioCurrency = vCurPrice;
							EndIf;
							vCurQuantity = vCurQuantity * vPricesRow.Quantity;
							// Take number of persons and room quantity into account
							vCurSrvQuantity = vCurQuantity;
							If vPricesRow.IsPricePerPerson Then
								vCurQuantity = vCurQuantity * NumberOfPersons;
							Else
								vCurQuantity = vCurQuantity * RoomQuantity;
							EndIf;
							// Fill remarks
							If Not IsBlankString(vPricesRow.Remarks) Then
								vCurRemarks = vPricesRow.Remarks;
							EndIf;
							// Check service package period
							If ValueIsFilled(vPricesRowServicePackage) Then
								If BegOfDay(vCheckInDate) < vPricesRow.ServicePackageDateValidFrom Or 
								   ValueIsFilled(vPricesRow.ServicePackageDateValidTo) And BegOfDay(vCheckInDate) > vPricesRow.ServicePackageDateValidTo Then
									Continue;
								EndIf;
								If vSrvAccountingDate < vPricesRow.ServicePackageDateFrom Or 
								   ValueIsFilled(vPricesRow.ServicePackageDateTo) And vSrvAccountingDate > vPricesRow.ServicePackageDateTo Then
									Continue;
								EndIf;
							EndIf;
							// Check if we should do no show or late annulation charge only
							If ValueIsFilled(vCurFeeTerms) And (vDoNoShowCharging Or vDoLateAnnulationCharging) Then
								If vDoNoShowCharging And ValueIsFilled(vCurFeeTerms.NoShowService) Or 
								   vDoLateAnnulationCharging And ValueIsFilled(vCurFeeTerms.LateAnnulationService) Then
									vCurSrvAttrs = vCurService.GetObject().pmGetServicePrices(Hotel, vCurAccountingDate, ClientType);
									If vCurSrvAttrs.Count() > 0 Then
										vCurSrvAttrsRow = vCurSrvAttrs.Get(0);
										vCurVATRate = vCurSrvAttrsRow.VATRate;
									EndIf;
								EndIf;
								If vDoNoShowCharging Then
									vCurPriceInFolioCurrency = Round(vCurPriceInFolioCurrency*vCurFeeTerms.NoShowFeePercent/100 + vCurFeeTerms.NoShowFeeSum, 2);
								ElsIf vDoLateAnnulationCharging Then
									vNumDays = (CheckInDate - ?(ValueIsFilled(DateOfAnnulation), DateOfAnnulation, CurrentSessionDate()))/(24*3600);
									vLateAnnulationFeePercent = 0;
									vLateAnnulationFeeSum = 0;
									If vCurFeeTerms.LateAnnulationPeriod > 0 And vCurFeeTerms.LateAnnulationPeriod1 > 0 And vCurFeeTerms.LateAnnulationPeriod <= vCurFeeTerms.LateAnnulationPeriod1 Then
										If vNumDays < vCurFeeTerms.LateAnnulationPeriod Then
											vLateAnnulationFeePercent = vCurFeeTerms.LateAnnulationFeePercent;
											vLateAnnulationFeeSum = vCurFeeTerms.LateAnnulationFeeSum;
										ElsIf vNumDays < vCurFeeTerms.LateAnnulationPeriod1 Then
											vLateAnnulationFeePercent = vCurFeeTerms.LateAnnulationFeePercent1;
											vLateAnnulationFeeSum = vCurFeeTerms.LateAnnulationFeeSum1;
										EndIf;
									ElsIf vCurFeeTerms.LateAnnulationPeriod > 0 And vCurFeeTerms.LateAnnulationPeriod1 > 0 And vCurFeeTerms.LateAnnulationPeriod > vCurFeeTerms.LateAnnulationPeriod1 Then
										If vNumDays < vCurFeeTerms.LateAnnulationPeriod1 Then
											vLateAnnulationFeePercent = vCurFeeTerms.LateAnnulationFeePercent1;
											vLateAnnulationFeeSum = vCurFeeTerms.LateAnnulationFeeSum1;
										ElsIf vNumDays < vCurFeeTerms.LateAnnulationPeriod Then
											vLateAnnulationFeePercent = vCurFeeTerms.LateAnnulationFeePercent;
											vLateAnnulationFeeSum = vCurFeeTerms.LateAnnulationFeeSum;
										EndIf;
									ElsIf vCurFeeTerms.LateAnnulationPeriod > 0 Then
										If vNumDays < vCurFeeTerms.LateAnnulationPeriod Then
											vLateAnnulationFeePercent = vCurFeeTerms.LateAnnulationFeePercent;
											vLateAnnulationFeeSum = vCurFeeTerms.LateAnnulationFeeSum;
										EndIf;
									ElsIf vCurFeeTerms.LateAnnulationPeriod1 > 0 Then
										If vNumDays < vCurFeeTerms.LateAnnulationPeriod1 Then
											vLateAnnulationFeePercent = vCurFeeTerms.LateAnnulationFeePercent1;
											vLateAnnulationFeeSum = vCurFeeTerms.LateAnnulationFeeSum1;
										EndIf;
									EndIf;
									vCurPriceInFolioCurrency = Round(vCurPriceInFolioCurrency*vLateAnnulationFeePercent/100 + vLateAnnulationFeeSum, 2);
								EndIf;
								// Try to find number of rooms left for fee
								vWriteOffs = cmGetWriteOffsForReservation(Ref);
								For Each vWriteOffRow In vWriteOffs Do
									If NumberOfBedsPerRoom > 0 And 
									   ValueIsFilled(vCurFeeTerms) And 
									  (vCurService = vCurFeeTerms.NoShowService Or vCurService = vCurFeeTerms.LateAnnulationService) Then
										vNumberOfRooms = NumberOfBeds/NumberOfBedsPerRoom;
										If Int(vNumberOfRooms) <> vNumberOfRooms Then
											vNumberOfRooms = Int(vNumberOfRooms) + 1;
										EndIf;
										vRoomsCheckedIn = vWriteOffRow.BedsCheckedIn/NumberOfBedsPerRoom;
										If Int(vRoomsCheckedIn) <> vRoomsCheckedIn Then
											vRoomsCheckedIn = Int(vRoomsCheckedIn) + 1;
										EndIf;
										vCoeff = vNumberOfRooms - vRoomsCheckedIn;
									Else
										vCoeff = NumberOfPersons - vWriteOffRow.GuestsCheckedIn;
									EndIf;
									If vCoeff > 0 Then 
										vCurQuantity = vCurSrvQuantity * vCoeff;
									Else
										vCurQuantity = 0;
									EndIf;
									Break;
								EndDo;
							Else
								If ValueIsFilled(ReservationStatus) Then
									If vDoNoShowCharging Or vDoLateAnnulationCharging Then
										Break;
									EndIf;
								EndIf;
							EndIf;
							// Process quantity calculation rule parameters
							If ValueIsFilled(vCurQuantityCalculationRule) Then
								// Skip if "Do not charge in reservations" flag is set
								If vCurQuantityCalculationRule.DoNotChargeInReservations Then
									If Not DoCharging Or DoCharging And Not ReservationStatus.AlwaysChargeInAdvanceServicesOnly Then
										Break;
									EndIf;
								EndIf;
								// Skip service based on "foreigners only" or "citizens only" parameters
								If vCurQuantityCalculationRule.ForeignersOnly Or vCurQuantityCalculationRule.CitizensOnly Then
									If ValueIsFilled(Hotel) And ValueIsFilled(Hotel.Citizenship) And 
									   ValueIsFilled(Guest) And ValueIsFilled(Guest.Citizenship) Then
										If Guest.Citizenship = Hotel.Citizenship Then
											If vCurQuantityCalculationRule.ForeignersOnly Then
												Break;
											EndIf;
										Else
											If vCurQuantityCalculationRule.CitizensOnly Then
												Break;
											EndIf;
										EndIf;
									Else
										If vCurQuantityCalculationRule.ForeignersOnly Then
											Break;
										EndIf;
									EndIf;
								EndIf;
							EndIf;
							// Add service to the services tabular part if quantity is not zero
							If vCurQuantity <> 0 Then
								// Check price upgrade
								vUpgradePrice = 0;
								vUpgradeDiscount = 0;
								vUpgradeCurrency = vCurFolioCurrency;
								vOfferRoomTypeUpgrade = Undefined;
								vOfferUpgradeIsActive = False;
								vRoomTypeUpgradeOffer = Undefined;
								vTermsUpgradeOffer = Undefined;
								If vCurIsRoomRevenue And vCurIsInPrice And Not vCurRoomRevenueAmountsOnly Then
									If ValueIsFilled(vRoomRoomType) And ValueIsFilled(vRoomRate) Then
										If ValueIsFilled(RoomTypeBeforeUpgrade) And vRoomRoomType <> RoomTypeBeforeUpgrade And 
											 vRoomRate.UpgradeDiscount > 0 And vRoomRate.UpgradeDiscount <= 100 Then
												vUpgradeDiscount = vRoomRate.UpgradeDiscount;           
												vOfferUpgradeIsActive = True;
										ElsIf vOffers.Count() > 0 Then
											For Each vOffersRow In vOffers Do
												vOffer = vOffersRow.SpecialOffer;
												For Each vOfferUpgradeRow In vOffer.RoomTypeUpgrades Do
													If vOfferUpgradeRow.RoomTypeTo = vRoomRoomType And 
													   (ValueIsFilled(RoomTypeBeforeUpgrade) And vRoomRoomType <> RoomTypeBeforeUpgrade And vOfferUpgradeRow.RoomTypeFrom = RoomTypeBeforeUpgrade Or 
													    Not ValueIsFilled(vOfferUpgradeRow.RoomTypeFrom) And ValueIsFilled(vOfferUpgradeRow.RoomTypeUpgrade)) Then
														If vOfferUpgradeRow.PriceMarkup <> 0 Then
															vUpgradePrice = vOfferUpgradeRow.PriceMarkup;
														EndIf;
														If vOfferUpgradeRow.PriceDifferenceDiscount >= 0 And vOfferUpgradeRow.PriceDifferenceDiscount <= 100 Then
															vUpgradeDiscount = vOfferUpgradeRow.PriceDifferenceDiscount;
														EndIf;
														vRoomTypeUpgradeOffer = vOffer;
														vUpgradeCurrency = vOffer.Currency;
														vOfferRoomTypeUpgrade = vOfferUpgradeRow.RoomTypeUpgrade;
														vOfferUpgradeIsActive = True;
														Break;
													EndIf;
												EndDo;
												If vOfferUpgradeIsActive Then
													If ValueIsFilled(vOffer.RoomUpgradeService) Then
														vUpgradeService = vOffer.RoomUpgradeService;
													EndIf;
													Break;
												EndIf;
											EndDo;
										EndIf;
										If vUpgradePrice <> 0 And vUpgradeCurrency <> vCurFolioCurrency Then
											vUpgradePrice = Round(cmConvertCurrencies(vUpgradePrice, vUpgradeCurrency, , vCurFolioCurrency, vCurFolioCurrencyExchangeRate, ?(ValueIsFilled(vCurAccountingDate), vCurAccountingDate, ExchangeRateDate), Hotel), 2);
										EndIf;
										If vOfferUpgradeIsActive Then
											If ValueIsFilled(vOfferRoomTypeUpgrade) Then
												vOfferByRoomTypeUpgradeDescription = TrimAll(vRoomTypeUpgradeOffer);
												If RoomTypeUpgrade <> vOfferRoomTypeUpgrade Then
													RoomTypeUpgrade = vOfferRoomTypeUpgrade;
												EndIf;
											Else
												vRRRow = vRoomRates.Find(vCurAccountingDate, "AccountingDate");
												If vRRRow <> Undefined Then
													vRateCurrency = vCurFolioCurrency;
													vRoomPriceBeforeUpgrade = pmGetServiceRatePrice(vRoomRate, vCurAccountingDate, vRRRow.PriceCalculationDate, vPricesRow.Service, vRateCurrency, RoomTypeBeforeUpgrade, ?(vCurPriceTag = Undefined, Catalogs.PriceTags.EmptyRef(), vCurPriceTag), vAccommodationType, vMainRoomGuestAccommodationTemplate, vIsForFolioSplitForPrices, vSplitPackagesByGuests);
													If vRoomPriceBeforeUpgrade <> 0 Then
														// Apply share percent
														If vCurIsRoomRevenue And vCurIsInPrice Then
															If vIsForFolioSplit And Not IsBlankString(SharePercent) Then
																vRoomPriceBeforeUpgrade = cmApplySharePercent(vRoomPriceBeforeUpgrade, SharePercent);
															EndIf;
														EndIf;
														If vRateCurrency <> vCurFolioCurrency Then
															vRoomPriceBeforeUpgradeInFolioCurrency = Round(cmConvertCurrencies(vRoomPriceBeforeUpgrade, vRateCurrency, , vCurFolioCurrency, vCurFolioCurrencyExchangeRate, ?(ValueIsFilled(vCurAccountingDate), vCurAccountingDate, ExchangeRateDate), Hotel), 2);
														Else
															vRoomPriceBeforeUpgradeInFolioCurrency = vRoomPriceBeforeUpgrade;
														EndIf;
														If vCurPriceInFolioCurrency > vRoomPriceBeforeUpgradeInFolioCurrency Then
															vPriceDiffDiscount = Round((vCurPriceInFolioCurrency - vRoomPriceBeforeUpgradeInFolioCurrency) * (100 - vUpgradeDiscount) / 100, 2);
															vUpgradePrice = vUpgradePrice + vPriceDiffDiscount;
															vCurPriceInFolioCurrency = vRoomPriceBeforeUpgradeInFolioCurrency;
															vOfferByRoomTypeUpgradeDescription = TrimAll(vRoomTypeUpgradeOffer);
														EndIf;
													EndIf;
												EndIf;
											EndIf;
										EndIf;
									EndIf;
								EndIf;
								// Add service
								vSrv = Services.Insert(i);
								i = i + 1;
								vSrv.Folio = vCurFolio;
								vSrv.FolioCurrency = vCurFolioCurrency;
								vSrv.FolioCurrencyExchangeRate = vCurFolioCurrencyExchangeRate;
								vSrv.AccountingDate = vCurAccountingDate;
								If ValueIsFilled(vCurFeeTerms) And (vCurService = vCurFeeTerms.LateAnnulationService Or vCurService = vCurFeeTerms.NoShowService) Then
									If ValueIsFilled(Hotel) And Hotel.DoNotEditClosedDateDocs And ValueIsFilled(Hotel.AccountingDate) And vSrv.AccountingDate < Hotel.AccountingDate Then
										vSrv.AccountingDate = vSrv.AccountingDate + 24*3600;
									EndIf;
								EndIf;
								vSrv.Service = vCurService;
								vSrv.Price = vCurPriceInFolioCurrency;
								If vRoomRate.RoundPrice And Not vDoNotRoundPrice Then
									If Not ValueIsFilled(vRoomRate.RoundPriceServiceGroup) Or 
									   ValueIsFilled(vRoomRate.RoundPriceServiceGroup) And cmIsServiceInServiceGroup(vSrv.Service, vRoomRate.RoundPriceServiceGroup) Then
										vSrv.Price = Round(vSrv.Price, vRoomRate.RoundPriceDigits);
									EndIf;
								EndIf;
								// Check if this is free of charge day
								If Not vRoomRate.NoDiscounts And ValueIsFilled(DiscountType) And DiscountType.EachNDayIsFreeOfCharge > 0 And
									cmIsServiceInServiceGroup(vSrv.Service, DiscountServiceGroup) Then   
									If ((vCurAccountingDate >= DiscountType.DateValidFrom Or Not ValueIsFilled(DiscountType.DateValidFrom)) 
										And (vCurAccountingDate <= DiscountType.DateValidTo Or Not ValueIsFilled(DiscountType.DateValidTo))) Then
										
										vNumberOfFreeOfChargeDays = ?(DiscountType.NumberOfFreeOfChargeDays > 1, DiscountType.NumberOfFreeOfChargeDays, 1);
										vPeriodInDays = DiscountType.EachNDayIsFreeOfCharge + vNumberOfFreeOfChargeDays - 1;
										vNumberOfDays = Round((BegOfDay(vSrv.AccountingDate) - BegOfDay(CheckInDate))/(24*3600), 0) + 1;
										For d = 1 To vNumberOfFreeOfChargeDays Do
											If vNumberOfDays <> 0 And Int((vNumberOfDays + vNumberOfFreeOfChargeDays - d)/vPeriodInDays) = (vNumberOfDays + vNumberOfFreeOfChargeDays - d)/vPeriodInDays Then
												vSrv.Price = 0;
												vCurPrice = 0;
												Break;
											EndIf;
										EndDo;
									EndIf;
								EndIf;
								// Apply share percent
								If vCurIsRoomRevenue And vCurIsInPrice Then
									If vIsForFolioSplit And Not IsBlankString(SharePercent) Then
										vSrv.Price = cmApplySharePercent(vSrv.Price, SharePercent);
									EndIf;
								EndIf;
								vSrv.Unit = vCurUnit;
								vSrv.Quantity = vCurQuantity;
								vSrv.Sum = Round(vSrv.Price * vSrv.Quantity, 2);
								vSrv.VATRate = vCurVATRate;
								vSrv.VATSum = cmCalculateVATSum(vCurVATRate, vSrv.Sum, vSrv.AccountingDate);
								vSrv.Remarks = vCurRemarks;
								If ValueIsFilled(vSrv.Service) Then
									vSrv.IsResourceRevenue = vSrv.Service.IsResourceRevenue;
									// Fill service composition
									If Not IsBlankString(vSrv.Service.Composition) Then
										vSrv.Remarks = TrimAll(vSrv.Service.Composition);
									EndIf;
									// Fill resource and service times
									If ValueIsFilled(vSrv.Service.Resource) And ValueIsFilled(vSrv.AccountingDate) Then
										vSrv.ServiceResource = vSrv.Service.Resource;
										vResourceObj = vSrv.ServiceResource.GetObject();
										vDefaultTimes = vResourceObj.pmGetResourceDefaultChargingTimes(vSrv.AccountingDate);
										vSrv.TimeFrom = vDefaultTimes.TimeFrom;
										vSrv.TimeTo = vDefaultTimes.TimeTo;
										vSrv.DoResourceReservation = True;
									EndIf;
								EndIf;
								vSrv.Company = Company;
								If vSrv.Company <> vCurFolio.Company And vCurFolio.DoNotUpdateCompany Then
									vSrv.Company = vCurFolio.Company;
								EndIf;
								vSrv.IsRoomRevenue = vCurIsRoomRevenue;
								vSrv.IsInPrice = vCurIsInPrice;
								vSrv.IsSplit = vCurIsSplit;
								vSrv.RoomRevenueAmountsOnly = vCurRoomRevenueAmountsOnly;
								vSrv.CalendarDayType = vCurCalendarDayType;
								If Not ValueIsFilled(vCurCalendarDayType) And ValueIsFilled(vCurAccountingDate) And ValueIsFilled(vRoomRate) Then
									vSrv.CalendarDayType = cmGetCalendarDayType(vRoomRate, vCurAccountingDate, vCheckInDate, vCheckOutDate, , ?(ValueIsFilled(RoomTypeUpgrade), RoomTypeUpgrade, vRoomRoomType), vPriceCalculationDate);
								EndIf;
								vSrv.PriceTag = vCurPriceTag;
								vSrv.CalendarDayTypeIsChanged = vCalendarDayTypeIsChanged;
								vSrv.RoomRate = vRoomRate;
								vSrv.AccommodationType = ?(Not vIsForFolioSplit And vCurService.ChargeToEachGuestSeparately And 
								                           ValueIsFilled(vCurAccommodationType) And ValueIsFilled(vRoomRate) And 
								                           vRoomRate.RateChargeDirection = Enums.RateChargeDirections.MergeToTheMainRoomGuest, 
														   vCurAccommodationType, 
														   vAccommodationType);
								vSrv.Room = vRoom;
								vSrv.RoomType = vRoomRoomType;
								vSrv.Timetable = vCurTimetable;
								vSrv.IsManual = False;
								vSrv.RateSum = 0;
								vSrv.RateDiscountSum = 0;
								vSrv.RateCommissionSum = 0;
								vSrv.ServicePackage = vCurServicePackage;
								vSrv.ClientType = vClientType;
								vSrv.SourceOfBusiness = vSourceOfBusiness;
								vSrv.MarketingCode = vMarketingCode;
								vSrv.BoardPlace = vBoardPlace;
								// Calculate room sales parameters
								If vSrv.IsRoomRevenue Then
									vNoAccommodationService = False;
								EndIf;
								If vSrv.IsRoomRevenue And Not vSrv.IsSplit And Not vSrv.RoomRevenueAmountsOnly Then
									vCurPeriodInHours = vCurQuantityCalculationRule.PeriodInHours;
									vNumberOfPersonsPerRoom = NumberOfPersonsPerRoom;
									vNumberOfBedsPerRoom = NumberOfBedsPerRoom;
									vUseDocumentNumberOfPersons = NumberOfPersons > 1 And ValueIsFilled(vRoomRate) And (vRoomRate.RateChargeDirection <> Enums.RateChargeDirections.MergeToTheMainRoomGuest Or IsForFolioSplit);
									vNumberOfPersons = ?(vUseDocumentNumberOfPersons, NumberOfPersons, vCurNumberOfPersons * RoomQuantity);
									vNumberOfRooms = ?(vUseDocumentNumberOfPersons, NumberOfRooms, vCurNumberOfRooms * RoomQuantity);
									vNumberOfBeds = ?(vUseDocumentNumberOfPersons, ?(NumberOfRooms > 0, NumberOfRooms * NumberOfBedsPerRoom, NumberOfBeds), ?(vNumberOfRooms > 0, vNumberOfRooms * NumberOfBedsPerRoom, vCurNumberOfBeds * RoomQuantity));
									vNumberOfAdditionalBeds = ?(vUseDocumentNumberOfPersons, NumberOfAdditionalBeds, vCurNumberOfAdditionalBeds * RoomQuantity);
									vIsVirtual = False;
									If ValueIsFilled(vRoom) Then
										vIsVirtual = vRoom.IsVirtual;
									ElsIf ValueIsFilled(vRoomRoomType) Then
										vIsVirtual = vRoomRoomType.IsVirtual;
									EndIf;
									If vRoomRoomType <> RoomType Then
										If ValueIsFilled(vRoom) Then
											vRoomAttrs = vRoom.GetObject().pmGetRoomAttributes(cm1SecondShift(vCurAccountingDate));
											For Each vRoomAttrsRow In vRoomAttrs Do
												vNumberOfBedsPerRoom = vRoomAttrsRow.NumberOfBedsPerRoom;
												vNumberOfPersonsPerRoom = vRoomAttrsRow.NumberOfPersonsPerRoom;
												vIsVirtual = vRoomAttrsRow.IsVirtual;
												Break;
											EndDo;
										ElsIf ValueIsFilled(vRoomRoomType) Then
											vNumberOfBedsPerRoom = vRoomRoomType.NumberOfBedsPerRoom;
											vNumberOfPersonsPerRoom = vRoomRoomType.NumberOfPersonsPerRoom;
											vIsVirtual = vRoomRoomType.IsVirtual;
										EndIf;
									EndIf;
									If vAccommodationType <> AccommodationType Or vRoomRoomType <> RoomType Then
										// Fill accommodation type resources
										If Not vIsVirtual Then
											vNumberOfRooms = vCurNumberOfRooms * RoomQuantity;
											vNumberOfBeds = ?(vNumberOfRooms > 0, vNumberOfRooms * vNumberOfBedsPerRoom, vCurNumberOfBeds * RoomQuantity);
											vNumberOfAdditionalBeds = vCurNumberOfAdditionalBeds * RoomQuantity;
										Else
											vNumberOfRooms = 0;
											vNumberOfBeds = 0;
											vNumberOfAdditionalBeds = 0;
										EndIf;
									EndIf;
									vSrv.RoomsRented = ?(vNumberOfBedsPerRoom=0, 0, Round(vNumberOfBeds/vNumberOfBedsPerRoom*vCurSrvQuantity*vCurPeriodInHours/24, 7));
									vSrv.BedsRented = Round(vNumberOfBeds*vCurSrvQuantity*vCurPeriodInHours/24, 7);
									vSrv.AdditionalBedsRented = Round(vNumberOfAdditionalBeds*vCurSrvQuantity*vCurPeriodInHours/24, 7);
									vSrv.GuestDays = Round(vNumberOfPersons*vCurSrvQuantity*vCurPeriodInHours/24, 7);
									If vFirstDayWithAccommodationService Then
										vGuestsCheckedInIsSet = True;
										vSrv.GuestsCheckedIn = vNumberOfPersons;
									EndIf;
									// Guests in rooms wich are not included in statistics still need to be in reports, but only as number of guests and number of guests checked-in
									If ValueIsFilled(vSrv.RoomType) AND vSrv.RoomType.DoesNotAffectRoomRevenueStatistics Then
										vCurPeriodInHours = vCurQuantityCalculationRule.PeriodInHours;
										vSrv.GuestDays = Round(vNumberOfPersons*vCurSrvQuantity*vCurPeriodInHours/24, 7);
										If vFirstDayWithAccommodationService Then
											vGuestsCheckedInIsSet = True;
											vSrv.GuestsCheckedIn = vNumberOfPersons;
										EndIf;
									EndIf;
									// Check if this is folio split mode and share percent is specified
									If IsForFolioSplit And Not IsBlankString(SharePercent) And Not ValueIsFilled(AccommodationTemplate) Then
										vSrv.RoomsRented = 0;
										vSrv.BedsRented = 0;
										vSrv.AdditionalBedsRented = 0;
										vSrv.GuestDays = 0;
										vSrv.GuestsCheckedIn = 0;
									EndIf;
								EndIf;
								// Contract meal board terms
								vPriceCorrection = vCurPriceInFolioCurrency;
								If vContractMealBoardTerms <> Undefined And vContractMealBoardTerms.Count() > 0 And ValueIsFilled(vPricesRowServicePackage) Then
									vAccommodationTypesList = New ValueList();
									If ValueIsFilled(vAccommodationTemplate) And Not vAccommodationTemplate.IsForFolioSplit And 
									   ValueIsFilled(vRoomRate) And vRoomRate.RateChargeDirection = Enums.RateChargeDirections.MergeToTheMainRoomGuest Then
										For Each vTemplateAccTypesRow In vAccommodationTemplate.AccommodationTypes Do
											vAccommodationTypesList.Add(vTemplateAccTypesRow.AccommodationType);
										EndDo;
									Else
										vAccommodationTypesList.Add(vAccommodationType);
									EndIf;
									For Each vAccommodationTypesListItem In vAccommodationTypesList Do
										vWrkAccommodationType = vAccommodationTypesListItem.Value;
										vCMBTRows = vContractMealBoardTerms.FindRows(New Structure("MealBoardTerm", vPricesRowServicePackage));
										If vCMBTRows.Count() > 0 Then
											For Each vCMBTRow In vCMBTRows Do
												If Not ValueIsFilled(vCMBTRow.RoomType) Or ValueIsFilled(vCMBTRow.RoomType) And ValueIsFilled(vRoomRoomType) And (vCMBTRow.RoomType = vRoomRoomType Or vRoomRoomType.BelongsToItem(vCMBTRow.RoomType)) Then
													If Not ValueIsFilled(vCMBTRow.AccommodationType) Or vCMBTRow.AccommodationType = vWrkAccommodationType Then
														If ValueIsFilled(vCMBTRow.CheckInDateTo) And vCMBTRow.CheckInDateFrom <= CheckInDate And EndOfDay(vCMBTRow.CheckInDateTo) >= CheckInDate Or 
														   Not ValueIsFilled(vCMBTRow.CheckInDateTo) And vCMBTRow.CheckInDateFrom <= CheckInDate Then
															If ValueIsFilled(vCMBTRow.ReservationDateTo) And vCMBTRow.ReservationDateFrom <= vReservationDate And EndOfDay(vCMBTRow.ReservationDateTo) >= vReservationDate Or 
															   Not ValueIsFilled(vCMBTRow.ReservationDateTo) And vCMBTRow.ReservationDateFrom <= vReservationDate Then
																If ValueIsFilled(vCMBTRow.PeriodOfStayTo) And vCMBTRow.PeriodOfStayFrom <= vCurAccountingDate And vCMBTRow.PeriodOfStayTo >= vCurAccountingDate Or 
																   Not ValueIsFilled(vCMBTRow.PeriodOfStayTo) And vCMBTRow.PeriodOfStayFrom <= vCurAccountingDate Then
																	vSPRowQuantity = 0;
																	If vMealBoardTermIncludedServices <> Undefined Then
																		l = vMealBoardTermIncludedServices.Count() - 1;
																		While l >= 0 Do
																			vSPRow = vMealBoardTermIncludedServices.Get(l);
																			If vSPRow.AccountingDate <= vCurAccountingDate Then
																				If Not ValueIsFilled(vSPRow.ClientType) Or vSPRow.ClientType = ClientType Then
																					If Not ValueIsFilled(vSPRow.RoomType) Or vSPRow.RoomType = vRoomRoomType Then
																						If Not ValueIsFilled(vSPRow.AccommodationType) Or vSPRow.AccommodationType = vWrkAccommodationType Then
																							vSPRowQuantity = vSPRow.Quantity;
																							Break;
																						EndIf;
																					EndIf;
																				EndIf;
																			EndIf;
																			l = l - 1;
																		EndDo;
																	EndIf;
																	vPriceCorrection = vPriceCorrection + vCMBTRow.PriceCorrection * vSPRowQuantity;
																	If vCMBTRow.DoNotApplyDiscounts Then
																		vDoNotApplyDiscountsToPriceCorrection = True;
																	EndIf;
																	Break;
																EndIf;
															EndIf;
														EndIf;
													EndIf;
												EndIf;
											EndDo;
										EndIf;
									EndDo;
									// Process terms upgrade special offers
									If Not vDoNotApplyDiscountsToPriceCorrection And vPriceCorrection <> 0 Then
										If vOffers.Count() > 0 Then
											vTermsUpgradeIsActive = False;
											vTermsUpgradeCurrency = Undefined;
											vTermsUpgradePriceMarkup = 0;
											vTermsUpgradePriceDifferenceDiscount = 0;
											For Each vOffersRow In vOffers Do
												vOffer = vOffersRow.SpecialOffer;
												For Each vOfferUpgradeRow In vOffer.TermsUpgrades Do
													If vOfferUpgradeRow.TermsTo = vMealBoardTermServicePackage And 
													   ValueIsFilled(vOfferUpgradeRow.TermsFrom) And vOfferUpgradeRow.TermsFrom = vMealBoardTermIncluded Then
														If vOfferUpgradeRow.PriceMarkup <> 0 Then
															vTermsUpgradePriceMarkup = vOfferUpgradeRow.PriceMarkup;
														EndIf;
														If vOfferUpgradeRow.PriceDifferenceDiscount >= 0 And vOfferUpgradeRow.PriceDifferenceDiscount <= 100 Then
															vTermsUpgradePriceDifferenceDiscount = vOfferUpgradeRow.PriceDifferenceDiscount;
														EndIf;
														vTermsUpgradeOffer = vOffer;
														vTermsUpgradeCurrency = vOffer.Currency;
														vTermsUpgradeIsActive = True;
														Break;
													EndIf;
												EndDo;
												If vTermsUpgradeIsActive Then
													Break;
												EndIf;
											EndDo;
											If vTermsUpgradeIsActive And (vTermsUpgradePriceMarkup <> 0 Or vTermsUpgradePriceDifferenceDiscount <> 0) Then
												If vTermsUpgradePriceMarkup <> 0 And ValueIsFilled(vTermsUpgradeCurrency) And vTermsUpgradeCurrency <> vSrv.FolioCurrency Then
													vTermsUpgradePriceMarkup = Round(cmConvertCurrencies(vTermsUpgradePriceMarkup, vTermsUpgradeCurrency, , vSrv.FolioCurrency, , ?(ValueIsFilled(vSrv.AccountingDate), vSrv.AccountingDate, ExchangeRateDate), Hotel), 2);
												EndIf;
												vPriceCorrection = vTermsUpgradePriceMarkup + Round(vPriceCorrection*(100 - vTermsUpgradePriceDifferenceDiscount)/100, 2);
												vOfferByTermsUpgradeDescription = TrimAll(vTermsUpgradeOffer);
											EndIf;
										EndIf;
									EndIf;
								EndIf;
								// Overrides from external algorithm
								If vSrv.IsRoomRevenue And Not vSrv.IsSplit And Not vSrv.RoomRevenueAmountsOnly Then
									If vOccParams <> Undefined And TypeOf(vOccParams) = Type("Structure") Then
										FillPropertyValues(vSrv, vOccParams);
									EndIf;
								EndIf;								
								// Discounts
								If Not vRoomRate.NoDiscounts And Not vNoDiscounts And (Not ValueIsFilled(Contract) Or ValueIsFilled(Contract) And Not Contract.NoDiscounts) Then
									// Calculate discount for this service if applicable
									vCurDiscount = 0;
									vCurDiscountType = Undefined;
									vCurDiscountServiceGroup = Undefined;
									vCurDiscountConfirmationText = "";
									// Check manual discount set in the document
									If cmIsServiceInServiceGroup(vSrv.Service, DiscountServiceGroup) Then
										vRRRow = vRoomRates.Find(vCurAccountingDate, "AccountingDate");
										If vRRRow <> Undefined And Not IsBlankString(vRRRow.Discount) And Not vSrv.IsSplit Then
											vCurDiscount = Number(vRRRow.Discount);
										ElsIf vFixedServiceDiscount <> 0 Then
											vCurDiscount = vFixedServiceDiscount;
										ElsIf vFixedDiscount <> 0 Then
											vCurDiscount = vFixedDiscount;
										EndIf;
										If vCurDiscount <> 0 Then
											If ValueIsFilled(DiscountType) And (vCurAccountingDate < DiscountType.DateValidFrom Or
											   vCurAccountingDate > DiscountType.DateValidTo And ValueIsFilled(DiscountType.DateValidTo)) Then
												vCurDiscount = 0;
											Else
												vCurDiscountType = DiscountType;
												vCurDiscountServiceGroup = DiscountServiceGroup;
												vCurDiscountConfirmationText = DiscountConfirmationText;
											EndIf;
										EndIf;
									EndIf;
									// Check accumulating discounts
									If Not TurnOffAutomaticDiscounts Then
										// Check period discount
										If vPeriodDiscount <> 0 Then
											If Not ValueIsFilled(vPeriodDiscountType) Or ValueIsFilled(vPeriodDiscountType) And (vCurAccountingDate >= vPeriodDiscountType.DateValidFrom And (vCurAccountingDate <= vPeriodDiscountType.DateValidTo Or Not ValueIsFilled(vPeriodDiscountType.DateValidTo))) Then
												If cmFirstDiscountIsGreater(vPeriodDiscount, vCurDiscount) Then
													vCurDiscount = vPeriodDiscount;
													vCurDiscountType = vPeriodDiscountType;
													vCurDiscountServiceGroup = vPeriodDiscountServiceGroup;
													vCurDiscountConfirmationText = vPeriodDiscountConfirmationText;
												EndIf;
											EndIf;
										EndIf;
										// Retrieve accumulation discounts
										For Each vAccDiscount In vAccDiscounts Do
											vDiscountType = vAccDiscount.DiscountType;
											If ValueIsFilled(vDiscountType) Then
												If vCurAccountingDate < vDiscountType.DateValidFrom Or
												   (vCurAccountingDate > vDiscountType.DateValidTo And ValueIsFilled(vDiscountType.DateValidTo)) Then
													Continue;
												EndIf;
											EndIf;
											vDiscountDimension = vAccDiscount.DiscountDimension;
											vDiscountServiceGroup = vDiscountType.DiscountServiceGroup;
											If cmIsServiceInServiceGroup(vSrv.Service, vDiscountServiceGroup) And 
											   (Not vDiscountType.IsForRackRatesOnly Or 
											    vDiscountType.IsForRackRatesOnly And ValueIsFilled(vSrv.RoomRate) And vSrv.RoomRate.IsRackRate Or 
												vSrv.IsManual) Then
												vDiscountTypeObj = vDiscountType.GetObject();
												
												// Check that this discount type fits to the service folio
												vSrvDiscountDimension = Undefined;
												vSrvResource = 0;
												vNumberOfPersons = NumberOfPersons;
												If ValueIsFilled(vSrv.RoomRate) And vSrv.GuestDays > 0 Then
													If vSrv.RoomRate.RateChargeDirection = Enums.RateChargeDirections.MergeToTheMainRoomGuest Then
														vNumberOfPersons = NumberOfPersons * vSrv.GuestDays;
													EndIf;
												ElsIf ValueIsFilled(RoomRate) And vSrv.GuestDays > 0 Then
													If RoomRate.RateChargeDirection = Enums.RateChargeDirections.MergeToTheMainRoomGuest Then
														vNumberOfPersons = NumberOfPersons * vSrv.GuestDays;
													EndIf;
												EndIf;
												vSrvResource = vDiscountTypeObj.pmCalculateResource(vSrv, vNumberOfPersons, vSrv.Folio, DiscountCard, vSrvDiscountDimension);
												If Not vDiscountType.IsPerVisit And (Not ValueIsFilled(Hotel.DateToGetBonusBalance) Or 
												   Hotel.DateToGetBonusBalance = Enums.DatesToGetBonusBalance.CheckInDate) Then
													vSrvResource = 0;
												EndIf;
												If TypeOf(vSrvDiscountDimension) = TypeOf(vDiscountDimension) Then
													// Add resource calculated for this service to the current discount resource
													If vSrvResource <> 0 Then
														vAccDiscount.Resource = vAccDiscount.Resource + vSrvResource;
													EndIf;
												   
													// Retrieve discount percent valid for current discount resource										
													vResource = vAccDiscount.Resource;
													vDiscountConfirmationText = "";
													vDiscount = vDiscountTypeObj.pmGetAccumulatingDiscount(vSrv.Service, vSrv.AccountingDate, 
													                                                       vResource, 
													                                                       vDiscountConfirmationText);
													If vDiscount <> 0 Then
														If cmFirstDiscountIsGreater(vDiscount, vCurDiscount) Then
															vCurDiscount = vDiscount;
															vCurDiscountType = vDiscountType;
															vCurDiscountServiceGroup = vDiscountServiceGroup;
															vCurDiscountConfirmationText = vDiscountConfirmationText;
														EndIf;
													EndIf;
												EndIf;
											EndIf;
										EndDo;
										// Check special offer discounts for room rate
										vOfferDiscount = 0;
										vOfferDiscountType = Undefined;
										vOfferDiscountServiceGroup = Undefined;
										vOfferDescription = "";
										If vOffers.Count() > 0 Then
											If vSrv.IsInPrice Then
												For Each vOffersRow In vOffers Do
													vCurOffer = vOffersRow.SpecialOffer;
													vCurOfferDiscountType = vCurOffer.DiscountType;
													If ValueIsFilled(vCurOfferDiscountType) Then
														If vCurAccountingDate >= vCurOfferDiscountType.DateValidFrom And 
														  (vCurAccountingDate <= vCurOfferDiscountType.DateValidTo Or Not ValueIsFilled(vCurOfferDiscountType.DateValidTo)) Then
															If Not ValueIsFilled(vCurOfferDiscountType.DiscountServiceGroup) Or 
															   ValueIsFilled(vCurOfferDiscountType.DiscountServiceGroup) And cmIsServiceInServiceGroup(vSrv.Service, vCurOfferDiscountType.DiscountServiceGroup) Then
																vCurOfferDiscount = vCurOfferDiscountType.GetObject().pmGetDiscount(vCurAccountingDate, vSrv.Service, Hotel);
																If vCurOfferDiscount <> 0 Then
																	vOfferDiscount = vCurOfferDiscount;
																	vOfferDiscountType = vCurOfferDiscountType;
																	vOfferDiscountServiceGroup = vCurOfferDiscountType.DiscountServiceGroup;
																	vOfferDescription = TrimAll(vCurOffer);
																	Break;
																EndIf;
															EndIf;
														EndIf;
													EndIf;
												EndDo;
											EndIf;
											// Check special offer discounts for service packages
											If vOfferDiscount = 0 Then
												If ValueIsFilled(vCurServicePackage) Then
													For Each vOffersRow In vOffers Do
														vCurOffer = vOffersRow.SpecialOffer;
														If vCurOffer.ServicePackageDiscounts.Count() > 0 Then
															vOfferSPDRows = vCurOffer.ServicePackageDiscounts.FindRows(New Structure("ServicePackage", vCurServicePackage));
															For Each vOfferSPDRow In vOfferSPDRows Do
																If vOfferDiscount < vOfferSPDRow.Discount Then
																	vOfferDiscount = vOfferSPDRow.Discount;
																	vOfferDiscountType = DiscountType;
																	vOfferDiscountServiceGroup = DiscountServiceGroup;
																	vOfferDescription = TrimAll(vCurOffer);
																EndIf;
															EndDo;
														EndIf;
													EndDo;
												EndIf;
											EndIf;
										EndIf;
										If cmCompareDiscounts(vOfferDiscount, vCurDiscount) Then
											vCurDiscount = vOfferDiscount;
											vCurDiscountType = vOfferDiscountType;
											vCurDiscountServiceGroup = vOfferDiscountServiceGroup;
											vCurDiscountConfirmationText = vOfferDescription;
										EndIf;
									EndIf;
									// Check special offer settings for early check-in and late check-out
									For Each vOffersRow In vOffers Do
										vCurOffer = vOffersRow.SpecialOffer;
										If vCurOffer.EarlyCheckInDiscount And 
										  (vCurQuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.EarlyCheckIn Or vCurQuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.EarlyCheckInNoDateShift) Then
											vCurDiscount = vCurOffer.EarlyCheckInDiscount;
											vCurDiscountConfirmationText = TrimAll(vCurOffer);
										EndIf;
										If vCurOffer.LateCheckOutDiscount <> 0 And 
										   vCurQuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.LateCheckOut Then
											vCurDiscount = vCurOffer.LateCheckOutDiscount;
											vCurDiscountConfirmationText = TrimAll(vCurOffer);
										EndIf;
									EndDo;
									// Calculate discount sum
									If vCurDiscount <> 0 Then
										If cmIsServiceInServiceGroup(vSrv.Service, vCurDiscountServiceGroup) Then
											If Not ValueIsFilled(vCurDiscountType) Or 
											   ValueIsFilled(vCurDiscountType) And (Not vCurDiscountType.IsForRackRatesOnly Or 
											                                        vCurDiscountType.IsForRackRatesOnly And ValueIsFilled(vSrv.RoomRate) And vSrv.RoomRate.IsRackRate Or
																					vSrv.IsManual) Then
												vSrv.Discount = vCurDiscount;
												vSrv.DiscountType = vCurDiscountType;
												vSrv.DiscountServiceGroup = vCurDiscountServiceGroup;
												vSrv.DiscountConfirmationText = vCurDiscountConfirmationText;
												If Not IsBlankString(vCurDiscountConfirmationText) Then
													DiscountConfirmationText = vCurDiscountConfirmationText;
												EndIf;
											EndIf;
											// Check should we set value for the period discount
											If ValueIsFilled(vCurDiscountType) Then
												If vCurDiscountType.IsPerPeriod Then
													If vCurDiscount > vPeriodDiscount And vCurDiscount > 0 Or 
													   vCurDiscount < vPeriodDiscount And vCurDiscount < 0 Then
														vPeriodDiscount = vCurDiscount;
														vPeriodDiscountType = vCurDiscountType;
														vPeriodDiscountServiceGroup = vCurDiscountServiceGroup;
														vPeriodDiscountConfirmationText = vCurDiscountConfirmationText;
													EndIf;
												EndIf;
											EndIf;
										EndIf;
									Else
										If ValueIsFilled(DiscountType) And 
										   DiscountType.IsAccumulatingDiscount And DiscountType.HasToBeDirectlyAssigned Then 
											If cmIsServiceInServiceGroup(vSrv.Service, DiscountServiceGroup) Then
												If Not DiscountType.IsForRackRatesOnly Or 
												   DiscountType.IsForRackRatesOnly And ValueIsFilled(vSrv.RoomRate) And vSrv.RoomRate.IsRackRate Or 
												   vSrv.IsManual Then
													vSrv.Discount = 0; // This is not mistake
													vSrv.DiscountType = DiscountType;
													vSrv.DiscountServiceGroup = DiscountServiceGroup;
													vSrv.DiscountConfirmationText = DiscountConfirmationText;
												EndIf;
											EndIf;
										EndIf;
									EndIf;
									// Recalculate bound amounts
									pmCalculateServiceDiscounts(vSrv);
									// Calculate rest of room revenue price
									If vRoomRevenuePriceByRoomType And vSrv.DiscountSum <> 0 And vSrv.Quantity <> 0 Then
										vRestOfCurPrice = vRestOfCurPrice + Round(vSrv.DiscountSum/vSrv.Quantity, 2);
									EndIf;
								EndIf;
								// Save reference to the accommodation service
								If vCurRoomRateSrv = Undefined Then
									If vSrv.IsRoomRevenue And vSrv.IsInPrice Then
										vCurRoomRateSrv = vSrv;
										vCurRoomRateSrvHasManualPrice = vIsManualPrice;
									EndIf;
								EndIf;
								// Check if charging rule amount is set
								If vChargingRuleAmountIsSet Then
									If vCurRoomRateSrv <> Undefined And Not vCurRoomRateSrv.IsManualPrice Then
										If vPricesRow.PacketPriceIsIncludedInRoomRate Or vCurServicePackageUsageType = Enums.ServicePackageUsageType.SubtractFromRoomRatePrice Then
											If vCurRestOfRoomRateSrv <> Undefined Then
												If vCurRestOfRoomRateSrv.Sum > 0 Then
													// Recalculate rate sum
													vCurRoomRateSrv.Sum = vCurRoomRateSrv.Sum + vCurRestOfRoomRateSrv.Sum;
													vCurRoomRateSrv.VATSum = cmCalculateVATSum(vCurRoomRateSrv.VATRate, vCurRoomRateSrv.Sum, vCurRoomRateSrv.AccountingDate);
													vCurRoomRateSrv.Price = Round(vCurRoomRateSrv.Sum / ?(vCurRoomRateSrv.Quantity = 0, 1, vCurRoomRateSrv.Quantity), 2);
													If Not (ValueIsFilled(vSrv.DiscountType) And vSrv.DiscountType.SubtractDiscountFromRoomRevenueAmount And 
													        ValueIsFilled(vCurRoomRateSrv.DiscountType) And Not vCurRoomRateSrv.IsManual And Not vCurRoomRateSrv.DiscountIsChanged) Then
														pmCalculateServiceDiscounts(vCurRoomRateSrv);
													EndIf;
													pmSetServiceCommissions(vCurRoomRateSrv, vRoomRates, vComplexCommission);
													// Update current service
													vSrv.Sum = vCurRestOfRoomRateSrv.Sum;
													vSrv.VATSum = cmCalculateVATSum(vSrv.VATRate, vSrv.Sum, vSrv.AccountingDate);
													vSrv.Price = Round(vSrv.Sum / ?(vSrv.Quantity = 0, 1, vSrv.Quantity), 2);
													pmCalculateServiceDiscounts(vSrv);
													// Reset split row to zeeroes
													vCurRestOfRoomRateSrv.Price = 0;
													vCurRestOfRoomRateSrv.Sum = 0;
													vCurRestOfRoomRateSrv.DiscountSum = 0;
													vCurRestOfRoomRateSrv.Quantity = 0;
													pmSetServiceCommissions(vCurRestOfRoomRateSrv, vRoomRates, vComplexCommission);
												Else
													// Update current service
													vSrv.Sum = 0;
													vSrv.VATSum = 0;
													vSrv.Price = 0;
													vSrv.DiscountSum = 0;
													vSrv.VATDiscountSum = 0;
												EndIf;
											Else
												vRestOfCurAmount = vRestOfCurAmount + (vSrv.Sum - vSrv.DiscountSum);
												vRestOfServiceSum = vRestOfServiceSum + (vSrv.Sum - vSrv.DiscountSum);
											EndIf;
										ElsIf vCurServicePackageUsageType = Enums.ServicePackageUsageType.AddToRoomRatePrice Then
											If vCurRestOfRoomRateSrv <> Undefined Then
												If vCurRestOfRoomRateSrv.Sum > 0 Then
													// Recalculate rate sum
													vCurRoomRateSrv.Sum = vCurRoomRateSrv.Sum - (vSrv.Sum - vSrv.DiscountSum);
													vCurRoomRateSrv.VATSum = cmCalculateVATSum(vCurRoomRateSrv.VATRate, vCurRoomRateSrv.Sum, vCurRoomRateSrv.AccountingDate);
													vCurRoomRateSrv.Price = Round(vCurRoomRateSrv.Sum / ?(vCurRoomRateSrv.Quantity = 0, 1, vCurRoomRateSrv.Quantity), 2);
													If Not (ValueIsFilled(vSrv.DiscountType) And vSrv.DiscountType.SubtractDiscountFromRoomRevenueAmount And 
													        ValueIsFilled(vCurRoomRateSrv.DiscountType) And Not vCurRoomRateSrv.IsManual And Not vCurRoomRateSrv.DiscountIsChanged) Then
														pmCalculateServiceDiscounts(vCurRoomRateSrv);
													EndIf;
													pmSetServiceCommissions(vCurRoomRateSrv, vRoomRates, vComplexCommission);
													// Recalculate rest of rate sum
													vCurRestOfRoomRateSrv.Sum = vCurRestOfRoomRateSrv.Sum + (vSrv.Sum - vSrv.DiscountSum);
													vCurRestOfRoomRateSrv.VATSum = cmCalculateVATSum(vCurRestOfRoomRateSrv.VATRate, vCurRestOfRoomRateSrv.Sum, vCurRestOfRoomRateSrv.AccountingDate);
													vCurRestOfRoomRateSrv.Price = Round(vCurRestOfRoomRateSrv.Sum / ?(vCurRestOfRoomRateSrv.Quantity = 0, 1, vCurRestOfRoomRateSrv.Quantity), 2);
													pmSetServiceCommissions(vCurRestOfRoomRateSrv, vRoomRates, vComplexCommission);
												EndIf;
											EndIf;
										EndIf;
									EndIf;
									If vRestOfCurAmount > 0 Then
										If (vSrv.Sum - vSrv.DiscountSum) > vRestOfCurAmount Then
											vRestOfServiceSum = (vSrv.Sum - vSrv.DiscountSum) - vRestOfCurAmount;
											vSrv.Sum = vRestOfCurAmount;
											vSrv.Discount = 0;
											vSrv.DiscountSum = 0;
											vRestOfCurAmount = 0;
											// Recalculate price and VAT sum
											cmSumOnChange(vSrv.Service, vSrv.Price, vSrv.Quantity, vSrv.Sum, vSrv.VATRate, vSrv.VATSum, True, vSrv.AccountingDate);
											// Recalculate commission for this service if applicable
											pmCalculateServiceCommissions(vSrv);
										Else
											vRestOfCurAmount = vRestOfCurAmount - (vSrv.Sum - vSrv.DiscountSum);
											vRestOfServiceSum = 0;
										EndIf;
									ElsIf vRestOfServiceSum > 0 Then
										vSrv.Sum = vRestOfServiceSum;
										vSrv.Price = vRestOfServiceSum;
										vSrv.Quantity = 1;
										vSrv.Discount = 0;
										vSrv.DiscountSum = 0;
										vRestOfCurAmount = 0;
										vRestOfServiceSum = 0;
										// Recalculate VAT sum
										vSrv.VATSum = cmCalculateVATSum(vSrv.VATRate, vSrv.Sum, vSrv.AccountingDate);
										// Set is split and room revenue amounts only flags
										vSrv.IsSplit = True;
										If vSrv.IsRoomRevenue Then
											vSrv.RoomRevenueAmountsOnly = True;
											// Clear room sales parameters
											vSrv.RoomsRented = 0;
											vSrv.BedsRented = 0;
											vSrv.AdditionalBedsRented = 0;
											vSrv.GuestDays = 0;
											vSrv.GuestsCheckedIn = 0;
										EndIf;
										// Rest of room revenue amount per day
										If vCurRestOfRoomRateSrv = Undefined Then
											vCurRestOfRoomRateSrv = vSrv;
										EndIf;
									EndIf;
								EndIf;
								// Calculate commission for this service if applicable
								pmSetServiceCommissions(vSrv, vRoomRates, vComplexCommission);
								// Check if this is room rate service
								If vCurRoomRateSrv <> Undefined Then
									If Not vSrv.IsRoomRevenue And vSrv.IsInPrice Then
										If vPricesRow.PacketPriceIsIncludedInRoomRate And Not vCurRoomRateSrv.IsManualPrice Then
											If (vCurRoomRateSrv.Sum - vCurRoomRateSrv.DiscountSum) > (vSrv.Sum - vSrv.DiscountSum) Or Not vCurService.IsQuantitativeAccounting Then
												vCurRoomRateSrv.Sum = vCurRoomRateSrv.Sum - vSrv.Sum;
											Else
												vSrv.Sum = vCurRoomRateSrv.Sum;
												// Calculate discounts
												pmCalculateServiceDiscounts(vSrv);
												// Calculate commission for this service if applicable
												pmSetServiceCommissions(vSrv, vRoomRates, vComplexCommission);
												
												vCurRoomRateSrv.Sum = 0;
											EndIf;
											vSrv.RateSum = 0;
											vSrv.RateDiscountSum = 0;
											vSrv.RateCommissionSum = 0;
											
											// Recalculate VAT sum
											vCurRoomRateSrv.VATSum = cmCalculateVATSum(vCurRoomRateSrv.VATRate, vCurRoomRateSrv.Sum, vCurRoomRateSrv.AccountingDate);
											// Recalculate VAT sum
											vCurRoomRateSrv.Price = Round(vCurRoomRateSrv.Sum / ?(vCurRoomRateSrv.Quantity = 0, 1, vCurRoomRateSrv.Quantity), 2);
											
											If Not (ValueIsFilled(vSrv.DiscountType) And vSrv.DiscountType.SubtractDiscountFromRoomRevenueAmount And 
											        ValueIsFilled(vCurRoomRateSrv.DiscountType) And Not vCurRoomRateSrv.IsManual And Not vCurRoomRateSrv.DiscountIsChanged) Then
												// Calculate discounts
												pmCalculateServiceDiscounts(vCurRoomRateSrv);
											EndIf;
											// Calculate commission for this service if applicable
											pmSetServiceCommissions(vCurRoomRateSrv, vRoomRates, vComplexCommission);
										ElsIf vCurServicePackageUsageType = Enums.ServicePackageUsageType.AddToRoomRatePrice Then
											If Not vCurRoomRateSrv.IsManualPrice Then
												vCurRoomRateSrv.Sum = vCurRoomRateSrv.Sum + vSrv.Sum;    
												vCurRoomRateSrv.DiscountSum = vCurRoomRateSrv.DiscountSum + vSrv.DiscountSum;
												vCurRoomRateSrv.VATDiscountSum = vCurRoomRateSrv.VATDiscountSum + vSrv.VATDiscountSum;
												// Recalculate VAT sum
												vCurRoomRateSrv.VATSum = cmCalculateVATSum(vCurRoomRateSrv.VATRate, vCurRoomRateSrv.Sum, vCurRoomRateSrv.AccountingDate);
												// Recalculate price
												vCurRoomRateSrv.Price = Round(vCurRoomRateSrv.Sum / ?(vCurRoomRateSrv.Quantity = 0, 1, vCurRoomRateSrv.Quantity), 2);
												// Calculate commission for this service if applicable
												pmSetServiceCommissions(vCurRoomRateSrv, vRoomRates, vComplexCommission);
											EndIf;
											
											// Update current service
											If vCurServicePackage.IsMealBoardTerm Then
												vSrv.Quantity = 0;
											EndIf;
											vSrv.Sum = 0;
											vSrv.Price = 0;
											vSrv.DiscountSum = 0;
											vSrv.VATSum = 0;
											vSrv.VATDiscountSum = 0;
											vSrv.CommissionSum = 0;
											vSrv.VATCommissionSum = 0;
										ElsIf vCurServicePackageUsageType = Enums.ServicePackageUsageType.SubtractFromRoomRatePrice And Not vCurRoomRateSrv.IsManualPrice Then
											If (vCurRoomRateSrv.Sum - vCurRoomRateSrv.DiscountSum) > (vSrv.Sum - vSrv.DiscountSum) Or Not vCurService.IsQuantitativeAccounting Then
												vCurRoomRateSrv.Sum = vCurRoomRateSrv.Sum - vSrv.Sum;
											Else
												vSrv.Sum = vCurRoomRateSrv.Sum;
												// Calculate discounts
												pmCalculateServiceDiscounts(vSrv);
												// Calculate commission for this service if applicable
												pmSetServiceCommissions(vSrv, vRoomRates, vComplexCommission);
												
												vCurRoomRateSrv.Sum = 0;
											EndIf;
											vSrv.RateSum = 0;
											vSrv.RateDiscountSum = 0;
											vSrv.RateCommissionSum = 0;
											
											// Recalculate VAT sum
											vCurRoomRateSrv.VATSum = cmCalculateVATSum(vCurRoomRateSrv.VATRate, vCurRoomRateSrv.Sum, vCurRoomRateSrv.AccountingDate);
											// Recalculate VAT sum
											vCurRoomRateSrv.Price = Round(vCurRoomRateSrv.Sum / ?(vCurRoomRateSrv.Quantity = 0, 1, vCurRoomRateSrv.Quantity), 2);
											
											If Not (ValueIsFilled(vSrv.DiscountType) And vSrv.DiscountType.SubtractDiscountFromRoomRevenueAmount And 
											        ValueIsFilled(vCurRoomRateSrv.DiscountType) And Not vCurRoomRateSrv.IsManual And Not vCurRoomRateSrv.DiscountIsChanged) Then
												// Calculate discounts
												pmCalculateServiceDiscounts(vCurRoomRateSrv);
											EndIf;
											// Calculate commission for this service if applicable
											pmSetServiceCommissions(vCurRoomRateSrv, vRoomRates, vComplexCommission);
										EndIf;
										If ValueIsFilled(vMealBoardTermIncluded) And vMealBoardTermIncluded = vPricesRowServicePackage And ValueIsFilled(vPricesRowServicePackage.RoomRevenueService) Then
											// Add current meal board price to room rate price 
											If vPriceCorrection <> 0 And Not vCurRoomRateSrv.IsManualPrice And Not vCurRoomRateSrvHasManualPrice Then
												vCurRoomRateSrv.Price = vCurRoomRateSrv.Price + vPriceCorrection;
												vCurRoomRateSrv.Price = ?(vCurRoomRateSrv.Price < 0, 0, vCurRoomRateSrv.Price);
												// Recalculate sum
												vCurRoomRateSrv.Sum = Round(vCurRoomRateSrv.Price * vCurRoomRateSrv.Quantity, 2);
												// Recalculate VAT sum
												vCurRoomRateSrv.VATSum = cmCalculateVATSum(vCurRoomRateSrv.VATRate, vCurRoomRateSrv.Sum, vCurRoomRateSrv.AccountingDate);
												// Calculate service discounts
												If Not vDoNotApplyDiscountsToPriceCorrection Then
													pmCalculateServiceDiscounts(vCurRoomRateSrv);
												EndIf;
												// Calculate commission for this service if applicable
												pmSetServiceCommissions(vCurRoomRateSrv, vRoomRates, vComplexCommission);
											EndIf;
											// Update current service
											If vCurServicePackage.IsMealBoardTerm Then
												vSrv.Quantity = 0;
											EndIf;
											vSrv.Sum = 0;
											vSrv.Price = 0;
											vSrv.DiscountSum = 0;
											vSrv.VATSum = 0;
											vSrv.VATDiscountSum = 0;
											vSrv.CommissionSum = 0;
											vSrv.VATCommissionSum = 0;
											vSrv.RateSum = 0;
											vSrv.RateDiscountSum = 0;
											vSrv.RateCommissionSum = 0;
										ElsIf ValueIsFilled(vMealBoardTermIncluded) And ValueIsFilled(vPricesRowServicePackage) And vMealBoardTermIncluded <> vPricesRowServicePackage And vPricesRowServicePackage.IsMealBoardTerm And ValueIsFilled(vPricesRowServicePackage.RoomRevenueService) Then
											// Add current meal board price to room rate price 
											If vPriceCorrection <> 0 And Not vCurRoomRateSrv.IsManualPrice And Not vCurRoomRateSrvHasManualPrice Then
												vCurRoomRateSrv.Price = vCurRoomRateSrv.Price + vPriceCorrection;
												vCurRoomRateSrv.Price = ?(vCurRoomRateSrv.Price < 0, 0, vCurRoomRateSrv.Price);
												// Recalculate sum
												vCurRoomRateSrv.Sum = Round(vCurRoomRateSrv.Price * vCurRoomRateSrv.Quantity, 2);
												// Recalculate VAT sum
												vCurRoomRateSrv.VATSum = cmCalculateVATSum(vCurRoomRateSrv.VATRate, vCurRoomRateSrv.Sum, vCurRoomRateSrv.AccountingDate);
												// Calculate service discounts
												If Not vDoNotApplyDiscountsToPriceCorrection Then
													pmCalculateServiceDiscounts(vCurRoomRateSrv);
												EndIf;
												// Calculate commission for this service if applicable
												pmSetServiceCommissions(vCurRoomRateSrv, vRoomRates, vComplexCommission);
											EndIf;
											// Update current service
											If vCurServicePackage.IsMealBoardTerm Then
												vSrv.Quantity = 0;
											EndIf;
											vSrv.Sum = 0;
											vSrv.Price = 0;
											vSrv.DiscountSum = 0;
											vSrv.VATSum = 0;
											vSrv.VATDiscountSum = 0;
											vSrv.CommissionSum = 0;
											vSrv.VATCommissionSum = 0;
											vSrv.RateSum = 0;
											vSrv.RateDiscountSum = 0;
											vSrv.RateCommissionSum = 0;
										EndIf;
									EndIf;
								EndIf;
								// Try to restore author and date of services added manually or from manually added service packages
								If Not vSrv.IsManual Then
									If vIsManualServices.Count() > 0 Then
										vIsManualServicesRows = vIsManualServices.FindRows(New Structure("ServicePackage, AccountingDate, Service", vSrv.ServicePackage, vSrv.AccountingDate, vSrv.Service));
										For Each vIsManualServicesRow In vIsManualServicesRows Do
											vSrv.IsManualAuthor = vIsManualServicesRow.IsManualAuthor;
											vSrv.IsManualDate = vIsManualServicesRow.IsManualDate;
											Break;
										EndDo;
									EndIf;
								EndIf;
								// Try to find current service in the table of services changed manually
								If vSrv.Quantity <> 0 Or vSrv.Price <> 0 Then
									If vMCServices.Count() > 0 Then
										If vSrv.IsRoomRevenue And vSrv.IsInPrice And Not vSrv.IsManual And Not vSrv.IsSplit Then
											vMCSrvRows = vMCServices.FindRows(New Structure("AccountingDate, Service, IsRoomRevenue, IsInPrice, IsManual, IsSplit, AccommodationType", vSrv.AccountingDate, vSrv.Service, vSrv.IsRoomRevenue, vSrv.IsInPrice, vSrv.IsManual, vSrv.IsSplit, vSrv.AccommodationType));
										Else
											vMCSrvRows = vMCServices.FindRows(New Structure("AccountingDate, Service, IsSplit, AccommodationType", vSrv.AccountingDate, vSrv.Service, vSrv.IsSplit, vSrv.AccommodationType));
										EndIf;
										If vMCSrvRows.Count() > 0 Then
											vMCSrv = vMCSrvRows.Get(0);
											FillPropertyValues(vSrv, vMCSrv, , "LineNumber, Folio, Company, Room, RoomType, AccommodationType, RoomRate, GuestsCheckedIn, GuestDays, AdditionalBedsRented, BedsRented, RoomsRented, Timetable, CalendarDayType, ServicePackage, RateSum, RateDiscountSum, RateCommissionSum, ClientType, SourceOfBusiness, MarketingCode, BoardPlace" + 
											                                   ?(vMCSrv.QuantityIsChanged, "", ", Quantity") + 
																			   ?(vMCSrv.DiscountIsChanged, "", ", DiscountType, Discount, DiscountServiceGroup, DiscountSum, VATDiscountSum, DiscountConfirmationText") + 
																			   ?(vMCSrv.CommissionIsChanged, "", ", AgentCommissionType, AgentCommission, CommissionSum, VATCommissionSum"));
											// Recalculate amount and VAT sum
											cmPriceOnChange(vSrv.Price, vSrv.Quantity, vSrv.Sum, vSrv.VATRate, vSrv.VATSum, vSrv.AccountingDate);
											// Recalculate discount for this service if applicable
											If Not vMCSrv.DiscountIsChanged Then
												pmCalculateServiceDiscounts(vSrv);
											EndIf;
											// Recalculate commission for this service if applicable
											If Not vMCSrv.CommissionIsChanged Then
												pmCalculateServiceCommissions(vSrv);
											EndIf;
											// Recalculate service room sales parameters
											cmRecalculateServiceRoomSalesParameters(vSrv, ThisObject);
										EndIf;
									EndIf;
								EndIf;
								// Check if we should apply discount to room revenue service only
								If Not vSrv.IsRoomRevenue And vSrv.IsInPrice And Not vSrv.IsManual And Not vSrv.DiscountIsChanged Then
									If ValueIsFilled(vSrv.DiscountType) And vSrv.DiscountType.SubtractDiscountFromRoomRevenueAmount Then
										If vCurRoomRateSrv <> Undefined And ValueIsFilled(vCurRoomRateSrv.DiscountType) And Not vCurRoomRateSrv.IsManual And Not vCurRoomRateSrv.DiscountIsChanged Then
											If Not ((vPricesRow.PacketPriceIsIncludedInRoomRate Or vCurServicePackageUsageType = Enums.ServicePackageUsageType.SubtractFromRoomRatePrice) And Not vCurRoomRateSrv.IsManualPrice) Then
												vCurRoomRateSrv.DiscountSum = vCurRoomRateSrv.DiscountSum + vSrv.DiscountSum;
												vCurRoomRateSrv.VATDiscountSum = cmCalculateVATSum(vCurRoomRateSrv.VATRate, vCurRoomRateSrv.DiscountSum, vCurRoomRateSrv.AccountingDate);
											EndIf;
											
											vSrv.DiscountSum = 0;
											vSrv.VATDiscountSum = 0;
											vSrv.Discount = 0;
											vSrv.DiscountType = DiscountType;
											vSrv.DiscountServiceGroup = DiscountServiceGroup;
											vSrv.DiscountConfirmationText = DiscountConfirmationText;

											pmCalculateServiceCommissions(vSrv);
										EndIf;
									EndIf;
								EndIf;
								// Add room upgrade service if neccessary
								If ValueIsFilled(vUpgradeService) And vUpgradePrice <> 0 Then
									// Add service
									vUpgrdSrv = Services.Insert(i);
									i = i + 1;
									FillPropertyValues(vUpgrdSrv, vSrv);
									vUpgrdSrv.Service = vUpgradeService;
									// Recalculate folio by charging rules
									pmSetServiceFolioBasedOnChargingRules(vUpgrdSrv, vCRTab, True);
									If ValueIsFilled(vUpgrdSrv.Folio) And vUpgrdSrv.Folio <> vSrv.Folio Then
										vUpgrdSrv.FolioCurrency = vUpgrdSrv.Folio.FolioCurrency;
										vUpgrdSrv.FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, vUpgrdSrv.FolioCurrency, ?(ValueIsFilled(vUpgrdSrv.AccountingDate), vUpgrdSrv.AccountingDate, ExchangeRateDate));
									EndIf;
									If vUpgrdSrv.FolioCurrency <> vSrv.FolioCurrency Then
										vUpgrdSrv.Price = Round(cmConvertCurrencies(vUpgradePrice, vSrv.FolioCurrency, , vUpgrdSrv.FolioCurrency, , ?(ValueIsFilled(vUpgrdSrv.AccountingDate), vUpgrdSrv.AccountingDate, ExchangeRateDate), Hotel), 2);
									Else
										vUpgrdSrv.Price = vUpgradePrice;
									EndIf;
									// Recalculate amount and VAT sum
									cmPriceOnChange(vUpgrdSrv.Price, vUpgrdSrv.Quantity, vUpgrdSrv.Sum, vUpgrdSrv.VATRate, vUpgrdSrv.VATSum, vUpgrdSrv.AccountingDate);
									// Reset discounts and commissions
									vUpgrdSrv.DiscountType = Undefined;
									vUpgrdSrv.Discount = 0;
									vUpgrdSrv.DiscountSum = 0;
									vUpgrdSrv.VATDiscountSum = 0;
									vUpgrdSrv.DiscountServiceGroup = Undefined;
									vUpgrdSrv.DiscountConfirmationText = "";
									vUpgrdSrv.AgentCommissionType = Undefined;
									vUpgrdSrv.AgentCommission = 0;
									vUpgrdSrv.CommissionSum = 0;
									vUpgrdSrv.VATCommissionSum = 0;
									// Reset room inventory resources
									vUpgrdSrv.RoomsRented = 0;
									vUpgrdSrv.BedsRented = 0;
									vUpgrdSrv.AdditionalBedsRented = 0;
									vUpgrdSrv.GuestDays = 0;
									vUpgrdSrv.GuestsCheckedIn = 0;
									// Flags
									vUpgrdSrv.RoomRevenueAmountsOnly = True;
									vUpgrdSrv.IsManual = False;
									vUpgrdSrv.IsManualPrice = False;
									vUpgrdSrv.IsSplit = False;
									// Remarks
									vUpgrdSrv.Remarks = TrimAll(vOffer);
									// Other
									vUpgrdSrv.RateSum = 0;
									vUpgrdSrv.RateDiscountSum = 0;
									vUpgrdSrv.RateCommissionSum = 0;
								Else
									If vSrv.IsRoomRevenue And vSrv.IsInPrice Then
										If Not IsBlankString(vOfferByRoomTypeUpgradeDescription) Then
											If StrFind(vSrv.Remarks, vOfferByRoomTypeUpgradeDescription) = 0 Then
												vSrv.Remarks = vSrv.Remarks + ?(IsBlankString(vSrv.Remarks), "", ", ") + vOfferByRoomTypeUpgradeDescription;
											EndIf;
										EndIf;
										If Not IsBlankString(vOfferByTermsUpgradeDescription) Then
											If StrFind(vSrv.Remarks, vOfferByTermsUpgradeDescription) = 0 Then
												vSrv.Remarks = vSrv.Remarks + ?(IsBlankString(vSrv.Remarks), "", ", ") + vOfferByTermsUpgradeDescription;
											EndIf;
										EndIf;
									ElsIf vCurRoomRateSrv <> Undefined Then
										If Not IsBlankString(vOfferByRoomTypeUpgradeDescription) Then
											If StrFind(vCurRoomRateSrv.Remarks, vOfferByRoomTypeUpgradeDescription) = 0 Then
												vCurRoomRateSrv.Remarks = vCurRoomRateSrv.Remarks + ?(IsBlankString(vCurRoomRateSrv.Remarks), "", ", ") + vOfferByRoomTypeUpgradeDescription;
											EndIf;
										EndIf;
										If Not IsBlankString(vOfferByTermsUpgradeDescription) Then
											If StrFind(vCurRoomRateSrv.Remarks, vOfferByTermsUpgradeDescription) = 0 Then
												vCurRoomRateSrv.Remarks = vCurRoomRateSrv.Remarks + ?(IsBlankString(vCurRoomRateSrv.Remarks), "", ", ") + vOfferByTermsUpgradeDescription;
											EndIf;
										EndIf;
									EndIf;
								EndIf;
								// We've found suitable charging rule so move to the other service
								If vChargingRuleAmountIsSet Then
									If vRestOfCurAmount > 0 Then
										Break;
									ElsIf vRestOfServiceSum <= 0 Then
										Break;
									EndIf;
								Else
									If vRestOfCurPrice = 0 Then
										Break;
									EndIf;
								EndIf;
							EndIf;
						EndIf;
					EndDo;
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	// Check amount discount
	If vIsAmountDiscount And DiscountSum <> 0 Then
		vDiscountSum = DiscountSum;
		vNumServices = Services.Count();
		If vNumServices > 0 Then
			// Do first run
			vNumDiscountServices = 0;
			vFirstRunDiscountSum = Int(vDiscountSum/vNumServices);
			For Each vSrvRow In Services Do
				If vSrvRow.Sum <> 0 And vSrvRow.Sum >= vFirstRunDiscountSum And 
				   cmIsServiceInServiceGroup(vSrvRow.Service, DiscountServiceGroup) Then
					vSrvRow.DiscountSum = vFirstRunDiscountSum;
					vSrvRow.VATDiscountSum = cmCalculateVATSum(vSrvRow.VATRate, vSrvRow.DiscountSum, vSrvRow.AccountingDate);
					vDiscountSum = vDiscountSum - vFirstRunDiscountSum;
					vNumDiscountServices = vNumDiscountServices + 1;
				EndIf;
			EndDo;
			// Do second run
			If vDiscountSum <> 0 And vNumDiscountServices > 0 Then
				vSecondRunDiscountSum = Round(vDiscountSum/vNumDiscountServices, 2);
				For Each vSrvRow In Services Do
					If vSrvRow.Sum <> 0 And vSrvRow.Sum >= vSecondRunDiscountSum And 
					   cmIsServiceInServiceGroup(vSrvRow.Service, DiscountServiceGroup) Then
						If vDiscountSum > 0 Then
							If vDiscountSum > vSecondRunDiscountSum Then
								vSrvRow.DiscountSum = vSrvRow.DiscountSum + vSecondRunDiscountSum;
								vDiscountSum = vDiscountSum - vSecondRunDiscountSum;
							Else
								vSrvRow.DiscountSum = vSrvRow.DiscountSum + vDiscountSum;
								vDiscountSum = 0;
							EndIf;
						Else
							If vDiscountSum < vSecondRunDiscountSum Then
								vSrvRow.DiscountSum = vSrvRow.DiscountSum + vSecondRunDiscountSum;
								vDiscountSum = vDiscountSum - vSecondRunDiscountSum;
							Else
								vSrvRow.DiscountSum = vSrvRow.DiscountSum + vDiscountSum;
								vDiscountSum = 0;
							EndIf;
						EndIf;
						vSrvRow.VATDiscountSum = cmCalculateVATSum(vSrvRow.VATRate, vSrvRow.DiscountSum, vSrvRow.AccountingDate);
					EndIf;
				EndDo;
			EndIf;
			// Do third run
			If vDiscountSum <> 0 And vNumDiscountServices > 0 Then
				For Each vSrvRow In Services Do
					If vSrvRow.Sum <> 0 And vSrvRow.Sum >= vDiscountSum And 
					   cmIsServiceInServiceGroup(vSrvRow.Service, DiscountServiceGroup) Then
						vSrvRow.DiscountSum = vSrvRow.DiscountSum + vDiscountSum;
						vSrvRow.VATDiscountSum = cmCalculateVATSum(vSrvRow.VATRate, vSrvRow.DiscountSum, vSrvRow.AccountingDate);
						vDiscountSum = 0;
						Break;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	// Calculate price presentation
	vPricePresentation = pmCalculatePricePresentation();
	If TrimAll(vPricePresentation) <> TrimAll(PricePresentation) Then
		PricePresentation = TrimAll(vPricePresentation);
	EndIf;
	// Check should we call this function recursively to recalculate discounts
	If vPeriodDiscount <> pPeriodDiscount Then
		Return pmCalculateServices(rWarnings, vPeriodDiscount, vPeriodDiscountType, 
		                                      vPeriodDiscountServiceGroup, vPeriodDiscountConfirmationText);
	Else
		// Update discount confirmation text for special offers
		If Not IsBlankString(vOfferByRoomTypeUpgradeDescription) And StrFind(DiscountConfirmationText, vOfferByRoomTypeUpgradeDescription) = 0 Then
			DiscountConfirmationText = ?(IsBlankString(DiscountConfirmationText), "", TrimR(DiscountConfirmationText)) + Char(8226) + " " + vOfferByRoomTypeUpgradeDescription;
		EndIf;
		If Not IsBlankString(vOfferByTermsUpgradeDescription) And StrFind(DiscountConfirmationText, vOfferByTermsUpgradeDescription) = 0 Then
			DiscountConfirmationText = ?(IsBlankString(DiscountConfirmationText), "", TrimR(DiscountConfirmationText)) + Char(8226) + " " + vOfferByTermsUpgradeDescription;
		EndIf;
		If Not IsBlankString(DiscountConfirmationText) And StrFind(DiscountConfirmationText, Char(8226)) = 0 Then
			DiscountConfirmationText = TrimAll(DiscountConfirmationText) + Char(8226);
		EndIf;
		// Check available quantity
		For Each vSrv In Services Do
			If vSrv.Quantity = 0 Then
				Continue;
			EndIf;
			vCurService = vSrv.Service;
			If ValueIsFilled(vSrv.AccountingDate) And ValueIsFilled(vCurService) And vCurService.AvailableQuantity <> 0 Then
				vAvailableQuantity = vCurService.AvailableQuantity;
				vUsedQuantity = cmGetServiceUsedQuantity(vCurService, BegOfDay(vSrv.AccountingDate), cmExtractTime(BegOfDay(vSrv.AccountingDate)), cmExtractTime(EndOfDay(vSrv.AccountingDate)), Ref);
				If (vAvailableQuantity - vUsedQuantity - vSrv.Quantity) <= 0 Then
					rWarnings = "en='" + "[" + Format(vSrv.AccountingDate, "DF=dd.MM.yyyy") + "] " + TrimAll(vCurService) + " - There is: " + vAvailableQuantity + "; Used: " + vUsedQuantity + "'; " + 
					            "ru='" + "[" + Format(vSrv.AccountingDate, "DF=dd.MM.yyyy") + "] " + TrimAll(vCurService) + " - Есть: " + vAvailableQuantity + "; Использовано: " + vUsedQuantity + "'; " + 
					            "de='" + "[" + Format(vSrv.AccountingDate, "DF=dd.MM.yyyy") + "] " + TrimAll(vCurService) + " - Es gibt: " + vAvailableQuantity + "; Gebraucht: " + vUsedQuantity + "'";
					vWarnings = True;
				EndIf;
			EndIf;
		EndDo;
		// Process warnings
		If IsBlankString(rWarnings) Then
			vWarningsEn = "";
			vWarningsDe = "";
			vWarningsRu = "";
			If vNoAccommodationService And NumberOfBeds > 0 Then
				If ValueIsFilled(RoomRate) And 
				   ValueIsFilled(vRoomType) And 
				   ValueIsFilled(AccommodationType) And 
				   Not ValueIsFilled(RoomQuota) And 
				   Not vRoomType.IsVirtual And
				   (RoomRate.RateChargeDirection <> Enums.RateChargeDirections.MergeToTheMainRoomGuest Or 
				    RoomRate.RateChargeDirection = Enums.RateChargeDirections.MergeToTheMainRoomGuest And ValueIsFilled(AccommodationTemplate)) Then
					vWarnings = True;
					vWarningsEn = "For accommodation period " + Format(CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ", room rate " + RoomRate + ", room type " + vRoomType + " and accommodation type " + AccommodationType + " accommodation services will not be charged!";
					vWarningsDe = "For accommodation period " + Format(CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ", room rate " + RoomRate + ", room type " + vRoomType + " and accommodation type " + AccommodationType + " accommodation services will not be charged!";
					vWarningsRu = "Для периода проживания " + Format(CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ", тарифа " + RoomRate + ", типа номера " + vRoomType + " и вида размещения " + AccommodationType + " услуги проживания начислены не будут!";
				EndIf;
			EndIf;
			If vWarnings Then
				rWarnings = "ru = '" + vWarningsRu + "'; de = '" + vWarningsDe + "'; en = '" + vWarningsEn + "'";
				If ValueIsFilled(ReservationStatus) Then
					If Not ReservationStatus.IsActive And 
					   (ReservationStatus.DoNoShowCharging Or ReservationStatus.DoLateAnnulationCharging) Then
						WriteLogEvent(NStr("en='Reservation.CalculateServices';ru='Резервирование.РасчетУслуг';de='Reservation.CalculateServices'"), EventLogLevel.Warning, Metadata(), Ref, NStr(rWarnings));
						vWarnings = False;
						rWarnings = "";
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If vWarnings And Not IsBlankString(rWarnings) Then
		WriteLogEvent(NStr("en='Reservation.CalculateServices';ru='Резервирование.РасчетУслуг';de='Reservation.CalculateServices'"), EventLogLevel.Warning, Metadata(), Ref, NStr(rWarnings));
	EndIf;
~pmCalculateServicesEnd:
	// Fill rate price for accommodation services
	i = 0;
	While i < Services.Count() Do
		vSrvRow = Services.Get(i);
		If vSrvRow.IsInPrice And vSrvRow.IsRoomRevenue And Not vSrvRow.RoomRevenueAmountsOnly And Not vSrvRow.IsSplit Then
			vAccountingDate = vSrvRow.AccountingDate;
			vSrvRow.RateSum = vSrvRow.Sum;
			vSrvRow.RateDiscountSum = vSrvRow.DiscountSum;
			vSrvRow.RateCommissionSum = vSrvRow.CommissionSum;
			// Read other services
			i = i + 1;
			While i < Services.Count() Do
				vNextSrvRow = Services.Get(i);
				vNextSrvRow.RateSum = 0;
				vNextSrvRow.RateDiscountSum = 0;
				vNextSrvRow.RateCommissionSum = 0;
				If vNextSrvRow.IsInPrice And Not (vNextSrvRow.IsRoomRevenue And Not vNextSrvRow.RoomRevenueAmountsOnly And Not vNextSrvRow.IsSplit) Then
					vNextSrvRowAccountingDate = vNextSrvRow.AccountingDate;
					If BegOfDay(CheckInDate) < BegOfDay(CheckOutDate) Then
						vNextSrvRowService = vNextSrvRow.Service;
						If ValueIsFilled(vNextSrvRowService) And ValueIsFilled(vNextSrvRowService.QuantityCalculationRule) Then
							vAccountingDateMove = cmGetAccountingDateMove(vNextSrvRowService.QuantityCalculationRule, vNextSrvRow.IsManual, ThisObject, False);
							If vAccountingDateMove < 0 Then
								vNextSrvRowAccountingDate = vNextSrvRowAccountingDate + vAccountingDateMove*(24*3600);
							EndIf;
						EndIf;
					EndIf;
					If vNextSrvRowAccountingDate = vAccountingDate Then
						If vSrvRow.Folio = vNextSrvRow.Folio Then
							vSrvRow.RateSum = vSrvRow.RateSum + vNextSrvRow.Sum;
							vSrvRow.RateDiscountSum = vSrvRow.RateDiscountSum + vNextSrvRow.DiscountSum;
							vSrvRow.RateCommissionSum = vSrvRow.RateCommissionSum + vNextSrvRow.CommissionSum;
						EndIf;
					Else
						i = i + 1;
						Break;
					EndIf;
				ElsIf vNextSrvRow.IsInPrice And vNextSrvRow.IsRoomRevenue And Not vNextSrvRow.RoomRevenueAmountsOnly And Not vNextSrvRow.IsSplit Then
					Break;
				EndIf;
				i = i + 1;
			EndDo;
		Else
			vSrvRow.RateSum = 0;
			vSrvRow.RateDiscountSum = 0;
			vSrvRow.RateCommissionSum = 0;
			i = i + 1;
		EndIf;
	EndDo;
	// Remove services without quantity and price
	i = 0;
	While i < Services.Count() Do
		vSrvRow = Services.Get(i);
		If Not vSrvRow.IsManual And Not vSrvRow.IsManualPrice And Not vSrvRow.QuantityIsChanged And 
		   vSrvRow.Quantity = 0 And vSrvRow.Sum = 0 Then
			Services.Delete(i);
		Else
			i = i + 1;
		EndIf;
	EndDo;
	// Calculate room rate amount in base currency and duration in days
	pmCalculateRateAmountAndDurationInDays();
	// Process tourist tax if neccessary
	pmCalculateTouristTax(vCheckInDate);
	// User exit after calculate services
	vAfterCalculateServicesUserExit = Catalogs.ExternalDataProcessors.ReservationAfterCalculateServices;
	If vAfterCalculateServicesUserExit.ExternalProcessingType = Enums.ExternalProcessingTypes.Algorithm And Not IsBlankString(vAfterCalculateServicesUserExit.Algorithm) Then
		SetSafeMode(True);
		Execute(TrimR(vAfterCalculateServicesUserExit.Algorithm));
		SetSafeMode(False);
	EndIf;
	Return vWarnings;
EndFunction // pmCalculateServices

// -----------------------------------------------------------------------------
Procedure pmCalculateTouristTax(pCheckInDate = '00010101') Export
	vCheckInDate = pCheckInDate;
	If Not ValueIsFilled(vCheckInDate) Then 
		vCheckInDate = CheckInDate;
	EndIf;

	vIsGroupMainClientDoc = False;
	vTouristicTaxIsCalculatedForMainGroupDocumentOnly = False;
	If ValueIsFilled(GuestGroup) And GuestGroup.TouristicTaxIsCalculatedForMainGroupDocumentOnly Then
		vTouristicTaxIsCalculatedForMainGroupDocumentOnly = True;
		If GuestGroup.ClientDoc = Ref Then
			vIsGroupMainClientDoc = True;
		EndIf;
	EndIf;
	vIsRoomMainClientDoc = False;
	vTouristicTaxIsCalculatedForMainRoomDocumentOnly = False;

	vTouristTaxAmountPerDate = 0;
	vTouristTaxSumInBaseCurrency = 0;
	If Hotel.TouristTaxIsUsed And ValueIsFilled(RoomRate) And Not RoomRate.IsStateContract Then
		vNoVATVatRate = cmGetNoVATVATRate();
		vStartDate = '20250101';

		// Get rate amount for all documents in the group
		If vIsGroupMainClientDoc Then
			RateSumInBaseCurrency = RateSumInBaseCurrency + cmGetOtherGroupDocumentsRateSum(GuestGroup);
		ElsIf Not vTouristicTaxIsCalculatedForMainGroupDocumentOnly And Not IsForFolioSplit And 
		      RoomRate.RateChargeDirection <> Enums.RateChargeDirections.MergeToTheMainRoomGuest Then
			vTouristicTaxIsCalculatedForMainRoomDocumentOnly = True;
			If ValueIsFilled(AccommodationTemplate) Then
				vIsRoomMainClientDoc = True;
				RateSumInBaseCurrency = RateSumInBaseCurrency + cmGetOtherRoomDocumentsRateSum(Ref);
			EndIf;
		EndIf;
		
		vDoNotMergeTouristTaxBaseToTheMainRoomGuest = GetDoNotMergeTouristTaxBaseToTheMainRoomGuest();
		
		// Create table of charging rules
		vChargingRules = ChargingRules.Unload();
		If Not IgnoreGroupChargingRules Then
			cmAddGuestGroupChargingRules(vChargingRules, GuestGroup);
		EndIf;
		
		// Build table with in price services to calculate tourist tax base amount per dates
		vRoomPriceService = Undefined;
		vInPriceServices = Services.Unload(New Structure("IsInPrice", True), 
		                                   "LineNumber, AccountingDate, Service, Sum, DiscountSum, VATRate, AccommodationType, " + 
		                                   "BoardPlace, CalendarDayType, ClientType, Company, MarketingCode, SourceOfBusiness, " + 
		                                   "PriceTag, Room, RoomType, RoomRate, FolioCurrency, FolioCurrencyExchangeRate, " + 
		                                   "IsManual, IsRoomRevenue, RoomRevenueAmountsOnly, IsSplit");
		For Each vInPriceServicesRow In vInPriceServices Do
			vInPriceServicesRowService = vInPriceServicesRow.Service;
			If vRoomPriceService = Undefined And ValueIsFilled(vInPriceServicesRowService) Then
				If vInPriceServicesRow.IsRoomRevenue And Not vInPriceServicesRow.RoomRevenueAmountsOnly And Not vInPriceServicesRow.IsSplit Then
					vRoomPriceService = vInPriceServicesRowService;
				EndIf;
			EndIf;
			If Not vInPriceServicesRow.IsManual And ValueIsFilled(vInPriceServicesRowService) And 
			   ValueIsFilled(vInPriceServicesRowService.QuantityCalculationRule) Then
				vAccountingDateMove = cmGetAccountingDateMove(vInPriceServicesRowService.QuantityCalculationRule, vInPriceServicesRow.IsManual, ThisObject, False);
				If vAccountingDateMove < 0 Then
					vInPriceServicesRow.AccountingDate = vInPriceServicesRow.AccountingDate + vAccountingDateMove*(24*3600);
				EndIf;
			EndIf;
		EndDo;
		vInPriceServices.Sort("AccountingDate, LineNumber");

		vTouristTaxService = Undefined;
		vTouristTaxAddToRate = Hotel.TouristTaxAddToRate;
		vTouristTaxSubtractFromRateIfExemption = Hotel.TouristTaxSubtractFromRateIfExemption;
		If ValueIsFilled(RoomRate) Then
			If ValueIsFilled(RoomRate.TouristTaxService) Then
				vTouristTaxService = RoomRate.TouristTaxService;
				vTouristTaxAddToRate = False;
				vTouristTaxSubtractFromRateIfExemption = False;
			ElsIf RoomRate.TouristTaxAddToRate Then
				vTouristTaxAddToRate = RoomRate.TouristTaxAddToRate;
				vTouristTaxSubtractFromRateIfExemption = False;
				vTouristTaxService = Undefined;
			ElsIf RoomRate.TouristTaxSubtractFromRateIfExemption Then
				vTouristTaxSubtractFromRateIfExemption = RoomRate.TouristTaxSubtractFromRateIfExemption;
				vTouristTaxAddToRate = False;
				vTouristTaxService = Undefined;
			EndIf;
		EndIf;
		
		vTouristTaxAccountingDate = TouristicTaxAccountingDate;
		vTouristTaxAmountPerDate = 0;
		If ValueIsFilled(vRoomPriceService) Then
			If ValueIsFilled(GuestGroup) And GuestGroup.TouristicTaxIsCalculatedForMainGroupDocumentOnly Then
				vTouristTaxAmountPerDate = cmCalculateTouristTaxSum(Hotel, vRoomPriceService.IsHotelProductService, vTouristTaxAccountingDate, RateSumInBaseCurrency, DurationInDays, Guest, GuestAge, CheckInDate, CheckOutDate, vTouristTaxService, TouristicTaxExemptionReason, TouristicTaxExemptionReasonFillDate, TouristTaxRate, MinAmountPerDay, TouristicTaxIsByMinAmount, True, 1, RoomRate);
			Else
				vTouristTaxAmountPerDate = cmCalculateTouristTaxSum(Hotel, vRoomPriceService.IsHotelProductService, vTouristTaxAccountingDate, RateSumInBaseCurrency, DurationInDays, Guest, GuestAge, CheckInDate, CheckOutDate, vTouristTaxService, TouristicTaxExemptionReason, TouristicTaxExemptionReasonFillDate, TouristTaxRate, MinAmountPerDay, TouristicTaxIsByMinAmount, True, RoomQuantity, RoomRate);
			EndIf;
			If ValueIsFilled(vTouristTaxAccountingDate) Then
				If TouristicTaxAccountingDate <> vTouristTaxAccountingDate Then
					TouristicTaxAccountingDate = vTouristTaxAccountingDate;
				EndIf;
			EndIf;
		EndIf;
		
		vCurAccountingDate = '00010101';
		vRoomRateServiceRowPerDate = Undefined;
		vFirstLineNumberPerDate = 0;
		vLastLineNumberPerDate = 0;
		vLineNumberShift = 0;
		vTouristTaxBaseAmountPerDate = 0;
		For Each vInPriceServicesRow In vInPriceServices Do
			If ValueIsFilled(vCurAccountingDate) And vCurAccountingDate <> vInPriceServicesRow.AccountingDate Then
				If ValueIsFilled(vTouristTaxAccountingDate) And vTouristTaxBaseAmountPerDate <> 0 And vTouristTaxAmountPerDate <> 0 And vCurAccountingDate >= vStartDate Then
					If Not vTouristicTaxIsCalculatedForMainGroupDocumentOnly And Not vTouristicTaxIsCalculatedForMainRoomDocumentOnly Or
					   vIsGroupMainClientDoc Or vIsRoomMainClientDoc Or 
					   vTouristicTaxIsCalculatedForMainRoomDocumentOnly And Not vIsRoomMainClientDoc And 
					   (vDoNotMergeTouristTaxBaseToTheMainRoomGuest Or IsForFolioSplit) Then
						If Not ValueIsFilled(TouristicTaxExemptionReason) Then
							If ValueIsFilled(vTouristTaxService) Then
								InsertTouristTaxRow(vLastLineNumberPerDate, vLineNumberShift, vCurAccountingDate, vTouristTaxService, vTouristTaxAmountPerDate, vTouristTaxBaseAmountPerDate, vRoomRateServiceRowPerDate, vNoVATVatRate, vChargingRules);
								vLineNumberShift = vLineNumberShift + 1;
							ElsIf vTouristTaxAddToRate And vFirstLineNumberPerDate > 0 Then
								vSrvRow = Services.Get(vFirstLineNumberPerDate - 1);
								vSrvRow.Price = vSrvRow.Price + vTouristTaxAmountPerDate;
								vSrvRow.RateSum = vSrvRow.RateSum + vTouristTaxAmountPerDate * RoomQuantity;
								cmPriceOnChange(vSrvRow.Price, vSrvRow.Quantity, vSrvRow.Sum, vSrvRow.VATRate, vSrvRow.VATSum, vSrvRow.AccountingDate);
								pmCalculateServiceDiscounts(vSrvRow);
								pmCalculateServiceCommissions(vSrvRow);
								If vSrvRow.DiscountSum <> 0 And vSrvRow.Discount <> 0 Then
									vSrvRow.RateDiscountSum = vSrvRow.RateDiscountSum + Round(vTouristTaxAmountPerDate * vSrvRow.Discount / 100, 2);
								EndIf;
								If vSrvRow.CommissionSum <> 0 And vSrvRow.AgentCommission <> 0 Then
									If vSrvRow.AgentCommissionType = Enums.AgentCommissionTypes.Percent Then
										vSrvRow.RateCommissionSum = vSrvRow.RateCommissionSum + Round(vTouristTaxAmountPerDate * vSrvRow.AgentCommission / 100, 2);
									ElsIf vSrvRow.AgentCommissionType = Enums.AgentCommissionTypes.FirstDayPercent And vSrvRow.GuestsCheckedIn <> 0 Then
										vSrvRow.RateCommissionSum = vSrvRow.RateCommissionSum + Round(vTouristTaxAmountPerDate * vSrvRow.AgentCommission / 100, 2);
									EndIf;
								EndIf;
							EndIf;
						ElsIf vTouristTaxSubtractFromRateIfExemption And vFirstLineNumberPerDate > 0 Then
							vSrvRow = Services.Get(vFirstLineNumberPerDate - 1);
							vSrvRow.Price = vSrvRow.Price - vTouristTaxAmountPerDate;
							cmPriceOnChange(vSrvRow.Price, vSrvRow.Quantity, vSrvRow.Sum, vSrvRow.VATRate, vSrvRow.VATSum, vSrvRow.AccountingDate);
							pmCalculateServiceDiscounts(vSrvRow);
							pmCalculateServiceCommissions(vSrvRow);
						EndIf;
					EndIf;
				EndIf;
				vTouristTaxBaseAmountPerDate = 0;
				vRoomRateServiceRowPerDate = Undefined;
			EndIf;
			vCurAccountingDate = vInPriceServicesRow.AccountingDate;
			If vInPriceServicesRow.IsRoomRevenue And Not vInPriceServicesRow.RoomRevenueAmountsOnly And Not vInPriceServicesRow.IsSplit Then
				vFirstLineNumberPerDate = vInPriceServicesRow.LineNumber;
			EndIf;
			vLastLineNumberPerDate = vInPriceServicesRow.LineNumber;
			vTouristTaxBaseAmount = (vInPriceServicesRow.Sum - vInPriceServicesRow.DiscountSum) - cmCalculateVATSum(vInPriceServicesRow.VATRate, (vInPriceServicesRow.Sum - vInPriceServicesRow.DiscountSum), vInPriceServicesRow.AccountingDate);
			vTouristTaxBaseAmountInBaseCurrency = Round(cmConvertCurrencies(vTouristTaxBaseAmount, vInPriceServicesRow.FolioCurrency, vInPriceServicesRow.FolioCurrencyExchangeRate, Hotel.BaseCurrency, , vInPriceServicesRow.AccountingDate, Hotel), 2);
			vTouristTaxBaseAmountPerDate = vTouristTaxBaseAmountPerDate + vTouristTaxBaseAmountInBaseCurrency;
			If vRoomRateServiceRowPerDate = Undefined And 
			   vInPriceServicesRow.IsRoomRevenue And 
			   Not vInPriceServicesRow.RoomRevenueAmountsOnly And
			   Not vInPriceServicesRow.IsSplit Then
				vRoomRateServiceRowPerDate = vInPriceServicesRow;
			EndIf;
		EndDo;
		If ValueIsFilled(vTouristTaxAccountingDate) And vTouristTaxBaseAmountPerDate <> 0 And vTouristTaxAmountPerDate <> 0 And vCurAccountingDate >= vStartDate Then
			If Not vTouristicTaxIsCalculatedForMainGroupDocumentOnly And Not vTouristicTaxIsCalculatedForMainRoomDocumentOnly Or 
			   vIsGroupMainClientDoc Or vIsRoomMainClientDoc Or 
			   vTouristicTaxIsCalculatedForMainRoomDocumentOnly And Not vIsRoomMainClientDoc And 
			   (vDoNotMergeTouristTaxBaseToTheMainRoomGuest Or IsForFolioSplit) Then
				If Not ValueIsFilled(TouristicTaxExemptionReason) Then
					If ValueIsFilled(vTouristTaxService) Then
						InsertTouristTaxRow(vLastLineNumberPerDate, vLineNumberShift, vCurAccountingDate, vTouristTaxService, vTouristTaxAmountPerDate, vTouristTaxBaseAmountPerDate, vRoomRateServiceRowPerDate, vNoVATVatRate, vChargingRules);
					ElsIf vTouristTaxAddToRate And vFirstLineNumberPerDate > 0 Then
						vSrvRow = Services.Get(vFirstLineNumberPerDate - 1);
						vSrvRow.Price = vSrvRow.Price + vTouristTaxAmountPerDate;
						vSrvRow.RateSum = vSrvRow.RateSum + vTouristTaxAmountPerDate * RoomQuantity;
						cmPriceOnChange(vSrvRow.Price, vSrvRow.Quantity, vSrvRow.Sum, vSrvRow.VATRate, vSrvRow.VATSum, vSrvRow.AccountingDate);
						pmCalculateServiceDiscounts(vSrvRow);
						pmCalculateServiceCommissions(vSrvRow);
						If vSrvRow.DiscountSum <> 0 And vSrvRow.Discount <> 0 Then
							vSrvRow.RateDiscountSum = vSrvRow.RateDiscountSum + Round(vTouristTaxAmountPerDate * vSrvRow.Discount / 100, 2);
						EndIf;
						If vSrvRow.CommissionSum <> 0 And vSrvRow.AgentCommission <> 0 Then
							If vSrvRow.AgentCommissionType = Enums.AgentCommissionTypes.Percent Then
								vSrvRow.RateCommissionSum = vSrvRow.RateCommissionSum + Round(vTouristTaxAmountPerDate * vSrvRow.AgentCommission / 100, 2);
							ElsIf vSrvRow.AgentCommissionType = Enums.AgentCommissionTypes.FirstDayPercent And vSrvRow.GuestsCheckedIn <> 0 Then
								vSrvRow.RateCommissionSum = vSrvRow.RateCommissionSum + Round(vTouristTaxAmountPerDate * vSrvRow.AgentCommission / 100, 2);
							EndIf;
						EndIf;
					EndIf;
				ElsIf vTouristTaxSubtractFromRateIfExemption And vFirstLineNumberPerDate > 0 Then
					vSrvRow = Services.Get(vFirstLineNumberPerDate - 1);
					vSrvRow.Price = vSrvRow.Price - vTouristTaxAmountPerDate;
					cmPriceOnChange(vSrvRow.Price, vSrvRow.Quantity, vSrvRow.Sum, vSrvRow.VATRate, vSrvRow.VATSum, vSrvRow.AccountingDate);
					pmCalculateServiceDiscounts(vSrvRow);
					pmCalculateServiceCommissions(vSrvRow);
				EndIf;
			EndIf;
		EndIf;
		If Not vTouristicTaxIsCalculatedForMainGroupDocumentOnly And Not vTouristicTaxIsCalculatedForMainRoomDocumentOnly Or
		   vIsGroupMainClientDoc Or vIsRoomMainClientDoc Or 
		   vTouristicTaxIsCalculatedForMainRoomDocumentOnly And Not vIsRoomMainClientDoc And 
		   (vDoNotMergeTouristTaxBaseToTheMainRoomGuest Or IsForFolioSplit) Then
			If ValueIsFilled(GuestGroup) And GuestGroup.TouristicTaxIsCalculatedForMainGroupDocumentOnly Then
				vTouristTaxSumInBaseCurrency = vTouristTaxAmountPerDate * DurationInDays;
			Else
				vTouristTaxSumInBaseCurrency = vTouristTaxAmountPerDate * DurationInDays * ?(RoomQuantity = 0, 1, RoomQuantity);
			EndIf;
			If TouristTaxSumInBaseCurrency <> vTouristTaxSumInBaseCurrency Then
				TouristTaxSumInBaseCurrency = vTouristTaxSumInBaseCurrency;
			EndIf;
		ElsIf TouristTaxSumInBaseCurrency <> 0 Then
			TouristTaxSumInBaseCurrency = 0;
		EndIf;
	Else
		If TouristTaxSumInBaseCurrency <> vTouristTaxSumInBaseCurrency Then
			TouristTaxSumInBaseCurrency = vTouristTaxSumInBaseCurrency;
		EndIf;
	EndIf;
EndProcedure // pmCalculateTouristTax

// -----------------------------------------------------------------------------
Procedure InsertTouristTaxRow(pLineNumber, pShift, pAccountingDate, pTouristTaxService, pTouristTaxAmount, pTouristTaxBaseAmount, pRoomRateServiceRow, pNoVATVatRate, pChargingRules)
	If pRoomRateServiceRow = Undefined Then
		pShift = pShift - 1;
		Return;
	EndIf;
	vTouristTaxSrvRow = Services.Insert(pLineNumber + pShift);
	vTouristTaxSrvRow.AccountingDate = pAccountingDate;
	vTouristTaxSrvRow.Service = pTouristTaxService;
	vTouristTaxSrvRow.Quantity = ?(RoomQuantity = 0, 1, RoomQuantity);
	vTouristTaxSrvRow.AccommodationType = pRoomRateServiceRow.AccommodationType;
	vTouristTaxSrvRow.BoardPlace = pRoomRateServiceRow.BoardPlace;
	vTouristTaxSrvRow.CalendarDayType = pRoomRateServiceRow.CalendarDayType;
	vTouristTaxSrvRow.ClientType = pRoomRateServiceRow.ClientType;
	vTouristTaxSrvRow.Company = pRoomRateServiceRow.Company;
	vTouristTaxSrvRow.MarketingCode = pRoomRateServiceRow.MarketingCode;
	vTouristTaxSrvRow.PriceTag = pRoomRateServiceRow.PriceTag;
	vTouristTaxSrvRow.Room = pRoomRateServiceRow.Room;
	vTouristTaxSrvRow.RoomRate = pRoomRateServiceRow.RoomRate;
	vTouristTaxSrvRow.RoomType = pRoomRateServiceRow.RoomType;
	vTouristTaxSrvRow.SourceOfBusiness = pRoomRateServiceRow.SourceOfBusiness;
	vTouristTaxSrvRow.Unit = TrimAll(pTouristTaxService.Unit);
	vTouristTaxSrvRow.VATRate = pNoVATVatRate;
	vTouristTaxSrvRow.IsInPrice = pTouristTaxService.IsInPrice;
	pmSetServiceFolioBasedOnChargingRules(vTouristTaxSrvRow, pChargingRules, True);
	If ValueIsFilled(vTouristTaxSrvRow.Folio) Then
		vTouristTaxSrvRow.Price = Round(cmConvertCurrencies(pTouristTaxAmount, Hotel.BaseCurrency, , vTouristTaxSrvRow.FolioCurrency, vTouristTaxSrvRow.FolioCurrencyExchangeRate, pAccountingDate, Hotel), 2);
		vTouristTaxSrvRow.Sum = Round(vTouristTaxSrvRow.Price * vTouristTaxSrvRow.Quantity, 2);
		vTouristTaxSrvRow.RateSum = Round(cmConvertCurrencies(pTouristTaxBaseAmount, Hotel.BaseCurrency, , vTouristTaxSrvRow.FolioCurrency, vTouristTaxSrvRow.FolioCurrencyExchangeRate, pAccountingDate, Hotel), 2);
		// Add tourist tax amount to the rate amount of the room revenue service
		If vTouristTaxSrvRow.IsInPrice And Hotel.RoomRatePackagesServicesAreNotShownInFolios Then
			vRoomRateServiceRow = Services.Get(pRoomRateServiceRow.LineNumber + pShift - 1);
			vRoomRateServiceRow.RateSum = vRoomRateServiceRow.RateSum + Round(cmConvertCurrencies(Round(pTouristTaxAmount * ?(RoomQuantity = 0, 1, RoomQuantity), 2), Hotel.BaseCurrency, , vRoomRateServiceRow.FolioCurrency, vRoomRateServiceRow.FolioCurrencyExchangeRate, pAccountingDate, Hotel), 2);
		EndIf;
	Else
		Services.Delete(pLineNumber + pShift);
		pShift = pShift - 1;
	EndIf;
EndProcedure // InsertTouristTaxRow

// -----------------------------------------------------------------------------
Procedure pmCalculateRateAmountAndDurationInDays() Export
	vDurationInDays = 0;
	vRateSumInBaseCurrency = 0;
	vDaysList = New ValueList();
	vTTExtraServicesGroup = Hotel.TouristicTaxBaseAmountExtraServicesGroup;
	vStartDate = '00010101';
	If Hotel.TouristTaxIsUsed Then
		vStartDate = '20250101';
	EndIf;
	
	For Each vSrvRow In Services Do
		If ValueIsFilled(vSrvRow.AccountingDate) And vSrvRow.AccountingDate >= vStartDate And 
		  (vSrvRow.IsInPrice Or ValueIsFilled(vTTExtraServicesGroup) And cmIsServiceInServiceGroup(vSrvRow.Service, vTTExtraServicesGroup) And Not vSrvRow.IsInPrice) Then
			If vSrvRow.IsRoomRevenue And Not vSrvRow.IsSplit And Not vSrvRow.RoomRevenueAmountsOnly And vSrvRow.Quantity <> 0 Then
				If vDaysList.FindByValue(vSrvRow.AccountingDate) = Undefined Then
					vDaysList.Add(vSrvRow.AccountingDate);
				EndIf;
			EndIf;
			vDaySumNoDiscount = vSrvRow.Sum - vSrvRow.DiscountSum;
			vDayVATSumNoDiscount = cmCalculateVATSum(vSrvRow.VATRate, vDaySumNoDiscount, vSrvRow.AccountingDate);
			vDayRateSum = vDaySumNoDiscount - vDayVATSumNoDiscount;
			vDayRateSumInBaseCurrency = cmConvertCurrencies(vDayRateSum, vSrvRow.FolioCurrency, vSrvRow.FolioCurrencyExchangeRate, Hotel.BaseCurrency, , vSrvRow.AccountingDate, Hotel);
			vRateSumInBaseCurrency = vRateSumInBaseCurrency + Round(vDayRateSumInBaseCurrency, 2);
		EndIf;
	EndDo;
	
	If vDaysList.Count() > 0 Then
		vDurationInDays = vDaysList.Count();
	EndIf;
	
	If vDurationInDays = 0 And BegOfDay(CheckInDate) >= vStartDate Then
		If ValueIsFilled(RoomRate) And RoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByHours Then
			vDurationInDays = 1;
		Else 
			vDurationInDays = Duration;
		EndIf;
	EndIf;
	
	If vDurationInDays <> DurationInDays Then
		DurationInDays = vDurationInDays;
	EndIf;
	If vRateSumInBaseCurrency <> RateSumInBaseCurrency Then
		RateSumInBaseCurrency = vRateSumInBaseCurrency;
	EndIf;
EndProcedure // pmCalculateRateAmountAndDurationInDays

// -----------------------------------------------------------------------------
Procedure pmCalculateServiceDiscounts(pSrvRow) Export
	vDiscountType = pSrvRow.DiscountType;
	If ValueIsFilled(vDiscountType) Then
		If Not vDiscountType.IsAmountDiscount Then
			pSrvRow.DiscountSum = Round(pSrvRow.Sum * pSrvRow.Discount / 100, 2);
			If vDiscountType.RoundPrice Then
				pSrvRow.DiscountSum = cmRoundDiscountAmount(pSrvRow.DiscountSum, vDiscountType.RoundPriceDigits, vDiscountType.RoundPriceType);
			EndIf;
			vWeekDays = vDiscountType.WeekDays;
			If Not IsBlankString(vWeekDays) Then
				If StrFind(vWeekDays, String(WeekDay(pSrvRow.AccountingDate))) = 0 Then
					pSrvRow.DiscountSum = 0;
				EndIf;
			EndIf;
		EndIf;
	Else
		pSrvRow.DiscountSum = Round(pSrvRow.Sum * pSrvRow.Discount / 100, 2);
	EndIf;
	pSrvRow.VATDiscountSum = cmCalculateVATSum(pSrvRow.VATRate, pSrvRow.DiscountSum, pSrvRow.AccountingDate);
EndProcedure //  pmCalculateServiceDiscounts

// -----------------------------------------------------------------------------
Procedure pmSetServiceCommissions(pSrvRow, pRoomRates, pComplexCommission = Undefined) Export
	pSrvRow.AgentCommissionType = Undefined;
	pSrvRow.AgentCommission = 0;
	pSrvRow.CommissionSum = 0;
	pSrvRow.VATCommissionSum = 0;
	vRoomRate = pSrvRow.RoomRate;
	If Not ValueIsFilled(vRoomRate) Then
		vRoomRate = RoomRate;
	EndIf;
	If ValueIsFilled(vRoomRate) And Not vRoomRate.NoAgentCommission Then
		vRRRow = pRoomRates.Find(pSrvRow.AccountingDate, "AccountingDate");
		If vRRRow <> Undefined And Not IsBlankString(vRRRow.AgentCommission) And Number(vRRRow.AgentCommission) <> 0 Then
			pSrvRow.AgentCommissionType = AgentCommissionType;
			pSrvRow.AgentCommission = Number(vRRRow.AgentCommission);
			If pSrvRow.AgentCommission <> 0 And vRoomRate.MaxAgentCommission <> 0 Then
				pSrvRow.AgentCommission = Min(pSrvRow.AgentCommission, vRoomRate.MaxAgentCommission);
			EndIf;
			If pComplexCommission <> Undefined And pComplexCommission.Count() > 0 Then
				For Each vComplexCommissionRow In pComplexCommission Do
					If BegOfDay(vComplexCommissionRow.Period) <= pSrvRow.AccountingDate Then
						If cmIsServiceInServiceGroup(pSrvRow.Service, vComplexCommissionRow.ServiceGroup) Then
							If Not ValueIsFilled(vComplexCommissionRow.RoomClass) And Not ValueIsFilled(vComplexCommissionRow.RoomType) Or
							   ValueIsFilled(vComplexCommissionRow.RoomClass) And Not ValueIsFilled(vComplexCommissionRow.RoomType) And ValueIsFilled(pSrvRow.RoomType) And pSrvRow.RoomType.RoomClass = vComplexCommissionRow.RoomClass Or
							   ValueIsFilled(vComplexCommissionRow.RoomType) And vComplexCommissionRow.RoomType = pSrvRow.RoomType Then
								pSrvRow.AgentCommissionType = vComplexCommissionRow.CommissionType;
								pSrvRow.AgentCommission = vComplexCommissionRow.Commission;
								If pSrvRow.AgentCommission <> 0 And vRoomRate.MaxAgentCommission <> 0 Then
									pSrvRow.AgentCommission = Min(pSrvRow.AgentCommission, vRoomRate.MaxAgentCommission);
								EndIf;
								Break;
							EndIf;
						EndIf;
					EndIf;
				EndDo;
			EndIf;
		Else
			pSrvRow.AgentCommissionType = AgentCommissionType;
			pSrvRow.AgentCommission = AgentCommission;
			If pSrvRow.AgentCommission <> 0 And vRoomRate.MaxAgentCommission <> 0 Then
				pSrvRow.AgentCommission = Min(pSrvRow.AgentCommission, vRoomRate.MaxAgentCommission);
			EndIf;
			If pComplexCommission <> Undefined And pComplexCommission.Count() > 0 Then
				For Each vComplexCommissionRow In pComplexCommission Do
					If BegOfDay(vComplexCommissionRow.Period) <= pSrvRow.AccountingDate Then
						If cmIsServiceInServiceGroup(pSrvRow.Service, vComplexCommissionRow.ServiceGroup) Then
							If Not ValueIsFilled(vComplexCommissionRow.RoomClass) And Not ValueIsFilled(vComplexCommissionRow.RoomType) Or
							   ValueIsFilled(vComplexCommissionRow.RoomClass) And Not ValueIsFilled(vComplexCommissionRow.RoomType) And ValueIsFilled(pSrvRow.RoomType) And pSrvRow.RoomType.RoomClass = vComplexCommissionRow.RoomClass Or
							   ValueIsFilled(vComplexCommissionRow.RoomType) And vComplexCommissionRow.RoomType = pSrvRow.RoomType Then
								pSrvRow.AgentCommissionType = vComplexCommissionRow.CommissionType;
								pSrvRow.AgentCommission = vComplexCommissionRow.Commission;
								If pSrvRow.AgentCommission <> 0 And vRoomRate.MaxAgentCommission <> 0 Then
									pSrvRow.AgentCommission = Min(pSrvRow.AgentCommission, vRoomRate.MaxAgentCommission);
								EndIf;
								Break;
							EndIf;
						EndIf;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		If pSrvRow.AgentCommission <> 0 Then
			// Check that current service fit to the commission service group
			If cmIsServiceInServiceGroup(pSrvRow.Service, AgentCommissionServiceGroup) Then
				If pSrvRow.AgentCommissionType = Enums.AgentCommissionTypes.Percent Then
					pSrvRow.CommissionSum = Round((pSrvRow.Sum - pSrvRow.DiscountSum) * pSrvRow.AgentCommission/100, 2);
					pSrvRow.VATCommissionSum = cmCalculateVATSum(pSrvRow.VATRate, pSrvRow.CommissionSum, pSrvRow.AccountingDate);
				ElsIf pSrvRow.AgentCommissionType = Enums.AgentCommissionTypes.FirstDayPercent Then
					If BegOfDay(CheckInDate) = BegOfDay(pSrvRow.AccountingDate) Then
						pSrvRow.CommissionSum = Round((pSrvRow.Sum - pSrvRow.DiscountSum) * pSrvRow.AgentCommission/100, 2);
						pSrvRow.VATCommissionSum = cmCalculateVATSum(pSrvRow.VATRate, pSrvRow.CommissionSum, pSrvRow.AccountingDate);
					Else
						pSrvRow.AgentCommissionType = Undefined;
						pSrvRow.AgentCommission = 0;
					EndIf;
				ElsIf pSrvRow.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerDayPerRoom And pSrvRow.IsRoomRevenue And pSrvRow.IsInPrice And Not pSrvRow.IsSplit And 
				      ValueIsFilled(AccommodationType) And (AccommodationType.Type = Enums.AccomodationTypes.Room Or AccommodationType.Type = Enums.AccomodationTypes.Beds) Then
					vAgentCurrency = ReportingCurrency;
					If ValueIsFilled(Contract) And ValueIsFilled(Contract.AgentCommissionType) Then
						vAgentCurrency = Contract.AccountingCurrency;
					ElsIf ValueIsFilled(Agent) Then
						vAgentCurrency = Agent.AccountingCurrency;
					EndIf;		
					pSrvRow.CommissionSum = RoomQuantity * Round(cmConvertCurrencies(pSrvRow.AgentCommission, vAgentCurrency, , pSrvRow.FolioCurrency, pSrvRow.FolioCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
					pSrvRow.VATCommissionSum = cmCalculateVATSum(pSrvRow.VATRate, pSrvRow.CommissionSum, pSrvRow.AccountingDate);
				ElsIf pSrvRow.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerCheckInPerRoom And pSrvRow.IsRoomRevenue And pSrvRow.IsInPrice And Not pSrvRow.IsSplit And 
				      ValueIsFilled(AccommodationType) And (AccommodationType.Type = Enums.AccomodationTypes.Room Or AccommodationType.Type = Enums.AccomodationTypes.Beds) Then
					If BegOfDay(CheckInDate) = BegOfDay(pSrvRow.AccountingDate) Then
						vAgentCurrency = ReportingCurrency;
						If ValueIsFilled(Contract) And ValueIsFilled(Contract.AgentCommissionType) Then
							vAgentCurrency = Contract.AccountingCurrency;
						ElsIf ValueIsFilled(Agent) Then
							vAgentCurrency = Agent.AccountingCurrency;
						EndIf;		
						pSrvRow.CommissionSum = RoomQuantity * Round(cmConvertCurrencies(pSrvRow.AgentCommission, vAgentCurrency, , pSrvRow.FolioCurrency, pSrvRow.FolioCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
						pSrvRow.VATCommissionSum = cmCalculateVATSum(pSrvRow.VATRate, pSrvRow.CommissionSum, pSrvRow.AccountingDate);
					Else
						pSrvRow.AgentCommissionType = Undefined;
						pSrvRow.AgentCommission = 0;
					EndIf;
				ElsIf pSrvRow.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerDayPerClient And pSrvRow.IsRoomRevenue And pSrvRow.IsInPrice And Not pSrvRow.IsSplit Then
					vAgentCurrency = ReportingCurrency;
					If ValueIsFilled(Contract) And ValueIsFilled(Contract.AgentCommissionType) Then
						vAgentCurrency = Contract.AccountingCurrency;
					ElsIf ValueIsFilled(Agent) Then
						vAgentCurrency = Agent.AccountingCurrency;
					EndIf;		
					pSrvRow.CommissionSum = RoomQuantity * Round(cmConvertCurrencies(pSrvRow.AgentCommission, vAgentCurrency, , pSrvRow.FolioCurrency, pSrvRow.FolioCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
					pSrvRow.VATCommissionSum = cmCalculateVATSum(pSrvRow.VATRate, pSrvRow.CommissionSum, pSrvRow.AccountingDate);
				ElsIf pSrvRow.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerCheckInPerClient And pSrvRow.IsRoomRevenue And pSrvRow.IsInPrice And Not pSrvRow.IsSplit Then
					If BegOfDay(CheckInDate) = BegOfDay(pSrvRow.AccountingDate) Then
						vAgentCurrency = ReportingCurrency;
						If ValueIsFilled(Contract) And ValueIsFilled(Contract.AgentCommissionType) Then
							vAgentCurrency = Contract.AccountingCurrency;
						ElsIf ValueIsFilled(Agent) Then
							vAgentCurrency = Agent.AccountingCurrency;
						EndIf;		
						pSrvRow.CommissionSum = RoomQuantity * Round(cmConvertCurrencies(pSrvRow.AgentCommission, vAgentCurrency, , pSrvRow.FolioCurrency, pSrvRow.FolioCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
						pSrvRow.VATCommissionSum = cmCalculateVATSum(pSrvRow.VATRate, pSrvRow.CommissionSum, pSrvRow.AccountingDate);
					Else
						pSrvRow.AgentCommissionType = Undefined;
						pSrvRow.AgentCommission = 0;
					EndIf;
				Else
					pSrvRow.AgentCommissionType = Undefined;
					pSrvRow.AgentCommission = 0;
				EndIf;
			Else
				pSrvRow.AgentCommissionType = Undefined;
				pSrvRow.AgentCommission = 0;
			EndIf;
		EndIf;
	EndIf;
EndProcedure //  pmSetServiceCommissions

// -----------------------------------------------------------------------------
Procedure pmCalculateServiceCommissions(pSrvRow) Export
	vAgentCurrency = ReportingCurrency;
	If ValueIsFilled(Contract) And ValueIsFilled(Contract.AgentCommissionType) Then
		vAgentCurrency = Contract.AccountingCurrency;
	ElsIf ValueIsFilled(Agent) Then
		vAgentCurrency = Agent.AccountingCurrency;
	EndIf;		
	pSrvRow.CommissionSum = 0;
	pSrvRow.VATCommissionSum = 0;
	vRoomRate = pSrvRow.RoomRate;
	If Not ValueIsFilled(vRoomRate) Then
		vRoomRate = RoomRate;
	EndIf;
	If ValueIsFilled(vRoomRate) And Not vRoomRate.NoAgentCommission Then
		If pSrvRow.AgentCommission <> 0 Then
			If vRoomRate.MaxAgentCommission <> 0 Then
				pSrvRow.AgentCommission = Min(pSrvRow.AgentCommission, vRoomRate.MaxAgentCommission);
			EndIf;
			// Check that current service fit to the commission service group
			If cmIsServiceInServiceGroup(pSrvRow.Service, AgentCommissionServiceGroup) Then
				If pSrvRow.AgentCommissionType = Enums.AgentCommissionTypes.Percent Then
					pSrvRow.CommissionSum = Round((pSrvRow.Sum - pSrvRow.DiscountSum) * pSrvRow.AgentCommission/100, 2);
					pSrvRow.VATCommissionSum = cmCalculateVATSum(pSrvRow.VATRate, pSrvRow.CommissionSum, pSrvRow.AccountingDate);
				ElsIf pSrvRow.AgentCommissionType = Enums.AgentCommissionTypes.FirstDayPercent Then
					If BegOfDay(CheckInDate) = BegOfDay(pSrvRow.AccountingDate) Then
						pSrvRow.CommissionSum = Round((pSrvRow.Sum - pSrvRow.DiscountSum) * pSrvRow.AgentCommission/100, 2);
						pSrvRow.VATCommissionSum = cmCalculateVATSum(pSrvRow.VATRate, pSrvRow.CommissionSum, pSrvRow.AccountingDate);
					Else
						pSrvRow.AgentCommissionType = Undefined;
						pSrvRow.AgentCommission = 0;
					EndIf;
				ElsIf pSrvRow.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerDayPerRoom And pSrvRow.IsRoomRevenue And pSrvRow.IsInPrice And Not pSrvRow.IsSplit And 
				      ValueIsFilled(AccommodationType) And (AccommodationType.Type = Enums.AccomodationTypes.Room Or AccommodationType.Type = Enums.AccomodationTypes.Beds) Then
					pSrvRow.CommissionSum = RoomQuantity * Round(cmConvertCurrencies(pSrvRow.AgentCommission, vAgentCurrency, , pSrvRow.FolioCurrency, pSrvRow.FolioCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
					pSrvRow.VATCommissionSum = cmCalculateVATSum(pSrvRow.VATRate, pSrvRow.CommissionSum, pSrvRow.AccountingDate);
				ElsIf pSrvRow.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerCheckInPerRoom And pSrvRow.IsRoomRevenue And pSrvRow.IsInPrice And Not pSrvRow.IsSplit And 
				      ValueIsFilled(AccommodationType) And (AccommodationType.Type = Enums.AccomodationTypes.Room Or AccommodationType.Type = Enums.AccomodationTypes.Beds) Then
					If BegOfDay(CheckInDate) = BegOfDay(pSrvRow.AccountingDate) Then
						pSrvRow.CommissionSum = RoomQuantity * Round(cmConvertCurrencies(pSrvRow.AgentCommission, vAgentCurrency, , pSrvRow.FolioCurrency, pSrvRow.FolioCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
						pSrvRow.VATCommissionSum = cmCalculateVATSum(pSrvRow.VATRate, pSrvRow.CommissionSum, pSrvRow.AccountingDate);
					Else
						pSrvRow.AgentCommissionType = Undefined;
						pSrvRow.AgentCommission = 0;
					EndIf;
				ElsIf pSrvRow.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerDayPerClient And pSrvRow.IsRoomRevenue And pSrvRow.IsInPrice And Not pSrvRow.IsSplit Then
					pSrvRow.CommissionSum = RoomQuantity * Round(cmConvertCurrencies(pSrvRow.AgentCommission, vAgentCurrency, , pSrvRow.FolioCurrency, pSrvRow.FolioCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
					pSrvRow.VATCommissionSum = cmCalculateVATSum(pSrvRow.VATRate, pSrvRow.CommissionSum, pSrvRow.AccountingDate);
				ElsIf pSrvRow.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerCheckInPerClient And pSrvRow.IsRoomRevenue And pSrvRow.IsInPrice And Not pSrvRow.IsSplit Then
					If BegOfDay(CheckInDate) = BegOfDay(pSrvRow.AccountingDate) Then
						pSrvRow.CommissionSum = RoomQuantity * Round(cmConvertCurrencies(pSrvRow.AgentCommission, vAgentCurrency, , pSrvRow.FolioCurrency, pSrvRow.FolioCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
						pSrvRow.VATCommissionSum = cmCalculateVATSum(pSrvRow.VATRate, pSrvRow.CommissionSum, pSrvRow.AccountingDate);
					Else
						pSrvRow.AgentCommissionType = Undefined;
						pSrvRow.AgentCommission = 0;
					EndIf;
				Else
					pSrvRow.AgentCommissionType = Undefined;
					pSrvRow.AgentCommission = 0;
				EndIf;
			Else
				pSrvRow.AgentCommissionType = Undefined;
				pSrvRow.AgentCommission = 0;
			EndIf;
		EndIf;
	Else
		pSrvRow.AgentCommissionType = Undefined;
		pSrvRow.AgentCommission = 0;
	EndIf;
EndProcedure //  pmCalculateServiceCommissions

// -----------------------------------------------------------------------------
Procedure pmSetServiceFolioBasedOnChargingRules(pServiceRow, pChargingRules, pAssignNew = False) Export
	// Try to get current service folio
	If Not pAssignNew Then
		For Each vSrvRow In Services Do
			If ValueIsFilled(vSrvRow.Folio) Then
				If vSrvRow.Service = pServiceRow.Service And 
				   vSrvRow.AccountingDate = pServiceRow.AccountingDate And 
				   vSrvRow.Price = pServiceRow.Price And 
				   vSrvRow.IsSplit = pServiceRow.IsSplit And 
				   TrimR(vSrvRow.Remarks) = TrimR(pServiceRow.Remarks) Then
					pServiceRow.Folio = vSrvRow.Folio;
					If ValueIsFilled(pServiceRow.Folio) And pServiceRow.FolioCurrency <> pServiceRow.Folio.FolioCurrency Then
						pServiceRow.FolioCurrency = pServiceRow.Folio.FolioCurrency;
						pServiceRow.FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, pServiceRow.FolioCurrency, ?(ValueIsFilled(pServiceRow.AccountingDate), pServiceRow.AccountingDate, ExchangeRateDate));
					EndIf;
					Break;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	If Not ValueIsFilled(pServiceRow.Folio) Or pAssignNew Then
		vCurIsInRate = Not pServiceRow.IsManual;
		If ValueIsFilled(pServiceRow.Service) Then
			vCurQuantityCalculationRule = pServiceRow.Service.QuantityCalculationRule;
			If ValueIsFilled(vCurQuantityCalculationRule) And 
			  (vCurQuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.ResortFeeRu2018 Or 
			   vCurQuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.ResortFeeRu2018CO Or 
			   vCurQuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.ResortFeeRu2022) Then
				vCurIsInRate = False;
			EndIf;
		EndIf;
		// Set folio according to the current charging rules
		For Each vChargingRuleRow in pChargingRules Do
			// Check if current service fit to the current charging rule
			If cmIsServiceFitToTheChargingRule(vChargingRuleRow, pServiceRow.Service, pServiceRow.AccountingDate, vCurIsInRate, pServiceRow.IsRoomRevenue) Then
				// Check price split charging rules
				If vChargingRuleRow.ChargingRule = Enums.ChargingRuleTypes.RoomRevenuePrice Then
					If pServiceRow.IsSplit Then
						Continue;
					EndIf;
				ElsIf vChargingRuleRow.ChargingRule = Enums.ChargingRuleTypes.RoomRevenuePricePercent Then
					If pServiceRow.IsSplit Then
						Continue;
					EndIf;
				ElsIf vChargingRuleRow.ChargingRule = Enums.ChargingRuleTypes.RoomRevenueAmount Then
					If pServiceRow.IsSplit Then
						Continue;
					EndIf;
				ElsIf vChargingRuleRow.ChargingRule = Enums.ChargingRuleTypes.RoomRevenuePriceByRoomType Then
					If pServiceRow.IsSplit Then
						Continue;
					EndIf;
				ElsIf vChargingRuleRow.ChargingRule = Enums.ChargingRuleTypes.RestOfRoomRevenuePrice Then
					If Not pServiceRow.IsSplit Then
						Continue;
					EndIf;
				EndIf;
				pServiceRow.Folio = vChargingRuleRow.ChargingFolio;
				If ValueIsFilled(pServiceRow.Folio) And pServiceRow.FolioCurrency <> pServiceRow.Folio.FolioCurrency Then
					pServiceRow.FolioCurrency = pServiceRow.Folio.FolioCurrency;
					pServiceRow.FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, pServiceRow.FolioCurrency, ?(ValueIsFilled(pServiceRow.AccountingDate), pServiceRow.AccountingDate, ExchangeRateDate));
				EndIf;
				Break;
			EndIf;
		EndDo;
	EndIf;
EndProcedure //  pmSetServiceFolioBasedOnChargingRules 

// -----------------------------------------------------------------------------
Procedure pmSetFolioBasedOnChargingRules(pServices, pAssignNew = False, pCharges = Undefined) Export
	// Create table of charging rules
	vChargingRules = ChargingRules.Unload();
	If Not IgnoreGroupChargingRules Then
		cmAddGuestGroupChargingRules(vChargingRules, GuestGroup);
	EndIf;
	// Process each service in the services value table
	For Each vServiceRow In pServices Do
		pmSetServiceFolioBasedOnChargingRules(vServiceRow, vChargingRules, pAssignNew);
	EndDo;
	// Try to set folio for the transfered charges
	If pCharges <> Undefined Then
		For Each vServiceRow In pServices Do
			vChargesRows = pCharges.FindRows(New Structure("AccountingDate", vServiceRow.AccountingDate));
			For Each vChargesRow In vChargesRows Do
				If ValueIsFilled(vChargesRow.ChargeTransfer) And
				   vServiceRow.Service = vChargesRow.Service And
				   vServiceRow.Price = vChargesRow.Price And
				   vServiceRow.VATRate = vChargesRow.VATRate And
				   vServiceRow.IsManual = vChargesRow.IsManual Then
					vServiceRow.Folio = vChargesRow.Folio;
					If ValueIsFilled(vServiceRow.Folio) And vServiceRow.FolioCurrency = vServiceRow.Folio.FolioCurrency Then
						vServiceRow.FolioCurrency = vServiceRow.Folio.FolioCurrency;
						vServiceRow.FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, vServiceRow.FolioCurrency, ?(ValueIsFilled(vServiceRow.AccountingDate), vServiceRow.AccountingDate, ExchangeRateDate));
					EndIf;
					Break;
				EndIf;
			EndDo;
		EndDo;
	EndIf;
EndProcedure //  pmSetFolioBasedOnChargingRules 

// -----------------------------------------------------------------------------
//  Get reservation attributes valid on specified date, If is not specified, then function gets attributes on current date
//
// Parameters:
//  pDate	 - Date	 - Attribute Receipt Date
// 
// Returns:
//  ValueTable - The value of the details
//
Function pmGetReservationAttributes(Val pDate = Undefined) Export
	// Fill parameter default values 
	If Not ValueIsFilled(pDate) Then
		pDate = CurrentSessionDate();
	EndIf;
	// Build and run query
	qGetLastAttr = New Query;
	qGetLastAttr.Text = 
	"SELECT 
	|	* 
	|FROM
	|	InformationRegister.ReservationChangeHistory.SliceLast(
	|	&qDate, 
	|	Reservation = &qReservation) AS ReservationChangeHistory";
	qGetLastAttr.SetParameter("qDate", pDate);
	qGetLastAttr.SetParameter("qReservation", Ref);
	vAttr = qGetLastAttr.Execute().Unload();
	
	Return vAttr;
EndFunction //  pmGetReservationAttributes

// -----------------------------------------------------------------------------
Procedure pmLoadChargingRules(pOwner, pPaymentMethod = Undefined) Export
	// Get list of hotel default charging rules owners
	vHotelCROwners = cmGetHotelDefaultChargingRuleOwners(Hotel);
	// Remove charging rules for objects of the same type
	i = 0;
	j = 0;
	vCRTo = ChargingRules.Unload();
	While i < vCRTo.Count() Do
		vCRRow = vCRTo.Get(i);
		If ValueIsFilled(vCRRow.Owner) Then
			If TypeOf(pOwner) = TypeOf(vCRRow.Owner) Or 
			   TypeOf(pOwner) = Type("CatalogRef.Contracts") And TypeOf(vCRRow.Owner) = Type("CatalogRef.Customers") Or
			   TypeOf(pOwner) = Type("CatalogRef.Customers") And TypeOf(vCRRow.Owner) = Type("CatalogRef.Contracts") Then
				If vHotelCROwners.FindByValue(vCRRow.Owner) = Undefined Then
					// Try to find hotel template rule of the same type
					vHotelCRRows = Hotel.ChargingRules.FindRows(New Structure("ChargingRule, ChargingRuleValue, ValidFromDate, ValidToDate", vCRRow.ChargingRule, vCRRow.ChargingRuleValue, vCRRow.ValidFromDate, vCRRow.ValidToDate));
					If vHotelCRRows.Count() <> 1 Then
						// Delete charging rule row
						vCRTo.Delete(i);
						cmUpdateChargingRulesFoliosLineNumbers(vCRTo);
						// Save position of the first deleted charging rule
						If j = 0 Then
							j = i;
						EndIf;
						Continue;
					Else
						vHotelCRRow = vHotelCRRows.Get(0);
						// Update charging folio
						vFolioObj = vCRRow.ChargingFolio.GetObject();
						vFolioObj.Read();
						If Not vFolioObj.IsMaster Then
							cmFillFolioFromTemplate(vFolioObj, vHotelCRRow.ChargingFolio, Hotel, Date);
							vFolioObj.ParentDoc = pmGetThisDocumentRef();
							If Not vFolioObj.DoNotUpdateCompany Then
								vFolioObj.Company = Company;
							EndIf;
							vFolioObj.Client = Guest;
							vFolioObj.DateTimeFrom = CheckInDate;
							vFolioObj.DateTimeTo = CheckOutDate;
							vFolioObj.GuestGroup = GuestGroup;
							If TypeOf(pOwner) = Type("CatalogRef.Customers") Then
								If Not vFolioObj.DoNotUpdateCustomer Then
									vFolioObj.Customer = Catalogs.Customers.EmptyRef();
								EndIf;
							ElsIf TypeOf(pOwner) = Type("CatalogRef.Contracts") Then
								If Not vFolioObj.DoNotUpdateCustomer Then
									vFolioObj.Customer = Catalogs.Customers.EmptyRef();
									vFolioObj.Contract = Catalogs.Contracts.EmptyRef();
								EndIf;
							ElsIf TypeOf(pOwner) = Type("CatalogRef.Clients") Then
								vFolioObj.Client = Catalogs.Clients.EmptyRef();
							ElsIf TypeOf(pOwner) = Type("CatalogRef.Rooms") Then
								vFolioObj.Room = Catalogs.Rooms.EmptyRef();
							EndIf;
							vFolioObj.LineNumber = vCRTo.IndexOf(vCRRow) + 1;
							If pPaymentMethod <> Undefined Then
								vFolioObj.PaymentMethod = pPaymentMethod;
							EndIf;
							vFolioObj.Write(DocumentWriteMode.Write);
							// Update owner
							vCRRow.Owner = Undefined;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		i = i + 1;
	EndDo;
	// Load changed charging rules to the tabular part
	ChargingRules.Load(vCRTo);
	// Check owner
	If Not ValueIsFilled(pOwner) Then
		If ChargingRules.Count() = 0 Then
			pmCreateFolios(pPaymentMethod);
		EndIf;
		Return;
	EndIf;
	vCRFrom = Undefined;
	If TypeOf(pOwner) = Type("CatalogRef.Rooms") Then
		If Not ValueIsFilled(Hotel) Then
			If ChargingRules.Count() = 0 Then
				pmCreateFolios(pPaymentMethod);
			EndIf;
			Return;
		EndIf;
		vCRFrom = Hotel.RoomChargingRules.Unload();
	Else
		vCRFrom = pOwner.ChargingRules.Unload();
	EndIf;
	If vCRFrom = Undefined Then
		If ChargingRules.Count() = 0 Then
			pmCreateFolios(pPaymentMethod);
		EndIf;
		Return;
	EndIf;
	If vCRFrom.Count() = 0 Then
		vOwnerPaymentMethod = pPaymentMethod;
		If Not ValueIsFilled(vOwnerPaymentMethod) Then
			If ValueIsFilled(pOwner) Then
				If TypeOf(pOwner) = Type("CatalogRef.Contracts") And ValueIsFilled(pOwner.PlannedPaymentMethod) Then
					vOwnerPaymentMethod = pOwner.PlannedPaymentMethod;
				ElsIf TypeOf(pOwner) = Type("CatalogRef.Customers") And ValueIsFilled(pOwner.PlannedPaymentMethod) Then
					vOwnerPaymentMethod = pOwner.PlannedPaymentMethod;
				EndIf;
			EndIf;
		EndIf;
		If ChargingRules.Count() = 0 Then
			pmCreateFolios(vOwnerPaymentMethod);
		ElsIf ValueIsFilled(vOwnerPaymentMethod) Then
			If vOwnerPaymentMethod <> PlannedPaymentMethod Then
				PlannedPaymentMethod = vOwnerPaymentMethod;
			EndIf;
			vCRRow = ChargingRules.Get(0);
			If ValueIsFilled(vCRRow.ChargingFolio) And vCRRow.ChargingFolio.PaymentMethod <> vOwnerPaymentMethod Then
				vFolioObj = vCRRow.ChargingFolio.GetObject();
				vFolioObj.PaymentMethod = vOwnerPaymentMethod;
				vFolioObj.AdditionalProperties.Insert("SkipCheckOfAnaliticalParametersChange", True);
				vFolioObj.Write();
			EndIf;
		EndIf;
		Return;
	EndIf;
	vGuestGroupObj = Undefined;
	If ValueIsFilled(GuestGroup) Then
		vGuestGroupObj = GuestGroup.GetObject();
		vGuestGroupObj.Read();
	EndIf;
	If ValueIsFilled(Hotel) And ValueIsFilled(GuestGroup) Then
		// Insert owners charging rules before this document charging rules
		For Each vCRRow In vCRFrom Do
			// Check if current folio should be used as template
			vIsTemplate = True;
			If ValueIsFilled(vCRRow.ChargingFolio) Then
				vIsTemplate = Not vCRRow.ChargingFolio.IsMaster;
			EndIf;
			// Try to find existing charging rule of the same type
			vReuseFolio = False;
			vCRToRows = vCRTo.FindRows(New Structure("ChargingRule, ChargingRuleValue, ValidFromDate, ValidToDate", vCRRow.ChargingRule, vCRRow.ChargingRuleValue, vCRRow.ValidFromDate, vCRRow.ValidToDate));
			If vCRToRows.Count() = 1 Then
				// Reuse existing one
				vCRToRow = vCRToRows.Get(0);
				vReuseFolio = True;
			Else
				// New charging rule row
				vCRToRow = vCRTo.Insert(j);
				cmUpdateChargingRulesFoliosLineNumbers(vCRTo);
				j = j + 1;
			EndIf;
			vCRToRow.ChargingRule = vCRRow.ChargingRule;
			vCRToRow.ChargingRuleValue = vCRRow.ChargingRuleValue;
			vCRToRow.ValidFromDate = vCRRow.ValidFromDate;
			vCRToRow.ValidToDate = vCRRow.ValidToDate;
			If Not vCRRow.IsPersonal Then
				vCRToRow.Owner = pOwner;
			EndIf;
			// Get template folio
			If vIsTemplate Then
				// If owner is room then try to find acive room folios first
				If TypeOf(pOwner) = Type("CatalogRef.Rooms") Then
					vHotel = Hotel;
					vRoom = pOwner;
					vFolioCurrency = Hotel.FolioCurrency;
					If ValueIsFilled(vCRRow.ChargingFolio) Then
						vFolioCurrency = vCRRow.ChargingFolio.FolioCurrency;
					EndIf;
					vRoomFolios = cmGetActiveRoomFolios(vHotel, vRoom, vFolioCurrency);
					For Each vRoomFoliosRow in vRoomFolios Do
						vCRRow.ChargingFolio = vRoomFoliosRow.Folio;
						vIsTemplate = False;
						Break;				
					EndDo;
				EndIf;
			EndIf;
			// If current charging folio is template then create new based on it
			If Not vReuseFolio Then
				If vIsTemplate Then
					// Create new folio from template
					vOldFolioRef = cmGetChargingRulesRowFolio(GuestGroup, pmGetThisDocumentRef(), vCRTo.IndexOf(vCRToRow) + 1);
					If ValueIsFilled(vOldFolioRef) Then
						vFolioObj = vOldFolioRef.GetObject();
						vFolioObj.DeletionMark = False;
					Else
						vFolioObj = Documents.Folio.CreateDocument();
					EndIf;
					cmFillFolioFromTemplate(vFolioObj, vCRRow.ChargingFolio, Hotel, Date);
					vFolioObj.ParentDoc = pmGetThisDocumentRef();
					If Not vFolioObj.DoNotUpdateCompany Then
						vFolioObj.Company = Company;
					EndIf;
					vFolioObj.Client = Guest;
					vFolioObj.GuestGroup = GuestGroup;
					vFolioObj.DateTimeFrom = CheckInDate;
					vFolioObj.DateTimeTo = CheckOutDate;
				Else
					vCRToRow.ChargingFolio = vCRRow.ChargingFolio;
					vFolioObj = vCRToRow.ChargingFolio.GetObject();
					vFolioObj.Read();
					vFolioObj.ParentDoc = pmGetThisDocumentRef();
					If Not vFolioObj.DoNotUpdateCompany Then
						vFolioObj.Company = Company;
					EndIf;
				EndIf;
			Else
				// Update folio from template
				If vIsTemplate Then
					vFolioObj = vCRToRow.ChargingFolio.GetObject();
					vFolioObj.Read();
					cmFillFolioFromTemplate(vFolioObj, vCRRow.ChargingFolio, Hotel, Date);
					vFolioObj.ParentDoc = pmGetThisDocumentRef();
					If Not vFolioObj.DoNotUpdateCompany Then
						vFolioObj.Company = Company;
					EndIf;
					vFolioObj.Client = Guest;
					vFolioObj.GuestGroup = GuestGroup;
					vFolioObj.DateTimeFrom = CheckInDate;
					vFolioObj.DateTimeTo = CheckOutDate;
				Else
					vCRToRow.ChargingFolio = vCRRow.ChargingFolio;
					vFolioObj = vCRToRow.ChargingFolio.GetObject();
					vFolioObj.Read();
					vFolioObj.ParentDoc = pmGetThisDocumentRef();
					If Not vFolioObj.DoNotUpdateCompany Then
						vFolioObj.Company = Company;
					EndIf;
				EndIf;
			EndIf;
			If TypeOf(pOwner) = Type("CatalogRef.Customers") Then
				If Not vCRRow.IsPersonal Then
					If Not vFolioObj.DoNotUpdateCustomer Then
						vFolioObj.Customer = pOwner;
					Else
						vCRToRow.Owner = vFolioObj.Customer;
					EndIf;
				EndIf;
			ElsIf TypeOf(pOwner) = Type("CatalogRef.Contracts") Then
				If Not vCRRow.IsPersonal Then
					If Not vFolioObj.DoNotUpdateCustomer Then
						vFolioObj.Customer = pOwner.Owner;
						vFolioObj.Contract = pOwner;
					Else
						vCRToRow.Owner = ?(ValueIsFilled(vFolioObj.Contract), vFolioObj.Contract, vFolioObj.Customer);
					EndIf;
				EndIf;
			ElsIf TypeOf(pOwner) = Type("CatalogRef.Clients") Then
				vFolioObj.Client = pOwner;
			ElsIf TypeOf(pOwner) = Type("CatalogRef.Rooms") Then
				vFolioObj.Room = pOwner;
			EndIf;
			vFolioObj.LineNumber = vCRTo.IndexOf(vCRToRow) + 1;
			If pPaymentMethod <> Undefined Then
				vFolioObj.PaymentMethod = pPaymentMethod;
			EndIf;
			vFolioObj.Write(DocumentWriteMode.Write);
			vCRToRow.ChargingFolio = vFolioObj.Ref;
		EndDo;
		// Load changed charging rules to the tabular part
		ChargingRules.Load(vCRTo);
	EndIf;
	If ChargingRules.Count() = 0 Then
		pmCreateFolios(pPaymentMethod);
	EndIf;
EndProcedure // pmLoadChargingRules

// -----------------------------------------------------------------------------
Procedure pmRemoveChargingRules(pOwner, pCheckOwnerValue = False) Export
	If ValueIsFilled(Hotel) Then
		i = 0;
		While i < ChargingRules.Count() Do
			vCRRow = ChargingRules.Get(i);
			If Not vCRRow.IsTransfer And ValueIsFilled(vCRRow.Owner) And TypeOf(vCRRow.Owner) = TypeOf(pOwner) And 
			  (Not pCheckOwnerValue Or pCheckOwnerValue And vCRRow.Owner = pOwner) Then
				// Check if hotel base charging rules have row with rule equal to the current one
				vBaseRuleIsFound = False;
				If Hotel.ChargingRules.Count() > 0 And 
				   ValueIsFilled(vCRRow.ChargingFolio) And Not vCRRow.ChargingFolio.IsMaster Then
					// Try to find hotel template rule of the same type
					vHotelCRRows = Hotel.ChargingRules.FindRows(New Structure("ChargingRule, ChargingRuleValue, ValidFromDate, ValidToDate", vCRRow.ChargingRule, vCRRow.ChargingRuleValue, vCRRow.ValidFromDate, vCRRow.ValidToDate));
					If vHotelCRRows.Count() = 1 Then
						vBaseRuleIsFound = True;
						vHotelCRRow = vHotelCRRows.Get(0);
						// Update charging folio
						vFolioObj = vCRRow.ChargingFolio.GetObject();
						cmFillFolioFromTemplate(vFolioObj, vHotelCRRow.ChargingFolio, Hotel, Date);
						If Not ValueIsFilled(vFolioObj.ParentDoc) Or 
							ValueIsFilled(vFolioObj.ParentDoc) And TypeOf(vFolioObj.ParentDoc) <> Type("DocumentRef.Accommodation") Then
							vFolioObj.ParentDoc = Ref;
						EndIf;
						If Not vFolioObj.DoNotUpdateCompany Then
							vFolioObj.Company = Company;
						EndIf;
						vFolioObj.Client = Guest;
						vFolioObj.GuestGroup = GuestGroup;
						vFolioObj.DateTimeFrom = CheckInDate;
						vFolioObj.DateTimeTo = CheckOutDate;
						vFolioObj.Customer = Catalogs.Customers.EmptyRef();
						vFolioObj.Contract = Catalogs.Contracts.EmptyRef();
						vFolioObj.Write(DocumentWriteMode.Write);
						// Update owner
						vIsTransfer = vCRRow.IsTransfer;
						vCRRow.Owner = GetChargingRuleOwnerByFolio(vCRRow.ChargingFolio, vIsTransfer);
						vCRRow.IsTransfer = vIsTransfer;
					EndIf;
				EndIf;
				If Not vBaseRuleIsFound Then
					ChargingRules.Delete(i);
				Else
					i = i + 1;
				EndIf;
			Else
				i = i + 1;
			EndIf;
		EndDo;
		cmUpdateChargingRulesFoliosLineNumbers(ChargingRules);
	EndIf;
EndProcedure // pmRemoveChargingRules

// ----------------------------------------------------------------------------
Function GetChargingRuleOwnerByFolio(pFolio, rIsTransfer)
	If ValueIsFilled(pFolio) Then
		vHotel = pFolio.Hotel;
		vParentDoc = pFolio.ParentDoc;
		If Ref <> vParentDoc And ValueIsFilled(vParentDoc) Then
			rIsTransfer = True;
		EndIf;
		If rIsTransfer And ValueIsFilled(vParentDoc) And 
		  (TypeOf(vParentDoc) = Type("DocumentRef.Reservation") Or 
		   TypeOf(vParentDoc) = Type("DocumentRef.ResourceReservation") Or
		   TypeOf(vParentDoc) = Type("DocumentRef.Accommodation")) Then
			Return vParentDoc;
		ElsIf ValueIsFilled(pFolio.Contract) Then
			Return pFolio.Contract;
		ElsIf ValueIsFilled(pFolio.Customer) And ValueIsFilled(vHotel) And 
		      Not pFolio.Customer = vHotel.IndividualsCustomer Then
			Return pFolio.Customer;
		ElsIf ValueIsFilled(pFolio.Client) Then
			Return pFolio.Client;
		EndIf;
	EndIf;
	Return Undefined;
EndFunction // GetChargingRuleOwnerByFolio

// -----------------------------------------------------------------------------
Procedure pmRemoveIsMasterChargingRules() Export
	// Remove charging rules with "Is master" flag on
	i = 0;
	vCRTo = ChargingRules.Unload();
	While i < vCRTo.Count() Do
		vCRRow = vCRTo.Get(i);
		If vCRRow.IsMaster Then
			vCRTo.Delete(i);
			Continue;
		EndIf;
		i = i + 1;
	EndDo;
	// Load changed charging rules to the tabular part
	ChargingRules.Load(vCRTo);
	cmUpdateChargingRulesFoliosLineNumbers(ChargingRules);
EndProcedure //  pmRemoveIsMasterChargingRules

// -----------------------------------------------------------------------------
Procedure pmLoadMasterChargingRules(pMasterDoc) Export
	// Remove "Is master" charging rules
	i = 0;
	j = 0;
	vCRTo = ChargingRules.Unload();
	While i < vCRTo.Count() Do
		vCRRow = vCRTo.Get(i);
		If vCRRow.IsMaster Then
			vCRTo.Delete(i);
			// Save position of first deleted row
			If j = 0 Then
				j = i;
			EndIf;
			Continue;
		EndIf;
		i = i + 1;
	EndDo;
	cmUpdateChargingRulesFoliosLineNumbers(vCRTo);
	// Load charging rules of the master document
	If ValueIsFilled(pMasterDoc) Then
		vCRFrom = pMasterDoc.ChargingRules.Unload();
		If vCRFrom <> Undefined Then
			If vCRFrom.Count() > 0 Then
				For Each vCRRow In vCRFrom Do
					vCRToRow = vCRTo.Insert(j);
					vCRToRow.ChargingRule = vCRRow.ChargingRule;
					vCRToRow.ChargingRuleValue = vCRRow.ChargingRuleValue;
					vCRToRow.ChargingFolio = vCRRow.ChargingFolio;
					vCRToRow.ValidFromDate = vCRRow.ValidFromDate;
					vCRToRow.ValidToDate = vCRRow.ValidToDate;
					vCRToRow.Owner = pMasterDoc;
					vCRToRow.IsMaster = True;
					vCRToRow.IsPersonal = True;
					vCRToRow.IsTransfer = True;
					cmUpdateChargingRulesFoliosLineNumbers(vCRTo);
					j = j + 1;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	// Load changed charging rules to the tabular part
	ChargingRules.Load(vCRTo);
EndProcedure //  pmLoadMasterChargingRules

// -----------------------------------------------------------------------------
Procedure pmOverloadMasterChargingRules(pMasterDoc) Export
	// Change owner and take master folios from the master document
	For Each vCRRow In ChargingRules Do	
		If vCRRow.IsMaster Then
			vOldOwner = vCRRow.Owner;
			If TypeOf(vOldOwner) = Type("DocumentRef.Accommodation") Or
			   TypeOf(vOldOwner) = Type("DocumentRef.Reservation") Then
				// Try to find index of old owner folio in the old owner charging rules
				vInd = -1;
				For Each vOldOwnerCRRow In vOldOwner.ChargingRules Do
					If vCRRow.ChargingFolio = vOldOwnerCRRow.ChargingFolio Then
						vInd = vOldOwnerCRRow.LineNumber - 1;
						Break;
					EndIf;
				EndDo;
				// Replace old charging folio with folio from the new master doc by index
				vCRRow.Owner = pMasterDoc;
				If vInd >= 0 And pMasterDoc.ChargingRules.Count() > vInd Then
					vNewOwnerCRRow = pMasterDoc.ChargingRules.Get(vInd);
					vCRRow.ChargingFolio = vNewOwnerCRRow.ChargingFolio;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
EndProcedure //  pmOverloadMasterChargingRules

// -----------------------------------------------------------------------------
Procedure pmLoadDefaultChargingRules() Export
	ChargingRules.Clear();
	If ValueIsFilled(AccommodationType) And AccommodationType.PostToRoomMainFolio And Not IsForFolioSplit Then
		vOneRoomDoc = GetRoomMainReservation();
		If ValueIsFilled(vOneRoomDoc) Then
			// Use folios from the one room document
			If AccommodationType.DoNotCreatePersonalFolios Then
				cmLoadMainRoomGuestChargingRules(ThisObject, vOneRoomDoc);
			Else
				cmUseParentChargingRules(ThisObject, vOneRoomDoc, True);
			EndIf;
			i = 0;
			While i < ChargingRules.Count() Do
				vCRRow = ChargingRules.Get(i);
				If vCRRow.ChargingRule = Enums.ChargingRuleTypes.RoomRevenuePrice Or
				   vCRRow.ChargingRule = Enums.ChargingRuleTypes.RoomRevenuePriceByRoomType Or 
				   vCRRow.ChargingRule = Enums.ChargingRuleTypes.RoomRevenuePricePercent Or 
				   vCRRow.ChargingRule = Enums.ChargingRuleTypes.RoomRevenueAmount Or 
				   vCRRow.ChargingRule = Enums.ChargingRuleTypes.RestOfRoomRevenuePrice Then
					ChargingRules.Delete(i);
					Continue;
				EndIf;
				i = i + 1;
			EndDo;
			cmUpdateChargingRulesFoliosLineNumbers(ChargingRules);
		Else
			pmCreateFolios();
		EndIf;
	Else
		pmCreateFolios();
	EndIf;
	If ValueIsFilled(Customer) And Not ValueIsFilled(Contract) Then
		pmLoadChargingRules(Customer);
	EndIf;
	If ValueIsFilled(Contract) Then
		pmLoadChargingRules(Contract);
	EndIf;
	If ValueIsFilled(Guest) Then
		pmLoadChargingRules(Guest);
	EndIf;
	If ValueIsFilled(Room) Then
		pmLoadChargingRules(Room);
	EndIf;
EndProcedure //  pmLoadDefaultChargingRules

// -----------------------------------------------------------------------------
Procedure pmReloadDefaultChargingRules(pOneRoomDoc) Export
	If AccommodationType.DoNotCreatePersonalFolios Then
		// Load folios from the one room document and mark them as transfer
		cmLoadMainRoomGuestChargingRules(ThisObject, pOneRoomDoc);
	Else
		// Clear all charging rules but personal or master
		p = -1;
		i = 0;
		vPersonalFoliosAvailable = False;
		While i < ChargingRules.Count() Do
			vCRRow = ChargingRules.Get(i);
			If vCRRow.IsPersonal And Not vCRRow.IsMaster Then
				vPersonalFoliosAvailable = True;
			EndIf;
			If Not vCRRow.IsPersonal And Not vCRRow.IsMaster Then
				ChargingRules.Delete(i);
				// Save position of first deleted row
				If p = -1 Then
					p = i;
				EndIf;
				Continue;
			EndIf;
			i = i + 1;
		EndDo;
		If p = -1 Then
			p = 0;
		EndIf;
		cmUpdateChargingRulesFoliosLineNumbers(ChargingRules);
		// Use folios from the one room document
		For Each vRMCRRow In pOneRoomDoc.ChargingRules Do
			If Not vPersonalFoliosAvailable And vRMCRRow.IsPersonal Then
				cmUseParentChargingRules(ThisObject, pOneRoomDoc, True);
				Break;
			EndIf;
			If Not vRMCRRow.IsPersonal And Not vRMCRRow.IsMaster Then
				vCRRow = ChargingRules.Insert(p);
				FillPropertyValues(vCRRow, vRMCRRow, , "LineNumber");
				vCRRow.IsTransfer = True;
				cmUpdateChargingRulesFoliosLineNumbers(ChargingRules);
				p = p + 1;
			EndIf;
		EndDo;
		// Remove splitters
		i = 0;
		While i < ChargingRules.Count() Do
			vCRRow = ChargingRules.Get(i);
			If vCRRow.ChargingRule = Enums.ChargingRuleTypes.RoomRevenuePrice Or
			   vCRRow.ChargingRule = Enums.ChargingRuleTypes.RoomRevenuePriceByRoomType Or 
			   vCRRow.ChargingRule = Enums.ChargingRuleTypes.RoomRevenuePricePercent Or 
			   vCRRow.ChargingRule = Enums.ChargingRuleTypes.RoomRevenueAmount Or 
			   vCRRow.ChargingRule = Enums.ChargingRuleTypes.RestOfRoomRevenuePrice Then
				ChargingRules.Delete(i);
				Continue;
			EndIf;
			i = i + 1;
		EndDo;
		cmUpdateChargingRulesFoliosLineNumbers(ChargingRules);
	EndIf;
EndProcedure // pmReloadDefaultChargingRules

// -----------------------------------------------------------------------------
Procedure pmAddBankTransferChargingRule(pPayerIsAgent = False, pPaymentMethod = Undefined) Export
	vCustomer = Customer;
	vContract = Contract;
	If Not ValueIsFilled(vCustomer) Then
		If ValueIsFilled(Hotel) Then
			vCustomer = Hotel.IndividualsCustomer;
			vContract = Hotel.IndividualsContract;
		EndIf;
	EndIf;
	If Not ValueIsFilled(vCustomer) And Not pPayerIsAgent Then
		Raise String(Ref) + " - " + NStr("en='Customer is not defined!';ru='Не указан контрагент!';de='Der Partner ist nicht angegeben!'");
	ElsIf Not ValueIsFilled(Agent) And pPayerIsAgent Then
		Raise String(Ref) + " - " + NStr("en='Agent is not defined!';ru='Не указан агент!';de='Der Agent ist nicht angegeben!'");
	EndIf;
	// Get default owners charging rules
	vOwnerCRs = Hotel.CustomerChargingRules;
	If ValueIsFilled(Agent) And pPayerIsAgent Then
		vOwnerCRs = Agent.ChargingRules;
	ElsIf ValueIsFilled(vContract) And vContract.ChargingRules.Count() > 0 Then
		vOwnerCRs = vContract.ChargingRules;
	ElsIf vCustomer.ChargingRules.Count() > 0  Then
		vOwnerCRs = vCustomer.ChargingRules;
	Else 
		vCustomerParent = vCustomer.Parent;
		While ValueIsFilled(vCustomerParent) Do
			If vCustomerParent.ChargingRules.Count() > 0  Then
				vOwnerCRs = vCustomerParent.ChargingRules;
				Break;
			EndIf;
			vCustomerParent = vCustomerParent.Parent; 
		EndDo;
	EndIf;
	If ValueIsFilled(Hotel) And ValueIsFilled(GuestGroup) Then
		If vOwnerCRs.Count() = 0 Then
			// Try to find existing charging rule row with the same type
			vCRIsFound = False;
			vCRRows = ChargingRules.FindRows(New Structure("ChargingRule, ChargingRuleValue, ValidFromDate, ValidToDate", Enums.ChargingRuleTypes.InRate, Undefined, '00010101', '00010101'));
			If vCRRows.Count() = 1 Then
				vCRIsFound = True;
				vCR = vCRRows.Get(0);
			Else
				vCR = ChargingRules.Insert(0);
				cmUpdateChargingRulesFoliosLineNumbers(ChargingRules);
			EndIf;
			
			// Create new folio and use base rules
			If vCRIsFound And ValueIsFilled(vCR.ChargingFolio) Then
				vFolioObj = vCR.ChargingFolio.GetObject();
				vFolioObj.Read();
			Else
				vOldFolioRef = cmGetChargingRulesRowFolio(GuestGroup, pmGetThisDocumentRef(), ChargingRules.IndexOf(vCR) + 1);
				If ValueIsFilled(vOldFolioRef) Then
					vFolioObj = vOldFolioRef.GetObject();
					vFolioObj.DeletionMark = False;
				Else
					vFolioObj = Documents.Folio.CreateDocument();
				EndIf;
			EndIf;
			cmFillFolioFromTemplate(vFolioObj, Undefined, Hotel, Date);
			If Not ValueIsFilled(vFolioObj.ParentDoc) Or 
			   ValueIsFilled(vFolioObj.ParentDoc) And TypeOf(vFolioObj.ParentDoc) <> Type("DocumentRef.Accommodation") Then
				vFolioObj.ParentDoc = pmGetThisDocumentRef();
			EndIf;
			If Not vFolioObj.DoNotUpdateCompany Then
				vFolioObj.Company = Company;
			EndIf;
			If Not vFolioObj.DoNotUpdateCustomer Then
				vFolioObj.Customer = ?(pPayerIsAgent, Agent, vCustomer);
				vFolioObj.Contract = ?(pPayerIsAgent, Undefined, vContract);
			EndIf;
			If Not vFolioObj.DoNotFillAgent Then
				vFolioObj.Agent = Agent;
			EndIf;
			vFolioObj.GuestGroup = GuestGroup;
			vFolioObj.PaymentMethod = Hotel.PaymentMethodForCustomerPayments;
			If ValueIsFilled(vFolioObj.Contract) Then
				vFolioObj.FolioCurrency = vContract.AccountingCurrency;
				If ValueIsFilled(vContract.PlannedPaymentMethod) Then
					vFolioObj.PaymentMethod = vContract.PlannedPaymentMethod;
				EndIf;
			Else
				If pPayerIsAgent Then
					vFolioObj.FolioCurrency = Agent.AccountingCurrency;
					If ValueIsFilled(Agent.PlannedPaymentMethod) Then
						vFolioObj.PaymentMethod = Agent.PlannedPaymentMethod;
					EndIf;
				Else
					vFolioObj.FolioCurrency = vCustomer.AccountingCurrency;
					If ValueIsFilled(vCustomer.PlannedPaymentMethod) Then
						vFolioObj.PaymentMethod = vCustomer.PlannedPaymentMethod;
					EndIf;
				EndIf;
			EndIf;
			vFolioObj.Client = Guest;
			vFolioObj.Room = Room;
			vFolioObj.DateTimeFrom = CheckInDate;
			vFolioObj.DateTimeTo = CheckOutDate;
			vFolioObj.LineNumber = ChargingRules.IndexOf(vCR) + 1;
			If pPaymentMethod <> Undefined Then
				vFolioObj.PaymentMethod = pPaymentMethod;
			EndIf;
			vFolioObj.Write(DocumentWriteMode.Write);
			
			// Add new charging rule
			If Not vFolioObj.DoNotUpdateCustomer Then
				If pPayerIsAgent And ValueIsFilled(Agent) Then
					vCR.Owner = Agent;
				Else
					If ValueIsFilled(vContract) Then
						vCR.Owner = vContract;
					Else
						vCR.Owner = vCustomer;
					EndIf;
				EndIf;
			Else
				If ValueIsFilled(vFolioObj.Customer) Then
					vCR.Owner = ?(ValueIsFilled(vFolioObj.Contract), vFolioObj.Contract, vFolioObj.Customer);
				Else
					vCR.Owner = Undefined;
				Endif;
			EndIf;
			vCR.ChargingFolio = vFolioObj.Ref;
			vCR.ChargingRule = Enums.ChargingRuleTypes.InRate;
		Else
			For i = 0 To (vOwnerCRs.Count() - 1) Do
				vOwnerCRsRow = vOwnerCRs.Get(i);
				If Not ValueIsFilled(vOwnerCRsRow.ChargingFolio) Then
					Continue;
				EndIf;
				
				// Try to find existing charging rule row with the same type
				vCRIsFound = False;
				vCRRows = ChargingRules.FindRows(New Structure("ChargingRule, ChargingRuleValue, ValidFromDate, ValidToDate", vOwnerCRsRow.ChargingRule, vOwnerCRsRow.ChargingRuleValue, vOwnerCRsRow.ValidFromDate, vOwnerCRsRow.ValidToDate));
				If vCRRows.Count() = 1 Then
					vCRIsFound = True;
					vCR = vCRRows.Get(0);
				Else
					vCR = ChargingRules.Insert(i);
					cmUpdateChargingRulesFoliosLineNumbers(ChargingRules);
				EndIf;
				
				// Get folio object
				vFolioObj = Undefined;
				If vCRIsFound And ValueIsFilled(vCR.ChargingFolio) And Not vOwnerCRsRow.ChargingFolio.IsMaster Then
					vFolioObj = vCR.ChargingFolio.GetObject();
					vFolioObj.Read();
					cmFillFolioFromTemplate(vFolioObj, vOwnerCRsRow.ChargingFolio, Hotel, Date);
					If Not ValueIsFilled(vFolioObj.ParentDoc) Or 
					   ValueIsFilled(vFolioObj.ParentDoc) And TypeOf(vFolioObj.ParentDoc) <> Type("DocumentRef.Accommodation") Then
						vFolioObj.ParentDoc = pmGetThisDocumentRef();
					EndIf;
					If Not vFolioObj.DoNotUpdateCompany Then
						vFolioObj.Company = Company;
					EndIf;
					If Not vFolioObj.DoNotUpdateCustomer Then
						vFolioObj.Customer = ?(pPayerIsAgent, Agent, vCustomer);
						vFolioObj.Contract = ?(pPayerIsAgent, Undefined, vContract);
					EndIf;
					If Not vFolioObj.DoNotFillAgent Then
						vFolioObj.Agent = Agent;
					EndIf;
					vFolioObj.GuestGroup = GuestGroup;
					vFolioObj.DateTimeFrom = CheckInDate;
					vFolioObj.DateTimeTo = CheckOutDate;
					vFolioObj.Client = Guest;
					vFolioObj.Room = Room;
					vFolioObj.LineNumber = ChargingRules.IndexOf(vCR) + 1;
					If pPaymentMethod <> Undefined Then
						vFolioObj.PaymentMethod = pPaymentMethod;
					EndIf;
					vFolioObj.Write(DocumentWriteMode.Write);
				Else
					If Not vOwnerCRsRow.ChargingFolio.IsMaster Then
						// Create new folio and take parameters from the template folio
						vOldFolioRef = cmGetChargingRulesRowFolio(GuestGroup, pmGetThisDocumentRef(), ChargingRules.IndexOf(vCR) + 1);
						If ValueIsFilled(vOldFolioRef) Then
							vFolioObj = vOldFolioRef.GetObject();
							vFolioObj.DeletionMark = False;
						Else
							vFolioObj = Documents.Folio.CreateDocument();
						EndIf;
						cmFillFolioFromTemplate(vFolioObj, vOwnerCRsRow.ChargingFolio, Hotel, Date);
						vFolioObj.ParentDoc = pmGetThisDocumentRef();
						If Not vFolioObj.DoNotUpdateCompany Then
							vFolioObj.Company = Company;
						EndIf;
						If Not vFolioObj.DoNotUpdateCustomer Then
							vFolioObj.Customer = ?(pPayerIsAgent, Agent, vCustomer);
							vFolioObj.Contract = ?(pPayerIsAgent, Undefined, vContract);
						EndIf;
						If Not vFolioObj.DoNotFillAgent Then
							vFolioObj.Agent = Agent;
						EndIf;
						vFolioObj.GuestGroup = GuestGroup;
						vFolioObj.DateTimeFrom = CheckInDate;
						vFolioObj.DateTimeTo = CheckOutDate;
						vFolioObj.Client = Guest;
						vFolioObj.Room = Room;
						vFolioObj.LineNumber = ChargingRules.IndexOf(vCR) + 1;
						If pPaymentMethod <> Undefined Then
							vFolioObj.PaymentMethod = pPaymentMethod;
						EndIf;
						vFolioObj.Write(DocumentWriteMode.Write);
					Else
						vFolioObj = vOwnerCRsRow.ChargingFolio.GetObject();
						vFolioObj.Read();
					EndIf;
				EndIf;
				
				// Add new charging rule
				If Not vFolioObj.DoNotUpdateCustomer Then
					If pPayerIsAgent And ValueIsFilled(Agent) Then
						vCR.Owner = Agent;
					Else
						If ValueIsFilled(vContract) Then
							vCR.Owner = vContract;
						Else
							vCR.Owner = vCustomer;
						EndIf;
					EndIf;
				Else
					If ValueIsFilled(vFolioObj.Customer) Then
						vCR.Owner = ?(ValueIsFilled(vFolioObj.Contract), vFolioObj.Contract, vFolioObj.Customer);
					Else
						vCR.Owner = Undefined;
					Endif;
				EndIf;
				vCR.ChargingFolio = vFolioObj.Ref;
				vCR.ChargingRule = vOwnerCRsRow.ChargingRule;
				vCR.ChargingRuleValue = vOwnerCRsRow.ChargingRuleValue;
				vCR.ValidFromDate = vOwnerCRsRow.ValidFromDate;
				vCR.ValidToDate = vOwnerCRsRow.ValidToDate;
			EndDo;
		EndIf;
	EndIf;
EndProcedure // pmAddBankTransferChargingRule

// -----------------------------------------------------------------------------
//  Get reservation prices for all day types of room rate
//
// Parameters:
//  pByDays	 - Number	 - 
// 
// Returns:
//  ValueTable - List of prices
//
Function pmGetPrices(pByDays = False) Export
	vPrices = Services.Unload();
	vPrices.Columns.Add("SumBeforeDiscount", cmGetSumTypeDescription());
	vPrices.Columns.Add("PriceBeforeDiscount", cmGetSumTypeDescription());
	If Not ValueIsFilled(RoomRate) Then
    	vPrices.Clear();
		Return vPrices;
	EndIf;
	// Remove not in price services
	vNotInPriceRows = vPrices.FindRows(New Structure("IsInPrice", False));
	If vNotInPriceRows <> Undefined Then
		For Each vNotInPriceRow In vNotInPriceRows Do
			vPrices.Delete(vNotInPriceRow);
		EndDo;
	EndIf;
	// Recalculate prices taking discounts into account
	For Each vCurSrv In vPrices Do
		vService = vCurSrv.Service;
		vCurSrv.SumBeforeDiscount = vCurSrv.Sum;
		If ValueIsFilled(Agent) And Agent = Customer And AgentCommission <> 0 And 
		   cmCustomerIsPayer(ChargingRules.Unload(), Customer, Contract, GuestGroup, IgnoreGroupChargingRules) Then
			If vCurSrv.DiscountSum <> 0 Then
				vCurSrv.Sum = vCurSrv.Sum - vCurSrv.DiscountSum - vCurSrv.CommissionSum;
				cmSumOnChange(vService, vCurSrv.Price, vCurSrv.Quantity, vCurSrv.Sum, vCurSrv.VATRate, vCurSrv.VATSum, True, vCurSrv.AccountingDate);
			Else
				vCurSrv.Sum = vCurSrv.Sum - vCurSrv.CommissionSum;
				cmSumOnChange(vService, vCurSrv.Price, vCurSrv.Quantity, vCurSrv.Sum, vCurSrv.VATRate, vCurSrv.VATSum, True, vCurSrv.AccountingDate);
			EndIf;
		Else
			If vCurSrv.DiscountSum <> 0 Then
				vCurSrv.Sum = vCurSrv.Sum - vCurSrv.DiscountSum;
				cmSumOnChange(vService, vCurSrv.Price, vCurSrv.Quantity, vCurSrv.Sum, vCurSrv.VATRate, vCurSrv.VATSum, True, vCurSrv.AccountingDate);
			EndIf;
		EndIf;
		// Take quantity into account
		If Not vCurSrv.IsRoomRevenue And vCurSrv.IsInPrice And vCurSrv.Price <> 0 Then
			If vService.ChargePerPerson Then
				If NumberOfPersons > 1 Then
					vCurSrv.SumBeforeDiscount = Round(vCurSrv.SumBeforeDiscount / NumberOfPersons, 2);
					vCurSrv.Sum = Round(vCurSrv.Sum / NumberOfPersons, 2);
				EndIf;
			Else
				If RoomQuantity > 1 Then
					vCurSrv.SumBeforeDiscount = Round(vCurSrv.SumBeforeDiscount / RoomQuantity, 2);
					vCurSrv.Sum = Round(vCurSrv.Sum / RoomQuantity, 2);
				EndIf;
			EndIf;
		EndIf;
		// Function will return price columns only, so take quantity into account
		vCurSrv.PriceBeforeDiscount = vCurSrv.SumBeforeDiscount;
		vCurSrv.Price = vCurSrv.Sum;
		// Change accounting dates for breakfast
		If Not vCurSrv.IsManual And vCurSrv.IsInPrice And vCurSrv.Price <> 0 And 
		   ValueIsFilled(vService.QuantityCalculationRule) Then
			vAccountingDateMove = cmGetAccountingDateMove(vService.QuantityCalculationRule, vCurSrv.IsManual, ThisObject, False);
			If vAccountingDateMove < 0 Then
				vCurSrv.AccountingDate = vCurSrv.AccountingDate + vAccountingDateMove*(24*3600);
				vCurSrv.CalendarDayType = cmGetDocumentCalendarDayType(ThisObject, vCurSrv.AccountingDate);
			EndIf;
		EndIf;
	EndDo;	
	// Set is manual price flag for all services per accounting day where at least one manual price service is
	vDays = vPrices.Copy(, "AccountingDate, IsManualPrice");
	vDays.GroupBy("AccountingDate, IsManualPrice",);
	vMPDays = vDays.FindRows(New Structure("IsManualPrice", True));
	For Each vMPDay In vMPDays Do
		vDayRows = vPrices.FindRows(New Structure("AccountingDate", vMPDay.AccountingDate));
		For Each vDayRow In vDayRows Do
			vDayRow.IsManualPrice = True;
		EndDo;
	EndDo;
	// Group services by accounting date to get prices per day
	vPrices.GroupBy("AccountingDate, CalendarDayType, IsManualPrice, FolioCurrency", "Price, PriceBeforeDiscount");
	// Clear accounting date for all services where there is no manual price
	For Each vRow In vPrices Do
		If Not vRow.IsManualPrice And Not pByDays Then
			vRow.AccountingDate = '00010101';
		EndIf;
	EndDo;
	// Group services by all attributes to remove per accounting date groups
	vPrices.GroupBy("AccountingDate, CalendarDayType, FolioCurrency, Price, PriceBeforeDiscount", );
	// Remove duplicated rows (this means that we will take prices from check-in day only)
	vPricesKeys = vPrices.CopyColumns();
	i = 0;
	While i < vPrices.Count() Do
		vCurSrv = vPrices.Get(i);
		vKeyRows = vPricesKeys.FindRows(New Structure("AccountingDate, CalendarDayType, FolioCurrency, Price", 
		                                              vCurSrv.AccountingDate,
		                                              vCurSrv.CalendarDayType,
		                                              vCurSrv.FolioCurrency,
		                                              vCurSrv.Price));
		If vKeyRows.Count() = 0 Then
			vKeySrv = vPricesKeys.Add();
			FillPropertyValues(vKeySrv, vCurSrv);
			i = i + 1;
		Else
			// Delete duplicated row
			vPrices.Delete(i);
		EndIf;
	EndDo;	
	// Sort prices by accounting date
	vPrices.Sort("AccountingDate, FolioCurrency"); 
	// Return prices
	Return vPrices;
EndFunction //  pmGetPrices

// -----------------------------------------------------------------------------
// 
// Returns:
//  CatalogRef.Languages - Language
//
Function pmGetDocumentLanguage() Export
	If ValueIsFilled(Customer) Then
		If ValueIsFilled(Customer.Language) Then
			Return Customer.Language;
		EndIf;
	EndIf;
	If ValueIsFilled(Guest) Then
		If ValueIsFilled(Guest.Language) Then
			Return Guest.Language;
		EndIf;
	EndIf;
	Return Catalogs.Languages.EmptyRef();
EndFunction //  pmGetDocumentLanguage

// -----------------------------------------------------------------------------
Procedure pmProcessHotelChange() Export
	If ValueIsFilled(Hotel) Then
		SetNewNumber(Catalogs.Hotels.pmGetPrefix(Hotel));
		If Not ValueIsFilled(Company) Or ValueIsFilled(Company) And ValueIsFilled(Company.Hotel) And Company.Hotel <> Hotel Then
			Company = Hotel.Company;
		EndIf;
		If ValueIsFilled(RoomRate) And ValueIsFilled(RoomRate.Hotel) And RoomRate.Hotel <> Hotel Then
			RoomRate = Hotel.RoomRate;
			RoomRateServiceGroup = Hotel.RoomRateServiceGroup;
		EndIf;
		ReportingCurrency = Hotel.ReportingCurrency;
		ReportingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, ReportingCurrency, Date);
		// Recreate guest group as it has hotel as owner
		pmCreateGuestGroup();
		// Reset room and room type
		If Room.Owner <> Hotel Then
			Room = Catalogs.Rooms.EmptyRef();
		EndIf;
		If RoomType.Owner <> Hotel Then
			RoomType = Catalogs.RoomTypes.EmptyRef();
		EndIf;
	EndIf;
EndProcedure //  pmProcessHotelChange	

// -----------------------------------------------------------------------------
// 
// Returns:
//  ValueTable - List of accommodation 
//
Function pmGetAccommodations() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.ParentDoc = &qParentDoc
	|	AND Accommodation.Posted = TRUE
	|ORDER BY
	|	Accommodation.PointInTime";
	vQry.SetParameter("qParentDoc", Ref);
	vAccs = vQry.Execute().Unload();
	Return vAccs;
EndFunction //  pmGetAccommodations

// -----------------------------------------------------------------------------
//
// Parameters:
//  rPayerStr	 - String - Payer
// 
// Returns:
//  Enums.WhoPays - Who pays 
//
Function pmSetPlannedPaymentMethod(rPayerStr = "") Export
	vPayer = Enums.WhoPays.Guest;
	rPayerStr = "";
	vAccSrvFolio = Undefined;
	vChargingRules = ChargingRules.Unload();
	If Not IgnoreGroupChargingRules Then
		cmAddGuestGroupChargingRules(vChargingRules, GuestGroup);
	EndIf;
	If vChargingRules.Count() > 0 Then
		If Services.Count() > 0 Then
			// Set planned payment method from the accommodation service folio
			i = Services.Count() - 1;
			While i >= 0 Do
				vSrvRow = Services.Get(i);
				If ValueIsFilled(vSrvRow.Folio) Then
					If vSrvRow.IsRoomRevenue And vSrvRow.IsInPrice And Not vSrvRow.RoomRevenueAmountsOnly Then
						vAccSrvFolio = vSrvRow.Folio;
						Break;
					EndIf;
				EndIf;
				i = i - 1;
			EndDo;
		EndIf;
		If ValueIsFilled(vAccSrvFolio) And ValueIsFilled(vAccSrvFolio.PaymentMethod) Then
			If PlannedPaymentMethod <> vAccSrvFolio.PaymentMethod Then
				PlannedPaymentMethod = vAccSrvFolio.PaymentMethod;
			EndIf;
		Else
			// Set planned payment method from the first charging rule
			vCRRow = vChargingRules.Get(0);
			If ValueIsFilled(vCRRow.ChargingFolio) Then
				If ValueIsFilled(vCRRow.ChargingFolio.PaymentMethod) Then
					vAccSrvFolio = vCRRow.ChargingFolio;
					If PlannedPaymentMethod <> vAccSrvFolio.PaymentMethod Then
						PlannedPaymentMethod = vAccSrvFolio.PaymentMethod;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(vAccSrvFolio) Then
		vCustomer = vAccSrvFolio.Customer;
		vContract = vAccSrvFolio.Contract;
		If Not ValueIsFilled(vCustomer) And ValueIsFilled(Hotel) Then
			vCustomer = Hotel.IndividualsCustomer;
			vContract = Hotel.IndividualsContract;
		EndIf;
		vAgent = vAccSrvFolio.Agent;
		vClient = Undefined;
		For Each vCRRow In vChargingRules Do
			If vCRRow.ChargingFolio = vAccSrvFolio Then
				vOwner = Undefined;
				If ValueIsFilled(vCRRow.Owner) And 
				  (TypeOf(vOwner) = Type("DocumentRef.Accommodation") Or TypeOf(vOwner) = Type("DocumentRef.Reservation")) And 
				   vOwner <> Ref Then
					vOwner = vCRRow.Owner;
					If ValueIsFilled(vOwner.Guest) Then
						vClient = vOwner.Guest;
					EndIf;
				Else
					If ValueIsFilled(vAgent) And vAgent = vCustomer And vAgent = Agent Then
						vOwner = vAgent;
					ElsIf ValueIsFilled(vContract) Then
						vOwner = vContract;
					ElsIf ValueIsFilled(vCustomer) Then 
						vOwner = vCustomer;
					ElsIf ValueIsFilled(vAccSrvFolio.Client) Then 
						vOwner = vAccSrvFolio.Client;
						vClient = vOwner;
					EndIf;
				EndIf;
				If vCRRow.Owner <> vOwner Then
					vCRRow.Owner = vOwner;
				EndIf;
			EndIf;
		EndDo;
		If Not ValueIsFilled(vClient) Then
			vClient = Guest;
		EndIf;
		If ValueIsFilled(vAgent) And vAgent = vCustomer And vAgent = Agent Then
			rPayerStr = TrimAll(vAgent.Description);
			vPayer = Enums.WhoPays.Agent;
		ElsIf ValueIsFilled(vCustomer) Then
			rPayerStr = TrimAll(vCustomer.Description);
			If ValueIsFilled(Hotel) And vCustomer = Hotel.IndividualsCustomer And vClient = Guest Then
				rPayerStr = TrimAll(vClient.FullName);
				vPayer = Enums.WhoPays.Guest;
			ElsIf vCustomer = Customer Then
				vPayer = Enums.WhoPays.Customer;
			Else
				vPayer = Enums.WhoPays.ChargingRules;
			EndIf;
		ElsIf ValueIsFilled(vClient) Then
			rPayerStr = TrimAll(vClient.FullName);
			If vClient = Guest Then
				vPayer = Enums.WhoPays.Guest;
			Else
				vPayer = Enums.WhoPays.ChargingRules;
			EndIf;
		ElsIf ValueIsFilled(Hotel) And ValueIsFilled(Hotel.IndividualsCustomer) Then
			rPayerStr = TrimAll(Hotel.IndividualsCustomer.Description);
		EndIf;
	EndIf;
	Return vPayer;
EndFunction //  pmSetPlannedPaymentMethod

// -----------------------------------------------------------------------------
// 
// Returns:
//  DocumentRef.Folio - Ref
//
Function pmGetAccommodationServiceChargingFolio() Export
	vAccSrvFolio = Undefined;
	If Services.Count() > 0 Then
		For Each vSrvRow In Services Do
			If vSrvRow.IsRoomRevenue And ValueIsFilled(vSrvRow.Folio) Then
				vAccSrvFolio = vSrvRow.Folio;
				Break;
			EndIf;
		EndDo;
	EndIf;
	If Not ValueIsFilled(vAccSrvFolio) Then
		vChargingRules = ChargingRules.Unload();
		If Not IgnoreGroupChargingRules Then
			cmAddGuestGroupChargingRules(vChargingRules, GuestGroup);
		EndIf;
		If vChargingRules.Count() > 0 Then
			vCRRow = vChargingRules.Get(0);
			If ValueIsFilled(vCRRow.ChargingFolio) Then
				vAccSrvFolio = vCRRow.ChargingFolio;
			EndIf;
		EndIf;
	EndIf;
	Return vAccSrvFolio;
EndFunction //  pmGetAccommodationServiceChargingFolio

// -----------------------------------------------------------------------------
Procedure pmSetDoCharging() Export 
	vDoCharging = False;
	If ValueIsFilled(ReservationStatus) And ReservationStatus.DoCharging And 
	  (Not ReservationStatus.DoChargingIfRoomIsFilled Or ReservationStatus.DoChargingIfRoomIsFilled And ValueIsFilled(Room)) Then
		vDoCharging = True;
	EndIf;
	If DoCharging <> vDoCharging Then
		DoCharging = vDoCharging;
	EndIf;
EndProcedure //  pmSetDoCharging

// -----------------------------------------------------------------------------
// 
// Returns:
//  DocumentRef.Reservation - Ref 
//
Function pmGetMasterReservation() Export
	vMasterDoc = Documents.Reservation.EmptyRef();
	// Try to find master document in the list of all documents in the group
	vGuestGroupReservations = GuestGroup.GetObject().pmGetReservations();
	vMasterRow = vGuestGroupReservations.Find(True, "IsMaster");
	If vMasterRow <> Undefined Then
		vMasterDoc = vMasterRow.Reservation;
	EndIf;
	Return vMasterDoc;
EndFunction //  pmGetMasterReservation

// -----------------------------------------------------------------------------
Procedure pmLoadManualServicesFromParentDoc(pBase, pIsUpdate = False) Export
	vChargingRules = ChargingRules.Unload();
	vBaseChargingRules = pBase.ChargingRules.Unload();
	// Remove manual services from the current document first
	If pIsUpdate Then
		vManualServicesArray = Services.FindRows(New Structure("IsManual", True));
		For Each vRow In vManualServicesArray Do
			Services.Delete(vRow);
		EndDo;
	EndIf;
	// Load manual services
	vBaseManualServicesArray = pBase.Services.Unload().FindRows(New Structure("IsManual", True));
	For Each vBaseRow In vBaseManualServicesArray Do
		vCurSrv = Services.Add();
		FillPropertyValues(vCurSrv, vBaseRow);
		// Recalculate quantity according to the number of persons
		If TypeOf(pBase) = Type("DocumentRef.Reservation") And vCurSrv.Quantity = pBase.RoomQuantity And pBase.RoomQuantity <> 0 Then
			vCurSrv.Quantity = vCurSrv.Quantity / pBase.RoomQuantity * RoomQuantity;
		ElsIf vCurSrv.Quantity = pBase.NumberOfPersons And pBase.NumberOfPersons <> 0 Then
			vCurSrv.Quantity = vCurSrv.Quantity / pBase.NumberOfPersons * NumberOfPersons;
		EndIf;
		// Recalculate resources
		cmQuantityOnChange(vCurSrv.Price, vCurSrv.Quantity, vCurSrv.Sum, vCurSrv.VATRate, vCurSrv.VATSum, vCurSrv.AccountingDate);
		// Recalculate service room sales parameters
		cmRecalculateServiceRoomSalesParameters(vCurSrv, ThisObject);
		// Recalculate discounts
		pmCalculateServiceDiscounts(vCurSrv);
		// Recalculate commissions
		pmCalculateServiceCommissions(vCurSrv);
		// Try to find charging folio in the current document charging rules with the same conditions as in the base document
		vCRWasFound = False;
		vBaseCRRow = vBaseChargingRules.Find(vBaseRow.Folio, "ChargingFolio");
		If vBaseCRRow <> Undefined Then
			vCRRows = vChargingRules.FindRows(New Structure("ChargingRule, ChargingRuleValue, ValidFromDate, ValidToDate, Owner", vBaseCRRow.ChargingRule, vBaseCRRow.ChargingRuleValue, vBaseCRRow.ValidFromDate, vBaseCRRow.ValidToDate, vBaseCRRow.Owner));
			If vCRRows.Count() = 1 Then
				vCRWasFound = True;
				vCRRow = vCRRows.Get(0);
				vCurSrv.Folio = vCRRow.ChargingFolio;
			EndIf;
		EndIf;
		If Not vCRWasFound Then
			// Assign charging folio according to the charging rules
			pmSetServiceFolioBasedOnChargingRules(vCurSrv, vChargingRules, True);
		EndIf;
	EndDo;
EndProcedure //  pmLoadManualServicesFromParentDoc

// -----------------------------------------------------------------------------
Procedure pmLoadManualPricesFromParentDoc(pBase) Export
	// Load manual prices
	vMCServices = pBase.Services.Unload().FindRows(New Structure("IsManualPrice, IsManual", True, False));
	For Each vMCSrv In vMCServices Do
		// Try to find appropriate automatic service
		vSrvRows = New Array;
		If vMCSrv.IsRoomRevenue And vMCSrv.IsInPrice And Not vMCSrv.IsManual And Not vMCSrv.IsSplit Then
			vSrvRows = Services.FindRows(New Structure("AccountingDate, Service, IsRoomRevenue, IsInPrice, IsManual, IsSplit, AccommodationType", vMCSrv.AccountingDate, vMCSrv.Service, vMCSrv.IsRoomRevenue, vMCSrv.IsInPrice, vMCSrv.IsManual, vMCSrv.IsSplit, vMCSrv.AccommodationType));
		Else
			vSrvRows = Services.FindRows(New Structure("AccountingDate, Service, IsSplit, AccommodationType", vMCSrv.AccountingDate, vMCSrv.Service, vMCSrv.IsSplit, vMCSrv.AccommodationType));
		EndIf;
		For Each vCurSrv In vSrvRows Do
			If ValueIsFilled(vMCSrv.Folio) And ValueIsFilled(pBase) And TypeOf(pBase) = Type("DocumentRef.Reservation") And pBase.RoomQuantity = 1 Then
				FillPropertyValues(vCurSrv, vMCSrv, , "AccountingDate, Service, IsManual, FolioCurrency, FolioCurrencyExchangeRate, LineNumber, Company, Room, RoomType, AccommodationType, RoomRate, GuestsCheckedIn, GuestDays, AdditionalBedsRented, BedsRented, RoomsRented, Timetable, CalendarDayType, RateSum, RateDiscountSum, RateCommissionSum, ClientType, SourceOfBusiness, MarketingCode, BoardPlace" + 
				                                      ?(vMCSrv.QuantityIsChanged, "", ", Quantity") + 
												      ?(vMCSrv.DiscountIsChanged, "", ", DiscountType, Discount, DiscountServiceGroup, DiscountSum, VATDiscountSum, DiscountConfirmationText") + 
												      ?(vMCSrv.CommissionIsChanged, "", ", AgentCommissionType, AgentCommission, CommissionSum, VATCommissionSum"));
				If vCurSrv.FolioCurrency <> vMCSrv.Folio.FolioCurrency Then
					vFolioObj = vMCSrv.Folio.GetObject();
					vFolioObj.Read();
					vFolioObj.FolioCurrency = vCurSrv.FolioCurrency;
					vFolioObj.Write(DocumentWriteMode.Write);
				EndIf;
			Else			
				FillPropertyValues(vCurSrv, vMCSrv, , "Folio, AccountingDate, Service, IsManual, FolioCurrency, FolioCurrencyExchangeRate, LineNumber, Company, Room, RoomType, AccommodationType, RoomRate, GuestsCheckedIn, GuestDays, AdditionalBedsRented, BedsRented, RoomsRented, Timetable, CalendarDayType, RateSum, RateDiscountSum, RateCommissionSum, ClientType, SourceOfBusiness, MarketingCode, BoardPlace" + 
				                                      ?(vMCSrv.QuantityIsChanged, "", ", Quantity") + 
												      ?(vMCSrv.DiscountIsChanged, "", ", DiscountType, Discount, DiscountServiceGroup, DiscountSum, VATDiscountSum, DiscountConfirmationText") + 
												      ?(vMCSrv.CommissionIsChanged, "", ", AgentCommissionType, AgentCommission, CommissionSum, VATCommissionSum"));
			EndIf;
			// Change service quantity proportionally
			If ValueIsFilled(pBase) And TypeOf(pBase) = Type("DocumentRef.Reservation") And Not vCurSrv.QuantityIsChanged Then
				vCurSrv.Quantity = vCurSrv.Quantity * (RoomQuantity / ?(pBase.RoomQuantity = 0, RoomQuantity, pBase.RoomQuantity));
				// Recalculate service room sales parameters
				cmRecalculateServiceRoomSalesParameters(vCurSrv, ThisObject);
			EndIf;
			// Recalculate all service resources
			cmPriceOnChange(vCurSrv.Price, vCurSrv.Quantity, vCurSrv.Sum, vCurSrv.VATRate, vCurSrv.VATSum, vCurSrv.AccountingDate);
			If Not vCurSrv.DiscountIsChanged Then
				pmCalculateServiceDiscounts(vCurSrv);
			EndIf;
			If Not vCurSrv.CommissionIsChanged Then
				pmCalculateServiceCommissions(vCurSrv);
			EndIf;
			vCurSrv.IsManualPrice = True;
		EndDo;
	EndDo;
EndProcedure // pmLoadManualPricesFromParentDoc

// -----------------------------------------------------------------------------
Procedure pmCalculateAccumulationDiscountForAdditionalService(pSrvRow) Export
	vRoomRate = pSrvRow.RoomRate;
	vAccDiscounts = pmGetAccumulatingDiscountResources();
	If vAccDiscounts.Count() > 0 Then
		vAccDiscountsRow = vAccDiscounts.Get(0);
		vDiscountType = vAccDiscountsRow.DiscountType;
		If Not ValueIsFilled(vDiscountType) Then
			Return;
		EndIf;
		If Not vDiscountType.IsPerVisit And (Not ValueIsFilled(Hotel.DateToGetBonusBalance) Or 
		   Hotel.DateToGetBonusBalance = Enums.DatesToGetBonusBalance.CheckInDate) Then
			Return;
		EndIf;
		If pSrvRow.AccountingDate < vDiscountType.DateValidFrom Or
		   (pSrvRow.AccountingDate > vDiscountType.DateValidTo And ValueIsFilled(vDiscountType.DateValidTo)) Then
			Return;
		EndIf;
		If vDiscountType.MLOS > 0 And Duration < vDiscountType.MLOS Then
			Return;
		EndIf;
		vDiscountDimension = vAccDiscountsRow.DiscountDimension;
		If cmIsServiceInServiceGroup(pSrvRow.Service, DiscountServiceGroup) And 
		  (Not vDiscountType.IsForRackRatesOnly Or 
		   vDiscountType.IsForRackRatesOnly And ValueIsFilled(vRoomRate) And vRoomRate.IsRackRate Or
		   pSrvRow.IsManual) Then
			vDiscountTypeObj = vDiscountType.GetObject();
			For i = 1 To pSrvRow.LineNumber Do
				vWrkSrvRow = Services.Get(i - 1);
				If vWrkSrvRow.AccountingDate <= pSrvRow.AccountingDate Then
					vSrvDiscountDimension = Undefined;
					vNumberOfPersons = NumberOfPersons;
					If ValueIsFilled(vWrkSrvRow.RoomRate) And vWrkSrvRow.GuestDays > 0 Then
						If vWrkSrvRow.RoomRate.RateChargeDirection = Enums.RateChargeDirections.MergeToTheMainRoomGuest Then
							vNumberOfPersons = NumberOfPersons * vWrkSrvRow.GuestDays;
						EndIf;
					ElsIf ValueIsFilled(RoomRate) And vWrkSrvRow.GuestDays > 0 Then
						If RoomRate.RateChargeDirection = Enums.RateChargeDirections.MergeToTheMainRoomGuest Then
							vNumberOfPersons = NumberOfPersons * vWrkSrvRow.GuestDays;
						EndIf;
					EndIf;
					vSrvResource = vDiscountTypeObj.pmCalculateResource(vWrkSrvRow, vNumberOfPersons, vWrkSrvRow.Folio, DiscountCard, vSrvDiscountDimension);
					If TypeOf(vSrvDiscountDimension) = TypeOf(vDiscountDimension) Then
						If vSrvResource <> 0 Then
							vAccDiscountsRow.Resource = vAccDiscountsRow.Resource + vSrvResource;
						EndIf;
					EndIf;
				EndIf;
			EndDo;
			vResource = vAccDiscountsRow.Resource;
			vDiscountConfirmationText = "";
			vDiscount = vDiscountTypeObj.pmGetAccumulatingDiscount(pSrvRow.Service, pSrvRow.AccountingDate, 
																   vResource, 
																   vDiscountConfirmationText);
			If vDiscount <> 0 Then
				pSrvRow.DiscountType = vDiscountType;
				pSrvRow.Discount = vDiscount;
				pSrvRow.DiscountServiceGroup = DiscountServiceGroup;
				pSrvRow.DiscountConfirmationText = vDiscountConfirmationText;
			EndIf;
		EndIf;
	EndIf;						
EndProcedure //  pmCalculateAccumulationDiscountForAdditionalService

// -----------------------------------------------------------------------------
Procedure pmFillAccumulationDiscountForManualServices() Export
	// Fill accumulation discounts for manual services
	If ValueIsFilled(DiscountType) And DiscountType.IsAccumulatingDiscount Then
		For Each vSrvRow In Services Do
			If vSrvRow.IsManual Then
				If cmIsServiceInServiceGroup(vSrvRow.Service, DiscountServiceGroup) Then
					pmCalculateAccumulationDiscountForAdditionalService(vSrvRow);
					pmCalculateServiceDiscounts(vSrvRow);
				Else
					vSrvRow.DiscountType = Catalogs.DiscountTypes.EmptyRef();
					vSrvRow.DiscountServiceGroup = Catalogs.ServiceGroups.EmptyRef();
					vSrvRow.Discount = 0;
					vSrvRow.DiscountConfirmationText = "";
				EndIf;
			EndIf;
		EndDo;
	EndIf;
EndProcedure //  pmFillAccumulationDiscountForManualServices

// -----------------------------------------------------------------------------
Procedure pmClearManualServicesDiscount() Export		
	// Clear manual services discounts
	For Each vSrvRow In Services Do
		If vSrvRow.IsManual And ValueIsFilled(vSrvRow.DiscountType) Then
			vSrvRow.DiscountType = Catalogs.DiscountTypes.EmptyRef();
			vSrvRow.DiscountServiceGroup = Catalogs.ServiceGroups.EmptyRef();
			vSrvRow.Discount = 0;
			vSrvRow.DiscountConfirmationText = "";
		EndIf;
	EndDo;
EndProcedure //  pmClearManualServicesDiscount

// -----------------------------------------------------------------------------
Procedure pmSetDiscounts() Export
	// Do nothing if this is inactive document
	If Not ValueIsFilled(ReservationStatus) Or ValueIsFilled(ReservationStatus) And (Not ReservationStatus.IsActive And Not ReservationStatus.IsPreliminary Or ReservationStatus.IsCheckIn) Then
		Return;
	EndIf;
	// Leave special offers in discount confirmation text
	vDiscountConfirmationTextReset = "";
	vSpecOfferPos = StrFind(DiscountConfirmationText, Char(8226));
	If vSpecOfferPos > 0 Then
		vDiscountConfirmationTextReset = Mid(DiscountConfirmationText, vSpecOfferPos);
	EndIf;
	// Check if client can use discount card
	If Not cmCheckUserPermissions("HavePermissionToUseClientDiscountCardWithAnyOtherClientHavingIt") Then
		If ValueIsFilled(AccommodationType) And (AccommodationType.Type = Enums.AccomodationTypes.Room Or AccommodationType.Type = Enums.AccomodationTypes.Beds) Then
			If ValueIsFilled(DiscountCard) And ValueIsFilled(DiscountCard.Client) Then
				vClearDiscountCard = True;
				If ValueIsFilled(Guest) And Guest = DiscountCard.Client Then
					vClearDiscountCard = False;
				EndIf;
				If ValueIsFilled(GuestGroup) And ValueIsFilled(GuestGroup.Client) And GuestGroup.Client = DiscountCard.Client Then
					vClearDiscountCard = False;
				EndIf;
				If vClearDiscountCard Then
					DiscountCard = Catalogs.DiscountCards.EmptyRef();
					DiscountType = Catalogs.DiscountTypes.EmptyRef();
					DiscountConfirmationText = vDiscountConfirmationTextReset;
					DiscountServiceGroup = Catalogs.ServiceGroups.EmptyRef();
					Discount = 0;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	// Check if manual discount is choosen
	If ValueIsFilled(DiscountType) And DiscountType.IsManualDiscount Then
		// Check if discount type is for individuals only
		If DiscountType.IsForIndividualsOnly Then
			If ValueIsFilled(Customer) And Not Customer.IsIndividual Or ValueIsFilled(Agent) Then
				DiscountType = Catalogs.DiscountTypes.EmptyRef();
				DiscountConfirmationText = vDiscountConfirmationTextReset;
				DiscountServiceGroup = Catalogs.ServiceGroups.EmptyRef();
				Discount = 0;
			EndIf;
		EndIf;
		Return;
	ElsIf Not ValueIsFilled(DiscountType) And Discount <> 0 Then
		Return;
	EndIf;
	// Fill discounts from the different sources
	DiscountType = Catalogs.DiscountTypes.EmptyRef();
	DiscountConfirmationText = vDiscountConfirmationTextReset;
	DiscountServiceGroup = Catalogs.ServiceGroups.EmptyRef();
	Discount = 0;
	vOldTurnOffAutomaticDiscounts = TurnOffAutomaticDiscounts;
	vTurnOffAutomaticDiscountsWasSet = False;
	TurnOffAutomaticDiscounts = False;
	If ValueIsFilled(RoomRate) And RoomRate.NoDiscounts Then
		Return;
	EndIf;
	If ValueIsFilled(Contract) And Contract.NoDiscounts Then
		Return;
	EndIf;
	If ValueIsFilled(Guest) And ValueIsFilled(Guest.DiscountCard) And Not ValueIsFilled(DiscountCard) Then
		DiscountCard = Guest.DiscountCard;
	EndIf;
	If ValueIsFilled(ClientType) And ClientType.NoDiscounts Then
		Return;
	EndIf;
	If ValueIsFilled(DiscountCard) Then
		If ValueIsFilled(DiscountCard.DiscountType) Then
			vDiscountType = DiscountCard.DiscountType;
			vDiscount = vDiscountType.GetObject().pmGetDiscount(CheckInDate, , Hotel);
			If cmCompareDiscounts(vDiscount, Discount) Or vDiscountType.DifferentDiscountPercentsForServiceGroupsAllowed Or 
			   vDiscountType.EachNDayIsFreeOfCharge > 0 Or
			   vDiscountType.IsAccumulatingDiscount And vDiscountType.HasToBeDirectlyAssigned Or
			   vDiscountType.IsAccumulatingDiscount And vDiscountType.BonusCalculationFactor <> 0 Then 
				DiscountType = vDiscountType;
				DiscountConfirmationText = DiscountCard.Metadata().Synonym + " " + TrimAll(DiscountCard.Description);
				DiscountServiceGroup = DiscountType.DiscountServiceGroup;
				If Not vDiscountType.DifferentDiscountPercentsForServiceGroupsAllowed Then
					Discount = vDiscount;
				EndIf;
				If ValueIsFilled(DiscountCard.ClientType) Then
					ClientType = DiscountCard.ClientType;
				EndIf;
			EndIf;
			If ValueIsFilled(DiscountCard.Client) Then
				If Not cmCheckUserPermissions("HavePermissionToUseClientDiscountCardWithAnyOtherClientHavingIt") Then
					If vDiscountType.IsPersonalDiscount Then
						If DiscountCard.Client <> Guest Then
							DiscountCard = Catalogs.DiscountCards.EmptyRef();
							DiscountType = Catalogs.DiscountTypes.EmptyRef();
							DiscountConfirmationText = vDiscountConfirmationTextReset;
							DiscountServiceGroup = Catalogs.ServiceGroups.EmptyRef();
							Discount = 0;
						EndIf;
					ElsIf ValueIsFilled(GuestGroup) And ValueIsFilled(GuestGroup.Client) Then
						If DiscountCard.Client <> GuestGroup.Client Then
							DiscountCard = Catalogs.DiscountCards.EmptyRef();
							DiscountType = Catalogs.DiscountTypes.EmptyRef();
							DiscountConfirmationText = vDiscountConfirmationTextReset;
							DiscountServiceGroup = Catalogs.ServiceGroups.EmptyRef();
							Discount = 0;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(DiscountCard) And DiscountCard.TurnOffAutomaticDiscounts Then
			TurnOffAutomaticDiscounts = DiscountCard.TurnOffAutomaticDiscounts;
			vTurnOffAutomaticDiscountsWasSet = True;
		EndIf;
	EndIf;	
	If ValueIsFilled(ClientType) Then
		If ClientType.TurnOffAutomaticDiscounts Then
			TurnOffAutomaticDiscounts = ClientType.TurnOffAutomaticDiscounts;
			vTurnOffAutomaticDiscountsWasSet = True;
		EndIf;
		If ValueIsFilled(ClientType.DiscountType) Then
			vDiscountType = ClientType.DiscountType;
			vDiscount = vDiscountType.GetObject().pmGetDiscount(CheckInDate, , Hotel);
			If cmCompareDiscounts(vDiscount, Discount) Or vDiscountType.DifferentDiscountPercentsForServiceGroupsAllowed Or 
			   vDiscountType.EachNDayIsFreeOfCharge > 0 Or
			   vDiscountType.IsAccumulatingDiscount And vDiscountType.HasToBeDirectlyAssigned Or 
			   vDiscountType.IsAccumulatingDiscount And vDiscountType.BonusCalculationFactor <> 0 Then 
				DiscountType = vDiscountType;
				If IsBlankString(ClientTypeConfirmationText) Then
					DiscountConfirmationText = NStr("en='Client type discount';ru='По типу клиента';de='Nach Kundentyp'");
				Else
					DiscountConfirmationText = ClientTypeConfirmationText;
				EndIf;
				DiscountServiceGroup = DiscountType.DiscountServiceGroup;
				If Not vDiscountType.DifferentDiscountPercentsForServiceGroupsAllowed Then
					Discount = vDiscount;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(MarketingCode) Then
		If MarketingCode.TurnOffAutomaticDiscounts Then
			TurnOffAutomaticDiscounts = MarketingCode.TurnOffAutomaticDiscounts;
			vTurnOffAutomaticDiscountsWasSet = True;
		EndIf;
		If ValueIsFilled(MarketingCode.DiscountType) Then
			vDiscountType = MarketingCode.DiscountType;
			vDiscount = vDiscountType.GetObject().pmGetDiscount(CheckInDate, , Hotel);
			If cmCompareDiscounts(vDiscount, Discount) Or vDiscountType.DifferentDiscountPercentsForServiceGroupsAllowed Or 
			   vDiscountType.EachNDayIsFreeOfCharge > 0 Or
			   vDiscountType.IsAccumulatingDiscount And vDiscountType.HasToBeDirectlyAssigned Or 
			   vDiscountType.IsAccumulatingDiscount And vDiscountType.BonusCalculationFactor <> 0 Then 
				DiscountType = vDiscountType;
				If IsBlankString(MarketingCodeConfirmationText) Then
					DiscountConfirmationText = NStr("en='Marketing code discount';ru='По направлению маркетинга';de='Nach Marketingrichtung'");
				Else
					DiscountConfirmationText = MarketingCodeConfirmationText;
				EndIf;
				DiscountServiceGroup = DiscountType.DiscountServiceGroup;
				If Not vDiscountType.DifferentDiscountPercentsForServiceGroupsAllowed Then
					Discount = vDiscount;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(Guest) Then
		If ValueIsFilled(Guest.DiscountType) Then
			vDiscountType = Guest.DiscountType;
			vDiscount = vDiscountType.GetObject().pmGetDiscount(CheckInDate, , Hotel);
			If cmCompareDiscounts(vDiscount, Discount) Or vDiscountType.DifferentDiscountPercentsForServiceGroupsAllowed Or 
			   vDiscountType.EachNDayIsFreeOfCharge > 0 Or
			   vDiscountType.IsAccumulatingDiscount And vDiscountType.HasToBeDirectlyAssigned Or 
			   vDiscountType.IsAccumulatingDiscount And vDiscountType.BonusCalculationFactor <> 0 Then 
				DiscountType = vDiscountType;
				DiscountServiceGroup = DiscountType.DiscountServiceGroup;
				If IsBlankString(Guest.DiscountConfirmationText) Then
					DiscountConfirmationText = NStr("en='Guest discount';ru='По гостю';de='Nach Gast'");
				Else
					DiscountConfirmationText = Guest.DiscountConfirmationText;
				EndIf;
				If Not vDiscountType.DifferentDiscountPercentsForServiceGroupsAllowed Then
					Discount = vDiscount;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(Customer) Then
		If ValueIsFilled(Customer.DiscountType) Then
			vDiscountType = Customer.DiscountType;
			vDiscount = vDiscountType.GetObject().pmGetDiscount(CheckInDate, , Hotel);
			If cmCompareDiscounts(vDiscount, Discount) Or vDiscountType.DifferentDiscountPercentsForServiceGroupsAllowed Or 
			   vDiscountType.EachNDayIsFreeOfCharge > 0 Or
			   vDiscountType.IsAccumulatingDiscount And vDiscountType.HasToBeDirectlyAssigned Or 
			   vDiscountType.IsAccumulatingDiscount And vDiscountType.BonusCalculationFactor <> 0 Then 
				DiscountType = vDiscountType;
				DiscountServiceGroup = DiscountType.DiscountServiceGroup;
				If IsBlankString(Customer.DiscountConfirmationText) Then
					DiscountConfirmationText = NStr("en='Customer discount';ru='По контрагенту';de='Nach Partner'");
				Else
					DiscountConfirmationText = Customer.DiscountConfirmationText;
				EndIf;
				If Not vDiscountType.DifferentDiscountPercentsForServiceGroupsAllowed Then
					Discount = vDiscount;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(Contract) Then
		vReservationDate = Date;
		If ValueIsFilled(GuestGroup) And ValueIsFilled(GuestGroup.CreateDate) Then
			vReservationDate = GuestGroup.CreateDate;
		EndIf;
		vDiscountType = Undefined;
		If ValueIsFilled(Contract.DiscountType) Then
			vDiscountType = Contract.DiscountType;
		EndIf;
		For Each vRRRow In Contract.RoomRates Do
			vRoomType = RoomType;
			If ValueIsFilled(RoomTypeUpgrade) Then
				vRoomType = RoomTypeUpgrade;
			EndIf;
			If ValueIsFilled(vRoomType) And ValueIsFilled(vRRRow.RoomType) Then
				If vRRRow.RoomType.IsFolder And Not vRoomType.BelongsToItem(vRRRow.RoomType) Then
					Continue;
				ElsIf Not vRRRow.RoomType.IsFolder And vRoomType <> vRRRow.RoomType Then 
					Continue;
				EndIf;
			EndIf;
			If ValueIsFilled(vRRRow.DiscountType) Then
				If Not ValueIsFilled(vRRRow.CheckInDateFrom) And Not ValueIsFilled(vRRRow.CheckInDateTo) And 
				   Not ValueIsFilled(vRRRow.ReservationDateFrom) And Not ValueIsFilled(vRRRow.ReservationDateTo) Then
					vDiscountType = vRRRow.DiscountType;
					Break;
				ElsIf (Not ValueIsFilled(vRRRow.ReservationDateFrom) Or ValueIsFilled(vRRRow.ReservationDateFrom) And vRRRow.ReservationDateFrom <= vReservationDate) And 
					  (Not ValueIsFilled(vRRRow.ReservationDateTo) Or ValueIsFilled(vRRRow.ReservationDateTo) And EndOfDay(vRRRow.ReservationDateTo) > vReservationDate) And 
					  (Not ValueIsFilled(vRRRow.CheckInDateFrom) Or ValueIsFilled(vRRRow.CheckInDateFrom) And vRRRow.CheckInDateFrom <= CheckInDate) And 
					  (Not ValueIsFilled(vRRRow.CheckInDateTo) Or ValueIsFilled(vRRRow.CheckInDateTo) And EndOfDay(vRRRow.CheckInDateTo) > CheckInDate) Then
					vDiscountType = vRRRow.DiscountType;
					Break;
				EndIf;
			EndIf;
		EndDo;
		If ValueIsFilled(vDiscountType) Then
			vDiscount = vDiscountType.GetObject().pmGetDiscount(CheckInDate, , Hotel);
			If cmCompareDiscounts(vDiscount, Discount) Or vDiscountType.DifferentDiscountPercentsForServiceGroupsAllowed Or 
			   vDiscountType.EachNDayIsFreeOfCharge > 0 Or
			   vDiscountType.IsAccumulatingDiscount And vDiscountType.HasToBeDirectlyAssigned Or 
			   vDiscountType.IsAccumulatingDiscount And vDiscountType.BonusCalculationFactor <> 0 Then 
				DiscountType = vDiscountType;
				DiscountServiceGroup = DiscountType.DiscountServiceGroup;
				If IsBlankString(Contract.DiscountConfirmationText) Then
					DiscountConfirmationText = NStr("en='Contract discount';ru='По договору';de='Nach Vertrag'");
				Else
					DiscountConfirmationText = Contract.DiscountConfirmationText;
				EndIf;
				If Not vDiscountType.DifferentDiscountPercentsForServiceGroupsAllowed Then
					Discount = vDiscount;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(RoomRate) Then
		If ValueIsFilled(RoomRate.DiscountType) Then
			vDiscountType = RoomRate.DiscountType;
			vDiscount = vDiscountType.GetObject().pmGetDiscount(CheckInDate, , Hotel);
			If cmCompareDiscounts(vDiscount, Discount) Or vDiscountType.DifferentDiscountPercentsForServiceGroupsAllowed Or 
			   vDiscountType.EachNDayIsFreeOfCharge > 0 Or
			   vDiscountType.IsAccumulatingDiscount And vDiscountType.HasToBeDirectlyAssigned Or 
			   vDiscountType.IsAccumulatingDiscount And vDiscountType.BonusCalculationFactor <> 0 Then 
				DiscountType = vDiscountType;
				DiscountServiceGroup = DiscountType.DiscountServiceGroup;
				DiscountConfirmationText = NStr("en='Room rate discount';ru='По тарифу';de='Nach Tarif'");
				If Not vDiscountType.DifferentDiscountPercentsForServiceGroupsAllowed Then
					Discount = vDiscount;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If Catalogs.ExternalDataProcessors.SetDiscounts.ExternalProcessingType = Enums.ExternalProcessingTypes.Algorithm Then
		If Not IsBlankString(Catalogs.ExternalDataProcessors.SetDiscounts.Algorithm) Then
			SetSafeMode(True);
			Execute(TrimAll(Catalogs.ExternalDataProcessors.SetDiscounts.Algorithm));
			SetSafeMode(False);
		EndIf;
	EndIf;
	If ValueIsFilled(DiscountType) Then
		If DiscountType.IsForIndividualsOnly Then
			If ValueIsFilled(Customer) And Not Customer.IsIndividual Or ValueIsFilled(Agent) Then
				DiscountType = Catalogs.DiscountTypes.EmptyRef();
				DiscountConfirmationText = vDiscountConfirmationTextReset;
				DiscountServiceGroup = Catalogs.ServiceGroups.EmptyRef();
				Discount = 0;
			EndIf;
		EndIf;
		If ValueIsFilled(DiscountType) And DiscountType.TurnOffAutomaticDiscounts Then
			TurnOffAutomaticDiscounts = DiscountType.TurnOffAutomaticDiscounts;
			vTurnOffAutomaticDiscountsWasSet = True;
		EndIf;
		// Fill accumulation discounts for manual services
		pmFillAccumulationDiscountForManualServices();
	Else
		// Clear manual services discounts
		pmClearManualServicesDiscount();
	EndIf;
	If Not vTurnOffAutomaticDiscountsWasSet Then
		TurnOffAutomaticDiscounts = vOldTurnOffAutomaticDiscounts;
	EndIf;
	// Check should we reset client type or not
	If ValueIsFilled(DiscountType) And DiscountType.ForceSetOfClientType Then
		If DiscountType.ClientType <> ClientType Then
			ClientType = DiscountType.ClientType;
		EndIf;
	EndIf;
EndProcedure //  pmSetDiscounts

// -----------------------------------------------------------------------------
//
// Parameters:
//  pDate				 - Date							 - 
//  pRoomRates			 - ValueTable					 - 
//  pRoom				 - CatalogRef.Rooms				 - 
//  pRoomType			 - CatalogRef.RoomTypes			 - 
//  pAccommodationType	 - CatalogRef.AccommodationTypes - 
//  pRoomRate			 - CatalogRef.RoomRate			 - 
//  pCheckInDate		 - Date							 - 
// 
// Returns:
//  Structure - Accommodation plan attributes
//
Function pmGetAccommodationPlanAttributes(pDate, pRoomRates, pRoom, pRoomType, 
	                                      pAccommodationType, pRoomRate, pCheckInDate) Export
	vCurStruct = New Structure("Room, RoomType, AccommodationType, RoomRate, RoomChangeDate", 
	                           pRoom, pRoomType, pAccommodationType, pRoomRate, pCheckInDate);
	For Each vRRRow In pRoomRates Do
		If vRRRow.AccountingDate > pDate Then
			Break;
		Else
			If ValueIsFilled(vRRRow.Room) Then
				vCurStruct.Room = vRRRow.Room;
				vCurStruct.RoomChangeDate = vRRRow.AccountingDate;
			EndIf;
			If ValueIsFilled(vRRRow.RoomType) Then
				vCurStruct.RoomType = vRRRow.RoomType;
			EndIf;
			If ValueIsFilled(vRRRow.AccommodationType) Then
				vCurStruct.AccommodationType = vRRRow.AccommodationType;
			EndIf;
			If ValueIsFilled(vRRRow.RoomRate) Then
				vCurStruct.RoomRate = vRRRow.RoomRate;
			EndIf;
		EndIf;	
	EndDo;
	Return vCurStruct;
EndFunction //  pmGetAccommodationPlanAttributes

// -----------------------------------------------------------------------------
Procedure pmDeleteUnusedChargingRuleFolios() Export
	vObjectRef = pmGetThisDocumentRef();
	// If folio left in the list do not have any transactions based on it then delete it
	For Each vCRRow In ChargingRules Do
		If Not ValueIsFilled(vCRRow.ChargingFolio) Then
			Continue;
		EndIf;
		vFolioRef = vCRRow.ChargingFolio;
		If ValueIsFilled(vFolioRef.ParentDoc) And 
		   vFolioRef.ParentDoc <> vObjectRef And 
		  (ValueIsFilled(vFolioRef.ParentDoc.DataVersion) Or ValueIsFilled(vObjectRef.DataVersion)) Then
			Continue;
		EndIf;
		If Not vFolioRef.IsMaster And Not vFolioRef.DeletionMark Then
			vFolioObj = vFolioRef.GetObject();
			vFolioObj.Read();
			If IsNew() Then
				vFolioObj.ParentDoc = Undefined;
				vFolioObj.Write(DocumentWriteMode.Write);
			EndIf;
			vTransCount = vFolioObj.pmGetAllFolioTransactionsCount();
			If vTransCount = 0 Then
				vFolioObj.IsClosed = True;
				vFolioObj.Write(DocumentWriteMode.Write);
				vFolioObj.SetDeletionMark(True);
			EndIf;
		EndIf;
	EndDo;
EndProcedure //  pmDeleteUnusedChargingRuleFolios

// -----------------------------------------------------------------------------
// 
// Returns:
//  DocumentRef.Reservation - Ref
//
Function pmGetThisDocumentRef() Export
	vObjectRef = Ref;
	If IsNew() Then
		vObjectRef = GetNewObjectRef();
		If Not ValueIsFilled(vObjectRef) Then
			SetNewObjectRef(Documents.Reservation.GetRef());
			vObjectRef = GetNewObjectRef();
		EndIf;
	EndIf;
	Return vObjectRef;
EndFunction //  pmGetThisDocumentRef

// -----------------------------------------------------------------------------
Procedure pmFillOccupationPercents(pPeriodFrom, pPeriodTo, pRoomRate = Undefined, pRoomType = Undefined) Export
	vRoomRate = RoomRate;
	If ValueIsFilled(pRoomRate) Then
		vRoomRate = pRoomRate;
	EndIf;
	vRoomType = RoomType;
	If ValueIsFilled(pRoomType) Then
		vRoomType = pRoomType;
	EndIf;
	// Fill occupation percents
	vThereAreChanges = False;
	vQry = New Query();
	If ValueIsFilled(vRoomRate) And vRoomRate.PriceTagType = Enums.PriceTagTypes.ByOccupancyPercentPerRoomTypePerDayType Then
		vQry.Text = 
		"SELECT
		|	CalendarDays.CalendarDayType AS DayType,
		|	CalendarDays.CalendarDayType.SortCode AS DayTypeSortCode
		|INTO CalendarDayTypes
		|FROM
		|	InformationRegister.CalendarDays.SliceLast(
		|			&qPriceCalculationDate,
		|			Calendar = &qCalendar
		|				AND AccountingDate >= &qPeriodFrom
		|				AND AccountingDate <= &qPeriodTo) AS CalendarDays
		|
		|GROUP BY
		|	CalendarDays.CalendarDayType,
		|	CalendarDays.CalendarDayType.SortCode
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DayTypesDays.CalendarDayType AS DayType,
		|	MIN(DayTypesDays.AccountingDate) AS MinPeriodFrom,
		|	MAX(DayTypesDays.AccountingDate) AS MaxPeriodTo
		|FROM
		|	InformationRegister.CalendarDays.SliceLast(
		|			&qPriceCalculationDate,
		|			Calendar = &qCalendar
		|				AND AccountingDate >= &qStartPeriodFrom
		|				AND AccountingDate <= &qEndPeriodTo
		|				AND CalendarDayType IN
		|					(SELECT
		|						CalendarDayTypes.DayType
		|					FROM
		|						CalendarDayTypes)) AS DayTypesDays
		|
		|GROUP BY
		|	DayTypesDays.CalendarDayType";
		vQry.SetParameter("qCalendar", ?(ValueIsFilled(vRoomRate), vRoomRate.Calendar, Undefined));
		vQry.SetParameter("qPriceCalculationDate", ?(ValueIsFilled(PriceCalculationDate), PriceCalculationDate, CurrentSessionDate()));
		vQry.SetParameter("qStartPeriodFrom", pPeriodFrom - 24*3600*180);
		vQry.SetParameter("qEndPeriodTo", EndOfDay(pPeriodTo) + 24*3600*180);
		vQry.SetParameter("qPeriodFrom", pPeriodFrom);
		vQry.SetParameter("qPeriodTo", EndOfDay(pPeriodTo));
		vDayTypes = vQry.Execute().Unload();
		// Do for each day type found
		For Each vDayTypesRow In vDayTypes Do
			vQry.Text = 
			"SELECT
			|	SUM(ISNULL(PerDayType.TotalRooms, 0)) AS TotalRooms,
			|	SUM(ISNULL(PerDayType.TotalRoomsBlocked, 0)) AS TotalRoomsBlocked,
			|	SUM(ISNULL(PerDayType.RoomsRented, 0)) AS RoomsRented
			|FROM
			|	(SELECT
			|		TotalRooms.Period AS Period,
			|		TotalRooms.CounterClosingBalance AS CounterClosingBalance,
			|		ISNULL(TotalRooms.TotalRoomsClosingBalance, 0) AS TotalRooms,
			|		-ISNULL(TotalRooms.RoomsBlockedClosingBalance, 0) AS TotalRoomsBlocked,
			|		ISNULL(RoomSales.RoomsRented, 0) AS RoomsRented
			|	FROM
			|		AccumulationRegister.RoomInventory.BalanceAndTurnovers(
			|				&qPeriodFrom,
			|				&qPeriodTo,
			|				Day,
			|				RegisterRecordsAndPeriodBoundaries,
			|				Hotel = &qHotel
			|					AND RoomType = &qRoomType) AS TotalRooms
			|			LEFT JOIN (SELECT
			|				RoomSalesTurnovers.Period AS Period,
			|				SUM(RoomSalesTurnovers.RoomsRentedTurnover) AS RoomsRented
			|			FROM
			|				(SELECT
			|					RoomSales.Period AS Period,
			|					RoomSales.RoomsRentedTurnover AS RoomsRentedTurnover,
			|					0 AS CounterClosingBalance
			|				FROM
			|					AccumulationRegister.Sales.Turnovers(
			|							&qPeriodFrom,
			|							&qPeriodTo,
			|							Day,
			|							Hotel = &qHotel
			|								AND RoomType = &qRoomType
			|								AND ParentDoc <> &qRef) AS RoomSales
			|				
			|				UNION ALL
			|				
			|				SELECT
			|					RoomSalesForecast.Period,
			|					RoomSalesForecast.RoomsRentedTurnover,
			|					0
			|				FROM
			|					AccumulationRegister.SalesForecast.Turnovers(
			|							&qForecastPeriodFrom,
			|							&qForecastPeriodTo,
			|							Day,
			|							Hotel = &qHotel
			|								AND RoomType = &qRoomType
			|								AND ParentDoc <> &qRef) AS RoomSalesForecast
			|				
			|				UNION ALL
			|				
			|				SELECT
			|					CommitmentBlocks.Period,
			|					CommitmentBlocks.RoomsRemainsClosingBalance,
			|					CommitmentBlocks.CounterClosingBalance
			|				FROM
			|					AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
			|							&qPeriodFrom,
			|							&qPeriodTo,
			|							Day,
			|							RegisterRecordsAndPeriodBoundaries,
			|							Hotel = &qHotel
			|								AND RoomType = &qRoomType
			|								AND RoomQuota.IsCommitment) AS CommitmentBlocks) AS RoomSalesTurnovers
			|			
			|			GROUP BY
			|				RoomSalesTurnovers.Period) AS RoomSales
			|			ON TotalRooms.Period = RoomSales.Period) AS PerDayType";
			vQry.SetParameter("qHotel", Hotel);
			vQry.SetParameter("qRef", pmGetThisDocumentRef());
			vQry.SetParameter("qRoomType", vRoomType);
			vQry.SetParameter("qPeriodFrom", vDayTypesRow.MinPeriodFrom);
			vQry.SetParameter("qPeriodTo", EndOfDay(vDayTypesRow.MaxPeriodTo));
			vForecastStartDate = tcOnServer.GetForecastStartDate(Hotel);
			vQry.SetParameter("qForecastPeriodFrom", Max(vDayTypesRow.MinPeriodFrom, BegOfDay(vForecastStartDate)));
			vQry.SetParameter("qForecastPeriodTo", Max(EndOfDay(vDayTypesRow.MaxPeriodTo), EndOfDay(vForecastStartDate-24*3600)));
			vStats = vQry.Execute().Unload();
			If vStats.Count() = 1 Then
				vStatsRow = vStats.Get(0);
				vOccupationPercent = 0;
				If vStatsRow.TotalRooms <> Null And vStatsRow.TotalRoomsBlocked <> Null And vStatsRow.RoomsRented <> Null And 
				  (vStatsRow.TotalRooms - vStatsRow.TotalRoomsBlocked) <> 0 Then
					vOccupationPercent = Round(100*vStatsRow.RoomsRented/(vStatsRow.TotalRooms - vStatsRow.TotalRoomsBlocked), 2);
				EndIf;
				vAccountingDate = Max(vDayTypesRow.MinPeriodFrom, pPeriodFrom);
				vMaxAccountingDate = Min(vDayTypesRow.MaxPeriodTo, pPeriodTo);
				While vAccountingDate <= vMaxAccountingDate Do
					vOPRow = OccupationPercents.Find(vAccountingDate, "AccountingDate");
					If vOPRow = Undefined Then
						vThereAreChanges = True;
						vOPRow = OccupationPercents.Add();
						vOPRow.AccountingDate = vAccountingDate;
						vOPRow.OccupationPercent = vOccupationPercent;
					EndIf;
					vAccountingDate = vAccountingDate + 24*3600;
				EndDo;
			EndIf;
		EndDo;
	ElsIf ValueIsFilled(vRoomRate) And vRoomRate.PriceTagType = Enums.PriceTagTypes.ByOccupancyPercentPerRoomType Then
		vQry.Text = 
		"SELECT
		|	TotalRooms.Period AS Period,
		|	TotalRooms.CounterClosingBalance AS CounterClosingBalance,
		|	ISNULL(TotalRooms.TotalRoomsClosingBalance, 0) AS TotalRooms,
		|	-ISNULL(TotalRooms.RoomsBlockedClosingBalance, 0) AS TotalRoomsBlocked,
		|	ISNULL(RoomSales.RoomsRented, 0) AS RoomsRented
		|FROM
		|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(
		|			&qPeriodFrom,
		|			&qPeriodTo,
		|			Day,
		|			RegisterRecordsAndPeriodBoundaries,
		|			Hotel = &qHotel
		|				AND RoomType = &qRoomType) AS TotalRooms
		|		LEFT JOIN (SELECT
		|			RoomSalesTurnovers.Period AS Period,
		|			SUM(RoomSalesTurnovers.RoomsRentedTurnover) AS RoomsRented
		|		FROM
		|			(SELECT
		|				RoomSales.Period AS Period,
		|				RoomSales.RoomsRentedTurnover AS RoomsRentedTurnover,
		|				0 AS CounterClosingBalance
		|			FROM
		|				AccumulationRegister.Sales.Turnovers(
		|						&qPeriodFrom,
		|						&qPeriodTo,
		|						Day,
		|						Hotel = &qHotel
		|							AND RoomType = &qRoomType
		|							AND ParentDoc <> &qRef) AS RoomSales
		|			
		|			UNION ALL
		|			
		|			SELECT
		|				RoomSalesForecast.Period,
		|				RoomSalesForecast.RoomsRentedTurnover,
		|				0
		|			FROM
		|				AccumulationRegister.SalesForecast.Turnovers(
		|						&qForecastPeriodFrom,
		|						&qForecastPeriodTo,
		|						Day,
		|						Hotel = &qHotel
		|							AND RoomType = &qRoomType
		|							AND ParentDoc <> &qRef) AS RoomSalesForecast
		|			
		|			UNION ALL
		|			
		|			SELECT
		|				CommitmentBlocks.Period,
		|				CommitmentBlocks.RoomsRemainsClosingBalance,
		|				CommitmentBlocks.CounterClosingBalance
		|			FROM
		|				AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
		|						&qPeriodFrom,
		|						&qPeriodTo,
		|						Day,
		|						RegisterRecordsAndPeriodBoundaries,
		|						Hotel = &qHotel
		|							AND RoomType = &qRoomType
		|							AND RoomQuota.IsCommitment) AS CommitmentBlocks
		|			) AS RoomSalesTurnovers
		|		
		|		GROUP BY
		|			RoomSalesTurnovers.Period) AS RoomSales
		|		ON TotalRooms.Period = RoomSales.Period
		|
		|ORDER BY
		|	TotalRooms.Period";
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qRef", pmGetThisDocumentRef());
		vQry.SetParameter("qRoomType", ?(ValueIsFilled(RoomTypeUpgrade), RoomTypeUpgrade, vRoomType));
		vQry.SetParameter("qPeriodFrom", pPeriodFrom);
		vQry.SetParameter("qPeriodTo", EndOfDay(pPeriodTo));
		vForecastStartDate = tcOnServer.GetForecastStartDate(Hotel);
		vQry.SetParameter("qForecastPeriodFrom", Max(pPeriodFrom, BegOfDay(vForecastStartDate)));
		vQry.SetParameter("qForecastPeriodTo", Max(EndOfDay(pPeriodTo), EndOfDay(vForecastStartDate-24*3600)));
		vDays = vQry.Execute().Unload();
		For Each vDaysRow In vDays Do
			vAccountingDate = BegOfDay(vDaysRow.Period);
			vOPRow = OccupationPercents.Find(vAccountingDate, "AccountingDate");
			If vOPRow = Undefined Then
				vThereAreChanges = True;
				vOPRow = OccupationPercents.Add();
				vOPRow.AccountingDate = vAccountingDate;
				If vDaysRow.TotalRooms - vDaysRow.TotalRoomsBlocked <> 0 Then
					vOPRow.OccupationPercent = Round(100*vDaysRow.RoomsRented/(vDaysRow.TotalRooms - vDaysRow.TotalRoomsBlocked), 2);
				Else
					vOPRow.OccupationPercent = 0;
				EndIf;
			EndIf;
		EndDo;
	ElsIf ValueIsFilled(vRoomRate) And vRoomRate.PriceTagType = Enums.PriceTagTypes.ByOccupancyPercentPerRoomClass Then
		vQry.Text = 
		"SELECT
		|	TotalByRoomClasses.Period AS Period,
		|	TotalByRoomClasses.RoomClass AS RoomClass,
		|	SUM(TotalByRoomClasses.CounterClosingBalance) AS CounterClosingBalance,
		|	SUM(TotalByRoomClasses.TotalRooms) AS TotalRooms,
		|	SUM(TotalByRoomClasses.TotalRoomsBlocked) AS TotalRoomsBlocked,
		|	SUM(TotalByRoomClasses.RoomsRented) AS RoomsRented
		|FROM
		|	(SELECT
		|		TotalRooms.Period AS Period,
		|		TotalRooms.RoomType AS RoomType,
		|		TotalRooms.RoomType.RoomClass AS RoomClass,
		|		TotalRooms.CounterClosingBalance AS CounterClosingBalance,
		|		ISNULL(TotalRooms.TotalRoomsClosingBalance, 0) AS TotalRooms,
		|		-ISNULL(TotalRooms.RoomsBlockedClosingBalance, 0) AS TotalRoomsBlocked,
		|		ISNULL(RoomSales.RoomsRented, 0) AS RoomsRented
		|	FROM
		|		AccumulationRegister.RoomInventory.BalanceAndTurnovers(
		|				&qPeriodFrom,
		|				&qPeriodTo,
		|				Day,
		|				RegisterRecordsAndPeriodBoundaries,
		|				Hotel = &qHotel
		|					AND RoomType.RoomClass = &qRoomClass) AS TotalRooms
		|			LEFT JOIN (SELECT
		|				RoomSalesTurnovers.Period AS Period,
		|				RoomSalesTurnovers.RoomType AS RoomType,
		|				SUM(RoomSalesTurnovers.RoomsRentedTurnover) AS RoomsRented
		|			FROM
		|				(SELECT
		|					RoomSales.Period AS Period,
		|					RoomSales.RoomType AS RoomType,
		|					RoomSales.RoomsRentedTurnover AS RoomsRentedTurnover,
		|					0 AS CounterClosingBalance
		|				FROM
		|					AccumulationRegister.Sales.Turnovers(
		|							&qPeriodFrom,
		|							&qPeriodTo,
		|							Day,
		|							Hotel = &qHotel
		|								AND RoomType.RoomClass = &qRoomClass
		|								AND ParentDoc <> &qRef) AS RoomSales
		|				
		|				UNION ALL
		|				
		|				SELECT
		|					RoomSalesForecast.Period,
		|					RoomSalesForecast.RoomType,
		|					RoomSalesForecast.RoomsRentedTurnover,
		|					0
		|				FROM
		|					AccumulationRegister.SalesForecast.Turnovers(
		|							&qForecastPeriodFrom,
		|							&qForecastPeriodTo,
		|							Day,
		|							Hotel = &qHotel
		|								AND RoomType.RoomClass = &qRoomClass
		|								AND ParentDoc <> &qRef) AS RoomSalesForecast
		|				
		|				UNION ALL
		|				
		|				SELECT
		|					CommitmentBlocks.Period,
		|					CommitmentBlocks.RoomType,
		|					CommitmentBlocks.RoomsRemainsClosingBalance,
		|					CommitmentBlocks.CounterClosingBalance
		|				FROM
		|					AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
		|							&qPeriodFrom,
		|							&qPeriodTo,
		|							Day,
		|							RegisterRecordsAndPeriodBoundaries,
		|							Hotel = &qHotel
		|								AND RoomType.RoomClass = &qRoomClass
		|								AND RoomQuota.IsCommitment) AS CommitmentBlocks) AS RoomSalesTurnovers
		|			
		|			GROUP BY
		|				RoomSalesTurnovers.Period,
		|				RoomSalesTurnovers.RoomType) AS RoomSales
		|			ON TotalRooms.Period = RoomSales.Period
		|				AND TotalRooms.RoomType = RoomSales.RoomType) AS TotalByRoomClasses
		|
		|GROUP BY
		|	TotalByRoomClasses.Period,
		|	TotalByRoomClasses.RoomClass
		|
		|ORDER BY
		|	TotalByRoomClasses.Period";
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qRef", pmGetThisDocumentRef());
		vQry.SetParameter("qRoomClass", ?(ValueIsFilled(RoomTypeUpgrade), RoomTypeUpgrade.RoomClass, vRoomType.RoomClass));
		vQry.SetParameter("qPeriodFrom", pPeriodFrom);
		vQry.SetParameter("qPeriodTo", EndOfDay(pPeriodTo));
		vForecastStartDate = tcOnServer.GetForecastStartDate(Hotel);
		vQry.SetParameter("qForecastPeriodFrom", Max(pPeriodFrom, BegOfDay(vForecastStartDate)));
		vQry.SetParameter("qForecastPeriodTo", Max(EndOfDay(pPeriodTo), EndOfDay(vForecastStartDate-24*3600)));
		vDays = vQry.Execute().Unload();
		For Each vDaysRow In vDays Do
			vAccountingDate = BegOfDay(vDaysRow.Period);
			vOPRow = OccupationPercents.Find(vAccountingDate, "AccountingDate");
			If vOPRow = Undefined Then
				vThereAreChanges = True;
				vOPRow = OccupationPercents.Add();
				vOPRow.AccountingDate = vAccountingDate;
				If vDaysRow.TotalRooms - vDaysRow.TotalRoomsBlocked <> 0 Then
					vOPRow.OccupationPercent = Round(100*vDaysRow.RoomsRented/(vDaysRow.TotalRooms - vDaysRow.TotalRoomsBlocked), 2);
				Else
					vOPRow.OccupationPercent = 0;
				EndIf;
			EndIf;
		EndDo;
	Else
		vQry.Text = 
		"SELECT
		|	TotalRooms.Period AS Period,
		|	TotalRooms.CounterClosingBalance AS CounterClosingBalance,
		|	ISNULL(TotalRooms.TotalRoomsClosingBalance, 0) AS TotalRooms,
		|	ISNULL(-TotalRooms.RoomsBlockedClosingBalance, 0) AS TotalRoomsBlocked,
		|	ISNULL(RoomSales.RoomsRented, 0) AS RoomsRented
		|FROM
		|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qPeriodFrom, &qPeriodTo, Day, RegisterRecordsAndPeriodBoundaries, Hotel = &qHotel) AS TotalRooms
		|		LEFT JOIN (SELECT
		|			RoomSalesTurnovers.Period AS Period,
		|			SUM(RoomSalesTurnovers.RoomsRentedTurnover) AS RoomsRented
		|		FROM
		|			(SELECT
		|				RoomSales.Period AS Period,
		|				RoomSales.RoomsRentedTurnover AS RoomsRentedTurnover,
		|				0 AS CounterClosingBalance
		|			FROM
		|				AccumulationRegister.Sales.Turnovers(
		|						&qPeriodFrom,
		|						&qPeriodTo,
		|						Day,
		|						Hotel = &qHotel
		|							AND ParentDoc <> &qRef) AS RoomSales
		|			
		|			UNION ALL
		|			
		|			SELECT
		|				RoomSalesForecast.Period,
		|				RoomSalesForecast.RoomsRentedTurnover, 
		|				0
		|			FROM
		|				AccumulationRegister.SalesForecast.Turnovers(
		|						&qForecastPeriodFrom,
		|						&qForecastPeriodTo,
		|						Day,
		|						Hotel = &qHotel
		|							AND ParentDoc <> &qRef) AS RoomSalesForecast
		|			
		|			UNION ALL
		|			
		|			SELECT
		|				CommitmentBlocks.Period,
		|				CommitmentBlocks.RoomsRemainsClosingBalance,
		|				CommitmentBlocks.CounterClosingBalance
		|			FROM
		|				AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
		|						&qPeriodFrom,
		|						&qPeriodTo,
		|						Day,
		|						RegisterRecordsAndPeriodBoundaries,
		|						Hotel = &qHotel
		|							AND RoomQuota.IsCommitment) AS CommitmentBlocks
		|			) AS RoomSalesTurnovers
		|		
		|		GROUP BY
		|			RoomSalesTurnovers.Period) AS RoomSales
		|		ON TotalRooms.Period = RoomSales.Period
		|
		|ORDER BY
		|	TotalRooms.Period";
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qRef", pmGetThisDocumentRef());
		vQry.SetParameter("qPeriodFrom", pPeriodFrom);
		vQry.SetParameter("qPeriodTo", EndOfDay(pPeriodTo));
		vForecastStartDate = tcOnServer.GetForecastStartDate(Hotel);
		vQry.SetParameter("qForecastPeriodFrom", Max(pPeriodFrom, BegOfDay(vForecastStartDate)));
		vQry.SetParameter("qForecastPeriodTo", Max(EndOfDay(pPeriodTo), EndOfDay(vForecastStartDate-24*3600)));
		vDays = vQry.Execute().Unload();
		For Each vDaysRow In vDays Do
			vAccountingDate = BegOfDay(vDaysRow.Period);
			vOPRow = OccupationPercents.Find(vAccountingDate, "AccountingDate");
			If vOPRow = Undefined Then
				vThereAreChanges = True;
				vOPRow = OccupationPercents.Add();
				vOPRow.AccountingDate = vAccountingDate;
				If vDaysRow.TotalRooms - vDaysRow.TotalRoomsBlocked <> 0 Then
					vOPRow.OccupationPercent = Round(100*vDaysRow.RoomsRented/(vDaysRow.TotalRooms - vDaysRow.TotalRoomsBlocked), 2);
				Else
					vOPRow.OccupationPercent = 0;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	// Resort occupation percents if there are changes
	If vThereAreChanges Then
		OccupationPercents.Sort("AccountingDate");
	EndIf;
	// Remove unused dates
	i = 0;
	While i < OccupationPercents.Count() Do
		vOPRow = OccupationPercents.Get(i);
		If vOPRow.AccountingDate < BegOfDay(pPeriodFrom) Or vOPRow.AccountingDate > BegOfDay(pPeriodTo) Then
			OccupationPercents.Delete(i);
		Else
			i = i + 1;
		EndIf;
	EndDo;
EndProcedure //  pmFillOccupationPercents

// -----------------------------------------------------------------------------
Procedure pmClearOccupationPercents() Export
	If ValueIsFilled(RoomRate) And 
	   (RoomRate.PriceTagType = Enums.PriceTagTypes.ByOccupancyPercentPerRoomType Or 
	    RoomRate.PriceTagType = Enums.PriceTagTypes.ByOccupancyPercentPerRoomClass Or 
	    RoomRate.PriceTagType = Enums.PriceTagTypes.ByOccupancyPercentPerRoomTypePerDayType) Then
		OccupationPercents.Clear();
		For Each vSrvRow In Services Do
			If Not vSrvRow.IsManualPrice Then
				vSrvRow.PriceTag = Undefined;
			EndIf;
		EndDo;
	EndIf;
EndProcedure //  pmClearOccupancyPercents

// -----------------------------------------------------------------------------
Procedure pmPrintConfirmation(vSpreadsheet, SelReservation, SelReservations, SelServicesFilter, SelServiceGroup, SelShowConfirmationForCurrentReservationOnly, SelLanguage, SelObjectPrintForm) Export
	
	If SelObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintConfirmationRichTextEn Or SelObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintConfirmationRichTextDe Or SelObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintConfirmationRichTextRu Then
		vConfirmationRichObj = DataProcessors.ReservationConfirmationRichTextFormat.Create();
		vConfirmationRichObj.pmPrintConfirmation(vSpreadsheet, SelReservation, SelReservations, SelServicesFilter, SelServiceGroup, SelShowConfirmationForCurrentReservationOnly, SelLanguage, SelObjectPrintForm);
		Return;
	EndIf;
	
	// Basic checks
	If Not ValueIsFilled(SelReservation.Hotel) Then
		Raise String(Ref) + " - " + NStr("ru='У документа должна быть указана гостиница!';de='Bei dem Dokument muss das Hotel angegeben sein!';en='Hotel attribute should be filled!'");
	EndIf;
	If Not ValueIsFilled(SelLanguage) Then
		SelLanguage = SessionParameters.CurrentLanguage;
	EndIf;
	
	// Some settings
	vShowReservationNumbersInConfirmation = cmCheckUserPermissions("ShowReservationNumbersInConfirmation");
	
	// Fill and check grouping parameter
	vParameter = Upper(TrimAll(SelObjectPrintForm.Parameter));
	
	// Choose template
	vResObj = SelReservation.GetObject();
	vSpreadsheet.Clear();
	If ValueIsFilled(SelLanguage) Then
		If SelLanguage = Catalogs.Languages.EN Then
			vTemplate = vResObj.GetTemplate("ReservationConfirmationEn");
		ElsIf SelLanguage = Catalogs.Languages.DE Then
			vTemplate = vResObj.GetTemplate("ReservationConfirmationDe");
		ElsIf SelLanguage = Catalogs.Languages.RU Then
			vTemplate = vResObj.GetTemplate("ReservationConfirmationRu");
		Else
			Raise String(Ref) + " - " + 
			      NStr("ru = 'Не найден шаблон печатной формы подтверждения бронирования для языка " + SelLanguage.Code + "!'; 
			           |de = 'No reservation confirmation print form template found for the " + SelLanguage.Code + " language!'; 
			           |en = 'No reservation confirmation print form template found for the " + SelLanguage.Code + " language!'");
		EndIf;
	Else
		vTemplate = vResObj.GetTemplate("ReservationConfirmationRu");
	EndIf;
	// Load external template if any
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(SelObjectPrintForm);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	EndIf;
		
	// Load pictures
	vLogoIsSet = False;
	vLogo = New Picture;
	If ValueIsFilled(SelReservation.Hotel) Then
		If SelReservation.Hotel.Logo <> Undefined Then
			vLogo = SelReservation.Hotel.Logo.Get();
			If vLogo = Undefined Then
				vLogo = New Picture;
			Else
				vLogoIsSet = True;
			EndIf;
		EndIf;
	EndIf;
	
	// Header
	vHeader = vTemplate.GetArea("TopHeader");
	// Hotel
	vHotelObj = SelReservation.Hotel.GetObject();
	mHotelPrintName = vHotelObj.pmGetHotelPrintName(SelLanguage);
	mHotelPostAddressPresentation = vHotelObj.pmGetHotelPostAddressPresentation(SelLanguage);
	mHotelPhones = TrimAll(SelReservation.Hotel.Phones);
	mHotelFax = TrimAll(SelReservation.Hotel.Fax);
	mHotelEMail = TrimAll(SelReservation.Hotel.EMail);
	// Contact person
	mContactPersonName = TrimR(SelReservation.ContactPerson);
	If IsBlankString(mContactPersonName) And 
	   ValueIsFilled(SelReservation.GuestGroup) And ValueIsFilled(SelReservation.GuestGroup.Client) Then
		mContactPersonName = TrimR(SelReservation.GuestGroup.Client.FullName);
	EndIf;
	// Customer
	mCustomerLegacyName = "";
	If ValueIsFilled(SelReservation.Customer) Then
		mCustomerLegacyName = TrimAll(SelReservation.Customer.LegacyName);
		If IsBlankString(mCustomerLegacyName) Then
			mCustomerLegacyName = TrimAll(SelReservation.Customer.Description);
		EndIf;
	EndIf;
	// Contract
	mContractDescription = "";
	If ValueIsFilled(SelReservation.Contract) Then
		mContractDescription = TrimAll(SelReservation.Contract.Description);
	EndIf;
	// Fax and E-Mail
	mFax = "";
	mEMail = "";
	If Not IsBlankString(SelReservation.Phone) Then
		mFax = TrimAll(SelReservation.Phone);
	EndIf;
	If Not IsBlankString(SelReservation.EMail) Then
		mEMail = TrimAll(SelReservation.EMail);
	EndIf;
	If ValueIsFilled(SelReservation.Customer) Then
		If IsBlankString(mFax) Then
			mFax = TrimAll(SelReservation.Customer.Phone);
		EndIf;
		If IsBlankString(mEMail) Then
			mEMail = TrimAll(SelReservation.Customer.EMail);
		EndIf;
	ElsIf ValueIsFilled(SelReservation.GuestGroup) And ValueIsFilled(SelReservation.GuestGroup.Client) Then
		If IsBlankString(mFax) Then
			mFax = TrimAll(SelReservation.GuestGroup.Client.Phone);
		EndIf;
		If IsBlankString(mEMail) Then
			mEMail = TrimAll(SelReservation.GuestGroup.Client.EMail);
		EndIf;
	EndIf;
	// Confirmation header text
	mFormHeader = cmNStr("en='RESERVATION CONFIRMATION';ru='ПОДТВЕРЖДЕНИЕ БРОНИРОВАНИЯ';de='BESTÄTIGUNG DER RESERVIERUNG'", SelLanguage);
	mFormName = cmNStr("en='Confirmation';ru='подтверждения';de='Bestätigung'", SelLanguage);
	// Check if this reservation is in waiting list
	IsWaitingList = False;
	If ValueIsFilled(SelReservation) And ValueIsFilled(SelReservation.ReservationStatus) And SelReservation.ReservationStatus.IsInWaitingList Then
		IsWaitingList = True;
		mFormHeader = cmNStr("en='RESERVATION REQUEST';ru='ЗАЯВКА';de='ANTRAG'", SelLanguage);
		mFormName = cmNStr("en='Request';ru='заявки';de='des Antrages'", SelLanguage);
	EndIf;
	// Document date
	mDate = Format(SelReservation.Date, "DF='dd.MM.yyyy'");
	// Guest group code
	mGuestGroupCode = TrimAll(SelReservation.GuestGroup.Code);
	vHotelPrefix = Catalogs.Hotels.pmGetPrefix(SelReservation.Hotel);
	If Not IsBlankString(vHotelPrefix) And SelReservation.Hotel.ShowHotelPrefixBeforeGroupCode Then
		mGuestGroupCode = vHotelPrefix + mGuestGroupCode;
	EndIf;
	// Set parameters and put report section
	vHeader.Parameters.mHotelPrintName = mHotelPrintName;
	vHeader.Parameters.mHotelPostAddressPresentation = mHotelPostAddressPresentation;
	vHeader.Parameters.mHotelPhones = mHotelPhones;
	vHeader.Parameters.mHotelFax = mHotelFax;
	vHeader.Parameters.mHotelEMail = mHotelEMail;
	vHeader.Parameters.mContactPersonName = mContactPersonName;
	vHeader.Parameters.mCustomerLegacyName = mCustomerLegacyName;
	vHeader.Parameters.mContractDescription = mContractDescription;
	vHeader.Parameters.mFax = mFax;
	vHeader.Parameters.mEMail = mEMail;
	vHeader.Parameters.mFormHeader = mFormHeader;
	vHeader.Parameters.mFormName = mFormName;
	vHeader.Parameters.mDate = mDate;
	vHeader.Parameters.mGuestGroupCode = mGuestGroupCode;
	vHeader.Parameters.mGuestGroupDescription = "";
	If ValueIsFilled(SelReservation.GuestGroup) Then
		If Not IsBlankString(SelReservation.GuestGroup.ID) Then
			vHeader.Parameters.mGuestGroupDescription = TrimR(SelReservation.GuestGroup.ID);
		Else
			vHeader.Parameters.mGuestGroupDescription = TrimR(SelReservation.GuestGroup.Description);
		EndIf;
	EndIf;
	// Logo
	If vLogoIsSet Then
		vHeader.Drawings.Logo.Print = True;
		vHeader.Drawings.Logo.Picture = vLogo;
	Else
		vHeader.Drawings.Delete(vHeader.Drawings.Logo);
	EndIf;   
	// Print QR code
	Try
		If Find(vParameter, "SHOW_QRCODE") > 0 Then  
			vResUUIDStr = String(SelReservation.UUID());
			vQRCodeControl = vHeader.Drawings.QRCodeControl;
			vQRCodeControl.Picture = cmGetQRCodePicture(vResUUIDStr);
		Else
			vHeader.Drawings.Delete(vHeader.Drawings.QRCodeControl);
		EndIf;
	Except
	EndTry;

	// Put top header		
	vSpreadsheet.Put(vHeader);
	
	// Put company data if necessary
	If ValueIsFilled(SelReservation.Company) And SelReservation.Hotel.PrintCompanyDataInReservationConfirmation Then
		vCompanyHeader = vTemplate.GetArea("CompanyHeader");
		vCompany = SelReservation.Company;
		vCompanyObj = vCompany.GetObject();
		vCompanyTIN = TrimAll(vCompany.TIN);
		vCompanyKPP = TrimAll(vCompany.KPP);
		vCompanyHeader.Parameters.mTIN = cmNStr("en='TIN ';ru='ИНН ';de='INN '", SelLanguage) + vCompanyTIN + ?(IsBlankString(vCompanyKPP), "", "/" + vCompanyKPP);
		vAccount = SelReservation.Company.BankAccount;
		vCompanyName = vCompanyObj.pmGetCompanyPrintName(SelLanguage);
		vCompanyBankAccount = "";
		If vAccount.IsDirectPayments Then
			vCompanyBankAccount = cmNStr("en='Acc. № ';ru='Р/С ';de='Verrechnungskonto '", SelLanguage) + TrimAll(vAccount.AccountNumber);
			vCompanyBankAccount = vCompanyBankAccount + cmNStr("en=' in ';ru=' в ';de=' in '", SelLanguage) + TrimAll(TrimAll(vAccount.BankName) + " " + TrimAll(vAccount.BankCity));
			If Not IsBlankString(vAccount.BankCorrAccountNumber) Then
				vCompanyBankAccount = vCompanyBankAccount + cmNStr("en=', Corr. acc. № ';de=', Corr. acc. № ';ru=', К/С '", SelLanguage) + TrimAll(vAccount.BankCorrAccountNumber);
			EndIf;
			If Not IsBlankString(vAccount.BankBIC) Then
				vCompanyBankAccount = vCompanyBankAccount + cmNStr("en=', BIC ';de=', BIC ';ru=', БИК '", SelLanguage) + TrimAll(vAccount.BankBIC);
			EndIf;
		Else
			vCompanyName = vCompanyName + cmNStr("en=', Acc. № ';de=', Acc. № ';ru=', Р/С '", SelLanguage) + TrimAll(vAccount.AccountNumber);
			vCompanyName = vCompanyName + cmNStr("en=' in ';ru=' в ';de=' in '", SelLanguage) + TrimAll(TrimAll(vAccount.BankName) + " " + TrimAll(vAccount.BankCity));
			If Not IsBlankString(vAccount.BankCorrAccountNumber) Then
				vCompanyName = vCompanyName + cmNStr("en=', Corr. acc. № ';de=', Corr. acc. № ';ru=', К/С '", SelLanguage) + TrimAll(vAccount.BankCorrAccountNumber);
			EndIf;
			If Not IsBlankString(vAccount.BankBIC) Then
				vCompanyName = vCompanyName + cmNStr("en=', BIC ';de=', BIC ';ru=', БИК '", SelLanguage) + TrimAll(vAccount.BankBIC);
			EndIf;
			vCompanyBankAccount = cmNStr("en='Acc. № ';ru='Р/С ';de='Verrechnungskonto '", SelLanguage) + TrimAll(vAccount.CorrBankCorrAccountNumber);
			vCompanyBankAccount = vCompanyBankAccount + cmNStr("en=' in ';ru=' в ';de=' in '", SelLanguage) + TrimAll(TrimAll(vAccount.CorrBankName) + " " + TrimAll(vAccount.CorrBankCity));
		EndIf;
		If Not IsBlankString(vAccount.BankIBAN) Then
			vCompanyBankAccount = vCompanyBankAccount + Chars.LF + cmNStr("en=', IBAN CODE ';de=', IBAN CODE ';ru=', IBAN CODE '", SelLanguage) + TrimAll(vAccount.BankIBAN);
		EndIf;
		If Not IsBlankString(vAccount.BankSWIFTCode) Then
			vCompanyBankAccount = vCompanyBankAccount + Chars.LF + cmNStr("en=', SWIFT CODE ';de=', SWIFT CODE ';ru=', SWIFT CODE '", SelLanguage) + TrimAll(vAccount.BankSWIFTCode);
		EndIf;
		vCompanyHeader.Parameters.mCompanyName = vCompanyName;
		vCompanyHeader.Parameters.mLegalAddress = vCompanyObj.pmGetCompanyLegacyAddressPresentation(SelLanguage);
		vCompanyHeader.Parameters.mBankAccount = vCompanyBankAccount;
		// Put company header
		vSpreadsheet.Put(vCompanyHeader);
	EndIf;
	
	// Put bottom header		
	vBottomHeader = vTemplate.GetArea("BottomHeader");
	vSpreadsheet.Put(vBottomHeader);
	
	// Get reservation currency
	vCurrency = SelReservation.Hotel.BaseCurrency;
	For Each vSrvRow In SelReservation.Services Do
		If vSrvRow.IsRoomRevenue Then
			vCurrency = vSrvRow.FolioCurrency;
			Break;
		EndIf;
	EndDo;
	
	// Total per guest group
	vTotalSum = 0;
	vTotalNumberOfPersons = 0;
	vTotalNumberOfRooms = 0;
	vTotalSumToBePayed = 0;
	vTotalCommissionSum = 0;
	vTotalVATCommissionSum = 0;
	
	vTotalPaidSum = 0;
	vDocsList = Undefined;
	If SelShowConfirmationForCurrentReservationOnly Then
		vDocsList = New ValueList();
		vDocsList.Add(SelReservation);
	EndIf;
	If SelReservations <> Undefined Then
		For Each vSelReservationsItem In SelReservations Do
			If vDocsList = Undefined Then
				vDocsList = New ValueList();
			EndIf;
			If vDocsList.FindByValue(vSelReservationsItem.Value) = Undefined Then
				vDocsList.Add(vSelReservationsItem.Value);
			EndIf;
		EndDo;
	EndIf;
	vGroupPayments = SelReservation.GuestGroup.GetObject().pmGetPaymentsTotals(vDocsList);
	For Each vGroupPaymentsRow In vGroupPayments Do
		vTotalPaidSum = vTotalPaidSum + Round(cmConvertCurrencies(vGroupPaymentsRow.Sum, vGroupPaymentsRow.Currency, , vCurrency, , vGroupPaymentsRow.AccountingDate, SelReservation.Hotel), 2);
	EndDo;
	
	// Print only main room guests
	vPrintMainRoomGuestsOnly = False;
	If Find(vParameter, "PRINT_MAIN_ROOM_GUESTS_ONLY") > 0 Then
		vPrintMainRoomGuestsOnly = True;
	EndIf;
	
	// Guests in group
	vGuestRowArea = vTemplate.GetArea("GuestRow");
	If vShowReservationNumbersInConfirmation Then
		vGuestRowArea = vTemplate.GetArea("GuestRowN");
	EndIf;
	vSrvRowArea = vTemplate.GetArea("SrvRow");
	vAddSrvRowArea = vTemplate.GetArea("AddSrvRow");
	vRowArea = vTemplate.GetArea("Row");
	vReservations = SelReservation.GuestGroup.GetObject().pmGetReservations(True, ?(IsWaitingList, False, True), False, IsWaitingList, ?(SelShowConfirmationForCurrentReservationOnly, SelReservation, Undefined), ?(SelShowConfirmationForCurrentReservationOnly, Undefined, ?(SelReservations = Undefined, Undefined, ?(SelReservations.Count() > 1, SelReservations, Undefined))));
	vSplittedReserv = vReservations.Copy();
	vSplittedReserv.Clear();
	vSplittedReserv.Columns.Add("Quantity", cmGetNumberTypeDescription(19, 7));
	vSplittedReserv.Columns.Add("Amount", cmGetSumTypeDescription());
	vSplittedReserv.Columns.Add("Currency", cmGetCatalogTypeDescription("Currencies"));
	vSplittedReserv.Columns.Add("Service", cmGetCatalogTypeDescription("Services"));
	vSplittedReserv.Columns.Add("Services");
	vChildrenAges = "";
	vChildrenIndex = 0;
	For Each vRes In vReservations Do
		If ValueIsFilled(vRes.Status) And 
		   (Not IsWaitingList And (vRes.Status.IsActive Or vRes.Status.IsCheckIn Or vRes.Status.IsPreliminary) Or IsWaitingList) Then
			vCurRes = vRes.Reservation;
			vCurResObj = vCurRes.GetObject();
			// Children ages
			If vCurRes.GuestAge > 0 Then
				vChildrenIndex = vChildrenIndex + 1;
				If vChildrenIndex > 1 Then
					vChildrenAges = vChildrenAges + Chars.LF;
				EndIf;
				vChildrenAges = vChildrenAges + cmNStr("en='Child '; ru='Ребёнок '; de='Kind '", SelLanguage) + Format(vChildrenIndex, "NFD=0; NG=") + cmNstr("en=': Age: '; ru=': Возраст: '; de=': Alter: '", SelLanguage) + Format(vCurRes.GuestAge, "NFD=0; NG=");
			EndIf;
			// Fill parameters
			If vPrintMainRoomGuestsOnly And Not ValueIsFilled(vCurRes.AccommodationTemplate) Then
				Continue;
			Else
				vGuestRowArea.Parameters.mGuestName = cmGetFullPersonName(vCurRes.Guest);
				// Fill RoomRateDescription
				vGuestRowStruct = New Structure("mRoomRateDescription", "");          
				vGuestRowStruct.mRoomRateDescription = vCurRes.RoomRate;               
				FillPropertyValues(vGuestRowArea.Parameters, vGuestRowStruct);          
				
				If vShowReservationNumbersInConfirmation Then
					vGuestRowArea.Parameters.mDocNumber = cmNStr("en='Res. #: ';ru='Бронь №: ';de='Reservierung Nr.: '", SelLanguage) + cmGetDocumentNumberPresentation(vCurRes.Number);
				EndIf;
				vSpreadsheet.Put(vGuestRowArea);
			EndIf;
			If vPrintMainRoomGuestsOnly Then
				vResNumberOfPersons = vCurRes.NumberOfAdults + vCurRes.NumberOfTeenagers + vCurRes.NumberOfChildren + vCurRes.NumberOfInfants;
			Else
				vResNumberOfPersons = vCurRes.NumberOfPersons;
			EndIf;
			vTotalNumberOfPersons = vTotalNumberOfPersons + vResNumberOfPersons;
			// Get reservation periods
			vAccPeriods = vCurResObj.pmGetAccommodationPeriods(False);
			// Group by current reservation services
			If Find(vParameter, "JOIN_IN_PRICE_SERVICES_TO_MAIN_ROOM_GUEST") > 0 And vCurRes.RoomQuantity = 1 And ValueIsFilled(vCurRes.AccommodationType) And 
			  (vCurRes.AccommodationType.Type = Enums.AccomodationTypes.Room Or vCurRes.AccommodationType.Type = Enums.AccomodationTypes.Together Or vCurRes.AccommodationType.Type = Enums.AccomodationTypes.AdditionalBed) Then
				vServices = cmGetReservationRoomServices(vCurRes);
			Else
				vServices = cmGetReservationServices(vCurRes);
			EndIf;
			// Filter services by customer
			If SelServicesFilter > 0 Then
				i = 0;
				While i < vServices.Count() Do
					vSrvRow = vServices.Get(i);
					If SelServicesFilter = 1 Then
						If ValueIsFilled(vSrvRow.Folio.Customer) Then
							vServices.Delete(i);
							Continue;
						EndIf;
					ElsIf SelServicesFilter = 2 Then
						If Not ValueIsFilled(vSrvRow.Folio.Customer) Then
							vServices.Delete(i);
							Continue;
						EndIf;
					EndIf;
					i = i + 1;
				EndDo;
			EndIf;
			// Filter services by service group
			If ValueIsFilled(SelServiceGroup) Then
				i = 0;
				While i < vServices.Count() Do
					vSrvRow = vServices.Get(i);
					If Not cmIsServiceInServiceGroup(vSrvRow.Service, SelServiceGroup) Then
						vServices.Delete(i);
						Continue;
					EndIf;
					i = i + 1;
				EndDo;
			EndIf;
			// Fill commission totals
			vTotalCommissionSum = vTotalCommissionSum + vServices.Total("CommissionSum");
			vTotalVATCommissionSum = vTotalVATCommissionSum + vServices.Total("VATCommissionSum");
			// Process services grouping parameters
			If Find(vParameter, "DETAILED") = 0 Then
				// Find accommodation service
				vAccommodationService = Undefined;	
				For Each vSrvRow In vServices Do
					If vSrvRow.IsRoomRevenue And Not vSrvRow.RoomRevenueAmountsOnly Then
						vAccommodationService = vSrvRow.Service;
						Break;
					EndIf;
				EndDo;
				// Change accounting dates for breakfast
				If Find(vParameter, "DETAILED") = 0 Then
					For Each vSrvRow In vServices Do
						If Not vSrvRow.IsManual And vSrvRow.IsInPrice And ValueIsFilled(vSrvRow.Service.QuantityCalculationRule) Then
							vAccountingDateMove = cmGetAccountingDateMove(vSrvRow.Service.QuantityCalculationRule, vSrvRow.IsManual, ThisObject, False);
							If vAccountingDateMove < 0 Then
								vSrvRow.AccountingDate = vSrvRow.AccountingDate + vAccountingDateMove*(24*3600);
							EndIf;
						EndIf;
					EndDo;
				EndIf;
				// Join services according to service parameters
				If Find(vParameter, "DETAILED") = 0 Then
					// Try to replace accommodation service to the one that should be used for printing
					vAccountingDate = '00010101';
					vFirstRoomRateService = Undefined;
					vFirstRoomRateServiceIsFound = False;
					For Each vSrvRow In vServices Do
						vSrvRowService = vSrvRow.Service;
						If ValueIsFilled(vSrvRowService) Then
							If vAccountingDate <> BegOfDay(vSrvRow.AccountingDate) Then
								vAccountingDate = BegOfDay(vSrvRow.AccountingDate);
								vFirstRoomRateService = Undefined;
								vFirstRoomRateServiceIsFound = False;
							EndIf;
							If vSrvRowService.IsRoomRevenue And vSrvRowService.IsInPrice And Not vSrvRowService.RoomRevenueAmountsOnly Then
								If ValueIsFilled(vSrvRowService.HideIntoServiceOnPrint) Then
									vSrvRow.Service = vSrvRowService.HideIntoServiceOnPrint;
								EndIf;
								If Not vFirstRoomRateServiceIsFound Then
									vFirstRoomRateService = vSrvRowService;
									vFirstRoomRateServiceIsFound = True;
								Else
									If vFirstRoomRateService <> vSrvRowService And ValueIsFilled(vSrvRowService.HideIntoServiceOnPrint) Then
										vSrvRow.Quantity = 0;
									EndIf;
								EndIf;
							ElsIf vSrvRowService.DoNotGroupIntoRoomRateOnPrint And ValueIsFilled(vSrvRowService.HideIntoServiceOnPrint) Then
								vSrvRow.Service = vSrvRowService.HideIntoServiceOnPrint;
							EndIf;
						EndIf;
					EndDo;
					// Try to merge other services to the accommodation service
					i = 0;
					While i < vServices.Count() Do
						vSrvRow = vServices.Get(i);
						vSrvRowService = vSrvRow.Service;
						If ValueIsFilled(vSrvRowService) And ValueIsFilled(vSrvRowService.HideIntoServiceOnPrint) Then
							If Not vSrvRowService.DoNotGroupIntoRoomRateOnPrint Then
								// Try to find service to hide current one to
								vHideToServices = vServices.FindRows(New Structure("Service, AccountingDate, FolioCurrency", vSrvRowService.HideIntoServiceOnPrint, vSrvRow.AccountingDate, vSrvRow.FolioCurrency));
								If vHideToServices.Count() = 0 Then
									vHideToServices = vServices.FindRows(New Structure("Service, AccountingDate, FolioCurrency", vSrvRowService.HideIntoServiceOnPrint, vSrvRow.AccountingDate - 24*3600, vSrvRow.FolioCurrency));
								EndIf;
								If vHideToServices.Count() > 0 Then
									vSrv2Hide2 = vHideToServices.Get(0);
									vSrv2Hide2.Sum = vSrv2Hide2.Sum + vSrvRow.Sum;
									vSrv2Hide2.VATSum = vSrv2Hide2.VATSum + vSrvRow.VATSum;
									vSrv2Hide2.DiscountSum = vSrv2Hide2.DiscountSum + vSrvRow.DiscountSum;
									vSrv2Hide2.VATDiscountSum = vSrv2Hide2.VATDiscountSum + vSrvRow.VATDiscountSum;
									vSrv2Hide2.CommissionSum = vSrv2Hide2.CommissionSum + vSrvRow.CommissionSum;
									vSrv2Hide2.VATCommissionSum = vSrv2Hide2.VATCommissionSum + vSrvRow.VATCommissionSum;
									vSrv2Hide2.Price = cmRecalculatePrice(vSrv2Hide2.Sum, vSrv2Hide2.Quantity);
									// Delete current service
									vServices.Delete(i);
									Continue;
								EndIf;
							EndIf;
						EndIf;
						i = i + 1;
					EndDo;
				EndIf;
				// Change services
				For Each vSrvRow In vServices Do
					If Find(vParameter, "ALL") > 0 Then
						If Not vSrvRow.IsRoomRevenue Or vSrvRow.RoomRevenueAmountsOnly Then
							vSrvRow.Service = ?(ValueIsFilled(vAccommodationService), vAccommodationService, vSrvRow.Service);
							vSrvRow.Quantity = ?(ValueIsFilled(vAccommodationService), 0, vSrvRow.Quantity);
							vSrvRow.Price = 0;
						EndIf;
					Else
						// Reset "is in price" flag if necessary
						If Find(vParameter, "DETAILED") = 0 Then
							If ValueIsFilled(vSrvRow.Service) And vSrvRow.Service.DoNotGroupIntoRoomRateOnPrint Then
								vSrvRow.IsInPrice = False;
							EndIf;
							If Not vSrvRow.IsRoomRevenue And vSrvRow.IsInPrice Then
								vSrvRow.IsRoomRevenue = True;
								vSrvRow.Service = ?(ValueIsFilled(vAccommodationService), vAccommodationService, vSrvRow.Service);
								vSrvRow.Quantity = ?(ValueIsFilled(vAccommodationService), 0, vSrvRow.Quantity);
								vSrvRow.Price = 0;
							ElsIf vSrvRow.IsRoomRevenue And vSrvRow.IsInPrice Then
								If vSrvRow.RoomRevenueAmountsOnly Then
									vSrvRow.Quantity = 0;
								EndIf;
								vSrvRow.Service = ?(ValueIsFilled(vAccommodationService), vAccommodationService, vSrvRow.Service);
								vSrvRow.Price = 0;
								If vSrvRow.IsSplit Then
									vSrvRow.Quantity = 0;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
				EndDo;
				// Group by services
				If Find(vParameter, "DETAILED") = 0 Then
					vServices.GroupBy("AccountingDate, Service, FolioCurrency, IsRoomRevenue, RoomRevenueAmountsOnly, IsInPrice", "Sum, VATSum, DiscountSum, VATDiscountSum, Quantity, Price, GuestsCheckedIn, GuestDays, CommissionSum, VATCommissionSum");
				EndIf;
				vServices.GroupBy("AccountingDate, Service, Price, FolioCurrency, IsRoomRevenue, RoomRevenueAmountsOnly, IsInPrice", "Sum, VATSum, DiscountSum, VATDiscountSum, Quantity, GuestsCheckedIn, GuestDays, CommissionSum, VATCommissionSum");
				// Recalculate price and sum for all services
				For Each vSrvRow In vServices Do
					vSrvRow.Price = cmRecalculatePrice(vSrvRow.Sum, vSrvRow.Quantity);
				EndDo;
			EndIf;
			// Split reservation period
			vSplittedReserv.Clear();
			vSRRow = vSplittedReserv.Add();
			FillPropertyValues(vSRRow, vRes);
			vAccPrice = Undefined;
			vSavCheckOutDate = Undefined;
			For Each vSrvRow In vServices Do
				If ValueIsFilled(vSrvRow.Service) And 
				   vSrvRow.IsRoomRevenue And vSrvRow.IsInPrice And Not vSrvRow.RoomRevenueAmountsOnly Then
					For Each vAccPeriodsRow In vAccPeriods Do
						If ValueIsFilled(vSrvRow.AccountingDate) And vAccPeriodsRow.CheckInDate <= vSrvRow.AccountingDate And vAccPeriodsRow.CheckOutDate > vSrvRow.AccountingDate Then
							vSRRow.Room = vAccPeriodsRow.Room;
							vSRRow.RoomType = vAccPeriodsRow.RoomType;
							vSRRow.RoomRate = vAccPeriodsRow.RoomRate;
							vSRRow.AccommodationType = vAccPeriodsRow.AccommodationType;
							Break;
						EndIf;
					EndDo;
					If vAccPrice = Undefined Then
					   vAccPrice = vSrvRow.Price;
					Else
						If vAccPrice <> vSrvRow.Price Then
							vAccPrice = vSrvRow.Price;
							vSavCheckOutDate = vSRRow.CheckOutDate;
							If ValueIsFilled(vCurRes.RoomRate) And vCurRes.RoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour Then
								vSRRow.CheckOutDate = BegOfDay(vSrvRow.AccountingDate) + (vCurRes.RoomRate.ReferenceHour - BegOfDay(vCurRes.RoomRate.ReferenceHour));
							Else
								vSRRow.CheckOutDate = BegOfDay(vSrvRow.AccountingDate) + (vSRRow.CheckOutDate - BegOfDay(vSRRow.CheckOutDate));
							EndIf;
							vSRRow.Duration = cmCalculateDuration(vCurRes.RoomRate, vSRRow.CheckInDate, vSRRow.CheckOutDate);
							vNewSRRow = vSplittedReserv.Add();
							FillPropertyValues(vNewSRRow, vSRRow);
							vNewSRRow.CheckInDate = vSRRow.CheckOutDate;
							vNewSRRow.CheckOutDate = vSavCheckOutDate;
							vNewSRRow.Duration = cmCalculateDuration(vCurRes.RoomRate, vNewSRRow.CheckInDate, vNewSRRow.CheckOutDate);
							vNewSRRow.RoomQuantity = 0;
							vNewSRRow.NumberOfPersons = 0;
							vNewSRRow.Quantity = 0;
							vNewSRRow.Amount = 0;
							vNewSRRow.Currency = Catalogs.Currencies.EmptyRef();
							vNewSRRow.Service = Catalogs.Services.EmptyRef();
							vNewSRRow.Services = Undefined;
							vSRRow = vNewSRRow;
						EndIf;
					EndIf;
				EndIf;
				If vSRRow.Services = Undefined Then
					vSRRow.Services = vServices.Copy();
					vSRRow.Services.Clear();
				EndIf;
				If vSrvRow.IsRoomRevenue And vSrvRow.IsInPrice And Not vSrvRow.RoomRevenueAmountsOnly Then
					If Find(vParameter, "DETAILED") = 0 Then
						If vSrvRow.IsInPrice Then
							vSRRow.Amount = vSRRow.Amount + vSrvRow.Sum - vSrvRow.DiscountSum;
						ElsIf Find(vParameter, "ALL") > 0 Then
							vSRRow.Amount = vSRRow.Amount + vSrvRow.Sum - vSrvRow.DiscountSum;
						EndIf;
					Else
						If vSrvRow.IsRoomRevenue And vSrvRow.IsInPrice And Not vSrvRow.RoomRevenueAmountsOnly Then
							vSRRow.Amount = vSRRow.Amount + vSrvRow.Sum - vSrvRow.DiscountSum;
						EndIf;
					EndIf;
					vSRRow.Quantity = vSRRow.Quantity + vSrvRow.Quantity;
					vSRRow.Currency = vSrvRow.FolioCurrency;
					vSRRow.Service = vSrvRow.Service;
				Else
					If vSrvRow.Sum <> 0 Then
						vSRRowServicesRow = vSRRow.Services.Add();
						FillPropertyValues(vSRRowServicesRow, vSrvRow);
					EndIf;
				EndIf;					
			EndDo;
			// Print periods in cycle
			vCurService = Undefined;
			For Each vSRRow In vSplittedReserv Do
				If ValueIsFilled(vSRRow.Service) And vCurService <> vSRRow.Service Then
					vCurService = vSRRow.Service;
					vSrvRowArea.Parameters.mServiceDescription = vSRRow.Service.GetObject().pmGetServiceDescription(SelLanguage);
					If vSRRow.CheckInDate = vSRRow.CheckOutDate And vSRRow.Amount = 0 Then
						Continue;
					EndIf;
				EndIf;
				If ValueIsFilled(vSRRow.RoomRate) And vSRRow.RoomRate.PeriodInHours = 24 And  
				   vSRRow.RoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour And 
				   ((vSRRow.RoomRate.DefaultCheckInTime - BegOfDay(vSRRow.RoomRate.DefaultCheckInTime)) = (cm0SecondShift(vSRRow.CheckInDate) - BegOfDay(vSRRow.CheckInDate)) 
				    Or Not ValueIsFilled(vSRRow.RoomRate.DefaultCheckInTime) 
					Or (vSRRow.RoomRate.ReferenceHour - BegOfDay(vSRRow.RoomRate.ReferenceHour)) = (cm0SecondShift(vSRRow.CheckInDate) - BegOfDay(vSRRow.CheckInDate))) And 
				   (vSRRow.RoomRate.ReferenceHour - BegOfDay(vSRRow.RoomRate.ReferenceHour)) = (cm0SecondShift(vSRRow.CheckOutDate) - BegOfDay(vSRRow.CheckOutDate)) Then
					vRowArea.Parameters.mPeriod = Format(vSRRow.CheckInDate, "DF='dd.MM.yy'") + " - " +
					                          Format(vSRRow.CheckOutDate, "DF='dd.MM.yy'");
				Else
					vRowArea.Parameters.mPeriod = Format(vSRRow.CheckInDate, "DF='dd.MM.yy HH:mm'") + " - " +
					                          Format(vSRRow.CheckOutDate, "DF='dd.MM.yy HH:mm'");
				EndIf;
				If ValueIsFilled(vSRRow.AccommodationType) Then
					If vSRRow.AccommodationType.Type = Enums.AccomodationTypes.Beds Then
						If vSRRow.NumberOfBedsPerRoom <> 0 Then
							vNumberOfRooms = vSRRow.NumberOfBeds/vSRRow.NumberOfBedsPerRoom;
							If vNumberOfRooms = 1 Then
								vRowArea.Parameters.mQuantity = "1";
							ElsIf vNumberOfRooms = 1/2 Then
								vRowArea.Parameters.mQuantity = "1/2";
							ElsIf vNumberOfRooms = 1/3 Then 
								vRowArea.Parameters.mQuantity = "1/3";
							ElsIf vNumberOfRooms = 1/4 Then 
								vRowArea.Parameters.mQuantity = "1/4";
							ElsIf vNumberOfRooms = 1/5 Then 
								vRowArea.Parameters.mQuantity = "1/5";
							ElsIf vNumberOfRooms = 1/6 Then 
								vRowArea.Parameters.mQuantity = "1/6";
							ElsIf vNumberOfRooms = 1/7 Then 
								vRowArea.Parameters.mQuantity = "1/7";
							ElsIf vNumberOfRooms = 1/8 Then 
								vRowArea.Parameters.mQuantity = "1/8";
							ElsIf vNumberOfRooms = 1/9 Then 
								vRowArea.Parameters.mQuantity = "1/9";
							Else
								vRowArea.Parameters.mQuantity = Format(vNumberOfRooms, "ND=6; NFD=3");
							EndIf;
							vTotalNumberOfRooms = vTotalNumberOfRooms + vNumberOfRooms;
						Else
							vRowArea.Parameters.mQuantity = "";
						EndIf;
					ElsIf vSRRow.AccommodationType.Type = Enums.AccomodationTypes.Room Then
						vRowArea.Parameters.mQuantity = Format(vSRRow.RoomQuantity, "ND=6");
						vTotalNumberOfRooms = vTotalNumberOfRooms + vSRRow.RoomQuantity;
					Else
						vRowArea.Parameters.mQuantity = "";
					EndIf;
				Else
					vRowArea.Parameters.mQuantity = "";
				EndIf;
				vRowArea.Parameters.mNumberOfPersons = Format(vResNumberOfPersons, "ND=6");
				vRoomTypeToPrint = vSRRow.RoomType;
				If ValueIsFilled(vRoomTypeToPrint) And ValueIsFilled(vCurRes.RoomTypeUpgrade) And vCurRes.RoomTypeUpgrade.BaseRoomType = vRoomTypeToPrint Then
					vRoomTypeToPrint = vCurRes.RoomTypeUpgrade;
				EndIf;
				If ValueIsFilled(vSRRow.Room) And Find(vParameter, "NO_ROOM") = 0 Then
					vRowArea.Parameters.mRoomType = TrimAll(vSRRow.Room.Description) + ?(ValueIsFilled(vRoomTypeToPrint), " - " + vRoomTypeToPrint.GetObject().pmGetRoomTypeDescription(SelLanguage), "");
				Else
					vRowArea.Parameters.mRoomType = ?(ValueIsFilled(vRoomTypeToPrint), vRoomTypeToPrint.GetObject().pmGetRoomTypeDescription(SelLanguage), "");
				EndIf;
				If ValueIsFilled(vSRRow.AccommodationType) Then
					vRowArea.Parameters.mRoomType = vRowArea.Parameters.mRoomType + ", " + vSRRow.AccommodationType.GetObject().pmGetAccommodationTypeDescription(SelLanguage);
				EndIf;
				// Get accommodation prices for all day types of room rate
				If vSRRow.Quantity = 0 Then
					mRoomRate = cmFormatSum(vSRRow.Amount, vSRRow.Currency);
				Else
					mRoomRate = cmFormatSum(Round(vSRRow.Amount/vSRRow.Quantity, 2), vSRRow.Currency);
				EndIf;
				vRowArea.Parameters.mRoomRate = mRoomRate;
				// Number of days
				vRowArea.Parameters.mDays = Format(vSRRow.Duration, "ND=6");
				// Amount
				vRowArea.Parameters.mAmount = cmFormatSum(vSRRow.Amount, vSRRow.Currency);
				// Fill totals
				vTotalSum = vTotalSum + vSRRow.Amount;

				// Put row
				vSpreadsheet.Put(vRowArea);
			EndDo;
			// Put other services
			For Each vSRRow In vSplittedReserv Do
				If vSRRow.Services <> Undefined Then
					For Each vSRRowServicesRow In vSRRow.Services Do
						If ValueIsFilled(vSRRowServicesRow.Service) And vSRRowServicesRow.Service <> vSRRow.Service Then
							vAddSrvRowArea.Parameters.mServiceDescription = vSRRowServicesRow.Service.GetObject().pmGetServiceDescription(SelLanguage) + " - " + Format(vSRRowServicesRow.AccountingDate, "DF='dd.MM.yy'");
							// Try to add remarks and resource
							vServicesRows = vCurResObj.Services.FindRows(New Structure("AccountingDate, Service, FolioCurrency, IsRoomRevenue, RoomRevenueAmountsOnly, IsInPrice", vSRRowServicesRow.AccountingDate, vSRRowServicesRow.Service, vSRRowServicesRow.FolioCurrency, vSRRowServicesRow.IsRoomRevenue, vSRRowServicesRow.RoomRevenueAmountsOnly, vSRRowServicesRow.IsInPrice));
							If vServicesRows.Count() = 1 Then
								vServicesRow = vServicesRows.Get(0);
								If ValueIsFilled(vServicesRow.ServiceResource) And ValueIsFilled(vServicesRow.TimeFrom) And ValueIsFilled(vServicesRow.TimeTo) Then
									vAddSrvRowArea.Parameters.mServiceDescription = vAddSrvRowArea.Parameters.mServiceDescription + Chars.LF + Chars.Tab + 
									TrimAll(?(TypeOf(vServicesRow.ServiceResource) = Type("String"), TrimAll(vServicesRow.ServiceResource), vServicesRow.ServiceResource.GetObject().pmGetResourceDescription(SelLanguage)) + " " + 
									Format(vServicesRow.TimeFrom, "DF=HH:mm") + " - " + Format(vServicesRow.TimeTo, "DF=HH:mm") + Chars.LF + Chars.Tab + Chars.Tab + 
									StrReplace(TrimAll(vServicesRow.Remarks), Chars.LF, Chars.LF + Chars.Tab + Chars.Tab));
								EndIf;
							EndIf;
							// Amount
							vAddSrvRowArea.Parameters.mAmount = cmFormatSum(vSRRowServicesRow.Sum - vSRRowServicesRow.DiscountSum, vSRRowServicesRow.FolioCurrency);
							// Put service row
							vSpreadsheet.Put(vAddSrvRowArea);
							
							// Fill totals
							vTotalSum = vTotalSum + vSRRowServicesRow.Sum - vSRRowServicesRow.DiscountSum;
						EndIf;
					EndDo;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	// Create table of charging rules
	vChargingRules = SelReservation.ChargingRules.Unload();
	If Not SelReservation.IgnoreGroupChargingRules Then
		cmAddGuestGroupChargingRules(vChargingRules, SelReservation.GuestGroup);
	EndIf;
	
	// Put group totals
	If SelReservation.Customer = SelReservation.Agent And ValueIsFilled(SelReservation.Agent) And vTotalCommissionSum <> 0 And 
	   cmCustomerIsPayer(vChargingRules, SelReservation.Customer, SelReservation.Contract, SelReservation.GuestGroup, SelReservation.IgnoreGroupChargingRules) And
	   Not Find(vParameter, "NO_COMMISSION") > 0 Then
		vTotalsRow = vTemplate.GetArea("TotalsRowCommission" + ?(Find(vParameter, "SHOW_TOTAL_PAID_AMOUNT") > 0, "Advances", ""));
		vTotalsRow.Parameters.mTotalNumberOfPersons = Format(vTotalNumberOfPersons, "ND=6");
		vTotalsRow.Parameters.mTotalQuantity = Format(vTotalNumberOfRooms, "ND=6");
		vTotalsRow.Parameters.mTotalAmount = cmFormatSum(vTotalSum, vCurrency);
		vTotalsRow.Parameters.mAgentCommission = "" + GetAgentCommissionDescription(SelReservation, SelLanguage);
		vTotalsRow.Parameters.mTotalCommissionSum = cmFormatSum(vTotalCommissionSum, vCurrency);
		If Find(vParameter, "SHOW_TOTAL_PAID_AMOUNT") > 0 Then
			vTotalsRow.Parameters.mTotalPaidSum = cmFormatSum(vTotalPaidSum, vCurrency);
			vTotalsRow.Parameters.mSumToBePaid = cmFormatSum(vTotalSum - vTotalCommissionSum - vTotalPaidSum, vCurrency);
		Else
			vTotalsRow.Parameters.mSumToBePaid = cmFormatSum(vTotalSum - vTotalCommissionSum, vCurrency);
		EndIf;
		vSpreadsheet.Put(vTotalsRow);
	Else
		vTotalsRow = vTemplate.GetArea("TotalsRow" + ?(Find(vParameter, "SHOW_TOTAL_PAID_AMOUNT") > 0, "Advances", ""));
		vTotalsRow.Parameters.mTotalNumberOfPersons = Format(vTotalNumberOfPersons, "ND=6");
		vTotalsRow.Parameters.mTotalQuantity = Format(vTotalNumberOfRooms, "ND=6");
		If Find(vParameter, "SHOW_TOTAL_PAID_AMOUNT") > 0 Then
			vTotalsRow.Parameters.mTotalAmount = cmFormatSum(vTotalSum, vCurrency);
			vTotalsRow.Parameters.mTotalPaidSum = cmFormatSum(vTotalPaidSum, vCurrency);
			vTotalsRow.Parameters.mSumToBePaid = cmFormatSum(vTotalSum - vTotalPaidSum, vCurrency);
		Else
			vTotalsRow.Parameters.mTotalAmount = cmFormatSum(vTotalSum, vCurrency);
		EndIf;
		vSpreadsheet.Put(vTotalsRow);
	EndIf;
	
	// Confirmation reply
	vConfRepl = vTemplate.GetArea("ConfirmationReply");
	vConfirmationReply = cmNStr("en='<Payment method was not set!>';ru='<Способ оплаты не установлен!>';de='<Zahlungsmethode nicht festgestellt!>'", SelLanguage);
	If vChargingRules.Count() > 0 Then
		// Get accommodation service charging rule
		vAccFolio = Undefined;
		For Each vSrvRow In SelReservation.Services Do
			If vSrvRow.IsRoomRevenue And vSrvRow.IsInPrice Then
				vAccFolio = vSrvRow.Folio;
				Break;
			EndIf;
		EndDo;
		vCRRow = Undefined;
		If Not ValueIsFilled(vAccFolio) Then				
			vCRRow = vChargingRules.Get(0);
			If Not ValueIsFilled(vCRRow.Owner) Then
				vCRRow = vChargingRules.Get(vChargingRules.Count()-1);
			EndIf;
			If vCRRow <> Undefined Then
				vAccFolio = vCRRow.ChargingFolio;
			EndIf;
		Else
			For Each vWrkCRRow In vChargingRules Do
				If vAccFolio = vWrkCRRow.ChargingFolio Then
					vCRRow = vWrkCRRow;
					Break;
				EndIf;
			EndDo;
		EndIf;
		If vCRRow <> Undefined And ValueIsFilled(vCRRow.ChargingRule) And ValueIsFilled(vAccFolio) Then
			If ValueIsFilled(vAccFolio.PaymentMethod) Then
				vPaymentMethodObj = vAccFolio.PaymentMethod.GetObject();
				If vCRRow.ChargingRule <> Enums.ChargingRuleTypes.Any Then
					vChargingRuleDescription = cmGetChargingRuleDescription(vCRRow, SelLanguage);
					vConfirmationReply = vPaymentMethodObj.pmGetPaymentMethodDescription(SelLanguage) + ?(IsBlankString(vChargingRuleDescription), "", " - " + vChargingRuleDescription);
				Else
					vConfirmationReply = vPaymentMethodObj.pmGetPaymentMethodDescription(SelLanguage);
				EndIf;
				For Each vGroupPaymentsRow In vGroupPayments Do
					If vGroupPayments.IndexOf(vGroupPaymentsRow) = 0 Then
						vConfirmationReply = vConfirmationReply + Chars.LF + cmNStr("en='Payments are';ru='Платежи';de='Zahlungen'", SelLanguage);
					EndIf;
					vConfirmationReply = vConfirmationReply + Chars.LF + Format(vGroupPaymentsRow.AccountingDate, "DF=dd.MM.yyyy") + " - " + cmFormatSum(vGroupPaymentsRow.Sum, vGroupPaymentsRow.Currency);
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(SelReservation.DiscountType) Then
		vConfirmationReply = vConfirmationReply + ?(IsBlankString(vConfirmationReply), "", Chars.LF) + TrimAll(SelReservation.DiscountType);
	EndIf;
	If Not IsBlankString(SelReservation.DiscountConfirmationText) Then
		vConfirmationReply = vConfirmationReply + ?(IsBlankString(vConfirmationReply), "", Chars.LF) + TrimAll(SelReservation.DiscountConfirmationText);
	EndIf;                                                                                                                                                                  
	If ValueIsFilled(SelReservation.ServicePackage) And SelReservation.ServicePackage.IsMealBoardTerm Then  
		vSPDesc = Catalogs.ServicePackages.GetServicePackageDescription(SelReservation.ServicePackage, SelLanguage);
		vConfirmationReply = vConfirmationReply + ?(IsBlankString(vConfirmationReply), "", Chars.LF) + cmNStr("en='Terms: '; ru='Питание: '; de='Terms: '", SelLanguage) + vSPDesc;
	EndIf;
	If Find(vParameter, "SHOW_CHILDREN_AGES") > 0 And Not IsBlankString(vChildrenAges) Then
		vConfirmationReply = vConfirmationReply + Chars.LF + vChildrenAges;
	EndIf;
	If Find(vParameter, "SHOW_AGENT_COMMISSION_PERCENT") > 0 Then
		If ValueIsFilled(SelReservation.AgentCommissionType) And SelReservation.AgentCommission > 0 Then
			vConfirmationReply = vConfirmationReply + Chars.Tab + Chars.Tab + Chars.Tab + Chars.Tab + cmNStr("en='Agent commission ';ru='Агентское вознаграждение ';de='Vertreterentlohnung '", SelLanguage) + SelReservation.AgentCommission + "%";
		EndIf;
	EndIf;
	If ValueIsFilled(SelReservation.GuestGroup) And Not IsBlankString(SelReservation.GuestGroup.Remarks) Then
		If Not IsBlankString(vConfirmationReply) Then
			vConfirmationReply = vConfirmationReply + Chars.LF + Chars.LF + TrimAll(SelReservation.GuestGroup.Remarks);
		Else
			vConfirmationReply = TrimAll(SelReservation.GuestGroup.Remarks);
		EndIf;
	EndIf;
	If Not IsBlankString(SelReservation.ConfirmationReply) Then
		If Not IsBlankString(vConfirmationReply) Then
			vConfirmationReply = vConfirmationReply + Chars.LF + Chars.LF + TrimAll(SelReservation.ConfirmationReply);
		Else
			vConfirmationReply = TrimAll(SelReservation.ConfirmationReply);
		EndIf;
	EndIf;
	vConfRepl.Parameters.mConfirmationReply = vConfirmationReply;
	vSpreadsheet.Put(vConfRepl);
	
	// Footer
	vFooter = vTemplate.GetArea("Footer");
	If ValueIsFilled(SelReservation.Company) And SelReservation.Company.DoNotPrintVAT Then
		vFooter.Parameters.mVATPresentation = "";
	Else
		vFooter.Parameters.mVATPresentation = cmNStr("ru='* В цену входит НДС';en='* All room rates include VAT (if other is not specified)';de='* All room rates include VAT (if other is not specified)'", SelLanguage);
		If ValueIsFilled(SelReservation) Then
			If ValueIsFilled(SelReservation.Company) Then
				If ValueIsFilled(SelReservation.Company.VATRate) Then
					If SelReservation.Company.VATRate.NoVAT Then
						vFooter.Parameters.mVATPresentation = cmNStr("ru='* Без НДС';en='* No VAT (if other is not specified)';de='* No VAT (if other is not specified)'", SelLanguage);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	vFooter.Parameters.mReservationConditions = "";
	vFeeTerms = SelReservation.FeeTerms;
	If Not ValueIsFilled(vFeeTerms) And ValueIsFilled(SelReservation.RoomRate) And ValueIsFilled(SelReservation.RoomRate.FeeTerms) Then
		vFeeTerms = SelReservation.RoomRate.FeeTerms;
	EndIf;
	If Not IsWaitingList Then
		If ValueIsFilled(SelReservation.RoomRate) And Not IsBlankString(SelReservation.RoomRate.ReservationConditions) Then
			vFooter.Parameters.mReservationConditions = vFooter.Parameters.mReservationConditions + cmNStr(SelReservation.RoomRate.ReservationConditions, SelLanguage);
		ElsIf Not IsBlankString(SelReservation.Hotel.ReservationConditions) Then
			vFooter.Parameters.mReservationConditions = vFooter.Parameters.mReservationConditions + cmNStr(SelReservation.Hotel.ReservationConditions, SelLanguage);
		Else
			vFooter.Parameters.mReservationConditions = vFooter.Parameters.mReservationConditions + 
			cmNStr(
			"ru='* Для аннулирования брони известите нас до 18:00 дня предшествующего дате заезда
			|
			|* Возможность поселения ранее указанного времени должна быть согласована с отделом бронирования'; 
			|de='* To cancel the booking, you may notify us by 6 p.m. ONE DAY PRIOR THE DATE OF ARRIVAL';
			|en='* To cancel the booking, you may notify us by 6 p.m. ONE DAY PRIOR THE DATE OF ARRIVAL'", SelLanguage);
		EndIf;
		If ValueIsFilled(SelReservation.ReservationStatus) And Not IsBlankString(SelReservation.ReservationStatus.ReservationConditions) Then
			vFooter.Parameters.mReservationConditions = vFooter.Parameters.mReservationConditions + Chars.LF + cmNStr(SelReservation.ReservationStatus.ReservationConditions, SelLanguage);
		EndIf;
		If ValueIsFilled(vFeeTerms) And Not IsBlankString(vFeeTerms.ConfirmationText) Then
			If Not vFeeTerms.ApplyConfirmationTextToGuaranteedReservationsOnly Or 
			   vFeeTerms.ApplyConfirmationTextToGuaranteedReservationsOnly And ValueIsFilled(SelReservation.ReservationStatus) And SelReservation.ReservationStatus.IsGuaranteed Then
				vFooter.Parameters.mReservationConditions = vFooter.Parameters.mReservationConditions + Chars.LF + Chars.LF + cmNStr(vFeeTerms.ConfirmationText, SelLanguage);
			EndIf;
		EndIf;
	Else
		vFooter.Parameters.mReservationConditions = vFooter.Parameters.mReservationConditions + 
		cmNStr(
		"ru='* Эта форма НЕ ЯВЛЯЕТСЯ подтверждением брони. 
		|
		|* Эта форма ЯВЛЯЕТСЯ уведомлением, что ваша заявка на бронирование зарегистрирована и по возможности МОЖЕТ быть удовлетворена позднее.
		|
		|* В случае удовлетворения заявки будет распечатана и отправлена отдельная форма подтверждения брони.'; 
		|en='* This is NOT reservation confirmation.
		|
		|* This form indicates that your reservation request was registered and could be confirmed if conditions allow it.
		|
		|* You will additionally receive reservation confirmation if your reservation request will be approved.';
		|de='* This is NOT reservation confirmation.
		|
		|* This form indicates that your reservation request was registered and could be confirmed if conditions allow it.
		|
		|* You will additionally receive reservation confirmation if your reservation request will be approved.'", SelLanguage);
	EndIf;
	vFooter.Parameters.mReservationConditions = StrReplace(vFooter.Parameters.mReservationConditions, "\n", "");
	// Get external system interactions
	vIntegration = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsGuestlink(SelReservation.Hotel);
	vOnlineModuleLink = "";
	If Not vIntegration = Undefined Then
		vOnlineModuleLink = vIntegration.HttpAddress;
	EndIf;	
	
	// Payment link
	vPaymentLinkIsEmpty = True;
	If Find(vParameter, "SHOW_PAYMENT_LINK") > 0 And Not IsBlankString(vOnlineModuleLink) And ValueIsFilled(Guest) And vTemplate.Areas.Find("PaymentLinkRow") <> Undefined Then
		vPaymentLinkArea = vTemplate.GetArea("PaymentLinkRow");
		vPaymentLinkText = cmNStr("en='To pay for your reservation click on the link '; ru='Для оплаты брони перейдите по ссылке '; de='Um Ihre Reservierung zu bezahlen, klicken Sie auf den Link '", SelLanguage);
		vPaymentLink = "&GuestReservationLink";
		vPaymentLink = SMS.ReplaceSMSParameters(vPaymentLink, Ref, Guest);
		vPaymentLinkArea.Parameters.mPaymentLinkText = vPaymentLinkText ;
		vPaymentLinkArea.Parameters.mPaymentLink = vPaymentLink;
		vPaymentLinkIsEmpty = False;
	EndIf;
	
	// Footer
	vFooter.Parameters.mReservationDivisionContacts = vHotelObj.pmGetHotelReservationDivisionContacts(SelLanguage);
	vFooter.Parameters.mAuthor = ?(ValueIsFilled(SelReservation.Author), SelReservation.Author.GetObject().pmGetEmployeeDescription(SelLanguage), "");
	vNumOfEmptyLines = 0;
	vEmptyRow = vTemplate.GetArea("EmptyRow");
	vFooterArray = New Array();
	If Not vPaymentLinkIsEmpty Then
		vFooterArray.Add(vPaymentLinkArea);
	EndIf;
	vFooterArray.Add(vFooter);
	Try
		While vSpreadsheet.CheckPut(vFooterArray) Do
			vFooterArray.Insert(0, vEmptyRow);
			vNumOfEmptyLines = vNumOfEmptyLines + 1;
		EndDo;
	Except
	EndTry;
	If vNumOfEmptyLines > 0 Then
		vFooterArray.Delete(0);
	EndIf;
	For Each vArea In vFooterArray Do
		vSpreadsheet.Put(vArea);
	EndDo;
	
	// Delete empy area payment link
	If vPaymentLinkIsEmpty Then
		vCurArea = vSpreadsheet.Areas.Find("PaymentLinkRow");
		If Not vCurArea = Undefined Then
			vSpreadsheet.DeleteArea(vCurArea, SpreadsheetDocumentShiftType.Vertical);
		EndIf;
	EndIf;	

	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Portrait, True);
	// Check authorities
	cmSetSpreadsheetProtection(vSpreadsheet);
EndProcedure //  pmPrintConfirmation

// -----------------------------------------------------------------------------
Procedure pmPrintConfirmationWithServices(vSpreadsheet, SelReservation, SelReservations, SelServicesFilter, SelServiceGroup, SelShowConfirmationForCurrentReservationOnly, SelLanguage, SelObjectPrintForm) Export
	// Basic checks
	If Not ValueIsFilled(SelReservation.Hotel) Then
		Raise String(Ref) + " - " + NStr("ru='У документа должна быть указана гостиница!';de='Bei dem Dokument muss das Hotel angegeben sein!';en='Hotel attribute should be filled!'");
	EndIf;
	If Not ValueIsFilled(SelLanguage) Then
		SelLanguage = SessionParameters.CurrentLanguage;
	EndIf;
	
	// Some settings
	vShowReservationNumbersInConfirmation = cmCheckUserPermissions("ShowReservationNumbersInConfirmation");
	
	// Fill and check grouping parameter
	vParameter = UPPER(TrimAll(SelObjectPrintForm.Parameter));
	
	// Choose template
	vResObj = SelReservation.GetObject();
	vSpreadsheet.Clear();
	If ValueIsFilled(SelLanguage) Then
		If SelLanguage = Catalogs.Languages.EN Then
			vTemplate = vResObj.GetTemplate("ReservationConfirmationWithServicesEn");
		ElsIf SelLanguage = Catalogs.Languages.DE Then
			vTemplate = vResObj.GetTemplate("ReservationConfirmationWithServicesDe");
		ElsIf SelLanguage = Catalogs.Languages.RU Then
			vTemplate = vResObj.GetTemplate("ReservationConfirmationWithServicesRu");
		Else
			Raise String(Ref) + " - " + 
			      NStr("ru='Не найден шаблон печатной формы подтверждения бронирования для языка " + SelLanguage.Code + "!'; 
			           |de='No reservation confirmation print form template found for the " + SelLanguage.Code + " language!';
			           |en='No reservation confirmation print form template found for the " + SelLanguage.Code + " language!'");
		EndIf;
	Else
		vTemplate = vResObj.GetTemplate("ReservationConfirmationWithServicesRu");
	EndIf;
	// Load external template if any
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(SelObjectPrintForm);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	EndIf;
	
	// Load pictures
	vLogoIsSet = False;
	vLogo = New Picture;
	If ValueIsFilled(SelReservation.Hotel) Then
		If SelReservation.Hotel.Logo <> Undefined Then
			vLogo = SelReservation.Hotel.Logo.Get();
			If vLogo = Undefined Then
				vLogo = New Picture;
			Else
				vLogoIsSet = True;
			EndIf;
		EndIf;
	EndIf;
	
	// Header top
	vHeader = vTemplate.GetArea("TopHeader");
	// Hotel
	vHotelObj = SelReservation.Hotel.GetObject();
	mHotelPrintName = vHotelObj.pmGetHotelPrintName(SelLanguage);
	mHotelPostAddressPresentation = vHotelObj.pmGetHotelPostAddressPresentation(SelLanguage);
	mHotelPhones = TrimAll(SelReservation.Hotel.Phones);
	mHotelFax = TrimAll(SelReservation.Hotel.Fax);
	mHotelEMail = TrimAll(SelReservation.Hotel.EMail);
	// Contact person
	mContactPersonName = TrimR(SelReservation.ContactPerson);
	If IsBlankString(mContactPersonName) And 
	   ValueIsFilled(SelReservation.GuestGroup) And ValueIsFilled(SelReservation.GuestGroup.Client) Then
		mContactPersonName = TrimR(SelReservation.GuestGroup.Client.FullName);
	EndIf;
	// Customer
	mCustomerLegacyName = "";
	If ValueIsFilled(SelReservation.Customer) Then
		mCustomerLegacyName = TrimAll(SelReservation.Customer.LegacyName);
		If IsBlankString(mCustomerLegacyName) Then
			mCustomerLegacyName = TrimAll(SelReservation.Customer.Description);
		EndIf;
	EndIf;
	// Contract
	mContractDescription = "";
	If ValueIsFilled(SelReservation.Contract) Then
		mContractDescription = TrimAll(SelReservation.Contract.Description);
	EndIf;
	// Fax and E-Mail
	mFax = "";
	mEMail = "";
	If Not IsBlankString(SelReservation.Phone) Then
		mFax = TrimAll(SelReservation.Phone);
	EndIf;
	If Not IsBlankString(SelReservation.EMail) Then
		mEMail = TrimAll(SelReservation.EMail);
	EndIf;
	If ValueIsFilled(SelReservation.Customer) Then
		If IsBlankString(mFax) Then
			mFax = TrimAll(SelReservation.Customer.Phone);
		EndIf;
		If IsBlankString(mEMail) Then
			mEMail = TrimAll(SelReservation.Customer.EMail);
		EndIf;
	ElsIf ValueIsFilled(SelReservation.GuestGroup) And ValueIsFilled(SelReservation.GuestGroup.Client) Then
		If IsBlankString(mFax) Then
			mFax = TrimAll(SelReservation.GuestGroup.Client.Phone);
		EndIf;
		If IsBlankString(mEMail) Then
			mEMail = TrimAll(SelReservation.GuestGroup.Client.EMail);
		EndIf;
	EndIf;
	// Confirmation header text
	mFormHeader = cmNStr("en='RESERVATION CONFIRMATION';ru='ПОДТВЕРЖДЕНИЕ БРОНИРОВАНИЯ';de='BESTÄTIGUNG DER RESERVIERUNG'", SelLanguage);
	mFormName = cmNStr("en='Confirmation';ru='подтверждения';de='Bestätigung'", SelLanguage);
	// Check if this reservation is in waiting list
	IsWaitingList = False;
	If ValueIsFilled(SelReservation) And ValueIsFilled(SelReservation.ReservationStatus) And SelReservation.ReservationStatus.IsInWaitingList Then
		IsWaitingList = True;
		mFormHeader = cmNStr("en='RESERVATION REQUEST';ru='ЗАЯВКА';de='ANTRAG'", SelLanguage);
		mFormName = cmNStr("en='Request';ru='заявки';de='des Antrages'", SelLanguage);
	EndIf;		
	// Document date
	mDate = Format(SelReservation.Date, "DF='dd.MM.yyyy'");
	// Guest group code
	mGuestGroupCode = TrimAll(SelReservation.GuestGroup.Code);
	vHotelPrefix = Catalogs.Hotels.pmGetPrefix(SelReservation.Hotel);
	If Not IsBlankString(vHotelPrefix) And SelReservation.Hotel.ShowHotelPrefixBeforeGroupCode Then
		mGuestGroupCode = vHotelPrefix + mGuestGroupCode;
	EndIf;
	// Set parameters and put report section
	vHeader.Parameters.mHotelPrintName = mHotelPrintName;
	vHeader.Parameters.mHotelPostAddressPresentation = mHotelPostAddressPresentation;
	vHeader.Parameters.mHotelPhones = mHotelPhones;
	vHeader.Parameters.mHotelFax = mHotelFax;
	vHeader.Parameters.mHotelEMail = mHotelEMail;
	vHeader.Parameters.mContactPersonName = mContactPersonName;
	vHeader.Parameters.mCustomerLegacyName = mCustomerLegacyName;
	vHeader.Parameters.mContractDescription = mContractDescription;
	vHeader.Parameters.mFax = mFax;
	vHeader.Parameters.mEMail = mEMail;
	vHeader.Parameters.mFormHeader = mFormHeader;
	vHeader.Parameters.mFormName = mFormName;
	vHeader.Parameters.mDate = mDate;
	vHeader.Parameters.mGuestGroupCode = mGuestGroupCode;
	vHeader.Parameters.mGuestGroupDescription = "";
	If ValueIsFilled(SelReservation.GuestGroup) Then
		If Not IsBlankString(SelReservation.GuestGroup.ID) Then
			vHeader.Parameters.mGuestGroupDescription = TrimR(SelReservation.GuestGroup.ID);
		Else
			vHeader.Parameters.mGuestGroupDescription = TrimR(SelReservation.GuestGroup.Description);
		EndIf;
	EndIf;
	// Logo
	If vLogoIsSet Then
		vHeader.Drawings.Logo.Print = True;
		vHeader.Drawings.Logo.Picture = vLogo;
	Else
		vHeader.Drawings.Delete(vHeader.Drawings.Logo);
	EndIf;    
	// Print QR code
	Try
		If Find(vParameter, "SHOW_QRCODE") > 0 Then  
			vResUUIDStr = String(SelReservation.UUID());
			vQRCodeControl = vHeader.Drawings.QRCodeControl;
			vQRCodeControl.Picture = cmGetQRCodePicture(vResUUIDStr);
		Else
			vHeader.Drawings.Delete(vHeader.Drawings.QRCodeControl);
		EndIf;
	Except
	EndTry;

	// Put header		
	vSpreadsheet.Put(vHeader);
	
	// Put company data if necessary
	If ValueIsFilled(SelReservation.Company) And SelReservation.Hotel.PrintCompanyDataInReservationConfirmation Then
		vCompanyHeader = vTemplate.GetArea("CompanyHeader");
		vCompany = SelReservation.Company;
		vCompanyObj = vCompany.GetObject();
		vCompanyTIN = TrimAll(vCompany.TIN);
		vCompanyKPP = TrimAll(vCompany.KPP);
		vCompanyHeader.Parameters.mTIN = cmNStr("en='TIN ';ru='ИНН ';de='INN '", SelLanguage) + vCompanyTIN + ?(IsBlankString(vCompanyKPP), "", "/" + vCompanyKPP);
		vAccount = SelReservation.Company.BankAccount;
		vCompanyName = vCompanyObj.pmGetCompanyPrintName(SelLanguage);
		vCompanyBankAccount = "";
		If vAccount.IsDirectPayments Then
			vCompanyBankAccount = cmNStr("en='Acc. № ';ru='Р/С ';de='Verrechnungskonto '", SelLanguage) + TrimAll(vAccount.AccountNumber);
			vCompanyBankAccount = vCompanyBankAccount + cmNStr("en=' in ';ru=' в ';de=' in '", SelLanguage) + TrimAll(TrimAll(vAccount.BankName) + " " + TrimAll(vAccount.BankCity));
			If Not IsBlankString(vAccount.BankCorrAccountNumber) Then
				vCompanyBankAccount = vCompanyBankAccount + cmNStr("en=', Corr. acc. № ';de=', Corr. acc. № ';ru=', К/С '", SelLanguage) + TrimAll(vAccount.BankCorrAccountNumber);
			EndIf;
			If Not IsBlankString(vAccount.BankBIC) Then
				vCompanyBankAccount = vCompanyBankAccount + cmNStr("en=', BIC ';de=', BIC ';ru=', БИК '", SelLanguage) + TrimAll(vAccount.BankBIC);
			EndIf;
		Else
			vCompanyName = vCompanyName + cmNStr("en=', Acc. № ';de=', Acc. № ';ru=', Р/С '", SelLanguage) + TrimAll(vAccount.AccountNumber);
			vCompanyName = vCompanyName + cmNStr("en=' in ';ru=' в ';de=' in '", SelLanguage) + TrimAll(TrimAll(vAccount.BankName) + " " + TrimAll(vAccount.BankCity));
			If Not IsBlankString(vAccount.BankCorrAccountNumber) Then
				vCompanyName = vCompanyName + cmNStr("en=', Corr. acc. № ';de=', Corr. acc. № ';ru=', К/С '", SelLanguage) + TrimAll(vAccount.BankCorrAccountNumber);
			EndIf;
			If Not IsBlankString(vAccount.BankBIC) Then
				vCompanyName = vCompanyName + cmNStr("en=', BIC ';de=', BIC ';ru=', БИК '", SelLanguage) + TrimAll(vAccount.BankBIC);
			EndIf;
			vCompanyBankAccount = cmNStr("en='Acc. № ';de='Acc. № ';ru='Р/С ';de='Verrechnungskonto '", SelLanguage) + TrimAll(vAccount.CorrBankCorrAccountNumber);
			vCompanyBankAccount = vCompanyBankAccount + cmNStr("en=' in ';ru=' в ';de=' in '", SelLanguage) + TrimAll(TrimAll(vAccount.CorrBankName) + " " + TrimAll(vAccount.CorrBankCity));
		EndIf;
		If Not IsBlankString(vAccount.BankIBAN) Then
			vCompanyBankAccount = vCompanyBankAccount + Chars.LF + cmNStr("en=', IBAN CODE ';de=', IBAN CODE ';ru=', IBAN CODE '", SelLanguage) + TrimAll(vAccount.BankIBAN);
		EndIf;
		If Not IsBlankString(vAccount.BankSWIFTCode) Then
			vCompanyBankAccount = vCompanyBankAccount + Chars.LF + cmNStr("en=', SWIFT CODE ';de=', SWIFT CODE ';ru=', SWIFT CODE '", SelLanguage) + TrimAll(vAccount.BankSWIFTCode);
		EndIf;
		vCompanyHeader.Parameters.mCompanyName = vCompanyName;
		vCompanyHeader.Parameters.mLegalAddress = vCompanyObj.pmGetCompanyLegacyAddressPresentation(SelLanguage);
		vCompanyHeader.Parameters.mBankAccount = vCompanyBankAccount;
		// Put company header
		vSpreadsheet.Put(vCompanyHeader);
	EndIf;
	
	// Header bottom
	vBottomHeader = vTemplate.GetArea("BottomHeader");
	vSpreadsheet.Put(vBottomHeader);
	
	// Table rows
	vClient = vTemplate.GetArea("Client");
	vRow = vTemplate.GetArea("Row");
	vTableFooter = vTemplate.GetArea("TableFooter");
	
	// Build table of all guest group services
	vServices = Undefined;
	vChildrenAges = "";
	vChildrenIndex = 0;
	vReservations = SelReservation.GuestGroup.GetObject().pmGetReservations(True, ?(IsWaitingList, False, True), False, IsWaitingList, ?(SelShowConfirmationForCurrentReservationOnly, SelReservation, Undefined), ?(SelShowConfirmationForCurrentReservationOnly, Undefined, ?(SelReservations = Undefined, Undefined, ?(SelReservations.Count() > 1, SelReservations, Undefined))));
	For Each vRes In vReservations Do
		If ValueIsFilled(vRes.Status) And 
		   (Not IsWaitingList And (vRes.Status.IsActive Or vRes.Status.IsCheckIn Or vRes.Status.IsPreliminary) Or IsWaitingList) Then
			vCurRes = vRes.Reservation;
			// Children ages
			If vCurRes.GuestAge > 0 Then
				vChildrenIndex = vChildrenIndex + 1;
				If vChildrenIndex > 1 Then
					vChildrenAges = vChildrenAges + Chars.LF;
				EndIf;
				vChildrenAges = vChildrenAges + cmNStr("en='Child '; ru='Ребёнок '; de='Kind '", SelLanguage) + Format(vChildrenIndex, "NFD=0; NG=") + cmNstr("en=': Age: '; ru=': Возраст: '; de=': Alter: '", SelLanguage) + Format(vCurRes.GuestAge, "NFD=0; NG=");
			EndIf;
			// Reservation services
			If vServices = Undefined Then
				vServices = vCurRes.Services.Unload();
				vServices.Clear();
				vServices.Columns.Add("Reservation");
				vServices.Columns.Add("Client");
				vServices.Columns.Add("DateTimeFrom");
				vServices.Columns.Add("DateTimeTo");
			EndIf;
			vCurResServices = cmGetReservationServices(vCurRes);
			// Join services according to service parameters
			If Find(vParameter, "DETAILED") = 0 Then
				// Try to replace accommodation service to the one that should be used for printing
				vAccountingDate = '00010101';
				vFirstRoomRateService = Undefined;
				vFirstRoomRateServiceIsFound = False;
				For Each vSrvRow In vCurResServices Do
					vSrvRowService = vSrvRow.Service;
					If ValueIsFilled(vSrvRowService) Then
						If vAccountingDate <> BegOfDay(vSrvRow.AccountingDate) Then
							vAccountingDate = BegOfDay(vSrvRow.AccountingDate);
							vFirstRoomRateService = Undefined;
							vFirstRoomRateServiceIsFound = False;
						EndIf;
						If vSrvRowService.IsRoomRevenue And vSrvRowService.IsInPrice And Not vSrvRowService.RoomRevenueAmountsOnly Then
							If ValueIsFilled(vSrvRowService.HideIntoServiceOnPrint) Then
								vSrvRow.Service = vSrvRowService.HideIntoServiceOnPrint;
							EndIf;
							If Not vFirstRoomRateServiceIsFound Then
								vFirstRoomRateService = vSrvRowService;
								vFirstRoomRateServiceIsFound = True;
							Else
								If vFirstRoomRateService <> vSrvRowService And ValueIsFilled(vSrvRowService.HideIntoServiceOnPrint) Then
									vSrvRow.Quantity = 0;
								EndIf;
							EndIf;
						ElsIf vSrvRowService.DoNotGroupIntoRoomRateOnPrint And ValueIsFilled(vSrvRowService.HideIntoServiceOnPrint) Then
							vSrvRow.Service = vSrvRowService.HideIntoServiceOnPrint;
						EndIf;
					EndIf;
				EndDo;
				// Try to merge other services to the accommodation service
				i = 0;
				While i < vCurResServices.Count() Do
					vSrvRow = vCurResServices.Get(i);
					vSrvRowService = vSrvRow.Service;
					If ValueIsFilled(vSrvRowService) And ValueIsFilled(vSrvRowService.HideIntoServiceOnPrint) Then
						If Not vSrvRowService.DoNotGroupIntoRoomRateOnPrint Then
							vHideToServices = vCurResServices.FindRows(New Structure("Service, AccountingDate, FolioCurrency", vSrvRowService.HideIntoServiceOnPrint, vSrvRow.AccountingDate, vSrvRow.FolioCurrency));
							If vHideToServices.Count() = 0 Then
								vHideToServices = vCurResServices.FindRows(New Structure("Service, AccountingDate, FolioCurrency", vSrvRowService.HideIntoServiceOnPrint, vSrvRow.AccountingDate - 24*3600, vSrvRow.FolioCurrency));
							EndIf;
							If vHideToServices.Count() > 0 Then
								vSrv2Hide2 = vHideToServices.Get(0);
								vSrv2Hide2.Sum = vSrv2Hide2.Sum + vSrvRow.Sum;
								vSrv2Hide2.VATSum = vSrv2Hide2.VATSum + vSrvRow.VATSum;
								vSrv2Hide2.DiscountSum = vSrv2Hide2.DiscountSum + vSrvRow.DiscountSum;
								vSrv2Hide2.VATDiscountSum = vSrv2Hide2.VATDiscountSum + vSrvRow.VATDiscountSum;
								vSrv2Hide2.CommissionSum = vSrv2Hide2.CommissionSum + vSrvRow.CommissionSum;
								vSrv2Hide2.VATCommissionSum = vSrv2Hide2.VATCommissionSum + vSrvRow.VATCommissionSum;
								vSrv2Hide2.Price = cmRecalculatePrice(vSrv2Hide2.Sum, vSrv2Hide2.Quantity);
								// Delete current service
								vCurResServices.Delete(i);
								Continue;
							EndIf;
						EndIf;
					EndIf;
					i = i + 1;
				EndDo;
			EndIf;
			// Filter services by customer
			If SelServicesFilter > 0 Then
				i = 0;
				While i < vCurResServices.Count() Do
					vResSrvRow = vCurResServices.Get(i);
					If SelServicesFilter = 1 Then
						If ValueIsFilled(vResSrvRow.Folio.Customer) Then
							vCurResServices.Delete(i);
							Continue;
						EndIf;
					ElsIf SelServicesFilter = 2 Then
						If Not ValueIsFilled(vResSrvRow.Folio.Customer) Then
							vCurResServices.Delete(i);
							Continue;
						EndIf;
					EndIf;
					i = i + 1;
				EndDo;
			EndIf;
			// Filter services by service group
			If ValueIsFilled(SelServiceGroup) Then
				i = 0;
				While i < vCurResServices.Count() Do
					vResSrvRow = vCurResServices.Get(i);
					If Not cmIsServiceInServiceGroup(vResSrvRow.Service, SelServiceGroup) Then
						vCurResServices.Delete(i);
						Continue;
					EndIf;
					i = i + 1;
				EndDo;
			EndIf;
			// Add current reservation services to the one value table of services
			For Each vResSrvRow In vCurResServices Do
				If Find(vParameter, "HIDE_ZERO_CLIENTS") > 0 Then
					If vResSrvRow.Sum = 0 Then
						Continue;
					EndIf;
				EndIf;
				vSrvRow = vServices.Add();
				FillPropertyValues(vSrvRow, vResSrvRow);
				vSrvRow.Client = vCurRes.Guest;
				vRoomTypeToPrint = vCurRes.RoomType;
				If ValueIsFilled(vRoomTypeToPrint) And ValueIsFilled(vCurRes.RoomTypeUpgrade) And vCurRes.RoomTypeUpgrade.BaseRoomType = vRoomTypeToPrint Then
					vRoomTypeToPrint = vCurRes.RoomTypeUpgrade;
				EndIf;
				vSrvRow.RoomType = vRoomTypeToPrint;
				If Not ValueIsFilled(vSrvRow.AccommodationType) Then
					vSrvRow.AccommodationType = vCurRes.AccommodationType;
				EndIf;
				vSrvRow.DateTimeFrom = vCurRes.CheckInDate;
				vSrvRow.DateTimeTo = vCurRes.CheckOutDate;
				vSrvRow.Reservation = vCurRes;
			EndDo;
		EndIf;
	EndDo;
	
	// Get accommodation service name
	vAccommodationService = Undefined;	
	If vServices <> Undefined Then
		For Each vSrvRow In vServices Do
			If vSrvRow.IsRoomRevenue And Not vSrvRow.RoomRevenueAmountsOnly Then
				vAccommodationService = vSrvRow.Service;
				Break;
			EndIf;
		EndDo;
		
		// Get reservation currency
		vCurrency = SelReservation.Hotel.BaseCurrency;
		For Each vSrvRow In SelReservation.Services Do
			If vSrvRow.IsRoomRevenue Then
				vCurrency = vSrvRow.FolioCurrency;
				Break;
			EndIf;
		EndDo;
		
		// Print services
		vTotalSum = 0;
		vTotalVATSum = 0;
		vTotalQuantity = 0;
		vTotalNumberOfPersons = 0;
		vTotalCommissionSum = vServices.Total("CommissionSum");
		vTotalVATCommissionSum = vServices.Total("VATCommissionSum");

		vTotalPaidSum = 0;
		vDocsList = Undefined;
		If SelShowConfirmationForCurrentReservationOnly Then
			vDocsList = New ValueList();
			vDocsList.Add(SelReservation);
		EndIf;
		If SelReservations <> Undefined Then
			For Each vSelReservationsItem In SelReservations Do
				If vDocsList = Undefined Then
					vDocsList = New ValueList();
				EndIf;
				If vDocsList.FindByValue(vSelReservationsItem.Value) = Undefined Then
					vDocsList.Add(vSelReservationsItem.Value);
				EndIf;
			EndDo;
		EndIf;
		vGroupPayments = SelReservation.GuestGroup.GetObject().pmGetPaymentsTotals(vDocsList);
		For Each vGroupPaymentsRow In vGroupPayments Do
			vTotalPaidSum = vTotalPaidSum + Round(cmConvertCurrencies(vGroupPaymentsRow.Sum, vGroupPaymentsRow.Currency, , vCurrency, , vGroupPaymentsRow.AccountingDate, SelReservation.Hotel), 2);
		EndDo;
		
		// Group by services by the accommodation conditions
		vConditions = vServices.Copy();
		i = 0;
		While i < vConditions.Count() Do
			vCndRow = vConditions.Get(0);
			If Not vCndRow.IsRoomRevenue Then
				vConditions.Delete(i);
			Else
				i = i + 1;
			EndIf;
		EndDo;
		vConditions.GroupBy("AccommodationType, RoomType, DateTimeFrom, DateTimeTo", );
		For Each vConditionsRow In vConditions Do
			// Select services for the each condition
			vRowsArray = vServices.FindRows(New Structure("AccommodationType, RoomType, DateTimeFrom, DateTimeTo", 
			                                vConditionsRow.AccommodationType, vConditionsRow.RoomType, 
			                                vConditionsRow.DateTimeFrom, vConditionsRow.DateTimeTo));
			vCndServices = vServices.CopyColumns();
			For Each vRowElement In vRowsArray Do
				vCndServicesRow = vCndServices.Add();
				FillPropertyValues(vCndServicesRow, vRowElement);
			EndDo;
			
			vGuests = vCndServices.Copy();
			vGuests.GroupBy("Reservation, Client", );
			vGuests.Sort("Client");
			vGuestNames = "";
			For Each vGuestsRow In vGuests Do
				If ValueIsFilled(vGuestsRow.Client) Then
					If IsBlankString(vGuestNames) Then
						If vGuests.Count() > 1 Then
							vGuestNames = Chars.LF;
						EndIf;
						vGuestNames = vGuestNames + TrimAll(TrimAll(vGuestsRow.Client) + ?(vShowReservationNumbersInConfirmation, cmNStr("en=' #';de=' Nr.';ru=' №'", SelLanguage) + cmGetDocumentNumberPresentation(vGuestsRow.Reservation.Number), ""));
					Else
						vGuestNames = vGuestNames + ", " + TrimAll(TrimAll(vGuestsRow.Client) + ?(vShowReservationNumbersInConfirmation, cmNStr("en=' #';de=' Nr.';ru=' №'", SelLanguage) + cmGetDocumentNumberPresentation(vGuestsRow.Reservation.Number), ""));
					EndIf;
				EndIf;
			EndDo;
		
			// Group sevices by accommodation by default
			If Find(vParameter, "DETAILED") = 0 Then
				For Each vSrvRow In vCndServices Do
					If Find(vParameter, "ALL") > 0 Then
						If Not vSrvRow.IsRoomRevenue Or vSrvRow.Service.RoomRevenueAmountsOnly Then
							vSrvRow.Service = ?(ValueIsFilled(vAccommodationService), vAccommodationService, vSrvRow.Service);
							vSrvRow.Quantity = ?(ValueIsFilled(vAccommodationService), 0, vSrvRow.Quantity);
							vSrvRow.Price = 0;
						EndIf;
					Else
						// Reset "is in price" flag if necessary
						If ValueIsFilled(vSrvRow.Service) And vSrvRow.Service.DoNotGroupIntoRoomRateOnPrint Then
							vSrvRow.IsInPrice = False;
						EndIf;
						If Not vSrvRow.IsRoomRevenue And vSrvRow.IsInPrice Then
							vSrvRow.Service = ?(ValueIsFilled(vAccommodationService), vAccommodationService, vSrvRow.Service);
							vSrvRow.Quantity = ?(ValueIsFilled(vAccommodationService), 0, vSrvRow.Quantity);
							vSrvRow.Price = 0;
						ElsIf vSrvRow.IsRoomRevenue And vSrvRow.IsInPrice Then
							If vSrvRow.Service.RoomRevenueAmountsOnly Then
								vSrvRow.Quantity = 0;
							EndIf;
							vSrvRow.Service = ?(ValueIsFilled(vAccommodationService), vAccommodationService, vSrvRow.Service);
							vSrvRow.Price = 0;
							If vSrvRow.IsSplit Then
								vSrvRow.Quantity = 0;
							EndIf;
						EndIf;
					EndIf;
				EndDo;
			EndIf;
			If Find(vParameter, "DETAILED") = 0 Then
				vCndServices.GroupBy("Service", "Sum, VATSum, DiscountSum, VATDiscountSum, Quantity, GuestsCheckedIn, GuestDays, Price");
			EndIf;
			vCndServices.GroupBy("Service, Price", "Sum, VATSum, DiscountSum, VATDiscountSum, Quantity, GuestsCheckedIn, GuestDays");
			// Recalculate price and sum for all services
			For Each vSrvRow In vCndServices Do
				vSrvRow.Sum = vSrvRow.Sum - vSrvRow.DiscountSum;
				vSrvRow.VATSum = vSrvRow.VATSum - vSrvRow.VATDiscountSum;
				vSrvRow.Price = cmRecalculatePrice(vSrvRow.Sum, vSrvRow.Quantity);
			EndDo;
		
			// Print condition header
			vDateTimeFrom = Format(vConditionsRow.DateTimeFrom, "DF='dd.MM.yy HH:mm'");
			vDateTimeTo = Format(vConditionsRow.DateTimeTo, "DF='dd.MM.yy HH:mm'");
			vRoomType = "";
			If ValueIsFilled(vConditionsRow.RoomType) Then
				vRoomType = vConditionsRow.RoomType.GetObject().pmGetRoomTypeDescription(SelLanguage);
			EndIf;
			mCondition = ?(ValueIsFilled(vConditionsRow.DateTimeFrom), vDateTimeFrom + " - " + vDateTimeTo, "") + 
					     ?(IsBlankString(vRoomType), "" , ", " + vRoomType) + 
			             ?(IsBlankString(vGuestNames), "", ", " + vGuestNames);
						 
			// Set client area parameters
			vClient.Parameters.mClient = mCondition;
			// Put client area
			vSpreadsheet.Put(vClient);
			For Each vSrvRow In vCndServices Do
				// Fill row parameters
				mPrice = vSrvRow.Price;
				mSum = vSrvRow.Sum;
				mQuantity = ?(vSrvRow.Quantity=0, "", vSrvRow.Quantity);
				If ValueIsFilled(vSrvRow.Service) Then
					If vSrvRow.Quantity <> 0 Then
						vServiceObj = vSrvRow.Service.GetObject();
						If vSrvRow.GuestsCheckedIn <> 0 Then
							vDuration = vSrvRow.GuestDays/vSrvRow.GuestsCheckedIn;
							If vDuration <> 0 And vSrvRow.Quantity > vDuration Then 
								vQuantity = Round(vSrvRow.Quantity/vDuration, 0);
								mQuantity = ?(vQuantity = 0, "", Format(vQuantity, "ND=10; NFD=0; NG=") + "*" + vServiceObj.pmGetServiceQuantityPresentation(vDuration, SelLanguage));
							Else
								mQuantity = vServiceObj.pmGetServiceQuantityPresentation(vSrvRow.Quantity, SelLanguage);
							EndIf;
						Else
							mQuantity = vServiceObj.pmGetServiceQuantityPresentation(vSrvRow.Quantity, SelLanguage);
						EndIf;
					EndIf;
				EndIf;
				mNumberOfPersons = vSrvRow.GuestsCheckedIn;
				mDescription = Chars.Tab + ?(ValueIsFilled(vSrvRow.Service), vSrvRow.Service.GetObject().pmGetServiceDescription(SelLanguage), TrimAll(vSrvRow.Service));
				
				vTotalSum = vTotalSum + vSrvRow.Sum;
				vTotalVATSum = vTotalVATSum + vSrvRow.VATSum;
				If vSrvRow.Service = vAccommodationService Then
					vTotalQuantity = vTotalQuantity + vSrvRow.Quantity;
					vTotalNumberOfPersons = vTotalNumberOfPersons + vSrvRow.GuestsCheckedIn;
				EndIf;
				
				vRow.Parameters.mPrice = Format(mPrice, "ND=17; NFD=2");
				vRow.Parameters.mQuantity = mQuantity;
				vRow.Parameters.mNumberOfPersons = Format(mNumberOfPersons, "ND=8, NFD=0");
				vRow.Parameters.mDescription = mDescription;
				vRow.Parameters.mSum = Format(mSum, "ND=17; NFD=2");
				
				// Put row
				If Not IsBlankString(mSum) Or Not IsBlankString(mNumberOfPersons) Then
					vSpreadsheet.Put(vRow);
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	
	// Create table of charging rules
	vChargingRules = SelReservation.ChargingRules.Unload();
	If Not SelReservation.IgnoreGroupChargingRules Then
		cmAddGuestGroupChargingRules(vChargingRules, SelReservation.GuestGroup);
	EndIf;
	
	// Fill footer parameters
	mTotalSum = cmFormatSum(vTotalSum, vCurrency);
	mTotalQuantity = Format(vTotalQuantity, "ND=17; NFD=0");
	mTotalNumberOfPersons = Format(vTotalNumberOfPersons, "ND=17; NFD=0");
	If ValueIsFilled(vAccommodationService) Then
		If vTotalQuantity <> 0 Then
			vServiceObj = vAccommodationService.GetObject();
			mTotalQuantity = vServiceObj.pmGetServiceQuantityPresentation(vTotalQuantity, SelLanguage);
		EndIf;
	EndIf;
	// Set parameters
	If SelReservation.Customer = SelReservation.Agent And ValueIsFilled(SelReservation.Agent) And vTotalCommissionSum <> 0 And 
	   cmCustomerIsPayer(vChargingRules, SelReservation.Customer, SelReservation.Contract, SelReservation.GuestGroup, SelReservation.IgnoreGroupChargingRules) And 
	   Not Find(vParameter, "NO_COMMISSION") > 0 Then
		vTblFooter = vTemplate.GetArea("TableFooterCommission" + ?(Find(vParameter, "SHOW_TOTAL_PAID_AMOUNT") > 0, "Advances", ""));
		vTblFooter.Parameters.mTotalSum = mTotalSum;
		vTblFooter.Parameters.mTotalQuantity = ""; //mTotalQuantity -- commented to avoid client misunderstanding;
		vTblFooter.Parameters.mTotalNumberOfPersons = mTotalNumberOfPersons;
		vTblFooter.Parameters.mAgentCommission = "" + GetAgentCommissionDescription(SelReservation, SelLanguage);
		vTblFooter.Parameters.mTotalCommissionSum = cmFormatSum(vTotalCommissionSum, vCurrency);
		If Find(vParameter, "SHOW_TOTAL_PAID_AMOUNT") > 0 Then
			vTblFooter.Parameters.mTotalPaidSum = cmFormatSum(vTotalPaidSum, vCurrency);
			vTblFooter.Parameters.mSumToBePaid = cmFormatSum(vTotalSum - vTotalCommissionSum - vTotalPaidSum, vCurrency);
		Else
			vTblFooter.Parameters.mSumToBePaid = cmFormatSum(vTotalSum - vTotalCommissionSum, vCurrency);
		EndIf;
	Else
		vTblFooter = vTemplate.GetArea("TableFooter" + ?(Find(vParameter, "SHOW_TOTAL_PAID_AMOUNT") > 0, "Advances", ""));
		vTblFooter.Parameters.mTotalSum = mTotalSum;
		vTblFooter.Parameters.mTotalQuantity = ""; //mTotalQuantity -- commented to avoid client misunderstanding;
		vTblFooter.Parameters.mTotalNumberOfPersons = mTotalNumberOfPersons;
		If Find(vParameter, "SHOW_TOTAL_PAID_AMOUNT") > 0 Then
			vTblFooter.Parameters.mTotalPaidSum = cmFormatSum(vTotalPaidSum, vCurrency);
			vTblFooter.Parameters.mSumToBePaid = cmFormatSum(vTotalSum - vTotalPaidSum, vCurrency);
		EndIf;
	EndIf;
	// Put table footer
	vSpreadsheet.Put(vTblFooter);
	
	// Confirmation reply
	vConfRepl = vTemplate.GetArea("ConfirmationReply");
	vConfirmationReply = cmNStr("en='<Payment method was not set!>';ru='<Способ оплаты не установлен!>';de='<Zahlungsmethode nicht festgestellt!>'", SelLanguage);
	If vChargingRules.Count() > 0 Then
		// Get accommodation service charging rule
		vAccFolio = Undefined;
		For Each vSrvRow In SelReservation.Services Do
			If vSrvRow.IsRoomRevenue And vSrvRow.IsInPrice Then
				vAccFolio = vSrvRow.Folio;
				Break;
			EndIf;
		EndDo;
		vCRRow = Undefined;
		If Not ValueIsFilled(vAccFolio) Then				
			vCRRow = vChargingRules.Get(0);
			If Not ValueIsFilled(vCRRow.Owner) Then
				vCRRow = vChargingRules.Get(vChargingRules.Count()-1);
			EndIf;
			If vCRRow <> Undefined Then
				vAccFolio = vCRRow.ChargingFolio;
			EndIf;
		Else
			For Each vWrkCRRow In vChargingRules Do
				If vAccFolio = vWrkCRRow.ChargingFolio Then
					vCRRow = vWrkCRRow;
					Break;
				EndIf;
			EndDo;
		EndIf;
		If vCRRow <> Undefined And ValueIsFilled(vCRRow.ChargingRule) And ValueIsFilled(vAccFolio) Then
			If ValueIsFilled(vAccFolio.PaymentMethod) Then
				vPaymentMethodObj = vAccFolio.PaymentMethod.GetObject();
				If vCRRow.ChargingRule <> Enums.ChargingRuleTypes.Any Then
					vChargingRuleDescription = cmGetChargingRuleDescription(vCRRow, SelLanguage);
					vConfirmationReply = vPaymentMethodObj.pmGetPaymentMethodDescription(SelLanguage) + ?(IsBlankString(vChargingRuleDescription), "", " - " + vChargingRuleDescription);
				Else
					vConfirmationReply = vPaymentMethodObj.pmGetPaymentMethodDescription(SelLanguage);
				EndIf;
				For Each vGroupPaymentsRow In vGroupPayments Do
					If vGroupPayments.IndexOf(vGroupPaymentsRow) = 0 Then
						vConfirmationReply = vConfirmationReply + Chars.LF + cmNStr("en='Payments are';ru='Платежи';de='Zahlungen'", SelLanguage);
					EndIf;
					vConfirmationReply = vConfirmationReply + Chars.LF + Format(vGroupPaymentsRow.AccountingDate, "DF=dd.MM.yyyy") + " - " + cmFormatSum(vGroupPaymentsRow.Sum, vGroupPaymentsRow.Currency);
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(SelReservation.DiscountType) Then
		vConfirmationReply = vConfirmationReply + ?(IsBlankString(vConfirmationReply), "", Chars.LF) + TrimAll(SelReservation.DiscountType);
	EndIf;
	If Not IsBlankString(SelReservation.DiscountConfirmationText) Then
		vConfirmationReply = vConfirmationReply + ?(IsBlankString(vConfirmationReply), "", Chars.LF) + TrimAll(SelReservation.DiscountConfirmationText);
	EndIf;
	If ValueIsFilled(SelReservation.ServicePackage) And SelReservation.ServicePackage.IsMealBoardTerm Then   
		vSPDesc = Catalogs.ServicePackages.GetServicePackageDescription(SelReservation.ServicePackage, SelLanguage);
		vConfirmationReply = vConfirmationReply + ?(IsBlankString(vConfirmationReply), "", Chars.LF) + cmNStr("en='Terms: '; ru='Питание: '; de='Terms: '", SelLanguage) + vSPDesc;
	EndIf;
	If Find(vParameter, "SHOW_CHILDREN_AGES") > 0 And Not IsBlankString(vChildrenAges) Then
		vConfirmationReply = vConfirmationReply + Chars.LF + vChildrenAges;
	EndIf;
	If Find(vParameter, "SHOW_AGENT_COMMISSION_PERCENT") > 0 Then
		If ValueIsFilled(SelReservation.AgentCommissionType) And SelReservation.AgentCommission > 0 Then
			vConfirmationReply = vConfirmationReply + Chars.Tab + Chars.Tab + Chars.Tab + Chars.Tab + cmNStr("en='Agent commission ';ru='Агентское вознаграждение ';de='Vertreterentlohnung '", SelLanguage) + SelReservation.AgentCommission + "%";
		EndIf;
	EndIf;
	If ValueIsFilled(SelReservation.GuestGroup) And Not IsBlankString(SelReservation.GuestGroup.Remarks) Then
		If Not IsBlankString(vConfirmationReply) Then
			vConfirmationReply = vConfirmationReply + Chars.LF + Chars.LF + TrimAll(SelReservation.GuestGroup.Remarks);
		Else
			vConfirmationReply = TrimAll(SelReservation.GuestGroup.Remarks);
		EndIf;
	EndIf;
	If Not IsBlankString(SelReservation.ConfirmationReply) Then
		If Not IsBlankString(vConfirmationReply) Then
			vConfirmationReply = vConfirmationReply + Chars.LF + Chars.LF + TrimAll(SelReservation.ConfirmationReply);
		Else
			vConfirmationReply = TrimAll(SelReservation.ConfirmationReply);
		EndIf;
	EndIf;
	vConfRepl.Parameters.mConfirmationReply = vConfirmationReply;
	vSpreadsheet.Put(vConfRepl);
	
	// Footer
	vFooter = vTemplate.GetArea("Footer");
	If ValueIsFilled(SelReservation.Company) And SelReservation.Company.DoNotPrintVAT Then
		vFooter.Parameters.mVATPresentation = "";
	Else
		vFooter.Parameters.mVATPresentation = cmNStr("ru='* В цену входит НДС';en='* All room rates include VAT (if other is not specified)';de='* All room rates include VAT (if other is not specified)'", SelLanguage);
		If ValueIsFilled(SelReservation) Then
			If ValueIsFilled(SelReservation.Company) Then
				If ValueIsFilled(SelReservation.Company.VATRate) Then
					If SelReservation.Company.VATRate.NoVAT Then
						vFooter.Parameters.mVATPresentation = cmNStr("ru='* Без НДС';en='* No VAT (if other is not specified)';de='* No VAT (if other is not specified)'", SelLanguage);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	vFooter.Parameters.mReservationConditions = "";
	vFeeTerms = SelReservation.FeeTerms;
	If Not ValueIsFilled(vFeeTerms) And ValueIsFilled(SelReservation.RoomRate) And ValueIsFilled(SelReservation.RoomRate.FeeTerms) Then
		vFeeTerms = SelReservation.RoomRate.FeeTerms;
	EndIf;
	If Not IsWaitingList Then
		If ValueIsFilled(SelReservation.RoomRate) And Not IsBlankString(SelReservation.RoomRate.ReservationConditions) Then
			vFooter.Parameters.mReservationConditions = vFooter.Parameters.mReservationConditions + cmNStr(SelReservation.RoomRate.ReservationConditions, SelLanguage);
		ElsIf Not IsBlankString(SelReservation.Hotel.ReservationConditions) Then
			vFooter.Parameters.mReservationConditions = vFooter.Parameters.mReservationConditions + cmNStr(SelReservation.Hotel.ReservationConditions, SelLanguage);
		Else
			vFooter.Parameters.mReservationConditions = vFooter.Parameters.mReservationConditions + 
			cmNStr(
			"ru='* Для аннулирования брони известите нас до 18:00 дня предшествующего дате заезда
			|
			|* Возможность поселения ранее указанного времени должна быть согласована с отделом бронирования'; 
			|de='* To cancel the booking, you may notify us by 6 p.m. ONE DAY PRIOR THE DATE OF ARRIVAL';
			|en='* To cancel the booking, you may notify us by 6 p.m. ONE DAY PRIOR THE DATE OF ARRIVAL'", SelLanguage);
		EndIf;
		If ValueIsFilled(SelReservation.ReservationStatus) And Not IsBlankString(SelReservation.ReservationStatus.ReservationConditions) Then
			vFooter.Parameters.mReservationConditions = vFooter.Parameters.mReservationConditions + Chars.LF + cmNStr(SelReservation.ReservationStatus.ReservationConditions, SelLanguage);
		EndIf;
		If ValueIsFilled(vFeeTerms) And Not IsBlankString(vFeeTerms.ConfirmationText) Then
			If Not vFeeTerms.ApplyConfirmationTextToGuaranteedReservationsOnly Or 
			   vFeeTerms.ApplyConfirmationTextToGuaranteedReservationsOnly And ValueIsFilled(SelReservation.ReservationStatus) And SelReservation.ReservationStatus.IsGuaranteed Then
				vFooter.Parameters.mReservationConditions = vFooter.Parameters.mReservationConditions + Chars.LF + Chars.LF + cmNStr(vFeeTerms.ConfirmationText, SelLanguage);
			EndIf;
		EndIf;
	Else
		vFooter.Parameters.mReservationConditions = vFooter.Parameters.mReservationConditions + 
		cmNStr(
		"ru='* Эта форма НЕ ЯВЛЯЕТСЯ подтверждением брони. 
		|
		|* Эта форма ЯВЛЯЕТСЯ уведомлением, что ваша заявка на бронирование зарегистрирована и по возможности МОЖЕТ быть удовлетворена позднее.
		|
		|* В случае удовлетворения заявки будет распечатана и отправлена отдельная форма подтверждения брони.'; 
		|de='* This is NOT reservation confirmation.
		|
		|* This form indicates that your reservation request was registered and could be confirmed if conditions allow it.
		|
		|* You will additionally receive reservation confirmation if your reservation request will be approved.'; 
		|en='* This is NOT reservation confirmation.
		|
		|* This form indicates that your reservation request was registered and could be confirmed if conditions allow it.
		|
		|* You will additionally receive reservation confirmation if your reservation request will be approved.'", SelLanguage);
	EndIf;
	vFooter.Parameters.mReservationConditions = StrReplace(vFooter.Parameters.mReservationConditions, "\n", "");
	// Get external system interactions
	vIntegration = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsGuestlink(SelReservation.Hotel);
	vOnlineModuleLink = "";
	If Not vIntegration = Undefined Then
		vOnlineModuleLink = vIntegration.HttpAddress;
	EndIf;	
	
	// Payment link
	vPaymentLinkIsEmpty = True;
	If Find(vParameter, "SHOW_PAYMENT_LINK") > 0 And Not IsBlankString(vOnlineModuleLink) And ValueIsFilled(Guest) And vTemplate.Areas.Find("PaymentLinkRow") <> Undefined Then
		vPaymentLinkArea = vTemplate.GetArea("PaymentLinkRow");
		vPaymentLinkText = cmNStr("en='To pay for your reservation click on the link '; ru='Для оплаты брони перейдите по ссылке '; de='Um Ihre Reservierung zu bezahlen, klicken Sie auf den Link '", SelLanguage);
		vPaymentLink = "&GuestReservationLink";
		vPaymentLink = SMS.ReplaceSMSParameters(vPaymentLink, Ref, Guest);
		vPaymentLinkArea.Parameters.mPaymentLinkText = vPaymentLinkText ;
		vPaymentLinkArea.Parameters.mPaymentLink = vPaymentLink;
		vPaymentLinkIsEmpty = False;
	EndIf;

	vFooter.Parameters.mReservationDivisionContacts = vHotelObj.pmGetHotelReservationDivisionContacts(SelLanguage);
	vFooter.Parameters.mAuthor = ?(ValueIsFilled(SelReservation.Author), SelReservation.Author.GetObject().pmGetEmployeeDescription(SelLanguage), "");
	
	vNumOfEmptyLines = 0;
	vEmptyRow = vTemplate.GetArea("EmptyRow");
	vFooterArray = New Array();
	If Not vPaymentLinkIsEmpty Then
		vFooterArray.Add(vPaymentLinkArea);
	EndIf;
	vFooterArray.Add(vFooter);
	Try
		While vSpreadsheet.CheckPut(vFooterArray) Do
			vFooterArray.Insert(0, vEmptyRow);
			vNumOfEmptyLines = vNumOfEmptyLines + 1;
		EndDo;
	Except
	EndTry;
	If vNumOfEmptyLines > 0 Then
		vFooterArray.Delete(0);
	EndIf;
	For Each vArea In vFooterArray Do
		vSpreadsheet.Put(vArea);
	EndDo;

	// Delete empy area payment link
	If vPaymentLinkIsEmpty Then
		vCurArea = vSpreadsheet.Areas.Find("PaymentLinkRow");
		If Not vCurArea = Undefined Then
			vSpreadsheet.DeleteArea(vCurArea, SpreadsheetDocumentShiftType.Vertical);
		EndIf;
	EndIf;	
	
	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Portrait, True);
	// Check authorities
	cmSetSpreadsheetProtection(vSpreadsheet);
EndProcedure //  pmPrintConfirmationWithServices

// -----------------------------------------------------------------------------
Procedure pmPrintCancellation(vSpreadsheet, SelReservation, SelReservations, SelShowCancellationForCurrentReservationOnly, SelLanguage, SelObjectPrintForm) Export
	// Basic checks
	If Not ValueIsFilled(SelReservation.Hotel) Then
		Raise String(Ref) + " - " + NStr("ru='У документа должна быть указана гостиница!';de='Bei dem Dokument muss das Hotel angegeben sein!';en='Hotel attribute should be filled!'");
	EndIf;
	If Not ValueIsFilled(SelLanguage) Then
		SelLanguage = SessionParameters.CurrentLanguage;
	EndIf;
	
	// Choose template
	vResObj = SelReservation.GetObject();
	vSpreadsheet.Clear();
	If ValueIsFilled(SelLanguage) Then
		If SelLanguage = Catalogs.Languages.EN Then
			vTemplate = vResObj.GetTemplate("ReservationCancellationEn");
		ElsIf SelLanguage = Catalogs.Languages.DE Then
			vTemplate = vResObj.GetTemplate("ReservationCancellationDe");
		ElsIf SelLanguage = Catalogs.Languages.RU Then
			vTemplate = vResObj.GetTemplate("ReservationCancellationRu");
		Else
			Raise String(Ref) + " - " + 
			      NStr("ru='Не найден шаблон печатной формы аннуляции бронирования для языка " + SelLanguage.Code + "!'; 
			           |de='No reservation cancellation print form template found for the " + SelLanguage.Code + " language!'; 
			           |en='No reservation cancellation print form template found for the " + SelLanguage.Code + " language!'");
		EndIf;
	Else
		vTemplate = vResObj.GetTemplate("ReservationCancellationRu");
	EndIf;
	// Load external template if any
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(SelObjectPrintForm);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	EndIf;
		
	// Load pictures
	vLogoIsSet = False;
	vLogo = New Picture;
	If ValueIsFilled(SelReservation.Hotel) Then
		If SelReservation.Hotel.Logo <> Undefined Then
			vLogo = SelReservation.Hotel.Logo.Get();
			If vLogo = Undefined Then
				vLogo = New Picture;
			Else
				vLogoIsSet = True;
			EndIf;
		EndIf;
	EndIf;

	// Header
	vHeader = vTemplate.GetArea("Header");
	// Hotel
	vHotelObj = SelReservation.Hotel.GetObject();
	mHotelPrintName = vHotelObj.pmGetHotelPrintName(SelLanguage);
	mHotelPostAddressPresentation = vHotelObj.pmGetHotelPostAddressPresentation(SelLanguage);
	mHotelPhones = TrimAll(SelReservation.Hotel.Phones);
	mHotelFax = TrimAll(SelReservation.Hotel.Fax);
	mHotelEMail = TrimAll(SelReservation.Hotel.EMail);
	// Contact person
	mContactPersonName = TrimR(SelReservation.ContactPerson);
	If IsBlankString(mContactPersonName) And 
	   ValueIsFilled(SelReservation.GuestGroup) And ValueIsFilled(SelReservation.GuestGroup.Client) Then
		mContactPersonName = TrimR(SelReservation.GuestGroup.Client.FullName);
	EndIf;
	// Customer
	mCustomerLegacyName = "";
	If ValueIsFilled(SelReservation.Customer) Then
		mCustomerLegacyName = TrimAll(SelReservation.Customer.LegacyName);
		If IsBlankString(mCustomerLegacyName) Then
			mCustomerLegacyName = TrimAll(SelReservation.Customer.Description);
		EndIf;
	EndIf;
	// Contract
	mContractDescription = "";
	If ValueIsFilled(SelReservation.Contract) Then
		mContractDescription = TrimAll(SelReservation.Contract.Description);
	EndIf;
	// Fax and E-Mail
	mFax = "";
	mEMail = "";
	If Not IsBlankString(SelReservation.Phone) Then
		mFax = TrimAll(SelReservation.Phone);
	EndIf;
	If Not IsBlankString(SelReservation.EMail) Then
		mEMail = TrimAll(SelReservation.EMail);
	EndIf;
	If ValueIsFilled(SelReservation.Customer) Then
		If IsBlankString(mFax) Then
			mFax = TrimAll(SelReservation.Customer.Phone);
		EndIf;
		If IsBlankString(mEMail) Then
			mEMail = TrimAll(SelReservation.Customer.EMail);
		EndIf;
	ElsIf ValueIsFilled(SelReservation.GuestGroup) And ValueIsFilled(SelReservation.GuestGroup.Client) Then
		If IsBlankString(mFax) Then
			mFax = TrimAll(SelReservation.GuestGroup.Client.Phone);
		EndIf;
		If IsBlankString(mEMail) Then
			mEMail = TrimAll(SelReservation.GuestGroup.Client.EMail);
		EndIf;
	EndIf;
	// Document date
	mDate = Format(SelReservation.Date, "DF='dd.MM.yyyy'");
	// Guest group code
	mGuestGroupCode = TrimAll(SelReservation.GuestGroup.Code);
	vHotelPrefix = Catalogs.Hotels.pmGetPrefix(SelReservation.Hotel);
	If Not IsBlankString(vHotelPrefix) And SelReservation.Hotel.ShowHotelPrefixBeforeGroupCode Then
		mGuestGroupCode = vHotelPrefix + mGuestGroupCode;
	EndIf;
	// Set parameters and put report section
	vHeader.Parameters.mHotelPrintName = mHotelPrintName;
	vHeader.Parameters.mHotelPostAddressPresentation = mHotelPostAddressPresentation;
	vHeader.Parameters.mHotelPhones = mHotelPhones;
	vHeader.Parameters.mHotelFax = mHotelFax;
	vHeader.Parameters.mHotelEMail = mHotelEMail;
	vHeader.Parameters.mContactPersonName = mContactPersonName;
	vHeader.Parameters.mCustomerLegacyName = mCustomerLegacyName;
	vHeader.Parameters.mContractDescription = mContractDescription;
	vHeader.Parameters.mFax = mFax;
	vHeader.Parameters.mEMail = mEMail;
	vHeader.Parameters.mDate = mDate;
	vHeader.Parameters.mGuestGroupCode = mGuestGroupCode;
	vHeader.Parameters.mGuestGroupDescription = "";
	If ValueIsFilled(SelReservation.GuestGroup) Then
		If Not IsBlankString(SelReservation.GuestGroup.ID) Then
			vHeader.Parameters.mGuestGroupDescription = TrimR(SelReservation.GuestGroup.ID);
		Else
			vHeader.Parameters.mGuestGroupDescription = TrimR(SelReservation.GuestGroup.Description);
		EndIf;
	EndIf;
	// Logo
	If vLogoIsSet Then
		vHeader.Drawings.Logo.Print = True;
		vHeader.Drawings.Logo.Picture = vLogo;
	Else
		vHeader.Drawings.Delete(vHeader.Drawings.Logo);
	EndIf;
	// Put header		
	vSpreadsheet.Put(vHeader);
	
	// Guests in group
	vRow = vTemplate.GetArea("Row");
	vReservations = SelReservation.GuestGroup.GetObject().pmGetReservations(True, False, True, False, ?(SelShowCancellationForCurrentReservationOnly, SelReservation, Undefined), ?(SelShowCancellationForCurrentReservationOnly, Undefined, ?(SelReservations = Undefined, Undefined, ?(SelReservations.Count() > 1, SelReservations, Undefined))));
	For Each vRes In vReservations Do
		If ValueIsFilled(vRes.Status) And 
		   (Not vRes.Status.IsActive And Not vRes.Status.IsCheckIn And Not vRes.Status.IsPreliminary) Then
			vCurRes = vRes.Reservation;
			vCurResObj = vCurRes.GetObject();
			// Get accommodation prices for all day types of room rate
			mRoomRate = vCurResObj.pmCalculatePricePresentation(SelLanguage);
			// Fill parameters
			vRow.Parameters.mGuest = cmGetFullPersonName(vCurRes.Guest) + Chars.LF + cmNStr("en='Indiv. #: ';ru='Индив. №: ';de='Ind. Nr.:'", SelLanguage) + cmGetDocumentNumberPresentation(vCurRes.Number);
			vRow.Parameters.mPeriod = Format(vCurRes.CheckInDate, "DF='dd.MM.yy HH:mm'") + " - " +
			                          Format(vCurRes.CheckOutDate, "DF='dd.MM.yy HH:mm'");
			vRow.Parameters.mQuantity = Format(vCurRes.RoomQuantity, "ND=6");
			vRoomTypeToPrint = vCurRes.RoomType;
			If ValueIsFilled(vRoomTypeToPrint) And ValueIsFilled(vCurRes.RoomTypeUpgrade) And vCurRes.RoomTypeUpgrade.BaseRoomType = vRoomTypeToPrint Then
				vRoomTypeToPrint = vCurRes.RoomTypeUpgrade;
			EndIf;
			vRow.Parameters.mRoomType = ?(ValueIsFilled(vRoomTypeToPrint), vRoomTypeToPrint.GetObject().pmGetRoomTypeDescription(SelLanguage) + " - ", "") + 
			                            ?(ValueIsFilled(vCurRes.AccommodationType), vCurRes.AccommodationType.GetObject().pmGetAccommodationTypeDescription(SelLanguage), "");
			vRow.Parameters.mRoom = ?(ValueIsFilled(vCurRes.Room), TrimAll(vCurRes.Room.Description), "");
			vRow.Parameters.mRoomRate = mRoomRate;
			vRow.Parameters.mNumberOfPersons = Format(vCurRes.NumberOfPersons, "ND=6");
			vSpreadsheet.Put(vRow);
		EndIf;
	EndDo;
	
	// Cancellation reply
	vRepl = vTemplate.GetArea("CancellationReply");
	vCancellationReply = "";
	If Not IsBlankString(SelReservation.ConfirmationReply) Then
		If Not IsBlankString(vCancellationReply) Then
			vCancellationReply = vCancellationReply + Chars.LF + Chars.LF + TrimAll(SelReservation.ConfirmationReply);
		Else
			vCancellationReply = TrimAll(SelReservation.ConfirmationReply);
		EndIf;
	EndIf;
	If ValueIsFilled(SelReservation.ReservationStatus) And Not IsBlankString(SelReservation.ReservationStatus.ReservationConditions) Then
		vCancellationReply = vCancellationReply + Chars.LF + cmNStr(SelReservation.ReservationStatus.ReservationConditions, SelLanguage);
	EndIf;
	vRepl.Parameters.mCancellationReply = vCancellationReply;
	vSpreadsheet.Put(vRepl);
	
	// Footer
	vFooter = vTemplate.GetArea("Footer");
	vFooter.Parameters.mReservationDivisionContacts = vHotelObj.pmGetHotelReservationDivisionContacts(SelLanguage);
	vFooter.Parameters.mAuthor = ?(ValueIsFilled(SelReservation.Author), SelReservation.Author.GetObject().pmGetEmployeeDescription(SelLanguage), "");
	vNumOfEmptyLines = 0;
	vEmptyRow = vTemplate.GetArea("EmptyRow");
	vFooterArray = New Array();
	vFooterArray.Add(vFooter);
	Try
		While vSpreadsheet.CheckPut(vFooterArray) Do
			vFooterArray.Insert(0, vEmptyRow);
			vNumOfEmptyLines = vNumOfEmptyLines + 1;
		EndDo;
	Except
	EndTry;
	If vNumOfEmptyLines > 0 Then
		vFooterArray.Delete(0);
	EndIf;
	For Each vArea In vFooterArray Do
		vSpreadsheet.Put(vArea);
	EndDo;

	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Portrait, True);
	// Check authorities
	cmSetSpreadsheetProtection(vSpreadsheet);
EndProcedure //  pmPrintCancellation

// -----------------------------------------------------------------------------
Procedure pmPrintPaymentOrder(vSpreadsheet, SelReservation, SelReservationObj, SelReservations, SelServicesFilter, SelLanguage, SelObjectPrintForm) Export
	// Basic checks
	If Not ValueIsFilled(SelReservation.Hotel) Then
		Raise String(Ref) + " - " + NStr("ru='У документа должна быть указана гостиница!';de='Bei dem Dokument muss das Hotel angegeben sein!';en='Hotel attribute should be filled!'");
	EndIf;
	If Not ValueIsFilled(SelLanguage) Then
		SelLanguage = SessionParameters.CurrentLanguage;
	EndIf;
	
	// Choose template
	vResObj = SelReservation.GetObject();
	vSpreadsheet.Clear();
	vTemplate = vResObj.GetTemplate("PaymentOrderRu");
	// Load external template if any
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(SelObjectPrintForm);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	EndIf;
	
	// Get template area
	vArea = vTemplate.GetArea("PaymentOrder");
	
	// Initialize area parameters
	mCompanyName = "";
	mCompanyBank = "";
	mCompanyBankAccount = "";
	mCompanyBankAttributes = "";
	mClientName = "";
	mClientAddress = "";
	mPaymentText = "";
	mSum = "";
	
	// Guest group code
	mGuestGroupCode = TrimAll(SelReservation.GuestGroup.Code);
	vHotelPrefix = Catalogs.Hotels.pmGetPrefix(SelReservation.Hotel);
	If Not IsBlankString(vHotelPrefix) And SelReservation.Hotel.ShowHotelPrefixBeforeGroupCode Then
		mGuestGroupCode = vHotelPrefix + mGuestGroupCode;
	EndIf;
	
	// Company
	If ValueIsFilled(SelReservation.Company) Then
		vCompanyObj = SelReservation.Company.GetObject();
		mCompanyName = vCompanyObj.pmGetCompanyPrintName(SelLanguage);
		
		mCompanyTIN = TrimAll(vCompanyObj.TIN);
		mCompanyKPP = TrimAll(vCompanyObj.KPP);
		
		If ValueIsFilled(vCompanyObj.BankAccount) Then
			vAccount = vCompanyObj.BankAccount;
			mCompanyBank = vAccount.BankName;
			mCompanyBankAccount = vAccount.AccountNumber;
			mCompanyBankAttributes = "к/с №" + vAccount.BankCorrAccountNumber + " " + 
			                         TrimAll(vAccount.BankName) + " " + TrimAll(vAccount.BankCity) + 
			                         " БИК " + TrimAll(vAccount.BankBIC) + " ИНН " + TrimAll(vCompanyObj.TIN);
		EndIf;
	EndIf;
	
	// Create table of charging rules
	vChargingRules = SelReservation.ChargingRules.Unload();
	If Not SelReservation.IgnoreGroupChargingRules Then
		cmAddGuestGroupChargingRules(vChargingRules, SelReservation.GuestGroup);
	EndIf;
	
	// Build table of all guest group services
	vServices = Undefined;
	vReservations = SelReservation.GuestGroup.GetObject().pmGetReservations(True, True, False, False, Undefined, ?(SelReservations = Undefined, Undefined, ?(SelReservations.Count() > 1, SelReservations, Undefined)));
	For Each vRes In vReservations Do
		If ValueIsFilled(vRes.Status) And 
		   (vRes.Status.IsActive Or vRes.Status.IsCheckIn Or vRes.Status.IsPreliminary) Then
			vCurRes = vRes.Reservation;
			If vServices = Undefined Then
				vServices = vCurRes.Services.Unload();
				vServices.Clear();
			EndIf;
			vCurResServices = cmGetReservationServices(vCurRes);
			// Filter services by customer
			If SelServicesFilter > 0 Then
				i = 0;
				While i < vCurResServices.Count() Do
					vResSrvRow = vCurResServices.Get(i);
					If SelServicesFilter = 1 Then
						If ValueIsFilled(vResSrvRow.Folio.Customer) Then
							vCurResServices.Delete(i);
							Continue;
						EndIf;
					ElsIf SelServicesFilter = 2 Then
						If Not ValueIsFilled(vResSrvRow.Folio.Customer) Then
							vCurResServices.Delete(i);
							Continue;
						EndIf;
					EndIf;
					i = i + 1;
				EndDo;
			EndIf;
			// Merge all services to the one value table
			For Each vResSrvRow In vCurResServices Do
				vSrvRow = vServices.Add();
				FillPropertyValues(vSrvRow, vResSrvRow);
			EndDo;
		EndIf;
	EndDo;
	vTotalSum = 0;
	vTotalVATSum = 0;
	If vServices <> Undefined Then
		vTotalSum = vServices.Total("Sum") - vServices.Total("DiscountSum");
		vTotalVATSum = vServices.Total("VATSum");
		If SelReservation.Customer = SelReservation.Agent And ValueIsFilled(SelReservation.Agent) And 
		   vServices.Total("CommissionSum") <> 0 And 
		   cmCustomerIsPayer(vChargingRules, SelReservation.Customer, SelReservation.Contract, SelReservation.GuestGroup, SelReservation.IgnoreGroupChargingRules) Then
			vTotalSum = vTotalSum - vServices.Total("CommissionSum");
		EndIf;		
	EndIf;
	
	// Get first folio in charging rules
	vFolio = Undefined;
	vFolioNumber = "";
	If SelReservationObj.ChargingRules.Count() = 0 Then
		Raise String(Ref) + " - " + NStr("ru='Не заданы правила начислений!';de='Die Anrechnungsregeln sind nicht angegeben!';en='Charging rules are not set!'");
	Else
		If ValueIsFilled(SelReservationObj.ChargingRules[0].ChargingFolio) Then
			vFolio = SelReservationObj.ChargingRules[0].ChargingFolio;
			vFolioNumber = cmGetDocumentNumberPresentation(vFolio.Number);
		EndIf;
	EndIf;
	
	// Get payment order sum
	mSum = cmFormatSum(vTotalSum, ?(ValueIsFilled(vFolio), vFolio.FolioCurrency, SelReservation.Hotel.FolioCurrency));
	
	// No VAT
	vNoVAT = "";
	If vTotalVATSum = 0 Then
		vNoVAT = cmNStr("en='. No VAT';de='. No VAT';ru='. Без НДС'", SelLanguage);
	EndIf;
	
	// Payment text
	mPaymentText = NStr("en='Reservation fee N';ru='Оплата брони №';de='Bezahlung der Reservierung Nr.'", SelLanguage) + mGuestGroupCode + NStr("en=', folio N';ru=', фолио №';de=', Folio Nr.'", SelLanguage) + vFolioNumber + vNoVAT + ".";
	
	// Client name and address
	If ValueIsFilled(SelReservation.Guest) Then
		vGuest = SelReservation.Guest;
		mClientName = TrimAll(vGuest.FullName);
		vGuestAddress = cmParseAddress(vGuest.Address);
		mClientAddress = "";
		If ValueIsFilled(vGuestAddress.PostCode) Then
			mClientAddress = vGuestAddress.PostCode;
		EndIf;
		If ValueIsFilled(vGuestAddress.Region) Then
			mClientAddress = TrimAll(mClientAddress) + " " + vGuestAddress.Region;
		EndIf;
		If ValueIsFilled(vGuestAddress.Area) Then
			mClientAddress = TrimAll(mClientAddress) + " " + vGuestAddress.Area;
		EndIf;
		If ValueIsFilled(vGuestAddress.City) Then
			mClientAddress = TrimAll(mClientAddress) + " " + vGuestAddress.City;
		EndIf;
		If ValueIsFilled(vGuestAddress.Street) Then
			mClientAddress = TrimAll(mClientAddress) + " " + vGuestAddress.Street;
		EndIf;
		If ValueIsFilled(vGuestAddress.House) Then
			mClientAddress = TrimAll(mClientAddress) + " " + vGuestAddress.House;
		EndIf;
		If ValueIsFilled(vGuestAddress.Flat) Then
			mClientAddress = TrimAll(mClientAddress) + " " + vGuestAddress.Flat;
		EndIf;
	EndIf;
	
	// Set parameters and put payment order section
	vArea.Parameters.mCompanyName = mCompanyName;
	vArea.Parameters.mCompanyBank = mCompanyBank;
	vArea.Parameters.mCompanyBankAccount = mCompanyBankAccount;
	vArea.Parameters.mCompanyBankAttributes = mCompanyBankAttributes;
	vArea.Parameters.mClientName = mClientName;
	vArea.Parameters.mClientAddress = mClientAddress;
	vArea.Parameters.mPaymentText = mPaymentText;
	vArea.Parameters.mSum = mSum;
	vSpreadsheet.Put(vArea);
	
	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Portrait, True);
	// Check authorities
	cmSetSpreadsheetProtection(vSpreadsheet);
EndProcedure //  pmPrintPaymentOrder

// -----------------------------------------------------------------------------
Procedure pmPrintExpressCheckInInvitation(vSpreadsheet, SelReservation, SelReservations, SelShowConfirmationForCurrentReservationOnly, SelLanguage, SelObjectPrintForm) Export
	// Basic checks
	If Not ValueIsFilled(SelReservation.Hotel) Then
		Raise String(Ref) + " - " + NStr("ru='У документа должна быть указана гостиница!';de='Bei dem Dokument muss das Hotel angegeben sein!';en='Hotel attribute should be filled!'");
	EndIf;
	If Not ValueIsFilled(SelLanguage) Then
		SelLanguage = SessionParameters.CurrentLanguage;
	EndIf;
	
	// Some settings
	vShowReservationNumbersInConfirmation = cmCheckUserPermissions("ShowReservationNumbersInConfirmation");
	
	// Fill and check grouping parameter
	vParameter = Upper(TrimAll(SelObjectPrintForm.Parameter));
	
	// Choose template
	vResObj = SelReservation.GetObject();
	vSpreadsheet.Clear();
	If ValueIsFilled(SelLanguage) Then
		If SelLanguage = Catalogs.Languages.EN Then
			vTemplate = vResObj.GetTemplate("ReservationExpressCheckInInvitationEn");
		ElsIf SelLanguage = Catalogs.Languages.DE Then
			vTemplate = vResObj.GetTemplate("ReservationExpressCheckInInvitationDe");
		ElsIf SelLanguage = Catalogs.Languages.RU Then
			vTemplate = vResObj.GetTemplate("ReservationExpressCheckInInvitationRu");
		Else
			Raise String(Ref) + " - " + 
			      NStr("ru = 'Не найден шаблон печатной формы приглашения на экспресс-заселение для языка " + SelLanguage.Code + "!'; 
			           |de = 'No reservation express check-in invitation print form template found for the " + SelLanguage.Code + " language!'; 
			           |en = 'No reservation express check-in invitation print form template found for the " + SelLanguage.Code + " language!'");
		EndIf;
	Else
		vTemplate = vResObj.GetTemplate("ReservationExpressCheckInInvitationRu");
	EndIf;
	// Load external template if any
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(SelObjectPrintForm);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	EndIf;
		
	// Load pictures
	vLogoIsSet = False;
	vLogo = New Picture;
	If ValueIsFilled(SelReservation.Hotel) Then
		If SelReservation.Hotel.Logo <> Undefined Then
			vLogo = SelReservation.Hotel.Logo.Get();
			If vLogo = Undefined Then
				vLogo = New Picture;
			Else
				vLogoIsSet = True;
			EndIf;
		EndIf;
	EndIf;
	
	// Guests in group
	vReservations = SelReservation.GuestGroup.GetObject().pmGetReservations(True, True, False, False, ?(SelShowConfirmationForCurrentReservationOnly, SelReservation, Undefined), ?(SelShowConfirmationForCurrentReservationOnly, Undefined, ?(SelReservations = Undefined, Undefined, ?(SelReservations.Count() > 1, SelReservations, Undefined))));
	For Each vRes In vReservations Do
		If ValueIsFilled(vRes.Status) And vRes.Status.IsActive Then
			vCurRes = vRes.Reservation;
			vCurResObj = vCurRes.GetObject();

			// Header
			vHeader = vTemplate.GetArea("TopHeader");
			// Hotel
			vHotelObj = vCurRes.Hotel.GetObject();
			mHotelPrintName = vHotelObj.pmGetHotelPrintName(SelLanguage);
			mHotelPostAddressPresentation = vHotelObj.pmGetHotelPostAddressPresentation(SelLanguage);
			mHotelPhones = TrimAll(vCurRes.Hotel.Phones);
			mHotelFax = TrimAll(vCurRes.Hotel.Fax);
			mHotelEMail = TrimAll(vCurRes.Hotel.EMail);
			// Guest
			mGuestName = "";
			If ValueIsFilled(vCurRes.Guest) Then
				mGuestName = TrimR(vCurRes.Guest.FullName);
			EndIf;
			// E-Mail
			mEMail = "";
			If Not IsBlankString(vCurRes.EMail) Then
				mEMail = TrimAll(vCurRes.EMail);
			EndIf;
			If ValueIsFilled(vCurRes.Customer) Then
				If IsBlankString(mEMail) Then
					mEMail = TrimAll(vCurRes.Customer.EMail);
				EndIf;
			ElsIf ValueIsFilled(vCurRes.GuestGroup) And ValueIsFilled(vCurRes.GuestGroup.Client) Then
				If IsBlankString(mEMail) Then
					mEMail = TrimAll(vCurRes.GuestGroup.Client.EMail);
				EndIf;
			EndIf;
			// Document date
			mDate = Format(vCurRes.Date, "DF='dd.MM.yyyy'");
			// Guest group code
			mGuestGroupCode = TrimAll(vCurRes.GuestGroup.Code);
			vHotelPrefix = Catalogs.Hotels.pmGetPrefix(vCurRes.Hotel);
			If Not IsBlankString(vHotelPrefix) And vCurRes.Hotel.ShowHotelPrefixBeforeGroupCode Then
				mGuestGroupCode = vHotelPrefix + mGuestGroupCode;
			EndIf;
			mReservationNumber = cmGetDocumentNumberPresentation(vCurRes.Number);
			// Set parameters and put report section
			vHeader.Parameters.mHotelPrintName = mHotelPrintName;
			vHeader.Parameters.mHotelPostAddressPresentation = mHotelPostAddressPresentation;
			vHeader.Parameters.mHotelPhones = mHotelPhones;
			vHeader.Parameters.mHotelFax = mHotelFax;
			vHeader.Parameters.mHotelEMail = mHotelEMail;
			vHeader.Parameters.mGuestName = mGuestName;
			vHeader.Parameters.mEMail = mEMail;
			vHeader.Parameters.mDate = mDate;
			vHeader.Parameters.mGuestGroupCode = mGuestGroupCode;
			vHeader.Parameters.mReservationNumber = mReservationNumber;
			// Logo
			If vLogoIsSet Then
				vHeader.Drawings.Logo.Print = True;
				vHeader.Drawings.Logo.Picture = vLogo;
			Else
				vHeader.Drawings.Delete(vHeader.Drawings.Logo);
			EndIf;
			// Put top header		
			vSpreadsheet.Put(vHeader);
			
			// Print QR code
			Try
				vQRCodeArea = vTemplate.GetArea("QRCode");
				vResUUIDStr = String(vCurRes.UUID());
				vQRCodeControl = vQRCodeArea.Drawings.QRCodeControl;
				vQRCodeControl.Picture = cmGetQRCodePicture(vResUUIDStr);
				vSpreadsheet.Put(vQRCodeArea);
			Except
			EndTry;
			
			// Print reservation data
			vResDataArea = vTemplate.GetArea("ReservationData");
			vResDataArea.Parameters.mReservationData = Format(vCurRes.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(vCurRes.CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ", " + vCurRes.RoomType.GetObject().pmGetRoomTypeDescription(SelLanguage);
			vSpreadsheet.Put(vResDataArea);
			
			// Footer
			vFooter = vTemplate.GetArea("Footer");
			vNumOfEmptyLines = 0;
			vEmptyRow = vTemplate.GetArea("EmptyRow");
			vFooterArray = New Array();
			vFooterArray.Add(vFooter);
			Try
				While vSpreadsheet.CheckPut(vFooterArray) Do
					vFooterArray.Insert(0, vEmptyRow);
					vNumOfEmptyLines = vNumOfEmptyLines + 1;
				EndDo;
			Except
			EndTry;
			If vNumOfEmptyLines > 0 Then
				vFooterArray.Delete(0);
			EndIf;
			For Each vArea In vFooterArray Do
				vSpreadsheet.Put(vArea);
			EndDo;
			
			// Add page break
			vSpreadsheet.PutHorizontalPageBreak();
		EndIf;
	EndDo;

	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Portrait, True);
	// Check authorities
	cmSetSpreadsheetProtection(vSpreadsheet);
EndProcedure //  pmPrintExpressCheckInInvitation

#EndRegion

#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel, pWriteMode, pPostingMode)
	Var vMessage, vAttributeInErr;
	If DataExchange.Load Then
		Return;
	EndIf;
	If pWriteMode = DocumentWriteMode.Posting Then
		pCancel	= pmCheckDocumentAttributes(ThisObject, Posted, vMessage, vAttributeInErr, True);
		If pCancel Then
			WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
			tcCommonFunctionOnClientServer.UserMessage(NStr(vMessage));
			Raise String(Ref) + " - " + NStr(vMessage);
		Else
			vLastDocState = pmGetPreviousObjectState(CurrentSessionDate(), True);

			// Check that status was changed and that change is allowed
			StatusHasChanged = False;
			If vLastDocState <> Undefined Then
				If vLastDocState.GuestGroup <> GuestGroup Then
					AdditionalProperties.Insert("OldGuestGroup", vLastDocState.GuestGroup);
				Else
					AdditionalProperties.Insert("OldGuestGroup", Undefined);
				EndIf;
				AdditionalProperties.Insert("OldClient", vLastDocState.Guest);
				AdditionalProperties.Insert("OldClientCitizenship", vLastDocState.Citizenship);
				AdditionalProperties.Insert("OldClientRegion", vLastDocState.Region);
				AdditionalProperties.Insert("OldClientCity", vLastDocState.City);
				AdditionalProperties.Insert("OldClientAge", vLastDocState.Age);
				AdditionalProperties.Insert("OldTouristicTaxExemptionReason", vLastDocState.TouristicTaxExemptionReason);
				AdditionalProperties.Insert("OldTouristicTaxExemptionReasonFillDate", vLastDocState.TouristicTaxExemptionReasonFillDate);
				If Not AdditionalProperties.Property("InfoBaseUpdateMode") And Not AdditionalProperties.Property("CloseOfDayMode") Then
					If ReservationStatus <> vLastDocState.ReservationStatus Then
						StatusHasChanged = True;
						If ValueIsFilled(vLastDocState.ReservationStatus) Then
							vPrevStatus = vLastDocState.ReservationStatus;
							If vPrevStatus.TransitionsAllowed.Count() > 0 Then
								If vPrevStatus.TransitionsAllowed.Find(ReservationStatus, "ReservationStatus") = Undefined Then
									Raise String(Ref) + " - " + NStr("en='Status transition from '; ru='Переход статуса из '; de='Statusübergang von '") + TrimAll(vPrevStatus) + NStr("en=' to '; ru=' в '; de=' nach '") + TrimAll(ReservationStatus) + NStr("en=' is forbidden!'; ru=' запрещен!'; de=' ist verboten!'");
								EndIf;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			Else
				AdditionalProperties.Insert("OldGuestGroup", Undefined);
				AdditionalProperties.Insert("OldClient", Undefined);
				AdditionalProperties.Insert("OldClientCitizenship", Undefined);
				AdditionalProperties.Insert("OldClientRegion", Undefined);
				AdditionalProperties.Insert("OldClientCity", Undefined);
				AdditionalProperties.Insert("OldClientAge", Undefined);
				AdditionalProperties.Insert("OldTouristicTaxExemptionReason", Undefined);
				AdditionalProperties.Insert("OldTouristicTaxExemptionReasonFillDate", Undefined);
				StatusHasChanged = True;
			EndIf;
			
			// Check new manual services and fill author and date for them
			vProcessAllManualServices = True;
			If vLastDocState <> Undefined Then
				vLastDocStateServices = vLastDocState.Services.Get();
				If vLastDocStateServices <> Undefined Then
					vProcessAllManualServices = False;
					vManualServices = Services.FindRows(New Structure("IsManual, IsManualAuthor, IsManualDate", True, Catalogs.Employees.EmptyRef(), '00010101'));
					For Each vManualServicesRow In vManualServices Do
						// Search service in the previous services state list
						vLastDocStateManualServices = vLastDocStateServices.FindRows(New Structure("IsManual, AccountingDate, Service", True, vManualServicesRow.AccountingDate, vManualServicesRow.Service));
						If vLastDocStateManualServices.Count() = 0 Then
							vManualServicesRow.IsManualAuthor = SessionParameters.CurrentUser;
							vManualServicesRow.IsManualDate = CurrentSessionDate();
						EndIf;
					EndDo;
				EndIf;
			EndIf;
			If vProcessAllManualServices Then
				vManualServices = Services.FindRows(New Structure("IsManual, IsManualAuthor, IsManualDate", True, Catalogs.Employees.EmptyRef(), '00010101'));
				For Each vManualServicesRow In vManualServices Do
					vManualServicesRow.IsManualAuthor = SessionParameters.CurrentUser;
					vManualServicesRow.IsManualDate = CurrentSessionDate();
				EndDo;
			EndIf;
			
			// Process service packages added to the document manually and fill author and date for them
			vServicePackages = ServicePackages.Unload(, "ServicePackage");
			vServicePackages.GroupBy("ServicePackage", );
			If ValueIsFilled(ServicePackage) And Not ServicePackage.IsMealBoardTerm Then
				If vServicePackages.Find(ServicePackage, "ServicePackage") = Undefined Then
					vServicePackagesRow = vServicePackages.Add();
					vServicePackagesRow.ServicePackage = ServicePackage;
				EndIf;
			EndIf;
			vProcessAllManualPackages = True;
			If vLastDocState <> Undefined Then
				vLastDocStateServicePackages = vLastDocState.ServicePackages.Get();
				If vLastDocStateServicePackages <> Undefined Then
					vProcessAllManualPackages = False;
					vLastDocStateServicePackages.GroupBy("ServicePackage", );
					If ValueIsFilled(vLastDocState.ServicePackage) And Not vLastDocState.ServicePackage.IsMealBoardTerm Then
						If vLastDocStateServicePackages.Find(vLastDocState.ServicePackage, "ServicePackage") = Undefined Then
							vLastDocStateServicePackagesRow = vLastDocStateServicePackages.Add();
							vLastDocStateServicePackagesRow.ServicePackage = vLastDocState.ServicePackage;
						EndIf;
					EndIf;
					For Each vServicePackagesRow In vServicePackages Do
						If ValueIsFilled(vServicePackagesRow.ServicePackage) Then
							If vLastDocStateServicePackages.Find(vServicePackagesRow.ServicePackage, "ServicePackage") = Undefined Then
								vSPServicesRows = Services.FindRows(New Structure("ServicePackage, IsManualAuthor, IsManualDate", vServicePackagesRow.ServicePackage, Catalogs.Employees.EmptyRef(), '00010101'));
								For Each vSPServicesRow In vSPServicesRows Do
									vSPServicesRow.IsManualAuthor = SessionParameters.CurrentUser;
									vSPServicesRow.IsManualDate = CurrentSessionDate();
								EndDo;
							EndIf;
						EndIf;
					EndDo;
				EndIf;
			EndIf;
			If vProcessAllManualPackages Then
				For Each vServicePackagesRow In vServicePackages Do
					If ValueIsFilled(vServicePackagesRow.ServicePackage) Then
						vSPServicesRows = Services.FindRows(New Structure("ServicePackage, IsManualAuthor, IsManualDate", vServicePackagesRow.ServicePackage, Catalogs.Employees.EmptyRef(), '00010101'));
						For Each vSPServicesRow In vSPServicesRows Do
							vSPServicesRow.IsManualAuthor = SessionParameters.CurrentUser;
							vSPServicesRow.IsManualDate = CurrentSessionDate();
						EndDo;
					EndIf;
				EndDo;
			EndIf;
			
			// Fill default beds
			If ValueIsFilled(RoomType) And ValueIsFilled(RoomType.DefaultBedsSetup) And Not ValueIsFilled(BedsSetup) Then
				BedsSetup = RoomType.DefaultBedsSetup;
			EndIf;
			
			// Fill room property codes
			vRoomPropertiesCodes = "";
			vRoomPropertiesDescriptions = "";
			For Each vRoomPropertyRow In RoomProperties Do
				If ValueIsFilled(vRoomPropertyRow.RoomProperty) Then
					vRoomProperty = vRoomPropertyRow.RoomProperty;
					If IsBlankString(vRoomPropertiesCodes) Then
						vRoomPropertiesCodes = TrimAll(vRoomProperty.Code);
						vRoomPropertiesDescriptions = TrimAll(vRoomProperty.Description);
					Else
						vRoomPropertiesCodes = TrimAll(vRoomPropertiesCodes) + Chars.LF + TrimAll(vRoomProperty.Code);
						vRoomPropertiesDescriptions = TrimAll(vRoomPropertiesDescriptions) + Chars.LF + TrimAll(vRoomProperty.Description);
					EndIf;
				EndIf;
			EndDo;
			If TrimAll(RoomPropertiesCodes) <> vRoomPropertiesCodes Then
				RoomPropertiesCodes = vRoomPropertiesCodes;
			EndIf;
			If TrimAll(RoomPropertiesDescriptions) <> vRoomPropertiesDescriptions Then
				RoomPropertiesDescriptions = vRoomPropertiesDescriptions;
			EndIf;
			
			// Check dates
			If CheckInDate <> cm1SecondShift(CheckInDate) Then
				CheckInDate = cm1SecondShift(CheckInDate);
			EndIf;
			If CheckOutDate <> cm0SecondShift(CheckOutDate) Then
				CheckOutDate = cm0SecondShift(CheckOutDate);
			EndIf;
			
			// Check if reservation is complimentary
			vIsComplimentary = False;
			If ValueIsFilled(RoomType) And Not RoomType.IsVirtual And Not RoomType.DoesNotAffectRoomRevenueStatistics Then
				If ValueIsFilled(AccommodationType) And (AccommodationType.Type = Enums.AccomodationTypes.Room Or AccommodationType.Type = Enums.AccomodationTypes.Beds) Then
					vRoomRevenueTotals = 0;
					vRoomRateServicesRows = Services.FindRows(New Structure("IsRoomRevenue, IsInPrice", True, True));
					For Each vRoomRateServicesRow In vRoomRateServicesRows Do
						vRoomRevenueTotals = vRoomRevenueTotals + (vRoomRateServicesRow.Sum - vRoomRateServicesRow.DiscountSum);
					EndDo;
					If vRoomRevenueTotals = 0 Then
						vIsComplimentary = True;
					EndIf;
				EndIf;
			EndIf;
			If vIsComplimentary <> IsComplimentary Then
				IsComplimentary = vIsComplimentary;
			EndIf;
			
			// Update data in the first change history record for check-in date
			pmUpdateFirstChangeHistoryRecord();		
			
			// Save is for folio split flag before document write
			AdditionalProperties.Insert("IsForFolioSplit", Ref.IsForFolioSplit);
			
			// Call external user exit procedure to fill bound document attributes
			vBeforeWriteUserExit = Catalogs.ExternalDataProcessors.ReservationBeforeWrite;
			If vBeforeWriteUserExit.ExternalProcessingType = Enums.ExternalProcessingTypes.Algorithm And Not IsBlankString(vBeforeWriteUserExit.Algorithm) Then
				SetSafeMode(True);
				Execute(TrimR(vBeforeWriteUserExit.Algorithm));
				SetSafeMode(False);
			EndIf;
		EndIf;
	Else
		If pWriteMode = DocumentWriteMode.UndoPosting Or DeletionMark Then
			If Not cmCheckUserPermissions("HavePermissionToSetDeletionMarkForReservations") Then
				pCancel = True;
				tcCommonFunctionOnClientServer.UserMessage(NStr("en='You do not have rights to mark reservation for deletion! Change reservation status instead.';ru='Нет прав на пометку брони на удаление! Вместо удаления измените статус брони.';de='Sie haben kein Recht, Reservierung für Löschung zu markieren! Ändern Sie stattdessen den reservierungsstatus.'"));
				Return;
			EndIf;
		EndIf;
		If ValueIsFilled(Hotel) And Hotel.DoNotEditSettledDocs And DoCharging And 
		  (pWriteMode = DocumentWriteMode.UndoPosting Or DeletionMark) And 
		  (Services.Total("Sum") <> 0 Or Services.Total("Quantity") <> 0) And 
		   cmGetDocumentCharges(Ref, Undefined, Undefined, Hotel, Undefined, True).Count() > 0 Then
			vDocBalanceIsZero = False;
			vDocBalancesRow = cmGetDocumentCurrentAccountsReceivableBalance(Ref);
			If vDocBalancesRow <> Undefined Then
				If vDocBalancesRow.SumBalance = 0 And vDocBalancesRow.QuantityBalance = 0 Then
					vDocBalanceIsZero = True;
				EndIf;
			Else
				vDocBalanceIsZero = True;
			EndIf;
			If vDocBalanceIsZero Then
				pCancel = True;
				tcCommonFunctionOnClientServer.UserMessage(NStr("en='All reservation charges are closed by settlements! Reservation is read only.';ru='Все начисления брони уже закрыты актами об оказании услуг! Редактирование такой брони запрещено.';de='Alle Anrechnungen der Reservierung wurden bereits durch Übergabeprotokolle über Dienstleistungserbringung geschlossen! Die Bearbeitung einer solchen Reservierung ist verboten.'"));
				Return;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(ReservationStatus) Then
		If (Not ReservationStatus.IsActive And 
            Not ReservationStatus.IsCheckIn And 
            Not ReservationStatus.IsInWaitingList And 
		    Not ReservationStatus.IsPreliminary) Or 
		   ReservationStatus.IsAnnulation Then
			If Not ValueIsFilled(DateOfAnnulation) Then
				DateOfAnnulation = CurrentSessionDate();
				AuthorOfAnnulation = SessionParameters.CurrentUser;
			EndIf;
		Else
			If ValueIsFilled(DateOfAnnulation) Then
				DateOfAnnulation = '00010101';
				AuthorOfAnnulation = Catalogs.Employees.EmptyRef();
				AnnulationReason = Undefined;
			EndIf;
		EndIf;
	EndIf;
	// Check DoCharging flag 
	pmSetDoCharging();
	// Fill guest full name (used to sort reservation's list by guest names)
	If ValueIsFilled(Guest) Then
		GuestFullName = Guest.FullName;
	Else
		GuestFullName = "";
	EndIf;
	// Check 1 second shift for check-in and check-out dates
	If cm1SecondShift(CheckInDate) <> CheckInDate Then
		CheckInDate = cm1SecondShift(CheckInDate);
	EndIf;
	If cm0SecondShift(CheckOutDate) <> CheckOutDate Then
		CheckOutDate = cm1SecondShift(CheckOutDate);
	EndIf;
	// Check number of rooms and number of persons
	If ValueIsFilled(AccommodationType) And AccommodationType.Type = Enums.AccomodationTypes.Room And NumberOfRooms = 0 Then
		pmCalculateResources();
	EndIf;
	// Calculate document sort code
	SortCode = cmCalculateReservationSortCode(ThisObject);
EndProcedure //  BeforeWrite

// -----------------------------------------------------------------------------
Procedure BeforeDelete(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	// Remove room inventory movements, recalculate room inventory balances and delete charges
	If Posted Then
		If ValueIsFilled(Hotel) And Hotel.DoNotEditSettledDocs And DoCharging And 
		  (Services.Total("Sum") <> 0 Or Services.Total("Quantity") <> 0) And 
		   cmGetDocumentCharges(Ref, Undefined, Undefined, Hotel, Undefined, True).Count() > 0 Then
			vDocBalanceIsZero = False;
			vDocBalancesRow = cmGetDocumentCurrentAccountsReceivableBalance(Ref);
			If vDocBalancesRow <> Undefined Then
				If vDocBalancesRow.SumBalance = 0 And vDocBalancesRow.QuantityBalance = 0 Then
					vDocBalanceIsZero = True;
				EndIf;
			Else
				vDocBalanceIsZero = True;
			EndIf;
			If vDocBalanceIsZero Then
				pCancel = True;
				tcCommonFunctionOnClientServer.UserMessage(NStr("en='All reservation charges are closed by settlements! Reservation is read only.';ru='Все начисления брони уже закрыты актами об оказании услуг! Редактирование такой брони запрещено.';de='Alle Anrechnungen der Reservierung wurden bereits durch Übergabeprotokolle über Dienstleistungserbringung geschlossen! Die Bearbeitung einer solchen Reservierung ist verboten.'"));
				Return;
			EndIf;
		EndIf;
		pmUndoPosting(pCancel);
	EndIf;
EndProcedure //  BeforeDelete

// -----------------------------------------------------------------------------
Procedure UndoPosting(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	// Remove room inventory movements, recalculate room inventory balances and delete charges
	pmUndoPosting(pCancel);
	// Save to reservation change history
	If Not Posted And Not DeletionMark Then
		pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
	EndIf;
EndProcedure //  UndoPosting

// -----------------------------------------------------------------------------
Procedure OnSetNewNumber(pStandardProcessing, pPrefix)
	vPrefix = "";
	If ValueIsFilled(SessionParameters.CurrentUser) Then
		vCU = SessionParameters.CurrentUser;
		If ValueIsFilled(vCU.Parent) Then
			vCUParent = vCU.Parent;
			If Not IsBlankString(vCUParent.Prefix) Then
				vPrefix = TrimAll(vCUParent.Prefix);
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vPrefix) Then
		If ValueIsFilled(Hotel) Then
			vPrefix = Catalogs.Hotels.pmGetPrefix(Hotel);
		ElsIf ValueIsFilled(SessionParameters.CurrentHotel) Then
			vPrefix = Catalogs.Hotels.pmGetPrefix(SessionParameters.CurrentHotel);
		EndIf;
	EndIf;
	If vPrefix <> "" Then
		pPrefix = vPrefix;
	EndIf;
EndProcedure //  OnSetNewNumber

// -----------------------------------------------------------------------------
Procedure Posting(pCancel, pPostingMode)
	Var vMessage, vAttributeInErr;
	If DataExchange.Load Then
		Return;
	EndIf;
	// Check if room rates are valid
	pmCheckRoomRates();
	// Check charging rules
	If ValueIsFilled(ReservationStatus) And RoomQuantity = 1 Then
		If ReservationStatus.IsActive Or ReservationStatus.IsPreliminary Then
			// Check reservation chains
			If ValueIsFilled(Guest) Then
				pmCheckReservationChains();
			EndIf;
			// Check if we have to rebuild guest folios
			pmCheckRoomMainFolios();
		EndIf;
	EndIf;
	// Post bound resource reservations
	If ValueIsFilled(ReservationStatus) Then
		vResourceReservations = cmGetChildResourceReservations(Ref, False);
		If Not ReservationStatus.IsActive Or ReservationStatus.IsCheckIn Then
			For Each vResourceReservationsRow In vResourceReservations Do
				vResourceReservationObj = vResourceReservationsRow.Ref.GetObject();
				If vResourceReservationObj.Posted Then
					vResourceReservationObj.AdditionalProperties.Insert("AllowSetDeletionMark", True);
					vResourceReservationObj.SetDeletionMark(True);
				EndIf;
			EndDo;
		Else
			vResourceReservationServices = pmGetResourceServices();
			PostResourceReservations(vResourceReservationServices, vResourceReservations);
		EndIf;
	EndIf;
	// Fill folio parameters
	If ValueIsFilled(ReservationStatus) Then
		If ReservationStatus.IsActive Or ReservationStatus.IsCheckIn Or ReservationStatus.IsPreliminary Then
			FillFolioParameters(pCancel);
		EndIf;
		SetFolioStatuses(pCancel);
	EndIf;
	// Clear forecast registers record sets
	RegisterRecords.SalesForecast.Clear();
	RegisterRecords.ServiceRegistration.Clear();
	RegisterRecords.HotelProductLog.Clear();
	RegisterRecords.AccountsReceivableForecast.Clear();
	// Post to expected customer sales. Those records are used to compare charged 
	// guest group services with planned ones
	PostToExpectedCustomerSales(pCancel);
	// Post to accumulation discount resources
	PostToAccumulatingDiscountResources();
	// Post services if necessary
	ChargeServices(pCancel, pPostingMode);
	// Move guests to the appropriate folder
	MoveGuests(pCancel, pPostingMode);
	// Change room status
	If ValueIsFilled(Hotel.ReservedRoomStatus) Then
		If ReservationStatus.IsActive And 
		   ReservationStatus.DoRoomStatusChange Then
			SetReservedStatusForSpareRooms();
		Else
			ClearReservedStatusFromRooms();
		EndIf;
		// Clear reserved status from rooms that were reserved before current document state
		ClearReservedStatusFromOldRooms();
	EndIf;
	// Recalculate document sort code
	vSortCode = cmCalculateReservationSortCode(ThisObject);
	If vSortCode <> SortCode Then
		SortCode = vSortCode;
	EndIf;
	// Update parent document if it is check-in schedule period
	pmUpdateCheckInSchedule();
	// Write document if it was changed
	If Modified() Then
		Write(DocumentWriteMode.Write);
	EndIf;
	// Delete all unused document folios not in charging rules
	cmDeleteUnusedDocumentFolios(Ref);
	// To the waiting list
	If ValueIsFilled(AccommodationType) And (AccommodationType.Type = Enums.AccomodationTypes.Room Or AccommodationType.Type = Enums.AccomodationTypes.Beds) Then
		PostToWaitingList(pCancel);
		If pCancel Then
			Return;
		EndIf;
	EndIf;
	// Do posting to room inventory
	DoRoomInventoryPosting(pCancel);
	If pCancel Then
		Return;
	EndIf;
	// Post to Pickup register
	PostToPickup();
	// Fill head of group guest, group customer, group period and number of guests checked-in
	FillGroupParameters();
	// Cancel bound orders
	If ValueIsFilled(ReservationStatus) And Not ReservationStatus.IsActive And Not ReservationStatus.IsPreliminary And Not ReservationStatus.IsCheckIn Then
		CancelBoundOrders();
	EndIf;
	// Update hotel product parameters
	pmUpdateHotelProductData();
	// Attach data scans document
	If Not AdditionalProperties.Property("OperationSource") Or 
	   AdditionalProperties.Property("OperationSource") And AdditionalProperties.OperationSource <> "ClientDataScans" Then
		AttachDataScansDocument();
	EndIf;
	// Post to tourist tax register
	pmPostToTouristTax();
	// Recalculate and repost tourist tax for the main guest of the group or for the main guest of the room
	pmRecalculateAndRepostTouristTaxOfTheMainGuest();
	// Process room interface commands
	If ValueIsFilled(Room) Then
		ProcessRoomInterfaceStatuses();
	EndIf;
	// Send change document status SMS
	If StatusHasChanged Then
		StatusHasChanged = False;
		vMessageDeliveryError = "";
		If Not SMS.SendChangeDocumentSatusMessage(Ref, vMessageDeliveryError) Then
			WriteLogEvent(NStr("en='Document.MessageDelivery';ru='Документ.РассылкаСообщений';de='Document.MessageDelivery'"), EventLogLevel.Warning, Metadata(), Ref, vMessageDeliveryError);
			If AdditionalProperties.Property("WarningMessage") Then
				AdditionalProperties.WarningMessage = AdditionalProperties.WarningMessage + ?(IsBlankString(AdditionalProperties.WarningMessage), "", Chars.LF) + vMessageDeliveryError;
			Else
				tcCommonFunctionOnClientServer.UserMessage(vMessageDeliveryError);
			EndIf;
		EndIf;
	EndIf;
	// Switch off automatic write of register records
	RegisterRecords.AccountsReceivableForecast.Write = False;
	RegisterRecords.AccumulatingDiscountResources.Write = False;
	RegisterRecords.ExpectedGuestGroups.Write = False;
	RegisterRecords.HotelProductLog.Write = False;
	RegisterRecords.ReservationWaitingList.Write = False;
	RegisterRecords.RoomInventory.Write = False;
	RegisterRecords.RoomQuotaSales.Write = False;
	RegisterRecords.SalesForecast.Write();
	RegisterRecords.SalesForecast.Write = False;
	RegisterRecords.ServiceRegistration.Write = False;
	RegisterRecords.Pickup.Write = False;
EndProcedure //  Posting

// -----------------------------------------------------------------------------
Procedure PostToPickup()
	If ValueIsFilled(ReservationStatus) And ReservationStatus.IsCheckIn Then
		Return;
	EndIf;
	
	// Get current hotel date
	vCurHotelDate = tcOnServer.GetForecastStartDate(Hotel);
	
	// Read pickup records for the period prior to the current date
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PickupDifference.AccountingDate AS AccountingDate,
	|	PickupDifference.RoomType AS RoomType,
	|	PickupDifference.SourceOfBusiness AS SourceOfBusiness,
	|	PickupDifference.MarketingCode AS MarketingCode,
	|	PickupDifference.Customer AS Customer,
	|	PickupDifference.Agent AS Agent,
	|	PickupDifference.GuestGroup AS GuestGroup,
	|	PickupDifference.RoomRate AS RoomRate,
	|	PickupDifference.ClientType AS ClientType,
	|	PickupDifference.ReportingCurrency AS ReportingCurrency,
	|	PickupDifference.Company AS Company,
	|	PickupDifference.Hotel AS Hotel,
	|	SUM(PickupDifference.Revenue) AS Revenue,
	|	SUM(PickupDifference.RevenueWithoutVAT) AS RevenueWithoutVAT,
	|	SUM(PickupDifference.RoomsRented) AS RoomsRented,
	|	SUM(PickupDifference.BedsRented) AS BedsRented,
	|	SUM(PickupDifference.AdditionalBedsRented) AS AdditionalBedsRented,
	|	SUM(PickupDifference.GuestDays) AS GuestDays
	|FROM
	|	(SELECT
	|		PickupTurnovers.AccountingDate AS AccountingDate,
	|		PickupTurnovers.RoomType AS RoomType,
	|		PickupTurnovers.SourceOfBusiness AS SourceOfBusiness,
	|		PickupTurnovers.MarketingCode AS MarketingCode,
	|		PickupTurnovers.Customer AS Customer,
	|		PickupTurnovers.Agent AS Agent,
	|		PickupTurnovers.GuestGroup AS GuestGroup,
	|		PickupTurnovers.RoomRate AS RoomRate,
	|		PickupTurnovers.ClientType AS ClientType,
	|		PickupTurnovers.ReportingCurrency AS ReportingCurrency,
	|		PickupTurnovers.Company AS Company,
	|		PickupTurnovers.Hotel AS Hotel,
	|		-SUM(PickupTurnovers.Revenue) AS Revenue,
	|		-SUM(PickupTurnovers.RevenueWithoutVAT) AS RevenueWithoutVAT,
	|		-SUM(PickupTurnovers.RoomsRented) AS RoomsRented,
	|		-SUM(PickupTurnovers.BedsRented) AS BedsRented,
	|		-SUM(PickupTurnovers.AdditionalBedsRented) AS AdditionalBedsRented,
	|		-SUM(PickupTurnovers.GuestDays) AS GuestDays
	|	FROM
	|		AccumulationRegister.Pickup AS PickupTurnovers
	|	WHERE
	|		PickupTurnovers.Recorder = &qRecorder
	|		AND PickupTurnovers.Period < &qPeriodTo
	|		AND PickupTurnovers.GuestGroup <> VALUE(Catalog.GuestGroups.EmptyRef)
	|	
	|	GROUP BY
	|		PickupTurnovers.AccountingDate,
	|		PickupTurnovers.RoomType,
	|		PickupTurnovers.SourceOfBusiness,
	|		PickupTurnovers.MarketingCode,
	|		PickupTurnovers.Customer,
	|		PickupTurnovers.Agent,
	|		PickupTurnovers.GuestGroup,
	|		PickupTurnovers.RoomRate,
	|		PickupTurnovers.ClientType,
	|		PickupTurnovers.ReportingCurrency,
	|		PickupTurnovers.Company,
	|		PickupTurnovers.Hotel
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		SalesForecastTurnovers.AccountingDate,
	|		SalesForecastTurnovers.RoomType,
	|		SalesForecastTurnovers.SourceOfBusiness,
	|		SalesForecastTurnovers.MarketingCode,
	|		SalesForecastTurnovers.Customer,
	|		SalesForecastTurnovers.Agent,
	|		SalesForecastTurnovers.GuestGroup,
	|		SalesForecastTurnovers.RoomRate,
	|		SalesForecastTurnovers.ClientType,
	|		SalesForecastTurnovers.ReportingCurrency,
	|		SalesForecastTurnovers.Company,
	|		SalesForecastTurnovers.Hotel,
	|		SUM(SalesForecastTurnovers.Sales),
	|		SUM(SalesForecastTurnovers.SalesWithoutVAT),
	|		SUM(SalesForecastTurnovers.RoomsRented),
	|		SUM(SalesForecastTurnovers.BedsRented),
	|		SUM(SalesForecastTurnovers.AdditionalBedsRented),
	|		SUM(SalesForecastTurnovers.GuestDays)
	|	FROM
	|		AccumulationRegister.SalesForecast AS SalesForecastTurnovers
	|	WHERE
	|		SalesForecastTurnovers.Recorder = &qRecorder
	|		AND SalesForecastTurnovers.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
	|		AND SalesForecastTurnovers.GuestGroup <> VALUE(Catalog.GuestGroups.EmptyRef)
	|		AND SalesForecastTurnovers.AccountingDate >= &qPeriodTo
	|		AND (SalesForecastTurnovers.Sales <> 0
	|				OR SalesForecastTurnovers.SalesWithoutVAT <> 0
	|				OR SalesForecastTurnovers.RoomsRented <> 0
	|				OR SalesForecastTurnovers.BedsRented <> 0
	|				OR SalesForecastTurnovers.AdditionalBedsRented <> 0
	|				OR SalesForecastTurnovers.GuestDays <> 0)
	|	
	|	GROUP BY
	|		SalesForecastTurnovers.AccountingDate,
	|		SalesForecastTurnovers.RoomType,
	|		SalesForecastTurnovers.SourceOfBusiness,
	|		SalesForecastTurnovers.MarketingCode,
	|		SalesForecastTurnovers.Customer,
	|		SalesForecastTurnovers.Agent,
	|		SalesForecastTurnovers.GuestGroup,
	|		SalesForecastTurnovers.RoomRate,
	|		SalesForecastTurnovers.ClientType,
	|		SalesForecastTurnovers.ReportingCurrency,
	|		SalesForecastTurnovers.Company,
	|		SalesForecastTurnovers.Hotel
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		SalesTurnovers.AccountingDate,
	|		SalesTurnovers.RoomType,
	|		SalesTurnovers.SourceOfBusiness,
	|		SalesTurnovers.MarketingCode,
	|		SalesTurnovers.Customer,
	|		SalesTurnovers.Agent,
	|		SalesTurnovers.GuestGroup,
	|		SalesTurnovers.RoomRate,
	|		SalesTurnovers.ClientType,
	|		SalesTurnovers.ReportingCurrency,
	|		SalesTurnovers.Company,
	|		SalesTurnovers.Hotel,
	|		SUM(SalesTurnovers.Sales),
	|		SUM(SalesTurnovers.SalesWithoutVAT),
	|		SUM(SalesTurnovers.RoomsRented),
	|		SUM(SalesTurnovers.BedsRented),
	|		SUM(SalesTurnovers.AdditionalBedsRented),
	|		SUM(SalesTurnovers.GuestDays)
	|	FROM
	|		AccumulationRegister.Sales AS SalesTurnovers
	|	WHERE
	|		SalesTurnovers.ParentDoc = &qRecorder
	|		AND SalesTurnovers.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
	|		AND SalesTurnovers.GuestGroup <> VALUE(Catalog.GuestGroups.EmptyRef)
	|		AND SalesTurnovers.AccountingDate <> &qEmptyDate
	|		AND (SalesTurnovers.Sales <> 0
	|				OR SalesTurnovers.SalesWithoutVAT <> 0
	|				OR SalesTurnovers.RoomsRented <> 0
	|				OR SalesTurnovers.BedsRented <> 0
	|				OR SalesTurnovers.AdditionalBedsRented <> 0
	|				OR SalesTurnovers.GuestDays <> 0)
	|	
	|	GROUP BY
	|		SalesTurnovers.AccountingDate,
	|		SalesTurnovers.RoomType,
	|		SalesTurnovers.SourceOfBusiness,
	|		SalesTurnovers.MarketingCode,
	|		SalesTurnovers.Customer,
	|		SalesTurnovers.Agent,
	|		SalesTurnovers.GuestGroup,
	|		SalesTurnovers.RoomRate,
	|		SalesTurnovers.ClientType,
	|		SalesTurnovers.ReportingCurrency,
	|		SalesTurnovers.Company,
	|		SalesTurnovers.Hotel) AS PickupDifference
	|
	|GROUP BY
	|	PickupDifference.AccountingDate,
	|	PickupDifference.RoomType,
	|	PickupDifference.SourceOfBusiness,
	|	PickupDifference.MarketingCode,
	|	PickupDifference.Customer,
	|	PickupDifference.Agent,
	|	PickupDifference.GuestGroup,
	|	PickupDifference.RoomRate,
	|	PickupDifference.ClientType,
	|	PickupDifference.ReportingCurrency,
	|	PickupDifference.Company,
	|	PickupDifference.Hotel
	|
	|HAVING
	|	(SUM(PickupDifference.Revenue) <> 0
	|		OR SUM(PickupDifference.RevenueWithoutVAT) <> 0
	|		OR SUM(PickupDifference.RoomsRented) <> 0
	|		OR SUM(PickupDifference.BedsRented) <> 0
	|		OR SUM(PickupDifference.AdditionalBedsRented) <> 0
	|		OR SUM(PickupDifference.GuestDays) <> 0)
	|
	|ORDER BY
	|	PickupDifference.AccountingDate";
	vQry.SetParameter("qRecorder", Ref);
	vQry.SetParameter("qPeriodTo", vCurHotelDate);
	vQry.SetParameter("qEmptyDate", '00010101');
	vNewPickupRecords = vQry.Execute().Unload();
	
	// Read old pickup records
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	*
	|FROM
	|	AccumulationRegister.Pickup AS PickupRecords
	|WHERE
	|	PickupRecords.Recorder = &qRecorder
	|	AND PickupRecords.Period < &qPeriodTo
	|ORDER BY
	|	PickupRecords.PointInTime,
	|	PickupRecords.LineNumber";
	vQry.SetParameter("qRecorder", Ref);
	vQry.SetParameter("qPeriodTo", vCurHotelDate);
	vOldPickupRecords = vQry.Execute().Unload();
	
	// Clear array of Pickup register records
	RegisterRecords.Pickup.Clear();
	
	// Add old pickup records to movements collection
	For Each vOldPickupRecordsRow In vOldPickupRecords Do
		vPickupRcd = RegisterRecords.Pickup.Add();
		FillPropertyValues(vPickupRcd, vOldPickupRecordsRow);
	EndDo;
	
	// Add new pickup records to movements collection
	For Each vNewPickupRecordsRow In vNewPickupRecords Do
		vPickupRcd = RegisterRecords.Pickup.Add();
		FillPropertyValues(vPickupRcd, vNewPickupRecordsRow);
		vPickupRcd.Recorder = Ref;
		vPickupRcd.Period = vCurHotelDate;
		vPickupRcd.Author = SessionParameters.CurrentUser;
		vPickupRcd.IsDayuse = ?(BegOfDay(CheckInDate) = BegOfDay(CheckOutDate), True, False);
		vPickupRcd.IsCancel = False;
		vPickupRcd.IsNoShow = False;
		If vPickupRcd.Revenue < 0 Or vPickupRcd.RevenueWithoutVAT < 0 Or 
		   vPickupRcd.RoomsRented < 0 Or vPickupRcd.BedsRented < 0 Or
		   vPickupRcd.AdditionalBedsRented < 0 Or vPickupRcd.GuestDays < 0 Then
			If Not ReservationStatus.IsActive And Not ReservationStatus.IsPreliminary Then
				vPickupRcd.IsCancel = True;
				If ReservationStatus.IsNoShow Then
					vPickupRcd.IsNoShow = True;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
	// Write pickup data
	RegisterRecords.Pickup.Write(True);
EndProcedure // PostToPickup

// -----------------------------------------------------------------------------
Procedure pmPostToTouristTax() Export
	RegisterRecords.TouristTaxToBePaid.Clear();

	If Not ValueIsFilled(GuestGroup) Or ValueIsFilled(GuestGroup) And (Not GuestGroup.TouristicTaxIsCalculatedForMainGroupDocumentOnly Or GuestGroup.TouristicTaxIsCalculatedForMainGroupDocumentOnly And GuestGroup.ClientDoc = Ref) Then
		If ValueIsFilled(ReservationStatus) And (ReservationStatus.IsActive Or ReservationStatus.IsPreliminary) Then
			If ValueIsFilled(TouristicTaxAccountingDate) And (TouristTaxSumInBaseCurrency <> 0 Or ValueIsFilled(TouristicTaxExemptionReason)) Then
				vTTRcd = RegisterRecords.TouristTaxToBePaid.AddReceipt();

				vTTRcd.Period = TouristicTaxAccountingDate;
				vTTRcd.Recorder = Ref;

				vTTRcd.Reservation = Ref;
				vTTRcd.Hotel = Hotel;
				vTTRcd.Company = Company;

				If ValueIsFilled(TouristicTaxExemptionReason) Then
					vTTRcd.TaxAmount = 0;
					vTTRcd.Exemption = 1;
				Else
					vTTRcd.TaxAmount = TouristTaxSumInBaseCurrency;
					vTTRcd.Exemption = 0;
				EndIf;

				vTTRcd.RateAmount = RateSumInBaseCurrency;
				vTTRcd.DurationInDays = DurationInDays;
				vTTRcd.TouristTaxRate = TouristTaxRate;
				vTTRcd.MinAmountPerDay = MinAmountPerDay;
			EndIf;
		EndIf;
	EndIf;
	
	RegisterRecords.TouristTaxToBePaid.Write = False;
	RegisterRecords.TouristTaxToBePaid.Write(True);
EndProcedure // pmPostToTouristTax

// -----------------------------------------------------------------------------
Procedure pmRecalculateAndRepostTouristTaxOfTheMainGuest() Export
	If RateSumInBaseCurrency <> 0 And ValueIsFilled(Hotel) And Hotel.TouristTaxIsUsed And Not AdditionalProperties.Property("SkipMainDocTouristTaxUpdate") Then
		vDoNotMergeTouristTaxBaseToTheMainRoomGuest = GetDoNotMergeTouristTaxBaseToTheMainRoomGuest();
		
		vMainDoc = Undefined;
		If ValueIsFilled(GuestGroup) And GuestGroup.TouristicTaxIsCalculatedForMainGroupDocumentOnly And 
		   ValueIsFilled(GuestGroup.ClientDoc) And 
		  (TypeOf(GuestGroup.ClientDoc) = Type("DocumentRef.Accommodation") Or TypeOf(GuestGroup.ClientDoc) = Type("DocumentRef.Reservation")) Then
			vMainDoc = GuestGroup.ClientDoc;
		ElsIf Not IsForFolioSplit And Not vDoNotMergeTouristTaxBaseToTheMainRoomGuest Then
			vMainDoc = cmGetMainRoomDocument(Number, GuestGroup);
		EndIf;
		If ValueIsFilled(vMainDoc) And vMainDoc <> Ref Then
			vMainDocObj = vMainDoc.GetObject();

			vCurTouristTaxSumInBaseCurrency = vMainDocObj.TouristTaxSumInBaseCurrency;
			vCurRateSumInBaseCurrency = vMainDocObj.RateSumInBaseCurrency;
			vCurTouristTaxRate = vMainDocObj.TouristTaxRate;
			vCurMinAmountPerDay = vMainDocObj.MinAmountPerDay;
			vCurTouristicTaxIsByMinAmount = vMainDocObj.TouristicTaxIsByMinAmount;

			// Recalculate tourist tax if neccessary
			vDoTransactionsPlanRecalculation = False;
			If ValueIsFilled(vMainDocObj.RoomRate) Then
				vMainDocObjRoomRate = vMainDocObj.RoomRate;
				If Hotel.TouristTaxSubtractFromRateIfExemption Or 
				   Hotel.TouristTaxAddToRate Or 
				   ValueIsFilled(Hotel.TouristTaxService) Or
				   vMainDocObjRoomRate.TouristTaxSubtractFromRateIfExemption Or 
				   vMainDocObjRoomRate.TouristTaxAddToRate Or 
				   ValueIsFilled(vMainDocObjRoomRate.TouristTaxService) Then
					vDoTransactionsPlanRecalculation = True;
				EndIf;
			EndIf;
			If vDoTransactionsPlanRecalculation Then
				vMainDocObj.pmCalculateServices();
			Else
				vMainDocObj.pmCalculateRateAmountAndDurationInDays();
				vMainDocObj.pmCalculateTouristTax(vMainDocObj.pmGetEffectiveCheckInDate());
			EndIf;

			// Repost tourist tax if it has changed
			If vCurTouristTaxSumInBaseCurrency <> vMainDocObj.TouristTaxSumInBaseCurrency Or
			   vCurRateSumInBaseCurrency <> vMainDocObj.RateSumInBaseCurrency Or
			   vCurTouristTaxRate <> vMainDocObj.TouristTaxRate Or
			   vCurMinAmountPerDay <> vMainDocObj.MinAmountPerDay Or
			   vCurTouristicTaxIsByMinAmount <> vMainDocObj.TouristicTaxIsByMinAmount Then
			   
				If Not vMainDocObj.Posted Then
					vMainDocObj.Write(DocumentWriteMode.Write);
				ElsIf vDoTransactionsPlanRecalculation Then
					vMainDocObj.AdditionalProperties.Insert("InfobaseUpdateMode", True);
					vMainDocObj.Write(DocumentWriteMode.Posting);
				Else
					vMainDocObj.Write(DocumentWriteMode.Write);
					vMainDocObj.pmPostToTouristTax();
				EndIf;
				
				// Log changes
				If TypeOf(vMainDocObj) = Type("DocumentObject.Accommodation") Then
					vMainDocObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				ElsIf TypeOf(vMainDocObj) = Type("DocumentObject.Reservation") Then
					vMainDocObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // pmRecalculateAndRepostTouristTaxOfTheMainGuest

// -----------------------------------------------------------------------------
Function GetDoNotMergeTouristTaxBaseToTheMainRoomGuest()
	vDoNotMergeTouristTaxBaseToTheMainRoomGuest = False;
	If ValueIsFilled(AccommodationType) And AccommodationType.DoNotMergeTouristTaxBaseToTheMainRoomGuest Then
		vDoNotMergeTouristTaxBaseToTheMainRoomGuest = True;
	ElsIf ValueIsFilled(RoomRate) And RoomRate.DoNotMergeTouristTaxBaseToTheMainRoomGuest Then
		vDoNotMergeTouristTaxBaseToTheMainRoomGuest = True;
	ElsIf ValueIsFilled(RoomRateType) And RoomRateType.DoNotMergeTouristTaxBaseToTheMainRoomGuest Then
		vDoNotMergeTouristTaxBaseToTheMainRoomGuest = True;
	EndIf;
	Return vDoNotMergeTouristTaxBaseToTheMainRoomGuest;
EndFunction // GetDoNotMergeTouristTaxBaseToTheMainRoomGuest

// -----------------------------------------------------------------------------
Function pmGetEffectiveCheckInDate() Export
	vCheckInDate = CheckInDate;
	If ValueIsFilled(HotelProduct) And Not HotelProduct.IsFolder Then
		If HotelProduct.FixProductPeriod Then
			vCheckInDate = HotelProduct.CheckInDate;
		EndIf;
	EndIf;
	Return vCheckInDate;
EndFunction // pmGetEffectiveCheckInDate

// -----------------------------------------------------------------------------
Procedure FillCheckProcessing(pCancel, pCheckedAttributes)
	If AdditionalProperties.Property("CheckedAttributes") Then
		For Each vId In AdditionalProperties.CheckedAttributes Do
			pCheckedAttributes.Add(vId);       
		EndDo;	
	EndIf;
EndProcedure //  FillCheckProcessing

// -----------------------------------------------------------------------------
Procedure Filling(pBase)
	// Fill from the base
	If ValueIsFilled(pBase) Then
		If TypeOf(pBase) = Type("CatalogRef.HotelProducts") And Not pBase.IsFolder Then
			// Fill attributes with default values
			pmFillAttributesWithDefaultValues();
			// Fill reservation based on hotel product
			HotelProduct = pBase.Ref;
			RoomQuota = pBase.RoomQuota;
			If ValueIsFilled(RoomQuota) Then
				FillPropertyValues(ThisObject, RoomQuota, , "Remarks");
			EndIf;
			FillPropertyValues(ThisObject, HotelProduct, , "Remarks");
			CheckInDate = cm1SecondShift(CheckInDate);
			CheckOutDate = cm0SecondShift(CheckOutDate);
			Duration = pmCalculateDuration();
			// Calculate resources
			pmCalculateResources();
			// Calculate services
			pmCalculateServices();
			// Set planned payment method from the first charging rule
			pmSetPlannedPaymentMethod();
		ElsIf TypeOf(pBase) = Type("CatalogRef.ObjectTemplates") Then
			// Reset price calculation date
			PriceCalculationDate = '00010101';
			// Fill attributes from template
			If ValueIsFilled(pBase.SourceOfBusiness) Then
				SourceOfBusiness = pBase.SourceOfBusiness;
			EndIf;
			If ValueIsFilled(pBase.MarketingCode) Then
				MarketingCode = pBase.MarketingCode;
				MarketingCodeConfirmationText = TrimAll(pBase.MarketingCodeConfirmationText);
			EndIf;
			If ValueIsFilled(pBase.ClientType) Then
				ClientType = pBase.ClientType;
				ClientTypeConfirmationText = TrimAll(pBase.ClientTypeConfirmationText);
			EndIf;
			If ValueIsFilled(pBase.RoomQuota) Then
				RoomQuota = pBase.RoomQuota;
			EndIf;
			If ValueIsFilled(pBase.RoomRate) Then
				RoomRate = pBase.RoomRate;
			EndIf;
			If ValueIsFilled(pBase.RoomRateType) Then
				RoomRateType = pBase.RoomRateType;
			EndIf;
			If ValueIsFilled(pBase.RoomRateServiceGroup) Then
				RoomRateServiceGroup = pBase.RoomRateServiceGroup;
			EndIf;
			If ValueIsFilled(pBase.DiscountType) Then
				DiscountType = pBase.DiscountType;
				DiscountConfirmationText = TrimAll(pBase.DiscountConfirmationText);
			EndIf;
			If pBase.Discount <> 0 Then
				Discount = pBase.Discount;
			EndIf;
			If ValueIsFilled(pBase.DiscountServiceGroup) Then
				DiscountServiceGroup = pBase.DiscountServiceGroup;
			EndIf;
			If ValueIsFilled(pBase.ReservationStatus) Then
				ReservationStatus = pBase.ReservationStatus;
				// Update DoCharging flag
				pmSetDoCharging();
			EndIf;
			If Not IsBlankString(pBase.ConfirmationReply) Then
				ConfirmationReply = TrimAll(pBase.ConfirmationReply);
			EndIf;
			If pBase.Rating <> 0 Then
				Rating = pBase.Rating;
			EndIf;
			If ValueIsFilled(pBase.PlannedPaymentMethod) Then
				PlannedPaymentMethod = pBase.PlannedPaymentMethod;
			EndIf;
			If ValueIsFilled(pBase.AccommodationType) Then
				AccommodationType = pBase.AccommodationType;
			EndIf;
			If ValueIsFilled(pBase.RoomType) Then
				RoomType = pBase.RoomType;
			EndIf;
			If ValueIsFilled(pBase.Room) Then
				Room = pBase.Room;
			EndIf;
			If ValueIsFilled(pBase.ReportingCurrency) Then
				ReportingCurrency = pBase.ReportingCurrency;
				ReportingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, ReportingCurrency, ExchangeRateDate);
			EndIf;
			If ValueIsFilled(pBase.Company) Then
				Company = pBase.Company;
			EndIf;
			If ValueIsFilled(pBase.Customer) Then
				Customer = pBase.Customer;
			EndIf;
			If ValueIsFilled(pBase.Contract) Then
				Contract = pBase.Contract;
			EndIf;
			If Not IsBlankString(pBase.Remarks) Then
				Remarks = TrimAll(pBase.Remarks);
			EndIf;
			// Fill attributes with default values
			pmFillAttributesWithDefaultValues();
			// Fill check-in and check-out times from the room rate
			If ValueIsFilled(RoomRate) Then
				vCheckInDate = CheckInDate;
				If ValueIsFilled(RoomRate.DefaultCheckInTime) Then
					vCheckInDate = cm1SecondShift(BegOfDay(CheckInDate) + (RoomRate.DefaultCheckInTime - BegOfDay(RoomRate.DefaultCheckInTime)));
				EndIf;
				vCheckOutDate = CheckOutDate;
				If RoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour And 
				   ValueIsFilled(RoomRate.ReferenceHour) Then
					vCheckOutDate = cm0SecondShift(BegOfDay(CheckOutDate) + (RoomRate.ReferenceHour - BegOfDay(RoomRate.ReferenceHour)));
				EndIf;
				If vCheckOutDate > vCheckInDate Then
					CheckInDate = vCheckInDate;
					CheckOutDate = vCheckOutDate;
					Duration = pmCalculateDuration();
				EndIf;
			EndIf;
			// Calculate resources
			pmCalculateResources();
			// Calculate services
			pmCalculateServices();
			// Set planned payment method from the first charging rule
			pmSetPlannedPaymentMethod();
		ElsIf TypeOf(pBase) = Type("DocumentRef.Accommodation") Then
			If Not ValueIsFilled(Hotel) Then
				Hotel = pBase.Hotel;
			EndIf;
			If Not ValueIsFilled(GuestGroup) Then
				GuestGroup = pBase.GuestGroup;
			EndIf;
			// Fill attributes with default values
			pmFillAttributesWithDefaultValues(, True);
			// Fill from base document
			FillPropertyValues(ThisObject, pBase, , "Number, Date, Author, DeletionMark, Posted");
			RoomQuantity = 1;
			ParentDoc = pBase;
			CheckInDate = cm1SecondShift(CheckOutDate);
			Duration = Hotel.Duration;
			CheckOutDate = pmCalculateCheckOutDate();
			IsMaster = False;
			// Load charging rules
			ChargingRules.Load(pBase.ChargingRules.Unload());
			// Load prices
			Prices.Load(pBase.Prices.Unload());
			// Load room rates
			RoomRates.Load(pBase.RoomRates.Unload());
			// Load service packages
			ServicePackages.Load(pBase.ServicePackages.Unload());
			// Load occupation percents
			OccupationPercents.Load(pBase.OccupationPercents.Unload());
			// Calculate resources
			pmCalculateResources();
			// Calculate services
			pmCalculateServices();
			// Load manual prices
			pmLoadManualPricesFromParentDoc(pBase);
			// Set planned payment method from the first charging rule
			pmSetPlannedPaymentMethod();
		ElsIf TypeOf(pBase) = Type("DocumentRef.Reservation") Then
			If Not ValueIsFilled(Hotel) Then
				Hotel = pBase.Hotel;
			EndIf;
			// Fill attributes with default values
			pmFillAttributesWithDefaultValues(, True);
			// Fill from base document
			FillPropertyValues(ThisObject, pBase, , "Number, Date, Author, DateOfAnnulation, AuthorOfAnnulation, AnnulationReason, DeletionMark, Posted, ExternalCode, ReservationStatus, GuestGroup, AccommodationTemplate");
			RoomQuantity = 1;                                       
			ParentDoc = pBase;
			IsMaster = False;
			// Clear old object charging rules list                        
			ChargingRules.Clear();
			// Create folios as copy of base folios
			cmCreateChargingRulesBasedOnParent(ThisObject, pBase);
			// Load prices
			Prices.Load(pBase.Prices.Unload());
			// Load room rates
			RoomRates.Load(pBase.RoomRates.Unload());
			// Load service packages
			ServicePackages.Load(pBase.ServicePackages.Unload());
			// Load occupation percents
			OccupationPercents.Load(pBase.OccupationPercents.Unload());
			// Calculate resources
			pmCalculateResources();
			// Calculate services
			pmCalculateServices();
			// Load manual prices
			pmLoadManualPricesFromParentDoc(pBase);
			// Set planned payment method from the first charging rule
			pmSetPlannedPaymentMethod();
		EndIf;
	EndIf;
EndProcedure //  Filling

// -----------------------------------------------------------------------------
Procedure OnCopy(pCopiedObject)
	IsMaster = False;
	ExternalCode = "";
	AnnulationReason = Undefined;
	AuthorOfAnnulation = Catalogs.Employees.EmptyRef();
	DateOfAnnulation = '00010101';
	// Clear author and date of manual services
	For Each vSrvRow In Services Do
		If ValueIsFilled(vSrvRow.IsManualAuthor) Then
			vSrvRow.IsManualAuthor = Undefined;
		EndIf;
		If ValueIsFilled(vSrvRow.IsManualDate) Then
			vSrvRow.IsManualDate = '00010101';
		EndIf;
	EndDo;
	// Clear old object charging rules list
	ChargingRules.Clear();
	// Create folios as copy of base folios
	cmCreateChargingRulesBasedOnParent(ThisObject, pCopiedObject.Ref);
	// If there is master reservation in the group, then 
	// load it's charging rules
	If ValueIsFilled(GuestGroup) Then
		vMasterDoc = pmGetMasterReservation();
		If ValueIsFilled(vMasterDoc) Then
			If pCopiedObject.IsMaster Then
				pmLoadMasterChargingRules(vMasterDoc);
			Else
				// Check if there are already master charging rules
				vMasterChargingRulesFound = cmCheckMasterChargingRulesArePresent(ThisObject);
				If vMasterChargingRulesFound Then
					pmOverloadMasterChargingRules(vMasterDoc);
				Else
					pmLoadMasterChargingRules(vMasterDoc);
				EndIf;
			EndIf;
		Else
			pmRemoveIsMasterChargingRules();
		EndIf;
	Else
		pmRemoveIsMasterChargingRules();
	EndIf;
	// Calculate resources
	pmCalculateResources();
	// Calculate services
	pmCalculateServices();
	// Set planned payment method from the first charging rule
	pmSetPlannedPaymentMethod();
EndProcedure // OnCopy

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)   
	If DataExchange.Load Then
		Return;
	EndIf;
	If DeletionMark Then
		pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
	EndIf;
EndProcedure // OnWrite

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure CalculateResourcesToWriteOff(pRoomsRow)
	If pRoomsRow <> Undefined Then
		// Calculate resources to write off for the current room
		vPersonsPerRoom = ?(EffectiveNumberOfRooms > 0, Min(Int(EffectiveNumberOfPersons/EffectiveNumberOfRooms), ?(pRoomsRow.NumberOfBedsPerRoom > 0, pRoomsRow.NumberOfBedsPerRoom, 1)), 1);
		PersonsWriteOff = Min(EffectiveNumberOfPersons, vPersonsPerRoom);
		EffectiveNumberOfPersons = EffectiveNumberOfPersons - PersonsWriteOff;
		EffectiveNumberOfPersons = ?(EffectiveNumberOfPersons < 0, 0, EffectiveNumberOfPersons);
		
		RoomsWriteOff = Min(EffectiveNumberOfRooms, 1);
		EffectiveNumberOfRooms = EffectiveNumberOfRooms - RoomsWriteOff;
		EffectiveNumberOfRooms = ?(EffectiveNumberOfRooms < 0, 0, EffectiveNumberOfRooms);
		
		BedsWriteOff = Min(EffectiveNumberOfBeds, pRoomsRow.NumberOfBedsPerRoom);
		EffectiveNumberOfBeds = EffectiveNumberOfBeds - BedsWriteOff;
		EffectiveNumberOfBeds = ?(EffectiveNumberOfBeds < 0, 0, EffectiveNumberOfBeds);
		
		AdditionalBedsWriteOff = 0;
	Else
		// Calculate resources to write off
		RoomsWriteOff = EffectiveNumberOfRooms;
		BedsWriteOff = EffectiveNumberOfBeds;
		AdditionalBedsWriteOff = EffectiveNumberOfAddBeds;
		PersonsWriteOff = EffectiveNumberOfPersons;
	EndIf;
EndProcedure // CalculateResourcesToWriteOff

// -----------------------------------------------------------------------------
Procedure CalculateResourcesToWriteOffDetailed(pPeriod, pEffectiveNumberOfRoomsRow)
	// Calculate resources to write off
	RoomsWriteOff = pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms;
	BedsWriteOff = EffectiveNumberOfBeds;
	AdditionalBedsWriteOff = EffectiveNumberOfAddBeds;
	PersonsWriteOff = EffectiveNumberOfPersons;
EndProcedure // CalculateResourcesToWriteOffDetailed

// -----------------------------------------------------------------------------
Procedure FillRIAttributes(pRIRec, pDate, pPeriods, pPeriod, pRoomsRow)
	FillPropertyValues(pRIRec, ThisObject);
	FillPropertyValues(pRIRec, pPeriod);
	
	pRIRec.Period = pDate;
	pRIRec.PeriodFrom = pPeriod.CheckInDate;
	pRIRec.PeriodTo = pPeriod.CheckOutDate;
	pRIRec.PeriodDuration = cmCalculateDuration(pPeriod.RoomRate, pRIRec.PeriodFrom, pRIRec.PeriodTo);
	pRIRec.CheckInAccountingDate = BegOfDay(CheckInDate);
	pRIRec.CheckOutAccountingDate = BegOfDay(CheckOutDate);
	pRIRec.CheckInDate = CheckInDate;
	pRIRec.CheckOutDate = CheckOutDate;
	pRIRec.Duration = Duration;
	
	If ValueIsFilled(pPeriod.RoomRate) Then
		pRIRec.RoomRateType = pPeriod.RoomRate.RoomRateType;
	EndIf;
	
	pRIRec.PricePresentation = PricePresentation;
	
	pRIRec.IsReservation = True;
	
	If pRoomsRow <> Undefined Then
		pRIRec.Room = pRoomsRow.Room;
		pRIRec.NumberOfBedsPerRoom = pRoomsRow.NumberOfBedsPerRoom;
		pRIRec.NumberOfPersonsPerRoom = pRoomsRow.NumberOfPersonsPerRoom;
	EndIf;
	
	pRIRec.NumberOfRooms = RoomsWriteOff;
	pRIRec.NumberOfBeds = BedsWriteOff;
	pRIRec.NumberOfAdditionalBeds = AdditionalBedsWriteOff;
	pRIRec.NumberOfPersons = PersonsWriteOff;
	
	// Fill register record resources
	pRIRec.RoomsReserved = RoomsWriteOff;
	pRIRec.BedsReserved = BedsWriteOff;
	pRIRec.AdditionalBedsReserved = AdditionalBedsWriteOff;
	pRIRec.GuestsReserved = PersonsWriteOff;
	
	If ReservationStatus.IsGuaranteed Then
		pRIRec.GuaranteedRoomsReserved = RoomsWriteOff;
		pRIRec.GuaranteedBedsReserved = BedsWriteOff;
		pRIRec.GuaranteedAdditionalBedsReserved = AdditionalBedsWriteOff;
		pRIRec.GuaranteedGuestsReserved = PersonsWriteOff;
	EndIf;
	
	pRIRec.RoomsVacant = RoomsWriteOff;
	pRIRec.BedsVacant = BedsWriteOff;
	If pPeriod.DoNotChangeAvailability Then
		pRIRec.GuestsVacant = 0;
	Else
		pRIRec.GuestsVacant = PersonsWriteOff;
	EndIf;
	
	pRIRec.ExpectedRoomsCheckedIn = 0;
	pRIRec.ExpectedBedsCheckedIn = 0;
	pRIRec.ExpectedAdditionalBedsCheckedIn = 0;
	pRIRec.ExpectedGuestsCheckedIn = 0;
	
	pRIRec.GuaranteedExpectedRoomsCheckedIn = 0;
	pRIRec.GuaranteedExpectedBedsCheckedIn = 0;
	pRIRec.GuaranteedExpectedAdditionalBedsCheckedIn = 0;
	pRIRec.GuaranteedExpectedGuestsCheckedIn = 0;
	
	pRIRec.ExpectedRoomsCheckedOut = 0;
	pRIRec.ExpectedBedsCheckedOut = 0;
	pRIRec.ExpectedAdditionalBedsCheckedOut = 0;
	pRIRec.ExpectedGuestsCheckedOut = 0;
	
	If cm1SecondShift(pPeriod.CheckInDate) = cm1SecondShift(CheckInDate) And pRIRec.RecordType = AccumulationRecordType.Expense Then
		pRIRec.ExpectedRoomsCheckedIn = RoomsWriteOff;
		pRIRec.ExpectedBedsCheckedIn = BedsWriteOff;
		pRIRec.ExpectedAdditionalBedsCheckedIn = AdditionalBedsWriteOff;
		pRIRec.ExpectedGuestsCheckedIn = PersonsWriteOff;
		
		If ReservationStatus.IsGuaranteed Then
			pRIRec.GuaranteedExpectedRoomsCheckedIn = pRIRec.ExpectedRoomsCheckedIn;
			pRIRec.GuaranteedExpectedBedsCheckedIn = pRIRec.ExpectedBedsCheckedIn;
			pRIRec.GuaranteedExpectedAdditionalBedsCheckedIn = pRIRec.ExpectedAdditionalBedsCheckedIn;
			pRIRec.GuaranteedExpectedGuestsCheckedIn = pRIRec.ExpectedGuestsCheckedIn;
		EndIf;
	EndIf;
	
	If cm0SecondShift(pPeriod.CheckOutDate) = cm0SecondShift(CheckOutDate) And pRIRec.RecordType = AccumulationRecordType.Receipt Then
		pRIRec.ExpectedRoomsCheckedOut = ?(RoomsWriteOff > 0, RoomsWriteOff, 0);
		pRIRec.ExpectedBedsCheckedOut = ?(BedsWriteOff > 0, BedsWriteOff, 0);
		pRIRec.ExpectedAdditionalBedsCheckedOut = ?(AdditionalBedsWriteOff > 0, AdditionalBedsWriteOff, 0);
		pRIRec.ExpectedGuestsCheckedOut = ?(PersonsWriteOff > 0, PersonsWriteOff, 0);
	EndIf;

	pRIRec.Timestamp = CurrentSessionDate();
	
	vPeriodIdx = pPeriods.IndexOf(pPeriod);
	vPeriodsCount = pPeriods.Count();
	If vPeriodIdx > 0 Then
		b = 1;
		While b <= vPeriodIdx Do
			vPrevPeriod = pPeriods.Get(vPeriodIdx - b);
			If vPrevPeriod.CheckInDate < pPeriod.CheckInDate Then
				If vPrevPeriod.RoomType <> pPeriod.RoomType Or vPrevPeriod.Room <> pPeriod.Room Then
					pRIRec.RoomTypeBefore = vPrevPeriod.RoomType;
					pRIRec.RoomBefore = vPrevPeriod.Room;
				EndIf;
				Break;
			EndIf;
			b = b + 1;
		EndDo;
	EndIf;
	If vPeriodIdx < (vPeriodsCount - 1) Then
		f = 1;
		While (vPeriodIdx + f) < vPeriodsCount Do
			vNextPeriod = pPeriods.Get(vPeriodIdx + f);
			If vNextPeriod.CheckInDate > pPeriod.CheckInDate Then
				If vNextPeriod.RoomType <> pPeriod.RoomType Or vNextPeriod.Room <> pPeriod.Room Then
					pRIRec.RoomTypeAfter = vNextPeriod.RoomType;
					pRIRec.RoomAfter = vNextPeriod.Room;
				EndIf;
				Break;
			EndIf;
			f = f + 1;
		EndDo;
	EndIf;
EndProcedure // FillRIAttributes

// -----------------------------------------------------------------------------
Procedure FillRIAttributesDetailed(pRIRec, pDate, pPeriods, pPeriod, pEffectiveNumberOfRoomsRow, pPrevEffectiveNumberOfRoomsRow, pNextEffectiveNumberOfRoomsRow)
	FillPropertyValues(pRIRec, ThisObject);
	FillPropertyValues(pRIRec, pPeriod);
	
	pRIRec.Period = pDate;
	pRIRec.PeriodFrom = pPeriod.CheckInDate;
	pRIRec.PeriodTo = pPeriod.CheckOutDate;
	pRIRec.PeriodDuration = cmCalculateDuration(pPeriod.RoomRate, pRIRec.PeriodFrom, pRIRec.PeriodTo);
	pRIRec.CheckInAccountingDate = BegOfDay(CheckInDate);
	pRIRec.CheckOutAccountingDate = BegOfDay(CheckOutDate);
	pRIRec.CheckInDate = CheckInDate;
	pRIRec.CheckOutDate = CheckOutDate;
	pRIRec.Duration = Duration;
	
	If ValueIsFilled(pPeriod.RoomRate) Then
		pRIRec.RoomRateType = pPeriod.RoomRate.RoomRateType;
	EndIf;
	
	pRIRec.PricePresentation = PricePresentation;
	
	pRIRec.IsReservation = True;
	
	pRIRec.NumberOfRooms = pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms;
	pRIRec.NumberOfBeds = BedsWriteOff;
	pRIRec.NumberOfAdditionalBeds = AdditionalBedsWriteOff;
	pRIRec.NumberOfPersons = PersonsWriteOff;
	
	// Fill register record resources
	pRIRec.RoomsReserved = pRIRec.NumberOfRooms;
	pRIRec.BedsReserved = pRIRec.NumberOfBeds;
	pRIRec.AdditionalBedsReserved = pRIRec.NumberOfAdditionalBeds;
	pRIRec.GuestsReserved = pRIRec.NumberOfPersons;
	
	If ReservationStatus.IsGuaranteed Then
		pRIRec.GuaranteedRoomsReserved = pRIRec.NumberOfRooms;
		pRIRec.GuaranteedBedsReserved = pRIRec.NumberOfBeds;
		pRIRec.GuaranteedAdditionalBedsReserved = pRIRec.NumberOfAdditionalBeds;
		pRIRec.GuaranteedGuestsReserved = pRIRec.NumberOfPersons;
	EndIf;
	
	pRIRec.RoomsVacant = pRIRec.NumberOfRooms;
	pRIRec.BedsVacant = pRIRec.NumberOfBeds;
	If pPeriod.DoNotChangeAvailability Then
		pRIRec.GuestsVacant = 0;
	Else
		pRIRec.GuestsVacant = pRIRec.NumberOfPersons;
	EndIf;
	
	pRIRec.ExpectedRoomsCheckedIn = 0;
	pRIRec.ExpectedBedsCheckedIn = 0;
	pRIRec.ExpectedAdditionalBedsCheckedIn = 0;
	pRIRec.ExpectedGuestsCheckedIn = 0;
	
	pRIRec.GuaranteedExpectedRoomsCheckedIn = 0;
	pRIRec.GuaranteedExpectedBedsCheckedIn = 0;
	pRIRec.GuaranteedExpectedAdditionalBedsCheckedIn = 0;
	pRIRec.GuaranteedExpectedGuestsCheckedIn = 0;
	
	pRIRec.ExpectedRoomsCheckedOut = 0;
	pRIRec.ExpectedBedsCheckedOut = 0;
	pRIRec.ExpectedAdditionalBedsCheckedOut = 0;
	pRIRec.ExpectedGuestsCheckedOut = 0;
	
	If pRIRec.RecordType = AccumulationRecordType.Expense Then
		If cm1SecondShift(pEffectiveNumberOfRoomsRow.PeriodFrom) = cm1SecondShift(CheckInDate) And 
		   pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms <> 0 Then
			pRIRec.ExpectedRoomsCheckedIn = pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms;
		ElsIf pPrevEffectiveNumberOfRoomsRow <> Undefined And 
		      pPrevEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms = 0 And 
		      pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms <> 0 Then
			pRIRec.ExpectedRoomsCheckedIn = pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms;
		ElsIf pPrevEffectiveNumberOfRoomsRow <> Undefined And 
		      pPrevEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms <> 0 And 
		      pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms = 0 Then
			pRIRec.ExpectedRoomsCheckedIn = -pPrevEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms;
		EndIf;
		If cm1SecondShift(pEffectiveNumberOfRoomsRow.PeriodFrom) = cm1SecondShift(CheckInDate) Then
			pRIRec.ExpectedBedsCheckedIn = pRIRec.NumberOfBeds;
			pRIRec.ExpectedAdditionalBedsCheckedIn = pRIRec.NumberOfAdditionalBeds;
			pRIRec.ExpectedGuestsCheckedIn = pRIRec.NumberOfPersons;
		EndIf;
		
		If ReservationStatus.IsGuaranteed Then
			pRIRec.GuaranteedExpectedRoomsCheckedIn = pRIRec.ExpectedRoomsCheckedIn;
			pRIRec.GuaranteedExpectedBedsCheckedIn = pRIRec.ExpectedBedsCheckedIn;
			pRIRec.GuaranteedExpectedAdditionalBedsCheckedIn = pRIRec.ExpectedAdditionalBedsCheckedIn;
			pRIRec.GuaranteedExpectedGuestsCheckedIn = pRIRec.ExpectedGuestsCheckedIn;
		EndIf;
	Else
		If cm0SecondShift(pEffectiveNumberOfRoomsRow.PeriodTo) = cm0SecondShift(CheckOutDate) And
		   pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms <> 0 Then
			pRIRec.ExpectedRoomsCheckedOut = ?(pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms > 0, pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms, 0);
		ElsIf pNextEffectiveNumberOfRoomsRow <> Undefined And 
		      pNextEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms = 0 And 
		      pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms <> 0 Then
			pRIRec.ExpectedRoomsCheckedOut = ?(pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms > 0, pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms, 0);
		ElsIf pNextEffectiveNumberOfRoomsRow <> Undefined And 
		      pNextEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms <> 0 And 
		      pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms = 0 Then
			pRIRec.ExpectedRoomsCheckedOut = ?(pNextEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms < 0, -pNextEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms, 0);
		EndIf;
		If cm0SecondShift(pEffectiveNumberOfRoomsRow.PeriodTo) = cm0SecondShift(CheckOutDate) Then
			pRIRec.ExpectedBedsCheckedOut = pRIRec.NumberOfBeds;
			pRIRec.ExpectedAdditionalBedsCheckedOut = pRIRec.NumberOfAdditionalBeds;
			pRIRec.ExpectedGuestsCheckedOut = pRIRec.NumberOfPersons;
		EndIf;
	EndIf;

	pRIRec.Timestamp = CurrentSessionDate();
	
	vPeriodIdx = pPeriods.IndexOf(pPeriod);
	vPeriodsCount = pPeriods.Count();
	If vPeriodIdx > 0 Then
		b = 1;
		While b <= vPeriodIdx Do
			vPrevPeriod = pPeriods.Get(vPeriodIdx - b);
			If vPrevPeriod.CheckInDate < pPeriod.CheckInDate Then
				If vPrevPeriod.RoomType <> pPeriod.RoomType Or vPrevPeriod.Room <> pPeriod.Room Then
					pRIRec.RoomTypeBefore = vPrevPeriod.RoomType;
					pRIRec.RoomBefore = vPrevPeriod.Room;
				EndIf;
				Break;
			EndIf;
			b = b + 1;
		EndDo;
	EndIf;
	If vPeriodIdx < (vPeriodsCount - 1) Then
		f = 1;
		While (vPeriodIdx + f) < vPeriodsCount Do
			vNextPeriod = pPeriods.Get(vPeriodIdx + f);
			If vNextPeriod.CheckInDate > pPeriod.CheckInDate Then
				If vNextPeriod.RoomType <> pPeriod.RoomType Or vNextPeriod.Room <> pPeriod.Room Then
					pRIRec.RoomTypeAfter = vNextPeriod.RoomType;
					pRIRec.RoomAfter = vNextPeriod.Room;
				EndIf;
				Break;
			EndIf;
			f = f + 1;
		EndDo;
	EndIf;
EndProcedure // FillRIAttributesDetailed

// -----------------------------------------------------------------------------
Procedure WriteRoomInitializationRecord(pInitRecordDate, pHotel, pRoomType)
	vRIRec = RegisterRecords.RoomInventory.AddReceipt();
	
	vRIRec.Period = pInitRecordDate;
	vRIRec.Hotel = pHotel;
	vRIRec.RoomType = pRoomType;
	vRIRec.Room = Catalogs.Rooms.EmptyRef();
	
	vRIRec.TotalRooms = 0;
	vRIRec.TotalBeds = 0;
	vRIRec.TotalGuests = 0;
	vRIRec.RoomsVacant = 0;
	vRIRec.BedsVacant = 0;
	vRIRec.GuestsVacant = 0;
	
	vRIRec.Counter = 1;
	
	vRIRec.ParentDoc = Ref;
	vRIRec.NumberOfBedsPerRoom = 0;
	vRIRec.NumberOfPersonsPerRoom = 0;
	vRIRec.Remarks = "";
	vRIRec.Author = Catalogs.Employees.EmptyRef();
	vRIRec.IsRoomInventory = False;

	vRIRec.Timestamp = CurrentSessionDate();
EndProcedure // WriteRoomInitializationRecords

// -----------------------------------------------------------------------------
Procedure PostToRoomInventory(pCancel, pPeriods, pPeriod, pRoomsRow = Undefined)
	// Write room inventory initialization record if necessary
	vRH = cmGetReferenceHour(pPeriod.RoomRate);
	vRHInSeconds = vRH - BegOfDay(vRH);
	If vRHInSeconds > 0 Then
		If (pPeriod.CheckInDate - BegOfDay(pPeriod.CheckInDate) - 1) < vRHInSeconds Then
			WriteRoomInitializationRecord(BegOfDay(pPeriod.CheckInDate) + vRHInSeconds + 1, pPeriod.Hotel, pPeriod.RoomType);
		EndIf;
		If (pPeriod.CheckOutDate - BegOfDay(pPeriod.CheckOutDate)) > vRHInSeconds Then
			WriteRoomInitializationRecord(BegOfDay(pPeriod.CheckOutDate) + vRHInSeconds + 1, pPeriod.Hotel, pPeriod.RoomType);
		EndIf;
	EndIf;
	WriteRoomInitializationRecord((pPeriod.CheckOutDate - 1), pPeriod.Hotel, pPeriod.RoomType);
	
	// Calculate resources to write off from the room inventory for the giving period
	CalculateResourcesToWriteOff(pRoomsRow);
	
	If PersonsWriteOff = 0 And
	   RoomsWriteOff = 0 And
	   BedsWriteOff = 0 And
	   AdditionalBedsWriteOff = 0 Then
		Return;
	EndIf;
	
	// Do expense movement on check in date
	vRIRec = RegisterRecords.RoomInventory.AddExpense();
	FillRIAttributes(vRIRec, pPeriod.CheckInDate, pPeriods, pPeriod, pRoomsRow);
		
	// Do receipt movement on check out date
	vRIRec = RegisterRecords.RoomInventory.AddReceipt();
	FillRIAttributes(vRIRec, pPeriod.CheckOutDate, pPeriods, pPeriod, pRoomsRow);
	
	// Change room status
	If ValueIsFilled(Hotel.ReservedRoomStatus) And 
	   ReservationStatus.DoRoomStatusChange And 
	   pPeriod.CheckInDate = CheckInDate Then
		vRoom = Undefined;
		If pRoomsRow <> Undefined Then
			vRoom = pRoomsRow.Room;
		Else
			vRoom = pPeriod.Room;
		EndIf;
		If ValueIsFilled(vRoom) Then	   
			If vRoom.RoomStatus <> Hotel.ReservedRoomStatus And 
			  (vRoom.RoomStatus = Hotel.VacantRoomStatus Or 
			   ValueIsFilled(vRoom.RoomStatus) And vRoom.RoomStatus.RoomIsVacantClear) Then
				If RoomsWithReservedStatus.FindByValue(vRoom) = Undefined Then
					RoomsWithReservedStatus.Add(vRoom);
					DoChangeRoomStatus(Hotel.ReservedRoomStatus, vRoom);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // PostToRoomInventory

// -----------------------------------------------------------------------------
Procedure PostToRoomInventoryDetailed(pCancel, pPeriods, pPeriod, pEffectiveNumberOfRoomsRow, pPrevEffectiveNumberOfRoomsRow, pNextEffectiveNumberOfRoomsRow)
	// Write room inventory initialization record if necessary
	vRH = cmGetReferenceHour(pPeriod.RoomRate);
	vRHInSeconds = vRH - BegOfDay(vRH);
	If vRHInSeconds > 0 Then
		If (pPeriod.CheckInDate - BegOfDay(pPeriod.CheckInDate) - 1) < vRHInSeconds Then
			WriteRoomInitializationRecord(BegOfDay(pPeriod.CheckInDate) + vRHInSeconds + 1, pPeriod.Hotel, pPeriod.RoomType);
		EndIf;
		If (pPeriod.CheckOutDate - BegOfDay(pPeriod.CheckOutDate)) > vRHInSeconds Then
			WriteRoomInitializationRecord(BegOfDay(pPeriod.CheckOutDate) + vRHInSeconds + 1, pPeriod.Hotel, pPeriod.RoomType);
		EndIf;
	EndIf;
	WriteRoomInitializationRecord((pPeriod.CheckOutDate - 1), pPeriod.Hotel, pPeriod.RoomType);
	
	// Calculate resources to write off from the room inventory for the giving period
	CalculateResourcesToWriteOffDetailed(pPeriod, pEffectiveNumberOfRoomsRow);
	
	If PersonsWriteOff = 0 And
	   RoomsWriteOff = 0 And
	   BedsWriteOff = 0 And
	   AdditionalBedsWriteOff = 0 Then
		Return;
	EndIf;
	
	// Do expense movement on check in date
	vRIRec = RegisterRecords.RoomInventory.AddExpense();
	FillRIAttributesDetailed(vRIRec, pEffectiveNumberOfRoomsRow.PeriodFrom, pPeriods, pPeriod, pEffectiveNumberOfRoomsRow, pPrevEffectiveNumberOfRoomsRow, pNextEffectiveNumberOfRoomsRow);
		
	// Do receipt movement on check out date
	vRIRec = RegisterRecords.RoomInventory.AddReceipt();
	FillRIAttributesDetailed(vRIRec, pEffectiveNumberOfRoomsRow.PeriodTo, pPeriods, pPeriod, pEffectiveNumberOfRoomsRow, pPrevEffectiveNumberOfRoomsRow, pNextEffectiveNumberOfRoomsRow);
	
	// Change room status
	If ValueIsFilled(Hotel.ReservedRoomStatus) And 
	   ReservationStatus.DoRoomStatusChange And 
	   pPeriod.CheckInDate = CheckInDate Then
		vRoom = pPeriod.Room;
		If ValueIsFilled(vRoom) Then	   
			If vRoom.RoomStatus <> Hotel.ReservedRoomStatus And 
			  (vRoom.RoomStatus = Hotel.VacantRoomStatus Or 
			   ValueIsFilled(vRoom.RoomStatus) And vRoom.RoomStatus.RoomIsVacantClear) Then
				If RoomsWithReservedStatus.FindByValue(vRoom) = Undefined Then
					RoomsWithReservedStatus.Add(vRoom);
					DoChangeRoomStatus(Hotel.ReservedRoomStatus, vRoom);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // PostToRoomInventoryDetailed

// -----------------------------------------------------------------------------
Procedure PostToWaitingList(pCancel)
	// Clear register records
	RegisterRecords.ReservationWaitingList.Clear();
	
	// Do movement on document date
	If ReservationStatus.IsInWaitingList Then
		vWLRec = RegisterRecords.ReservationWaitingList.Add();
		
		vWLRec.Period = Date;
		vWLRec.Reservation = Ref;
		vWLRec.Rating = Rating;
	EndIf;
			
	// Write movements
	RegisterRecords.ReservationWaitingList.Write();
EndProcedure // PostToWaitingList

// -----------------------------------------------------------------------------
Procedure PostToExpectedGuestGroups(pPeriod, pCancel)
	vRoomQuota = pPeriod.RoomQuota;
	vRoomType = pPeriod.RoomType;
	If ValueIsFilled(RoomTypeUpgrade) And ValueIsFilled(RoomTypeUpgrade.BaseRoomType) And RoomTypeUpgrade.BaseRoomType = vRoomType Then
		vRoomType = RoomTypeUpgrade;
	EndIf;
	
	// Do movements for each day from the reservation period
	If ReservationStatus.IsPreliminary Or 
	  (Not ReservationStatus.IsActive And (ReservationStatus.IsNoShow Or ReservationStatus.IsAnnulation Or ReservationStatus.IsCheckIn)) And
	   ValueIsFilled(vRoomQuota) And vRoomQuota.ForecastIsUsed And vRoomQuota.FirstForecastUsageTime < Date Then
		// Get tentative rooms balance if we are writing off tentative rooms from allotment
		If Not ReservationStatus.IsPreliminary Then
			vTentativeRoomsBalance = GetTentativeRoomsBalance(Hotel, vRoomQuota, vRoomType, pPeriod.CheckInDate, pPeriod.CheckOutDate);
		EndIf;

		vBegOfDay = BegOfDay(pPeriod.CheckInDate);
		While vBegOfDay < BegOfDay(pPeriod.CheckOutDate) Or vBegOfDay = BegOfDay(pPeriod.CheckOutDate) And BegOfDay(pPeriod.CheckInDate) = BegOfDay(pPeriod.CheckOutDate) Do
			// Resources
			If ReservationStatus.IsPreliminary Then
				vEGGRec = RegisterRecords.ExpectedGuestGroups.Add();
				FillPropertyValues(vEGGRec, ThisObject);
				vEGGRec.Period = EndOfDay(vBegOfDay);
				vEGGRec.Recorder = Ref;
				vEGGRec.RoomQuota = vRoomQuota;
				vEGGRec.RoomType = vRoomType;

				vEGGRec.RoomsReserved = ?(pPeriod.NumberOfRooms <> 0, pPeriod.NumberOfRooms, ?(pPeriod.NumberOfBedsPerRoom <> 0, pPeriod.NumberOfBeds/pPeriod.NumberOfBedsPerRoom, 0));
				vEGGRec.BedsReserved = pPeriod.NumberOfBeds;
				vEGGRec.AdditionalBedsReserved = pPeriod.NumberOfAdditionalBeds;
				vEGGRec.GuestsReserved = pPeriod.NumberOfPersons;
			Else
				vRooms2WriteOff = ?(pPeriod.NumberOfRooms <> 0, pPeriod.NumberOfRooms, ?(pPeriod.NumberOfBedsPerRoom <> 0, pPeriod.NumberOfBeds/pPeriod.NumberOfBedsPerRoom, 0));
				vBeds2WriteOff = pPeriod.NumberOfBeds;
				
				vTentativeRoomsBalanceRow = vTentativeRoomsBalance.Find(vBegOfDay, "Period");
				If vTentativeRoomsBalanceRow <> Undefined Then
					If vTentativeRoomsBalanceRow.RoomsForecast >= vRooms2WriteOff And vTentativeRoomsBalanceRow.BedsForecast >= vBeds2WriteOff Then
						vEGGRec = RegisterRecords.ExpectedGuestGroups.Add();
						FillPropertyValues(vEGGRec, ThisObject);
						vEGGRec.Period = EndOfDay(vBegOfDay);
						vEGGRec.Recorder = Ref;
						vEGGRec.RoomQuota = vRoomQuota;
						vEGGRec.RoomType = vRoomType;

						vEGGRec.RoomsReserved = -vRooms2WriteOff;
						vEGGRec.BedsReserved = -vBeds2WriteOff;
						vEGGRec.AdditionalBedsReserved = 0;
						vEGGRec.GuestsReserved = 0;
					EndIf;
				EndIf;
			EndIf;
			
			// Next date
			vBegOfDay = vBegOfDay + 24*3600;
		EndDo;
	EndIf;
EndProcedure // PostToExpectedGuestGroups

// -----------------------------------------------------------------------------
Function GetTentativeRoomsBalance(pHotel, pRoomQuota, pRoomType, pPeriodFrom, pPeriodTo)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ExpectedGuestGroupsTurnovers.Period AS Period,
	|	ExpectedGuestGroupsTurnovers.RoomsReservedTurnover AS RoomsForecast,
	|	ExpectedGuestGroupsTurnovers.BedsReservedTurnover AS BedsForecast
	|FROM
	|	AccumulationRegister.ExpectedGuestGroups.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			Hotel = &qHotel
	|				AND RoomQuota = &qRoomQuota
	|				AND RoomType = &qRoomType
	|				AND CASE
	|					WHEN RoomQuota = VALUE(Catalog.RoomQuotas.EmptyRef)
	|						THEN TRUE
	|					WHEN GuestGroup <> VALUE(Catalog.GuestGroups.EmptyRef)
	|						THEN TRUE
	|					WHEN NOT ISNULL(RoomQuota.DoWriteOff, FALSE)
	|						THEN TRUE
	|					ELSE FALSE
	|				END) AS ExpectedGuestGroupsTurnovers
	|
	|ORDER BY
	|	Period";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qRoomType", pRoomType);
	vQry.SetParameter("qRoomQuota", pRoomQuota);
	vQry.SetParameter("qPeriodFrom", BegOfDay(pPeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(pPeriodTo));
	Return vQry.Execute().Unload();
EndFunction // GetTentativeRoomsBalance

// -----------------------------------------------------------------------------
Procedure FillRQInitializationAttributes(pRQRec, pDate, pPeriod, pRoomsRow = Undefined)
	pRQRec.Hotel = Hotel;
	pRQRec.RoomQuota = RoomQuota;
	pRQRec.RoomType = pPeriod.RoomType;
	pRQRec.Room = pPeriod.Room;
	
	If ValueIsFilled(RoomTypeUpgrade) And ValueIsFilled(RoomTypeUpgrade.BaseRoomType) And RoomTypeUpgrade.BaseRoomType = pPeriod.RoomType Then
		pRQRec.RoomType = RoomTypeUpgrade;
	EndIf;
	
	If pRoomsRow <> Undefined Then
		pRQRec.Room = pRoomsRow.Room;
	EndIf;
	If Not RoomQuota.IsQuotaForRooms Then
		pRQRec.Room = Catalogs.Rooms.EmptyRef();
	EndIf;

	pRQRec.Period = pDate;
	
	pRQRec.RoomsInQuota = 0;
	pRQRec.BedsInQuota = 0;
	pRQRec.RoomsRemains = 0;
	pRQRec.BedsRemains = 0;
	
	pRQRec.Counter = 1;
	
	pRQRec.IsRoomQuota = False;

	pRQRec.Timestamp = CurrentSessionDate();
EndProcedure // FillRQInitializationAttributes

// -----------------------------------------------------------------------------
Procedure FillRQAttributes(pRQRec, pDate, pPeriod, pRoomsRow)
	FillPropertyValues(pRQRec, ThisObject);
	FillPropertyValues(pRQRec, pPeriod);
	
	If ValueIsFilled(RoomTypeUpgrade) And ValueIsFilled(RoomTypeUpgrade.BaseRoomType) And RoomTypeUpgrade.BaseRoomType = pPeriod.RoomType Then
		pRQRec.RoomType = RoomTypeUpgrade;
	EndIf;
	
	// Corrections to the reference hour
	vDate = pDate;
	If WriteOffAllotmentLateCheckOutAndEarlyCheckInFromFreeSaleVacantRooms Then
		vDate = cmMovePeriodToToReferenceHour(vDate, pPeriod.RoomRate);
	EndIf;
	pRQRec.Period = vDate;
	
	pRQRec.DateFrom = pPeriod.CheckInDate;
	pRQRec.DateTo = pPeriod.CheckOutDate;
	pRQRec.Duration = cmCalculateDuration(pPeriod.RoomRate, pPeriod.CheckInDate, pPeriod.CheckOutDate);
	
	If ValueIsFilled(pPeriod.RoomRate) Then
		pRQRec.RoomRateType = pPeriod.RoomRate.RoomRateType;
	EndIf;
	
	pRQRec.RoomsReserved = RoomsWriteOff;
	pRQRec.BedsReserved = BedsWriteOff;
	pRQRec.RoomsRemains = RoomsWriteOff;
	pRQRec.BedsRemains = BedsWriteOff;
	
	If ReservationStatus.IsGuaranteed Then
		pRQRec.GuaranteedRoomsReserved = RoomsWriteOff;
		pRQRec.GuaranteedBedsReserved = BedsWriteOff;
	EndIf;
	
	If pRoomsRow <> Undefined Then
		pRQRec.Room = pRoomsRow.Room;
	EndIf;
	
	If Not RoomQuota.IsQuotaForRooms Then
		pRQRec.Room = Catalogs.Rooms.EmptyRef();
	EndIf;
	
	pRQRec.IsReservation = True;

	pRQRec.Timestamp = CurrentSessionDate();
EndProcedure // FillRQAttributes

// -----------------------------------------------------------------------------
Procedure FillRQAttributesDetailed(pRQRec, pDate, pPeriod, pPeriodFrom, pPeriodTo, pEffectiveNumberOfRooms)
	FillPropertyValues(pRQRec, ThisObject);
	FillPropertyValues(pRQRec, pPeriod);
	
	If ValueIsFilled(RoomTypeUpgrade) And ValueIsFilled(RoomTypeUpgrade.BaseRoomType) And RoomTypeUpgrade.BaseRoomType = pPeriod.RoomType Then
		pRQRec.RoomType = RoomTypeUpgrade;
	EndIf;
	
	// Corrections to the reference hour
	vDate = pDate;
	If WriteOffAllotmentLateCheckOutAndEarlyCheckInFromFreeSaleVacantRooms Then
		vDate = cmMovePeriodToToReferenceHour(vDate, pPeriod.RoomRate);
	EndIf;
	pRQRec.Period = vDate;
	
	pRQRec.DateFrom = pPeriodFrom;
	pRQRec.DateTo = pPeriodTo;
	pRQRec.Duration = cmCalculateDuration(pPeriod.RoomRate, pPeriodFrom, pPeriodTo);
	
	If ValueIsFilled(pPeriod.RoomRate) Then
		pRQRec.RoomRateType = pPeriod.RoomRate.RoomRateType;
	EndIf;
	
	pRQRec.RoomsReserved = pEffectiveNumberOfRooms;
	pRQRec.BedsReserved = BedsWriteOff;
	pRQRec.RoomsRemains = pEffectiveNumberOfRooms;
	pRQRec.BedsRemains = BedsWriteOff;
	
	If ReservationStatus.IsGuaranteed Then
		pRQRec.GuaranteedRoomsReserved = pEffectiveNumberOfRooms;
		pRQRec.GuaranteedBedsReserved = BedsWriteOff;
	EndIf;
	
	If Not RoomQuota.IsQuotaForRooms Then
		pRQRec.Room = Catalogs.Rooms.EmptyRef();
	EndIf;
	
	pRQRec.IsReservation = True;

	pRQRec.Timestamp = CurrentSessionDate();
EndProcedure // FillRQAttributesDetailed

// -----------------------------------------------------------------------------
Procedure FillRQRIAttributes(pRIRec, pDate, pDateFrom, pDateTo, pPeriod, pRoomsRow, pRoomsToWriteOff, pBedsToWriteOff)
	FillPropertyValues(pRIRec, ThisObject);
	FillPropertyValues(pRIRec, pPeriod);

	vDate = pDate;
	If WriteOffAllotmentLateCheckOutAndEarlyCheckInFromFreeSaleVacantRooms Then
		vDate = cmMovePeriodToToReferenceHour(vDate, pPeriod.RoomRate);
	EndIf;
	pRIRec.Period = vDate;
	
	pRIRec.PeriodFrom = pPeriod.CheckInDate;
	pRIRec.PeriodTo = pPeriod.CheckOutDate;
	pRIRec.PeriodDuration = cmCalculateDuration(pPeriod.RoomRate, pRIRec.PeriodFrom, pRIRec.PeriodTo);
	pRIRec.CheckInAccountingDate = BegOfDay(CheckInDate);
	pRIRec.CheckOutAccountingDate = BegOfDay(CheckOutDate);
	pRIRec.CheckInDate = CheckInDate;
	pRIRec.CheckOutDate = CheckOutDate;
	pRIRec.Duration = Duration;
	
	If ValueIsFilled(pPeriod.RoomRate) Then
		pRIRec.RoomRateType = pPeriod.RoomRate.RoomRateType;
	EndIf;
	
	pRIRec.PricePresentation = PricePresentation;
	
	pRIRec.IsRoomQuota = True;
	
	If pRoomsRow <> Undefined Then
		pRIRec.Room = pRoomsRow.Room;
		pRIRec.NumberOfBedsPerRoom = pRoomsRow.NumberOfBedsPerRoom;
		pRIRec.NumberOfPersonsPerRoom = pRoomsRow.NumberOfPersonsPerRoom;
	EndIf;
	
	If Not RoomQuota.IsQuotaForRooms Then
		pRIRec.Room = Catalogs.Rooms.EmptyRef();
	EndIf;
	
	pRIRec.NumberOfRooms = pRoomsToWriteOff;
	pRIRec.NumberOfBeds = pBedsToWriteOff;
	
	// Fill register record resources
	pRIRec.RoomsInQuota = -pRoomsToWriteOff;
	pRIRec.BedsInQuota = -pBedsToWriteOff;
	pRIRec.RoomsVacant = -pRoomsToWriteOff;
	pRIRec.BedsVacant = -pBedsToWriteOff;
	
	pRIRec.Timestamp = CurrentSessionDate();
EndProcedure // FillRQRIAttributes

// -----------------------------------------------------------------------------
Procedure PostToRoomQuotaSales(pCancel, pPeriod, pRoomsRow = Undefined)
	If PersonsWriteOff = 0 And
	   RoomsWriteOff = 0 And
	   BedsWriteOff = 0 And
	   AdditionalBedsWriteOff = 0 Then
		Return;
	EndIf;
	
	vDoPeriodCorrection = False;
	If Not pPeriod.RoomQuota.DoWriteOff Or pPeriod.RoomQuota.DoWriteOff And pPeriod.RoomQuota.IsForCheckInPeriods Then
		vDoPeriodCorrection = True;
	EndIf;
	
	vRHCheckInDate = pPeriod.CheckInDate;
	vRHCheckOutDate = pPeriod.CheckOutDate;
	If BegOfDay(pPeriod.CheckInDate) <> BegOfDay(pPeriod.CheckOutDate) Then
		vRHCheckInDate = cmMovePeriodFromToReferenceHour(pPeriod.CheckInDate, pPeriod.RoomRate);
		vRHCheckOutDate = cmMovePeriodToToReferenceHour(pPeriod.CheckOutDate, pPeriod.RoomRate);
	EndIf;
	
	vEffectiveCheckInDate = pPeriod.CheckInDate;
	vEffectiveCheckOutDate = pPeriod.CheckOutDate;
	If BegOfDay(pPeriod.CheckInDate) <> BegOfDay(pPeriod.CheckOutDate) And vDoPeriodCorrection Then
		vEffectiveCheckInDate = vRHCheckInDate;
		vEffectiveCheckOutDate = vRHCheckOutDate;
	EndIf;
	
	// Do storno movements for room inventory
	If pPeriod.RoomQuota.DoWriteOff And vEffectiveCheckInDate < vEffectiveCheckOutDate Then
		If RoomsWriteOff > 0 Or
		   BedsWriteOff > 0 Then
			// Do expense movement on check in date
			vRIRec = RegisterRecords.RoomInventory.AddExpense();
			FillRQRIAttributes(vRIRec, vEffectiveCheckInDate, vEffectiveCheckInDate, vEffectiveCheckOutDate, pPeriod, pRoomsRow, RoomsWriteOff, BedsWriteOff);
				
			// Do receipt movement on check out date
			vRIRec = RegisterRecords.RoomInventory.AddReceipt();
			FillRQRIAttributes(vRIRec, vEffectiveCheckOutDate, vEffectiveCheckInDate, vEffectiveCheckOutDate, pPeriod, pRoomsRow, RoomsWriteOff, BedsWriteOff);
		EndIf;
	EndIf;

	// Do expense movement on check in date moved to reference hour
	If vEffectiveCheckInDate < vEffectiveCheckOutDate And 
	   BegOfDay(pPeriod.CheckInDate) <> BegOfDay(pPeriod.CheckOutDate) Then
		vRQRec = RegisterRecords.RoomQuotaSales.AddExpense();
		FillRQAttributes(vRQRec, vEffectiveCheckInDate, pPeriod, pRoomsRow);
			
		// Do receipt movement on check out date moved to reference hour
		vRQRec = RegisterRecords.RoomQuotaSales.AddReceipt();
		FillRQAttributes(vRQRec, vEffectiveCheckOutDate, pPeriod, pRoomsRow);
		
		// If allotment is tentative then we have to correct the number of tentative rooms booked
		If Not ReservationStatus.IsPreliminary Then
			vRoomQuota = pPeriod.RoomQuota;
			If ValueIsFilled(vRoomQuota) And (RoomsWriteOff <> 0 Or BedsWriteOff <> 0) And 
			  (vRoomQuota.TreatAsTentativeBooking Or vRoomQuota.ForecastIsUsed And vRoomQuota.FirstForecastUsageTime < Date) Then
				vRoomType = pPeriod.RoomType;
				If ValueIsFilled(RoomTypeUpgrade) And ValueIsFilled(RoomTypeUpgrade.BaseRoomType) And RoomTypeUpgrade.BaseRoomType = vRoomType Then
					vRoomType = RoomTypeUpgrade;
				EndIf;

				// Get tentative rooms balance if we are writing off tentative rooms from allotment
				vTentativeRoomsBalance = GetTentativeRoomsBalance(Hotel, vRoomQuota, vRoomType, vEffectiveCheckInDate, vEffectiveCheckOutDate);

				vBegOfDay = BegOfDay(vEffectiveCheckInDate);
				While vBegOfDay < BegOfDay(vEffectiveCheckOutDate) Or vBegOfDay = BegOfDay(vEffectiveCheckOutDate) And BegOfDay(vEffectiveCheckInDate) = BegOfDay(vEffectiveCheckOutDate) Do
					vTentativeRoomsBalanceRow = vTentativeRoomsBalance.Find(vBegOfDay, "Period");
					If vTentativeRoomsBalanceRow <> Undefined Then
						If vTentativeRoomsBalanceRow.RoomsForecast >= RoomsWriteOff And vTentativeRoomsBalanceRow.BedsForecast >= BedsWriteOff Then
							vEGGRec = RegisterRecords.ExpectedGuestGroups.Add();
							
							vEGGRec.Period = EndOfDay(vBegOfDay);
							vEGGRec.Recorder = Ref;
							
							vEGGRec.Hotel = Hotel;
							vEGGRec.RoomQuota = vRoomQuota;
							vEGGRec.ReservationStatus = ReservationStatus;
							vEGGRec.GuestGroup = GuestGroup;
							vEGGRec.RoomType = vRoomType;
							
							// Resources
							vEGGRec.RoomsReserved = -RoomsWriteOff;
							vEGGRec.BedsReserved = -BedsWriteOff;
							vEGGRec.AdditionalBedsReserved = 0;
							vEGGRec.GuestsReserved = 0;
						EndIf;
					EndIf;
					
					// Next date
					vBegOfDay = vBegOfDay + 24*3600;
				EndDo;
			EndIf;
		EndIf;
	EndIf;

	// Do receipt movement on begin of time to initialize room quota balances
	vRQRec = RegisterRecords.RoomQuotaSales.AddReceipt();
	FillRQInitializationAttributes(vRQRec, '20000101', pPeriod, pRoomsRow);
		
	// Do receipt initialization movements on each day from the room quota period
	If vRHCheckInDate < vRHCheckOutDate Then 
		vCurDate = cm0SecondShift(vRHCheckInDate);
		While vCurDate <= vRHCheckOutDate Do
			vRQRec = RegisterRecords.RoomQuotaSales.AddReceipt();
			FillRQInitializationAttributes(vRQRec, vCurDate, pPeriod, pRoomsRow);
			vCurDate = vCurDate + 24*3600;
		EndDo;		
	EndIf;
EndProcedure // PostToRoomQuotaSales

// -----------------------------------------------------------------------------
Procedure PostToRoomQuotaSalesDetailed(pCancel, pPeriod, pEffectiveNumberOfRoomsRow)
	// Allotment effective period
	vDoPeriodCorrection = False;
	If Not pPeriod.RoomQuota.DoWriteOff Or pPeriod.RoomQuota.DoWriteOff And pPeriod.RoomQuota.IsForCheckInPeriods Then
		vDoPeriodCorrection = True;
	EndIf;
	
	vRHCheckInDate = pEffectiveNumberOfRoomsRow.PeriodFrom;
	vRHCheckOutDate = pEffectiveNumberOfRoomsRow.PeriodTo;
	If BegOfDay(pEffectiveNumberOfRoomsRow.PeriodFrom) <> BegOfDay(pEffectiveNumberOfRoomsRow.PeriodTo) Then
		vRHCheckInDate = cmMovePeriodFromToReferenceHour(pEffectiveNumberOfRoomsRow.PeriodFrom, pPeriod.RoomRate);
		vRHCheckOutDate = cmMovePeriodToToReferenceHour(pEffectiveNumberOfRoomsRow.PeriodTo, pPeriod.RoomRate);
	EndIf;

	vEffectiveCheckInDate = pEffectiveNumberOfRoomsRow.PeriodFrom;
	vEffectiveCheckOutDate = pEffectiveNumberOfRoomsRow.PeriodTo;
	If BegOfDay(pEffectiveNumberOfRoomsRow.PeriodFrom) <> BegOfDay(pEffectiveNumberOfRoomsRow.PeriodTo) And vDoPeriodCorrection Then
		vEffectiveCheckInDate = vRHCheckInDate;
		vEffectiveCheckOutDate = vRHCheckOutDate;
	EndIf;
	
	// Do storno movements for room inventory
	If pPeriod.RoomQuota.DoWriteOff And vEffectiveCheckInDate < vEffectiveCheckOutDate Then
		vRoomsToWriteOff = pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms;
		vBedsToWriteOff = BedsWriteOff;
		If vRoomsToWriteOff > 0 Or
		   vBedsToWriteOff > 0 Then
			// Do expense movement on check in date
			vRIRec = RegisterRecords.RoomInventory.AddExpense();
			FillRQRIAttributes(vRIRec, vEffectiveCheckInDate, vEffectiveCheckInDate, vEffectiveCheckOutDate, pPeriod, Undefined, vRoomsToWriteOff, vBedsToWriteOff);
				
			// Do receipt movement on check out date
			vRIRec = RegisterRecords.RoomInventory.AddReceipt();
			FillRQRIAttributes(vRIRec, vEffectiveCheckOutDate, vEffectiveCheckInDate, vEffectiveCheckOutDate, pPeriod, Undefined, vRoomsToWriteOff, vBedsToWriteOff);
		EndIf;
	EndIf;

	// Do expense movement on check in date moved to reference hour
	If vEffectiveCheckInDate < vEffectiveCheckOutDate And 
	   BegOfDay(pEffectiveNumberOfRoomsRow.PeriodFrom) <> BegOfDay(pEffectiveNumberOfRoomsRow.PeriodTo) Then
		vRQRec = RegisterRecords.RoomQuotaSales.AddExpense();
		FillRQAttributesDetailed(vRQRec, vEffectiveCheckInDate, pPeriod, pEffectiveNumberOfRoomsRow.PeriodFrom, pEffectiveNumberOfRoomsRow.PeriodTo, pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms);
			
		// Do receipt movement on check out date moved to reference hour
		vRQRec = RegisterRecords.RoomQuotaSales.AddReceipt();
		FillRQAttributesDetailed(vRQRec, vEffectiveCheckOutDate, pPeriod, pEffectiveNumberOfRoomsRow.PeriodFrom, pEffectiveNumberOfRoomsRow.PeriodTo, pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms);
		
		// If allotment is tentative then we have to correct the number of tentative rooms booked
		If Not ReservationStatus.IsPreliminary Then
			vRoomQuota = pPeriod.RoomQuota;
			If ValueIsFilled(vRoomQuota) And (pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms <> 0 Or BedsWriteOff <> 0) And 
			  (vRoomQuota.TreatAsTentativeBooking Or vRoomQuota.ForecastIsUsed And vRoomQuota.FirstForecastUsageTime < Date) Then
				vRoomType = pPeriod.RoomType;
				If ValueIsFilled(RoomTypeUpgrade) And ValueIsFilled(RoomTypeUpgrade.BaseRoomType) And RoomTypeUpgrade.BaseRoomType = vRoomType Then
					vRoomType = RoomTypeUpgrade;
				EndIf;

				// Get tentative rooms balance if we are writing off tentative rooms from allotment
				vTentativeRoomsBalance = GetTentativeRoomsBalance(Hotel, vRoomQuota, vRoomType, vEffectiveCheckInDate, vEffectiveCheckOutDate);

				vBegOfDay = BegOfDay(vEffectiveCheckInDate);
				While vBegOfDay < BegOfDay(vEffectiveCheckOutDate) Or vBegOfDay = BegOfDay(vEffectiveCheckOutDate) And BegOfDay(vEffectiveCheckInDate) = BegOfDay(vEffectiveCheckOutDate) Do
					vTentativeRoomsBalanceRow = vTentativeRoomsBalance.Find(vBegOfDay, "Period");
					If vTentativeRoomsBalanceRow <> Undefined Then
						If vTentativeRoomsBalanceRow.RoomsForecast >= pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms And vTentativeRoomsBalanceRow.BedsForecast >= BedsWriteOff Then
							vEGGRec = RegisterRecords.ExpectedGuestGroups.Add();
							
							vEGGRec.Period = EndOfDay(vBegOfDay);
							vEGGRec.Recorder = Ref;
							
							vEGGRec.Hotel = Hotel;
							vEGGRec.RoomQuota = vRoomQuota;
							vEGGRec.ReservationStatus = ReservationStatus;
							vEGGRec.GuestGroup = GuestGroup;
							vEGGRec.RoomType = vRoomType;
							
							// Resources
							vEGGRec.RoomsReserved = -pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms;
							vEGGRec.BedsReserved = -BedsWriteOff;
							vEGGRec.AdditionalBedsReserved = 0;
							vEGGRec.GuestsReserved = 0;
						EndIf;
					EndIf;
					
					// Next date
					vBegOfDay = vBegOfDay + 24*3600;
				EndDo;
			EndIf;
		EndIf;
	EndIf;

	// Do receipt movement on begin of time to initialize room quota balances
	vRQRec = RegisterRecords.RoomQuotaSales.AddReceipt();
	FillRQInitializationAttributes(vRQRec, '20000101', pPeriod);
		
	// Do receipt initialization movements on each day from the room quota period
	If vRHCheckInDate < vRHCheckOutDate Then 
		vCurDate = cm0SecondShift(vRHCheckInDate);
		While vCurDate <= vRHCheckOutDate Do
			vRQRec = RegisterRecords.RoomQuotaSales.AddReceipt();
			FillRQInitializationAttributes(vRQRec, vCurDate, pPeriod);
			vCurDate = vCurDate + 24*3600;
		EndDo;		
	EndIf;
EndProcedure // PostToRoomQuotaSalesDetailed

// -----------------------------------------------------------------------------
Procedure FillSFAttributes(pSFRec, pSrvRec, pDate, pServiceDate, pRoomsRow, pSrvService, pSrvQuantity, pSrvVATRate, pSrvSumInReportingCurrency, pSrvVATSumInReportingCurrency, pSrvDiscountSumInReportingCurrency, pSrvVATDiscountSumInReportingCurrency, pSrvCommissionSumInReportingCurrency, pSrvVATCommissionSumInReportingCurrency, pIsInRoomRevenue = True, pPersonIndex = 0, pAccommodationTemplate = Undefined, pAccommodationType = Undefined, pClient = Undefined)
	vIsMainService = True;
	vMainService = pSrvRec.Service;
	If pSrvService <> pSrvRec.Service Then
		vIsMainService = False;
	EndIf;
	
	FillPropertyValues(pSFRec, ThisObject);
	FillPropertyValues(pSFRec, pSrvRec);
	
	pSFRec.Service = pSrvService;
	
	pSFRec.ServiceDate = pServiceDate;
	
	// Fill customer, contract and payment method from the folio
	vSrvRecFolio = pSrvRec.Folio;
	If ValueIsFilled(vSrvRecFolio) Then
		pSFRec.Customer = vSrvRecFolio.Customer;
		pSFRec.Contract = vSrvRecFolio.Contract;
		pSFRec.Agent = vSrvRecFolio.Agent;
		pSFRec.PaymentMethod = vSrvRecFolio.PaymentMethod;
		If ValueIsFilled(vSrvRecFolio.GuestGroup) Then
			pSFRec.GuestGroup = vSrvRecFolio.GuestGroup;
		EndIf;
	EndIf;
	
	// Fill hotel product
	If ValueIsFilled(vMainService) And vMainService.IsHotelProductService Then
		If ValueIsFilled(pSFRec.Folio.HotelProduct) Then
			pSFRec.HotelProduct = pSFRec.Folio.HotelProduct;
		EndIf;
	Else
		pSFRec.HotelProduct = Catalogs.HotelProducts.EmptyRef();
	EndIf;
	
	// Fill client
	pSFRec.Client = Guest;
	If ValueIsFilled(pClient) Then
		pSFRec.Client = pClient;
	EndIf;
	If ValueIsFilled(pSFRec.Client) Then
		vWrkClient = pSFRec.Client;
		pSFRec.Age = vWrkClient.Age;
		pSFRec.AgeRange = vWrkClient.AgeRange;
	Else
		pSFRec.Age = 0;
		pSFRec.AgeRange = Undefined;
	EndIf;
	
	// Fill analitical parameters
	If Not ValueIsFilled(pSFRec.ClientType) And ValueIsFilled(ClientType) Then
		pSFRec.ClientType = ClientType;
	EndIf;
	If Not ValueIsFilled(pSFRec.MarketingCode) And ValueIsFilled(MarketingCode) Then
		pSFRec.MarketingCode = MarketingCode;
	EndIf;
	If Not ValueIsFilled(pSFRec.SourceOfBusiness) And ValueIsFilled(SourceOfBusiness) Then
		pSFRec.SourceOfBusiness = SourceOfBusiness;
	EndIf;
	If Not ValueIsFilled(pSFRec.BoardPlace) And ValueIsFilled(BoardPlace) Then
		pSFRec.BoardPlace = BoardPlace;
	EndIf;
	
	// Fill accomodation parameters
	If Not ValueIsFilled(pSrvRec.RoomRate) Then
		pSFRec.RoomRate = RoomRate;
	EndIf;
	If Not ValueIsFilled(pSrvRec.AccommodationType) Then
		pSFRec.AccommodationType = AccommodationType;
	EndIf;
	If ValueIsFilled(pAccommodationType) Then
		pSFRec.AccommodationType = pAccommodationType;
	EndIf;
	If Not ValueIsFilled(pSrvRec.RoomType) Then
		pSFRec.RoomType = RoomType;
	EndIf;
	If Not ValueIsFilled(pSrvRec.Room) Then
		pSFRec.Room = Room;
	EndIf;
	pSFRec.ResourceType = Catalogs.ResourceTypes.EmptyRef();
	If ValueIsFilled(pSrvRec.ServiceResource) And TypeOf(pSrvRec.ServiceResource) = Type("CatalogRef.Resources") Then
		pSFRec.Resource = pSrvRec.ServiceResource;
		pSFRec.ResourceType = pSFRec.Resource.Owner;
	EndIf;
	
	pSFRec.Period = pDate;
	pSFRec.ParentDoc = Ref;
	
	If ValueIsFilled(pAccommodationTemplate) Then
		pSFRec.AccommodationTemplate = pAccommodationTemplate;
	EndIf;
	
	If pRoomsRow <> Undefined Then
		pSFRec.Room = pRoomsRow.Room;
		If vIsMainService And Not pSrvRec.IsSplit Then
			pSFRec.NumberOfBedsPerRoom = pRoomsRow.NumberOfBedsPerRoom;
			pSFRec.NumberOfPersonsPerRoom = pRoomsRow.NumberOfPersonsPerRoom;
		EndIf;
	EndIf;
	
	If vIsMainService And Not pSrvRec.IsSplit Then
		pSFRec.NumberOfRooms = RoomsWriteOff;
		pSFRec.NumberOfBeds = BedsWriteOff;
		pSFRec.NumberOfAdditionalBeds = AdditionalBedsWriteOff;
		pSFRec.NumberOfPersons = PersonsWriteOff;
	Else
		pSFRec.NumberOfRooms = 0;
		pSFRec.NumberOfBeds = 0;
		pSFRec.NumberOfAdditionalBeds = 0;
		pSFRec.NumberOfPersons = 0;
	EndIf;
	
	// Calculate write off coefficient
	vWriteOffCoeff = 1;
	If NumberOfPersons > 0 Then
		vWriteOffCoeff = PersonsWriteOff / NumberOfPersons;
	EndIf;
	
	vSrvRecPrice = pSrvSumInReportingCurrency;
	If pSrvQuantity <> 0 Then
		vSrvRecPrice = cmRecalculatePrice(pSrvSumInReportingCurrency, pSrvQuantity);
	EndIf;
	
	// Recalculate forecast resources according to the write off coefficient
	vSrvRec = New Structure("Price, Quantity, Sum, VATRate, VATSum, DiscountSum, VATDiscountSum, CommissionSum, VATCommissionSum, RoomsRented, BedsRented, AdditionalBedsRented, GuestDays, GuestsCheckedIn, RateSum, RateDiscountSum", 
	                        vSrvRecPrice, pSrvQuantity, pSrvSumInReportingCurrency, pSrvVATRate, pSrvVATSumInReportingCurrency, pSrvDiscountSumInReportingCurrency, pSrvVATDiscountSumInReportingCurrency, pSrvCommissionSumInReportingCurrency, pSrvVATCommissionSumInReportingCurrency, pSrvRec.RoomsRented, pSrvRec.BedsRented, pSrvRec.AdditionalBedsRented, pSrvRec.GuestDays, pSrvRec.GuestsCheckedIn, ?(vIsMainService, Round(cmConvertCurrencies(pSrvRec.RateSum, pSrvRec.FolioCurrency, , ReportingCurrency, , ?(ValueIsFilled(pSrvRec.AccountingDate), pSrvRec.AccountingDate, ExchangeRateDate), Hotel), 2), 0), ?(vIsMainService, Round(cmConvertCurrencies(pSrvRec.RateDiscountSum, pSrvRec.FolioCurrency, , ReportingCurrency, , ?(ValueIsFilled(pSrvRec.AccountingDate), pSrvRec.AccountingDate, ExchangeRateDate), Hotel), 2), 0));
	If vWriteOffCoeff <> 1 Then
		vSrvRec.Quantity = Round(vWriteOffCoeff * vSrvRec.Quantity, 7);
		vSrvRec.Sum = Round(vSrvRec.Price * vSrvRec.Quantity, 2);
		vSrvRec.VATSum = cmCalculateVATSum(vSrvRec.VATRate, vSrvRec.Sum, pDate);
		vSrvRec.DiscountSum = Round(vWriteOffCoeff * vSrvRec.DiscountSum, 2);
		vSrvRec.VATDiscountSum = Round(vWriteOffCoeff * vSrvRec.VATDiscountSum, 2);
		vSrvRec.CommissionSum = Round(vWriteOffCoeff * vSrvRec.CommissionSum, 2);
		vSrvRec.VATCommissionSum = Round(vWriteOffCoeff * vSrvRec.VATCommissionSum, 2);
		vSrvRec.RoomsRented = Round(vWriteOffCoeff * vSrvRec.RoomsRented, 7);
		vSrvRec.BedsRented = Round(vWriteOffCoeff * vSrvRec.BedsRented, 7);
		vSrvRec.AdditionalBedsRented = Round(vWriteOffCoeff * vSrvRec.AdditionalBedsRented, 7);
		vSrvRec.GuestDays = Round(vWriteOffCoeff * vSrvRec.GuestDays, 7);
		vSrvRec.GuestsCheckedIn = Round(vWriteOffCoeff * vSrvRec.GuestsCheckedIn, 7);
		If pSrvRec.Quantity <> 0 Then
			vSrvRec.RateSum = Round(vSrvRec.RateSum / pSrvRec.Quantity * vSrvRec.Quantity, 2);
			vSrvRec.RateDiscountSum = Round(vSrvRec.RateDiscountSum / pSrvRec.Quantity * vSrvRec.Quantity, 2);
		EndIf;
	EndIf;	
	
	vSumInFolioCurrency = Round(cmConvertCurrencies(vSrvRec.Sum, ReportingCurrency, , pSrvRec.FolioCurrency, , ?(ValueIsFilled(pSrvRec.AccountingDate), pSrvRec.AccountingDate, ExchangeRateDate), Hotel), 2);
	
	pSFRec.Sales = vSrvRec.Sum;
	pSFRec.VATSum = cmCalculateVATSum(vSrvRec.VATRate, vSrvRec.Sum, pSrvRec.AccountingDate);
	pSFRec.SalesWithoutVAT = pSFRec.Sales - pSFRec.VATSum;
	If pSrvRec.IsRoomRevenue And pIsInRoomRevenue Then
		pSFRec.RoomRevenue = pSFRec.Sales;
		pSFRec.RoomRevenueWithoutVAT = pSFRec.SalesWithoutVAT;
	Else
		pSFRec.RoomRevenue = 0;
		pSFRec.RoomRevenueWithoutVAT = 0;
	EndIf;
	If vSrvRec.AdditionalBedsRented <> 0 And pIsInRoomRevenue Then
		pSFRec.ExtraBedRevenue = pSFRec.Sales;
		pSFRec.ExtraBedRevenueWithoutVAT = pSFRec.SalesWithoutVAT;
	Else
		pSFRec.ExtraBedRevenue = 0;
		pSFRec.ExtraBedRevenueWithoutVAT = 0;
	EndIf;
	pSFRec.Quantity = vSrvRec.Quantity;
	pSFRec.Price = cmRecalculatePrice(vSrvRec.Sum, vSrvRec.Quantity);
	pSFRec.ResourceRevenue = 0;
	pSFRec.ResourceRevenueWithoutVAT = 0;
	pSFRec.HoursRented = 0;
	
	pSFRec.CommissionSum = vSrvRec.CommissionSum;
	pSFRec.CommissionSumWithoutVAT = vSrvRec.CommissionSum - vSrvRec.VATCommissionSum;
	
	pSFRec.DiscountSum = vSrvRec.DiscountSum;
	pSFRec.DiscountSumWithoutVAT = vSrvRec.DiscountSum - vSrvRec.VATDiscountSum;
	
	If vIsMainService Then
		pSFRec.RoomsRented = vSrvRec.RoomsRented;
		pSFRec.BedsRented = vSrvRec.BedsRented;
		pSFRec.AdditionalBedsRented = vSrvRec.AdditionalBedsRented;
		pSFRec.GuestDays = vSrvRec.GuestDays;
		pSFRec.GuestsCheckedIn = vSrvRec.GuestsCheckedIn;
	Else
		pSFRec.RoomsRented = 0;
		pSFRec.BedsRented = 0;
		pSFRec.AdditionalBedsRented = 0;
		pSFRec.GuestDays = 0;
		pSFRec.GuestsCheckedIn = 0;
	EndIf;
	
	// Fill check-in resources
	pSFRec.RoomsCheckedIn = 0;
	pSFRec.BedsCheckedIn = 0;
	pSFRec.AdditionalBedsCheckedIn = 0;
	pSFRec.BookingWindow = 0;
	If vIsMainService And pSFRec.GuestsCheckedIn <> 0 And pSFRec.Quantity <> 0 Then
		pSFRec.RoomsCheckedIn = pSFRec.RoomsRented;
		pSFRec.BedsCheckedIn = pSFRec.BedsRented;
		pSFRec.AdditionalBedsCheckedIn = pSFRec.AdditionalBedsRented;
		If pSFRec.RoomsCheckedIn <> 0 Then
			pSFRec.BookingWindow = Round((BegOfDay(CheckInDate) - BegOfDay(Date))/(24*3600)*?(pSFRec.RoomsCheckedIn > 1, pSFRec.RoomsCheckedIn, 1), 0);
		EndIf;
	EndIf;
	
	If vIsMainService And Not pSrvRec.IsManual And vSrvRec.RateSum <> 0 Then
		pSFRec.RateSum = vSrvRec.RateSum - vSrvRec.RateDiscountSum;
	Else
		pSFRec.RateSum = 0;
	EndIf;
	
	// Check if customer and agent are the same
	If ValueIsFilled(vSrvRecFolio) Then
		vDoNotPostCommission = False;
		If ValueIsFilled(vSrvRecFolio.Agent) And vSrvRecFolio.Agent.DoNotPostCommission Then
			vDoNotPostCommission = True;
		EndIf;
		If Not vDoNotPostCommission Then
			If ValueIsFilled(vSrvRecFolio.Agent) And 
			   vSrvRecFolio.Agent <> vSrvRecFolio.Customer And 
			   vSrvRec.CommissionSum <> 0 Then
				pSFRec.CommissionSum = 0;
				pSFRec.CommissionSumWithoutVAT = 0;
			
				// Add new record
				If pPersonIndex = 0 Then
					vSFRec = RegisterRecords.SalesForecast.Add();
					FillPropertyValues(vSFRec, pSFRec, , "RecordType");
					
					// Fill dimensions
					vSFRec.Customer = vSrvRecFolio.Agent;
					vSFRec.Contract = vSrvRecFolio.Agent.AgentCommissionContract;
					vSFRec.Agent = vSrvRecFolio.Agent;
					vSFRec.GuestGroup = Catalogs.GuestGroups.EmptyRef();
					
					// Reset resources
					vSFRec.Sales = 0;
					vSFRec.SalesWithoutVAT = 0;
					vSFRec.RoomRevenue = 0;
					vSFRec.RoomRevenueWithoutVAT = 0;
					vSFRec.ExtraBedRevenue = 0;
					vSFRec.ExtraBedRevenueWithoutVAT = 0;
					vSFRec.Quantity = 0;
					vSFRec.DiscountSum = 0;
					vSFRec.DiscountSumWithoutVAT = 0;
					vSFRec.RoomsRented = 0;
					vSFRec.BedsRented = 0;
					vSFRec.AdditionalBedsRented = 0;
					vSFRec.GuestDays = 0;
					vSFRec.GuestsCheckedIn = 0;
					vSFRec.RoomsCheckedIn = 0;
					vSFRec.BedsCheckedIn = 0;
					vSFRec.AdditionalBedsCheckedIn = 0;
					vSFRec.BookingWindow = 0;
					
					vSFRec.RateSum = 0;
					
					// Fill commission
					vSFRec.CommissionSum = vSrvRec.CommissionSum;
					vSFRec.CommissionSumWithoutVAT = vSrvRec.CommissionSum - vSrvRec.VATCommissionSum;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // FillSFAttributes

// -----------------------------------------------------------------------------
Procedure PostToServiceRegistration(pServiceDate, pService, pBoardPlace, pRoom, pResource, pGuestGroup, pFolio, pClient, pSum, pQuantity, pRemarks)
	vServiceDate = pServiceDate;  

	Movement = RegisterRecords.ServiceRegistration.Add();
	
	Movement.RecordType = AccumulationRecordType.Receipt;

	Movement.Period = vServiceDate;
	Movement.AccountingDate = BegOfDay(Movement.Period);

	Movement.Service = pService;
	Movement.BoardPlace = pBoardPlace;
	Movement.Room = pRoom;
	Movement.Resource = pResource;
	Movement.Client = pClient;
	Movement.GuestGroup = ?(ValueIsFilled(pFolio.GuestGroup), pFolio.Guestgroup, pGuestGroup);
	Movement.FolioCurrency = pFolio.FolioCurrency;
	Movement.Folio = pFolio;
	Movement.ParentDoc = Ref;
	Movement.Hotel = Hotel;
	
	// Resources
	Movement.Sum = Round(cmConvertCurrencies(pSum, ReportingCurrency, ReportingCurrencyExchangeRate, pFolio.FolioCurrency, , ExchangeRateDate, Hotel), 2);
	Movement.Quantity = pQuantity;
	
	// Attributes
	Movement.Price = cmRecalculatePrice(Movement.Sum, Movement.Quantity);
	Movement.Unit = pService.Unit;
	Movement.Author = SessionParameters.CurrentUser;
	
	RegisterRecords.ServiceRegistration.Write = True;
EndProcedure // PostToServiceRegistration

// -----------------------------------------------------------------------------
Procedure FillARFAttributes(pARFRec, pSrvRec, pDate, pRoomsRow)
	FillPropertyValues(pARFRec, ThisObject);
	FillPropertyValues(pARFRec, pSrvRec);
	
	pARFRec.Period = pDate;
	pARFRec.ParentDoc = Ref;
	
	// Fill client
	pARFRec.Client = Guest;
	
	// Fill accommodation parameters
	If Not ValueIsFilled(pSrvRec.RoomRate) Then
		pARFRec.RoomRate = RoomRate;
	EndIf;
	If Not ValueIsFilled(pSrvRec.AccommodationType) Then
		pARFRec.AccommodationType = AccommodationType;
	EndIf;
	If Not ValueIsFilled(pSrvRec.RoomType) Then
		pARFRec.RoomType = RoomType;
	EndIf;
	If Not ValueIsFilled(pSrvRec.Room) Then
		pARFRec.Room = Room;
	EndIf;
	If ValueIsFilled(pSrvRec.ServiceResource) And TypeOf(pSrvRec.ServiceResource) = Type("CatalogRef.Resources") Then
		pARFRec.Resource = pSrvRec.ServiceResource;
	EndIf;
	
	// Fill customer, contract and payment method from the folio
	vSrvRecFolio = pSrvRec.Folio;
	If ValueIsFilled(vSrvRecFolio) Then
		pARFRec.Customer = vSrvRecFolio.Customer;
		pARFRec.Contract = vSrvRecFolio.Contract;
		pARFRec.Agent = vSrvRecFolio.Agent;
		pARFRec.PaymentMethod = vSrvRecFolio.PaymentMethod;
		If ValueIsFilled(vSrvRecFolio.GuestGroup) Then
			pARFRec.GuestGroup = vSrvRecFolio.GuestGroup;
		EndIf;
	EndIf;
	
	// Calculate write off coefficient
	vWriteOffCoeff = 1;
	If NumberOfPersons > 0 Then
		vWriteOffCoeff = PersonsWriteOff / NumberOfPersons;
	EndIf;
	
	// Recalculate forecast resources according to the write off coefficient
	vSrvRec = New Structure("Price, Quantity, Sum, VATRate, VATSum, DiscountSum, VATDiscountSum, CommissionSum, VATCommissionSum, RoomsRented, BedsRented, AdditionalBedsRented, GuestDays, GuestsCheckedIn", 
	                        pSrvRec.Price, pSrvRec.Quantity, pSrvRec.Sum, pSrvRec.VATRate, pSrvRec.VATSum, pSrvRec.DiscountSum, pSrvRec.VATDiscountSum, pSrvRec.CommissionSum, pSrvRec.VATCommissionSum, pSrvRec.RoomsRented, pSrvRec.BedsRented, pSrvRec.AdditionalBedsRented, pSrvRec.GuestDays, pSrvRec.GuestsCheckedIn);
	If vWriteOffCoeff <> 1 Then
		vSrvRec.Quantity = Round(vWriteOffCoeff * vSrvRec.Quantity, 7);
		vSrvRec.Sum = Round(vSrvRec.Price * vSrvRec.Quantity, 2);
		vSrvRec.VATSum = cmCalculateVATSum(vSrvRec.VATRate, vSrvRec.Sum, pDate);
		vSrvRec.DiscountSum = Round(vWriteOffCoeff * vSrvRec.DiscountSum, 2);
		vSrvRec.VATDiscountSum = Round(vWriteOffCoeff * vSrvRec.VATDiscountSum, 2);
		vSrvRec.CommissionSum = Round(vWriteOffCoeff * vSrvRec.CommissionSum, 2);
		vSrvRec.VATCommissionSum = Round(vWriteOffCoeff * vSrvRec.VATCommissionSum, 2);
		vSrvRec.RoomsRented = Round(vWriteOffCoeff * vSrvRec.RoomsRented, 7);
		vSrvRec.BedsRented = Round(vWriteOffCoeff * vSrvRec.BedsRented, 7);
		vSrvRec.AdditionalBedsRented = Round(vWriteOffCoeff * vSrvRec.AdditionalBedsRented, 7);
		vSrvRec.GuestDays = Round(vWriteOffCoeff * vSrvRec.GuestDays, 7);
		vSrvRec.GuestsCheckedIn = Round(vWriteOffCoeff * vSrvRec.GuestsCheckedIn, 7);
	EndIf;	
	
	vSumInFolioCurrency = vSrvRec.Sum - vSrvRec.DiscountSum;
	vVATSumInFolioCurrency = vSrvRec.VATSum - vSrvRec.VATDiscountSum;
	pARFRec.Sales = vSumInFolioCurrency;
	pARFRec.SalesWithoutVAT = vSumInFolioCurrency - vVATSumInFolioCurrency;
	If pSrvRec.IsRoomRevenue Then
		pARFRec.RoomRevenue = vSumInFolioCurrency;
		pARFRec.RoomRevenueWithoutVAT = vSumInFolioCurrency - vVATSumInFolioCurrency;
	EndIf;
	If vSrvRec.AdditionalBedsRented <> 0 Then
		pARFRec.ExtraBedRevenue = vSumInFolioCurrency;
		pARFRec.ExtraBedRevenueWithoutVAT = vSumInFolioCurrency - vVATSumInFolioCurrency;
	EndIf;
	pARFRec.Price = cmRecalculatePrice(vSumInFolioCurrency, vSrvRec.Quantity);
	pARFRec.Quantity = vSrvRec.Quantity;
	
	vDiscountSumInFolioCurrency = vSrvRec.DiscountSum;
	vVATDiscountSumInFolioCurrency = vSrvRec.VATDiscountSum;
	pARFRec.DiscountSum = vDiscountSumInFolioCurrency;
	pARFRec.DiscountSumWithoutVAT = vDiscountSumInFolioCurrency - vVATDiscountSumInFolioCurrency;
	
	pARFRec.RoomsRented = vSrvRec.RoomsRented;
	pARFRec.BedsRented = vSrvRec.BedsRented;
	pARFRec.AdditionalBedsRented = vSrvRec.AdditionalBedsRented;
	pARFRec.GuestDays = vSrvRec.GuestDays;
	pARFRec.GuestsCheckedIn = vSrvRec.GuestsCheckedIn;
	
	// Fill check-in resources
	pARFRec.RoomsCheckedIn = 0;
	pARFRec.BedsCheckedIn = 0;
	pARFRec.AdditionalBedsCheckedIn = 0;
	pARFRec.BookingWindow = 0;
	If pARFRec.GuestsCheckedIn <> 0 And pARFRec.Quantity <> 0 Then
		pARFRec.RoomsCheckedIn = pARFRec.RoomsRented;
		pARFRec.BedsCheckedIn = pARFRec.BedsRented;
		pARFRec.AdditionalBedsCheckedIn = pARFRec.AdditionalBedsRented;
		If pARFRec.RoomsCheckedIn <> 0 Then
			pARFRec.BookingWindow = Round((BegOfDay(CheckInDate) - BegOfDay(Date))/(24*3600)*?(pARFRec.RoomsCheckedIn > 1, pARFRec.RoomsCheckedIn, 1), 0);
		EndIf;
	EndIf;
	
	vSumInFolioCurrency = pSrvRec.Sum - pSrvRec.DiscountSum;
	vVATSumInFolioCurrency = pSrvRec.VATSum - pSrvRec.VATDiscountSum;
	
	pARFRec.ExpectedQuantity = pSrvRec.Quantity;
	pARFRec.ExpectedSales = vSumInFolioCurrency;
	pARFRec.ExpectedSalesWithoutVAT = vSumInFolioCurrency - vVATSumInFolioCurrency;
	If pSrvRec.IsRoomRevenue Then
		pARFRec.ExpectedRoomRevenue = vSumInFolioCurrency;
		pARFRec.ExpectedRoomRevenueWithoutVAT = vSumInFolioCurrency - vVATSumInFolioCurrency;
	EndIf;
	If pSrvRec.AdditionalBedsRented <> 0 Then
		pARFRec.ExpectedExtraBedRevenue = vSumInFolioCurrency;
		pARFRec.ExpectedExtraBedRevenueWithoutVAT = vSumInFolioCurrency - vVATSumInFolioCurrency;
	EndIf;
	
	vDiscountSumInFolioCurrency = pSrvRec.DiscountSum;
	vVATDiscountSumInFolioCurrency = pSrvRec.VATDiscountSum;
	pARFRec.ExpectedDiscountSum = vDiscountSumInFolioCurrency;
	pARFRec.ExpectedDiscountSumWithoutVAT = vDiscountSumInFolioCurrency - vVATDiscountSumInFolioCurrency;
	
	pARFRec.ExpectedRoomsRented = pSrvRec.RoomsRented;
	pARFRec.ExpectedBedsRented = pSrvRec.BedsRented;
	pARFRec.ExpectedAdditionalBedsRented = pSrvRec.AdditionalBedsRented;
	pARFRec.ExpectedGuestDays = pSrvRec.GuestDays;
	pARFRec.ExpectedGuestsCheckedIn = pSrvRec.GuestsCheckedIn;
	
	// Fill check-in resources
	pARFRec.ExpectedBookingWindow = 0;
	pARFRec.ExpectedRoomsCheckedIn = 0;
	pARFRec.ExpectedBedsCheckedIn = 0;
	pARFRec.ExpectedAdditionalBedsCheckedIn = 0;
	If pARFRec.ExpectedGuestsCheckedIn <> 0 And pARFRec.ExpectedQuantity <> 0 Then
		pARFRec.ExpectedRoomsCheckedIn = pARFRec.ExpectedRoomsRented;
		pARFRec.ExpectedBedsCheckedIn = pARFRec.ExpectedBedsRented;
		pARFRec.ExpectedAdditionalBedsCheckedIn = pARFRec.ExpectedAdditionalBedsRented;
		If pARFRec.ExpectedRoomsCheckedIn <> 0 Then
			pARFRec.ExpectedBookingWindow = Round((BegOfDay(CheckInDate) - BegOfDay(Date))/(24*3600)*?(pARFRec.ExpectedRoomsCheckedIn > 1, pARFRec.ExpectedRoomsCheckedIn, 1), 0);
		EndIf;
	EndIf;
	
	// Commission sum
	pARFRec.CommissionSum = vSrvRec.CommissionSum;
	pARFRec.CommissionSumWithoutVAT = vSrvRec.CommissionSum - vSrvRec.VATCommissionSum;
	pARFRec.ExpectedCommissionSum = pSrvRec.CommissionSum;
	pARFRec.ExpectedCommissionSumWithoutVAT = pSrvRec.CommissionSum - pSrvRec.VATCommissionSum;
	
	// Check if customer and agent are the same
	If ValueIsFilled(vSrvRecFolio) Then
		vDoNotPostCommission = False;
		If ValueIsFilled(vSrvRecFolio.Agent) And vSrvRecFolio.Agent.DoNotPostCommission Then
			vDoNotPostCommission = True;
		EndIf;
		If vDoNotPostCommission Then
			pARFRec.CommissionSum = 0;
			pARFRec.CommissionSumWithoutVAT = 0;
			pARFRec.ExpectedCommissionSum = 0;
			pARFRec.ExpectedCommissionSumWithoutVAT = 0;
		Else
			If ValueIsFilled(vSrvRecFolio.Agent) And 
			   vSrvRecFolio.Agent <> vSrvRecFolio.Customer And 
			   (pSrvRec.CommissionSum <> 0 Or vSrvRec.CommissionSum <> 0) Then
				pARFRec.CommissionSum = 0;
				pARFRec.CommissionSumWithoutVAT = 0;
				pARFRec.ExpectedCommissionSum = 0;
				pARFRec.ExpectedCommissionSumWithoutVAT = 0;
			
				// Add new record
				vARFRec = RegisterRecords.AccountsReceivableForecast.Add();
				FillPropertyValues(vARFRec, pARFRec, , "RecordType");
				
				// Fill dimensions
				vARFRec.Customer = vSrvRecFolio.Agent;
				vARFRec.Contract = vSrvRecFolio.Agent.AgentCommissionContract;
				vARFRec.Agent = vSrvRecFolio.Agent;
				vARFRec.GuestGroup = Catalogs.GuestGroups.EmptyRef();
				
				// Reset resources
				vARFRec.Sales = 0;
				vARFRec.SalesWithoutVAT = 0;
				vARFRec.RoomRevenue = 0;
				vARFRec.RoomRevenueWithoutVAT = 0;
				vARFRec.ExtraBedRevenue = 0;
				vARFRec.ExtraBedRevenueWithoutVAT = 0;
				vARFRec.Quantity = 0;
				vARFRec.DiscountSum = 0;
				vARFRec.DiscountSumWithoutVAT = 0;
				vARFRec.RoomsRented = 0;
				vARFRec.BedsRented = 0;
				vARFRec.AdditionalBedsRented = 0;
				vARFRec.GuestDays = 0;
				vARFRec.GuestsCheckedIn = 0;
				vARFRec.RoomsCheckedIn = 0;
				vARFRec.BedsCheckedIn = 0;
				vARFRec.AdditionalBedsCheckedIn = 0;
				vARFRec.BookingWindow = 0;
					
				vARFRec.ExpectedSales = 0;
				vARFRec.ExpectedSalesWithoutVAT = 0;
				vARFRec.ExpectedRoomRevenue = 0;
				vARFRec.ExpectedRoomRevenueWithoutVAT = 0;
				vARFRec.ExpectedExtraBedRevenue = 0;
				vARFRec.ExpectedExtraBedRevenueWithoutVAT = 0;
				vARFRec.ExpectedQuantity = 0;
				vARFRec.ExpectedDiscountSum = 0;
				vARFRec.ExpectedDiscountSumWithoutVAT = 0;
				vARFRec.ExpectedRoomsRented = 0;
				vARFRec.ExpectedBedsRented = 0;
				vARFRec.ExpectedAdditionalBedsRented = 0;
				vARFRec.ExpectedGuestDays = 0;
				vARFRec.ExpectedGuestsCheckedIn = 0;
				vARFRec.ExpectedRoomsCheckedIn = 0;
				vARFRec.ExpectedBedsCheckedIn = 0;
				vARFRec.ExpectedAdditionalBedsCheckedIn = 0;
				vARFRec.ExpectedBookingWindow = 0;
				
				// Fill commission
				vARFRec.CommissionSum = vSrvRec.CommissionSum;
				vARFRec.CommissionSumWithoutVAT = vSrvRec.CommissionSum - vSrvRec.VATCommissionSum;
				vARFRec.ExpectedCommissionSum = pSrvRec.CommissionSum;
				vARFRec.ExpectedCommissionSumWithoutVAT = pSrvRec.CommissionSum - pSrvRec.VATCommissionSum;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // FillARFAttributes

// -----------------------------------------------------------------------------
Procedure FillExpectedARFAttributes(pARFRec, pSrvRec, pDate)
	FillPropertyValues(pARFRec, ThisObject);
	FillPropertyValues(pARFRec, pSrvRec);
	
	pARFRec.Period = pDate;
	pARFRec.ParentDoc = Ref;
	
	// Fill client
	pARFRec.Client = Guest;
	
	// Fill accommodation parameters
	If Not ValueIsFilled(pSrvRec.RoomRate) Then
		pARFRec.RoomRate = RoomRate;
	EndIf;
	If Not ValueIsFilled(pSrvRec.AccommodationType) Then
		pARFRec.AccommodationType = AccommodationType;
	EndIf;
	If Not ValueIsFilled(pSrvRec.RoomType) Then
		pARFRec.RoomType = RoomType;
	EndIf;
	If Not ValueIsFilled(pSrvRec.Room) Then
		pARFRec.Room = Room;
	EndIf;
	If ValueIsFilled(pSrvRec.ServiceResource) And TypeOf(pSrvRec.ServiceResource) = Type("CatalogRef.Resources") Then
		pARFRec.Resource = pSrvRec.ServiceResource;
	EndIf;
	
	// Fill customer, contract and payment method from the folio
	vSrvRecFolio = pSrvRec.Folio;
	If ValueIsFilled(vSrvRecFolio) Then
		pARFRec.Customer = vSrvRecFolio.Customer;
		pARFRec.Contract = vSrvRecFolio.Contract;
		pARFRec.Agent = vSrvRecFolio.Agent;
		pARFRec.PaymentMethod = vSrvRecFolio.PaymentMethod;
		If ValueIsFilled(vSrvRecFolio.GuestGroup) Then
			pARFRec.GuestGroup = vSrvRecFolio.GuestGroup;
		EndIf;
	EndIf;
	
	vSumInFolioCurrency = pSrvRec.Sum - pSrvRec.DiscountSum;
	vVATSumInFolioCurrency = pSrvRec.VATSum - pSrvRec.VATDiscountSum;
	pARFRec.ExpectedSales = vSumInFolioCurrency;
	pARFRec.ExpectedSalesWithoutVAT = vSumInFolioCurrency - vVATSumInFolioCurrency;
	If pSrvRec.IsRoomRevenue Then
		pARFRec.ExpectedRoomRevenue = vSumInFolioCurrency;
		pARFRec.ExpectedRoomRevenueWithoutVAT = vSumInFolioCurrency - vVATSumInFolioCurrency;
	EndIf;
	If pSrvRec.AdditionalBedsRented <> 0 Then
		pARFRec.ExpectedExtraBedRevenue = vSumInFolioCurrency;
		pARFRec.ExpectedExtraBedRevenueWithoutVAT = vSumInFolioCurrency - vVATSumInFolioCurrency;
	EndIf;
	pARFRec.Price = cmRecalculatePrice(vSumInFolioCurrency, pSrvRec.Quantity);
	pARFRec.ExpectedQuantity = pSrvRec.Quantity;
	
	vDiscountSumInFolioCurrency = pSrvRec.DiscountSum;
	vVATDiscountSumInFolioCurrency = pSrvRec.VATDiscountSum;
	pARFRec.ExpectedDiscountSum = vDiscountSumInFolioCurrency;
	pARFRec.ExpectedDiscountSumWithoutVAT = vDiscountSumInFolioCurrency - vVATDiscountSumInFolioCurrency;
	
	pARFRec.ExpectedRoomsRented = pSrvRec.RoomsRented;
	pARFRec.ExpectedBedsRented = pSrvRec.BedsRented;
	pARFRec.ExpectedAdditionalBedsRented = pSrvRec.AdditionalBedsRented;
	pARFRec.ExpectedGuestDays = pSrvRec.GuestDays;
	pARFRec.ExpectedGuestsCheckedIn = pSrvRec.GuestsCheckedIn;
	
	// Fill check-in resources
	pARFRec.ExpectedBookingWindow = 0;
	pARFRec.ExpectedRoomsCheckedIn = 0;
	pARFRec.ExpectedBedsCheckedIn = 0;
	pARFRec.ExpectedAdditionalBedsCheckedIn = 0;
	If pARFRec.ExpectedGuestsCheckedIn <> 0 And pARFRec.ExpectedQuantity <> 0 Then
		pARFRec.ExpectedRoomsCheckedIn = pARFRec.ExpectedRoomsRented;
		pARFRec.ExpectedBedsCheckedIn = pARFRec.ExpectedBedsRented;
		pARFRec.ExpectedAdditionalBedsCheckedIn = pARFRec.ExpectedAdditionalBedsRented;
		If pARFRec.ExpectedRoomsCheckedIn <> 0 Then
			pARFRec.ExpectedBookingWindow = Round((BegOfDay(CheckInDate) - BegOfDay(Date))/(24*3600)*?(pARFRec.ExpectedRoomsCheckedIn > 1, pARFRec.ExpectedRoomsCheckedIn, 1), 0);
		EndIf;
	EndIf;
	
	pARFRec.Sales = 0;
	pARFRec.SalesWithoutVAT = 0;
	pARFRec.RoomRevenue = 0;
	pARFRec.RoomRevenueWithoutVAT = 0;
	pARFRec.ExtraBedRevenue = 0;
	pARFRec.ExtraBedRevenueWithoutVAT = 0;
	pARFRec.DiscountSum = 0;
	pARFRec.DiscountSumWithoutVAT = 0;
	pARFRec.RoomsRented = 0;
	pARFRec.BedsRented = 0;
	pARFRec.AdditionalBedsRented = 0;
	pARFRec.GuestDays = 0;
	pARFRec.GuestsCheckedIn = 0;
	pARFRec.RoomsCheckedIn = 0;
	pARFRec.BedsCheckedIn = 0;
	pARFRec.AdditionalBedsCheckedIn = 0;
	pARFRec.Quantity = 0;
	pARFRec.BookingWindow = 0;
	
	// Commission sum
	pARFRec.CommissionSum = 0;
	pARFRec.CommissionSumWithoutVAT = 0;
	pARFRec.ExpectedCommissionSum = pSrvRec.CommissionSum;
	pARFRec.ExpectedCommissionSumWithoutVAT = pSrvRec.CommissionSum - pSrvRec.VATCommissionSum;
	
	// Check if customer and agent are the same
	If ValueIsFilled(vSrvRecFolio) Then
		vDoNotPostCommission = False;
		If ValueIsFilled(vSrvRecFolio.Agent) And vSrvRecFolio.Agent.DoNotPostCommission Then
			vDoNotPostCommission = True;
		EndIf;
		If vDoNotPostCommission Then
			pARFRec.ExpectedCommissionSum = 0;
			pARFRec.ExpectedCommissionSumWithoutVAT = 0;
		Else
			If ValueIsFilled(vSrvRecFolio.Agent) And 
			   vSrvRecFolio.Agent <> vSrvRecFolio.Customer And 
			   pSrvRec.CommissionSum <> 0 Then
				pARFRec.ExpectedCommissionSum = 0;
				pARFRec.ExpectedCommissionSumWithoutVAT = 0;
			
				// Add new record
				vARFRec = RegisterRecords.AccountsReceivableForecast.Add();
				FillPropertyValues(vARFRec, pARFRec, , "RecordType");
				
				// Fill dimensions
				vARFRec.Customer = vSrvRecFolio.Agent;
				vARFRec.Contract = vSrvRecFolio.Agent.AgentCommissionContract;
				vARFRec.Agent = vSrvRecFolio.Agent;
				vARFRec.GuestGroup = Catalogs.GuestGroups.EmptyRef();
				
				// Reset expected resources
				vARFRec.ExpectedSales = 0;
				vARFRec.ExpectedSalesWithoutVAT = 0;
				vARFRec.ExpectedRoomRevenue = 0;
				vARFRec.ExpectedRoomRevenueWithoutVAT = 0;
				vARFRec.ExpectedExtraBedRevenue = 0;
				vARFRec.ExpectedExtraBedRevenueWithoutVAT = 0;
				vARFRec.ExpectedQuantity = 0;
				vARFRec.ExpectedDiscountSum = 0;
				vARFRec.ExpectedDiscountSumWithoutVAT = 0;
				vARFRec.ExpectedRoomsRented = 0;
				vARFRec.ExpectedBedsRented = 0;
				vARFRec.ExpectedAdditionalBedsRented = 0;
				vARFRec.ExpectedGuestDays = 0;
				vARFRec.ExpectedGuestsCheckedIn = 0;
				vARFRec.ExpectedRoomsCheckedIn = 0;
				vARFRec.ExpectedBedsCheckedIn = 0;
				vARFRec.ExpectedAdditionalBedsCheckedIn = 0;
				vARFRec.ExpectedBookingWindow = 0;
				
				// Fill commission
				vARFRec.ExpectedCommissionSum = pSrvRec.CommissionSum;
				vARFRec.ExpectedCommissionSumWithoutVAT = pSrvRec.CommissionSum - pSrvRec.VATCommissionSum;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // FillExpectedARFAttributes

// -----------------------------------------------------------------------------
Procedure PostToForecastSales(pCancel, pRoomsRow = Undefined)
	If DoCharging And Not ReservationStatus.AlwaysChargeInAdvanceServicesOnly Or
	   PersonsWriteOff = 0 And ValueIsFilled(RoomType) And Not RoomType.IsVirtual Then
		// Clear forecast
		pmClearSalesForecastRegisterRecords();
		Return;
	EndIf;
	vNoVATRate = cmGetNoVATVATRate();
	
	vRoomQuantity = ?(RoomQuantity = 0, 1, RoomQuantity);
	
	// Calculate number of persons in the room
	vNumberOfPersonsInRoom = 0;
	vOneRoomDocs = Undefined;
	If ValueIsFilled(AccommodationTemplate) Then
		vNumberOfPersonsInRoom = AccommodationTemplate.NumberOfAdults + AccommodationTemplate.NumberOfTeenagers + AccommodationTemplate.NumberOfChildren + AccommodationTemplate.NumberOfInfants;
		vOneRoomDocs = cmGetOneRoomAccommodations(Room, GuestGroup, CheckInDate, CheckOutDate, Number);
		If vOneRoomDocs.Count() > 1 Then
			vNumberOfPersonsInRoom = vOneRoomDocs.Count();
		EndIf;
	EndIf;
	
	// Create cache value table with service parameters
	vServiceQCRTypes = New ValueTable();
	vServiceQCRTypes.Columns.Add("Service");
	vServiceQCRTypes.Columns.Add("ServiceType");
	vServiceQCRTypes.Columns.Add("QuantityCalculationRule");
	vServiceQCRTypes.Columns.Add("QuantityCalculationRuleType");
	vServiceQCRTypes.Columns.Add("ChargeMealsAtFirstDay");
	vServiceQCRTypes.Columns.Add("ActualAmountIsChargedExternally");
	vServiceQCRTypes.Columns.Add("DoNotChargeInReservations");
	
	vBegOfCheckInDate = BegOfDay(CheckInDate);
	vBegOfCheckOutDate = BegOfDay(CheckOutDate);
	
	vServices = Services.Unload();
	
	// Add virtual services for connected room types
	vConnectRoomTypesCache = New ValueList();
	i = 0;
	While i < vServices.Count() Do
		vSrvRec = vServices.Get(i);
		vCurRoom = vSrvRec.Room;
		vCurRoomType = vSrvRec.RoomType;
		vIsConnectService = False;
		If ValueIsFilled(vCurRoomType) And vSrvRec.IsRoomRevenue And vSrvRec.IsInPrice And Not vSrvRec.IsSplit And Not vSrvRec.RoomRevenueAmountsOnly And (vSrvRec.RoomsRented <> 0 Or vSrvRec.BedsRented <> 0) Then
			If vConnectRoomTypesCache.FindByValue(vCurRoomType) = Undefined Then
				If vCurRoomType.DoesNotAffectRoomRevenueStatistics And vCurRoomType.ConnectedRoomTypes.Count() > 0 Then
					vConnectRoomTypesCache.Add(vCurRoomType);
					vIsConnectService = True;
				EndIf;
			Else
				vIsConnectService = True;
			EndIf;
		EndIf;
		If vIsConnectService Then
			For Each vConnectedRoomTypesRow In vCurRoomType.ConnectedRoomTypes Do
				If ValueIsFilled(vConnectedRoomTypesRow.RoomType) Then
					i = i + 1;
					vConSrvRec = vServices.Insert(i);
					FillPropertyValues(vConSrvRec, vSrvRec, , "Price, Sum, VATSum, AdditionalBedsRented, GuestDays, GuestsCheckedIn, DiscountSum, VATDiscountSum, CommissionSum, VATCommissionSum, Room, RoomType, RateSum, RateDiscountSum");
					vConSrvRec.IsSplit = True;
					If ValueIsFilled(vCurRoom) Then
						If vCurRoom.ConnectedRooms.Count() = vCurRoomType.ConnectedRoomTypes.Count() Then
							vConnectedRoomsRow = vSrvRec.Room.ConnectedRooms.Get(vCurRoomType.ConnectedRoomTypes.IndexOf(vConnectedRoomTypesRow));
							vConSrvRec.Room = vConnectedRoomsRow.Room;
							vConSrvRec.RoomType = vConnectedRoomsRow.RoomType;
						EndIf;
					Else
						vConSrvRec.RoomType = vConnectedRoomTypesRow.RoomType;
					EndIf;
				EndIf;
			EndDo;					
		EndIf;
		i = i + 1;
	EndDo;
	
	// Do movement on accounting date for each service in services
	For Each vSrvRec In vServices Do
		// In some cases the reservation may come from interface (OTA) without mapped service
		// It's better to save the reservation without forcast then raise an exception
		If vSrvRec.Quantity = 0 Then
			Continue;
		EndIf;
		If Not ValueIsFilled(vSrvRec.AccountingDate) Then
			Continue;
		EndIf;
		If Not ValueIsFilled(vSrvRec.Service) Then
			Continue;
		EndIf;
		
		vSrvAccountingDate = vSrvRec.AccountingDate;
		vSrvService = vSrvRec.Service;
		If vBegOfCheckInDate < vBegOfCheckOutDate Then
			If ValueIsFilled(vSrvService) And ValueIsFilled(vSrvService.QuantityCalculationRule) Then
				vAccountingDateMove = cmGetAccountingDateMove(vSrvService.QuantityCalculationRule, vSrvRec.IsManual, ThisObject, False);
				If vAccountingDateMove < 0 Then
					vSrvAccountingDate = vSrvAccountingDate + vAccountingDateMove*(24*3600);
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(ReservationStatus) And (ReservationStatus.IsActive Or ReservationStatus.IsPreliminary) And 
	       ValueIsFilled(DoChargingToDate) And vSrvAccountingDate <= DoChargingToDate Then
			// Service will be charged in advance
			Continue;
		EndIf;
		
		If Not ReservationStatus.DoNotChargeForecastServices Then
			vSrvRoomRate = vSrvRec.RoomRate;
			If Not ValueIsFilled(vSrvRoomRate) Then
				vSrvRoomRate = RoomRate;
			EndIf;
			vSrvRoomType = vSrvRec.RoomType;
			If Not ValueIsFilled(vSrvRoomType) Then
				vSrvRoomType = ?(ValueIsFilled(RoomTypeUpgrade), RoomTypeUpgrade, RoomType);
			EndIf;
			vSrvAccommodationType = vSrvRec.AccommodationType;
			If Not ValueIsFilled(vSrvAccommodationType) Then
				vSrvAccommodationType = AccommodationType;
			EndIf;
			vSrvQuantity = vSrvRec.Quantity;
			vSrvAccommodationTemplate = AccommodationTemplate;
			For Each vRRRow In RoomRates Do
				If BegOfDay(vRRRow.AccountingDate) <= vSrvAccountingDate Then
					If ValueIsFilled(vRRRow.AccommodationTemplate) Then
						If vRRRow.AccommodationTemplate = Catalogs.AccommodationTemplates.NoTemplate Then
							vSrvAccommodationTemplate = Catalogs.AccommodationTemplates.EmptyRef();
						Else
							vSrvAccommodationTemplate = vRRRow.AccommodationTemplate;
						EndIf;
					EndIf;
				Else
					Break;
				EndIf;
			EndDo;
			
			// Check other reservation status settings
			If DoCharging And vSrvService.AlwaysChargeInAdvance Then
				Continue;
			EndIf;
			If ValueIsFilled(vSrvRec.Folio) Then
				vSrvRecFolio = vSrvRec.Folio;
				If ValueIsFilled(vSrvRecFolio.PaymentMethod) And vSrvRecFolio.PaymentMethod.ChargeServicesInAdvance Then
					Continue;
				EndIf;
			EndIf;
		
			// Get service charging rule parameters
			vServiceQCRTypesRow = vServiceQCRTypes.Find(vSrvService, "Service");
			vServiceType = Undefined;
			vQuantityCalculationRule = Undefined;
			vQuantityCalculationRuleType = Undefined;
			vChargeMealsAtFirstDay = False;
			vActualAmountIsChargedExternally = False;
			vDoNotChargeInReservations = False;
			If vServiceQCRTypesRow <> Undefined Then
				vServiceType = vServiceQCRTypesRow.ServiceType;
				vQuantityCalculationRule = vServiceQCRTypesRow.QuantityCalculationRule;
				vQuantityCalculationRuleType = vServiceQCRTypesRow.QuantityCalculationRuleType;
				vChargeMealsAtFirstDay = vServiceQCRTypesRow.ChargeMealsAtFirstDay;
				vActualAmountIsChargedExternally = vServiceQCRTypesRow.ActualAmountIsChargedExternally;
				vDoNotChargeInReservations = vServiceQCRTypesRow.DoNotChargeInReservations;
			Else
				vQuantityCalculationRule = vSrvService.QuantityCalculationRule;
				If ValueIsFilled(vQuantityCalculationRule) Then
					vQuantityCalculationRuleType = vQuantityCalculationRule.QuantityCalculationRuleType;
					vChargeMealsAtFirstDay = vQuantityCalculationRule.ChargeMealsAtFirstDay;
					vDoNotChargeInReservations = vQuantityCalculationRule.DoNotChargeInReservations;
				EndIf;
				vServiceType = vSrvService.ServiceType;
				If ValueIsFilled(vServiceType) Then
					vActualAmountIsChargedExternally = vServiceType.ActualAmountIsChargedExternally;
				EndIf;
				
				vServiceQCRTypesRow = vServiceQCRTypes.Add();
				vServiceQCRTypesRow.Service = vSrvService;
				vServiceQCRTypesRow.ServiceType = vSrvService.ServiceType;
				vServiceQCRTypesRow.QuantityCalculationRule = vQuantityCalculationRule;
				vServiceQCRTypesRow.QuantityCalculationRuleType = vQuantityCalculationRuleType;
				vServiceQCRTypesRow.ChargeMealsAtFirstDay = vChargeMealsAtFirstDay;
				vServiceQCRTypesRow.ActualAmountIsChargedExternally = vActualAmountIsChargedExternally;
				vServiceQCRTypesRow.DoNotChargeInReservations = vDoNotChargeInReservations;
			EndIf;
			If vDoNotChargeInReservations Then
				Continue;
			EndIf;
			
			// Check if we have to move service date
			vAccountingDateMove = 0;
			vServiceDateMove = cmGetServiceDateMove(vQuantityCalculationRule, vQuantityCalculationRuleType, vChargeMealsAtFirstDay, vSrvRec.IsManual, ThisObject, False, vAccountingDateMove);
			
			vSrvSumInReportingCurrency = Round(cmConvertCurrencies((vSrvRec.Sum - vSrvRec.DiscountSum), vSrvRec.FolioCurrency, , ReportingCurrency, , ?(ValueIsFilled(vSrvRec.AccountingDate), vSrvRec.AccountingDate, ExchangeRateDate), Hotel)/vRoomQuantity, 2);
			vSrvDiscountSumInReportingCurrency = Round(cmConvertCurrencies(vSrvRec.DiscountSum, vSrvRec.FolioCurrency, , ReportingCurrency, , ?(ValueIsFilled(vSrvRec.AccountingDate), vSrvRec.AccountingDate, ExchangeRateDate), Hotel)/vRoomQuantity, 2);
			vSrvVATDiscountSumInReportingCurrency = Round(cmConvertCurrencies(vSrvRec.VATDiscountSum, vSrvRec.FolioCurrency, , ReportingCurrency, , ?(ValueIsFilled(vSrvRec.AccountingDate), vSrvRec.AccountingDate, ExchangeRateDate), Hotel)/vRoomQuantity, 2);
			vSrvCommissionSumInReportingCurrency = Round(cmConvertCurrencies(vSrvRec.CommissionSum, vSrvRec.FolioCurrency, , ReportingCurrency, , ?(ValueIsFilled(vSrvRec.AccountingDate), vSrvRec.AccountingDate, ExchangeRateDate), Hotel)/vRoomQuantity, 2);
			vSrvVATCommissionSumInReportingCurrency = Round(cmConvertCurrencies(vSrvRec.VATCommissionSum, vSrvRec.FolioCurrency, , ReportingCurrency, , ?(ValueIsFilled(vSrvRec.AccountingDate), vSrvRec.AccountingDate, ExchangeRateDate), Hotel)/vRoomQuantity, 2);
			vSrvVATSumInReportingCurrency = Round(cmConvertCurrencies(vSrvRec.VATSum, vSrvRec.FolioCurrency, , ReportingCurrency, , ?(ValueIsFilled(vSrvRec.AccountingDate), vSrvRec.AccountingDate, ExchangeRateDate), Hotel)/vRoomQuantity, 2);
			vSrvQuantity = vSrvRec.Quantity/vRoomQuantity;
			vSrvVATRate = vSrvRec.VATRate;
			vRateSumInReportingCurrency = ?(vSrvRec.IsRoomRevenue And vSrvRec.IsInPrice, Round(cmConvertCurrencies((vSrvRec.RateSum - vSrvRec.RateDiscountSum), vSrvRec.FolioCurrency, , ReportingCurrency, , ?(ValueIsFilled(vSrvRec.AccountingDate), vSrvRec.AccountingDate, ExchangeRateDate), Hotel), 2), 0);
			vVATRateSumInReportingCurrency = cmCalculateVATSum(vSrvVATRate, vRateSumInReportingCurrency, vSrvAccountingDate);
			
			vBaseSumInReportingCurrency = vSrvSumInReportingCurrency;
			
			If vSrvSumInReportingCurrency >= 0 And Not vSrvRec.IsSplit Then
				vBDLSettingsDate = GetServiceBreakdownListActiveDate(vSrvService, vSrvAccountingDate, Hotel);
				vAccommodationTypesList = New ValueList();
				If vSrvRec.IsInPrice And ValueIsFilled(vSrvRec.RoomRate) And vSrvRec.RoomRate.RateChargeDirection = Enums.RateChargeDirections.MergeToTheMainRoomGuest And 
				   Not IsForFolioSplit And ValueIsFilled(vSrvAccommodationTemplate) And vSrvAccommodationTemplate.AccommodationTypes.Count() > 0 Then
					For Each vSrvAccommodationTemplateRow In vSrvAccommodationTemplate.AccommodationTypes Do
						vAccommodationTypesList.Add(vSrvAccommodationTemplateRow.AccommodationType);
					EndDo;
				Else
					vAccommodationTypesList.Add(vSrvAccommodationType);
				EndIf;
				For Each vAccommodationTypesListItem In vAccommodationTypesList Do
					vAccommodationTypesListItemIndex = vAccommodationTypesList.IndexOf(vAccommodationTypesListItem);

					vCurAccommodationType = vAccommodationTypesListItem.Value;
					
					vCurClient = Guest;
					If vAccommodationTypesListItemIndex > 0 Then
						If AdditionalProperties.Property("GuestsInRoom") And AdditionalProperties.GuestsInRoom.Count() = (vAccommodationTypesList.Count() - 1) Then
							vOneRoomDocsRow = AdditionalProperties.GuestsInRoom.Get(vAccommodationTypesListItemIndex - 1);
							If vOneRoomDocsRow.AccommodationType = vCurAccommodationType Then
								vCurClient = vOneRoomDocsRow.GuestRef;
							EndIf;
						ElsIf vOneRoomDocs <> Undefined And vOneRoomDocs.Count() = vAccommodationTypesList.Count() Then
							vOneRoomDocsRow = vOneRoomDocs.Get(vAccommodationTypesListItemIndex);
							vPersonParentDoc = vOneRoomDocsRow.Ref;
							If ValueIsFilled(vPersonParentDoc) And vPersonParentDoc.AccommodationType = vCurAccommodationType Then
								vCurClient = vPersonParentDoc.Guest;
							EndIf;
						EndIf;
					EndIf;
					
					vBDLSettings = cmGetServiceBreakdownList(vSrvService, vBDLSettingsDate, Hotel, vSrvRoomRate, vSrvRoomType, vCurAccommodationType);
					For Each vBDLSettingsRow In vBDLSettings Do
						If ValueIsFilled(vBDLSettingsRow.Item) And Not vBDLSettingsRow.IsNotInForecast Then
							vItemService = vBDLSettingsRow.Item;
							
							// Item VAT rate
							vItemVATRate = vSrvRec.VATRate;
							If ValueIsFilled(vBDLSettingsRow.VATRate) And Not vBDLSettingsRow.IsTax Then
								vItemVATRate = vBDLSettingsRow.VATRate;
							EndIf;
							
							// Item price
							vItemPrice = 0;
							vPriceFormula = "";
							If vBDLSettingsRow.Price <> 0 And ValueIsFilled(vBDLSettingsRow.Currency) Then
								vItemPrice = cmConvertCurrencies(vBDLSettingsRow.Price, vBDLSettingsRow.Currency, , ReportingCurrency, , ExchangeRateDate, Hotel);
							ElsIf Not IsBlankString(vBDLSettingsRow.PriceCalculationFormula) Then
								vPriceFormula = TrimAll(vBDLSettingsRow.PriceCalculationFormula);
								vPriceFormula = cmGetFormulaExecutionText(vPriceFormula, ThisObject);
								SetSafeMode(True);
								Execute(vPriceFormula);
								SetSafeMode(False);
		 					EndIf;
							
							// Item quantity
							vItemQuantity = vSrvQuantity;
							vQuantityFormula = "";
							If vBDLSettingsRow.Quantity <> 0 Then
								vItemQuantity = vBDLSettingsRow.Quantity;
							ElsIf Not IsBlankString(vBDLSettingsRow.QuantityCalculationFormula) Then
								vQuantityFormula = TrimAll(vBDLSettingsRow.QuantityCalculationFormula);
								vQuantityFormula = cmGetFormulaExecutionText(vQuantityFormula, ThisObject);
								SetSafeMode(True);
								Execute(vQuantityFormula);
								SetSafeMode(False);
							EndIf;
							
							// Check rest of amount
							If Round(vItemPrice*vItemQuantity, 2) > vSrvSumInReportingCurrency Then
								If vItemQuantity <> 0 Then
									vItemPrice = Round(vSrvSumInReportingCurrency/vItemQuantity, 2);
								Else
									Continue;
								EndIf;
							EndIf;
							
							// Service date
							vServiceDate = vSrvRec.AccountingDate;
							If vBDLSettingsRow.ServiceDateNumber > 0 Then
								If BegOfDay(CheckInDate) <= BegOfDay(vServiceDate) Then
									vN = (BegOfDay(vServiceDate) - BegOfDay(CheckInDate))/(24*3600) + 1;
									If vN <> vBDLSettingsRow.ServiceDateNumber Then
										vItemQuantity = 0;
									EndIf;
								EndIf;
							ElsIf vBDLSettingsRow.ServiceDateNumber < 0 Then
								If BegOfDay(CheckOutDate) >= BegOfDay(vServiceDate) Then
									vN = -(BegOfDay(CheckOutDate) - BegOfDay(vServiceDate))/(24*3600) - 1;
									If vN <> vBDLSettingsRow.ServiceDateNumber Then
										vItemQuantity = 0;
									EndIf;
								EndIf;
							EndIf;
							If StrFind(lower(vBDLSettingsRow.PriceCalculationFormula), lower("[TouristTaxAmountRU]")) > 0 And vItemPrice = 0 Then
								vItemQuantity = 0;
							EndIf;
							If vItemQuantity = 0 Then
								Continue;
							EndIf;
							If vBDLSettingsRow.ServiceDateShift <> 0 Then
								If BegOfDay(CheckInDate) < BegOfDay(CheckOutDate) Then
									vServiceDate = vServiceDate + vBDLSettingsRow.ServiceDateShift * 24 * 3600;
								EndIf;
							EndIf;
							
							// Calculate amount to be posted by this item service
							vItemSumInReportingCurrency = Round(vItemPrice*vItemQuantity, 2);
							If Not vBDLSettingsRow.IsTax Then
								vItemVATSumInReportingCurrency = cmCalculateVATSum(vItemVATRate, vItemSumInReportingCurrency, vSrvAccountingDate);
							Else
								If ValueIsFilled(vNoVATRate) Then
									vItemVATRate = vNoVATRate;
								EndIf;
								vItemVATSumInReportingCurrency = 0;
							EndIf;
							vItemDiscountSumInReportingCurrency = 0;
							vItemVATDiscountSumInReportingCurrency = 0;
							vItemCommissionSumInReportingCurrency = 0;
							vItemVATCommissionSumInReportingCurrency = 0;
							
							// Do correction of the amounts to be posted by main charge service
							vSrvSumInReportingCurrency = vSrvSumInReportingCurrency - vItemSumInReportingCurrency;
							vSrvVATSumInReportingCurrency = vSrvVATSumInReportingCurrency - vItemVATSumInReportingCurrency;
							vSrvDiscountSumInReportingCurrency = vSrvDiscountSumInReportingCurrency - vItemDiscountSumInReportingCurrency;
							vSrvVATDiscountSumInReportingCurrency = vSrvVATDiscountSumInReportingCurrency - vItemVATDiscountSumInReportingCurrency;
							vSrvCommissionSumInReportingCurrency = vSrvCommissionSumInReportingCurrency - vItemCommissionSumInReportingCurrency;
							vSrvVATCommissionSumInReportingCurrency = vSrvVATCommissionSumInReportingCurrency - vItemVATCommissionSumInReportingCurrency;
							
							// Take number of rooms into account
							vItemQuantity = vItemQuantity * vRoomQuantity;
							vItemSumInReportingCurrency = vItemSumInReportingCurrency * vRoomQuantity;
							vItemVATSumInReportingCurrency = vItemVATSumInReportingCurrency * vRoomQuantity;
							vItemDiscountSumInReportingCurrency = vItemDiscountSumInReportingCurrency * vRoomQuantity;
							vItemVATDiscountSumInReportingCurrency = vItemVATDiscountSumInReportingCurrency * vRoomQuantity;
							vItemCommissionSumInReportingCurrency = vItemCommissionSumInReportingCurrency * vRoomQuantity;
							vItemVATCommissionSumInReportingCurrency = vItemVATCommissionSumInReportingCurrency * vRoomQuantity;
							
							vSFRec = RegisterRecords.SalesForecast.Add();
							FillSFAttributes(vSFRec, vSrvRec, vSrvRec.AccountingDate, vServiceDate, pRoomsRow, vItemService, vItemQuantity, vItemVATRate, vItemSumInReportingCurrency, vItemVATSumInReportingCurrency, vItemDiscountSumInReportingCurrency, vItemVATDiscountSumInReportingCurrency, vItemCommissionSumInReportingCurrency, vItemVATCommissionSumInReportingCurrency, vBDLSettingsRow.IsInRoomRevenue, , vSrvAccommodationTemplate, vCurAccommodationType, vCurClient);
							If vAccommodationTypesListItemIndex > 0 Then
								vSFRec.AccommodationTemplate = Undefined;
							EndIf;
							
							// Post to service registration
							If vItemService.ServiceRegistrationIsTurnedOn Then
								PostToServiceRegistration(vSFRec.ServiceDate, vSFRec.Service, vSFRec.BoardPlace, vSFRec.Room, vSFRec.Resource, vSFRec.GuestGroup, vSFRec.Folio, vSFRec.Client, vSFRec.Sales, vSFRec.Quantity, vSFRec.Remarks);
							EndIf;
						EndIf;
					EndDo; // By breakdown list settings rows
				EndDo; // By accommodation types
			EndIf;
			
			vServiceDate = vSrvRec.AccountingDate;
			// Move service date if neccessary
			If vServiceDateMove <> 0 Then
				vServiceDate = vServiceDate + 24*3600*vServiceDateMove;
			EndIf;
			
			// Take number of rooms into account
			vSrvQuantity = vSrvQuantity * vRoomQuantity;
			vSrvSumInReportingCurrency = vSrvSumInReportingCurrency * vRoomQuantity;
			vSrvDiscountSumInReportingCurrency = vSrvDiscountSumInReportingCurrency * vRoomQuantity;
			vSrvCommissionSumInReportingCurrency = vSrvCommissionSumInReportingCurrency * vRoomQuantity;
			vSrvVATSumInReportingCurrency = vSrvVATSumInReportingCurrency * vRoomQuantity;
			vSrvVATDiscountSumInReportingCurrency = vSrvVATDiscountSumInReportingCurrency * vRoomQuantity;
			vSrvVATCommissionSumInReportingCurrency = vSrvVATCommissionSumInReportingCurrency * vRoomQuantity;
			
			vNumberOfPersonsInTemplate = 0;
			vRecalculateQuantity = False;
			If (vSrvService.ChargeToEachGuestSeparately Or vSrvRec.IsRoomRevenue And Not vSrvRec.RoomRevenueAmountsOnly And Not vSrvRec.IsSplit) And 
			   ValueIsFilled(vSrvAccommodationTemplate) And Not vSrvAccommodationTemplate.IsForFolioSplit And ValueIsFilled(vSrvRoomRate) And 
			   vSrvRoomRate.RateChargeDirection = Enums.RateChargeDirections.MergeToTheMainRoomGuest And Not IsForFolioSplit Then
				If vSrvRec.IsRoomRevenue And Not vSrvRec.RoomRevenueAmountsOnly And Not vSrvRec.IsSplit Then
					vNumberOfPersonsInTemplate = vNumberOfPersonsInRoom;
				ElsIf vSrvQuantity <> 0 Then
					vNumberOfPersonsInTemplate = vNumberOfPersonsInRoom;
					vRecalculateQuantity = True;
				EndIf;
			EndIf;
			If vNumberOfPersonsInTemplate = 1 Then
				vNumberOfPersonsInTemplate = 0;
			EndIf;
			
			vPersonIndex = 0;
			vPersonIndexShift = 0;
			
			vRecGuestDays = vSrvRec.GuestDays;
			vRecGuestsCheckedIn = vSrvRec.GuestsCheckedIn;
			vRecQuantity = vSrvRec.Quantity;
			
			vEffGuestDaysPerPerson = 0;
			vEffGuestsCheckedInPerPerson = 0;
			vEffQuantityPerPerson = 0;
			If vNumberOfPersonsInTemplate > 0 Then
				vEffGuestDaysPerPerson = Round(vSrvRec.GuestDays / vNumberOfPersonsInTemplate, 0);
				If vEffGuestDaysPerPerson = 0 And vSrvRec.GuestDays <> 0 Then
					vEffGuestDaysPerPerson = ?(vSrvRec.GuestDays < 0, -1, 1);
				EndIf;
				vEffGuestsCheckedInPerPerson = Round(vSrvRec.GuestsCheckedIn / vNumberOfPersonsInTemplate, 0);
				If vEffGuestsCheckedInPerPerson = 0 And vSrvRec.GuestsCheckedIn <> 0 Then
					vEffGuestsCheckedInPerPerson = 1;
				EndIf;
				vEffQuantityPerPerson = Round(vSrvRec.Quantity / vNumberOfPersonsInTemplate, 0);
				If vEffQuantityPerPerson = 0 And vSrvRec.Quantity <> 0 Then
					vEffQuantityPerPerson = 1;
				EndIf;
			EndIf;
			
			While True Do
				vDoBreak = False;
				If (vPersonIndex + vPersonIndexShift) >= (vNumberOfPersonsInTemplate - 1) Then
					vDoBreak = True;
				EndIf;
				
				vSFRec = RegisterRecords.SalesForecast.Add();
				FillSFAttributes(vSFRec, vSrvRec, vSrvRec.AccountingDate, vServiceDate, pRoomsRow, vSrvService, vSrvQuantity, vSrvVATRate, vSrvSumInReportingCurrency, vSrvVATSumInReportingCurrency, vSrvDiscountSumInReportingCurrency, vSrvVATDiscountSumInReportingCurrency, vSrvCommissionSumInReportingCurrency, vSrvVATCommissionSumInReportingCurrency, , vPersonIndex, vSrvAccommodationTemplate);
				
				// Correction for the template guests
				If vNumberOfPersonsInTemplate > 0 Then
					If vRecGuestDays = 0 Then
						vEffGuestDaysPerPerson = 0;
					EndIf;
					If vRecGuestsCheckedIn = 0 Then
						vEffGuestsCheckedInPerPerson = 0;
					EndIf;
					If vRecQuantity = 0 Then
						vEffQuantityPerPerson = 0;
					EndIf;
					
					// Guest stats
					If (vPersonIndex + vPersonIndexShift) = (vNumberOfPersonsInTemplate - 1) Then
						vSFRec.GuestDays = vRecGuestDays;
						vSFRec.GuestsCheckedIn = vRecGuestsCheckedIn;
					Else
						If vRecGuestDays > 0 Then
							vSFRec.GuestDays = ?(vRecGuestDays > vEffGuestDaysPerPerson, vEffGuestDaysPerPerson, vRecGuestDays);
							vSFRec.GuestsCheckedIn = ?(vRecGuestsCheckedIn > vEffGuestsCheckedInPerPerson, vEffGuestsCheckedInPerPerson, vRecGuestsCheckedIn);
						Else
							vSFRec.GuestDays = ?(vRecGuestDays < vEffGuestDaysPerPerson, vEffGuestDaysPerPerson, vRecGuestDays);
							vSFRec.GuestsCheckedIn = ?(vRecGuestsCheckedIn < vEffGuestsCheckedInPerPerson, vEffGuestsCheckedInPerPerson, vRecGuestsCheckedIn);
						EndIf;
					EndIf;
					vRecGuestDays = vRecGuestDays - vSFRec.GuestDays;
					vRecGuestsCheckedIn = vRecGuestsCheckedIn - vSFRec.GuestsCheckedIn;
					
					// Service quantity correction
					If vRecalculateQuantity Then
						vSFRec.Quantity = Round(vSFRec.Quantity / vNumberOfPersonsInTemplate, 7);
						If (vPersonIndex + vPersonIndexShift) = (vNumberOfPersonsInTemplate - 1) Then
							vSFRec.Quantity = vRecQuantity;
						Else
							If vRecQuantity > 0 Then
								vSFRec.Quantity = ?(vRecQuantity > vEffQuantityPerPerson, vEffQuantityPerPerson, vRecQuantity);
							Else
								vSFRec.Quantity = ?(vRecQuantity < vEffQuantityPerPerson, vEffQuantityPerPerson, vRecQuantity);
							EndIf;
						EndIf;
						vRecQuantity = vRecQuantity - vSFRec.Quantity;
					ElsIf vPersonIndex > 0 Then
						vSFRec.Quantity = 0;
						vRecQuantity = 0;
					EndIf;

					If vNumberOfPersonsInTemplate = 0 Then
						vDoBreak = True;
					EndIf;
					If vRecGuestDays = 0 And vRecGuestsCheckedIn = 0 And 
					  (Not vRecalculateQuantity Or vRecalculateQuantity And vRecQuantity = 0) Then
						vDoBreak = True;
					EndIf;
					
					// Calculate initial shift for template
					If vPersonIndex = 0 Then
						If AdditionalProperties.Property("GuestsInRoom") And AdditionalProperties.GuestsInRoom.Count() = (vNumberOfPersonsInTemplate - 1) Then
							For j = 0 To (AdditionalProperties.GuestsInRoom.Count() - 1) Do
								vOneRoomDocsRow = AdditionalProperties.GuestsInRoom.Get(j);
								If vOneRoomDocsRow.AccommodationType = vSrvAccommodationType Then
									vPersonIndexShift = j + 1;
									If ValueIsFilled(vOneRoomDocsRow.Ref) Then
										vSFRec.ParentDoc = vOneRoomDocsRow.Ref;
									EndIf;
									vSFRec.Client = vOneRoomDocsRow.GuestRef;
									Break;
								EndIf;
							EndDo;
						ElsIf vOneRoomDocs <> Undefined And vOneRoomDocs.Count() = vNumberOfPersonsInTemplate Then
							For j = 0 To (vOneRoomDocs.Count() - 1) Do
								vOneRoomDocsRow = vOneRoomDocs.Get(j);
								vPersonParentDoc = vOneRoomDocsRow.Ref;
								If ValueIsFilled(vPersonParentDoc) And vPersonParentDoc.AccommodationType = vSrvAccommodationType Then
									vPersonIndexShift = j;
									vSFRec.ParentDoc = vPersonParentDoc;
									vSFRec.Client = vPersonParentDoc.Guest;
									Break;
								EndIf;
							EndDo;
						Else
							For j = 0 To (AccommodationTemplate.AccommodationTypes.Count() - 1) Do
								vOneRoomDocsRow = AccommodationTemplate.AccommodationTypes.Get(j);
								If vOneRoomDocsRow.AccommodationType = vSrvAccommodationType Then
									vPersonIndexShift = j;
									Break;
								EndIf;
							EndDo;
						EndIf;
					EndIf;
					
					If vPersonIndex > 0 Then
						vPersonParentDoc = Ref;
						vPerson = Guest;
						vPersonAccommodationType = vSrvAccommodationType;
						If AdditionalProperties.Property("GuestsInRoom") And AdditionalProperties.GuestsInRoom.Count() = (vNumberOfPersonsInTemplate - 1) Then
							If (vPersonIndex + vPersonIndexShift - 1) < AdditionalProperties.GuestsInRoom.Count() Then
								vOneRoomDocsRow = AdditionalProperties.GuestsInRoom.Get(vPersonIndex + vPersonIndexShift - 1);
								If ValueIsFilled(vOneRoomDocsRow.Ref) Then
									vPersonParentDoc = vOneRoomDocsRow.Ref;
								EndIf;
								vPerson = vOneRoomDocsRow.GuestRef;
								vPersonAccommodationType = vOneRoomDocsRow.AccommodationType;
							EndIf;
						ElsIf vOneRoomDocs <> Undefined And vOneRoomDocs.Count() = vNumberOfPersonsInTemplate Then
							If (vPersonIndex + vPersonIndexShift) <  vOneRoomDocs.Count() Then
								vOneRoomDocsRow = vOneRoomDocs.Get(vPersonIndex + vPersonIndexShift);
								vPersonParentDoc = vOneRoomDocsRow.Ref;
								vPerson = vPersonParentDoc.Guest;
								vPersonAccommodationType = vPersonParentDoc.AccommodationType;
							EndIf;
						Else
							If (vPersonIndex + vPersonIndexShift) < AccommodationTemplate.AccommodationTypes.Count() Then
								vPerson = Undefined;
								vPersonAccommodationType = AccommodationTemplate.AccommodationTypes.Get(vPersonIndex + vPersonIndexShift).AccommodationType;
							EndIf;
						EndIf;					
						// Update dimensions
						vSFRec.Client = vPerson;
						vSFRec.ParentDoc = vPersonParentDoc;
						vSFRec.AccommodationType = vPersonAccommodationType;
						If ValueIsFilled(vPerson) Then
							vSFRec.Age = vPerson.Age;
							vSFRec.AgeRange = vPerson.AgeRange;
						Else
							vSFRec.Age = 0;
							vSFRec.AgeRange = Undefined;
						EndIf;
						If (vPersonIndex + vPersonIndexShift) > 0 Then
							vSFRec.AccommodationTemplate = Undefined;
						EndIf;
						// Update attributes
						vSFRec.RateSum = 0;
						vSFRec.NumberOfAdditionalBeds = 0;
						vSFRec.NumberOfBeds = 0;
						vSFRec.NumberOfRooms = 0;
						// Reset resources
						If vRecalculateQuantity And vSrvRec.Quantity <> 0 Then
							vProportion = vSFRec.Quantity / vSrvRec.Quantity;
							
							If vDoBreak Then
								vSFRec.Sales = vSFRec.Sales - Round(vSFRec.Sales * vProportion, 2) * vPersonIndex;
								vSFRec.SalesWithoutVAT = vSFRec.SalesWithoutVAT - Round(vSFRec.SalesWithoutVAT * vProportion, 2) * vPersonIndex;
								vSFRec.RoomRevenue = vSFRec.RoomRevenue - Round(vSFRec.RoomRevenue * vProportion, 2) * vPersonIndex;
								vSFRec.RoomRevenueWithoutVAT = vSFRec.RoomRevenueWithoutVAT - Round(vSFRec.RoomRevenueWithoutVAT * vProportion, 2) * vPersonIndex;
								vSFRec.ExtraBedRevenue = vSFRec.ExtraBedRevenue - Round(vSFRec.ExtraBedRevenue * vProportion, 2);
								vSFRec.ExtraBedRevenueWithoutVAT = vSFRec.ExtraBedRevenueWithoutVAT - Round(vSFRec.ExtraBedRevenueWithoutVAT * vProportion, 2) * vPersonIndex;
								vSFRec.CommissionSum = vSFRec.CommissionSum - Round(vSFRec.CommissionSum * vProportion, 2) * vPersonIndex;
								vSFRec.CommissionSumWithoutVAT = vSFRec.CommissionSumWithoutVAT - Round(vSFRec.CommissionSumWithoutVAT * vProportion, 2) * vPersonIndex;
								vSFRec.DiscountSum = vSFRec.DiscountSum - Round(vSFRec.DiscountSum * vProportion, 2) * vPersonIndex;
								vSFRec.DiscountSumWithoutVAT = vSFRec.DiscountSumWithoutVAT - Round(vSFRec.DiscountSumWithoutVAT * vProportion, 2) * vPersonIndex;
								vSFRec.ResourceRevenue = vSFRec.ResourceRevenue - Round(vSFRec.ResourceRevenue * vProportion, 2) * vPersonIndex;
								vSFRec.ResourceRevenueWithoutVAT = vSFRec.ResourceRevenueWithoutVAT - Round(vSFRec.ResourceRevenueWithoutVAT * vProportion, 2) * vPersonIndex;
								vSFRec.VATSum = vSFRec.Sales - vSFRec.SalesWithoutVAT;
							Else
								vSFRec.Sales = Round(vSFRec.Sales * vProportion, 2);
								vSFRec.SalesWithoutVAT = Round(vSFRec.SalesWithoutVAT * vProportion, 2);
								vSFRec.RoomRevenue = Round(vSFRec.RoomRevenue * vProportion, 2);
								vSFRec.RoomRevenueWithoutVAT = Round(vSFRec.RoomRevenueWithoutVAT * vProportion, 2);
								vSFRec.ExtraBedRevenue = Round(vSFRec.ExtraBedRevenue * vProportion, 2);
								vSFRec.ExtraBedRevenueWithoutVAT = Round(vSFRec.ExtraBedRevenueWithoutVAT * vProportion, 2);
								vSFRec.CommissionSum = Round(vSFRec.CommissionSum * vProportion, 2);
								vSFRec.CommissionSumWithoutVAT = Round(vSFRec.CommissionSumWithoutVAT * vProportion, 2);
								vSFRec.DiscountSum = Round(vSFRec.DiscountSum * vProportion, 2);
								vSFRec.DiscountSumWithoutVAT = Round(vSFRec.DiscountSumWithoutVAT * vProportion, 2);
								vSFRec.ResourceRevenue = Round(vSFRec.ResourceRevenue * vProportion, 2);
								vSFRec.ResourceRevenueWithoutVAT = Round(vSFRec.ResourceRevenueWithoutVAT * vProportion, 2);
								vSFRec.VATSum = vSFRec.Sales - vSFRec.SalesWithoutVAT;
							EndIf;
						Else
							vSFRec.Price = 0;
							vSFRec.Sales = 0;
							vSFRec.SalesWithoutVAT = 0;
							vSFRec.RoomRevenue = 0;
							vSFRec.RoomRevenueWithoutVAT = 0;
							vSFRec.ExtraBedRevenue = 0;
							vSFRec.ExtraBedRevenueWithoutVAT = 0;
							vSFRec.CommissionSum = 0;
							vSFRec.CommissionSumWithoutVAT = 0;
							vSFRec.DiscountSum = 0;
							vSFRec.DiscountSumWithoutVAT = 0;
							vSFRec.VATSum = 0;
							vSFRec.ResourceRevenue = 0;
							vSFRec.ResourceRevenueWithoutVAT = 0;
						EndIf;
						vSFRec.RoomsRented = 0;
						vSFRec.BedsRented = 0;
						vSFRec.AdditionalBedsRented = 0;
						vSFRec.RoomsCheckedIn = 0;
						vSFRec.BedsCheckedIn = 0;
						vSFRec.AdditionalBedsCheckedIn = 0;
						vSFRec.BookingWindow = 0;
						vSFRec.HoursRented = 0;
					ElsIf vRecalculateQuantity And vSrvRec.Quantity <> 0 Then
						vProportion = vSFRec.Quantity / vSrvRec.Quantity;
						
						vSFRec.Sales = Round(vSFRec.Sales * vProportion, 2);
						vSFRec.SalesWithoutVAT = Round(vSFRec.SalesWithoutVAT * vProportion, 2);
						vSFRec.RoomRevenue = Round(vSFRec.RoomRevenue * vProportion, 2);
						vSFRec.RoomRevenueWithoutVAT = Round(vSFRec.RoomRevenueWithoutVAT * vProportion, 2);
						vSFRec.ExtraBedRevenue = Round(vSFRec.ExtraBedRevenue * vProportion, 2);
						vSFRec.ExtraBedRevenueWithoutVAT = Round(vSFRec.ExtraBedRevenueWithoutVAT * vProportion, 2);
						vSFRec.CommissionSum = Round(vSFRec.CommissionSum * vProportion, 2);
						vSFRec.CommissionSumWithoutVAT = Round(vSFRec.CommissionSumWithoutVAT * vProportion, 2);
						vSFRec.DiscountSum = Round(vSFRec.DiscountSum * vProportion, 2);
						vSFRec.DiscountSumWithoutVAT = Round(vSFRec.DiscountSumWithoutVAT * vProportion, 2);
						vSFRec.ResourceRevenue = Round(vSFRec.ResourceRevenue * vProportion, 2);
						vSFRec.ResourceRevenueWithoutVAT = Round(vSFRec.ResourceRevenueWithoutVAT * vProportion, 2);
						vSFRec.VATSum = vSFRec.Sales - vSFRec.SalesWithoutVAT;
					EndIf;
				EndIf;
				
				// Post to service registration
				If vSrvService.ServiceRegistrationIsTurnedOn Then
					PostToServiceRegistration(vSFRec.ServiceDate, vSFRec.Service, vSFRec.BoardPlace, vSFRec.Room, vSFRec.Resource, vSFRec.GuestGroup, vSFRec.Folio, vSFRec.Client, vSFRec.Sales, vSFRec.Quantity, vSFRec.Remarks);
				EndIf;
				
				If vDoBreak Then
					Break;
				EndIf;
				
				vPersonIndex = vPersonIndex + 1;
			EndDo;
			
			vARFRec = RegisterRecords.AccountsReceivableForecast.Add();
			FillARFAttributes(vARFRec, vSrvRec, vSrvRec.AccountingDate, pRoomsRow);
			
			// Write to the hotel product log
			vVaucher = vSFRec.HotelProduct;
			If ValueIsFilled(vVaucher) And Not vVaucher.IsFolder Then
				vHPLRec = RegisterRecords.HotelProductLog.AddReceipt();
				vHPLRec.Period = ?(ValueIsFilled(vVaucher.CreateDate), vVaucher.CreateDate, vSrvRec.AccountingDate);
				vHPLRec.FolioCurrency = vSrvRec.FolioCurrency;
				vHPLRec.Hotel = Hotel;
				vHPLRec.HotelProduct = vVaucher;
				vHPLRec.Sum = vSrvRec.Sum - vSrvRec.DiscountSum;
			EndIf;
		EndIf;
	EndDo;
			
	// Write RegisterRecords	
	RegisterRecords.ServiceRegistration.Write();
	RegisterRecords.HotelProductLog.Write();
	RegisterRecords.AccountsReceivableForecast.Write();
EndProcedure // PostToForecastSales

// -----------------------------------------------------------------------------
Procedure PostToExpectedCustomerSales(pCancel)
	If ValueIsFilled(ReservationStatus) And Not ReservationStatus.IsActive And Not DoCharging Then
		// Do movement on accounting date for each service in services
		For Each vSrvRec In Services Do	
			If vSrvRec.Quantity = 0 Then
				Continue;
			EndIf;
			vARFRec = RegisterRecords.AccountsReceivableForecast.Add();
			FillExpectedARFAttributes(vARFRec, vSrvRec, vSrvRec.AccountingDate);
		EndDo;
	EndIf;
	RegisterRecords.AccountsReceivableForecast.Write();
EndProcedure //  PostToExpectedCustomerSales

// -----------------------------------------------------------------------------
Procedure CalculateEffectiveNumberOfRooms(pPeriod)
	// Calculate the effective resources to use
	vEffectiveResources = cmCalculateEffectiveResourcesForReservation(pPeriod);
	
	// Fill effective resources from the structure received
	EffectiveNumberOfBeds = vEffectiveResources.EffectiveNumberOfBeds;
	EffectiveNumberOfAddBeds = vEffectiveResources.EffectiveNumberOfAddBeds;
	EffectiveNumberOfPersons = vEffectiveResources.EffectiveNumberOfPersons;
	EffectiveNumberOfRooms = vEffectiveResources.EffectiveNumberOfRooms;
EndProcedure //  CalculateEffectiveNumberOfRooms

// -----------------------------------------------------------------------------
Function DoChargeTransfer(pServiceRow, pChargeRow, pServiceDateMove = 0)
	vChargeFolio = pChargeRow.Folio;
	vServiceFolio = pServiceRow.Folio;
	vChargeParentDoc = pChargeRow.ParentDoc;
	If vChargeFolio <> vServiceFolio Or (vChargeParentDoc <> Ref And TypeOf(vChargeParentDoc) <> Type("DocumentRef.Accommodation")) Then
		vChargeObj = pChargeRow.Ref.GetObject();
		FillPropertyValues(vChargeObj, pServiceRow, , "Folio");
		If Not ValueIsFilled(pChargeRow.ChargeTransfer) Then
			vChargeObj.Folio = vServiceFolio;
		EndIf;
		If vChargeParentDoc <> Ref And TypeOf(vChargeParentDoc) <> Type("DocumentRef.Accommodation") Then
			vChargeObj.ParentDoc = Ref;
		EndIf;
		vChargeObj.Date = pServiceRow.AccountingDate;
		vChargeObj.ServiceDate = pServiceRow.AccountingDate;
		// Move service date if neccessary
		If pServiceDateMove <> 0 Then
			vChargeObj.ServiceDate = vChargeObj.ServiceDate + 24*3600*pServiceDateMove;
		EndIf;
		vChargeObj.SetTime(AutoTimeMode.DontUse);
		If Not ValueIsFilled(vChargeObj.Author) Then
			vChargeObj.Author = SessionParameters.CurrentUser;
		EndIf;
		If ValueIsFilled(pServiceRow.IsManualAuthor) Then
			vChargeObj.Author = pServiceRow.IsManualAuthor;
		EndIf;
		vChargeObj.IsCorrection = False;
		vChargeObj.CorrectionDate = '00010101';
		vChargeObj.CorrectedCharge = Undefined;
		For Each vAddPropItem In AdditionalProperties Do
			vChargeObj.AdditionalProperties.Insert(vAddPropItem.Key, vAddPropItem.Value);
		EndDo;
		vChargeObj.Write(DocumentWriteMode.Posting);
	EndIf;
	Return pChargeRow.Ref;
EndFunction // DoChargeTransfer

// -----------------------------------------------------------------------------
Function DoCharge(pServiceRow, pChargeRow, pCurrentAccountingDate = '00010101', pSwitchOffAutoCorrections = True, pServiceDateMove = 0, pAccountingDateMove = 0, pRoomRevenueCharge = Undefined, pIsMergedToRoomRevenue = False)
	If ValueIsFilled(pServiceRow.AccountingDate) Then
		If pChargeRow = Undefined Then
			vChargeObj = Documents.Charge.CreateDocument();
			FillPropertyValues(vChargeObj, pServiceRow);
			If pServiceRow.AccountingDate < pCurrentAccountingDate Then
				If pSwitchOffAutoCorrections Then
				   // Do nothing
				   Return Undefined;
				EndIf;
				vChargeObj.Date = pCurrentAccountingDate;
				vChargeObj.ServiceDate = pServiceRow.AccountingDate;
				vChargeObj.IsCorrection = True;
				vChargeObj.CorrectionDate = pServiceRow.AccountingDate;
			Else
				vChargeObj.Date = pServiceRow.AccountingDate;
				vChargeObj.ServiceDate = pServiceRow.AccountingDate;
				vChargeObj.IsCorrection = False;
				vChargeObj.CorrectionDate = '00010101';
			EndIf;
			vChargeObj.SetTime(AutoTimeMode.DontUse);
			vChargeObj.CorrectedCharge = Undefined;
			vChargeObj.Author = SessionParameters.CurrentUser;
			If ValueIsFilled(pServiceRow.IsManualAuthor) Then
				vChargeObj.Author = pServiceRow.IsManualAuthor;
			EndIf;
			vChargeObj.ParentDoc = Ref;
		Else
			vChargeRef = pChargeRow.Ref;
			// Try to find posted correction charges and if they are not available (were deleted) then clear CorrectedCharge field
			vSkipAccountingDateCheck = False;
			If pSwitchOffAutoCorrections And vChargeRef.CorrectedCharge = vChargeRef Then
				vCorrectionCharges = cmGetChargeCorrectionCharges(vChargeRef);
				If vCorrectionCharges.Count() = 0 Then
					vSkipAccountingDateCheck = True;
					vChargeObj = vChargeRef.GetObject();
					vChargeObj.IsCorrection = False;
					vChargeObj.CorrectionDate = '00010101';
					vChargeObj.CorrectedCharge = Undefined;
					vChargeObj.AdditionalProperties.Insert("ChargeSplitMode", True);
					If vChargeObj.Posted Then
						vChargeObj.Write(DocumentWriteMode.Posting);
					Else
						vChargeObj.DeletionMark = False;
						vChargeObj.Write(DocumentWriteMode.Write);
					EndIf;
					vChargeRef = vChargeObj.Ref;
				EndIf;
			EndIf;
			If vChargeRef.CorrectedCharge <> vChargeRef Then
				If pServiceRow.AccountingDate < pCurrentAccountingDate And Not vSkipAccountingDateCheck Then
					If pSwitchOffAutoCorrections Then
						If pServiceRow.HotelProduct <> vChargeRef.HotelProduct Or
						   pServiceRow.SourceOfBusiness <> vChargeRef.SourceOfBusiness Or 
						   pServiceRow.MarketingCode <> vChargeRef.MarketingCode Or
						   pServiceRow.ClientType <> vChargeRef.ClientType Or 
						   pServiceRow.BoardPlace <> vChargeRef.BoardPlace Or
						   pServiceRow.AgentCommissionType <> vChargeRef.AgentCommissionType Or
						   pServiceRow.AgentCommission <> vChargeRef.AgentCommission Or
						   pServiceRow.CommissionSum <> vChargeRef.CommissionSum Or
						   pServiceRow.GuestGroup <> pChargeRow.GuestGroup Or
						   pServiceRow.Client <> pChargeRow.Client Or
						   pServiceRow.ClientAge <> pChargeRow.ClientAge Then
						   
							vChargeObj = vChargeRef.GetObject();
							FillPropertyValues(vChargeObj, pServiceRow);
							vChargeObj.IsCorrection = False;
							vChargeObj.CorrectionDate = '00010101';
							vChargeObj.CorrectedCharge = Undefined;
							vChargeObj.Date = pServiceRow.AccountingDate;
							vChargeObj.ServiceDate = pServiceRow.AccountingDate;
							vChargeObj.SetTime(AutoTimeMode.DontUse);
							If Not ValueIsFilled(vChargeObj.Author) Then
								vChargeObj.Author = SessionParameters.CurrentUser;
							EndIf;
							If ValueIsFilled(pServiceRow.IsManualAuthor) Then
								vChargeObj.Author = pServiceRow.IsManualAuthor;
							EndIf;
							vChargeObj.ParentDoc = Ref;
							
							vChargeObj.AdditionalProperties.Insert("NewGuestGroup", pServiceRow.GuestGroup);
							vChargeObj.AdditionalProperties.Insert("OldGuestGroup", pChargeRow.GuestGroup);
							vChargeObj.AdditionalProperties.Insert("NewClient", pServiceRow.Client);
							vChargeObj.AdditionalProperties.Insert("OldClient", pChargeRow.Client);
							vChargeObj.AdditionalProperties.Insert("NewClientAge", pServiceRow.ClientAge);
							vChargeObj.AdditionalProperties.Insert("OldClientAge", pChargeRow.ClientAge);
							vChargeObj.AdditionalProperties.Insert("NewTouristicTaxExemptionReason", pServiceRow.TouristicTaxExemptionReason);
							vChargeObj.AdditionalProperties.Insert("OldTouristicTaxExemptionReason", pChargeRow.TouristicTaxExemptionReason);
							vChargeObj.AdditionalProperties.Insert("NewTouristicTaxExemptionReasonFillDate", pServiceRow.TouristicTaxExemptionReasonFillDate);
							vChargeObj.AdditionalProperties.Insert("OldTouristicTaxExemptionReasonFillDate", pChargeRow.TouristicTaxExemptionReasonFillDate);
						Else
							// Do nothing
							Return vChargeRef;
						EndIf;
					Else
						vChargeObj = vChargeRef.Copy();
						FillPropertyValues(vChargeObj, pServiceRow);
						vChargeObj.Date = pCurrentAccountingDate;
						vChargeObj.ServiceDate = pServiceRow.AccountingDate;
						vChargeObj.SetTime(AutoTimeMode.DontUse);
						vChargeObj.Author = SessionParameters.CurrentUser;
						If ValueIsFilled(pServiceRow.IsManualAuthor) Then
							vChargeObj.Author = pServiceRow.IsManualAuthor;
						EndIf;
						vChargeObj.ParentDoc = Ref;
						vChargeObj.IsCorrection = True;
						vChargeObj.CorrectionDate = vChargeRef.Date;
						vChargeObj.CorrectedCharge = vChargeRef;
						// If all resources are zero, then do nothing
						If vChargeObj.Sum = 0 And vChargeObj.VATSum = 0 And 
						   vChargeObj.DiscountSum = 0 And vChargeObj.VATDiscountSum = 0 And 
						   vChargeObj.CommissionSum = 0 And vChargeObj.VATCommissionSum = 0 And
						   vChargeObj.RoomsRented = 0 And vChargeObj.BedsRented = 0 And vChargeObj.AdditionalBedsRented = 0 And 
						   vChargeObj.GuestDays = 0 And vChargeObj.GuestsCheckedIn = 0 Then
						   // Do nothing
						   Return vChargeRef;
						EndIf;
					EndIf;
				Else
					vChargeObj = vChargeRef.GetObject();
					FillPropertyValues(vChargeObj, pServiceRow);
					vChargeObj.IsCorrection = False;
					vChargeObj.CorrectionDate = '00010101';
					vChargeObj.CorrectedCharge = Undefined;
					vChargeObj.Date = pServiceRow.AccountingDate;
					vChargeObj.ServiceDate = pServiceRow.AccountingDate;
					vChargeObj.SetTime(AutoTimeMode.DontUse);
					If Not ValueIsFilled(vChargeObj.Author) Then
						vChargeObj.Author = SessionParameters.CurrentUser;
					EndIf;
					If ValueIsFilled(pServiceRow.IsManualAuthor) Then
						vChargeObj.Author = pServiceRow.IsManualAuthor;
					EndIf;
					vChargeObj.ParentDoc = Ref;
					If vSkipAccountingDateCheck Then
						vChargeObj.AdditionalProperties.Insert("ChargeSplitMode", True);
					EndIf;
				EndIf;
			Else
				// Do nothing
				Return vChargeRef;
			EndIf;
		EndIf;
		
		// Resource
		If ValueIsFilled(pServiceRow.ServiceResource) And TypeOf(pServiceRow.ServiceResource) = Type("CatalogRef.Resources") Then
			vChargeObj.Resource = pServiceRow.ServiceResource; 
		EndIf;
		
		// Fill charge exchange rate date and folio and reporting currency exchange rates
		vChargeObj.ExchangeRateDate = ?(ValueIsFilled(pServiceRow.AccountingDate), pServiceRow.AccountingDate, ExchangeRateDate);
		vChargeObj.FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(vChargeObj.Hotel, vChargeObj.FolioCurrency, vChargeObj.ExchangeRateDate);
		vChargeObj.ReportingCurrencyExchangeRate = cmGetCurrencyExchangeRate(vChargeObj.Hotel, vChargeObj.ReportingCurrency, vChargeObj.ExchangeRateDate);
		
		// Fill charge payment section
		vChargeObj.PaymentSection = vChargeObj.Service.PaymentSection;
		
		// Do not add splitted services to the hotel product sales
		If vChargeObj.IsSplit Then
			vChargeObj.HotelProduct = Catalogs.HotelProducts.EmptyRef();
		EndIf;
		
		// Move service date if neccessary
		If pServiceDateMove <> 0 Then
			vChargeObj.ServiceDate = vChargeObj.ServiceDate + 24*3600*pServiceDateMove;
		EndIf;
		
		// Check if folio is marked for deletion
		If vChargeObj.Folio.DeletionMark Then
			vFolioObj = vChargeObj.Folio.GetObject();
			vFolioObj.SetDeletionMark(False);
		EndIf;
		
		vChargeIsNew = vChargeObj.IsNew();
		
		// Fill room revenue charge
		vIsMergedToRoomRevenue = pIsMergedToRoomRevenue;
		vChargeObj.RoomRevenueCharge = Undefined;
		If ValueIsFilled(pRoomRevenueCharge) And Not vChargeObj.IsManual And pRoomRevenueCharge.Folio = vChargeObj.Folio Then
			vSetBoundCharge = False;
			vRoomRevenueChargeDate = BegOfDay(pRoomRevenueCharge.Date);
			vChargeObjDate = BegOfDay(vChargeObj.Date);
			If vRoomRevenueChargeDate <> vChargeObjDate Then
				If (vChargeObjDate - vRoomRevenueChargeDate)/(24*3600) = pAccountingDateMove Then
					vSetBoundCharge = True;
				Else
					vIsMergedToRoomRevenue = False;
				EndIf;
			ElsIf vRoomRevenueChargeDate = vChargeObjDate Then
				vSetBoundCharge = True;
			EndIf;
			If vSetBoundCharge Then
				vChargeObj.RoomRevenueCharge = pRoomRevenueCharge;
			EndIf;
		EndIf;
		If vChargeObj.IsManual Then
			vIsMergedToRoomRevenue = False;
		ElsIf ValueIsFilled(pRoomRevenueCharge) And pRoomRevenueCharge.Folio <> vChargeObj.Folio Then
			vIsMergedToRoomRevenue = False;
		EndIf;
		If vChargeIsNew Then
			vChargeObj.IsMergedToRoomRevenue = vIsMergedToRoomRevenue;
		Else
			If Not ValueIsFilled(vChargeObj.RoomRevenueCharge) And 
			   Not (vChargeObj.IsRoomRevenue And vChargeObj.IsInPrice And Not vChargeObj.RoomRevenueAmountsOnly) Then
				vChargeObj.IsMergedToRoomRevenue = False;
			EndIf;
			If vChargeObj.IsMergedToRoomRevenue And vChargeObj.IsRoomRevenue And vChargeObj.IsInPrice And Not vChargeObj.RoomRevenueAmountsOnly And Not vChargeObj.IsManual Then
				If vChargeObj.RateSum <> 0 And pChargeRow.StornoSum <> 0 Then
					vChargeObj.RateSum = vChargeObj.RateSum - pChargeRow.StornoSum;
					vChargeObj.RateDiscountSum = vChargeObj.RateDiscountSum - pChargeRow.StornoDiscountSum;
					vChargeObj.RateCommissionSum = vChargeObj.RateCommissionSum - pChargeRow.StornoCommissionSum;
				EndIf;
			EndIf;
		EndIf;

		// Post charge
		For Each vAddPropItem In AdditionalProperties Do
			vChargeObj.AdditionalProperties.Insert(vAddPropItem.Key, vAddPropItem.Value);
		EndDo;
		vChargeObj.Write(DocumentWriteMode.Posting);
		
		If Not vChargeIsNew Then
			ChargesToRepostStorno.Add(vChargeObj.Ref);
		EndIf;
		
		Return vChargeObj.Ref;
	Else
		Return Undefined;
	EndIf;
EndFunction // DoCharge

// -----------------------------------------------------------------------------
Procedure DeleteCharge(pChargeRow, pCurrentAccountingDate = '00010101', pSwitchOffAutoCorrections = True)
	vChargeRef = pChargeRow.Ref;
	// Try to find posted correction charges and if they are not available (were deleted) then clear CorrectedCharge field
	If pSwitchOffAutoCorrections And vChargeRef.CorrectedCharge = vChargeRef Then
		vCorrectionCharges = cmGetChargeCorrectionCharges(vChargeRef);
		If vCorrectionCharges.Count() = 0 Then
			vChargeObj = vChargeRef.GetObject();
			vChargeObj.IsCorrection = False;
			vChargeObj.CorrectionDate = '00010101';
			vChargeObj.CorrectedCharge = Undefined;
			vChargeObj.AdditionalProperties.Insert("ChargeSplitMode", True);
			If vChargeObj.Posted Then
				vChargeObj.Write(DocumentWriteMode.Posting);
			Else
				vChargeObj.DeletionMark = False;
				vChargeObj.Write(DocumentWriteMode.Write);
			EndIf;
			vChargeRef = vChargeObj.Ref;
		EndIf;
	EndIf;
	// Check charge accounting date
	If vChargeRef.CorrectedCharge <> vChargeRef Then
		If BegOfDay(vChargeRef.Date) < pCurrentAccountingDate Then
			If pSwitchOffAutoCorrections Then
				If Not vChargeRef.IsSplit And 
				  (HotelProduct <> vChargeRef.HotelProduct Or
				   SourceOfBusiness <> vChargeRef.SourceOfBusiness Or 
				   MarketingCode <> vChargeRef.MarketingCode Or
				   ClientType <> vChargeRef.ClientType Or 
				   BoardPlace <> vChargeRef.BoardPlace) Then
					// Update charge hotel product
					vChargeObj = vChargeRef.GetObject();
					vChargeObj.HotelProduct = HotelProduct;
					vChargeObj.SourceOfBusiness = SourceOfBusiness;
					vChargeObj.MarketingCode = MarketingCode;
					vChargeObj.ClientType = ClientType;
					vChargeObj.BoardPlace = BoardPlace;
					If vChargeObj.Folio.DeletionMark Then
						vFolioObj = vChargeObj.Folio.GetObject();
						vFolioObj.SetDeletionMark(False);
					EndIf;
					For Each vAddPropItem In AdditionalProperties Do
						vChargeObj.AdditionalProperties.Insert(vAddPropItem.Key, vAddPropItem.Value);
					EndDo;
					vChargeObj.Write(DocumentWriteMode.Posting);
				EndIf;
			Else
				vChargeObj = vChargeRef.Copy();
				vChargeObj.pmFillAuthorAndDate(pCurrentAccountingDate);
				vChargeObj.IsCorrection = True;
				vChargeObj.CorrectionDate = vChargeRef.Date;
				vChargeObj.CorrectedCharge = vChargeRef;
				// Correction for resources
				vChargeObj.Quantity = -pChargeRow.Quantity;
				vChargeObj.Sum = -pChargeRow.Sum;
				vChargeObj.VATSum = -pChargeRow.VATSum;
				vChargeObj.DiscountSum = -pChargeRow.DiscountSum;
				vChargeObj.VATDiscountSum = -pChargeRow.VATDiscountSum;
				vChargeObj.CommissionSum = -pChargeRow.CommissionSum;
				vChargeObj.VATCommissionSum = -pChargeRow.VATCommissionSum;
				vChargeObj.RoomsRented = -pChargeRow.RoomsRented;
				vChargeObj.BedsRented = -pChargeRow.BedsRented;
				vChargeObj.AdditionalBedsRented = -pChargeRow.AdditionalBedsRented;
				vChargeObj.GuestDays = -pChargeRow.GuestDays;
				vChargeObj.GuestsCheckedIn = -pChargeRow.GuestsCheckedIn;
				For Each vAddPropItem In AdditionalProperties Do
					vChargeObj.AdditionalProperties.Insert(vAddPropItem.Key, vAddPropItem.Value);
				EndDo;
				vChargeObj.Write(DocumentWriteMode.Posting);
			EndIf;
		Else
			vChargeObj = vChargeRef.GetObject();
			vChargeObj.SetDeletionMark(True);
		EndIf;
	EndIf;
EndProcedure //  DeleteCharge

// -----------------------------------------------------------------------------
Procedure ChargeServiceDifferences(pTab, pServices, pCharges)
	vCurrentAccountingDate = '00010101';
	If Hotel.DoNotEditClosedDateDocs Then
		vCurrentAccountingDate = tcOnServer.GetForecastStartDate(Hotel);
	EndIf;
	// Create cache value table with service parameters
	vServiceQCRTypes = New ValueTable();
	vServiceQCRTypes.Columns.Add("Service");
	vServiceQCRTypes.Columns.Add("ServiceType");
	vServiceQCRTypes.Columns.Add("QuantityCalculationRule");
	vServiceQCRTypes.Columns.Add("QuantityCalculationRuleType");
	vServiceQCRTypes.Columns.Add("ChargeMealsAtFirstDay");
	vServiceQCRTypes.Columns.Add("ActualAmountIsChargedExternally");
	// Day room revenue charge
	vDayRoomRevenueCharge = Undefined;
	// For each row in current services table
	For Each vServiceRow In pServices Do
		vService = vServiceRow.Service;
		If Not ValueIsFilled(vService) Then
			Continue;
		EndIf;
		// Get service charging rule parameters
		vServiceQCRTypesRow = vServiceQCRTypes.Find(vService, "Service");
		vServiceType = Undefined;
		vQuantityCalculationRule = Undefined;
		vQuantityCalculationRuleType = Undefined;
		vChargeMealsAtFirstDay = False;
		vActualAmountIsChargedExternally = False;
		If vServiceQCRTypesRow <> Undefined Then
			vServiceType = vServiceQCRTypesRow.ServiceType;
			vQuantityCalculationRule = vServiceQCRTypesRow.QuantityCalculationRule;
			vQuantityCalculationRuleType = vServiceQCRTypesRow.QuantityCalculationRuleType;
			vChargeMealsAtFirstDay = vServiceQCRTypesRow.ChargeMealsAtFirstDay;
			vActualAmountIsChargedExternally = vServiceQCRTypesRow.ActualAmountIsChargedExternally;
		Else
			vQuantityCalculationRule = vService.QuantityCalculationRule;
			If ValueIsFilled(vQuantityCalculationRule) Then
				vQuantityCalculationRuleType = vQuantityCalculationRule.QuantityCalculationRuleType;
				vChargeMealsAtFirstDay = vQuantityCalculationRule.ChargeMealsAtFirstDay;
			EndIf;
			vServiceType = vService.ServiceType;
			If ValueIsFilled(vServiceType) Then
				vActualAmountIsChargedExternally = vServiceType.ActualAmountIsChargedExternally;
			EndIf;
			
			vServiceQCRTypesRow = vServiceQCRTypes.Add();
			vServiceQCRTypesRow.Service = vService;
			vServiceQCRTypesRow.ServiceType = vService.ServiceType;
			vServiceQCRTypesRow.QuantityCalculationRule = vQuantityCalculationRule;
			vServiceQCRTypesRow.QuantityCalculationRuleType = vQuantityCalculationRuleType;
			vServiceQCRTypesRow.ChargeMealsAtFirstDay = vChargeMealsAtFirstDay;
			vServiceQCRTypesRow.ActualAmountIsChargedExternally = vActualAmountIsChargedExternally;
		EndIf;
		// Check if we have to move service date
		vAccountingDateMove = 0;
		vServiceDateMove = cmGetServiceDateMove(vQuantityCalculationRule, vQuantityCalculationRuleType, vChargeMealsAtFirstDay, vServiceRow.IsManual, ThisObject, False, vAccountingDateMove);
		// Check if this service has to be charged by external system
		If vActualAmountIsChargedExternally Then
			If vServiceRow.AccountingDate < vCurrentAccountingDate Or ReservationStatus.IsCheckIn Then
				// Try to find the same row in the existing charges
				vChargeRow = cmGetChargeRow(pCharges, vServiceRow);
				// Delete previous charge
				If vChargeRow <> Undefined Then
					DeleteCharge(vChargeRow, vCurrentAccountingDate, Hotel.SwitchOffAutoCorrections);
					pCharges.Delete(vChargeRow);
				EndIf;
				// Process next service
				Continue;
			EndIf;
		EndIf;
		// Try to find difference rows for the current service row
		vDiffRows = pTab.FindRows(New Structure("AccountingDate, LineNumber", vServiceRow.AccountingDate, vServiceRow.LineNumber));
		If vDiffRows.Count() = 1 Then
			vDiffRow = vDiffRows.Get(0);
			If cmServiceResourcesAreZero(vDiffRow) Then
				vChargeRow = cmGetChargeRow(pCharges, vServiceRow);
				If vChargeRow <> Undefined Then
					// Charge is the same as current service
					vChargeRef = DoChargeTransfer(vServiceRow, vChargeRow, vServiceDateMove);
					// Fill link to the room revenue charge for the current date
					If ValueIsFilled(vChargeRef) And vServiceRow.IsInPrice And 
					   vServiceRow.IsRoomRevenue And Not vServiceRow.IsSplit And Not vServiceRow.RoomRevenueAmountsOnly And Not vServiceRow.IsManual Then
						If Not ValueIsFilled(vDayRoomRevenueCharge) Or 
						   ValueIsFilled(vDayRoomRevenueCharge) And BegOfDay(vDayRoomRevenueCharge.Date) <> vServiceRow.AccountingDate Then
							vDayRoomRevenueCharge = vChargeRef;
						EndIf;
					EndIf;
					pCharges.Delete(vChargeRow);
				EndIf;
				Continue;
			EndIf;
		EndIf;
		// Add new charge for the current service row
		vChargeRef = Undefined;
		vChargeRow = cmGetChargeRow(pCharges, vServiceRow);
		If ValueIsFilled(vDayRoomRevenueCharge) And vServiceRow.IsInPrice And 
		   Not (vServiceRow.IsRoomRevenue And Not vServiceRow.IsSplit And Not vServiceRow.RoomRevenueAmountsOnly) Then
			vChargeRef = DoCharge(vServiceRow, vChargeRow, vCurrentAccountingDate, Hotel.SwitchOffAutoCorrections, vServiceDateMove, vAccountingDateMove, vDayRoomRevenueCharge, Hotel.RoomRatePackagesServicesAreNotShownInFolios);
		Else
			If vServiceRow.IsInPrice And 
			   vServiceRow.IsRoomRevenue And Not vServiceRow.IsSplit And Not vServiceRow.RoomRevenueAmountsOnly Then
				vChargeRef = DoCharge(vServiceRow, vChargeRow, vCurrentAccountingDate, Hotel.SwitchOffAutoCorrections, vServiceDateMove, vAccountingDateMove, , Hotel.RoomRatePackagesServicesAreNotShownInFolios);
			Else
				vChargeRef = DoCharge(vServiceRow, vChargeRow, vCurrentAccountingDate, Hotel.SwitchOffAutoCorrections, vServiceDateMove, vAccountingDateMove);
			EndIf;
		EndIf;
		If ValueIsFilled(vChargeRef) And vServiceRow.IsInPrice And 
		   vServiceRow.IsRoomRevenue And Not vServiceRow.IsSplit And Not vServiceRow.RoomRevenueAmountsOnly And Not vServiceRow.IsManual Then
			If Not ValueIsFilled(vDayRoomRevenueCharge) Or 
			   ValueIsFilled(vDayRoomRevenueCharge) And BegOfDay(vDayRoomRevenueCharge.Date) <> vServiceRow.AccountingDate Then
				vDayRoomRevenueCharge = vChargeRef;
			EndIf;
		EndIf;
		// Remove processed row from the working table
		If vChargeRow <> Undefined Then
			pCharges.Delete(vChargeRow);
		EndIf;
	EndDo; // By services
	// Delete all charges left in previously charged table of services
	For Each vChargeRow In pCharges Do
		DeleteCharge(vChargeRow, vCurrentAccountingDate, Hotel.SwitchOffAutoCorrections);
	EndDo;
	pCharges.Clear();
EndProcedure // ChargeServiceDifferences

// -----------------------------------------------------------------------------
Procedure PostToAccumulatingDiscountResources()
	vBegOfCheckInDate = BegOfDay(CheckInDate);
	vBegOfCheckOutDate = BegOfDay(CheckOutDate);
	// Clear register records
	RegisterRecords.AccumulatingDiscountResources.Clear();
	// Check if reservation is active
	If ValueIsFilled(ReservationStatus) And ReservationStatus.IsActive And (Not DoCharging Or DoCharging And ReservationStatus.AlwaysChargeInAdvanceServicesOnly) Then
		// Get accummulating discount types
		vDiscountType = Undefined;
		If ValueIsFilled(DiscountType) And DiscountType.IsAccumulatingDiscount Then
			vDiscountType = DiscountType;
		EndIf;
		vAccDiscounts = cmGetAccumulatingDiscountTypes(vDiscountType, Hotel);
		For Each vAccDiscount In vAccDiscounts Do
			// Process discount type
			vDiscountType = vAccDiscount.DiscountType;
			If TurnOffAutomaticDiscounts Then
				If DiscountType <> vDiscountType Then
					Continue;
				EndIf;
			EndIf;
			If ValueIsFilled(vDiscountType) And vDiscountType.ExternalBonusSystemIsUsed Then
				Continue;
			EndIf;
			If vDiscountType.MLOS > 0 And Duration < vDiscountType.MLOS Then
				Continue;
			EndIf;
			vDiscountServiceGroup = vDiscountType.DiscountServiceGroup;
			For Each vSrvRow In Services Do
				If vSrvRow.Quantity = 0 Then
					Continue;
				EndIf;
				If Not ValueIsFilled(vSrvRow.AccountingDate) Then
					Continue;
				EndIf;
				If Not ValueIsFilled(vSrvRow.Service) Then
					Continue;
				EndIf;
				vAccountingDate = vSrvRow.AccountingDate;
				vService = vSrvRow.Service;
				If ValueIsFilled(vService) And ValueIsFilled(vService.QuantityCalculationRule) Then
					vAccountingDateMove = cmGetAccountingDateMove(vService.QuantityCalculationRule, vSrvRow.IsManual, ThisObject, False); 
					If vAccountingDateMove < 0 Then
						vAccountingDate = vAccountingDate + vAccountingDateMove*(24*3600);
					EndIf;
				EndIf;
				If ValueIsFilled(ReservationStatus) And (ReservationStatus.IsActive Or ReservationStatus.IsPreliminary) And 
			       ValueIsFilled(DoChargingToDate) And vAccountingDate <= DoChargingToDate Then
					// Service will be charged in advance
					Continue;
				EndIf;
				// Check discount type is valid period
				If vAccountingDate < vAccDiscount.DateValidFrom Or ValueIsFilled(vAccDiscount.DateValidTo) And vAccountingDate > vAccDiscount.DateValidTo Then
					Continue;
				EndIf;
				If DoCharging And ReservationStatus.AlwaysChargeInAdvanceServicesOnly Then
					If vService.AlwaysChargeInAdvance Then
						Continue;
					EndIf;
				EndIf;
				If ValueIsFilled(vSrvRow.Folio) Then
					vSrvRecFolio = vSrvRow.Folio;
					If ValueIsFilled(vSrvRecFolio.PaymentMethod) And vSrvRecFolio.PaymentMethod.ChargeServicesInAdvance Then
						Continue;
					EndIf;
				EndIf;
				If cmIsServiceInServiceGroup(vService, vDiscountServiceGroup) Then
					If Not vDiscountType.IsForRackRatesOnly Or 
					   vDiscountType.IsForRackRatesOnly And ValueIsFilled(vSrvRow.RoomRate) And vSrvRow.RoomRate.IsRackRate Or 
					   vSrvRow.IsManual Then
						vDiscountTypeObj = vDiscountType.GetObject();
						vDiscountDimension = Undefined;
						vNumberOfPersons = NumberOfPersons;
						If ValueIsFilled(vSrvRow.RoomRate) And vSrvRow.GuestDays > 0 Then
							If vSrvRow.RoomRate.RateChargeDirection = Enums.RateChargeDirections.MergeToTheMainRoomGuest Then
								vNumberOfPersons = NumberOfPersons * vSrvRow.GuestDays;
							EndIf;
						ElsIf ValueIsFilled(RoomRate) And vSrvRow.GuestDays > 0 Then
							If RoomRate.RateChargeDirection = Enums.RateChargeDirections.MergeToTheMainRoomGuest Then
								vNumberOfPersons = NumberOfPersons * vSrvRow.GuestDays;
							EndIf;
						EndIf;
						vResource = vDiscountTypeObj.pmCalculateResource(vSrvRow, vNumberOfPersons, vSrvRow.Folio, DiscountCard, vDiscountDimension);
						If vResource <> 0 Then
							If ValueIsFilled(vDiscountDimension) Then
								Movement = RegisterRecords.AccumulatingDiscountResources.Add();
								If vResource > 0 Then
									Movement.RecordType = AccumulationRecordType.Receipt;
								Else
									Movement.RecordType = AccumulationRecordType.Expense;
								EndIf;
								Movement.Period = vSrvRow.AccountingDate;
								Movement.DiscountType = vDiscountType;
								Movement.DiscountDimension = vDiscountDimension;
								If vDiscountType.IsPerVisit Or vDiscountType.BonusCalculationFactor <> 0 Then
									Movement.GuestGroup = GuestGroup;
								EndIf;
								Movement.Resource = vResource;
								If vDiscountTypeObj.BonusCalculationFactor <> 0 Then
									Movement.Bonus = vResource * vDiscountTypeObj.BonusCalculationFactor;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	// Write register records
	RegisterRecords.AccumulatingDiscountResources.Write();
EndProcedure // PostToAccumulatingDiscountResources

// -----------------------------------------------------------------------------
Procedure ChargeServices(pCancel, pPostingMode)
	vBegOfCheckInDate = BegOfDay(CheckInDate);
	vBegOfCheckOutDate = BegOfDay(CheckOutDate);
	ChargesToRepostStorno = New ValueList();

	// 1. Build table of already charged services
	vIsForFolioSplit = IsForFolioSplit;
	If AdditionalProperties.Property("IsForFolioSplit") And TypeOf(AdditionalProperties.IsForFolioSplit) = Type("Boolean") Then
		vIsForFolioSplit = AdditionalProperties.IsForFolioSplit;
	EndIf;
	vChargesTab = cmGetTableOfAlreadyChargedServices(Ref, vIsForFolioSplit,
	                                                 ?(AdditionalProperties.Property("OldGuestGroup"), AdditionalProperties.OldGuestGroup, Undefined),
	                                                 ?(AdditionalProperties.Property("OldClient"), AdditionalProperties.OldClient, Undefined),
	                                                 ?(AdditionalProperties.Property("OldClientCitizenship"), AdditionalProperties.OldClientCitizenship, Undefined),
	                                                 ?(AdditionalProperties.Property("OldClientRegion"), AdditionalProperties.OldClientRegion, Undefined),
	                                                 ?(AdditionalProperties.Property("OldClientCity"), AdditionalProperties.OldClientCity, Undefined),
	                                                 ?(AdditionalProperties.Property("OldClientAge"), AdditionalProperties.OldClientAge, Undefined),
	                                                 ?(AdditionalProperties.Property("OldTouristicTaxExemptionReason"), AdditionalProperties.OldTouristicTaxExemptionReason, Undefined),
	                                                 ?(AdditionalProperties.Property("OldTouristicTaxExemptionReasonFillDate"), AdditionalProperties.OldTouristicTaxExemptionReasonFillDate, Undefined));
	
	// 2. Create table of document services
	vServicesTab = Services.Unload();
	// Remove services with 0 quantity or leave services allowed for prepayment only
	i = 0;
	While i < vServicesTab.Count() Do
		vSrvRow = vServicesTab.Get(i);
		vSrvRowFolio = vSrvRow.Folio;
		vSrvRowAccountingDate = vSrvRow.AccountingDate;
		vSrvRowService = vSrvRow.Service;
		If vBegOfCheckInDate < vBegOfCheckOutDate Then
			If ValueIsFilled(vSrvRowService) And ValueIsFilled(vSrvRowService.QuantityCalculationRule) Then
				vAccountingDateMove = cmGetAccountingDateMove(vSrvRowService.QuantityCalculationRule, vSrvRow.IsManual, ThisObject, False); 
				If vAccountingDateMove < 0 Then
					vSrvRowAccountingDate = vSrvRowAccountingDate + vAccountingDateMove*(24*3600);
				EndIf;
			EndIf;
		EndIf;
		If vSrvRow.Quantity = 0 Then
			vServicesTab.Delete(i);
		ElsIf Not DoCharging And ValueIsFilled(ReservationStatus) And Not ReservationStatus.IsCheckIn And (ReservationStatus.IsActive Or ReservationStatus.IsPreliminary) And 
		      ValueIsFilled(vSrvRowFolio) And ValueIsFilled(vSrvRowFolio.PaymentMethod) And vSrvRowFolio.PaymentMethod.ChargeServicesInAdvance Then
			i = i + 1;
		ElsIf ValueIsFilled(ReservationStatus) And (ReservationStatus.IsActive Or ReservationStatus.IsPreliminary) And 
		      ValueIsFilled(DoChargingToDate) And vSrvRowAccountingDate <= DoChargingToDate Then
			i = i + 1;
		ElsIf Not DoCharging Then
			vServicesTab.Delete(i);
		ElsIf DoCharging And ValueIsFilled(ReservationStatus) And ReservationStatus.AlwaysChargeInAdvanceServicesOnly And Not vSrvRowService.AlwaysChargeInAdvance Then
			vServicesTab.Delete(i);
		Else
			i = i + 1;
		EndIf;
	EndDo;
	
	// Add analitical dimensions to the services table
	cmAddServicesDimensionsColumns(vServicesTab);
	
	For Each vSrv In vServicesTab Do
		// Try to set folio for the transfered charges
		vChargesRows = vChargesTab.FindRows(New Structure("AccountingDate", vSrv.AccountingDate));
		For Each vChargesRow In vChargesRows Do
			If ValueIsFilled(vChargesRow.ChargeTransfer) And
			   vSrv.Service = vChargesRow.Service And
			   vSrv.Price = vChargesRow.Price And
			   vSrv.VATRate = vChargesRow.VATRate And
			   vSrv.IsManual = vChargesRow.IsManual Then
				vSrv.Folio = vChargesRow.Folio;
				vSrv.FolioCurrency = vSrv.Folio.FolioCurrency;
				If ValueIsFilled(vSrv.Folio.Company) Then
					vSrv.Company = vSrv.Folio.Company;
				EndIf;
				Break;
			EndIf;
		EndDo;
		// Fill additional charge attributes
		cmFillServicesDimensionsColumns(vSrv, ThisObject);
	EndDo;
	
	// 3. Build difference table between already charged services and 
	// services in the document. We will do it ignoring folios.
	vServicesDifferenceTab = cmGetServicesDifference(vServicesTab, vChargesTab);
	
	// 4. Create charging for each service in difference services
	ChargeServiceDifferences(vServicesDifferenceTab, vServicesTab, vChargesTab);
	
	// 5. Repost storno for changed charges
	If ChargesToRepostStorno.Count() > 0 Then
		RepostStornosForChangedCharges();
	EndIf;
EndProcedure // ChargeServices

// -----------------------------------------------------------------------------
Procedure RepostStornosForChangedCharges()
	// Get list of stornos to repost
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Storno.Ref AS Ref
	|FROM
	|	Document.Storno AS Storno
	|WHERE
	|	Storno.ParentCharge IN (&qChargesToRepostStorno)
	|	AND Storno.Posted";
	vQry.SetParameter("qChargesToRepostStorno", ChargesToRepostStorno);
	vStornos = vQry.Execute().Unload();
	For Each vStornosRow In vStornos Do
		vStornoObj = vStornosRow.Ref.GetObject();
		vStornoObj.Write(DocumentWriteMode.Posting);
	EndDo;
EndProcedure // RepostStornosForChangedCharges

// -----------------------------------------------------------------------------
Procedure FillFolioParameters(pCancel)
	// Get last reservation in chain and use it to set folio parameters
	vLastReservation = pmGetLastReservationInChain();
	// Set parameters of the folios in the charging rules
	For Each vCRRec In ChargingRules Do
		If ValueIsFilled(vCRRec.ChargingFolio) Then
			vFolioRef = vCRRec.ChargingFolio;
			If Not vCRRec.IsMaster And Not vFolioRef.IsMaster Then
				If Not ValueIsFilled(vCRRec.Owner) Or 
				   (TypeOf(vCRRec.Owner) <> Type("DocumentRef.Accommodation") And 
				    TypeOf(vCRRec.Owner) <> Type("DocumentRef.Reservation")) Then
					// Skip transfer rules
					If vCRRec.IsTransfer Then
						Continue;
					EndIf;
					// Check if there is accommodation for this folio
					If ValueIsFilled(vFolioRef.ParentDoc) And TypeOf(vFolioRef.ParentDoc) = Type("DocumentRef.Accommodation") 
					   And vFolioRef.ParentDoc.Posted And ValueIsFilled(vFolioRef.ParentDoc.AccommodationStatus) And 
					   vFolioRef.ParentDoc.AccommodationStatus.IsActive Then
						Continue;
					EndIf;
					// Update folio attributes
					vDoCheckOfAnaliticalParametersChange = False;
					vFolioIsChanged = False;
					vFolioObj = vFolioRef.GetObject();
					vFolioObj.Read();
					If vFolioObj.Hotel <> Hotel Then
						vFolioObj.Hotel = Hotel;
						vFolioIsChanged = True;
					EndIf;
					If Not vFolioObj.DoNotUpdateCompany Then
						If ValueIsFilled(Room) And ValueIsFilled(Room.Company) Or
						   ValueIsFilled(RoomType) And ValueIsFilled(RoomType.Company) Or 
						   ValueIsFilled(RoomRate) And ValueIsFilled(RoomRate.Company) Or 
						   ((Not ValueIsFilled(Room) Or ValueIsFilled(Room) And Not ValueIsFilled(Room.Company)) And 
						    ValueIsFilled(RoomType) And Not ValueIsFilled(RoomType.Company) And 
							ValueIsFilled(RoomRate) And Not ValueIsFilled(RoomRate.Company)) Then
							If vFolioObj.Company <> Company Then
								vFolioObj.Company = Company;
								vDoCheckOfAnaliticalParametersChange = True;
								vFolioIsChanged = True;
							EndIf;
						EndIf;
					EndIf;
					If Not ValueIsFilled(vFolioObj.ParentDoc) Or 
					   vFolioObj.ParentDoc <> Ref And 
					   (TypeOf(vFolioObj.ParentDoc) <> Type("DocumentRef.Accommodation") Or 
					    TypeOf(vFolioObj.ParentDoc) = Type("DocumentRef.Accommodation") And 
						(Not vFolioObj.ParentDoc.Posted Or vFolioObj.ParentDoc.Posted And Not vFolioObj.ParentDoc.AccommodationStatus.IsActive)) Then
						vFolioObj.ParentDoc = pmGetThisDocumentRef();
						vFolioIsChanged = True;
					EndIf;
					If TypeOf(vCRRec.Owner) <> Type("CatalogRef.Clients") Then
						If vFolioObj.Client <> Guest Then
							vFolioObj.Client = Guest;
							vFolioIsChanged = True;
						EndIf;
					EndIf;
					If vFolioObj.GuestGroup <> GuestGroup Then
						vFolioObj.GuestGroup = GuestGroup;
						vFolioIsChanged = True;
					EndIf;
					If TypeOf(vCRRec.Owner) <> Type("CatalogRef.Rooms") Then
						If vFolioObj.Room <> Room Then
							vFolioObj.Room = Room;
							vFolioIsChanged = True;
						EndIf;
					EndIf;
					vDateTimeFrom = pmGetCheckInDate();
					If ValueIsFilled(vCRRec.ValidFromDate) Then
						vRefHour = cmGetReferenceHour(RoomRate);
						vDateTimeFrom = cm1SecondShift(BegOfDay(vCRRec.ValidFromDate) + (vRefHour - BegOfDay(vRefHour)));
					EndIf;
					If vFolioObj.DateTimeFrom <> vDateTimeFrom Then
						vFolioObj.DateTimeFrom = vDateTimeFrom;
						vFolioIsChanged = True;
					EndIf;
					vDateTimeTo = vLastReservation.CheckOutDate;
					If ValueIsFilled(vCRRec.ValidToDate) Then
						vRefHour = cmGetReferenceHour(RoomRate);
						vDateTimeTo = cm0SecondShift(BegOfDay(vCRRec.ValidToDate) + (vRefHour - BegOfDay(vRefHour)) + 24*3600);
					EndIf;
					If vFolioObj.DateTimeTo <> vDateTimeTo Then
						vFolioObj.DateTimeTo = vDateTimeTo;
						vFolioIsChanged = True;
					EndIf;
					If Not ValueIsFilled(vFolioObj.Customer) Then
						If Not ValueIsFilled(vFolioObj.PaymentMethod) Then
							If ValueIsFilled(PlannedPaymentMethod) Then
								If vFolioObj.PaymentMethod <> PlannedPaymentMethod Then
									vFolioObj.PaymentMethod = PlannedPaymentMethod;
									vFolioIsChanged = True;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
					If ValueIsFilled(ReservationStatus) Then
						If Not ReservationStatus.IsCheckIn And Not ReservationStatus.IsActive And Not ReservationStatus.IsPreliminary Then
							If Not vFolioObj.IsClosed Then
								// Check that there is no other active documents referencing this folio
								vFolioDocs = cmGetActiveFolioDocuments(vFolioObj.Ref, Ref);
								// Close folio
								If vFolioDocs.Count() = 0 Then
									vFolioObj.IsClosed = True;
									vFolioIsChanged = True;
								EndIf;
							EndIf;
						Else
							If vFolioObj.IsClosed Then
								vFolioObj.IsClosed = False;
								vFolioIsChanged = True;
							EndIf;
						EndIf;
					EndIf;
					If Agent <> vFolioObj.Agent Then
						vFolioObj.Agent = Agent;
						vFolioIsChanged = True;
					EndIf;
					If ValueIsFilled(HotelProduct) Then
						vHotelProductParent = Undefined;
						If HotelProduct.IsFolder Then
							vHotelProductParent = HotelProduct;
						Else
							vHotelProductParent = HotelProduct.Parent;
						EndIf;
						If ValueIsFilled(vHotelProductParent) And ValueIsFilled(vHotelProductParent.PaymentSection) Then
							vAccSrvFolio = pmGetAccommodationServiceChargingFolio();
							If vCRRec.ChargingFolio = vAccSrvFolio Then
								If vHotelProductParent.PaymentSection <> vFolioObj.PaymentSection Then
									vFolioObj.PaymentSection = vHotelProductParent.PaymentSection;
									vFolioIsChanged = True;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
					If ValueIsFilled(ClientType) And ValueIsFilled(ClientType.PaymentSection) Then
						vAccSrvFolio = pmGetAccommodationServiceChargingFolio();
						If vCRRec.ChargingFolio = vAccSrvFolio Then
							If ClientType.PaymentSection <> vFolioObj.PaymentSection Then
								vFolioObj.PaymentSection = ClientType.PaymentSection;
								vFolioIsChanged = True;
							EndIf;
						EndIf;
					EndIf;
					If ValueIsFilled(vCRRec.Owner) Then
						If TypeOf(vCRRec.Owner) = Type("CatalogRef.Customers") Then
							If vFolioObj.Customer <> vCRRec.Owner Then
								vFolioObj.Customer = vCRRec.Owner;
								vFolioObj.Contract = Catalogs.Contracts.EmptyRef();
								vDoCheckOfAnaliticalParametersChange = True;
								vFolioIsChanged = True;
							EndIf;
						ElsIf TypeOf(vCRRec.Owner) = Type("CatalogRef.Contracts") Then
							If vFolioObj.Contract <> vCRRec.Owner Then
								vFolioObj.Customer = vCRRec.Owner.Owner;
								vFolioObj.Contract = vCRRec.Owner;
								vDoCheckOfAnaliticalParametersChange = True;
								vFolioIsChanged = True;
							EndIf;
						ElsIf TypeOf(vCRRec.Owner) = Type("CatalogRef.Clients") Then
							If vFolioObj.Client <> vCRRec.Owner Then
								vFolioObj.Client = vCRRec.Owner;
								vFolioIsChanged = True;
							EndIf;
						EndIf;
					Else
						If ValueIsFilled(vFolioObj.Customer) Then
							vFolioObj.Customer = Catalogs.Customers.EmptyRef();
							vFolioObj.Contract = Catalogs.Contracts.EmptyRef();
							vDoCheckOfAnaliticalParametersChange = True;
							vFolioIsChanged = True;
						EndIf;
					EndIf;
					If TrimAll(vFolioObj.Remarks) <> TrimAll(Remarks) Then
						vAccommodationServices = Services.FindRows(New Structure("Folio, IsRoomRevenue, IsInPrice, IsSplit", vFolioRef, True, True, False));
						If vAccommodationServices.Count() > 0 Then
							vFolioObj.Remarks = TrimAll(Remarks);
							vFolioIsChanged = True;
						EndIf;
					EndIf;
					If vFolioObj.DeletionMark Then
						vFolioObj.DeletionMark = False;
						vFolioIsChanged = True;
					EndIf;
					If vFolioObj.LineNumber <> (ChargingRules.IndexOf(vCRRec) + 1) Then
						vFolioObj.LineNumber = ChargingRules.IndexOf(vCRRec) + 1;
						vFolioIsChanged = True;
					EndIf;
					If vFolioIsChanged Then
						If Not vDoCheckOfAnaliticalParametersChange Then
							vFolioObj.AdditionalProperties.Insert("SkipCheckOfAnaliticalParametersChange", True);
						EndIf;
						vFolioObj.Write(DocumentWriteMode.Write);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	// Process extra folios created manually
	vFolios = cmGetActiveDocumentFolios(Ref);
	For Each vFoliosRow In vFolios Do
		If ValueIsFilled(vFoliosRow.Folio) Then
			vFolioRef = vFoliosRow.Folio;
			If ChargingRules.Find(vFolioRef, "ChargingFolio") <> Undefined Then
				Continue;
			EndIf;
			vDoCheckOfAnaliticalParametersChange = False;
			vFolioIsChanged = False;
			vFolioObj = vFolioRef.GetObject();
			vFolioObj.Read();
			If vFolioObj.Hotel <> Hotel Then
				vFolioObj.Hotel = Hotel;
				vDoCheckOfAnaliticalParametersChange = True;
				vFolioIsChanged = True;
			EndIf;
			If Not vFolioObj.IsMaster Then
				If vFolioObj.Client <> Guest Then
					vFolioObj.Client = Guest;
					vFolioIsChanged = True;
				EndIf;
				If vFolioObj.GuestGroup <> GuestGroup Then
					vFolioObj.GuestGroup = GuestGroup;
					vFolioIsChanged = True;
				EndIf;
				If vFolioObj.Room <> Room Then
					vFolioObj.Room = Room;
					vFolioIsChanged = True;
				EndIf;
				vDateTimeFrom = pmGetCheckInDate();
				If vFolioObj.DateTimeFrom <> vDateTimeFrom Then
					vFolioObj.DateTimeFrom = vDateTimeFrom;
					vFolioIsChanged = True;
				EndIf;
				vDateTimeTo = vLastReservation.CheckOutDate;
				If vFolioObj.DateTimeTo <> vDateTimeTo Then
					vFolioObj.DateTimeTo = vDateTimeTo;
					vFolioIsChanged = True;
				EndIf;
			EndIf;
			If vFolioObj.DeletionMark Then
				vFolioObj.DeletionMark = False;
				vFolioIsChanged = True;
			EndIf;
			// Save changes if folio object was changed
			If vFolioIsChanged Then
				If Not vDoCheckOfAnaliticalParametersChange Then
					vFolioObj.AdditionalProperties.Insert("SkipCheckOfAnaliticalParametersChange", True);
				EndIf;
				vFolioObj.Write(DocumentWriteMode.Write);
			EndIf;
		EndIf;
	EndDo;
EndProcedure // FillFolioParameters

// -----------------------------------------------------------------------------
Procedure SetFolioStatuses(pCancel)
	// Check current folio status state
	If Not ReservationStatus.IsActive And Not ReservationStatus.IsPreliminary Then
		// Close all folios of the current document
		vFolios = cmGetActiveDocumentFolios(Ref);
		For Each vFoliosRow In vFolios Do
			If ValueIsFilled(vFoliosRow.Folio) Then
				vFolioRef = vFoliosRow.Folio;
				If Not vFolioRef.IsMaster Then
					// Check should we change folio status at all
					If ValueIsFilled(AccommodationType) And AccommodationType.PostToRoomMainFolio And 
					   ValueIsFilled(vFolioRef.ParentDoc) And vFolioRef.ParentDoc <> Ref Then
						Continue;
					EndIf;
					// Check that there is no other active documents referencing this folio
					vFolioDocs = cmGetActiveFolioDocuments(vFolioRef, Ref);
					If Not vFolioRef.IsClosed Then
						// Close folio
						If vFolioDocs.Count() = 0 Then
							vFolioObj = vFolioRef.GetObject();
							// Get previous reservation status
							If Not AdditionalProperties.Property("InfoBaseUpdateMode") And Not AdditionalProperties.Property("CloseOfDayMode") Then
								If Not ReservationStatus.IsCheckIn Then
									vPrevResStates = pmGetReservationHistoryState(CurrentSessionDate());
									If vPrevResStates.Count() > 0 Then
										vPrevResStatesRow = vPrevResStates.Get(0);
										If vPrevResStatesRow.ReservationStatus <> ReservationStatus And Not vPrevResStatesRow.ReservationStatus.DoCharging Then
											// Check folio balance
											If ValueIsFilled(vFolioObj.Customer) And Not vFolioObj.Customer.IsIndividual Then
												If Not cmCheckUserPermissions("HavePermissionToCheckOutAccommodationsWithCustomerDebts") Then
													vFolioBalance = vFolioObj.pmGetBalance(, vFolioObj.Hotel);
													If vFolioBalance <> 0 Then
														Raise NStr("en='You do not have rights to close customer folio with non zero balance! '; ru='Нет прав закрывать лицевой счет контрагента с не нулевым балансом! '; de='Sie haben nicht das Recht, ein Firmen Konto mit Bilanz ungleich Null zu schließen! '") + 
														      NStr("en='Folio N'; ru='Фолио №'; de='Folio Nr.'") + TrimAll(vFolioObj.Number) + ?(vFolioBalance > 0, NStr("en=' - debt is '; ru=' - долг '; de=' - Schulden '"), NStr("en=' - advance is '; ru=' - предоплата '; de=' - Vorauszahlung '")) + cmFormatSum(?(vFolioBalance < 0, -vFolioBalance, vFolioBalance), vFolioObj.FolioCurrency);
													EndIf;
												EndIf;
											Else
												If Not cmCheckUserPermissions("HavePermissionToCheckOutAccommodationsWithClientDebts") Then
													vFolioBalance = vFolioObj.pmGetBalance(, vFolioObj.Hotel);
													If vFolioBalance <> 0 Then
														Raise NStr("en='You do not have rights to close individuals folio with non zero balance! '; ru='Нет прав закрывать лицевой счет физ. лица с не нулевым балансом! '; de='Sie haben nicht das Recht, ein persönliches Konto mit Bilanz ungleich Null zu schließen! '") + 
														      NStr("en='Folio N'; ru='Фолио №'; de='Folio Nr.'") + TrimAll(vFolioObj.Number) + ?(vFolioBalance > 0, NStr("en=' - debt is '; ru=' - долг '; de=' - Schulden '"), NStr("en=' - advance is '; ru=' - предоплата '; de=' - Vorauszahlung '")) + cmFormatSum(?(vFolioBalance < 0, -vFolioBalance, vFolioBalance), vFolioObj.FolioCurrency);
													EndIf;
												EndIf;
											EndIf;
										EndIf;
									EndIf;
								EndIf;
							EndIf;
							// Do close
							vFolioObj.Read();
							vFolioObj.DeletionMark = False;
							vFolioObj.IsClosed = True;
							vFolioObj.AdditionalProperties.Insert("SkipCheckOfAnaliticalParametersChange", True);
							vFolioObj.Write(DocumentWriteMode.Write);
						EndIf;
					Else
						// Open folio
						If vFolioDocs.Count() > 0 Then
							vFolioObj = vFolioRef.GetObject();
							vFolioObj.Read();
							vFolioObj.DeletionMark = False;
							vFolioObj.IsClosed = False;
							vFolioObj.AdditionalProperties.Insert("SkipCheckOfAnaliticalParametersChange", True);
							vFolioObj.Write(DocumentWriteMode.Write);
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	Else
		// Open all folios of the current document
		vFolios = cmGetInactiveDocumentFolios(Ref);
		For Each vFoliosRow In vFolios Do
			If ValueIsFilled(vFoliosRow.Folio) Then
				vFolioRef = vFoliosRow.Folio;
				// Check should we change folio status at all
				If ValueIsFilled(AccommodationType) And AccommodationType.PostToRoomMainFolio And 
				   ValueIsFilled(vFolioRef.ParentDoc) And vFolioRef.ParentDoc <> Ref Then
					Continue;
				EndIf;
				If vFolioRef.IsClosed Then
					vFolioObj = vFolioRef.GetObject();
					vFolioObj.Read();
					vFolioObj.DeletionMark = False;
					vFolioObj.IsClosed = False;
					vFolioObj.AdditionalProperties.Insert("SkipCheckOfAnaliticalParametersChange", True);
					vFolioObj.Write(DocumentWriteMode.Write);
				EndIf;
			EndIf;
		EndDo;
		// Check should we open guest group folios or not
		If ValueIsFilled(GuestGroup) And GuestGroup.ChargingRules.Count() > 0 Then
			For Each vGGCRRow In GuestGroup.ChargingRules Do
				If ValueIsFilled(vGGCRRow.ChargingFolio) And vGGCRRow.ChargingFolio.IsClosed Then
					vFolioObj = vGGCRRow.ChargingFolio.GetObject();
					vFolioObj.Read();
					vFolioObj.DeletionMark = False;
					vFolioObj.IsClosed = False;
					vFolioObj.AdditionalProperties.Insert("SkipCheckOfAnaliticalParametersChange", True);
					vFolioObj.Write(DocumentWriteMode.Write);
				EndIf;
			EndDo;
		EndIf;
	EndIf;
EndProcedure // SetFolioStatuses

// -----------------------------------------------------------------------------
Procedure DoChangeRoomStatus(pRoomStatus, pRoom)
	If Not ValueIsFilled(pRoom) Then
		Return;
	EndIf;
	
	// Update status for room
	If pRoom.RoomStatus <> pRoomStatus Then
		vRoomObj = pRoom.GetObject();
		vRoomObj.Read();
		vRoomObj.RoomStatus = pRoomStatus;
		vRoomObj.Write();
		
		// Add record to the room status change history
		vRoomObj.pmWriteToRoomStatusChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser, TrimAll(ReservationStatus) + " - " + TrimAll(Guest) + " - " + String(Ref));
	EndIf;
EndProcedure //  DoChangeRoomStatus

// -----------------------------------------------------------------------------
Procedure MoveGuests(pCancel, pPostingMode)
	If ValueIsFilled(Guest) Then
		vDoWrite = False;
		vGuestObj = Undefined;
		If ValueIsFilled(ReservationStatus) Then
			If ReservationStatus.IsActive Then
				If Guest.Parent <> Catalogs.Clients.ReservedGuests And 
				   Guest.Parent <> Catalogs.Clients.BlackListPersons And
				   Guest.Parent <> Catalogs.Clients.CheckedInGuests Then
					vGuestObj = Guest.GetObject();
					vGuestObj.Read();
					vGuestObj.Parent = Catalogs.Clients.ReservedGuests;
					vDoWrite = True;
				EndIf;
			EndIf;
		EndIf;
		If Not IsBlankString(Phone) And IsBlankString(Guest.Phone) Then
			If Not vDoWrite Then
				vGuestObj = Guest.GetObject();
				vGuestObj.Read();
			EndIf;
			vGuestObj.Phone = TrimAll(Phone);
			vDoWrite = True;
		EndIf;
		If Not IsBlankString(Fax) And IsBlankString(Guest.Fax) Then
			If Not vDoWrite Then
				vGuestObj = Guest.GetObject();
				vGuestObj.Read();
			EndIf;
			vGuestObj.Fax = TrimAll(Fax);
			vDoWrite = True;
		EndIf;
		If Not IsBlankString(EMail) And IsBlankString(Guest.EMail) Then
			If Not vDoWrite Then
				vGuestObj = Guest.GetObject();
				vGuestObj.Read();
			EndIf;
			vGuestObj.EMail = TrimAll(EMail);
			vDoWrite = True;
		EndIf;
		If vDoWrite Then
			vGuestObj.Write();
			vGuestObj.pmWriteToClientChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
		EndIf;
	EndIf;
EndProcedure //  MoveGuests

// -----------------------------------------------------------------------------
Procedure SetReservedStatusForSpareRooms()
	If Rooms.Count() > 0 Then
		// Calculate initial number of rooms to reserve
		vRoomsReserved = ?(NumberOfBedsPerRoom > 0, NumberOfBeds/NumberOfBedsPerRoom, 0);
		If vRoomsReserved > 0 Then
			If Int(vRoomsReserved) <> vRoomsReserved Then
				vRoomsReserved = Int(vRoomsReserved) + 1;
			EndIf;
			If Rooms.Count() > vRoomsReserved Then
				// There are spare rooms
				i = Rooms.Count();
				While i > vRoomsReserved And i > 0 Do
					vRoom = Rooms.Get(i - 1).Room;
					If ValueIsFilled(vRoom) Then
						If vRoom.RoomStatus <> Hotel.ReservedRoomStatus And 
						  (vRoom.RoomStatus = Hotel.VacantRoomStatus Or 
						   ValueIsFilled(vRoom.RoomStatus) And vRoom.RoomStatus.RoomIsVacantClear) Then
							If RoomsWithReservedStatus.FindByValue(vRoom) = Undefined Then
								RoomsWithReservedStatus.Add(vRoom);
								DoChangeRoomStatus(Hotel.ReservedRoomStatus, vRoom);
							EndIf;
						EndIf;
					EndIf;
					i = i - 1;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
EndProcedure //  SetReservedStatusForSpareRooms

// -----------------------------------------------------------------------------
Procedure ClearReservedStatusFromRooms()
	// Build list of rooms to process
	vRooms = New ValueList();
	If ValueIsFilled(Room) Then
		vRooms.Add(Room);
	EndIf;
	If Rooms.Count() > 0 Then
		For Each vRoomsRow In Rooms Do
			If ValueIsFilled(vRoomsRow.Room) Then
				If vRooms.FindByValue(vRoomsRow.Room) = Undefined Then
					vRooms.Add(vRoomsRow.Room);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	// Process rooms
	If vRooms.Count() > 0 Then
		For Each vRoomsItem In vRooms Do
			vRoom = vRoomsItem.Value;
			If vRoom.RoomStatus = Hotel.ReservedRoomStatus Then
				// Retrieve room's previous status
				vRoomObj = vRoom.GetObject();
				vRoomStates = vRoomObj.pmGetRoomStatusHistoryState(CurrentSessionDate(), vRoom.RoomStatus);
				If vRoomStates.Count() > 0 Then
					vRoomStatesRow = vRoomStates.Get(0);
					// If previous room status is occupied or is vacant then check if there any in-house guests in the room
					If vRoomStatesRow.RoomStatus = Hotel.OccupiedRoomStatus Then
						vInHouseGuests = vRoomObj.pmGetInHouseGuests();
						If vInHouseGuests.Count() > 0 Then
							DoChangeRoomStatus(vRoomStatesRow.RoomStatus, vRoom);
						Else
							// Set room status to the room status after check-out
							DoChangeRoomStatus(Hotel.RoomStatusAfterCheckOut, vRoom);
						EndIf;
					ElsIf (vRoomStatesRow.RoomStatus = Hotel.VacantRoomStatus Or 
						   ValueIsFilled(vRoomStatesRow.RoomStatus) And vRoomStatesRow.RoomStatus.RoomIsVacantClear) Then
						vInHouseGuests = vRoomObj.pmGetInHouseGuests();
						If vInHouseGuests.Count() = 0 Then
							DoChangeRoomStatus(vRoomStatesRow.RoomStatus, vRoom);
						Else
							// Set room status to the occupied
							DoChangeRoomStatus(Hotel.OccupiedRoomStatus, vRoom);
						EndIf;
					Else
						DoChangeRoomStatus(vRoomStatesRow.RoomStatus, vRoom);
					EndIf;
				Else
					// Set room status to the vacant room status
					DoChangeRoomStatus(Hotel.VacantRoomStatus, vRoom);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
EndProcedure //  ClearReservedStatusFromRooms

// -----------------------------------------------------------------------------
Procedure ClearReservedStatusFromOldRooms()
	// Build list of current rooms
	vNewRooms = New ValueList();
	If ValueIsFilled(Room) Then
		vNewRooms.Add(Room);
	Else
		If Rooms.Count() > 0 Then
			For Each vRoomsRow In Rooms Do
				If ValueIsFilled(vRoomsRow.Room) Then
					If vNewRooms.FindByValue(vRoomsRow.Room) = Undefined Then
						vNewRooms.Add(vRoomsRow.Room);
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	// Retrieve document previous state
	vPrevResStates = pmGetReservationHistoryState(CurrentSessionDate());
	If vPrevResStates.Count() > 0 Then
		vPrevResStatesRow = vPrevResStates.Get(0);
		// Get rooms that were in the previous document state but not in the current document state
		vPrevRooms = New ValueList();
		If ValueIsFilled(vPrevResStatesRow.Room) Then
			If vNewRooms.FindByValue(vPrevResStatesRow.Room) = Undefined Then
				vPrevRooms.Add(vPrevResStatesRow.Room);
			EndIf;
		EndIf;
		vPrevRoomsTab = vPrevResStatesRow.Rooms.Get();
		If vPrevRoomsTab <> Undefined Then
			If vPrevRoomsTab.Count() > 0 Then
				For Each vPrevRoomsTabRow In vPrevRoomsTab Do
					If ValueIsFilled(vPrevRoomsTabRow.Room) Then
						If vNewRooms.FindByValue(vPrevRoomsTabRow.Room) = Undefined Then
							If vPrevRooms.FindByValue(vPrevRoomsTabRow.Room) = Undefined Then
								vPrevRooms.Add(vPrevRoomsTabRow.Room);
							EndIf;
						EndIf;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		// Process previous rooms
		If vPrevRooms.Count() > 0 Then
			For Each vPrevRoomsItem In vPrevRooms Do
				vRoom = vPrevRoomsItem.Value;
				If vRoom.RoomStatus = Hotel.ReservedRoomStatus Then
					// Retrieve room's previous status
					vRoomObj = vRoom.GetObject();
					vRoomStates = vRoomObj.pmGetRoomStatusHistoryState(CurrentSessionDate(), vRoom.RoomStatus);
					If vRoomStates.Count() > 0 Then
						vRoomStatesRow = vRoomStates.Get(0);
						// If previous room status is occupied or is vacant then check if there any in-house guests in the room
						If vRoomStatesRow.RoomStatus = Hotel.OccupiedRoomStatus Then
							vInHouseGuests = vRoomObj.pmGetInHouseGuests();
							If vInHouseGuests.Count() > 0 Then
								DoChangeRoomStatus(vRoomStatesRow.RoomStatus, vRoom);
							Else
								// Set room status to the room status after check-out
								DoChangeRoomStatus(Hotel.RoomStatusAfterCheckOut, vRoom);
							EndIf;
						ElsIf vRoomStatesRow.RoomStatus = Hotel.VacantRoomStatus Or 
						      ValueIsFilled(vRoomStatesRow.RoomStatus) And vRoomStatesRow.RoomStatus.RoomIsVacantClear Then
							vInHouseGuests = vRoomObj.pmGetInHouseGuests();
							If vInHouseGuests.Count() = 0 Then
								DoChangeRoomStatus(vRoomStatesRow.RoomStatus, vRoom);
							Else
								// Set room status to the occupied
								DoChangeRoomStatus(Hotel.OccupiedRoomStatus, vRoom);
							EndIf;
						Else
							DoChangeRoomStatus(vRoomStatesRow.RoomStatus, vRoom);
						EndIf;
					Else
						// Set room status to the vacant room status
						DoChangeRoomStatus(Hotel.VacantRoomStatus, vRoom);
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
EndProcedure //  ClearReservedStatusFromOldRooms

// -----------------------------------------------------------------------------
Procedure FillGroupParameters()
	If ValueIsFilled(GuestGroup) Then
		// Reservation manager
		vUpdateReservationManager = False;
		If Not ValueIsFilled(GuestGroup.ReservationManager) And 
		   ValueIsFilled(ReservationStatus) And (ReservationStatus.IsActive And 
		   Not ReservationStatus.IsCheckIn) Then
			vUpdateReservationManager = True;
		EndIf;
		// Client document
		vUpdateClientDoc = False;
		If Not ValueIsFilled(GuestGroup.ClientDoc) Or 
		   ValueIsFilled(GuestGroup.ClientDoc) And TypeOf(GuestGroup.ClientDoc) <> Type("DocumentRef.Accommodation") And 
		   GuestGroup.FixedClient And ValueIsFilled(GuestGroup.Client) And GuestGroup.Client = Guest Then
			vUpdateClientDoc = True;
		EndIf;
		// Client
		vUpdateClient = False;
		If ValueIsFilled(Guest) And Not GuestGroup.FixedClient Then
			If Not ValueIsFilled(GuestGroup.Client) Or 
			   IsMaster And GuestGroup.Client <> Guest Or 
			   ValueIsFilled(GuestGroup.ClientDoc) And GuestGroup.ClientDoc = Ref And GuestGroup.Client <> Guest Then
				vUpdateClient = True;
			EndIf;
		EndIf;
		// Customer
		vUpdateCustomer = False;
		vUpdateContract = False;
		If GuestGroup.OneCustomerPerGuestGroup Then
			If GuestGroup.Customer <> Customer Then
				If Not IsForFolioSplit Or 
				   IsForFolioSplit And (Ref = GuestGroup.ClientDoc Or vUpdateClientDoc Or vUpdateClient) Then
					vUpdateCustomer = True;
				EndIf;
			EndIf;
			If GuestGroup.Contract <> Contract Then
				If Not IsForFolioSplit Or 
				   IsForFolioSplit And (Ref = GuestGroup.ClientDoc Or vUpdateClientDoc Or vUpdateClient) Then
					vUpdateContract = True;
				EndIf;
			EndIf;
		EndIf;
		// Agent
		vUpdateAgent = False;
		If GuestGroup.OneCustomerPerGuestGroup Then
			If GuestGroup.Agent <> Agent Then
				vUpdateAgent = True;
			EndIf;
		EndIf;
		// Group period and number of guests checked-in
		vUpdatePeriod = False;
		vUpdateGuestsCheckedIn = False;
		vGroupParams = cmGetGroupPeriodAndGuestsCheckedIn(GuestGroup);
		If vGroupParams.Count() > 0 Then
			vGroupParamsRow = vGroupParams.Get(0);
			If vGroupParamsRow.CheckInDate <> GuestGroup.CheckInDate Or
			   vGroupParamsRow.CheckOutDate <> GuestGroup.CheckOutDate Then
				vUpdatePeriod = True;
			EndIf;
			If vGroupParamsRow.GuestsCheckedIn <> GuestGroup.GuestsCheckedIn Or 
			   vGroupParamsRow.NumberOfAdults <> GuestGroup.NumberOfAdults Or 
			   vGroupParamsRow.NumberOfTeenagers <> GuestGroup.NumberOfTeenagers Or 
			   vGroupParamsRow.NumberOfChildren <> GuestGroup.NumberOfChildren Or 
			   vGroupParamsRow.NumberOfInfants <> GuestGroup.NumberOfInfants Then
				vUpdateGuestsCheckedIn = True;
			EndIf;
		EndIf;
		// Group check date
		vCheckDate = '00010101';
		vUpdateCheckDate = False;
		If Not ValueIsFilled(GuestGroup.CheckDate) Then
			If ValueIsFilled(Contract) And (Contract.DaysBeforeCheckIn <> 0 Or Contract.DaysAfterReservation <> 0) Then
				vUpdateCheckDate = True;
				If Contract.DaysBeforeCheckIn <> 0 And ValueIsFilled(CheckInDate) Then
					vCheckDate = BegOfDay(CheckInDate) - 24*3600*Contract.DaysBeforeCheckIn;
				ElsIf Contract.DaysAfterReservation <> 0 And ValueIsFilled(Date) Then
					vCheckDate = cmAddWorkingDays(BegOfDay(Date), (Contract.DaysAfterReservation + 1));
				EndIf;
			ElsIf ValueIsFilled(Customer) And (Customer.DaysBeforeCheckIn <> 0 Or Customer.DaysAfterReservation <> 0) Then
				vUpdateCheckDate = True;
				If Customer.DaysBeforeCheckIn <> 0 And ValueIsFilled(CheckInDate) Then
					vCheckDate = BegOfDay(CheckInDate) - 24*3600*Customer.DaysBeforeCheckIn;
				ElsIf Customer.DaysAfterReservation <> 0 And ValueIsFilled(Date) Then
					vCheckDate = cmAddWorkingDays(BegOfDay(Date), (Customer.DaysAfterReservation + 1));
				EndIf;
			ElsIf ValueIsFilled(Hotel) And (Hotel.DaysBeforeCheckIn <> 0 Or Hotel.DaysAfterReservation <> 0) Then
				vUpdateCheckDate = True;
				If Hotel.DaysBeforeCheckIn <> 0 And ValueIsFilled(CheckInDate) Then
					vCheckDate = BegOfDay(CheckInDate) - 24*3600*Hotel.DaysBeforeCheckIn;
				ElsIf Hotel.DaysAfterReservation <> 0 And ValueIsFilled(Date) Then
					vCheckDate = cmAddWorkingDays(BegOfDay(Date), (Hotel.DaysAfterReservation + 1));
				EndIf;
			EndIf;
		EndIf;
		// Group status
		vUpdateGroupStatus = False;
		vCurGuestGroupStatus = GuestGroup.Status;
		If Not ValueIsFilled(vCurGuestGroupStatus) Or 
		   ValueIsFilled(vCurGuestGroupStatus) And 
		   (TypeOf(vCurGuestGroupStatus) <> Type("CatalogRef.ReservationStatuses") Or 
		    TypeOf(vCurGuestGroupStatus) = Type("CatalogRef.ReservationStatuses") And Not vCurGuestGroupStatus.DoNotCreateReservationsInBlock) Then
			vGuestGroupStatus = cmGetGuestGroupStatus(GuestGroup);
			If vCurGuestGroupStatus <> vGuestGroupStatus Then
				vUpdateGroupStatus = True;
			EndIf;
		EndIf;
		// Update guest group params
		If vUpdateReservationManager Or vUpdateCustomer Or vUpdateContract Or vUpdateAgent Or vUpdateClient Or vUpdateClientDoc Or vUpdatePeriod Or vUpdateGuestsCheckedIn Or vUpdateGroupStatus Then
			vGroupObj = GuestGroup.GetObject();
			vGroupObj.Read();
			If vUpdateReservationManager Then
				vGroupObj.ReservationManager = SessionParameters.CurrentUser;
			EndIf;
			If vUpdateCustomer Then
				vGroupObj.Customer = Customer;
			EndIf;
			If vUpdateContract Then
				vGroupObj.Contract = Contract;
			EndIf;
			If vUpdateAgent Then
				vGroupObj.Agent = Agent;
			EndIf;
			If vUpdateClient Then
				vGroupObj.Client = Guest;
				vGroupObj.ClientDoc = Ref;
			ElsIf vUpdateClientDoc Then
				vGroupObj.ClientDoc = Ref;
			EndIf;
			If vUpdatePeriod Then
				vGroupObj.CheckInDate = vGroupParamsRow.CheckInDate;
				vGroupObj.CheckOutDate = vGroupParamsRow.CheckOutDate;
				vGroupObj.Duration = cmCalculateDuration(RoomRate, vGroupObj.CheckInDate, vGroupObj.CheckOutDate);
			EndIf;
			If vUpdateGuestsCheckedIn Then
				vGroupObj.GuestsCheckedIn = vGroupParamsRow.GuestsCheckedIn;
				vGroupObj.NumberOfAdults = vGroupParamsRow.NumberOfAdults;
				vGroupObj.NumberOfTeenagers = vGroupParamsRow.NumberOfTeenagers;
				vGroupObj.NumberOfChildren = vGroupParamsRow.NumberOfChildren;
				vGroupObj.NumberOfInfants = vGroupParamsRow.NumberOfInfants;
			EndIf;
			If vUpdateCheckDate And ValueIsFilled(vCheckDate) Then
				vGroupObj.CheckDate = vCheckDate;
			EndIf;
			If vUpdateGroupStatus Then
				vGroupObj.Status = vGuestGroupStatus;
			EndIf;
			vGroupObj.Write();
		EndIf;
	EndIf;
EndProcedure //  FillGroupParameters

// -----------------------------------------------------------------------------
Procedure pmUpdateCheckInSchedule()
	If ValueIsFilled(ParentDoc) And TypeOf(ParentDoc) = Type("DocumentRef.Reservation") And 
	   ValueIsFilled(ReservationStatus) And Not ReservationStatus.IsCheckIn And Not ReservationStatus.IsArrivalSchedule And 
	   ParentDoc.GuestGroup <> GuestGroup And ValueIsFilled(ParentDoc.ReservationStatus) And ParentDoc.ReservationStatus.IsArrivalSchedule Then
		If ReservationStatus.IsActive Then
			// Try to find active schedule period if base one was deleted
			If RoomType <> ParentDoc.RoomType Then
				// Restore initial schedule period if there is no other active main bed reservation based on the same parent
				If Not ParentDoc.Posted Then
					If Not GetActiveDocByParentDoc(ParentDoc, Ref) Then
						vSchDocObj = ParentDoc.GetObject();
						vSchDocObj.DeletionMark = False;
						If vSchDocObj.AccommodationType.Type <> Enums.AccomodationTypes.Beds Then
							vSchDocObj.AccommodationType = cmGetAccommodationTypeBed(Hotel);
						EndIf;
						vSchDocObj.Write(DocumentWriteMode.Posting);
						vSchDocObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
					EndIf;
				EndIf;
				// Unbind this reservation from schedule
				ParentDoc = Undefined;
			ElsIf ValueIsFilled(AccommodationType) And AccommodationType.Type = Enums.AccomodationTypes.AdditionalBed Then
				// Restore initial schedule period if there is no other active main bed reservation based on the same parent
				If Not ParentDoc.Posted Then
					If Not GetActiveDocByParentDoc(ParentDoc, Ref) Then
						vSchDocObj = ParentDoc.GetObject();
						vSchDocObj.DeletionMark = False;
						If vSchDocObj.AccommodationType.Type <> Enums.AccomodationTypes.Beds Then
							vSchDocObj.AccommodationType = cmGetAccommodationTypeBed(Hotel);
						EndIf;
						vSchDocObj.Write(DocumentWriteMode.Posting);
						vSchDocObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
					EndIf;
				EndIf;
			Else
				// Check if there is other active reservation with accommodation type room or bed referencing same ParentDoc
				// If yes then try to change current ParentDoc to the new vacant one
				If GetActiveDocByParentDoc(ParentDoc, Ref) Then
					vNewParentDoc = GetNewActiveScheduleDocument(ParentDoc);
					If ValueIsFilled(vNewParentDoc) And vNewParentDoc <> ParentDoc Then
						ParentDoc = vNewParentDoc;
					EndIf;
				EndIf;
				If ValueIsFilled(ParentDoc) And ParentDoc.Posted Then
					// Change parent doc accommodation type to bed if it is not
					vSchDocObj = ParentDoc.GetObject();
					If vSchDocObj.AccommodationType.Type <> Enums.AccomodationTypes.Beds Then
						vSchDocObj.AccommodationType = cmGetAccommodationTypeBed(Hotel);
						vSchDocObj.Write(DocumentWriteMode.Write);
					EndIf;
					vSchDocObj.SetDeletionMark(True);
					vSchDocObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				EndIf;
			EndIf;
		Else
			// Restore initial schedule period if there is no other active main bed reservation based on the same parent
			If Not ParentDoc.Posted Then
				If Not GetActiveDocByParentDoc(ParentDoc, Ref) Then
					vSchDocObj = ParentDoc.GetObject();
					vSchDocObj.DeletionMark = False;
					If vSchDocObj.AccommodationType.Type <> Enums.AccomodationTypes.Beds Then
						vSchDocObj.AccommodationType = cmGetAccommodationTypeBed(Hotel);
					EndIf;
					vSchDocObj.Write(DocumentWriteMode.Posting);
					vSchDocObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // pmUpdateCheckInSchedule

// -----------------------------------------------------------------------------
Function GetActiveDocByParentDoc(pParentDoc, pThisDoc)
	vDoc = Undefined;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reservations.Ref AS Ref
	|FROM
	|	Document.Reservation AS Reservations
	|WHERE
	|	Reservations.ParentDoc = &qParentDoc
	|	AND Reservations.RoomType = &qParentDocRoomType
	|	AND Reservations.Ref <> &qThisDoc
	|	AND Reservations.AccommodationType.Type <> VALUE(Enum.AccomodationTypes.AdditionalBed)
	|	AND (Reservations.ReservationStatus.IsActive
	|			OR Reservations.ReservationStatus.IsPreliminary
	|			OR Reservations.ReservationStatus.IsCheckIn)
	|	AND NOT Reservations.ReservationStatus.IsArrivalSchedule
	|	AND Reservations.Posted
	|
	|ORDER BY
	|	Reservations.PointInTime";
	vQry.SetParameter("qParentDoc", pParentDoc);
	vQry.SetParameter("qParentDocRoomType", pParentDoc.RoomType);
	vQry.SetParameter("qThisDoc", pThisDoc);
	vDocs = vQry.Execute().Unload();
	For Each vDocsRow In vDocs Do
		vDoc = vDocsRow.Ref;
		Break;
	EndDo;
	Return ValueIsFilled(vDoc);
EndFunction // GetActiveDocByParentDoc

// -----------------------------------------------------------------------------
Function GetNewActiveScheduleDocument(pParentDoc)
	vDoc = Undefined;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reservations.Ref AS Ref
	|FROM
	|	Document.Reservation AS Reservations
	|WHERE
	|	Reservations.RoomType = &qParentDocRoomType
	|	AND Reservations.ReservationStatus.IsArrivalSchedule
	|	AND Reservations.Ref <> &qParentDoc
	|	AND (&qParentDocStatus = UNDEFINED OR Reservations.ReservationStatus = &qParentDocStatus)
	|	AND Reservations.CheckInDate BETWEEN &qParentDocCheckInDateStart AND &qParentDocCheckInDateEnd
	|	AND Reservations.CheckOutDate BETWEEN &qParentDocCheckOutDateStart AND &qParentDocCheckOutDateEnd
	|	AND Reservations.AccommodationType.Type <> VALUE(Enum.AccomodationTypes.AdditionalBed)
	|	AND (Reservations.ReservationStatus.IsActive
	|			OR Reservations.ReservationStatus.IsPreliminary
	|			OR Reservations.ReservationStatus.IsCheckIn)
	|	AND Reservations.Posted
	|
	|ORDER BY
	|	Reservations.PointInTime";
	vQry.SetParameter("qParentDoc", pParentDoc);
	vQry.SetParameter("qParentDocRoomType", pParentDoc.RoomType);
	vQry.SetParameter("qParentDocCheckInDateStart", BegOfDay(pParentDoc.CheckInDate));
	vQry.SetParameter("qParentDocCheckInDateEnd", EndOfDay(pParentDoc.CheckInDate));
	vQry.SetParameter("qParentDocCheckOutDateStart", BegOfDay(pParentDoc.CheckOutDate));
	vQry.SetParameter("qParentDocCheckOutDateEnd", EndOfDay(pParentDoc.CheckOutDate));
	vQry.SetParameter("qParentDocStatus", ?(TypeOf(pParentDoc) = Type("DocumentRef.Reservation"), pParentDoc.ReservationStatus, Undefined));
	vDocs = vQry.Execute().Unload();
	For Each vDocsRow In vDocs Do
		vDoc = vDocsRow.Ref;
		Break;
	EndDo;
	Return vDoc;
EndFunction // GetNewActiveScheduleDocument

// -----------------------------------------------------------------------------
Procedure ClearInventoryRecordsForIntersectedDocs(pIntersectedDocs)
	For Each vIntersectedDocsRow In pIntersectedDocs Do
		If Not vIntersectedDocsRow.Cleared Then
			vDocObj = vIntersectedDocsRow.Ref.GetObject();
			vDocObj.pmClearInventoryRegisterRecords();
			vIntersectedDocsRow.DocObj = vDocObj;
			vIntersectedDocsRow.Reposted = False;
			vIntersectedDocsRow.Cleared = True;
		EndIf;
	EndDo;
EndProcedure // ClearInventoryRecordsForIntersectedDocs

// -----------------------------------------------------------------------------
Procedure RepostIntersectedDocs(pIntersectedDocs, pPeriodsRow, pMode = 0)
	For Each vIntersectedDocsRow In pIntersectedDocs Do
		vDocObj = vIntersectedDocsRow.DocObj;
		If vDocObj = Undefined Then
			vDocObj = vIntersectedDocsRow.Ref.GetObject();
		EndIf;
		// Build value table of accommodation periods
		vPeriods = vDocObj.pmGetAccommodationPeriods(True);
		// Process each accommodation period separately
		For Each vPeriodsRow In vPeriods Do
			If pMode = 1 And cm1SecondShift(vPeriodsRow.CheckInDate) > cm1SecondShift(pPeriodsRow.CheckInDate) Then
				Continue;
			ElsIf pMode = 2 And cm1SecondShift(vPeriodsRow.CheckInDate) <= cm1SecondShift(pPeriodsRow.CheckInDate) Then
				Continue;
			EndIf;
			vDocObj.pmPostToInventoryRegisters(vPeriods, vPeriodsRow, False);
			vIntersectedDocsRow.Reposted = True;
		EndDo;
	EndDo;
	If pMode <> 1 Then
		For Each vIntersectedDocsRow In pIntersectedDocs Do
			If Not vIntersectedDocsRow.Reposted Then
				vDocObj = vIntersectedDocsRow.DocObj;
				If vDocObj = Undefined Then
					vDocObj = vIntersectedDocsRow.Ref.GetObject();
				EndIf;
				// Build value table of accommodation periods
				vPeriods = vDocObj.pmGetAccommodationPeriods(True);
				// Process each accommodation period separately
				For Each vPeriodsRow In vPeriods Do
					vDocObj.pmPostToInventoryRegisters(vPeriods, vPeriodsRow, False);
				EndDo;
				vIntersectedDocsRow.Reposted = True;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // RepostIntersectedDocs

// -----------------------------------------------------------------------------
Procedure FillPeriodsRowWithDefaultValues(pPeriodsRow)
	pPeriodsRow.Ref = Ref;
	pPeriodsRow.Hotel = Hotel;
	pPeriodsRow.RoomQuota = RoomQuota;
	pPeriodsRow.CheckInDate = CheckInDate;
	pPeriodsRow.CheckOutDate = CheckOutDate;
	pPeriodsRow.RoomType = RoomType;
	pPeriodsRow.Room = Room;
	pPeriodsRow.AccommodationType = AccommodationType;
	pPeriodsRow.AccommodationTemplate = AccommodationTemplate;
	pPeriodsRow.RoomRate = RoomRate;
	pPeriodsRow.ServicePackage = ?(ValueIsFilled(ServicePackage) And ServicePackage.IsMealBoardTerm, ServicePackage, Catalogs.ServicePackages.EmptyRef());
	pPeriodsRow.NumberOfBedsPerRoom = NumberOfBedsPerRoom;
	pPeriodsRow.NumberOfPersonsPerRoom = NumberOfPersonsPerRoom;
	pPeriodsRow.NumberOfPersons = NumberOfPersons;
	pPeriodsRow.NumberOfRooms = NumberOfRooms;
	pPeriodsRow.NumberOfBeds = NumberOfBeds;
	pPeriodsRow.NumberOfAdditionalBeds = NumberOfAdditionalBeds;
	pPeriodsRow.AccountingDate = BegOfDay(CheckInDate);
EndProcedure //  FillPeriodsRowWithDefaultValues

// -----------------------------------------------------------------------------
Procedure UpdatePeriodsRow(pPeriods, pPeriodsRow, pRRRow)
	vPrevPeriodsRow = pPeriodsRow;
	vPeriodsRowIndex = pPeriods.IndexOf(pPeriodsRow);
	If vPeriodsRowIndex > 0 Then
		vPrevPeriodsRow = pPeriods.Get(vPeriodsRowIndex - 1);
	EndIf;
	If ValueIsFilled(pRRRow.RoomType) And pRRRow.RoomType <> vPrevPeriodsRow.RoomType Or
	   ValueIsFilled(pRRRow.Room) And pRRRow.Room <> vPrevPeriodsRow.Room Or
	   ValueIsFilled(pRRRow.AccommodationTemplate) And pRRRow.AccommodationTemplate <> vPrevPeriodsRow.AccommodationTemplate Or
	   ValueIsFilled(pRRRow.AccommodationType) And pRRRow.AccommodationType <> vPrevPeriodsRow.AccommodationType Or
	   ValueIsFilled(pRRRow.RoomRate) And pRRRow.RoomRate <> vPrevPeriodsRow.RoomRate Or 
	   ValueIsFilled(pRRRow.ServicePackage) And pRRRow.ServicePackage.IsMealBoardTerm And pRRRow.ServicePackage <> vPrevPeriodsRow.ServicePackage Or
	   pRRRow.DoNotChangeAvailability <> vPrevPeriodsRow.DoNotChangeAvailability Then
		If ValueIsFilled(pRRRow.RoomType) Then
			pPeriodsRow.RoomType = pRRRow.RoomType;
		Else
			pPeriodsRow.RoomType = vPrevPeriodsRow.RoomType;
		EndIf;
		If ValueIsFilled(pRRRow.Room) Then
			pPeriodsRow.Room = pRRRow.Room;
		Else
			If ValueIsFilled(pRRRow.RoomType) Then
				pPeriodsRow.Room = pRRRow.Room;
				pPeriodsRow.RoomType = pRRRow.RoomType;
			Else
				pPeriodsRow.Room = vPrevPeriodsRow.Room;
				pPeriodsRow.RoomType = vPrevPeriodsRow.RoomType;
			EndIf;
		EndIf;
		If ValueIsFilled(pRRRow.AccommodationType) Then
			pPeriodsRow.AccommodationType = pRRRow.AccommodationType;
		Else
			pPeriodsRow.AccommodationType = vPrevPeriodsRow.AccommodationType;
		EndIf;
		If ValueIsFilled(pRRRow.AccommodationTemplate) Then
			pPeriodsRow.AccommodationTemplate = pRRRow.AccommodationTemplate;
		Else
			pPeriodsRow.AccommodationTemplate = vPrevPeriodsRow.AccommodationTemplate;
		EndIf;
		If ValueIsFilled(pRRRow.RoomRate) Then
			pPeriodsRow.RoomRate = pRRRow.RoomRate;
		Else
			pPeriodsRow.RoomRate = vPrevPeriodsRow.RoomRate;
		EndIf;
		If ValueIsFilled(pRRRow.ServicePackage) And pRRRow.ServicePackage.IsMealBoardTerm Then
			pPeriodsRow.ServicePackage = pRRRow.ServicePackage;
		Else
			pPeriodsRow.ServicePackage = vPrevPeriodsRow.ServicePackage;
		EndIf;
		If pRRRow.DoNotChangeAvailability <> vPrevPeriodsRow.DoNotChangeAvailability Then
			pPeriodsRow.DoNotChangeAvailability = pRRRow.DoNotChangeAvailability;
		EndIf;
		// Retrieve room resources
		If ValueIsFilled(pPeriodsRow.Room) Then
			vRoomObj = pPeriodsRow.Room.GetObject();
			vRoomAttr = vRoomObj.pmGetRoomAttributes(cm1SecondShift(pPeriodsRow.CheckInDate));
			For Each vRoomAttrRow In vRoomAttr Do
				pPeriodsRow.NumberOfBedsPerRoom = vRoomAttrRow.NumberOfBedsPerRoom;
				pPeriodsRow.NumberOfPersonsPerRoom = vRoomAttrRow.NumberOfPersonsPerRoom;
				pPeriodsRow.RoomType = vRoomAttrRow.RoomType;
				Break;
			EndDo;
		ElsIf ValueIsFilled(pPeriodsRow.RoomType) Then
			pPeriodsRow.NumberOfBedsPerRoom = pPeriodsRow.RoomType.NumberOfBedsPerRoom;
			pPeriodsRow.NumberOfPersonsPerRoom = pPeriodsRow.RoomType.NumberOfPersonsPerRoom;
		EndIf;
		// Calculate resources
		cmCalculateResources(pPeriodsRow.CheckInDate, pPeriodsRow.RoomType, pPeriodsRow.AccommodationType,
							 pPeriodsRow.Room, 1, pPeriodsRow.NumberOfRooms,
							 pPeriodsRow.NumberOfBeds, pPeriodsRow.NumberOfAdditionalBeds, pPeriodsRow.NumberOfPersons, 
							 pPeriodsRow.NumberOfBedsPerRoom, pPeriodsRow.NumberOfPersonsPerRoom);
		If pPeriodsRow.DoNotChangeAvailability Then
			pPeriodsRow.NumberOfRooms = 0;
			pPeriodsRow.NumberOfBeds = 0;
			pPeriodsRow.NumberOfAdditionalBeds = 0;
		EndIf;
	EndIf;
	// Update accounting date
	pPeriodsRow.AccountingDate = BegOfDay(pPeriodsRow.CheckinDate);
EndProcedure //  UpdatePeriodsRow

// -----------------------------------------------------------------------------
Procedure AddDataLocks(pPeriodsRow)
	// Add data locks
	vDataLock = New DataLock();
	// Room inventory
	vRIItem = vDataLock.Add("AccumulationRegister.RoomInventory");
	vRIItem.Mode = DataLockMode.Exclusive;
	vRIItem.SetValue("RoomType", pPeriodsRow.RoomType);
	// Lock room
	If ValueIsFilled(pPeriodsRow.Room) Then
		vRIItem.SetValue("Room", pPeriodsRow.Room);
	EndIf;
	vRIItem.SetValue("Period", New Range(cm1SecondShift(pPeriodsRow.CheckInDate), cm0SecondShift(pPeriodsRow.CheckOutDate)));
	// Room quota sales
	If ValueIsFilled(RoomQuota) Then
		vRQSItem = vDataLock.Add("AccumulationRegister.RoomQuotaSales");
		vRQSItem.Mode = DataLockMode.Exclusive;
		vRQSItem.SetValue("RoomQuota", pPeriodsRow.RoomQuota);
		vRQSItem.SetValue("RoomType", pPeriodsRow.RoomType);
		vRQSItem.SetValue("Period", New Range(cm1SecondShift(pPeriodsRow.CheckInDate), cm0SecondShift(pPeriodsRow.CheckOutDate)));
	EndIf;
	// Set all locks
	i = 0;
	While i < 2 Do
		Try
			vDataLock.Lock();
			Break;
		Except
			If i = 1 Then
				Raise String(Ref) + " - " + NStr("en='Failed to lock room inventory for update! Please retry later...';ru='Другие пользователи выполняют запись в базу данных! Повторите попытку позже...';de='Andere Nutzer führen bereits den Eintrag in die Datenbank aus! Wiederholen Sie den Versuch später…'");
			EndIf;
		EndTry;
		i = i + 1;
		// Wait for 10 seconds
		cmWait(10);
	EndDo;
EndProcedure //  AddDataLocks 

// -----------------------------------------------------------------------------
Procedure DoRoomInventoryPosting(pCancel)
	Var vMessage, vAttributeInErr;
	// Clear inventory registers
	pmClearInventoryRegisterRecords();
	// Build value table of accommodation periods
	vPeriods = pmGetAccommodationPeriods(False);
	// Check should we repost any intersecting accommodations or reservations
	For Each vPeriodsRow In vPeriods Do
		vIntersectedDocs = New ValueTable();
		If vPeriodsRow.NumberOfBeds <> 0 Then
			vIntersectedDocs = cmGetTableOfIntersectedDocs(vPeriodsRow);
		EndIf;
		// Clear room inventory movements for all intersected docs
		If vIntersectedDocs.Count() > 0 Then
			ClearInventoryRecordsForIntersectedDocs(vIntersectedDocs);
		EndIf;
		// Save intersected docs table
		vPeriodsRow.IntersectedDocs = vIntersectedDocs;
	EndDo;
	// Repost intersected documents prior to the current one 
	For Each vPeriodsRow In vPeriods Do
		If vPeriodsRow.IntersectedDocs.Count() > 0 Then
			RepostIntersectedDocs(vPeriodsRow.IntersectedDocs, vPeriodsRow, 1);
		EndIf;
	EndDo;
	// Build value table of accommodation periods taking new movements into account
	vAllPeriods = pmGetAccommodationPeriods(True);
	// Post to registers
	For Each vPeriodsRow In vAllPeriods Do
		// Add data locks
		AddDataLocks(vPeriodsRow);
		// Do posting
		pmPostToInventoryRegisters(vAllPeriods, vPeriodsRow, True, pCancel);
	EndDo;
	// Repost intersected documents after the current one 
	For Each vPeriodsRow In vPeriods Do
		If vPeriodsRow.IntersectedDocs.Count() > 0 And Not pCancel Then
			RepostIntersectedDocs(vPeriodsRow.IntersectedDocs, vPeriodsRow, 2);
		EndIf;
	EndDo;
	// Check room inventory and room quota vacant rooms
	For Each vPeriodsRow In vAllPeriods Do
		If Not pCancel Then
			pCancel	= pmCheckDocumentAttributes(vPeriodsRow, True, vMessage, vAttributeInErr);
			If pCancel Then
				WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
				tcCommonFunctionOnClientServer.UserMessage(NStr(vMessage));
				Raise String(Ref) + " - " + NStr(vMessage);
			EndIf;
		EndIf;
	EndDo;
	// Post to business block forecast sales
	If Not pCancel Then
		If ValueIsFilled(ReservationStatus) And ValueIsFilled(RoomQuota) Then
			If ReservationStatus.IsActive Or ReservationStatus.IsPreliminary Then
				If RoomQuota.AllotmentBusinessType = Enums.AllotmentBusinessTypes.BusinessBlock Then
					If RoomQuota.AllotmentType = Enums.AllotmentTypes.Definite Or 
					   RoomQuota.AllotmentType = Enums.AllotmentTypes.DefiniteNotGuaranteed Or
					   RoomQuota.AllotmentType = Enums.AllotmentTypes.Tentative Then
						PostToBusinessBlockForecastSales(vAllPeriods);
					EndIf;
				EndIf;
				// Process release period
				If Not ReservationStatus.IsCheckIn And RoomQuota.ReleaseTime <> 0 And ValueIsFilled(RoomRate) Then
					vCurAccountingDate = BegOfDay(CurrentSessionDate());
					If ValueIsFilled(Hotel.AccountingDate) Then
						vCurAccountingDate = Hotel.AccountingDate;
					EndIf;
					vPrevDocState = pmGetPreviousObjectState(CurrentSessionDate(), False);
					If vPrevDocState <> Undefined Then
						// Get object as it was before current state
						vPrevObject = Documents.Reservation.CreateDocument();
						vPrevObject.pmRestoreAttributesFromHistory(vPrevDocState);
						// Build value table of accommodation periods for the old object state
						vPrevPeriods = vPrevObject.pmGetAccommodationPeriods(True);
						For Each vPrevPeriodsRow In vPrevPeriods Do
							vRoomRate = vPrevPeriodsRow.RoomRate;
							If Not ValueIsFilled(vRoomRate) Then
								If ValueIsFilled(RoomQuota.RoomRate) Then
									vRoomRate = RoomQuota.RoomRate;
								Else
									vRoomRate = Hotel.RoomRate;
								EndIf;
							EndIf;
							If Not ValueIsFilled(vRoomRate) Then
								Break;
							EndIf;
							vReleasePeriodFrom = cm0SecondShift(cmInitializeDateTime(vCurAccountingDate, vRoomRate));
							vReleasePeriodTo = cm0SecondShift(cmInitializeDateTime(vCurAccountingDate + 24*3600*RoomQuota.ReleaseTime, vRoomRate));
							If vPrevPeriodsRow.CheckInDate < vReleasePeriodTo And vPrevPeriodsRow.CheckOutDate > vReleasePeriodFrom Then
								For Each vPeriodsRow In vAllPeriods Do
									If vPeriodsRow.CheckInDate < vReleasePeriodTo And vPeriodsRow.CheckOutDate > vReleasePeriodFrom Then
										If vPeriodsRow.RoomType <> vPrevPeriodsRow.RoomType Then
											If BegOfDay(vReleasePeriodFrom) < BegOfDay(vPrevPeriodsRow.CheckInDate) Then
												vReleasePeriodFrom = cm0SecondShift(cmInitializeDateTime(BegOfDay(vPrevPeriodsRow.CheckInDate), vRoomRate));
											EndIf;
											If BegOfDay(vReleasePeriodTo) > BegOfDay(vPrevPeriodsRow.CheckOutDate) Then
												vReleasePeriodTo = cm0SecondShift(cmInitializeDateTime(BegOfDay(vPrevPeriodsRow.CheckOutDate), vRoomRate));
											EndIf;
											If BegOfDay(vReleasePeriodFrom) < BegOfDay(vReleasePeriodTo) Then
												cmWriteOffAllotmentRooms(RoomQuota, vPrevPeriodsRow.RoomType, vReleasePeriodFrom, vReleasePeriodTo);
											EndIf;
										EndIf;
									Else
										Break;
									EndIf;
								EndDo;
							Else
								Break;
							EndIf;
						EndDo;
					EndIf;
				EndIf;
			ElsIf Not ReservationStatus.IsCheckIn And RoomQuota.ReleaseTime <> 0 Then
				// Process release period
				vCurAccountingDate = BegOfDay(CurrentSessionDate());
				If ValueIsFilled(Hotel.AccountingDate) Then
					vCurAccountingDate = Hotel.AccountingDate;
				EndIf;
				For Each vPeriodsRow In vAllPeriods Do
					vRoomRate = vPeriodsRow.RoomRate;
					If Not ValueIsFilled(vRoomRate) Then
						If ValueIsFilled(RoomQuota.RoomRate) Then
							vRoomRate = RoomQuota.RoomRate;
						Else
							vRoomRate = Hotel.RoomRate;
						EndIf;
					EndIf;
					If Not ValueIsFilled(vRoomRate) Then
						Break;
					EndIf;
					vReleasePeriodFrom = cm0SecondShift(cmInitializeDateTime(vCurAccountingDate, vRoomRate));
					vReleasePeriodTo = cm0SecondShift(cmInitializeDateTime(vCurAccountingDate + 24*3600*RoomQuota.ReleaseTime, vRoomRate));
					If vPeriodsRow.CheckInDate < vReleasePeriodTo And vPeriodsRow.CheckOutDate > vReleasePeriodFrom Then
						If BegOfDay(vReleasePeriodFrom) < BegOfDay(vPeriodsRow.CheckInDate) Then
							vReleasePeriodFrom = cm0SecondShift(cmInitializeDateTime(BegOfDay(vPeriodsRow.CheckInDate), vRoomRate));
						EndIf;
						If BegOfDay(vReleasePeriodTo) > BegOfDay(vPeriodsRow.CheckOutDate) Then
							vReleasePeriodTo = cm0SecondShift(cmInitializeDateTime(BegOfDay(vPeriodsRow.CheckOutDate), vRoomRate));
						EndIf;
						If BegOfDay(vReleasePeriodFrom) < BegOfDay(vReleasePeriodTo) Then
							cmWriteOffAllotmentRooms(RoomQuota, vPeriodsRow.RoomType, vReleasePeriodFrom, vReleasePeriodTo);
						Else
							Break;
						EndIf;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // DoRoomInventoryPosting 

// -----------------------------------------------------------------------------
Procedure PostToBusinessBlockForecastSales(pPeriods)
	vHotelAccountingDate = Hotel.AccountingDate;
	If Not ValueIsFilled(vHotelAccountingDate) Then
		vHotelAccountingDate = BegOfDay(CurrentSessionDate());
	EndIf;
	vRoomQuotaObj = RoomQuota.GetObject();
	For Each vPeriodsRow In pPeriods Do
		If vPeriodsRow.NumberOfRooms > 0 Or vPeriodsRow.NumberOfBeds > 0 Then 
			vPeriodRoomType = vPeriodsRow.RoomType;
			If ValueIsFilled(RoomTypeUpgrade) Then
				If ValueIsFilled(RoomTypeUpgrade.BaseRoomType) And RoomTypeUpgrade.BaseRoomType = vPeriodRoomType Then
					vPeriodRoomType = RoomTypeUpgrade;
				ElsIf vRoomQuotaObj.UsePriceCalculationRoomTypeForAllotmentWriteOff Then
					vPeriodRoomType = RoomTypeUpgrade;
				EndIf;
			EndIf;
			vMessage = "";
			vAllotmentForecastSales = vRoomQuotaObj.pmCalculateBusinessBlockForecastSales(Hotel, vPeriodRoomType, vPeriodsRow.CheckInDate, vPeriodsRow.CheckOutDate, -vPeriodsRow.NumberOfRooms, -vPeriodsRow.NumberOfBeds, vPeriodsRow.NumberOfBedsPerRoom, vMessage);
			For Each vSalesRow In vAllotmentForecastSales Do
				If ValueIsFilled(vSalesRow.AccountingDate) And ValueIsFilled(vSalesRow.Service) And (vSalesRow.Sales <> 0 Or vSalesRow.RoomsRented <> 0) Then
					If vSalesRow.AccountingDate >= vHotelAccountingDate Then
						vSFRec = RegisterRecords.SalesForecast.Add();
						FillPropertyValues(vSFRec, RoomQuota);
						FillPropertyValues(vSFRec, vSalesRow);
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
EndProcedure // PostToBusinessBlockForecastSales

// -----------------------------------------------------------------------------
Procedure SwitchOffRoomInterfaceStatuses()
	// Switch off all room interface statuses
	vDate = Date;
	vCheckInDate = Min(CheckinDate, vDate);
	vRoomSts = cmGetRoomInterfaceStatuses(Room, vCheckinDate, CheckOutDate, Ref);
	For Each vRoomStsRow In vRoomSts Do
		If vRoomStsRow.ApplyToAllRoomGuests Then
			If vRoomStsRow.ParentDoc <> Ref Then
				Continue;
			EndIf;
		Else
			If Not pmIsMainAccommodationType() Then
				Continue;
			EndIf;
		EndIf;
		
		vDoc = vRoomStsRow.Ref;
		If Not vRoomStsRow.IsProcessed And Not vRoomStsRow.PeriodOfStayExtensionIsRequested And Not vRoomStsRow.GuestNameChangeIsRequested And Not vRoomStsRow.RoomChangeIsRequested Then
			If vRoomStsRow.IsCanceled Then
				// Wait till driver processes cancellation request
			Else
				// Document was not processed yet, so mark it for deletion
				vDocObj = vDoc.GetObject();
				vDocObj.SetDeletionMark(True);
			EndIf;
		Else
			vDocObj = vDoc.GetObject();
			If vRoomStsRow.IsProcessed And vRoomStsRow.IsCanceled Then
				vDocObj.SetDeletionMark(True);
			ElsIf Not vRoomStsRow.IsCanceled Then
				If ValueIsFilled(vRoomStsRow.RoomInterfaceType) And ValueIsFilled(vRoomStsRow.TurnOffParameters) Then
					// Cancel room interface
					vDocObj.Read();
					vDocObj.IsCanceled = True;
					vDocObj.IsProcessed = False;
					vDocObj.Write(DocumentWriteMode.Write);
				Else
					vDocObj.SetDeletionMark(True);	
				EndIf;
			Else
				// Wait till driver processes cancellation request
			EndIf;
		EndIf;
	EndDo;
EndProcedure //  SwitchOffRoomInterfaceStatuses 

// -----------------------------------------------------------------------------
Procedure ProcessRoomInterfaceStatuses()
	// Do main processing
	If Not ReservationStatus.IsActive And Not ReservationStatus.IsCheckIn And Not ReservationStatus.IsPreliminary Then
		SwitchOffRoomInterfaceStatuses();
	Else
		// Check if there was room change, period of stay extension or guest name change
		vPrevAccStates = pmGetReservationAttributes(CurrentSessionDate());
		If vPrevAccStates.Count() > 0 Then
			vPrevAccStateRow = vPrevAccStates.Get(0);
			vPrevRoomInterfaces = cmGetRoomInterfaceStatuses(vPrevAccStateRow.Room, Min(vPrevAccStateRow.CheckInDate, Date), vPrevAccStateRow.CheckOutDate, Ref);
			// Room change
			If ValueIsFilled(vPrevAccStateRow.Room) And vPrevAccStateRow.Room <> Room Then
				For Each vPrevRoomInterfacesRow In vPrevRoomInterfaces Do
					If Not vPrevRoomInterfacesRow.IsCanceled Then
						If Not vPrevRoomInterfacesRow.ApplyToAllRoomGuests Then
							If Not pmIsMainAccommodationType() Then
								Continue;
							EndIf;
						Else
							If vPrevRoomInterfacesRow.ParentDoc <> Ref Then
								Continue;
							EndIf;
						EndIf;
						
						If vPrevRoomInterfacesRow.IsCanceled Or (Not vPrevRoomInterfacesRow.IsCanceled And Not ValueIsFilled(vPrevRoomInterfacesRow.RoomChangeParameters)) Then
							// First we have to copy room interface statuses from the previous room
							vStsObj = Documents.RoomInterfaceStatus.CreateDocument();
							vStsObj.Fill(Ref);
							FillPropertyValues(vStsObj, vPrevRoomInterfacesRow, , "Number, Date, Author, Hotel, ParentDoc, Room, IsProcessed, IsCanceled");
							vStsObj.Write(DocumentWriteMode.Write);
							
							// Then we have to switch off previous room interfaces
							If Not vPrevRoomInterfacesRow.IsProcessed Then
								If Not vPrevRoomInterfacesRow.IsCanceled Then
									// Document was not processed yet, so mark it for deletion
									vStsObj = vPrevRoomInterfacesRow.Ref.GetObject();
									vStsObj.SetDeletionMark(True);
								EndIf;
							Else
								If Not vPrevRoomInterfacesRow.IsCanceled Then
									// Cancel room interface
									If ValueIsFilled(vPrevRoomInterfacesRow.RoomInterfaceType) And ValueIsFilled(vPrevRoomInterfacesRow.TurnOffParameters) Then
										vStsObj = vPrevRoomInterfacesRow.Ref.GetObject();
										vStsObj.IsCanceled = True;
										vStsObj.IsProcessed = False;
										vStsObj.Write(DocumentWriteMode.Write);
									Else
										vStsObj = vPrevRoomInterfacesRow.Ref.GetObject();
										vStsObj.SetDeletionMark(True);	
									EndIf;
								EndIf;
							EndIf;
						Else
							vStsObj = vPrevRoomInterfacesRow.Ref.GetObject();
							If vPrevRoomInterfacesRow.PeriodOfStayExtensionIsRequested Or vPrevRoomInterfacesRow.GuestNameChangeIsRequested Or vPrevRoomInterfacesRow.RoomChangeIsRequested Or 
							   vPrevRoomInterfacesRow.ExtraParametersChangeIsRequested Or vPrevRoomInterfacesRow.IsProcessed  Then
								vStsObj.OldRoom = vStsObj.Room;
								vStsObj.IsProcessed = False;
								vStsObj.RoomChangeIsRequested = True; 
							EndIf;
							vStsObj.Room = Room;
							vStsObj.Write(DocumentWriteMode.Write);	
						EndIf;
					EndIf;
				EndDo;
			Else
				// Guest name change
				If lower(TrimAll(vPrevAccStateRow.GuestFullName)) <> lower(TrimAll(GuestFullName)) Then
					For Each vPrevRoomInterfacesRow In vPrevRoomInterfaces Do
						If Not vPrevRoomInterfacesRow.IsCanceled Then
							If Not IsBlankString(vPrevRoomInterfacesRow.GuestNameChangeParameters) Then
								If Not vPrevRoomInterfacesRow.ApplyToAllRoomGuests Then
									If Not pmIsMainAccommodationType() Then
										Continue;
									EndIf;
								Else
									If vPrevRoomInterfacesRow.ParentDoc <> Ref Then
										Continue;
									EndIf;
								EndIf;

								// Update room interface record
								vStsObj = vPrevRoomInterfacesRow.Ref.GetObject();
								vStsObj.GuestNameChangeIsRequested = True;
								vStsObj.IsProcessed = False;
								vStsObj.Write(DocumentWriteMode.Write);
							EndIf;
						EndIf;
					EndDo;
				EndIf;
				// Period of stay extension
				If vPrevAccStateRow.CheckOutDate < CheckOutDate Then
					For Each vPrevRoomInterfacesRow In vPrevRoomInterfaces Do
						If Not vPrevRoomInterfacesRow.IsCanceled Then
							If Not IsBlankString(vPrevRoomInterfacesRow.PeriodOfStayExtentionParameters) Then
								If Not vPrevRoomInterfacesRow.ApplyToAllRoomGuests Then
									If Not pmIsMainAccommodationType() Then
										Continue;
									EndIf;
								Else
									If vPrevRoomInterfacesRow.ParentDoc <> Ref Then
										Continue;
									EndIf;
								EndIf;

								vStsObj = vPrevRoomInterfacesRow.Ref.GetObject();
								vStsObj.PeriodOfStayExtensionIsRequested = True;
								vStsObj.IsProcessed = False;
								vStsObj.Write(DocumentWriteMode.Write);
							EndIf;
						EndIf;
					EndDo;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure //  ProcessRoomInterfaceStatuses

// -----------------------------------------------------------------------------
Function pmIsMainAccommodationType()
	If ValueisFilled(AccommodationType) Then
		If AccommodationType.Type = Enums.AccomodationTypes.Room Or
		   AccommodationType.Type = Enums.AccomodationTypes.Beds Then
			Return True;
		EndIf;
	EndIf;
	Return False;
EndFunction //  pmIsMainAccommodationType

// -----------------------------------------------------------------------------
Procedure AttachDataScansDocument()
	vDocRef = Documents.ClientDataScans.EmptyRef();
	If ValueIsFilled(Guest) And ValueIsFilled(GuestGroup) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	ClientDataScans.Ref AS Ref
		|FROM
		|	Document.ClientDataScans AS ClientDataScans
		|WHERE
		|	ClientDataScans.Posted
		|	AND ClientDataScans.Hotel = &qHotel
		|	AND ClientDataScans.Guest <> &qEmptyGuest
		|	AND (ClientDataScans.ParentDoc = &qEmptyReservation
		|				AND ClientDataScans.Guest = &qGuest
		|			OR ClientDataScans.ParentDoc = &qEmptyAccommodation
		|				AND ClientDataScans.Guest = &qGuest
		|			OR ClientDataScans.ParentDoc = UNDEFINED
		|				AND ClientDataScans.Guest = &qGuest
		|			OR ClientDataScans.GuestGroup = &qGuestGroup
		|				AND ClientDataScans.Guest = &qGuest
		|				AND ClientDataScans.ParentDoc <> &qThisDocRef)
		|
		|ORDER BY
		|	ClientDataScans.PointInTime DESC";
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qGuest", Guest);
		vQry.SetParameter("qGuestGroup", GuestGroup);
		vQry.SetParameter("qThisDocRef", Ref);
		vQry.SetParameter("qEmptyGuest", Catalogs.Clients.EmptyRef());
		vQry.SetParameter("qEmptyReservation", Documents.Reservation.EmptyRef());
		vQry.SetParameter("qEmptyAccommodation", Documents.Accommodation.EmptyRef());
		vDocs = vQry.Execute().Unload();
		For Each vDocsRow In vDocs Do
			vDocRef = vDocsRow.Ref;
			Break;
		EndDo;
		vDocObj = Undefined;
		If ValueIsFilled(vDocRef) Then
			vDocObj = vDocRef.GetObject();
			vDocObj.GuestGroup = GuestGroup;
			vDocObj.ParentDoc = Ref;
			vDocObj.Guest = Guest;
			If ValueIsFilled(Room) Then
				vDocObj.Room = Room;
			EndIf;
			vDocObj.AdditionalProperties.Insert("LinksRestoreMode", True);
			vDocObj.Write(DocumentWriteMode.Posting);
		EndIf;
	EndIf;
EndProcedure //  AttachDataScansDocument

// -----------------------------------------------------------------------------
Procedure CancelBoundOrders()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Orders.Ref AS Ref
	|FROM
	|	Document.Order AS Orders
	|WHERE
	|	NOT Orders.DeletionMark
	|	AND Orders.ParentDoc = &qParentDoc
	|	AND (Orders.Hotel.AccountingDate = &qEmptyDate
	|			OR Orders.Hotel.AccountingDate <> &qEmptyDate
	|				AND NOT Orders.Hotel.DoNotEditClosedDateDocs
	|			OR Orders.Hotel.AccountingDate <> &qEmptyDate
	|				AND Orders.Hotel.DoNotEditClosedDateDocs
	|				AND Orders.Charge.Date IS NULL
	|			OR Orders.Hotel.AccountingDate <> &qEmptyDate
	|				AND Orders.Hotel.DoNotEditClosedDateDocs
	|				AND NOT Orders.Charge.Date IS NULL
	|				AND Orders.Charge.Date >= Orders.Hotel.AccountingDate)
	|	AND &qRefIsFilled
	|
	|ORDER BY
	|	Orders.PointInTime";
	vQry.SetParameter("qParentDoc", Ref);
	vQry.SetParameter("qRefIsFilled", ValueIsFilled(Ref));
	vQry.SetParameter("qEmptyDate", '00010101');
	vOrders = vQry.Execute().Unload();	
	If vOrders.Count() > 0 Then
		vCancelStatus = Catalogs.OrderStatuses.Cancel;
		For Each vOrdersRow In vOrders Do
			vOrderObj = vOrdersRow.Ref.GetObject();
			vOrderObj.Status = vCancelStatus;
			If ValueIsFilled(vOrderObj.Charge) Then
				vChargeObject = vOrderObj.Charge.GetObject();
				vChargeObject.SetDeletionMark(True);
			EndIf;
			vOrderObj.AdditionalProperties.Insert("SkipIfModificationIsAllowedCheck", True);
			vOrderObj.Write(DocumentWriteMode.Write);
		EndDo;
	EndIf;
EndProcedure //  CancelBoundOrders

// -----------------------------------------------------------------------------
Procedure PostResourceReservations(pResourceReservationServices, pResourceReservations)
	pResourceReservationServices.Columns.Add("ResourceReservation", cmGetDocumentTypeDescription("ResourceReservation"));
	vDocsToDelete = New ValueList();
	For Each vRRSrvRow In pResourceReservationServices Do
		// Try to search for such resource reservation
		vDateTimeFrom = BegOfDay(vRRSrvRow.AccountingDate) + (vRRSrvRow.TimeFrom - BegOfDay(vRRSrvRow.TimeFrom));
		vRRRows = pResourceReservations.FindRows(New Structure("Resource, DateTimeFrom", vRRSrvRow.ServiceResource, vDateTimeFrom));
		If vRRRows.Count() = 1 Then
			vRRRow = vRRRows.Get(0);
			vRRSrvRow.ResourceReservation = vRRRow.Ref;
		EndIf;
	EndDo;
	For Each vRRRow In pResourceReservations Do
		If pResourceReservationServices.Find(vRRRow.Ref, "ResourceReservation") = Undefined Then
			vRRRowDocObj = vRRRow.Ref.GetObject();
			vRRRowDocObj.AdditionalProperties.Insert("AllowSetDeletionMark", True);
			vRRRowDocObj.SetDeletionMark(True);
		EndIf;
	EndDo;
	For Each vRRSrvRow In pResourceReservationServices Do
		// Get resource reservation main parameters
		vDateTimeFrom = BegOfDay(vRRSrvRow.AccountingDate) + (vRRSrvRow.TimeFrom - BegOfDay(vRRSrvRow.TimeFrom));
		vDateTimeTo = BegOfDay(vRRSrvRow.AccountingDate) + (vRRSrvRow.TimeTo - BegOfDay(vRRSrvRow.TimeTo));
		If vRRSrvRow.TimeFrom >= vRRSrvRow.TimeTo Then
			vDateTimeTo = vDateTimeTo + 24*3600;
		EndIf;
		// Get resource reservation object
		vFolio = vRRSrvRow.Folio;
		vDocObj = Undefined;
		If ValueIsFilled(vRRSrvRow.ResourceReservation) Then
			vDocObj = vRRSrvRow.ResourceReservation.GetObject();
			vDocObj.Read();
		Else
			vDocObj = Documents.ResourceReservation.CreateDocument();
		EndIf;
		vDocObj.Hotel = vFolio.Hotel;
		If Not ValueIsFilled(vDocObj.Hotel) Then
			vDocObj.Hotel = Hotel;
		EndIf;
		vDocObj.Company = vFolio.Company;
		If Not ValueIsFilled(vDocObj.Company) Then
			vDocObj.Company = Company;
		EndIf;
		vDocObj.ExchangeRateDate = ExchangeRateDate;
		vDocObj.ChargingFolio = vFolio;
		vDocObj.FolioCurrency = vRRSrvRow.FolioCurrency;
		vDocObj.FolioCurrencyExchangeRate = vRRSrvRow.FolioCurrencyExchangeRate;
		vDocObj.GuestGroup = vFolio.GuestGroup;
		vDocObj.ResourceReservationStatus = vDocObj.Hotel.NewResourceReservationStatus;
		If ValueIsFilled(vDocObj.ResourceReservationStatus) Then
			vDocObj.DoCharging = vDocObj.ResourceReservationStatus.DoCharging;
		EndIf;
		If Not ValueIsFilled(vRRSrvRow.ResourceReservation) Then
			vDocObj.pmFillAttributesWithDefaultValues();
		EndIf;
		vDocObj.ReportingCurrency = ReportingCurrency;
		vDocObj.ReportingCurrencyExchangeRate = ReportingCurrencyExchangeRate;
		vDocObj.ResourceType = vRRSrvRow.ServiceResource.Owner;
		vDocObj.Resource = vRRSrvRow.ServiceResource;
		vDocObj.ClientType = ClientType;
		vDocObj.ClientTypeConfirmationText = ClientTypeConfirmationText;
		vDocObj.PlannedPaymentMethod = vFolio.PaymentMethod;
		vDocObj.DateTimeFrom = vDateTimeFrom;
		vDocObj.DateTimeTo = vDateTimeTo;
		vDocObj.Duration = vDocObj.pmCalculateDuration();
		vDocObj.NumberOfPersons = NumberOfPersons;
		If ValueIsFilled(vFolio.Contract) Then
			vDocObj.Owner = vFolio.Contract;
		ElsIf ValueIsFilled(vFolio.Customer) Then
			vDocObj.Owner = vFolio.Customer;
		ElsIf ValueIsFilled(vDocObj.Hotel) Then
			If ValueIsFilled(vDocObj.Hotel.IndividualsContract) Then
				vDocObj.Owner = vDocObj.Hotel.IndividualsContract;
			Else
				vDocObj.Owner = vDocObj.Hotel.IndividualsCustomer;
			EndIf;
		Else
			vDocObj.Owner = Undefined;
		EndIf;
		vDocObj.Customer = Customer;
		If ValueIsFilled(vDocObj.Customer) Then
			vDocObj.CustomerType = vDocObj.Customer.CustomerType;
		Else
			vDocObj.CustomerType = CustomerType;
		EndIf;
		vDocObj.Contract = Contract;
		vDocObj.Agent = vFolio.Agent;
		If ValueIsFilled(vDocObj.Agent) Then
			vDocObj.AgentCommission = AgentCommission;
			vDocObj.AgentCommissionType = AgentCommissionType;
			vDocObj.AgentCommissionServiceGroup = AgentCommissionServiceGroup;
		Else
			vDocObj.AgentCommission = 0;
			vDocObj.AgentCommissionType = Undefined;
			vDocObj.AgentCommissionServiceGroup = Catalogs.ServiceGroups.EmptyRef();
		EndIf;
		vDocObj.Client = vFolio.Client;
		vDocObj.ContactPerson = ContactPerson;
		vDocObj.CreditCard = CreditCard;
		vDocObj.Phone = Phone;
		vDocObj.Fax = Fax;
		vDocObj.EMail = EMail;
		vDocObj.PlannedPaymentMethod = vFolio.PaymentMethod;
		vDocObj.MarketingCode = MarketingCode;
		vDocObj.MarketingCodeConfirmationText = MarketingCodeConfirmationText;
		vDocObj.SourceOfBusiness = SourceOfBusiness;
		vDocObj.ParentDoc = Ref;
		vDocObj.Remarks = TrimAll(vRRSrvRow.Remarks);
		vDocObj.DoNotCalculateServices = True;
		vDocObj.DeletionMark = False;
		vDocObj.pmCalculateServices();
		vDocObj.Write(DocumentWriteMode.Posting);
		vDocObj.pmWriteToResourceReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
	EndDo;
EndProcedure //  PostResourceReservations	

// -----------------------------------------------------------------------------
Function IsChangeOfAccommodationConditions(pLastDocStateRow) 
	vIsChangeOfAccConditions = ReservationStatus.IsActive;
	If pLastDocStateRow <> Undefined And Posted And ReservationStatus.IsActive Then
		If cm0SecondShift(pLastDocStateRow.CheckInDate) <= cm0SecondShift(CheckInDate) And
		   cm0SecondShift(pLastDocStateRow.CheckOutDate) >= cm0SecondShift(CheckOutDate) And 
		   pLastDocStateRow.RoomType = RoomType And
		   pLastDocStateRow.AccommodationType = AccommodationType And
		   pLastDocStateRow.RoomQuantity >= RoomQuantity And 
		   ValueIsFilled(ReservationStatus) And ValueIsFilled(pLastDocStateRow.ReservationStatus) And 
		   ReservationStatus.IsActive = pLastDocStateRow.ReservationStatus.IsActive And
		   ReservationStatus.IsPreliminary = pLastDocStateRow.ReservationStatus.IsPreliminary And
		   ReservationStatus.IsArrivalSchedule = pLastDocStateRow.ReservationStatus.IsArrivalSchedule And 
		   Not ThereAreChangesInRoomRates(pLastDocStateRow) Then
			vIsChangeOfAccConditions = False;
		EndIf;
	EndIf;
	Return vIsChangeOfAccConditions;
EndFunction //  IsChangeOfAccommodationConditions

// -----------------------------------------------------------------------------
Function ThereAreChangesInRoomRates(pLastDocState)
	vRRAreChanged = False;
	If pLastDocState <> Undefined Then
		vLastRoomRates = pLastDocState.RoomRates.Get();
		If vLastRoomRates <> Undefined Then
			If vLastRoomRates.Count() <> RoomRates.Count() Then
				vRRAreChanged = True;
			Else
				i = 0;
				While i < vLastRoomRates.Count() Do
					vLastRoomRatesRow = vLastRoomRates.Get(i);
					vRoomRatesRow = RoomRates.Get(i);
					If vLastRoomRatesRow.AccountingDate <> vRoomRatesRow.AccountingDate Or
					   vLastRoomRatesRow.ChangeTime <> vRoomRatesRow.ChangeTime Or
					   vLastRoomRatesRow.AccommodationType <> vRoomRatesRow.AccommodationType Or
					   vLastRoomRatesRow.AccommodationTemplate <> vRoomRatesRow.AccommodationTemplate Or
					   vLastRoomRatesRow.RoomType <> vRoomRatesRow.RoomType Or
					   vLastRoomRatesRow.Room <> vRoomRatesRow.Room Then
						vRRAreChanged = True;
						Break;
					EndIf;
					i = i + 1;
				EndDo;
			EndIf;
		ElsIf RoomRates.Count() > 0 Then
			vRRAreChanged = True;
		EndIf;
	EndIf;
	Return vRRAreChanged;
EndFunction //  ThereAreChangesInRoomRates

// -----------------------------------------------------------------------------
Function GetRoomMainReservation()
	vOneRoomDoc = Undefined;
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reservation.Ref
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	Reservation.Posted
	|	AND Reservation.GuestGroup = &qGuestGroup
	|	AND (Reservation.Room = &qRoom
	|				AND &qRoomIsFilled
	|			OR Reservation.Number = &qNumber)
	|	AND Reservation.AccommodationType.Type = &qAccommodationTypeType
	|	AND Reservation.ReservationStatus.IsActive";
	vQry.SetParameter("qGuestGroup", GuestGroup);
	vQry.SetParameter("qRoom", Room);
	vQry.SetParameter("qRoomIsFilled", ValueIsFilled(Room));
	vQry.SetParameter("qAccommodationTypeType", Enums.AccomodationTypes.Room);
	vQry.SetParameter("qNumber", Number);
	vOneRoomDocs = vQry.Execute().Unload();
	If vOneRoomDocs.Count() > 0 Then
		vOneRoomDoc = vOneRoomDocs.Get(0).Ref;
	ElsIf ValueIsFilled(RoomType) And RoomType.DoesNotAffectRoomRevenueStatistics Then
		// Try to find main reservation by guest
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	Reservation.Ref
		|FROM
		|	Document.Reservation AS Reservation
		|WHERE
		|	Reservation.Posted
		|	AND Reservation.GuestGroup = &qGuestGroup
		|	AND Reservation.Guest = &qGuest
		|	AND &qGuestIsFilled
		|	AND Reservation.AccommodationType.Type = &qAccommodationTypeType
		|	AND Reservation.ReservationStatus.IsActive";
		vQry.SetParameter("qGuestGroup", GuestGroup);
		vQry.SetParameter("qGuest", Guest);
		vQry.SetParameter("qGuestIsFilled", ValueIsFilled(Guest));
		vQry.SetParameter("qAccommodationTypeType", Enums.AccomodationTypes.Room);
		vQry.SetParameter("qNumber", Number);
		vOneRoomDocs = vQry.Execute().Unload();
		If vOneRoomDocs.Count() > 0 Then
			vOneRoomDoc = vOneRoomDocs.Get(0).Ref;
		EndIf;
	EndIf;
	Return vOneRoomDoc;
EndFunction //  GetRoomMainReservation

// -----------------------------------------------------------------------------
Function GetAgentCommissionDescription(pDoc, pLanguage)
	vStr = "";
	If pDoc.AgentCommissionType = Enums.AgentCommissionTypes.Percent Then
		vStr = TrimAll(pDoc.AgentCommission) + cmNStr("en='%';ru='%';de='%'", pLanguage);
	ElsIf pDoc.AgentCommissionType = Enums.AgentCommissionTypes.FirstDayPercent Then
		vStr = TrimAll(pDoc.AgentCommission) + cmNStr("en='% for the 1-st day';ru='% за 1-ый день';de='% für den ersten Tag'", pLanguage);
	ElsIf pDoc.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerCheckInPerClient Then
		vStr = cmFormatSum(pDoc.AgentCommission, pDoc.Agent.AccountingCurrency) + cmNStr("en=' per guest per check-in';ru=' за гостя за заезд';de=' pro Gast pro Check-in'", pLanguage);
	ElsIf pDoc.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerCheckInPerRoom Then
		vStr = cmFormatSum(pDoc.AgentCommission, pDoc.Agent.AccountingCurrency) + cmNStr("en=' per room per check-in';ru=' за номер за заезд';de=' pro Zimmer pro Check-in'", pLanguage);
	ElsIf pDoc.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerDayPerClient Then
		vStr = cmFormatSum(pDoc.AgentCommission, pDoc.Agent.AccountingCurrency) + cmNStr("en=' per guest per night';ru=' за гостя за ночь';de=' pro Gast pro Nacht'", pLanguage);
	ElsIf pDoc.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerDayPerRoom Then
		vStr = cmFormatSum(pDoc.AgentCommission, pDoc.Agent.AccountingCurrency) + cmNStr("en=' per room per night';ru=' за номер за ночь';de=' pro Zimmer pro Nacht'", pLanguage);
	EndIf;
	Return vStr;
EndFunction //  GetAgentCommissionDescription

// -----------------------------------------------------------------------------
Procedure AddPriceCalculatioDateChangeHistoryRecord(pDate, pPriceCalculationDate)
	vRRRow = Undefined;
	vRRRows = RoomRates.FindRows(New Structure("AccountingDate", BegOfDay(pDate)));
	If vRRRows.Count() > 0 Then
		vRRRow = vRRRows.Get(0);
	Else
		vRRRow = RoomRates.Add();
		vRRRow.AccountingDate = BegOfDay(pDate);
	EndIf;
	If vRRRow <> Undefined Then
		vRRRow.PriceCalculationDate = pPriceCalculationDate;
	EndIf;
	RoomRates.Sort("AccountingDate, ChangeTime");
EndProcedure // AddPriceCalculatioDateChangeHistoryRecord

// -----------------------------------------------------------------------------
Procedure pmUpdatePriceCalculationDate() Export
	vUpdatePriceCalculationDate = False;

	vOldPriceCalculationDate = PriceCalculationDate;
	vNewPriceCalculationDate = CurrentSessionDate();
	If BegOfDay(vNewPriceCalculationDate) = vNewPriceCalculationDate Then
		vNewPriceCalculationDate = vNewPriceCalculationDate + 1;
	EndIf;
	
	vBegOfCheckInDate = BegOfDay(CheckInDate);
	vBegOfCheckOutDate = BegOfDay(CheckOutDate);
	
	If ValueIsFilled(Ref) And ValueIsFilled(vOldPriceCalculationDate) Then
		vBegOfRefCheckInDate = BegOfDay(Ref.CheckInDate);
		vBegOfRefCheckOutDate = BegOfDay(Ref.CheckOutDate);
			
		If ValueIsFilled(vBegOfRefCheckInDate) And ValueIsFilled(vBegOfCheckInDate) And 
		   ValueIsFilled(vBegOfRefCheckOutDate) And ValueIsFilled(vBegOfCheckOutDate) Then
			If vBegOfRefCheckInDate > vBegOfCheckOutDate Or vBegOfRefCheckOutDate < vBegOfCheckInDate Then
				vUpdatePriceCalculationDate = True;
			Else
				If vBegOfCheckInDate < vBegOfRefCheckInDate Then
					// Add record to the change history for new check-in date
					AddPriceCalculatioDateChangeHistoryRecord(vBegOfCheckInDate, vNewPriceCalculationDate);
					// Add record to the change history for old check-in date
					AddPriceCalculatioDateChangeHistoryRecord(vBegOfRefCheckInDate, vOldPriceCalculationDate);
				EndIf;
				If vBegOfCheckOutDate > vBegOfRefCheckOutDate Then
					// Add record to the change history for old check-out date
					AddPriceCalculatioDateChangeHistoryRecord(vBegOfRefCheckOutDate, vNewPriceCalculationDate);
				EndIf;
			EndIf;
		EndIf;
	EndIf;

	If vUpdatePriceCalculationDate Then
		PriceCalculationDate = vNewPriceCalculationDate;
	EndIf;

	// Update data in the first change history record for check-in date
	pmUpdateFirstChangeHistoryRecord();		
EndProcedure // pmUpdatePriceCalculationDate

// -----------------------------------------------------------------------------
Procedure pmUpdateFirstChangeHistoryRecord() Export
	If RoomRates.Count() > 0 Then
		v1RRRow = RoomRates.Find(BegOfDay(CheckInDate), "AccountingDate");
		If v1RRRow = Undefined Then
			v1RRRow = RoomRates.Insert(0);
			v1RRRow.AccountingDate = BegOfDay(CheckInDate);
		EndIf;
		If ValueIsFilled(v1RRRow.RoomRate) Then
			v1RRRow.RoomRate = RoomRate;
		EndIf;
		If ValueIsFilled(v1RRRow.RoomType) Then
			v1RRRow.RoomType = RoomType;
		EndIf;
		If ValueIsFilled(v1RRRow.Room) Then
			v1RRRow.Room = Room;
		EndIf;
		If ValueIsFilled(v1RRRow.AccommodationTemplate) Then
			v1RRRow.AccommodationTemplate = AccommodationTemplate;
		EndIf;
		If ValueIsFilled(v1RRRow.AccommodationType) Then
			v1RRRow.AccommodationType = AccommodationType;
		EndIf;
		If ValueIsFilled(v1RRRow.BoardPlace) Then
			v1RRRow.BoardPlace = BoardPlace;
		EndIf;
		If ValueIsFilled(v1RRRow.ClientType) Then
			v1RRRow.ClientType = ClientType;
		EndIf;
		If ValueIsFilled(v1RRRow.MarketingCode) Then
			v1RRRow.MarketingCode = MarketingCode;
		EndIf;
		If ValueIsFilled(v1RRRow.SourceOfBusiness) Then
			v1RRRow.SourceOfBusiness = SourceOfBusiness;
		EndIf;
		If ValueIsFilled(v1RRRow.ServicePackage) Then
			v1RRRow.ServicePackage = ServicePackage;
		EndIf;
		If v1RRRow.NumberOfAdults <> 0 Or v1RRRow.NumberOfTeenagers <> 0 Or v1RRRow.NumberOfChildren <> 0 Or v1RRRow.NumberOfInfants <> 0 Then
			v1RRRow.NumberOfAdults = NumberOfAdults;
			v1RRRow.NumberOfTeenagers = NumberOfTeenagers;
			v1RRRow.NumberOfChildren = NumberOfChildren;
			v1RRRow.NumberOfInfants = NumberOfInfants;
		EndIf;
		RoomRates.Sort("AccountingDate, ChangeTime");
	EndIf;
EndProcedure // pmUpdateFirstChangeHistoryRecord

// -----------------------------------------------------------------------------
Function pmDeleteEmptyChangeHistoryRecord(pRoomRatesRow, pIndex = 0, pPrevIsBookedOut = False) Export
	vRowWasDeleted = False;
	If (Not ValueIsFilled(pRoomRatesRow.RoomRate) Or pRoomRatesRow.RoomRate = RoomRate And pIndex = 0) And 
	   (Not ValueIsFilled(pRoomRatesRow.AccommodationType) Or pRoomRatesRow.AccommodationType = AccommodationType And pIndex = 0) And 
	   (Not ValueIsFilled(pRoomRatesRow.AccommodationTemplate) Or pRoomRatesRow.AccommodationTemplate = AccommodationTemplate And pIndex = 0) And 
	   (Not ValueIsFilled(pRoomRatesRow.Room) Or pRoomRatesRow.Room = Room And pIndex = 0) And 
	   (Not ValueIsFilled(pRoomRatesRow.RoomType) Or pRoomRatesRow.RoomType = RoomType And pIndex = 0) And 
	   (Not ValueIsFilled(pRoomRatesRow.SourceOfBusiness) Or pRoomRatesRow.SourceOfBusiness = SourceOfBusiness And pIndex = 0) And 
	   (Not ValueIsFilled(pRoomRatesRow.MarketingCode) Or pRoomRatesRow.MarketingCode = MarketingCode And pIndex = 0) And 
	   (Not ValueIsFilled(pRoomRatesRow.ClientType) Or pRoomRatesRow.ClientType = ClientType And pIndex = 0) And 
	   (Not ValueIsFilled(pRoomRatesRow.BoardPlace) Or pRoomRatesRow.BoardPlace = BoardPlace And pIndex = 0) And 
	   (Not ValueIsFilled(pRoomRatesRow.ServicePackage) Or pRoomRatesRow.ServicePackage = ServicePackage And pIndex = 0) And 
	   (Not ValueIsFilled(pRoomRatesRow.PriceCalculationDate) Or pRoomRatesRow.PriceCalculationDate = PriceCalculationDate And pIndex = 0) And 
	   (pRoomRatesRow.NumberOfAdults = 0 Or pRoomRatesRow.NumberOfAdults = NumberOfAdults And pIndex = 0) And 
	   (pRoomRatesRow.NumberOfTeenagers = 0 Or pRoomRatesRow.NumberOfTeenagers = NumberOfTeenagers And pIndex = 0) And 
	   (pRoomRatesRow.NumberOfChildren = 0 Or pRoomRatesRow.NumberOfChildren = NumberOfChildren And pIndex = 0) And 
	   (pRoomRatesRow.NumberOfInfants = 0 Or pRoomRatesRow.NumberOfInfants = NumberOfInfants And pIndex = 0) And
	   IsBlankString(pRoomRatesRow.Discount) And
	   IsBlankString(pRoomRatesRow.AgentCommission) And 
	   (Not pRoomRatesRow.IsBookedOut And Not pPrevIsBookedOut) Then
		RoomRates.Delete(pRoomRatesRow);
		vRowWasDeleted = True;
	EndIf;
	Return vRowWasDeleted;
EndFunction // pmDeleteEmptyChangeHistoryRecord

#EndRegion

#Region Initialize

RoomsWriteOff = 0;
BedsWriteOff = 0;
AdditionalBedsWriteOff = 0;
PersonsWriteOff = 0;
RoomsWithReservedStatus = New ValueList();
HavePermissionToDoBookingWithoutRooms = cmCheckUserPermissions("HavePermissionToDoBookingWithoutRooms");
StatusHasChanged = False;
WriteOffAllotmentLateCheckOutAndEarlyCheckInFromFreeSaleVacantRooms = True;

#EndRegion

