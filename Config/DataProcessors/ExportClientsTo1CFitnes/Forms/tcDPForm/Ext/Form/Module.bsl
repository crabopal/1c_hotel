
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
	vInteractionParameters = Catalogs.ExternalSystemInteractions.EmptyRef();
	If Parameters.Property("InteractionParameters", vInteractionParameters) Then
		Obj.InteractionParameters = vInteractionParameters;
	EndIf;
	Obj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(Obj, "Object");
	
	LoadInteractionParameters();  
	
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
EndProcedure //  OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure LastExportPeriodOnChange(pItem)
	FillActionCaption();
EndProcedure //  LastExportPeriodOnChange

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveSettings(pCommand)	
	SaveSettingsAtServer();
EndProcedure //  SaveSettings

// -----------------------------------------------------------------------------
&AtClient
Procedure BackgroundJob(pCommand)
	vDP = Undefined;
	vDP = tcOnServer.cmGetAttributeByRef(Object.InteractionParameters, "DataProcessor");;
	
	If ValueIsFilled(vDP) Then
		// Open settings form
		OpenForm("DataProcessor.ScheduledJobsManagementConsole.Form.tc_BackgroundJobSettingsForm", 
				 New Structure("DataProcessor", vDP), 
				 ThisObject,
				 UUID, , , 
				 New NotifyDescription("AfterUpdateBackgroundJob", ThisObject), 
				 FormWindowOpeningMode.LockOwnerWindow);
	Else
		ShowMessageBox( , NStr("ru = 'Укажите обработку во внешней системе!'; en = 'Specify processing in an external system!'"));			 
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
	If CheckFilling() Then
		SaveInteractionParameters();					
		// Save DP parameters
		Obj = FormAttributeToValue("Object");
		Obj.pmSaveDataProcessorAttributes();
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
	Items.ActionCaption.Title = StrReplace(Items.ActionCaption.Title, "&1", Format(LastExportPeriod, "DF='dd.MM.yyyy HH:mm'"));
EndProcedure // FillActionCaption

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadInteractionParameters()
	
	If Not ValueIsFilled(Object.InteractionParameters) Then
		Return;
	EndIf;
	
	Hotel        	  			= Object.InteractionParameters.Hotel;
	HttpAdress					= Object.InteractionParameters.HttpAddress;
	HttpResource				= Object.InteractionParameters.WebhookURL;
	User 						= Object.InteractionParameters.Login;
	Password 					= Object.InteractionParameters.Password;
	IsDebugMode 				= Object.InteractionParameters.DebugMode;
	LastExportPeriod			= Object.InteractionParameters.LastFullSynchronizationTime;
	
EndProcedure //  LoadInteractionParameters

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveInteractionParameters()
	
	If Not ValueIsFilled(Object.InteractionParameters) Then
		Return;
	EndIf;
	
	// Save InteractionParam
	vIntParObj 								  = Object.InteractionParameters.GetObject();
	vIntParObj.Hotel   						  = Hotel;
	vIntParObj.HttpAddress					  = HttpAdress;
	vIntParObj.WebhookURL 					  = HttpResource;
	vIntParObj.Login 						  = User;
	vIntParObj.Password 					  = Password;
	vIntParObj.DebugMode 					  = IsDebugMode;
	vIntParObj.LastFullSynchronizationTime	  = LastExportPeriod;
	
	vIntParObj.Write();
	
EndProcedure //  SaveInteractionParameters

#EndRegion
