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
	If Not ValueIsFilled(PeriodFrom) Then
		PeriodFrom = BegOfDay(CurrentSessionDate()); // For today
		PeriodTo = EndOfDay(PeriodFrom);
	EndIf;
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
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
			vParamPresentation = vParamPresentation + NStr("de='Firma - Quelle ';en='Customer - source ';ru='Контрагент - источник '") + 
			                     TrimAll(Customer.Description) + 
			                     "; ";
		Else
			vParamPresentation = vParamPresentation + NStr("de='Gruppe Firmen - Quelle ';en='Customers folder - source ';ru='Группа контрагентов - источник '") + 
			                     TrimAll(Customer.Description) + 
			                     "; ";
		EndIf;
	EndIf;							 
	If ValueIsFilled(CustomerTo) Then
		If Not CustomerTo.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("de='Firma - Empfänger ';en='Customer - receiver ';ru='Контрагент - получатель '") + 
			                     TrimAll(CustomerTo.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("de='Gruppe Firmen - Empfänger ';en='Customers folder - receiver ';ru='Группа контрагентов - получатель '") + 
			                     TrimAll(CustomerTo.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	Else
		If ValueIsFilled(Customer) Then
			vParamPresentation = vParamPresentation + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(Contract) Then
		vParamPresentation = vParamPresentation + NStr("en='Contract - source ';ru='Договор - источник ';de='Vertrag - Quelle '") + 
							 TrimAll(Contract.Description) + 
							 "; ";
	EndIf;							 
	If ValueIsFilled(ContractTo) Then
		vParamPresentation = vParamPresentation + NStr("en='Contract - receiver ';ru='Договор - получатель ';de='Vertrag - Empfänger '") + 
							 TrimAll(ContractTo.Description) + 
							 ";" + Chars.LF;
	Else
		If ValueIsFilled(Contract) Then
			vParamPresentation = vParamPresentation + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(GuestGroup) Then
		vParamPresentation = vParamPresentation + NStr("en='Guest group - source ';ru='Группа - источник ';de='Gruppe - Quelle '") + 
							 TrimAll(GuestGroup.Code) + 
							 "; ";
	EndIf;							 
	If ValueIsFilled(GuestGroupTo) Then
		vParamPresentation = vParamPresentation + NStr("en='Guest group - receiver ';ru='Группа - получатель ';de='Gruppe - Empfänger '") + 
							 TrimAll(GuestGroupTo.Code) + 
							 ";" + Chars.LF;
	Else
		If ValueIsFilled(GuestGroup) Then
			vParamPresentation = vParamPresentation + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(Company) Then
		If Not Company.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Фирма - источник '; en = 'Company - source '; de = 'Kompanie - Quelle '") + 
			                     TrimAll(Company.Description) + 
			                     "; ";
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа фирм - источник '; en = 'Companies folder - source '; de = 'Kompaniegruppe - Quelle '") + 
			                     TrimAll(Company.Description) + 
			                     "; ";
		EndIf;
	EndIf;					 
	If ValueIsFilled(CompanyTo) Then
		If Not CompanyTo.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Фирма - получатель '; en = 'Company - receiver '; de = 'Kompanie - Empfänger '") + 
			                     TrimAll(CompanyTo.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа фирм - получатель '; en = 'Companies folder - receiver '; de = 'Kompaniegruppe - Empfänger '") + 
			                     TrimAll(CompanyTo.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	Else
		If ValueIsFilled(Company) Then
			vParamPresentation = vParamPresentation + Chars.LF;
		EndIf;
	EndIf;					 
	If ValueIsFilled(Hotel) Then
		If Not Hotel.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Hotel - source ';ru='Гостиница - источник ';de='Hotel - Quelle '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     "; ";
		Else
			vParamPresentation = vParamPresentation + NStr("en='Hotels folder - source ';ru='Группа гостиниц - источник ';de='Gruppe Hotels - Quelle '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     "; ";
		EndIf;
	EndIf;
	If ValueIsFilled(HotelTo) Then
		If Not HotelTo.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Hotel - receiver ';ru='Гостиница - получатель ';de='Hotel - Empfänger '") + 
			                     HotelTo.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Hotels folder - receiver ';ru='Группа гостиниц - получатель ';de='Gruppe Hotels - Empfänger '") + 
			                     HotelTo.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		EndIf;
	Else
		If ValueIsFilled(Hotel) Then
			vParamPresentation = vParamPresentation + Chars.LF;
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
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	ReportBuilder.Parameters.Insert("qCompany", Company);
	ReportBuilder.Parameters.Insert("qCompanyIsEmpty", Not ValueIsFilled(Company));
	ReportBuilder.Parameters.Insert("qCustomer", Customer);
	ReportBuilder.Parameters.Insert("qCustomerIsEmpty", Not ValueIsFilled(Customer));
	ReportBuilder.Parameters.Insert("qContract", Contract);
	ReportBuilder.Parameters.Insert("qContractIsEmpty", Not ValueIsFilled(Contract));
	ReportBuilder.Parameters.Insert("qGuestGroup", GuestGroup);
	ReportBuilder.Parameters.Insert("qGuestGroupIsEmpty", Not ValueIsFilled(GuestGroup));
	ReportBuilder.Parameters.Insert("qHotelTo", HotelTo);
	ReportBuilder.Parameters.Insert("qHotelToIsEmpty", Not ValueIsFilled(HotelTo));
	ReportBuilder.Parameters.Insert("qCompanyTo", CompanyTo);
	ReportBuilder.Parameters.Insert("qCompanyToIsEmpty", Not ValueIsFilled(CompanyTo));
	ReportBuilder.Parameters.Insert("qCustomerTo", CustomerTo);
	ReportBuilder.Parameters.Insert("qCustomerToIsEmpty", Not ValueIsFilled(CustomerTo));
	ReportBuilder.Parameters.Insert("qContractTo", ContractTo);
	ReportBuilder.Parameters.Insert("qContractToIsEmpty", Not ValueIsFilled(ContractTo));
	ReportBuilder.Parameters.Insert("qGuestGroupTo", GuestGroupTo);
	ReportBuilder.Parameters.Insert("qGuestGroupToIsEmpty", Not ValueIsFilled(GuestGroupTo));
	
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
	|	DepositTransfer.Date AS Date,
	|	DepositTransfer.Ref AS DepositTransfer,
	|	DepositTransfer.SumInFolioFromCurrency AS SumInFolioFromCurrency,
	|	DepositTransfer.FolioFromCurrency AS FolioFromCurrency,
	|	DepositTransfer.FolioFrom.Customer AS FolioFromCustomer,
	|	DepositTransfer.FolioFrom.Contract AS FolioFromContract,
	|	DepositTransfer.FolioFrom.GuestGroup AS FolioFromGuestGroup,
	|	DepositTransfer.FolioFrom.Client AS FolioFromClient,
	|	DepositTransfer.FolioFrom.Room AS FolioFromRoom,
	|	DepositTransfer.FolioFrom.DateTimeFrom AS FolioFromDateTimeFrom,
	|	DepositTransfer.FolioFrom.DateTimeTo AS FolioFromDateTimeTo,
	|	DepositTransfer.SumInFolioToCurrency AS SumInFolioToCurrency,
	|	DepositTransfer.FolioToCurrency AS FolioToCurrency,
	|	DepositTransfer.FolioTo.Customer AS FolioToCustomer,
	|	DepositTransfer.FolioTo.Contract AS FolioToContract,
	|	DepositTransfer.FolioTo.GuestGroup AS FolioToGuestGroup,
	|	DepositTransfer.FolioTo.Client AS FolioToClient,
	|	DepositTransfer.FolioTo.Room AS FolioToRoom,
	|	DepositTransfer.FolioTo.DateTimeFrom AS FolioToDateTimeFrom,
	|	DepositTransfer.FolioTo.DateTimeTo AS FolioToDateTimeTo,
	|	DepositTransfer.Remarks AS Remarks,
	|	DepositTransfer.Author AS Author
	|{SELECT
	|	Date,
	|	DepositTransfer.*,
	|	DepositTransfer.FolioFrom.*,
	|	SumInFolioFromCurrency,
	|	FolioFromCurrency.*,
	|	DepositTransfer.FolioFrom.PaymentMethod.* AS FolioFromPaymentMethod,
	|	FolioFromCustomer.*,
	|	FolioFromContract.*,
	|	FolioFromGuestGroup.*,
	|	FolioFromClient.*,
	|	FolioFromRoom.*,
	|	FolioFromDateTimeFrom,
	|	FolioFromDateTimeTo,
	|	DepositTransfer.FolioTo.*,
	|	SumInFolioToCurrency,
	|	FolioToCurrency.*,
	|	DepositTransfer.FolioTo.PaymentMethod.* AS FolioToPaymentMethod,
	|	FolioToCustomer.*,
	|	FolioToContract.*,
	|	FolioToGuestGroup.*,
	|	FolioToClient.*,
	|	FolioToRoom.*,
	|	FolioToDateTimeFrom,
	|	FolioToDateTimeTo,
	|	DepositTransfer.ParentDoc.*,
	|	Remarks,
	|	Author.*,
	|	DepositTransfer.Hotel.*,
	|	DepositTransfer.ExchangeRateDate,
	|	DepositTransfer.FolioToCurrencyExchangeRate,
	|	DepositTransfer.FolioFromCurrencyExchangeRate,
	|	(BEGINOFPERIOD(DepositTransfer.Date, DAY)) AS AccountingDate,
	|	(WEEK(DepositTransfer.Date)) AS AccountingWeek,
	|	(MONTH(DepositTransfer.Date)) AS AccountingMonth,
	|	(QUARTER(DepositTransfer.Date)) AS AccountingQuarter,
	|	(YEAR(DepositTransfer.Date)) AS AccountingYear}
	|FROM
	|	Document.DepositTransfer AS DepositTransfer
	|WHERE
	|	(DepositTransfer.FolioFrom.Hotel IN HIERARCHY (&qHotel)
	|			OR &qHotelIsEmpty)
	|	AND (DepositTransfer.FolioTo.Hotel IN HIERARCHY (&qHotelTo)
	|			OR &qHotelToIsEmpty)
	|	AND (DepositTransfer.FolioFrom.Customer IN HIERARCHY (&qCustomer)
	|			OR &qCustomerIsEmpty)
	|	AND (DepositTransfer.FolioTo.Customer IN HIERARCHY (&qCustomerTo)
	|			OR &qCustomerToIsEmpty)
	|	AND (DepositTransfer.FolioFrom.Contract = &qContract
	|			OR &qContractIsEmpty)
	|	AND (DepositTransfer.FolioTo.Contract = &qContractTo
	|			OR &qContractToIsEmpty)
	|	AND (DepositTransfer.FolioFrom.GuestGroup = &qGuestGroup
	|			OR &qGuestGroupIsEmpty)
	|	AND (DepositTransfer.FolioTo.GuestGroup = &qGuestGroupTo
	|			OR &qGuestGroupToIsEmpty)
	|	AND DepositTransfer.Date >= &qPeriodFrom
	|	AND DepositTransfer.Date < &qPeriodTo
	|	AND DepositTransfer.Posted
	|	AND (DepositTransfer.FolioFrom.Company IN HIERARCHY (&qCompany)
	|			OR &qCompanyIsEmpty)
	|	AND (DepositTransfer.FolioTo.Company IN HIERARCHY (&qCompanyTo)
	|			OR &qCompanyToIsEmpty)
	|{WHERE
	|	DepositTransfer.Ref.* AS DepositTransfer,
	|	DepositTransfer.ParentDoc.*,
	|	DepositTransfer.FolioFrom.*,
	|	DepositTransfer.FolioTo.*,
	|	DepositTransfer.Hotel.*,
	|	DepositTransfer.SumInFolioFromCurrency,
	|	DepositTransfer.FolioFromCurrency.*,
	|	DepositTransfer.SumInFolioToCurrency,
	|	DepositTransfer.FolioToCurrency.*,
	|	DepositTransfer.ExchangeRateDate,
	|	DepositTransfer.Remarks,
	|	DepositTransfer.Author.*,
	|	DepositTransfer.Date,
	|	DepositTransfer.FolioToCurrencyExchangeRate,
	|	DepositTransfer.FolioFromCurrencyExchangeRate,
	|	DepositTransfer.FolioFrom.Customer.*,
	|	DepositTransfer.FolioFrom.Contract.*,
	|	DepositTransfer.FolioFrom.GuestGroup.*,
	|	DepositTransfer.FolioFrom.Client.*,
	|	DepositTransfer.FolioFrom.DateTimeFrom,
	|	DepositTransfer.FolioFrom.DateTimeTo,
	|	DepositTransfer.FolioFrom.Room.*,
	|	DepositTransfer.FolioTo.Customer.*,
	|	DepositTransfer.FolioTo.Contract.*,
	|	DepositTransfer.FolioTo.GuestGroup.*,
	|	DepositTransfer.FolioTo.Client.*,
	|	DepositTransfer.FolioTo.DateTimeFrom,
	|	DepositTransfer.FolioTo.DateTimeTo,
	|	DepositTransfer.FolioTo.Room.*,
	|	DepositTransfer.FolioTo.PaymentMethod.*,
	|	DepositTransfer.FolioFrom.PaymentMethod.*}
	|
	|ORDER BY
	|	Date
	|{ORDER BY
	|	DepositTransfer.*,
	|	DepositTransfer.ParentDoc.*,
	|	DepositTransfer.FolioFrom.*,
	|	DepositTransfer.FolioTo.*,
	|	DepositTransfer.Hotel.*,
	|	SumInFolioFromCurrency,
	|	DepositTransfer.FolioFromCurrency.*,
	|	SumInFolioToCurrency,
	|	FolioToCurrency.*,
	|	DepositTransfer.ExchangeRateDate,
	|	Remarks,
	|	Author.*,
	|	Date,
	|	DepositTransfer.FolioToCurrencyExchangeRate,
	|	DepositTransfer.FolioFromCurrencyExchangeRate,
	|	FolioFromCustomer.*,
	|	FolioFromContract.*,
	|	FolioFromGuestGroup.*,
	|	FolioFromClient.*,
	|	FolioFromDateTimeFrom,
	|	FolioFromDateTimeTo,
	|	FolioFromRoom.*,
	|	FolioToCustomer.*,
	|	FolioToContract.*,
	|	FolioToGuestGroup.*,
	|	FolioToClient.*,
	|	FolioToDateTimeFrom,
	|	FolioToDateTimeTo,
	|	FolioToRoom.*,
	|	DepositTransfer.FolioTo.PaymentMethod.* AS FolioToPaymentMethod,
	|	DepositTransfer.FolioFrom.PaymentMethod.* AS FolioFromPaymentMethod}
	|TOTALS
	|	SUM(SumInFolioFromCurrency),
	|	SUM(SumInFolioToCurrency)
	|BY
	|	OVERALL
	|{TOTALS BY
	|	DepositTransfer.Ref.* AS DepositTransfer,
	|	DepositTransfer.ParentDoc.*,
	|	DepositTransfer.FolioFrom.*,
	|	DepositTransfer.FolioTo.*,
	|	DepositTransfer.Hotel.*,
	|	FolioFromCurrency.*,
	|	FolioToCurrency.*,
	|	Author.*,
	|	FolioFromCustomer.*,
	|	FolioFromContract.*,
	|	FolioFromGuestGroup.*,
	|	FolioFromClient.*,
	|	FolioFromRoom.*,
	|	FolioToCustomer.*,
	|	FolioToContract.*,
	|	FolioToGuestGroup.*,
	|	FolioToClient.*,
	|	FolioToRoom.*,
	|	DepositTransfer.FolioFrom.PaymentMethod.* AS FolioFromPaymentMethod,
	|	DepositTransfer.FolioTo.PaymentMethod.* AS FolioToPaymentMethod,
	|	(BEGINOFPERIOD(DepositTransfer.Date, DAY)) AS AccountingDate,
	|	(WEEK(DepositTransfer.Date)) AS AccountingWeek,
	|	(MONTH(DepositTransfer.Date)) AS AccountingMonth,
	|	(QUARTER(DepositTransfer.Date)) AS AccountingQuarter,
	|	(YEAR(DepositTransfer.Date)) AS AccountingYear}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Deposit transfers';RU='Перемещения депозитов';de='Verschiebungen der Deposite'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
