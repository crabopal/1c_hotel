
#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pParameter	 - Any - Dataprocessor attribute
//
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

// -----------------------------------------------------------------------------
//  Initialize attributes with default values
//  Attention: This procedure could be called AFTER some attributes initialization
//  routine, so it SHOULD NOT reset attributes being set before
//  -----------------------------------------------------------------------------
//
Procedure pmFillAttributesWithDefaultValues() Export
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
//  Run data processor in silent mode
//  -----------------------------------------------------------------------------
//
// Parameters:
//  pParameter		 - Any - Dataprocessor attribute
//  pIsInteractive	 - Boolean - Is interactive mode
//
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	pmRunAndSendReports(pIsInteractive, , , pParameter);
EndProcedure // pmRun

// -----------------------------------------------------------------------------
//
// Parameters:
//  pIsInteractive	 - Boolean		 - Is interactive mode
//  rDoPrint		 - Boolean		 - do print
//  pLanguage		 - CatalogRef.Languages	 - Ref
//
Procedure pmRunAndSendReports(pIsInteractive = False, rDoPrint = Undefined, pLanguage = Undefined, pParameter = Undefined) Export  
	vFuncName = NStr("en='DataProcessor.RunAndSendReports';ru='Обработка.ФормированиеИРассылкаОтчетов';de='DataProcessor.RunAndSendReports'");
	WriteLogEvent(vFuncName, EventLogLevel.Information, Undefined, Undefined, NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'"));
	
	// Do for each report in settings
	vFilePath = "";
	pSendEMail = False;
	vEMailAdress = EMailAdress; 
	vAttachments = New Map;
	For Each vReportsRow In ReportsList Do
		Try
			If vReportsRow.IsActive Then
				// Create report object
				vReportObj = cmBuildReportObject(vReportsRow.Report);
				vReportObj.Report = vReportsRow.Report;
				vReportObj.pmLoadReportAttributes();
				FillPropertyValues(vReportObj, New Structure("Hotel", Hotel), "Hotel");
				
				// Create spreadsheet
				vSpreadsheet = New SpreadsheetDocument();
				
				// Set report builder attributes
				Try
					cmSetReportBuilderAttributes(vReportObj, cmGetReportBuilderAttributesStructure());
				Except
				EndTry;
				
				// Fill spreadsheet
				vReportObj.pmGenerate(vSpreadsheet);

				// Generate other reports in package
				If ValueIsFilled(vReportObj.Report) Then
					If vReportObj.Report.IsPackage Then
						GenerateReportsInThePackage(vReportObj.Report, vReportObj, vSpreadsheet, pParameter);
					EndIf;
				EndIf;
				
				// Setup default attributes
				cmSetDefaultPrintFormSettings(vSpreadsheet, 
				                              ?(vReportsRow.PageOrientation = Enums.PageOrientations.Landscape, PageOrientation.Landscape, PageOrientation.Portrait), 
				                              vReportsRow.FitToPage, 
				                              vReportsRow.Copies, 
				                              vReportsRow.BlackAndWhite);
				
				// Check authorities
				cmSetSpreadsheetProtection(vSpreadsheet);
				
				// Fill settings
				cmSetSpreadsheetSettings(vSpreadsheet, vReportsRow);
				
				// Check printing direction
				vName = cmGetPrintFormFileName(vReportsRow);
				
				// Save report as file
				If vReportsRow.PrintDirection <> Enums.PrintDirections.Screen Then
					cmDoSpreadsheetOutput(vSpreadsheet, vReportsRow, vName, , rDoPrint, pSendEMail, vFilePath);
				Else
					Raise NStr("en='Output report to screen is not supported at server!'; 
					           |ru='Вывод отчета на экран на сервере не поддерживается!'; 
					           |de='Ausgabe des Berichts auf dem Bildschirm wird auf dem Server nicht unterstützt!'");
				EndIf;
			EndIf;   
			
			// Save file path in the map
			vAttachments.Insert(vName, vFilePath);
		Except
			vMessage = cmGetRootErrorDescription(ErrorInfo());
			WriteLogEvent(vFuncName, EventLogLevel.Warning, Undefined, Undefined, vMessage);
			If pIsInteractive Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			EndIf;
		EndTry;
	EndDo;
	
	If SendEMail Then 
		// Execute in the background
		vLanguage = pLanguage;
		If Not ValueIsFilled(vLanguage) Then
			vLanguage = SessionParameters.CurrentLanguage;
		EndIf;	
		vMessageSubject = TrimAll(MessageSubject);
		If IsBlankString(vMessageSubject) Then
			vMessageSubject = NStr("en='Sending reports'; ru='Рассылка отчетов'; de='Senden von Berichten'");
		EndIf;
		vMessageText = TrimAll(MessageText);
		If IsBlankString(vMessageText) Then
			vMessageText = NStr("en='Reports are in files attached to the letter'; ru='Отчеты в прикрепленных к письму в файлах'; de='Berichte in Dateien, die an eine E-Mail angehängt sind'");
		EndIf;
		 
		JobsScheduled.cmSendFilesByEMail(vMessageSubject, vMessageText, vEMailAdress, vAttachments, vLanguage, True, Undefined);
	EndIf;

	WriteLogEvent(vFuncName, EventLogLevel.Information, Undefined, Undefined, NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'"));
EndProcedure // pmRunAndSendReports

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure GenerateReportsInThePackage(pReport, pParentRepObj, pSpreadsheet, pParameter = Undefined)
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
				
				// Fill spreadsheet
				vRepObj.pmGenerate(pSpreadsheet);
			Except
				Continue;
			EndTry;
		EndIf;
	EndDo;
EndProcedure // GenerateReportsInThePackage

#EndRegion