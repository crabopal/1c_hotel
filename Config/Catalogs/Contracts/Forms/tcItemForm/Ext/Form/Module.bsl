
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	// Initialize hotel
	tcOnServer.cmInitHotel(Object);
	
	// Get object value
	WasNew = False;
	vObj = FormAttributeToValue("Object");
	If vObj.IsNew() Then
		WasNew = True;
		If Not cmCheckUserPermissions("HavePermissionToEditCustomer") Then
			pCancel = True;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to create new contracts!';ru='Нет прав регистрировать новые договора контрагентов!';de='Sie haben keine Rechte, neue Verträge der Partner zu registrieren!'"));
		EndIf;
	EndIf;
	
	// Group titles
	If Catalogs.ObjectFormActions.ContractSendInvitationToNewAgent.IsActive And Not Catalogs.ObjectFormActions.ContractSendInvitationToNewAgent.DeletionMark Then
		Items.FormContractSendInvitationToNewAgent.Visible = True;			
	Else	
		Items.FormContractSendInvitationToNewAgent.Visible = False;		
	EndIf;
	
	// Printing button appearance
	If Not WasNew Then
		FillPrintingButton();
	EndIf;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	OnOpenForm();
EndProcedure // OnOpen

// -----------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	vMessage = ""; 
	vAttributeInErr = "";
	// Save state
	WasNew = pCurrentObject.IsNew();
	// Check item attributes
	pCancel = pCurrentObject.pmCheckContractAttributes(vMessage, vAttributeInErr);
	If pCancel Then
		WriteLogEvent(NStr("en = 'Catalog.Write'; de = 'Catalog.Write'; ru = 'Справочник.Запись'"), EventLogLevel.Warning, pCurrentObject.Metadata(), pCurrentObject.Ref, NStr(vMessage));
		tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage));
		If Not IsBlankString(vAttributeInErr) Then
			CurrentItem = Items[vAttributeInErr];
		EndIf;
		// Reset write in form flag
		WasWriteInForm = False;
	Else
		// Save color
		If ItemColorIsSet Then
			pCurrentObject.ColorHexString = tcOnServer.ColorToHex(ItemColor);
			pCurrentObject.Color = New ValueStorage(tcOnServer.HexToColor(pCurrentObject.ColorHexString));
		Else
			pCurrentObject.ColorHexString = "";
			pCurrentObject.Color = Undefined;
		EndIf;
		// Check room rates
		vInt = 0;
		While vInt < pCurrentObject.RoomRates.Count() Do
			vRRRow = pCurrentObject.RoomRates.Get(vInt);
			If Not ValueIsFilled(vRRRow.RoomRate) And Not ValueIsFilled(vRRRow.DiscountType) Then
				pCurrentObject.RoomRates.Delete(vInt);
			Else
				vInt = vInt + 1;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // BeforeWriteAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure AfterWriteAtServer(pCurrentObject, pWriteParameters)
	// Save changes to the client change history
	pCurrentObject.pmWriteToContractChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
	// Printing button appearance
	If WasNew Then
		FillPrintingButton();
	EndIf;
EndProcedure // AfterWriteAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	// Check should we recalculate prices for the active reservations
	If Ask2RecalcReservations Then
		ShowQueryBox(New NotifyDescription("Ask2RecalculateReservationsAfterAnswer", ThisObject), 
		             NStr("en='Do you want to recalculate prices in active contract reservations?'; ru='Нужно пересчитать цены в действующей брони этого договора?'; de='Möchten Sie Preise in aktiven Vertragsreservierungen neu berechnen?'"), QuestionDialogMode.YesNo, 20, DialogReturnCode.No, , DialogReturnCode.No);
	EndIf;
	WriteAtServer();
EndProcedure // AfterWrite

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure FillCheckProcessingAtServer(pCancel, pCheckedAttributes)
	vObj = FormAttributeToValue("Object");
	pCancel = tcOnServer.cmFillCheckProcessingForm(pCheckedAttributes, CheckedAttributesManual, vObj);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeClose(pCancel, pStandardProcessing)
	If WasWriteInForm And Ask2RecalcReservations Then
		If ValueIsFilled(Object.Ref) Then
			pCancel = True;
		EndIf;
	EndIf;
EndProcedure // BeforeClose

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure CodeOnChange(pItem)
	CodeOnChangeAtServer();
EndProcedure // CodeOnChange

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
Procedure SourceOfBusinessStartListChoice(pItem, pStandardProcessing)
	Items.SourceOfBusiness.ChoiceList.LoadValues(GetArrayOfAllSourceOfBusiness());
EndProcedure // SourceOfBusinessStartListChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure ClientTypeStartListChoice(pItem, pStandardProcessing)
	Items.ClientType.ChoiceList.LoadValues(GetArrayOfAllClientTypes());
EndProcedure // ClientTypeStartListChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure ClientTypeOnChange(pItem)
	ClientTypeOnChangeAtServer();
EndProcedure // ClientTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ClientTypeConfirmationTextOnChange(pItem)
	ClientTypeOnChangeAtServer();
EndProcedure // ClientTypeConfirmationTextOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AccountingCurrencyOnChange(pItem)
	ChargingFolioParametersOnChangeAtServer();
EndProcedure // AccountingCurrencyOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PlannedPaymentMethodOnChange(pItem)
	Ask2RecalcReservations = True;
	ChargingFolioParametersOnChangeAtServer();
EndProcedure // PlannedPaymentMethodOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PayerOnChange(pItem)
	Ask2RecalcReservations = True;
	PayerOnChangeAtServer();
EndProcedure // PayerOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRatesOnEditEnd(pItem, pNewRow, pCancelEdit)
	Ask2RecalcReservations = True;
EndProcedure // RoomRatesOnEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRatesAfterDeleteRow(pItem)
	Ask2RecalcReservations = True;
EndProcedure // RoomRatesAfterDeleteRow

// -----------------------------------------------------------------------------
&AtClient
Procedure MealBoardTermsOnEditEnd(pItem, pNewRow, pCancelEdit)
	Ask2RecalcReservations = True;
EndProcedure // MealBoardTermsOnEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure MealBoardTermsAfterDeleteRow(pItem)
	Ask2RecalcReservations = True;
EndProcedure // MealBoardTermsAfterDeleteRow

// -----------------------------------------------------------------------------
&AtClient
Procedure AgentOnChange(pItem)
	Ask2RecalcReservations = True;
	BuildCommissionCollapsedTitle();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AgentCommissionTypeOnChange(pItem)
	Ask2RecalcReservations = True;
	BuildCommissionCollapsedTitle();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AgentCommissionOnChange(pItem)
	Ask2RecalcReservations = True;
	BuildCommissionCollapsedTitle();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PerInvoiceCommissionOnChange(pItem)
	Ask2RecalcReservations = True;
	BuildCommissionCollapsedTitle();
EndProcedure // PerInvoiceCommissionOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AgentCommissionServiceGroupOnChange(pItem)
	Ask2RecalcReservations = True;
	BuildCommissionCollapsedTitle();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ChargingRulesOnChange(pItem)
	Ask2RecalcReservations = True;
EndProcedure // ChargingRulesOnChange

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenFolios(pCommand)
	If ValueIsFilled(Object.Ref) Then
		// APDEX
		vKeyOperation = "CommonForm.tcFoliosForm.OpenForm";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

		vParametersStructure = New Structure("IsNew, WasPosted, IsFormModified, ObjectRef", False, False, Modified, Object.Ref);
		OpenForm("CommonForm.tcFoliosForm", New Structure("ParametersStructure", vParametersStructure), ThisObject, UUID);
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Save contract first!'; ru='Сначала сохраните договор!'; de='Speichern Sie den Vertrag zuerst!'"));
	EndIf;
EndProcedure // OpenFolios

// -----------------------------------------------------------------------------
&AtClient
Procedure ContractSendInvitationToNewAgent(pCommand)   
	If ValueIsFilled(Object.Ref) Then
		OpenForm("Catalog.Contracts.Form.tcAgentInvitationForm", New Structure("Key", Object.Ref), ThisObject, UniqueKey, , , , FormWindowOpeningMode.LockOwnerWindow);
	Else  
		ShowMessageBox(, Nstr("en = 'You must first save the contract'; de = 'Sie müssen den Vertrag zunächst speichern'; ru = 'Необходимо сначала сохранить договор'"), , Nstr("en = 'Error'; de = 'Error'; ru = 'Ошибка'"));
	EndIf;
EndProcedure // ContractSendInvitationToNewAgent

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure SetColor(pCommand)
	// Choose color
	vColorDlg =  New ColorChooseDialog;
	vColorDlg.Color = ItemColor;
	vColorDlg.Show(New NotifyDescription("SetColorAfterUserChoice", ThisObject));
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure ClearColor(pCommand)
	// Clear color
	ItemColor = Undefined;
	ItemColorIsSet = False;
	Items.FormSetColor.BackColor = Items.FormClearColor.BackColor;
EndProcedure // ClearColor

// -----------------------------------------------------------------------------
&AtClient
Procedure LoadDefaultChargingRules(pCommand)
	LoadDefaultChargingRulesAtServer();
EndProcedure // LoadDefaultChargingRules

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintButtonClick(pCommand)
	// Save document first
	If Not ValueIsFilled(Object.Ref) Or Modified Then
		If Not Write() Then
			Return;
		EndIf;
	EndIf;
	// Choose processing type
	vPrintNumber = StrReplace(pCommand.Name, "Print", "");
	vPrintForm = GetPrintFormForNumber(vPrintNumber);
	// Load external print form
	If ValueIsFilled(vPrintForm.ExternalProcessing) Then 
		Try
			OpenExternalProcedureForm(vPrintForm.ExternalProcessing, vPrintForm.Ref);
		Except
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Failed to load external print form!'; 
															|de = 'Das externe Druckformular konnte nicht geladen werden!'; 
															|ru = 'Не удалось загрузить внешнюю печатную форму!'"), MessageStatus.Attention);
		EndTry;
	ElsIf ValueIsFilled(vPrintForm.Report) Then
		Try
			OpenExternalReportForm(vPrintForm.Report, vPrintForm.Ref);
		Except
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'"), MessageStatus.Attention);
		EndTry;
	ElsIf vPrintForm.PredefinedDataName = "ContractPrintDetailedBalances" Then
		OpenReportForm(PredefinedValue("Catalog.Reports.CustomerAccountsDetails"));
	ElsIf vPrintForm.PredefinedDataName = "ContractPrintBalances" Then
		OpenReportForm(PredefinedValue("Catalog.Reports.CustomerAccounts"));
	ElsIf Left(vPrintForm.PredefinedDataName, 13) = "ContractPrint" Then   
		// Nothing yet
	EndIf;
EndProcedure // PrintButtonClick

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure OnOpenForm(pObj = Undefined)
	vUseParametersObject = True;
	ClientTypeIsDisabled = False;
	// Check parameters
	vObj = pObj;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParametersObject = False;
	EndIf;
	If vObj.IsNew() Then
		// Fill attributes with default values
		If Not ValueIsFilled(vObj.Author) Then
			vObj.pmFillAttributesWithDefaultValues();
		EndIf;
	EndIf;
	If vObj.ChargingRules.Count() > 0 And ValueIsFilled(vObj.ChargingRules.Get(0).ChargingFolio) Then
		If ValueIsFilled(vObj.Agent) And vObj.ChargingRules.Get(0).ChargingFolio.Customer = vObj.Agent Then
			Payer = Enums.WhoPays.Agent;
		ElsIf vObj.ChargingRules.Get(0).ChargingFolio.Customer = vObj.Owner Then
			Payer = Enums.WhoPays.Customer;
		Else
			Payer = Enums.WhoPays.ChargingRules;
		EndIf;
	Else
		Payer = Enums.WhoPays.Guest;
	EndIf;
	// Check user rights to edit charging rules
	If Not cmCheckUserPermissions("HavePermissionToEditChargingRules") Then
		Items.ChargingRules.ReadOnly = True;
	EndIf;
	// Open read only if user do not have rights to edit customer
	If Not cmCheckUserPermissions("HavePermissionToEditCustomer") Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'You do not have rights to edit contracts! Contract data will be opened read only.'; 
														|de = 'Sie haben keine Rechte, Daten von Verträgen zu redigieren! Die Karte der Verträge wird zur Ansicht geöffnet.'; 
														|ru = 'Нет прав редактировать данные договоров! Карточка договора будет открыта на просмотр.'"));
		ReadOnly = True;
	EndIf;
	// Check user rights to edit discounts
	If Not cmCheckUserPermissions("HavePermissionToAddManualDiscounts") Then
		Items.DiscountType.Enabled = False;
	EndIf;
	// Check user rights to edit client type
	If Not cmCheckUserPermissions("HavePermissionToChooseClientTypeManually") Then
		Items.ClientType.Enabled = False;
		ClientTypeIsDisabled = True;
	EndIf;
	// Check user rights to edit manager
	If Not cmCheckUserPermissions("HavePermissionToEditCustomerAndGuestGroupManagers") Then
		Items.Author.ReadOnly = True;
		Items.Author.TextEdit = False;
		Items.Author.OpenButton = False;
	EndIf;
	// Check user rights to edit room rates
	If Not cmCheckUserPermissions("HavePermissionToApproveRoomRates") Then
		Items.RoomRatesApproved.Enabled = False;
	Else
		Items.RoomRatesApproved.Enabled = True;
	EndIf;
	RoomRatesApprovedAppearance(vObj);
	DisableFieldsByCustomer();
	// Group titles
	BuildAccountingGroupCollapsedTitle(vObj);
	BuildCommissionCollapsedTitle(vObj);
	// Reset write in form flag
	WasWriteInForm = False;
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
	If Not vUseParametersObject Then
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure // OnOpenForm

// -----------------------------------------------------------------------------
&AtServer
Procedure RoomRatesApprovedAppearance(pObj = Undefined)
	// Check parameters
	vObj = pObj;
	If pObj = Undefined Then
		vObj = Object;
	EndIf;
	If vObj.RoomRatesApproved Then
		Items.DiscountType.ReadOnly = True;
		Items.RoomRate.ReadOnly = True;
		Items.RoomRateServiceGroup.ReadOnly = True;
		Items.RoomRates.ReadOnly = True;
		Items.FeeTerms.ReadOnly = True;
		Items.DaysBeforeCheckIn.ReadOnly = True;
		Items.DaysAfterReservation.ReadOnly = True;
		Items.DaysAfterSettlement.ReadOnly = True;
		Items.AccountingCurrency.ReadOnly = True;
		Items.Agent.ReadOnly = True;
		Items.AgentCommission.ReadOnly = True;
		Items.AgentCommissionType.ReadOnly = True;
		Items.AgentCommissionServiceGroup.ReadOnly = True;
	Else
		Items.DiscountType.ReadOnly = False;
		Items.RoomRate.ReadOnly = False;
		Items.RoomRateServiceGroup.ReadOnly = False;
		Items.RoomRates.ReadOnly = False;
		Items.FeeTerms.ReadOnly = False;
		Items.DaysBeforeCheckIn.ReadOnly = False;
		Items.DaysAfterReservation.ReadOnly = False;
		Items.DaysAfterSettlement.ReadOnly = False;
		Items.AccountingCurrency.ReadOnly = False;
		Items.Agent.ReadOnly = False;
		Items.AgentCommission.ReadOnly = False;
		Items.AgentCommissionType.ReadOnly = False;
		Items.AgentCommissionServiceGroup.ReadOnly = False;
	EndIf;
EndProcedure // RoomRatesApprovedAppearance

// ----------------------------------------------------------------
&AtServer
Procedure BuildAccountingGroupCollapsedTitle(pObj = Undefined)
	vObj = pObj;
	If vObj = Undefined Then
		vObj = Object;
	EndIf; 
	vAgent = "";
	If Payer = Enums.WhoPays.Customer Then
		vAgent = " " + TrimAll(vObj.Owner);
	Else
		If Payer = Enums.WhoPays.Agent And ValueIsFilled(vObj.Agent) Then
			vAgent = " " + TrimAll(vObj.Agent);	
		EndIf;	
	EndIf;	
	vTitle = NStr("en='Pays: '; ru='Платит: '; de='Zahler: '") + TrimAll(Payer) + vAgent + NStr("en=' by '; ru=', '; de=', '") + TrimAll(vObj.PlannedPaymentMethod);
	Items.GroupAccounting.CollapsedRepresentationTitle = vTitle;
EndProcedure // BuildAccountingGroupCollapsedTitle

// ----------------------------------------------------------------
&AtServer
Procedure BuildCommissionCollapsedTitle(pObj = Undefined)
	vObj = pObj;
	If vObj = Undefined Then
		vObj = Object;
	EndIf;
	If ValueIsFilled(vObj.AgentCommissionType) Or vObj.AgentCommission <> 0 Or vObj.PerInvoiceCommission <> 0 Then  
		vAgent = "";
		If ValueIsFilled(vObj.Agent) Then
			vAgent = TrimAll(vObj.Agent);
		Else
			vAgent =  TrimAll(vObj.Owner);	
		EndIf;	
		vAgentCommissionServiceGroup = NStr("en = 'all'; de = 'alle '; ru = 'все'");
		If ValueIsFilled(vObj.AgentCommissionServiceGroup) Then
			vAgentCommissionServiceGroup = TrimAll(vObj.AgentCommissionServiceGroup);	
		EndIf;	
		vTitle = NStr("en='Agent '; ru='Агент '; de='Agent '") + vAgent + ": " + TrimAll(vObj.AgentCommission) + " " + TrimAll(vObj.AgentCommissionType) 
				+ NStr("en = ' for '; de = ' für '; ru = ' за '") + vAgentCommissionServiceGroup;
		If vObj.PerInvoiceCommission <> 0 Then
			vTitle = vTitle + ", " + NStr("en='per invoice commission '; ru='комиссия на акт '; de='per Rechnung provision '") + TrimAll(vObj.PerInvoiceCommission) + "%";
		EndIf;
	Else
		vTitle = NStr("en = 'No commission'; de = 'Keine Kommission'; ru = 'Без комиссии'");
	EndIf;
	Items.GroupCommission.CollapsedRepresentationTitle = vTitle;
EndProcedure // BuildCommissionCollapsedTitle

// -----------------------------------------------------------------------------
&AtServer
Procedure DisableFieldsByCustomer()
	// Disabled fields if customer is filled
	If ValueIsFilled(SessionParameters.CurrentUser.Customer) Then
		ReadOnly = True;
		// Contract data
		Items.Hotel.ClearButton = False;
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
		Items.Payer.Enabled = False;
		Items.Payer.ChoiceListButton = False;
		Items.PlannedPaymentMethod.Enabled = False;
		Items.PlannedPaymentMethod.OpenButton = False;
		Items.PlannedPaymentMethod.ClearButton = False;
		Items.PlannedPaymentMethod.ChoiceButton = False;
		// Charging rules
		Items.ChargingRules.ReadOnly = True;
		// Room rates
		Items.DiscountType.Enabled = False;
		Items.DiscountType.OpenButton = False;
		Items.DiscountType.ClearButton = False;
		Items.DiscountType.ChoiceButton = False;
        Items.DiscountConfirmationText.Enabled = False;
		Items.RoomRate.Enabled = False;
		Items.RoomRate.OpenButton = False;
		Items.RoomRate.ClearButton = False;
		Items.RoomRate.ChoiceButton = False;
		Items.RoomRateServiceGroup.Enabled = False;
		Items.RoomRateServiceGroup.OpenButton = False;
		Items.RoomRateServiceGroup.ClearButton = False;
		Items.RoomRateServiceGroup.ChoiceButton = False;
		Items.FeeTerms.Enabled = False;
		Items.FeeTerms.OpenButton = False;
		Items.FeeTerms.ClearButton = False;
		Items.FeeTerms.ChoiceButton = False;
		Items.DaysBeforeCheckIn.Enabled = False;
        Items.DaysAfterReservation.Enabled = False;
		Items.DaysAfterSettlement.Enabled = False;
		Items.RoomRatesApproved.Enabled = False;
		Items.RoomRates.ReadOnly = True;
		Items.DefAnaliticalParametersGroup.Enabled = False;
	EndIf;
EndProcedure // DisableFieldsByCustomer

// -----------------------------------------------------------------------------
&AtServer
Procedure CodeOnChangeAtServer(pObj = Undefined)
	vUseParametersObject = True;
	// Check parameters
	vObj = pObj;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParametersObject = False;
	EndIf;
	If vObj.IsNew() Then
		If Not IsBlankString(vObj.Code) And IsBlankString(vObj.Description) Then
			vObj.Description = TrimAll(vObj.Code);
		EndIf;
	EndIf;
	If Not vUseParametersObject Then
		// Set object value
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure // CodeOnChangeAtServer

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
&AtServer
Function GetArrayOfAllSourceOfBusiness()
	vSOBTable = cmGetAllSourcesOfBusiness();
	vSOBArray = vSOBTable.UnloadColumn("SourceOfBusiness");
	Return vSOBArray;
EndFunction // GetListOfAllSourceOfBusiness

// -----------------------------------------------------------------------------
&AtServer
Function GetArrayOfAllClientTypes()
	vCTTable = cmGetAllClientTypes();
	vCTArray = vCTTable.UnloadColumn("ClientType");
	Return vCTArray;
EndFunction // GetArrayOfAllClientTypes

// -----------------------------------------------------------------------------     
&AtServer
Procedure ClientTypeOnChangeAtServer(pObj = Undefined) 
	// Check parameters
	vUseParameterObject = True;
	vObj = pObj;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParameterObject = False;
	EndIf;
	vClientType = vObj.ClientType;
	vClientTypeConfirmationText = vObj.ClientTypeConfirmationText;
	If Not ValueIsFilled(vClientType) Then
		vClientTypeConfirmationText = "";
	EndIf;
	If Not vUseParameterObject Then
		// Set object value
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure // ClientTypeOnChangeAtServer

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
	If ValueIsFilled(vObj.Hotel) Then
		 vHotel = vObj.Hotel;
	EndIf;	
	If Payer = Enums.WhoPays.Guest Then
		If ValueIsFilled(vHotel) Then
			vObj.PlannedPaymentMethod = vHotel.PlannedPaymentMethod;
		Else
			vObj.PlannedPaymentMethod = Catalogs.PaymentMethods.EmptyRef();
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Default hotel is not filled!'; de = 'Kein Hotel als Standard-Einstellung ist gewählt!'; ru = 'Не выбрана гостиница по умолчанию!'"));
		EndIf;
		vObj.ChargingRules.Clear();
	ElsIf Payer = Enums.WhoPays.Customer Or Payer = Enums.WhoPays.Agent Then
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
	Ask2RecalcReservations = True;
	Modified = True;
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
		vObj.pmCreateFolios(vHotel, CurrentSessionDate(), Payer);
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Default hotel is not filled!'; de = 'Kein Hotel als Standard-Einstellung ist gewählt!'; ru = 'Не выбрана гостиница по умолчанию!'"));
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
	If Payer = Enums.WhoPays.Customer Or Payer = Enums.WhoPays.Agent Then
		If ValueIsFilled(vObj.PlannedPaymentMethod) Then
			If vObj.ChargingRules.Count() > 0 Then
				If Not vObj.ChargingRules.Get(0).ChargingFolio.IsEmpty() Then
					vFolioObj = vObj.ChargingRules.Get(0).ChargingFolio.GetObject();
					vFolioObj.PaymentMethod = vObj.PlannedPaymentMethod;
					vFolioObj.FolioCurrency = vObj.AccountingCurrency;
					Try
						vFolioObj.Write();
					Except
						tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Failed to change planned payment method! Please try again.'; 
																		|de = 'Die geplante Zahlungsmethode konnte nicht gespeichert werden! Wiederholen Sie die Änderung noch einmal.'; 
																		|ru = 'Не удалось сохранить планируемый способ оплаты! Повторите изменение еще раз.'"));
					EndTry;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	BuildAccountingGroupCollapsedTitle(vObj);
	Ask2RecalcReservations = True;
 	Modified = True;
EndProcedure // ChargingFolioParametersOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure Ask2RecalculateReservationsAfterAnswer(pAnswer, pExtraParams) Export
	If pAnswer = DialogReturnCode.Yes Then
		// Check should we recalculate prices for the active reservations
		vOperationParametrs = New Array;
		vOperationParametrs.Add(Object.Ref);
		vOperationParametrs.Add(GetSessionParameter("CurrentUser"));
		StartProlongedOperation("ProlongedOperations.Contract_RecalculatePricesForActiveReservations", "en = 'Processing reservations...'; ru = 'Обработка брони...'; de = 'Reservierungen bearbeiten...'", vOperationParametrs);
	EndIf;
	Ask2RecalcReservations = False;
EndProcedure // Ask2RecalculateReservationsAfterAnswer

// -----------------------------------------------------------------------------
&AtServer
Procedure WriteAtServer()
	// Get object value
	vObj = FormAttributeToValue("Object");
	// Update customer and contract attribute for all folios in the charging rules if was new
	If WasNew Then
		WasNew = False;
		For Each vRow In vObj.ChargingRules Do
			vFolio = vRow.ChargingFolio;
			If ValueIsFilled(vFolio) Then
				vFolioObj = vFolio.GetObject();
				If Not ValueIsFilled(vFolioObj.Contract) Then
					vFolioObj.Customer = vObj.Owner;
					vFolioObj.Contract = vObj.Ref;
					Try
						vFolioObj.Write();
					Except
						vErrInfo = ErrorInfo();
						WriteLogEvent(NStr("en = 'Catalog.Contracts.AfterWrite'; de = 'Catalog.Contracts.AfterWrite'; ru = 'Справочник.Договоры.ПослеЗаписи'"), EventLogLevel.Error, vObj.Metadata(), vObj.Ref, cmGetRootErrorDescription(vErrInfo));
						tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Write error!'; de = 'Fehler beim Schreiben!'; ru = 'Ошибка записи!'"));
					EndTry;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	// Set write in form flag
	WasWriteInForm = True;
EndProcedure // WriteAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure BlockForm_ShowProgressBar()
	BackgroundOperationProgress = 0;
	Items.BackgroundOperationProgress.Visible = True;
	ReadOnly = True;
EndProcedure // BlockForm_ShowProgressBar

// -----------------------------------------------------------------------------
&AtClient
Procedure UnlockForm_HideProgressBar()
	BackgroundOperationProgress = 0;
	Items.BackgroundOperationProgress.Visible	= False;
	ReadOnly = False;
EndProcedure // UnlockForm_HideProgressBar

// ------------------------------------------------------------------------------------------------
&AtServer
Function GetColor(pObj = Undefined)
	vObject = pObj;
	If pObj = Undefined Then
		vObject = Object;
	EndIf;
	vColor = Undefined;
	If Not IsBlankString(vObject.ColorHexString) Then
		vColor = tcOnServer.HexToColor(vObject.ColorHexString);
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
		ItemColor = pColor;
		ItemColorIsSet = True;
		Items.FormSetColor.BackColor = pColor;
	EndIf;
EndProcedure // SetColorAfterUserChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure StartProlongedOperation(pFunctionName, pOperationName, pOperationParametrs = Undefined) 
	BlockForm_ShowProgressBar();
	Items.BackgroundOperationProgress.Title	= NStr("en = 'Background operation in progress, you can continue to work in other forms  - '; ru = 'Выполняется фоновая операция, можете продолжать работать в других формах  - '; de = 'Die Hintergrundoperation läuft, Sie können weiterhin in anderen Formen arbeiten - '") + NStr(pOperationName);
	vBackgroundJob = StartBackgroundJob(pOperationName, pFunctionName, pOperationParametrs);
	CurrentBackgroundJobUUID = vBackgroundJob.UUID;
	AttachIdleHandler("Attachable_CheckBackgroundJobs", 1, False);
EndProcedure // StartProlongedOperation

// -----------------------------------------------------------------------------
&AtServer                               
Function StartBackgroundJob(pOperationName, pProcedureName, pProcedureParametrs = Undefined, pTempStorageAddress = Undefined)
	Return AsyncCalls.StartBackgroundJobWithRecordInRegister(Object.Ref, pOperationName, pProcedureName, pProcedureParametrs, , , pTempStorageAddress);	
EndFunction

// -----------------------------------------------------------------------------
&AtClient
Procedure Attachable_CheckBackgroundJobs()
	vBackgroundJob = CheckBackgroundJobStatus(CurrentBackgroundJobUUID);
	BackgroundOperationProgress = vBackgroundJob.Progress; 
	
	For Each msg In vBackgroundJob.Messages Do
		If ListOfMessages.FindByValue(msg) = Undefined Then
			ListOfMessages.Add(msg);
			tcCommonFunctionOnClientServer.TextMessage(msg);
		EndIf;
	EndDo;
	
	If vBackgroundJob.Status = "Error" Then 
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Error in background job: '; ru = 'Ошибка выполнения фонового задания: '; de = 'Fehler beim Ausführen des Hintergrundjobs: '") + vBackgroundJob.Error);
		DetachIdleHandler("Attachable_CheckBackgroundJobs");
		UnlockForm_HideProgressBar();
		Read();
		OnOpen(False);
	ElsIf vBackgroundJob.Status = "Canceled" Then 
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Background job - canceled.'; ru = 'Фоновое задание - отменено.'; de = 'Hintergrundjob - abgebrochen.'"));
		DetachIdleHandler("Attachable_CheckBackgroundJobs");
		UnlockForm_HideProgressBar();
		Read();
		OnOpen(False);
	ElsIf vBackgroundJob.Status = "Completed" Then
		DetachIdleHandler("Attachable_CheckBackgroundJobs");
		UnlockForm_HideProgressBar();
		Read();
		OnOpen(False);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function CheckBackgroundJobStatus(pBackgroundJobId)
	Return AsyncCalls.CheckBackgroundJob(pBackgroundJobId); 
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Function GetSessionParameter(pParametrName)	
	Return SessionParameters[pParametrName];	
EndFunction //  GetSessionParameter()

// -----------------------------------------------------------------------------
&AtServer
Procedure FillPrintingButton()
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	ObjectPrintingForms.Ref AS Ref,
	|	ObjectPrintingForms.Code AS Code,
	|	ObjectPrintingForms.PredefinedDataName AS PredefinedDataName,
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
	
	vQuery.SetParameter("ObjectType", Catalogs.Contracts.EmptyRef());	
	vResult = vQuery.Execute();	
	vResByGroups = vResult.Select(QueryResultIteration.ByGroups);
	
	PrintForms.Clear();
	vLang = SessionParameters.CurrentLanguage;
	If ValueIsFilled(Object.Hotel) Then
		vLang = Object.Hotel.Language;
	EndIf;
	If ValueIsFilled(Object.Owner) And ValueIsFilled(Object.Owner.Language) Then
		vLang = Object.Owner.Language;
	EndIf;
	
	While vResByGroups.Next() Do
		SelectionDetailRecords = vResByGroups.Select(QueryResultIteration.ByGroups);
		
		If vLang = vResByGroups.Language Or Not ValueIsFilled(vResByGroups.Language) Then
			vParentLang = Items.FormGroupPrintingNotDefaultMain;
		ElsIf Not vLang = vResByGroups.Language Then
			vParentLang = tcOnServer.cmCreateItem(ThisObject, Items.FormGroupPrintingNotDefaultExtra, "Print" + vResByGroups.Language, "FormGroup",
												  New Structure("Type, Title", FormGroupType.Popup, vResByGroups.Language));
		EndIf;
		
		While SelectionDetailRecords.Next() Do
			vNewRow = PrintForms.Add();
			vNewRow.PrintForm = SelectionDetailRecords.Ref;
			vNewRow.IsDefault = SelectionDetailRecords.IsDefault;
			
			vID = vNewRow.GetID();
			
			vCommand = Commands.Add("Print" + vID);
			vCommand.Action = "PrintButtonClick";
			If SelectionDetailRecords.IsDefault Then
				vParent = Items.FormGroupPrintingDefault;
			Else
				vParent = vParentLang;
			EndIf;
			vStructure = New Structure("Title, CommandName", TrimAll(SelectionDetailRecords.Code) + " " + cmNStr(SelectionDetailRecords.ref), "Print" + vID);
			        
			tcOnServer.cmCreateItem(ThisObject, vParent, "Print" + vID, "FormButton", vStructure);
		EndDo;
	EndDo;
EndProcedure // FillPrintingButton

// -----------------------------------------------------------------------------
&AtServer
Function GetPrintFormForNumber(pActionsNumber)
	vPrintForms = PrintForms.FindByID(Number(pActionsNumber)).PrintForm;
	
	vStruct = New Structure();
	vStruct.Insert("Ref", vPrintForms);
	vStruct.Insert("PredefinedDataName", vPrintForms.PredefinedDataName);	
	vStruct.Insert("ExternalProcessing", vPrintForms.ExternalProcessing);
	vStruct.Insert("Report", vPrintForms.Report);
	vStruct.Insert("Language", vPrintForms.Language);
	
	Return vStruct;
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Function ConnectExternalDataProcessor(pPath, pName = "", pUseSafeMode = False)
	Return ExternalDataProcessors.Connect(pPath, pName, pUseSafeMode);
EndFunction // ConnectExternalDataProcessor

// -----------------------------------------------------------------------------
&AtServer
Function ConnectExternalReport(pPath, pName = "", pUseSafeMode = False)
	Return ExternalReports.Connect(pPath, pName, pUseSafeMode);
EndFunction // ConnectExternalDataProcessor

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenExternalProcedureForm(pExtProcRef, pPrintFormTypeRef)
	vURL = GetURL(pExtProcRef, "ExternalProcessingStorage");
	vName = ConnectExternalDataProcessor(vURL, GetExternalProcessingValidName(tcOnServer.cmGetAttributeByRef(pExtProcRef, "FileName")));
	vParams = New Structure("InputParameter, ObjectPrintingForm", Object.Ref, pPrintFormTypeRef);
	OpenForm("ExternalDataProcessor." + vName + ".Form", vParams);
EndProcedure // OpenExternalProcedureForm

// -----------------------------------------------------------------------------
&AtServer
Function GetExternalProcessingValidName(Val pStr)
	Return cmGetValidName(pStr); 	
EndFunction // GetExternalProcessingValidName

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenExternalReportForm(pExtRepRef, pPrintFormTypeRef)
	vURL = GetURL(tcOnServer.cmGetAttributeByRef(pExtRepRef, "Report"), "ExternalProcessingStorage"); 
	vName = ConnectExternalReport(vURL, "ExternalReportForm");
	vParams = New Structure("Contract, ObjectPrintingForm", Object.Ref, pPrintFormTypeRef);
	OpenForm("ExternalReport." + vName + ".Form", vParams);
EndProcedure // OpenExternalReportForm

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenReportForm(pReportRef)
	vManagedReportForm = Undefined;
	vReportObj = tcOnServer.cmGetAtributeAsArray(pReportRef);    
	vParams = New Structure("FillingValues, GenerateOnOpen", New Structure("ReportRef, Customer, Contract", pReportRef, Object.Owner, Object.Ref), Not vReportObj.DoNotGenerateOnOpen);
	If vReportObj.IsExternal Then
		vURL = GetURL(vReportObj.Report, "ExternalProcessingStorage"); 
		vName = ConnectExternalReport(vURL, StrReplace(tcOnServer.cmGetAttributeByRef(vReportObj.Report, "FileName"), ".erf", ""));
		OpenForm("ExternalReport." + vName + ".Form", vParams, ThisObject, pReportRef);
	Else	
		If vReportObj.Report = Undefined Then 
			vErr = Nstr("en = 'You must fill the handler in the report settings'; 
						|de = 'Sie müssen den Handler in den Berichteinstellungen ausfüllen'; 
						|ru = 'Необходимо заполнить обработчик в настройках отчета'");
			Raise vErr
		Else       
			OpenForm("Report." + vReportObj.Report + ".Form", vParams, ThisObject, pReportRef);
		EndIf; 
	EndIf;	
EndProcedure // OpenReportForm

#EndRegion    
