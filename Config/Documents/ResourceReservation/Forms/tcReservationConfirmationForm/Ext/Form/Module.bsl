
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Form size
	Height = 297;
	Width = 210;
	// Process parameters
	If Parameters.Property("SelReservation") Then
		SelReservation = Parameters.SelReservation;
	EndIf;
	If Parameters.Property("SelListReservation") Then
		SelListReservation = Parameters.SelListReservation;
	EndIf;
	If Parameters.Property("SelLanguage") Then
		SelLanguage = Parameters.SelLanguage;
	EndIf;
	If Parameters.Property("SelObjectPrintForm") Then
		SelObjectPrintForm = Parameters.SelObjectPrintForm;
	EndIf;
	If Parameters.Property("SelByDays") Then
		SelByDays = Parameters.SelByDays;
	EndIf;
	If Parameters.Property("CloseOnOwnerClose") Then
		CloseOnOwnerClose = Parameters.CloseOnOwnerClose;
	EndIf;
	
	SelShowArrangement = False;
	If ValueIsFilled(SelObjectPrintForm) And Not IsBlankString(SelObjectPrintForm.Parameter) Then
		If Find(SelObjectPrintForm.Parameter, "SHOW_ARRANGEMENT") > 0 Then
			SelShowArrangement = True;
		EndIf;
	EndIf;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	// Print
	rDoPrint = Undefined;
	PrintConfirmation(rDoPrint);
	// Close form if form is to be printed directly to the printer
	If rDoPrint <> Undefined Then
		rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
		pCancel = True;
	Else
		// Fill e-mail list
		FillEMailList();
	EndIf;
EndProcedure // OnOpen

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ReservationSpreadsheetOnChangeAreaContent(pItem, pArea)
	vNotify = ReservationSpreadsheetOnChangeAreaContentAtServer(pArea.Name, pArea.Text);
	If vNotify Then
		Notify("Document.ResourceReservation.Write", SelReservation, ThisObject);
	EndIf;
EndProcedure // ReservationSpreadsheetOnChangeAreaContent

// -----------------------------------------------------------------------------
&AtClient
Procedure SelDateFromOnChange(pItem)
	If ValueIsFilled(SelDateFrom) And Not ValueIsFilled(SelDateTo) Then
		SelDateTo = SelDateFrom;
	EndIf;
EndProcedure // SelDateFromOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelDateToOnChange(pItem)
	If ValueIsFilled(SelDateTo) And Not ValueIsFilled(SelDateFrom) Then
		SelDateFrom = SelDateTo;
	EndIf;
EndProcedure // SelDateToOnChange

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure GeneratePrintForm(pCommand)
	rDoPrint = Undefined;
	PrintConfirmation(rDoPrint);
	If rDoPrint <> Undefined Then
		rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
	EndIf;
EndProcedure // GeneratePrintForm

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
		vFilePath = StrReplace(tcOnServer.cmGetMetadataMethodOrAttribiteByRef(SelReservation, "Presentation") + " " + StrReplace(TrimAll(tcOnServer.cmGetAttributeByRef(SelReservation, "Number")), "/", "-"), " ", "_");
	EndIf;
	vFileType = SpreadsheetDocumentFileType.PDF;
	tcOnClient.SaveSpreadsheetToFile(vFileType, vFilePath, ReservationSpreadsheet);
EndProcedure // SaveAsPDF

// -----------------------------------------------------------------------------
&AtClient
Procedure SendByEMail(pCommand)
	vParams = GenerateParametersReservationConfirmationByEMail();
	OpenForm("CommonForm.tcSendMail", vParams, ThisObject, UUID);
EndProcedure // SendByEMail

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure PrintConfirmation(rDoPrint = Undefined)
	// Basic checks
	If Not ValueIsFilled(SelReservation.Hotel) And ValueIsFilled(SelReservation) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("ru='У документа должна быть указана гостиница!';de='Bei dem Dokument muss das Hotel angegeben sein!';en='Hotel attribute should be filled!'"));
		Return;
	EndIf;
	If ValueIsFilled(SelDateFrom) And Not ValueIsFilled(SelDateTo) Then
		vUM = New UserMessage();
		vUM.Text = NStr("ru='При необходимости указать период печати указывайте обе даты!';de='Sowohl Start- als auch Periodenenddaten sollten ausgefüllt werden!';en='Both start and period end dates should be filled!'");
		vUM.Field = "SelDateTo";
		vUM.Message();
		Return;
	EndIf;
	If Not ValueIsFilled(SelDateFrom) And ValueIsFilled(SelDateTo) Then
		vUM = New UserMessage();
		vUM.Text = NStr("ru='При необходимости указать период печати указывайте обе даты!';de='Sowohl Start- als auch Periodenenddaten sollten ausgefüllt werden!';en='Both start and period end dates should be filled!'");
		vUM.Field = "SelDateFrom";
		vUM.Message();
		Return;
	EndIf;
	If ValueIsFilled(SelDateFrom) And ValueIsFilled(SelDateTo) And BegOfDay(SelDateFrom) > BegOfDay(SelDateTo) Then
		vUM = New UserMessage();
		vUM.Text = NStr("ru='Период печати указан неверно!';de='Druckzeitraum ist falsch!';en='Print period is incorrect!'");
		vUM.Field = "SelDateFrom";
		vUM.Message();
		Return;
	EndIf;
	SelReservations = New ValueList();
	
	// Fill spreadsheet
	If ValueIsFilled(SelListReservation) Then
		Documents.ResourceReservation.PrintConfirmationList(ReservationSpreadsheet, SelListReservation, SelReservations, SelDateFrom, SelDateTo, SelCurrency, SelByDays, SelShortView, SelShowTasks, SelHideTotals, SelDoNotJoinServices, SelLanguage, SelObjectPrintForm, rDoPrint, SelShowArrangement);
	Else
		Documents.ResourceReservation.PrintConfirmation(ReservationSpreadsheet, SelReservation, SelReservations, SelDateFrom, SelDateTo, SelCurrency, SelByDays, SelShortView, SelShowTasks, SelHideTotals, SelDoNotJoinServices, SelLanguage, SelObjectPrintForm, rDoPrint, SelShowArrangement);
	EndIf;	

	// Set form protection
	cmSetSpreadsheetProtection(Items.ReservationSpreadsheet);
EndProcedure // PrintConfirmation

// -----------------------------------------------------------------------------
&AtServer
Function ReservationSpreadsheetOnChangeAreaContentAtServer(pAreaName, pAreaText)
	vNotify = False;
	// Get reservation object value
	vSelReservationObj = SelReservation.GetObject();
	If pAreaName = "R10C3:R10C5" Then
		If Not IsBlankString(pAreaText) Then
			vSelReservationObj.ContactPerson = TrimAll(pAreaText);
			vSelReservationObj.Write(DocumentWriteMode.Write);
			vNotify = True;
		EndIf;
	ElsIf pAreaName = "R11C3:R11C5" Then
		If Not IsBlankString(pAreaText) Then
			vSelReservationObj.Fax = TrimAll(pAreaText);
			vSelReservationObj.Write(DocumentWriteMode.Write);
			vNotify = True;
		EndIf;
	ElsIf pAreaName = "R12C3:R12C5" Then
		If Not IsBlankString(pAreaText) Then
			vSelReservationObj.EMail = TrimAll(pAreaText);
			vSelReservationObj.Write(DocumentWriteMode.Write);
			vNotify = True;
		EndIf;
	EndIf;
	// Set reservation object value
	FillEMailList();
	Return vNotify;
EndFunction // ReservationSpreadsheetOnChangeAreaContentAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GenerateParametersReservationConfirmationByEMail()
	// Save current spreadsheet as PDF
	vFileName = StrReplace(SelReservation.Metadata().Presentation() + " " + Format(SelReservation.GuestGroup.Code, "ND=12; NFD=0; NG="), " ", "_");
	vFilePath = cmGetFullFileName(vFileName, TempFilesDir()) + ".pdf";
	vFileType = SpreadsheetDocumentFileType.PDF;
	ReservationSpreadsheet.Write(vFilePath, vFileType);
	// Employee signature
	vEmployeeSignature = TrimAll(cmNStr(SessionParameters.CurrentUser.Position, SelLanguage) + " " + SessionParameters.CurrentUser.GetObject().pmGetEmployeeDescription(SelLanguage));
	// Sender name
	vSenderName = ?(ValueIsFilled(SelReservation.Hotel), Catalogs.Hotels.pmGetHotelPrintName(SelReservation.Hotel, SelLanguage), "");
	// Initialize message texts
	MessageSubject = ?(ValueIsFilled(SelReservation.Hotel), Catalogs.Hotels.pmGetHotelPrintName(SelReservation.Hotel, SelLanguage), "") + 
	                 tcOnServer.cmNStrAtServer("en=' Reservation confirmation N" + Format(SelReservation.GuestGroup.Code, "ND=12; NFD=0; NG=") + "'; 
					                           |de=' Reservation confirmation N" + Format(SelReservation.GuestGroup.Code, "ND=12; NFD=0; NG=") + "'; 
	                                           |ru=' Подтверждение брони №" + Format(SelReservation.GuestGroup.Code, "ND=12; NFD=0; NG=") + "'", 
	                                           SelLanguage);
	MessageText = tcOnServer.cmNStrAtServer("en='Your reservation number is " + Format(SelReservation.GuestGroup.Code, "ND=12; NFD=0; NG=") + "'; 
				                            |de='Your reservation number is " + Format(SelReservation.GuestGroup.Code, "ND=12; NFD=0; NG=") + "'; 
	                                        |ru='Номер брони " + Format(SelReservation.GuestGroup.Code, "ND=12; NFD=0; NG=") + "'",
	                                        SelLanguage) + Chars.LF + Chars.LF +
	              tcOnServer.cmNStrAtServer("en='Best regards,'; 
				                            |de='Best regards,'; 
	                                        |ru='С уважением,'",
	                                        SelLanguage) + Chars.LF + 
	              vEmployeeSignature + Chars.LF + 
	              ?(ValueIsFilled(SelReservation.Hotel), Catalogs.Hotels.pmGetHotelPrintName(SelReservation.Hotel, SelLanguage), "") + Chars.LF + 
			      tcOnServer.cmNStrAtServer(SessionParameters.ConfigurationName, SelLanguage);
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
	Return vParams;
EndFunction // GenerateParametersReservationConfirmationByEMail

// -----------------------------------------------------------------------------
&AtServer
Procedure FillEMailList()
	EMailList.Clear();
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
	If ValueIsFilled(SelReservation.Client.EMail) Then
		EMailList.Add(SelReservation.Client.EMail);
	EndIf;
EndProcedure // FillEMailList

#EndRegion
