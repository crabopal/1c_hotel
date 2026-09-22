// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	cmSetSpreadsheetProtection(Items.Spreadsheet);
	PrintSurvey();
EndProcedure // OnCreateAtServer


// -----------------------------------------------------------------------------
&AtServer
Procedure PrintSurvey()
	// Call invoice object procedure
	If Not ValueIsFilled(Parameters.Ref) Then
		Return;
	EndIf;
	Spreadsheet.Clear();
	Spreadsheet = Catalogs.Surveys.GetSurveySpreadsheet(Parameters.Ref);
EndProcedure // PrintInvoice

// -----------------------------------------------------------------------------
&AtClient
Procedure OnReopen()
	// Draw invoice form
	PrintSurvey();
EndProcedure // OnReopen

// -----------------------------------------------------------------------------
&AtClient
Procedure Print(pCommand)
	Spreadsheet.Print(PrintDialogUseMode.DontUse);
	ThisForm.Close();
EndProcedure // Print

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePrinter(pCommand)
	Spreadsheet.Print(PrintDialogUseMode.Use);
	ThisForm.Close();
EndProcedure // ChoosePrinter

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveAsPDF(pCommand)
	vFilePath = "";
	If ValueIsFilled(Parameters.Ref) Then
		vFilePath = StrReplace(tcOnServer.cmGetMetadataMethodOrAttribiteByRef(Parameters.Ref, "Presentation"), " ", "_");
	EndIf;
	vFileType = SpreadsheetDocumentFileType.PDF;
	tcOnClient.SaveSpreadsheetToFile(vFileType, vFilePath, Spreadsheet);
EndProcedure // SaveAsPDF


