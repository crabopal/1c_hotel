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
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	// Close cash register day
	pmCloseCashRegisterDay(pIsInteractive);
EndProcedure // pmRun

// -----------------------------------------------------------------------------
// Data processors framework end
// -----------------------------------------------------------------------------
	
// -----------------------------------------------------------------------------
Procedure pmCloseCashRegisterDay(pIsInteractive = False) Export
	WriteLogEvent(NStr("en='DataProcessor.AutoCloseCashRegisterDay';ru='Обработка.АвтоматическоеЗакрытиеКассовыхСмен';de='DataProcessor.AutoCloseCashRegisterDay'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'"));
	If Not ValueIsFilled(CashRegister) Then
		Return;
	EndIf;
	// Check interactive mode
	If pIsInteractive = Undefined Then
		pIsInteractive = True;
	EndIf;
	Try
		vDocObj = Documents.CloseOfCashRegisterDay.CreateDocument();
		// Use current time by default
		vDocObj.SetTime(AutoTimeMode.CurrentOrLast);
		// Fill attributes with default values
		vDocObj.pmFillAttributesWithDefaultValues();
		// Set cash register and company
		vDocObj.CashRegister = CashRegister;
		vDocObj.Company = CashRegister.Owner;
		vDocObj.ZReportType = CashRegister.ZReportType;
		// Fill date from value
		vDateFrom = vDocObj.pmCalculateDateFrom(vDocObj.Date);
		If Not ValueIsFilled(vDateFrom) Then
			vDocObj.DateFrom = vDocObj.Date - 24*3600;
		Else
			vDocObj.DateFrom = vDateFrom;
		EndIf;
		// Fill totals table
		vDocObj.pmFillAccountingTotals();
		// Save document
		vDocObj.Write(DocumentWriteMode.Posting);
		// Close day at cash register device
		If vDocObj.CashRegister.IsControlledByProgram Then
			vMessage = "";
			If Not CloseDeviceSession(vMessage) Then
				Raise vMessage;
			EndIf;
		EndIf;
	Except
		vMessage = NStr("en='Error auto closing cash register day: ';ru='Ошибка при закрытии кассовой смены: ';de='Fehler bei Kassentag schließung: '") + cmGetRootErrorDescription(ErrorInfo());
		WriteLogEvent(NStr("en='DataProcessor.AutoCloseCashRegisterDay';ru='Обработка.АвтоматическоеЗакрытиеКассовыхСмен';de='DataProcessor.AutoCloseCashRegisterDay'"), EventLogLevel.Error, CashRegister.Metadata(), CashRegister, vMessage);
		If ValueIsFilled(ErrorNotificationDepartment) Then
			cmSendMessageToDepartment(ErrorNotificationDepartment, vMessage, , True, CashRegister, SendBySMS);
		EndIf;
		Raise vMessage;
	EndTry;
	// End processing
	WriteLogEvent(NStr("en='DataProcessor.AutoCloseCashRegisterDay';ru='Обработка.АвтоматическоеЗакрытиеКассовыхСмен';de='DataProcessor.AutoCloseCashRegisterDay'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'"));
EndProcedure // pmCloseCashRegisterDay

// -----------------------------------------------------------------------------
Function CloseDeviceSession(rMessage)
	rMessage = "";
	vCashRegisterProcessor = cmGetCashRegisterDataProcessor(CashRegister);
	Return vCashRegisterProcessor.pmCloseSession(rMessage);
EndFunction // CloseDeviceSession
