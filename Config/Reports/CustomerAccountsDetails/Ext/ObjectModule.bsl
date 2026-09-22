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
		vParamPresentation = vParamPresentation + NStr("ru = 'Период на '; en = 'Period on '; de = 'Periode gleich '") + 
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
	If ValueIsFilled(GuestGroupCreateDatePeriodFrom) Or ValueIsFilled(GuestGroupCreateDatePeriodTo) Then
		If Not ValueIsFilled(GuestGroupCreateDatePeriodFrom) And ValueIsFilled(GuestGroupCreateDatePeriodTo) Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Отбор групп с датой и временем создания в периоде по '; en = 'Choose groups with create date in period to '; de = 'Wählen Sie Gruppen mit Erstellungsdatum in Periode zu '") + 
			                     Format(GuestGroupCreateDatePeriodTo, "DF='dd.MM.yyyy HH:mm'") + 
			                     ";" + Chars.LF;
		ElsIf ValueIsFilled(GuestGroupCreateDatePeriodFrom) And Not ValueIsFilled(GuestGroupCreateDatePeriodTo) Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Отбор групп с датой и временем создания в периоде с '; en = 'Choose groups with create date in period from '; de = 'Wählen Sie Gruppen mit Erstellungsdatum in Periode aus '") + 
			                     Format(GuestGroupCreateDatePeriodFrom, "DF='dd.MM.yyyy HH:mm'") + 
			                     ";" + Chars.LF;
		ElsIf GuestGroupCreateDatePeriodFrom = GuestGroupCreateDatePeriodTo Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Отбор групп с датой и временем создания равным '; en = 'Choose groups with create date equal '; de = 'Wählen Sie Gruppen mit erstellen Datum gleich '") + 
			                     Format(GuestGroupCreateDatePeriodFrom, "DF='dd.MM.yyyy HH:mm'") + 
			                     ";" + Chars.LF;
		ElsIf GuestGroupCreateDatePeriodFrom < GuestGroupCreateDatePeriodTo Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Отбор групп с датой и временем создания в периоде '; en = 'Choose groups with create date in period '; de = 'Wählen Sie Gruppen mit erstellen Datum in Periode '") + PeriodPresentation(GuestGroupCreateDatePeriodFrom, GuestGroupCreateDatePeriodTo, cmLocalizationCode()) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Guest group create period is wrong!';ru='Неправильно задан период отбора групп по дате и времени создания!';de='Erstellungszeitraum der Gruppen nach Datum und Uhrzeit wurde falsch eingegeben!'") + 
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
	ReportBuilder.Parameters.Insert("qPeriodTo", ?(ValueIsFilled(PeriodTo), PeriodTo, '39991231235958'));
	vForecastStartDate = tcOnServer.GetForecastStartDate(Hotel);
	ReportBuilder.Parameters.Insert("qForecastPeriodFrom", Max(PeriodFrom, vForecastStartDate));
	ReportBuilder.Parameters.Insert("qForecastPeriodTo", ?(ValueIsFilled(PeriodTo), PeriodTo, '39991231235959'));
	ReportBuilder.Parameters.Insert("qGuestGroupCheckInPeriodFrom", GuestGroupCheckInPeriodFrom);
	ReportBuilder.Parameters.Insert("qGuestGroupCheckInPeriodFromIsEmpty", Not ValueIsFilled(GuestGroupCheckInPeriodFrom));
	ReportBuilder.Parameters.Insert("qGuestGroupCheckInPeriodTo", GuestGroupCheckInPeriodTo);
	ReportBuilder.Parameters.Insert("qGuestGroupCheckInPeriodToIsEmpty", Not ValueIsFilled(GuestGroupCheckInPeriodTo));
	ReportBuilder.Parameters.Insert("qGuestGroupCreateDatePeriodFrom", GuestGroupCreateDatePeriodFrom);
	ReportBuilder.Parameters.Insert("qGuestGroupCreateDatePeriodFromIsEmpty", Not ValueIsFilled(GuestGroupCreateDatePeriodFrom));
	ReportBuilder.Parameters.Insert("qGuestGroupCreateDatePeriodTo", GuestGroupCreateDatePeriodTo);
	ReportBuilder.Parameters.Insert("qGuestGroupCreateDatePeriodToIsEmpty", Not ValueIsFilled(GuestGroupCreateDatePeriodTo));
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
	ReportBuilder.Parameters.Insert("qUndefined", Undefined);
	ReportBuilder.Parameters.Insert("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	ReportBuilder.Parameters.Insert("qIndividualsCustomer", ?(ValueIsFilled(Hotel), Hotel.IndividualsCustomer, Catalogs.Customers.EmptyRef()));
	ReportBuilder.Parameters.Insert("qIndividualsContract", ?(ValueIsFilled(Hotel), Hotel.IndividualsContract, Catalogs.Contracts.EmptyRef()));
	If ValueIsFilled(Hotel) And ValueIsFilled(Customer) And Customer = Hotel.IndividualsCustomer Then
		ReportBuilder.Parameters.Insert("qIndividualsCustomerIsChoosen", True);
	Else
		ReportBuilder.Parameters.Insert("qIndividualsCustomerIsChoosen", False);
	EndIf;
	ReportBuilder.Parameters.Insert("qInPriceServicesFolioType", TrimAll(InPriceServicesFolioType) + "%");
	ReportBuilder.Parameters.Insert("qShowInPriceAmountsOnly", ShowInPriceAmountsOnly);
	
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
	|	CustomerAccounts.Hotel AS Hotel,
	|	CustomerAccounts.Company AS Company,
	|	CustomerAccounts.Currency AS Currency,
	|	CustomerAccounts.Customer AS Customer,
	|	CustomerAccounts.Contract AS Contract,
	|	CustomerAccounts.GuestGroup AS GuestGroup,
	|	BEGINOFPERIOD(CustomerAccounts.Recorder.Date, DAY) AS RecorderAccountingDate,
	|	CustomerAccounts.Recorder AS Recorder,
	|	CustomerAccounts.Recorder.Remarks AS RecorderRemarks,
	|	CustomerAccounts.CommissionSum AS CommissionSum,
	|	CustomerAccounts.SumReceipt AS SumReceipt,
	|	CustomerAccounts.SumExpense AS SumExpense,
	|	CustomerAccounts.Sum AS Sum,
	|	CustomerAccounts.VATSum AS VATSum,
	|	1 AS Counter
	|INTO CustomerAccounts
	|FROM
	|	(SELECT
	|		CustomerAccountsBalance.Hotel AS Hotel,
	|		CustomerAccountsBalance.Company AS Company,
	|		CustomerAccountsBalance.AccountingCurrency AS Currency,
	|		CustomerAccountsBalance.AccountingCustomer AS Customer,
	|		CustomerAccountsBalance.AccountingContract AS Contract,
	|		CustomerAccountsBalance.GuestGroup AS GuestGroup,
	|		NULL AS Recorder,
	|		0 AS CommissionSum,
	|		SUM(CustomerAccountsBalance.SumBalance) AS Sum,
	|		0 AS SumReceipt,
	|		0 AS SumExpense,
	|		0 AS VATSum,
	|		0 AS Dummy
	|	FROM
	|		AccumulationRegister.CustomerAccounts.Balance(
	|				&qPeriodFrom,
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
	|							AND GuestGroup.CheckInDate <= &qGuestGroupCheckInPeriodTo)
	|					AND (&qGuestGroupCreateDatePeriodFromIsEmpty
	|						OR NOT &qGuestGroupCreateDatePeriodFromIsEmpty
	|							AND GuestGroup.CreateDate >= &qGuestGroupCreateDatePeriodFrom)
	|					AND (&qGuestGroupCreateDatePeriodToIsEmpty
	|						OR NOT &qGuestGroupCreateDatePeriodToIsEmpty
	|							AND GuestGroup.CreateDate <= &qGuestGroupCreateDatePeriodTo)) AS CustomerAccountsBalance
	|	
	|	GROUP BY
	|		CustomerAccountsBalance.Hotel,
	|		CustomerAccountsBalance.Company,
	|		CustomerAccountsBalance.AccountingCurrency,
	|		CustomerAccountsBalance.AccountingCustomer,
	|		CustomerAccountsBalance.AccountingContract,
	|		CustomerAccountsBalance.GuestGroup
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CustomerAccountsDetailed.Hotel,
	|		CustomerAccountsDetailed.Company,
	|		CustomerAccountsDetailed.AccountingCurrency,
	|		CustomerAccountsDetailed.AccountingCustomer,
	|		CustomerAccountsDetailed.AccountingContract,
	|		CustomerAccountsDetailed.GuestGroup,
	|		CustomerAccountsDetailed.Recorder,
	|		ISNULL(AccountsReceivableTurnovers.CommissionSum, 0),
	|		CustomerAccountsDetailed.Sum,
	|		CustomerAccountsDetailed.SumReceipt,
	|		CustomerAccountsDetailed.SumExpense,
	|		CustomerAccountsDetailed.VATSum,
	|		0
	|	FROM
	|		(SELECT
	|			CustomerAccountsRecords.Hotel AS Hotel,
	|			CustomerAccountsRecords.Company AS Company,
	|			CustomerAccountsRecords.AccountingCurrency AS AccountingCurrency,
	|			CustomerAccountsRecords.AccountingCustomer AS AccountingCustomer,
	|			CustomerAccountsRecords.AccountingContract AS AccountingContract,
	|			CustomerAccountsRecords.GuestGroup AS GuestGroup,
	|			CustomerAccountsRecords.Recorder AS Recorder,
	|			SUM(CASE
	|					WHEN CustomerAccountsRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
	|						THEN CustomerAccountsRecords.Sum
	|					ELSE -CustomerAccountsRecords.Sum
	|				END) AS Sum,
	|			SUM(CASE
	|					WHEN CustomerAccountsRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
	|						THEN CustomerAccountsRecords.Sum
	|					ELSE 0
	|				END) AS SumReceipt,
	|			SUM(CASE
	|					WHEN CustomerAccountsRecords.RecordType = VALUE(AccumulationRecordType.Expense)
	|						THEN CustomerAccountsRecords.Sum
	|					ELSE 0
	|				END) AS SumExpense,
	|			SUM(CASE
	|					WHEN CustomerAccountsRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
	|						THEN CustomerAccountsRecords.VATSum
	|					ELSE 0
	|				END) AS VATSum
	|		FROM
	|			AccumulationRegister.CustomerAccounts AS CustomerAccountsRecords
	|		WHERE
	|			CustomerAccountsRecords.Period >= &qPeriodFrom
	|			AND CustomerAccountsRecords.Period <= &qPeriodTo
	|			AND (CustomerAccountsRecords.Hotel IN HIERARCHY (&qHotel)
	|					OR &qIsEmptyHotel)
	|			AND (CustomerAccountsRecords.Company IN HIERARCHY (&qCompany)
	|					OR &qIsEmptyCompany)
	|			AND (CustomerAccountsRecords.AccountingCustomer IN HIERARCHY (&qCustomer)
	|					OR &qIsEmptyCustomer)
	|			AND (CustomerAccountsRecords.AccountingContract = &qContract
	|					OR &qIsEmptyContract)
	|			AND (CustomerAccountsRecords.GuestGroup = &qGuestGroup
	|					OR &qIsEmptyGuestGroup)
	|			AND (CustomerAccountsRecords.AccountingCurrency = &qCurrency
	|					OR &qIsEmptyCurrency)
	|			AND (&qGuestGroupCheckInPeriodFromIsEmpty
	|					OR NOT &qGuestGroupCheckInPeriodFromIsEmpty
	|						AND CustomerAccountsRecords.GuestGroup.CheckInDate >= &qGuestGroupCheckInPeriodFrom)
	|			AND (&qGuestGroupCheckInPeriodToIsEmpty
	|					OR NOT &qGuestGroupCheckInPeriodToIsEmpty
	|						AND CustomerAccountsRecords.GuestGroup.CheckInDate <= &qGuestGroupCheckInPeriodTo)
	|			AND (&qGuestGroupCreateDatePeriodFromIsEmpty
	|					OR NOT &qGuestGroupCreateDatePeriodFromIsEmpty
	|						AND CustomerAccountsRecords.GuestGroup.CreateDate >= &qGuestGroupCreateDatePeriodFrom)
	|			AND (&qGuestGroupCreateDatePeriodToIsEmpty
	|					OR NOT &qGuestGroupCreateDatePeriodToIsEmpty
	|						AND CustomerAccountsRecords.GuestGroup.CreateDate <= &qGuestGroupCreateDatePeriodTo)
	|			AND (NOT &qShowInPriceAmountsOnly
	|					OR &qShowInPriceAmountsOnly
	|						AND CustomerAccountsRecords.Folio.Description LIKE &qInPriceServicesFolioType)
	|		
	|		GROUP BY
	|			CustomerAccountsRecords.Hotel,
	|			CustomerAccountsRecords.Company,
	|			CustomerAccountsRecords.AccountingCurrency,
	|			CustomerAccountsRecords.AccountingCustomer,
	|			CustomerAccountsRecords.AccountingContract,
	|			CustomerAccountsRecords.GuestGroup,
	|			CustomerAccountsRecords.Recorder) AS CustomerAccountsDetailed
	|			LEFT JOIN (SELECT
	|				AccountsReceivable.Hotel AS Hotel,
	|				AccountsReceivable.Company AS Company,
	|				AccountsReceivable.AccountingCurrency AS AccountingCurrency,
	|				AccountsReceivable.AccountingCustomer AS AccountingCustomer,
	|				AccountsReceivable.AccountingContract AS AccountingContract,
	|				AccountsReceivable.GuestGroup AS GuestGroup,
	|				AccountsReceivable.Recorder AS Recorder,
	|				SUM(AccountsReceivable.CommissionSum) AS CommissionSum
	|			FROM
	|				AccumulationRegister.AccountsReceivable AS AccountsReceivable
	|			WHERE
	|				AccountsReceivable.Period >= &qPeriodFrom
	|				AND AccountsReceivable.Period <= &qPeriodTo
	|				AND (AccountsReceivable.Hotel IN HIERARCHY (&qHotel)
	|						OR &qIsEmptyHotel)
	|				AND (AccountsReceivable.Company IN HIERARCHY (&qCompany)
	|						OR &qIsEmptyCompany)
	|				AND (AccountsReceivable.AccountingCustomer IN HIERARCHY (&qCustomer)
	|						OR &qIsEmptyCustomer)
	|				AND (AccountsReceivable.AccountingContract = &qContract
	|						OR &qIsEmptyContract)
	|				AND (AccountsReceivable.GuestGroup = &qGuestGroup
	|						OR &qIsEmptyGuestGroup)
	|				AND (AccountsReceivable.AccountingCurrency = &qCurrency
	|						OR &qIsEmptyCurrency)
	|				AND (&qGuestGroupCheckInPeriodFromIsEmpty
	|						OR NOT &qGuestGroupCheckInPeriodFromIsEmpty
	|							AND AccountsReceivable.GuestGroup.CheckInDate >= &qGuestGroupCheckInPeriodFrom)
	|				AND (&qGuestGroupCheckInPeriodToIsEmpty
	|						OR NOT &qGuestGroupCheckInPeriodToIsEmpty
	|							AND AccountsReceivable.GuestGroup.CheckInDate <= &qGuestGroupCheckInPeriodTo)
	|				AND (&qGuestGroupCreateDatePeriodFromIsEmpty
	|						OR NOT &qGuestGroupCreateDatePeriodFromIsEmpty
	|							AND AccountsReceivable.GuestGroup.CreateDate >= &qGuestGroupCreateDatePeriodFrom)
	|				AND (&qGuestGroupCreateDatePeriodToIsEmpty
	|						OR NOT &qGuestGroupCreateDatePeriodToIsEmpty
	|							AND AccountsReceivable.GuestGroup.CreateDate <= &qGuestGroupCreateDatePeriodTo)
	|				AND (NOT &qShowInPriceAmountsOnly
	|						OR &qShowInPriceAmountsOnly
	|							AND AccountsReceivable.Service.IsInPrice)
	|			
	|			GROUP BY
	|				AccountsReceivable.Hotel,
	|				AccountsReceivable.Company,
	|				AccountsReceivable.AccountingCurrency,
	|				AccountsReceivable.AccountingCustomer,
	|				AccountsReceivable.AccountingContract,
	|				AccountsReceivable.GuestGroup,
	|				AccountsReceivable.Recorder) AS AccountsReceivableTurnovers
	|			ON CustomerAccountsDetailed.Hotel = AccountsReceivableTurnovers.Hotel
	|				AND CustomerAccountsDetailed.Company = AccountsReceivableTurnovers.Company
	|				AND CustomerAccountsDetailed.AccountingCurrency = AccountsReceivableTurnovers.AccountingCurrency
	|				AND CustomerAccountsDetailed.AccountingCustomer = AccountsReceivableTurnovers.AccountingCustomer
	|				AND CustomerAccountsDetailed.AccountingContract = AccountsReceivableTurnovers.AccountingContract
	|				AND CustomerAccountsDetailed.GuestGroup = AccountsReceivableTurnovers.GuestGroup
	|				AND CustomerAccountsDetailed.Recorder = AccountsReceivableTurnovers.Recorder
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CurrentAccountsReceivableBalance.Hotel,
	|		CurrentAccountsReceivableBalance.Company,
	|		CurrentAccountsReceivableBalance.FolioCurrency,
	|		CASE
	|			WHEN CurrentAccountsReceivableBalance.Customer = &qEmptyCustomer
	|				THEN &qIndividualsCustomer
	|			ELSE CurrentAccountsReceivableBalance.Customer
	|		END,
	|		CASE
	|			WHEN CurrentAccountsReceivableBalance.Customer = &qEmptyCustomer
	|				THEN &qIndividualsContract
	|			ELSE CurrentAccountsReceivableBalance.Contract
	|		END,
	|		NULL,
	|		NULL,
	|		0,
	|		CASE
	|			WHEN ISNULL(CurrentAccountsReceivableBalance.Customer.DoNotPostCommission, FALSE)
	|				THEN SUM(CurrentAccountsReceivableBalance.SumBalance)
	|			ELSE SUM(CurrentAccountsReceivableBalance.SumBalance - CurrentAccountsReceivableBalance.CommissionSumBalance)
	|		END,
	|		0,
	|		0,
	|		0,
	|		SUM(CurrentAccountsReceivableBalance.QuantityBalance)
	|	FROM
	|		AccumulationRegister.CurrentAccountsReceivable.Balance(
	|				&qPeriodFrom,
	|				&qShowCurrentAccountsReceivable
	|					AND (Hotel IN HIERARCHY (&qHotel)
	|						OR &qIsEmptyHotel)
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
	|							AND GuestGroup.CheckInDate <= &qGuestGroupCheckInPeriodTo)
	|					AND (&qGuestGroupCreateDatePeriodFromIsEmpty
	|						OR NOT &qGuestGroupCreateDatePeriodFromIsEmpty
	|							AND GuestGroup.CreateDate >= &qGuestGroupCreateDatePeriodFrom)
	|					AND (&qGuestGroupCreateDatePeriodToIsEmpty
	|						OR NOT &qGuestGroupCreateDatePeriodToIsEmpty
	|							AND GuestGroup.CreateDate <= &qGuestGroupCreateDatePeriodTo)
	|					AND (NOT &qShowInPriceAmountsOnly
	|						OR &qShowInPriceAmountsOnly
	|							AND Charge.Folio.Description LIKE &qInPriceServicesFolioType)) AS CurrentAccountsReceivableBalance
	|	
	|	GROUP BY
	|		CurrentAccountsReceivableBalance.Hotel,
	|		CurrentAccountsReceivableBalance.Company,
	|		CurrentAccountsReceivableBalance.FolioCurrency,
	|		CASE
	|			WHEN CurrentAccountsReceivableBalance.Customer = &qEmptyCustomer
	|				THEN &qIndividualsCustomer
	|			ELSE CurrentAccountsReceivableBalance.Customer
	|		END,
	|		CASE
	|			WHEN CurrentAccountsReceivableBalance.Customer = &qEmptyCustomer
	|				THEN &qIndividualsContract
	|			ELSE CurrentAccountsReceivableBalance.Contract
	|		END,
	|		CurrentAccountsReceivableBalance.Customer.DoNotPostCommission
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
	|		CASE
	|			WHEN CurrentAccountsReceivable.Charge.ParentDoc = &qUndefined
	|				THEN CurrentAccountsReceivable.Charge.Folio
	|			ELSE CurrentAccountsReceivable.Charge.ParentDoc
	|		END,
	|		SUM(CurrentAccountsReceivable.CommissionSumTurnover),
	|		CASE
	|			WHEN ISNULL(CurrentAccountsReceivable.Customer.DoNotPostCommission, FALSE)
	|				THEN SUM(CurrentAccountsReceivable.SumTurnover)
	|			ELSE SUM(CurrentAccountsReceivable.SumTurnover - CurrentAccountsReceivable.CommissionSumTurnover)
	|		END,
	|		CASE
	|			WHEN ISNULL(CurrentAccountsReceivable.Customer.DoNotPostCommission, FALSE)
	|				THEN SUM(CurrentAccountsReceivable.SumTurnover)
	|			ELSE SUM(CurrentAccountsReceivable.SumTurnover - CurrentAccountsReceivable.CommissionSumTurnover)
	|		END,
	|		0,
	|		0,
	|		SUM(CurrentAccountsReceivable.QuantityTurnover)
	|	FROM
	|		AccumulationRegister.CurrentAccountsReceivable.BalanceAndTurnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				RegisterRecordsAndPeriodBoundaries,
	|				&qShowCurrentAccountsReceivable
	|					AND (Hotel IN HIERARCHY (&qHotel)
	|						OR &qIsEmptyHotel)
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
	|							AND GuestGroup.CheckInDate <= &qGuestGroupCheckInPeriodTo)
	|					AND (&qGuestGroupCreateDatePeriodFromIsEmpty
	|						OR NOT &qGuestGroupCreateDatePeriodFromIsEmpty
	|							AND GuestGroup.CreateDate >= &qGuestGroupCreateDatePeriodFrom)
	|					AND (&qGuestGroupCreateDatePeriodToIsEmpty
	|						OR NOT &qGuestGroupCreateDatePeriodToIsEmpty
	|							AND GuestGroup.CreateDate <= &qGuestGroupCreateDatePeriodTo)
	|					AND (NOT &qShowInPriceAmountsOnly
	|						OR &qShowInPriceAmountsOnly
	|							AND Charge.Folio.Description LIKE &qInPriceServicesFolioType)) AS CurrentAccountsReceivable
	|	
	|	GROUP BY
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
	|		CASE
	|			WHEN CurrentAccountsReceivable.Charge.ParentDoc = &qUndefined
	|				THEN CurrentAccountsReceivable.Charge.Folio
	|			ELSE CurrentAccountsReceivable.Charge.ParentDoc
	|		END,
	|		CurrentAccountsReceivable.Customer.DoNotPostCommission
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AccountsReceivableForecast.Hotel,
	|		AccountsReceivableForecast.Company,
	|		AccountsReceivableForecast.FolioCurrency,
	|		CASE
	|			WHEN AccountsReceivableForecast.Customer = &qEmptyCustomer
	|				THEN &qIndividualsCustomer
	|			ELSE AccountsReceivableForecast.Customer
	|		END,
	|		CASE
	|			WHEN AccountsReceivableForecast.Customer = &qEmptyCustomer
	|				THEN &qIndividualsContract
	|			ELSE AccountsReceivableForecast.Contract
	|		END,
	|		AccountsReceivableForecast.GuestGroup,
	|		AccountsReceivableForecast.ParentDoc,
	|		SUM(AccountsReceivableForecast.CommissionSumTurnover),
	|		CASE
	|			WHEN ISNULL(AccountsReceivableForecast.Customer.DoNotPostCommission, FALSE)
	|				THEN SUM(AccountsReceivableForecast.SalesTurnover)
	|			ELSE SUM(AccountsReceivableForecast.SalesTurnover - AccountsReceivableForecast.CommissionSumTurnover)
	|		END,
	|		CASE
	|			WHEN ISNULL(AccountsReceivableForecast.Customer.DoNotPostCommission, FALSE)
	|				THEN SUM(AccountsReceivableForecast.SalesTurnover)
	|			ELSE SUM(AccountsReceivableForecast.SalesTurnover - AccountsReceivableForecast.CommissionSumTurnover)
	|		END,
	|		0,
	|		0,
	|		SUM(AccountsReceivableForecast.QuantityTurnover)
	|	FROM
	|		AccumulationRegister.AccountsReceivableForecast.Turnovers(
	|				&qForecastPeriodFrom,
	|				&qForecastPeriodTo,
	|				Period,
	|				&qShowAccountsReceivableForecast
	|					AND (Hotel IN HIERARCHY (&qHotel)
	|						OR &qIsEmptyHotel)
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
	|							AND GuestGroup.CheckInDate <= &qGuestGroupCheckInPeriodTo)
	|					AND (&qGuestGroupCreateDatePeriodFromIsEmpty
	|						OR NOT &qGuestGroupCreateDatePeriodFromIsEmpty
	|							AND GuestGroup.CreateDate >= &qGuestGroupCreateDatePeriodFrom)
	|					AND (&qGuestGroupCreateDatePeriodToIsEmpty
	|						OR NOT &qGuestGroupCreateDatePeriodToIsEmpty
	|							AND GuestGroup.CreateDate <= &qGuestGroupCreateDatePeriodTo)
	|					AND (NOT &qShowInPriceAmountsOnly
	|						OR &qShowInPriceAmountsOnly
	|							AND Service.IsInPrice)) AS AccountsReceivableForecast
	|	
	|	GROUP BY
	|		AccountsReceivableForecast.Hotel,
	|		AccountsReceivableForecast.Company,
	|		AccountsReceivableForecast.FolioCurrency,
	|		CASE
	|			WHEN AccountsReceivableForecast.Customer = &qEmptyCustomer
	|				THEN &qIndividualsCustomer
	|			ELSE AccountsReceivableForecast.Customer
	|		END,
	|		CASE
	|			WHEN AccountsReceivableForecast.Customer = &qEmptyCustomer
	|				THEN &qIndividualsContract
	|			ELSE AccountsReceivableForecast.Contract
	|		END,
	|		AccountsReceivableForecast.GuestGroup,
	|		AccountsReceivableForecast.ParentDoc,
	|		AccountsReceivableForecast.Customer.DoNotPostCommission) AS CustomerAccounts
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GroupCounterTotals.GuestGroup AS GuestGroup,
	|	SUM(GroupCounterTotals.Counter) AS GroupCounter
	|INTO GroupCounterTotals
	|FROM
	|	CustomerAccounts AS GroupCounterTotals
	|
	|GROUP BY
	|	GroupCounterTotals.GuestGroup
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CustomerAccounts.Currency AS Currency,
	|	CustomerAccounts.Customer AS Customer,
	|	CustomerAccounts.Contract AS Contract,
	|	CustomerAccounts.GuestGroup AS GuestGroup,
	|	CustomerAccounts.RecorderAccountingDate AS RecorderAccountingDate,
	|	CustomerAccounts.Recorder AS Recorder,
	|	CustomerAccounts.RecorderRemarks AS RecorderRemarks,
	|	CustomerAccounts.CommissionSum AS CommissionSum,
	|	CustomerAccounts.SumReceipt AS SumReceipt,
	|	CustomerAccounts.SumExpense AS SumExpense,
	|	CustomerAccounts.Sum AS Sum,
	|	CustomerAccounts.VATSum AS VATSum,
	|	CASE
	|		WHEN NOT CustomerAccounts.GuestGroup IS NULL
	|				AND CustomerAccounts.GuestGroup <> VALUE(Catalog.GuestGroups.EmptyRef)
	|			THEN CustomerAccounts.Counter / GroupCounterTotals.GroupCounter
	|		ELSE 0
	|	END AS Counter
	|{SELECT
	|	CustomerAccounts.Hotel.*,
	|	CustomerAccounts.Company.*,
	|	Currency.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	RecorderAccountingDate,
	|	Recorder.*,
	|	RecorderRemarks,
	|	CommissionSum,
	|	SumReceipt,
	|	SumExpense,
	|	Sum,
	|	VATSum,
	|	Counter}
	|FROM
	|	CustomerAccounts AS CustomerAccounts
	|		LEFT JOIN GroupCounterTotals AS GroupCounterTotals
	|		ON (GroupCounterTotals.GuestGroup = CustomerAccounts.GuestGroup)
	|{WHERE
	|	CustomerAccounts.Hotel.*,
	|	CustomerAccounts.Company.*,
	|	CustomerAccounts.Currency.*,
	|	CustomerAccounts.Customer.*,
	|	CustomerAccounts.Contract.*,
	|	CustomerAccounts.GuestGroup.*,
	|	CustomerAccounts.RecorderAccountingDate AS RecorderAccountingDate,
	|	CustomerAccounts.Recorder.*}
	|
	|ORDER BY
	|	Currency,
	|	Customer,
	|	Contract,
	|	GuestGroup
	|{ORDER BY
	|	CustomerAccounts.Hotel.*,
	|	CustomerAccounts.Company.*,
	|	Currency.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	Recorder.*}
	|TOTALS
	|	SUM(CommissionSum),
	|	SUM(SumReceipt),
	|	SUM(SumExpense),
	|	SUM(Sum),
	|	SUM(VATSum),
	|	CASE
	|		WHEN SUM(Counter) - (CAST(SUM(Counter) AS NUMBER(17, 0))) > 0.9
	|			THEN (CAST(SUM(Counter) AS NUMBER(17, 0))) + 1
	|		ELSE CAST(SUM(Counter) AS NUMBER(17, 0))
	|	END AS Counter
	|BY
	|	OVERALL,
	|	Currency,
	|	Customer,
	|	Contract,
	|	GuestGroup
	|{TOTALS BY
	|	CustomerAccounts.Hotel.*,
	|	CustomerAccounts.Company.*,
	|	Currency.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	RecorderAccountingDate,
	|	Recorder.*}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Customer accounts details';RU='Детальный баланс взаиморасчетов с контрагентами';de='Detaillierte Bilanz der Verrechnung mit Vertragspartnern'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
