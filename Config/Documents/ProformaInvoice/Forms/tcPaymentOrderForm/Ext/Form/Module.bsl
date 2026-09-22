
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	// Draw payment order
	PrintPaymentOrder();
	FillEMailList();
	
	// Get and fill workstation print form settings
	vShowThisForm = False;
	vInvoiceNumber = GetInvoiceNumberAtServer();
	vCurrentWorkstation = tcOnServer.cmGetSessionParametersAttribute("CurrentWorkstation");
	If ValueIsFilled(vCurrentWorkstation) Then
		vWorkstationPrintSettings = tcOnServer.cmGetAttributeByRef(vCurrentWorkstation, "WorkstationPrintSettings");
		If ValueIsFilled(vWorkstationPrintSettings) Then
			// Try to find records for the current object print form
			vPrintSettingsSet = tcOnServer.GetPrintSettingsArray(vWorkstationPrintSettings, SelObjectPrintForm);
			If vPrintSettingsSet.Count() = 0 Then
				vShowThisForm = True;
			Else
				For Each vPrintSettings In vPrintSettingsSet Do
					// Fill settings
					tcOnServer.SetSpreadsheetSettings(PaymentOrderSpreadsheet, vPrintSettings);
					// Check printing direction
					If vPrintSettings.PrintDirection <> PredefinedValue("Enum.PrintDirections.Screen") Then
						vName = tcOnClient.GetPrintFormFileNameAtClient(vPrintSettings, NStr("en='Payment order for invoice N';ru='Платежное поручение по счету №';de='Zahlungsauftrag zur Rechnung Nr.'")) + " " + vInvoiceNumber;
						If vPrintSettings.PrintDirection = PredefinedValue("Enum.PrintDirections.Printer") Then
							If IsBlankString(PaymentOrderSpreadsheet.PrinterName) Then
								PaymentOrderSpreadsheet.Print(False);
							Else
								PaymentOrderSpreadsheet.Print(True);
							EndIf;
						EndIf;
					Else
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

// -----------------------------------------------------------------------------
&AtClient
Procedure OnReopen()
	// Draw payment order
	PrintPaymentOrder();
	FillEMailList();
EndProcedure // OnReopen

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("Invoice") Then
		SelInvoice = Parameters.Invoice;
	EndIf;
	Invoices.Clear();
	If Parameters.Property("Invoices") Then
		Invoices.LoadValues(Parameters.Invoices.UnloadValues());
	Else
		If ValueIsFilled(SelInvoice) Then
			Invoices.Add(SelInvoice);
		EndIf;
	EndIf;
	If Parameters.Property("Language") Then
		SelLanguage = Parameters.Language;
	EndIf;
	If Parameters.Property("PrintForm") Then
		SelObjectPrintForm = Parameters.PrintForm;
	EndIf;
	Height = 297;
	Width = 210;
	cmSetSpreadsheetProtection(Items.PaymentOrderSpreadsheet);
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Print(pCommand)
	PaymentOrderSpreadsheet.Print(PrintDialogUseMode.Use);
	Close();
EndProcedure // Print

// -----------------------------------------------------------------------------
&AtClient
Procedure SendByEMail(pCommand)
	vParams = GenerateParametersInvoiceByEMail();
	OpenForm("CommonForm.tcSendMail", vParams, ThisObject, UUID);
EndProcedure // SendByEMail

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Function GetInvoiceNumberAtServer()
	Return cmGetDocumentNumberPresentation(SelInvoice.Number);
EndFunction // GetInvoiceNumberAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure PrintPaymentOrder()
	// Call invoice object procedure
	If Not ValueIsFilled(SelInvoice) And Invoices.Count() = 0 Then
		Return;
	EndIf;
	FillEMailList();
	vInvoiceNumber = "";
	vClear = True;
	For Each vInvoiceItem In Invoices Do
		If Invoices.IndexOf(vInvoiceItem) > 0 Then
			PaymentOrderSpreadsheet.PutHorizontalPageBreak();
		EndIf;
		Documents.ProformaInvoice.pmPrintPaymentOrder(PaymentOrderSpreadsheet, vInvoiceItem.Value, SelLanguage, SelObjectPrintForm, vClear);
		vClear = False;
	EndDo;
EndProcedure // PrintPaymentOrder

// -----------------------------------------------------------------------------
&AtServer
Function GenerateParametersInvoiceByEMail()
	// Save current spreadsheet as PDF
	vFileName = StrReplace(tcOnServer.cmNStrAtServer("en='Payment order for invoice N" + StrReplace(cmGetDocumentNumberPresentation(SelInvoice.Number), "/", "-") + "'; 
	                                                 |de='Payment order for invoice N" + StrReplace(cmGetDocumentNumberPresentation(SelInvoice.Number), "/", "-") + "'; 
	                                                 |ru='Платежное поручение по счету №" + StrReplace(cmGetDocumentNumberPresentation(SelInvoice.Number), "/", "-") + "'", 
	                              SelLanguage), " ", "_");
	vFilePath = cmGetFullFileName(vFileName, TempFilesDir()) + ".pdf";
	vFileType = SpreadsheetDocumentFileType.PDF;
	PaymentOrderSpreadsheet.Write(vFilePath, vFileType);
	// Initialize message texts
	MessageSubject = ?(ValueIsFilled(SelInvoice.Hotel), Catalogs.Hotels.pmGetHotelPrintName(SelInvoice.Hotel, SelLanguage), "") + 
	                 tcOnServer.cmNStrAtServer("en=' Payment order for invoice N" + cmGetDocumentNumberPresentation(SelInvoice.Number) + "'; 
					                           |de=' Payment order for invoice N" + cmGetDocumentNumberPresentation(SelInvoice.Number) + "'; 
	                                           |ru=' Платежное поручение по счету №" + cmGetDocumentNumberPresentation(SelInvoice.Number) + "'", 
	                        SelLanguage);
	MessageText = tcOnServer.cmNStrAtServer("en='Your invoice number is " + cmGetDocumentNumberPresentation(SelInvoice.Number) + "'; 
				                            |de='Your invoice number is " + cmGetDocumentNumberPresentation(SelInvoice.Number) + "'; 
	                                        |ru='Номер счета " + cmGetDocumentNumberPresentation(SelInvoice.Number) + "'",
	                     SelLanguage) + Chars.LF + Chars.LF +
	              tcOnServer.cmNStrAtServer("en='Best regards,'; 
				                            |de='Best regards,'; 
	                                        |ru='С уважением,'",
	                     SelLanguage) + Chars.LF + 
	              ?(ValueIsFilled(SelInvoice.Hotel), Catalogs.Hotels.pmGetHotelPrintName(SelInvoice.Hotel, SelLanguage), "") + Chars.LF + 
			      tcOnServer.cmNStrAtServer(SessionParameters.ConfigurationName, SelLanguage);
	// Call user exit procedure to give possibility to override message subject ans message text
	vUserExitProc = Catalogs.ExternalDataProcessors.SendPaymentOrderByEMail;
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
	vParams.Insert("SelEMails", "");
	vParams.Insert("SelToList", EMailList);
	vFile = New Structure();
	vFile.Insert("FileName", cmGetValidFileName(MessageSubject)+".pdf");
	vFile.Insert("FullFileNameAtClient", "");
	vFile.Insert("FullFileNameAtServer", vFilePath);
	vFile.Insert("CheckRemoveAtClient",  False);
	vFile.Insert("CheckRemoveAtServer", True);
	vParams.Insert("SelFile", vFile);
	vParams.Insert("SelLanguage", SelLanguage);
	vParams.Insert("SelGuestGroup", SelInvoice.GuestGroup);
	vParams.Insert("SelSenderName", "");
	vParams.Insert("SelHotel", SelInvoice.Hotel);
	vParams.Insert("SelDocument", SelInvoice);
	Return vParams;
EndFunction // GenerateParametersInvoiceByEMail

// -----------------------------------------------------------------------------
&AtServer
Procedure FillEMailList()
	EMailList.Clear();
	If ValueIsFilled(SelInvoice.EMail) Then
		EMailList.Add(SelInvoice.EMail);
	EndIf;
	If ValueIsFilled(SelInvoice.AccountingCustomer.EMail) Then
		EMailList.Add(SelInvoice.AccountingCustomer.EMail);
	EndIf;
	vReservation = SelInvoice.ParentDoc;
	If ValueIsFilled(vReservation) And TypeOf(vReservation) = Type("DocumentRef.Settlement") Then
		vReservation = Undefined;
	EndIf;
	If Not ValueIsFilled(vReservation) And ValueIsFilled(SelInvoice.GuestGroup) And ValueIsFilled(SelInvoice.GuestGroup.ClientDoc) Then
		vReservation = SelInvoice.GuestGroup.ClientDoc;
	EndIf;
	If ValueIsFilled(vReservation) Then
		If TypeOf(vReservation) = Type("DocumentRef.Folio") Then
			If Not IsBlankString(vReservation.Client.EMail) Then
				EMailList.Add(vReservation.Client.EMail);
			EndIf;
		ElsIf TypeOf(vReservation) = Type("DocumentRef.ResourceReservation") Then
			If Not IsBlankString(vReservation.Client.EMail) Then
				EMailList.Add(vReservation.Client.EMail);
			EndIf;
			If Not IsBlankString(vReservation.ContactPerson) Then
				vContactPersonEMail = cmGetContactPersonEMail(vReservation.ContactPerson);
				If Not IsBlankString(vContactPersonEMail) Then
					EMailList.Add(vContactPersonEMail);
				EndIf;
			EndIf;
		ElsIf TypeOf(vReservation) <> Type("DocumentRef.Settlement") Then
			If Not IsBlankString(vReservation.Guest.EMail) Then
				EMailList.Add(vReservation.Guest.EMail);
			EndIf;
			If Not IsBlankString(vReservation.ContactPerson) Then
				vContactPersonEMail = cmGetContactPersonEMail(vReservation.ContactPerson);
				If Not IsBlankString(vContactPersonEMail) Then
					EMailList.Add(vContactPersonEMail);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // FillEMailList

#EndRegion
