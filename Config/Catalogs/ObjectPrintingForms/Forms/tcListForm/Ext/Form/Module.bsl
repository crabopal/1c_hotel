
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServerNoContext
Procedure TreeOnGetDataAtServer(pItemName, pSettings, pRows)
	For Each vRow In pRows Do
		vRow.Value.Data.Description = cmNStr(vRow.Value.Data.Description, SessionParameters.CurrentLanguage);
	EndDo;
EndProcedure

// --------------------------------------------------------------------------------
&AtServerNoContext
Procedure ListOnGetDataAtServer(pItemName, pSettings, pRows)
	For Each vRow In pRows Do
		vRowValue = vRow.Value;
		vRow.Value.Data.Description = cmNStr(vRowValue.Data.Description, SessionParameters.CurrentLanguage);
		vRow.Value.Data.Remarks = cmNStr(vRowValue.Data.Remarks, SessionParameters.CurrentLanguage);
		vTypeAppearance = vRowValue.Appearance.Get("ObjectType");
		If vTypeAppearance <> Undefined Then
			vVal = vRowValue.Data.ObjectType; 
			If vVal = Undefined Then
				vTypeText = "";
			Else
				vTypeText = String(TypeOf(vVal));
			EndIf;
			vTypeAppearance.SetParameterValue("Text", vTypeText);
		EndIf;
	EndDo;
EndProcedure

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
	vXMLWriter.WriteStartElement("ObjectPrintingForms", vNameSpaceURI);
	
	// Do for each obecjt form action in the catalog
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ObjectPrintingForms.Ref AS Ref,
	|	ObjectPrintingForms.Parent AS Parent,
	|	ObjectPrintingForms.IsFolder AS IsFolder,
	|	ObjectPrintingForms.Code AS Code,
	|	ObjectPrintingForms.Description AS Description,
	|	ObjectPrintingForms.ObjectType AS ObjectType,
	|	ObjectPrintingForms.Report AS Report,
	|	ObjectPrintingForms.ExternalProcessing AS ExternalProcessing,
	|	ObjectPrintingForms.ExternalTemplate AS ExternalTemplate,
	|	ObjectPrintingForms.ExternalTemplateFileName AS ExternalTemplateFileName,
	|	ObjectPrintingForms.ExternalTemplateFileLoadTime AS ExternalTemplateFileLoadTime,
	|	ObjectPrintingForms.ExternalTemplateFileLastChangeTime AS ExternalTemplateFileLastChangeTime,
	|	ObjectPrintingForms.Parameter AS Parameter,
	|	ObjectPrintingForms.Width AS Width,
	|	ObjectPrintingForms.Copies AS Copies,
	|	ObjectPrintingForms.FormText AS FormText,
	|	ObjectPrintingForms.AutomaticallyPrintOnFirstObjectWrite AS AutomaticallyPrintOnFirstObjectWrite,
	|	ObjectPrintingForms.PrintFormPreview AS PrintFormPreview,
	|	ObjectPrintingForms.Remarks AS Remarks,
	|	ObjectPrintingForms.IsDefault AS IsDefault,
	|	ObjectPrintingForms.IsActive AS IsActive,
	|	ObjectPrintingForms.Predefined AS Predefined,
	|	ObjectPrintingForms.PredefinedDataName AS PredefinedDataName,
	|	ObjectPrintingForms.Presentation AS Presentation,
	|	CASE
	|		WHEN ObjectPrintingForms.Language = VALUE(Catalog.Languages.EmptyRef)
	|			THEN """"
	|		ELSE ObjectPrintingForms.Language.Code
	|	END AS LanguageCode
	|FROM
	|	Catalog.ObjectPrintingForms AS ObjectPrintingForms
	|WHERE
	|	NOT ObjectPrintingForms.DeletionMark
	|
	|ORDER BY
	|	IsFolder DESC,
	|	Code";
	vResult = vQry.Execute().Unload();
	For Each vRow In vResult Do
		vRef = vRow.Ref;
		// Write object form action to the XML
		vXMLWriter.WriteStartElement("ObjectPrintingFormObject", vNameSpaceURI);	
		vXMLWriter.WriteAttribute("languageCode", vNameSpaceURI, TrimAll(vRow.LanguageCode));
		vXMLWriter.WriteAttribute("parent", vNameSpaceURI, String(vRow.Parent));
		vXMLWriter.WriteAttribute("isFolder", vNameSpaceURI, String(vRow.IsFolder));
		vXMLWriter.WriteAttribute("code", vNameSpaceURI, TrimAll(vRow.Code));
		vXMLWriter.WriteAttribute("description", vNameSpaceURI, TrimAll(vRow.Description));		
		vXMLWriter.WriteAttribute("objectType", vNameSpaceURI, TrimAll(vRow.ObjectType));
		vXMLWriter.WriteAttribute("report", vNameSpaceURI, TrimAll(vRow.Report));
		vXMLWriter.WriteAttribute("externalProcessing", vNameSpaceURI, TrimAll(vRow.ExternalProcessing));
		vXMLWriter.WriteAttribute("externalTemplate", vNameSpaceURI, TrimAll(vRow.ExternalTemplate));
		vXMLWriter.WriteAttribute("externalTemplateFileName", vNameSpaceURI, TrimAll(vRow.ExternalTemplateFileName));
		vXMLWriter.WriteAttribute("externalTemplateFileLoadTime", vNameSpaceURI, TrimAll(vRow.ExternalTemplateFileLoadTime));
		vXMLWriter.WriteAttribute("externalTemplateFileLastChangeTime", vNameSpaceURI, TrimAll(vRow.ExternalTemplateFileLastChangeTime));
		vXMLWriter.WriteAttribute("parameter", vNameSpaceURI, TrimAll(vRow.Parameter));
		vXMLWriter.WriteAttribute("width", vNameSpaceURI, TrimAll(vRow.Width));
		vXMLWriter.WriteAttribute("copies", vNameSpaceURI, TrimAll(vRow.Copies));
		vXMLWriter.WriteAttribute("formText", vNameSpaceURI, TrimAll(vRow.FormText));
		vXMLWriter.WriteAttribute("automaticallyPrintOnFirstObjectWrite", vNameSpaceURI, TrimAll(vRow.AutomaticallyPrintOnFirstObjectWrite));
		vXMLWriter.WriteAttribute("printFormPreview", vNameSpaceURI, TrimAll(vRow.PrintFormPreview));
		vXMLWriter.WriteAttribute("isDefault", vNameSpaceURI, TrimAll(vRow.IsDefault));
		vXMLWriter.WriteAttribute("isActive", vNameSpaceURI, TrimAll(vRow.IsActive));
		vXMLWriter.WriteAttribute("predefined", vNameSpaceURI, TrimAll(vRow.Predefined));
		vXMLWriter.WriteAttribute("predefinedDataName", vNameSpaceURI, TrimAll(vRow.PredefinedDataName));
		vXMLWriter.WriteAttribute("presentation", vNameSpaceURI, TrimAll(vRow.Presentation));
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
			// Clear all user defined object printing forms
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	ObjectFormActions.Ref AS Ref
			|FROM
			|	Catalog.ObjectPrintingForms AS ObjectFormActions
			|
			|ORDER BY
			|	ObjectFormActions.IsFolder DESC,
			|	ObjectFormActions.Code";
			vResult = vQry.Execute().Unload();
			For Each vRow In vResult Do
				vObj = vRow.Ref.GetObject();
				If vObj <> Undefined Then
					vObj.Delete();
				EndIf;
			EndDo;
			
			// Read all object printing forms from file
			vXMLReader = New XMLReader();
			vXMLReader.OpenFile(vTempFileName);
			While vXMLReader.Read() Do
				If vXMLReader.NodeType = XMLNodeType.StartElement Then
					If vXMLReader.Name = "htl:ObjectPrintingFormObject" Then
						vLanguageCode = "";
						While vXMLReader.ReadAttribute() Do
							If vXMLReader.Name = "htl:languageCode" Then
								vLanguageCode = vXMLReader.Value;
								Break;
							EndIf;
						EndDo;
						vXMLReader.Read();
						vObj = ReadXML(vXMLReader);
						If ValueIsFilled(vLanguageCode) Then
							vObj.Language = Catalogs.Languages.FindByCode(vLanguageCode);
						EndIf;
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
		ShowMessageBox(, NStr("en = 'All object form prining were exported to the file successfully!'; de = 'Alle Datenbankobjektformularaktionen wurden erfolgreich in die Datei exportiert!'; ru = 'Все печатные формы объектов базы данных были успешно сохранены в файл!'"));
	EndIf;
EndProcedure // AllsFileDownloadToClientCompleted

// --------------------------------------------------------------------------------
&AtClient 
Procedure OpenFileDialogToSaveFile()
	vFileSave = New FileDialog(FileDialogMode.Save);
	vFileSave.FullFileName = "1CHotelObjectPrintingForms.xml";
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
	
	ShowMessageBox(, NStr("en='All database object printing forms were loaded from the file successfully!';ru='Все печатные формы объектов базы данных были успешно восстановлены из файла!';de='Alle objektdruckformen wurden erfolgreich aus der Datei geladen!'"), 5);
EndProcedure // TransferFileFromClientToServerCompleted

#EndRegion

#EndRegion

