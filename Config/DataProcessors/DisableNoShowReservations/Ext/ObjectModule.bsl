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
	If PeriodToKeepReservations = 0 Then
		PeriodToKeepReservations = 12;
	EndIf;
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(Hotel) Then
		PeriodToKeepReservations = Hotel.PeriodToKeepReservations;
		NoShowReservationStatus = Hotel.NoShowReservationStatus;
	EndIf;
	NoShowDate = CurrentSessionDate() - PeriodToKeepReservations*3600;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	// Disable reservations
	pmDisableNoShowReservations(pIsInteractive);
EndProcedure // pmRun

// -----------------------------------------------------------------------------
// Data processors framework end
// -----------------------------------------------------------------------------
	
// -----------------------------------------------------------------------------
Procedure pmDisableNoShowReservations(pIsInteractive = False) Export
	WriteLogEvent(NStr("en='DataProcessor.DisableNoShowReservations';ru='Обработка.СнятиеПросроченнойБрони';de='DataProcessor.DisableNoShowReservations'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'"));
	// Check parameters
	If Not ValueIsFilled(NoShowReservationStatus) Then
		vMessage = NStr("ru='Не указан статус просроченной брони!';
		                |de='Der Status einer überzogenen Reservierung ist nicht angegeben!'; 
						|en='No show reservation status is not set!'");
		WriteLogEvent(NStr("en='DataProcessor.DisableNoShowReservations';ru='Обработка.СнятиеПросроченнойБрони';de='DataProcessor.DisableNoShowReservations'"), EventLogLevel.Warning, ThisObject.Metadata(), Undefined, vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			Return;
		Else
			Raise vMessage;
		EndIf;
	EndIf;
	If Not ValueIsFilled(NoShowDate) Then
		vMessage = NStr("ru='Не указана дата просроченной брони!';
		                |de='Das Datum der überzogenen Reservierung ist nicht angegeben!';
						|en='No show reservation date is not set!'");
		WriteLogEvent(NStr("en='DataProcessor.DisableNoShowReservations';ru='Обработка.СнятиеПросроченнойБрони';de='DataProcessor.DisableNoShowReservations'"), EventLogLevel.Warning, ThisObject.Metadata(), Undefined, vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			Return;
		Else
			Raise vMessage;
		EndIf;
	EndIf;
	// Get list of reservations to process
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reservations.Ref AS Reservation
	|FROM
	|	Document.Reservation AS Reservations
	|WHERE
	|	(Reservations.CheckInDate <= &qNoShowDate
	|				AND Reservations.WaitTillDate = &qEmptyDate
	|			OR Reservations.WaitTillDate > Reservations.CheckInDate
	|				AND Reservations.WaitTillDate <= &qCurrentDate
	|				AND Reservations.WaitTillDate > &qEmptyDate
	|			OR &qProcessExpiredBlockReservations
	|				AND Reservations.RoomQuantity > 1
	|				AND Reservations.ReservationStatus <> &qWaitTillDateIsExpiredReservationStatus
	|				AND Reservations.WaitTillDate < Reservations.CheckInDate
	|				AND Reservations.WaitTillDate <= &qCurrentDate
	|				AND Reservations.WaitTillDate > &qEmptyDate)
	|	AND (&qHotelIsFilled
	|				AND Reservations.Hotel IN HIERARCHY (&qHotel)
	|			OR NOT &qHotelIsFilled)
	|	AND (Reservations.ReservationStatus.IsActive
	|			OR Reservations.ReservationStatus.IsPreliminary)
	|	AND (Reservations.ReservationStatus = &qReservationStatus
	|			OR &qReservationStatusIsEmpty)
	|	AND Reservations.ReservationStatus <> &qNoShowReservationStatus
	|	AND NOT Reservations.RoomType.IsVirtual
	|	AND NOT ISNULL(Reservations.Room.IsVirtual, FALSE)
	|	AND Reservations.Posted
	|
	|ORDER BY
	|	Reservations.PointInTime";
	vQry.SetParameter("qNoShowDate", NoShowDate);
	vQry.SetParameter("qEmptyDate", Date('00010101'));
	vQry.SetParameter("qCurrentDate", CurrentSessionDate());
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsFilled", ValueIsFilled(Hotel));
	vQry.SetParameter("qExpense", AccumulationRecordType.Expense);
	vQry.SetParameter("qReservationStatus", ReservationStatus);
	vQry.SetParameter("qReservationStatusIsEmpty", Not ValueIsFilled(ReservationStatus));
	vQry.SetParameter("qProcessExpiredBlockReservations", ValueIsFilled(WaitTillDateIsExpiredReservationStatus));
	vQry.SetParameter("qWaitTillDateIsExpiredReservationStatus", WaitTillDateIsExpiredReservationStatus);
	vQry.SetParameter("qNoShowReservationStatus", NoShowReservationStatus);
	vReservations = vQry.Execute().Unload();
	// Change reservation status for each reservation and post it
	For Each vReservationsRow In vReservations Do
		Try
			vReservationRef = vReservationsRow.Reservation;
			vReservationObj = Undefined;
			vReservationObj = vReservationRef.GetObject();
			If TypeOf(vReservationObj.Ref) <> Type("DocumentRef.Reservation") Then
				Continue;
			EndIf;
			
			// Build list of reservation charges
			vCharges = New ValueTable();
			If DeleteFolioCharges Then
				vCharges = cmGetDocumentCharges(vReservationRef, vReservationRef.Customer, vReservationRef.Contract, vReservationRef.Hotel, Undefined, True);
			EndIf;				
			
			// Set reservation status
			If ValueIsFilled(WaitTillDateIsExpiredReservationStatus) And ValueIsFilled(vReservationObj.WaitTillDate) And vReservationObj.WaitTillDate < vReservationObj.CheckInDate And vReservationObj.ReservationStatus <> WaitTillDateIsExpiredReservationStatus And vReservationObj.RoomQuantity > 1 Then
				vReservationObj.ReservationStatus = WaitTillDateIsExpiredReservationStatus;
				vReservationObj.pmSetDoCharging();
			Else
				vReservationObj.ReservationStatus = NoShowReservationStatus;
				vReservationObj.pmSetDoCharging();
				If ValueIsFilled(PartialNoShowReservationStatus) Then
					// Check if there is checked-in guests for this reservation
					vAccommodations = vReservationObj.pmGetAccommodations();
					If vAccommodations.Count() > 0 And vReservationObj.NumberOfPersons > vAccommodations.Count() Then
						vReservationObj.ReservationStatus = PartialNoShowReservationStatus;
						vReservationObj.pmSetDoCharging();
					EndIf;
				EndIf;
			EndIf;
			If (vReservationObj.ReservationStatus.DoNoShowCharging Or vReservationObj.ReservationStatus.DoLateAnnulationCharging) Then
				vReservationObj.pmCalculateServices();
			EndIf;
			vReservationObj.Write(DocumentWriteMode.Posting);
			// Save data to the document history
			vReservationObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			
			// Delete charges found before cancelling reservation
			If DeleteFolioCharges Then
				For Each vChargesRow In vCharges Do
					If vChargesRow.Recorder.Posted Then
						vChargesRow.Recorder.GetObject().SetDeletionMark(True);
					EndIf;
				EndDo;
			EndIf;			
			
			// Log current state
			vMessage = NStr("ru='Обработан документ: " + String(vReservationObj.Ref) + " - группа № " + TrimAll(vReservationObj.GuestGroup) + "'; 
			                |de='Document " + String(vReservationObj.Ref) + " - group N " + TrimAll(vReservationObj.GuestGroup) + " was processed'; 
			                |en='Document " + String(vReservationObj.Ref) + " - group N " + TrimAll(vReservationObj.GuestGroup) + " was processed'");
			WriteLogEvent(NStr("en='DataProcessor.DisableNoShowReservations';ru='Обработка.СнятиеПросроченнойБрони';de='DataProcessor.DisableNoShowReservations'"), EventLogLevel.Information, ThisObject.Metadata(), vReservationObj.Ref, vMessage);
			If pIsInteractive Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
			EndIf;
		Except
			vMessage = ErrorDescription();
			WriteLogEvent(NStr("en='DataProcessor.DisableNoShowReservations';ru='Обработка.СнятиеПросроченнойБрони';de='DataProcessor.DisableNoShowReservations'"), EventLogLevel.Warning, ThisObject.Metadata(), ?(vReservationObj = Undefined, Undefined, vReservationObj.Ref), vMessage);
			If pIsInteractive Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			EndIf;
		EndTry;
	EndDo;
	WriteLogEvent(NStr("en='DataProcessor.DisableNoShowReservations';ru='Обработка.СнятиеПросроченнойБрони';de='DataProcessor.DisableNoShowReservations'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'"));
EndProcedure // pmDisableNoShowReservations
