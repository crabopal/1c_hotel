
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	FillRegionsList();
	ShowRegionsList();
	FillFiles("");
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SourceRegionsListSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	ActionAddSelectedRegionsAtServer();
EndProcedure // SourceRegionsListSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure LoadRegionsListSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	ActionDeleteSelectedRegionsAtServer();
EndProcedure // LoadRegionsListSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure AddressClassifierFileStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	BeginAttachingFileSystemExtension(New NotifyDescription("AddressClassifierFileAttachingFileSystemExtensionResult", ThisForm));
EndProcedure // AddressClassifierFileStartChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure StreetsClassifierFileStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	BeginAttachingFileSystemExtension(New NotifyDescription("StreetsClassifierFileAttachingFileSystemExtensionResult", ThisForm));
EndProcedure //  StreetsClassifierFileStartChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure AbbreviationsClassifierFileStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	BeginAttachingFileSystemExtension(New NotifyDescription("AbbreviationsClassifierFileAttachingFileSystemExtensionResult", ThisForm));
EndProcedure //  AbbreviationsClassifierFileStartChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure AddressClassifierFileOnChange(pItem)
	AddressClassifierFileOnChangeAtServer();
EndProcedure // AddressClassifierFileOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure AbbreviationsClassifierFileOnChange(Item)
	AbbreviationsClassifierFileOnChangeAtServer();
EndProcedure // AbbreviationsClassifierFileOnChange

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionAddAllRegions(pCommand)
	ActionAddAllRegionsAtServer();
EndProcedure // ActionAddAllRegions

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionDeleteAllRegions(pCommand)
	ActionDeleteAllRegionsAtServer();
EndProcedure // ActionDeleteAllRegions

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionAddSelectedRegions(pCommand)
	ActionAddSelectedRegionsAtServer();
EndProcedure // ActionAddSelectedRegions

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionDeleteSelectedRegions(pCommand)
	ActionDeleteSelectedRegionsAtServer();
EndProcedure // ActionDeleteSelectedRegions

// -----------------------------------------------------------------------------
&AtServer
Function GetFilePathAtServer(pTempStorageAddress, pFileName)
	vTempFilePath = TempFilesDir() + pFileName;
	vTempFile = New File(vTempFilePath);
	If vTempFile.Exists() Then
		DeleteFiles(vTempFilePath);
	EndIf;
	vFileBinaryData = GetFromTempStorage(pTempStorageAddress);
	vFileBinaryData.Write(vTempFilePath);
	Return vTempFilePath;
EndFunction // GetFilePathAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure ActionsExecute(pCommand)
	vCheckFile = True;
	If IsBlankString(AddressClassifierFile)Then
		vCheckFile = False;
	EndIf;
	If IsBlankString(StreetsClassifierFile)Then
		vCheckFile = False;
	EndIf;
	If IsBlankString(AbbreviationsClassifierFile)Then
		vCheckFile = False;
	EndIf;
	If Not CheckNullRegions() Then 
		ShowMessageBox(,NStr("ru = 'Необходимо отметить хотя бы один регион для загрузки!'; en = 'Choose at least one region to load classifiers for!'; de = 'Choose at least one region to load classifiers for!'"));
	ElsIf Not vCheckFile  Then 
		ShowMessageBox(,NStr("ru = 'Необходимо указать путь ко всем файлам!'; en = 'You must specify the path to all files!'; de = 'Sie müssen den Pfad zu allen Dateien angeben!'"));
	Else
		vAddressClassifierFileAtServer = "";
		vAddressClassifierFile = New File(AddressClassifierFile);
		If vAddressClassifierFile.Exists() Then
			vAddressClassifierFileBinData = New BinaryData(AddressClassifierFile);
			vAddressClassifierFileAtServer = GetFilePathAtServer(PutToTempStorage(vAddressClassifierFileBinData, ThisForm.UUID), vAddressClassifierFile.Name);
		Else
			Raise NStr("en='Address classifier file is not found in directory specified!'; 
			           |ru='Файл классификатора адресов не найден в указанном каталоге!'; 
					   |de='Adressklassifizierungsdatei wurde im angegebenen Verzeichnis nicht gefunden!'");
		EndIf;

		vStreetsClassifierFileAtServer = "";
		vStreetsClassifierFile = New File(StreetsClassifierFile);
		If vStreetsClassifierFile.Exists() Then
			vStreetsClassifierFileBinData = New BinaryData(StreetsClassifierFile);
			vStreetsClassifierFileAtServer = GetFilePathAtServer(PutToTempStorage(vStreetsClassifierFileBinData, ThisForm.UUID), vStreetsClassifierFile.Name);
		Else
			Raise NStr("en='Streets classifier file is not found in directory specified!'; 
			           |ru='Файл классификатора улиц не найден в указанном каталоге!'; 
					   |de='Die Straßenklassifizierungsdatei wurde im angegebenen Verzeichnis nicht gefunden!'");
		EndIf;

		vAbbreviationsClassifierFileAtServer = "";
		vAbbreviationsClassifierFile = New File(AbbreviationsClassifierFile);
		If vAbbreviationsClassifierFile.Exists() Then
			vAbbreviationsClassifierFileBinData = New BinaryData(AbbreviationsClassifierFile);
			vAbbreviationsClassifierFileAtServer = GetFilePathAtServer(PutToTempStorage(vAbbreviationsClassifierFileBinData, ThisForm.UUID), vAbbreviationsClassifierFile.Name);
		Else
			Raise NStr("en='Abbreviations classifier file is not found in directory specified!'; 
			           |ru='Файл классификатора сокращений не найден в указанном каталоге!'; 
					   |de='Abkürzungen Klassifikatordatei wird im angegebenen Verzeichnis nicht gefunden!'");
		EndIf;
		
		// Copy them 
		vOperationParameters = New Array;
		vOperationParameters.Add(vAddressClassifierFileAtServer);
		vOperationParameters.Add(vStreetsClassifierFileAtServer);
		vOperationParameters.Add(vAbbreviationsClassifierFileAtServer);
		vOperationParameters.Add(LoadRegionsList);
		
		StartProlongedOperation("ProlongedOperations.LoadAddressClassifierRu_LoadClassifiers", 
		                        Nstr("en = 'Loading the classifier of addresses of the Russian Federation'; 
								     |ru = 'Загрузка классификатора адресов Российской Федерации'; 
									 |de = 'Herunterladen des adressenklassifikators der Russischen Föderation'"), 
								vOperationParameters);
	EndIf;
EndProcedure // ActionsExecute

#EndRegion  

#Region Public

// -----------------------------------------------------------------------------
// Functions to work with russian address codes
// Mask  RR AAA CCCCCC SSSS HHHH FFFF AA
//
//        RR     - region code
//        AAA    - area code
//        CCCCCC - city code
//        SSSS   - street code
//        HHHH   - house code
//        FFFF   - flat code
//        AA     - actuality code
// -----------------------------------------------------------------------------
&AtServer
Function RegionMask() Export
	Return 100000000000000000000000;
EndFunction // RegionMask

// -----------------------------------------------------------------------------
&AtServer
Function AreaMask() Export
	Return 100000000000000000000;
EndFunction // AreaMask

// -----------------------------------------------------------------------------
&AtServer
Function CityMask() Export
	Return 100000000000000;
EndFunction // CityMask

// -----------------------------------------------------------------------------
&AtServer
Function StreetMask() Export
	Return 10000000000;
EndFunction // StreetMask

// -----------------------------------------------------------------------------
&AtServer
Function HouseMask() Export
	Return 1000000;
EndFunction // HouseMask

// -----------------------------------------------------------------------------
&AtServer
Function FlatMask() Export
	Return 100;
EndFunction // FlatMask

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure FillRegionsList()
	RegionsList.Clear();
	vRegionsList = DataProcessors.LoadAddressClassifierRu.GetTemplate("RegionsListRu");
	For i = 2 To vRegionsList.TableHeight Do
		vRegionCode = Number(vRegionsList.Area(i, 1, i, 1).Text);
		vRegionCode = Int(vRegionCode/RegionMask());
		
		vRegionDescription = TrimAll(vRegionsList.Area(i, 2, i, 2).Text);
		vRegionAbbreviation = TrimAll(vRegionsList.Area(i, 3, i, 3).Text);
		
		RegionsList.Add(vRegionCode,  Format(vRegionCode, "ND=2; NLZ=") + " " + vRegionDescription + " " + vRegionAbbreviation, False);
	EndDo;
EndProcedure // FillRegionsList

// -----------------------------------------------------------------------------
&AtServer
Procedure ShowRegionsList()
	SourceRegionsList = new ValueList();
	LoadRegionsList = new ValueList();
	
	For Each vItem In RegionsList Do
		If vItem.Check Then
			vRegionItem = LoadRegionsList.Add(vItem.Value,vItem.Presentation,vItem.Check);
		Else
			vRegionItem = SourceRegionsList.Add(vItem.Value,vItem.Presentation,vItem.Check);
		EndIf;
	EndDo;
EndProcedure // ShowRegionsList

// -----------------------------------------------------------------------------
&AtServer
Procedure FillFiles(pFileName)
	If Not IsBlankString(pFileName) Then
		vStr = SwapString(pFileName);
		vPos = Find(vStr, "\");
		If vPos > 0 Then
			vDir = SwapString(Mid(vStr, vPos + 1));
		
			vAddressClassifierFile = vDir + "\kladr.dbf";
			vStreetsClassifierFile = vDir + "\street.dbf";
			vAbbreviationsClassifierFile = vDir + "\socrbase.dbf";
			
			If IsBlankString(AddressClassifierFile) Then
				AddressClassifierFile = vAddressClassifierFile;
			EndIf;
			
			If IsBlankString(StreetsClassifierFile) Then
				StreetsClassifierFile = vStreetsClassifierFile;
			EndIf;
			
			If IsBlankString(AbbreviationsClassifierFile) Then
				AbbreviationsClassifierFile = vAbbreviationsClassifierFile;
			EndIf;
		EndIf;
	EndIf;
	
	Items.AddressClassifierFile.ToolTip = GetClassifierFileMessage(1, AddressClassifierFile);
	Items.StreetsClassifierFile.ToolTip = GetClassifierFileMessage(2, StreetsClassifierFile);
	Items.AbbreviationsClassifierFile.ToolTip = GetClassifierFileMessage(4, AbbreviationsClassifierFile);
EndProcedure // FillFiles

// -----------------------------------------------------------------------------
&AtServer
Function SwapString(pStr)
	vStr = "";
	vStrLen = StrLen(pStr);
	
	For i = 1 To vStrLen Do
	     vStr = vStr + Mid(pStr, vStrLen - i + 1, 1);
	EndDo;
	
	Return vStr;
EndFunction // SwapString

// -----------------------------------------------------------------------------
&AtServer
Function GetClassifierFileMessage(pLevel, pFileName)
	If Not FileExists(pFileName) Then
		Return NStr("ru = 'Не обнаружен файл с классификатором!'; en = 'No classifier file found!'; de = 'No classifier file found!'");
	EndIf;
	
	If Not ThisIsXBaseFile(pFileName) Then
		Return NStr("ru = 'Указанный файл не является файлом формата dBase!'; en = 'File is not of the dBase format!'; de = 'File is not of the dBase format!'");
	EndIf;
	
	vFormatString = NStr("ru = ' в формате КЛАДР 4.0. '; en = ' in the KLADR 4.0 format '; de = ' in den KLADR 4.0 Format'");
	
	vClassifierName = "";
	If pLevel = 1 Then
		vClassifierName = NStr("ru = 'Классификатор адресов'; en = 'Address classifier'; de = 'Address classifier'");
	ElsIf pLevel = 2 Then
		vClassifierName = NStr("ru = 'Классификатор улиц'; en = 'Streets classifier'; de = 'Streets classifier'");
	ElsIf pLevel = 4 Then
		vClassifierName = NStr("ru = 'Классификатор сокращений'; en = 'Abbreviations classifier'; de = 'Abbreviations classifier'");
	Else
		Return NStr("ru = 'Неизвестный классификатор!'; en = 'Unknown classifier!'; de = 'Unknown classifier!'");
	EndIf;
	
	Return vClassifierName + vFormatString + NStr("ru = ' (кодировка '; en = ' (encoding '; de = ' (encoding '") + XBaseEncoding.OEM + ")";
EndFunction // GetClassifierFileMessage

// -----------------------------------------------------------------------------
&AtServer
Function FileExists(pFileName)
	vFile = New File(pFileName);
	Return tcCommonFunctionOnClientServer.cmExists(vFile);
EndFunction // FileExists

// -----------------------------------------------------------------------------
&AtServer
Function ThisIsXBaseFile(pFileName)
	vDB = New XBase(pFileName,, True);
	vRes = vDB.IsOpen();
	vDB.CloseFile();
	Return vRes;
EndFunction // ThisIsXBaseFile

// --------------------------------------------------------------------------------
&AtClient
Procedure AddressClassifierFileAttachingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		AddressClassifierFileOpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension is being installing on your browser...'; ru='В браузер устанавливается расширение по работе с файлами...'; de='Dateisystemerweiterung wird in Ihrem Browser installiert...'"), MessageStatus.Information);
		BeginInstallFileSystemExtension(New NotifyDescription("AddressClassifierFileFileSystemExtensionInstallCompleted", ThisForm));
	EndIf;
EndProcedure // AddressClassifierFileAttachingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure AddressClassifierFileFileSystemExtensionInstallCompleted(pParam) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("AddressClassifierFileInstallingFileSystemExtensionResult", ThisForm));
EndProcedure // AddressClassifierFileFileSystemExtensionInstallCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure AddressClassifierFileInstallingFileSystemExtensionResult(pResult, pParam) Export 
	If pResult Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension was successfully installed on your browser!'; ru='В браузер успешно установлено расширение по работе с файлами!'; de='Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'"), MessageStatus.Information);
		AddressClassifierFileOpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Your browser does not support file operations in 1C!'; ru='Браузер не поддерживает работу с файлами в 1С!'; de='Ihr Browser unterstützt keine Dateioperationen in 1C!'"), MessageStatus.Attention);
	EndIf;
EndProcedure // AddressClassifierFileInstallingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient 
Procedure AddressClassifierFileOpenFileDialogToChooseFile()
	vFindFile = New FileDialog(FileDialogMode.Open);
	vFindFile.Filter = NStr("ru = 'Файл базы данных (*.dbf)|*.dbf'; en = 'Database file (*.dbf)|*.dbf'; de = 'Database file (*.dbf)|*.dbf'");
	vFindFile.FullFileName = AddressClassifierFile;
	vFindFile.CheckFileExist = True;
	vFindFile.Show(New NotifyDescription("AddressClassifierFileOpenFileDialogToChooseFileCompleted", ThisForm));
EndProcedure // AddressClassifierFileOpenFileDialogToChooseFile

// --------------------------------------------------------------------------------
&AtClient
Procedure AddressClassifierFileOpenFileDialogToChooseFileCompleted(pFileArray, pParam) Export 
	If ValueIsFilled(pFileArray) Then
		AddressClassifierFile = pFileArray[0];
		AddressClassifierFileOnChangeAtServer();
	EndIf;
EndProcedure // AddressClassifierFileOpenFileDialogToChooseFileCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure StreetsClassifierFileAttachingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		StreetsClassifierFileOpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension is being installing on your browser...'; ru='В браузер устанавливается расширение по работе с файлами...'; de='Dateisystemerweiterung wird in Ihrem Browser installiert...'"), MessageStatus.Information);
		BeginInstallFileSystemExtension(New NotifyDescription("StreetsClassifierFileFileSystemExtensionInstallCompleted", ThisForm));
	EndIf;
EndProcedure // StreetsClassifierFileAttachingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure StreetsClassifierFileFileSystemExtensionInstallCompleted(pParam) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("StreetsClassifierFileInstallingFileSystemExtensionResult", ThisForm));
EndProcedure // StreetsClassifierFileFileSystemExtensionInstallCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure StreetsClassifierFileInstallingFileSystemExtensionResult(pResult, pParam) Export 
	If pResult Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension was successfully installed on your browser!'; ru='В браузер успешно установлено расширение по работе с файлами!'; de='Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'"), MessageStatus.Information);
		StreetsClassifierFileOpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Your browser does not support file operations in 1C!'; ru='Браузер не поддерживает работу с файлами в 1С!'; de='Ihr Browser unterstützt keine Dateioperationen in 1C!'"), MessageStatus.Attention);
	EndIf;
EndProcedure // StreetsClassifierFileInstallingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient 
Procedure StreetsClassifierFileOpenFileDialogToChooseFile()
	vFindFile = New FileDialog(FileDialogMode.Open);
	vFindFile.Filter = NStr("ru = 'Файл базы данных (*.dbf)|*.dbf'; en = 'Database file (*.dbf)|*.dbf'; de = 'Database file (*.dbf)|*.dbf'");
	vFindFile.FullFileName = AddressClassifierFile;
	vFindFile.CheckFileExist = True;
	vFindFile.Show(New NotifyDescription("StreetsClassifierFileOpenFileDialogToChooseFileCompleted", ThisForm));
EndProcedure // StreetsClassifierFileOpenFileDialogToChooseFile

// --------------------------------------------------------------------------------
&AtClient
Procedure StreetsClassifierFileOpenFileDialogToChooseFileCompleted(pFileArray, pParam) Export 
	If ValueIsFilled(pFileArray) Then
		StreetsClassifierFile = pFileArray[0];
		StreetsClassifierFileOnChangeAtServer();
	EndIf;
EndProcedure // StreetsClassifierFileOpenFileDialogToChooseFileCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure AbbreviationsClassifierFileAttachingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		AbbreviationsClassifierFileOpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension is being installing on your browser...'; ru='В браузер устанавливается расширение по работе с файлами...'; de='Dateisystemerweiterung wird in Ihrem Browser installiert...'"), MessageStatus.Information);
		BeginInstallFileSystemExtension(New NotifyDescription("AbbreviationsClassifierFileFileSystemExtensionInstallCompleted", ThisForm));
	EndIf;
EndProcedure // AbbreviationsClassifierFileAttachingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure AbbreviationsClassifierFileFileSystemExtensionInstallCompleted(pParam) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("AbbreviationsClassifierFileInstallingFileSystemExtensionResult", ThisForm));
EndProcedure // AbbreviationsClassifierFileFileSystemExtensionInstallCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure AbbreviationsClassifierFileInstallingFileSystemExtensionResult(pResult, pParam) Export 
	If pResult Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension was successfully installed on your browser!'; ru='В браузер успешно установлено расширение по работе с файлами!'; de='Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'"), MessageStatus.Information);
		AbbreviationsClassifierFileOpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Your browser does not support file operations in 1C!'; ru='Браузер не поддерживает работу с файлами в 1С!'; de='Ihr Browser unterstützt keine Dateioperationen in 1C!'"), MessageStatus.Attention);
	EndIf;
EndProcedure // AbbreviationsClassifierFileInstallingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient 
Procedure AbbreviationsClassifierFileOpenFileDialogToChooseFile()
	vFindFile = New FileDialog(FileDialogMode.Open);
	vFindFile.Filter = NStr("ru = 'Файл базы данных (*.dbf)|*.dbf'; en = 'Database file (*.dbf)|*.dbf'; de = 'Database file (*.dbf)|*.dbf'");
	vFindFile.FullFileName = AddressClassifierFile;
	vFindFile.CheckFileExist = True;
	vFindFile.Show(New NotifyDescription("AbbreviationsClassifierFileOpenFileDialogToChooseFileCompleted", ThisForm));
EndProcedure // AbbreviationsClassifierFileOpenFileDialogToChooseFile

// --------------------------------------------------------------------------------
&AtClient
Procedure AbbreviationsClassifierFileOpenFileDialogToChooseFileCompleted(pFileArray, pParam) Export 
	If ValueIsFilled(pFileArray) Then
		AbbreviationsClassifierFile = pFileArray[0];
		AbbreviationsClassifierFileOnChangeAtServer();
	EndIf;
EndProcedure // AbbreviationsClassifierFileOpenFileDialogToChooseFileCompleted

// --------------------------------------------------------------------------------
&AtServer
Procedure AddressClassifierFileOnChangeAtServer()
	FillFiles(AddressClassifierFile);
EndProcedure // AddressClassifierFileOnChangeAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure StreetsClassifierFileOnChangeAtServer()
	FillFiles(StreetsClassifierFile);
EndProcedure // StreetsClassifierFileOnChangeAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure StreetsClassifierFileOnChange(pItem)
	StreetsClassifierFileOnChangeAtServer();
EndProcedure // StreetsClassifierFileOnChange

// --------------------------------------------------------------------------------
&AtServer
Procedure AbbreviationsClassifierFileOnChangeAtServer()
	FillFiles(AbbreviationsClassifierFile);
EndProcedure // AbbreviationsClassifierFileOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure StartProlongedOperation(pFunctionName, pOperationName, pOperationParametrs = Undefined)	
	BlockForm_ShowProgressBar();
	Items.BackgroundOperationProgress.Title	= NStr("en = 'Background operation in progress, you can continue to work in other forms  - '; ru = 'Выполняется фоновая операция, можете продолжать работать в других формах  - '; de = 'Die Hintergrundoperation läuft, Sie können weiterhin in anderen Formen arbeiten - '") + NStr(pOperationName);
	vBackgroundJob = StartBackgroundJob(pOperationName, pFunctionName, pOperationParametrs);
	CurrentBackgroundJobUUID = vBackgroundJob.UUID;
	AttachIdleHandler("Attachable_CheckBackgroundJobs",1,False);
EndProcedure 

// --------------------------------------------------------------------------------
&AtServer
Function CheckNullRegions()
	// Load classifiers
	vLoadRegions = False;
	For Each vItem In RegionsList Do
		If vItem.Check Then
			vLoadRegions = True;
			Break;
		EndIf;
	EndDo;
	If vLoadRegions Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // ActionsExecuteAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure BlockForm_ShowProgressBar()
	BackgroundOperationProgress = 0;
	Items.BackgroundOperationProgress.Visible = True;
	ThisForm.ReadOnly = True;	
EndProcedure // BlockForm_ShowProgressBar

// -----------------------------------------------------------------------------
&AtClient
Procedure UnlockForm_HideProgressBar()
	BackgroundOperationProgress = 0;
	Items.BackgroundOperationProgress.Visible = False;
	ThisForm.ReadOnly = False;
EndProcedure // UnlockForm_HideProgressBar

// -----------------------------------------------------------------------------
&AtServer                               
Function StartBackgroundJob(pOperationName, pProcedureName, pProcedureParametrs = Undefined, pTempStorageAddress = Undefined)
	ListOfMessages = new ValueList;
	Return AsyncCalls.StartBackgroundJobWithRecordInRegister(Undefined, pOperationName, pProcedureName, pProcedureParametrs,,,pTempStorageAddress);	
EndFunction // StartBackgroundJob

// -----------------------------------------------------------------------------
&AtClient
Procedure Attachable_CheckBackgroundJobs()
	vBackgroundJob 				= CheckBackgroundJobStatus(CurrentBackgroundJobUUID);            
	BackgroundOperationProgress = vBackgroundJob.Progress; 
	
	For each msg in vBackgroundJob.Messages Do
		If ListOfMessages.FindByValue(msg) = Undefined then
			ListOfMessages.Add(msg);
			Items.BackgroundOperationProgress.Title = msg;
		EndIf;
	EndDo;
	
	If vBackgroundJob.Status = "Error" Then 
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Error in background job: '; ru = 'Ошибка выполнения фонового задания: '; de = 'Fehler beim Ausführen des Hintergrundjobs: '") + vBackgroundJob.Error);
		DetachIdleHandler("Attachable_CheckBackgroundJobs");
		UnlockForm_HideProgressBar();
	ElsIf vBackgroundJob.Status = "Canceled" Then 
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Background job - canceled.'; ru = 'Фоновое задание - отменено.'; de = 'Hintergrundjob - abgebrochen.'"));
		DetachIdleHandler("Attachable_CheckBackgroundJobs");
		UnlockForm_HideProgressBar();
	ElsIf vBackgroundJob.Status = "Completed" Then
		DetachIdleHandler("Attachable_CheckBackgroundJobs");
		tcOnServer.Wait(1);
		UnlockForm_HideProgressBar();
	EndIf;
EndProcedure // Attachable_CheckBackgroundJobs

// -----------------------------------------------------------------------------
&AtServer
Function CheckBackgroundJobStatus(pBackgroundJobId)
	Return AsyncCalls.CheckBackgroundJob(pBackgroundJobId); 
EndFunction // CheckBackgroundJobStatus

// -----------------------------------------------------------------------------
&AtServer
Procedure ActionAddAllRegionsAtServer()
	RegionsList.FillChecks(True);
	ShowRegionsList();
EndProcedure //  ActionAddAllRegionsAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ActionDeleteAllRegionsAtServer()
	RegionsList.FillChecks(False);
	ShowRegionsList();
EndProcedure // ActionDeleteAllRegionsAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ActionAddSelectedRegionsAtServer()
	vSelectedRows = Items.SourceRegionsList.SelectedRows;
	For Each vSelectedRow In vSelectedRows Do
	    vValueSelect = SourceRegionsList.FindByID(vSelectedRow);
		vItem = RegionsList.FindByValue(vValueSelect.Value);
		If vItem <> Undefined Then
			vItem.Check = True;
		EndIf;
	EndDo;
	If vSelectedRows.Count() > 0 Then
		ShowRegionsList();
	EndIf;
EndProcedure // ActionAddSelectedRegionsAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ActionDeleteSelectedRegionsAtServer()
	vSelectedRows = Items.LoadRegionsList.SelectedRows;
	For Each vSelectedRow In vSelectedRows Do
		vValueSelect = LoadRegionsList.FindByID(vSelectedRow);
		vItem = RegionsList.FindByValue(vValueSelect.Value);
		If vItem <> Undefined Then
			vItem.Check = False;
		EndIf;
	EndDo;
	If vSelectedRows.Count() > 0 Then
		ShowRegionsList();
	EndIf;
EndProcedure // ActionDeleteSelectedRegionsAtServer

#EndRegion
