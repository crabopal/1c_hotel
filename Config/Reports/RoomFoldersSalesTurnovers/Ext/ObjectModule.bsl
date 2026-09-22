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
	vForecastStartDate = tcOnServer.GetForecastStartDate(Hotel);
	ReportBuilder.Parameters.Insert("qForecastPeriodFrom", Max(BegOfDay(PeriodFrom), vForecastStartDate));
	ReportBuilder.Parameters.Insert("qForecastPeriodTo", ?(ValueIsFilled(PeriodTo), Max(PeriodTo, EndOfDay(vForecastStartDate-24*3600)), '00010101'));
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qIsEmptyRoom", Not ValueIsFilled(Room));
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qIsEmptyRoomType", Not ValueIsFilled(RoomType));
	ReportBuilder.Parameters.Insert("qService", Service);
	ReportBuilder.Parameters.Insert("qIsEmptyService", Not ValueIsFilled(Service));
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
	ReportBuilder.Put(pSpreadsheet);
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
	|	PeriodDates.Hotel AS Hotel,
	|	BEGINOFPERIOD(PeriodDates.Period, DAY) AS AccountingDate,
	|	MAX(PeriodDates.CounterClosingBalance) AS Counter
	|INTO PeriodDates
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qPeriodFrom, &qPeriodTo, DAY, RegisterRecordsAndPeriodBoundaries, Hotel IN HIERARCHY (&qHotel)) AS PeriodDates
	|
	|GROUP BY
	|	PeriodDates.Hotel,
	|	BEGINOFPERIOD(PeriodDates.Period, DAY)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomTotalsPerDay.Hotel AS Hotel,
	|	RoomTotalsPerDay.Room AS Room,
	|	BEGINOFPERIOD(RoomTotalsPerDay.Period, DAY) AS AccountingDate,
	|	RoomTotalsPerDay.CounterClosingBalance AS Counter,
	|	RoomTotalsPerDay.TotalRoomsClosingBalance AS TotalRooms,
	|	RoomTotalsPerDay.TotalBedsClosingBalance AS TotalBeds,
	|	-RoomTotalsPerDay.RoomsBlockedClosingBalance AS RoomsBlocked,
	|	-RoomTotalsPerDay.BedsBlockedClosingBalance AS BedsBlocked
	|INTO RoomTotalsPerDay
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			DAY,
	|			RegisterRecordsAndPeriodBoundaries,
	|			Hotel IN HIERARCHY (&qHotel)
	|				AND (Room IN HIERARCHY (&qRoom)
	|					OR &qIsEmptyRoom)
	|				AND (RoomType IN HIERARCHY (&qRoomType)
	|					OR &qIsEmptyRoomType)
	|				AND NOT RoomType.DoesNotAffectRoomRevenueStatistics) AS RoomTotalsPerDay
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PeriodDates.Hotel AS Hotel,
	|	PeriodDates.AccountingDate AS AccountingDate,
	|	RoomTotalsPerDay.Room AS Room,
	|	RoomTotalsPerDay.AccountingDate AS AccountingDate2,
	|	RoomTotalsPerDay.TotalRooms AS TotalRooms,
	|	RoomTotalsPerDay.TotalBeds AS TotalBeds,
	|	RoomTotalsPerDay.RoomsBlocked AS RoomsBlocked,
	|	RoomTotalsPerDay.BedsBlocked AS BedsBlocked
	|INTO FullRoomTotalsPerDay
	|FROM
	|	PeriodDates AS PeriodDates
	|		LEFT JOIN RoomTotalsPerDay AS RoomTotalsPerDay
	|		ON PeriodDates.Hotel = RoomTotalsPerDay.Hotel
	|			AND PeriodDates.AccountingDate >= RoomTotalsPerDay.AccountingDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MaxRoomTotalsPerDay.Hotel AS Hotel,
	|	MaxRoomTotalsPerDay.Room AS Room,
	|	MaxRoomTotalsPerDay.AccountingDate AS AccountingDate,
	|	MAX(MaxRoomTotalsPerDay.AccountingDate2) AS AccountingDate2
	|INTO MaxRoomTotalsPerDay
	|FROM
	|	FullRoomTotalsPerDay AS MaxRoomTotalsPerDay
	|
	|GROUP BY
	|	MaxRoomTotalsPerDay.Hotel,
	|	MaxRoomTotalsPerDay.Room,
	|	MaxRoomTotalsPerDay.AccountingDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomsTotalsPerDay.Hotel AS Hotel,
	|	RoomsTotalsPerDay.Room AS Room,
	|	RoomsTotalsPerDay.AccountingDate AS AccountingDate,
	|	RoomsTotalsPerDay.TotalRooms AS TotalRooms,
	|	RoomsTotalsPerDay.TotalBeds AS TotalBeds,
	|	RoomsTotalsPerDay.RoomsBlocked AS RoomsBlocked,
	|	RoomsTotalsPerDay.BedsBlocked AS BedsBlocked
	|INTO RoomsTotalsPerDay
	|FROM
	|	FullRoomTotalsPerDay AS RoomsTotalsPerDay
	|		INNER JOIN MaxRoomTotalsPerDay AS MaxRoomTotalsPerDay
	|		ON RoomsTotalsPerDay.Hotel = MaxRoomTotalsPerDay.Hotel
	|			AND RoomsTotalsPerDay.Room = MaxRoomTotalsPerDay.Room
	|			AND RoomsTotalsPerDay.AccountingDate = MaxRoomTotalsPerDay.AccountingDate
	|			AND RoomsTotalsPerDay.AccountingDate2 = MaxRoomTotalsPerDay.AccountingDate2
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventoryTotalsPerDay.Hotel AS Hotel,
	|	RoomInventoryTotalsPerDay.Room.Parent AS RoomParent,
	|	RoomInventoryTotalsPerDay.AccountingDate AS AccountingDate,
	|	SUM(RoomInventoryTotalsPerDay.TotalRooms) AS TotalRooms,
	|	SUM(RoomInventoryTotalsPerDay.TotalBeds) AS TotalBeds,
	|	SUM(RoomInventoryTotalsPerDay.RoomsBlocked) AS RoomsBlocked,
	|	SUM(RoomInventoryTotalsPerDay.BedsBlocked) AS BedsBlocked
	|INTO RoomInventoryTotalsPerDay
	|FROM
	|	RoomsTotalsPerDay AS RoomInventoryTotalsPerDay
	|
	|GROUP BY
	|	RoomInventoryTotalsPerDay.Hotel,
	|	RoomInventoryTotalsPerDay.Room.Parent,
	|	RoomInventoryTotalsPerDay.AccountingDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventoryTotalsPerDay.Hotel AS Hotel,
	|	RoomInventoryTotalsPerDay.RoomParent AS RoomParent,
	|	RoomInventoryTotalsPerDay.AccountingDate AS AccountingDate,
	|	RoomSales.ReportingCurrency AS ReportingCurrency,
	|	ISNULL(RoomSales.Sales, 0) AS Sales,
	|	ISNULL(RoomSales.RoomRevenue, 0) AS RoomRevenue,
	|	ISNULL(RoomSales.SalesWithoutVAT, 0) AS SalesWithoutVAT,
	|	ISNULL(RoomSales.RoomRevenueWithoutVAT, 0) AS RoomRevenueWithoutVAT,
	|	ISNULL(RoomSales.CommissionSum, 0) AS CommissionSum,
	|	ISNULL(RoomSales.CommissionSumWithoutVAT, 0) AS CommissionSumWithoutVAT,
	|	ISNULL(RoomSales.DiscountSum, 0) AS DiscountSum,
	|	ISNULL(RoomSales.DiscountSumWithoutVAT, 0) AS DiscountSumWithoutVAT,
	|	ISNULL(RoomSales.RoomsRented, 0) AS RoomsRented,
	|	ISNULL(RoomSales.BedsRented, 0) AS BedsRented,
	|	ISNULL(RoomSales.AdditionalBedsRented, 0) AS AdditionalBedsRented,
	|	ISNULL(RoomSales.GuestDays, 0) AS GuestDays,
	|	ISNULL(RoomSales.GuestsCheckedIn, 0) AS GuestsCheckedIn,
	|	ISNULL(RoomSales.RoomsCheckedIn, 0) AS RoomsCheckedIn,
	|	ISNULL(RoomSales.BedsCheckedIn, 0) AS BedsCheckedIn,
	|	ISNULL(RoomSales.AdditionalBedsCheckedIn, 0) AS AdditionalBedsCheckedIn,
	|	ISNULL(RoomSales.Quantity, 0) AS Quantity,
	|	CASE
	|		WHEN ISNULL(RoomSales.RoomsRented, 0) <> 0
	|			THEN ISNULL(RoomSales.RoomRevenue, 0) / ISNULL(RoomSales.RoomsRented, 0)
	|		ELSE 0
	|	END AS ADR,
	|	CASE
	|		WHEN ISNULL(RoomSales.RoomsRented, 0) <> 0
	|			THEN ISNULL(RoomSales.RoomRevenueWithoutVAT, 0) / ISNULL(RoomSales.RoomsRented, 0)
	|		ELSE 0
	|	END AS ADRWithoutVAT,
	|	CASE
	|		WHEN ISNULL(RoomSales.BedsRented, 0) <> 0
	|			THEN ISNULL(RoomSales.RoomRevenue, 0) / ISNULL(RoomSales.BedsRented, 0)
	|		ELSE 0
	|	END AS ADBR,
	|	CASE
	|		WHEN ISNULL(RoomSales.BedsRented, 0) <> 0
	|			THEN ISNULL(RoomSales.RoomRevenueWithoutVAT, 0) / ISNULL(RoomSales.BedsRented, 0)
	|		ELSE 0
	|	END AS ADBRWithoutVAT,
	|	CASE
	|		WHEN ISNULL(RoomInventoryTotalsPerDay.TotalRooms, 0) - ISNULL(RoomInventoryTotalsPerDay.RoomsBlocked, 0) <> 0
	|			THEN ISNULL(RoomSales.RoomRevenue, 0) / (ISNULL(RoomInventoryTotalsPerDay.TotalRooms, 0) - ISNULL(RoomInventoryTotalsPerDay.RoomsBlocked, 0))
	|		ELSE 0
	|	END AS RevPAR,
	|	CASE
	|		WHEN ISNULL(RoomInventoryTotalsPerDay.TotalRooms, 0) - ISNULL(RoomInventoryTotalsPerDay.RoomsBlocked, 0) <> 0
	|			THEN ISNULL(RoomSales.RoomRevenueWithoutVAT, 0) / (ISNULL(RoomInventoryTotalsPerDay.TotalRooms, 0) - ISNULL(RoomInventoryTotalsPerDay.RoomsBlocked, 0))
	|		ELSE 0
	|	END AS RevPARWithoutVAT,
	|	CASE
	|		WHEN ISNULL(RoomInventoryTotalsPerDay.TotalBeds, 0) - ISNULL(RoomInventoryTotalsPerDay.BedsBlocked, 0) <> 0
	|			THEN ISNULL(RoomSales.RoomRevenue, 0) / (ISNULL(RoomInventoryTotalsPerDay.TotalBeds, 0) - ISNULL(RoomInventoryTotalsPerDay.BedsBlocked, 0))
	|		ELSE 0
	|	END AS RevPAB,
	|	CASE
	|		WHEN ISNULL(RoomInventoryTotalsPerDay.TotalBeds, 0) - ISNULL(RoomInventoryTotalsPerDay.BedsBlocked, 0) <> 0
	|			THEN ISNULL(RoomSales.RoomRevenueWithoutVAT, 0) / (ISNULL(RoomInventoryTotalsPerDay.TotalBeds, 0) - ISNULL(RoomInventoryTotalsPerDay.BedsBlocked, 0))
	|		ELSE 0
	|	END AS RevPABWithoutVAT,
	|	CASE
	|		WHEN ISNULL(RoomSales.GuestDays, 0) <> 0
	|			THEN ISNULL(RoomSales.RoomRevenue, 0) / ISNULL(RoomSales.GuestDays, 0)
	|		ELSE 0
	|	END AS RevPAC,
	|	CASE
	|		WHEN ISNULL(RoomSales.GuestDays, 0) <> 0
	|			THEN ISNULL(RoomSales.RoomRevenueWithoutVAT, 0) / ISNULL(RoomSales.GuestDays, 0) <> 0
	|		ELSE 0
	|	END AS RevPACWithoutVAT,
	|	CASE
	|		WHEN ISNULL(RoomSales.GuestsCheckedIn, 0) <> 0
	|			THEN ISNULL(RoomSales.GuestDays, 0) / ISNULL(RoomSales.GuestsCheckedIn, 0)
	|		ELSE 0
	|	END AS ALS,
	|	ISNULL(RoomInventoryTotalsPerDay.TotalRooms, 0) AS RoomsPerRoomParent,
	|	ISNULL(RoomInventoryTotalsPerDay.TotalBeds, 0) AS BedsPerRoomParent,
	|	ISNULL(RoomInventoryTotalsPerDay.RoomsBlocked, 0) AS RoomsBlockedPerRoomParent,
	|	ISNULL(RoomInventoryTotalsPerDay.BedsBlocked, 0) AS BedsBlockedPerRoomParent,
	|	ISNULL(RoomInventoryTotalsPerDay.TotalRooms, 0) - ISNULL(RoomInventoryTotalsPerDay.RoomsBlocked, 0) AS RoomsAvailablePerRoomParent,
	|	ISNULL(RoomInventoryTotalsPerDay.TotalBeds, 0) - ISNULL(RoomInventoryTotalsPerDay.BedsBlocked, 0) AS BedsAvailablePerRoomParent,
	|	CASE
	|		WHEN ISNULL(RoomInventoryTotalsPerDay.TotalRooms, 0) <> 0
	|			THEN ISNULL(RoomSales.RoomsRented, 0) / ISNULL(RoomInventoryTotalsPerDay.TotalRooms, 0) * 100
	|		ELSE 0
	|	END AS RoomsRentedPercent,
	|	CASE
	|		WHEN ISNULL(RoomInventoryTotalsPerDay.TotalBeds, 0) <> 0
	|			THEN ISNULL(RoomSales.BedsRented, 0) / ISNULL(RoomInventoryTotalsPerDay.TotalBeds, 0) * 100
	|		ELSE 0
	|	END AS BedsRentedPercent,
	|	CASE
	|		WHEN ISNULL(RoomInventoryTotalsPerDay.TotalRooms, 0) - ISNULL(RoomInventoryTotalsPerDay.RoomsBlocked, 0) <> 0
	|			THEN ISNULL(RoomSales.RoomsRented, 0) / (ISNULL(RoomInventoryTotalsPerDay.TotalRooms, 0) - ISNULL(RoomInventoryTotalsPerDay.RoomsBlocked, 0)) * 100
	|		ELSE 0
	|	END AS RoomsRentedWithBlocksPercent,
	|	CASE
	|		WHEN ISNULL(RoomInventoryTotalsPerDay.TotalBeds, 0) - ISNULL(RoomInventoryTotalsPerDay.BedsBlocked, 0) <> 0
	|			THEN ISNULL(RoomSales.BedsRented, 0) / (ISNULL(RoomInventoryTotalsPerDay.TotalBeds, 0) - ISNULL(RoomInventoryTotalsPerDay.BedsBlocked, 0)) * 100
	|		ELSE 0
	|	END AS BedsRentedWithBlocksPercent
	|{SELECT
	|	ReportingCurrency.*,
	|	Hotel.*,
	|	RoomParent.*,
	|	AccountingDate,
	|	Sales,
	|	RoomRevenue,
	|	SalesWithoutVAT,
	|	RoomRevenueWithoutVAT,
	|	CommissionSum,
	|	CommissionSumWithoutVAT,
	|	DiscountSum,
	|	DiscountSumWithoutVAT,
	|	RoomsRented,
	|	BedsRented,
	|	AdditionalBedsRented,
	|	GuestDays,
	|	GuestsCheckedIn,
	|	RoomsCheckedIn,
	|	BedsCheckedIn,
	|	AdditionalBedsCheckedIn,
	|	Quantity,
	|	ADR,
	|	ADRWithoutVAT,
	|	ADBR,
	|	ADBRWithoutVAT,
	|	RevPAR,
	|	RevPARWithoutVAT,
	|	RevPAB,
	|	RevPABWithoutVAT,
	|	RevPAC,
	|	RevPACWithoutVAT,
	|	ALS,
	|	RoomsPerRoomParent,
	|	BedsPerRoomParent,
	|	RoomsBlockedPerRoomParent,
	|	BedsBlockedPerRoomParent,
	|	RoomsAvailablePerRoomParent,
	|	BedsAvailablePerRoomParent,
	|	RoomsRentedPercent,
	|	BedsRentedPercent,
	|	RoomsRentedWithBlocksPercent,
	|	BedsRentedWithBlocksPercent}
	|FROM
	|	RoomInventoryTotalsPerDay AS RoomInventoryTotalsPerDay
	|		LEFT JOIN (SELECT
	|			RoomSalesPerDay.ReportingCurrency AS ReportingCurrency,
	|			RoomSalesPerDay.Hotel AS Hotel,
	|			RoomSalesPerDay.RoomParent AS RoomParent,
	|			RoomSalesPerDay.RoomType AS RoomType,
	|			RoomSalesPerDay.AccountingDate AS AccountingDate,
	|			SUM(RoomSalesPerDay.SalesTurnover) AS Sales,
	|			SUM(RoomSalesPerDay.RoomRevenueTurnover) AS RoomRevenue,
	|			SUM(RoomSalesPerDay.SalesWithoutVATTurnover) AS SalesWithoutVAT,
	|			SUM(RoomSalesPerDay.RoomRevenueWithoutVATTurnover) AS RoomRevenueWithoutVAT,
	|			SUM(RoomSalesPerDay.CommissionSumTurnover) AS CommissionSum,
	|			SUM(RoomSalesPerDay.CommissionSumWithoutVATTurnover) AS CommissionSumWithoutVAT,
	|			SUM(RoomSalesPerDay.DiscountSumTurnover) AS DiscountSum,
	|			SUM(RoomSalesPerDay.DiscountSumWithoutVATTurnover) AS DiscountSumWithoutVAT,
	|			SUM(RoomSalesPerDay.RoomsRentedTurnover) AS RoomsRented,
	|			SUM(RoomSalesPerDay.BedsRentedTurnover) AS BedsRented,
	|			SUM(RoomSalesPerDay.AdditionalBedsRentedTurnover) AS AdditionalBedsRented,
	|			SUM(RoomSalesPerDay.GuestDaysTurnover) AS GuestDays,
	|			SUM(RoomSalesPerDay.GuestsCheckedInTurnover) AS GuestsCheckedIn,
	|			SUM(RoomSalesPerDay.RoomsCheckedInTurnover) AS RoomsCheckedIn,
	|			SUM(RoomSalesPerDay.BedsCheckedInTurnover) AS BedsCheckedIn,
	|			SUM(RoomSalesPerDay.AdditionalBedsCheckedInTurnover) AS AdditionalBedsCheckedIn,
	|			SUM(RoomSalesPerDay.QuantityTurnover) AS Quantity
	|		FROM
	|			(SELECT
	|				RoomSalesTurnovers.ReportingCurrency AS ReportingCurrency,
	|				RoomSalesTurnovers.Hotel AS Hotel,
	|				RoomSalesTurnovers.Room.Parent AS RoomParent,
	|				RoomSalesTurnovers.RoomType AS RoomType,
	|				BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY) AS AccountingDate,
	|				RoomSalesTurnovers.SalesTurnover AS SalesTurnover,
	|				RoomSalesTurnovers.RoomRevenueTurnover AS RoomRevenueTurnover,
	|				RoomSalesTurnovers.SalesWithoutVATTurnover AS SalesWithoutVATTurnover,
	|				RoomSalesTurnovers.RoomRevenueWithoutVATTurnover AS RoomRevenueWithoutVATTurnover,
	|				RoomSalesTurnovers.CommissionSumTurnover AS CommissionSumTurnover,
	|				RoomSalesTurnovers.CommissionSumWithoutVATTurnover AS CommissionSumWithoutVATTurnover,
	|				RoomSalesTurnovers.DiscountSumTurnover AS DiscountSumTurnover,
	|				RoomSalesTurnovers.DiscountSumWithoutVATTurnover AS DiscountSumWithoutVATTurnover,
	|				RoomSalesTurnovers.RoomsRentedTurnover AS RoomsRentedTurnover,
	|				RoomSalesTurnovers.BedsRentedTurnover AS BedsRentedTurnover,
	|				RoomSalesTurnovers.AdditionalBedsRentedTurnover AS AdditionalBedsRentedTurnover,
	|				RoomSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover,
	|				RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
	|				RoomSalesTurnovers.RoomsCheckedInTurnover AS RoomsCheckedInTurnover,
	|				RoomSalesTurnovers.BedsCheckedInTurnover AS BedsCheckedInTurnover,
	|				RoomSalesTurnovers.AdditionalBedsCheckedInTurnover AS AdditionalBedsCheckedInTurnover,
	|				RoomSalesTurnovers.QuantityTurnover AS QuantityTurnover
	|			FROM
	|				AccumulationRegister.Sales.Turnovers(
	|						&qPeriodFrom,
	|						&qPeriodTo,
	|						DAY,
	|						NOT IsCorrection
	|							AND Hotel IN HIERARCHY (&qHotel)
	|							AND (Room IN HIERARCHY (&qRoom)
	|								OR &qIsEmptyRoom)
	|							AND (RoomType IN HIERARCHY (&qRoomType)
	|								OR &qIsEmptyRoomType)
	|							AND (Service IN HIERARCHY (&qService)
	|								OR &qIsEmptyService)
	|							AND (Service IN (&qServicesList)
	|								OR NOT &qUseServicesList)) AS RoomSalesTurnovers
	|			
	|			UNION ALL
	|			
	|			SELECT
	|				RoomSalesForecastTurnovers.ReportingCurrency,
	|				RoomSalesForecastTurnovers.Hotel,
	|				RoomSalesForecastTurnovers.Room.Parent,
	|				RoomSalesForecastTurnovers.RoomType,
	|				BEGINOFPERIOD(RoomSalesForecastTurnovers.Period, DAY),
	|				RoomSalesForecastTurnovers.SalesTurnover,
	|				RoomSalesForecastTurnovers.RoomRevenueTurnover,
	|				RoomSalesForecastTurnovers.SalesWithoutVATTurnover,
	|				RoomSalesForecastTurnovers.RoomRevenueWithoutVATTurnover,
	|				RoomSalesForecastTurnovers.CommissionSumTurnover,
	|				RoomSalesForecastTurnovers.CommissionSumWithoutVATTurnover,
	|				RoomSalesForecastTurnovers.DiscountSumTurnover,
	|				RoomSalesForecastTurnovers.DiscountSumWithoutVATTurnover,
	|				RoomSalesForecastTurnovers.RoomsRentedTurnover,
	|				RoomSalesForecastTurnovers.BedsRentedTurnover,
	|				RoomSalesForecastTurnovers.AdditionalBedsRentedTurnover,
	|				RoomSalesForecastTurnovers.GuestDaysTurnover,
	|				RoomSalesForecastTurnovers.GuestsCheckedInTurnover,
	|				RoomSalesForecastTurnovers.RoomsCheckedInTurnover,
	|				RoomSalesForecastTurnovers.BedsCheckedInTurnover,
	|				RoomSalesForecastTurnovers.AdditionalBedsCheckedInTurnover,
	|				RoomSalesForecastTurnovers.QuantityTurnover
	|			FROM
	|				AccumulationRegister.SalesForecast.Turnovers(
	|						&qForecastPeriodFrom,
	|						&qForecastPeriodTo,
	|						DAY,
	|						Hotel IN HIERARCHY (&qHotel)
	|							AND (Room IN HIERARCHY (&qRoom)
	|								OR &qIsEmptyRoom)
	|							AND (RoomType IN HIERARCHY (&qRoomType)
	|								OR &qIsEmptyRoomType)
	|							AND (Service IN HIERARCHY (&qService)
	|								OR &qIsEmptyService)
	|							AND (Service IN (&qServicesList)
	|								OR NOT &qUseServicesList)) AS RoomSalesForecastTurnovers) AS RoomSalesPerDay
	|		
	|		GROUP BY
	|			RoomSalesPerDay.ReportingCurrency,
	|			RoomSalesPerDay.Hotel,
	|			RoomSalesPerDay.RoomParent,
	|			RoomSalesPerDay.RoomType,
	|			RoomSalesPerDay.AccountingDate) AS RoomSales
	|		ON RoomInventoryTotalsPerDay.Hotel = RoomSales.Hotel
	|			AND RoomInventoryTotalsPerDay.RoomParent = RoomSales.RoomParent
	|			AND RoomInventoryTotalsPerDay.AccountingDate = RoomSales.AccountingDate
	|{WHERE
	|	RoomSales.ReportingCurrency.*,
	|	RoomInventoryTotalsPerDay.Hotel.*,
	|	RoomInventoryTotalsPerDay.RoomParent.* AS RoomParent,
	|	RoomInventoryTotalsPerDay.AccountingDate AS AccountingDate}
	|
	|ORDER BY
	|	RoomSales.ReportingCurrency.SortCode,
	|	RoomInventoryTotalsPerDay.Hotel.SortCode,
	|	RoomInventoryTotalsPerDay.RoomParent.SortCode,
	|	RoomInventoryTotalsPerDay.AccountingDate
	|{ORDER BY
	|	ReportingCurrency.*,
	|	Hotel.*,
	|	RoomParent.*,
	|	Sales,
	|	RoomRevenue,
	|	SalesWithoutVAT,
	|	RoomRevenueWithoutVAT,
	|	CommissionSum,
	|	CommissionSumWithoutVAT,
	|	DiscountSum,
	|	DiscountSumWithoutVAT,
	|	RoomsRented,
	|	BedsRented,
	|	AdditionalBedsRented,
	|	GuestDays,
	|	GuestsCheckedIn,
	|	RoomsCheckedIn,
	|	BedsCheckedIn,
	|	AdditionalBedsCheckedIn,
	|	Quantity,
	|	ADR,
	|	ADRWithoutVAT,
	|	ADBR,
	|	ADBRWithoutVAT,
	|	RevPAR,
	|	RevPARWithoutVAT,
	|	RevPAB,
	|	RevPABWithoutVAT,
	|	RevPAC,
	|	RevPACWithoutVAT,
	|	ALS,
	|	RoomsPerRoomParent,
	|	BedsPerRoomParent,
	|	RoomsBlockedPerRoomParent,
	|	BedsBlockedPerRoomParent,
	|	RoomsAvailablePerRoomParent,
	|	BedsAvailablePerRoomParent,
	|	RoomsRentedPercent,
	|	BedsRentedPercent,
	|	RoomsRentedWithBlocksPercent,
	|	BedsRentedWithBlocksPercent}
	|TOTALS
	|	SUM(Sales),
	|	SUM(RoomRevenue),
	|	SUM(SalesWithoutVAT),
	|	SUM(RoomRevenueWithoutVAT),
	|	SUM(CommissionSum),
	|	SUM(CommissionSumWithoutVAT),
	|	SUM(DiscountSum),
	|	SUM(DiscountSumWithoutVAT),
	|	SUM(RoomsRented),
	|	SUM(BedsRented),
	|	SUM(AdditionalBedsRented),
	|	SUM(GuestDays),
	|	SUM(GuestsCheckedIn),
	|	SUM(RoomsCheckedIn),
	|	SUM(BedsCheckedIn),
	|	SUM(AdditionalBedsCheckedIn),
	|	SUM(Quantity),
	|	CASE
	|		WHEN SUM(RoomsRented) <> 0
	|			THEN SUM(RoomRevenue) / SUM(RoomsRented)
	|		ELSE 0
	|	END AS ADR,
	|	CASE
	|		WHEN SUM(RoomsRented) <> 0
	|			THEN SUM(RoomRevenueWithoutVAT) / SUM(RoomsRented)
	|		ELSE 0
	|	END AS ADRWithoutVAT,
	|	CASE
	|		WHEN SUM(BedsRented) <> 0
	|			THEN SUM(RoomRevenue) / SUM(BedsRented)
	|		ELSE 0
	|	END AS ADBR,
	|	CASE
	|		WHEN SUM(BedsRented) <> 0
	|			THEN SUM(RoomRevenueWithoutVAT) / SUM(BedsRented)
	|		ELSE 0
	|	END AS ADBRWithoutVAT,
	|	CASE
	|		WHEN SUM(RoomsPerRoomParent) - SUM(RoomsBlockedPerRoomParent) <> 0
	|			THEN SUM(RoomRevenue) / (SUM(RoomsPerRoomParent) - SUM(RoomsBlockedPerRoomParent))
	|		ELSE 0
	|	END AS RevPAR,
	|	CASE
	|		WHEN SUM(RoomsPerRoomParent) - SUM(RoomsBlockedPerRoomParent) <> 0
	|			THEN SUM(RoomRevenueWithoutVAT) / (SUM(RoomsPerRoomParent) - SUM(RoomsBlockedPerRoomParent))
	|		ELSE 0
	|	END AS RevPARWithoutVAT,
	|	CASE
	|		WHEN SUM(BedsPerRoomParent) - SUM(BedsBlockedPerRoomParent) <> 0
	|			THEN SUM(RoomRevenue) / (SUM(BedsPerRoomParent) - SUM(BedsBlockedPerRoomParent))
	|		ELSE 0
	|	END AS RevPAB,
	|	CASE
	|		WHEN SUM(BedsPerRoomParent) - SUM(BedsBlockedPerRoomParent) <> 0
	|			THEN SUM(RoomRevenueWithoutVAT) / (SUM(BedsPerRoomParent) - SUM(BedsBlockedPerRoomParent))
	|		ELSE 0
	|	END AS RevPABWithoutVAT,
	|	CASE
	|		WHEN SUM(GuestDays) <> 0
	|			THEN SUM(RoomRevenue) / SUM(GuestDays)
	|		ELSE 0
	|	END AS RevPAC,
	|	CASE
	|		WHEN SUM(GuestDays) <> 0
	|			THEN SUM(RoomRevenueWithoutVAT) / SUM(GuestDays)
	|		ELSE 0
	|	END AS RevPACWithoutVAT,
	|	CASE
	|		WHEN SUM(GuestsCheckedIn) <> 0
	|			THEN SUM(GuestDays) / SUM(GuestsCheckedIn)
	|		ELSE 0
	|	END AS ALS,
	|	SUM(RoomsPerRoomParent),
	|	SUM(BedsPerRoomParent),
	|	SUM(RoomsBlockedPerRoomParent),
	|	SUM(BedsBlockedPerRoomParent),
	|	SUM(RoomsAvailablePerRoomParent),
	|	SUM(BedsAvailablePerRoomParent),
	|	CASE
	|		WHEN SUM(RoomsPerRoomParent) <> 0
	|			THEN SUM(RoomsRented) / SUM(RoomsPerRoomParent) * 100
	|		ELSE 0
	|	END AS RoomsRentedPercent,
	|	CASE
	|		WHEN SUM(BedsPerRoomParent) <> 0
	|			THEN SUM(BedsRented) / SUM(BedsPerRoomParent) * 100
	|		ELSE 0
	|	END AS BedsRentedPercent,
	|	CASE
	|		WHEN SUM(RoomsPerRoomParent) - SUM(RoomsBlockedPerRoomParent) <> 0
	|			THEN SUM(RoomsRented) / (SUM(RoomsPerRoomParent) - SUM(RoomsBlockedPerRoomParent)) * 100
	|		ELSE 0
	|	END AS RoomsRentedWithBlocksPercent,
	|	CASE
	|		WHEN SUM(BedsPerRoomParent) - SUM(BedsBlockedPerRoomParent) <> 0
	|			THEN SUM(BedsRented) / (SUM(BedsPerRoomParent) - SUM(BedsBlockedPerRoomParent)) * 100
	|		ELSE 0
	|	END AS BedsRentedWithBlocksPercent
	|BY
	|	OVERALL,
	|	ReportingCurrency,
	|	Hotel,
	|	RoomParent,
	|	AccountingDate
	|{TOTALS BY
	|	ReportingCurrency.*,
	|	Hotel.*,
	|	RoomParent.*,
	|	AccountingDate}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("en='Room folders sales turnovers';ru='Обороты по продажам групп номеров';de='Umsätze nach Verkäufen von Zimmergruppen'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
Function pmIsResource(pName) Export
	If pName = "Sales" 
	   Or pName = "RoomRevenue" 
	   Or pName = "SalesWithoutVAT" 
	   Or pName = "RoomRevenueWithoutVAT" 
	   Or pName = "CommissionSum" 
	   Or pName = "CommissionSumWithoutVAT" 
	   Or pName = "DiscountSum" 
	   Or pName = "DiscountSumWithoutVAT" 
	   Or pName = "RoomsRented" 
	   Or pName = "BedsRented" 
	   Or pName = "AdditionalBedsRented" 
	   Or pName = "GuestDays" 
	   Or pName = "GuestsCheckedIn" 
	   Or pName = "RoomsCheckedIn" 
	   Or pName = "BedsCheckedIn" 
	   Or pName = "AdditionalBedsCheckedIn" 
	   Or pName = "Quantity" 
	   Or pName = "ADR"
	   Or pName = "ADRWithoutVAT"
	   Or pName = "ADBR"
	   Or pName = "ADBRWithoutVAT"
	   Or pName = "RevPAR"
	   Or pName = "RevPARWithoutVAT"
	   Or pName = "RevPAB"
	   Or pName = "RevPABWithoutVAT"
	   Or pName = "RevPAC"
	   Or pName = "RevPACWithoutVAT"
	   Or pName = "ALS"
	   Or pName = "RoomsPerRoomParent"
	   Or pName = "BedsPerRoomParent"
	   Or pName = "RoomsBlockedPerRoomParent"
	   Or pName = "BedsBlockedPerRoomParent"
	   Or pName = "RoomsAvailablePerRoomParent"
	   Or pName = "BedsAvailablePerRoomParent"
	   Or pName = "RoomsRentedPercent"
	   Or pName = "BedsRentedPercent"
	   Or pName = "RoomsRentedWithBlocksPercent"
	   Or pName = "BedsRentedWithBlocksPercent" Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // pmIsResource

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
