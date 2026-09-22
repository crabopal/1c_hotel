// -----------------------------------------------------------------------------
// Reports framework start
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Procedure pmSaveReportAttributes() Export
	cmSaveReportAttributes(ThisObject);
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
	EndIf;
	If Not ValueIsFilled(Company) Then
		If ValueIsFilled(Hotel) Then
			Company = Hotel.Company;
		EndIf;
	EndIf;
	If Not ValueIsFilled(PeriodFrom) Then
		PeriodFrom = BegOfMonth(CurrentSessionDate()); // For beg. of month
	EndIf;
	If Not ValueIsFilled(PeriodTo) Then
		PeriodTo = EndOfMonth(CurrentSessionDate()); // For end of month
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
		vParamPresentation = vParamPresentation + NStr("ru = 'Период '; en = 'Period '") + PeriodPresentation(PeriodFrom, PeriodTo, cmLocalizationCode()) + 
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
	If ValueIsFilled(ServiceGroup) Then
		If Not ServiceGroup.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Набор услуг '; en = 'Service group '; de = 'Dienstgruppe '") + 
			                     TrimAll(ServiceGroup.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа наборов услуг '; en = 'Service groups folder '; de = 'Dienstgruppengruppe '") + 
			                     TrimAll(ServiceGroup.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;					 
	If ValueIsFilled(Company) Then
		If Not Company.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Фирма '; en = 'Company '; de = 'Kompanie '") + 
			                     Company.GetObject().pmGetCompanyPrintName(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа фирм '; en = 'Companies folder '; de = 'Kompaniegruppe '") + 
			                     Company.GetObject().pmGetCompanyPrintName(SessionParameters.CurrentLanguage) + 
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
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	Return vParamPresentation;
EndFunction // pmGetReportParametersPresentation

// -----------------------------------------------------------------------------
// Runs report
// -----------------------------------------------------------------------------
Procedure pmGenerate(pSpreadsheet, pAddChart = False) Export
	Var vTemplateAttributes;
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
	
	// Initialize report builder query generator attributes
	ReportBuilder.PresentationAdding = PresentationAdditionType.Add;
	
	// Fill report parameters
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qIsEmptyHotel", Not ValueIsFilled(Hotel));
	ReportBuilder.Parameters.Insert("qCompany", Company);
	ReportBuilder.Parameters.Insert("qIsEmptyCompany", Not ValueIsFilled(Company));
	ReportBuilder.Parameters.Insert("qCustomer", Customer);
	ReportBuilder.Parameters.Insert("qIsEmptyCustomer", Not ValueIsFilled(Customer));
	ReportBuilder.Parameters.Insert("qContract", Contract);
	ReportBuilder.Parameters.Insert("qIsEmptyContract", Not ValueIsFilled(Contract));
	ReportBuilder.Parameters.Insert("qGuestGroup", GuestGroup);
	ReportBuilder.Parameters.Insert("qIsEmptyGuestGroup", Not ValueIsFilled(GuestGroup));
	vUseServicesList = False;
	vServicesList = New ValueList();
	If ValueIsFilled(ServiceGroup) Then
		If Not ServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(ServiceGroup);
		EndIf;
	EndIf;
	ReportBuilder.Parameters.Insert("qUseServicesList", vUseServicesList);
	ReportBuilder.Parameters.Insert("qServicesList", vServicesList);
	ReportBuilder.Parameters.Insert("qServices", NStr("en='Services'; ru='Услуги'; de='Dienstleistungen'"));
	ReportBuilder.Parameters.Insert("qPayments", NStr("en='Payments'; ru='Платежи'; de='Zahlungen'"));
	ReportBuilder.Parameters.Insert("qShowPayments", ShowPayments);
	
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
	
	// Add chart 
	If pAddChart Then
		cmAddReportChart(pSpreadsheet, ThisObject);
	EndIf;
EndProcedure // pmGenerate
	
// -----------------------------------------------------------------------------
Procedure pmInitializeReportBuilder() Export
	ReportBuilder = New ReportBuilder();
	
	// Initialize default query text
	QueryText = 
	"SELECT DISTINCT
	|	Invoices.Settlement AS Invoice
	|INTO Invoices
	|FROM
	|	AccumulationRegister.AccountsReceivable.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			(Hotel IN HIERARCHY (&qHotel)
	|				OR &qIsEmptyHotel)
	|				AND (Company IN HIERARCHY (&qCompany)
	|					OR &qIsEmptyCompany)
	|				AND (AccountingCustomer IN HIERARCHY (&qCustomer)
	|					OR &qIsEmptyCustomer)
	|				AND (AccountingContract = &qContract
	|					OR &qIsEmptyContract)) AS Invoices
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	InvoiceFolios.Folio AS Folio
	|INTO InvoiceFolios
	|FROM
	|	AccumulationRegister.AccountsReceivable.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			Settlement IN
	|					(SELECT
	|						Invoices.Invoice
	|					FROM
	|						Invoices AS Invoices)
	|				AND (GuestGroup = &qGuestGroup
	|					OR &qIsEmptyGuestGroup)
	|				AND (Hotel IN HIERARCHY (&qHotel)
	|					OR &qIsEmptyHotel)
	|				AND (Service IN (&qServicesList)
	|					OR NOT &qUseServicesList)) AS InvoiceFolios
	|
	|GROUP BY
	|	InvoiceFolios.Folio
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	InvoicePayments.PaymentDoc AS PaymentDoc,
	|	InvoicePayments.Invoice AS Invoice
	|INTO InvoicePayments
	|FROM
	|	(SELECT
	|		InvoicePayments.PaymentDoc AS PaymentDoc,
	|		Invoices1.Invoice AS Invoice
	|	FROM
	|		Document.Settlement.PaymentDocuments AS InvoicePayments
	|			INNER JOIN Invoices AS Invoices1
	|			ON InvoicePayments.Ref = Invoices1.Invoice
	|	WHERE
	|		InvoicePayments.PaymentDoc.Posted
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Payments.Ref,
	|		Invoices2.Invoice
	|	FROM
	|		Document.Payment AS Payments
	|			INNER JOIN Invoices AS Invoices2
	|			ON Payments.Invoice = Invoices2.Invoice
	|	WHERE
	|		Payments.Posted
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Returns.Ref,
	|		Invoices4.Invoice
	|	FROM
	|		Document.Return AS Returns
	|			INNER JOIN Invoices AS Invoices4
	|			ON Returns.Invoice = Invoices4.Invoice
	|	WHERE
	|		Returns.Posted
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CustomerPayments.Ref,
	|		Invoices3.Invoice
	|	FROM
	|		Document.CustomerPayment AS CustomerPayments
	|			INNER JOIN Invoices AS Invoices3
	|			ON CustomerPayments.Invoice = Invoices3.Invoice
	|	WHERE
	|		CustomerPayments.Posted) AS InvoicePayments
	|
	|GROUP BY
	|	InvoicePayments.PaymentDoc,
	|	InvoicePayments.Invoice
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InvoiceTransactions.Period AS Period,
	|	InvoiceTransactions.Company AS Company,
	|	InvoiceTransactions.AccountingCustomer AS AccountingCustomer,
	|	InvoiceTransactions.GuestGroup AS GuestGroup,
	|	InvoiceTransactions.Folio AS Folio,
	|	InvoiceTransactions.Folio.Client AS FolioClient,
	|	InvoiceTransactions.Folio.Room AS FolioRoom,
	|	InvoiceTransactions.Folio.DateTimeFrom AS FolioDateTimeFrom,
	|	InvoiceTransactions.Folio.DateTimeTo AS FolioDateTimeTo,
	|	InvoiceTransactions.Service AS Service,
	|	InvoiceTransactions.CommissionSum AS CommissionSum,
	|	InvoiceTransactions.Sum AS Sum,
	|	InvoiceTransactions.SumWithoutVAT AS SumWithoutVAT,
	|	InvoiceTransactions.VATSum AS VATSum,
	|	InvoiceTransactions.Quantity AS Quantity,
	|	InvoiceTransactions.PaymentSum AS PaymentSum,
	|	InvoiceTransactions.PaymentSumWithoutVAT AS PaymentSumWithoutVAT,
	|	InvoiceTransactions.PaymentVATSum AS PaymentVATSum,
	|	0 AS PaymentsDiff
	|{SELECT
	|	InvoiceTransactions.TransactionType AS TransactionType,
	|	Period,
	|	InvoiceTransactions.AccountingDate,
	|	InvoiceTransactions.Hotel.*,
	|	InvoiceTransactions.Settlement.*,
	|	InvoiceTransactions.ParentDoc.*,
	|	InvoiceTransactions.HotelProduct.*,
	|	Company.*,
	|	InvoiceTransactions.AccountingCurrency.*,
	|	AccountingCustomer.*,
	|	InvoiceTransactions.AccountingContract.*,
	|	GuestGroup.*,
	|	Folio.*,
	|	FolioRoom.*,
	|	FolioClient.*,
	|	FolioDateTimeFrom,
	|	FolioDateTimeTo,
	|	Service.*,
	|	InvoiceTransactions.VATRate.*,
	|	CommissionSum,
	|	Sum,
	|	SumWithoutVAT,
	|	VATSum,
	|	Quantity,
	|	PaymentSum,
	|	PaymentSumWithoutVAT,
	|	PaymentVATSum,
	|	PaymentsDiff}
	|FROM
	|	(SELECT
	|		&qServices AS TransactionType,
	|		BEGINOFPERIOD(AccountsReceivableTurnovers.Period, DAY) AS Period,
	|		AccountsReceivableTurnovers.AccountingDate AS AccountingDate,
	|		AccountsReceivableTurnovers.Hotel AS Hotel,
	|		AccountsReceivableTurnovers.Settlement AS Settlement,
	|		AccountsReceivableTurnovers.Folio.ParentDoc AS ParentDoc,
	|		AccountsReceivableTurnovers.HotelProduct AS HotelProduct,
	|		AccountsReceivableTurnovers.AccountingCurrency AS AccountingCurrency,
	|		AccountsReceivableTurnovers.Company AS Company,
	|		AccountsReceivableTurnovers.AccountingCustomer AS AccountingCustomer,
	|		AccountsReceivableTurnovers.AccountingContract AS AccountingContract,
	|		AccountsReceivableTurnovers.GuestGroup AS GuestGroup,
	|		AccountsReceivableTurnovers.Folio AS Folio,
	|		AccountsReceivableTurnovers.Service AS Service,
	|		AccountsReceivableTurnovers.VATRate AS VATRate,
	|		AccountsReceivableTurnovers.CommissionSumTurnover AS CommissionSum,
	|		AccountsReceivableTurnovers.SumTurnover AS Sum,
	|		AccountsReceivableTurnovers.SumTurnover - AccountsReceivableTurnovers.VATSumTurnover AS SumWithoutVAT,
	|		AccountsReceivableTurnovers.VATSumTurnover AS VATSum,
	|		AccountsReceivableTurnovers.QuantityTurnover AS Quantity,
	|		0 AS PaymentSum,
	|		0 AS PaymentSumWithoutVAT,
	|		0 AS PaymentVATSum
	|	FROM
	|		AccumulationRegister.AccountsReceivable.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Day,
	|				Settlement IN
	|						(SELECT
	|							Invoices.Invoice
	|						FROM
	|							Invoices AS Invoices)
	|					AND (GuestGroup = &qGuestGroup
	|						OR &qIsEmptyGuestGroup)
	|					AND (Hotel IN HIERARCHY (&qHotel)
	|						OR &qIsEmptyHotel)
	|					AND (Service IN (&qServicesList)
	|						OR NOT &qUseServicesList)) AS AccountsReceivableTurnovers
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		&qPayments,
	|		BEGINOFPERIOD(CustomerAccounts.Period, DAY),
	|		CustomerAccounts.AccountingDate,
	|		CustomerAccounts.Hotel,
	|		InvoicePayments.Invoice,
	|		CustomerAccounts.Recorder.Folio.ParentDoc,
	|		NULL,
	|		CustomerAccounts.AccountingCurrency,
	|		CustomerAccounts.Company,
	|		CustomerAccounts.AccountingCustomer,
	|		CustomerAccounts.AccountingContract,
	|		CustomerAccounts.GuestGroup,
	|		CustomerAccounts.Folio,
	|		CustomerAccounts.Recorder.PaymentMethod,
	|		CustomerAccounts.VATRate,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		SUM(CustomerAccounts.Sum),
	|		SUM(CustomerAccounts.Sum) - SUM(CustomerAccounts.VATSum),
	|		SUM(CustomerAccounts.VATSum)
	|	FROM
	|		AccumulationRegister.CustomerAccounts AS CustomerAccounts
	|			INNER JOIN InvoicePayments AS InvoicePayments
	|			ON CustomerAccounts.Recorder = InvoicePayments.PaymentDoc
	|			INNER JOIN InvoiceFolios AS InvoiceFolios
	|			ON CustomerAccounts.Folio = InvoiceFolios.Folio
	|	WHERE
	|		&qShowPayments
	|		AND (CustomerAccounts.GuestGroup = &qGuestGroup
	|				OR &qIsEmptyGuestGroup)
	|		AND (CustomerAccounts.Hotel IN HIERARCHY (&qHotel)
	|				OR &qIsEmptyHotel)
	|	
	|	GROUP BY
	|		BEGINOFPERIOD(CustomerAccounts.Period, DAY),
	|		CustomerAccounts.AccountingDate,
	|		CustomerAccounts.Hotel,
	|		InvoicePayments.Invoice,
	|		CustomerAccounts.ParentDoc,
	|		CustomerAccounts.AccountingCurrency,
	|		CustomerAccounts.Company,
	|		CustomerAccounts.AccountingCustomer,
	|		CustomerAccounts.AccountingContract,
	|		CustomerAccounts.GuestGroup,
	|		CustomerAccounts.Folio,
	|		CustomerAccounts.Recorder.PaymentMethod,
	|		CustomerAccounts.VATRate,
	|		CustomerAccounts.Recorder.Folio.ParentDoc
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		&qPayments,
	|		BEGINOFPERIOD(CityLedgerPayments.Period, DAY),
	|		BEGINOFPERIOD(CityLedgerPayments.Period, DAY),
	|		CityLedgerPayments.Hotel,
	|		CityLedgerPayments.Recorder,
	|		CityLedgerPayments.Folio.ParentDoc,
	|		NULL,
	|		CityLedgerPayments.FolioCurrency,
	|		CityLedgerPayments.Folio.Company,
	|		CityLedgerPayments.Folio.Customer,
	|		CityLedgerPayments.Folio.Contract,
	|		CityLedgerPayments.Folio.GuestGroup,
	|		CityLedgerPayments.Folio,
	|		CityLedgerPayments.PaymentMethod,
	|		CityLedgerPayments.VATRate,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		SUM(CityLedgerPayments.Sum),
	|		SUM(CityLedgerPayments.Sum) - SUM(CityLedgerPayments.VATSum),
	|		SUM(CityLedgerPayments.VATSum)
	|	FROM
	|		AccumulationRegister.Accounts AS CityLedgerPayments
	|			INNER JOIN Invoices AS Invoices
	|			ON CityLedgerPayments.Recorder = Invoices.Invoice
	|	WHERE
	|		&qShowPayments
	|		AND (CityLedgerPayments.Folio.GuestGroup = &qGuestGroup
	|				OR &qIsEmptyGuestGroup)
	|		AND (CityLedgerPayments.Hotel IN HIERARCHY (&qHotel)
	|				OR &qIsEmptyHotel)
	|	
	|	GROUP BY
	|		BEGINOFPERIOD(CityLedgerPayments.Period, DAY),
	|		CityLedgerPayments.Hotel,
	|		CityLedgerPayments.Recorder,
	|		CityLedgerPayments.ParentDoc,
	|		CityLedgerPayments.FolioCurrency,
	|		CityLedgerPayments.Folio.Company,
	|		CityLedgerPayments.Folio.Customer,
	|		CityLedgerPayments.Folio.Contract,
	|		CityLedgerPayments.Folio.GuestGroup,
	|		CityLedgerPayments.Folio,
	|		CityLedgerPayments.PaymentMethod,
	|		CityLedgerPayments.VATRate,
	|		CityLedgerPayments.Folio.ParentDoc,
	|		BEGINOFPERIOD(CityLedgerPayments.Period, DAY)) AS InvoiceTransactions
	|{WHERE
	|	InvoiceTransactions.TransactionType AS TransactionType,
	|	InvoiceTransactions.Period,
	|	InvoiceTransactions.AccountingDate,
	|	InvoiceTransactions.Settlement.*,
	|	InvoiceTransactions.Hotel.*,
	|	InvoiceTransactions.Company.*,
	|	InvoiceTransactions.AccountingCurrency.*,
	|	InvoiceTransactions.AccountingCustomer.*,
	|	InvoiceTransactions.AccountingContract.*,
	|	InvoiceTransactions.ParentDoc.*,
	|	InvoiceTransactions.HotelProduct.*,
	|	InvoiceTransactions.GuestGroup.*,
	|	InvoiceTransactions.Folio.*,
	|	InvoiceTransactions.Folio.Room.* AS FolioRoom,
	|	InvoiceTransactions.Folio.Client.* AS FolioClient,
	|	InvoiceTransactions.Folio.DateTimeFrom AS FolioDateTimeFrom,
	|	InvoiceTransactions.Folio.DateTimeTo AS FolioDateTimeTo,
	|	InvoiceTransactions.Service.*,
	|	InvoiceTransactions.VATRate.*,
	|	InvoiceTransactions.CommissionSum AS CommissionSum,
	|	InvoiceTransactions.Sum AS Sum,
	|	InvoiceTransactions.VATSum AS VATSum,
	|	InvoiceTransactions.Quantity AS Quantity}
	|
	|ORDER BY
	|	Period,
	|	Company,
	|	AccountingCustomer,
	|	GuestGroup,
	|	Folio,
	|	Service
	|{ORDER BY
	|	Period,
	|	InvoiceTransactions.AccountingDate,
	|	InvoiceTransactions.TransactionType AS TransactionType,
	|	InvoiceTransactions.Settlement.*,
	|	InvoiceTransactions.Hotel.*,
	|	Company.*,
	|	InvoiceTransactions.AccountingCurrency.*,
	|	AccountingCustomer.*,
	|	InvoiceTransactions.AccountingContract.*,
	|	InvoiceTransactions.ParentDoc.*,
	|	InvoiceTransactions.HotelProduct.*,
	|	GuestGroup.*,
	|	Folio.*,
	|	FolioClient.*,
	|	FolioRoom.*,
	|	FolioDateTimeFrom,
	|	FolioDateTimeTo,
	|	Service.*,
	|	InvoiceTransactions.VATRate.*,
	|	CommissionSum,
	|	Sum,
	|	SumWithoutVAT,
	|	VATSum,
	|	Quantity,
	|	PaymentSum,
	|	PaymentSumWithoutVAT,
	|	PaymentVATSum}
	|TOTALS
	|	SUM(CommissionSum),
	|	SUM(Sum),
	|	SUM(SumWithoutVAT),
	|	SUM(VATSum),
	|	SUM(Quantity),
	|	SUM(PaymentSum),
	|	SUM(PaymentSumWithoutVAT),
	|	SUM(PaymentVATSum),
	|	SUM(Sum) - SUM(PaymentSum) AS PaymentsDiff
	|BY
	|	OVERALL,
	|	Period,
	|	Company HIERARCHY,
	|	AccountingCustomer HIERARCHY,
	|	GuestGroup,
	|	Folio
	|{TOTALS BY
	|	Period,
	|	InvoiceTransactions.AccountingDate,
	|	InvoiceTransactions.TransactionType AS TransactionType,
	|	InvoiceTransactions.Settlement.*,
	|	InvoiceTransactions.Hotel.*,
	|	InvoiceTransactions.ParentDoc.*,
	|	InvoiceTransactions.HotelProduct.*,
	|	Company.*,
	|	InvoiceTransactions.AccountingCurrency.*,
	|	AccountingCustomer.*,
	|	InvoiceTransactions.AccountingContract.*,
	|	GuestGroup.*,
	|	Folio.*,
	|	FolioRoom.*,
	|	FolioClient.*,
	|	Service.*,
	|	InvoiceTransactions.VATRate.*}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Accounts receivable';RU='Бухгалтерская реализация услуг';de='rechnerische Realisation von Dienstleistungen'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
Function pmIsResource(pName) Export
	If pName = "Sum" 
	   Or pName = "CommissionSum" 
	   Or pName = "VATSum" 
	   Or pName = "Quantity" 
	   Or pName = "PaymentsDiff" Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // pmIsResource

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
