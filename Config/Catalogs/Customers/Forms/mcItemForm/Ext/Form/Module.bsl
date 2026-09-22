
#Region FormEventHandlers

// ----------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	TableBoxContracts.Parameters.SetParameterValue("qOwner", Object.Ref);
	TableBoxBankAccounts.Parameters.SetParameterValue("qOwner", Object.Ref);
	vObj = FormAttributeToValue("Object");
	If vObj.IsNew() Then
		If ValueIsFilled(SessionParameters.CurrentHotel) Then
			vObj.Country = SessionParameters.CurrentHotel.Citizenship;
		EndIf;
	EndIf;
	// Open read only if user do not have rights to edit customer
	If Not cmCheckUserPermissions("HavePermissionToEditCustomer") Then
		If Not vObj.IsNew() Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to edit customers! Customer data will be opened read only.';ru='Нет прав редактировать данные контрагентов! Карточка контрагента будет открыта на просмотр.';de='Sie haben keine Rechte, Daten von Partnern zu redigieren! Die Karte des Partners wird zur Ansicht geöffnet.'"));
			ReadOnly = True;
		EndIf;
	EndIf;
	// Check if customer was opened by agent user
	DisableFieldsByCustomer();
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	If Catalogs.ObjectFormActions.CustomerSendInvitationToNewAgent.IsActive And Not Catalogs.ObjectFormActions.CustomerSendInvitationToNewAgent.DeletionMark Then
		Items.FormContractSendInvitationToNewAgent.Visible = True;			
	Else	
		Items.FormContractSendInvitationToNewAgent.Visible = False;		
	EndIf;
	// Fill document tasks presentation
	FillTasksPresentation();
EndProcedure // OnCreateAtServer

// ----------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	OnOpenForm();
	vTasksStructure = GetTasksStructure();
	Title = Items.Pages.CurrentPage.Title;
	For Each vTasks In vTasksStructure Do
		If	vTasks.Value.PopUp Then
			tcCommonFunctionOnClientServer.TextMessage(vTasks.Value.Remarks);
		EndIf;
	EndDo;
EndProcedure // OnOpen

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	// Save state
	If Not pWriteParameters.Property("Success") Then
		vResultMessage = BeforeWriteServer(pCancel);
		If Not IsBlankString(vResultMessage) Then
			ShowQueryBox(New NotifyDescription("BeforeWriteEnd", ThisObject), vResultMessage, QuestionDialogMode.OKCancel, , DialogReturnCode.Cancel);
			pCancel = True;
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	// Save color
	If ItemColorIsSet Then
		pCurrentObject.Color = New ValueStorage(ItemColor);
	Else
		pCurrentObject.Color = Undefined;
	EndIf;
	// Check room rates
	vNum = 0;
	While vNum < pCurrentObject.RoomRates.Count() Do
		vRRRow = pCurrentObject.RoomRates.Get(vNum);
		If Not ValueIsFilled(vRRRow.RoomRate) And Not ValueIsFilled(vRRRow.DiscountType) Then
			pCurrentObject.RoomRates.Delete(vNum);
		Else
			vNum = vNum + 1;
		EndIf;
	EndDo;
EndProcedure // BeforeWriteAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	vErrorInfo = AfterWriteServer();
	If vErrorInfo <> "" Then
		ShowErrorInfo(vErrorInfo);
	EndIf;
EndProcedure // AfterWrite

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "MessageWrite" Then
		FillTasksPresentation();
	EndIf;
EndProcedure // NotificationProcessing

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure DecorationTasksClick(pItem)
	Task();
EndProcedure // DecorationVerticalSpacingClick

// -----------------------------------------------------------------------------
&AtClient
Procedure PayerOnChange(pItem)
	PayerOnChangeAtServer();
EndProcedure // PayerOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AccountingCurrencyOnChange(pItem)
	ChargingFolioParametersOnChangeAtServer();
EndProcedure // AccountingCurrencyOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PlannedPaymentMethodOnChange(pItem)
	ChargingFolioParametersOnChangeAtServer();
EndProcedure // PlannedPaymentMethodOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DescriptionOnChange(pItem)
	DescriptionOnChangeAtServer();
EndProcedure // DescriptionOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure LegacyAddressStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vParameters = New Structure("Country, Address, AddressType", GetBaseCountryAtServer(), TrimAll(Object.LegacyAddress), "Address");
	OpenForm("CommonForm.tcInputAddress", vParameters, pItem, Object.Ref, , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // LegacyAddressStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure PostAddressStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vParameters = New Structure("Country, Address, AddressType", GetBaseCountryAtServer(), TrimAll(Object.PostAddress), "Address");
	OpenForm("CommonForm.tcInputAddress", vParameters, pItem, Object.Ref, , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // PostAddressStartChoice

// ----------------------------------------------------------------------------------
&AtClient
Procedure AddressChoiceProcessing(pItem, pSelectedValue, pAdditionalData, pStandardProcessing)
	If pSelectedValue <> Undefined Then
		Object[pItem.Name] = pSelectedValue.Address;     
		If pItem.Name = "LegacyAddress" Then
			Object.StreetFiasId = pSelectedValue.StreetFiasId;   
		EndIf;
		pSelectedValue = pSelectedValue.Address;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountTypeOnChange(pItem)
	DiscountTypeOnChangeAtServer();
EndProcedure // DiscountTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountConfirmationTextOnChange(pItem)
	DiscountTypeOnChangeAtServer();
EndProcedure // DiscountConfirmationTextOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRatesApprovedOnChange(pItem)
	RoomRatesApprovedAppearance();
EndProcedure // RoomRatesApprovedOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DescriptionStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vCustomerList = GetCustomersListByName(TrimAll(pItem.EditText));
	If vCustomerList.Count() > 0 Then
		vNotifyDescription = New NotifyDescription("CustomerIsChoosen", ThisObject);
		vParams = New Structure("ValueList, MultipleChoice, Title", vCustomerList, False);
		OpenForm("CommonForm.mcChoiceValueList", vParams, ThisObject, UUID, , , vNotifyDescription);
	EndIf;
EndProcedure // DescriptionStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure TINStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vCustomerList = GetCustomersListByTIN(TrimAll(pItem.EditText));
	If vCustomerList.Count() > 0 Then
		vNotifyDescription = New NotifyDescription("CustomerIsChoosen", ThisObject);
		vParams = New Structure("ValueList, MultipleChoice, Title", vCustomerList, False);
		OpenForm("CommonForm.mcChoiceValueList", vParams, ThisObject, UUID, , , vNotifyDescription);
	EndIf;
EndProcedure // TINStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure AgentOnChange(pItem)
	BuildCommissionCollapsedTitle();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AgentCommissionTypeOnChange(pItem)
	BuildCommissionCollapsedTitle();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AgentCommissionOnChange(pItem)
	BuildCommissionCollapsedTitle();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AgentCommissionServiceGroupOnChange(pItem)
	BuildCommissionCollapsedTitle();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PostAddressOnChange(pItem)
	BuildAddressTitle();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure LegacyAddressOnChange(pItem)
	BuildAddressTitle();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ContactPersonsPhoneOnChange(pItem)
	vCurRow = Items.ContactPersons.CurrentData;
	If vCurRow <> Undefined Then
		vCurRow.Phone = SMS.GetValidPhoneNumber(vCurRow.Phone);
	EndIf;
EndProcedure // ContactPersonsPhoneOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ContactPersonsPhone2OnChange(pItem)
	vCurRow = Items.ContactPersons.CurrentData;
	If vCurRow <> Undefined Then
		vCurRow.Phone2 = SMS.GetValidPhoneNumber(vCurRow.Phone2);
	EndIf;
EndProcedure // ContactPersonsPhone2OnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PagesOnCurrentPageChange(pItem, pCurrentPage)
	If pCurrentPage.Name = "StatisticsGroup"  And Not StatusOfObject() Then
		BuildCustomerStatistics();
	EndIf;
	Title = pCurrentPage.Title;
EndProcedure // PagesOnCurrentPageChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PhoneOnChange(pItem)
	Object.Phone = SMS.GetValidPhoneNumber(Object.Phone);
EndProcedure // PhoneOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure IsIndividualOnChange(pItem)
	IsIndividualOnChangeAtServer();
EndProcedure // IsIndividualOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ParentOnChange(pItem)
	ParentOnChangeAtServer();
EndProcedure // ParentOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure IsInBlackListOnChange(pItem)
	If Object.IsInBlackList And Object.IsInWhiteList Then
		Object.IsInWhiteList = False;
	EndIf;
EndProcedure // IsInBlackListOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure IsInWhiteListOnChange(pItem)
	If Object.IsInWhiteList And Object.IsInBlackList Then
		Object.IsInBlackList = False;
	EndIf;
EndProcedure // IsInWhiteListOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure CountryOnChangeAtServer()
	If ValueIsFilled(Object.Country) Then
		vHotel = SessionParameters.CurrentHotel;
		If ValueIsFilled(vHotel) And ValueIsFilled(vHotel.Citizenship) Then
			If Object.Country <> vHotel.Citizenship Then
				If Not Object.NonResident Then
					Object.NonResident = True;
				EndIf;
			Else
				If Object.NonResident Then
					Object.NonResident = False;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // CountryOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure CountryOnChange(pItem)
	CountryOnChangeAtServer();
EndProcedure // CountryOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ContactPersonsClientOnChange(pItem)
	vCurRow = Items.ContactPersons.CurrentData;
	If vCurRow <> Undefined And ValueIsFilled(vCurRow.Client) Then
		If IsBlankString(vCurRow.Phone) Then
			vClientPhone = tcOnServer.cmGetAttributeByRef(vCurRow.Client, "Phone");
			If Not IsBlankString(vClientPhone) Then
				vCurRow.Phone = vClientPhone;
			EndIf;
		EndIf;
		If IsBlankString(vCurRow.Phone2) Then
			vClientPhone2 = tcOnServer.cmGetAttributeByRef(vCurRow.Client, "Fax");
			If Not IsBlankString(vClientPhone2) Then
				vCurRow.Phone2 = vClientPhone2;
			EndIf;
		EndIf;
		If IsBlankString(vCurRow.EMail) Then
			vClientEMail = tcOnServer.cmGetAttributeByRef(vCurRow.Client, "EMail");
			If Not IsBlankString(vClientEMail) Then
				vCurRow.EMail = vClientEMail;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ContactPersonsClientOnChange

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure NewTask(Command)
	If ValueIsFilled(Object.Ref) Then
		stParam = New Structure("SetParamObject", Object.Ref);
		OpenForm("Document.Message.Form.tcDocumentForm", stParam);
	EndIf;
EndProcedure // NewTask

// -----------------------------------------------------------------------------
&AtClient
Procedure SetAsDefault(pCommand)
	vCurData = Items.TableBoxBankAccounts.CurrentData;
	If vCurData <> Undefined Then
		Object.BankAccount = vCurData.Ref;
	EndIf;
EndProcedure // SetAsDefault

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenFolios(pCommand)
	If ValueIsFilled(Object.Ref) Then
		vParametersStructure = New Structure("IsNew, WasPosted, IsFormModified, ObjectRef", False, False, Modified, Object.Ref);
		OpenForm("CommonForm.tcFoliosForm", New Structure("ParametersStructure", vParametersStructure), ThisObject, UUID);
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Save customer first!'; ru='Сначала сохраните контрагента!'; de='Speichern Sie die Firma zuerst!'"));
	EndIf;
EndProcedure // OpenFolios

// -----------------------------------------------------------------------------
&AtClient
Procedure ContractSendInvitationToNewAgent(pCommand)
	vCheckResult = ContractSendInvitationToNewAgentAtServer();
	If vCheckResult.Repeat Then  
		vND = New NotifyDescription("AfterEnteringALine", ThisObject);   
		vTitle = tcOnServer.cmNStrAtServer("en = 'Enter your E-Mail address of the agent'; de = 'Geben Sie Ihre E-Mail-Adresse des Agenten'; ru = 'Введите E-Mail адрес агента'");
		ShowInputString(vND, "", vTitle, 0, False);
	Else
		tcCommonFunctionOnClientServer.TextMessage(vCheckResult.Message);
	EndIf;
EndProcedure // ContractSendInvitationToNewAgent

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionOpenCustomerReservationHistory(pCommand)
	// Check user rights to view reservations
	If RightsToOpenTheDocument("Reservation") Then
		OpenForm("Document.Reservation.Form.mcReservationListForm", New Structure("SelDocPeriod,SelCustomer,SelFilterStatus", Date(1, 1, 1), Object.Ref, "&ALL"), ThisObject, UUID);	
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'You do not have rights to open reservations!'; 
														|de = 'Sie haben keine Rechte, die Reservierungsliste zu öffnen!'; 
														|ru = 'Нет прав открывать список брони!'"));	
	EndIf;	
EndProcedure // ActionOpenCustomerReservationHistory

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionOpenCustomerAccommodationHistory(pCommand)
	// Check user rights to view accommodations
	If RightsToOpenTheDocument("Accommodation") Then
		OpenForm("Document.Accommodation.Form.mcAccommodationListForm", New Structure("Customer,SelFilterStatus", Object.Ref, 1), ThisObject, UUID);	
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'You do not have rights to open accommodations!'; 
														|de = 'Sie haben keine Rechte, die Unterbringungsliste zu öffnen!'; 
														|ru = 'Нет прав открывать список размещений!'"));	
	EndIf;	
EndProcedure // ActionOpenCustomerAccommodationHistory

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionOpenCustomerResourceReservationHistory(pCommand)
	// Check user rights to view resource reservations
	If RightsToOpenTheDocument("ResourceReservation") Then
		OpenForm("Document.ResourceReservation.Form.tcReservationListForm", New Structure("SelDocPeriod,SelCustomer,SelFilterStatus", Date(1, 1, 1), Object.Ref, "&ALL"), ThisObject, UUID);
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'You do not have rights to open reservations!'; 
														|de = 'Sie haben keine Rechte, die Reservierungsliste zu öffnen!'; 
														|ru = 'Нет прав открывать список брони!'"));	
	EndIf;
EndProcedure // ActionOpenCustomerResourceReservationHistory

// -----------------------------------------------------------------------------
&AtClient
Procedure LoadDefaultChargingRules(pCommand)
	LoadDefaultChargingRulesAtServer();
EndProcedure // LoadDefaultChargingRules

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure SetColor(pCommand)
	// Choose color
	vColorDlg =  New ColorChooseDialog;
	vColorDlg.Color = ItemColor;
	vColorDlg.Show(New NotifyDescription("SetColorAfterUserChoice", ThisObject))
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure ClearColor(pCommand)
	// Clear color
	ItemColor = Undefined;
	ItemColorIsSet = False;
	Items.FormSetColor.BackColor = Items.FormClearColor.BackColor;
EndProcedure // ClearColor

#EndRegion

#Region Private

// ----------------------------------------------------------------
&AtServer
Procedure BuildAccountingGroupCollapsedTitle(pObj = Undefined)
	vObj = pObj;
	If vObj = Undefined Then
		vObj = Object;
	EndIf;
	vTitle = NStr("en='Pays: '; ru='Платит: '; de='Zahler: '") + TrimAll(Payer) + 
			 ?(Payer = Enums.WhoPays.Customer, " " + TrimAll(vObj.Description) + ?(ValueIsFilled(vObj.Contract), ", " + TrimAll(vObj.Contract), ""), "") + 
	         NStr("en=' by '; ru=', '; de=', '") + TrimAll(vObj.PlannedPaymentMethod);
	Items.GroupAccounting.CollapsedRepresentationTitle = vTitle;
EndProcedure // BuildAccountingGroupCollapsedTitle

// ----------------------------------------------------------------
&AtServer
Procedure BuildAddressTitle(pObj = Undefined)
	vObj = pObj;
	If vObj = Undefined Then
		vObj = Object;
	EndIf;
	vTitle = "";
	vTitle = ?(IsBlankString(vObj.LegacyAddress),"",NStr("en = 'Billing:'; de = ' Rechnung:'; ru = 'Юр.адр:'")+TrimAll(vObj.LegacyAddress));
	If Not IsBlankString(vObj.PostAddress) And TrimAll(vObj.LegacyAddress) <> TrimAll(vObj.PostAddress) Then
		If Not IsBlankString(vTitle) Then
			vTitle = vTitle + "; ";
		EndIf;
		vTitle = vTitle + NStr("en = 'Shipping:'; de = 'Lieferanschrift:'; ru = 'Почт.адр:'")+TrimAll(vObj.PostAddress);
	EndIf;
	Items.GroupAddresses.CollapsedRepresentationTitle = vTitle;
EndProcedure

// ----------------------------------------------------------------
&AtServer
Procedure BuildCommissionCollapsedTitle(pObj = Undefined)
	vObj = pObj;
	If vObj = Undefined Then
		vObj = Object;
	EndIf;
	If ValueIsFilled(vObj.AgentCommissionType) Or vObj.AgentCommission <> 0 Then
		vTitle = NStr("en='Agent '; ru='Агент '; de='Agent '") + ?(ValueIsFilled(vObj.Agent), TrimAll(vObj.Agent), TrimAll(vObj.Description)) + ": " + TrimAll(vObj.AgentCommission) + " " + TrimAll(vObj.AgentCommissionType) + NStr("en = ' for '; de = ' für '; ru = ' за '") + ?(ValueIsFilled(vObj.AgentCommissionServiceGroup), TrimAll(vObj.AgentCommissionServiceGroup), NStr("en = 'all'; de = 'alle '; ru = 'все'"));
	Else
		vTitle = NStr("en = 'No commission'; de = 'Keine Kommission'; ru = 'Без комиссии'");
	EndIf;
	Items.GroupCommission.CollapsedRepresentationTitle = vTitle;
EndProcedure // BuildCommissionCollapsedTitle

// -----------------------------------------------------------------------------
&AtServer
Procedure FillTasksPresentation()
	TTasks = "";
	If ValueIsFilled(Object.Ref) Then
		vTasks = cmGetMessagesForObject(Object.Ref);
		For Each vTasksRow In vTasks Do
			TTasks = TTasks + "• " + TrimAll(vTasksRow.Remarks) + Chars.LF;
			If vTasks.IndexOf(vTasksRow) > 4 Then
				TTasks = TTasks + "• " + "..." + Chars.LF;
				Break;
			EndIf;
		EndDo;
	EndIf;
	TTasks = TrimAll(TTasks);
	Items.DecorationTasks.Title = TTasks;
	If IsBlankString(TTasks) Then
		Items.DecorationTasks.Visible = False;
	Else
		Items.DecorationTasks.Visible = True;
	EndIf;
EndProcedure // FillTasksPresentation

// -----------------------------------------------------------------------------
&AtClient
Procedure Task()
	stParam = New Structure("SetParamObject", Object.Ref);
	OpenForm("DataProcessor.Messages.Form.tcForm", stParam);
	Notify("DataProcessor.Messages.Form.Open", stParam);
EndProcedure // Task

// -----------------------------------------------------------------------------
&AtServer
Procedure DisableFieldsByCustomer()
	// Disabled fields if customer is filled
	If ValueIsFilled(SessionParameters.CurrentUser.Customer) Then
		// Customer attributes
		Items.AccountingCurrency.Enabled = False;
		Items.AccountingCurrency.OpenButton = False;
		Items.AccountingCurrency.ClearButton = False;
		Items.AccountingCurrency.ChoiceButton = False;
		Items.Agent.Enabled = False;
		Items.Agent.OpenButton = False;
		Items.Agent.ClearButton = False;
		Items.Agent.ChoiceButton = False;
		Items.AgentCommissionType.Enabled = False;
		Items.AgentCommissionType.OpenButton = False;
		Items.AgentCommissionType.ClearButton = False;
		Items.AgentCommissionType.ChoiceButton = False;
		Items.AgentCommission.Enabled = False;
		Items.AgentCommission.OpenButton = False;
		Items.AgentCommission.ClearButton = False;
		Items.AgentCommission.ChoiceButton = False;
		Items.AgentCommissionServiceGroup.Enabled = False;
		Items.AgentCommissionServiceGroup.OpenButton = False;
		Items.AgentCommissionServiceGroup.ClearButton = False;
		Items.AgentCommissionServiceGroup.ChoiceButton = False;
		Items.CustomerType.Enabled = False;
		Items.CustomerType.OpenButton = False;
		Items.CustomerType.ClearButton = False;
		Items.CustomerType.ChoiceButton = False;
		Items.Payer.Enabled = False;
		Items.PlannedPaymentMethod.Enabled = False;
		Items.PlannedPaymentMethod.OpenButton = False;
		Items.PlannedPaymentMethod.ClearButton = False;
		Items.PlannedPaymentMethod.ChoiceButton = False;
		Items.IsInBlackList.Enabled = False;
		Items.IsInWhiteList.Enabled = False;
		Items.DoNotPostCommission.Enabled = False;
		Items.ExternalCode.Enabled = False;
		// Charging rules
		Items.ChargingRules.ReadOnly = True;
		// Room rates
		Items.GroupRoomRates.Visible = False;
		Items.RoomRate.Enabled = False;
		Items.RoomRate.OpenButton = False;
		Items.RoomRate.ClearButton = False;
		Items.RoomRate.ChoiceButton = False;
		Items.RoomRateServiceGroup.Enabled = False;
		Items.RoomRateServiceGroup.OpenButton = False;
		Items.RoomRateServiceGroup.ClearButton = False;
		Items.RoomRateServiceGroup.ChoiceButton = False;
		Items.NoShowFeeTerms.Enabled = False;
		Items.NoShowFeeTerms.OpenButton = False;
		Items.NoShowFeeTerms.ClearButton = False;
		Items.NoShowFeeTerms.ChoiceButton = False;
		Items.DaysBeforeCheckIn.Enabled = False;
        Items.DaysAfterReservation.Enabled = False;
		Items.RoomRates.ReadOnly = True;
		Items.RoomRatesApproved.Enabled =False;
		Items.DiscountType.Enabled = False;
		Items.DiscountType.OpenButton = False;
		Items.DiscountType.ClearButton = False;
		Items.DiscountType.ChoiceButton = False;
		Items.DiscountConfirmationText.Enabled = False;
		// Contracts
		Items.Contract.Enabled = False;
		Items.Contract.OpenButton = False;
		Items.Contract.ClearButton = False;
		Items.Contract.ChoiceButton = False;
		Items.AgentCommissionContract.Enabled = False;
		Items.AgentCommissionContract.OpenButton = False;
		Items.AgentCommissionContract.ClearButton = False;
		Items.AgentCommissionContract.ChoiceButton = False;
        Items.TableBoxContracts.ReadOnly = True;
		// Statistics
		Items.StatisticsGroup.Visible = False;
	EndIf;
EndProcedure // DisableFieldsByCustomer

// -----------------------------------------------------------------------------
&AtServer
Function  GetTasksStructure()
	vTasksStructure = New Structure();
	If ValueIsFilled(Object.Ref) Then
		vTasks = cmGetMessagesForObject(Object.Ref);
		vNumber = 0;
		For Each vTasksRow In vTasks Do
			vTasksStructure.Insert(TrimAll("Tasks" + vNumber), New Structure("PopUp, Remarks", vTasksRow.PopUp, vTasksRow.Remarks));
			vNumber = vNumber + 1;
		EndDo;
	EndIf;
	Return vTasksStructure;
EndFunction // GetTasksStructure

// ----------------------------------------------------------------
&AtServer
Procedure OnOpenForm(pObj = Undefined)
	// Check paramters
	vObj = pObj;
	vUseParamterObject = True;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParamterObject = False;
	EndIf;
	If vObj.IsNew() Then
		// Fill attributes with default values
		If Not ValueIsFilled(vObj.Author) Then
			vObj.pmFillAttributesWithDefaultValues();
		EndIf;
	EndIf;
	If vObj.ChargingRules.Count() > 0 Then
		Payer = Enums.WhoPays.Customer;
	Else
		Payer = Enums.WhoPays.Guest;
	EndIf;
	// Check user rights to edit charging rules
	If Not cmCheckUserPermissions("HavePermissionToEditChargingRules") Then
		Items.ChargingRules.ReadOnly = True;
	EndIf;
	// Check user rights to edit discounts
	If Not cmCheckUserPermissions("HavePermissionToAddManualDiscounts") Then
		Items.DiscountType.Enabled = False;
		Items.DiscountConfirmationText.Enabled = False;
	EndIf;
	// Check user rights to edit manager
	If Not cmCheckUserPermissions("HavePermissionToEditCustomerAndGuestGroupManagers") Then
		Items.ReservationManager.ReadOnly = True;
		Items.MICEManager.ReadOnly = True;
	EndIf;
	// Check user rights to edit room rates
	If Not cmCheckUserPermissions("HavePermissionToApproveRoomRates") Then
		Items.RoomRatesApproved.Enabled = False;
	Else
		Items.RoomRatesApproved.Enabled = True;
	EndIf;
	RoomRatesApprovedAppearance(vObj);
	// Group titles
	BuildCommissionCollapsedTitle(vObj);
	BuildAccountingGroupCollapsedTitle(vObj);
	BuildAddressTitle(vObj);
	// Color
	vColor = GetColor(vObj);
	If vColor <> Undefined Then
		ItemColor = vColor;
		ItemColorIsSet = True;
		Items.FormSetColor.BackColor = vColor;
	Else
		ItemColor = Undefined;
		ItemColorIsSet = False;
	EndIf;
	// Set object value
	If Not vUseParamterObject Then
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure // OnOpenForm

// -----------------------------------------------------------------------------
&AtServer
Procedure RoomRatesApprovedAppearance(pObj = Undefined)
	// Check paramters
	vObj = pObj;
	If pObj = Undefined Then
		vObj = Object;
	EndIf;
	If vObj.RoomRatesApproved Then
		Items.DiscountType.ReadOnly = True;
		Items.RoomRate.ReadOnly = True;
		Items.RoomRateServiceGroup.ReadOnly = True;
		Items.RoomRates.ReadOnly = True;
		Items.NoShowFeeTerms.ReadOnly = True;
		Items.DaysBeforeCheckIn.ReadOnly = True;
		Items.DaysAfterReservation.ReadOnly = True;
		Items.DefaultContracts.ReadOnly = True;
		Items.TableBoxContracts.ReadOnly = True;
		Items.AccountingCurrency.ReadOnly = True;
		Items.Agent.ReadOnly = True;
		Items.AgentCommission.ReadOnly = True;
		Items.AgentCommissionType.ReadOnly = True;
		Items.AgentCommissionServiceGroup.ReadOnly = True;
		Items.AgentCommissionContract.ReadOnly = True;
		Items.DoNotPostCommission.Enabled = False;
	Else
		Items.DiscountType.ReadOnly = False;
		Items.RoomRate.ReadOnly = False;
		Items.RoomRateServiceGroup.ReadOnly = False;
		Items.RoomRates.ReadOnly = False;
		Items.NoShowFeeTerms.ReadOnly = False;
		Items.DaysBeforeCheckIn.ReadOnly = False;
		Items.DaysAfterReservation.ReadOnly = False;
		Items.DefaultContracts.ReadOnly = False;
		Items.TableBoxContracts.ReadOnly = False;
		Items.AccountingCurrency.ReadOnly = False;
		Items.Agent.ReadOnly = False;
		Items.AgentCommission.ReadOnly = False;
		Items.AgentCommissionType.ReadOnly = False;
		Items.AgentCommissionServiceGroup.ReadOnly = False;
		Items.AgentCommissionContract.ReadOnly = False;
		Items.DoNotPostCommission.Enabled = True;
	EndIf;
EndProcedure // RoomRatesApprovedAppearance

// -----------------------------------------------------------------------------
&AtServer
Procedure PayerOnChangeAtServer(pObj = Undefined)
	// Check parameters
	vUseParamterObject = True;
	vObj = pObj;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParamterObject = False;
	EndIf;
	vHotel = SessionParameters.CurrentHotel;
	If Payer = Enums.WhoPays.Guest Then
		If ValueIsFilled(vHotel) Then
			vObj.PlannedPaymentMethod = vHotel.PlannedPaymentMethod;
		Else
			vObj.PlannedPaymentMethod = Catalogs.PaymentMethods.EmptyRef();
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Default hotel is not filled!';ru='Не выбрана гостиница по умолчанию!';de='Kein Hotel als Standard-Einstellung ist gewählt!'"));
		EndIf;
		vObj.ChargingRules.Clear();
	ElsIf Payer = Enums.WhoPays.Customer Then
		If ValueIsFilled(vHotel) Then
			vObj.PlannedPaymentMethod = vHotel.PaymentMethodForCustomerPayments;
			ChargingFolioParametersOnChangeAtServer(vObj);
		Else
			vObj.PlannedPaymentMethod = Catalogs.PaymentMethods.EmptyRef();
		EndIf;
		LoadDefaultChargingRulesAtServer(vObj);
	EndIf;
	BuildAccountingGroupCollapsedTitle(vObj);
	If Not vUseParamterObject Then
		// Set object value
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure // PayerOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadDefaultChargingRulesAtServer(pObj = Undefined)
	// Check paramters
	vUseParamterObject = True;
	vObj = pObj;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParamterObject = False;
	EndIf;
	vHotel = SessionParameters.CurrentHotel;
	If ValueIsFilled(vHotel) Then
		vObj.ChargingRules.Clear();
		vObj.pmCreateFolios(vHotel, CurrentSessionDate());
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Default hotel is not filled!';ru='Не выбрана гостиница по умолчанию!';de='Kein Hotel als Standard-Einstellung ist gewählt!'"));
	EndIf;
	If Not vUseParamterObject Then
		// Set object value
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure // LoadDefaultChargingRulesAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ChargingFolioParametersOnChangeAtServer(pObj = Undefined)
	// Check parameters
	vObj = pObj;
	If pObj = Undefined Then
		vObj = Object;
	EndIf;
	If Payer = Enums.WhoPays.Customer Then
		If ValueIsFilled(vObj.PlannedPaymentMethod) Then
			If vObj.ChargingRules.Count() > 0 Then
				If Not vObj.ChargingRules.Get(0).ChargingFolio.IsEmpty() Then
					vFolioObj = vObj.ChargingRules.Get(0).ChargingFolio.GetObject();
					vFolioObj.PaymentMethod = vObj.PlannedPaymentMethod;
					vFolioObj.FolioCurrency = vObj.AccountingCurrency;
					Try
						vFolioObj.Write();
					Except
						tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to change planned payment method! Please try again.';ru='Не удалось сохранить планируемый способ оплаты! Повторите изменение еще раз.';de='Die geplante Zahlungsmethode konnte nicht gespeichert werden! Wiederholen Sie die Änderung noch einmal.'"));
					EndTry;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	BuildAccountingGroupCollapsedTitle(vObj);
EndProcedure // ChargingFolioParametersOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure DescriptionOnChangeAtServer(pObj = Undefined)
	// Check parameters
	vObj = pObj;
	vUseParameterObject = True;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParameterObject = False;
	EndIf;
	If vObj.IsNew() Then
		If Not IsBlankString(vObj.Description) And IsBlankString(vObj.LegacyName) Then
			vObj.LegacyName = TrimAll(vObj.Description);
		EndIf;
	EndIf;
	If Not vUseParameterObject Then
		// Set object value
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure // DescriptionOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetBaseCountryAtServer()
	vCountry = Undefined;
	If ValueIsFilled(SessionParameters.CurrentHotel) Then
		vCountry = SessionParameters.CurrentHotel.Citizenship;
	EndIf;
	Return vCountry;
EndFunction // GetBaseCountryAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure DiscountTypeOnChangeAtServer(pObj = Undefined)
	// Check parameters
	vUseParameterObject = True;
	vObj = pObj;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParameterObject = False;
	EndIf;
	vDiscountType = vObj.DiscountType;
	vDiscountConfirmationText = vObj.DiscountConfirmationText;
	If Not ValueIsFilled(vDiscountType) Then
		pDiscountConfirmationText = "";
	EndIf;
	If Not vUseParameterObject Then
		// Set object value
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure // DiscountTypeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeWriteEnd(QuestionResult, AdditionalParameters) Export
	If Not QuestionResult = DialogReturnCode.Cancel Then
		Write(New Structure("Success"));
	EndIf;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
&AtServer
Function BeforeWriteServer(rCancel, pObj = Undefined)
	// Check paramters
	vObj = pObj;
	vUseParamterObject = True;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParamterObject = False;
	EndIf;
	// Save state
	WasNew = vObj.IsNew();
	// Check customer attributes
	vMessage = "";
	vAttributeInErr = "";
	rCancel = vObj.pmCheckCustomerAttributes(vMessage, vAttributeInErr);
	If rCancel Then
		WriteLogEvent(NStr("en='Catalog.Write';ru='Справочник.Запись';de='Catalog.Write'"), EventLogLevel.Warning, vObj.Metadata(), vObj.Ref, NStr(vMessage));
		tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage));
		If Not IsBlankString(vAttributeInErr) Then
			CurrentItem = Items[vAttributeInErr];
		EndIf;
	EndIf;
	// Check TIN for the customer
	If Not rCancel And Not vObj.NonResident Then
		vEmptyTINIsAllowed = cmCheckUserPermissions("HavePermissionToCreateCustomersWithoutTIN");
		If Not IsBlankString(vObj.TIN) Then
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	Customers.Ref AS Customer
			|FROM
			|	Catalog.Customers AS Customers
			|WHERE
			|	Customers.TIN = &qTIN
			|	AND (Customers.KPP = &qKPP
			|			OR &qKPPIsEmpty)
			|	AND NOT Customers.DeletionMark
			|	AND NOT Customers.IsFolder
			|
			|ORDER BY
			|	Customers.CreateDate";
			vQry.SetParameter("qTIN", TrimAll(vObj.TIN));
			vQry.SetParameter("qKPP", TrimAll(vObj.KPP));
			vQry.SetParameter("qKPPIsEmpty", IsBlankString(TrimAll(vObj.KPP)));
			vRes = vQry.Execute().Unload();
			vNumberOfCustomers = vRes.Count();
			If Not WasNew Then
				For Each vResRow In vRes Do
					If vResRow.Customer = vObj.Ref Then
						vNumberOfCustomers = vNumberOfCustomers - 1;
					EndIf;
				EndDo;
			EndIf;
			If vNumberOfCustomers > 0 Then
				vMessage = NStr("ru='" + vNumberOfCustomers + " контрагент(ов) найдено с тем же ИНН (" + TrimAll(vObj.TIN) + ")!';
				                |de='" + vNumberOfCustomers + " customer(s) with the same TIN (" + TrimAll(vObj.TIN) + ") are found!';
				                |en='" + vNumberOfCustomers + " customer(s) with the same TIN (" + TrimAll(vObj.TIN) + ") are found!'");
				For Each vResRow In vRes Do
					If vResRow.Customer <> vObj.Ref Then
						vStrCode = NStr("en='Code:';ru='Код:';de='Code:'");
						vMessage = vMessage + Chars.LF + TrimAll(vResRow.Customer.Description) + " (" + vStrCode + " " + TrimAll(vResRow.Customer.Code) + ")";
					EndIf;
				EndDo;
				If Not vEmptyTINIsAllowed And WasNew Then
					rCancel = True;
					vUM = New UserMessage();
					vUM.SetData(vObj);
					vUM.Field = "TIN";
					vUM.Text = vMessage;
					vUM.Message();
					Return "";
				Else
					Return vMessage;
				EndIf;
			EndIf;
		Else
			If Not vEmptyTINIsAllowed And WasNew And Not vObj.IsIndividual Then
				rCancel = True;
				vMessage = NStr("en='Customer TIN should be filled!'; ru='ИНН контрагента должен быть указан!'; de='TIN der Firma muss angegeben werden!'");
				vUM = New UserMessage();
				vUM.SetData(vObj);
				vUM.Field = "TIN";
				vUM.Text = vMessage;
				vUM.Message();
				Return "";
			EndIf;
		EndIf;
	EndIf;
	Return "";
EndFunction // BeforeWriteServer

// -----------------------------------------------------------------------------
&AtServer
Function AfterWriteServer()
	// Get object value
	vObj = FormAttributeToValue("Object");
	// Save changes to the client change history
	vObj.pmWriteToCustomerChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
	// Update customer attribute for all folios in the charging rules if was new
	vErrInfo = "";
	If WasNew Then
		For Each vRow In vObj.ChargingRules Do
			vFolio = vRow.ChargingFolio;
			If ValueIsFilled(vFolio) Then
				vFolioObj = vFolio.GetObject();
				If Not ValueIsFilled(vFolioObj.Customer) Then
					vFolioObj.Customer = vObj.Ref;
					Try
						vFolioObj.Write();
					Except
						vErrInfo = ErrorInfo();
						WriteLogEvent(NStr("en='Catalog.Customers.AfterWrite';ru='Справочник.Контрагенты.ПослеЗаписи';de='Catalog.Customers.AfterWrite'"), EventLogLevel.Warning, vObj.Metadata(), vObj.Ref, cmGetRootErrorDescription(vErrInfo));
					EndTry;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	// Reset write flag
	WasNew = False;
	Return vErrInfo;
EndFunction // AfterWriteServer

// -----------------------------------------------------------------------------
&AtServer
Function GetCustomersListByName(pName)
	vCustomerList = New ValueList();
	vDadataToken = Constants.DadataToken.Get();
	If Not IsBlankString(vDadataToken) Then
		Try
			If StrLen(TrimAll(pName)) > 3 Then
				// Call API
				vListArr = cmGetDadataArray(TrimAll(pName), vDadataToken, "party");
				For n = 1 To vListArr.Count()-1 Do
					vCustomerList.Add(vListArr[n], vListArr[n-1]);
					n = n + 1;
				EndDo;
			EndIf;
		Except
			WriteLogEvent(NStr("en='GetDataWebService';ru='ПолучениеДанныхВебсервиса';de='GetDataWebService'"), EventLogLevel.Error, , , NStr("en='Error getting customer data: ';ru='Ошибка получения контрагента: ';de='Fehler beim Abrufen von Firmadaten: '") + ErrorDescription());
		EndTry;
	EndIf;
	Return vCustomerList;
EndFunction // GetCustomersListByName

// -----------------------------------------------------------------------------
&AtServer
Function GetCustomersListByTIN(pTIN)
	vCustomerList = New ValueList();
	vDadataToken = Constants.DadataToken.Get();
	If Not IsBlankString(vDadataToken) Then
		Try
			If StrLen(TrimAll(PTIN)) >= 10 Then
				// Call API
				vListArr = cmGetDadataArray(TrimAll(pTIN), vDadataToken, "party");
				For n = 1 To vListArr.Count()-1 Do
					vCustomerList.Add(vListArr[n], vListArr[n-1]);
					n = n + 1;
				EndDo;
			EndIf;
		Except
			WriteLogEvent(NStr("en='GetDataWebService';ru='ПолучениеДанныхВебсервиса';de='GetDataWebService'"), EventLogLevel.Error, , , NStr("en='Error getting customer data: ';ru='Ошибка получения контрагента: ';de='Fehler beim Abrufen von Firmadaten: '") + ErrorDescription());
		EndTry;
	EndIf;
	Return vCustomerList;
EndFunction // GetCustomersListByTIN

// -----------------------------------------------------------------------------
&AtClient
Procedure CustomerIsChoosen(pListItem, pAdditionalParameters) Export
	If pListItem <> Undefined Then
		vText = pListItem.Value;
		vStrData = DecomposeCustomerStr(vText);
		FillPropertyValues(Object, vStrData);
		If vStrData.Status = "LIQUIDATING" Then	
			Items.Description.BackColor = WebColors.Yellow;
			Title = Title + NStr("en=' - LIQUIDATING'; ru=' - ЛИКВИДИРУЕТСЯ';de=' - LIQUIDIEREN'");
		ElsIf vStrData.Status = "LIQUIDATED" Then	
			Items.Description.BackColor = WebColors.Red;
			Title = Title + NStr("en=' - LIQUIDATED'; ru=' - ЛИКВИДИРОВАНА';de=' - PAUSCHALER'");
		Else
			Items.Description.BackColor = Items.Code.BackColor;
			Title = NStr("en='Customer'; ru='Контрагент'; de='Firma'");
		EndIf;
	EndIf;
EndProcedure // IdentityDocumentIssuedByIsChoosen

// -----------------------------------------------------------------------------
&AtClient
Function DecomposeCustomerStr(Val pStr)
	vDescription	= "";
	vLegacyName		= "";
	vINN          	= "";
	vKPP           	= "";
	vOGRN           = "";
	vLegacyAddress 	= "";
	vDirector       = "";
	vPosition       = "";
	vStatus         = "";
	
	vArrayStr = New Array();
	While True Do
		n = Find(pStr,";");
		If n = 0 Then
			vArrayStr.Add(pStr);
			Break;
		EndIf;
		vArrayStr.Add(Left(pStr,n-1));
		pStr = Mid(pStr,n+1);
	EndDo;
	
	vItmCount = vArrayStr.Count();   
	
	If vItmCount > 0 Then
		vDescription = Upper(TrimAll(vArrayStr[0]));
		vDescription = StrReplace(vDescription, "ООО ", "");
		vDescription = StrReplace(vDescription, "ОАО ", "");
		vDescription = StrReplace(vDescription, "ЗАО ", "");
		vDescription = StrReplace(vDescription, "ИП ", "");
		vDescription = StrReplace(vDescription, "ФГУП ", "");
		vDescription = StrReplace(vDescription, """", "");
	EndIf;
	If vItmCount > 1 Then
		vINN = TrimAll(vArrayStr[1]);
	EndIf;
	If vItmCount > 2 Then
		vKPP = TrimAll(vArrayStr[2]);
	EndIf;
	If vItmCount > 3 Then
		vOGRN = TrimAll(vArrayStr[3]);
	EndIf;
	If vItmCount > 4 Then
		vLegacyAddress = TrimAll(vArrayStr[4]);
	EndIf;
	If vItmCount > 5 Then
		vLegacyName = TrimAll(vArrayStr[5]);
	EndIf;
	If vItmCount > 6 Then
		vDirector = TrimAll(vArrayStr[6]);
	EndIf;
	If vItmCount > 7 Then
		vPosition = TrimAll(vArrayStr[7]);
	EndIf;
	If vItmCount > 8 Then
		vStatus = TrimAll(vArrayStr[8]);
	EndIf;
	
	vStrData = New Structure;
	vStrData.Insert("Description",   vDescription);
	vStrData.Insert("LegacyName",    vLegacyName);
	vStrData.Insert("TIN",           vINN);
	vStrData.Insert("KPP",           vKPP);
	vStrData.Insert("OGRN",          vOGRN);
	vStrData.Insert("LegacyAddress", vLegacyAddress);
	vStrData.Insert("Director",      vDirector);
	vStrData.Insert("Position",      vPosition);
	vStrData.Insert("Status",        vStatus);
	
	Return vStrData;
EndFunction //  DecomposeCustomerStr

// -----------------------------------------------------------------------------
&AtServer
Procedure ParentOnChangeAtServer()
	If ValueIsFilled(Object.Ref) And ValueIsFilled(SessionParameters.CurrentHotel) And 
	   ValueIsFilled(SessionParameters.CurrentHotel.IndividualsCustomer) And 
	   Object.Ref = SessionParameters.CurrentHotel.IndividualsCustomer Then
		If Not Object.IsIndividual Then
			Object.IsIndividual = True;
		EndIf;
	Else
		vIndividualsFolder = Constants.IndividualsFolder.Get();
		If Not ValueIsFilled(vIndividualsFolder) Then
			vIndividualsFolder = Catalogs.Customers.IndividualsFolder;
		EndIf;
		If ValueIsFilled(Object.Parent) And (Object.Parent = vIndividualsFolder Or Object.Parent.BelongsToItem(vIndividualsFolder)) Then
			If Not Object.IsIndividual Then
				Object.IsIndividual = True;
			EndIf;
		ElsIf Not ValueIsFilled(Object.Parent) Or ValueIsFilled(Object.Parent) And Not (Object.Parent = vIndividualsFolder Or Object.Parent.BelongsToItem(vIndividualsFolder)) Then
			If Object.IsIndividual Then
				Object.IsIndividual = False;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ParentOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function ContractSendInvitationToNewAgentAtServer()
	vCheckResult = New Structure("Repeat,Message",False,"");     
	//SEND E-MAIL!!!
	vHotelRef = SessionParameters.CurrentHotel;
	vLanguage = Object.Language;
	If Not ValueIsFilled(vLanguage) Then
		vLanguage = SessionParameters.CurrentLanguage;
	EndIf;
	// Get external system interactions
	vIntegration = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsHotelOnlineBooking(vHotelRef);
	vModulePath = "";
	vMessage = "";
	vIntegrationFillingError = False;
	If Not vIntegration = Undefined Then
		vModulePath = vIntegration.HttpAddress;
	Else
		vIntegrationFillingError = True;
		vMessage = vMessage + " - " + NStr("en = 'It is necessary to create interaction with an external system with the integration type ""1C: Hotel online booking""'; de = 'Es ist notwendig, eine Interaktion mit einem externen System mit der Integrationsart ""1C: Hotel online booking"" zu erstellen.'; ru = 'Необходимо создать взаимодействие с внешней системой с типом интеграции ""1C:Hotel online booking""'")+Chars.LF;
	EndIf;
	vTemplate = vHotelRef.NewAgentInvitationMessageTemplate;
	
	vTemplateError = False;
	vEMailFiilingError = False;
	vModuleLinkFillingError = False;
	If Not ValueIsFilled(Object.EMail) Then
		vEMailFiilingError = True;
		vMessage = vMessage + " - " + NStr("en='You must fill the customer E-Mail.'; de='Sie müssen die Firma E-Mail zu füllen.'; ru='Необходимо заполнить у контрагента поле E-Mail.'")+Chars.LF;
	EndIf;
	If Not ValueIsFilled(vModulePath) Then
		vModuleLinkFillingError = True;
		vMessage = vMessage + " - " + NStr("en = 'You must fill out the path to the Online Booking module. You can find the ""Link to the module"" field in the Integration-> Interactions with external systems menu, then select the integration with the type ""1C: Hotel online booking""'; de = 'Sie müssen den Pfad zum Online-Buchungsmodul ausfüllen. Sie finden das Feld ""Link zum Modul"" im Menü Integration-> Interaktionen mit externen Systemen und wählen dann die Integration mit dem Typ ""1C: Hotel online booking"".'; ru = 'Необходимо заполнить путь к модулю Онлайн-Бронирования. Поле ""Ссылка на модуль"" Можете найти в меню Интеграции->Взаимодействия с внешними системами, далее выбрать интеграцию с типом ""1C:Hotel online booking""'")+Chars.LF;
	EndIf;
	If Not ValueIsFilled(vTemplate) Then
		vTemplateError = True;
		vMessage = vMessage + " - " + NStr("en='You must fill in the ""New agent invitation message template"". This field can be found in the settings of the current tab Hotels ""Constants 5""'; de='Sie müssen in der füllen ""Neue Mittel Einladung Nachrichtenvorlage"". Dieses Feld kann in den Einstellungen der aktuellen Registerkarte Hotels ""Konstanten 5"" gefunden werden'; ru='Необходимо заполнить поле ""Шаблон приглашения для нового агента"". Это поле можете найти в настройках текущей Гостиницы на вкладке ""Константы 5""'")+Chars.LF;
	EndIf;	
	If Not vEMailFiilingError And Not vTemplateError And Not vModuleLinkFillingError And Not vIntegrationFillingError Then
		If ValueIsFilled(Object.EMail) Then
			If ValueIsFilled(vModulePath) Then
				// Send e-mail
				If ValueIsFilled(vTemplate) Then
					vModulePath = TrimAll(vModulePath);
					If Left(vModulePath, 7) <> "http://" Then
						vModulePath = "http://"+vModulePath;
					EndIf;
					If Right(vModulePath, 1) <> "/" Then
						vModulePath = vModulePath + "/";
					EndIf;
					vEMailsList = cmParseEMailAddress(Object.EMail);
					For Each vEMailItem In vEMailsList Do
						vEmail = vEMailItem.Value;
						vLink = vModulePath+"areg.php?email="+TrimAll(vEmail)+"&hcode="+TrimAll(vHotelRef.Code);
						vText = "";
						If ValueIsFilled(vTemplate.HTMLTextRu) Or ValueIsFilled(vTemplate.HTMLTextEn) Or ValueIsFilled(vTemplate.HTMLTextDe) Then
							vText = SMS.GetHTMLTextByLanguage(vTemplate, vLanguage);
						EndIf;
						If IsBlankString(vText) Then
							vText = SMS.GetSMSTextByLanguage(vTemplate, vLanguage);
						EndIf;
						vText = StrReplace(vText, "&email", TrimAll(vEmail));
						vText = StrReplace(vText, "&ContractNumber", "");
						vText = StrReplace(vText, "&ContractDesc", "");
						vText = StrReplace(vText, "&CustomerDesc", TrimAll(Object.Description));
						vText = StrReplace(vText, "&HotelDesc", TrimAll(vHotelRef.Description));
						vText = StrReplace(vText, "&RegLink", vLink);
						rErrorMessage = "";
						If Not JobsScheduled.cmSendTextByEMail(cmNStr(vTemplate.Description, vLanguage), TrimAll(vText), TrimAll(vEmail), False, rErrorMessage) Then
							vCheckResult.Message = cmNStr("ru='Сообщение не отправлено!'; en='The message was not sent'; de='The message was not sent'", vLanguage)+Chars.LF+rErrorMessage;
							vError = cmNStr("ru='Ошибка отправки E-Mail! '; en='E-Mail sending failed! '; de='E-Mail sending failed! '", vLanguage)+rErrorMessage;
							WriteLogEvent(NStr("en='New agent registration'; de='New agent registration'; ru='Регистрация нового агента'"), EventLogLevel.Error, , , vError);
							Return vCheckResult;
						Else
							// Try to update existing mapping or create new one
							vMgrObj = InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
							vMgrObj.Hotel = vHotelRef;
							vMgrObj.ExternalSystemCode = "1CBITRIX";
							vMgrObj.ObjectTypeName = "Customers";
							vMgrObj.ObjectExternalCode = TrimAll(vEmail);
							vMgrObj.ObjectRef = Object.Ref;
							vMgrObj.Write(True);
							
							vCheckResult.Message = cmNStr("ru='Сообщение отправлено!'; en='The message was sent'; de='Die Nachricht wurde gesendet'", vLanguage);
							WriteLogEvent(NStr("en='New agent registration'; de='New Agentenregistrierung'; ru='Регистрация нового агента'"), EventLogLevel.Information, , , 
							cmNStr("ru='Сообщение отправлено!'; en='The message was sent'; de='Die Nachricht wurde gesendet'", vLanguage));
							Return vCheckResult;
						EndIf;
						Break;
					EndDo;
				Else
					vError = NStr("en='E-Mail sending failed! Template not found'; de='EMail Senden fehlgeschlagen! Template nicht gefunden'; ru='Ошибка отправки E-Mail! Шаблон сообщения не найден'");
					vCheckResult.Message = cmNStr("ru='Сообщение не отправлено!'; en='The message was not sent'; de='Die Nachricht wurde nicht gesendet'", vLanguage)+Chars.LF+vError;
					WriteLogEvent(NStr("en='New agent registration'; de='New Agentenregistrierung'; ru='Регистрация нового агента'"), EventLogLevel.Error, , , vError);
					Return vCheckResult;
				EndIf;
			Else
				vError = NStr("en='E-Mail sending failed! Onlinebooking module path is not filled'; de='EMail Senden fehlgeschlagen! Online Buchen Modulpfad nicht gefüllt ist'; ru='Ошибка отправки E-Mail! Не указан путь к модулю Онлайн Бронирования'");
				vCheckResult.Message = cmNStr("ru='Сообщение не отправлено!'; en='The message was not sent'; de='Die Nachricht wurde nicht gesendet'", vLanguage)+Chars.LF+vError;
				WriteLogEvent(NStr("en='New agent registration'; de='New Agentenregistrierung'; ru='Регистрация нового агента'"), EventLogLevel.Error, , , vError);
				Return vCheckResult;
			EndIf;
		Else
			vError = NStr("en='E-Mail sending failed! Customer e-mail address is empty'; de='EMail Senden fehlgeschlagen! Firma EMail Adresse ist leer'; ru='Ошибка отправки E-Mail! E-Mail адрес не заполнен'");
			vCheckResult.Message = cmNStr("ru='Сообщение не отправлено!'; en='The message was not sent'; de='Die Nachricht wurde nicht gesendet'", vLanguage)+Chars.LF+vError;
			WriteLogEvent(NStr("en='New agent registration'; de='New Agentenregistrierung'; ru='Регистрация нового агента'"), EventLogLevel.Error, , , vError);
			vCheckResult.Repeat = True;
			Return vCheckResult;
		EndIf;
	Else
		vCheckResult.Message = cmNStr("ru='Сообщение не отправлено!'; en='The message was not sent'; de='Die Nachricht wurde nicht gesendet'", vLanguage)+Chars.LF+vMessage;
		WriteLogEvent(NStr("en='New agent registration'; de='New Agentenregistrierung'; ru='Регистрация нового агента'"), EventLogLevel.Error, , , vMessage);
		Return vCheckResult;
	EndIf;
EndFunction // ContractSendInvitationToNewAgentAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure  AfterEnteringALine(pNewEMail, ExtaParams)
	If ValueIsFilled(pNewEMail) Then
		vCustObj = Object.Owner.GetObject();
		vCustObj.EMail = pNewEMail;	
		vCustObj.Write();
		ContractSendInvitationToNewAgentAtServer();
	EndIf;
EndProcedure // AfterEnteringALine

// -----------------------------------------------------------------------------
&AtServer
Function StatusOfObject(pObj = Undefined)
	// Check parameters
	vObj = pObj;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
	EndIf;
	Return vObj.IsNew();
EndFunction // StatusOfObject

// -----------------------------------------------------------------------------
&AtServer
Procedure BuildCustomerStatistics(pObj = Undefined)
	 // Check parameters
	vUseParameterObject = True;
	vObj = pObj;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParameterObject = False;
	EndIf;
	// Get type of revenue sums
	vWithVAT = True;
	If ValueIsFilled(SessionParameters.CurrentHotel) Then
		vWithVAT = SessionParameters.CurrentHotel.ShowSalesInReportsWithVAT;
	EndIf;
	// 1. Get customer number of check-ins
	vNumberOfCheckIns = vObj.pmCountNumberOfCheckIns();
	// 2. Get customer number of nights
	vNumberOfNights = vObj.pmCountNumberOfNights();
	// 3. Get customer reservation statistics
	vResStats = vObj.pmGetCustomerReservationStatistics();
	// 4. Get customer revenue statistics
	vRevenues = vObj.pmGetCustomerRevenueStatistics();
	// 5. Get customer last accommodation
	vLastAcc = vObj.pmGetCustomerLastAccommodation();
	// 6. Get customer first accommodation
	vFirstAcc = vObj.pmGetCustomerFirstAccommodation();
	// Clear statistics table
	TableBoxStatistics.Clear();
	// Customer full name
	vRow = TableBoxStatistics.Add();
	vRow.Item = ?(IsBlankString(vObj.LegacyName), TrimAll(vObj.Description), TrimAll(vObj.LegacyName));
	vRow.IsFirstRow = True;
	vRow.IsHeaderRow = True;
	// Fill statistics table
	vRow = TableBoxStatistics.Add();
	vRow.Item = NStr("en='STATS';ru='СТАТИСТИКА';de='STATISTIK'");
	vRow.IsFirstRow = False;
	vRow.IsHeaderRow = True;
	// Check-ins
	vRow = TableBoxStatistics.Add();
	vRow.Item = NStr("en='  Check-ins';ru='  Заездов';de='  Anreisen'");
	vRow.Value = Format(vNumberOfCheckIns, "ND=10; NFD=0; NZ=; NG=");
	vRow.IsFirstRow = False;
	vRow.IsHeaderRow = False;
	// Nights
	vRow = TableBoxStatistics.Add();
	vRow.Item = NStr("en='  Nights';ru='  Ночей';de='  Nächte'");
	vRow.Value = Format(vNumberOfNights, "ND=10; NFD=0; NZ=; NG=");
	vRow.IsFirstRow = False;
	vRow.IsHeaderRow = False;
	// Reservation statistics
	For Each vResRow In vResStats Do
		vRow = TableBoxStatistics.Add();
		vRow.Item = "  " + TrimAll(vResRow.ReservationStatus);
		vRow.Value = Format(vResRow.Count, "ND=10; NFD=0; NZ=; NG=");
		vRow.IsFirstRow = False;
		vRow.IsHeaderRow = False;
	EndDo;
	// Revenue
	vRow = TableBoxStatistics.Add();
	vRow.Item = NStr("en='REVENUE';ru='ДОХОД';de='ERLÖS'");
	vRow.IsFirstRow = False;
	vRow.IsHeaderRow = True;
	// Revenue statistics
	For Each vRevRow In vRevenues Do
		vRow = TableBoxStatistics.Add();
		vRow.Item = NStr("en='  Total';ru='  Общий';de='  Gesamt'");
		If vWithVAT Then
			vRow.Value = cmFormatSum(vRevRow.SalesTurnover, vRevRow.ReportingCurrency);
		Else
			vRow.Value = cmFormatSum(vRevRow.SalesWithoutVATTurnover, vRevRow.ReportingCurrency);
		EndIf;
		vRow.IsFirstRow = False;
		vRow.IsHeaderRow = False;
	EndDo;
	For Each vRevRow In vRevenues Do
		vRow = TableBoxStatistics.Add();
		vRow.Item = NStr("en='  Room revenue';ru='  За проживание';de='  Für Aufenthalt'");
		If vWithVAT Then
			vRow.Value = cmFormatSum(vRevRow.RoomRevenueTurnover, vRevRow.ReportingCurrency);
		Else
			vRow.Value = cmFormatSum(vRevRow.RoomRevenueWithoutVATTurnover, vRevRow.ReportingCurrency);
		EndIf;
		vRow.IsFirstRow = False;
		vRow.IsHeaderRow = False;
		// ADR
		If vNumberOfNights <> Null And vNumberOfNights > 0 Then
			vRow = TableBoxStatistics.Add();
			vRow.Item = NStr("en='  ADR';ru='  Средняя цена за ночь';de='  Durchschnittlicher Tagespreis'");
			If vWithVAT Then
				vRow.Value = cmFormatSum(Round(vRevRow.RoomRevenueTurnover/vNumberOfNights, 2), vRevRow.ReportingCurrency);
			Else
				vRow.Value = cmFormatSum(Round(vRevRow.RoomRevenueWithoutVATTurnover/vNumberOfNights, 2), vRevRow.ReportingCurrency);
			EndIf;
			vRow.IsFirstRow = False;
			vRow.IsHeaderRow = False;
		EndIf;
	EndDo;
	// Last accommodation
	vRow = TableBoxStatistics.Add();
	vRow.Item = NStr("en='LAST CHECK-IN';ru='ПОСЛЕДНИЙ ЗАЕЗД';de='LETZTE ANREISE'");
	vRow.IsFirstRow = False;
	vRow.IsHeaderRow = True;
	// Check-in date
	vRow = TableBoxStatistics.Add();
	vRow.Item = NStr("en='  Check-in date';ru='  Дата заезда';de='  Anreisedatum'");
	If ValueIsFilled(vLastAcc) Then
		vRow.Value = Format(vLastAcc.CheckInDate, "DF=dd.MM.yyyy");
	EndIf;
	vRow.IsFirstRow = False;
	vRow.IsHeaderRow = False;
	// First accommodation
	vRow = TableBoxStatistics.Add();
	vRow.Item = NStr("en='FIRST CHECK-IN';ru='ПЕРВЫЙ ЗАЕЗД';de='ERSTE ANREISE'");
	vRow.IsFirstRow = False;
	vRow.IsHeaderRow = True;
	// Check-in date
	vRow = TableBoxStatistics.Add();
	vRow.Item = NStr("en='  Check-in date';ru='  Дата заезда';de='  Anreisedatum'");
	If ValueIsFilled(vFirstAcc) Then
		vRow.Value = Format(vFirstAcc.CheckInDate, "DF=dd.MM.yyyy");
	EndIf;
	vRow.IsFirstRow = False;
	vRow.IsHeaderRow = False;
	If vUseParameterObject = False Then
		// Set object value
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure // BuildCustomerStatistics

// -----------------------------------------------------------------------------
&AtServer
Function RightsToOpenTheDocument(pNameDoc)
	If Not AccessRight("View", Metadata.Documents[pNameDoc]) Then
		Return False;
	EndIf;
	Return True;
EndFunction // RightsToOpenTheDocument

// ------------------------------------------------------------------------------------------------
&AtServer
Function GetColor(pObj = Undefined)
	vObject = pObj;
	If pObj = Undefined Then
		vObject = Object;
	EndIf;
	vColor = Undefined;
	If Not IsBlankString(Object.ColorHexString) Then
		vColor = tcOnServer.HexToColor(Object.ColorHexString);
		If TypeOf(vColor) <> Type("Color") Then
			vColor = Undefined;
		EndIf;
	EndIf;
	Return vColor;
EndFunction // GetColor

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure SetColorAfterUserChoice(pColor, pExtraParams) Export
	If pColor <> Undefined Then
		If pColor.Type = ColorType.WebColor Or pColor.Type = ColorType.Absolute Then
			ItemColor = pColor;
			ItemColorIsSet = True;
			Items.FormSetColor.BackColor = pColor;
		Else
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You can choose web or absolute colors only! Style and windows colors are not supported.';ru='Можете выбирать только абсолютные цвета (по названию или по RGB)! Выбор цветов из стилей не поддерживается.';de='Sie dürfen nur absolute Farben wählen (nach Bezeichnung oder nach RGB)! Die Farbenauswahl aus Stilen wird nicht unterstützt.'"));
		EndIf;
	EndIf;
EndProcedure // SetColorAfterUserChoice

// -----------------------------------------------------------------------------
&AtServer
Procedure IsIndividualOnChangeAtServer()
	If ValueIsFilled(Object.Ref) And ValueIsFilled(SessionParameters.CurrentHotel) And 
	   ValueIsFilled(SessionParameters.CurrentHotel.IndividualsCustomer) And 
	   Object.Ref = SessionParameters.CurrentHotel.IndividualsCustomer Then
		If Not Object.IsIndividual Then
			Object.IsIndividual = True;
		EndIf;
	Else
		vIndividualsFolder = Constants.IndividualsFolder.Get();
		If Not ValueIsFilled(vIndividualsFolder) Then
			vIndividualsFolder = Catalogs.Customers.IndividualsFolder;
		EndIf;
		If Object.IsIndividual Then
			If Not ValueIsFilled(Object.Parent) Or ValueIsFilled(Object.Parent) And Not (Object.Parent = vIndividualsFolder Or Object.Parent.BelongsToItem(vIndividualsFolder)) Then
				Object.Parent = vIndividualsFolder;
			EndIf;
		Else
			If ValueIsFilled(Object.Parent) And (Object.Parent = vIndividualsFolder Or Object.Parent.BelongsToItem(vIndividualsFolder)) Then
				Object.Parent = Catalogs.Customers.EmptyRef();
			EndIf;
		EndIf;
	EndIf;
EndProcedure // IsIndividualOnChangeAtServer

#EndRegion   
