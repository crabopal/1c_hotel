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
	If Not ValueIsFilled(PeriodFrom) Then
		PeriodFrom = BegOfDay(CurrentSessionDate()); // For today
		PeriodTo = EndOfDay(PeriodFrom);
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
	If ValueIsFilled(Route) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Направление телефонного звонка '; en = 'Phone call direction '; de = 'Anruf-Richtung '") + 
							 TrimAll(Route) + 
							 ";" + Chars.LF;
	EndIf;					 
	If Not IsBlankString(PhoneNumberFrom) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'От кого (телефон) '; en = 'Phone number from '; de = 'Telefonnummer von '") + 
		                     TrimAll(PhoneNumberFrom) + 
		                     ";" + Chars.LF;
	EndIf;							 
	If Not IsBlankString(PhoneNumberTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Кому (телефон) '; en = 'Phone number to '; de = 'Telefonnummer zu '") + 
		                     TrimAll(PhoneNumberTo) + 
		                     ";" + Chars.LF;
	EndIf;							 
	If ValueIsFilled(Room) Then
		If Not Room.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Room ';ru='Номер ';de='Zimmer '") + 
			                     TrimAll(Room.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Rooms folder ';ru='Группа номеров ';de='Zimmergruppe '") + 
			                     TrimAll(Room.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(Hotel) Then
		If Not Hotel.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Hotel ';ru='Гостиница ';de='Hotel '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Hotels folder ';ru='Группа гостиниц ';de='Hotelsgruppe '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     TrimAll(Hotel.Description) + ";" + Chars.LF;
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
	ReportBuilder.Parameters.Insert("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	ReportBuilder.Parameters.Insert("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qPeriodToIsEmpty", Not ValueIsFilled(PeriodTo));
	ReportBuilder.Parameters.Insert("qRoute", Route);
	ReportBuilder.Parameters.Insert("qRouteIsEmpty", ?(Route = 3, True, False));
	ReportBuilder.Parameters.Insert("qPhoneNumberFrom", "%" + TrimAll(PhoneNumberFrom) + "%");
	ReportBuilder.Parameters.Insert("qPhoneNumberFromIsEmpty", IsBlankString(PhoneNumberFrom));
	ReportBuilder.Parameters.Insert("qPhoneNumberTo", "%" + TrimAll(PhoneNumberTo) + "%");
	ReportBuilder.Parameters.Insert("qPhoneNumberToIsEmpty", IsBlankString(PhoneNumberTo));
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qRoomIsEmpty", Not ValueIsFilled(Room));
	ReportBuilder.Parameters.Insert("qEmptyRoom", Catalogs.Rooms.EmptyRef());
	ReportBuilder.Parameters.Insert("qIncoming", NStr("en='Incoming'; ru='Входящий'; de='Eingehend'"));
	ReportBuilder.Parameters.Insert("qOutcoming",  NStr("en='Outgoing'; ru='Исходящий'; de='Abgehend'"));
	ReportBuilder.Parameters.Insert("qMissed", NStr("en='Missed'; ru='Пропущенный'; de='Verpasste'"));
	
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
	|	CASE
	|		WHEN HistorySimpleCalls.Route = 0
	|			THEN &qIncoming
	|		WHEN HistorySimpleCalls.Route = 1
	|			THEN &qOutcoming
	|		WHEN HistorySimpleCalls.Route = 2
	|			THEN &qMissed
	|		ELSE HistorySimpleCalls.Route
	|	END AS Route,
	|	HistorySimpleCalls.PhoneNumberFrom,
	|	HistorySimpleCalls.PhoneNumberTo,
	|	HistorySimpleCalls.DateFrom,
	|	HistorySimpleCalls.Duration,
	|	HistorySimpleCalls.DateTo,
	|	HistorySimpleCalls.Room,
	|	HistorySimpleCalls.Customer,
	|	HistorySimpleCalls.Client,
	|	HistorySimpleCalls.Workstation,
	|	HistorySimpleCalls.User,
	|	1 AS Quantity
	|{SELECT
	|	HistorySimpleCalls.ID,
	|	Route,
	|	PhoneNumberFrom,
	|	PhoneNumberTo,
	|	DateFrom,
	|	(HOUR(HistorySimpleCalls.DateFrom)) AS CallHour,
	|	(BEGINOFPERIOD(HistorySimpleCalls.DateFrom, DAY)) AS CallDate,
	|	(WEEK(HistorySimpleCalls.DateFrom)) AS CallWeek,
	|	(MONTH(HistorySimpleCalls.DateFrom)) AS CallMonth,
	|	(QUARTER(HistorySimpleCalls.DateFrom)) AS CallQuarter,
	|	(YEAR(HistorySimpleCalls.DateFrom)) AS CallYear,
	|	Duration,
	|	DateTo,
	|	Room.* AS Room,
	|	Customer.* AS Customer,
	|	Client.* AS Client,
	|	Workstation.* AS Workstation,
	|	User.* AS User,
	|	HistorySimpleCalls.Missed,
	|	HistorySimpleCalls.File,
	|	HistorySimpleCalls.Hotel.*,
	|	Quantity AS Quantity}
	|FROM
	|	InformationRegister.HistorySimpleCalls AS HistorySimpleCalls
	|WHERE
	|	(HistorySimpleCalls.Hotel = &qEmptyHotel
	|				AND (HistorySimpleCalls.Room.Owner IN HIERARCHY (&qHotel)
	|					OR &qHotelIsEmpty
	|					OR HistorySimpleCalls.Room = &qEmptyRoom)
	|			OR HistorySimpleCalls.Hotel <> &qEmptyHotel
	|				AND HistorySimpleCalls.Hotel IN HIERARCHY (&qHotel))
	|	AND HistorySimpleCalls.DateFrom >= &qPeriodFrom
	|	AND (HistorySimpleCalls.DateFrom <= &qPeriodTo
	|			OR &qPeriodToIsEmpty)
	|	AND (HistorySimpleCalls.Route = &qRoute
	|			OR &qRouteIsEmpty)
	|	AND (HistorySimpleCalls.PhoneNumberFrom LIKE &qPhoneNumberFrom
	|			OR &qPhoneNumberFromIsEmpty)
	|	AND (HistorySimpleCalls.PhoneNumberTo LIKE &qPhoneNumberTo
	|			OR &qPhoneNumberToIsEmpty)
	|	AND (HistorySimpleCalls.Room IN HIERARCHY (&qRoom)
	|			OR &qRoomIsEmpty)
	|{WHERE
	|	HistorySimpleCalls.ID,
	|	(CASE
	|			WHEN HistorySimpleCalls.Route = 0
	|				THEN &qIncoming
	|			WHEN HistorySimpleCalls.Route = 1
	|				THEN &qOutcoming
	|			WHEN HistorySimpleCalls.Route = 2
	|				THEN &qMissed
	|			ELSE HistorySimpleCalls.Route
	|		END) AS Route,
	|	HistorySimpleCalls.PhoneNumberFrom,
	|	HistorySimpleCalls.PhoneNumberTo,
	|	HistorySimpleCalls.DateFrom,
	|	HistorySimpleCalls.Duration,
	|	HistorySimpleCalls.DateTo,
	|	HistorySimpleCalls.Room.* AS Room,
	|	HistorySimpleCalls.Customer.* AS Customer,
	|	HistorySimpleCalls.Client.* AS Client,
	|	HistorySimpleCalls.Workstation.* AS Workstation,
	|	HistorySimpleCalls.User.* AS User,
	|	HistorySimpleCalls.Hotel.*,
	|	HistorySimpleCalls.Missed,
	|	HistorySimpleCalls.File}
	|
	|ORDER BY
	|	HistorySimpleCalls.DateFrom
	|{ORDER BY
	|	HistorySimpleCalls.ID,
	|	Route,
	|	PhoneNumberFrom,
	|	PhoneNumberTo,
	|	DateFrom,
	|	Duration,
	|	DateTo,
	|	Room.* AS Room,
	|	Customer.* AS Customer,
	|	Client.* AS Client,
	|	Workstation.* AS Workstation,
	|	User.* AS User,
	|	HistorySimpleCalls.Hotel.*,
	|	HistorySimpleCalls.Missed,
	|	HistorySimpleCalls.File}
	|TOTALS
	|	SUM(Quantity)
	|BY
	|	OVERALL
	|{TOTALS BY
	|	Route,
	|	PhoneNumberFrom,
	|	PhoneNumberTo,
	|	(HOUR(HistorySimpleCalls.DateFrom)) AS CallHour,
	|	(BEGINOFPERIOD(HistorySimpleCalls.DateFrom, DAY)) AS CallDate,
	|	(WEEK(HistorySimpleCalls.DateFrom)) AS CallWeek,
	|	(MONTH(HistorySimpleCalls.DateFrom)) AS CallMonth,
	|	(QUARTER(HistorySimpleCalls.DateFrom)) AS CallQuarter,
	|	(YEAR(HistorySimpleCalls.DateFrom)) AS CallYear,
	|	Duration,
	|	Room.* AS Room,
	|	Customer.* AS Customer,
	|	Client.* AS Client,
	|	Workstation.* AS Workstation,
	|	User.* AS User,
	|	HistorySimpleCalls.Hotel.*,
	|	HistorySimpleCalls.Missed,
	|	HistorySimpleCalls.File}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("ru='История звонков';de='Anrufliste';en='Phone calls history'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
