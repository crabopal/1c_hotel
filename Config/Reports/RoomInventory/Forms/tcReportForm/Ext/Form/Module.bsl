
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
	
	If Parameters.Property("Hotel") Then
		vRepObj.Hotel = Parameters.Hotel;
	EndIf;
	If Parameters.Property("RoomType") Then
		vRepObj.RoomType = Parameters.RoomType;
	EndIf;
	If Parameters.Property("PeriodTo") Then
		vRepObj.PeriodTo = Parameters.PeriodTo;
	EndIf;

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

// -----------------------------------------------------------------------------
&AtClient
Procedure OnClose(pExit)
	If Not pExit Then
		ClearCurrentUnsavedReportSettings(ReportObj.Report);
	EndIf;
EndProcedure // OnClose

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
Procedure Generate(pCommand)
	GenerateAtServer(ReportSpreadsheet);
EndProcedure // Generate

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
&AtServerNoContext
Procedure HotelClearingAtServer(pStandardProcessing)
	pStandardProcessing = tcOnServer.CheckIfHotelCouldBeCleared();
EndProcedure // HotelClearingAtServer

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
	GenerateAtServer(ReportSpreadsheet, vRepObj);
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
Procedure ReportSpreadsheetDetailProcessingAtServer()
	// Вставить содержимое обработчика.
EndProcedure

// -----------------------------------------------------------------------------
&AtServerNoContext
Function CheckRights(pReport)

	Return cmCheckUserRightsToOpenReport(pReport);

EndFunction // CheckRights

Function NStrAtServer(pStr)

	Return cmNStr(pStr);

EndFunction // NStrAtServer()

// -----------------------------------------------------------------------------
&AtClient
Procedure ReportSpreadsheetDetailProcessing(pItem, pDetails, pStandardProcessing, pAdditionalParameters)
	If TypeOf(pDetails) = Type("Structure") Then
		pStandardProcessing = False;
		ReportBuilderDetails = pDetails;
		// fmGenerateReport();
	ElsIf TypeOf(pDetails) = Type("CatalogRef.RoomBlockTypes") Then
		pStandardProcessing = False;
		// Open room blocks report
		vRoomBlockHistoryRep = PredefinedValue("Catalog.Reports.RoomBlocksHistory");
		If Not CheckRights(vRoomBlockHistoryRep) Then
			Raise NStr("en='You do not have rights to run report: ';ru='У вас нет прав на формирование отчета: ';de='Sie haben keine Rechte, einen Bericht zu erstellen:'") + NStrAtServer(vRoomBlockHistoryRep.Description) + "!";
		EndIf;
		
		vFillingValues = New Structure();
		vFillingValues.Insert("ReportRef", vRoomBlockHistoryRep);
		
		vParams = New Structure();
		vParams.Insert("FillingValues", vFillingValues);
		vParams.Insert("GenerateOnOpen", True);
		vParams.Insert("Hotel", ReportObj.Hotel);
		vParams.Insert("Room", ReportObj.Room);
		vParams.Insert("RoomType", ReportObj.RoomType);
		vParams.Insert("RoomBlockType", pDetails);
		vParams.Insert("PeriodFrom", ReportObj.PeriodTo);
		vParams.Insert("PeriodTo", ReportObj.PeriodTo);
		vParams.Insert("PeriodCheckType", PredefinedValue("Enum.PeriodCheckTypes.Intersection"));
		
		OpenForm("Report." + tcOnServer.cmGetAttributeByRef(vRoomBlockHistoryRep, "Report") + ".Form", vParams, ThisForm, New UUID());
	ElsIf TypeOf(pDetails) = Type("CatalogRef.RoomQuotas") Then
		pStandardProcessing = False;
		// Open room quotas report
		vRoomQuotaSalesRep = PredefinedValue("Catalog.Reports.RoomQuotaSales");
		If Not CheckRights(vRoomQuotaSalesRep) Then
			Raise NStr("en='You do not have rights to run report: ';ru='У вас нет прав на формирование отчета: ';de='Sie haben keine Rechte, einen Bericht zu erstellen:'") + NStrAtServer(vRoomQuotaSalesRep.Description) + "!";
		EndIf;
		
		vFillingValues = New Structure();
		vFillingValues.Insert("ReportRef", vRoomBlockHistoryRep);
		
		vParams = New Structure();
		vParams.Insert("FillingValues", vFillingValues);
		vParams.Insert("GenerateOnOpen", True);
		vParams.Insert("ReportRef", vRoomQuotaSalesRep);
		vParams.Insert("Hotel", ReportObj.Hotel);
		vParams.Insert("RoomType", ReportObj.RoomType);
		vParams.Insert("RoomQuota", pDetails);
		vParams.Insert("PeriodFrom", ReportObj.PeriodTo);
		vParams.Insert("PeriodTo", ReportObj.PeriodTo);
		
		OpenForm("Report." + tcOnServer.cmGetAttributeByRef(vRoomQuotaSalesRep, "Report") + ".Form", vParams, ThisForm, New UUID());
	ElsIf TypeOf(pDetails) = Type("CatalogRef.ReservationStatuses") Then
		pStandardProcessing = False;
		// Open reservations history with active reservations only
		vReservationsHistoryRep = PredefinedValue("Catalog.Reports.ReservationsHistory");
		If Not CheckRights(vReservationsHistoryRep) Then
			Raise NStr("en='You do not have rights to run report: ';ru='У вас нет прав на формирование отчета: ';de='Sie haben keine Rechte, einen Bericht zu erstellen:'") + NStrAtServer(vReservationsHistoryRep.Description) + "!";
		EndIf;
		
		vParams = New Structure();
		vParams.Insert("ReportRef", vReservationsHistoryRep);
		vParams.Insert("GenerateOnOpen", True);
		vParams.Insert("Hotel", ReportObj.Hotel);
		vParams.Insert("Room", ReportObj.Room);
		vParams.Insert("RoomType", ReportObj.RoomType);
		vParams.Insert("PeriodFrom", ReportObj.PeriodTo);
		vParams.Insert("PeriodTo", ReportObj.PeriodTo);
		vParams.Insert("PeriodCheckType", PredefinedValue("Enum.PeriodCheckTypes.Intersection"));
		vParams.Insert("ShowActiveOnly", False);
		vParams.Insert("ShowInactiveOnly", False);
		
		OpenForm("Report." + tcOnServer.cmGetAttributeByRef(vReservationsHistoryRep, "Report") + ".Form", vParams, ThisForm, New UUID());
	ElsIf TypeOf(pDetails) = Type("CatalogRef.AccommodationStatuses") Then
		pStandardProcessing = False;
		// Open room occupation history report
		vOccHistoryRep = PredefinedValue("Catalog.Reports.RoomsOccupationHistory");
		If Not CheckRights(vOccHistoryRep) Then
			Raise NStr("en='You do not have rights to run report: ';ru='У вас нет прав на формирование отчета: ';de='Sie haben keine Rechte, einen Bericht zu erstellen:'") + NStrAtServer(vOccHistoryRep.Description) + "!";
		EndIf;
		
		vFillingValues = New Structure();
		vFillingValues.Insert("ReportRef", vOccHistoryRep);
		vFillingValues.Insert("Hotel", ReportObj.Hotel);
		vFillingValues.Insert("Room", ReportObj.Room);
		vFillingValues.Insert("RoomType", ReportObj.RoomType);
		vFillingValues.Insert("PeriodFrom", ReportObj.PeriodTo);
		vFillingValues.Insert("PeriodTo", ReportObj.PeriodTo);
		vFillingValues.Insert("PeriodCheckType", PredefinedValue("Enum.PeriodCheckTypes.Intersection"));
		vFillingValues.Insert("ShowInHouseOnly", False);
		vFillingValues.Insert("ShowNotInHouseOnly", False);
		
		OpenForm("Report." + tcOnServer.cmGetAttributeByRef(vOccHistoryRep, "Report") + ".Form", New Structure("FillingValues", vFillingValues), ThisForm, New UUID());
	ElsIf pDetails = Null Then
		pStandardProcessing = False;
	EndIf;
	
	ReportSpreadsheetDetailProcessingAtServer();
EndProcedure

#EndRegion