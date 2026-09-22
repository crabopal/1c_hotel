
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Save current user
	CurrentUser = SessionParameters.CurrentUser;
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	If Parameters.Property("ExtraService") And TypeOf(Parameters.ExtraService) = TypeOf(Documents.ProformaInvoice.EmptyRef()) Then    
		CalcExtraInvoiceServices();
	ElsIf Parameters.Property("Refill") Then
		vObj = FormAttributeToValue("Object"); 
		vObj.Fill(Parameters.Basis);  
		ValueToFormAttribute(vObj, "Object");
	EndIf;
	
	// Fill folio for payment
	FillPaymentFolio();
	
	If Parameters.Property("PrintOnOpen") Then
		PrintOnOpen = Parameters.PrintOnOpen;
	EndIf;
	If Parameters.Property("PrintFormLanguage") Then
		PrintFormLanguage = Parameters.PrintFormLanguage;
	EndIf;
	
	// User rights to open item
	If Not IsInRole("RightsToChooseHotel") Then
		If ValueIsFilled(Object.Hotel) And SessionParameters.CurrentHotel <> Object.Hotel Then
			pCancel = True;
		EndIf;
	EndIf;
	
	// User rights to edit item
	If Object.Posted Then
		If ValueIsFilled(Object.Hotel) And Object.Hotel.PaymentsGenerateInvoices Then
			If Not cmCheckUserPermissions("HavePermissionToEditPostedFolioTransactions") Then
				If PaymentsAmountByProforma() <> 0 Then
					ReadOnly = True;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If ReadOnly Then
		Items.ServicesRecalculateServices.Visible = False;
		Items.ServicesRecalculateServices.Enabled = False;
		Items.FormSetDeletionMark.Visible = False;
		Items.FormSetDeletionMark.Enabled = False;
		Items.FormPostAndClose.Visible = False;
		Items.FormPostAndClose.Enabled = False;
	EndIf;
	FillPrintingButton();
	
	ShowButtonGetPaid = ?(Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsGuestlink(Object.Hotel) <> Undefined, True, False);
	If Not ShowButtonGetPaid Then
		ShowButtonGetPaid = ?(Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsHotel365(Object.Hotel) <> Undefined, True, False);
	EndIF;
	If ValueIsFilled(Object.Ref) And Object.Posted Then
		Items.GetPaid.Visible = ShowButtonGetPaid; 	
	EndIf;
	
	// Fill mode conversion
	If Not ReadOnly Then
		If Not ValueIsFilled(Object.FillProformaInvoiceMode) And ValueIsFilled(Object.Hotel) And Object.Hotel.ProformaInvoicesFillServicesInDetail Then
			Object.FillProformaInvoiceMode = Enums.FillProformaInvoiceModes.InDetails;
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	// Check if we have to open print form instead of opening the document
	If PrintOnOpen Then
		vPrintForm = tcOnServer.GetProformaInvoiceDefaultPrintForm(PrintFormLanguage);
		If ValueIsFilled(vPrintForm) Then
			OpenForm("Document.ProformaInvoice.Form.tcInvoicePrintForm", New Structure("Invoice, Language, PrintForm", Object.Ref, PrintFormLanguage, vPrintForm), , Object.Ref);
			pCancel = True;
			Return;
		EndIf;
	EndIf;
	// Normal processing
	WasAlreadyPrint = False;
	PrintFormPresentationCommissionSum = 0;
	PrintFormPresentationSum = 0;
	OnOpenForm();
EndProcedure // OnOpen

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeClose(pCancel, pExit, pMessageText, pStandardProcessing)
	If IsNew And WasPosted And Not WasAlreadyPrint Then
		vPrintFormsList = PerformAutomaticPrinting();
		For Each vFormType In vPrintFormsList Do
			If ValueIsFilled(vFormType.Presentation) Then
				vFormTypeRef = tcOnServer.cmGetAtributeAsArray(vFormType.Value);
				If ValueIsFilled(vFormTypeRef.ExternalProcessing) Then 
					Try
						OpenExternalProcedureForm(vFormTypeRef.ExternalProcessing, vFormTypeRef.Ref);
					Except
						tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'"), MessageStatus.Attention);
					EndTry;
				ElsIf ValueIsFilled(vFormTypeRef.Report) Then
					Try
						OpenExternalReportForm(vFormTypeRef.Report, vFormTypeRef.Ref);
					Except
						tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'"), MessageStatus.Attention);
					EndTry;
				ElsIf vFormType.Presentation = "PrintInvoiceForm" Then
					vParams = New Structure();
					vParams.Insert("Invoice", Object.Ref);
					vParams.Insert("GroupBy", GetPrintGroupBy(vFormType.Presentation, tcOnServer.cmGetAttributeByRef(vFormType.Value,"PredefinedDataName")));
					vParams.Insert("Language", tcOnServer.cmGetAttributeByRef(vFormType.Value,"Language"));
					vParams.Insert("PrintForm", vFormType.Value);
					OpenForm("Document.ProformaInvoice.Form.tcInvoicePrintForm", vParams, ThisObject);
				ElsIf vFormType.Presentation = "PrintInvoiceShortForm" Then
					vParams = New Structure();
					vParams.Insert("Invoice", Object.Ref);
					vParams.Insert("GroupBy", GetPrintGroupBy(vFormType.Presentation, tcOnServer.cmGetAttributeByRef(vFormType.Value,"PredefinedDataName")));
					vParams.Insert("Language", tcOnServer.cmGetAttributeByRef(vFormType.Value,"Language"));
					vParams.Insert("PrintForm", vFormType.Value);
					OpenForm("Document.ProformaInvoice.Form.tcInvoicePrintShortForm", vParams, ThisObject);
				ElsIf vFormType.Presentation = "PrintInvoiceHotelProductsForm" Then
					vParams = New Structure();
					vParams.Insert("Invoice", Object.Ref);
					vParams.Insert("GroupBy", GetPrintGroupBy(vFormType.Presentation, tcOnServer.cmGetAttributeByRef(vFormType.Value,"PredefinedDataName")));
					vParams.Insert("Language", tcOnServer.cmGetAttributeByRef(vFormType.Value,"Language"));
					vParams.Insert("PrintForm", vFormType.Value);
					OpenForm("Document.ProformaInvoice.Form.tcInvoicePrintHotelProductsForm", vParams, ThisObject);
				ElsIf vFormType.Presentation = "PrintPaymentOrder" Then
					vParams = New Structure();
					vParams.Insert("Invoice", Object.Ref);
					vParams.Insert("Language", tcOnServer.cmGetAttributeByRef(vFormType.Value,"Language"));
					vParams.Insert("PrintForm", vFormType.Value);
					OpenForm("Document.ProformaInvoice.Form.tcPaymentOrderForm", vParams, ThisObject);  
				ElsIf vFormType.Presentation = "PrintInvoiceSimpleForm" Then
					vParams = New Structure();
					vParams.Insert("Invoice", Object.Ref);
					vParams.Insert("Language", tcOnServer.cmGetAttributeByRef(vFormType.Value,"Language"));
					vParams.Insert("PrintForm", vFormType.Value);
					OpenForm("Document.ProformaInvoice.Form.tcInvoicePrintSimpleForm", vParams, ThisObject);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // BeforeClose

// -----------------------------------------------------------------------------
&AtClient
Procedure OnClose(pExit)
	If Not pExit Then
		OnCloseAtServer();
	EndIf;
EndProcedure // OnClose

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "SessionParameters.CurrentUser.Change" Then
		EmployeePINCodeChecked = True;
		If Not ValueIsFilled(Object.Ref) Then
			Object.Author = tcOnServer.cmGetSessionParametersAttribute("CurrentUser");
		EndIf;
		If pParameter.ModeAfterCheck = "BeforeWrite" Then
			If Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
				Close();
			EndIf;
		EndIf;
	ElsIf pEventName = "Document.Proformainvoice.Write" And Object.Ref = pParameter Then
		Read();
	ElsIf pEventName = "CommonForm.tcSendMail.Send" And pSource = Object.Ref Then
		If ValueIsFilled(pParameter) And Not ValueIsFilled(Object.EMail) Then 
			Object.EMail = pParameter; 	
		EndIf;
	EndIf;
EndProcedure // NotificationProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	ClearMessages();
	
	vMessage = ""; 
	If pWriteParameters.WriteMode = DocumentWriteMode.Posting Then
		// Check document attributes
		If Not CheckDocumentAttributesAtServer(vMessage) Then
			pCancel = True;
			tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"),,,,tcOnServer.cmNStrAtServer(vMessage));
			Return;
		EndIf;
		vMessage = "";
		// Check user PIN if necessary
		If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
			OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "BeforeWrite"), ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
			pCancel = True;
			Return;
		EndIf;
		EmployeePINCodeChecked = False;
	EndIf;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	// Notify changes in the accounts subsystem
	Notify("Subsystem.Accounts.Changed", Object.Ref);
	If (FormOwner <> Undefined) And (TypeOf(FormOwner)=Type("ClientApplicationForm")) And FormOwner.UniqueKey = "8b37f7cc-8096-44e2-a045-87fa9bedd28d" Then
		FormOwner.PutData();
	EndIf;
	WasPosted = True;
EndProcedure // AfterWrite

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesPriceOnChange(pItem)
	vCurRow = pItem.Parent.CurrentData;
	If Not ValueIsFilled(vCurRow.Quantity) Then 		
		vCurRow.Quantity = 1;
	EndIf;
	vCurRow.Sum = vCurRow.Quantity*pItem.EditText;
	Object.Sum = Object.Services.Total("Sum");
	vCurRow.VATSum = CalculateVATSum(vCurRow.VATRate, vCurRow.Sum, vCurRow.AccountingDate);
	Object.VATSum = Object.Services.Total("VATSum");
EndProcedure // ServicesPriceOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesSumOnChange(pItem)
	vCurRow = pItem.Parent.CurrentData;
	vCurRow.Price = pItem.EditText/vCurRow.Quantity;
	Object.Sum = Object.Services.Total("Sum");
	vCurRow.VATSum = CalculateVATSum(vCurRow.VATRate, vCurRow.Sum, vCurRow.AccountingDate);
	Object.VATSum = Object.Services.Total("VATSum");
EndProcedure // ServicesSumOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesQuantityOnChange(pItem)
	vCurRow = pItem.Parent.CurrentData;
	vCurRow.Sum = pItem.EditText*vCurRow.Price;
	Object.Sum = Object.Services.Total("Sum");
	vCurRow.VATSum = CalculateVATSum(vCurRow.VATRate, vCurRow.Sum, vCurRow.AccountingDate);
	Object.VATSum = Object.Services.Total("VATSum");
	If Not ValueIsFilled(pItem.EditText) Then
		vCurRow.Price = "";
	EndIf;
EndProcedure // ServicesQuantityOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesVATRateOnChange(pItem)
	vCurRow = pItem.Parent.CurrentData;
	vCurRow.VATSum = CalculateVATSum(vCurRow.VATRate, vCurRow.Sum, vCurRow.AccountingDate);
	Object.VATSum = Object.Services.Total("VATSum");
EndProcedure // ServicesVATRateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure BankAccountOnChange(pItem)
	BankAccountOnChangeAtServer();
EndProcedure // BankAccountOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AccountingCurrencyOnChange(pItem)
	AccountingCurrencyOnChangeAtServer();
EndProcedure // AccountingCurrencyOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ExchangeRateDateOnChange(pItem)
	ExchangeRateDateOnChangeAtServer();
EndProcedure // ExchangeRateDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AccountingCurrencyExchangeRateOnChange(pItem)
	AccountingCurrencyExchangeRateOnChangeAtServer();
EndProcedure // AccountingCurrencyExchangeRateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CompanyOnChange(pItem)
	CompanyOnChangeAtServer();
EndProcedure // CompanyOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DateOnChange(pItem)
	DateOnChangeAtServer();
EndProcedure // DateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AccountingCustomerOnChange(pItem)
	AccountingCustomerOnChangeAtServer();
EndProcedure // AccountingCustomerOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AccountingContractOnChange(pItem)
	RecalculateServicesAtServer();
EndProcedure // AccountingContractOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupOnChange(pItem)
	RecalculateServicesAtServer();
EndProcedure // GuestGroupOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesServiceOnChange(pItem)
	vCurRow = pItem.Parent.CurrentData;
	If ValueIsFilled(vCurRow.Service) And ValueIsFilled(Object.AccountingCustomer) Then 		
		vCurRow.Remarks = ServicesServiceOnChangeAtServer(vCurRow.Service, Object.AccountingCustomer);
	EndIf;
EndProcedure // ServicesServiceOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesAfterDeleteRow(pItem)
	vObj = Object;
	// Recalculate totals
	CalculateTotals(vObj);
EndProcedure // ServicesAfterDeleteRow

// -----------------------------------------------------------------------------
&AtClient
Procedure FillProformaInvoiceModeOnChange(pItem)
	If Object.Services.Count() > 0 Then
		ShowQueryBox(New NotifyDescription("RecalculateServicesConfirmation", ThisObject), 
		                                   NStr("en='Refill proforma invoice services?'; 
										        |ru='Перезаполнить услуги счета на оплату?'; 
												|de='Proforma Rechnung neu ausfüllen?'"), 
										   QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
	Else
		RecalculateServicesAtServer();
	EndIf;
EndProcedure // FillProformaInvoiceModeOnChange

#EndRegion

#Region FormTableItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesClientChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	pStandardProcessing = False;
	Items.Services.CurrentData.Client = pSelectedValue;
EndProcedure // ServicesClientChoiceProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesBeforeEditEnd(pItem, pNewRow, pCancelEdit, pCancel)
	vCurRow = Items.Services.CurrentData;
	If Not ValueIsFilled(vCurRow.VATRate) Then
		pCancel = True;
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='VAT rate should be filled!'; ru='Нужно указать ставку НДС!'; de='Sie müssen den Mehrwertsteuersatz angeben!'"));
	EndIf;
EndProcedure // ServicesBeforeEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesOnEditEnd(pItem, pNewRow, pCancelEdit)
	// Recalculate totals
	vObj = Object;
	CalculateTotals(vObj);
EndProcedure // ServicesOnEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.GuestGroups.ChoiceForm",, pItem,,,, New NotifyDescription("AfterGuestGroupStartChoice", ThisObject, New Structure("Item", pItem)), FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // GuestGroupStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	If pSelectedRow <> Undefined Then
		If pField.Name = "ServicesParentDoc" Then
			vRowData = Items.Services.RowData(pSelectedRow);
			If vRowData <> Undefined And ValueIsFilled(vRowData.ParentDoc) Then
				pStandardProcessing = False;
				ShowValue(, vRowData.ParentDoc);
			EndIf;
		ElsIf pField.Name = "ServicesGuestGroup" Then
			vRowData = Items.Services.RowData(pSelectedRow);
			If vRowData <> Undefined And ValueIsFilled(vRowData.GuestGroup) Then
				pStandardProcessing = False;
				ShowValue(, vRowData.GuestGroup);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ServicesSelection

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintButtonClick(pCommand)
	// Save document first
	If Not ValueIsFilled(Object.Ref) Or Modified Then
		If Not Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
			Return;
		EndIf;
	EndIf;
	// Choose processing type
	vPrintNumber = StrReplace(pCommand.Name,"Print","");
	vPrintForm = GetPrintFormForNumber(vPrintNumber);
	// Load external print form
	If ValueIsFilled(vPrintForm.ExternalProcessing) Then 
		Try
			OpenExternalProcedureForm(vPrintForm.ExternalProcessing, vPrintForm.Ref);
		Except
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'"), MessageStatus.Attention);
		EndTry;
	ElsIf ValueIsFilled(vPrintForm.Report) Then
		Try
			OpenExternalReportForm(vPrintForm.Report, vPrintForm.Ref);
		Except
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'"), MessageStatus.Attention);
		EndTry;
	ElsIf Left(vPrintForm.PredefinedDataName, 19) = "InvoicePrintInvoice" Then
		vParams = New Structure();
		vParams.Insert("Invoice", Object.Ref);
		vParams.Insert("GroupBy", GetPrintGroupBy("PrintInvoiceForm", vPrintForm.PredefinedDataName));
		vParams.Insert("Language", vPrintForm.Language);
		vParams.Insert("PrintForm", vPrintForm.Ref);
		OpenForm("Document.ProformaInvoice.Form.tcInvoicePrintForm", vParams, ThisObject);
	ElsIf Left(vPrintForm.PredefinedDataName, 24) = "InvoicePrintShortInvoice" Then
		vParams = New Structure();
		vParams.Insert("Invoice", Object.Ref);
		vParams.Insert("GroupBy", GetPrintGroupBy("PrintInvoiceShortForm", vPrintForm.PredefinedDataName));
		vParams.Insert("Language", vPrintForm.Language);
		vParams.Insert("PrintForm", vPrintForm.Ref);
		OpenForm("Document.ProformaInvoice.Form.tcInvoicePrintShortForm", vParams, ThisObject);
	ElsIf Left(vPrintForm.PredefinedDataName, 25) = "InvoicePrintHotelProducts" Then
		vParams = New Structure();
		vParams.Insert("Invoice", Object.Ref);
		vParams.Insert("GroupBy", GetPrintGroupBy("PrintInvoiceHotelProductsForm", vPrintForm.PredefinedDataName));
		vParams.Insert("Language", vPrintForm.Language);
		vParams.Insert("PrintForm", vPrintForm.Ref);
		OpenForm("Document.ProformaInvoice.Form.tcInvoicePrintHotelProductsForm", vParams, ThisObject);
	ElsIf vPrintForm.PredefinedDataName = "InvoicePrintPaymentOrder" Then
		vParams = New Structure();
		vParams.Insert("Invoice", Object.Ref);
		vParams.Insert("Language", vPrintForm.Language);
		vParams.Insert("PrintForm", vPrintForm.Ref);
		OpenForm("Document.ProformaInvoice.Form.tcPaymentOrderForm", vParams, ThisObject);  
	ElsIf Left(vPrintForm.PredefinedDataName, 25) = "InvoicePrintSimpleInvoice" Then
		vParams = New Structure();
		vParams.Insert("Invoice", Object.Ref);    
		vParams.Insert("GroupBy", GetPrintGroupBy("PrintInvoiceSimpleForm", vPrintForm.PredefinedDataName));
		vParams.Insert("Language", vPrintForm.Language);
		vParams.Insert("PrintForm", vPrintForm.Ref);
		OpenForm("Document.ProformaInvoice.Form.tcInvoicePrintSimpleForm", vParams, ThisObject);
	EndIf;
EndProcedure // PrintButtonClick

// -----------------------------------------------------------------------------
&AtClient
Procedure RecalculateServices(pCommand)
	RecalculateServicesAtServer();
EndProcedure // RecalculateServices

// -----------------------------------------------------------------------------
&AtClient
Procedure CreatePayment(pCommand)
	If Modified Then
		If Not Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
			Return;
		EndIf;
	EndIf;
	If ValueIsFilled(Object.Ref) Then
		OpenForm("Document.CustomerPayment.ObjectForm", New Structure("Basis", Object.Ref), , Object.Ref);
		Close();
	EndIf;
EndProcedure // CreatePayment

// -----------------------------------------------------------------------------
&AtClient
Procedure GroupByServicesButton(pCommand)
	// Ask for group by mode
	vUserChoices = New ValueList();
	vUserChoices.Add(1, NStr("en='Group by to the one selected service';ru='Свернуть в одну выбранную (выделенную в таблице счета) услугу';de='Zu einer ausgewählten Dienstleistung verkleinern'"));
	vUserChoices.Add(2, NStr("en='Group by Service, Remarks, Price, VAT Rate';ru='Свернуть по Услуге, Примечаниям, Цене, Ставке НДС';de='Gruppe von Service, Bemerkungen, Preis, MwSt. bewerten'"));
	vUserChoices.Add(3, NStr("en='Group by Service, Remarks, Price, VAT Rate, Period, Reservation conditions';ru='Свернуть по Услуге, Примечаниям, Цене, Ставке НДС, Периоду бронирования, Условиям бронирования';de='Gruppe von Service, Bemerkungen, Preis, MwSt., die Zeit der Reservierung, Buchung Bedingungen bewerten'"));
	ShowChooseFromMenu(New NotifyDescription("AfterChoiceGroupByMode", ThisObject), vUserChoices, Items.ServicesCommandBar);
EndProcedure // GroupByServicesButton

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure CalcExtraInvoiceServices()
	vObject = FormAttributeToValue("Object");   
	vNewInvServices = vObject.Services.Unload();
	For Each vExistingInvoicesServicesRow In Parameters.ExtraService.Services Do
		vNewInvServicesRow = vNewInvServices.Add();
		FillPropertyValues(vNewInvServicesRow, vExistingInvoicesServicesRow, , "LineNumber");
		vNewInvServicesRow.Quantity = -vNewInvServicesRow.Quantity;
		vNewInvServicesRow.Sum = -vNewInvServicesRow.Sum;
		vNewInvServicesRow.VATSum = -vNewInvServicesRow.VATSum;
		vNewInvServicesRow.DiscountSum = -vNewInvServicesRow.DiscountSum;
		vNewInvServicesRow.CommissionSum = -vNewInvServicesRow.CommissionSum;
		vNewInvServicesRow.VATCommissionSum = -vNewInvServicesRow.VATCommissionSum;
		vNewInvServicesRow.NumberOfPersons = -vNewInvServicesRow.NumberOfPersons;
		vNewInvServicesRow.RoomQuantity = -vNewInvServicesRow.RoomQuantity;
	EndDo;
	vNewInvServices.GroupBy("AccountingDate, Service, Price, Unit, VATRate, Remarks, Client, AccommodationType, RoomType, Room, Resource, IsInPrice, IsRoomRevenue, IsResourceRevenue, DateTimeFrom, DateTimeTo, CalendarDayType, Discount, HotelProduct, Agent, AgentCommissionType, AgentCommission, GuestGroup", "Quantity, Sum, VATSum, NumberOfPersons, RoomQuantity, DiscountSum, CommissionSum, VATCommissionSum");
	vMinusIsFound = False;
	i = 0;
	While i < vNewInvServices.Count() Do
		vNewInvServicesRow = vNewInvServices.Get(i);
		If vNewInvServicesRow.Quantity < 0 Then  
			vMinusIsFound = True;
		ElsIf vNewInvServicesRow.Quantity = 0 And vNewInvServicesRow.Sum = 0 Then
			vNewInvServices.Delete(i);
			Continue;
		EndIf;
		i = i + 1;
	EndDo;
	If vMinusIsFound Then
		FillExtraInvoiceServices(vObject, vNewInvServices);
	Else
		vObject.Services.Load(vNewInvServices);
	EndIf;
	vObject.ExtraInvoice = True;
	ValueToFormAttribute(vObject, "Object");
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillExtraInvoiceServices(pInvObj, pExtraServices)
	vAccommodationService = Undefined;
	For Each pServicesRow In pExtraServices Do
		If pServicesRow.IsRoomRevenue And pServicesRow.IsInPrice Then
			vAccommodationService = pServicesRow.Service;
			Break;
		EndIf;
	EndDo;
	pExtraServices.FillValues(vAccommodationService, "Service");
	pExtraServices.FillValues(0, "Price");
	pExtraServices.FillValues(0, "Quantity");
	pExtraServices.GroupBy("Service, VATRate", "Quantity, Price, Sum, VATSum, DiscountSum, CommissionSum, VATCommissionSum");
	pInvObj.Services.Load(pExtraServices);
	For Each vServicesRow In pInvObj.Services Do
		If ValueIsFilled(pInvObj.GuestGroup) Then
			vServicesRow.Remarks = cmNStr("en='Extra charge by guest group N';ru='Доплата по группе N';de='Zuzahlung nach Gruppe N'", ?(ValueIsFilled(pInvObj.AccountingCustomer), pInvObj.AccountingCustomer.Language, Catalogs.Languages.RU)) + Format(pInvObj.GuestGroup.Code, "ND=12; NFD=0; NG=");
		ElsIf ValueIsFilled(pInvObj.AccountingContract) Then
			vServicesRow.Remarks = cmNStr("en='Extra charge by contract ';ru='Доплата по договору ';de='Zuzahlung nach Vertrag '", ?(ValueIsFilled(pInvObj.AccountingCustomer), pInvObj.AccountingCustomer.Language, Catalogs.Languages.RU)) + TrimAll(pInvObj.AccountingContract);
		Else
			vServicesRow.Remarks = cmNStr("en='Extra charge';ru='Доплата';de='Zuzahlung'", ?(ValueIsFilled(pInvObj.AccountingCustomer), pInvObj.AccountingCustomer.Language, Catalogs.Languages.RU));
		EndIf;
		vServicesRow.Price = vServicesRow.Sum;
		vServicesRow.Quantity = 1;
	EndDo;
EndProcedure // FillExtraInvoiceServices

// -----------------------------------------------------------------------------
&AtServer
Function CalculateVATSum(pVATRate, pSum, pDate = '00010101')
	vVATSum = 0;
	If ValueIsFilled(pVATRate) Then
		vTaxRate = cmGetVATTaxRate(pVATRate, pDate);
		vVATSum = Round(pSum*vTaxRate/(100+vTaxRate), 2);
	EndIf;
	Return vVATSum;
EndFunction // CalculateVATSum

// -----------------------------------------------------------------------------
&AtServer
Function PaymentsAmountByProforma()
	vPayments = 0;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	InvoiceAccountsTurnovers.Invoice AS Invoice,
	|	InvoiceAccountsTurnovers.SumExpense AS SumExpense
	|FROM
	|	AccumulationRegister.InvoiceAccounts.Turnovers(, , Period, Invoice = &qProformaInvoice) AS InvoiceAccountsTurnovers";
	vQry.SetParameter("qProformaInvoice", Object.Ref);
	vQryRes = vQry.Execute().Unload();
	If vQryRes.Count() > 0 Then
		vTrnRow = vQryRes.Get(0);
		If vTrnRow.SumExpense <> Null Then
			vPayments = vTrnRow.SumExpense;
		EndIf;
	EndIf;
	Return vPayments;
EndFunction // PaymentsAmountByProforma

// -----------------------------------------------------------------------------
&AtServer
Procedure FillPrintingButton()
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ObjectPrintingForms.Ref,
	|	ObjectPrintingForms.Code AS Code,
	|	ObjectPrintingForms.PredefinedDataName,
	|	ObjectPrintingForms.IsDefault AS IsDefault,
	|	ObjectPrintingForms.Language AS Language
	|FROM
	|	Catalog.ObjectPrintingForms AS ObjectPrintingForms
	|WHERE
	|	NOT ObjectPrintingForms.DeletionMark
	|	AND ObjectPrintingForms.IsActive = TRUE
	|	AND ObjectPrintingForms.ObjectType = &ObjectType
	|
	|ORDER BY
	|	IsDefault DESC,
	|	Code
	|TOTALS BY
	|	Language";
	
	Query.SetParameter("ObjectType", Documents.ProformaInvoice.EmptyRef());	
	QueryResult = Query.Execute();	
	SelectionRecords = QueryResult.Select(QueryResultIteration.ByGroups);
	PrintForms.Clear();
	vLang = SessionParameters.CurrentLanguage;
	While SelectionRecords.Next() Do
		SelectionDetailRecords = SelectionRecords.Select(QueryResultIteration.ByGroups);
		
		If vLang = SelectionRecords.Language Or not ValueIsFilled(SelectionRecords.Language) Then
			vParentLang = Items.FormGroupPrintingNotDefaultMain;
		ElsIf Not vLang = SelectionRecords.Language Then
			vParentLang = tcOnServer.cmCreateItem(ThisObject, Items.FormGroupPrintingNotDefaultExtra, "Print" + SelectionRecords.Language, "FormGroup",
			New Structure("Type,Title",
			FormGroupType.Popup,SelectionRecords.Language));
		EndIf;
		
		While SelectionDetailRecords.Next() Do
			vNewRow = PrintForms.Add();
			vNewRow.PrintForm = SelectionDetailRecords.Ref;
			vNewRow.IsDefault = SelectionDetailRecords.IsDefault;
			
			vID = vNewRow.GetID();
			
			vCommand = Commands.Add("Print"+vID);
			vCommand.Action = "PrintButtonClick";
			If SelectionDetailRecords.IsDefault Then
				vParent = Items.FormGroupPrintingDefault;
			Else
				vParent = vParentLang;
			EndIf;
			vStructure = New Structure("Title,CommandName",
			TrimAll(SelectionDetailRecords.Code) + " " + cmNStr(SelectionDetailRecords.Ref), "Print" + vID);
			        
			tcOnServer.cmCreateItem(ThisObject, vParent, "Print" + vID, "FormButton", vStructure);
		EndDo;
	EndDo;
EndProcedure // FillPrintingButton

// -----------------------------------------------------------------------------
&AtServer
Function GetPrintFormForNumber(pActionsNumber)
	vPrintForms = PrintForms.FindByID(Number(pActionsNumber)).PrintForm;
	
	vStruct = New Structure();
	vStruct.Insert("Ref",vPrintForms);
	vStruct.Insert("PredefinedDataName",vPrintForms.PredefinedDataName);	
	vStruct.Insert("ExternalProcessing",vPrintForms.ExternalProcessing);
	vStruct.Insert("Report",vPrintForms.Report);
	vStruct.Insert("Language",vPrintForms.Language);
	
	Return vStruct;
EndFunction // GetPrintFormForNumber

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenExternalProcedureForm(pExtProcRef, pPrintFormTypeRef)
	#If ThickClientOrdinaryApplication Then
		vExtProcData = pExtProcRef.ExternalProcessingStorage.Get();
		vExtProcPath = GetTempFileName(".efd");
		vExtProcData.Write(vExtProcPath);
		vExtProcObj = ExternalDataProcessors.Create(vExtProcPath, False);
		vStruct = New Structure("InputParameter, ObjectPrintingForm", FormDataToValue(Object, Type("DocumentObject.Reservation")), pPrintFormTypeRef);
		FillPropertyValues(vExtProcObj, vStruct);
		vFrm = vExtProcObj.GetForm();
		vFrm.Open();
		BeginDeletingFiles(Undefined, vExtProcPath);
	#Else
		vURL = GetURL(pExtProcRef, "ExternalProcessingStorage");
		vName = ConnectExternalDataProcessor(vURL, GetExternalProcessingValidName(tcOnServer.cmGetAttributeByRef(pExtProcRef,"FileName")));
		vParams = New Structure("InputParameter, ObjectPrintingForm", Object.Ref, pPrintFormTypeRef);
		OpenForm("ExternalDataProcessor." + vName + ".Form", vParams);
	#EndIf
EndProcedure // OpenExternalProcedureForm

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenExternalReportForm(pExtRepRef, pPrintFormTypeRef)
	#If ThickClientOrdinaryApplication Then
		vExtRepData = pExtRepRef.ExternalProcessingStorage.Get();
		vExtRepPath = GetTempFileName(".erf");
		vExtRepData.Write(vExtRepPath);
		vExtRepObj = ExternalReports.Create(vExtRepPath, False);
		vStruct = New Structure("InputParameter, ObjectPrintingForm", FormDataToValue(Object, Type("DocumentObject.Accommodation")), pPrintFormTypeRef);
		FillPropertyValues(vExtRepObj, vStruct);
		// Fill reference to the report catalog item
		vExtRepObj.Report = pPrintFormTypeRef.Report;
		// Load report catalog item attributes
		vExtRepObj.pmLoadReportAttributes(Object.Ref);
		// Open report's default form
		vExtRepFrm = vExtRepObj.GetForm();
		vExtRepFrm.GenerateOnFormOpen = True;
		vExtRepFrm.Open();
		BeginDeletingFiles(New NotifyDescription, vExtRepPath);
	#Else
		ShowMessageBox(, NStr("en='Not supported in thin or web client mode!'; ru='Не поддерживается в режиме тонкого и WEB клиента!'; de='Nicht in Dünnen-Client-Modus oder Web-Client-Modus unterstützt!'"));
	#EndIf
EndProcedure // OpenExternalReportForm

// -----------------------------------------------------------------------------
&AtServer
Function ConnectExternalDataProcessor(pPath, pName = "", pUseSafeMode = False)
	Return ExternalDataProcessors.Connect(pPath, pName, pUseSafeMode);
EndFunction // ConnectExternalDataProcessor

// -----------------------------------------------------------------------------
&AtServer
Function GetExternalProcessingValidName(Val pStr)
	Return cmGetValidName(pStr); 	
EndFunction // GetExternalProcessingValidName

// -----------------------------------------------------------------------------
&AtServer
Function GetPrintGroupBy(pTypeOfPrintForm, pPredefinedDataName)
	vForm = Catalogs.ObjectPrintingForms;
	vGroupBy = "";
	If ValueIsFilled(pTypeOfPrintForm) Then
		If pTypeOfPrintForm = "PrintInvoiceForm" Then
			If pPredefinedDataName = "InvoicePrintInvoiceGroupInPricePerClientPerDayRu" Or
			   pPredefinedDataName = "InvoicePrintInvoiceGroupInPricePerClientPerDayEn" Or
			   pPredefinedDataName = "InvoicePrintInvoiceGroupInPricePerClientPerDayDe" Then
				vGroupBy = "InPricePerClientPerDay";
			ElsIf pPredefinedDataName = "InvoicePrintInvoiceGroupInPricePerDayRu" Or
			      pPredefinedDataName = "InvoicePrintInvoiceGroupInPricePerDayEn" Or
			      pPredefinedDataName = "InvoicePrintInvoiceGroupInPricePerDayDe" Then
				vGroupBy = "InPricePerDay";
			ElsIf pPredefinedDataName = "InvoicePrintInvoiceGroupPerClientRu" Or
			      pPredefinedDataName = "InvoicePrintInvoiceGroupPerClientEn" Or
			      pPredefinedDataName = "InvoicePrintInvoiceGroupPerClientDe" Then
				vGroupBy = "PerClient";
			ElsIf pPredefinedDataName = "InvoicePrintInvoiceGroupByServiceRu" Or
			      pPredefinedDataName = "InvoicePrintInvoiceGroupByServiceEn" Or
			      pPredefinedDataName = "InvoicePrintInvoiceGroupByServiceDe" Then
				vGroupBy = "ByService";
			ElsIf pPredefinedDataName = "InvoicePrintInvoiceGroupAllPerClientPerDayRu" Or
			      pPredefinedDataName = "InvoicePrintInvoiceGroupAllPerClientPerDayEn" Or
			      pPredefinedDataName = "InvoicePrintInvoiceGroupAllPerClientPerDayDe" Then
				vGroupBy = "AllPerClientPerDay";
			ElsIf pPredefinedDataName = "InvoicePrintInvoiceGroupAllPerDayRu" Or
			      pPredefinedDataName = "InvoicePrintInvoiceGroupAllPerDayEn" Or
			      pPredefinedDataName = "InvoicePrintInvoiceGroupAllPerDayDe" Then
				vGroupBy = "AllPerDay";
			ElsIf pPredefinedDataName = "InvoicePrintInvoiceGroupInPricePerClientRu" Or
			      pPredefinedDataName = "InvoicePrintInvoiceGroupInPricePerClientEn" Or
			      pPredefinedDataName = "InvoicePrintInvoiceGroupInPricePerClientDe" Then
				vGroupBy = "InPricePerClient";
			ElsIf pPredefinedDataName = "InvoicePrintInvoiceGroupInPriceRu" Or
			      pPredefinedDataName = "InvoicePrintInvoiceGroupInPriceEn" Or
			      pPredefinedDataName = "InvoicePrintInvoiceGroupInPriceDe" Then
				vGroupBy = "InPrice";
			ElsIf pPredefinedDataName = "InvoicePrintInvoiceGroupAllPerClientRu" Or
			      pPredefinedDataName = "InvoicePrintInvoiceGroupAllPerClientEn" Or
			      pPredefinedDataName = "InvoicePrintInvoiceGroupAllPerClientDe" Then
				vGroupBy = "AllPerClient";
			ElsIf pPredefinedDataName = "InvoicePrintInvoiceGroupAllRu" Or
			      pPredefinedDataName = "InvoicePrintInvoiceGroupAllEn" Or
			      pPredefinedDataName = "InvoicePrintInvoiceGroupAllDe" Then
				vGroupBy = "All";
			EndIf;
		ElsIf pTypeOfPrintForm = "PrintInvoiceShortForm" Then
			If pPredefinedDataName = "InvoicePrintShortInvoiceGroupInPriceRu" Or
			   pPredefinedDataName = "InvoicePrintShortInvoiceGroupInPriceEn" Or
			   pPredefinedDataName = "InvoicePrintShortInvoiceGroupInPriceDe" Then
				vGroupBy = "InPrice";
			ElsIf pPredefinedDataName = "InvoicePrintShortInvoiceGroupAllRu" Or
			      pPredefinedDataName = "InvoicePrintShortInvoiceGroupAllEn" Or
			      pPredefinedDataName = "InvoicePrintShortInvoiceGroupAllDe" Then
				vGroupBy = "All";
			ElsIf pPredefinedDataName = "InvoicePrintShortInvoiceGroupByServiceRu" Or
			      pPredefinedDataName = "InvoicePrintShortInvoiceGroupByServiceEn" Or
			      pPredefinedDataName = "InvoicePrintShortInvoiceGroupByServiceDe" Then
				vGroupBy = "ByService";
			EndIf;
		ElsIf pTypeOfPrintForm = "PrintInvoiceHotelProductsForm" Then
			If pPredefinedDataName = "InvoicePrintHotelProductsGroupInPriceRu" Or
			   pPredefinedDataName = "InvoicePrintHotelProductsGroupInPriceEn" Or
			   pPredefinedDataName = "InvoicePrintHotelProductsGroupInPriceDe" Then
				vGroupBy = "InPrice";
			ElsIf pPredefinedDataName = "InvoicePrintHotelProductsGroupAllRu" Or
			      pPredefinedDataName = "InvoicePrintHotelProductsGroupAllEn" Or
			      pPredefinedDataName = "InvoicePrintHotelProductsGroupAllDe" Then
				vGroupBy = "All";
			ElsIf pPredefinedDataName = "InvoicePrintHotelProductsGroupByServiceRu" Or
			      pPredefinedDataName = "InvoicePrintHotelProductsGroupByServiceEn" Or
			      pPredefinedDataName = "InvoicePrintHotelProductsGroupByServiceDe" Then
				vGroupBy = "ByService";
			EndIf;
		EndIf;
	EndIf;	
	Return vGroupBy;
EndFunction // GetPrintGroupBy

// -----------------------------------------------------------------------------
&AtServer
Procedure DisableFieldsByCustomer()
	// Disabled fields if customer is filled
	If ValueIsFilled(SessionParameters.CurrentUser.Customer) Then
		Items.AccountingCustomer.Enabled = False;
		Items.AccountingCustomer.ClearButton = False;
		Items.AccountingCustomer.ChoiceButton = False;
		Items.GuestGroup.ChoiceButton = False;
		Items.GuestGroup.ClearButton = False;
	EndIf;
EndProcedure // DisableFieldsByCustomer

// -----------------------------------------------------------------------------
&AtServer
Procedure OnOpenForm()
	WasPosted = True;
	IsNew = False;
	DisableFieldsByCustomer();
	// Get object value
	vObj = FormAttributeToValue("Object");
	If vObj.IsNew() Then
		IsNew = True;
		WasPosted = False;
		// Use current time by default
		vObj.SetTime(AutoTimeMode.CurrentOrLast);
		// Fill attributes with default values
		If Not ValueIsFilled(vObj.Author) Then
			vObj.pmFillAttributesWithDefaultValues();
		Else
			vObj.pmFillAuthorAndDate();
		EndIf;
		vAuthorCustomer = vObj.Author.Customer; 
		If ValueIsFilled(vAuthorCustomer) Then
			vObj.AccountingCustomer = vAuthorCustomer;
			AccountingCustomerOnChangeAtServer(vObj);
		EndIf;
	EndIf;
	If Not ValueIsFilled(PrintFormLanguage) Then
		PrintFormLanguage = SessionParameters.CurrentLanguage;
		If ValueIsFilled(vObj.AccountingCustomer) And ValueIsFilled(vObj.AccountingCustomer.Language) Then
			PrintFormLanguage = vObj.AccountingCustomer.Language;
		EndIf;
	EndIf;
	If ValueIsFilled(vObj.Company) Then
		If ValueIsFilled(vObj.Company.EditProhibitedDate) And 
		   BegOfDay(vObj.Company.EditProhibitedDate) >= BegOfDay(vObj.Date) Then
			ReadOnly = True;
		EndIf;
	EndIf;
	// Calculate totals
	CalculateTotals(vObj);
	// Save current accounting currency and rate
	SavAccountingCurrency = vObj.AccountingCurrency;
	SavAccountingCurrencyExchangeRate = vObj.AccountingCurrencyExchangeRate;
	// Set document number and date appearances
	If Not cmCheckUserPermissions("HavePermissionToEditPostedFolioTransactions") Then
		Items.Number.ReadOnly = True;
		Items.Number.Enabled = False;
		Items.Date.ReadOnly = True;
		Items.Date.Enabled = False;
		Items.Date.ChoiceButton = False;
	EndIf;
	// Save current document date
	OldDate = vObj.Date;
	// Set object value
	ValueToFormAttribute(vObj, "Object");
EndProcedure // OnOpenForm

// -----------------------------------------------------------------------------
&AtServer
Procedure AccountingCustomerOnChangeAtServer(pObj = Undefined)
	// Check parameters
	vObj = pObj;
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object", Type("DocumentObject.ProformaInvoice"));
	EndIf;
	If ValueIsFilled(vObj.AccountingCustomer) Then
		If ValueIsFilled(vObj.AccountingContract) Then
			If vObj.AccountingContract.Owner <> vObj.AccountingCustomer Then
				vObj.AccountingContract = vObj.AccountingCustomer.Contract;
			EndIf;
		EndIf;
	EndIf;
	RecalculateServicesAtServer(vObj);
	ValueToFormAttribute(vObj, "Object");
EndProcedure // AccountingCustomerOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure BankAccountOnChangeAtServer(pObj = Undefined)
	// Check parameters
	vObj = pObj;
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	If ValueIsFilled(vObj.BankAccount) And ValueIsFilled(vObj.BankAccount.AccountCurrency) And
	   vObj.BankAccount.AccountCurrency <> vObj.AccountingCurrency Then
		vObj.AccountingCurrency = vObj.BankAccount.AccountCurrency;
		AccountingCurrencyOnChangeAtServer(vObj);
	EndIf;
	RecalculateServicesAtServer(vObj);
EndProcedure // BankAccountOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure AccountingCurrencyOnChangeAtServer(pObj = Undefined)
	// Check parameters
	vUseParamterObject = True;
	vObj = pObj;
	If (TypeOf(pObj) = Type("FormDataCollection")) Or pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParamterObject = False;
	EndIf;	
	vObj.AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(vObj.Hotel, vObj.AccountingCurrency, vObj.ExchangeRateDate);
	For Each vSrvRow In vObj.Services Do
		// Recalculate service according to the accounting currency
		vObj.pmRecalculateService(vSrvRow, SavAccountingCurrency, SavAccountingCurrencyExchangeRate);
	EndDo;
	CalculateTotals(vObj);
	// Save current accounting currency and rate
	SavAccountingCurrency = vObj.AccountingCurrency;
	SavAccountingCurrencyExchangeRate = vObj.AccountingCurrencyExchangeRate;
	// Try to find bank account of the same account currency as choosen one
	If ValueIsFilled(vObj.BankAccount) And ValueIsFilled(vObj.Company) Then
		If vObj.BankAccount.AccountCurrency <> vObj.AccountingCurrency Then
			vAccounts = vObj.Company.GetObject().pmGetCompanyBankAccounts(vObj.AccountingCurrency);
			If vAccounts.Count() > 0 Then
				vAccountRow = vAccounts.Get(0);
				vObj.BankAccount = vAccountRow.BankAccount;
			EndIf;
		EndIf;
	EndIf;
	If vUseParamterObject = False Then
		// Set object value
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure // AccountingCurrencyOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure CalculateTotals(pObj = Undefined)
	// Check parameters
	vObj = pObj;
	If pObj = Undefined Then
		vObj = Object;
	EndIf;
	vSum = 0;
	vVATSum = 0;
	If ValueIsFilled(vObj.AccountingCustomer) And vObj.AccountingCustomer.DoNotPostCommission Then
		vSum = vObj.Services.Total("Sum");
		vVATSum = vObj.Services.Total("VATSum");
	Else
		vSum = vObj.Services.Total("Sum") - vObj.Services.Total("CommissionSum");
		vVATSum = vObj.Services.Total("VATSum") - vObj.Services.Total("VATCommissionSum");
	EndIf;
	If vSum <> vObj.Sum Then
		vObj.Sum = vSum;
	EndIf;
	If vVATSum <> vObj.VATSum Then
		vObj.VATSum = vVATSum;
	EndIf;
	Totals = cmFormatSum(vSum, vObj.AccountingCurrency);
	UpdateDecoration(vObj);
EndProcedure // CalculateTotals

// -----------------------------------------------------------------------------
&AtServer
Procedure ExchangeRateDateOnChangeAtServer(pObj = Undefined)
	// Check parameters
	vObj = pObj;
	If pObj = Undefined Then
		vObj = Object;
	EndIf;
	vObj.AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(vObj.Hotel, vObj.AccountingCurrency, vObj.ExchangeRateDate);
	// Save current accounting currency and rate
	SavAccountingCurrency = vObj.AccountingCurrency;
	SavAccountingCurrencyExchangeRate = vObj.AccountingCurrencyExchangeRate;
	RecalculateServicesAtServer();
EndProcedure // ExchangeRateDateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure AccountingCurrencyExchangeRateOnChangeAtServer(pObj = Undefined)
	// Check parameters
	vObj = pObj;
	If pObj = Undefined Then
		vObj = Object;
	EndIf;
	vObj.AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(vObj.Hotel, vObj.AccountingCurrency, vObj.ExchangeRateDate);
	// Save current accounting currency and rate
	SavAccountingCurrency = vObj.AccountingCurrency;
	SavAccountingCurrencyExchangeRate = vObj.AccountingCurrencyExchangeRate;
	RecalculateServicesAtServer();
EndProcedure // AccountingCurrencyExchangeRateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure CompanyOnChangeAtServer(pObj = Undefined)
	// Check parameters
	vUseParamterObject = True;
	vObj = pObj;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParamterObject = False;
	EndIf;
	If ValueIsFilled(vObj.Company) Then
		If Not ValueIsFilled(vObj.BankAccount) Or
		   ValueIsFilled(vObj.BankAccount) And vObj.BankAccount.Owner <> vObj.Company Then
			If ValueIsFilled(vObj.Company.BankAccount) And vObj.AccountingCurrency = vObj.Company.BankAccount.AccountCurrency Then
				vObj.BankAccount = vObj.Company.BankAccount;
			Else
				vObj.BankAccount = Catalogs.BankAccounts.EmptyRef();
			EndIf;
		EndIf;
		vObj.SetNewNumber();
	Else
		vObj.BankAccount = Catalogs.BankAccounts.EmptyRef();
	EndIf;
	RecalculateServicesAtServer(vObj);
	If vUseParamterObject = False Then
		// Set object value
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure // CompanyOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure DateOnChangeAtServer(pObj = Undefined)
	// Check parameters
	vUseParamterObject = True;
	vObj = pObj;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParamterObject = False;
	EndIf;
	// Automatically assign new document number if year has changed
	If ValueIsFilled(vObj.Date) And ValueIsFilled(OldDate) Then
		If Year(OldDate) <> Year(vObj.Date) Then
			vObj.SetNewNumber();
		EndIf;
		OldDate = vObj.Date;
	EndIf;
	If vUseParamterObject = False Then
		// Set object value
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure // DateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function PerformAutomaticPrinting()
	// Get language
	vLanguage = Catalogs.Languages.EmptyRef();
	If ValueIsFilled(Object.AccountingCustomer) Then
		vLanguage = Object.AccountingCustomer.Language;
	EndIf;
	// Get list of automatic print froms for this object type
	vForms = cmGetObjectPrintingForms(Documents.ProformaInvoice.EmptyRef(), vLanguage);
	vAutoForms = vForms.FindRows(New Structure("AutomaticallyPrintOnFirstObjectWrite", True));
	// Call object print forms handler for each form
	vTypeOfPrintFormList = New ValueList;
	For Each vAutoForm In vAutoForms Do
		vTypeOfPrintForm = GetTypeOfPrintForm(vAutoForm.ObjectPrintingForm);
		vTypeOfPrintFormList.Add(vAutoForm.ObjectPrintingForm, vTypeOfPrintForm);
	EndDo;
    //Return
	Return vTypeOfPrintFormList;
EndFunction // PerformAutomaticPrinting

// -----------------------------------------------------------------------------
&AtServer
Function GetTypeOfPrintForm(pForm = Undefined)
	vForm = pForm;
	vTypeOfPrintForm = "";
	// Check predefined forms
	If vForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceRu Or 
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceEn Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceDe Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupPerClientRu Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupPerClientEn Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupPerClientDe Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupByServiceRu Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupByServiceEn Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupByServiceDe Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupInPricePerClientPerDayRu Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupInPricePerClientPerDayEn Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupInPricePerClientPerDayDe Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupInPricePerDayRu Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupInPricePerDayEn Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupInPricePerDayDe Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupAllPerClientPerDayRu Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupAllPerClientPerDayEn Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupAllPerClientPerDayDe Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupAllPerDayRu Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupAllPerDayEn Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupAllPerDayDe Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupInPricePerClientRu Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupInPricePerClientEn Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupInPricePerClientDe Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupInPriceRu Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupInPriceEn Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupInPriceDe Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupAllPerClientRu Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupAllPerClientEn Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupAllPerClientDe Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupAllRu Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupAllEn Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupAllDe Then
		vTypeOfPrintForm = "PrintInvoiceForm";
	ElsIf vForm = Catalogs.ObjectPrintingForms.InvoicePrintShortInvoiceGroupInPriceRu Or 
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintShortInvoiceGroupInPriceEn Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintShortInvoiceGroupInPriceDe Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintShortInvoiceGroupAllRu Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintShortInvoiceGroupAllEn Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintShortInvoiceGroupAllDe Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintShortInvoiceGroupByServiceRu Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintShortInvoiceGroupByServiceEn Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintShortInvoiceGroupByServiceDe Then
		vTypeOfPrintForm = "PrintInvoiceShortForm";
	ElsIf vForm = Catalogs.ObjectPrintingForms.InvoicePrintHotelProductsGroupInPriceRu Or 
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintHotelProductsGroupInPriceEn Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintHotelProductsGroupInPriceDe Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintHotelProductsGroupAllRu Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintHotelProductsGroupAllEn Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintHotelProductsGroupAllDe Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintHotelProductsGroupByServiceRu Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintHotelProductsGroupByServiceEn Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintHotelProductsGroupByServiceDe Then
		vTypeOfPrintForm = "PrintInvoiceHotelProductsForm";
	ElsIf vForm = Catalogs.ObjectPrintingForms.InvoicePrintSimpleInvoiceRu Or 
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintSimpleInvoiceEn Or
		vForm = Catalogs.ObjectPrintingForms.InvoicePrintSimpleInvoiceDe Then
		vTypeOfPrintForm = "PrintInvoiceSimpleForm";
	ElsIf vForm = Catalogs.ObjectPrintingForms.InvoicePrintPaymentOrder Then
		vTypeOfPrintForm = "PrintPaymentOrder";
		// Run report
	ElsIf ValueIsFilled(vForm.Report) Then
		If Not cmGenerateReport(vForm.Report, Object.Ref) Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to run report!';ru='Не удалось выполнить отчет!';de='Der Bericht konnte nicht ausgeführt werden!'"));
		EndIf;
	ElsIf ValueIsFilled(vForm.ExternalProcessing) Then
		vTypeOfPrintForm = "ExternalProcessing";
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='No print form processor found!';ru='В настройках печатной формы не задан обработчик!';de='In den Einstellungen der Druckunterlagen wurde kein Bearbeiter vorgegeben!'"));
	EndIf;
	Return vTypeOfPrintForm;
EndFunction // GetTypeOfPrintForm

// -----------------------------------------------------------------------------
&AtServer
Procedure RecalculateServicesAtServer(pObj = Undefined)
	// Check parameters
	vObj = pObj;
	vUseParameterObject = True;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParameterObject = False;
	EndIf;
	// Set recalculate invoice button disabled if invoice is paid
	If Not vObj.IsNew() Then
		vInvBalance = vObj.pmGetInvoiceBalance();
		If vInvBalance = 0 And vObj.Sum <> 0 Then
			If Not cmCheckUserPermissions("HavePermissionToRecalculateInvoicesBeingAlreadyPaid") Then  
				vMsg = NStr("en = 'This invoice is already paid! It could not be recalculated.'; 
							|de = 'Diese Pro-Forma Rechnung ist bezahlt! Nach der Bezahlung kann die Rechnung nicht durchgerechnet werden.'; 
							|ru = 'Этот счет-требование оплачен! После оплаты счет не может быть пересчитан.'");
				tcCommonFunctionOnClientServer.TextMessage(vMsg);
				Return;
			EndIf;
		EndIf;
	EndIf;
	// Refill the document services
	If ValueIsFilled(vObj.ParentDoc) Then
		If TypeOf(vObj.ParentDoc) = Type("DocumentRef.Folio") Then
			vObj.pmFillByFolio(vObj.ParentDoc, True);
		ElsIf TypeOf(vObj.ParentDoc) = Type("DocumentRef.Reservation") Then 
			vObj.pmFillByReservation(vObj.ParentDoc, , True);
		ElsIf TypeOf(vObj.ParentDoc) = Type("DocumentRef.Accommodation") Then
			vParentDoc = vObj.ParentDoc;
			vObj.pmFillByReservation(vParentDoc, , True);
		ElsIf TypeOf(vObj.ParentDoc) = Type("DocumentRef.Settlement") Then 
			vObj.pmFillBySettlement(vObj.ParentDoc);
		ElsIf TypeOf(vObj.ParentDoc) = Type("DocumentRef.IssueHotelProducts") Then 
			vObj.pmFillByIssueHotelProducts(vObj.ParentDoc);
		EndIf;
	ElsIf ValueIsFilled(vObj.GuestGroup) Then
		vOldServices = vObj.Services.Unload();
		vObj.pmFillByGuestGroup(vObj.GuestGroup, , True);
		If vObj.ExtraInvoice Then
			If Not CheckOtherInvoices(vObj.GuestGroup, vObj, ThisObject, Items.ServicesCommandBar, True) Then
				vObj.Services.Load(vOldServices);
			EndIf;
		EndIf;
	ElsIf ValueIsFilled(vObj.RoomQuota) Then 
		vObj.pmFillByAllotment(vObj.RoomQuota);
	ElsIf ValueIsFilled(vObj.AccountingContract) Then 
		vObj.pmFillByContract(vObj.AccountingContract);
	ElsIf ValueIsFilled(vObj.AccountingCustomer) Then 
		vObj.pmFillByCustomer(vObj.AccountingCustomer);
	EndIf;
	// Recalculate totals
	CalculateTotals(vObj);
	If Not vUseParameterObject Then
		// Set object value
		ValueToFormAttribute(vObj, "Object");
	EndIf;
	// Turn on is modified flag
	Modified = True;
EndProcedure // RecalculateServicesAtServer

// -----------------------------------------------------------------------------
// Description: Checks guest group changes and asks user whether to create invoice for changes only
// Parameters: Guest group reference, New invoice object 
// Return value: False if user skipped selection, true if choice was done
// -----------------------------------------------------------------------------
&AtServer
Function CheckOtherInvoices(pGuestGroup, pInvObj, pForm, pButton, pExtraInvoice = False)
	// Check if there are other guest group invoices
	vGuestGroupObj = pGuestGroup.GetObject();
	vExistingInvoices = vGuestGroupObj.pmGetInvoices();
	If vExistingInvoices.Count() > 0 Then
		vNewInvServices = pInvObj.Services.Unload();
		For Each vExistingInvoicesRow In vExistingInvoices Do
			If vExistingInvoicesRow.InvoiceDate <= pInvObj.Date And vExistingInvoicesRow.Invoice <> pInvObj.Ref Then
				For Each vExistingInvoicesServicesRow In vExistingInvoicesRow.Invoice.Services Do
					vNewInvServicesRow = vNewInvServices.Add();
					FillPropertyValues(vNewInvServicesRow, vExistingInvoicesServicesRow, , "LineNumber");
					vNewInvServicesRow.Quantity = -vNewInvServicesRow.Quantity;
					vNewInvServicesRow.Sum = -vNewInvServicesRow.Sum;
					vNewInvServicesRow.VATSum = -vNewInvServicesRow.VATSum;
					vNewInvServicesRow.DiscountSum = -vNewInvServicesRow.DiscountSum;
					vNewInvServicesRow.CommissionSum = -vNewInvServicesRow.CommissionSum;
					vNewInvServicesRow.VATCommissionSum = -vNewInvServicesRow.VATCommissionSum;
					vNewInvServicesRow.NumberOfPersons = -vNewInvServicesRow.NumberOfPersons;
					vNewInvServicesRow.RoomQuantity = -vNewInvServicesRow.RoomQuantity;
				EndDo;
			EndIf;
		EndDo;
		vNewInvServices.GroupBy("AccountingDate, Service, Price, Unit, VATRate, Remarks, Client, AccommodationType, RoomType, Room, Resource, IsInPrice, IsRoomRevenue, IsResourceRevenue, DateTimeFrom, DateTimeTo, CalendarDayType, Discount, HotelProduct, Agent, AgentCommissionType, AgentCommission, GuestGroup", "Quantity, Sum, VATSum, NumberOfPersons, RoomQuantity, DiscountSum, CommissionSum, VATCommissionSum");
		i = 0;
		While i < vNewInvServices.Count() Do
			vNewInvServicesRow = vNewInvServices.Get(i);
			If vNewInvServicesRow.Quantity < 0 Or vNewInvServicesRow.Quantity = 0 And vNewInvServicesRow.Sum = 0 Then
				vNewInvServices.Delete(i);
			Else
				i = i + 1;
			EndIf;
		EndDo;
		vNewFullAmount = pInvObj.Services.Total("Sum");
		vNewExtraAmount = vNewInvServices.Total("Sum");
		If pExtraInvoice Then
			pInvObj.Services.Load(vNewInvServices);
		ElsIf vNewExtraAmount <> 0 And vNewFullAmount <> 0 And vNewFullAmount <> vNewExtraAmount Then
			vUCMenu = New ValueList();
			vUCMenu.Add(1, NStr("en='Invoice for total amount ';ru='Счет на полную сумму ';de='Rechnung für die volle Summe'") + cmFormatSum(vNewFullAmount, pInvObj.AccountingCurrency));
			vUCMenu.Add(2, NStr("en='Invoice for extra amount ';ru='Счет на доплату ';de='Nachzahlungsrechnung'") + cmFormatSum(vNewExtraAmount, pInvObj.AccountingCurrency));
			vUC = pForm.ChooseFromMenu(vUCMenu, pButton);
			If vUC = Undefined Then
				Return False;
			ElsIf vUC.Value = 2 Then
				pInvObj.Services.Load(vNewInvServices);
				pInvObj.ExtraInvoice = True;
			EndIf;
		EndIf;
	EndIf;
	Return True;
EndFunction // CheckOtherInvoices

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterGuestGroupStartChoice(pResult, pParams) Export
  
  If pResult <> Undefined Then
		Object.GuestGroup = pResult;
		GuestGroupOnChange(pParams.Item);
	EndIf;
  
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure UpdateDecoration(pObj)
	Items.DecorationSum.Title = tcOnServer.cmFormattedSumString(pObj.Sum, pObj.AccountingCurrency); 	
	Items.DecorationVatSum.Title = tcOnServer.cmFormattedSumString(pObj.VATSum, pObj.AccountingCurrency);	
EndProcedure // GuestGroupOnChange

// -----------------------------------------------------------------------------
&AtServerNoContext
Function ServicesServiceOnChangeAtServer(pService, pCustomer)
	If ValueIsFilled(pCustomer) Then
		Return pService.GetObject().pmGetServiceDescription(pCustomer.Language, True);
	Else
		Return pService.GetObject().pmGetServiceDescription(SessionParameters.CurrentLanguage, True);
	EndIf;
EndFunction // ServicesServiceOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCloseAtServer()
	If ValueIsFilled(CurrentUser) Then
		SessionParameters.CurrentUser = CurrentUser;
	EndIf;
EndProcedure // OnCloseAtServer

// -----------------------------------------------------------------------------
&AtServer
Function CheckDocumentAttributesAtServer(rMessage)
	vObj = FormAttributeToValue("Object");	
	SetObjectAndFormAttributeConformity(vObj, "Object");
	// Basic checks
	vAttributeInErr = "";
	If vObj.pmCheckDocumentAttributes(rMessage, vAttributeInErr) Then
		vUM = New UserMessage();
		vUM.SetData(vObj);
		vUM.Field = vAttributeInErr;
		vUM.Text = NStr(rMessage);
		vUM.Message();
		Return False;
	Else
		Return True;
	EndIf;	
EndFunction // CheckDocumentAttributesAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure GroupByServicesButtonAtServer(pMode)
	// Initialize working table with services
	vServices = Object.Services.Unload();
	If pMode = 1 Or pMode = 2 Then
		vCurRow = Items.Services.CurrentRow;
		If vCurRow <> Undefined Then
			vCurData = Object.Services.FindByID(vCurRow);
		Else
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Service row is not choosen!';ru='Не выбрана строка с услугой!';de='Keine Zeile mit Dienstleistung ist gewählt!'"));
			Return;	
		EndIf;
	EndIf;
	If pMode = 1 Then
		// Group by services
		If vCurData <> Undefined Then
			// Calculate quantity
			vService = Undefined;
			vServiceRow = Undefined;
			vIsResourceRevenue = False;
			vIsRoomRevenue = False;
			vQuantity = 0;
			vDateTimeFrom = '39991231235959';
			vDateTimeTo = '00010101';
			For Each vServicesRow In vServices Do
				If Not vIsResourceRevenue And vServicesRow.IsRoomRevenue And vServicesRow.Client = vCurData.Client Then
					vQuantity = vQuantity + vServicesRow.Quantity;
					vDateTimeFrom = Min(vDateTimeFrom, vServicesRow.DateTimeFrom);
					vDateTimeTo = Max(vDateTimeTo, vServicesRow.DateTimeTo);
					If Not vIsRoomRevenue Then
						vService = vServicesRow.Service;
						vServiceRow = vServicesRow;
					EndIf;
					vIsRoomRevenue = True;
				EndIf;
				If Not vIsRoomRevenue And vServicesRow.IsResourceRevenue And vServicesRow.Client = vCurData.Client Then
					vQuantity = vQuantity + vServicesRow.Quantity;
					vDateTimeFrom = Min(vDateTimeFrom, vServicesRow.DateTimeFrom);
					vDateTimeTo = Max(vDateTimeTo, vServicesRow.DateTimeTo);
					If Not vIsResourceRevenue Then
						vService = vServicesRow.Service;
						vServiceRow = vServicesRow;
					EndIf;
					vIsResourceRevenue = True;
				EndIf;
			EndDo;
			If Not ValueIsFilled(vService) Then
				vService = vCurData.Service;
			EndIf;
			If vQuantity = 0 Then
				vQuantity = vCurData.Quantity;
			EndIf;
			// Group by services
			vServices.FillValues(vService, "Service");
			vServices.FillValues(0, "Price");
			If vServiceRow <> Undefined Then
				vServices.FillValues(vServiceRow.Remarks, "Remarks");
				vServices.FillValues(vServiceRow.Unit, "Unit");
				vServices.FillValues(vServiceRow.VATRate, "VATRate");
				vServices.FillValues(vServiceRow.RoomType, "RoomType");
				vServices.FillValues(vServiceRow.Resource, "Resource");
			EndIf;
			If ValueIsFilled(vDateTimeFrom) And vDateTimeFrom < vDateTimeTo Then
				vServices.FillValues(vDateTimeFrom, "DateTimeFrom");
				vServices.FillValues(vDateTimeTo, "DateTimeTo");
			ElsIf vServiceRow <> Undefined Then
				vServices.FillValues(vServiceRow.DateTimeFrom, "DateTimeFrom");
				vServices.FillValues(vServiceRow.DateTimeTo, "DateTimeTo");
			EndIf;
			vServices.FillValues(vQuantity, "Quantity");
			vServices.GroupBy("Service, Remarks, Price, Unit, VATRate, RoomType, Resource, DateTimeFrom, DateTimeTo, Quantity, Discount, AgentCommission", "Sum, VATSum, DiscountSum, CommissionSum");
			For Each vServicesRow In vServices Do
				vServicesRow.Price = cmRecalculatePrice(vServicesRow.Sum, vServicesRow.Quantity);
				If ValueIsFilled(Object.GuestGroup) And ValueIsFilled(Object.AccountingCustomer) And ValueIsFilled(Object.GuestGroup.ClientDoc) And 
				  (TypeOf(Object.GuestGroup.ClientDoc) = Type("DocumentRef.Accommodation") Or TypeOf(Object.GuestGroup.ClientDoc) = Type("DocumentRef.Reservation")) Then
					vDoc = Object.GuestGroup.ClientDoc;
					vLanguage = ?(ValueIsFilled(Object.AccountingCustomer), Object.AccountingCustomer.Language, Object.Hotel.Language);
					vGuestGroupCode = ", " + cmNStr("en='Reserv. N '; ru='Бронь № '; de='Reserv. Nr. '", vLanguage) + Format(Object.GuestGroup.Code, "ND=12; NFD=0; NG=");
					vRoomTypeStr = ", " + vDoc.RoomType.GetObject().pmGetRoomTypeDescription(vLanguage);
					vPeriodStr = ", " + Format(vDoc.CheckInDate, "DF=dd.MM.yyyy") + " - " + Format(vDoc.CheckOutDate, "DF=dd.MM.yyyy");
					vGuestStr = ?(ValueIsFilled(vDoc.Guest), ", " + TrimAll(vDoc.Guest.FullName), "");
					vNumberOfGuestsStr = ?(Object.GuestGroup.GuestsCheckedIn > 1, ", " + Format(Object.GuestGroup.GuestsCheckedIn, "ND=6; NFD=0; NG=") + cmNStr("en=' prs.'; ru=' чел.'; de=' Prs.'", vLanguage), "");
					vServicesRow.Remarks = vServicesRow.Remarks + vGuestGroupCode + vRoomTypeStr + vPeriodStr + vGuestStr + vNumberOfGuestsStr;
				EndIf;
			EndDo;
		Else
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Service row is not choosen!';ru='Не выбрана строка с услугой!';de='Keine Zeile mit Dienstleistung ist gewählt!'"));
			Return;
		EndIf
	ElsIf pMode = 2 Then
		If vCurData <> Undefined Then
			vLanguage = Catalogs.Languages.RU;
			If ValueIsFilled(Object.AccountingCustomer) Then
				vLanguage = Object.AccountingCustomer.Language;
			EndIf;
			vServices.FillValues("", "Remarks");
			vServices.GroupBy("Service, Remarks, Price, Unit, VATRate, IsInPrice, IsRoomRevenue, IsResourceRevenue, RoomType, Resource, DateTimeFrom, DateTimeTo", "Quantity, Sum, VATSum");
			For Each vServicesRow In vServices Do
				If ValueIsFilled(vServicesRow.Service) Then
					vServicesRow.Remarks = vServicesRow.Service.GetObject().pmGetServiceDescription(vLanguage);
				EndIf;
				vServicesRow.Price = cmRecalculatePrice(vServicesRow.Sum, vServicesRow.Quantity);
			EndDo;
		Else
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Service row is not choosen!';ru='Не выбрана строка с услугой!';de='Keine Zeile mit Dienstleistung ist gewählt!'"));
			Return;			
		EndIf;
	ElsIf pMode = 3 Then
		vServices.GroupBy("Service, Remarks, Price, Unit, VATRate, AccommodationType, NumberOfPersons, RoomQuantity, Client, RoomType, Room, HotelProduct, IsInPrice, IsRoomRevenue, Resource, IsResourceRevenue, DateTimeFrom, DateTimeTo, CalendarDayType, GuestGroup", "Quantity, Sum, VATSum");
	EndIf;
	// Load resulting value table to the invoice services
	Object.Services.Load(vServices);
	// Recalculate services VAT
	For Each vSrvRow In Object.Services Do
		vSrvRow.VATSum = cmCalculateVATSum(vSrvRow.VATRate, vSrvRow.Sum, vSrvRow.AccountingDate);
	EndDo;
	// Recalculate totals
	CalculateTotals();
	// Turn on is modified flag
	Modified = True;
EndProcedure // GroupByServicesButtonAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterChoiceGroupByMode(pItem, pExtaParams) Export 
	If pItem <> Undefined Then
		GroupByServicesButtonAtServer(pItem.Value);	
	EndIf;
EndProcedure // AfterChoiceGroupByMode

// -----------------------------------------------------------------------------
// Fill folio for payment
//
// Parameters:
//  - None
&AtServer
Procedure FillPaymentFolio()
	vParentDoc = Object.ParentDoc;
	vFolio = Undefined;
	If ValueIsFilled(vParentDoc) Or ValueIsFilled(Object.GuestGroup) Then
		If TypeOf(vParentDoc) = Type("DocumentRef.Folio") Then
			vFolio = vParentDoc;
		ElsIf TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Or
			TypeOf(vParentDoc) = Type("DocumentRef.Reservation") Then
			If vParentDoc.Services.Count() > 0 Then
				vRoomRevenueServices = vParentDoc.Services.FindRows(New Structure("IsRoomRevenue", True));
				If vRoomRevenueServices.Count() > 0 Then
					vFolio = vRoomRevenueServices.Get(0).Folio;
				EndIf;
			EndIf;
		ElsIf TypeOf(vParentDoc) = Type("DocumentRef.ResourceReservation") Then
			vFolio = vParentDoc.ChargingFolio;
		ElsIf ValueIsFilled(Object.GuestGroup) Then
			vGuestGroup = Object.GuestGroup;
			If vGuestGroup.ChargingRules.Count() > 0 Then
				vGGCRRow = vGuestGroup.ChargingRules.Get(0);
				If ValueIsFilled(vGGCRRow.ChargingFolio) And Not vGGCRRow.ChargingFolio.IsClosed Then
					vFolio = vGGCRRow.ChargingFolio;
				EndIf;
			EndIf;
			vQry = New Query();
				vQry.Text = 
				"SELECT
				|	Folio.Ref AS Ref,
				|	Folio.ParentDoc AS ParentDoc
				|FROM
				|	Document.Folio AS Folio
				|WHERE
				|	NOT Folio.DeletionMark
				|	AND NOT Folio.IsClosed
				|	AND Folio.Hotel = &qHotel
				|	AND (Folio.ParentDoc = &qParentDoc
				|			OR &qParentDocIsEmpty)
				|	AND Folio.GuestGroup = &qGuestGroup
				|	AND (Folio.Client = &qClient
				|			OR &qClientIsEmpty)
				|	AND (Folio.Customer In (&qCustomer)
				|			OR &qCustomerIsEmpty)
				|	AND (Folio.Company = &qCompany
				|			OR &qCompanyIsEmpty)
				|
				|ORDER BY
				|	Folio.IsClosed,
				|	Folio.PointInTime";
				vCustomerList = New Array;
				If ValueIsFilled(Object.AccountingCustomer) Then
					vCustomerList.Add(Object.AccountingCustomer);
					If Object.AccountingCustomer = Object.Hotel.IndividualsCustomer Then
						vCustomerList.Add(Catalogs.Customers.EmptyRef());
					EndIf;	
				EndIf;	
				vQry.SetParameter("qHotel", Object.Hotel);
				vQry.SetParameter("qParentDoc", Object.ParentDoc);
				vQry.SetParameter("qParentDocIsEmpty", Not ValueIsFilled(Object.ParentDoc));
				vQry.SetParameter("qGuestGroup", vGuestGroup);
				vQry.SetParameter("qClient", Catalogs.Clients.EmptyRef());
				vQry.SetParameter("qClientIsEmpty", True);
				vQry.SetParameter("qCustomer", Object.AccountingCustomer);
				vQry.SetParameter("qCustomerIsEmpty", vCustomerList.Count() = 0);
				vQry.SetParameter("qCompany", Object.Company);
				vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Object.Company));
				vFolios = vQry.Execute().Unload();
				// Find folio with room revenue services
				For Each vFoliosRow In vFolios Do
					vFirstGroupFolio = vFoliosRow.Ref;
					If ValueIsFilled(vFoliosRow.ParentDoc) Then
						If TypeOf(vFoliosRow.ParentDoc) = Type("DocumentRef.Accommodation") Or
						   TypeOf(vFoliosRow.ParentDoc) = Type("DocumentRef.Reservation") Then
							If vFoliosRow.ParentDoc.Services.Count() > 0 Then
								vRoomRevenueServices = vFoliosRow.ParentDoc.Services.FindRows(New Structure("IsRoomRevenue", True));
								If vRoomRevenueServices.Count() > 0 Then
									vFolio = vRoomRevenueServices.Get(0).Folio;
									Break;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
				EndDo;

		EndIf;
		Object.Folio = vFolio;
	EndIf;
EndProcedure //  FillPaymentFolio()

// -----------------------------------------------------------------------------
&AtServer
Procedure AfterWriteAtServer(pCurrentObject, pWriteParameters)
	If pCurrentObject.Posted Then
		Items.GetPaid.Visible = ShowButtonGetPaid;
	EndIf;
EndProcedure // AfterWriteAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure GetPaidClick(pItem)
	If Not Modified Then
		vParams = New Structure("SelDocument", Object.Ref); 
		OpenForm("CommonForm.tcGetPaidForm", vParams, ThisObject, UUID);
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'All changes must be saved!'; de = 'Alle Änderungen müssen gespeichert werden!'; ru = 'Все изменения должны быть сохранены!'"));
	EndIf;
EndProcedure // GetPaidClick

// -----------------------------------------------------------------------------
&AtClient
Procedure RecalculateServicesConfirmation(pUC, pExtraParams) Export
	If pUC = DialogReturnCode.Yes Then
		RecalculateServicesAtServer();
	EndIf;
EndProcedure // RecalculateServicesConfirmation

#EndRegion
