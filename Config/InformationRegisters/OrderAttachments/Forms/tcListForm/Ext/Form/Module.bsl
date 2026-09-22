

#Region FormTableListItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ListSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	If pField.Name = "FileName" Then
		vRow = Items.List.RowData(pSelectedRow);
		ActionOpenFile(vRow.Period, vRow.Order);
	Else
		OpenForm("InformationRegister.OrderAttachments.Form.tcRecordForm", New Structure("Key", pSelectedRow));
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ListBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder, pParameter)
	pCancel = True;   
	If List.Filter.Items.Count() > 0 Then
		vFilter = New Structure("Order", List.Filter.Items.Get(0).RightValue);    
	Else
		vFilter = New Structure;
	EndIf;
	OpenForm("InformationRegister.OrderAttachments.Form.tcRecordForm", vFilter);
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Function GetFileBinaryData(pPeriod, pOrder, rFileName)
    vRecord = InformationRegisters.OrderAttachments.CreateRecordManager();
	vRecord.Period = pPeriod;
	vRecord.Order = pOrder;
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
Function GetFileTempStorageAddress(pPeriod, pOrder, rFileName)
    vRecord = InformationRegisters.OrderAttachments.CreateRecordManager();
	vRecord.Period = pPeriod;
	vRecord.Order = pOrder;
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
		             NStr("en='Save document changes to the database?';ru='Сохранить измененный документ в базу данных?';de='Das geänderte Dokument in der Datenbank speichern?'"), 
					 QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
	EndIf;
EndProcedure // OpenFileRunningApplicationCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileGettingFilesCompleted(pTransferredFiles, pParam) Export
	vLocalFullFileName = pTransferredFiles.Get(0).Name;
	// Open temp file in application
	BeginRunningApplication(New NotifyDescription("OpenFileRunningApplicationCompleted", ThisForm, pParam), vLocalFullFileName, pParam.TempFilesDir, True);
EndProcedure // OpenFileGettingFilesCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileGettingTempFilesDirCompleted(pTempFilesDir, pParam) Export
	pParam.TempFilesDir = pTempFilesDir;
	// Get temp storage address with file data
	rFileName = "";
	vTempStorageAddress = GetFileTempStorageAddress(pParam.Period, pParam.Order, rFileName);
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
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension was successfully installed on your browser!'; ru='В браузер успешно установлено расширение по работе с файлами!'; de='Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'"), MessageStatus.Information);
		// Getting temp files dir
		BeginGettingTempFilesDir(New NotifyDescription("OpenFileGettingTempFilesDirCompleted", ThisForm, pParam));
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Your browser does not support file operations in 1C!'; ru='Браузер не поддерживает работу с файлами в 1С!'; de='Ihr Browser unterstützt keine Dateioperationen in 1C!'"), MessageStatus.Attention);
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
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension is being installing on your browser...'; ru='В браузер устанавливается расширение по работе с файлами...'; de='Dateisystemerweiterung wird in Ihrem Browser installiert...'"), MessageStatus.Information);
		BeginInstallFileSystemExtension(New NotifyDescription("OpenFileFileSystemExtensionInstallCompleted", ThisForm, pParam));
	EndIf;
EndProcedure // OpenFileAttachingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure ActionOpenFile(pPeriod, pOrder)
	#IF WebClient OR ThinClient OR MobileClient THEN
		BeginAttachingFileSystemExtension(New NotifyDescription("OpenFileAttachingFileSystemExtensionResult", ThisForm, New Structure("Period, Order, TempStorageAddress, TempFilesDir, LocalFullFileName", pPeriod, pOrder, "", "", "")));
	#ELSE
		rFileName = "";
		vBinary = GetFileBinaryData(pPeriod, pOrder, rFileName);
		If vBinary <> Undefined And Not IsBlankString(rFileName) Then
			Try
				// Save file to disk
				vLocalFullFileName = TempFilesDir() + Trimall(rFileName);
				vBinary.Write(vLocalFullFileName);
				// Open temp file in application
				BeginRunningApplication(New NotifyDescription("AfterRunApp", ThisForm, New Structure("Period, Order, LocalFullFileName", pPeriod, pOrder, vLocalFullFileName)), vLocalFullFileName, TempFilesDir(), True);
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
	vRecord = InformationRegisters.OrderAttachments.CreateRecordManager();
	vRecord.Period = pParams.Period;
	vRecord.Order = pParams.Order;
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
	Try
		// If file is editable then ask user to save it back
		vFile = New File(pParams.LocalFullFileName);
		If IsFileEditable(vFile.Extension) Then
			ShowQueryBox(New NotifyDescription("AfterClosedQueryBox", ThisForm, pParams),
			             NStr("en='Save document changes to the database?'; ru='Сохранить измененный документ в базу данных?'; de='Das geänderte Dokument in der Datenbank speichern?'"), 
						 QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
		EndIf;
	Except
		ShowMessageBox(, ErrorDescription());
	EndTry;	
EndProcedure // AfterRunApp

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
