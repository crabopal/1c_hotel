
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Check if form settings mode is used
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	// Flag icon
	vObj = FormAttributeToValue("Object");
	vFlagPicture = vObj.Flag.Get();
	If vFlagPicture <> Undefined And TypeOf(vFlagPicture) = Type("Picture") Then
		vFlagBinaryData = vFlagPicture.GetBinaryData();
		FlagIcon = PutToTempStorage(vFlagBinaryData, UUID);
	Else
		FlagIcon = "";
	EndIf;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	If IsBlankString(FlagIcon) Then
		pCurrentObject.Flag = Undefined;
	Else
		vFlagBinaryData = GetFromTempStorage(FlagIcon);
		If vFlagBinaryData <> Undefined And TypeOf(vFlagBinaryData) = Type("BinaryData") Then
			vFlagPicture = New Picture(vFlagBinaryData);
			pCurrentObject.Flag = New ValueStorage(vFlagPicture);
		EndIf;
	EndIf;
EndProcedure // BeforeWriteAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure DescriptionTranslationsOpening(pItem, pStandardProcessing)
	pStandardProcessing = false;
	OpenForm("Catalog.Languages.Form.tcEditForm",New Structure("Text", Object.DescriptionTranslations), pItem);	
EndProcedure // DescriptionTranslationsOpening

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFlagIcon(Command)
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadFromFileAttachingFileSystemExtensionResult", ThisObject));
EndProcedure // LoadPhoto

// --------------------------------------------------------------------------------
&AtClient
Procedure ClearFlagIcon(pCommand)
	ClearFlagIconAtServer();
EndProcedure // ClearFlagIcon

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure CommandActionLoadFromFileAtServer(pBinaryData, pFileName, pFileLastChangeTime) 
	FlagIcon = PutToTempStorage(pBinaryData, UUID);
	Modified = True;
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
	BeginPuttingFiles(New NotifyDescription("FileDownloadToServerCompleted", ThisObject, pFile), vFilesArray, , False);
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
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadFromFileInstallingFileSystemExtensionResult", ThisObject));
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
		vFile.BeginGettingModificationTime(New NotifyDescription("LoadFileGettingModificationTimeCompleted", ThisObject, New Structure("FileName, FullFileName", vFile.Name, vFullFileName)));
	EndIf;
EndProcedure // OpenFileDialogToChooseFileCompleted

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
Procedure OpenFileDialogToChooseFile()
	vFileOpen = New FileDialog(FileDialogMode.Open);
	vFileOpen.Filter = NStr("ru = 'Картинки (*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf)|*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf|" +
	                               "bmp (*.bmp;*.dib;*.rle)|*.bmp;*.dib;*.rle|" + 
	                               "JPEG (*.jpg;*.jpeg)|*.jpg;*.jpeg|" + 
	                               "TIFF (*.tif)|*.tif|" + 
	                               "GIF (*.gif)|*.gif|" + 
	                               "PNG (*.png)|*.png|" + 
	                               "icon (*.ico)|*.ico|" + 
	                               "метафайл (*.wmf;*.emf)|*.wmf;*.emf|'; 
	                        |de = 'Картинки (*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf)|*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf|" +
	                               "bmp (*.bmp;*.dib;*.rle)|*.bmp;*.dib;*.rle|" + 
	                               "JPEG (*.jpg;*.jpeg)|*.jpg;*.jpeg|" + 
	                               "TIFF (*.tif)|*.tif|" + 
	                               "GIF (*.gif)|*.gif|" + 
	                               "PNG (*.png)|*.png|" + 
	                               "icon (*.ico)|*.ico|" + 
	                               "метафайл (*.wmf;*.emf)|*.wmf;*.emf|'; 
	                        |en = 'Pictures (*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf)|*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf|" +
	                               "bmp (*.bmp;*.dib;*.rle)|*.bmp;*.dib;*.rle|" + 
	                               "JPEG (*.jpg;*.jpeg)|*.jpg;*.jpeg|" + 
	                               "TIFF (*.tif)|*.tif|" + 
	                               "GIF (*.gif)|*.gif|" + 
	                               "PNG (*.png)|*.png|" + 
	                               "icon (*.ico)|*.ico|" + 
	                               "metafile (*.wmf;*.emf)|*.wmf;*.emf|'");

	vFileOpen.Multiselect = False;
	vFileOpen.Title = NStr("en='Open file';ru='Открыть файл';de='Datei öffnen'");
	vFileOpen.Preview = True;
	vFileOpen.Show(New NotifyDescription("OpenFileDialogToChooseFileCompleted", ThisObject));
EndProcedure // OpenFileDialogToChooseFile

// --------------------------------------------------------------------------------
&AtServer
Procedure ClearFlagIconAtServer()
	FlagIcon = "";
	Modified = True;
EndProcedure // ClearFlagIconAtServer

#EndRegion
