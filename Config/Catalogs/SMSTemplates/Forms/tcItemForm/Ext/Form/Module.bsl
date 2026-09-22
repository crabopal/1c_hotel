
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Language
	SelLanguage = SessionParameters.CurrentLanguage;
	SelLanguageOld = SelLanguage;
	TypeDescription = cmGetObjectTypeDescription(Object.ObjectType);
	Items.ObjectType.AvailableTypes = cmGetObjectsTypeDescription();
	Items.ObjectType.TypeDomainEnabled = False;

	Items.ObjectPrintingFormRu.Enabled = Object.AttachDocumentPrintFormToEMail;
	Items.ObjectPrintingFormEn.Enabled = Object.AttachDocumentPrintFormToEMail;
	Items.ObjectPrintingFormDe.Enabled = Object.AttachDocumentPrintFormToEMail;
	Items.ObjectPrintingFormRu.Visible = Object.AttachDocumentPrintFormToEMail;
	Items.ObjectPrintingFormEn.Visible = Object.AttachDocumentPrintFormToEMail;
	Items.ObjectPrintingFormDe.Visible = Object.AttachDocumentPrintFormToEMail;
		
	Refresh(SelLanguage);	
	SetHTMLText(SelLanguage);
	SetHTMLViewer(SelLanguage);
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	If PrevHTMLPanelPage = "GroupReachEdit" Then
		FillHTMLText(SelLanguage);
	EndIf;
EndProcedure // BeforeWrite

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure AttachDocumentPrintFormToEMailOnChange(pItem)
	Items.ObjectPrintingFormRu.Enabled = Object.AttachDocumentPrintFormToEMail;
	Items.ObjectPrintingFormEn.Enabled = Object.AttachDocumentPrintFormToEMail;
	Items.ObjectPrintingFormDe.Enabled = Object.AttachDocumentPrintFormToEMail;
	Items.ObjectPrintingFormRu.Visible = Object.AttachDocumentPrintFormToEMail;
	Items.ObjectPrintingFormEn.Visible = Object.AttachDocumentPrintFormToEMail;
	Items.ObjectPrintingFormDe.Visible = Object.AttachDocumentPrintFormToEMail;
EndProcedure // AttachDocumentPrintFormToEMailOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DescriptionOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", TrimAll(pItem.EditText)), pItem);
EndProcedure // DescriptionOpening

// -----------------------------------------------------------------------------
&AtClient
Procedure GroupHTMLPanelOnCurrentPageChange(pItem, pCurrentPage)
	If pCurrentPage.Name = "GroupReachEdit" Then	 
		 SetHTMLText(SelLanguage);
	Else
		If PrevHTMLPanelPage = "GroupReachEdit" Then
			FillHTMLText(SelLanguage);
		EndIf; 
		SetHTMLViewer(SelLanguage);	 
	EndIf;
	PrevHTMLPanelPage = Items.GroupHTMLPanel.CurrentPage.Name;
EndProcedure // GroupHTMLPanelOnCurrentPageChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelLanguageOnChange(pItem)
	FillHTMLText(SelLanguageOld);	
	SetHTMLText(SelLanguage);
	SetHTMLViewer(SelLanguage);
	Refresh(SelLanguage);
	SelLanguageOld = SelLanguage;
EndProcedure // SelLanguageOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ObjectPrintingFormStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.ObjectPrintingForms.Form.tcChoiceForm", New Structure("ChoiceMode", True), pItem, UUID);
EndProcedure // ObjectPrintingFormStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure ObjectTypeOnChange(pItem)
	Object.ObjectType = TypeDescription.AdjustValue();	
EndProcedure // ObjectTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelLanguageClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure // SelLanguageClearing

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionInsertPicture(pCommand) 
	vParams = tcOnClientWorkWithFiles.cmGetEmptyParamsForLoadFiles();
	vParams.Filter = tcOnClientWorkWithFiles.cmGetChooseFilterForAllPictures();
	vParams.NotifyDescription = New NotifyDescription("SetImageToFormattedDocument", ThisObject); 
	tcOnClientWorkWithFiles.LoadFile(vParams);
EndProcedure // ActionInsertPicture

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionInsertAutoTextSMS(pCommand)
	ShowChooseFromMenu(New NotifyDescription("AfterActionInsertAutoTextSMS", ThisObject), GetAutoTextItem(), Items.ActionInsertAutoTextSMS);
EndProcedure // ActionInsertAutoTextSMS

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionInsertAutoTextHTML(pCommand) 
	ShowChooseFromMenu(New NotifyDescription("AfterActionInsertAutoTextHTML", ThisObject), EMail.GetEMailParametersList(), Items.ActionInsertAutoTextHTML);
EndProcedure // ActionInsertAutoTextHTML 

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure ActionInsertAutoTextSMSAtServer(pKWListItem, pNameAttribute)
	vObj = FormAttributeToValue("Object");
	vObj[pNameAttribute] = TrimAll(TrimAll(vObj[pNameAttribute]) + " " + pKWListItem);
	ValueToFormAttribute(vObj, "Object");
EndProcedure // ActionInsertAutoTextSMSAtServer 

// -----------------------------------------------------------------------------
&AtServer
Procedure Refresh(pLanguage)
	Items.SMSTextRu.Visible = False;
	Items.SMSTextEn.Visible = False;
	Items.SMSTextDe.Visible = False;
	Items.HTMLTextRu.Visible = False;
	Items.HTMLTextEn.Visible = False;
	Items.HTMLTextDe.Visible = False;
	If pLanguage = Catalogs.Languages.RU Then 
		TMessageLength = Format(StrLen(Object.SMSTextRu), "ND=10; NFD=0; NG="); 
		TNumberOfSMS = Format(SMS.GetNumberOfSegments(Object.SMSTextRu), "ND=10; NFD=0; NG=");
		Items.SMSTextRu.Visible = True;
		Items.HTMLTextRu.Visible = True;
	ElsIf pLanguage = Catalogs.Languages.EN Then 
		TMessageLength = Format(StrLen(Object.SMSTextEn), "ND=10; NFD=0; NG="); 
		TNumberOfSMS = Format(SMS.GetNumberOfSegments(Object.SMSTextEn), "ND=10; NFD=0; NG=");
		Items.SMSTextEn.Visible = True;
		Items.HTMLTextEn.Visible = True;
	ElsIf pLanguage = Catalogs.Languages.DE Then
		TMessageLength = Format(StrLen(Object.SMSTextDe), "ND=10; NFD=0; NG="); 
		TNumberOfSMS = Format(SMS.GetNumberOfSegments(Object.SMSTextDe), "ND=10; NFD=0; NG=");
		Items.SMSTextDe.Visible = True;
		Items.HTMLTextDe.Visible = True;
	EndIf;	
EndProcedure // Refresh

// -----------------------------------------------------------------------------
&AtServer
Procedure SetHTMLViewer(pLanguage)	
	HTMLViewer = GetHTMLText(pLanguage);
EndProcedure // SetHTMLViewer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillHTMLText(pLanguage)
	vTextHTML = "";
	vAttachments = New Structure();
	HTMLEditor.GetHTML(vTextHTML, vAttachments);
	For Each vRow In vAttachments Do    
		vTextHTML = StrReplace(vTextHTML, vRow.Key, EMail.GetPictureIsBase64HTMLString(vRow.Value));	
	EndDo;
	If pLanguage = Catalogs.Languages.RU Then
		Object.HTMLTextRu = StrReplace(vTextHTML, "&amp;","&");
	ElsIf pLanguage = Catalogs.Languages.EN Then
		Object.HTMLTextEn = StrReplace(vTextHTML, "&amp;","&");
	ElsIf pLanguage = Catalogs.Languages.DE Then
		Object.HTMLTextDe = StrReplace(vTextHTML, "&amp;","&");
	EndIf;
EndProcedure // FillHTMLText

// -----------------------------------------------------------------------------
&AtServer
Procedure SetHTMLText(pLanguage) 
	HTMLEditor.SetHTML(GetHTMLText(pLanguage), New Structure());
EndProcedure // SetHTMLText

// -----------------------------------------------------------------------------
&AtServer
Function GetHTMLText(pLanguage)
	If pLanguage = Catalogs.Languages.RU Then
		Return Object.HTMLTextRu;	
	ElsIf pLanguage = Catalogs.Languages.EN Then
		Return Object.HTMLTextEn;	
	ElsIf pLanguage = Catalogs.Languages.DE Then
		Return Object.HTMLTextDe;	
	EndIf;	
EndFunction // GetHTMLText

// -----------------------------------------------------------------------------
&AtServer
Procedure ActionInsertAutoTextHTMLAtServer(pText)
	HTMLEditor.Add(pText, Type("FormattedDocumentText"));
EndProcedure // ActionInsertAutoTextHTMLAtServer

// -----------------------------------------------------------------------------
&AtClient
Function GetAutoTextItem()
	vKWList = New Valuelist();
	
	vKWList.Add("&Dear", NStr("en='<Dear>'; ru='<Уважаемый(ая)>'; de='<Lieber>'"));
	vKWList.Add("&FirstName", NStr("en='<Client first name>'; ru='<Имя клиента>'; de='<Kunde Name>'"));
	vKWList.Add("&LastName", NStr("en='<Client last name>'; ru='<Фамилия клиента>'; de='<Kunde Nachname>'"));
	vKWList.Add("&SecondName", NStr("en='<Client second name>'; ru='<Отчество клиента>'; de='<Kunde zweiter Vorname>'"));
	vKWList.Add("&CheckInDate", NStr("en='<Check-in date>'; ru='<Дата заезда>'; de='<Anreise datum>'"));
	vKWList.Add("&CheckOutDate", NStr("en='<Check-out date>'; ru='<Дата выезда>'; de='<Abreise datum>'"));
	vKWList.Add("&Duration", NStr("en='<Duration of stay>'; ru='<Продолжительность проживания>'; de='<Aufenthaltsdauer>'"));
	vKWList.Add("&Room", NStr("en='<Room number>'; ru='<Номер комнаты>'; de='<Zimmernummer>'"));
	vKWList.Add("&RoomType", NStr("en='<Room type>'; ru='<Тип номера>'; de='<Zimmertyp>'"));
	vKWList.Add("&RoomClass", NStr("en='<Room class>'; ru='<Класс номера>'; de='<Zimmerklasse>'"));
	vKWList.Add("&WindowView", NStr("en='<Window view>'; ru='<Вид из окна>'; de='<Fensteransicht>'"));
	vKWList.Add("&Resource", NStr("en='<Resource>'; ru='<Ресурс>'; de='<Ressource>'"));
	vKWList.Add("&ResourceType", NStr("en='<Resource type>'; ru='<Тип ресурса>'; de='<Ressourcetyp>'"));
	vKWList.Add("&Service", NStr("en='<Service>'; ru='<Услуга>'; de='<Service>'"));
	vKWList.Add("&GuestGroup", NStr("en='<Guest group number>'; ru='<Номер группы>'; de='<Gastgruppennummer>'"));
	vKWList.Add("&ReservationNumber", NStr("en='<Reservation number>'; ru='<Индивидуальный номер брони>'; de='<Reservierungsnummer>'"));
	vKWList.Add("&HotelName", NStr("en='<Hotel name>'; ru='<Наименование отеля>'; de='<Hotelname>'"));
	vKWList.Add("&PaymentAmount", NStr("en='<Payment amount>'; ru='<Сумма платежа>'; de='<Zahlungsbetrag>'"));
	vKWList.Add("&GuestUUID", NStr("en='<Client ID in ""My folio"" system>'; ru='<ID клиента в системе ""Мой счет"">'; de='<Kunde ID in ""My Folio"" System>'"));
	vKWList.Add("&HotelUUID", NStr("en='<Hotel ID in ""My folio"" system>'; ru='<ID отеля в системе ""Мой счет"">'; de='<Hotel ID in ""My Folio"" System>'"));
	vKWList.Add("&FolioBalance", NStr("en='<Client folios balance>'; ru='<Баланс по лицевым счетам клиента>'; de='<Kunde Foliosaldo>'"));
	vKWList.Add("&GroupTotalAmount", NStr("en='<Group total charging amount>'; ru='<Сумма всех начислений по группе клиента>'; de='<Total summe für die Kundegruppe>'"));
	vKWList.Add("&ReservationUUID", NStr("de = '<Reservierung ID>'; en = '<Reservation ID>'; ru = '<ID брони>'"));
	vKWList.Add("&GuestReservationLink", NStr("de = '<Reservierung link>'; en = '<Reservation link for a guest>'; ru = '<Ссылка на бронь для гостя>'"));
    vKWList.Add("&GuestRegistrationLink", NStr("de = '<Registrierungslink für einen Gast>'; en = '<Registration link for a guest>'; ru = '<Ссылка на регистрацию для гостя>'"));
	vKWList.Add("&GuestHotel365Link", NStr("de = '<Folio-Link für einen Gast>'; en = '<Folio link for a guest>'; ru = '<Ссылка на фолио для гостя>'"));
	vKWList.Add("&CardID", NStr("en = '<Card ID>'; de = '<Karte ID>'; ru = '<ID Карты>'"));
    vKWList.Add("&DiscountCardBalance", NStr("en = '<Discount card balance>'; de = '<Rabattkartenguthaben>'; ru = '<Баланс дисконтной карты>'"));
    vKWList.Add("&BonusesOperationAmount", NStr("en = '<Amount of discount card transaction>'; de = '<Betrag der Rabattkartentransaktion>'; ru = '<Сумма операции дисконтной карты>'"));
    vKWList.Add("&WalletURL", NStr("en = '<Wallet URL>'; de = '<Wallet URL>'; ru = '<Wallet URL>'"));
	vKWList.Add("&ProformaInvoiceLink", NStr("de = '<Proforma-Rechnung zahlung link>'; en = '<Proforma invoice payment link>'; ru = '<Ссылка на оплату счета>'"));   
	vKWList.Add("&EmployeeFirstName", NStr("en='<Employee.FirstName>'; ru='<Сотрудник.Имя>'; de='<Employee.FirstName>'"));
	vKWList.Add("&EmployeeSecondName", NStr("en='<Employee.SecondName>'; ru='<Сотрудник.Отчество>'; de='<Employee.SecondName>'"));
	vKWList.Add("&EmployeeLastName", NStr("en='<Employee.LastName>'; ru='<Сотрудник.Фамилия>'; de='<Employee.LastName>'"));
	vKWList.Add("&EmployeeFullName", NStr("en='<Employee.FullName>'; ru='<Сотрудник.ФИО>'; de='<Employee.FullName>'"));
	vKWList.Add("&EmployeeDepartment", NStr("en='<Employee.Department>'; ru='<Сотрудник.Отдел>'; de='<Employee.Department>'"));
	vKWList.Add("&EmployeePosition", NStr("en='<Employee.Position>'; ru='<Сотрудник.Должность>'; de='<Employee.Position>'"));
	vKWList.Add("&AgentEmail", NStr("en = '<Agent.Email>'; de = '<Agent.Email>'; ru = '<Агент.Email>'")); 
	vKWList.Add("&AgentCode", NStr("en = '<Agent.Token>'; de = '<Agent.Zeichen>'; ru = '<Агент.Token>'"));
	vKWList.Add("&AgentContractNumber", NStr("en = '<Agent.Contract number>'; de = '<Agent.Vertragsnummer>'; ru = '<Агент.Номер договора>'"));
	vKWList.Add("&AgentContractDesc", NStr("en = '<Agent.Contract description>'; de = '<Agent.Name des Vertrags>'; ru = '<Агент.Наименование договора>'"));
	vKWList.Add("&AgentCustomerDesc", NStr("en = '<Agent.Description>'; de = '<Agent.Name>'; ru = '<Агент.Наименование>'"));
	vKWList.Add("&AgentRegLink", NStr("en = '<Agent.Registration link>'; de = '<Agent.Registrierungslink>'; ru = '<Агент.Ссылка на регистрацию>'"));
	vKWList.Add("&AgentAuthLink", NStr("en = '<Agent.Link for booking>'; de = '<Agent.Link zur Buchung>'; ru = '<Агент.Ссылка для бронирования>'"));  
		
	Return vKWList;
EndFunction // GetAutoTextItem

// -----------------------------------------------------------------------------
&AtServer
Procedure SetPicture(pSelectionBound, pPicture)
	HTMLEditor.Insert(pSelectionBound, pPicture, Type("FormattedDocumentPicture"));
EndProcedure // SetPicture

// -----------------------------------------------------------------------------
&AtClient
Procedure SetImageToFormattedDocument(pFileArray, pParam) Export 
	If ValueIsFilled(pFileArray) Then
		vStart = Undefined;
		vEnd = Undefined;
		Items.HTMLEditor.GetTextSelectionBounds(vStart, vEnd);
		SetPicture(vStart, New Picture(pFileArray[0]));
	EndIf;
EndProcedure // SetImageToFormattedDocument

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterActionInsertAutoTextSMS(pItem, pExtraParams) Export 
	If pItem <> Undefined Then
		If SelLanguage = PredefinedValue("Catalog.Languages.RU") Then
			ActionInsertAutoTextSMSAtServer(pItem.Value, "SMSTextRu");
		ElsIf SelLanguage = PredefinedValue("Catalog.Languages.EN") Then 
			ActionInsertAutoTextSMSAtServer(pItem.Value, "SMSTextEn");
		ElsIf SelLanguage = PredefinedValue("Catalog.Languages.DE") Then
			 ActionInsertAutoTextSMSAtServer(pItem.Value, "SMSTextDe");
		EndIf;
	EndIf;
EndProcedure // AfterActionInsertAutoTextSMS

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterActionInsertAutoTextHTML(pItem, pExtraParams) Export  
	If pItem <> Undefined Then
		ActionInsertAutoTextHTMLAtServer("&" + pItem.Value);
	EndIf;
EndProcedure // AfterActionInsertAutoTextHTML

#EndRegion
