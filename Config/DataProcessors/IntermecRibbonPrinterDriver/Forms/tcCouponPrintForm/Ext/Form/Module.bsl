// -----------------------------------------------------------------------------
&AtServer
Function Print()
	DataProcessors.IntermecRibbonPrinterDriver.pmPrint(FormSpreadsheet, SelLanguage, SelObjList, Object.RibbonPrinterConnectionParameters);	
EndFunction//Print 

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	Print();		
EndProcedure // OnOpen

// -----------------------------------------------------------------------------
&AtClient
Procedure OnReopen()
	Print();
EndProcedure // OnReopen

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintButton(pCommand)
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
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	cmSetSpreadsheetProtection(Items.FormSpreadsheet);
	If Parameters.Property("SelObjList") Then
		SelObjList = Parameters.SelObjList;	
	EndIf;
	If Parameters.Property("SelLanguage") Then
		SelLanguage = Parameters.SelLanguage;	
	EndIf;
	If Parameters.Property("RibbonPrinterConnectionParameters") Then
		Object.RibbonPrinterConnectionParameters = Parameters.RibbonPrinterConnectionParameters;	
	EndIf;
EndProcedure // OnCreateAtServer

