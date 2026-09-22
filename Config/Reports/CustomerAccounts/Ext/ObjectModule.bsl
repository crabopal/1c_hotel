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
			If Not ShowCurrentAccountsReceivable And Hotel.ShowCurrentAccountsReceivable Then
				ShowCurrentAccountsReceivable = Hotel.ShowCurrentAccountsReceivable;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetReportParametersPresentation() Export
	vParamPresentation = "";
	If Not ValueIsFilled(PeriodFrom) And Not ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru='Период отчета не установлен'; en='Report period is not set'; de='Berichtszeitraum nicht festgelegt'") + 
		                     ";" + Chars.LF;
	ElsIf ValueIsFilled(PeriodFrom) And Not ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период c '; en = 'Period from '; de = 'Periode von '") + 
		                     Format(PeriodFrom, "DF=dd.MM.yyyy") + 
		                     ";" + Chars.LF;
	ElsIf Not ValueIsFilled(PeriodFrom) And ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период по '; en = 'Period to '; de = 'Period nach '") + 
		                     Format(PeriodTo, "DF=dd.MM.yyyy") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom = PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период на '; en = 'Period on '; de = 'Datum '") + 
		                     Format(PeriodFrom, "DF=dd.MM.yyyy") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom < PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период '; en = 'Period '; de = 'Periode '") + PeriodPresentation(PeriodFrom, PeriodTo, cmLocalizationCode()) + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("ru='Неправильно задан период!'; en='Period is wrong!'; de='Der Zeitraum wurde falsch eingetragen!'") + 
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
		vParamPresentation = vParamPresentation + NStr("ru = 'Группа гостей '; en = 'Guest group '; de = 'Guest group '") + 
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
			vParamPresentation = vParamPresentation + NStr("ru = 'Отбор групп с датой и временем заезда в периоде по '; en = 'Choose groups with check-in date in period to '; de = 'Wählen Sie Gruppen mit check-in-Datum im Zeitraum bis '") + 
			                     Format(GuestGroupCheckInPeriodTo, "DF=dd.MM.yyyy") + 
			                     ";" + Chars.LF;
		ElsIf ValueIsFilled(GuestGroupCheckInPeriodFrom) And Not ValueIsFilled(GuestGroupCheckInPeriodTo) Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Отбор групп с датой и временем заезда в периоде с '; en = 'Choose groups with check-in date in period from '; de = 'Wählen Sie Gruppen mit check-in-Datum im Zeitraum von '") + 
			                     Format(GuestGroupCheckInPeriodFrom, "DF=dd.MM.yyyy") + 
			                     ";" + Chars.LF;
		ElsIf GuestGroupCheckInPeriodFrom = GuestGroupCheckInPeriodTo Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Отбор групп с датой и временем заезда равным '; en = 'Choose groups with check-in date equal '; de = 'Wählen Sie Gruppen mit check-in-Datum im Zeitraum gleich '") + 
			                     Format(GuestGroupCheckInPeriodFrom, "DF=dd.MM.yyyy") + 
			                     ";" + Chars.LF;
		ElsIf GuestGroupCheckInPeriodFrom < GuestGroupCheckInPeriodTo Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Отбор групп с датой и временем заезда в периоде '; en = 'Choose groups with check-in date in period '; de = 'Wählen Sie Gruppen mit check-in-Datum im Zeitraum '") + PeriodPresentation(GuestGroupCheckInPeriodFrom, GuestGroupCheckInPeriodTo, cmLocalizationCode()) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru='Неправильно задан период отбора групп по дате и времени заезда!'; en='Guest group check-in period is wrong!'; de='Auswahlzeitraum der Gruppen nach Datum und Uhrzeit wurde falsch eingegeben!'") + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(GuestGroupCreateDatePeriodFrom) Or ValueIsFilled(GuestGroupCreateDatePeriodTo) Then
		If Not ValueIsFilled(GuestGroupCreateDatePeriodFrom) And ValueIsFilled(GuestGroupCreateDatePeriodTo) Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Отбор групп с датой и временем создания в периоде по '; en = 'Choose groups with create date in period to '; de = 'Wählen Sie Gruppen mit Erstellungsdatum in Periode bis '") + 
			                     Format(GuestGroupCreateDatePeriodTo, "DF=dd.MM.yyyy") + 
			                     ";" + Chars.LF;
		ElsIf ValueIsFilled(GuestGroupCreateDatePeriodFrom) And Not ValueIsFilled(GuestGroupCreateDatePeriodTo) Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Отбор групп с датой и временем создания в периоде с '; en = 'Choose groups with create date in period from '; de = 'Wählen Sie Gruppen mit Erstellungsdatum in Periode aus '") + 
			                     Format(GuestGroupCreateDatePeriodFrom, "DF=dd.MM.yyyy") + 
			                     ";" + Chars.LF;
		ElsIf GuestGroupCreateDatePeriodFrom = GuestGroupCreateDatePeriodTo Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Отбор групп с датой и временем создания равным '; en = 'Choose groups with create date equal '; de = 'Wählen Sie Gruppen mit erstellen Datum gleich '") + 
			                     Format(GuestGroupCreateDatePeriodFrom, "DF=dd.MM.yyyy") + 
			                     ";" + Chars.LF;
		ElsIf GuestGroupCreateDatePeriodFrom < GuestGroupCreateDatePeriodTo Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Отбор групп с датой и временем создания в периоде '; en = 'Choose groups with create date in period '; de = 'Wählen Sie Gruppen mit Erstellungsdatum in Periode '") + PeriodPresentation(GuestGroupCreateDatePeriodFrom, GuestGroupCreateDatePeriodTo, cmLocalizationCode()) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru='Неправильно задан период отбора групп по дате и времени создания!'; en='Guest group create period is wrong!'; de='Erstellungszeitraum der Gruppen nach Datum und Uhrzeit wurde falsch eingegeben!'") + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(GuestGroupCheckDateFrom) Or ValueIsFilled(GuestGroupCheckDateTo) Then
		If Not ValueIsFilled(GuestGroupCheckDateFrom) And ValueIsFilled(GuestGroupCheckDateTo) Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Отбор групп с датой проверки оплаты в периоде по '; en = 'Choose groups with payment due date in period to '; de = 'Wählen Sie Gruppen mit Fälligkeitsdatum in der Zeit bis '") + 
			                     Format(GuestGroupCheckDateTo, "DF=dd.MM.yyyy") + 
			                     ";" + Chars.LF;
		ElsIf ValueIsFilled(GuestGroupCheckDateFrom) And Not ValueIsFilled(GuestGroupCheckDateTo) Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Отбор групп с датой проверки оплаты в периоде с '; en = 'Choose groups with payment due date in period from '; de = 'Wählen Sie Gruppen mit Fälligkeitsdatum in der Periode aus '") + 
			                     Format(GuestGroupCheckDateFrom, "DF=dd.MM.yyyy") + 
			                     ";" + Chars.LF;
		ElsIf GuestGroupCheckDateFrom = GuestGroupCheckDateTo Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Отбор групп с датой проверки оплаты равной '; en = 'Choose groups with payment due date equal '; de = 'Wählen Sie Gruppen mit Fälligkeit der Zahlung gleich '") + 
			                     Format(GuestGroupCheckDateFrom, "DF=dd.MM.yyyy") + 
			                     ";" + Chars.LF;
		ElsIf GuestGroupCheckDateFrom < GuestGroupCheckDateTo Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Отбор групп с датой проверки оплаты в периоде '; en = 'Choose groups with payment due date in period '; de = 'Wählen Sie Gruppen mit Fälligkeitsdatum in der Periode '") + PeriodPresentation(GuestGroupCheckDateFrom, GuestGroupCheckDateTo, cmLocalizationCode()) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru='Неправильно задан период отбора групп по дате проверки оплаты!'; en='Guest group payment due date period is wrong!'; de='Gastgruppe Zahlung Fälligkeit Zeitraum ist falsch!'") + 
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
Procedure pmGenerate(pSpreadsheet, pAddChart = False) Export
	Var vTemplateAttributes;
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
	
	// Initialize report builder query generator attributes
	ReportBuilder.PresentationAdding = PresentationAdditionType.Add;
	
	// Fill report parameters
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qIsEmptyHotel", Not ValueIsFilled(Hotel));
	ReportBuilder.Parameters.Insert("qPeriodFrom", BegOfDay(PeriodFrom));
	ReportBuilder.Parameters.Insert("qPeriodTo", ?(ValueIsFilled(PeriodTo), EndOfDay(PeriodTo), '39991231235959'));
	vForecastStartDate = tcOnServer.GetForecastStartDate(Hotel);
	ReportBuilder.Parameters.Insert("qForecastPeriodFrom", Max(BegOfDay(PeriodFrom), vForecastStartDate));
	ReportBuilder.Parameters.Insert("qForecastPeriodTo", ?(ValueIsFilled(PeriodTo), EndOfDay(PeriodTo), '39991231235959'));
	ReportBuilder.Parameters.Insert("qPaymentPeriodTo", ?(ValueIsFilled(PeriodTo), EndOfDay(PeriodTo), '39991231235959'));
	ReportBuilder.Parameters.Insert("qGuestGroupCheckInPeriodFrom", BegOfDay(GuestGroupCheckInPeriodFrom));
	ReportBuilder.Parameters.Insert("qGuestGroupCheckInPeriodFromIsEmpty", Not ValueIsFilled(GuestGroupCheckInPeriodFrom));
	ReportBuilder.Parameters.Insert("qGuestGroupCheckInPeriodTo", EndOfDay(GuestGroupCheckInPeriodTo));
	ReportBuilder.Parameters.Insert("qGuestGroupCheckInPeriodToIsEmpty", Not ValueIsFilled(GuestGroupCheckInPeriodTo));
	ReportBuilder.Parameters.Insert("qGuestGroupCreateDatePeriodFrom", BegOfDay(GuestGroupCreateDatePeriodFrom));
	ReportBuilder.Parameters.Insert("qGuestGroupCreateDatePeriodFromIsEmpty", Not ValueIsFilled(GuestGroupCreateDatePeriodFrom));
	ReportBuilder.Parameters.Insert("qGuestGroupCreateDatePeriodTo", EndOfDay(GuestGroupCreateDatePeriodTo));
	ReportBuilder.Parameters.Insert("qGuestGroupCreateDatePeriodToIsEmpty", Not ValueIsFilled(GuestGroupCreateDatePeriodTo));
	ReportBuilder.Parameters.Insert("qGuestGroupCheckDateFrom", BegOfDay(GuestGroupCheckDateFrom));
	ReportBuilder.Parameters.Insert("qGuestGroupCheckDateFromIsEmpty", Not ValueIsFilled(GuestGroupCheckDateFrom));
	ReportBuilder.Parameters.Insert("qGuestGroupCheckDateTo", EndOfDay(GuestGroupCheckDateTo));
	ReportBuilder.Parameters.Insert("qGuestGroupCheckDateToIsEmpty", Not ValueIsFilled(GuestGroupCheckDateTo));
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
	ReportBuilder.Parameters.Insert("qShowCurrentAccountsReceivable", ShowCurrentAccountsReceivable);
	ReportBuilder.Parameters.Insert("qShowAccountsReceivableForecast", ShowAccountsReceivableForecast);
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
	|	GuestStatistics.Client AS Client,
	|	SUM(GuestStatistics.GuestsCheckedIn) AS NumberOfClientPreviousCheckIns
	|INTO GuestStatistics
	|FROM
	|	AccumulationRegister.Sales AS GuestStatistics
	|
	|GROUP BY
	|	GuestStatistics.Client
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CustomerAccounts.Currency AS Currency,
	|	CustomerAccounts.Customer AS Customer,
	|	CustomerAccounts.Contract AS Contract,
	|	CustomerAccounts.Hotel AS Hotel,
	|	CustomerAccounts.Company AS Company,
	|	CustomerAccounts.GuestGroup AS GuestGroup,
	|	CustomerAccounts.GuestGroup.Description AS GuestGroupDescription,
	|	CustomerAccounts.GuestGroup.Client AS GuestGroupClient,
	|	CustomerAccounts.GuestGroup.CheckInDate AS GuestGroupCheckInDate,
	|	CustomerAccounts.GuestGroup.Duration AS GuestGroupDuration,
	|	CustomerAccounts.GuestGroup.CheckOutDate AS GuestGroupCheckOutDate,
	|	CustomerAccounts.GuestGroup.GuestsCheckedIn AS GuestGroupGuestsCheckedIn,
	|	CustomerAccounts.SumOpeningBalance AS SumOpeningBalance,
	|	CustomerAccounts.SumExpense AS SumExpense,
	|	CustomerAccounts.SumReceipt AS SumReceipt,
	|	CustomerAccounts.SumTurnover AS SumTurnover,
	|	CustomerAccounts.SumClosingBalance AS SumClosingBalance,
	|	CustomerAccounts.CommissionSumTurnover AS CommissionSumTurnover,
	|	ISNULL(PreauthorizationLimits.PreauthorizationBalance, 0) AS PreauthorizationBalance,
	|	CustomerAccounts.SumClosingBalance - ISNULL(PreauthorizationLimits.PreauthorizationBalance, 0) AS BalanceWithPreauthorization,
	|	1 AS Counter
	|{SELECT
	|	Currency.*,
	|	Customer.*,
	|	Contract.*,
	|	Hotel.*,
	|	Company.*,
	|	GuestGroup.*,
	|	GuestGroupDescription,
	|	GuestGroupClient.*,
	|	GuestGroupCheckInDate,
	|	GuestGroupDuration,
	|	GuestGroupCheckOutDate,
	|	GuestGroupGuestsCheckedIn,
	|	CustomerAccounts.GuestGroup.Customer.* AS GuestGroupCustomer,
	|	CustomerAccounts.GuestGroup.Contract.* AS GuestGroupContract,
	|	(BEGINOFPERIOD(CustomerAccounts.GuestGroup.CheckInDate, DAY)) AS CheckInDate,
	|	(BEGINOFPERIOD(CustomerAccounts.GuestGroup.CheckOutDate, DAY)) AS CheckOutDate,
	|	CustomerLastPayment.LastPaymentDate AS LastPaymentDate,
	|	CommissionSumTurnover,
	|	SumOpeningBalance,
	|	SumReceipt,
	|	SumExpense,
	|	SumTurnover,
	|	SumClosingBalance,
	|	PreauthorizationBalance,
	|	BalanceWithPreauthorization,
	|	GuestStatistics.NumberOfClientPreviousCheckIns,
	|	(1) AS Counter}
	|FROM
	|	(SELECT
	|		FullCustomerAccounts.Currency AS Currency,
	|		FullCustomerAccounts.Customer AS Customer,
	|		FullCustomerAccounts.Contract AS Contract,
	|		FullCustomerAccounts.Hotel AS Hotel,
	|		FullCustomerAccounts.Company AS Company,
	|		FullCustomerAccounts.GuestGroup AS GuestGroup,
	|		SUM(FullCustomerAccounts.SumOpeningBalance) AS SumOpeningBalance,
	|		SUM(FullCustomerAccounts.SumReceipt) AS SumReceipt,
	|		SUM(FullCustomerAccounts.SumExpense) AS SumExpense,
	|		SUM(FullCustomerAccounts.SumTurnover) AS SumTurnover,
	|		SUM(FullCustomerAccounts.SumClosingBalance) AS SumClosingBalance,
	|		SUM(FullCustomerAccounts.CommissionSumTurnover) AS CommissionSumTurnover
	|	FROM
	|		(SELECT
	|			AccountingCustomerAccounts.AccountingCurrency AS Currency,
	|			AccountingCustomerAccounts.AccountingCustomer AS Customer,
	|			AccountingCustomerAccounts.AccountingContract AS Contract,
	|			AccountingCustomerAccounts.Hotel AS Hotel,
	|			AccountingCustomerAccounts.Company AS Company,
	|			AccountingCustomerAccounts.GuestGroup AS GuestGroup,
	|			AccountingCustomerAccounts.SumOpeningBalance AS SumOpeningBalance,
	|			AccountingCustomerAccounts.SumReceipt AS SumReceipt,
	|			AccountingCustomerAccounts.SumExpense AS SumExpense,
	|			AccountingCustomerAccounts.SumTurnover AS SumTurnover,
	|			AccountingCustomerAccounts.SumClosingBalance AS SumClosingBalance,
	|			ISNULL(AccountsReceivable.CommissionSumTurnover, 0) AS CommissionSumTurnover
	|		FROM
	|			AccumulationRegister.CustomerAccounts.BalanceAndTurnovers(
	|					&qPeriodFrom,
	|					&qPeriodTo,
	|					Period,
	|					RegisterRecordsAndPeriodBoundaries,
	|					(Hotel IN HIERARCHY (&qHotel)
	|						OR &qIsEmptyHotel)
	|						AND (Company IN HIERARCHY (&qCompany)
	|							OR &qIsEmptyCompany)
	|						AND (AccountingCustomer IN HIERARCHY (&qCustomer)
	|							OR &qIsEmptyCustomer)
	|						AND (AccountingContract = &qContract
	|							OR &qIsEmptyContract)
	|						AND (GuestGroup = &qGuestGroup
	|							OR &qIsEmptyGuestGroup)
	|						AND (AccountingCurrency = &qCurrency
	|							OR &qIsEmptyCurrency)
	|						AND (&qGuestGroupCheckInPeriodFromIsEmpty
	|							OR NOT &qGuestGroupCheckInPeriodFromIsEmpty
	|								AND GuestGroup.CheckInDate >= &qGuestGroupCheckInPeriodFrom)
	|						AND (&qGuestGroupCheckInPeriodToIsEmpty
	|							OR NOT &qGuestGroupCheckInPeriodToIsEmpty
	|								AND GuestGroup.CheckInDate <= &qGuestGroupCheckInPeriodTo)
	|						AND (&qGuestGroupCheckDateFromIsEmpty
	|							OR NOT &qGuestGroupCheckDateFromIsEmpty
	|								AND GuestGroup.CheckDate >= &qGuestGroupCheckDateFrom)
	|						AND (&qGuestGroupCheckDateToIsEmpty
	|							OR NOT &qGuestGroupCheckDateToIsEmpty
	|								AND GuestGroup.CheckDate <= &qGuestGroupCheckDateTo)
	|						AND (&qGuestGroupCreateDatePeriodFromIsEmpty
	|							OR NOT &qGuestGroupCreateDatePeriodFromIsEmpty
	|								AND GuestGroup.CreateDate >= &qGuestGroupCreateDatePeriodFrom)
	|						AND (&qGuestGroupCreateDatePeriodToIsEmpty
	|							OR NOT &qGuestGroupCreateDatePeriodToIsEmpty
	|								AND GuestGroup.CreateDate <= &qGuestGroupCreateDatePeriodTo)) AS AccountingCustomerAccounts
	|				LEFT JOIN (SELECT
	|					AccountsReceivableTurnovers.AccountingCurrency AS AccountingCurrency,
	|					AccountsReceivableTurnovers.AccountingCustomer AS AccountingCustomer,
	|					AccountsReceivableTurnovers.AccountingContract AS AccountingContract,
	|					AccountsReceivableTurnovers.Hotel AS Hotel,
	|					AccountsReceivableTurnovers.Company AS Company,
	|					AccountsReceivableTurnovers.GuestGroup AS GuestGroup,
	|					AccountsReceivableTurnovers.CommissionSumTurnover AS CommissionSumTurnover
	|				FROM
	|					AccumulationRegister.AccountsReceivable.Turnovers(
	|							&qPeriodFrom,
	|							&qPeriodTo,
	|							Period,
	|							(Hotel IN HIERARCHY (&qHotel)
	|								OR &qIsEmptyHotel)
	|								AND (Company IN HIERARCHY (&qCompany)
	|									OR &qIsEmptyCompany)
	|								AND (AccountingCustomer IN HIERARCHY (&qCustomer)
	|									OR &qIsEmptyCustomer)
	|								AND (AccountingContract = &qContract
	|									OR &qIsEmptyContract)
	|								AND (GuestGroup = &qGuestGroup
	|									OR &qIsEmptyGuestGroup)
	|								AND (AccountingCurrency = &qCurrency
	|									OR &qIsEmptyCurrency)
	|								AND (&qGuestGroupCheckInPeriodFromIsEmpty
	|									OR NOT &qGuestGroupCheckInPeriodFromIsEmpty
	|										AND GuestGroup.CheckInDate >= &qGuestGroupCheckInPeriodFrom)
	|								AND (&qGuestGroupCheckInPeriodToIsEmpty
	|									OR NOT &qGuestGroupCheckInPeriodToIsEmpty
	|										AND GuestGroup.CheckInDate <= &qGuestGroupCheckInPeriodTo)
	|								AND (&qGuestGroupCheckDateFromIsEmpty
	|									OR NOT &qGuestGroupCheckDateFromIsEmpty
	|										AND GuestGroup.CheckDate >= &qGuestGroupCheckDateFrom)
	|								AND (&qGuestGroupCheckDateToIsEmpty
	|									OR NOT &qGuestGroupCheckDateToIsEmpty
	|										AND GuestGroup.CheckDate <= &qGuestGroupCheckDateTo)
	|								AND (&qGuestGroupCreateDatePeriodFromIsEmpty
	|									OR NOT &qGuestGroupCreateDatePeriodFromIsEmpty
	|										AND GuestGroup.CreateDate >= &qGuestGroupCreateDatePeriodFrom)
	|								AND (&qGuestGroupCreateDatePeriodToIsEmpty
	|									OR NOT &qGuestGroupCreateDatePeriodToIsEmpty
	|										AND GuestGroup.CreateDate <= &qGuestGroupCreateDatePeriodTo)) AS AccountsReceivableTurnovers) AS AccountsReceivable
	|				ON (AccountsReceivable.AccountingCurrency = AccountingCustomerAccounts.AccountingCurrency)
	|					AND (AccountsReceivable.AccountingCustomer = AccountingCustomerAccounts.AccountingCustomer)
	|					AND (AccountsReceivable.AccountingContract = AccountingCustomerAccounts.AccountingContract)
	|					AND (AccountsReceivable.Hotel = AccountingCustomerAccounts.Hotel)
	|					AND (AccountsReceivable.Company = AccountingCustomerAccounts.Company)
	|					AND (AccountsReceivable.GuestGroup = AccountingCustomerAccounts.GuestGroup)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			CurrentAccountsReceivable.FolioCurrency,
	|			CASE
	|				WHEN CurrentAccountsReceivable.Customer = &qEmptyCustomer
	|					THEN &qIndividualsCustomer
	|				ELSE CurrentAccountsReceivable.Customer
	|			END,
	|			CASE
	|				WHEN CurrentAccountsReceivable.Customer = &qEmptyCustomer
	|					THEN &qIndividualsContract
	|				ELSE CurrentAccountsReceivable.Contract
	|			END,
	|			CurrentAccountsReceivable.Hotel,
	|			CurrentAccountsReceivable.Company,
	|			CurrentAccountsReceivable.GuestGroup,
	|			CASE
	|				WHEN ISNULL(CurrentAccountsReceivable.Customer.DoNotPostCommission, FALSE)
	|					THEN CurrentAccountsReceivable.SumOpeningBalance
	|				ELSE CurrentAccountsReceivable.SumOpeningBalance - CurrentAccountsReceivable.CommissionSumOpeningBalance
	|			END,
	|			CASE
	|				WHEN ISNULL(CurrentAccountsReceivable.Customer.DoNotPostCommission, FALSE)
	|					THEN CurrentAccountsReceivable.SumTurnover
	|				ELSE CurrentAccountsReceivable.SumTurnover - CurrentAccountsReceivable.CommissionSumTurnover
	|			END,
	|			0,
	|			CASE
	|				WHEN ISNULL(CurrentAccountsReceivable.Customer.DoNotPostCommission, FALSE)
	|					THEN CurrentAccountsReceivable.SumTurnover
	|				ELSE CurrentAccountsReceivable.SumTurnover - CurrentAccountsReceivable.CommissionSumTurnover
	|			END,
	|			CASE
	|				WHEN ISNULL(CurrentAccountsReceivable.Customer.DoNotPostCommission, FALSE)
	|					THEN CurrentAccountsReceivable.SumClosingBalance
	|				ELSE CurrentAccountsReceivable.SumClosingBalance - CurrentAccountsReceivable.CommissionSumClosingBalance
	|			END,
	|			CurrentAccountsReceivable.CommissionSumTurnover
	|		FROM
	|			AccumulationRegister.CurrentAccountsReceivable.BalanceAndTurnovers(
	|					&qPeriodFrom,
	|					&qPeriodTo,
	|					Period,
	|					RegisterRecordsAndPeriodBoundaries,
	|					&qShowCurrentAccountsReceivable
	|						AND (Hotel IN HIERARCHY (&qHotel)
	|							OR &qIsEmptyHotel)
	|						AND (Company IN HIERARCHY (&qCompany)
	|							OR &qIsEmptyCompany)
	|						AND (Customer IN HIERARCHY (&qCustomer)
	|							OR &qIsEmptyCustomer
	|							OR &qIndividualsCustomerIsChoosen
	|								AND Customer = &qEmptyCustomer)
	|						AND (Contract = &qContract
	|							OR &qIsEmptyContract)
	|						AND (GuestGroup = &qGuestGroup
	|							OR &qIsEmptyGuestGroup)
	|						AND (FolioCurrency = &qCurrency
	|							OR &qIsEmptyCurrency)
	|						AND (&qGuestGroupCheckInPeriodFromIsEmpty
	|							OR NOT &qGuestGroupCheckInPeriodFromIsEmpty
	|								AND GuestGroup.CheckInDate >= &qGuestGroupCheckInPeriodFrom)
	|						AND (&qGuestGroupCheckInPeriodToIsEmpty
	|							OR NOT &qGuestGroupCheckInPeriodToIsEmpty
	|								AND GuestGroup.CheckInDate <= &qGuestGroupCheckInPeriodTo)
	|						AND (&qGuestGroupCheckDateFromIsEmpty
	|							OR NOT &qGuestGroupCheckDateFromIsEmpty
	|								AND GuestGroup.CheckDate >= &qGuestGroupCheckDateFrom)
	|						AND (&qGuestGroupCheckDateToIsEmpty
	|							OR NOT &qGuestGroupCheckDateToIsEmpty
	|								AND GuestGroup.CheckDate <= &qGuestGroupCheckDateTo)
	|						AND (&qGuestGroupCreateDatePeriodFromIsEmpty
	|							OR NOT &qGuestGroupCreateDatePeriodFromIsEmpty
	|								AND GuestGroup.CreateDate >= &qGuestGroupCreateDatePeriodFrom)
	|						AND (&qGuestGroupCreateDatePeriodToIsEmpty
	|							OR NOT &qGuestGroupCreateDatePeriodToIsEmpty
	|								AND GuestGroup.CreateDate <= &qGuestGroupCreateDatePeriodTo)) AS CurrentAccountsReceivable
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			AccountsReceivableForecast.FolioCurrency,
	|			CASE
	|				WHEN AccountsReceivableForecast.Customer = &qEmptyCustomer
	|					THEN &qIndividualsCustomer
	|				ELSE AccountsReceivableForecast.Customer
	|			END,
	|			CASE
	|				WHEN AccountsReceivableForecast.Customer = &qEmptyCustomer
	|					THEN &qIndividualsContract
	|				ELSE AccountsReceivableForecast.Contract
	|			END,
	|			AccountsReceivableForecast.Hotel,
	|			AccountsReceivableForecast.Company,
	|			AccountsReceivableForecast.GuestGroup,
	|			0,
	|			CASE
	|				WHEN ISNULL(AccountsReceivableForecast.Customer.DoNotPostCommission, FALSE)
	|					THEN AccountsReceivableForecast.SalesTurnover
	|				ELSE AccountsReceivableForecast.SalesTurnover - AccountsReceivableForecast.CommissionSumTurnover
	|			END,
	|			0,
	|			CASE
	|				WHEN ISNULL(AccountsReceivableForecast.Customer.DoNotPostCommission, FALSE)
	|					THEN AccountsReceivableForecast.SalesTurnover
	|				ELSE AccountsReceivableForecast.SalesTurnover - AccountsReceivableForecast.CommissionSumTurnover
	|			END,
	|			CASE
	|				WHEN ISNULL(AccountsReceivableForecast.Customer.DoNotPostCommission, FALSE)
	|					THEN AccountsReceivableForecast.SalesTurnover
	|				ELSE AccountsReceivableForecast.SalesTurnover - AccountsReceivableForecast.CommissionSumTurnover
	|			END,
	|			AccountsReceivableForecast.CommissionSumTurnover
	|		FROM
	|			AccumulationRegister.AccountsReceivableForecast.Turnovers(
	|					&qForecastPeriodFrom,
	|					&qForecastPeriodTo,
	|					Period,
	|					&qShowAccountsReceivableForecast
	|						AND (Hotel IN HIERARCHY (&qHotel)
	|							OR &qIsEmptyHotel)
	|						AND (Company IN HIERARCHY (&qCompany)
	|							OR &qIsEmptyCompany)
	|						AND (Customer IN HIERARCHY (&qCustomer)
	|							OR &qIsEmptyCustomer
	|							OR &qIndividualsCustomerIsChoosen
	|								AND Customer = &qEmptyCustomer)
	|						AND (Contract = &qContract
	|							OR &qIsEmptyContract)
	|						AND (GuestGroup = &qGuestGroup
	|							OR &qIsEmptyGuestGroup)
	|						AND (FolioCurrency = &qCurrency
	|							OR &qIsEmptyCurrency)
	|						AND (&qGuestGroupCheckInPeriodFromIsEmpty
	|							OR NOT &qGuestGroupCheckInPeriodFromIsEmpty
	|								AND GuestGroup.CheckInDate >= &qGuestGroupCheckInPeriodFrom)
	|						AND (&qGuestGroupCheckInPeriodToIsEmpty
	|							OR NOT &qGuestGroupCheckInPeriodToIsEmpty
	|								AND GuestGroup.CheckInDate <= &qGuestGroupCheckInPeriodTo)
	|						AND (&qGuestGroupCheckDateFromIsEmpty
	|							OR NOT &qGuestGroupCheckDateFromIsEmpty
	|								AND GuestGroup.CheckDate >= &qGuestGroupCheckDateFrom)
	|						AND (&qGuestGroupCheckDateToIsEmpty
	|							OR NOT &qGuestGroupCheckDateToIsEmpty
	|								AND GuestGroup.CheckDate <= &qGuestGroupCheckDateTo)
	|						AND (&qGuestGroupCreateDatePeriodFromIsEmpty
	|							OR NOT &qGuestGroupCreateDatePeriodFromIsEmpty
	|								AND GuestGroup.CreateDate >= &qGuestGroupCreateDatePeriodFrom)
	|						AND (&qGuestGroupCreateDatePeriodToIsEmpty
	|							OR NOT &qGuestGroupCreateDatePeriodToIsEmpty
	|								AND GuestGroup.CreateDate <= &qGuestGroupCreateDatePeriodTo)) AS AccountsReceivableForecast) AS FullCustomerAccounts
	|	
	|	GROUP BY
	|		FullCustomerAccounts.Currency,
	|		FullCustomerAccounts.Customer,
	|		FullCustomerAccounts.Contract,
	|		FullCustomerAccounts.Hotel,
	|		FullCustomerAccounts.Company,
	|		FullCustomerAccounts.GuestGroup) AS CustomerAccounts
	|		LEFT JOIN (SELECT
	|			AccountsBalance.FolioCurrency AS Currency,
	|			CASE
	|				WHEN AccountsBalance.Folio.Customer = &qEmptyCustomer
	|					THEN &qIndividualsCustomer
	|				ELSE AccountsBalance.Folio.Customer
	|			END AS Customer,
	|			CASE
	|				WHEN AccountsBalance.Folio.Customer = &qEmptyCustomer
	|					THEN &qIndividualsContract
	|				ELSE AccountsBalance.Folio.Contract
	|			END AS Contract,
	|			AccountsBalance.Hotel AS Hotel,
	|			AccountsBalance.Folio.Company AS Company,
	|			AccountsBalance.Folio.GuestGroup AS GuestGroup,
	|			-SUM(AccountsBalance.LimitBalance) AS PreauthorizationBalance
	|		FROM
	|			AccumulationRegister.Accounts.Balance(
	|					&qPeriodTo,
	|					(Hotel IN HIERARCHY (&qHotel)
	|						OR &qIsEmptyHotel)
	|						AND (Folio.Company IN HIERARCHY (&qCompany)
	|							OR &qIsEmptyCompany)
	|						AND (Folio.Customer IN HIERARCHY (&qCustomer)
	|							OR &qIsEmptyCustomer)
	|						AND (Folio.Contract = &qContract
	|							OR &qIsEmptyContract)
	|						AND (Folio.GuestGroup = &qGuestGroup
	|							OR &qIsEmptyGuestGroup)
	|						AND (FolioCurrency = &qCurrency
	|							OR &qIsEmptyCurrency)
	|						AND (&qGuestGroupCheckInPeriodFromIsEmpty
	|							OR NOT &qGuestGroupCheckInPeriodFromIsEmpty
	|								AND Folio.GuestGroup.CheckInDate >= &qGuestGroupCheckInPeriodFrom)
	|						AND (&qGuestGroupCheckInPeriodToIsEmpty
	|							OR NOT &qGuestGroupCheckInPeriodToIsEmpty
	|								AND Folio.GuestGroup.CheckInDate <= &qGuestGroupCheckInPeriodTo)
	|						AND (&qGuestGroupCheckDateFromIsEmpty
	|							OR NOT &qGuestGroupCheckDateFromIsEmpty
	|								AND Folio.GuestGroup.CheckDate >= &qGuestGroupCheckDateFrom)
	|						AND (&qGuestGroupCheckDateToIsEmpty
	|							OR NOT &qGuestGroupCheckDateToIsEmpty
	|								AND Folio.GuestGroup.CheckDate <= &qGuestGroupCheckDateTo)
	|						AND (&qGuestGroupCreateDatePeriodFromIsEmpty
	|							OR NOT &qGuestGroupCreateDatePeriodFromIsEmpty
	|								AND Folio.GuestGroup.CreateDate >= &qGuestGroupCreateDatePeriodFrom)
	|						AND (&qGuestGroupCreateDatePeriodToIsEmpty
	|							OR NOT &qGuestGroupCreateDatePeriodToIsEmpty
	|								AND Folio.GuestGroup.CreateDate <= &qGuestGroupCreateDatePeriodTo)) AS AccountsBalance
	|		
	|		GROUP BY
	|			AccountsBalance.FolioCurrency,
	|			CASE
	|				WHEN AccountsBalance.Folio.Customer = &qEmptyCustomer
	|					THEN &qIndividualsCustomer
	|				ELSE AccountsBalance.Folio.Customer
	|			END,
	|			CASE
	|				WHEN AccountsBalance.Folio.Customer = &qEmptyCustomer
	|					THEN &qIndividualsContract
	|				ELSE AccountsBalance.Folio.Contract
	|			END,
	|			AccountsBalance.Hotel,
	|			AccountsBalance.Folio.Company,
	|			AccountsBalance.Folio.GuestGroup) AS PreauthorizationLimits
	|		ON CustomerAccounts.Currency = PreauthorizationLimits.Currency
	|			AND CustomerAccounts.Customer = PreauthorizationLimits.Customer
	|			AND CustomerAccounts.Contract = PreauthorizationLimits.Contract
	|			AND CustomerAccounts.Hotel = PreauthorizationLimits.Hotel
	|			AND CustomerAccounts.Company = PreauthorizationLimits.Company
	|			AND CustomerAccounts.GuestGroup = PreauthorizationLimits.GuestGroup
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
	|			AND (&qGuestGroupCheckDateFromIsEmpty
	|					OR NOT &qGuestGroupCheckDateFromIsEmpty
	|						AND CustomerPayments.GuestGroup.CheckDate >= &qGuestGroupCheckDateFrom)
	|			AND (&qGuestGroupCheckDateToIsEmpty
	|					OR NOT &qGuestGroupCheckDateToIsEmpty
	|						AND CustomerPayments.GuestGroup.CheckDate <= &qGuestGroupCheckDateTo)
	|			AND (&qGuestGroupCreateDatePeriodFromIsEmpty
	|					OR NOT &qGuestGroupCreateDatePeriodFromIsEmpty
	|						AND CustomerPayments.GuestGroup.CreateDate >= &qGuestGroupCreateDatePeriodFrom)
	|			AND (&qGuestGroupCreateDatePeriodToIsEmpty
	|					OR NOT &qGuestGroupCreateDatePeriodToIsEmpty
	|						AND CustomerPayments.GuestGroup.CreateDate <= &qGuestGroupCreateDatePeriodTo)
	|		
	|		GROUP BY
	|			CustomerPayments.AccountingCurrency,
	|			CustomerPayments.AccountingCustomer,
	|			CustomerPayments.AccountingContract,
	|			CustomerPayments.Hotel,
	|			CustomerPayments.Company,
	|			CustomerPayments.GuestGroup) AS CustomerLastPayment
	|		ON CustomerAccounts.Currency = CustomerLastPayment.Currency
	|			AND CustomerAccounts.Customer = CustomerLastPayment.Customer
	|			AND CustomerAccounts.Contract = CustomerLastPayment.Contract
	|			AND CustomerAccounts.Hotel = CustomerLastPayment.Hotel
	|			AND CustomerAccounts.Company = CustomerLastPayment.Company
	|			AND CustomerAccounts.GuestGroup = CustomerLastPayment.GuestGroup
	|		LEFT JOIN GuestStatistics AS GuestStatistics
	|		ON (GuestStatistics.Client = CustomerAccounts.GuestGroup.Client)
	|{WHERE
	|	CustomerAccounts.Hotel.* AS Hotel,
	|	CustomerAccounts.Company.* AS Company,
	|	CustomerAccounts.Currency.* AS Currency,
	|	CustomerAccounts.Customer.* AS Customer,
	|	CustomerAccounts.Contract.* AS Contract,
	|	CustomerAccounts.GuestGroup.*,
	|	CustomerAccounts.GuestGroup.Description AS GuestGroupDescription,
	|	CustomerAccounts.GuestGroup.Client AS GuestGroupClient,
	|	CustomerAccounts.GuestGroup.CheckInDate AS GuestGroupCheckInDate,
	|	CustomerAccounts.GuestGroup.Duration AS GuestGroupDuration,
	|	CustomerAccounts.GuestGroup.CheckOutDate AS GuestGroupCheckOutDate,
	|	CustomerAccounts.GuestGroup.GuestsCheckedIn AS GuestGroupGuestsCheckedIn,
	|	CustomerAccounts.GuestGroup.Customer.* AS GuestGroupCustomer,
	|	CustomerAccounts.GuestGroup.Contract.* AS GuestGroupContract,
	|	(BEGINOFPERIOD(CustomerAccounts.GuestGroup.CheckInDate, DAY)) AS CheckInDate,
	|	(BEGINOFPERIOD(CustomerAccounts.GuestGroup.CheckOutDate, DAY)) AS CheckOutDate,
	|	CustomerLastPayment.LastPaymentDate AS LastPaymentDate,
	|	CustomerAccounts.SumOpeningBalance,
	|	CustomerAccounts.SumExpense,
	|	CustomerAccounts.SumReceipt,
	|	CustomerAccounts.SumTurnover,
	|	CustomerAccounts.SumClosingBalance,
	|	CustomerAccounts.CommissionSumTurnover,
	|	(ISNULL(PreauthorizationLimits.PreauthorizationBalance, 0)) AS PreauthorizationBalance,
	|	(CustomerAccounts.SumClosingBalance - ISNULL(PreauthorizationLimits.PreauthorizationBalance, 0)) AS BalanceWithPreauthorization}
	|
	|ORDER BY
	|	Currency,
	|	Customer,
	|	Contract
	|{ORDER BY
	|	Hotel.*,
	|	Company.*,
	|	Currency.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	GuestGroupClient.*,
	|	GuestGroupCheckInDate,
	|	GuestGroupDuration,
	|	GuestGroupCheckOutDate,
	|	GuestGroupGuestsCheckedIn,
	|	CustomerAccounts.GuestGroup.Customer.* AS GuestGroupCustomer,
	|	CustomerAccounts.GuestGroup.Contract.* AS GuestGroupContract,
	|	(BEGINOFPERIOD(CustomerAccounts.GuestGroup.CheckInDate, DAY)) AS CheckInDate,
	|	(BEGINOFPERIOD(CustomerAccounts.GuestGroup.CheckOutDate, DAY)) AS CheckOutDate,
	|	CustomerLastPayment.LastPaymentDate AS LastPaymentDate,
	|	SumOpeningBalance,
	|	SumExpense,
	|	SumReceipt,
	|	SumTurnover,
	|	SumClosingBalance,
	|	CommissionSumTurnover,
	|	PreauthorizationBalance,
	|	BalanceWithPreauthorization}
	|TOTALS
	|	SUM(SumOpeningBalance),
	|	SUM(SumExpense),
	|	SUM(SumReceipt),
	|	SUM(SumTurnover),
	|	SUM(SumClosingBalance),
	|	SUM(CommissionSumTurnover),
	|	SUM(PreauthorizationBalance),
	|	SUM(BalanceWithPreauthorization),
	|	SUM(Counter)
	|BY
	|	OVERALL,
	|	Currency,
	|	Customer HIERARCHY,
	|	Contract
	|{TOTALS BY
	|	Hotel.* AS Hotel,
	|	Company.* AS Company,
	|	Currency.* AS Currency,
	|	Customer.* AS Customer,
	|	Contract.* AS Contract,
	|	GuestGroup.* AS GuestGroup,
	|	CustomerAccounts.GuestGroup.Customer.* AS GuestGroupCustomer,
	|	CustomerAccounts.GuestGroup.Contract.* AS GuestGroupContract,
	|	(BEGINOFPERIOD(CustomerAccounts.GuestGroup.CheckInDate, DAY)) AS CheckInDate,
	|	(BEGINOFPERIOD(CustomerAccounts.GuestGroup.CheckOutDate, DAY)) AS CheckOutDate,
	|	CustomerLastPayment.LastPaymentDate AS LastPaymentDate}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Customer accounts';RU='Баланс взаиморасчетов с контрагентами';de='Bilanz der Verrechnung mit Vertragspartnern'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
Function pmIsResource(pName) Export
	If pName = "SumOpeningBalance" Or
	   pName = "SumExpence" Or 
	   pName = "SumReceipt" Or 
	   pName = "SumTurnover" Or 
	   pName = "SumClosingBalance" Or
	   pName = "Counter" Or
	   pName = "CommissionSumTurnover" Or
	   pName = "PreauthorizationBalance" Or
	   pName = "BalanceWithPreauthorization" Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // pmIsResource

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
