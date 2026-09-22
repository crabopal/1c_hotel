
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
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
EndProcedure

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
Procedure Generate(Command)
	GenerateAtServer(ReportSpreadsheet);
EndProcedure // Generate

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveReportSettings(pCommand)
	SaveReportSettingsAtServer();
EndProcedure // SaveReportSettings

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
Procedure GenerateAtServer(pSpreadsheet, pRepObj = Undefined)
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
	
	// Clear spreadsheet
	pSpreadsheet.Clear();
	
	// Fill spreadsheet
	vRepObj.pmGenerate(pSpreadsheet);
	
	// Apply report print settings and do output other then on screen
	vOutputOnScreen = cmApplyReportPrintSettingsAndDoOutput(vRepObj, pSpreadsheet, 
	                                                        PageOrientation["Portrait"],
	                                                        1, 
	                                                        True, 
	                                                        cmNStr(vRepObj.Metadata().Synonym));

	If pRepObj = Undefined Then
		ValueToFormAttribute(vRepObj, "ReportObj");
	EndIf;
EndProcedure // GenerateAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveReportSettingsAtServer()
	vObject = FormAttributeToValue("ReportObj"); 
	If ValueIsFilled(vObject.Report) Then
		vObject.pmSaveReportAttributes();
	EndIf;
EndProcedure // SaveReportSettingsAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure HotelClearingAtServer(pStandardProcessing)
	pStandardProcessing = tcOnServer.CheckIfHotelCouldBeCleared();
EndProcedure // HotelClearingAtServer

#EndRegion



