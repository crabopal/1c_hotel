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
	If PeriodToWait = 0 Then
		PeriodToWait = 1;
	EndIf;
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	// Try to find active resource reservation status with both "Do charging" and 
	// "Services are delivered" flags checked
	If Not ValueIsFilled(FinishedResourceReservationStatus) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT TOP 1
		|	ResourceReservationStatuses.Ref
		|FROM
		|	Catalog.ResourceReservationStatuses AS ResourceReservationStatuses
		|WHERE
		|	(NOT ResourceReservationStatuses.DeletionMark)
		|	AND (NOT ResourceReservationStatuses.IsFolder)
		|	AND ResourceReservationStatuses.IsActive
		|	AND ResourceReservationStatuses.DoCharging
		|	AND ResourceReservationStatuses.ServicesAreDelivered";
		vStses = vQry.Execute().Unload();
		If vStses.Count() > 0 Then
			FinishedResourceReservationStatus = vStses.Get(0).Ref;
		EndIf;
	EndIf;
	// Set processing date time
	ProcessingDateTime = CurrentSessionDate() - PeriodToWait*3600;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	// Process finished resource reservations
	pmProcessFinishedResourceReservations(pIsInteractive);
EndProcedure // pmRun

// -----------------------------------------------------------------------------
// Data processors framework end
// -----------------------------------------------------------------------------
	
// -----------------------------------------------------------------------------
Procedure pmProcessFinishedResourceReservations(pIsInteractive = False) Export
	WriteLogEvent(NStr("en='DataProcessor.ProcessFinishedResourceReservations';ru='Обработка.ОбработкаЗавершеннойБрониРесурсов';de='DataProcessor.ProcessFinishedResourceReservations'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'"));
	// Check parameters
	WriteLogEvent(NStr("en='DataProcessor.ProcessFinishedResourceReservations';ru='Обработка.ОбработкаЗавершеннойБрониРесурсов';de='DataProcessor.ProcessFinishedResourceReservations'"), EventLogLevel.Information, ThisObject.Metadata(), FinishedResourceReservationStatus, NStr("en='Hotel: ';ru='Гостиница: ';de='Hotel: '") + TrimAll(Hotel));
	If Not ValueIsFilled(FinishedResourceReservationStatus) Then
		vMessage = NStr("ru='Не указан статус завершенной брони!';
		                |de='Der Status einer abgeschlossenen Reservierung ist nicht angegeben!';
						|en='Finished resource reservation status is not set!'");
		WriteLogEvent(NStr("en='DataProcessor.ProcessFinishedResourceReservations';ru='Обработка.ОбработкаЗавершеннойБрониРесурсов';de='DataProcessor.ProcessFinishedResourceReservations'"), EventLogLevel.Warning, ThisObject.Metadata(), Undefined, vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			Return;
		Else
			Raise vMessage;
		EndIf;
	Else
		WriteLogEvent(NStr("en='DataProcessor.ProcessFinishedResourceReservations';ru='Обработка.ОбработкаЗавершеннойБрониРесурсов';de='DataProcessor.ProcessFinishedResourceReservations'"), EventLogLevel.Information, ThisObject.Metadata(), FinishedResourceReservationStatus, NStr("en='Finished resource reservation status: ';ru='Статус завершенной брони: ';de='Status der abgeschlossenen Reservierung: '") + TrimAll(FinishedResourceReservationStatus));
	EndIf;
	If Not ValueIsFilled(ProcessingDateTime) Then
		vMessage = NStr("ru='Не указана дата, на которую считать бронь завершенной!';
		                |de='Das Datum, an dem die Reservierung als abgeschlossen betrachtet werden kann, ist nicht angegeben!'; 
						|en='Finished resource reservation date is not set!'");
		WriteLogEvent(NStr("en='DataProcessor.ProcessFinishedResourceReservations';ru='Обработка.ОбработкаЗавершеннойБрониРесурсов';de='DataProcessor.ProcessFinishedResourceReservations'"), EventLogLevel.Warning, ThisObject.Metadata(), Undefined, vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			Return;
		Else
			Raise vMessage;
		EndIf;
	Else
		WriteLogEvent(NStr("en='DataProcessor.ProcessFinishedResourceReservations';ru='Обработка.ОбработкаЗавершеннойБрониРесурсов';de='DataProcessor.ProcessFinishedResourceReservations'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Finished resource reservation date and time: ';ru='Дата и время на которые считать бронь завершенной: ';de='Datum und Zeit, zu denen die Reservierung als abgeschlossen gelten kann: '") + Format(ProcessingDateTime, "DF='dd.MM.yyyy HH:mm'"));
	EndIf;
	// Get list of resource reservations to process
	vQry = New Query();
	vQry.Text = 
	"SELECT DISTINCT
	|	ResourceReservations.Ref AS ResourceReservation,
	|	ResourceReservations.Ref.PointInTime AS PointInTime
	|FROM
	|	Document.ResourceReservation AS ResourceReservations
	|WHERE
	|	ResourceReservations.Posted
	|	AND NOT ResourceReservations.ResourceReservationStatus.ServicesAreDelivered
	|	AND ResourceReservations.ResourceReservationStatus.IsActive
	|	AND ResourceReservations.Ref.DateTimeTo <= &qProcessingDateTime
	|	AND ResourceReservations.ResourceReservationStatus <> &qFinishedResourceReservationStatus
	|	AND (ResourceReservations.Hotel IN HIERARCHY (&qHotel)
	|			OR &qHotelIsEmpty)
	|
	|ORDER BY
	|	ResourceReservations.Ref.PointInTime";
	vQry.SetParameter("qProcessingDateTime", ProcessingDateTime);
	vQry.SetParameter("qFinishedResourceReservationStatus", FinishedResourceReservationStatus);
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vReservations = vQry.Execute().Unload();
	// Change reservation status for each reservation and post it
	For Each vReservationsRow In vReservations Do
		Try
			vReservationObj = vReservationsRow.ResourceReservation.GetObject();
			If TypeOf(vReservationObj.Ref) <> Type("DocumentRef.ResourceReservation") Then
				Continue;
			EndIf;
			vReservationObj.ResourceReservationStatus = FinishedResourceReservationStatus;
			vReservationObj.DoCharging = FinishedResourceReservationStatus.DoCharging;
			vReservationObj.Write(DocumentWriteMode.Posting);
			// Save data to the document history
			vReservationObj.pmWriteToResourceReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			
			// Log current state
			vMessage = NStr("ru = 'Обработан документ: " + String(vReservationObj.Ref) + " - группа № " + TrimAll(vReservationObj.GuestGroup) + "'; 
			                |de = 'Document " + String(vReservationObj.Ref) + " - group N " + TrimAll(vReservationObj.GuestGroup) + " was processed'; 
			                |en = 'Document " + String(vReservationObj.Ref) + " - group N " + TrimAll(vReservationObj.GuestGroup) + " was processed'");
			WriteLogEvent(NStr("en='DataProcessor.ProcessFinishedResourceReservations';ru='Обработка.ОбработкаЗавершеннойБрониРесурсов';de='DataProcessor.ProcessFinishedResourceReservations'"), EventLogLevel.Information, ThisObject.Metadata(), vReservationObj.Ref, vMessage);
			If pIsInteractive Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
			Endif;
		Except
			vMessage = ErrorDescription();
			WriteLogEvent(NStr("en='DataProcessor.ProcessFinishedResourceReservations';ru='Обработка.ОбработкаЗавершеннойБрониРесурсов';de='DataProcessor.ProcessFinishedResourceReservations'"), EventLogLevel.Warning, ThisObject.Metadata(), ?(vReservationObj = Undefined, Undefined, vReservationObj.Ref), vMessage);
			If pIsInteractive Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			EndIf;
		EndTry;
	EndDo;
	WriteLogEvent(NStr("en='DataProcessor.ProcessFinishedResourceReservations';ru='Обработка.ОбработкаЗавершеннойБрониРесурсов';de='DataProcessor.ProcessFinishedResourceReservations'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'"));
EndProcedure // pmProcessFinishedResourceReservations
