
#Region FormEventHandlers

//-----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	GenerateAtServer();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

//-----------------------------------------------------------------------------
&AtClient
Procedure ChoosePrinter(pCommand)
	ReportSpreadsheet.Print(PrintDialogUseMode.Use);
	Close();
EndProcedure

//-----------------------------------------------------------------------------
&AtClient
Procedure Print(pCommand)
	ReportSpreadsheet.Print(PrintDialogUseMode.DontUse);
	Close();
EndProcedure

//-----------------------------------------------------------------------------
&AtClient
Procedure SaveAsPDF(pCommand)
	vFilePath = GetFileName(); 
	vFileType = SpreadsheetDocumentFileType.PDF;
	SaveFile(vFileType, vFilePath);
EndProcedure

#EndRegion

#Region Private

//-----------------------------------------------------------------------------
&AtServer
Procedure GenerateAtServer()
	// Get output spreadsheet
	vSpreadsheet = ReportSpreadsheet;

	// Hotel
	If Parameters.Property("Owner") And ValueIsFilled(Parameters.Owner) And TypeOf(Parameters.Owner) = Type("CatalogRef.Hotels") Then
		Hotel = Parameters.Owner;
	ElsIf Parameters.Property("Hotel") And ValueIsFilled(Parameters.Hotel) And TypeOf(Parameters.Hotel) = Type("CatalogRef.Hotels") Then
		Hotel = Parameters.Hotel;
	Else
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	
	// List of items to print
	LostItemsToPrint.Clear();
	If Parameters.Property("ChosenRows") And Parameters.ChosenRows.Count() > 0 Then
		For Each vRow In Parameters.ChosenRows Do
			LostItemsToPrint.Add(vRow);
		EndDo;
	EndIf;
	
	// Print
	If Parameters.Property("Type") And Parameters.Type = "Register" Then
		PrintFormType = "Register";
		GenerateRegistration(vSpreadsheet, LostItemsToPrint, Hotel, SelLanguage);
	Else
		PrintFormType = "Return";
		GenerateReturn(vSpreadsheet, LostItemsToPrint, Hotel, SelLanguage);
	EndIf;
	
	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Portrait, True); 
		
	// Check authorities
	cmSetSpreadsheetProtection(vSpreadsheet);
EndProcedure // GenerateAtServer()

//----------------------------------------------------------------------
&AtServer
Function GetFileName()   
	vTemplateMsg = NStr("en = 'Form for guest from %2'; de = 'Formular für Gast von %2'; ru = 'Бланк для гостя от %2'");
	vFilePath = StrTemplate(vTemplateMsg, Format(CurrentSessionDate(), "DF=dd-MM-yy")); 
	Return vFilePath;
EndFunction // GetFileName

//-----------------------------------------------------------------------------
&AtClient
Procedure SaveFile(pFileType, rFilePath)
	vFileDlg = New FileDialog(FileDialogMode.Save);
	vFileDlg.FullFileName = rFilePath;
	vFileDlg.Multiselect = False;
	vFileDlg.Preview = False;
	vFileDlg.Title = NStr("en = 'Save to file'; de = 'in Datei speichern'; ru = 'Сохранить в файл'");
	If pFileType = SpreadsheetDocumentFileType.MXL Then
		vFileDlg.DefaultExt = "mxl";
		vFileDlg.Filter = NStr("en = '1C spreadsheet format (*.mxl)|*.mxl'; de = 'Format der Tabelle 1C (*.mxl)|*.mxl'; ru = 'Формат таблицы 1C (*.mxl)|*.mxl'");
	ElsIf pFileType = SpreadsheetDocumentFileType.XLSX Then
		vFileDlg.DefaultExt = "xlsx";
		vFileDlg.Filter = NStr("en = 'Microsoft Excel format (*.xlsx)|*.xlsx'; de = 'Format Microsoft Excel (*.xlsx)|*.xlsx'; ru = 'Формат Microsoft Excel (*.xlsx)|*.xlsx'");
	ElsIf pFileType = SpreadsheetDocumentFileType.HTML Then
		vFileDlg.DefaultExt = "html";
		vFileDlg.Filter = NStr("en = 'HTML format (*.html)|*.html'; de = 'Format HTML (*.html)|*.html'; ru = 'Формат HTML (*.html)|*.html'");
	ElsIf pFileType = SpreadsheetDocumentFileType.PDF Then
		vFileDlg.DefaultExt = "pdf";
		vFileDlg.Filter = NStr("en = 'Adobe Reader PDF format (*.pdf)|*.pdf'; de = 'Format Adobe Reader PDF (*.pdf)|*.pdf'; ru = 'Формат Adobe Reader PDF (*.pdf)|*.pdf'");
	EndIf;
	vNotifity = New NotifyDescription("SelectFileEnd", ThisObject, New Structure("FileType", pFileType));
	vFileDlg.Show(vNotifity);
EndProcedure // SaveFile

//-----------------------------------------------------------------------------
&AtClient
Procedure SelectFileEnd(pSelectedItem, pAdditionalParameters) Export
	If Not pSelectedItem = Undefined Then
		ReportSpreadsheet.Write(pSelectedItem.Get(0), pAdditionalParameters.FileType);	
	EndIf;
EndProcedure // SelectFile

//-----------------------------------------------------------------------------
&AtServer
Procedure GenerateReturn(pSpreadsheet, pLostItemsList, pHotel, pLanguage) 
	InformationRegisters.LostAndFound.Print(pHotel, pSpreadsheet, pLostItemsList, pLanguage)
EndProcedure // GenerateReturn

//-----------------------------------------------------------------------------
&AtServer
Procedure GenerateRegistration(pSpreadsheet, pLostItemsList, pHotel, pLanguage) 
	InformationRegisters.LostAndFound.PrintRegistration(pHotel, pSpreadsheet, pLostItemsList, pLanguage)
EndProcedure // GenerateRegistration

//-----------------------------------------------------------------------------
&AtClient
Procedure Generate(pCommand)
	vSpreadsheet = ReportSpreadsheet;
	If PrintFormType = "Register" Then
		GenerateRegistration(vSpreadsheet, LostItemsToPrint, Hotel, SelLanguage);
	Else
		GenerateReturn(vSpreadsheet, LostItemsToPrint, Hotel, SelLanguage);
	EndIf;
EndProcedure

#EndRegion
