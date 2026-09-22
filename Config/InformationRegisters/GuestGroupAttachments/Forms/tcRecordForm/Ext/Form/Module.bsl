
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If ValueIsFilled(Record.GuestGroup) Then
		If Not cmCheckUserPermissions("HavePermissionToEditReservationDocumentNumberAndDate") Then
			Items.Dimensions.ReadOnly = True;
			Items.DocumentType.ReadOnly = True;
			Items.DocumentNumber.ReadOnly = True;
		EndIf;
	EndIf;
	If Parameters.Property("GuestGroup") Then
		Record.GuestGroup = Parameters.GuestGroup;
	EndIf;
	If Not ValueIsFilled(Record.Author) Then
		Record.Author = SessionParameters.CurrentUser;
	EndIf;
	If Not ValueIsFilled(Record.Period) Then
		Record.Period = CurrentSessionDate();
	EndIf;   
	If Find(Lower(TrimAll(Record.DocumentText)), "<html") <> 0 Then
		Items.PageHTML.Visible = True;
		Items.PagesDocumentPresentation.CurrentPage = Items.PageHTML; 
		HTML = Record.DocumentText;
	ELse
		Items.PageHTML.Visible = False;
		Items.PagesDocumentPresentation.CurrentPage = Items.PageText; 
		HTML = "";	
	EndIf;   
	Items.FileName.ToolTip = NStr("en = 'File loaded: '; de = 'Datei geladen: '; ru = 'Загружен: '") + Format(Record.FileLoadTime, "DF='dd.MM.yyyy HH:mm:ss'") + " " +
						 	 NStr("en = 'Changed: '; de = 'Geändert: '; ru = 'Изменен: '") + Format(Record.FileLastChangeTime, "DF='dd.MM.yyyy HH:mm:ss'");
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure FileNameClick(pItem, pStandardProcessing)
	pStandardProcessing = False;
	CommandActionOpenFile(Commands.CommandActionOpenFile);
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure DocumentTextOnChange(pItem)
		If Find(Lower(TrimAll(Record.DocumentText)), "<html") <> 0 Then
		Items.PageHTML.Visible = True;
		HTML = Record.DocumentText;
	ELse
		Items.PageHTML.Visible = False;
		HTML = "";	
	EndIf; 
EndProcedure // DocumentTextOnChange

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure CommandActionOpenFile(pCommand)
	#IF WebClient OR ThinClient OR MobileClient THEN
		BeginAttachingFileSystemExtension(New NotifyDescription("OpenFileAttachingFileSystemExtensionResult", ThisForm));
	#ELSE
		vBinary = GetFileBinaryData();
		If vBinary <> Undefined And Not IsBlankString(Record.FileName) Then
			// Save file to disk
			vFullFileName = TempFilesDir() + Trimall(Record.FileName);
			vBinary.Write(vFullFileName);
			// Open temp file in application
			BeginRunningApplication(New NotifyDescription("AfterRunApp", ThisForm, vFullFileName), vFullFileName, TempFilesDir(), True);
		Else
			ShowMessageBox(,NStr("en='File was not loaded!';ru='Файл не загружен!';de='Datei wurde nicht geladen!'"));
		EndIf;
	#ENDIF
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure CommandActionLoadFromFile(pCommand)
	#IF WebClient OR ThinClient OR MobileClient THEN
		BeginAttachingFileSystemExtension(New NotifyDescription("LoadFromFileAttachingFileSystemExtensionResult", ThisForm));
	#ELSE
		OpenFileDialogToChooseFile();
	#ENDIF
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure CommandActionClearData(pCommand)
	CommandActionClearDataAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure CommandActionSaveToFile(pCommand)
	If Not CheckFileDataAtServer() Then
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='No external file was loaded!';ru='Внешний файл не был загружен!';de='Die externe Datei wurde nicht geladen!'"));
		Return;
	EndIf;
	#IF WebClient OR ThinClient OR MobileClient THEN
		BeginAttachingFileSystemExtension(New NotifyDescription("SaveFileAttachingFileSystemExtensionResult", ThisForm));
	#ELSE
		OpenChooseFileToSaveToDialog();
	#ENDIF
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Function GetFileBinaryData()
    vRecord = FormAttributeToValue("Record");
	Return vRecord.ExtFile.Get();
EndFunction // GetFileBinaryData

// --------------------------------------------------------------------------------
&AtServerNoContext
Function IsFileEditable(pExtension)
	Return cmIsFileEditable(pExtension);
EndFunction // IsFileEditable

// --------------------------------------------------------------------------------
&AtServer
Function GetFileTempStorageAddress()
    vRecord = FormAttributeToValue("Record");
	vBinaryData = vRecord.ExtFile.Get();
	Return PutToTempStorage(vBinaryData);
EndFunction // GetFileTempStorageAddress

// --------------------------------------------------------------------------------
&AtClient 
Procedure OpenFileRunningApplicationCompleted(pReturnCode, pLocalFullFileName) Export
	// If file is editable then ask user to save it back
	vFile = New File(pLocalFullFileName);
	If IsFileEditable(vFile.Extension) Then
		ShowQueryBox(New NotifyDescription("AfterClosedQueryBox", ThisForm, pLocalFullFileName),
		             NStr("en='Save document changes to the database?';ru='Сохранить измененный документ в базу данных?';de='Das geänderte Dokument in der Datenbank speichern?'"), QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
	EndIf;
EndProcedure // OpenFileRunningApplicationCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileGettingFilesCompleted(pTransferredFiles, pTempFilesDir) Export
	vLocalFullFileName = pTransferredFiles.Get(0).Name;
	// Open temp file in application
	BeginRunningApplication(New NotifyDescription("OpenFileRunningApplicationCompleted", ThisForm, vLocalFullFileName), vLocalFullFileName, pTempFilesDir, True);
EndProcedure // OpenFileGettingFilesCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileGettingTempFilesDirCompleted(pTempFilesDir, pParam) Export
	// Build local temp file name
	vLocalFullFileName = pTempFilesDir + Record.FileName;
	// Get temp storage address with file data
	vTemStorageAddress = GetFileTempStorageAddress();
	// Create array of files to transfer from server to the client
	vFilesToBeObtained = New Array();
	vFileToBeObtained = New TransferableFileDescription(vLocalFullFileName, vTemStorageAddress);
	vFilesToBeObtained.Add(vFileToBeObtained);
	BeginGettingFiles(New NotifyDescription("OpenFileGettingFilesCompleted", ThisForm, pTempFilesDir), vFilesToBeObtained, , False);
EndProcedure // OpenFileGettingTempFilesDirCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileInstallingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='File system extension was successfully installed on your browser!'; ru='Успешно установлено расширение по работе с файлами!'; de='Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'"));
		// Getting temp files dir
		BeginGettingTempFilesDir(New NotifyDescription("OpenFileGettingTempFilesDirCompleted", ThisForm, pParam));
	Else
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='Your browser does not support file operations in 1C!'; ru='Браузер не поддерживает работу с файлами в 1С!'; de='Ihr Browser unterstützt keine Dateioperationen in 1C!'"));
	EndIf;
EndProcedure // OpenFileInstallingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileFileSystemExtensionInstallCompleted(pParam) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("OpenFileInstallingFileSystemExtensionResult", ThisForm));
EndProcedure // OpenFileFileSystemExtensionInstallCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileAttachingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		// Getting temp files dir
		BeginGettingTempFilesDir(New NotifyDescription("OpenFileGettingTempFilesDirCompleted", ThisForm, pParam));
	Else
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='File system extension is being installing on your browser...'; ru='Браузер устанавливается расширение по работе с файлами...'; de='Dateisystemerweiterung wird in Ihrem Browser installiert...'"));
		BeginInstallFileSystemExtension(New NotifyDescription("OpenFileFileSystemExtensionInstallCompleted", ThisForm));
	EndIf;
EndProcedure // OpenFileAttachingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtServer
Procedure AfterClosedQueryBoxAtServer(pBinaryData) 
	vRecord = FormAttributeToValue("Record");
	vRecord.ExtFile = New ValueStorage(pBinaryData);
	vRecord.FileLastChangeTime = CurrentSessionDate();
	vRecord.Write();
	ValueToFormAttribute(vRecord,"Record");
	ThisForm.Modified = False;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure UpdatedFileDownloadToServerCompletedAtServer(pTempStorageFileAddress, pParam)
	vBinaryData = GetFromTempStorage(pTempStorageFileAddress);
	AfterClosedQueryBoxAtServer(vBinaryData);
EndProcedure // UpdatedFileDownloadToServerCompletedAtServer

// --------------------------------------------------------------------------------
&AtClient 
Procedure UpdatedFileDownloadToServerCompleted(pTransferredFiles, pParam) Export
	vTempStorageFileAddress = pTransferredFiles.Get(0).Location;
	UpdatedFileDownloadToServerCompletedAtServer(vTempStorageFileAddress, pParam);
EndProcedure // UpdatedFileDownloadToServerCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure AfterRunApp(pResult, pFullFileName) Export
	// If file is editable then ask user to save it back
	vFile = New File(pFullFileName);
	If IsFileEditable(vFile.Extension) Then
		ShowQueryBox(New NotifyDescription("AfterClosedQueryBox", ThisForm, pFullFileName),
	                 NStr("en='Save document changes to the database?';ru='Сохранить измененный документ в базу данных?';de='Das geänderte Dokument in der Datenbank speichern?'"), QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
	EndIf;
EndProcedure // AfterRunApp

// --------------------------------------------------------------------------------
&AtClient
Procedure AfterClosedQueryBox(pResult, pFullFileName) Export
	If pResult = DialogReturnCode.Yes Then
		#IF WebClient OR ThinClient OR MobileClient THEN
			vFile = New File(pFullFileName);
			vFilesArray = New Array();
			vFileDescription = New TransferableFileDescription(pFullFileName);
			vFilesArray.Add(vFileDescription);
			BeginPuttingFiles(New NotifyDescription("UpdatedFileDownloadToServerCompleted", ThisForm), vFilesArray, , False);
		#ELSE
			vBinaryData = New BinaryData(pFullFileName);
			AfterClosedQueryBoxAtServer(vBinaryData);
		#ENDIF
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure CommandActionLoadFromFileAtServer(pBinaryData, pFileName, pFileLastChangeTime) 
	vRecord = FormAttributeToValue("Record");
	vRecord.ExtFile = New ValueStorage(pBinaryData);
	// Save file name, load time and last modification time
	vRecord.FileName = pFileName;
	vRecord.FileLoadTime = CurrentSessionDate();
	vRecord.FileLastChangeTime = pFileLastChangeTime;
	Items.FileName.ToolTip = NStr("en = 'File loaded: '; de = 'Datei geladen: '; ru = 'Загружен: '") + Format(vRecord.FileLoadTime, "DF='dd.MM.yyyy HH:mm:ss'") + " " +
						 	 NStr("en = 'Changed: '; de = 'Geändert: '; ru = 'Изменен: '") + Format(vRecord.FileLastChangeTime, "DF='dd.MM.yyyy HH:mm:ss'"); 
	vRecord.Write(True);
	ValueToFormAttribute(vRecord,"Record");
	ThisForm.Modified = False;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure FileDownloadToServerCompletedAtServer(pTransferredFiles, pFile)
	vFileAddress = pTransferredFiles.Get(0).Location;
	vBinaryData = GetFromTempStorage(vFileAddress);
	CommandActionLoadFromFileAtServer(vBinaryData, pFile.Name, pFile.LastModificationTime);
EndProcedure // FileDownloadToServerCompletedAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure FileDownloadToServerCompleted(pTransferredFiles, pFile) Export
	FileDownloadToServerCompletedAtServer(pTransferredFiles, pFile);
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFileInWebClient(pFullFileName, pFile)
	vFilesArray = New Array();
	vFileDescription = New TransferableFileDescription(pFullFileName);
	vFilesArray.Add(vFileDescription);
	BeginPuttingFiles(New NotifyDescription("FileDownloadToServerCompleted", ThisForm, pFile), vFilesArray, , False);
EndProcedure // LoadFileInWebClient

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFromFileInstallingFileSystemExtensionResult(pResult, pParam) Export 
	If pResult Then
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='File system extension was successfully installed on your browser!'; ru='Браузер успешно установлено расширение по работе с файлами!'; de='Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'"));
		OpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='Your browser does not support file operations in 1C!'; ru='Браузер не поддерживает работу с файлами в 1С!'; de='Ihr Browser unterstützt keine Dateioperationen in 1C!'"));
	EndIf;
EndProcedure // LoadFromFileInstallingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFromFileFileSystemExtensionInstallCompleted(pParam) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadFromFileInstallingFileSystemExtensionResult", ThisForm));
EndProcedure // LoadFromFileFileSystemExtensionInstallCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFileGettingModificationTimeCompleted(pModificationTime, pParams) Export
	LoadFileInWebClient(pParams.FullFileName, New Structure("Name, LastModificationTime", pParams.FileName, pModificationTime));
EndProcedure // LoadFileGettingModificationTimeCompleted
	
// --------------------------------------------------------------------------------
&AtClient
Procedure CommandActionLoadFromFileNotification(pFileArray, pParam) Export 
	If ValueIsFilled(pFileArray) Then
		vFullFileName = pFileArray[0];
		vFile = New File(vFullFileName);
		#IF WebClient OR ThinClient OR MobileClient THEN
			vFile.BeginGettingModificationTime(New NotifyDescription("LoadFileGettingModificationTimeCompleted", ThisForm, New Structure("FileName, FullFileName", vFile.Name, vFullFileName)));
		#ELSE
			vBinaryData = New BinaryData(vFullFileName);
			CommandActionLoadFromFileAtServer(vBinaryData, vFile.Name, vFile.GetModificationTime());
		#ENDIF
	EndIf;
EndProcedure // CommandActionLoadFromFileNotification

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFromFileAttachingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		OpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='File system extension is being installing on your browser...'; ru='Браузер устанавливается расширение по работе с файлами...'; de='Dateisystemerweiterung wird in Ihrem Browser installiert...'"));
		BeginInstallFileSystemExtension(New NotifyDescription("LoadFromFileFileSystemExtensionInstallCompleted", ThisForm));
	EndIf;
EndProcedure // LoadFromFileAttachingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient 
Procedure OpenFileDialogToChooseFile()
	vFullFileName = TrimAll(Record.FileName);
	vFileOpen = New FileDialog(FileDialogMode.Open);
	vFileOpen.FullFileName = vFullFileName;
	vFileOpen.Multiselect = False;
	vFileOpen.Title = NStr("en='Open file';ru='Открыть файл';de='Datei öffnen'");
	vFileOpen.Preview = True;
	vFileOpen.Show(New NotifyDescription("CommandActionLoadFromFileNotification", ThisForm));
EndProcedure // OpenFileDialogToChooseFile

// --------------------------------------------------------------------------------
&AtServer
Function GetFileDataFromServer()
	vBinaryData = Undefined;
	pRecord = FormAttributeToValue("Record");
	If pRecord.ExtFile <> Undefined Then
		vBinaryData = pRecord.ExtFile.Get();
	EndIf;
	Return vBinaryData;
EndFunction // GetFileDataFromServer

// --------------------------------------------------------------------------------
&AtServer
Function CheckFileDataAtServer()
	vBinaryData = Undefined;
	pRecord = FormAttributeToValue("Record");
	If pRecord.ExtFile <> Undefined Then
		vBinaryData = pRecord.ExtFile.Get();
		If TypeOf(vBinaryData) = Type("BinaryData") Then
			Return True;
		EndIf;
	EndIf;
	Return False;
EndFunction // CheckFileDataAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenChooseFileToSaveToDialog()
	vFileSave = New FileDialog(FileDialogMode.Save);
	vFileSave.FullFileName = TrimAll(Record.FileName);
	vFileSave.Title = NStr("en='Save file to disk';ru='Сохранить файл';de='Datei speichern'");
	vFileSave.Preview = False;
	vFileSave.Show(New NotifyDescription("CommandActionSaveToFileNotification", ThisForm));
EndProcedure

// --------------------------------------------------------------------------------
&AtClient 
Procedure SaveFileInstallingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='File system extension was successfully installed on your browser!'; ru='Браузер успешно установлено расширение по работе с файлами!'; de='Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'"));
		OpenChooseFileToSaveToDialog();
	Else
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='Your browser does not support file operations in 1C!'; ru='Браузер не поддерживает работу с файлами в 1С!'; de='Ihr Browser unterstützt keine Dateioperationen in 1C!'"));
	EndIf;
EndProcedure // SaveFileInstallingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient 
Procedure SaveFileFileSystemExtensionInstallCompleted(pResult, pParam) Export
	BeginAttachingFileSystemExtension(New NotifyDescription("SaveFileInstallingFileSystemExtensionResult", ThisForm));
EndProcedure // SaveFileFileSystemExtensionInstallCompleted

// --------------------------------------------------------------------------------
&AtClient 
Procedure SaveFileAttachingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		OpenChooseFileToSaveToDialog();
	Else
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='File system extension is being installing on your browser...'; ru='Браузер устанавливается расширение по работе с файлами...'; de='Dateisystemerweiterung wird in Ihrem Browser installiert...'"));
		BeginInstallFileSystemExtension(New NotifyDescription("SaveFileFileSystemExtensionInstallCompleted", ThisForm));
	EndIf;
EndProcedure // SaveFileAttachingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure SaveFileGettingFilesCompleted(pTransferredFiles, pParam) Export
	tcCommonFunctionOnClientServer.UserMessage(NStr("en='File was successfully saved!'; ru='Файл успешно сохранен!'; de='File was successfully saved!'"));
EndProcedure // SaveFileGettingFilesCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure CommandActionSaveToFileNotification(pFileArray, pParam) Export
	If ValueIsFilled(pFileArray) Then
		vLocalFullFileName = pFileArray[0];
		#IF WebClient OR ThinClient OR MobileClient THEN
			// Get temp storage address with file data
			vTempStorageAddress = GetFileTempStorageAddress();
			// Create array of files to transfer from server to the client
			vFilesToBeObtained = New Array();
			vFileToBeObtained = New TransferableFileDescription(vLocalFullFileName, vTempStorageAddress);
			vFilesToBeObtained.Add(vFileToBeObtained);
			BeginGettingFiles(New NotifyDescription("SaveFileGettingFilesCompleted", ThisForm), vFilesToBeObtained, , False);
		#ELSE			
			vBinaryData = GetFileDataFromServer();
			vBinaryData.Write(vLocalFullFileName);
		#ENDIF
	EndIf;
EndProcedure // CommandActionSaveToFileNotification

// --------------------------------------------------------------------------------
&AtServer
Procedure CommandActionClearDataAtServer()
	vRecord = FormAttributeToValue("Record");
	vRecord.ExtFile = Undefined;
	// Clear file name, load time and last modification time
	vRecord.FileName = "";
	vRecord.FileLoadTime = Undefined;
	vRecord.FileLastChangeTime = Undefined;
	Items.FileName.ToolTip = NStr("en = 'File loaded: '; de = 'Datei geladen: '; ru = 'Загружен: '") + Format(vRecord.FileLoadTime, "DF='dd.MM.yyyy HH:mm:ss'") + " " +
						 	 NStr("en = 'Changed: '; de = 'Geändert: '; ru = 'Изменен: '") + Format(vRecord.FileLastChangeTime, "DF='dd.MM.yyyy HH:mm:ss'");
	vRecord.Write(True);
	ValueToFormAttribute(vRecord,"Record");
	ThisForm.Modified = False;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure CommandActionMakePhoto(Command)
	If amWebCamera = Undefined Then
		Try
			amWebCamera = tcCommonFunctions.cmGetCommonModule("tcWebCamDriver");
			a = amWebCamera.Connect();
		Except
			amWebCamera = Undefined;
		EndTry;
	EndIf;
	If amWebCamera <> Undefined Then
		vBinaryData = amWebCamera.MakeAPhoto(CheckWebCam(), GetFocTime()); 
		vPhotoPicture = New Picture(vBinaryData);
		CommandActionLoadFromFileAtServer(vBinaryData, NSTR("en = 'Webcam photo'; de = 'Webcam-Foto'; ru = 'Фото с вебкамеры'") + Format(CurrentDate(), "DF=_dd_mm_yyyy_hh_mm_ss") + ".jpg", CurrentDate());
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
// 
// Returns:
//  String - contains the number of currently selected WebCamera 
//
&AtServer
Function CheckWebCam()
	Return SessionParameters.CurrentWorkstation.WEBCamConnectionParameters.TwainDeviceName;
EndFunction 

// --------------------------------------------------------------------------------
// 
// Returns:
// Number  - The number of the frame to make a photo
//
&AtServer
Function GetFocTime()
	Return SessionParameters.CurrentWorkstation.WEBCamConnectionParameters.FocusTime;
EndFunction 

#EndRegion
