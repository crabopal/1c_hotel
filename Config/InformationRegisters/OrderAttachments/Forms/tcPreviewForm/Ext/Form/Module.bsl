
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If ValueIsFilled(Parameters.Filter.Order) Then
		SelOrder = Parameters.Filter.Order;
	EndIf;

	If Not ValueIsFilled(SelOrder) Then
		pCancel = True;
		Return;
	EndIf;
	
	Title = TrimAll(SelOrder);
	
	HTML = StrReplace(StrReplace(InformationRegisters.OrderAttachments.GetTemplate("HTML").GetText(), "[CSS]", InformationRegisters.OrderAttachments.GetTemplate("CSS").GetText()), "[JavaScript]", InformationRegisters.OrderAttachments.GetTemplate("JavaScript").GetText());
	HTML = StrReplace(HTML, "[JQuery]", GetCommonTemplate("JQuery").GetText());	
	FillOrderAttachments();	
EndProcedure //  OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure HTMLDocumentComplete(pItem)  
	If Not IsBlankString(HTML) Then
		If OrderAttachments.Count() > 0 Then
			DrawOrderAttachments(GetJSONOrderAttachments());		
		EndIf; 
	Else
		RefreshAtServer();	
	EndIf;
EndProcedure //  HTMLDocumentComplete

// --------------------------------------------------------------------------------
&AtClient
Procedure HTMLOnClick(pItem, pEventData, pStandardProcessing)
	pStandardProcessing = False;
	vElement = pEventData.Element;

	If vElement = Undefined Then
		vElement = pEventData.Document.activeElement; 		
	EndIf;
	vHref = Right(pEventData.Href, StrLen(pEventData.Href) - StrFind(pEventData.Href, "/", SearchDirection.FromEnd));
	If ValueIsFilled(vHref) Then
		vOrderAttachmentsArr = OrderAttachments.FindRows(New Structure("UUID", vHref));
		If vOrderAttachmentsArr.Count() > 0 Then
			If pEventData.Element.name = "DeleteFile" Then
				DeleteRecord(vOrderAttachmentsArr[0].Date)
			ElsIf pEventData.Element.name = "Settings" Then
				vRecStructure = New Structure("Period, Order", vOrderAttachmentsArr[0].Date, SelOrder);
				vRecStructArr = New Array;
				vRecStructArr.Add(vRecStructure);
				vRecKey = New ("InformationRegisterRecordKey.OrderAttachments", vRecStructArr);
				vFormParameters = New Structure("Key", vRecKey);
				OpenForm("InformationRegister.OrderAttachments.Form.tcRecordForm", vFormParameters, ThisObject, , , , New NotifyDescription("CallBackProcessing", ThisObject));
			Else
				vLocalFullFileName = TempFilesDir() + Trimall(vOrderAttachmentsArr[0].Description);
				vBinary = vOrderAttachmentsArr[0].ExtFile;
				vBinary.Write(vLocalFullFileName);
				BeginRunningApplication(New NotifyDescription("AfterRunApp", ThisObject, New Structure("Period, Order, LocalFullFileName", vOrderAttachmentsArr[0].Date, SelOrder, vLocalFullFileName)), vLocalFullFileName, TempFilesDir(), True);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // HTMLOnClick

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure AddNewRecord(pCommand)
	vFormParameters = New Structure("Order", ThisObject.SelOrder);
	OpenForm("InformationRegister.OrderAttachments.Form.tcRecordForm", vFormParameters, ThisObject, , , , New NotifyDescription("CallBackProcessing", ThisObject)); 
EndProcedure // AddNewRecord

// --------------------------------------------------------------------------------
&AtClient
Procedure PrintHTML(pCommand)
	Items.HTML.Document.execCommand("Print", False);
EndProcedure // PrintHTML

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure FillOrderAttachments()
	vLanguage = SessionParameters.CurrentLanguage;
	vQuery = New Query;
	vQuery.text =
	"SELECT
	|	OrderAttachments.ExtFilePreview AS ScanPicture,
	|	OrderAttachments.Author AS Author,
	|	OrderAttachments.FileName AS FileName,
	|	OrderAttachments.Remarks AS Remarks,
	|	OrderAttachments.Author.Hotel AS Hotel,
	|	OrderAttachments.ExtFile AS ExtFile,
	|	OrderAttachments.Period AS Period
	|FROM
	|	InformationRegister.OrderAttachments AS OrderAttachments
	|WHERE
	|	OrderAttachments.Order = &qOrder"; 
	vQuery.SetParameter("qOrder", SelOrder);
	vResult = vQuery.Execute().Unload();
	For Each vRow In vResult Do 
		vScanPicture = vRow.ScanPicture.Get();
		vNewRow = OrderAttachments.Add();
		If vScanPicture <> Undefined Then 
			FillPropertyValues(vNewRow, vRow,, "ScanPicture");
			If TypeOf(vScanPicture) = Type("BinaryData") Then
				vNewRow.ScanPicture = New Picture(vScanPicture);
			ElsIf TypeOf(vScanPicture) = Type("Picture") Then
			EndIf;
		EndIf;
		vNewRow.UUID = TrimAll(New UUID());
		vNewRow.Author = vRow.Author;
		vNewRow.Description = vRow.FileName;
		vNewRow.Hotel = vRow.Hotel; 
		vNewRow.Date = vRow.Period;
		vNewRow.ExtFile = vRow.ExtFile.Get();
		vNewRow.Title = cmNStr("en='Delete';ru='Удалить';de='Löschen'", vLanguage);
		vNewRow.settings = cmNStr("en='Change';ru='Редактировать';de='Bearbeiten'", vLanguage);
		vNewRow.opentitle = cmNStr("en='Open';ru='Открыть';de='Offen'", vLanguage);
	EndDo;
EndProcedure // FillOrderAttachments

// --------------------------------------------------------------------------------
&AtClient
Function GetPictureIsBase64HTMLString(pPicture)
	Return StrTemplate("data:image/%1;base64,%2", GetImageType(pPicture.Format()), StrReplace(Base64String(pPicture.GetBinaryData()), Chars.CR + Chars.LF, ""));	
EndFunction // GetPictureIsBase64HTMLString

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
		Return "png";		
	EndIf;
EndFunction //  GetImageType 

// --------------------------------------------------------------------------------
&AtClient
Function MapToJSON(pMap)
	#IF NOT WebClient THEN
		vJSONWriter = New JSONWriter;
		vJSONWriter.SetString();
		WriteJSON(vJSONWriter, pMap);
		Return vJSONWriter.Close();	
	#ELSE
		Return "";	
	#ENDIF
EndFunction //  MapToJSON

// --------------------------------------------------------------------------------
&AtClient
Function GetJSONOrderAttachments()
	vOrderAttachmentsArr = New Array;
	For Each vRow In OrderAttachments Do
		vOrderAttachmentsArr.Add(New Structure("UUID, name, img, author, date, hotel, title, settings, opentitle", 
		TrimAll(vRow.UUID), ?(ValueIsFilled(TrimAll(vRow.Description)), TrimAll(vRow.Description), TrimAll(vRow.ScanConfiguration)), ?(vRow.ScanPicture.Type <> PictureType.Empty, GetPictureIsBase64HTMLString(vRow.ScanPicture), Undefined),
		TrimAll(vRow.Author), Format(vRow.Date, "DF='dd.MM.yyyy HH:mm:ss'"), TrimAll(vRow.Hotel), TrimAll(vRow.title), TrimAll(vRow.settings), TrimAll(vRow.opentitle)));			
	EndDo;	                                                                                                                                 
	Return MapToJSON(vOrderAttachmentsArr);
EndFunction //  GetJSONOrderAttachments

// --------------------------------------------------------------------------------
&AtClient
Procedure DrawOrderAttachments(pJson)
	GetHTMLDocument(Items.HTML.Document).addJSOrderAttachments(pJson);	
EndProcedure //  DrawOperations

// --------------------------------------------------------------------------------
&AtClient
Function GetHTMLDocument(pDocument)
	vDoc = pDocument.parentWindow;
	If vDoc = Undefined Then
		vDoc = pDocument.defaultView;	
	EndIf;
	Return vDoc;
EndFunction //  GetHTMLDocument

// --------------------------------------------------------------------------------
&AtServer
Procedure RefreshAtServer()
	HTML = StrReplace(StrReplace(InformationRegisters.OrderAttachments.GetTemplate("HTML").GetText(), "[CSS]", InformationRegisters.OrderAttachments.GetTemplate("CSS").GetText()), "[JavaScript]", InformationRegisters.OrderAttachments.GetTemplate("JavaScript").GetText());
	HTML = StrReplace(HTML, "[JQuery]", GetCommonTemplate("JQuery").GetText());
EndProcedure // RefreshAtServer
// --------------------------------------------------------------------------------
&AtClient
Procedure AfterRunApp(pResult, pParams) Export
	Try
		// If file is editable then ask user to save it back
		vFile = New File(pParams.LocalFullFileName);
		If IsFileEditable(vFile.Extension) Then
			ShowQueryBox(New NotifyDescription("AfterClosedQueryBox", ThisObject, pParams),
			             NStr("en = 'Save document changes to the database?'; de = 'Das geänderte Dokument in der Datenbank speichern?'; ru = 'Сохранить измененный документ в базу данных?'"), 
						 QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
		EndIf;
	Except
		ShowMessageBox(, ErrorDescription());
	EndTry;	
EndProcedure // AfterRunApp 

// --------------------------------------------------------------------------------
&AtServerNoContext
Function IsFileEditable(pExtension)
	Return cmIsFileEditable(pExtension);
EndFunction // IsFileEditable

// --------------------------------------------------------------------------------
&AtClient
Procedure CallBackProcessing(Answer, AdditionalParameters) Export
	OrderAttachments.Clear();
	FillOrderAttachments();
	HTML = "";
EndProcedure // CallBackProcessing

// --------------------------------------------------------------------------------
&AtServer
Procedure DeleteRecord(pPeriod)
	vRecSet = InformationRegisters.OrderAttachments.CreateRecordSet();
	vRecSet.Filter.Order.Value = SelOrder;
	vRecSet.Filter.Period.Value = pPeriod;
	vRecSet.Filter.Period.Use = True;
	vRecSet.Read();
	vRecSet.Clear();
	vRecSet.Write(True);
	
	OrderAttachments.Clear();
	FillOrderAttachments();
	HTML = "";	
EndProcedure // DeleteRecord

// --------------------------------------------------------------------------------
&AtServer
Procedure AfterClosedQueryBoxAtServer(pParams, pBinaryData)
	vRecord = InformationRegisters.OrderAttachments.CreateRecordManager();
	vRecord.Period = pParams.Period;
	vRecord.Order = pParams.Order;
	vRecord.Read();
	If vRecord.Selected() Then
		vRecord.ExtFile = New ValueStorage(pBinaryData);
		vRecord.FileLastChangeTime = CurrentSessionDate();
		vRecord.Write(True);
	EndIf;
	OrderAttachments.Clear();
	FillOrderAttachments();
	HTML = "";
EndProcedure // AfterClosedQueryBoxAtServer 

// --------------------------------------------------------------------------------
&AtClient
Procedure AfterClosedQueryBox(pResult, pParams) Export 
	If pResult = DialogReturnCode.Yes Then
		#If WebClient Or ThinClient Or MobileClient Then
			vFile = New File(pParams.LocalFullFileName);
			vFilesArray = New Array();
			vFileDescription = New TransferableFileDescription(pParams.LocalFullFileName);
			vFilesArray.Add(vFileDescription);
			BeginPuttingFiles(New NotifyDescription("UpdatedFileDownloadToServerCompleted", ThisObject, pParams), vFilesArray, , False);
		#Else
			vBinary = New BinaryData(pParams.LocalFullFileName);
			AfterClosedQueryBoxAtServer(pParams, vBinary);
		#EndIf
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure UpdatedFileDownloadToServerCompletedAtServer(pTempStorageFileAddress, pParam)
	vBinaryData = GetFromTempStorage(pTempStorageFileAddress);
	AfterClosedQueryBoxAtServer(pParam, vBinaryData);
EndProcedure // UpdatedFileDownloadToServerCompletedAtServer

// --------------------------------------------------------------------------------
&AtClient 
Procedure UpdatedFileDownloadToServerCompleted(pTransferredFiles, pParam) Export
	vTempStorageFileAddress = pTransferredFiles.Get(0).Location;
	UpdatedFileDownloadToServerCompletedAtServer(vTempStorageFileAddress, pParam);
EndProcedure // UpdatedFileDownloadToServerCompleted

#EndRegion