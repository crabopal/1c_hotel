
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Load DP parameters
	Obj = FormAttributeToValue("Object");
	vDataProcessor = Undefined;
	If Parameters.Property("DataProcessor", vDataProcessor) Then
		Obj.DataProcessor = vDataProcessor;
	EndIf;
	Obj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(Obj,"Object");

	// User rights
	If Not tcOnServer.cmIsInRole("Administrator") Then
		Items.GroupParameters.Visible = False;
	Else
		FillScheduledJobStatus();
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	// Run data processor if neccessary
	vGenerateOnOpen = False;
	If Parameters.Property("GenerateOnOpen", vGenerateOnOpen) And vGenerateOnOpen <> Undefined And vGenerateOnOpen Then
    	Obj.pmRun();
    	pCancel = True;
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure TimesToWaitOnlineReservationPaymentOnEditEnd(pItem, pNewRow, pCancelEdit)
	If Object.TimesToWaitOnlineReservationPayment.Count() > 0 Then
		Object.TimesToWaitOnlineReservationPayment.Sort("CheckInDateFrom, CheckInDateTo, NumberOfDaysBeforeCheckInSinceReservationFrom");
		If Object.TimeToWaitOnlineReservationPayment <> 0 Then
			Object.TimeToWaitOnlineReservationPayment = 0;
		EndIf;
	EndIf;
EndProcedure // TimesToWaitOnlineReservationPaymentOnEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure TimeToWaitOnlineReservationPaymentOnChange(pItem)
	If Object.TimeToWaitOnlineReservationPayment <> 0 Then
		If Object.TimesToWaitOnlineReservationPayment.Count() > 0 Then
			Object.TimesToWaitOnlineReservationPayment.Clear();
		EndIf;
	EndIf;
EndProcedure // TimeToWaitOnlineReservationPaymentOnChange

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveSettings(Command)
	If ValueIsFilled(Object.DataProcessor) Then
		Save_AtServer();
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure BackgroundJob(Command)
	
	vDP = Object.DataProcessor;
	If ValueIsFilled(vDP) Then
		
		// Open settings form
		OpenForm("DataProcessor.ScheduledJobsManagementConsole.Form.tc_BackgroundJobSettingsForm", 
				New Structure("DataProcessor", vDP), 
				ThisObject,
				UUID, , , 
				New NotifyDescription("AfterUpdateBackgroundJob", ThisObject), 
				FormWindowOpeningMode.LockOwnerWindow);
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionsExecute(Command)
	If Not ValueIsFilled(Object.GuaranteedReservationStatus) 
		And Not ValueIsFilled(Object.PaymentDateExpiredReservationStatus)  
	    And Not ValueIsFilled(Object.DepartmentToSendNotificationsTo) Then
		ShowMessageBox( , NStr("en = 'At least guaranteed reservation status or payment date expired reservation status or department to send notifications has to be filled! You can specify all three parameters.'; de = 'Es müssen entweder der Status der garantierten Reservierung, oder der Status einer Reservierung mit überfälliger Zahlung, oder die Abteilung angegeben werden, an die die Benachrichtigungen verschickt werden sollen! Es können alle drei Parameter angegeben werden.'; ru = 'Необходимо указать либо статус гарантированной брони, либо статус брони с просроченой оплатой, либо отдел, куда отправлять уведомления! Можно указывать все три параметра.'"));
		Return;
	EndIf;	

	// Do processing
	DoCheck();
	
	// Processing completed
	ShowMessageBox( , NStr("en='Processing completed!';ru='Выполнение процедуры закончено!';de='Die Prozedur ist abgeschlossen!'"));
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure Save_AtServer()
	If ValueIsFilled(Object.DataProcessor) Then
		// Save DP parameters
		vObj = FormAttributeToValue("Object");
		vObj.pmSaveDataProcessorAttributes();
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterUpdateBackgroundJob(Result, AdditionalParameters) Export
	
	FillScheduledJobStatus();

EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillScheduledJobStatus()
	vDP = Object.DataProcessor;
	If ValueIsFilled(vDP) And Not IsBlankString(vDP.Key) Then
		ArrayScheduledJob = ScheduledJobs.GetScheduledJobs(New Structure("Key", vDP.Key));
		
		If ArrayScheduledJob.Count() > 0 Then
			vScheduledJob = ArrayScheduledJob[0];
			If vScheduledJob.Use Then
				Items.DecorationBackgroundJob.Picture = PictureLib.CheckMark;
				Items.DecorationBackgroundJob.ToolTip = NStr("en = 'Active'; de = 'Aktiv'; ru = 'Активно'");
			Else
				Items.DecorationBackgroundJob.Picture = PictureLib.Unpaid;
				Items.DecorationBackgroundJob.ToolTip = NStr("en = 'Turned off'; de = 'Deaktiviert'; ru = 'Выключено'");
			EndIf;	
		Else 
			Items.DecorationBackgroundJob.Picture = PictureLib.Remove;
			Items.DecorationBackgroundJob.ToolTip = NStr("en = 'Not configured'; de = 'Nicht konfiguriert'; ru = 'Не настроено'");
		EndIf;
	Else
		Items.DecorationBackgroundJob.Picture = PictureLib.Remove;
		Items.DecorationBackgroundJob.ToolTip = NStr("en = 'Not configured'; de = 'Nicht konfiguriert'; ru = 'Не настроено'");
	EndIf;
EndProcedure	

// -----------------------------------------------------------------------------
&AtServer
Procedure DoCheck()
	Obj = FormAttributeToValue("Object");
	Obj.pmDoCheck(True);
EndProcedure	

#EndRegion    
