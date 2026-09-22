
#Region Public

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
	If ValueIsFilled(Resource) Then
		vParamPresentation = vParamPresentation + NStr("en='Resource ';ru='Ресурс ';de='Ressource '") + 
							 TrimAll(Resource.Description) + 
							 ";" + Chars.LF;
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
	vForecastStartDate = tcOnServer.GetForecastStartDate(Hotel);
	ReportBuilder.Parameters.Insert("qForecastPeriodFrom", Max(BegOfDay(PeriodFrom), vForecastStartDate));
	ReportBuilder.Parameters.Insert("qForecastPeriodTo", ?(ValueIsFilled(PeriodTo), Max(PeriodTo, EndOfDay(vForecastStartDate-24*3600)), '00010101'));
	ReportBuilder.Parameters.Insert("qService", Service);
	ReportBuilder.Parameters.Insert("qResource", Resource);
	ReportBuilder.Parameters.Insert("qResourceIsEmpty", Not ValueIsFilled(Resource));
	ReportBuilder.Parameters.Insert("qEmptyResourceType", Catalogs.ResourceTypes.EmptyRef());
	ReportBuilder.Parameters.Insert("qEmptyResource", Catalogs.Resources.EmptyRef());
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
	|	SalesForecast.Period AS Period,
	|	SalesForecast.Hotel AS Hotel,
	|	SalesForecast.Service AS Service,
	|	SalesForecast.Price AS Price,
	|	SalesForecast.Resource AS Resource,
	|	SalesForecast.Client AS Client,
	|	SalesForecast.Recorder AS Recorder,
	|	SalesForecast.ParentDoc AS ParentDoc,
	|	SalesForecast.IsStorno AS IsStorno,
	|	SalesForecast.ReportingCurrency AS ReportingCurrency,
	|	SalesForecast.Quantity AS Quantity,
	|	SalesForecast.QuantityFact AS QuantityFact,
	|	SalesForecast.QuantityPlan AS QuantityPlan,
	|	SalesForecast.Sum AS Sum,
	|	SalesForecast.SumFact AS SumFact,
	|	SalesForecast.SumPlan AS SumPlan,
	|	SalesForecast.SumWithoutVAT AS SumWithoutVAT,
	|	SalesForecast.SumWithoutVATFact AS SumWithoutVATFact,
	|	SalesForecast.SumWithoutVATPlan AS SumWithoutVATPlan,
	|	SalesForecast.CommissionSum AS CommissionSum,
	|	SalesForecast.CommissionSumFact AS CommissionSumFact,
	|	SalesForecast.CommissionSumPlan AS CommissionSumPlan,
	|	SalesForecast.CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|	SalesForecast.CommissionSumWithoutVATFact AS CommissionSumWithoutVATFact,
	|	SalesForecast.CommissionSumWithoutVATPlan AS CommissionSumWithoutVATPlan,
	|	SalesForecast.DiscountSum AS DiscountSum,
	|	SalesForecast.DiscountSumFact AS DiscountSumFact,
	|	SalesForecast.DiscountSumPlan AS DiscountSumPlan,
	|	SalesForecast.DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|	SalesForecast.DiscountSumWithoutVATFact AS DiscountSumWithoutVATFact,
	|	SalesForecast.DiscountSumWithoutVATPlan AS DiscountSumWithoutVATPlan,
	|	SalesForecast.ResourceRevenue AS ResourceRevenue,
	|	SalesForecast.ResourceRevenueFact AS ResourceRevenueFact,
	|	SalesForecast.ResourceRevenuePlan AS ResourceRevenuePlan,
	|	SalesForecast.ResourceRevenueWithoutVAT AS ResourceRevenueWithoutVAT,
	|	SalesForecast.ResourceRevenueWithoutVATFact AS ResourceRevenueWithoutVATFact,
	|	SalesForecast.ResourceRevenueWithoutVATPlan AS ResourceRevenueWithoutVATPlan,
	|	SalesForecast.HoursRented AS HoursRented,
	|	SalesForecast.HoursRentedFact AS HoursRentedFact,
	|	SalesForecast.HoursRentedPlan AS HoursRentedPlan,
	|	SalesForecast.NumberOfPersons AS NumberOfPersons
	|{SELECT
	|	Period AS Period,
	|	SalesForecast.AccountingDate AS AccountingDate,
	|	(HOUR(SalesForecast.Period)) AS AccountingHour,
	|	(DAY(SalesForecast.AccountingDate)) AS AccountingDay,
	|	(WEEK(SalesForecast.AccountingDate)) AS AccountingWeek,
	|	(MONTH(SalesForecast.AccountingDate)) AS AccountingMonth,
	|	(QUARTER(SalesForecast.AccountingDate)) AS AccountingQuarter,
	|	(YEAR(SalesForecast.AccountingDate)) AS AccountingYear,
	|	Hotel.* AS Hotel,
	|	SalesForecast.Company.* AS Company,
	|	ReportingCurrency.* AS ReportingCurrency,
	|	Service.* AS Service,
	|	SalesForecast.DateTimeFrom AS DateTimeFrom,
	|	(HOUR(SalesForecast.DateTimeFrom)) AS FromHour,
	|	(DAY(SalesForecast.DateTimeFrom)) AS FromDay,
	|	(WEEK(SalesForecast.DateTimeFrom)) AS FromWeek,
	|	(MONTH(SalesForecast.DateTimeFrom)) AS FromMonth,
	|	(QUARTER(SalesForecast.DateTimeFrom)) AS FromQuarter,
	|	(YEAR(SalesForecast.DateTimeFrom)) AS FromYear,
	|	SalesForecast.DateTimeTo AS DateTimeTo,
	|	SalesForecast.Duration AS Duration,
	|	Price AS Price,
	|	Client.* AS Client,
	|	SalesForecast.ResourceTariff.* AS ResourceTariff,
	|	SalesForecast.EventActivity.* AS EventActivity,
	|	SalesForecast.ClientType.* AS ClientType,
	|	SalesForecast.ClientAge AS ClientAge,
	|	SalesForecast.ClientCitizenship.* AS ClientCitizenship,
	|	SalesForecast.ClientRegion AS ClientRegion,
	|	SalesForecast.ClientCity AS ClientCity,
	|	SalesForecast.Agent.* AS Agent,
	|	SalesForecast.Customer.* AS Customer,
	|	SalesForecast.Contract.* AS Contract,
	|	SalesForecast.GuestGroup.* AS GuestGroup,
	|	SalesForecast.MarketingCode.* AS MarketingCode,
	|	SalesForecast.SourceOfBusiness.* AS SourceOfBusiness,
	|	SalesForecast.Folio.* AS Folio,
	|	Recorder.* AS Recorder,
	|	ParentDoc.* AS ParentDoc,
	|	SalesForecast.NumberOfPersons AS NumberOfPersons,
	|	SalesForecast.ResourceType.* AS ResourceType,
	|	Resource.* AS Resource,
	|	SalesForecast.VATRate.* AS VATRate,
	|	SalesForecast.Author.* AS Author,
	|	IsStorno AS IsStorno,
	|	Quantity AS Quantity,
	|	QuantityPlan AS QuantityPlan,
	|	QuantityFact AS QuantityFact,
	|	Sum AS Sum,
	|	SumPlan AS SumPlan,
	|	SumFact AS SumFact,
	|	SumWithoutVAT AS SumWithoutVAT,
	|	SumWithoutVATPlan AS SumWithoutVATPlan,
	|	SumWithoutVATFact AS SumWithoutVATFact,
	|	CommissionSum AS CommissionSum,
	|	CommissionSumPlan AS CommissionSumPlan,
	|	CommissionSumFact AS CommissionSumFact,
	|	CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|	CommissionSumWithoutVATPlan AS CommissionSumWithoutVATPlan,
	|	CommissionSumWithoutVATFact AS CommissionSumWithoutVATFact,
	|	DiscountSum AS DiscountSum,
	|	DiscountSumPlan AS DiscountSumPlan,
	|	DiscountSumFact AS DiscountSumFact,
	|	DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|	DiscountSumWithoutVATPlan AS DiscountSumWithoutVATPlan,
	|	DiscountSumWithoutVATFact AS DiscountSumWithoutVATFact,
	|	ResourceRevenue AS ResourceRevenue,
	|	ResourceRevenueFact AS ResourceRevenueFact,
	|	ResourceRevenuePlan AS ResourceRevenuePlan,
	|	ResourceRevenueWithoutVAT AS ResourceRevenueWithoutVAT,
	|	ResourceRevenueWithoutVATFact AS ResourceRevenueWithoutVATFact,
	|	ResourceRevenueWithoutVATPlan AS ResourceRevenueWithoutVATPlan,
	|	HoursRented AS HoursRented,
	|	HoursRentedFact AS HoursRentedFact,
	|	HoursRentedPlan AS HoursRentedPlan,
	|	NumberOfPersons}
	|FROM
	|	(SELECT
	|		ResourceSales.ServiceDate AS Period,
	|		ResourceSales.Hotel AS Hotel,
	|		ResourceSales.Company AS Company,
	|		ResourceSales.ReportingCurrency AS ReportingCurrency,
	|		ResourceSales.Service AS Service,
	|		ResourceSales.AccountingDate AS AccountingDate,
	|		CASE
	|			WHEN ResourceSales.Resource <> ResourceSales.ParentDoc.Resource
	|				THEN DATEADD(ResourceSales.AccountingDate, SECOND, DATEDIFF(BEGINOFPERIOD(ResourceSales.TimeFrom, DAY), ResourceSales.TimeFrom, SECOND))
	|			ELSE ResourceSales.ParentDoc.DateTimeFrom
	|		END AS DateTimeFrom,
	|		CASE
	|			WHEN ResourceSales.Resource <> ResourceSales.ParentDoc.Resource
	|					AND ResourceSales.TimeTo >= ResourceSales.TimeFrom
	|				THEN DATEDIFF(ResourceSales.TimeFrom, ResourceSales.TimeTo, HOUR)
	|			WHEN ResourceSales.Resource <> ResourceSales.ParentDoc.Resource
	|					AND ResourceSales.TimeTo < ResourceSales.TimeFrom
	|				THEN DATEDIFF(ResourceSales.TimeFrom, DATEADD(ResourceSales.TimeTo, SECOND, 86400), HOUR)
	|			ELSE ResourceSales.ParentDoc.Duration
	|		END AS Duration,
	|		CASE
	|			WHEN ResourceSales.Resource <> ResourceSales.ParentDoc.Resource
	|					AND ResourceSales.TimeTo >= ResourceSales.TimeFrom
	|				THEN DATEADD(ResourceSales.AccountingDate, SECOND, DATEDIFF(BEGINOFPERIOD(ResourceSales.TimeTo, DAY), ResourceSales.TimeTo, SECOND))
	|			WHEN ResourceSales.Resource <> ResourceSales.ParentDoc.Resource
	|					AND ResourceSales.TimeTo < ResourceSales.TimeFrom
	|				THEN DATEADD(ResourceSales.AccountingDate, SECOND, DATEDIFF(BEGINOFPERIOD(ResourceSales.TimeTo, DAY), ResourceSales.TimeTo, SECOND) + 86400)
	|			ELSE ResourceSales.ParentDoc.DateTimeTo
	|		END AS DateTimeTo,
	|		ResourceSales.Price AS Price,
	|		ResourceSales.Resource AS Resource,
	|		ResourceSales.Client AS Client,
	|		ResourceSales.ParentDoc.ResourceTariff AS ResourceTariff,
	|		ResourceSales.EventActivity AS EventActivity,
	|		ResourceSales.ClientType AS ClientType,
	|		ResourceSales.Client.Age AS ClientAge,
	|		ResourceSales.Client.Citizenship AS ClientCitizenship,
	|		ResourceSales.Client.Region AS ClientRegion,
	|		ResourceSales.Client.City AS ClientCity,
	|		ResourceSales.Agent AS Agent,
	|		ResourceSales.Customer AS Customer,
	|		ResourceSales.Contract AS Contract,
	|		ResourceSales.GuestGroup AS GuestGroup,
	|		ResourceSales.MarketingCode AS MarketingCode,
	|		ResourceSales.SourceOfBusiness AS SourceOfBusiness,
	|		ResourceSales.Folio AS Folio,
	|		ResourceSales.Recorder AS Recorder,
	|		ResourceSales.ParentDoc AS ParentDoc,
	|		ResourceSales.PaymentMethod AS PaymentMethod,
	|		ResourceSales.ParentDoc.NumberOfPersons AS NumberOfPersons,
	|		ResourceSales.ResourceType AS ResourceType,
	|		ResourceSales.VATRate AS VATRate,
	|		ResourceSales.Author AS Author,
	|		ResourceSales.IsStorno AS IsStorno,
	|		ResourceSales.Quantity AS Quantity,
	|		0 AS QuantityPlan,
	|		ResourceSales.Quantity AS QuantityFact,
	|		ResourceSales.Sales AS Sum,
	|		0 AS SumPlan,
	|		ResourceSales.Sales AS SumFact,
	|		ResourceSales.SalesWithoutVAT AS SumWithoutVAT,
	|		0 AS SumWithoutVATPlan,
	|		ResourceSales.SalesWithoutVAT AS SumWithoutVATFact,
	|		ResourceSales.CommissionSum AS CommissionSum,
	|		0 AS CommissionSumPlan,
	|		ResourceSales.CommissionSum AS CommissionSumFact,
	|		ResourceSales.CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|		0 AS CommissionSumWithoutVATPlan,
	|		ResourceSales.CommissionSumWithoutVAT AS CommissionSumWithoutVATFact,
	|		ResourceSales.DiscountSum AS DiscountSum,
	|		0 AS DiscountSumPlan,
	|		ResourceSales.DiscountSum AS DiscountSumFact,
	|		ResourceSales.DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|		0 AS DiscountSumWithoutVATPlan,
	|		ResourceSales.DiscountSumWithoutVAT AS DiscountSumWithoutVATFact,
	|		ResourceSales.ResourceRevenue AS ResourceRevenue,
	|		0 AS ResourceRevenuePlan,
	|		ResourceSales.ResourceRevenue AS ResourceRevenueFact,
	|		ResourceSales.ResourceRevenueWithoutVAT AS ResourceRevenueWithoutVAT,
	|		0 AS ResourceRevenueWithoutVATPlan,
	|		ResourceSales.ResourceRevenueWithoutVAT AS ResourceRevenueWithoutVATFact,
	|		ResourceSales.HoursRented AS HoursRented,
	|		0 AS HoursRentedPlan,
	|		ResourceSales.HoursRented AS HoursRentedFact
	|	FROM
	|		AccumulationRegister.Sales AS ResourceSales
	|	WHERE
	|		NOT ResourceSales.IsCorrection
	|		AND ResourceSales.Hotel IN HIERARCHY(&qHotel)
	|		AND ResourceSales.Service IN HIERARCHY(&qService)
	|		AND (ResourceSales.Service IN (&qServicesList)
	|				OR NOT &qUseServicesList)
	|		AND (ResourceSales.Resource = &qResource
	|				OR &qResourceIsEmpty)
	|		AND (ResourceSales.ResourceType <> &qEmptyResourceType
	|				OR ResourceSales.Resource <> &qEmptyResource)
	|		AND ResourceSales.ServiceDate BETWEEN &qPeriodFrom AND &qPeriodTo
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ResourceSalesForecast.ServiceDate,
	|		ResourceSalesForecast.Hotel,
	|		ResourceSalesForecast.Company,
	|		ResourceSalesForecast.ReportingCurrency,
	|		ResourceSalesForecast.Service,
	|		ResourceSalesForecast.AccountingDate,
	|		CASE
	|			WHEN ResourceSalesForecast.Resource <> ResourceSalesForecast.Recorder.Resource
	|				THEN DATEADD(ResourceSalesForecast.AccountingDate, SECOND, DATEDIFF(BEGINOFPERIOD(ResourceSalesForecast.TimeFrom, DAY), ResourceSalesForecast.TimeFrom, SECOND))
	|			ELSE ResourceSalesForecast.Recorder.DateTimeFrom
	|		END,
	|		CASE
	|			WHEN ResourceSalesForecast.Resource <> ResourceSalesForecast.Recorder.Resource
	|					AND ResourceSalesForecast.TimeTo >= ResourceSalesForecast.TimeFrom
	|				THEN DATEDIFF(ResourceSalesForecast.TimeFrom, ResourceSalesForecast.TimeTo, HOUR)
	|			WHEN ResourceSalesForecast.Resource <> ResourceSalesForecast.Recorder.Resource
	|					AND ResourceSalesForecast.TimeTo < ResourceSalesForecast.TimeFrom
	|				THEN DATEDIFF(ResourceSalesForecast.TimeFrom, DATEADD(ResourceSalesForecast.TimeTo, SECOND, 86400), HOUR)
	|			ELSE ResourceSalesForecast.Recorder.Duration
	|		END,
	|		CASE
	|			WHEN ResourceSalesForecast.Resource <> ResourceSalesForecast.Recorder.Resource
	|					AND ResourceSalesForecast.TimeTo >= ResourceSalesForecast.TimeFrom
	|				THEN DATEADD(ResourceSalesForecast.AccountingDate, SECOND, DATEDIFF(BEGINOFPERIOD(ResourceSalesForecast.TimeTo, DAY), ResourceSalesForecast.TimeTo, SECOND))
	|			WHEN ResourceSalesForecast.Resource <> ResourceSalesForecast.Recorder.Resource
	|					AND ResourceSalesForecast.TimeTo < ResourceSalesForecast.TimeFrom
	|				THEN DATEADD(ResourceSalesForecast.AccountingDate, SECOND, DATEDIFF(BEGINOFPERIOD(ResourceSalesForecast.TimeTo, DAY), ResourceSalesForecast.TimeTo, SECOND) + 86400)
	|			ELSE ResourceSalesForecast.Recorder.DateTimeTo
	|		END,
	|		ResourceSalesForecast.Price,
	|		ResourceSalesForecast.Resource,
	|		ResourceSalesForecast.Client,
	|		ResourceSalesForecast.Recorder.ResourceTariff,
	|		ResourceSalesForecast.EventActivity,
	|		ResourceSalesForecast.ClientType,
	|		ResourceSalesForecast.Client.Age,
	|		ResourceSalesForecast.Client.Citizenship,
	|		ResourceSalesForecast.Client.Region,
	|		ResourceSalesForecast.Client.City,
	|		ResourceSalesForecast.Agent,
	|		ResourceSalesForecast.Customer,
	|		ResourceSalesForecast.Contract,
	|		ResourceSalesForecast.GuestGroup,
	|		ResourceSalesForecast.MarketingCode,
	|		ResourceSalesForecast.SourceOfBusiness,
	|		ResourceSalesForecast.Folio,
	|		ResourceSalesForecast.Recorder,
	|		ResourceSalesForecast.ParentDoc,
	|		ResourceSalesForecast.Recorder.PlannedPaymentMethod,
	|		ResourceSalesForecast.Recorder.NumberOfPersons,
	|		ResourceSalesForecast.ResourceType,
	|		ResourceSalesForecast.VATRate,
	|		ResourceSalesForecast.Author,
	|		ResourceSalesForecast.IsStorno,
	|		ResourceSalesForecast.Quantity,
	|		ResourceSalesForecast.Quantity,
	|		0,
	|		ResourceSalesForecast.Sales,
	|		ResourceSalesForecast.Sales,
	|		0,
	|		ResourceSalesForecast.SalesWithoutVAT,
	|		ResourceSalesForecast.SalesWithoutVAT,
	|		0,
	|		ResourceSalesForecast.CommissionSum,
	|		ResourceSalesForecast.CommissionSum,
	|		0,
	|		ResourceSalesForecast.CommissionSumWithoutVAT,
	|		ResourceSalesForecast.CommissionSumWithoutVAT,
	|		0,
	|		ResourceSalesForecast.DiscountSum,
	|		ResourceSalesForecast.DiscountSum,
	|		0,
	|		ResourceSalesForecast.DiscountSumWithoutVAT,
	|		ResourceSalesForecast.DiscountSumWithoutVAT,
	|		0,
	|		ResourceSalesForecast.ResourceRevenue,
	|		ResourceSalesForecast.ResourceRevenue,
	|		0,
	|		ResourceSalesForecast.ResourceRevenueWithoutVAT,
	|		ResourceSalesForecast.ResourceRevenueWithoutVAT,
	|		0,
	|		ResourceSalesForecast.HoursRented,
	|		ResourceSalesForecast.HoursRented,
	|		0
	|	FROM
	|		AccumulationRegister.SalesForecast AS ResourceSalesForecast
	|	WHERE
	|		ResourceSalesForecast.Hotel IN HIERARCHY(&qHotel)
	|		AND ResourceSalesForecast.Service IN HIERARCHY(&qService)
	|		AND (ResourceSalesForecast.Service IN (&qServicesList)
	|				OR NOT &qUseServicesList)
	|		AND (ResourceSalesForecast.Resource = &qResource
	|				OR &qResourceIsEmpty)
	|		AND (ResourceSalesForecast.ResourceType <> &qEmptyResourceType
	|				OR ResourceSalesForecast.Resource <> &qEmptyResource)
	|		AND ResourceSalesForecast.ServiceDate BETWEEN &qPeriodFrom AND &qPeriodTo) AS SalesForecast
	|{WHERE
	|	SalesForecast.Period AS Period,
	|	SalesForecast.Hotel.* AS Hotel,
	|	SalesForecast.Company.* AS Company,
	|	SalesForecast.ReportingCurrency.* AS ReportingCurrency,
	|	SalesForecast.Service.* AS Service,
	|	SalesForecast.AccountingDate AS AccountingDate,
	|	SalesForecast.DateTimeFrom AS DateTimeFrom,
	|	SalesForecast.Duration AS Duration,
	|	SalesForecast.DateTimeTo AS DateTimeTo,
	|	SalesForecast.Price AS Price,
	|	SalesForecast.ResourceTariff.* AS ResourceTariff,
	|	SalesForecast.EventActivity.* AS EventActivity,
	|	SalesForecast.Client.* AS Client,
	|	SalesForecast.ClientType.* AS ClientType,
	|	SalesForecast.ClientAge AS ClientAge,
	|	SalesForecast.ClientCitizenship.* AS ClientCitizenship,
	|	SalesForecast.ClientRegion AS ClientRegion,
	|	SalesForecast.ClientCity AS ClientCity,
	|	SalesForecast.Agent.* AS Agent,
	|	SalesForecast.Customer.* AS Customer,
	|	SalesForecast.Contract.* AS Contract,
	|	SalesForecast.GuestGroup.* AS GuestGroup,
	|	SalesForecast.MarketingCode.* AS MarketingCode,
	|	SalesForecast.SourceOfBusiness.* AS SourceOfBusiness,
	|	SalesForecast.Folio.* AS Folio,
	|	SalesForecast.Recorder.* AS Recorder,
	|	SalesForecast.ParentDoc.* AS ParentDoc,
	|	SalesForecast.NumberOfPersons AS NumberOfPersons,
	|	SalesForecast.ResourceType.* AS ResourceType,
	|	SalesForecast.Resource.* AS Resource,
	|	SalesForecast.VATRate.* AS VATRate,
	|	SalesForecast.Author.* AS Author,
	|	SalesForecast.IsStorno AS IsStorno,
	|	SalesForecast.Quantity AS Quantity,
	|	SalesForecast.QuantityPlan AS QuantityPlan,
	|	SalesForecast.QuantityFact AS QuantityFact,
	|	SalesForecast.Sum AS Sum,
	|	SalesForecast.SumPlan AS SumPlan,
	|	SalesForecast.SumFact AS SumFact,
	|	SalesForecast.SumWithoutVAT AS SumWithoutVAT,
	|	SalesForecast.SumWithoutVATPlan AS SumWithoutVATPlan,
	|	SalesForecast.SumWithoutVATFact AS SumWithoutVATFact,
	|	SalesForecast.CommissionSum AS CommissionSum,
	|	SalesForecast.CommissionSumPlan AS CommissionSumPlan,
	|	SalesForecast.CommissionSumFact AS CommissionSumFact,
	|	SalesForecast.CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|	SalesForecast.CommissionSumWithoutVATPlan AS CommissionSumWithoutVATPlan,
	|	SalesForecast.CommissionSumWithoutVATFact AS CommissionSumWithoutVATFact,
	|	SalesForecast.DiscountSum AS DiscountSum,
	|	SalesForecast.DiscountSumPlan AS DiscountSumPlan,
	|	SalesForecast.DiscountSumFact AS DiscountSumFact,
	|	SalesForecast.DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|	SalesForecast.DiscountSumWithoutVATPlan AS DiscountSumWithoutVATPlan,
	|	SalesForecast.DiscountSumWithoutVATFact AS DiscountSumWithoutVATFact,
	|	SalesForecast.ResourceRevenue AS ResourceRevenue,
	|	SalesForecast.ResourceRevenueFact AS ResourceRevenueFact,
	|	SalesForecast.ResourceRevenuePlan AS ResourceRevenuePlan,
	|	SalesForecast.ResourceRevenueWithoutVAT AS ResourceRevenueWithoutVAT,
	|	SalesForecast.ResourceRevenueWithoutVATFact AS ResourceRevenueWithoutVATFact,
	|	SalesForecast.ResourceRevenueWithoutVATPlan AS ResourceRevenueWithoutVATPlan,
	|	SalesForecast.HoursRented AS HoursRented,
	|	SalesForecast.HoursRentedFact AS HoursRentedFact,
	|	SalesForecast.HoursRentedPlan AS HoursRentedPlan}
	|
	|ORDER BY
	|	ReportingCurrency,
	|	Hotel,
	|	Service,
	|	Resource,
	|	Period
	|{ORDER BY
	|	Period AS Period,
	|	Hotel.* AS Hotel,
	|	SalesForecast.Company.* AS Company,
	|	ReportingCurrency.* AS ReportingCurrency,
	|	Service.* AS Service,
	|	SalesForecast.AccountingDate AS AccountingDate,
	|	SalesForecast.DateTimeFrom AS DateTimeFrom,
	|	SalesForecast.Duration AS Duration,
	|	SalesForecast.DateTimeTo AS DateTimeTo,
	|	Price AS Price,
	|	SalesForecast.ResourceTariff.* AS ResourceTariff,
	|	SalesForecast.EventActivity.* AS EventActivity,
	|	Client.* AS Client,
	|	SalesForecast.ClientType.* AS ClientType,
	|	SalesForecast.ClientAge AS ClientAge,
	|	SalesForecast.ClientCitizenship.* AS ClientCitizenship,
	|	SalesForecast.ClientRegion AS ClientRegion,
	|	SalesForecast.ClientCity AS ClientCity,
	|	SalesForecast.Agent.* AS Agent,
	|	SalesForecast.Customer.* AS Customer,
	|	SalesForecast.Contract.* AS Contract,
	|	SalesForecast.GuestGroup.* AS GuestGroup,
	|	SalesForecast.MarketingCode.* AS MarketingCode,
	|	SalesForecast.SourceOfBusiness.* AS SourceOfBusiness,
	|	SalesForecast.Folio.* AS Folio,
	|	Recorder.* AS Recorder,
	|	ParentDoc.* AS ParentDoc,
	|	SalesForecast.NumberOfPersons AS NumberOfPersons,
	|	SalesForecast.ResourceType.* AS ResourceType,
	|	Resource.* AS Resource,
	|	SalesForecast.VATRate.* AS VATRate,
	|	SalesForecast.Author.* AS Author,
	|	IsStorno AS IsStorno,
	|	Quantity AS Quantity,
	|	QuantityPlan AS QuantityPlan,
	|	QuantityFact AS QuantityFact,
	|	Sum AS Sum,
	|	SumPlan AS SumPlan,
	|	SumFact AS SumFact,
	|	SumWithoutVAT AS SumWithoutVAT,
	|	SumWithoutVATPlan AS SumWithoutVATPlan,
	|	SumWithoutVATFact AS SumWithoutVATFact,
	|	CommissionSum AS CommissionSum,
	|	CommissionSumPlan AS CommissionSumPlan,
	|	CommissionSumFact AS CommissionSumFact,
	|	CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|	CommissionSumWithoutVATPlan AS CommissionSumWithoutVATPlan,
	|	CommissionSumWithoutVATFact AS CommissionSumWithoutVATFact,
	|	DiscountSum AS DiscountSum,
	|	DiscountSumPlan AS DiscountSumPlan,
	|	DiscountSumFact AS DiscountSumFact,
	|	DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|	DiscountSumWithoutVATPlan AS DiscountSumWithoutVATPlan,
	|	DiscountSumWithoutVATFact AS DiscountSumWithoutVATFact,
	|	ResourceRevenue AS ResourceRevenue,
	|	ResourceRevenueFact AS ResourceRevenueFact,
	|	ResourceRevenuePlan AS ResourceRevenuePlan,
	|	ResourceRevenueWithoutVAT AS ResourceRevenueWithoutVAT,
	|	ResourceRevenueWithoutVATFact AS ResourceRevenueWithoutVATFact,
	|	ResourceRevenueWithoutVATPlan AS ResourceRevenueWithoutVATPlan,
	|	HoursRented AS HoursRented,
	|	HoursRentedFact AS HoursRentedFact,
	|	HoursRentedPlan AS HoursRentedPlan}
	|TOTALS
	|	SUM(Quantity),
	|	SUM(QuantityFact),
	|	SUM(QuantityPlan),
	|	SUM(Sum),
	|	SUM(SumFact),
	|	SUM(SumPlan),
	|	SUM(SumWithoutVAT),
	|	SUM(SumWithoutVATFact),
	|	SUM(SumWithoutVATPlan),
	|	SUM(CommissionSum),
	|	SUM(CommissionSumFact),
	|	SUM(CommissionSumPlan),
	|	SUM(CommissionSumWithoutVAT),
	|	SUM(CommissionSumWithoutVATFact),
	|	SUM(CommissionSumWithoutVATPlan),
	|	SUM(DiscountSum),
	|	SUM(DiscountSumFact),
	|	SUM(DiscountSumPlan),
	|	SUM(DiscountSumWithoutVAT),
	|	SUM(DiscountSumWithoutVATFact),
	|	SUM(DiscountSumWithoutVATPlan),
	|	SUM(ResourceRevenue),
	|	SUM(ResourceRevenueFact),
	|	SUM(ResourceRevenuePlan),
	|	SUM(ResourceRevenueWithoutVAT),
	|	SUM(ResourceRevenueWithoutVATFact),
	|	SUM(ResourceRevenueWithoutVATPlan),
	|	SUM(HoursRented),
	|	SUM(HoursRentedFact),
	|	SUM(HoursRentedPlan),
	|	SUM(NumberOfPersons)
	|BY
	|	OVERALL,
	|	ReportingCurrency,
	|	Hotel,
	|	Service,
	|	Resource,
	|	Period
	|{TOTALS BY
	|	Period AS Period,
	|	SalesForecast.AccountingDate AS AccountingDate,
	|	(HOUR(SalesForecast.Period)) AS AccountingHour,
	|	(DAY(SalesForecast.AccountingDate)) AS AccountingDay,
	|	(WEEK(SalesForecast.AccountingDate)) AS AccountingWeek,
	|	(MONTH(SalesForecast.AccountingDate)) AS AccountingMonth,
	|	(QUARTER(SalesForecast.AccountingDate)) AS AccountingQuarter,
	|	(YEAR(SalesForecast.AccountingDate)) AS AccountingYear,
	|	(HOUR(SalesForecast.DateTimeFrom)) AS FromHour,
	|	(DAY(SalesForecast.DateTimeFrom)) AS FromDay,
	|	(WEEK(SalesForecast.DateTimeFrom)) AS FromWeek,
	|	(MONTH(SalesForecast.DateTimeFrom)) AS FromMonth,
	|	(QUARTER(SalesForecast.DateTimeFrom)) AS FromQuarter,
	|	(YEAR(SalesForecast.DateTimeFrom)) AS FromYear,
	|	Hotel.* AS Hotel,
	|	SalesForecast.Company.* AS Company,
	|	ReportingCurrency.* AS ReportingCurrency,
	|	Service.* AS Service,
	|	Price AS Price,
	|	Client.* AS Client,
	|	SalesForecast.ResourceTariff.* AS ResourceTariff,
	|	SalesForecast.EventActivity.* AS EventActivity,
	|	SalesForecast.ClientType.* AS ClientType,
	|	SalesForecast.ClientAge AS ClientAge,
	|	SalesForecast.ClientCitizenship.* AS ClientCitizenship,
	|	SalesForecast.ClientRegion AS ClientRegion,
	|	SalesForecast.ClientCity AS ClientCity,
	|	SalesForecast.Agent.* AS Agent,
	|	SalesForecast.Customer.* AS Customer,
	|	SalesForecast.Contract.* AS Contract,
	|	SalesForecast.GuestGroup.* AS GuestGroup,
	|	SalesForecast.MarketingCode.* AS MarketingCode,
	|	SalesForecast.SourceOfBusiness.* AS SourceOfBusiness,
	|	SalesForecast.Folio.* AS Folio,
	|	Recorder.* AS Recorder,
	|	ParentDoc.* AS ParentDoc,
	|	SalesForecast.NumberOfPersons AS NumberOfPersons,
	|	SalesForecast.ResourceType.* AS ResourceType,
	|	Resource.* AS Resource,
	|	SalesForecast.VATRate.* AS VATRate,
	|	SalesForecast.Author.* AS Author,
	|	IsStorno AS IsStorno,
	|	NumberOfPersons}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Resource sales forecast';RU='Планируемые продажи ресурсов';de='Geplante Ressourcenverkäufen'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
Function pmIsResource(pName) Export
	If pName = "Quantity" 
	   Or pName = "QuantityFact" 
	   Or pName = "QuantityPlan" 
	   Or pName = "Sum" 
	   Or pName = "SumFact" 
	   Or pName = "SumPlan" 
	   Or pName = "SumWithoutVAT" 
	   Or pName = "SumWithoutVATFact" 
	   Or pName = "SumWithoutVATPlan" 
	   Or pName = "CommissionSum" 
	   Or pName = "CommissionSumFact" 
	   Or pName = "CommissionSumPlan" 
	   Or pName = "CommissionSumWithoutVAT" 
	   Or pName = "CommissionSumWithoutVATFact" 
	   Or pName = "CommissionSumWithoutVATPlan" 
	   Or pName = "DiscountSum" 
	   Or pName = "DiscountSumFact" 
	   Or pName = "DiscountSumPlan" 
	   Or pName = "DiscountSumWithoutVAT" 
	   Or pName = "DiscountSumWithoutVATFact" 
	   Or pName = "DiscountSumWithoutVATPlan"
	   Or pName = "ResourceRevenue" 
	   Or pName = "ResourceRevenueFact" 
	   Or pName = "ResourceRevenuePlan"
	   Or pName = "ResourceRevenueWithoutVAT" 
	   Or pName = "ResourceRevenueWithoutVATFact" 
	   Or pName = "ResourceRevenueWithoutVATPlan"
	   Or pName = "HoursRented" 
	   Or pName = "HoursRentedFact" 
	   Or pName = "HoursRentedPlan" Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // pmIsResource

#EndRegion
