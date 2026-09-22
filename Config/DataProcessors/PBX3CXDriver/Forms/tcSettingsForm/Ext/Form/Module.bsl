
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
	Items.FormActionsExecute.Enabled = Not vObj.IsRunning;
	Items.FormActionsStop.Enabled = vObj.IsRunning;
	ValueToFormAttribute(vObj, "Object");
	// User rights
	If Not tcOnServer.cmIsInRole("Administrator") Then
		Items.GroupParameters.Visible = False;
	EndIf;    
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);	
	
	FillScheduledJobStatus();
	
	// Run data processor if neccessary
	vGenerateOnOpen = False;
	If Parameters.Property("GenerateOnOpen", vGenerateOnOpen) And vGenerateOnOpen <> Undefined And vGenerateOnOpen Then
		vObj.pmRun();
		pCancel = True;
	EndIf;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	If Object.IsRunning Then
		AttachIdleHandler("RefreshInterfaceState", 11, False);
	EndIf;
EndProcedure // OnOpen

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelClearing(pItem, pStandardProcessing)
	If Not tcOnServer.cmIsInRole("RightsToChooseHotel") Then
		pStandardProcessing = False;
	EndIf;
EndProcedure // HotelClearing

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
Procedure ActionsStop(pCommand)
	ActionsStopAtServer();
EndProcedure // ActionsStop

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveSettings(pCommand)
	If ValueIsFilled(Object.DataProcessor) Then
		SaveSettingsAtServer();
	EndIf;
EndProcedure //  SaveSettings

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionsLoadDefaultSettingRecords(pCommand)
	ActionsLoadDefaultSettingRecordsAtServer();
	ShowMessageBox( , NStr("en='Completed'; ru='Выполнено'; de='Abgeschlossen'")); 
EndProcedure // ActionsLoadDefaultSettingRecords

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
EndProcedure // BackgroundJob

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtClient
Procedure RefreshInterfaceState()
	RefreshInterfaceStateAtServer();
	If Not Object.IsRunning Then
		DetachIdleHandler("RefreshInterfaceState");	
	EndIf;
EndProcedure // RefreshInterfaceState

// -----------------------------------------------------------------------------
&AtServer
Procedure RefreshInterfaceStateAtServer()
	// Load data processor catalog item attributes
	vObj = FormAttributeToValue("Object");
	vObj.pmLoadDataProcessorAttributes();
	Items.FormActionsExecute.Enabled = Not vObj.IsRunning;
	Items.FormActionsStop.Enabled = vObj.IsRunning;
	ValueToFormAttribute(vObj, "Object");
EndProcedure // RefreshInterfaceStateAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ActionsExecuteAtServer()
	If Not ValueIsFilled(Object.Address) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Interface server address should be filled!';ru='Не указан сетевой адрес, на котором должен работать интерфейсный сервер!';de='Server address sollten ausgefüllt werden!'"));
		Return;
	EndIf;	
	If Object.Port = 0 Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Interface server port should be filled!';ru='Не указан сетевой порт, на котором должен работать интерфейсный сервер!';de='Port sollten ausgefüllt werden!'"));
		Return;
	EndIf;
	
	vObj = FormAttributeToValue("Object");
	vObj.pmRunInterfaceClient(True);
	ValueToFormAttribute(vObj, "Object");
EndProcedure // ActionsExecuteAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ActionsStopAtServer()
	vObj = FormAttributeToValue("Object");
	// Do processing
	While True Do
		Try
			vObj.pmLoadDataProcessorAttributes();
			vObj.StopInterface = True;
			vObj.pmSaveDataProcessorAttributes();
			Break;
		Except
		EndTry;
	EndDo;
	If vObj.IsRunning Then
		tcOnServer.Wait(15);
		vObj.pmLoadDataProcessorAttributes();
		If vObj.IsRunning Then
			vObj.IsRunning = False;
			vObj.pmSaveDataProcessorAttributes();
		EndIf;
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Interface is stopped!'; ru='Интерфейс остановлен!'; de='Interface gestopped!'"));
	EndIf;
	ValueToFormAttribute(vObj, "Object");
EndProcedure // ActionsStopAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveSettingsAtServer()
	If ValueIsFilled(Object.DataProcessor) Then
		// Save DP parameters
		vObj = FormAttributeToValue("Object");
		vObj.pmSaveDataProcessorAttributes();
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure //  SaveSettingsAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ActionsLoadDefaultSettingRecordsAtServer()
	// Read template with default settings and write it to the Room interface types catalog
	vRITList = DataProcessors.PBX3CXDriver.GetTemplate("InitializationRecords");
	vCount = vRITList.TableHeight - 1;
	For vInt = 2 To (vCount + 1) Do
		vCode = TrimAll(vRITList.Area(vInt, 1, vInt, 1).Text);
		vRITRef = Catalogs.RoomInterfaceTypes.FindByCode(vCode, False);
		If ValueIsFilled(vRITRef) Then
			vRITObj = vRITRef.GetObject();
		Else
			vRITObj = Catalogs.RoomInterfaceTypes.CreateItem();
		EndIf;
		vRITObj.Code = vCode;
		vRITObj.Hotel = ?(ValueIsFilled(Object.Hotel), Object.Hotel, SessionParameters.CurrentHotel);
		vRITObj.InterfaceType = Enums.InterfaceTypes.Phone;
		vRITObj.Description = NStr(TrimAll(vRITList.Area(vInt, 2, vInt, 2).Text));
		vRITObj.Remarks = TrimAll(vRITList.Area(vInt, 3, vInt, 3).Text);
		vRITObj.TurnOnParameters = TrimAll(vRITList.Area(vInt, 4, vInt, 4).Text);
		vRITObj.TurnOffParameters = TrimAll(vRITList.Area(vInt, 5, vInt, 5).Text);
		vRITObj.RefusalReason = TrimAll(vRITList.Area(vInt, 7, vInt, 7).Text);
		vManualCancelIsForbidden = Upper(TrimAll(vRITList.Area(vInt, 6, vInt, 6).Text));
		If vManualCancelIsForbidden = "TRUE" Then
			vRITObj.ManualCancelIsForbidden = True;
		Else
			vRITObj.ManualCancelIsForbidden = False;
		EndIf;
		vRITObj.Write();
	EndDo;
EndProcedure // ActionsLoadDefaultSettingRecords

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterUpdateBackgroundJob(pResult, pAdditionalParameters) Export
	FillScheduledJobStatus();
EndProcedure // AfterUpdateBackgroundJob

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
EndProcedure // FillScheduledJobStatus

#EndRegion  
