
#Region FormEventHandlers

// ---------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("InputParameter") And ValueIsFilled(Parameters.InputParameter) Then
		If TypeOf(Parameters.InputParameter) = Type("CatalogRef.GuestGroups") Then
			SelReservation = Undefined;
			SelGuestGroup = Parameters.InputParameter;
			SelHotel = SelGuestGroup.Owner;
		Else
			SelReservation = Parameters.InputParameter;	
			SelGuestGroup = SelReservation.GuestGroup;
			SelHotel = SelReservation.Hotel;
		EndIf;
	EndIf;	
	If Parameters.Property("ObjectPrintingForm") Then
		SelObjectPrintForm = Parameters.ObjectPrintingForm;
		SelLanguage = SelObjectPrintForm.Language;
		SelShowDetails = False;
		If Find(SelObjectPrintForm.Parameter, "SHOW_DAILY_PRICES") > 0 Then
			SelShowDetails = True;
		EndIf; 
		SelShowGuests = True;
		If Find(SelObjectPrintForm.Parameter, "DONT_SHOW_GUESTS_LIST") > 0 Then
			SelShowGuests = False;
		EndIf; 
		SelShowPaymentLink = False;
		If Find(SelObjectPrintForm.Parameter, "SHOW_PAYMENT_LINK") > 0 Then
			SelShowPaymentLink = True;
		EndIf;
	EndIf;
	If Parameters.Property("OneGuestMode") And Parameters.OneGuestMode Then
		SelShowGuests = False;
	EndIf;
	RadioButtonServicesFilter = 0;
	cmSetSpreadsheetProtection(Items.ReservationSpreadsheet);
EndProcedure // OnCreateAtServer

// ---------------------------------------------------------------------------------
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

// ---------------------------------------------------------------------------------
&AtClient
Procedure OnReopen()
	rDoPrint = Undefined;
	PrintConfirmation(rDoPrint);
	If rDoPrint <> Undefined Then
		rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
	EndIf;
	FillEMailList();
EndProcedure // OnReopen

#EndRegion

#Region FormHeaderItemsEventHandlers

// ---------------------------------------------------------------------------------
&AtClient
Procedure SelReservationStartChoice(pItem, pChoiceData, pChoiceByAdding, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure // SelReservationStartChoice

// ---------------------------------------------------------------------------------
&AtClient
Procedure SelGuestGroupClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure // SelGuestGroupClearing

// ---------------------------------------------------------------------------------
&AtClient
Procedure SelGuestGroupOnChange(pItem)
	SelReservation = Undefined;
	GenerateReport();
EndProcedure // SelGuestGroupOnChange

// ---------------------------------------------------------------------------------
&AtClient
Procedure SelReservationOnChange(pItem)
	GenerateReport();
EndProcedure // SelReservationOnChange

// ---------------------------------------------------------------------------------
&AtClient
Procedure SelIsShowDetailsOnChange(pItem)
	GenerateReport();
EndProcedure // SelIsShowDetailsOnChange

// ---------------------------------------------------------------------------------
&AtClient
Procedure SelIsShowGuestOnChange(pItem)
	GenerateReport();
EndProcedure // SelIsShowGuestOnChange

// ---------------------------------------------------------------------------------
&AtClient
Procedure SelShowPaymentLinkOnChange(pItem)
	GenerateReport();
EndProcedure // SelShowPaymentLinkOnChange

&AtClient
Procedure HideRoomRateAndSumOnChange(pItem)
	GenerateReport();
EndProcedure // HideRoomRateAndSumOnChange

// ---------------------------------------------------------------------------------
&AtClient
Procedure RadioButtonServicesFilterOnChange(pItem)
	rDoPrint = Undefined;
	PrintConfirmation(rDoPrint);
	If rDoPrint <> Undefined Then
		rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
	EndIf;
EndProcedure // RadioButtonServicesFilterOnChange

// ---------------------------------------------------------------------------------
&AtClient
Procedure SelServiceGroupOnChange(pItem)
	rDoPrint = Undefined;
	PrintConfirmation(rDoPrint);
	If rDoPrint <> Undefined Then
		rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
	EndIf;
EndProcedure // SelServiceGroupOnChange

// ---------------------------------------------------------------------------------
&AtClient
Procedure ReservationSpreadsheetDetailProcessing(pItem, pDetails, pStandardProcessing, pAdditionalParameters)
	If StrStartsWith(pDetails, "http") Then
		pStandardProcessing = False;
		GotoURL(pDetails);
	EndIf;
EndProcedure // ReservationSpreadsheetDetailProcessing

#EndRegion

#Region FormCommandsEventHandlers

// ---------------------------------------------------------------------------------
&AtClient
Procedure Print(pCommand)
	ReservationSpreadsheet.Print();
	Close();
EndProcedure // Print

// ---------------------------------------------------------------------------------
&AtClient
Procedure ChoosePrinter(pCommand)
	ReservationSpreadsheet.Print(PrintDialogUseMode.Use);
	Close();
EndProcedure // ChoosePrinter

// ---------------------------------------------------------------------------------
&AtClient
Procedure SaveAsPDF(pCommand)
	vFilePath = "";
	If ValueIsFilled(SelReservation) Then
		If IsWaitingList Then
			vFilePath = StrReplace(NStr("en = 'Request'; de = 'Antrag'; ru = 'Заявка'") + " " + Format(tcOnServer.cmGetAttributeByRef(SelReservation, "GuestGroup.Code"), "ND=12; NFD=0; NG="), " ", "_");
		Else
			vFilePath = StrReplace(tcOnServer.cmGetMetadataMethodOrAttribiteByRef(SelReservation, "Presentation") + " " + StrReplace(TrimAll(tcOnServer.cmGetAttributeByRef(SelReservation, "Number")), "/", "-"), " ", "_");
		EndIf;
	EndIf;
	vFileType = SpreadsheetDocumentFileType.PDF;
	tcOnClient.SaveSpreadsheetToFile(vFileType, vFilePath, ReservationSpreadsheet);
EndProcedure // SaveAsPDF

// ---------------------------------------------------------------------------------
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

// ---------------------------------------------------------------------------------
&AtClient
Procedure Generate(pCommand)
	GenerateReport();
EndProcedure

#EndRegion

#Region Private

// ---------------------------------------------------------------------------------
&AtServer
Procedure PrintConfirmation(rDoPrint = Undefined)
	// Basic checks
	If Not ValueIsFilled(SelGuestGroup) Then
		tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Guest group is not selected!'; de = 'Keine Gästegruppe ausgewählt!'; ru = 'Не выбрана группа гостей!'"));
		Return;
	EndIf;
	If Not ValueIsFilled(SelHotel) Then
		tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'The hotel has not been identified!'; de = 'Kein Hotel definiert!'; ru = 'Гостиница не определена!'"));
		Return;
	EndIf;

	vReservationsArray = New Array();
	vReservation = SelReservation;
	If ValueIsFilled(SelReservation) Then
		vReservations = cmGetOneRoomReservations(SelReservation.Number, SelReservation.GuestGroup, SelReservation.CheckInDate, SelReservation.CheckOutDate, False, True);
		For Each vReservationsRow In vReservations Do
			vReservationsArray.Add(vReservationsRow.Reservation);
		EndDo;
	Else
		If ValueIsFilled(SelGuestGroup.ClientDoc) And TypeOf(SelGuestGroup.ClientDoc) = Type("DocumentRef.Reservation") Then
			vReservation = SelGuestGroup.ClientDoc;
		EndIf;
		vGroupDocs = cmGetGuestGroupDocuments(SelGuestGroup);
		For Each vGroupDocsRow In vGroupDocs Do
			If TypeOf(vGroupDocsRow.Reservation) = Type("DocumentRef.Reservation") Then
				vReservationsArray.Add(vGroupDocsRow.Reservation);
			EndIf;
		EndDo;
		If Not ValueIsFilled(vReservation) And vReservationsArray.Count() > 0 Then
			vReservation = vReservationsArray.Get(0);
		EndIf;
	EndIf;

	// Fill spreadsheet
	vProcessorObj = FormAttributeToValue("DataProcessorObject");
	vProcessorObj.pmPrintConfirmation(ReservationSpreadsheet, vReservation, vReservationsArray, RadioButtonServicesFilter, SelServiceGroup, ?(vReservationsArray.Count() = 0, True, False), SelLanguage, SelObjectPrintForm,  SelShowGuests, SelShowDetails, SelShowPaymentLink, SelHideRoomRateAndSum);
	
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
						vName = cmGetPrintFormFileName(vPrintSettings, NStr("en = 'Confirmation'; de = 'Bestätigung'; ru = 'Подтверждение'")) + " " + mGuestGroupCode;
						cmDoSpreadsheetOutput(ReservationSpreadsheet, vPrintSettings, vName, SelLanguage, rDoPrint);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // PrintConfirmation

// ---------------------------------------------------------------------------------
&AtServer
Function GenerateParametersRequestByEMail()
	vUser = SessionParameters.CurrentUser;  
	vHotel = SelReservation.Hotel; 
	vGuestGroup = SelReservation.GuestGroup;
	vGuestGroupCode = Format(SelReservation.GuestGroup.Code, "ND=12; NFD=0; NG=");
	
	// Save current spreadsheet as PDF
	vFileName = StrReplace(NStr("en = 'Request'; de = 'Antrag'; ru = 'Заявка'") + " " + vGuestGroupCode, " ", "_");
	vFilePath = cmGetFullFileName(vFileName, TempFilesDir()) + ".pdf";
	vFileType = SpreadsheetDocumentFileType.PDF;
	ReservationSpreadsheet.Write(vFilePath, vFileType);
	
	// Employee signature
	vEmployeeSignature = TrimAll(cmNStr(vUser.Position, SelLanguage) + " " + Catalogs.Employees.pmGetEmployeeDescription(vUser, SelLanguage));
	// Sender name
	vSenderName = ?(ValueIsFilled(vHotel), Catalogs.Hotels.pmGetHotelPrintName(vHotel, SelLanguage), "");
	// Initialize message texts
	MessageSubject = vSenderName  
	                 + tcOnServer.cmNStrAtServer("en=' Reservation request N" + vGuestGroupCode + "'; 
					                           |de=' Reservation request N" + vGuestGroupCode + "'; 
	                                           |ru=' Заявка №" + vGuestGroupCode + "'", 
	                                           SelLanguage);
	MessageText = tcOnServer.cmNStrAtServer("en='Automatic request for reservation status delivery:'; 
	                                        |de='Automatic request for reservation status delivery:'; 
	                                        |ru='Автоматизированная система рассылки статусов заявок:'",
	                                        SelLanguage) + Chars.LF + Chars.LF +
	              tcOnServer.cmNStrAtServer("en='Your reservation request number is " + vGuestGroupCode + "'; 
				                            |de='Your reservation request number is " + vGuestGroupCode + "'; 
	                                        |ru='Номер вашей заявки " + vGuestGroupCode + "'",
	                     SelLanguage) + Chars.LF + Chars.LF +
	              tcOnServer.cmNStrAtServer("en='This is NOT reservation confirmation!'; 
				                            |de='This is NOT reservation confirmation!'; 
	                                        |ru='Это НЕ подтверждение брони!'",
	                     SelLanguage) + Chars.LF + Chars.LF + 
	              tcOnServer.cmNStrAtServer("en='Best regards,'; 
				                            |de='Best regards,'; 
	                                        |ru='С уважением,'",
	                     SelLanguage) + Chars.LF 
				  + vEmployeeSignature + Chars.LF 
				  + vSenderName + Chars.LF 
				  + tcOnServer.cmNStrAtServer(SessionParameters.ConfigurationName, SelLanguage);
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
	Return vParams;
EndFunction // GenerateParametersRequestByEMail

// ---------------------------------------------------------------------------------
&AtServer
Function GenerateParametersConfirmationByEMail()
	If ValueIsFilled(SelReservation) Then
		vHotel = SelReservation.Hotel;   
		vGuestGroup = SelReservation.GuestGroup;
	ElsIf ValueIsFilled(SelGuestGroup) Then
		vHotel = SelGuestGroup.Owner; 
		vGuestGroup = SelGuestGroup;
		If TypeOf(SelGuestGroup.ClientDoc) = Type("DocumentRef.Reservation") Then
			SelReservation = SelGuestGroup.ClientDoc;                                
		EndIf;
	Else
		vGuestGroup = Catalogs.GuestGroups.EmptyRef();
		vHotel = Catalogs.Hotels.EmptyRef();
	EndIf;	
		
	// Save current spreadsheet as PDF
	vFileName = StrReplace(SelReservation.Metadata().Presentation() + " " + Format(vGuestGroup.Code, "ND=12; NFD=0; NG="), " ", "_");
	vFilePath = cmGetFullFileName(vFileName, TempFilesDir()) + ".pdf";
	vFileType = SpreadsheetDocumentFileType.PDF;
	ReservationSpreadsheet.Write(vFilePath, vFileType);   
	
	vIsHTML = False;
	MessageText = "";				
	If ValueIsFilled(vHotel) And ValueIsFilled(vHotel.TemplateSendReservationConfirmationByEMail) Then
		vTemplate = vHotel.TemplateSendReservationConfirmationByEMail;
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
	If Not IsBlankString(MessageText) Then
		MessageText = SMS.ReplaceSMSParameters(MessageText, SelReservation);
	EndIf;	
	vParams = New Structure("Reservation, User, Language, GuestGroup", SelReservation, SessionParameters.CurrentUser, SelLanguage, vGuestGroup);
	vMessage = EMail.GetReservationConfirmationSubjectAndText(vParams);
	If IsBlankString(MessageText) Then
		MessageText = vMessage.MessageText;
	EndIf;
	
	MessageSubject = vMessage.MessageSubject;
	SenderName = vMessage.SenderName;
			  
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
	vFile.Insert("FileName", cmGetValidFileName(SMS.ReplaceSMSParameters(MessageSubject, SelReservation)) + ".pdf");
	vFile.Insert("FullFileNameAtClient", "");
	vFile.Insert("FullFileNameAtServer", vFilePath);
	vFile.Insert("CheckRemoveAtClient",  False);
	vFile.Insert("CheckRemoveAtServer", True);
	
	vParams.Insert("SelFile", vFile);
	vParams.Insert("SelLanguage", SelLanguage);
	vParams.Insert("SelGuestGroup", vGuestGroup);
	vParams.Insert("SelSenderName", SenderName);
	vParams.Insert("SelHotel", SelReservation.Hotel);
	vParams.Insert("SelDocument", SelReservation);
	vParams.Insert("IsHTML", vIsHTML);
	Return vParams;
EndFunction // GenerateParametersConfirmationByEMail

// ---------------------------------------------------------------------------------
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

// ---------------------------------------------------------------------------------
&AtClient
Procedure GenerateReport()
	rDoPrint = Undefined;
	PrintConfirmation(rDoPrint);
	If rDoPrint <> Undefined Then
		rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
	EndIf;
	FillEMailList();
EndProcedure // GenerateReport

#EndRegion
