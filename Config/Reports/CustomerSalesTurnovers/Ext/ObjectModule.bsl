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
	If ValueIsFilled(Customer) Then
		If Not Customer.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("de='Firma ';en='Customer ';ru='Контрагент '") + 
			                     TrimAll(Customer.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("de='Gruppe Firmen ';en='Customers folder ';ru='Группа контрагентов '") + 
			                     TrimAll(Customer.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(Contract) Then
		vParamPresentation = vParamPresentation + NStr("en='Contract ';ru='Договор ';de='Vertrag '") + 
							 TrimAll(Contract.Description) + 
							 ";" + Chars.LF;
	EndIf;							 
	If ValueIsFilled(GuestGroup) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Группа гостей '; en = 'Guest group '; de = 'Gastgruppe '") + 
							 TrimAll(TrimAll(GuestGroup.Code) + " " + TrimAll(GuestGroup.Description)) + 
							 ";" + Chars.LF;
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
			vParamPresentation = vParamPresentation + NStr("en='Hotels folder ';ru='Группа гостиниц ';de='Gruppe Hotels '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
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
	ReportBuilder.Parameters.Insert("qCustomer", Customer);
	ReportBuilder.Parameters.Insert("qIsEmptyCustomer", Not ValueIsFilled(Customer));
	ReportBuilder.Parameters.Insert("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	ReportBuilder.Parameters.Insert("qContract", Contract);
	ReportBuilder.Parameters.Insert("qIsEmptyContract", Not ValueIsFilled(Contract));
	ReportBuilder.Parameters.Insert("qGuestGroup", GuestGroup);
	ReportBuilder.Parameters.Insert("qEmptyDate", '00010101');
	ReportBuilder.Parameters.Insert("qIsEmptyGuestGroup", Not ValueIsFilled(GuestGroup));
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
	ReportBuilder.Parameters.Insert("qCustomAttribute1", CustomAttribute1);
	ReportBuilder.Parameters.Insert("qCustomAttribute2", CustomAttribute2);
	ReportBuilder.Parameters.Insert("qCustomAttribute3", CustomAttribute3);
	// Check report dimensions being used in current report settings
	vReportDimensionsUsage = New ValueTable();
	vReportDimensionsUsage.Columns.Add("Name");
	vReportDimensionsUsage.Columns.Add("IsUsed", cmGetBooleanTypeDescription());
	For Each vDim In Metadata.AccumulationRegisters.Sales.Dimensions Do
		vReportDimensionsUsageRow = vReportDimensionsUsage.Add();
		vReportDimensionsUsageRow.Name = vDim.Name;
		vReportDimensionsUsageRow.IsUsed = False;
	EndDo;
	vSelectedFields = cmGetReportUsedFields(ReportBuilder);
	For Each vReportDimensionsUsageRow In vReportDimensionsUsage Do
		If vReportDimensionsUsageRow.Name = "Hotel" Then
			vReportDimensionsUsageRow.IsUsed = True;
		EndIf;
		If vReportDimensionsUsageRow.Name = "GuestGroup" Then
			vReportDimensionsUsageRow.IsUsed = True;
		EndIf;
		If vReportDimensionsUsageRow.Name = "ParentDoc" Then
			vReportDimensionsUsageRow.IsUsed = True;
		EndIf;
		If vReportDimensionsUsageRow.Name = "Client" Then
			vReportDimensionsUsageRow.IsUsed = True;
		EndIf;
		If vReportDimensionsUsageRow.Name = "AccountingDate" Then
			vReportDimensionsUsageRow.IsUsed = True;
		EndIf;
		For Each vReportField In vSelectedFields Do
			If vReportField.DataPath = vReportDimensionsUsageRow.Name Or Left(vReportField.DataPath, StrLen(vReportDimensionsUsageRow.Name)) = vReportDimensionsUsageRow.Name Then
				vReportDimensionsUsageRow.IsUsed = True;
			EndIf;
		EndDo;
	EndDo;
	vRBSettings = ReportBuilder.GetSettings(True, True, True, True, True);
	vQryText = ReportBuilder.Text;
	For Each vReportDimensionsUsageRow In vReportDimensionsUsage Do
		If Not vReportDimensionsUsageRow.IsUsed Then
			If vReportDimensionsUsageRow.Name = "AccountingDate" Then
				vQryText = StrReplace(vQryText, "SalesTurnovers." + vReportDimensionsUsageRow.Name + " AS ", "&qEmptyDate AS ");
				vQryText = StrReplace(vQryText, "SalesForecastTurnovers." + vReportDimensionsUsageRow.Name + ",", "&qEmptyDate,");
			Else
				vQryText = StrReplace(vQryText, "SalesTurnovers." + vReportDimensionsUsageRow.Name + " AS ", "NULL AS ");
				vQryText = StrReplace(vQryText, "SalesForecastTurnovers." + vReportDimensionsUsageRow.Name + ",", "NULL,");
			EndIf;
			If vReportDimensionsUsageRow.Name = "Client" Then
				vQryText = StrReplace(vQryText, "CustomerSalesFull.Client = ClientCheckInStatistics.Client", "FALSE");
			EndIf;
			If vReportDimensionsUsageRow.Name = "Customer" Then
				vQryText = StrReplace(vQryText, "CustomerSalesFull.Customer = CustomerCheckInStatistics.Customer", "FALSE");
			EndIf;
			If vReportDimensionsUsageRow.Name = "AccountingDate" Then
				vQryText = StrReplace(vQryText, "DAY(CustomerSales.AccountingDate)", "0");
				vQryText = StrReplace(vQryText, "DATEADD(BEGINOFPERIOD(CustomerSales.AccountingDate, WEEK), YEAR, -YEAR(CustomerSales.AccountingDate) + 1)", "&qEmptyDate");
				vQryText = StrReplace(vQryText, "DATEADD(BEGINOFPERIOD(CustomerSales.AccountingDate, MONTH), YEAR, -YEAR(CustomerSales.AccountingDate) + 1)", "&qEmptyDate");
				vQryText = StrReplace(vQryText, "DATEADD(BEGINOFPERIOD(CustomerSales.AccountingDate, QUARTER), YEAR, -YEAR(CustomerSales.AccountingDate) + 1)", "&qEmptyDate");
				vQryText = StrReplace(vQryText, "YEAR(CustomerSales.AccountingDate)", "0");
			EndIf;				
		EndIf;
	EndDo;
	ReportBuilder.Text = vQryText;
	ReportBuilder.FillSettings();
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	cmFillReportAttributesPresentations(ThisObject);
	ReportBuilder.Template = Undefined;
	
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
	
	// Restore report default query text
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	cmFillReportAttributesPresentations(ThisObject);
	ReportBuilder.Template = Undefined;
EndProcedure // pmGenerate
	
// -----------------------------------------------------------------------------
Procedure pmInitializeReportBuilder() Export
	ReportBuilder = New ReportBuilder();
	
	// Initialize default query text
	QueryText = 
	"SELECT
	|	CustomerTotals.Hotel AS Hotel,
	|	SUM(CustomerTotals.TotalSales) AS TotalSales,
	|	SUM(CustomerTotals.TotalRoomsRented) AS TotalRoomsRented,
	|	SUM(CustomerTotals.TotalBedsRented) AS TotalBedsRented,
	|	SUM(CustomerTotals.TotalRoomRevenue) AS TotalRoomRevenue
	|INTO CustomerTotals
	|FROM
	|	(SELECT
	|		SalesTurnovers.Hotel AS Hotel,
	|		SalesTurnovers.SalesTurnover AS TotalSales,
	|		SalesTurnovers.RoomsRentedTurnover AS TotalRoomsRented,
	|		SalesTurnovers.BedsRentedTurnover AS TotalBedsRented,
	|		SalesTurnovers.RoomRevenueTurnover AS TotalRoomRevenue
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection
	|					AND Hotel IN HIERARCHY (&qHotel)
	|					AND (Service IN (&qServicesList)
	|						OR NOT &qUseServicesList)) AS SalesTurnovers
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		SalesForecastTurnovers.Hotel,
	|		SalesForecastTurnovers.SalesTurnover,
	|		SalesForecastTurnovers.RoomsRentedTurnover,
	|		SalesForecastTurnovers.BedsRentedTurnover,
	|		SalesForecastTurnovers.RoomRevenueTurnover
	|	FROM
	|		AccumulationRegister.SalesForecast.Turnovers(
	|				&qForecastPeriodFrom,
	|				&qForecastPeriodTo,
	|				Period,
	|				Hotel IN HIERARCHY (&qHotel)
	|					AND (Service IN (&qServicesList)
	|						OR NOT &qUseServicesList)) AS SalesForecastTurnovers) AS CustomerTotals
	|
	|GROUP BY
	|	CustomerTotals.Hotel
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CustomerMonthlyTotals.Hotel AS Hotel,
	|	CustomerMonthlyTotals.Period AS Period,
	|	SUM(CustomerMonthlyTotals.TotalSales) AS MonthlySales,
	|	SUM(CustomerMonthlyTotals.TotalRoomsRented) AS MonthlyRoomsRented,
	|	SUM(CustomerMonthlyTotals.TotalBedsRented) AS MonthlyBedsRented,
	|	SUM(CustomerMonthlyTotals.TotalRoomRevenue) AS MonthlyRoomRevenue
	|INTO CustomerMonthlyTotals
	|FROM
	|	(SELECT
	|		SalesMonthlyTurnovers.Hotel AS Hotel,
	|		BEGINOFPERIOD(SalesMonthlyTurnovers.Period, MONTH) AS Period,
	|		SalesMonthlyTurnovers.SalesTurnover AS TotalSales,
	|		SalesMonthlyTurnovers.RoomsRentedTurnover AS TotalRoomsRented,
	|		SalesMonthlyTurnovers.BedsRentedTurnover AS TotalBedsRented,
	|		SalesMonthlyTurnovers.RoomRevenueTurnover AS TotalRoomRevenue
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Day,
	|				NOT IsCorrection
	|					AND Hotel IN HIERARCHY (&qHotel)
	|					AND (Service IN (&qServicesList)
	|						OR NOT &qUseServicesList)) AS SalesMonthlyTurnovers
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		SalesForecastMonthlyTurnovers.Hotel,
	|		BEGINOFPERIOD(SalesForecastMonthlyTurnovers.Period, MONTH),
	|		SalesForecastMonthlyTurnovers.SalesTurnover,
	|		SalesForecastMonthlyTurnovers.RoomsRentedTurnover,
	|		SalesForecastMonthlyTurnovers.BedsRentedTurnover,
	|		SalesForecastMonthlyTurnovers.RoomRevenueTurnover
	|	FROM
	|		AccumulationRegister.SalesForecast.Turnovers(
	|				&qForecastPeriodFrom,
	|				&qForecastPeriodTo,
	|				Day,
	|				Hotel IN HIERARCHY (&qHotel)
	|					AND (Service IN (&qServicesList)
	|						OR NOT &qUseServicesList)) AS SalesForecastMonthlyTurnovers) AS CustomerMonthlyTotals
	|
	|GROUP BY
	|	CustomerMonthlyTotals.Hotel,
	|	CustomerMonthlyTotals.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventoryTotalsPerMonth.Hotel AS Hotel,
	|	BEGINOFPERIOD(RoomInventoryTotalsPerMonth.Period, MONTH) AS Period,
	|	SUM(RoomInventoryTotalsPerMonth.CounterClosingBalance) AS CounterClosingBalance,
	|	SUM(RoomInventoryTotalsPerMonth.TotalRoomsClosingBalance) AS TotalRooms,
	|	SUM(RoomInventoryTotalsPerMonth.TotalBedsClosingBalance) AS TotalBeds,
	|	-SUM(RoomInventoryTotalsPerMonth.RoomsBlockedClosingBalance) AS TotalRoomsBlocked,
	|	-SUM(RoomInventoryTotalsPerMonth.BedsBlockedClosingBalance) AS TotalBedsBlocked
	|INTO HotelInventoryTotalsPerMonth
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qPeriodFrom, &qPeriodTo, Day, RegisterRecordsAndPeriodBoundaries, Hotel IN HIERARCHY (&qHotel)) AS RoomInventoryTotalsPerMonth
	|
	|GROUP BY
	|	RoomInventoryTotalsPerMonth.Hotel,
	|	BEGINOFPERIOD(RoomInventoryTotalsPerMonth.Period, MONTH)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CustomerSalesWithForecast.Hotel AS Hotel,
	|	CustomerSalesWithForecast.Company AS Company,
	|	CustomerSalesWithForecast.ReportingCurrency AS ReportingCurrency,
	|	CustomerSalesWithForecast.Agent AS Agent,
	|	CustomerSalesWithForecast.Customer AS Customer,
	|	CustomerSalesWithForecast.Contract AS Contract,
	|	CustomerSalesWithForecast.GuestGroup AS GuestGroup,
	|	CustomerSalesWithForecast.AccountingDate AS AccountingDate,
	|	BEGINOFPERIOD(CustomerSalesWithForecast.AccountingDate, MONTH) AS AccountingMonthDate,
	|	DATEADD(CustomerSalesWithForecast.AccountingDate, DAY, 1) AS NextAccountingDate,
	|	BEGINOFPERIOD(DATEADD(CustomerSalesWithForecast.AccountingDate, DAY, 1), MONTH) AS NextAccountingMonthDate,
	|	CustomerSalesWithForecast.Client AS Client,
	|	CustomerSalesWithForecast.ParentDoc AS ParentDoc,
	|	CustomerSalesWithForecast.CheckOutDate AS CheckOutDate,
	|	CustomerSalesWithForecast.AccommodationStatus AS AccommodationStatus,
	|	CustomerSalesWithForecast.Service AS Service,
	|	CustomerSalesWithForecast.PaymentMethod AS PaymentMethod,
	|	CustomerSalesWithForecast.ClientType AS ClientType,
	|	CustomerSalesWithForecast.Folio AS Folio,
	|	CustomerSalesWithForecast.RoomRate AS RoomRate,
	|	CustomerSalesWithForecast.Room AS Room,
	|	CustomerSalesWithForecast.RoomType AS RoomType,
	|	CustomerSalesWithForecast.AccommodationType AS AccommodationType,
	|	CustomerSalesWithForecast.TripPurpose AS TripPurpose,
	|	CustomerSalesWithForecast.MarketingCode AS MarketingCode,
	|	CustomerSalesWithForecast.SourceOfBusiness AS SourceOfBusiness,
	|	CustomerSalesWithForecast.Resource AS Resource,
	|	CustomerSalesWithForecast.ResourceType AS ResourceType,
	|	CustomerSalesWithForecast.Author AS Author,
	|	CustomerSalesWithForecast.Discount AS Discount,
	|	CustomerSalesWithForecast.DiscountType AS DiscountType,
	|	CustomerSalesWithForecast.DiscountCard AS DiscountCard,
	|	CustomerSalesWithForecast.AgentCommissionType AS AgentCommissionType,
	|	CustomerSalesWithForecast.AgentCommission AS AgentCommission,
	|	CustomerSalesWithForecast.VATRate AS VATRate,
	|	CustomerSalesWithForecast.Price AS Price,
	|	CustomerSalesWithForecast.HotelProduct AS HotelProduct,
	|	CustomerSalesWithForecast.SalesTurnover AS SalesTurnover,
	|	CustomerSalesWithForecast.RoomRevenueTurnover AS RoomRevenueTurnover,
	|	CustomerSalesWithForecast.ExtraBedRevenueTurnover AS ExtraBedRevenueTurnover,
	|	CustomerSalesWithForecast.SalesWithoutVATTurnover AS SalesWithoutVATTurnover,
	|	CustomerSalesWithForecast.RoomRevenueWithoutVATTurnover AS RoomRevenueWithoutVATTurnover,
	|	CustomerSalesWithForecast.ExtraBedRevenueWithoutVATTurnover AS ExtraBedRevenueWithoutVATTurnover,
	|	CustomerSalesWithForecast.CommissionSumTurnover AS CommissionSumTurnover,
	|	CustomerSalesWithForecast.CommissionSumWithoutVATTurnover AS CommissionSumWithoutVATTurnover,
	|	CustomerSalesWithForecast.DiscountSumTurnover AS DiscountSumTurnover,
	|	CustomerSalesWithForecast.DiscountSumWithoutVATTurnover AS DiscountSumWithoutVATTurnover,
	|	CustomerSalesWithForecast.RoomsRentedTurnover AS RoomsRentedTurnover,
	|	CustomerSalesWithForecast.BedsRentedTurnover AS BedsRentedTurnover,
	|	CustomerSalesWithForecast.AdditionalBedsRentedTurnover AS AdditionalBedsRentedTurnover,
	|	CustomerSalesWithForecast.GuestDaysTurnover AS GuestDaysTurnover,
	|	CustomerSalesWithForecast.BookingWindowTurnover AS BookingWindowTurnover,
	|	CustomerSalesWithForecast.QuantityTurnover AS QuantityTurnover,
	|	CustomerSalesWithForecast.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
	|	CustomerSalesWithForecast.RoomsCheckedInTurnover AS RoomsCheckedInTurnover,
	|	CustomerSalesWithForecast.BedsCheckedInTurnover AS BedsCheckedInTurnover,
	|	CustomerSalesWithForecast.AdditionalBedsCheckedInTurnover AS AdditionalBedsCheckedInTurnover,
	|	CASE
	|		WHEN DATEADD(CustomerSalesWithForecast.AccountingDate, DAY, 1) = BEGINOFPERIOD(ISNULL(CustomerSalesWithForecast.CheckOutDate, &qEmptyDate), DAY)
	|				AND ISNULL(CustomerSalesWithForecast.AccommodationStatus.IsCheckOut, TRUE)
	|			THEN CustomerSalesWithForecast.GuestDaysTurnover
	|		ELSE 0
	|	END AS GuestsCheckedOutTurnover,
	|	CASE
	|		WHEN DATEADD(CustomerSalesWithForecast.AccountingDate, DAY, 1) = BEGINOFPERIOD(ISNULL(CustomerSalesWithForecast.CheckOutDate, &qEmptyDate), DAY)
	|				AND ISNULL(CustomerSalesWithForecast.AccommodationStatus.IsCheckOut, TRUE)
	|			THEN CustomerSalesWithForecast.RoomsRentedTurnover
	|		ELSE 0
	|	END AS RoomsCheckedOutTurnover,
	|	CASE
	|		WHEN DATEADD(CustomerSalesWithForecast.AccountingDate, DAY, 1) = BEGINOFPERIOD(ISNULL(CustomerSalesWithForecast.CheckOutDate, &qEmptyDate), DAY)
	|				AND ISNULL(CustomerSalesWithForecast.AccommodationStatus.IsCheckOut, TRUE)
	|			THEN CustomerSalesWithForecast.BedsRentedTurnover
	|		ELSE 0
	|	END AS BedsCheckedOutTurnover,
	|	CASE
	|		WHEN DATEADD(CustomerSalesWithForecast.AccountingDate, DAY, 1) = BEGINOFPERIOD(ISNULL(CustomerSalesWithForecast.CheckOutDate, &qEmptyDate), DAY)
	|				AND ISNULL(CustomerSalesWithForecast.AccommodationStatus.IsCheckOut, TRUE)
	|			THEN CustomerSalesWithForecast.AdditionalBedsRentedTurnover
	|		ELSE 0
	|	END AS AdditionalBedsCheckedOutTurnover
	|INTO CustomerSalesWithForecast
	|FROM
	|	(SELECT
	|		SalesTurnovers.Hotel AS Hotel,
	|		SalesTurnovers.Company AS Company,
	|		SalesTurnovers.ReportingCurrency AS ReportingCurrency,
	|		SalesTurnovers.Agent AS Agent,
	|		CASE
	|			WHEN SalesTurnovers.Customer = &qEmptyCustomer
	|				THEN SalesTurnovers.Hotel.IndividualsCustomer
	|			ELSE SalesTurnovers.Customer
	|		END AS Customer,
	|		CASE
	|			WHEN SalesTurnovers.Customer = &qEmptyCustomer
	|				THEN SalesTurnovers.Hotel.IndividualsContract
	|			ELSE SalesTurnovers.Contract
	|		END AS Contract,
	|		SalesTurnovers.GuestGroup AS GuestGroup,
	|		SalesTurnovers.AccountingDate AS AccountingDate,
	|		SalesTurnovers.Client AS Client,
	|		SalesTurnovers.ParentDoc AS ParentDoc,
	|		SalesTurnovers.ParentDoc.CheckOutDate AS CheckOutDate,
	|		SalesTurnovers.ParentDoc.AccommodationStatus AS AccommodationStatus,
	|		SalesTurnovers.Service AS Service,
	|		SalesTurnovers.PaymentMethod AS PaymentMethod,
	|		SalesTurnovers.ClientType AS ClientType,
	|		SalesTurnovers.Folio AS Folio,
	|		SalesTurnovers.RoomRate AS RoomRate,
	|		SalesTurnovers.Room AS Room,
	|		SalesTurnovers.RoomType AS RoomType,
	|		SalesTurnovers.AccommodationType AS AccommodationType,
	|		SalesTurnovers.TripPurpose AS TripPurpose,
	|		SalesTurnovers.MarketingCode AS MarketingCode,
	|		SalesTurnovers.SourceOfBusiness AS SourceOfBusiness,
	|		SalesTurnovers.Resource AS Resource,
	|		SalesTurnovers.ResourceType AS ResourceType,
	|		SalesTurnovers.Author AS Author,
	|		SalesTurnovers.Discount AS Discount,
	|		SalesTurnovers.DiscountType AS DiscountType,
	|		SalesTurnovers.DiscountCard AS DiscountCard,
	|		SalesTurnovers.AgentCommissionType AS AgentCommissionType,
	|		SalesTurnovers.AgentCommission AS AgentCommission,
	|		SalesTurnovers.VATRate AS VATRate,
	|		SalesTurnovers.Price AS Price,
	|		SalesTurnovers.HotelProduct AS HotelProduct,
	|		SalesTurnovers.SalesTurnover AS SalesTurnover,
	|		SalesTurnovers.RoomRevenueTurnover AS RoomRevenueTurnover,
	|		SalesTurnovers.ExtraBedRevenueTurnover AS ExtraBedRevenueTurnover,
	|		SalesTurnovers.SalesWithoutVATTurnover AS SalesWithoutVATTurnover,
	|		SalesTurnovers.RoomRevenueWithoutVATTurnover AS RoomRevenueWithoutVATTurnover,
	|		SalesTurnovers.ExtraBedRevenueWithoutVATTurnover AS ExtraBedRevenueWithoutVATTurnover,
	|		SalesTurnovers.CommissionSumTurnover AS CommissionSumTurnover,
	|		SalesTurnovers.CommissionSumWithoutVATTurnover AS CommissionSumWithoutVATTurnover,
	|		SalesTurnovers.DiscountSumTurnover AS DiscountSumTurnover,
	|		SalesTurnovers.DiscountSumWithoutVATTurnover AS DiscountSumWithoutVATTurnover,
	|		SalesTurnovers.RoomsRentedTurnover AS RoomsRentedTurnover,
	|		SalesTurnovers.BedsRentedTurnover AS BedsRentedTurnover,
	|		SalesTurnovers.AdditionalBedsRentedTurnover AS AdditionalBedsRentedTurnover,
	|		SalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover,
	|		SalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
	|		SalesTurnovers.RoomsCheckedInTurnover AS RoomsCheckedInTurnover,
	|		SalesTurnovers.BedsCheckedInTurnover AS BedsCheckedInTurnover,
	|		SalesTurnovers.AdditionalBedsCheckedInTurnover AS AdditionalBedsCheckedInTurnover,
	|		SalesTurnovers.BookingWindowTurnover AS BookingWindowTurnover,
	|		SalesTurnovers.QuantityTurnover AS QuantityTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection
	|					AND Hotel IN HIERARCHY (&qHotel)
	|					AND (Customer IN HIERARCHY (&qCustomer)
	|						OR &qIsEmptyCustomer)
	|					AND (Contract = &qContract
	|						OR &qIsEmptyContract)
	|					AND (GuestGroup = &qGuestGroup
	|						OR &qIsEmptyGuestGroup)
	|					AND (Service IN (&qServicesList)
	|						OR NOT &qUseServicesList)) AS SalesTurnovers
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		SalesForecastTurnovers.Hotel,
	|		SalesForecastTurnovers.Company,
	|		SalesForecastTurnovers.ReportingCurrency,
	|		SalesForecastTurnovers.Agent,
	|		CASE
	|			WHEN SalesForecastTurnovers.Customer = &qEmptyCustomer
	|				THEN SalesForecastTurnovers.Hotel.IndividualsCustomer
	|			ELSE SalesForecastTurnovers.Customer
	|		END,
	|		CASE
	|			WHEN SalesForecastTurnovers.Customer = &qEmptyCustomer
	|				THEN SalesForecastTurnovers.Hotel.IndividualsContract
	|			ELSE SalesForecastTurnovers.Contract
	|		END,
	|		SalesForecastTurnovers.GuestGroup,
	|		SalesForecastTurnovers.AccountingDate,
	|		SalesForecastTurnovers.Client,
	|		SalesForecastTurnovers.ParentDoc,
	|		SalesForecastTurnovers.ParentDoc.CheckOutDate,
	|		SalesForecastTurnovers.ParentDoc.AccommodationStatus,
	|		SalesForecastTurnovers.Service,
	|		SalesForecastTurnovers.PaymentMethod,
	|		SalesForecastTurnovers.ClientType,
	|		SalesForecastTurnovers.Folio,
	|		SalesForecastTurnovers.RoomRate,
	|		SalesForecastTurnovers.Room,
	|		SalesForecastTurnovers.RoomType,
	|		SalesForecastTurnovers.AccommodationType,
	|		SalesForecastTurnovers.TripPurpose,
	|		SalesForecastTurnovers.MarketingCode,
	|		SalesForecastTurnovers.SourceOfBusiness,
	|		SalesForecastTurnovers.Resource,
	|		SalesForecastTurnovers.ResourceType,
	|		SalesForecastTurnovers.Author,
	|		SalesForecastTurnovers.Discount,
	|		SalesForecastTurnovers.DiscountType,
	|		SalesForecastTurnovers.DiscountCard,
	|		SalesForecastTurnovers.AgentCommissionType,
	|		SalesForecastTurnovers.AgentCommission,
	|		SalesForecastTurnovers.VATRate,
	|		SalesForecastTurnovers.Price,
	|		SalesForecastTurnovers.HotelProduct,
	|		SalesForecastTurnovers.SalesTurnover,
	|		SalesForecastTurnovers.RoomRevenueTurnover,
	|		SalesForecastTurnovers.ExtraBedRevenueTurnover,
	|		SalesForecastTurnovers.SalesWithoutVATTurnover,
	|		SalesForecastTurnovers.RoomRevenueWithoutVATTurnover,
	|		SalesForecastTurnovers.ExtraBedRevenueWithoutVATTurnover,
	|		SalesForecastTurnovers.CommissionSumTurnover,
	|		SalesForecastTurnovers.CommissionSumWithoutVATTurnover,
	|		SalesForecastTurnovers.DiscountSumTurnover,
	|		SalesForecastTurnovers.DiscountSumWithoutVATTurnover,
	|		SalesForecastTurnovers.RoomsRentedTurnover,
	|		SalesForecastTurnovers.BedsRentedTurnover,
	|		SalesForecastTurnovers.AdditionalBedsRentedTurnover,
	|		SalesForecastTurnovers.GuestDaysTurnover,
	|		SalesForecastTurnovers.GuestsCheckedInTurnover,
	|		SalesForecastTurnovers.RoomsCheckedInTurnover,
	|		SalesForecastTurnovers.BedsCheckedInTurnover,
	|		SalesForecastTurnovers.AdditionalBedsCheckedInTurnover,
	|		SalesForecastTurnovers.BookingWindowTurnover,
	|		SalesForecastTurnovers.QuantityTurnover
	|	FROM
	|		AccumulationRegister.SalesForecast.Turnovers(
	|				&qForecastPeriodFrom,
	|				&qForecastPeriodTo,
	|				Period,
	|				Hotel IN HIERARCHY (&qHotel)
	|					AND (Customer IN HIERARCHY (&qCustomer)
	|						OR &qIsEmptyCustomer)
	|					AND (Contract = &qContract
	|						OR &qIsEmptyContract)
	|					AND (GuestGroup = &qGuestGroup
	|						OR &qIsEmptyGuestGroup)
	|					AND (Service IN (&qServicesList)
	|						OR NOT &qUseServicesList)) AS SalesForecastTurnovers) AS CustomerSalesWithForecast
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CustomerSalesWithCheckout.Hotel AS Hotel,
	|	CustomerSalesWithCheckout.Company AS Company,
	|	CustomerSalesWithCheckout.ReportingCurrency AS ReportingCurrency,
	|	CustomerSalesWithCheckout.Agent AS Agent,
	|	CustomerSalesWithCheckout.Customer AS Customer,
	|	CustomerSalesWithCheckout.Contract AS Contract,
	|	CustomerSalesWithCheckout.GuestGroup AS GuestGroup,
	|	CustomerSalesWithCheckout.AccountingDate AS AccountingDate,
	|	CustomerSalesWithCheckout.AccountingMonthDate AS AccountingMonthDate,
	|	CustomerSalesWithCheckout.Client AS Client,
	|	CustomerSalesWithCheckout.ParentDoc AS ParentDoc,
	|	CustomerSalesWithCheckout.Service AS Service,
	|	CustomerSalesWithCheckout.PaymentMethod AS PaymentMethod,
	|	CustomerSalesWithCheckout.ClientType AS ClientType,
	|	CustomerSalesWithCheckout.Folio AS Folio,
	|	CustomerSalesWithCheckout.RoomRate AS RoomRate,
	|	CustomerSalesWithCheckout.Room AS Room,
	|	CustomerSalesWithCheckout.RoomType AS RoomType,
	|	CustomerSalesWithCheckout.AccommodationType AS AccommodationType,
	|	CustomerSalesWithCheckout.TripPurpose AS TripPurpose,
	|	CustomerSalesWithCheckout.MarketingCode AS MarketingCode,
	|	CustomerSalesWithCheckout.SourceOfBusiness AS SourceOfBusiness,
	|	CustomerSalesWithCheckout.Resource AS Resource,
	|	CustomerSalesWithCheckout.ResourceType AS ResourceType,
	|	CustomerSalesWithCheckout.Author AS Author,
	|	CustomerSalesWithCheckout.Discount AS Discount,
	|	CustomerSalesWithCheckout.DiscountType AS DiscountType,
	|	CustomerSalesWithCheckout.DiscountCard AS DiscountCard,
	|	CustomerSalesWithCheckout.AgentCommissionType AS AgentCommissionType,
	|	CustomerSalesWithCheckout.AgentCommission AS AgentCommission,
	|	CustomerSalesWithCheckout.VATRate AS VATRate,
	|	CustomerSalesWithCheckout.Price AS Price,
	|	CustomerSalesWithCheckout.HotelProduct AS HotelProduct,
	|	SUM(CustomerSalesWithCheckout.SalesTurnover) AS SalesTurnover,
	|	SUM(CustomerSalesWithCheckout.RoomRevenueTurnover) AS RoomRevenueTurnover,
	|	SUM(CustomerSalesWithCheckout.ExtraBedRevenueTurnover) AS ExtraBedRevenueTurnover,
	|	SUM(CustomerSalesWithCheckout.SalesWithoutVATTurnover) AS SalesWithoutVATTurnover,
	|	SUM(CustomerSalesWithCheckout.RoomRevenueWithoutVATTurnover) AS RoomRevenueWithoutVATTurnover,
	|	SUM(CustomerSalesWithCheckout.ExtraBedRevenueWithoutVATTurnover) AS ExtraBedRevenueWithoutVATTurnover,
	|	SUM(CustomerSalesWithCheckout.CommissionSumTurnover) AS CommissionSumTurnover,
	|	SUM(CustomerSalesWithCheckout.CommissionSumWithoutVATTurnover) AS CommissionSumWithoutVATTurnover,
	|	SUM(CustomerSalesWithCheckout.DiscountSumTurnover) AS DiscountSumTurnover,
	|	SUM(CustomerSalesWithCheckout.DiscountSumWithoutVATTurnover) AS DiscountSumWithoutVATTurnover,
	|	SUM(CustomerSalesWithCheckout.RoomsRentedTurnover) AS RoomsRentedTurnover,
	|	SUM(CustomerSalesWithCheckout.BedsRentedTurnover) AS BedsRentedTurnover,
	|	SUM(CustomerSalesWithCheckout.AdditionalBedsRentedTurnover) AS AdditionalBedsRentedTurnover,
	|	SUM(CustomerSalesWithCheckout.GuestDaysTurnover) AS GuestDaysTurnover,
	|	SUM(CustomerSalesWithCheckout.BookingWindowTurnover) AS BookingWindowTurnover,
	|	SUM(CustomerSalesWithCheckout.QuantityTurnover) AS QuantityTurnover,
	|	SUM(CustomerSalesWithCheckout.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover,
	|	SUM(CustomerSalesWithCheckout.RoomsCheckedInTurnover) AS RoomsCheckedInTurnover,
	|	SUM(CustomerSalesWithCheckout.BedsCheckedInTurnover) AS BedsCheckedInTurnover,
	|	SUM(CustomerSalesWithCheckout.AdditionalBedsCheckedInTurnover) AS AdditionalBedsCheckedInTurnover,
	|	SUM(CustomerSalesWithCheckout.GuestsCheckedOutTurnover) AS GuestsCheckedOutTurnover,
	|	SUM(CustomerSalesWithCheckout.RoomsCheckedOutTurnover) AS RoomsCheckedOutTurnover,
	|	SUM(CustomerSalesWithCheckout.BedsCheckedOutTurnover) AS BedsCheckedOutTurnover,
	|	SUM(CustomerSalesWithCheckout.AdditionalBedsCheckedOutTurnover) AS AdditionalBedsCheckedOutTurnover
	|INTO CustomerSalesWithCheckout
	|FROM
	|	(SELECT
	|		CustomerSalesWithForecast.Hotel AS Hotel,
	|		CustomerSalesWithForecast.Company AS Company,
	|		CustomerSalesWithForecast.ReportingCurrency AS ReportingCurrency,
	|		CustomerSalesWithForecast.Agent AS Agent,
	|		CustomerSalesWithForecast.Customer AS Customer,
	|		CustomerSalesWithForecast.Contract AS Contract,
	|		CustomerSalesWithForecast.GuestGroup AS GuestGroup,
	|		CustomerSalesWithForecast.AccountingDate AS AccountingDate,
	|		CustomerSalesWithForecast.AccountingMonthDate AS AccountingMonthDate,
	|		CustomerSalesWithForecast.Client AS Client,
	|		CustomerSalesWithForecast.ParentDoc AS ParentDoc,
	|		CustomerSalesWithForecast.Service AS Service,
	|		CustomerSalesWithForecast.PaymentMethod AS PaymentMethod,
	|		CustomerSalesWithForecast.ClientType AS ClientType,
	|		CustomerSalesWithForecast.Folio AS Folio,
	|		CustomerSalesWithForecast.RoomRate AS RoomRate,
	|		CustomerSalesWithForecast.Room AS Room,
	|		CustomerSalesWithForecast.RoomType AS RoomType,
	|		CustomerSalesWithForecast.AccommodationType AS AccommodationType,
	|		CustomerSalesWithForecast.TripPurpose AS TripPurpose,
	|		CustomerSalesWithForecast.MarketingCode AS MarketingCode,
	|		CustomerSalesWithForecast.SourceOfBusiness AS SourceOfBusiness,
	|		CustomerSalesWithForecast.Resource AS Resource,
	|		CustomerSalesWithForecast.ResourceType AS ResourceType,
	|		CustomerSalesWithForecast.Author AS Author,
	|		CustomerSalesWithForecast.Discount AS Discount,
	|		CustomerSalesWithForecast.DiscountType AS DiscountType,
	|		CustomerSalesWithForecast.DiscountCard AS DiscountCard,
	|		CustomerSalesWithForecast.AgentCommissionType AS AgentCommissionType,
	|		CustomerSalesWithForecast.AgentCommission AS AgentCommission,
	|		CustomerSalesWithForecast.VATRate AS VATRate,
	|		CustomerSalesWithForecast.Price AS Price,
	|		CustomerSalesWithForecast.HotelProduct AS HotelProduct,
	|		CustomerSalesWithForecast.SalesTurnover AS SalesTurnover,
	|		CustomerSalesWithForecast.RoomRevenueTurnover AS RoomRevenueTurnover,
	|		CustomerSalesWithForecast.ExtraBedRevenueTurnover AS ExtraBedRevenueTurnover,
	|		CustomerSalesWithForecast.SalesWithoutVATTurnover AS SalesWithoutVATTurnover,
	|		CustomerSalesWithForecast.RoomRevenueWithoutVATTurnover AS RoomRevenueWithoutVATTurnover,
	|		CustomerSalesWithForecast.ExtraBedRevenueWithoutVATTurnover AS ExtraBedRevenueWithoutVATTurnover,
	|		CustomerSalesWithForecast.CommissionSumTurnover AS CommissionSumTurnover,
	|		CustomerSalesWithForecast.CommissionSumWithoutVATTurnover AS CommissionSumWithoutVATTurnover,
	|		CustomerSalesWithForecast.DiscountSumTurnover AS DiscountSumTurnover,
	|		CustomerSalesWithForecast.DiscountSumWithoutVATTurnover AS DiscountSumWithoutVATTurnover,
	|		CustomerSalesWithForecast.RoomsRentedTurnover AS RoomsRentedTurnover,
	|		CustomerSalesWithForecast.BedsRentedTurnover AS BedsRentedTurnover,
	|		CustomerSalesWithForecast.AdditionalBedsRentedTurnover AS AdditionalBedsRentedTurnover,
	|		CustomerSalesWithForecast.GuestDaysTurnover AS GuestDaysTurnover,
	|		CustomerSalesWithForecast.BookingWindowTurnover AS BookingWindowTurnover,
	|		CustomerSalesWithForecast.QuantityTurnover AS QuantityTurnover,
	|		CustomerSalesWithForecast.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
	|		CustomerSalesWithForecast.RoomsCheckedInTurnover AS RoomsCheckedInTurnover,
	|		CustomerSalesWithForecast.BedsCheckedInTurnover AS BedsCheckedInTurnover,
	|		CustomerSalesWithForecast.AdditionalBedsCheckedInTurnover AS AdditionalBedsCheckedInTurnover,
	|		0 AS GuestsCheckedOutTurnover,
	|		0 AS RoomsCheckedOutTurnover,
	|		0 AS BedsCheckedOutTurnover,
	|		0 AS AdditionalBedsCheckedOutTurnover
	|	FROM
	|		CustomerSalesWithForecast AS CustomerSalesWithForecast
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CustomerSalesCheckOut.Hotel,
	|		CustomerSalesCheckOut.Company,
	|		CustomerSalesCheckOut.ReportingCurrency,
	|		CustomerSalesCheckOut.Agent,
	|		CustomerSalesCheckOut.Customer,
	|		CustomerSalesCheckOut.Contract,
	|		CustomerSalesCheckOut.GuestGroup,
	|		CustomerSalesCheckOut.NextAccountingDate,
	|		CustomerSalesCheckOut.NextAccountingMonthDate,
	|		CustomerSalesCheckOut.Client,
	|		CustomerSalesCheckOut.ParentDoc,
	|		CustomerSalesCheckOut.Service,
	|		CustomerSalesCheckOut.PaymentMethod,
	|		CustomerSalesCheckOut.ClientType,
	|		CustomerSalesCheckOut.Folio,
	|		CustomerSalesCheckOut.RoomRate,
	|		CustomerSalesCheckOut.Room,
	|		CustomerSalesCheckOut.RoomType,
	|		CustomerSalesCheckOut.AccommodationType,
	|		CustomerSalesCheckOut.TripPurpose,
	|		CustomerSalesCheckOut.MarketingCode,
	|		CustomerSalesCheckOut.SourceOfBusiness,
	|		CustomerSalesCheckOut.Resource,
	|		CustomerSalesCheckOut.ResourceType,
	|		CustomerSalesCheckOut.Author,
	|		CustomerSalesCheckOut.Discount,
	|		CustomerSalesCheckOut.DiscountType,
	|		CustomerSalesCheckOut.DiscountCard,
	|		CustomerSalesCheckOut.AgentCommissionType,
	|		CustomerSalesCheckOut.AgentCommission,
	|		CustomerSalesCheckOut.VATRate,
	|		CustomerSalesCheckOut.Price,
	|		CustomerSalesCheckOut.HotelProduct,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		CustomerSalesCheckOut.GuestsCheckedOutTurnover,
	|		CustomerSalesCheckOut.RoomsCheckedOutTurnover,
	|		CustomerSalesCheckOut.BedsCheckedOutTurnover,
	|		CustomerSalesCheckOut.AdditionalBedsCheckedOutTurnover
	|	FROM
	|		CustomerSalesWithForecast AS CustomerSalesCheckOut) AS CustomerSalesWithCheckout
	|
	|GROUP BY
	|	CustomerSalesWithCheckout.Hotel,
	|	CustomerSalesWithCheckout.Company,
	|	CustomerSalesWithCheckout.ReportingCurrency,
	|	CustomerSalesWithCheckout.Agent,
	|	CustomerSalesWithCheckout.Customer,
	|	CustomerSalesWithCheckout.Contract,
	|	CustomerSalesWithCheckout.GuestGroup,
	|	CustomerSalesWithCheckout.AccountingDate,
	|	CustomerSalesWithCheckout.AccountingMonthDate,
	|	CustomerSalesWithCheckout.Client,
	|	CustomerSalesWithCheckout.ParentDoc,
	|	CustomerSalesWithCheckout.Service,
	|	CustomerSalesWithCheckout.PaymentMethod,
	|	CustomerSalesWithCheckout.ClientType,
	|	CustomerSalesWithCheckout.Folio,
	|	CustomerSalesWithCheckout.RoomRate,
	|	CustomerSalesWithCheckout.Room,
	|	CustomerSalesWithCheckout.RoomType,
	|	CustomerSalesWithCheckout.AccommodationType,
	|	CustomerSalesWithCheckout.TripPurpose,
	|	CustomerSalesWithCheckout.MarketingCode,
	|	CustomerSalesWithCheckout.SourceOfBusiness,
	|	CustomerSalesWithCheckout.Resource,
	|	CustomerSalesWithCheckout.ResourceType,
	|	CustomerSalesWithCheckout.Author,
	|	CustomerSalesWithCheckout.Discount,
	|	CustomerSalesWithCheckout.DiscountType,
	|	CustomerSalesWithCheckout.DiscountCard,
	|	CustomerSalesWithCheckout.AgentCommissionType,
	|	CustomerSalesWithCheckout.AgentCommission,
	|	CustomerSalesWithCheckout.VATRate,
	|	CustomerSalesWithCheckout.Price,
	|	CustomerSalesWithCheckout.HotelProduct
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CustomerSales.Hotel AS Hotel,
	|	CustomerSales.Company AS Company,
	|	CustomerSales.ReportingCurrency AS ReportingCurrency,
	|	CustomerSales.Agent AS Agent,
	|	CustomerSales.Customer AS Customer,
	|	CustomerSales.Contract AS Contract,
	|	CustomerSales.GuestGroup AS GuestGroup,
	|	CustomerSales.RoomRate AS RoomRate,
	|	CustomerSales.AccountingDate AS AccountingDate,
	|	DAY(CustomerSales.AccountingDate) AS AccountingDay,
	|	DATEADD(BEGINOFPERIOD(CustomerSales.AccountingDate, WEEK), YEAR, -YEAR(CustomerSales.AccountingDate) + 1) AS AccountingWeek,
	|	DATEADD(BEGINOFPERIOD(CustomerSales.AccountingDate, MONTH), YEAR, -YEAR(CustomerSales.AccountingDate) + 1) AS AccountingMonth,
	|	DATEADD(BEGINOFPERIOD(CustomerSales.AccountingDate, QUARTER), YEAR, -YEAR(CustomerSales.AccountingDate) + 1) AS AccountingQuarter,
	|	YEAR(CustomerSales.AccountingDate) AS AccountingYear,
	|	CustomerSales.ParentDoc AS ParentDoc,
	|	CustomerSales.Service AS Service,
	|	CustomerSales.ClientLastCheckInDate AS ClientLastCheckInDate,
	|	CustomerSales.ClientFirstCheckInDate AS ClientFirstCheckInDate,
	|	CustomerSales.CustomerLastCheckInDate AS CustomerLastCheckInDate,
	|	CustomerSales.CustomerFirstCheckInDate AS CustomerFirstCheckInDate,
	|	CustomerSales.Sales AS Sales,
	|	CustomerSales.RoomRevenue AS RoomRevenue,
	|	CustomerSales.ExtraBedRevenue AS ExtraBedRevenue,
	|	CustomerSales.RoomRevenue - CustomerSales.ExtraBedRevenue AS MainBedsRevenue,
	|	CustomerSales.SalesWithoutVAT AS SalesWithoutVAT,
	|	CustomerSales.RoomRevenueWithoutVAT AS RoomRevenueWithoutVAT,
	|	CustomerSales.ExtraBedRevenueWithoutVAT AS ExtraBedRevenueWithoutVAT,
	|	CustomerSales.RoomRevenueWithoutVAT - CustomerSales.ExtraBedRevenueWithoutVAT AS MainBedsRevenueWithoutVAT,
	|	CustomerSales.Sales - CustomerSales.RoomRevenue AS ExtraServicesRevenue,
	|	CustomerSales.SalesWithoutVAT - CustomerSales.RoomRevenueWithoutVAT AS ExtraServicesRevenueWithoutVAT,
	|	CustomerSales.CommissionSum AS CommissionSum,
	|	CustomerSales.CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|	CustomerSales.DiscountSum AS DiscountSum,
	|	CustomerSales.DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|	CustomerSales.RoomsRented AS RoomsRented,
	|	CustomerSales.BedsRented AS BedsRented,
	|	CustomerSales.AdditionalBedsRented AS AdditionalBedsRented,
	|	CustomerSales.GuestDays AS GuestDays,
	|	CustomerSales.GuestsCheckedIn AS GuestsCheckedIn,
	|	CustomerSales.RoomsCheckedIn AS RoomsCheckedIn,
	|	CustomerSales.BedsCheckedIn AS BedsCheckedIn,
	|	CustomerSales.AdditionalBedsCheckedIn AS AdditionalBedsCheckedIn,
	|	CustomerSales.GuestsCheckedOut AS GuestsCheckedOut,
	|	CustomerSales.RoomsCheckedOut AS RoomsCheckedOut,
	|	CustomerSales.BedsCheckedOut AS BedsCheckedOut,
	|	CustomerSales.AdditionalBedsCheckedOut AS AdditionalBedsCheckedOut,
	|	CASE
	|		WHEN CustomerSales.RoomsCheckedIn <> 0
	|			THEN CAST(CustomerSales.BookingWindow / CustomerSales.RoomsCheckedIn AS NUMBER(10, 0))
	|		ELSE 0
	|	END AS BookingWindowDimension,
	|	CASE
	|		WHEN CustomerSales.RoomsCheckedIn <> 0
	|			THEN CAST(CustomerSales.BookingWindow / CustomerSales.RoomsCheckedIn AS NUMBER(10, 0))
	|		ELSE 0
	|	END AS BookingWindow,
	|	CustomerSales.Quantity AS Quantity,
	|	CustomerSales.TotalSales AS TotalSales,
	|	CustomerSales.TotalRoomRevenue AS TotalRoomRevenue,
	|	CustomerSales.TotalRoomsRented AS TotalRoomsRented,
	|	CustomerSales.TotalBedsRented AS TotalBedsRented,
	|	CustomerSales.TotalSalesPercent AS TotalSalesPercent,
	|	CustomerSales.TotalRoomRevenuePercent AS TotalRoomRevenuePercent,
	|	CustomerSales.TotalRoomsRentedPercent AS TotalRoomsRentedPercent,
	|	CustomerSales.TotalBedsRentedPercent AS TotalBedsRentedPercent,
	|	CustomerSales.MonthlySales AS MonthlySales,
	|	CustomerSales.MonthlyRoomRevenue AS MonthlyRoomRevenue,
	|	CustomerSales.MonthlyRoomsRented AS MonthlyRoomsRented,
	|	CustomerSales.MonthlyBedsRented AS MonthlyBedsRented,
	|	CustomerSales.MonthlySalesPercent AS MonthlySalesPercent,
	|	CustomerSales.MonthlyRoomRevenuePercent AS MonthlyRoomRevenuePercent,
	|	CustomerSales.MonthlyRoomsRentedPercent AS MonthlyRoomsRentedPercent,
	|	CustomerSales.MonthlyBedsRentedPercent AS MonthlyBedsRentedPercent,
	|	CustomerSales.MonthlyRoomsAvailable + CustomerSales.CounterClosingBalance - CustomerSales.CounterClosingBalance AS MonthlyRoomsAvailable,
	|	CustomerSales.MonthlyBedsAvailable + CustomerSales.CounterClosingBalance - CustomerSales.CounterClosingBalance AS MonthlyBedsAvailable,
	|	CustomerSales.MonthlyRoomsOccupancyPercent + CustomerSales.CounterClosingBalance - CustomerSales.CounterClosingBalance AS MonthlyRoomsOccupancyPercent,
	|	CustomerSales.MonthlyBedsOccupancyPercent + CustomerSales.CounterClosingBalance - CustomerSales.CounterClosingBalance AS MonthlyBedsOccupancyPercent,
	|	CustomerSales.ADR AS ADR,
	|	CustomerSales.ADBR AS ADBR,
	|	CustomerSales.ADRWithoutVAT AS ADRWithoutVAT,
	|	CustomerSales.ADBRWithoutVAT AS ADBRWithoutVAT,
	|	CustomerSales.RevPAC AS RevPAC,
	|	CustomerSales.RevPACWithoutVAT AS RevPACWithoutVAT,
	|	CustomerSales.ALS AS ALS
	|{SELECT
	|	Hotel.*,
	|	Company.*,
	|	ReportingCurrency.*,
	|	Agent.*,
	|	Customer.*,
	|	CustomerSales.Customer.TagsPresentation AS CustomerTagsPresentation,
	|	Contract.*,
	|	GuestGroup.*,
	|	CustomerSales.Client.*,
	|	CustomerSales.Client.TagsPresentation AS ClientTagsPresentation,
	|	RoomRate.*,
	|	Service.*,
	|	ParentDoc.*,
	|	CustomerSales.PaymentMethod.*,
	|	CustomerSales.ClientType.*,
	|	CustomerSales.Folio.*,
	|	CustomerSales.Room.*,
	|	CustomerSales.RoomType.*,
	|	CustomerSales.AccommodationType.*,
	|	CustomerSales.TripPurpose.*,
	|	CustomerSales.MarketingCode.*,
	|	CustomerSales.SourceOfBusiness.*,
	|	CustomerSales.Resource.*,
	|	CustomerSales.ResourceType.*,
	|	CustomerSales.Author.*,
	|	CustomerSales.Discount,
	|	CustomerSales.DiscountType.*,
	|	CustomerSales.DiscountCard.*,
	|	CustomerSales.AgentCommissionType,
	|	CustomerSales.AgentCommission,
	|	CustomerSales.VATRate.*,
	|	CustomerSales.Price AS Price,
	|	CustomerSales.HotelProduct.* AS HotelProduct,
	|	ReservationCustomAttributeValues1.CharacteristicValue.* AS CustomAttribute1,
	|	ReservationCustomAttributeValues2.CharacteristicValue.* AS CustomAttribute2,
	|	ReservationCustomAttributeValues3.CharacteristicValue.* AS CustomAttribute3,
	|	Sales,
	|	RoomRevenue,
	|	ExtraBedRevenue,
	|	MainBedsRevenue,
	|	SalesWithoutVAT,
	|	RoomRevenueWithoutVAT,
	|	ExtraBedRevenueWithoutVAT,
	|	MainBedsRevenueWithoutVAT,
	|	ExtraServicesRevenue,
	|	ExtraServicesRevenueWithoutVAT,
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
	|	GuestsCheckedOut,
	|	RoomsCheckedOut,
	|	BedsCheckedOut,
	|	AdditionalBedsCheckedOut,
	|	BookingWindowDimension,
	|	BookingWindow,
	|	Quantity,
	|	ClientLastCheckInDate,
	|	ClientFirstCheckInDate,
	|	CustomerLastCheckInDate,
	|	CustomerFirstCheckInDate,
	|	AccountingDate,
	|	AccountingDay,
	|	AccountingWeek,
	|	AccountingMonth,
	|	AccountingQuarter,
	|	AccountingYear,
	|	(CASE
	|			WHEN NOT CustomerSales.GuestGroup.GroupType.Code IS NULL
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS IsGroupReservation,
	|	TotalSales,
	|	TotalRoomRevenue,
	|	TotalRoomsRented,
	|	TotalBedsRented,
	|	TotalSalesPercent,
	|	TotalRoomRevenuePercent,
	|	TotalRoomsRentedPercent,
	|	TotalBedsRentedPercent,
	|	MonthlySales,
	|	MonthlyRoomRevenue,
	|	MonthlyRoomsRented,
	|	MonthlyBedsRented,
	|	MonthlySalesPercent,
	|	MonthlyRoomRevenuePercent,
	|	MonthlyRoomsRentedPercent,
	|	MonthlyBedsRentedPercent,
	|	MonthlyRoomsAvailable,
	|	MonthlyBedsAvailable,
	|	MonthlyRoomsOccupancyPercent,
	|	MonthlyBedsOccupancyPercent,
	|	ADR,
	|	ADBR,
	|	ADRWithoutVAT,
	|	ADBRWithoutVAT,
	|	RevPAC,
	|	RevPACWithoutVAT,
	|	ALS}
	|FROM
	|	(SELECT
	|		CustomerSalesFull.Hotel AS Hotel,
	|		CustomerSalesFull.Company AS Company,
	|		CustomerSalesFull.ReportingCurrency AS ReportingCurrency,
	|		CustomerSalesFull.Agent AS Agent,
	|		CustomerSalesFull.Customer AS Customer,
	|		CustomerSalesFull.Contract AS Contract,
	|		CustomerSalesFull.GuestGroup AS GuestGroup,
	|		ISNULL(CustomerSalesFull.AccountingDate, &qEmptyDate) AS AccountingDate,
	|		ISNULL(CustomerSalesFull.AccountingMonthDate, &qEmptyDate) AS AccountingMonthDate,
	|		CustomerSalesFull.Client AS Client,
	|		CustomerSalesFull.ParentDoc AS ParentDoc,
	|		CustomerSalesFull.Service AS Service,
	|		CustomerSalesFull.PaymentMethod AS PaymentMethod,
	|		CustomerSalesFull.ClientType AS ClientType,
	|		CustomerSalesFull.Folio AS Folio,
	|		CustomerSalesFull.RoomRate AS RoomRate,
	|		CustomerSalesFull.Room AS Room,
	|		CustomerSalesFull.RoomType AS RoomType,
	|		CustomerSalesFull.AccommodationType AS AccommodationType,
	|		CustomerSalesFull.TripPurpose AS TripPurpose,
	|		CustomerSalesFull.MarketingCode AS MarketingCode,
	|		CustomerSalesFull.SourceOfBusiness AS SourceOfBusiness,
	|		CustomerSalesFull.Resource AS Resource,
	|		CustomerSalesFull.ResourceType AS ResourceType,
	|		CustomerSalesFull.Author AS Author,
	|		CustomerSalesFull.Discount AS Discount,
	|		CustomerSalesFull.DiscountType AS DiscountType,
	|		CustomerSalesFull.DiscountCard AS DiscountCard,
	|		CustomerSalesFull.AgentCommissionType AS AgentCommissionType,
	|		CustomerSalesFull.AgentCommission AS AgentCommission,
	|		CustomerSalesFull.VATRate AS VATRate,
	|		CustomerSalesFull.Price AS Price,
	|		CustomerSalesFull.HotelProduct AS HotelProduct,
	|		CustomerSalesFull.SalesTurnover AS Sales,
	|		CustomerSalesFull.RoomRevenueTurnover AS RoomRevenue,
	|		CustomerSalesFull.ExtraBedRevenueTurnover AS ExtraBedRevenue,
	|		CustomerSalesFull.SalesWithoutVATTurnover AS SalesWithoutVAT,
	|		CustomerSalesFull.RoomRevenueWithoutVATTurnover AS RoomRevenueWithoutVAT,
	|		CustomerSalesFull.ExtraBedRevenueWithoutVATTurnover AS ExtraBedRevenueWithoutVAT,
	|		CustomerSalesFull.CommissionSumTurnover AS CommissionSum,
	|		CustomerSalesFull.CommissionSumWithoutVATTurnover AS CommissionSumWithoutVAT,
	|		CustomerSalesFull.DiscountSumTurnover AS DiscountSum,
	|		CustomerSalesFull.DiscountSumWithoutVATTurnover AS DiscountSumWithoutVAT,
	|		CustomerSalesFull.RoomsRentedTurnover AS RoomsRented,
	|		CustomerSalesFull.BedsRentedTurnover AS BedsRented,
	|		CustomerSalesFull.AdditionalBedsRentedTurnover AS AdditionalBedsRented,
	|		CustomerSalesFull.GuestDaysTurnover AS GuestDays,
	|		CustomerSalesFull.GuestsCheckedInTurnover AS GuestsCheckedIn,
	|		CustomerSalesFull.RoomsCheckedInTurnover AS RoomsCheckedIn,
	|		CustomerSalesFull.BedsCheckedInTurnover AS BedsCheckedIn,
	|		CustomerSalesFull.AdditionalBedsCheckedInTurnover AS AdditionalBedsCheckedIn,
	|		CustomerSalesFull.GuestsCheckedOutTurnover AS GuestsCheckedOut,
	|		CustomerSalesFull.RoomsCheckedOutTurnover AS RoomsCheckedOut,
	|		CustomerSalesFull.BedsCheckedOutTurnover AS BedsCheckedOut,
	|		CustomerSalesFull.AdditionalBedsCheckedOutTurnover AS AdditionalBedsCheckedOut,
	|		CustomerSalesFull.BookingWindowTurnover AS BookingWindow,
	|		CustomerSalesFull.QuantityTurnover AS Quantity,
	|		ClientCheckInStatistics.LastCheckInDate AS ClientLastCheckInDate,
	|		ClientCheckInStatistics.FirstCheckInDate AS ClientFirstCheckInDate,
	|		CustomerCheckInStatistics.LastCheckInDate AS CustomerLastCheckInDate,
	|		CustomerCheckInStatistics.FirstCheckInDate AS CustomerFirstCheckInDate,
	|		CustomerTotalSales.TotalSales AS TotalSales,
	|		CustomerTotalSales.TotalRoomRevenue AS TotalRoomRevenue,
	|		CustomerTotalSales.TotalRoomsRented AS TotalRoomsRented,
	|		CustomerTotalSales.TotalBedsRented AS TotalBedsRented,
	|		CASE
	|			WHEN CustomerTotalSales.TotalSales = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.SalesTurnover * 100 / CustomerTotalSales.TotalSales
	|		END AS TotalSalesPercent,
	|		CASE
	|			WHEN CustomerTotalSales.TotalRoomRevenue = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.RoomRevenueTurnover * 100 / CustomerTotalSales.TotalRoomRevenue
	|		END AS TotalRoomRevenuePercent,
	|		CASE
	|			WHEN CustomerTotalSales.TotalRoomsRented = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.RoomsRentedTurnover * 100 / CustomerTotalSales.TotalRoomsRented
	|		END AS TotalRoomsRentedPercent,
	|		CASE
	|			WHEN CustomerTotalSales.TotalBedsRented = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.BedsRentedTurnover * 100 / CustomerTotalSales.TotalBedsRented
	|		END AS TotalBedsRentedPercent,
	|		CustomerMonthlySales.MonthlySales AS MonthlySales,
	|		CustomerMonthlySales.MonthlyRoomRevenue AS MonthlyRoomRevenue,
	|		CustomerMonthlySales.MonthlyRoomsRented AS MonthlyRoomsRented,
	|		CustomerMonthlySales.MonthlyBedsRented AS MonthlyBedsRented,
	|		CASE
	|			WHEN CustomerMonthlySales.MonthlySales = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.SalesTurnover * 100 / CustomerMonthlySales.MonthlySales
	|		END AS MonthlySalesPercent,
	|		CASE
	|			WHEN CustomerMonthlySales.MonthlyRoomRevenue = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.RoomRevenueTurnover * 100 / CustomerMonthlySales.MonthlyRoomRevenue
	|		END AS MonthlyRoomRevenuePercent,
	|		CASE
	|			WHEN CustomerMonthlySales.MonthlyRoomsRented = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.RoomsRentedTurnover * 100 / CustomerMonthlySales.MonthlyRoomsRented
	|		END AS MonthlyRoomsRentedPercent,
	|		CASE
	|			WHEN CustomerMonthlySales.MonthlyBedsRented = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.BedsRentedTurnover * 100 / CustomerMonthlySales.MonthlyBedsRented
	|		END AS MonthlyBedsRentedPercent,
	|		HotelInventoryPerMonth.CounterClosingBalance AS CounterClosingBalance,
	|		HotelInventoryPerMonth.MonthlyRoomsAvailable AS MonthlyRoomsAvailable,
	|		HotelInventoryPerMonth.MonthlyBedsAvailable AS MonthlyBedsAvailable,
	|		CASE
	|			WHEN HotelInventoryPerMonth.MonthlyRoomsAvailable = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.RoomsRentedTurnover * 100 / HotelInventoryPerMonth.MonthlyRoomsAvailable
	|		END AS MonthlyRoomsOccupancyPercent,
	|		CASE
	|			WHEN HotelInventoryPerMonth.MonthlyBedsAvailable = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.BedsRentedTurnover * 100 / HotelInventoryPerMonth.MonthlyBedsAvailable
	|		END AS MonthlyBedsOccupancyPercent,
	|		CASE
	|			WHEN CustomerSalesFull.RoomsRentedTurnover = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.RoomRevenueTurnover / CustomerSalesFull.RoomsRentedTurnover
	|		END AS ADR,
	|		CASE
	|			WHEN CustomerSalesFull.BedsRentedTurnover = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.RoomRevenueTurnover / CustomerSalesFull.BedsRentedTurnover
	|		END AS ADBR,
	|		CASE
	|			WHEN CustomerSalesFull.RoomsRentedTurnover = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.RoomRevenueWithoutVATTurnover / CustomerSalesFull.RoomsRentedTurnover
	|		END AS ADRWithoutVAT,
	|		CASE
	|			WHEN CustomerSalesFull.BedsRentedTurnover = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.RoomRevenueWithoutVATTurnover / CustomerSalesFull.BedsRentedTurnover
	|		END AS ADBRWithoutVAT,
	|		CASE
	|			WHEN CustomerSalesFull.GuestDaysTurnover = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.RoomRevenueTurnover / CustomerSalesFull.GuestDaysTurnover
	|		END AS RevPAC,
	|		CASE
	|			WHEN CustomerSalesFull.GuestDaysTurnover = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.RoomRevenueWithoutVATTurnover / CustomerSalesFull.GuestDaysTurnover
	|		END AS RevPACWithoutVAT,
	|		CASE
	|			WHEN CustomerSalesFull.GuestsCheckedInTurnover = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.GuestDaysTurnover / CustomerSalesFull.GuestsCheckedInTurnover
	|		END AS ALS
	|	FROM
	|		CustomerSalesWithCheckout AS CustomerSalesFull
	|			LEFT JOIN (SELECT
	|				RoomInventory.Guest AS Client,
	|				MAX(RoomInventory.CheckInDate) AS LastCheckInDate,
	|				MIN(RoomInventory.CheckInDate) AS FirstCheckInDate
	|			FROM
	|				AccumulationRegister.RoomInventory AS RoomInventory
	|			WHERE
	|				RoomInventory.IsAccommodation
	|				AND RoomInventory.IsCheckIn
	|			
	|			GROUP BY
	|				RoomInventory.Guest) AS ClientCheckInStatistics
	|			ON CustomerSalesFull.Client = ClientCheckInStatistics.Client
	|			LEFT JOIN (SELECT
	|				CASE
	|					WHEN RoomInventory.Customer = &qEmptyCustomer
	|						THEN RoomInventory.Hotel.IndividualsCustomer
	|					ELSE RoomInventory.Customer
	|				END AS Customer,
	|				MAX(RoomInventory.CheckInDate) AS LastCheckInDate,
	|				MIN(RoomInventory.CheckInDate) AS FirstCheckInDate
	|			FROM
	|				AccumulationRegister.RoomInventory AS RoomInventory
	|			WHERE
	|				RoomInventory.IsAccommodation
	|				AND RoomInventory.IsCheckIn
	|			
	|			GROUP BY
	|				CASE
	|					WHEN RoomInventory.Customer = &qEmptyCustomer
	|						THEN RoomInventory.Hotel.IndividualsCustomer
	|					ELSE RoomInventory.Customer
	|				END) AS CustomerCheckInStatistics
	|			ON CustomerSalesFull.Customer = CustomerCheckInStatistics.Customer
	|			LEFT JOIN (SELECT
	|				CustomerTotals.Hotel AS Hotel,
	|				CustomerTotals.TotalRoomRevenue AS TotalRoomRevenue,
	|				CustomerTotals.TotalRoomsRented AS TotalRoomsRented,
	|				CustomerTotals.TotalBedsRented AS TotalBedsRented,
	|				CustomerTotals.TotalSales AS TotalSales
	|			FROM
	|				CustomerTotals AS CustomerTotals) AS CustomerTotalSales
	|			ON CustomerSalesFull.Hotel = CustomerTotalSales.Hotel
	|			LEFT JOIN (SELECT
	|				CustomerMonthlyTotals.Hotel AS Hotel,
	|				CustomerMonthlyTotals.Period AS Period,
	|				CustomerMonthlyTotals.MonthlyRoomRevenue AS MonthlyRoomRevenue,
	|				CustomerMonthlyTotals.MonthlyRoomsRented AS MonthlyRoomsRented,
	|				CustomerMonthlyTotals.MonthlyBedsRented AS MonthlyBedsRented,
	|				CustomerMonthlyTotals.MonthlySales AS MonthlySales
	|			FROM
	|				CustomerMonthlyTotals AS CustomerMonthlyTotals) AS CustomerMonthlySales
	|			ON CustomerSalesFull.Hotel = CustomerMonthlySales.Hotel
	|				AND CustomerSalesFull.AccountingMonthDate = CustomerMonthlySales.Period
	|			LEFT JOIN (SELECT
	|				HotelInventoryTotalsPerMonth.Hotel AS Hotel,
	|				HotelInventoryTotalsPerMonth.Period AS Period,
	|				HotelInventoryTotalsPerMonth.CounterClosingBalance AS CounterClosingBalance,
	|				HotelInventoryTotalsPerMonth.TotalRooms - HotelInventoryTotalsPerMonth.TotalRoomsBlocked AS MonthlyRoomsAvailable,
	|				HotelInventoryTotalsPerMonth.TotalBeds - HotelInventoryTotalsPerMonth.TotalBedsBlocked AS MonthlyBedsAvailable
	|			FROM
	|				HotelInventoryTotalsPerMonth AS HotelInventoryTotalsPerMonth) AS HotelInventoryPerMonth
	|			ON CustomerSalesFull.Hotel = HotelInventoryPerMonth.Hotel
	|				AND CustomerSalesFull.AccountingMonthDate = HotelInventoryPerMonth.Period) AS CustomerSales
	|		LEFT JOIN InformationRegister.ReservationCustomAttributeValues AS ReservationCustomAttributeValues1
	|		ON (CustomerSales.ParentDoc.Reservation = ReservationCustomAttributeValues1.Owner
	|				OR CustomerSales.ParentDoc = ReservationCustomAttributeValues1.Owner
	|					AND CustomerSales.ParentDoc.Reservation.Number IS NULL)
	|			AND (ReservationCustomAttributeValues1.Characteristic = &qCustomAttribute1)
	|		LEFT JOIN InformationRegister.ReservationCustomAttributeValues AS ReservationCustomAttributeValues2
	|		ON (CustomerSales.ParentDoc.Reservation = ReservationCustomAttributeValues2.Owner
	|				OR CustomerSales.ParentDoc = ReservationCustomAttributeValues2.Owner
	|					AND CustomerSales.ParentDoc.Reservation.Number IS NULL)
	|			AND (ReservationCustomAttributeValues2.Characteristic = &qCustomAttribute2)
	|		LEFT JOIN InformationRegister.ReservationCustomAttributeValues AS ReservationCustomAttributeValues3
	|		ON (CustomerSales.ParentDoc.Reservation = ReservationCustomAttributeValues3.Owner
	|				OR CustomerSales.ParentDoc = ReservationCustomAttributeValues3.Owner
	|					AND CustomerSales.ParentDoc.Reservation.Number IS NULL)
	|			AND (ReservationCustomAttributeValues3.Characteristic = &qCustomAttribute3)
	|{WHERE
	|	CustomerSales.Hotel.*,
	|	CustomerSales.Company.*,
	|	CustomerSales.ReportingCurrency.*,
	|	CustomerSales.Agent.*,
	|	CustomerSales.Customer.*,
	|	CustomerSales.Customer.TagsPresentation AS CustomerTagsPresentation,
	|	CustomerSales.Contract.*,
	|	CustomerSales.GuestGroup.*,
	|	CustomerSales.Client.*,
	|	CustomerSales.Client.TagsPresentation AS ClientTagsPresentation,
	|	CustomerSales.RoomRate.*,
	|	CustomerSales.ParentDoc.*,
	|	CustomerSales.PaymentMethod.*,
	|	CustomerSales.Service.*,
	|	CustomerSales.PaymentMethod.*,
	|	CustomerSales.ClientType.*,
	|	CustomerSales.Folio.*,
	|	CustomerSales.Room.*,
	|	CustomerSales.RoomType.*,
	|	CustomerSales.AccommodationType.*,
	|	CustomerSales.TripPurpose.*,
	|	CustomerSales.MarketingCode.*,
	|	CustomerSales.SourceOfBusiness.*,
	|	CustomerSales.Resource.*,
	|	CustomerSales.ResourceType.*,
	|	CustomerSales.Author.*,
	|	CustomerSales.Discount,
	|	CustomerSales.DiscountType.*,
	|	CustomerSales.DiscountCard.*,
	|	CustomerSales.AgentCommissionType,
	|	CustomerSales.AgentCommission,
	|	CustomerSales.VATRate.*,
	|	CustomerSales.Price AS Price,
	|	CustomerSales.HotelProduct.* AS HotelProduct,
	|	ReservationCustomAttributeValues1.CharacteristicValue.* AS CustomAttribute1,
	|	ReservationCustomAttributeValues2.CharacteristicValue.* AS CustomAttribute2,
	|	ReservationCustomAttributeValues3.CharacteristicValue.* AS CustomAttribute3,
	|	(CASE
	|			WHEN NOT CustomerSales.GuestGroup.GroupType.Code IS NULL
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS IsGroupReservation,
	|	CustomerSales.Sales AS Sales,
	|	CustomerSales.RoomRevenue AS RoomRevenue,
	|	CustomerSales.ExtraBedRevenue AS ExtraBedRevenue,
	|	CustomerSales.SalesWithoutVAT AS SalesWithoutVAT,
	|	CustomerSales.RoomRevenueWithoutVAT AS RoomRevenueWithoutVAT,
	|	CustomerSales.ExtraBedRevenueWithoutVAT AS ExtraBedRevenueWithoutVAT,
	|	(CustomerSales.Sales - CustomerSales.RoomRevenue) AS ExtraServicesRevenue,
	|	(CustomerSales.SalesWithoutVAT - CustomerSales.RoomRevenueWithoutVAT) AS ExtraServicesRevenueWithoutVAT,
	|	CustomerSales.CommissionSum AS CommissionSum,
	|	CustomerSales.CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|	CustomerSales.DiscountSum AS DiscountSum,
	|	CustomerSales.DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|	CustomerSales.RoomsRented AS RoomsRented,
	|	CustomerSales.BedsRented AS BedsRented,
	|	CustomerSales.AdditionalBedsRented AS AdditionalBedsRented,
	|	CustomerSales.GuestDays AS GuestDays,
	|	CustomerSales.GuestsCheckedIn AS GuestsCheckedIn,
	|	CustomerSales.RoomsCheckedIn AS RoomsCheckedIn,
	|	CustomerSales.BedsCheckedIn AS BedsCheckedIn,
	|	CustomerSales.AdditionalBedsCheckedIn AS AdditionalBedsCheckedIn,
	|	CustomerSales.GuestsCheckedOut AS GuestsCheckedOut,
	|	CustomerSales.RoomsCheckedOut AS RoomsCheckedOut,
	|	CustomerSales.BedsCheckedOut AS BedsCheckedOut,
	|	CustomerSales.AdditionalBedsCheckedOut AS AdditionalBedsCheckedOut,
	|	(CASE
	|			WHEN CustomerSales.RoomsCheckedIn <> 0
	|				THEN CAST(CustomerSales.BookingWindow / CustomerSales.RoomsCheckedIn AS NUMBER(10, 0))
	|			ELSE 0
	|		END) AS BookingWindowDimension,
	|	(CASE
	|			WHEN CustomerSales.RoomsCheckedIn <> 0
	|				THEN CAST(CustomerSales.BookingWindow / CustomerSales.RoomsCheckedIn AS NUMBER(10, 0))
	|			ELSE 0
	|		END) AS BookingWindow,
	|	CustomerSales.Quantity AS Quantity,
	|	CustomerSales.ClientLastCheckInDate AS ClientLastCheckInDate,
	|	CustomerSales.ClientFirstCheckInDate AS ClientFirstCheckInDate,
	|	CustomerSales.CustomerLastCheckInDate AS CustomerLastCheckInDate,
	|	CustomerSales.CustomerFirstCheckInDate AS CustomerFirstCheckInDate,
	|	CustomerSales.AccountingDate,
	|	(DAY(CustomerSales.AccountingDate)) AS AccountingDay,
	|	(DATEADD(BEGINOFPERIOD(CustomerSales.AccountingDate, WEEK), YEAR, -YEAR(CustomerSales.AccountingDate) + 1)) AS AccountingWeek,
	|	(DATEADD(BEGINOFPERIOD(CustomerSales.AccountingDate, MONTH), YEAR, -YEAR(CustomerSales.AccountingDate) + 1)) AS AccountingMonth,
	|	(DATEADD(BEGINOFPERIOD(CustomerSales.AccountingDate, QUARTER), YEAR, -YEAR(CustomerSales.AccountingDate) + 1)) AS AccountingQuarter,
	|	(YEAR(CustomerSales.AccountingDate)) AS AccountingYear,
	|	CustomerSales.TotalSales AS TotalSales,
	|	CustomerSales.TotalRoomRevenue AS TotalRoomRevenue,
	|	CustomerSales.TotalRoomsRented AS TotalRoomsRented,
	|	CustomerSales.TotalBedsRented AS TotalBedsRented,
	|	CustomerSales.TotalSalesPercent AS TotalSalesPercent,
	|	CustomerSales.TotalRoomRevenuePercent AS TotalRoomRevenuePercent,
	|	CustomerSales.TotalRoomsRentedPercent AS TotalRoomsRentedPercent,
	|	CustomerSales.TotalBedsRentedPercent AS TotalBedsRentedPercent,
	|	CustomerSales.ADR AS ADR,
	|	CustomerSales.ADBR AS ADBR,
	|	CustomerSales.ADRWithoutVAT AS ADRWithoutVAT,
	|	CustomerSales.ADBRWithoutVAT AS ADBRWithoutVAT,
	|	CustomerSales.RevPAC AS RevPAC,
	|	CustomerSales.RevPACWithoutVAT AS RevPACWithoutVAT,
	|	CustomerSales.ALS AS ALS}
	|
	|ORDER BY
	|	ReportingCurrency,
	|	Customer
	|{ORDER BY
	|	Hotel.*,
	|	Company.*,
	|	ReportingCurrency.*,
	|	Agent.*,
	|	Customer.*,
	|	CustomerSales.Customer.TagsPresentation AS CustomerTagsPresentation,
	|	Contract.*,
	|	GuestGroup.*,
	|	CustomerSales.Client.*,
	|	CustomerSales.Client.TagsPresentation AS ClientTagsPresentation,
	|	RoomRate.*,
	|	Service.*,
	|	ParentDoc.*,
	|	CustomerSales.PaymentMethod.*,
	|	CustomerSales.PaymentMethod.*,
	|	CustomerSales.ClientType.*,
	|	CustomerSales.Folio.*,
	|	CustomerSales.Room.*,
	|	CustomerSales.RoomType.*,
	|	CustomerSales.AccommodationType.*,
	|	CustomerSales.TripPurpose.*,
	|	CustomerSales.MarketingCode.*,
	|	CustomerSales.SourceOfBusiness.*,
	|	CustomerSales.Resource.*,
	|	CustomerSales.ResourceType.*,
	|	CustomerSales.Author.*,
	|	CustomerSales.Discount,
	|	CustomerSales.DiscountType.*,
	|	CustomerSales.DiscountCard.*,
	|	CustomerSales.AgentCommissionType,
	|	CustomerSales.AgentCommission,
	|	CustomerSales.VATRate.*,
	|	CustomerSales.Price AS Price,
	|	CustomerSales.HotelProduct.* AS HotelProduct,
	|	ReservationCustomAttributeValues1.CharacteristicValue.* AS CustomAttribute1,
	|	ReservationCustomAttributeValues2.CharacteristicValue.* AS CustomAttribute2,
	|	ReservationCustomAttributeValues3.CharacteristicValue.* AS CustomAttribute3,
	|	(CASE
	|			WHEN NOT CustomerSales.GuestGroup.GroupType.Code IS NULL
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS IsGroupReservation,
	|	Sales,
	|	RoomRevenue,
	|	ExtraBedRevenue,
	|	SalesWithoutVAT,
	|	RoomRevenueWithoutVAT,
	|	ExtraBedRevenueWithoutVAT,
	|	ExtraServicesRevenue,
	|	ExtraServicesRevenueWithoutVAT,
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
	|	BookingWindowDimension,
	|	BookingWindow,
	|	Quantity,
	|	ClientLastCheckInDate,
	|	ClientFirstCheckInDate,
	|	CustomerLastCheckInDate,
	|	CustomerFirstCheckInDate,
	|	AccountingDate,
	|	AccountingDay,
	|	AccountingWeek,
	|	AccountingMonth,
	|	AccountingQuarter,
	|	AccountingYear,
	|	TotalSales,
	|	TotalRoomRevenue,
	|	TotalRoomsRented,
	|	TotalBedsRented,
	|	TotalSalesPercent,
	|	TotalRoomRevenuePercent,
	|	TotalRoomsRentedPercent,
	|	TotalBedsRentedPercent,
	|	ADR,
	|	ADBR,
	|	ADRWithoutVAT,
	|	ADBRWithoutVAT,
	|	RevPAC,
	|	RevPACWithoutVAT,
	|	ALS}
	|TOTALS
	|	MAX(ClientLastCheckInDate),
	|	MIN(ClientFirstCheckInDate),
	|	MAX(CustomerLastCheckInDate),
	|	MIN(CustomerFirstCheckInDate),
	|	SUM(Sales),
	|	SUM(RoomRevenue),
	|	SUM(ExtraBedRevenue),
	|	SUM(MainBedsRevenue),
	|	SUM(SalesWithoutVAT),
	|	SUM(RoomRevenueWithoutVAT),
	|	SUM(ExtraBedRevenueWithoutVAT),
	|	SUM(MainBedsRevenueWithoutVAT),
	|	SUM(CustomerSales.Sales) - SUM(CustomerSales.RoomRevenue) AS ExtraServicesRevenue,
	|	SUM(CustomerSales.SalesWithoutVAT) - SUM(CustomerSales.RoomRevenueWithoutVAT) AS ExtraServicesRevenueWithoutVAT,
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
	|	SUM(GuestsCheckedOut),
	|	SUM(RoomsCheckedOut),
	|	SUM(BedsCheckedOut),
	|	SUM(AdditionalBedsCheckedOut),
	|	CASE
	|		WHEN SUM(RoomsCheckedIn) <> 0
	|			THEN CAST(SUM(BookingWindow) / SUM(RoomsCheckedIn) AS NUMBER(10, 0))
	|		ELSE 0
	|	END AS BookingWindow,
	|	SUM(Quantity),
	|	MAX(TotalSales),
	|	MAX(TotalRoomRevenue),
	|	MAX(TotalRoomsRented),
	|	MAX(TotalBedsRented),
	|	CASE
	|		WHEN MAX(TotalSales) = 0
	|			THEN 0
	|		ELSE SUM(Sales) * 100 / MAX(TotalSales)
	|	END AS TotalSalesPercent,
	|	CASE
	|		WHEN MAX(TotalRoomRevenue) = 0
	|			THEN 0
	|		ELSE SUM(RoomRevenue) * 100 / MAX(TotalRoomRevenue)
	|	END AS TotalRoomRevenuePercent,
	|	CASE
	|		WHEN MAX(TotalRoomsRented) = 0
	|			THEN 0
	|		ELSE SUM(RoomsRented) * 100 / MAX(TotalRoomsRented)
	|	END AS TotalRoomsRentedPercent,
	|	CASE
	|		WHEN MAX(TotalBedsRented) = 0
	|			THEN 0
	|		ELSE SUM(BedsRented) * 100 / MAX(TotalBedsRented)
	|	END AS TotalBedsRentedPercent,
	|	MAX(MonthlySales),
	|	MAX(MonthlyRoomRevenue),
	|	MAX(MonthlyRoomsRented),
	|	MAX(MonthlyBedsRented),
	|	CASE
	|		WHEN MAX(MonthlySales) = 0
	|			THEN 0
	|		ELSE SUM(Sales) * 100 / MAX(MonthlySales)
	|	END AS MonthlySalesPercent,
	|	CASE
	|		WHEN MAX(MonthlyRoomRevenue) = 0
	|			THEN 0
	|		ELSE SUM(RoomRevenue) * 100 / MAX(MonthlyRoomRevenue)
	|	END AS MonthlyRoomRevenuePercent,
	|	CASE
	|		WHEN MAX(MonthlyRoomsRented) = 0
	|			THEN 0
	|		ELSE SUM(RoomsRented) * 100 / MAX(MonthlyRoomsRented)
	|	END AS MonthlyRoomsRentedPercent,
	|	CASE
	|		WHEN MAX(MonthlyBedsRented) = 0
	|			THEN 0
	|		ELSE SUM(BedsRented) * 100 / MAX(MonthlyBedsRented)
	|	END AS MonthlyBedsRentedPercent,
	|	MAX(MonthlyRoomsAvailable),
	|	MAX(MonthlyBedsAvailable),
	|	CASE
	|		WHEN MAX(MonthlyRoomsAvailable) = 0
	|			THEN 0
	|		ELSE SUM(RoomsRented) * 100 / MAX(MonthlyRoomsAvailable)
	|	END AS MonthlyRoomsOccupancyPercent,
	|	CASE
	|		WHEN MAX(MonthlyBedsAvailable) = 0
	|			THEN 0
	|		ELSE SUM(BedsRented) * 100 / MAX(MonthlyBedsAvailable)
	|	END AS MonthlyBedsOccupancyPercent,
	|	CASE
	|		WHEN SUM(RoomsRented) = 0
	|			THEN 0
	|		ELSE SUM(RoomRevenue) / SUM(RoomsRented)
	|	END AS ADR,
	|	CASE
	|		WHEN SUM(BedsRented) = 0
	|			THEN 0
	|		ELSE SUM(RoomRevenue) / SUM(BedsRented)
	|	END AS ADBR,
	|	CASE
	|		WHEN SUM(RoomsRented) = 0
	|			THEN 0
	|		ELSE SUM(RoomRevenueWithoutVAT) / SUM(RoomsRented)
	|	END AS ADRWithoutVAT,
	|	CASE
	|		WHEN SUM(BedsRented) = 0
	|			THEN 0
	|		ELSE SUM(RoomRevenueWithoutVAT) / SUM(BedsRented)
	|	END AS ADBRWithoutVAT,
	|	CASE
	|		WHEN SUM(GuestDays) = 0
	|			THEN 0
	|		ELSE SUM(RoomRevenue) / SUM(GuestDays)
	|	END AS RevPAC,
	|	CASE
	|		WHEN SUM(GuestDays) = 0
	|			THEN 0
	|		ELSE SUM(RoomRevenueWithoutVAT) / SUM(GuestDays)
	|	END AS RevPACWithoutVAT,
	|	CASE
	|		WHEN SUM(GuestsCheckedIn) = 0
	|			THEN 0
	|		ELSE SUM(GuestDays) / SUM(GuestsCheckedIn)
	|	END AS ALS
	|BY
	|	OVERALL,
	|	ReportingCurrency,
	|	Customer HIERARCHY
	|{TOTALS BY
	|	Hotel.*,
	|	Company.*,
	|	ReportingCurrency.*,
	|	Agent.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	CustomerSales.Client.*,
	|	RoomRate.*,
	|	ParentDoc.*,
	|	CustomerSales.PaymentMethod.*,
	|	Service.*,
	|	CustomerSales.PaymentMethod.*,
	|	CustomerSales.ClientType.*,
	|	CustomerSales.Folio.*,
	|	CustomerSales.Room.*,
	|	CustomerSales.RoomType.*,
	|	CustomerSales.AccommodationType.*,
	|	CustomerSales.TripPurpose.*,
	|	CustomerSales.MarketingCode.*,
	|	CustomerSales.SourceOfBusiness.*,
	|	CustomerSales.Resource.*,
	|	CustomerSales.ResourceType.*,
	|	CustomerSales.Author.*,
	|	CustomerSales.Discount,
	|	CustomerSales.DiscountType.*,
	|	CustomerSales.DiscountCard.*,
	|	CustomerSales.AgentCommissionType,
	|	CustomerSales.AgentCommission,
	|	CustomerSales.VATRate.*,
	|	CustomerSales.Price AS Price,
	|	CustomerSales.HotelProduct.* AS HotelProduct,
	|	ReservationCustomAttributeValues1.CharacteristicValue.* AS CustomAttribute1,
	|	ReservationCustomAttributeValues2.CharacteristicValue.* AS CustomAttribute2,
	|	ReservationCustomAttributeValues3.CharacteristicValue.* AS CustomAttribute3,
	|	BookingWindowDimension,
	|	(CASE
	|			WHEN NOT CustomerSales.GuestGroup.GroupType.Code IS NULL
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS IsGroupReservation,
	|	ADR,
	|	AccountingDate,
	|	AccountingDay,
	|	AccountingWeek,
	|	AccountingMonth,
	|	AccountingQuarter,
	|	AccountingYear}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Customer sales turnovers';RU='Обороты продаж по контрагентам';de='Verkaufsumsätze nach Vertragspartnern'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
Function pmIsResource(pName) Export
	If pName = "Sales" 
	   Or pName = "RoomRevenue" 
	   Or pName = "ExtraBedRevenue" 
	   Or pName = "MainBedsRevenue" 
	   Or pName = "SalesWithoutVAT" 
	   Or pName = "RoomRevenueWithoutVAT" 
	   Or pName = "ExtraBedRevenueWithoutVAT" 
	   Or pName = "MainBedsRevenueWithoutVAT" 
	   Or pName = "ExtraServicesRevenue" 
	   Or pName = "ExtraServicesRevenueWithoutVAT" 
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
	   Or pName = "GuestsCheckedOut" 
	   Or pName = "RoomsCheckedOut" 
	   Or pName = "BedsCheckedOut" 
	   Or pName = "AdditionalBedsCheckedOut" 
	   Or pName = "Quantity" 
	   Or pName = "TotalRoomRevenue" 
	   Or pName = "TotalSales" 
	   Or pName = "TotalRoomsRented" 
	   Or pName = "TotalBedsRented" 
	   Or pName = "TotalRoomRevenuePercent" 
	   Or pName = "TotalSalesPercent"
	   Or pName = "TotalRoomsRentedPercent" 
	   Or pName = "TotalBedsRentedPercent" 
	   Or pName = "ADR"
	   Or pName = "ADBR"
	   Or pName = "ADRWithoutVAT"
	   Or pName = "ADBRWithoutVAT"
	   Or pName = "RevPAC"
	   Or pName = "RevPACWithoutVAT"
	   Or pName = "ALS" 
	   Or pName = "BookingWindow" Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // pmIsResource

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
