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
	If Not ValueIsFilled(DateFrom) Then
		DateFrom = BegOfMonth(CurrentSessionDate()); // For beg of month
		DateTo = EndOfDay(CurrentSessionDate());
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetReportParametersPresentation() Export
	vParamPresentation = "";
	If Not ValueIsFilled(DateFrom) And Not ValueIsFilled(DateTo) Then
		vParamPresentation = vParamPresentation + NStr("en='Reservation period is not set';ru='Период бронирования не установлен';de='Reservierungszeitraum nicht festgelegt'") + 
		                     ";" + Chars.LF;
	ElsIf ValueIsFilled(DateFrom) And Not ValueIsFilled(DateTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период бронирования c '; en = 'Reservation period from '; de = 'Reservierungszeitraum von '") + 
		                     Format(DateFrom, "DF='dd.MM.yyyy'") + 
		                     ";" + Chars.LF;
	ElsIf Not ValueIsFilled(DateFrom) And ValueIsFilled(DateTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период бронирования по '; en = 'Reservation period to '; de = 'Reservierungszeitraum zu '") + 
		                     Format(DateTo, "DF='dd.MM.yyyy'") + 
		                     ";" + Chars.LF;
	ElsIf DateFrom = DateTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период бронирования на '; en = 'Reservation period on '; de = 'Reservierungszeitraum '") + 
		                     Format(DateFrom, "DF='dd.MM.yyyy'") + 
		                     ";" + Chars.LF;
	ElsIf DateFrom < DateTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период бронирования '; en = 'Reservation period '; de = 'Reservierungszeitraum '") + PeriodPresentation(DateFrom, DateTo, cmLocalizationCode()) + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("en='Reservation period is wrong!';ru='Неправильно задан период бронирования!';de='Der Reservierungszeitraum wurde falsch eingetragen!'") + 
		                     ";" + Chars.LF;
	EndIf;
	If Not ValueIsFilled(PeriodFrom) And Not ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("en='Request period is not set';ru='Период выполнения запросов не установлен';de='Anforderungszeitraum nicht festgelegt'") + 
		                     ";" + Chars.LF;
	ElsIf ValueIsFilled(PeriodFrom) And Not ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период запросов c '; en = 'Request period from '; de = 'Anforderungszeitraum von '") + 
		                     Format(PeriodFrom, "DF='dd.MM.yyyy'") + 
		                     ";" + Chars.LF;
	ElsIf Not ValueIsFilled(PeriodFrom) And ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период запросов по '; en = 'Request period to '; de = 'Anforderungszeitraum zu '") + 
		                     Format(PeriodTo, "DF='dd.MM.yyyy'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom = PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период запросов на '; en = 'Request period on '; de = 'Anforderungszeitraum '") + 
		                     Format(PeriodFrom, "DF='dd.MM.yyyy'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom < PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период запросов '; en = 'Request period '; de = 'Anforderungszeitraum '") + PeriodPresentation(PeriodFrom, PeriodTo, cmLocalizationCode()) + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("en='Request period is wrong!';ru='Неправильно задан период запросов!';de='Der Anforderungszeitraum wurde falsch eingetragen!'") + 
		                     ";" + Chars.LF;
	EndIf;
	If Not IsBlankString(ExtSystemCode) Then
		vParamPresentation = vParamPresentation + NStr("de='Fremdsystem ';en='External system ';ru='Внешняя система '") + 
		                     TrimAll(ExtSystemCode) + 
		                     ";" + Chars.LF;
	EndIf;							 
	If Not IsBlankString(utm_source) Then
		vParamPresentation = vParamPresentation + NStr("de='utm_source ';en='utm_source ';ru='utm_source '") + 
		                     TrimAll(utm_source) + 
		                     ";" + Chars.LF;
	EndIf;							 
	If Not IsBlankString(utm_medium) Then
		vParamPresentation = vParamPresentation + NStr("de='utm_medium ';en='utm_medium ';ru='utm_medium '") + 
		                     TrimAll(utm_medium) + 
		                     ";" + Chars.LF;
	EndIf;							 
	If Not IsBlankString(utm_campaign) Then
		vParamPresentation = vParamPresentation + NStr("de='utm_campaign ';en='utm_campaign ';ru='utm_campaign '") + 
		                     TrimAll(utm_campaign) + 
		                     ";" + Chars.LF;
	EndIf;							 
	If ValueIsFilled(Hotel) Then
		If Not Hotel.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Hotel ';ru='Гостиница ';de='Hotel '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Hotels folder ';ru='Группа гостиниц '; de='Hotelsgruppe '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     TrimAll(Hotel.Description) + ";" + Chars.LF;
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
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qPeriodToIsEmpty", Not ValueIsFilled(PeriodTo));
	ReportBuilder.Parameters.Insert("qDateFrom", DateFrom);
	ReportBuilder.Parameters.Insert("qDateTo", DateTo);
	ReportBuilder.Parameters.Insert("qDateToIsEmpty", Not ValueIsFilled(DateTo));
	ReportBuilder.Parameters.Insert("qExtSystemCode", ExtSystemCode);
	ReportBuilder.Parameters.Insert("qIsEmptyExtSystemCode", IsBlankString(ExtSystemCode));
	ReportBuilder.Parameters.Insert("qUtm_source", utm_source);
	ReportBuilder.Parameters.Insert("qIsEmptyUtm_source", IsBlankString(utm_source));
	ReportBuilder.Parameters.Insert("qUtm_medium", utm_medium);
	ReportBuilder.Parameters.Insert("qIsEmptyUtm_medium", IsBlankString(utm_medium));
	ReportBuilder.Parameters.Insert("qUtm_campaign", utm_campaign);
	ReportBuilder.Parameters.Insert("qIsEmptyUtm_campaign", IsBlankString(utm_campaign));
	
	// Execute report builder query
	ReportBuilder.Execute();
	
	// Apply appearance settings to the report template
	vTemplateAttributes = cmApplyReportTemplateAppearance(ThisObject);
	
	// Output report to the spreadsheet
	ReportBuilder.Put(pSpreadsheet);
	//ReportBuilder.Template.Show(); // For debug purpose

	// Apply appearance settings to the report spreadsheet
	cmApplyReportAppearance(ThisObject, pSpreadsheet, vTemplateAttributes);
	
	// Add chart 
	If pAddChart Then
		cmAddReportChart(pSpreadsheet, ThisObject);
	EndIf;
	
	// Restore report default query text
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmGenerate
	
// -----------------------------------------------------------------------------
Procedure pmInitializeReportBuilder() Export
	ReportBuilder = New ReportBuilder();
	
	// Initialize default query text
	QueryText = 
	"SELECT
	|	OnlineRequests.Hotel AS Hotel,
	|	OnlineRequests.ExtSystemCode AS ExtSystemCode,
	|	OnlineRequests.Date AS AccountingDate,
	|	OnlineRequests.Counter AS Counter
	|{SELECT
	|	OnlineRequests.Period,
	|	(BEGINOFPERIOD(OnlineRequests.Period, DAY)) AS PeriodDate,
	|	(WEEK(OnlineRequests.Period)) AS PeriodWeek,
	|	(MONTH(OnlineRequests.Period)) AS PeriodMonth,
	|	(QUARTER(OnlineRequests.Period)) AS PeriodQuarter,
	|	(YEAR(OnlineRequests.Period)) AS PeriodYear,
	|	Hotel.*,
	|	ExtSystemCode,
	|	AccountingDate,
	|	(WEEK(OnlineRequests.Date)) AS AccountingWeek,
	|	(MONTH(OnlineRequests.Date)) AS AccountingMonth,
	|	(QUARTER(OnlineRequests.Date)) AS AccountingQuarter,
	|	(YEAR(OnlineRequests.Date)) AS AccountingYear,
	|	Counter,
	|	OnlineRequests.PeriodFrom,
	|	OnlineRequests.PeriodTo,
	|	OnlineRequests.utm_source,
	|	OnlineRequests.utm_medium,
	|	OnlineRequests.utm_campaign}
	|FROM
	|	InformationRegister.OnlineRequests AS OnlineRequests
	|WHERE
	|	OnlineRequests.Period >= &qPeriodFrom
	|	AND (NOT &qPeriodToIsEmpty
	|				AND OnlineRequests.Period <= &qPeriodTo
	|			OR &qPeriodToIsEmpty)
	|	AND OnlineRequests.Date >= &qDateFrom
	|	AND (NOT &qDateToIsEmpty
	|				AND OnlineRequests.Date <= &qDateTo
	|			OR &qDateToIsEmpty)
	|	AND OnlineRequests.Hotel IN HIERARCHY (&qHotel)
	|	AND (NOT &qIsEmptyExtSystemCode
	|				AND OnlineRequests.ExtSystemCode = &qExtSystemCode
	|			OR &qIsEmptyExtSystemCode)
	|	AND (NOT &qIsEmptyUtm_source
	|				AND OnlineRequests.utm_source = &qutm_source
	|			OR &qIsEmptyUtm_source)
	|	AND (NOT &qIsEmptyUtm_campaign
	|				AND OnlineRequests.utm_campaign = &qutm_campaign
	|			OR &qIsEmptyUtm_campaign)
	|	AND (NOT &qIsEmptyUtm_medium
	|				AND OnlineRequests.utm_medium = &qutm_medium
	|			OR &qIsEmptyUtm_medium)
	|{WHERE
	|	OnlineRequests.Period,
	|	OnlineRequests.Hotel.*,
	|	OnlineRequests.ExtSystemCode,
	|	OnlineRequests.Date AS AccountingDate,
	|	OnlineRequests.Counter,
	|	OnlineRequests.PeriodFrom,
	|	OnlineRequests.PeriodTo,
	|	OnlineRequests.Adults,
	|	OnlineRequests.Children,
	|	OnlineRequests.SessionID,
	|	OnlineRequests.UserID,
	|	OnlineRequests.utm_source,
	|	OnlineRequests.utm_medium,
	|	OnlineRequests.utm_campaign}
	|
	|ORDER BY
	|	OnlineRequests.Hotel,
	|	OnlineRequests.ExtSystemCode,
	|	AccountingDate
	|{ORDER BY
	|	OnlineRequests.Period,
	|	Hotel.*,
	|	ExtSystemCode,
	|	AccountingDate,
	|	Counter,
	|	OnlineRequests.PeriodFrom,
	|	OnlineRequests.PeriodTo,
	|	OnlineRequests.utm_source,
	|	OnlineRequests.utm_medium,
	|	OnlineRequests.utm_campaign}
	|TOTALS
	|	SUM(Counter)
	|BY
	|	Hotel,
	|	ExtSystemCode,
	|	AccountingDate
	|{TOTALS BY
	|	AccountingDate,
	|	Hotel.*,
	|	ExtSystemCode,
	|	OnlineRequests.utm_source,
	|	OnlineRequests.utm_medium,
	|	OnlineRequests.utm_campaign,
	|	(BEGINOFPERIOD(OnlineRequests.Period, DAY)) AS PeriodDate,
	|	(WEEK(OnlineRequests.Period)) AS PeriodWeek,
	|	(MONTH(OnlineRequests.Period)) AS PeriodMonth,
	|	(QUARTER(OnlineRequests.Period)) AS PeriodQuarter,
	|	(YEAR(OnlineRequests.Period)) AS PeriodYear,
	|	(WEEK(OnlineRequests.Date)) AS AccountingWeek,
	|	(MONTH(OnlineRequests.Date)) AS AccountingMonth,
	|	(QUARTER(OnlineRequests.Date)) AS AccountingQuarter,
	|	(YEAR(OnlineRequests.Date)) AS AccountingYear}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("ru='Статистика он-лайн запросов';de='Online-Anfragen Statistiken';en='On-line requests statistics'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
Function pmIsResource(pName) Export
	If pName = "Counter" Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // pmIsResource

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
