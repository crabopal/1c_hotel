
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Load DP parameters
	vObj = FormAttributeToValue("Object");
	vDataProcessor = Undefined;
	If Parameters.Property("DataProcessor", vDataProcessor) Then
		vObj.DataProcessor = vDataProcessor;
	EndIf;
	vObj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(vObj, "Object");
	
	// Action caption
	FillActionCaption();

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
    	vObj.pmRun();
    	pCancel = True;
	EndIf;
EndProcedure //  OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure LastExportPeriodOnChange(pItem)
	FillActionCaption();
EndProcedure // LastExportPeriodOnChange

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveSettings(pCommand)
	If ValueIsFilled(Object.DataProcessor) Then
		SaveSettingsAtServer();
	EndIf;
EndProcedure //  SaveSettings

// -----------------------------------------------------------------------------
&AtClient
Procedure BackgroundJob(pCommand)
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
EndProcedure //  BackgroundJob

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionsExecute(pCommand)
	ActionExecuteAtServer();
	ShowMessageBox( , NStr("ru = 'Выполнение процедуры закончено! Данные выгружены.'; en = 'Processing completed! Data exported.'"));
EndProcedure //  ActionExecute

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveSettingsAtServer()
	If ValueIsFilled(Object.DataProcessor) Then
		// Save DP parameters
		vObj = FormAttributeToValue("Object");
		vObj.pmSaveDataProcessorAttributes();
	EndIf;
EndProcedure //  SaveSettingsAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterUpdateBackgroundJob(pResult, pAdditionalParameters) Export	
	FillScheduledJobStatus();
EndProcedure //  AfterUpdateBackgroundJob

// -----------------------------------------------------------------------------
&AtServer
Procedure FillScheduledJobStatus()
	vDP = Object.DataProcessor;
	If ValueIsFilled(vDP) And Not IsBlankString(vDP.Key) Then
		vArrayScheduledJob = ScheduledJobs.GetScheduledJobs(New Structure("Key", vDP.Key));
		If vArrayScheduledJob.Count() > 0 Then
			vScheduledJob = vArrayScheduledJob[0];
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
EndProcedure //  FillScheduledJobStatus

// -----------------------------------------------------------------------------
&AtServer
Procedure ActionExecuteAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.pmRun(, True);
	ValueToFormAttribute(vObj, "Object");
	// Action caption
	FillActionCaption();
EndProcedure //  ActionExecuteAtServer 

// -----------------------------------------------------------------------------
&AtServer
Procedure FillActionCaption()	
	Items.ActionCaption.Title = StrReplace(Items.ActionCaption.Title, "&1", Format(Object.LastExportPeriod, "DF='dd.MM.yyyy HH:mm'"));
EndProcedure // FillActionCaption

#EndRegion
