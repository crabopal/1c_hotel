
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
	ValueToFormAttribute(vObj,"Object");
	
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
Procedure DataExchangeFileStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadFromFileAttachingFileSystemExtensionResult", ThisObject));
EndProcedure //  DataExchangeFileStartChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure HistoryCatalogStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadFromFileAttachingDirectoireSystemExtensionResult", ThisObject));
EndProcedure

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
EndProcedure // BackgroundJob

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionsExecute(pCommand)
	ActionsExecuteAtServer();
	ShowMessageBox( , NStr("en='Processing completed!';ru='Выполнение процедуры закончено!';de='Die Prozedur ist abgeschlossen!'"));
EndProcedure // ActionsExecute

#EndRegion

#Region Private

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
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure ActionsExecuteAtServer()
	If IsBlankString(Object.DataExchangeFile) Then
		Raise NStr("ru = 'Укажите путь к файлу с выгруженными заказами!'; en = 'Fill path to the exported restaurant orders!'; de = 'Fill path to the exported restaurant orders!'");
	EndIf;	
	If Not ValueIsFilled(Object.Service) Then
		Raise NStr("ru = 'Укажите услугу!'; en = 'Fill service!'; de = 'Fill service!'");
	EndIf;	
	If Not ValueIsFilled(Object.DataExchangeFileCurrency) Then
		Raise NStr("ru = 'Укажите валюту файла обмена!'; en = 'Fill data exchange file currency!'; de = 'Fill data exchange file currency!'");
	EndIf;
	
	vObj = FormAttributeToValue("Object");
	vObj.pmLoadOrders(True);
	ValueToFormAttribute(vObj, "Object");
EndProcedure // ActionsExecuteAtServer

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
	vFileOpen = New FileDialog(FileDialogMode.Open);
	vFileOpen.Filter = NStr("ru='Файл с заказами из ресторана Calls.dbf (*.dbf)|*.dbf|';de='Bestelldatei für das Restaurant Calls.dbf (*.dbf)|*.dbf|';en='Restaurant order file Calls.dbf (*.dbf)|*.dbf|'");
	vFileOpen.Multiselect = False;
	vFileOpen.Title = NStr("en='Selecting a file with orders from a restaurant';ru='Выбор файла с заказами из ресторана';de='Auswahl einer Datei mit Bestellungen aus einem Restaurant'");
	vFileOpen.Preview = False;
	vFileOpen.Show(New NotifyDescription("OpenFileDialogToChooseFileCompleted", ThisObject));
EndProcedure // OpenFileDialogToChooseFile

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileDialogToChooseFileCompleted(pFileArray, pParam) Export 
	If ValueIsFilled(pFileArray) Then
		Object.DataExchangeFile = pFileArray[0];
	EndIf;
EndProcedure // OpenFileDialogToChooseFileCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFromFileAttachingDirectoireSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		OpenFileDialogToChooseDirectoire();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension is being installing on your browser...'; ru='В браузер устанавливается расширение по работе с файлами...'; de='Dateisystemerweiterung wird in Ihrem Browser installiert...'"), MessageStatus.Information);
		BeginInstallFileSystemExtension(New NotifyDescription("LoadFromFileDirectoireSystemExtensionInstallCompleted", ThisObject));
	EndIf;
EndProcedure // LoadFromFileAttachingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFromFileDirectoireSystemExtensionInstallCompleted(pParam) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadFromFileInstallingFileSystemExtensionResultDirectoire", ThisObject));
EndProcedure // LoadFromFileFileSystemExtensionInstallCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFromFileInstallingFileSystemExtensionResultDirectoire(pResult, pParam) Export 
	If pResult Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension was successfully installed on your browser!'; ru='В браузер успешно установлено расширение по работе с файлами!'; de='Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'"), MessageStatus.Information);
		OpenFileDialogToChooseDirectoire();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Your browser does not support file operations in 1C!'; ru='Браузер не поддерживает работу с файлами в 1С!'; de='Ihr Browser unterstützt keine Dateioperationen in 1C!'"), MessageStatus.Attention);
	EndIf;
EndProcedure // LoadFromFileInstallingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient 
Procedure OpenFileDialogToChooseDirectoire()
	vFileOpen = New FileDialog(FileDialogMode.ChooseDirectory);
	vFileOpen.Directory = TrimAll(Object.HistoryCatalog);
	vFileOpen.Multiselect = False;
	vFileOpen.Title = NStr("ru = 'Выбор папки хранения истории загруженных тел. разговоров'; en = 'Choose directory to store history of loaded phone call files'; de = 'Choose directory to store history of loaded phone call files'");
	vFileOpen.Preview = False;
	vFileOpen.Show(New NotifyDescription("OpenFileDialogToChooseDirectoireCompleted", ThisObject));
EndProcedure // OpenFileDialogToChooseFile

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileDialogToChooseDirectoireCompleted(pFileArray, pParam) Export 
	If ValueIsFilled(pFileArray) Then
		Object.HistoryCatalog = pFileArray[0];
	EndIf;
EndProcedure // OpenFileDialogToChooseFileCompleted

#EndRegion
