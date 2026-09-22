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
		If Not ValueIsFilled(ReservedRoomStatus) And ValueIsFilled(Hotel.ReservedRoomStatus) Then
			ReservedRoomStatus = Hotel.ReservedRoomStatus;
		EndIf;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	// Manage reserved room statuses
	If ValueIsFilled(ReservedRoomStatus) Then
		pmManageReservedRoomStatuses(pIsInteractive);
	EndIf;
EndProcedure // pmRun

// -----------------------------------------------------------------------------
// Data processors framework end
// -----------------------------------------------------------------------------
	
// -----------------------------------------------------------------------------
Procedure pmManageReservedRoomStatuses(pIsInteractive = False) Export
	WriteLogEvent(NStr("en='DataProcessor.ManageReservedRoomStatuses';ru='Обработка.УправлениеСтатусамиЗабронированныхНомеров';de='DataProcessor.ManageReservedRoomStatuses'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'"));
	// Get list of rooms to process
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reservations.Room AS Room,
	|	MIN(Reservations.CheckInDate) AS CheckInDate
	|FROM
	|	AccumulationRegister.RoomInventory AS Reservations
	|WHERE
	|	Reservations.IsReservation
	|	AND Reservations.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND Reservations.Room <> &qEmptyRoom
	|	AND (Reservations.Hotel IN HIERARCHY (&qHotel)
	|			OR &qHotelIsEmpty)
	|	AND Reservations.CheckInDate >= &qBegOfCurrentDate
	|	AND Reservations.CheckInDate <= &qEndOfCurrentDate
	|	AND Reservations.Recorder.ReservationStatus.DoRoomStatusChange
	|	AND (Reservations.Room.RoomStatus = Reservations.Room.Owner.VacantRoomStatus
	|			OR ISNULL(Reservations.Room.RoomStatus.RoomIsVacantClear, FALSE))
	|
	|GROUP BY
	|	Reservations.Room
	|
	|ORDER BY
	|	Reservations.Room.SortCode";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qEmptyRoom", Catalogs.Rooms.EmptyRef());
	vQry.SetParameter("qBegOfCurrentDate", BegOfDay(CurrentSessionDate()));
	vQry.SetParameter("qEndOfCurrentDate", EndOfDay(CurrentSessionDate()));
	vRooms = vQry.Execute().Unload();
	For Each vRoomsRow In vRooms Do
		BeginTransaction(DataLockControlMode.Managed);
		Try
			vRoomObj = vRoomsRow.Room.GetObject();
			
			// Set room status to reserved
			vRoomStatusHasChanged = False;
			If ValueIsFilled(ReservedRoomStatus) Then
				vRoomObj.RoomStatus = ReservedRoomStatus;
				vRoomStatusHasChanged = True;
			EndIf;
			
			// Update room if necessary
			If vRoomStatusHasChanged Then
				vRoomObj.Write();
				
				// Add record to the room status change history
				vRoomObj.pmWriteToRoomStatusChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser, NStr("en = 'Automatically because room is reserved'; ru = 'Автоматически, т.к. номер на брони'; de = 'Automatisch, da das Zimmer reserviert ist'"));
				
				// Log current state
				vMessage = NStr("ru = 'Статус номера " + TrimAll(vRoomObj.Ref) + " установлен в " + TrimAll(vRoomObj.RoomStatus) + "'; 
				                |de = 'Zimmer: " + TrimAll(vRoomObj.Ref) + ", neu Status: " + TrimAll(vRoomObj.RoomStatus) + "'; 
				                |en = 'Room " + TrimAll(vRoomObj.Ref) + " status has been changed to " + TrimAll(vRoomObj.RoomStatus) + "'");
				WriteLogEvent(NStr("en='DataProcessor.ManageReservedRoomStatuses';ru='Обработка.УправлениеСтатусамиЗабронированныхНомеров';de='DataProcessor.ManageReservedRoomStatuses'"), EventLogLevel.Information, ThisObject.Metadata(), vRoomObj.Ref, vMessage);
				If pIsInteractive Then
					tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
				EndIf;
			EndIf;
			CommitTransaction();
		Except
			vMessage = ErrorDescription();
			WriteLogEvent(NStr("en='DataProcessor.ManageReservedRoomStatuses';ru='Обработка.УправлениеСтатусамиЗабронированныхНомеров';de='DataProcessor.ManageReservedRoomStatuses'"), EventLogLevel.Warning, ThisObject.Metadata(), vRoomsRow.Room, vMessage);
			If TransactionActive() Then
				RollbackTransaction();
			EndIf;
			If pIsInteractive Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			EndIf;
		EndTry;
	EndDo;
	WriteLogEvent(NStr("en='DataProcessor.ManageReservedRoomStatuses';ru='Обработка.УправлениеСтатусамиЗабронированныхНомеров';de='DataProcessor.ManageReservedRoomStatuses'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'"));
EndProcedure // pmManageReservedRoomStatuses
