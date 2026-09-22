
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Form caption
	ThisForm.AutoTitle = False;
	ThisForm.Title = cmNStr(Object.Description, SessionParameters.CurrentLanguage);
	// Processing type
	ExternalProcessingTypeOnChangeAtServer();
	// File
	vObj = FormAttributeToValue("Object");
	vFileBinaryData = vObj.ExternalProcessingStorage.Get();
	If vFileBinaryData <> Undefined And TypeOf(vFileBinaryData) = Type("BinaryData") Then
		FileTempStorage = PutToTempStorage(vFileBinaryData, ThisForm.UUID);
	Else
		FileTempStorage = "";
	EndIf;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	If IsBlankString(FileTempStorage) Then
		pCurrentObject.ExternalProcessingStorage = Undefined;
	Else
		vFileBinaryData = GetFromTempStorage(FileTempStorage);
		If vFileBinaryData <> Undefined And TypeOf(vFileBinaryData) = Type("BinaryData") Then
			pCurrentObject.ExternalProcessingStorage = New ValueStorage(vFileBinaryData);
		EndIf;
	EndIf;
EndProcedure // BeforeWriteAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ExternalProcessingTypeOnChange(pItem)
	ExternalProcessingTypeOnChangeAtServer();
EndProcedure // ExternalProcessingTypeOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure DescriptionOpening(pItem, pStandardProcessing)
	pStandardProcessing = false;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", Object.Description), pItem);
EndProcedure // DescriptionOpening

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFile(pCommand)
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadFromFileAttachingFileSystemExtensionResult", ThisForm));
EndProcedure // LoadFile

// --------------------------------------------------------------------------------
&AtClient
Procedure ClearFile(pCommand)
	ClearFileAtServer();
EndProcedure // ClearFile

// --------------------------------------------------------------------------------
&AtClient
Procedure SaveFile(Command)
	If Not IsBlankString(FileTempStorage) Then
		OpenFileDialogToSaveFile();		
	EndIf;
EndProcedure // SaveFile

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure ExternalProcessingTypeOnChangeAtServer()
	If Object.ExternalProcessingType = Enums.ExternalProcessingTypes.Algorithm Then
		Items.GroupAlgorithm.Visible = True;
		Items.GroupFile.Visible = False;
	ElsIf Object.ExternalProcessingType = Enums.ExternalProcessingTypes.DataProcessor Or
	      Object.ExternalProcessingType = Enums.ExternalProcessingTypes.Report Then
		Items.GroupAlgorithm.Visible = False;
		Items.GroupFile.Visible = True;
	Else
		Items.GroupAlgorithm.Visible = False;
		Items.GroupFile.Visible = False;
	EndIf;
EndProcedure // ExternalProcessingTypeOnChangeAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure CommandActionLoadFromFileAtServer(pBinaryData, pFileName, pFileLastChangeTime) 
	FileTempStorage = PutToTempStorage(pBinaryData, ThisForm.UUID);
	If Object.FileName <> pFileName Or Not ValueIsFilled(Object.FileLoadTime) Then
		Object.FileLoadTime = CurrentSessionDate();
	EndIf;
	Object.FileName = pFileName;
	Object.FileLastChangeTime = pFileLastChangeTime;
	ThisForm.Modified = True;
EndProcedure // CommandActionLoadFromFileAtServer

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
EndProcedure // FileDownloadToServerCompleted

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
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension was successfully installed on your browser!'; ru='В браузер успешно установлено расширение по работе с файлами!'; de='Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'"), MessageStatus.Information);
		OpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Your browser does not support file operations in 1C!'; ru='Браузер не поддерживает работу с файлами в 1С!'; de='Ihr Browser unterstützt keine Dateioperationen in 1C!'"), MessageStatus.Attention);
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
Procedure OpenFileDialogToChooseFileCompleted(pFileArray, pParam) Export 
	If ValueIsFilled(pFileArray) Then
		vFullFileName = pFileArray[0];
		vFile = New File(vFullFileName);
		vFile.BeginGettingModificationTime(New NotifyDescription("LoadFileGettingModificationTimeCompleted", ThisForm, New Structure("FileName, FullFileName", vFile.Name, vFullFileName)));
	EndIf;
EndProcedure // OpenFileDialogToChooseFileCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFromFileAttachingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		OpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension is being installing on your browser...'; ru='В браузер устанавливается расширение по работе с файлами...'; de='Dateisystemerweiterung wird in Ihrem Browser installiert...'"), MessageStatus.Information);
		BeginInstallFileSystemExtension(New NotifyDescription("LoadFromFileFileSystemExtensionInstallCompleted", ThisForm));
	EndIf;
EndProcedure // LoadFromFileAttachingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient 
Procedure OpenFileDialogToChooseFile()
	vFileOpen = New FileDialog(FileDialogMode.Open);
	If Object.ExternalProcessingType = PredefinedValue("Enum.ExternalProcessingTypes.DataProcessor") Then
		vFileOpen.Filter = NStr("ru = 'Внешняя обработка (*.epf)|*.epf;|'; 
		                        |de = 'Externe Bearbeitung (*.epf)|*.epf;|'; 
		                        |en = 'External processing (*.epf)|*.epf;|'");
	ElsIf Object.ExternalProcessingType = PredefinedValue("Enum.ExternalProcessingTypes.Report") Then
		vFileOpen.Filter = NStr("ru = 'Внешний отчет (*.erf)|*.erf;|'; 
		                        |de = 'Externer Bericht (*.erf)|*.erf;|'; 
		                        |en = 'External report (*.erf)|*.erf;|'");
	EndIf;
	vFileOpen.Multiselect = False;
	vFileOpen.Title = NStr("en='Open file';ru='Открыть файл';de='Datei öffnen'");
	vFileOpen.Preview = True;
	vFileOpen.Show(New NotifyDescription("OpenFileDialogToChooseFileCompleted", ThisForm));
EndProcedure // OpenFileDialogToChooseFile

// --------------------------------------------------------------------------------
&AtServer
Procedure ClearFileAtServer()
	FileTempStorage = "";
	Object.FileName = "";
	Object.FileLastChangeTime = '00010101';
	Object.FileLoadTime = '00010101';
	ThisForm.Modified = True;
EndProcedure // ClearPhotoAtServer

// --------------------------------------------------------------------------------
&AtClient 
Procedure OpenFileDialogToSaveFile()
	vFileSave = New FileDialog(FileDialogMode.Save);
	If Object.ExternalProcessingType = PredefinedValue("Enum.ExternalProcessingTypes.DataProcessor") Then
		vFileSave.Filter = NStr("ru = 'Внешняя обработка (*.epf)|*.epf;|'; 
		                        |de = 'Externe Bearbeitung (*.epf)|*.epf;|'; 
		                        |en = 'External processing (*.epf)|*.epf;|'");
		vFileSave.DefaultExt = "epf";
	ElsIf Object.ExternalProcessingType = PredefinedValue("Enum.ExternalProcessingTypes.Report") Then
		vFileSave.Filter = NStr("ru = 'Внешний отчет (*.erf)|*.erf;|'; 
		                        |de = 'Externer Bericht (*.erf)|*.erf;|'; 
		                        |en = 'External report (*.erf)|*.erf;|'");
		vFileSave.DefaultExt = "erf";
	EndIf;
	vFileSave.Multiselect = False;
	vFileSave.Title = NStr("en='Save file';ru='Сохранить файл';de='Datei speichern'");
	vFileSave.CheckFileExist = True;
	vFileSave.Show(New NotifyDescription("OpenFileDialogToSaveFileCompleted", ThisForm));
EndProcedure // OpenFileDialogToSaveFile

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileDialogToSaveFileCompleted(pFileArray, pParam) Export 
	If ValueIsFilled(pFileArray) Then
		vFullFileName = pFileArray[0];
		vFileBinaryData = GetFromTempStorage(FileTempStorage);
		If vFileBinaryData <> Undefined And TypeOf(vFileBinaryData) = Type("BinaryData") Then
			vFileBinaryData.BeginWrite(New NotifyDescription("SaveFileAfterWrite", ThisForm), vFullFileName);
		EndIf;
	EndIf;
EndProcedure // OpenFileDialogToSaveFileCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure SaveFileAfterWrite(pExtraParams) Export
	ShowMessageBox(, NStr("en='Success!'; ru='Успешно!'; de='Erfolg!'"), 3);
EndProcedure // SaveFileAfterWrite

#EndRegion


