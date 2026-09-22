
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	SelDocument = Parameters.SelDocument;
	If ValueIsFilled(SelDocument) Then
		SelGuestGroup = SelDocument.GuestGroup;
	ElsIf Parameters.Property("SelGuestGroup") And ValueIsFilled(Parameters.SelGuestGroup) Then
		SelGuestGroup = Parameters.SelGuestGroup;
	EndIf;
	If Not ValueIsFilled(SelDocument) And Not ValueIsFilled(SelGuestGroup) Then
		pCancel = True;
		Return;
	EndIf;
	
	SelIsHotel365 = False;
	SelExternalSystemInteraction = Catalogs.ExternalSystemInteractions.EmptyRef();
	SelPaymentLink = "";   
	//1. check if the service is connected
	If ValueIsFilled(SelDocument) Then
		
		If TypeOf(SelDocument) = Type("DocumentRef.Accommodation") Then
			SelPaymentLink = Catalogs.ExternalSystemInteractions.GetHotel365URL(SelDocument, SelExternalSystemInteraction);
			SelIsHotel365 = True;
		Else
			SelExternalSystemInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsGuestlink(SelDocument.Hotel);
			If TypeOf(SelDocument) = Type("DocumentRef.Reservation") Then
				SelPaymentLink = Catalogs.ExternalSystemInteractions.GetReservationGuestURL(SelDocument, SelExternalSystemInteraction);
			ElsIf TypeOf(SelDocument) = Type("DocumentRef.ProformaInvoice") Then
				SelPaymentLink = Catalogs.ExternalSystemInteractions.GetProformaInvoiceURL(SelDocument, SelExternalSystemInteraction);
			EndIf;
		EndIf;		
		SelLanguage = SelDocument.Hotel.Language;
		If TypeOf(SelDocument) = Type("DocumentRef.Accommodation") Or TypeOf(SelDocument) = Type("DocumentRef.Reservation") Then
			If ValueIsFilled(SelDocument.Guest) Then
				SelLanguage = SelDocument.Guest.Language;
			EndIf;
		ElsIf TypeOf(SelDocument) = Type("DocumentRef.Folio") Or TypeOf(SelDocument) = Type("DocumentRef.ResourceReservation") Then
			If ValueIsFilled(SelDocument.Client) Then
				SelLanguage = SelDocument.Client.Language;
			EndIf;
		ElsIf TypeOf(SelDocument) = Type("DocumentRef.ProformaInvoice") Then
			If ValueIsFilled(SelDocument.AccountingCustomer) Then
				SelLanguage = SelDocument.AccountingCustomer.Language;
			EndIf;
		EndIf;
	Else
		SelExternalSystemInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsGuestlink(SelGuestGroup.Owner);
		SelPaymentLink = Catalogs.ExternalSystemInteractions.GetGuestGroupURL(SelGuestGroup, SelExternalSystemInteraction);
		SelLanguage = SelGuestGroup.Owner.Language;
		If ValueIsFilled(SelGuestGroup.Client) Then
			SelLanguage = SelGuestGroup.Client.Language;
		EndIf;
	EndIf;
	
	If ValueIsFilled(SelExternalSystemInteraction) Then
		Items.GroupConnected.Visible = true;
		Items.GroupNotConnected.Visible = false;
		
		Items.SendSMS.Visible = ValueIsFilled(Constants.SMSLogin.Get());
			
		FillInformationTable();
	Else
		Items.GroupConnected.Visible = False;
		Items.GroupNotConnected.Visible = True;
	EndIf;
	
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure InformationTableSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	If pField.Name = "InformationTableDescription" Then
		vCurRow = Items.InformationTable.CurrentData;
		If vCurRow <> Undefined Then
			vCurData = vCurRow["Description"];
			If ValueIsFilled(vCurData) Then
				ShowValue(, vCurData);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // InformationTableSelection

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure CopyToBuffer(pCommand)
	#If Not MobileClient Then
		Try
			ObjCopy = New COMObject("htmlfile"); 
			ObjCopy.ParentWindow.ClipboardData.SetData("Text", SelPaymentLink);
		Except
		EndTry;
	#EndIf
EndProcedure // CopyToBuffer

// --------------------------------------------------------------------------------
&AtClient
Procedure SendSMS(pCommand)
	vDocument = SelDocument;
	If Not ValueIsFilled(vDocument) Then
		vDocument = tcOnServer.cmGetAttributeByRef(SelGuestGroup, "ClientDoc");
	EndIf;
	If Not ValueIsFilled(vDocument) Then
		tcCommonFunctionOnClientServer.UserMessage("Client document used to send E-Mail to is not defined!");
		Return;
	EndIf;
	If Not ValueIsFilled(tcOnServer.cmGetAttributeByRef(vDocument, "Hotel")) Then
		tcCommonFunctionOnClientServer.UserMessage("Not all parameters are filled!");
		Return;
	EndIf;
	If Not ValueIsFilled(SelPaymentLink) Then
		tcCommonFunctionOnClientServer.UserMessage("Missing online module link in the program constants!");
		Return;
	EndIf;
	vParams = GetParametersForSMS(vDocument, SelLanguage, SelPaymentLink, SelExternalSystemInteraction, SelIsHotel365);
	OpenForm("CommonForm.tcSMSSending", vParams, ThisObject, UUID, , , New NotifyDescription("AfterSMSSending", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // SendSMS

// --------------------------------------------------------------------------------
&AtClient
Procedure SendMail(pCommand)
	vDocument = SelDocument;
	If Not ValueIsFilled(vDocument) Then
		vDocument = tcOnServer.cmGetAttributeByRef(SelGuestGroup, "ClientDoc");
	EndIf;
	If Not ValueIsFilled(vDocument) Then
		tcCommonFunctionOnClientServer.UserMessage("Client document used to send E-Mail to is not defined!");
		Return;
	EndIf;
	If Not ValueIsFilled(tcOnServer.cmGetAttributeByRef(vDocument, "Hotel")) Then
		tcCommonFunctionOnClientServer.UserMessage("Not all parameters are filled!");
		Return;
	EndIf;
	If Not ValueIsFilled(SelPaymentLink) Then
		tcCommonFunctionOnClientServer.UserMessage("Missing online module link in the program constants!");
		Return;
	EndIf;
	vParams = GetParametersForEMail(vDocument, SelLanguage, SelPaymentLink, SelExternalSystemInteraction, SelIsHotel365, Not ValueIsFilled(SelDocument));
	OpenForm("CommonForm.tcSendMail", vParams, ThisObject, UUID, , , New NotifyDescription("AfterSendMail", ThisObject));
EndProcedure // SendMail

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure CreateGroupInvoice(pCommand)
	vForm = GetForm("Document.ProformaInvoice.ObjectForm");
	#If ThinClient Or WebClient Or MobileClient Then
		vFormData = vForm.Object;
		NewGroupInvoice(vFormData, True);
		CopyFormData(vFormData, vForm.Object);
	#Else
		vObj = NewGroupInvoice(Undefined, False);
		vForm = GetForm("Document.ProformaInvoice.Form.DocumentForm", New Structure("Key", vObj));
	#EndIf
	vForm.Open();
EndProcedure // CreateGroupInvoice

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure ActionRefresh(pCommand)
	FillInformationTable();
EndProcedure // Refresh

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure FillInformationTable()
	InformationTable.Clear();
	
	vQuery = New Query();
	vQuery.Text = 
	"SELECT
	|	SMSMessages.Text AS Description,
	|	SMSMessages.Status AS Status,
	|	SMSMessages.Period AS Date,
	|	SMSMessages.MessageID AS MessageID,
	|	SMSMessages.Phone AS Phone
	|FROM
	|	InformationRegister.SMSMessages AS SMSMessages
	|WHERE
	|	&qDocumentIsFilled AND SMSMessages.SourceDoc = &qDocument OR 
	|	&qGuestGroupIsFilled AND SMSMessages.SourceDoc.GuestGroup = &qGuestGroup";
	vQuery.SetParameter("qDocument", SelDocument);
	vQuery.SetParameter("qDocumentIsFilled", ValueIsFilled(SelDocument));
	vQuery.SetParameter("qGuestGroup", SelGuestGroup);
	vQuery.SetParameter("qGuestGroupIsFilled", ValueIsFilled(SelGuestGroup) And Not ValueIsFilled(SelDocument));
	vResult = vQuery.Execute().Unload();
	
	For Each vRow In vResult Do
		vNewRow = InformationTable.Add();
		vNewRow.Type = "SMS";
		vNewRow.Description = vRow.Description; 
		vNewRow.Status = vRow.Status;
		vNewRow.Date = vRow.Date;
		vNewRow.Icon = 1;
		vNewRow.DatePresentation = GetDateTimePresentation(vNewRow.Date);
	EndDo;
	
	If ValueIsFilled(SelGuestGroup) Then
		vQuery = New Query();
		vQuery.Text =
		"SELECT
		|	GuestGroupAttachments.DocumentText AS Description,
		|	GuestGroupAttachments.AttachmentStatus AS Status,
		|	GuestGroupAttachments.Period AS Date,
		|	GuestGroupAttachments.Remarks AS Remarks
		|FROM
		|	InformationRegister.GuestGroupAttachments AS GuestGroupAttachments
		|WHERE
		|	GuestGroupAttachments.GuestGroup = &qGuestGroup";
		vQuery.SetParameter("qGuestGroup", SelGuestGroup);
		vResult = vQuery.Execute().Unload();

		For Each vRow In vResult Do    
			vDescription = vRow.Remarks + Chars.CR + vRow.Description;
			If IsBlankString(vRow.Remarks) Then
			    vDescription = vRow.Description;
			EndIf;
			vNewRow = InformationTable.Add();
			vNewRow.Type = "HTML";
			vNewRow.Description = vDescription;
			vNewRow.Status = vRow.Status;
			vNewRow.Date = vRow.Date;
			vNewRow.Icon = 6;
			vNewRow.DatePresentation = GetDateTimePresentation(vNewRow.Date);
		EndDo;
	EndIf;
	
	vQuery = New Query();
	vQuery.Text =
	"SELECT
	|	DocumentInvoice.Ref AS Description,
	|	DocumentInvoice.Sum AS Status,
	|	CASE
	|		WHEN DocumentInvoice.Posted
	|			THEN CASE
	|					WHEN DocumentInvoice.CheckDate <> DATETIME(1, 1, 1, 0, 0, 0)
	|							AND BEGINOFPERIOD(DocumentInvoice.CheckDate, DAY) < BEGINOFPERIOD(&qCurrentDate, DAY)
	|							AND ISNULL(DocumentInvoice.Sum, 0) = ISNULL(InvoiceAccountsBalance.SumBalance, 0)
	|						THEN 12
	|					ELSE CASE
	|							WHEN ISNULL(DocumentInvoice.Sum, 0) - ISNULL(InvoiceAccountsBalance.SumBalance, 0) >= DocumentInvoice.Sum
	|								THEN 10
	|							ELSE CASE
	|									WHEN ISNULL(DocumentInvoice.Sum, 0) - ISNULL(InvoiceAccountsBalance.SumBalance, 0) > 0
	|										THEN 11
	|									ELSE 9
	|								END
	|						END
	|				END
	|		ELSE 0
	|	END AS IDStatus,
	|	DocumentInvoice.AccountingCurrency AS Currency,
	|	DocumentInvoice.PointInTime AS PointInTime
	|FROM
	|	Document.ProformaInvoice AS DocumentInvoice
	|		LEFT JOIN AccumulationRegister.InvoiceAccounts.Balance(, ) AS InvoiceAccountsBalance
	|		ON DocumentInvoice.Ref = InvoiceAccountsBalance.Invoice
	|WHERE
	|	DocumentInvoice.Hotel = &qHotel
	|	AND (DocumentInvoice.ParentDoc = &qParentDoc
	|				AND VALUETYPE(&qParentDoc) <> TYPE(Document.ProformaInvoice)
	|				AND &qParentDocIsFilled
	|			OR DocumentInvoice.GuestGroup = &qGuestGroup
	|				AND VALUETYPE(&qParentDoc) <> TYPE(Document.ProformaInvoice)
	|				AND NOT &qParentDocIsFilled
	|			OR DocumentInvoice.Ref = &qParentDoc
	|				AND VALUETYPE(&qParentDoc) = TYPE(Document.ProformaInvoice))
	|	AND DocumentInvoice.Posted";
	vQuery.SetParameter("qParentDoc", SelDocument);
	vQuery.SetParameter("qParentDocIsFilled", ValueIsFilled(SelDocument));
	vQuery.SetParameter("qGuestGroup", SelGuestGroup);
	vQuery.SetParameter("qHotel", SelGuestGroup.Owner);
	vQuery.SetParameter("qCurrentDate", CurrentSessionDate());
	vResult = vQuery.Execute().Unload();

	For Each vRow In vResult Do
		vNewRow = InformationTable.Add();
		vNewRow.Type = NStr("en = 'Invoice'; de = 'Rechnung'; ru = 'Счет'");
		vNewRow.Description = vRow.Description; 
		vNewRow.Status = cmFormatSum(vRow.Status, vRow.Currency, "0");
		vNewRow.Date = vRow.PointInTime.Date;
		vNewRow.Icon = vRow.IDStatus;
		vNewRow.DatePresentation = GetDateTimePresentation(vNewRow.Date);
	EndDo;
	
	vQuery = New Query();
	vQuery.Text =
	"SELECT
	|	Payments.PointInTime AS PointInTime,
	|	Payments.Sum AS Status,
	|	Payments.PaymentCurrency AS Currency,
	|	Payments.PaymentMethod AS Description
	|FROM
	|	Document.Payment AS Payments
	|WHERE
	|	Payments.Posted
	|	AND CASE
	|			WHEN VALUETYPE(&qParentDoc) = TYPE(Document.ProformaInvoice)
	|				THEN Payments.Invoice = &qParentDoc
	|			WHEN VALUETYPE(&qParentDoc) <> TYPE(Document.Folio)
	|					AND &qParentDocIsFilled
	|				THEN Payments.ParentDoc = &qParentDoc
	|			WHEN VALUETYPE(&qParentDoc) = TYPE(Document.Folio)
	|					AND &qParentDocIsFilled
	|				THEN Payments.Folio = &qParentDoc
	|			ELSE Payments.GuestGroup = &qGuestGroup
	|		END
	|	AND Payments.Hotel = &qHotel";
	vQuery.SetParameter("qParentDoc", SelDocument);
	vQuery.SetParameter("qParentDocIsFilled", ValueIsFilled(SelDocument));
	vQuery.SetParameter("qGuestGroup", SelGuestGroup);
	vQuery.SetParameter("qHotel", SelGuestGroup.Owner);
	vResult = vQuery.Execute().Unload();
	
	For Each vRow In vResult Do
		vNewRow = InformationTable.Add();
		vNewRow.Type = NStr("en = 'Payment'; de = 'Zahlung'; ru = 'Платеж'");
		vNewRow.Description =   vRow.Description;
		vNewRow.Status = cmFormatSum(vRow.Status, vRow.Currency, "0"); 
		vNewRow.Icon = 5;
		vNewRow.Date = vRow.PointInTime.Date;
		vNewRow.DatePresentation = GetDateTimePresentation(vNewRow.Date);
	EndDo;
	InformationTable.Sort("Date");
EndProcedure // FillInformationTable

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetDateTimePresentation(pDate)  
	If BegOfDay(pDate) = BegOfDay(CurrentSessionDate()) Then
		// It's taday - time is enough
		vDatePres = Format(pDate, "DF=HH:mm");
	ElsIf BegOfYear(pDate) = BegOfYear(CurrentSessionDate()) Then
		vDatePres = Format(pDate, "DF='dd.MMM. HH:mm'");
	Else
		vDatePres = Format(pDate, "DF=dd.MMM.yyyy");
	EndIf; 
	Return vDatePres;
EndFunction

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetParametersForSMS(pDocument, pLanguage, pPaymentLink, pExternalSystemInteraction, pIsHotel365)
	vParams = New Structure();
	vSMSText = "";
	If Not pIsHotel365 Then
		If TypeOf(pDocument) = Type("DocumentRef.ProformaInvoice") Then
			vSMSTemplate = Catalogs.SMSTemplates.SendProformaInvoicePaymentLinkMessage;
		Else
			vSMSTemplate = Catalogs.SMSTemplates.SendPaymentLinkMessage;
		EndIf;
	Else
		vSMSTemplate = pExternalSystemInteraction.SMSTemplate;	
	EndIf;
	If ValueIsFilled(vSMSTemplate) And (Not IsBlankString(vSMSTemplate.SMSTextRu) Or Not IsBlankString(vSMSTemplate.SMSTextEn) Or Not IsBlankString(vSMSTemplate.SMSTextDe)) Then
		vSMSText = SMS.GetSMSTextByLanguage(vSMSTemplate, pLanguage);
	Else
		vHotel = pDocument.Hotel;
		If ValueIsFilled(vHotel) Then
			If Not pIsHotel365 Then    
				vSenderName = Catalogs.Hotels.pmGetHotelPrintName(pDocument.Hotel, pLanguage);
				If TypeOf(pDocument) = Type("DocumentRef.ProformaInvoice") Then
					vSMSText = vSenderName + cmNStr("en=': You may pay the proforma invoice by following the link '; ru=': Оплатить счет можно по ссылке '; de=': Sie können die Proforma-Rechnung bezahlen, indem Sie dem Link folgen '", pLanguage) + "&ProformaInvoiceLink";
				Else
					vSMSText = vSenderName + cmNStr("en=': Your reservation '; ru=': Ваше бронирование '; de=': Um Ihre Reservierung '", pLanguage) + "&GuestGroup &GuestReservationLink";
				EndIf;
			Else
				vSMSText = cmNStr("en = 'Welcome to '; de = 'Willkommen bei '; ru = 'Добро пожаловать в '", pLanguage) + vSenderName + " &GuestHotel365Link";	
			EndIf;	
		EndIf;		
	EndIf;
	If TypeOf(pDocument) = Type("DocumentRef.ProformaInvoice") Then
		vClient = Undefined;
		If ValueIsFilled(pDocument.ParentDoc) Then
			If TypeOf(pDocument.ParentDoc) = Type("DocumentRef.ResourceReservation") Then
				vClient = pDocument.ParentDoc.Client;
			ElsIf TypeOf(pDocument.ParentDoc) = Type("DocumentRef.Reservation") Then
				vClient = pDocument.ParentDoc.Guest;
			ElsIf TypeOf(pDocument.ParentDoc) = Type("DocumentRef.Accommodation") Then
				vClient = pDocument.ParentDoc.Guest;
			EndIf;
		EndIf;          
		vSMSText = SMS.ReplaceSMSParameters(vSMSText, pDocument);
		vSMSText = ReplaceParameters(vSMSText, pDocument, pPaymentLink, pExternalSystemInteraction, False);
	Else 
		vSMSText = SMS.ReplaceSMSParameters(vSMSText, pDocument);
		vSMSText = ReplaceParameters(vSMSText, pDocument, pPaymentLink, pExternalSystemInteraction, False);
	EndIf;
	
	vParams.Insert("SMSText", vSMSText);
	vParams.Insert("Reciever", pDocument);
	vParams.Insert("ReadOnlyReciever", True);
	
	Return vParams;
EndFunction // GetParametersForSMS

// --------------------------------------------------------------------------------
&AtClient
Procedure AfterSMSSending(pValue, pExtraParams) Export 
	FillInformationTable();	
EndProcedure // AfterSMSSending

// --------------------------------------------------------------------------------
&AtServerNoContext
Function ReplaceParameters(pSMSText, pDocRef, pPaymentLink, pExternalSystemInteraction, pIsHTML)
	// Get external system interactions
	If TypeOf(pDocRef) = Type("DocumentRef.Reservation") Then
		If pIsHTML Then
			pSMSText = StrReplace(pSMSText, "&GuestReservationLink", "<a href=" + pPaymentLink + ">" + pExternalSystemInteraction.HttpAddress + "</a>");
		Else
			pSMSText = StrReplace(pSMSText, "&GuestReservationLink", pPaymentLink);
		EndIf;
	ElsIf TypeOf(pDocRef) = Type("DocumentRef.Accommodation") Or TypeOf(pDocRef) = Type("DocumentRef.ResourceReservation") Or TypeOf(pDocRef) = Type("DocumentRef.Folio") Then
		If pIsHTML Then
			pSMSText = StrReplace(pSMSText, "&GuestHotel365Link", "<a href=" + pPaymentLink + ">" + pExternalSystemInteraction.HttpAddress + "</a>");
		Else
			pSMSText = StrReplace(pSMSText, "&GuestHotel365Link", pPaymentLink);
		EndIf;	
	ElsIf TypeOf(pDocRef) = Type("DocumentRef.ProformaInvoice") Then
		If pIsHTML Then
			pSMSText = StrReplace(pSMSText, "&ProformaInvoiceLink", "<a href=" + pPaymentLink + ">" + pExternalSystemInteraction.HttpAddress + "</a>");
		Else
			pSMSText = StrReplace(pSMSText, "&ProformaInvoiceLink", pPaymentLink);
		EndIf;
	EndIf;   
	Return pSMSText;
EndFunction // ReplaceParameters

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetEMailList(pDocument)
	vEMailList = New ValueList();
	If ValueIsFilled(pDocument) Then
		If ValueIsFilled(pDocument.EMail) Then
			vEMailList.Add(pDocument.EMail);
		EndIf;
		If TypeOf(pDocument) = Type("DocumentRef.Accommodation") Or TypeOf(pDocument) = Type("DocumentRef.Reservation") Or TypeOf(pDocument) = Type("DocumentRef.ResourceReservation") Then 
			If ValueIsFilled(pDocument.Customer) And ValueIsFilled(pDocument.Customer.EMail) Then
				vEMailList.Add(pDocument.Customer.EMail);
			EndIf;
			If ValueIsFilled(pDocument.ContactPerson) Then
				vContactPersonEMail = cmGetContactPersonEMail(pDocument.ContactPerson);
				If ValueIsFilled(vContactPersonEMail) Then
					vEMailList.Add(vContactPersonEMail);
				EndIf;
			EndIf;
		ElsIf TypeOf(pDocument) = Type("DocumentRef.ProformaInvoice") Then
			If ValueIsFilled(pDocument.AccountingCustomer) And ValueIsFilled(pDocument.AccountingCustomer.EMail) Then
				vEMailList.Add(pDocument.AccountingCustomer.EMail);
			EndIf;
		EndIf;
		If TypeOf(pDocument) = Type("DocumentRef.Accommodation") Or TypeOf(pDocument) = Type("DocumentRef.Reservation") Then 
			If ValueIsFilled(pDocument.Guest) And ValueIsFilled(pDocument.Guest.EMail) Then
				vEMailList.Add(pDocument.Guest.EMail);
			EndIf;
		ElsIf TypeOf(pDocument) = Type("DocumentRef.ResourceReservation") Or TypeOf(pDocument) = Type("DocumentRef.Folio") Then 
			If ValueIsFilled(pDocument.Client) And ValueIsFilled(pDocument.Client.EMail) Then
				vEMailList.Add(pDocument.Client.EMail);
			EndIf;
		EndIf;
	EndIf;
	Return vEMailList;
EndFunction // GetEMailList

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetObjectPrintingByLanguage(pTemplate, pLanguage)
	vObjectPrintingForm = Catalogs.ObjectPrintingForms.EmptyRef();
	If Not ValueIsFilled(pLanguage) Then
		pLanguage = SessionParameters.CurrentLanguage;
	EndIf;
	If pLanguage = Catalogs.Languages.RU Then
		vObjectPrintingForm = pTemplate.ObjectPrintingFormRu;
	ElsIf pLanguage = Catalogs.Languages.EN Then
		vObjectPrintingForm = pTemplate.ObjectPrintingFormEn;
	ElsIf pLanguage = Catalogs.Languages.DE Then
		vObjectPrintingForm = pTemplate.ObjectPrintingFormDe;
	EndIf;
	Return vObjectPrintingForm;
EndFunction // GetObjectPrintingByLanguage

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetParametersForEMail(pDocument, pLanguage, pPaymentLink, pExternalSystemInteraction, pIsHotel365, pShowConfirmationForCurrentReservationOnly = False)
	vParams = New Structure();
	vIsHTML = False;
	vSMSTemplate = Catalogs.SMSTemplates.EmptyRef();  
	vSenderName = "";
	If ValueIsFilled(pDocument.Hotel) Then 
		vSenderName = Catalogs.Hotels.pmGetHotelPrintName(pDocument.Hotel, pLanguage);  
	EndIf;
	vEMailList = GetEMailList(pDocument); 
	vGuestGroupPrint = Format(pDocument.GuestGroup.Code, "ND=12; NFD=0; NG=");
	If Not pIsHotel365 Then
		If TypeOf(pDocument) = Type("DocumentRef.ProformaInvoice") Then
			vMessageSubject = vSenderName + tcOnServer.cmNStrAtServer("en=' Payment by proforma invoice N." + cmGetDocumentNumberPresentation(pDocument.Number) + " (" + Format(pDocument.Date, "DF=dd.MM.yyyy") + ")'; 
							                           |de=' Zahlung per Proforma-Rechnung Nr." + cmGetDocumentNumberPresentation(pDocument.Number) + " (" + Format(pDocument.Date, "DF=dd.MM.yyyy") + ")'; 
			                                           |ru=' Оплата по счету №" + cmGetDocumentNumberPresentation(pDocument.Number) + " (" + Format(pDocument.Date, "DF=dd.MM.yyyy") + ")'", pLanguage);
			vSMSTemplate = Catalogs.SMSTemplates.SendProformaInvoicePaymentLinkMessage;
		Else
			vMessageSubject = vSenderName + StrTemplate(tcOnServer.cmNStrAtServer("en = ' Reservation confirmation N %1'; de = ' Reservation confirmation N %1'; ru = ' Подтверждение брони № %1'", pLanguage), vGuestGroupPrint);
			vSMSTemplate = Catalogs.SMSTemplates.SendPaymentLinkMessage;
		EndIf;
		
		If ValueIsFilled(vSMSTemplate) Then
			vMessageSubject = cmNStr(TrimAll(vSMSTemplate.Description), pLanguage);
			If vSMSTemplate.AttachDocumentPrintFormToEMail Then
				vObjectPrinting = GetObjectPrintingByLanguage(vSMSTemplate, pLanguage);
				If ValueIsFilled(vObjectPrinting) Then
					vReservationSpreadsheet = New SpreadsheetDocument();
					If ValueIsFilled(vObjectPrinting.ExternalProcessing) Then
						vExtDataProcessor = cmGetExternalDataProcessorObject(vObjectPrinting.ExternalProcessing);
						vExtDataProcessor.pmPrintConfirmation(vReservationSpreadsheet, pDocument, Undefined, 0, Catalogs.ServiceGroups.EmptyRef(), pShowConfirmationForCurrentReservationOnly, pLanguage, vObjectPrinting);
					Else
						pDocument.GetObject().pmPrintConfirmation(vReservationSpreadsheet, pDocument, New ValueList(), 0, Catalogs.ServiceGroups.EmptyRef(), pShowConfirmationForCurrentReservationOnly, pLanguage, vObjectPrinting);
					EndIf;
					vFileName = StrReplace(pDocument.Metadata().Presentation() + " " + vGuestGroupPrint, " ", "_");
					vFilePath = cmGetFullFileName(vFileName, TempFilesDir()) + ".pdf";
					vFileType = SpreadsheetDocumentFileType.PDF;
					vReservationSpreadsheet.Write(vFilePath, vFileType);
					vFile = New Structure();
					vFile.Insert("FileName", cmGetValidFileName(vMessageSubject) + ".pdf");
					vFile.Insert("FullFileNameAtClient", "");
					vFile.Insert("FullFileNameAtServer", vFilePath);
					vFile.Insert("CheckRemoveAtClient",  False);
					vFile.Insert("CheckRemoveAtServer", True);
					vParams.Insert("SelFile", vFile);
				EndIf;
			EndIf;
		EndIf;
	Else
		vSMSTemplate = pExternalSystemInteraction.SMSTemplate;	
		If ValueIsFilled(vSMSTemplate) Then
			vMessageSubject = cmNStr(TrimAll(vSMSTemplate.Description), pLanguage); 		
		EndIf;
	EndIf;
	
	vMessageText = "";
	If ValueIsFilled(vSMSTemplate) And (ValueIsFilled(vSMSTemplate.HTMLTextRu) Or ValueIsFilled(vSMSTemplate.HTMLTextEn) Or ValueIsFilled(vSMSTemplate.HTMLTextDe)) Then
		vMessageText = SMS.GetHTMLTextByLanguage(vSMSTemplate, pLanguage);
		If Not IsBlankString(vMessageText) Then
			vIsHTML = True;
		EndIf;
	EndIf;
	If IsBlankString(vMessageText) Then
		If ValueIsFilled(vSMSTemplate) And (ValueIsFilled(vSMSTemplate.SMSTextRu) Or ValueIsFilled(vSMSTemplate.SMSTextRu) Or ValueIsFilled(vSMSTemplate.SMSTextDe)) Then
			vMessageText = SMS.GetSMSTextByLanguage(vSMSTemplate, pLanguage);
		EndIf;
	EndIf;
	If IsBlankString(vMessageText) Then
		If Not pIsHotel365 Then
			If TypeOf(pDocument) = Type("DocumentRef.ProformaInvoice") Then
				vMessageText = vSenderName + cmNStr("en=': You may pay the proforma invoice by following the link '; ru=': Оплатить счет можно по ссылке '; de=': Sie können die Proforma-Rechnung bezahlen, indem Sie dem Link folgen '", pLanguage) + "&ProformaInvoiceLink";
			Else
				vMessageText = vSenderName + cmNStr("en=': Your reservation '; ru=': Ваше бронирование '; de=': Um Ihre Reservierung '", pLanguage) + "&GuestGroup &GuestReservationLink";
			EndIf;
		Else
			vMessageText = cmNStr("en = 'Welcome to '; de = 'Willkommen bei '; ru = 'Добро пожаловать в '", pLanguage) + vSenderName + " &GuestHotel365Link";	
		EndIf;
	EndIf;
	
	If TypeOf(pDocument) = Type("DocumentRef.ProformaInvoice") Then
		vClient = Undefined;
		If ValueIsFilled(pDocument.ParentDoc) Then
			If TypeOf(pDocument.ParentDoc) = Type("DocumentRef.ResourceReservation") Then
				vClient = pDocument.ParentDoc.Client;
			ElsIf TypeOf(pDocument.ParentDoc) = Type("DocumentRef.Reservation") Then
				vClient = pDocument.ParentDoc.Guest;
			ElsIf TypeOf(pDocument.ParentDoc) = Type("DocumentRef.Accommodation") Then
				vClient = pDocument.ParentDoc.Guest;
			EndIf;
		EndIf;
	   	vMessageSubject = ReplaceParameters(vMessageSubject, pDocument, pPaymentLink, pExternalSystemInteraction, False);
	   	vMessageText = ReplaceParameters(vMessageText, pDocument, pPaymentLink, pExternalSystemInteraction, vIsHTML);
	Else
   		vMessageSubject = ReplaceParameters(vMessageSubject, pDocument, pPaymentLink, pExternalSystemInteraction, False); 
   		vMessageText = ReplaceParameters(vMessageText, pDocument, pPaymentLink, pExternalSystemInteraction, vIsHTML); 
	EndIf;
	
	vParams.Insert("SelMessageSubject", vMessageSubject);
	vParams.Insert("SelMessageText", vMessageText);
	vParams.Insert("IsHTML", vIsHTML);
	vParams.Insert("SelEMails", "");
	vParams.Insert("SelToList", vEMailList);
	vParams.Insert("SelLanguage", pLanguage);
	vParams.Insert("SelGuestGroup", pDocument.GuestGroup);
	vParams.Insert("SelSenderName", vSenderName);
	vParams.Insert("SelHotel", pDocument.Hotel);
	vParams.Insert("SelDocument", pDocument);
	vParams.Insert("SelSMSTemplates", vSMSTemplate);
	Return vParams;
EndFunction // GetParametersForEMail

// --------------------------------------------------------------------------------
&AtClient
Procedure AfterSendMail(pValue, pExtraParams) Export 
	FillInformationTable();	
EndProcedure // AfterSendMail

// ------------------------------------------------------------------------------------------------
&AtServer
Function NewGroupInvoice(pFormData, pThinClient)
	If ValueIsFilled(SelDocument) Then
		If TypeOf(SelDocument) <> Type("DocumentRef.ProformaInvoice") Then
			If pThinClient Then
				vInvObj = FormDataToValue(pFormData, Type("DocumentObject.ProformaInvoice"));
				vInvObj.Fill(SelDocument);
				vInvObj.ParentDoc = Undefined;
				vInvObj.Fill(SelDocument.GuestGroup);
				ValueToFormData(vInvObj, pFormData);
			Else
				vInvObj = Documents.ProformaInvoice.CreateDocument();
				vInvObj.Fill(SelDocument.Ref);
				vInvObj.ParentDoc = Undefined;
				vInvObj.Fill(SelDocument.GuestGroup);
				Return vInvObj;
			EndIf;
		EndIf;
	Else
		If pThinClient Then
			vInvObj = FormDataToValue(pFormData, Type("DocumentObject.ProformaInvoice"));
			vInvObj.Fill(SelGuestGroup);
			ValueToFormData(vInvObj, pFormData);
		Else
			vInvObj = Documents.ProformaInvoice.CreateDocument();
			vInvObj.Fill(SelGuestGroup);
			Return vInvObj;
		EndIf;
	EndIf;
EndFunction // NewGroupInvoice

&AtClient
Async Procedure CommandConnect(Command)
  #IF WebClient THEN
    GotoURL("https://pay.guestlink.ru/order");
  #ELSE
    Await RunAppAsync("https://pay.guestlink.ru/order");
  #ENDIF
EndProcedure

#EndRegion
