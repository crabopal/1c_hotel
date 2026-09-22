// -----------------------------------------------------------------------------
// Data processors framework start
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

// -----------------------------------------------------------------------------
// Initialize attributes with default values
// Attention: This procedure could be called AFTER some attributes initialization
// routine, so it SHOULD NOT reset attributes being set before
// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(Hotel) Then
		If Not ValueIsFilled(OccupiedDirtyRoomStatus) And ValueIsFilled(Hotel.OccupiedDirtyRoomStatus) Then
			OccupiedDirtyRoomStatus = Hotel.OccupiedDirtyRoomStatus;
		EndIf;
		If Not ValueIsFilled(OccupiedDueOutRoomStatus) And ValueIsFilled(Hotel.RoomStatusDueOut) Then
			OccupiedDueOutRoomStatus = Hotel.RoomStatusDueOut;
		EndIf;
		If Not ValueIsFilled(RoomStatusAfterEarlyCheckIn) And ValueIsFilled(Hotel.RoomStatusAfterEarlyCheckIn) Then
			RoomStatusAfterEarlyCheckIn = Hotel.RoomStatusAfterEarlyCheckIn;
			If Not ValueIsFilled(EarlyCheckInTime) Then
				EarlyCheckInTime = '00010101' + 6 * 3600; // Set to the 06:00
			EndIf;
		EndIf;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	// Manage occupied room statuses
	pmManageOccupiedRoomStatuses(pIsInteractive);
EndProcedure // pmRun

// -----------------------------------------------------------------------------
// Data processors framework end
// -----------------------------------------------------------------------------
	
// -----------------------------------------------------------------------------
Procedure pmManageOccupiedRoomStatuses(pIsInteractive = False) Export
	WriteLogEvent(NStr("en='DataProcessor.ManageOccupiedRoomStatuses';ru='Обработка.УправлениеСтатусамиЗанятыхНомеров';de='DataProcessor.ManageOccupiedRoomStatuses'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'"));
	// Get list of rooms to process
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodations.Room AS Room,
	|	MIN(Accommodations.PeriodFrom) AS CheckInDate,
	|	MAX(Accommodations.PeriodTo) AS CheckOutDate
	|FROM
	|	AccumulationRegister.RoomInventory AS Accommodations
	|WHERE
	|	Accommodations.IsAccommodation
	|	AND Accommodations.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND Accommodations.IsInHouse
	|	AND (Accommodations.Hotel IN HIERARCHY (&qHotel)
	|			OR &qHotelIsEmpty)
	|	AND Accommodations.CheckInDate <= &qCurrentDate
	|	AND Accommodations.CheckOutDate > &qCurrentDate
	|	AND NOT ISNULL(Accommodations.Room.RoomType.RoomsShouldNotBeClearedRegularly, FALSE)
	|
	|GROUP BY
	|	Accommodations.Room
	|
	|HAVING
	|	MIN(Accommodations.PeriodFrom) <= &qCurrentDate AND
	|	MAX(Accommodations.PeriodTo) > &qCurrentDate
	|
	|ORDER BY
	|	Accommodations.Room.SortCode";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCurrentDate", CurrentSessionDate());
	vRooms = vQry.Execute().Unload();
	For Each vRoomsRow In vRooms Do
		vRoom = vRoomsRow.Room;
		vRoomType = vRoom.RoomType;
		
		BeginTransaction(DataLockControlMode.Managed);
		Try
			vRoomObj = vRoom.GetObject();
			
			// Set room status to occupied/dirty
			vRoomStatusHasChanged = False;
			If ValueIsFilled(OccupiedDirtyRoomStatus) Or ValueIsFilled(RoomStatusAfterEarlyCheckIn) Or ValueIsFilled(OccupiedDueOutRoomStatus) Then
				If ValueIsFilled(vRoomsRow.CheckInDate) Then
					If ValueIsFilled(RoomStatusAfterEarlyCheckIn) And BegOfDay(vRoomsRow.CheckInDate) = BegOfDay(CurrentSessionDate()) And
					   vRoomsRow.CheckInDate < (BegOfDay(CurrentSessionDate()) + (EarlyCheckInTime - BegOfDay(EarlyCheckInTime))) Then
						vRoomObj.RoomStatus = RoomStatusAfterEarlyCheckIn;
						vRoomStatusHasChanged = True;
					ElsIf ValueIsFilled(OccupiedDueOutRoomStatus) And BegOfDay(vRoomsRow.CheckOutDate) = BegOfDay(CurrentSessionDate()) And OccupiedDirtyRoomStatus <> OccupiedDueOutRoomStatus Then
						// Check that there is no period of stay extension reservation
						vDoChangeRoomStatus = False;
						vThereIsPeriodOfStayExtension = False;
						vRoomAccs = cmGetRoomGuests(vRoomObj.Owner, Undefined, vRoomObj.Ref, vRoomsRow.CheckInDate, vRoomsRow.CheckOutDate, Undefined);
						For Each vRoomAccsRow In vRoomAccs Do
							vAccRef = vRoomAccsRow.Accommodation;
							If Not vAccRef.AccommodationStatus.IsInHouse Then
								Continue;
							EndIf;
							If vAccRef.AccommodationType.Type = Enums.AccomodationTypes.Room Or 
							   vAccRef.AccommodationType.Type = Enums.AccomodationTypes.Beds And vAccRef.Hotel.SetRoomStatusAfterCheckOutForBeds Then
								If BegOfDay(vAccRef.CheckOutDate) = BegOfDay(CurrentSessionDate()) Then
									vNextRes = GetNextReservationInChain(vAccRef, vRoom, vRoomType);
									If Not ValueIsFilled(vNextRes) Then
										vDoChangeRoomStatus = True;
										Break;
									Else
										If BegOfDay(vNextRes.CheckOutDate) <= BegOfDay(CurrentSessionDate()) Then
											vDoChangeRoomStatus = True;
											Break;
										Else
											vThereIsPeriodOfStayExtension = True;
										EndIf;
									EndIf;
								EndIf;
							EndIf;
						EndDo;
						If vDoChangeRoomStatus Then
							vRoomObj.RoomStatus = OccupiedDueOutRoomStatus;
							vRoomStatusHasChanged = True;
						ElsIf vThereIsPeriodOfStayExtension Then
							If ValueIsFilled(OccupiedDirtyRoomStatus) And BegOfDay(vRoomsRow.CheckInDate) < BegOfDay(CurrentSessionDate()) Then
								vRoomObj.RoomStatus = OccupiedDirtyRoomStatus;
								vRoomStatusHasChanged = True;
							EndIf;
						EndIf;
					ElsIf ValueIsFilled(OccupiedDirtyRoomStatus) And BegOfDay(vRoomsRow.CheckInDate) < BegOfDay(CurrentSessionDate()) Then
						vRoomObj.RoomStatus = OccupiedDirtyRoomStatus;
						vRoomStatusHasChanged = True;
					EndIf;
				EndIf;
			EndIf;
			
			// Update room if necessary
			If vRoomStatusHasChanged Then
				vRoomObj.Write();
				
				// Add record to the room status change history
				vRoomObj.pmWriteToRoomStatusChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser, NStr("en = 'Automatically because room is in-use'; ru = 'Автоматически, т.к. номер занят'; de = 'Automatisch, da die Nummer belegt ist'"), True);
				
				// Log current state
				vMessage = NStr("ru = 'Статус номера " + TrimAll(vRoomObj.Ref) + " установлен в " + TrimAll(vRoomObj.RoomStatus) + "'; 
				                |de = 'Zimmer: " + TrimAll(vRoomObj.Ref) + ", neu Status: " + TrimAll(vRoomObj.RoomStatus) + "'; 
				                |en = 'Room " + TrimAll(vRoomObj.Ref) + " status has been changed to " + TrimAll(vRoomObj.RoomStatus) + "'");
				WriteLogEvent(NStr("en='DataProcessor.ManageOccupiedRoomStatuses';ru='Обработка.УправлениеСтатусамиЗанятыхНомеров';de='DataProcessor.ManageOccupiedRoomStatuses'"), EventLogLevel.Information, ThisObject.Metadata(), vRoomObj.Ref, vMessage);
				If pIsInteractive Then
					tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
				EndIf;
			EndIf;
			CommitTransaction();
		Except
			vMessage = ErrorDescription();
			WriteLogEvent(NStr("en='DataProcessor.ManageOccupiedRoomStatuses';ru='Обработка.УправлениеСтатусамиЗанятыхНомеров';de='DataProcessor.ManageOccupiedRoomStatuses'"), EventLogLevel.Warning, ThisObject.Metadata(), vRoom, vMessage);
			If TransactionActive() Then
				RollbackTransaction();
			EndIf;
			If pIsInteractive Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			EndIf;
		EndTry;
	EndDo;
	WriteLogEvent(NStr("en='DataProcessor.ManageOccupiedRoomStatuses';ru='Обработка.УправлениеСтатусамиЗанятыхНомеров';de='DataProcessor.ManageOccupiedRoomStatuses'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'"));
EndProcedure // pmManageOccupiedRoomStatuses

// -----------------------------------------------------------------------------
Function GetNextReservationInChain(pAccRef, pRoom, pRoomType)
	vNextRes = Undefined;
	If ValueIsFilled(pAccRef.Reservation) Then
		vResObj = pAccRef.Reservation.GetObject();
		vNextRes = vResObj.pmGetNextReservationInChain();
	EndIf;
	If Not ValueIsFilled(vNextRes) And ValueIsFilled(pAccRef.Guest) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT TOP 1
		|	Reservation.Ref AS Ref
		|FROM
		|	Document.Reservation AS Reservation
		|WHERE
		|	Reservation.Guest = &qGuest
		|	AND BEGINOFPERIOD(Reservation.CheckInDate, DAY) = &qDate
		|	AND (Reservation.ReservationStatus.IsActive
		|			OR Reservation.ReservationStatus.IsPreliminary)
		|	AND Reservation.Posted";
		vQry.SetParameter("qGuest", pAccRef.Guest);
		vQry.SetParameter("qDate", BegOfDay(pAccRef.CheckOutDate));
		vDocs = vQry.Execute().Unload();
		If vDocs.Count() > 0 Then
			vNextRes = vDocs.Get(0).Ref;
		EndIf;
	EndIf;
	If ValueIsFilled(vNextRes) Then
		If ValueIsFilled(vNextRes.Room) And vNextRes.Room <> pRoom Then
			vNextRes = Undefined;
		ElsIf Not ValueIsFilled(vNextRes.Room) And vNextRes.RoomType <> pRoomType Then
			vNextRes = Undefined;
		EndIf;
	EndIf;
	Return vNextRes;
EndFunction // GetNextReservationInChain
