
#Region FormEventHandlers

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
	If Parameters.Property("GroupBy") Then
		SelGroupBy = Parameters.GroupBy;
	EndIf;
	ThisForm.Height = 297;
	ThisForm.Width = 210;
	cmSetSpreadsheetProtection(Items.InvoiceSpreadsheet);
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	// Draw invoice form
	PrintInvoice();
	
	// Get and fill workstation print form settings
	vShowThisForm = False;
	vInvoiceNumber = tcOnServer.cmGetAttributeByRef(SelInvoice, "Number");
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
					tcOnServer.SetSpreadsheetSettings(InvoiceSpreadsheet, vPrintSettings);
					// Check printing direction
					If vPrintSettings.PrintDirection <> PredefinedValue("Enum.PrintDirections.Screen") Then
						vName = tcOnClient.GetPrintFormFileNameAtClient(vPrintSettings, NStr("de='Pro-Forma Rechnung';en='Invoice';ru='Счет на оплату'")) + " " + vInvoiceNumber;
						If vPrintSettings.PrintDirection = PredefinedValue("Enum.PrintDirections.Printer") Then
							If IsBlankString(InvoiceSpreadsheet.PrinterName) Then
								InvoiceSpreadsheet.Print(False);
							Else
								InvoiceSpreadsheet.Print(True);
							EndIf;
						EndIf;
					Else
						If Not IsBlankString(InvoiceSpreadsheet.PrinterName) Then
							InvoiceSpreadsheet.Print(True);
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

// -----------------------------------------------------------------------------
&AtClient
Procedure OnReopen()
	// Draw invoice form
	PrintInvoice();
EndProcedure // OnReopen

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Print(pCommand)
	InvoiceSpreadsheet.Print(PrintDialogUseMode.DontUse);
	ThisForm.Close();
EndProcedure // Print

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePrinter(pCommand)
	InvoiceSpreadsheet.Print(PrintDialogUseMode.Use);
	ThisForm.Close();
EndProcedure // ChoosePrinter

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveAsPDF(pCommand)
	vFilePath = "";
	If ValueIsFilled(SelInvoice) Then
		vFilePath = StrReplace(tcOnServer.cmGetMetadataMethodOrAttribiteByRef(SelInvoice, "Presentation") + " " + StrReplace(TrimAll(tcOnServer.cmGetAttributeByRef(SelInvoice, "Number")), "/", "-"), " ", "_");
	EndIf;	
	vFileType = SpreadsheetDocumentFileType.PDF;
	tcOnClient.SaveSpreadsheetToFile(vFileType, vFilePath, InvoiceSpreadsheet);
EndProcedure // SaveAsPDF

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintAsWord(pCommand)
	vFilePath = "";
	If ValueIsFilled(SelInvoice) Then
		vFilePath = StrReplace(tcOnServer.cmGetMetadataMethodOrAttribiteByRef(SelInvoice, "Presentation") + " " + StrReplace(TrimAll(tcOnServer.cmGetAttributeByRef(SelInvoice, "Number")), "/", "-"), " ", "_");
	EndIf;
	vFileType = SpreadsheetDocumentFileType.DOCX;
	tcOnClient.SaveSpreadsheetToFile(vFileType, vFilePath, InvoiceSpreadsheet);
EndProcedure // PrintAsWord

// -----------------------------------------------------------------------------
&AtClient
Procedure SendByEMail(pCommand)
	vParams = GenerateParametersInvoiceByEMail();
	OpenForm("CommonForm.tcSendMail", vParams, ThisForm, ThisForm.UUID);	
EndProcedure // SendByEMail

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure PrintInvoice()
	// Call invoice object procedure
	If Not ValueIsFilled(SelInvoice) And Invoices.Count() = 0 Then
		Return;
	EndIf;
	FillEMailList();
	vInvoiceNumber = "";
	vClear = True;
	For Each vInvoiceItem In Invoices Do
		If Invoices.IndexOf(vInvoiceItem) > 0 Then
			InvoiceSpreadsheet.PutHorizontalPageBreak();
		EndIf;
		vInvoiceObj = vInvoiceItem.Value.GetObject();
		vInvoiceObj.pmPrintInvoiceShort(InvoiceSpreadsheet, SelLanguage, SelGroupBy, SelObjectPrintForm, vInvoiceNumber, vClear);
		vClear = False;
	EndDo;
EndProcedure // PrintInvoice

// -----------------------------------------------------------------------------
&AtServer
Function GenerateParametersInvoiceByEMail(pMessageText = "")
	// Save current spreadsheet as HTML
	vFileName = StrReplace(SelInvoice.Metadata().Presentation() + " " + StrReplace(TrimAll(SelInvoice.Number), "/", "-"), " ", "_");
	vFilePath = cmGetFullFileName(vFileName, TempFilesDir()) + ".pdf";
	vFileType = SpreadsheetDocumentFileType.PDF;
	InvoiceSpreadsheet.Write(vFilePath, vFileType);
	// Employee signature
	vEmployeeSignature = TrimAll(cmNStr(SessionParameters.CurrentUser.Position, SelLanguage) + " " + SessionParameters.CurrentUser.GetObject().pmGetEmployeeDescription(SelLanguage));
	// Sender name
	vSenderName = ?(ValueIsFilled(SelInvoice.Hotel), Catalogs.Hotels.pmGetHotelPrintName(SelInvoice.Hotel, SelLanguage), "");
	// Initialize message texts
	vMessageSubject = ?(ValueIsFilled(SelInvoice.Hotel), Catalogs.Hotels.pmGetHotelPrintName(SelInvoice.Hotel, SelLanguage), "") + 
	                  cmNStr("en=' Invoice N" + TrimAll(SelInvoice.Number) + "'; 
					         |de=' Invoice N" + TrimAll(SelInvoice.Number) + "'; 
	                         |ru=' Счет №" + TrimAll(SelInvoice.Number) + "'", 
	                         SelLanguage);
	vIsHTML = False; 
	vTemplate = Undefined;
	vMessageText = "";
	If ValueIsFilled(SelInvoice.Hotel) Then
		vTemplate = SelInvoice.Hotel.TemplateSendInvoiceByEMail;
		If ValueIsFilled(vTemplate) Then
			vMessageSubject = cmNStr(TrimAll(vTemplate.Description), SelLanguage);
			vMessageSubject = SMS.ReplaceSMSParameters(vMessageSubject, SelInvoice.Ref);
			If ValueIsFilled(vTemplate.HTMLTextRu) Or ValueIsFilled(vTemplate.HTMLTextEn) Or ValueIsFilled(vTemplate.HTMLTextDe) Then
				vMessageText = SMS.GetHTMLTextByLanguage(vTemplate, SelLanguage);
				If Not IsBlankString(vMessageText) Then
					vIsHTML = True;
				EndIf;
			EndIf;
			If IsBlankString(vMessageText) Then
				vMessageText = SMS.GetSMSTextByLanguage(vTemplate, SelLanguage);
			EndIf;
		EndIf;
	EndIf;
	If Not IsBlankString(vMessageText) Then
		vMessageText = SMS.ReplaceSMSParameters(vMessageText, SelInvoice.Ref);
	EndIf;	
	If IsBlankString(vMessageText) Then								 
		vMessageText = ?(IsBlankString(pMessageText), "", cmNStr(TrimAll(pMessageText), SelLanguage) + Chars.LF + Chars.LF) + 
		              cmNStr("en='Invoice number is " + TrimAll(SelInvoice.Number) + "'; 
					         |de='Invoice number is " + TrimAll(SelInvoice.Number) + "'; 
					         |ru='Номер счета " + TrimAll(SelInvoice.Number) + "'",
		                     SelLanguage) + Chars.LF +
		              ?(ValueIsFilled(SelInvoice.GuestGroup), 
		              cmNStr("en='Confirmation number " + Format(SelInvoice.GuestGroup.Code, "ND=12; NFD=0; NG=") + "'; 
					         |de='Confirmation number " + Format(SelInvoice.GuestGroup.Code, "ND=12; NFD=0; NG=") + "'; 
		                     |ru='Номер подтверждения " + Format(SelInvoice.GuestGroup.Code, "ND=12; NFD=0; NG=") + "'",
		                     SelLanguage) + Chars.LF + Chars.LF, 
		              Chars.LF) + 
		              cmNStr("en='Best regards,'; 
					         |de='Best regards,'; 
		                     |ru='С уважением,'",
		                     SelLanguage) + Chars.LF + 
		              vEmployeeSignature + Chars.LF + 
		              ?(ValueIsFilled(SelInvoice.Hotel), Catalogs.Hotels.pmGetHotelPrintName(SelInvoice.Hotel, SelLanguage), "") + Chars.LF + 
				      cmNStr(SessionParameters.ConfigurationName, SelLanguage);
	EndIf;
	// Call user exit procedure to give possibility to override message subject ans message text
	vUserExitProc = Catalogs.ExternalDataProcessors.SendInvoiceByEMail;
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
	vParams.Insert("SelMessageSubject", vMessageSubject);
	vParams.Insert("SelMessageText", vMessageText);
	vParams.Insert("SelEMails", "");
	vParams.Insert("SelToList", EMailList);
	vFile = New Structure();
	vFile.Insert("FileName", cmGetValidFileName(vMessageSubject)+".pdf");
	vFile.Insert("FullFileNameAtClient", "");
	vFile.Insert("FullFileNameAtServer", vFilePath);
	vFile.Insert("CheckRemoveAtClient",  False);
	vFile.Insert("CheckRemoveAtServer", True);
	vParams.Insert("SelFile", vFile);
	vParams.Insert("SelLanguage", SelLanguage);
	vParams.Insert("SelGuestGroup", SelInvoice.GuestGroup);
	vParams.Insert("SelSenderName", vSenderName);
	vParams.Insert("SelHotel", SelInvoice.Hotel);
	vParams.Insert("SelDocument", SelInvoice);
	vParams.Insert("IsHTML", vIsHTML);
	vParams.Insert("SelSMSTemplates", vTemplate);
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

// -----------------------------------------------------------------------------
&AtClient
Procedure InvoiceSpreadsheetOnChangeAreaContent(pItem, pArea)
	InvoiceSpreadsheetOnChangeAreaContentAtServer(pArea.Name, pArea.Text);
	If FormOwner <> Undefined Then
		FormOwner.Read();
	EndIf;
EndProcedure // InvoiceSpreadsheetOnChangeAreaContent

// -----------------------------------------------------------------------------
&AtServer
Procedure InvoiceSpreadsheetOnChangeAreaContentAtServer(pAreaName, pAreaText)
	// Get invoice object value
	vSelInvoiceObj = SelInvoice.GetObject();
	If pAreaName = "EMail" Or pAreaName = "EMailRu" Then
		If Not IsBlankString(pAreaText) Then
			vSelInvoiceObj.EMail = TrimAll(pAreaText);
			vSelInvoiceObj.Write(DocumentWriteMode.Write);
			// Referesh document reference
			SelInvoice = vSelInvoiceObj.Ref;
		EndIf;
	EndIf;
	FillEMailList();
EndProcedure // InvoiceSpreadsheetOnChangeAreaContentAtServer

#EndRegion
