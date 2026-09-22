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
	If ValueIsFilled(RoomType) Then
		If Not RoomType.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Room type ';ru='Тип номера ';de='Zimmertyp '") + 
			                     TrimAll(RoomType.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Room types folder ';ru='Группа типов номеров ';de='Zimmertypengruppe '") + 
			                     TrimAll(RoomType.Description) + 
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
	If ValueIsFilled(BoardPlace) Then
		If Not BoardPlace.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Место питания '; en = 'Board place '; de = 'Essenort '") + 
			                     TrimAll(BoardPlace.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа мест питания '; en = 'Board places folder '; de = 'Essenortgruppe '") + 
			                     TrimAll(BoardPlace.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;						 
	If ValueIsFilled(Service) Then
		If Not Service.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Service ';ru='Услуга ';de='Dienstleistung '") + 
			                     TrimAll(Service.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа услуг '; en = 'Services folder '; de = 'Dienstleistungengruppe '") + 
			                     TrimAll(Service.Description) + 
			                     ";" + Chars.LF;
		EndIf;
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
	If ShowPlan Then
		vParamPresentation = vParamPresentation + NStr("ru = 'План/факт'; en = 'Plan/Fact'; de = 'Plan/Faktum'") +
		                     ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(Hotel) Then
		If Not Hotel.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Hotel ';ru='Гостиница ';de='Hotel '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Hotels folder ';ru='Группа гостиниц ';de='Hotelsgruppe '") + 
			                     TrimAll(Hotel.Description) + 
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
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	vForecastStartDate = tcOnServer.GetForecastStartDate(Hotel);
	ReportBuilder.Parameters.Insert("qForecastPeriodFrom", Max(vForecastStartDate, PeriodFrom));
	ReportBuilder.Parameters.Insert("qService", Service);
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qRoomIsEmpty", Not ValueIsFilled(Room));
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qRoomTypeIsEmpty", Not ValueIsFilled(RoomType));
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
	ReportBuilder.Parameters.Insert("qShowPlan", ShowPlan);
	ReportBuilder.Parameters.Insert("qBoardPlace", BoardPlace);
	ReportBuilder.Parameters.Insert("qBoardPlaceIsEmpty", Not ValueIsFilled(BoardPlace));
	
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
	|	Registration.Hotel AS Hotel,
	|	Registration.Service AS Service,
	|	Registration.Period AS Period,
	|	Registration.Room AS Room,
	|	Registration.Resource AS Resource,
	|	Registration.Client AS Client,
	|	Registration.GuestGroup AS GuestGroup,
	|	Registration.Folio AS Folio,
	|	Registration.FolioCurrency AS FolioCurrency,
	|	Registration.FolioDateTimeFrom AS FolioDateTimeFrom,
	|	Registration.FolioDateTimeTo AS FolioDateTimeTo,
	|	Registration.Recorder AS Recorder,
	|	Registration.Author AS Author,
	|	Registration.Quantity AS Quantity,
	|	Registration.Sum AS Sum,
	|	Registration.PlanQuantity AS PlanQuantity,
	|	Registration.PlanSum AS PlanSum
	|{SELECT
	|	Hotel.*,
	|	Service.*,
	|	Period,
	|	(BEGINOFPERIOD(Registration.AccountingDate, DAY)) AS AccountingDate,
	|	(BEGINOFPERIOD(Registration.AccountingDate, MONTH)) AS AccountingMonth,
	|	(HOUR(Registration.Period)) AS RegistrationHour,
	|	Room.*,
	|	Registration.RoomType.* AS RoomType,
	|	Resource.*,
	|	Client.*,
	|	GuestGroup.*,
	|	Registration.Customer.* AS Customer,
	|	Registration.BoardPlace.* AS BoardPlace,
	|	Registration.AccommodationType.* AS AccommodationType,
	|	Folio.*,
	|	FolioCurrency.*,
	|	FolioDateTimeFrom,
	|	FolioDateTimeTo,
	|	Recorder.*,
	|	Author.*,
	|	Registration.Price,
	|	Registration.Unit,
	|	Registration.ParentDoc.*,
	|	Registration.Remarks,
	|	Quantity,
	|	Sum,
	|	PlanQuantity,
	|	PlanSum}
	|FROM
	|	(SELECT
	|		ServiceRegistration.Hotel AS Hotel,
	|		ServiceRegistration.Service AS Service,
	|		ServiceRegistration.AccountingDate AS AccountingDate,
	|		ServiceRegistration.Period AS Period,
	|		ServiceRegistration.Room AS Room,
	|		ServiceRegistration.RoomType AS RoomType,
	|		ServiceRegistration.Resource AS Resource,
	|		ServiceRegistration.Client AS Client,
	|		ServiceRegistration.GuestGroup AS GuestGroup,
	|		ServiceRegistration.Customer AS Customer,
	|		ServiceRegistration.BoardPlace AS BoardPlace,
	|		ServiceRegistration.AccommodationType AS AccommodationType,
	|		ServiceRegistration.Folio AS Folio,
	|		ServiceRegistration.FolioCurrency AS FolioCurrency,
	|		ServiceRegistration.FolioDateTimeFrom AS FolioDateTimeFrom,
	|		ServiceRegistration.FolioDateTimeTo AS FolioDateTimeTo,
	|		ServiceRegistration.ParentDoc AS ParentDoc,
	|		ServiceRegistration.Remarks AS Remarks,
	|		ServiceRegistration.Recorder AS Recorder,
	|		ServiceRegistration.Author AS Author,
	|		ServiceRegistration.Unit AS Unit,
	|		ServiceRegistration.Price AS Price,
	|		SUM(ServiceRegistration.Quantity) AS Quantity,
	|		SUM(ServiceRegistration.Sum) AS Sum,
	|		SUM(ServiceRegistration.PlanQuantity) AS PlanQuantity,
	|		SUM(ServiceRegistration.PlanSum) AS PlanSum
	|	FROM
	|		(SELECT
	|			ServiceRegistrations.Hotel AS Hotel,
	|			ServiceRegistrations.Service AS Service,
	|			ServiceRegistrations.AccountingDate AS AccountingDate,
	|			ServiceRegistrations.Date AS Period,
	|			ServiceRegistrations.Room AS Room,
	|			ServiceRegistrations.Room.RoomType AS RoomType,
	|			ServiceRegistrations.Resource AS Resource,
	|			ServiceRegistrations.Client AS Client,
	|			ServiceRegistrations.GuestGroup AS GuestGroup,
	|			ServiceRegistrations.Folio.Customer AS Customer,
	|			ServiceRegistrations.BoardPlace AS BoardPlace,
	|			ServiceRegistrations.Folio AS Folio,
	|			ServiceRegistrations.FolioCurrency AS FolioCurrency,
	|			ServiceRegistrations.Folio.DateTimeFrom AS FolioDateTimeFrom,
	|			ServiceRegistrations.Folio.DateTimeTo AS FolioDateTimeTo,
	|			ServiceRegistrations.ParentDoc AS ParentDoc,
	|			ServiceRegistrations.ParentDoc.AccommodationType AS AccommodationType,
	|			CAST(ServiceRegistrations.Remarks AS STRING(1024)) AS Remarks,
	|			ServiceRegistrations.Ref AS Recorder,
	|			ServiceRegistrations.Author AS Author,
	|			ServiceRegistrations.Unit AS Unit,
	|			ServiceRegistrations.Price AS Price,
	|			ServiceRegistrations.Quantity AS Quantity,
	|			ServiceRegistrations.Sum AS Sum,
	|			0 AS PlanQuantity,
	|			0 AS PlanSum
	|		FROM
	|			Document.ServiceRegistration AS ServiceRegistrations
	|		WHERE
	|			ServiceRegistrations.Posted
	|			AND ServiceRegistrations.Hotel IN HIERARCHY(&qHotel)
	|			AND ServiceRegistrations.AccountingDate BETWEEN &qPeriodFrom AND &qPeriodTo
	|			AND ServiceRegistrations.Service IN HIERARCHY(&qService)
	|			AND (ServiceRegistrations.Room IN HIERARCHY (&qRoom)
	|					OR &qRoomIsEmpty)
	|			AND (ServiceRegistrations.Room.RoomType IN HIERARCHY (&qRoomType)
	|					OR &qRoomTypeIsEmpty)
	|			AND (ServiceRegistrations.Service IN (&qServicesList)
	|					OR NOT &qUseServicesList)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			ServiceSales.Hotel,
	|			ServiceSales.Service,
	|			ServiceSales.AccountingDate,
	|			ServiceSales.Period,
	|			ServiceSales.Room,
	|			ServiceSales.RoomType,
	|			ServiceSales.Resource,
	|			ServiceSales.Client,
	|			ServiceSales.GuestGroup,
	|			ServiceSales.Customer,
	|			ServiceSales.BoardPlace,
	|			ServiceSales.Folio,
	|			ServiceSales.Folio.FolioCurrency,
	|			ServiceSales.Folio.DateTimeFrom,
	|			ServiceSales.Folio.DateTimeTo,
	|			ServiceSales.ParentDoc,
	|			ServiceSales.AccommodationType,
	|			CAST(ServiceSales.Recorder.Remarks AS STRING(1024)),
	|			ServiceSales.Recorder,
	|			ServiceSales.Author,
	|			ServiceSales.Service.Unit,
	|			ServiceSales.Price,
	|			0,
	|			0,
	|			ServiceSales.Quantity,
	|			ServiceSales.Sales
	|		FROM
	|			AccumulationRegister.Sales AS ServiceSales
	|		WHERE
	|			&qShowPlan
	|			AND ServiceSales.Hotel IN HIERARCHY(&qHotel)
	|			AND ServiceSales.Period BETWEEN &qPeriodFrom AND &qPeriodTo
	|			AND ServiceSales.Service IN HIERARCHY(&qService)
	|			AND (ServiceSales.Room IN HIERARCHY (&qRoom)
	|					OR &qRoomIsEmpty)
	|			AND (ServiceSales.RoomType IN HIERARCHY (&qRoomType)
	|					OR &qRoomTypeIsEmpty)
	|			AND (ServiceSales.Service IN (&qServicesList)
	|					OR NOT &qUseServicesList)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			ServiceSalesForecast.Hotel,
	|			ServiceSalesForecast.Service,
	|			ServiceSalesForecast.AccountingDate,
	|			ServiceSalesForecast.Period,
	|			ServiceSalesForecast.Room,
	|			ServiceSalesForecast.RoomType,
	|			ServiceSalesForecast.Resource,
	|			ServiceSalesForecast.Client,
	|			ServiceSalesForecast.GuestGroup,
	|			ServiceSalesForecast.Customer,
	|			ServiceSalesForecast.BoardPlace,
	|			ServiceSalesForecast.Folio,
	|			ServiceSalesForecast.Folio.FolioCurrency,
	|			ServiceSalesForecast.Folio.DateTimeFrom,
	|			ServiceSalesForecast.Folio.DateTimeTo,
	|			ServiceSalesForecast.ParentDoc,
	|			ServiceSalesForecast.AccommodationType,
	|			CAST(ServiceSalesForecast.Recorder.Remarks AS STRING(1024)),
	|			ServiceSalesForecast.Recorder,
	|			ServiceSalesForecast.Author,
	|			ServiceSalesForecast.Service.Unit,
	|			ServiceSalesForecast.Price,
	|			0,
	|			0,
	|			ServiceSalesForecast.Quantity,
	|			ServiceSalesForecast.Sales
	|		FROM
	|			AccumulationRegister.SalesForecast AS ServiceSalesForecast
	|		WHERE
	|			&qShowPlan
	|			AND ServiceSalesForecast.Hotel IN HIERARCHY(&qHotel)
	|			AND ServiceSalesForecast.Period >= &qForecastPeriodFrom
	|			AND ServiceSalesForecast.Period <= &qPeriodTo
	|			AND ServiceSalesForecast.Service IN HIERARCHY(&qService)
	|			AND (ServiceSalesForecast.Room IN HIERARCHY (&qRoom)
	|					OR &qRoomIsEmpty)
	|			AND (ServiceSalesForecast.RoomType IN HIERARCHY (&qRoomType)
	|					OR &qRoomTypeIsEmpty)
	|			AND (ServiceSalesForecast.Service IN (&qServicesList)
	|					OR NOT &qUseServicesList)) AS ServiceRegistration
	|	
	|	GROUP BY
	|		ServiceRegistration.Hotel,
	|		ServiceRegistration.Service,
	|		ServiceRegistration.AccountingDate,
	|		ServiceRegistration.Period,
	|		ServiceRegistration.Room,
	|		ServiceRegistration.RoomType,
	|		ServiceRegistration.Resource,
	|		ServiceRegistration.Client,
	|		ServiceRegistration.GuestGroup,
	|		ServiceRegistration.Customer,
	|		ServiceRegistration.BoardPlace,
	|		ServiceRegistration.AccommodationType,
	|		ServiceRegistration.Folio,
	|		ServiceRegistration.FolioCurrency,
	|		ServiceRegistration.FolioDateTimeFrom,
	|		ServiceRegistration.FolioDateTimeTo,
	|		ServiceRegistration.ParentDoc,
	|		ServiceRegistration.Remarks,
	|		ServiceRegistration.Recorder,
	|		ServiceRegistration.Author,
	|		ServiceRegistration.Unit,
	|		ServiceRegistration.Price) AS Registration
	|WHERE
	|	(&qBoardPlaceIsEmpty
	|			OR NOT &qBoardPlaceIsEmpty
	|				AND Registration.BoardPlace IN HIERARCHY (&qBoardPlace))
	|{WHERE
	|	Registration.Hotel.*,
	|	Registration.Service.*,
	|	Registration.Period AS Period,
	|	(BEGINOFPERIOD(Registration.AccountingDate, DAY)) AS AccountingDate,
	|	(BEGINOFPERIOD(Registration.AccountingDate, MONTH)) AS AccountingMonth,
	|	(HOUR(Registration.Period)) AS RegistrationHour,
	|	Registration.Room.*,
	|	Registration.RoomType.*,
	|	Registration.Resource.*,
	|	Registration.Client.*,
	|	Registration.GuestGroup.*,
	|	Registration.Customer.* AS Customer,
	|	Registration.BoardPlace.* AS BoardPlace,
	|	Registration.AccommodationType.* AS AccommodationType,
	|	Registration.Folio.*,
	|	Registration.FolioCurrency.*,
	|	Registration.Recorder.*,
	|	Registration.Author.*,
	|	Registration.ParentDoc.*,
	|	Registration.Remarks,
	|	Registration.Price,
	|	Registration.Unit,
	|	Registration.Quantity,
	|	Registration.Sum,
	|	Registration.PlanQuantity,
	|	Registration.PlanSum}
	|
	|ORDER BY
	|	Hotel,
	|	Service,
	|	Period
	|{ORDER BY
	|	Hotel.*,
	|	Service.*,
	|	Period,
	|	(HOUR(Registration.Period)) AS RegistrationHour,
	|	(BEGINOFPERIOD(Registration.AccountingDate, DAY)) AS AccountingDate,
	|	(BEGINOFPERIOD(Registration.AccountingDate, MONTH)) AS AccountingMonth,
	|	Room.*,
	|	Registration.RoomType.*,
	|	Resource.*,
	|	Client.*,
	|	GuestGroup.*,
	|	Registration.Customer.* AS Customer,
	|	Registration.BoardPlace.* AS BoardPlace,
	|	Registration.AccommodationType.* AS AccommodationType,
	|	Folio.*,
	|	FolioCurrency.*,
	|	FolioDateTimeFrom,
	|	FolioDateTimeTo,
	|	Recorder.*,
	|	Author.*,
	|	Registration.ParentDoc.*,
	|	Registration.Remarks,
	|	Registration.Price,
	|	Registration.Unit AS Quantity,
	|	Sum,
	|	PlanQuantity,
	|	PlanSum}
	|TOTALS
	|	SUM(Quantity),
	|	SUM(Sum),
	|	SUM(PlanQuantity),
	|	SUM(PlanSum)
	|BY
	|	OVERALL,
	|	Hotel,
	|	Service
	|{TOTALS BY
	|	Hotel.*,
	|	Service.*,
	|	(BEGINOFPERIOD(Registration.AccountingDate, DAY)) AS AccountingDate,
	|	(BEGINOFPERIOD(Registration.AccountingDate, MONTH)) AS AccountingMonth,
	|	(HOUR(Registration.Period)) AS RegistrationHour,
	|	Room.*,
	|	Registration.RoomType.*,
	|	Resource.*,
	|	Client.*,
	|	GuestGroup.*,
	|	Registration.Customer.* AS Customer,
	|	Registration.BoardPlace.* AS BoardPlace,
	|	Registration.AccommodationType.* AS AccommodationType,
	|	Folio.*,
	|	FolioCurrency.*,
	|	Recorder.*,
	|	Author.*,
	|	Registration.ParentDoc.*,
	|	Registration.Unit,
	|	Registration.Price}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("en='Registered services';de='In der Tat registriert Dienstleistungen';ru='Фактически зарегистрированные услуги'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
