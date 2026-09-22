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
	ReportBuilder.Parameters.Insert("qSplitPaymentsAndServices", SplitPaymentsAndServices);
	
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
	|			PERIOD,
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
	|SELECT
	|	CASE
	|		WHEN &qSplitPaymentsAndServices
	|			THEN &qPayments
	|		ELSE NULL
	|	END AS TransactionType,
	|	BEGINOFPERIOD(CustomerAccounts.Period, DAY) AS Period,
	|	CustomerAccounts.AccountingDate AS AccountingDate,
	|	CustomerAccounts.Hotel AS Hotel,
	|	CustomerAccounts.Recorder AS Settlement,
	|	CustomerAccounts.Folio.ParentDoc AS ParentDoc,
	|	ISNULL(CustomerAccounts.ParentDoc.HotelProduct, VALUE(Catalog.HotelProducts.EmptyRef)) AS HotelProduct,
	|	CustomerAccounts.AccountingCurrency AS AccountingCurrency,
	|	CustomerAccounts.Company AS Company,
	|	CustomerAccounts.AccountingCustomer AS AccountingCustomer,
	|	CustomerAccounts.AccountingContract AS AccountingContract,
	|	CustomerAccounts.GuestGroup AS GuestGroup,
	|	CustomerAccounts.Folio AS Folio,
	|	CustomerAccounts.VATRate AS VATRate,
	|	CustomerAccounts.Service AS Service,
	|	CustomerAccounts.PaymentMethod AS PaymentMethod,
	|	0 AS CommissionSum,
	|	SUM(CASE
	|			WHEN &qSplitPaymentsAndServices
	|				THEN 0
	|			ELSE CustomerAccounts.Sum
	|		END) AS Sum,
	|	SUM(CASE
	|			WHEN &qSplitPaymentsAndServices
	|				THEN 0
	|			ELSE CustomerAccounts.Sum - CustomerAccounts.VATSum
	|		END) AS SumWithoutVAT,
	|	SUM(CASE
	|			WHEN &qSplitPaymentsAndServices
	|				THEN 0
	|			ELSE CustomerAccounts.VATSum
	|		END) AS VATSum,
	|	SUM(CASE
	|			WHEN &qSplitPaymentsAndServices
	|				THEN 0
	|			ELSE CustomerAccounts.Quantity
	|		END) AS Quantity,
	|	SUM(CASE
	|			WHEN CustomerAccounts.PaymentMethod = VALUE(Catalog.PaymentMethods.Settlement)
	|				THEN 0
	|			ELSE CustomerAccounts.Sum
	|		END) AS PaymentSum,
	|	SUM(CASE
	|			WHEN CustomerAccounts.PaymentMethod = VALUE(Catalog.PaymentMethods.Settlement)
	|				THEN 0
	|			ELSE CustomerAccounts.Sum - CustomerAccounts.VATSum
	|		END) AS PaymentSumWithoutVAT,
	|	SUM(CASE
	|			WHEN CustomerAccounts.PaymentMethod = VALUE(Catalog.PaymentMethods.Settlement)
	|				THEN 0
	|			ELSE CustomerAccounts.VATSum
	|		END) AS PaymentVATSum
	|INTO PaymentsClearing
	|FROM
	|	AccumulationRegister.CustomerAccounts AS CustomerAccounts
	|		INNER JOIN Invoices AS Invoices
	|		ON CustomerAccounts.Recorder = Invoices.Invoice
	|WHERE
	|	&qShowPayments
	|	AND (CustomerAccounts.GuestGroup = &qGuestGroup
	|			OR &qIsEmptyGuestGroup)
	|	AND CustomerAccounts.PaymentMethod <> VALUE(Catalog.PaymentMethods.AdvanceSettlement)
	|	AND (CustomerAccounts.Hotel IN HIERARCHY (&qHotel)
	|			OR &qIsEmptyHotel)
	|	AND (CustomerAccounts.Price <> 0
	|			OR CustomerAccounts.Quantity <> 0)
	|	AND (CustomerAccounts.Service IN (&qServicesList)
	|			OR NOT &qUseServicesList)
	|
	|GROUP BY
	|	BEGINOFPERIOD(CustomerAccounts.Period, DAY),
	|	CustomerAccounts.AccountingDate,
	|	CustomerAccounts.Hotel,
	|	CustomerAccounts.Recorder,
	|	CustomerAccounts.Folio.ParentDoc,
	|	ISNULL(CustomerAccounts.ParentDoc.HotelProduct, VALUE(Catalog.HotelProducts.EmptyRef)),
	|	CustomerAccounts.AccountingCurrency,
	|	CustomerAccounts.Company,
	|	CustomerAccounts.AccountingCustomer,
	|	CustomerAccounts.AccountingContract,
	|	CustomerAccounts.GuestGroup,
	|	CustomerAccounts.Folio,
	|	CustomerAccounts.VATRate,
	|	CustomerAccounts.Service,
	|	CustomerAccounts.PaymentMethod
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN &qSplitPaymentsAndServices
	|			THEN &qServices
	|		ELSE NULL
	|	END AS TransactionType,
	|	BEGINOFPERIOD(AccountsReceivableTurnovers.Period, DAY) AS Period,
	|	AccountsReceivableTurnovers.AccountingDate AS AccountingDate,
	|	AccountsReceivableTurnovers.Hotel AS Hotel,
	|	AccountsReceivableTurnovers.Settlement AS Settlement,
	|	AccountsReceivableTurnovers.Folio.ParentDoc AS ParentDoc,
	|	AccountsReceivableTurnovers.HotelProduct AS HotelProduct,
	|	AccountsReceivableTurnovers.AccountingCurrency AS AccountingCurrency,
	|	AccountsReceivableTurnovers.Company AS Company,
	|	AccountsReceivableTurnovers.AccountingCustomer AS AccountingCustomer,
	|	AccountsReceivableTurnovers.AccountingContract AS AccountingContract,
	|	AccountsReceivableTurnovers.GuestGroup AS GuestGroup,
	|	AccountsReceivableTurnovers.Folio AS Folio,
	|	AccountsReceivableTurnovers.VATRate AS VATRate,
	|	AccountsReceivableTurnovers.Service AS Service,
	|	VALUE(Catalog.PaymentMethods.Settlement) AS PaymentMethod,
	|	AccountsReceivableTurnovers.CommissionSumTurnover AS CommissionSum,
	|	AccountsReceivableTurnovers.SumTurnover AS Sum,
	|	AccountsReceivableTurnovers.SumTurnover - AccountsReceivableTurnovers.VATSumTurnover AS SumWithoutVAT,
	|	AccountsReceivableTurnovers.VATSumTurnover AS VATSum,
	|	AccountsReceivableTurnovers.QuantityTurnover AS Quantity,
	|	0 AS PaymentSum,
	|	0 AS PaymentSumWithoutVAT,
	|	0 AS PaymentVATSum
	|INTO AccountsReceivable
	|FROM
	|	AccumulationRegister.AccountsReceivable.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			(NOT &qShowPayments
	|				OR &qSplitPaymentsAndServices)
	|				AND Settlement IN
	|					(SELECT
	|						Invoices.Invoice
	|					FROM
	|						Invoices AS Invoices)
	|				AND (GuestGroup = &qGuestGroup
	|					OR &qIsEmptyGuestGroup)
	|				AND (Hotel IN HIERARCHY (&qHotel)
	|					OR &qIsEmptyHotel)
	|				AND (Service IN (&qServicesList)
	|					OR NOT &qUseServicesList)) AS AccountsReceivableTurnovers
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
	|	InvoiceTransactions.PaymentVATSum AS PaymentVATSum
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
	|	InvoiceTransactions.PaymentMethod.* AS PaymentMethod,
	|	InvoiceTransactions.VATRate.*,
	|	CommissionSum,
	|	Sum,
	|	SumWithoutVAT,
	|	VATSum,
	|	Quantity,
	|	PaymentSum,
	|	PaymentSumWithoutVAT,
	|	PaymentVATSum}
	|FROM
	|	(SELECT
	|		AccountsReceivable.TransactionType AS TransactionType,
	|		AccountsReceivable.Period AS Period,
	|		AccountsReceivable.AccountingDate AS AccountingDate,
	|		AccountsReceivable.Hotel AS Hotel,
	|		AccountsReceivable.Settlement AS Settlement,
	|		AccountsReceivable.ParentDoc AS ParentDoc,
	|		AccountsReceivable.HotelProduct AS HotelProduct,
	|		AccountsReceivable.AccountingCurrency AS AccountingCurrency,
	|		AccountsReceivable.Company AS Company,
	|		AccountsReceivable.AccountingCustomer AS AccountingCustomer,
	|		AccountsReceivable.AccountingContract AS AccountingContract,
	|		AccountsReceivable.GuestGroup AS GuestGroup,
	|		AccountsReceivable.Folio AS Folio,
	|		AccountsReceivable.VATRate AS VATRate,
	|		AccountsReceivable.Service AS Service,
	|		AccountsReceivable.PaymentMethod AS PaymentMethod,
	|		AccountsReceivable.CommissionSum AS CommissionSum,
	|		AccountsReceivable.Sum AS Sum,
	|		AccountsReceivable.SumWithoutVAT AS SumWithoutVAT,
	|		AccountsReceivable.VATSum AS VATSum,
	|		AccountsReceivable.Quantity AS Quantity,
	|		AccountsReceivable.PaymentSum AS PaymentSum,
	|		AccountsReceivable.PaymentSumWithoutVAT AS PaymentSumWithoutVAT,
	|		AccountsReceivable.PaymentVATSum AS PaymentVATSum
	|	FROM
	|		AccountsReceivable AS AccountsReceivable
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		PaymentsClearing.TransactionType,
	|		PaymentsClearing.Period,
	|		PaymentsClearing.AccountingDate,
	|		PaymentsClearing.Hotel,
	|		PaymentsClearing.Settlement,
	|		PaymentsClearing.ParentDoc,
	|		PaymentsClearing.HotelProduct,
	|		PaymentsClearing.AccountingCurrency,
	|		PaymentsClearing.Company,
	|		PaymentsClearing.AccountingCustomer,
	|		PaymentsClearing.AccountingContract,
	|		PaymentsClearing.GuestGroup,
	|		PaymentsClearing.Folio,
	|		PaymentsClearing.VATRate,
	|		PaymentsClearing.Service,
	|		PaymentsClearing.PaymentMethod,
	|		PaymentsClearing.CommissionSum,
	|		PaymentsClearing.Sum,
	|		PaymentsClearing.SumWithoutVAT,
	|		PaymentsClearing.VATSum,
	|		PaymentsClearing.Quantity,
	|		PaymentsClearing.PaymentSum,
	|		PaymentsClearing.PaymentSumWithoutVAT,
	|		PaymentsClearing.PaymentVATSum
	|	FROM
	|		PaymentsClearing AS PaymentsClearing) AS InvoiceTransactions
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
	|	InvoiceTransactions.PaymentMethod.* AS PaymentMethod,
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
	|	InvoiceTransactions.TransactionType AS TransactionType,
	|	Period,
	|	InvoiceTransactions.AccountingDate,
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
	|	InvoiceTransactions.PaymentMethod.* AS PaymentMethod,
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
	|	SUM(PaymentVATSum)
	|BY
	|	OVERALL,
	|	Period,
	|	Company HIERARCHY,
	|	AccountingCustomer HIERARCHY,
	|	GuestGroup,
	|	Folio
	|{TOTALS BY
	|	InvoiceTransactions.TransactionType AS TransactionType,
	|	Period,
	|	InvoiceTransactions.AccountingDate,
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
	|	InvoiceTransactions.PaymentMethod.* AS PaymentMethod,
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
	   Or pName = "Quantity" Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // pmIsResource

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
