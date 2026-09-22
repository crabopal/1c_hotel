
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

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelClearing(pItem, pStandardProcessing)
	HotelClearingAtServer(pStandardProcessing);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CallsLoggingFileStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	BeginAttachingFileSystemExtension(New NotifyDescription("CallsLoggingFileAttachingFileSystemExtensionResult", ThisObject));
EndProcedure //  CallsLoggingFileStartChoice

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionsExecute(pCommand)
	If IsBlankString(Object.CallsLoggingFile) Then
		ShowMessageBox( , NStr("en='Fill path to the calls file!';ru='Укажите путь к файлу лога телефонных разговоров!';de='Geben Sie den Pfad zur Datei mit Telefongesprächen an!'"));
		Return;
	EndIf;	
	If Object.PBXSerialPort = 0 Then
		ShowMessageBox( , NStr("en='Fill serial port!';ru='Укажите номер COM порта!';de='Geben Sie den COM port Nummer!'"));
		Return;
	EndIf;
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
		// Open settings form
		OpenForm("DataProcessor.ScheduledJobsManagementConsole.Form.tc_BackgroundJobSettingsForm", 
				New Structure("DataProcessor", vDP), 
				ThisObject,
				UUID, , , 
				New NotifyDescription("AfterUpdateBackgroundJob", ThisObject), 
				FormWindowOpeningMode.LockOwnerWindow);
	EndIf;	
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure StopInterface(pCommand)
	StopInterfaceAtServer();
EndProcedure // StopInterface

// --------------------------------------------------------------------------------
&AtClient
Procedure InitializeInterfaceCommands(pCommand)
	InitializeInterfaceCommandsAtServer();
	// Open room interface types catalog list form
	OpenForm("Catalog.RoomInterfaceTypes.ListForm");
EndProcedure // InitializeInterfaceCommands

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure ActionsExecuteAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.pmRun(, True);
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

// --------------------------------------------------------------------------------
&AtClient
Procedure CallsLoggingFileAttachingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		OpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'File system extension is being installing on your browser...'; de = 'Dateisystemerweiterung wird in Ihrem Browser installiert...'; ru = 'В браузер устанавливается расширение по работе с файлами...'"), MessageStatus.Information);
		BeginInstallFileSystemExtension(New NotifyDescription("CallsLoggingFileFileSystemExtensionInstallCompleted", ThisObject));
	EndIf;
EndProcedure // CallsLoggingFileAttachingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure CallsLoggingFileFileSystemExtensionInstallCompleted(pParam) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("CallsLoggingFileInstallingFileSystemExtensionResult", ThisObject));
EndProcedure // CallsLoggingFileFileSystemExtensionInstallCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure CallsLoggingFileInstallingFileSystemExtensionResult(pResult, pParam) Export 
	If pResult Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'File system extension was successfully installed on your browser!'; de = 'Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'; ru = 'В браузер успешно установлено расширение по работе с файлами!'"), MessageStatus.Information);
		OpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Your browser does not support file operations in 1C!'; de = 'Ihr Browser unterstützt keine Dateioperationen in 1C!'; ru = 'Браузер не поддерживает работу с файлами в 1С!'"), MessageStatus.Attention);
	EndIf;
EndProcedure // CallsLoggingFileInstallingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient 
Procedure OpenFileDialogToChooseFile()
	vFileOpen = New FileDialog(FileDialogMode.Open);
	vFileOpen.Filter = NStr("en = 'File with phone calls log *.txt (*.txt)|*.txt|'; de = 'Datei mit Telefongesprächen *.txt (*.txt)|*.txt|'; ru = 'Файл для логирования телефонных разговоров *.txt (*.txt)|*.txt|'");
	vFileOpen.Multiselect = False;
	vFileOpen.Title = NStr("en = 'Choose calls log file'; de = 'Auswahl der Datei mit Telefongesprächen'; ru = 'Выбор файла для логирования телефонных разговоров'");
	vFileOpen.Preview = False;
	vFileOpen.Show(New NotifyDescription("OpenFileDialogToChooseFileCompleted", ThisObject));
EndProcedure // OpenFileDialogToChooseFile

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileDialogToChooseFileCompleted(pFileArray, pParam) Export 
	If ValueIsFilled(pFileArray) Then
		Object.CallsLoggingFile = pFileArray[0];
	EndIf;
EndProcedure // OpenFileDialogToChooseFileCompleted

// --------------------------------------------------------------------------------
&AtServer
Procedure StopInterfaceAtServer()
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
		cmWait(15);
		vObj.pmLoadDataProcessorAttributes();
		If vObj.IsRunning Then
			vObj.IsRunning = False;
			vObj.pmSaveDataProcessorAttributes();
		EndIf;
	EndIf;
	ValueToFormAttribute(vObj, "Object");
	tcCommonFunctionOnClientServer.TextMessage(NStr("en='Interface is stopped!'; ru='Интерфейс остановлен!'; de='Interface gestopped!'"));
EndProcedure // StopInterfaceAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure InitializeInterfaceCommandsAtServer()
	// Read template with default settings and write it to the Room interface types catalog
	vRITList = DataProcessors.EricssonPBXDriverCIL4.GetTemplate("InitializationRecords");
	vCount = vRITList.TableHeight - 1;
	For i = 2 To (vCount + 1) Do
		vCode = TrimAll(vRITList.Area(i, 1, i, 1).Text);
		vRITRef = Catalogs.RoomInterfaceTypes.FindByCode(vCode, False);
		If ValueIsFilled(vRITRef) Then
			vRITObj = vRITRef.GetObject();
		Else
			vRITObj = Catalogs.RoomInterfaceTypes.CreateItem();
		EndIf;
		vRITObj.Code = vCode;
		vRITObj.InterfaceType = Enums.InterfaceTypes.Phone;
		vRITObj.Description = TrimAll(vRITList.Area(i, 2, i, 2).Text);
		vRITObj.Remarks = TrimAll(vRITList.Area(i, 3, i, 3).Text);
		vRITObj.TurnOnParameters = TrimAll(vRITList.Area(i, 4, i, 4).Text);
		vRITObj.TurnOffParameters = TrimAll(vRITList.Area(i, 5, i, 5).Text);
		vRITObj.RefusalReason = TrimAll(vRITList.Area(i, 7, i, 7).Text);
		vManualCancelIsForbidden = Upper(TrimAll(vRITList.Area(i, 6, i, 6).Text));
		If vManualCancelIsForbidden = "TRUE" Then
			vRITObj.ManualCancelIsForbidden = True;
		Else
			vRITObj.ManualCancelIsForbidden = False;
		EndIf;
		vRITObj.Write();
	EndDo;
	// Do message
	tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Done'; de = 'Fertig'; ru = 'Выполнено'"));
EndProcedure // InitializeInterfaceCommandsAtServer

#EndRegion
