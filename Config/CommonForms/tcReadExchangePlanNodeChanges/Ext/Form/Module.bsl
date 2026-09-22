
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

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeClose(pCancel, pExit, pMessageText, pStandardProcessing)
	SystemSettingsStorageSave();
	If ValueIsFilled(SelTempAddress) And IsTempStorageURL(SelTempAddress) Then
		DeleteFromTempStorage(SelTempAddress);	
	EndIf;
EndProcedure // BeforeClose

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionOK(pCommand)
	If Not ValueIsFilled(SelNode) Then
		ShowMessageBox(, NStr("en='Exchange node is not set!';ru='Узел обмена не указан!';de='Austauschknoten nicht angegeben!'"));
		Return;
	EndIf;            
	// ACC:561-off
	If ValueIsFilled(SelPath) And Not SelUseFTP Then
		vFileName = GetExchangeFileName();
		vFile = New File(vFileName);
		If tcCommonFunctionOnClientServer.cmExists(vFile) Then
			SelTempAddress = PutToTempStorage(New BinaryData(vFileName), UUID);
		Else
			ShowMessageBox(, TrimAll(vFileName) + NStr("en = ' not exist!'; de = ' existiert nicht!'; ru = ' не существует!'"));
			Return;
		EndIf;
	EndIf;  
	// ACC:561-on
	ReadExchangePlanChanges();
	Notify("tcReadExchangePlanNodeChanges.Сompleted");
	ShowMessageBox(New NotifyDescription("AfterShowMessageBox", ThisForm), NStr("en='Operation completed!';ru='Операция выполнена!';de='Die Operation wurde ausgeführt'"));
EndProcedure // ActionOK

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Function GetExchangeFileName()
	If Not ValueIsFilled(SelNode) Then
		Raise NStr("en='Node to receive changes from is not set!';ru='Не выбран узел от которого нужно получить изменения!';de='Kein Knoten ist gewählt, von dem Änderungen empfangen werden sollen!'");
	EndIf;
	
	vThisNode = ExchangePlansProcessing.GetThisNode(SelNode);
	
	// Check path to read data from
	vSourceAddress = StrReplace(TrimAll(SelPath), "\", "/");
	If Right(vSourceAddress, 1) <> "/" Then
		vSourceAddress = vSourceAddress + "/";
	EndIf;
	
	// Initialize file name
	vMessageFileName = "Message_" + Upper(TrimAll(SelNode.Code)) + "_" + Upper(TrimAll(vThisNode.Code));
	
	// Build file name to be used further
	vExchangeFileName = vMessageFileName + ?(SelUseZip, ".zip", ".xml");
	
	Return vSourceAddress + vExchangeFileName;  
EndFunction // GetExchangeFileName

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterShowMessageBox(pExtraParams) Export 
	Close();	
EndProcedure // AfterShowMessageBox

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
Procedure ReadExchangePlanChanges()
	If Not ValueIsFilled(SelNode) Then
		Raise NStr("en='Node to receive changes from is not set!';ru='Не выбран узел от которого нужно получить изменения!';de='Kein Knoten ist gewählt, von dem Änderungen empfangen werden sollen!'");
	EndIf;
	// Get and check this node
	vThisNode = ExchangePlansProcessing.GetThisNode(SelNode);
	If vThisNode = Undefined Then
		Raise NStr("en='<This node> is not defined for the current configuration!';ru='В текущей конфигурации не определен <Этот узел>!';de='In der aktuellen Konfiguration ist <Dieser Knoten> nicht festgelegt!'");
	EndIf;
	If SelNode = vThisNode Then
		Raise NStr("en='Node to receive changes from should not be this node!';ru='Нельзя получать изменения от текущего узла!';de='Vom aktuellen Knoten dürfen keine Änderungen bezogen werden!'");
	EndIf;
	
	// Get temporal directory path 
	vTempDirPath = TrimAll(TempFilesDir());
	vTempDirPath = StrReplace(vTempDirPath, "\", "/");
	If Right(vTempDirPath, 1) <> "/" Then
		vTempDirPath = vTempDirPath + "/";
	EndIf;
	
	// Check path to read data from
	vSourceAddress = StrReplace(TrimAll(SelPath), "\", "/");
	If Right(vSourceAddress, 1) <> "/" Then
		vSourceAddress = vSourceAddress + "/";
	EndIf;
	
	// Initialize file name
	vMessageFileName = "Message_" + Upper(TrimAll(SelNode.Code)) + "_" + Upper(TrimAll(vThisNode.Code));
	
	// Build file name to be used further
	vExchangeFileName = vMessageFileName + ?(SelUseZip, ".zip", ".xml");
	
	// Initialize number of attempts. Use 1 if function is running interactively and 20 if function is running on server
	vNumberOfAttempts = 1;
	If Left(InfoBaseConnectionString(), 5) <> "File=" Then
		#IF SERVER THEN
			vNumberOfAttempts = 20;
		#ENDIF
	EndIf;
	
	// Do 20 attempts in server mode (5 minutes of tries) before raising failure if any
	vAttemptTime = CurrentSessionDate();
	For i = 1 To vNumberOfAttempts Do
		Try
			// Delete temp files left from a previous run
			RemoveTempExchangeFiles(vTempDirPath + vMessageFileName);
			
			// Copy file from the FTP or file source directory
			If ValueIsFilled(vSourceAddress) Or Not SelUseFTP And ValueIsFilled(SelTempAddress) Then
				// Receive file from FTP or copy it from directory
				If SelUseFTP Then
					vProxy = cmGetInternetProxy(SelInternetConnectionSettings, False, SelFTPAddress);
					vFTPServer = Undefined;
					If vProxy <> Undefined Then
					    vFTPServer = New FTPConnection(SelFTPAddress, SelFTPPort, SelFTPUser, SelFTPPwd, vProxy, SelUsePassiveMode, SelFTPConnectionTimeout);
					Else
					    vFTPServer = New FTPConnection(SelFTPAddress, SelFTPPort, SelFTPUser, SelFTPPwd, , SelUsePassiveMode, SelFTPConnectionTimeout);
					EndIf;
					// Get file from FTP server
					vExchangeFiles = vFTPServer.FindFiles(vSourceAddress + vExchangeFileName);
					For Each vExchangeFile In vExchangeFiles Do
						vFTPServer.Get(vExchangeFile.FullName, vTempDirPath + vExchangeFileName);
					EndDo;
				Else
					// Copy file
					vBinaryData = GetFromTempStorage(SelTempAddress);
					vBinaryData.Write(vTempDirPath + vExchangeFileName);
				EndIf;
			EndIf;
			
			// Unzip file with changes if necessary
			If SelUseZip Then
				vArchive = New ZipFileReader(vTempDirPath + vExchangeFileName, SelZipPwd);
				vArchive.ExtractAll(vTempDirPath, ZIPRestoreFilePathsMode.DontRestore);
				vArchive.Close();
			EndIf;
			
			// Load changes
			vXMLReader = New XMLReader();
			vXMLReader.OpenFile(vTempDirPath + vMessageFileName + ".xml");
			vMessageReader = ExchangePlans.CreateMessageReader();
			vMessageReader.BeginRead(vXMLReader, AllowedMessageNo.Any);
			If vMessageReader.Sender <> SelNode Then
				Raise NStr("en='Wrong node in the data exchange file!';ru='Неверный узел в файле обмена данными!';de='Falscher Knoten in der Datenaustauschdatei!'");
			ElsIf vMessageReader.MessageNo > SelNode.ReceivedNo Then
				Try
	               	ExchangePlans.ReadChanges(vMessageReader, SelObjectsInTranCount);
				Except
					tcCommonFunctionOnClientServer.UserMessage(BriefErrorDescription(ErrorInfo()));
				EndTry; 
				vMessageReader.EndRead();
			Else
				WriteLogEvent(NStr("en='Procedure.ReadExchangePlanChanges';ru='Процедура.ЧтениеИзмененийПоПлануОбмена';de='Procedure.ReadExchangePlanChanges'"), EventLogLevel.Information, Undefined, Undefined, 
							  NStr("ru='Номер прочитанного сообщения " + Format(vMessageReader.MessageNo, "ND=9; NFD=0; NZ=; NG=") + " меньше или равен номеру " + Format(SelNode.ReceivedNo, "ND=9; NFD=0; NZ=; NG=") + " последнего полученного сообщения!'; 
							       |de='Number " + Format(vMessageReader.MessageNo, "ND=9; NFD=0; NZ=; NG=") + " of message being read is less or equal the number " + Format(SelNode.ReceivedNo, "ND=9; NFD=0; NZ=; NG=") + " of message being already received!';
								   |en='Number " + Format(vMessageReader.MessageNo, "ND=9; NFD=0; NZ=; NG=") + " of message being read is less or equal the number " + Format(SelNode.ReceivedNo, "ND=9; NFD=0; NZ=; NG=") + " of message being already received!'"));
			EndIf;
			vXMLReader.Close();
			
			// Delete temp files
			RemoveTempExchangeFiles(vTempDirPath + vMessageFileName);
			
			// Break attempts cycle if everything is OK
			Break;
		Except
			// Save current error description
			vErrorDescription = ErrorDescription();
			// Rollback transaction if any and close file with XML changes
			Try
				If TransactionActive() Then
					RollbackTransaction();
				EndIf;
				vXMLReader.Close();
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
EndProcedure // ReadExchangePlanChanges

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

// -----------------------------------------------------------------------------
&AtServer
Procedure RemoveTempExchangeFiles(pFileName)  
	// ACC:561-off
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
	// ACC:561-on
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

