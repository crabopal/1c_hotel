
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	ValueStorageDataTempStorageAddress = "";
	// Form caption
	AutoTitle = False;
	Title = cmNStr(Object.Description, SessionParameters.CurrentLanguage);
	ClearExternalTemplate = False;
	// Report type
	ReportTypeOnChangeAtServer();
	// Fill list of report attributes
	FillListOfReportAttributes();
	// Packages appearance
	IsPackageOnChangeAtServer();
	// Save all value storage data
	vValueStorageDataStruct = New Structure("StaticParameters, ExternalTemplate, DefaultSettings", Undefined, Undefined, Undefined);
	vRef = Object.Ref;
	If Parameters.Property("CopyingValue") And ValueIsFilled(Parameters.CopyingValue) Then
		vRef = Parameters.CopyingValue;
	EndIf;
	If ValueIsFilled(vRef) Then
		vStaticParametersStruct = vRef.StaticParameters.Get();
		If vStaticParametersStruct <> Undefined And TypeOf(vStaticParametersStruct) = Type("Structure") Then
			If vStaticParametersStruct.Property("Hotel") And cmIsBrokenRef("Catalog.Hotels", vStaticParametersStruct.Hotel) Then
				vStaticParametersStruct.Hotel = Catalogs.Hotels.EmptyRef();
			EndIf;
			vValueStorageDataStruct.StaticParameters = vStaticParametersStruct;
		EndIf;
		vExternalTemplateBinaryData = vRef.ExternalTemplate.Get();
		If vExternalTemplateBinaryData <> Undefined And TypeOf(vExternalTemplateBinaryData) = Type("BinaryData") Then
			vValueStorageDataStruct.ExternalTemplate = vExternalTemplateBinaryData;
		EndIf;
		vDefaultSettingsBinaryData = vRef.DefaultSettings.Get();
		If vDefaultSettingsBinaryData <> Undefined And TypeOf(vDefaultSettingsBinaryData) = Type("BinaryData") Then
			vValueStorageDataStruct.DefaultSettings = vDefaultSettingsBinaryData;
		EndIf;
	EndIf;
	ValueStorageDataTempStorageAddress = PutToTempStorage(vValueStorageDataStruct, UUID);
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	vValueStorageDataStruct = GetFromTempStorage(ValueStorageDataTempStorageAddress);
	If vValueStorageDataStruct.StaticParameters <> Undefined And TypeOf(vValueStorageDataStruct.StaticParameters) = Type("Structure") Then
		pCurrentObject.StaticParameters = New ValueStorage(vValueStorageDataStruct.StaticParameters);
	Else
		pCurrentObject.StaticParameters = Undefined;
	EndIf;
	If ClearExternalTemplate Then
		pCurrentObject.ExternalTemplate = Undefined;
	Else
		If vValueStorageDataStruct.ExternalTemplate <> Undefined And TypeOf(vValueStorageDataStruct.ExternalTemplate) = Type("BinaryData") Then
			pCurrentObject.ExternalTemplate = New ValueStorage(vValueStorageDataStruct.ExternalTemplate);
		Else
			pCurrentObject.ExternalTemplate = Undefined;
		EndIf;
	EndIf;
	If vValueStorageDataStruct.DefaultSettings <> Undefined And TypeOf(vValueStorageDataStruct.DefaultSettings) = Type("BinaryData") Then
		pCurrentObject.DefaultSettings = New ValueStorage(vValueStorageDataStruct.DefaultSettings);
	Else
		pCurrentObject.DefaultSettings = Undefined;
	EndIf;
EndProcedure // BeforeWriteAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure AfterWriteAtServer(pCurrentObject, pWriteParameters)
	ClearExternalTemplate = False;
EndProcedure // AfterWriteAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	Notify("Report.Chaged",,Object.Ref);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure IsExternalOnChange(pItem)
	ReportTypeOnChangeAtServer();
EndProcedure // IsExternalOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure IsPackageOnChange(pItem)
	IsPackageOnChangeAtServer();
EndProcedure // IsPackageOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure DescriptionOpening(pItem, pStandardProcessing)
	pStandardProcessing = false;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", Object.Description), pItem);
EndProcedure // DescriptionOpening

// --------------------------------------------------------------------------------
&AtClient
Procedure ReportOnChange(pItem)
	// Fill list of report attributes
	FillListOfReportAttributes(); 
	// Fill description
	If IsBlankString(Object.Description) And Object.IsExternal = False And Not IsBlankString(Object.Report) Then
		Object.Description = GetPresentationReport(Object.Report) 	
	EndIf;
EndProcedure // ReportOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure PackageOnStartEdit(pItem, pNewRow, pClone)
	If pNewRow Then
		vRowData = Items.Package.CurrentData;
		If vRowData <> Undefined Then
			vRowData.IsActive = True;
		EndIf;
	EndIf;
EndProcedure // PackageOnStartEdit

// --------------------------------------------------------------------------------
&AtClient
Procedure PackageReportOnChange(Item)
	vRowData = Items.Package.CurrentData;
	If vRowData <> Undefined And ValueIsFilled(vRowData.Report) Then
		If vRowData.Report = Object.Ref Then
			vRowData.Report = PredefinedValue("Catalog.Reports.EmptyRef");
			ShowMessageBox(, NStr("en='You could not choose report itself!';ru='Нельзя выбирать самого себя!';de='Man darf sich selbst nicht wählen!'"));
		ElsIf tcOnServer.cmGetAttributeByRef(vRowData.Report, "IsPackage") Then
			vRowData.Report = PredefinedValue("Catalog.Reports.EmptyRef");
			ShowMessageBox(, NStr("en='You could not choose report package!';ru='Нельзя выбирать пакеты отчетов!';de='Berichtpakete dürfen nicht gewählt werden!'"));
		EndIf;
	EndIf;
EndProcedure // PackageReportOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure RemarksOpening(pItem, pStandardProcessing)
	pStandardProcessing = false;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", Object.Remarks), pItem);
EndProcedure // RemarksOpening

// --------------------------------------------------------------------------------
&AtClient
Procedure AvailableAttributesDragStart(pItem, pDragParameters, pPerform)
	vRowData = AvailableAttributes.FindByID(pDragParameters.Value);
	If vRowData <> Undefined Then
		pDragParameters.Value = TrimAll(vRowData.Attribute);
	EndIf;
EndProcedure // AvailableAttributesDragStart

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFile(pCommand)
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadFromFileAttachingFileSystemExtensionResult", ThisObject));
EndProcedure // LoadFile

// --------------------------------------------------------------------------------
&AtClient
Procedure ClearFile(pCommand)
	ClearFileAtServer();
EndProcedure // ClearFile

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadReportSettingsFromXMLFile(pCommand)
	// Check that form is saved
	If Modified Then
		If Not Write() Then
			Return;
		EndIf;
	EndIf;
	// Start file operations
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadReportSettingsFromXMLFileAttachingFileSystemExtensionResult", ThisObject));
EndProcedure // LoadReportSettingsFromXMLFile

// --------------------------------------------------------------------------------
&AtClient
Procedure ResetReportSettings(pCommand)
	ResetReportSettingsAtServer();
	If Modified Then
		Modified = False;
	EndIf;
	Close();
	ShowMessageBox(, NStr("en='Report settings were reset to the system values!';ru='Настройки отчета были успешно сброшены к системным установкам!';de='Berichtseinstellungen wurden auf die Systemwerte zurückgesetzt!'"), 5);
EndProcedure // ResetReportSettings
	
// --------------------------------------------------------------------------------
&AtClient
Procedure SaveReportSettingsToXMLFile(pCommand)
	// Check that form is saved
	If Modified Then
		If Not Write() Then
			Return;
		EndIf;
	EndIf;
	// Start file operations
	BeginAttachingFileSystemExtension(New NotifyDescription("SaveReportSettingsToXMLFileAttachingFileSystemExtensionResult", ThisObject));
EndProcedure // SaveReportSettingsToXMLFile

// --------------------------------------------------------------------------------
&AtClient
Procedure SaveFile(Command)
	OpenFileDialogToSaveFile();		
EndProcedure // SaveFile

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure ReportTypeOnChangeAtServer()
	If Object.IsExternal Then
		If TypeOf(Object.Report) <> Type("CatalogRef.ExternalDataProcessors") Then
			Object.Report = Catalogs.ExternalDataProcessors.EmptyRef();
		EndIf;
		Items.Report.TextEdit = True;
		Items.Report.ListChoiceMode = False;
		Items.Report.DropListButton = False;
		Items.Report.ChoiceButton = True;
		Items.Report.OpenButton = True;
		Items.Report.ClearButton = True;
	Else
		If TypeOf(Object.Report) <> Type("String") Then
			Object.Report = "";
		EndIf;
		Items.Report.TextEdit = False;
		Items.Report.ListChoiceMode = True;
		Items.Report.DropListButton = True;
		Items.Report.ChoiceButton = False;
		Items.Report.OpenButton = False;
		Items.Report.ClearButton = False;
		vReportsList = cmFillReportsList();  
		Items.Report.ChoiceList.Clear();
		For Each vRowRP In vReportsList Do
			Items.Report.ChoiceList.Add(vRowRP.Value, vRowRP.Presentation);	
		EndDo;
	EndIf;
	AvailableAttributes.Clear();
EndProcedure // ExternalProcessingTypeOnChangeAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure IsPackageOnChangeAtServer()
	If Object.IsPackage Then
		Items.Package.Enabled = True;
	Else
		Items.Package.Enabled = False;
	EndIf;
EndProcedure // IsPackageOnChangeAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure CommandActionLoadFromFileAtServer(pBinaryData, pFileName, pFileLastChangeTime) 
	vValueStorageDataStruct = GetFromTempStorage(ValueStorageDataTempStorageAddress);
	vValueStorageDataStruct.ExternalTemplate = pBinaryData;
	ValueStorageDataTempStorageAddress = PutToTempStorage(vValueStorageDataStruct, UUID);
	If Object.ExternalTemplateFileName <> pFileName Or Not ValueIsFilled(Object.ExternalTemplateFileLoadTime) Then
		Object.ExternalTemplateFileLoadTime = CurrentSessionDate();
	EndIf;
	ClearExternalTemplate = False;
	Object.ExternalTemplateFileName = pFileName;
	Object.ExternalTemplateFileLastChangeTime = pFileLastChangeTime;
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
&AtServer
Procedure FillListOfReportAttributes()
	AvailableAttributes.Clear();
	// Fill list of atributes from the data processor object metadata
	Try
		vRepObj = cmBuildReportObject(Object);
		If vRepObj <> Undefined Then
			For Each vAttr In vRepObj.Metadata().Attributes Do
				vRow = AvailableAttributes.Add();
				vRow.Attribute = "REP." + vAttr.Name;
			EndDo;
		EndIf;
		vRow = AvailableAttributes.Add();
		vRow.Attribute = "PARM";
		vRow = AvailableAttributes.Add();
		vRow.Attribute = "SessionParameters.CurrentUser";
		vRow = AvailableAttributes.Add();
		vRow.Attribute = "SessionParameters.CurrentWorkstation";
		vRow = AvailableAttributes.Add();
		vRow.Attribute = "SessionParameters.CurrentHotel";
		vRow = AvailableAttributes.Add();
		vRow.Attribute = "CurrentSessionDate()";
		vRow = AvailableAttributes.Add();
		vRow.Attribute = "BegOfDay(CurrentSessionDate())";
		vRow = AvailableAttributes.Add();
		vRow.Attribute = "EndOfDay(CurrentSessionDate())";
		vRow = AvailableAttributes.Add();
		vRow.Attribute = "BegOfWeek(CurrentSessionDate())";
		vRow = AvailableAttributes.Add();
		vRow.Attribute = "EndOfWeek(CurrentSessionDate())";
		vRow = AvailableAttributes.Add();
		vRow.Attribute = "BegOfMonth(CurrentSessionDate())";
		vRow = AvailableAttributes.Add();
		vRow.Attribute = "EndOfMonth(CurrentSessionDate())";
		vRow = AvailableAttributes.Add();
		vRow.Attribute = "BegOfQuarter(CurrentSessionDate())";
		vRow = AvailableAttributes.Add();
		vRow.Attribute = "EndOfQuarter(CurrentSessionDate())";
		vRow = AvailableAttributes.Add();
		vRow.Attribute = "BegOfYear(CurrentSessionDate())";
		vRow = AvailableAttributes.Add();
		vRow.Attribute = "EndOfYear(CurrentSessionDate())";
	Except
		AvailableAttributes.Clear();
		vRow = AvailableAttributes.Add();
		vRow.Attribute = NStr("en='Failed to create report object for settings specified!';ru='Ошибка создания объекта отчета по текущим параметрам!';de='Fehler bei der Erstellung des Berichtsobjekts nach aktuellen Parametern!'");
	EndTry;
EndProcedure // FillListOfReportAttributes

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
	vFileOpen.Filter = NStr("ru = 'Шаблон отчета (*.mxl)|*.mxl;|'; 
	                        |de = 'Berichtsvorlage (*.mxl)|*.mxl;|'; 
	                        |en = 'Report template (*.mxl)|*.mxl;|'");
	vFileOpen.Multiselect = False;
	vFileOpen.Title = NStr("en='Open file';ru='Открыть файл';de='Datei öffnen'");
	vFileOpen.Preview = True;
	vFileOpen.Show(New NotifyDescription("OpenFileDialogToChooseFileCompleted", ThisObject));
EndProcedure // OpenFileDialogToChooseFile

// --------------------------------------------------------------------------------
&AtServer
Procedure ClearFileAtServer()
	ClearExternalTemplate = True;
	Object.ExternalTemplateFileName = "";
	Object.ExternalTemplateFileLastChangeTime = '00010101';
	Object.ExternalTemplateFileLoadTime = '00010101';
	Modified = True;
EndProcedure // ClearPhotoAtServer

// --------------------------------------------------------------------------------
&AtClient 
Procedure OpenFileDialogToSaveFile()
	vFileSave = New FileDialog(FileDialogMode.Save);
	vFileSave.Filter = NStr("ru = 'Шаблон отчета (*.mxl)|*.mxl;|'; 
	                        |de = 'Berichtsvorlage (*.mxl)|*.mxl;|'; 
	                        |en = 'Report template (*.mxl)|*.mxl;|'");
	vFileSave.DefaultExt = "mxl";
	vFileSave.Multiselect = False;
	vFileSave.Title = NStr("en='Save file';ru='Сохранить файл';de='Datei speichern'");
	vFileSave.CheckFileExist = True;
	vFileSave.Show(New NotifyDescription("OpenFileDialogToSaveFileCompleted", ThisObject));
EndProcedure // OpenFileDialogToSaveFile

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileDialogToSaveFileCompleted(pFileArray, pParam) Export 
	If ValueIsFilled(pFileArray) Then
		vFullFileName = pFileArray[0];
		vValueStorageDataStruct = GetFromTempStorage(ValueStorageDataTempStorageAddress);
		vFileBinaryData = vValueStorageDataStruct.ExternalTemplate;
		If vFileBinaryData <> Undefined And TypeOf(vFileBinaryData) = Type("BinaryData") Then
			vFileBinaryData.BeginWrite(New NotifyDescription("SaveFileAfterWrite", ThisObject), vFullFileName);
		EndIf;
	EndIf;
EndProcedure // OpenFileDialogToSaveFileCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure SaveFileAfterWrite(pExtraParams) Export
	ShowMessageBox(, NStr("en='Success!'; ru='Успешно!'; de='Erfolg!'"), 3);
EndProcedure // SaveFileAfterWrite

// --------------------------------------------------------------------------------
&AtServer
Procedure ResetReportSettingsAtServer()
	vRepObj = FormAttributeToValue("Object");
	
	// Reset dynamic parameters
	vRepObj.DynamicParameters = "";
	
	// Reset static parameters
	vRepObj.StaticParameters = Undefined;
	
	// Save cleared parameters
	vRepObj.Write();
	
	// Initialize structure of the static parameters
	If ValueIsFilled(vRepObj.Report) And Not vRepObj.IsExternal Then
		vReportObject = Reports[TrimAll(vRepObj.Report)].Create();
		vReportObject.pmFillAttributesWithDefaultValues();
		vReportObject.pmInitializeReportBuilder();
			
		vStatic = New Structure();
		For Each vAttr In vReportObject.Metadata().Attributes Do
			If vAttr.Name <> "Report" And vAttr.Name <> "ReportBuilder" Then
				vStatic.Insert(vAttr.Name);
			EndIf;
		EndDo;
		
		// Fill structure from the report object attributes
		FillPropertyValues(vStatic, vReportObject);
		
		// Save report builder settings
		Try
			If vReportObject.ReportBuilder <> Undefined Then
				vStatic.Insert("ReportBuilderSettings", vReportObject.ReportBuilder.GetSettings(True, True, True, True, True));
			EndIf;
		Except
		EndTry;
		
		// Save structure in the value storage of the report catalog item
		vStaticVS = New ValueStorage(vStatic);
		vRepObj.StaticParameters = vStaticVS;
	EndIf;
	
	// Save parameters
	vRepObj.Write();
	
	ValueToFormAttribute(vRepObj, "Object");
	Modified = False;
EndProcedure // ResetReportSettingsAtServer

// --------------------------------------------------------------------------------
&AtServer
Function ExportReportSettingsToXMLFileAtServer()
	vRepObj = FormAttributeToValue("Object");
	
	vFileName = GetTempFileName("xml");
	vNameSpaceURI = "http://1chotel.ru";
	vXMLWriter = New XMLWriter();
	vXMLWriter.OpenFile(vFileName, "UTF-8");
	vXMLWriter.WriteXMLDeclaration();
	vXMLWriter.WriteStartElement("Hotel");
	vXMLWriter.WriteNamespaceMapping("htl", vNameSpaceURI);
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
	vXMLWriter.WriteEndElement();
	vXMLWriter.Close();
	
	vFileBinaryData = New BinaryData(vFileName);
	vFileTempStorageAddress = PutToTempStorage(vFileBinaryData, UUID);
	
	DeleteFiles(vFileName);
	
	Return vFileTempStorageAddress;
EndFunction // ExportReportSettingsToXMLFileAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure SaveReportSettingsToXMLFileAttachingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		OpenFileDialogToSaveReportSettingsXMLFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension is being installing on your browser...'; ru='В браузер устанавливается расширение по работе с файлами...'; de='Dateisystemerweiterung wird in Ihrem Browser installiert...'"), MessageStatus.Information);
		BeginInstallFileSystemExtension(New NotifyDescription("SaveReportSettingsToXMLFileFileSystemExtensionInstallCompleted", ThisObject, pParam));
	EndIf;
EndProcedure // SaveReportSettingsToXMLFileAttachingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure SaveReportSettingsToXMLFileFileSystemExtensionInstallCompleted(pParam) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("SaveReportSettingsToXMLFileInstallingFileSystemExtensionResult", ThisObject, pParam));
EndProcedure // SaveReportSettingsToXMLFileFileSystemExtensionInstallCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure SaveReportSettingsToXMLFileInstallingFileSystemExtensionResult(pResult, pParam) Export 
	If pResult Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension was successfully installed on your browser!'; ru='В браузер успешно установлено расширение по работе с файлами!'; de='Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'"), MessageStatus.Information);
		OpenFileDialogToSaveReportSettingsXMLFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Your browser does not support file operations in 1C!'; ru='Браузер не поддерживает работу с файлами в 1С!'; de='Ihr Browser unterstützt keine Dateioperationen in 1C!'"), MessageStatus.Attention);
	EndIf;
EndProcedure // SaveReportSettingsToXMLFileInstallingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileDialogToSaveReportSettingsXMLFileCompleted(pFileArray, pParam) Export
	If ValueIsFilled(pFileArray) Then
		vFullFileNameAtClient = pFileArray[0];
		StartTransferReportSettingsFileFromServerToClient(vFullFileNameAtClient);
	EndIf;
EndProcedure // OpenFileDialogToSaveReportSettingsXMLFileCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure StartTransferReportSettingsFileFromServerToClient(pFullFileNameAtClient) Export
	vFileAddressAtServer = ExportReportSettingsToXMLFileAtServer();

	vFilesArray = New Array();
	vFileDescription = New TransferableFileDescription(pFullFileNameAtClient, vFileAddressAtServer);
	vFilesArray.Add(vFileDescription);
	
	BeginGettingFiles(New NotifyDescription("ReportSettingsFileDownloadToClientCompleted", ThisObject), vFilesArray, , False);
EndProcedure // StartTransferReportSettingsFileFromServerToClient

// --------------------------------------------------------------------------------
&AtClient 
Procedure ReportSettingsFileDownloadToClientCompleted(pFilesArray, pParam) Export
	If pFilesArray <> Undefined Then
		// Show result message
		ShowMessageBox(, NStr("en='Report settings were exported to the file successfully!';ru='Настройки отчета были успешно сохранены в файл!';de='Die Berichtseinstellungen wurden erfolgreich in einer Datei gespeichert!'"), 5);
	EndIf;
EndProcedure // ReportSettingsFileDownloadToClientCompleted

// --------------------------------------------------------------------------------
&AtClient 
Procedure OpenFileDialogToSaveReportSettingsXMLFile()
	vFileSave = New FileDialog(FileDialogMode.Save);
	vFileSave.FullFileName = GetDefaultReportSettingsFileName(Object.Description, Object.Code);
	vFileSave.Filter = NStr("ru = 'XML файл (*.xml)|*.xml;|'; 
	                        |de = 'XML Datei (*.xml)|*.xml;|'; 
	                        |en = 'XML file (*.xml)|*.xml;|'");
	vFileSave.Multiselect = False;
	vFileSave.Title = NStr("en='Create file';ru='Создать файл';de='Datei erstellen'");
	vFileSave.Preview = False;
	vFileSave.CheckFileExist = True;
	vFileSave.Show(New NotifyDescription("OpenFileDialogToSaveReportSettingsXMLFileCompleted", ThisObject));
EndProcedure // OpenFileDialogToSaveReportSettingsXMLFile

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetDefaultReportSettingsFileName(pDescription, pCode)
	Return StrReplace(cmGetValidFileName(cmNStr(TrimAll(pDescription))), " ", "_") + "_" + TrimAll(pCode);
EndFunction // GetDefaultReportSettingFileName

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadReportSettingsFromXMLFileAttachingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		OpenReportSettingsXMLFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension is being installing on your browser...'; ru='В браузер устанавливается расширение по работе с файлами...'; de='Dateisystemerweiterung wird in Ihrem Browser installiert...'"), MessageStatus.Information);
		BeginInstallFileSystemExtension(New NotifyDescription("LoadReportSettingsFromXMLFileFileSystemExtensionInstallCompleted", ThisObject, pParam));
	EndIf;
EndProcedure // LoadReportSettingsFromXMLFileAttachingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadReportSettingsFromXMLFileFileSystemExtensionInstallCompleted(pParam) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadReportSettingsFromXMLFileInstallingFileSystemExtensionResult", ThisObject, pParam));
EndProcedure // LoadReportSettingsFromXMLFileFileSystemExtensionInstallCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadReportSettingsFromXMLFileInstallingFileSystemExtensionResult(pResult, pParam) Export 
	If pResult Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension was successfully installed on your browser!'; ru='В браузер успешно установлено расширение по работе с файлами!'; de='Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'"), MessageStatus.Information);
		OpenReportSettingsXMLFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Your browser does not support file operations in 1C!'; ru='Браузер не поддерживает работу с файлами в 1С!'; de='Ihr Browser unterstützt keine Dateioperationen in 1C!'"), MessageStatus.Attention);
	EndIf;
EndProcedure // LoadReportSettingsFromXMLFileInstallingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenReportSettingsXMLFileDialogToChooseFile()
	vFileOpen = New FileDialog(FileDialogMode.Open);
	vFileOpen.FullFileName = GetDefaultReportSettingsFileName(Object.Description, Object.Code);
	vFileOpen.Multiselect = False;
	vFileOpen.Title = NStr("en='Open file';ru='Открыть файл';de='Datei öffnen'");
	vFileOpen.Preview = False;
	vFileOpen.Show(New NotifyDescription("OpenReportSettingsXMLFileDialogToChooseFileCompleted", ThisObject));
EndProcedure // OpenReportSettingsXMLFileDialogToChooseFile

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenReportSettingsXMLFileDialogToChooseFileCompleted(pFileArray, pParam) Export
	If ValueIsFilled(pFileArray) Then
		vFullFileNameAtClient = pFileArray[0];
		StartTransferReportSettingsFileFromClientToServer(vFullFileNameAtClient);
	EndIf;
EndProcedure // OpenReportSettingsXMLFileDialogToChooseFileCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure StartTransferReportSettingsFileFromClientToServer(pFullFileNameAtClient)
	vFilesArray = New Array();
	vFileDescription = New TransferableFileDescription(pFullFileNameAtClient, );
	vFilesArray.Add(vFileDescription);
	BeginPuttingFiles(New NotifyDescription("TransferReportSettingsFileFromClientToServerCompleted", ThisObject), vFilesArray, , False);
EndProcedure // StartTransferReportSettingsFileFromClientToServer

// --------------------------------------------------------------------------------
&AtClient
Procedure TransferReportSettingsFileFromClientToServerCompleted(pTransferredFiles, pParam) Export
	vTempStorageFileAddressAtServer = pTransferredFiles.Get(0).Location;
	LoadReportSettingsFileAtServer(vTempStorageFileAddressAtServer);
	ShowMessageBox(, NStr("en='Report settings were loaded from the file and saved to the database successfully!';ru='Настройки отчета были успешно загружены из файла и сохранены в базе данных!';de='Die Berichtseinstellungen wurden erfolgreich aus der Datei geladen und in der Datenbank gespeichert!'"), 5);
EndProcedure // TransferReportSettingsFileFromClientToServerCompleted

// --------------------------------------------------------------------------------
&AtServer
Procedure LoadReportSettingsFileAtServer(pSettingsFileAddressAtServer)
	vTempFileName = GetTempFileName("xml");
	vBinaryData = GetFromTempStorage(pSettingsFileAddressAtServer);
	vBinaryData.Write(vTempFileName);
		
	vRepObj = FormAttributeToValue("Object");
	vSystemReportSynonym = "";
		
	vXMLReader = New XMLReader();
	vXMLReader.OpenFile(vTempFileName);
	While vXMLReader.Read() Do
		If vXMLReader.NodeType = XMLNodeType.StartElement Then
			If vXMLReader.Name = "htl:ReportSettings" Then
				While vXMLReader.ReadAttribute() Do
					If vXMLReader.Name = "htl:report" Then
						If Not ValueIsFilled(vRepObj.Report) Then
							vSystemReportSynonym = FindSystemReportSynonymByName(TrimAll(vXMLReader.Value));
							If ValueIsFilled(vSystemReportSynonym) Then
								vRepObj.Report = vXMLReader.Value;
							Else
								vRepObj.IsExternal = True;
								vRepObj.Report = GetExternalReportAttributeByValue(vXMLReader.Value);
							EndIf;
						ElsIf vXMLReader.Value <> TrimAll(vRepObj.Report) Then
							Raise NStr("en='Report settings you are trying to load from are of different report type!';
							           |ru='Тип отчета, настройки которого пытаетесь загрузить, отличается от типа текущего отчета!';
									   |de='Der Berichtstyp, dessen Einstellungen Sie zu laden versuchen, unterscheidet sich vom Typ des aktuellen Berichts!'");
						EndIf;
					EndIf;
					If vXMLReader.Name = "htl:description" Then
						If Not ValueIsFilled(vRepObj.Description) Then
							If ValueIsFilled(vXMLReader.Value) Then
								vRepObj.Description = NStr(vXMLReader.Value);
								If Not ValueIsFilled(vRepObj.Description) Then
									vRepObj.Description = vXMLReader.Value;
								EndIf;
							EndIf;
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
	vXMLReader.Close();
	
	// Save report settings to the database
	vRepObj.Write();
	
	// Update value storage struct
	vValueStorageDataStruct = GetFromTempStorage(ValueStorageDataTempStorageAddress);
	If vRepObj.StaticParameters <> Undefined Then
		vValueStorageDataStruct.StaticParameters = vRepObj.StaticParameters.Get();
	Else
		vValueStorageDataStruct.StaticParameters = Undefined;
	EndIf;
	ValueStorageDataTempStorageAddress = PutToTempStorage(vValueStorageDataStruct, UUID);
	
	// Refresh form data
	ValueToFormAttribute(vRepObj, "Object");
	ReportTypeOnChangeAtServer();
	Modified = False;
EndProcedure // LoadReportSettingsFileAtServer

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

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetPresentationReport(pDPName)
	vDesc = "";
	vRP = Metadata.Reports.Find(pDPName);
	If vRP <> Undefined Then
		vDesc = vRP.Synonym;   
	EndIf;   
	Return vDesc;
EndFunction // GetPresentationDataProcessor()

#EndRegion    
