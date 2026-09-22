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
	If ValueIsFilled(PhoneCallType) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Тип телефонного разговора '; en = 'Phone call type '; de = 'Telefon Anruf Typ '") + 
							 TrimAll(PhoneCallType) + 
							 ";" + Chars.LF;
	EndIf;					 
	If ValueIsFilled(PhoneNumber) Then
		If Not PhoneNumber.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Телефонный номер '; en = 'Phone number '; de = 'Telefonnummer '") + 
			                     TrimAll(PhoneNumber.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа телефонных номеров '; en = 'Phone numbers folder '; de = 'Telefonnummergruppe '") + 
			                     TrimAll(PhoneNumber.Description) + 
			                     ";" + Chars.LF;
		EndIf;
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
	ReportBuilder.Parameters.Insert("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qPhoneCallType", PhoneCallType);
	ReportBuilder.Parameters.Insert("qPhoneCallTypeIsEmpty", Not ValueIsFilled(PhoneCallType));
	ReportBuilder.Parameters.Insert("qPhoneNumber", PhoneNumber);
	ReportBuilder.Parameters.Insert("qPhoneNumberIsEmpty", Not ValueIsFilled(PhoneNumber));
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qRoomIsEmpty", Not ValueIsFilled(Room));
	
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
	|	PhoneCalls.Period,
	|	PhoneCalls.PhoneCallDate AS PhoneCallDate,
	|	PhoneCalls.PhoneCallType,
	|	PhoneCalls.PhoneNumber,
	|	PhoneCalls.Room,
	|	PhoneCalls.Quantity AS Quantity,
	|	PhoneCalls.Price,
	|	PhoneCalls.Currency,
	|	PhoneCalls.Sum AS Sum,
	|	PhoneCalls.PerCallSum AS PerCallSum,
	|	PhoneCalls.TargetPhoneNumber,
	|	PhoneCalls.PhoneCallRegion,
	|	PhoneCalls.Remarks,
	|	PhoneCalls.Folio
	|{SELECT
	|	Period,
	|	(HOUR(PhoneCalls.Period)) AS AccountingHour,
	|	(BEGINOFPERIOD(PhoneCalls.Period, DAY)) AS AccountingDate,
	|	(WEEK(PhoneCalls.Period)) AS AccountingWeek,
	|	(MONTH(PhoneCalls.Period)) AS AccountingMonth,
	|	(QUARTER(PhoneCalls.Period)) AS AccountingQuarter,
	|	(YEAR(PhoneCalls.Period)) AS AccountingYear,
	|	PhoneCalls.Recorder.*,
	|	PhoneCallDate,
	|	(HOUR(PhoneCalls.PhoneCallDate)) AS CallHour,
	|	(BEGINOFPERIOD(PhoneCalls.PhoneCallDate, DAY)) AS CallDate,
	|	(WEEK(PhoneCalls.PhoneCallDate)) AS CallWeek,
	|	(MONTH(PhoneCalls.PhoneCallDate)) AS CallMonth,
	|	(QUARTER(PhoneCalls.PhoneCallDate)) AS CallQuarter,
	|	(YEAR(PhoneCalls.PhoneCallDate)) AS CallYear,
	|	PhoneCallType.*,
	|	PhoneNumber.*,
	|	Room.*,
	|	Quantity,
	|	Price,
	|	Currency.*,
	|	Sum,
	|	PerCallSum,
	|	TargetPhoneNumber,
	|	PhoneCallRegion,
	|	Remarks,
	|	Folio.*,
	|	PhoneCalls.Hotel.*,
	|	PhoneCalls.PhoneCallService.*,
	|	PhoneCalls.Company.*,
	|	PhoneCalls.PhoneCallPriceIsWithVAT,
	|	PhoneCalls.Unit,
	|	PhoneCalls.VATRate.*,
	|	PhoneCalls.VATSum,
	|	PhoneCalls.Charge.*,
	|	PhoneCalls.PerCallService.*,
	|	PhoneCalls.PerCallServiceVATRate.*,
	|	PhoneCalls.PerCallVATSum,
	|	PhoneCalls.PerCallCharge.*,
	|	PhoneCalls.ExchangeRateDate,
	|	PhoneCalls.Author.*,
	|	PhoneCalls.PointInTime}
	|FROM
	|	AccumulationRegister.PhoneCalls AS PhoneCalls
	|WHERE
	|	(PhoneCalls.Hotel IN HIERARCHY (&qHotel)
	|			OR &qHotelIsEmpty)
	|	AND PhoneCalls.PhoneCallDate >= &qPeriodFrom
	|	AND PhoneCalls.PhoneCallDate < &qPeriodTo
	|	AND (PhoneCalls.PhoneCallType = &qPhoneCallType
	|			OR &qPhoneCallTypeIsEmpty)
	|	AND (PhoneCalls.PhoneNumber IN HIERARCHY (&qPhoneNumber)
	|			OR &qPhoneNumberIsEmpty)
	|	AND (PhoneCalls.Room IN HIERARCHY (&qRoom)
	|			OR &qRoomIsEmpty)
	|{WHERE
	|	PhoneCalls.Period,
	|	PhoneCalls.Recorder.*,
	|	PhoneCalls.PhoneCallDate,
	|	PhoneCalls.PhoneCallType.*,
	|	PhoneCalls.PhoneNumber.*,
	|	PhoneCalls.Room.*,
	|	PhoneCalls.Quantity,
	|	PhoneCalls.Price,
	|	PhoneCalls.Currency.*,
	|	PhoneCalls.Sum,
	|	PhoneCalls.PerCallSum,
	|	PhoneCalls.TargetPhoneNumber,
	|	PhoneCalls.PhoneCallRegion,
	|	PhoneCalls.Remarks,
	|	PhoneCalls.Folio.*,
	|	PhoneCalls.Hotel.*,
	|	PhoneCalls.PhoneCallService.*,
	|	PhoneCalls.Company.*,
	|	PhoneCalls.PhoneCallPriceIsWithVAT,
	|	PhoneCalls.Unit,
	|	PhoneCalls.VATRate.*,
	|	PhoneCalls.VATSum,
	|	PhoneCalls.Charge.*,
	|	PhoneCalls.PerCallService.*,
	|	PhoneCalls.PerCallServiceVATRate.*,
	|	PhoneCalls.PerCallVATSum,
	|	PhoneCalls.PerCallCharge.*,
	|	PhoneCalls.ExchangeRateDate,
	|	PhoneCalls.CurrencyExchangeRate,
	|	PhoneCalls.Author.*,
	|	PhoneCalls.PointInTime}
	|
	|ORDER BY
	|	PhoneCallDate
	|{ORDER BY
	|	Period,
	|	PhoneCalls.Recorder.*,
	|	PhoneCallDate,
	|	PhoneCallType.*,
	|	PhoneNumber.*,
	|	Room.*,
	|	Quantity,
	|	Price,
	|	Currency.*,
	|	Sum,
	|	PerCallSum,
	|	TargetPhoneNumber,
	|	PhoneCallRegion,
	|	Folio.*,
	|	PhoneCalls.Hotel.*,
	|	PhoneCalls.PhoneCallService.*,
	|	PhoneCalls.Company.*,
	|	PhoneCalls.VATRate.*,
	|	PhoneCalls.VATSum,
	|	PhoneCalls.Charge.*,
	|	PhoneCalls.PerCallService.*,
	|	PhoneCalls.PerCallServiceVATRate.*,
	|	PhoneCalls.PerCallVATSum,
	|	PhoneCalls.PerCallCharge.*,
	|	PhoneCalls.ExchangeRateDate,
	|	PhoneCalls.CurrencyExchangeRate,
	|	PhoneCalls.Author.*,
	|	PhoneCalls.PointInTime}
	|TOTALS
	|	SUM(Quantity),
	|	SUM(Sum),
	|	SUM(PerCallSum)
	|BY
	|	OVERALL
	|{TOTALS BY
	|	(HOUR(PhoneCalls.Period)) AS AccountingHour,
	|	(BEGINOFPERIOD(PhoneCalls.Period, DAY)) AS AccountingDate,
	|	(WEEK(PhoneCalls.Period)) AS AccountingWeek,
	|	(MONTH(PhoneCalls.Period)) AS AccountingMonth,
	|	(QUARTER(PhoneCalls.Period)) AS AccountingQuarter,
	|	(YEAR(PhoneCalls.Period)) AS AccountingYear,
	|	(HOUR(PhoneCalls.PhoneCallDate)) AS CallHour,
	|	(BEGINOFPERIOD(PhoneCalls.PhoneCallDate, DAY)) AS CallDate,
	|	(WEEK(PhoneCalls.PhoneCallDate)) AS CallWeek,
	|	(MONTH(PhoneCalls.PhoneCallDate)) AS CallMonth,
	|	(QUARTER(PhoneCalls.PhoneCallDate)) AS CallQuarter,
	|	(YEAR(PhoneCalls.PhoneCallDate)) AS CallYear,
	|	PhoneCallType.*,
	|	PhoneNumber.*,
	|	Room.*,
	|	Currency.*,
	|	TargetPhoneNumber,
	|	PhoneCallRegion,
	|	Folio.*,
	|	PhoneCalls.Hotel.*,
	|	PhoneCalls.PhoneCallService.*,
	|	PhoneCalls.Company.*,
	|	PhoneCalls.PhoneCallPriceIsWithVAT,
	|	PhoneCalls.Unit,
	|	PhoneCalls.VATRate.*,
	|	PhoneCalls.PerCallService.*,
	|	PhoneCalls.PerCallServiceVATRate.*,
	|	PhoneCalls.ExchangeRateDate,
	|	PhoneCalls.Author.*}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Phone calls';RU='Телефонные разговоры';de='Telefongespräche'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
