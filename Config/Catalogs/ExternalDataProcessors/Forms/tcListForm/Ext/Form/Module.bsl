
#Region EventHandlers

// --------------------------------------------------------------------------------
&AtServerNoContext
Procedure ListOnGetDataAtServer(pItemName, pSettings, pRows)
	For Each vRow In pRows Do
		vRow.Value.Data.Description = cmNStr(vRow.Value.Data.Description, SessionParameters.CurrentLanguage);
	EndDo;
EndProcedure // ListOnGetDataAtServer

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ExportAllSettingsToXMLFile(pCommand)
	// Start file operations
	BeginAttachingFileSystemExtension(New NotifyDescription("ExportAllToXMLFileAttachingFileSystemExtensionResult", ThisObject));
EndProcedure // ExportAllDPSettingsToXMLFile

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadAllFromXMLFile(pCommand)
	LoadAll = True;
	// Start file operations
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadFromXMLFileAttachingFileSystemExtensionResult", ThisObject));
EndProcedure // LoadAllReportsFromXMLFile

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Function ExportAllToXMLFileAtServer()
	vNameSpaceURI = "http://1chotel.ru";
	
	vFileName = GetTempFileName("xml");
	
	// Open XML writer
	vXMLWriter = New XMLWriter();
	vXMLWriter.OpenFile(vFileName, "UTF-8");
	vXMLWriter.WriteXMLDeclaration();
	vXMLWriter.WriteStartElement("Hotel");
	vXMLWriter.WriteNamespaceMapping("htl", vNameSpaceURI);
	vXMLWriter.WriteStartElement("ExternalDataProcessors", vNameSpaceURI);
	
	// Do for each external data processor in the catalog
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ExternalDataProcessors.Ref AS Ref,
	|	ExternalDataProcessors.Predefined AS Predefined,
	|	ExternalDataProcessors.IsFolder AS IsFolder,
	|	ExternalDataProcessors.Code AS Code,
	|	ExternalDataProcessors.Description AS Description,
	|	ExternalDataProcessors.ExternalProcessingType AS ExternalProcessingType,
	|	ExternalDataProcessors.ExternalProcessingStorage AS ExternalProcessingStorage,
	|	ExternalDataProcessors.Algorithm AS Algorithm,
	|	ExternalDataProcessors.FileName AS FileName,
	|	ExternalDataProcessors.FileLoadTime AS FileLoadTime,
	|	ExternalDataProcessors.FileLastChangeTime AS FileLastChangeTime,
	|	ExternalDataProcessors.Remarks AS Remarks
	|FROM
	|	Catalog.ExternalDataProcessors AS ExternalDataProcessors
	|WHERE
	|	NOT ExternalDataProcessors.DeletionMark
	|
	|ORDER BY
	|	IsFolder DESC,
	|	Code";
	vResult = vQry.Execute().Unload();
	For Each vRow In vResult Do
		vRef = vRow.Ref;
		// Write external data processor to the XML
		vXMLWriter.WriteStartElement("ExternalDataProcessorObject", vNameSpaceURI);
		vXMLWriter.WriteAttribute("isFolder", vNameSpaceURI, String(vRow.IsFolder));
		vXMLWriter.WriteAttribute("predefined", vNameSpaceURI, String(vRow.Predefined));
		vXMLWriter.WriteAttribute("code", vNameSpaceURI, TrimAll(vRow.Code));
		vXMLWriter.WriteAttribute("description", vNameSpaceURI, TrimAll(vRow.Description));
		vXMLWriter.WriteAttribute("externalProcessingType", vNameSpaceURI, TrimAll(vRow.ExternalProcessingType));
		vXMLWriter.WriteAttribute("externalProcessingStorage", vNameSpaceURI, TrimAll(vRow.ExternalProcessingStorage));
		vXMLWriter.WriteAttribute("algorithm", vNameSpaceURI, TrimAll(vRow.Algorithm));
		vXMLWriter.WriteAttribute("fileName", vNameSpaceURI, TrimAll(vRow.FileName));
		vXMLWriter.WriteAttribute("fileLoadTime", vNameSpaceURI, TrimAll(vRow.FileLoadTime));
		vXMLWriter.WriteAttribute("fileLastChangeTime", vNameSpaceURI, TrimAll(vRow.FileLastChangeTime));
		WriteXML(vXMLWriter, vRef.GetObject(), XMLTypeAssignment.Explicit);
		vXMLWriter.WriteEndElement();
	EndDo;		
	vXMLWriter.WriteEndElement();
	vXMLWriter.WriteEndElement();
	vXMLWriter.Close();
	
	vFileBinaryData = New BinaryData(vFileName);
	vFileTempStorageAddress = PutToTempStorage(vFileBinaryData, UUID);
	
	DeleteFiles(vFileName);  
	
	Return vFileTempStorageAddress;
EndFunction // ExportAllToXMLFileAtServer

// --------------------------------------------------------------------------------
&AtServer 
Procedure LoadFileAtServer(pTempStorageFileAddress)
	// Do in one transaction
	BeginTransaction(DataLockControlMode.Managed);
	Try
		vTempFileName = GetTempFileName("xml");
		vBinaryData = GetFromTempStorage(pTempStorageFileAddress);
		vBinaryData.Write(vTempFileName);
		
		If LoadAll Then
			// Clear all user defined external data processors
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	ExternalDataProcessors.Ref AS Ref,
			|	ExternalDataProcessors.Predefined AS Predefined,
			|	ExternalDataProcessors.DeletionMark AS DeletionMark,
			|	ExternalDataProcessors.IsFolder AS IsFolder,
			|	ExternalDataProcessors.Code AS Code,
			|	ExternalDataProcessors.Description AS Description,
			|	ExternalDataProcessors.Parent AS Parent
			|FROM
			|	Catalog.ExternalDataProcessors AS ExternalDataProcessors
			|
			|ORDER BY
			|	IsFolder DESC,
			|	Code";
			vResult = vQry.Execute().Unload();
			For Each vRow In vResult Do
				vObj = vRow.Ref.GetObject();
				If vObj <> Undefined Then
					vObj.Delete();
				EndIf;
			EndDo;
			
			// Read all external data processors from file
			vXMLReader = New XMLReader();
			vXMLReader.OpenFile(vTempFileName);
			While vXMLReader.Read() Do
				If vXMLReader.NodeType = XMLNodeType.StartElement Then
					If vXMLReader.Name = "htl:ExternalDataProcessorObject" Then
						vXMLReader.Read();
						vObj = ReadXML(vXMLReader);
						vObj.Write();
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		vXMLReader.Close();
		DeleteFiles(vTempFileName);
		// Commit transaction
		CommitTransaction();
	Except
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		vErrorInfo = ErrorInfo();
		Raise cmGetRootErrorDescription(vErrorInfo);
	EndTry;		
EndProcedure // LoadFileAtServer

#Region ExportAllToFile

// --------------------------------------------------------------------------------
&AtClient
Procedure ExportAllToXMLFileAttachingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		OpenFileDialogToSaveFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension is being installing on your browser...'; ru='В браузер устанавливается расширение по работе с файлами...'; de='Dateisystemerweiterung wird in Ihrem Browser installiert...'"), MessageStatus.Information);
		BeginInstallFileSystemExtension(New NotifyDescription("ExportAllToXMLFileFileSystemExtensionInstallCompleted", ThisForm, pParam));
	EndIf;
EndProcedure // LoadFromFileAttachingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure ExportAllToXMLFileFileSystemExtensionInstallCompleted(pParam) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("ExportAllToXMLFileInstallingFileSystemExtensionResult", ThisForm, pParam));
EndProcedure // LoadFromFileFileSystemExtensionInstallCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure ExportAllToXMLFileInstallingFileSystemExtensionResult(pResult, pParam) Export 
	If pResult Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension was successfully installed on your browser!'; ru='В браузер успешно установлено расширение по работе с файлами!'; de='Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'"), MessageStatus.Information);
		OpenFileDialogToSaveFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Your browser does not support file operations in 1C!'; ru='Браузер не поддерживает работу с файлами в 1С!'; de='Ihr Browser unterstützt keine Dateioperationen in 1C!'"), MessageStatus.Attention);
	EndIf;
EndProcedure // ExportAllToXMLFileInstallingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileDialogToSaveFileCompleted(pFileArray, pParam) Export
	If ValueIsFilled(pFileArray) Then
		vFullFileNameAtClient = pFileArray[0];
		StartTransferAllFileFromServerToClient(vFullFileNameAtClient);
	EndIf;
EndProcedure // OpenFileDialogToSaveFileCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure StartTransferAllFileFromServerToClient(pFullFileNameAtClient) Export
	vFullFileNameAtServer = ExportAllToXMLFileAtServer();

	vFilesArray = New Array();
	vFileDescription = New TransferableFileDescription(pFullFileNameAtClient, vFullFileNameAtServer);
	vFilesArray.Add(vFileDescription);
	
	BeginGettingFiles(New NotifyDescription("AllFileDownloadToClientCompleted", ThisForm), vFilesArray, , False);
EndProcedure // StartTransferAllFileFromServerToClient

// --------------------------------------------------------------------------------
&AtClient 
Procedure AllFileDownloadToClientCompleted(pFilesArray, pParam) Export
	If pFilesArray <> Undefined Then
		// Show result message
		ShowMessageBox(, NStr("en='All database external data processors were exported to the file successfully!';ru='Все внешние обработки базы данных были успешно сохранены в файл!';de='Alle datenbankexternen Datenverarbeiter wurden erfolgreich in die Datei exportiert!'"));
	EndIf;
EndProcedure // AllsFileDownloadToClientCompleted

// --------------------------------------------------------------------------------
&AtClient 
Procedure OpenFileDialogToSaveFile()
	vFileSave = New FileDialog(FileDialogMode.Save);
	vFileSave.FullFileName = "1CHotelExternalDataProcessors.xml";
	vFileSave.Filter = NStr("ru = 'XML файл (*.xml)|*.xml;|'; 
	                        |de = 'XML Datei (*.xml)|*.xml;|'; 
	                        |en = 'XML file (*.xml)|*.xml;|'");
	vFileSave.Multiselect = False;
	vFileSave.Title = NStr("en='Create file';ru='Создать файл';de='Datei erstellen'");
	vFileSave.Preview = False;
	vFileSave.CheckFileExist = True;
	vFileSave.Show(New NotifyDescription("OpenFileDialogToSaveFileCompleted", ThisForm));
EndProcedure // OpenFileDialogToSaveFile

#EndRegion

#Region LoadAllFromFile

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFromXMLFileAttachingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		OpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension is being installing on your browser...'; ru='В браузер устанавливается расширение по работе с файлами...'; de='Dateisystemerweiterung wird in Ihrem Browser installiert...'"), MessageStatus.Information);
		BeginInstallFileSystemExtension(New NotifyDescription("LoadFromXMLFileFileSystemExtensionInstallCompleted", ThisForm, pParam));
	EndIf;
EndProcedure // LoadFromXMLFileAttachingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFromXMLFileFileSystemExtensionInstallCompleted(pParam) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadFromXMLFileInstallingFileSystemExtensionResult", ThisForm, pParam));
EndProcedure // LoadFromXMLFileFileSystemExtensionInstallCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFromXMLFileInstallingFileSystemExtensionResult(pResult, pParam) Export 
	If pResult Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension was successfully installed on your browser!'; ru='В браузер успешно установлено расширение по работе с файлами!'; de='Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'"), MessageStatus.Information);
		OpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Your browser does not support file operations in 1C!'; ru='Браузер не поддерживает работу с файлами в 1С!'; de='Ihr Browser unterstützt keine Dateioperationen in 1C!'"), MessageStatus.Attention);
	EndIf;
EndProcedure // LoadFromXMLFileInstallingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileDialogToChooseFile()
	vFileOpen = New FileDialog(FileDialogMode.Open);
	vFileOpen.Multiselect = False;
	vFileOpen.Title = NStr("en='Open file';ru='Открыть файл';de='Datei öffnen'");
	vFileOpen.Preview = True;
	vFileOpen.Show(New NotifyDescription("OpenFileDialogToChooseFileCompleted", ThisForm));
EndProcedure // OpenFileDialogToChooseFile

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileDialogToChooseFileCompleted(pFileArray, pParam) Export
	If ValueIsFilled(pFileArray) Then
		vFullFileNameAtClient = pFileArray[0];
		StartTransferFileFromClientToServer(vFullFileNameAtClient);
	EndIf;
EndProcedure // OpenFileDialogToChooseFileCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure StartTransferFileFromClientToServer(pFullFileNameAtClient)
	vFilesArray = New Array();
	vFileDescription = New TransferableFileDescription(pFullFileNameAtClient, );
	vFilesArray.Add(vFileDescription);
	BeginPuttingFiles(New NotifyDescription("TransferFileFromClientToServerCompleted", ThisForm), vFilesArray, , False);
EndProcedure // StartTransferFileFromClientToServer

// --------------------------------------------------------------------------------
&AtClient
Procedure TransferFileFromClientToServerCompleted(pTransferredFiles, pParam) Export
	vTempStorageFileAddressAtServer = pTransferredFiles.Get(0).Location;
	LoadFileAtServer(vTempStorageFileAddressAtServer);
	
	Items.List.Refresh();
	Items.Tree.Refresh();
	
	ShowMessageBox(, NStr("en='All database external data processors were loaded from the file successfully!';ru='Все внешние обработки базы данных были успешно восстановлены из файла!';de='Alle datenbankexternen Datenprozessoren wurden erfolgreich aus der Datei geladen!'"), 5);
EndProcedure // TransferFileFromClientToServerCompleted

#EndRegion

#EndRegion