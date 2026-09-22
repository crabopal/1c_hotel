// -----------------------------------------------------------------------------
&AtServer
Procedure Print(rDoPrint = Undefined)
	If ValueIsFilled(SelAcc) Then
		vAccObj = Documents.Accommodation.CreateDocument();
		If SelObjectPrintForm = Catalogs.ObjectPrintingForms.AccommodationPrintGuestPersonalDataProcessingConsent Or 
		   SelObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintGuestPersonalDataProcessingConsent Then 
			vTemplate = vAccObj.GetTemplate("PrintGuestPersonalDataProcessingConsent");
			Documents.Accommodation.PrintGuestPersonalDataProcessingConsent(ValueListAccommodations, FormSpreadsheet, vTemplate, SelObjectPrintForm, rDoPrint);	
		ElsIf SelObjectPrintForm = Catalogs.ObjectPrintingForms.AccommodationPrintGuestRefusalToPayResortFee Then 
			vTemplate = vAccObj.GetTemplate("PrintGuestRefusalToPayResortFee");
			Documents.Accommodation.PrintGuestRefusalToPayResortFee(ValueListAccommodations, FormSpreadsheet, vTemplate, SelObjectPrintForm, rDoPrint);
		EndIf;
	EndIf;
EndProcedure // Print 

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	rDoPrint = Undefined;
	Print(rDoPrint);
	If rDoPrint <> Undefined Then
		rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
		pCancel = true;
	EndIf;
EndProcedure // OnOpen

// -----------------------------------------------------------------------------
&AtClient
Procedure OnReopen()
	rDoPrint = Undefined;
	Print(rDoPrint);
	If rDoPrint <> Undefined Then
		rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
	EndIf;
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
&AtClient
Procedure SaveAsPDF(pCommand)
	vFilePath = "";
	If ValueIsFilled(SelAcc) Then
		vFilePath = StrReplace(NStr("en='PKO';ru='ПКО';de='PKO'") + "_" + Format(tcOnServer.cmGetAttributeByRef(SelAcc, "GuestGroup.Code"), "ND=12; NFD=0; NG="), " ", "_");
	EndIf;
	vFileType = SpreadsheetDocumentFileType.PDF;
	tcOnClient.SaveSpreadsheetToFile(vFileType, vFilePath, FormSpreadsheet);
EndProcedure // SaveAsPDF

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	ThisForm.Height = 297;
	ThisForm.Width = 210;
	RadioButtonServicesFilter = 0;
	cmSetSpreadsheetProtection(Items.FormSpreadsheet);
	If Parameters.Property("InputParameter") Then
		If Parameters.InputParameter.Count() > 0 Then 
			SelAcc = Parameters.InputParameter[0].Value;
		EndIf;
		ValueListAccommodations = Parameters.InputParameter;
		SelLanguage = ?(ValueIsFilled(Parameters.Lang), Parameters.Lang, Parameters.ObjectPrintingForm.Language);
		SelObjectPrintForm = Parameters.ObjectPrintingForm;
	EndIf;
EndProcedure // OnCreateAtServer

