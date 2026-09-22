
#Region Public

// -----------------------------------------------------------------------------
// 
// Returns:
//  Structure - Empty params for load files
//
Function cmGetEmptyParamsForLoadFiles() Export
	vParam = new Structure();
	vParam.Insert("Form");
	vParam.Insert("Item","");
	vParam.Insert("Filter","");	
	vParam.Insert("Preview",True);
	vParam.Insert("Title","");
	vParam.Insert("FileDialogMode",FileDialogMode.Open);
	vParam.Insert("FillingValues", New Structure);
	vParam.Insert("NotifyDescription", Undefined);
	Return vParam;
EndFunction //  cmGetEmptyParamsForLoadFiles()

// -----------------------------------------------------------------------------
//
// Parameters:
//  pParams	 - Structure - Params 
//
Procedure LoadFile(pParams) Export 
	#IF WebClient THEN
		BeginAttachingFileSystemExtension(New NotifyDescription("LoadFromFileAttachingFileSystemExtensionResult", tcOnClientWorkWithFiles,pParams));
	#ELSE
		OpenFileDialogToChooseFile(pParams);
	#ENDIF
EndProcedure

// -----------------------------------------------------------------------------
//
// Parameters:
//  pFileArray	 - Array - File params
//  pParams		 - Structure - Params 
//
Procedure CommandActionLoadFromFileNotification(pFileArray, pParams) Export 
	If ValueIsFilled(pFileArray) Then
		vFullFileName = pFileArray[0];
		vFile = New File(vFullFileName);
		pParams.Insert("FileName",vFile.Name);
		pParams.Insert("FullFileName",vFullFileName);
		vFile.BeginGettingModificationTime(New NotifyDescription("LoadFileGettingModificationTimeCompleted", tcOnClientWorkWithFiles, pParams));
	EndIf;
EndProcedure // CommandActionLoadFromFileNotification

// -----------------------------------------------------------------------------
//
// Parameters:
//  pModificationTime	 - Date	 - Time
//  pParams				 - Structure - Params
//
Procedure LoadFileGettingModificationTimeCompleted(pModificationTime, pParams) Export
	pParams.Insert("Name", pParams.FileName);
	pParams.Insert("LastModificationTime", pModificationTime);
	LoadFileInWebClient(pParams.FullFileName,pParams);
EndProcedure // LoadFileGettingModificationTimeCompleted

// -----------------------------------------------------------------------------
//
// Parameters:
//  pResult	 - File - File 
//  pParams	 - Structure - Params 
//
Procedure LoadFromFileAttachingFileSystemExtensionResult(pResult, pParams) Export
	If pResult Then
		OpenFileDialogToChooseFile(pParams);
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension is being installing on your browser...'; ru='В браузер устанавливается расширение по работе с файлами...'; de='Dateisystemerweiterung wird in Ihrem Browser installiert...'"), MessageStatus.Information);
		BeginInstallFileSystemExtension(New NotifyDescription("LoadFromFileFileSystemExtensionInstallCompleted", tcOnClientWorkWithFiles, pParams));
	EndIf;
EndProcedure // LoadFromFileAttachingFileSystemExtensionResult

// -----------------------------------------------------------------------------
//
// Parameters:
//  pResult	 - File - File 
//  pParams	 - Structure - Params 
//
Procedure LoadFromFileFileSystemExtensionInstallCompleted(pResult, pParams) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadFromFileInstallingFileSystemExtensionResult", tcOnClientWorkWithFiles, pParams));
EndProcedure // LoadFromFileFileSystemExtensionInstallCompleted

// -----------------------------------------------------------------------------
//
// Parameters:
//  pResult	 - File - File 
//  pParams	 - Structure - Params 
//
Procedure LoadFromFileInstallingFileSystemExtensionResult(pResult, pParams) Export 
	If pResult Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension was successfully installed on your browser!'; ru='В браузер успешно установлено расширение по работе с файлами!'; de='Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'"), MessageStatus.Information);
		OpenFileDialogToChooseFile(pParams);
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Your browser does not support file operations in 1C!'; ru='Браузер не поддерживает работу с файлами в 1С!'; de='Ihr Browser unterstützt keine Dateioperationen in 1C!'"), MessageStatus.Attention);
	EndIf;
EndProcedure // LoadFromFileInstallingFileSystemExtensionResult

// -----------------------------------------------------------------------------
//
// Parameters:
//  pTransferredFiles	 - Array - List files
//  pParams				 - Structure - Params 
//
Procedure SaveFileToAttribute(pTransferredFiles, pParams) Export
	If pTransferredFiles <> Undefined Then
		vForm 				= pParams.Form;
		vTempStorage 		= pTransferredFiles.Get(0).Location;
		vForm[pParams.Item] = vTempStorage;
		vForm.Modified 		= True;
		If pParams.FillingValues.Count()>0 Then
			For Each vKey In  pParams.FillingValues Do
				vVal = Undefined;
				If pParams.Property(vKey.Key,vVal) Then
					vForm[vKey.Key] = vVal;
				EndIf; 
			EndDo;
			vForm.LastModificationTime = pParams.LastModificationTime;
		EndIf; 
	EndIf; 
EndProcedure

// -----------------------------------------------------------------------------
// 
// Returns:
//  String - Choose filter 
//
Function cmGetChooseFilterForAllPictures() Export 
 vFilter = NStr("ru = 'Картинки (*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf)|*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf|" +
	                               "bmp (*.bmp;*.dib;*.rle)|*.bmp;*.dib;*.rle|" + 
	                               "JPEG (*.jpg;*.jpeg)|*.jpg;*.jpeg|" + 
	                               "TIFF (*.tif)|*.tif|" + 
	                               "GIF (*.gif)|*.gif|" + 
	                               "PNG (*.png)|*.png|" + 
	                               "icon (*.ico)|*.ico|" + 
	                               "метафайл (*.wmf;*.emf)|*.wmf;*.emf|'; 
	                        |de = 'Картинки (*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf)|*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf|" +
	                               "bmp (*.bmp;*.dib;*.rle)|*.bmp;*.dib;*.rle|" + 
	                               "JPEG (*.jpg;*.jpeg)|*.jpg;*.jpeg|" + 
	                               "TIFF (*.tif)|*.tif|" + 
	                               "GIF (*.gif)|*.gif|" + 
	                               "PNG (*.png)|*.png|" + 
	                               "icon (*.ico)|*.ico|" + 
	                               "метафайл (*.wmf;*.emf)|*.wmf;*.emf|'; 
	                        |en = 'Pictures (*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf)|*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf|" +
	                               "bmp (*.bmp;*.dib;*.rle)|*.bmp;*.dib;*.rle|" + 
	                               "JPEG (*.jpg;*.jpeg)|*.jpg;*.jpeg|" + 
	                               "TIFF (*.tif)|*.tif|" + 
	                               "GIF (*.gif)|*.gif|" + 
	                               "PNG (*.png)|*.png|" + 
	                               "icon (*.ico)|*.ico|" + 
	                               "metafile (*.wmf;*.emf)|*.wmf;*.emf|'");	
 
 Return vFilter;
EndFunction	

// -----------------------------------------------------------------------------
// 
// Returns:
//  String - Choose filter 
//
Function cmGetChooseFilterAnyRef() Export 
 vFilter = NStr("ru='Все файлы (*.*)|*.*|';
	                        |de='Alle Dateien (*.*)|*.*|';
	                        |en='All files (*.*)|*.*|'");	
 
 Return vFilter;
EndFunction	

// -----------------------------------------------------------------------------
//
// Parameters:
//  pItemName	 - String	 - ItemName
//  pObject		 - Object	 - Object
//  pFile		 - String	 - File
//  pFilter		 - String	 - Filter
//
Procedure cmChooseDirectoryOnClient(pItemName, pObject, pFile = False, pFilter = "") Export
	vFileDialogMode = ?(pFile = False, FileDialogMode.ChooseDirectory, FileDialogMode.Open);
	vFileDialog 			= New FileDialog(vFileDialogMode);
	vFileDialog.Multiselect = False;
	vFileDialog.Directory	= pObject[pItemName];
	If pFile = True And Not IsBlankString(pFilter) Then
		vFilter = pFilter;
	ElsIf pFile = True Then
		vFilter = NStr("en = 'All files'; de = 'Alle Dateien'; ru = 'Все файлы'")+ " (*.*)|*.*";
	EndIf;	
	vFileDialog.Filter = vFilter;
	vFileDialog.Show(New NotifyDescription("SaveFilePathStartChoice_AfterInput", tcOnClientWorkWithFiles,New Structure("ItemName, Object",pItemName,pObject)));
EndProcedure

// -----------------------------------------------------------------------------
//
// Parameters:
//  pValue		 - File	 - Selected file 
//  pParameters	 - Structure	 - File params
//
Procedure SaveFilePathStartChoice_AfterInput(pValue, pParameters) Export
	If pValue = Undefined Then
		Return;
	EndIf;
	vObject = pParameters.Object;
	vObject[pParameters.ItemName] = pValue[0];	
EndProcedure
     
// -----------------------------------------------------------------------------
//
// Parameters:
//  pPdfFileFullName - String	 - PdfFileFullName
//  pFormUUID		 - UUID		  
// 
// Returns:
//  String  
//
Function ConvertPDFtoJPG(pPdfFileFullName, pFormUUID) Export 
	#If Not WebClient And Not MobileClient Then
		// Converter path
		vConverterPath = CommonDir();
		vFilesPath = TempFilesDir();
		If vConverterPath <> Undefined Then
			vPdfFile = New File(pPdfFileFullName);
			If tcCommonFunctionOnClientServer.cmExists(vPdfFile) Then
				vPdfFileFullName = vFilesPath + vPdfFile.Name;
				FileCopy(pPdfFileFullName, vPdfFileFullName);
				vRetCode = 0;
				RunApp("""" + vConverterPath + "szp.exe"" " + """" + vConverterPath + "pdftopng.exe"" -q " + """" + vPdfFileFullName + """ " + vPdfFile.BaseName, vFilesPath, True, vRetCode);
				If vRetCode = 0 Or vRetCode = 2 Then
					vPngFile = New File(vFilesPath + vPdfFile.BaseName + "-000001.png");
					If tcCommonFunctionOnClientServer.cmExists(vPngFile) Then
						vUsePNG = False;
						vPngFileFullName = vPngFile.FullName;
						vJpgFileFullName = vPngFile.Path + vPngFile.BaseName + ".jpg";
						Try
							vGFLAx = New COMObject("GFLAx.GFLAx");
							vGFLAx.LoadBitmap(vPngFileFullName);
							vGFLAx.SaveformatName = "jpeg";
							vGFLAx.SaveJPEGQuality = 30;
							vGFLAx.SaveBitmap(vJpgFileFullName);
							vGFLAx = Undefined;
						Except
							vUsePNG = True;
						EndTry;
						If vUsePNG Then
							vPngFileAddress = "";
							If PutFile(vPngFileAddress, vPngFileFullName, , False, pFormUUID) Then
								DeleteFiles(vPdfFileFullName);
								DeleteFiles(vPngFileFullName);
								Return vPngFileAddress;
							EndIf;
						Else
							vJpgFileAddress = "";
							If PutFile(vJpgFileAddress, vJpgFileFullName, , False, pFormUUID) Then
								DeleteFiles(vPdfFileFullName);
								DeleteFiles(vPngFileFullName);
								DeleteFiles(vJpgFileFullName);
								Return vJpgFileAddress;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;  
	#EndIf
	Return Undefined;
EndFunction // ConvertPDFtoJPG

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure OpenFileDialogToChooseFile(pParams)
	vFilter = pParams.Filter;
	vFileOpen = New FileDialog(pParams.FileDialogMode);
	If IsBlankString(vFilter) Then
		vFilter = NStr("en = 'All files'; de = 'Alle Dateien'; ru = 'Все файлы'")+ " (*.*)|*.*";
	EndIf; 
	vTitle = pParams.Title;
	If IsBlankString(vTitle) Then
		vTitle = NStr("en='Open file';ru='Открыть файл';de='Datei öffnen'");
	EndIf;
	vFileOpen.Filter = vFilter;
	vFileOpen.Multiselect = False;
	vFileOpen.Title = vTitle;
	vFileOpen.Preview = pParams.Preview; 
	vFileOpen.Show(?(pParams.NotifyDescription <> Undefined, pParams.NotifyDescription,New NotifyDescription("CommandActionLoadFromFileNotification",tcOnClientWorkWithFiles, pParams)));
EndProcedure // OpenFileDialogToChooseFile

// -----------------------------------------------------------------------------
Procedure LoadFileInWebClient(pFullFileName, pParams)
	vFilesArray = New Array();
	vFileDescription = New TransferableFileDescription(pFullFileName);
	vFilesArray.Add(vFileDescription);
	BeginPuttingFiles(New NotifyDescription("SaveFileToAttribute", tcOnClientWorkWithFiles, pParams), vFilesArray, , False, pParams.Form.UUID);
EndProcedure // LoadFileInWebClient

// -----------------------------------------------------------------------------
Function CommonDir()
	#If Not WebClient  And Not MobileClient Then
		vDir = Lower(BinDir());
		vSI = New SystemInfo();
		vAppVersion = Left(vSI.AppVersion, 3);
		If vAppVersion = "8.2" Then
			vCommonPos = Find(vDir, "\1cv82\");
			If vCommonPos > 0 Then
				vDir = Left(vDir, vCommonPos + 5) + "\common\";
			EndIf;
		Else
			vCommonPos = Find(vDir, "\1cv8\");
			If vCommonPos > 0 Then
				vDir = Left(vDir, vCommonPos + 4) + "\common\";
			EndIf;
		EndIf;
		Return vDir;
	#EndIf	
EndFunction // CommonDir

#EndRegion