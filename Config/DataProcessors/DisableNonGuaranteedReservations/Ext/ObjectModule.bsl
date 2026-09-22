	
#Region Public

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
		PeriodToKeepReservations = 60;
	EndIf;
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	// Cancel non guaranteed reservations
	pmCancelNonGuaranteedReservations(pIsInteractive);
EndProcedure // pmRun

// -----------------------------------------------------------------------------
Procedure pmCancelNonGuaranteedReservations(pIsInteractive = False) Export
	WriteLogEvent(NStr("en='DataProcessor.DisableNonGuaranteedReservations';ru='Обработка.СнятьНегарантированнуюБронь';de='DataProcessor.DisableNonGuaranteedReservations'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'"));
	// Check parameters
	If Not ValueIsFilled(NonGuaranteedReservationStatus) Then
		vMessage = NStr("ru='Не указан статус негарантированной брони!';
		                |de='Status einer nicht garantierten Reservierung ist nicht angegeben!';
						|en='Non guaranteed reservations status is not set!'");
		WriteLogEvent(NStr("en='DataProcessor.DisableNonGuaranteedReservations';ru='Обработка.СнятьНегарантированнуюБронь';de='DataProcessor.DisableNonGuaranteedReservations'"), EventLogLevel.Warning, ThisObject.Metadata(), Undefined, vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			Return;
		Else
			Raise vMessage;
		EndIf;
	EndIf;
	If Not ValueIsFilled(CanceledReservationStatus) Then
		vMessage = NStr("ru='Не указан статус отмененной брони!';
		                |de='Der Status einer gelöschten Reservierung ist nicht angegeben!';
						|en='Canceled reservations status is not set!'");
		WriteLogEvent(NStr("en='DataProcessor.DisableNonGuaranteedReservations';ru='Обработка.СнятьНегарантированнуюБронь';de='DataProcessor.DisableNonGuaranteedReservations'"), EventLogLevel.Warning, ThisObject.Metadata(), Undefined, vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			Return;
		Else
			Raise vMessage;
		EndIf;
	EndIf;
	If PeriodToKeepReservations <= 0 Then
		vMessage = NStr("ru='Не указан период удержания негарантированной брони в минутах!';
		                |de='Zeitraum für die Aufrechterhaltung einer nicht garantierten Reservierung in Minuten!'; 
						|en='Period to keep non guaranteed reservations in minutes is not set!'");
		WriteLogEvent(NStr("en='DataProcessor.DisableNonGuaranteedReservations';ru='Обработка.СнятьНегарантированнуюБронь';de='DataProcessor.DisableNonGuaranteedReservations'"), EventLogLevel.Warning, ThisObject.Metadata(), Undefined, vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			Return;
		Else
			Raise vMessage;
		EndIf;
	EndIf;
	// Calculate time to check reservation statuses
	vCheckTime = CurrentSessionDate() - 60 * PeriodToKeepReservations;
	// Get list of reservations to process
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInventory.Recorder AS Reservation
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventory
	|WHERE
	|	RoomInventory.ReservationStatus = &qNonGuaranteedReservationStatus 
	|	AND RoomInventory.Recorder.Date < &qCancellationDate " + 
		?(ValueIsFilled(Hotel), " AND RoomInventory.Hotel IN HIERARCHY (&qHotel)", "") + "
	|	AND (RoomInventory.BedsReserved > 0
	|			OR RoomInventory.AdditionalBedsReserved > 0
	|			OR RoomInventory.GuestsReserved > 0)
	|	AND RoomInventory.RecordType = &qExpense
	|
	|GROUP BY
	|	RoomInventory.Recorder
	|
	|ORDER BY
	|	RoomInventory.Recorder.PointInTime";
	vQry.SetParameter("qNonGuaranteedReservationStatus", NonGuaranteedReservationStatus);
	vQry.SetParameter("qCancellationDate", vCheckTime);
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qExpense", AccumulationRecordType.Expense);
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
			
			// Check non guaranteed reservation status set time
			vResObjState = GetChangeStatusReservationState(vReservationRef);
			If vResObjState <> Undefined Then
				If vResObjState.Period >= vCheckTime Then
					Continue;
				EndIf;
			EndIf;
			
			// Set reservation status
			vReservationObj.ReservationStatus = CanceledReservationStatus;
			vReservationObj.pmSetDoCharging();
			If (vReservationObj.ReservationStatus.DoNoShowCharging Or vReservationObj.ReservationStatus.DoLateAnnulationCharging) Then
				vReservationObj.pmCalculateServices();
			EndIf;
			vReservationObj.Write(DocumentWriteMode.Posting);
			// Save data to the document history
			vReservationObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			
			// Log current state
			vMessage = NStr("ru='Обработан документ: " + String(vReservationObj.Ref) + " - группа № " + TrimAll(vReservationObj.GuestGroup) + "'; 
			                |de='Document " + String(vReservationObj.Ref) + " - group N " + TrimAll(vReservationObj.GuestGroup) + " was processed'; 
			                |en='Document " + String(vReservationObj.Ref) + " - group N " + TrimAll(vReservationObj.GuestGroup) + " was processed'");
			WriteLogEvent(NStr("en='DataProcessor.DisableNonGuaranteedReservations';ru='Обработка.СнятьНегарантированнуюБронь';de='DataProcessor.DisableNonGuaranteedReservations'"), EventLogLevel.Information, ThisObject.Metadata(), vReservationObj.Ref, vMessage);
			If pIsInteractive Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
			EndIf;
		Except
			vMessage = ErrorDescription();
			WriteLogEvent(NStr("en='DataProcessor.DisableNonGuaranteedReservations';ru='Обработка.СнятьНегарантированнуюБронь';de='DataProcessor.DisableNonGuaranteedReservations'"), EventLogLevel.Warning, ThisObject.Metadata(), ?(vReservationObj = Undefined, Undefined, vReservationObj.Ref), vMessage);
			If pIsInteractive Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			EndIf;
		EndTry;
	EndDo;
	WriteLogEvent(NStr("en='DataProcessor.DisableNonGuaranteedReservations';ru='Обработка.СнятьНегарантированнуюБронь';de='DataProcessor.DisableNonGuaranteedReservations'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'"));
EndProcedure // pmCancelNonGuaranteedReservations

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function GetChangeStatusReservationState(pReservation)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	*
	|FROM
	|	InformationRegister.ReservationChangeHistory AS ReservationChangeHistory
	|WHERE
	|	ReservationChangeHistory.Reservation = &qReservation
	|	AND ReservationChangeHistory.ReservationStatus = &qReservationStatus
	|ORDER BY
	|	ReservationChangeHistory.Period";
	vQry.SetParameter("qReservation", pReservation);
	vQry.SetParameter("qReservationStatus", pReservation.ReservationStatus);
	vStates = vQry.Execute().Unload();
	If vStates.Count() > 0 Then
		Return vStates.Get(0);
	Else
		Return Undefined;
	EndIf;
EndFunction // GetChangeStatusReservationState

#EndRegion