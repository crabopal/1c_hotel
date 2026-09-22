
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	// Draw form
	PrintDeclaration();
EndProcedure // OnOpen

// -----------------------------------------------------------------------------
&AtClient
Procedure OnReopen()
	// Draw form
	PrintDeclaration();
EndProcedure // OnReopen

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("Document") Then
		SelDeclaration = Parameters.Document;
	EndIf;
	If Parameters.Property("Language") Then
		SelLanguage = Parameters.Language;
	EndIf;
	If Parameters.Property("PrintForm") Then
		SelObjectPrintForm = Parameters.PrintForm;
	EndIf;
	cmSetSpreadsheetProtection(Items.DeclarationSpreadsheet);
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Run(pCommand)
	PrintDeclaration();
EndProcedure  

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveAsXLSX(pCommand)
	vFilePath = "";
	If ValueIsFilled(SelDeclaration) Then
		vFilePath = StrReplace(tcOnServer.cmGetMetadataMethodOrAttribiteByRef(SelDeclaration, "Presentation") + " " + StrReplace(TrimAll(tcOnServer.cmGetAttributeByRef(SelDeclaration, "Number")), "/", "-"), " ", "_");
	EndIf;
	vFileType = SpreadsheetDocumentFileType.XLSX;
	tcOnClient.SaveSpreadsheetToFile(vFileType, vFilePath, DeclarationSpreadsheet);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure Print(pCommand)
	DeclarationSpreadsheet.Print(PrintDialogUseMode.DontUse);
	ThisForm.Close();
EndProcedure // Print

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePrinter(pCommand)
	DeclarationSpreadsheet.Print(PrintDialogUseMode.Use);
	ThisForm.Close();
EndProcedure // ChoosePrinter

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveAsPDF(pCommand)
	vFilePath = "";
	If ValueIsFilled(SelDeclaration) Then
		vFilePath = StrReplace(tcOnServer.cmGetMetadataMethodOrAttribiteByRef(SelDeclaration, "Presentation") + " " + StrReplace(TrimAll(tcOnServer.cmGetAttributeByRef(SelDeclaration, "Number")), "/", "-"), " ", "_");
	EndIf;
	vFileType = SpreadsheetDocumentFileType.PDF;
	tcOnClient.SaveSpreadsheetToFile(vFileType, vFilePath, DeclarationSpreadsheet);
EndProcedure // SaveAsPDF

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure PrintDeclaration()
	Documents.TouristTaxDeclarationRU.PrintDeclaration(DeclarationSpreadsheet, SelDeclaration, SelLanguage, SelObjectPrintForm, SelTaxAgency, SelByLocationOfAccounting,
		SelDistrictName, SelDistrictType, SelSettlementName, SelSettlementType, SelCityName, SelCityType, SelPlanName, SelPlanType,  SelNetName , SelNetType,
		SelLandNum, SelHouse1Name, SelHouse1Type, SelHouse2Name, SelHouse2Type, SelHouse3Name, SelHouse3Type, SelRoomName, SelRoomType)
EndProcedure // PrintInvoice

#EndRegion
