
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

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenDPForm(pCommand)
	vCurRow = Items.List.CurrentData;
	If vCurRow <> Undefined Then
		Try     
			pDPRef = vCurRow.Ref;
			vDPObj = tcOnServer.cmGetAtributeAsArray(pDPRef);
			If vDPObj.IsExternal Then  
				vExtDPO = tcOnServer.cmGetAtributeAsArray(vDPObj.Processing); 
				If vExtDPO.ExternalProcessingType = PredefinedValue("Enum.ExternalProcessingTypes.Algorithm") Then
					ExecuteAlgoritm(vExtDPO);
				Else	
					vURL = GetURL(vDPObj.Processing, "ExternalProcessingStorage"); 
					vName = ConnectExternalDataProcessor(vURL, StrReplace(tcOnServer.cmGetAttributeByRef(vDPObj.Processing,"FileName"),".epf",""));
					vParams = New Structure("DataProcessor", pDPRef);
					OpenForm("ExternalDataProcessor." + vName + ".Form", vParams, ThisObject, pDPRef);     
				EndIf;
			Else
				If vDPObj.Processing = Undefined Or vDPObj.Processing = "" Then
					ShowMessageBox(, Nstr("en = 'You must fill the handler in the processing settings'; de = 'Sie müssen den Handler in den Verarbeitungseinstellungen angeben'; ru = 'Необходимо заполнить обработчик в настройках обработки'"));
				Else
					OpenForm("DataProcessor." + vDPObj.Processing + ".Form", New Structure("DataProcessor", pDPRef), ThisObject, pDPRef);
				EndIf;
			EndIf; 
		Except
			ClearMessages();
			vErr = ErrorInfo();     
			vErrMsg = NStr("en = 'This data processor could not be executed in thin client mode yet!'; 
						   |de = 'Dieser Bearbeitung kann noch nicht in Thin-Client-Modus gestartet werden!'; 
						   |ru = 'Эта обработка пока не может быть запущена в режиме тонкого клиента!'") + Chars.LF + BriefErrorDescription(vErr); 
			tcCommonFunctionOnClientServer.UserMessage(vErrMsg);
			
		EndTry;
	EndIf;
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

// -----------------------------------------------------------------------------
&AtServer
Procedure ExecuteAlgoritm(pDPO)
	vAlgorithm = TrimAll(pDPO.Algorithm);
	Execute(vAlgorithm);
EndProcedure // ExecuteAlgoritm

// -----------------------------------------------------------------------------
&AtServerNoContext
Function ConnectExternalDataProcessor(pPath, pName = "", pUseSafeMode = False)
	Return ExternalDataProcessors.Connect(pPath, pName, pUseSafeMode);
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
	vXMLWriter.WriteStartElement("DataProcessors", vNameSpaceURI);
	
	// Do for each data processor in the catalog
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	DataProcessors.Ref AS Ref,
	|	DataProcessors.Predefined AS Predefined,
	|	DataProcessors.IsFolder AS IsFolder,
	|	DataProcessors.Code AS Code,
	|	DataProcessors.Description AS Description,
	|	DataProcessors.Processing AS Processing,
	|	DataProcessors.IsExternal AS IsExternal,
	|	DataProcessors.StaticParameters AS StaticParameters,
	|	DataProcessors.DynamicParameters AS DynamicParameters,
	|	DataProcessors.Key AS Key,
	|	DataProcessors.Remarks AS Remarks,
	|	DataProcessors.IsSystem AS IsSystem,
	|	DataProcessors.SortCode AS SortCode
	|FROM
	|	Catalog.DataProcessors AS DataProcessors
	|WHERE
	|	NOT DataProcessors.DeletionMark
	|
	|ORDER BY
	|	IsFolder DESC,
	|	Code";
	vResult = vQry.Execute().Unload();
	For Each vRow In vResult Do
		vRef = vRow.Ref;
		// Write data processor to the XML
		vXMLWriter.WriteStartElement("DataProcessorObject", vNameSpaceURI);
		vXMLWriter.WriteAttribute("processing", vNameSpaceURI, String(vRow.Processing));
		vXMLWriter.WriteAttribute("isFolder", vNameSpaceURI, String(vRow.IsFolder));
		vXMLWriter.WriteAttribute("predefined", vNameSpaceURI, String(vRow.Predefined));
		vXMLWriter.WriteAttribute("code", vNameSpaceURI, TrimAll(vRow.Code));
		vXMLWriter.WriteAttribute("description", vNameSpaceURI, TrimAll(vRow.Description));
		vXMLWriter.WriteAttribute("isExternal", vNameSpaceURI, TrimAll(vRow.IsExternal));
		vXMLWriter.WriteAttribute("staticParameters", vNameSpaceURI, TrimAll(vRow.StaticParameters));
		vXMLWriter.WriteAttribute("dynamicParameters", vNameSpaceURI, TrimAll(vRow.DynamicParameters));
		vXMLWriter.WriteAttribute("key", vNameSpaceURI, TrimAll(vRow.Key));
		vXMLWriter.WriteAttribute("remarks", vNameSpaceURI, TrimAll(vRow.Remarks));
		vXMLWriter.WriteAttribute("isSystem", vNameSpaceURI, TrimAll(vRow.IsSystem));
		vXMLWriter.WriteAttribute("sortCode", vNameSpaceURI, TrimAll(vRow.SortCode));
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
			// Clear all user defined data processors
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	DataProcessors.Ref AS Ref,
			|	DataProcessors.Predefined AS Predefined,
			|	DataProcessors.DeletionMark AS DeletionMark,
			|	DataProcessors.IsFolder AS IsFolder,
			|	DataProcessors.IsExternal AS IsExternal,
			|	DataProcessors.Code AS Code,
			|	DataProcessors.Description AS Description,
			|	DataProcessors.Processing AS Processing,
			|	DataProcessors.Parent AS Parent
			|FROM
			|	Catalog.DataProcessors AS DataProcessors
			|
			|ORDER BY
			|	IsFolder,
			|	Code";
			vResult = vQry.Execute().Unload();
			For Each vRow In vResult Do
				vObj = vRow.Ref.GetObject();
				If vObj <> Undefined Then
					vObj.Delete();
				EndIf;
			EndDo;
			
			// Read all data processors from file
			vXMLReader = New XMLReader();
			vXMLReader.OpenFile(vTempFileName);
			While vXMLReader.Read() Do
				If vXMLReader.NodeType = XMLNodeType.StartElement Then
					If vXMLReader.Name = "htl:DataProcessorObject" Then
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
		BeginInstallFileSystemExtension(New NotifyDescription("ExportAllToXMLFileFileSystemExtensionInstallCompleted", ThisObject, pParam));
	EndIf;
EndProcedure // LoadFromFileAttachingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure ExportAllToXMLFileFileSystemExtensionInstallCompleted(pParam) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("ExportAllToXMLFileInstallingFileSystemExtensionResult", ThisObject, pParam));
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
	
	BeginGettingFiles(New NotifyDescription("AllFileDownloadToClientCompleted", ThisObject), vFilesArray, , False);
EndProcedure // StartTransferAllFileFromServerToClient

// --------------------------------------------------------------------------------
&AtClient 
Procedure AllFileDownloadToClientCompleted(pFilesArray, pParam) Export
	If pFilesArray <> Undefined Then
		// Show result message
		ShowMessageBox(, NStr("en='All database data processors were exported to the file successfully!';ru='Все обработки базы данных были успешно сохранены в файл!';de='Alle Datenbankdatenprozessoren wurden erfolgreich in die Datei exportiert!'"));
	EndIf;
EndProcedure // AllsFileDownloadToClientCompleted

// --------------------------------------------------------------------------------
&AtClient 
Procedure OpenFileDialogToSaveFile()
	vFileSave = New FileDialog(FileDialogMode.Save);
	vFileSave.FullFileName = "1CHotelDataProcessors.xml";
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

#Region LoadAllFromFile

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFromXMLFileAttachingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		OpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension is being installing on your browser...'; ru='В браузер устанавливается расширение по работе с файлами...'; de='Dateisystemerweiterung wird in Ihrem Browser installiert...'"), MessageStatus.Information);
		BeginInstallFileSystemExtension(New NotifyDescription("LoadFromXMLFileFileSystemExtensionInstallCompleted", ThisObject, pParam));
	EndIf;
EndProcedure // LoadFromXMLFileAttachingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFromXMLFileFileSystemExtensionInstallCompleted(pParam) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadFromXMLFileInstallingFileSystemExtensionResult", ThisObject, pParam));
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
	vFileOpen.Show(New NotifyDescription("OpenFileDialogToChooseFileCompleted", ThisObject));
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
	BeginPuttingFiles(New NotifyDescription("TransferFileFromClientToServerCompleted", ThisObject), vFilesArray, , False);
EndProcedure // StartTransferFileFromClientToServer

// --------------------------------------------------------------------------------
&AtClient
Procedure TransferFileFromClientToServerCompleted(pTransferredFiles, pParam) Export
	vTempStorageFileAddressAtServer = pTransferredFiles.Get(0).Location;
	LoadFileAtServer(vTempStorageFileAddressAtServer);
	
	Items.List.Refresh();
	Items.Tree.Refresh();
	
	ShowMessageBox(, NStr("en='All database data processors were loaded from the file successfully!';ru='Все обработки базы данных были успешно восстановлены из файла!';de='Alle Datenbankdatenprozessoren wurden erfolgreich aus der Datei geladen!'"), 5);
EndProcedure // TransferFileFromClientToServerCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure ListOnChange(pItem)
	Items.List.Refresh();
	Items.Tree.Refresh();
EndProcedure

#EndRegion

#EndRegion
