Var StatusHasChanged;
Var CheckAccountingDate;
Var HotelAccountingDate;
Var BegOfCheckInDate;
Var ChargesToRepostStorno;
Var WriteOffAllotmentLateCheckOutAndEarlyCheckInFromFreeSaleVacantRooms;

// -----------------------------------------------------------------------------
Procedure FillRIExpenseAttributes(pRIRec, pPeriods, pPeriod, pEffectiveNumberOfRoomsRow, pPrevEffectiveNumberOfRoomsRow)
	FillPropertyValues(pRIRec, ThisObject);
	FillPropertyValues(pRIRec, pPeriod);
	
	pRIRec.Period = pEffectiveNumberOfRoomsRow.PeriodFrom;
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
	
	pRIRec.IsAccommodation = True;
	pRIRec.IsInHouse = AccommodationStatus.IsInHouse;
	pRIRec.IsCheckIn = AccommodationStatus.IsCheckIn And cm0SecondShift(pEffectiveNumberOfRoomsRow.PeriodFrom) = cm0SecondShift(CheckInDate);
	pRIRec.IsCheckOut = AccommodationStatus.IsCheckOut And cm0SecondShift(pEffectiveNumberOfRoomsRow.PeriodTo) = cm0SecondShift(CheckOutDate);
	pRIRec.IsRoomChange = AccommodationStatus.IsRoomChange;
	
	If AccommodationStatus.IsCheckIn And 
	   pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms <> 0 And 
	   cm1SecondShift(pEffectiveNumberOfRoomsRow.PeriodFrom) = cm1SecondShift(CheckInDate) Then
		pRIRec.RoomsCheckedIn = pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms;
	ElsIf pPrevEffectiveNumberOfRoomsRow <> Undefined And 
	      pPrevEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms <> 0 And 
	      pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms = 0 Then
		pRIRec.RoomsCheckedIn = -pPrevEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms;
		pRIRec.IsCheckIn = True;
	ElsIf pPrevEffectiveNumberOfRoomsRow <> Undefined And 
	      pPrevEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms = 0 And 
	      pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms <> 0 Then
		pRIRec.RoomsCheckedIn = pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms;
		pRIRec.IsCheckIn = True;
	EndIf;
	If AccommodationStatus.IsCheckIn And 
	   cm1SecondShift(pEffectiveNumberOfRoomsRow.PeriodFrom) = cm1SecondShift(CheckInDate) Then
		pRIRec.BedsCheckedIn = pPeriod.NumberOfBeds;
		pRIRec.AdditionalBedsCheckedIn = pPeriod.NumberOfAdditionalBeds;
		pRIRec.GuestsCheckedIn = pPeriod.NumberOfPersons;
	EndIf;
	
	pRIRec.InHouseRooms = pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms;
	pRIRec.InHouseBeds = pPeriod.NumberOfBeds;
	pRIRec.InHouseAdditionalBeds = pPeriod.NumberOfAdditionalBeds;
	pRIRec.InHouseGuests = pPeriod.NumberOfPersons;
	
	pRIRec.RoomsVacant = pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms;
	pRIRec.BedsVacant = pPeriod.NumberOfBeds;
	If pPeriod.DoNotChangeAvailability Then
		pRIRec.GuestsVacant = 0;
	Else
		pRIRec.GuestsVacant = pPeriod.NumberOfPersons;
	EndIf;
	
	pRIRec.ExpectedRoomsCheckedIn = 0;
	pRIRec.ExpectedBedsCheckedIn = 0;
	pRIRec.ExpectedAdditionalBedsCheckedIn = 0;
	pRIRec.ExpectedGuestsCheckedIn = 0;
	
	pRIRec.ExpectedRoomsCheckedOut = 0;
	pRIRec.ExpectedBedsCheckedOut = 0;
	pRIRec.ExpectedAdditionalBedsCheckedOut = 0;
	pRIRec.ExpectedGuestsCheckedOut = 0;
	
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
EndProcedure // FillRIExpenseAttributes

// -----------------------------------------------------------------------------
Procedure FillRIReceiptAttributes(pRIRec, pPeriods, pPeriod, pEffectiveNumberOfRoomsRow, pNextEffectiveNumberOfRoomsRow)
	FillPropertyValues(pRIRec, ThisObject);
	FillPropertyValues(pRIRec, pPeriod);
	
	pRIRec.Period = pEffectiveNumberOfRoomsRow.PeriodTo;
	pRIRec.PeriodFrom = pPeriod.CheckInDate;
	pRIRec.PeriodTo = pPeriod.CheckOutDate;
	pRIRec.PeriodDuration = cmCalculateDuration(pPeriod.RoomRate, pRIRec.PeriodFrom, pRIRec.PeriodTo);
	pRIRec.CheckInAccountingDate = BegOfDay(CheckInDate);
	pRIRec.CheckOutAccountingDate = BegOfDay(CheckOutDate);
	pRIRec.CheckInDate = CheckInDate;
	pRIRec.CheckOutDate = CheckOutDate;
	pRIRec.Duration = Duration;
	
	If ValueIsFilled(pPeriod.RoomRate) Then
		pRIRec.RoomRateType = RoomRate.RoomRateType;
	EndIf;
	
	pRIRec.PricePresentation = PricePresentation;
	
	pRIRec.IsAccommodation = True;
	pRIRec.IsInHouse = AccommodationStatus.IsInHouse;
	pRIRec.IsCheckIn = AccommodationStatus.IsCheckIn And cm0SecondShift(pEffectiveNumberOfRoomsRow.PeriodFrom) = cm0SecondShift(CheckInDate);
	pRIRec.IsCheckOut = AccommodationStatus.IsCheckOut And cm0SecondShift(pEffectiveNumberOfRoomsRow.PeriodTo) = cm0SecondShift(CheckOutDate);
	pRIRec.IsRoomChange = AccommodationStatus.IsRoomChange;
	
	pRIRec.ExpectedRoomsCheckedIn = 0;
	pRIRec.ExpectedBedsCheckedIn = 0;
	pRIRec.ExpectedAdditionalBedsCheckedIn = 0;
	pRIRec.ExpectedGuestsCheckedIn = 0;
	
	If AccommodationStatus.IsCheckOut And 
	   pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms <> 0 And 
	   cm0SecondShift(pEffectiveNumberOfRoomsRow.PeriodTo) = cm0SecondShift(CheckOutDate) Then
		pRIRec.RoomsCheckedOut = ?(pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms > 0, pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms, 0);
	ElsIf pNextEffectiveNumberOfRoomsRow <> Undefined And 
	      pNextEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms <> 0 And 
	      pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms = 0 Then
		pRIRec.RoomsCheckedOut = ?(pNextEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms < 0, -pNextEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms, 0);
		pRIRec.IsCheckOut = True;
	ElsIf pNextEffectiveNumberOfRoomsRow <> Undefined And 
	      pNextEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms = 0 And 
	      pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms <> 0 Then
		pRIRec.RoomsCheckedOut = ?(pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms > 0, pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms, 0);
		pRIRec.IsCheckOut = True;
	EndIf;
	If AccommodationStatus.IsCheckOut And 
	   cm0SecondShift(pEffectiveNumberOfRoomsRow.PeriodTo) = cm0SecondShift(CheckOutDate) Then
		pRIRec.BedsCheckedOut = pPeriod.NumberOfBeds;
		pRIRec.AdditionalBedsCheckedOut = pPeriod.NumberOfAdditionalBeds;
		pRIRec.GuestsCheckedOut = pPeriod.NumberOfPersons;
		If AccommodationStatus.IsInHouse And AccommodationStatus.IsActive Then
			pRIRec.ExpectedRoomsCheckedOut = ?(pRIRec.RoomsCheckedOut > 0, pRIRec.RoomsCheckedOut, 0);
			pRIRec.ExpectedBedsCheckedOut = ?(pRIRec.BedsCheckedOut > 0, pRIRec.BedsCheckedOut, 0);
			pRIRec.ExpectedAdditionalBedsCheckedOut = ?(pRIRec.AdditionalBedsCheckedOut > 0, pRIRec.AdditionalBedsCheckedOut, 0);
			pRIRec.ExpectedGuestsCheckedOut = ?(pRIRec.GuestsCheckedOut > 0, pRIRec.GuestsCheckedOut, 0);
			
			pRIRec.RoomsCheckedOut = 0;
			pRIRec.BedsCheckedOut = 0;
			pRIRec.AdditionalBedsCheckedOut = 0;
			pRIRec.GuestsCheckedOut = 0;
		EndIf;
	EndIf;
	
	pRIRec.InHouseRooms = pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms;
	pRIRec.InHouseBeds = pPeriod.NumberOfBeds;
	pRIRec.InHouseAdditionalBeds = pPeriod.NumberOfAdditionalBeds;
	pRIRec.InHouseGuests = pPeriod.NumberOfPersons;
	
	pRIRec.RoomsVacant = pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms;
	pRIRec.BedsVacant = pPeriod.NumberOfBeds;
	If pPeriod.DoNotChangeAvailability Then
		pRIRec.GuestsVacant = 0;
	Else
		pRIRec.GuestsVacant = pPeriod.NumberOfPersons;
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
EndProcedure // FillRIReceiptAttributes

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
Procedure PostToRoomInventory(pCancel, pPeriods, pPeriod, pEffectiveNumberOfRoomsRow, pPrevEffectiveNumberOfRoomsRow, pNextEffectiveNumberOfRoomsRow)
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
	
	// Do expense movement
	vRIRec = RegisterRecords.RoomInventory.AddExpense();
	FillRIExpenseAttributes(vRIRec, pPeriods, pPeriod, pEffectiveNumberOfRoomsRow, pPrevEffectiveNumberOfRoomsRow);
		
	// Do receipt movement
	vRIRec = RegisterRecords.RoomInventory.AddReceipt();
	FillRIReceiptAttributes(vRIRec, pPeriods, pPeriod, pEffectiveNumberOfRoomsRow, pNextEffectiveNumberOfRoomsRow);
EndProcedure // PostToRoomInventory

// -----------------------------------------------------------------------------
Procedure FillRQInitializationAttributes(pRQRec, pDate, pRoomQuota, pRoomType, pRoom)
	pRQRec.Hotel = Hotel;
	pRQRec.RoomQuota = pRoomQuota;
	pRQRec.RoomType = pRoomType;
	
	If ValueIsFilled(RoomTypeUpgrade) And ValueIsFilled(RoomTypeUpgrade.BaseRoomType) And RoomTypeUpgrade.BaseRoomType = pRoomType Then
		pRQRec.RoomType = RoomTypeUpgrade;
	EndIf;
	
	If pRoomQuota.IsQuotaForRooms Then
		pRQRec.Room = pRoom;
	Else
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
Procedure FillRQAttributes(pRQRec, pPeriod, pDate, pPeriodFrom, pPeriodTo, pEffectiveNumberOfRooms, pAllotment = Undefined)
	FillPropertyValues(pRQRec, ThisObject);
	FillPropertyValues(pRQRec, pPeriod);

	vDate = pDate;
	If WriteOffAllotmentLateCheckOutAndEarlyCheckInFromFreeSaleVacantRooms Then
		vDate = cmMovePeriodToToReferenceHour(vDate, pPeriod.RoomRate);
	EndIf;
	pRQRec.Period = vDate;
	
	If ValueIsFilled(RoomTypeUpgrade) And ValueIsFilled(RoomTypeUpgrade.BaseRoomType) And RoomTypeUpgrade.BaseRoomType = pPeriod.RoomType Then
		pRQRec.RoomType = RoomTypeUpgrade;
	EndIf;
	
	vAllotment = pRQRec.RoomQuota;
	If ValueIsFilled(pAllotment) Then
		vAllotment = pAllotment;
		pRQRec.RoomQuota = vAllotment;
		
		pRQRec.RoomsInQuota = pEffectiveNumberOfRooms;
		pRQRec.BedsInQuota = pPeriod.NumberOfBeds;
	EndIf;
	
	If ValueIsFilled(pPeriod.RoomRate) Then
		pRQRec.RoomRateType = pPeriod.RoomRate.RoomRateType;
	EndIf;
	
	pRQRec.InHouseRooms = pEffectiveNumberOfRooms;
	pRQRec.InHouseBeds = pPeriod.NumberOfBeds;
	
	pRQRec.RoomsRemains = pEffectiveNumberOfRooms;
	pRQRec.BedsRemains = pPeriod.NumberOfBeds;
	
	pRQRec.DateFrom = pPeriodFrom;
	pRQRec.DateTo = pPeriodTo;
	pRQRec.Duration = cmCalculateDuration(pPeriod.RoomRate, pPeriodFrom, pPeriodTo);
		
	If Not vAllotment.IsQuotaForRooms Then
		pRQRec.Room = Catalogs.Rooms.EmptyRef();
	EndIf;

	pRQRec.IsAccommodation = True;
	
	pRQRec.Timestamp = CurrentSessionDate();
EndProcedure // FillRQAttributes

// -----------------------------------------------------------------------------
Procedure FillRQRIAttributes(pRIRec, pPeriod, pDate, pPeriodFrom, pPeriodTo, pRoomsToWriteOff, pBedsToWriteOff)
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
	
	If Not pPeriod.RoomQuota.IsQuotaForRooms Then
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
Procedure PostToRoomQuotaSales(pCancel, pPeriod, pEffectiveNumberOfRoomsRow)
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
	
	vEffectivePeriodFrom = pEffectiveNumberOfRoomsRow.PeriodFrom;
	vEffectivePeriodTo = pEffectiveNumberOfRoomsRow.PeriodTo;
	If BegOfDay(pEffectiveNumberOfRoomsRow.PeriodFrom) <> BegOfDay(pEffectiveNumberOfRoomsRow.PeriodTo) And vDoPeriodCorrection Then
		vEffectivePeriodFrom = vRHCheckInDate;
		vEffectivePeriodTo = vRHCheckOutDate;
	EndIf;
	
	// Do storno movements for room inventory
	If pPeriod.RoomQuota.DoWriteOff And vEffectivePeriodFrom < vEffectivePeriodTo Then
		vRoomsToWriteOff = pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms;
		vBedsToWriteOff = pPeriod.NumberOfBeds;
		If vRoomsToWriteOff > 0 Or
		   vBedsToWriteOff > 0 Then
			// Do expense movement on check in date
			vRIRec = RegisterRecords.RoomInventory.AddExpense();
			FillRQRIAttributes(vRIRec, pPeriod, pEffectiveNumberOfRoomsRow.PeriodFrom, vEffectivePeriodFrom, vEffectivePeriodTo, vRoomsToWriteOff, vBedsToWriteOff);
				
			// Do receipt movement on check out date
			vRIRec = RegisterRecords.RoomInventory.AddReceipt();
			FillRQRIAttributes(vRIRec, pPeriod, pEffectiveNumberOfRoomsRow.PeriodTo, vEffectivePeriodFrom, vEffectivePeriodTo, vRoomsToWriteOff, vBedsToWriteOff);
		EndIf;
	EndIf;
	
	If vEffectivePeriodFrom < vEffectivePeriodTo And 
	   BegOfDay(pEffectiveNumberOfRoomsRow.PeriodFrom) <> BegOfDay(pEffectiveNumberOfRoomsRow.PeriodTo) Then
	   
		// Do expense movement on check in date
		vRQRec = RegisterRecords.RoomQuotaSales.AddExpense();
		FillRQAttributes(vRQRec, pPeriod, vEffectivePeriodFrom, pEffectiveNumberOfRoomsRow.PeriodFrom, pEffectiveNumberOfRoomsRow.PeriodTo, pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms);
			
		// Do receipt movement on check out date
		vRQRec = RegisterRecords.RoomQuotaSales.AddReceipt();
		FillRQAttributes(vRQRec, pPeriod, vEffectivePeriodTo, pEffectiveNumberOfRoomsRow.PeriodFrom, pEffectiveNumberOfRoomsRow.PeriodTo, pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms);

		// If allotment is tentative then we have to correct the number of tentative rooms booked
		If ValueIsFilled(pPeriod.RoomQuota) And pPeriod.RoomQuota.TreatAsTentativeBooking And (pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms <> 0 Or pPeriod.NumberOfBeds <> 0) Then
			vEndOfDay = EndOfDay(vEffectivePeriodFrom);
			While vEndOfDay <= vEffectivePeriodTo Do
				vEGGRec = RegisterRecords.ExpectedGuestGroups.Add();
				
				vEGGRec.Period = vEndOfDay;
				vEGGRec.Recorder = Ref;
				
				vEGGRec.Hotel = Hotel;
				vEGGRec.RoomQuota = pPeriod.RoomQuota;
				vEGGRec.ReservationStatus = ?(ValueIsFilled(Reservation), Reservation.ReservationStatus, Undefined);
				vEGGRec.GuestGroup = GuestGroup;
				vEGGRec.RoomType = pPeriod.RoomType;
				If ValueIsFilled(RoomTypeUpgrade) And ValueIsFilled(RoomTypeUpgrade.BaseRoomType) And RoomTypeUpgrade.BaseRoomType = pPeriod.RoomType Then
					vEGGRec.RoomType = RoomTypeUpgrade;
				EndIf;
				
				// Resources
				vEGGRec.RoomsReserved = -pEffectiveNumberOfRoomsRow.EffectiveNumberOfRooms;
				vEGGRec.BedsReserved = -pPeriod.NumberOfBeds;
				vEGGRec.AdditionalBedsReserved = 0;
				vEGGRec.GuestsReserved = 0;
				
				// Next date
				vEndOfDay = vEndOfDay + 24*3600;
			EndDo;
		EndIf;
	EndIf;

	// Do receipt movement on begin of time to initialize room quota balances
	vRQRec = RegisterRecords.RoomQuotaSales.AddReceipt();
	FillRQInitializationAttributes(vRQRec, '20000101', pPeriod.RoomQuota, pPeriod.RoomType, pPeriod.Room);
		
	// Do receipt initialization movements on each day from the room quota period
	If vRHCheckInDate < vRHCheckOutDate Then
		vCurDate = cm0SecondShift(vRHCheckInDate);
		While vCurDate <= vRHCheckOutDate Do
			vRQRec = RegisterRecords.RoomQuotaSales.AddReceipt();
			FillRQInitializationAttributes(vRQRec, vCurDate, pPeriod.RoomQuota, pPeriod.RoomType, pPeriod.Room);
			vCurDate = vCurDate + 24*3600;
		EndDo;		
	EndIf;
EndProcedure // PostToRoomQuotaSales

// -----------------------------------------------------------------------------
Procedure pmPostToInventoryRegisters(pPeriods, pPeriod, pPostForecastSales = False, pCancel = False) Export
	// If accommodation is active
	If AccommodationStatus.IsActive Then
		// Calculate the effective number of rooms to write off
		vPrevEffectiveNumberOfRoomsRow = Undefined;
		vNextEffectiveNumberOfRoomsRow = Undefined;
		vEffectiveNumberOfRooms = cmCalculateEffectiveNumberOfRoomsForAccommodation(pPeriod);
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
			PostToRoomInventory(pCancel, pPeriods, pPeriod, vEffectiveNumberOfRoomsRow, vPrevEffectiveNumberOfRoomsRow, vNextEffectiveNumberOfRoomsRow);
			// To the room quota sales
			If ValueIsFilled(pPeriod.RoomQuota) Then
				PostToRoomQuotaSales(pCancel, pPeriod, vEffectiveNumberOfRoomsRow);
			EndIf;
			// Next row
			i = i + 1;
		EndDo;
		// Write RegisterRecords	
		RegisterRecords.RoomInventory.Write();
		RegisterRecords.RoomQuotaSales.Write();
		RegisterRecords.ExpectedGuestGroups.Write();
		RegisterRecords.RoomInventory.Write = False;
		RegisterRecords.RoomQuotaSales.Write = False;
		RegisterRecords.ExpectedGuestGroups.Write = False;
	EndIf;
EndProcedure // pmPostToInventoryRegisters

// -----------------------------------------------------------------------------
Function DoChargeTransfer(pServiceRow, pChargeRow, pServiceDateMove = 0)
	vChargeFolio = pChargeRow.Folio;
	vServiceFolio = pServiceRow.Folio;
	vChargeParentDoc = pChargeRow.ParentDoc;
	If vChargeFolio <> vServiceFolio Or TypeOf(vChargeParentDoc) <> TypeOf(Ref) Then
		vChargeObj = pChargeRow.Ref.GetObject();
		FillPropertyValues(vChargeObj, pServiceRow, , "Folio");
		If Not ValueIsFilled(pChargeRow.ChargeTransfer) Then
			vChargeObj.Folio = vServiceFolio;
		EndIf;
		If TypeOf(vChargeParentDoc) <> TypeOf(Ref) Then
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
			vChargeObj.CorrectedCharge = Undefined;
			vChargeObj.SetTime(AutoTimeMode.DontUse);
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
EndProcedure // DeleteCharge

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
		vServiceDateMove = cmGetServiceDateMove(vQuantityCalculationRule, vQuantityCalculationRuleType, vChargeMealsAtFirstDay, vServiceRow.IsManual, ThisObject, True, vAccountingDateMove);
		// Check if this service has to be charged by external system
		If vActualAmountIsChargedExternally Then
			If vServiceRow.AccountingDate < vCurrentAccountingDate Or Not AccommodationStatus.IsInHouse Then
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
Procedure pmChargeServices(pCancel, pPostingMode) Export
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
	vCloseOfDayMode = False;
	vAccountingDate = '00010101';
	vServicesTab = Services.Unload();
	// Remove services with 0 quantity
	i = 0;
	While i < vServicesTab.Count() Do
		vSrvRow = vServicesTab.Get(i);
		If vSrvRow.Quantity = 0 Then
			vServicesTab.Delete(i);
		Else
			i = i + 1;
		EndIf;
	EndDo;
	// Remove future services if charging should be done by close of period
	If ValueIsFilled(Hotel) And ValueIsFilled(Hotel.AccountingDate) And ValueIsFilled(RoomRate) And 
	   ValueIsFilled(AccommodationStatus) And AccommodationStatus.IsActive And AccommodationStatus.IsInHouse Then
		If (Hotel.CloseOfPeriodDoChargeServices Or RoomRate.CloseOfPeriodDoChargeServices) Then
			If AdditionalProperties.Property("CloseOfDayMode") And AdditionalProperties.CloseOfDayMode Then
				vCloseOfDayMode = AdditionalProperties.CloseOfDayMode;
			EndIf;
			vAccountingDate = Hotel.AccountingDate;
			If ValueIsFilled(vAccountingDate) And AdditionalProperties.Property("AccountingDate") Then
				If ValueIsFilled(AdditionalProperties.AccountingDate) And TypeOf(AdditionalProperties.AccountingDate) = Type("Date") Then
					vAccountingDate = AdditionalProperties.AccountingDate;
				EndIf;
			EndIf;
			i = 0;
			While i < vServicesTab.Count() Do
				vSrvRow = vServicesTab.Get(i);
				vSrvRowFolio = vSrvRow.Folio;
				If Not vSrvRow.Service.AlwaysChargeInAdvance And 
				  (Not vCloseOfDayMode And vSrvRow.AccountingDate >= vAccountingDate And vSrvRow.AccountingDate > DoChargingToDate And vAccountingDate < BegOfDay(CheckOutDate) And BegOfDay(CurrentSessionDate()) < BegOfDay(CheckOutDate) Or 
				   vCloseOfDayMode And vSrvRow.AccountingDate > vAccountingDate And vSrvRow.AccountingDate > DoChargingToDate And vAccountingDate < BegOfDay(CheckOutDate) And BegOfDay(CurrentSessionDate()) < BegOfDay(CheckOutDate)) And 
				  (Not ValueIsFilled(vSrvRowFolio) Or ValueIsFilled(vSrvRowFolio) And Not ValueIsFilled(vSrvRowFolio.PaymentMethod) Or ValueIsFilled(vSrvRowFolio) And ValueIsFilled(vSrvRowFolio.PaymentMethod) And Not vSrvRowFolio.PaymentMethod.ChargeServicesInAdvance) Then
					vServicesTab.Delete(i);
				Else
					i = i + 1;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	// If charges were posted by reservation then do nothing
	vParentRes = pmGetParentReservation();
	If ValueIsFilled(vParentRes) And vParentRes.Posted Then
		vDoCharging = True;
		If vParentRes.DoCharging And 
		   ValueIsFilled(vParentRes.ReservationStatus) And 
		   Not vParentRes.ReservationStatus.DoNoShowCharging And 
		   Not vParentRes.ReservationStatus.DoLateAnnulationCharging And 
		   ValueIsFilled(Hotel) And ValueIsFilled(Hotel.CheckInReservationStatus) And Hotel.CheckInReservationStatus.DoCharging Then
			vDoCharging = False;
		EndIf;
		If Not vDoCharging Then
			vServicesTab.Clear();
			vChargesTab.Clear();
		EndIf;
	EndIf;
	
	// Add analitical dimensions to the services table
	cmAddServicesDimensionsColumns(vServicesTab);
	
	// If accommodation is active
	If AccommodationStatus.IsActive Then
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
	Else
		vServicesTab.Clear();
	EndIf;
	
	// 3. Build difference table between already charged services and 
	// services in the document. We will do it ignoring folios.
	vServicesDifferenceTab = cmGetServicesDifference(vServicesTab, vChargesTab);
	
	// 4. Create charging for each service in difference services
	ChargeServiceDifferences(vServicesDifferenceTab, vServicesTab, vChargesTab);
	
	// 5. Repost storno for changed charges
	If ChargesToRepostStorno.Count() > 0 Then
		RepostStornosForChangedCharges();
	EndIf;
EndProcedure // pmChargeServices

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
Function pmGetCheckInDate() Export
	vCheckInDate = CheckInDate;
	If ParentDoc = Ref Then
		ParentDoc = Undefined;
	EndIf;
	vParentDoc = ParentDoc;
	While ValueIsFilled(vParentDoc) Do
		If TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Then
			vCheckInDate = Min(vCheckInDate, vParentDoc.CheckInDate);
			vParentDoc = vParentDoc.ParentDoc;
		ElsIf TypeOf(vParentDoc) = Type("DocumentRef.Reservation") And 
		      ValueIsFilled(vParentDoc.ParentDoc) And 
			  TypeOf(vParentDoc.ParentDoc) = Type("DocumentRef.Reservation") Then
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	Accommodation.Ref
			|FROM
			|	Document.Accommodation AS Accommodation
			|WHERE
			|	Accommodation.Posted
			|	AND Accommodation.AccommodationStatus.IsActive
			|	AND Accommodation.ParentDoc = &qParentDoc
			|ORDER BY
			|	Accommodation.PointInTime";
			vQry.SetParameter("qParentDoc", vParentDoc.ParentDoc);
			vQryRes = vQry.Execute().Unload();
			If vQryRes.Count() > 0 Then
				vParentDoc = vQryRes.Get(0).Ref;
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
EndFunction // pmGetCheckInDate

// -----------------------------------------------------------------------------
Function pmGetParentReservation() Export
	vParentRes = Documents.Reservation.EmptyRef();
	vParentDoc = ParentDoc;
	While ValueIsFilled(vParentDoc) Do
		If TypeOf(vParentDoc) = Type("DocumentRef.Reservation") Then
			vParentRes = vParentDoc;
			Break;
		Else
			vParentDoc = vParentDoc.ParentDoc;
		EndIf;
	EndDo;
	Return vParentRes;
EndFunction // pmGetParentReservation

// -----------------------------------------------------------------------------
Function pmGetNextAccommodationInChain(pAccommodation = Undefined) Export
	// Initialize input parameter
	If Not ValueIsFilled(pAccommodation) Then
		pAccommodation = Ref;
	EndIf;
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	AccommodationsByDocs.Ref AS Ref,
	|	AccommodationsByDocs.PointInTime AS PointInTime
	|FROM
	|	(SELECT
	|		Accommodation.Ref AS Ref,
	|		Accommodation.PointInTime AS PointInTime
	|	FROM
	|		Document.Accommodation AS Accommodation
	|	WHERE
	|		Accommodation.ParentDoc = &qDoc
	|		AND Accommodation.Posted
	|		AND ISNULL(Accommodation.AccommodationStatus.IsActive, FALSE)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Accommodation.Ref,
	|		Accommodation.PointInTime
	|	FROM
	|		Document.Accommodation AS Accommodation
	|	WHERE
	|		&qReservationIsFilled
	|		AND Accommodation.Reservation.ParentDoc = &qReservation
	|		AND Accommodation.Posted
	|		AND ISNULL(Accommodation.AccommodationStatus.IsActive, FALSE)) AS AccommodationsByDocs
	|		INNER JOIN (SELECT
	|			AccommodationsByGuest.Ref AS Ref
	|		FROM
	|			(SELECT
	|				Accommodation.Ref AS Ref
	|			FROM
	|				Document.Accommodation AS Accommodation
	|			WHERE
	|				Accommodation.Guest = &qGuest
	|				AND Accommodation.Posted
	|				AND ISNULL(Accommodation.AccommodationStatus.IsActive, FALSE)
	|			
	|			UNION ALL
	|			
	|			SELECT
	|				Accommodation.Ref
	|			FROM
	|				Document.Accommodation AS Accommodation
	|			WHERE
	|				ISNULL(Accommodation.GuestFullName, &qEmptyString) = &qGuestFullName
	|				AND &qGuestFullName <> &qEmptyString
	|				AND Accommodation.Posted
	|				AND ISNULL(Accommodation.AccommodationStatus.IsActive, FALSE)) AS AccommodationsByGuest) AS AccommodationsByGuests
	|		ON AccommodationsByDocs.Ref = AccommodationsByGuests.Ref
	|
	|ORDER BY
	|	AccommodationsByDocs.PointInTime DESC";
	vQry.SetParameter("qDoc", pAccommodation);
	vQry.SetParameter("qGuest", pAccommodation.Guest);
	vQry.SetParameter("qGuestFullName", ?(ValueIsFilled(pAccommodation.Guest), TrimAll(pAccommodation.Guest.FullName), ""));
	vQry.SetParameter("qEmptyString", "");
	vQry.SetParameter("qReservation", pAccommodation.Reservation);
	vQry.SetParameter("qReservationIsFilled", ValueIsFilled(pAccommodation.Reservation));
	vNextDocs = vQry.Execute().Unload();
	If vNextDocs.Count() > 0 Then
		Return vNextDocs.Get(0).Ref;
	Else
		Return Undefined;
	EndIf;
EndFunction // pmGetNextAccommodationInChain

// -----------------------------------------------------------------------------
Function pmGetLastAccommodationInChain() Export
	vLastAccInChain = Undefined;
	If ValueIsFilled(AccommodationStatus) And AccommodationStatus.IsActive Then
		vLastAccInChain = Ref;
	EndIf;
	vNextAccInChain = pmGetNextAccommodationInChain();
	While ValueIsFilled(vNextAccInChain) Do
		vLastAccInChain = vNextAccInChain;
		vNextAccInChain = pmGetNextAccommodationInChain(vNextAccInChain);
	EndDo;
	If Not ValueIsFilled(vLastAccInChain) Then
		// Current accommodation is not active and there are no active accommodations after it
		// So, try to check previous one
		vParentAcc = ParentDoc;
		While ValueIsFilled(vParentAcc) And TypeOf(vParentAcc) = Type("DocumentRef.Accommodation") And 
		      (Not vParentAcc.Posted Or Not ValueIsFilled(vParentAcc.AccommodationStatus) Or
		       (ValueIsFilled(vParentAcc.AccommodationStatus) And Not vParentAcc.AccommodationStatus.IsActive)) Do
			vParentAcc = vParentAcc.ParentDoc;
		EndDo;
		If ValueIsFilled(vParentAcc) And TypeOf(vParentAcc) = Type("DocumentRef.Accommodation") And 
		   vParentAcc.Posted And ValueIsFilled(vParentAcc.AccommodationStatus) And vParentAcc.AccommodationStatus.IsActive Then
			vLastAccInChain = vParentAcc;
		EndIf;
	EndIf;
	Return vLastAccInChain;
EndFunction // pmGetLastAccommodationInChain 

// -----------------------------------------------------------------------------
Function pmGetAccommodationByReservation(pReservation) Export
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.ParentDoc = &qDoc
	|	AND Accommodation.Posted
	|	AND ISNULL(Accommodation.AccommodationStatus.IsActive, FALSE)
	|
	|ORDER BY
	|	Accommodation.PointInTime";
	vQry.SetParameter("qDoc", pReservation);
	vAccDocs = vQry.Execute().Unload();
	If vAccDocs.Count() > 0 Then
		Return vAccDocs.Get(0).Ref;
	Else
		Return Undefined;
	EndIf;
EndFunction // pmGetAccommodationByReservation

// -----------------------------------------------------------------------------
Function pmGetFirstAccommodationInChain() Export
	vFirstAccInChain = Ref;
	While ValueIsFilled(vFirstAccInChain.ParentDoc) Do
		If TypeOf(vFirstAccInChain.ParentDoc) = Type("DocumentRef.Accommodation") Then
			vFirstAccInChain = vFirstAccInChain.ParentDoc;
		Else
			If ValueIsFilled(vFirstAccInChain.Reservation) And ValueIsFilled(vFirstAccInChain.Reservation.ParentDoc) Then
				If TypeOf(vFirstAccInChain.Reservation.ParentDoc) = Type("DocumentRef.Reservation") Then
					vDocRef = pmGetAccommodationByReservation(vFirstAccInChain.Reservation.ParentDoc);
					If ValueIsFilled(vDocRef) And TypeOf(vDocRef) = Type("DocumentRef.Accommodation") Then
						vFirstAccInChain = vDocRef;
					Else
						Break;
					EndIf;
				Else
					Break;
				EndIf;
			Else
				Break;
			EndIf;
		EndIf;
	EndDo;
	Return vFirstAccInChain;
EndFunction // pmGetFirstAccommodationInChain

// -----------------------------------------------------------------------------
Procedure FillFolioParameters(pCancel)
	// Get last accommodation in chain and use it to set folio parameters
	vLastAccommodation = pmGetLastAccommodationInChain();
	If Not ValueIsFilled(vLastAccommodation) Then
		// This is annulated accommodation
		If ValueIsFilled(AccommodationStatus) And Not AccommodationStatus.IsActive And 
		   ValueIsFilled(ParentDoc) And TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Then
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
							vFolioIsChanged = False;
							vFolioObj = vFolioRef.GetObject();
							vFolioObj.Read();
							// Update parent document in charging folios back to reservation
							If ParentDoc.ChargingRules.Find(vFolioRef, "ChargingFolio") <> Undefined Then
								vFolioObj.ParentDoc = ParentDoc;
								If ParentDoc.Posted And ValueIsFilled(ParentDoc.ReservationStatus) Then
									vFolioObj.IsClosed = Not ParentDoc.ReservationStatus.IsActive;
								Else
									vFolioObj.IsClosed = True;
								EndIf;
								vFolioIsChanged = True;
							EndIf;
							If vFolioObj.DeletionMark Then
								vFolioObj.DeletionMark = False;
								vFolioIsChanged = True;
							EndIf;
							If vFolioObj.LineNumber <> (ChargingRules.IndexOf(vCRRec) + 1) Then
								vFolioObj.LineNumber = ChargingRules.IndexOf(vCRRec) + 1;
								vFolioIsChanged = True;
							EndIf;
							// Save changes if folio object was changed
							If vFolioIsChanged Then
								vFolioObj.AdditionalProperties.Insert("SkipCheckOfAnaliticalParametersChange", True);
								vFolioObj.Write(DocumentWriteMode.Write);
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		Return;
	EndIf;
	// Process folios from charging rules
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
					vDoCheckOfAnaliticalParametersChange = False;
					vFolioIsChanged = False;
					vFolioObj = vFolioRef.GetObject();
					vFolioObj.Read();
					If vFolioObj.Hotel <> vLastAccommodation.Hotel Then
						vFolioObj.Hotel = vLastAccommodation.Hotel;
						vFolioIsChanged = True;
					EndIf;
					If Not vFolioObj.DoNotUpdateCompany Then
						If ValueIsFilled(vLastAccommodation.Room) And ValueIsFilled(vLastAccommodation.Room.Company) Or
						   ValueIsFilled(vLastAccommodation.RoomType) And ValueIsFilled(vLastAccommodation.RoomType.Company) Or 
						   ValueIsFilled(vLastAccommodation.RoomRate) And ValueIsFilled(vLastAccommodation.RoomRate.Company) Or
						   (ValueIsFilled(vLastAccommodation.Room) And Not ValueIsFilled(vLastAccommodation.Room.Company) And 
						    ValueIsFilled(vLastAccommodation.RoomType) And Not ValueIsFilled(vLastAccommodation.RoomType.Company) And 
							ValueIsFilled(vLastAccommodation.RoomRate) And Not ValueIsFilled(vLastAccommodation.RoomRate.Company)) Then
							If vFolioObj.Company <> vLastAccommodation.Company Then
								vFolioObj.Company = vLastAccommodation.Company;
								vDoCheckOfAnaliticalParametersChange = True;
								vFolioIsChanged = True;
							EndIf;
						EndIf;
					EndIf;
					If ValueIsFilled(AccommodationStatus) Then
						If AccommodationStatus.IsActive Then
							If vFolioObj.ParentDoc <> vLastAccommodation Then
								vFolioObj.ParentDoc = vLastAccommodation;
								vFolioIsChanged = True;
							EndIf;
						EndIf;
					EndIf;
					If TypeOf(vCRRec.Owner) <> Type("CatalogRef.Clients") Then
						If vFolioObj.Client <> vLastAccommodation.Guest Then
							vFolioObj.Client = vLastAccommodation.Guest;
							vFolioIsChanged = True;
						EndIf;
					EndIf;
					If vFolioObj.GuestGroup <> vLastAccommodation.GuestGroup Then
						vFolioObj.GuestGroup = vLastAccommodation.GuestGroup;
						vFolioIsChanged = True;
					EndIf;
					If TypeOf(vCRRec.Owner) <> Type("CatalogRef.Rooms") Then
						If vFolioObj.Room <> vLastAccommodation.Room Then
							vFolioObj.Room = vLastAccommodation.Room;
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
					vDateTimeTo = vLastAccommodation.CheckOutDate;
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
							If ValueIsFilled(vLastAccommodation.PlannedPaymentMethod) Then
								If vFolioObj.PaymentMethod <> vLastAccommodation.PlannedPaymentMethod Then
									vFolioObj.PaymentMethod = vLastAccommodation.PlannedPaymentMethod;
									vFolioIsChanged = True;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
					If vFolioObj.Agent <> vLastAccommodation.Agent Then
						vFolioObj.Agent = vLastAccommodation.Agent;
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
					// Save changes if folio object was changed
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
	vResFolios = New ValueTable();
	If ValueIsFilled(Reservation) Then
		vResFolios = cmGetActiveDocumentFolios(Reservation);
		If vResFolios.Count() > 0 Then
			For Each vResFoliosRow In vResFolios Do
				If vFolios.Find(vResFoliosRow.Folio, "Folio") = Undefined Then
					vFoliosRow = vFolios.Add();
					FillPropertyValues(vFoliosRow, vResFoliosRow);
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	If ValueIsFilled(ParentDoc) And ParentDoc <> Reservation Then
		vParFolios = cmGetActiveDocumentFolios(ParentDoc);
		If vParFolios.Count() > 0 Then
			For Each vParFoliosRow In vParFolios Do
				If vFolios.Find(vParFoliosRow.Folio, "Folio") = Undefined Then
					vFoliosRow = vFolios.Add();
					FillPropertyValues(vFoliosRow, vParFoliosRow);
				EndIf;
			EndDo;
		EndIf;
	EndIf;
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
			If vFolioObj.Hotel <> vLastAccommodation.Hotel Then
				vFolioObj.Hotel = vLastAccommodation.Hotel;
				vDoCheckOfAnaliticalParametersChange = True;
				vFolioIsChanged = True;
			EndIf;
			If Not vFolioObj.IsMaster Then
				If Not vFolioObj.DoNotUpdateCompany Then
					If ValueIsFilled(vLastAccommodation.Room) And ValueIsFilled(vLastAccommodation.Room.Company) Or
					   ValueIsFilled(vLastAccommodation.RoomType) And ValueIsFilled(vLastAccommodation.RoomType.Company) Or 
					   ValueIsFilled(vLastAccommodation.RoomRate) And ValueIsFilled(vLastAccommodation.RoomRate.Company) Or
					   (ValueIsFilled(vLastAccommodation.Room) And Not ValueIsFilled(vLastAccommodation.Room.Company) And 
					    ValueIsFilled(vLastAccommodation.RoomType) And Not ValueIsFilled(vLastAccommodation.RoomType.Company) And 
						ValueIsFilled(vLastAccommodation.RoomRate) And Not ValueIsFilled(vLastAccommodation.RoomRate.Company)) Then
						If vFolioObj.Company <> vLastAccommodation.Company Then
							vFolioObj.Company = vLastAccommodation.Company;
							vDoCheckOfAnaliticalParametersChange = True;
							vFolioIsChanged = True;
						EndIf;
					EndIf;
				EndIf;
				If ValueIsFilled(AccommodationStatus) Then
					If AccommodationStatus.IsActive Then
						If vFolioObj.ParentDoc <> vLastAccommodation Then
							vFolioObj.ParentDoc = vLastAccommodation;
							vFolioIsChanged = True;
						EndIf;
					EndIf;
				EndIf;
				If vFolioObj.Client <> vLastAccommodation.Guest Then
					vFolioObj.Client = vLastAccommodation.Guest;
					vFolioIsChanged = True;
				EndIf;
				If vFolioObj.GuestGroup <> vLastAccommodation.GuestGroup Then
					vFolioObj.GuestGroup = vLastAccommodation.GuestGroup;
					vFolioIsChanged = True;
				EndIf;
				If vFolioObj.Room <> vLastAccommodation.Room Then
					vFolioObj.Room = vLastAccommodation.Room;
					vFolioIsChanged = True;
				EndIf;
				vDateTimeFrom = pmGetCheckInDate();
				If vFolioObj.DateTimeFrom <> vDateTimeFrom Then
					vFolioObj.DateTimeFrom = vDateTimeFrom;
					vFolioIsChanged = True;
				EndIf;
				vDateTimeTo = vLastAccommodation.CheckOutDate;
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
	// Update folio statuses
	If vLastAccommodation <> Ref Then
		vLastAccommodation.GetObject().pmSetFolioStatuses();
	EndIf;
EndProcedure // FillFolioParameters

// -----------------------------------------------------------------------------
Procedure DoChangeRoomStatus(pRoomStatus, pRoom = Undefined, pDoNotUpdateOperation = False)
	// Update status for room
	vRoomObj = Undefined;
	If ValueIsFilled(pRoom) Then
		vRoomObj = pRoom.GetObject();
	Else
		vRoomObj = Room.GetObject();
	EndIf;
	If vRoomObj.RoomStatus <> pRoomStatus Then
		vRoomObj.Read();
		vRoomObj.RoomStatus = pRoomStatus;
		vRoomObj.Write();
		
		// Add record to the room status change history
		If ValueIsFilled(Hotel) And ValueIsFilled(pRoom) Then
			// This is room change operation
			vRoomObj.pmWriteToRoomStatusChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser, TrimAll(Hotel.ChangeRoomAccommodationStatus) + " - " + TrimAll(Guest) + " - " + String(Ref), , pDoNotUpdateOperation);
		Else
			vRoomObj.pmWriteToRoomStatusChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser, TrimAll(AccommodationStatus) + " - " + TrimAll(Guest) + " - " + String(Ref), , pDoNotUpdateOperation);
		EndIf;
	EndIf;
EndProcedure // DoChangeRoomStatus

// -----------------------------------------------------------------------------
Procedure ChangeRoomStatus(pCancel, pPostingMode)
	If ValueIsFilled(Hotel) Then
		// Change status of the current room
		If ValueIsFilled(Room) Then
			If ValueIsFilled(AccommodationStatus) Then
				If AccommodationStatus.IsActive And AccommodationStatus.IsInHouse Then
					If Room.RoomStatus <> Hotel.OccupiedRoomStatus And 
					  (Room.RoomStatus <> Hotel.RoomStatusDueOut Or Not ValueIsFilled(Hotel.RoomStatusDueOut)) And 
					  (Room.RoomStatus <> Hotel.OccupiedDirtyRoomStatus Or Not ValueIsFilled(Hotel.OccupiedDirtyRoomStatus)) And 
					  (Room.RoomStatus <> Hotel.RoomStatusAfterEarlyCheckIn Or Not ValueIsFilled(Hotel.RoomStatusAfterEarlyCheckIn)) Then
						If ValueIsFilled(Hotel.RoomStatusAfterCheckOut) And 
						   ValueIsFilled(Hotel.OccupiedDirtyRoomStatus) And 
						   Room.RoomStatus = Hotel.RoomStatusAfterCheckOut Then
							DoChangeRoomStatus(Hotel.OccupiedDirtyRoomStatus, , True);
						Else
							DoChangeRoomStatus(Hotel.OccupiedRoomStatus);
						EndIf;
					EndIf;
				ElsIf Not AccommodationStatus.IsActive Then
					If (Room.RoomStatus = Hotel.OccupiedRoomStatus) Or 
					   (Room.RoomStatus = Hotel.RoomStatusDueOut And ValueIsFilled(Hotel.RoomStatusDueOut)) And 
					   (Room.RoomStatus = Hotel.OccupiedDirtyRoomStatus And ValueIsFilled(Hotel.OccupiedDirtyRoomStatus)) Or
					   (Room.RoomStatus = Hotel.RoomStatusAfterEarlyCheckIn And ValueIsFilled(Hotel.RoomStatusAfterEarlyCheckIn)) Or 
					   (ValueIsFilled(Room.RoomStatus) And ValueIsFilled(Room.RoomStatus.NextRoomStatus) And Room.RoomStatus.NextRoomStatus = Hotel.RoomStatusAfterCheckOut) Then
						// Try to restore previous room status if check-in was less then 15 minutes ago and 
						// current accommodation is last in-house accommodation in the room
						vThereAreOtherGuestsInTheRoom = False;
						vInHouseGuests = Room.GetObject().pmGetInHouseGuests();
						For Each vInHouseGuestsRow In vInHouseGuests Do
							If vInHouseGuestsRow.Accommodation <> Ref Then
								vThereAreOtherGuestsInTheRoom = True;
								Break;
							EndIf;
						EndDo;
						If Not vThereAreOtherGuestsInTheRoom Then
							vRestoreRoomStatus = False;
							vRoomCheckInTime = Undefined;
							vPrevAccStates = pmGetAccommodationAttributes(CurrentSessionDate());
							If vPrevAccStates.Count() > 0 Then
								vPrevAccStateRow = vPrevAccStates.Get(0);
								While ValueIsFilled(vPrevAccStateRow.Room) And vPrevAccStateRow.Room = Room Do
									vRoomCheckInTime = vPrevAccStateRow.Period;
									vPrevAccStates = pmGetAccommodationAttributes(New Boundary(vPrevAccStateRow.Period, BoundaryType.Excluding));
									If vPrevAccStates.Count() = 0 Then
										Break;
									Else
										vPrevAccStateRow = vPrevAccStates.Get(0);
									EndIf;
								EndDo;
								vAllowedAnnulationDelayTime = 0;
								If ValueIsFilled(SessionParameters.CurrentUser) Then
									vPermissionGroup = cmGetEmployeePermissionGroup(SessionParameters.CurrentUser);
									If ValueIsFilled(vPermissionGroup) Then
										vAllowedAnnulationDelayTime = vPermissionGroup.AllowedAnnulationDelayTime;
									EndIf;
								EndIf;
								If ValueIsFilled(vRoomCheckInTime) And (CurrentSessionDate() - vRoomCheckInTime) <= (vAllowedAnnulationDelayTime * 60) Then
									vRoomPrevStatuses = Room.GetObject().pmGetRoomStatusHistoryState(vRoomCheckInTime, Room.RoomStatus);
									If vRoomPrevStatuses.Count() > 0 Then
										vRoomPrevStatusRow = vRoomPrevStatuses.Get(0);
										If ValueIsFilled(vRoomPrevStatusRow.RoomStatus) Then
											// Set previous room status to the room status after check-out
											DoChangeRoomStatus(vRoomPrevStatusRow.RoomStatus);
											vRestoreRoomStatus = True;
										EndIf;
									EndIf;
								EndIf;
							EndIf;
							// Else set room status to the room status after check-out
							If Not vRestoreRoomStatus Then
								DoChangeRoomStatus(Hotel.RoomStatusAfterCheckOut);
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		// Check if there was room change
		vPrevAccStates = pmGetAccommodationAttributes(CurrentSessionDate());
		If vPrevAccStates.Count() > 0 Then
			vPrevAccStateRow = vPrevAccStates.Get(0);
			If ValueIsFilled(vPrevAccStateRow.Room) And vPrevAccStateRow.Room <> Room And 
			  (vPrevAccStateRow.Room.RoomStatus = Hotel.OccupiedRoomStatus Or 
			   vPrevAccStateRow.Room.RoomStatus = Hotel.RoomStatusDueOut And ValueIsFilled(Hotel.RoomStatusDueOut) Or
			   vPrevAccStateRow.Room.RoomStatus = Hotel.OccupiedDirtyRoomStatus And ValueIsFilled(Hotel.OccupiedDirtyRoomStatus) Or
			   vPrevAccStateRow.Room.RoomStatus = Hotel.RoomStatusAfterEarlyCheckIn And ValueIsFilled(Hotel.RoomStatusAfterEarlyCheckIn) Or 
			   ValueIsFilled(vPrevAccStateRow.Room.RoomStatus) And ValueIsFilled(vPrevAccStateRow.Room.RoomStatus.NextRoomStatus) And vPrevAccStateRow.Room.RoomStatus.NextRoomStatus = Hotel.RoomStatusAfterCheckOut) Then
				// Set previous room status to the room status after check-out
				vThereAreOtherGuestsInTheRoom = False;
				vInHouseGuests = vPrevAccStateRow.Room.GetObject().pmGetInHouseGuests();
				For Each vInHouseGuestsRow In vInHouseGuests Do
					If vInHouseGuestsRow.Accommodation <> Ref Then
						vThereAreOtherGuestsInTheRoom = True;
						Break;
					EndIf;
				EndDo;
				If Not vThereAreOtherGuestsInTheRoom Then
					DoChangeRoomStatus(Hotel.RoomStatusAfterCheckOut, vPrevAccStateRow.Room);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ChangeRoomStatus

// -----------------------------------------------------------------------------
Procedure MoveGuests(pCancel, pPostingMode)
	If ValueIsFilled(Guest) Then
		vDoWrite = False;
		vGuestObj = Undefined;
		If ValueIsFilled(AccommodationStatus) Then
			If AccommodationStatus.IsActive And AccommodationStatus.IsInHouse Then
				If Guest.Parent <> Catalogs.Clients.CheckedInGuests And 
				   Guest.Parent <> Catalogs.Clients.BlackListPersons Then
					vGuestObj = Guest.GetObject();
					vGuestObj.Read();
					vGuestObj.Parent = Catalogs.Clients.CheckedInGuests;
					vDoWrite = True;
				EndIf;
			Else
				If Guest.Parent <> Catalogs.Clients.CheckedOutGuests And
				   Guest.Parent <> Catalogs.Clients.BlackListPersons Then
					vGuestObj = Guest.GetObject();
					vGuestObj.Read();
					vGuestObj.Parent = Catalogs.Clients.CheckedOutGuests;
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
EndProcedure // MoveGuests

// -----------------------------------------------------------------------------
Procedure CancelParentReservation()
	If ValueIsFilled(Hotel) Then
		If ValueIsFilled(ParentDoc) Then
			If TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Then
				If ParentDoc.Posted Then
					If ValueIsFilled(ParentDoc.ReservationStatus) Then
						If AccommodationStatus.IsActive Then
							vGuestIsChanged = False;
							vSetCheckInStatus = False;
							vParentResObj = Undefined;
							If ParentDoc.ReservationStatus.IsActive Or ParentDoc.ReservationStatus.IsPreliminary Or ParentDoc.ReservationStatus = Hotel.NoShowReservationStatus Then
								vRepostReservation = False;
								vSetRoomIsUsedInRooms = False;
								vResetRoomIsUsedInRooms = False;
								If ParentDoc.NumberOfPersons <= NumberOfPersons Then
									vSetCheckInStatus = True;
									vRepostReservation = True;
								Else
									// Calculate write offs done by accommodations based on this reservation
									vWriteOffs = cmGetWriteOffsForReservation(ParentDoc);
									vNumberOfPersonsToWriteOff = 0;
									If vWriteOffs.Count() > 0 Then
										For Each vWriteOffRow In vWriteOffs Do
											vNumberOfPersonsToWriteOff = vNumberOfPersonsToWriteOff + vWriteOffRow.GuestsCheckedIn;
										EndDo;
									EndIf;
									If (ParentDoc.NumberOfPersons - vNumberOfPersonsToWriteOff) <= NumberOfPersons Then
										vSetCheckInStatus = True;
										vRepostReservation = True;
									Endif;
								EndIf;
								If ParentDoc.Rooms.Count() > 0 Then
									// Try to find current room in the reservation rooms list. 
									// If found then check that this room is used
									vRoomsRow = ParentDoc.Rooms.Find(Room, "Room");
									If vRoomsRow <> Undefined Then
										If Not vRoomsRow.IsUsed Then
											vRepostReservation = True;
											vSetRoomIsUsedInRooms = True;
										EndIf;
									EndIf;
									// Try to find current accommodation in the reservation rooms list. 
									// If found then check that this room is the same as room in accommodation.
									vRoomsRow = ParentDoc.Rooms.Find(Ref, "Accommodation");
									If vRoomsRow <> Undefined Then
										If vRoomsRow.Room <> Room Then
											vRepostReservation = True;
											vResetRoomIsUsedInRooms = True;
										EndIf;
									EndIf;
								EndIf;
								If vRepostReservation Then
									vParentResObj = ParentDoc.GetObject();
									vParentResObj.Read();
									If vSetCheckInStatus Then
										vParentResObj.ReservationStatus = Hotel.CheckInReservationStatus;
										vParentResObj.pmSetDoCharging();
									EndIf;
									If ValueIsFilled(Guest) And AccommodationStatus.IsCheckIn And vParentResObj.NumberOfPersons = 1 And 
									   vParentResObj.Guest <> Guest And Not IsBlankString(Guest.IdentityDocumentNumber) Then
										vGuestIsChanged = True;
										vParentResObj.Guest = Guest;
									EndIf;
									If vResetRoomIsUsedInRooms Then
										vRoomsRow = vParentResObj.Rooms.Find(Ref, "Accommodation");
										If vRoomsRow <> Undefined Then
											vRoomsRow.IsUsed = False;
											vRoomsRow.Accommodation = Documents.Accommodation.EmptyRef();
										EndIf;
									EndIf;
									If vSetRoomIsUsedInRooms Then
										vRoomsRow = vParentResObj.Rooms.Find(Room, "Room");
										If vRoomsRow <> Undefined Then
											vRoomsRow.IsUsed = True;
											vRoomsRow.Accommodation = Ref;
										EndIf;
									EndIf;
									vParentResObj.AdditionalProperties.Insert("SkipMainDocTouristTaxUpdate", True);
									vParentResObj.Write(DocumentWriteMode.Posting);
									// Save reservation data in change history if reservation status was changed
									If vSetCheckInStatus Or vGuestIsChanged Then
										vParentResObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
									EndIf;
								EndIf;
							ElsIf ParentDoc.ReservationStatus = Hotel.CheckInReservationStatus Then
								If ValueIsFilled(Guest) And AccommodationStatus.IsCheckIn And ParentDoc.NumberOfPersons = 1 And 
								   ParentDoc.Guest <> Guest And Not IsBlankString(Guest.IdentityDocumentNumber) Then
									vGuestIsChanged = True;
									vParentResObj = ParentDoc.GetObject();
									vParentResObj.Read();
									vParentResObj.Guest = Guest;
									vParentResObj.AdditionalProperties.Insert("SkipMainDocTouristTaxUpdate", True);
									vParentResObj.Write(DocumentWriteMode.Posting);
									vParentResObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
								EndIf;
							EndIf;
							// Change guest in reservations next in chain to the current one
							If vGuestIsChanged Then
								vNextReservationInChain = vParentResObj.pmGetNextReservationInChain();
								While ValueIsFilled(vNextReservationInChain) Do
									vNextReservationInChainObj = vNextReservationInChain.GetObject();
									vNextReservationInChainObj.Read();
									vNextReservationInChainObj.Guest = Guest;
									vNextReservationInChainObj.AdditionalProperties.Insert("SkipMainDocTouristTaxUpdate", True);
									vNextReservationInChainObj.Write(DocumentWriteMode.Posting);
									// Save reservation data in change history if reservation status was changed
									If vSetCheckInStatus Then
										vNextReservationInChainObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
									EndIf;
									vNextReservationInChain = vNextReservationInChainObj.pmGetNextReservationInChain();
								EndDo;
							EndIf;
						Else
							vRepostReservation = False;
							vSetActiveStatus = False;
							vParentResObj = ParentDoc.GetObject();
							vParentResObj.Read();
							If vParentResObj.Rooms.Count() > 0 Then
								// Try to find current accommodation in the reservation rooms list. 
								// If found then check that this room is the same as room in accommodation.
								vRoomsRow = vParentResObj.Rooms.Find(Ref, "Accommodation");
								If vRoomsRow <> Undefined Then
									If vRoomsRow.Room = Room Then
										vRoomsRow.IsUsed = False;
										vRoomsRow.Accommodation = Documents.Accommodation.EmptyRef();
										vRepostReservation = True;
									EndIf;
								EndIf;
							EndIf;
							// Reset reservation status
							If (BegOfDay(CurrentSessionDate()) - BegOfDay(vParentResObj.CheckInDate)) < (24*3600) And 
							   vParentResObj.ReservationStatus.IsCheckIn Then
								// Try to restore previous reservation status
								vPrevResData = vParentResObj.pmGetReservationHistoryState(CurrentSessionDate());
								If vPrevResData.Count() > 0 Then
									vPrevResDataRow = vPrevResData.Get(0);
									While ValueIsFilled(vPrevResDataRow.ReservationStatus) And 
									      vPrevResDataRow.ReservationStatus.IsCheckIn Do
										vPrevResData = vParentResObj.pmGetReservationHistoryState(New Boundary(vPrevResDataRow.Period, BoundaryType.Excluding));
										If vPrevResData.Count() = 0 Then
											Break;
										Else
											vPrevResDataRow = vPrevResData.Get(0);
										EndIf;
									EndDo;
									If ValueIsFilled(vPrevResDataRow.ReservationStatus) And 
									   vPrevResDataRow.ReservationStatus.IsActive And 
									   Not vPrevResDataRow.ReservationStatus.IsCheckIn Then
										vParentResObj.ReservationStatus = vPrevResDataRow.ReservationStatus;
										vParentResObj.pmSetDoCharging();
										vParentResObj.pmCalculateServices();
										vSetActiveStatus = True;
										vRepostReservation = True;
									EndIf;
								EndIf;
							EndIf;
						    // Write reservation
							If vRepostReservation Then
								vParentResObj.AdditionalProperties.Insert("SkipMainDocTouristTaxUpdate", True);
								vParentResObj.Write(DocumentWriteMode.Posting);
								// Save reservation data in change history if reservation status was changed
								If vSetActiveStatus Then
									vParentResObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
								EndIf;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // CancelParentReservation

// -----------------------------------------------------------------------------
Function pmGetChildReservations() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reservation.Ref AS Reservation
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	Reservation.ParentDoc = &qAccommodation
	|	AND Reservation.Posted
	|	AND (Reservation.ReservationStatus.IsActive
	|			OR Reservation.ReservationStatus.IsPreliminary)
	|
	|ORDER BY
	|	Reservation.PointInTime";
	vQry.SetParameter("qAccommodation", Ref);
	vChildReservations = vQry.Execute().Unload();
	Return vChildReservations;
EndFunction // pmGetChildReservations

// -----------------------------------------------------------------------------
Procedure UpdateChildReservations()
	If Not ValueIsFilled(AccommodationStatus) Or Not ValueIsFilled(Hotel) Then
		Return;
	EndIf;
	vChildReservations = pmGetChildReservations();
	For Each vChildReservationsRow In vChildReservations Do
		vChildReservation = vChildReservationsRow.Reservation;
		vChildReservationObj = vChildReservation.GetObject();
		vChildReservationObj.Read();
		If Not AccommodationStatus.IsInHouse And AccommodationStatus.IsCheckOut Then
			// Cancel reservations
			vChildReservationObj.ReservationStatus = Hotel.NoShowReservationStatus;
			vChildReservationObj.pmSetDoCharging();
		Else
			// Update reservation check-in date or cancel it
			If BegOfDay(vChildReservation.CheckOutDate) > BegOfDay(CheckOutDate) Then
				vSomethingChanged = False;
				If vChildReservation.CheckInDate < CheckOutDate And vChildReservation.Room = Room Then
					vChildReservationObj.CheckInDate = cm1SecondShift(CheckOutDate);
					vChildReservationObj.Duration = vChildReservationObj.pmCalculateDuration();
					vSomethingChanged = True;
				EndIf;
				// Check if room has changed
				If ValueIsFilled(vChildReservationObj.Room) And vChildReservationObj.Room <> Room And BegOfDay(vChildReservation.CheckInDate) = BegOfDay(CheckOutDate) Then
					vChildReservationObj.Room = Room;
					vSomethingChanged = True;
					// Retrieve room resources
					vRoomAttrs = vChildReservationObj.Room.GetObject().pmGetRoomAttributes(cm1SecondShift(vChildReservationObj.CheckInDate));
					For Each vRoomAttrsRow In vRoomAttrs Do
						vChildReservationObj.RoomType = vRoomAttrsRow.RoomType;
						Break;
					EndDo;
					// Check if hotel was changed
					If ValueIsFilled(vChildReservationObj.RoomType) Then
						If vChildReservationObj.RoomType.Owner <> vChildReservationObj.Hotel Then
							vChildReservationObj.Hotel = vChildReservationObj.RoomType.Owner;
							vChildReservationObj.pmProcessHotelChange();
						EndIf;
					EndIf;
					// Set room type company
					If ValueIsFilled(vChildReservationObj.RoomType) Then
						If ValueIsFilled(vChildReservationObj.RoomType.Company) Then
							If vChildReservationObj.Company <> vChildReservationObj.RoomType.Company Then
								vChildReservationObj.Company = vChildReservationObj.RoomType.Company;
							EndIf;
						EndIf;
					EndIf;
					// Set room company
					If ValueIsFilled(vChildReservationObj.Room.Company) Then
						If vChildReservationObj.Company <> vChildReservationObj.Room.Company Then
							vChildReservationObj.Company = vChildReservationObj.Room.Company;
						EndIf;
					EndIf;
					// Calculate resources
					vChildReservationObj.pmCalculateResources();
					// Charging rules
					vChildReservationObj.pmLoadChargingRules(vChildReservationObj.Room);
				EndIf;
				// Check if room rate has changed
				If vChildReservationObj.RoomRate <> RoomRate Then
					vChildReservationObj.RoomRate = RoomRate;
					vChildReservationObj.PriceCalculationDate = '00010101';
					vSomethingChanged = True;
					// Set room rate company
					If ValueIsFilled(vChildReservationObj.RoomRate.Company) Then
						If vChildReservationObj.Company <> vChildReservationObj.RoomRate.Company Then
							vChildReservationObj.Company = vChildReservationObj.RoomRate.Company;
						EndIf;
					EndIf;
				EndIf;
				// Check if room rate service group has changed
				If vChildReservationObj.RoomRateServiceGroup <> RoomRateServiceGroup Then
					vChildReservationObj.RoomRateServiceGroup = RoomRateServiceGroup;
					vSomethingChanged = True;
				EndIf;
				// Check if discount card has changed
				If vChildReservationObj.DiscountCard <> DiscountCard Then
					vChildReservationObj.DiscountCard = DiscountCard;
					vSomethingChanged = True;
				EndIf;
				// Check if discount type has changed
				If vChildReservationObj.DiscountType <> DiscountType Then
					vChildReservationObj.DiscountType = DiscountType;
					vChildReservationObj.DiscountConfirmationText = DiscountConfirmationText;
					vSomethingChanged = True;
				EndIf;
				// Check if discount has changed
				If vChildReservationObj.Discount <> Discount Then
					vChildReservationObj.Discount = Discount;
					vSomethingChanged = True;
				EndIf;
				// Continue to the next reservation if nothing changed
				If Not vSomethingChanged Then
					Continue;
				EndIf;
			Else
				vChildReservationObj.ReservationStatus = Hotel.CheckInReservationStatus;
				vChildReservationObj.pmSetDoCharging();
				vChildReservationObj.AdditionalProperties.Insert("SkipMainDocTouristTaxUpdate", True);
			EndIf;
		EndIf;
		// Automatic services list calculation
		vChildReservationObj.pmCalculateServices();
		// Post changed reservation
		vChildReservationObj.Write(DocumentWriteMode.Posting);
		// Write to reservation change history
		vChildReservationObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
	EndDo;
	// Update hotel product if is set in accommodation
	If ValueIsFilled(HotelProduct) And ValueIsFilled(Reservation) And HotelProduct <> Reservation.HotelProduct Then
		vReservationObj = Reservation.GetObject();
		vReservationObj.HotelProduct = HotelProduct;
		vReservationObj.AdditionalProperties.Insert("SkipMainDocTouristTaxUpdate", True);
		vReservationObj.Write(DocumentWriteMode.Write);
		// Write to reservation change history
		vReservationObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
	EndIf;
EndProcedure // UpdateChildReservations

// -----------------------------------------------------------------------------
Function WriteOffParentReservation()
	vWriteOffIsDone = False;
	If ValueIsFilled(ParentDoc) Then
		If TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Then
			If ParentDoc.Posted Then
				If AccommodationStatus.IsActive Then
					If ValueIsFilled(ParentDoc.ReservationStatus) Then
						If ParentDoc.ReservationStatus.IsActive Then
							vParentResObj = ParentDoc.GetObject();
							vParentResObj.Read();
							vParentResObj.AdditionalProperties.Insert("SkipMainDocTouristTaxUpdate", True);
							vParentResObj.Write(DocumentWriteMode.Posting);
							vWriteOffIsDone = True;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	Return vWriteOffIsDone;
EndFunction // WriteOffParentReservation

// -----------------------------------------------------------------------------
Procedure ProcessChangeRoomAction(pLevel = 0)
	If ValueIsFilled(ParentDoc) Then
		If TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") Then
			If ParentDoc.Posted And ValueIsFilled(ParentDoc.AccommodationStatus) And 
			   ParentDoc.AccommodationStatus.IsInHouse Then
				If ValueIsFilled(AccommodationStatus) And AccommodationStatus.IsRoomChange Then
					vParentAccObj = ParentDoc.GetObject();
					vParentAccObj.Read();
					If cm1SecondShift(ParentDoc.CheckInDate) < cm1SecondShift(CheckInDate) Then
						vNewParentObjStatus = Hotel.CheckInAndMoveAccommodationStatus;
						If ParentDoc.AccommodationStatus.IsRoomChange And ValueIsFilled(Hotel.MoveAccommodationStatus) Then
							vNewParentObjStatus = Hotel.MoveAccommodationStatus;
						EndIf;
						vParentAccObj.pmCheckOut(cm0SecondShift(CheckInDate), vNewParentObjStatus, vParentAccObj.IsForFolioSplit);
						vParentAccObj.Write(DocumentWriteMode.Posting);
						// Save data to the document history
						vParentAccObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
					Else
						vParentAccObj.SetDeletionMark(True);
						ParentDoc = ParentDoc.ParentDoc;
						If ValueIsFilled(ParentDoc) And TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") Then
							ProcessChangeRoomAction(pLevel + 1);
						Else
							If pLevel = 0 Then
								AccommodationStatus = Hotel.CheckInAccommodationStatus;
							Else
								AccommodationStatus = Hotel.CheckInAndMoveAccommodationStatus;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		ElsIf TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Then
			If ValueIsFilled(AccommodationStatus) And AccommodationStatus.IsRoomChange Then
				If ValueIsFilled(ParentDoc.ParentDoc) And TypeOf(ParentDoc.ParentDoc) = Type("DocumentRef.Reservation") Then
					If BegOfDay(ParentDoc.ParentDoc.CheckOutDate) = BegOfDay(ParentDoc.CheckInDate) Then
						// Try to find accommodation that was based on this reservation
						vQry = New Query();
						vQry.Text = 
						"SELECT
						|	Accommodation.Ref
						|FROM
						|	Document.Accommodation AS Accommodation
						|WHERE
						|	Accommodation.Posted
						|	AND Accommodation.AccommodationStatus.IsActive
						|	AND Accommodation.AccommodationStatus.IsInHouse
						|	AND Accommodation.ParentDoc = &qParentDoc
						|	AND BEGINOFPERIOD(Accommodation.CheckOutDate, DAY) = &qCheckInDate
						|ORDER BY
						|	Accommodation.PointInTime";
						vQry.SetParameter("qParentDoc", ParentDoc.ParentDoc);
						vQry.SetParameter("qCheckInDate", BegOfDay(CheckInDate));
						vQryRes = vQry.Execute().Unload();
						For Each vQryResRow In vQryRes Do
							vAccObj = vQryResRow.Ref.GetObject();
							vAccObj.Read();
							vNewAccObjStatus = Hotel.CheckInAndMoveAccommodationStatus;
							If vAccObj.AccommodationStatus.IsRoomChange And ValueIsFilled(Hotel.MoveAccommodationStatus) Then
								vNewAccObjStatus = Hotel.MoveAccommodationStatus;
							EndIf;
							vAccObj.pmCheckOut(cm0SecondShift(CheckInDate), vNewAccObjStatus, vAccObj.IsForFolioSplit);
							vAccObj.Write(DocumentWriteMode.Posting);
							// Save data to the document history
							vAccObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
						EndDo;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ProcessChangeRoomAction

// -----------------------------------------------------------------------------
Procedure ChangeForeignerRegistryRecord(pCancel, pPostingMode)
	// Check if current guest record exists. If yes then update it
	vLastAccInChain = pmGetLastAccommodationInChain();
	If ValueIsFilled(vLastAccInChain) Then
		vRecords = pmGetForeignerRegistryRecords(vLastAccInChain);
		If vRecords <> Undefined Then
			// Get last one from the list
			If vRecords.Count() > 0 Then
				vDocObj = vRecords.Get(vRecords.Count()-1).ForeignerRegistryRecord.GetObject();
				vDocObj.Read();
				If vDocObj.ParentDoc <> vLastAccInChain Then
					vDocObj.ParentDoc = vLastAccInChain;
				EndIf;
				If ValueIsFilled(vLastAccInChain.TripPurpose) Then
					If vDocObj.TripPurpose <> vLastAccInChain.TripPurpose Then
						vDocObj.TripPurpose = vLastAccInChain.TripPurpose;
					EndIf;
				EndIf;
				If vLastAccInChain = Ref Then
					If ValueIsFilled(vDocObj.TripPurpose) And Not ValueIsFilled(TripPurpose) Then
						TripPurpose = vDocObj.TripPurpose;
						Write(DocumentWriteMode.Write);
					EndIf;
				EndIf;
				If ValueIsFilled(vLastAccInChain.AccommodationStatus) Then
					If Not vLastAccInChain.AccommodationStatus.IsInHouse Then
						If Not vDocObj.IsCheckedOut Then
							vDocObj.CheckOutDate = vLastAccInChain.CheckOutDate;
							If BegOfDay(vDocObj.CheckOutDate) > BegOfDay(vDocObj.MigrationCardDateTo) Then
								vDocObj.MigrationCardDateTo = vDocObj.CheckOutDate;
							EndIf;
							vDocObj.IsCheckedOut = True;
							vDocObj.Room = vLastAccInChain.Room;
						EndIf;
					Else
						If vDocObj.IsCheckedOut Then
							vDocObj.IsCheckedOut = False;
						EndIf;
					EndIf;
				EndIf;
				If vDocObj.Modified() Then
					vDocObj.Write(DocumentWriteMode.Posting);
					vDocObj.pmWriteToForeignerRegistryRecordChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ChangeForeignerRegistryRecord

// -----------------------------------------------------------------------------
Function CheckFolioActiveDocuments(pFolio)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	AccommodationChargingRules.Ref
	|FROM
	|	Document.Accommodation.ChargingRules AS AccommodationChargingRules
	|WHERE
	|	AccommodationChargingRules.ChargingFolio = &qFolio
	|	AND AccommodationChargingRules.Ref <> &qThisAccommodation
	|	AND AccommodationChargingRules.Ref.Posted
	|	AND AccommodationChargingRules.Ref.AccommodationStatus.IsActive
	|	AND AccommodationChargingRules.Ref.AccommodationStatus.IsInHouse
	|
	|UNION ALL
	|
	|SELECT
	|	ReservationChargingRules.Ref
	|FROM
	|	Document.Reservation.ChargingRules AS ReservationChargingRules
	|WHERE
	|	ReservationChargingRules.ChargingFolio = &qFolio
	|	AND ReservationChargingRules.Ref.Posted
	|	AND (ReservationChargingRules.Ref.ReservationStatus.IsActive
	|			OR ReservationChargingRules.Ref.ReservationStatus.IsPreliminary)
	|	AND NOT ReservationChargingRules.Ref.ReservationStatus.IsCheckIn
	|
	|UNION ALL
	|
	|SELECT
	|	ResourceReservations.Ref
	|FROM
	|	Document.ResourceReservation AS ResourceReservations
	|WHERE
	|	ResourceReservations.ChargingFolio = &qFolio
	|	AND ResourceReservations.Posted
	|	AND ResourceReservations.ResourceReservationStatus.IsActive
	|	AND NOT ResourceReservations.ResourceReservationStatus.ServicesAreDelivered";
	vQry.SetParameter("qFolio", pFolio);
	vQry.SetParameter("qThisAccommodation", Ref);
	vDocs = vQry.Execute().Unload();
	If vDocs.Count() > 0 Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // CheckFolioActiveDocuments

// -----------------------------------------------------------------------------
Procedure pmSetFolioStatuses() Export
	If Not AccommodationStatus.IsInHouse Or Not AccommodationStatus.IsActive Then
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
							vFolioObj.Read();
							vFolioObj.IsClosed = True;
							vFolioObj.DeletionMark = False;
							vFolioObj.AdditionalProperties.Insert("SkipCheckOfAnaliticalParametersChange", True);
							vFolioObj.Write(DocumentWriteMode.Write);
						EndIf;
					Else
						// Open folio
						If vFolioDocs.Count() > 0 Then
							vFolioObj = vFolioRef.GetObject();
							vFolioObj.Read();
							vFolioObj.IsClosed = False;
							vFolioObj.DeletionMark = False;
							vFolioObj.AdditionalProperties.Insert("SkipCheckOfAnaliticalParametersChange", True);
							vFolioObj.Write(DocumentWriteMode.Write);
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
		// Check should we close transfer folios or not
		For Each vCRRec In ChargingRules Do
			vFolioRef = vCRRec.ChargingFolio;
			If ValueIsFilled(vFolioRef) And Not vCRRec.IsMaster And vCRRec.IsTransfer And Not vFolioRef.IsMaster Then
				vFolioObj = vFolioRef.GetObject();
				If Not vFolioObj.IsClosed Or vFolioObj.DeletionMark Then
					If Not CheckFolioActiveDocuments(vFolioRef) Then
						vFolioObj.Read();
						vFolioObj.IsClosed = True;
						vFolioObj.DeletionMark = False;
						vFolioObj.AdditionalProperties.Insert("SkipCheckOfAnaliticalParametersChange", True);
						vFolioObj.Write(DocumentWriteMode.Write);
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
				If vFolioRef.IsMaster Then
					Continue;
				EndIf;
				// Check should we change folio status at all
				If ValueIsFilled(AccommodationType) And AccommodationType.PostToRoomMainFolio And 
				   ValueIsFilled(vFolioRef.ParentDoc) And vFolioRef.ParentDoc <> Ref Then
					Continue;
				EndIf;
				If vFolioRef.IsClosed Then
					vFolioObj = vFolioRef.GetObject();
					vFolioObj.Read();
					vFolioObj.IsClosed = False;
					vFolioObj.DeletionMark = False;
					vFolioObj.AdditionalProperties.Insert("SkipCheckOfAnaliticalParametersChange", True);
					vFolioObj.Write(DocumentWriteMode.Write);
				EndIf;
			EndIf;
		EndDo;
		// Check should we open guest group folios or not
		If ValueIsFilled(GuestGroup) And GuestGroup.ChargingRules.Count() > 0 Then
			For Each vGGCRRow In GuestGroup.ChargingRules Do
				vFolioRef = vGGCRRow.ChargingFolio;
				If ValueIsFilled(vFolioRef) And vFolioRef.IsClosed And Not vFolioRef.IsMaster Then
					vFolioObj = vFolioRef.GetObject();
					vFolioObj.Read();
					vFolioObj.IsClosed = False;
					vFolioObj.DeletionMark = False;
					vFolioObj.AdditionalProperties.Insert("SkipCheckOfAnaliticalParametersChange", True);
					vFolioObj.Write(DocumentWriteMode.Write);
				EndIf;
			EndDo;
		EndIf;
		// Check should we open transfer folios or not
		For Each vCRRec In ChargingRules Do
			vFolioRef = vCRRec.ChargingFolio;
			If ValueIsFilled(vFolioRef) And Not vCRRec.IsMaster And vCRRec.IsTransfer And Not vFolioRef.IsMaster Then
				vFolioObj = vFolioRef.GetObject();
				If vFolioObj.IsClosed Or vFolioObj.DeletionMark Then
					vFolioObj.Read();
					vFolioObj.IsClosed = False;
					vFolioObj.DeletionMark = False;
					vFolioObj.AdditionalProperties.Insert("SkipCheckOfAnaliticalParametersChange", True);
					vFolioObj.Write(DocumentWriteMode.Write);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // pmSetFolioStatuses

// -----------------------------------------------------------------------------
Procedure pmSetIsByReservation(rReservation = Undefined) Export
	vIsByReservation = False;
	rReservation = Documents.Reservation.EmptyRef();
	vParentDoc = ParentDoc;
	While ValueIsFilled(vParentDoc) Do
		If TypeOf(vParentDoc) = Type("DocumentRef.Reservation") Then
			vIsByReservation = True;
			rReservation = vParentDoc;
			Break;
		Else
			vParentDoc = vParentDoc.ParentDoc;
		EndIf;
	EndDo;
	If IsByReservation <> vIsByReservation Then
		IsByReservation = vIsByReservation;
	EndIf;
	If rReservation <> Reservation Then
		Reservation = rReservation;
	EndIf;
EndProcedure // pmSetIsByReservation

// -----------------------------------------------------------------------------
Procedure pmCheckFolioDebts(pCancel, pPostingMode) Export 
	If Not AdditionalProperties.Property("InfoBaseUpdateMode") And Not AdditionalProperties.Property("CloseOfDayMode") Then
		If Not cmCheckUserPermissions("HavePermissionToCheckOutAccommodationsWithClientDebts") Or
		   Not cmCheckUserPermissions("HavePermissionToCheckOutAccommodationsWithCustomerDebts") Then
			// Check if this accommodation is the last one in chain. If not then skip check
			vNextAccommodation = pmGetNextAccommodationInChain();
			If ValueIsFilled(vNextAccommodation) Then
				Return;
			EndIf;
			// Process folios from charging rules
			vFolios = cmGetDocumentFoliosWithDebts(Ref);
			For Each vFoliosRow In vFolios Do
				vFolioRef = vFoliosRow.Folio;
				If ValueIsFilled(vFolioRef) And ValueIsFilled(vFolioRef.ParentDoc) And vFolioRef.ParentDoc = Ref Then
					If Not vFolioRef.IsMaster Then
						If cmCheckUserPermissions("HavePermissionToCheckOutAccommodationsWithCustomerDebts") Then
							If ValueIsFilled(vFolioRef.Customer) And Not vFolioRef.Customer.IsIndividual Then
								If ValueIsFilled(vFolioRef.PaymentMethod) Then
									If vFolioRef.PaymentMethod.IsByBankTransfer Then
										Continue;
									EndIf;
								EndIf;
							EndIf;
						EndIf;
						If cmCheckUserPermissions("HavePermissionToCheckOutAccommodationsWithClientDebts") Then
							If ValueIsFilled(vFolioRef.Customer) And vFolioRef.Customer.IsIndividual Then
								If ValueIsFilled(vFolioRef.PaymentMethod) Then
									If Not vFolioRef.PaymentMethod.IsByBankTransfer Then
										Continue;
									EndIf;
								Else
									Continue;
								EndIf;
							Else
								Continue;
							EndIf;
						EndIf;
						Raise String(Ref) + " - " + NStr("en='Guest balance after check-out is not zero (CHECKOUT_WITH_DEBT)! You do not have rights to check-out guests with balances.';ru='Баланс гостя не равен нулю (CHECKOUT_WITH_DEBT)! Нет прав на выселение гостей с долгами.';de='Die Bilanz des Gastes ist nicht gleich Null (CHECKOUT_WITH_DEBT)! Sie haben keine Rechte, Gaste mit Schulden auszuchecken.'");
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		// Check if advances were cleared
		If cmCheckUserPermissions("HavePermissionToCheckIfAdvancesClearingIsDone") Then
			vFoliosWithAdvances = cmGetDocumentFoliosWithNotClearedAdvances(Ref);
			If vFoliosWithAdvances.Count() > 0 Then
				For Each vFoliosRow In vFoliosWithAdvances Do
					vFolioRef = vFoliosRow.Folio;
					If ValueIsFilled(vFolioRef) And ValueIsFilled(vFolioRef.ParentDoc) And vFolioRef.ParentDoc = Ref Then
						If Not vFolioRef.IsMaster Then
							Raise String(Ref) + " - " + NStr("en='Folio advances were not cleared (ADVANCES_NOT_CLEARED)! Please go to the folios list and do clearing - ';ru='Не выполнен зачет аванса (ADVANCES_NOT_CLEARED)! Откройте список лицевых счетов и выполните зачет аванса для ';de='Die Vorauszahlung wurde nicht abgeschlossen (ADVANCES_NOT_CLEARED)! Öffnen Sie die Liste der persönlichen Konten und verrechnen Sie den Vorschuss für '") + TrimAll(vFolioRef);
						EndIf;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // pmCheckFolioDebts

// -----------------------------------------------------------------------------
Procedure FillCheckOutOperationTime()
	If ValueIsFilled(AccommodationStatus) And 
	   AccommodationStatus.IsActive And 
	   Not AccommodationStatus.IsInHouse Then
		If Not ValueIsFilled(CheckOutOperationTime) Then
			CheckOutOperationTime = CurrentSessionDate();
			CheckOutOperationAuthor = SessionParameters.CurrentUser;
		EndIf;
	Else
		If ValueIsFilled(CheckOutOperationTime) Then
			CheckOutOperationTime = '00010101';
			CheckOutOperationAuthor = Catalogs.Employees.EmptyRef();
		EndIf;
	EndIf;
EndProcedure // FillCheckOutOperationTime

// -----------------------------------------------------------------------------
Procedure FillGroupParameters()
	If ValueIsFilled(GuestGroup) Then
		// Client document
		vUpdateClientDoc = False;
		If Not ValueIsFilled(GuestGroup.ClientDoc) Or 
		   GuestGroup.FixedClient And ValueIsFilled(GuestGroup.Client) And GuestGroup.Client = Guest Then
			vUpdateClientDoc = True;
		EndIf;
		// Client
		vUpdateClient = False;
		If ValueIsFilled(Guest) And Not GuestGroup.FixedClient Then
			If Not ValueIsFilled(GuestGroup.Client) Or 
			   IsMaster And GuestGroup.Client <> Guest Or 
			   ValueIsFilled(GuestGroup.ClientDoc) And (GuestGroup.ClientDoc = Ref Or GuestGroup.ClientDoc = Reservation) And GuestGroup.Client <> Guest Then
				vUpdateClient = True;
			EndIf;
		EndIf;
		// Customer
		vUpdateCustomer = False;
		vUpdateContract = False;
		If GuestGroup.OneCustomerPerGuestGroup Then
			If GuestGroup.Customer <> Customer Then
				If Not IsForFolioSplit Or 
				   IsForFolioSplit And (Ref = GuestGroup.ClientDoc Or ValueIsFilled(Reservation) And Reservation = GuestGroup.ClientDoc Or vUpdateClientDoc Or vUpdateClient) Then
					vUpdateCustomer = True;
				EndIf;
			EndIf;
			If GuestGroup.Contract <> Contract Then
				If Not IsForFolioSplit Or 
				   IsForFolioSplit And (Ref = GuestGroup.ClientDoc Or ValueIsFilled(Reservation) And Reservation = GuestGroup.ClientDoc Or vUpdateClientDoc Or vUpdateClient) Then
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
		If vUpdateCustomer Or vUpdateContract Or vUpdateAgent Or vUpdateClient Or vUpdateClientDoc Or vUpdatePeriod Or vUpdateGuestsCheckedIn Or vUpdateGroupStatus Then
			vGroupObj = GuestGroup.GetObject();
			vGroupObj.Read();
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
			If vUpdateGroupStatus Then
				vGroupObj.Status = vGuestGroupStatus;
			EndIf;
			vGroupObj.Write();
		EndIf;
	EndIf;
EndProcedure // FillGroupParameters

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
EndProcedure // pmClearInventoryRegisterRecords

// -----------------------------------------------------------------------------
Procedure pmClearSalesForecastRegisterRecords() Export
	RegisterRecords.SalesForecast.Clear();
	RegisterRecords.ServiceRegistration.Clear();
	RegisterRecords.HotelProductLog.Clear();
	RegisterRecords.AccountsReceivableForecast.Clear();
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
		// Accounts receivable forecast
	    vSFSet = AccumulationRegisters.AccountsReceivableForecast.CreateRecordSet();
	    vSFSet.Filter.Recorder.Set(Ref);
	    vSFSet.Read();
	    vSFSet.Clear();
	    vSFSet.Write(True);
		// Service registration
	    vSFSet = AccumulationRegisters.ServiceRegistration.CreateRecordSet();
	    vSFSet.Filter.Recorder.Set(Ref);
	    vSFSet.Read();
	    vSFSet.Clear();
	    vSFSet.Write(True);
	EndIf;
EndProcedure // pmClearSalesForecastRegisterRecords

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
Procedure pmUpdateHotelProductData() Export
	If ValueIsFilled(HotelProduct) Then
		If Not HotelProduct.IsFolder Then
			// We'll try to update hotel product sum and period here
			vHPCurrency = Undefined;
			vHPSum = GetVoucherSum(vHPCurrency);
			// Get hotel product payment date and payment method
			vPaymentDate = Undefined;
			vPaymentMethod = Undefined;
			If Not ValueIsFilled(HotelProduct.PaymentDate) Then
				vPaymentDate = HotelProduct.GetObject().pmGetHotelProductPaymentDate(vPaymentMethod);
			EndIf;
			// Update hotel product data
			vUpdateSum = False;
			vUpdatePeriod = False;
			vUpdatePaymentDate = False;
			vUpdateClient = False;
			If ValueIsFilled(AccommodationStatus) And 
			   AccommodationStatus.IsActive And Not AccommodationStatus.IsRoomChange And 
			   AccommodationStatus.IsCheckIn And AccommodationStatus.IsCheckOut Then
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
						vHPObj.Client = vClient;
					EndIf;
					vHPObj.Write();
				Except
				EndTry;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // pmUpdateHotelProductData

// -----------------------------------------------------------------------------
Procedure pmAutoCreateVouchers() Export
	If Not ValueIsFilled(HotelProduct) Then
		If ValueIsFilled(RoomRate) And ValueIsFilled(AccommodationStatus) And AccommodationStatus.IsInHouse And AccommodationStatus.IsActive And 
		     (ValueIsFilled(RoomRate.RoomRateType) And RoomRate.RoomRateType.AutoGenerationOfVoucherNumbers Or 
			  ValueIsFilled(RoomRateType) And RoomRateType.AutoGenerationOfVoucherNumbers) Then
			vVoucherType = ?(ValueIsFilled(RoomRateType) And RoomRateType.AutoGenerationOfVoucherNumbers, RoomRateType.VoucherType, ?(ValueIsFilled(RoomRate.RoomRateType), RoomRate.RoomRateType.VoucherType, Undefined));
			vCreateNewVoucher = True;
			If RoomRate.RateChargeDirection = Enums.RateChargeDirections.MergeToTheMainRoomGuest And Not IsForFolioSplit Then
				vMainRoomDoc = cmGetMainRoomAccommodation(Number, GuestGroup, Room);
				If ValueIsFilled(vMainRoomDoc) And vMainRoomDoc <> Ref And ValueIsFilled(vMainRoomDoc.HotelProduct) Then
					HotelProduct = vMainRoomDoc.HotelProduct;
					vCreateNewVoucher = False;
				EndIf;
			EndIf;
			If vCreateNewVoucher Then
				// Add lock to vouchers catalog to avoid voucher numbers to overlap
				vDataLock = New DataLock();
				vVouchersLock = vDataLock.Add("Catalog.HotelProducts");
				vVouchersLock.Mode = DataLockMode.Exclusive;
				vVouchersLock.SetValue("Hotel", Hotel);
				If ValueIsFilled(vVoucherType) Then
					vVouchersLock.SetValue("Parent", vVoucherType);
				EndIf;
				vDataLock.Lock();
				// Get next vacant voucher number
				vNewVoucherNumber = GetNewVoucherNumber(vVoucherType);
				// Get voucher amount
				vHPCurrency = Undefined;
				vHPSum = GetVoucherSum(vHPCurrency);
				// Create new voucher based on room rate type settings
				If Not IsBlankString(vNewVoucherNumber) Then
					vHPObj = Catalogs.HotelProducts.CreateItem();
					vHPObj.Code = vNewVoucherNumber;
					vHPObj.Description = vHPObj.Code;
					vHPObj.Hotel = Hotel;
					vHPObj.Parent = vVoucherType;
					vHPObj.RoomQuota = RoomQuota;
					vHPObj.pmFillAttributesWithDefaultValues();
					vHPObj.Sum = vHPSum;
					vHPObj.Currency = vHPCurrency;
					vHPObj.CheckInDate = CheckInDate;
					vHPObj.Duration = Duration;
					vHPObj.CheckOutDate = CheckOutDate;
					vHPObj.RoomType = RoomType;
					vHPObj.PaymentMethod = PlannedPaymentMethod;
					vHPObj.Client = Guest;
					vHPObj.SocialGroup = vHPObj.Parent.SocialGroup;
					vHPObj.Write();
					
					HotelProduct = vHPObj.Ref;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // pmAutoCreateVouchers

// -----------------------------------------------------------------------------
Function GetVoucherSum(rHPCurrency)
	vHPSum = 0;
	rHPCurrency = Undefined;
	If ValueIsFilled(HotelProduct) Then
		rHPCurrency = HotelProduct.Currency;
	Else
		rHPCurrency = Hotel.FolioCurrency;
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
		If rHPCurrency = vTotal.FolioCurrency Then
			vHPSum = vHPSum + vTotal.Sum - vTotal.DiscountSum;
		Else
			rHPCurrency = Undefined;
		EndIf;
	EndDo;
	Return vHPSum;
EndFunction // GetVoucherSum

// -----------------------------------------------------------------------------
Function GetNewVoucherNumber(pVoucherType)
	vNewVoucherNumber = "";
	// Get last voucher number
	vMaxCode = "";
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	MAX(HotelProducts.Code) AS MaxCode
	|FROM
	|	Catalog.HotelProducts AS HotelProducts
	|WHERE
	|	HotelProducts.Hotel = &qHotel
	|	AND HotelProducts.Parent = &qParent
	|	AND NOT HotelProducts.IsFolder
	|	AND NOT HotelProducts.DeletionMark";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qParent", pVoucherType);
	vCodes = vQry.Execute().Unload();
	For Each vCodesRow In vCodes Do
		vMaxCode = TrimR(vCodesRow.MaxCode);
		Break;
	EndDo;
	If IsBlankString(vMaxCode) Then
		vNewVoucherNumber = Catalogs.HotelProducts.SetVaucherNumberPresentation("000001", pVoucherType);
	Else
		vCodeLen = StrLen(vMaxCode);
		vLastVoucherNumber = "";
		// Remove series
		If ValueIsFilled(pVoucherType) And pVoucherType.SeriesIsAtTheEnd Then
			vMaxCode = TrimL(vMaxCode);
			vFirstNotDigitIndex = 0; 
			For i = 1 To vCodeLen Do
				vChar = Mid(vMaxCode, i, 1);
				If StrFind("0123456789", vChar) = 0 Then
					vFirstNotDigitIndex = i;
					Break;
				EndIf;
			EndDo;
			If vFirstNotDigitIndex = 0 Then
				vNewVoucherNumber = Format(Number(vMaxCode) + 1, "ND=" + vCodeLen + "; NFD=0; NZ=; NLZ=; NG=");
			ElsIf vFirstNotDigitIndex <= vCodeLen Then
				vLastVoucherSuffix = Mid(vMaxCode, vFirstNotDigitIndex);
				vLastVoucherNumber = Left(vMaxCode, vFirstNotDigitIndex - 1);
				vLastVoucherNumberLen = StrLen(vLastVoucherNumber);
				vNewVoucherNumber = Format(Number(vLastVoucherNumber) + 1, "ND=" + vLastVoucherNumberLen + "; NFD=0; NZ=; NLZ=; NG=") + vLastVoucherSuffix;
			EndIf;
		Else
			vLastNotDigitIndex = 0; 
			For i = 1 To vCodeLen Do
				vChar = Mid(vMaxCode, i, 1);
				If StrFind("0123456789", vChar) = 0 Then
					vLastNotDigitIndex = i; 
				EndIf;
			EndDo;
			If vLastNotDigitIndex = 0 Then
				vNewVoucherNumber = Format(Number(vMaxCode) + 1, "ND=" + vCodeLen + "; NFD=0; NZ=; NLZ=; NG=");
			ElsIf vLastNotDigitIndex < vCodeLen Then
				vLastVoucherPrefix = Left(vMaxCode, vLastNotDigitIndex); 
				vLastVoucherNumber = TrimR(Mid(vMaxCode, vLastNotDigitIndex + 1));
				vLastVoucherNumberLen = StrLen(vLastVoucherNumber);
				vNewVoucherNumber = vLastVoucherPrefix + Format(Number(vLastVoucherNumber) + 1, "ND=" + vLastVoucherNumberLen + "; NFD=0; NZ=; NLZ=; NG=");
			EndIf;
		EndIf;
	EndIf;
	Return vNewVoucherNumber;
EndFunction // GetNewVoucherNumber

// -----------------------------------------------------------------------------
Procedure RepostIntersectedDocs(pIntersectedDocs, pPeriodsRow, pMode = 0, pWriteOffIsDone = False)
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
	pPeriodsRow.IsCheckIn = AccommodationStatus.IsCheckIn;
	pPeriodsRow.IsCheckOut = AccommodationStatus.IsCheckOut;
EndProcedure // FillPeriodsRowWithDefaultValues

// -----------------------------------------------------------------------------
Procedure UpdatePeriodsRow(pPeriods, pPeriodsRow, pRRRow)
	vPrevPeriodsRow = pPeriodsRow;
	vPeriodsRowIndex = pPeriods.IndexOf(pPeriodsRow);
	If vPeriodsRowIndex > 0 Then
		vPrevPeriodsRow = pPeriods.Get(vPeriodsRowIndex - 1);
	EndIf;
	If ValueIsFilled(pRRRow.RoomType) And pRRRow.RoomType <> vPrevPeriodsRow.RoomType Or
	   ValueIsFilled(pRRRow.Room) And pRRRow.Room <> vPrevPeriodsRow.Room Or
	   ValueIsFilled(pRRRow.AccommodationType) And pRRRow.AccommodationType <> vPrevPeriodsRow.AccommodationType Or
	   ValueIsFilled(pRRRow.AccommodationTemplate) And pRRRow.AccommodationTemplate <> vPrevPeriodsRow.AccommodationTemplate Or
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
			pPeriodsRow.Room = vPrevPeriodsRow.Room;
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
EndProcedure // UpdatePeriodsRow

// -----------------------------------------------------------------------------
Function pmGetAccommodationPeriods(pAddConnected = False) Export
	// Create value table of accommodation periods
	vPeriods = New ValueTable();
	vPeriods.Columns.Add("Ref", cmGetDocumentTypeDescription("Accommodation"));
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
	vPeriods.Columns.Add("DoNotChangeAvailability", cmGetBooleanTypeDescription());
	vPeriods.Columns.Add("IsRoomChange", cmGetBooleanTypeDescription());
	vPeriods.Columns.Add("IsCheckOut", cmGetBooleanTypeDescription());
	vPeriods.Columns.Add("IsCheckIn", cmGetBooleanTypeDescription());
	vPeriods.Columns.Add("AccountingDate", cmGetDateTimeTypeDescription());
	vPeriods.Columns.Add("NoRoomsInRoomQuota", cmGetBooleanTypeDescription());
	vPeriods.Columns.Add("IntersectedDocs");
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
			   BegOfDay(CheckOutDate) < BegOfDay(vRRRow.AccountingDate) Then
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
								vPeriodsRow.CheckOutDate = cmMovePeriodToToReferenceHour(vRRRow.AccountingDate, vPeriodsRow.RoomRate);
							EndIf;
							// Add new row
							vPeriodsRow = vPeriods.Add();
							FillPeriodsRowWithDefaultValues(vPeriodsRow);
							If ValueIsFilled(vRRRow.ChangeTime) Then
								vPeriodsRow.CheckInDate = cm1SecondShift(BegOfDay(vRRRow.AccountingDate) + (vRRRow.ChangeTime - BegOfDay(vRRRow.ChangeTime)));
							Else
								vPeriodsRow.CheckInDate = cmMovePeriodFromToReferenceHour(vRRRow.AccountingDate, vPeriodsRow.RoomRate);
							EndIf;
							vPeriodsRow.IsRoomChange = True;
						EndIf;
						If cmMovePeriodToToReferenceHour((vRRRow.AccountingDate + 24*3600), ?(ValueIsFilled(vRRRow.RoomRate), vRRRow.RoomRate, RoomRate)) < CheckOutDate Then
							If ValueIsFilled(vRRRow.ChangeTime) Then
								vPeriodsRow.CheckOutDate = cm0SecondShift(BegOfDay(vRRRow.AccountingDate + 24*3600) + (vRRRow.ChangeTime - BegOfDay(vRRRow.ChangeTime)));
							Else
								vPeriodsRow.CheckOutDate = cmMovePeriodToToReferenceHour((vRRRow.AccountingDate + 24*3600), vPeriodsRow.RoomRate);
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
								vPeriodsRow.CheckInDate = cmMovePeriodFromToReferenceHour(vRRRow.AccountingDate, vPeriodsRow.RoomRate);
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
					For Each vConnectedRoom In vPeriod.Room.ConnectedRooms Do
						vPeriodsRow = vNewPeriods.Add();
						vPeriodsRow.Ref = vPeriod.Ref;
						vPeriodsRow.Hotel = vPeriod.Hotel;
						vPeriodsRow.RoomQuota =vPeriod.RoomQuota;
						vPeriodsRow.CheckInDate = vPeriod.CheckInDate;
						vPeriodsRow.CheckOutDate = vPeriod.CheckOutDate;
						vRoomAttrs = vConnectedRoom.Room.GetObject().pmGetRoomAttributes(cm1SecondShift(vPeriod.CheckInDate));
						vPeriodsRow.RoomType = vRoomAttrs[0].RoomType;
						vPeriodsRow.Room = vConnectedRoom.Room;
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
			EndIf;
		EndDo;
	EndIf;
	Return vNewPeriods;
EndFunction // pmGetAccommodationPeriods 

// -----------------------------------------------------------------------------
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
EndFunction // pmGetAccommodationPlan 

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
				Raise String(Ref) + " - " + NStr("en='Failed to lock room inventory for update! Please retry later...';ru='Другие пользователи выполняют запись в базу данных! Повторите попытку позже...';de='Andere Nutzer fuhren bereits den Eintrag in die Datenbank aus! Wiederholen Sie den Versuch spater…'");
			EndIf;
		EndTry;
		i = i + 1;
		// Wait for 10 seconds
		cmWait(10);
	EndDo;
EndProcedure // AddDataLocks 

// -----------------------------------------------------------------------------
Procedure DoRoomInventoryPosting(pCancel)
	Var vMessage, vAttributeInErr;
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
		// Repost intersected document prior to the current one 
		If vPeriodsRow.IntersectedDocs.Count() > 0 Then
			RepostIntersectedDocs(vPeriodsRow.IntersectedDocs, vPeriodsRow, 1, False);
		EndIf;
	EndDo;
	// Build value table of accommodation periods taking new movements into account
	vAllPeriods = pmGetAccommodationPeriods(True);
	// Post to registers
	For Each vPeriodsRow In vAllPeriods Do
		// Add data locks
		AddDataLocks(vPeriodsRow);
		// Post to registers
		pmPostToInventoryRegisters(vAllPeriods, vPeriodsRow, False, pCancel);
		// Write off parent reservation
		vWriteOffIsDone = False;
		If vPeriods.IndexOf(vPeriodsRow) = 0 Then
			vWriteOffIsDone = WriteOffParentReservation();
		EndIf;
	EndDo;
	// Repost intersected document after the current one 
	For Each vPeriodsRow In vPeriods Do
		If vPeriodsRow.IntersectedDocs.Count() > 0 Then
			RepostIntersectedDocs(vPeriodsRow.IntersectedDocs, vPeriodsRow, 2, vWriteOffIsDone);
		EndIf;
		// Write off parent reservation
		If vPeriods.IndexOf(vPeriodsRow) = 0 Then
			// Update next reservations in chain
			pmUpdateNextReservationsInChain();
		EndIf;
	EndDo;
	// Check room inventory and room quota vacant rooms
	For Each vPeriodsRow In vAllPeriods Do
		If Not pCancel Then
			pCancel	= pmCheckDocumentAttributes(vPeriodsRow, True, vMessage, vAttributeInErr);
			If pCancel Then
				WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
				tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage), MessageStatus.Attention);
				Raise String(Ref) + " - " + NStr(vMessage);
			EndIf;
		EndIf;
	EndDo;
	// Post to business block forecast sales
	If Not pCancel Then
		If ValueIsFilled(AccommodationStatus) And AccommodationStatus.IsActive And AccommodationStatus.IsInHouse Then
			If ValueIsFilled(RoomQuota) And RoomQuota.AllotmentBusinessType = Enums.AllotmentBusinessTypes.BusinessBlock Then
				If RoomQuota.AllotmentType = Enums.AllotmentTypes.Definite Or 
				   RoomQuota.AllotmentType = Enums.AllotmentTypes.DefiniteNotGuaranteed Or 
				   RoomQuota.AllotmentType = Enums.AllotmentTypes.Tentative Then
					pmPostToBusinessBlockForecastSales(vAllPeriods);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // DoRoomInventoryPosting

// -----------------------------------------------------------------------------
Procedure pmPostToBusinessBlockForecastSales(pPeriods) Export
	vCloseOfDayMode = False;
	If AdditionalProperties.Property("CloseOfDayMode") And AdditionalProperties.CloseOfDayMode Then
		vCloseOfDayMode = True;
	EndIf;
	vHotelAccountingDate = Hotel.AccountingDate;
	If ValueIsFilled(vHotelAccountingDate) And AdditionalProperties.Property("AccountingDate") Then
		If ValueIsFilled(AdditionalProperties.AccountingDate) And TypeOf(AdditionalProperties.AccountingDate) = Type("Date") Then
			vHotelAccountingDate = AdditionalProperties.AccountingDate;
		EndIf;
	EndIf;
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
					If Not vCloseOfDayMode And vSalesRow.AccountingDate >= vHotelAccountingDate And vSalesRow.AccountingDate > DoChargingToDate And vHotelAccountingDate < BegOfDay(CheckOutDate) And BegOfDay(CurrentSessionDate()) < BegOfDay(CheckOutDate) Or 
					   vCloseOfDayMode And vSalesRow.AccountingDate > vHotelAccountingDate And vSalesRow.AccountingDate > DoChargingToDate And vHotelAccountingDate < BegOfDay(CheckOutDate) And BegOfDay(CurrentSessionDate()) < BegOfDay(CheckOutDate) Then
						vSFRec = RegisterRecords.SalesForecast.Add();
						FillPropertyValues(vSFRec, RoomQuota);
						FillPropertyValues(vSFRec, vSalesRow);
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
EndProcedure // pmPostToBusinessBlockForecastSales

// -----------------------------------------------------------------------------
Procedure RepostPreviousAccommodation()
	If ValueIsFilled(AccommodationStatus) And AccommodationStatus.IsActive Then
		If ValueIsFilled(ParentDoc) And TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") Then
			If ParentDoc.Posted And ValueIsFilled(ParentDoc.AccommodationStatus) And 
			   ParentDoc.AccommodationStatus.IsActive And ParentDoc.FixReservationConditions Then
				vParentDocObj = ParentDoc.GetObject();
				vParentDocObj.Read();
				vParentDocObj.pmCalculateServices();
				vParentDocObj.Write(DocumentWriteMode.Posting);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // RepostPreviousAccommodation 

// -----------------------------------------------------------------------------
Procedure pmCheckRoomRates() Export
	vRRAreChanged = False;
	vCheckInDate = CheckInDate;
	vCheckOutDate = CheckOutDate;
	If ValueIsFilled(Reservation) Then
		vCheckInDate = Min(vCheckInDate, Reservation.CheckInDate);
		vCheckOutDate = Max(vCheckOutDate, Reservation.CheckOutDate);
	EndIf;
	// Delete rows outside the period of stay
	vPrevIsBookedOut = False;
	i = 0;
	While i < RoomRates.Count() Do
		vRRRow = RoomRates.Get(i);
		If BegOfDay(vRRRow.AccountingDate) < BegOfDay(vCheckInDate) Or 
		   BegOfDay(vRRRow.AccountingDate) > BegOfDay(vCheckOutDate) Then
			RoomRates.Delete(i);
			vRRAreChanged = True;
			Continue;
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
		     (Not vRRRow.IsBookedOut And Not vPrevIsBookedOut) Then
			RoomRates.Delete(i);
			vRRAreChanged = True;
			Continue;
		Else
			vPrevIsBookedOut = vRRRow.IsBookedOut;
			i = i + 1;
		EndIf;
	EndDo;
	// Add initialization row for the first day
	If RoomRates.Count() > 0 Then
		vAddCheckInRow = True;
		For Each vRRRow In RoomRates Do
			If BegOfDay(vRRRow.AccountingDate) = BegOfDay(vCheckInDate) Then
				vAddCheckInRow = False;
			ElsIf BegOfDay(vRRRow.AccountingDate) > BegOfDay(vCheckInDate) Then
				Break;
			EndIf;
		EndDo;
		If vAddCheckInRow Then
			vRRRow = RoomRates.Insert(0);
			vRRRow.AccountingDate = BegOfDay(vCheckInDate);
			vRRRow.AccommodationTemplate = AccommodationTemplate;
			vRRRow.AccommodationType = AccommodationType;
			vRRRow.Room = Room;
			vRRRow.RoomType = RoomType;
			vRRRow.RoomRate = RoomRate;
			vRRRow.PriceCalculationDate = PriceCalculationDate;
			vRRAreChanged = True;
		EndIf;
	EndIf;
	If vRRAreChanged Then
		RoomRates.Sort("AccountingDate, ChangeTime");
	EndIf;
	// Check current document values
	vActiveRRRow = Undefined;
	For Each vRRRow In RoomRates Do
		If (BegOfDay(vRRRow.AccountingDate) + (vRRRow.ChangeTime - BegOfDay(vRRRow.ChangeTime))) < CurrentSessionDate() Then
			vActiveRRRow = vRRRow;
		Else
			Break;
		EndIf;
	EndDo;
	If vActiveRRRow <> Undefined Then
		If ValueIsFilled(vActiveRRRow.AccommodationTemplate) And vActiveRRRow.AccommodationTemplate <> AccommodationTemplate Then
			AccommodationTemplate = vActiveRRRow.AccommodationTemplate;
		EndIf;
		If ValueIsFilled(vActiveRRRow.AccommodationType) And vActiveRRRow.AccommodationType <> AccommodationType Then
			AccommodationType = vActiveRRRow.AccommodationType;
		EndIf;
		If ValueIsFilled(vActiveRRRow.Room) And vActiveRRRow.Room <> Room Then
			Room = vActiveRRRow.Room;
			If ValueIsFilled(vActiveRRRow.RoomType) Then
				RoomType = vActiveRRRow.RoomType;
			EndIf;
		EndIf;
		If ValueIsFilled(vActiveRRRow.RoomRate) And vActiveRRRow.RoomRate <> RoomRate Then
			RoomRate = vActiveRRRow.RoomRate;
			PriceCalculationDate = ?(ValueIsFilled(vActiveRRRow.PriceCalculationDate), vActiveRRRow.PriceCalculationDate, PriceCalculationDate);
		EndIf;
	EndIf;
EndProcedure // pmCheckRoomRates

// -----------------------------------------------------------------------------
Function pmCheckRoomMainFolios() Export
	vDoReloadDefault = False;
	If ValueIsFilled(AccommodationType) Then
		If Not IsForFolioSplit And AccommodationType.PostToRoomMainFolio Then
			vRoomMainDoc = GetRoomMainAccommodation();
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
				If Not vCRRow.IsTransfer And Not vCRRow.IsMaster And Not vCRRow.IsPersonal And Not vCRRow.ChargingFolio.IsMaster Then
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
Procedure pmUpdateNextReservationsInChain() Export
	vCheckOutDate = CheckOutDate;
	If ValueIsFilled(AccommodationStatus) And ValueIsFilled(Hotel) And AccommodationStatus.IsActive Then
		vParentReservation = pmGetParentReservation();
		If ValueIsFilled(vParentReservation) Then
			vParentReservationObj = vParentReservation.GetObject();
			vNextReservationInChain = vParentReservationObj.pmGetNextReservationInChain();
			While ValueIsFilled(vNextReservationInChain) Do
				If AccommodationStatus.IsInHouse Then
					If vNextReservationInChain.RoomQuantity = 1 And vNextReservationInChain.RoomType = RoomType Then
						If BegOfDay(vNextReservationInChain.CheckOutDate) > BegOfDay(vCheckOutDate) And vNextReservationInChain.Room <> Room And 
						   vNextReservationInChain.RoomQuota <> RoomQuota Then
							vCheckOutDate = vNextReservationInChain.CheckOutDate;
							// Set room to the reservation
							vNextReservationInChainObj = vNextReservationInChain.GetObject();
							vNextReservationInChainObj.Read();
							vNextReservationInChainObj.Room = Room;
							// Automatic services list calculation
							vNextReservationInChainObj.pmCalculateServices();
							// Post changed reservation
							vNextReservationInChainObj.Write(DocumentWriteMode.Posting);
							// Write to reservation change history
							vNextReservationInChainObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
						ElsIf BegOfDay(vNextReservationInChain.CheckOutDate) <= BegOfDay(vCheckOutDate) Then
							If ValueIsFilled(vNextReservationInChain.ReservationStatus) And vNextReservationInChain.ReservationStatus.IsActive Then
								// Set checked-in reservation status
								vNextReservationInChainObj = vNextReservationInChain.GetObject();
								vNextReservationInChainObj.Read();
								vNextReservationInChainObj.ReservationStatus = vNextReservationInChain.Hotel.CheckInReservationStatus;
								vNextReservationInChainObj.pmSetDoCharging();
								// Post changed reservation
								vNextReservationInChainObj.Write(DocumentWriteMode.Posting);
								// Write to reservation change history
								vNextReservationInChainObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
							EndIf;
						EndIf;
					Else
						Break;   
					EndIf;
				ElsIf Not AccommodationStatus.IsInHouse And AccommodationStatus.IsCheckOut Then
					Break;   
				EndIf;
				vNextReservationInChain = vNextReservationInChain.GetObject().pmGetNextReservationInChain();
			EndDo;
		EndIf;
	EndIf;
EndProcedure // pmUpdateNextReservationsInChain

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
		pSFRec.NumberOfRooms = NumberOfRooms;
		pSFRec.NumberOfBeds = NumberOfBeds;
		pSFRec.NumberOfAdditionalBeds = NumberOfAdditionalBeds;
		pSFRec.NumberOfPersons = NumberOfPersons;
	Else
		pSFRec.NumberOfRooms = 0;
		pSFRec.NumberOfBeds = 0;
		pSFRec.NumberOfAdditionalBeds = 0;
		pSFRec.NumberOfPersons = 0;
	EndIf;
	
	vSrvRecPrice = pSrvSumInReportingCurrency;
	If pSrvQuantity <> 0 Then
		vSrvRecPrice = cmRecalculatePrice(pSrvSumInReportingCurrency, pSrvQuantity);
	EndIf;
	
	// Recalculate forecast resources according to the write off coefficient
	vSrvRec = New Structure("Price, Quantity, Sum, VATRate, VATSum, DiscountSum, VATDiscountSum, CommissionSum, VATCommissionSum, RoomsRented, BedsRented, AdditionalBedsRented, GuestDays, GuestsCheckedIn, RateSum, RateDiscountSum, RateCommissionSum", 
	                        vSrvRecPrice, pSrvQuantity, pSrvSumInReportingCurrency, pSrvVATRate, pSrvVATSumInReportingCurrency, pSrvDiscountSumInReportingCurrency, pSrvVATDiscountSumInReportingCurrency, pSrvCommissionSumInReportingCurrency, pSrvVATCommissionSumInReportingCurrency, pSrvRec.RoomsRented, pSrvRec.BedsRented, pSrvRec.AdditionalBedsRented, pSrvRec.GuestDays, pSrvRec.GuestsCheckedIn, ?(vIsMainService, Round(cmConvertCurrencies(pSrvRec.RateSum, pSrvRec.FolioCurrency, , ReportingCurrency, , ?(ValueIsFilled(pSrvRec.AccountingDate), pSrvRec.AccountingDate, ExchangeRateDate), Hotel), 2), 0), ?(vIsMainService, Round(cmConvertCurrencies(pSrvRec.RateDiscountSum, pSrvRec.FolioCurrency, , ReportingCurrency, , ?(ValueIsFilled(pSrvRec.AccountingDate), pSrvRec.AccountingDate, ExchangeRateDate), Hotel), 2), 0));
	
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
	pSFRec.Price = cmRecalculatePrice(pSFRec.Sales, pSFRec.Quantity);
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
			If ValueIsFilled(Reservation) Then
				pSFRec.BookingWindow = Round((BegOfDay(CheckInDate) - BegOfDay(Reservation.Date))/(24*3600), 0);
			Else
				pSFRec.BookingWindow = Round((BegOfDay(CheckInDate) - BegOfDay(Date))/(24*3600), 0);
			EndIf;
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
	Movement.GuestGroup = ?(ValueIsFilled(pFolio.GuestGroup), pFolio.GuestGroup, pGuestGroup);
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
	
	// Recalculate forecast resources according to the write off coefficient
	vSrvRec = New Structure("Price, Quantity, Sum, VATRate, VATSum, DiscountSum, VATDiscountSum, CommissionSum, VATCommissionSum, RoomsRented, BedsRented, AdditionalBedsRented, GuestDays, GuestsCheckedIn", 
	                        pSrvRec.Price, pSrvRec.Quantity, pSrvRec.Sum, pSrvRec.VATRate, pSrvRec.VATSum, pSrvRec.DiscountSum, pSrvRec.VATDiscountSum, pSrvRec.CommissionSum, pSrvRec.VATCommissionSum, pSrvRec.RoomsRented, pSrvRec.BedsRented, pSrvRec.AdditionalBedsRented, pSrvRec.GuestDays, pSrvRec.GuestsCheckedIn);
	
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
			If ValueIsFilled(Reservation) Then
				pARFRec.BookingWindow = Round((BegOfDay(CheckInDate) - BegOfDay(Reservation.Date))/(24*3600), 0);
			Else
				pARFRec.BookingWindow = Round((BegOfDay(CheckInDate) - BegOfDay(Date))/(24*3600), 0);
			EndIf;
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
			If ValueIsFilled(Reservation) Then
				pARFRec.ExpectedBookingWindow = Round((BegOfDay(CheckInDate) - BegOfDay(Reservation.Date))/(24*3600), 0);
			Else
				pARFRec.ExpectedBookingWindow = Round((BegOfDay(CheckInDate) - BegOfDay(Date))/(24*3600), 0);
			EndIf;
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
Procedure pmPostToForecastSales(pCancel = False, pRoomsRow = Undefined) Export
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
	vNoVATRate = cmGetNoVATVATRate();
	
	// Clear forecast registers record sets
	RegisterRecords.SalesForecast.Clear();
	RegisterRecords.ServiceRegistration.Clear();
	RegisterRecords.HotelProductLog.Clear();
	RegisterRecords.AccountsReceivableForecast.Clear();
	
	// Create cache value table with service parameters
	vServiceQCRTypes = New ValueTable();
	vServiceQCRTypes.Columns.Add("Service");
	vServiceQCRTypes.Columns.Add("ServiceType");
	vServiceQCRTypes.Columns.Add("QuantityCalculationRule");
	vServiceQCRTypes.Columns.Add("QuantityCalculationRuleType");
	vServiceQCRTypes.Columns.Add("ChargeMealsAtFirstDay");
	vServiceQCRTypes.Columns.Add("ActualAmountIsChargedExternally");
	vServiceQCRTypes.Columns.Add("DoNotChargeInReservations");
	
	// Do movement on accounting date for each service in services
	If ValueIsFilled(Hotel) And ValueIsFilled(Hotel.AccountingDate) And ValueIsFilled(RoomRate) Then
		If (Hotel.CloseOfPeriodDoChargeServices Or RoomRate.CloseOfPeriodDoChargeServices) Then
			vCloseOfDayMode = False;
			If AdditionalProperties.Property("CloseOfDayMode") And AdditionalProperties.CloseOfDayMode Then
				vCloseOfDayMode = AdditionalProperties.CloseOfDayMode;
			EndIf;
			vAccountingDate = Hotel.AccountingDate;
			If ValueIsFilled(vAccountingDate) And AdditionalProperties.Property("AccountingDate") Then
				If ValueIsFilled(AdditionalProperties.AccountingDate) And TypeOf(AdditionalProperties.AccountingDate) = Type("Date") Then
					vAccountingDate = AdditionalProperties.AccountingDate;
				EndIf;
			EndIf;
			If ValueIsFilled(AccommodationStatus) And AccommodationStatus.IsActive And AccommodationStatus.IsInHouse Then
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
				
				// Post services
				For Each vSrvRec In vServices Do	
					If vSrvRec.Quantity = 0 Then
						Continue;
					EndIf;
					If vSrvRec.Service.AlwaysChargeInAdvance Then
						Continue;
					EndIf;
					If ValueIsFilled(vSrvRec.Folio) Then
						vSrvRecFolio = vSrvRec.Folio;
						If ValueIsFilled(vSrvRecFolio.PaymentMethod) And vSrvRecFolio.PaymentMethod.ChargeServicesInAdvance Then
							Continue;
						EndIf;
					EndIf;
					If Not vCloseOfDayMode And vSrvRec.AccountingDate >= vAccountingDate And vSrvRec.AccountingDate > DoChargingToDate And vAccountingDate < BegOfDay(CheckOutDate) And BegOfDay(CurrentSessionDate()) < BegOfDay(CheckOutDate) Or 
					   vCloseOfDayMode And vSrvRec.AccountingDate > vAccountingDate And vSrvRec.AccountingDate > DoChargingToDate And vAccountingDate < BegOfDay(CheckOutDate) And BegOfDay(CurrentSessionDate()) < BegOfDay(CheckOutDate) Then
						vSrvService = vSrvRec.Service;
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
							If BegOfDay(vRRRow.AccountingDate) <= vSrvRec.AccountingDate Then
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
						vServiceDateMove = cmGetServiceDateMove(vQuantityCalculationRule, vQuantityCalculationRuleType, vChargeMealsAtFirstDay, vSrvRec.IsManual, ThisObject, True, vAccountingDateMove);
						
						vSrvSumInReportingCurrency = Round(cmConvertCurrencies((vSrvRec.Sum - vSrvRec.DiscountSum), vSrvRec.FolioCurrency, , ReportingCurrency, , ?(ValueIsFilled(vSrvRec.AccountingDate), vSrvRec.AccountingDate, ExchangeRateDate), Hotel), 2);
						vSrvDiscountSumInReportingCurrency = Round(cmConvertCurrencies(vSrvRec.DiscountSum, vSrvRec.FolioCurrency, , ReportingCurrency, , ?(ValueIsFilled(vSrvRec.AccountingDate), vSrvRec.AccountingDate, ExchangeRateDate), Hotel), 2);
						vSrvVATDiscountSumInReportingCurrency = Round(cmConvertCurrencies(vSrvRec.VATDiscountSum, vSrvRec.FolioCurrency, , ReportingCurrency, , ?(ValueIsFilled(vSrvRec.AccountingDate), vSrvRec.AccountingDate, ExchangeRateDate), Hotel), 2);
						vSrvCommissionSumInReportingCurrency = Round(cmConvertCurrencies(vSrvRec.CommissionSum, vSrvRec.FolioCurrency, , ReportingCurrency, , ?(ValueIsFilled(vSrvRec.AccountingDate), vSrvRec.AccountingDate, ExchangeRateDate), Hotel), 2);
						vSrvVATCommissionSumInReportingCurrency = Round(cmConvertCurrencies(vSrvRec.VATCommissionSum, vSrvRec.FolioCurrency, , ReportingCurrency, , ?(ValueIsFilled(vSrvRec.AccountingDate), vSrvRec.AccountingDate, ExchangeRateDate), Hotel), 2);
						vSrvVATSumInReportingCurrency = Round(cmConvertCurrencies(vSrvRec.VATSum, vSrvRec.FolioCurrency, , ReportingCurrency, , ?(ValueIsFilled(vSrvRec.AccountingDate), vSrvRec.AccountingDate, ExchangeRateDate), Hotel), 2);
						vSrvQuantity = vSrvRec.Quantity;
						vSrvVATRate = vSrvRec.VATRate;
						vRateSumInReportingCurrency = ?(vSrvRec.IsRoomRevenue And vSrvRec.IsInPrice, Round(cmConvertCurrencies((vSrvRec.RateSum - vSrvRec.RateDiscountSum), vSrvRec.FolioCurrency, , ReportingCurrency, , ?(ValueIsFilled(vSrvRec.AccountingDate), vSrvRec.AccountingDate, ExchangeRateDate), Hotel), 2), 0);
						vVATRateSumInReportingCurrency = cmCalculateVATSum(vSrvVATRate, vRateSumInReportingCurrency, vSrvRec.AccountingDate);
						
						vBaseSumInReportingCurrency = vSrvSumInReportingCurrency;
						
						If vSrvSumInReportingCurrency >= 0 And Not vSrvRec.IsSplit Then
							vBDLSettingsDate = GetServiceBreakdownListActiveDate(vSrvService, vSrvRec.AccountingDate, Hotel);
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
											If FixReservationConditions And ValueIsFilled(Reservation) And BegOfDay(Reservation.CheckInDate) < BegOfDay(Reservation.CheckOutDate) Then
												vServiceDate = vServiceDate + vBDLSettingsRow.ServiceDateShift * 24 * 3600;
											ElsIf BegOfDay(CheckInDate) < BegOfDay(CheckOutDate) Then
												vServiceDate = vServiceDate + vBDLSettingsRow.ServiceDateShift * 24 * 3600;
											EndIf;
										EndIf;
										
										// Calculate amount to be posted by this item service
										vItemSumInReportingCurrency = Round(vItemPrice*vItemQuantity, 2);
										If Not vBDLSettingsRow.IsTax Then
											vItemVATSumInReportingCurrency = cmCalculateVATSum(vItemVATRate, vItemSumInReportingCurrency, vSrvRec.AccountingDate);
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
										vSrvDiscountSumInReportingCurrency = vSrvDiscountSumInReportingCurrency - vItemDiscountSumInReportingCurrency;
										vSrvCommissionSumInReportingCurrency = vSrvCommissionSumInReportingCurrency - vItemCommissionSumInReportingCurrency;
										vSrvVATSumInReportingCurrency = vSrvVATSumInReportingCurrency - vItemVATSumInReportingCurrency;
										vSrvVATDiscountSumInReportingCurrency = vSrvVATDiscountSumInReportingCurrency - vItemVATDiscountSumInReportingCurrency;
										vSrvVATCommissionSumInReportingCurrency = vSrvVATCommissionSumInReportingCurrency - vItemVATCommissionSumInReportingCurrency;
										
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
										vPerson = Undefined;
										If (vPersonIndex + vPersonIndexShift) <  AccommodationTemplate.AccommodationTypes.Count() Then
											vPersonAccommodationType = AccommodationTemplate.AccommodationTypes.Get(vPersonIndex + vPersonIndexShift).AccommodationType;
										EndIf;
									EndIf;					
									// Update dimensions
									vSFRec.Client = vPerson;
									vSFRec.ParentDoc = vPersonParentDoc;
									vSFRec.AccommodationType = vPersonAccommodationType;
									If (vPersonIndex + vPersonIndexShift) > 0 Then
										vSFRec.AccommodationTemplate = Undefined;
									EndIf;
									If ValueIsFilled(vPerson) Then
										vSFRec.Age = vPerson.Age;
										vSFRec.AgeRange = vPerson.AgeRange;
									Else
										vSFRec.Age = 0;
										vSFRec.AgeRange = Undefined;
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
			EndIf;
		EndIf;
	EndIf;
			
	// Write RegisterRecords	
	RegisterRecords.ServiceRegistration.Write();
	RegisterRecords.HotelProductLog.Write();
	RegisterRecords.AccountsReceivableForecast.Write();
EndProcedure // pmPostToForecastSales

// -----------------------------------------------------------------------------
Procedure PostToAccumulatingDiscountResources()
	// Clear register records
	RegisterRecords.AccumulatingDiscountResources.Clear();
	// Check conditions
	If ValueIsFilled(Hotel) And ValueIsFilled(Hotel.AccountingDate) And ValueIsFilled(RoomRate) Then
		If (Hotel.CloseOfPeriodDoChargeServices Or RoomRate.CloseOfPeriodDoChargeServices) Then
			vCloseOfDayMode = False;
			If AdditionalProperties.Property("CloseOfDayMode") And AdditionalProperties.CloseOfDayMode Then
				vCloseOfDayMode = AdditionalProperties.CloseOfDayMode;
			EndIf;
			vAccountingDate = Hotel.AccountingDate;
			If ValueIsFilled(vAccountingDate) And AdditionalProperties.Property("AccountingDate") Then
				If ValueIsFilled(AdditionalProperties.AccountingDate) And TypeOf(AdditionalProperties.AccountingDate) = Type("Date") Then
					vAccountingDate = AdditionalProperties.AccountingDate;
				EndIf;
			EndIf;
			If ValueIsFilled(AccommodationStatus) And AccommodationStatus.IsActive And AccommodationStatus.IsInHouse Then
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
						If vSrvRow.Service.AlwaysChargeInAdvance Then
							Continue;
						EndIf;
						If ValueIsFilled(vSrvRow.Folio) Then
							vSrvRecFolio = vSrvRow.Folio;
							If ValueIsFilled(vSrvRecFolio.PaymentMethod) And vSrvRecFolio.PaymentMethod.ChargeServicesInAdvance Then
								Continue;
							EndIf;
						EndIf;
						// Check period
						If Not vCloseOfDayMode And (vSrvRow.AccountingDate < vAccountingDate Or vSrvRow.AccountingDate <= DoChargingToDate Or vAccountingDate >= BegOfDay(CheckOutDate) Or BegOfDay(CurrentSessionDate()) >= BegOfDay(CheckOutDate)) Or 
						   vCloseOfDayMode And (vSrvRow.AccountingDate <= vAccountingDate Or vSrvRow.AccountingDate <= DoChargingToDate Or vAccountingDate >= BegOfDay(CheckOutDate) Or BegOfDay(CurrentSessionDate()) >= BegOfDay(CheckOutDate)) Then
							Continue;
						EndIf;
						// Check discount type is valid period
						If vSrvRow.AccountingDate < vAccDiscount.DateValidFrom Or ValueIsFilled(vAccDiscount.DateValidTo) And vSrvRow.AccountingDate > vAccDiscount.DateValidTo Then
							Continue;
						EndIf;
						vService = vSrvRow.Service;
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
		EndIf;
	EndIf;
	// Write register records
	RegisterRecords.AccumulatingDiscountResources.Write();
EndProcedure // PostToAccumulatingDiscountResources

// -----------------------------------------------------------------------------
Procedure Posting(pCancel, pPostingMode)
	If DataExchange.Load Then
		Return;
	EndIf;
	// Save document posting state
	vReservationWasActive = False;
	If ValueIsFilled(Reservation) And ValueIsFilled(Reservation.ReservationStatus) Then
		vReservationWasActive = Reservation.ReservationStatus.IsActive;
	EndIf;
	// Check if end of day is running
	vCloseOfDayMode = False;
	If AdditionalProperties.Property("CloseOfDayMode") And AdditionalProperties.CloseOfDayMode Then
		vCloseOfDayMode = AdditionalProperties.CloseOfDayMode;
	EndIf;
	If Not vCloseOfDayMode And ValueIsFilled(Company) Then
		// Try to check lock over company
		vDataLock = New DataLock();
		vCmpItem = vDataLock.Add("Catalog.Companies");
		vCmpItem.Mode = DataLockMode.Shared;
		vCmpItem.SetValue("Ref", Company);
		vDataLock.Lock();
	EndIf;
	// Check if we have to rebuild guest folios
	If ValueIsFilled(AccommodationStatus) And AccommodationStatus.IsActive And AccommodationStatus.IsInHouse Then
		pmCheckRoomMainFolios();
	EndIf;
	// Check if room rates are valid
	pmCheckRoomRates();
	// Fill folio parameters
	FillFolioParameters(pCancel);
	// Create vouchers automatically if neccessary
	pmAutoCreateVouchers();
	// To the forecast sales
	pmPostToForecastSales(pCancel);
	// Post to accumulating discount resources
	PostToAccumulatingDiscountResources();
	// Post services
	pmChargeServices(pCancel, pPostingMode);
	// Clear register records
	pmClearInventoryRegisterRecords();
	// Cancel parent reservation
	CancelParentReservation();
	// Update or cancel descendant reservation
	UpdateChildReservations();
	// Process change room action if necessary
	ProcessChangeRoomAction();
	// Post bound resource reservations
	If ValueIsFilled(AccommodationStatus) Then
		vResourceReservations = cmGetChildResourceReservations(?(ValueIsFilled(Reservation), Reservation, Ref), False);
		If Not AccommodationStatus.IsActive Then
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
	// If this is checked out accommodation, then check folio debts
	If ValueIsFilled(AccommodationStatus) Then
		If AccommodationStatus.IsActive And 
		   AccommodationStatus.IsCheckOut And 
		   Not AccommodationStatus.IsInHouse Then
			vCheckFolioDebts = True;
			If AdditionalProperties.Property("CheckFolioDebts") Then
				vCheckFolioDebts = AdditionalProperties.CheckFolioDebts;
			EndIf;
			If vCheckFolioDebts Then
				pmCheckFolioDebts(pCancel, pPostingMode);
			EndIf;
		EndIf;
	EndIf;
	// Change room status
	ChangeRoomStatus(pCancel, pPostingMode);
	// Move guests to the appropriate folder
	MoveGuests(pCancel, pPostingMode);
	// If this is check out or inactive document, then close all open folios
	pmSetFolioStatuses();
	// Set is by reservation
	pmSetIsByReservation();
	// Fill check-out operation time
	FillCheckOutOperationTime();
	// Recalculate document sort code
	vSortCode = cmCalculateReservationSortCode(ThisObject);
	If vSortCode <> SortCode Then
		SortCode = vSortCode;
	EndIf;
	// Write document if it was changed
	If Modified() Then
		Write(DocumentWriteMode.Write);
	EndIf;
	// Delete all unused document folios not in charging rules
	cmDeleteUnusedDocumentFolios(Ref);
	// Write suspicious events if any
	cmWriteSuspiciousAccommodationEvents(ThisObject);
	// Do posting to room inventory
	DoRoomInventoryPosting(pCancel);
	If pCancel Then
		Return;
	EndIf;
	// Post to Pickup register
	PostToPickup();
	// Process room interface statuses
	ProcessRoomInterfaceStatuses();
	// Repost previous accommodation
	RepostPreviousAccommodation();
	// Fill head of group guest, group customer, group period and number of guests checked-in
	FillGroupParameters();
	// Update hotel product parameters
	pmUpdateHotelProductData();
	// Update client identification cards
	pmUpdateClientIdentificationCards();
	// Post to tourist tax register
	pmPostToTouristTax();
	// Recalculate and repost tourist tax for the main guest of the group or for the main guest of the room
	pmRecalculateAndRepostTouristTaxOfTheMainGuest();
	// Copy reservation tasks to this accommodation
	If vReservationWasActive And ValueIsFilled(Reservation) And ValueIsFilled(AccommodationStatus) And AccommodationStatus.IsActive And AccommodationStatus.IsInHouse And AccommodationStatus.IsCheckIn Then
		CopyReservationTasks();
	EndIf;
	// Move bound order to the final state after check-out
	FinishBoundOrders();
	// Attach data scans document
	If Not AdditionalProperties.Property("OperationSource") Or 
	   AdditionalProperties.Property("OperationSource") And AdditionalProperties.OperationSource <> "ClientDataScans" Then
		AttachDataScansDocument();
	EndIf;
	// Attach foreigner registry records
	If Not AdditionalProperties.Property("OperationSource") Or 
	   AdditionalProperties.Property("OperationSource") And AdditionalProperties.OperationSource <> "ForeignerRegistryRecord" Then
		AttachForeignerRegistryRecords();
		ChangeForeignerRegistryRecord(pCancel, pPostingMode);
	EndIf;
	// Send change document status SMS
	If StatusHasChanged Then
		StatusHasChanged = False;
		vMessageDeliveryError = "";
		If Not SMS.SendChangeDocumentSatusMessage(Ref, vMessageDeliveryError) Then
			WriteLogEvent(NStr("en='Document.MessageDelivery';ru='Документ.РассылкаСообщений';de='Document.MessageDelivery'"), EventLogLevel.Warning, Metadata(), Ref, vMessageDeliveryError);
			tcCommonFunctionOnClientServer.TextMessage(vMessageDeliveryError, MessageStatus.Attention);
		EndIf;
	EndIf;
	// Transfer reservation advances to the guest folio
	If ValueIsFilled(Hotel.ReservationAdvancesFolio) And ValueIsFilled(Reservation) Then
		If ValueIsFilled(AccommodationStatus) And AccommodationStatus.IsActive And AccommodationStatus.IsInHouse And AccommodationStatus.IsCheckIn Then
			TransferReservationAdvances();
		EndIf;
	EndIf;
	// Switch off automatic write of register records
	RegisterRecords.AccountsReceivableForecast.Write = False;
	RegisterRecords.AccumulatingDiscountResources.Write = False;
	RegisterRecords.HotelProductLog.Write = False;
	RegisterRecords.SalesForecast.Write();
	RegisterRecords.SalesForecast.Write = False;
	RegisterRecords.ServiceRegistration.Write = False;
EndProcedure // Posting

// -----------------------------------------------------------------------------
Procedure pmPostToTouristTax() Export
	RegisterRecords.TouristTaxToBePaid.Clear();

	If Not ValueIsFilled(GuestGroup) Or ValueIsFilled(GuestGroup) And (Not GuestGroup.TouristicTaxIsCalculatedForMainGroupDocumentOnly Or GuestGroup.TouristicTaxIsCalculatedForMainGroupDocumentOnly And (GuestGroup.ClientDoc = Ref Or GuestGroup.ClientDoc = Reservation And ValueIsFilled(Reservation))) Then
		If ValueIsFilled(AccommodationStatus) And AccommodationStatus.IsActive Then
			If ValueIsFilled(TouristicTaxAccountingDate) And (TouristTaxSumInBaseCurrency <> 0 Or ValueIsFilled(TouristicTaxExemptionReason)) Then
				vTTRcd = RegisterRecords.TouristTaxToBePaid.AddReceipt();

				vTTRcd.Period = TouristicTaxAccountingDate;
				vTTRcd.Recorder = Ref;

				vTTRcd.Reservation = ?(ValueIsFilled(Reservation) And Reservation.RoomQuantity = 1 And Reservation.CheckInDate < CheckOutDate And Reservation.CheckOutDate > CheckInDate, Reservation, Ref);
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
		If ValueIsFilled(vMainDoc) And vMainDoc <> Ref And vMainDoc <> Reservation Then
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
	If IsByReservation And ValueIsFilled(Reservation) Then
		If ValueIsFilled(AccountingCheckInDate) And BegOfDay(vCheckInDate) > AccountingCheckInDate And 
		  (BegOfDay(vCheckInDate) - AccountingCheckInDate)/(24*3600) = 1 And 
		   AccountingCheckInDate = BegOfDay(Reservation.CheckInDate) Then
			vCheckInDate = EndOfDay(AccountingCheckInDate);
		EndIf;
		If FixReservationConditions Then
			vCheckInDate = Reservation.CheckInDate;
		EndIf;
	EndIf;
	If ValueIsFilled(HotelProduct) And Not HotelProduct.IsFolder Then
		If HotelProduct.FixProductPeriod Then
			vCheckInDate = HotelProduct.CheckInDate;
		EndIf;
	EndIf;
	Return vCheckInDate;
EndFunction // pmGetEffectiveCheckInDate

// -----------------------------------------------------------------------------
Procedure PostToPickup()
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
	|		PickupTurnovers.Hotel,
	|		-SUM(PickupTurnovers.Revenue),
	|		-SUM(PickupTurnovers.RevenueWithoutVAT),
	|		-SUM(PickupTurnovers.RoomsRented),
	|		-SUM(PickupTurnovers.BedsRented),
	|		-SUM(PickupTurnovers.AdditionalBedsRented),
	|		-SUM(PickupTurnovers.GuestDays)
	|	FROM
	|		AccumulationRegister.Pickup AS PickupTurnovers
	|	WHERE
	|		PickupTurnovers.Recorder = &qReservation
	|		AND PickupTurnovers.GuestGroup <> VALUE(Catalog.GuestGroups.EmptyRef)
	|		AND &qReservationIsFilled
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
	|		(SalesForecastTurnovers.Recorder = &qRecorder
	|				OR SalesForecastTurnovers.Recorder = &qReservation
	|					AND &qReservationIsFilled)
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
	|		(SalesTurnovers.ParentDoc = &qRecorder
	|				OR SalesTurnovers.ParentDoc = &qReservation
	|					AND &qReservationIsFilled)
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
	vQry.SetParameter("qReservation", Reservation);
	vQry.SetParameter("qReservationIsFilled", ValueIsFilled(Reservation));
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
		vPickupRcd.IsDayuse = ?(BegOfDay(CheckInDate) = BegOfDay(CheckOutDate) And ValueIsFilled(AccommodationStatus) And AccommodationStatus.IsCheckIn And AccommodationStatus.IsCheckOut, True, False);
		vPickupRcd.IsCancel = False;
		vPickupRcd.IsNoShow = False;
		If vPickupRcd.Revenue < 0 Or vPickupRcd.RevenueWithoutVAT < 0 Or 
		   vPickupRcd.RoomsRented < 0 Or vPickupRcd.BedsRented < 0 Or
		   vPickupRcd.AdditionalBedsRented < 0 Or vPickupRcd.GuestDays < 0 Then
			If Not AccommodationStatus.IsActive Then
				vPickupRcd.IsCancel = True;
			EndIf;
		EndIf;
	EndDo;
	
	// Write pickup data
	RegisterRecords.Pickup.Write(True);
EndProcedure // PostToPickup

// -----------------------------------------------------------------------------
Procedure TransferReservationAdvances()
	vFolioFrom = Hotel.ReservationAdvancesFolio;
	// Get folio to transfer advances to
	vFolioTo = Undefined;
	For Each vSrvRow In Services Do
		If vSrvRow.Quantity = 0 Then
			Continue;
		EndIf;
		If vSrvRow.IsRoomRevenue And vSrvRow.IsInPrice Then
			vFolioTo = vSrvRow.Folio;
			Break;
		EndIf;
	EndDo;
	If Not ValueIsFilled(vFolioTo) Then
		Return;
	EndIf;
	// Find open reservation advance balances in the folio from
	vAdvanceAmount = 0;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SUM(Accounts.Sum) AS Sum
	|FROM
	|	AccumulationRegister.Accounts AS Accounts
	|WHERE
	|	Accounts.Folio = &qFolio
	|	AND Accounts.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND Accounts.ParentDoc = &qParentDoc";
	vQry.SetParameter("qFolio", vFolioFrom);
	vQry.SetParameter("qParentDoc", Reservation);
	vRows = vQry.Execute().Unload();
	If vRows.Count() > 0 Then
		For Each vRow In vRows Do
			If vRow.Sum <> Null Then
				vAdvanceAmount = vAdvanceAmount + vRow.Sum;
			EndIf;
		EndDo;
	EndIf;
	If vAdvanceAmount = 0 Then
		Return;
	EndIf;
	// Create deposit transfer operation to transfer advance amount to the guest folio
	vDTObj = Documents.DepositTransfer.CreateDocument();
	vDTObj.Hotel = Hotel;
	vDTObj.Fill(vFolioFrom);
	vDTObj.FolioTo = vFolioTo;
	vDTObj.pmFolioToOnChange();
	vDTObj.ParentDoc = Reservation;
	vDTObj.Remarks = TrimAll(Reservation);
	vDTObj.SumInFolioFromCurrency = vAdvanceAmount;
	vDTObj.SumInFolioToCurrency = 0;
	For Each vPSRow In vDTObj.PaymentSections Do
		If vAdvanceAmount <> 0 Then
			vPSRow.SumInFolioFromCurrency = ?(vPSRow.SumInFolioFromCurrency >= vAdvanceAmount, vAdvanceAmount, vPSRow.SumInFolioFromCurrency);
			vPSRow.SumInFolioToCurrency = 0;
			
			vAdvanceAmount = vAdvanceAmount - vPSRow.SumInFolioFromCurrency;
		Else
			vPSRow.SumInFolioFromCurrency = 0;
			vPSRow.SumInFolioToCurrency = 0;
		EndIf;
	EndDo;
	vDTObj.pmCalculateSums();
	vDTObj.Write(DocumentWriteMode.Posting);
EndProcedure // TransferReservationAdvances

// -----------------------------------------------------------------------------
// Copy tasks from reservation to this accommodation
// -----------------------------------------------------------------------------
Procedure CopyReservationTasks()
	vAccTasks = cmGetMessagesForObject(Ref);
	If vAccTasks.Count() = 0 Then
		vResTasks = cmGetMessagesForObject(Reservation);
		For Each vResTasksRow In vResTasks Do
			vResTaskRef = vResTasksRow.Recorder;
			vAccTaskObj = vResTaskRef.Copy();
			vAccTaskObj.Author = vResTaskRef.Author;
			vAccTaskObj.Date = vResTaskRef.Date;
			vAccTaskObj.ByObject = Ref;
			vAccTaskObj.Write(DocumentWriteMode.Posting);
		EndDo;
	EndIf;
EndProcedure // CopyReservationTasks 

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
			If Not AccommodationStatus.IsInHouse And 
			   vRRSrvRow.ResourceReservation.ResourceReservationStatus = cmGetDeliveredResourceReservationStatus(Hotel) Then
				Continue;
			EndIf;
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
		vDocObj.GuestGroup = ?(ValueIsFilled(vFolio.GuestGroup), vFolio.GuestGroup, GuestGroup);
		If AccommodationStatus.IsInHouse Then
			vDocObj.ResourceReservationStatus = vDocObj.Hotel.NewResourceReservationStatus;
		Else
			vDocObj.ResourceReservationStatus = cmGetDeliveredResourceReservationStatus(vDocObj.Hotel);
		EndIf;
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
		vDocObj.ParentDoc = ?(ValueIsFilled(Reservation), Reservation, Ref);
		vDocObj.Remarks = TrimAll(vRRSrvRow.Remarks);
		vDocObj.DoNotCalculateServices = True;
		vDocObj.DeletionMark = False;
		vDocObj.pmCalculateServices();
		vDocObj.Write(DocumentWriteMode.Posting);
		vDocObj.pmWriteToResourceReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
	EndDo;
EndProcedure // PostResourceReservations	

// -----------------------------------------------------------------------------
Function pmGetResourceServices() Export
	vRRServices = Services.Unload();
	vRRServices.Clear();
	For Each vSrvRow In Services Do
		If ValueIsFilled(vSrvRow.AccountingDate) And 
		   ValueIsFilled(vSrvRow.ServiceResource) And TypeOf(vSrvRow.ServiceResource) = Type("CatalogRef.Resources") And 
		   vSrvRow.DoResourceReservation Then
			vRRServicesRow = vRRServices.Add();
			FillPropertyValues(vRRServicesRow, vSrvRow);
		EndIf;
	EndDo;
	Return vRRServices;
EndFunction // pmGetResourceServices

// -----------------------------------------------------------------------------
Procedure pmUpdateClientIdentificationCards() Export
	If ValueIsFilled(AccommodationStatus) And AccommodationStatus.IsActive And AccommodationStatus.IsInHouse Then
		// Search for client identification cards issued for the accommodation
		If ValueIsFilled(Guest) Then
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	IdentificationCards.Ref
			|FROM
			|	Catalog.IdentificationCards AS IdentificationCards
			|WHERE
			|	(NOT IdentificationCards.DeletionMark)
			|	AND IdentificationCards.ParentDoc = &qAccommodation
			|	AND IdentificationCards.Client <> &qClient
			|
			|ORDER BY
			|	IdentificationCards.Code";
			vQry.SetParameter("qAccommodation", Ref);
			vQry.SetParameter("qClient", Guest);
			vCards = vQry.Execute().Unload();
			For Each vCardsRow In vCards Do
				vCardObj = vCardsRow.Ref.GetObject();
				vCardObj.Read();
				vCardObj.Room = Room;
				vCardObj.DateTimeTo = CheckOutDate;
				vCardObj.Client = Guest;
				vCardObj.Write();
			EndDo;
		EndIf;
		// Search for client identification cards issued for the reservation
		If ValueIsFilled(Reservation) Then
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	IdentificationCards.Ref
			|FROM
			|	Catalog.IdentificationCards AS IdentificationCards
			|WHERE
			|	(NOT IdentificationCards.DeletionMark)
			|	AND IdentificationCards.ParentDoc = &qReservation
			|
			|ORDER BY
			|	IdentificationCards.Code";
			vQry.SetParameter("qReservation", Reservation);
			vCards = vQry.Execute().Unload();
			For Each vCardsRow In vCards Do
				vCardObj = vCardsRow.Ref.GetObject();
				vCardObj.Read();
				vCardObj.ParentDoc = Ref;
				vCardObj.Room = Room;
				vCardObj.DateTimeTo = CheckOutDate;
				If ValueIsFilled(Guest) Then
					vCardObj.Client = Guest;
				EndIf;
				vCardObj.Write();
			EndDo;
		EndIf;
		// Search for client identification cards issued for the previous accommodation
		If ValueIsFilled(Reservation) And ValueIsFilled(Reservation.ParentDoc) And TypeOf(Reservation.ParentDoc) = Type("DocumentRef.Accommodation") Then
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	IdentificationCards.Ref
			|FROM
			|	Catalog.IdentificationCards AS IdentificationCards
			|WHERE
			|	(NOT IdentificationCards.DeletionMark)
			|	AND IdentificationCards.ParentDoc = &qAccommodation
			|
			|ORDER BY
			|	IdentificationCards.Code";
			vQry.SetParameter("qAccommodation", Reservation.ParentDoc);
			vCards = vQry.Execute().Unload();
			For Each vCardsRow In vCards Do
				vCardObj = vCardsRow.Ref.GetObject();
				vCardObj.Read();
				vCardObj.ParentDoc = Ref;
				vCardObj.Room = Room;
				vCardObj.DateTimeTo = CheckOutDate;
				If ValueIsFilled(Guest) Then
					vCardObj.Client = Guest;
				EndIf;
				vCardObj.Write();
			EndDo;
		EndIf;
	EndIf;
EndProcedure // pmUpdateClientIdentificationCards

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
	vResourceReservations = cmGetChildResourceReservations(?(ValueIsFilled(Reservation), Reservation, Ref), True);
	For Each vResourceReservationsRow In vResourceReservations Do
		vResourceReservationObj = vResourceReservationsRow.Ref.GetObject();
		vResourceReservationObj.AdditionalProperties.Insert("AllowSetDeletionMark", True);
		vResourceReservationObj.SetDeletionMark(True);
	EndDo;
	// 4. Switch off all room interface statuses
	If pmIsMainAccommodationType() Then
		SwitchOffRoomInterfaceStatuses();
	EndIf;
EndProcedure // pmUndoPosting

// -----------------------------------------------------------------------------
Procedure UndoPosting(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	// Remove room inventory movements, recalculate room inventory balances and delete charges
	pmUndoPosting(pCancel);
EndProcedure // UndoPosting

// -----------------------------------------------------------------------------
Procedure BeforeDelete(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	// Remove room inventory movements, recalculate room inventory balances and delete charges
	If Posted Then
		If ValueIsFilled(Hotel) And Hotel.DoNotEditSettledDocs And 
		  (Services.Total("Sum") <> 0 Or Services.Total("Quantity") <> 0) And 
		   ValueIsFilled(AccommodationStatus) And AccommodationStatus.IsActive And Not AccommodationStatus.IsInHouse And
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
				tcCommonFunctionOnClientServer.TextMessage(NStr("ru='Все начисления размещения уже закрыты актами об оказании услуг! Редактирование такого размещения запрещено.';en='All accommodation charges are closed by invoices! Accommodation is read only.';de='Alle Übernachtungskosten werden durch Rechnungen geschlossen! Die Unterkunft ist nur lesbar.'"), MessageStatus.Attention);
				Return;
			EndIf;
		EndIf;
		pmUndoPosting(pCancel);
	EndIf;    
	vEventDescription = NStr("en='Document deletion';ru='Непосредственное удаление';de='Unmittelbare Loschung'");
	// User activity history    
	InformationRegisters.UserActionsHistory.WriteUserActivityRecord(Ref, vEventDescription, Hotel);
EndProcedure // BeforeDelete

// -----------------------------------------------------------------------------
Procedure FillRChgAttributes(pRChgRec, pPeriod, pUser)
	FillPropertyValues(pRChgRec, ThisObject);
	
	pRChgRec.Period = pPeriod;
	pRChgRec.Accommodation = Ref;
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
	vOccupationPercents = New ValueStorage(OccupationPercents.Unload());
	pRChgRec.OccupationPercents = vOccupationPercents;
	vRoomProperties = New ValueStorage(RoomProperties.Unload());
	pRChgRec.RoomProperties = vRoomProperties;
EndProcedure // FillRChgAttributes

// -----------------------------------------------------------------------------
Procedure pmWriteToAccommodationChangeHistory(pPeriod, pUser) Export
	// Get channges description
	vChanges = cmGetObjectChanges(ThisObject);
	If Not IsBlankString(vChanges) Then
		// Do movement on current date
		vRChgRec = InformationRegisters.AccommodationChangeHistory.CreateRecordManager();
		
		FillRChgAttributes(vRChgRec, pPeriod, pUser);
		vRChgRec.Changes = vChanges;
		
		// Write record
		vRChgRec.Write(True);
		
		// User activity history
		InformationRegisters.UserActionsHistory.WriteUserActivityRecord(Ref, vChanges, Hotel, pUser, pPeriod);
	EndIf;
EndProcedure // pmWriteToAccommodationChangeHistory

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
EndProcedure // pmRestoreAttributesFromHistory

// -----------------------------------------------------------------------------
Function pmGetLastInHouseDocumentState() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	* 
	|FROM
	|	InformationRegister.AccommodationChangeHistory AS AccommodationChangeHistory
	|WHERE
	|	AccommodationChangeHistory.Accommodation = &qDoc
	|	AND AccommodationChangeHistory.AccommodationStatus.IsInHouse
	|ORDER BY
	|	Period DESC";
	vQry.SetParameter("qDoc", Ref);
	vStates = vQry.Execute().Unload();
	If vStates.Count() > 0 Then
		Return vStates.Get(0);
	Else
		Return Undefined;
	EndIf;
EndFunction // pmGetLastInHouseDocumentState

// -----------------------------------------------------------------------------
Function pmGetLastDocumentState() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	* 
	|FROM
	|	InformationRegister.AccommodationChangeHistory AS AccommodationChangeHistory
	|WHERE
	|	AccommodationChangeHistory.Accommodation = &qDoc
	|ORDER BY
	|	Period DESC";
	vQry.SetParameter("qDoc", Ref);
	vStates = vQry.Execute().Unload();
	If vStates.Count() > 0 Then
		Return vStates.Get(0);
	Else
		Return Undefined;
	EndIf;
EndFunction // pmGetLastDocumentState

// -----------------------------------------------------------------------------
Function pmGetPreviousObjectState(pPeriod, pMergeGuestState = False) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	*
	|FROM
	|	InformationRegister.AccommodationChangeHistory.SliceLast(&qPeriod, Accommodation = &qDoc) AS AccommodationChangeHistoryState";
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
EndFunction // pmGetPreviousObjectState

// -----------------------------------------------------------------------------
Function IsChangeOfAccommodationConditions(pIsByReservation, rIsFirstAccState = True)
	rIsFirstAccState = True;
	vIsChangeOfAccConditions = True;
	If Posted Then
		vPrevAccState = pmGetAccommodationAttributes(CurrentSessionDate());
		If pIsByReservation And vPrevAccState.Count() = 0 Then
			vIsChangeOfAccConditions = False;
		EndIf;
		For Each vPrevAccStateRow In vPrevAccState Do
			rIsFirstAccState = False;
			If cm0SecondShift(vPrevAccStateRow.CheckInDate) <= cm0SecondShift(CheckInDate) And
			   cm0SecondShift(vPrevAccStateRow.CheckOutDate) >= cm0SecondShift(CheckOutDate) And 
			   vPrevAccStateRow.RoomType = RoomType And
			   vPrevAccStateRow.AccommodationType = AccommodationType And 
			   ValueIsFilled(AccommodationStatus) And ValueIsFilled(vPrevAccStateRow.AccommodationStatus) And 
			   AccommodationStatus.IsActive = vPrevAccStateRow.AccommodationStatus.IsActive And 
			   Not ThereAreChangesInRoomRates(vPrevAccStateRow) Then
				vIsChangeOfAccConditions = False;
			EndIf;
			Break;
		EndDo;
	EndIf;
	Return vIsChangeOfAccConditions;
EndFunction // IsChangeOfAccommodationConditions

// -----------------------------------------------------------------------------
Function CheckRoomTypeBalances()
	vCheck = Not IsByReservation;
	// Check parent reservation conditions
	If IsByReservation Then
		vParentReservationRef = pmGetParentReservation();
		If ValueIsFilled(vParentReservationRef) Then
			rIsFirstAccState = True;
			If IsChangeOfAccommodationConditions(True, rIsFirstAccState) Then
				vCheck = True;
			Else
				If rIsFirstAccState And 
				  (vParentReservationRef.RoomType <> RoomType Or
				   vParentReservationRef.RoomQuota <> RoomQuota Or
				   vParentReservationRef.AccommodationType <> AccommodationType Or
				   BegOfDay(vParentReservationRef.CheckInDate) > BegOfDay(CheckInDate) Or
				   vParentReservationRef.CheckOutDate < CheckOutDate Or 
				   Not vParentReservationRef.Posted) Then
					vCheck = True;
				EndIf;
			EndIf;
		Else
			If IsChangeOfAccommodationConditions(False) Then
				vCheck = True;
			EndIf;
		EndIf;
	Else
		If Not IsChangeOfAccommodationConditions(False) Then
			vCheck = False;
		EndIf;
	EndIf;
	Return vCheck;
EndFunction // CheckRoomTypeBalances

// -----------------------------------------------------------------------------
Function GetGuestOtherActiveAccommodations(pGuest, pObj)
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.CheckInDate AS CheckInDate,
	|	Accommodation.CheckOutDate AS CheckOutDate,
	|	Accommodation.Duration AS Duration,
	|	Accommodation.RoomType AS RoomType,
	|	Accommodation.Room AS Room,
	|	Accommodation.AccommodationType AS AccommodationType,
	|	Accommodation.GuestGroup.Code AS GuestGroupCode,
	|	Accommodation.Hotel AS Hotel
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.Posted
	|	AND Accommodation.Guest = &qGuest
	|	AND Accommodation.Ref <> &qAccomm
	|	AND Accommodation.Number <> &qNumber
	|	AND (Accommodation.AccommodationStatus.IsActive AND Accommodation.AccommodationStatus.IsInHouse)
	|
	|ORDER BY
	|	CheckInDate";
	vQry.SetParameter("qGuest", pGuest);
	vQry.SetParameter("qAccomm", pObj);
	vQry.SetParameter("qNumber", pObj.Number);
	vResList = vQry.Execute().Unload();
	Return vResList; 	
EndFunction // GetGuestOtherActiveAccommodations

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
EndFunction // ThereAreChangesInRoomRates

// -----------------------------------------------------------------------------
Function pmCheckDocumentAttributes(pPeriod, pIsPosted, pMessage, pAttributeInErr, pDoNotCheckRests = False, pDoCheckRests = False) Export
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
	If Not ValueIsFilled(AccommodationStatus) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Статус размещения> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Accommodation status> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Accommodation status> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "AccommodationStatus", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(pPeriod.AccommodationType) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Вид размещения> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Accommodation type> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Accommodation type> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "AccommodationType", pAttributeInErr);
	ElsIf ValueIsFilled(Guest) And ValueIsFilled(CheckInDate) Then
		If Not ValueIsFilled(Guest.DateOfBirth) And GuestAge = 0 Then
			If AccommodationType.AllowedClientAgeFrom <> 0 Or 
			   AccommodationType.AllowedClientAgeTo <> 0 Or 
			   ValueIsFilled(AccommodationType.AllowedClientAgeRange) Then
				If Not cmCheckUserPermissions("HavePermissionToIgnoreGuestAgeLimitations") Then
					vMsgTextRu = vMsgTextRu + "Не указана дата рождения гостя " + TrimAll(Guest) + "!" + Chars.LF;
					vMsgTextEn = vMsgTextEn + "Date of birth is not specified for guest " + TrimAll(Guest) + "!" + Chars.LF;
					vMsgTextDe = vMsgTextDe + "Date of birth is not specified for guest " + TrimAll(Guest) + "!" + Chars.LF;
					pAttributeInErr = ?(pAttributeInErr = "", "Guest", pAttributeInErr);
					vHasErrors = True; 
				EndIf;
			EndIf;
		EndIf;
		vGuestAge = Guest.GetObject().pmGetClientAge(CheckInDate);
		If vGuestAge = 0 Then
			vGuestAge = GuestAge;
		EndIf;
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
		vMsgTextDe = vMsgTextDe + "<Room type> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "RoomType", pAttributeInErr);
	Else
		If pPeriod.RoomType.IsVirtual Then
			If Not cmCheckUserPermissions("HavePermissionToUseVirtualRooms") Then
				vHasErrors = True; 
				vMsgTextRu = vMsgTextRu + "Нет прав на поселение гостей в виртуальные типы номеров!" + Chars.LF;
				vMsgTextEn = vMsgTextEn + "You do not have rights to check-in to the virtual room types!" + Chars.LF;
				vMsgTextDe = vMsgTextDe + "You do not have rights to check-in to the virtual room types!" + Chars.LF;
				pAttributeInErr = ?(pAttributeInErr = "", "RoomType", pAttributeInErr);
			EndIf;
		EndIf;
	EndIf;
	If Not ValueIsFilled(pPeriod.Room) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Номер> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Room> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Room> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Room", pAttributeInErr);
	Else
		If pPeriod.Room.IsVirtual Then
			If Not cmCheckUserPermissions("HavePermissionToUseVirtualRooms") Then
				vHasErrors = True; 
				vMsgTextRu = vMsgTextRu + "Нет прав на поселение гостей в виртуальные номера!" + Chars.LF;
				vMsgTextEn = vMsgTextEn + "You do not have rights to check-in to the virtual rooms!" + Chars.LF;
				vMsgTextDe = vMsgTextDe + "You do not have rights to check-in to the virtual rooms!" + Chars.LF;
				pAttributeInErr = ?(pAttributeInErr = "", "Room", pAttributeInErr);
			EndIf;
		EndIf;
	EndIf;
	If Not ValueIsFilled(pPeriod.CheckInDate) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Дата заезда> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Check in date> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Check in date> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "CheckInDate", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(pPeriod.CheckOutDate) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Дата выезда> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Check out date> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Check out date> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "CheckOutDate", pAttributeInErr);
	EndIf;
	If ValueIsFilled(pPeriod.CheckInDate) And ValueIsFilled(pPeriod.CheckOutDate) Then
		If pPeriod.CheckInDate > pPeriod.CheckOutDate Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Дата выезда должна быть позже даты заезда!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "Check out date should be after check in date!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "Check out date should be after check in date!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "CheckOutDate", pAttributeInErr);
		Else
			If ValueIsFilled(Contract) Then
				If Contract.PeriodCheckType = 0 Then
					If ValueIsFilled(Contract.ValidFromDate) And 
					   pPeriod.CheckInDate < BegOfDay(Contract.ValidFromDate) Or
					   ValueIsFilled(Contract.ValidToDate) And
					   pPeriod.CheckInDate > EndOfDay(Contract.ValidToDate) Then
						vHasErrors = True; 
						vMsgTextRu = vMsgTextRu + "Выбранный договор не действует на указанном периоде проживания!" + Chars.LF;
						vMsgTextEn = vMsgTextEn + "Contract is not valid on period selected!" + Chars.LF;
						vMsgTextDe = vMsgTextDe + "Contract is not valid on period selected!" + Chars.LF;
						pAttributeInErr = ?(pAttributeInErr = "", "Contract", pAttributeInErr);
					EndIf;
				ElsIf Contract.PeriodCheckType = 1 And Not IsByReservation Then
					If ValueIsFilled(Contract.ValidFromDate) And 
					   Date < BegOfDay(Contract.ValidFromDate) Or
					   ValueIsFilled(Contract.ValidToDate) And
					   Date > EndOfDay(Contract.ValidToDate) Then
						vHasErrors = True; 
						vMsgTextRu = vMsgTextRu + "Выбранный договор не действует на дату создания размещения!" + Chars.LF;
						vMsgTextEn = vMsgTextEn + "Contract is not valid on accommodation creation date!" + Chars.LF;
						vMsgTextDe = vMsgTextDe + "Contract is not valid on accommodation creation date!" + Chars.LF;
						pAttributeInErr = ?(pAttributeInErr = "", "Contract", pAttributeInErr);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If Not vHasErrors And Not (AdditionalProperties.Property("CloseOfDayMode") And AdditionalProperties.CloseOfDayMode) Then
		If Not cmCheckUserPermissions("HavePermissionToDoCheckInWithEmptyGuest") Then
			If Not ValueIsFilled(Guest) Then
				vHasErrors = True; 
				vMsgTextRu = vMsgTextRu + "Не указан гость!" + Chars.LF;
				vMsgTextEn = vMsgTextEn + "Guest should be filled!" + Chars.LF;
				vMsgTextDe = vMsgTextDe + "Guest should be filled!" + Chars.LF;
				pAttributeInErr = ?(pAttributeInErr = "", "Guest", pAttributeInErr);
			EndIf;
		EndIf;
		If Not Posted And AccommodationStatus.IsInHouse And cmCheckUserPermissions("HavePermissionToForbiddenCheckInForGuestsWithActiveAccommodation") Then
			If ValueIsFilled(Guest) Then
				vGuestOtherAccommodations = GetGuestOtherActiveAccommodations(Guest, pPeriod.Ref);
				If vGuestOtherAccommodations.Count() > 0 Then  
					vRow = vGuestOtherAccommodations.Get(0);				
					vHasErrors = True; 				
					vTextRu = "У гостя " + TrimAll(Guest.FullName) + " уже есть активное размещение на срок " +
					          Format(vRow.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(vRow.CheckOutDate, "DF='dd.MM.yyyy HH:mm'") +
					          " в "+ TrimAll(vRow.Hotel) + ", группа "+ Format(vRow.GuestGroupCode, "ND=12; NFD=0; NG=") + ", тип номера " + 
					          TrimAll(vRow.RoomType) + ", номер "  + TrimAll(vRow.Room)+"!";
					vTextEn = "The guest " + TrimAll(Guest.FullName) + " already has an active accommodation for a period " +
					          Format(vRow.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(vRow.CheckOutDate, "DF='dd.MM.yyyy HH:mm'") +
					          " in "+ TrimAll(vRow.Hotel) + ", guest group "+ Format(vRow.GuestGroupCode, "ND=12; NFD=0; NG=") + ", room type " + 
					          TrimAll(vRow.RoomType) + ", room "  + TrimAll(vRow.Room)+"!";
					vTextDe = "Der Gast " + TrimAll(Guest.FullName) + " hat bereits eine aktive Belegung für die Dauer " +
					          Format(vRow.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(vRow.CheckOutDate, "DF='dd.MM.yyyy HH:mm'") +
					          " im "+ TrimAll(vRow.Hotel) + ", Gruppe "+ Format(vRow.GuestGroupCode, "ND=12; NFD=0; NG=") + ", Zimmertypen " + 
					          TrimAll(vRow.RoomType) + ", Zimmer "  + TrimAll(vRow.Room)+"!";  			
					vMsgTextRu = vMsgTextRu + vTextRu + Chars.LF;
					vMsgTextEn = vMsgTextEn + vTextEn + Chars.LF;
					vMsgTextDe = vMsgTextDe + vTextDe + Chars.LF;
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(Guest) Then
			If Guest.DoNotCheckIn Then
				If Not cmCheckUserPermissions("HavePermissionToIgnoreBlackListLimitations") Then
					vHasErrors = True; 
					vMsgTextRu = vMsgTextRu + "У гостя установлен режим запрета поселения!" + Chars.LF;
					vMsgTextEn = vMsgTextEn + "Guest check-in is forbidden!" + Chars.LF;
					vMsgTextDe = vMsgTextDe + "Guest check-in is forbidden!" + Chars.LF;
					pAttributeInErr = ?(pAttributeInErr = "", "Guest", pAttributeInErr);
				EndIf;
			EndIf;
		EndIf;
		If BegOfDay(pPeriod.CheckInDate) = BegOfDay(CurrentSessionDate()) And ValueIsFilled(AccommodationStatus) And AccommodationStatus.IsActive And 
		   AccommodationStatus.IsCheckIn And AccommodationStatus.IsInHouse And 
		   ValueIsFilled(pPeriod.Room) And ValueIsFilled(pPeriod.Room.RoomStatus) Then
			If pPeriod.Room.RoomStatus.CheckInIsForbidden Then
				If Not cmCheckUserPermissions("HavePermissionToCheckInToRoomsWithForbiddenStatus") Then
					vHasErrors = True; 
					vMsgTextRu = vMsgTextRu + "Нет прав на поселение гостя в номер со статусом " + TrimAll(pPeriod.Room.RoomStatus) + "!" + Chars.LF;
					vMsgTextEn = vMsgTextEn + "You do not have rights to check-in guest to the room with " + TrimAll(pPeriod.Room.RoomStatus) + " status!" + Chars.LF;
					vMsgTextDe = vMsgTextDe + "You do not have rights to check-in guest to the room with " + TrimAll(pPeriod.Room.RoomStatus) + " status!" + Chars.LF;
					pAttributeInErr = ?(pAttributeInErr = "", "Room", pAttributeInErr);
				EndIf;
			EndIf;
		EndIf;
		If Not ValueIsFilled(BoardPlace) Then
			If Not cmCheckUserPermissions("HavePermissionToSkipBoardPlaceSetting") And Not pDoNotCheckRests Then
				vBoardPlaces = cmGetBoardPlaces(Hotel);
				If vBoardPlaces.Count() > 0 Then
					vHasErrors = True; 
					vMsgTextRu = vMsgTextRu + "Нет прав на поселение гостя без указания места питания!" + Chars.LF;
					vMsgTextEn = vMsgTextEn + "You do not have rights to check-in guest with no board place setting!" + Chars.LF;
					vMsgTextDe = vMsgTextDe + "Es gibt kein Rechte auf Nahrung nicht in der Reservierung angeben!" + Chars.LF;
					pAttributeInErr = ?(pAttributeInErr = "", "BoardPlace", pAttributeInErr);
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(AccommodationStatus) Then
			vRes = pmGetParentReservation();
			If Not ValueIsFilled(vRes) And ValueIsFilled(RoomType) Or
			   ValueIsFilled(vRes) And vRes.RoomType <> RoomType Or
			   ValueIsFilled(vRes) And vRes.RoomType = RoomType And BegOfDay(vRes.CheckOutDate) < BegOfDay(CheckOutDate) Then
				If RoomType.StopSale And NumberOfBeds > 0 Then
					vRemarks = "";
					If cmIsStopSalePeriod(RoomType, CheckInDate, CheckOutDate, vRemarks) Then
						If Not cmCheckUserPermissions("HavePermissionToIgnoreStopSaleLimitations") Then
							vHasErrors = Not Posted;
						Else
							vHasErrors = False;
						EndIf;
						vMsgTextRu = vMsgTextRu + "Выбранный тип номера снят с продажи!" + Chars.LF + ?(IsBlankString(vRemarks), "", vRemarks + Chars.LF);
						vMsgTextEn = vMsgTextEn + "Room type choosen is out of sale!" + Chars.LF + ?(IsBlankString(vRemarks), "", vRemarks + Chars.LF);
						vMsgTextDe = vMsgTextDe + "Room type choosen is out of sale!" + Chars.LF + ?(IsBlankString(vRemarks), "", vRemarks + Chars.LF);
						pAttributeInErr = ?(pAttributeInErr = "", "RoomType", pAttributeInErr);
					EndIf;
				EndIf;
			EndIf;
			If Not ValueIsFilled(vRes) And ValueIsFilled(Room) Or 
			   ValueIsFilled(vRes) And ValueIsFilled(vRes.Room) And vRes.Room <> Room Or 
			   ValueIsFilled(vRes) And ValueIsFilled(vRes.Room) And vRes.Room = Room And BegOfDay(vRes.CheckOutDate) < BegOfDay(CheckOutDate) Or 
			   ValueIsFilled(vRes) And Not ValueIsFilled(vRes.Room) Then
				If Room.StopSale And NumberOfBeds > 0 Then
					vRemarks = "";
					If cmIsRoomStopSalePeriod(Room, CheckInDate, CheckOutDate, vRemarks) Then
						If Not cmCheckUserPermissions("HavePermissionToIgnoreStopSaleLimitations") Then
							vHasErrors = Not Posted;
						Else
							vHasErrors = False;
						EndIf;
						vMsgTextRu = vMsgTextRu + "Выбранный номер снят с продажи!" + Chars.LF + ?(IsBlankString(vRemarks), "", vRemarks + Chars.LF);
						vMsgTextEn = vMsgTextEn + "Room choosen is out of sale!" + Chars.LF + ?(IsBlankString(vRemarks), "", vRemarks + Chars.LF);
						vMsgTextDe = vMsgTextDe + "Room choosen is out of sale!" + Chars.LF + ?(IsBlankString(vRemarks), "", vRemarks + Chars.LF);
						pAttributeInErr = ?(pAttributeInErr = "", "Room", pAttributeInErr);
					EndIf;
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
		If Not pDoNotCheckRests And ValueIsFilled(AccommodationStatus) Then    
			vLastDocState = pmGetPreviousObjectState(CurrentSessionDate());
			If AccommodationStatus.IsActive Then
				If Not vHasErrors Then
					vMsgTextRu = ""; vMsgTextEn = ""; vMsgTextde = "";
					vAccessibilityAttributesChanged = False;
					If vLastDocState = Undefined Then
						vAccessibilityAttributesChanged = True;   
					ElsIf AccommodationStatus <> vLastDocState.AccommodationStatus And vLastDocState.AccommodationStatus.IsActive = False Then	
						vAccessibilityAttributesChanged = True;	
					ElsIf vLastDocState.RoomQuota <> RoomQuota Then
						vAccessibilityAttributesChanged = True;
					ElsIf vLastDocState.CheckInDate <> CheckInDate Or vLastDocState.CheckOutDate <> CheckOutDate Or 
					      vLastDocState.RoomType <> RoomType Or vLastDocState.Room <> Room Or
					      vLastDocState.AccommodationType <> AccommodationType Or
					      ThereAreChangesInRoomRates(vLastDocState) Then
						vAccessibilityAttributesChanged = True;  
					EndIf;	
					If vAccessibilityAttributesChanged And Max(CurrentSessionDate(), pPeriod.CheckInDate) < pPeriod.CheckOutDate Then
						If Not cmCheckRoomAvailability(Hotel, RoomQuota, pPeriod.RoomType, pPeriod.Room, Ref, pIsPosted, ?(pDoCheckRests, True, CheckRoomTypeBalances()),
						                               pPeriod.NumberOfPersons, pPeriod.NumberOfRooms, pPeriod.NumberOfBeds, pPeriod.NumberOfAdditionalBeds, 
						                               pPeriod.NumberOfBedsPerRoom, pPeriod.NumberOfPersonsPerRoom, Max(CurrentSessionDate(), pPeriod.CheckInDate), pPeriod.CheckOutDate, 
						                               vMsgTextRu, vMsgTextEn, vMsgTextDe) Then
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
				If ValueIsFilled(RoomQuota) And ValueIsFilled(pPeriod.AccommodationType) And 
				   (pPeriod.AccommodationType.Type = Enums.AccomodationTypes.Beds Or pPeriod.AccommodationType.Type = Enums.AccomodationTypes.Room) Then
					If RoomQuota.CustomerOrContractChangeIsNotAllowed Then
						If RoomQuota.Customer <> Customer Or
						   RoomQuota.Contract <> Contract Then
							vHasErrors = True; 
							vMsgTextRu = vMsgTextRu + "Поселение с указанием контрагента/договора отличных от них в выбранной квоте запрещено!" + Chars.LF;
							vMsgTextEn = vMsgTextEn + "It is not allowed to check-in with customer/contract different from them in allotment choosen!" + Chars.LF;
							vMsgTextDe = vMsgTextDe + "It is not allowed to check-in with customer/contract different from them in allotment choosen!" + Chars.LF;
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
						ElsIf AccommodationStatus <> vLastDocState.AccommodationStatus And vLastDocState.AccommodationStatus.IsActive = False Then	
							vAccessibilityAttributesChanged = True;	
						ElsIf vLastDocState.RoomQuota <> RoomQuota Then
							vAccessibilityAttributesChanged = True;
						ElsIf vLastDocState.CheckInDate <> CheckInDate Or vLastDocState.CheckOutDate <> CheckOutDate Or 
						      vLastDocState.RoomType <> RoomType Or vLastDocState.Room <> Room Or
						      vLastDocState.AccommodationType <> AccommodationType Or
						      ThereAreChangesInRoomRates(vLastDocState) Then
							vAccessibilityAttributesChanged = True;  
						EndIf;	
						If vAccessibilityAttributesChanged And Max(CurrentSessionDate(), pPeriod.CheckInDate) < pPeriod.CheckOutDate Then
							If Not cmCheckRoomQuotaAvailability(RoomQuota.Agent, RoomQuota.Customer, RoomQuota.Contract, RoomQuota, 
							                                    Hotel, vRoomType, pPeriod.Room, Ref, pIsPosted, False,
							                                    pPeriod.NumberOfRooms, pPeriod.NumberOfBeds, 
							                                    Max(CurrentSessionDate(), pPeriod.CheckInDate), pPeriod.CheckOutDate, 
							                                    vMsgTextRu, vMsgTextEn, vMsgTextDe) Then
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
							   Not RoomQuota.OverbookingIsNotAllowed And Not RoomQuota.IsQuotaForRooms And RoomQuota.AllotmentBusinessType = Enums.AllotmentBusinessTypes.BusinessBlock Then
								AdditionalProperties.Insert("AddRoomsToAllotment", True);
								FillAllotmentBalances(pPeriod);
							EndIf;
							If Not IsByReservation And ValueIsFilled(AccommodationStatus) And 
							   AccommodationStatus.IsActive And AccommodationStatus.IsInHouse Then
								If RoomQuota.IsForCheckInPeriods And pPeriod.CheckInDate = CheckInDate Then
									If Not vHasErrors Then
										vMsgTextRu = ""; vMsgTextEn = ""; vMsgTextde = "";
										If Not cmCheckCheckInPeriods(Hotel, RoomQuota, CheckInDate, CheckOutDate) Then
											vHasErrors = True; 
											vMsgTextRu = vMsgTextRu + "Указанный срок проживания не попадает на границы заездов!" + Chars.LF;
											vMsgTextEn = vMsgTextEn + "Accommodation period specified is out from the check-in period dates!" + Chars.LF;
											vMsgTextDe = vMsgTextDe + "Accommodation period specified is out from the check-in period dates!" + Chars.LF;
											pAttributeInErr = ?(pAttributeInErr = "", "CheckOutDate", pAttributeInErr);
										EndIf;
									EndIf;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
				EndIf;  
				// Check rate LOS
				vLOSChecked = False;
				vRestrStruct = Undefined;  
				vIgnoreLOS = cmCheckUserPermissions("HavePermissionToIgnoreLOS");
				// Fill effective period
				vCheckInDate = CheckInDate;
				vCheckOutDate = CheckOutDate;
				vReservationCheckInDate = vCheckInDate;
				vReservationCheckOutDate = vCheckOutDate;

				If Not FixReservationConditions Then
					vRestrStruct = RoomRate.GetObject().pmGetRoomRateRestrictions(vCheckInDate, vCheckOutDate, ?(ValueIsFilled(RoomTypeUpgrade), RoomTypeUpgrade, RoomType), True, PriceCalculationDate);   
					vLOSChecked = True;
					If vRestrStruct.MLOS > 0 And Duration < vRestrStruct.MLOS And RoomRate.MLOSIsBlocking And ValueIsFilled(AccommodationStatus) And AccommodationStatus.IsActive And Not FixReservationConditions Then
						vHasErrors = Not vIgnoreLOS; 
						vMsgTextRu = vMsgTextRu + "Минимальная продолжительность проживания " + vRestrStruct.MLOS + " дней!" + Chars.LF;
						vMsgTextEn = vMsgTextEn + "Minimum length of stay is " + vRestrStruct.MLOS + "!" + Chars.LF;
						vMsgTextDe = vMsgTextDe + "Mindestaufenthaltsdauer betragt " + vRestrStruct.MLOS + " Tage!" + Chars.LF;
						pAttributeInErr = ?(pAttributeInErr = "", "CheckInDate", pAttributeInErr);
					EndIf;
					If vRestrStruct.MaxLOS > 0 And Duration > vRestrStruct.MaxLOS Then
						vHasErrors = Not vIgnoreLOS; 
						vMsgTextRu = vMsgTextRu + "Максимальная продолжительность проживания " + vRestrStruct.MaxLOS + " дней!" + Chars.LF;
						vMsgTextEn = vMsgTextEn + "Maximum length of stay is " + vRestrStruct.MaxLOS + "!" + Chars.LF;
						vMsgTextDe = vMsgTextDe + "Maximaleaufenthaltsdauer betragt " + vRestrStruct.MaxLOS + " Tage!" + Chars.LF;
						pAttributeInErr = ?(pAttributeInErr = "", "CheckOutDate", pAttributeInErr);
					EndIf;
					If vRestrStruct.MinDaysBeforeCheckIn > 0 And ValueIsFilled(AccommodationType) And (AccommodationType.Type = Enums.AccomodationTypes.Room Or AccommodationType.Type = Enums.AccomodationTypes.Beds) Then
						vDate = GuestGroup.CreateDate;
						vDaysBeforeCheckIn = Int((BegOfDay(vCheckInDate) - BegOfDay(vDate)) / (24 * 3600));
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
				EndIf;	
				
				// Get and check room rate restrictions
				If ValueIsFilled(RoomRate) And BegOfDay(CheckInDate) >= BegOfDay(CurrentSessionDate()) And AccommodationStatus.IsCheckIn And AccommodationStatus.IsInHouse Then 
					If IsByReservation Then
						If ValueIsFilled(Reservation) Then
							vReservationCheckInDate = Reservation.CheckInDate;
							vReservationCheckOutDate = Reservation.CheckOutDate;
						EndIf;
					EndIf;
					If ValueIsFilled(HotelProduct) And Not HotelProduct.IsFolder Then
						If HotelProduct.FixProductPeriod Then
							vCheckInDate = HotelProduct.CheckInDate;
							vCheckOutDate = HotelProduct.CheckOutDate;
						EndIf;
					EndIf;
					If FixReservationConditions And IsByReservation Then
						vSavCheckInDate = vCheckInDate;
						vSavCheckOutDate = vCheckOutDate;
						If ValueIsFilled(ParentDoc) And TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Then
							vCheckInDate = Min(CheckInDate, vReservationCheckInDate);
						Else
							vReservationCheckInDate = vCheckInDate;
						EndIf;
						If AccommodationStatus.IsCheckOut Then
							vSkipCheck = True;
							If IsNew() Then
								vSkipCheck = False;
							EndIf;
							If vSkipCheck Then 
								// Check that there is no accommodation where current one is parent document
								vQry = New Query();
								vQry.Text = 
								"SELECT
								|	Accommodation.Ref
								|FROM
								|	Document.Accommodation AS Accommodation
								|WHERE
								|	Accommodation.Posted
								|	AND Accommodation.ParentDoc = &qParentDoc
								|	AND Accommodation.CheckInDate > &qCheckInDate
								|	AND Accommodation.AccommodationStatus.IsActive";
								vQry.SetParameter("qParentDoc", Ref);
								vQry.SetParameter("qCheckInDate", CheckInDate);
								vNextDocs = vQry.Execute().Unload();
								If vNextDocs.Count() = 0 Then
									vSkipCheck = False;
								EndIf;
							EndIf;
							If Not vSkipCheck Then
								vCheckOutDate = Max(CheckOutDate, vReservationCheckOutDate);
							Else
								vReservationCheckOutDate = vCheckOutDate;
							EndIf;
						EndIf;
						If vCheckOutDate <= vCheckInDate Then
							vCheckInDate = vSavCheckInDate;
							vCheckOutDate = vSavCheckOutDate;
							If Not (ValueIsFilled(ParentDoc) And TypeOf(ParentDoc) = Type("DocumentRef.Reservation")) Then
								vReservationCheckInDate = vCheckInDate;
								vReservationCheckOutDate = vCheckOutDate;
							EndIf;
						EndIf;
					EndIf;
					If Not IsByReservation Then
						vRoomRateHasChanged = False;
						If vLastDocState <> Undefined Then
							If RoomRate <> vLastDocState.RoomRate 
								Or BegOfDay(CheckInDate) <> BegOfDay(vLastDocState.CheckInDate) 
							    Or BegOfDay(CheckOutDate) <> BegOfDay(vLastDocState.CheckOutDate) 
								Or RoomType <> vLastDocState.RoomType Then
								vRoomRateHasChanged = True;
							EndIf;
						Else
							vRoomRateHasChanged = True;
						EndIf;
						If Not Posted Or vRoomRateHasChanged Then  
							If vRestrStruct = Undefined Then
								vRestrStruct = RoomRate.GetObject().pmGetRoomRateRestrictions(vCheckInDate, vCheckOutDate, ?(ValueIsFilled(RoomTypeUpgrade), RoomTypeUpgrade, RoomType), True, PriceCalculationDate);    
							EndIf;
							If vRestrStruct.StopSale Then
								If Not cmCheckUserPermissions("HavePermissionToIgnoreStopSaleLimitations") Then
									vHasErrors = True;
								Else
									vHasErrors = False;
								EndIf;
								vMsgTextRu = vMsgTextRu + "Продажи по тарифу " + TrimAll(RoomRate) + " остановлены на периоде с " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " по " + Format(vCheckOutDate, "DF=dd.MM.yyyy") + " в ограничениях тарифа (Stop Sale включен)!" + Chars.LF;
								vMsgTextEn = vMsgTextEn + "Room rate " + TrimAll(RoomRate) + " could not be used for the given period " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " - " + Format(vCheckOutDate, "DF=dd.MM.yyyy") + " (room rate restriction Stop Sales is turned on)!" + Chars.LF;
								vMsgTextDe = vMsgTextDe + "Tariff " + TrimAll(RoomRate) + " ist geschlossen (Tariff Einschränkung Stop Sale ist auf), periode " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " - " + Format(vCheckOutDate, "DF=dd.MM.yyyy") + "!" + Chars.LF;
								pAttributeInErr = ?(pAttributeInErr = "", "RoomRate", pAttributeInErr);
							EndIf;
							If vRestrStruct.CTA Then
								vHasErrors = Not Posted; 
								vMsgTextRu = vMsgTextRu + "Заезд в выбранную дату " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " запрещен в ограничениях указанных у тарифа (CTA включен)!" + Chars.LF;
								vMsgTextEn = vMsgTextEn + "Check-in is closed (CTA is On) for the given check-in date " + Format(vCheckInDate, "DF=dd.MM.yyyy") + "!" + Chars.LF;
								vMsgTextDe = vMsgTextDe + "Check-in ist fur den Check-in-Datum " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " geschlossen (CTA is On)!" + Chars.LF;
								pAttributeInErr = ?(pAttributeInErr = "", "CheckInDate", pAttributeInErr);
							EndIf;
							If vRestrStruct.CTD Then
								vHasErrors = Not Posted; 
								vMsgTextRu = vMsgTextRu + "Выезд в выбранную дату " + Format(vCheckOutDate, "DF=dd.MM.yyyy") + " запрещен в ограничениях указанных у тарифа (CTD включен)!" + Chars.LF;
								vMsgTextEn = vMsgTextEn + "Check-out is closed (CTD is On) for the given check-out date " + Format(vCheckOutDate, "DF=dd.MM.yyyy") + "!" + Chars.LF;
								vMsgTextDe = vMsgTextDe + "Check-out ist fur den Check-out-Datum " + Format(vCheckOutDate, "DF=dd.MM.yyyy") + " geschlossen (CTD is On)!" + Chars.LF;
								pAttributeInErr = ?(pAttributeInErr = "", "CheckOutDate", pAttributeInErr);
							EndIf;    
							If vLOSChecked = False Then
								If vRestrStruct.MLOS > 0 And Duration < vRestrStruct.MLOS And RoomRate.MLOSIsBlocking And ValueIsFilled(AccommodationStatus) And AccommodationStatus.IsCheckOut And AccommodationStatus.IsActive And Not FixReservationConditions Then
									vHasErrors = Not Posted; 
									vMsgTextRu = vMsgTextRu + "Минимальная продолжительность проживания " + vRestrStruct.MLOS + " дней!" + Chars.LF;
									vMsgTextEn = vMsgTextEn + "Minimum length of stay is " + vRestrStruct.MLOS + "!" + Chars.LF;
									vMsgTextDe = vMsgTextDe + "Mindestaufenthaltsdauer betragt " + vRestrStruct.MLOS + " Tage!" + Chars.LF;
									pAttributeInErr = ?(pAttributeInErr = "", "CheckInDate", pAttributeInErr);
								EndIf;
								If vRestrStruct.MaxLOS > 0 And Duration > vRestrStruct.MaxLOS Then
									vHasErrors = Not Posted; 
									vMsgTextRu = vMsgTextRu + "Максимальная продолжительность проживания " + vRestrStruct.MaxLOS + " дней!" + Chars.LF;
									vMsgTextEn = vMsgTextEn + "Maximum length of stay is " + vRestrStruct.MaxLOS + "!" + Chars.LF;
									vMsgTextDe = vMsgTextDe + "Maximaleaufenthaltsdauer betragt " + vRestrStruct.MaxLOS + " Tage!" + Chars.LF;
									pAttributeInErr = ?(pAttributeInErr = "", "CheckOutDate", pAttributeInErr);
								EndIf;
								If vRestrStruct.MinDaysBeforeCheckIn > 0 And ValueIsFilled(AccommodationType) And (AccommodationType.Type = Enums.AccomodationTypes.Room Or AccommodationType.Type = Enums.AccomodationTypes.Beds) Then
									vDate = GuestGroup.CreateDate;
									vDaysBeforeCheckIn = Int((BegOfDay(vCheckInDate) - BegOfDay(vDate)) / (24 * 3600));
									If vDaysBeforeCheckIn < vRestrStruct.MinDaysBeforeCheckIn Then
										vHasErrors = Not Posted; 
										vMsgTextRu = vMsgTextRu + "Минимальное кол-во дней от даты бронирования до даты заезда " + vRestrStruct.MinDaysBeforeCheckIn + "!" + Chars.LF;
										vMsgTextEn = vMsgTextEn + "Minimum days between booking and check-in dates is " + vRestrStruct.MinDaysBeforeCheckIn + "!" + Chars.LF;
										vMsgTextDe = vMsgTextDe + "Mindest Tage zwischen Buchung und Check-in Daten ist " + vRestrStruct.MinDaysBeforeCheckIn + "!" + Chars.LF;
										pAttributeInErr = ?(pAttributeInErr = "", "CheckInDate", pAttributeInErr);
									EndIf;
								EndIf;
								If vRestrStruct.MaxDaysBeforeCheckIn > 0 And ValueIsFilled(AccommodationType) And (AccommodationType.Type = Enums.AccomodationTypes.Room Or AccommodationType.Type = Enums.AccomodationTypes.Beds) Then
									vDate = GuestGroup.CreateDate;
									vDaysBeforeCheckIn = Int((BegOfDay(vCheckInDate) - BegOfDay(vDate)) / (24 * 3600));
									If vDaysBeforeCheckIn > vRestrStruct.MaxDaysBeforeCheckIn Then
										vHasErrors = Not Posted; 
										vMsgTextRu = vMsgTextRu + "Максимальное кол-во дней от даты бронирования до даты заезда " + vRestrStruct.MaxDaysBeforeCheckIn + "!" + Chars.LF;
										vMsgTextEn = vMsgTextEn + "Maximum days between booking and check-in dates is " + vRestrStruct.MaxDaysBeforeCheckIn + "!" + Chars.LF;
										vMsgTextDe = vMsgTextDe + "Maximale Tage zwischen Buchung und Check-in Daten ist " + vRestrStruct.MaxDaysBeforeCheckIn + "!" + Chars.LF;
										pAttributeInErr = ?(pAttributeInErr = "", "CheckInDate", pAttributeInErr);
									EndIf;
								EndIf;  
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		// Check that there is no change room attributes in the period selected
		If ValueIsFilled(Room) And ValueIsFilled(CheckInDate) And ValueIsFilled(CheckOutDate) Then
			If TypeOf(pPeriod) <> Type("DocumentObject.Accommodation") Then
				vChangeRoomAttrs = cmGetChangeRoomAttributes(pPeriod.Room, pPeriod.CheckInDate, pPeriod.CheckOutDate);
				If vChangeRoomAttrs.Count() > 0 Then
					vHasErrors = True; 
					vMsgTextRu = vMsgTextRu + "В плане размещения не должно быть не учтенных изменений параметров выбранного номера!" + Chars.LF;
					vMsgTextEn = vMsgTextEn + "There should be no missed change room attributes in the accommodation plan!" + Chars.LF;
					vMsgTextDe = vMsgTextDe + "There should be no missed change room attributes in the accommodation plan!" + Chars.LF;
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
				vMsgTextDe = vMsgTextDe + "Service is not filled in the charging rules row number " + Format(vCRRow.LineNumber, "ND=4; NFD=0; NG=") + "!" + Chars.LF;
				pAttributeInErr = ?(pAttributeInErr = "", "ChargingRules", pAttributeInErr);
			ElsIf vCRRow.ChargingRule = Enums.ChargingRuleTypes.InServiceGroup And Not ValueIsFilled(vCRRow.ChargingRuleValue) Then
				vHasErrors = True; 
				vMsgTextRu = vMsgTextRu + "В правилах начисления в строке " + Format(vCRRow.LineNumber, "ND=4; NFD=0; NG=") + " не указан набор услуг!" + Chars.LF;
				vMsgTextEn = vMsgTextEn + "Service group is not filled in the charging rules row number " + Format(vCRRow.LineNumber, "ND=4; NFD=0; NG=") + "!" + Chars.LF;
				vMsgTextDe = vMsgTextDe + "Service group is not filled in the charging rules row number " + Format(vCRRow.LineNumber, "ND=4; NFD=0; NG=") + "!" + Chars.LF;
				pAttributeInErr = ?(pAttributeInErr = "", "ChargingRules", pAttributeInErr);
			ElsIf vCRRow.ChargingRule = Enums.ChargingRuleTypes.One And Not ValueIsFilled(vCRRow.ChargingRuleValue) Then
				vHasErrors = True; 
				vMsgTextRu = vMsgTextRu + "В правилах начисления в строке " + Format(vCRRow.LineNumber, "ND=4; NFD=0; NG=") + " не указана услуга!" + Chars.LF;
				vMsgTextEn = vMsgTextEn + "Service is not filled in the charging rules row number " + Format(vCRRow.LineNumber, "ND=4; NFD=0; NG=") + "!" + Chars.LF;
				vMsgTextDe = vMsgTextDe + "Service is not filled in the charging rules row number " + Format(vCRRow.LineNumber, "ND=4; NFD=0; NG=") + "!" + Chars.LF;
				pAttributeInErr = ?(pAttributeInErr = "", "ChargingRules", pAttributeInErr);
			ElsIf vCRRow.ChargingRule = Enums.ChargingRuleTypes.NotInServiceGroup And Not ValueIsFilled(vCRRow.ChargingRuleValue) Then
				vHasErrors = True; 
				vMsgTextRu = vMsgTextRu + "В правилах начисления в строке " + Format(vCRRow.LineNumber, "ND=4; NFD=0; NG=") + " не указан набор услуг!" + Chars.LF;
				vMsgTextEn = vMsgTextEn + "Service group is not filled in the charging rules row number " + Format(vCRRow.LineNumber, "ND=4; NFD=0; NG=") + "!" + Chars.LF;
				vMsgTextDe = vMsgTextDe + "Service group is not filled in the charging rules row number " + Format(vCRRow.LineNumber, "ND=4; NFD=0; NG=") + "!" + Chars.LF;
				pAttributeInErr = ?(pAttributeInErr = "", "ChargingRules", pAttributeInErr);
			EndIf;
			If Not ValueIsFilled(vCRRow.Owner) And ValueIsFilled(vCRRow.ChargingFolio) And ValueIsFilled(vCRRow.ChargingFolio.PaymentMethod) And vCRRow.ChargingFolio.PaymentMethod.IsByBankTransfer Then
				If ValueIsFilled(Hotel) And ValueIsFilled(Hotel.IndividualsCustomer) Then
					vCRRow.Owner = Hotel.IndividualsCustomer;
				Else
					vHasErrors = True; 
					vMsgTextRu = vMsgTextRu + "В правилах начисления в строке " + Format(vCRRow.LineNumber, "ND=4; NFD=0; NG=") + " установлен способ оплаты контрагентом, а контрагент не указан!" + Chars.LF;
					vMsgTextEn = vMsgTextEn + "Customer is not choosen in the charging rule owner in the row number " + Format(vCRRow.LineNumber, "ND=4; NFD=0; NG=") + " but payment method choosen states that folio is paid by customer!" + Chars.LF;
					vMsgTextDe = vMsgTextDe + "Customer is not choosen in the charging rule owner in the row number " + Format(vCRRow.LineNumber, "ND=4; NFD=0; NG=") + " but payment method choosen states that folio is paid by customer!" + Chars.LF;
					pAttributeInErr = ?(pAttributeInErr = "", "ChargingRules", pAttributeInErr);
				EndIf;
			EndIf;
		EndDo;
		// Check room rates
		If ValueIsFilled(AccommodationStatus) And AccommodationStatus.IsActive And AccommodationStatus.IsInHouse Then
			For Each vRRRow In RoomRates Do
				If Not ValueIsFilled(vRRRow.Room) And ValueIsFilled(vRRRow.RoomType) And vRRRow.RoomType <> RoomType Then
					vHasErrors = True; 
					vMsgTextRu = vMsgTextRu + "В плане изменений в строке " + Format(vRRRow.LineNumber, "ND=4; NFD=0; NG=") + " не указан номер комнаты, куда запланировано переселение!" + Chars.LF;
					vMsgTextEn = vMsgTextEn + "Room is not specified for expected room move in changes plan row number " + Format(vRRRow.LineNumber, "ND=4; NFD=0; NG=") + "!" + Chars.LF;
					vMsgTextDe = vMsgTextDe + "Im Änderungsplan steht in Zeile " + Format(vRRRow.LineNumber, "ND=4; NFD=0; NG=") + " nicht die Zimmer, in dem der Umzug geplant ist!" + Chars.LF;
					pAttributeInErr = ?(pAttributeInErr = "", "RoomRates", pAttributeInErr);
					Break;
				EndIf;
			EndDo;
		EndIf;
		// Check table of services
		If ValueIsFilled(AccommodationStatus) And AccommodationStatus.IsActive And AccommodationStatus.IsInHouse Then
			If Not cmCheckUserPermissions("HavePermissionToEditRoomRateServices") Then
				If ValueIsFilled(RoomRate) And RoomRate.RateChargeDirection = Enums.RateChargeDirections.MergeToTheMainRoomGuest And ValueIsFilled(AccommodationTemplate) Or
				   ValueIsFilled(RoomRate) And RoomRate.RateChargeDirection <> Enums.RateChargeDirections.MergeToTheMainRoomGuest Then
					vServices = Services.FindRows(New Structure("IsRoomRevenue", True));
					If vServices.Count() = 0 Then
						vHasErrors = True; 
						vMsgTextRu = vMsgTextRu + "В таблице услуг к начислению нет стоимости проживания!" + Chars.LF;
						vMsgTextEn = vMsgTextEn + "There are no room revenue found in the list of services to be charged!" + Chars.LF;
						vMsgTextDe = vMsgTextDe + "There are no room revenue found in the list of services to be charged!" + Chars.LF;
						pAttributeInErr = ?(pAttributeInErr = "", "Services", pAttributeInErr);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		// Check rights to create group debt
		If IsByReservation And ValueIsFilled(Customer) And ValueIsFilled(PlannedPaymentMethod) And PlannedPaymentMethod.IsByBankTransfer And 
		   ValueIsFilled(AccommodationStatus) And AccommodationStatus.IsActive Then
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
	EndIf;
	// Build error return string
	If vHasErrors Then
		pMessage = "ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // pmCheckDocumentAttributes

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
	If ValueIsFilled(Hotel) And ValueIsFilled(RoomRate) Then
		If Not ValueIsFilled(Reservation) And Duration = 0 Then
			Duration = ?(RoomRate.DefaultDuration <> 0, RoomRate.DefaultDuration, ?(Hotel.Duration <> 0, Hotel.Duration, 1));
		EndIf;
		vRRPer = ?(RoomRate.PeriodInHours = 0, 24, RoomRate.PeriodInHours);
		vRRRH = RoomRate.ReferenceHour;
		If Not ValueIsFilled(CheckInDate) Then
			CheckInDate = CurrentSessionDate();
		EndIf;
		If Not ValueIsFilled(CheckOutDate) Then
			If RoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour Then
				vCheckInDateRH = Date(Year(CheckInDate), Month(CheckInDate), Day(CheckInDate), Hour(vRRRH), Minute(vRRRH), 0);
				If Duration = 1 And 
				   vRRPer = 24 And 
				   (Not RoomRate.FirstDayEndsAtReferenceHourTime) And 
				   (CheckInDate - vCheckInDateRH) > 0 Then
					CheckOutDate = CheckInDate + Duration*vRRPer*3600;
				Else
					CheckOutDate = Date(Year(CheckInDate), Month(CheckInDate), Day(CheckInDate), 
					                    Hour(vRRRH), Minute(vRRRH), 0) + Duration*vRRPer*3600;
					If RoomRate.ReferenceHour = '00010101' Then
						CheckOutDate = CheckOutDate - 1;
					EndIf;
				EndIf;
			ElsIf RoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByDays Then
				vDefaultCheckOutTime = RoomRate.DefaultCheckOutTime;
				If Not ValueIsFilled(Reservation) Then
					CheckOutDate = Date(Year(CheckInDate), Month(CheckInDate), Day(CheckInDate), 
					                    21, 0, 0) + (Duration - 1) * vRRPer * 3600;
					If ValueIsFilled(vDefaultCheckOutTime) Then
						CheckOutDate = cm0SecondShift(BegOfDay(CheckOutDate) + (vDefaultCheckOutTime - BegOfDay(vDefaultCheckOutTime)));
					EndIf;
				EndIf;
			ElsIf RoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByNights Then
				vCheckInTime = CheckInDate - BegOfDay(CheckInDate);
				If vCheckInTime <= 9*3600 Then // Breakfast check-in
					CheckOutDate = BegOfDay(CheckInDate) + Duration * vRRPer * 3600 + 7 * 3600;
				ElsIf vCheckInTime <= 14*3600 Then // Lunch check-in
					CheckOutDate = BegOfDay(CheckInDate) + Duration * vRRPer * 3600 + 12 * 3600;
				ElsIf vCheckInTime <= 20*3600 Then // Supper check-in
					CheckOutDate = BegOfDay(CheckInDate) + Duration * vRRPer * 3600 + 18 * 3600;
				Else  // Late check-in
					CheckOutDate = BegOfDay(CheckInDate) + Duration * vRRPer * 3600 + 21 * 3600;
				EndIf;
			Else
				CheckOutDate = Date(Year(CheckInDate), Month(CheckInDate), Day(CheckInDate), 
				                    Hour(CheckInDate), Minute(CheckInDate), 0) + Duration*vRRPer*3600;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // pmInitializePeriod

// -----------------------------------------------------------------------------
// Calculates and returns duration for giving check in and check out dates
// -----------------------------------------------------------------------------
Function pmCalculateDuration() Export
	Return cmCalculateDuration(RoomRate, CheckInDate, CheckOutDate);
EndFunction // pmCalculateDuration

// -----------------------------------------------------------------------------
// Calculates and returns check out date based on giving duration and check in date
// -----------------------------------------------------------------------------
Function pmCalculateCheckOutDate() Export
	vCheckOutDate = CheckOutDate;
	If ValueIsFilled(RoomRate) And
	   ValueIsFilled(CheckInDate) Then
	   vCheckOutDate = cmCalculateCheckOutDate(RoomRate, CheckInDate, Duration);
	EndIf;
	Return vCheckOutDate;
EndFunction // pmCalculateCheckOutDate

// -----------------------------------------------------------------------------
Procedure pmFillAuthorAndDate() Export
	Date = CurrentSessionDate();
	Author = SessionParameters.CurrentUser;
EndProcedure // pmFillAuthorAndDate

// -----------------------------------------------------------------------------
Procedure pmCreateGuestGroup(pGuestGroup = Undefined) Export
	If ValueIsFilled(Hotel) Then
		vGuestGroupObj = Catalogs.GuestGroups.CreateItem();
		vGuestGroupObj.Owner = Hotel;
		vGuestGroupFolder = Catalogs.Hotels.pmGetGuestGroupFolder(Hotel);
		If ValueIsFilled(vGuestGroupFolder) Then
			vGuestGroupObj.Parent = vGuestGroupFolder;
			vGuestGroupObj.SetNewCode();
		EndIf;
		vGuestGroupObj.OneCustomerPerGuestGroup = Hotel.OneCustomerPerGuestGroup;       
		// Fill group type and room quotas
		If ValueIsFilled(pGuestGroup) Then
			vGuestGroupObj.GroupType = pGuestGroup.GroupType;
			vGuestGroupObj.Allotment = pGuestGroup.Allotment;
		EndIf;	
		vGuestGroupObj.Write();
		// Fill document attribute
		GuestGroup = vGuestGroupObj.Ref;
	EndIf;
EndProcedure // pmCreateGuestGroup

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
			vFolioObj = Documents.Folio.CreateDocument();
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
					vFolioObj = Documents.Folio.CreateDocument();
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
EndProcedure // pmCreateFolios

// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues(pCreateGuestGroup = True, pCreateChargingRules = True) Export
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
		If Not ValueIsFilled(AccommodationStatus) Then
			AccommodationStatus = Hotel.CheckInAccommodationStatus;
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
		If Not ValueIsFilled(AccountingCheckInDate) Then
			If ValueIsFilled(Hotel.AccountingDate) Then
				AccountingCheckInDate = Hotel.AccountingDate;
			Else
				AccountingCheckInDate = BegOfDay(CurrentSessionDate());
			EndIf;
		EndIf;
		// Initialize document period
		pmInitializePeriod();
	EndIf;
	ExchangeRateDate = Date;
	IsOneTimeChargeNecessary = True;
	// Create guest group if is new
	If pCreateGuestGroup Then
		If Not ValueIsFilled(GuestGroup) Then
			pmCreateGuestGroup();
		EndIf;
	EndIf;
	// Create document folio if is new
	If pCreateChargingRules And ChargingRules.Count() = 0 Then
		pmCreateFolios();
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Procedure pmCalculateResources() Export
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
			NumberOfRooms = AccommodationType.NumberOfRooms;
			NumberOfBeds = ?(AccommodationType.NumberOfRooms = 0, 0, NumberOfBedsPerRoom);
			If NumberOfPersons = 0 Then
				NumberOfPersons = AccommodationType.NumberOfPersons;
			EndIf;
			NumberOfAdditionalBeds = AccommodationType.NumberOfAdditionalBeds;
		ElsIf AccommodationType.Type = Enums.AccomodationTypes.Beds Then
			NumberOfRooms = 0;
			NumberOfBeds = AccommodationType.NumberOfBeds;
			If NumberOfPersons = 0 Then
				NumberOfPersons = AccommodationType.NumberOfPersons;
			EndIf;
			NumberOfAdditionalBeds = AccommodationType.NumberOfAdditionalBeds;
		ElsIf AccommodationType.Type = Enums.AccomodationTypes.AdditionalBed Then
			NumberOfRooms = 0;
			NumberOfBeds = 0;
			If NumberOfPersons = 0 Then
				NumberOfPersons = AccommodationType.NumberOfPersons;
			EndIf;
			NumberOfAdditionalBeds = AccommodationType.NumberOfAdditionalBeds;
		ElsIf AccommodationType.Type = Enums.AccomodationTypes.Together Then
			NumberOfRooms = 0;
			NumberOfBeds = 0;
			If NumberOfPersons = 0 Then
				NumberOfPersons = AccommodationType.NumberOfPersons;
			EndIf;
			NumberOfAdditionalBeds = AccommodationType.NumberOfAdditionalBeds;
		EndIf;
		If AccommodationType.NumberOfPersons = 0 Then
			NumberOfPersons = 0;
		EndIf;
	Else
		NumberOfRooms = 0;
		NumberOfBeds = 0;
		NumberOfAdditionalBeds = 0;
	EndIf;
EndProcedure // pmCalculateResources

// -----------------------------------------------------------------------------
Function pmGetAccumulatingDiscountResources() Export
	// Initialize map with resources
	vRes = New ValueTable();
	vRes.Columns.Add("DiscountType", cmGetCatalogTypeDescription("DiscountTypes"), "Discount type", 20);
	vRes.Columns.Add("DiscountDimension", cmGetDiscountDimensionTypeDescription(), "Discount dimension", 20);
	vRes.Columns.Add("Resource", cmGetAccumulatingDiscountResourceTypeDescription(), "Discount resource", 20);
	vRes.Columns.Add("Bonus", cmGetAccumulatingDiscountResourceTypeDescription(), "Bonus", 20);
	vRes.Columns.Add("Name", cmGetStringTypeDescription(50));
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
EndFunction // pmGetAccumulatingDiscountResources

// -----------------------------------------------------------------------------
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
	vCurRecorder = Undefined;
	For Each vPricesRow In vPrices Do
		If vCurRecorder <> vPricesRow.Recorder Then
			vCurRecorder = vPricesRow.Recorder;
		EndIf;
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
EndFunction // pmFillTypesTable

// -----------------------------------------------------------------------------
// Get accommodation prices for all day types of room rate
// -----------------------------------------------------------------------------
Function pmCalculatePricePresentation(Val pLang = Undefined) Export
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
EndFunction // pmCalculatePricePresentation

// -----------------------------------------------------------------------------
Function pmGetServiceRatePrice(pRoomRate, pAccountingDate, pPriceCalculationDate, pService, rCurrency, 
	                           pRoomType = Undefined, pPriceTag = Undefined, pAccommodationType = Undefined, pAccommodationTemplate = Undefined, 
							   pIsForFolioSplit = False, pSplitPackagesByGuests = Undefined, pServicePackagesList = Undefined, 
	                           pReservationCheckInDate = '00010101', pReservationCheckOutDate = '00010101', pReservationPricesCache = Undefined) Export
	vPrice = 0;
	vSplitPackagesByGuests = pIsForFolioSplit;
	If pSplitPackagesByGuests <> Undefined Then
		vSplitPackagesByGuests = pSplitPackagesByGuests;
	EndIf;
	vRoomType = RoomType;
	If pRoomtype <> Undefined Then
		vRoomType = pRoomType;
	ElsIf ValueIsFilled(RoomTypeUpgrade) Then
		vRoomType = RoomTypeUpgrade;
	EndIf;
	vAccommodationType = AccommodationType;
	If pAccommodationType <> Undefined Then
		vAccommodationType = pAccommodationType;
	EndIf;
	// Check that room rate is filled
	If Not ValueIsFilled(pRoomRate) Then
		Return vPrice;
	EndIf;
	If Not ValueIsFilled(pRoomRate.Calendar) Then
		Return vPrice;
	EndIf;
	// Calendar day type
	vCalendarDayType = Catalogs.CalendarDayTypes.EmptyRef();
	vRoomRateCalendarDays = New ValueTable();
	vPrices = New ValueTable();
	// Try to get days and prices from cache
	If pReservationPricesCache <> Undefined Then
		vCacheCalendarDays = New ValueTable();
		vCacheCalendarDays.Columns.Add("Period", cmGetDateTypeDescription());
		vCachePrices = New ValueTable();
		vCachePrices.Columns.Add("AccountingDate", cmGetDateTypeDescription());
		
		// Check cache
		vReservationPricesCacheRow = Undefined;
		vReservationPricesCacheRows = pReservationPricesCache.FindRows(New Structure("RoomRate, RoomType, AccommodationType, AccommodationTemplate, PriceCalculationDate", pRoomRate, vRoomType, vAccommodationType, pAccommodationTemplate, pPriceCalculationDate));
		If vReservationPricesCacheRows.Count() = 1 Then
			vReservationPricesCacheRow = vReservationPricesCacheRows.Get(0);
		EndIf;
		
		If vReservationPricesCacheRow = Undefined Then
			// Get rack rate calendar accounting date day type
			vCacheCalendarDays = pRoomRate.Calendar.GetObject().pmGetDays(BegOfDay(pReservationCheckInDate), BegOfDay(pReservationCheckOutDate), , , vRoomType, pPriceCalculationDate);
			// Get list of price records for the given room rate
			vCachePrices = pRoomRate.GetObject().pmGetRoomRatePrices(pReservationCheckInDate, pPriceCalculationDate, ClientType, vRoomType, vAccommodationType, pServicePackagesList, , pReservationCheckInDate, pReservationCheckOutDate, , , , , pAccommodationTemplate, pIsForFolioSplit, vSplitPackagesByGuests, Not IsBlankString(SharePercent));
			If ValueIsFilled(ClientType) And (vCachePrices.Count() = 0 Or vCachePrices.FindRows(New Structure("IsRoomRevenue", True)).Count() = 0) Then
				vCachePrices = pRoomRate.GetObject().pmGetRoomRatePrices(pReservationCheckInDate, pPriceCalculationDate, Catalogs.ClientTypes.EmptyRef(), vRoomType, vAccommodationType, pServicePackagesList, , pReservationCheckInDate, pReservationCheckOutDate, , , , , pAccommodationTemplate, pIsForFolioSplit, vSplitPackagesByGuests, Not IsBlankString(SharePercent));
			EndIf;
			// Save in cache
			vReservationPricesCacheRow = pReservationPricesCache.Add();
			vReservationPricesCacheRow.RoomRate = pRoomRate;
			vReservationPricesCacheRow.RoomType = vRoomType;
			vReservationPricesCacheRow.AccommodationType = vAccommodationType;
			vReservationPricesCacheRow.AccommodationTemplate = pAccommodationTemplate;
			vReservationPricesCacheRow.PriceCalculationDate = pPriceCalculationDate;
			vReservationPricesCacheRow.CalendarDays = vCacheCalendarDays;
			vReservationPricesCacheRow.Prices = vCachePrices;
		Else
			vCacheCalendarDays = vReservationPricesCacheRow.CalendarDays;
			vCachePrices = vReservationPricesCacheRow.Prices;
		EndIf;
		
		// Filter by accounting date
		vRoomRateCalendarDays = vCacheCalendarDays.Copy(vCacheCalendarDays.FindRows(New Structure("Period", pAccountingDate)));
		vPrices = vCachePrices.Copy(vCachePrices.FindRows(New Structure("AccountingDate", pAccountingDate)));
		vEmptyDatePricesRows = vCachePrices.FindRows(New Structure("AccountingDate", '00010101'));
		For Each vEmptyDatePricesRow In vEmptyDatePricesRows Do
			vPricesRow = vPrices.Add();
			FillPropertyValues(vPricesRow, vEmptyDatePricesRow);
		EndDo;
	Else
		// Get rack rate calendar accounting date day type
		vRoomRateCalendarDays = pRoomRate.Calendar.GetObject().pmGetDays(pAccountingDate, pAccountingDate, , , vRoomType, pPriceCalculationDate);
		// Get list of price records for the given room rate
		vPrices = pRoomRate.GetObject().pmGetRoomRatePrices(pAccountingDate, pPriceCalculationDate, ClientType, vRoomType, vAccommodationType, pServicePackagesList, , pAccountingDate, pAccountingDate, , , , , pAccommodationTemplate, pIsForFolioSplit, vSplitPackagesByGuests, Not IsBlankString(SharePercent));
		If ValueIsFilled(ClientType) And (vPrices.Count() = 0 Or vPrices.FindRows(New Structure("IsRoomRevenue", True)).Count() = 0) Then
			vPrices = pRoomRate.GetObject().pmGetRoomRatePrices(pAccountingDate, pPriceCalculationDate, Catalogs.ClientTypes.EmptyRef(), vRoomType, vAccommodationType, pServicePackagesList, , pAccountingDate, pAccountingDate, , , , , pAccommodationTemplate, pIsForFolioSplit, vSplitPackagesByGuests, Not IsBlankString(SharePercent));
		EndIf;
	EndIf;
	If vRoomRateCalendarDays.Count() > 0 Then
		For Each vRoomRateCalendarDaysRow In vRoomRateCalendarDays Do
			If ValueIsFilled(vRoomRateCalendarDaysRow.CalendarDayTypeByRoomType) Then
				vCalendarDayType = vRoomRateCalendarDaysRow.CalendarDayTypeByRoomType;
				Break;
			EndIf;
			If ValueIsFilled(vRoomRateCalendarDaysRow.CalendarDayType) Then
				vCalendarDayType = vRoomRateCalendarDaysRow.CalendarDayType;
				Break;
			EndIf;
		EndDo;
	EndIf;
	If vPrices.Count() > 0 Then
		If pPriceTag <> Undefined Then
			vServicePrices = vPrices.FindRows(New Structure("Service, PriceTag", pService, pPriceTag));
		Else
			vServicePrices = vPrices.FindRows(New Structure("Service", pService));
		EndIf;
		For Each vPricesRow In vServicePrices Do
			// Check service package period
			If ValueIsFilled(vPricesRow.ServicePackage) Then
				If BegOfDay(CheckInDate) < vPricesRow.ServicePackageDateValidFrom Or 
				   ValueIsFilled(vPricesRow.ServicePackageDateValidTo) And BegOfDay(CheckInDate) > vPricesRow.ServicePackageDateValidTo Then
					Continue;
				EndIf;
				If pAccountingDate < vPricesRow.ServicePackageDateFrom Or 
				   ValueIsFilled(vPricesRow.ServicePackageDateTo) And pAccountingDate > vPricesRow.ServicePackageDateTo Then
					Continue;
				EndIf;
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
	// Return rack price
	Return vPrice;
EndFunction // pmGetServiceRatePrice	

// -----------------------------------------------------------------------------
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
EndFunction // pmGetComplexCommission

// -----------------------------------------------------------------------------
Procedure AddService(i, vCurFolio, vCurFolioCurrency, vCurFolioCurrencyExchangeRate, vCurAccountingDate,
                     vCurService, vCurPrice, vCurUnit, vCurQuantity, vCurVATRate, vCurRemarks, 
                     vCurIsRoomRevenue, vCurIsInPrice, vCurIsSplit, vCurRoomRevenueAmountsOnly, vCurCalendarDayType, vCurTimetable, vCurPriceTag, vCurQuantityCalculationRule,
                     vCurSrvQuantity, vFirstDayWithAccommodationService, vIsCheckIn, vIsRoomChange, vIsCheckOut, 
                     vFixedDiscount, vFixedServiceDiscount, vPeriodDiscount, vPeriodDiscountType, vPeriodDiscountServiceGroup, vPeriodDiscountConfirmationText, 
                     vAccDiscounts, vMCServices, vNoAccommodationService, vRoomRate, vAccommodationType, vRoom, vRoomRoomType, vNoDiscounts, 
					 vRoomRevenuePriceByRoomType, vRestOfCurPrice, vRestOfCurAmount, vChargingRuleAmountIsSet, vRestOfServiceSum, 
					 vRoomRates, vNoCommission = False, vChargingRules, vComplexCommission = Undefined, vPacketPriceIsIncludedInRoomRate = False, vCurRoomRateSrv = Undefined, vCurRestOfRoomRateSrv = Undefined, rMessage = "", vOccParams = Undefined, 
					 vServicePackageUsageType = Undefined, vServicePackage = Undefined, vMealBoardTermIncluded = Undefined, vMealBoardTermIncludedServices = Undefined, vContractMealBoardTerms = Undefined, vReservationDate = '00010101', vAccommodationTemplate = Undefined, 
					 vCurNumberOfPersons = 0, vCurNumberOfRooms = 0, vCurNumberOfBeds = 0, vCurNumberOfAdditionalBeds = 0, vCurRoomRateSrvHasManualPrice = False, vIsManualPrice = False, vPriceCalculationDate = '00010101', vOffers = Undefined, pIsForFolioSplit = False, vDoNotRoundPrice = False, 
					 vCurAccommodationType = Undefined, pIsForFolioSplitForPrices = False, pSplitPackagesByGuests = False, vIsManualServices = Undefined, 
					 Val vClientType = Undefined, Val vSourceOfBusiness = Undefined, vMarketingCode = Undefined, Val vBoardPlace = Undefined, vCalendarDayTypeIsChanged = False, 
                     vOfferByRoomTypeUpgradeDescription = "", vOfferByTermsUpgradeDescription = "", vRateService = Undefined, vGuestsCheckedInIsSet = False)
	If Not ValueIsFilled(vPriceCalculationDate) Then
		vPriceCalculationDate = PriceCalculationDate;
	EndIf;
	If vClientType = Undefined Then
		vClientType = ClientType;
	EndIf;
	If vSourceOfBusiness = Undefined Then
		vSourceOfBusiness = SourceOfBusiness;
	EndIf;
	If vMarketingCode = Undefined Then
		vMarketingCode = MarketingCode;
	EndIf;
	If vBoardPlace = Undefined Then
		vBoardPlace = BoardPlace;
	EndIf;
	// Check price upgrade
	vOffer = Undefined;
	If vOffers = Undefined Then
		vOffers = New ValueTable();
	EndIf;
	vRoomTypeUpgradeOffer = Undefined;
	vUpgradeService = Hotel.RoomUpgradeService;
	vUpgradePrice = 0;
	vUpgradeDiscount = 0;
	vUpgradeCurrency = vCurFolioCurrency;
	vOfferRoomTypeUpgrade = Undefined;
	vOfferUpgradeIsActive = False;
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
							vUpgradeCurrency = vOffer.Currency; 
							vRoomTypeUpgradeOffer = vOffer;
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
					vRateCurrency = vCurFolioCurrency;
					vRoomPriceBeforeUpgrade = pmGetServiceRatePrice(vRoomRate, vCurAccountingDate, vPriceCalculationDate, ?(ValueIsFilled(vRateService), vRateService, vCurService), vRateCurrency, RoomTypeBeforeUpgrade, ?(vCurPriceTag = Undefined, Catalogs.PriceTags.EmptyRef(), vCurPriceTag), vAccommodationType, vAccommodationTemplate, pIsForFolioSplitForPrices, pSplitPackagesByGuests);
					If vRoomPriceBeforeUpgrade <> 0 Then
						// Apply share percent
						If vCurIsRoomRevenue And vCurIsInPrice Then
							If pIsForFolioSplit And Not IsBlankString(SharePercent) Then
								vRoomPriceBeforeUpgrade = cmApplySharePercent(vRoomPriceBeforeUpgrade, SharePercent);
							EndIf;
						EndIf;
						If vRateCurrency <> vCurFolioCurrency Then
							vRoomPriceBeforeUpgradeInFolioCurrency = Round(cmConvertCurrencies(vRoomPriceBeforeUpgrade, vRateCurrency, , vCurFolioCurrency, vCurFolioCurrencyExchangeRate, ?(ValueIsFilled(vCurAccountingDate), vCurAccountingDate, ExchangeRateDate), Hotel), 2);
						Else
							vRoomPriceBeforeUpgradeInFolioCurrency = vRoomPriceBeforeUpgrade;
						EndIf;
						If vRoomPriceBeforeUpgradeInFolioCurrency > 0 And vCurPrice > vRoomPriceBeforeUpgradeInFolioCurrency Then
							vPriceDiffDiscount = Round((vCurPrice - vRoomPriceBeforeUpgradeInFolioCurrency) * (100 - vUpgradeDiscount) / 100, 2);
							vUpgradePrice = vUpgradePrice + vPriceDiffDiscount;
							vCurPrice = vRoomPriceBeforeUpgradeInFolioCurrency;
							vOfferByRoomTypeUpgradeDescription = TrimAll(vRoomTypeUpgradeOffer);
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	vDoNotApplyDiscountsToPriceCorrection = False;
	If ValueIsFilled(DiscountType) And DiscountType.DoNotApplyToTerms Then
		vDoNotApplyDiscountsToPriceCorrection = True;
	EndIf;
	// Add service				 
	vSrv = Services.Insert(i);
	i = i + 1;
	vSrv.Folio = vCurFolio;
	vSrv.FolioCurrency = vCurFolioCurrency;
	vSrv.FolioCurrencyExchangeRate = vCurFolioCurrencyExchangeRate;
	// Shift service accounting date to check-in date if neccessary
	vSrv.AccountingDate = vCurAccountingDate;
	vSrv.Service = vCurService;
	vSrv.Price = vCurPrice;
	If vRoomRate.RoundPrice And Not vDoNotRoundPrice Then
		If Not ValueIsFilled(vRoomRate.RoundPriceServiceGroup) Or 
		   ValueIsFilled(vRoomRate.RoundPriceServiceGroup) And cmIsServiceInServiceGroup(vSrv.Service, vRoomRate.RoundPriceServiceGroup) Then
			vSrv.Price = Round(vSrv.Price, vRoomRate.RoundPriceDigits);
		EndIf;
	EndIf;
	// Check if this is free of charge day
	If Not vRoomRate.NoDiscounts And vCurIsInPrice And ValueIsFilled(DiscountType) And DiscountType.EachNDayIsFreeOfCharge > 0 And
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
		If pIsForFolioSplit And Not IsBlankString(SharePercent) Then
			vSrv.Price = cmApplySharePercent(vSrv.Price, SharePercent);
		EndIf;
	EndIf;
	vSrv.Unit = vCurUnit;
	vSrv.Quantity = vCurQuantity;
	vSrv.Sum = Round(vSrv.Price * vSrv.Quantity, 2);
	vSrv.VATRate = vCurVATRate;
	vSrv.VATSum = cmCalculateVATSum(vCurVATRate, vSrv.Sum, vSrv.AccountingDate);
	vSrv.RateSum = 0;
	vSrv.RateDiscountSum = 0;
	vSrv.RateCommissionSum = 0;
	vSrv.Remarks = vCurRemarks;
	vSrv.Company = Company;
	If vSrv.Company <> vCurFolio.Company And vCurFolio.DoNotUpdateCompany Then
		vSrv.Company = vCurFolio.Company;
	EndIf;
	vSrv.IsRoomRevenue = vCurIsRoomRevenue;
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
	vSrv.IsInPrice = vCurIsInPrice;
	vSrv.IsSplit = vCurIsSplit;
	vSrv.RoomRevenueAmountsOnly = vCurRoomRevenueAmountsOnly;
	vSrv.CalendarDayType = vCurCalendarDayType;
	If Not ValueIsFilled(vCurCalendarDayType) And ValueIsFilled(vCurAccountingDate) And ValueIsFilled(vRoomRate) Then
		vSrv.CalendarDayType = cmGetCalendarDayType(vRoomRate, vSrv.AccountingDate, CheckInDate, CheckOutDate, , ?(ValueIsFilled(RoomTypeUpgrade), RoomTypeUpgrade, vRoomRoomType), vPriceCalculationDate);
	EndIf;
	vSrv.PriceTag = vCurPriceTag;
	vSrv.CalendarDayTypeIsChanged = vCalendarDayTypeIsChanged;
	vSrv.RoomRate = vRoomRate;
	vSrv.AccommodationType = ?(Not pIsForFolioSplit And vCurService.ChargeToEachGuestSeparately And 
	                           ValueIsFilled(vCurAccommodationType) And ValueIsFilled(vRoomRate) And 
	                           vRoomRate.RateChargeDirection = Enums.RateChargeDirections.MergeToTheMainRoomGuest, 
							   vCurAccommodationType, 
							   vAccommodationType);
	vSrv.Room = vRoom;
	vSrv.RoomType = vRoomRoomType;
	vSrv.Timetable = vCurTimetable;
	vSrv.IsManual = False;
	vSrv.ServicePackage = vServicePackage;
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
		vNumberOfPersons = vCurNumberOfPersons;
		vNumberOfRooms = vCurNumberOfRooms;
		vNumberOfBeds = ?(vCurNumberOfRooms > 0, vCurNumberOfRooms * vNumberOfBedsPerRoom, vCurNumberOfBeds);
		vNumberOfAdditionalBeds = vCurNumberOfAdditionalBeds;
		vIsVirtual = False;
		If ValueIsFilled(vRoom) Then
			vIsVirtual = vRoom.IsVirtual;
		ElsIf ValueIsFilled(vRoomRoomType) Then
			vIsVirtual = vRoomRoomType.IsVirtual;
		EndIf;
		If vRoomRoomType <> RoomType Then
			If ValueIsFilled(vRoom) Then
				vRoomAttrs = vRoom.GetObject().pmGetRoomAttributes(cm1SecondShift(vSrv.AccountingDate));
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
				vNumberOfRooms = vCurNumberOfRooms;
				vNumberOfBeds = ?(vNumberOfRooms > 0, vNumberOfRooms * vNumberOfBedsPerRoom, vCurNumberOfBeds);
				vNumberOfAdditionalBeds = vCurNumberOfAdditionalBeds;
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
			If vIsCheckIn Then
				vSrv.GuestsCheckedIn = vNumberOfPersons;
			EndIf;
		EndIf;
		If ValueIsFilled(vSrv.RoomType) AND vSrv.RoomType.DoesNotAffectRoomRevenueStatistics Then
			vCurPeriodInHours = vCurQuantityCalculationRule.PeriodInHours;
			vSrv.GuestDays = Round(vNumberOfPersons*vCurSrvQuantity*vCurPeriodInHours/24, 7);
			If vFirstDayWithAccommodationService Then
				vGuestsCheckedInIsSet = True;
				If vIsCheckIn Then
					vSrv.GuestsCheckedIn = vNumberOfPersons;
				EndIf;
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
	vPriceCorrection = vCurPrice;
	If vContractMealBoardTerms <> Undefined And vContractMealBoardTerms.Count() > 0 And ValueIsFilled(vServicePackage) Then
		vAccommodationTypesList = New ValueList();
		If ValueIsFilled(vRoomRate) And ValueIsFilled(vAccommodationTemplate) And vRoomRate.RateChargeDirection = Enums.RateChargeDirections.MergeToTheMainRoomGuest Then
			For Each vTemplateAccTypesRow In vAccommodationTemplate.AccommodationTypes Do
				vAccommodationTypesList.Add(vTemplateAccTypesRow.AccommodationType);
			EndDo;
		Else
			vAccommodationTypesList.Add(vAccommodationType);
		EndIf;
		For Each vAccommodationTypesListItem In vAccommodationTypesList Do
			vWrkAccommodationType = vAccommodationTypesListItem.Value;
			vCMBTRows = vContractMealBoardTerms.FindRows(New Structure("MealBoardTerm", vServicePackage));
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
				vTermsUpgradeOffer = Undefined;
				For Each vOffersRow In vOffers Do
					vOffer = vOffersRow.SpecialOffer;
					For Each vOfferUpgradeRow In vOffer.TermsUpgrades Do
						If vOfferUpgradeRow.TermsTo = vServicePackage And 
						   ValueIsFilled(vOfferUpgradeRow.TermsFrom) And vOfferUpgradeRow.TermsFrom = vMealBoardTermIncluded Then
							If vOfferUpgradeRow.PriceMarkup <> 0 Then
								vTermsUpgradePriceMarkup = vOfferUpgradeRow.PriceMarkup;
							EndIf;
							If vOfferUpgradeRow.PriceDifferenceDiscount >= 0 And vOfferUpgradeRow.PriceDifferenceDiscount <= 100 Then
								vTermsUpgradePriceDifferenceDiscount = vOfferUpgradeRow.PriceDifferenceDiscount;
							EndIf;
							vTermsUpgradeCurrency = vOffer.Currency;
							vTermsUpgradeOffer = vOffer;
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
				If cmIsServiceInServiceGroup(vSrv.Service, vDiscountServiceGroup) And ValueIsFilled(vDiscountType) And 
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
					If ValueIsFilled(vServicePackage) Then
						For Each vOffersRow In vOffers Do
							vCurOffer = vOffersRow.SpecialOffer;
							If vCurOffer.ServicePackageDiscounts.Count() > 0 Then
								vOfferSPDRows = vCurOffer.ServicePackageDiscounts.FindRows(New Structure("ServicePackage", vServicePackage));
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
			If vCurOffer.EarlyCheckInDiscount <> 0 And 
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
				If Not ValueIsFilled(vCurDiscountType) Or ValueIsFilled(vCurDiscountType) And 
					                                     (Not vCurDiscountType.IsForRackRatesOnly Or 
				                                          vCurDiscountType.IsForRackRatesOnly And ValueIsFilled(vSrv.RoomRate) And vSrv.RoomRate.IsRackRate Or
														  vSrv.IsManual) Then 
					vSrv.Discount = vCurDiscount;
					vSrv.DiscountType = vCurDiscountType;
					vSrv.DiscountServiceGroup = vCurDiscountServiceGroup;
					vSrv.DiscountConfirmationText = vCurDiscountConfirmationText;
					If Not IsBlankString(vCurDiscountConfirmationText) Then
						DiscountConfirmationText = vCurDiscountConfirmationText;
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
	// Check if charging rule amount is set
	If vChargingRuleAmountIsSet Then 
		If vCurRoomRateSrv <> Undefined And Not vCurRoomRateSrv.IsManualPrice Then
			If vPacketPriceIsIncludedInRoomRate Or vServicePackageUsageType = Enums.ServicePackageUsageType.SubtractFromRoomRatePrice Then
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
			ElsIf vServicePackageUsageType = Enums.ServicePackageUsageType.AddToRoomRatePrice Then
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
	If Not vNoCommission Then
		pmSetServiceCommissions(vSrv, vRoomRates, vComplexCommission);
	EndIf;
	// Check if this is room rate service
	If vCurRoomRateSrv = Undefined Then
		If vSrv.IsRoomRevenue And vSrv.IsInPrice Then
			vCurRoomRateSrv = vSrv;
			vCurRoomRateSrvHasManualPrice = vIsManualPrice;
		EndIf;
	Else
		If Not vSrv.IsRoomRevenue And vSrv.IsInPrice Then // And Not FixReservationConditions Then
			If vPacketPriceIsIncludedInRoomRate And Not vCurRoomRateSrv.IsManualPrice Then
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
			ElsIf vServicePackageUsageType = Enums.ServicePackageUsageType.AddToRoomRatePrice Then
				If Not vCurRoomRateSrv.IsManualPrice Then
					vCurRoomRateSrv.Sum = vCurRoomRateSrv.Sum + vSrv.Sum;
					vCurRoomRateSrv.DiscountSum = vCurRoomRateSrv.DiscountSum + vSrv.DiscountSum;
					vCurRoomRateSrv.VATDiscountSum = vCurRoomRateSrv.VATDiscountSum + vSrv.VATDiscountSum;
					// Recalculate VAT sum
					vCurRoomRateSrv.VATSum = cmCalculateVATSum(vCurRoomRateSrv.VATRate, vCurRoomRateSrv.Sum, vCurRoomRateSrv.AccountingDate);
					// Recalculate VAT sum
					vCurRoomRateSrv.Price = Round(vCurRoomRateSrv.Sum / ?(vCurRoomRateSrv.Quantity = 0, 1, vCurRoomRateSrv.Quantity), 2);
					// Calculate commission for this service if applicable
					pmSetServiceCommissions(vCurRoomRateSrv, vRoomRates, vComplexCommission);
				EndIf;
				
				// Update current service
				If vServicePackage.IsMealBoardTerm Then
					vSrv.Quantity = 0;
				EndIf;
				vSrv.Sum = 0;
				vSrv.Price = 0;
				vSrv.DiscountSum = 0;
				vSrv.VATSum = 0;
				vSrv.VATDiscountSum = 0;
				vSrv.CommissionSum = 0;
				vSrv.VATCommissionSum = 0;
			ElsIf vServicePackageUsageType = Enums.ServicePackageUsageType.SubtractFromRoomRatePrice And Not vCurRoomRateSrv.IsManualPrice Then
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
			If ValueIsFilled(vMealBoardTermIncluded) And vMealBoardTermIncluded = vServicePackage And ValueIsFilled(vServicePackage.RoomRevenueService) Then
				// Price correction
				If vPriceCorrection <> 0 And Not vCurRoomRateSrv.IsManualPrice And Not vCurRoomRateSrvHasManualPrice Then
					// Subtract default meal board price from room rate price 
					vCurRoomRateSrv.Price = vCurRoomRateSrv.Price + vPriceCorrection;
					vCurRoomRateSrv.Price = ?(vCurRoomRateSrv.Price < 0, 0, vCurRoomRateSrv.Price);
					// Recalculate sum
					vCurRoomRateSrv.Sum = Round(vCurRoomRateSrv.Price * vCurRoomRateSrv.Quantity, 2);
					// Recalculate VAT sum
					vCurRoomRateSrv.VATSum = cmCalculateVATSum(vCurRoomRateSrv.VATRate, vCurRoomRateSrv.Sum, vCurRoomRateSrv.AccountingDate);
					// Calculate discounts
					If Not vDoNotApplyDiscountsToPriceCorrection Then
						pmCalculateServiceDiscounts(vCurRoomRateSrv);
					EndIf;
					// Calculate commission for this service if applicable
					pmSetServiceCommissions(vCurRoomRateSrv, vRoomRates, vComplexCommission);
				EndIf;
				// Update current service
				If vServicePackage.IsMealBoardTerm Then
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
			ElsIf ValueIsFilled(vMealBoardTermIncluded) And ValueIsFilled(vServicePackage) And vMealBoardTermIncluded <> vServicePackage And vServicePackage.IsMealBoardTerm And ValueIsFilled(vServicePackage.RoomRevenueService) Then
				// Price correction
				If vPriceCorrection <> 0 And Not vCurRoomRateSrv.IsManualPrice And Not vCurRoomRateSrvHasManualPrice Then
					// Subtract default meal board price from room rate price 
					vCurRoomRateSrv.Price = vCurRoomRateSrv.Price + vPriceCorrection;
					vCurRoomRateSrv.Price = ?(vCurRoomRateSrv.Price < 0, 0, vCurRoomRateSrv.Price);
					// Recalculate sum
					vCurRoomRateSrv.Sum = Round(vCurRoomRateSrv.Price * vCurRoomRateSrv.Quantity, 2);
					// Recalculate VAT sum
					vCurRoomRateSrv.VATSum = cmCalculateVATSum(vCurRoomRateSrv.VATRate, vCurRoomRateSrv.Sum, vCurRoomRateSrv.AccountingDate);
					// Calculate discounts
					If Not vDoNotApplyDiscountsToPriceCorrection Then
						pmCalculateServiceDiscounts(vCurRoomRateSrv);
					EndIf;
					// Calculate commission for this service if applicable
					pmSetServiceCommissions(vCurRoomRateSrv, vRoomRates, vComplexCommission);
				EndIf;
				// Update current service
				If vServicePackage.IsMealBoardTerm Then
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
	If Not vSrv.IsManual And vIsManualServices <> Undefined Then
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
				FillPropertyValues(vSrv, vMCSrv, , "LineNumber, Folio, Company, Room, RoomType, AccommodationType, RoomRate, GuestsCheckedIn, GuestDays, AdditionalBedsRented, BedsRented, RoomsRented, Timetable, CalendarDayType, RateSum, RateDiscountSum, RateCommissionSum, ClientType, SourceOfBusiness, MarketingCode, BoardPlace" + 
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
				If Not vNoCommission And Not vMCSrv.CommissionIsChanged Then
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
				If Not ((vPacketPriceIsIncludedInRoomRate Or vServicePackageUsageType = Enums.ServicePackageUsageType.SubtractFromRoomRatePrice) And Not vCurRoomRateSrv.IsManualPrice) Then
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
	// Check available quantity
	If ValueIsFilled(vSrv.AccountingDate) And ValueIsFilled(vSrv.Service) And vSrv.Service = vCurService And vCurService.AvailableQuantity <> 0 Then
		vAvailableQuantity = vCurService.AvailableQuantity;
		vUsedQuantity = cmGetServiceUsedQuantity(vCurService, BegOfDay(vSrv.AccountingDate), cmExtractTime(BegOfDay(vSrv.AccountingDate)), cmExtractTime(EndOfDay(vSrv.AccountingDate)), Ref);
		If (vAvailableQuantity - vUsedQuantity - vSrv.Quantity) <= 0 Then
			rMessage = "en='" + "[" + Format(vSrv.AccountingDate, "DF=dd.MM.yyyy") + "] " + TrimAll(vCurService) + " - There is: " + vAvailableQuantity + "; Used: " + vUsedQuantity + "'; " + 
			           "ru='" + "[" + Format(vSrv.AccountingDate, "DF=dd.MM.yyyy") + "] " + TrimAll(vCurService) + " - Есть: " + vAvailableQuantity + "; Использовано: " + vUsedQuantity + "'; " + 
			           "de='" + "[" + Format(vSrv.AccountingDate, "DF=dd.MM.yyyy") + "] " + TrimAll(vCurService) + " - Es gibt: " + vAvailableQuantity + "; Gebraucht: " + vUsedQuantity + "'";
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
		pmSetServiceFolioBasedOnChargingRules(vUpgrdSrv, vChargingRules, True);
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
EndProcedure // AddService

// -----------------------------------------------------------------------------
// Calculates services for the given document.
// Returns False if warnings were rised during services calculation. Otherwise
// returns True
// -----------------------------------------------------------------------------
Function pmCalculateServices(rWarnings = "", pPeriodDiscount = 0, pPeriodDiscountType = Undefined, 
                                             pPeriodDiscountServiceGroup = Undefined, pPeriodDiscountConfirmationText = "", pIsForFolioSplit = Undefined, pIgnoreRestrictions = False, pAccommodationTemplate = Undefined) Export
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
	If Not IsNew() And ValueIsFilled(Ref) Or ValueIsFilled(Reservation) Then
		vCurAccountingDate = ?(ValueIsFilled(Hotel.AccountingDate), Hotel.AccountingDate, BegOfDay(CurrentSessionDate()));
		vNewPriceCalculationDate = CurrentSessionDate();
		If vNewPriceCalculationDate = BegOfDay(vNewPriceCalculationDate) Then
			vNewPriceCalculationDate = vNewPriceCalculationDate + 1;
		EndIf;
		If ValueIsFilled(RoomRate) And RoomRate.RoomTypeChangeUpdatesPriceCalculationDate Then
			If Not IsNew() And ValueIsFilled(Ref) And Ref.RoomType <> RoomType And Ref.PriceCalculationDate = PriceCalculationDate Or 
			   IsNew() And ValueIsFilled(Reservation) And Reservation.RoomType <> RoomType And Reservation.PriceCalculationDate = PriceCalculationDate Then
				PriceCalculationDate = vNewPriceCalculationDate;
				For Each vSrvRow In Services Do
					If vSrvRow.CalendarDayTypeIsChanged And vSrvRow.AccountingDate >= vCurAccountingDate Then
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
					vOldRRRow = Undefined;
					If Not IsNew() And ValueIsFilled(Ref) Then
						vOldRRRow = Ref.RoomRates.Find(vRRRow.AccountingDate, "AccountingDate");
					ElsIf IsNew() And ValueIsFilled(Reservation) Then
						vOldRRRow = Reservation.RoomRates.Find(vRRRow.AccountingDate, "AccountingDate");
					EndIf;
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
	
	// Remove special offers from discount confirmation text
	vSpecOfferPos = StrFind(DiscountConfirmationText, Char(8226));
	If vSpecOfferPos > 1 Then
		DiscountConfirmationText = TrimAll(Left(DiscountConfirmationText, vSpecOfferPos - 1));
	Else
		DiscountConfirmationText = "";
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
	
	// Folio split mode
	vMainRoomGuestAccommodationTemplate = AccommodationTemplate;
	If ValueIsFilled(pAccommodationTemplate) And IsForFolioSplit And Not IsBlankString(SharePercent) Then
		vMainRoomGuestAccommodationTemplate = pAccommodationTemplate;
	EndIf;
	vOneRoomAccommodations = Undefined;
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
				vOneRoomAccommodations = cmGetOneRoomAccommodations(Room, GuestGroup, CheckInDate, CheckOutDate, Number, Posted);
				If vOneRoomAccommodations.Count() = 0 Then
					vIsForFolioSplit = True;
				EndIf;
				For Each vOneRoomAccommodationRow In vOneRoomAccommodations Do
					If vOneRoomAccommodationRow.AccommodationTypeType = Enums.AccomodationTypes.Beds Then
						vIsForFolioSplit = True;
					EndIf;
					If Not ValueIsFilled(vMainRoomGuestAccommodationTemplate) And vIsForFolioSplit And Not IsBlankString(SharePercent) And ValueIsFilled(vOneRoomAccommodationRow.AccommodationTemplate) Then
						vMainRoomGuestAccommodationTemplate = vOneRoomAccommodationRow.AccommodationTemplate;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	If Not ValueIsFilled(vMainRoomGuestAccommodationTemplate) And vIsForFolioSplit And Not IsBlankString(SharePercent) Then
		If vOneRoomAccommodations = Undefined Then
			vOneRoomAccommodations = cmGetOneRoomAccommodations(Room, GuestGroup, CheckInDate, CheckOutDate, Number);
		EndIf;
		For Each vOneRoomAccommodationRow In vOneRoomAccommodations Do
			If ValueIsFilled(vOneRoomAccommodationRow.AccommodationTemplate) Then
				vMainRoomGuestAccommodationTemplate = vOneRoomAccommodationRow.AccommodationTemplate;
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
			NumberOfAdults = AccommodationTemplate.NumberOfAdults;
			NumberOfTeenagers = AccommodationTemplate.NumberOfTeenagers;
			NumberOfChildren = AccommodationTemplate.NumberOfChildren;
			NumberOfInfants = AccommodationTemplate.NumberOfInfants;
		EndIf;
	Else
		NumberOfAdults = 0;
		NumberOfTeenagers = 0;
		NumberOfChildren = 0;
		NumberOfInfants = 0;
	EndIf;
	
	// User exit before calculate services
	vBeforeCalculateServicesUserExit = Catalogs.ExternalDataProcessors.AccommodationBeforeCalculateServices;
	If vBeforeCalculateServicesUserExit.ExternalProcessingType = Enums.ExternalProcessingTypes.Algorithm And Not IsBlankString(vBeforeCalculateServicesUserExit.Algorithm) Then
		SetSafeMode(True);
		Execute(TrimR(vBeforeCalculateServicesUserExit.Algorithm));
		SetSafeMode(False);
	EndIf;
	
	// Processing
	vNoAccommodationService = True;
	vCurPriceTag = Undefined;
	BegOfCheckInDate = BegOfDay(CheckInDate);
	HotelAccountingDate = '00010101';
	CheckAccountingDate = False;	
	If ValueIsFilled(Hotel) Then
		CheckAccountingDate = Hotel.DoNotEditClosedDateDocs;
		HotelAccountingDate = Hotel.AccountingDate;
		If Not ValueIsFilled(HotelAccountingDate) Then
			CheckAccountingDate = False;
		EndIf;
	EndIf;
	If ValueIsFilled(HotelAccountingDate) And AdditionalProperties.Property("AccountingDate") Then
		If ValueIsFilled(AdditionalProperties.AccountingDate) And TypeOf(AdditionalProperties.AccountingDate) = Type("Date") Then
			HotelAccountingDate = AdditionalProperties.AccountingDate;
		EndIf;
	EndIf;
	vSplitChargesToPersonalFolioForIndividualCustomers = Constants.SplitChargesToPersonalFolioForIndividualCustomers.Get();
	// Check if this accommodation is check in
	vIsCheckIn = False;
	vIsCheckOut = False;
	vIsRoomChange = False;
	vIsBeforeRoomChange = False;
	If ValueIsFilled(AccommodationStatus) Then
		vIsCheckIn = AccommodationStatus.IsCheckIn;
		vIsCheckOut = AccommodationStatus.IsCheckOut;
		vIsRoomChange = AccommodationStatus.IsRoomChange;
		If AccommodationStatus.IsActive And Not AccommodationStatus.IsCheckOut Then
			vIsBeforeRoomChange = True;
		EndIf;
	EndIf;
	// Check if this accommodation is based on reservation
	vFixReservationConditions = FixReservationConditions;
	vIsBasedOnReservation = False;
	vReservation = Documents.Reservation.EmptyRef();
	vReservationCheckInDate = CheckInDate;
	vReservationCheckOutDate = CheckOutDate;
	pmSetIsByReservation(vReservation);
	If IsByReservation And ValueIsFilled(vReservation) Then
		If vIsCheckIn Then
			vIsBasedOnReservation = True;
		EndIf;
		If ValueIsFilled(vReservation) Then
			vReservationCheckInDate = vReservation.CheckInDate;
			vReservationCheckOutDate = vReservation.CheckOutDate;
		EndIf;
		// Optimization: virtually switch off fix reservation conditions flag if accommodation does not differ from reservation
		If vFixReservationConditions Then
			If BegOfDay(CheckInDate) = BegOfDay(vReservationCheckInDate) And BegOfDay(CheckOutDate) = BegOfDay(vReservationCheckOutDate) Then
				If ValueIsFilled(RoomRate) And ValueIsFilled(RoomRate.ReferenceHour) And RoomRate.PeriodInHours = 24 Then
					vReferenceHourInSeconds = RoomRate.ReferenceHour - BegOfDay(RoomRate.ReferenceHour);
					vCheckInTimeInSeconds = CheckInDate - BegOfDay(CheckInDate);
					vCheckOutTimeInSeconds = CheckOutDate - BegOfDay(CheckOutDate);
					If vCheckInTimeInSeconds >= vReferenceHourInSeconds And vCheckOutTimeInSeconds <= vReferenceHourInSeconds Then
						If vReservation.RoomType = RoomType And vReservation.AccommodationType = AccommodationType And vReservation.AccommodationTemplate = AccommodationTemplate Then
							If vReservation.RoomRates.Count() = RoomRates.Count() Then
								vFixReservationConditions = False;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	vReservationDate = Date;
	If ValueIsFilled(GuestGroup) And ValueIsFilled(GuestGroup.CreateDate) Then
		vReservationDate = GuestGroup.CreateDate;
	EndIf;
	vParentDocObj = Undefined;
	If ValueIsFilled(ParentDoc) Then
		vParentDocObj = ParentDoc.GetObject();
	EndIf;
	
	// Create table of charging rules
	vCRTab = ChargingRules.Unload();
	If Not IgnoreGroupChargingRules Then
		cmAddGuestGroupChargingRules(vCRTab, GuestGroup);
	EndIf;
	// Check if there are customer charging rules
	vThereAreCustomerChargingRules = False;
	For Each vCRTabRow In vCRTab Do
		If ValueIsFilled(vCRTabRow.Owner) And 
		  (TypeOf(vCRTabRow.Owner) = Type("CatalogRef.Customers") Or TypeOf(vCRTabRow.Owner) = Type("CatalogRef.Contracts")) Then
			vThereAreCustomerChargingRules = True;
			Break;
		EndIf;
	EndDo;
	
	// Fill effective period
	vCheckInDate = CheckInDate;
	vCheckOutDate = CheckOutDate;
	// Move date from to the end of accounting date
	If IsByReservation And ValueIsFilled(Reservation) Then
		If ValueIsFilled(AccountingCheckInDate) And BegOfDay(vCheckInDate) > AccountingCheckInDate And 
		  (BegOfDay(vCheckInDate) - AccountingCheckInDate)/(24*3600) = 1 And 
		   AccountingCheckInDate = BegOfDay(Reservation.CheckInDate) Then
			vCheckInDate = EndOfDay(AccountingCheckInDate);
		EndIf;
	EndIf;
	// Process vaucher
	If ValueIsFilled(HotelProduct) And Not HotelProduct.IsFolder Then
		If HotelProduct.FixProductPeriod Then
			vCheckInDate = HotelProduct.CheckInDate;
			vCheckOutDate = HotelProduct.CheckOutDate;
			// If this is not check-in then return because all services were already added
			If Not vIsCheckIn Then
				PricePresentation = "";
				Return vWarnings;
			EndIf;
		EndIf;
		If HotelProduct.FixProductCost Then
			// If this is not check-in then return because all services were already added
			If Not vIsCheckIn Then
				PricePresentation = "";
				Return vWarnings;
			EndIf;
		EndIf;
	EndIf;
	If FixReservationConditions And IsByReservation Then
		vSavCheckInDate = vCheckInDate;
		vSavCheckOutDate = vCheckOutDate;
		If vIsCheckIn Then
			If ValueIsFilled(ParentDoc) And TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Then
				vCheckInDate = Min(CheckInDate, vReservationCheckInDate);
			Else
				vReservationCheckInDate = vCheckInDate;
			EndIf;
		EndIf;
		If vIsCheckOut Then
			vSkipCheck = True;
			If IsNew() Then
				vSkipCheck = False;
			EndIf;
			If vSkipCheck Then 
				// Check that there is no accommodation where current one is parent document
				vQry = New Query();
				vQry.Text = 
				"SELECT
				|	Accommodation.Ref
				|FROM
				|	Document.Accommodation AS Accommodation
				|WHERE
				|	Accommodation.Posted
				|	AND Accommodation.ParentDoc = &qParentDoc
				|	AND Accommodation.CheckInDate > &qCheckInDate
				|	AND Accommodation.AccommodationStatus.IsActive";
				vQry.SetParameter("qParentDoc", Ref);
				vQry.SetParameter("qCheckInDate", CheckInDate);
				vNextDocs = vQry.Execute().Unload();
				If vNextDocs.Count() = 0 Then
					vSkipCheck = False;
				EndIf;
			EndIf;
			If Not vSkipCheck Then
				vCheckOutDate = Max(CheckOutDate, vReservationCheckOutDate);
			Else
				vReservationCheckOutDate = vCheckOutDate;
			EndIf;
		EndIf;
		If vCheckOutDate <= vCheckInDate Then
			vCheckInDate = vSavCheckInDate;
			vCheckOutDate = vSavCheckOutDate;
			If Not (ValueIsFilled(ParentDoc) And TypeOf(ParentDoc) = Type("DocumentRef.Reservation")) Then
				vReservationCheckInDate = vCheckInDate;
				vReservationCheckOutDate = vCheckOutDate;
			EndIf;
		EndIf;
	EndIf;
	// Create table of manual prices
	vMPTab = Prices.Unload();
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
	If ValueIsFilled(Reservation) And FixReservationConditions Then
		vReservationDayTypes = Reservation.Services.Unload(, "CalendarDayType");
		vReservationDayTypes.GroupBy("CalendarDayType", );
		For Each vReservationDayTypesRow In vReservationDayTypes Do
			If vCalendarDayTypesList.FindByValue(vReservationDayTypesRow.CalendarDayType) = Undefined Then
				vCalendarDayTypesList.Add(vReservationDayTypesRow.CalendarDayType);
			EndIf;
		EndDo;
	EndIf;
	// Save services with prices changed manually
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
	// Clear room rate services
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
	// Check folios for the manual services
	pmSetFolioBasedOnChargingRules(Services, True);
	// Check that room rate is filled
	If Not ValueIsFilled(RoomRate) Then
		PricePresentation = "";
		Return vWarnings;
	EndIf;
	If Not ValueIsFilled(RoomRate.Calendar) Then
		PricePresentation = "";
		Return vWarnings;
	EndIf;
	// Get and check room rate restrictions
	vDoCheckRestrictions = False;
	If Not IsNew() Then
		If RoomRate <> Ref.RoomRate Or 
		   BegOfDay(CheckInDate) <> BegOfDay(Ref.CheckInDate) Or 
		   BegOfDay(CheckOutDate) <> BegOfDay(Ref.CheckOutDate) Or 
		   RoomType <> Ref.RoomType Then
			vDoCheckRestrictions = True;
		EndIf;
	ElsIf ValueIsFilled(Reservation) Then
		If RoomRate <> Reservation.RoomRate Or 
		   BegOfDay(CheckInDate) <> BegOfDay(Reservation.CheckInDate) Or 
		   BegOfDay(CheckOutDate) <> BegOfDay(Reservation.CheckOutDate) Or 
		   RoomType <> Reservation.RoomType Then
			vDoCheckRestrictions = True;
		EndIf;
	Else
		vDoCheckRestrictions = True;
	EndIf;
	vRestrStruct = RoomRate.GetObject().pmGetRoomRateRestrictions(vCheckInDate, vCheckOutDate, ?(ValueIsFilled(RoomTypeUpgrade), RoomTypeUpgrade, RoomType), True, PriceCalculationDate);
	If vDoCheckRestrictions And vRestrStruct.StopSale And AccommodationStatus.IsActive And AccommodationStatus.IsInHouse Then
		vWarnings = True;
		vWarningsEn = "Room rate " + TrimAll(RoomRate) + " could not be used for the given period " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " - " + Format(vCheckOutDate, "DF=dd.MM.yyyy") + " (room rate restriction Stop Sales is turned on)!";
		vWarningsDe = "Tariff " + TrimAll(RoomRate) + " ist geschlossen (Tariff Einschränkung Stop Sale ist auf), periode " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " - " + Format(vCheckOutDate, "DF=dd.MM.yyyy") + "!";
		vWarningsRu = "Продажи по тарифу " + TrimAll(RoomRate) + " остановлены на периоде с " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " по " + Format(vCheckOutDate, "DF=dd.MM.yyyy") + " в ограничениях тарифа (Stop Sale включен)!";
		rWarnings = "ru = '" + vWarningsRu + "'; de = '" + vWarningsDe + "'; en = '" + vWarningsEn + "'";
	EndIf;
	If vDoCheckRestrictions And vRestrStruct.CTA And AccommodationStatus.IsActive And AccommodationStatus.IsCheckIn And AccommodationStatus.IsInHouse Then
		vWarnings = True;
		vWarningsEn = "Check-in is closed (CTA is On) for the given check-in date " + Format(vCheckInDate, "DF=dd.MM.yyyy") + "!";
		vWarningsDe = "Check-in ist fur den Check-in-Datum " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " geschlossen (CTA is On)!";
		vWarningsRu = "Заезд в выбранную дату " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " запрещен в ограничениях указанных у тарифа (CTA включен)!";
		rWarnings = "ru = '" + vWarningsRu + "'; de = '" + vWarningsDe + "'; en = '" + vWarningsEn + "'";
	EndIf;
	If vDoCheckRestrictions And vRestrStruct.CTD And AccommodationStatus.IsActive And AccommodationStatus.IsCheckOut And AccommodationStatus.IsInHouse Then
		vWarnings = True;
		vWarningsEn = "Check-out is closed (CTD is On) for the given check-out date " + Format(vCheckOutDate, "DF=dd.MM.yyyy") + "!";
		vWarningsDe = "Check-out ist fur den Check-out-Datum " + Format(vCheckOutDate, "DF=dd.MM.yyyy") + " geschlossen (CTD is On)!";
		vWarningsRu = "Выезд в выбранную дату " + Format(vCheckOutDate, "DF=dd.MM.yyyy") + " запрещен в ограничениях указанных у тарифа (CTD включен)!";
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
		If vDoCheckRestrictions And RoomRate.MLOSIsBlocking And ValueIsFilled(AccommodationStatus) And AccommodationStatus.IsCheckOut And AccommodationStatus.IsActive And Not FixReservationConditions Then
			vWarnings = True;
			vWarningsRu = "Минимальная продолжительность проживания " + vRestrStruct.MLOS + " дней!";
			vWarningsEn = "Minimum length of stay is " + vRestrStruct.MLOS + "!";
			vWarningsDe = "Mindestaufenthaltsdauer betragt " + vRestrStruct.MLOS + " Tage!";
			rWarnings = "ru = '" + vWarningsRu + "'; de = '" + vWarningsDe + "'; en = '" + vWarningsEn + "'";
		EndIf;
	EndIf;
	If vDoCheckRestrictions And vRestrStruct.MaxLOS > 0 And Duration > vRestrStruct.MaxLOS Then
		vWarnings = True;
		vWarningsRu = "Максимальная продолжительность проживания " + vRestrStruct.MaxLOS + " дней!";
		vWarningsEn = "Maximum length of stay is " + vRestrStruct.MaxLOS + "!";
		vWarningsDe = "Maximaleaufenthaltsdauer betragt " + vRestrStruct.MaxLOS + " Tage!";
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
	// Get accounting check-in and check-out dates
	vBegOfCheckInDate = BegOfDay(vCheckInDate);
	vBegOfCheckOutDate = BegOfDay(vCheckOutDate);
	// Save some old values
	vSavCheckInDate = CheckInDate;
	vSavCheckOutDate = CheckOutDate;
	If Not IsNew() Then
		vSavCheckInDate = Ref.CheckInDate;
		vSavCheckOutDate = Ref.CheckOutDate;
	EndIf;
	// Fill occupation percents
	vOccupationPercentsAreFilled = Not OccupationPercents.Count() = 0;
	// Discount confirmation text
	If Not ValueIsFilled(DiscountType) Or ValueIsFilled(DiscountType) And (DiscountType.IsAccumulatingDiscount Or IsBlankString(DiscountType.ConfirmationPattern) And Not DiscountType.IsManualDiscount) Then
		DiscountConfirmationText = "";
	EndIf;
	// Get list of accumulating discount types with actual resources
	vAccDiscounts = pmGetAccumulatingDiscountResources();
	// Initialize value of discount that should be applied to the whole period
	vPeriodDiscount = pPeriodDiscount;
	vPeriodDiscountType = pPeriodDiscountType;
	vPeriodDiscountServiceGroup = pPeriodDiscountServiceGroup;
	vPeriodDiscountConfirmationText = pPeriodDiscountConfirmationText;
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
	// Get list of price records for the given room rate
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
	vReservationRoomType = vRoomType;
	vReservationRoomRate = RoomRate;
	vReservationAccommodationType = AccommodationType;
	vReservationAccommodationTemplate = AccommodationTemplate;
	vReservationPriceCalculationDate = PriceCalculationDate;
	vReservationRoomRates = Undefined;
	vReservationServicePackage = ServicePackage;
	If ValueIsFilled(Reservation) Then
		vReservationRoomRate = Reservation.RoomRate;
		vReservationRoomType = Reservation.RoomType;
		If ValueIsFilled(Reservation.RoomTypeUpgrade) Then
			vReservationRoomType = Reservation.RoomTypeUpgrade;
		EndIf;
		vReservationAccommodationType = Reservation.AccommodationType;
		vReservationRoomRates = Reservation.GetObject().pmGetAccommodationPlan();
		vReservationServicePackage = Reservation.ServicePackage;
	EndIf;
	// Reservation prices cache
	vReservationPricesCache = New ValueTable();
	vReservationPricesCache.Columns.Add("RoomRate", cmGetCatalogTypeDescription("RoomRates"));
	vReservationPricesCache.Columns.Add("RoomType", cmGetCatalogTypeDescription("RoomTypes"));
	vReservationPricesCache.Columns.Add("AccommodationType", cmGetCatalogTypeDescription("AccommodationTypes"));
	vReservationPricesCache.Columns.Add("AccommodationTemplate", cmGetCatalogTypeDescription("AccommodationTemplates"));
	vReservationPricesCache.Columns.Add("PriceCalculationDate", cmGetDateTimeTypeDescription());
	vReservationPricesCache.Columns.Add("Prices");
	vReservationPricesCache.Columns.Add("CalendarDays");
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
	vRestOfCurAmount = 0;
	vRestOfServiceSum = 0;
	vChargingRuleAmountIsSet = False;
	vLastOccupationPercentRoomRate = Undefined;
	vLastOccupationPercentRoomType = Undefined;
	For Each vDayRow In vDays Do
		If vGuestsCheckedInIsSet Then
			vFirstDayWithAccommodationService = False;
		EndIf;
		vCurAccountingDate = vDayRow.Period;
		vCurCalendarDayType = vDayRow.CalendarDayType;
		vCurTimetable = vDayRow.Timetable;
		vCurPriceTag = Catalogs.PriceTags.EmptyRef();
		vFixedPriceTag = vDayRow.PriceTag;
		vEarlyCheckInQuantity = 0;
		vEarlyCheckInSrvQuantity = 0;
		vLateCheckOutQuantity = 0;
		vLateCheckOutSrvQuantity = 0;
		vCurRoomRateSrv = Undefined;
		vCurRoomRateSrvHasManualPrice = False;
		vCurRestOfRoomRateSrv = Undefined;
		// Build value table of discount percents per days
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
		// Fill some reservation attributes
		If vReservationRoomRates <> Undefined And ValueIsFilled(Reservation) Then
			vReservationRoomRatesRow = vReservationRoomRates.Find(vCurAccountingDate, "AccountingDate");
			If vReservationRoomRatesRow <> Undefined Then
				If ValueIsFilled(vReservationRoomRatesRow.RoomType) Then
					If Not ValueIsFilled(Reservation.RoomTypeUpgrade) Then
						vReservationRoomType = vReservationRoomRatesRow.RoomType;
					EndIf;
				EndIf;
				If ValueIsFilled(vReservationRoomRatesRow.RoomRate) Then
					vReservationRoomRate = vReservationRoomRatesRow.RoomRate;
				EndIf;
				If ValueIsFilled(vReservationRoomRatesRow.AccommodationType) Then
					vReservationAccommodationType = vReservationRoomRatesRow.AccommodationType;
				EndIf;
				If ValueIsFilled(vReservationRoomRatesRow.AccommodationTemplate) Then
					vReservationAccommodationTemplate = vReservationRoomRatesRow.AccommodationTemplate;
				EndIf;
				If ValueIsFilled(vReservationRoomRatesRow.PriceCalculationDate) Then
					vReservationPriceCalculationDate = vReservationRoomRatesRow.PriceCalculationDate;
				EndIf;
			EndIf;
		EndIf;
		vDoesNotAffectRoomRevenueStatistics = False;
		If ValueIsFilled(vRoomRoomType) And vRoomRoomType.DoesNotAffectRoomRevenueStatistics And vRoomRoomType.ConnectedRoomTypes.Count() = 0 Then
			vDoesNotAffectRoomRevenueStatistics = vRoomRoomType.DoesNotAffectRoomRevenueStatistics;
		EndIf;
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
					If IsNew() And Not ValueIsFilled(Reservation) Then
						vResetPriceTagPrices = True;
					EndIf;
				ElsIf vRoomRate.PriceTagType = Enums.PriceTagTypes.ByDurationOfStayByPeriod Then
					// Check should we used saved price tags or not
					If BegOfDay(CheckInDate) <> BegOfDay(vSavCheckInDate) Or BegOfDay(CheckOutDate) <> BegOfDay(vSavCheckOutDate) Then
						vResetPriceTagPrices = True;
					EndIf;
					If IsNew() And Not ValueIsFilled(Reservation) Then
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
					If IsNew() And Not ValueIsFilled(Reservation) Then
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
		// Try to restore old calendar day type from the reservation
		If FixReservationConditions And IsByReservation And vRoomType = vReservationRoomType And vAccommodationType = vReservationAccommodationType And 
		   vCurAccountingDate >= BegOfDay(vReservationCheckInDate) And vCurAccountingDate < BegOfDay(vReservationCheckOutDate) Then
			vReservationServices = vReservation.Services.FindRows(New Structure("AccountingDate, IsRoomRevenue, IsSplit", vCurAccountingDate, True, False));
			If vReservationServices.Count() > 0 Then
				vReservationServicesRow = vReservationServices.Get(0);
				vCurCalendarDayType = vReservationServicesRow.CalendarDayType;
				If vPriceTagsAreUsed And Not vResetPriceTagPrices Then
					vCurPriceTag = vReservationServicesRow.PriceTag;
				EndIf;
			EndIf;
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
			vCurRecorder = vPricesRow.Recorder;
			vCurService = vPricesRow.Service;
			vRateService = vPricesRow.Service;
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
			// Check that service fit to the room rate service group
			If cmIsServiceInServiceGroup(vCurService, RoomRateServiceGroup) Then
				If (vCurCalendarDayType = vPricesRow.CalendarDayType) Or 
				   (vPricesRow.CalendarDayType = Catalogs.CalendarDayTypes.EmptyRef() And 
				    (ValueIsFilled(vPricesRow.QuantityCalculationRule) Or 
				     vPricesRow.AccountingDayNumber = 0 And vCurAccountingDate = BegOfDay(vPricesRow.AccountingDate) Or 
				     vPricesRow.AccountingDayNumber = 9999 And vCurAccountingDate = vBegOfCheckOutDate Or 
				     vPricesRow.AccountingDayNumber <> 0 And vCurAccountingDate = (vBegOfCheckInDate + (vPricesRow.AccountingDayNumber - 1) * 24 * 3600) Or 
				     Not ValueIsFilled(vPricesRow.QuantityCalculationRule) And Not ValueIsFilled(vPricesRow.AccountingDate) And vPricesRow.AccountingDayNumber = 0)) Then
					If vPricesRow.AccountingDayNumber <> 0 And vPricesRow.AccountingDayNumber <> 9999 And vCurAccountingDate <> (vBegOfCheckInDate + (vPricesRow.AccountingDayNumber - 1) * 24 * 3600) 
						Or vPricesRow.AccountingDayNumber = 9999 And vCurAccountingDate <> vBegOfCheckOutDate Then
						Continue;
					EndIf;     
					// Check accounting date time for service package
					If ValueIsFilled(vPricesRow.AccountingDate) And vPricesRow.AccountingDate <> BegOfDay(vPricesRow.AccountingDate) Then
						If BegOfDay(vCheckInDate) = BegOfDay(vPricesRow.AccountingDate) And vPricesRow.AccountingDate <= vCheckInDate Then
							Continue;
						EndIf;
						If BegOfDay(vCheckOutDate) = BegOfDay(vPricesRow.AccountingDate) And vPricesRow.AccountingDate >= vCheckOutDate Then
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
								vRMPRows = RoomQuota.RoomTypes.FindRows(New Structure("RoomType, NumberOfAdults, NumberOfTeenagers, NumberOfChildren, NumberOfInfants", vProbeRoomType, NumberOfAdults, NumberOfTeenagers, NumberOfChildren, NumberOfInfants));
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
								vGMPRows = GuestGroup.InitialBlock.FindRows(New Structure("NumberOfAdults, NumberOfTeenagers, NumberOfChildren, NumberOfInfants", NumberOfAdults, NumberOfTeenagers, NumberOfChildren, NumberOfInfants));
								For Each vGMPRow In vGMPRows Do
									If vGMPRow.Price <> 0 And (Not ValueIsFilled(vGMPRow.RoomType) Or ValueIsFilled(vGMPRow.RoomType) And (vGMPRow.RoomType = vProbeRoomType Or vGMPRow.RoomType.IsFolder And vProbeRoomType.BelongsToItem(vGMPRow.RoomType))) Then
										If BegOfDay(vGMPRow.CheckInDate) = BegOfDay(CheckInDate) And BegOfDay(vGMPRow.CheckOutDate) = BegOfDay(CheckOutDate) Or 
										   ValueIsFilled(Reservation) And BegOfDay(vGMPRow.CheckInDate) = BegOfDay(Reservation.CheckInDate) And BegOfDay(vGMPRow.CheckOutDate) = BegOfDay(Reservation.CheckOutDate) Then
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
					// Initialize flags
					vEarlyCheckInIsCharged = False;
					vLateCheckOutIsCharged = False;
					vReservationServiceWasCharged = False;
					// Check charging rules
					vSkipPriceUpdate = False;
					vCRRowWasFound = False;
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
												If (vCurCalendarDayType = vCRPricesRow.CalendarDayType) 
													Or (vCRPricesRow.CalendarDayType = Catalogs.CalendarDayTypes.EmptyRef() And (ValueIsFilled(vCRPricesRow.QuantityCalculationRule) 
													 Or vCRPricesRow.AccountingDayNumber = 0 And vCurAccountingDate = BegOfDay(vCRPricesRow.AccountingDate) 
													 Or vCRPricesRow.AccountingDayNumber = 9999 And vCurAccountingDate = vBegOfCheckOutDate 
													 Or vCRPricesRow.AccountingDayNumber <> 0 And vCurAccountingDate = (vBegOfCheckInDate + (vCRPricesRow.AccountingDayNumber - 1) * 24 * 3600) 
													 Or Not ValueIsFilled(vCRPricesRow.QuantityCalculationRule) And Not ValueIsFilled(vCRPricesRow.AccountingDate) And vCRPricesRow.AccountingDayNumber = 0)) Then
													// Check accounting date time for service package
													If ValueIsFilled(vCRPricesRow.AccountingDate) And vCRPricesRow.AccountingDate <> BegOfDay(vCRPricesRow.AccountingDate) Then
														If BegOfDay(vCheckInDate) = BegOfDay(vCRPricesRow.AccountingDate) And vCRPricesRow.AccountingDate <= vCheckInDate Then
															Continue;
														EndIf;
														If BegOfDay(vCheckOutDate) = BegOfDay(vCRPricesRow.AccountingDate) And vCRPricesRow.AccountingDate >= vCheckOutDate Then
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
							vSrvAccountingDate = vCurAccountingDate;
							// Restore prices from the reservation
							vResRateSrv = False;
							vResService = Undefined;
							vResPrice = 0;
							vResQuantity = 0;
							vResDiscount = 0;
							vResDiscountSum = 0;
							vResVATDiscountSum = 0;
							vSavCurPrice = vCurPrice;
							If vFixReservationConditions And IsByReservation And vPricesRow.IsRoomRevenue And vPricesRow.IsInPrice And vAccommodationType = vReservationAccommodationType Then
								If vCurAccountingDate >= BegOfDay(vReservationCheckInDate) And vCurAccountingDate < BegOfDay(vReservationCheckOutDate) Then
									If Not vIsManualPrice Then
										vReservationServices = vReservation.Services.FindRows(New Structure("AccountingDate, Service, Folio, IsInPrice, IsSplit", vCurAccountingDate, vCurService, vCurFolio, True, False));
										If vReservationServices.Count() = 1 Then
											vReservationServicesRow = vReservationServices.Get(0);
											vResRateSrv = True;
											vResService = vReservationServicesRow.Service;
											vResPrice = vReservationServicesRow.Price;
											vResQuantity = vReservationServicesRow.Quantity;
											vResDiscount = vReservationServicesRow.Discount;
											vResDiscountSum = vReservationServicesRow.DiscountSum;
											vResVATDiscountSum = vReservationServicesRow.VATDiscountSum;
										EndIf;
									
										vReservationServiceCurrency = vCurFolioCurrency;
										vReservationServicePrice = pmGetServiceRatePrice(vReservationRoomRate, vSrvAccountingDate, vReservationPriceCalculationDate, vPricesRow.Service, vReservationServiceCurrency, vReservationRoomType, ?(vCurPriceTag = Undefined, Catalogs.PriceTags.EmptyRef(), vCurPriceTag), vReservationAccommodationType, vReservationAccommodationTemplate, vIsForFolioSplitForPrices, vSplitPackagesByGuests, vServicePackagesList, vReservationCheckInDate, vReservationCheckOutDate, vReservationPricesCache);
										If vReservationServiceCurrency <> vCurFolioCurrency Then
											vReservationPriceInFolioCurrency = Round(cmConvertCurrencies(vReservationServicePrice, vReservationServiceCurrency, , vCurFolioCurrency, vCurFolioCurrencyExchangeRate, ?(ValueIsFilled(vCurAccountingDate), vCurAccountingDate, ExchangeRateDate), Hotel), 2);
										Else
											vReservationPriceInFolioCurrency = vReservationServicePrice;
										EndIf;
										vCurPrice = vReservationPriceInFolioCurrency;
									EndIf;
								EndIf;
							EndIf;
							vCurMinQuantity = vPricesRow.MinimumQuantity;
							vCurRemarks = "";
							vIsDayUse = False;
							vOccParams = Undefined;
							// Calculate quantity
							vCurQuantity = cmCalculateServiceQuantity(vCurService, vCurQuantityCalculationRule, 
							                                          vSrvAccountingDate, vCheckInDate, vCheckOutDate, 
							                                          ThisObject, vParentDocObj, vIsCheckIn, vIsBasedOnReservation, 
							                                          vIsBeforeRoomChange, vIsRoomChange, vIsCheckOut, IsOneTimeChargeNecessary, 
							                                          vCurPrice, vCurCurrency, vCurRemarks, vIsDayUse, vCurMinQuantity, vAccommodationPeriods, 
																	  vOccParams);
							If vCRRowWasFound Then
								vSkipPriceUpdate = True;
							EndIf;
							If vSkipPriceUpdate Then
								vCurPrice = vSavCurPrice;
							EndIf;
							vCRRowWasFound = True;
							If vCurCurrency <> vCurFolioCurrency Then
								vCurPriceInFolioCurrency = Round(cmConvertCurrencies(vCurPrice, vCurCurrency, , vCurFolioCurrency, vCurFolioCurrencyExchangeRate, ?(ValueIsFilled(vCurAccountingDate), vCurAccountingDate, ExchangeRateDate), Hotel), 2);
							Else
								vCurPriceInFolioCurrency = vCurPrice;
							EndIf;
							vCurQuantity = vCurQuantity * vPricesRow.Quantity;
							// Take number of persons into account
							vCurSrvQuantity = vCurQuantity;
							If vPricesRow.IsPricePerPerson Then
								vCurQuantity = vCurQuantity * NumberOfPersons;
							EndIf;
							// Fill remarks
							If Not IsBlankString(vPricesRow.Remarks) Then
								vCurRemarks = vPricesRow.Remarks;
							EndIf;
							// Check service package period
							If ValueIsFilled(vPricesRow.ServicePackage) Then
								If BegOfDay(vCheckInDate) < vPricesRow.ServicePackageDateValidFrom Or 
								   ValueIsFilled(vPricesRow.ServicePackageDateValidTo) And BegOfDay(vCheckInDate) > vPricesRow.ServicePackageDateValidTo Then
									Continue;
								EndIf;
								If vCurAccountingDate < vPricesRow.ServicePackageDateFrom Or 
								   ValueIsFilled(vPricesRow.ServicePackageDateTo) And vCurAccountingDate > vPricesRow.ServicePackageDateTo Then
									Continue;
								EndIf;
							EndIf;
							// Process quantity calculation rule parameters
							If ValueIsFilled(vCurQuantityCalculationRule) Then
								// Skip reservation charge if parent document is not reservation
								If Not vIsBasedOnReservation Then
									If vCurQuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.Reservation Then
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
							vSavCurQuantity = vCurQuantity;
							// Process fix reservation conditions flag
							vDoStandartCharging = False;
							If vFixReservationConditions And IsByReservation And ValueIsFilled(Reservation) And vPricesRow.IsInPrice Then
								If vPricesRow.IsRoomRevenue Then
									If (vCurAccountingDate < BegOfDay(vReservationCheckInDate) Or 
								        vCurAccountingDate = BegOfDay(vReservationCheckInDate) And CheckInDate < vReservationCheckInDate Or
								        vCurAccountingDate > BegOfDay(vReservationCheckOutDate) Or
								        vCurAccountingDate = BegOfDay(vReservationCheckOutDate) And CheckOutDate > vReservationCheckOutDate) Then
										If vCurAccountingDate < BegOfDay(vReservationCheckInDate) Or
										   vCurAccountingDate > BegOfDay(vReservationCheckOutDate) Then
											vWrkRoomRate = vRoomRate;
											If ValueIsFilled(vCRRow.ChargingFolio) And ValueIsFilled(vCRRow.ChargingFolio.Customer) And Not vCRRow.ChargingFolio.Customer.IsIndividual Then
												Continue; // Continue to the next charging rule
											EndIf;
											// Add service to the services tabular part if quantity is not zero
											If vCurQuantity > 0 Then
												vWrkNoDiscounts = vNoDiscounts;
												If ValueIsFilled(vRoomRate.RackRate) Then
													vWrkRoomRate = vRoomRate.RackRate;
												Else
													vWrkRoomRate = Hotel.RoomRate;
												EndIf;
												vRackCurrency = vCurCurrency;
												If vWrkRoomRate <> vRoomRate Then
													vPriceCalcDate = CheckOutDate;
													If vCurAccountingDate < BegOfDay(vReservationCheckInDate) Then
														vPriceCalcDate = CheckInDate;
													EndIf;
													vRackPrice = pmGetServiceRatePrice(vWrkRoomRate, vCurAccountingDate, vPriceCalcDate, vPricesRow.Service, vRackCurrency, vRoomType, ?(vCurPriceTag = Undefined, Catalogs.PriceTags.EmptyRef(), vCurPriceTag), vAccommodationType, vMainRoomGuestAccommodationTemplate, vIsForFolioSplitForPrices, vSplitPackagesByGuests);
													If vRackPrice <> 0 Then
														// Apply share percent
														If vCurIsRoomRevenue And vCurIsInPrice Then
															If vIsForFolioSplit And Not IsBlankString(SharePercent) Then
																vRackPrice = cmApplySharePercent(vRackPrice, SharePercent);
															EndIf;
														EndIf;
														If vRackCurrency <> vCurFolioCurrency Then
															vCurPriceInFolioCurrency = Round(cmConvertCurrencies(vRackPrice, vRackCurrency, , vCurFolioCurrency, vCurFolioCurrencyExchangeRate, ?(ValueIsFilled(vCurAccountingDate), vCurAccountingDate, ExchangeRateDate), Hotel), 2);
														Else
															vCurPriceInFolioCurrency = vRackPrice;
														EndIf;
														// If discount type is from the customer then it shouldn't be applied
														If ValueIsFilled(Contract) And ValueIsFilled(Contract.DiscountType) And Contract.DiscountType = DiscountType Then
															vWrkNoDiscounts = True;
														ElsIf ValueIsFilled(Customer) And ValueIsFilled(Customer.DiscountType) And Customer.DiscountType = DiscountType Then
															vWrkNoDiscounts = True;
														ElsIf ValueIsFilled(RoomRate) And ValueIsFilled(RoomRate.DiscountType) And RoomRate.DiscountType = DiscountType Then
															vWrkNoDiscounts = True;
														EndIf;
													Else
														vWrkRoomRate = vRoomRate;
													EndIf;
												EndIf;
												AddService(i, vCurFolio, vCurFolioCurrency, vCurFolioCurrencyExchangeRate, vSrvAccountingDate,
												           vCurService, vCurPriceInFolioCurrency, vCurUnit, vCurQuantity, vCurVATRate, vCurRemarks, 
												           vCurIsRoomRevenue, vCurIsInPrice, vCurIsSplit, vCurRoomRevenueAmountsOnly, vCurCalendarDayType, vCurTimetable, vCurPriceTag, vCurQuantityCalculationRule,
												           vCurSrvQuantity, vFirstDayWithAccommodationService, vIsCheckIn, vIsRoomChange, vIsCheckOut, 
												           vFixedDiscount, vFixedServiceDiscount, vPeriodDiscount, vPeriodDiscountType, vPeriodDiscountServiceGroup, vPeriodDiscountConfirmationText, 
												           vAccDiscounts, vMCServices, vNoAccommodationService, vWrkRoomRate, vAccommodationType, vRoom, vRoomRoomType, vWrkNoDiscounts, 
														   vRoomRevenuePriceByRoomType, vRestOfCurPrice, vRestOfCurAmount, vChargingRuleAmountIsSet, vRestOfServiceSum, 
														   vRoomRates, True, vCRTab, vComplexCommission, vPricesRow.PacketPriceIsIncludedInRoomRate, vCurRoomRateSrv, vCurRestOfRoomRateSrv, rWarnings, vOccParams, 
														   vCurServicePackageUsageType, vCurServicePackage, vMealBoardTermIncluded, vMealBoardTermIncludedServices, vContractMealBoardTerms, vReservationDate, vMainRoomGuestAccommodationTemplate, 
														   vCurNumberOfPersons, vCurNumberOfRooms, vCurNumberOfBeds, vCurNumberOfAdditionalBeds,
														   vCurRoomRateSrvHasManualPrice, vIsManualPrice, vPriceCalcDate, vOffers, vIsForFolioSplit, vDoNotRoundPrice, vCurAccommodationType, vIsForFolioSplitForPrices, vSplitPackagesByGuests, vIsManualServices, 
														   vClientType, vSourceOfBusiness, vMarketingCode, vBoardPlace, vCalendarDayTypeIsChanged, vOfferByRoomTypeUpgradeDescription, vOfferByTermsUpgradeDescription, vRateService, vGuestsCheckedInIsSet);
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
										ElsIf vCurAccountingDate = BegOfDay(vReservationCheckInDate) And 
										      BegOfDay(CheckInDate) = BegOfDay(vReservationCheckInDate) And
										      CheckInDate < vReservationCheckInDate Then
											If Not vEarlyCheckInIsCharged Then
												vEarlyCheckInIsCharged = True;
												// Add service with early check-in based on reservation period
												vWrkPrice = vCurPriceInFolioCurrency;
												vWrkAccountingDate = vDayRow.Period;
												vEarlyCheckInQuantity = cmCalculateServiceQuantity(vCurService, vCurQuantityCalculationRule, 
												                                                   vWrkAccountingDate, vReservationCheckInDate, vReservationCheckOutDate, 
												                                                   ThisObject, vParentDocObj, vIsCheckIn, vIsBasedOnReservation, 
												                                                   vIsBeforeRoomChange, vIsRoomChange, vIsCheckOut, IsOneTimeChargeNecessary, 
												                                                   vWrkPrice, vCurCurrency, vCurRemarks, vIsDayUse);
												vWrkPrice = vCurPriceInFolioCurrency;
												vEarlyCheckInQuantity = vEarlyCheckInQuantity * vPricesRow.Quantity;
												// Take number of persons into account
												vEarlyCheckInSrvQuantity = vEarlyCheckInQuantity;
												If vPricesRow.IsPricePerPerson Then
													vEarlyCheckInQuantity = vEarlyCheckInQuantity * NumberOfPersons;
												EndIf;
												If vEarlyCheckInQuantity > 0 Then
													If Not (vThereAreCustomerChargingRules And (vReservationRoomType <> vRoomType Or vReservationAccommodationType <> vAccommodationType)) Then
														AddService(i, vCurFolio, vCurFolioCurrency, vCurFolioCurrencyExchangeRate, vSrvAccountingDate,
														           vCurService, vWrkPrice, vCurUnit, vEarlyCheckInQuantity, vCurVATRate, vCurRemarks, 
														           vCurIsRoomRevenue, vCurIsInPrice, False, vCurRoomRevenueAmountsOnly, vCurCalendarDayType, vCurTimetable, vCurPriceTag, vCurQuantityCalculationRule,
														           vEarlyCheckInSrvQuantity, vFirstDayWithAccommodationService, vIsCheckIn, vIsRoomChange, vIsCheckOut, 
														           vFixedDiscount, vFixedServiceDiscount, vPeriodDiscount, vPeriodDiscountType, vPeriodDiscountServiceGroup, vPeriodDiscountConfirmationText, 
														           vAccDiscounts, vMCServices, vNoAccommodationService, vRoomRate, vAccommodationType, vRoom, vRoomRoomType, vNoDiscounts, 
																   vRoomRevenuePriceByRoomType, vRestOfCurPrice, vRestOfCurAmount, vChargingRuleAmountIsSet, vRestOfServiceSum, 
																   vRoomRates, , vCRTab, vComplexCommission, vPricesRow.PacketPriceIsIncludedInRoomRate, vCurRoomRateSrv, vCurRestOfRoomRateSrv, rWarnings, , 
																   vCurServicePackageUsageType, vCurServicePackage, vMealBoardTermIncluded, vMealBoardTermIncludedServices, vContractMealBoardTerms, vReservationDate, vMainRoomGuestAccommodationTemplate, 
																   vCurNumberOfPersons, vCurNumberOfRooms, vCurNumberOfBeds, vCurNumberOfAdditionalBeds, 
																   vCurRoomRateSrvHasManualPrice, vIsManualPrice, vPriceCalcDate, vOffers, vIsForFolioSplit, vDoNotRoundPrice, vCurAccommodationType, vIsForFolioSplitForPrices, vSplitPackagesByGuests, vIsManualServices, 
																   vClientType, vSourceOfBusiness, vMarketingCode, vBoardPlace, vCalendarDayTypeIsChanged, vOfferByRoomTypeUpgradeDescription, vOfferByTermsUpgradeDescription, vRateService, vGuestsCheckedInIsSet);
													EndIf;
												EndIf;
											EndIf;
											If Not ValueIsFilled(vCurFolio.Customer) Or ValueIsFilled(vCurFolio.Customer) And vCurFolio.Customer.IsIndividual And 
											   Not vSplitChargesToPersonalFolioForIndividualCustomers Then
												// Add service to the services tabular part if quantity is not zero
												vWrkRoomRate = vRoomRate;
												vCurQuantity = vCurQuantity - vEarlyCheckInQuantity;
												vCurSrvQuantity = vCurSrvQuantity - vEarlyCheckInSrvQuantity;
												If vCurQuantity > 0 Then
													vWrkNoDiscounts = vNoDiscounts;
													If ValueIsFilled(vRoomRate.RackRate) Then
														vWrkRoomRate = vRoomRate.RackRate;
													Else
														vWrkRoomRate = Hotel.RoomRate;
													EndIf;
													vWrkPrice = vCurPriceInFolioCurrency;
													vRackCurrency = vCurCurrency;
													vRackPrice = pmGetServiceRatePrice(vWrkRoomRate, vCurAccountingDate, CheckInDate, vPricesRow.Service, vRackCurrency, vRoomType, ?(vCurPriceTag = Undefined, Catalogs.PriceTags.EmptyRef(), vCurPriceTag), vAccommodationType, vMainRoomGuestAccommodationTemplate, vIsForFolioSplitForPrices, vSplitPackagesByGuests);
													If vRackPrice <> 0 Then
														// Apply share percent
														If vCurIsRoomRevenue And vCurIsInPrice Then
															If vIsForFolioSplit And Not IsBlankString(SharePercent) Then
																vRackPrice = cmApplySharePercent(vRackPrice, SharePercent);
															EndIf;
														EndIf;
														If vRackCurrency <> vCurFolioCurrency Then
															vWrkPrice = Round(cmConvertCurrencies(vRackPrice, vRackCurrency, , vCurFolioCurrency, vCurFolioCurrencyExchangeRate, ?(ValueIsFilled(vCurAccountingDate), vCurAccountingDate, ExchangeRateDate), Hotel), 2);
														Else
															vWrkPrice = vRackPrice;
														EndIf;
														// If discount type is from the customer then it shouldn't be applied
														If ValueIsFilled(Contract) And ValueIsFilled(Contract.DiscountType) And Contract.DiscountType = DiscountType Then
															vWrkNoDiscounts = True;
														ElsIf ValueIsFilled(Customer) And ValueIsFilled(Customer.DiscountType) And Customer.DiscountType = DiscountType Then
															vWrkNoDiscounts = True;
														ElsIf ValueIsFilled(RoomRate) And ValueIsFilled(RoomRate.DiscountType) And RoomRate.DiscountType = DiscountType Then
															vWrkNoDiscounts = True;
														EndIf;
													Else
														vWrkRoomRate = vRoomRate;
													EndIf;
													vWrkRemarks = vCurRemarks;
													vWrkIsInPrice = vCurIsInPrice;
													If vEarlyCheckInSrvQuantity <> 0 Then
														vWrkIsInPrice = False;
														vWrkRemarks = NStr("ru='Доп. начисление " + Round(vCurSrvQuantity*24, 0) + " часов';en='Add. charge " + Round(vCurSrvQuantity*24, 0) + " hours';de='Aufpreis " + Round(vCurSrvQuantity*24, 0) + " Stunden'");
													EndIf;
													AddService(i, vCurFolio, vCurFolioCurrency, vCurFolioCurrencyExchangeRate, vSrvAccountingDate,
													           vCurService, vWrkPrice, vCurUnit, vCurQuantity, vCurVATRate, vWrkRemarks, 
													           vCurIsRoomRevenue, vWrkIsInPrice, False, vCurRoomRevenueAmountsOnly, vCurCalendarDayType, vCurTimetable, vCurPriceTag, vCurQuantityCalculationRule,
													           vCurSrvQuantity, vFirstDayWithAccommodationService, vIsCheckIn, vIsRoomChange, vIsCheckOut, 
													           vFixedDiscount, vFixedServiceDiscount, vPeriodDiscount, vPeriodDiscountType, vPeriodDiscountServiceGroup, vPeriodDiscountConfirmationText, 
													           vAccDiscounts, vMCServices, vNoAccommodationService, vWrkRoomRate, vAccommodationType, vRoom, vRoomRoomType, vWrkNoDiscounts, 
															   vRoomRevenuePriceByRoomType, vRestOfCurPrice, vRestOfCurAmount, vChargingRuleAmountIsSet, vRestOfServiceSum, 
															   vRoomRates, True, vCRTab, vComplexCommission, vPricesRow.PacketPriceIsIncludedInRoomRate, vCurRoomRateSrv, vCurRestOfRoomRateSrv, rWarnings, , 
															   vCurServicePackageUsageType, vCurServicePackage, vMealBoardTermIncluded, vMealBoardTermIncludedServices, vContractMealBoardTerms, vReservationDate, vMainRoomGuestAccommodationTemplate, 
															   vCurNumberOfPersons, vCurNumberOfRooms, vCurNumberOfBeds, vCurNumberOfAdditionalBeds, 
															   vCurRoomRateSrvHasManualPrice, vIsManualPrice, vPriceCalcDate, vOffers, vIsForFolioSplit, vDoNotRoundPrice, vCurAccommodationType, vIsForFolioSplitForPrices, vSplitPackagesByGuests, vIsManualServices, 
															   vClientType, vSourceOfBusiness, vMarketingCode, vBoardPlace, vCalendarDayTypeIsChanged, vOfferByRoomTypeUpgradeDescription, vOfferByTermsUpgradeDescription, vRateService, vGuestsCheckedInIsSet);
													// We've found suitable charging rule so move to the other service
													If Not (vThereAreCustomerChargingRules And (vReservationRoomType <> vRoomType Or vReservationAccommodationType <> vAccommodationType)) Then
														Break;
													EndIf;
												EndIf;
											EndIf;
										ElsIf vCurAccountingDate = BegOfDay(vReservationCheckOutDate) And 
										      BegOfDay(CheckOutDate) = BegOfDay(vReservationCheckOutDate) And
										      CheckOutDate > vReservationCheckOutDate Then
											If Not vLateCheckOutIsCharged Then
												vLateCheckOutIsCharged = True;
												// Add service with late check-out based on reservation period
												vWrkPrice = vCurPriceInFolioCurrency;
												vWrkAccountingDate = vDayRow.Period;
												vLateCheckOutQuantity = cmCalculateServiceQuantity(vCurService, vCurQuantityCalculationRule, 
												                                                   vWrkAccountingDate, vReservationCheckInDate, vReservationCheckOutDate, 
												                                                   ThisObject, vParentDocObj, vIsCheckIn, vIsBasedOnReservation, 
												                                                   vIsBeforeRoomChange, vIsRoomChange, vIsCheckOut, IsOneTimeChargeNecessary, 
												                                                   vWrkPrice, vCurCurrency, vCurRemarks, vIsDayUse);
												vWrkPrice = vCurPriceInFolioCurrency;
												vLateCheckOutQuantity = vLateCheckOutQuantity * vPricesRow.Quantity;
												// Take number of persons into account
												vLateCheckOutSrvQuantity = vLateCheckOutQuantity;
												If vPricesRow.IsPricePerPerson Then
													vLateCheckOutQuantity = vLateCheckOutQuantity * NumberOfPersons;
												EndIf;
												If vLateCheckOutQuantity > 0 Then
													If Not (vThereAreCustomerChargingRules And (vReservationRoomType <> vRoomType Or vReservationAccommodationType <> vAccommodationType)) Then
														AddService(i, vCurFolio, vCurFolioCurrency, vCurFolioCurrencyExchangeRate, vSrvAccountingDate,
														           vCurService, vWrkPrice, vCurUnit, vLateCheckOutQuantity, vCurVATRate, vCurRemarks, 
														           vCurIsRoomRevenue, vCurIsInPrice, False, vCurRoomRevenueAmountsOnly, vCurCalendarDayType, vCurTimetable, vCurPriceTag, vCurQuantityCalculationRule,
														           vCurSrvQuantity, vFirstDayWithAccommodationService, vIsCheckIn, vIsRoomChange, vIsCheckOut, 
														           vFixedDiscount, vFixedServiceDiscount, vPeriodDiscount, vPeriodDiscountType, vPeriodDiscountServiceGroup, vPeriodDiscountConfirmationText, 
														           vAccDiscounts, vMCServices, vNoAccommodationService, vRoomRate, vAccommodationType, vRoom, vRoomRoomType, vNoDiscounts, 
																   vRoomRevenuePriceByRoomType, vRestOfCurPrice, vRestOfCurAmount, vChargingRuleAmountIsSet, vRestOfServiceSum, 
																   vRoomRates, , vCRTab, vComplexCommission, vPricesRow.PacketPriceIsIncludedInRoomRate, vCurRoomRateSrv, vCurRestOfRoomRateSrv, rWarnings, , 
																   vCurServicePackageUsageType, vCurServicePackage, vMealBoardTermIncluded, vMealBoardTermIncludedServices, vContractMealBoardTerms, vReservationDate, vMainRoomGuestAccommodationTemplate, 
																   vCurNumberOfPersons, vCurNumberOfRooms, vCurNumberOfBeds, vCurNumberOfAdditionalBeds, 
																   vCurRoomRateSrvHasManualPrice, vIsManualPrice, vPriceCalcDate, vOffers, vIsForFolioSplit, vDoNotRoundPrice, vCurAccommodationType, vIsForFolioSplitForPrices, vSplitPackagesByGuests, vIsManualServices, 
																   vClientType, vSourceOfBusiness, vMarketingCode, vBoardPlace, vCalendarDayTypeIsChanged, vOfferByRoomTypeUpgradeDescription, vOfferByTermsUpgradeDescription, vRateService, vGuestsCheckedInIsSet);
													EndIf;
												EndIf;
											EndIf;
											If Not ValueIsFilled(vCurFolio.Customer) Or ValueIsFilled(vCurFolio.Customer) And vCurFolio.Customer.IsIndividual And 
											   Not vSplitChargesToPersonalFolioForIndividualCustomers Then
												// Add service to the services tabular part if quantity is not zero
												vWrkRoomRate = vRoomRate;
												vCurQuantity = vCurQuantity - vLateCheckOutQuantity;
												vCurSrvQuantity = vCurSrvQuantity - vLateCheckOutSrvQuantity;
												If vCurQuantity > 0 Then
													vWrkNoDiscounts = vNoDiscounts;
													If ValueIsFilled(vRoomRate.RackRate) Then
														vWrkRoomRate = vRoomRate.RackRate;
													Else
														vWrkRoomRate = Hotel.RoomRate;
													EndIf;
													vWrkPrice = vCurPriceInFolioCurrency;
													vRackCurrency = vCurCurrency;
													vRackPrice = pmGetServiceRatePrice(vWrkRoomRate, vCurAccountingDate, CheckOutDate, vPricesRow.Service, vRackCurrency, vRoomType, ?(vCurPriceTag = Undefined, Catalogs.PriceTags.EmptyRef(), vCurPriceTag), vAccommodationType, vMainRoomGuestAccommodationTemplate, vIsForFolioSplitForPrices, vSplitPackagesByGuests);
													If vRackPrice <> 0 Then
														// Apply share percent
														If vCurIsRoomRevenue And vCurIsInPrice Then
															If vIsForFolioSplit And Not IsBlankString(SharePercent) Then
																vRackPrice = cmApplySharePercent(vRackPrice, SharePercent);
															EndIf;
														EndIf;
														If vRackCurrency <> vCurFolioCurrency Then
															vWrkPrice = Round(cmConvertCurrencies(vRackPrice, vRackCurrency, , vCurFolioCurrency, vCurFolioCurrencyExchangeRate, ?(ValueIsFilled(vCurAccountingDate), vCurAccountingDate, ExchangeRateDate), Hotel), 2);
														Else
															vWrkPrice = vRackPrice;
														EndIf;
														// If discount type is from the customer then it shouldn't be applied
														If ValueIsFilled(Contract) And ValueIsFilled(Contract.DiscountType) And Contract.DiscountType = DiscountType Then
															vWrkNoDiscounts = True;
														ElsIf ValueIsFilled(Customer) And ValueIsFilled(Customer.DiscountType) And Customer.DiscountType = DiscountType Then
															vWrkNoDiscounts = True;
														ElsIf ValueIsFilled(RoomRate) And ValueIsFilled(RoomRate.DiscountType) And RoomRate.DiscountType = DiscountType Then
															vWrkNoDiscounts = True;
														EndIf;
													Else
														vWrkRoomRate = vRoomRate;
													EndIf;
													vWrkRemarks = vCurRemarks;
													vWrkIsInPrice = vCurIsInPrice;
													If vLateCheckOutSrvQuantity <> 0 Then
														vWrkIsInPrice = False;
														vWrkRemarks = NStr("ru='Доп. начисление " + Round(vCurSrvQuantity*24, 0) + " часов';en='Add. charge " + Round(vCurSrvQuantity*24, 0) + " hours';de='Aufpreis " + Round(vCurSrvQuantity*24, 0) + " Stunden'");
													EndIf;
													AddService(i, vCurFolio, vCurFolioCurrency, vCurFolioCurrencyExchangeRate, vSrvAccountingDate,
													           vCurService, vWrkPrice, vCurUnit, vCurQuantity, vCurVATRate, vWrkRemarks, 
													           vCurIsRoomRevenue, vWrkIsInPrice, False, vCurRoomRevenueAmountsOnly, vCurCalendarDayType, vCurTimetable, vCurPriceTag, vCurQuantityCalculationRule,
													           vCurSrvQuantity, vFirstDayWithAccommodationService, vIsCheckIn, vIsRoomChange, vIsCheckOut, 
													           vFixedDiscount, vFixedServiceDiscount, vPeriodDiscount, vPeriodDiscountType, vPeriodDiscountServiceGroup, vPeriodDiscountConfirmationText, 
													           vAccDiscounts, vMCServices, vNoAccommodationService, vWrkRoomRate, vAccommodationtype, vRoom, vRoomRoomType, vWrkNoDiscounts, 
															   vRoomRevenuePriceByRoomType, vRestOfCurPrice, vRestOfCurAmount, vChargingRuleAmountIsSet, vRestOfServiceSum, 
															   vRoomRates, True, vCRTab, vComplexCommission, vPricesRow.PacketPriceIsIncludedInRoomRate, vCurRoomRateSrv, vCurRestOfRoomRateSrv, rWarnings, , 
															   vCurServicePackageUsageType, vCurServicePackage, vMealBoardTermIncluded, vMealBoardTermIncludedServices, vContractMealBoardTerms, vReservationDate, vMainRoomGuestAccommodationTemplate, 
															   vCurNumberOfPersons, vCurNumberOfRooms, vCurNumberOfBeds, vCurNumberOfAdditionalBeds, 
															   vCurRoomRateSrvHasManualPrice, vIsManualPrice, vPriceCalcDate, vOffers, vIsForFolioSplit, vDoNotRoundPrice, vCurAccommodationType, vIsForFolioSplitForPrices, vSplitPackagesByGuests, vIsManualServices, 
															   vClientType, vSourceOfBusiness, vMarketingCode, vBoardPlace, vCalendarDayTypeIsChanged, vOfferByRoomTypeUpgradeDescription, vOfferByTermsUpgradeDescription, vRateService, vGuestsCheckedInIsSet);
													// We've found suitable charging rule so move to the other service
													If Not (vThereAreCustomerChargingRules And (vReservationRoomType <> vRoomType Or vReservationAccommodationType <> vAccommodationType)) Then
														Break;
													EndIf;
												EndIf;
											EndIf;
										Else
											vDoStandartCharging = True;
											If vCurAccountingDate < BegOfDay(vReservationCheckInDate) Or
											   vCurAccountingDate >= BegOfDay(vReservationCheckOutDate) Then
												If ValueIsFilled(vCRRow.ChargingFolio) And ValueIsFilled(vCRRow.ChargingFolio.Customer) And Not vCRRow.ChargingFolio.Customer.IsIndividual Then
													Continue; // Continue to the next charging rule
												EndIf;
											EndIf;
										EndIf;
									// Check if there are customer folios
									ElsIf vThereAreCustomerChargingRules And 
									     (vReservationRoomType <> vRoomType Or vReservationAccommodationType <> vAccommodationType) And 
										 (vCurAccountingDate >= BegOfDay(vReservationCheckInDate) Or vCurAccountingDate < BegOfDay(vReservationCheckOutDate)) Then
										If vCurQuantity <> 0 Then
											If ValueIsFilled(vCurFolio.Customer) And Not vCurFolio.Customer.IsIndividual Then
												If Not vReservationServiceWasCharged Then
													// Get reservation price
													vReservationServiceCurrency = vCurFolioCurrency;
													vReservationServicePrice = pmGetServiceRatePrice(vReservationRoomRate, vSrvAccountingDate, vReservationPriceCalculationDate, vPricesRow.Service, vReservationServiceCurrency, vReservationRoomType, ?(vCurPriceTag = Undefined, Catalogs.PriceTags.EmptyRef(), vCurPriceTag), vReservationAccommodationType, vReservationAccommodationTemplate, vIsForFolioSplitForPrices, vSplitPackagesByGuests, vServicePackagesList, vReservationCheckInDate, vReservationCheckOutDate, vReservationPricesCache);
													If vReservationServiceCurrency <> vCurFolioCurrency Then
														vReservationPriceInFolioCurrency = Round(cmConvertCurrencies(vReservationServicePrice, vReservationServiceCurrency, , vCurFolioCurrency, vCurFolioCurrencyExchangeRate, ?(ValueIsFilled(vCurAccountingDate), vCurAccountingDate, ExchangeRateDate), Hotel), 2);
													Else
														vReservationPriceInFolioCurrency = vReservationServicePrice;
													EndIf;
													AddService(i, vCurFolio, vCurFolioCurrency, vCurFolioCurrencyExchangeRate, vSrvAccountingDate,
													           vCurService, vReservationPriceInFolioCurrency, vCurUnit, vCurQuantity, vCurVATRate, vCurRemarks, 
													           vCurIsRoomRevenue, vCurIsInPrice, vCurIsSplit, vCurRoomRevenueAmountsOnly, vCurCalendarDayType, vCurTimetable, vCurPriceTag, vCurQuantityCalculationRule,
													           vCurSrvQuantity, vFirstDayWithAccommodationService, vIsCheckIn, vIsRoomChange, vIsCheckOut, 
													           vFixedDiscount, vFixedServiceDiscount, vPeriodDiscount, vPeriodDiscountType, vPeriodDiscountServiceGroup, vPeriodDiscountConfirmationText, 
													           vAccDiscounts, vMCServices, vNoAccommodationService, vRoomRate, vAccommodationType, vRoom, vRoomRoomType, vNoDiscounts, 
															   vRoomRevenuePriceByRoomType, vRestOfCurPrice, vRestOfCurAmount, vChargingRuleAmountIsSet, vRestOfServiceSum, 
															   vRoomRates, , vCRTab, vComplexCommission, vPricesRow.PacketPriceIsIncludedInRoomRate, vCurRoomRateSrv, vCurRestOfRoomRateSrv, rWarnings, vOccParams, 
															   vCurServicePackageUsageType, vCurServicePackage, vMealBoardTermIncluded, vMealBoardTermIncludedServices, vContractMealBoardTerms, vReservationDate, vMainRoomGuestAccommodationTemplate, 
															   vCurNumberOfPersons, vCurNumberOfRooms, vCurNumberOfBeds, vCurNumberOfAdditionalBeds, 
															   vCurRoomRateSrvHasManualPrice, vIsManualPrice, vPriceCalcDate, vOffers, vIsForFolioSplit, vDoNotRoundPrice, vCurAccommodationType, vIsForFolioSplitForPrices, vSplitPackagesByGuests, vIsManualServices, 
															   vClientType, vSourceOfBusiness, vMarketingCode, vBoardPlace, vCalendarDayTypeIsChanged, vOfferByRoomTypeUpgradeDescription, vOfferByTermsUpgradeDescription, vRateService, vGuestsCheckedInIsSet);
													vReservationServiceWasCharged = True;
												EndIf;
											ElsIf (vSplitChargesToPersonalFolioForIndividualCustomers Or vReservationServiceWasCharged) Then
												If Not vReservationServiceWasCharged Then
													// Get reservation price
													vReservationServiceCurrency = vCurFolioCurrency;
													vReservationServicePrice = pmGetServiceRatePrice(vReservationRoomRate, vSrvAccountingDate, vReservationPriceCalculationDate, vPricesRow.Service, vReservationServiceCurrency, vReservationRoomType, ?(vCurPriceTag = Undefined, Catalogs.PriceTags.EmptyRef(), vCurPriceTag), vReservationAccommodationType, vReservationAccommodationTemplate, vIsForFolioSplitForPrices, vSplitPackagesByGuests, vServicePackagesList, vReservationCheckInDate, vReservationCheckOutDate, vReservationPricesCache);
													If vReservationServiceCurrency <> vCurFolioCurrency Then
														vReservationPriceInFolioCurrency = Round(cmConvertCurrencies(vReservationServicePrice, vReservationServiceCurrency, , vCurFolioCurrency, vCurFolioCurrencyExchangeRate, ?(ValueIsFilled(vCurAccountingDate), vCurAccountingDate, ExchangeRateDate), Hotel), 2);
													Else
														vReservationPriceInFolioCurrency = vReservationServicePrice;
													EndIf;
													AddService(i, vCurFolio, vCurFolioCurrency, vCurFolioCurrencyExchangeRate, vSrvAccountingDate,
													           vCurService, vReservationPriceInFolioCurrency, vCurUnit, vCurQuantity, vCurVATRate, vCurRemarks, 
													           vCurIsRoomRevenue, vCurIsInPrice, vCurIsSplit, vCurRoomRevenueAmountsOnly, vCurCalendarDayType, vCurTimetable, vCurPriceTag, vCurQuantityCalculationRule,
													           vCurSrvQuantity, vFirstDayWithAccommodationService, vIsCheckIn, vIsRoomChange, vIsCheckOut, 
													           vFixedDiscount, vFixedServiceDiscount, vPeriodDiscount, vPeriodDiscountType, vPeriodDiscountServiceGroup, vPeriodDiscountConfirmationText, 
													           vAccDiscounts, vMCServices, vNoAccommodationService, vRoomRate, vAccommodationType, vRoom, vRoomRoomType, vNoDiscounts, 
															   vRoomRevenuePriceByRoomType, vRestOfCurPrice, vRestOfCurAmount, vChargingRuleAmountIsSet, vRestOfServiceSum, 
															   vRoomRates, , vCRTab, vComplexCommission, vPricesRow.PacketPriceIsIncludedInRoomRate, vCurRoomRateSrv, vCurRestOfRoomRateSrv, rWarnings, vOccParams, 
															   vCurServicePackageUsageType, vCurServicePackage, vMealBoardTermIncluded, vMealBoardTermIncludedServices, vContractMealBoardTerms, vReservationDate, vMainRoomGuestAccommodationTemplate, 
															   vCurNumberOfPersons, vCurNumberOfRooms, vCurNumberOfBeds, vCurNumberOfAdditionalBeds, 
															   vCurRoomRateSrvHasManualPrice, vIsManualPrice, vPriceCalcDate, vOffers, vIsForFolioSplit, vDoNotRoundPrice, vCurAccommodationType, vIsForFolioSplitForPrices, vSplitPackagesByGuests, vIsManualServices, 
															   vClientType, vSourceOfBusiness, vMarketingCode, vBoardPlace, vCalendarDayTypeIsChanged, vOfferByRoomTypeUpgradeDescription, vOfferByTermsUpgradeDescription, vRateService, vGuestsCheckedInIsSet);
													vReservationServiceWasCharged = True;
												EndIf;
												// Charge difference between rack prices 
												vWrkNoDiscounts = vNoDiscounts;
												vWrkRoomRate = vRoomRate;
												If ValueIsFilled(vRoomRate.RackRate) Then
													vWrkRoomRate = vRoomRate.RackRate;
												Else
													vWrkRoomRate = Hotel.RoomRate;
												EndIf;
												vWrkPrice = vCurPriceInFolioCurrency;
												vRackCurrency = vCurCurrency;
												vRackPrice = pmGetServiceRatePrice(vWrkRoomRate, vCurAccountingDate, CheckInDate, vPricesRow.Service, vRackCurrency, vRoomType, ?(vCurPriceTag = Undefined, Catalogs.PriceTags.EmptyRef(), vCurPriceTag), vAccommodationType, vMainRoomGuestAccommodationTemplate, vIsForFolioSplitForPrices, vSplitPackagesByGuests, vServicePackagesList);
												If vRackPrice <> 0 Then
													// Apply share percent
													If vCurIsRoomRevenue And vCurIsInPrice Then
														If vIsForFolioSplit And Not IsBlankString(SharePercent) Then
															vRackPrice = cmApplySharePercent(vRackPrice, SharePercent);
														EndIf;
													EndIf;
													If vRackCurrency <> vCurCurrency Then
														vRackPrice = Round(cmConvertCurrencies(vRackPrice, vRackCurrency, , vCurCurrency, vCurFolioCurrencyExchangeRate, ?(ValueIsFilled(vCurAccountingDate), vCurAccountingDate, ExchangeRateDate), Hotel), 2);
													EndIf;
													// Get price from rack rate for reservation room type
													vReservationRackCurrency = vRackCurrency;
													vReservationRackPrice = pmGetServiceRatePrice(vWrkRoomRate, vCurAccountingDate, CheckInDate, vPricesRow.Service, vReservationRackCurrency, vReservationRoomType, ?(vCurPriceTag = Undefined, Catalogs.PriceTags.EmptyRef(), vCurPriceTag), vReservationAccommodationType, vReservationAccommodationTemplate, vIsForFolioSplitForPrices, vSplitPackagesByGuests, vServicePackagesList);
													If vReservationRackPrice <> 0 Then
														// Apply share percent
														If vCurIsRoomRevenue And vCurIsInPrice Then
															If vIsForFolioSplit And ValueIsFilled(Reservation) And Not IsBlankString(Reservation.SharePercent) Then
																vReservationRackPrice = cmApplySharePercent(vReservationRackPrice, Reservation.SharePercent);
															EndIf;
														EndIf;
														If vReservationRackCurrency <> vCurCurrency Then
															vReservationRackPrice = Round(cmConvertCurrencies(vReservationRackPrice, vReservationRackCurrency, , vCurCurrency, vCurFolioCurrencyExchangeRate, ?(ValueIsFilled(vCurAccountingDate), vCurAccountingDate, ExchangeRateDate), Hotel), 2);
														EndIf;
														vWrkPrice = vRackPrice - vReservationRackPrice;
														If vWrkPrice > 0 Then
															// If discount type is from the customer then it shouldn't be applied
															If ValueIsFilled(Contract) And ValueIsFilled(Contract.DiscountType) And Contract.DiscountType = DiscountType Then
																vWrkNoDiscounts = True;
															ElsIf ValueIsFilled(Customer) And ValueIsFilled(Customer.DiscountType) And Customer.DiscountType = DiscountType Then
																vWrkNoDiscounts = True;
															ElsIf ValueIsFilled(RoomRate) And ValueIsFilled(RoomRate.DiscountType) And RoomRate.DiscountType = DiscountType Then
																vWrkNoDiscounts = True;
															EndIf;
															AddService(i, vCurFolio, vCurFolioCurrency, vCurFolioCurrencyExchangeRate, vSrvAccountingDate,
																	   vCurService, vWrkPrice, vCurUnit, vCurQuantity, vCurVATRate, vCurRemarks, 
																	   vCurIsRoomRevenue, vCurIsInPrice, True, True, vCurCalendarDayType, vCurTimetable, vCurPriceTag, vCurQuantityCalculationRule,
																	   vCurSrvQuantity, vFirstDayWithAccommodationService, vIsCheckIn, vIsRoomChange, vIsCheckOut, 
																	   vFixedDiscount, vFixedServiceDiscount, vPeriodDiscount, vPeriodDiscountType, vPeriodDiscountServiceGroup, vPeriodDiscountConfirmationText, 
																	   vAccDiscounts, vMCServices, vNoAccommodationService, vWrkRoomRate, vAccommodationtype, vRoom, vRoomRoomType, vWrkNoDiscounts, 
																	   vRoomRevenuePriceByRoomType, vRestOfCurPrice, vRestOfCurAmount, vChargingRuleAmountIsSet, vRestOfServiceSum, 
																	   vRoomRates, True, vCRTab, vComplexCommission, vPricesRow.PacketPriceIsIncludedInRoomRate, vCurRoomRateSrv, vCurRestOfRoomRateSrv, rWarnings, vOccParams, 
																	   vCurServicePackageUsageType, vCurServicePackage, vMealBoardTermIncluded, vMealBoardTermIncludedServices, vContractMealBoardTerms, vReservationDate, vMainRoomGuestAccommodationTemplate, 
																	   vCurNumberOfPersons, vCurNumberOfRooms, vCurNumberOfBeds, vCurNumberOfAdditionalBeds, 
																	   vCurRoomRateSrvHasManualPrice, vIsManualPrice, vPriceCalcDate, vOffers, vIsForFolioSplit, vDoNotRoundPrice, vCurAccommodationType, vIsForFolioSplitForPrices, vSplitPackagesByGuests, vIsManualServices, 
																	   vClientType, vSourceOfBusiness, vMarketingCode, vBoardPlace, vCalendarDayTypeIsChanged, vOfferByRoomTypeUpgradeDescription, vOfferByTermsUpgradeDescription, vRateService, vGuestsCheckedInIsSet);
														EndIf;
													EndIf;
												Else
													vWrkRoomRate = vRoomRate;
												EndIf;
												// We've found suitable charging rule so move to the other service
												Break;
											Else
												vDoStandartCharging = True;
											EndIf;
										EndIf;
									Else
										vDoStandartCharging = True;
									EndIf;
								Else
									vDoStandartCharging = True;
									If vCurAccountingDate < BegOfDay(vReservationCheckInDate) Or
									   vCurAccountingDate >= BegOfDay(vReservationCheckOutDate) Then
										If ValueIsFilled(vCRRow.ChargingFolio) And ValueIsFilled(vCRRow.ChargingFolio.Customer) And Not vCRRow.ChargingFolio.Customer.IsIndividual Then
											Continue; // Continue to the next charging rule
										EndIf;
									EndIf;
								EndIf;
							Else
								vDoStandartCharging = True;
							EndIf;
							// Add service to the services tabular part if quantity is not zero
							If vDoStandartCharging Then
 								If vCurQuantity <> 0 Then
									vSavI = i;
									AddService(i, vCurFolio, vCurFolioCurrency, vCurFolioCurrencyExchangeRate, vSrvAccountingDate,
									           vCurService, vCurPriceInFolioCurrency, vCurUnit, vCurQuantity, vCurVATRate, vCurRemarks, 
									           vCurIsRoomRevenue, vCurIsInPrice, vCurIsSplit, vCurRoomRevenueAmountsOnly, vCurCalendarDayType, vCurTimetable, vCurPriceTag, vCurQuantityCalculationRule,
									           vCurSrvQuantity, vFirstDayWithAccommodationService, vIsCheckIn, vIsRoomChange, vIsCheckOut, 
									           vFixedDiscount, vFixedServiceDiscount, vPeriodDiscount, vPeriodDiscountType, vPeriodDiscountServiceGroup, vPeriodDiscountConfirmationText, 
									           vAccDiscounts, vMCServices, vNoAccommodationService, vRoomRate, vAccommodationType, vRoom, vRoomRoomType, vNoDiscounts, 
											   vRoomRevenuePriceByRoomType, vRestOfCurPrice, vRestOfCurAmount, vChargingRuleAmountIsSet, vRestOfServiceSum, 
											   vRoomRates, , vCRTab, vComplexCommission, vPricesRow.PacketPriceIsIncludedInRoomRate, vCurRoomRateSrv, vCurRestOfRoomRateSrv, rWarnings, vOccParams, 
											   vCurServicePackageUsageType, vCurServicePackage, vMealBoardTermIncluded, vMealBoardTermIncludedServices, vContractMealBoardTerms, vReservationDate, vMainRoomGuestAccommodationTemplate, 
											   vCurNumberOfPersons, vCurNumberOfRooms, vCurNumberOfBeds, vCurNumberOfAdditionalBeds, 
											   vCurRoomRateSrvHasManualPrice, vIsManualPrice, vPriceCalcDate, vOffers, vIsForFolioSplit, vDoNotRoundPrice, vCurAccommodationType, vIsForFolioSplitForPrices, vSplitPackagesByGuests, vIsManualServices, 
											   vClientType, vSourceOfBusiness, vMarketingCode, vBoardPlace, vCalendarDayTypeIsChanged, vOfferByRoomTypeUpgradeDescription, vOfferByTermsUpgradeDescription, vRateService, vGuestsCheckedInIsSet);
									// Try to restore discount amount from reservation service
									If vFixReservationConditions And vResRateSrv Then
										vSrvRowToFix = Services.Get(vSavI);
										If vResService = vSrvRowToFix.Service And vResPrice = vSrvRowToFix.Price And vResDiscount = vSrvRowToFix.Discount And vResQuantity = vSrvRowToFix.Quantity Then
											vSrvRowToFix.DiscountSum = vResDiscountSum;
											vSrvRowToFix.VATDiscountSum = vResVATDiscountSum;
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
	ElsIf IsBlankString(rWarnings) Then
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
		// Process warnings
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
				vWarningsEn = "Room rate price is not defined for room rate " + RoomRate + ", accommodation period " + Format(CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ", room type " + vRoomType + " and accommodation type " + AccommodationType + "!";
				vWarningsDe = "Zimmerpreis ist nicht definiert fur Tariff " + RoomRate + ", den Zeitraum des Aufenthalts von " + Format(CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " bis " + Format(CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ", Zimmertyp " + vRoomType + " und Typ der Unterbringungen " + AccommodationType + "!";
				vWarningsRu = "Для периода проживания " + Format(CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + " в тарифе " + RoomRate + " для типа номера " + vRoomType + " и вида размещения " + AccommodationType + " не определена цена проживания!";
			EndIf;
		EndIf;
		If vWarnings Then
			rWarnings = "ru = '" + vWarningsRu + "'; de = '" + vWarningsDe + "'; en = '" + vWarningsEn + "'";
		EndIf;
	Else
		vWarnings = True;
	EndIf;
	If vWarnings And Not IsBlankString(rWarnings) Then
		WriteLogEvent(NStr("en='Accommodation.CalculateServices';ru='Размещение.РасчетУслуг';de='Accommodation.CalculateServices'"), EventLogLevel.Warning, Metadata(), Ref, cmNStr(rWarnings));
	EndIf;
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
							vAccountingDateMove = cmGetAccountingDateMove(vNextSrvRowService.QuantityCalculationRule, vNextSrvRow.IsManual, ThisObject, True);
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
	vAfterCalculateServicesUserExit = Catalogs.ExternalDataProcessors.AccommodationAfterCalculateServices;
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
		If GuestGroup.ClientDoc = Ref Or GuestGroup.ClientDoc = Reservation And ValueIsFilled(Reservation) Then
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
		
		// Fill tax calculation date if empty
		If Not ValueIsFilled(TouristicTaxAccountingDate) Then
			If Hotel.TouristTaxAccountingDateSettingType = Enums.TouristTaxAccountingDateSettingTypes.UseDateOfFullPayment Then
				If ValueIsFilled(AccommodationStatus) And AccommodationStatus.IsActive And Not AccommodationStatus.IsInHouse Then
					TouristicTaxAccountingDate = BegOfDay(CheckOutDate);
				EndIf;
			EndIf;
		EndIf;
		
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
				vAccountingDateMove = cmGetAccountingDateMove(vInPriceServicesRowService.QuantityCalculationRule, vInPriceServicesRow.IsManual, ThisObject, True);
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
			vTouristTaxAmountPerDate = cmCalculateTouristTaxSum(Hotel, vRoomPriceService.IsHotelProductService, vTouristTaxAccountingDate, RateSumInBaseCurrency, DurationInDays, Guest, GuestAge, CheckInDate, CheckOutDate, vTouristTaxService, TouristicTaxExemptionReason, TouristicTaxExemptionReasonFillDate, TouristTaxRate, MinAmountPerDay, TouristicTaxIsByMinAmount, True, 1, RoomRate);
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
								vSrvRow.RateSum = vSrvRow.RateSum + vTouristTaxAmountPerDate;
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
						vSrvRow.RateSum = vSrvRow.RateSum + vTouristTaxAmountPerDate;
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
			vTouristTaxSumInBaseCurrency = vTouristTaxAmountPerDate * DurationInDays;
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
	vTouristTaxSrvRow.Quantity = 1;
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
			vRoomRateServiceRow.RateSum = vRoomRateServiceRow.RateSum + Round(cmConvertCurrencies(pTouristTaxAmount, Hotel.BaseCurrency, , vRoomRateServiceRow.FolioCurrency, vRoomRateServiceRow.FolioCurrencyExchangeRate, pAccountingDate, Hotel), 2);
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
			pSrvRow.DiscountSum = Round(pSrvRow.Sum * pSrvRow.Discount/100, 2);
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
		pSrvRow.DiscountSum = Round(pSrvRow.Sum * pSrvRow.Discount/100, 2);
	EndIf;
 	pSrvRow.VATDiscountSum = cmCalculateVATSum(pSrvRow.VATRate, pSrvRow.DiscountSum, pSrvRow.AccountingDate);
EndProcedure // pmCalculateServiceDiscounts

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
					pSrvRow.CommissionSum = Round(cmConvertCurrencies(pSrvRow.AgentCommission, vAgentCurrency, , pSrvRow.FolioCurrency, pSrvRow.FolioCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
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
						pSrvRow.CommissionSum = Round(cmConvertCurrencies(pSrvRow.AgentCommission, vAgentCurrency, , pSrvRow.FolioCurrency, pSrvRow.FolioCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
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
					pSrvRow.CommissionSum = Round(cmConvertCurrencies(pSrvRow.AgentCommission, vAgentCurrency, , pSrvRow.FolioCurrency, pSrvRow.FolioCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
					pSrvRow.VATCommissionSum = cmCalculateVATSum(pSrvRow.VATRate, pSrvRow.CommissionSum, pSrvRow.AccountingDate);
				ElsIf pSrvRow.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerCheckInPerClient And pSrvRow.IsRoomRevenue And pSrvRow.IsInPrice And Not pSrvRow.IsSplit Then
					If BegOfDay(CheckInDate) = BegOfDay(pSrvRow.AccountingDate) Then
						vAgentCurrency = ReportingCurrency;
						If ValueIsFilled(Contract) And ValueIsFilled(Contract.AgentCommissionType) Then
							vAgentCurrency = Contract.AccountingCurrency;
						ElsIf ValueIsFilled(Agent) Then
							vAgentCurrency = Agent.AccountingCurrency;
						EndIf;		
						pSrvRow.CommissionSum = Round(cmConvertCurrencies(pSrvRow.AgentCommission, vAgentCurrency, , pSrvRow.FolioCurrency, pSrvRow.FolioCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
						pSrvRow.VATCommissionSum = cmCalculateVATSum(pSrvRow.VATRate, pSrvRow.CommissionSum, pSrvRow.AccountingDate);
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
	EndIf;
EndProcedure // pmSetServiceCommissions

// -----------------------------------------------------------------------------
Procedure pmCalculateServiceCommissions(pSrvRow) Export
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
					vAgentCurrency = ReportingCurrency;
					If ValueIsFilled(Contract) And ValueIsFilled(Contract.AgentCommissionType) Then
						vAgentCurrency = Contract.AccountingCurrency;
					ElsIf ValueIsFilled(Agent) Then
						vAgentCurrency = Agent.AccountingCurrency;
					EndIf;		
					pSrvRow.CommissionSum = Round(cmConvertCurrencies(pSrvRow.AgentCommission, vAgentCurrency, , pSrvRow.FolioCurrency, pSrvRow.FolioCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
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
						pSrvRow.CommissionSum = Round(cmConvertCurrencies(pSrvRow.AgentCommission, vAgentCurrency, , pSrvRow.FolioCurrency, pSrvRow.FolioCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
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
					pSrvRow.CommissionSum = Round(cmConvertCurrencies(pSrvRow.AgentCommission, vAgentCurrency, , pSrvRow.FolioCurrency, pSrvRow.FolioCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
					pSrvRow.VATCommissionSum = cmCalculateVATSum(pSrvRow.VATRate, pSrvRow.CommissionSum, pSrvRow.AccountingDate);
				ElsIf pSrvRow.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerCheckInPerClient And pSrvRow.IsRoomRevenue And pSrvRow.IsInPrice And Not pSrvRow.IsSplit Then
					If BegOfDay(CheckInDate) = BegOfDay(pSrvRow.AccountingDate) Then
						vAgentCurrency = ReportingCurrency;
						If ValueIsFilled(Contract) And ValueIsFilled(Contract.AgentCommissionType) Then
							vAgentCurrency = Contract.AccountingCurrency;
						ElsIf ValueIsFilled(Agent) Then
							vAgentCurrency = Agent.AccountingCurrency;
						EndIf;		
						pSrvRow.CommissionSum = Round(cmConvertCurrencies(pSrvRow.AgentCommission, vAgentCurrency, , pSrvRow.FolioCurrency, pSrvRow.FolioCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
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
EndProcedure // pmCalculateServiceCommissions

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
		For Each vChargingRuleRow In pChargingRules Do
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
EndProcedure // pmSetServiceFolioBasedOnChargingRules 

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
					If ValueIsFilled(vServiceRow.Folio) And vServiceRow.FolioCurrency <> vServiceRow.Folio.FolioCurrency Then
						vServiceRow.FolioCurrency = vServiceRow.Folio.FolioCurrency;
						vServiceRow.FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, vServiceRow.FolioCurrency, ?(ValueIsFilled(vServiceRow.AccountingDate), vServiceRow.AccountingDate, ExchangeRateDate));
					EndIf;
					Break;
				EndIf;
			EndDo;
		EndDo;
	EndIf;
EndProcedure // pmSetFolioBasedOnChargingRules 

// -----------------------------------------------------------------------------
// Get accommodation attributes valid on specified date
// - pDate is optional. If is not specified, then function gets attributes on current date
// Returns ValueTable 
// -----------------------------------------------------------------------------
Function pmGetAccommodationAttributes(Val pDate = Undefined) Export
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
	|	InformationRegister.AccommodationChangeHistory.SliceLast(
	|	&qDate, 
	|	Accommodation = &qAccommodation) AS AccommodationChangeHistory";
	qGetLastAttr.SetParameter("qDate", pDate);
	qGetLastAttr.SetParameter("qAccommodation", Ref);
	vAttr = qGetLastAttr.Execute().Unload();
	
	Return vAttr;
EndFunction // pmGetAccommodationAttributes

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
							vFolioObj.GuestGroup = GuestGroup;
							vFolioObj.DateTimeFrom = CheckInDate;
							vFolioObj.DateTimeTo = CheckOutDate;
							If TypeOf(pOwner) = Type("CatalogRef.Customers") Then
								vFolioObj.Customer = Catalogs.Customers.EmptyRef();
							ElsIf TypeOf(pOwner) = Type("CatalogRef.Contracts") Then
								vFolioObj.Customer = Catalogs.Customers.EmptyRef();
								vFolioObj.Contract = Catalogs.Contracts.EmptyRef();
							ElsIf TypeOf(pOwner) = Type("CatalogRef.Clients") Then
								vFolioObj.Client = Catalogs.Clients.EmptyRef();
							ElsIf TypeOf(pOwner) = Type("CatalogRef.Rooms") Then
								vFolioObj.Room = Catalogs.Rooms.EmptyRef();
							EndIf;
							vFolioObj.DeletionMark = False;
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
							ValueIsFilled(vFolioObj.ParentDoc) And vFolioObj.ParentDoc <> Ref Then
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
EndProcedure // pmRemoveIsMasterChargingRules

// -----------------------------------------------------------------------------
Procedure pmLoadMasterChargingRules(pMasterDoc) Export
	// Remove "Is Master" charging rules
	i = 0;
	j = 0;
	vCRTo = ChargingRules.Unload();
	While i < vCRTo.Count() Do
		vCRRow = vCRTo.Get(i);
		If vCRRow.IsMaster Then
			vCRTo.Delete(i);
			// Save position of the first deleted row
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
EndProcedure // pmLoadMasterChargingRules

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
EndProcedure // pmOverloadMasterChargingRules

// -----------------------------------------------------------------------------
Function GetRoomMainAccommodation()
	vOneRoomDoc = Undefined;
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.Posted
	|	AND Accommodation.GuestGroup = &qGuestGroup
	|	AND Accommodation.Room = &qRoom
	|	AND Accommodation.AccommodationType.Type = &qAccommodationTypeType
	|	AND Accommodation.AccommodationStatus.IsActive";
	vQry.SetParameter("qGuestGroup", GuestGroup);
	vQry.SetParameter("qRoom", Room);
	vQry.SetParameter("qAccommodationTypeType", Enums.AccomodationTypes.Room);
	vOneRoomDocs = vQry.Execute().Unload();
	If vOneRoomDocs.Count() > 0 Then
		vOneRoomDoc = vOneRoomDocs.Get(0).Ref;
	ElsIf ValueIsFilled(RoomType) And RoomType.DoesNotAffectRoomRevenueStatistics Then
		// Try to find main reservation by guest
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	Accommodation.Ref
		|FROM
		|	Document.Accommodation AS Accommodation
		|WHERE
		|	Accommodation.Posted
		|	AND Accommodation.GuestGroup = &qGuestGroup
		|	AND Accommodation.Guest = &qGuest
		|	AND &qGuestIsFilled
		|	AND Accommodation.AccommodationType.Type = &qAccommodationTypeType
		|	AND Accommodation.AccommodationStatus.IsActive";
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
EndFunction // GetRoomMainAccommodation

// -----------------------------------------------------------------------------
Procedure pmLoadDefaultChargingRules() Export
	ChargingRules.Clear();
	If ValueIsFilled(AccommodationType) And AccommodationType.PostToRoomMainFolio And Not IsForFolioSplit Then
		vOneRoomDoc = GetRoomMainAccommodation();
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
EndProcedure // pmLoadDefaultChargingRules

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
			vFolioObj.PaymentMethod = Hotel.PaymentMethodForCustomerPayments;
			If ValueIsFilled(vContract) Then
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
// Get accommodation prices for all day types of room rate
// -----------------------------------------------------------------------------
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
			EndIf;
		EndIf;
		// Function will return price columns only, so take quantity into account
		vCurSrv.PriceBeforeDiscount = vCurSrv.SumBeforeDiscount;
		vCurSrv.Price = vCurSrv.Sum;
		// Change accounting dates for breakfast
		If Not vCurSrv.IsManual And vCurSrv.IsInPrice And vCurSrv.Price <> 0 And 
		   ValueIsFilled(vService.QuantityCalculationRule) Then
			vAccountingDateMove = cmGetAccountingDateMove(vService.QuantityCalculationRule, vCurSrv.IsManual, ThisObject, True);
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
EndFunction // pmGetPrices

// -----------------------------------------------------------------------------
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
EndFunction // pmGetDocumentLanguage

// -----------------------------------------------------------------------------
Function pmGetForeignerRegistryRecords(pLastAccInChain = Undefined) Export
	// Check guest attributes
	If Not ValueIsFilled(Guest) Then
		Return Undefined;
	EndIf;
	If Not ValueIsFilled(Guest.Citizenship) Then
		Return Undefined;
	EndIf;
	If Not ValueIsFilled(Hotel) Then
		Return Undefined;
	EndIf;
	If Guest.Citizenship = Hotel.Citizenship Then
		Return Undefined;
	EndIf;
	
	// If last accommodation in chain is not defined, then try to get it
	If Not ValueIsFilled(pLastAccInChain) Then
		pLastAccInChain = pmGetLastAccommodationInChain();
	EndIf;
	
	// Check previous accommodation in chain
	vPrevAccInChain = Undefined;
	If TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") Then
		vPrevAccInChain = ParentDoc;
	EndIf;
	
	// Build and run query to get records for the current document
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	ForeignerRegistryRecord.Ref AS ForeignerRegistryRecord
	|FROM
	|	Document.ForeignerRegistryRecord AS ForeignerRegistryRecord
	|WHERE
	|	(ForeignerRegistryRecord.ParentDoc = &qCurAcc
	|			OR ForeignerRegistryRecord.ParentDoc = &qLastAcc
	|			OR ForeignerRegistryRecord.ParentDoc = &qPrevAcc)
	|	AND ForeignerRegistryRecord.Guest = &qGuest
	|	AND (NOT ForeignerRegistryRecord.DeletionMark)
	|
	|ORDER BY
	|	ForeignerRegistryRecord.PointInTime";
	vQry.SetParameter("qCurAcc", Ref);
	vQry.SetParameter("qLastAcc", pLastAccInChain);
	vQry.SetParameter("qPrevAcc", vPrevAccInChain);
	vQry.SetParameter("qGuest", Guest);
	vFRs = vQry.Execute().Unload();
	
	// Return
	Return vFRs;
EndFunction // pmGetForeignerRegistryRecords

// -----------------------------------------------------------------------------
Procedure pmProcessHotelChange() Export
	If ValueIsFilled(Hotel) Then
		SetNewNumber(Catalogs.Hotels.pmGetPrefix(Hotel));
		Company = Hotel.Company;
		RoomRate = Hotel.RoomRate;
		RoomRateServiceGroup = Hotel.RoomRateServiceGroup;
		ReportingCurrency = Hotel.ReportingCurrency;
		ReportingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, ReportingCurrency, Date);
		// Recreate guest group as it has hotel as owner
		pmCreateGuestGroup();
	EndIf;
EndProcedure // pmProcessHotelChange	

// -----------------------------------------------------------------------------
Procedure pmCheckOut(pCheckOutDate, pCheckOutStatus = Undefined, pIsForFolioSplit = Undefined) Export
	// Check current accommodation status
	If ValueIsFilled(AccommodationStatus) Then
		If AccommodationStatus.IsInHouse = False Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Guest has already being checked out! ';ru='Гость уже выселен! ';de='Gast bereits ausgecheckt! '") + String(Ref));
			Return;
		EndIf;
	EndIf;
	// Fill check out date
	CheckOutDate = pCheckOutDate;
	If ValueIsFilled(Hotel.AccountingDate) Then
		AccountingCheckOutDate = Hotel.AccountingDate;
	Else
		AccountingCheckOutDate = BegOfDay(CurrentSessionDate());
	EndIf;
	
	// Initialize check out status
	vCheckOutStatus = pCheckOutStatus;
	If vCheckOutStatus = Undefined Then
		If ValueIsFilled(AccommodationStatus) And ValueIsFilled(Hotel) Then
			If AccommodationStatus.IsRoomChange Then
				vCheckOutStatus = Hotel.MoveAndCheckOutAccommodationStatus;
			Else
				vCheckOutStatus = Hotel.CheckOutAccommodationStatus;
			EndIf;
		EndIf;
	EndIf;
	AccommodationStatus = vCheckOutStatus;
	// Calculate duration
	Duration = pmCalculateDuration();
	// Check should we update document attributes from the accommodation plan
	vStruct = pmGetAccommodationPlanAttributes(BegOfDay(CheckOutDate), RoomRates, Room, RoomType, AccommodationType, RoomRate, CheckInDate);
	If vStruct.Room <> Room Or vStruct.RoomType <> RoomType Or 
	   vStruct.AccommodationType <> AccommodationType Or 
	   vStruct.RoomRate <> RoomRate Then
		// Check if there is room rates row for check in date
		vCheckInDate = CheckInDate;
		If ValueIsFilled(Reservation) Then
			vCheckInDate = Min(vCheckInDate, Reservation.CheckInDate);
		EndIf;
		v1DayRRRow = RoomRates.Find(BegOfDay(vCheckInDate), "AccountingDate");
		If v1DayRRRow = Undefined Then
			v1DayRRRow = RoomRates.Insert(0);
			v1DayRRRow.AccountingDate = BegOfDay(vCheckInDate);
			v1DayRRRow.RoomType = RoomType;
			v1DayRRRow.Room = Room;
			v1DayRRRow.AccommodationType = AccommodationType;
		Else
			If Not ValueIsFilled(v1DayRRRow.Room) And vStruct.Room <> Room Then
				v1DayRRRow.Room = Room;
				v1DayRRRow.RoomType = RoomType;
			EndIf;
			If Not ValueIsFilled(v1DayRRRow.RoomType) And vStruct.RoomType <> RoomType Then
				v1DayRRRow.RoomType = RoomType;
			EndIf;
			If Not ValueIsFilled(v1DayRRRow.AccommodationType) And vStruct.AccommodationType <> AccommodationType Then
				v1DayRRRow.AccommodationType = AccommodationType;
			EndIf;
		EndIf;
		RoomRates.Sort("AccountingDate, ChangeTime");
		// Update current document attributes from the structure
		FillPropertyValues(ThisObject, vStruct, , "RoomRate");
		// Retrieve room resources
		If ValueIsFilled(Room) Then
			vRoomObj = Room.GetObject();
			vRoomAttr = vRoomObj.pmGetRoomAttributes(cm1SecondShift(vStruct.RoomChangeDate));
			For Each vRoomAttrRow In vRoomAttr Do
				NumberOfBedsPerRoom = vRoomAttrRow.NumberOfBedsPerRoom;
				NumberOfPersonsPerRoom = vRoomAttrRow.NumberOfPersonsPerRoom;
				RoomType = vRoomAttrRow.RoomType;
				Break;
			EndDo;
		ElsIf ValueIsFilled(RoomType) Then
			NumberOfBedsPerRoom = RoomType.NumberOfBedsPerRoom;
			NumberOfPersonsPerRoom = RoomType.NumberOfPersonsPerRoom;
		EndIf;
		// Calculate resources
		cmCalculateResources(vStruct.RoomChangeDate, RoomType, AccommodationType,
							 Room, 1, NumberOfRooms,
							 NumberOfBeds, NumberOfAdditionalBeds, NumberOfPersons, 
							 NumberOfBedsPerRoom, NumberOfPersonsPerRoom);
	EndIf;
	// Update price calculation dates if necessary
	pmUpdatePriceCalculationDate();
	// Calculate services
	vWarnings = "";
	If pmCalculateServices(vWarnings, , , , , pIsForFolioSplit) Then
		WriteLogEvent(NStr("en='Accommodation.CheckOut';ru='Размещение.Выселение';de='Accommodation.CheckOut'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vWarnings));
		tcCommonFunctionOnClientServer.TextMessage(NStr(vWarnings), MessageStatus.Attention);
	EndIf;
	// Set room status after check out
	If ValueIsFilled(Hotel) And ValueIsFilled(Room) And ValueIsFilled(AccommodationType) Then
		vDoChangeRoomStatus = True;
		vRoomRoomStatus = Room.RoomStatus;
		// Do nothing if room status already was changed
		If ValueIsFilled(Hotel.RoomStatusAfterCheckOut) And vRoomRoomStatus = Hotel.RoomStatusAfterCheckOut Then
			vDoChangeRoomStatus = False;
		EndIf;
		// Do nothing if room was cleared already
		If vRoomRoomStatus = Hotel.VacantRoomStatus Then
			vDoChangeRoomStatus = False;
		EndIf;
		// Do nothing if inspection is in progress already
		If ValueIsFilled(Hotel.RoomStatusInspection) And vRoomRoomStatus = Hotel.RoomStatusInspection Or 
		   ValueIsFilled(vRoomRoomStatus) And vRoomRoomStatus.InspectionIsInProgress Then
			vDoChangeRoomStatus = False;
		EndIf;
		// Check if there are another checked-in guests in this room
		vRoomNextGuests = cmGetRoomNextGuests(Hotel, RoomType, Room, CheckOutDate, Ref);
		If vRoomNextGuests.Count() > 0 Then
			vDoChangeRoomStatus = False;
		EndIf;
		If vDoChangeRoomStatus Then
			If AccommodationType.Type = Enums.AccomodationTypes.Room Or AccommodationType.Type = Enums.AccomodationTypes.Beds Then
				// Do change room status if main room guest is checked out
				If AccommodationType.Type = Enums.AccomodationTypes.Room Or Hotel.SetRoomStatusAfterCheckOutForBeds Then
					// Check if there is another active reservation for the current guest to the same room
					If ValueIsFilled(Hotel.OccupiedDirtyRoomStatus) And CheckOtherReservationForTheCurrentGuest(Guest, Room, Hotel, CheckOutDate) Then
						DoChangeRoomStatus(Hotel.OccupiedDirtyRoomStatus);
					Else
						DoChangeRoomStatus(Hotel.RoomStatusAfterCheckOut);
					EndIf;
				Else
					// Check number of occupied beds in the room
					vThereAreOtherGuests = False;
					vAccommodations = cmGetRoomGuests(Hotel, RoomType, Room, CheckOutDate - 1, CheckOutDate);
					For Each vAccommodationsRow In vAccommodations Do
						vAccommodation = vAccommodationsRow.Accommodation;
						If vAccommodation <> Ref And 
						   vAccommodation.AccommodationStatus.IsInHouse And 
						  (vAccommodation.AccommodationType.Type = Enums.AccomodationTypes.Room Or 
						   vAccommodation.AccommodationType.Type = Enums.AccomodationTypes.Beds) Then
							vThereAreOtherGuests = True;
							Break;
						EndIf;
					EndDo;
					If Not vThereAreOtherGuests Then
						// Check if there is another active reservation for the current guest to the same room
						If ValueIsFilled(Hotel.OccupiedDirtyRoomStatus) And CheckOtherReservationForTheCurrentGuest(Guest, Room, Hotel, CheckOutDate) Then
							DoChangeRoomStatus(Hotel.OccupiedDirtyRoomStatus);
						Else
							DoChangeRoomStatus(Hotel.RoomStatusAfterCheckOut);
						EndIf;
					EndIf;
				EndIf;
			Else
				// Check if there are other in-house guests in the room
				vThereAreOtherGuests = False;
				vAccommodations = cmGetRoomGuests(Hotel, RoomType, Room, CheckOutDate - 1, CheckOutDate);
				For Each vAccommodationsRow In vAccommodations Do
					vAccommodation = vAccommodationsRow.Accommodation;
					If vAccommodation <> Ref And 
					   vAccommodation.AccommodationStatus.IsInHouse Then
						vThereAreOtherGuests = True;
						Break;
					EndIf;
				EndDo;
				If Not vThereAreOtherGuests Then
					// Check if there is another active reservation for the current guest to the same room
					If ValueIsFilled(Hotel.OccupiedDirtyRoomStatus) And CheckOtherReservationForTheCurrentGuest(Guest, Room, Hotel, CheckOutDate) Then
						DoChangeRoomStatus(Hotel.OccupiedDirtyRoomStatus);
					Else
						DoChangeRoomStatus(Hotel.RoomStatusAfterCheckOut);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // pmCheckOut

// -----------------------------------------------------------------------------
Function CheckOtherReservationForTheCurrentGuest(pGuest, pRoom, pHotel, pCheckOutDate)
	vReservationIsFound = False;
	If ValueIsFilled(pGuest) And BegOfDay(pCheckOutDate) = BegOfDay(CurrentSessionDate()) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	Reservations.Ref AS Ref
		|FROM
		|	Document.Reservation AS Reservations
		|WHERE
		|	Reservations.Guest = &qGuest
		|	AND (Reservations.Room = &qRoom
		|			OR Reservations.Room = &qEmptyRoom
		|				AND Reservations.RoomType = &qRoomType)
		|	AND Reservations.Hotel = &qHotel
		|	AND Reservations.Posted
		|	AND Reservations.ReservationStatus.IsActive
		|	AND BEGINOFPERIOD(Reservations.CheckInDate, DAY) = &qCheckInDate
		|	AND Reservations.ParentDoc <> &qThisRef
		|	AND Reservations.Number <> &qThisRefNumber
		|
		|UNION ALL
		|
		|SELECT
		|	Accommodations.Ref
		|FROM
		|	Document.Accommodation AS Accommodations
		|WHERE
		|	Accommodations.Guest = &qGuest
		|	AND Accommodations.Room = &qRoom
		|	AND Accommodations.Hotel = &qHotel
		|	AND Accommodations.Posted
		|	AND Accommodations.Ref <> &qThisRef
		|	AND Accommodations.Number <> &qThisRefNumber
		|	AND Accommodations.AccommodationStatus.IsActive
		|	AND Accommodations.AccommodationStatus.IsInHouse
		|	AND BEGINOFPERIOD(Accommodations.CheckInDate, DAY) = &qCheckInDate";
		vQry.SetParameter("qGuest", pGuest);
		vQry.SetParameter("qRoom", pRoom);
		vQry.SetParameter("qRoomType", pRoom.RoomType);
		vQry.SetParameter("qEmptyRoom", Catalogs.Rooms.EmptyRef());
		vQry.SetParameter("qHotel", pHotel);
		vQry.SetParameter("qThisRef", Ref);
		vQry.SetParameter("qThisRefNumber", Number);
		vQry.SetParameter("qCheckInDate", BegOfDay(pCheckOutDate));
		vReservations = vQry.Execute().Unload();
		If vReservations.Count() > 0 Then
			vReservationIsFound = True;
		EndIf;
	EndIf;
	Return vReservationIsFound;
EndFunction // CheckOtherReservationForTheCurrentGuest

// -----------------------------------------------------------------------------
Function pmHideClientNameAndNameHistory() Export
	// Check if we have to clear client names
	If ValueIsFilled(Guest) Then
		If ValueIsFilled(ClientType) And ClientType.ClearClientNamesAfterCheckout Or
		   ValueIsFilled(Guest.ClientType) And Guest.ClientType.ClearClientNamesAfterCheckout Then
			cmHideClientNameAndNameHistory(Guest);
			Return True;
		EndIf;
	EndIf;
	Return False;
EndFunction // pmHideClientNameAndNameHistory

// -----------------------------------------------------------------------------
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
EndFunction // pmSetPlannedPaymentMethod

// -----------------------------------------------------------------------------
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
EndFunction // pmGetAccommodationServiceChargingFolio

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
			tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage), MessageStatus.Attention);
			Raise String(Ref) + " - " + NStr(vMessage);
		Else
			StatusHasChanged = False;
			vLastDocState = pmGetPreviousObjectState(CurrentSessionDate(), True);
			
			// Check if there was document status change
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
				If AccommodationStatus <> vLastDocState.AccommodationStatus Then
					StatusHasChanged = True;
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

			// Refill guarantee type
			If ValueIsFilled(Reservation) Then
				If Not ValueIsFilled(GuaranteeType) And ValueIsFilled(Reservation.GuaranteeType) Then
					GuaranteeType = Reservation.GuaranteeType;
				EndIf;
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
			
			// Check if accommodation is complimentary
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
			If Not cmCheckUserPermissions("HavePermissionToSetDeletionMarkForAccommodations") Then
				pCancel = True;
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to mark accommodation for deletion! Change accommodation status instead.';ru='Нет прав на пометку размещения на удаление! Вместо удаления измените статус размещения.';de='Sie haben kein Recht, Unterkunft für Löschung zu markieren! Ändern Sie stattdessen den unterkunftsstatus.'"), MessageStatus.Attention);
				Return;
			EndIf;
		EndIf;
		If ValueIsFilled(Hotel) And Hotel.DoNotEditSettledDocs And 
		  (pWriteMode = DocumentWriteMode.UndoPosting Or DeletionMark) And 
		  (Services.Total("Sum") <> 0 Or Services.Total("Quantity") <> 0) And 
		   ValueIsFilled(AccommodationStatus) And AccommodationStatus.IsActive And Not AccommodationStatus.IsInHouse And 
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
				tcCommonFunctionOnClientServer.TextMessage(NStr("ru='Все начисления размещения уже закрыты актами об оказании услуг! Редактирование такого размещения запрещено.';en='All accommodation charges are closed by invoices! Accommodation is read only.';de='Alle Übernachtungskosten werden durch Rechnungen geschlossen! Die Unterkunft ist nur lesbar.'"), MessageStatus.Attention);
				Return;
			EndIf;
		EndIf;
		If DeletionMark Then
			// User activity history   
			vEventDescription = NStr("en = 'Set document deletion mark'; de = 'Erstellung der Löschmarkierung'; ru = 'Установка отметки удаления'");    
			InformationRegisters.UserActionsHistory.WriteUserActivityRecord(Ref, vEventDescription, Hotel);
		EndIf;
	EndIf;
	// Fill guest full name (used to sort accommodation's archive by guest names)
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
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
Procedure WriteDefaultInterfaceStatuses()
	If Hotel.DefaultRoomInterfaces.Count() > 0 And ValueIsFilled(Room) And Not Room.IsVirtual Then
		vDate = Date;
		vCheckInDate = pmGetRoomCheckInDate(vDate);
		vRoomInterfaces = cmGetRoomInterfaceStatuses(Room, Min(vCheckInDate, vDate), CheckOutDate, Ref);
		For Each vDftRoomStsRow In Hotel.DefaultRoomInterfaces Do
			If ValueIsFilled(vDftRoomStsRow.RoomInterfaceType) Then
				vDftRoomInterfaceType = vDftRoomStsRow.RoomInterfaceType;
				If vDftRoomInterfaceType.InterfaceType = Enums.InterfaceTypes.TV And Not Room.IsUseTVInterface Then
					Continue;
				EndIf;
				If Not vDftRoomInterfaceType.ApplyToAllRoomGuests Then
					If Not pmIsMainAccommodationType() Then
						Continue;
					ElsIf vRoomInterfaces.Find(vDftRoomInterfaceType, "RoomInterfaceType") <> Undefined Then
						Continue;
					EndIf;
				Else
					If vRoomInterfaces.FindRows(New Structure("RoomInterfaceType, ParentDoc", vDftRoomInterfaceType, Ref)).Count() > 0 Then
						Continue;
					EndIf;
				EndIf;
				
				vStsObj = Documents.RoomInterfaceStatus.CreateDocument();
				vStsObj.Fill(Ref);
				FillPropertyValues(vStsObj, vDftRoomStsRow);
				vStsObj.InterfaceType = vDftRoomInterfaceType.InterfaceType;
				vStsObj.ExtraParameters = vDftRoomInterfaceType.ExtraParameters; 
				vStsObj.Write(DocumentWriteMode.Write);
			EndIf;
		EndDo;
	EndIf;
EndProcedure // WriteDefaultInterfaceStatuses 

// -----------------------------------------------------------------------------
Procedure SwitchOffRoomInterfaceStatuses()
	// Switch off all room interface statuses
	vDate = Date;
	vCheckInDate = pmGetRoomCheckInDate(vDate);
	vRoomSts = cmGetRoomInterfaceStatuses(Room, Min(vCheckinDate, vDate), CheckOutDate, Ref);
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
EndProcedure // SwitchOffRoomInterfaceStatuses 

// -----------------------------------------------------------------------------
Function pmIsMainAccommodationType()
	If ValueisFilled(AccommodationType) Then
		If AccommodationType.Type = Enums.AccomodationTypes.Room Or
		   AccommodationType.Type = Enums.AccomodationTypes.Beds Then
			Return True;
		EndIf;
	EndIf;
	Return False;
EndFunction // pmIsMainAccommodationType

// -----------------------------------------------------------------------------
Function pmGetMasterAccommodation() Export
	vMasterDoc = Documents.Accommodation.EmptyRef();
	// Try to find master document in the list of all documents in the group
	vGuestGroupAccommodations = GuestGroup.GetObject().pmGetAccommodations();
	vMasterRow = vGuestGroupAccommodations.Find(True, "IsMaster");
	If vMasterRow <> Undefined Then
		vMasterDoc = vMasterRow.Accommodation;
	EndIf;
	Return vMasterDoc;
EndFunction // pmGetMasterAccommodation

// -----------------------------------------------------------------------------
Function pmGetRoomCheckInDate(pDate = Undefined) Export
	vRoomCheckInDoc = Ref;
	vParentDoc = ParentDoc;
	While ValueIsFilled(vParentDoc) And 
	      TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") And 
	      vParentDoc.Room = Room Do
		vRoomCheckInDoc = vParentDoc;
		vParentDoc = vParentDoc.ParentDoc;
	EndDo;
	pDate = vRoomCheckInDoc.Date;
	Return vRoomCheckInDoc.CheckInDate;
EndFunction // pmGetRoomCheckInDate

// -----------------------------------------------------------------------------
Procedure ProcessRoomInterfaceStatuses()
	// Check if there are commands created for the reservation and move them to this ref
	If ValueIsFilled(Reservation) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	RoomInterfaceStatus.Ref AS Ref
		|FROM
		|	Document.RoomInterfaceStatus AS RoomInterfaceStatus
		|WHERE
		|	RoomInterfaceStatus.ParentDoc = &qReservation
		|	AND NOT RoomInterfaceStatus.DeletionMark
		|
		|ORDER BY
		|	RoomInterfaceStatus.PointInTime";
		vQry.SetParameter("qReservation", Reservation);
		vResCommands = vQry.Execute().Unload();
		For Each vResCommandsRow In vResCommands Do
			vCommandDocObj = vResCommandsRow.Ref.GetObject();
			vCommandDocObj.ParentDoc = Ref;
			vCommandDocObj.Write(DocumentWriteMode.Write);
		EndDo;
	EndIf;
	// Do main processing
	If Not AccommodationStatus.IsActive Then
		SwitchOffRoomInterfaceStatuses();
	ElsIf Not AccommodationStatus.IsInHouse And AccommodationStatus.IsCheckOut Then
		SwitchOffRoomInterfaceStatuses();
	Else
		If AccommodationStatus.IsRoomChange Then
			If ValueIsFilled(ParentDoc) And TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") And ParentDoc.Room <> Room Then
				// Check if room interface statuses were already copied
				vDate = Date;
				vCheckInDate = pmGetRoomCheckInDate(vDate);
				vRoomInterfaces = cmGetRoomInterfaceStatuses(Room, Min(vCheckInDate, vDate), CheckOutDate, Ref);
				vDate = Date;
				vCheckInDate = ParentDoc.GetObject().pmGetRoomCheckInDate(vDate);
				vPrevRoomInterfaces = cmGetRoomInterfaceStatuses(ParentDoc.Room, Min(vCheckInDate, vDate), ParentDoc.CheckOutDate, Ref);
				For Each vPrevRoomInterfacesRow In vPrevRoomInterfaces Do
					If Not vPrevRoomInterfacesRow.IsCanceled Then
						If Not vPrevRoomInterfacesRow.ApplyToAllRoomGuests Then
							If Not pmIsMainAccommodationType() Then
								Continue;
							ElsIf vRoomInterfaces.Find(vPrevRoomInterfacesRow.RoomInterfaceType, "RoomInterfaceType") <> Undefined Then
								Continue;
							EndIf;
						Else
							If vPrevRoomInterfacesRow.ParentDoc <> ParentDoc Then
								Continue;
							ElsIf vRoomInterfaces.FindRows(New Structure("RoomInterfaceType, ParentDoc", vPrevRoomInterfacesRow.RoomInterfaceType, Ref)).Count() > 0 Then
								Continue;
							EndIf;
						EndIf;
						
						If vPrevRoomInterfacesRow.IsCanceled Or (Not vPrevRoomInterfacesRow.IsCanceled And Not ValueIsFilled(vPrevRoomInterfacesRow.RoomChangeParameters)) Or 
						   ParentDoc.Number <> Number Then
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
			EndIf;
		EndIf;
		// Check if there was room change, period of stay extension or guest name change
		vPrevAccStates = pmGetAccommodationAttributes(CurrentSessionDate());
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
						
						If vPrevRoomInterfacesRow.IsCanceled Or (Not vPrevRoomInterfacesRow.IsCanceled And Not ValueIsFilled(vPrevRoomInterfacesRow.RoomChangeParameters)) Or 
						   vPrevAccStateRow.Number <> Number Then
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
						If Not vPrevRoomInterfacesRow.IsCanceled And vPrevRoomInterfacesRow.IsProcessed Then
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
						If Not vPrevRoomInterfacesRow.IsCanceled And vPrevRoomInterfacesRow.IsProcessed Then
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
		// Write default interface statuses
		If AccommodationStatus.IsCheckIn And AccommodationStatus.IsInHouse Then
			WriteDefaultInterfaceStatuses();
		EndIf;
	EndIf;
EndProcedure // ProcessRoomInterfaceStatuses

// -----------------------------------------------------------------------------
Procedure Filling(pBase)
	// Fill from the base
	If ValueIsFilled(pBase) Then
		If TypeOf(pBase) = Type("CatalogRef.HotelProducts") And Not pBase.IsFolder Then
			// Fill attributes with default values
			pmFillAttributesWithDefaultValues();
			// Fill accommodation based on hotel product
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
			If ValueIsFilled(pBase.AccommodationStatus) Then
				AccommodationStatus = pBase.AccommodationStatus;
				IsOneTimeChargeNecessary = pBase.IsOneTimeChargeNecessary;
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
			// Fill check out time from the room rate
			If ValueIsFilled(RoomRate) And 
			   RoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour And 
			   ValueIsFilled(RoomRate.ReferenceHour) Then
				vCheckOutDate = cm0SecondShift(BegOfDay(CheckOutDate) + (RoomRate.ReferenceHour - BegOfDay(RoomRate.ReferenceHour)));
				If vCheckOutDate > CheckInDate Then
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
			pmFillAttributesWithDefaultValues(False);
			// This is change room action
			FillPropertyValues(ThisObject, pBase, , "Date, Author, DeletionMark, Posted");
			ParentDoc = pBase;
			AccommodationStatus = Hotel.ChangeRoomAccommodationStatus;
			Room = Catalogs.Rooms.EmptyRef();
			// If hotel is using reference hour then reset check-in time to it
			CheckInDate = cm1SecondShift(CurrentSessionDate());
			If ValueIsFilled(RoomRate) And RoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour And 
			   BegOfDay(CheckInDate) < BegOfDay(CurrentSessionDate()) Then
				If cmCheckUserPermissions("HavePermissionToEditAccommodationCheckInDate") Then
					CheckInDate = cm1SecondShift(BegOfDay(CurrentSessionDate()) + (RoomRate.ReferenceHour - BegOfDay(RoomRate.ReferenceHour)));
				EndIf;
			EndIf;
			If pBase.CheckOutDate > CheckInDate Then
				CheckOutDate = pBase.CheckOutDate;
				Duration = pmCalculateDuration();
			Else
				Duration = Hotel.Duration;
				CheckOutDate = pmCalculateCheckOutDate();
			EndIf;
			// Load prices
			Prices.Load(pBase.Prices.Unload());
			// Load room rates
			RoomRates.Load(pBase.RoomRates.Unload());
			// Load service packages
			ServicePackages.Load(pBase.ServicePackages.Unload());
			// Load services
			Services.Load(pBase.Services.Unload(New Structure("IsManual", False)));
			// Load charging rules
			ChargingRules.Load(pBase.ChargingRules.Unload());
			// Load occupation percents
			OccupationPercents.Load(pBase.OccupationPercents.Unload());
			// Load room properties
			RoomProperties.Load(pBase.RoomProperties.Unload());
			// Calculate resources
			pmCalculateResources();
			// Load manual services
			pmLoadManualServicesFromParentDoc(pBase);
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
			If Not ValueIsFilled(GuestGroup) Then
				GuestGroup = pBase.GuestGroup;
			EndIf;
			// Fill attributes with default values
			pmFillAttributesWithDefaultValues(False, False);
			If Not cmCheckUserPermissions("HavePermissionToCheckInBasedOnInactiveReservations") Then
				vRaiseException = False;
				If Not pBase.Posted Then
					vRaiseException = True;
				ElsIf Not ValueIsFilled(pBase.ReservationStatus) Then
					vRaiseException = True;
				ElsIf Not pBase.ReservationStatus.IsActive And pBase.ReservationStatus <> Hotel.NoShowReservationStatus Then
					vRaiseException = True;
				EndIf;
				If vRaiseException Then
					Raise String(Ref) + " - " + 
					      NStr("ru='Нет прав на размещение гостей по не активной брони! Действие будет отменено.';
					           |de='Sie haben keine Rechte, Gaste nach nicht aktiven Reservierungen zu platzieren! Die Aktion wird abgebrochen!'; 
							   |en='You do not have rights to check-in guests based on inactive reservation! Action will be canceled.'");
				EndIf;
			EndIf;
			// This is check-in based on reservation
			FillPropertyValues(ThisObject, pBase, , "Date, Author, DeletionMark, Posted, IsClosedForEdit");
			ParentDoc = pBase;
			If ValueIsFilled(pBase.Room) And pBase.IsClosedForEdit Then
				IsClosedForEdit = pBase.IsClosedForEdit;
			EndIf;	
			AccommodationStatus = Hotel.CheckInAccommodationStatus;
			If pBase.RoomQuantity > 1 Then 
				NumberOfAdults = Round(pBase.NumberOfAdults / pBase.RoomQuantity, 0);
				NumberOfTeenagers = Round(pBase.NumberOfTeenagers / pBase.RoomQuantity, 0);
				NumberOfChildren = Round(pBase.NumberOfChildren / pBase.RoomQuantity, 0);
				NumberOfInfants = Round(pBase.NumberOfInfants / pBase.RoomQuantity, 0);
			EndIf;
			vUseCurrentTime = True;
			If ValueIsFilled(Hotel) Then
				vUseCurrentTime = Not Hotel.UseReservationTimeForCheckIn;
			EndIf;
			If ValueIsFilled(pBase.ReservationStatus) And pBase.ReservationStatus.UseReservationTimeForCheckIn Then
				vUseCurrentTime = False;
			EndIf;
			If vUseCurrentTime Then
				If ValueIsFilled(Hotel) And ValueIsFilled(Hotel.CloseOfDayDefaultTime) And 
				   BegOfDay(pBase.CheckInDate) < BegOfDay(CurrentSessionDate()) And 
				   ValueIsFilled(RoomRate) And 
				   RoomRate.PeriodInHours = 24 And 
				   RoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour And
				   RoomRate.ReferenceHour = '00010101120000' And 
				   (CurrentSessionDate() - BegOfDay(CurrentSessionDate())) < (Hotel.CloseOfDayDefaultTime - BegOfDay(Hotel.CloseOfDayDefaultTime)) Then
					CheckInDate = BegOfDay(CurrentSessionDate()) - 1; // 23:59:59 of the previous date is assumed
				Else
					CheckInDate = cm1SecondShift(CurrentSessionDate());
				EndIf;
			Else
				CheckInDate = cm1SecondShift(pBase.CheckInDate);
			EndIf;
			If ValueIsFilled(pBase.ParentDoc) And TypeOf(pBase.ParentDoc) = Type("DocumentRef.Reservation") Then
				If BegOfDay(pBase.ParentDoc.CheckOutDate) = BegOfDay(pBase.CheckInDate) Then
					AccommodationStatus = Hotel.ChangeRoomAccommodationStatus;
					If BegOfDay(CurrentSessionDate()) <> BegOfDay(pBase.CheckInDate) Then
						CheckInDate = cm1SecondShift(pBase.CheckInDate);
					EndIf;
				EndIf;
			EndIf;
			If pBase.CheckOutDate > CheckInDate Then
				CheckOutDate = pBase.CheckOutDate;
				Duration = pmCalculateDuration();
			Else
				Duration = Hotel.Duration;
				CheckOutDate = pmCalculateCheckOutDate();
			EndIf;
			// Reset number of guests to 1 if it is necessary
			If Not Hotel.MultipleGuestsPerAccommodationIsByConvention Then
				NumberOfPersons = 1;
			Else
				vNumberOfPersonsPerRoom = Int(pBase.NumberOfPersons/?(pBase.RoomQuantity = 0, 1, pBase.RoomQuantity));
				If vNumberOfPersonsPerRoom > 0 Then
					NumberOfPersons = vNumberOfPersonsPerRoom;
				EndIf;
			EndIf;
			// Fill remarks from confirmation reply text
			If Not IsBlankString(pBase.ConfirmationReply) Then
				Remarks = TrimAll(Remarks) + ?(IsBlankString(Remarks), TrimAll(pBase.ConfirmationReply), Chars.LF + TrimAll(pBase.ConfirmationReply));
			EndIf;
			// Load prices
			Prices.Load(pBase.Prices.Unload());
			// Load room rates
			RoomRates.Load(pBase.RoomRates.Unload());
			// Load service packages
			ServicePackages.Load(pBase.ServicePackages.Unload());
			// Load services
			Services.Load(pBase.Services.Unload(New Structure("IsManual", False)));
			// Load occupation percents
			OccupationPercents.Load(pBase.OccupationPercents.Unload());
			// Load room properties
			RoomProperties.Load(pBase.RoomProperties.Unload());
			// Check parent reservation charging folio parent document
			vBaseFolioParentDocIsReservation = True;
			If Not ValueIsFilled(ParentDoc.ParentDoc) Or ValueIsFilled(ParentDoc.ParentDoc) And TypeOf(ParentDoc.ParentDoc) <> Type("DocumentRef.Reservation") Then
				For Each vCRRow In pBase.ChargingRules Do
					vFolioRef = vCRRow.ChargingFolio;
					If ValueIsFilled(vFolioRef) And 
					   ValueIsFilled(vFolioRef.ParentDoc) And 
					   TypeOf(vFolioRef.ParentDoc) = Type("DocumentRef.Accommodation") And 
					   Not vCRRow.IsMaster And Not vCRRow.IsTransfer And Not vFolioRef.IsMaster Then
						vBaseFolioParentDocIsReservation = False;
						Break;
					EndIf;
				EndDo;
			EndIf;
			// Create charging rules
			If vBaseFolioParentDocIsReservation Then
				#IF ThickClientOrdinaryApplication THEN
					If Not ValueIsFilled(GetNewObjectRef()) Then
						SetNewObjectRef(Documents.Accommodation.GetRef());
					EndIf;
					vIsSimpleMode = cmIsSimpleMode();
					If vIsSimpleMode Then
						// Use folios from the reservation
						If pBase.RoomQuantity = 1 Then
							ChargingRules.Load(pBase.ChargingRules.Unload());
						Else
							// Create folios as copy of base folios
							cmCreateChargingRulesBasedOnParent(ThisObject, pBase);
						EndIf;
					ElsIf Not vIsSimpleMode And cmLockChargingRules(pBase.ChargingRules, GetNewObjectRef(), amPersistentObjects) Then
						// Use folios from the reservation
						ChargingRules.Load(pBase.ChargingRules.Unload());
					Else
						// Create folios as copy of base folios
						cmCreateChargingRulesBasedOnParent(ThisObject, pBase);
					EndIf;
				#ELSE
					// Use folios from the reservation
					If pBase.RoomQuantity = 1 Then
						ChargingRules.Load(pBase.ChargingRules.Unload());
					Else
						// Create folios as copy of base folios
						cmCreateChargingRulesBasedOnParent(ThisObject, pBase);
					EndIf;
				#ENDIF
			Else
				// Create folios as copy of base folios
				cmCreateChargingRulesBasedOnParent(ThisObject, pBase);
			EndIf;
			// If there is master accommodation in the group, then 
			// load it's charging rules
			PayerAccommodation = Documents.Accommodation.EmptyRef();
			If ValueIsFilled(GuestGroup) Then
				vMasterDoc = pmGetMasterAccommodation();
				If ValueIsFilled(vMasterDoc) Then
					PayerAccommodation = vMasterDoc;
					// Check if there are already master charging rules
					vMasterChargingRulesFound = cmCheckMasterChargingRulesArePresent(ThisObject);
					If vMasterChargingRulesFound Then
						pmOverloadMasterChargingRules(vMasterDoc);
					Else
						pmLoadMasterChargingRules(vMasterDoc);
					EndIf;
				Else
					pmRemoveIsMasterChargingRules();
				EndIf;
			Else
				pmRemoveIsMasterChargingRules();
			EndIf;
			// Load manual services
			pmLoadManualServicesFromParentDoc(pBase);
			// Calculate resources
			pmCalculateResources();
			// Fill fix reservation period
			If ValueIsFilled(pBase.ReservationStatus) Then
				FixReservationConditions = pBase.ReservationStatus.FixReservationConditions;
			EndIf;
			// Calculate services
			pmCalculateServices();
			// Load manual prices
			pmLoadManualPricesFromParentDoc(pBase);
			// Set planned payment method from the first charging rule
			pmSetPlannedPaymentMethod();
			// If there are rooms in reservation then use first not in use room available
			If pBase.Rooms.Count() > 0 Then
				If ValueIsFilled(pBase.ReservationStatus) Then
					If pBase.ReservationStatus.IsActive Then
						pBaseObj = pBase.GetObject();
						pBaseObj.Read();
						For Each vRoomsRow In pBaseObj.Rooms Do
							If Not ValueIsFilled(vRoomsRow.Room) Then
								Continue;
							EndIf;
							If vRoomsRow.IsUsed Then
								Continue;
							EndIf;
							Room = vRoomsRow.Room;
							// Try to update reservation to mark that current room is already used
							vRoomsRow.IsUsed = True;
							If Not ValueIsFilled(GetNewObjectRef()) Then
								SetNewObjectRef(Documents.Accommodation.GetRef());
							EndIf;
							vRoomsRow.Accommodation = GetNewObjectRef();
							pBaseObj.Write(DocumentWriteMode.Write);
							// Stop iterating rooms
							Break;
						EndDo;
					EndIf;
				EndIf;
			EndIf;
			// Try to fill default room if necessary
			If ValueIsFilled(RoomType) And 
			   ValueIsFilled(AccommodationType) And 
			   ValueIsFilled(CheckInDate) And 
			   ValueIsFilled(CheckOutDate) And 
			   CheckOutDate > CheckInDate And 
			   Not ValueIsFilled(Room) Then
				Room = cmGetDefaultRoom(NumberOfBeds, Hotel, Company, RoomQuota, RoomType, CheckInDate, CheckOutDate, Guest);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // Filling

// -----------------------------------------------------------------------------
Procedure pmLoadManualServicesFromParentDoc(pBase, pIsUpdate = False) Export
	vChargingRules = ChargingRules.Unload();
	If ValueIsFilled(pBase) And (TypeOf(pBase) = Type("DocumentRef.Accommodation") Or TypeOf(pBase) = Type("DocumentRef.Reservation")) Then
		If Not pBase.IgnoreGroupChargingRules Then
			cmAddGuestGroupChargingRules(vChargingRules, GuestGroup);
		EndIf;
	Else
		cmAddGuestGroupChargingRules(vChargingRules, GuestGroup);
	EndIf;
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
		vCurSrv.Quantity = vCurSrv.Quantity / pBase.NumberOfPersons * NumberOfPersons;
		// Recalculate resources
		cmQuantityOnChange(vCurSrv.Price, vCurSrv.Quantity, vCurSrv.Sum, vCurSrv.VATRate, vCurSrv.VATSum, vCurSrv.AccountingDate);
		// Recalculate service room sales parameters
		cmRecalculateServiceRoomSalesParameters(vCurSrv, ThisObject);
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
EndProcedure // pmLoadManualServicesFromParentDoc

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
				vCurSrv.Quantity = vCurSrv.Quantity * (1 / ?(pBase.RoomQuantity = 0, 1, pBase.RoomQuantity));
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
Procedure OnSetNewNumber(pStandardProcessing, pPrefix)
	vPrefix = "";
	If ValueIsFilled(Hotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(Hotel);
	ElsIf ValueIsFilled(SessionParameters.CurrentHotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(SessionParameters.CurrentHotel);
	EndIf;
	If vPrefix <> "" Then
		pPrefix = vPrefix;
	EndIf;
EndProcedure // OnSetNewNumber

// -----------------------------------------------------------------------------
Procedure OnCopy(pCopiedObject)
	IsMaster = False;
	PayerAccommodation = Documents.Accommodation.EmptyRef();
	ExternalCode = "";
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
	// If there is master accommodation in the group, then 
	// load it's charging rules
	If ValueIsFilled(GuestGroup) Then
		vMasterDoc = pmGetMasterAccommodation();
		If ValueIsFilled(vMasterDoc) Then
			PayerAccommodation = vMasterDoc;
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
EndProcedure // pmCalculateAccumulationDiscountForAdditionalService

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
EndProcedure // pmFillAccumulationDiscountForManualServices

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
EndProcedure // pmClearManualServicesDiscount

// -----------------------------------------------------------------------------
Procedure pmSetDiscounts() Export
	// Do nothing if this is checked-out document
	If Not ValueIsFilled(AccommodationStatus) Or ValueIsFilled(AccommodationStatus) And Not AccommodationStatus.IsInHouse Then
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
	If ValueIsFilled(ParentDoc) Then
		If ParentDoc.Discount <> 0 Then
			vDiscountType = ParentDoc.DiscountType;
			vDiscount = ParentDoc.Discount;
			If cmCompareDiscounts(vDiscount, Discount) Or vDiscountType.DifferentDiscountPercentsForServiceGroupsAllowed Or 
			   vDiscountType.EachNDayIsFreeOfCharge > 0 Or
			   vDiscountType.IsAccumulatingDiscount And vDiscountType.HasToBeDirectlyAssigned Or 
			   vDiscountType.IsAccumulatingDiscount And vDiscountType.BonusCalculationFactor <> 0 Then 
				DiscountType = vDiscountType;
				DiscountServiceGroup = ParentDoc.DiscountServiceGroup;
				If IsBlankString(ParentDoc.DiscountConfirmationText) Then
					If TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Then
						DiscountConfirmationText = NStr("en='Reservation discount';ru='По брони';de='Nach Reservierung'");
					Else
						DiscountConfirmationText = NStr("en='Parent document discount';ru='По документу основанию';de='Nach dem Begrundungsdokument'");
					EndIf;
				Else
					DiscountConfirmationText = ParentDoc.DiscountConfirmationText;
				EndIf;
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
EndProcedure // pmSetDiscounts

// -----------------------------------------------------------------------------
Procedure pmDoChangeRoom(pChangeRoomDateTime) Export
	// Update room rates if change room date is not equal to the check-in date
	If BegOfDay(pChangeRoomDateTime) >= BegOfDay(CheckInDate) Then
		vOldRoomIsSet = False;
		vAccountingDate = BegOfDay(CheckInDate);
		While vAccountingDate <= BegOfDay(pChangeRoomDateTime) Do
			vRRRow = RoomRates.Find(vAccountingDate, "AccountingDate");
			If vAccountingDate = BegOfDay(pChangeRoomDateTime) Then
				If vRRRow = Undefined Then
					vRRRow = RoomRates.Add();
					vRRRow.AccountingDate = vAccountingDate;
				EndIf;
				If BegOfDay(pChangeRoomDateTime) > BegOfDay(CheckInDate) Then
					vRRRow.ChangeTime = '00010101' + (pChangeRoomDateTime - BegOfDay(pChangeRoomDateTime));
				EndIf;
				vRRRow.Room = Room;
				vRRRow.RoomType = RoomType;
				vRRRow.AccommodationType = AccommodationType;
				Break;
			ElsIf Not vOldRoomIsSet And BegOfDay(pChangeRoomDateTime) > BegOfDay(CheckInDate) Then
				If vRRRow = Undefined And vAccountingDate = BegOfDay(CheckInDate) Then
					vRRRow = RoomRates.Add();
					vRRRow.AccountingDate = vAccountingDate;
					vRRRow.Room = Ref.Room;
					vRRRow.RoomType = Ref.RoomType;
					vRRRow.AccommodationType = Ref.AccommodationType;
					vOldRoomIsSet = True;
				ElsIf vRRRow <> Undefined And ValueIsFilled(vRRRow.Room) And vRRRow.Room = Ref.Room And vRRRow.AccommodationType = Ref.AccommodationType Then
					vOldRoomIsSet = True;
				EndIf;
			EndIf;
			vAccountingDate = vAccountingDate + 24*3600;
		EndDo;
	EndIf;
	RoomRates.Sort("AccountingDate, ChangeTime");
EndProcedure // pmDoChangeRoom

// -----------------------------------------------------------------------------
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
EndFunction // pmGetAccommodationPlanAttributes

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
EndProcedure // pmDeleteUnusedChargingRuleFolios

// -----------------------------------------------------------------------------
Function pmGetThisDocumentRef() Export
	vObjectRef = Ref;
	If IsNew() Then
		vObjectRef = GetNewObjectRef();
		If Not ValueIsFilled(vObjectRef) Then
			SetNewObjectRef(Documents.Accommodation.GetRef());
			vObjectRef = GetNewObjectRef();
		EndIf;
	EndIf;
	Return vObjectRef;
EndFunction // pmGetThisDocumentRef

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
		vQry.SetParameter("qPriceCalculationDate", ?(ValueIsFilled(PriceCalculationDate), PriceCalculationDate, CurrentSessionDate()));
		vQry.SetParameter("qCalendar", ?(ValueIsFilled(vRoomRate), vRoomRate.Calendar, Undefined));
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
			|								AND RoomQuota.IsCommitment) AS CommitmentBlocks
			|				) AS RoomSalesTurnovers
			|			
			|			GROUP BY
			|				RoomSalesTurnovers.Period) AS RoomSales
			|			ON TotalRooms.Period = RoomSales.Period) AS PerDayType";
			vQry.SetParameter("qHotel", Hotel);
			vQry.SetParameter("qRef", pmGetThisDocumentRef());
			vQry.SetParameter("qRoomType", ?(ValueIsFilled(RoomTypeUpgrade), RoomTypeUpgrade, vRoomType));
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
		|	-ISNULL(TotalRooms.RoomsBlockedClosingBalance, 0) AS TotalRoomsBlocked,
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
		vQry.SetParameter("qForecastPeriodTo", Max(pPeriodTo, EndOfDay(vForecastStartDate-24*3600)));
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
EndProcedure // pmFillOccupationPercents

// -----------------------------------------------------------------------------
Procedure pmClearOccupationPercents(pDate = Undefined) Export
	If ValueIsFilled(RoomRate) And 
	   (RoomRate.PriceTagType = Enums.PriceTagTypes.ByOccupancyPercentPerRoomType Or 
	    RoomRate.PriceTagType = Enums.PriceTagTypes.ByOccupancyPercentPerRoomClass Or 
	    RoomRate.PriceTagType = Enums.PriceTagTypes.ByOccupancyPercentPerRoomTypePerDayType) And 
		Not RoomRate.DoNotRefillOccupationPercentsAfterInHouseRoomChange Then
		If pDate = Undefined Then
			OccupationPercents.Clear();
			For Each vSrvRow In Services Do
				If Not vSrvRow.IsManualPrice Then
					vSrvRow.PriceTag = Undefined;
				EndIf;
			EndDo;
		Else
			i = 0;
			While i < OccupationPercents.Count() Do
				vOccupationPercentsRow = OccupationPercents.Get(i);
				If vOccupationPercentsRow.AccountingDate >= BegOfDay(pDate) Then
					vDate = vOccupationPercentsRow.AccountingDate;
					OccupationPercents.Delete(i);
					vSrvRows = Services.FindRows(New Structure("AccountingDate, IsInPrice", vDate, True));
					For Each vSrvRow In vSrvRows Do
						If Not vSrvRow.IsManualPrice Then
							vSrvRow.PriceTag = Undefined;
						EndIf;
					EndDo;
				Else
					i = i + 1;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
EndProcedure // pmClearOccupationPercents

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
			vDocObj.Room = Room;
			vDocObj.AdditionalProperties.Insert("LinksRestoreMode", True);
			vDocObj.Write(DocumentWriteMode.Posting);
		EndIf;
	EndIf;
EndProcedure // AttachDataScansDocument

// -----------------------------------------------------------------------------
Procedure AttachForeignerRegistryRecords()
	vDocRef = Documents.ClientDataScans.EmptyRef();
	If ValueIsFilled(Guest) And ValueIsFilled(GuestGroup) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	ForeignerRegistryRecords.Ref AS Ref
		|FROM
		|	Document.ForeignerRegistryRecord AS ForeignerRegistryRecords
		|WHERE
		|	ForeignerRegistryRecords.Posted
		|	AND ForeignerRegistryRecords.Hotel = &qHotel
		|	AND ForeignerRegistryRecords.ParentDoc.GuestGroup = &qGuestGroup
		|	AND (ForeignerRegistryRecords.ParentDoc <> &qThisDocRef
		|				AND ForeignerRegistryRecords.Guest = &qGuest
		|			OR ForeignerRegistryRecords.ParentDoc = &qThisDocRef
		|				AND ForeignerRegistryRecords.Guest <> &qGuest)
		|
		|ORDER BY
		|	ForeignerRegistryRecords.PointInTime DESC";
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qGuest", Guest);
		vQry.SetParameter("qGuestGroup", GuestGroup);
		vQry.SetParameter("qThisDocRef", Ref);
		vDocs = vQry.Execute().Unload();
		For Each vDocsRow In vDocs Do
			vDocObj = vDocsRow.Ref.GetObject();
			vDocObj.ParentDoc = Ref;
			If vDocs.IndexOf(vDocsRow) = 0 Then
				vDocObj.Room = Room;
			EndIf;
			vDocObj.AdditionalProperties.Insert("LinksRestoreMode", True);
			vDocObj.Write(DocumentWriteMode.Posting);
		EndDo;
	EndIf;
EndProcedure // AttachForeignerRegistryRecords

// -----------------------------------------------------------------------------
Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	If AdditionalProperties.Property("CheckedAttributes") Then
		For Each vId In AdditionalProperties.CheckedAttributes Do
			CheckedAttributes.Add(vId);       
		EndDo;	
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
// Finishes pending orders after check-out
// -----------------------------------------------------------------------------
Procedure FinishBoundOrders()
	If ValueIsFilled(AccommodationStatus) AND Not AccommodationStatus.IsInHouse AND AccommodationStatus.IsCheckOut Then
		vQry = New Query("SELECT
		                 |	Orders.Ref AS Ref
		                 |FROM
		                 |	Document.Order AS Orders
		                 |WHERE
		                 |	NOT Orders.DeletionMark
		                 |	AND ISNULL(Orders.Type.CloseOrdersAtCheckout, FALSE)
		                 |	AND NOT ISNULL(Orders.Status.isOrderCancel, FALSE)
		                 |	AND NOT ISNULL(Orders.Status.isOrderComplete, FALSE)
		                 |	AND (Orders.ParentDoc = &qParentDoc
		                 |			OR Orders.ParentDoc = &qReservation)
		                 |
		                 |ORDER BY
		                 |	Orders.PointInTime");
		vQry.SetParameter("qParentDoc", Ref);
		vQry.SetParameter("qReservation", Reservation);
		vOrders = vQry.Execute().Select();
		While vOrders.Next() Do
			vOrderObj = vOrders.Ref.GetObject();
			vOrderObj.Status = Catalogs.OrderStatuses.Complete;
			vOrderObj.AdditionalProperties.Insert("SkipIfModificationIsAllowedCheck", True);
			vOrderObj.Write(DocumentWriteMode.Write);
		EndDo;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)   
	If DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // OnWrite

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
	
	If ValueIsFilled(vOldPriceCalculationDate) Then
		vBegOfRefCheckInDate = '00010101';
		vBegOfRefCheckOutDate = '00010101';
		If ValueIsFilled(Ref) Then
			vBegOfRefCheckInDate = BegOfDay(Ref.CheckInDate);
			vBegOfRefCheckOutDate = BegOfDay(Ref.CheckOutDate);
		ElsIf ValueIsFilled(Reservation) Then
			vBegOfRefCheckInDate = BegOfDay(Reservation.CheckInDate);
			vBegOfRefCheckOutDate = BegOfDay(Reservation.CheckOutDate);
		EndIf;
	
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
EndProcedure // pmUpdatePriceCalculationDate

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

// -----------------------------------------------------------------------------
StatusHasChanged = False;
HotelAccountingDate = '00010101';
CheckAccountingDate = False;
BegOfCheckInDate = '00010101';
WriteOffAllotmentLateCheckOutAndEarlyCheckInFromFreeSaleVacantRooms = True;