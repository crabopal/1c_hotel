
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("DocumentsList") Then
		DocumentsList.LoadValues(Parameters.DocumentsList.UnloadValues());
		ObjectPrintingForm = Catalogs.ObjectPrintingForms.SMSDeliveryPrintReceivers;
		If Parameters.Property("ObjectPrintingForm") And ValueIsFilled(Parameters.ObjectPrintingForm) Then
			ObjectPrintingForm = Parameters.ObjectPrintingForm;
		EndIf;
		UseHTML = False;
		If Parameters.Property("UseHTML") Then
			UseHTML = Parameters.UseHTML;
		EndIf;
	EndIf;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	rDoPrint = Undefined;
	PrintReceivers(rDoPrint);
	If rDoPrint <> Undefined Then
		rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
		pCancel = True;
	EndIf;
EndProcedure // OnOpen

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
Procedure SaveAsXLS(pCommand)
	vFilePath = "";
	vFileType = SpreadsheetDocumentFileType.XLSX;
	tcOnClient.SaveSpreadsheetToFile(vFileType, vFilePath, FormSpreadsheet);
EndProcedure // SaveAsXLS

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure PrintReceivers(rDoPrint = Undefined)
	If UseHTML Then
		Documents.SMSDelivery.pmPrintEMailReceivers(DocumentsList, FormSpreadsheet, ObjectPrintingForm, SessionParameters.CurrentLanguage, rDoPrint);
	Else
		Documents.SMSDelivery.pmPrintSMSReceivers(DocumentsList, FormSpreadsheet, ObjectPrintingForm, SessionParameters.CurrentLanguage, rDoPrint);
	EndIf;
EndProcedure // PrintReceivers

#EndRegion
