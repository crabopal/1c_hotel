
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	vRepObj = FormAttributeToValue("ReportObj");
	FillingParameters(vRepObj);
	cmLoadReportAttributes(vRepObj);
	ValueToFormAttribute(vRepObj,"ReportObj");
	
	vGenerateOnOpen = False;
	If Parameters.Property("GenerateOnOpen", vGenerateOnOpen) Then
		If vGenerateOnOpen <> Undefined And vGenerateOnOpen Then
			GenerateAtServer(ReportSpreadsheet);
		Else
			FillReportSpreadsheetWithSavedReportParameters("Fully");
		EndIf;
	EndIf;
	
	// Check if hotels folder could be selected
	If Not tcOnServer.CheckIfHotelCouldBeCleared() Then
		Items.Hotel.ChoiceFoldersAndItems = FoldersAndItems.Items;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelClearing(pItem, pStandardProcessing)
	HotelClearingAtServer(pStandardProcessing);
EndProcedure // HotelClearing

//-----------------------------------------------------------------------------
&AtClient
Procedure ExportDirStartChoice(pItem, pChoiceData, pStandardProcessing)
	tcOnClientWorkWithFiles.cmChooseDirectoryOnClient("ExportDir", ReportObj);
EndProcedure //ExportDirStartChoice

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveAsPDF(pCommand)
	vFilePath = GetFileName();
	vFileType = SpreadsheetDocumentFileType.PDF;
	tcOnClient.SaveSpreadsheetToFile(vFileType, vFilePath, ReportSpreadsheet);
EndProcedure // SaveAsPDF

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveAsXLSX(pCommand)
	vFilePath = GetFileName();
	vFileType = SpreadsheetDocumentFileType.XLSX;
	tcOnClient.SaveSpreadsheetToFile(vFileType, vFilePath, ReportSpreadsheet);
EndProcedure // SaveAsXLSX

// -----------------------------------------------------------------------------
&AtClient
Procedure Generate(pCommand)
	GenerateAtServer(ReportSpreadsheet);
	
	For Each Area In ReportSpreadSheet.Areas Do
		If ReportObj.ReportParameters.Property(Area.Name) Then
		    If Area.Text = "" Then
				Area.Text = ReportObj.ReportParameters[Area.Name];
			EndIf;
		EndIf; 
	EndDo;
EndProcedure // Generate

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveReportSettings(pCommand)
	SaveReportSettingsAtServer();
EndProcedure // SaveReportSettings

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriod(pCommand)
	vChoosePeriodDialog = New StandardPeriodEditDialog();
	vChoosePeriodDialog.Period.StartDate = ReportObj.PeriodFrom;
	vChoosePeriodDialog.Period.EndDate = ReportObj.PeriodTo;
	vChoosePeriodDialog.Period.Variant = StandardPeriodVariant.Custom;
	vChoosePeriodDialog.Show(New NotifyDescription("ChoosePeriodAfterChoice", ThisForm));
EndProcedure // ChoosePeriod

// -----------------------------------------------------------------------------
&AtClient
Procedure Unload(pCommand)
	ReadReportParametersFromSpreadsheet();	

	If IsBlankString(ReportObj.ExportDir) Then
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='Specify the folder in which the XML file with report data will be generated!'; ru='Укажите папку в которой будет сформирован XML файл с данными отчета!'; de='Geben Sie den Ordner an, in dem die XML-Datei mit den Berichtsdaten generiert werden soll!'"));
		Return;
	EndIf;
	
	vMsg = "";
	vAddressStorage = "";
	UnloadAtServer(vMsg, vAddressStorage);
		
	If Not IsBlankString(vMsg) Then
		tcCommonFunctionOnClientServer.UserMessage(vMsg);
	Else
		If Not IsBlankString(vAddressStorage) Then
			vPath = GetFullFileName(ReportObj.ExportDir);
			SaveFile(vAddressStorage, vPath);
		EndIf;	
	EndIf;
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer 
Procedure FillingParameters(pRepObj)
	vFillingValues = "";
	If Parameters.Property("FillingValues", vFillingValues) And Parameters.FillingValues.Count() > 0 Then
		If vFillingValues.Property("ReportRef") Then
			pRepObj.Report = vFillingValues.ReportRef;
		EndIf;
	EndIf;
EndProcedure // FillingParameters

// -----------------------------------------------------------------------------
&AtServer 
Function GetFileName()
	vFilePath = StrReplace(cmGetValidFileName(cmNStr(TrimAll(ReportObj.Report))), " ", "_") + "_" + Format(CurrentDate(),"DF=dd.MM.yyyy_HH.mm");
	Return vFilePath;
EndFunction // GetFileName

// -----------------------------------------------------------------------------
&AtServer
Procedure GenerateAtServer(pSpreadsheet)
	vRepObj = FormAttributeToValue("ReportObj");
	
	cmLoadReportAttributes(vRepObj);
	
	FillPropertyValues(vRepObj, ReportObj, "Hotel, Company, PeriodFrom, PeriodTo, TopRoomTypes, SNGCountriesFolder, RussiaCountry, ChildrenAge, TotalIncomeServiceGroup, TourTicketIncomeServiceGroup, VaucherIncomeServiceGroup, ExcursionIncomeServiceGroup, MedicalIncomeServiceGroup, MealIncomeServiceGroup, TradeIncomeServiceGroup, ConsumerServicesIncomeServiceGroup");
	
	pSpreadsheet.Clear();
	
	// Fill spreadsheet
	vRepObj.pmGenerate(pSpreadsheet);

	ValueToFormAttribute(vRepObj, "ReportObj");
	
	// Apply report print settings and do output other then on screen
	vOutputOnScreen = cmApplyReportPrintSettingsAndDoOutput(vRepObj, pSpreadsheet, 
	                                                        PageOrientation["Portrait"],
	                                                        1, 
	                                                        True, 
	                                                        NStr("ru='РОССТАТ - Форма №1 (КСР) - Годовая';
															     |de='ROSSTAT - Form № 1 - Jährlich';
																 |en='ROSSTAT - Form 1 - Year'"));
EndProcedure // GenerateAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveReportSettingsAtServer()
	vObject = FormAttributeToValue("ReportObj"); 
	
	For Each Area In ReportSpreadsheet.Areas Do
		If vObject.ReportParameters.Property(Area.Name) Then
			vObject.ReportParameters[Area.Name] = StrReplace(Area.Text, Chars.NBSp, "");
		EndIf;
	EndDo;
	
	If ValueIsFilled(vObject.Report) Then
		vObject.pmSaveReportAttributes();
	EndIf;
	
	tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Saved!'; de = 'Saved!'; ru = 'Сохранено!'"));
EndProcedure // SaveReportSettingsAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure HotelClearingAtServer(pStandardProcessing)
	pStandardProcessing = tcOnServer.CheckIfHotelCouldBeCleared();
EndProcedure // HotelClearingAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillReportSpreadsheetWithSavedReportParameters(pFillType)
	If pFillType = "Fully" Then
		vPage1Area = Reports.RosstatForm1Year.GetTemplate("Report2025");
		vPage1Area.Parameters.mPeriodStr = PeriodPresentation(BegOfDay(ReportObj.PeriodFrom), EndOfDay(ReportObj.PeriodTo), cmLocalizationCode());
		vPage1Area.Parameters.mHotelName = TrimAll(ReportObj.Hotel.LegacyName);
		vPage1Area.Parameters.mHotelPostAddress = cmGetAddressPresentation(ReportObj.Hotel.PostAddress);
		vPage1Area.Parameters.mCompanyName = TrimAll(ReportObj.Company.LegacyName);
		vPage1Area.Parameters.mCompanyPostAddress = cmGetAddressPresentation(ReportObj.Company.PostAddress);
		vPage1Area.Parameters.mCompanyOKPOCode = TrimAll(ReportObj.Company.OKPO);
		ReportSpreadSheet.Put(vPage1Area);
		For Each Area In ReportSpreadSheet.Areas Do
			If ReportObj.ReportParameters.Property(Area.Name) Then
				Area.Text = ReportObj.ReportParameters[Area.Name];
			EndIf; 
		EndDo;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriodAfterChoice(pPeriod, pExtraParams) Export
	If pPeriod <> Undefined Then
		ReportObj.PeriodFrom = pPeriod.StartDate;
		ReportObj.PeriodTo = pPeriod.EndDate;
	EndIf;
EndProcedure // ChoosePeriodAfterChoice

// -----------------------------------------------------------------------------
&AtServer
Procedure UnloadAtServer(pMsg, pAddressStorage)
	vRepObj = FormAttributeToValue("ReportObj");
	vRepObj.pmUnloadToXML( , , pAddressStorage, UUID);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ReadReportParametersFromSpreadsheet()
	For Each Area In ReportSpreadsheet.Areas Do
		If ReportObj.ReportParameters.Property(Area.Name) And ValueIsFilled(Area.Text) Then
			ReportObj.ReportParameters[Area.Name] = Area.Text;
		EndIf;
	EndDo;	
EndProcedure

//-----------------------------------------------------------------------------
&AtClient
Async Procedure SaveFile(pAddressStorage, pPath)
	vResult = Await GetFileFromServerAsync(pAddressStorage, pPath);
	If TypeOf(vResult) = Type("TransferredFileDescription") Then
		vMessage = New UserMessage;
		vMessage.Text = "XML файл сохранен в " + pPath;
		vMessage.Message();
	EndIf;
EndProcedure // SaveFile

// -----------------------------------------------------------------------------
//
// Parameters:
//  pFileCatalog - String	 - Catalog to save file into
// 
// Returns:
//  String - Full file path
//
&AtServer
Function GetFullFileName(Val pFileCatalog)
	vFileName = "";
	
	vObj = FormAttributeToValue("ReportObj");
	vRepDetails = vObj.AnnualReportDetails();
	
	vRepStr = 
		vRepDetails["code"] + "_" 
		+ vRepDetails["form"] + "_" 
		+ vRepDetails["period"] + "_"
		+ ReportObj.Company.OKPO + "_" 
		+ vRepDetails["year"] + "_" 
		+ ReplaceInvalidCharactersInFileName(ReportObj.Hotel.LegacyName);
			  
	vFileName = ReplaceInvalidCharactersInFileName(vRepStr) + ".xml";
		
	pFileCatalog = TrimAll(pFileCatalog);
	If Right(pFileCatalog, 1) = "\" Then
		Return pFileCatalog + vFileName;
	ElsIf Right(pFileCatalog, 1) = "/" Then
		Return pFileCatalog + vFileName;
	Else
		Return pFileCatalog + "\" + vFileName; // Windows format by default
	EndIf;
	
EndFunction // cmGetFullFileName

// -----------------------------------------------------------------------------
//
// Parameters:
//  pFileName		 - String	 - File name.
//  pCharToReplace	 - String	 - The string to replace invalid characters with.
// 
// Returns:
//  String - The converted file name.
//
&AtServer
Function ReplaceInvalidCharactersInFileName(Val pFileName, pCharToReplace = "")
	vInvalidChars = """/\[]:;|=?*<> ";
	vInvalidChars = vInvalidChars + Chars.Tab + Chars.LF;
	
	Return TrimAll(StrConcat(StrSplit(pFileName, vInvalidChars, True), pCharToReplace));
EndFunction // ReplaceInvalidCharactersInFileName

#EndRegion
