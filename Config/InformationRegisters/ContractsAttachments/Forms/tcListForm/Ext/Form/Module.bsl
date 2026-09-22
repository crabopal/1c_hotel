
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Customer) Then
		pCancel = True;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormTableListItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ListSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	If pField.Name = "FileName" Then
		pStandardProcessing = False;
		vRow = Items.List.RowData(pSelectedRow);
		ActionOpenFile(vRow.Period, vRow.Contract);
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ListBeforeDeleteRow(pItem, pCancel)
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToEditReservationDocumentNumberAndDate") Then
		pCancel = True;
	EndIf;
EndProcedure // ListBeforeDeleteRow

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Function GetFileBinaryData(pPeriod, pContract, rFileName)
    vRecord = InformationRegisters.ContractsAttachments.CreateRecordManager();
	vRecord.Period = pPeriod;
	vRecord.Contract = pContract;
	vRecord.Read();
	If vRecord.Selected() Then
		rFileName = vRecord.FileName;
		Return vRecord.ExtFile.Get();
	Else
		Return Undefined;
	EndIf;
EndFunction // GetFileBinaryData

// --------------------------------------------------------------------------------
&AtServerNoContext
Function IsFileEditable(pExtension)
	Return cmIsFileEditable(pExtension);
EndFunction // IsFileEditable

// --------------------------------------------------------------------------------
&AtServer
Function GetFileTempStorageAddress(pPeriod, pContract, rFileName)
    vRecord = InformationRegisters.ContractsAttachments.CreateRecordManager();
	vRecord.Period = pPeriod;
	vRecord.Contract = pContract;
	vRecord.Read();
	If vRecord.Selected() Then
		rFileName = vRecord.FileName;
		vBinaryData = vRecord.ExtFile.Get();
		Return PutToTempStorage(vBinaryData);
	Else
		Return Undefined;
	EndIf;
EndFunction // GetFileTempStorageAddress

// --------------------------------------------------------------------------------
&AtClient 
Procedure OpenFileRunningApplicationCompleted(pReturnCode, pParam) Export
	// If file is editable then ask user to save it back
	vFile = New File(pParam.LocalFullFileName);
	If IsFileEditable(vFile.Extension) Then
		ShowQueryBox(New NotifyDescription("AfterClosedQueryBox", ThisForm, pParam),
		             NStr("en='Save document changes to the database?';ru='Сохранить измененный документ в базу данных?';de='Das geänderte Dokument in der Datenbank speichern?'"), QuestionDialogMode.YesNo);
	EndIf;
EndProcedure // OpenFileRunningApplicationCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileGettingFilesCompleted(pTransferredFiles, pParam) Export
	vLocalFullFileName = pTransferredFiles.Get(0).Name;
	// Open temp file in application
	BeginRunningApplication(New NotifyDescription("OpenFileRunningApplicationCompleted", ThisForm, pParam), vLocalFullFileName, pParam.TempFilesDir, False);
EndProcedure // OpenFileGettingFilesCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileGettingTempFilesDirCompleted(pTempFilesDir, pParam) Export
	pParam.TempFilesDir = pTempFilesDir;
	// Get temp storage address with file data
	rFileName = "";
	vTempStorageAddress = GetFileTempStorageAddress(pParam.Period, pParam.Contract, rFileName);
	pParam.TempStorageAddress = vTempStorageAddress;
	// Build local temp file name
	vLocalFullFileName = pTempFilesDir + rFileName;
	pParam.LocalFullFileName = vLocalFullFileName;
	// Create array of files to transfer from server to the client
	vFilesToBeObtained = New Array();
	vFileToBeObtained = New TransferableFileDescription(vLocalFullFileName, vTempStorageAddress);
	vFilesToBeObtained.Add(vFileToBeObtained);
	BeginGettingFiles(New NotifyDescription("OpenFileGettingFilesCompleted", ThisForm, pParam), vFilesToBeObtained, , False);
EndProcedure // OpenFileGettingTempFilesDirCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileInstallingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='File system extension was successfully installed on your browser!'; ru='Браузер успешно установлено расширение по работе с файлами!'; de='Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'"));
		// Getting temp files dir
		BeginGettingTempFilesDir(New NotifyDescription("OpenFileGettingTempFilesDirCompleted", ThisForm, pParam));
	Else
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='Your browser does not support file operations in 1C!'; ru='Браузер не поддерживает работу с файлами в 1С!'; de='Ihr Browser unterstützt keine Dateioperationen in 1C!'"));
	EndIf;
EndProcedure // OpenFileInstallingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileFileSystemExtensionInstallCompleted(pParam) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("OpenFileInstallingFileSystemExtensionResult", ThisForm, pParam));
EndProcedure // OpenFileFileSystemExtensionInstallCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileAttachingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		// Getting temp files dir
		BeginGettingTempFilesDir(New NotifyDescription("OpenFileGettingTempFilesDirCompleted", ThisForm, pParam));
	Else
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='File system extension is being installing on your browser...'; ru='В браузер устанавливается расширение по работе с файлами...'; de='Dateisystemerweiterung wird in Ihrem Browser installiert...'"));
		BeginInstallFileSystemExtension(New NotifyDescription("OpenFileFileSystemExtensionInstallCompleted", ThisForm, pParam));
	EndIf;
EndProcedure // OpenFileAttachingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure ActionOpenFile(pPeriod, pContract)
	#IF WebClient OR ThinClient OR MobileClient THEN
		BeginAttachingFileSystemExtension(New NotifyDescription("OpenFileAttachingFileSystemExtensionResult", ThisForm, New Structure("Period, Contract, TempStorageAddress, TempFilesDir, LocalFullFileName", pPeriod, pContract, "", "", "")));
	#ELSE
		rFileName = "";
		vBinary = GetFileBinaryData(pPeriod, pContract, rFileName);
		If vBinary <> Undefined And Not IsBlankString(rFileName) Then
			Try
				// Save file to disk
				vLocalFullFileName = TempFilesDir() + Trimall(rFileName);
				vBinary.Write(vLocalFullFileName);
				// Open temp file in application
				BeginRunningApplication(New NotifyDescription("AfterRunApp", ThisForm, New Structure("Period, Contract, LocalFullFileName", pPeriod, pContract, vLocalFullFileName)), vLocalFullFileName, TempFilesDir(), False);
			Except
				ShowMessageBox(, ErrorDescription());
			EndTry;
		Else
			ShowMessageBox(, NStr("en='File was not loaded!';ru='Файл не загружен!';de='Datei wurde nicht geladen!'"));
		EndIf;
	#ENDIF
EndProcedure // ActionOpenFile

// --------------------------------------------------------------------------------
&AtServer
Procedure AfterClosedQueryBoxAtServer(pParams, pBinaryData)
	vRecord = InformationRegisters.ContractsAttachments.CreateRecordManager();
	vRecord.Period = pParams.Period;
	vRecord.Contract = pParams.Contract;
	vRecord.Read();
	If vRecord.Selected() Then
		vRecord.ExtFile = New ValueStorage(pBinaryData);
		vRecord.FileLastChangeTime = CurrentSessionDate();
		vRecord.Write(True);
	EndIf;
EndProcedure // AfterClosedQueryBoxAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure UpdatedFileDownloadToServerCompletedAtServer(pTempStorageFileAddress, pParam)
	vBinaryData = GetFromTempStorage(pTempStorageFileAddress);
	AfterClosedQueryBoxAtServer(pParam, vBinaryData);
EndProcedure // UpdatedFileDownloadToServerCompletedAtServer

// --------------------------------------------------------------------------------
&AtClient 
Procedure UpdatedFileDownloadToServerCompleted(pTransferredFiles, pParam) Export
	vTempStorageFileAddress = pTransferredFiles.Get(0).Location;
	UpdatedFileDownloadToServerCompletedAtServer(vTempStorageFileAddress, pParam);
EndProcedure // UpdatedFileDownloadToServerCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure AfterRunApp(pResult, pParams) Export
	// If file is editable then ask user to save it back
	vFile = New File(pParams.LocalFullFileName);
	If IsFileEditable(vFile.Extension) Then
		ShowQueryBox(New NotifyDescription("AfterClosedQueryBox", ThisForm, pParams),
		             NStr("en='Save document changes to the database?'; ru='Сохранить измененный документ в базу данных?'; de='Das geänderte Dokument in der Datenbank speichern?'"), QuestionDialogMode.YesNo);
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure AfterClosedQueryBox(pResult, pParams) Export 
	If pResult = DialogReturnCode.Yes Then
		#IF WebClient OR ThinClient OR MobileClient THEN
			vFile = New File(pParams.LocalFullFileName);
			vFilesArray = New Array();
			vFileDescription = New TransferableFileDescription(pParams.LocalFullFileName);
			vFilesArray.Add(vFileDescription);
			BeginPuttingFiles(New NotifyDescription("UpdatedFileDownloadToServerCompleted", ThisForm, pParams), vFilesArray, , False);
		#ELSE
			vBinary = New BinaryData(pParams.LocalFullFileName);
			AfterClosedQueryBoxAtServer(pParams, vBinary);
		#ENDIF
	EndIf;
EndProcedure

#EndRegion
