// -----------------------------------------------------------------------------
&AtServer
Procedure PrintConfirmation(rDoPrint = Undefined)
	// Basic checks
	If Not ValueIsFilled(SelReservation.Hotel) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("ru='У документа должна быть указана гостиница!';de='Bei dem Dokument muss das Hotel angegeben sein!';en='Hotel attribute should be filled!'"));
		Return;
	EndIf;
	SelReservations = New ValueList();

	// Fill spreadsheet
	SelReservation.GetObject().pmPrintConfirmation(ReservationSpreadsheet, SelReservation, SelReservations, RadioButtonServicesFilter, SelServiceGroup, SelShowConfirmationForCurrentReservationOnly, SelLanguage, SelObjectPrintForm);
	
	// Get and fill workstation print form settings
	If ValueIsFilled(SessionParameters.CurrentWorkstation) Then
		vWorkstationPrintSettings = SessionParameters.CurrentWorkstation.WorkstationPrintSettings;
		If ValueIsFilled(vWorkstationPrintSettings) Then
			// Try to find records for the current object print form
			vFilter = New Structure("ObjectPrintingForm, IsActive", SelObjectPrintForm, True); 
			vPrintSettingsSet = vWorkstationPrintSettings.PrintFormsList.FindRows(vFilter);
			If vPrintSettingsSet.Count() > 0 Then
				For Each vPrintSettings In vPrintSettingsSet Do
					// Fill settings
					cmSetSpreadsheetSettings(ReservationSpreadsheet, vPrintSettings);
					// Check printing direction
					If vPrintSettings.PrintDirection <> Enums.PrintDirections.Screen Then
						// Guest group code
						mGuestGroupCode = TrimAll(SelReservation.GuestGroup.Code);
						vHotelPrefix = Catalogs.Hotels.pmGetPrefix(SelReservation.Hotel);
						If Not IsBlankString(vHotelPrefix) And SelReservation.Hotel.ShowHotelPrefixBeforeGroupCode Then
							mGuestGroupCode = vHotelPrefix + mGuestGroupCode;
						EndIf;
						vName = cmGetPrintFormFileName(vPrintSettings, NStr("en='Confirmation';ru='Подтверждение';de='Bestätigung'")) + " " + mGuestGroupCode;
						cmDoSpreadsheetOutput(ReservationSpreadsheet, vPrintSettings, vName, SelLanguage, rDoPrint);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // PrintConfirmation

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	rDoPrint = Undefined;
	PrintConfirmation(rDoPrint);
	If rDoPrint <> Undefined Then
		rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
		pCancel = True;
	Else
		FillEMailList();
	EndIf;
EndProcedure // OnOpen

// -----------------------------------------------------------------------------
&AtClient
Procedure OnReopen()
	rDoPrint = Undefined;
	PrintConfirmation(rDoPrint);
	If rDoPrint <> Undefined Then
		rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
	EndIf;
	FillEMailList();
EndProcedure // OnReopen

// -----------------------------------------------------------------------------
&AtClient
Procedure Print(pCommand)
	ReservationSpreadsheet.Print();
	Close();
EndProcedure // Print

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePrinter(pCommand)
	ReservationSpreadsheet.Print(PrintDialogUseMode.Use);
	Close();
EndProcedure // ChoosePrinter

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveAsPDF(pCommand)
	vFilePath = "";
	If ValueIsFilled(SelReservation) Then
		If IsWaitingList Then
			vFilePath = StrReplace(NStr("en='Request';ru='Заявка';de='Antrag'") + " " + Format(tcOnServer.cmGetAttributeByRef(SelReservation, "GuestGroup.Code"), "ND=12; NFD=0; NG="), " ", "_");
		Else
			vFilePath = StrReplace(tcOnServer.cmGetMetadataMethodOrAttribiteByRef(SelReservation, "Presentation") + " " + StrReplace(TrimAll(tcOnServer.cmGetAttributeByRef(SelReservation, "Number")), "/", "-"), " ", "_");
		EndIf;
	EndIf;
	vFileType = SpreadsheetDocumentFileType.PDF;
	tcOnClient.SaveSpreadsheetToFile(vFileType, vFilePath, ReservationSpreadsheet);
EndProcedure // SaveAsPDF

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("SelReservation") Then
		SelReservation = Parameters.SelReservation;	
	EndIf;
	If Parameters.Property("SelReservationObj") Then
		If Parameters.SelReservationObj <> Undefined Then
			CopyFormData(Parameters.SelReservationObj, SelReservationObj);
		EndIf;
	EndIf;
	If Parameters.Property("SelLanguage") Then
		SelLanguage = Parameters.SelLanguage;	
	EndIf;
	If Parameters.Property("SelObjectPrintForm") Then
		SelObjectPrintForm = Parameters.SelObjectPrintForm;	
	EndIf;
	If Parameters.Property("SelShowConfirmationForCurrentReservationOnly") Then
		SelShowConfirmationForCurrentReservationOnly = Parameters.SelShowConfirmationForCurrentReservationOnly;	
	EndIf;
	If Parameters.Property("CloseOnOwnerClose") And TypeOf(Parameters.CloseOnOwnerClose) = Type("Boolean") Then
		ThisObject.CloseOnOwnerClose = Parameters.CloseOnOwnerClose;	
	EndIf;
	Height = 297;
	Width = 210;
	RadioButtonServicesFilter = 0;
	cmSetSpreadsheetProtection(Items.ReservationSpreadsheet);
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ReservationSpreadsheetOnChangeAreaContent(pItem, pArea)
	ReservationSpreadsheetOnChangeAreaContentAtServer(pArea.Name, pArea.Text);
	Try
		If FormOwner <> Undefined And FormOwner.Object <> Undefined And 
		   FormOwner.Object.Property("Date") And ValueIsFilled(FormOwner.Object.Date) Then
			CopyFormData(SelReservationObj, FormOwner.Object);
			FormOwner.Read();
		EndIf;
	Except
	EndTry;
EndProcedure // ReservationSpreadsheetOnChangeAreaContent

// -----------------------------------------------------------------------------
&AtServer
Procedure ReservationSpreadsheetOnChangeAreaContentAtServer(pAreaName, pAreaText)
	// Get reservation object value
	If Not ValueIsFilled(SelReservationObj.Date) And ValueIsFilled(SelReservation) Then
		vSelReservationObj = SelReservation.GetObject();
	Else
		vSelReservationObj = FormAttributeToValue("SelReservationObj");
	EndIf;
	vResObjWasModified = False;
	If pAreaName = "R9C5" Then
		If Not IsBlankString(pAreaText) Then
			vSelReservationObj.ContactPerson = TrimAll(pAreaText);
			vSelReservationObj.Write(DocumentWriteMode.Write);
			vSelReservationObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			// Referesh document reference
			SelReservation = vSelReservationObj.Ref;
			vResObjWasModified = True;
		EndIf;
	ElsIf pAreaName = "R10C5" Then
		If Not IsBlankString(pAreaText) Then
			vSelReservationObj.Phone = SMS.GetValidPhoneNumber(TrimAll(pAreaText));
			vSelReservationObj.Write(DocumentWriteMode.Write);
			vSelReservationObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			// Referesh document reference
			SelReservation = vSelReservationObj.Ref;
			vResObjWasModified = True;
		EndIf;
	ElsIf pAreaName = "R11C5" Then
		If Not IsBlankString(pAreaText) Then
			vSelReservationObj.EMail = TrimAll(pAreaText);
			vSelReservationObj.Write(DocumentWriteMode.Write);
			vSelReservationObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			// Referesh document reference
			SelReservation = vSelReservationObj.Ref;
			vResObjWasModified = True;
		EndIf;
	EndIf;
	// Set reservation object value
	If vResObjWasModified Then
		ValueToFormAttribute(vSelReservationObj, "SelReservationObj");
		FillEMailList();
	EndIf;
EndProcedure // ReservationSpreadsheetOnChangeAreaContentAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure RadioButtonServicesFilterOnChange(pItem)
	rDoPrint = Undefined;
	PrintConfirmation(rDoPrint);
	If rDoPrint <> Undefined Then
		rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
	EndIf;
EndProcedure // RadioButtonServicesFilterOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelServiceGroupOnChange(pItem)
	rDoPrint = Undefined;
	PrintConfirmation(rDoPrint);
	If rDoPrint <> Undefined Then
		rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
	EndIf;
EndProcedure // SelServiceGroupOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SendByEMail(pCommand)
	If IsWaitingList Then
		vParams = GenerateParametersRequestByEMail();
		OpenForm("CommonForm.tcSendMail", vParams, ThisObject, UUID);
	Else
		vParams = GenerateParametersConfirmationByEMail();
		OpenForm("CommonForm.tcSendMail", vParams, ThisObject, UUID);
	EndIf;
EndProcedure // SendByEMail

// -----------------------------------------------------------------------------
&AtServer
Function GenerateParametersRequestByEMail()
	// Save current spreadsheet as PDF
	vFileName = StrReplace(NStr("en='Request';ru='Заявка';de='Antrag'") + " " + Format(SelReservation.GuestGroup.Code, "ND=12; NFD=0; NG="), " ", "_");
	vFilePath = cmGetFullFileName(vFileName, TempFilesDir()) + ".pdf";
	vFileType = SpreadsheetDocumentFileType.PDF;
	ReservationSpreadsheet.Write(vFilePath, vFileType);
	// Employee signature
	vEmployeeSignature = TrimAll(cmNStr(SessionParameters.CurrentUser.Position, SelLanguage) + " " + SessionParameters.CurrentUser.GetObject().pmGetEmployeeDescription(SelLanguage));
	// Sender name
	vSenderName = ?(ValueIsFilled(SelReservation.Hotel), Catalogs.Hotels.pmGetHotelPrintName(SelReservation.Hotel, SelLanguage), "");
	// Initialize message texts
	MessageSubject = ?(ValueIsFilled(SelReservation.Hotel), Catalogs.Hotels.pmGetHotelPrintName(SelReservation.Hotel, SelLanguage), "") + 
					tcOnServer.cmNStrAtServer("en=' Reservation request N" + Format(SelReservation.GuestGroup.Code, "ND=12; NFD=0; NG=") + "'; 
					|de=' Reservation request N" + Format(SelReservation.GuestGroup.Code, "ND=12; NFD=0; NG=") + "'; 
					|ru=' Заявка №" + Format(SelReservation.GuestGroup.Code, "ND=12; NFD=0; NG=") + "'", 
					SelLanguage);
	MessageText = "";	
	vIsHTML = False; 
	vTemplate = Undefined;
	If ValueIsFilled(SelReservation.Hotel) And ValueIsFilled(SelReservation.Hotel.TemplateSendReservationRequestByEMail) Then
		vTemplate = SelReservation.Hotel.TemplateSendReservationRequestByEMail;
		If ValueIsFilled(vTemplate) Then
			If ValueIsFilled(vTemplate.HTMLTextRu) Or ValueIsFilled(vTemplate.HTMLTextEn) Or ValueIsFilled(vTemplate.HTMLTextDe) Then
				MessageText = SMS.GetHTMLTextByLanguage(vTemplate, SelLanguage);
				If Not IsBlankString(MessageText) Then
					vIsHTML = True;
				EndIf;
			EndIf;
			If IsBlankString(MessageText) Then
				MessageText = SMS.GetSMSTextByLanguage(vTemplate, SelLanguage);
			EndIf; 
		EndIf;
	EndIf;
	If Not IsBlankString(MessageText) Then
		MessageText = SMS.ReplaceSMSParameters(MessageText, SelReservation);
	EndIf;	
	If IsBlankString(MessageText) Then
		MessageText = tcOnServer.cmNStrAtServer("en='Your reservation request number is " + Format(SelReservation.GuestGroup.Code, "ND=12; NFD=0; NG=") + "'; 
		|de='Your reservation request number is " + Format(SelReservation.GuestGroup.Code, "ND=12; NFD=0; NG=") + "'; 
		|ru='Номер вашей заявки " + Format(SelReservation.GuestGroup.Code, "ND=12; NFD=0; NG=") + "'",
		SelLanguage) + Chars.LF + Chars.LF +
		tcOnServer.cmNStrAtServer("en='This is NOT reservation confirmation!'; 
		|de='This is NOT reservation confirmation!'; 
		|ru='Это НЕ подтверждение брони!'",
		SelLanguage) + Chars.LF + Chars.LF + 
		tcOnServer.cmNStrAtServer("en='Best regards,'; 
		|de='Best regards,'; 
		|ru='С уважением,'",
		SelLanguage) + Chars.LF +
		vEmployeeSignature + Chars.LF + 
		?(ValueIsFilled(SelReservation.Hotel), Catalogs.Hotels.pmGetHotelPrintName(SelReservation.Hotel, SelLanguage), "") + Chars.LF 
		 	+ tcOnServer.cmNStrAtServer(SessionParameters.ConfigurationName, SelLanguage);
	EndIf;				  
	// Call user exit procedure to give possibility to override message subject and message text
	vUserExitProc = Catalogs.ExternalDataProcessors.SendReservationRequestByEMail;
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
	vParams.Insert("SelEMails", "");
	vParams.Insert("SelToList", EMailList);
	vFile = New Structure();
	vFile.Insert("FileName", cmGetValidFileName(MessageSubject) + ".pdf");
	vFile.Insert("FullFileNameAtClient", "");
	vFile.Insert("FullFileNameAtServer", vFilePath);
	vFile.Insert("CheckRemoveAtClient",  False);
	vFile.Insert("CheckRemoveAtServer", True);
	vParams.Insert("SelFile", vFile);
	vParams.Insert("SelLanguage", SelLanguage);
	vParams.Insert("SelGuestGroup", SelReservation.GuestGroup);
	vParams.Insert("SelSenderName", vSenderName);
	vParams.Insert("SelHotel", SelReservation.Hotel);
	vParams.Insert("SelDocument", SelReservation);
	vParams.Insert("IsHTML", vIsHTML);
	vParams.Insert("SelSMSTemplates", vTemplate);
	Return vParams;
EndFunction // GenerateParametersRequestByEMail

// -----------------------------------------------------------------------------
&AtServer
Function GenerateParametersConfirmationByEMail()
	// Save current spreadsheet as PDF
	vFileName = StrReplace(SelReservation.Metadata().Presentation() + " " + Format(SelReservation.GuestGroup.Code, "ND=12; NFD=0; NG="), " ", "_");
	vFilePath = cmGetFullFileName(vFileName, TempFilesDir()) + ".pdf";
	vFileType = SpreadsheetDocumentFileType.PDF;
	ReservationSpreadsheet.Write(vFilePath, vFileType);
	vIsHTML = False;
	MessageText = "";
	vTemplate = Undefined;
	If ValueIsFilled(SelReservation.Hotel) And ValueIsFilled(SelReservation.Hotel.TemplateSendReservationConfirmationByEMail) Then
		vTemplate = SelReservation.Hotel.TemplateSendReservationConfirmationByEMail; 
		If ValueIsFilled(vTemplate) Then
			If ValueIsFilled(vTemplate.HTMLTextRu) Or ValueIsFilled(vTemplate.HTMLTextEn) Or ValueIsFilled(vTemplate.HTMLTextDe) Then
				MessageText = SMS.GetHTMLTextByLanguage(vTemplate, SelLanguage);
				If Not IsBlankString(MessageText) Then
					vIsHTML = True;
				EndIf;
			EndIf;
			If IsBlankString(MessageText) Then
				MessageText = SMS.GetSMSTextByLanguage(vTemplate, SelLanguage);
			EndIf;  
		EndIf;	
	EndIf;	
	If Not IsBlankString(MessageText) Then
		MessageText = SMS.ReplaceSMSParameters(MessageText, SelReservation);
	EndIf;	
	vParams = New Structure("Reservation, User, Language", SelReservation, SessionParameters.CurrentUser, SelLanguage);
	vMessage = EMail.GetReservationConfirmationSubjectAndText(vParams);
	If IsBlankString(MessageText) Then
		MessageText = vMessage.MessageText;
	EndIf;
	
	MessageSubject = vMessage.MessageSubject;
	SenderName = vMessage.SenderName;
	If Not ValueIsFilled(vTemplate) Then
		vTemplate = vMessage.SMSTemplates; 
	EndIf;
			  
	// Call user exit procedure to give possibility to override message subject ans message text
	vUserExitProc = Catalogs.ExternalDataProcessors.SendReservationConfirmationByEMail;
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
	vParams.Insert("SelGuestGroup", SelReservation.GuestGroup);
	vParams.Insert("SelSenderName", SenderName);
	vParams.Insert("SelHotel", SelReservation.Hotel);
	vParams.Insert("SelDocument", SelReservation);
	vParams.Insert("IsHTML", vIsHTML); 
	vParams.Insert("SelSMSTemplates", vTemplate);
	Return vParams;
EndFunction // GenerateParametersConfirmationByEMail

// -----------------------------------------------------------------------------
&AtServer
Procedure FillEMailList()
	EMailList.Clear();
	If ValueIsFilled(SelReservationObj.EMail) Then
		EMailList.Add(SelReservationObj.EMail);
	EndIf;
	If ValueIsFilled(SelReservationObj.Customer.EMail) Then
		EMailList.Add(SelReservationObj.Customer.EMail);
	EndIf;
	If Not IsBlankString(SelReservationObj.ContactPerson) Then
		vContactPersonEMail = cmGetContactPersonEMail(SelReservationObj.ContactPerson);
		If Not IsBlankString(vContactPersonEMail) Then
			EMailList.Add(vContactPersonEMail);
		EndIf;
	EndIf;
	If ValueIsFilled(SelReservationObj.Guest.EMail) Then
		EMailList.Add(SelReservationObj.Guest.EMail);
	EndIf;
	If ValueIsFilled(SelReservation.EMail) Then
		EMailList.Add(SelReservation.EMail);
	EndIf;
	If ValueIsFilled(SelReservation.Customer.EMail) Then
		EMailList.Add(SelReservation.Customer.EMail);
	EndIf;
	If Not IsBlankString(SelReservation.ContactPerson) Then
		vContactPersonEMail = cmGetContactPersonEMail(SelReservation.ContactPerson);
		If Not IsBlankString(vContactPersonEMail) Then
			EMailList.Add(vContactPersonEMail);
		EndIf;
	EndIf;
	If ValueIsFilled(SelReservation.Guest.EMail) Then
		EMailList.Add(SelReservation.Guest.EMail);
	EndIf;
EndProcedure // FillEMailList

// -----------------------------------------------------------------------------
&AtClient
Procedure ReservationSpreadsheetDetailProcessing(Item, Details, StandardProcessing, AdditionalParameters)
	If StrStartsWith(Details,"http") Then
		StandardProcessing = False;
		GotoURL(Details);
	EndIf;
EndProcedure
