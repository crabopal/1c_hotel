
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("Document") Then
		Report.Document = Parameters.Document;
	EndIf;	
	
	If Parameters.Property("SelObjectPrintForm") Then 
		SelObjectPrintForm = Parameters.SelObjectPrintForm;
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	// Check attributes
	If CheckAttributes() Then
		rDoPrint = Undefined;
		GenerateAtServer(rDoPrint);
		If rDoPrint <> Undefined Then
			rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
			pCancel = True;
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Generate(Command)
	// Check attributes
	If CheckAttributes() Then
		rDoPrint = Undefined;
		GenerateAtServer(rDoPrint);
		If rDoPrint <> Undefined Then
			rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
		EndIf;
	EndIf;
EndProcedure // Generate

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePrinter(Command)
	ReportSpreadsheet.Print(PrintDialogUseMode.Use);
	ThisForm.Close();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure Print(Command)
	ReportSpreadsheet.Print(PrintDialogUseMode.DontUse);
	ThisForm.Close();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveAsPDF(Command)
	vFilePath = "";
	If ValueIsFilled(Report.Document) Then
		vFilePath = StrReplace(tcOnServer.cmGetMetadataMethodOrAttribiteByRef(Report.Document, "Presentation") + " " + StrReplace(TrimAll(tcOnServer.cmGetAttributeByRef(Report.Document, "Number")), "/", "-"), " ", "_");
	EndIf;
	vFileType = SpreadsheetDocumentFileType.PDF;
	tcOnClient.SaveSpreadsheetToFile(vFileType, vFilePath, ReportSpreadsheet);
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtClient
Function CheckAttributes()
	If Not ValueIsFilled(Report.Document) Then
		ShowMessageBox(, NStr("ru = 'Для печати должен быть выбран документ!'; 
		                      |en = 'A document should be selected for printing!';
							  |de = 'Ein Dokument sollte zum drucken ausgewählt werden!'"), , 
		                 NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
		Return False;
	EndIf;
	Return True;
EndFunction // CheckAttributes

// -----------------------------------------------------------------------------
&AtServer
Procedure GenerateAtServer(rDoPrint = Undefined)
	// Get output spreadsheet
	vSpreadsheet = ReportSpreadsheet;
	
	// Load external printing form template
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(SelObjectPrintForm);
	
	// Print
	vReportObj = FormAttributeToValue("Report");
	vReportObj.pmGenerate(vSpreadsheet, vExtTemplate);
	
	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Portrait);
	// Check authorities
	cmSetSpreadsheetProtection(vSpreadsheet);
	// Get and fill workstation print form settings
	vShowThisForm = False;
	If ValueIsFilled(SessionParameters.CurrentWorkstation) Then
		vWorkstationPrintSettings = SessionParameters.CurrentWorkstation.WorkstationPrintSettings;
		If ValueIsFilled(vWorkstationPrintSettings) Then
			// Try to find records for the current object print form
			vFilter = New Structure("ObjectPrintingForm, IsActive", SelObjectPrintForm, True); 
			vPrintSettingsSet = vWorkstationPrintSettings.PrintFormsList.FindRows(vFilter);
			If Not vPrintSettingsSet.Count() = 0 Then
				For Each vPrintSettings In vPrintSettingsSet Do
					// Fill settings
					cmSetSpreadsheetSettings(vSpreadsheet, vPrintSettings);
					// Check printing direction
					If vPrintSettings.PrintDirection <> Enums.PrintDirections.Screen Then
						vName = cmGetPrintFormFileName(vPrintSettings, NStr("ru = 'Документы на возврат'; en = 'Return forms'"));
						cmDoSpreadsheetOutput(vSpreadsheet, vPrintSettings, vName, , rDoPrint);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // GenerateAtServer

#EndRegion
