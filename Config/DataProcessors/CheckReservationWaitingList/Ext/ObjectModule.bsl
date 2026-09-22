
#Region Public

// ----------------------------------------------------------------------------
//
// Parameters:
//  pParameter	 - Structure - Parameter 
//
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// ----------------------------------------------------------------------------
//
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

// ----------------------------------------------------------------------------
//  Initialize attributes with default values
//  Attention: This procedure could be called AFTER some attributes initialization
//  routine, so it SHOULD NOT reset attributes being set before
//  ----------------------------------------------------------------------------
//
Procedure pmFillAttributesWithDefaultValues() Export
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
		If ValueIsFilled(Hotel) Then
			ReservationDepartment = Hotel.ReservationDepartment;
		EndIf;
	EndIf;
EndProcedure //  pmFillAttributesWithDefaultValues

// ----------------------------------------------------------------------------
//  Run data processor in silent mode
//  ----------------------------------------------------------------------------
//
// Parameters:
//  pParameter		 - Null	 - Parameter
//  pIsInteractive	 - Boolean	 - Is interactive
//
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	// Check reservation waiting list
	pmCheck(pIsInteractive);
EndProcedure // pmRun

// ----------------------------------------------------------------------------
//
// Parameters:
//  pIsInteractive	 - Boolean	 - Is interactive
//
Procedure pmCheck(pIsInteractive = False) Export
	WriteLogEvent(NStr("en = 'DataProcessor.CheckReservationWaitingList'; de = 'DataProcessor.CheckReservationWaitingList'; ru = 'Обработка.ПроверкаЛистаОжиданияБрони'"), EventLogLevel.Information, Metadata(), Undefined, NStr("en = 'Start of processing'; de = 'Anfang der Ausführung'; ru = 'Начало выполнения'"));
	// Get up to date reservations in the waiting list
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ReservationWaitingList.Reservation AS Reservation,
	|	ReservationWaitingList.Rating AS Rating,
	|	ReservationWaitingList.Ready AS Ready
	|FROM
	|	InformationRegister.ReservationWaitingList AS ReservationWaitingList
	|WHERE
	|	ReservationWaitingList.Active
	|	AND (ReservationWaitingList.Reservation.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND ReservationWaitingList.Reservation.CheckInDate >= &qCurrentDate
	|	AND (ReservationWaitingList.Reservation.AccommodationType.Type = VALUE(Enum.AccomodationTypes.Room)
	|			OR ReservationWaitingList.Reservation.AccommodationType.Type = VALUE(Enum.AccomodationTypes.Beds))";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCurrentDate", CurrentSessionDate());
	vReservations = vQry.Execute().Unload();
	// Check notification transport type
	For Each vReservationsRow In vReservations Do 
		vReservationRef = vReservationsRow.Reservation;
		vNewReservationStatus = vReservationRef.Hotel.NewReservationStatus;
		If Not ValueIsFilled(vReservationRef) Then
			Continue;
		EndIf;
		If Not ValueIsFilled(vNewReservationStatus) Then
			Continue;
		EndIf;
		If Not vNewReservationStatus.IsActive Then
			Continue;
		EndIf;
		BeginTransaction(DataLockControlMode.Managed);
		Try
			// Change reservation status and try to post it
			vReservationObj = vReservationRef.GetObject();
			vReservationObj.ReservationStatus = vNewReservationStatus;
			vReservationObj.pmCalculateResources();
			vReservationObj.Write(DocumentWriteMode.Posting);
			// Check room quota inventory balances
			If ValueIsFilled(vReservationObj.RoomQuota) Then
				vMsgTextRu = "";
				vMsgTextEn = "";
				vMsgTextDe = "";
				If Not cmCheckRoomQuotaAvailability(vReservationObj.RoomQuota.Agent, vReservationObj.RoomQuota.Customer, vReservationObj.RoomQuota.Contract, vReservationObj.RoomQuota, 
				                                    vReservationObj.Hotel, vReservationObj.RoomType, vReservationObj.Room, vReservationObj.Ref, True, True,
				                                    vReservationObj.NumberOfRooms, vReservationObj.NumberOfBeds, 
				                                    cmMovePeriodFromToReferenceHour(vReservationObj.CheckInDate, vReservationObj.RoomRate), 
				                                    cmMovePeriodToToReferenceHour(vReservationObj.CheckOutDate, vReservationObj.RoomRate), 
				                                    vMsgTextRu, vMsgTextEn, vMsgTextDe, False) Then
					Raise NStr("ru = '" + TrimAll(vMsgTextRu) + "';" + "en = '" + TrimAll(vMsgTextEn) + "';" + "de = '" + TrimAll(vMsgTextDe) + "';");
				EndIf;
			EndIf;
			// Check room inventory balances
			If Not ValueIsFilled(vReservationObj.RoomQuota) Or ValueIsFilled(vReservationObj.Room) Then
				vMsgTextRu = "";
				vMsgTextEn = "";
				vMsgTextDe = "";
				If Not cmCheckRoomAvailability(vReservationObj.Hotel, vReservationObj.RoomQuota, vReservationObj.RoomType, vReservationObj.Room, vReservationObj.Ref, True, True,
				                               vReservationObj.NumberOfPersons, vReservationObj.NumberOfRooms, vReservationObj.NumberOfBeds, vReservationObj.NumberOfAdditionalBeds, 
				                               vReservationObj.NumberOfBedsPerRoom, vReservationObj.NumberOfPersonsPerRoom, Max(CurrentSessionDate(), vReservationObj.CheckInDate), vReservationObj.CheckOutDate, 
				                               vMsgTextRu, vMsgTextEn, vMsgTextDe, False, False, True) Then
					Raise NStr("ru = '" + TrimAll(vMsgTextRu) + "';" + "en = '" + TrimAll(vMsgTextEn) + "';" + "de = '" + TrimAll(vMsgTextDe) + "';");
				EndIf;
			EndIf;
			// Roll back transaction if all checks has passed
			RollbackTransaction();
			// Log current state
			vMessage = NStr("en='Reservation could be confirmed: ';ru='Бронь может быть подтверждена: ';de='Die Reservierung kann bestätigt werden: '") + Chars.LF +
			           Format(vReservationRef.GuestGroup.Code, "ND=12; NFD=0; NG=") + ", " +
			           Format(vReservationRef.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(vReservationRef.CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ", " +
			           TrimAll(vReservationRef.RoomType) + ", " + TrimAll(vReservationRef.Room) + Chars.LF +
			           TrimAll(vReservationRef.Hotel) + " / " + TrimAll(vReservationRef.Author);
			WriteLogEvent(NStr("en = 'DataProcessor.CheckReservationWaitingList'; de = 'DataProcessor.CheckReservationWaitingList'; ru = 'Обработка.ПроверкаЛистаОжиданияБрони'"), EventLogLevel.Information, Metadata(), vReservationRef, vMessage);
			If pIsInteractive Then
				tcCommonFunctionOnClientServer.UserMessage(vMessage);
			EndIf;
			// Update current waiting list record status
			UpdateWaitingListRecordStatus(vReservationRef);
			// Write notification message
			If ValueIsFilled(ReservationDepartment) Then
				If CheckMessageToDepartment(ReservationDepartment, vReservationRef, "%" + vMessage + "%") Then
					cmSendMessageToDepartment(ReservationDepartment, vMessage, Undefined, True, vReservationRef);
				EndIf;
			EndIf;
		Except
			vMessage = cmGetRootErrorDescription(ErrorInfo());
			If TransactionActive() Then
				RollbackTransaction();
			EndIf; 
			UpdateWaitingListRecordStatus(vReservationRef, False); 
			CloseMessageToDepartment(ReservationDepartment, vReservationRef, "%" + vMessage + "%");
			WriteLogEvent(NStr("en = 'DataProcessor.CheckReservationWaitingList'; de = 'DataProcessor.CheckReservationWaitingList'; ru = 'Обработка.ПроверкаЛистаОжиданияБрони'"), EventLogLevel.Information, Metadata(), vReservationRef, vMessage);
			// Exit
			If pIsInteractive Then
				tcCommonFunctionOnClientServer.UserMessage(vMessage);
			EndIf;
		EndTry;
	EndDo;
	WriteLogEvent(NStr("en = 'DataProcessor.CheckReservationWaitingList'; de = 'DataProcessor.CheckReservationWaitingList'; ru = 'Обработка.ПроверкаЛистаОжиданияБрони'"), EventLogLevel.Information, Metadata(), Undefined, NStr("en = 'End of processing'; de = 'Ende des Ausführung'; ru = 'Конец выполнения'"));
EndProcedure // pmCheck

#EndRegion

#Region Private

// ----------------------------------------------------------------------------
Function CheckMessageToDepartment(pReservationDepartment, pReservation, pMessage)
	vQ = New Query();
	vQ.Text = 
	"SELECT
	|	Message.Ref AS Ref
	|FROM
	|	Document.Message AS Message
	|WHERE
	|	Message.Posted
	|	AND NOT Message.DeletionMark
	|	AND NOT Message.IsClosed
	|	AND Message.ByObject = &qByObject
	|	AND Message.ForDepartment = &qForDepartment
	|	AND Message.Remarks LIKE &qRemarks";
	vQ.SetParameter("qByObject", pReservation);
	vQ.SetParameter("qForDepartment", pReservationDepartment);
	vQ.SetParameter("qRemarks", TrimAll(pMessage));
	Return vQ.Execute().IsEmpty();
EndFunction // CheckMessageToDepartment

// ----------------------------------------------------------------------------
Procedure CloseMessageToDepartment(pReservationDepartment, pReservation, pMessage)
	vQ = New Query(); 
	vQ.Text = 
	"SELECT
	|	Message.Ref AS Ref
	|FROM
	|	Document.Message AS Message
	|WHERE
	|	Message.Posted
	|	AND NOT Message.DeletionMark
	|	AND NOT Message.IsClosed
	|	AND Message.ByObject = &qByObject
	|	AND Message.ForDepartment = &qForDepartment
	|	AND Message.Remarks LIKE &qRemarks";
	vQ.SetParameter("qByObject", pReservation);
	vQ.SetParameter("qForDepartment", pReservationDepartment);
	vQ.SetParameter("qRemarks", TrimAll(pMessage));
	vMessages = vQ.Execute().Unload();
	For Each vMessage In vMessages Do
		vMsgObj = vMessage.Ref.GetObject();
		vMsgObj.IsClosed = True;
		vMsgObj.PopUp = False;
		vMsgObj.Remarks = vMsgObj.Remarks + Chars.LF + Format(CurrentSessionDate(), "DF='dd.MM.yyyy HH:mm:ss'") + NStr("en = ' Not available rooms'; de = 'Nicht verfügbare Zimmer'; ru = 'Нет свободных номеров'");
		vMsgObj.Write(DocumentWriteMode.Posting);
	EndDo;
EndProcedure // DeleteMessageToDepartment

// ----------------------------------------------------------------------------
Procedure UpdateWaitingListRecordStatus(pReservation, pReady = True)
	// Update current attachment status
	vSet = InformationRegisters.ReservationWaitingList.CreateRecordSet();
	vSet.Filter.Recorder.Value = pReservation;
	vSet.Filter.Recorder.ComparisonType = ComparisonType.Equal;
	vSet.Filter.Recorder.Use = True;
	vSet.Read();
	For Each vSetRow In vSet Do
		vSetRow.Ready = pReady;
	EndDo;
	vSet.Write();
EndProcedure //  UpdateWaitingListRecordStatus

#EndRegion
