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
		PeriodFrom = BegOfDay(CurrentSessionDate()); // For today
		PeriodTo = EndOfDay(PeriodFrom);
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetReportParametersPresentation() Export
	vParamPresentation = "";
	If ValueIsFilled(Hotel) Then
		If Not Hotel.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Hotel ';ru='Гостиница ';de='Hotel'") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Hotels folder ';ru='Группа гостиниц ';de='Gruppe Hotels '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If Not ValueIsFilled(PeriodFrom) And Not ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("en='Report period is not set';ru='Период отчета не установлен';de='Berichtszeitraum nicht festgelegt'") + 
		                     ";" + Chars.LF;
	ElsIf Not ValueIsFilled(PeriodFrom) And ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период c '; en = 'Period from '") + 
		                     Format(PeriodFrom, "DF='dd.MM.yyyy HH:mm:ss'") + 
		                     ";" + Chars.LF;
	ElsIf ValueIsFilled(PeriodFrom) And Not ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период по '; en = 'Period to '") + 
		                     Format(PeriodTo, "DF='dd.MM.yyyy HH:mm:ss'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom = PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период на '; en = 'Period on '") + 
		                     Format(PeriodFrom, "DF='dd.MM.yyyy HH:mm:ss'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom < PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период '; en = 'Period '") + PeriodPresentation(PeriodFrom, PeriodTo, cmLocalizationCode()) + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("en='Period is wrong!';ru='Неправильно задан период!';de='Der Zeitraum wurde falsch eingetragen!'") + 
		                     ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(Room) Then
		If Not Room.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Room ';ru='Номер ';de='Zimmer'") + 
			                     TrimAll(Room.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Rooms folder ';ru='Группа номеров ';de='Gruppe Zimmer '") + 
			                     TrimAll(Room.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(Company) Then
		If Not Company.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Company ';ru='Фирма ';de='Kompanie '") + 
			                     TrimAll(Company.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа фирм '; en = 'Companies folder '; de = 'Kompanien '") + 
			                     TrimAll(Company.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;					 
	If ValueIsFilled(CashRegister) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'ККМ '; en = 'Cash register '; de = 'Kasse '") + 
		                     TrimAll(CashRegister.Description) + 
		                     ";" + Chars.LF;
	EndIf;					 
	If ValueIsFilled(Currency) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Валюта '; en = 'Currency '; de = 'Währung '") + 
		                     TrimAll(Currency.Description) + 
		                     ";" + Chars.LF;
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
	ReportBuilder.Parameters.Insert("qPeriodFrom", BegOfDay(PeriodFrom));
	ReportBuilder.Parameters.Insert("qPeriodTo", EndOfDay(PeriodTo));
	ReportBuilder.Parameters.Insert("qCurrency", Currency);
	ReportBuilder.Parameters.Insert("qCurrencyIsEmpty", Not ValueIsFilled(Currency));
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qRoomIsEmpty", Not ValueIsFilled(Room));
	ReportBuilder.Parameters.Insert("qCompany", Company);
	ReportBuilder.Parameters.Insert("qCompanyIsEmpty", Not ValueIsFilled(Company));
	ReportBuilder.Parameters.Insert("qCashRegister", CashRegister);
	ReportBuilder.Parameters.Insert("qCashRegisterIsEmpty", Not ValueIsFilled(CashRegister));
	
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
	|	Operations.Ref.Date AS Period,
	|	Operations.Ref.Author AS Author,
	|	Operations.Ref AS Operation,
	|	Operations.Ref.Hotel AS Hotel,
	|	Operations.Ref.Company AS Company,
	|	Operations.Ref.CashRegister AS CashRegister,
	|	Operations.Ref.ExchangeRateDate AS ExchangeRateDate,
	|	Operations.Ref.Room AS Room,
	|	Operations.Ref.Client AS Client,
	|	Operations.Ref.Remarks AS Remarks,
	|	Operations.CurrencyFrom AS CurrencyFrom,
	|	Operations.CurrencyFromExchangeRate AS CurrencyFromExchangeRate,
	|	Operations.TravellerChequesQuantity AS TravellerChequesQuantity,
	|	Operations.FromSum AS FromSum,
	|	Operations.CurrencyTo AS CurrencyTo,
	|	Operations.CurrencyToExchangeRate AS CurrencyToExchangeRate,
	|	Operations.ToSum AS ToSum
	|{SELECT
	|	Period,
	|	Author.*,
	|	Operation.*,
	|	Hotel.*,
	|	Company.*,
	|	CashRegister.*,
	|	Room.*,
	|	Client.*,
	|	ExchangeRateDate,
	|	Remarks,
	|	CurrencyFrom.*,
	|	CurrencyFromExchangeRate,
	|	TravellerChequesQuantity,
	|	FromSum,
	|	CurrencyTo.*,
	|	CurrencyToExchangeRate,
	|	ToSum}
	|FROM
	|	Document.CurrencyConversion.Conversions AS Operations
	|WHERE
	|	Operations.Ref.Hotel IN HIERARCHY(&qHotel)
	|	AND Operations.Ref.Date BETWEEN &qPeriodFrom AND &qPeriodTo
	|	AND (Operations.Ref.Company IN HIERARCHY (&qCompany)
	|			OR &qCompanyIsEmpty)
	|	AND (Operations.Ref.CashRegister = &qCashRegister
	|			OR &qCashRegisterIsEmpty)
	|	AND (Operations.Ref.Room IN HIERARCHY (&qRoom)
	|			OR &qRoomIsEmpty)
	|	AND (Operations.CurrencyFrom = &qCurrency
	|			OR &qCurrencyIsEmpty)
	|	AND NOT Operations.Ref.DeletionMark
	|{WHERE
	|	Operations.Ref.Date AS Period,
	|	Operations.Ref.Author.* AS Author,
	|	Operations.Ref AS Operation,
	|	Operations.Ref.Hotel.* AS Hotel,
	|	Operations.Ref.Company.* AS Company,
	|	Operations.Ref.CashRegister.* AS CashRegister,
	|	Operations.Ref.ExchangeRateDate AS ExchangeRateDate,
	|	Operations.Ref.Room.* AS Room,
	|	Operations.Ref.Client.* AS Client,
	|	Operations.Ref.Remarks AS Remarks,
	|	Operations.CurrencyFrom.* AS CurrencyFrom,
	|	Operations.CurrencyFromExchangeRate AS CurrencyFromExchangeRate,
	|	Operations.TravellerChequesQuantity AS TravellerChequesQuantity,
	|	Operations.FromSum AS FromSum,
	|	Operations.CurrencyTo.* AS CurrencyTo,
	|	Operations.CurrencyToExchangeRate AS CurrencyToExchangeRate,
	|	Operations.ToSum AS ToSum}
	|
	|ORDER BY
	|	CurrencyFrom,
	|	Period
	|{ORDER BY
	|	Period,
	|	Author.*,
	|	Operation.*,
	|	Hotel.*,
	|	Company.*,
	|	CashRegister.*,
	|	Room.*,
	|	Client.*,
	|	ExchangeRateDate,
	|	Remarks,
	|	CurrencyFrom.*,
	|	CurrencyFromExchangeRate,
	|	TravellerChequesQuantity,
	|	FromSum,
	|	CurrencyTo.*,
	|	CurrencyToExchangeRate,
	|	ToSum}
	|TOTALS
	|	SUM(TravellerChequesQuantity),
	|	SUM(FromSum),
	|	SUM(ToSum)
	|BY
	|	OVERALL,
	|	CurrencyFrom
	|{TOTALS BY
	|	Author.*,
	|	Operation.*,
	|	Hotel.*,
	|	Company.*,
	|	CashRegister.*,
	|	Room.*,
	|	Client.*,
	|	ExchangeRateDate,
	|	CurrencyFrom.*,
	|	CurrencyFromExchangeRate,
	|	CurrencyTo.*,
	|	CurrencyToExchangeRate}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("en='Foreign currency exchange report';ru='Отчет по обмену иностранной валюты';de='Devisenkursbericht'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
