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
	If Not IsBlankString(RoomServiceChargeType) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Тип начисления на номер '; en = 'Room service charge type '; de = 'Zimmerservice Gebühr Typ '") + 
							 TrimAll(RoomServiceChargeType) + 
							 ";" + Chars.LF;
	EndIf;					 
	If ValueIsFilled(RoomService) Then
		If Not RoomService.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Услуга '; en = 'Service '; de = 'Dienstleistung '") + 
			                     TrimAll(RoomService.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа услуг '; en = 'Services folder '; de = 'Dienstleistungengruppe '") + 
			                     TrimAll(RoomService.Description) + 
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
			vParamPresentation = vParamPresentation + NStr("en='Hotels folder ';ru='Группа гостиниц ';de='Hotelsgruppe '") + 
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
	ReportBuilder.Parameters.Insert("qRoomServiceChargeType", RoomServiceChargeType);
	ReportBuilder.Parameters.Insert("qRoomServiceChargeTypeIsEmpty", IsBlankString(RoomServiceChargeType));
	ReportBuilder.Parameters.Insert("qRoomService", RoomService);
	ReportBuilder.Parameters.Insert("qRoomServiceIsEmpty", Not ValueIsFilled(RoomService));
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
	|	RoomServices.Period,
	|	RoomServices.ServiceDate AS ServiceDate,
	|	RoomServices.RoomServiceChargeType,
	|	RoomServices.RoomService,
	|	RoomServices.Room,
	|	RoomServices.Quantity AS Quantity,
	|	RoomServices.Price,
	|	RoomServices.Currency,
	|	RoomServices.Sum AS Sum,
	|	RoomServices.FixedServiceSum AS FixedServiceSum,
	|	RoomServices.Remarks,
	|	RoomServices.Folio
	|{SELECT
	|	Period,
	|	(HOUR(RoomServices.Period)) AS AccountingHour,
	|	(BEGINOFPERIOD(RoomServices.Period, DAY)) AS AccountingDate,
	|	(WEEK(RoomServices.Period)) AS AccountingWeek,
	|	(MONTH(RoomServices.Period)) AS AccountingMonth,
	|	(QUARTER(RoomServices.Period)) AS AccountingQuarter,
	|	(YEAR(RoomServices.Period)) AS AccountingYear,
	|	RoomServices.Recorder.*,
	|	ServiceDate,
	|	(HOUR(RoomServices.ServiceDate)) AS ServiceHour,
	|	(BEGINOFPERIOD(RoomServices.ServiceDate, DAY)) AS ServiceDay,
	|	(WEEK(RoomServices.ServiceDate)) AS ServiceWeek,
	|	(MONTH(RoomServices.ServiceDate)) AS ServiceMonth,
	|	(QUARTER(RoomServices.ServiceDate)) AS ServiceQuarter,
	|	(YEAR(RoomServices.ServiceDate)) AS ServiceYear,
	|	RoomServiceChargeType,
	|	RoomService.*,
	|	Room.*,
	|	Quantity,
	|	Price,
	|	Currency.*,
	|	Sum,
	|	FixedServiceSum,
	|	Remarks,
	|	Folio.*,
	|	RoomServices.Hotel.*,
	|	RoomServices.Company.*,
	|	RoomServices.RoomServicePriceIsWithVAT,
	|	RoomServices.Unit,
	|	RoomServices.VATRate.*,
	|	RoomServices.VATSum,
	|	RoomServices.Charge.*,
	|	RoomServices.FixedService.*,
	|	RoomServices.FixedServiceVATRate.*,
	|	RoomServices.FixedServiceVATSum,
	|	RoomServices.FixedServiceCharge.*,
	|	RoomServices.ExchangeRateDate,
	|	RoomServices.Author.*,
	|	RoomServices.PointInTime}
	|FROM
	|	AccumulationRegister.RoomServices AS RoomServices
	|WHERE
	|	(RoomServices.Hotel IN HIERARCHY (&qHotel)
	|			OR &qHotelIsEmpty)
	|	AND RoomServices.ServiceDate >= &qPeriodFrom
	|	AND RoomServices.ServiceDate < &qPeriodTo
	|	AND (RoomServices.RoomServiceChargeType = &qRoomServiceChargeType
	|			OR &qRoomServiceChargeTypeIsEmpty)
	|	AND (RoomServices.RoomService IN HIERARCHY (&qRoomService)
	|			OR &qRoomServiceIsEmpty)
	|	AND (RoomServices.Room IN HIERARCHY (&qRoom)
	|			OR &qRoomIsEmpty)
	|{WHERE
	|	RoomServices.Period,
	|	RoomServices.Recorder.*,
	|	RoomServices.ServiceDate,
	|	RoomServices.RoomServiceChargeType,
	|	RoomServices.RoomService.*,
	|	RoomServices.Room.*,
	|	RoomServices.Quantity,
	|	RoomServices.Price,
	|	RoomServices.Currency.*,
	|	RoomServices.Sum,
	|	RoomServices.FixedServiceSum,
	|	RoomServices.Remarks,
	|	RoomServices.Folio.*,
	|	RoomServices.Hotel.*,
	|	RoomServices.Company.*,
	|	RoomServices.RoomServicePriceIsWithVAT,
	|	RoomServices.Unit,
	|	RoomServices.VATRate.*,
	|	RoomServices.VATSum,
	|	RoomServices.Charge.*,
	|	RoomServices.FixedService.*,
	|	RoomServices.FixedServiceVATRate.*,
	|	RoomServices.FixedServiceVATSum,
	|	RoomServices.FixedServiceCharge.*,
	|	RoomServices.ExchangeRateDate,
	|	RoomServices.CurrencyExchangeRate,
	|	RoomServices.Author.*,
	|	RoomServices.PointInTime}
	|
	|ORDER BY
	|	ServiceDate
	|{ORDER BY
	|	Period,
	|	RoomServices.Recorder.*,
	|	ServiceDate,
	|	RoomServiceChargeType,
	|	RoomService.*,
	|	Room.*,
	|	Quantity,
	|	Price,
	|	Currency.*,
	|	Sum,
	|	FixedServiceSum,
	|	Folio.*,
	|	RoomServices.Hotel.*,
	|	RoomServices.Company.*,
	|	RoomServices.VATRate.*,
	|	RoomServices.VATSum,
	|	RoomServices.Charge.*,
	|	RoomServices.FixedService.*,
	|	RoomServices.FixedServiceVATRate.*,
	|	RoomServices.FixedServiceVATSum,
	|	RoomServices.FixedServiceCharge.*,
	|	RoomServices.ExchangeRateDate,
	|	RoomServices.CurrencyExchangeRate,
	|	RoomServices.Author.*,
	|	RoomServices.PointInTime}
	|TOTALS
	|	SUM(Quantity),
	|	SUM(Sum),
	|	SUM(FixedServiceSum)
	|BY
	|	OVERALL
	|{TOTALS BY
	|	(HOUR(RoomServices.Period)) AS AccountingHour,
	|	(BEGINOFPERIOD(RoomServices.Period, DAY)) AS AccountingDate,
	|	(WEEK(RoomServices.Period)) AS AccountingWeek,
	|	(MONTH(RoomServices.Period)) AS AccountingMonth,
	|	(QUARTER(RoomServices.Period)) AS AccountingQuarter,
	|	(YEAR(RoomServices.Period)) AS AccountingYear,
	|	(HOUR(RoomServices.ServiceDate)) AS ServiceHour,
	|	(BEGINOFPERIOD(RoomServices.ServiceDate, DAY)) AS ServiceDay,
	|	(WEEK(RoomServices.ServiceDate)) AS ServiceWeek,
	|	(MONTH(RoomServices.ServiceDate)) AS ServiceMonth,
	|	(QUARTER(RoomServices.ServiceDate)) AS ServiceQuarter,
	|	(YEAR(RoomServices.ServiceDate)) AS ServiceYear,
	|	RoomServiceChargeType,
	|	RoomService.*,
	|	Room.*,
	|	Currency.*,
	|	Folio.*,
	|	RoomServices.Hotel.*,
	|	RoomServices.Company.*,
	|	RoomServices.RoomServicePriceIsWithVAT,
	|	RoomServices.Unit,
	|	RoomServices.VATRate.*,
	|	RoomServices.FixedService.*,
	|	RoomServices.FixedServiceVATRate.*,
	|	RoomServices.ExchangeRateDate,
	|	RoomServices.Author.*}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Room services';RU='Услуги на номера';de='Dienstleistungen pro Zimmer'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
