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
		PeriodToWait = 4;
	EndIf;
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	CheckDateTime = CurrentSessionDate() - PeriodToWait*3600;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	// Check load of phone calls
	pmCheckLoadOfPhoneCalls(pIsInteractive);
EndProcedure // pmRun

// -----------------------------------------------------------------------------
// Data processors framework end
// -----------------------------------------------------------------------------
	
// -----------------------------------------------------------------------------
Procedure pmCheckLoadOfPhoneCalls(pIsInteractive = False) Export
	WriteLogEvent(NStr("en='DataProcessor.CheckLoadOfPhoneCalls'; de='DataProcessor.CheckLoadOfPhoneCalls'; ru='Обработка.ПроверкаВыполненияЗагрузкиТелефонныхРазговоров'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'"));
	// Check parameters
	If Not ValueIsFilled(DepartmentToNotify) Then
		vMessage = NStr("ru='Не указан отдел, сотрудникам которого отправлять сообщения!'; 
		                |de='Department to notify is not set!'; 
						|en='Department to notify is not set!'");
		WriteLogEvent(NStr("en='DataProcessor.CheckLoadOfPhoneCalls'; de='DataProcessor.CheckLoadOfPhoneCalls'; ru='Обработка.ПроверкаВыполненияЗагрузкиТелефонныхРазговоров'"), EventLogLevel.Warning, ThisObject.Metadata(), Undefined, vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			Return;
		Else
			Raise vMessage;
		EndIf;
	EndIf;
	If Not ValueIsFilled(CheckDateTime) Then
		vMessage = NStr("ru='Не указаны дата и время, на которые проверять наличие телефонных разговоров!';
		                |de='Date and time to check phone calls is not set!';
						|en='Date and time to check phone calls is not set!'");
		WriteLogEvent(NStr("en='DataProcessor.CheckLoadOfPhoneCalls'; de='DataProcessor.CheckLoadOfPhoneCalls'; ru='Обработка.ПроверкаВыполненияЗагрузкиТелефонныхРазговоров'"), EventLogLevel.Warning, ThisObject.Metadata(), Undefined, vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			Return;
		Else
			Raise vMessage;
		EndIf;
	EndIf;
	// Get loaded phone calls
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RecordPhoneCall.Ref
	|FROM
	|	Document.RecordPhoneCall AS RecordPhoneCall
	|WHERE
	|	RecordPhoneCall.Date > &qPeriod
	|	AND RecordPhoneCall.Posted
	|	AND RecordPhoneCall.Hotel IN HIERARCHY (&qHotel)
	|ORDER BY
	|	RecordPhoneCall.PointInTime";
	vQry.SetParameter("qPeriod", CheckDateTime);
	vQry.SetParameter("qHotel", Hotel);
	vPhoneCalls = vQry.Execute().Unload();
	// If there is no phone calls in the query result, then send notification
	If vPhoneCalls.Count() = 0 Then
		Try
			// Get last phone call load date and time
			vLastCallDate = '00010101010101';
			vQry = New Query();
			vQry.Text = 
			"SELECT TOP 1
			|	RecordPhoneCall.Date
			|FROM
			|	Document.RecordPhoneCall AS RecordPhoneCall
			|WHERE
			|	RecordPhoneCall.Posted
			|	AND RecordPhoneCall.Hotel IN HIERARCHY(&qHotel)
			|ORDER BY
			|	RecordPhoneCall.PointInTime DESC";
			vQry.SetParameter("qHotel", Hotel);
			vLastCall = vQry.Execute().Unload();
			If vLastCall.Count() > 0 Then
				vLastCallDate = vLastCall.Get(0).Date;
			EndIf;
			// Build message
			vMessage = NStr("ru='Дата и время загрузки последнего телефонного разговора: " + Format(vLastCallDate, "DF='dd.MM.yyyy HH:mm:ss'") + "! Проверьте тарификатор и процедуру импорта данных телефонных разговоров.'; 
			                |de='Last phone call load date and time is: " + Format(vLastCallDate, "DF='dd.MM.yyyy HH:mm:ss'") + "! Check phone calls tariffication program and load phone calls procedure.'; 
			                |en='Last phone call load date and time is: " + Format(vLastCallDate, "DF='dd.MM.yyyy HH:mm:ss'") + "! Check phone calls tariffication program and load phone calls procedure.'");
			// Send notification
			WriteLogEvent(NStr("en='DataProcessor.CheckLoadOfPhoneCalls'; de='DataProcessor.CheckLoadOfPhoneCalls'; ru='Обработка.ПроверкаВыполненияЗагрузкиТелефонныхРазговоров'"), EventLogLevel.Information, ThisObject.Metadata(), , vMessage);
			If pIsInteractive Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
			Endif;
			cmSendMessageToDepartment(DepartmentToNotify, vMessage);
		Except
			vMessage = ErrorDescription();
			WriteLogEvent(NStr("en='DataProcessor.CheckLoadOfPhoneCalls'; de='DataProcessor.CheckLoadOfPhoneCalls'; ru='Обработка.ПроверкаВыполненияЗагрузкиТелефонныхРазговоров'"), EventLogLevel.Warning, ThisObject.Metadata(), , vMessage);
			If pIsInteractive Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			Else
				Raise vMessage;
			EndIf;
		EndTry;
	EndIf;
	WriteLogEvent(NStr("en='DataProcessor.CheckLoadOfPhoneCalls'; de='DataProcessor.CheckLoadOfPhoneCalls'; ru='Обработка.ПроверкаВыполненияЗагрузкиТелефонныхРазговоров'"), EventLogLevel.Information, ThisObject.Metadata(), , NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'"));
EndProcedure // pmCheckLoadOfPhoneCalls
