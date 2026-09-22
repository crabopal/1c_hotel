
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Save current user
	CurrentUser = SessionParameters.CurrentUser;
	
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;
	EndIf;
	
	// Initialize some attributes
	SetNewDocNumber = False;
	ChequeIsPrinted = False;
	PaymentIsAuthorized = False;
	Items.PaymentSection.Visible = UsePaymentSections();
	
	NewObjectRef = Object.Ref;
	If Not ValueIsFilled(NewObjectRef) Then
		vObj = FormAttributeToValue("Object");
		
		If Not ValueIsFilled(vObj.GetNewObjectRef()) Then
			vObj.SetNewObjectRef(Documents.CustomerPayment.GetRef());
		EndIf;
		NewObjectRef = vObj.GetNewObjectRef();
		
		ValueToFormAttribute(vObj, "Object");
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	// Check parameters
	If Parameters.Property("AccountingContract") Then
		If ValueIsFilled(Parameters.AccountingContract) Then
			Object.AccountingCustomer = Parameters.AccountingContract.Owner;
			Object.AccountingContract = Parameters.AccountingContract;
		EndIf;
	ElsIf Parameters.Property("AccountingCustomer") Then
		If ValueIsFilled(Parameters.AccountingCustomer) Then
			Object.AccountingCustomer = Parameters.AccountingCustomer;
		EndIf;
	EndIf;
	If Parameters.Property("GuestGroup") Then
		If ValueIsFilled(Parameters.GuestGroup) Then
			Object.GuestGroup = Parameters.GuestGroup;
		EndIf;
	EndIf;
	
	// Fill list of payment methods allowed for the current user
	FillListOfPaymentMethods();
	// Set default payment method
	If Not ValueIsFilled(Object.Ref) Then
		SetDefaultPaymentMethod();
	EndIf;
	
	// Fill list of cash registers allowed for the current user
	FillListOfCashRegisters();
	// Set default cash register
	If Not ValueIsFilled(Object.Ref) Then
		SetDefaultCashRegister(True);
	EndIf;
	
	// Save payment currency attributes
	SavePaymentCurrencyAttributes();
	
	// Fill list of payers credit cards
	FillListOfPayersCreditCards();
	
	Items.FormShowCheque.Enabled = False;
	Items.FormShowCheque.Visible = False;
	If ValueIsFilled(Object.Ref) Then
		vAttrRow = cmGetChequeAttributes(Object.Ref);
		If vAttrRow <> Undefined And ValueIsFilled(Object.CashRegister) And Not IsBlankString(Object.CashRegister.ChequeVerificationInternetAddress)Then
			Items.FormShowCheque.Enabled = True;
			Items.FormShowCheque.Visible = True;
		EndIf;
	EndIf;
	
	// User rights
	If Not tcOnServer.cmIsInRole("Administrator") Then
		Items.GroupParameters.Visible = False;
	EndIf;
	SendPayerContactsRefresh(True, False, False, False);
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	If Not ValueIsFilled(pCurrentObject.Ref) And ValueIsFilled(NewObjectRef) Then
		pCurrentObject.SetNewObjectRef(NewObjectRef);
	EndIf;
	If SetNewDocNumber Then
		pCurrentObject.SetNewNumber();
		SetNewDocNumber = False;
	EndIf;
EndProcedure // BeforeWriteAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	vPaymentMethodArr = tcOnServer.cmGetAtributeAsArray(Object.PaymentMethod);
	
	If CreditCardProcessingSystem.IsEmpty() And vPaymentMethodArr.IsByCreditCard Then
		vTempArr = GetCreditCardProcessingSystem();
		If vTempArr.Count() > 1 Then
			pCancel = True;
			vParams = New Structure("Arr", vTempArr);
			OpenForm("CommonForm.tcCreditCardProcessingSystemChoiceForm", vParams, ThisObject, UUID);
			Return;
		ElsIf vTempArr.Count() = 1 Then
			CreditCardProcessingSystem = vTempArr[0];
		EndIf; 
	EndIf;	
	vMessage = ""; 
	
	ClearMessages();
	
	vCashRegisterArr = tcOnServer.cmGetAtributeAsArray(Object.CashRegister);
	
	If pWriteParameters.WriteMode = DocumentWriteMode.Posting Then
		// Check document attributes
		If Not CheckDocumentAttributes(vMessage) Then
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
		// Do first document write processing
		If Not Object.Posted And Not Object.DeletionMark Then
			// Check if it is possible to print cheque
			If ValueIsFilled(Object.CashRegister) And ValueIsFilled(Object.PaymentMethod) Then
				If vPaymentMethodArr.BookByCashRegister Then
					If vCashRegisterArr.IsControlledByProgram Then
						If vPaymentMethodArr.PrintCheque And Not ChequeIsPrinted Then
							If Object.Sum <> 0 Or Object.Sum = 0 And Object.PaymentMethod = PredefinedValue("Catalog.PaymentMethods.AdvanceSettlement") Then
								If Not IsReadyToPrintCheque(vMessage, Object.CashRegister) Then
									pCancel = True;
									tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), , , , tcOnServer.cmNStrAtServer(vMessage));
									ShowMessageBox(,tcOnServer.cmNStrAtServer(vMessage));
									Return;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
				// Process payment by the credit card processing system
				If vPaymentMethodArr.IsByCreditCard And Not vPaymentMethodArr.ExternalBankTerminalIsUsed Then
					// If payment was earlier authorized manually (reference number is filled) or automatically then skip this step
					If IsBlankString(Object.ReferenceNumber) And Not PaymentIsAuthorized Then
						If CheckCreditCardsProcessingSystem() Then
							If Object.Sum <> 0 Then
								If Object.Sum > 0 Then
									If Not AuthorizePayment(vMessage) Then
										pCancel = True;
										tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), , , , tcOnServer.cmNStrAtServer(vMessage));
										ShowMessageBox(, tcOnServer.cmNStrAtServer(vMessage));
										Return;
									Else
										PaymentIsAuthorized = True;
									EndIf;
								Else
									If ValueIsFilled(Object.CustomerPayment) Then
										If Not IsBlankString(tcOnServer.cmGetAttributeByRef(Object.CustomerPayment, "ReferenceNumber")) Then
											If Not AuthorizePayment(vMessage) Then
												pCancel = True;
												tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), , , , tcOnServer.cmNStrAtServer(vMessage));
												ShowMessageBox(, tcOnServer.cmNStrAtServer(vMessage));
												Return;
											Else
												PaymentIsAuthorized = True;	
											EndIf;
										Else
											pCancel = True;
											vMessage = NStr("en='Reference number in the payment is not set!';ru='У платежа по которому делается возврат не указан ссылочный номер!';de='Bei der Zahlung, zu der eine Rückerstattung durchgeführt wird, ist keine Referenznummer angegeben!'");
											tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), , , , tcOnServer.cmNStrAtServer(vMessage));
											ShowMessageBox(, tcOnServer.cmNStrAtServer(vMessage));
											Return;
										EndIf;
									Else
										pCancel = True;
										vMessage = NStr("en='Return should be done based on payment!';ru='Возврат должен быть введен на основании платежа!';de='Die Rückgabe muss auf der Grundlage einer Zahlung eingegeben werden!'");
										tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), , , , tcOnServer.cmNStrAtServer(vMessage));
										ShowMessageBox(, tcOnServer.cmNStrAtServer(vMessage));
										Return;
									EndIf;	
								EndIf;
							Else
								pCancel = True;
								vMessage = NStr("en='Payment amount should be entered!';ru='Не введена сумма платежа!';de='Die Zahlungssumme wurde nicht eingegeben!'");
								tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"),,,, vMessage);
								ShowMessageBox(,vMessage);
								Return;	
							EndIf;
						EndIf;
					EndIf;
				EndIf;
				If vPaymentMethodArr.BookByCashRegister Then
					If vCashRegisterArr.IsControlledByProgram Then
						If vPaymentMethodArr.PrintCheque And Not ChequeIsPrinted Then
							If Object.Sum <> 0 Or Object.Sum = 0 And Object.PaymentMethod = PredefinedValue("Catalog.PaymentMethods.AdvanceSettlement") Then					// Print cheque at cash register
								StartPrintCheque(vMessage, pCancel);
								If pCancel And Not IsBlankString(vMessage) Then
									tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), , , , tcOnServer.cmNStrAtServer(vMessage));
									ShowMessageBox(, tcOnServer.cmNStrAtServer(vMessage));
								EndIf;	
							Else
								pCancel = True;
								vMessage = NStr("en='Payment amount should be entered!';ru='Не введена сумма платежа!';de='Die Zahlungssumme wurde nicht eingegeben!'");
								tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"),,,, vMessage);
								ShowMessageBox(,vMessage);
								Return;	
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	// Reset flags
	If Object.Posted Then
		ChequeIsPrinted = False;
		PaymentIsAuthorized = False;
	EndIf;
	// Notify changes in the accounts subsystem
	Notify("Subsystem.Accounts.Changed");
EndProcedure // AfterWrite

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
	ElsIf pEventName = "CreditCard.Write" And pSource = Items.CreditCard And ValueIsFilled(pParameter) And tcOnServer.cmGetAttributeByRef(pParameter, "CardOwner") = Object.AccountingCustomer Then
		If Items.CreditCard.ChoiceList.FindByValue(pParameter) = Undefined Then
			Items.CreditCard.ChoiceList.Add(pParameter);
		EndIf;
		Object.CreditCard = pParameter;
		CreditCardOnChange(Items.CreditCard);
	EndIf;
EndProcedure // NotificationProcessing

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure CompanyOnChange(Item)
	CompanyOnChangeAtServer();
EndProcedure // CompanyOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ParentDocStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure // ParentDocStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure CashRegisterOnChange(pItem)
	CashRegisterOnChangeAtServer();
	SendPayerContactsRefresh(False, False, True, False);
EndProcedure // CashRegisterOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AccountingCustomerOnChange(pItem)
	AccountingCustomerOnChangeAtServer();
	SendPayerContactsRefresh(False, True, False, False);
EndProcedure // AccountingCustomerOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AccountingContractOnChange(pItem)
	AccountingContractOnChangeAtServer();
EndProcedure // AccountingContractOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure InvoiceOnChange(pItem)
	InvoiceOnChangeAtServer();
EndProcedure // InvoiceOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentCurrencyOnChange(pItem)
	PaymentCurrencyOnChangeAtServer();
EndProcedure // PaymentCurrencyOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ExchangeRateDateOnChange(pItem)
	ExchangeRateDateOnChangeAtServer();
EndProcedure // ExchangeRateDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentSectionOnChange(pItem)
	PaymentSectionOnChangeAtServer();
EndProcedure // PaymentSectionOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentMethodOnChange(pItem)
	PaymentMethodOnChangeAtServer();
	SendPayerContactsRefresh(False, False, False, True);
EndProcedure // PaymentMethodOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SumOnChange(pItem)
	SumOnChangeAtServer();
EndProcedure // SumOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure VATRateOnChange(pItem)
	VATRateOnChangeAtServer();
EndProcedure // VATRateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CreditCardOpening(pItem, pStandardProcessing)
	If Not ValueIsFilled(Object.CreditCard) Then
		pStandardProcessing = False;
		OpenForm("Catalog.CreditCards.ObjectForm", New Structure("FillingValues", New Structure("CardOwner, CardNumber", Object.AccountingCustomer, Items.CreditCard.EditText)), pItem);
	EndIf;
EndProcedure // CreditCardOpening

// -----------------------------------------------------------------------------
&AtClient
Procedure CreditCardOnChange(pItem)
	If ValueIsFilled(Object.CreditCard) Then
		Object.CardType = tcOnServer.cmGetAttributeByRef(Object.CreditCard, "CardType");
	EndIf;
EndProcedure // CreditCardOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SendPayerContactsToOFDOnChange(pItem)
	SendPayerContactsRefresh(False, False, False, False);
EndProcedure // SendPayerContactsToOFDOnChange

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowCheque(pCommand)
	OpenForm("Catalog.CashRegisters.Form.tcShowCheque", New Structure("SelDocument", Object.Ref), ThisObject, UUID);
EndProcedure // ShowCheque

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCloseAtServer()
	If ValueIsFilled(CurrentUser) Then
		SessionParameters.CurrentUser = CurrentUser;
	EndIf;
EndProcedure // OnCloseAtServer

// -----------------------------------------------------------------------------
&AtServer
Function UsePaymentSections()
	vQ = New Query("SELECT
	|	PaymentSections.Ref
	|FROM
	|	Catalog.PaymentSections AS PaymentSections
	|WHERE
	|	NOT PaymentSections.DeletionMark");
	vRes = vQ.Execute();
	If vRes.IsEmpty() And Not Object.Hotel.SplitFolioBalanceByServicesAndPrices Then
		Return False
	Else
		Return True;
	EndIf;
EndFunction

// --------------------------------------------------------------------------------
&AtServer
Procedure CompanyOnChangeAtServer()
	// Clear all table parts
	Object.Invoices.Clear();
	Object.Contracts.Clear();
	// Fill VAT rate
	If ValueIsFilled(Object.Company) Then
		If ValueIsFilled(Object.Company.VATRate) Then
			Object.VATRate = Object.Company.VATRate;
		EndIf;
		SetNewDocNumber = True;
	EndIf;
	// Fill list of payment methods allowed for the current user
	FillListOfPaymentMethods();
	// Set default payment method
	If Not ValueIsFilled(Object.Ref) Then
		SetDefaultPaymentMethod();
	EndIf;
	// Fill list of cash registers allowed for the current user
	FillListOfCashRegisters();
	// Set default cash register
	If Not ValueIsFilled(Object.Ref) Then
		SetDefaultCashRegister(True);
	EndIf;
	// Recalculate totals
	vObj = FormAttributeToValue("Object", Type("DocumentObject.CustomerPayment"));
	vObj.pmCalculateSums();
	ValueToFormAttribute(vObj, "Object");
EndProcedure // CompanyOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillListOfCashRegisters()
	vCashRegistersList = New ValueList();
	If cmCheckUserPermissions("HavePermissionToViewAllCashRegisters") Then
		vCashRegistersList = cmGetListOfAllCashRegisters(Object.Company);
	Else
		vCashRegistersList = cmGetListOfCashRegistersAllowed(Object.Company, SessionParameters.CurrentWorkstation, Object.PaymentMethod);
	EndIf;
	// Filter cash registers list by hotel
	i = 0;
	While i < vCashRegistersList.Count() Do
		vCashRegister = vCashRegistersList.Get(i).Value;
		If ValueIsFilled(vCashRegister) Then
			If ValueIsFilled(vCashRegister.Hotel) And vCashRegister.Hotel = Object.Hotel Or 
				Not ValueIsFilled(vCashRegister.Hotel) Then
				i = i + 1;
			Else
				vCashRegistersList.Delete(i);
			EndIf;
		Else
			vCashRegistersList.Delete(i);
		EndIf;
	EndDo;
	// Check that current cash register is in the list
	If Object.Posted Then
		If ValueIsFilled(Object.CashRegister) Then
			If vCashRegistersList.FindByValue(Object.CashRegister) = Undefined Then
				vCashRegistersList.Add(Object.CashRegister);
			EndIf;
		EndIf;
	EndIf;
	// Load list of cash registers
	Items.CashRegister.ChoiceList.LoadValues(vCashRegistersList.UnloadValues());
EndProcedure // FillListOfCashRegisters

// -----------------------------------------------------------------------------
&AtServer
Procedure SetDefaultCashRegister(pRefill = False)
	If pRefill Or Items.CashRegister.ChoiceList.FindByValue(Object.CashRegister) = Undefined Then
		Object.CashRegister = Catalogs.CashRegisters.EmptyRef();
		If ValueIsFilled(Object.PaymentMethod) Then
			If Object.PaymentMethod.BookByCashRegister Then
				If Items.CashRegister.ChoiceList.Count() > 0 Then
					Object.CashRegister = Items.CashRegister.ChoiceList.Get(0).Value;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // SetDefaultCashRegister

// -----------------------------------------------------------------------------
&AtServer
Procedure CashRegisterOnChangeAtServer()
	// Fill list of payment methods allowed for the current user
	FillListOfPaymentMethods();
	// Set default payment method
	If Not ValueIsFilled(Object.Ref) Then
		SetDefaultPaymentMethod();
	EndIf;
EndProcedure // CashRegisterOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillListOfPaymentMethods()
	vPMs = cmGetListOfPaymentMethodsAllowed(SessionParameters.CurrentUser, ?(Object.Sum < 0, True, False), Object.CashRegister);
	i = 0;
	While i < vPMs.Count() Do
		vPM = vPMs.Get(i).Value;
		If vPM = Catalogs.PaymentMethods.AdvanceSettlement Or
			vPM = Catalogs.PaymentMethods.DepositTransfer Or
			vPM = Catalogs.PaymentMethods.Settlement Or
			vPM.IsForResortFee Then
			vPMs.Delete(i);
		Else
			i = i + 1;
		EndIf;
	EndDo;
	Items.PaymentMethod.ChoiceList.LoadValues(vPMs.UnloadValues());
	// Check that current payment method is in the list
	If Object.Posted Then
		If ValueIsFilled(Object.PaymentMethod) Then
			If Items.PaymentMethod.ChoiceList.FindByValue(Object.PaymentMethod) = Undefined Then
				Items.PaymentMethod.ChoiceList.Add(Object.PaymentMethod);
			EndIf;
		EndIf;
	EndIf;
	// Add icons
	For Each vListItem In Items.PaymentMethod.ChoiceList Do
		vPM = vListItem.Value;
		If vPM.IsByCash Then
			vListItem.Picture = PictureLib.Coins;
		ElsIf vPM.IsByCreditCard Then
			vListItem.Picture = PictureLib.CreditCard16;
		ElsIf vPM.IsByBankTransfer Then
			vListItem.Picture = PictureLib.Customers;
		ElsIf vPM = Catalogs.PaymentMethods.Settlement Then
			vListItem.Picture = PictureLib.Customer;
		ElsIf vPM.IsCloseToTheFolio Then
			vListItem.Picture = PictureLib.Adult;
		ElsIf vPM.IsCloseToTheRoom Then
			vListItem.Picture = PictureLib.Rooms;
		ElsIf vPM.IsByGiftCertificate Then
			vListItem.Picture = PictureLib.CalculationType;
		ElsIf vPM.IsByBonuses Then
			vListItem.Picture = PictureLib.AccumulationRegister;
		ElsIf vPM.IsViaInternetAcquiring Then
			vListItem.Picture = PictureLib.GeographicalSchema;
		Else
			vListItem.Picture = PictureLib.Empty;
		EndIf;
	EndDo;		
EndProcedure // FillListOfPaymentMethods

// -----------------------------------------------------------------------------
&AtServer
Procedure SetDefaultPaymentMethod()
	If Not ValueIsFilled(Object.PaymentMethod) Then
		If ValueIsFilled(Object.Hotel) Then
			Object.PaymentMethod = Catalogs.PaymentMethods.EmptyRef();
			If ValueIsFilled(Object.Hotel.PaymentMethodForCustomerPayments) Then
				Object.PaymentMethod = Object.Hotel.PaymentMethodForCustomerPayments;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(Object.PaymentMethod) Then
		If Items.PaymentMethod.ChoiceList.FindByValue(Object.PaymentMethod) = Undefined Then
			Object.PaymentMethod = Catalogs.PaymentMethods.EmptyRef();
		EndIf;
	EndIf;
	If Not ValueIsFilled(Object.PaymentMethod) Then
		If Items.PaymentMethod.ChoiceList.Count() > 0 Then
			Object.PaymentMethod = Items.PaymentMethod.ChoiceList.Get(0).Value;
		EndIf;
	EndIf;
EndProcedure // SetDefaultPaymentMethod

// -----------------------------------------------------------------------------
&AtServer
Procedure AccountingCustomerOnChangeAtServer()
	// Fill list of payers credit cards
	FillListOfPayersCreditCards();
	// Clear all table parts
	Object.Invoices.Clear();
	Object.Contracts.Clear();
	// Clear contract and invoice
	Object.AccountingContract = Catalogs.Contracts.EmptyRef();
	Object.GuestGroup = Catalogs.GuestGroups.EmptyRef();
	Object.Invoice = Undefined;
	// Fill accounting currency
	If ValueIsFilled(Object.AccountingCustomer) Then
		If ValueIsFilled(Object.Hotel) Then
			Object.AccountingCurrency = Object.AccountingCustomer.AccountingCurrency;
			Object.AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Object.Hotel, Object.AccountingCurrency, Object.ExchangeRateDate);
			Object.SumInAccountingCurrency = Round(cmConvertCurrencies(Object.Sum, Object.PaymentCurrency, Object.PaymentCurrencyExchangeRate, Object.AccountingCurrency, Object.AccountingCurrencyExchangeRate, Object.ExchangeRateDate, Object.Hotel), 2);
		Else
			Object.AccountingCurrency = Object.PaymentCurrency;
			Object.AccountingCurrencyExchangeRate = Object.PaymentCurrencyExchangeRate;
			Object.SumInAccountingCurrency = Object.Sum;
		EndIf;
	EndIf;
	// Recalculate totals
	vObj = FormAttributeToValue("Object", Type("DocumentObject.CustomerPayment"));
	vObj.pmCalculateSums();
	ValueToFormAttribute(vObj, "Object");
EndProcedure // AccountingCustomerOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillListOfPayersCreditCards()
	Items.CreditCard.ChoiceList.LoadValues(cmGetListOfPayersCreditCards(Object.AccountingCustomer).UnloadValues());
	// Check that current credit card is in the list
	If ValueIsFilled(Object.CreditCard) Then
		If Items.CreditCard.ChoiceList.FindByValue(Object.CreditCard) = Undefined Then
			Items.CreditCard.ChoiceList.Add(Object.CreditCard);
		EndIf;
	EndIf;
EndProcedure // FillListOfPayersCreditCards

// -----------------------------------------------------------------------------
&AtServer
Procedure AccountingContractOnChangeAtServer()
	// Clear all table parts
	Object.Invoices.Clear();
	Object.Contracts.Clear();
	// Clear contract and invoice
	Object.GuestGroup = Catalogs.GuestGroups.EmptyRef();
	Object.Invoice = Undefined;
	// Fill accounting currency
	If ValueIsFilled(Object.AccountingContract) Then
		If ValueIsFilled(Object.Hotel) Then
			Object.AccountingCurrency = Object.AccountingContract.AccountingCurrency;
			Object.AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Object.Hotel, Object.AccountingCurrency, Object.ExchangeRateDate);
			Object.SumInAccountingCurrency = Round(cmConvertCurrencies(Object.Sum, Object.PaymentCurrency, Object.PaymentCurrencyExchangeRate, Object.AccountingCurrency, Object.AccountingCurrencyExchangeRate, Object.ExchangeRateDate, Object.Hotel), 2);
		Else
			Object.AccountingCurrency = Object.PaymentCurrency;
			Object.AccountingCurrencyExchangeRate = Object.PaymentCurrencyExchangeRate;
			Object.SumInAccountingCurrency = Object.Sum;
		EndIf;
	EndIf;
	// Recalculate totals
	vObj = FormAttributeToValue("Object", Type("DocumentObject.CustomerPayment"));
	vObj.pmCalculateSums();
	ValueToFormAttribute(vObj, "Object");
EndProcedure // AccountingContractOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure InvoiceOnChangeAtServer()
	// Clear all table parts
	Object.Invoices.Clear();
	Object.Contracts.Clear();
	// Fill accounting currency
	If ValueIsFilled(Object.Invoice) Then
		If ValueIsFilled(Object.Invoice.AccountingCustomer) Then
			Object.AccountingCustomer = Object.Invoice.AccountingCustomer;
		EndIf;
		If ValueIsFilled(Object.Invoice.AccountingContract) Then
			Object.AccountingContract = Object.Invoice.AccountingContract;
		EndIf;
		If ValueIsFilled(Object.Invoice.GuestGroup) Then
			Object.GuestGroup = Object.Invoice.GuestGroup;
		EndIf;
		Object.AccountingCurrency = Object.Invoice.AccountingCurrency;
		If ValueIsFilled(Object.Hotel) Then
			Object.AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Object.Hotel, Object.AccountingCurrency, Object.ExchangeRateDate);
			Object.SumInAccountingCurrency = Round(cmConvertCurrencies(Object.Sum, Object.PaymentCurrency, Object.PaymentCurrencyExchangeRate, Object.AccountingCurrency, Object.AccountingCurrencyExchangeRate, Object.ExchangeRateDate, Object.Hotel), 2);
		EndIf;
	EndIf;
EndProcedure // InvoiceOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure PaymentCurrencyOnChangeAtServer()
	If Not ValueIsFilled(Object.Hotel) Then
		Return;
	EndIf;
	// Clear all table parts
	Object.Invoices.Clear();
	Object.Contracts.Clear();
	// Recalculations
	Object.PaymentCurrencyExchangeRate = cmGetCurrencyExchangeRate(Object.Hotel, Object.PaymentCurrency, Object.ExchangeRateDate);
	Object.Sum = Round(cmConvertCurrencies(Object.SumInAccountingCurrency, Object.AccountingCurrency, Object.AccountingCurrencyExchangeRate, Object.PaymentCurrency, Object.PaymentCurrencyExchangeRate, Object.ExchangeRateDate, Object.Hotel), 2);
	// Save payment currency attributes
	SavePaymentCurrencyAttributes();
	// Recalculate totals
	vObj = FormAttributeToValue("Object", Type("DocumentObject.CustomerPayment"));
	vObj.pmCalculateSums();
	ValueToFormAttribute(vObj, "Object");
EndProcedure // PaymentCurrencyOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ExchangeRateDateOnChangeAtServer()
	If Not ValueIsFilled(Object.Hotel) Then
		Return;
	EndIf;
	// Clear all table parts
	Object.Invoices.Clear();
	Object.Contracts.Clear();
	// Recalculations
	Object.AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Object.Hotel, Object.AccountingCurrency, Object.ExchangeRateDate);
	Object.PaymentCurrencyExchangeRate = cmGetCurrencyExchangeRate(Object.Hotel, Object.PaymentCurrency, Object.ExchangeRateDate);
	Object.Sum = Round(cmConvertCurrencies(Object.SumInAccountingCurrency, Object.AccountingCurrency, Object.AccountingCurrencyExchangeRate, Object.PaymentCurrency, Object.PaymentCurrencyExchangeRate, Object.ExchangeRateDate, Object.Hotel), 2);
	// Save payment currency attributes
	SavePaymentCurrencyAttributes();
	// Recalculate totals
	vObj = FormAttributeToValue("Object", Type("DocumentObject.CustomerPayment"));
	vObj.pmCalculateSums();
	ValueToFormAttribute(vObj, "Object");
EndProcedure // ExchangeRateDateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SavePaymentCurrencyAttributes()
	OldPaymentCurrency = Object.PaymentCurrency;
	OldPaymentCurrencyExchangeRate = Object.PaymentCurrencyExchangeRate;
EndProcedure // SavePaymentCurrencyAttributes

// -----------------------------------------------------------------------------
&AtServer
Procedure PaymentSectionOnChangeAtServer()
	// Clear all table parts
	Object.Invoices.Clear();
	Object.Contracts.Clear();
	// Fill VAT rate from the section
	If ValueIsFilled(Object.PaymentSection) Then
		If ValueIsFilled(Object.PaymentSection.VATRate) Then
			Object.VATRate = Object.PaymentSection.VATRate;
			// Recalculate totals
			vObj = FormAttributeToValue("Object", Type("DocumentObject.CustomerPayment"));
			vObj.pmCalculateSums();
			ValueToFormAttribute(vObj, "Object");
		EndIf;
	EndIf;
EndProcedure // PaymentSectionOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure PaymentMethodOnChangeAtServer()
	// Fill list of cash registers allowed for the current user
	FillListOfCashRegisters();
	// Set default cash register
	SetDefaultCashRegister(True);
EndProcedure // PaymentMethodOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SumOnChangeAtServer()
	vSignWasChanged = False;
	If Object.SumInAccountingCurrency > 0 And Object.Sum < 0 Or
		Object.SumInAccountingCurrency > 0 And Object.Sum < 0 Then
		vSignWasChanged = True;
	EndIf;
	
	If ValueIsFilled(Object.Hotel) Then
		Object.SumInAccountingCurrency = Round(cmConvertCurrencies(Object.Sum, Object.PaymentCurrency, Object.PaymentCurrencyExchangeRate, Object.AccountingCurrency, Object.AccountingCurrencyExchangeRate, Object.ExchangeRateDate, Object.Hotel), 2);
	Else
		Object.SumInAccountingCurrency = Object.Sum;
	EndIf;
	
	// Recalculate VAT
	vVATSum = cmCalculateVATSum(Object.VATRate, Object.Sum, Object.Date);
	If vVATSum <> Object.VATSum Then
		Object.VATSum = vVATSum;
	EndIf;
	
	// Fill list of payment methods allowed for the current user
	If vSignWasChanged Then
		FillListOfPaymentMethods();
		SetDefaultPaymentMethod();
		
		// Set default cash register
		SetDefaultCashRegister(True);
	EndIf;
	
	// Clear tabular parts if they exists
	Object.Invoices.Clear();
	Object.Contracts.Clear();
EndProcedure // SumOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure VATRateOnChangeAtServer()
	// Recalculate VAT
	vVATSum = cmCalculateVATSum(Object.VATRate, Object.Sum, Object.Date);
	If vVATSum <> Object.VATSum Then
		Object.VATSum = vVATSum;
	EndIf;
EndProcedure // VATRateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function CheckDocumentAttributes(rMessage)
	vObj = FormAttributeToValue("Object", Type("DocumentObject.CustomerPayment"));
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
EndFunction // CheckDocumentAttributes

// -----------------------------------------------------------------------------
&AtServer
Function CheckCreditCardsProcessingSystem()
	If ValueIsFilled(SessionParameters.CurrentWorkstation) And Not CreditCardProcessingSystem.IsEmpty() Then
		ArrPaymentTerminal = tcOnServer.cmGetAtributeAsArray(CreditCardProcessingSystem);
		ArrPaymentTerminal.ConnectionParameters = ArrPaymentTerminal.ConnectionParameters.Get();
		Return True
	Else
		Return False;
	EndIf;
EndFunction	//CheckCreditCardsProcessingSystem

&AtServer
Function GetCreditCardProcessingSystem()
	vTempArr = New Array();
	If ValueIsFilled(SessionParameters.CurrentWorkstation) Then
		vQry = New Query; 
		vQry.Text = "SELECT
		|	ConnectedDevices.DeviceSettings AS DeviceSettings
		|FROM
		|	InformationRegister.ConnectedDevices AS ConnectedDevices
		|WHERE
		|	ConnectedDevices.Workstation = &qCurrentWorkstation
		|	AND ConnectedDevices.DeviceType = &qCreditCardProcessingSystem
		|	AND ConnectedDevices.IsActive
		|	AND (ConnectedDevices.DeviceSettings.Company = VALUE(Catalog.Companies.EmptyRef)
		|			OR ConnectedDevices.DeviceSettings.Company = &qCompany)";
		vQry.SetParameter("qCurrentWorkStation", SessionParameters.CurrentWorkstation);
		vQry.SetParameter("qCreditCardProcessingSystem", Enums.DeviceTypes.CreditCardsProcessingSystemParameters);
		vQry.SetParameter("qCompany", Object.Company);
		vResult = vQry.Execute().Unload();
		
		vTempArrayWithPaymentMethod = New Array();
		For Each vRow In vResult Do
			vPaymentMethods = vRow.DeviceSettings.PaymentMethods;
			If vPaymentMethods.Count() > 0 Then
				For Each vPaymentRow In vPaymentMethods Do
					If vPaymentRow.PaymentMethod = Object.PaymentMethod Then
						vTempArrayWithPaymentMethod.Add(vRow.DeviceSettings); 
					Else
						vTempArr.Add(vRow.DeviceSettings);
					EndIf;
				EndDo;
			Else
				vTempArr.Add(vRow.DeviceSettings);
			EndIf;
		EndDo;
		
		If vTempArrayWithPaymentMethod.Count() > 0 Then
			Return vTempArrayWithPaymentMethod;
		Else
			Return vTempArr;
		EndIf;
	Else
		Return vTempArr;
	EndIf;
EndFunction


// -----------------------------------------------------------------------------
&AtClient
Function IsReadyToPrintCheque(rMessage, pCashRegister)
	rMessage = "";
	If Not ValueIsFilled(pCashRegister) Then
		Return False;
	EndIf;
	vDriver = tcOnClient.cmGetModulTO(pCashRegister);
	If Not vDriver = Undefined Then
		Return vDriver.pmIsReadyToPrint(rMessage, , pCashRegister);
	Else
		ShowMessageBox(, Nstr("en = 'Work with this device driver is not supported!'; ru = 'Работа с драйвером этого устройства не поддерживается'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird!'"),,NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
	EndIf;	
	Return  False;
EndFunction // IsReadyToPrintCheque

// -----------------------------------------------------------------------------
&AtClient
Procedure StartPrintCheque(rMessage, pCancel)
	vDriver = tcOnClient.cmGetModulTO(Object.CashRegister);
	If Not vDriver = Undefined Then
		vPasswordKKM = tcOnServer.cmGetUserPasswordKKM(, Object.CashRegister);
		vQuestion =  NStr("ru='Пожалуйста введите пароль ККМ...'; 
		|de='Input cash register password please...';
		|en='Input cash register password please...'");
		If IsBlankString(vPasswordKKM) Then
			// Break before write event and ask user to input cash register password
			pCancel = True;
			vNotify = New NotifyDescription("AfterInputCashRegisterPassword", ThisObject, New Structure("Driver, rMessage", vDriver, rMessage));
			OpenForm("CommonForm.tcInputCashRegisterPassword", New Structure("LabelDescription", vQuestion), ThisObject, , , , vNotify);
			// Attach idle handler to close form when cheque will be printed
			AttachIdleHandler("WriteAndCloseFormAfterChequeBeingPrinted", 1, False);
		Else
			vObject = Object;
			If tcOnServer.cmGetAttributeByRef(Object.PaymentMethod, "PrintNonFiscalCheque") Then
				vChequeTemplate = TrimAll(tcOnServer.cmGetAttributeByRef(Object.PaymentMethod, "NonFiscalChequeTemplate"));
				If Not IsBlankString(vChequeTemplate) Then
					ChequeIsPrinted = vDriver.pmPrintNonFiscalCheque(Object.Sum, Object.VATSum, vObject, vChequeTemplate, rMessage, vPasswordKKM);
				Else
					rMessage = NStr("en='Non-fiscal cheque template is not filled for payment method!'; ru='У способа оплаты не заполнен шаблон нефискального чека!'; de='Zahlungsmethode hat eine leer Vorlage für die nonfiscal Kassenbon!'");
					ChequeIsPrinted = False;
				EndIf;
			Else
				ChequeIsPrinted = vDriver.pmPrintCustomerCheque(Object.Sum, Object.VATSum, vObject, NewObjectRef, rMessage, vPasswordKKM, , , , , , Object.SendPayerContactsToOFD, Object.EmailToSendToOFD, Object.PhoneToSendToOFD);
			EndIf;
			If Not ChequeIsPrinted Then
				// Error printing cheque, so break before write event
				pCancel = True;
			EndIf;
		EndIf;
	Else
		// Device driver was not found
		pCancel = True;
		rMessage = Nstr("en = 'Work with this device driver is not supported'; ru = 'Работа с драйвером этого устройства не поддерживается'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird'");
	EndIf;	
EndProcedure // StartPrintCheque

// -----------------------------------------------------------------------------
&AtClient
Procedure WriteAndCloseFormAfterChequeBeingPrinted() Export
	If ChequeIsPrinted Then
		DetachIdleHandler("WriteAndCloseFormAfterChequeBeingPrinted");
		WriteAndCloseForm();
	EndIf;
EndProcedure // WriteAndCloseFormAfterChequeBeingPrinted

// -----------------------------------------------------------------------------
&AtClient
Procedure WriteAndCloseForm() Export
	If Write(New Structure("WriteMode, PostingMode", PredefinedValue("DocumentWriteMode.Posting"), PredefinedValue("DocumentPostingMode.Regular"))) Then
		Close();
	EndIf;
EndProcedure // WriteAndCloseForm

// -----------------------------------------------------------------------------
&AtClient
Function AfterInputCashRegisterPassword(pValue, pAdditionalParameters) Export
	vDriver = pAdditionalParameters.Driver;
	vMessage = pAdditionalParameters.rMessage;
	If Not pValue = Undefined Then
		vObject = Object;
		If tcOnServer.cmGetAttributeByRef(Object.PaymentMethod, "PrintNonFiscalCheque") Then
			vChequeTemplate = TrimAll(tcOnServer.cmGetAttributeByRef(Object.PaymentMethod, "NonFiscalChequeTemplate"));
			If Not IsBlankString(vChequeTemplate) Then
				ChequeIsPrinted = vDriver.pmPrintNonFiscalCheque(Object.Sum, Object.VATSum, vObject, vChequeTemplate, vMessage, pValue.Password);
			Else
				vMessage = NStr("en='Non-fiscal cheque template is not filled for payment method!'; ru='У способа оплаты не заполнен шаблон нефискального чека!'; de='Zahlungsmethode hat eine leer Vorlage für die nonfiscal Kassenbon!'");
				ChequeIsPrinted = False;
			EndIf;
		Else
			ChequeIsPrinted = vDriver.pmPrintCustomerCheque(Object.Sum, Object.VATSum, vObject, NewObjectRef, vMessage, pValue.Password, , , , , , Object.SendPayerContactsToOFD, Object.EmailToSendToOFD, Object.PhoneToSendToOFD);
		EndIf;
		If Not ChequeIsPrinted Then
			DetachIdleHandler("WriteAndCloseFormAfterChequeBeingPrinted");
		EndIf;
	Else
		DetachIdleHandler("WriteAndCloseFormAfterChequeBeingPrinted");
	EndIf;
EndFunction // AfterInputCashRegisterPassword

// -----------------------------------------------------------------------------
&AtClient
Function AuthorizePayment(rMessage)
	rMessage = "";
	If Not ValueIsFilled(Object.AuthorizationCode) Then
		vDriver = tcOnClient.cmGetModulTO(ArrPaymentTerminal);
		If Not vDriver = Undefined Then
			If ArrPaymentTerminal.CreditCardsProcessingSystemType = PredefinedValue("Enum.CreditCardsProcessingSystems.TrPosPOSTerminalsDriver") Then
				SetNewObjectRefAtServer();	
			EndIf;
			Return vDriver.pmAuthorizePayment(Object.Sum, Object.VATSum, Object, rMessage, ArrPaymentTerminal);
		Else
			ShowMessageBox(, Nstr("en = 'Work with this device driver is not supported'; ru = 'Работа с драйвером этого устройства не поддерживается'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird'"), , NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
		EndIf;	
	EndIf;
	Return True;
EndFunction // AuthorizePayment

// -----------------------------------------------------------------------------
&AtServer
Procedure SetNewObjectRefAtServer()
	If Not ValueIsFilled(Object.Number) Then
		vObj = FormAttributeToValue("Object");
		vObj.SetNewNumber();
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure //  SetNewObjectRefAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SendPayerContactsRefresh(pIsOnOpen = False, pIsChangePayer = False, pIsChangeCashRegister = False, pIsChangePaymentMethod = False)
	If ValueIsFilled(Object.CashRegister) And Object.CashRegister.IsControlledByProgram And 
		ValueIsFilled(Object.PaymentMethod) And Object.PaymentMethod.BookByCashRegister And Object.PaymentMethod.PrintCheque Then
		If pIsOnOpen And Not ValueIsFilled(Object.Ref) Or pIsChangeCashRegister Then
			Object.SendPayerContactsToOFD = Object.CashRegister.SendPayerContactsToOFD;
		EndIf;
		Items.SendPayerContacts.Visible = True;
	ElsIf pIsOnOpen And Not ValueIsFilled(Object.Ref) Or pIsChangeCashRegister Or pIsChangePaymentMethod Then                
		Object.SendPayerContactsToOFD = 2;
		Items.SendPayerContacts.Visible = False;
	EndIf;
	If Object.SendPayerContactsToOFD = 0 Then	
		Items.EmailToSendToOFD.Enabled = True;
		Items.PhoneToSendToOFD.Enabled = False;
	ElsIf Object.SendPayerContactsToOFD = 1 Then
		Items.EmailToSendToOFD.Enabled = False;
		Items.PhoneToSendToOFD.Enabled = True;	
	ElsIf Object.SendPayerContactsToOFD = 2 Then
		Items.EmailToSendToOFD.Enabled = False;
		Items.PhoneToSendToOFD.Enabled = False;	
	EndIf;
	If pIsOnOpen And Not ValueIsFilled(Object.Ref) Or pIsChangePayer Then
		If ValueIsFilled(Object.AccountingCustomer) Then
			Object.EmailToSendToOFD = Object.AccountingCustomer.EMail;
			Object.PhoneToSendToOFD = Object.AccountingCustomer.Phone;
		Else
			Object.EmailToSendToOFD = "";
			Object.PhoneToSendToOFD = "";
		EndIf;
	EndIf;
EndProcedure // SendClientContactsRefresh  

&AtClient
Procedure ChoiceProcessing(pSelectedValue, pChoiceSource)
	If TypeOf(pSelectedValue) = Type("Structure") And pSelectedValue.Property("CreditCardProcessingSystem") Then
		CreditCardProcessingSystem = pSelectedValue.CreditCardProcessingSystem;
		Write(New Structure("WriteMode", DocumentWriteMode.Posting));
	EndIf;
EndProcedure

#EndRegion

