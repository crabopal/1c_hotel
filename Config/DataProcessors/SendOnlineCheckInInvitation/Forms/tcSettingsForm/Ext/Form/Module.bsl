#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Load DP parameters
	vObj = FormAttributeToValue("Object");
	vDataProcessor = Undefined;
	If ThisForm.Parameters.Property("DataProcessor", vDataProcessor) Then
		vObj.DataProcessor = vDataProcessor;
	EndIf;
	vObj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(vObj, "Object");
	
	// User rights
	If Not tcOnServer.cmIsInRole("Administrator") Then
		Items.GroupParameters.Visible = False;
	Else
		FillScheduledJobStatus();
	EndIf;
	
	// Run data processor if neccessary
	vGenerateOnOpen = False;
	If Parameters.Property("GenerateOnOpen", vGenerateOnOpen) And vGenerateOnOpen <> Undefined And vGenerateOnOpen Then
		vObj.pmRun();
		pCancel = True;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveSettings(pCommand)
	If ValueIsFilled(Object.DataProcessor) Then
		Save_AtServer();
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure BackgroundJob(pCommand)
	vDP = Object.DataProcessor;
	If ValueIsFilled(vDP) Then
		// Open settings form
		OpenForm("DataProcessor.ScheduledJobsManagementConsole.Form.tc_BackgroundJobSettingsForm", 
				New Structure("DataProcessor", vDP), 
				ThisForm,
				ThisForm.UUID,,, 
				New NotifyDescription("AfterUpdateBackgroundJob", ThisObject), 
				FormWindowOpeningMode.LockOwnerWindow);
	EndIf;	
EndProcedure // BackgroundJob

// -----------------------------------------------------------------------------
&AtClient
Procedure SendInvitationByEmail(pCommand)
	// Run processing at server
	RunAtServer();
	
	// Processing completed
	ShowMessageBox(, NStr("en='Processing completed!';ru='Выполнение процедуры закончено!';de='Die Prozedur ist abgeschlossen!'"));
EndProcedure // SendInvitationByEmail

#EndRegion

#Region Private
// -----------------------------------------------------------------------------
&AtServer
Procedure RunAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.pmSendInvitationByEmail(True);
EndProcedure // RunAtServer

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
Procedure AfterUpdateBackgroundJob(pResult, pAdditionalParameters) Export
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

#EndRegion
