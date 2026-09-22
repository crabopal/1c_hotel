
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
	ValueToFormAttribute(Obj, "Object");

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
		
		//Open settings form
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
	If Not ValueIsFilled(Object.NonGuaranteedReservationStatus) Then
		ShowMessageBox( , NStr("en = 'Fill non guaranteed reservations status!'; de = 'Geben Sie den Status der nichtgarantierten Reservierung an!'; ru = 'Укажите статус негарантированной брони!'"));
		Return;
	EndIf;	
	If Not ValueIsFilled(Object.CanceledReservationStatus) Then
		ShowMessageBox( , NStr("en = 'Fill canceled reservations status!'; de = 'Geben Sie den Status der stornierten Reservierung an!'; ru = 'Укажите статус отмененной брони!'"));
		Return;
	EndIf;	
	If Object.PeriodToKeepReservations <= 0 Then
		ShowMessageBox( , NStr("en = 'Fill period in minutes to keep non guaranteed reservations!'; de = 'Geben Sie den Zeitraum in Minuten an, nach dem die überfällige und nicht garantierte Reservierung entfernt werden soll!'; ru = 'Укажите период в минутах после которого нужно снимать просроченную не гарантированную бронь!'"));
		Return;
	EndIf;	

	// Do processing
	DoCheck();
	
	// Processing completed
	ShowMessageBox( , NStr("en = 'Processing completed!'; de = 'Die Prozedur ist abgeschlossen!'; ru = 'Выполнение процедуры закончено!'"));
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
	Obj.pmCancelNonGuaranteedReservations(True);
EndProcedure	

#EndRegion    
