#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure NodeOnChange(pItem)
	If Not ValueIsFilled(Record.SenderNode) And Not ValueIsFilled(Record.ReceiverNode) Then 
		vExchangePlansRefs = GetExchangePlansRefsType();
		
		Items.SenderNode.TypeRestriction = vExchangePlansRefs;
		Record.SenderNode = vExchangePlansRefs.AdjustValue(Record.SenderNode);
		
		Items.ReceiverNode.TypeRestriction = vExchangePlansRefs;
		Record.ReceiverNode = vExchangePlansRefs.AdjustValue(Record.ReceiverNode);
	EndIf;
EndProcedure // NodeOnChange

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFromFile(pCommand)
	#IF WebClient OR ThinClient OR MobileClient THEN
		BeginAttachingFileSystemExtension(New NotifyDescription("LoadFromFileAttachingFileSystemExtensionResult", ThisForm));
	#ELSE
		OpenFileDialogToChooseFile();
	#ENDIF
EndProcedure // LoadFromFile

// --------------------------------------------------------------------------------
&AtClient
Procedure SaveToFile(pCommand)
	If Not CheckFileDataAtServer() Then
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='No external file was loaded!';ru='Внешний файл не был загружен!';de='Die externe Datei wurde nicht geladen!'"));
		Return;
	EndIf;
	#IF WebClient OR ThinClient OR MobileClient THEN
		BeginAttachingFileSystemExtension(New NotifyDescription("SaveFileAttachingFileSystemExtensionResult", ThisForm));
	#ELSE
		OpenChooseFileToSaveToDialog();
	#ENDIF
EndProcedure // SaveToFile

// --------------------------------------------------------------------------------
&AtClient
Procedure ClearData(pCommand)
	ClearDataAtServer();	
EndProcedure // ClearData

#EndRegion

#Region Private

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
Procedure LoadFromFileFileSystemExtensionInstallCompleted(pParam) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadFromFileInstallingFileSystemExtensionResult", ThisForm));
EndProcedure // LoadFromFileFileSystemExtensionInstallCompleted

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
Procedure OpenFileDialogToChooseFile()
	vFileOpen = New FileDialog(FileDialogMode.Open);
	vFileOpen.Filter = NStr("ru = 'Сообщение с изменениями (*.zip)|*.zip|'; en = 'Change message (*.zip)|*.zip|'; de = 'Nachricht ändern (*.zip)|*.zip|'");
	vFileOpen.Multiselect = False;
	vFileOpen.Title = NStr("en='Open file';ru='Открыть файл';de='Datei öffnen'");
	vFileOpen.Preview = True;
	vFileOpen.Show(New NotifyDescription("CommandActionLoadFromFileNotification", ThisForm));
EndProcedure // OpenFileDialogToChooseFile

// --------------------------------------------------------------------------------
&AtClient
Procedure CommandActionLoadFromFileNotification(pFileArray, pParam) Export 
	If ValueIsFilled(pFileArray) Then
		vFullFileName = pFileArray[0];
		vFile = New File(vFullFileName);
		#IF WebClient OR ThinClient OR MobileClient THEN
			vFile.BeginGettingModificationTime(New NotifyDescription("LoadFileGettingModificationTimeCompleted", ThisForm, New Structure("FileSize, FullFileName", vFile.Size(), vFullFileName)));
		#ELSE
			vBinaryData = New BinaryData(vFullFileName);
			LoadFromFileAtServer(vBinaryData, vFile.Size());
		#ENDIF
	EndIf;
EndProcedure // CommandActionLoadFromFileNotification

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFileGettingModificationTimeCompleted(pModificationTime, pParams) Export
	LoadFileInWebClient(pParams.FullFileName, pParams.FileSize);
EndProcedure // LoadFileGettingModificationTimeCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFileInWebClient(pFullFileName, pFileSize)
	vFilesArray = New Array();
	vFileDescription = New TransferableFileDescription(pFullFileName);
	vFilesArray.Add(vFileDescription);
	BeginPuttingFiles(New NotifyDescription("FileDownloadToServerCompleted", ThisForm, pFileSize), vFilesArray, , False);
EndProcedure // LoadFileInWebClient

// --------------------------------------------------------------------------------
&AtClient
Procedure FileDownloadToServerCompleted(pTransferredFiles, pFileSize) Export
	FileDownloadToServerCompletedAtServer(pTransferredFiles, pFileSize);
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure FileDownloadToServerCompletedAtServer(pTransferredFiles, pFileSize)
	vBinaryData = GetFromTempStorage(pTransferredFiles.Get(0).Location);
	LoadFromFileAtServer(vBinaryData, pFileSize);
EndProcedure // FileDownloadToServerCompletedAtServer

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
Procedure SaveFileFileSystemExtensionInstallCompleted(pResult, pParam) Export
	BeginAttachingFileSystemExtension(New NotifyDescription("SaveFileInstallingFileSystemExtensionResult", ThisForm));
EndProcedure // SaveFileFileSystemExtensionInstallCompleted

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
Procedure OpenChooseFileToSaveToDialog()
	vFileSave = New FileDialog(FileDialogMode.Save);
	vFileSave.Filter = "ZIP (*.zip)|*.zip";
	vFileSave.Title = NStr("en='Save file to disk';ru='Сохранить файл';de='Datei speichern'");
	vFileSave.Preview = False;
	vFileSave.Show(New NotifyDescription("SaveToFileAtServer", ThisForm));
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Function GetFileDataFromServer()
	vBinaryData = Undefined;
	pRecord = FormAttributeToValue("Record");
	If pRecord.XMLValue <> Undefined Then
		vBinaryData = pRecord.XMLValue.Get();
	EndIf;
	Return vBinaryData;
EndFunction // GetFileDataFromServer

// --------------------------------------------------------------------------------
&AtServer
Function CheckFileDataAtServer()
	vBinaryData = Undefined;
	pRecord = FormAttributeToValue("Record");
	If pRecord.XMLValue <> Undefined Then
		vBinaryData = pRecord.XMLValue.Get();
		If TypeOf(vBinaryData) = Type("BinaryData") Then
			Return True;
		EndIf;
	EndIf;
	Return False;
EndFunction // CheckFileDataAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure SaveFileGettingFilesCompleted(pTransferredFiles, pParam) Export
	tcCommonFunctionOnClientServer.UserMessage(NStr("en='File was successfully saved!'; ru='Файл успешно сохранен!'; de='File was successfully saved!'"));
EndProcedure // SaveFileGettingFilesCompleted

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetExchangePlansRefsType()
	Return ExchangePlans.AllRefsType();
EndFunction // GetExchangePlansRefsType

// --------------------------------------------------------------------------------
&AtServer
Function GetFileTempStorageAddress()
    vRecord = FormAttributeToValue("Record");
	vBinaryData = vRecord.XMLValue.Get();
	Return PutToTempStorage(vBinaryData);
EndFunction // GetFileTempStorageAddress

// --------------------------------------------------------------------------------
&AtServer
Procedure LoadFromFileAtServer(pBinaryData, pFileSize)
	vRecord = FormAttributeToValue("Record");
	vRecord.XMLValue = New ValueStorage(pBinaryData);
	vRecord.FileSize = Round(pFileSize / 1024, 2, RoundMode.Round15as20);
	vRecord.Write(True);
	ValueToFormAttribute(vRecord, "Record");
	ThisForm.Modified = False;
EndProcedure // LoadFromFileAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure SaveToFileAtServer(pFileArray, pParam) Export 
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
EndProcedure // ClearDataAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure ClearDataAtServer()
	vRecord = FormAttributeToValue("Record");
	vRecord.XMLValue = Undefined;
	vRecord.FileSize = 0;
	vRecord.Write(True);
	ValueToFormAttribute(vRecord, "Record");
	ThisForm.Modified = False;
EndProcedure // ClearDataAtServer

#EndRegion





