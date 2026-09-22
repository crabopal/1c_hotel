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
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetReportParametersPresentation() Export
	vParamPresentation = "";
	If ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Оперативный баланс на '; en = 'Operative balance on '; de = 'Balance auf '") + 
		                     Format(PeriodTo, "DF='dd.MM.yyyy HH:mm'") + 
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
	If ValueIsFilled(Currency) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Валюта '; en = 'Currency '; de = 'Währung '") + 
							 TrimAll(Currency.Description) + 
							 ";" + Chars.LF;
	EndIf;					 
	If ValueIsFilled(GuestGroupCheckInPeriodFrom) Or ValueIsFilled(GuestGroupCheckInPeriodTo) Then
		If Not ValueIsFilled(GuestGroupCheckInPeriodFrom) And ValueIsFilled(GuestGroupCheckInPeriodTo) Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Отбор групп с датой и временем заезда в периоде по '; en = 'Choose groups with check-in date in period to '; de = 'Wählen Sie Gruppen mit check-in-Datum zu '") + 
			                     Format(GuestGroupCheckInPeriodTo, "DF='dd.MM.yyyy HH:mm'") + 
			                     ";" + Chars.LF;
		ElsIf ValueIsFilled(GuestGroupCheckInPeriodFrom) And Not ValueIsFilled(GuestGroupCheckInPeriodTo) Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Отбор групп с датой и временем заезда в периоде с '; en = 'Choose groups with check-in date in period from '; de = 'Wählen Sie Gruppen mit check-in-Datum von '") + 
			                     Format(GuestGroupCheckInPeriodFrom, "DF='dd.MM.yyyy HH:mm'") + 
			                     ";" + Chars.LF;
		ElsIf GuestGroupCheckInPeriodFrom = GuestGroupCheckInPeriodTo Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Отбор групп с датой и временем заезда равным '; en = 'Choose groups with check-in date equal '; de = 'Wählen Sie Gruppen mit check-in-Datum gleich '") + 
			                     Format(GuestGroupCheckInPeriodFrom, "DF='dd.MM.yyyy HH:mm'") + 
			                     ";" + Chars.LF;
		ElsIf GuestGroupCheckInPeriodFrom < GuestGroupCheckInPeriodTo Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Отбор групп с датой и временем заезда в периоде '; en = 'Choose groups with check-in date in period '; de = 'Wählen Sie Gruppen mit check-in-Datum im Periode '") + PeriodPresentation(GuestGroupCheckInPeriodFrom, GuestGroupCheckInPeriodTo, cmLocalizationCode()) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Guest group check-in period is wrong!';ru='Неправильно задан период отбора групп по дате и времени заезда!';de='Auswahlzeitraum der Gruppen nach Datum und Uhrzeit wurde falsch eingegeben!'") + 
			                     ";" + Chars.LF;
		EndIf;
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
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qIsEmptyHotel", Not ValueIsFilled(Hotel));
	ReportBuilder.Parameters.Insert("qPeriodFrom", '00010101');
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qForecastPeriodFrom", tcOnServer.GetForecastStartDate(Hotel));
	ReportBuilder.Parameters.Insert("qForecastPeriodTo", ?(ValueIsFilled(PeriodTo), PeriodTo, '39991231235959'));
	ReportBuilder.Parameters.Insert("qPaymentPeriodTo", ?(ValueIsFilled(PeriodTo), PeriodTo, '39991231235959'));
	ReportBuilder.Parameters.Insert("qGuestGroupCheckInPeriodFrom", GuestGroupCheckInPeriodFrom);
	ReportBuilder.Parameters.Insert("qGuestGroupCheckInPeriodFromIsEmpty", Not ValueIsFilled(GuestGroupCheckInPeriodFrom));
	ReportBuilder.Parameters.Insert("qGuestGroupCheckInPeriodTo", GuestGroupCheckInPeriodTo);
	ReportBuilder.Parameters.Insert("qGuestGroupCheckInPeriodToIsEmpty", Not ValueIsFilled(GuestGroupCheckInPeriodTo));
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
	ReportBuilder.Parameters.Insert("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	ReportBuilder.Parameters.Insert("qIndividualsCustomer", ?(ValueIsFilled(Hotel), Hotel.IndividualsCustomer, Catalogs.Customers.EmptyRef()));
	ReportBuilder.Parameters.Insert("qIndividualsContract", ?(ValueIsFilled(Hotel), Hotel.IndividualsContract, Catalogs.Contracts.EmptyRef()));
	If ValueIsFilled(Hotel) And ValueIsFilled(Customer) And Customer = Hotel.IndividualsCustomer Then
		ReportBuilder.Parameters.Insert("qIndividualsCustomerIsChoosen", True);
	Else
		ReportBuilder.Parameters.Insert("qIndividualsCustomerIsChoosen", False);
	EndIf;
	
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
	"SELECT
	|	OperationalAccounts.Company AS Company,
	|	OperationalAccounts.Currency AS Currency,
	|	OperationalAccounts.Customer AS Customer,
	|	OperationalAccounts.Contract AS Contract,
	|	OperationalAccounts.Hotel AS Hotel,
	|	OperationalAccounts.GuestGroup AS GuestGroup,
	|	SUM(OperationalAccounts.AccountingBalance) AS AccountingBalance,
	|	SUM(OperationalAccounts.CurrentSum) AS CurrentSum,
	|	SUM(OperationalAccounts.ForecastSum) AS ForecastSum,
	|	SUM(OperationalAccounts.AccountingBalance) + SUM(OperationalAccounts.CurrentSum) + SUM(OperationalAccounts.ForecastSum) AS SumBalance
	|{SELECT
	|	Company.* AS Company,
	|	Currency.* AS Currency,
	|	Customer.* AS Customer,
	|	Contract.* AS Contract,
	|	Hotel.* AS Hotel,
	|	GuestGroup.* AS GuestGroup,
	|	CustomerLastPayment.LastPaymentDate AS LastPaymentDate,
	|	AccountingBalance,
	|	CurrentSum,
	|	ForecastSum,
	|	SumBalance}
	|FROM
	|	(SELECT
	|		CustomerAccounts.Hotel AS Hotel,
	|		CustomerAccounts.Company AS Company,
	|		CustomerAccounts.AccountingCurrency AS Currency,
	|		CustomerAccounts.AccountingCustomer AS Customer,
	|		CustomerAccounts.AccountingContract AS Contract,
	|		CustomerAccounts.GuestGroup AS GuestGroup,
	|		CustomerAccounts.SumBalance AS AccountingBalance,
	|		0 AS CurrentSum,
	|		0 AS ForecastSum
	|	FROM
	|		AccumulationRegister.CustomerAccounts.Balance(
	|				&qPeriodTo,
	|				(Hotel IN HIERARCHY (&qHotel)
	|					OR &qIsEmptyHotel)
	|					AND (Company IN HIERARCHY (&qCompany)
	|						OR &qIsEmptyCompany)
	|					AND (AccountingCustomer IN HIERARCHY (&qCustomer)
	|						OR &qIsEmptyCustomer)
	|					AND (AccountingContract = &qContract
	|						OR &qIsEmptyContract)
	|					AND (GuestGroup = &qGuestGroup
	|						OR &qIsEmptyGuestGroup)
	|					AND (AccountingCurrency = &qCurrency
	|						OR &qIsEmptyCurrency)
	|					AND (&qGuestGroupCheckInPeriodFromIsEmpty
	|						OR NOT &qGuestGroupCheckInPeriodFromIsEmpty
	|							AND GuestGroup.CheckInDate >= &qGuestGroupCheckInPeriodFrom)
	|					AND (&qGuestGroupCheckInPeriodToIsEmpty
	|						OR NOT &qGuestGroupCheckInPeriodToIsEmpty
	|							AND GuestGroup.CheckInDate <= &qGuestGroupCheckInPeriodTo)) AS CustomerAccounts
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CurrentAccountsReceivable.Hotel,
	|		CurrentAccountsReceivable.Company,
	|		CurrentAccountsReceivable.FolioCurrency,
	|		CASE
	|			WHEN CurrentAccountsReceivable.Customer = &qEmptyCustomer
	|				THEN &qIndividualsCustomer
	|			ELSE CurrentAccountsReceivable.Customer
	|		END,
	|		CASE
	|			WHEN CurrentAccountsReceivable.Customer = &qEmptyCustomer
	|				THEN &qIndividualsContract
	|			ELSE CurrentAccountsReceivable.Contract
	|		END,
	|		CurrentAccountsReceivable.GuestGroup,
	|		0,
	|		CASE
	|			WHEN ISNULL(CurrentAccountsReceivable.Customer.DoNotPostCommission, FALSE)
	|				THEN CurrentAccountsReceivable.SumBalance
	|			ELSE CurrentAccountsReceivable.SumBalance - CurrentAccountsReceivable.CommissionSumBalance
	|		END,
	|		0
	|	FROM
	|		AccumulationRegister.CurrentAccountsReceivable.Balance(
	|				&qPeriodTo,
	|				(Hotel IN HIERARCHY (&qHotel)
	|					OR &qIsEmptyHotel)
	|					AND (Company IN HIERARCHY (&qCompany)
	|						OR &qIsEmptyCompany)
	|					AND (Customer IN HIERARCHY (&qCustomer)
	|						OR &qIsEmptyCustomer
	|						OR &qIndividualsCustomerIsChoosen
	|							AND Customer = &qEmptyCustomer)
	|					AND (Contract = &qContract
	|						OR &qIsEmptyContract)
	|					AND (GuestGroup = &qGuestGroup
	|						OR &qIsEmptyGuestGroup)
	|					AND (FolioCurrency = &qCurrency
	|						OR &qIsEmptyCurrency)
	|					AND (&qGuestGroupCheckInPeriodFromIsEmpty
	|						OR NOT &qGuestGroupCheckInPeriodFromIsEmpty
	|							AND GuestGroup.CheckInDate >= &qGuestGroupCheckInPeriodFrom)
	|					AND (&qGuestGroupCheckInPeriodToIsEmpty
	|						OR NOT &qGuestGroupCheckInPeriodToIsEmpty
	|							AND GuestGroup.CheckInDate <= &qGuestGroupCheckInPeriodTo)) AS CurrentAccountsReceivable
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CustomerSalesForecast.Hotel,
	|		CustomerSalesForecast.Company,
	|		CustomerSalesForecast.ReportingCurrency,
	|		CASE
	|			WHEN CustomerSalesForecast.Customer = &qEmptyCustomer
	|				THEN &qIndividualsCustomer
	|			ELSE CustomerSalesForecast.Customer
	|		END,
	|		CASE
	|			WHEN CustomerSalesForecast.Customer = &qEmptyCustomer
	|				THEN &qIndividualsContract
	|			ELSE CustomerSalesForecast.Contract
	|		END,
	|		CustomerSalesForecast.GuestGroup,
	|		0,
	|		0,
	|		CASE
	|			WHEN ISNULL(CustomerSalesForecast.Customer.DoNotPostCommission, FALSE)
	|				THEN CustomerSalesForecast.SalesTurnover
	|			ELSE CustomerSalesForecast.SalesTurnover - CustomerSalesForecast.CommissionSumTurnover
	|		END
	|	FROM
	|		AccumulationRegister.SalesForecast.Turnovers(
	|				&qForecastPeriodFrom,
	|				&qForecastPeriodTo,
	|				Period,
	|				(Hotel IN HIERARCHY (&qHotel)
	|					OR &qIsEmptyHotel)
	|					AND (Company IN HIERARCHY (&qCompany)
	|						OR &qIsEmptyCompany)
	|					AND (Customer IN HIERARCHY (&qCustomer)
	|						OR &qIsEmptyCustomer
	|						OR &qIndividualsCustomerIsChoosen
	|							AND Customer = &qEmptyCustomer)
	|					AND (Contract = &qContract
	|						OR &qIsEmptyContract)
	|					AND (GuestGroup = &qGuestGroup
	|						OR &qIsEmptyGuestGroup)
	|					AND (ReportingCurrency = &qCurrency
	|						OR &qIsEmptyCurrency)
	|					AND (&qGuestGroupCheckInPeriodFromIsEmpty
	|						OR NOT &qGuestGroupCheckInPeriodFromIsEmpty
	|							AND GuestGroup.CheckInDate >= &qGuestGroupCheckInPeriodFrom)
	|					AND (&qGuestGroupCheckInPeriodToIsEmpty
	|						OR NOT &qGuestGroupCheckInPeriodToIsEmpty
	|							AND GuestGroup.CheckInDate <= &qGuestGroupCheckInPeriodTo)) AS CustomerSalesForecast) AS OperationalAccounts
	|		LEFT JOIN (SELECT
	|			CustomerPayments.AccountingCurrency AS Currency,
	|			CustomerPayments.AccountingCustomer AS Customer,
	|			CustomerPayments.AccountingContract AS Contract,
	|			CustomerPayments.Hotel AS Hotel,
	|			CustomerPayments.Company AS Company,
	|			CustomerPayments.GuestGroup AS GuestGroup,
	|			MAX(BEGINOFPERIOD(CustomerPayments.Period, DAY)) AS LastPaymentDate
	|		FROM
	|			AccumulationRegister.CustomerAccounts AS CustomerPayments
	|		WHERE
	|			CustomerPayments.RecordType = VALUE(AccumulationRecordType.Expense)
	|			AND CustomerPayments.Period < &qPaymentPeriodTo
	|			AND (CustomerPayments.Hotel IN HIERARCHY (&qHotel)
	|					OR &qIsEmptyHotel)
	|			AND (CustomerPayments.Company IN HIERARCHY (&qCompany)
	|					OR &qIsEmptyCompany)
	|			AND (CustomerPayments.AccountingCustomer IN HIERARCHY (&qCustomer)
	|					OR &qIsEmptyCustomer)
	|			AND (CustomerPayments.AccountingContract = &qContract
	|					OR &qIsEmptyContract)
	|			AND (CustomerPayments.GuestGroup = &qGuestGroup
	|					OR &qIsEmptyGuestGroup)
	|			AND (CustomerPayments.AccountingCurrency = &qCurrency
	|					OR &qIsEmptyCurrency)
	|			AND (&qGuestGroupCheckInPeriodFromIsEmpty
	|					OR NOT &qGuestGroupCheckInPeriodFromIsEmpty
	|						AND CustomerPayments.GuestGroup.CheckInDate >= &qGuestGroupCheckInPeriodFrom)
	|			AND (&qGuestGroupCheckInPeriodToIsEmpty
	|					OR NOT &qGuestGroupCheckInPeriodToIsEmpty
	|						AND CustomerPayments.GuestGroup.CheckInDate <= &qGuestGroupCheckInPeriodTo)
	|		
	|		GROUP BY
	|			CustomerPayments.AccountingCurrency,
	|			CustomerPayments.AccountingCustomer,
	|			CustomerPayments.AccountingContract,
	|			CustomerPayments.Hotel,
	|			CustomerPayments.Company,
	|			CustomerPayments.GuestGroup) AS CustomerLastPayment
	|		ON OperationalAccounts.Currency = CustomerLastPayment.Currency
	|			AND OperationalAccounts.Customer = CustomerLastPayment.Customer
	|			AND OperationalAccounts.Contract = CustomerLastPayment.Contract
	|			AND OperationalAccounts.Hotel = CustomerLastPayment.Hotel
	|			AND OperationalAccounts.Company = CustomerLastPayment.Company
	|			AND OperationalAccounts.GuestGroup = CustomerLastPayment.GuestGroup
	|{WHERE
	|	OperationalAccounts.Hotel.*,
	|	OperationalAccounts.Company.*,
	|	OperationalAccounts.Currency.*,
	|	OperationalAccounts.Customer.*,
	|	OperationalAccounts.Contract.*,
	|	OperationalAccounts.GuestGroup.*,
	|	CustomerLastPayment.LastPaymentDate AS LastPaymentDate,
	|	OperationalAccounts.AccountingBalance,
	|	OperationalAccounts.CurrentSum,
	|	OperationalAccounts.ForecastSum,
	|	(SUM(OperationalAccounts.AccountingBalance) + SUM(OperationalAccounts.CurrentSum) + SUM(OperationalAccounts.ForecastSum)) AS SumBalance}
	|
	|GROUP BY
	|	OperationalAccounts.Company,
	|	OperationalAccounts.Currency,
	|	OperationalAccounts.Customer,
	|	OperationalAccounts.Contract,
	|	OperationalAccounts.Hotel,
	|	OperationalAccounts.GuestGroup
	|
	|ORDER BY
	|	Company,
	|	Currency,
	|	Customer,
	|	Contract,
	|	GuestGroup
	|{ORDER BY
	|	Company.*,
	|	Currency.*,
	|	Customer.*,
	|	Contract.*,
	|	Hotel.*,
	|	GuestGroup.*,
	|	CustomerLastPayment.LastPaymentDate AS LastPaymentDate,
	|	AccountingBalance,
	|	CurrentSum,
	|	ForecastSum,
	|	SumBalance}
	|TOTALS
	|	SUM(AccountingBalance),
	|	SUM(CurrentSum),
	|	SUM(ForecastSum),
	|	SUM(SumBalance)
	|BY
	|	OVERALL,
	|	Company HIERARCHY,
	|	Currency,
	|	Customer HIERARCHY,
	|	Contract,
	|	Hotel HIERARCHY,
	|	GuestGroup
	|{TOTALS BY
	|	Company.*,
	|	Currency.*,
	|	Customer.*,
	|	Contract.*,
	|	Hotel.*,
	|	GuestGroup.*,
	|	CustomerLastPayment.LastPaymentDate AS LastPaymentDate}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Operational customer accounts balance';RU='Оперативный баланс взаиморасчетов с контрагентами';de='Operative Bilanz der gegenseitigen Verrechnung mit  den Vertragspartnern'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
Function pmIsResource(pName) Export
	If pName = "AccountingBalance" Or
	   pName = "CurrentSum" Or 
	   pName = "SumBalance" Or 
	   pName = "ForecastSum" Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // pmIsResource

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
