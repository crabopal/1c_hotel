
#Region FormEventHandlers

 // --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not Parameters.Filter.Property("Hotel") Then
		vHotel = SessionParameters.CurrentHotel;
		If ValueIsFilled(vHotel) Then
			SelHotel = vHotel; 
			vArray = New Array;
			vArray.Add(SelHotel);		
			vArray.Add(Catalogs.Hotels.EmptyRef());	
			AttributeChangeAtServer("Hotel", vArray, DataCompositionComparisonType.InList);
		EndIf;
	EndIf;
	
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
	If Not IsInRole("RightsToChooseHotel") Then
		Items.SelHotel.ReadOnly = True;
		Items.SelHotel.ChoiceButton = False;
		Items.SelHotel.ClearButton = False;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion    

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ListOnChange(pItem)
	Items.List.Refresh();
	Items.Tree.Refresh();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure SelHotelOnChange(pItem)
	If ValueIsFilled(SelHotel) Then
		vArray = New Array;
		vArray.Add(SelHotel);		
		vArray.Add(PredefinedValue("Catalog.Hotels.EmptyRef"));	
		AttributeChangeAtServer("Hotel", vArray, DataCompositionComparisonType.InList);
	Else
		ClearingAttributeAtServer("Hotel");
	EndIf; 
	
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlers

// --------------------------------------------------------------------------------
&AtServerNoContext
Procedure ListOnGetDataAtServer(pItemName, pSettings, pRows)
	For Each vRow In pRows Do
		vRow.Value.Data.Description = cmNStr(vRow.Value.Data.Description, SessionParameters.CurrentLanguage);
		vRow.Value.Data.Remarks = cmNStr(vRow.Value.Data.Remarks, SessionParameters.CurrentLanguage);
	EndDo;
EndProcedure // ListOnGetDataAtServer

// --------------------------------------------------------------------------------
&AtServerNoContext
Procedure TreeOnGetDataAtServer(pItemName, pSettings, pRows)
	For Each vRow In pRows Do
		vRow.Value.Data.Description = cmNStr(vRow.Value.Data.Description, SessionParameters.CurrentLanguage);
	EndDo;
EndProcedure // TreeOnGetDataAtServer

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenReportForm(pCommand)  
	vCurRow = Items.List.CurrentData;
	If vCurRow <> Undefined Then
		vReportRef = vCurRow.Ref;
		vReportObj = tcOnServer.cmGetAtributeAsArray(vReportRef);
		If vReportObj.IsExternal Then
			vURL = GetURL(vReportObj.Report, "ExternalProcessingStorage"); 
			vName = ConnectExternalReport(vURL, StrReplace(tcOnServer.cmGetAttributeByRef(vReportObj.Report,"FileName"),".erf",""));
			vParams = New Structure("FillingValues, GenerateOnOpen", New Structure("ReportRef", vReportRef), Not vReportObj.DoNotGenerateOnOpen);
			OpenForm("ExternalReport." + vName + ".Form", vParams, ThisObject, vReportRef);
		Else	
			If vReportObj.Report = Undefined Or vReportObj.Report = "" Then
				ShowMessageBox(, Nstr("en = 'You must fill the handler in the report settings'; de = 'Sie müssen den Handler in den Berichteinstellungen ausfüllen'; ru = 'Необходимо заполнить обработчик в настройках отчета'"));
			Else
				OpenForm("Report." + vReportObj.Report + ".Form", New Structure("FillingValues, GenerateOnOpen", New Structure("ReportRef", vReportRef), Not vReportObj.DoNotGenerateOnOpen), ThisObject, vReportRef);
			EndIf; 
		EndIf;	
	EndIf;
EndProcedure // OpenReportForm

// --------------------------------------------------------------------------------
&AtClient
Procedure ExportAllReportsToXMLFile(pCommand)
	// Start file operations
	BeginAttachingFileSystemExtension(New NotifyDescription("ExportAllReportsToXMLFileAttachingFileSystemExtensionResult", ThisObject));
EndProcedure // ExportAllReportsToXMLFile

// --------------------------------------------------------------------------------
&AtClient
Procedure ExportSelectedReportsToXMLFile(pCommand)
	vSelRows = Items.List.SelectedRows;
	SelectedReports.Clear();
	For Each vRow In vSelRows Do
		If Not tcOnServer.cmGetAttributeByRef(vRow, "IsFolder") Then
			SelectedReports.Add(Items.List.RowData(vRow).Ref);
		EndIf;
	EndDo;
	If SelectedReports.Count() > 0 Then
		// Start file operations
		BeginAttachingFileSystemExtension(New NotifyDescription("ExportAllReportsToXMLFileAttachingFileSystemExtensionResult", ThisObject));
	Else
		tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'No reports have been selected!';
														|de = 'Es wurden keine Berichte ausgewählt!';
														|ru = 'Не выбрано ни одного отчета!'"));
	EndIf;
EndProcedure // ExportAllReportsToXMLFile

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadAllReportsFromXMLFile(pCommand)
	LoadAllReports = True;
	// Start file operations
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadReportsFromXMLFileAttachingFileSystemExtensionResult", ThisObject));
EndProcedure // LoadReportsFromXMLFile

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadReportFromXMLFile(pCommand)
	LoadAllReports = False;
	// Start file operations
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadReportsFromXMLFileAttachingFileSystemExtensionResult", ThisObject));	
EndProcedure // LoadReportSettingsFromXMLFile
	
#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Function ExportAllReportsToXMLFileAtServer()
	vNameSpaceURI = "http://1chotel.ru";
	
	vFileName = GetTempFileName("xml");
	
	// Open XML writer
	vXMLWriter = New XMLWriter();
	vXMLWriter.OpenFile(vFileName, "UTF-8");
	vXMLWriter.WriteXMLDeclaration();
	vXMLWriter.WriteStartElement("Hotel");
	vXMLWriter.WriteNamespaceMapping("htl", vNameSpaceURI);
	vXMLWriter.WriteStartElement("Reports", vNameSpaceURI);
	
	// Do for each report in the catalog
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reports.Ref AS Ref,
	|	Reports.Predefined AS Predefined,
	|	Reports.IsFolder AS IsFolder,
	|	Reports.Code AS Code,
	|	Reports.Description AS Description,
	|	Reports.Report AS Report,
	|	Reports.IsExternal AS IsExternal,
	|	Reports.StaticParameters AS StaticParameters,
	|	Reports.DynamicParameters AS DynamicParameters,
	|	Reports.IsPackage AS IsPackage,
	|	Reports.Key AS Key,
	|	Reports.SortCode AS SortCode,
	|	Reports.ReportHeaderText AS ReportHeaderText,
	|	Reports.ExternalTemplate AS ExternalTemplate,
	|	Reports.ExternalTemplateFileName AS ExternalTemplateFileName,
	|	Reports.ExternalTemplateFileLoadTime AS ExternalTemplateFileLoadTime,
	|	Reports.ExternalTemplateFileLastChangeTime AS ExternalTemplateFileLastChangeTime,
	|	Reports.DefaultSettings AS DefaultSettings,
	|	Reports.Remarks AS Remarks,
	|	Reports.DoNotGenerateOnOpen AS DoNotGenerateOnOpen,
	|	Reports.LockSettings AS LockSettings,
	|	Reports.IsSystem AS IsSystem
	|FROM
	|	Catalog.Reports AS Reports
	|WHERE
	|	NOT Reports.DeletionMark
	|
	|ORDER BY
	|	Reports.IsFolder DESC,
	|	Code";
	vReports = vQry.Execute().Unload();
	For Each vReportsRow In vReports Do
		vRepRef = vReportsRow.Ref;
		// Write report to the XML
		vXMLWriter.WriteStartElement("ReportObject", vNameSpaceURI);
		vXMLWriter.WriteAttribute("isFolder", vNameSpaceURI, String(vReportsRow.IsFolder));
		vXMLWriter.WriteAttribute("predefined", vNameSpaceURI, String(vReportsRow.Predefined));
		vXMLWriter.WriteAttribute("code", vNameSpaceURI, TrimAll(vReportsRow.Code));
		vXMLWriter.WriteAttribute("description", vNameSpaceURI, TrimAll(vReportsRow.Description));
		vXMLWriter.WriteAttribute("Report", vNameSpaceURI, TrimAll(vReportsRow.Report));
		vXMLWriter.WriteAttribute("isExternal", vNameSpaceURI, TrimAll(vReportsRow.IsExternal));
		vXMLWriter.WriteAttribute("staticParameters", vNameSpaceURI, TrimAll(vReportsRow.StaticParameters));
		vXMLWriter.WriteAttribute("dynamicParameters", vNameSpaceURI, TrimAll(vReportsRow.DynamicParameters));
		vXMLWriter.WriteAttribute("isPackage", vNameSpaceURI, TrimAll(vReportsRow.IsPackage));
		vXMLWriter.WriteAttribute("key", vNameSpaceURI, TrimAll(vReportsRow.Key));
		vXMLWriter.WriteAttribute("sortCode", vNameSpaceURI, TrimAll(vReportsRow.SortCode));
		vXMLWriter.WriteAttribute("reportHeaderText", vNameSpaceURI, TrimAll(vReportsRow.ReportHeaderText));
		vXMLWriter.WriteAttribute("externalTemplate", vNameSpaceURI, TrimAll(vReportsRow.ExternalTemplate));
		vXMLWriter.WriteAttribute("externalTemplateFileName", vNameSpaceURI, TrimAll(vReportsRow.ExternalTemplateFileName));
		vXMLWriter.WriteAttribute("externalTemplateFileLoadTime", vNameSpaceURI, TrimAll(vReportsRow.ExternalTemplateFileLoadTime));
		vXMLWriter.WriteAttribute("externalTemplateFileLastChangeTime", vNameSpaceURI, TrimAll(vReportsRow.ExternalTemplateFileLastChangeTime));
		vXMLWriter.WriteAttribute("defaultSettings", vNameSpaceURI, TrimAll(vReportsRow.DefaultSettings));
		vXMLWriter.WriteAttribute("remarks", vNameSpaceURI, TrimAll(vReportsRow.Remarks));
		vXMLWriter.WriteAttribute("doNotGenerateOnOpen", vNameSpaceURI, TrimAll(vReportsRow.DoNotGenerateOnOpen));
		vXMLWriter.WriteAttribute("lockSettings", vNameSpaceURI, TrimAll(vReportsRow.LockSettings));
		vXMLWriter.WriteAttribute("isSystem", vNameSpaceURI, TrimAll(vReportsRow.IsSystem));
		WriteXML(vXMLWriter, vRepRef.GetObject(), XMLTypeAssignment.Explicit);
		vXMLWriter.WriteEndElement();
	EndDo;		
	vXMLWriter.WriteEndElement();
	vXMLWriter.WriteEndElement();
	vXMLWriter.Close();
	
	vFileBinaryData = New BinaryData(vFileName);
	vFileTempStorageAddress = PutToTempStorage(vFileBinaryData, UUID);
	
	DeleteFiles(vFileName);  
	
	Return vFileTempStorageAddress;
EndFunction // ExportAllReportsToXMLFileAtServer

// --------------------------------------------------------------------------------
&AtServer
Function ExportSelectedReportsSettingsToXMLFileAtServer()
	vFileName = GetTempFileName("xml");
	vNameSpaceURI = "http://1chotel.ru";
	vXMLWriter = New XMLWriter();
	vXMLWriter.OpenFile(vFileName, "UTF-8");
	vXMLWriter.WriteXMLDeclaration();
	vXMLWriter.WriteStartElement("Hotel");
	vXMLWriter.WriteNamespaceMapping("htl", vNameSpaceURI);
	For Each vRep In SelectedReports Do
		vRepObj = vRep.Value.GetObject();
		vXMLWriter.WriteStartElement("ReportSettings", vNameSpaceURI);
		vXMLWriter.WriteAttribute("report", vNameSpaceURI, TrimAll(vRepObj.Report));
		vXMLWriter.WriteAttribute("description", vNameSpaceURI, TrimAll(vRepObj.Description));
		vXMLWriter.WriteStartElement("Dynamic", vNameSpaceURI);
		WriteXML(vXMLWriter, vRepObj.DynamicParameters, XMLTypeAssignment.Explicit);
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteStartElement("Static", vNameSpaceURI);
		WriteXML(vXMLWriter, vRepObj.StaticParameters, XMLTypeAssignment.Explicit);
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteEndElement();
	EndDo;
	vXMLWriter.WriteEndElement();
	vXMLWriter.Close();
		
	vFileBinaryData = New BinaryData(vFileName);
	vFileTempStorageAddress = PutToTempStorage(vFileBinaryData, UUID);
	
	DeleteFiles(vFileName);
	
	Return vFileTempStorageAddress;
EndFunction // ExportReportSettingsToXMLFileAtServer

// --------------------------------------------------------------------------------
&AtServer 
Procedure LoadReportsFileAtServer(pTempStorageFileAddress)
	Try
		vTempFileName = GetTempFileName("xml");
		vBinaryData = GetFromTempStorage(pTempStorageFileAddress);
		vBinaryData.Write(vTempFileName);
		
		If LoadAllReports Then
			// Do in one transaction
			BeginTransaction(DataLockControlMode.Managed);
			
			// Clear all user defined reports
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	ReportsList.Ref AS Ref,
			|	ReportsList.Predefined AS Predefined,
			|	ReportsList.DeletionMark AS DeletionMark,
			|	ReportsList.IsFolder AS IsFolder,
			|	ReportsList.IsExternal AS IsExternal,
			|	ReportsList.Code AS Code,
			|	ReportsList.Description AS Description,
			|	ReportsList.Report AS Report
			|FROM
			|	Catalog.Reports AS ReportsList
			|
			|ORDER BY
			|	ReportsList.IsFolder,
			|	Code";
			vReports = vQry.Execute().Unload();
			For Each vReportsRow In vReports Do
				vRepObj = vReportsRow.Ref.GetObject();
				If vRepObj <> Undefined Then
					vRepObj.Delete();
				EndIf;
			EndDo;
			
			// Read all reports from file
			vReportIsFound = False;
			vXMLReader = New XMLReader();
			vXMLReader.OpenFile(vTempFileName);
			While vXMLReader.Read() Do
				If vXMLReader.NodeType = XMLNodeType.StartElement Then
					If vXMLReader.Name = "htl:ReportObject" Then
						vReportIsFound = True;
						vXMLReader.Read();
						vRepObj = ReadXML(vXMLReader);
						vRepObj.Write();
					EndIf;
				EndIf;
			EndDo;
			If Not vReportIsFound Then
				Raise NStr("en = 'The wrong file is selected for loadl!';
					   	   |de = 'Die falsche Datei ist zum Laden ausgewählt!';
					   	   |ru = 'Для загрузки выбран неверный файл!'");
			EndIf;
			// Commit transaction
			CommitTransaction();
		Else
			vCurrFolder = Items.Tree.CurrentRow;
			
			vXMLReader = New XMLReader();
			vXMLReader.OpenFile(vTempFileName);
			vSystemReportSynonym = "";
			vRepObjCreated = False;
			
			While vXMLReader.Read() Do
				If vXMLReader.NodeType = XMLNodeType.StartElement Then
					If vXMLReader.Name = "htl:ReportSettings" Then
						If vRepObjCreated Then
							vRepObj.Write();
						EndIf;
						vRepObj = Catalogs.Reports.CreateItem();
						vRepObjCreated = True;
						vRepObj.Parent = vCurrFolder;
						
						While vXMLReader.ReadAttribute() Do
							If vXMLReader.Name = "htl:report" Then
								vSystemReportSynonym = FindSystemReportSynonymByName(TrimAll(vXMLReader.Value));
								If ValueIsFilled(vSystemReportSynonym) Then
									vRepObj.Report = vXMLReader.Value;
								Else
									vRepObj.IsExternal = True;
									vRepObj.Report = GetExternalReportAttributeByValue(vXMLReader.Value);
								EndIf;
							EndIf;
							If vXMLReader.Name = "htl:description" Then
								vRepObj.Description = NStr(vXMLReader.Value);
								If Not ValueIsFilled(vRepObj.Description) Then
									vRepObj.Description = vXMLReader.Value;
								EndIf;
							EndIf;
						EndDo;
						If Not ValueIsFilled(vRepObj.Description) Then
							If ValueIsFilled(vSystemReportSynonym) Then
								vRepObj.Description = vSystemReportSynonym;
							Else
								vRepObj.Description = NStr(vRepObj.Report.Description);
								If Not ValueIsFilled(vRepObj.Description) Then
									vRepObj.Description = vRepObj.Report.Description;
								EndIf;
							EndIf;
						EndIf;
					ElsIf vXMLReader.Name = "htl:Dynamic" Then
						vXMLReader.Read();
						vRepObj.DynamicParameters = ReadXML(vXMLReader);
					ElsIf vXMLReader.Name = "htl:Static" Then
						vXMLReader.Read();
						vRepObj.StaticParameters = ReadXML(vXMLReader);
					EndIf;
				EndIf;
			EndDo;
			If vRepObjCreated Then
				vRepObj.Write();
			Else
				Raise NStr("en = 'The wrong file is selected for loadl!';
					   	   |de = 'Die falsche Datei ist zum Laden ausgewählt!';
					   	   |ru = 'Для загрузки выбран неверный файл!'");
			EndIf;
		EndIf;
		vXMLReader.Close();
		DeleteFiles(vTempFileName);
	Except
		vErrorInfo = ErrorInfo();
		If LoadAllReports Then
			If TransactionActive() Then
				RollbackTransaction();
			EndIf;
		EndIf;
		Raise cmGetRootErrorDescription(vErrorInfo);
	EndTry;		
EndProcedure // LoadReportsFileAtServer

// --------------------------------------------------------------------------------
&AtServerNoContext
Function FindSystemReportSynonymByName(pReportName)
	vRepPresentation = "";
	For Each vRepMetadata In Metadata.Reports Do
		vFound = False;
		If vRepMetadata.Name = pReportName Then
			// Check that Report attribute exists
			For Each vRepAttr In vRepMetadata.Attributes Do
				If vRepAttr.Name = "Report" Then
					vFound = True;
					Break;
				EndIf;
			EndDo;
		EndIf;
		If vFound Then
			vRepPresentation = vRepMetadata.Presentation();
		EndIf;
	EndDo;
	Return TrimAll(vRepPresentation);
EndFunction // FindSystemReportSynonymByName

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetExternalReportAttributeByValue(pValue)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ExternalDataProcessors.Ref AS Ref
	|FROM
	|	Catalog.ExternalDataProcessors AS ExternalDataProcessors
	|WHERE
	|	ExternalDataProcessors.Description LIKE &qValue";
	vQry.SetParameter("qValue", "%" + pValue + "%");
	vDescriptions = vQry.Execute().Unload();
	
	Return vDescriptions[0].Ref;
EndFunction // GetDefaultReportSettingFileName

// -----------------------------------------------------------------------------
&AtServer
Function ConnectExternalReport(pPath, pName = "", pUseSafeMode = False)
	Return ExternalReports.Connect(pPath, pName, pUseSafeMode);
EndFunction // ConnectExternalDataProcessor

// -----------------------------------------------------------------------------
&AtServer
Procedure AttributeChangeAtServer(pAttribute, pValue, pComparisonType = Undefined)
	If ValueIsFilled(pValue) Then
		vComparisonType = ?(pComparisonType = Undefined, DataCompositionComparisonType.Equal, pComparisonType);
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, pAttribute, pValue, vComparisonType, , True);
	EndIf;
EndProcedure // AttributeChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ClearingAttributeAtServer(pAttribute)
	tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, pAttribute, , , , False);
EndProcedure // ClearingAttributeAtServer

#Region ExportAllReportsToFile

// --------------------------------------------------------------------------------
&AtClient
Procedure ExportAllReportsToXMLFileAttachingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		OpenFileDialogToSaveFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension is being installing on your browser...'; ru='В браузер устанавливается расширение по работе с файлами...'; de='Dateisystemerweiterung wird in Ihrem Browser installiert...'"), MessageStatus.Information);
		BeginInstallFileSystemExtension(New NotifyDescription("ExportAllReportsToXMLFileFileSystemExtensionInstallCompleted", ThisObject, pParam));
	EndIf;
EndProcedure // LoadFromFileAttachingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure ExportAllReportsToXMLFileFileSystemExtensionInstallCompleted(pParam) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("ExportAllReportsToXMLFileInstallingFileSystemExtensionResult", ThisObject, pParam));
EndProcedure // LoadFromFileFileSystemExtensionInstallCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure ExportAllReportsToXMLFileInstallingFileSystemExtensionResult(pResult, pParam) Export 
	If pResult Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension was successfully installed on your browser!'; ru='В браузер успешно установлено расширение по работе с файлами!'; de='Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'"), MessageStatus.Information);
		OpenFileDialogToSaveFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Your browser does not support file operations in 1C!'; ru='Браузер не поддерживает работу с файлами в 1С!'; de='Ihr Browser unterstützt keine Dateioperationen in 1C!'"), MessageStatus.Attention);
	EndIf;
EndProcedure // ExportAllReportsToXMLFileInstallingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileDialogToSaveFileCompleted(pFileArray, pParam) Export
	If ValueIsFilled(pFileArray) Then
		vFullFileNameAtClient = pFileArray[0];
		StartTransferAllReportsFileFromServerToClient(vFullFileNameAtClient);
	EndIf;
EndProcedure // OpenFileDialogToSaveFileCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure StartTransferAllReportsFileFromServerToClient(pFullFileNameAtClient) Export
	If SelectedReports.Count() > 0 Then
		vFullFileNameAtServer = ExportSelectedReportsSettingsToXMLFileAtServer();
	Else
		vFullFileNameAtServer = ExportAllReportsToXMLFileAtServer();
	EndIf;
		
	vFilesArray = New Array();
	vFileDescription = New TransferableFileDescription(pFullFileNameAtClient, vFullFileNameAtServer);
	vFilesArray.Add(vFileDescription);
	
	BeginGettingFiles(New NotifyDescription("AllReportsFileDownloadToClientCompleted", ThisObject), vFilesArray, , False);
EndProcedure // StartTransferAllReportsFileFromServerToClient

// --------------------------------------------------------------------------------
&AtClient 
Procedure AllReportsFileDownloadToClientCompleted(pFilesArray, pParam) Export
	If pFilesArray <> Undefined Then
		// Show result message
		ShowMessageBox(, NStr("en='All database reports were exported to the file successfully!';ru='Все отчеты базы данных были успешно сохранены в файл!';de='Alle Datenbankberichte wurden erfolgreich in der Datei gespeichert!'"));
	EndIf;
EndProcedure // AllReportsFileDownloadToClientCompleted

// --------------------------------------------------------------------------------
&AtClient 
Procedure OpenFileDialogToSaveFile()
	vFileSave = New FileDialog(FileDialogMode.Save);
	If SelectedReports.Count() = 0 Then
		vFileSave.FullFileName = "1CHotelReportsAll.xml";
	Else
		vFileSave.FullFileName = "1CHotelReports.xml";
	EndIf;
	vFileSave.Filter = NStr("ru = 'XML файл (*.xml)|*.xml;|'; 
	                        |de = 'XML Datei (*.xml)|*.xml;|'; 
	                        |en = 'XML file (*.xml)|*.xml;|'");
	vFileSave.Multiselect = False;
	vFileSave.Title = NStr("en='Create file';ru='Создать файл';de='Datei erstellen'");
	vFileSave.Preview = False;
	vFileSave.CheckFileExist = True;
	vFileSave.Show(New NotifyDescription("OpenFileDialogToSaveFileCompleted", ThisObject));
EndProcedure // OpenFileDialogToSaveFile

#EndRegion

#Region LoadAllReportsFromFile

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadReportsFromXMLFileAttachingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		OpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension is being installing on your browser...'; ru='В браузер устанавливается расширение по работе с файлами...'; de='Dateisystemerweiterung wird in Ihrem Browser installiert...'"), MessageStatus.Information);
		BeginInstallFileSystemExtension(New NotifyDescription("LoadReportsFromXMLFileFileSystemExtensionInstallCompleted", ThisObject, pParam));
	EndIf;
EndProcedure // LoadReportsFromXMLFileAttachingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadReportsFromXMLFileFileSystemExtensionInstallCompleted(pParam) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadReportsFromXMLFileInstallingFileSystemExtensionResult", ThisObject, pParam));
EndProcedure // LoadReportsFromXMLFileFileSystemExtensionInstallCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadReportsFromXMLFileInstallingFileSystemExtensionResult(pResult, pParam) Export 
	If pResult Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension was successfully installed on your browser!'; ru='В браузер успешно установлено расширение по работе с файлами!'; de='Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'"), MessageStatus.Information);
		OpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Your browser does not support file operations in 1C!'; ru='Браузер не поддерживает работу с файлами в 1С!'; de='Ihr Browser unterstützt keine Dateioperationen in 1C!'"), MessageStatus.Attention);
	EndIf;
EndProcedure // LoadReportsFromXMLFileInstallingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileDialogToChooseFile()
	If LoadAllReports Then
		vFullFileName = "1CHotelReportsAll.xml";
	Else
		vFullFileName = "1CHotelReports.xml";
	EndIf;
	vFileOpen = New FileDialog(FileDialogMode.Open);
	vFileOpen.FullFileName = vFullFileName;
	vFileOpen.Multiselect = False;
	vFileOpen.Title = NStr("en='Open file';ru='Открыть файл';de='Datei öffnen'");
	vFileOpen.Preview = True;
	vFileOpen.Show(New NotifyDescription("OpenFileDialogToChooseFileCompleted", ThisObject));
EndProcedure // OpenFileDialogToChooseFile

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileDialogToChooseFileCompleted(pFileArray, pParam) Export
	If ValueIsFilled(pFileArray) Then
		vFullFileNameAtClient = pFileArray[0];
		StartTransferReportsFileFromClientToServer(vFullFileNameAtClient);
	EndIf;
EndProcedure // OpenFileDialogToChooseFileCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure StartTransferReportsFileFromClientToServer(pFullFileNameAtClient)
	vFilesArray = New Array();
	vFileDescription = New TransferableFileDescription(pFullFileNameAtClient, );
	vFilesArray.Add(vFileDescription);
	BeginPuttingFiles(New NotifyDescription("TransferReportsFileFromClientToServerCompleted", ThisObject), vFilesArray, , False);
EndProcedure // StartTransferReportsFileFromClientToServer

// --------------------------------------------------------------------------------
&AtClient
Procedure TransferReportsFileFromClientToServerCompleted(pTransferredFiles, pParam) Export
	vTempStorageFileAddressAtServer = pTransferredFiles.Get(0).Location;
	LoadReportsFileAtServer(vTempStorageFileAddressAtServer);
	
	Items.List.Refresh();
	Items.Tree.Refresh();
	
	If LoadAllReports Then
		ShowMessageBox(, NStr("en='All database reports were loaded from the file successfully!';ru='Все отчеты базы данных были успешно восстановлены из файла!';de='Alle Datenbankberichte wurden erfolgreich aus der Datei wiederhergestellt!'"), 5);
	Else
		ShowMessageBox(, NStr("en='Report settings were loaded from the file and saved to the database successfully!';ru='Настройки отчета были успешно загружены из файла и сохранены в базе данных!';de='Die Berichtseinstellungen wurden erfolgreich aus der Datei geladen und in der Datenbank gespeichert!'"), 5);
	EndIf;
EndProcedure // TransferReportsFileFromClientToServerCompleted

#EndRegion

#EndRegion
