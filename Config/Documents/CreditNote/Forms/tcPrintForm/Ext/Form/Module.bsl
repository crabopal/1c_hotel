
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("FormSpreadsheet") Then
		FormSpreadsheet = Parameters.FormSpreadsheet;
	EndIf;
	
	If Parameters.Property("CreditNote") Then
		CreditNote = Parameters.CreditNote;
	EndIf;
	
	vDocsArray = New Array();
	vDocsArray.Add(CreditNote);
	vCreditNoteObj = CreditNote.GetObject();
	FormSpreadsheet = vCreditNoteObj.pmPrintDocument(vDocsArray);
	vClear = False;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Print(pCommand)
	FormSpreadsheet.Print();
	Close();
EndProcedure // Print

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePrinter(pCommand)
	FormSpreadsheet.Print(PrintDialogUseMode.Use);
	Close();
EndProcedure // ChoosePrinter

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveAsPDF(pCommand)
	vFilePath = "";
	vFileType = SpreadsheetDocumentFileType.PDF;
	tcOnClient.SaveSpreadsheetToFile(vFileType, vFilePath, FormSpreadsheet);
EndProcedure // SaveAsPDF

#EndRegion
