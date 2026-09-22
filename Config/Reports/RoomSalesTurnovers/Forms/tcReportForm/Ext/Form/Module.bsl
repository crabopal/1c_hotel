
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Fill report attributes from parameters
	FillingParameters();
	
	// Initialize report attributes
	vRepObj = FormAttributeToValue("ReportObj");
	If vRepObj.Report.IsEmpty() Then
		If Not vRepObj.Report.IsExternal Then
			vRepObj.Report = Catalogs.Reports[TrimAll(vRepObj.Metadata().Name)];
		EndIf;
	EndIf;
	vRepObj.pmLoadReportAttributes();
	
	ReservationPeriodIsWithoutYearOnChangeAtServer(vRepObj);
	LimitPreviousYearDataByTodaysDateInThePastOnChangeAtServer(vRepObj);
	
	// Show chart appearance
	Items.ShowChart.Check = vRepObj.ReportShowChartOnOpen;
	
	// Correction
	Items.HideCorrections.Visible = tcOnServer.cmGetHideCorrectionVisibility(vRepObj.Hotel);
	
	// Run report if neccessary
	vGenerateOnOpen = False;
	If Parameters.Property("GenerateOnOpen", vGenerateOnOpen) And vGenerateOnOpen <> Undefined And vGenerateOnOpen Then
		GenerateAtServer(ReportSpreadsheet, vRepObj, , vRepObj.ReportShowChartOnOpen);
	Else
		// Fill filter collapsed title
		FillFilterCollapsedTitle(vRepObj);
	EndIf;
	ValueToFormAttribute(vRepObj, "ReportObj");
	
	vTypes = New Array();
	vTypes.Add(Type("CatalogRef.Rooms"));
	ReportObj.Rooms2IgnoreList.ValueType = New TypeDescription(vTypes);
	
	// Check if hotels folder could be selected
	If Not tcOnServer.CheckIfHotelCouldBeCleared() Then
		Items.Hotel.ChoiceFoldersAndItems = FoldersAndItems.Items;
	EndIf;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnClose(pExit)
	If Not pExit Then
		ClearCurrentUnsavedReportSettings(ReportObj.Report);
	EndIf;
EndProcedure // OnClose

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "ReportSettings.Generate" And pSource = ReportObj.Report Then
		If pParameter <> Undefined And TypeOf(pParameter) = Type("Structure") Then
			ApplyReportSettingsAndGenerate(pParameter, True);
		EndIf;
	ElsIf pEventName = "ReportSettings.Save" And pSource = ReportObj.Report Then
		If pParameter <> Undefined And TypeOf(pParameter) = Type("Structure") Then
			ApplyReportSettingsAndGenerate(pParameter, False);
		EndIf;
	EndIf;
EndProcedure // NotificationProcessing

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelClearing(pItem, pStandardProcessing)
	HotelClearingAtServer(pStandardProcessing);
EndProcedure // HotelClearing

// -----------------------------------------------------------------------------
&AtClient
Procedure PeriodToOnChange(pItem)
	If ValueIsFilled(ReportObj.PeriodTo) And BegOfDay(ReportObj.PeriodTo) = (ReportObj.PeriodTo - Second(ReportObj.PeriodTo)) Then
		ReportObj.PeriodTo = EndOfDay(ReportObj.PeriodTo);
	EndIf;
EndProcedure // PeriodToOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DateFromOnChange(Item)
	If ReportObj.ReservationPeriodIsWithoutYear Then
		ReportObj.DateFrom = Date(2, Month(ReportObj.DateFrom), Day(ReportObj.DateFrom));
		ReportObj.DateTo = Date(2, Month(ReportObj.DateTo), Day(ReportObj.DateTo));
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DateToOnChange(pItem)
	If ReportObj.ReservationPeriodIsWithoutYear Then
		ReportObj.DateFrom = Date(2, Month(ReportObj.DateFrom), Day(ReportObj.DateFrom));
		ReportObj.DateTo = Date(2, Month(ReportObj.DateTo), Day(ReportObj.DateTo));
	Else
		If ValueIsFilled(ReportObj.DateTo) And (BegOfDay(ReportObj.DateTo) + 23*3600 + 59*60) = ReportObj.DateTo Then
			ReportObj.DateTo = EndOfDay(ReportObj.DateTo);
		EndIf;
	EndIf;
EndProcedure // DateToOnChange

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
	GenerateAtServer(ReportSpreadsheet, , , Items.ShowChart.Check);
EndProcedure // Generate

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowChart(pCommand)
	Items.ShowChart.Check = Not Items.ShowChart.Check;
	GenerateAtServer(ReportSpreadsheet, , , Items.ShowChart.Check);
EndProcedure // ShowChart

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
Procedure ChooseReservationPeriod(pCommand)
	vChoosePeriodDialog = New StandardPeriodEditDialog();
	vChoosePeriodDialog.Period.StartDate = ReportObj.DateFrom;
	vChoosePeriodDialog.Period.EndDate = ReportObj.DateTo;
	vChoosePeriodDialog.Period.Variant = StandardPeriodVariant.Custom;
	vChoosePeriodDialog.Show(New NotifyDescription("ChooseReservationPeriodAfterChoice", ThisForm));
EndProcedure // ChoosePeriod

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenSettingsForm(pCommand)
	vParams = GetSettingsFormParameters();
	OpenForm("CommonForm.tcReportSettingsForm", vParams, ThisForm, ReportObj.Report, , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // OpenSettingsForm

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure FillFilterCollapsedTitle(pRepObj)
	Items.Head.CollapsedRepresentationTitle = Items.Head.Title + ": " + StrReplace(pRepObj.pmGetReportParametersPresentation(), Chars.LF, " ");
EndProcedure // FillFilterCollapsedTitle

// -----------------------------------------------------------------------------
&AtServer 
Procedure FillingParameters()
	vFillingValues = Undefined;
	If Parameters.Property("FillingValues", vFillingValues) And TypeOf(vFillingValues) = Type("Structure") Then
		If vFillingValues.Property("ReportRef") Then
			ReportObj.Report = vFillingValues.ReportRef;
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
Procedure GenerateAtServer(pSpreadsheet, pRepObj = Undefined, pReportBuilderDetails = Undefined, pShowChart = False)
	// Get report object
	vRepObj = pRepObj;
	If vRepObj = Undefined Then
		vRepObj = FormAttributeToValue("ReportObj");
		// Load report default settings
		vRepObj.pmLoadReportAttributes();
		// Fill report attributes by current values
		FillPropertyValues(vRepObj, ReportObj, cmGetReportUserAtrributes(vRepObj));
	EndIf;
	
	// Fill filter collapsed title
	FillFilterCollapsedTitle(vRepObj);
	
	// Initialize default report builder attributes structure
	vReportBuilderAttrStruct = cmGetReportBuilderAttributesStructure();
	
	// Rewrite report builder attributes specific for this report
	// None so far
	
	// Set report builder attributes
	cmSetReportBuilderAttributes(vRepObj, vReportBuilderAttrStruct);
	
	// Initialize report builder details
	If pReportBuilderDetails <> Undefined Then
		vRepObj.ReportBuilder.InitDetails(vRepObj.ReportBuilder, pReportBuilderDetails);
	Else
		// Clear report spreadsheet
		pSpreadsheet.Clear();
	EndIf;
	
	// Fill spreadsheet
	vRepObj.pmGenerate(pSpreadsheet, pShowChart);
	
	// Generate other reports in package
	If ValueIsFilled(vRepObj.Report) Then
		If vRepObj.Report.IsPackage Then
			GenerateReportsInThePackage(vRepObj.Report, vRepObj, 
			                            pSpreadsheet, pReportBuilderDetails, 
			                            Undefined);
		EndIf;
	EndIf;
	
	// Reset report builder details
	If pReportBuilderDetails <> Undefined Then
		pReportBuilderDetails = Undefined;
	EndIf;
	
	// Apply report print settings and do output other then on screen
	vOutputOnScreen = cmApplyReportPrintSettingsAndDoOutput(vRepObj, pSpreadsheet, 
	                                                        PageOrientation[?(vRepObj.ReportPageOrientation.IsEmpty(), "Landscape", vRepObj.ReportPageOrientation.Metadata().EnumValues[Enums.PageOrientations.IndexOf(vRepObj.ReportPageOrientation)].Name)],
	                                                        ?(ValueIsFilled(vRepObj.ReportAutoscaleType), ?(vRepObj.ReportAutoscaleType = Enums.ReportAutoscaleTypes.FitToPageWidth, 1, 0), 1), 
	                                                        True, 
	                                                        cmNStr(vRepObj.Metadata().Synonym));

	If pRepObj = Undefined Then
		ValueToFormAttribute(vRepObj, "ReportObj");
	EndIf;
EndProcedure // GenerateAtServer

// -----------------------------------------------------------------------------
// Description: Generates reports from the report package
// Parameters: Main package report item, Report object to use parameters from, 
//             Spreadsheet where to put reports, REport builder details object,
//             Report parameter object
// Return value: None
// -----------------------------------------------------------------------------
&AtServer
Procedure GenerateReportsInThePackage(pReport, pParentRepObj, 
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
			Try
				// Fill reference to the report catalog item
				vRepObj.Report = vReportRow.Report;
				
				// Load report catalog item attributes
				vRepObj.pmLoadReportAttributes(pParameter);
				
				// Fill report attributes from the current report object
				If Not vReportRow.DoNotUseParentReportAttributes Then
					Try
						FillPropertyValues(vRepObj, pParentRepObj, , cmGetReportSystemAttributes(vRepObj));
					Except
					EndTry;
				EndIf;
				
				// Initialize default report builder attributes structure
				vReportBuilderAttrStruct = cmGetReportBuilderAttributesStructure();
				vReportBuilderAttrStruct.PutReportHeader = Not vReportRow.ReportDoNotPutReportHeader;
				vReportBuilderAttrStruct.PutTableHeader = Not vReportRow.ReportDoNotPutTableHeader;
				vReportBuilderAttrStruct.PutDetailRecords = Not vReportRow.ReportDoNotPutDetailRecords;
				vReportBuilderAttrStruct.PutTableFooter = Not vReportRow.ReportDoNotPutTableFooter;
				vReportBuilderAttrStruct.PutOveralls = Not vReportRow.ReportDoNotPutOveralls;
				vReportBuilderAttrStruct.PutReportFooter = Not vReportRow.ReportDoNotPutReportFooter;
				
				// Set report builder attributes
				cmSetReportBuilderAttributes(vRepObj, vReportBuilderAttrStruct);
				
				// Initialize report builder details
				If pReportBuilderDetails <> Undefined Then
					vRepObj.ReportBuilder.InitDetails(vRepObj.ReportBuilder, pReportBuilderDetails);
				EndIf;
				
				// Fill spreadsheet
				vRepObj.pmGenerate(pSpreadsheet);
			Except
				Continue;
			EndTry;
		EndIf;
	EndDo;
EndProcedure // GenerateReportsInThePackage

#EndRegion

#Region ReportAttributesEvents

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriodAfterChoice(pPeriod, pExtraParams) Export
	If pPeriod <> Undefined Then
		ReportObj.PeriodFrom = pPeriod.StartDate;
		ReportObj.PeriodTo = pPeriod.EndDate;
	EndIf;
EndProcedure // ChoosePeriodAfterChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure ChooseReservationPeriodAfterChoice(pPeriod, pExtraParams) Export
	If pPeriod <> Undefined Then
		ReportObj.DateFrom = pPeriod.StartDate;
		ReportObj.DateTo = pPeriod.EndDate;
	EndIf;
EndProcedure // ChoosePeriodAfterChoice

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure HotelClearingAtServer(pStandardProcessing)
	pStandardProcessing = tcOnServer.CheckIfHotelCouldBeCleared();
EndProcedure // HotelClearingAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ReservationPeriodIsWithoutYearOnChange(pItem)
	ReservationPeriodIsWithoutYearOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure LimitPreviousYearDataByTodaysDateInThePastOnChange(Item)
	LimitPreviousYearDataByTodaysDateInThePastOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ByGroupCreationDateOnChange(pItem)
	LimitPreviousYearDataByTodaysDateInThePastOnChangeAtServer();
EndProcedure

#EndRegion

#Region ReportSettings

// -----------------------------------------------------------------------------
&AtServer
Function GetSettingsFormParameters()
	vRepObj = FormAttributeToValue("ReportObj");
	vParams = cmGetReportParametersStructure(vRepObj, ThisForm.UUID);
	Return vParams;
EndFunction // GetSettingsFormParameters

// -----------------------------------------------------------------------------
&AtServer
Procedure ApplyReportSettingsAndGenerate(pSettingsStruct, pGenerateOnly = False)
	vRepObj = FormAttributeToValue("ReportObj");
	// Load report default settings
	vRepObj.pmLoadReportAttributes();
	// Fill report attributes by current values
	FillPropertyValues(vRepObj, ReportObj, cmGetReportUserAtrributes(vRepObj));
	// Apply report settings
	cmApplyReportSettingsStructure(vRepObj, pSettingsStruct);
	// Save current report settings
	If ValueIsFilled(vRepObj.Report) Then
		vRepObj.pmSaveReportAttributes(pGenerateOnly);
	EndIf;
	// Generate report
	GenerateAtServer(ReportSpreadsheet, vRepObj, , Items.ShowChart.Check);
	// Restore form attributes
	ValueToFormAttribute(vRepObj, "ReportObj");
EndProcedure // ApplyReportSettingsAndGenerate

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure ClearCurrentUnsavedReportSettings(pRep)
	cmClearCurrentUnsavedReportSettings(pRep);
EndProcedure // ClearCurrentUnsavedReportSettings

// -----------------------------------------------------------------------------
&AtServer
Procedure ReservationPeriodIsWithoutYearOnChangeAtServer(pRepObj = Undefined)
	vRepObj = pRepObj;
	If pRepObj = Undefined Then
		vRepObj = ReportObj;
	EndIf;
	If vRepObj.ReservationPeriodIsWithoutYear Then
		vRepObj.DateFrom = Date(2, Month(vRepObj.DateFrom), Day(vRepObj.DateFrom));
		vRepObj.DateTo = Date(2, Month(vRepObj.DateTo), Day(vRepObj.DateTo));
	EndIf;

	If vRepObj.ReservationPeriodIsWithoutYear Then
		Items.DateFrom.EditFormat = "DF=dd.MM";
		Items.DateTo.EditFormat = "DF=dd.MM";
	ElsIf vRepObj.ByGroupCreationDate Then
		Items.DateFrom.EditFormat = "DF=dd.MM.yyyy";
		Items.DateTo.EditFormat = "DF=dd.MM.yyyy";
	Else
		Items.DateFrom.EditFormat = "DF='dd.MM.yyyy HH:mm'";
		Items.DateTo.EditFormat = "DF='dd.MM.yyyy HH:mm'";
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure LimitPreviousYearDataByTodaysDateInThePastOnChangeAtServer(pRepObj = Undefined)
	vRepObj = pRepObj;
	If pRepObj = Undefined Then
		vRepObj = ReportObj;
	EndIf;

	If vRepObj.LimitPreviousYearDataByTodaysDateInThePast Then
		vRepObj.DateFrom = '00010101';
		vRepObj.DateTo = '00010101';
		vRepObj.ReservationPeriodIsWithoutYear = False;

		Items.DateFrom.Enabled = False;
		Items.DateTo.Enabled = False;
		Items.ReservationPeriodIsWithoutYear.Enabled = False;
	Else
		Items.DateFrom.Enabled = True;
		Items.DateTo.Enabled = True;
		Items.ReservationPeriodIsWithoutYear.Enabled = True;
	EndIf;

	If vRepObj.ReservationPeriodIsWithoutYear Then
		Items.DateFrom.EditFormat = "DF=dd.MM";
		Items.DateTo.EditFormat = "DF=dd.MM";
	ElsIf vRepObj.ByGroupCreationDate Then
		Items.DateFrom.EditFormat = "DF=dd.MM.yyyy";
		Items.DateTo.EditFormat = "DF=dd.MM.yyyy";
	Else
		Items.DateFrom.EditFormat = "DF='dd.MM.yyyy HH:mm'";
		Items.DateTo.EditFormat = "DF='dd.MM.yyyy HH:mm'";
	EndIf;
EndProcedure // LimitPreviousYearDataByTodaysDateInThePastOnChangeAtServer

#EndRegion