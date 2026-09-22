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
	If Not ValueIsFilled(Periodicity) Then
		Periodicity = Enums.PeriodicityTypes.Day;
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
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа услуг '; en = 'Services folder '; en = 'Dienstleistungengruppe '") + 
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
	
	// Take report query text from report builder
	QueryText = ReportBuilder.Text;
	
	// Run query to get available rooms
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
	
	// Run query to get total room blocks that should be added to the number of total rooms rented
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomBlocksBalanceAndTurnovers.Period AS Period,
	|	SUM(RoomBlocksBalanceAndTurnovers.RoomsBlockedClosingBalance) AS SpecRoomsBlocked,
	|	SUM(RoomBlocksBalanceAndTurnovers.BedsBlockedClosingBalance) AS SpecBedsBlocked
	|FROM
	|	AccumulationRegister.RoomBlocks.BalanceAndTurnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			RegisterRecordsAndPeriodBoundaries,
	|			Hotel IN HIERARCHY (&qHotel)
	|				AND (Room IN HIERARCHY (&qRoom)
	|					OR &qIsEmptyRoom)
	|				AND (RoomType IN HIERARCHY (&qRoomType)
	|					OR &qIsEmptyRoomType)
	|				AND RoomBlockType.AddToRoomsRentedInSummaryIndexes) AS RoomBlocksBalanceAndTurnovers
	|
	|GROUP BY
	|	RoomBlocksBalanceAndTurnovers.Period
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
	vTotalSpecBlocks = vQry.Execute().Unload();
	
	AddMissingPeriods(vTotalSpecBlocks);
	
	// Run main query to get data
	vQry = New Query();
	vQry.Text = TrimAll(QueryText);
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qPeriodFrom", PeriodFrom);
	vForecastStartDate = tcOnServer.GetForecastStartDate(Hotel);
	vQry.SetParameter("qForecastPeriodFrom", Max(BegOfDay(PeriodFrom), vForecastStartDate));
	vQry.SetParameter("qPeriodTo", PeriodTo);
	vQry.SetParameter("qForecastPeriodTo", Max(PeriodTo, EndOfDay(vForecastStartDate-24*3600)));
	vQry.SetParameter("qRoom", Room);
	vQry.SetParameter("qIsEmptyRoom", Not ValueIsFilled(Room));
	vQry.SetParameter("qRoomType", RoomType);
	vQry.SetParameter("qIsEmptyRoomType", Not ValueIsFilled(RoomType));
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
	vQry.SetParameter("qHideCorrections", HideCorrections);
	vQry.SetParameter("qEmptyString", "                              ");
	vQry.SetParameter("qEmptyDate", '00010101');
	vResults = vQry.Execute().Unload();
		
	// Recalculate booking window if periodicity is not a day
	vTotalRoomsCheckedIn = 0;
	vTotalBookingWindow = 0;
	For Each vRow In vResults Do
		If vResults.IndexOf(vRow) > 0 Then
			vTotalRoomsCheckedIn = vTotalRoomsCheckedIn + vRow.RoomsCheckedIn;
			vTotalBookingWindow = vTotalBookingWindow + vRow.BookingWindow * vRow.RoomsCheckedIn;
			If ValueIsFilled(Periodicity) And Periodicity <> Enums.PeriodicityTypes.Day Then
				vRow.BookingWindow = vRow.BookingWindow * vRow.RoomsCheckedIn;
			EndIf;
		EndIf;
	EndDo;
	If vResults.Count() > 1 Then
		vRow = vResults.Get(0);
		If vTotalRoomsCheckedIn <> 0 Then
			vRow.BookingWindow = Int(vTotalBookingWindow / vTotalRoomsCheckedIn);
		EndIf;
	EndIf;
	
	// Move period column value to the first day of the current period
	For Each vRow In vResults Do
		If ValueIsFilled(vRow.Period) Then
			If Periodicity = Enums.PeriodicityTypes.Week Then
				vRow.Period = BegOfWeek(vRow.Period);
			ElsIf Periodicity = Enums.PeriodicityTypes.Month Then
				vRow.Period = BegOfMonth(vRow.Period);
			ElsIf Periodicity = Enums.PeriodicityTypes.Quarter Then
				vRow.Period = BegOfQuarter(vRow.Period);
			ElsIf Periodicity = Enums.PeriodicityTypes.Year Then
				vRow.Period = BegOfYear(vRow.Period);
			EndIf;
		EndIf;
	EndDo;
	If ValueIsFilled(Periodicity) Then
		If ValueIsFilled(Hotel) Then
			vResults.GroupBy("Hotel,ReportingCurrency,PerPresentation,Period", GetReportResourcesList());
		Else
			vResults.GroupBy("ReportingCurrency,PerPresentation,Period", GetReportResourcesList());
		EndIf;
	EndIf;
	
	// Move totals row to the last row position
	If vResults.Count() > 0 Then
		vRow = vResults.Get(0);
		If vResults.Count() > 1 Then
			vResults.Move(vRow, vResults.Count() - 1);
		EndIf;
	EndIf;
	
	// For each row in resulting table calculate load percents
	For Each vRow In vResults Do
		vTotalRooms = 0;
		vTotalBeds = 0;
		vTotalRoomsBlocked = 0;
		vTotalBedsBlocked = 0;
		vTotalSpecRoomsBlocked = 0;
		vTotalSpecBedsBlocked = 0;
		If Not ValueIsFilled(vRow.Period) Then
			vTotalRooms = vTotals.Total("TotalRooms");
			vTotalBeds = vTotals.Total("TotalBeds");
			vTotalRoomsBlocked = vTotals.Total("TotalRoomsBlocked");
			vTotalBedsBlocked = vTotals.Total("TotalBedsBlocked");
			
			vTotalSpecRoomsBlocked = vTotalSpecBlocks.Total("SpecRoomsBlocked");
			vTotalSpecBedsBlocked = vTotalSpecBlocks.Total("SpecBedsBlocked");
		Else
			vRowPeriod = vRow.Period;
			
			vPeriodTotals = vTotals.FindRows(New Structure("Period", vRowPeriod));
			vPeriodTotalSpecBlocks = vTotalSpecBlocks.FindRows(New Structure("Period", vRowPeriod));
			
			For Each vTotalsRow In vPeriodTotals Do
				vTotalRooms = vTotalRooms + vTotalsRow.TotalRooms;
				vTotalBeds = vTotalBeds + vTotalsRow.TotalBeds;
				vTotalRoomsBlocked = vTotalRoomsBlocked + vTotalsRow.TotalRoomsBlocked;
				vTotalBedsBlocked = vTotalBedsBlocked + vTotalsRow.TotalBedsBlocked;
			EndDo;
			
			For Each vTotalsSpecBlocksRow In vPeriodTotalSpecBlocks Do
				vTotalSpecRoomsBlocked = vTotalSpecRoomsBlocked + vTotalsSpecBlocksRow.SpecRoomsBlocked;
				vTotalSpecBedsBlocked = vTotalSpecBedsBlocked + vTotalsSpecBlocksRow.SpecBedsBlocked;
			EndDo;
		EndIf;
		vTotalRoomsAvailable = vTotalRooms - vTotalRoomsBlocked + vTotalSpecRoomsBlocked;
		vTotalBedsAvailable = vTotalBeds - vTotalBedsBlocked + vTotalSpecBedsBlocked;
		
		// Fill period resources
		vRow.TotalRooms = vTotalRooms;
		vRow.TotalBeds = vTotalBeds;
		vRow.TotalRoomsBlocked = vTotalRoomsBlocked;
		vRow.TotalBedsBlocked = vTotalBedsBlocked;

		vRow.TotalRoomsRentedPercent = ?(vTotalRooms = 0, 0, 100 * (vRow.RoomsRented + vTotalSpecRoomsBlocked)/vTotalRooms);
		vRow.TotalBedsRentedPercent = ?(vTotalBeds = 0, 0, 100 * (vRow.BedsRented + vTotalSpecBedsBlocked)/vTotalBeds);
		vRow.TotalRoomsRentedWithBlocksPercent = ?(vTotalRoomsAvailable = 0, 0, 100 * (vRow.RoomsRented + vTotalSpecRoomsBlocked)/vTotalRoomsAvailable);
		vRow.TotalBedsRentedWithBlocksPercent = ?(vTotalBedsAvailable = 0, 0, 100 * (vRow.BedsRented + vTotalSpecBedsBlocked)/vTotalBedsAvailable);

		vRow.RoomsRentedWithCommitmentPercent = ?(vTotalRooms = 0, 0, 100 * (vRow.RoomsRented + vRow.CommitmentRooms + vTotalSpecRoomsBlocked)/vTotalRooms);
		vRow.BedsRentedWithCommitmentPercent = ?(vTotalBeds = 0, 0, 100 * (vRow.BedsRented + vRow.CommitmentBeds + vTotalSpecBedsBlocked)/vTotalBeds);

		vRow.RoomsRentedWithBlocksAndCommitmentPercent = ?(vTotalRoomsAvailable = 0, 0, 100 * (vRow.RoomsRented + vRow.CommitmentRooms + vTotalSpecRoomsBlocked)/vTotalRoomsAvailable);
		vRow.BedsRentedWithBlocksAndCommitmentPercent = ?(vTotalBedsAvailable = 0, 0, 100 * (vRow.BedsRented + vRow.CommitmentBeds + vTotalSpecBedsBlocked)/vTotalBedsAvailable);
		
		vRow.RoomsRented = vRow.RoomsRented + vTotalSpecRoomsBlocked;
		vRow.BedsRented = vRow.BedsRented + vTotalSpecBedsBlocked;
		
		vRow.TotalRoomsBlocked = vTotalRoomsBlocked - vTotalSpecRoomsBlocked;
		vRow.TotalBedsBlocked = vTotalBedsBlocked - vTotalSpecBedsBlocked;
		
		vRow.TotalRoomsAvailable = vTotalRoomsAvailable;
		vRow.TotalBedsAvailable = vTotalBedsAvailable;

		vRow.ADR = ?(vRow.RoomsRented = 0, 0, Round(vRow.RoomRevenue/vRow.RoomsRented, 2));
		vRow.ADRWithoutVAT = ?(vRow.RoomsRented = 0, 0, Round(vRow.RoomRevenueWithoutVAT/vRow.RoomsRented, 2));
		vRow.ADBR = ?(vRow.BedsRented = 0, 0, Round(vRow.RoomRevenue/vRow.BedsRented, 2));
		vRow.ADBRWithoutVAT = ?(vRow.BedsRented = 0, 0, Round(vRow.RoomRevenueWithoutVAT/vRow.BedsRented, 2));
		vRow.RevPAR = ?(vTotalRoomsAvailable = 0, 0, Round(vRow.RoomRevenue/vTotalRoomsAvailable, 2));
		vRow.RevPARWithoutVAT = ?(vTotalRoomsAvailable = 0, 0, Round(vRow.RoomRevenueWithoutVAT/vTotalRoomsAvailable, 2));
		vRow.RevPAB = ?(vTotalBedsAvailable = 0, 0, Round(vRow.RoomRevenue/vTotalBedsAvailable, 2));
		vRow.RevPABWithoutVAT = ?(vTotalBedsAvailable = 0, 0, Round(vRow.RoomRevenueWithoutVAT/vTotalBedsAvailable, 2));
		vRow.RevPAC = ?(vRow.GuestDays = 0, 0, Round(vRow.RoomRevenue/vRow.GuestDays, 2));
		vRow.RevPACWithoutVAT = ?(vRow.GuestDays = 0, 0, Round(vRow.RoomRevenueWithoutVAT/vRow.GuestDays, 2));
		vRow.ALS = ?(vRow.GuestsCheckedIn = 0, 0, Round(vRow.GuestDays/vRow.GuestsCheckedIn, 3));
		
		// Fill period presentation
		If ValueIsFilled(vRow.Period) Then
			If ValueIsFilled(Periodicity) Then
				If Periodicity = Enums.PeriodicityTypes.Day Then
					vRow.PerPresentation = Format(vRow.Period, "DF=dd.MM.yyyy");
				ElsIf Periodicity = Enums.PeriodicityTypes.Week Then
					vRow.PerPresentation = PeriodPresentation(BegOfWeek(vRow.Period), EndOfWeek(vRow.Period), cmLocalizationCode());
				ElsIf Periodicity = Enums.PeriodicityTypes.Month Then
					vRow.PerPresentation = PeriodPresentation(BegOfMonth(vRow.Period), EndOfMonth(vRow.Period), cmLocalizationCode());
				ElsIf Periodicity = Enums.PeriodicityTypes.Quarter Then
					vRow.PerPresentation = PeriodPresentation(BegOfQuarter(vRow.Period), EndOfQuarter(vRow.Period), cmLocalizationCode());
				ElsIf Periodicity = Enums.PeriodicityTypes.Year Then
					vRow.PerPresentation = PeriodPresentation(BegOfYear(vRow.Period), EndOfYear(vRow.Period), cmLocalizationCode());
				EndIf;
			Else
				vRow.PerPresentation = Format(vRow.Period, "DF=dd.MM.yyyy");
			EndIf;
		EndIf;
		
		// Recalculate booking window if periodicity is not a day
		If vResults.IndexOf(vRow) < (vResults.Count() - 1) Then
			If ValueIsFilled(Periodicity) And Periodicity <> Enums.PeriodicityTypes.Day Then
				If vRow.RoomsCheckedIn <> 0 Then
					vRow.BookingWindow = Int(vRow.BookingWindow / vRow.RoomsCheckedIn);
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
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
	Try
		ReportBuilder.Put(pSpreadsheet);
	Except
		tcCommonFunctionOnClientServer.TextMessage(cmGetRootErrorDescription(ErrorInfo()), MessageStatus.Attention);
	EndTry;
	//ReportBuilder.Template.Show(); // For debug purpose

	// Add totals caption and appearance to the last report row
	vLastRepRow = pSpreadsheet.Area(pSpreadsheet.TableHeight-2, 2, pSpreadsheet.TableHeight-2, pSpreadsheet.TableWidth);
	vLastRepRow.Font = New Font(pSpreadsheet.Area(pSpreadsheet.TableHeight-2, 2, pSpreadsheet.TableHeight-2, 2).Font, , , True);
	vLastRepRow.BackColor = pSpreadsheet.Area(4, 2, 4, 2).BackColor;
	pSpreadsheet.Area(pSpreadsheet.TableHeight-2, 2, pSpreadsheet.TableHeight-2, 2).Text = NStr("en='Totals';ru='Итог';de='Ergebnis'");
	
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
	|	PeriodDates.Period AS Period,
	|	0 AS TotalRoomsClosingBalance,
	|	0 AS TotalBedsClosingBalance,
	|	0 AS RoomsBlockedClosingBalance,
	|	0 AS BedsBlockedClosingBalance,
	|	PeriodDates.CounterClosingBalance AS CounterClosingBalance
	|INTO PeriodDates
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qPeriodFrom, &qPeriodTo, DAY, RegisterRecordsAndPeriodBoundaries, Hotel IN HIERARCHY (&qHotel)) AS PeriodDates
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SalesByDates.Hotel AS Hotel,
	|	SalesByDates.ReportingCurrency AS ReportingCurrency,
	|	SalesByDates.Period AS Period,
	|	SUM(SalesByDates.SalesTurnover) AS SalesTurnover,
	|	SUM(SalesByDates.RoomRevenueTurnover) AS RoomRevenueTurnover,
	|	SUM(SalesByDates.SalesWithoutVATTurnover) AS SalesWithoutVATTurnover,
	|	SUM(SalesByDates.RoomRevenueWithoutVATTurnover) AS RoomRevenueWithoutVATTurnover,
	|	SUM(SalesByDates.CommissionSumTurnover) AS CommissionSumTurnover,
	|	SUM(SalesByDates.CommissionSumWithoutVATTurnover) AS CommissionSumWithoutVATTurnover,
	|	SUM(SalesByDates.DiscountSumTurnover) AS DiscountSumTurnover,
	|	SUM(SalesByDates.DiscountSumWithoutVATTurnover) AS DiscountSumWithoutVATTurnover,
	|	SUM(SalesByDates.RoomsRentedTurnover) AS RoomsRentedTurnover,
	|	SUM(SalesByDates.BedsRentedTurnover) AS BedsRentedTurnover,
	|	SUM(SalesByDates.AdditionalBedsRentedTurnover) AS AdditionalBedsRentedTurnover,
	|	SUM(SalesByDates.GuestDaysTurnover) AS GuestDaysTurnover,
	|	SUM(SalesByDates.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover,
	|	SUM(SalesByDates.RoomsCheckedInTurnover) AS RoomsCheckedInTurnover,
	|	SUM(SalesByDates.BedsCheckedInTurnover) AS BedsCheckedInTurnover,
	|	SUM(SalesByDates.AdditionalBedsCheckedInTurnover) AS AdditionalBedsCheckedInTurnover,
	|	SUM(SalesByDates.GuestsCheckedOutTurnover) AS GuestsCheckedOutTurnover,
	|	SUM(SalesByDates.RoomsCheckedOutTurnover) AS RoomsCheckedOutTurnover,
	|	SUM(SalesByDates.BedsCheckedOutTurnover) AS BedsCheckedOutTurnover,
	|	SUM(SalesByDates.AdditionalBedsCheckedOutTurnover) AS AdditionalBedsCheckedOutTurnover,
	|	SUM(SalesByDates.QuantityTurnover) AS QuantityTurnover,
	|	CASE
	|		WHEN SUM(SalesByDates.RoomsCheckedInTurnover) <> 0
	|			THEN CAST(SUM(SalesByDates.BookingWindowTurnover) / SUM(SalesByDates.RoomsCheckedInTurnover) AS NUMBER(10, 0))
	|		ELSE 0
	|	END AS BookingWindowTurnover,
	|	SUM(SalesByDates.VATSumTurnover) AS VATSumTurnover
	|INTO SalesByDates
	|FROM
	|	(SELECT
	|		ChargedSales.Hotel AS Hotel,
	|		ChargedSales.ReportingCurrency AS ReportingCurrency,
	|		BEGINOFPERIOD(ChargedSales.Period, DAY) AS Period,
	|		ChargedSales.SalesTurnover AS SalesTurnover,
	|		ChargedSales.RoomRevenueTurnover AS RoomRevenueTurnover,
	|		ChargedSales.SalesWithoutVATTurnover AS SalesWithoutVATTurnover,
	|		ChargedSales.RoomRevenueWithoutVATTurnover AS RoomRevenueWithoutVATTurnover,
	|		ChargedSales.CommissionSumTurnover AS CommissionSumTurnover,
	|		ChargedSales.CommissionSumWithoutVATTurnover AS CommissionSumWithoutVATTurnover,
	|		ChargedSales.DiscountSumTurnover AS DiscountSumTurnover,
	|		ChargedSales.DiscountSumWithoutVATTurnover AS DiscountSumWithoutVATTurnover,
	|		ChargedSales.RoomsRentedTurnover AS RoomsRentedTurnover,
	|		ChargedSales.BedsRentedTurnover AS BedsRentedTurnover,
	|		ChargedSales.AdditionalBedsRentedTurnover AS AdditionalBedsRentedTurnover,
	|		ChargedSales.GuestDaysTurnover AS GuestDaysTurnover,
	|		ChargedSales.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
	|		ChargedSales.RoomsCheckedInTurnover AS RoomsCheckedInTurnover,
	|		ChargedSales.BedsCheckedInTurnover AS BedsCheckedInTurnover,
	|		ChargedSales.AdditionalBedsCheckedInTurnover AS AdditionalBedsCheckedInTurnover,
	|		ChargedSales.QuantityTurnover AS QuantityTurnover,
	|		ChargedSales.BookingWindowTurnover AS BookingWindowTurnover,
	|		ChargedSales.VATSumTurnover AS VATSumTurnover,
	|		0 AS GuestsCheckedOutTurnover,
	|		0 AS RoomsCheckedOutTurnover,
	|		0 AS BedsCheckedOutTurnover,
	|		0 AS AdditionalBedsCheckedOutTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Day,
	|				(&qHideCorrections
	|					OR NOT &qHideCorrections
	|						AND NOT IsCorrection)
	|					AND Hotel IN HIERARCHY (&qHotel)
	|					AND (Room IN HIERARCHY (&qRoom)
	|						OR &qIsEmptyRoom)
	|					AND (RoomType IN HIERARCHY (&qRoomType)
	|						OR &qIsEmptyRoomType)
	|					AND (Service IN HIERARCHY (&qService)
	|						OR &qIsEmptyService)
	|					AND (Service IN (&qServicesList)
	|						OR NOT &qUseServicesList)) AS ChargedSales
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ChargedSales.Hotel,
	|		ChargedSales.ReportingCurrency,
	|		CASE
	|			WHEN DATEADD(ChargedSales.AccountingDate, DAY, 1) = BEGINOFPERIOD(ChargedSales.ParentDoc.CheckOutDate, DAY)
	|					AND BEGINOFPERIOD(ChargedSales.ParentDoc.CheckInDate, DAY) < BEGINOFPERIOD(ChargedSales.ParentDoc.CheckOutDate, DAY)
	|				THEN DATEADD(BEGINOFPERIOD(ChargedSales.Period, DAY), DAY, 1)
	|			WHEN ChargedSales.AccountingDate = BEGINOFPERIOD(ChargedSales.ParentDoc.CheckOutDate, DAY)
	|					AND BEGINOFPERIOD(ChargedSales.ParentDoc.CheckInDate, DAY) = BEGINOFPERIOD(ChargedSales.ParentDoc.CheckOutDate, DAY)
	|					AND BEGINOFPERIOD(ISNULL(ChargedSales.ParentDoc.CheckInDate, &qEmptyDate), DAY) <> &qEmptyDate
	|				THEN BEGINOFPERIOD(ChargedSales.Period, DAY)
	|			ELSE &qEmptyDate
	|		END,
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
	|		CASE
	|			WHEN DATEADD(ChargedSales.AccountingDate, DAY, 1) = BEGINOFPERIOD(ChargedSales.ParentDoc.CheckOutDate, DAY)
	|					AND BEGINOFPERIOD(ChargedSales.ParentDoc.CheckInDate, DAY) < BEGINOFPERIOD(ChargedSales.ParentDoc.CheckOutDate, DAY)
	|				THEN ChargedSales.GuestDaysTurnover
	|			WHEN ChargedSales.AccountingDate = BEGINOFPERIOD(ChargedSales.ParentDoc.CheckOutDate, DAY)
	|					AND BEGINOFPERIOD(ChargedSales.ParentDoc.CheckInDate, DAY) = BEGINOFPERIOD(ChargedSales.ParentDoc.CheckOutDate, DAY)
	|					AND BEGINOFPERIOD(ISNULL(ChargedSales.ParentDoc.CheckInDate, &qEmptyDate), DAY) <> &qEmptyDate
	|				THEN ChargedSales.GuestDaysTurnover
	|			ELSE 0
	|		END,
	|		CASE
	|			WHEN DATEADD(ChargedSales.AccountingDate, DAY, 1) = BEGINOFPERIOD(ChargedSales.ParentDoc.CheckOutDate, DAY)
	|					AND BEGINOFPERIOD(ChargedSales.ParentDoc.CheckInDate, DAY) < BEGINOFPERIOD(ChargedSales.ParentDoc.CheckOutDate, DAY)
	|				THEN ChargedSales.RoomsRentedTurnover
	|			WHEN ChargedSales.AccountingDate = BEGINOFPERIOD(ChargedSales.ParentDoc.CheckOutDate, DAY)
	|					AND BEGINOFPERIOD(ChargedSales.ParentDoc.CheckInDate, DAY) = BEGINOFPERIOD(ChargedSales.ParentDoc.CheckOutDate, DAY)
	|					AND BEGINOFPERIOD(ISNULL(ChargedSales.ParentDoc.CheckInDate, &qEmptyDate), DAY) <> &qEmptyDate
	|				THEN ChargedSales.RoomsRentedTurnover
	|			ELSE 0
	|		END,
	|		CASE
	|			WHEN DATEADD(ChargedSales.AccountingDate, DAY, 1) = BEGINOFPERIOD(ChargedSales.ParentDoc.CheckOutDate, DAY)
	|					AND BEGINOFPERIOD(ChargedSales.ParentDoc.CheckInDate, DAY) < BEGINOFPERIOD(ChargedSales.ParentDoc.CheckOutDate, DAY)
	|				THEN ChargedSales.BedsRentedTurnover
	|			WHEN ChargedSales.AccountingDate = BEGINOFPERIOD(ChargedSales.ParentDoc.CheckOutDate, DAY)
	|					AND BEGINOFPERIOD(ChargedSales.ParentDoc.CheckInDate, DAY) = BEGINOFPERIOD(ChargedSales.ParentDoc.CheckOutDate, DAY)
	|					AND BEGINOFPERIOD(ISNULL(ChargedSales.ParentDoc.CheckInDate, &qEmptyDate), DAY) <> &qEmptyDate
	|				THEN ChargedSales.BedsRentedTurnover
	|			ELSE 0
	|		END,
	|		CASE
	|			WHEN DATEADD(ChargedSales.AccountingDate, DAY, 1) = BEGINOFPERIOD(ChargedSales.ParentDoc.CheckOutDate, DAY)
	|					AND BEGINOFPERIOD(ChargedSales.ParentDoc.CheckInDate, DAY) < BEGINOFPERIOD(ChargedSales.ParentDoc.CheckOutDate, DAY)
	|				THEN ChargedSales.AdditionalBedsRentedTurnover
	|			WHEN ChargedSales.AccountingDate = BEGINOFPERIOD(ChargedSales.ParentDoc.CheckOutDate, DAY)
	|					AND BEGINOFPERIOD(ChargedSales.ParentDoc.CheckInDate, DAY) = BEGINOFPERIOD(ChargedSales.ParentDoc.CheckOutDate, DAY)
	|					AND BEGINOFPERIOD(ISNULL(ChargedSales.ParentDoc.CheckInDate, &qEmptyDate), DAY) <> &qEmptyDate
	|				THEN ChargedSales.AdditionalBedsRentedTurnover
	|			ELSE 0
	|		END
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				DAY,
	|				(&qHideCorrections
	|					OR NOT &qHideCorrections
	|						AND NOT IsCorrection)
	|					AND Hotel IN HIERARCHY (&qHotel)
	|					AND (Room IN HIERARCHY (&qRoom)
	|						OR &qIsEmptyRoom)
	|					AND (RoomType IN HIERARCHY (&qRoomType)
	|						OR &qIsEmptyRoomType)
	|					AND (Service IN HIERARCHY (&qService)
	|						OR &qIsEmptyService)
	|					AND (Service IN (&qServicesList)
	|						OR NOT &qUseServicesList)) AS ChargedSales
	|	WHERE
	|		CASE
	|				WHEN DATEADD(ChargedSales.AccountingDate, DAY, 1) = BEGINOFPERIOD(ChargedSales.ParentDoc.CheckOutDate, DAY)
	|						AND BEGINOFPERIOD(ChargedSales.ParentDoc.CheckInDate, DAY) < BEGINOFPERIOD(ChargedSales.ParentDoc.CheckOutDate, DAY)
	|					THEN DATEADD(BEGINOFPERIOD(ChargedSales.Period, DAY), DAY, 1)
	|				WHEN ChargedSales.AccountingDate = BEGINOFPERIOD(ChargedSales.ParentDoc.CheckOutDate, DAY)
	|						AND BEGINOFPERIOD(ChargedSales.ParentDoc.CheckInDate, DAY) = BEGINOFPERIOD(ChargedSales.ParentDoc.CheckOutDate, DAY)
	|						AND BEGINOFPERIOD(ISNULL(ChargedSales.ParentDoc.CheckInDate, &qEmptyDate), DAY) <> &qEmptyDate
	|					THEN BEGINOFPERIOD(ChargedSales.Period, DAY)
	|				ELSE &qEmptyDate
	|			END <> &qEmptyDate
	|		AND (ChargedSales.GuestDaysTurnover <> 0
	|				OR ChargedSales.RoomsRentedTurnover <> 0
	|				OR ChargedSales.BedsRentedTurnover <> 0
	|				OR ChargedSales.AdditionalBedsRentedTurnover <> 0)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		SalesForecast.Hotel,
	|		SalesForecast.ReportingCurrency,
	|		BEGINOFPERIOD(SalesForecast.Period, DAY),
	|		SalesForecast.SalesTurnover,
	|		SalesForecast.RoomRevenueTurnover,
	|		SalesForecast.SalesWithoutVATTurnover,
	|		SalesForecast.RoomRevenueWithoutVATTurnover,
	|		SalesForecast.CommissionSumTurnover,
	|		SalesForecast.CommissionSumWithoutVATTurnover,
	|		SalesForecast.DiscountSumTurnover,
	|		SalesForecast.DiscountSumWithoutVATTurnover,
	|		SalesForecast.RoomsRentedTurnover,
	|		SalesForecast.BedsRentedTurnover,
	|		SalesForecast.AdditionalBedsRentedTurnover,
	|		SalesForecast.GuestDaysTurnover,
	|		SalesForecast.GuestsCheckedInTurnover,
	|		SalesForecast.RoomsCheckedInTurnover,
	|		SalesForecast.BedsCheckedInTurnover,
	|		SalesForecast.AdditionalBedsCheckedInTurnover,
	|		SalesForecast.QuantityTurnover,
	|		SalesForecast.BookingWindowTurnover,
	|		SalesForecast.VATSumTurnover,
	|		0,
	|		0,
	|		0,
	|		0
	|	FROM
	|		AccumulationRegister.SalesForecast.Turnovers(
	|				&qForecastPeriodFrom,
	|				&qForecastPeriodTo,
	|				Day,
	|				Hotel IN HIERARCHY (&qHotel)
	|					AND (Room IN HIERARCHY (&qRoom)
	|						OR &qIsEmptyRoom)
	|					AND (RoomType IN HIERARCHY (&qRoomType)
	|						OR &qIsEmptyRoomType)
	|					AND (Service IN HIERARCHY (&qService)
	|						OR &qIsEmptyService)
	|					AND (Service IN (&qServicesList)
	|						OR NOT &qUseServicesList)) AS SalesForecast
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		SalesForecast.Hotel,
	|		SalesForecast.ReportingCurrency,
	|		CASE
	|			WHEN DATEADD(SalesForecast.AccountingDate, DAY, 1) = BEGINOFPERIOD(SalesForecast.ParentDoc.CheckOutDate, DAY)
	|					AND BEGINOFPERIOD(SalesForecast.ParentDoc.CheckInDate, DAY) < BEGINOFPERIOD(SalesForecast.ParentDoc.CheckOutDate, DAY)
	|				THEN DATEADD(BEGINOFPERIOD(SalesForecast.Period, DAY), DAY, 1)
	|			WHEN SalesForecast.AccountingDate = BEGINOFPERIOD(SalesForecast.ParentDoc.CheckOutDate, DAY)
	|					AND BEGINOFPERIOD(SalesForecast.ParentDoc.CheckInDate, DAY) = BEGINOFPERIOD(SalesForecast.ParentDoc.CheckOutDate, DAY)
	|					AND BEGINOFPERIOD(ISNULL(SalesForecast.ParentDoc.CheckInDate, &qEmptyDate), DAY) <> &qEmptyDate
	|				THEN BEGINOFPERIOD(SalesForecast.Period, DAY)
	|			ELSE &qEmptyDate
	|		END,
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
	|		CASE
	|			WHEN DATEADD(SalesForecast.AccountingDate, DAY, 1) = BEGINOFPERIOD(SalesForecast.ParentDoc.CheckOutDate, DAY)
	|					AND BEGINOFPERIOD(SalesForecast.ParentDoc.CheckInDate, DAY) < BEGINOFPERIOD(SalesForecast.ParentDoc.CheckOutDate, DAY)
	|				THEN SalesForecast.GuestDaysTurnover
	|			WHEN SalesForecast.AccountingDate = BEGINOFPERIOD(SalesForecast.ParentDoc.CheckOutDate, DAY)
	|					AND BEGINOFPERIOD(SalesForecast.ParentDoc.CheckInDate, DAY) = BEGINOFPERIOD(SalesForecast.ParentDoc.CheckOutDate, DAY)
	|					AND BEGINOFPERIOD(ISNULL(SalesForecast.ParentDoc.CheckInDate, &qEmptyDate), DAY) <> &qEmptyDate
	|				THEN SalesForecast.GuestDaysTurnover
	|			ELSE 0
	|		END,
	|		CASE
	|			WHEN DATEADD(SalesForecast.AccountingDate, DAY, 1) = BEGINOFPERIOD(SalesForecast.ParentDoc.CheckOutDate, DAY)
	|					AND BEGINOFPERIOD(SalesForecast.ParentDoc.CheckInDate, DAY) < BEGINOFPERIOD(SalesForecast.ParentDoc.CheckOutDate, DAY)
	|				THEN SalesForecast.RoomsRentedTurnover
	|			WHEN SalesForecast.AccountingDate = BEGINOFPERIOD(SalesForecast.ParentDoc.CheckOutDate, DAY)
	|					AND BEGINOFPERIOD(SalesForecast.ParentDoc.CheckInDate, DAY) = BEGINOFPERIOD(SalesForecast.ParentDoc.CheckOutDate, DAY)
	|					AND BEGINOFPERIOD(ISNULL(SalesForecast.ParentDoc.CheckInDate, &qEmptyDate), DAY) <> &qEmptyDate
	|				THEN SalesForecast.RoomsRentedTurnover
	|			ELSE 0
	|		END,
	|		CASE
	|			WHEN DATEADD(SalesForecast.AccountingDate, DAY, 1) = BEGINOFPERIOD(SalesForecast.ParentDoc.CheckOutDate, DAY)
	|					AND BEGINOFPERIOD(SalesForecast.ParentDoc.CheckInDate, DAY) < BEGINOFPERIOD(SalesForecast.ParentDoc.CheckOutDate, DAY)
	|				THEN SalesForecast.BedsRentedTurnover
	|			WHEN SalesForecast.AccountingDate = BEGINOFPERIOD(SalesForecast.ParentDoc.CheckOutDate, DAY)
	|					AND BEGINOFPERIOD(SalesForecast.ParentDoc.CheckInDate, DAY) = BEGINOFPERIOD(SalesForecast.ParentDoc.CheckOutDate, DAY)
	|					AND BEGINOFPERIOD(ISNULL(SalesForecast.ParentDoc.CheckInDate, &qEmptyDate), DAY) <> &qEmptyDate
	|				THEN SalesForecast.BedsRentedTurnover
	|			ELSE 0
	|		END,
	|		CASE
	|			WHEN DATEADD(SalesForecast.AccountingDate, DAY, 1) = BEGINOFPERIOD(SalesForecast.ParentDoc.CheckOutDate, DAY)
	|					AND BEGINOFPERIOD(SalesForecast.ParentDoc.CheckInDate, DAY) < BEGINOFPERIOD(SalesForecast.ParentDoc.CheckOutDate, DAY)
	|				THEN SalesForecast.AdditionalBedsRentedTurnover
	|			WHEN SalesForecast.AccountingDate = BEGINOFPERIOD(SalesForecast.ParentDoc.CheckOutDate, DAY)
	|					AND BEGINOFPERIOD(SalesForecast.ParentDoc.CheckInDate, DAY) = BEGINOFPERIOD(SalesForecast.ParentDoc.CheckOutDate, DAY)
	|					AND BEGINOFPERIOD(ISNULL(SalesForecast.ParentDoc.CheckInDate, &qEmptyDate), DAY) <> &qEmptyDate
	|				THEN SalesForecast.AdditionalBedsRentedTurnover
	|			ELSE 0
	|		END
	|	FROM
	|		AccumulationRegister.SalesForecast.Turnovers(
	|				&qForecastPeriodFrom,
	|				&qForecastPeriodTo,
	|				Day,
	|				Hotel IN HIERARCHY (&qHotel)
	|					AND (Room IN HIERARCHY (&qRoom)
	|						OR &qIsEmptyRoom)
	|					AND (RoomType IN HIERARCHY (&qRoomType)
	|						OR &qIsEmptyRoomType)
	|					AND (Service IN HIERARCHY (&qService)
	|						OR &qIsEmptyService)
	|					AND (Service IN (&qServicesList)
	|						OR NOT &qUseServicesList)) AS SalesForecast
	|	WHERE
	|		CASE
	|				WHEN DATEADD(SalesForecast.AccountingDate, DAY, 1) = BEGINOFPERIOD(SalesForecast.ParentDoc.CheckOutDate, DAY)
	|						AND BEGINOFPERIOD(SalesForecast.ParentDoc.CheckInDate, DAY) < BEGINOFPERIOD(SalesForecast.ParentDoc.CheckOutDate, DAY)
	|					THEN DATEADD(BEGINOFPERIOD(SalesForecast.Period, DAY), DAY, 1)
	|				WHEN SalesForecast.AccountingDate = BEGINOFPERIOD(SalesForecast.ParentDoc.CheckOutDate, DAY)
	|						AND BEGINOFPERIOD(SalesForecast.ParentDoc.CheckInDate, DAY) = BEGINOFPERIOD(SalesForecast.ParentDoc.CheckOutDate, DAY)
	|						AND BEGINOFPERIOD(ISNULL(SalesForecast.ParentDoc.CheckInDate, &qEmptyDate), DAY) <> &qEmptyDate
	|					THEN BEGINOFPERIOD(SalesForecast.Period, DAY)
	|				ELSE &qEmptyDate
	|			END <> &qEmptyDate
	|		AND (SalesForecast.GuestDaysTurnover <> 0
	|				OR SalesForecast.RoomsRentedTurnover <> 0
	|				OR SalesForecast.BedsRentedTurnover <> 0
	|				OR SalesForecast.AdditionalBedsRentedTurnover <> 0)) AS SalesByDates
	|
	|GROUP BY
	|	SalesByDates.Hotel,
	|	SalesByDates.ReportingCurrency,
	|	SalesByDates.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ConfirmedBlockSales.Hotel AS Hotel,
	|	ConfirmedBlockSales.Period AS Period,
	|	ISNULL(ConfirmedBlockSales.CounterClosingBalance, 0) AS CounterClosingBalance,
	|	ISNULL(ConfirmedBlockSales.RoomsInQuotaClosingBalance, 0) AS RoomsInQuotaClosingBalance,
	|	ISNULL(ConfirmedBlockSales.BedsInQuotaClosingBalance, 0) AS BedsInQuotaClosingBalance,
	|	-ISNULL(ConfirmedBlockSales.RoomsReservedClosingBalance, 0) AS RoomsReservedClosingBalance,
	|	-ISNULL(ConfirmedBlockSales.BedsReservedClosingBalance, 0) AS BedsReservedClosingBalance,
	|	-ISNULL(ConfirmedBlockSales.InHouseRoomsClosingBalance, 0) AS InHouseRoomsClosingBalance,
	|	-ISNULL(ConfirmedBlockSales.InHouseBedsClosingBalance, 0) AS InHouseBedsClosingBalance,
	|	ISNULL(ConfirmedBlockSales.RoomsRemainsClosingBalance, 0) AS RoomsRemainsClosingBalance,
	|	ISNULL(ConfirmedBlockSales.BedsRemainsClosingBalance, 0) AS BedsRemainsClosingBalance,
	|	ISNULL(ConfirmedBlockSales.RoomsRemainsOpeningBalance, 0) AS RoomsRemainsOpeningBalance,
	|	ISNULL(ConfirmedBlockSales.BedsRemainsOpeningBalance, 0) AS BedsRemainsOpeningBalance
	|INTO ConfirmedBlockSales
	|FROM
	|	AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			RegisterRecordsAndPeriodBoundaries,
	|			Hotel IN HIERARCHY (&qHotel)
	|				AND (Room IN HIERARCHY (&qRoom)
	|					OR &qIsEmptyRoom)
	|				AND (RoomType IN HIERARCHY (&qRoomType)
	|					OR &qIsEmptyRoomType)
	|				AND NOT RoomType.DeletionMark
	|				AND RoomQuota.IsCommitment) AS ConfirmedBlockSales
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NotConfirmedBlockSales.Hotel AS Hotel,
	|	NotConfirmedBlockSales.Period AS Period,
	|	ISNULL(NotConfirmedBlockSales.CounterClosingBalance, 0) AS CounterClosingBalance,
	|	ISNULL(NotConfirmedBlockSales.RoomsInQuotaClosingBalance, 0) AS RoomsInQuotaClosingBalance,
	|	ISNULL(NotConfirmedBlockSales.BedsInQuotaClosingBalance, 0) AS BedsInQuotaClosingBalance,
	|	-ISNULL(NotConfirmedBlockSales.RoomsReservedClosingBalance, 0) AS RoomsReservedClosingBalance,
	|	-ISNULL(NotConfirmedBlockSales.BedsReservedClosingBalance, 0) AS BedsReservedClosingBalance,
	|	-ISNULL(NotConfirmedBlockSales.InHouseRoomsClosingBalance, 0) AS InHouseRoomsClosingBalance,
	|	-ISNULL(NotConfirmedBlockSales.InHouseBedsClosingBalance, 0) AS InHouseBedsClosingBalance,
	|	ISNULL(NotConfirmedBlockSales.RoomsRemainsClosingBalance, 0) AS RoomsRemainsClosingBalance,
	|	ISNULL(NotConfirmedBlockSales.BedsRemainsClosingBalance, 0) AS BedsRemainsClosingBalance,
	|	ISNULL(NotConfirmedBlockSales.RoomsRemainsOpeningBalance, 0) AS RoomsRemainsOpeningBalance,
	|	ISNULL(NotConfirmedBlockSales.BedsRemainsOpeningBalance, 0) AS BedsRemainsOpeningBalance
	|INTO NotConfirmedBlockSales
	|FROM
	|	AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			RegisterRecordsAndPeriodBoundaries,
	|			Hotel IN HIERARCHY (&qHotel)
	|				AND (Room IN HIERARCHY (&qRoom)
	|					OR &qIsEmptyRoom)
	|				AND (RoomType IN HIERARCHY (&qRoomType)
	|					OR &qIsEmptyRoomType)
	|				AND NOT RoomType.DeletionMark
	|				AND RoomQuota.DoWriteOff
	|				AND NOT RoomQuota.IsCommitment) AS NotConfirmedBlockSales
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TentativeGroups.Hotel AS Hotel,
	|	TentativeGroups.Period AS Period,
	|	ISNULL(TentativeGroups.RoomsReservedTurnover, 0) AS TentativeRooms,
	|	ISNULL(TentativeGroups.BedsReservedTurnover, 0) AS TentativeBeds,
	|	ISNULL(TentativeGroups.AdditionalBedsReservedTurnover, 0) AS TentativeAdditionalBeds,
	|	ISNULL(TentativeGroups.GuestsReservedTurnover, 0) AS TentativeGuests
	|INTO TentativeGroups
	|FROM
	|	AccumulationRegister.ExpectedGuestGroups.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			Hotel IN HIERARCHY (&qHotel)
	|				AND (RoomType IN HIERARCHY (&qRoomType)
	|					OR &qIsEmptyRoomType)
	|				AND CASE
	|					WHEN RoomQuota = VALUE(Catalog.RoomQuotas.EmptyRef)
	|						THEN TRUE
	|					WHEN GuestGroup <> VALUE(Catalog.GuestGroups.EmptyRef)
	|						THEN TRUE
	|					WHEN NOT ISNULL(RoomQuota.DoWriteOff, FALSE)
	|						THEN TRUE
	|					ELSE FALSE
	|				END
	|				AND NOT RoomType.DeletionMark) AS TentativeGroups
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomSalesTurnovers.Hotel AS Hotel,
	|	RoomSalesTurnovers.ReportingCurrency AS ReportingCurrency,
	|	RoomSalesTurnovers.Period AS Period,
	|	&qEmptyString AS PerPresentation,
	|	RoomSalesTurnovers.TotalRoomsClosingBalance AS TotalRooms,
	|	RoomSalesTurnovers.TotalBedsClosingBalance AS TotalBeds,
	|	RoomSalesTurnovers.RoomsBlockedClosingBalance AS TotalRoomsBlocked,
	|	RoomSalesTurnovers.BedsBlockedClosingBalance AS TotalBedsBlocked,
	|	RoomSalesTurnovers.SalesTurnover AS Sales,
	|	RoomSalesTurnovers.SalesTurnover - RoomSalesTurnovers.CommissionSumTurnover AS SalesWithoutCommission,
	|	RoomSalesTurnovers.RoomRevenueTurnover AS RoomRevenue,
	|	RoomSalesTurnovers.SalesWithoutVATTurnover AS SalesWithoutVAT,
	|	RoomSalesTurnovers.RoomRevenueWithoutVATTurnover AS RoomRevenueWithoutVAT,
	|	RoomSalesTurnovers.CommissionSumTurnover AS CommissionSum,
	|	RoomSalesTurnovers.CommissionSumWithoutVATTurnover AS CommissionSumWithoutVAT,
	|	RoomSalesTurnovers.DiscountSumTurnover AS DiscountSum,
	|	RoomSalesTurnovers.DiscountSumWithoutVATTurnover AS DiscountSumWithoutVAT,
	|	RoomSalesTurnovers.RoomsRentedTurnover AS RoomsRented,
	|	ISNULL(TentativeGroups.TentativeRooms, 0) AS TentativeRooms,
	|	RoomSalesTurnovers.RoomsRentedTurnover + ISNULL(TentativeGroups.TentativeRooms, 0) AS RoomsRentedWithTentative,
	|	ISNULL(NotConfirmedBlockSales.RoomsRemainsClosingBalance, 0) AS AllotmentRooms,
	|	ISNULL(ConfirmedBlockSales.RoomsRemainsClosingBalance, 0) AS CommitmentRooms,
	|	RoomSalesTurnovers.RoomsRentedTurnover + ISNULL(ConfirmedBlockSales.RoomsRemainsClosingBalance, 0) AS RoomsRentedWithCommitment,
	|	RoomSalesTurnovers.RoomsRentedTurnover + ISNULL(TentativeGroups.TentativeRooms, 0) + ISNULL(ConfirmedBlockSales.RoomsRemainsClosingBalance, 0) AS RoomsRentedWithTentativeAndCommitment,
	|	0 AS RoomsRentedWithCommitmentPercent,
	|	0 AS RoomsRentedWithBlocksAndCommitmentPercent,
	|	RoomSalesTurnovers.BedsRentedTurnover AS BedsRented,
	|	ISNULL(TentativeGroups.TentativeBeds, 0) AS TentativeBeds,
	|	RoomSalesTurnovers.BedsRentedTurnover + ISNULL(TentativeGroups.TentativeBeds, 0) AS BedsRentedWithTentative,
	|	ISNULL(NotConfirmedBlockSales.BedsRemainsClosingBalance, 0) AS AllotmentBeds,
	|	ISNULL(ConfirmedBlockSales.BedsRemainsClosingBalance, 0) AS CommitmentBeds,
	|	RoomSalesTurnovers.BedsRentedTurnover + ISNULL(ConfirmedBlockSales.BedsRemainsClosingBalance, 0) AS BedsRentedWithCommitment,
	|	RoomSalesTurnovers.BedsRentedTurnover + ISNULL(TentativeGroups.TentativeBeds, 0) + ISNULL(ConfirmedBlockSales.BedsRemainsClosingBalance, 0) AS BedsRentedWithTentativeAndCommitment,
	|	0 AS BedsRentedWithCommitmentPercent,
	|	0 AS BedsRentedWithBlocksAndCommitmentPercent,
	|	RoomSalesTurnovers.AdditionalBedsRentedTurnover AS AdditionalBedsRented,
	|	RoomSalesTurnovers.GuestDaysTurnover AS GuestDays,
	|	RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedIn,
	|	RoomSalesTurnovers.RoomsCheckedInTurnover AS RoomsCheckedIn,
	|	RoomSalesTurnovers.BedsCheckedInTurnover AS BedsCheckedIn,
	|	RoomSalesTurnovers.AdditionalBedsCheckedInTurnover AS AdditionalBedsCheckedIn,
	|	RoomSalesTurnovers.GuestsCheckedOutTurnover AS GuestsCheckedOut,
	|	RoomSalesTurnovers.RoomsCheckedOutTurnover AS RoomsCheckedOut,
	|	RoomSalesTurnovers.BedsCheckedOutTurnover AS BedsCheckedOut,
	|	RoomSalesTurnovers.AdditionalBedsCheckedOutTurnover AS AdditionalBedsCheckedOut,
	|	RoomSalesTurnovers.QuantityTurnover AS Quantity,
	|	RoomSalesTurnovers.VATSumTurnover AS VATSum,
	|	RoomSalesTurnovers.BookingWindowTurnover AS BookingWindow,
	|	0 AS ADR,
	|	0 AS ADRWithoutVAT,
	|	0 AS ADBR,
	|	0 AS ADBRWithoutVAT,
	|	0 AS RevPAR,
	|	0 AS RevPARWithoutVAT,
	|	0 AS RevPAB,
	|	0 AS RevPABWithoutVAT,
	|	0 AS RevPAC,
	|	0 AS RevPACWithoutVAT,
	|	0 AS ALS,
	|	0 AS TotalRoomsAvailable,
	|	0 AS TotalBedsAvailable,
	|	0 AS TotalRoomsRentedPercent,
	|	0 AS TotalBedsRentedPercent,
	|	0 AS TotalRoomsRentedWithBlocksPercent,
	|	0 AS TotalBedsRentedWithBlocksPercent
	|INTO RoomSalesTurnovers
	|FROM
	|	(SELECT
	|		PeriodDates.Hotel AS Hotel,
	|		PeriodDates.Period AS Period,
	|		PeriodDates.TotalRoomsClosingBalance AS TotalRoomsClosingBalance,
	|		PeriodDates.TotalBedsClosingBalance AS TotalBedsClosingBalance,
	|		PeriodDates.RoomsBlockedClosingBalance AS RoomsBlockedClosingBalance,
	|		PeriodDates.BedsBlockedClosingBalance AS BedsBlockedClosingBalance,
	|		ISNULL(SalesByDates.ReportingCurrency, PeriodDates.Hotel.ReportingCurrency) AS ReportingCurrency,
	|		ISNULL(SalesByDates.SalesTurnover, 0) AS SalesTurnover,
	|		ISNULL(SalesByDates.RoomRevenueTurnover, 0) AS RoomRevenueTurnover,
	|		ISNULL(SalesByDates.SalesWithoutVATTurnover, 0) AS SalesWithoutVATTurnover,
	|		ISNULL(SalesByDates.RoomRevenueWithoutVATTurnover, 0) AS RoomRevenueWithoutVATTurnover,
	|		ISNULL(SalesByDates.CommissionSumTurnover, 0) AS CommissionSumTurnover,
	|		ISNULL(SalesByDates.CommissionSumWithoutVATTurnover, 0) AS CommissionSumWithoutVATTurnover,
	|		ISNULL(SalesByDates.DiscountSumTurnover, 0) AS DiscountSumTurnover,
	|		ISNULL(SalesByDates.DiscountSumWithoutVATTurnover, 0) AS DiscountSumWithoutVATTurnover,
	|		ISNULL(SalesByDates.RoomsRentedTurnover, 0) AS RoomsRentedTurnover,
	|		ISNULL(SalesByDates.BedsRentedTurnover, 0) AS BedsRentedTurnover,
	|		ISNULL(SalesByDates.AdditionalBedsRentedTurnover, 0) AS AdditionalBedsRentedTurnover,
	|		ISNULL(SalesByDates.GuestDaysTurnover, 0) AS GuestDaysTurnover,
	|		ISNULL(SalesByDates.GuestsCheckedInTurnover, 0) AS GuestsCheckedInTurnover,
	|		ISNULL(SalesByDates.RoomsCheckedInTurnover, 0) AS RoomsCheckedInTurnover,
	|		ISNULL(SalesByDates.BedsCheckedInTurnover, 0) AS BedsCheckedInTurnover,
	|		ISNULL(SalesByDates.AdditionalBedsCheckedInTurnover, 0) AS AdditionalBedsCheckedInTurnover,
	|		ISNULL(SalesByDates.GuestsCheckedOutTurnover, 0) AS GuestsCheckedOutTurnover,
	|		ISNULL(SalesByDates.RoomsCheckedOutTurnover, 0) AS RoomsCheckedOutTurnover,
	|		ISNULL(SalesByDates.BedsCheckedOutTurnover, 0) AS BedsCheckedOutTurnover,
	|		ISNULL(SalesByDates.AdditionalBedsCheckedOutTurnover, 0) AS AdditionalBedsCheckedOutTurnover,
	|		ISNULL(SalesByDates.QuantityTurnover, 0) AS QuantityTurnover,
	|		ISNULL(SalesByDates.BookingWindowTurnover, 0) AS BookingWindowTurnover,
	|		ISNULL(SalesByDates.VATSumTurnover, 0) AS VATSumTurnover
	|	FROM
	|		PeriodDates AS PeriodDates
	|			LEFT JOIN SalesByDates AS SalesByDates
	|			ON PeriodDates.Hotel = SalesByDates.Hotel
	|				AND PeriodDates.Period = SalesByDates.Period) AS RoomSalesTurnovers
	|		LEFT JOIN ConfirmedBlockSales AS ConfirmedBlockSales
	|		ON RoomSalesTurnovers.Hotel = ConfirmedBlockSales.Hotel
	|			AND RoomSalesTurnovers.Period = ConfirmedBlockSales.Period
	|		LEFT JOIN NotConfirmedBlockSales AS NotConfirmedBlockSales
	|		ON RoomSalesTurnovers.Hotel = NotConfirmedBlockSales.Hotel
	|			AND RoomSalesTurnovers.Period = NotConfirmedBlockSales.Period
	|		LEFT JOIN TentativeGroups AS TentativeGroups
	|		ON RoomSalesTurnovers.Hotel = TentativeGroups.Hotel
	|			AND RoomSalesTurnovers.Period = TentativeGroups.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomSalesTurnovers.Hotel AS Hotel,
	|	RoomSalesTurnovers.ReportingCurrency AS ReportingCurrency,
	|	RoomSalesTurnovers.Period AS Period,
	|	RoomSalesTurnovers.PerPresentation AS PerPresentation,
	|	RoomSalesTurnovers.TotalRooms AS TotalRooms,
	|	RoomSalesTurnovers.TotalBeds AS TotalBeds,
	|	RoomSalesTurnovers.TotalRoomsBlocked AS TotalRoomsBlocked,
	|	RoomSalesTurnovers.TotalBedsBlocked AS TotalBedsBlocked,
	|	RoomSalesTurnovers.Sales AS Sales,
	|	RoomSalesTurnovers.SalesWithoutCommission AS SalesWithoutCommission,
	|	RoomSalesTurnovers.RoomRevenue AS RoomRevenue,
	|	RoomSalesTurnovers.SalesWithoutVAT AS SalesWithoutVAT,
	|	RoomSalesTurnovers.RoomRevenueWithoutVAT AS RoomRevenueWithoutVAT,
	|	RoomSalesTurnovers.Sales - RoomSalesTurnovers.RoomRevenue AS ExtraServicesRevenue,
	|	RoomSalesTurnovers.SalesWithoutVAT - RoomSalesTurnovers.RoomRevenueWithoutVAT AS ExtraServicesRevenueWithoutVAT,
	|	RoomSalesTurnovers.CommissionSum AS CommissionSum,
	|	RoomSalesTurnovers.CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|	RoomSalesTurnovers.DiscountSum AS DiscountSum,
	|	RoomSalesTurnovers.DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|	RoomSalesTurnovers.RoomsRented AS RoomsRented,
	|	RoomSalesTurnovers.TentativeRooms AS TentativeRooms,
	|	RoomSalesTurnovers.RoomsRentedWithTentative AS RoomsRentedWithTentative,
	|	RoomSalesTurnovers.AllotmentRooms AS AllotmentRooms,
	|	RoomSalesTurnovers.CommitmentRooms AS CommitmentRooms,
	|	RoomSalesTurnovers.RoomsRentedWithCommitment AS RoomsRentedWithCommitment,
	|	RoomSalesTurnovers.RoomsRentedWithTentativeAndCommitment AS RoomsRentedWithTentativeAndCommitment,
	|	RoomSalesTurnovers.RoomsRentedWithCommitmentPercent AS RoomsRentedWithCommitmentPercent,
	|	RoomSalesTurnovers.RoomsRentedWithBlocksAndCommitmentPercent AS RoomsRentedWithBlocksAndCommitmentPercent,
	|	RoomSalesTurnovers.BedsRented AS BedsRented,
	|	RoomSalesTurnovers.TentativeBeds AS TentativeBeds,
	|	RoomSalesTurnovers.BedsRentedWithTentative AS BedsRentedWithTentative,
	|	RoomSalesTurnovers.AllotmentBeds AS AllotmentBeds,
	|	RoomSalesTurnovers.CommitmentBeds AS CommitmentBeds,
	|	RoomSalesTurnovers.BedsRentedWithCommitment AS BedsRentedWithCommitment,
	|	RoomSalesTurnovers.BedsRentedWithTentativeAndCommitment AS BedsRentedWithTentativeAndCommitment,
	|	RoomSalesTurnovers.BedsRentedWithCommitmentPercent AS BedsRentedWithCommitmentPercent,
	|	RoomSalesTurnovers.BedsRentedWithBlocksAndCommitmentPercent AS BedsRentedWithBlocksAndCommitmentPercent,
	|	RoomSalesTurnovers.AdditionalBedsRented AS AdditionalBedsRented,
	|	RoomSalesTurnovers.GuestDays AS GuestDays,
	|	RoomSalesTurnovers.GuestsCheckedIn AS GuestsCheckedIn,
	|	RoomSalesTurnovers.RoomsCheckedIn AS RoomsCheckedIn,
	|	RoomSalesTurnovers.BedsCheckedIn AS BedsCheckedIn,
	|	RoomSalesTurnovers.AdditionalBedsCheckedIn AS AdditionalBedsCheckedIn,
	|	RoomSalesTurnovers.GuestsCheckedOut AS GuestsCheckedOut,
	|	RoomSalesTurnovers.RoomsCheckedOut AS RoomsCheckedOut,
	|	RoomSalesTurnovers.BedsCheckedOut AS BedsCheckedOut,
	|	RoomSalesTurnovers.AdditionalBedsCheckedOut AS AdditionalBedsCheckedOut,
	|	RoomSalesTurnovers.Quantity AS Quantity,
	|	RoomSalesTurnovers.VATSum AS VATSum,
	|	RoomSalesTurnovers.BookingWindow AS BookingWindow,
	|	RoomSalesTurnovers.ADR AS ADR,
	|	RoomSalesTurnovers.ADRWithoutVAT AS ADRWithoutVAT,
	|	RoomSalesTurnovers.ADBR AS ADBR,
	|	RoomSalesTurnovers.ADBRWithoutVAT AS ADBRWithoutVAT,
	|	RoomSalesTurnovers.RevPAR AS RevPAR,
	|	RoomSalesTurnovers.RevPARWithoutVAT AS RevPARWithoutVAT,
	|	RoomSalesTurnovers.RevPAB AS RevPAB,
	|	RoomSalesTurnovers.RevPABWithoutVAT AS RevPABWithoutVAT,
	|	RoomSalesTurnovers.RevPAC AS RevPAC,
	|	RoomSalesTurnovers.RevPACWithoutVAT AS RevPACWithoutVAT,
	|	RoomSalesTurnovers.ALS AS ALS,
	|	RoomSalesTurnovers.TotalRoomsAvailable AS TotalRoomsAvailable,
	|	RoomSalesTurnovers.TotalBedsAvailable AS TotalBedsAvailable,
	|	RoomSalesTurnovers.TotalRoomsRentedPercent AS TotalRoomsRentedPercent,
	|	RoomSalesTurnovers.TotalBedsRentedPercent AS TotalBedsRentedPercent,
	|	RoomSalesTurnovers.TotalRoomsRentedWithBlocksPercent AS TotalRoomsRentedWithBlocksPercent,
	|	RoomSalesTurnovers.TotalBedsRentedWithBlocksPercent AS TotalBedsRentedWithBlocksPercent
	|{SELECT
	|	ReportingCurrency.*,
	|	Hotel.*,
	|	PerPresentation,
	|	Period,
	|	TotalRooms,
	|	TotalBeds,
	|	TotalRoomsBlocked,
	|	TotalBedsBlocked,
	|	Sales,
	|	SalesWithoutCommission,
	|	RoomRevenue,
	|	SalesWithoutVAT,
	|	RoomRevenueWithoutVAT,
	|	ExtraServicesRevenue,
	|	ExtraServicesRevenueWithoutVAT,
	|	CommissionSum,
	|	CommissionSumWithoutVAT,
	|	DiscountSum,
	|	DiscountSumWithoutVAT,
	|	RoomsRented,
	|	TentativeRooms,
	|	RoomsRentedWithTentative,
	|	CommitmentRooms,
	|	AllotmentRooms,
	|	RoomsRentedWithCommitment,
	|	RoomsRentedWithTentativeAndCommitment,
	|	RoomsRentedWithCommitmentPercent,
	|	RoomsRentedWithBlocksAndCommitmentPercent,
	|	BedsRented,
	|	TentativeBeds,
	|	BedsRentedWithTentative,
	|	CommitmentBeds,
	|	AllotmentBeds,
	|	BedsRentedWithCommitment,
	|	BedsRentedWithTentativeAndCommitment,
	|	BedsRentedWithCommitmentPercent,
	|	BedsRentedWithBlocksAndCommitmentPercent,
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
	|	Quantity,
	|	BookingWindow,
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
	|	TotalRoomsAvailable,
	|	TotalBedsAvailable,
	|	TotalRoomsRentedPercent,
	|	TotalBedsRentedPercent,
	|	TotalRoomsRentedWithBlocksPercent,
	|	TotalBedsRentedWithBlocksPercent,
	|	VATSum}
	|FROM
	|	RoomSalesTurnovers AS RoomSalesTurnovers
	|{WHERE
	|	RoomSalesTurnovers.Hotel.* AS Hotel,
	|	RoomSalesTurnovers.ReportingCurrency.* AS ReportingCurrency,
	|	RoomSalesTurnovers.Period AS Period,
	|	RoomSalesTurnovers.PerPresentation AS PerPresentation,
	|	RoomSalesTurnovers.TotalRooms AS TotalRooms,
	|	RoomSalesTurnovers.TotalBeds AS TotalBeds,
	|	RoomSalesTurnovers.TotalRoomsBlocked AS TotalRoomsBlocked,
	|	RoomSalesTurnovers.TotalBedsBlocked AS TotalBedsBlocked,
	|	RoomSalesTurnovers.Sales AS Sales,
	|	RoomSalesTurnovers.SalesWithoutCommission AS SalesWithoutCommission,
	|	RoomSalesTurnovers.RoomRevenue AS RoomRevenue,
	|	RoomSalesTurnovers.SalesWithoutVAT AS SalesWithoutVAT,
	|	RoomSalesTurnovers.RoomRevenueWithoutVAT AS RoomRevenueWithoutVAT,
	|	(RoomSalesTurnovers.Sales - RoomSalesTurnovers.RoomRevenue) AS ExtraServicesRevenue,
	|	(RoomSalesTurnovers.SalesWithoutVAT - RoomSalesTurnovers.RoomRevenueWithoutVAT) AS ExtraServicesRevenueWithoutVAT,
	|	RoomSalesTurnovers.CommissionSum AS CommissionSum,
	|	RoomSalesTurnovers.CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|	RoomSalesTurnovers.DiscountSum AS DiscountSum,
	|	RoomSalesTurnovers.DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|	RoomSalesTurnovers.RoomsRented AS RoomsRented,
	|	RoomSalesTurnovers.TentativeRooms AS TentativeRooms,
	|	RoomSalesTurnovers.RoomsRentedWithTentative AS RoomsRentedWithTentative,
	|	RoomSalesTurnovers.AllotmentRooms AS AllotmentRooms,
	|	RoomSalesTurnovers.CommitmentRooms AS CommitmentRooms,
	|	RoomSalesTurnovers.RoomsRentedWithCommitment AS RoomsRentedWithCommitment,
	|	RoomSalesTurnovers.RoomsRentedWithTentativeAndCommitment AS RoomsRentedWithTentativeAndCommitment,
	|	RoomSalesTurnovers.RoomsRentedWithCommitmentPercent AS RoomsRentedWithCommitmentPercent,
	|	RoomSalesTurnovers.RoomsRentedWithBlocksAndCommitmentPercent AS RoomsRentedWithBlocksAndCommitmentPercent,
	|	RoomSalesTurnovers.BedsRented AS BedsRented,
	|	RoomSalesTurnovers.TentativeBeds AS TentativeBeds,
	|	RoomSalesTurnovers.BedsRentedWithTentative AS BedsRentedWithTentative,
	|	RoomSalesTurnovers.AllotmentBeds AS AllotmentBeds,
	|	RoomSalesTurnovers.CommitmentBeds AS CommitmentBeds,
	|	RoomSalesTurnovers.BedsRentedWithCommitment AS BedsRentedWithCommitment,
	|	RoomSalesTurnovers.BedsRentedWithTentativeAndCommitment AS BedsRentedWithTentativeAndCommitment,
	|	RoomSalesTurnovers.BedsRentedWithCommitmentPercent AS BedsRentedWithCommitmentPercent,
	|	RoomSalesTurnovers.BedsRentedWithBlocksAndCommitmentPercent AS BedsRentedWithBlocksAndCommitmentPercent,
	|	RoomSalesTurnovers.AdditionalBedsRented AS AdditionalBedsRented,
	|	RoomSalesTurnovers.GuestDays AS GuestDays,
	|	RoomSalesTurnovers.GuestsCheckedIn AS GuestsCheckedIn,
	|	RoomSalesTurnovers.RoomsCheckedIn AS RoomsCheckedIn,
	|	RoomSalesTurnovers.BedsCheckedIn AS BedsCheckedIn,
	|	RoomSalesTurnovers.AdditionalBedsCheckedIn AS AdditionalBedsCheckedIn,
	|	RoomSalesTurnovers.Quantity AS Quantity,
	|	RoomSalesTurnovers.VATSum AS VATSum,
	|	RoomSalesTurnovers.BookingWindow,
	|	RoomSalesTurnovers.ADR AS ADR,
	|	RoomSalesTurnovers.ADRWithoutVAT AS ADRWithoutVAT,
	|	RoomSalesTurnovers.ADBR AS ADBR,
	|	RoomSalesTurnovers.ADBRWithoutVAT AS ADBRWithoutVAT,
	|	RoomSalesTurnovers.RevPAR AS RevPAR,
	|	RoomSalesTurnovers.RevPARWithoutVAT AS RevPARWithoutVAT,
	|	RoomSalesTurnovers.RevPAB AS RevPAB,
	|	RoomSalesTurnovers.RevPABWithoutVAT AS RevPABWithoutVAT,
	|	RoomSalesTurnovers.RevPAC AS RevPAC,
	|	RoomSalesTurnovers.RevPACWithoutVAT AS RevPACWithoutVAT,
	|	RoomSalesTurnovers.ALS AS ALS,
	|	RoomSalesTurnovers.TotalRoomsAvailable AS TotalRoomsAvailable,
	|	RoomSalesTurnovers.TotalBedsAvailable AS TotalBedsAvailable,
	|	RoomSalesTurnovers.TotalRoomsRentedPercent AS TotalRoomsRentedPercent,
	|	RoomSalesTurnovers.TotalBedsRentedPercent AS TotalBedsRentedPercent,
	|	RoomSalesTurnovers.TotalRoomsRentedWithBlocksPercent AS TotalRoomsRentedWithBlocksPercent,
	|	RoomSalesTurnovers.TotalBedsRentedWithBlocksPercent AS TotalBedsRentedWithBlocksPercent}
	|
	|ORDER BY
	|	RoomSalesTurnovers.ReportingCurrency.Description,
	|	RoomSalesTurnovers.Hotel.SortCode,
	|	Period
	|TOTALS
	|	SUM(TotalRooms),
	|	SUM(TotalBeds),
	|	SUM(TotalRoomsBlocked),
	|	SUM(TotalBedsBlocked),
	|	SUM(Sales),
	|	SUM(SalesWithoutCommission),
	|	SUM(RoomRevenue),
	|	SUM(SalesWithoutVAT),
	|	SUM(RoomRevenueWithoutVAT),
	|	SUM(ExtraServicesRevenue),
	|	SUM(ExtraServicesRevenueWithoutVAT),
	|	SUM(CommissionSum),
	|	SUM(CommissionSumWithoutVAT),
	|	SUM(DiscountSum),
	|	SUM(DiscountSumWithoutVAT),
	|	SUM(RoomsRented),
	|	SUM(TentativeRooms),
	|	SUM(RoomsRentedWithTentative),
	|	SUM(AllotmentRooms),
	|	SUM(CommitmentRooms),
	|	SUM(RoomsRentedWithCommitment),
	|	SUM(RoomsRentedWithTentativeAndCommitment),
	|	SUM(BedsRented),
	|	SUM(TentativeBeds),
	|	SUM(BedsRentedWithTentative),
	|	SUM(AllotmentBeds),
	|	SUM(CommitmentBeds),
	|	SUM(BedsRentedWithCommitment),
	|	SUM(BedsRentedWithTentativeAndCommitment),
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
	|	SUM(Quantity),
	|	SUM(VATSum),
	|	CASE
	|		WHEN SUM(RoomsCheckedIn) <> 0
	|			THEN CAST(SUM(RoomSalesTurnovers.BookingWindow) / SUM(RoomsCheckedIn) AS NUMBER(10, 0))
	|		ELSE 0
	|	END AS BookingWindow
	|BY
	|	OVERALL";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Revenue turnovers';RU='Доходность и загрузка';de='Wirtschaftlichkeit und Auslastung'");
	
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
	   Or pName = "ExtraServicesRevenue"
	   Or pName = "ExtraServicesRevenueWithoutVAT"
	   Or pName = "CommissionSum" 
	   Or pName = "CommissionSumWithoutVAT" 
	   Or pName = "DiscountSum" 
	   Or pName = "DiscountSumWithoutVAT" 
	   Or pName = "RoomsRented" 
	   Or pName = "TentativeRooms"
	   Or pName = "RoomsRentedWithTentative"
	   Or pName = "CommitmentRooms"
	   Or pName = "AllotmentRooms"
	   Or pName = "RoomsRentedWithCommitment"
	   Or pName = "RoomsRentedWithTentativeAndCommitment"
	   Or pName = "RoomsRentedWithCommitmentPercent"
	   Or pName = "RoomsRentedWithBlocksAndCommitmentPercent"
	   Or pName = "BedsRented" 
	   Or pName = "TentativeBeds"
	   Or pName = "BedsRentedWithTentative"
	   Or pName = "CommitmentBeds"
	   Or pName = "AllotmentBeds"
	   Or pName = "BedsRentedWithCommitment"
	   Or pName = "BedsRentedWithTentativeAndCommitment"
	   Or pName = "BedsRentedWithCommitmentPercent"
	   Or pName = "BedsRentedWithBlocksAndCommitmentPercent"
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
	   Or pName = "TotalRooms"
	   Or pName = "TotalBeds"
	   Or pName = "TotalRoomsBlocked"
	   Or pName = "TotalBedsBlocked"
	   Or pName = "TotalRoomsAvailable"
	   Or pName = "TotalBedsAvailable"
	   Or pName = "TotalRoomsRentedPercent"
	   Or pName = "TotalBedsRentedPercent"
	   Or pName = "TotalRoomsRentedWithBlocksPercent"
	   Or pName = "TotalBedsRentedWithBlocksPercent" 
	   Or pName = "BookingWindow" Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // pmIsResource

// -----------------------------------------------------------------------------
Function GetReportResourcesList()
	vResources = "Sales,SalesWithoutCommission,RoomRevenue,SalesWithoutVAT,RoomRevenueWithoutVAT,ExtraServicesRevenue,ExtraServicesRevenueWithoutVAT,CommissionSum,CommissionSumWithoutVAT,Quantity," +
	             "DiscountSum,DiscountSumWithoutVAT,RoomsRented,BedsRented,AdditionalBedsRented," + 
	             "GuestDays,GuestsCheckedIn,RoomsCheckedIn,BedsCheckedIn,AdditionalBedsCheckedIn,GuestsCheckedOut,RoomsCheckedOut,BedsCheckedOut,AdditionalBedsCheckedOut,BookingWindow,ADR,ADRWithoutVAT,ADBR,ADBRWithoutVAT," + 
	             "RevPAR,RevPARWithoutVAT,RevPAB,RevPABWithoutVAT,RevPAC,RevPACWithoutVAT,ALS," + 
	             "TotalRooms,TotalBeds,TotalRoomsBlocked,TotalBedsBlocked,TotalRoomsAvailable,TotalBedsAvailable," + 
	             "TotalRoomsRentedPercent,TotalBedsRentedPercent,TotalRoomsRentedWithBlocksPercent,TotalBedsRentedWithBlocksPercent," +
	             "TentativeRooms,RoomsRentedWithTentative,CommitmentRooms,AllotmentRooms,RoomsRentedWithCommitment,RoomsRentedWithTentativeAndCommitment,RoomsRentedWithCommitmentPercent,RoomsRentedWithBlocksAndCommitmentPercent," + 
	             "TentativeBeds,BedsRentedWithTentative,CommitmentBeds,AllotmentBeds,BedsRentedWithCommitment,BedsRentedWithTentativeAndCommitment,BedsRentedWithCommitmentPercent,BedsRentedWithBlocksAndCommitmentPercent";
	Return vResources;
EndFunction // GetReportResourcesList

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Procedure AddMissingPeriods(pTbl)
	// Add missing days to the table
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
	
	// Convert periods to report periodicity
	If ValueIsFilled(Periodicity) And Periodicity <> Enums.PeriodicityTypes.Day Then
		For Each vRow In pTbl Do
			If ValueIsFilled(vRow.Period) Then
				If Periodicity = Enums.PeriodicityTypes.Week Then
					vRow.Period = BegOfWeek(vRow.Period);
				ElsIf Periodicity = Enums.PeriodicityTypes.Month Then
					vRow.Period = BegOfMonth(vRow.Period);
				ElsIf Periodicity = Enums.PeriodicityTypes.Quarter Then
					vRow.Period = BegOfQuarter(vRow.Period);
				ElsIf Periodicity = Enums.PeriodicityTypes.Year Then
					vRow.Period = BegOfYear(vRow.Period);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // AddMissingPeriods
