
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	ThisForm.Height = 297;
	ThisForm.Width = 210;
	RadioButtonServicesFilter = 0;
	cmSetSpreadsheetProtection(Items.FolioSpreadsheet);
	If Parameters.Property("InputParameter") Then
		SelFolio = Parameters.InputParameter;
		SelLanguage = Parameters.ObjectPrintingForm.Language;
		SelObjectPrintForm = Parameters.ObjectPrintingForm;
		vList = Parameters.Transactions; 
		If TypeOf(vList) = Type("ValueList") Then
			SelTransactions.LoadValues(vList.UnloadValues());
		ElsIf TypeOf(vList) = Type("Array") Then	
			SelTransactions.LoadValues(vList);
		EndIf;	
	EndIf;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	vError = Print();
	If Not IsBlankString(vError) Then
		ShowMessageBox(,vError);
		Close();
	EndIf;
EndProcedure // OnOpen

// -----------------------------------------------------------------------------
&AtClient
Procedure OnReopen()
	vError = Print();
	If Not IsBlankString(vError) Then
		ShowMessageBox(,vError);
		Close();
	EndIf;
EndProcedure // OnReopen

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintButton(pCommand)
	FolioSpreadsheet.Print();
	ThisForm.Close();
EndProcedure // Print

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePrinter(pCommand)
	FolioSpreadsheet.Print(PrintDialogUseMode.Use);
	ThisForm.Close();
EndProcedure // ChoosePrinter

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveAsPDF(pCommand)
	vFilePath = "";
	If ValueIsFilled(SelFolio) Then
		vFilePath = StrReplace(NStr("en='PKO';ru='ПКО';de='PKO'") + "_" + Format(tcOnServer.cmGetAttributeByRef(SelFolio, "GuestGroup.Code"), "ND=12; NFD=0; NG="), " ", "_");
	EndIf;
	vFileType = SpreadsheetDocumentFileType.PDF;
	tcOnClient.SaveSpreadsheetToFile(vFileType, vFilePath, FolioSpreadsheet);
EndProcedure // SaveAsPDF



#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Function Print()
	If ValueIsFilled(SelFolio) Then
		vFolioObj = SelFolio.GetObject();
		vTemplate = vFolioObj.GetTemplate("PKO_Ru");
		Documents.Folio.PrintPKO(FolioSpreadsheet, vTemplate, SelTransactions, SelObjectPrintForm);	
	EndIf;
EndFunction//Print 

#EndRegion




