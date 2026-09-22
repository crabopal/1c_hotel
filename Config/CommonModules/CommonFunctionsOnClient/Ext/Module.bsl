
#Region Public

// -----------------------------------------------------------------------------
// Description: Returns shortcut object based on shortcut text representation  
// Parameters: Text representation of the shortcut
// Return value: Shortcut object
// -----------------------------------------------------------------------------
Function cmGetShortcutObject(Val pShortcutStr) Export
	If IsBlankString(pShortcutStr) Then
		Return New Shortcut(Key.None, False, False, False);
	Else
		// Alt
		vAlt = False;
		vAltPos = Find(pShortcutStr, "Alt+");
		If vAltPos > 0 Then
			vAlt = True;
			pShortcutStr = StrReplace(pShortcutStr, "Alt+", "");
		EndIf;
		// Ctrl
		vCtrl = False;
		vCtrlPos = Find(pShortcutStr, "Ctrl+");
		If vCtrlPos > 0 Then
			vCtrl = True;
			pShortcutStr = StrReplace(pShortcutStr, "Ctrl+", "");
		EndIf;
		// Shift
		vShift = False;
		vShiftPos = Find(pShortcutStr, "Shift+");
		If vShiftPos > 0 Then
			vShift = True;
			pShortcutStr = StrReplace(pShortcutStr, "Shift+", "");
		EndIf;
		// Key
		vKey = Key[pShortcutStr];
		// Shortcut object
		Return New Shortcut(vKey, vAlt, vCtrl, vShift);
	EndIf;
EndFunction // cmGetShortcutObject 

// -----------------------------------------------------------------------------
// Description: Sets object form button captions, shortcuts and tooltips
// Parameters: Button control, Button action, Form action
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmSetButtonAttributes(pButton, pButtonAction, pFormAction) Export
	If pButtonAction = Undefined Then
		pFormAction = Catalogs.ObjectFormActions.EmptyRef();
		pButton.Enabled = False;
		pButton.Visible = False;
	Else
		pFormAction = pButtonAction.ObjectFormAction;
		pButton.Enabled = True;
		pButton.Visible = True;
		pButton.Caption = cmNStr(pButtonAction.ButtonCaption);
		pButton.ToolTip = cmNStr(pButtonAction.ButtonToolTip);
		pButton.Shortcut = cmGetShortcutObject(pButtonAction.ButtonShortcut);
		vIcon = pButtonAction.ObjectFormAction.ActionIcon.Get();
		If vIcon = Undefined Then
			pButton.Picture = New Picture;
		Else
			pButton.Picture = pButtonAction.ObjectFormAction.ActionIcon.Get();
		EndIf;
	EndIf;
EndProcedure // cmSetButtonAttributes

// -----------------------------------------------------------------------------
// Description: Shows open file dialog
// Parameters: Returns full file name of file being open
// Return value: True if file was choosen, False if not
// -----------------------------------------------------------------------------
Function cmOpenFile(rFullFileName) Export
	vFileOpen = New FileDialog(FileDialogMode.Open);
	vFileOpen.FullFileName = rFullFileName;
	vFileOpen.Filter = NStr("ru='Все файлы (*.*)|*.*|';
	                        |de='Alle Dateien (*.*)|*.*|';
	                        |en='All files (*.*)|*.*|'");
	vFileOpen.Multiselect = False;
	vFileOpen.Title = NStr("en='Open file';ru='Выбрать файл';de='Datei wählen'");
	vFileOpen.Preview = True;
	If vFileOpen.Choose() Then
		rFullFileName = vFileOpen.FullFileName;
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // cmOpenFile

// -----------------------------------------------------------------------------
// Description: Shows open picture dialog
// Parameters: Returns full file name of picture being open
// Return value: True if picture was choosen, False if not
// -----------------------------------------------------------------------------
Function cmOpenPicture(rFullFileName) Export
	vFileOpen = New FileDialog(FileDialogMode.Open);
	vFileOpen.FullFileName = rFullFileName;
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
	vFileOpen.Title = NStr("en='Load picture';ru='Загрузить картинку';de='Bild laden'");
	vFileOpen.Preview = True;
	If vFileOpen.Choose() Then
		rFullFileName = vFileOpen.FullFileName;
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // cmOpenPicture

// -----------------------------------------------------------------------------
// Description: Shows open mxl template file dialog
// Parameters: Returns full file name of mxl template file being open
// Return value: True if file was choosen, False if not
// -----------------------------------------------------------------------------
Function cmOpenTemplate(rFullFileName) Export
	vFileOpen = New FileDialog(FileDialogMode.Open);
	vFileOpen.FullFileName = rFullFileName;
	vFileOpen.Filter = NStr("ru = 'Макеты 1С (*.mxl)|*.mxl|'; en = '1C templates (*.mxl)|*.mxl|'; de = '1C templates (*.mxl)|*.mxl|'");
	vFileOpen.Multiselect = False;
	vFileOpen.Title = NStr("en='Load template';ru='Загрузить макет';de='Design laden'");
	vFileOpen.Preview = False;
	If vFileOpen.Choose() Then
		rFullFileName = vFileOpen.FullFileName;
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // cmOpenTemplate

// -----------------------------------------------------------------------------
// Description: Shows open external data processor file dialog
// Parameters: Returns full file name of data processor being open, Type of external data processor
// Return value: True if file was choosen, False if not
// -----------------------------------------------------------------------------
Function cmOpenExternalDataProcessorFile(rFullFileName, pExternalProcessingType = Undefined) Export
	vFileOpen = New FileDialog(FileDialogMode.Open);
	vFileOpen.FullFileName = rFullFileName;
	If ValueIsFilled(pExternalProcessingType) Then
		If pExternalProcessingType = Enums.ExternalProcessingTypes.DataProcessor Then
			vFileOpen.Filter = NStr("ru='Внешняя обработка (*.epf)|*.epf|';
			                        |de='Externe Bearbeitung (*.epf)|*.epf|';
			                        |en='External data processor (*.epf)|*.epf|'");
		ElsIf pExternalProcessingType = Enums.ExternalProcessingTypes.Report Then
			vFileOpen.Filter = NStr("ru='Внешний отчет (*.erf)|*.erf|';
			                        |de='Externer Bericht (*.erf)|*.erf|';
			                        |en='External report (*.erf)|*.erf|'");
		Else
			vFileOpen.Filter = NStr("ru='Любой файл (*.*)|*.*|';
			                        |de='Beliebige Date (*.*)|*.*|';
			                        |en='Any file (*.*)|*.*|'");
		EndIf;
	Else
		vFileOpen.Filter = NStr("ru = 'Внешний отчет или обработка (*.erf;*.epf)|*.erf;*.epf|" +
		                              "Внешний отчет (*.erf)|*.erf|" + 
		                              "Внешняя обработка (*.epf)|*.epf|'; 
		                        |de = 'Внешний отчет или обработка (*.erf;*.epf)|*.erf;*.epf|" +
		                              "Внешний отчет (*.erf)|*.erf|" + 
		                              "Внешняя обработка (*.epf)|*.epf|'; 
								|en = 'External report or data processor (*.erf;*.epf)|*.erf;*.epf|" +
		                              "External report (*.erf)|*.erf|" + 
		                              "External data processor (*.epf)|*.epf|'");
	EndIf;
	vFileOpen.Multiselect = False;
	vFileOpen.Title = NStr("en='Load external data processor or report';de='Load external data processor or report';ru='Загрузить внешнюю обработку или отчет';de='Externe Bearbeitung oder Bericht laden'");
	vFileOpen.Preview = False;
	If vFileOpen.Choose() Then
		rFullFileName = vFileOpen.FullFileName;
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // cmOpenExternalDataProcessorFile

// -----------------------------------------------------------------------------
// Description: Shows choose directory dialog
// Parameters: Returns full directory name being choosen
// Return value: True if directory was choosen, False if not
// -----------------------------------------------------------------------------
Function cmChooseDirectory(rDirectoryName) Export
	vFileOpen = New FileDialog(FileDialogMode.ChooseDirectory);
	vFileOpen.Directory = rDirectoryName;
	vFileOpen.Multiselect = False;
	vFileOpen.Title = NStr("en='Choose directory';ru='Выбрать папку';de='Ordner auswählen'");
	vFileOpen.Preview = False;
	If vFileOpen.Choose() Then
		rDirectoryName = vFileOpen.Directory;
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // cmChooseDirectory

// -----------------------------------------------------------------------------
// Description: Shows choose file name dialog
// Parameters: Returns full file name being choosen
// Return value: True if directory was choosen, False if not
// -----------------------------------------------------------------------------
Function cmSaveXMLFile(rFileName) Export
	vFileSave = New FileDialog(FileDialogMode.Save);
	vFileSave.Filter = "XML (*.xml)|*.xml";
	vFileSave.DefaultExt = "xml";
	vFileSave.FullFileName = rFileName;
	vFileSave.Multiselect = False;
	vFileSave.Title = NStr("en='Choose file name and directory';ru='Укажите имя файла и путь';de='Geben Sie Namen und Pfad der Datei an'");
	vFileSave.Preview = False;
	If vFileSave.Choose() Then
		rFileName = vFileSave.FullFileName;
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // cmSaveXMLFile

// -----------------------------------------------------------------------------
// Description: Shows choose file name dialog
// Parameters: Returns full file name being choosen
// Return value: True if directory was choosen, False if not
// -----------------------------------------------------------------------------
Function cmOpenXMLFile(rFileName) Export
	vFileOpen = New FileDialog(FileDialogMode.Open);
	vFileOpen.Filter = "XML (*.xml)|*.xml";
	vFileOpen.Multiselect = False;
	vFileOpen.Title = NStr("en='Choose file';ru='Выберите файл';de='Wählen Sie die Datei'");
	vFileOpen.Preview = False;
	If vFileOpen.Choose() Then
		rFileName = vFileOpen.FullFileName;
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // cmOpenXMLFile

// -----------------------------------------------------------------------------
// Description: Saves report static and dynamic settings and parameters to the XML file
// Parameters: Reports catalog item reference or object
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmSaveReportSettingsToFile(pRep) Export
	vFileName = StrReplace(TrimAll(pRep.Report), " ", "") + "_" + TrimAll(pRep.Code);
	If cmSaveXMLFile(vFileName) Then
		cmWriteReportSettingsToFile(pRep, vFileName);
		DoMessageBox(NStr("en='Report settings are saved to file successfully!';ru='Настройки отчета успешно сохранены в файл!';de='Einstellungen des Berichts wurden erfolgreich in die Datei gespeichert!'"));
	EndIf;
EndProcedure // cmSaveReportSettingsToFile 

// -----------------------------------------------------------------------------
// Description: Load's report static and dynamic settings and parameters from the XML file
// Parameters: Reports catalog item object
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmLoadReportSettingsFromFile(pRepObj) Export
	vFileName = "";
	If cmOpenXMLFile(vFileName) Then
		cmReadReportSettingsFromFile(pRepObj, vFileName);
		DoMessageBox(NStr("en='Report settings are loaded from file successfully!';ru='Настройки отчета успешно загружены из файла!';de='Einstellungen des Berichts wurden erfolgreich aus der Datei geladen!'"));
	EndIf;
EndProcedure // cmLoadReportSettingsFromFile

// -----------------------------------------------------------------------------
// Description: Opens full text search form
// Parameters: Metadata to be searched name or value list of such metadata names,
//             String to be searched
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmOpenFullTextSearch(pMetadata, pSearchString = "") Export
	vFrm = DataProcessors.FullTextSearch.GetForm("Form", , "FullTextSearch");
	vFrm.LimitSearchArea = True;
	vFrm.SearchAreaList.Clear();
	If TypeOf(pMetadata) = Type("ValueList") Then
		vFrm.SearchAreaList = pMetadata;
	Else
		vFrm.SearchAreaList.Add(pMetadata);
	EndIf;
	vFrm.Open();
	// Check search string
	If Not IsBlankString(pSearchString) Then
		vFrm.SearchString = pSearchString;
		vFrm.Search();
	EndIf;
EndProcedure // cmOpenFullTextSearch

// -----------------------------------------------------------------------------
// Description: Opens form with document child structure
// Parameters: Document to build child documents tree from 
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmShowDocumentTree(pDoc) Export
	If Not ValueIsFilled(pDoc) Then
		Return;
	EndIf;
	vFrm = GetCommonForm("DocumentsTree");
	If vFrm.IsOpen() Then
		vFrm.Close();
	EndIf;
	vFrm.DocumentRef = pDoc;
	vFrm.Open();
EndProcedure // cmShowDocumentTree

// -----------------------------------------------------------------------------
// Description: Opens form of the given document
// Parameters: Document reference
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmOpenDocumentForm(pDoc) Export
	vFrm = pDoc.GetForm();
	vFrm.Open();
EndProcedure // cmOpenDocumentForm

// -----------------------------------------------------------------------------
// Description: Sets availability of "save as" button in the print form
// Parameters: Print form, Spreadsheet object
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmSetSaveAsButtonsAppearance(pForm, pSpreadsheet) Export
	Try
		If pSpreadsheet.Protection Then
			pForm.Controls.FormActions.Buttons.ActionSaveAs.Enabled = False;
			pForm.Controls.FormActions.Buttons.ActionSaveAs.Buttons.ActionSaveAsPDF.Enabled = False;
			pForm.Controls.FormActions.Buttons.ActionSaveAs.Buttons.ActionSaveAsMXL.Enabled = False;
			pForm.Controls.FormActions.Buttons.ActionSaveAs.Buttons.ActionSaveAsXLS.Enabled = False;
			pForm.Controls.FormActions.Buttons.ActionSaveAs.Buttons.ActionSaveAsHTML.Enabled = False;
		Else
			pForm.Controls.FormActions.Buttons.ActionSaveAs.Enabled = True;
			pForm.Controls.FormActions.Buttons.ActionSaveAs.Buttons.ActionSaveAsPDF.Enabled = True;
			pForm.Controls.FormActions.Buttons.ActionSaveAs.Buttons.ActionSaveAsMXL.Enabled = True;
			pForm.Controls.FormActions.Buttons.ActionSaveAs.Buttons.ActionSaveAsXLS.Enabled = True;
			pForm.Controls.FormActions.Buttons.ActionSaveAs.Buttons.ActionSaveAsHTML.Enabled = True;
		EndIf;
	Except
	EndTry;
EndProcedure // cmSetSaveAsButtonsAppearance 

// -----------------------------------------------------------------------------
// Description: This function is used to open new data processor item form
//              filled with parameters of data processor object currently open
// Parameters: Data processor object, Data processor form
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmSaveNewDataProcessorAttributesSetting(pDPObject, pDPForm) Export
	vDPObj = Catalogs.DataProcessors.CreateItem();
	vDPObj.Description = pDPObject.Metadata().Presentation();
	vDPObj.IsExternal = False;
	vDPObj.Processing = pDPObject.Metadata().Name;
	If ValueIsFilled(pDPObject.DataProcessor) Then
		vDPObj.Description = pDPObject.DataProcessor.Description;
		vDPObj.SortCode = pDPObject.DataProcessor.SortCode;
		vDPObj.Key = pDPObject.DataProcessor.Key;
		vDPObj.PermissionGroup = pDPObject.DataProcessor.PermissionGroup;
		vDPObj.Parent = pDPObject.DataProcessor.Parent;
		vDPObj.IsExternal = pDPObject.DataProcessor.IsExternal;
		If vDPObj.IsExternal Then
			vDPObj.Processing = pDPObject.DataProcessor.Processing;
		EndIf;
		vDPObj.DynamicParameters = pDPObject.DataProcessor.DynamicParameters;
	EndIf;
	vDPObj.StaticParameters = cmGetDataProcessorStaticParametersValue(pDPObject);
	If Not cmCheckUserPermissions("HavePermissionToRunAllDataProcessors") Then
		If ValueIsFilled(SessionParameters.CurrentUser) Then
			vDPObj.PermissionGroup = SessionParameters.CurrentUser.PermissionGroup;
		EndIf;
	EndIf;
	vFrm = vDPObj.GetForm(, pDPForm);
	vFrm.Open();
EndProcedure // cmSaveNewDataProcessorAttributesSetting

// -----------------------------------------------------------------------------
// Description: This function is used to open new report item form
//              filled with parameters of report object currently open
// Parameters: Report object, Report settings form
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmSaveNewReportAttributesSetting(pRepObject, pRepSettingsForm) Export
	vRepObj = Catalogs.Reports.CreateItem();
	vRepObj.Description = pRepObject.Metadata().Presentation();
	vRepObj.IsExternal = False;
	vRepObj.Report = pRepObject.Metadata().Name;
	If ValueIsFilled(pRepObject.Report) Then
		vRepObj.Description = pRepObject.Report.Description;
		vRepObj.SortCode = pRepObject.Report.SortCode;
		vRepObj.Key = pRepObject.Report.Key;
		vRepObj.PermissionGroup = pRepObject.Report.PermissionGroup;
		vRepObj.Parent = pRepObject.Report.Parent;
		vRepObj.IsExternal = pRepObject.Report.IsExternal;
		If vRepObj.IsExternal Then
			vRepObj.Report = pRepObject.Report.Report;
		EndIf;
		vRepObj.DynamicParameters = pRepObject.Report.DynamicParameters;
	EndIf;
	vRepObj.StaticParameters = cmGetReportStaticParametersValue(pRepObject);
	If Not cmCheckUserPermissions("HavePermissionToRunAllReports") Then
		If ValueIsFilled(SessionParameters.CurrentUser) Then
			vRepObj.PermissionGroup = SessionParameters.CurrentUser.PermissionGroup;
		EndIf;
	EndIf;
	vFrm = vRepObj.GetForm(, pRepSettingsForm);
	vFrm.Open();
EndProcedure // cmSaveNewReportAttributesSetting

// -----------------------------------------------------------------------------
// Description: This function is used to save current report settings to some existing
//              report setting
// Parameters: Report object, Report settings form
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmSaveAsReportAttributesSetting(pRepObject, pRepSettingsForm) Export
	// Choose new report item
	vFrm = Catalogs.Reports.GetChoiceForm();
	If ValueIsFilled(pRepObject.Report) Then
		vFrm.SelPermissionGroup = pRepObject.Report.PermissionGroup;
		vFrm.SelReport = pRepObject.Report.Report;
	Else
		If Not cmCheckUserPermissions("HavePermissionToRunAllReports") Then
			If ValueIsFilled(SessionParameters.CurrentUser) Then
				vFrm.SelPermissionGroup = cmGetEmployeePermissionGroup(SessionParameters.CurrentUser);
			EndIf;
		EndIf;
	EndIf;
	vReportItem = vFrm.DoModal();
	If ValueIsFilled(vReportItem) Then
		// Set reference to the new report item
		pRepObject.Report = vReportItem;
		// Set settings form appearance
		pRepSettingsForm.fmCommandBarAttributesAppearance();
		// Save setings to the changed report item
		cmSaveReportAttributes(pRepObject);
	EndIf;
EndProcedure // cmSaveAsReportAttributesSetting

// -----------------------------------------------------------------------------
// Description: Applies rules to the "Send by e-mail" print form button appearance
// Parameters: Submenu object, Document reference
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmSendByEmailSubmenuAppearance(pSendByEMail, pDoc) Export
	pSendByEMail.Buttons.Clear();
	pSendByEMail.Enabled = False;
	If ValueIsFilled(pDoc) Then
		vDocumentEMail = "";
		vCustomerEMail = "";
		vContactPersonEMail = "";
		vGuestEMail = "";
		vDocument = Undefined;
		vCustomer = Undefined;
		vGuest = Undefined;
		vContactPerson = "";
		If TypeOf(pDoc) = Type("DocumentRef.Reservation") Or 
		   TypeOf(pDoc) = Type("DocumentRef.Accommodation") Then
			vDocument = pDoc;
			vDocumentEmail = TrimAll(pDoc.EMail);
			vCustomer = pDoc.Customer;
			If ValueIsFilled(pDoc.Customer) Then
				vCustomerEMail = TrimAll(pDoc.Customer.EMail);
			EndIf;
			If ValueIsFilled(pDoc.Guest) Then
				vGuest = pDoc.Guest;
				vGuestEMail = TrimAll(vGuest.EMail);
			EndIf;
			If Not IsBlankString(pDoc.ContactPerson) Then
				vContactPersonEMail = cmGetContactPersonEMail(pDoc.ContactPerson);
				vContactPerson = TrimAll(pDoc.ContactPerson);
			EndIf;				
		ElsIf TypeOf(pDoc) = Type("DocumentRef.ResourceReservation") Then
			vDocument = pDoc;
			vDocumentEmail = TrimAll(pDoc.EMail);
			vCustomer = pDoc.Customer;
			If ValueIsFilled(pDoc.Customer) Then
				vCustomerEMail = TrimAll(pDoc.Customer.EMail);
			EndIf;
			If ValueIsFilled(pDoc.Client) Then
				vGuest = pDoc.Client;
				vGuestEMail = TrimAll(vGuest.EMail);
			EndIf;
			If Not IsBlankString(pDoc.ContactPerson) Then
				vContactPersonEMail = cmGetContactPersonEMail(pDoc.ContactPerson);
				vContactPerson = TrimAll(pDoc.ContactPerson);
			EndIf;				
		ElsIf TypeOf(pDoc) = Type("DocumentRef.ProformaInvoice") Then
			vDocumentEmail = TrimAll(pDoc.EMail);
			vCustomer = pDoc.AccountingCustomer;
			If ValueIsFilled(vCustomer) Then
				vCustomerEMail = TrimAll(vCustomer.EMail);
			EndIf;
			vDocument = pDoc.ParentDoc;
			If ValueIsFilled(vDocument) And TypeOf(vDocument) = Type("DocumentRef.Settlement") Then
				vDocument = Undefined;
			EndIf;
			If Not ValueIsFilled(vDocument) And ValueIsFilled(pDoc.GuestGroup) And ValueIsFilled(pDoc.GuestGroup.ClientDoc) Then
				vDocument = pDoc.GuestGroup.ClientDoc;
			EndIf;
			If ValueIsFilled(vDocument) Then
				If TypeOf(vDocument) = Type("DocumentRef.Reservation") Or 
				   TypeOf(vDocument) = Type("DocumentRef.Accommodation") Then
					If ValueIsFilled(vDocument.Guest) Then
						vGuest = vDocument.Guest;
						vGuestEMail = TrimAll(vGuest.EMail);
					EndIf;
					If Not IsBlankString(vDocument.ContactPerson) Then
						vContactPersonEMail = cmGetContactPersonEMail(vDocument.ContactPerson);
						vContactPerson = TrimAll(vDocument.ContactPerson);
					EndIf;				
				ElsIf TypeOf(vDocument) = Type("DocumentRef.ResourceReservation") Then
					If ValueIsFilled(vDocument.Client) Then
						vGuest = vDocument.Client;
						vGuestEMail = TrimAll(vGuest.EMail);
					EndIf;
					If Not IsBlankString(vDocument.ContactPerson) Then
						vContactPersonEMail = cmGetContactPersonEMail(vDocument.ContactPerson);
						vContactPerson = TrimAll(vDocument.ContactPerson);
					EndIf;				
				EndIf;
			EndIf;
		ElsIf TypeOf(pDoc) = Type("DocumentRef.Folio") Then
			vDocument = pDoc.ParentDoc;
			If ValueIsFilled(vDocument) Then
				vDocumentEmail = TrimAll(vDocument.EMail);
				If TypeOf(vDocument) = Type("DocumentRef.Reservation") Or 
				   TypeOf(vDocument) = Type("DocumentRef.ResourceReservation") Or 
				   TypeOf(vDocument) = Type("DocumentRef.Accommodation") Then
					If Not IsBlankString(vDocument.ContactPerson) Then
						vContactPersonEMail = cmGetContactPersonEMail(vDocument.ContactPerson);
						vContactPerson = TrimAll(vDocument.ContactPerson);
					EndIf;				
				EndIf;
			EndIf;
			vCustomer = pDoc.Customer;
			If ValueIsFilled(pDoc.Customer) Then
				vCustomerEMail = TrimAll(pDoc.Customer.EMail);
			EndIf;
			If ValueIsFilled(pDoc.Client) Then
				vGuest = pDoc.Client;
				vGuestEMail = TrimAll(vGuest.EMail);
			EndIf;
		ElsIf TypeOf(pDoc) = Type("DocumentRef.Settlement") Then
			vCustomer = pDoc.AccountingCustomer;
			If ValueIsFilled(vCustomer) Then
				vCustomerEMail = TrimAll(vCustomer.EMail);
			EndIf;
			vDocument = pDoc.ParentDoc;
			If Not ValueIsFilled(vDocument) And ValueIsFilled(pDoc.GuestGroup) Then
				If ValueIsFilled(pDoc.GuestGroup.Client) Then
					vGuest = pDoc.GuestGroup.Client;
					vGuestEMail = TrimAll(vGuest.EMail);
				EndIf;
				If ValueIsFilled(pDoc.GuestGroup.ClientDoc) Then
					vDocument = pDoc.GuestGroup.ClientDoc;
				EndIf;
			EndIf;
			If ValueIsFilled(vDocument) Then
				If TypeOf(vDocument) = Type("DocumentRef.Reservation") Or 
				   TypeOf(vDocument) = Type("DocumentRef.ResourceReservation") Or 
				   TypeOf(vDocument) = Type("DocumentRef.Accommodation") Then
					vDocumentEmail = TrimAll(vDocument.EMail);
					If Not IsBlankString(vDocument.ContactPerson) Then
						vContactPersonEMail = cmGetContactPersonEMail(vDocument.ContactPerson);
						vContactPerson = TrimAll(vDocument.ContactPerson);
					EndIf;				
				EndIf;
			EndIf;
		EndIf;
		If Not IsBlankString(vDocumentEmail) Or 
		   Not IsBlankString(vCustomerEmail) Or 
		   Not IsBlankString(vGuestEmail) Or 
		   Not IsBlankString(vContactPersonEMail) Then
			pSendByEMail.Enabled = True;
			If Not IsBlankString(vDocumentEmail) Then
				vButton = pSendByEMail.Buttons.Add("ActionSendToDocumentEMail", 
												   CommandBarButtonType.Action, 
												   vDocumentEmail, 
												   New Action("SendToDocumentEMailAction"));
				vButton.Picture = PictureLib.HTMLPage;
				vButton.Representation = CommandBarButtonRepresentation.PictureText;
				vButton.Description = NStr("ru='Отправить на адрес электронной почты указанный в документе';
				                           |de='An die im Dokument angegeben E-Mail-Adresse senden';
										   |en='Send to E-Mail address specified in the document'");
				vButton.ToolTip = NStr("ru='Отправить на адрес электронной почты указанный в документе';
				                       |de='An die im Dokument angegeben E-Mail-Adresse senden';
									   |en='Send to E-Mail address specified in the document'");
			EndIf;
			If Not IsBlankString(vCustomerEmail) Then
				vButton = pSendByEMail.Buttons.Add("ActionSendToCustomerEMail", 
												   CommandBarButtonType.Action, 
												   vCustomerEmail + " (" + TrimAll(vCustomer) + ")", 
												   New Action("SendToCustomerEMailAction"));
				vButton.Picture = PictureLib.HTMLPage;
				vButton.Representation = CommandBarButtonRepresentation.PictureText;
				vButton.Description = NStr("ru='Отправить на адрес электронной почты указанный у контрагента';
				                           |de='An die beim Partner angegebene E-Mail-Adresse senden';
										   |en='Send to E-Mail address specified for customer'");
				vButton.ToolTip = NStr("ru='Отправить на адрес электронной почты указанный у контрагента';
				                       |de='An die beim Partner angegebene E-Mail-Adresse senden';
									   |en='Send to E-Mail address specified for customer'");
			EndIf;
			If Not IsBlankString(vGuestEmail) Then
				vButton = pSendByEMail.Buttons.Add("ActionSendToGuestEMail", 
												   CommandBarButtonType.Action, 
												   vGuestEmail + " (" + TrimAll(vGuest) + ")", 
												   New Action("SendToGuestEMailAction"));
				vButton.Picture = PictureLib.HTMLPage;
				vButton.Representation = CommandBarButtonRepresentation.PictureText;
				vButton.Description = NStr("ru='Отправить на адрес электронной почты указанный у гостя';
				                           |de='An die beim Gast angegeben E-Mail-Adresse senden';
										   |en='Send to E-Mail address specified for guest'");
				vButton.ToolTip = NStr("ru='Отправить на адрес электронной почты указанный у гостя';
				                       |de='An die beim Gast angegeben E-Mail-Adresse senden';
									   |en='Send to E-Mail address specified for guest'");
			EndIf;
			If Not IsBlankString(vContactPersonEMail) Then
				vButton = pSendByEMail.Buttons.Add("ActionSendToContactPersonEMail", 
												   CommandBarButtonType.Action, 
												   vContactPersonEMail + " (" + TrimAll(vContactPerson) + ")", 
												   New Action("SendToContactPersonEMailAction"));
				vButton.Picture = PictureLib.HTMLPage;
				vButton.Representation = CommandBarButtonRepresentation.PictureText;
				vButton.Description = NStr("ru='Отправить на адрес электронной почты указанный у контактного лица';
				                           |de='An die bei der Kontaktperson angegebene E-Mail-Adresse senden';
										   |en='Send to E-Mail address specified for contact person'");
				vButton.ToolTip = NStr("ru='Отправить на адрес электронной почты указанный у контактного лица';
				                       |de='An die bei der Kontaktperson angegebene E-Mail-Adresse senden';
									   |en='Send to E-Mail address specified for contact person'");
			EndIf;
		EndIf;
	EndIf;
EndProcedure // cmSendByEmailSubmenuAppearance

// -----------------------------------------------------------------------------
// Description: Runs scheduled jobs in the file mode of the 1C:Enterprize
// Parameters: None
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmProcessScheduledJobs() Export
	ProcessJobs();
EndProcedure // cmProcessScheduledJobs

// -----------------------------------------------------------------------------
// Description: Checks scheduled reports information register for the new records
//              where schedule date&time is less then current date. If some records 
//              found then reports are generated for each of them and those records 
//              are deleted
// Parameters: None
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmProcessScheduledReports() Export
	// Create scheduled reports register record manager
	vRecordManager = InformationRegisters.ScheduledReports.CreateRecordManager();
	
	// Run query to get all active report keys
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ScheduledReports.ScheduleDateTime AS ScheduleDateTime,
	|	ScheduledReports.Key AS Key
	|FROM
	|	InformationRegister.ScheduledReports AS ScheduledReports
	|WHERE
	|	ScheduledReports.ScheduleDateTime <= &qPeriod
	|ORDER BY
	|	ScheduleDateTime";
	vQry.SetParameter("qPeriod", CurrentSessionDate());
	vScheduledReports = vQry.Execute().Unload();
	For Each vRow In vScheduledReports Do	
		// Generate reports by current register row key
		cmGenerateReportsByKey(TrimR(vRow.Key));
		
		// Delete processed register record
		Try
			vRecordManager.ScheduleDateTime = vRow.ScheduleDateTime;
			vRecordManager.Key = TrimR(vRow.Key);
			vRecordManager.Delete();
		Except
		EndTry;
	EndDo;
EndProcedure // cmProcessScheduledReports

// -----------------------------------------------------------------------------
// Description: Generates reports from the report package
// Parameters: Main package report item, Report object to use parameters from, 
//             Spreadsheet where to put reports, REport builder details object,
//             Report parameter object
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmGenerateReportsInThePackage(pReport, pParentRepObj, 
                                        pSpreadsheet, pReportBuilderDetails, 
                                        pParameter = Undefined) Export
	For Each vReportRow In pReport.Package Do
		If Not vReportRow.IsActive Then
			Continue;
		EndIf;
		// Put horizontal page break if necessary
		If vReportRow.ReportPutHorizontalPageBreakBefore Then
			pSpreadsheet.PutHorizontalPageBreak();
		EndIf;
		// Build package report object and generate report
		vRepObj = cmBuildReportObject(vReportRow.Report);
		If vRepObj <> Undefined Then
			// Initialize report settings
			Try
				// Fill reference to the report catalog item
				vRepObj.Report = vReportRow.Report;
				// Load report catalog item attributes
				vRepObj.pmLoadReportAttributes(pParameter);
				// Fill report attributes from the current report object
				If Not vReportRow.DoNotUseParentReportAttributes Then
					Try
						cmFillChildReportAttributes(vRepObj, pParentRepObj);
					Except
					EndTry;
				EndIf;
				// Generate report
				vRepFrm = vRepObj.GetForm();
				vRepFrm.GenerateOnFormOpen = True;
				If pReportBuilderDetails <> Undefined Then
					vRepFrm.ReportBuilderDetails = pReportBuilderDetails;
				EndIf;
				vRepFrm.fmGenerateReport(pParameter, pSpreadsheet, False, False, vReportRow);
			Except
				Continue;
			EndTry;
		EndIf;
	EndDo;
EndProcedure // cmGenerateReportsInThePackage	

// -----------------------------------------------------------------------------
// Description: Fills child report (from the package) attributes from the 
//              attributes of the parent main package report
// Parameters: Child report object, Parent report object 
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmFillChildReportAttributes(vChildRepObj, vParentRepObj) Export
	vExcludingAttributes = "Report, ReportBuilder, QueryText, ReportAppearanceTemplateType, " + 
	                       "ReportDimensionsPlacementOnRowsType, ReportDimensionsPlacementOnColumnsType, " + 
	                       "ReportTotalsPlacementOnRowsType, ReportTotalsPlacementOnColumnsType, " + 
	                       "ReportDimensionAttributesPlacementInRowsType, ReportDimensionAttributesPlacementInColumnsType, " + 
	                       "ReportDoNotPutReportHeader, ReportDoNotPutTableHeader, " + 
	                       "ReportDoNotPutDetailRecords, ReportDoNotPutTableFooter, " + 
	                       "ReportDoNotPutOveralls, ReportDoNotPutReportFooter"; 
	FillPropertyValues(vChildRepObj, vParentRepObj, , vExcludingAttributes);
EndProcedure // cmFillChildReportAttributes

// -----------------------------------------------------------------------------
// Description: Applies package row settings to the child report builder object
// Parameters: Structure of child report builder object, Package row
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmApplyPackageRowSettings(pReportBuilderAttrStruct, pPackageRow) Export
	// Override some report settings from the package row
	pReportBuilderAttrStruct.PutReportHeader = Not pPackageRow.ReportDoNotPutReportHeader;
	pReportBuilderAttrStruct.PutTableHeader = Not pPackageRow.ReportDoNotPutTableHeader;
	pReportBuilderAttrStruct.PutDetailRecords = Not pPackageRow.ReportDoNotPutDetailRecords;
	pReportBuilderAttrStruct.PutTableFooter = Not pPackageRow.ReportDoNotPutTableFooter;
	pReportBuilderAttrStruct.PutOveralls = Not pPackageRow.ReportDoNotPutOveralls;
	pReportBuilderAttrStruct.PutReportFooter = Not pPackageRow.ReportDoNotPutReportFooter;
EndProcedure // cmApplyPackageRowSettings

// -----------------------------------------------------------------------------
// Description: Fills main menu desktop Cash region with data
// Parameters: Spreadsheet where to put data
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmFillCashMonitor(pSpreadsheet, pDate = Undefined) Export
	vDate = pDate;
	If vDate = Undefined Then
		vDate = CurrentSessionDate();
	EndIf;
	
	// Clear spreadsheet
	pSpreadsheet.Clear();
	
	// Get monitor template
	vTemplate = GetCommonTemplate("MonitorTemplate");
	vArea = vTemplate.GetArea("CashMonitorHeader");
	pSpreadsheet.Put(vArea);
	
	// Get list of allowed cash registers
	vAllowedCashRegisters = New ValueList();
	If cmCheckUserPermissions("HavePermissionToViewAllCashRegisters") Then
		vAllowedCashRegisters = cmGetListOfAllCashRegisters();
	Else
		vAllowedCashRegisters = cmGetListOfCashRegistersAllowed(, SessionParameters.CurrentWorkstation);
	EndIf;
	
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CashInCashRegistersBalanceAndTurnovers.CashRegister,
	|	CashInCashRegistersBalanceAndTurnovers.Currency,
	|	CashInCashRegistersBalanceAndTurnovers.SumClosingBalance,
	|	CashInCashRegistersBalanceAndTurnovers.SumOpeningBalance,
	|	CashInCashRegistersBalanceAndTurnovers.SumReceipt,
	|	CashInCashRegistersBalanceAndTurnovers.SumExpense,
	|	CashInCashRegistersBalanceAndTurnovers.SumTurnover
	|FROM
	|	AccumulationRegister.CashInCashRegisters.BalanceAndTurnovers(&qPeriodFrom, &qPeriodTo, Day, RegisterRecordsAndPeriodBoundaries, CashRegister IN (&qAllowedCashRegisters)) AS CashInCashRegistersBalanceAndTurnovers
	|
	|ORDER BY
	|	CashInCashRegistersBalanceAndTurnovers.Currency.SortCode,
	|	CashInCashRegistersBalanceAndTurnovers.CashRegister.SortCode";
	vQry.SetParameter("qPeriodFrom", BegOfDay(vDate));
	vQry.SetParameter("qPeriodTo", EndOfDay(vDate));
	vQry.SetParameter("qAllowedCashRegisters", vAllowedCashRegisters);
	vResult = vQry.Execute().Unload();
	
	// Do output
	vArea = vTemplate.GetArea("CashRegister");
	For Each vResultRow In vResult Do
		vArea.Parameters.mCashRegister = vResultRow.CashRegister;
		vArea.Parameters.mCurrency = cmGetCurrencyPresentation(vResultRow.Currency);
		vArea.Parameters.mClosingBalance = vResultRow.SumClosingBalance;
		
		// Set up details structure
		vDetailsStructure = New Structure("Report, CashRegister");
		vDetailsStructure.Report = "PrintCashRegisterDayReport";
		vDetailsStructure.CashRegister = vResultRow.CashRegister;
		vArea.Parameters.mDetailsStructure = vDetailsStructure;
		
		pSpreadsheet.Put(vArea);
	EndDo;
EndProcedure // cmFillCashMonitor

// -----------------------------------------------------------------------------
// Description: Fills main menu desktop Payments region with data
// Parameters: Spreadsheet where to put data
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmFillPaymentsMonitor(pSpreadsheet, pDate = Undefined) Export
	vDate = pDate;
	If vDate = Undefined Then
		vDate = CurrentSessionDate();
	EndIf;
	
	// Clear spreadsheet
	pSpreadsheet.Clear();
	
	// Get monitor template
	vTemplate = GetCommonTemplate("MonitorTemplate");
	vArea = vTemplate.GetArea("PaymentsMonitorHeader");
	pSpreadsheet.Put(vArea);
	
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PaymentsTurnovers.PaymentMethod,
	|	PaymentsTurnovers.PaymentCurrency,
	|	SUM(PaymentsTurnovers.SumExpenseTurnover) AS SumExpenseTurnover,
	|	SUM(PaymentsTurnovers.SumReceiptTurnover) AS SumReceiptTurnover
	|FROM
	|	AccumulationRegister.Payments.Turnovers(&qPeriodFrom, &qPeriodTo, Day, Hotel IN HIERARCHY (&qHotel)) AS PaymentsTurnovers
	|
	|GROUP BY
	|	PaymentsTurnovers.PaymentMethod,
	|	PaymentsTurnovers.PaymentCurrency
	|
	|ORDER BY
	|	PaymentsTurnovers.PaymentMethod.SortCode,
	|	PaymentsTurnovers.PaymentCurrency.SortCode";
	vQry.SetParameter("qPeriodFrom", BegOfDay(vDate));
	vQry.SetParameter("qPeriodTo", EndOfDay(vDate));
	vQry.SetParameter("qHotel", SessionParameters.CurrentHotel);
	vResult = vQry.Execute().Unload();
	
	// Do output
	vArea = vTemplate.GetArea("PaymentMethod");
	For Each vResultRow In vResult Do
		// Skip settlements
		If vResultRow.PaymentMethod = Catalogs.PaymentMethods.Settlement Then
			Continue;
		EndIf;
		
		vArea.Parameters.mPaymentMethod = vResultRow.PaymentMethod;
		vArea.Parameters.mCurrency = cmGetCurrencyPresentation(vResultRow.PaymentCurrency);
		vArea.Parameters.mReceipt = vResultRow.SumReceiptTurnover;
		vArea.Parameters.mExpense = vResultRow.SumExpenseTurnover;
		
		pSpreadsheet.Put(vArea);
	EndDo;
EndProcedure // cmFillPaymentsMonitor

// -----------------------------------------------------------------------------
// Description: Fills main menu desktop Check-in region with data
// Parameters: Spreadsheet where to put data
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmFillCheckInMonitor(pSpreadsheet, pDate = Undefined) Export
	vDate = pDate;
	If vDate = Undefined Then
		vDate = CurrentSessionDate();
	EndIf;
	
	// Clear spreadsheet
	pSpreadsheet.Clear();
	
	// Get current hotel
	vHotel = SessionParameters.CurrentHotel;
	
	// Get monitor template
	vTemplate = GetCommonTemplate("MonitorTemplate");
	vArea = vTemplate.GetArea("CheckIn");
	
	// Run query to get planned resources for today
	vQryPlannedToday = New Query();
	vQryPlannedToday.Text = 
	"SELECT
	|	RoomInventoryTurnovers.Hotel,
	|	-SUM(RoomInventoryTurnovers.ExpectedRoomsCheckedInTurnover) AS RoomsReservedExpense,
	|	-SUM(RoomInventoryTurnovers.ExpectedBedsCheckedInTurnover) AS BedsReservedExpense,
	|	-SUM(RoomInventoryTurnovers.ExpectedGuestsCheckedInTurnover) AS GuestsReservedExpense
	|FROM
	|	AccumulationRegister.RoomInventory.Turnovers(&qPeriodFrom, &qPeriodTo, Period, Hotel IN HIERARCHY (&qHotel)) AS RoomInventoryTurnovers
	|
	|GROUP BY
	|	RoomInventoryTurnovers.Hotel";
	If BegOfDay(vDate) = BegOfDay(CurrentSessionDate()) Then
		vQryPlannedToday.SetParameter("qPeriodFrom", cmGetMinCheckInDate(vHotel));
	Else
		vQryPlannedToday.SetParameter("qPeriodFrom", BegOfDay(vDate));
	EndIf;
	vQryPlannedToday.SetParameter("qPeriodTo", EndOfDay(vDate));
	vQryPlannedToday.SetParameter("qHotel", vHotel);
	vPlannedTodayResult = vQryPlannedToday.Execute().Unload();
	vPlannedTodayResult.GroupBy(, "RoomsReservedExpense, BedsReservedExpense, GuestsReservedExpense");
	
	vPlannedRoomsToday = 0;
	vPlannedBedsToday = 0;
	vPlannedGuestsToday = 0;
	If vPlannedTodayResult.Count() > 0 Then
		vPlannedTodayRow = vPlannedTodayResult.Get(0);
		
		vPlannedRoomsToday = ?(vPlannedTodayRow.RoomsReservedExpense < 0, 0, vPlannedTodayRow.RoomsReservedExpense);
		vPlannedBedsToday = vPlannedTodayRow.BedsReservedExpense;
		vPlannedGuestsToday = vPlannedTodayRow.GuestsReservedExpense;
	EndIf;
	
	// Run query to get planned resources for tomorrow
	vQryPlannedTomorrow = New Query();
	vQryPlannedTomorrow.Text = 
	"SELECT
	|	RoomInventoryTurnovers.Hotel,
	|	-SUM(RoomInventoryTurnovers.ExpectedRoomsCheckedInTurnover) AS RoomsReservedExpense,
	|	-SUM(RoomInventoryTurnovers.ExpectedBedsCheckedInTurnover) AS BedsReservedExpense,
	|	-SUM(RoomInventoryTurnovers.ExpectedGuestsCheckedInTurnover) AS GuestsReservedExpense
	|FROM
	|	AccumulationRegister.RoomInventory.Turnovers(&qPeriodFrom, &qPeriodTo, Day, Hotel IN HIERARCHY (&qHotel)) AS RoomInventoryTurnovers
	|GROUP BY
	|	RoomInventoryTurnovers.Hotel";
	vQryPlannedTomorrow.SetParameter("qPeriodFrom", BegOfDay(vDate) + 24*3600);
	vQryPlannedTomorrow.SetParameter("qPeriodTo", EndOfDay(vDate) + 24*3600);
	vQryPlannedTomorrow.SetParameter("qHotel", vHotel);
	vPlannedTomorrowResult = vQryPlannedTomorrow.Execute().Unload();
	vPlannedTomorrowResult.GroupBy(, "RoomsReservedExpense, BedsReservedExpense, GuestsReservedExpense");
	
	vPlannedRoomsTomorrow = 0;
	vPlannedBedsTomorrow = 0;
	vPlannedGuestsTomorrow = 0;
	If vPlannedTomorrowResult.Count() > 0 Then
		vPlannedTomorrowRow = vPlannedTomorrowResult.Get(0);
		
		vPlannedRoomsTomorrow = ?(vPlannedTomorrowRow.RoomsReservedExpense < 0, 0, vPlannedTomorrowRow.RoomsReservedExpense);
		vPlannedBedsTomorrow = vPlannedTomorrowRow.BedsReservedExpense;
		vPlannedGuestsTomorrow = vPlannedTomorrowRow.GuestsReservedExpense;
	EndIf;
	
	// Run query to get checked in guests for today
	vQryToday = New Query();
	vQryToday.Text = 
	"SELECT
	|	RoomInventoryTurnovers.Hotel,
	|	-SUM(RoomInventoryTurnovers.RoomsCheckedInTurnover) AS RoomsCheckedIn,
	|	-SUM(RoomInventoryTurnovers.BedsCheckedInTurnover) AS BedsCheckedIn,
	|	-SUM(RoomInventoryTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedIn
	|FROM
	|	AccumulationRegister.RoomInventory.Turnovers(&qPeriodFrom, &qPeriodTo, Day, Hotel IN HIERARCHY (&qHotel)) AS RoomInventoryTurnovers
	|
	|GROUP BY
	|	RoomInventoryTurnovers.Hotel";
	vQryToday.SetParameter("qPeriodFrom", BegOfDay(vDate));
	vQryToday.SetParameter("qPeriodTo", EndOfDay(vDate));
	vQryToday.SetParameter("qHotel", vHotel);
	vTodayResult = vQryToday.Execute().Unload();
	vTodayResult.GroupBy(, "RoomsCheckedIn, BedsCheckedIn, GuestsCheckedIn");
	
	vRoomsToday = 0;
	vBedsToday = 0;
	vGuestsToday = 0;
	If vTodayResult.Count() > 0 Then
		vTodayRow = vTodayResult.Get(0);
		
		vRoomsToday = ?(vTodayRow.RoomsCheckedIn < 0, 0, vTodayRow.RoomsCheckedIn);
		vBedsToday = vTodayRow.BedsCheckedIn;
		vGuestsToday = vTodayRow.GuestsCheckedIn;
	EndIf;
	
	// Do output
	vArea.Parameters.mPlannedGuestsToday = vPlannedGuestsToday;
	vArea.Parameters.mPlannedGuestsTomorrow = vPlannedGuestsTomorrow;
	vArea.Parameters.mGuestsToday = vGuestsToday;
	
	vShowInBeds = False;
	If ValueIsFilled(vHotel) Then
		If vHotel.ShowReportsInBeds Then
			vShowInBeds = True;
		EndIf;
	EndIf;
	If vShowInBeds Then
		vArea.Parameters.mRoomsLabel = NStr("en='Beds';ru='Мест';de='Betten'");
		
		vArea.Parameters.mPlannedRoomsToday = vPlannedBedsToday;
		vArea.Parameters.mPlannedRoomsTomorrow = vPlannedBedsTomorrow;
		vArea.Parameters.mRoomsToday = vBedsToday;
	Else
		vArea.Parameters.mRoomsLabel = NStr("en='Rooms';ru='Номеров';de='Zimmern'");
		
		vArea.Parameters.mPlannedRoomsToday = vPlannedRoomsToday;
		vArea.Parameters.mPlannedRoomsTomorrow = vPlannedRoomsTomorrow;
		vArea.Parameters.mRoomsToday = vRoomsToday;
	EndIf;
	
	// Initialize details structures
	vArea.Parameters.mPlannedCheckInTodayDetailsStructure = New Structure("Report", "ExpectedCheckInForToday");
	vArea.Parameters.mPlannedCheckInTomorrowDetailsStructure = New Structure("Report", "ExpectedCheckInForTomorrow");
	vArea.Parameters.mCheckInTodayDetailsStructure = New Structure("Report", "GuestsCheckedInToday");
	
	pSpreadsheet.Put(vArea);
EndProcedure // cmFillCheckInMonitor

// -----------------------------------------------------------------------------
// Description: Fills main menu desktop Check-out region with data
// Parameters: Spreadsheet where to put data
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmFillCheckOutMonitor(pSpreadsheet, pDate = Undefined) Export
	vDate = pDate;
	If vDate = Undefined Then
		vDate = CurrentSessionDate();
	EndIf;
	
	// Clear spreadsheet
	pSpreadsheet.Clear();
	
	// Get current hotel
	vHotel = SessionParameters.CurrentHotel;
	
	// Get monitor template
	vTemplate = GetCommonTemplate("MonitorTemplate");
	vArea = vTemplate.GetArea("CheckOut");
	
	// Run query to get planned resources for today
	vQryPlannedToday = New Query();
	vQryPlannedToday.Text = 
	"SELECT
	|	RoomInventory.Hotel AS Hotel,
	|	SUM(RoomInventory.InHouseRooms) AS InHouseRooms,
	|	SUM(RoomInventory.InHouseBeds) AS InHouseBeds,
	|	SUM(RoomInventory.InHouseGuests) AS InHouseGuests
	|FROM
	|	(SELECT
	|		RoomInventoryMovements.Hotel AS Hotel,
	|		RoomInventoryMovements.Room AS Room,
	|		CASE
	|			WHEN SUM(RoomInventoryMovements.ExpectedRoomsCheckedOut) < 0
	|				THEN 0
	|			ELSE SUM(RoomInventoryMovements.ExpectedRoomsCheckedOut)
	|		END AS InHouseRooms,
	|		SUM(RoomInventoryMovements.ExpectedBedsCheckedOut) AS InHouseBeds,
	|		SUM(RoomInventoryMovements.ExpectedGuestsCheckedOut) AS InHouseGuests
	|	FROM
	|		AccumulationRegister.RoomInventory AS RoomInventoryMovements
	|	WHERE
	|		RoomInventoryMovements.IsAccommodation
	|		AND RoomInventoryMovements.RecordType = VALUE(AccumulationRecordType.Receipt) " + 
			?(ValueIsFilled(vHotel), ?(vHotel.IsFolder, " AND RoomInventoryMovements.Hotel IN HIERARCHY(&qHotel)", " AND RoomInventoryMovements.Hotel = &qHotel"), "") + "
	|		AND RoomInventoryMovements.PeriodTo >= &qPeriodFrom
	|		AND RoomInventoryMovements.PeriodTo <= &qPeriodTo
	|		AND RoomInventoryMovements.PeriodTo = RoomInventoryMovements.CheckOutDate
	|		AND RoomInventoryMovements.IsInHouse
	|		AND RoomInventoryMovements.IsCheckOut
	|	
	|	GROUP BY
	|		RoomInventoryMovements.Hotel,
	|		RoomInventoryMovements.Room) AS RoomInventory
	|
	|GROUP BY
	|	RoomInventory.Hotel";
	If BegOfDay(vDate) = BegOfDay(CurrentSessionDate()) Then
		vQryPlannedToday.SetParameter("qPeriodFrom", '00010101');
	Else
		vQryPlannedToday.SetParameter("qPeriodFrom", BegOfDay(vDate));
	EndIf;
	vQryPlannedToday.SetParameter("qPeriodTo", EndOfDay(vDate));
	vQryPlannedToday.SetParameter("qHotel", vHotel);
	vPlannedTodayResult = vQryPlannedToday.Execute().Unload();
	vPlannedTodayResult.GroupBy(, "InHouseRooms, InHouseBeds, InHouseGuests");
	
	vPlannedRoomsToday = 0;
	vPlannedBedsToday = 0;
	vPlannedGuestsToday = 0;
	If vPlannedTodayResult.Count() > 0 Then
		vPlannedTodayRow = vPlannedTodayResult.Get(0);
		
		vPlannedRoomsToday = vPlannedTodayRow.InHouseRooms;
		vPlannedBedsToday = vPlannedTodayRow.InHouseBeds;
		vPlannedGuestsToday = vPlannedTodayRow.InHouseGuests;
	EndIf;
	
	// Run query to get planned resources for tomorrow
	vQryPlannedTomorrow = New Query();
	vQryPlannedTomorrow.Text = 
	"SELECT
	|	RoomInventoryTurnovers.Hotel,
	|	SUM(RoomInventoryTurnovers.ExpectedRoomsCheckedOutTurnover) AS RoomsCheckedOut,
	|	SUM(RoomInventoryTurnovers.ExpectedBedsCheckedOutTurnover) AS BedsCheckedOut,
	|	SUM(RoomInventoryTurnovers.ExpectedGuestsCheckedOutTurnover) AS GuestsCheckedOut
	|FROM
	|	AccumulationRegister.RoomInventory.Turnovers(&qPeriodFrom, &qPeriodTo, Day, " + 
	?(ValueIsFilled(vHotel), ?(vHotel.IsFolder, " Hotel IN HIERARCHY (&qHotel)", " Hotel = &qHotel"), "") + "
	|	) AS RoomInventoryTurnovers
	|GROUP BY
	|	RoomInventoryTurnovers.Hotel";
	vQryPlannedTomorrow.SetParameter("qPeriodFrom", BegOfDay(vDate) + 24*3600);
	vQryPlannedTomorrow.SetParameter("qPeriodTo", EndOfDay(vDate) + 24*3600);
	vQryPlannedTomorrow.SetParameter("qHotel", vHotel);
	vPlannedTomorrowResult = vQryPlannedTomorrow.Execute().Unload();
	vPlannedTomorrowResult.GroupBy(, "RoomsCheckedOut, BedsCheckedOut, GuestsCheckedOut");
	
	vPlannedRoomsTomorrow = 0;
	vPlannedBedsTomorrow = 0;
	vPlannedGuestsTomorrow = 0;
	If vPlannedTomorrowResult.Count() > 0 Then
		vPlannedTomorrowRow = vPlannedTomorrowResult.Get(0);
		
		vPlannedRoomsTomorrow = vPlannedTomorrowRow.RoomsCheckedOut;
		vPlannedBedsTomorrow = vPlannedTomorrowRow.BedsCheckedOut;
		vPlannedGuestsTomorrow = vPlannedTomorrowRow.GuestsCheckedOut;
	EndIf;
	
	// Do output
	vArea.Parameters.mPlannedGuestsToday = vPlannedGuestsToday;
	vArea.Parameters.mPlannedGuestsTomorrow = vPlannedGuestsTomorrow;
	
	vShowInBeds = False;
	If ValueIsFilled(vHotel) Then
		If vHotel.ShowReportsInBeds Then
			vShowInBeds = True;
		EndIf;
	EndIf;
	If vShowInBeds Then
		vArea.Parameters.mRoomsLabel = NStr("en='Beds';ru='Мест';de='Betten'");
		
		vArea.Parameters.mPlannedRoomsToday = vPlannedBedsToday;
		vArea.Parameters.mPlannedRoomsTomorrow = vPlannedBedsTomorrow;
	Else
		vArea.Parameters.mRoomsLabel = NStr("en='Rooms';ru='Номеров';de='Zimmern'");
		
		vArea.Parameters.mPlannedRoomsToday = vPlannedRoomsToday;
		vArea.Parameters.mPlannedRoomsTomorrow = vPlannedRoomsTomorrow;
	EndIf;
	
	// Initialize details structures
	vArea.Parameters.mCheckOutTodayDetailsStructure = New Structure("Report", "ExpectedCheckOutForToday");
	vArea.Parameters.mCheckOutTomorrowDetailsStructure = New Structure("Report", "ExpectedCheckOutForTomorrow");
	
	pSpreadsheet.Put(vArea);
EndProcedure // cmFillCheckOutMonitor

// -----------------------------------------------------------------------------
// Description: Fills main menu desktop Occupation percents region with data
// Parameters: Spreadsheet where to put data
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmFillOccupationMonitor(pSpreadsheet, pDate = Undefined) Export
	vDate = pDate;
	If vDate = Undefined Then
		vDate = CurrentSessionDate();
	EndIf;
	
	// Clear spreadsheet
	pSpreadsheet.Clear();
	
	// Show in beds
	vHotel = SessionParameters.CurrentHotel;
	
	vShowInBeds = False;
	vShowSalesWithVAT = False;
	If ValueIsFilled(vHotel) Then
		vShowInBeds = vHotel.ShowReportsInBeds;
		vShowSalesWithVAT = vHotel.ShowSalesInReportsWithVAT;
	EndIf;
	
	// Get monitor template
	vTemplate = GetCommonTemplate("MonitorTemplate");
	
	// Run query to get room inventory statistics
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInventoryBalance.Hotel,
	|	SUM(RoomInventoryBalance.TotalRoomsBalance) AS TotalRoomsBalance,
	|	SUM(RoomInventoryBalance.TotalBedsBalance) AS TotalBedsBalance,
	|	SUM(RoomInventoryBalance.RoomsBlockedBalance) AS RoomsBlockedBalance,
	|	SUM(RoomInventoryBalance.BedsBlockedBalance) AS BedsBlockedBalance,
	|	SUM(RoomInventoryBalance.RoomsVacantBalance) AS RoomsVacantBalance,
	|	SUM(RoomInventoryBalance.BedsVacantBalance) AS BedsVacantBalance,
	|	SUM(RoomInventoryBalance.InHouseGuestsBalance) AS InHouseGuestsBalance
	|FROM
	|	AccumulationRegister.RoomInventory.Balance(
	|			&qPeriodTo, 
	|			Hotel IN HIERARCHY (&qHotel)) AS RoomInventoryBalance
	|GROUP BY
	|	RoomInventoryBalance.Hotel";
	vQry.SetParameter("qPeriodTo", EndOfDay(vDate));
	vQry.SetParameter("qHotel", vHotel);
	vInvResult = vQry.Execute().Unload();
	vInvResult.GroupBy(, "TotalRoomsBalance, TotalBedsBalance, RoomsBlockedBalance, BedsBlockedBalance, RoomsVacantBalance, BedsVacantBalance, InHouseGuestsBalance");
	
	vTotalRooms = 0;
	vTotalBeds = 0;
	vRoomsBlocked = 0;
	vBedsBlocked = 0;
	vRoomsVacant = 0;
	vBedsVacant = 0;
	vInHouseGuests = 0;
	If vInvResult.Count() > 0 Then
		vResultRow = vInvResult.Get(0);
		
		vTotalRooms = vResultRow.TotalRoomsBalance;
		vTotalBeds = vResultRow.TotalBedsBalance;
		vRoomsBlocked = -vResultRow.RoomsBlockedBalance;
		vBedsBlocked = -vResultRow.BedsBlockedBalance;
		vRoomsVacant = vResultRow.RoomsVacantBalance;
		vBedsVacant = vResultRow.BedsVacantBalance;
		vInHouseGuests = -vResultRow.InHouseGuestsBalance;
	EndIf;
	
	// Run query to get total room blocks that should be added to the number of total rooms rented
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomBlocksBalance.Hotel,
	|	SUM(RoomBlocksBalance.RoomsBlockedBalance) AS SpecRoomsBlocked,
	|	SUM(RoomBlocksBalance.BedsBlockedBalance) AS SpecBedsBlocked
	|FROM
	|	AccumulationRegister.RoomBlocks.Balance(
	|			&qPeriodTo,
	|			Hotel IN HIERARCHY (&qHotel) AND
	|			RoomBlockType.AddToRoomsRentedInSummaryIndexes) AS RoomBlocksBalance
	|GROUP BY
	|	RoomBlocksBalance.Hotel";
	vQry.SetParameter("qHotel", vHotel);
	vQry.SetParameter("qPeriodTo", EndOfDay(vDate));
	vSpecBlocksResult = vQry.Execute().Unload();
	
	vSpecRoomsBlocked = 0;
	vSpecBedsBlocked = 0;
	If vSpecBlocksResult.Count() > 0 Then
		vSpecBlocksResultRow = vSpecBlocksResult.Get(0);
		
		vSpecRoomsBlocked = vSpecBlocksResultRow.SpecRoomsBlocked;
		vSpecBedsBlocked = vSpecBlocksResultRow.SpecBedsBlocked;
	EndIf;
	
	// Fill area A.
	If vShowInBeds Then
		vAreaA = vTemplate.GetArea("TotalBeds");
		vAreaA.Parameters.mTotalBeds = vTotalBeds;
		vAreaA.Parameters.mBedsBlocked = vBedsBlocked - vSpecBedsBlocked;
	Else
		vAreaA = vTemplate.GetArea("TotalRooms");
		vAreaA.Parameters.mTotalRooms = vTotalRooms;
		vAreaA.Parameters.mRoomsBlocked = vRoomsBlocked - vSpecRoomsBlocked;
	EndIf;
	
	// Run query to get room sales for today
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomSales.ReportingCurrency AS ReportingCurrency,
	|	SUM(RoomSales.SalesTurnover) AS SalesTurnover,
	|	SUM(RoomSales.SalesWithoutVATTurnover) AS SalesWithoutVATTurnover,
	|	SUM(RoomSales.RoomRevenueTurnover) AS RoomRevenueTurnover,
	|	SUM(RoomSales.RoomRevenueWithoutVATTurnover) AS RoomRevenueWithoutVATTurnover,
	|	SUM(RoomSales.GuestDaysTurnover) AS GuestDaysTurnover,
	|	SUM(RoomSales.RoomsRentedTurnover) AS RoomsRentedTurnover,
	|	SUM(RoomSales.BedsRentedTurnover) AS BedsRentedTurnover
	|FROM
	|	(SELECT
	|		RoomSalesTurnovers.ReportingCurrency AS ReportingCurrency,
	|		RoomSalesTurnovers.SalesTurnover AS SalesTurnover,
	|		RoomSalesTurnovers.SalesWithoutVATTurnover AS SalesWithoutVATTurnover,
	|		RoomSalesTurnovers.RoomRevenueTurnover AS RoomRevenueTurnover,
	|		RoomSalesTurnovers.RoomRevenueWithoutVATTurnover AS RoomRevenueWithoutVATTurnover,
	|		RoomSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover,
	|		RoomSalesTurnovers.RoomsRentedTurnover AS RoomsRentedTurnover,
	|		RoomSalesTurnovers.BedsRentedTurnover AS BedsRentedTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(&qPeriodFrom, &qPeriodTo, Day, Hotel IN HIERARCHY (&qHotel)) AS RoomSalesTurnovers
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RoomSalesForecastTurnovers.ReportingCurrency,
	|		RoomSalesForecastTurnovers.SalesTurnover,
	|		RoomSalesForecastTurnovers.SalesWithoutVATTurnover,
	|		RoomSalesForecastTurnovers.RoomRevenueTurnover,
	|		RoomSalesForecastTurnovers.RoomRevenueWithoutVATTurnover,
	|		RoomSalesForecastTurnovers.GuestDaysTurnover,
	|		RoomSalesForecastTurnovers.RoomsRentedTurnover,
	|		RoomSalesForecastTurnovers.BedsRentedTurnover
	|	FROM
	|		AccumulationRegister.SalesForecast.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Day,
	|				NOT &qDateIsInThePast
	|					AND Hotel IN HIERARCHY (&qHotel)
	|					AND ParentDoc REFS Document.Accommodation) AS RoomSalesForecastTurnovers) AS RoomSales
	|
	|GROUP BY
	|	RoomSales.ReportingCurrency
	|
	|ORDER BY
	|	RoomSales.ReportingCurrency.SortCode";
	vQry.SetParameter("qPeriodFrom", BegOfDay(vDate));
	vQry.SetParameter("qPeriodTo", EndOfDay(vDate));
	vForecastStartDate = tcOnServer.GetForecastStartDate(vHotel);
	vQry.SetParameter("qDateIsInthePast", ?(BegOfDay(vDate) < BegOfDay(vForecastStartDate), True, False));
	vQry.SetParameter("qHotel", vHotel);
	vSalesResult = vQry.Execute().Unload();
	
	// Get number of rooms/beds sold
	vReportingCurrency = Undefined;
	If ValueIsFilled(vHotel) Then
		vReportingCurrency = vHotel.ReportingCurrency;
	EndIf;
	vSales = 0;
	vSalesWithoutVAT = 0;
	vRoomRevenue = 0;
	vRoomRevenueWithoutVAT = 0;
	vRoomsSold = 0;
	vBedsSold = 0;
	vGuestDays = 0;
	For Each vSalesResultRow In vSalesResult Do
		vReportingCurrency = vSalesResultRow.ReportingCurrency;
		vSales = vSales + vSalesResultRow.SalesTurnover;
		vSalesWithoutVAT = vSalesWithoutVAT + vSalesResultRow.SalesWithoutVATTurnover;
		vRoomRevenue = vRoomRevenue + vSalesResultRow.RoomRevenueTurnover;
		vRoomRevenueWithoutVAT = vRoomRevenueWithoutVAT + vSalesResultRow.RoomRevenueWithoutVATTurnover;
		vRoomsSold = vRoomsSold + vSalesResultRow.RoomsRentedTurnover;
		vBedsSold = vBedsSold + vSalesResultRow.BedsRentedTurnover;
		vGuestDays = vGuestDays + vSalesResultRow.GuestDaysTurnover;
	EndDo;
	
	// Run query to get room sales forcast for today
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomSalesForecastTurnovers.ReportingCurrency,
	|	SUM(RoomSalesForecastTurnovers.SalesTurnover) AS SalesTurnover,
	|	SUM(RoomSalesForecastTurnovers.SalesWithoutVATTurnover) AS SalesWithoutVATTurnover,
	|	SUM(RoomSalesForecastTurnovers.RoomRevenueTurnover) AS RoomRevenueTurnover,
	|	SUM(RoomSalesForecastTurnovers.RoomRevenueWithoutVATTurnover) AS RoomRevenueWithoutVATTurnover,
	|	SUM(RoomSalesForecastTurnovers.GuestDaysTurnover) AS GuestDaysTurnover,
	|	SUM(RoomSalesForecastTurnovers.RoomsRentedTurnover) AS RoomsRentedTurnover,
	|	SUM(RoomSalesForecastTurnovers.BedsRentedTurnover) AS BedsRentedTurnover
	|FROM
	|	AccumulationRegister.SalesForecast.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			NOT &qDateIsInThePast
	|				AND Hotel IN HIERARCHY (&qHotel)
	|				AND NOT ParentDoc REFS Document.Accommodation) AS RoomSalesForecastTurnovers
	|
	|GROUP BY
	|	RoomSalesForecastTurnovers.ReportingCurrency
	|
	|ORDER BY
	|	RoomSalesForecastTurnovers.ReportingCurrency.SortCode";
	vQry.SetParameter("qPeriodFrom", BegOfDay(vDate));
	vQry.SetParameter("qPeriodTo", EndOfDay(vDate));
	vForecastStartDate = tcOnServer.GetForecastStartDate(vHotel);
	vQry.SetParameter("qDateIsInthePast", ?(BegOfDay(vDate) < BegOfDay(vForecastStartDate), True, False));
	vQry.SetParameter("qHotel", vHotel);
	vSalesForecastResult = vQry.Execute().Unload();
	
	// Get number of rooms/beds sold
	vSalesForecast = 0;
	vSalesWithoutVATForecast = 0;
	vRoomRevenueForecast = 0;
	vRoomRevenueWithoutVATForecast = 0;
	vRoomsSoldForecast = 0;
	vBedsSoldForecast = 0;
	vGuestDaysForecast = 0;
	For Each vSalesForecastResultRow In vSalesForecastResult Do
		vSalesForecast = vSalesForecast + vSalesForecastResultRow.SalesTurnover;
		vSalesWithoutVATForecast = vSalesWithoutVATForecast + vSalesForecastResultRow.SalesWithoutVATTurnover;
		vRoomRevenueForecast = vRoomRevenueForecast + vSalesForecastResultRow.RoomRevenueTurnover;
		vRoomRevenueWithoutVATForecast = vRoomRevenueWithoutVATForecast + vSalesForecastResultRow.RoomRevenueWithoutVATTurnover;
		vRoomsSoldForecast = vRoomsSoldForecast + vSalesForecastResultRow.RoomsRentedTurnover;
		vBedsSoldForecast = vBedsSoldForecast + vSalesForecastResultRow.BedsRentedTurnover;
		vGuestDaysForecast = vGuestDaysForecast + vSalesForecastResultRow.GuestDaysTurnover;
	EndDo;
	
	// Fill areas C.D.E.
	If vShowInBeds Then
		vAreaCDE = vTemplate.GetArea("BedsSold|First2Columns");
		vDiagramCDE = vTemplate.GetArea("BedsSold|Last3Column");
		vDiagram = vDiagramCDE.Area("BedsSoldMeter").Object;
		
		If vBedsSoldForecast <> 0 Then
			vAreaCDE.Parameters.mBedsSold = "" + Format(vBedsSold + vSpecBedsBlocked, "ND=10; NFD=1; NZ=; NG=") + " / " + Format(vBedsSold + vBedsSoldForecast + vSpecBedsBlocked, "ND=10; NFD=1; NZ=; NG=");
		Else
			vAreaCDE.Parameters.mBedsSold = "" + Format(vBedsSold + vSpecBedsBlocked, "ND=10; NFD=1; NZ=; NG=");
		EndIf;
	Else
		vAreaCDE = vTemplate.GetArea("RoomsSold|First2Columns");
		vDiagramCDE = vTemplate.GetArea("RoomsSold|Last3Column");
		vDiagram = vDiagramCDE.Area("RoomsSoldMeter").Object;
		
		If vRoomsSoldForecast <> 0 Then
			vAreaCDE.Parameters.mRoomsSold = "" + Format(vRoomsSold + vSpecRoomsBlocked, "ND=10; NFD=1; NZ=; NG=") + " / " + Format(vRoomsSold + vRoomsSoldForecast + vSpecRoomsBlocked, "ND=10; NFD=1; NZ=; NG=");
		Else
			vAreaCDE.Parameters.mRoomsSold = "" + Format(vRoomsSold + vSpecRoomsBlocked, "ND=10; NFD=1; NZ=; NG=");
		EndIf;
	EndIf;
	
	mOccupationPercent = 0;
	mOccupationPercentForecast = 0;
	If vShowInBeds Then
		If (vTotalBeds - vBedsBlocked + vSpecBedsBlocked) <> 0 Then 
			mOccupationPercent = Round(100*(vBedsSold + vSpecBedsBlocked)/(vTotalBeds - vBedsBlocked + vSpecBedsBlocked), 2);
			mOccupationPercentForecast = Round(100*(vBedsSold + vBedsSoldForecast + vSpecBedsBlocked)/(vTotalBeds - vBedsBlocked + vSpecBedsBlocked), 2);
		EndIf;
	Else
		If (vTotalRooms - vRoomsBlocked + vSpecRoomsBlocked) <> 0 Then 
			mOccupationPercent = Round(100*(vRoomsSold + vSpecRoomsBlocked)/(vTotalRooms - vRoomsBlocked + vSpecRoomsBlocked), 2);
			mOccupationPercentForecast = Round(100*(vRoomsSold + vRoomsSoldForecast + vSpecRoomsBlocked)/(vTotalRooms - vRoomsBlocked + vSpecRoomsBlocked), 2);
		EndIf;
	EndIf;
	If mOccupationPercent = mOccupationPercentForecast Then
		vAreaCDE.Parameters.mOccupationPercent = "" + mOccupationPercent;
	Else
		vAreaCDE.Parameters.mOccupationPercent = "" + mOccupationPercent + " / " + mOccupationPercentForecast;
	EndIf;
	
	If vGuestDaysForecast <> 0 Then
		vAreaCDE.Parameters.mInHouseGuests = "" + Format(vGuestDays, "ND=10; NFD=0; NZ=; NG=") + " / " + Format(vGuestDays + vGuestDaysForecast, "ND=10; NFD=0; NZ=; NG=");
	Else
		vAreaCDE.Parameters.mInHouseGuests = "" + Format(vGuestDays, "ND=10; NFD=0; NZ=; NG=");
	EndIf;
	
	// Get occupation percent meter
	vDiagram.RefreshEnabled = False;
	vDiagram.AutoSeriesText = False;
	vDiagram.AutoPointText = False;
	vDiagram.Clear();
	vSeria = vDiagram.Series.Add(NStr("en='Current occupancy %';ru='Тек. % загрузки';de='Aktueller % die Belegung'"));
	vSeriaForecast = vDiagram.Series.Add(NStr("en='Forecast occupancy %';ru='План. % загрузки';de='Geplant % des Ladens'"));
	If vShowInBeds Then
		vPoint = vDiagram.Points.Add(NStr("en='By beds sold';ru='По проданным местам';de='Nach verkauften Betten'"));
	Else
		vPoint = vDiagram.Points.Add(NStr("en='By rooms sold';ru='По проданным номерам';de='Nach verkauften Zimmern'"));
	EndIf;
	vDiagram.SetValue(vPoint, vSeria, Min(?(mOccupationPercent < 0, 0, mOccupationPercent), 100));
	vDiagram.SetValue(vPoint, vSeriaForecast, Min(?(mOccupationPercentForecast < 0, 0, mOccupationPercentForecast), 100));
	vDiagram.RefreshEnabled = True;

	// Do output	
	vArea = vTemplate.GetArea("StatisticsMonitorHeader");
	pSpreadsheet.Put(vArea);
	
	// Output section A
	pSpreadsheet.Put(vAreaA);
	// Output section C, D, E
	pSpreadsheet.Put(vAreaCDE);
	pSpreadsheet.Join(vDiagramCDE);
	
	// Output section F
	If vShowSalesWithVAT Then
		vAreaFHeader = vTemplate.GetArea("SalesHeaderWithVAT");
	Else
		vAreaFHeader = vTemplate.GetArea("SalesHeader");
	EndIf;
	pSpreadsheet.Put(vAreaFHeader);
	
	vAreaF = vTemplate.GetArea("Sales");
	If vShowSalesWithVAT Then
		vAreaF.Parameters.mSales = vSales + vSalesForecast;
		vAreaF.Parameters.mRoomRevenue = vRoomRevenue + vRoomRevenueForecast;
	Else
		vAreaF.Parameters.mSales = vSalesWithoutVAT + vSalesWithoutVATForecast;
		vAreaF.Parameters.mRoomRevenue = vRoomRevenueWithoutVAT + vRoomRevenueWithoutVATForecast;
	EndIf;
	vAreaF.Parameters.mCurrency = cmGetCurrencyPresentation(vReportingCurrency);
	
	pSpreadsheet.Put(vAreaF);
	
	// Output section G
	If vShowInBeds Then
		vAreaGHeader = vTemplate.GetArea("AverageBedStatisticsHeader");
	Else
		vAreaGHeader = vTemplate.GetArea("AverageRoomStatisticsHeader");
	EndIf;
	pSpreadsheet.Put(vAreaGHeader);
	
	If vShowInBeds Then
		vAreaG = vTemplate.GetArea("AverageBedStatistics");
	Else
		vAreaG = vTemplate.GetArea("AverageRoomStatistics");
	EndIf;
	If vShowSalesWithVAT Then
		If vShowInBeds Then
			If (vBedsSold + vBedsSoldForecast) = 0 Then
				vAreaG.Parameters.mAvgBedPrice = 0;
			Else
				vAreaG.Parameters.mAvgBedPrice = Round((vRoomRevenue + vRoomRevenueForecast)/(vBedsSold + vBedsSoldForecast), 2);
			EndIf;
			If (vTotalBeds - vBedsBlocked + vSpecBedsBlocked) = 0 Then
				vAreaG.Parameters.mAvgBedIncome = 0;
			Else
				vAreaG.Parameters.mAvgBedIncome = Round((vRoomRevenue + vRoomRevenueForecast)/(vTotalBeds - vBedsBlocked + vSpecBedsBlocked), 2);
			EndIf;
		Else
			If (vRoomsSold + vRoomsSoldForecast) = 0 Then
				vAreaG.Parameters.mAvgRoomPrice = 0;
			Else
				vAreaG.Parameters.mAvgRoomPrice = Round((vRoomRevenue + vRoomRevenueForecast)/(vRoomsSold + vRoomsSoldForecast), 2);
			EndIf;
			If (vTotalRooms - vRoomsBlocked + vSpecRoomsBlocked) = 0 Then
				vAreaG.Parameters.mAvgRoomIncome = 0;
			Else
				vAreaG.Parameters.mAvgRoomIncome = Round((vRoomRevenue + vRoomRevenueForecast)/(vTotalRooms - vRoomsBlocked + vSpecRoomsBlocked), 2);
			EndIf;
		EndIf;
	Else
		If vShowInBeds Then
			If (vBedsSold + vBedsSoldForecast) = 0 Then
				vAreaG.Parameters.mAvgBedPrice = 0;
			Else
				vAreaG.Parameters.mAvgBedPrice = Round((vRoomRevenueWithoutVAT + vRoomRevenueWithoutVATForecast)/(vBedsSold + vBedsSoldForecast), 2);
			EndIf;
			If (vTotalBeds - vBedsBlocked + vSpecBedsBlocked) = 0 Then
				vAreaG.Parameters.mAvgBedIncome = 0;
			Else
				vAreaG.Parameters.mAvgBedIncome = Round((vRoomRevenueWithoutVAT + vRoomRevenueWithoutVATForecast)/(vTotalBeds - vBedsBlocked + vSpecBedsBlocked), 2);
			EndIf;
		Else
			If (vRoomsSold + vRoomsSoldForecast) = 0 Then
				vAreaG.Parameters.mAvgRoomPrice = 0;
			Else
				vAreaG.Parameters.mAvgRoomPrice = Round((vRoomRevenueWithoutVAT + vRoomRevenueWithoutVATForecast)/(vRoomsSold + vRoomsSoldForecast), 2);
			EndIf;
			If (vTotalRooms - vRoomsBlocked + vSpecRoomsBlocked) = 0 Then
				vAreaG.Parameters.mAvgRoomIncome = 0;
			Else
				vAreaG.Parameters.mAvgRoomIncome = Round((vRoomRevenueWithoutVAT + vRoomRevenueWithoutVATForecast)/(vTotalRooms - vRoomsBlocked + vSpecRoomsBlocked), 2);
			EndIf;
		EndIf;
	EndIf;
	vAreaG.Parameters.mCurrency = cmGetCurrencyPresentation(vReportingCurrency);
	
	pSpreadsheet.Put(vAreaG);
EndProcedure // cmFillOccupationMonitor

// -----------------------------------------------------------------------------
// Description: Fills main menu desktop Occupation percents region with data in 
//              case if ShowOccupationPercentBasedOnInHouseGuests hotel parameter 
//              is true
// Parameters: Spreadsheet where to put data
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmFillOccupationMonitorByRoomInventory(pSpreadsheet, pDate = Undefined) Export
	vDate = pDate;
	If vDate = Undefined Or vDate <> Undefined And BegOfDay(vDate) = BegOfDay(CurrentSessionDate()) Then
		vDate = CurrentSessionDate();
	EndIf;
	
	// Clear spreadsheet
	pSpreadsheet.Clear();
	
	// Show in beds
	vHotel = SessionParameters.CurrentHotel;
	
	vShowInBeds = False;
	vShowSalesWithVAT = False;
	If ValueIsFilled(vHotel) Then
		vShowInBeds = vHotel.ShowReportsInBeds;
		vShowSalesWithVAT = vHotel.ShowSalesInReportsWithVAT;
	EndIf;
	
	// Get monitor template
	vTemplate = GetCommonTemplate("MonitorTemplate");
	
	// Run query to get room inventory statistics
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInventoryBalance.Hotel,
	|	SUM(RoomInventoryBalance.TotalRoomsBalance) AS TotalRoomsBalance,
	|	SUM(RoomInventoryBalance.TotalBedsBalance) AS TotalBedsBalance,
	|	SUM(RoomInventoryBalance.RoomsBlockedBalance) AS RoomsBlockedBalance,
	|	SUM(RoomInventoryBalance.BedsBlockedBalance) AS BedsBlockedBalance,
	|	SUM(RoomInventoryBalance.RoomsVacantBalance) AS RoomsVacantBalance,
	|	SUM(RoomInventoryBalance.BedsVacantBalance) AS BedsVacantBalance,
	|	SUM(RoomInventoryBalance.InHouseGuestsBalance) AS InHouseGuestsBalance,
	|	SUM(RoomInventoryBalance.InHouseBedsBalance) AS InHouseBedsBalance,
	|	SUM(RoomInventoryBalance.InHouseRoomsBalance) AS InHouseRoomsBalance
	|FROM
	|	AccumulationRegister.RoomInventory.Balance(&qPeriodTo, Hotel IN HIERARCHY (&qHotel)) AS RoomInventoryBalance
	|GROUP BY
	|	RoomInventoryBalance.Hotel";
	vQry.SetParameter("qPeriodTo", vDate);
	vQry.SetParameter("qHotel", vHotel);
	vInvResult = vQry.Execute().Unload();
	vInvResult.GroupBy(, "TotalRoomsBalance, TotalBedsBalance, RoomsBlockedBalance, BedsBlockedBalance, RoomsVacantBalance, BedsVacantBalance, InHouseGuestsBalance, InHouseRoomsBalance, InHouseBedsBalance");
	
	vTotalRooms = 0;
	vTotalBeds = 0;
	vRoomsBlocked = 0;
	vBedsBlocked = 0;
	vRoomsVacant = 0;
	vBedsVacant = 0;
	vInHouseGuests = 0;
	vInHouseRooms = 0;
	vInHouseBeds = 0;
	If vInvResult.Count() > 0 Then
		vResultRow = vInvResult.Get(0);
		
		vTotalRooms = vResultRow.TotalRoomsBalance;
		vTotalBeds = vResultRow.TotalBedsBalance;
		vRoomsBlocked = -vResultRow.RoomsBlockedBalance;
		vBedsBlocked = -vResultRow.BedsBlockedBalance;
		vRoomsVacant = vResultRow.RoomsVacantBalance;
		vBedsVacant = vResultRow.BedsVacantBalance;
		vInHouseGuests = -vResultRow.InHouseGuestsBalance;
		vInHouseRooms = -vResultRow.InHouseRoomsBalance;
		vInHouseBeds = -vResultRow.InHouseBedsBalance;
	EndIf;
	
	// Run query to get total room blocks that should be added to the number of total rooms rented
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomBlocksBalance.Hotel,
	|	SUM(RoomBlocksBalance.RoomsBlockedBalance) AS SpecRoomsBlocked,
	|	SUM(RoomBlocksBalance.BedsBlockedBalance) AS SpecBedsBlocked
	|FROM
	|	AccumulationRegister.RoomBlocks.Balance(
	|			&qPeriodTo,
	|			Hotel IN HIERARCHY (&qHotel) AND
	|			RoomBlockType.AddToRoomsRentedInSummaryIndexes) AS RoomBlocksBalance
	|GROUP BY
	|	RoomBlocksBalance.Hotel";
	vQry.SetParameter("qHotel", vHotel);
	vQry.SetParameter("qPeriodTo", vDate);
	vSpecBlocksResult = vQry.Execute().Unload();
	
	vSpecRoomsBlocked = 0;
	vSpecBedsBlocked = 0;
	If vSpecBlocksResult.Count() > 0 Then
		vSpecBlocksResultRow = vSpecBlocksResult.Get(0);
		
		vSpecRoomsBlocked = vSpecBlocksResultRow.SpecRoomsBlocked;
		vSpecBedsBlocked = vSpecBlocksResultRow.SpecBedsBlocked;
	EndIf;
	
	// Fill area A.
	If vShowInBeds Then
		vAreaA = vTemplate.GetArea("TotalBeds");
		vAreaA.Parameters.mTotalBeds = vTotalBeds;
		vAreaA.Parameters.mBedsBlocked = vBedsBlocked - vSpecBedsBlocked;
	Else
		vAreaA = vTemplate.GetArea("TotalRooms");
		vAreaA.Parameters.mTotalRooms = vTotalRooms;
		vAreaA.Parameters.mRoomsBlocked = vRoomsBlocked - vSpecRoomsBlocked;
	EndIf;
	
	// Run query to get room sales for today
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomSales.ReportingCurrency,
	|	SUM(RoomSales.SalesTurnover) AS SalesTurnover,
	|	SUM(RoomSales.SalesWithoutVATTurnover) AS SalesWithoutVATTurnover,
	|	SUM(RoomSales.RoomRevenueTurnover) AS RoomRevenueTurnover,
	|	SUM(RoomSales.RoomRevenueWithoutVATTurnover) AS RoomRevenueWithoutVATTurnover,
	|	SUM(RoomSales.GuestDaysTurnover) AS GuestDaysTurnover,
	|	SUM(RoomSales.RoomsRentedTurnover) AS RoomsRentedTurnover,
	|	SUM(RoomSales.BedsRentedTurnover) AS BedsRentedTurnover
	|FROM
	|	(SELECT
	|		RoomSalesTurnovers.ReportingCurrency AS ReportingCurrency,
	|		RoomSalesTurnovers.SalesTurnover AS SalesTurnover,
	|		RoomSalesTurnovers.SalesWithoutVATTurnover AS SalesWithoutVATTurnover,
	|		RoomSalesTurnovers.RoomRevenueTurnover AS RoomRevenueTurnover,
	|		RoomSalesTurnovers.RoomRevenueWithoutVATTurnover AS RoomRevenueWithoutVATTurnover,
	|		RoomSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover,
	|		RoomSalesTurnovers.RoomsRentedTurnover AS RoomsRentedTurnover,
	|		RoomSalesTurnovers.BedsRentedTurnover AS BedsRentedTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(&qPeriodFrom, &qPeriodTo, Day, Hotel IN HIERARCHY (&qHotel)) AS RoomSalesTurnovers
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RoomSalesForecastTurnovers.ReportingCurrency,
	|		RoomSalesForecastTurnovers.SalesTurnover,
	|		RoomSalesForecastTurnovers.SalesWithoutVATTurnover,
	|		RoomSalesForecastTurnovers.RoomRevenueTurnover,
	|		RoomSalesForecastTurnovers.RoomRevenueWithoutVATTurnover,
	|		RoomSalesForecastTurnovers.GuestDaysTurnover,
	|		RoomSalesForecastTurnovers.RoomsRentedTurnover,
	|		RoomSalesForecastTurnovers.BedsRentedTurnover
	|	FROM
	|		AccumulationRegister.SalesForecast.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Day,
	|				NOT &qDateIsInThePast
	|					AND Hotel IN HIERARCHY (&qHotel)
	|					AND ParentDoc REFS Document.Accommodation) AS RoomSalesForecastTurnovers) AS RoomSales
	|
	|GROUP BY
	|	RoomSales.ReportingCurrency
	|
	|ORDER BY
	|	RoomSales.ReportingCurrency.SortCode";
	vQry.SetParameter("qPeriodFrom", BegOfDay(vDate));
	vQry.SetParameter("qPeriodTo", EndOfDay(vDate));
	vForecastStartDate = tcOnServer.GetForecastStartDate(vHotel);
	vQry.SetParameter("qDateIsInthePast", ?(BegOfDay(vDate) < BegOfDay(vForecastStartDate), True, False));
	vQry.SetParameter("qHotel", vHotel);
	vSalesResult = vQry.Execute().Unload();
	
	// Fill area C.D.E.
	If vShowInBeds Then
		vAreaCDE = vTemplate.GetArea("BedsInHouse|First2Columns");
		vDiagramCDE = vTemplate.GetArea("BedsInHouse|Last3Column");
		vDiagram = vDiagramCDE.Area("BedsInHouseMeter").Object;
		
		vAreaCDE.Parameters.mBedsInHouse = vInHouseBeds + vSpecBedsBlocked;
	Else
		vAreaCDE = vTemplate.GetArea("RoomsInHouse|First2Columns");
		vDiagramCDE = vTemplate.GetArea("RoomsInHouse|Last3Column");
		vDiagram = vDiagramCDE.Area("RoomsInHouseMeter").Object;
		
		vAreaCDE.Parameters.mRoomsInHouse = vInHouseRooms + vSpecRoomsBlocked;
	EndIf;
	
	If vShowInBeds Then
		If (vTotalBeds - vBedsBlocked + vSpecBedsBlocked) = 0 Then 
			vAreaCDE.Parameters.mOccupationPercent = 0;
		Else
			vAreaCDE.Parameters.mOccupationPercent = Round(100*(vInHouseBeds + vSpecBedsBlocked)/(vTotalBeds - vBedsBlocked + vSpecBedsBlocked), 2);
		EndIf;
	Else
		If (vTotalRooms - vRoomsBlocked + vSpecRoomsBlocked) = 0 Then 
			vAreaCDE.Parameters.mOccupationPercent = 0;
		Else
			vAreaCDE.Parameters.mOccupationPercent = Round(100*(vInHouseRooms + vSpecRoomsBlocked)/(vTotalRooms - vRoomsBlocked + vSpecRoomsBlocked), 2);
		EndIf;
	EndIf;
	
	vAreaCDE.Parameters.mInHouseGuests = vInHouseGuests;
	
	// Get occupation percent meter
	vDiagram.RefreshEnabled = False;
	vDiagram.AutoSeriesText = False;
	vDiagram.AutoPointText = False;
	vDiagram.Clear();
	vSeria = vDiagram.Series.Add(NStr("en='Occupancy %'; ru='% Загрузки'; de='% die Belegung'"));
	If vShowInBeds Then
		vPoint = vDiagram.Points.Add(NStr("en='By beds in-house';ru='По занятым местам';de='Nach besetzten Betten'"));
	Else
		vPoint = vDiagram.Points.Add(NStr("en='By rooms in-house';ru='По занятым номерам';de='Nach belegten Zimmern'"));
	EndIf;
	mOccupationPercent = vAreaCDE.Parameters.mOccupationPercent;
	vDiagram.SetValue(vPoint, vSeria, Min(?(mOccupationPercent < 0, 0, mOccupationPercent), 100));
	vDiagram.RefreshEnabled = True;

	// Do output	
	vArea = vTemplate.GetArea("StatisticsMonitorHeaderInHouse");
	pSpreadsheet.Put(vArea);
	
	// Output section A
	pSpreadsheet.Put(vAreaA);
	// Output section C
	pSpreadsheet.Put(vAreaCDE);
	pSpreadsheet.Join(vDiagramCDE);
	
	// Output section F
	If vShowSalesWithVAT Then
		vAreaFHeader = vTemplate.GetArea("SalesHeaderWithVAT");
	Else
		vAreaFHeader = vTemplate.GetArea("SalesHeader");
	EndIf;
	pSpreadsheet.Put(vAreaFHeader);
	
	vAreaF = vTemplate.GetArea("Sales");
	For Each vSalesResultRow In vSalesResult Do
		If vShowSalesWithVAT Then
			vAreaF.Parameters.mSales = vSalesResultRow.SalesTurnover;
			vAreaF.Parameters.mRoomRevenue = vSalesResultRow.RoomRevenueTurnover;
		Else
			vAreaF.Parameters.mSales = vSalesResultRow.SalesWithoutVATTurnover;
			vAreaF.Parameters.mRoomRevenue = vSalesResultRow.RoomRevenueWithoutVATTurnover;
		EndIf;
		vAreaF.Parameters.mCurrency = cmGetCurrencyPresentation(vSalesResultRow.ReportingCurrency);
		
		pSpreadsheet.Put(vAreaF);
	EndDo;
	
	// Output section G
	If vShowInBeds Then
		vAreaGHeader = vTemplate.GetArea("AverageBedInventoryStatisticsHeader");
	Else
		vAreaGHeader = vTemplate.GetArea("AverageRoomInventoryStatisticsHeader");
	EndIf;
	pSpreadsheet.Put(vAreaGHeader);
	
	If vShowInBeds Then
		vAreaG = vTemplate.GetArea("AverageBedInventoryStatistics");
	Else
		vAreaG = vTemplate.GetArea("AverageRoomInventoryStatistics");
	EndIf;
	For Each vSalesResultRow In vSalesResult Do
		If vShowSalesWithVAT Then
			If vShowInBeds Then
				If vSalesResultRow.BedsRentedTurnover = 0 Then
					vAreaG.Parameters.mAvgBedPrice = 0;
				Else
					vAreaG.Parameters.mAvgBedPrice = Round(vSalesResultRow.RoomRevenueTurnover/vSalesResultRow.BedsRentedTurnover, 2);
				EndIf;
			Else
				If vSalesResultRow.RoomsRentedTurnover = 0 Then
					vAreaG.Parameters.mAvgRoomPrice = 0;
				Else
					vAreaG.Parameters.mAvgRoomPrice = Round(vSalesResultRow.RoomRevenueTurnover/vSalesResultRow.RoomsRentedTurnover, 2);
				EndIf;
			EndIf;
		Else
			If vShowInBeds Then
				If vSalesResultRow.BedsRentedTurnover = 0 Then
					vAreaG.Parameters.mAvgBedPrice = 0;
				Else
					vAreaG.Parameters.mAvgBedPrice = Round(vSalesResultRow.RoomRevenueWithoutVATTurnover/vSalesResultRow.BedsRentedTurnover, 2);
				EndIf;
			Else
				If vSalesResultRow.RoomsRentedTurnover = 0 Then
					vAreaG.Parameters.mAvgRoomPrice = 0;
				Else
					vAreaG.Parameters.mAvgRoomPrice = Round(vSalesResultRow.RoomRevenueWithoutVATTurnover/vSalesResultRow.RoomsRentedTurnover, 2);
				EndIf;
			EndIf;
		EndIf;
		vAreaG.Parameters.mCurrency = cmGetCurrencyPresentation(vSalesResultRow.ReportingCurrency);
		
		pSpreadsheet.Put(vAreaG);
	EndDo;
EndProcedure // cmFillOccupationMonitorByRoomInventory

// -----------------------------------------------------------------------------
// Description: Fills main menu desktop Customers region with data
// Parameters: Spreadsheet where to put data
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmFillCustomersMonitor(pSpreadsheet, pDate = Undefined) Export
	vDate = pDate;
	If vDate = Undefined Then
		vDate = CurrentSessionDate();
	EndIf;
	
	// Show with or without VAT
	vHotel = SessionParameters.CurrentHotel;
	
	vShowSalesWithVAT = False;
	If ValueIsFilled(vHotel) Then
		vShowSalesWithVAT = vHotel.ShowSalesInReportsWithVAT;
	EndIf;
	
	// Clear spreadsheet
	pSpreadsheet.Clear();
	
	// Get monitor template
	vTemplate = GetCommonTemplate("MonitorTemplate");
	vArea = vTemplate.GetArea("CustomersMonitorHeader");
	pSpreadsheet.Put(vArea);
	
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CustomerSales.Customer,
	|	CustomerSales.ReportingCurrency,
	|	SUM(CustomerSales.SalesTurnover) AS SalesTurnover,
	|	SUM(CustomerSales.CommissionSumTurnover) AS CommissionSumTurnover,
	|	SUM(CustomerSales.SalesWithoutVATTurnover) AS SalesWithoutVATTurnover,
	|	SUM(CustomerSales.CommissionSumWithoutVATTurnover) AS CommissionSumWithoutVATTurnover,
	|	SUM(CustomerSales.DiscountSumTurnover) AS DiscountSumTurnover,
	|	SUM(CustomerSales.DiscountSumWithoutVATTurnover) AS DiscountSumWithoutVATTurnover
	|FROM
	|	(SELECT
	|		SalesTurnovers.Customer AS Customer,
	|		SalesTurnovers.ReportingCurrency AS ReportingCurrency,
	|		SalesTurnovers.SalesTurnover AS SalesTurnover,
	|		SalesTurnovers.CommissionSumTurnover AS CommissionSumTurnover,
	|		SalesTurnovers.SalesWithoutVATTurnover AS SalesWithoutVATTurnover,
	|		SalesTurnovers.CommissionSumWithoutVATTurnover AS CommissionSumWithoutVATTurnover,
	|		SalesTurnovers.DiscountSumTurnover AS DiscountSumTurnover,
	|		SalesTurnovers.DiscountSumWithoutVATTurnover AS DiscountSumWithoutVATTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(&qPeriodFrom, &qPeriodTo, PERIOD, Hotel IN HIERARCHY (&qHotel)) AS SalesTurnovers
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ExpectedSalesTurnovers.Customer,
	|		ExpectedSalesTurnovers.ReportingCurrency,
	|		ExpectedSalesTurnovers.SalesTurnover,
	|		ExpectedSalesTurnovers.CommissionSumTurnover,
	|		ExpectedSalesTurnovers.SalesWithoutVATTurnover,
	|		ExpectedSalesTurnovers.CommissionSumWithoutVATTurnover,
	|		ExpectedSalesTurnovers.DiscountSumTurnover,
	|		ExpectedSalesTurnovers.DiscountSumWithoutVATTurnover
	|	FROM
	|		AccumulationRegister.SalesForecast.Turnovers(&qPeriodFrom, &qPeriodTo, PERIOD, NOT &qDateIsInThePast AND Hotel IN HIERARCHY (&qHotel)) AS ExpectedSalesTurnovers) AS CustomerSales
	|
	|GROUP BY
	|	CustomerSales.Customer,
	|	CustomerSales.ReportingCurrency
	|
	|ORDER BY
	|	CustomerSales.ReportingCurrency.SortCode,
	|	SalesTurnover DESC,
	|	CustomerSales.Customer.Description";
	vQry.SetParameter("qPeriodFrom", BegOfDay(vDate));
	vQry.SetParameter("qPeriodTo", EndOfDay(vDate));
	vForecastStartDate = tcOnServer.GetForecastStartDate(vHotel);
	vQry.SetParameter("qDateIsInthePast", ?(BegOfDay(vDate) < BegOfDay(vForecastStartDate), True, False));
	vQry.SetParameter("qHotel", vHotel);
	vQryResult = vQry.Execute().Unload();
	
	// Do top 5 output
	i = 0;
	vArea = vTemplate.GetArea("Customer");
	For Each vQryResultRow In vQryResult Do
		If i < 5 Then
			If ValueIsFilled(vQryResultRow.Customer) Then
				vArea.Parameters.mCustomer = vQryResultRow.Customer;
				vArea.Parameters.mCustomerRef = vQryResultRow.Customer;
			Else
				vArea.Parameters.mCustomer = NStr("en='<Persons>';ru='<Физические лица>';de='<Natürliche Personen>'");
				vArea.Parameters.mCustomerRef = Undefined;
			EndIf;
			vArea.Parameters.mCurrency = cmGetCurrencyPresentation(vQryResultRow.ReportingCurrency);
			If vShowSalesWithVAT Then
				vArea.Parameters.mSales = vQryResultRow.SalesTurnover;
				vArea.Parameters.mCommission = vQryResultRow.CommissionSumTurnover;
			Else
				vArea.Parameters.mSales = vQryResultRow.SalesWithoutVATTurnover;
				vArea.Parameters.mCommission = vQryResultRow.CommissionSumWithoutVATTurnover;
			EndIf;
			
			pSpreadsheet.Put(vArea);
			
			i = i + 1;
		Else
			Break;
		EndIf;
	EndDo;
	
	// Group all other customers into one row
	If i = 5 Then
		// Delete top 5 rows
		i = 0;
		While i < 5 Do
			vQryResult.Delete(0);
			i = i + 1;
		EndDo;
		// Group all other
		vQryResult.GroupBy("ReportingCurrency", "SalesTurnover, SalesWithoutVATTurnover, CommissionSumTurnover, CommissionSumWithoutVATTurnover, DiscountSumTurnover");
		vQryResult.Sort("ReportingCurrency Asc, SalesTurnover Desc");
		For Each vQryResultRow In vQryResult Do
			vArea.Parameters.mCustomer = NStr("en='<All other>';ru='<Все остальные>';de='<Alle anderen>'");
			vArea.Parameters.mCustomerRef = Undefined;
			vArea.Parameters.mCurrency = cmGetCurrencyPresentation(vQryResultRow.ReportingCurrency);
			
			If vShowSalesWithVAT Then
				vArea.Parameters.mSales = vQryResultRow.SalesTurnover;
				vArea.Parameters.mCommission = vQryResultRow.CommissionSumTurnover;
			Else
				vArea.Parameters.mSales = vQryResultRow.SalesWithoutVATTurnover;
				vArea.Parameters.mCommission = vQryResultRow.CommissionSumWithoutVATTurnover;
			EndIf;
			
			pSpreadsheet.Put(vArea);
		EndDo;
	EndIf;
EndProcedure // cmFillCustomersMonitor

// -----------------------------------------------------------------------------
// Description: Fills main menu desktop Debtors region with data
// Parameters: Spreadsheet where to put data
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmFillDebtorsMonitor(pSpreadsheet, pDate = Undefined) Export
	vDate = pDate;
	If vDate = Undefined Then
		vDate = CurrentSessionDate();
	EndIf;
	
	// Clear spreadsheet
	pSpreadsheet.Clear();
	
	// Get monitor template
	vTemplate = GetCommonTemplate("MonitorTemplate");
	vArea = vTemplate.GetArea("DebtorsMonitorHeader");
	pSpreadsheet.Put(vArea);
	
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CustomerAccounts.AccountingCustomer AS AccountingCustomer,
	|	CustomerAccounts.AccountingCurrency AS AccountingCurrency,
	|	SUM(CustomerAccounts.SumBalance) AS SumBalance
	|FROM
	|	(SELECT
	|		CustomerAccountsBalance.AccountingCustomer AS AccountingCustomer,
	|		CustomerAccountsBalance.AccountingCurrency AS AccountingCurrency,
	|		CustomerAccountsBalance.SumBalance AS SumBalance
	|	FROM
	|		AccumulationRegister.CustomerAccounts.Balance(
	|				&qPeriodTo,
	|				Hotel = &qHotel
	|					OR &qHotelIsEmpty) AS CustomerAccountsBalance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CASE
	|			WHEN CurrentAccountsReceivableBalance.Customer = &qEmptyCustomer
	|				THEN &qIndividualsCustomer
	|			ELSE CurrentAccountsReceivableBalance.Customer
	|		END,
	|		CurrentAccountsReceivableBalance.FolioCurrency,
	|		CurrentAccountsReceivableBalance.SumBalance - CurrentAccountsReceivableBalance.CommissionSumBalance
	|	FROM
	|		AccumulationRegister.CurrentAccountsReceivable.Balance(
	|				&qPeriodTo,
	|				&qShowCurrentAccountsReceivable
	|					AND (Hotel = &qHotel
	|						OR &qHotelIsEmpty)) AS CurrentAccountsReceivableBalance) AS CustomerAccounts
	|
	|GROUP BY
	|	CustomerAccounts.AccountingCustomer,
	|	CustomerAccounts.AccountingCurrency
	|
	|ORDER BY
	|	SumBalance DESC,
	|	CustomerAccounts.AccountingCustomer.Description,
	|	CustomerAccounts.AccountingCurrency.SortCode";
	vQry.SetParameter("qPeriodTo", EndOfDay(vDate));
	vQry.SetParameter("qHotel", SessionParameters.CurrentHotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(SessionParameters.CurrentHotel));
	vQry.SetParameter("qShowCurrentAccountsReceivable", ?(ValueIsFilled(SessionParameters.CurrentHotel), SessionParameters.CurrentHotel.ShowCurrentAccountsReceivable, False));
	vQry.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	vQry.SetParameter("qIndividualsCustomer", ?(ValueIsFilled(SessionParameters.CurrentHotel), SessionParameters.CurrentHotel.IndividualsCustomer, Catalogs.Customers.EmptyRef()));
	vQryResult = vQry.Execute().Unload();
	
	// Do top 5 output
	i = 0;
	vArea = vTemplate.GetArea("Debtor");
	For Each vQryResultRow In vQryResult Do
		If i < 5 Then
			vArea.Parameters.mCustomer = vQryResultRow.AccountingCustomer;
			vArea.Parameters.mCustomerRef = vQryResultRow.AccountingCustomer;
			vArea.Parameters.mCurrency = cmGetCurrencyPresentation(vQryResultRow.AccountingCurrency);
			vArea.Parameters.mSum = vQryResultRow.SumBalance;
			
			pSpreadsheet.Put(vArea);
			
			i = i + 1;
		Else
			Break;
		EndIf;
	EndDo;
	
	// Group all other customers into one row
	If i = 5 Then
		// Delete top 5 rows
		i = 0;
		While i < 5 Do
			vQryResult.Delete(0);
			i = i + 1;
		EndDo;
		// Group all other
		vQryResult.GroupBy("AccountingCurrency", "SumBalance");
		vQryResult.Sort("SumBalance Desc");
		For Each vQryResultRow In vQryResult Do
			vArea.Parameters.mCustomer = NStr("en='<All other>';ru='<Все остальные>';de='<Alle anderen>'");
			vArea.Parameters.mCustomerRef = Undefined;
			vArea.Parameters.mCurrency = cmGetCurrencyPresentation(vQryResultRow.AccountingCurrency);
			vArea.Parameters.mSum = vQryResultRow.SumBalance;
			
			pSpreadsheet.Put(vArea);
		EndDo;
	EndIf;
EndProcedure // cmFillDebtorsMonitor

// -----------------------------------------------------------------------------
// Description: Fills main menu desktop Room statuses region with data
// Parameters: Spreadsheet where to put data
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmFillRoomStatusesMonitor(pSpreadsheet) Export
	// Clear spreadsheet
	pSpreadsheet.Clear();
	
	// Get monitor template
	vTemplate = GetCommonTemplate("MonitorTemplate");
	vArea = vTemplate.GetArea("RoomStatusesMonitorHeader");
	pSpreadsheet.Put(vArea);
	
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Rooms.RoomStatus,
	|	COUNT(Rooms.RoomStatus) AS Quantity
	|FROM
	|	Catalog.Rooms AS Rooms
	|WHERE
	|	Rooms.Owner IN HIERARCHY(&qHotel)
	|	AND (NOT Rooms.IsFolder)
	|	AND (NOT Rooms.DeletionMark)
	|	AND Rooms.OperationStartDate <= &qPeriod
	|	AND (Rooms.OperationEndDate = &qEmptyDate
	|			OR Rooms.OperationEndDate >= &qPeriod)
	|
	|GROUP BY
	|	Rooms.RoomStatus
	|
	|ORDER BY
	|	Rooms.RoomStatus.SortCode,
	|	Rooms.RoomStatus.Description";
	vQry.SetParameter("qPeriod", BegOfDay(CurrentSessionDate()));
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qHotel", SessionParameters.CurrentHotel);
	vQryResult = vQry.Execute().Unload();
	
	// Do output
	vArea = vTemplate.GetArea("RoomStatus");
	For Each vQryResultRow In vQryResult Do
		If ValueIsFilled(vQryResultRow.RoomStatus) Then
			vArea.Parameters.mRoomStatus = vQryResultRow.RoomStatus;
			vArea.Parameters.mRoomStatusRef = vQryResultRow.RoomStatus;
		Else
			vArea.Parameters.mRoomStatus = NStr("en='<Empty status>';ru='<Пустой статус>';de='<Leerer Status>'");
			vArea.Parameters.mRoomStatusRef = Undefined;
		EndIf;
		vArea.Parameters.mQuantity = vQryResultRow.Quantity;
		
		pSpreadsheet.Put(vArea);
	EndDo;
EndProcedure // cmFillRoomStatusesMonitor

// -----------------------------------------------------------------------------
// Description: Fills main menu desktop Check-in region with data
// Parameters: Spreadsheet where to put data
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmFillGroupStatusMonitor(pSpreadsheet, pEmployee) Export
	// Clear spreadsheet
	pSpreadsheet.Clear();
	
	// Get current hotel
	vHotel = SessionParameters.CurrentHotel;
	
	// Get monitor template
	vTemplate = GetCommonTemplate("MonitorTemplate");
	
	vArea = vTemplate.GetArea("GroupStatusesMonitorHeader");
	pSpreadsheet.Put(vArea);
	
	vArea = vTemplate.GetArea("GroupStatus");
	
	// Get list of statuses that are interesting to the sales managers
	vStatusesList = cmGetSalesGuestGroupStatuses();
	
	// Run query to get room status statistics
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	GuestGroups.Status AS Status,
	|	CASE
	|		WHEN GuestGroups.Status.IsPreliminary
	|				AND (NOT GuestGroups.Status.IsActive)
	|			THEN 1
	|		WHEN GuestGroups.Status.IsPreliminary
	|				AND GuestGroups.Status.IsActive
	|			THEN 2
	|		WHEN (NOT GuestGroups.Status.IsPreliminary)
	|				AND GuestGroups.Status.IsActive
	|			THEN 3
	|		ELSE 4
	|	END AS TypeSortOrder,
	|	GuestGroups.Status.SortCode AS StatusSortOrder,
	|	GuestGroups.Status.Description AS StatusDescription,
	|	SUM(GuestGroups.GuestsCheckedIn) AS NumberOfGuests,
	|	COUNT(GuestGroups.Ref) AS NumberOfGroups
	|FROM
	|	Catalog.GuestGroups AS GuestGroups
	|WHERE
	|	(NOT GuestGroups.DeletionMark)
	|	AND GuestGroups.Owner = &qHotel
	|	AND (GuestGroups.Author = &qEmployee
	|			OR &qEmployeeIsEmpty)
	|	AND GuestGroups.CheckInDate >= &qPeriodFrom
	|	AND GuestGroups.Status IN(&qStatuses)
	|
	|GROUP BY
	|	GuestGroups.Status,
	|	CASE
	|		WHEN GuestGroups.Status.IsPreliminary
	|				AND (NOT GuestGroups.Status.IsActive)
	|			THEN 1
	|		WHEN GuestGroups.Status.IsPreliminary
	|				AND GuestGroups.Status.IsActive
	|			THEN 2
	|		WHEN (NOT GuestGroups.Status.IsPreliminary)
	|				AND GuestGroups.Status.IsActive
	|			THEN 3
	|		ELSE 4
	|	END,
	|	GuestGroups.Status.SortCode,
	|	GuestGroups.Status.Description
	|
	|ORDER BY
	|	TypeSortOrder,
	|	StatusSortOrder,
	|	StatusDescription";
	vQry.SetParameter("qPeriodFrom", BegOfDay(CurrentSessionDate()));
	vQry.SetParameter("qHotel", vHotel);
	vQry.SetParameter("qEmployee", pEmployee);
	vQry.SetParameter("qEmployeeIsEmpty", Not ValueIsFilled(pEmployee));
	vQry.SetParameter("qStatuses", vStatusesList);
	vStatuses = vQry.Execute().Unload();
	
	// Do output
	vTotalGroups = 0;
	vTotalGuests = 0;
	For Each vStatusesRow In vStatuses Do
		vArea.Parameters.mGroupStatus = vStatusesRow.Status;
		vArea.Parameters.mGroups = vStatusesRow.NumberOfGroups;
		vArea.Parameters.mGuests = vStatusesRow.NumberOfGuests;
		
		vTotalGroups = vTotalGroups + vStatusesRow.NumberOfGroups;
		vTotalGuests = vTotalGuests + vStatusesRow.NumberOfGuests;
	
		pSpreadsheet.Put(vArea);
	EndDo;
	vArea = vTemplate.GetArea("GroupStatusTotals");
	vArea.Parameters.mTotalGroups = vTotalGroups;
	vArea.Parameters.mTotalGuests = vTotalGuests;
	pSpreadsheet.Put(vArea);
	
	// Fill group status diagram
	vArea = vTemplate.GetArea("GroupStatusesDiagram");
	vDiagram = vArea.Area("GroupStatusesStats").Object;
	vDiagram.RefreshEnabled = False;
	vDiagram.Clear();
	vDiagram.LabelTextColor = StyleColors.FieldSelectedTextColor;
	vGroupCountSeria = vDiagram.Series.Add(NStr("en='Groups q-ty';ru='Кол-во групп';de='Gruppenanzahl'"));
	vGroupCountSeria.Color = StyleColors.FieldSelectionBackColor;
	vGroupCountSeria.ColorPriority = True;
	i = vStatuses.Count() - 1;
	While i >= 0 Do
		vStatusesRow = vStatuses.Get(i);
		vStatusPoint = vDiagram.Points.Add(TrimAll(vStatusesRow.Status));
		vStatusPoint.Details = vStatusesRow.Status;
		vStatusPoint.Value = vStatusesRow.Status;
		vDiagram.SetValue(vStatusPoint, vGroupCountSeria, vStatusesRow.NumberOfGroups, vStatusesRow.Status, TrimAll(vStatusesRow.Status));
		i = i - 1;
	EndDo;
	vDiagram.RefreshEnabled = True;
	pSpreadsheet.Put(vArea);
EndProcedure // cmFillGroupStatusMonitor

// -----------------------------------------------------------------------------
// Description: Shows payment method confirmation dialog when OK button is pressed
//              in payments
// Parameters: Payment document object
// Return value: True to continue document posting, False to cancel operation
// -----------------------------------------------------------------------------
Function cmConfirmPaymentMethodChoice(pObj) Export
	If ValueIsFilled(SessionParameters.CurrentUser) Then
		If ValueIsFilled(SessionParameters.CurrentUser.EmployeePreferences) Then
			If SessionParameters.CurrentUser.EmployeePreferences.AskForPaymentMethodConfirmation Then
				vQuery = NStr("ru = 'В документе выбран способ оплаты
				              |
				              |" + Upper(TrimAll(pObj.PaymentMethod)) + ".
				              |
				              |Вы подтверждаете выбор этого способа оплаты?
				              |
				              |Ответ ""Да"" - провести документ" + ?(ValueIsFilled(pObj.CashRegister), " по ККМ " + Upper(TrimAll(pObj.CashRegister)) + ".", ".") + "
				              |Ответ ""Нет"" - вернуться в режим редактирования документа.'; 
							  |de = 'You have choosen 
				              |
				              |" + Upper(TrimAll(pObj.PaymentMethod)) + " payment method.
				              |
				              |Would you like to confirm your choice?
				              |
				              |Answer ""Yes"" to post document" + ?(ValueIsFilled(pObj.CashRegister), " by " + Upper(TrimAll(pObj.CashRegister)) + " cash register.", ".") + "
				              |Answer ""No"" to return to the document form.';
							  |en = 'You have choosen 
				              |
				              |" + Upper(TrimAll(pObj.PaymentMethod)) + " payment method.
				              |
				              |Would you like to confirm your choice?
				              |
				              |Answer ""Yes"" to post document" + ?(ValueIsFilled(pObj.CashRegister), " by " + Upper(TrimAll(pObj.CashRegister)) + " cash register.", ".") + "
				              |Answer ""No"" to return to the document form.'");
				If DoQueryBox(vQuery, QuestionDialogMode.YesNo, , DialogReturnCode.No) = DialogReturnCode.No Then
					Return False;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	Return True;
EndFunction // cmConfirmPaymentMethodChoice

// -----------------------------------------------------------------------------
// Description: Opens current user preferences catalog item form
// Parameters: None
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmOpenCurrentUserPreferences() Export
	vCurEmpPrefRef = Catalogs.EmployeePreferences.EmptyRef();
	If ValueIsFilled(SessionParameters.CurrentUser) Then
		If ValueIsFilled(SessionParameters.CurrentUser.EmployeePreferences) Then
			vCurEmpPrefRef = SessionParameters.CurrentUser.EmployeePreferences;
		Else
			// Create new one
			vCurEmpPrefObj = Catalogs.EmployeePreferences.CreateItem();
			vCurEmpPrefObj.Description = SessionParameters.CurrentUser.Description;
			vCurEmpPrefObj.Write();
			vCurEmpPrefRef = vCurEmpPrefObj.Ref;
			
			vCurEmpObj = SessionParameters.CurrentUser.GetObject();
			vCurEmpObj.EmployeePreferences = vCurEmpPrefRef;
			vCurEmpObj.Write();
		EndIf;
		// Open preferences item form
		If ValueIsFilled(vCurEmpPrefRef) Then
			vFrm = vCurEmpPrefRef.GetForm();
			vFrm.PasswordChangeAllowed = True;
			vFrm.Open();
		EndIf;
	EndIf;
EndProcedure // cmOpenCurrentUserPreferences

// -----------------------------------------------------------------------------
// Description: Checks if there are any active object print forms. If yes then
//              object form "Print" button is enabled and visible, otherwise not
// Parameters: Object form, Object type (empty ref)
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmLoadFormPrintButton(pForm, pObjectType) Export
	vForms = cmGetObjectPrintingForms(pObjectType, Undefined);
	// Print button
	vButtonPrint = pForm.Controls.ButtonPrint;
	If vForms.Count() = 0 Then
		vButtonPrint.Enabled = False;
		vButtonPrint.Visible = False;
	Else
		vButtonPrint.Enabled = True;
		vButtonPrint.Visible = True;
	EndIf;
EndProcedure // cmLoadFormPrintButton

// -----------------------------------------------------------------------------
// Description: Loads form action buttons defined for the given object type
// Parameters: Object form, Object type (empty ref), If yes then no action buttons 
//             will be shown
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmLoadFormActionButtons(pForm, pObjectType, pNoButtons = False) Export
	// Get object actions
	vActions = cmGetObjectActions(pObjectType, Undefined);
	// Other actions button
	vButtonActionsArray = vActions.FindRows(New Structure("ObjectFormActionButton", Enums.ObjectFormActionButtons.EmptyRef()));
	vButtonActions = pForm.Controls.ButtonActions;
	If vButtonActionsArray.Count() = 0 Then
		vButtonActions.Enabled = False;
		vButtonActions.Visible = False;
	Else
		vButtonActions.Enabled = True;
		vButtonActions.Visible = True;
	EndIf;
	If Not pNoButtons Then
		// Button 1
		vButton1Action = vActions.Find(Enums.ObjectFormActionButtons.Button1, "ObjectFormActionButton");
		vButton1 = pForm.Controls.Button1;
		cmSetButtonAttributes(vButton1, vButton1Action, pForm.Button1Action);
		// Button 2
		vButton2Action = vActions.Find(Enums.ObjectFormActionButtons.Button2, "ObjectFormActionButton");
		vButton2 = pForm.Controls.Button2;
		cmSetButtonAttributes(vButton2, vButton2Action, pForm.Button2Action);
		// Button 3
		vButton3Action = vActions.Find(Enums.ObjectFormActionButtons.Button3, "ObjectFormActionButton");
		vButton3 = pForm.Controls.Button3;
		cmSetButtonAttributes(vButton3, vButton3Action, pForm.Button3Action);
	EndIf;
EndProcedure // cmLoadFormActionButtons

// -----------------------------------------------------------------------------
// Description: Processes report columns page on row output event
// Parameters: Report object, Table of report columns, Row appearance, Row data
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmReportColumnsOnRowOutput(pRepObject, pControl, pRowAppearance, pRowData) Export
	If pRepObject.ReportColumnOverrides.Count() > 0 And 
	   pRepObject.ReportColumnOverrides.Columns.Count() > 0 Then
		vOverrideRow = Undefined;
		If pRepObject.ReportColumnOverrides.Columns.Find("ColumnDataPath") <> Undefined Then
			vOverrideRow = pRepObject.ReportColumnOverrides.Find(pRowData.DataPath, "ColumnDataPath");
		EndIf;
		If vOverrideRow = Undefined Then
			vOverrideRow = pRepObject.ReportColumnOverrides.Find(pRowData.Name, "ColumnName");
		EndIf;
		If vOverrideRow <> Undefined Then
			Try
				If vOverrideRow.ColumnWidth > 0 Then
					If pControl.Columns.ColumnWidth.Visible Then
						pRowAppearance.Cells.ColumnWidth.ShowText = True;
						pRowAppearance.Cells.ColumnWidth.Text = Format(vOverrideRow.ColumnWidth, "ND=6; NFD=2");
					EndIf;
				EndIf;
				If ValueIsFilled(vOverrideRow.ColumnHeaderDescription) Then
					If pControl.Columns.ColumnHeaderDescription.Visible Then
						pRowAppearance.Cells.ColumnHeaderDescription.ShowText = True;
						pRowAppearance.Cells.ColumnHeaderDescription.Text = TrimAll(vOverrideRow.ColumnHeaderDescription);
					EndIf;
				EndIf;
				If ValueIsFilled(vOverrideRow.ColumnFormat) Then
					If pControl.Columns.ColumnFormat.Visible Then
						pRowAppearance.Cells.ColumnFormat.ShowText = True;
						pRowAppearance.Cells.ColumnFormat.Text = TrimAll(vOverrideRow.ColumnFormat);
					EndIf;
				EndIf;
				If ValueIsFilled(vOverrideRow.ColumnTextPlacement) Then
					If pControl.Columns.ColumnTextPlacement.Visible Then
						pRowAppearance.Cells.ColumnTextPlacement.ShowText = True;
						pRowAppearance.Cells.ColumnTextPlacement.Text = TrimAll(vOverrideRow.ColumnTextPlacement);
					EndIf;
				EndIf;
				If pControl.Columns.Find("ShowInChart") <> Undefined Then
					If pControl.Columns.ShowInChart.Visible Then
						pRowAppearance.Cells.ShowInChart.CheckValue = vOverrideRow.ShowInChart;
						pRowAppearance.Cells.ShowInChart.ShowText = True;
						If vOverrideRow.ShowInChart Then
							pRowAppearance.Cells.ShowInChart.Text = NStr("en='+'; de='+'; ru='+'");
						Else
							pRowAppearance.Cells.ShowInChart.Text = "";
						EndIf;
					EndIf;
				EndIf;
			Except
			EndTry;
		EndIf;
	EndIf;
EndProcedure // cmReportColumnsOnRowOutput

// -----------------------------------------------------------------------------
// Description: Processes report columns page on start edit event
// Parameters: Report object, Report settings form, Table of report columns, 
//             If this is new row, If this is clone operation
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmReportColumnsOnStartEdit(pRepObject, pRepSettingsForm, pControl, pNewRow, pClone) Export
	vWithChart = False;
	If pRepSettingsForm.Controls.Columns.Columns.Find("ShowInChart") <> Undefined Then
		vWithChart = True;
	EndIf;
	// Check if report ReportColumnOverrides attribute is initialized
	If pRepObject.ReportColumnOverrides.Columns.Find("ColumnName") = Undefined Then
		pRepObject.ReportColumnOverrides.Columns.Add("ColumnName", cmGetStringTypeDescription());
	EndIf;
	If pRepObject.ReportColumnOverrides.Columns.Find("ColumnDataPath") = Undefined Then
		pRepObject.ReportColumnOverrides.Columns.Add("ColumnDataPath", cmGetStringTypeDescription());
	EndIf;
	If pRepObject.ReportColumnOverrides.Columns.Find("ColumnWidth") = Undefined Then
		pRepObject.ReportColumnOverrides.Columns.Add("ColumnWidth", cmGetNumberTypeDescription(6, 2));
	EndIf;
	If pRepObject.ReportColumnOverrides.Columns.Find("ColumnHeaderDescription") = Undefined Then
		pRepObject.ReportColumnOverrides.Columns.Add("ColumnHeaderDescription", cmGetStringTypeDescription());
	EndIf;
	If pRepObject.ReportColumnOverrides.Columns.Find("ColumnFormat") = Undefined Then
		pRepObject.ReportColumnOverrides.Columns.Add("ColumnFormat", cmGetStringTypeDescription());
	EndIf;
	If pRepObject.ReportColumnOverrides.Columns.Find("ColumnTextPlacement") = Undefined Then
		pRepObject.ReportColumnOverrides.Columns.Add("ColumnTextPlacement", cmGetEnumTypeDescription("TextPlacements"));
	EndIf;
	If vWithChart Then
		If pRepObject.ReportColumnOverrides.Columns.Find("ShowInChart") = Undefined Then
			pRepObject.ReportColumnOverrides.Columns.Add("ShowInChart", cmGetBooleanTypeDescription());
		EndIf;
	EndIf;
	// Get current column name
	vColumnName = String(pControl.CurrentRow.Name);
	vColumnDataPath = String(pControl.CurrentRow.DataPath);
	If IsBlankString(vColumnName) And IsBlankString(vColumnDataPath) Then
		Return;
	EndIf;
	// Try to find appropriate row in the ReportColumnOverrides value table
	vOverrideRow = pRepObject.ReportColumnOverrides.Find(vColumnDataPath, "ColumnDataPath");
	If vOverrideRow = Undefined Then
		vOverrideRow = pRepObject.ReportColumnOverrides.Find(vColumnName, "ColumnName");
	EndIf;
	If vOverrideRow <> Undefined Then
		// Get override values
		vColumnWidth = vOverrideRow.ColumnWidth;
		vColumnHeaderDescription = vOverrideRow.ColumnHeaderDescription;
		vColumnFormat = vOverrideRow.ColumnFormat;
		vColumnTextPlacement = vOverrideRow.ColumnTextPlacement;
		vShowInChart = False;
		If vWithChart Then
			vShowInChart = vOverrideRow.ShowInChart;
		EndIf;
		// Set this value to the controls
		pRepSettingsForm.Controls.Columns.Columns.ColumnWidth.Control.Value = vColumnWidth;
		pRepSettingsForm.Controls.Columns.Columns.ColumnHeaderDescription.Control.Value = vColumnHeaderDescription;
		pRepSettingsForm.Controls.Columns.Columns.ColumnFormat.Control.Value = vColumnFormat;
		pRepSettingsForm.Controls.Columns.Columns.ColumnTextPlacement.Control.Value = vColumnTextPlacement;
		If vWithChart Then
			pRepSettingsForm.Controls.Columns.Columns.ShowInChart.Control.Value = vShowInChart;
		EndIf;
	Else
		// Set 0 to the Columns.ColumnWidth control
		pRepSettingsForm.Controls.Columns.Columns.ColumnWidth.Control.Value = 0;
		// Set "" to the Columns.ColumnHeaderDescription control
		pRepSettingsForm.Controls.Columns.Columns.ColumnHeaderDescription.Control.Value = "";
		// Set "" to the Columns.ColumnFormat control
		pRepSettingsForm.Controls.Columns.Columns.ColumnFormat.Control.Value = "";
		// Set Undefined to the Columns.ColumnTextPlacement control
		pRepSettingsForm.Controls.Columns.Columns.ColumnTextPlacement.Control.Value = Undefined;
		// Set False to the Columns.ShowInChart control
		If vWithChart Then
			pRepSettingsForm.Controls.Columns.Columns.ShowInChart.Control.Value = False;
		EndIf;
	EndIf;
EndProcedure // cmReportColumnsOnStartEdit

// -----------------------------------------------------------------------------
// Description: Processes report columns page on edit end event
// Parameters: Report object, Report settings form, Table of report columns 
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmReportColumnsOnEditEnd(pRepObject, pRepSettingsForm, pControl) Export
	vWithChart = False;
	If pRepSettingsForm.Controls.Columns.Columns.Find("ShowInChart") <> Undefined Then
		vWithChart = True;
	EndIf;
	vWithShowGroupClosed = False;
	If pRepObject.ReportColumnOverrides.Columns.Find("ShowGroupClosed") <> Undefined Then
		vWithShowGroupClosed = True;
	EndIf;
	vWithShowColumnGroupClosed = False;
	If pRepObject.ReportColumnOverrides.Columns.Find("ShowColumnGroupClosed") <> Undefined Then
		vWithShowColumnGroupClosed = True;
	EndIf;
	// Get current values
	vColumnWidth = pRepSettingsForm.Controls.Columns.Columns.ColumnWidth.Control.Value;
	vColumnHeaderDescription = pRepSettingsForm.Controls.Columns.Columns.ColumnHeaderDescription.Control.Value;
	vColumnFormat = pRepSettingsForm.Controls.Columns.Columns.ColumnFormat.Control.Value;
	vColumnTextPlacement = pRepSettingsForm.Controls.Columns.Columns.ColumnTextPlacement.Control.Value;
	vShowInChart = False;
	If vWithChart Then
		vShowInChart = pRepSettingsForm.Controls.Columns.Columns.ShowInChart.Control.Value;
	EndIf;
	// Get current column name
	vColumnDataPath = String(pRepSettingsForm.Controls.Columns.CurrentRow.DataPath);
	vColumnName = String(pRepSettingsForm.Controls.Columns.CurrentRow.Name);
	If IsBlankString(vColumnName) And IsBlankString(vColumnDataPath) Then
		Return;
	EndIf;
	// Try to find appropriate row in the ReportColumnOverrides value table
	vOverrideRow = Undefined;
	If pRepObject.ReportColumnOverrides.Columns.Find("ColumnDataPath") <> Undefined Then
		vOverrideRow = pRepObject.ReportColumnOverrides.Find(vColumnDataPath, "ColumnDataPath");
	EndIf;
	If vOverrideRow = Undefined Then
		vOverrideRow = pRepObject.ReportColumnOverrides.Find(vColumnName, "ColumnName");
	EndIf;
	If vOverrideRow <> Undefined Then
		// Check that row and column groups are not overriding
		vShowGroupClosed = False;
		If vWithShowGroupClosed Then
			vShowGroupClosed = vOverrideRow.ShowGroupClosed;
		EndIf;
		vShowColumnGroupClosed = False;
		If vWithShowColumnGroupClosed Then
			vShowColumnGroupClosed = vOverrideRow.ShowColumnGroupClosed;
		EndIf;
		If vColumnWidth = 0 And 
		   IsBlankString(vColumnHeaderDescription) And 
		   IsBlankString(vColumnFormat) And 
		   Not ValueIsFilled(vColumnTextPlacement) And 
		   Not vShowInChart And 
		   Not vShowGroupClosed And 
		   Not vShowColumnGroupClosed Then
			// Delete this row
			pRepObject.ReportColumnOverrides.Delete(vOverrideRow);
		Else
			// Update this row
			vOverrideRow.ColumnWidth = vColumnWidth;
			vOverrideRow.ColumnHeaderDescription = vColumnHeaderDescription;
			vOverrideRow.ColumnFormat = vColumnFormat;
			vOverrideRow.ColumnTextPlacement = vColumnTextPlacement;
			If vWithChart Then
				vOverrideRow.ShowInChart = vShowInChart;
			EndIf;
		EndIf;
	Else
		If vColumnWidth > 0 Or 
		   Not IsBlankString(vColumnHeaderDescription) Or 
		   Not IsBlankString(vColumnFormat) Or 
		   ValueIsFilled(vColumnTextPlacement) Or 
		   vShowInChart Then
			// Add row
			vOverrideRow = pRepObject.ReportColumnOverrides.Add();
			vOverrideRow.ColumnName = vColumnName;
			If pRepObject.ReportColumnOverrides.Columns.Find("ColumnDataPath") <> Undefined Then
				vOverrideRow.ColumnDataPath = vColumnDataPath;
			EndIf;
			vOverrideRow.ColumnWidth = vColumnWidth;
			vOverrideRow.ColumnHeaderDescription = vColumnHeaderDescription;
			vOverrideRow.ColumnFormat = vColumnFormat;
			vOverrideRow.ColumnTextPlacement = vColumnTextPlacement;
			If vWithChart Then
				vOverrideRow.ShowInChart = vShowInChart;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // cmReportColumnsOnEditEnd

// -----------------------------------------------------------------------------
// Description: Processes report row totals page on row output event
// Parameters: Report object, Table of report row totals, Row appearance, Row data
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmReportRowTotalsOnRowOutput(pRepObject, pControl, pRowAppearance, pRowData) Export
	If pRepObject.ReportColumnOverrides.Count() > 0 And 
	   pRepObject.ReportColumnOverrides.Columns.Count() > 0 Then
		vOverrideRow = Undefined;
		If pRepObject.ReportColumnOverrides.Columns.Find("ColumnDataPath") <> Undefined Then
			vOverrideRow = pRepObject.ReportColumnOverrides.Find(pRowData.DataPath, "ColumnDataPath");
		EndIf;
		If vOverrideRow = Undefined Then
			vOverrideRow = pRepObject.ReportColumnOverrides.Find(pRowData.Name, "ColumnName");
		EndIf;
		If vOverrideRow <> Undefined Then
			Try
				If pControl.Columns.Find("ShowGroupClosed") <> Undefined Then
					If pControl.Columns.ShowGroupClosed.Visible Then
						pRowAppearance.Cells.ShowGroupClosed.CheckValue = vOverrideRow.ShowGroupClosed;
						pRowAppearance.Cells.ShowGroupClosed.ShowText = True;
						If vOverrideRow.ShowGroupClosed Then
							pRowAppearance.Cells.ShowGroupClosed.Text = NStr("en='+'; ru='+'; de='+'");
						Else
							pRowAppearance.Cells.ShowGroupClosed.Text = "";
						EndIf;
					EndIf;
				EndIf;
			Except
			EndTry;
		EndIf;
	EndIf;
EndProcedure // cmReportRowTotalsOnRowOutput

// -----------------------------------------------------------------------------
// Description: Processes report row totals page on start edit event
// Parameters: Report object, Report settings form, Table of report row totals, 
//             If this is new row, If this is clone operation
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmReportRowTotalsOnStartEdit(pRepObject, pRepSettingsForm, pControl, pNewRow, pClone) Export
	// Check if report ReportColumnOverrides attribute is initialized
	vColumnShowGroupClosed = False;
	If pRepSettingsForm.Controls.RowTotals.Columns.Find("ShowGroupClosed") <> Undefined Then
		vColumnShowGroupClosed = True;
		If pRepObject.ReportColumnOverrides.Columns.Find("ShowGroupClosed") = Undefined Then
			pRepObject.ReportColumnOverrides.Columns.Add("ShowGroupClosed", cmGetBooleanTypeDescription());
		EndIf;
	EndIf;
	If pRepObject.ReportColumnOverrides.Columns.Find("ColumnName") = Undefined Then
		pRepObject.ReportColumnOverrides.Columns.Add("ColumnName", cmGetStringTypeDescription());
	EndIf;
	If pRepObject.ReportColumnOverrides.Columns.Find("ColumnDataPath") = Undefined Then
		pRepObject.ReportColumnOverrides.Columns.Add("ColumnDataPath", cmGetStringTypeDescription());
	EndIf;
	// Get current column name
	vColumnName = String(pControl.CurrentRow.Name);
	vColumnDataPath = String(pControl.CurrentRow.DataPath);
	If IsBlankString(vColumnName) And IsBlankString(vColumnDataPath) Then
		Return;
	EndIf;
	// Try to find appropriate row in the ReportColumnOverrides value table
	vOverrideRow = pRepObject.ReportColumnOverrides.Find(vColumnDataPath, "ColumnDataPath");
	If vOverrideRow = Undefined Then
		vOverrideRow = pRepObject.ReportColumnOverrides.Find(vColumnName, "ColumnName");
	EndIf;
	If vOverrideRow <> Undefined Then
		// Get override values
		vShowGroupClosed = False;
		If vColumnShowGroupClosed Then
			vShowGroupClosed = vOverrideRow.ShowGroupClosed;
			pRepSettingsForm.Controls.RowTotals.Columns.ShowGroupClosed.Control.Value = vShowGroupClosed;
		EndIf;
	Else
		// Set False to the RowTotals.ShowGroupClosed control
		If vColumnShowGroupClosed Then
			pRepSettingsForm.Controls.RowTotals.Columns.ShowGroupClosed.Control.Value = False;
		EndIf;
	EndIf;
EndProcedure // cmReportRowTotalsOnStartEdit

// -----------------------------------------------------------------------------
// Description: Processes report row totals page on edit end event
// Parameters: Report object, Report settings form, Table of report row totals
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmReportRowTotalsOnEditEnd(pRepObject, pRepSettingsForm, pControl) Export
	vColumnShowGroupClosed = False;
	If pRepSettingsForm.Controls.RowTotals.Columns.Find("ShowGroupClosed") <> Undefined Then
		vColumnShowGroupClosed = True;
	EndIf;
	// Get current values
	vShowGroupClosed = False;
	If vColumnShowGroupClosed Then
		vShowGroupClosed = pRepSettingsForm.Controls.RowTotals.Columns.ShowGroupClosed.Control.Value;
	EndIf;
	// Get current column name
	vColumnName = String(pRepSettingsForm.Controls.RowTotals.CurrentRow.Name);
	vColumnDataPath = String(pRepSettingsForm.Controls.RowTotals.CurrentRow.DataPath);
	If IsBlankString(vColumnName) And IsBlankString(vColumnDataPath) Then
		Return;
	EndIf;
	// Try to find appropriate row in the ReportColumnOverrides value table
	vOverrideRow = Undefined;
	If pRepObject.ReportColumnOverrides.Columns.Find("ColumnDataPath") <> Undefined Then
		vOverrideRow = pRepObject.ReportColumnOverrides.Find(vColumnDataPath, "ColumnDataPath");
	EndIf;
	If vOverrideRow = Undefined Then
		vOverrideRow = pRepObject.ReportColumnOverrides.Find(vColumnName, "ColumnName");
	EndIf;
	If vOverrideRow <> Undefined Then
		// Update this row
		If vColumnShowGroupClosed Then
			vOverrideRow.ShowGroupClosed = vShowGroupClosed;
		EndIf;
	Else
		If vColumnShowGroupClosed Then
			// Add row
			vOverrideRow = pRepObject.ReportColumnOverrides.Add();
			vOverrideRow.ColumnName = vColumnName;
			If pRepObject.ReportColumnOverrides.Columns.Find("ColumnDataPath") <> Undefined Then
				vOverrideRow.ColumnDataPath = vColumnDataPath;
			EndIf;
			If vShowGroupClosed Then
				vOverrideRow.ShowGroupClosed = vShowGroupClosed;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // cmReportRowTotalsOnEditEnd

// -----------------------------------------------------------------------------
// Description: Processes report column totals page on row output event
// Parameters: Report object, Table of report column totals, Row appearance, Row data
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmReportColumnTotalsOnRowOutput(pRepObject, pControl, pRowAppearance, pRowData) Export
	If pRepObject.ReportColumnOverrides.Count() > 0 And 
	   pRepObject.ReportColumnOverrides.Columns.Count() > 0 Then
		vOverrideRow = Undefined;
		If pRepObject.ReportColumnOverrides.Columns.Find("ColumnDataPath") <> Undefined Then
			vOverrideRow = pRepObject.ReportColumnOverrides.Find(pRowData.DataPath, "ColumnDataPath");
		EndIf;
		If vOverrideRow = Undefined Then
			vOverrideRow = pRepObject.ReportColumnOverrides.Find(pRowData.Name, "ColumnName");
		EndIf;
		If vOverrideRow <> Undefined Then
			Try
				If pControl.Columns.Find("ShowGroupClosed") <> Undefined Then
					If pControl.Columns.ShowGroupClosed.Visible Then
						pRowAppearance.Cells.ShowGroupClosed.CheckValue = vOverrideRow.ShowColumnGroupClosed;
						pRowAppearance.Cells.ShowGroupClosed.ShowText = True;
						If vOverrideRow.ShowColumnGroupClosed Then
							pRowAppearance.Cells.ShowGroupClosed.Text = NStr("en='+'; ru='+'; de='+'");
						Else
							pRowAppearance.Cells.ShowGroupClosed.Text = "";
						EndIf;
					EndIf;
				EndIf;
			Except
			EndTry;
		EndIf;
	EndIf;
EndProcedure // cmReportColumnTotalsOnRowOutput

// -----------------------------------------------------------------------------
// Description: Processes report column totals page on start edit event
// Parameters: Report object, Report settings form, Table of report column totals, 
//             If this is new row, If this is clone operation
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmReportColumnTotalsOnStartEdit(pRepObject, pRepSettingsForm, pControl, pNewRow, pClone) Export
	// Check if report ReportColumnOverrides attribute is initialized
	vColumnShowGroupClosed = False;
	If pRepSettingsForm.Controls.ColumnTotals.Columns.Find("ShowGroupClosed") <> Undefined Then
		vColumnShowGroupClosed = True;
		If pRepObject.ReportColumnOverrides.Columns.Find("ShowColumnGroupClosed") = Undefined Then
			pRepObject.ReportColumnOverrides.Columns.Add("ShowColumnGroupClosed", cmGetBooleanTypeDescription());
		EndIf;
	EndIf;
	If pRepObject.ReportColumnOverrides.Columns.Find("ColumnName") = Undefined Then
		pRepObject.ReportColumnOverrides.Columns.Add("ColumnName", cmGetStringTypeDescription());
	EndIf;
	If pRepObject.ReportColumnOverrides.Columns.Find("ColumnDataPath") = Undefined Then
		pRepObject.ReportColumnOverrides.Columns.Add("ColumnDataPath", cmGetStringTypeDescription());
	EndIf;
	// Get current column name
	vColumnName = String(pControl.CurrentRow.Name);
	vColumnDataPath = String(pControl.CurrentRow.DataPath);
	If IsBlankString(vColumnName) And IsBlankString(vColumnDataPath) Then
		Return;
	EndIf;
	// Try to find appropriate row in the ReportColumnOverrides value table
	vOverrideRow = pRepObject.ReportColumnOverrides.Find(vColumnDataPath, "ColumnDataPath");
	If vOverrideRow = Undefined Then
		vOverrideRow = pRepObject.ReportColumnOverrides.Find(vColumnName, "ColumnName");
	EndIf;
	If vOverrideRow <> Undefined Then
		// Get override values
		vShowGroupClosed = False;
		If vColumnShowGroupClosed Then
			vShowGroupClosed = vOverrideRow.ShowColumnGroupClosed;
			pRepSettingsForm.Controls.ColumnTotals.Columns.ShowGroupClosed.Control.Value = vShowGroupClosed;
		EndIf;
	Else
		// Set False to the ColumnTotals.ShowGroupClosed control
		If vColumnShowGroupClosed Then
			pRepSettingsForm.Controls.ColumnTotals.Columns.ShowGroupClosed.Control.Value = False;
		EndIf;
	EndIf;
EndProcedure // cmReportColumnTotalsOnStartEdit

// -----------------------------------------------------------------------------
// Description: Processes report column totals page on edit end event
// Parameters: Report object, Report settings form, Table of report column totals
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmReportColumnTotalsOnEditEnd(pRepObject, pRepSettingsForm, pControl) Export
	vColumnShowGroupClosed = False;
	If pRepSettingsForm.Controls.ColumnTotals.Columns.Find("ShowGroupClosed") <> Undefined Then
		vColumnShowGroupClosed = True;
	EndIf;
	// Get current values
	vShowGroupClosed = False;
	If vColumnShowGroupClosed Then
		vShowGroupClosed = pRepSettingsForm.Controls.ColumnTotals.Columns.ShowGroupClosed.Control.Value;
	EndIf;
	// Get current column name
	vColumnName = String(pRepSettingsForm.Controls.ColumnTotals.CurrentRow.Name);
	vColumnDataPath = String(pRepSettingsForm.Controls.ColumnTotals.CurrentRow.DataPath);
	If IsBlankString(vColumnName) And IsBlankString(vColumnDataPath) Then
		Return;
	EndIf;
	// Try to find appropriate row in the ReportColumnOverrides value table
	vOverrideRow = Undefined;
	If pRepObject.ReportColumnOverrides.Columns.Find("ColumnDataPath") <> Undefined Then
		vOverrideRow = pRepObject.ReportColumnOverrides.Find(vColumnDataPath, "ColumnDataPath");
	EndIf;
	If vOverrideRow = Undefined Then
		vOverrideRow = pRepObject.ReportColumnOverrides.Find(vColumnName, "ColumnName");
	EndIf;
	If vOverrideRow <> Undefined Then
		// Update this row
		If vColumnShowGroupClosed Then
			vOverrideRow.ShowColumnGroupClosed = vShowGroupClosed;
		EndIf;
	Else
		If vColumnShowGroupClosed Then
			// Add row
			vOverrideRow = pRepObject.ReportColumnOverrides.Add();
			vOverrideRow.ColumnName = vColumnName;
			If pRepObject.ReportColumnOverrides.Columns.Find("ColumnDataPath") <> Undefined Then
				vOverrideRow.ColumnDataPath = vColumnDataPath;
			EndIf;
			If vShowGroupClosed Then
				vOverrideRow.ShowColumnGroupClosed = vShowGroupClosed;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // cmReportColumnTotalsOnEditEnd

// -----------------------------------------------------------------------------
// Description: Shows edit report column format string dialog
// Parameters: Report object, Report settings form, Table of report columns 
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmReportColumnsColumnFormatStartChoice(pRepObject, pRepSettingsForm, pControl) Export
	vFormatWizard = Undefined;
	vFormat = pControl.Value;
	If IsBlankString(vFormat) Then
		vFormatWizard = New FormatStringWizard();
	Else
		vFormatWizard = New FormatStringWizard(vFormat);
	EndIf;
	If vFormatWizard.DoModal() Then
		pControl.Value = vFormatWizard.Text;
	EndIf;
EndProcedure // cmReportColumnsColumnFormatStartChoice

// -----------------------------------------------------------------------------
// Description: Returns picture index of the given room status
// Parameters: Room status 
// Return value: Number
// -----------------------------------------------------------------------------
Function cmGetRoomStatusIconIndex(pRoomStatus) Export
	vPictureIndex = 5;
	If ValueIsFilled(pRoomStatus) Then
		If ValueIsFilled(pRoomStatus.RoomStatusIcon) Then
			If pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.None Then
				vPictureIndex = 3;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Reserved Then
				vPictureIndex = 6;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Occupied Then
				vPictureIndex = 2;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.OccupiedDirty Then
				vPictureIndex = 7;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Waiting Then
				vPictureIndex = 1;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.TidyingUp Then
				vPictureIndex = 0;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.CheckOut Then
				vPictureIndex = 3;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Vacant Then
				vPictureIndex = 4;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Repair Then
				vPictureIndex = 8;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Luggage Then
				vPictureIndex = 9;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Malfunction Then
				vPictureIndex = 10;
			EndIf;
		EndIf;
	EndIf;
	Return vPictureIndex;
EndFunction // cmGetRoomStatusIconIndex

// -----------------------------------------------------------------------------
// Description: Returns icon of the given reservation status
// Parameters: Reservation status 
// Return value: Picture object
// -----------------------------------------------------------------------------
Function cmGetReservationStatusIcon(pReservationStatus, pParentDoc = Undefined) Export
	vPicture = PictureLib.Empty;
	If ValueIsFilled(pReservationStatus) Then
		If pReservationStatus.IsInWaitingList Then
			vPicture = PictureLib.Waiting;
		ElsIf pReservationStatus.IsActive Then
			If ValueIsFilled(pParentDoc) Then
				vPicture = PictureLib.ChangeRoomStatus;
			ElsIf pReservationStatus.IsGuaranteed Then
				vPicture = PictureLib.IsGuaranteed;
			Else
				vPicture = PictureLib.IsActive;
			EndIf;
		ElsIf pReservationStatus.IsCheckIn Then
			vPicture = PictureLib.IsCheckIn;
		ElsIf pReservationStatus.IsNoShow Then
			vPicture = PictureLib.IsNoShow;
		ElsIf pReservationStatus.IsPreliminary Then
			vPicture = PictureLib.IsPreliminary;
		Else
			vPicture = PictureLib.IsNotActive;
		EndIf;
	EndIf;
	Return vPicture;
EndFunction // cmGetReservationStatusIcon

// -----------------------------------------------------------------------------
// Description: Returns icon of the given resource reservation status
// Parameters: Resource reservation status 
// Return value: Picture object
// -----------------------------------------------------------------------------
Function cmGetResourceReservationStatusIcon(pResourceReservationStatus) Export
	vPicture = PictureLib.Empty;
	If ValueIsFilled(pResourceReservationStatus) Then
		If pResourceReservationStatus.IsActive Then 
			If pResourceReservationStatus.ServicesAreDelivered Then
				vPicture = PictureLib.Pin;
			ElsIf pResourceReservationStatus.DoCharging Then
				vPicture = PictureLib.AccumulationRegister;
			ElsIf pResourceReservationStatus.IsGuaranteed Then
				vPicture = PictureLib.CheckMark;
			Else
				vPicture = PictureLib.IsActive;
			EndIf;
		Else
			vPicture = PictureLib.IsNotActive;
		EndIf;
	EndIf;
	Return vPicture;
EndFunction // cmGetResourceReservationStatusIcon

// -----------------------------------------------------------------------------
// Description: Returns icon of the given accommodation status
// Parameters: Accommodation status 
// Return value: Picture object
// -----------------------------------------------------------------------------
Function cmGetAccommodationStatusIcon(pAccommodationStatus) Export
	vPicture = PictureLib.Empty;
	If ValueIsFilled(pAccommodationStatus) Then
		If pAccommodationStatus.IsActive Then
			If pAccommodationStatus.IsCheckIn And pAccommodationStatus.IsInHouse Then
				vPicture = PictureLib.CheckIn;
			ElsIf pAccommodationStatus.IsRoomChange And pAccommodationStatus.IsInHouse Then
				vPicture = PictureLib.ChangeRoom;
			Else
				vPicture = PictureLib.CheckOut;
			EndIf;
		Else
			vPicture = PictureLib.IsNotActive;
		EndIf;
	EndIf;
	Return vPicture;
EndFunction // cmGetAccommodationStatusIcon

// -----------------------------------------------------------------------------
// Description: Returns client sex icon
// Parameters: Client
// Return value: Picture object
// -----------------------------------------------------------------------------
Function cmGetClientSexIcon(pClientRef) Export
	vPicture = PictureLib.Clients;
	If ValueIsFilled(pClientRef) And ValueIsFilled(pClientRef.Sex) Then
		If pClientRef.Sex = Enums.Sex.Male Then
			vPicture = PictureLib.Male;
		Else
			vPicture = PictureLib.Female;
		EndIf;
	EndIf;
	Return vPicture;
EndFunction // cmGetClientSexIcon

// -----------------------------------------------------------------------------
// Description: Writes to the main menu "Last visited objects list" 
// Parameters: Persistent objects application structure, Object reference
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmWriteToLastVisitedObjects(pPersistentObjects, pObjectRef) Export
	If ValueIsFilled(pObjectRef) Then   
		vObjString = pObjectRef.Metadata().FullName();
		If StrFind(vObjString, "Document") Then
			vEventDescription = NStr("en = 'View document'; de = 'Ein Dokument anzeigen'; ru = 'Просмотр документа'");   
		ElsIf StrFind(vObjString, "Catalog") Then 
			vEventDescription = NStr("en = 'View catalog'; de = 'Ein Katalog anzeigen'; ru = 'Просмотр справочника'");	
		Else
			vEventDescription = NStr("en = 'View object'; de = 'Ein Objekt anzeigen'; ru = 'Просмотр объекта'");
		EndIf;
		InformationRegisters.UserActionsHistory.WriteUserActivityRecord(pObjectRef, vEventDescription, SessionParameters.CurrentHotel);	
	EndIf;
EndProcedure // cmWriteToLastVisitedObjects

// -----------------------------------------------------------------------------
// Description: Returns object presentation string for the "Last visited objects list" 
// Parameters: Object reference
// Return value: String to be shown in the list for the given object
// -----------------------------------------------------------------------------
Function cmGetObjectPresentation(pObjectRef) Export
	vPresentation = New Structure("Icon, Text", PictureLib.Empty, "");
	If ValueIsFilled(pObjectRef) Then
		If TypeOf(pObjectRef) = Type("DocumentRef.Reservation") Then
			vPresentation.Icon = cmGetReservationStatusIcon(pObjectRef.ReservationStatus, pObjectRef.ParentDoc);
			vPresentation.Text = TrimAll(pObjectRef.ReservationStatus) + Chars.LF + 
			                     TrimAll(pObjectRef.GuestGroup) + ", " + 
			                     TrimAll(pObjectRef.Guest) + ", " + TrimAll(pObjectRef.Room) + Chars.LF + 
			                     TrimAll(pObjectRef.Customer);
		ElsIf TypeOf(pObjectRef) = Type("DocumentRef.Accommodation") Then
			vPresentation.Icon = cmGetAccommodationStatusIcon(pObjectRef.AccommodationStatus);
			vPresentation.Text = TrimAll(pObjectRef.AccommodationStatus) + Chars.LF + 
			                     TrimAll(pObjectRef.GuestGroup) + ", " + 
			                     TrimAll(pObjectRef.Guest) + ", " + TrimAll(pObjectRef.Room) + Chars.LF + 
			                     TrimAll(pObjectRef.Customer);
		ElsIf TypeOf(pObjectRef) = Type("DocumentRef.ResourceReservation") Then
			vPresentation.Icon = cmGetResourceReservationStatusIcon(pObjectRef.ResourceReservationStatus);
			vPresentation.Text = TrimAll(pObjectRef.ResourceReservationStatus) + Chars.LF + 
			                     TrimAll(pObjectRef.GuestGroup) + ", " + 
			                     TrimAll(pObjectRef.Client) + ", " + TrimAll(pObjectRef.Resource) + Chars.LF + 
			                     TrimAll(pObjectRef.Customer);
		ElsIf TypeOf(pObjectRef) = Type("DocumentRef.ForeignerRegistryRecord") Then
			vPresentation.Icon = PictureLib.GeographicalSchema;
			vPresentation.Text = TrimAll(pObjectRef.Guest) + Chars.LF + 
			                     TrimAll(pObjectRef.Citizenship);
		ElsIf TypeOf(pObjectRef) = Type("CatalogRef.Clients") Then
			vPresentation.Icon = cmGetClientSexIcon(pObjectRef);
			vPresentation.Text = TrimAll(pObjectRef.FullName) + ", " + 
			                     Format(pObjectRef.DateOfBirth, "DF=dd.MM.yyyy");
		ElsIf TypeOf(pObjectRef) = Type("CatalogRef.Customers") Then
			vPresentation.Icon = PictureLib.Customer;
			vPresentation.Text = TrimAll(pObjectRef.Description);
		ElsIf TypeOf(pObjectRef) = Type("CatalogRef.Contracts") Then
			vPresentation.Icon = PictureLib.Appointment;
			vPresentation.Text = TrimAll(pObjectRef.Description);
		ElsIf TypeOf(pObjectRef) = Type("CatalogRef.GuestGroups") Then
			vPresentation.Icon = PictureLib.Clients;
			vPresentation.Text = TrimAll(pObjectRef.Code) + Chars.LF + TrimAll(pObjectRef.Description);
		ElsIf TypeOf(pObjectRef) = Type("CatalogRef.HotelProducts") Then
			vPresentation.Icon = PictureLib.PeriodWeek;
			vPresentation.Text = TrimAll(pObjectRef.Description);
		ElsIf TypeOf(pObjectRef) = Type("CatalogRef.Rooms") Then
			If Not pObjectRef.IsFolder Then
				vPresentation.Icon = PictureLib.Rooms;
				vPresentation.Text = TrimAll(pObjectRef.Description) + " " + 
				                     ?(ValueIsFilled(pObjectRef.RoomType), TrimAll(pObjectRef.RoomType.Code), "");
			EndIf;
		ElsIf TypeOf(pObjectRef) = Type("DocumentRef.Folio") Then
			vPresentation.Icon = PictureLib.Calculator;
			vPresentation.Text = TrimAll(pObjectRef.Number) + Chars.LF + 
			                     TrimAll(pObjectRef.Room) + " " + 
								 TrimAll(pObjectRef.Client) + Chars.LF + 
 			                     TrimAll(pObjectRef.Description);
		ElsIf TypeOf(pObjectRef) = Type("DocumentRef.ProformaInvoice") Then
			vPresentation.Icon = PictureLib.DocumentObject;
			vPresentation.Text = TrimAll(pObjectRef.Number) + " " + 
			                     TrimAll(pObjectRef.AccountingCustomer) + Chars.LF + 
								 cmFormatSum(pObjectRef.Sum, pObjectRef.AccountingCurrency);
		ElsIf TypeOf(pObjectRef) = Type("DocumentRef.Settlement") Then
			vPresentation.Icon = PictureLib.Deal;
			vPresentation.Text = TrimAll(pObjectRef.Number) + " " + 
			                     TrimAll(pObjectRef.AccountingCustomer) + Chars.LF + 
								 cmFormatSum(pObjectRef.Sum, pObjectRef.AccountingCurrency);
		ElsIf TypeOf(pObjectRef) = Type("DocumentRef.CustomerPayment") Then
			vPresentation.Icon = PictureLib.AccumulationRegister;
			vPresentation.Text = TrimAll(pObjectRef.Number) + " " + 
			                     TrimAll(pObjectRef.AccountingCustomer) + Chars.LF + 
								 cmFormatSum(pObjectRef.Sum, pObjectRef.PaymentCurrency);
		ElsIf TypeOf(pObjectRef) = Type("DocumentRef.CustomerAdvanceDistribution") Then
			vPresentation.Icon = PictureLib.AccumulationRegister;
			vPresentation.Text = TrimAll(pObjectRef.Number) + " " + 
			                     TrimAll(pObjectRef.AccountingCustomer) + Chars.LF + 
								 cmFormatSum(pObjectRef.GuestGroups.Total("Sum"), pObjectRef.AccountingCurrency);
		ElsIf TypeOf(pObjectRef) = Type("DocumentRef.SetRoomBlock") Then
			vPresentation.Icon = PictureLib.Stop;
			vPresentation.Text = TrimAll(pObjectRef.Room) + " - " + TrimAll(pObjectRef.RoomBlockType);
		ElsIf TypeOf(pObjectRef) = Type("DocumentRef.OperationSchedule") Then
			vPresentation.Icon = PictureLib.PeriodDay;
			vPresentation.Text = Format(pObjectRef.Date, "DLF=DD");
		Else
			vPresentation.Text = String(pObjectRef);
		EndIf;
		vPresentation.Text = TrimAll(vPresentation.Text);
	EndIf;
	Return vPresentation;
EndFunction // cmGetObjectPresentation

// -----------------------------------------------------------------------------
// Description: Checks user rights to add/remove report columns
// Parameters: Report settings form
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmSetReportSettingsAvailability(pSettingsForm) Export
	If Not cmCheckUserPermissions("HavePermissionToManageReportColumns") Then
		pSettingsForm.Controls.Columns.ChangeRowSet = False;
		pSettingsForm.Controls.Columns.Columns.Field.ReadOnly = True;
		pSettingsForm.Controls.CommandBarColumns.Buttons.ActionLoadDefaultColumns.Enabled = False;
	Else
		pSettingsForm.Controls.Columns.ChangeRowSet = True;
		pSettingsForm.Controls.Columns.Columns.Field.ReadOnly = False;
		pSettingsForm.Controls.CommandBarColumns.Buttons.ActionLoadDefaultColumns.Enabled = True;
	EndIf;
EndProcedure // cmSetReportSettingsAvailability

// -----------------------------------------------------------------------------
// Description: Changes application window caption
// Parameters: Hotel
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmChangeApplicationCaption(pHotel) Export
	vCurNodeCode = "";
	vCurNode = ExchangePlans.CentralOfficeExchangePlan.ThisNode();
	If ValueIsFilled(vCurNode) Then
		vCurNodeCode = TrimAll(vCurNode.Code);
	EndIf;
	If IsBlankString(vCurNodeCode) Then
		vCurNode = ExchangePlans.ReplicationExchangePlan.ThisNode();
		If ValueIsFilled(vCurNode) Then
			vCurNodeCode = TrimAll(vCurNode.Code);
		EndIf;
	EndIf;
	If IsBlankString(vCurNodeCode) Then
		If ValueIsFilled(pHotel) Then
			SetCaption(TrimAll(pHotel) + " - " + TrimAll(SessionParameters.ConfigurationPresentation));
		Else
			SetCaption(TrimAll(SessionParameters.ConfigurationPresentation));
		EndIf;
	Else
		If ValueIsFilled(pHotel) Then
			SetCaption(TrimAll(pHotel) + " - " + vCurNodeCode + " - " + TrimAll(SessionParameters.ConfigurationPresentation));
		Else
			SetCaption(vCurNodeCode + " - " + TrimAll(SessionParameters.ConfigurationPresentation));
		EndIf;
	EndIf;
EndProcedure // cmChangeApplicationCaption

// -----------------------------------------------------------------------------
// Description: Sets height of the choice forms to the main menu form height
// Parameters: Choice form, Main menu form
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmSetChoiceFormHeight(pChoiceForm, pMainMenuForm) Export
	vDefaultChoiceFormHeight = pMainMenuForm.Height - 50;
	If vDefaultChoiceFormHeight > pChoiceForm.Height Then
		pChoiceForm.Height = vDefaultChoiceFormHeight;
	EndIf;
EndProcedure // cmSetChoiceFormHeight

// -----------------------------------------------------------------------------
// Description: Sets width of the item forms slightly less then main menu form width 
// Parameters: Item form, Main menu form
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmSetWideItemFormWidth(pForm, pMainMenuForm) Export
	vDefaultFormWidth = pMainMenuForm.Width - 200;
	If vDefaultFormWidth > 960 Then
		vDefaultFormWidth = 960;
	EndIf;
	If vDefaultFormWidth > pForm.Width Then
		pForm.Width = vDefaultFormWidth;
	EndIf;
EndProcedure // cmSetWideItemFormWidth

// -----------------------------------------------------------------------------
// Description: Checks whether scheduled jobs manager is running or not
// Parameters: None
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmCheckScheduledJobsAgentState() Export
	If IsInRole("Administrator") Then
		vIsHanging = True;
		Try
			vBackgroundJobs = BackgroundJobs.GetBackgroundJobs();
			If vBackgroundJobs.Count() > 0 Then
				vIsHanging = False;
			EndIf;
		Except
		EndTry;
		If vIsHanging Then
			vMessage = NStr("en='Background jobs manager is likely in a ""hanging"" state! Please check background jobs console and ask your system administrator to restart 1C:Enterprise application server if background jobs list is empty!';
			                |ru='Менеджер фоновых заданий возможно ""завис"" и не работает! Пожалуйста проверьте консоль фоновых заданий и, если список фоновых заданий (нижний список) пуст, обратитесь к системному администратору и перезапустите сервер приложений 1С:Предприятия.';
							|de='Hintergrundaufgaben-Manager ""hängt"" möglicherweise und funktioniert nicht. Prüfen Sie bitte die Konsole der Hintergrundaufgaben  und, wenn die Liste der Hintergrundaufgaben (untere Liste) leer ist, wenden Sie sich an den Systemadministrator und starten Sie den Anwendungsserver 1C:Unternehmen neu.'");
			WriteLogEvent(NStr("en='ScheduledJobsManagerStateCheck';ru='ПроверкаСостоянияМенеджераФоновыхЗаданий';de='ScheduledJobsManagerStateCheck'"), EventLogLevel.Warning, , , vMessage);
			tcCommonFunctionOnClientServer.UserMessage(vMessage);
		EndIf;
	EndIf;
EndProcedure // cmCheckScheduledJobsAgentState

// -----------------------------------------------------------------------------
// Description: Returns true if scheduled jobs manager is running, false otherwise
// Parameters: None
// Return value: None
// -----------------------------------------------------------------------------
Function cmGetScheduledJobsAgentState() Export
	vIsRunning = True;
	Try
		vBackgroundJobs = BackgroundJobs.GetBackgroundJobs();
	Except
		vIsRunning = False;
	EndTry;
	Try
		If vIsRunning Then
			// Restart processing if this is the only client running
			vThereAreOtherThickSessions = False;
			vCurSessionNumber = InfoBaseSessionNumber();
			vActiveConnections = GetInfoBaseConnections();
			For Each vActiveConnection In vActiveConnections Do
				If vCurSessionNumber <> vActiveConnection.SessionNumber Then
					If TrimAll(vActiveConnection.ApplicationName) = "1CV8" Then
						vThereAreOtherThickSessions = True;
						Break;
					EndIf;
				EndIf;
			EndDo;
			If Not vThereAreOtherThickSessions Then
				vIsRunning = False;
			EndIf;
		EndIf;
	Except
	EndTry;
	Return vIsRunning;
EndFunction // cmGetScheduledJobsAgentState

// -----------------------------------------------------------------------------
// Description: Returns icon of the external interface type (TV, Phone, Internet, e.t.c)
// Parameters: Interface type enum item
// Return value: Picture
// -----------------------------------------------------------------------------
Function cmGetInterfaceTypePicture(pInterfaceType) Export
	If pInterfaceType = Enums.InterfaceTypes.Internet Then
		Return PictureLib.HTMLPage;
	ElsIf pInterfaceType = Enums.InterfaceTypes.Minibar Then
		Return PictureLib.Minibar;
	ElsIf pInterfaceType = Enums.InterfaceTypes.Phone Then
		Return PictureLib.Phone;
	ElsIf pInterfaceType = Enums.InterfaceTypes.TV Then
		Return PictureLib.TV;
	Else
		Return PictureLib.Empty;
	EndIf;
EndFunction // cmGetInterfaceTypePicture

// -----------------------------------------------------------------------------
// Description: Saves current report settings to the report catalog item value storage
// Parameters: Report object, Report settings form
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmSaveAsDefaultReportSettings(pReportObject, pReportSettingsForm = Undefined) Export
	If ValueIsFilled(pReportObject.Report) Then
		pReportObject.pmSaveReportAttributes();
		If pReportSettingsForm <> Undefined Then
			pReportSettingsForm.Modified = False;
		EndIf;
		vFileName = GetTempFileName("xml");
		cmWriteReportSettingsToFile(pReportObject.Report, vFileName);
		vFileReader = New TextReader(vFileName, TextEncoding.UTF8);
		vXMLData = vFileReader.Read();
		vFileReader.Close();
		vRepObj = pReportObject.Report.GetObject();
		vRepObj.DefaultSettings = New ValueStorage(vXMLData);
		vRepObj.Write();
	Else
		DoMessageBox(NStr("en='Use menu option <Save current form attributes to existing setting> first!';
		                  |ru='Сначала выполните пункт меню <Сохранить параметры в существующую настройку>!';
						  |de='Zuerst im Menü den Punkt <Alle Parameter in den existierenden Einstellungen speichern> ausführen!'"));
	EndIf;
EndProcedure // SaveAsDefaultReportSettingsAction

// -----------------------------------------------------------------------------
// Description: Loads default report settings from the report binary template or from
//              report catalog item value storage
// Parameters: Report object, Report settings form
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmLoadDefaultReportSettings(pReportObject, pReportSettingsForm = Undefined) Export
	vDefaultSettings = Undefined;
	If Not ValueIsFilled(pReportObject.Report) Then
		DoMessageBox(NStr("en='Use menu option <Save current form attributes to existing setting> first!';
		                  |ru='Сначала выполните пункт меню <Сохранить параметры в существующую настройку>!';
						  |de='Zuerst im Menü den Punkt <Alle Parameter in den existierenden Einstellungen speichern> ausführen!'"));
		Return;
	EndIf;
	If pReportObject.Report.DefaultSettings <> Undefined Then
		// Read settings from the report catalog item value storage
		vDefaultSettings = pReportObject.Report.DefaultSettings.Get();
		If TypeOf(vDefaultSettings) <> Type("String") Then
			// Read settings from the report binary template if found
			Try
				vFileName = GetTempFileName("xml");
				pReportObject.GetTemplate("DefaultSettings").Write(vFileName);
				vFileReader = New TextReader(vFileName, TextEncoding.UTF8);
				vDefaultSettings = vFileReader.Read();
				vFileReader.Close();
			Except
			EndTry;
		EndIf;
	EndIf;
	If TypeOf(vDefaultSettings) <> Type("String") Then
		DoMessageBox(NStr("en='Default report settings are not filled!';
		                  |ru='Настройки отчета по умолчанию не заполнены!';
		                  |de='Standardeinstellungen des Berichts sind nicht ausgefüllt!'"));
		Return;
	EndIf;
	vFileName = GetTempFileName("xml");
	vFileWriter = New TextWriter(vFileName, TextEncoding.UTF8);
	vFileWriter.Write(vDefaultSettings);
	vFileWriter.Close();
	// Update report object
	vRepObj = pReportObject.Report.GetObject();
	cmReadReportSettingsFromFile(vRepObj, vFileName);
	vRepObj.Write();
	// Reload report attribuets from the catalog item
	pReportObject.pmLoadReportAttributes();
	// Set attributes command bar buttons appearance
	If pReportSettingsForm <> Undefined Then
		pReportSettingsForm.fmCommandBarAttributesAppearance();
	EndIf;
EndProcedure // cmLoadDefaultReportSettings
	
// -----------------------------------------------------------------------------
// Description: Opens default data processor's form
// Parameters: Data processors catalog folder or item
// Return value: True if form was opened successfully, False if not
// -----------------------------------------------------------------------------
Function cmOpenDataProcessorForm(pDataProcessor, pParameter = Undefined) Export
	Try
		// Initialize list of data processors to run
		vDPs = cmGetListOfDataProcessorsToRun(pDataProcessor);
		// Run each data processor from the list
		For Each vDPRow In vDPs Do
			// Check user rights to execute data processor
			If Not cmCheckUserRightsToExecuteDataProcessor(vDPRow.DataProcessor) Then
				Raise StrTemplate(NStr("en = 'You do not have rights to run data processor: %1!'; de = 'Sie haben keine Rechte, die Bearbeitung einzuschalten: %1!'; ru = 'Нет прав на запуск обработки: %1!'"), cmNStr(vDPRow.DataProcessor.Description));
			EndIf;
			vDPObj = cmBuildDataProcessorObject(vDPRow.DataProcessor);
			If vDPObj <> Undefined Then
				// Fill reference to the data processor catalog item
				Try
					vDPObj.DataProcessor = vDPRow.DataProcessor;
				Except
				EndTry;
				// Open data processor's default form
				Try
					vDPFrm = vDPObj.GetForm();
					vDPFrm.Open();
				Except
					vDPFrm = GetForm("DataProcessor." + TrimAll(vDPObj.DataProcessor.Processing) + ".Form", New Structure("DataProcessor", vDPObj.DataProcessor));
					vObj = FormDataToValue(vDPFrm.Object, Type("DataProcessorObject."+TrimAll(vDPObj.DataProcessor.Processing)));
					vObj.DataProcessor = vDPObj.DataProcessor;
					ValueToFormData(vObj, vDPFrm.Object);
					vDPFrm.Open();
				EndTry;
			EndIf;
		EndDo;
		Return True;
	Except
		vErrorDescription = ErrorDescription();
		vMessage = StrTemplate(NStr("en = 'Error executing data processor: %1! Error description: %2!'; 
									|de = 'Error executing data processor: %1! Error description: %2!'; 
									|ru = 'Ошибка выполнения обработки: %1! Описание ошибки: %2!'"), cmNStr(pDataProcessor.Description, SessionParameters.CurrentLanguage), vErrorDescription);
		WriteLogEvent(NStr("en='DataProcessor.Run';ru='Обработка.Выполнить';de='DataProcessor.Run'"), EventLogLevel.Warning, Metadata.Catalogs.DataProcessors, pDataProcessor, vMessage);
		tcCommonFunctionOnClientServer.UserMessage(vMessage);
		Return False;
	EndTry;
EndFunction // cmOpenDataProcessorForm

// -----------------------------------------------------------------------------
Procedure cmDoSpreadsheetOutputAtClient(pSpreadsheet, pPrintSettings, pFileName, pLanguage = Undefined) Export
	vLanguage = pLanguage;
	If Not ValueIsFilled(vLanguage) Then
		vLanguage = tcOnServer.cmGetSessionParametersAttribute("CurrentLanguage");
	EndIf;
	If pPrintSettings <> Undefined Then
		If pPrintSettings.PrintDirection = PredefinedValue("Enum.PrintDirections.Printer") Then
			If IsBlankString(pSpreadsheet.PrinterName) Then
				pSpreadsheet.Print(False);
			Else
				pSpreadsheet.Print(True);
			EndIf;
		Else
			// Get file and save catalog names
			vFileName = "";
			If IsBlankString(pFileName) Then
				If ValueIsFilled(pPrintSettings.Report) Then
					vFileName = cmNStr(TrimAll(pPrintSettings.Report));
				ElsIf ValueIsFilled(pPrintSettings.ObjectPrintingForm) Then
					vFileName = cmNStr(TrimAll(pPrintSettings.ObjectPrintingForm));
				Else
					vUUID = New UUID();
					vFileName = String(vUUID);
				EndIf;
			Else
				vFileName = TrimAll(pFileName);
			EndIf;
			vFileSaveCatalog = "";
			If IsBlankString(pPrintSettings.FileSaveCatalog) Then
				vFileSaveCatalog = TempFilesDir();
			Else
				vFileSaveCatalog = TrimAll(pPrintSettings.FileSaveCatalog);
			EndIf;
			// Get full file name and save file
			vFullFileName = "";
			If pPrintSettings.PrintDirection = Enums.PrintDirections.MXL Then
				vFileName = vFileName + ".mxl";
				vFullFileName = cmGetFullFileName(vFileName, vFileSaveCatalog);
				pSpreadsheet.Write(vFullFileName, SpreadsheetDocumentFileType.MXL);
			ElsIf pPrintSettings.PrintDirection = Enums.PrintDirections.XLS Then
				vFileName = vFileName + ".xls";
				vFullFileName = cmGetFullFileName(vFileName, vFileSaveCatalog);
				pSpreadsheet.Write(vFullFileName, SpreadsheetDocumentFileType.XLS);
			ElsIf pPrintSettings.PrintDirection = Enums.PrintDirections.XLSX Then
				vFileName = vFileName + ".xlsx";
				vFullFileName = cmGetFullFileName(vFileName, vFileSaveCatalog);
				pSpreadsheet.Write(vFullFileName, SpreadsheetDocumentFileType.XLSX);
			ElsIf pPrintSettings.PrintDirection = Enums.PrintDirections.HTML Then
				vFileName = vFileName + ".html";
				vFullFileName = cmGetFullFileName(vFileName, vFileSaveCatalog);
				pSpreadsheet.Write(vFullFileName, SpreadsheetDocumentFileType.HTML);
			ElsIf pPrintSettings.PrintDirection = Enums.PrintDirections.TXT Then
				vFileName = vFileName + ".txt";
				vFullFileName = cmGetFullFileName(vFileName, vFileSaveCatalog);
				pSpreadsheet.Write(vFullFileName, SpreadsheetDocumentFileType.TXT);
			ElsIf pPrintSettings.PrintDirection = Enums.PrintDirections.PDF Then
				vFileName = vFileName + ".pdf";
				vFullFileName = cmGetFullFileName(vFileName, vFileSaveCatalog);
				pSpreadsheet.Write(vFullFileName, SpreadsheetDocumentFileType.PDF);
			EndIf;
			// Check if we have to send file by e-mail
			If Not IsBlankString(pPrintSettings.EMails) Then
				vSubject = vFileName;
				vMessage = cmNStr("ru='Рассылка печатных форм: '; de='Versand von Druckformen: '; en = 'Print form delivery: '", vLanguage) + Chars.LF + Chars.LF + 
				           vFileName + Chars.LF + Chars.LF + 
				           cmNStr("ru='C уважением, '; de='Hochachtungsvoll, '; en='Best regards, '", vLanguage) + Chars.LF + 
				           cmNStr(tcOnServer.cmGetSessionParametersAttribute("ConfigurationName"), vLanguage);
				cmSendFileByEMailInBackground(vSubject, vMessage, pPrintSettings.EMails, vFileName, vFullFileName, vLanguage);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // cmDoSpreadsheetOutputAtClient

#EndRegion

