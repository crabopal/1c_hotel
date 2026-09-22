
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
	If Not ValueIsFilled(AccountingCurrency) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Валюта взаиморасчетов> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Accounting currency> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Accounting currency> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "AccountingCurrency", pAttributeInErr);
	EndIf;
	If SumAdvance < GuestGroups.Total("Sum") Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Распределена сумма больше чем сумма аванса у контрагента!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "You have distributed amount that greater then customer advance amount!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "You have distributed amount that greater then customer advance amount!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "GuestGroups", pAttributeInErr);
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
	// Fill from session parameters
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	vHotel = Hotel;
	If Not ValueIsFilled(vHotel) Then
		vHotels = cmGetAllHotels();
		vHotel = vHotels.Get(0).Hotel;
	EndIf;
	If ValueIsFilled(vHotel) Then
		If ValueIsFilled(vHotel.AccountingDate) And Not ValueIsFilled(AccountingDate) Then
			AccountingDate = vHotel.AccountingDate;
		EndIf;
		If Not ValueIsFilled(AccountingCurrency) Then
			AccountingCurrency = vHotel.BaseCurrency;
		EndIf;
		If Not ValueIsFilled(Company) Then
			Company = vHotel.Company;
		EndIf;
	EndIf;
	If ValueIsFilled(Author) And ValueIsFilled(Author.Company) Then
		Company = Author.Company;
	EndIf;
	If Not ValueIsFilled(OperationType) Then
		OperationType = Enums.AdvanceDistributionTypes.ByProformaInvoices;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetCustomerAdvanceBalance() Export
	// Get current customer accounting balance
	vSumAdvance = 0;
	vCustomerAccounts = cmGetCustomerAccountsBalances(?(IsNew(), Undefined, New Boundary(Date, BoundaryType.Excluding)), 
	                                                  AccountingCustomer, AccountingContract, Catalogs.GuestGroups.EmptyRef(), 
	                                                  AccountingCurrency, Company, ?(ValueIsFilled(Hotel), Hotel, Undefined), False);
	vSumAdvance = -vCustomerAccounts.Total("Balance");
	Return vSumAdvance;
EndFunction // pmGetCustomerAdvanceBalance

// -----------------------------------------------------------------------------
Function pmGetInvoiceDeposit() Export
	// Get current customer accounting balance
	vSumAdvance = 0;
	If ValueIsFilled(ProformaInvoice) Then
		//[TODO]
	EndIf;
	Return vSumAdvance;
EndFunction // pmGetInvoiceBalance

// -----------------------------------------------------------------------------
Procedure pmFillInvoiceRow(pInvoiceRow, pInvoice, pSumAdvance, pInvoiceBalance, pGuestGroup = Undefined) Export
	pInvoiceRow.Invoice = pInvoice;
	pInvoiceRow.AccountingContract = pInvoice.AccountingContract;
	pInvoiceRow.GuestGroup = pInvoice.GuestGroup;
	If ValueIsFilled(pGuestGroup) Then
		pInvoiceRow.GuestGroup = pGuestGroup;
	EndIf;
	pInvoiceRow.Balance = pInvoiceBalance;
	If pInvoiceRow.Balance > 0 And pSumAdvance > 0 Then
		If pInvoiceRow.Balance > pSumAdvance Then
			pInvoiceRow.Sum = pSumAdvance;
		Else
			pInvoiceRow.Sum = pInvoiceRow.Balance;
		EndIf;
		pSumAdvance = pSumAdvance - pInvoiceRow.Balance;
	EndIf;
EndProcedure // pmFillInvoiceRow

// -----------------------------------------------------------------------------
Procedure pmFillGroupRow(pGroupRow, pGuestGroup, pAccountingContract, pSumAdvance, pGroupBalance) Export
	pGroupRow.Invoice = Documents.ProformaInvoice.EmptyRef();
	pGroupRow.AccountingContract = pAccountingContract;
	pGroupRow.GuestGroup = pGuestGroup;
	pGroupRow.Balance = pGroupBalance;
	If pGroupRow.Balance > 0 And pSumAdvance > 0 Then
		If pGroupRow.Balance > pSumAdvance Then
			pGroupRow.Sum = pSumAdvance;
		Else
			pGroupRow.Sum = pGroupRow.Balance;
		EndIf;
		pSumAdvance = pSumAdvance - pGroupRow.Balance;
	EndIf;
EndProcedure // pmFillGroupRow

// -----------------------------------------------------------------------------
Procedure pmFillByProformaInvoice(pInvoice) Export
	If Not ValueIsFilled(pInvoice) Or ValueIsFilled(pInvoice) And TypeOf(pInvoice) <> Type("DocumentRef.ProformaInvoice") Then
		Return;
	EndIf;
	OperationType = Enums.AdvanceDistributionTypes.BySettlementInvoices;
	GuestGroups.Clear();
	
	// Fill document properties based on invoice ones
	FillPropertyValues(ThisObject, pInvoice, , "Number, Date, Author, DeletionMark, Posted, Remarks");
	ProformaInvoice = pInvoice;
	
	// Get settlement invoices 
	SumAdvance = ProformaInvoice.GetObject().pmGetDepositBalance();
	If SumAdvance > 0 Then
		// Fill guest groups tabular part by settlement invoices
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	InvoiceAccountsBalance.Invoice,
		|	InvoiceAccountsBalance.SumBalance
		|FROM
		|	AccumulationRegister.InvoiceAccounts.Balance(
		|			&qPeriod,
		|			Hotel = &qHotel
		|				AND Company = &qCompany
		|				AND AccountingCurrency = &qAccountingCurrency
		|				AND (&qGuestGroupIsFilled
		|						AND GuestGroup = &qGuestGroup
		|					OR NOT &qGuestGroupIsFilled)
		|				AND (&qAccountingCustomerIsFilled
		|						AND AccountingCustomer = &qAccountingCustomer
		|					OR NOT &qAccountingCustomerIsFilled)
		|				AND (&qAccountingContractIsFilled
		|						AND AccountingContract = &qAccountingContract
		|					OR NOT &qAccountingContractIsFilled)
		|				AND Invoice REFS Document.Settlement) AS InvoiceAccountsBalance
		|WHERE
		|	InvoiceAccountsBalance.SumBalance > 0
		|
		|ORDER BY
		|	InvoiceAccountsBalance.Invoice.PointInTime";
		vQry.SetParameter("qPeriod", '00010101');
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qCompany", Company);
		vQry.SetParameter("qGuestGroup", GuestGroup);
		vQry.SetParameter("qGuestGroupIsFilled", ValueIsFilled(GuestGroup));
		vQry.SetParameter("qAccountingCustomer", AccountingCustomer);
		vQry.SetParameter("qAccountingCustomerIsFilled", ValueIsFilled(AccountingCustomer));
		vQry.SetParameter("qAccountingContract", AccountingContract);
		vQry.SetParameter("qAccountingContractIsFilled", ValueIsFilled(AccountingContract));
		vQry.SetParameter("qAccountingCurrency", AccountingCurrency);
		vSettlements = vQry.Execute().Unload();
		
		vSumAdvance = SumAdvance;
		For Each vRow In vSettlements Do
			vRowSum = Min(vRow.SumBalance, vSumAdvance); 
			
			If vRowSum > 0 Then
				vGuestGroupsRow = GuestGroups.Add();
				vGuestGroupsRow.Invoice = vRow.Invoice;
				vGuestGroupsRow.Sum = vRowSum;
				vGuestGroupsRow.Balance = vRow.SumBalance;
				vGuestGroupsRow.AccountingContract = vRow.Invoice.AccountingContract;
				vGuestGroupsRow.GuestGroup = vRow.Invoice.GuestGroup;
			EndIf;
			
			vSumAdvance = vSumAdvance - vRowSum;
			If vSumAdvance <= 0 Then
				Break;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // pmFillByProformaInvoice

// -----------------------------------------------------------------------------
Procedure pmFillByInvoice(pInvoice) Export
	If Not ValueIsFilled(pInvoice) Or ValueIsFilled(pInvoice) And TypeOf(pInvoice) <> Type("DocumentRef.Settlement") Then
		Return;
	EndIf;
	OperationType = Enums.AdvanceDistributionTypes.BySettlementInvoices;
	GuestGroups.Clear();
	
	// Fill document properties based on invoice ones
	FillPropertyValues(ThisObject, pInvoice, , "Number, Date, Author, DeletionMark, Posted, Remarks");
	ProformaInvoice = Undefined;
	
	
	// Get document advance balance
	SumAdvance = pmGetCustomerAdvanceBalance();
	
	// Add 1 row for this invoice
	vGuestGroupsRow = GuestGroups.Add();
	vGuestGroupsRow.Invoice = pInvoice;
	vGuestGroupsRow.Sum = 0;
	vGuestGroupsRow.Balance = pInvoice.GetObject().pmGetInvoiceBalance();
	vGuestGroupsRow.AccountingContract = pInvoice.AccountingContract;
	vGuestGroupsRow.GuestGroup = pInvoice.GuestGroup;
EndProcedure // pmFillByInvoice

// -----------------------------------------------------------------------------
Procedure pmFillByDebitNote(pDebitNote) Export
	If Not ValueIsFilled(pDebitNote) Or ValueIsFilled(pDebitNote) And TypeOf(pDebitNote) <> Type("DocumentRef.DebitNote") Then
		Return;
	EndIf;
	OperationType = Enums.AdvanceDistributionTypes.BySettlementInvoices;
	GuestGroups.Clear();
	
	// Fill document properties based on invoice ones
	FillPropertyValues(ThisObject, pDebitNote, , "Number, Date, Author, DeletionMark, Posted, Remarks");
	ProformaInvoice = Undefined;
	
	
	// Get document advance balance
	SumAdvance = pmGetCustomerAdvanceBalance();
	
	// Add 1 row for this debit note
	vGuestGroupsRow = GuestGroups.Add();
	vGuestGroupsRow.Invoice = pDebitNote;
	vGuestGroupsRow.Sum = pDebitNote.CorrectionSum;
	vGuestGroupsRow.Balance = 0;
	vGuestGroupsRow.AccountingContract = pDebitNote.AccountingContract;
	vGuestGroupsRow.GuestGroup = pDebitNote.GuestGroup;
EndProcedure // pmFillByDebitNote

// -----------------------------------------------------------------------------
Procedure pmFillByCreditNote(pCreditNote) Export
	If Not ValueIsFilled(pCreditNote) Or ValueIsFilled(pCreditNote) And TypeOf(pCreditNote) = Type("DocumentRef.CreditNote") Then
		Return;
	EndIf;
	OperationType = Enums.AdvanceDistributionTypes.BySettlementInvoices;
	GuestGroups.Clear();
	
	// Fill document properties based on invoice ones
	FillPropertyValues(ThisObject, pCreditNote, , "Number, Date, Author, DeletionMark, Posted, Remarks");
	ProformaInvoice = Undefined;
	
	// Get document advance balance
	SumAdvance = pmGetCustomerAdvanceBalance();
	
	// Add 1 row for this credit note
	vGuestGroupsRow = GuestGroups.Add();
	vGuestGroupsRow.Invoice = pCreditNote;
	vGuestGroupsRow.Sum = -pCreditNote.CorrectionSum;
	vGuestGroupsRow.Balance = 0;
	vGuestGroupsRow.AccountingContract = pCreditNote.AccountingContract;
	vGuestGroupsRow.GuestGroup = pCreditNote.GuestGroup;
EndProcedure // pmFillByCreditNote

// -----------------------------------------------------------------------------
Procedure pmFillByGuestGroup(pGuestGroup) Export
	If Not ValueIsFilled(pGuestGroup) Then
		Return;
	EndIf;
	OperationType = Enums.AdvanceDistributionTypes.ByGroups;
	
	// Fill customer and currency
	AccountingCustomer = pGuestGroup.Customer;
	AccountingContract = Catalogs.Contracts.EmptyRef();
	AccountingCurrency = AccountingCustomer.AccountingCurrency;
	GuestGroup = pGuestGroup;
	
	// Get customer advance balance
	SumAdvance = pmGetCustomerAdvanceBalance();
	
	// Fill guest groups tabular part
	vSumAdvance = SumAdvance;
	
	// Select all customer accounts balances for given group
	vGroups = cmGetCustomerAccountsBalances(?(IsNew(), Undefined, New Boundary(Date, BoundaryType.Excluding)), 
	                                        AccountingCustomer, ?(ValueIsFilled(AccountingContract), AccountingContract, Undefined), GuestGroup, 
	                                        AccountingCurrency, Company, pGuestGroup.Owner, True, True);
	For Each vGroupsRow In vGroups Do
		If vGroupsRow.Balance <> 0 Then
			vGroupRow = GuestGroups.Add();
			pmFillGroupRow(vGroupRow, vGroupsRow.GuestGroup, vGroupsRow.AccountingContract, vSumAdvance, vGroupsRow.Balance);
		EndIf;
	EndDo;
EndProcedure // pmFillByGuestGroup

// -----------------------------------------------------------------------------
Procedure pmFillByPayment(pPayment) Export
	If Not ValueIsFilled(pPayment) Then
		Return;
	EndIf;
	OperationType = Enums.AdvanceDistributionTypes.ByGroups;
	
	// Fill customer and currency
	Hotel = pPayment.Hotel;
	Company = pPayment.Company;
	AccountingCustomer = pPayment.AccountingCustomer;
	AccountingContract = pPayment.AccountingContract;
	AccountingCurrency = pPayment.PaymentCurrency;
	GuestGroup = pPayment.GuestGroup;
	Payment = pPayment;
	
	// Get customer advance balance
	SumAdvance = pPayment.Sum;
	
	// Fill guest groups tabular part
	vSumAdvance = SumAdvance;
	
	// Select all customer accounts balances for given group
	vGroups = cmGetCustomerAccountsBalances(?(IsNew(), Undefined, New Boundary(Date, BoundaryType.Excluding)), 
	                                        AccountingCustomer, ?(ValueIsFilled(AccountingContract), AccountingContract, Undefined), ?(ValueIsFilled(GuestGroup), GuestGroup, Undefined), 
	                                        AccountingCurrency, Company, Hotel, True, True);
	If vGroups.Count() > 0 Then
		For Each vGroupsRow In vGroups Do
			If vGroupsRow.Balance <> 0 Then
				vGroupRow = GuestGroups.Add();
				pmFillGroupRow(vGroupRow, vGroupsRow.GuestGroup, vGroupsRow.AccountingContract, vSumAdvance, vGroupsRow.Balance);
			EndIf;
		EndDo;
	EndIf;
EndProcedure // pmFillByPayment

// -----------------------------------------------------------------------------
Procedure pmFillBalances() Export
	// Get document advance balance
	SumAdvance = pmGetCustomerAdvanceBalance();
	
	// Fill guest groups tabular part
	vSumAdvance = SumAdvance;
	If Not ValueIsFilled(OperationType) Or OperationType = Enums.AdvanceDistributionTypes.ByProformaInvoices Then
		// Select all proforma invoices with balances for given customer, company and hotel
		vInvoices = cmGetInvoicesWithBalances(?(IsNew(), Undefined, New Boundary(Date, BoundaryType.Excluding)), 
		                                      AccountingCustomer, AccountingContract, ?(ValueIsFilled(GuestGroup), GuestGroup, Undefined), 
		                                      AccountingCurrency, Company, ?(ValueIsFilled(Hotel), Hotel, Undefined));
		For Each vInvoicesRow In vInvoices Do
			If vInvoicesRow.Balance <> 0 And ValueIsFilled(vInvoicesRow.Invoice) Then
				vInvoiceRow = GuestGroups.Add();
				pmFillInvoiceRow(vInvoiceRow, vInvoicesRow.Invoice, vSumAdvance, vInvoicesRow.Balance);
			EndIf;
		EndDo;
	ElsIf OperationType = Enums.AdvanceDistributionTypes.BySettlementInvoices Then
		// Select all invoices with balances for given customer, company and hotel
		vInvoices = cmGetSettlementsWithBalances(?(IsNew(), Undefined, New Boundary(Date, BoundaryType.Excluding)), 
		                                         AccountingCustomer, AccountingContract, ?(ValueIsFilled(GuestGroup), GuestGroup, Undefined), 
		                                         AccountingCurrency, Company, ?(ValueIsFilled(Hotel), Hotel, Undefined));
		For Each vInvoicesRow In vInvoices Do
			If vInvoicesRow.Balance <> 0 And ValueIsFilled(vInvoicesRow.Invoice) Then
				vInvoiceRow = GuestGroups.Add();
				pmFillInvoiceRow(vInvoiceRow, vInvoicesRow.Invoice, vSumAdvance, vInvoicesRow.Balance);
			EndIf;
		EndDo;
	Else
		// Select all customer accounts balances for given customer, company and hotel
		vGroups = cmGetCustomerAccountsBalances(?(IsNew(), Undefined, New Boundary(Date, BoundaryType.Excluding)), 
		                                        AccountingCustomer, ?(ValueIsFilled(AccountingContract), AccountingContract, Undefined), ?(ValueIsFilled(GuestGroup), GuestGroup, Undefined), 
		                                        AccountingCurrency, Company, ?(ValueIsFilled(Hotel), Hotel, Undefined), True, True);
		For Each vGroupsRow In vGroups Do
			If vGroupsRow.Balance <> 0 And ValueIsFilled(vGroupsRow.GuestGroup) Then
				vGroupRow = GuestGroups.Add();
				pmFillGroupRow(vGroupRow, vGroupsRow.GuestGroup, vGroupsRow.AccountingContract, vSumAdvance, vGroupsRow.Balance);
			EndIf;
		EndDo;
	EndIf;
EndProcedure // pmFillBalances

// -----------------------------------------------------------------------------
Procedure pmFillByCustomer(pCustomer) Export
	If Not ValueIsFilled(pCustomer) Then
		Return;
	EndIf;
	
	// Fill customer and currency
	AccountingCustomer = pCustomer;
	AccountingContract = Catalogs.Contracts.EmptyRef();
	AccountingCurrency = AccountingCustomer.AccountingCurrency;
	
	// Fill customer group balances
	pmFillBalances();
EndProcedure // pmFillByCustomer

// -----------------------------------------------------------------------------
Procedure pmFillByContract(pContract) Export
	If Not ValueIsFilled(pContract) Then
		Return;
	EndIf;
	
	// Fill customer contract and currency
	AccountingCustomer = pContract.Owner;
	AccountingContract = pContract;
	AccountingCurrency = AccountingContract.AccountingCurrency;
	
	// Fill customer group balances
	pmFillBalances();
EndProcedure // pmFillByContract

#EndRegion

#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure Posting(pCancel, pMode)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// 1. Post to Invoice accounts
	PostToInvoiceAccounts();
	
	// 2. Post to Customer accounts
	PostToCustomerAccounts();
	
	// 3. Post to Customer deposits
	PostToCustomerDeposits();
EndProcedure // Posting

// -----------------------------------------------------------------------------
Procedure Filling(pBase)
	// Fill attributes with default values
	pmFillAttributesWithDefaultValues();
	// Fill from the base
	If ValueIsFilled(pBase) Then
		If TypeOf(pBase) = Type("DocumentRef.ProformaInvoice") Then
			pmFillByProformaInvoice(pBase);
		ElsIf TypeOf(pBase) = Type("DocumentRef.Settlement") Then
			pmFillByInvoice(pBase);
		ElsIf TypeOf(pBase) = Type("DocumentRef.CreditNote") Then
			pmFillByCreditNote(pBase);
		ElsIf TypeOf(pBase) = Type("DocumentRef.DebitNote") Then
			pmFillByDebitNote(pBase);
		ElsIf TypeOf(pBase) = Type("CatalogRef.Customers") Then
			pmFillByCustomer(pBase);
		ElsIf TypeOf(pBase) = Type("CatalogRef.Contracts") Then
			pmFillByContract(pBase);
		ElsIf TypeOf(pBase) = Type("CatalogRef.GuestGroups") Then
			pmFillByGuestGroup(pBase);
		ElsIf TypeOf(pBase) = Type("DocumentRef.Payment") Or TypeOf(pBase) = Type("DocumentRef.CustomerPayment") Then
			pmFillByPayment(pBase);
		EndIf;
		SetNewNumber();
	EndIf;
EndProcedure // Filling

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel, pWriteMode, pPostingMode)
	Var vMessage, vAttributeInErr;
	If DataExchange.Load Then
		Return;
	EndIf;
	If pWriteMode = DocumentWriteMode.Posting Then
		pCancel	= pmCheckDocumentAttributes(vMessage, vAttributeInErr);
		If pCancel Then
			WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
			tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage), MessageStatus.Attention);
			Raise NStr(vMessage);
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

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

#Region Private

// -----------------------------------------------------------------------------
Procedure PostToInvoiceAccounts()
	For Each vRow In GuestGroups Do
		If Not ValueIsFilled(vRow.Invoice) Then
			Continue;
		ElsIf vRow.Sum = 0 Then
			Continue;
		EndIf;
		
		Movement = RegisterRecords.InvoiceAccounts.Add();
		
		Movement.RecordType = AccumulationRecordType.Expense;
		Movement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
		
		FillPropertyValues(Movement, ThisObject);
		FillPropertyValues(Movement, vRow.Invoice);
		FillPropertyValues(Movement, vRow);
		
		// Attributes
		Movement.AccountingDate = ?(ValueIsFilled(AccountingDate), AccountingDate, BegOfDay(Date));
	EndDo;

	RegisterRecords.InvoiceAccounts.Write();
EndProcedure // PostToInvoiceAccounts

// -----------------------------------------------------------------------------
Procedure PostToCustomerAccounts() 
	RegisterRecords.CustomerAccounts.Clear();
	
	If Not ValueIsFilled(ProformaInvoice) Then
		For Each vRow In GuestGroups Do
			If Not ValueIsFilled(vRow.Invoice) And Not ValueIsFilled(vRow.GuestGroup) Then
				Continue;
			ElsIf vRow.Sum = 0 Then
				Continue;
			EndIf;
			
			// Add movement to write off sum from customer advance
			Movement = RegisterRecords.CustomerAccounts.Add();
			Movement.RecordType = AccumulationRecordType.Expense;
			Movement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
			// Dimensions
			FillPropertyValues(Movement, ThisObject);
			If ValueIsFilled(vRow.Invoice) Then
				FillPropertyValues(Movement, vRow.Invoice);
			Else
				FillPropertyValues(Movement, vRow);
			EndIf;
			Movement.AccountingContract = AccountingContract;
			Movement.GuestGroup = Catalogs.GuestGroups.EmptyRef();
			Movement.Hotel = Hotel;
			// Resources
			Movement.Sum = -vRow.Sum;
			// Attributes
			Movement.AccountingDate = ?(ValueIsFilled(AccountingDate), AccountingDate, BegOfDay(Date));
			
			// Add movement to move sum to the guest group
			Movement = RegisterRecords.CustomerAccounts.Add();
			Movement.RecordType = AccumulationRecordType.Expense;
			Movement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
			// Dimensions
			FillPropertyValues(Movement, ThisObject);
			If ValueIsFilled(vRow.Invoice) Then
				FillPropertyValues(Movement, vRow.Invoice);
				If ValueIsFilled(vRow.AccountingContract) Then
					Movement.AccountingContract = vRow.AccountingContract;
				EndIf;
				If ValueIsFilled(vRow.GuestGroup) Then
					Movement.GuestGroup = vRow.GuestGroup;
				EndIf;
			Else
				FillPropertyValues(Movement, vRow);
				If ValueIsFilled(vRow.GuestGroup) Then
					Movement.Hotel = vRow.GuestGroup.Owner;
				EndIf;
			EndIf;
			// Resources
			Movement.Sum = vRow.Sum;
			// Attributes
			Movement.AccountingDate = ?(ValueIsFilled(AccountingDate), AccountingDate, BegOfDay(Date));
		EndDo;
	EndIf;

	RegisterRecords.CustomerAccounts.Write();
EndProcedure // PostToCustomerAccounts

// -----------------------------------------------------------------------------
Procedure PostToCustomerDeposits() 
	RegisterRecords.CustomerDeposits.Clear();
	
	If ValueIsFilled(ProformaInvoice) Then
		For Each vRow In GuestGroups Do
			If Not ValueIsFilled(vRow.Invoice) Then
				Continue;
			ElsIf TypeOf(vRow.Invoice) <> Type("DocumentRef.Settlement") Then
				Continue;
			ElsIf vRow.Sum = 0 Then
				Continue;
			EndIf;
			
			// Add movement to write off sum from customer advance
			Movement = RegisterRecords.CustomerDeposits.Add();
			Movement.RecordType = AccumulationRecordType.Expense;
			Movement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
			
			// Dimensions
			Movement.ProformaInvoice = ProformaInvoice;
			Movement.AccountingCurrency = AccountingCurrency;
			Movement.Hotel = Hotel;
			
			// Resources
			Movement.Sum = vRow.Sum;
		EndDo;
	EndIf;
	
	RegisterRecords.CustomerDeposits.Write();
EndProcedure // PostToCustomerDeposits

#EndRegion
