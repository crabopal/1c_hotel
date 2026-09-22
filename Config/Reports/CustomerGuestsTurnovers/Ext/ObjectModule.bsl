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
	ReportBuilder.Parameters.Insert("qContract", Contract);
	ReportBuilder.Parameters.Insert("qIsEmptyContract", Not ValueIsFilled(Contract));
	ReportBuilder.Parameters.Insert("qGuestGroup", GuestGroup);
	ReportBuilder.Parameters.Insert("qIsEmptyGuestGroup", Not ValueIsFilled(GuestGroup));
	ReportBuilder.Parameters.Insert("qEmptyClient", Catalogs.Clients.EmptyRef());
	ReportBuilder.Parameters.Insert("qEmptyDate", '00010101');
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
	ReportBuilder.Parameters.Insert("qRepeater", NStr("en='REPEATER'; ru='ПОВТОРНЫЙ'; de='REPEATER'"));
	ReportBuilder.Parameters.Insert("qNumberOfPrevCheckinsForRepeater", 1);
	// Check report dimensions being used in current report settings
	vReportDimensionsUsage = New ValueTable();
	vReportDimensionsUsage.Columns.Add("Name");
	vReportDimensionsUsage.Columns.Add("IsUsed", cmGetBooleanTypeDescription());
	For Each vDim In Metadata.AccumulationRegisters.Sales.Dimensions Do
		vReportDimensionsUsageRow = vReportDimensionsUsage.Add();
		vReportDimensionsUsageRow.Name = vDim.Name;
		vReportDimensionsUsageRow.IsUsed = False;
	EndDo;
	vReportDimensionsUsageRow = vReportDimensionsUsage.Add();
	vReportDimensionsUsageRow.Name = "GuestsCheckedInDimension";
	vReportDimensionsUsageRow.IsUsed = False;
	vUseAllotmentSales = True;
	vSelectedFields = cmGetReportUsedFields(ReportBuilder);
	For Each vReportDimensionsUsageRow In vReportDimensionsUsage Do
		If vReportDimensionsUsageRow.Name = "Hotel" Then
			vReportDimensionsUsageRow.IsUsed = True;
			Continue;
		EndIf;
		If vReportDimensionsUsageRow.Name = "GuestGroup" Then
			vReportDimensionsUsageRow.IsUsed = True;
		EndIf;
		If vReportDimensionsUsageRow.Name = "Client" Then
			vReportDimensionsUsageRow.IsUsed = True;
		EndIf;
		If vReportDimensionsUsageRow.Name = "AccountingDate" Then
			vReportDimensionsUsageRow.IsUsed = True;
			Continue;
		EndIf;
		If vReportDimensionsUsageRow.Name = "ServiceDate" Then
			vReportDimensionsUsageRow.IsUsed = True;
			Continue;
		EndIf;
		For Each vReportField In vSelectedFields Do
			If vReportField.DataPath = vReportDimensionsUsageRow.Name Or Left(vReportField.DataPath, StrLen(vReportDimensionsUsageRow.Name)) = vReportDimensionsUsageRow.Name Then
				vReportDimensionsUsageRow.IsUsed = True;
			EndIf;
			If vReportDimensionsUsageRow.Name = "TotalRoomsInAllotments" Or vReportDimensionsUsageRow.Name = "TotalBedsInAllotments" Then
				vUseAllotmentSales = True;
			EndIf;
		EndDo;
	EndDo;
	ReportBuilder.Parameters.Insert("qUseAllotmentSales", vUseAllotmentSales);
	vRBSettings = ReportBuilder.GetSettings(True, True, True, True, True);
	vQryText = ReportBuilder.Text;
	// Check report builder dimensions settings
	For Each vReportDimensionsUsageRow In vReportDimensionsUsage Do
		If Not vReportDimensionsUsageRow.IsUsed Then
			vQryText = StrReplace(vQryText, "SalesTurnovers." + vReportDimensionsUsageRow.Name + " AS ", "NULL AS ");
			vQryText = StrReplace(vQryText, "SalesForecastTurnovers." + vReportDimensionsUsageRow.Name + ",", "NULL,");
			If vReportDimensionsUsageRow.Name = "Client" Then
				vQryText = StrReplace(vQryText, "CustomerSalesFull.Client = ClientCheckInStatistics.Client", "FALSE");
			EndIf;
			If vReportDimensionsUsageRow.Name = "Customer" Then
				vQryText = StrReplace(vQryText, "SalesTurnovers.ParentDoc." + vReportDimensionsUsageRow.Name + " AS ", "NULL AS ");
				vQryText = StrReplace(vQryText, "SalesForecastTurnovers.ParentDoc." + vReportDimensionsUsageRow.Name + ",", "NULL,");
				vQryText = StrReplace(vQryText, "CustomerSalesFull.Customer = CustomerCheckInStatistics.Customer", "FALSE");
			EndIf;
			If vReportDimensionsUsageRow.Name = "Contract" Then
				vQryText = StrReplace(vQryText, "SalesTurnovers.ParentDoc." + vReportDimensionsUsageRow.Name + " AS ", "NULL AS ");
				vQryText = StrReplace(vQryText, "SalesForecastTurnovers.ParentDoc." + vReportDimensionsUsageRow.Name + ",", "NULL,");
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
	|	TotalInventoryBalanceAndTurnovers.Hotel AS Hotel,
	|	SUM(TotalInventoryBalanceAndTurnovers.CounterClosingBalance) AS CounterClosingBalance,
	|	SUM(TotalInventoryBalanceAndTurnovers.TotalRoomsClosingBalance) AS TotalRooms,
	|	SUM(TotalInventoryBalanceAndTurnovers.TotalBedsClosingBalance) AS TotalBeds,
	|	-SUM(TotalInventoryBalanceAndTurnovers.RoomsBlockedClosingBalance) AS TotalRoomsBlocked,
	|	-SUM(TotalInventoryBalanceAndTurnovers.BedsBlockedClosingBalance) AS TotalBedsBlocked
	|INTO HotelInventoryTotals
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qPeriodFrom, &qPeriodTo, DAY, RegisterRecordsAndPeriodBoundaries, Hotel IN HIERARCHY (&qHotel)) AS TotalInventoryBalanceAndTurnovers
	|
	|GROUP BY
	|	TotalInventoryBalanceAndTurnovers.Hotel
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TotalInventoryDailyBalanceAndTurnovers.Hotel AS Hotel,
	|	BEGINOFPERIOD(TotalInventoryDailyBalanceAndTurnovers.Period, DAY) AS AccountingDate,
	|	SUM(TotalInventoryDailyBalanceAndTurnovers.CounterClosingBalance) AS CounterClosingBalance,
	|	SUM(TotalInventoryDailyBalanceAndTurnovers.TotalRoomsClosingBalance) AS TotalRooms,
	|	SUM(TotalInventoryDailyBalanceAndTurnovers.TotalBedsClosingBalance) AS TotalBeds,
	|	-SUM(TotalInventoryDailyBalanceAndTurnovers.RoomsBlockedClosingBalance) AS TotalRoomsBlocked,
	|	-SUM(TotalInventoryDailyBalanceAndTurnovers.BedsBlockedClosingBalance) AS TotalBedsBlocked
	|INTO HotelInventoryDailyTotals
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qPeriodFrom, &qPeriodTo, DAY, RegisterRecordsAndPeriodBoundaries, Hotel IN HIERARCHY (&qHotel)) AS TotalInventoryDailyBalanceAndTurnovers
	|
	|GROUP BY
	|	TotalInventoryDailyBalanceAndTurnovers.Hotel,
	|	BEGINOFPERIOD(TotalInventoryDailyBalanceAndTurnovers.Period, DAY)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TotalInventoryMonthlyBalanceAndTurnovers.Hotel AS Hotel,
	|	BEGINOFPERIOD(TotalInventoryMonthlyBalanceAndTurnovers.Period, MONTH) AS AccountingDate,
	|	SUM(TotalInventoryMonthlyBalanceAndTurnovers.CounterClosingBalance) AS CounterClosingBalance,
	|	SUM(TotalInventoryMonthlyBalanceAndTurnovers.TotalRoomsClosingBalance) AS TotalRooms,
	|	SUM(TotalInventoryMonthlyBalanceAndTurnovers.TotalBedsClosingBalance) AS TotalBeds,
	|	-SUM(TotalInventoryMonthlyBalanceAndTurnovers.RoomsBlockedClosingBalance) AS TotalRoomsBlocked,
	|	-SUM(TotalInventoryMonthlyBalanceAndTurnovers.BedsBlockedClosingBalance) AS TotalBedsBlocked
	|INTO HotelInventoryMonthlyTotals
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qPeriodFrom, &qPeriodTo, DAY, RegisterRecordsAndPeriodBoundaries, Hotel IN HIERARCHY (&qHotel)) AS TotalInventoryMonthlyBalanceAndTurnovers
	|
	|GROUP BY
	|	TotalInventoryMonthlyBalanceAndTurnovers.Hotel,
	|	BEGINOFPERIOD(TotalInventoryMonthlyBalanceAndTurnovers.Period, MONTH)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ClientTotals.Client AS Client,
	|	ClientTotals.TotalSales AS TotalSales,
	|	ClientTotals.TotalGuestDays AS TotalGuestDays,
	|	ClientTotals.TotalGuestsCheckedIn AS TotalGuestsCheckedIn,
	|	ClientTotals.TotalRoomsRented AS TotalRoomsRented,
	|	ClientTotals.TotalBedsRented AS TotalBedsRented,
	|	ClientTotals.TotalRoomRevenue AS TotalRoomRevenue,
	|	ISNULL(Repeaters.NumberOfPrevCheckins, 0) AS NumberOfPrevCheckins
	|INTO ClientTotals
	|FROM
	|	(SELECT
	|		ClientMergedTotals.Client AS Client,
	|		SUM(ClientMergedTotals.TotalSales) AS TotalSales,
	|		SUM(ClientMergedTotals.TotalGuestDays) AS TotalGuestDays,
	|		SUM(ClientMergedTotals.TotalGuestsCheckedIn) AS TotalGuestsCheckedIn,
	|		SUM(ClientMergedTotals.TotalRoomsRented) AS TotalRoomsRented,
	|		SUM(ClientMergedTotals.TotalBedsRented) AS TotalBedsRented,
	|		SUM(ClientMergedTotals.TotalRoomRevenue) AS TotalRoomRevenue
	|	FROM
	|		(SELECT
	|			SalesTurnovers.Client AS Client,
	|			SalesTurnovers.SalesTurnover AS TotalSales,
	|			SalesTurnovers.GuestDaysTurnover AS TotalGuestDays,
	|			SalesTurnovers.GuestsCheckedInTurnover AS TotalGuestsCheckedIn,
	|			SalesTurnovers.RoomsRentedTurnover AS TotalRoomsRented,
	|			SalesTurnovers.BedsRentedTurnover AS TotalBedsRented,
	|			SalesTurnovers.RoomRevenueTurnover AS TotalRoomRevenue
	|		FROM
	|			AccumulationRegister.Sales.Turnovers(
	|					&qPeriodFrom,
	|					&qPeriodTo,
	|					Period,
	|					NOT IsCorrection
	|						AND Hotel IN HIERARCHY (&qHotel)
	|						AND (Service IN (&qServicesList)
	|							OR NOT &qUseServicesList)) AS SalesTurnovers
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			SalesForecastTurnovers.Client,
	|			SalesForecastTurnovers.SalesTurnover,
	|			SalesForecastTurnovers.GuestDaysTurnover,
	|			SalesForecastTurnovers.GuestsCheckedInTurnover,
	|			SalesForecastTurnovers.RoomsRentedTurnover,
	|			SalesForecastTurnovers.BedsRentedTurnover,
	|			SalesForecastTurnovers.RoomRevenueTurnover
	|		FROM
	|			AccumulationRegister.SalesForecast.Turnovers(
	|					&qForecastPeriodFrom,
	|					&qForecastPeriodTo,
	|					Period,
	|					Hotel IN HIERARCHY (&qHotel)
	|						AND (Service IN (&qServicesList)
	|							OR NOT &qUseServicesList)) AS SalesForecastTurnovers) AS ClientMergedTotals
	|	WHERE
	|		ClientMergedTotals.Client <> &qEmptyClient
	|	
	|	GROUP BY
	|		ClientMergedTotals.Client) AS ClientTotals
	|		LEFT JOIN (SELECT
	|			ClientTurnovers.Client AS Client,
	|			ClientTurnovers.GuestsCheckedInTurnover AS NumberOfPrevCheckins
	|		FROM
	|			AccumulationRegister.Sales.Turnovers(
	|					,
	|					&qPeriodFrom,
	|					PERIOD,
	|					NOT IsCorrection
	|						AND Hotel IN HIERARCHY (&qHotel)) AS ClientTurnovers) AS Repeaters
	|		ON ClientTotals.Client = Repeaters.Client
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CheckInTotals.TotalGuestsCheckedIn AS NumberOfCheckIns,
	|	COUNT(CheckInTotals.Client) AS CountOfGuestsCheckedIn
	|INTO CheckInTotals
	|FROM
	|	ClientTotals AS CheckInTotals
	|
	|GROUP BY
	|	CheckInTotals.TotalGuestsCheckedIn
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(TotalNumberOfClients.CountOfGuestsCheckedIn) AS TotalNumberOfGuests
	|INTO TotalNumberOfClients
	|FROM
	|	CheckInTotals AS TotalNumberOfClients
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	HotelInventoryDailyTotals.Hotel AS Hotel,
	|	HotelInventoryDailyTotals.AccountingDate AS AccountingDate,
	|	ISNULL(GuestsDailyStats.GuestDays, 0) AS GuestDays,
	|	ISNULL(GuestsDailyStats.GuestsCheckedIn, 0) AS GuestsCheckedIn
	|INTO GuestsDailyStats
	|FROM
	|	HotelInventoryDailyTotals AS HotelInventoryDailyTotals
	|		LEFT JOIN (SELECT
	|			GuestStatisticsDaily.Hotel AS Hotel,
	|			GuestStatisticsDaily.AccountingDate AS AccountingDate,
	|			SUM(GuestStatisticsDaily.GuestDays) AS GuestDays,
	|			SUM(GuestStatisticsDaily.GuestsCheckedIn) AS GuestsCheckedIn
	|		FROM
	|			(SELECT
	|				SalesTurnovers.Hotel AS Hotel,
	|				SalesTurnovers.AccountingDate AS AccountingDate,
	|				SalesTurnovers.GuestDaysTurnover AS GuestDays,
	|				SalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedIn
	|			FROM
	|				AccumulationRegister.Sales.Turnovers(
	|						&qPeriodFrom,
	|						&qPeriodTo,
	|						Period,
	|						NOT IsCorrection
	|							AND Hotel IN HIERARCHY (&qHotel)
	|							AND (Service IN (&qServicesList)
	|								OR NOT &qUseServicesList)) AS SalesTurnovers
	|			
	|			UNION ALL
	|			
	|			SELECT
	|				SalesForecastTurnovers.Hotel,
	|				SalesForecastTurnovers.AccountingDate,
	|				SalesForecastTurnovers.GuestDaysTurnover,
	|				SalesForecastTurnovers.GuestsCheckedInTurnover
	|			FROM
	|				AccumulationRegister.SalesForecast.Turnovers(
	|						&qForecastPeriodFrom,
	|						&qForecastPeriodTo,
	|						Period,
	|						Hotel IN HIERARCHY (&qHotel)
	|							AND (Service IN (&qServicesList)
	|								OR NOT &qUseServicesList)) AS SalesForecastTurnovers) AS GuestStatisticsDaily
	|		
	|		GROUP BY
	|			GuestStatisticsDaily.Hotel,
	|			GuestStatisticsDaily.AccountingDate) AS GuestsDailyStats
	|		ON HotelInventoryDailyTotals.Hotel = GuestsDailyStats.Hotel
	|			AND HotelInventoryDailyTotals.AccountingDate = GuestsDailyStats.AccountingDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GuestsDailyStats.Hotel AS Hotel,
	|	BEGINOFPERIOD(GuestsDailyStats.AccountingDate, MONTH) AS AccountingDate,
	|	SUM(GuestsDailyStats.GuestDays) AS GuestDays,
	|	SUM(GuestsDailyStats.GuestsCheckedIn) AS GuestsCheckedIn
	|INTO GuestsMonthlyStats
	|FROM
	|	GuestsDailyStats AS GuestsDailyStats
	|
	|GROUP BY
	|	GuestsDailyStats.Hotel,
	|	BEGINOFPERIOD(GuestsDailyStats.AccountingDate, MONTH)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	HotelTotals.Hotel AS Hotel,
	|	SUM(HotelTotals.TotalSales) AS TotalSales,
	|	SUM(HotelTotals.TotalGuestDays) AS TotalGuestDays,
	|	SUM(HotelTotals.TotalGuestsCheckedIn) AS TotalGuestsCheckedIn,
	|	SUM(HotelTotals.TotalRoomsRented) AS TotalRoomsRented,
	|	SUM(HotelTotals.TotalBedsRented) AS TotalBedsRented,
	|	SUM(HotelTotals.TotalRoomRevenue) AS TotalRoomRevenue
	|INTO HotelTotals
	|FROM
	|	(SELECT
	|		SalesTurnovers.Hotel AS Hotel,
	|		SalesTurnovers.SalesTurnover AS TotalSales,
	|		SalesTurnovers.GuestDaysTurnover AS TotalGuestDays,
	|		SalesTurnovers.GuestsCheckedInTurnover AS TotalGuestsCheckedIn,
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
	|		SalesForecastTurnovers.GuestDaysTurnover,
	|		SalesForecastTurnovers.GuestsCheckedInTurnover,
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
	|						OR NOT &qUseServicesList)) AS SalesForecastTurnovers) AS HotelTotals
	|
	|GROUP BY
	|	HotelTotals.Hotel
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllotmentSales.Hotel AS Hotel,
	|	AllotmentSales.RoomQuota.Customer AS Customer,
	|	SUM(ISNULL(AllotmentSales.CounterClosingBalance, 0)) AS CounterClosingBalance,
	|	SUM(ISNULL(AllotmentSales.RoomsInQuotaClosingBalance, 0)) + SUM(ISNULL(AllotmentSales.CounterClosingBalance, 0)) - SUM(ISNULL(AllotmentSales.CounterClosingBalance, 0)) AS RoomsInQuotaClosingBalance,
	|	SUM(ISNULL(AllotmentSales.BedsInQuotaClosingBalance, 0)) + SUM(ISNULL(AllotmentSales.CounterClosingBalance, 0)) - SUM(ISNULL(AllotmentSales.CounterClosingBalance, 0)) AS BedsInQuotaClosingBalance,
	|	-SUM(ISNULL(AllotmentSales.RoomsReservedClosingBalance, 0)) - SUM(ISNULL(AllotmentSales.InHouseRoomsClosingBalance, 0)) AS OccupiedRoomsClosingBalance,
	|	-SUM(ISNULL(AllotmentSales.BedsReservedClosingBalance, 0)) - SUM(ISNULL(AllotmentSales.InHouseBedsClosingBalance, 0)) AS OccupiedBedsClosingBalance
	|INTO AllotmentSales
	|FROM
	|	AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			RegisterRecordsAndPeriodBoundaries,
	|			Hotel IN HIERARCHY (&qHotel)
	|				AND (RoomQuota.Customer IN HIERARCHY (&qCustomer)
	|					OR &qIsEmptyCustomer)
	|				AND (RoomQuota.Contract = &qContract
	|					OR &qIsEmptyContract)) AS AllotmentSales
	|
	|GROUP BY
	|	AllotmentSales.Hotel,
	|	AllotmentSales.RoomQuota.Customer
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CustomerSalesFull.Hotel AS Hotel,
	|	CustomerSalesFull.Company AS Company,
	|	CustomerSalesFull.ReportingCurrency AS ReportingCurrency,
	|	CustomerSalesFull.Agent AS Agent,
	|	CustomerSalesFull.Customer AS Customer,
	|	CustomerSalesFull.Contract AS Contract,
	|	CustomerSalesFull.GuestGroup AS GuestGroup,
	|	CustomerSalesFull.AccountingDate AS AccountingDate,
	|	DATEADD(CustomerSalesFull.AccountingDate, DAY, 1) AS NextAccountingDate,
	|	CustomerSalesFull.Client AS Client,
	|	CustomerSalesFull.ParentDoc AS ParentDoc,
	|	CustomerSalesFull.CheckInDate AS CheckInDate,
	|	CustomerSalesFull.CheckOutDate AS CheckOutDate,
	|	CustomerSalesFull.Service AS Service,
	|	CustomerSalesFull.PaymentMethod AS PaymentMethod,
	|	CustomerSalesFull.ClientType AS ClientType,
	|	CustomerSalesFull.Folio AS Folio,
	|	CustomerSalesFull.RoomRate AS RoomRate,
	|	CustomerSalesFull.Room AS Room,
	|	CustomerSalesFull.RoomType AS RoomType,
	|	CustomerSalesFull.AccommodationType AS AccommodationType,
	|	CustomerSalesFull.TripPurpose AS TripPurpose,
	|	CustomerSalesFull.MarketingCode AS MarketingCode,
	|	CustomerSalesFull.SourceOfBusiness AS SourceOfBusiness,
	|	CustomerSalesFull.Resource AS Resource,
	|	CustomerSalesFull.ResourceType AS ResourceType,
	|	CustomerSalesFull.Author AS Author,
	|	CustomerSalesFull.Discount AS Discount,
	|	CustomerSalesFull.DiscountType AS DiscountType,
	|	CustomerSalesFull.DiscountCard AS DiscountCard,
	|	CustomerSalesFull.AgentCommissionType AS AgentCommissionType,
	|	CustomerSalesFull.AgentCommission AS AgentCommission,
	|	CustomerSalesFull.VATRate AS VATRate,
	|	CustomerSalesFull.Price AS Price,
	|	CustomerSalesFull.HotelProduct AS HotelProduct,
	|	CustomerSalesFull.SalesTurnover AS Sales,
	|	CustomerSalesFull.RoomRevenueTurnover AS RoomRevenue,
	|	CustomerSalesFull.ExtraBedRevenueTurnover AS ExtraBedRevenue,
	|	CustomerSalesFull.SalesWithoutVATTurnover AS SalesWithoutVAT,
	|	CustomerSalesFull.RoomRevenueWithoutVATTurnover AS RoomRevenueWithoutVAT,
	|	CustomerSalesFull.ExtraBedRevenueWithoutVATTurnover AS ExtraBedRevenueWithoutVAT,
	|	CustomerSalesFull.CommissionSumTurnover AS CommissionSum,
	|	CustomerSalesFull.CommissionSumWithoutVATTurnover AS CommissionSumWithoutVAT,
	|	CustomerSalesFull.DiscountSumTurnover AS DiscountSum,
	|	CustomerSalesFull.DiscountSumWithoutVATTurnover AS DiscountSumWithoutVAT,
	|	CustomerSalesFull.RoomsRentedTurnover AS RoomsRented,
	|	CustomerSalesFull.BedsRentedTurnover AS BedsRented,
	|	CustomerSalesFull.AdditionalBedsRentedTurnover AS AdditionalBedsRented,
	|	CustomerSalesFull.GuestDaysTurnover AS GuestDays,
	|	CASE
	|		WHEN DATEADD(CustomerSalesFull.AccountingDate, DAY, 1) = BEGINOFPERIOD(ISNULL(CustomerSalesFull.CheckOutDate, &qEmptyDate), DAY)
	|				AND ISNULL(CustomerSalesFull.AccommodationStatus.IsCheckOut, TRUE)
	|			THEN CustomerSalesFull.RoomsRentedTurnover
	|		ELSE 0
	|	END AS RoomsCheckedOut,
	|	CASE
	|		WHEN DATEADD(CustomerSalesFull.AccountingDate, DAY, 1) = BEGINOFPERIOD(ISNULL(CustomerSalesFull.CheckOutDate, &qEmptyDate), DAY)
	|				AND ISNULL(CustomerSalesFull.AccommodationStatus.IsCheckOut, TRUE)
	|			THEN CustomerSalesFull.BedsRentedTurnover
	|		ELSE 0
	|	END AS BedsCheckedOut,
	|	CASE
	|		WHEN DATEADD(CustomerSalesFull.AccountingDate, DAY, 1) = BEGINOFPERIOD(ISNULL(CustomerSalesFull.CheckOutDate, &qEmptyDate), DAY)
	|				AND ISNULL(CustomerSalesFull.AccommodationStatus.IsCheckOut, TRUE)
	|			THEN CustomerSalesFull.AdditionalBedsRentedTurnover
	|		ELSE 0
	|	END AS AdditionalBedsCheckedOut,
	|	CASE
	|		WHEN DATEADD(CustomerSalesFull.AccountingDate, DAY, 1) = BEGINOFPERIOD(ISNULL(CustomerSalesFull.CheckOutDate, &qEmptyDate), DAY)
	|				AND ISNULL(CustomerSalesFull.AccommodationStatus.IsCheckOut, TRUE)
	|			THEN CustomerSalesFull.GuestDaysTurnover
	|		ELSE 0
	|	END AS GuestsCheckedOut,
	|	CustomerSalesFull.GuestsCheckedInTurnover AS GuestsCheckedIn,
	|	CustomerSalesFull.NumberOfVisitsTurnover AS NumberOfVisits,
	|	CustomerSalesFull.RoomsCheckedInTurnover AS RoomsCheckedIn,
	|	CustomerSalesFull.BedsCheckedInTurnover AS BedsCheckedIn,
	|	CustomerSalesFull.AdditionalBedsCheckedInTurnover AS AdditionalBedsCheckedIn,
	|	CustomerSalesFull.BookingWindowTurnover AS BookingWindow,
	|	CustomerSalesFull.QuantityTurnover AS Quantity
	|INTO CustomerSalesFull
	|FROM
	|	(SELECT
	|		SalesTurnovers.Hotel AS Hotel,
	|		SalesTurnovers.Company AS Company,
	|		SalesTurnovers.ReportingCurrency AS ReportingCurrency,
	|		SalesTurnovers.Agent AS Agent,
	|		SalesTurnovers.ParentDoc.Customer AS Customer,
	|		SalesTurnovers.ParentDoc.Contract AS Contract,
	|		SalesTurnovers.ParentDoc.CheckInDate AS CheckInDate,
	|		SalesTurnovers.ParentDoc.CheckOutDate AS CheckOutDate,
	|		SalesTurnovers.ParentDoc.AccommodationStatus AS AccommodationStatus,
	|		SalesTurnovers.GuestGroup AS GuestGroup,
	|		SalesTurnovers.AccountingDate AS AccountingDate,
	|		SalesTurnovers.Client AS Client,
	|		SalesTurnovers.ParentDoc AS ParentDoc,
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
	|		CASE
	|			WHEN SalesTurnovers.GuestsCheckedInTurnover > 0
	|				THEN 1
	|			WHEN SalesTurnovers.GuestsCheckedInTurnover < 0
	|				THEN -1
	|			ELSE 0
	|		END AS NumberOfVisitsTurnover,
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
	|					AND (ParentDoc.Customer IN HIERARCHY (&qCustomer)
	|						OR &qIsEmptyCustomer)
	|					AND (ParentDoc.Contract = &qContract
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
	|		SalesForecastTurnovers.ParentDoc.Customer,
	|		SalesForecastTurnovers.ParentDoc.Contract,
	|		SalesForecastTurnovers.ParentDoc.CheckInDate,
	|		SalesForecastTurnovers.ParentDoc.CheckOutDate,
	|		SalesForecastTurnovers.ParentDoc.AccommodationStatus,
	|		SalesForecastTurnovers.GuestGroup,
	|		SalesForecastTurnovers.AccountingDate,
	|		SalesForecastTurnovers.Client,
	|		SalesForecastTurnovers.ParentDoc,
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
	|		CASE
	|			WHEN SalesForecastTurnovers.GuestsCheckedInTurnover > 0
	|				THEN 1
	|			WHEN SalesForecastTurnovers.GuestsCheckedInTurnover < 0
	|				THEN -1
	|			ELSE 0
	|		END,
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
	|					AND (ParentDoc.Customer IN HIERARCHY (&qCustomer)
	|						OR &qIsEmptyCustomer)
	|					AND (ParentDoc.Contract = &qContract
	|						OR &qIsEmptyContract)
	|					AND (GuestGroup = &qGuestGroup
	|						OR &qIsEmptyGuestGroup)
	|					AND (Service IN (&qServicesList)
	|						OR NOT &qUseServicesList)) AS SalesForecastTurnovers) AS CustomerSalesFull
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
	|	CustomerSales.ParentDoc AS ParentDoc,
	|	CustomerSales.CheckInDate AS CheckInDate,
	|	CustomerSales.CheckOutDate AS CheckOutDate,
	|	CustomerSales.Service AS Service,
	|	CustomerSales.ClientLastCheckInDate AS ClientLastCheckInDate,
	|	CustomerSales.ClientFirstCheckInDate AS ClientFirstCheckInDate,
	|	CustomerSales.ClientLastCheckInDuration AS ClientLastCheckInDuration,
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
	|	CustomerSales.NumberOfPrevCheckIns AS NumberOfPrevCheckIns,
	|	CASE
	|		WHEN CustomerSales.NumberOfPrevCheckIns > &qNumberOfPrevCheckinsForRepeater
	|			THEN &qRepeater
	|		ELSE """"
	|	END AS IsRepeater,
	|	CustomerSales.GuestDays AS GuestDays,
	|	CustomerSales.GuestsCheckedIn AS GuestsCheckedIn,
	|	CustomerSales.GuestsCheckedInDimension AS GuestsCheckedInDimension,
	|	CustomerSales.NumberOfVisits AS NumberOfVisits,
	|	CustomerSales.RoomsCheckedIn AS RoomsCheckedIn,
	|	CustomerSales.BedsCheckedIn AS BedsCheckedIn,
	|	CustomerSales.AdditionalBedsCheckedIn AS AdditionalBedsCheckedIn,
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
	|	CustomerSales.RoomsCheckedOut AS RoomsCheckedOut,
	|	CustomerSales.BedsCheckedOut AS BedsCheckedOut,
	|	CustomerSales.AdditionalBedsCheckedOut AS AdditionalBedsCheckedOut,
	|	CustomerSales.GuestsCheckedOut AS GuestsCheckedOut,
	|	CustomerSales.Quantity AS Quantity,
	|	CustomerSales.TotalSales AS TotalSales,
	|	CustomerSales.TotalRoomRevenue AS TotalRoomRevenue,
	|	CustomerSales.TotalGuestDays AS TotalGuestDays,
	|	CustomerSales.TotalGuestsCheckedIn AS TotalGuestsCheckedIn,
	|	CustomerSales.TotalNumberOfGuests AS TotalNumberOfGuests,
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
	|	CustomerSales.ALS AS ALS,
	|	CustomerSales.CountOfGuestsCheckedIn AS CountOfGuestsCheckedIn,
	|	CustomerSales.ReturnedGuestsPercent AS ReturnedGuestsPercent,
	|	ISNULL(AllotmentSales.RoomsInQuotaClosingBalance, 0) AS TotalRoomsInAllotments,
	|	ISNULL(AllotmentSales.BedsInQuotaClosingBalance, 0) AS TotalBedsInAllotments,
	|	ISNULL(AllotmentSales.OccupiedRoomsClosingBalance, 0) AS OccupiedRoomsInAllotments,
	|	ISNULL(AllotmentSales.BedsInQuotaClosingBalance, 0) AS OccupiedBedsInAllotments,
	|	CASE
	|		WHEN ISNULL(AllotmentSales.RoomsInQuotaClosingBalance, 0) > 0
	|			THEN ISNULL(AllotmentSales.RoomsInQuotaClosingBalance, 0) - CustomerSales.RoomsRented
	|		ELSE 0
	|	END AS VacantRoomsInAllotments,
	|	CASE
	|		WHEN ISNULL(AllotmentSales.BedsInQuotaClosingBalance, 0) > 0
	|			THEN ISNULL(AllotmentSales.BedsInQuotaClosingBalance, 0) - CustomerSales.BedsRented
	|		ELSE 0
	|	END AS VacantBedsInAllotments,
	|	CASE
	|		WHEN CustomerSales.RoomsRented > 0
	|			THEN CustomerSales.GuestDays / CustomerSales.RoomsRented
	|		ELSE 0
	|	END AS RoomsRentedConversion,
	|	CASE
	|		WHEN CustomerSales.BedsRented > 0
	|			THEN CustomerSales.GuestDays / CustomerSales.BedsRented
	|		ELSE 0
	|	END AS BedsRentedConversion,
	|	HotelInventoryTotals.TotalRooms + HotelInventoryTotals.CounterClosingBalance - HotelInventoryTotals.CounterClosingBalance AS TotalRooms,
	|	HotelInventoryTotals.TotalRoomsBlocked + HotelInventoryTotals.CounterClosingBalance - HotelInventoryTotals.CounterClosingBalance AS TotalRoomsBlocked,
	|	CASE
	|		WHEN HotelInventoryTotals.TotalRooms - HotelInventoryTotals.TotalRoomsBlocked <> 0
	|			THEN CustomerSales.RoomsRented / (HotelInventoryTotals.TotalRooms - HotelInventoryTotals.TotalRoomsBlocked + HotelInventoryTotals.CounterClosingBalance - HotelInventoryTotals.CounterClosingBalance) * 100
	|		ELSE 0
	|	END AS RoomsRentedPercent,
	|	HotelInventoryDailyTotals.TotalRooms + HotelInventoryDailyTotals.CounterClosingBalance - HotelInventoryDailyTotals.CounterClosingBalance AS TotalRoomsPerDay,
	|	HotelInventoryDailyTotals.TotalRoomsBlocked + HotelInventoryDailyTotals.CounterClosingBalance - HotelInventoryDailyTotals.CounterClosingBalance AS TotalRoomsBlockedPerDay,
	|	CASE
	|		WHEN HotelInventoryDailyTotals.TotalRooms - HotelInventoryDailyTotals.TotalRoomsBlocked <> 0
	|			THEN CustomerSales.RoomsRented / (HotelInventoryDailyTotals.TotalRooms - HotelInventoryDailyTotals.TotalRoomsBlocked + HotelInventoryDailyTotals.CounterClosingBalance - HotelInventoryDailyTotals.CounterClosingBalance) * 100
	|		ELSE 0
	|	END AS RoomsRentedPercentPerDay,
	|	HotelInventoryMonthlyTotals.TotalRooms + HotelInventoryMonthlyTotals.CounterClosingBalance - HotelInventoryMonthlyTotals.CounterClosingBalance AS TotalRoomsPerMonth,
	|	HotelInventoryMonthlyTotals.TotalRoomsBlocked + HotelInventoryMonthlyTotals.CounterClosingBalance - HotelInventoryMonthlyTotals.CounterClosingBalance AS TotalRoomsBlockedPerMonth,
	|	CASE
	|		WHEN HotelInventoryMonthlyTotals.TotalRooms - HotelInventoryMonthlyTotals.TotalRoomsBlocked <> 0
	|			THEN CustomerSales.RoomsRented / (HotelInventoryMonthlyTotals.TotalRooms - HotelInventoryMonthlyTotals.TotalRoomsBlocked + HotelInventoryMonthlyTotals.CounterClosingBalance - HotelInventoryMonthlyTotals.CounterClosingBalance) * 100
	|		ELSE 0
	|	END AS RoomsRentedPercentPerMonth,
	|	CASE
	|		WHEN GuestsDailyStats.GuestDays <> 0
	|			THEN CustomerSales.GuestDays / GuestsDailyStats.GuestDays
	|		ELSE 0
	|	END AS GuestDaysPercentPerDay,
	|	CASE
	|		WHEN GuestsDailyStats.GuestsCheckedIn <> 0
	|			THEN CustomerSales.GuestsCheckedIn / GuestsDailyStats.GuestsCheckedIn
	|		ELSE 0
	|	END AS GuestsCheckedInPercentPerDay,
	|	GuestsDailyStats.GuestDays AS TotalGuestDaysPerDay,
	|	GuestsDailyStats.GuestsCheckedIn AS TotalGuestsCheckedInPerDay,
	|	CASE
	|		WHEN GuestsMonthlyStats.GuestDays <> 0
	|			THEN CustomerSales.GuestDays / GuestsMonthlyStats.GuestDays
	|		ELSE 0
	|	END AS GuestDaysPercentPerMonth,
	|	CASE
	|		WHEN GuestsMonthlyStats.GuestsCheckedIn <> 0
	|			THEN CustomerSales.GuestsCheckedIn / GuestsMonthlyStats.GuestsCheckedIn
	|		ELSE 0
	|	END AS GuestsCheckedInPercentPerMonth,
	|	GuestsMonthlyStats.GuestDays AS TotalGuestDaysPerMonth,
	|	GuestsMonthlyStats.GuestsCheckedIn AS TotalGuestsCheckedInPerMonth,
	|	CustomerSales.AccountingDate AS AccountingDate,
	|	DAY(CustomerSales.AccountingDate) AS AccountingDay,
	|	DATEADD(BEGINOFPERIOD(CustomerSales.AccountingDate, WEEK), YEAR, -YEAR(CustomerSales.AccountingDate) + 1) AS AccountingWeek,
	|	DATEADD(BEGINOFPERIOD(CustomerSales.AccountingDate, MONTH), YEAR, -YEAR(CustomerSales.AccountingDate) + 1) AS AccountingMonth,
	|	DATEADD(BEGINOFPERIOD(CustomerSales.AccountingDate, QUARTER), YEAR, -YEAR(CustomerSales.AccountingDate) + 1) AS AccountingQuarter,
	|	YEAR(CustomerSales.AccountingDate) AS AccountingYear,
	|	1 - 1 AS RoomRevenuePlan,
	|	1 - 1 AS CustomerDebt
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
	|	CheckInDate,
	|	CheckOutDate,
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
	|	NumberOfPrevCheckIns,
	|	IsRepeater,
	|	GuestDays,
	|	GuestsCheckedIn,
	|	GuestsCheckedInDimension,
	|	NumberOfVisits,
	|	RoomsCheckedIn,
	|	BedsCheckedIn,
	|	AdditionalBedsCheckedIn,
	|	RoomsCheckedOut,
	|	BedsCheckedOut,
	|	AdditionalBedsCheckedOut,
	|	GuestsCheckedOut,
	|	BookingWindowDimension,
	|	BookingWindow,
	|	Quantity,
	|	ClientLastCheckInDate,
	|	ClientFirstCheckInDate,
	|	ClientLastCheckInDuration,
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
	|	TotalGuestDays,
	|	TotalGuestsCheckedIn,
	|	TotalNumberOfGuests,
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
	|	ALS,
	|	CountOfGuestsCheckedIn,
	|	ReturnedGuestsPercent,
	|	TotalRoomsInAllotments,
	|	TotalBedsInAllotments,
	|	OccupiedRoomsInAllotments,
	|	OccupiedBedsInAllotments,
	|	VacantRoomsInAllotments,
	|	VacantBedsInAllotments,
	|	RoomsRentedConversion,
	|	BedsRentedConversion,
	|	RoomRevenuePlan,
	|	CustomerDebt,
	|	TotalRooms,
	|	TotalRoomsBlocked,
	|	RoomsRentedPercent,
	|	TotalRoomsPerDay,
	|	TotalRoomsBlockedPerDay,
	|	RoomsRentedPercentPerDay,
	|	TotalRoomsPerMonth,
	|	TotalRoomsBlockedPerMonth,
	|	RoomsRentedPercentPerMonth,
	|	TotalGuestDaysPerDay,
	|	TotalGuestsCheckedInPerDay,
	|	GuestDaysPercentPerDay,
	|	GuestsCheckedInPercentPerDay,
	|	TotalGuestDaysPerMonth,
	|	TotalGuestsCheckedInPerMonth,
	|	GuestDaysPercentPerMonth,
	|	GuestsCheckedInPercentPerMonth}
	|FROM
	|	(SELECT
	|		CustomerSalesFull.Hotel AS Hotel,
	|		CustomerSalesFull.Company AS Company,
	|		CustomerSalesFull.ReportingCurrency AS ReportingCurrency,
	|		CustomerSalesFull.Agent AS Agent,
	|		CustomerSalesFull.Customer AS Customer,
	|		CustomerSalesFull.Contract AS Contract,
	|		CustomerSalesFull.GuestGroup AS GuestGroup,
	|		CustomerSalesFull.AccountingDate AS AccountingDate,
	|		CustomerSalesFull.Client AS Client,
	|		CustomerSalesFull.ParentDoc AS ParentDoc,
	|		CustomerSalesFull.CheckInDate AS CheckInDate,
	|		CustomerSalesFull.CheckOutDate AS CheckOutDate,
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
	|		CustomerSalesFull.Sales AS Sales,
	|		CustomerSalesFull.RoomRevenue AS RoomRevenue,
	|		CustomerSalesFull.ExtraBedRevenue AS ExtraBedRevenue,
	|		CustomerSalesFull.SalesWithoutVAT AS SalesWithoutVAT,
	|		CustomerSalesFull.RoomRevenueWithoutVAT AS RoomRevenueWithoutVAT,
	|		CustomerSalesFull.ExtraBedRevenueWithoutVAT AS ExtraBedRevenueWithoutVAT,
	|		CustomerSalesFull.CommissionSum AS CommissionSum,
	|		CustomerSalesFull.CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|		CustomerSalesFull.DiscountSum AS DiscountSum,
	|		CustomerSalesFull.DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|		CustomerSalesFull.RoomsRented AS RoomsRented,
	|		CustomerSalesFull.BedsRented AS BedsRented,
	|		CustomerSalesFull.AdditionalBedsRented AS AdditionalBedsRented,
	|		CustomerSalesFull.GuestDays AS GuestDays,
	|		CustomerSalesFull.GuestsCheckedIn AS GuestsCheckedIn,
	|		CustomerSalesFull.GuestsCheckedOut AS GuestsCheckedOut,
	|		CustomerSalesFull.NumberOfVisits AS NumberOfVisits,
	|		CustomerSalesFull.RoomsCheckedIn AS RoomsCheckedIn,
	|		CustomerSalesFull.BedsCheckedIn AS BedsCheckedIn,
	|		CustomerSalesFull.AdditionalBedsCheckedIn AS AdditionalBedsCheckedIn,
	|		CustomerSalesFull.RoomsCheckedOut AS RoomsCheckedOut,
	|		CustomerSalesFull.BedsCheckedOut AS BedsCheckedOut,
	|		CustomerSalesFull.AdditionalBedsCheckedOut AS AdditionalBedsCheckedOut,
	|		CustomerSalesFull.BookingWindow AS BookingWindow,
	|		CustomerSalesFull.Quantity AS Quantity,
	|		ClientCheckInStatistics.LastCheckInDate AS ClientLastCheckInDate,
	|		ClientCheckInStatistics.FirstCheckInDate AS ClientFirstCheckInDate,
	|		ClientLastCheckInData.LastCheckInDuration AS ClientLastCheckInDuration,
	|		CustomerCheckInStatistics.LastCheckInDate AS CustomerLastCheckInDate,
	|		CustomerCheckInStatistics.FirstCheckInDate AS CustomerFirstCheckInDate,
	|		HotelTotalSales.TotalSales AS TotalSales,
	|		HotelTotalSales.TotalGuestDays AS TotalGuestDays,
	|		HotelTotalSales.TotalGuestsCheckedIn AS TotalGuestsCheckedIn,
	|		TotalOfClients.TotalNumberOfGuests AS TotalNumberOfGuests,
	|		HotelTotalSales.TotalRoomRevenue AS TotalRoomRevenue,
	|		HotelTotalSales.TotalRoomsRented AS TotalRoomsRented,
	|		HotelTotalSales.TotalBedsRented AS TotalBedsRented,
	|		ISNULL(ClientTotalSales.NumberOfPrevCheckIns, 0) AS NumberOfPrevCheckIns,
	|		ISNULL(ClientTotalSales.TotalGuestsCheckedIn, 0) AS GuestsCheckedInDimension,
	|		ISNULL(TotalsByCheckIns.CountOfGuestsCheckedIn, 0) AS CountOfGuestsCheckedIn,
	|		CASE
	|			WHEN HotelTotalSales.TotalSales = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.Sales * 100 / HotelTotalSales.TotalSales
	|		END AS TotalSalesPercent,
	|		CASE
	|			WHEN HotelTotalSales.TotalRoomRevenue = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.RoomRevenue * 100 / HotelTotalSales.TotalRoomRevenue
	|		END AS TotalRoomRevenuePercent,
	|		CASE
	|			WHEN HotelTotalSales.TotalRoomsRented = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.RoomsRented * 100 / HotelTotalSales.TotalRoomsRented
	|		END AS TotalRoomsRentedPercent,
	|		CASE
	|			WHEN HotelTotalSales.TotalBedsRented = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.BedsRented * 100 / HotelTotalSales.TotalBedsRented
	|		END AS TotalBedsRentedPercent,
	|		CASE
	|			WHEN CustomerSalesFull.RoomsRented = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.RoomRevenue / CustomerSalesFull.RoomsRented
	|		END AS ADR,
	|		CASE
	|			WHEN CustomerSalesFull.BedsRented = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.RoomRevenue / CustomerSalesFull.BedsRented
	|		END AS ADBR,
	|		CASE
	|			WHEN CustomerSalesFull.RoomsRented = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.RoomRevenueWithoutVAT / CustomerSalesFull.RoomsRented
	|		END AS ADRWithoutVAT,
	|		CASE
	|			WHEN CustomerSalesFull.BedsRented = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.RoomRevenueWithoutVAT / CustomerSalesFull.BedsRented
	|		END AS ADBRWithoutVAT,
	|		CASE
	|			WHEN CustomerSalesFull.GuestDays = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.RoomRevenue / CustomerSalesFull.GuestDays
	|		END AS RevPAC,
	|		CASE
	|			WHEN CustomerSalesFull.GuestDays = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.RoomRevenueWithoutVAT / CustomerSalesFull.GuestDays
	|		END AS RevPACWithoutVAT,
	|		CASE
	|			WHEN CustomerSalesFull.GuestsCheckedIn = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.GuestDays / CustomerSalesFull.GuestsCheckedIn
	|		END AS ALS,
	|		CAST(CASE
	|				WHEN ISNULL(TotalOfClients.TotalNumberOfGuests, 0) = 0
	|					THEN 0
	|				ELSE ISNULL(TotalsByCheckIns.CountOfGuestsCheckedIn, 0) / ISNULL(TotalOfClients.TotalNumberOfGuests, 0) * 100
	|			END AS NUMBER(6, 2)) AS ReturnedGuestsPercent
	|	FROM
	|		(SELECT
	|			CustomerSales.Hotel AS Hotel,
	|			CustomerSales.Company AS Company,
	|			CustomerSales.ReportingCurrency AS ReportingCurrency,
	|			CustomerSales.Agent AS Agent,
	|			CustomerSales.Customer AS Customer,
	|			CustomerSales.Contract AS Contract,
	|			CustomerSales.GuestGroup AS GuestGroup,
	|			CustomerSales.AccountingDate AS AccountingDate,
	|			CustomerSales.Client AS Client,
	|			CustomerSales.ParentDoc AS ParentDoc,
	|			CustomerSales.CheckInDate AS CheckInDate,
	|			CustomerSales.CheckOutDate AS CheckOutDate,
	|			CustomerSales.Service AS Service,
	|			CustomerSales.PaymentMethod AS PaymentMethod,
	|			CustomerSales.ClientType AS ClientType,
	|			CustomerSales.Folio AS Folio,
	|			CustomerSales.RoomRate AS RoomRate,
	|			CustomerSales.Room AS Room,
	|			CustomerSales.RoomType AS RoomType,
	|			CustomerSales.AccommodationType AS AccommodationType,
	|			CustomerSales.TripPurpose AS TripPurpose,
	|			CustomerSales.MarketingCode AS MarketingCode,
	|			CustomerSales.SourceOfBusiness AS SourceOfBusiness,
	|			CustomerSales.Resource AS Resource,
	|			CustomerSales.ResourceType AS ResourceType,
	|			CustomerSales.Author AS Author,
	|			CustomerSales.Discount AS Discount,
	|			CustomerSales.DiscountType AS DiscountType,
	|			CustomerSales.DiscountCard AS DiscountCard,
	|			CustomerSales.AgentCommissionType AS AgentCommissionType,
	|			CustomerSales.AgentCommission AS AgentCommission,
	|			CustomerSales.VATRate AS VATRate,
	|			CustomerSales.Price AS Price,
	|			CustomerSales.HotelProduct AS HotelProduct,
	|			SUM(CustomerSales.Sales) AS Sales,
	|			SUM(CustomerSales.RoomRevenue) AS RoomRevenue,
	|			SUM(CustomerSales.ExtraBedRevenue) AS ExtraBedRevenue,
	|			SUM(CustomerSales.SalesWithoutVAT) AS SalesWithoutVAT,
	|			SUM(CustomerSales.RoomRevenueWithoutVAT) AS RoomRevenueWithoutVAT,
	|			SUM(CustomerSales.ExtraBedRevenueWithoutVAT) AS ExtraBedRevenueWithoutVAT,
	|			SUM(CustomerSales.CommissionSum) AS CommissionSum,
	|			SUM(CustomerSales.CommissionSumWithoutVAT) AS CommissionSumWithoutVAT,
	|			SUM(CustomerSales.DiscountSum) AS DiscountSum,
	|			SUM(CustomerSales.DiscountSumWithoutVAT) AS DiscountSumWithoutVAT,
	|			SUM(CustomerSales.RoomsRented) AS RoomsRented,
	|			SUM(CustomerSales.BedsRented) AS BedsRented,
	|			SUM(CustomerSales.AdditionalBedsRented) AS AdditionalBedsRented,
	|			SUM(CustomerSales.GuestDays) AS GuestDays,
	|			SUM(CustomerSales.GuestsCheckedIn) AS GuestsCheckedIn,
	|			SUM(CustomerSales.GuestsCheckedOut) AS GuestsCheckedOut,
	|			SUM(CustomerSales.NumberOfVisits) AS NumberOfVisits,
	|			SUM(CustomerSales.RoomsCheckedIn) AS RoomsCheckedIn,
	|			SUM(CustomerSales.BedsCheckedIn) AS BedsCheckedIn,
	|			SUM(CustomerSales.AdditionalBedsCheckedIn) AS AdditionalBedsCheckedIn,
	|			SUM(CustomerSales.RoomsCheckedOut) AS RoomsCheckedOut,
	|			SUM(CustomerSales.BedsCheckedOut) AS BedsCheckedOut,
	|			SUM(CustomerSales.AdditionalBedsCheckedOut) AS AdditionalBedsCheckedOut,
	|			SUM(CustomerSales.BookingWindow) AS BookingWindow,
	|			SUM(CustomerSales.Quantity) AS Quantity
	|		FROM
	|			(SELECT
	|				CustomerSalesNoCheckOut.Hotel AS Hotel,
	|				CustomerSalesNoCheckOut.Company AS Company,
	|				CustomerSalesNoCheckOut.ReportingCurrency AS ReportingCurrency,
	|				CustomerSalesNoCheckOut.Agent AS Agent,
	|				CustomerSalesNoCheckOut.Customer AS Customer,
	|				CustomerSalesNoCheckOut.Contract AS Contract,
	|				CustomerSalesNoCheckOut.GuestGroup AS GuestGroup,
	|				CustomerSalesNoCheckOut.AccountingDate AS AccountingDate,
	|				CustomerSalesNoCheckOut.Client AS Client,
	|				CustomerSalesNoCheckOut.ParentDoc AS ParentDoc,
	|				CustomerSalesNoCheckOut.CheckInDate AS CheckInDate,
	|				CustomerSalesNoCheckOut.CheckOutDate AS CheckOutDate,
	|				CustomerSalesNoCheckOut.Service AS Service,
	|				CustomerSalesNoCheckOut.PaymentMethod AS PaymentMethod,
	|				CustomerSalesNoCheckOut.ClientType AS ClientType,
	|				CustomerSalesNoCheckOut.Folio AS Folio,
	|				CustomerSalesNoCheckOut.RoomRate AS RoomRate,
	|				CustomerSalesNoCheckOut.Room AS Room,
	|				CustomerSalesNoCheckOut.RoomType AS RoomType,
	|				CustomerSalesNoCheckOut.AccommodationType AS AccommodationType,
	|				CustomerSalesNoCheckOut.TripPurpose AS TripPurpose,
	|				CustomerSalesNoCheckOut.MarketingCode AS MarketingCode,
	|				CustomerSalesNoCheckOut.SourceOfBusiness AS SourceOfBusiness,
	|				CustomerSalesNoCheckOut.Resource AS Resource,
	|				CustomerSalesNoCheckOut.ResourceType AS ResourceType,
	|				CustomerSalesNoCheckOut.Author AS Author,
	|				CustomerSalesNoCheckOut.Discount AS Discount,
	|				CustomerSalesNoCheckOut.DiscountType AS DiscountType,
	|				CustomerSalesNoCheckOut.DiscountCard AS DiscountCard,
	|				CustomerSalesNoCheckOut.AgentCommissionType AS AgentCommissionType,
	|				CustomerSalesNoCheckOut.AgentCommission AS AgentCommission,
	|				CustomerSalesNoCheckOut.VATRate AS VATRate,
	|				CustomerSalesNoCheckOut.Price AS Price,
	|				CustomerSalesNoCheckOut.HotelProduct AS HotelProduct,
	|				CustomerSalesNoCheckOut.Sales AS Sales,
	|				CustomerSalesNoCheckOut.RoomRevenue AS RoomRevenue,
	|				CustomerSalesNoCheckOut.ExtraBedRevenue AS ExtraBedRevenue,
	|				CustomerSalesNoCheckOut.SalesWithoutVAT AS SalesWithoutVAT,
	|				CustomerSalesNoCheckOut.RoomRevenueWithoutVAT AS RoomRevenueWithoutVAT,
	|				CustomerSalesNoCheckOut.ExtraBedRevenueWithoutVAT AS ExtraBedRevenueWithoutVAT,
	|				CustomerSalesNoCheckOut.CommissionSum AS CommissionSum,
	|				CustomerSalesNoCheckOut.CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|				CustomerSalesNoCheckOut.DiscountSum AS DiscountSum,
	|				CustomerSalesNoCheckOut.DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|				CustomerSalesNoCheckOut.RoomsRented AS RoomsRented,
	|				CustomerSalesNoCheckOut.BedsRented AS BedsRented,
	|				CustomerSalesNoCheckOut.AdditionalBedsRented AS AdditionalBedsRented,
	|				CustomerSalesNoCheckOut.GuestDays AS GuestDays,
	|				CustomerSalesNoCheckOut.GuestsCheckedIn AS GuestsCheckedIn,
	|				0 AS GuestsCheckedOut,
	|				CustomerSalesNoCheckOut.NumberOfVisits AS NumberOfVisits,
	|				CustomerSalesNoCheckOut.RoomsCheckedIn AS RoomsCheckedIn,
	|				CustomerSalesNoCheckOut.BedsCheckedIn AS BedsCheckedIn,
	|				CustomerSalesNoCheckOut.AdditionalBedsCheckedIn AS AdditionalBedsCheckedIn,
	|				0 AS RoomsCheckedOut,
	|				0 AS BedsCheckedOut,
	|				0 AS AdditionalBedsCheckedOut,
	|				CustomerSalesNoCheckOut.BookingWindow AS BookingWindow,
	|				CustomerSalesNoCheckOut.Quantity AS Quantity
	|			FROM
	|				CustomerSalesFull AS CustomerSalesNoCheckOut
	|			
	|			UNION ALL
	|			
	|			SELECT
	|				CustomerSalesCheckOut.Hotel,
	|				CustomerSalesCheckOut.Company,
	|				CustomerSalesCheckOut.ReportingCurrency,
	|				CustomerSalesCheckOut.Agent,
	|				CustomerSalesCheckOut.Customer,
	|				CustomerSalesCheckOut.Contract,
	|				CustomerSalesCheckOut.GuestGroup,
	|				CustomerSalesCheckOut.NextAccountingDate,
	|				CustomerSalesCheckOut.Client,
	|				CustomerSalesCheckOut.ParentDoc,
	|				CustomerSalesCheckOut.CheckInDate,
	|				CustomerSalesCheckOut.CheckOutDate,
	|				CustomerSalesCheckOut.Service,
	|				CustomerSalesCheckOut.PaymentMethod,
	|				CustomerSalesCheckOut.ClientType,
	|				CustomerSalesCheckOut.Folio,
	|				CustomerSalesCheckOut.RoomRate,
	|				CustomerSalesCheckOut.Room,
	|				CustomerSalesCheckOut.RoomType,
	|				CustomerSalesCheckOut.AccommodationType,
	|				CustomerSalesCheckOut.TripPurpose,
	|				CustomerSalesCheckOut.MarketingCode,
	|				CustomerSalesCheckOut.SourceOfBusiness,
	|				CustomerSalesCheckOut.Resource,
	|				CustomerSalesCheckOut.ResourceType,
	|				CustomerSalesCheckOut.Author,
	|				CustomerSalesCheckOut.Discount,
	|				CustomerSalesCheckOut.DiscountType,
	|				CustomerSalesCheckOut.DiscountCard,
	|				CustomerSalesCheckOut.AgentCommissionType,
	|				CustomerSalesCheckOut.AgentCommission,
	|				CustomerSalesCheckOut.VATRate,
	|				CustomerSalesCheckOut.Price,
	|				CustomerSalesCheckOut.HotelProduct,
	|				0,
	|				0,
	|				0,
	|				0,
	|				0,
	|				0,
	|				0,
	|				0,
	|				0,
	|				0,
	|				0,
	|				0,
	|				0,
	|				0,
	|				0,
	|				CustomerSalesCheckOut.GuestsCheckedOut,
	|				0,
	|				0,
	|				0,
	|				0,
	|				CustomerSalesCheckOut.RoomsCheckedOut,
	|				CustomerSalesCheckOut.BedsCheckedOut,
	|				CustomerSalesCheckOut.AdditionalBedsCheckedOut,
	|				0,
	|				0
	|			FROM
	|				CustomerSalesFull AS CustomerSalesCheckOut) AS CustomerSales
	|		
	|		GROUP BY
	|			CustomerSales.Hotel,
	|			CustomerSales.Company,
	|			CustomerSales.ReportingCurrency,
	|			CustomerSales.Agent,
	|			CustomerSales.Customer,
	|			CustomerSales.Contract,
	|			CustomerSales.GuestGroup,
	|			CustomerSales.AccountingDate,
	|			CustomerSales.Client,
	|			CustomerSales.ParentDoc,
	|			CustomerSales.CheckInDate,
	|			CustomerSales.CheckOutDate,
	|			CustomerSales.Service,
	|			CustomerSales.PaymentMethod,
	|			CustomerSales.ClientType,
	|			CustomerSales.Folio,
	|			CustomerSales.RoomRate,
	|			CustomerSales.Room,
	|			CustomerSales.RoomType,
	|			CustomerSales.AccommodationType,
	|			CustomerSales.TripPurpose,
	|			CustomerSales.MarketingCode,
	|			CustomerSales.SourceOfBusiness,
	|			CustomerSales.Resource,
	|			CustomerSales.ResourceType,
	|			CustomerSales.Author,
	|			CustomerSales.Discount,
	|			CustomerSales.DiscountType,
	|			CustomerSales.DiscountCard,
	|			CustomerSales.AgentCommissionType,
	|			CustomerSales.AgentCommission,
	|			CustomerSales.VATRate,
	|			CustomerSales.Price,
	|			CustomerSales.HotelProduct) AS CustomerSalesFull
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
	|				RoomInventory.Guest AS Client,
	|				BEGINOFPERIOD(RoomInventory.CheckInDate, DAY) AS LastCheckInDate,
	|				MAX(RoomInventory.Duration) AS LastCheckInDuration
	|			FROM
	|				AccumulationRegister.RoomInventory AS RoomInventory
	|			WHERE
	|				RoomInventory.IsAccommodation
	|				AND RoomInventory.IsCheckIn
	|			
	|			GROUP BY
	|				RoomInventory.Guest,
	|				BEGINOFPERIOD(RoomInventory.CheckInDate, DAY)) AS ClientLastCheckInData
	|			ON CustomerSalesFull.Client = ClientLastCheckInData.Client
	|				AND (ClientLastCheckInData.LastCheckInDate = BEGINOFPERIOD(ClientCheckInStatistics.LastCheckInDate, DAY))
	|			LEFT JOIN (SELECT
	|				RoomInventory.Customer AS Customer,
	|				MAX(RoomInventory.CheckInDate) AS LastCheckInDate,
	|				MIN(RoomInventory.CheckInDate) AS FirstCheckInDate
	|			FROM
	|				AccumulationRegister.RoomInventory AS RoomInventory
	|			WHERE
	|				RoomInventory.IsAccommodation
	|				AND RoomInventory.IsCheckIn
	|			
	|			GROUP BY
	|				RoomInventory.Customer) AS CustomerCheckInStatistics
	|			ON CustomerSalesFull.Customer = CustomerCheckInStatistics.Customer
	|			LEFT JOIN (SELECT
	|				HotelTotals.Hotel AS Hotel,
	|				HotelTotals.TotalGuestDays AS TotalGuestDays,
	|				HotelTotals.TotalGuestsCheckedIn AS TotalGuestsCheckedIn,
	|				HotelTotals.TotalRoomRevenue AS TotalRoomRevenue,
	|				HotelTotals.TotalRoomsRented AS TotalRoomsRented,
	|				HotelTotals.TotalBedsRented AS TotalBedsRented,
	|				HotelTotals.TotalSales AS TotalSales
	|			FROM
	|				HotelTotals AS HotelTotals) AS HotelTotalSales
	|			ON CustomerSalesFull.Hotel = HotelTotalSales.Hotel
	|			LEFT JOIN (SELECT
	|				ClientTotals.Client AS Client,
	|				ClientTotals.TotalGuestDays AS TotalGuestDays,
	|				ClientTotals.TotalGuestsCheckedIn AS TotalGuestsCheckedIn,
	|				ClientTotals.TotalRoomRevenue AS TotalRoomRevenue,
	|				ClientTotals.TotalRoomsRented AS TotalRoomsRented,
	|				ClientTotals.TotalBedsRented AS TotalBedsRented,
	|				ClientTotals.TotalSales AS TotalSales,
	|				ClientTotals.NumberOfPrevCheckins AS NumberOfPrevCheckIns
	|			FROM
	|				ClientTotals AS ClientTotals) AS ClientTotalSales
	|			ON CustomerSalesFull.Client = ClientTotalSales.Client
	|			LEFT JOIN (SELECT
	|				CheckInTotals.NumberOfCheckIns AS NumberOfCheckIns,
	|				CheckInTotals.CountOfGuestsCheckedIn AS CountOfGuestsCheckedIn
	|			FROM
	|				CheckInTotals AS CheckInTotals) AS TotalsByCheckIns
	|			ON (ClientTotalSales.TotalGuestsCheckedIn = TotalsByCheckIns.NumberOfCheckIns)
	|			LEFT JOIN (SELECT
	|				TotalNumberOfClients.TotalNumberOfGuests AS TotalNumberOfGuests
	|			FROM
	|				TotalNumberOfClients AS TotalNumberOfClients) AS TotalOfClients
	|			ON (TRUE)) AS CustomerSales
	|		LEFT JOIN AllotmentSales AS AllotmentSales
	|		ON CustomerSales.Customer = AllotmentSales.Customer
	|			AND CustomerSales.Hotel = AllotmentSales.Hotel
	|			AND (&qUseAllotmentSales)
	|		LEFT JOIN HotelInventoryTotals AS HotelInventoryTotals
	|		ON CustomerSales.Hotel = HotelInventoryTotals.Hotel
	|		LEFT JOIN HotelInventoryDailyTotals AS HotelInventoryDailyTotals
	|		ON CustomerSales.Hotel = HotelInventoryDailyTotals.Hotel
	|			AND CustomerSales.AccountingDate = HotelInventoryDailyTotals.AccountingDate
	|		LEFT JOIN HotelInventoryMonthlyTotals AS HotelInventoryMonthlyTotals
	|		ON CustomerSales.Hotel = HotelInventoryMonthlyTotals.Hotel
	|			AND (BEGINOFPERIOD(CustomerSales.AccountingDate, MONTH) = HotelInventoryMonthlyTotals.AccountingDate)
	|		LEFT JOIN GuestsDailyStats AS GuestsDailyStats
	|		ON CustomerSales.Hotel = GuestsDailyStats.Hotel
	|			AND CustomerSales.AccountingDate = GuestsDailyStats.AccountingDate
	|		LEFT JOIN GuestsMonthlyStats AS GuestsMonthlyStats
	|		ON CustomerSales.Hotel = GuestsMonthlyStats.Hotel
	|			AND (BEGINOFPERIOD(CustomerSales.AccountingDate, MONTH) = GuestsMonthlyStats.AccountingDate)
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
	|	CustomerSales.NumberOfPrevCheckIns,
	|	(CASE
	|			WHEN CustomerSales.NumberOfPrevCheckIns > &qNumberOfPrevCheckinsForRepeater
	|				THEN &qRepeater
	|			ELSE """"
	|		END) AS IsRepeater,
	|	CustomerSales.GuestDays AS GuestDays,
	|	CustomerSales.GuestsCheckedIn AS GuestsCheckedIn,
	|	CustomerSales.GuestsCheckedInDimension AS GuestsCheckedInDimension,
	|	CustomerSales.NumberOfVisits AS NumberOfVisits,
	|	CustomerSales.RoomsCheckedIn AS RoomsCheckedIn,
	|	CustomerSales.BedsCheckedIn AS BedsCheckedIn,
	|	CustomerSales.AdditionalBedsCheckedIn AS AdditionalBedsCheckedIn,
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
	|	CustomerSales.ClientLastCheckInDuration AS ClientLastCheckInDuration,
	|	CustomerSales.CustomerLastCheckInDate AS CustomerLastCheckInDate,
	|	CustomerSales.CustomerFirstCheckInDate AS CustomerFirstCheckInDate,
	|	CustomerSales.AccountingDate,
	|	(DAY(CustomerSales.AccountingDate)) AS AccountingDay,
	|	(DATEADD(BEGINOFPERIOD(CustomerSales.AccountingDate, WEEK), YEAR, -YEAR(CustomerSales.AccountingDate) + 1)) AS AccountingWeek,
	|	(DATEADD(BEGINOFPERIOD(CustomerSales.AccountingDate, MONTH), YEAR, -YEAR(CustomerSales.AccountingDate) + 1)) AS AccountingMonth,
	|	(DATEADD(BEGINOFPERIOD(CustomerSales.AccountingDate, QUARTER), YEAR, -YEAR(CustomerSales.AccountingDate) + 1)) AS AccountingQuarter,
	|	(YEAR(CustomerSales.AccountingDate)) AS AccountingYear,
	|	(CASE
	|			WHEN NOT CustomerSales.GuestGroup.GroupType.Code IS NULL
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS IsGroupReservation,
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
	|	CustomerSales.ALS AS ALS,
	|	CustomerSales.ReturnedGuestsPercent,
	|	HotelInventoryTotals.TotalRooms AS TotalRooms,
	|	HotelInventoryTotals.TotalRoomsBlocked AS TotalRoomsBlocked,
	|	(CASE
	|			WHEN HotelInventoryTotals.TotalRooms - HotelInventoryTotals.TotalRoomsBlocked <> 0
	|				THEN CustomerSales.RoomsRented / (HotelInventoryTotals.TotalRooms - HotelInventoryTotals.TotalRoomsBlocked) * 100
	|			ELSE 0
	|		END) AS RoomsRentedPercent,
	|	HotelInventoryDailyTotals.TotalRooms AS TotalRoomsPerDay,
	|	HotelInventoryDailyTotals.TotalRoomsBlocked AS TotalRoomsBlockedPerDay,
	|	(CASE
	|			WHEN HotelInventoryDailyTotals.TotalRooms - HotelInventoryDailyTotals.TotalRoomsBlocked <> 0
	|				THEN CustomerSales.RoomsRented / (HotelInventoryDailyTotals.TotalRooms - HotelInventoryDailyTotals.TotalRoomsBlocked) * 100
	|			ELSE 0
	|		END) AS RoomsRentedPercentPerDay,
	|	HotelInventoryMonthlyTotals.TotalRooms AS TotalRoomsPerMonth,
	|	HotelInventoryMonthlyTotals.TotalRoomsBlocked AS TotalRoomsBlockedPerMonth,
	|	(CASE
	|			WHEN HotelInventoryMonthlyTotals.TotalRooms - HotelInventoryMonthlyTotals.TotalRoomsBlocked <> 0
	|				THEN CustomerSales.RoomsRented / (HotelInventoryMonthlyTotals.TotalRooms - HotelInventoryMonthlyTotals.TotalRoomsBlocked) * 100
	|			ELSE 0
	|		END) AS RoomsRentedPercentPerMonth}
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
	|	NumberOfPrevCheckIns,
	|	IsRepeater,
	|	GuestDays,
	|	GuestsCheckedInDimension,
	|	NumberOfVisits,
	|	RoomsCheckedIn,
	|	BedsCheckedIn,
	|	AdditionalBedsCheckedIn,
	|	BookingWindowDimension,
	|	BookingWindow,
	|	RoomsCheckedOut,
	|	BedsCheckedOut,
	|	AdditionalBedsCheckedOut,
	|	GuestsCheckedOut,
	|	Quantity,
	|	ClientLastCheckInDate,
	|	ClientFirstCheckInDate,
	|	ClientLastCheckInDuration,
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
	|	ALS,
	|	ReturnedGuestsPercent,
	|	TotalRoomsInAllotments,
	|	TotalBedsInAllotments,
	|	OccupiedRoomsInAllotments,
	|	OccupiedBedsInAllotments,
	|	VacantRoomsInAllotments,
	|	VacantBedsInAllotments,
	|	RoomsRentedConversion,
	|	BedsRentedConversion,
	|	GuestDaysPercentPerDay,
	|	GuestsCheckedInPercentPerDay,
	|	GuestDaysPercentPerMonth,
	|	GuestsCheckedInPercentPerMonth}
	|TOTALS
	|	MAX(ClientLastCheckInDate),
	|	MIN(ClientFirstCheckInDate),
	|	MAX(ClientLastCheckInDuration),
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
	|	SUM(NumberOfVisits),
	|	SUM(RoomsCheckedIn),
	|	SUM(BedsCheckedIn),
	|	SUM(AdditionalBedsCheckedIn),
	|	CASE
	|		WHEN SUM(RoomsCheckedIn) <> 0
	|			THEN CAST(SUM(BookingWindow) / SUM(RoomsCheckedIn) AS NUMBER(10, 0))
	|		ELSE 0
	|	END AS BookingWindow,
	|	SUM(RoomsCheckedOut),
	|	SUM(BedsCheckedOut),
	|	SUM(AdditionalBedsCheckedOut),
	|	SUM(GuestsCheckedOut),
	|	SUM(Quantity),
	|	MAX(TotalSales),
	|	MAX(TotalRoomRevenue),
	|	MAX(TotalGuestDays),
	|	MAX(TotalGuestsCheckedIn),
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
	|	END AS ALS,
	|	CASE
	|		WHEN GuestsCheckedInDimension IS NULL
	|			THEN 100
	|		ELSE MAX(ReturnedGuestsPercent)
	|	END AS ReturnedGuestsPercent,
	|	CASE
	|		WHEN NOT Customer IS NULL
	|			THEN MAX(TotalRoomsInAllotments)
	|		ELSE 0
	|	END AS TotalRoomsInAllotments,
	|	CASE
	|		WHEN NOT Customer IS NULL
	|			THEN MAX(TotalBedsInAllotments)
	|		ELSE 0
	|	END AS TotalBedsInAllotments,
	|	CASE
	|		WHEN NOT Customer IS NULL
	|			THEN MAX(OccupiedRoomsInAllotments)
	|		ELSE 0
	|	END AS OccupiedRoomsInAllotments,
	|	CASE
	|		WHEN NOT Customer IS NULL
	|			THEN MAX(OccupiedBedsInAllotments)
	|		ELSE 0
	|	END AS OccupiedBedsInAllotments,
	|	CASE
	|		WHEN NOT Customer IS NULL
	|				AND MAX(TotalRoomsInAllotments) > SUM(RoomsRented)
	|			THEN MAX(TotalRoomsInAllotments) - SUM(RoomsRented)
	|		ELSE 0
	|	END AS VacantRoomsInAllotments,
	|	CASE
	|		WHEN NOT Customer IS NULL
	|				AND MAX(TotalBedsInAllotments) > SUM(BedsRented)
	|			THEN SUM(TotalBedsInAllotments) - SUM(BedsRented)
	|		ELSE 0
	|	END AS VacantBedsInAllotments,
	|	CASE
	|		WHEN SUM(RoomsRented) > 0
	|			THEN SUM(GuestDays) / SUM(RoomsRented)
	|		ELSE 0
	|	END AS RoomsRentedConversion,
	|	CASE
	|		WHEN SUM(BedsRented) > 0
	|			THEN SUM(GuestDays) / SUM(BedsRented)
	|		ELSE 0
	|	END AS BedsRentedConversion,
	|	MAX(TotalRooms),
	|	MAX(TotalRoomsBlocked),
	|	CASE
	|		WHEN MAX(TotalRooms - TotalRoomsBlocked) <> 0
	|			THEN SUM(RoomsRented) / MAX(TotalRooms - TotalRoomsBlocked) * 100
	|		ELSE 0
	|	END AS RoomsRentedPercent,
	|	MAX(TotalRoomsPerDay),
	|	MAX(TotalRoomsBlockedPerDay),
	|	CASE
	|		WHEN AccountingDay IS NULL
	|			THEN CASE
	|					WHEN SUM(TotalRoomsPerDay) - SUM(TotalRoomsBlockedPerDay) <> 0
	|						THEN SUM(RoomsRented) / (SUM(TotalRoomsPerDay) - SUM(TotalRoomsBlockedPerDay)) * 100
	|					ELSE 0
	|				END
	|		ELSE CASE
	|				WHEN MAX(TotalRoomsPerDay) - MAX(TotalRoomsBlockedPerDay) <> 0
	|					THEN SUM(RoomsRented) / (MAX(TotalRoomsPerDay) - MAX(TotalRoomsBlockedPerDay)) * 100
	|				ELSE 0
	|			END
	|	END AS RoomsRentedPercentPerDay,
	|	MAX(TotalRoomsPerMonth),
	|	MAX(TotalRoomsBlockedPerMonth),
	|	CASE
	|		WHEN AccountingMonth IS NULL
	|			THEN CASE
	|					WHEN SUM(TotalRoomsPerMonth) - SUM(TotalRoomsBlockedPerMonth) <> 0
	|						THEN SUM(RoomsRented) / (SUM(TotalRoomsPerMonth) - SUM(TotalRoomsBlockedPerMonth)) * 100
	|					ELSE 0
	|				END
	|		ELSE CASE
	|				WHEN MAX(TotalRoomsPerMonth) - MAX(TotalRoomsBlockedPerMonth) <> 0
	|					THEN SUM(RoomsRented) / (MAX(TotalRoomsPerMonth) - MAX(TotalRoomsBlockedPerMonth)) * 100
	|				ELSE 0
	|			END
	|	END AS RoomsRentedPercentPerMonth,
	|	CASE
	|		WHEN AccountingDate IS NULL
	|				AND AccountingMonth IS NULL
	|				AND MAX(TotalGuestDays) <> 0
	|			THEN SUM(GuestDays) / MAX(TotalGuestDays) * 100
	|		WHEN AccountingDate IS NULL
	|				AND NOT AccountingMonth IS NULL
	|				AND SUM(TotalGuestDaysPerMonth) <> 0
	|			THEN SUM(GuestDays) / MAX(TotalGuestDaysPerMonth) * 100
	|		WHEN MAX(TotalGuestDaysPerDay) <> 0
	|			THEN SUM(GuestDays) / MAX(TotalGuestDaysPerDay) * 100
	|		ELSE 0
	|	END AS GuestDaysPercentPerDay,
	|	CASE
	|		WHEN AccountingDate IS NULL
	|				AND AccountingMonth IS NULL
	|				AND MAX(TotalGuestsCheckedIn) <> 0
	|			THEN SUM(GuestsCheckedIn) / MAX(TotalGuestsCheckedIn) * 100
	|		WHEN AccountingDate IS NULL
	|				AND NOT AccountingMonth IS NULL
	|				AND MAX(TotalGuestsCheckedInPerMonth) <> 0
	|			THEN SUM(GuestsCheckedIn) / MAX(TotalGuestsCheckedInPerMonth) * 100
	|		WHEN MAX(TotalGuestsCheckedInPerDay) <> 0
	|			THEN SUM(GuestsCheckedIn) / MAX(TotalGuestsCheckedInPerDay) * 100
	|		ELSE 0
	|	END AS GuestsCheckedInPercentPerDay,
	|	CASE
	|		WHEN AccountingMonth IS NULL
	|				AND MAX(TotalGuestDays) <> 0
	|			THEN SUM(GuestDays) / MAX(TotalGuestDays) * 100
	|		WHEN MAX(TotalGuestDaysPerMonth) <> 0
	|			THEN SUM(GuestDays) / MAX(TotalGuestDaysPerMonth) * 100
	|		ELSE 0
	|	END AS GuestDaysPercentPerMonth,
	|	CASE
	|		WHEN AccountingMonth IS NULL
	|				AND MAX(TotalGuestsCheckedIn) <> 0
	|			THEN SUM(GuestsCheckedIn) / MAX(TotalGuestsCheckedIn) * 100
	|		WHEN MAX(TotalGuestsCheckedInPerDay) <> 0
	|			THEN SUM(GuestsCheckedIn) / MAX(TotalGuestsCheckedInPerMonth) * 100
	|		ELSE 0
	|	END AS GuestsCheckedInPercentPerMonth,
	|	SUM(RoomRevenuePlan),
	|	SUM(CustomerDebt)
	|BY
	|	OVERALL,
	|	ReportingCurrency,
	|	Customer HIERARCHY,
	|	GuestsCheckedInDimension,
	|	CountOfGuestsCheckedIn,
	|	AccountingDate,
	|	AccountingMonth
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
	|	(CASE
	|			WHEN NOT CustomerSales.GuestGroup.GroupType.Code IS NULL
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS IsGroupReservation,
	|	BookingWindowDimension,
	|	ADR,
	|	GuestsCheckedInDimension,
	|	AccountingDate,
	|	AccountingDay,
	|	AccountingWeek,
	|	AccountingMonth,
	|	AccountingQuarter,
	|	AccountingYear,
	|	NumberOfPrevCheckIns,
	|	IsRepeater}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("en='Customer guests turnovers';de='Verkaufsumsätze nach Gästen der Firmen';ru='Обороты продаж по гостям от контрагентов'");
	
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
	   Or pName = "NumberOfVisits" 
	   Or pName = "RoomsCheckedIn" 
	   Or pName = "BedsCheckedIn" 
	   Or pName = "AdditionalBedsCheckedIn" 
	   Or pName = "Quantity" 
	   Or pName = "TotalRoomRevenue" 
	   Or pName = "TotalSales" 
	   Or pName = "TotalCuestsCheckedIn" 
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
	   Or pName = "BookingWindow" 
	   Or pName = "GuestsCheckedOut" 
	   Or pName = "RoomsCheckedOut" 
	   Or pName = "BedsCheckedOut" 
	   Or pName = "ReturnedGuestsPercent" 
	   Or pName = "TotalRoomsInAllotments" 
	   Or pName = "TotalBedsInAllotments" 
	   Or pName = "OccupiedRoomsInAllotments" 
	   Or pName = "OccupiedBedsInAllotments" 
	   Or pName = "VacantRoomsInAllotments" 
	   Or pName = "VacantBedsInAllotments" 
	   Or pName = "RoomsRentedConversion" 
	   Or pName = "BedsRentedConversion" 
	   Or pName = "RoomRevenuePlan" 
	   Or pName = "CustomerDebt" 
	   Or pName = "TotalRooms"
	   Or pName = "TotalRoomsBlocked"
	   Or pName = "TotalRoomsPerDay"
	   Or pName = "TotalRoomsBlockedPerDay"
	   Or pName = "TotalRoomsPerMonth"
	   Or pName = "TotalRoomsBlockedPerMonth"
	   Or pName = "RoomsRentedPercent"
	   Or pName = "RoomsRentedPercentPerDay"
	   Or pName = "RoomsRentedPercentPerMonth" Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // pmIsResource

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
