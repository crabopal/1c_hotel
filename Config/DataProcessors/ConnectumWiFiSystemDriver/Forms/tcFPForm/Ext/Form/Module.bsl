
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
	
	// User rights
	If Not tcOnServer.cmIsInRole("Administrator") Then
		Items.GroupParameters.Visible = False;
	Else
		// Fill background job status
		FillScheduledJobStatus();
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	// Run data processor if neccessary
	vGenerateOnOpen = False;
	If Parameters.Property("GenerateOnOpen", vGenerateOnOpen) And vGenerateOnOpen <> Undefined And vGenerateOnOpen Then
		vObj.pmRun(, True);
		pCancel = True;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelClearing(pItem, pStandardProcessing)
	HotelClearingAtServer(pStandardProcessing);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionsExecute(pCommand)
	ActionsExecuteAtServer();
	ShowMessageBox( , NStr("en='Processing completed!';ru='Выполнение процедуры закончено!';de='Die Prozedur ist abgeschlossen!'"));
EndProcedure // ActionsExecute

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveSettings(pCommand)
	SaveSettingsAtServer();
EndProcedure //  SaveSettings

// -----------------------------------------------------------------------------
&AtClient
Procedure BackgroundJob(pCommand)
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
Procedure InitializeConfDictionaries(pCommand)
	LoadDefaultSettingRecordsAtServer();
	// Open room interface types catalog list form
	OpenForm("Catalog.RoomInterfaceTypes.ListForm");
EndProcedure // InitializeConfDictionaries

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure ActionsExecuteAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.pmRun( , True);
	ValueToFormAttribute(vObj, "Object");
EndProcedure // ActionsExecuteAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveSettingsAtServer()
	If ValueIsFilled(Object.DataProcessor) Then
		vObj = FormAttributeToValue("Object");
		vObj.pmSaveDataProcessorAttributes();
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure //  SaveSettingsAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterUpdateBackgroundJob(pResult,pAdditionalParameters) Export
	FillScheduledJobStatus();
EndProcedure //  AfterUpdateBackgroundJob

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
Procedure HotelClearingAtServer(pStandardProcessing)
	If Not IsInRole("RightsToChooseHotel") Then
		pStandardProcessing = False;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadDefaultSettingRecordsAtServer()
	// Initialize room interface types catalog
	vCode = "WIFI";
	vRITRef = Catalogs.RoomInterfaceTypes.FindByCode(vCode, False);
	If ValueIsFilled(vRITRef) Then
		vRITObj = vRITRef.GetObject();
	Else
		vRITObj = Catalogs.RoomInterfaceTypes.CreateItem();
	EndIf;
	vRITObj.Code = vCode;
	vRITObj.InterfaceType = Enums.InterfaceTypes.Internet;
	vRITObj.Description = NStr("en='Turn-on Wi-Fi'; ru='Включить Wi-Fi'; de='Wi-Fi einschalten'");
	vRITObj.TurnOnParameters = "add_user";
	vRITObj.PeriodOfStayExtentionParameters = "update_users";
	vRITObj.ManualCancelIsForbidden = True;
	vRITObj.Write();
EndProcedure // LoadDefaultSettingRecords

#EndRegion    
 