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
			vParamPresentation = vParamPresentation + NStr("de='Firma ';en='Customer ';ru='Контрагент '") + 
			                     TrimAll(Customer.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("de='Firmengruppe ';en='Customers folder ';ru='Группа контрагентов '") + 
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
	If ValueIsFilled(Company) Then
		If Not Company.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Фирма '; en = 'Company '; de = 'Kompanie '") + 
			                     TrimAll(Company.LegacyName) + 
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
			vParamPresentation = vParamPresentation + NStr("en='Hotels folder ';ru='Группа гостиниц ';de='Hotelgruppe '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
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
	ReportBuilder.Parameters.Insert("qEmptyDate", '00010101');
	
	// Execute report builder query
	ReportBuilder.Execute();
	
	// Apply appearance settings to the report template
	vTemplateAttributes = cmApplyReportTemplateAppearance(ThisObject);
	
	// Output report to the spreadsheet
	ReportBuilder.Put(pSpreadsheet);
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
	|	Invoices.Invoice.CheckDate AS CheckDate,
	|	Invoices.Sum AS Sum,
	|	InvoiceBalances.InvoiceBalance AS InvoiceBalance
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
	|		AND InvoiceAccountsReceipt.Invoice.CheckDate <> &qEmptyDate
	|		AND InvoiceAccountsReceipt.Invoice.CheckDate >= &qPeriodFrom
	|		AND InvoiceAccountsReceipt.Invoice.CheckDate <= &qPeriodTo
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
	|	InvoiceAccounts.CheckDate AS CheckDate,
	|	InvoiceAccounts.Invoice AS Invoice,
	|	InvoiceAccounts.InvoiceAge AS InvoiceAge,
	|	InvoiceAccounts.DaysBeforeCheckIn AS DaysBeforeCheckIn,
	|	InvoiceAccounts.Payment AS Payment,
	|	InvoiceAccounts.PaymentDelay AS PaymentDelay,
	|	InvoiceAccounts.PaymentDays AS PaymentDays,
	|	InvoiceAccounts.PaymentDaysBeforeCheckIn AS PaymentDaysBeforeCheckIn,
	|	SUM(InvoiceAccounts.SumReceipt) AS SumReceipt,
	|	SUM(InvoiceAccounts.SumExpense) AS SumExpense,
	|	SUM(InvoiceAccounts.SumBalance) AS SumBalance
	|INTO InvoiceAccounts
	|FROM
	|	(SELECT
	|		Invoices.Hotel AS Hotel,
	|		Invoices.Company AS Company,
	|		Invoices.Currency AS Currency,
	|		Invoices.Customer AS Customer,
	|		Invoices.Contract AS Contract,
	|		Invoices.GuestGroup AS GuestGroup,
	|		Invoices.CheckDate AS CheckDate,
	|		Invoices.Invoice AS Invoice,
	|		DATEDIFF(BEGINOFPERIOD(Invoices.Invoice.Date, DAY), &qBegOfCurrentDate, DAY) AS InvoiceAge,
	|		DATEDIFF(&qBegOfCurrentDate, BEGINOFPERIOD(Invoices.GuestGroup.CheckInDate, DAY), DAY) AS DaysBeforeCheckIn,
	|		NULL AS Payment,
	|		NULL AS PaymentDelay,
	|		NULL AS PaymentDays,
	|		NULL AS PaymentDaysBeforeCheckIn,
	|		Invoices.Sum AS SumReceipt,
	|		0 AS SumExpense,
	|		Invoices.Sum AS SumBalance
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
	|		InvoicePayments.Invoice.CheckDate,
	|		InvoicePayments.Invoice,
	|		DATEDIFF(BEGINOFPERIOD(InvoicePayments.Invoice.Date, DAY), &qBegOfCurrentDate, DAY),
	|		DATEDIFF(&qBegOfCurrentDate, BEGINOFPERIOD(InvoicePayments.GuestGroup.CheckInDate, DAY), DAY),
	|		InvoicePayments.Payment,
	|		CASE
	|			WHEN ISNULL(InvoicePayments.Invoice.CheckDate, &qEmptyDate) > &qEmptyDate
	|					AND ISNULL(InvoicePayments.Payment.Date, &qEmptyDate) > &qEmptyDate
	|				THEN CASE
	|						WHEN BEGINOFPERIOD(InvoicePayments.Invoice.CheckDate, DAY) < BEGINOFPERIOD(InvoicePayments.Payment.Date, DAY)
	|							THEN DATEDIFF(BEGINOFPERIOD(InvoicePayments.Invoice.CheckDate, DAY), BEGINOFPERIOD(InvoicePayments.Payment.Date, DAY), DAY)
	|						ELSE 0
	|					END
	|			ELSE 0
	|		END,
	|		CASE
	|			WHEN ISNULL(InvoicePayments.Invoice.Date, &qEmptyDate) > &qEmptyDate
	|					AND ISNULL(InvoicePayments.Payment.Date, &qEmptyDate) > &qEmptyDate
	|				THEN CASE
	|						WHEN BEGINOFPERIOD(InvoicePayments.Invoice.Date, DAY) < BEGINOFPERIOD(InvoicePayments.Payment.Date, DAY)
	|							THEN DATEDIFF(BEGINOFPERIOD(InvoicePayments.Invoice.Date, DAY), BEGINOFPERIOD(InvoicePayments.Payment.Date, DAY), DAY)
	|						ELSE 0
	|					END
	|			ELSE 0
	|		END,
	|		CASE
	|			WHEN ISNULL(InvoicePayments.GuestGroup.CheckInDate, &qEmptyDate) > &qEmptyDate
	|					AND ISNULL(InvoicePayments.Payment.Date, &qEmptyDate) > &qEmptyDate
	|				THEN CASE
	|						WHEN BEGINOFPERIOD(InvoicePayments.Payment.Date, DAY) < BEGINOFPERIOD(InvoicePayments.GuestGroup.CheckInDate, DAY)
	|							THEN DATEDIFF(BEGINOFPERIOD(InvoicePayments.Payment.Date, DAY), BEGINOFPERIOD(InvoicePayments.GuestGroup.CheckInDate, DAY), DAY)
	|						ELSE 0
	|					END
	|			ELSE 0
	|		END,
	|		0,
	|		InvoicePayments.Sum,
	|		-InvoicePayments.Sum
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
	|	InvoiceAccounts.CheckDate,
	|	InvoiceAccounts.Invoice,
	|	InvoiceAccounts.InvoiceAge,
	|	InvoiceAccounts.DaysBeforeCheckIn,
	|	InvoiceAccounts.Payment,
	|	InvoiceAccounts.PaymentDelay,
	|	InvoiceAccounts.PaymentDays,
	|	InvoiceAccounts.PaymentDaysBeforeCheckIn
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InvoiceAccounts.Currency AS Currency,
	|	InvoiceAccounts.Customer AS Customer,
	|	InvoiceAccounts.Contract AS Contract,
	|	InvoiceAccounts.GuestGroup AS GuestGroup,
	|	InvoiceAccounts.CheckDate AS CheckDate,
	|	InvoiceAccounts.Invoice AS Invoice,
	|	InvoiceAccounts.InvoiceAge AS InvoiceAge,
	|	InvoiceAccounts.DaysBeforeCheckIn AS DaysBeforeCheckIn,
	|	InvoiceAccounts.Payment AS Payment,
	|	InvoiceAccounts.SumReceipt AS SumReceipt,
	|	InvoiceAccounts.SumExpense AS SumExpense,
	|	InvoiceAccounts.SumBalance AS SumBalance
	|{SELECT
	|	InvoiceAccounts.Hotel.*,
	|	InvoiceAccounts.Company.*,
	|	Currency.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	CheckDate,
	|	(WEEK(InvoiceAccounts.CheckDate)) AS CheckDateWeek,
	|	(MONTH(InvoiceAccounts.CheckDate)) AS CheckDateMonth,
	|	(QUARTER(InvoiceAccounts.CheckDate)) AS CheckDateQuarter,
	|	(YEAR(InvoiceAccounts.CheckDate)) AS CheckDateYear,
	|	Invoice.*,
	|	InvoiceAccounts.Invoice.Remarks AS Remarks,
	|	Payment.*,
	|	InvoiceAge,
	|	DaysBeforeCheckIn,
	|	InvoiceAccounts.PaymentDelay,
	|	InvoiceAccounts.PaymentDays,
	|	InvoiceAccounts.PaymentDaysBeforeCheckIn,
	|	SumReceipt,
	|	SumExpense,
	|	SumBalance}
	|FROM
	|	InvoiceAccounts AS InvoiceAccounts
	|{WHERE
	|	InvoiceAccounts.Hotel.*,
	|	InvoiceAccounts.Company.*,
	|	InvoiceAccounts.Currency.*,
	|	InvoiceAccounts.Customer.*,
	|	InvoiceAccounts.Contract.*,
	|	InvoiceAccounts.GuestGroup.*,
	|	InvoiceAccounts.InvoiceAge,
	|	InvoiceAccounts.PaymentDelay,
	|	InvoiceAccounts.PaymentDays,
	|	InvoiceAccounts.DaysBeforeCheckIn,
	|	InvoiceAccounts.PaymentDaysBeforeCheckIn,
	|	InvoiceAccounts.Invoice.*,
	|	InvoiceAccounts.Invoice.Remarks AS Remarks,
	|	InvoiceAccounts.Payment.*,
	|	InvoiceAccounts.SumReceipt AS SumReceipt,
	|	InvoiceAccounts.SumExpense AS SumExpense,
	|	InvoiceAccounts.SumBalance AS SumBalance}
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
	|	CheckDate,
	|	(WEEK(InvoiceAccounts.CheckDate)) AS CheckDateWeek,
	|	(MONTH(InvoiceAccounts.CheckDate)) AS CheckDateMonth,
	|	(QUARTER(InvoiceAccounts.CheckDate)) AS CheckDateQuarter,
	|	(YEAR(InvoiceAccounts.CheckDate)) AS CheckDateYear,
	|	InvoiceAge,
	|	DaysBeforeCheckIn,
	|	InvoiceAccounts.PaymentDelay,
	|	InvoiceAccounts.PaymentDays,
	|	InvoiceAccounts.PaymentDaysBeforeCheckIn,
	|	Invoice.*,
	|	Payment.*,
	|	SumReceipt,
	|	SumExpense,
	|	SumBalance}
	|TOTALS
	|	MAX(InvoiceAge),
	|	MIN(DaysBeforeCheckIn),
	|	SUM(SumReceipt),
	|	SUM(SumExpense),
	|	SUM(SumBalance)
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
	|	CheckDate,
	|	(WEEK(InvoiceAccounts.CheckDate)) AS CheckDateWeek,
	|	(MONTH(InvoiceAccounts.CheckDate)) AS CheckDateMonth,
	|	(QUARTER(InvoiceAccounts.CheckDate)) AS CheckDateQuarter,
	|	(YEAR(InvoiceAccounts.CheckDate)) AS CheckDateYear,
	|	InvoiceAge,
	|	DaysBeforeCheckIn,
	|	Invoice.*,
	|	Payment.*}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("ru='График платежей по счетам на оплату';de='Zeitplan der Zahlungen auf Rechnungen';en='Payments schedule by invoices'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
