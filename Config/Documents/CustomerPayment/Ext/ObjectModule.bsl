
#Region Variables

Var WasPosted;

#EndRegion

#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure Filling(pBase)
	vOldHotel = Hotel;
	vOldCompany = Company;
	// Fill attributes with default values
	If IsNew() Then
		pmFillAttributesWithDefaultValues();
	EndIf;
	// Fill from the base
	If ValueIsFilled(pBase) Then
		If TypeOf(pBase) = Type("DocumentRef.ProformaInvoice") Then
			pmFillByInvoice(pBase);
		ElsIf TypeOf(pBase) = Type("DocumentRef.Settlement") Then
			pmFillBySettlement(pBase);
		ElsIf TypeOf(pBase) = Type("DocumentRef.CreditNote") Then
			pmFillByCreditNote(pBase);
		ElsIf TypeOf(pBase) = Type("DocumentRef.DebitNote") Then
			pmFillByDebitNote(pBase);
		ElsIf TypeOf(pBase) = Type("CatalogRef.Customers") Then
			pmFillByCustomer(pBase, True);
		ElsIf TypeOf(pBase) = Type("CatalogRef.Contracts") Then
			pmFillByContract(pBase, True);
		ElsIf TypeOf(pBase) = Type("DocumentRef.CustomerPayment") Then
			pmFillByCustomerPayment(pBase);
		EndIf;
	EndIf;
	// If return, then try to set up special payment method for return
	pmSetDefaultPaymentMethodForReturn();
	pmFillContactsToOFD();
EndProcedure // Filling

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel, pWriteMode, pPostingMode)
	Var vMessage, vAttributeInErr;
	If DataExchange.Load Then
		Return;
	EndIf;
	If IsBlankString(Number) Then
		SetNewNumber();
	EndIf;
	If pWriteMode = DocumentWriteMode.Posting Then
		pCancel	= pmCheckDocumentAttributes(vMessage, vAttributeInErr);
		If pCancel Then
			WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
			tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage), MessageStatus.Attention);
			Raise NStr(vMessage);
		EndIf;
	Else
		If DeletionMark Then
			// User activity history   
			vEventDescription = NStr("en = 'Set document deletion mark'; de = 'Erstellung der Löschmarkierung'; ru = 'Установка отметки удаления'");    
			InformationRegisters.UserActionsHistory.WriteUserActivityRecord(Ref, vEventDescription, Hotel);

			AuthorOfAnnulation = SessionParameters.CurrentUser;
			DateOfAnnulation = CurrentSessionDate();
		EndIf;
	EndIf;
	WasPosted = Posted;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
Procedure BeforeDelete(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	// User activity history   
	vEventDescription = NStr("en = 'Document deletion'; de = 'Unmittelbare Löschung'; ru = 'Непосредственное удаление'");    
	InformationRegisters.UserActionsHistory.WriteUserActivityRecord(Ref, vEventDescription, Hotel);
EndProcedure // BeforeDelete

// -----------------------------------------------------------------------------
Procedure OnSetNewNumber(pStandardProcessing, pPrefix)
	vPrefix = "";
	If ValueIsFilled(Company) And Company.UsePrefixForPayments And Not IsBlankString(Company.Prefix) Then
		vPrefix = TrimAll(Company.Prefix);
	ElsIf ValueIsFilled(Hotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(Hotel);
	ElsIf ValueIsFilled(SessionParameters.CurrentHotel) Then
		If ValueIsFilled(SessionParameters.CurrentHotel.Company) And SessionParameters.CurrentHotel.Company.UsePrefixForPayments And Not IsBlankString(SessionParameters.CurrentHotel.Company.Prefix) Then
			vPrefix = TrimAll(SessionParameters.CurrentHotel.Company.Prefix);
		Else
			vPrefix = Catalogs.Hotels.pmGetPrefix(SessionParameters.CurrentHotel);
		EndIf;
	EndIf;
	If vPrefix <> "" Then
		pPrefix = vPrefix;
	EndIf;
EndProcedure // OnSetNewNumber

// -----------------------------------------------------------------------------
Procedure OnCopy(pCopiedObject)
	AccountingDate = '00010101';
	If ValueIsFilled(Hotel) And ValueIsFilled(Hotel.AccountingDate) Then
		AccountingDate = Hotel.AccountingDate;
	EndIf;
	ExternalCode = "";
EndProcedure // OnCopy

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // OnWrite

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
Function pmCheckDocumentAttributes(pMessage, pAttributeInErr) Export
	vHasErrors = False;
	pMessage = "";
	pAttributeInErr = "";
	vMsgTextRu = "";
	vMsgTextEn = "";
	vMsgTextDe = "";
	If AdditionalProperties.Property("InfoBaseUpdateMode") And AdditionalProperties.InfoBaseUpdateMode Then
		Return vHasErrors;
	EndIf;
	If Not ValueIsFilled(Company) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Фирма> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Company> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Company> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Company", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(AccountingCustomer) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Контрагент> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Customer> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Customer> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "AccountingCustomer", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(PaymentMethod) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Способ оплаты> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Payment method> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Payment method> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "PaymentMethod", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(PaymentCurrency) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Валюта платежа> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Payment currency> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Payment currency> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "PaymentCurrency", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(ExchangeRateDate) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Дата курса> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Exchange rate date> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Exchange rate date> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "ExchangeRateDate", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(PaymentSection) And ValueIsFilled(PaymentMethod) And PaymentMethod.BookByCashRegister Then
		If Not cmCheckUserPermissions("HavePermissionToPostPaymentsWithEmptyPaymentSections") Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Не указана кассовая секция (отдел)!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "<Payment section> attribute should be filled!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "<Payment section> attribute should be filled!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "PaymentSection", pAttributeInErr);
		EndIf;
	EndIf;
	If Sum < 0 Then
		If Not cmCheckUserPermissions("HavePermissionToReturnPayments") Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Нет прав на оформление возвратов!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "You do not have rights to return payments!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "You do not have rights to return payments!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "PaymentMethod", pAttributeInErr);
		EndIf;
	EndIf;
	If ValueIsFilled(PaymentMethod) Then
		If ValueIsFilled(SessionParameters.CurrentWorkstation) Then
			If Not SessionParameters.CurrentWorkstation.HasConnectionToCreditCardsProcessingSystem Or 
			   PaymentMethod.ExternalBankTerminalIsUsed Then
				If PaymentMethod.AuthorizationCodeIsRequired And IsBlankString(AuthorizationCode) Then
					vHasErrors = True; 
					vMsgTextRu = vMsgTextRu + "При оплате кредитной картой должен быть введен реквизит <Код авторизации>!" + Chars.LF;
					vMsgTextEn = vMsgTextEn + "<Authorization code> attribute should be filled for credit card payment!" + Chars.LF;
					vMsgTextDe = vMsgTextDe + "<Authorization code> attribute should be filled for credit card payment!" + Chars.LF;
					pAttributeInErr = ?(pAttributeInErr = "", "AuthorizationCode", pAttributeInErr);
				EndIf;
				If PaymentMethod.ReferenceCodeIsRequired And IsBlankString(ReferenceNumber) Then
					vHasErrors = True; 
					vMsgTextRu = vMsgTextRu + "При оплате кредитной картой должен быть введен реквизит <Референс номер>!" + Chars.LF;
					vMsgTextEn = vMsgTextEn + "<Reference number> attribute should be filled for credit card payment!" + Chars.LF;
					vMsgTextDe = vMsgTextDe + "<Reference number> attribute should be filled for credit card payment!" + Chars.LF;
					pAttributeInErr = ?(pAttributeInErr = "", "ReferenceNumber", pAttributeInErr);
				EndIf;
			EndIf;
		EndIf;
		If Not cmCheckUserPermissions("HavePermissionToDoCashAndCreditCardPaymentsWithoutCashRegister") Then
			If PaymentMethod.BookByCashRegister Then
				If Not ValueIsFilled(CashRegister) Then
					vHasErrors = True; 
					vMsgTextRu = vMsgTextRu + "Реквизит <ККМ> должен быть заполнен!" + Chars.LF;
					vMsgTextEn = vMsgTextEn + "<Cash register> attribute should be filled!" + Chars.LF;
					vMsgTextDe = vMsgTextDe + "<Cash register> attribute should be filled!" + Chars.LF;
					pAttributeInErr = ?(pAttributeInErr = "", "CashRegister", pAttributeInErr);
				EndIf;
			EndIf;
		EndIf;
		If PaymentMethod = Catalogs.PaymentMethods.Settlement Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Оплата способом оплаты Акт запрещена!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "Customer payment could not be done to City ledger!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "Firma Zahlung konnte nicht um City Ledger getan werden!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "PaymentMethod", pAttributeInErr);
		EndIf;
	EndIf;
	If ValueIsFilled(CustomerPayment) Then
		If Not cmCheckUserPermissions("HavePermissionToReturnBasedOnFolio") Then
			If ValueIsFilled(PaymentMethod) And ValueIsFilled(CustomerPayment.PaymentMethod) Then
				If CustomerPayment.PaymentMethod.IsByCash And Not PaymentMethod.IsByCash Then
					vHasErrors = True; 
					vMsgTextRu = vMsgTextRu + "Возврат можно оформить только наличными!" + Chars.LF;
					vMsgTextEn = vMsgTextEn + "Return could be done by cash only!" + Chars.LF;
					vMsgTextDe = vMsgTextDe + "Return could be done by cash only!" + Chars.LF;
					pAttributeInErr = ?(pAttributeInErr = "", "PaymentMethod", pAttributeInErr);
				ElsIf CustomerPayment.PaymentMethod.IsByCreditCard And Not PaymentMethod.IsByCreditCard Then
					vHasErrors = True; 
					vMsgTextRu = vMsgTextRu + "Возврат можно оформить только на кредитную карту!" + Chars.LF;
					vMsgTextEn = vMsgTextEn + "Return could be done by credit card only!" + Chars.LF;
					vMsgTextDe = vMsgTextDe + "Return could be done by credit card only!" + Chars.LF;
					pAttributeInErr = ?(pAttributeInErr = "", "PaymentMethod", pAttributeInErr);
				ElsIf CustomerPayment.PaymentMethod.IsByBankTransfer And Not PaymentMethod.IsByBankTransfer Then
					vHasErrors = True; 
					vMsgTextRu = vMsgTextRu + "Возврат можно оформить только банковским платежом!" + Chars.LF;
					vMsgTextEn = vMsgTextEn + "Return could be done by bank transfer only!" + Chars.LF;
					vMsgTextDe = vMsgTextDe + "Return could be done by bank transfer only!" + Chars.LF;
					pAttributeInErr = ?(pAttributeInErr = "", "PaymentMethod", pAttributeInErr);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(AccountingCustomer) And AccountingCustomer.NonResident And Not AccountingCustomer.IsIndividual And 
	   ValueIsFilled(Hotel) And ValueIsFilled(Hotel.Citizenship) And Hotel.Citizenship.Code = 643 Then // Russia only
		If ValueIsFilled(PaymentMethod) And PaymentMethod.PrintCheque And 
		  (PaymentMethod.IsByCash Or PaymentMethod.IsByCreditCard) Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Принимать платежи наличными от контрагентов нерезидентов запрещено!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "Cash payments are forbidden from non-resident customers!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "Cash payments are forbidden from non-resident customers!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "PaymentMethod", pAttributeInErr);
		EndIf;
	EndIf;
	If vHasErrors Then
		pMessage = "ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // CheckDocumentAttributes

// -----------------------------------------------------------------------------
Procedure pmFillAuthorAndDate() Export
	If Not ValueIsFilled(Date) Then
		Date = CurrentSessionDate();
	EndIf;
	If Not ValueIsFilled(Author) Then
		Author = SessionParameters.CurrentUser;
	EndIf;
EndProcedure // pmFillAuthorAndDate

// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// Fill author and document date
	pmFillAuthorAndDate();
	// New object ref
	If IsNew() Then
		If Not ValueIsFilled(GetNewObjectRef()) Then
			SetNewObjectRef(Documents.CustomerPayment.GetRef());
		EndIf;
	EndIf;
	// Fill from session parameters
	ExchangeRateDate = BegOfDay(Date);
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	vHotel = Hotel;
	If Not ValueIsFilled(vHotel) Then
		vHotels = cmGetAllHotels();
		vHotel = vHotels.Get(0).Hotel;
	EndIf;
	If ValueIsFilled(vHotel) Then
		If ValueIsFilled(Hotel.AccountingDate) And Not ValueIsFilled(AccountingDate) Then
			AccountingDate = Hotel.AccountingDate;
		EndIf;
		If Not ValueIsFilled(PaymentCurrency) Then
			PaymentCurrency = vHotel.BaseCurrency;
			If ValueIsFilled(SessionParameters.CurrentWorkstation) And ValueIsFilled(SessionParameters.CurrentWorkstation.DefaultPaymentCurrency) Then
				PaymentCurrency = SessionParameters.CurrentWorkstation.DefaultPaymentCurrency;
			EndIf;
		EndIf;
		PaymentCurrencyExchangeRate = cmGetCurrencyExchangeRate(vHotel, PaymentCurrency, ExchangeRateDate);
		If Not ValueIsFilled(Company) Then
			Company = vHotel.Company;
		EndIf;
		If ValueIsFilled(Company) Then
			VATRate = Company.VATRate;
		EndIf;
		If Not ValueIsFilled(PaymentMethod) Then
			PaymentMethod = vHotel.PaymentMethodForCustomerPayments;
		EndIf;
		AccountingCurrency = PaymentCurrency;
		AccountingCurrencyExchangeRate = PaymentCurrencyExchangeRate;
	EndIf;
	If ValueIsFilled(Author) And ValueIsFilled(Author.Company) Then
		Company = Author.Company;
		If ValueIsFilled(Company) Then
			VATRate = Company.VATRate;
		EndIf;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Procedure pmFillInvoiceRow(pInvoiceRow, pInvoice) Export
	If ValueIsFilled(Hotel) Then
		pInvoiceRow.Invoice = pInvoice;
		vBalance = pInvoice.GetObject().pmGetInvoiceBalance(?(IsNew(), Undefined, New Boundary(Date, BoundaryType.Excluding)));
		pInvoiceRow.SumInAccountingCurrency = vBalance;
		pInvoiceRow.AccountingCurrency = pInvoice.AccountingCurrency;
		pInvoiceRow.AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, pInvoiceRow.AccountingCurrency, ExchangeRateDate);
		pInvoiceRow.Sum = Round(cmConvertCurrencies(pInvoiceRow.SumInAccountingCurrency, pInvoiceRow.AccountingCurrency, pInvoiceRow.AccountingCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
		pInvoiceRow.Balance = Round(cmConvertCurrencies(vBalance, pInvoiceRow.AccountingCurrency, pInvoiceRow.AccountingCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
	EndIf;
EndProcedure // pmFillInvoiceRow

// -----------------------------------------------------------------------------
Procedure pmFillByInvoice(pInvoice) Export
	If Not ValueIsFilled(pInvoice) Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(ParentDoc) Then
		ParentDoc = pInvoice;
	EndIf;
	If Not ValueIsFilled(Hotel) Then
		Hotel = Invoice.Hotel;
	EndIf;
	
	FillPropertyValues(ThisObject, pInvoice, , "Number, Date, Author, DeletionMark, Posted, ParentDoc, Remarks");
	AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, AccountingCurrency, ExchangeRateDate);
	
	// Fill payment currency from the invoice company bank account
	If ValueIsFilled(pInvoice.BankAccount) Then
		If ValueIsFilled(pInvoice.BankAccount.AccountCurrency) Then
			PaymentCurrency = pInvoice.BankAccount.AccountCurrency;
			PaymentCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, PaymentCurrency, ExchangeRateDate);
		Endif;
	EndIf;
	
	// Fill payment method
	PaymentMethod = Catalogs.PaymentMethods.EmptyRef();
	If ValueIsFilled(Hotel) Then
		If ValueIsFilled(Hotel.PaymentMethodForCustomerPayments) Then
			PaymentMethod = Hotel.PaymentMethodForCustomerPayments;
		EndIf;
	EndIf;
	
	// Fill VAT rate
	If ValueIsFilled(Company) Then
		If ValueIsFilled(Company.VATRate) Then
			VATRate = Company.VATRate;
		EndIf;
	EndIf;
	
	If ValueIsFilled(pInvoice.GuestGroup) Then
		Invoice = pInvoice;
		vBalance = pInvoice.GetObject().pmGetInvoiceBalance(?(IsNew(), Undefined, New Boundary(Date, BoundaryType.Excluding)));
		SumInAccountingCurrency = vBalance;
		Sum = Round(cmConvertCurrencies(SumInAccountingCurrency, AccountingCurrency, AccountingCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
		VATSum = cmCalculateVATSum(VATRate, Sum, Date);
	Else
		vInvoiceRow = Invoices.Add();
		pmFillInvoiceRow(vInvoiceRow, pInvoice);
		vInvoiceGuestGroups = pInvoice.Services.Unload();
		vInvoiceGuestGroups.GroupBy("GuestGroup", "Sum");
		For Each vInvoiceGuestGroupsRow In vInvoiceGuestGroups Do
			vContractRow = Contracts.Add();
			vContractRow.AccountingContract = pInvoice.AccountingContract;
			vContractRow.GuestGroup = vInvoiceGuestGroupsRow.GuestGroup;
			vContractRow.AccountingCurrency = pInvoice.AccountingCurrency;
			vContractRow.AccountingCurrencyExchangeRate = pInvoice.AccountingCurrencyExchangeRate;
			vContractRow.Sum = vInvoiceGuestGroupsRow.Sum;
			vContractRow.SumInAccountingCurrency = Round(cmConvertCurrencies(vContractRow.Sum, PaymentCurrency, PaymentCurrencyExchangeRate, vContractRow.AccountingCurrency, vContractRow.AccountingCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
		EndDo;
	EndIf;
EndProcedure // FillByInvoice

// -----------------------------------------------------------------------------
Procedure pmFillBySettlement(pSettlement) Export
	If Not ValueIsFilled(pSettlement) Then
		Return;
	EndIf;
	
	ParentDoc = pSettlement;
	Invoice = pSettlement;
	
	FillPropertyValues(ThisObject, pSettlement, , "Number, Date, Author, DeletionMark, Posted, ParentDoc, Remarks");
	
	// Fill payment currency from the settlement company bank account
	If ValueIsFilled(pSettlement.Company) Then
		If ValueIsFilled(pSettlement.Company.BankAccount) Then
			If ValueIsFilled(pSettlement.Company.BankAccount.AccountCurrency) Then
				PaymentCurrency = pSettlement.Company.BankAccount.AccountCurrency;
				PaymentCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, PaymentCurrency, ExchangeRateDate);
			Endif;
		EndIf;
	EndIf;
	
	// Fill payment method
	PaymentMethod = Catalogs.PaymentMethods.EmptyRef();
	If ValueIsFilled(Hotel) Then
		If ValueIsFilled(Hotel.PaymentMethodForCustomerPayments) Then
			PaymentMethod = Hotel.PaymentMethodForCustomerPayments;
		EndIf;
	EndIf;
	
	// Fill VAT rate
	If ValueIsFilled(Company) Then
		If ValueIsFilled(Company.VATRate) Then
			VATRate = Company.VATRate;
		EndIf;
	EndIf;
	
	// Fill amounts
	SumInAccountingCurrency = pSettlement.SumDue;
	AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, AccountingCurrency, ExchangeRateDate);
	Sum = Round(cmConvertCurrencies(SumInAccountingCurrency, AccountingCurrency, AccountingCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
	VATSum = Round(cmConvertCurrencies(pSettlement.VATSum, AccountingCurrency, AccountingCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
	
	// Get settlement balance
	vBalanceInAccountingCurrency = cmGetCustomerAccountsBalance(, AccountingCustomer, AccountingContract, GuestGroup, AccountingCurrency, Company, Hotel);
	vBalance = Round(cmConvertCurrencies(vBalanceInAccountingCurrency, AccountingCurrency, AccountingCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
	
	// Clear tabular parts
	Invoices.Clear();
	Contracts.Clear();
EndProcedure // pmFillBySettlement

// -----------------------------------------------------------------------------
Procedure pmFillByDebitNote(pDebitNote) Export
	If Not ValueIsFilled(pDebitNote) Then
		Return;
	EndIf;
	
	ParentDoc = pDebitNote;
	
	FillPropertyValues(ThisObject, pDebitNote, , "Number, Date, Author, DeletionMark, Posted, Remarks");

	Invoice = pDebitNote;
	
	// Fill payment currency from the settlement company bank account
	If ValueIsFilled(pDebitNote.Company) Then
		If ValueIsFilled(pDebitNote.Company.BankAccount) Then
			If ValueIsFilled(pDebitNote.Company.BankAccount.AccountCurrency) Then
				PaymentCurrency = pDebitNote.Company.BankAccount.AccountCurrency;
				PaymentCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, PaymentCurrency, ExchangeRateDate);
			Endif;
		EndIf;
	EndIf;
	
	// Fill payment method
	PaymentMethod = Catalogs.PaymentMethods.EmptyRef();
	If ValueIsFilled(Hotel) Then
		If ValueIsFilled(Hotel.PaymentMethodForCustomerPayments) Then
			PaymentMethod = Hotel.PaymentMethodForCustomerPayments;
		EndIf;
	EndIf;
	
	// Fill VAT rate
	If ValueIsFilled(Company) Then
		If ValueIsFilled(Company.VATRate) Then
			VATRate = Company.VATRate;
		EndIf;
	EndIf;
	
	// Fill amounts
	SumInAccountingCurrency = pDebitNote.CorrectionSum;
	AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, AccountingCurrency, ExchangeRateDate);
	Sum = Round(cmConvertCurrencies(SumInAccountingCurrency, AccountingCurrency, AccountingCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
	VATSum = Round(cmCalculateVATSum(VATRate, Sum, Date), 2);
	
	// Get settlement balance
	vBalanceInAccountingCurrency = cmGetCustomerAccountsBalance(, AccountingCustomer, AccountingContract, GuestGroup, AccountingCurrency, Company, Hotel);
	vBalance = Round(cmConvertCurrencies(vBalanceInAccountingCurrency, AccountingCurrency, AccountingCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
	
	// Clear tabular parts
	Invoices.Clear();
	Contracts.Clear();
EndProcedure // pmFillByDebitNote

// -----------------------------------------------------------------------------
Procedure pmFillByCreditNote(pCreditNote) Export
	If Not ValueIsFilled(pCreditNote) Then
		Return;
	EndIf;
	
	ParentDoc = pCreditNote;
	
	FillPropertyValues(ThisObject, pCreditNote, , "Number, Date, Author, DeletionMark, Posted, Remarks");
	
	Invoice = pCreditNote;

	// Fill payment currency from the settlement company bank account
	If ValueIsFilled(pCreditNote.Company) Then
		If ValueIsFilled(pCreditNote.Company.BankAccount) Then
			If ValueIsFilled(pCreditNote.Company.BankAccount.AccountCurrency) Then
				PaymentCurrency = pCreditNote.Company.BankAccount.AccountCurrency;
				PaymentCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, PaymentCurrency, ExchangeRateDate);
			Endif;
		EndIf;
	EndIf;
	
	// Fill payment method
	PaymentMethod = Catalogs.PaymentMethods.EmptyRef();
	If ValueIsFilled(Hotel) Then
		If ValueIsFilled(Hotel.PaymentMethodForCustomerPayments) Then
			PaymentMethod = Hotel.PaymentMethodForCustomerPayments;
		EndIf;
	EndIf;
	
	// Fill VAT rate
	If ValueIsFilled(Company) Then
		If ValueIsFilled(Company.VATRate) Then
			VATRate = Company.VATRate;
		EndIf;
	EndIf;
	
	// Fill amounts
	SumInAccountingCurrency = -pCreditNote.CorrectionSum;
	AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, AccountingCurrency, ExchangeRateDate);
	Sum = Round(cmConvertCurrencies(SumInAccountingCurrency, AccountingCurrency, AccountingCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
	VATSum = Round(cmCalculateVATSum(VATRate, Sum, Date), 2);
	
	// Get settlement balance
	vBalanceInAccountingCurrency = cmGetCustomerAccountsBalance(, AccountingCustomer, AccountingContract, GuestGroup, AccountingCurrency, Company, Hotel);
	vBalance = Round(cmConvertCurrencies(vBalanceInAccountingCurrency, AccountingCurrency, AccountingCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
	
	// Clear tabular parts
	Invoices.Clear();
	Contracts.Clear();
EndProcedure // pmFillByCreditNote

// -----------------------------------------------------------------------------
Procedure pmFillByCustomer(pCustomer, pFillInvoices = True, pFillCurrencies = True) Export
	If Not ValueIsFilled(pCustomer) Then
		Return;
	EndIf;
	
	AccountingCustomer = pCustomer;
	
	ParentDoc = Undefined;
	
	// Fill payment currency from the company bank account
	If ValueIsFilled(Company) Then
		If ValueIsFilled(Company.BankAccount) Then
			If ValueIsFilled(Company.BankAccount.AccountCurrency) Then
				If pFillCurrencies And ValueIsFilled(Hotel) Then
					PaymentCurrency = Company.BankAccount.AccountCurrency;
					PaymentCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, PaymentCurrency, ExchangeRateDate);
				EndIf;
			Endif;
		EndIf;
	EndIf;
	
	// Fill payment method
	If pFillCurrencies Then
		If ValueIsFilled(Hotel) Then
			PaymentMethod = Catalogs.PaymentMethods.EmptyRef();
			If ValueIsFilled(Hotel.PaymentMethodForCustomerPayments) Then
				PaymentMethod = Hotel.PaymentMethodForCustomerPayments;
			EndIf;
		EndIf;
	EndIf;
	
	// Fill VAT rate
	If ValueIsFilled(Company) Then
		If ValueIsFilled(Company.VATRate) Then
			VATRate = Company.VATRate;
		EndIf;
	EndIf;
	
	// Accounting currency
	AccountingCurrency = PaymentCurrency;
	AccountingCurrencyExchangeRate = PaymentCurrencyExchangeRate;
	
	If Not ValueIsFilled(Hotel) Then
		Return;
	EndIf;
	
	// Fill contracts tabular part
	// Select all customer accounts balances for given customer, company and hotel
	vCustomerAccounts = cmGetCustomerAccountsBalances(?(IsNew(), Undefined, New Boundary(Date, BoundaryType.Excluding)), 
	                                                  AccountingCustomer, , , 
	                                                  ?(pFillCurrencies, AccountingCustomer.AccountingCurrency, AccountingCurrency), Company, Hotel, False);
	// Group balances by customer and contract if necessary
	If vCustomerAccounts.Count() > 0 Then
		If vCustomerAccounts.Count() > 1 Then
			If pFillCurrencies Then
				AccountingCurrency = AccountingCustomer.AccountingCurrency;
				AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, AccountingCurrency, ExchangeRateDate);
			EndIf;
			For Each vCustomerAccountsRow In vCustomerAccounts Do
				vContractRow = Contracts.Add();
				vContractRow.AccountingContract = vCustomerAccountsRow.AccountingContract;
				vContractRow.GuestGroup = vCustomerAccountsRow.GuestGroup;
				vContractRow.AccountingCurrency = vCustomerAccountsRow.AccountingCurrency;
				vContractRow.AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, vContractRow.AccountingCurrency, ExchangeRateDate);
				vContractRow.Balance = Round(cmConvertCurrencies(vCustomerAccountsRow.Balance, vContractRow.AccountingCurrency, vContractRow.AccountingCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
				// User have to map payment manually
				vContractRow.SumInAccountingCurrency = 0;
				vContractRow.Sum = 0;
			EndDo;
		Else
			vCustomerAccountsRow = vCustomerAccounts.Get(0);
			AccountingContract = vCustomerAccountsRow.AccountingContract;
			GuestGroup = vCustomerAccountsRow.GuestGroup;
			If pFillCurrencies Then
				AccountingCurrency = vCustomerAccountsRow.AccountingCurrency;
				AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, AccountingCurrency, ExchangeRateDate);
			EndIf;
			// User have to map payment manually
			SumInAccountingCurrency = vCustomerAccountsRow.Balance;
			Sum = Round(cmConvertCurrencies(vCustomerAccountsRow.Balance, AccountingCurrency, AccountingCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
		EndIf;		
	Else
		AccountingContract = Catalogs.Contracts.EmptyRef();
		GuestGroup = Catalogs.GuestGroups.EmptyRef();
		If pFillCurrencies Then
			AccountingCurrency = AccountingCustomer.AccountingCurrency;
			AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, AccountingCurrency, ExchangeRateDate);
		EndIf;
		SumInAccountingCurrency = 0;
		Sum = 0;
	EndIf;
	
	// Fill invoices tabular part
	If pFillInvoices Then
		// Select all invoices with balances for given customer, company and hotel
		vInvoices = cmGetInvoicesWithBalances(?(IsNew(), Undefined, New Boundary(Date, BoundaryType.Excluding)), 
		                                      AccountingCustomer, , , 
		                                      ?(pFillCurrencies, AccountingCustomer.AccountingCurrency, AccountingCurrency), Company, Hotel);
		If vInvoices.Count() > 0 Then									  
			If vInvoices.Count() > 1 Then
				For Each vInvoicesRow In vInvoices Do
					vInvoiceRow = Invoices.Add();
					vInvoiceRow.Invoice = vInvoicesRow.Invoice;
					vInvoiceRow.AccountingCurrency = vInvoicesRow.AccountingCurrency;
					vInvoiceRow.AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, vInvoiceRow.AccountingCurrency, ExchangeRateDate);
					vInvoiceRow.Balance = Round(cmConvertCurrencies(vInvoicesRow.Balance, vInvoiceRow.AccountingCurrency, vInvoiceRow.AccountingCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
					
					// User have to map payment manually
					vInvoiceRow.SumInAccountingCurrency = 0;
					vInvoiceRow.Sum = 0;
					
					// Fill appropriate contract row
					pmCalculateCustomerAccountsMapForInvoice(vInvoiceRow);
				EndDo;
			Else
				vInvoicesRow = vInvoices.Get(0);
				AccountingContract = vInvoicesRow.AccountingContract;
				GuestGroup = vInvoicesRow.GuestGroup;
				Invoice = vInvoicesRow.Invoice;
				If pFillCurrencies Then
					AccountingCurrency = vInvoicesRow.AccountingCurrency;
					AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, AccountingCurrency, ExchangeRateDate);
				EndIf;
				vBalanceInAccountingCurrency = vInvoicesRow.Balance;
				vBalance = Round(cmConvertCurrencies(vBalanceInAccountingCurrency, AccountingCurrency, AccountingCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
				SumInAccountingCurrency = vBalanceInAccountingCurrency;
				Sum = vBalance;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // pmFillByCustomer

// -----------------------------------------------------------------------------
Procedure pmFillByContract(pContract, pFillInvoices = True, pFillCurrencies = True) Export
	If Not ValueIsFilled(pContract) Then
		Return;
	EndIf;
	
	AccountingCustomer = pContract.Owner;
	AccountingContract = pContract;
	
	ParentDoc = Undefined;
	
	// Fill payment currency from the company bank account
	If ValueIsFilled(Company) Then
		If ValueIsFilled(Company.BankAccount) Then
			If ValueIsFilled(Company.BankAccount.AccountCurrency) Then
				If pFillCurrencies And ValueIsFilled(Hotel) Then
					PaymentCurrency = Company.BankAccount.AccountCurrency;
					PaymentCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, PaymentCurrency, ExchangeRateDate);
				EndIf;
			Endif;
		EndIf;
	EndIf;
	
	// Fill payment method
	If pFillCurrencies Then
		If ValueIsFilled(Hotel) Then
			PaymentMethod = Catalogs.PaymentMethods.EmptyRef();
			If ValueIsFilled(Hotel.PaymentMethodForCustomerPayments) Then
				PaymentMethod = Hotel.PaymentMethodForCustomerPayments;
			EndIf;
		EndIf;
	EndIf;
	
	// Fill VAT rate
	If ValueIsFilled(Company) Then
		If ValueIsFilled(Company.VATRate) Then
			VATRate = Company.VATRate;
		EndIf;
	EndIf;
	
	// Accounting currency
	AccountingCurrency = PaymentCurrency;
	AccountingCurrencyExchangeRate = PaymentCurrencyExchangeRate;
	
	If Not ValueIsFilled(Hotel) Then
		Return;
	EndIf;
	
	// Fill contracts tabular part
	// Select all customer accounts balances for given customer, contract, company and hotel
	vCustomerAccounts = cmGetCustomerAccountsBalances(?(IsNew(), Undefined, New Boundary(Date, BoundaryType.Excluding)), 
	                                                  AccountingCustomer, pContract, , 
	                                                  ?(pFillCurrencies, pContract.AccountingCurrency, AccountingCurrency), Company, Hotel, False);
	// Group balances by customer and contract if necessary
	If vCustomerAccounts.Count() > 0 Then
		If vCustomerAccounts.Count() > 1 Then
			If pFillCurrencies Then
				AccountingCurrency = pContract.AccountingCurrency;
				AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, AccountingCurrency, ExchangeRateDate);
			EndIf;
			For Each vCustomerAccountsRow In vCustomerAccounts Do
				vContractRow = Contracts.Add();
				vContractRow.AccountingContract = vCustomerAccountsRow.AccountingContract;
				vContractRow.GuestGroup = vCustomerAccountsRow.GuestGroup;
				vContractRow.AccountingCurrency = vCustomerAccountsRow.AccountingCurrency;
				vContractRow.AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, vContractRow.AccountingCurrency, ExchangeRateDate);
				vContractRow.Balance = Round(cmConvertCurrencies(vCustomerAccountsRow.Balance, vContractRow.AccountingCurrency, vContractRow.AccountingCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
			
				// User have to map payment manually
				vContractRow.SumInAccountingCurrency = 0;
				vContractRow.Sum = 0;
			EndDo;
		Else
			vCustomerAccountsRow = vCustomerAccounts.Get(0);
			GuestGroup = vCustomerAccountsRow.GuestGroup;
			If pFillCurrencies Then
				AccountingCurrency = vCustomerAccountsRow.AccountingCurrency;
				AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, AccountingCurrency, ExchangeRateDate);
			EndIf;
			vBalanceInAccountingCurrency = vCustomerAccountsRow.Balance;
			vBalance = Round(cmConvertCurrencies(vBalanceInAccountingCurrency, AccountingCurrency, AccountingCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
			
			// User have to map payment manually
			SumInAccountingCurrency = vBalanceInAccountingCurrency;
			Sum = vBalance;
		EndIf;
	Else
		GuestGroup = Catalogs.GuestGroups.EmptyRef();
		If pFillCurrencies Then
			AccountingCurrency = pContract.AccountingCurrency;
			AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, AccountingCurrency, ExchangeRateDate);
		EndIf;
		SumInAccountingCurrency = 0;
		Sum = 0;
	EndIf;
	
	// Fill invoices tabular part
	If pFillInvoices Then
		// Select all invoices with balances for given customer, contract, company and hotel
		vInvoices = cmGetInvoicesWithBalances(?(IsNew(), Undefined, New Boundary(Date, BoundaryType.Excluding)), 
		                                      AccountingCustomer, pContract, , 
		                                      ?(pFillCurrencies, pContract.AccountingCurrency, AccountingCurrency), Company, Hotel);
		If vInvoices.Count() > 0 Then									  
			If vInvoices.Count() > 1 Then
				For Each vInvoicesRow In vInvoices Do
					vInvoiceRow = Invoices.Add();
					vInvoiceRow.Invoice = vInvoicesRow.Invoice;
					vInvoiceRow.AccountingCurrency = vInvoicesRow.AccountingCurrency;
					vInvoiceRow.AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, vInvoiceRow.AccountingCurrency, ExchangeRateDate);
					vInvoiceRow.Balance = Round(cmConvertCurrencies(vInvoicesRow.Balance, vInvoiceRow.AccountingCurrency, vInvoiceRow.AccountingCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
					
					// User have to map payment manually
					vInvoiceRow.SumInAccountingCurrency = 0;
					vInvoiceRow.Sum = 0;
					
					// Fill appropriate contract row
					pmCalculateCustomerAccountsMapForInvoice(vInvoiceRow);
				EndDo;
			Else
				vInvoicesRow = vInvoices.Get(0);
				GuestGroup = vInvoicesRow.GuestGroup;
				Invoice = vInvoicesRow.Invoice;
				If pFillCurrencies Then
					AccountingCurrency = vInvoicesRow.AccountingCurrency;
					AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, AccountingCurrency, ExchangeRateDate);
				EndIf;
				vBalanceInAccountingCurrency = vInvoicesRow.Balance;
				vBalance = Round(cmConvertCurrencies(vBalanceInAccountingCurrency, AccountingCurrency, AccountingCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
				SumInAccountingCurrency = vBalanceInAccountingCurrency;
				Sum = vBalance;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // pmFillByContract

// -----------------------------------------------------------------------------
// This is return based on previous payment
// -----------------------------------------------------------------------------
Procedure pmFillByCustomerPayment(pPayment) Export
	If Not ValueIsFilled(pPayment) Then
		Return;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToReturnPayments") Then
		Raise NStr("en='You do not have rights to return payments!';
		           |ru='Нет прав на оформление возвратов!';
				   |de='Sie haben keine Rechte, eine Rückvergütung zu realisieren!'");
	EndIf;
	
	FillPropertyValues(ThisObject, pPayment, , "Number, Date, AccountingDate, Author, DeletionMark, Posted, Remarks, AuthorizationCode, ReferenceNumber, SlipText, AnnulationSlipText, TypeOfAnnulation, AuthorOfAnnulation, DateOfAnnulation, ExternalCode");
	
	CustomerPayment = pPayment;
	
	// Fill tabular parts and invert sums in there
	For Each vInvoiceRow In pPayment.Invoices Do
		vRow = Invoices.Add();
		FillPropertyValues(vRow, vInvoiceRow);
		vRow.Sum = -vRow.Sum;
		vRow.SumInAccountingCurrency = -vRow.SumInAccountingCurrency;
		If ValueIsFilled(vRow.Invoice) And ValueIsFilled(Hotel) Then
			vBalance = vRow.Invoice.GetObject().pmGetInvoiceBalance();
			vRow.Balance = Round(cmConvertCurrencies(vBalance, vRow.AccountingCurrency, vRow.AccountingCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
		Else
			vRow.Balance = 0;
		EndIf;
	EndDo;
	For Each vContractRow In pPayment.Contracts Do
		vRow = Contracts.Add();
		FillPropertyValues(vRow, vContractRow);
		vRow.Sum = -vRow.Sum;
		vRow.SumInAccountingCurrency = -vRow.SumInAccountingCurrency;
		If ValueIsFilled(Hotel) Then
			vBalance = cmGetCustomerAccountsBalance(, AccountingCustomer, vRow.AccountingContract, vRow.GuestGroup, vRow.AccountingCurrency, Company, Hotel);
			vRow.Balance = Round(cmConvertCurrencies(vBalance, vRow.AccountingCurrency, vRow.AccountingCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
		Else
			vRow.Balance = 0;
		EndIf;
	EndDo;
	
	// Invert amounts
	Sum = -Sum;
	VATSum = -VATSum;
	SumInAccountingCurrency = -SumInAccountingCurrency;
EndProcedure // pmFillByCustomerPayment

// -----------------------------------------------------------------------------
Procedure pmFillTabularParts(pFillInvoices = True) Export
	// Clear tabular parts
	Invoices.Clear();
	Contracts.Clear();
	// Refill tabular parts
	If ValueIsFilled(CustomerPayment) Then
		// This is return based on previous payment
		pmFillByCustomerPayment(CustomerPayment);
	Else
		If ValueIsFilled(ParentDoc) Then
			If TypeOf(ParentDoc) = Type("DocumentRef.ProformaInvoice") Then
				pmFillByInvoice(ParentDoc);
			ElsIf TypeOf(ParentDoc) = Type("DocumentRef.Settlement") Then
				pmFillBySettlement(ParentDoc);
			EndIf
		Else
			If ValueIsFilled(AccountingCustomer) Then
				pmFillByCustomer(AccountingCustomer, pFillInvoices);
			EndIf;
		EndIf;
	EndIf;
	// Recalculate totals
	pmCalculateSums();
EndProcedure // pmFillTabularParts

// -----------------------------------------------------------------------------
// Set default payment method for return
// -----------------------------------------------------------------------------
Procedure pmSetDefaultPaymentMethodForReturn() Export
	If ValueIsFilled(PaymentMethod) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	PaymentMethods.Ref
		|FROM
		|	Catalog.PaymentMethods AS PaymentMethods
		|WHERE
		|	(NOT PaymentMethods.DeletionMark)
		|	AND (PaymentMethods.IsForReturnOnly
		|			OR &qIgnoreForReturnOnly)
		|	AND PaymentMethods.IsByCash = &qIsByCash
		|	AND PaymentMethods.IsByCreditCard = &qIsByCreditCard
		|	AND PaymentMethods.IsByBankTransfer = &qIsByBankTransfer
		|ORDER BY
		|	PaymentMethods.SortCode";
		vQry.SetParameter("qIsByCash", PaymentMethod.IsByCash);
		vQry.SetParameter("qIsByCreditCard", PaymentMethod.IsByCreditCard);
		vQry.SetParameter("qIsByBankTransfer", PaymentMethod.IsByBankTransfer);
		vQry.SetParameter("qIgnoreForReturnOnly", ?(ValueIsFilled(CashRegister), CashRegister.CashReturnDirectlyFromCashBoxIsAllowed, False));
		vPMs = vQry.Execute().Unload();
		If vPMs.Count() > 0 Then
			PaymentMethod = vPMs.Get(0).Ref;
		EndIf;
	Else
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	PaymentMethods.Ref
		|FROM
		|	Catalog.PaymentMethods AS PaymentMethods
		|WHERE
		|	(NOT PaymentMethods.DeletionMark)
		|	AND (PaymentMethods.IsForReturnOnly
		|			OR &qIgnoreForReturnOnly)
		|ORDER BY
		|	PaymentMethods.SortCode";
		vQry.SetParameter("qIgnoreForReturnOnly", ?(ValueIsFilled(CashRegister), CashRegister.CashReturnDirectlyFromCashBoxIsAllowed, False));
		vPMs = vQry.Execute().Unload();
		If vPMs.Count() > 0 Then
			PaymentMethod = vPMs.Get(0).Ref;
		EndIf;
	EndIf;
EndProcedure // pmSetDefaultPaymentMethodForReturn

// -----------------------------------------------------------------------------
Procedure pmCalculateCustomerAccountsMapForInvoice(pCurRow) Export
	If Not ValueIsFilled(pCurRow.Invoice) Then
		Return;
	EndIf;
	// Fill guest group for invoices
	vContractRowSum = 0;
	vCurContract = pCurRow.Invoice.AccountingContract;
	vCurGuestGroup = pCurRow.Invoice.GuestGroup;
	vInvoices = Invoices.Unload();
	vInvoices.Columns.Add("AccountingContract", cmGetCatalogTypeDescription("Contracts"));
	vInvoices.Columns.Add("GuestGroup", cmGetCatalogTypeDescription("GuestGroups"));
	For Each vRow In vInvoices Do
		If ValueIsFilled(vRow.Invoice) Then
			vRow.AccountingContract = vRow.Invoice.AccountingContract;
			vRow.GuestGroup = vRow.Invoice.GuestGroup;
		EndIf;
	EndDo;
	vInvoices.GroupBy("AccountingContract, GuestGroup", "Sum");
	vRows = vInvoices.FindRows(New Structure("AccountingContract, GuestGroup", vCurContract, vCurGuestGroup));
	If vRows.Count() = 0 Then
		vInvoices.GroupBy("AccountingContract", "Sum");
		vRows = vInvoices.FindRows(New Structure("AccountingContract", vCurContract));
	EndIf;
	If vRows.Count() > 0 Then
		For Each vRow In vRows Do
			vContractRowSum = vContractRowSum + vRow.Sum;
		EndDo;
	EndIf;
	// Check if there is suitable row in contracts. Create it if not
	vContractRow = Undefined;
	For Each vRow In Contracts Do
		If pCurRow.Invoice.AccountingContract = vRow.AccountingContract And
		   pCurRow.Invoice.GuestGroup = vRow.GuestGroup And
		   pCurRow.AccountingCurrency = vRow.AccountingCurrency Then
			vContractRow = vRow;
			Break;
		EndIf;
	EndDo;
	If vContractRow = Undefined Then
		vContractRow = Contracts.Add();
	EndIf;
	vContractRow.AccountingContract = pCurRow.Invoice.AccountingContract;
	vContractRow.GuestGroup = pCurRow.Invoice.GuestGroup;
	vContractRow.AccountingCurrency = pCurRow.AccountingCurrency;
	vContractRow.Sum = vContractRowSum;
	If ValueIsFilled(Hotel) Then
		vContractRow.SumInAccountingCurrency = Round(cmConvertCurrencies(vContractRow.Sum, PaymentCurrency, PaymentCurrencyExchangeRate, vContractRow.AccountingCurrency, vContractRow.AccountingCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
	Else
		vContractRow.SumInAccountingCurrency = vContractRow.Sum;
	EndIf;
EndProcedure // pmCalculateCustomerAccountsMapForInvoice

// -----------------------------------------------------------------------------
Procedure pmCalculateSums() Export
	If Contracts.Count() > 0 Then
		vSum = Contracts.Total("Sum");
		If vSum <> Sum Then
			Sum = vSum;
		EndIf;
		vSumInAccountingCurrency = Contracts.Total("SumInAccountingCurrency");
		If SumInAccountingCurrency <> vSumInAccountingCurrency Then
			SumInAccountingCurrency = vSumInAccountingCurrency;
		EndIf;
	EndIf;
	vVATSum = cmCalculateVATSum(VATRate, Sum, Date);
	If vVATSum <> VATSum Then
		VATSum = vVATSum;
	EndIf;
EndProcedure // pmCalculateSums

// --------------------------------------------------------------------------------
Procedure pmFillContactsToOFD() Export
	If ValueIsFilled(CashRegister) And CashRegister.IsControlledByProgram And
		ValueIsFilled(PaymentMethod) And PaymentMethod.BookByCashRegister And PaymentMethod.PrintCheque Then
		SendPayerContactsToOFD = CashRegister.SendPayerContactsToOFD; 
	Else
		SendPayerContactsToOFD = 2;
	EndIf;
	If ValueIsFilled(AccountingCustomer) Then
		EmailToSendToOFD = AccountingCustomer.EMail;
		PhoneToSendToOFD = AccountingCustomer.Phone;
	Else
		EmailToSendToOFD = "";
		PhoneToSendToOFD = "";
	EndIf;
EndProcedure // pmFillContactsToOFD

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure PostToCustomerAccounts()
	If Contracts.Count() > 0 Then
		For Each vRow In Contracts Do
			Movement = RegisterRecords.CustomerAccounts.Add();
			
			Movement.RecordType = AccumulationRecordType.Expense;
			Movement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
			
			If ValueIsFilled(ParentDoc) Then
				FillPropertyValues(Movement, ParentDoc);
			EndIf;
			FillPropertyValues(Movement, ThisObject);
			FillPropertyValues(Movement, vRow);
			
			// Resources
			Movement.Sum = vRow.SumInAccountingCurrency;
			
			// Attributes
			Movement.VATSum = cmCalculateVATSum(VATRate, Movement.Sum, Date);
			Movement.AccountingDate = ?(ValueIsFilled(AccountingDate), AccountingDate, BegOfDay(Date));
		EndDo;
	Else
		Movement = RegisterRecords.CustomerAccounts.Add();
		
		Movement.RecordType = AccumulationRecordType.Expense;
		Movement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
		
		If ValueIsFilled(ParentDoc) Then
			FillPropertyValues(Movement, ParentDoc);
		EndIf;
		FillPropertyValues(Movement, ThisObject);
		
		// Resources
		Movement.Sum = SumInAccountingCurrency;
		
		// Attributes
		Movement.VATSum = cmCalculateVATSum(VATRate, Movement.Sum, Date);
		Movement.AccountingDate = ?(ValueIsFilled(AccountingDate), AccountingDate, BegOfDay(Date));
	EndIf;
EndProcedure // PostToCustomerAccounts

// -----------------------------------------------------------------------------
Procedure PostToCustomerDeposits()
	If Invoices.Count() > 0 Then
		For Each vRow In Invoices Do
			If ValueIsFilled(vRow.Invoice) And TypeOf(vRow.Invoice) = Type("DocumentRef.ProformaInvoice") And vRow.SumInAccountingCurrency <> 0 Then
				Movement = RegisterRecords.CustomerDeposits.Add();
				
				Movement.RecordType = AccumulationRecordType.Receipt;
				Movement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
				
				Movement.ProformaInvoice = vRow.Invoice;
				Movement.AccountingCurrency = vRow.AccountingCurrency;
				Movement.Hotel = Hotel;
				
				Movement.Sum = vRow.SumInAccountingCurrency;
			EndIf;
		EndDo;
	EndIf;
	
	If ValueIsFilled(Invoice) And TypeOf(Invoice) = Type("DocumentRef.ProformaInvoice") Then
		Movement = RegisterRecords.CustomerDeposits.Add();
		
		Movement.RecordType = AccumulationRecordType.Receipt;
		Movement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
		
		Movement.ProformaInvoice = Invoice;
		Movement.AccountingCurrency = AccountingCurrency;
		Movement.Hotel = Hotel;
		
		Movement.Sum = SumInAccountingCurrency;
	EndIf;
EndProcedure // PostToCustomerDeposits

// -----------------------------------------------------------------------------
Procedure PostToInvoiceAccounts()
	If Invoices.Count() > 0 Then
		For Each vRow In Invoices Do
			If vRow.SumInAccountingCurrency <> 0 Then
				Movement = RegisterRecords.InvoiceAccounts.Add();
				
				Movement.RecordType = AccumulationRecordType.Expense;
				Movement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
				
				If ValueIsFilled(ParentDoc) Then
					FillPropertyValues(Movement, ParentDoc);
				EndIf;
				If ValueIsFilled(vRow.Invoice) Then
					FillPropertyValues(Movement, vRow.Invoice);
				EndIf;
				FillPropertyValues(Movement, ThisObject, , "AccountingContract, GuestGroup, Invoice");
				FillPropertyValues(Movement, vRow);
				
				Movement.AccountingContract = vRow.Invoice.AccountingContract;
				
				// Resources
				Movement.Sum = vRow.SumInAccountingCurrency;
				
				// Attributes
				Movement.VATSum = cmCalculateVATSum(VATRate, Movement.Sum, Date);
				Movement.AccountingDate = ?(ValueIsFilled(AccountingDate), AccountingDate, BegOfDay(Date));
			EndIf;
		EndDo;
	EndIf;
	
	If ValueIsFilled(Invoice) Then
		Movement = RegisterRecords.InvoiceAccounts.Add();
		
		Movement.RecordType = AccumulationRecordType.Expense;
		Movement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
		
		If ValueIsFilled(ParentDoc) Then
			FillPropertyValues(Movement, ParentDoc);
		EndIf;
		If ValueIsFilled(Invoice) Then
			FillPropertyValues(Movement, Invoice);
		EndIf;
		FillPropertyValues(Movement, ThisObject);
		
		Movement.AccountingContract = Invoice.AccountingContract;
		
		// Resources
		Movement.Sum = SumInAccountingCurrency;
		
		// Attributes
		Movement.VATSum = cmCalculateVATSum(VATRate, Movement.Sum, Date);
		Movement.AccountingDate = ?(ValueIsFilled(AccountingDate), AccountingDate, BegOfDay(Date));
	EndIf;
EndProcedure // PostToInvoiceAccounts

// -----------------------------------------------------------------------------
Procedure PostToPayments()
	Movement = RegisterRecords.Payments.Add();
	
	Movement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
	
	FillPropertyValues(Movement, ThisObject);
	
	// Dimensions
	Movement.Payer = AccountingCustomer;
	Movement.AccountingDate = ?(ValueIsFilled(AccountingDate), AccountingDate, BegOfDay(Date));
	
	// Resources
	If Sum >= 0 Then
		Movement.SumReceipt = Sum;
		Movement.VATSumReceipt = VATSum;
		Movement.SumExpense = 0;
		Movement.VATSumExpense = 0;
	Else
		Movement.SumReceipt = 0;
		Movement.VATSumReceipt = 0;
		Movement.SumExpense = -Sum;
		Movement.VATSumExpense = -VATSum;
	EndIf;
EndProcedure // PostToPayments

// -----------------------------------------------------------------------------
Procedure PostToCashRegisterDailyReceipts()
	If Contracts.Count() > 0 Then
		For Each vRow In Contracts Do
			Movement = RegisterRecords.CashRegisterDailyReceipts.AddReceipt();
			
			Movement.Period = Date;
			Movement.Currency = PaymentCurrency;
			
			If ValueIsFilled(ParentDoc) Then
				FillPropertyValues(Movement, ParentDoc);
			EndIf;
			FillPropertyValues(Movement, ThisObject);
			
			// Dimensions
			Movement.Customer = AccountingCustomer;
			Movement.Contract = vRow.AccountingContract;
			Movement.GuestGroup = vRow.GuestGroup;
			Movement.Payment = Ref;
			
			// Resources
			Movement.Sum = vRow.Sum;
			Movement.VATSum = cmCalculateVATSum(VATRate, Movement.Sum, Date);
			If Movement.Sum < 0 Then
				Movement.PaymentSum = 0;
				Movement.VATPaymentSum = 0;
				Movement.ReturnSum = -Movement.Sum;
				Movement.VATReturnSum = -Movement.VATSum;
			Else
				Movement.PaymentSum = Movement.Sum;
				Movement.VATPaymentSum = Movement.VATSum;
				Movement.ReturnSum = 0;
				Movement.VATReturnSum = 0;
			EndIf;
			
			// Attributes
			Movement.Payer = AccountingCustomer;
		EndDo;
	Else
		Movement = RegisterRecords.CashRegisterDailyReceipts.AddReceipt();
		
		Movement.Period = Date;
		Movement.Currency = PaymentCurrency;
		
		If ValueIsFilled(ParentDoc) Then
			FillPropertyValues(Movement, ParentDoc);
		EndIf;
		FillPropertyValues(Movement, ThisObject);
		
		// Dimensions
		Movement.Customer = AccountingCustomer;
		Movement.Contract = AccountingContract;
		Movement.GuestGroup = GuestGroup;
		Movement.Payment = Ref;
		
		// Resources
		Movement.Sum = Sum;
		Movement.VATSum = cmCalculateVATSum(VATRate, Movement.Sum, Date);
		If Movement.Sum < 0 Then
			Movement.PaymentSum = 0;
			Movement.VATPaymentSum = 0;
			Movement.ReturnSum = -Movement.Sum;
			Movement.VATReturnSum = -Movement.VATSum;
		Else
			Movement.PaymentSum = Movement.Sum;
			Movement.VATPaymentSum = Movement.VATSum;
			Movement.ReturnSum = 0;
			Movement.VATReturnSum = 0;
		EndIf;
		
		// Attributes
		Movement.Payer = AccountingCustomer;
	EndIf;
EndProcedure // PostToCashRegisterDailyReceipts

// -----------------------------------------------------------------------------
Procedure PostToCashInCashRegisters()
	Movement = RegisterRecords.CashInCashRegisters.Add();
	
	Movement.Period = Date;
	Movement.Currency = PaymentCurrency;
	
	FillPropertyValues(Movement, ThisObject);
	
	If Sum < 0 Then
		Movement.RecordType = AccumulationRecordType.Expense;
		Movement.Sum = -Sum;
	Else
		Movement.RecordType = AccumulationRecordType.Receipt;
		Movement.Sum = Sum;
	EndIf;
EndProcedure // PostToCashInCashRegisters

// -----------------------------------------------------------------------------
Procedure Posting(pCancel, pMode)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// 1. Post to Customer accounts
	PostToCustomerAccounts();
	
	// 2. Post to Customer deposits
	PostToCustomerDeposits();
	
	// 3. Post to Payments
	PostToPayments();
	
	// 4. Post to Close of cash register day debits
	If ValueIsFilled(CashRegister) And ValueIsFilled(PaymentMethod) Then
		If PaymentMethod.BookByCashRegister Then
			PostToCashRegisterDailyReceipts();
			// 3. Post to cash in cash registers
			If PaymentMethod.IsByCash Then
				PostToCashInCashRegisters();
			EndIf;
		EndIf;
	EndIf;

	// 5. Create invoice if necessary
	If Not PaymentMethod.IsCloseToTheRoom And Not PaymentMethod.IsCloseToTheFolio Then
		If ValueIsFilled(Hotel) And Hotel.PaymentsGenerateInvoices Then
			If Not ValueIsFilled(Invoice) Then
				// Generate proforma invoice
				vInvObj = Documents.ProformaInvoice.CreateDocument();
				vInvObj.Date = Date + 1;
				vInvObj.Fill(Ref);
				vInvObj.Write(DocumentWriteMode.Posting);
				// Save proforma invoice reference to the customer payment
				Invoice = vInvObj.Ref;
			EndIf;					
		EndIf;
	EndIf;
	
	// Save data if there were changes
	If Modified() Then
		Write(DocumentWriteMode.Write);
	EndIf;
	
	// 6. Post to Invoice accounts
	PostToInvoiceAccounts();
	
	// 7. Post to chart of accounts FO postings
	WriteCustomerAccountsFOPostings();
	
	// 8. Send payment SMS
	If Not WasPosted Then
		vMessageDeliveryError = "";
		If Not SMS.SendPaymentMessage(AccountingCustomer, GuestGroup, ?(ValueIsFilled(GuestGroup), GuestGroup.ClientDoc, Undefined), cmFormatSum(Sum, PaymentCurrency), PaymentMethod, Ref, vMessageDeliveryError) Then
			WriteLogEvent(NStr("en='Document.MessageDelivery';ru='Документ.РассылкаСообщений';de='Document.MessageDelivery'"), EventLogLevel.Warning, Metadata(), Ref, vMessageDeliveryError);
			tcCommonFunctionOnClientServer.TextMessage(vMessageDeliveryError, MessageStatus.Attention);
		EndIf;
	EndIf;
EndProcedure // Posting

// -----------------------------------------------------------------------------
Procedure WriteCustomerAccountsFOPostings()
	// Do nothing if paid amount is zero
	vPostingAmount = SumInAccountingCurrency;
	If vPostingAmount = 0 Then
		Return;
	EndIf;
	
	// Get service account
	vAccountStruct = cmGetAccountCodeForPOSAndPaymentMethod(Hotel, Company, CashRegister, PaymentMethod, PaymentSection);
	vPostingAccount = vAccountStruct.Account;
	If Not ValueIsFilled(vPostingAccount) Then
		Return;
	EndIf;
	vCorrespondingAccountStruct = cmGetAccountCodeForCustomer(Hotel, Company, AccountingCustomer, AccountingContract);
	vCorrespondingAccount = vCorrespondingAccountStruct.Account;
	If Not ValueIsFilled(vCorrespondingAccount) Then
		Return;
	EndIf;
	
	// Postings currency
	vAccountCurrency = AccountingCurrency;
	
	vReverseSign = False;
	If vPostingAmount < 0 Then
		vReverseSign = True;
		
		vPostingAmount = -vPostingAmount;
	EndIf;
	
	// Commission percent
	vCommissionAccount = Undefined;
	vCommissionPercent = 0;
	vCommissionAmount = 0;
	If ValueIsFilled(vAccountStruct.CommissionAccount) And vAccountStruct.CommissionPercent <> 0 Then
		vCommissionAccount = vAccountStruct.CommissionAccount;
		vCommissionPercent = vAccountStruct.CommissionPercent;
		vCommissionAmount = Round(vPostingAmount * vCommissionPercent / 100, 2);
	EndIf;
	
	// Create movement for this payment
	PostingMovement = Undefined;
	If vPostingAccount.Type = AccountType.Passive Then
		If vReverseSign Then
			PostingMovement = RegisterRecords.PostingsFO.AddDebit();
		Else
			PostingMovement = RegisterRecords.PostingsFO.AddCredit();
		EndIf;
	ElsIf vPostingAccount.Type = AccountType.Active Then
		If vReverseSign Then
			PostingMovement = RegisterRecords.PostingsFO.AddCredit();
		Else
			PostingMovement = RegisterRecords.PostingsFO.AddDebit();
		EndIf;
	Else
		Raise NStr("en='Sign is not defined for account '; ru='Знак не указан в настройках счета '; de='Das buchungszeichen ist in den Konto nicht angegeben '") + vPostingAccount;
	EndIf;
	
	PostingMovement.Active = True;
	
	PostingMovement.Account = vPostingAccount;
	PostingMovement.CorrAccount = vCorrespondingAccount;
	
	PostingMovement.Amount = vPostingAmount - vCommissionAmount;
	PostingMovement.GrosAmount = 0;
	
	PostingMovement.Description = TrimAll(Ref);
	
	PostingMovement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
	PostingMovement.FODate = ?(ValueIsFilled(AccountingDate), AccountingDate, BegOfDay(Date));
	PostingMovement.ServiceDate = '00010101';
	PostingMovement.Days = 0;
				
	PostingMovement.ParentDoc = Undefined;
	
	PostingMovement.Room = Undefined;
	PostingMovement.Resource = Undefined;
	
	PostingMovement.Service = Undefined;
	PostingMovement.PaymentMethod = PaymentMethod;
	PostingMovement.AccountingCustomer = AccountingCustomer;
		
	PostingMovement.AccountGroup = vPostingAccount.AccountGroup;
	PostingMovement.AccountType = vPostingAccount.AccountType;
	PostingMovement.Department = vPostingAccount.Department;
	PostingMovement.DiscountType = vPostingAccount.DiscountType;
	PostingMovement.ServiceType = vPostingAccount.ServiceType;
	
	PostingMovement.Hotel = Hotel;
	PostingMovement.Company = Company;
	PostingMovement.Currency = vAccountCurrency;
	
	PostingMovement.Discount = 0;
	PostingMovement.DiscountAmount = 0;
	
	PostingMovement.VATAmount = 0;
	PostingMovement.VATRate = Undefined;
	
	PostingMovement.POSTicket = "";
	PostingMovement.Invoice = Undefined;
	
	PostingMovement.Recorder = Ref;
	PostingMovement.Author = Author;
	
	// Create corresponding account debit movement
	If PostingMovement.RecordType = AccountingRecordType.Debit Then
		PostingMovement = RegisterRecords.PostingsFO.AddCredit();
	Else
		PostingMovement = RegisterRecords.PostingsFO.AddDebit();
	EndIf;
				
	PostingMovement.Active = True;
	
	PostingMovement.Account = vCorrespondingAccount;
	PostingMovement.CorrAccount = vPostingAccount;
	
	PostingMovement.Amount = vPostingAmount;
	PostingMovement.GrosAmount = 0;
	
	PostingMovement.Description = TrimAll(Ref);
	
	PostingMovement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
	PostingMovement.FODate = ?(ValueIsFilled(AccountingDate), AccountingDate, BegOfDay(Date));
	PostingMovement.ServiceDate = '00010101';
	PostingMovement.Days = 0;
				
	PostingMovement.ParentDoc = Undefined;
	
	PostingMovement.Room = Undefined;
	PostingMovement.Resource = Undefined;
	
	PostingMovement.Service = Undefined;
	PostingMovement.PaymentMethod = PaymentMethod;
	PostingMovement.AccountingCustomer = AccountingCustomer;
		
	PostingMovement.AccountGroup = vCorrespondingAccount.AccountGroup;
	PostingMovement.AccountType = vCorrespondingAccount.AccountType;
	PostingMovement.Department = vCorrespondingAccount.Department;
	PostingMovement.DiscountType = vCorrespondingAccount.DiscountType;
	PostingMovement.ServiceType = vCorrespondingAccount.ServiceType;
	
	PostingMovement.Hotel = Hotel;
	PostingMovement.Company = Company;
	PostingMovement.Currency = vAccountCurrency;
	
	PostingMovement.Discount = 0;
	PostingMovement.DiscountAmount = 0;
	
	PostingMovement.VATAmount = 0;
	PostingMovement.VATRate = Undefined;
	
	PostingMovement.POSTicket = "";
	PostingMovement.Invoice = Undefined;
	
	PostingMovement.Recorder = Ref;
	PostingMovement.Author = Author;
	
	// Commission
	If vCommissionAccount <> Undefined And vCommissionAmount <> 0 Then
		If vPostingAccount.Type = AccountType.Passive Then
			If vReverseSign Then
				PostingMovement = RegisterRecords.PostingsFO.AddDebit();
			Else
				PostingMovement = RegisterRecords.PostingsFO.AddCredit();
			EndIf;
		ElsIf vPostingAccount.Type = AccountType.Active Then
			If vReverseSign Then
				PostingMovement = RegisterRecords.PostingsFO.AddCredit();
			Else
				PostingMovement = RegisterRecords.PostingsFO.AddDebit();
			EndIf;
		Else
			Raise NStr("en='Sign is not defined for account '; ru='Знак не указан в настройках счета '; de='Das buchungszeichen ist in den Konto nicht angegeben '") + vPostingAccount;
		EndIf;
		
		PostingMovement.Active = True;
		
		PostingMovement.Account = vCommissionAccount;
		PostingMovement.CorrAccount = vCorrespondingAccount;
		
		PostingMovement.Amount = vCommissionAmount;
		PostingMovement.GrosAmount = 0;
		
		PostingMovement.Description = TrimAll(vCommissionPercent) + "%";
		
		PostingMovement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
		PostingMovement.FODate = ?(ValueIsFilled(AccountingDate), AccountingDate, BegOfDay(Date));
		PostingMovement.ServiceDate = '00010101';
		PostingMovement.Days = 0;
					
		PostingMovement.ParentDoc = Undefined;
		
		PostingMovement.Room = Undefined;
		PostingMovement.Resource = Undefined;
		
		PostingMovement.Service = Undefined;
		PostingMovement.PaymentMethod = PaymentMethod;
		PostingMovement.AccountingCustomer = AccountingCustomer;
			
		PostingMovement.AccountGroup = vPostingAccount.AccountGroup;
		PostingMovement.AccountType = vPostingAccount.AccountType;
		PostingMovement.Department = vPostingAccount.Department;
		PostingMovement.DiscountType = vPostingAccount.DiscountType;
		PostingMovement.ServiceType = vPostingAccount.ServiceType;
		
		PostingMovement.Hotel = Hotel;
		PostingMovement.Company = Company;
		PostingMovement.Currency = vAccountCurrency;
		
		PostingMovement.Discount = 0;
		PostingMovement.DiscountAmount = 0;
		
		PostingMovement.VATAmount = 0;
		PostingMovement.VATRate = Undefined;
		
		PostingMovement.POSTicket = "";
		PostingMovement.Invoice = Undefined;
		
		PostingMovement.Recorder = Ref;
		PostingMovement.Author = Author;
	EndIf;
EndProcedure // WriteCustomerAccountsFOPostings

#EndRegion

#Region Initialize

// -----------------------------------------------------------------------------
WasPosted = True;

#EndRegion
