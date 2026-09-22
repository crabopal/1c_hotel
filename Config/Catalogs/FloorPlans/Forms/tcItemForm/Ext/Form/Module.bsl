
#Region Variables

&AtClient
Var FloorPlan;

#EndRegion 

#Region FormEventHandlers

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Form caption
	If ValueIsFilled(Object.Description) Then
		AutoTitle = False;
		Title = cmNStr(Object.Description, SessionParameters.CurrentLanguage);
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) And Not ValueIsFilled(Object.Hotel) Then
		Object.Hotel = SessionParameters.CurrentHotel;
	EndIf;
	
	HTML = Catalogs.FloorPlans.GetTemplate("HTML").GetText();
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure HTMLOnClick(pItem, pEventData, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure // HTMLOnClick

// --------------------------------------------------------------------------------
&AtClient
Procedure HTMLDocumentComplete(pItem)
	FloorPlan = GetHTMLDocument(Items.HTML.Document).floorPlan;
	FillHTML();
EndProcedure // HTMLDocumentComplete

// --------------------------------------------------------------------------------
&AtClient
Procedure ImageInBase64OnChange(pItem = Undefined)
	Try
		If ValueIsFilled(Object.ImageInBase64) Then
			vPicture = New Picture(Base64Value(Object.ImageInBase64));
			Object.ImageWidth = vPicture.Width();
			Object.ImageHeight = vPicture.Height();
			Object.ImageType = GetImageType(vPicture.Format());
		Else
			Object.ImageWidth = 0; 
			Object.ImageHeight = 0;
			Object.ImageType = "";
		EndIf;
	Except
		tcCommonFunctionOnClientServer.TextMessage(BriefErrorDescription(ErrorInfo()));
		Object.ImageWidth = 0;
		Object.ImageHeight = 0;
		Object.ImageType = "";
	EndTry;
	FillHTML();
EndProcedure // ImageInBase64OnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure AreasOnChange(pItem)
	FillHTML();
EndProcedure // AreasOnChange

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure TestFloorPlan(pCommand)
	If Not Write() Then
		Return;
	EndIf;
	OpenForm("CommonForm.tcShowFloorPlans", New Structure("SelFloorPlan", Object.Ref));
EndProcedure // TestFloorPlan

// --------------------------------------------------------------------------------
&AtClient
Procedure UploadImage(pCommand)
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadFromFileAttachingFileSystemExtensionResult", ThisForm));
EndProcedure // UploadImage

// --------------------------------------------------------------------------------
&AtClient
Procedure SaveFile(pCommand)
	If ValueIsFilled(Object.ImageInBase64) Then
		OpenFileDialogToSaveFile();
	EndIf;
EndProcedure // SaveFile

// --------------------------------------------------------------------------------
&AtClient
Procedure ClearImage(pCommand)
	Object.ImageInBase64 = "";
	ImageInBase64OnChange();
EndProcedure // ClearImage

#EndRegion

#Region Private

// ----------------------------------------------------------------------------
&AtClient
Function GetHTMLObj(pData)
	vObj = Undefined;
	If TypeOf(pData) = Type("Structure") Or TypeOf(pData) = Type("Map") Then
		vObj = FloorPlan.createObj();
		For Each vItem In pData Do
			If TypeOf(vItem.Value) = Type("Structure") Or TypeOf(vItem.Value) = Type("Map") Or TypeOf(vItem.Value) = Type("Array") Then
				FloorPlan.setToObj(vObj, vItem.Key, GetHTMLObj(vItem.Value));
			Else
				FloorPlan.setToObj(vObj, vItem.Key, vItem.Value);
			EndIf;
		EndDo;
	ElsIf TypeOf(pData) = Type("Array") Then
		vObj = FloorPlan.createArr();
		For Each vItem In pData Do
			If TypeOf(vItem) = Type("Structure") Or TypeOf(vItem) = Type("Map") Or TypeOf(vItem) = Type("Array") Then
				FloorPlan.setToArr(vObj, GetHTMLObj(vItem));
			Else
				FloorPlan.setToArr(vObj, vItem);
			EndIf;
		EndDo;
	EndIf;
	Return vObj;
EndFunction // getHTMLObj

// -----------------------------------------------------------------------------
&AtClient
Procedure FillHTMLAttach() Export
	FillHTML(True);
EndProcedure // PrintFloorPlanAttach

// --------------------------------------------------------------------------------
&AtClient
Procedure FillHTML(pAttach = False)
	If Not pAttach Then
		FloorPlan.unbindMap();
		If Not ValueIsFilled(Object.ImageInBase64) Then
			Return;
		EndIf;
		
		FloorPlan.setImg(StrTemplate("data:image/%1;base64, %2", ?(IsBlankString(Object.ImageType), "png", Object.ImageType), Object.ImageInBase64));
		FloorPlan.setMap(Object.Areas);
		FloorPlan.buildMap();
		AttachIdleHandler("FillHTMLAttach", 0.1, True);
	EndIf;
	
	vTDArr = FloorPlan.document.querySelectorAll("area");
	vData = New Map;
	For Each vRow In vTDArr Do
		vRoom = vRow.getAttribute("state");
		vDataStr = New Structure;
		vDataStr.Insert("occupied", Undefined);
		vDataStr.Insert("status", "");
		vDataStr.Insert("room", TrimAll(vRoom));
		vDataStr.Insert("color", "ccff99");
		vData.Insert(TrimAll(vRoom), vDataStr);
	EndDo;
	FloorPlan.setData(GetHTMLObj(vData), False);
EndProcedure // FillHTML

// -----------------------------------------------------------------------------
&AtClient
Function GetHTMLDocument(pDocument)
	vDoc = pDocument.parentWindow;
	If vDoc = Undefined Then
		vDoc = pDocument.defaultView;
	EndIf;
	Return vDoc;
EndFunction // GetHTMLDocument

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
	vFileOpen = New FileDialog(FileDialogMode.Open);
	vFileOpen.Filter = NStr("ru = 'Картинки (*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf)|*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf|" +
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
	vFileOpen.Multiselect = False;
	vFileOpen.Title = NStr("en='Open file';ru='Открыть файл';de='Datei öffnen'");
	vFileOpen.Preview = True;
	vFileOpen.Show(New NotifyDescription("OpenFileDialogToChooseFileCompleted", ThisForm));
EndProcedure // OpenFileDialogToChooseFile

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileDialogToChooseFileCompleted(pFileArray, pParam) Export 
	If ValueIsFilled(pFileArray) Then
		Object.ImageInBase64 = Base64String(New BinaryData(pFileArray[0]));
		ImageInBase64OnChange();
	EndIf;
EndProcedure // OpenFileDialogToChooseFileCompleted

// --------------------------------------------------------------------------------
&AtClient 
Procedure OpenFileDialogToSaveFile()
	vFileSave = New FileDialog(FileDialogMode.Save);
	vFileSave.Filter = StrTemplate(NStr("ru = 'Изображение (*%1)|*%1;|'; 
	                        			|de = 'Bild (*%1)|*%1;|'; 
	                        			|en = 'Image (*%1)|*%1;|'"), GetIMGType());
	vFileSave.Multiselect = False;
	vFileSave.Title = NStr("en = 'Save file'; de = 'Datei speichern'; ru = 'Сохранить файл'");
	vFileSave.CheckFileExist = True;
	vFileSave.Show(New NotifyDescription("OpenFileDialogToSaveFileCompleted", ThisForm));
EndProcedure // OpenFileDialogToSaveFile

// --------------------------------------------------------------------------------
&AtClient
Function GetIMGType()
	If Object.ImageType = "png" Then
		Return ".png";
	ElsIf Object.ImageType = "jpeg" Then
		Return ".jpg";
	ElsIf Object.ImageType = "svg+xml" Then
		Return ".svg";
	ElsIf Object.ImageType = "gif" Then
		Return ".gif";
	ElsIf Object.ImageType = "bmp" Then
		Return ".bmp";
	Else
		Return "";
	EndIf;
EndFunction // GetIMGType

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileDialogToSaveFileCompleted(pFileArray, pParam) Export 
	If ValueIsFilled(pFileArray) Then
		vFileBinaryData = Base64Value(Object.ImageInBase64);
		If TypeOf(vFileBinaryData) = Type("BinaryData") Then
			vFileBinaryData.BeginWrite(New NotifyDescription("SaveFileAfterWrite", ThisForm), pFileArray[0]);
		EndIf;
	EndIf;
EndProcedure // OpenFileDialogToSaveFileCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure SaveFileAfterWrite(pExtraParams) Export
	ShowMessageBox(, NStr("en='Success!'; ru='Успешно!'; de='Erfolg!'"), 3);
EndProcedure // SaveFileAfterWrite

// --------------------------------------------------------------------------------
&AtClient
Function GetImageType(pFormat)
	If pFormat = PictureFormat.PNG Then
		Return "png";
	ElsIf pFormat = PictureFormat.JPEG Then
		Return "jpeg";
	ElsIf pFormat = PictureFormat.SVG Then
		Return "svg+xml";
	ElsIf pFormat = PictureFormat.GIF Then
		Return "gif";
	ElsIf pFormat = PictureFormat.BMP Then
		Return "bmp";
	Else
		Return "";
	EndIf;
EndFunction // GetImageType

#EndRegion



