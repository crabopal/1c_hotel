
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("SelNode") Then
		SelNode = Parameters.SelNode;	
	EndIf;
	SystemSettingsStorageLoad();
	RefreshDisplay();
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeClose(pCancel, pExit, pMessageText, pStandardProcessing)
	SystemSettingsStorageSave();
	If ValueIsFilled(SelTempAddress) And IsTempStorageURL(SelTempAddress) Then
		DeleteFromTempStorage(SelTempAddress);	
	EndIf;
EndProcedure // BeforeClose

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SelUseZipOnChange(pItem)
	RefreshDisplay();
EndProcedure //  SelUseZipOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelUseFTPOnChange(pItem)
	RefreshDisplay();
EndProcedure // SelUseFTPOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelPathStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadFromFileAttachingFileSystemExtensionResult", ThisForm));
EndProcedure // SelPathStartChoice

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionOK(pCommand)
	If Not ValueIsFilled(SelNode) Then
		ShowMessageBox(, NStr("en='Exchange node is not set!';ru='Узел обмена не указан!';de='Austauschknoten nicht angegeben!'"));
		Return;
	EndIf; 
	If pCommand.Name = "ActionOK" Then 
		ActionOKAtServer();
	Else
		SelTempAddress = ExchangePlansProcessing.ExchangePlansWriteConfigurationChanges(SelNode, SelPath, SelFileName, SelExchangeFileName, SelUseZip, SelZIPPwd, UUID, SelUseFTP, SelInternetConnectionSettings, SelFTPAddress, SelFTPPort, SelFTPUser, SelFTPPwd, SelUsePassiveMode, SelFTPConnectionTimeout);	
	EndIf;
	If ValueIsFilled(SelPath) And ValueIsFilled(SelTempAddress) And Not SelUseFTP Then
		vDirPath = TrimAll(SelPath);
		vDirPath = StrReplace(vDirPath, "\", "/");
		If Right(vDirPath, 1) <> "/" Then
			vDirPath = vDirPath + "/";
		EndIf;
		vBinaryData = GetFromTempStorage(SelTempAddress);
		vBinaryData.Write(vDirPath + SelExchangeFileName);
	EndIf;
	Notify("tcWriteExchangePlanNodeChanges.Сompleted");
	ShowMessageBox(New NotifyDescription("AfterShowMessageBox", ThisForm), NStr("en='Operation completed!';ru='Операция выполнена!';de='Die Operation wurde ausgeführt'"));
EndProcedure // ActionOK

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure ActionOKAtServer()
	WriteExchangePlanChanges();
EndProcedure // ActionOKAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterShowMessageBox(pExtraParams) Export 
	Close();	
EndProcedure // AfterShowMessageBox

// -----------------------------------------------------------------------------
&AtServer
Procedure RefreshDisplay()
	If SelUseZip Then
		Items.SelZIPPwd.Enabled = True;
	Else
		Items.SelZIPPwd.Enabled = False;
	EndIf;
	If SelUseFTP Then
		Items.SelFTPAddress.Enabled = True;
		Items.SelFTPUser.Enabled = True;
		Items.SelFTPPwd.Enabled = True;
		Items.SelFTPPort.Enabled = True;
		Items.SelFTPConnectionTimeout.Enabled = True;
		Items.SelUsePassiveMode.Enabled = True;
		Items.SelInternetConnectionSettings.Enabled = True;
	Else
		Items.SelFTPAddress.Enabled = False;
		Items.SelFTPUser.Enabled = False;
		Items.SelFTPPwd.Enabled = False;
		Items.SelFTPPort.Enabled = False;
		Items.SelFTPConnectionTimeout.Enabled = False;
		Items.SelUsePassiveMode.Enabled = False;
		Items.SelInternetConnectionSettings.Enabled = False;
	EndIf;
EndProcedure // RefreshDisplay

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
Procedure LoadFromFileFileSystemExtensionInstallCompleted(pParam) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadFromFileInstallingFileSystemExtensionResult", ThisForm));
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
	vFileOpen.Directory = SelPath;
	vFileOpen.Multiselect = False;
	vFileOpen.Title = NStr("en='Choose directory';ru='Выбрать папку';de='Ordner auswählen'");
	vFileOpen.Preview = False;
	vFileOpen.Show(New NotifyDescription("OpenFileDialogToChooseFileCompleted", ThisForm));
EndProcedure // OpenFileDialogToChooseFile

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileDialogToChooseFileCompleted(pFileArray, pParam) Export 
	If ValueIsFilled(pFileArray) Then
		SelPath = pFileArray[0];
	EndIf;
EndProcedure // OpenFileDialogToChooseFileCompleted

// -----------------------------------------------------------------------------
&AtServer
Procedure WriteExchangePlanChanges()
	If Not ValueIsFilled(SelNode) Then
		Raise NStr("en='Node to send changes to is not set!';ru='Не выбран узел для отправки изменений!';de='Kein Knoten zum Versenden von Änderungen ist gewählt!'");
	EndIf;
	// Get and check this node
	vThisNode = ExchangePlansProcessing.GetThisNode(SelNode);
	If vThisNode = Undefined Then
		Raise NStr("en='<This node> is not defined for the current configuration!';ru='В текущей конфигурации не определен <Этот узел>!';de='In der aktuellen Konfiguration ist <Dieser Knoten> nicht festgelegt!'");
	EndIf;
	If SelNode = vThisNode Then
		Raise NStr("en='Node to send changes to should not be this node!';ru='Нельзя отправлять изменения в текущий узел!';de='Änderungen dürfen nicht an den aktuellen Knoten gesendet werden!'");
	EndIf;
	
	SelTempAddress = "";
	
	// Get temporal directory path and initialize file name
	vTempDirPath = TrimAll(TempFilesDir());
	vTempDirPath = StrReplace(vTempDirPath, "\", "/");
	If Right(vTempDirPath, 1) <> "/" Then
		vTempDirPath = vTempDirPath + "/";
	EndIf;
	
	// Check path to write data to
	vTargetAddress = StrReplace(TrimAll(SelPath), "\", "/");
	If Right(vTargetAddress, 1) <> "/" Then
		vTargetAddress = vTargetAddress + "/";
	EndIf;
	
	// Initialize file name
	SelFileName = "Message_" + Upper(TrimAll(vThisNode.Code)) + "_" + Upper(TrimAll(SelNode.Code));
	
	// Build file name to be used further
	SelExchangeFileName = SelFileName + ?(SelUseZip, ".zip", ".xml");
	
	// Initialize number of attempts. Use 1 if function is running interactively and 20 if function is running on server
	vNumberOfAttempts = 1;
	If Left(InfoBaseConnectionString(), 5) <> "File=" Then
		vNumberOfAttempts = 20;
	EndIf;
	
	// Do 20 attempts in server mode (5 minutes of tries) before raising failure if any
	vAttemptTime = CurrentSessionDate();
	For i = 1 To vNumberOfAttempts Do
		Try
			// Delete temp files left from a previous run
			RemoveTempExchangeFiles(vTempDirPath + SelFileName);
			
			// Write XML file with changes
			vXMLWriter = New XMLWriter();
			vXMLWriter.OpenFile(vTempDirPath + SelFileName + ".xml");
			vXMLWriter.WriteXMLDeclaration();
			vMessageWriter = ExchangePlans.CreateMessageWriter();
			vMessageWriter.BeginWrite(vXMLWriter, SelNode);
			ExchangePlans.WriteChanges(vMessageWriter, SelObjectsInTranCount);
			vMessageWriter.EndWrite();
			vXMLWriter.Close();
			
			// Zip file with changes if necessary
			If SelUseZip Then
				vArchive = New ZipFileWriter(vTempDirPath + SelFileName + ".zip", SelZipPwd, , ZIPCompressionMethod.Deflate, ZIPCompressionLevel.Maximum, ZIPEncryptionMethod.AES256);
				vArchive.Add(vTempDirPath + SelFileName + ".xml", ZIPStorePathMode.DontStorePath);
				vArchive.Write();
			EndIf;
			
			// Copy file to the FTP or file target directory
			If Not IsBlankString(vTargetAddress) Then
				If SelUseFTP Then
					vProxy = cmGetInternetProxy(SelInternetConnectionSettings, False, SelFTPAddress);
					vFTPServer = Undefined;
					If vProxy <> Undefined Then
					    vFTPServer = New FTPConnection(SelFTPAddress, SelFTPPort, SelFTPUser, SelFTPPwd, vProxy, SelUsePassiveMode, SelFTPConnectionTimeout);
					Else
					    vFTPServer = New FTPConnection(SelFTPAddress, SelFTPPort, SelFTPUser, SelFTPPwd, , SelUsePassiveMode, SelFTPConnectionTimeout);
					EndIf;
					// Delete file left from previous run
					If vFTPServer.FindFiles(vTargetAddress + SelExchangeFileName).Count() > 0 Then
						vFTPServer.Delete(vTargetAddress + SelExchangeFileName);
					EndIf;
					// Put file to server
					vFTPServer.Put(vTempDirPath + SelExchangeFileName, vTargetAddress + SelExchangeFileName);
				Else
					SelTempAddress = PutToTempStorage(New BinaryData(vTempDirPath + SelExchangeFileName), ?(ValueIsFilled(SelTempAddress), SelTempAddress, UUID));
				EndIf;
			EndIf;
			
			// Delete temp files
			RemoveTempExchangeFiles(vTempDirPath + SelFileName);
			
			// Break attempts cycle if everything is OK
			Break;
		Except
			// Save current error description
			vErrorDescription = ErrorDescription();
			// Close file with XML changes
			Try
				vXMLWriter.Close();
			Except
			EndTry;
			If i = vNumberOfAttempts Then
				Raise vErrorDescription;
			Else
				// Wait 15 seconds and try again
				vGap = CurrentSessionDate() - vAttemptTime;
				While vGap < 15 Do
					vGap = CurrentSessionDate() - vAttemptTime;
				EndDo;
				vAttemptTime = CurrentSessionDate();
			EndIf;
		EndTry;
	EndDo;
EndProcedure // WriteExchangePlanChanges

// -----------------------------------------------------------------------------
&AtServer
Procedure RemoveTempExchangeFiles(pFileName)
	vTempXML = New File(pFileName + ".xml");
	If tcCommonFunctionOnClientServer.cmExists(vTempXML) Then
		DeleteFiles(pFileName + ".xml");
	EndIf;
	If SelUseZip Then
		vTempZIP = New File(pFileName + ".zip");
		If tcCommonFunctionOnClientServer.cmExists(vTempZIP) Then
			DeleteFiles(pFileName + ".zip");
		EndIf;
	EndIf;
EndProcedure // RemoveTempExchangeFiles

// -----------------------------------------------------------------------------
&AtServer
Procedure SystemSettingsStorageSave()
	SystemSettingsStorage.Save("tcWriteExchangePlanNodeChangesSelFTPAddress", tcOnServer.cmGetCurrentUserAttribute(), SelFTPAddress);
	SystemSettingsStorage.Save("tcWriteExchangePlanNodeChangesSelFTPConnectionTimeout", tcOnServer.cmGetCurrentUserAttribute(), SelFTPConnectionTimeout);
	SystemSettingsStorage.Save("tcWriteExchangePlanNodeChangesSelFTPPort", tcOnServer.cmGetCurrentUserAttribute(), SelFTPPort);
	SystemSettingsStorage.Save("tcWriteExchangePlanNodeChangesSelFTPUser", tcOnServer.cmGetCurrentUserAttribute(), SelFTPUser);
	SystemSettingsStorage.Save("tcWriteExchangePlanNodeChangesSelInternetConnectionSettings", tcOnServer.cmGetCurrentUserAttribute(), SelInternetConnectionSettings);
	SystemSettingsStorage.Save("tcWriteExchangePlanNodeChangesSelObjectsInTranCount", tcOnServer.cmGetCurrentUserAttribute(), SelObjectsInTranCount);
	SystemSettingsStorage.Save("tcWriteExchangePlanNodeChangesSelPath", tcOnServer.cmGetCurrentUserAttribute(), SelPath);
	SystemSettingsStorage.Save("tcWriteExchangePlanNodeChangesSelUseFTP", tcOnServer.cmGetCurrentUserAttribute(), SelUseFTP);
	SystemSettingsStorage.Save("tcWriteExchangePlanNodeChangesSelUsePassiveMode", tcOnServer.cmGetCurrentUserAttribute(), SelUsePassiveMode);
	SystemSettingsStorage.Save("tcWriteExchangePlanNodeChangesSelUseZip", tcOnServer.cmGetCurrentUserAttribute(), SelUseZip);
EndProcedure // SystemSettingsStorageSave

// -----------------------------------------------------------------------------
&AtServer
Procedure SystemSettingsStorageLoad()
	vSelFTPAddress = SystemSettingsStorage.Load("tcWriteExchangePlanNodeChangesSelFTPAddress", tcOnServer.cmGetCurrentUserAttribute());
	If vSelFTPAddress <> Undefined Then
		SelFTPAddress = vSelFTPAddress;
	EndIf;
	vSelFTPConnectionTimeout = SystemSettingsStorage.Load("tcWriteExchangePlanNodeChangesSelFTPConnectionTimeout", tcOnServer.cmGetCurrentUserAttribute());
	If vSelFTPConnectionTimeout <> Undefined Then
		SelFTPConnectionTimeout = vSelFTPConnectionTimeout;
	EndIf;
	vSelFTPPort = SystemSettingsStorage.Load("tcWriteExchangePlanNodeChangesSelFTPPort", tcOnServer.cmGetCurrentUserAttribute());
	If vSelFTPPort <> Undefined Then
		SelFTPPort = vSelFTPPort;
	EndIf;
	vSelFTPUser = SystemSettingsStorage.Load("tcWriteExchangePlanNodeChangesSelFTPUser", tcOnServer.cmGetCurrentUserAttribute());
	If vSelFTPUser <> Undefined Then
		SelFTPUser = vSelFTPUser;
	EndIf;
	vSelInternetConnectionSettings = SystemSettingsStorage.Load("tcWriteExchangePlanNodeChangesSelInternetConnectionSettings", tcOnServer.cmGetCurrentUserAttribute());
	If vSelInternetConnectionSettings <> Undefined Then
		SelInternetConnectionSettings = vSelInternetConnectionSettings;
	EndIf;
	vSelObjectsInTranCount = SystemSettingsStorage.Load("tcWriteExchangePlanNodeChangesSelObjectsInTranCount", tcOnServer.cmGetCurrentUserAttribute());
	If vSelObjectsInTranCount <> Undefined Then
		SelObjectsInTranCount = vSelObjectsInTranCount;
	EndIf;
	vSelPath = SystemSettingsStorage.Load("tcWriteExchangePlanNodeChangesSelPath", tcOnServer.cmGetCurrentUserAttribute());
	If vSelPath <> Undefined Then
		SelPath = vSelPath;
	EndIf;
	vSelUseFTP = SystemSettingsStorage.Load("tcWriteExchangePlanNodeChangesSelUseFTP", tcOnServer.cmGetCurrentUserAttribute());
	If vSelUseFTP <> Undefined Then
		SelUseFTP = vSelUseFTP;
	EndIf;
	vSelUsePassiveMode = SystemSettingsStorage.Load("tcWriteExchangePlanNodeChangesSelUsePassiveMode", tcOnServer.cmGetCurrentUserAttribute());
	If vSelUsePassiveMode <> Undefined Then
		SelUsePassiveMode = vSelUsePassiveMode;
	EndIf;
	vSelUseZip = SystemSettingsStorage.Load("tcWriteExchangePlanNodeChangesSelUseZip", tcOnServer.cmGetCurrentUserAttribute());
	If vSelUseZip <> Undefined Then
		SelUseZip = vSelUseZip;
	EndIf;
EndProcedure // SystemSettingsStorageLoad

#EndRegion
