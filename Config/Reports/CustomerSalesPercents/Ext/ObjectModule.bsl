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
			vParamPresentation = vParamPresentation + NStr("en='Rooms folder ';ru='Группа номеров ';de='Gruppe Zimmer '") + 
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
			vParamPresentation = vParamPresentation + NStr("en='Room types folder ';ru='Группа типов номеров ';de='Gruppe Zimmertypen '") + 
			                     TrimAll(RoomType.Description) + 
			                     ";" + Chars.LF;
		EndIf;
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
	
	vTotalsAvailable = True;
	
	// Check if there is any custom ordering applied for the report builder
	vOrderString = "";
	For Each vOrderItem In ReportBuilder.Order Do
		vDataPath = vOrderItem.DataPath;
		vDotPos = StrFind(vDataPath, ".");
		If vDotPos > 0 Then
			vDataPath = Left(vDataPath, vDotPos - 1);
		EndIf;
		vOrderString = vOrderString + ?(IsBlankString(vOrderString), "", ", ") + vDataPath + ?(vOrderItem.Direction = SortDirection.Desc, " Desc", "");
	EndDo;
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
	
	// Initialize report builder query generator attributes
	ReportBuilder.PresentationAdding = PresentationAdditionType.Add;
	
	// Run query to get available rooms for days
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	TotalRoomInventoryBalanceAndTurnovers.Period AS Period,
	|	SUM(TotalRoomInventoryBalanceAndTurnovers.CounterClosingBalance) AS CounterClosingBalance,
	|	SUM(TotalRoomInventoryBalanceAndTurnovers.TotalRoomsClosingBalance) AS TotalRooms,
	|	SUM(TotalRoomInventoryBalanceAndTurnovers.TotalBedsClosingBalance) AS TotalBeds,
	|	-SUM(TotalRoomInventoryBalanceAndTurnovers.RoomsBlockedClosingBalance) AS TotalRoomsBlocked,
	|	-SUM(TotalRoomInventoryBalanceAndTurnovers.BedsBlockedClosingBalance) AS TotalBedsBlocked,
	|	SUM(TotalRoomInventoryBalanceAndTurnovers.GuestsReservedReceipt) AS TotalGuestsReservedReceipt,
	|	SUM(TotalRoomInventoryBalanceAndTurnovers.GuestsReservedExpense) AS TotalGuestsReservedExpense,
	|	SUM(TotalRoomInventoryBalanceAndTurnovers.InHouseGuestsReceipt) AS TotalInHouseGuestsReceipt,
	|	SUM(TotalRoomInventoryBalanceAndTurnovers.InHouseGuestsExpense) AS TotalInHouseGuestsExpense
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			RegisterRecordsAndPeriodBoundaries,
	|			Hotel IN HIERARCHY (&qHotel)
	|				AND (Room IN HIERARCHY (&qRoom)
	|					OR &qIsEmptyRoom)
	|				AND (RoomType IN HIERARCHY (&qRoomType)
	|					OR &qIsEmptyRoomType)) AS TotalRoomInventoryBalanceAndTurnovers
	|
	|GROUP BY
	|	TotalRoomInventoryBalanceAndTurnovers.Period
	|
	|ORDER BY
	|	Period";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qPeriodFrom", PeriodFrom);
	vQry.SetParameter("qPeriodTo", PeriodTo);
	vQry.SetParameter("qRoom", Room);
	vQry.SetParameter("qIsEmptyRoom", Not ValueIsFilled(Room));
	vQry.SetParameter("qRoomType", RoomType);
	vQry.SetParameter("qIsEmptyRoomType", Not ValueIsFilled(RoomType));
	vTotals = vQry.Execute().Unload();
	
	AddMissingPeriods(vTotals);
	
	vTotalRooms = vTotals.Total("TotalRooms");
	vTotalBeds = vTotals.Total("TotalBeds");
	vTotalRoomsBlocked = vTotals.Total("TotalRoomsBlocked");
	vTotalBedsBlocked = vTotals.Total("TotalBedsBlocked");
	vTotalRoomsAvailable = vTotalRooms - vTotalRoomsBlocked;
	vTotalBedsAvailable = vTotalBeds - vTotalBedsBlocked;
	
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
	vQry.SetParameter("qCustomer", Customer);
	vQry.SetParameter("qIsEmptyCustomer", Not ValueIsFilled(Customer));
	vQry.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	vQry.SetParameter("qRoom", Room);
	vQry.SetParameter("qIsEmptyRoom", Not ValueIsFilled(Room));
	vQry.SetParameter("qRoomType", RoomType);
	vQry.SetParameter("qIsEmptyRoomType", Not ValueIsFilled(RoomType));
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
	vQry.SetParameter("qEmptyString", "                  ");
	vResults = vQry.Execute().Unload();
	
	// Get total sales and room revenue assuming this is the first row in the query results table
	vTotalRoomRevenue = 0;
	vTotalRoomRevenueWithoutVAT = 0;
	vTotalSales = 0;
	vTotalSalesWithoutVAT = 0;
	vTotalCommissionSum = 0;
	vTotalCommissionSumWithoutVAT = 0;
	vTotalDiscountSum = 0;
	vTotalDiscountSumWithoutVAT = 0;
	vTotalRoomsRented = 0;
	vTotalBedsRented = 0;
	vTotalAdditionalBedsRented = 0;
	vTotalGuestDays = 0;
	vTotalGuestsCheckedIn = 0;
	vTotalRoomsCheckedIn = 0;
	vTotalBedsCheckedIn = 0;
	vTotalAdditionalBedsCheckedIn = 0;
	If vResults.Count() > 0 Then
		vRow = vResults.Get(0);
		
		vTotalRoomRevenue = vRow.RoomRevenue;
		vTotalRoomRevenueWithoutVAT = vRow.RoomRevenueWithoutVAT;
		vTotalSales = vRow.Sales;
		vTotalSalesWithoutVAT = vRow.SalesWithoutVAT;
		vTotalCommissionSum = vRow.CommissionSum;
		vTotalCommissionSumWithoutVAT = vRow.CommissionSumWithoutVAT;
		vTotalDiscountSum = vRow.DiscountSum;
		vTotalDiscountSumWithoutVAT = vRow.DiscountSumWithoutVAT;
		vTotalRoomsRented = vRow.RoomsRented;
		vTotalBedsRented = vRow.BedsRented;
		vTotalAdditionalBedsRented = vRow.BedsRented;
		vTotalGuestDays = vRow.GuestDays;
		vTotalGuestsCheckedIn = vRow.GuestsCheckedIn;
		vTotalRoomsCheckedIn = vRow.RoomsCheckedIn;
		vTotalBedsCheckedIn = vRow.BedsCheckedIn;
		vTotalAdditionalBedsCheckedIn = vRow.AdditionalBedsCheckedIn;
	EndIf;
	
	// For each row in resulting table calculate all percents
	For Each vRow In vResults Do
		vRow.TotalRooms = vTotalRooms;
		vRow.TotalBeds = vTotalBeds;
		vRow.TotalRoomsBlocked = vTotalRoomsBlocked;
		vRow.TotalBedsBlocked = vTotalBedsBlocked;
		vRow.TotalRoomsRentedPercent = Round(?(vTotalRooms = 0, 0, 100 * vRow.RoomsRented/vTotalRooms), 2);
		vRow.TotalBedsRentedPercent = Round(?(vTotalBeds = 0, 0, 100 * vRow.BedsRented/vTotalBeds), 2);
		vRow.RoomRevenuePercent = Round(?(vTotalRoomRevenue = 0, 0, 100 * vRow.RoomRevenue/vTotalRoomRevenue), 2);
		vRow.SalesPercent = Round(?(vTotalSales = 0, 0, 100 * vRow.Sales/vTotalSales), 2);

		vRow.ADR = ?(vRow.RoomsRented = 0, 0, Round(vRow.RoomRevenue/vRow.RoomsRented, 2));
		vRow.ADRWithoutVAT = ?(vRow.RoomsRented = 0, 0, Round(vRow.RoomRevenueWithoutVAT/vRow.RoomsRented, 2));
		vRow.ADBR = ?(vRow.BedsRented = 0, 0, Round(vRow.RoomRevenue/vRow.BedsRented, 2));
		vRow.ADBRWithoutVAT = ?(vRow.BedsRented = 0, 0, Round(vRow.RoomRevenueWithoutVAT/vRow.BedsRented, 2));
		vRow.RevPAC = ?(vRow.GuestDays = 0, 0, Round(vRow.RoomRevenue/vRow.GuestDays, 2));
		vRow.RevPACWithoutVAT = ?(vRow.GuestDays = 0, 0, Round(vRow.RoomRevenueWithoutVAT/vRow.GuestDays, 2));
		vRow.ALS = ?(vRow.GuestsCheckedIn = 0, 0, Round(vRow.GuestDays/vRow.GuestsCheckedIn, 3));
		
		// Calculate ABC analysis percent
		vRow.ABCAnalysisPercent = 0;
		If ABCAnalysisResourceName = "Sales" Then
			vRow.ABCAnalysisPercent = ?(vTotalSales = 0, 0, Round(100*vRow.Sales/vTotalSales, 7));
		ElsIf ABCAnalysisResourceName = "SalesWithoutVAT" Then
			vRow.ABCAnalysisPercent = ?(vTotalSalesWithoutVAT = 0, 0, Round(100*vRow.SalesWithoutVAT/vTotalSalesWithoutVAT, 7));
		ElsIf ABCAnalysisResourceName = "RoomRevenue" Then
			vRow.ABCAnalysisPercent = ?(vTotalRoomRevenue = 0, 0, Round(100*vRow.RoomRevenue/vTotalRoomRevenue, 7));
		ElsIf ABCAnalysisResourceName = "RoomRevenueWithoutVAT" Then
			vRow.ABCAnalysisPercent = ?(vTotalRoomRevenueWithoutVAT = 0, 0, Round(100*vRow.RoomRevenueWithoutVAT/vTotalRoomRevenueWithoutVAT, 7));
		ElsIf ABCAnalysisResourceName = "CommissionSum" Then
			vRow.ABCAnalysisPercent = ?(vTotalCommissionSum = 0, 0, Round(100*vRow.CommissionSum/vTotalCommissionSum, 7));
		ElsIf ABCAnalysisResourceName = "CommissionSumWithoutVAT" Then
			vRow.ABCAnalysisPercent = ?(vTotalCommissionSumWithoutVAT = 0, 0, Round(100*vRow.CommissionSumWithoutVAT/vTotalCommissionSumWithoutVAT, 7));
		ElsIf ABCAnalysisResourceName = "DiscountSum" Then
			vRow.ABCAnalysisPercent = ?(vTotalDiscountSum = 0, 0, Round(100*vRow.DiscountSum/vTotalDiscountSum, 7));
		ElsIf ABCAnalysisResourceName = "DiscountSumWithoutVAT" Then
			vRow.ABCAnalysisPercent = ?(vTotalDiscountSumWithoutVAT = 0, 0, Round(100*vRow.DiscountSumWithoutVAT/vTotalDiscountSumWithoutVAT, 7));
		ElsIf ABCAnalysisResourceName = "RoomsRented" Then
			vRow.ABCAnalysisPercent = ?(vTotalRoomsRented = 0, 0, Round(100*vRow.RoomsRented/vTotalRoomsRented, 7));
		ElsIf ABCAnalysisResourceName = "BedsRented" Then
			vRow.ABCAnalysisPercent = ?(vTotalBedsRented = 0, 0, Round(100*vRow.BedsRented/vTotalBedsRented, 7));
		ElsIf ABCAnalysisResourceName = "AdditionalBedsRented" Then
			vRow.ABCAnalysisPercent = ?(vTotalAdditionalBedsRented = 0, 0, Round(100*vRow.AdditionalBedsRented/vTotalAdditionalBedsRented, 7));
		ElsIf ABCAnalysisResourceName = "GuestDays" Then
			vRow.ABCAnalysisPercent = ?(vTotalGuestDays = 0, 0, Round(100*vRow.GuestDays/vTotalGuestDays, 7));
		ElsIf ABCAnalysisResourceName = "GuestsCheckedIn" Then
			vRow.ABCAnalysisPercent = ?(vTotalGuestsCheckedIn = 0, 0, Round(100*vRow.GuestsCheckedIn/vTotalGuestsCheckedIn, 7));
		ElsIf ABCAnalysisResourceName = "RoomsCheckedIn" Then
			vRow.ABCAnalysisPercent = ?(vTotalRoomsCheckedIn = 0, 0, Round(100*vRow.RoomsCheckedIn/vTotalRoomsCheckedIn, 7));
		ElsIf ABCAnalysisResourceName = "BedsCheckedIn" Then
			vRow.ABCAnalysisPercent = ?(vTotalBedsCheckedIn = 0, 0, Round(100*vRow.BedsCheckedIn/vTotalBedsCheckedIn, 7));
		ElsIf ABCAnalysisResourceName = "AdditionalBedsCheckedIn" Then
			vRow.ABCAnalysisPercent = ?(vTotalAdditionalBedsCheckedIn = 0, 0, Round(100*vRow.AdditionalBedsCheckedIn/vTotalAdditionalBedsCheckedIn, 7));
		EndIf;
	EndDo;
	
	// Calculate ABC analysis group
	If Not IsBlankString(ABCAnalysisResourceName) And vResults.Count() > 0 Then
		vABCAnalysisResults = vResults.Copy();
		For Each vABCAnalysisRow In vABCAnalysisResults Do
			If Not ValueIsFilled(vABCAnalysisRow.ReportingCurrency) Then
				vABCAnalysisResults.Delete(vABCAnalysisRow);
				Break;
			EndIf;
		EndDo;
		vABCAnalysisResults.Sort("ABCAnalysisPercent DESC");
		vAccumulatingPercent = 0;
		For Each vABCAnalysisRow In vABCAnalysisResults Do
			If vAccumulatingPercent <= ABCAnalysisAGroupPercent Then
				vABCAnalysisRow.ABCAnalysisGroup = NStr("en='A Group';ru='Группа A';de='Gruppe A'");
			ElsIf vAccumulatingPercent <= (ABCAnalysisAGroupPercent + ABCAnalysisBGroupPercent) Then
				vABCAnalysisRow.ABCAnalysisGroup = NStr("en='B Group';ru='Группа B';de='Gruppe B'");
			Else
				vABCAnalysisRow.ABCAnalysisGroup = NStr("en='C Group';ru='Группа C';de='Gruppe C'");
			EndIf;
			vRows = vResults.FindRows(New Structure("ReportingCurrency, Hotel, Customer", vABCAnalysisRow.ReportingCurrency, vABCAnalysisRow.Hotel, vABCAnalysisRow.Customer));
			If vRows.Count() > 0 Then
				vRow = vRows.Get(0);
				vRow.ABCAnalysisGroup = vABCAnalysisRow.ABCAnalysisGroup;
			EndIf;
			vAccumulatingPercent = vAccumulatingPercent + vABCAnalysisRow.ABCAnalysisPercent;
		EndDo;
	EndIf;
	
	// Sort results according to the sort settings
	If Not IsBlankString(vOrderString) Then
		vResults.Sort(vOrderString);
	EndIf;
	
	// Try to find totals row and move it to the last position if available
	For Each vRow In vResults Do
		If Not ValueIsFilled(vRow.ReportingCurrency) Then
			If ReportDoNotPutOveralls Then
				vResults.Delete(vRow);
				vTotalsAvailable = False;
			Else
				vResults.Move(vRow, vResults.Count() - vResults.IndexOf(vRow) - 1);
			EndIf;
			Break;
		EndIf;
	EndDo;
	
	// Save current report builder settings
	vCurReportBuilderSettings = ReportBuilder.GetSettings(True, False, False, True, True);
	
	// Set resulting table as data source for the report builder
	ReportBuilder.DataSource = New DataSourceDescription(vResults);
	
	// Apply current report builder settings
	ReportBuilder.SetSettings(vCurReportBuilderSettings, True, False, False, True, True);
	
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
	If vResults.Count() > 0 And vTotalsAvailable Then
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
	|	CustomerSales.ReportingCurrency AS ReportingCurrency,
	|	CustomerSales.Hotel AS Hotel,
	|	CustomerSales.Customer AS Customer,
	|	&qEmptyString AS ABCAnalysisGroup,
	|	0 AS ABCAnalysisPercent,
	|	SUM(CustomerSales.SalesTurnover) AS Sales,
	|	SUM(CustomerSales.RoomRevenueTurnover) AS RoomRevenue,
	|	SUM(CustomerSales.SalesWithoutVATTurnover) AS SalesWithoutVAT,
	|	SUM(CustomerSales.RoomRevenueWithoutVATTurnover) AS RoomRevenueWithoutVAT,
	|	SUM(CustomerSales.CommissionSumTurnover) AS CommissionSum,
	|	SUM(CustomerSales.CommissionSumWithoutVATTurnover) AS CommissionSumWithoutVAT,
	|	SUM(CustomerSales.DiscountSumTurnover) AS DiscountSum,
	|	SUM(CustomerSales.DiscountSumWithoutVATTurnover) AS DiscountSumWithoutVAT,
	|	SUM(CustomerSales.RoomsRentedTurnover) AS RoomsRented,
	|	SUM(CustomerSales.BedsRentedTurnover) AS BedsRented,
	|	SUM(CustomerSales.AdditionalBedsRentedTurnover) AS AdditionalBedsRented,
	|	SUM(CustomerSales.GuestDaysTurnover) AS GuestDays,
	|	SUM(CustomerSales.GuestsCheckedInTurnover) AS GuestsCheckedIn,
	|	SUM(CustomerSales.RoomsCheckedInTurnover) AS RoomsCheckedIn,
	|	SUM(CustomerSales.BedsCheckedInTurnover) AS BedsCheckedIn,
	|	SUM(CustomerSales.AdditionalBedsCheckedInTurnover) AS AdditionalBedsCheckedIn,
	|	0 AS TotalRooms,
	|	0 AS TotalBeds,
	|	0 AS TotalRoomsBlocked,
	|	0 AS TotalBedsBlocked,
	|	0 AS TotalRoomsRentedPercent,
	|	0 AS TotalBedsRentedPercent,
	|	0 AS RoomRevenuePercent,
	|	0 AS SalesPercent,
	|	0 AS ADR,
	|	0 AS ADBR,
	|	0 AS ADRWithoutVAT,
	|	0 AS ADBRWithoutVAT,
	|	0 AS RevPAC,
	|	0 AS RevPACWithoutVAT,
	|	0 AS ALS
	|{SELECT
	|	ReportingCurrency.*,
	|	Hotel.*,
	|	Customer.*,
	|	ABCAnalysisGroup,
	|	ABCAnalysisPercent,
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
	|	TotalRooms,
	|	TotalBeds,
	|	TotalRoomsBlocked,
	|	TotalBedsBlocked,
	|	TotalRoomsRentedPercent,
	|	TotalBedsRentedPercent,
	|	RoomRevenuePercent,
	|	SalesPercent,
	|	ADR,
	|	ADBR,
	|	ADRWithoutVAT,
	|	ADBRWithoutVAT,
	|	RevPAC,
	|	RevPACWithoutVAT,
	|	ALS}
	|FROM
	|	(SELECT
	|		CustomerSalesTurnovers.ReportingCurrency AS ReportingCurrency,
	|		CustomerSalesTurnovers.Hotel AS Hotel,
	|		CASE
	|			WHEN CustomerSalesTurnovers.Customer = &qEmptyCustomer
	|				THEN CustomerSalesTurnovers.Hotel.IndividualsCustomer
	|			ELSE CustomerSalesTurnovers.Customer
	|		END AS Customer,
	|		CustomerSalesTurnovers.SalesTurnover AS SalesTurnover,
	|		CustomerSalesTurnovers.RoomRevenueTurnover AS RoomRevenueTurnover,
	|		CustomerSalesTurnovers.SalesWithoutVATTurnover AS SalesWithoutVATTurnover,
	|		CustomerSalesTurnovers.RoomRevenueWithoutVATTurnover AS RoomRevenueWithoutVATTurnover,
	|		CustomerSalesTurnovers.CommissionSumTurnover AS CommissionSumTurnover,
	|		CustomerSalesTurnovers.CommissionSumWithoutVATTurnover AS CommissionSumWithoutVATTurnover,
	|		CustomerSalesTurnovers.DiscountSumTurnover AS DiscountSumTurnover,
	|		CustomerSalesTurnovers.DiscountSumWithoutVATTurnover AS DiscountSumWithoutVATTurnover,
	|		CustomerSalesTurnovers.RoomsRentedTurnover AS RoomsRentedTurnover,
	|		CustomerSalesTurnovers.BedsRentedTurnover AS BedsRentedTurnover,
	|		CustomerSalesTurnovers.AdditionalBedsRentedTurnover AS AdditionalBedsRentedTurnover,
	|		CustomerSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover,
	|		CustomerSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
	|		CustomerSalesTurnovers.RoomsCheckedInTurnover AS RoomsCheckedInTurnover,
	|		CustomerSalesTurnovers.BedsCheckedInTurnover AS BedsCheckedInTurnover,
	|		CustomerSalesTurnovers.AdditionalBedsCheckedInTurnover AS AdditionalBedsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Day,
	|				NOT IsCorrection AND Hotel IN HIERARCHY (&qHotel)
	|					AND (Customer IN HIERARCHY (&qCustomer)
	|						OR &qIsEmptyCustomer)
	|					AND (ParentDoc.Room IN HIERARCHY (&qRoom)
	|						OR &qIsEmptyRoom)
	|					AND (ParentDoc.RoomType IN HIERARCHY (&qRoomType)
	|						OR &qIsEmptyRoomType)
	|					AND (Service IN (&qServicesList)
	|						OR NOT &qUseServicesList)) AS CustomerSalesTurnovers
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CustomerSalesForecastTurnovers.ReportingCurrency,
	|		CustomerSalesForecastTurnovers.Hotel,
	|		CASE
	|			WHEN CustomerSalesForecastTurnovers.Customer = &qEmptyCustomer
	|				THEN CustomerSalesForecastTurnovers.Hotel.IndividualsCustomer
	|			ELSE CustomerSalesForecastTurnovers.Customer
	|		END,
	|		CustomerSalesForecastTurnovers.SalesTurnover,
	|		CustomerSalesForecastTurnovers.RoomRevenueTurnover,
	|		CustomerSalesForecastTurnovers.SalesWithoutVATTurnover,
	|		CustomerSalesForecastTurnovers.RoomRevenueWithoutVATTurnover,
	|		CustomerSalesForecastTurnovers.CommissionSumTurnover,
	|		CustomerSalesForecastTurnovers.CommissionSumWithoutVATTurnover,
	|		CustomerSalesForecastTurnovers.DiscountSumTurnover,
	|		CustomerSalesForecastTurnovers.DiscountSumWithoutVATTurnover,
	|		CustomerSalesForecastTurnovers.RoomsRentedTurnover,
	|		CustomerSalesForecastTurnovers.BedsRentedTurnover,
	|		CustomerSalesForecastTurnovers.AdditionalBedsRentedTurnover,
	|		CustomerSalesForecastTurnovers.GuestDaysTurnover,
	|		CustomerSalesForecastTurnovers.GuestsCheckedInTurnover,
	|		CustomerSalesForecastTurnovers.RoomsCheckedInTurnover,
	|		CustomerSalesForecastTurnovers.BedsCheckedInTurnover,
	|		CustomerSalesForecastTurnovers.AdditionalBedsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.SalesForecast.Turnovers(
	|				&qForecastPeriodFrom,
	|				&qForecastPeriodTo,
	|				Day,
	|				Hotel IN HIERARCHY (&qHotel)
	|					AND (Customer IN HIERARCHY (&qCustomer)
	|						OR &qIsEmptyCustomer)
	|					AND (ParentDoc.Room IN HIERARCHY (&qRoom)
	|						OR &qIsEmptyRoom)
	|					AND (ParentDoc.RoomType IN HIERARCHY (&qRoomType)
	|						OR &qIsEmptyRoomType)
	|					AND (Service IN (&qServicesList)
	|						OR NOT &qUseServicesList)) AS CustomerSalesForecastTurnovers) AS CustomerSales
	|{WHERE
	|	CustomerSales.ReportingCurrency.*,
	|	CustomerSales.Hotel.*,
	|	CustomerSales.Customer.*,
	|	(SUM(CustomerSales.SalesTurnover)) AS Sales,
	|	(SUM(CustomerSales.RoomRevenueTurnover)) AS RoomRevenue,
	|	(SUM(CustomerSales.SalesWithoutVATTurnover)) AS SalesWithoutVAT,
	|	(SUM(CustomerSales.RoomRevenueWithoutVATTurnover)) AS RoomRevenueWithoutVAT,
	|	(SUM(CustomerSales.CommissionSumTurnover)) AS CommissionSum,
	|	(SUM(CustomerSales.CommissionSumWithoutVATTurnover)) AS CommissionSumWithoutVAT,
	|	(SUM(CustomerSales.DiscountSumTurnover)) AS DiscountSum,
	|	(SUM(CustomerSales.DiscountSumWithoutVATTurnover)) AS DiscountSumWithoutVAT,
	|	(SUM(CustomerSales.RoomsRentedTurnover)) AS RoomsRented,
	|	(SUM(CustomerSales.BedsRentedTurnover)) AS BedsRented,
	|	(SUM(CustomerSales.AdditionalBedsRentedTurnover)) AS AdditionalBedsRented,
	|	(SUM(CustomerSales.GuestDaysTurnover)) AS GuestDays,
	|	(SUM(CustomerSales.GuestsCheckedInTurnover)) AS GuestsCheckedIn,
	|	(SUM(CustomerSales.RoomsCheckedInTurnover)) AS RoomsCheckedIn,
	|	(SUM(CustomerSales.BedsCheckedInTurnover)) AS BedsCheckedIn,
	|	(SUM(CustomerSales.AdditionalBedsCheckedInTurnover)) AS AdditionalBedsCheckedIn,
	|	(0) AS TotalRooms,
	|	(0) AS TotalBeds,
	|	(0) AS TotalRoomsBlocked,
	|	(0) AS TotalBedsBlocked,
	|	(0) AS TotalRoomsRentedPercent,
	|	(0) AS TotalBedsRentedPercent,
	|	(0) AS RoomRevenuePercent,
	|	(0) AS SalesPercent,
	|	(0) AS ADR,
	|	(0) AS ADBR,
	|	(0) AS ADRWithoutVAT,
	|	(0) AS ADBRWithoutVAT,
	|	(0) AS RevPAC,
	|	(0) AS RevPACWithoutVAT,
	|	(0) AS ALS,
	|	(&qEmptyString) AS ABCAnalysisGroup,
	|	(0) AS ABCAnalysisPercent}
	|
	|GROUP BY
	|	CustomerSales.ReportingCurrency,
	|	CustomerSales.Hotel,
	|	CustomerSales.Customer
	|
	|ORDER BY
	|	CustomerSales.ReportingCurrency.SortCode,
	|	CustomerSales.Hotel.SortCode,
	|	CustomerSales.Customer.Description
	|{ORDER BY
	|	ReportingCurrency.*,
	|	Hotel.*,
	|	Customer.*,
	|	ABCAnalysisGroup,
	|	ABCAnalysisPercent,
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
	|	TotalRooms,
	|	TotalBeds,
	|	TotalRoomsBlocked,
	|	TotalBedsBlocked,
	|	TotalRoomsRentedPercent,
	|	TotalBedsRentedPercent,
	|	RoomRevenuePercent,
	|	SalesPercent,
	|	ADR,
	|	ADBR,
	|	ADRWithoutVAT,
	|	ADBRWithoutVAT,
	|	RevPAC,
	|	RevPACWithoutVAT,
	|	ALS}
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
	|	SUM(AdditionalBedsCheckedIn)
	|BY
	|	OVERALL
	|{TOTALS BY
	|	ReportingCurrency.*,
	|	Hotel.*,
	|	Customer.*}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Customer sales percents';RU='Проценты продаж по контрагентам';de='Verkaufsprozente nach Vertragspartnern'");
	
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
	   Or pName = "ADR"
	   Or pName = "ADRWithoutVAT"
	   Or pName = "ADBR"
	   Or pName = "ADBRWithoutVAT"
	   Or pName = "RevPAC"
	   Or pName = "RevPACWithoutVAT"
	   Or pName = "ALS"
	   Or pName = "TotalRooms"
	   Or pName = "TotalBeds"
	   Or pName = "TotalRoomsBlocked"
	   Or pName = "TotalBedsBlocked"
	   Or pName = "TotalRoomsRentedPercent"
	   Or pName = "TotalBedsRentedPercent"
	   Or pName = "RoomRevenuePercent"
	   Or pName = "SalesPercent" Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // pmIsResource

// -----------------------------------------------------------------------------
Function pmGetListOfABCAnalysisResources() Export
	vResources = New ValueList();
	vResources.Add("Sales", NStr("en='Sales';ru='Продажи';de='Verkäufe'"));
	vResources.Add("RoomRevenue", NStr("en='Room revenue';ru='Продажи номеров';de='Zimmerverkäufe'"));
	vResources.Add("SalesWithoutVAT", NStr("en='Sales without VAT';ru='Продажи без НДС';de='Verkäufe ohne MwSt.'"));
	vResources.Add("RoomRevenueWithoutVAT", NStr("en='Room revenue without VAT';ru='Продажи номеров без НДС';de='Zimmerverkäufe ohne MwSt.'"));
	vResources.Add("CommissionSum", NStr("en='Commission sum';ru='Сумма комиссии';de='Summe der Kommission'"));
	vResources.Add("CommissionSumWithoutVAT", NStr("en='Commission sum without VAT';ru='Сумма комиссии без НДС';de='Kommissionssumme ohne MwSt.'"));
	vResources.Add("DiscountSum", NStr("en='Discount sum';ru='Сумма скидок';de='Preisnachlasssumme'"));
	vResources.Add("DiscountSumWithoutVAT", NStr("en='Discount sum without VAT';ru='Сумма скидок без НДС';de='Preisnachlasssumme ohne MwSt.'"));
	vResources.Add("RoomsRented", NStr("en='Rooms rented';ru='Продано номеродней';de='Zimmertage verkauft'"));
	vResources.Add("BedsRented", NStr("en='Beds rented';ru='Продано местодней';de='Verkaufte Betten pro Tag'"));
	vResources.Add("AdditionalBedsRented", NStr("en='Additional beds rented';ru='Продано дополнительных местодней';de='Zusätzliche Betten nach Tagen verkauft'"));
	vResources.Add("GuestDays", NStr("en='Guest days';ru='Продано человеко-дней';de='Personen-Tag verkauft'"));
	vResources.Add("GuestsCheckedIn", NStr("en='Guests checked-in';ru='Заезд гостей';de='Anreise der Gäste'"));
	vResources.Add("RoomsCheckedIn", NStr("en='Rooms checked-in'; ru='Заезд номеров'"));
	vResources.Add("BedsCheckedIn", NStr("en='Beds checked-in'; ru='Заезд мест'"));
	vResources.Add("AdditionalBedsCheckedIn", NStr("en='Additional beds checked-in';ru='Заезд доп. мест';de='Anreise zusätzlicher Betten'"));
	Return vResources;
EndFunction // pmGetListOfABCAnalysisResources 

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Procedure AddMissingPeriods(pTbl)
	If pTbl.Count() > 0 Then
		vLastDayRow = pTbl.Get(0);
		
		vDay = BegOfDay(vLastDayRow.Period);
		While vDay <= BegOfDay(PeriodTo) Do
			vRow = pTbl.Find(vDay, "Period");
			If vRow = Undefined Then
				vRow = pTbl.Add();
				FillPropertyValues(vRow, vLastDayRow);
				vRow.Period = vDay;
			Else
				vLastDayRow = vRow;
			EndIf;
			
			vDay = vDay + 24*3600;
		EndDo;
	EndIf;
EndProcedure // AddMissingPeriods
