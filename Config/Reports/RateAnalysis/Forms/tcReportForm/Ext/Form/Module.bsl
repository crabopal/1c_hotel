
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
	
	// Run report if neccessary
	vGenerateOnOpen = False;
	If Parameters.Property("GenerateOnOpen", vGenerateOnOpen) And vGenerateOnOpen <> Undefined And vGenerateOnOpen Then
		GenerateAtServer(ReportSpreadsheet, vRepObj);
	Else
		// Fill filter collapsed title
		FillFilterCollapsedTitle(vRepObj);
	EndIf;
	ValueToFormAttribute(vRepObj, "ReportObj");
	
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

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Generate(pCommand)
	GenerateAtServer(ReportSpreadsheet);
EndProcedure // Generate

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
Procedure GenerateAtServer(pSpreadsheet, pRepObj = Undefined, pReportBuilderDetails = Undefined)
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
	
	// Initialize report builder details
	If pReportBuilderDetails = Undefined Then
		// Clear report spreadsheet
		pSpreadsheet.Clear();
	EndIf;
	
	// Fill spreadsheet
	vRepObj.pmGenerate(pSpreadsheet);
	
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
	                                                        PageOrientation.Portrait,
	                                                        1, 
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

// -----------------------------------------------------------------------------
&AtServer 
Function GetFileName()
	vFilePath = StrReplace(cmGetValidFileName(cmNStr(TrimAll(ReportObj.Report))), " ", "_") + "_" + Format(CurrentDate(),"DF=dd.MM.yyyy_HH.mm");
	Return vFilePath;
EndFunction // GetFileName

#EndRegion

#Region ReportAttributesEvents

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure HotelClearingAtServer(pStandardProcessing)
	pStandardProcessing = tcOnServer.CheckIfHotelCouldBeCleared();
EndProcedure // HotelClearingAtServer

#EndRegion
