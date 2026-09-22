// -----------------------------------------------------------------------------
// Reports framework start
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Procedure pmSaveReportAttributes(pGenerateOnly = False) Export
	cmSaveReportAttributes(ThisObject, , pGenerateOnly);
EndProcedure // pmSaveReportAttributes

// -----------------------------------------------------------------------------
Procedure pmLoadReportAttributes(pParameter = Undefined) Export
	cmLoadReportAttributes(ThisObject, pParameter);
EndProcedure // pmLoadReportAttributes

// -----------------------------------------------------------------------------
// Initialize attributes with default values
// Attention: This procedure could be called AFTER some attributes initialization
// routine, so it SHOULD NOT reset attributes being set before
// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// Fill parameters with default values
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
		If Not ValueIsFilled(PeriodFrom) Then
			PeriodFrom = BegOfMonth(CurrentSessionDate()); // For beg. of month
			PeriodTo = EndOfDay(CurrentSessionDate());
		EndIf;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetReportParametersPresentation() Export
	vParamPresentation = "";
	If Not ValueIsFilled(PeriodFrom) And Not ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("en='Report period is not set';ru='Период отчета не установлен';de='Berichtszeitraum nicht festgelegt'") + 
		                     ";" + Chars.LF;
	ElsIf ValueIsFilled(PeriodFrom) And Not ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период c '; en = 'Period from '; de = 'Periode von '") + 
		                     Format(PeriodFrom, "DF='dd.MM.yyyy HH:mm'") + 
		                     ";" + Chars.LF;
	ElsIf Not ValueIsFilled(PeriodFrom) And ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период по '; en = 'Period to '; de = 'Periode zu '") + 
		                     Format(PeriodTo, "DF='dd.MM.yyyy HH:mm'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom = PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период на '; en = 'Period on '; de = 'Periode '") + 
		                     Format(PeriodFrom, "DF='dd.MM.yyyy HH:mm'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom < PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период '; en = 'Period '; de = 'Periode '") + PeriodPresentation(PeriodFrom, PeriodTo, cmLocalizationCode()) + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("en='Period is wrong!';ru='Неправильно задан период!';de='Der Zeitraum wurde falsch eingetragen!'") + 
		                     ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(Customer) Then
		If Not Customer.IsFolder Then
			vLanguage = Customer.Language;
			If Not ValueIsFilled(vLanguage) Then
				vLanguage = SessionParameters.CurrentLanguage;
			EndIf;
			vCustomerLegacyName = TrimAll(Customer.LegacyName);
			If IsBlankString(vCustomerLegacyName) Then
				vCustomerLegacyName = TrimAll(Customer.Description);
			EndIf;
			vCustomerLegacyAddress = cmGetAddressPresentation(Customer.LegacyAddress);
			vCustomerPostAddress = cmGetAddressPresentation(Customer.PostAddress);
			If lower(vCustomerPostAddress) = lower(vCustomerLegacyAddress) Then
				vCustomerPostAddress = "";
			EndIf;
			vCustomerTIN = TrimAll(Customer.TIN);
			vCustomerKPP = TrimAll(Customer.KPP);
			vCustomerVATC = TrimAll(Customer.VATC);
			vCustomerCodes = "";
			If Not IsBlankString(vCustomerTIN) Then
				vCustomerCodes = cmNStr("en='Reg. N';de='Reg. N';ru='ИНН'", vLanguage) + ?(IsBlankString(vCustomerKPP), " ", "/" + cmNStr("en='KPP ';de='KPP ';ru='КПП '", vLanguage)) + vCustomerTIN + ?(IsBlankString(vCustomerKPP), "", "/" + vCustomerKPP);
			EndIf;
			If Not IsBlankString(vCustomerVATC) Then
				vCustomerCodes = vCustomerCodes + ?(IsBlankString(vCustomerCodes), "", ", ") + cmNStr("EN='VAT Code ';RU='код НДС ';de='Mw.St. Code '", vLanguage) + vCustomerVATC;
			EndIf;
			// Fax and E-Mail
			vCustomerPhones = TrimAll(Customer.Phone);
			vCustomerFax = TrimAll(Customer.Fax);
			vCustomerEMail = TrimAll(Customer.EMail);
			vCustomerPhones = vCustomerPhones + 
			                  ?(IsBlankString(vCustomerFax), "", ?(IsBlankString(vCustomerPhones), "", ", ") + cmNStr("en='fax ';de='fax ';ru='факс '", vLanguage) + vCustomerFax);
			vCustomerPhones = vCustomerPhones + 
							  ?(IsBlankString(vCustomerEMail), "", ?(IsBlankString(vCustomerPhones), "", ", ") + cmNStr("en='e-mail ';de='e-mail ';ru='e-mail '", vLanguage) + vCustomerEMail);
			// Name
			vCustomerLegacyName = vCustomerLegacyName + ?(IsBlankString(vCustomerCodes), "", ", " + vCustomerCodes) + Chars.LF + 
			                      ?(IsBlankString(vCustomerLegacyAddress), "", vCustomerLegacyAddress + Chars.LF) + 
								  ?(IsBlankString(vCustomerPostAddress), "", vCustomerPostAddress + Chars.LF) + 
								  ?(IsBlankString(vCustomerPhones), "", vCustomerPhones);
			vCustomerLegacyName = TrimAll(vCustomerLegacyName);

			vParamPresentation = vParamPresentation + NStr("de='Firma ';en='Customer ';ru='Контрагент '") + 
				                     vCustomerLegacyName + 
				                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("de='Gruppe Firmen ';en='Customers folder ';ru='Группа контрагентов '") + 
			                     TrimAll(Customer.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(Contract) Then
		vParamPresentation = vParamPresentation + NStr("en='Contract ';ru='Договор ';de='Vertrag '") + 
							 TrimAll(Contract.Description) + 
							 ";" + Chars.LF;
	EndIf;							 
	If ValueIsFilled(GuestGroup) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Группа гостей '; en = 'Guest group '; de = 'Gastgruppe '") + 
							 TrimAll(TrimAll(GuestGroup.Code) + " " + TrimAll(GuestGroup.Description)) + 
							 ";" + Chars.LF;
	EndIf;							 
	If ValueIsFilled(Currency) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Валюта '; en = 'Currency '; de = 'Währung '") + 
							 TrimAll(Currency.Description) + 
							 ";" + Chars.LF;
	EndIf;
	If TypeOfInvoicesToShow = 0 Then
		vParamPresentation = vParamPresentation + NStr("en='Show proforma invoices';ru='Отбор счетов на оплату';de='Proforma-Rechnungen zu zeigen'") + 
							 ";" + Chars.LF;
	ElsIf TypeOfInvoicesToShow = 1 Then
		vParamPresentation = vParamPresentation + NStr("en='Show invoices';ru='Отбор актов';de='Rechnungen zu zeigen'") + 
							 ";" + Chars.LF;
	EndIf;
	If ShowExpiredInvoicesOnly Then
		vParamPresentation = vParamPresentation + NStr("en='Show expired invoices only';ru='Только счета/акты с просроченной оплатой';de='Nur Rechnungen mit versäumter Zahlung'") + 
							 ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(Company) Then
		If Not Company.IsFolder Then
			vLanguage = Undefined;
			If ValueIsFilled(Customer) Then
				If Not Customer.IsFolder Then
					vLanguage = Customer.Language;
				EndIf;
			EndIf;
			If Not ValueIsFilled(vLanguage) Then
				vLanguage = SessionParameters.CurrentLanguage;
			EndIf;
			vCompanyObj = Company.GetObject();
			vCompanyLegacyName = vCompanyObj.pmGetCompanyPrintName(vLanguage);
			vCompanyLegacyAddress = vCompanyObj.pmGetCompanyLegacyAddressPresentation(vLanguage);
			vCompanyPostAddress = vCompanyObj.pmGetCompanyPostAddressPresentation(vLanguage);
			If lower(vCompanyPostAddress) = lower(vCompanyLegacyAddress) Then
				vCompanyPostAddress = "";
			EndIf;
			vCompanyTIN = TrimAll(vCompanyObj.TIN);
			vCompanyKPP = TrimAll(vCompanyObj.KPP);
			vCompanyVATC = TrimAll(vCompanyObj.VATC);
			vCompanyCodes = "";
			If Not IsBlankString(vCompanyTIN) Then
				vCompanyCodes = cmNStr("en='Reg. N';de='Reg. N';ru='ИНН'", vLanguage) + ?(IsBlankString(vCompanyKPP), " ", "/" + cmNStr("en='KPP ';de='KPP ';ru='КПП '", vLanguage)) + vCompanyTIN + ?(IsBlankString(vCompanyKPP), "", "/" + vCompanyKPP);
			EndIf;
			If Not IsBlankString(vCompanyVATC) Then
				vCompanyCodes = vCompanyCodes + ?(IsBlankString(vCompanyCodes), "", ", ") + cmNStr("en='VAT Code ';ru='код НДС ';de='Mw.St. Code ';lv='PVN '", vLanguage) + vCompanyVATC;
			EndIf;
			vCompanyPhones = TrimAll(vCompanyObj.Phones);
			vCompanyPhones = vCompanyPhones + 
			                 ?(IsBlankString(vCompanyObj.Fax), "", ?(IsBlankString(vCompanyPhones), "", ", ") + cmNStr("en='fax ';de='fax ';ru='факс '", vLanguage) + TrimAll(vCompanyObj.Fax));
			vCompanyLegacyName = TrimAll(vCompanyLegacyName + ?(IsBlankString(vCompanyCodes), "", ", " + vCompanyCodes) + Chars.LF + vCompanyLegacyAddress + Chars.LF + ?(IsBlankString(vCompanyPostAddress), "", vCompanyPostAddress + Chars.LF) + vCompanyPhones);
			vCompanyLegacyName = TrimAll(vCompanyLegacyName);

			vParamPresentation = vParamPresentation + NStr("ru = 'Фирма '; en = 'Company '; de = 'Kompanie '") + 
			                     vCompanyLegacyName + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа фирм '; en = 'Companies folder '; de = 'Kompaniegruppe '") + 
			                     TrimAll(Company.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(Hotel) Then
		If Not Hotel.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Hotel ';ru='Гостиница ';de='Hotel '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Hotels folder ';ru='Группа гостиниц ';de='Gruppe Hotels '") + 
			                     TrimAll(Hotel.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	Return vParamPresentation;
EndFunction // pmGetReportParametersPresentation

// -----------------------------------------------------------------------------
// Runs report
// -----------------------------------------------------------------------------
Procedure pmGenerate(pSpreadsheet) Export
	Var vTemplateAttributes;
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
	
	// Initialize report builder query generator attributes
	ReportBuilder.PresentationAdding = PresentationAdditionType.Add;
	
	// Fill report parameters
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qIsEmptyHotel", Not ValueIsFilled(Hotel));
	ReportBuilder.Parameters.Insert("qPeriodFrom", ?(ValueIsFilled(PeriodFrom), PeriodFrom, '00010101010101'));
	ReportBuilder.Parameters.Insert("qPeriodTo", ?(ValueIsFilled(PeriodTo), PeriodTo, '39991231235959'));
	ReportBuilder.Parameters.Insert("qCustomer", Customer);
	ReportBuilder.Parameters.Insert("qIsEmptyCustomer", Not ValueIsFilled(Customer));
	ReportBuilder.Parameters.Insert("qContract", Contract);
	ReportBuilder.Parameters.Insert("qIsEmptyContract", Not ValueIsFilled(Contract));
	ReportBuilder.Parameters.Insert("qGuestGroup", GuestGroup);
	ReportBuilder.Parameters.Insert("qIsEmptyGuestGroup", Not ValueIsFilled(GuestGroup));
	ReportBuilder.Parameters.Insert("qCompany", Company);
	ReportBuilder.Parameters.Insert("qIsEmptyCompany", Not ValueIsFilled(Company));
	ReportBuilder.Parameters.Insert("qCurrency", Currency);
	ReportBuilder.Parameters.Insert("qIsEmptyCurrency", Not ValueIsFilled(Currency));
	ReportBuilder.Parameters.Insert("qBegOfCurrentDate", BegOfDay(CurrentSessionDate()));
	ReportBuilder.Parameters.Insert("qShowExpiredInvoicesOnly", ShowExpiredInvoicesOnly);
	ReportBuilder.Parameters.Insert("qShowDepositInvoicesOnly", ShowDepositInvoicesOnly);
	ReportBuilder.Parameters.Insert("qTypeOfInvoicesToShow", TypeOfInvoicesToShow);
	ReportBuilder.Parameters.Insert("qEmptyDate", '00010101');
	ReportBuilder.Parameters.Insert("qByGroupCheckInDate", ?(PeriodSelectionType = 1, True, False));
	
	// Execute report builder query
	ReportBuilder.Execute();
	
	// Apply appearance settings to the report template
	vTemplateAttributes = cmApplyReportTemplateAppearance(ThisObject);
	
	// Output report to the spreadsheet
	Try
		ReportBuilder.Put(pSpreadsheet);
	Except
		tcCommonFunctionOnClientServer.TextMessage(cmGetRootErrorDescription(ErrorInfo()), MessageStatus.Attention);
	EndTry;
	//ReportBuilder.Template.Show(); // For debug purpose

	// Apply appearance settings to the report spreadsheet
	cmApplyReportAppearance(ThisObject, pSpreadsheet, vTemplateAttributes);
EndProcedure // pmGenerate
	
// -----------------------------------------------------------------------------
Procedure pmInitializeReportBuilder() Export
	ReportBuilder = New ReportBuilder();
	
	// Initialize default query text
	QueryText = 
	"SELECT
	|	Invoices.Hotel AS Hotel,
	|	Invoices.Company AS Company,
	|	Invoices.Currency AS Currency,
	|	Invoices.Customer AS Customer,
	|	Invoices.Contract AS Contract,
	|	Invoices.GuestGroup AS GuestGroup,
	|	Invoices.Invoice AS Invoice,
	|	Invoices.Sum AS Sum,
	|	ISNULL(InvoiceBalances.InvoiceBalance, 0) AS InvoiceBalance,
	|	ISNULL(InvoiceDeposits.DepositBalance, 0) AS DepositBalance
	|INTO Invoices
	|FROM
	|	(SELECT
	|		InvoiceAccountsReceipt.Hotel AS Hotel,
	|		InvoiceAccountsReceipt.Company AS Company,
	|		InvoiceAccountsReceipt.AccountingCurrency AS Currency,
	|		InvoiceAccountsReceipt.AccountingCustomer AS Customer,
	|		InvoiceAccountsReceipt.AccountingContract AS Contract,
	|		InvoiceAccountsReceipt.GuestGroup AS GuestGroup,
	|		InvoiceAccountsReceipt.Invoice AS Invoice,
	|		SUM(InvoiceAccountsReceipt.Sum) AS Sum
	|	FROM
	|		AccumulationRegister.InvoiceAccounts AS InvoiceAccountsReceipt
	|	WHERE
	|		InvoiceAccountsReceipt.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND (NOT &qByGroupCheckInDate
	|					AND InvoiceAccountsReceipt.Period >= &qPeriodFrom
	|					AND InvoiceAccountsReceipt.Period <= &qPeriodTo
	|				OR &qByGroupCheckInDate
	|					AND InvoiceAccountsReceipt.GuestGroup.CheckInDate >= &qPeriodFrom
	|					AND InvoiceAccountsReceipt.GuestGroup.CheckInDate <= &qPeriodTo)
	|		AND (InvoiceAccountsReceipt.Hotel IN HIERARCHY (&qHotel)
	|				OR &qIsEmptyHotel)
	|		AND (InvoiceAccountsReceipt.Company IN HIERARCHY (&qCompany)
	|				OR &qIsEmptyCompany)
	|		AND (InvoiceAccountsReceipt.AccountingCustomer IN HIERARCHY (&qCustomer)
	|				OR &qIsEmptyCustomer)
	|		AND (InvoiceAccountsReceipt.AccountingContract IN HIERARCHY (&qContract)
	|				OR &qIsEmptyContract)
	|		AND (InvoiceAccountsReceipt.GuestGroup = &qGuestGroup
	|				OR &qIsEmptyGuestGroup)
	|		AND (InvoiceAccountsReceipt.AccountingCurrency = &qCurrency
	|				OR &qIsEmptyCurrency)
	|		AND (&qTypeOfInvoicesToShow = 0
	|					AND InvoiceAccountsReceipt.Invoice REFS Document.ProformaInvoice
	|				OR &qTypeOfInvoicesToShow = 1
	|					AND NOT InvoiceAccountsReceipt.Invoice REFS Document.ProformaInvoice)
	|	
	|	GROUP BY
	|		InvoiceAccountsReceipt.Hotel,
	|		InvoiceAccountsReceipt.Company,
	|		InvoiceAccountsReceipt.AccountingCurrency,
	|		InvoiceAccountsReceipt.AccountingCustomer,
	|		InvoiceAccountsReceipt.AccountingContract,
	|		InvoiceAccountsReceipt.GuestGroup,
	|		InvoiceAccountsReceipt.Invoice) AS Invoices
	|		LEFT JOIN (SELECT
	|			InvoiceAccountsBalance.Invoice AS Invoice,
	|			InvoiceAccountsBalance.SumBalance AS InvoiceBalance
	|		FROM
	|			AccumulationRegister.InvoiceAccounts.Balance(&qEmptyDate, ) AS InvoiceAccountsBalance) AS InvoiceBalances
	|		ON Invoices.Invoice = InvoiceBalances.Invoice
	|		LEFT JOIN (SELECT
	|			InvoiceDepositsBalance.ProformaInvoice AS Invoice,
	|			InvoiceDepositsBalance.SumBalance AS DepositBalance
	|		FROM
	|			AccumulationRegister.CustomerDeposits.Balance(&qEmptyDate, ) AS InvoiceDepositsBalance) AS InvoiceDeposits
	|		ON Invoices.Invoice = InvoiceDeposits.Invoice
	|WHERE
	|	(NOT &qShowExpiredInvoicesOnly
	|			OR &qShowExpiredInvoicesOnly
	|				AND ISNULL(InvoiceBalances.InvoiceBalance, 0) = ISNULL(Invoices.Sum, 0)
	|				AND Invoices.Invoice.CheckDate < &qBegOfCurrentDate)
	|	AND (NOT &qShowDepositInvoicesOnly
	|			OR &qShowDepositInvoicesOnly
	|				AND ISNULL(InvoiceDeposits.DepositBalance, 0) <> 0)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Invoices.GuestGroup AS GuestGroup
	|INTO GuestGroups
	|FROM
	|	Invoices AS Invoices
	|
	|GROUP BY
	|	Invoices.GuestGroup
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Invoices.GuestGroup AS GuestGroup,
	|	MAX(Invoices.Number) AS InvoiceNumber
	|INTO GuestGroupInvoiceNumbers
	|FROM
	|	Document.Settlement AS Invoices
	|		INNER JOIN GuestGroups AS GuestGroups
	|		ON Invoices.GuestGroup = GuestGroups.GuestGroup
	|WHERE
	|	Invoices.Posted
	|
	|GROUP BY
	|	Invoices.GuestGroup
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GroupInvoices.GuestGroup AS GuestGroup,
	|	GroupInvoices.Ref AS GroupInvoice
	|INTO GuestGroupInvoices
	|FROM
	|	Document.Settlement AS GroupInvoices
	|		INNER JOIN GuestGroupInvoiceNumbers AS GuestGroupInvoiceNumbers
	|		ON GroupInvoices.GuestGroup = GuestGroupInvoiceNumbers.GuestGroup
	|			AND GroupInvoices.Number = GuestGroupInvoiceNumbers.InvoiceNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InvoiceAccountsExpense.Hotel AS Hotel,
	|	InvoiceAccountsExpense.Company AS Company,
	|	InvoiceAccountsExpense.AccountingCurrency AS Currency,
	|	InvoiceAccountsExpense.AccountingCustomer AS Customer,
	|	InvoiceAccountsExpense.AccountingContract AS Contract,
	|	InvoiceAccountsExpense.GuestGroup AS GuestGroup,
	|	InvoiceAccountsExpense.Invoice AS Invoice,
	|	InvoiceAccountsExpense.Recorder AS Payment,
	|	SUM(InvoiceAccountsExpense.Sum) AS Sum
	|INTO InvoicePayments
	|FROM
	|	AccumulationRegister.InvoiceAccounts AS InvoiceAccountsExpense
	|WHERE
	|	InvoiceAccountsExpense.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND InvoiceAccountsExpense.Invoice IN
	|			(SELECT
	|				Invoices.Invoice
	|			FROM
	|				Invoices AS Invoices)
	|
	|GROUP BY
	|	InvoiceAccountsExpense.Hotel,
	|	InvoiceAccountsExpense.Company,
	|	InvoiceAccountsExpense.AccountingCurrency,
	|	InvoiceAccountsExpense.AccountingCustomer,
	|	InvoiceAccountsExpense.AccountingContract,
	|	InvoiceAccountsExpense.GuestGroup,
	|	InvoiceAccountsExpense.Invoice,
	|	InvoiceAccountsExpense.Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InvoiceAccounts.Hotel AS Hotel,
	|	InvoiceAccounts.Company AS Company,
	|	InvoiceAccounts.Currency AS Currency,
	|	InvoiceAccounts.Customer AS Customer,
	|	InvoiceAccounts.Contract AS Contract,
	|	InvoiceAccounts.GuestGroup AS GuestGroup,
	|	InvoiceAccounts.Invoice AS Invoice,
	|	InvoiceAccounts.InvoiceAge AS InvoiceAge,
	|	InvoiceAccounts.DaysBeforeCheckIn AS DaysBeforeCheckIn,
	|	InvoiceAccounts.Payment AS Payment,
	|	InvoiceAccounts.PaymentDelay AS PaymentDelay,
	|	InvoiceAccounts.PaymentDaysBeforeCheckIn AS PaymentDaysBeforeCheckIn,
	|	SUM(InvoiceAccounts.Sum) AS Sum,
	|	SUM(InvoiceAccounts.SumReceipt) AS SumReceipt,
	|	SUM(InvoiceAccounts.SumExpense) AS SumExpense,
	|	SUM(InvoiceAccounts.SumBalance) AS SumBalance,
	|	SUM(InvoiceAccounts.DepositBalance) AS DepositBalance,
	|	COUNT(DISTINCT InvoiceAccounts.Invoice) AS InvoicesCounter
	|INTO InvoiceAccounts
	|FROM
	|	(SELECT
	|		Invoices.Hotel AS Hotel,
	|		Invoices.Company AS Company,
	|		Invoices.Currency AS Currency,
	|		Invoices.Customer AS Customer,
	|		Invoices.Contract AS Contract,
	|		Invoices.GuestGroup AS GuestGroup,
	|		Invoices.Invoice AS Invoice,
	|		DATEDIFF(BEGINOFPERIOD(Invoices.Invoice.Date, DAY), &qBegOfCurrentDate, DAY) AS InvoiceAge,
	|		DATEDIFF(&qBegOfCurrentDate, BEGINOFPERIOD(Invoices.GuestGroup.CheckInDate, DAY), DAY) AS DaysBeforeCheckIn,
	|		NULL AS Payment,
	|		NULL AS PaymentDelay,
	|		NULL AS PaymentDaysBeforeCheckIn,
	|		CASE
	|			WHEN Invoices.Invoice.Sum IS NULL
	|					AND Invoices.Invoice REFS Document.DebitNote
	|				THEN ISNULL(Invoices.Invoice.CorrectionSum, 0)
	|			WHEN Invoices.Invoice.Sum IS NULL
	|					AND Invoices.Invoice REFS Document.CreditNote
	|				THEN -ISNULL(Invoices.Invoice.CorrectionSum, 0)
	|			ELSE Invoices.Invoice.Sum
	|		END AS Sum,
	|		Invoices.Sum AS SumReceipt,
	|		0 AS SumExpense,
	|		Invoices.Sum AS SumBalance,
	|		Invoices.DepositBalance AS DepositBalance
	|	FROM
	|		Invoices AS Invoices
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		InvoicePayments.Hotel,
	|		InvoicePayments.Company,
	|		InvoicePayments.Currency,
	|		InvoicePayments.Customer,
	|		InvoicePayments.Contract,
	|		InvoicePayments.GuestGroup,
	|		InvoicePayments.Invoice,
	|		DATEDIFF(BEGINOFPERIOD(InvoicePayments.Invoice.Date, DAY), &qBegOfCurrentDate, DAY),
	|		DATEDIFF(&qBegOfCurrentDate, BEGINOFPERIOD(InvoicePayments.GuestGroup.CheckInDate, DAY), DAY),
	|		InvoicePayments.Payment,
	|		DATEDIFF(BEGINOFPERIOD(InvoicePayments.Invoice.Date, DAY), BEGINOFPERIOD(InvoicePayments.Payment.Date, DAY), DAY),
	|		DATEDIFF(BEGINOFPERIOD(InvoicePayments.Payment.Date, DAY), BEGINOFPERIOD(InvoicePayments.GuestGroup.CheckInDate, DAY), DAY),
	|		0,
	|		0,
	|		InvoicePayments.Sum,
	|		-InvoicePayments.Sum,
	|		0
	|	FROM
	|		InvoicePayments AS InvoicePayments) AS InvoiceAccounts
	|
	|GROUP BY
	|	InvoiceAccounts.Hotel,
	|	InvoiceAccounts.Company,
	|	InvoiceAccounts.Currency,
	|	InvoiceAccounts.Customer,
	|	InvoiceAccounts.Contract,
	|	InvoiceAccounts.GuestGroup,
	|	InvoiceAccounts.Invoice,
	|	InvoiceAccounts.InvoiceAge,
	|	InvoiceAccounts.DaysBeforeCheckIn,
	|	InvoiceAccounts.Payment,
	|	InvoiceAccounts.PaymentDelay,
	|	InvoiceAccounts.PaymentDaysBeforeCheckIn
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InvoiceAccounts.Currency AS Currency,
	|	InvoiceAccounts.Customer AS Customer,
	|	InvoiceAccounts.Contract AS Contract,
	|	InvoiceAccounts.GuestGroup AS GuestGroup,
	|	InvoiceAccounts.Invoice AS Invoice,
	|	InvoiceAccounts.InvoiceAge AS InvoiceAge,
	|	InvoiceAccounts.DaysBeforeCheckIn AS DaysBeforeCheckIn,
	|	InvoiceAccounts.Payment AS Payment,
	|	InvoiceAccounts.Sum AS Sum,
	|	InvoiceAccounts.SumReceipt AS SumReceipt,
	|	InvoiceAccounts.SumExpense AS SumExpense,
	|	InvoiceAccounts.SumBalance AS SumBalance,
	|	InvoiceAccounts.DepositBalance AS DepositBalance,
	|	GuestGroupInvoices.GroupInvoice.Sum AS GroupInvoiceSum,
	|	InvoiceAccounts.InvoicesCounter AS InvoicesCounter
	|{SELECT
	|	InvoiceAccounts.Hotel.*,
	|	InvoiceAccounts.Company.*,
	|	Currency.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	Invoice.*,
	|	InvoiceAccounts.Invoice.Remarks AS Remarks,
	|	Payment.*,
	|	InvoiceAge,
	|	DaysBeforeCheckIn,
	|	InvoiceAccounts.PaymentDelay,
	|	InvoiceAccounts.PaymentDaysBeforeCheckIn,
	|	GuestGroupInvoices.GroupInvoice.* AS GroupInvoice,
	|	Sum,
	|	SumReceipt,
	|	SumExpense,
	|	SumBalance,
	|	DepositBalance,
	|	GroupInvoiceSum,
	|	InvoicesCounter}
	|FROM
	|	InvoiceAccounts AS InvoiceAccounts
	|		LEFT JOIN GuestGroupInvoices AS GuestGroupInvoices
	|		ON InvoiceAccounts.GuestGroup = GuestGroupInvoices.GuestGroup
	|			AND (InvoiceAccounts.GuestGroup <> VALUE(Catalog.GuestGroups.EmptyRef))
	|{WHERE
	|	InvoiceAccounts.Hotel.*,
	|	InvoiceAccounts.Company.*,
	|	InvoiceAccounts.Currency.*,
	|	InvoiceAccounts.Customer.*,
	|	InvoiceAccounts.Contract.*,
	|	InvoiceAccounts.GuestGroup.*,
	|	InvoiceAccounts.InvoiceAge,
	|	InvoiceAccounts.PaymentDelay,
	|	InvoiceAccounts.DaysBeforeCheckIn,
	|	InvoiceAccounts.PaymentDaysBeforeCheckIn,
	|	InvoiceAccounts.Invoice.*,
	|	InvoiceAccounts.Invoice.Remarks AS Remarks,
	|	InvoiceAccounts.Payment.*,
	|	GuestGroupInvoices.GroupInvoice.* AS GroupInvoice,
	|	InvoiceAccounts.Sum AS Sum,
	|	InvoiceAccounts.SumReceipt AS SumReceipt,
	|	InvoiceAccounts.SumExpense AS SumExpense,
	|	InvoiceAccounts.SumBalance AS SumBalance,
	|	InvoiceAccounts.DepositBalance AS DepositBalance}
	|
	|ORDER BY
	|	Currency,
	|	Customer,
	|	Contract,
	|	InvoiceAccounts.Invoice.Date,
	|	InvoiceAccounts.Payment.Date
	|{ORDER BY
	|	InvoiceAccounts.Hotel.*,
	|	InvoiceAccounts.Company.*,
	|	Currency.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	InvoiceAge,
	|	DaysBeforeCheckIn,
	|	InvoiceAccounts.PaymentDelay,
	|	InvoiceAccounts.PaymentDaysBeforeCheckIn,
	|	Invoice.*,
	|	Payment.*,
	|	GuestGroupInvoices.GroupInvoice.* AS GroupInvoice,
	|	Sum,
	|	SumReceipt,
	|	SumExpense,
	|	SumBalance,
	|	DepositBalance,
	|	GroupInvoiceSum}
	|TOTALS
	|	MAX(InvoiceAge),
	|	MIN(DaysBeforeCheckIn),
	|	SUM(Sum),
	|	SUM(SumReceipt),
	|	SUM(SumExpense),
	|	SUM(SumBalance),
	|	SUM(DepositBalance),
	|	SUM(GroupInvoiceSum),
	|	SUM(InvoicesCounter)
	|BY
	|	OVERALL,
	|	Currency,
	|	Customer,
	|	Contract,
	|	Invoice
	|{TOTALS BY
	|	InvoiceAccounts.Hotel.*,
	|	InvoiceAccounts.Company.*,
	|	Currency.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	InvoiceAge,
	|	DaysBeforeCheckIn,
	|	Invoice.*,
	|	GuestGroupInvoices.GroupInvoice.* AS GroupInvoice,
	|	Payment.*}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Settlements on Proforma/Invoices';RU='Взаиморасчеты по счетам и актам';de='Gegenseitige Abrechnung nach Proforma/Rechnungen'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
