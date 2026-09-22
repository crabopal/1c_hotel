// -----------------------------------------------------------------------------
// Data processors framework start
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

// -----------------------------------------------------------------------------
// Initialize attributes with default values
// Attention: This procedure could be called AFTER some attributes initialization
// routine, so it SHOULD NOT reset attributes being set before
// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If Not ValueIsFilled(AccountingDate) Then
		AccountingDate = BegOfDay(CurrentSessionDate());
		If ValueIsFilled(Hotel) And ValueIsFilled(Hotel.AccountingDate) Then
			AccountingDate = Hotel.AccountingDate;
		EndIf;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	// Create proforma invoices based on groups
	pmDoProcess(pIsInteractive);
EndProcedure // pmRun

// -----------------------------------------------------------------------------
// Data processors framework end
// -----------------------------------------------------------------------------
	
// -----------------------------------------------------------------------------
Function pmDoProcess(pIsInteractive = False, rInvoicesList = Undefined, rPrintFormType = "") Export
	vMessageText = "";

	WriteLogEvent(NStr("en='DataProcessor.CreateCityLedgerPayments';ru='Обработка.СозданиеПлатежейСоСпособомОплатыАкт';de='DataProcessor.CreateCityLedgerPayments'"), EventLogLevel.Information, Undefined, Undefined, NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'"));
	
	// Get list of companies to close day for
	vCompanies = GetHotelCompanies();
	
	// Do for each company with appropriate flag ON
	Try
		// Some checks
		If Not ValueIsFilled(AccountingDate) Then
			vMessageText = NStr("en='Date is empty!'; ru='Не указана дата!'; de='Das Datum ist nicht angegeben!'");
			Raise vMessageText;
		EndIf;
		
		// Define invoice print form type
		rPrintFormType = "";
		If ValueIsFilled(InvoicePrintForm) Then
			If InvoicePrintForm = Catalogs.ObjectPrintingForms.SettlementPrintInvoiceRu Or
			   InvoicePrintForm = Catalogs.ObjectPrintingForms.SettlementPrintInvoiceEn Or
			   InvoicePrintForm = Catalogs.ObjectPrintingForms.SettlementPrintInvoiceDe Then
				rPrintFormType = "Invoice";
			ElsIf InvoicePrintForm = Catalogs.ObjectPrintingForms.SettlementPrint7GRu Or 
			      InvoicePrintForm = Catalogs.ObjectPrintingForms.SettlementPrint7GEn Then
				rPrintFormType = "Settlement7G";
			ElsIf InvoicePrintForm = Catalogs.ObjectPrintingForms.SettlementPrintHotelProducts Then
				rPrintFormType = "SettlementHotelProducts";
			ElsIf InvoicePrintForm = Catalogs.ObjectPrintingForms.SettlementPrintVATInvoice Or 
			      InvoicePrintForm = Catalogs.ObjectPrintingForms.SettlementPrintVATInvoiceGroupAll Or 
			      InvoicePrintForm = Catalogs.ObjectPrintingForms.SettlementPrintVATInvoiceGroupAllPerDay Or 
			      InvoicePrintForm = Catalogs.ObjectPrintingForms.SettlementPrintVATInvoiceGroupAllPerFolio Or 
			      InvoicePrintForm = Catalogs.ObjectPrintingForms.SettlementPrintVATInvoiceGroupAllPerFolioPerDay Or 
			      InvoicePrintForm = Catalogs.ObjectPrintingForms.SettlementPrintVATInvoiceGroupByService Or 
			      InvoicePrintForm = Catalogs.ObjectPrintingForms.SettlementPrintVATInvoiceGroupInPrice Or 
			      InvoicePrintForm = Catalogs.ObjectPrintingForms.SettlementPrintVATInvoiceGroupInPricePerDay Or 
			      InvoicePrintForm = Catalogs.ObjectPrintingForms.SettlementPrintVATInvoiceGroupInPricePerFolio Or 
			      InvoicePrintForm = Catalogs.ObjectPrintingForms.SettlementPrintVATInvoiceGroupInPricePerFolioPerDay Or 
			      InvoicePrintForm = Catalogs.ObjectPrintingForms.SettlementPrintVATInvoiceGroupPerFolio Then
				rPrintFormType = "VATInvoice";
			Else
				rPrintFormType = "Settlement";
			EndIf;
		EndIf;
		
		// Do processing
		BeginTransaction(DataLockControlMode.Managed);
		For Each vCompaniesRow In vCompanies Do
			If vCompaniesRow.CloseCityLedgerByPayments Then
				GenerateCityLedgerPaymentsForCompany(vCompaniesRow.Company, rInvoicesList);
			EndIf;
		EndDo;
		CommitTransaction();
	Except
		vErrorInfo = ErrorInfo();
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		// Log error
		vErrorDescription = cmGetRootErrorDescription(vErrorInfo);
		WriteLogEvent(NStr("en='City ledger payments generation'; ru='Создание платежей на City Ledger'; de='City-Ledger-Zahlungen generieren'"), 
		              EventLogLevel.Error, , Hotel, 
					  NStr("en='Company: '; ru='Фирма: '; de='Kompanie: '") + ?(vCompaniesRow = Undefined, "N/A", TrimAll(vCompaniesRow.Company)) + ", " + 
					  Format(AccountingDate, "DF=dd.MM.yyyy") + ", " + 
					  NStr("en='Error: '; ru='Ошибка: '; de='Fehler: '") + vErrorDescription);
		// Show message
		vMessageText = NStr("en='An error occured while generating payments!'; 
		                    |ru='При создании платежей произошла ошибка!'; 
						    |de='Beim Erstellen von Zahlungen ist ein Fehler aufgetreten!'") + Chars.LF + 
		               vErrorDescription + Chars.LF + 
				       NStr("en='Please wait a few minutes and try again. If the error persists, contact technical support.'; 
				            |ru='Пожалуйста подождите несколько минут и попробуйте еще раз. Если ошибка повторится, обращайтесь в службу технической поддержки.'; 
					        |de='Bitte warten Sie einige Minuten und versuchen Sie es erneut. Wenn der Fehler weiterhin besteht, wenden Sie sich an den technischen Support.'");
	EndTry;
	
	WriteLogEvent(NStr("en='DataProcessor.CreateCityLedgerPayments';ru='Обработка.СозданиеПлатежейСоСпособомОплатыАкт';de='DataProcessor.CreateCityLedgerPayments'"), EventLogLevel.Information, Undefined, Undefined, NStr("en='Completed'; ru='Выполнено'; de='Vollendet'"));
	
	Return vMessageText;
EndFunction // pmDoProcess

// -----------------------------------------------------------------------------
Function GetHotelCompanies()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CurrentAccountsReceivableBalance.Company AS Company,
	|	CurrentAccountsReceivableBalance.Company.CloseCityLedgerByPayments AS CloseCityLedgerByPayments,
	|	CurrentAccountsReceivableBalance.SumBalance AS SumBalance,
	|	CurrentAccountsReceivableBalance.QuantityBalance AS QuantityBalance,
	|	CurrentAccountsReceivableBalance.CommissionSumBalance AS CommissionSumBalance
	|FROM
	|	AccumulationRegister.CurrentAccountsReceivable.Balance(
	|			,
	|			(&qHotelIsEmpty
	|				OR NOT &qHotelIsEmpty
	|					AND Hotel IN HIERARCHY (&qHotel))
	|				AND NOT Company.DeletionMark
	|				AND Company.CloseCityLedgerByPayments) AS CurrentAccountsReceivableBalance
	|
	|ORDER BY
	|	CurrentAccountsReceivableBalance.Company.SortCode,
	|	CurrentAccountsReceivableBalance.Company.Description";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vCompanies = vQry.Execute().Unload();
	If ValueIsFilled(Hotel) And ValueIsFilled(Hotel.Company) Then
		If vCompanies.Find(Hotel.Company, "Company") = Undefined Then
			vCompaniesRow = vCompanies.Add();
			vCompaniesRow.Company = Hotel.Company;
			vCompaniesRow.CloseCityLedgerByPayments = Hotel.Company.CloseCityLedgerByPayments;
		EndIf;
	EndIf;
	Return vCompanies;
EndFunction // GetHotelCompanies

// -----------------------------------------------------------------------------
Function CityLedgerPaymentIsAvailable(pFolioRef)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	COUNT(Payments.Ref) AS DocsCount
	|FROM
	|	Document.Payment AS Payments
	|WHERE
	|	Payments.Folio = &qFolio
	|	AND Payments.PaymentMethod = &qPaymentMethod
	|	AND BEGINOFPERIOD(Payments.Date, DAY) = &qAccountingDate
	|	AND Payments.Posted";
	vQry.SetParameter("qFolio", pFolioRef);
	vQry.SetParameter("qPaymentMethod", Catalogs.PaymentMethods.Settlement);
	vQry.SetParameter("qAccountingDate", AccountingDate);
	vDocsCount = vQry.Execute().Unload();
	If vDocsCount.Count() > 0 Then
		vCount = vDocsCount.Get(0).DocsCount;
		If vCount = Null Then
			Return False;
		Else
			If vCount > 0 Then
				Return True;
			Else
				Return False;
			EndIf;
		EndIf;
	Else
		Return False;
	EndIf;
EndFunction // CityLedgerPaymentIsAvailable

// -----------------------------------------------------------------------------
Function InvoiceIsAvailable(pFolioRef, pFolioDescription = "")
	vQry = New Query();
	If CreateOneInvoicePerGuestGroup And ValueIsFilled(pFolioRef.GuestGroup) Then
		vQry.Text = 
		"SELECT
		|	COUNT(Invoices.Ref) AS DocsCount
		|FROM
		|	Document.Settlement AS Invoices
		|WHERE
		|	Invoices.AccountingCustomer = &qCustomer
		|	AND Invoices.AccountingContract = &qContract
		|	AND Invoices.GuestGroup = &qGuestGroup
		|	AND Invoices.FolioDescription = &qFolioDescription
		|	AND BEGINOFPERIOD(Invoices.Date, DAY) = &qAccountingDate
		|	AND Invoices.Posted";
		vQry.SetParameter("qCustomer", ?(ValueIsFilled(pFolioRef.Customer), pFolioRef.Customer, pFolioRef.GuestGroup.Owner.IndividualsCustomer));
		vQry.SetParameter("qContract", ?(ValueIsFilled(pFolioRef.Contract), pFolioRef.Contract, pFolioRef.GuestGroup.Owner.IndividualsContract));
		vQry.SetParameter("qGuestGroup", pFolioRef.GuestGroup);
		vQry.SetParameter("qFolioDescription", pFolioDescription);
		vQry.SetParameter("qAccountingDate", AccountingDate);
	Else
		vQry.Text = 
		"SELECT
		|	COUNT(Invoices.Ref) AS DocsCount
		|FROM
		|	Document.Settlement AS Invoices
		|WHERE
		|	Invoices.AccountingCustomer = &qCustomer
		|	AND Invoices.AccountingContract = &qContract
		|	AND Invoices.ParentDoc = &qFolio
		|	AND Invoices.FolioDescription = &qFolioDescription
		|	AND BEGINOFPERIOD(Invoices.Date, DAY) = &qAccountingDate
		|	AND Invoices.Posted";
		vQry.SetParameter("qCustomer", ?(ValueIsFilled(pFolioRef.Customer), pFolioRef.Customer, ?(ValueIsFilled(pFolioRef.Hotel), pFolioRef.Hotel.IndividualsCustomer, pFolioRef.Customer)));
		vQry.SetParameter("qContract", ?(ValueIsFilled(pFolioRef.Contract), pFolioRef.Contract, ?(ValueIsFilled(pFolioRef.Hotel), pFolioRef.Hotel.IndividualsContract, pFolioRef.Contract)));
		vQry.SetParameter("qFolio", pFolioRef);
		vQry.SetParameter("qFolioDescription", pFolioDescription);
		vQry.SetParameter("qAccountingDate", AccountingDate);
	EndIf;
	vDocsCount = vQry.Execute().Unload();
	If vDocsCount.Count() > 0 Then
		vCount = vDocsCount.Get(0).DocsCount;
		If vCount = Null Then
			Return False;
		Else
			If vCount > 0 Then
				Return True;
			Else
				Return False;
			EndIf;
		EndIf;
	Else
		Return False;
	EndIf;
EndFunction // InvoiceIsAvailable

// -----------------------------------------------------------------------------
Procedure GenerateCityLedgerPaymentsForCompany(pCompany, pInvoicesList = Undefined)
	// Date to be used to retreive balances
	vDate = EndOfDay(AccountingDate) + 1;
	vCustomer = ?(ValueIsFilled(Customer), Customer, pCompany.CloseCityLedgerByPaymentsForCustomers);
	
	If ValueIsFilled(pCompany) And pCompany.SettlementsDoNotChangeFolioBalances Then
		// Get table with customers, contracts and guest groups with balances in Accounts
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	AccountsBalance.Hotel AS Hotel,
		|	AccountsBalance.Folio AS Folio,
		|	AccountsBalance.Folio.Number AS FolioNumber,
		|	ISNULL(AccountsBalance.Folio.Customer.Description, """") AS CustomerDescription,
		|	ISNULL(AccountsBalance.Folio.Contract.Description, """") AS ContractDescription,
		|	SUM(AccountsBalance.SumBalance) AS Amount
		|FROM
		|	AccumulationRegister.Accounts.Balance(
		|			&qDate,
		|			(&qHotelIsEmpty
		|				OR NOT &qHotelIsEmpty
		|					AND Hotel IN HIERARCHY (&qHotel))
		|				AND Folio.Company = &qCompany
		|				AND (&qCustomerIsEmpty
		|					OR NOT &qCustomerIsEmpty
		|						AND Folio.Customer IN HIERARCHY (&qCustomer))
		|				AND Folio.DateTimeTo <= &qPeriodTo
		|				AND Folio.DateTimeTo >= &qPeriodFrom
		|				AND NOT ISNULL(Folio.Customer.IsIndividual, TRUE)
		|				AND (Folio.PaymentMethod = VALUE(Catalog.PaymentMethods.Settlement)
		|					OR ISNULL(Folio.PaymentMethod.IsByBankTransfer, FALSE))) AS AccountsBalance
		|
		|GROUP BY
		|	AccountsBalance.Hotel,
		|	AccountsBalance.Folio,
		|	AccountsBalance.Folio.Number,
		|	ISNULL(AccountsBalance.Folio.Customer.Description, """"),
		|	ISNULL(AccountsBalance.Folio.Contract.Description, """")
		|
		|HAVING
		|	SUM(AccountsBalance.SumBalance) <> 0
		|
		|ORDER BY
		|	CustomerDescription,
		|	ContractDescription,
		|	FolioNumber";
	Else
		// Get table with customers, contracts and guest groups with balances in Current Accounts Receivable
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	CurrentAccountsReceivableBalance.Hotel AS Hotel,
		|	CurrentAccountsReceivableBalance.Charge.Folio AS Folio,
		|	CurrentAccountsReceivableBalance.Charge.Folio.Number AS FolioNumber,
		|	CurrentAccountsReceivableBalance.Customer.Description AS CustomerDescription,
		|	CurrentAccountsReceivableBalance.Contract.Description AS ContractDescription,
		|	SUM(CurrentAccountsReceivableBalance.SumBalance) AS Amount
		|FROM
		|	AccumulationRegister.CurrentAccountsReceivable.Balance(
		|			&qDate,
		|			(&qHotelIsEmpty
		|				OR NOT &qHotelIsEmpty
		|					AND Hotel IN HIERARCHY (&qHotel))
		|				AND Company = &qCompany
		|				AND (&qCustomerIsEmpty
		|					OR NOT &qCustomerIsEmpty
		|						AND Customer IN HIERARCHY (&qCustomer))
		|				AND Charge.Folio.DateTimeTo <= &qPeriodTo
		|				AND Charge.Folio.DateTimeTo >= &qPeriodFrom
		|				AND NOT ISNULL(Customer.IsIndividual, TRUE)
		|				AND (Charge.Folio.PaymentMethod = VALUE(Catalog.PaymentMethods.Settlement)
		|					OR ISNULL(Charge.Folio.PaymentMethod.IsByBankTransfer, FALSE))) AS CurrentAccountsReceivableBalance
		|
		|GROUP BY
		|	CurrentAccountsReceivableBalance.Hotel,
		|	CurrentAccountsReceivableBalance.Charge.Folio,
		|	CurrentAccountsReceivableBalance.Charge.Folio.Number,
		|	CurrentAccountsReceivableBalance.Customer.Description,
		|	CurrentAccountsReceivableBalance.Contract.Description
		|
		|HAVING
		|	SUM(CurrentAccountsReceivableBalance.SumBalance) <> 0
		|
		|ORDER BY
		|	CustomerDescription,
		|	ContractDescription,
		|	FolioNumber";
	EndIf;
	vQry.SetParameter("qDate", New Boundary(vDate, BoundaryType.Excluding));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", pCompany);
	vQry.SetParameter("qCustomer", vCustomer);
	vQry.SetParameter("qCustomerIsEmpty", Not ValueIsFilled(vCustomer));
	vQry.SetParameter("qEmptyGuestGroup", Catalogs.GuestGroups.EmptyRef());
	vQry.SetParameter("qPeriodFrom", BegOfDay(AccountingDate));
	vQry.SetParameter("qPeriodTo", EndOfDay(AccountingDate));
	vDimensions = vQry.Execute().Unload();
	
	// Create payment for each row in dimensions table
	For Each vDimensionsRow In vDimensions Do
		// Check that there are charges in the folio with balance
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	Charges.Hotel AS Hotel,
		|	Charges.Folio AS Folio,
		|	SUM(Charges.Sum) AS Amount
		|FROM
		|	Document.Charge AS Charges
		|		LEFT JOIN Document.Storno AS Stornos
		|		ON Charges.Ref = Stornos.ParentCharge
		|			AND (Stornos.Posted)
		|WHERE
		|	Charges.Hotel = &qHotel
		|	AND Charges.Folio = &qFolio
		|	AND Charges.Posted
		|	AND Stornos.Ref IS NULL
		|
		|GROUP BY
		|	Charges.Hotel,
		|	Charges.Folio
		|
		|HAVING
		|	SUM(Charges.Sum) <> 0";
		vQry.SetParameter("qHotel", vDimensionsRow.Hotel);
		vQry.SetParameter("qFolio", vDimensionsRow.Folio);
		vCharges = vQry.Execute().Unload();
		If vCharges.Count() > 0 Then
			// Create payment and invoice 
			vDocsStruct = CreateAndPostPayment(vDimensionsRow);
			// Print invoice if was created
			If ValueIsFilled(vDocsStruct.Invoice) And pInvoicesList <> Undefined Then
				If pInvoicesList.FindByValue(vDocsStruct.Invoice) = Undefined Then
					pInvoicesList.Add(vDocsStruct.Invoice);
				EndIf;
			EndIf;
			If ValueIsFilled(vDocsStruct.Invoice2) And pInvoicesList <> Undefined Then
				If pInvoicesList.FindByValue(vDocsStruct.Invoice2) = Undefined Then
					pInvoicesList.Add(vDocsStruct.Invoice2);
				EndIf;
			EndIf;
		EndIf;
	EndDo;
EndProcedure // GenerateCityLedgerPaymentsForCompany

// -----------------------------------------------------------------------------
Function CreateAndPostPayment(pDimensionsRow)
	vStruct = New Structure("Payment, Invoice, Invoice2", Undefined, Undefined, Undefined);
	vFolio = pDimensionsRow.Folio;
	If ValueIsFilled(vFolio.Customer) And Not vFolio.Customer.IsIndividual Then
		// Check if there is already payment to city ledger. If yes skip this folio
		If Not CityLedgerPaymentIsAvailable(vFolio) Then
			// Create payment
			vPaymentObj = Documents.Payment.CreateDocument();
			vPaymentObj.pmFillAttributesWithDefaultValues();
			vPaymentObj.Fill(vFolio);
			vPaymentObj.CashRegister = Catalogs.CashRegisters.EmptyRef();
			vPaymentObj.PaymentMethod = Catalogs.PaymentMethods.Settlement;
			If vPaymentObj.Sum > 0 Then
				vPaymentObj.Write(DocumentWriteMode.Posting);
				vStruct.Payment = vPaymentObj.Ref;
			EndIf;
		EndIf;
		// Create invoice if neccessary
		If CreateInvoices Then
			If Not IsBlankString(FolioDescription) Then
				If Not InvoiceIsAvailable(vFolio, FolioDescription) Then
					vInvObj = Undefined;
					If CreateOneInvoicePerGuestGroup And ValueIsFilled(vFolio.GuestGroup) Then
						vInvObj = Documents.Settlement.CreateDocument();
						vInvObj.Hotel = vFolio.Company;
						vInvObj.Company = vFolio.Company;
						vInvObj.AccountingCustomer = vFolio.Customer;
						vInvObj.AccountingContract = vFolio.Contract;
						vInvObj.FolioDescription = FolioDescription;
						vInvObj.Fill(vFolio.GuestGroup);
					ElsIf lower(TrimAll(vFolio.Description)) = lower(TrimAll(FolioDescription)) Then
						vInvObj = Documents.Settlement.CreateDocument();
						vInvObj.FolioDescription = FolioDescription;
						vInvObj.Fill(vFolio);
					EndIf;
					If vInvObj <> Undefined Then
						vInvObj.Date = EndOfDay(AccountingDate);
						vInvObj.SetTime(AutoTimeMode.DontUse);
						vInvObj.ChangeDate = CurrentSessionDate();
						vInvObj.ChangeAuthor = SessionParameters.CurrentUser;
						If vInvObj.Services.Count() > 0 Then
							vInvObj.Write(DocumentWriteMode.Write);
							If vInvObj.Date <> EndOfDay(AccountingDate) Then
								vInvObj.Date = EndOfDay(AccountingDate);
								vInvObj.Write(DocumentWriteMode.Write);
							EndIf;
							vInvObj.Write(DocumentWriteMode.Posting);
							vStruct.Invoice2 = vInvObj.Ref;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			If Not InvoiceIsAvailable(vFolio, "") Then
				vInvObj = Undefined;
				If CreateOneInvoicePerGuestGroup And ValueIsFilled(vFolio.GuestGroup) Then
					vInvObj = Documents.Settlement.CreateDocument();
					vInvObj.Hotel = vFolio.Company;
					vInvObj.Company = vFolio.Company;
					vInvObj.AccountingCustomer = vFolio.Customer;
					vInvObj.AccountingContract = vFolio.Contract;
					vInvObj.FolioDescription = "";
					vInvObj.Fill(vFolio.GuestGroup);
				ElsIf IsBlankString(FolioDescription) Or 
				      Not IsBlankString(FolioDescription) And lower(TrimAll(vFolio.Description)) <> lower(TrimAll(FolioDescription)) Then
					vInvObj = Documents.Settlement.CreateDocument();
					vInvObj.FolioDescription = "";
					vInvObj.Fill(vFolio);
				EndIf;
				If vInvObj <> Undefined Then
					vInvObj.Date = EndOfDay(AccountingDate);
					vInvObj.SetTime(AutoTimeMode.DontUse);
					vInvObj.ChangeDate = CurrentSessionDate();
					vInvObj.ChangeAuthor = SessionParameters.CurrentUser;
					If vInvObj.Services.Count() > 0 Then
						vInvObj.Write(DocumentWriteMode.Write);
						If vInvObj.Date <> EndOfDay(AccountingDate) Then
							vInvObj.Date = EndOfDay(AccountingDate);
							vInvObj.Write(DocumentWriteMode.Write);
						EndIf;
						vInvObj.Write(DocumentWriteMode.Posting);
						vStruct.Invoice = vInvObj.Ref;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	Return vStruct;
EndFunction // CreateAndPostPayment
