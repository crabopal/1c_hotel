
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
	FillLogСleaning();
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

// --------------------------------------------------------------------------------
&AtClient
Procedure CallsLoggingFileStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadFromFileAttachingFileSystemExtensionResult", ThisObject));
EndProcedure // CallsLoggingFileStartChoice

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionsExecute(pCommand)
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

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure FillLogСleaning()
	Items.LogСleaning.ChoiceList.Clear();
	Items.LogСleaning.ChoiceList.Add("", NStr("en = 'Do not clear the log'; de = 'Löschen Sie das Protokoll nicht'; ru = 'Не очищать лог'"));
	Items.LogСleaning.ChoiceList.Add("1", NStr("en = 'Everyday'; de = 'Täglich'; ru = 'Каждый день'"));
	Items.LogСleaning.ChoiceList.Add("2", NStr("en = 'Every week'; de = 'Jede Woche'; ru = 'Каждую неделю'"));
	Items.LogСleaning.ChoiceList.Add("3", NStr("en = 'Every month'; de = 'Jeden Monat'; ru = 'Каждый месяц'"));
EndProcedure // LogСleaning

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
&AtClient
Procedure LoadFromFileAttachingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		OpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension is being installing on your browser...'; ru='В браузер устанавливается расширение по работе с файлами...'; de='Dateisystemerweiterung wird in Ihrem Browser installiert...'"), MessageStatus.Information);
		BeginInstallFileSystemExtension(New NotifyDescription("LoadFromFileFileSystemExtensionInstallCompleted", ThisObject));
	EndIf;
EndProcedure // LoadFromFileAttachingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFromFileFileSystemExtensionInstallCompleted(pParam) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadFromFileInstallingFileSystemExtensionResult", ThisObject));
EndProcedure // LoadFromFileFileSystemExtensionInstallCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFromFileInstallingFileSystemExtensionResult(pResult, pParam) Export 
	If pResult Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension was successfully installed on your browser!'; ru='В браузер успешно установлено расширение по работе с файлами!'; de='Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'"), MessageStatus.Information);
		OpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Your browser does not support file operations in 1C!'; ru='Браузер не поддерживает работу с файлами в 1С!'; de='Ihr Browser unterstützt keine Dateioperationen in 1C!'"), MessageStatus.Attention);
	EndIf;
EndProcedure // LoadFromFileInstallingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient 
Procedure OpenFileDialogToChooseFile()
	vFileOpen = New FileDialog(FileDialogMode.ChooseDirectory);
	vFileOpen.Multiselect = False;
	vFileOpen.Title = NStr("en='Choosing a directory for saving logs';ru='Выбор директории для сохранения логов';de='Auswählen eines Verzeichnisses zum Speichern von Protokollen'");
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

#EndRegion
