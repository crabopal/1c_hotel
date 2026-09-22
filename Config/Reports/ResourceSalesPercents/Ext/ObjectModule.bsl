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
		PeriodFrom = BegOfMonth(CurrentSessionDate()); // For beg of month
		PeriodTo = EndOfDay(CurrentSessionDate());
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
	If ValueIsFilled(ResourceType) Then
		If Not ResourceType.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Resource type ';ru='Тип ресурса ';de='Ressourcentyp '") + 
			                     TrimAll(ResourceType.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Resource types folder ';ru='Группа типов ресурсов ';de='Ressourcentypengruppe '") + 
			                     TrimAll(ResourceType.Description) + 
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
	
	// Check if there are any filters set for the report builder
	vFilterIsNotSet = True;
	For Each vFilterRow In ReportBuilder.Filter Do
		If vFilterRow.Use Then
			vFilterIsNotSet = False;
			Break;
		EndIf;
	EndDo;
	// Check if there is any custom ordering applied for the report builder
	vOrderIsNotSet = True;
	If ReportBuilder.Order.Count() > 0 Then
		vOrderIsNotSet = False;
	EndIf;
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
	
	// Initialize report builder query generator attributes
	ReportBuilder.PresentationAdding = PresentationAdditionType.Add;
	
	// Run main query to get data
	QueryText = ReportBuilder.Text;
	
	vQry = New Query();
	vQry.Text = TrimAll(QueryText);
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qPeriodFrom", PeriodFrom);
	vQry.SetParameter("qPeriodTo", PeriodTo);
	vForecastStartDate = tcOnServer.GetForecastStartDate(Hotel);
	vQry.SetParameter("qForecastPeriodFrom", Max(BegOfDay(PeriodFrom), vForecastStartDate));
	vQry.SetParameter("qForecastPeriodTo", ?(ValueIsFilled(PeriodTo), Max(PeriodTo, EndOfDay(vForecastStartDate-24*3600)), '00010101'));
	vQry.SetParameter("qResource", Resource);
	vQry.SetParameter("qIsEmptyResource", Not ValueIsFilled(Resource));
	vQry.SetParameter("qResourceType", ResourceType);
	vQry.SetParameter("qIsEmptyResourceType", Not ValueIsFilled(ResourceType));
	vQry.SetParameter("qEmptyResourceType", Catalogs.ResourceTypes.EmptyRef());
	vQry.SetParameter("qService", Service);
	vQry.SetParameter("qIsEmptyService", Not ValueIsFilled(Service));
	vUseServicesList = False;
	vServicesList = New ValueList();
	If ValueIsFilled(ServiceGroup) Then
		If Not ServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(ServiceGroup);
		EndIf;
	EndIf;
	vQry.SetParameter("qUseServicesList", vUseServicesList);
	vQry.SetParameter("qServicesList", vServicesList);
	vResults = vQry.Execute().Unload();
	
	// Move totals row to the last row position
	If vResults.Count() > 0 Then
		vRow = vResults.Get(0);
		
		// Move first row to the last position or remove totals if there are filters or custom ordering
		If vResults.Count() > 1 Then
			If vFilterIsNotSet And vOrderIsNotSet Then
				vResults.Move(vRow, vResults.Count() - 1);
			Else
				vResults.Delete(vRow);
			EndIf;
		EndIf;
	EndIf;
	
	vDaysRentedQry = New Query();
	vDaysRentedQry.Text = 
	"SELECT
	|	ResourceSalesTurnovers.ResourceRevenueTurnover,
	|	ResourceSalesTurnovers.HoursRentedTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(&qBegOfDay, &qEndOfDay, Period, NOT IsCorrection AND Resource = &qResource) AS ResourceSalesTurnovers";
	
	// Initialize report totals
	vTotalWorkingHours = 0;
	vTotalWorkingDays = 0;
	vTotalRevenuePlanned = 0;
	vTotalDaysRented = 0;
	
	// For each row in resulting table run query to get working days, working hours, revenue planned
	i = 0;
	For Each vRow In vResults Do
		// Initialize resource totals
		vWorkingHours = 0;
		vWorkingDays = 0;
		vRevenuePlanned = 0;
		vDaysRented = 0;
		
		If ValueIsFilled(vRow.Resource) Then
			// Do for each period day in the resources calendar
			If ValueIsFilled(vRow.Resource) Then
				vCurResource = vRow.Resource;
				If ValueIsFilled(vCurResource.Calendar) Then
					vDays = vCurResource.Calendar.GetObject().pmGetDays(PeriodFrom, PeriodTo, , , Catalogs.RoomTypes.EmptyRef());
					For Each vDaysRow In vDays Do
						If ValueIsFilled(vDaysRow.Timetable) Then
							If vDaysRow.Timetable.WorkingHoursPerDay > 0 Then
								vWorkingDays = vWorkingDays + 1;
								vWorkingHours = vWorkingHours + vDaysRow.Timetable.WorkingHoursPerDay;
								vRevenuePlanned = vRevenuePlanned + vDaysRow.Timetable.WorkingHoursPerDay*vCurResource.RackRate;
							EndIf;
						ElsIf vCurResource.RoundTheClockOperation Then
							vWorkingDays = vWorkingDays + 1;
							vWorkingHours = vWorkingHours + 24;
							vRevenuePlanned = vRevenuePlanned + 24*vCurResource.RackRate;
						ElsIf ValueIsFilled(vCurResource.TimeTo) And vCurResource.TimeTo > vCurResource.TimeFrom Then
							vWorkingDays = vWorkingDays + 1;
							vWorkingHoursPerDay = Round((vCurResource.TimeTo - vCurResource.TimeFrom)/3600, 3);
							vWorkingHours = vWorkingHours + vWorkingHoursPerDay;
							vRevenuePlanned = vRevenuePlanned + vWorkingHoursPerDay*vCurResource.RackRate;
						EndIf;
						// Check if this day was sold
						vDaysRentedQry.SetParameter("qBegOfDay", BegOfDay(vDaysRow.Period));
						vDaysRentedQry.SetParameter("qEndOfDay", EndOfDay(vDaysRow.Period));
						vDaysRentedQry.SetParameter("qResource", vCurResource);
						vDaysRentedQryRes = vDaysRentedQry.Execute().Unload();
						For Each vDaysRentedQryResRow In vDaysRentedQryRes Do
							If vDaysRentedQryResRow.ResourceRevenueTurnover > 0 Or
							   vDaysRentedQryResRow.HoursRentedTurnover > 0 Then
								vDaysRented = vDaysRented + 1;
								Break;
							EndIf;
						EndDo;
					EndDo;
				ElsIf vCurResource.RoundTheClockOperation Then
					vWorkingDays = Round((EndOfDay(PeriodTo) - BegOfDay(PeriodFrom))/(24*3600), 0);
					vWorkingHours = vWorkingDays*24;
					vRevenuePlanned = vWorkingHours*vCurResource.RackRate;
				ElsIf ValueIsFilled(vCurResource.TimeTo) And vCurResource.TimeTo > vCurResource.TimeFrom Then
					vWorkingDays = vWorkingDays + 1;
					vWorkingHoursPerDay = Round((vCurResource.TimeTo - vCurResource.TimeFrom)/3600, 3);
					vWorkingHours = vWorkingHours + vWorkingHoursPerDay;
					vRevenuePlanned = vRevenuePlanned + vWorkingHoursPerDay*vCurResource.RackRate;
				EndIf;
			EndIf;
			
			// Fill resource totals
			vRow.WorkingHours = vWorkingHours;
			vRow.WorkingDays = vWorkingDays;
			vRow.RevenuePlanned = vRevenuePlanned;
			vRow.DaysRented = vDaysRented;
	
			// Fill resource percents
			vRow.WorkingHoursPercent = ?(vRow.WorkingHours = 0, 0, 100 * vRow.HoursRented/vRow.WorkingHours);
			vRow.WorkingDaysPercent = ?(vRow.WorkingDays = 0, 0, 100 * vRow.DaysRented/vRow.WorkingDays);
			vRow.RevenuePercent = ?(vRow.RevenuePlanned = 0, 0, 100 * vRow.ResourceRevenue/vRow.RevenuePlanned);
			
			// Fill report totals
			If ValueIsFilled(vRow.Resource) Then
				vTotalWorkingHours = vTotalWorkingHours + vWorkingHours;
				vTotalWorkingDays = vTotalWorkingDays + vWorkingDays;
				vTotalRevenuePlanned = vTotalRevenuePlanned + vRevenuePlanned;
				vTotalDaysRented = vTotalDaysRented + vDaysRented;
			EndIf;
		EndIf;
		
		i = i + 1;
	EndDo;
	
	// Calculate percents for report totals row
	If vResults.Count() > 0 Then
		vTotalsRow = vResults.Get(vResults.Count()-1);
		
		// Fill totals
		vTotalsRow.WorkingHours = vTotalWorkingHours;
		vTotalsRow.WorkingDays = vTotalWorkingDays;
		vTotalsRow.RevenuePlanned = vTotalRevenuePlanned;
		vTotalsRow.DaysRented = vTotalDaysRented;

		// Fill percents
		vTotalsRow.WorkingHoursPercent = ?(vRow.WorkingHours = 0, 0, 100 * vTotalsRow.HoursRented/vTotalsRow.WorkingHours);
		vTotalsRow.WorkingDaysPercent = ?(vRow.WorkingDays = 0, 0, 100 * vTotalsRow.DaysRented/vTotalsRow.WorkingDays);
		vTotalsRow.RevenuePercent = ?(vRow.RevenuePlanned = 0, 0, 100 * vTotalsRow.ResourceRevenue/vTotalsRow.RevenuePlanned);
	EndIf;
	
	// Save current report builder settings
	vCurReportBuilderSettings = ReportBuilder.GetSettings(True, True, False, True, True);
	
	// Set resulting table as data source for the report builder
	ReportBuilder.DataSource = New DataSourceDescription(vResults);
	
	// Apply current report builder settings
	ReportBuilder.SetSettings(vCurReportBuilderSettings, True, True, False, True, True);
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Execute report builder
	ReportBuilder.Execute();
	
	// Apply appearance settings to the report template
	vTemplateAttributes = cmApplyReportTemplateAppearance(ThisObject);
	
	// Output report to the spreadsheet
	ReportBuilder.Put(pSpreadsheet);
	//ReportBuilder.Template.Show(); // For debug purpose

	// Add totals caption and appearance to the last report row
	If vResults.Count() > 0 And vFilterIsNotSet And vOrderIsNotSet Then
		vLastRepRow = pSpreadsheet.Area(pSpreadsheet.TableHeight-2, 2, pSpreadsheet.TableHeight-2, pSpreadsheet.TableWidth);
		vLastRepRow.Font = New Font(pSpreadsheet.Area(pSpreadsheet.TableHeight-2, 2, pSpreadsheet.TableHeight-2, 2).Font, , , True);
		vLastRepRow.BackColor = pSpreadsheet.Area(4, 2, 4, 2).BackColor;
		pSpreadsheet.Area(pSpreadsheet.TableHeight-2, 2, pSpreadsheet.TableHeight-2, 2).Text = NStr("en='Totals';ru='Итог';de='Ergebnis'");
	EndIf;
	
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
	|	ResourceSales.ReportingCurrency AS ReportingCurrency,
	|	ResourceSales.Hotel AS Hotel,
	|	ResourceSales.Resource AS Resource,
	|	SUM(ResourceSales.SumTurnover) AS Sum,
	|	SUM(ResourceSales.SumWithoutVATTurnover) AS SumWithoutVAT,
	|	SUM(ResourceSales.QuantityTurnover) AS Quantity,
	|	SUM(ResourceSales.ResourceRevenueTurnover) AS ResourceRevenue,
	|	SUM(ResourceSales.ResourceRevenueWithoutVATTurnover) AS ResourceRevenueWithoutVAT,
	|	SUM(ResourceSales.CommissionSumTurnover) AS CommissionSum,
	|	SUM(ResourceSales.CommissionSumWithoutVATTurnover) AS CommissionSumWithoutVAT,
	|	SUM(ResourceSales.DiscountSumTurnover) AS DiscountSum,
	|	SUM(ResourceSales.DiscountSumWithoutVATTurnover) AS DiscountSumWithoutVAT,
	|	SUM(ResourceSales.HoursRentedTurnover) AS HoursRented,
	|	0 AS DaysRented,
	|	0 AS WorkingHours,
	|	0 AS WorkingDays,
	|	0 AS RevenuePlanned,
	|	0 AS WorkingHoursPercent,
	|	0 AS WorkingDaysPercent,
	|	0 AS RevenuePercent
	|{SELECT
	|	ReportingCurrency.*,
	|	Hotel.*,
	|	Resource.*,
	|	Sum,
	|	SumWithoutVAT,
	|	Quantity,
	|	ResourceRevenue,
	|	ResourceRevenueWithoutVAT,
	|	CommissionSum,
	|	CommissionSumWithoutVAT,
	|	DiscountSum,
	|	DiscountSumWithoutVAT,
	|	HoursRented,
	|	DaysRented,
	|	WorkingHours,
	|	WorkingDays,
	|	RevenuePlanned,
	|	WorkingHoursPercent,
	|	WorkingDaysPercent,
	|	RevenuePercent}
	|FROM
	|	(SELECT
	|		ResourceSalesTurnovers.ReportingCurrency AS ReportingCurrency,
	|		ResourceSalesTurnovers.Hotel AS Hotel,
	|		ResourceSalesTurnovers.Resource AS Resource,
	|		ResourceSalesTurnovers.SalesTurnover AS SumTurnover,
	|		ResourceSalesTurnovers.SalesWithoutVATTurnover AS SumWithoutVATTurnover,
	|		ResourceSalesTurnovers.QuantityTurnover AS QuantityTurnover,
	|		ResourceSalesTurnovers.ResourceRevenueTurnover AS ResourceRevenueTurnover,
	|		ResourceSalesTurnovers.ResourceRevenueWithoutVATTurnover AS ResourceRevenueWithoutVATTurnover,
	|		ResourceSalesTurnovers.CommissionSumTurnover AS CommissionSumTurnover,
	|		ResourceSalesTurnovers.CommissionSumWithoutVATTurnover AS CommissionSumWithoutVATTurnover,
	|		ResourceSalesTurnovers.DiscountSumTurnover AS DiscountSumTurnover,
	|		ResourceSalesTurnovers.DiscountSumWithoutVATTurnover AS DiscountSumWithoutVATTurnover,
	|		ResourceSalesTurnovers.HoursRentedTurnover AS HoursRentedTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection
	|					AND Hotel IN HIERARCHY (&qHotel)
	|					AND (Resource IN HIERARCHY (&qResource)
	|						OR &qIsEmptyResource)
	|					AND (ResourceType IN HIERARCHY (&qResourceType)
	|						OR &qIsEmptyResourceType)
	|					AND ResourceType <> &qEmptyResourceType
	|					AND (Service IN HIERARCHY (&qService)
	|						OR &qIsEmptyService)
	|					AND (Service IN (&qServicesList)
	|						OR NOT &qUseServicesList)) AS ResourceSalesTurnovers
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ResourceSalesForecastTurnovers.ReportingCurrency,
	|		ResourceSalesForecastTurnovers.Hotel,
	|		ResourceSalesForecastTurnovers.Resource,
	|		ResourceSalesForecastTurnovers.SalesTurnover,
	|		ResourceSalesForecastTurnovers.SalesWithoutVATTurnover,
	|		ResourceSalesForecastTurnovers.QuantityTurnover,
	|		ResourceSalesForecastTurnovers.ResourceRevenueTurnover,
	|		ResourceSalesForecastTurnovers.ResourceRevenueWithoutVATTurnover,
	|		ResourceSalesForecastTurnovers.CommissionSumTurnover,
	|		ResourceSalesForecastTurnovers.CommissionSumWithoutVATTurnover,
	|		ResourceSalesForecastTurnovers.DiscountSumTurnover,
	|		ResourceSalesForecastTurnovers.DiscountSumWithoutVATTurnover,
	|		ResourceSalesForecastTurnovers.HoursRentedTurnover
	|	FROM
	|		AccumulationRegister.SalesForecast.Turnovers(
	|				&qForecastPeriodFrom,
	|				&qForecastPeriodTo,
	|				Period,
	|				Hotel IN HIERARCHY (&qHotel)
	|					AND (Resource IN HIERARCHY (&qResource)
	|						OR &qIsEmptyResource)
	|					AND (ResourceType IN HIERARCHY (&qResourceType)
	|						OR &qIsEmptyResourceType)
	|					AND ResourceType <> &qEmptyResourceType
	|					AND (Service IN HIERARCHY (&qService)
	|						OR &qIsEmptyService)
	|					AND (Service IN (&qServicesList)
	|						OR NOT &qUseServicesList)) AS ResourceSalesForecastTurnovers) AS ResourceSales
	|{WHERE
	|	ResourceSales.ReportingCurrency.*,
	|	ResourceSales.Hotel.*,
	|	ResourceSales.Resource.* AS Resource,
	|	(SUM(ResourceSales.SumTurnover)) AS Sum,
	|	(SUM(ResourceSales.SumWithoutVATTurnover)) AS SumWithoutVAT,
	|	(SUM(ResourceSales.QuantityTurnover)) AS Quantity,
	|	(SUM(ResourceSales.ResourceRevenueTurnover)) AS ResourceRevenue,
	|	(SUM(ResourceSales.ResourceRevenueWithoutVATTurnover)) AS ResourceRevenueWithoutVAT,
	|	(SUM(ResourceSales.CommissionSumTurnover)) AS CommissionSum,
	|	(SUM(ResourceSales.CommissionSumWithoutVATTurnover)) AS CommissionSumWithoutVAT,
	|	(SUM(ResourceSales.DiscountSumTurnover)) AS DiscountSum,
	|	(SUM(ResourceSales.DiscountSumWithoutVATTurnover)) AS DiscountSumWithoutVAT,
	|	(SUM(ResourceSales.HoursRentedTurnover)) AS HoursRented,
	|	(0) AS DaysRented,
	|	(0) AS WorkingHours,
	|	(0) AS WorkingDays,
	|	(0) AS RevenuePlanned,
	|	(0) AS WorkingHoursPercent,
	|	(0) AS WorkingDaysPercent,
	|	(0) AS RevenuePercent}
	|
	|GROUP BY
	|	ResourceSales.ReportingCurrency,
	|	ResourceSales.Hotel,
	|	ResourceSales.Resource
	|
	|ORDER BY
	|	ResourceSales.ReportingCurrency.SortCode,
	|	ResourceSales.Hotel.SortCode,
	|	ResourceSales.Resource.SortCode
	|{ORDER BY
	|	ReportingCurrency.*,
	|	Hotel.*,
	|	Resource.*,
	|	Sum,
	|	SumWithoutVAT,
	|	Quantity,
	|	ResourceRevenue,
	|	ResourceRevenueWithoutVAT,
	|	CommissionSum,
	|	CommissionSumWithoutVAT,
	|	DiscountSum,
	|	DiscountSumWithoutVAT,
	|	HoursRented,
	|	DaysRented,
	|	WorkingHours,
	|	WorkingDays,
	|	RevenuePlanned,
	|	WorkingHoursPercent,
	|	WorkingDaysPercent,
	|	RevenuePercent}
	|TOTALS
	|	SUM(Sum),
	|	SUM(SumWithoutVAT),
	|	SUM(Quantity),
	|	SUM(ResourceRevenue),
	|	SUM(ResourceRevenueWithoutVAT),
	|	SUM(CommissionSum),
	|	SUM(CommissionSumWithoutVAT),
	|	SUM(DiscountSum),
	|	SUM(DiscountSumWithoutVAT),
	|	SUM(HoursRented)
	|BY
	|	OVERALL";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Resource sales percents';RU='Проценты продаж по ресурсам';de='Prozente aus Verkäufen nach Ressourcen'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
Function pmIsResource(pName) Export
	If pName = "Sum" 
	   Or pName = "SumWithoutVAT" 
	   Or pName = "Quantity" 
	   Or pName = "ResourceRevenue" 
	   Or pName = "ResourceRevenueWithoutVAT" 
	   Or pName = "CommissionSum" 
	   Or pName = "CommissionSumWithoutVAT" 
	   Or pName = "DiscountSum" 
	   Or pName = "DiscountSumWithoutVAT" 
	   Or pName = "HoursRented" 
	   Or pName = "DaysRented"
	   Or pName = "WorkingHours"
	   Or pName = "WorkingDays"
	   Or pName = "RevenuePlanned"
	   Or pName = "WorkingHoursPercent"
	   Or pName = "WorkingDaysPercent"
	   Or pName = "RevenuePercent" Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // pmIsResource

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
