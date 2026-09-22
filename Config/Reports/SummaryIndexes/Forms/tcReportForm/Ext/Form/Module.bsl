
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	vRepObj = FormAttributeToValue("ReportObj");
	FillingParameters(vRepObj);
	cmLoadReportAttributes(vRepObj);
	ValueToFormAttribute(vRepObj, "ReportObj");
	vGenerateOnOpen = False;
	If Parameters.Property("GenerateOnOpen", vGenerateOnOpen) Then
		If vGenerateOnOpen <> Undefined And vGenerateOnOpen Then
			GenerateAtServer(ReportSpreadsheet);
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
	vFilePath = StrReplace(cmGetValidFileName(cmNStr(TrimAll(ReportObj.Report))), " ", "_") + "_" + Format(CurrentDate(), "DF=dd.MM.yyyy_HH.mm");
	Return vFilePath;
EndFunction // GetFileName

// -----------------------------------------------------------------------------
&AtServer
Procedure GenerateAtServer(pSpreadsheet)
	vRepObj = FormAttributeToValue("ReportObj");
	cmLoadReportAttributes(vRepObj);
	
	FillPropertyValues(vRepObj, ReportObj, "Hotel, PeriodTo, DoNotShowTotalRoomsRentedPercent, DoNotShowComplimentaryRoomsRentedPercent, UseSlidingPeriod, ShowPreviousYearData, ShowRoomsOccupiedPercent, ShowAmountsWithoutVAT");
	
	pSpreadsheet.Clear();
	
	// Fill spreadsheet
	vRepObj.pmGenerate(pSpreadsheet);
	
	// Apply report print settings and do output other then on screen
	vOutputOnScreen = cmApplyReportPrintSettingsAndDoOutput(vRepObj, pSpreadsheet, 
	                                                        PageOrientation["Portrait"],
	                                                        1, 
	                                                        True, 
	                                                        NStr("en = 'Summary indexes'; de = 'Gesamtindikatoren'; ru = 'Сводные показатели'"));
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
