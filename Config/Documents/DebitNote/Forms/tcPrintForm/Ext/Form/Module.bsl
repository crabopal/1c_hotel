
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("FormSpreadsheet") Then
		FormSpreadsheet = Parameters.FormSpreadsheet;
	EndIf;
	If Parameters.Property("DebitNote") Then
		DebitNote = Parameters.DebitNote;
	EndIf;
	
	vDocsArray = New Array();
	vDocsArray.Add(DebitNote);
	vDebitNoteObj = DebitNote.GetObject();
	FormSpreadsheet = vDebitNoteObj.pmPrintDocument(vDocsArray);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Print(pCommand)
	FormSpreadsheet.Print();
	ThisForm.Close();
EndProcedure // Print

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePrinter(pCommand)
	FormSpreadsheet.Print(PrintDialogUseMode.Use);
	ThisForm.Close();
EndProcedure // ChoosePrinter

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveAsPDF(pCommand)
	vFilePath = "";
	vFileType = SpreadsheetDocumentFileType.PDF;
	tcOnClient.SaveSpreadsheetToFile(vFileType, vFilePath, FormSpreadsheet);
EndProcedure // SaveAsPDF

#EndRegion
