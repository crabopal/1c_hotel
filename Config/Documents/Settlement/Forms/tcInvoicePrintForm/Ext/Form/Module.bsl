
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("Invoice") Then
		Invoice = Parameters.Invoice;
	EndIf;
	Invoices.Clear();
	If Parameters.Property("Invoices") Then
		Invoices.LoadValues(Parameters.Invoices.UnloadValues());
	ElsIf ValueIsFilled(Invoice) Then
		Invoices.Add(Invoice);
	EndIf;
	FillEMailList();	
	Language = Parameters.Language;
	PrintForm = Undefined;
	If Parameters.Property("PrintForm") Then
		If TypeOf(Parameters.PrintForm) = Type("CatalogRef.ObjectPrintingForms") Then
			PrintForm = Parameters.PrintForm;
		ElsIf TypeOf(Parameters.PrintForm) = Type("Structure") And Parameters.PrintForm.Property("Ref") Then
			PrintForm = Parameters.PrintForm.Ref;
		EndIf;
	EndIf;
	PrintFormType = "";
	If Parameters.Property("PrintFormType") Then
		PrintFormType = Parameters.PrintFormType;
	EndIf;
	vClear = True;
	If PrintFormType = "" Or PrintFormType = "Invoice" Then
		If PrintForm = Undefined Then
			PrintForm = Catalogs.ObjectPrintingForms.SettlementPrintInvoiceRu;
			If Language = Catalogs.Languages.EN Then
				PrintForm = Catalogs.ObjectPrintingForms.SettlementPrintInvoiceEn;
			ElsIf Language = Catalogs.Languages.DE Then
				PrintForm = Catalogs.ObjectPrintingForms.SettlementPrintInvoiceDe;
			EndIf;
		EndIf;
		For Each vInvoiceItem In Invoices Do
			If Not vClear Then
				Spreadsheet.PutHorizontalPageBreak();
			EndIf;
			Documents.Settlement.PrintInvoice(Spreadsheet, vInvoiceItem.Value, Language, PrintForm, vClear);
			vClear = False;
		EndDo;
	ElsIf PrintFormType = "Settlement" Then
		vGroupBy = "";
		If PrintForm.PredefinedDataName = "SettlementPrintSettlementGroupInPricePerFolioPerDayRu" Or
		   PrintForm.PredefinedDataName = "SettlementPrintSettlementGroupInPricePerFolioPerDayEn" Then
			vGroupBy = "InPricePerFolioPerDay";
		ElsIf PrintForm.PredefinedDataName = "SettlementPrintSettlementGroupInPricePerDayRu" Or
		      PrintForm.PredefinedDataName = "SettlementPrintSettlementGroupInPricePerDayEn" Then
			vGroupBy = "InPricePerDay";
		ElsIf PrintForm.PredefinedDataName = "SettlementPrintSettlementGroupPerFolioRu" Or
			  PrintForm.PredefinedDataName = "SettlementPrintSettlementGroupPerFolioEn" Then
			vGroupBy = "PerFolio";
		ElsIf PrintForm.PredefinedDataName = "SettlementPrintSettlementGroupByServiceRu" Or
			  PrintForm.PredefinedDataName = "SettlementPrintSettlementGroupByServiceEn" Then
			vGroupBy = "ByService";
		ElsIf PrintForm.PredefinedDataName = "SettlementPrintSettlementGroupAllPerFolioPerDayRu" Or
			  PrintForm.PredefinedDataName = "SettlementPrintSettlementGroupAllPerFolioPerDayEn" Then
			vGroupBy = "AllPerFolioPerDay";
		ElsIf PrintForm.PredefinedDataName = "SettlementPrintSettlementGroupAllPerDayRu" Or
			  PrintForm.PredefinedDataName = "SettlementPrintSettlementGroupAllPerDayEn" Then
			vGroupBy = "AllPerDay";
		ElsIf PrintForm.PredefinedDataName = "SettlementPrintSettlementGroupInPricePerFolioRu" Or
			  PrintForm.PredefinedDataName = "SettlementPrintSettlementGroupInPricePerFolioEn" Then
			vGroupBy = "InPricePerFolio";
		ElsIf PrintForm.PredefinedDataName = "SettlementPrintSettlementGroupInPriceRu" Or
			  PrintForm.PredefinedDataName = "SettlementPrintSettlementGroupInPriceEn" Then
			vGroupBy = "InPrice";
		ElsIf PrintForm.PredefinedDataName = "SettlementPrintSettlementGroupAllPerFolioRu" Or
			  PrintForm.PredefinedDataName = "SettlementPrintSettlementGroupAllPerFolioEn" Then
			vGroupBy = "AllPerFolio";
		ElsIf PrintForm.PredefinedDataName = "SettlementPrintSettlementGroupAllRu" Or
			  PrintForm.PredefinedDataName = "SettlementPrintSettlementGroupAllEn" Then
			vGroupBy = "All";
		EndIf;
		For Each vInvoiceItem In Invoices Do
			vInvoiceObj = vInvoiceItem.Value.GetObject();
			vInvoiceObj.pmPrintSettlement(Spreadsheet, Language, vGroupBy, PrintForm, Not vClear);
			vClear = False;
		EndDo;
	ElsIf PrintFormType = "VATInvoice" Then
		vGroupBy = "";
		If PrintForm.PredefinedDataName = "SettlementPrintVATInvoiceGroupInPricePerFolioPerDay" Then
			vGroupBy = "InPricePerFolioPerDay";
		ElsIf PrintForm.PredefinedDataName = "SettlementPrintVATInvoiceGroupInPricePerDay" Then
			vGroupBy = "InPricePerDay";
		ElsIf PrintForm.PredefinedDataName = "SettlementPrintVATInvoiceGroupPerFolio" Then
			vGroupBy = "PerFolio";
		ElsIf PrintForm.PredefinedDataName = "SettlementPrintVATInvoiceGroupByService" Then
			vGroupBy = "ByService";
		ElsIf PrintForm.PredefinedDataName = "SettlementPrintVATInvoiceGroupAllPerFolioPerDay" Then
			vGroupBy = "AllPerFolioPerDay";
		ElsIf PrintForm.PredefinedDataName = "SettlementPrintVATInvoiceGroupAllPerDay" Then
			vGroupBy = "AllPerDay";
		ElsIf PrintForm.PredefinedDataName = "SettlementPrintVATInvoiceGroupInPricePerFolio" Then
			vGroupBy = "InPricePerFolio";
		ElsIf PrintForm.PredefinedDataName = "SettlementPrintVATInvoiceGroupInPrice" Then
			vGroupBy = "InPrice";
		ElsIf PrintForm.PredefinedDataName = "SettlementPrintVATInvoiceGroupAllPerFolio" Then
			vGroupBy = "AllPerFolio";
		ElsIf PrintForm.PredefinedDataName = "SettlementPrintVATInvoiceGroupAll" Then
			vGroupBy = "All";
		EndIf;
		For Each vInvoiceItem In Invoices Do
			vInvoiceObj = vInvoiceItem.Value.GetObject();
			vInvoiceObj.pmPrintVATInvoice(Spreadsheet, Language, vGroupBy, PrintForm, Undefined, Not vClear);
			vClear = False;
		EndDo;
	ElsIf PrintFormType = "Settlement7G" Then
		vGroupBy = "InPricePerFolio";
		For Each vInvoiceItem In Invoices Do
			vInvoiceObj = vInvoiceItem.Value.GetObject();
			vInvoiceObj.pmPrintSettlement7G(Spreadsheet, Language, vGroupBy, PrintForm, Not vClear);
			vClear = False;
		EndDo;
	ElsIf PrintFormType = "SettlementHotelProducts" Then
		vGroupBy = "All";
		vGroupBy = "InPricePerFolio";
		For Each vInvoiceItem In Invoices Do
			vInvoiceObj = vInvoiceItem.Value.GetObject();
			vInvoiceObj.pmPrintSettlementHotelProducts(Spreadsheet, Language, vGroupBy, PrintForm, Not vClear);
			vClear = False;
		EndDo;
	EndIf;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	// Get and fill workstation print form settings
	vShowThisForm = False;
	vInvoiceNumber = tcOnServer.cmGetAttributeByRef(Invoice, "Number");
	vCurrentWorkstation = tcOnServer.cmGetSessionParametersAttribute("CurrentWorkstation");
	If ValueIsFilled(vCurrentWorkstation) Then
		vWorkstationPrintSettings = tcOnServer.cmGetAttributeByRef(vCurrentWorkstation, "WorkstationPrintSettings");
		If ValueIsFilled(vWorkstationPrintSettings) Then
			// Try to find records for the current object print form
			vPrintSettingsSet = tcOnServer.GetPrintSettingsArray(vWorkstationPrintSettings, PrintForm);
			If vPrintSettingsSet.Count() = 0 Then
				vShowThisForm = True;
			Else
				For Each vPrintSettings In vPrintSettingsSet Do
					// Fill settings
					tcOnServer.SetSpreadsheetSettings(Spreadsheet, vPrintSettings);
					// Check printing direction
					If vPrintSettings.PrintDirection <> PredefinedValue("Enum.PrintDirections.Screen") Then
						vName = tcOnClient.GetPrintFormFileNameAtClient(vPrintSettings, NStr("de='Rechnung';en='Invoice';ru='Акт'")) + " " + vInvoiceNumber;
						If vPrintSettings.PrintDirection = PredefinedValue("Enum.PrintDirections.Printer") Then
							If IsBlankString(Spreadsheet.PrinterName) Then
								Spreadsheet.Print(False);
							Else
								Spreadsheet.Print(True);
							EndIf;
						EndIf;
					Else
						If Not IsBlankString(Spreadsheet.PrinterName) Then
							Spreadsheet.Print(True);
						EndIf;
						vShowThisForm = True;
					EndIf;
				EndDo;
			EndIf;
		Else
			vShowThisForm = True;
		EndIf;
	Else
		vShowThisForm = True;
	EndIf;
	If Not vShowThisForm Then 	
		pCancel = True;
	EndIf;
EndProcedure // OnOpen

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SendByEMail(Command)
	vParams = GenerateParametersSettlementByEMail();
	OpenForm("CommonForm.tcSendMail", vParams, ThisObject, UUID);
EndProcedure // SendByEMail

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveAsPDF(Command)
	vFilePath = "";
	If ValueIsFilled(Invoice) Then
		vFilePath = StrReplace(NStr("en='Invoice'; ru='Акт'; de='Rechnung'") + " " + tcOnServer.cmGetAttributeByRef(Invoice, "Number"), " ", "_");
	EndIf;
	vFileType = SpreadsheetDocumentFileType.PDF;
	tcOnClient.SaveSpreadsheetToFile(vFileType, vFilePath, Spreadsheet);
EndProcedure // SaveAsPDF

// -----------------------------------------------------------------------------
&AtClient
Procedure SendByAccEMail(pCommand)
	vCompany = tcOnServer.cmGetAttributeByRef(Invoice, "Company");
	If ValueIsFilled(vCompany) Then
		vParams = GenerateParametersSettlementByEMail(tcOnServer.cmGetAttributeByRef(vCompany, "AccountantEmail"));
		OpenForm("CommonForm.tcSendMail", vParams, ThisObject, UUID);
	EndIf;
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Function GenerateParametersSettlementByEMail(pEMails = "")
	If Not ValueIsFilled(Invoice) Then
		Return False;
	EndIf;
	
	// Save current spreadsheet as PDF
	vFileName = StrReplace(Invoice.Metadata().Presentation() + " " + TrimAll(Invoice.Number), " ", "_");
	vFilePath = cmGetFullFileName(vFileName, TempFilesDir()) + ".pdf";
	vFileType = SpreadsheetDocumentFileType.PDF;
	Spreadsheet.Write(vFilePath, vFileType);
	
	// Initialize message texts
	MessageSubject = ?(ValueIsFilled(Invoice.Hotel), Catalogs.Hotels.pmGetHotelPrintName(Invoice.Hotel, Language), "") + 
	                 tcOnServer.cmNStrAtServer("en=' Invoice N" + TrimAll(Invoice.Number) + "'; 
					                           |de=' Rechnung N" + TrimAll(Invoice.Number) + "'; 
	                                           |ru=' Акт №" + TrimAll(Invoice.Number) + "'", Language);
	vIsHTML = False;
	MessageText = "";
	vTemplate = Undefined;
	If ValueIsFilled(Invoice.Hotel) And ValueIsFilled(Invoice.Hotel.TemplateSendSettlementByEMail) Then
		 vTemplate = Invoice.Hotel.TemplateSendSettlementByEMail; 
		 If ValueIsFilled(vTemplate) Then
			If ValueIsFilled(vTemplate.HTMLTextRu) Or ValueIsFilled(vTemplate.HTMLTextEn) Or ValueIsFilled(vTemplate.HTMLTextDe) Then
				MessageText = SMS.GetHTMLTextByLanguage(vTemplate, Language);
				If Not IsBlankString(MessageText) Then
					vIsHTML = True;
				EndIf;
			EndIf;
			If IsBlankString(MessageText) Then
				MessageText = SMS.GetSMSTextByLanguage(vTemplate, Language);
			EndIf; 
		EndIf;
	EndIf;
	If Not IsBlankString(MessageText) Then
		 MessageText = SMS.ReplaceSMSParameters(MessageText, Invoice.Ref);
	EndIf;	
	If IsBlankString(MessageText) Then					 
		 MessageText = tcOnServer.cmNStrAtServer("en='Invoice number is " + TrimAll(Invoice.Number) + "'; 
		 |de='Rechnungsnummer ist " + TrimAll(Invoice.Number) + "'; 
		 |ru='Номер акта " + TrimAll(Invoice.Number) + "'",
		 Language) + Chars.LF + Chars.LF +
		 tcOnServer.cmNStrAtServer("en='Best regards,'; 
		 |de='Freundliche Grüße,'; 
		 |ru='С уважением,'",
		 Language) + Chars.LF + 
		 ?(ValueIsFilled(Invoice.Hotel), Catalogs.Hotels.pmGetHotelPrintName(Invoice.Hotel, Language), "") + Chars.LF + 
		 tcOnServer.cmNStrAtServer(SessionParameters.ConfigurationName, Language);
	EndIf;		  
	// Call user exit procedure to give possibility to override message subject and message text
	vUserExitProc = Catalogs.ExternalDataProcessors.SendSettlementByEMail;
	If ValueIsFilled(vUserExitProc) Then
		If vUserExitProc.ExternalProcessingType = Enums.ExternalProcessingTypes.Algorithm Then
			If Not IsBlankString(vUserExitProc.Algorithm) Then
				SetSafeMode(True);
				Execute(TrimAll(vUserExitProc.Algorithm));
				SetSafeMode(False);
			EndIf;
		EndIf;
	EndIf;
	
	vParams = New Structure();
	vParams.Insert("SelMessageSubject", MessageSubject);
	vParams.Insert("SelMessageText", MessageText);
	If Not IsBlankString(String(pEMails)) Then
		vParams.Insert("SelEMails", pEMails);
	Else
		vParams.Insert("SelEMails", EMailList);
	EndIf;
	vFile = New Structure();
	vFile.Insert("FileName", cmGetValidFileName(MessageSubject)+".pdf");
	vFile.Insert("FullFileNameAtClient", "");
	vFile.Insert("FullFileNameAtServer", vFilePath);
	vFile.Insert("CheckRemoveAtClient",  False);
	vFile.Insert("CheckRemoveAtServer", True);
	vParams.Insert("SelFile", vFile);
	vParams.Insert("SelLanguage", Language);
	vParams.Insert("SelGuestGroup", Invoice.GuestGroup);
	vParams.Insert("SelSenderName", "");
	vParams.Insert("SelHotel", Invoice.Hotel);
	vParams.Insert("IsHTML", vIsHTML); 
	vParams.Insert("SelSMSTemplates", vTemplate);
	Return vParams;
EndFunction // GenerateParametersSettlementByEMail

// -----------------------------------------------------------------------------
&AtServer
Procedure FillEMailList()
	If ValueIsFilled(Invoice) And Invoices.Count() <= 1 Then
		EMailList.Clear();
		If TypeOf(Invoice.ParentDoc) = Type("DocumentRef.Folio") Then 
			vClient = Invoice.ParentDoc.Client; 
		ElsIf TypeOf(Invoice.ParentDoc) = Type("DocumentRef.Accommodation") or TypeOf(Invoice.ParentDoc) = Type("DocumentRef.Reservation")  Then		
			vClient = Invoice.ParentDoc.Guest; 
		ElsIf TypeOf(Invoice.ParentDoc) = Type("DocumentRef.ResourceReservation") Then	
			vClient = Invoice.ParentDoc.Client; 		
		Else
			vClient = Invoice.GuestGroup.Client; 
		EndIf;
		If ValueIsFilled(vClient.Email) Then
			EMailList.Add(vClient.Email);
		EndIf;
		If ValueIsFilled(Invoice.AccountingCustomer.Email) Then
			EMailList.Add(Invoice.AccountingCustomer.Email);
		EndIf;
		If EMailList.Count() > 0 Then
			Items.FormSendByEMail.Enabled = True;
		Else
			Items.FormSendByEMail.Enabled = False;
		EndIf;
		If ValueIsFilled(Invoice.Hotel.Company.AccountantEmail) Then
			Items.FormSendByAccEMail.Enabled = True;
		Else
			Items.FormSendByAccEMail.Enabled = False;
		EndIf;
	Else
		Items.FormSendByEMail.Enabled = False;
		Items.FormSendByAccEMail.Enabled = False;
	EndIf;
EndProcedure // FillEMailList

#EndRegion
