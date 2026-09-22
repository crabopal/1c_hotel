
#Region Variables

Var TotalPerDay;
Var TotalPerMonth;
Var TotalPerYear;
Var TotalPerDayLY;
Var TotalPerMonthLY;
Var TotalPerYearLY;

#EndRegion  

#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pGenerateOnly	 - Boolean - Generate only
//
Procedure pmSaveReportAttributes(pGenerateOnly = False) Export
	cmSaveReportAttributes(ThisObject, , pGenerateOnly);
EndProcedure // pmSaveReportAttributes

// -----------------------------------------------------------------------------
//
// Parameters:
//  pParameter	 - Any - Parameter for set
//
Procedure pmLoadReportAttributes(pParameter = Undefined) Export
	cmLoadReportAttributes(ThisObject, pParameter);
EndProcedure // pmLoadReportAttributes

// -----------------------------------------------------------------------------
//  Initialize attributes with default values
//  Attention: This procedure could be called AFTER some attributes initialization
//  routine, so it SHOULD NOT reset attributes being set before
//
Procedure pmFillAttributesWithDefaultValues() Export
	// Fill parameters with default values
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(Hotel) Then
		ShowAmountsWithoutVAT = Not Hotel.ShowSalesInReportsWithVAT;
	EndIf;
	If Not ValueIsFilled(PeriodTo) Then
		PeriodTo = BegOfDay(CurrentSessionDate());
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// 
// Returns:
//  String - Report parameters presentation
//
Function pmGetReportParametersPresentation() Export
	vParamPresentation = "";
	If Not ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("en='Report period is not set';ru='Период отчета не установлен';de='Berichtszeitraum nicht festgelegt'") + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("ru = 'Дата '; en = 'Date '; de = 'Datum '") 
												+ Format(PeriodTo, "DF='dd.MM.yyyy'") 
												+ ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(Hotel) Then
		If Not Hotel.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Hotel ';ru='Гостиница ';de='Hotel '") 
													+ Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) 
													+ ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Hotels folder ';ru='Группа гостиниц ';de='Hotelsgruppe '") 
													+ Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) 
													+ ";" + Chars.LF;
		EndIf;
	EndIf;
	If ShowAmountsWithoutVAT Then
		vParamPresentation = vParamPresentation + NStr("en = 'All amounts without VAT'; de = 'Alle Summe ohne MwSt.'; ru = 'Все суммы без НДС'");
	Else
		vParamPresentation = vParamPresentation + NStr("en = 'All amounts with VAT'; de = 'Alle Summe enthalten MwSt.'; ru = 'Все суммы включают НДС'");
	EndIf;
	If DoNotShowForecast Then
		vParamPresentation = vParamPresentation + Chars.LF + NStr("en = 'No forecast'; de = 'Keine Prognose'; ru = 'Без прогноза'");
	EndIf;
	Return vParamPresentation;
EndFunction // pmGetReportParametersPresentation

// -----------------------------------------------------------------------------
//
// Parameters:
//  pDate	 - Date - date
// 
// Returns:
//  Date - beg of year
//
Function pmBegOfYear(pDate) Export 
	vYear = 365 * 24 * 3600;
	If UseSlidingPeriod Then
		Return BegOfDay(pDate) - vYear;
	Else
		Return BegOfYear(pDate);
	EndIf;
EndFunction // pmBegOfYear

// -----------------------------------------------------------------------------
//
// Parameters:
//  pDate	 - Date - date 
// 
// Returns:
//  Date - beg of month 
//
Function pmBegOfMonth(pDate) Export   
	vMonth = 30 * 24 * 3600; 
	If UseSlidingPeriod Then
		Return BegOfDay(pDate) - vMonth;
	Else
		Return BegOfMonth(pDate);
	EndIf;
EndFunction // pmBegOfYear

// -----------------------------------------------------------------------------
//
// Parameters:
//  pSpreadsheet - Spreadsheet - Spreadsheet
//
Procedure pmGenerate(pSpreadsheet) Export
	vForecastStartDate = tcOnServer.GetForecastStartDate(Hotel);
	vHotelList = New Array;
	If ValueIsFilled(Hotel) And Not Hotel.IsFolder Then
		vHotelList.Add(Hotel);
	Else
		vQry = New Query("SELECT
		                 |	Hotels.Ref AS Ref
		                 |FROM
		                 |	Catalog.Hotels AS Hotels
		                 |WHERE
		                 |	NOT Hotels.IsFolder
		                 |	AND NOT Hotels.DeletionMark
		                 |	AND Hotels.Ref IN HIERARCHY(&qHotel)
		                 |
		                 |ORDER BY
		                 |	Hotels.SortCode");
		vQry.SetParameter("qHotel", Hotel);
		vHotelList = vQry.Execute().Unload().UnloadColumn("Ref");
	EndIf;
	If vHotelList.Count() > 1 Then
		vTemplate = ThisObject.GetTemplate("ReportWithPreviousYearByHotels");
	Else
		If ShowPreviousYearData Then
			vTemplate = ThisObject.GetTemplate("ReportWithPreviousYear");
		Else
			vTemplate = ThisObject.GetTemplate("Report");
		EndIf;
	EndIf;
	
	// Report header
	vHeader = vTemplate.GetArea("Header");
	vHotelDesc = ?(ValueIsFilled(Hotel), TrimAll(Hotel), Nstr("en = 'For all'; de = 'Für alle'; ru = 'По всем'"));
	// Fill header parameters
	vHeader.Parameters.mReportName = NStr("en='Summary indexes';ru='Сводные показатели';de='Gesamtindikatoren'") + " - " + CurrentSessionDate() + ", " + TrimAll(SessionParameters.CurrentWorkstation) + ", " + TrimAll(SessionParameters.CurrentUser);
	vHeader.Parameters.mFilter = NStr("en='Filter:';ru='Отбор:';de='Auswahl:'") + Chars.LF 
							   + NStr("ru = 'Период '; en = 'Period '") + Format(PeriodTo, "DF='dd.MM.yyyy'") + ";" + Chars.LF 
							   + NStr("en='Hotel ';ru='Гостиница ';de='Hotel'") + vHotelDesc + ";";
	// Put header
	pSpreadsheet.Put(vHeader);
	
	If vHotelList.Count() > 1 Then
		FillReportByHotels(vHotelList, pSpreadsheet, vTemplate);
	Else
		vHotel = vHotelList.Get(0);
		
		// Put table header
		If UseSlidingPeriod Then
			vArea = vTemplate.GetArea("TableSlidingHeader");
		Else
			vArea = vTemplate.GetArea("TableHeader");
		EndIf;
		vArea.Parameters.mDate = Format(PeriodTo, "DF=dd.MM.yy");
		vArea.Parameters.mMonthPeriod = Format(pmBegOfMonth(PeriodTo), "DF=dd.MM.yy") + " - " + Format(PeriodTo, "DF=dd.MM.yy");
		vArea.Parameters.mYearPeriod = Format(pmBegOfYear(PeriodTo), "DF=dd.MM.yy") + " - " + Format(PeriodTo, "DF=dd.MM.yy");
		If ShowPreviousYearData Then
			vPeriodToLY = AddMonth(PeriodTo, -12);
			vArea.Parameters.mDateLY = Format(vPeriodToLY, "DF=dd.MM.yy");
			vArea.Parameters.mMonthPeriodLY = Format(pmBegOfMonth(vPeriodToLY), "DF=dd.MM.yy") + " - " + Format(vPeriodToLY, "DF=dd.MM.yy");
			vArea.Parameters.mYearPeriodLY = Format(pmBegOfYear(vPeriodToLY), "DF=dd.MM.yy") + " - " + Format(vPeriodToLY, "DF=dd.MM.yy");
		EndIf;
		pSpreadsheet.Put(vArea);
		
		// Set type of output - in rooms or in beds and with VAT or without
		vInRooms = True;
		vWithVAT = True;
		If ValueIsFilled(vHotel) Then
			vInRooms = Not vHotel.ShowReportsInBeds;
			vWithVAT = Not ShowAmountsWithoutVAT;
		EndIf;
		
		// 1. Occupation summary indexes
		
		// Put section header
		vArea = vTemplate.GetArea("OccupationHeader");
		pSpreadsheet.Put(vArea);
		
		// Run query to get total number of rooms, rooms blocked, vacant number of rooms
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	RoomInventoryBalanceAndTurnovers.Period AS Period,
		|	SUM(RoomInventoryBalanceAndTurnovers.CounterClosingBalance) AS CounterClosingBalance,
		|	SUM(RoomInventoryBalanceAndTurnovers.TotalRoomsClosingBalance) AS TotalRoomsClosingBalance,
		|	SUM(RoomInventoryBalanceAndTurnovers.TotalBedsClosingBalance) AS TotalBedsClosingBalance,
		|	SUM(-RoomInventoryBalanceAndTurnovers.RoomsBlockedClosingBalance) AS RoomsBlockedClosingBalance,
		|	SUM(-RoomInventoryBalanceAndTurnovers.BedsBlockedClosingBalance) AS BedsBlockedClosingBalance,
		|	SUM(-RoomInventoryBalanceAndTurnovers.InHouseRoomsClosingBalance - RoomInventoryBalanceAndTurnovers.RoomsReservedClosingBalance) AS RoomsOccupiedClosingBalance,
		|	SUM(-RoomInventoryBalanceAndTurnovers.InHouseBedsClosingBalance - RoomInventoryBalanceAndTurnovers.BedsReservedClosingBalance) AS BedsOccupiedClosingBalance
		|FROM
		|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qPeriodFrom, &qPeriodTo, Day, RegisterRecordsAndPeriodBoundaries, Hotel IN HIERARCHY (&qHotel)) AS RoomInventoryBalanceAndTurnovers
		|
		|GROUP BY
		|	RoomInventoryBalanceAndTurnovers.Period,
		|	RoomInventoryBalanceAndTurnovers.InHouseRoomsClosingBalance,
		|	RoomInventoryBalanceAndTurnovers.RoomsReservedClosingBalance
		|
		|ORDER BY
		|	Period";
		vQry.SetParameter("qPeriodFrom", pmBegOfYear(PeriodTo));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qHotel", vHotel);
		vQryResult = vQry.Execute().Unload();
		
		vResources = "TotalRoomsClosingBalance, TotalBedsClosingBalance, RoomsBlockedClosingBalance, BedsBlockedClosingBalance, RoomsOccupiedClosingBalance, BedsOccupiedClosingBalance";
		GetQryResultTableTotals(vQryResult, vQryResult, vResources);
		
		PeriodToLY = AddMonth(PeriodTo, -12);
		
		If ShowPreviousYearData Then
			// Run query to get total number of rooms, rooms blocked, vacant number of rooms
			vQryLY = New Query();
			vQryLY.Text = 
			"SELECT
			|	RoomInventoryBalanceAndTurnovers.Period AS Period,
			|	SUM(RoomInventoryBalanceAndTurnovers.CounterClosingBalance) AS CounterClosingBalance,
			|	SUM(RoomInventoryBalanceAndTurnovers.TotalRoomsClosingBalance) AS TotalRoomsClosingBalance,
			|	SUM(RoomInventoryBalanceAndTurnovers.TotalBedsClosingBalance) AS TotalBedsClosingBalance,
			|	SUM(-RoomInventoryBalanceAndTurnovers.RoomsBlockedClosingBalance) AS RoomsBlockedClosingBalance,
			|	SUM(-RoomInventoryBalanceAndTurnovers.BedsBlockedClosingBalance) AS BedsBlockedClosingBalance,
			|	SUM(-RoomInventoryBalanceAndTurnovers.InHouseRoomsClosingBalance - RoomInventoryBalanceAndTurnovers.RoomsReservedClosingBalance) AS RoomsOccupiedClosingBalance,
			|	SUM(-RoomInventoryBalanceAndTurnovers.InHouseBedsClosingBalance - RoomInventoryBalanceAndTurnovers.BedsReservedClosingBalance) AS BedsOccupiedClosingBalance
			|FROM
			|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qPeriodFrom, &qPeriodTo, Day, RegisterRecordsAndPeriodBoundaries, Hotel IN HIERARCHY (&qHotel)) AS RoomInventoryBalanceAndTurnovers
			|
			|GROUP BY
			|	RoomInventoryBalanceAndTurnovers.Period
			|
			|ORDER BY
			|	Period";
			vQryLY.SetParameter("qPeriodFrom", pmBegOfYear(PeriodToLY));
			vQryLY.SetParameter("qPeriodTo", EndOfDay(PeriodToLY));
			vQryLY.SetParameter("qHotel", vHotel);
			vQryResultLY = vQryLY.Execute().Unload();
			
			GetQryResultTableTotalsLY(vQryResultLY, vQryResultLY, vResources);
		EndIf;
		
		// Put total rooms
		vTotalRooms = cmCastToNumber(TotalPerDay.TotalRoomsClosingBalance);
		vRoomsBlocked =  cmCastToNumber(TotalPerDay.RoomsBlockedClosingBalance);
		vRoomsForSale = vTotalRooms - vRoomsBlocked;
		vTotalBeds = cmCastToNumber(TotalPerDay.TotalBedsClosingBalance);
		vBedsBlocked = cmCastToNumber(TotalPerDay.BedsBlockedClosingBalance);
		vBedsForSale = vTotalBeds - vBedsBlocked;
		vOccupiedRooms = cmCastToNumber(TotalPerDay.RoomsOccupiedClosingBalance);
		vOccupiedBeds = cmCastToNumber(TotalPerDay.BedsOccupiedClosingBalance);
		
		vTotalRoomsPerMonth = cmCastToNumber(TotalPerMonth.TotalRoomsClosingBalance);
		vRoomsBlockedPerMonth = cmCastToNumber(TotalPerMonth.RoomsBlockedClosingBalance);
		vRoomsForSalePerMonth = vTotalRoomsPerMonth - vRoomsBlockedPerMonth;
		vTotalBedsPerMonth = cmCastToNumber(TotalPerMonth.TotalBedsClosingBalance);
		vBedsBlockedPerMonth = cmCastToNumber(TotalPerMonth.BedsBlockedClosingBalance);
		vBedsForSalePerMonth = vTotalBedsPerMonth - vBedsBlockedPerMonth;
		vOccupiedRoomsPerMonth = cmCastToNumber(TotalPerMonth.RoomsOccupiedClosingBalance);
		vOccupiedBedsPerMonth = cmCastToNumber(TotalPerMonth.BedsOccupiedClosingBalance);
		
		vTotalRoomsPerYear = cmCastToNumber(TotalPerYear.TotalRoomsClosingBalance);
		vRoomsBlockedPerYear = cmCastToNumber(TotalPerYear.RoomsBlockedClosingBalance);
		vRoomsForSalePerYear = vTotalRoomsPerYear - vRoomsBlockedPerYear;
		vTotalBedsPerYear = cmCastToNumber(TotalPerYear.TotalBedsClosingBalance);
		vBedsBlockedPerYear = cmCastToNumber(TotalPerYear.BedsBlockedClosingBalance);
		vBedsForSalePerYear = vTotalBedsPerYear - vBedsBlockedPerYear;
		vOccupiedRoomsPerYear = cmCastToNumber(TotalPerYear.RoomsOccupiedClosingBalance);
		vOccupiedBedsPerYear = cmCastToNumber(TotalPerYear.BedsOccupiedClosingBalance);
		
		vTotalRoomsLY = 0;
		vTotalRoomsPerMonthLY = 0;
		vTotalRoomsPerYearLY = 0;
		vTotalBedsLY = 0;
		vTotalBedsPerMonthLY = 0;
		vTotalBedsPerYearLY = 0;

		vOccupiedRoomsLY = 0;
		vOccupiedRoomsPerMonthLY = 0;
		vOccupiedRoomsPerYearLY = 0;
		vOccupiedBedsLY = 0;
		vOccupiedBedsPerMonthLY = 0;
		vOccupiedBedsPerYearLY = 0;

		vRoomsBlockedLY = 0;
		vRoomsBlockedPerMonthLY = 0;
		vRoomsBlockedPerYearLY = 0;
		vBedsBlockedLY = 0;
		vBedsBlockedPerMonthLY = 0;
		vBedsBlockedPerYearLY = 0;
		
		If ShowPreviousYearData Then
			vTotalRoomsLY = cmCastToNumber(TotalPerDayLY.TotalRoomsClosingBalance);
			vTotalRoomsPerMonthLY = cmCastToNumber(TotalPerMonthLY.TotalRoomsClosingBalance);
			vTotalRoomsPerYearLY = cmCastToNumber(TotalPerYearLY.TotalRoomsClosingBalance);

			vOccupiedRoomsLY = cmCastToNumber(TotalPerDayLY.RoomsOccupiedClosingBalance);
			vOccupiedRoomsPerMonthLY = cmCastToNumber(TotalPerMonthLY.RoomsOccupiedClosingBalance);
			vOccupiedRoomsPerYearLY = cmCastToNumber(TotalPerYearLY.RoomsOccupiedClosingBalance);

			vRoomsBlockedLY = cmCastToNumber(TotalPerDayLY.RoomsBlockedClosingBalance);
			vRoomsBlockedPerMonthLY = cmCastToNumber(TotalPerMonthLY.RoomsBlockedClosingBalance);
			vRoomsBlockedPerYearLY = cmCastToNumber(TotalPerYearLY.RoomsBlockedClosingBalance);
			
			vTotalBedsLY = cmCastToNumber(TotalPerDayLY.TotalBedsClosingBalance);
			vTotalBedsPerMonthLY = cmCastToNumber(TotalPerMonthLY.TotalBedsClosingBalance);
			vTotalBedsPerYearLY = cmCastToNumber(TotalPerYearLY.TotalBedsClosingBalance);

			vOccupiedBedsLY = cmCastToNumber(TotalPerDayLY.BedsOccupiedClosingBalance);
			vOccupiedBedsPerMonthLY = cmCastToNumber(TotalPerMonthLY.BedsOccupiedClosingBalance);
			vOccupiedBedsPerYearLY = cmCastToNumber(TotalPerYearLY.BedsOccupiedClosingBalance);

			vBedsBlockedLY = cmCastToNumber(TotalPerDayLY.BedsBlockedClosingBalance);
			vBedsBlockedPerMonthLY = cmCastToNumber(TotalPerMonthLY.BedsBlockedClosingBalance);
			vBedsBlockedPerYearLY = cmCastToNumber(TotalPerYearLY.BedsBlockedClosingBalance);
		EndIf;
		
		If vInRooms Then
			vArea = vTemplate.GetArea("TotalRooms");
			vArea.Parameters.mTotalRooms = vTotalRooms;
			vArea.Parameters.mTotalRoomsPerMonth = vTotalRoomsPerMonth;
			vArea.Parameters.mTotalRoomsPerYear = vTotalRoomsPerYear;
			vArea.Parameters.mTotalRooms = vTotalRooms;
			vArea.Parameters.mTotalRoomsPerMonth = vTotalRoomsPerMonth;
			vArea.Parameters.mTotalRoomsPerYear = vTotalRoomsPerYear;
			If ShowPreviousYearData Then
				vArea.Parameters.mTotalRoomsLY = cmCastToNumber(TotalPerDayLY.TotalRoomsClosingBalance);
				vArea.Parameters.mTotalRoomsPerMonthLY = cmCastToNumber(TotalPerMonthLY.TotalRoomsClosingBalance);
				vArea.Parameters.mTotalRoomsPerYearLY = cmCastToNumber(TotalPerYearLY.TotalRoomsClosingBalance);
			EndIf;
			pSpreadsheet.Put(vArea);
		Else
			vArea = vTemplate.GetArea("TotalBeds");
			vArea.Parameters.mTotalBeds = vTotalBeds;
			vArea.Parameters.mTotalBedsPerMonth = vTotalBedsPerMonth;
			vArea.Parameters.mTotalBedsPerYear = vTotalBedsPerYear;
			If ShowPreviousYearData Then
				vArea.Parameters.mTotalBedsLY = cmCastToNumber(TotalPerDayLY.TotalBedsClosingBalance);
				vArea.Parameters.mTotalBedsPerMonthLY = cmCastToNumber(TotalPerMonthLY.TotalBedsClosingBalance);
				vArea.Parameters.mTotalBedsPerYearLY = cmCastToNumber(TotalPerYearLY.TotalBedsClosingBalance);
			EndIf;
			pSpreadsheet.Put(vArea);
		EndIf;

		vRoomsVacant = vTotalRooms - vOccupiedRooms;
		vRoomsVacantPerMonth = vTotalRoomsPerMonth - vOccupiedRoomsPerMonth;
		vRoomsVacantPerYear = vTotalRoomsPerYear - vOccupiedRoomsPerYear;

		vBedsVacant = vTotalBeds - vOccupiedBeds;
		vBedsVacantPerMonth = vTotalBedsPerMonth - vOccupiedBedsPerMonth;
		vBedsVacantPerYear = vTotalBedsPerYear - vOccupiedBedsPerYear;

		vRoomsVacantLY = 0;
		vRoomsVacantPerMonthLY = 0;
		vRoomsVacantPerYearLY = 0;

		vBedsVacantLY = 0;
		vBedsVacantPerMonthLY = 0;
		vBedsVacantPerYearLY = 0;

		If ShowPreviousYearData Then
			vRoomsVacantLY = vTotalRoomsLY - vOccupiedRoomsLY;
			vRoomsVacantPerMonthLY = vTotalRoomsPerMonthLY - vOccupiedRoomsPerMonthLY;
			vRoomsVacantPerYearLY = vTotalRoomsPerYearLY - vOccupiedRoomsPerYearLY;

			vBedsVacantLY = vTotalBedsLY - vOccupiedBedsLY;
			vBedsVacantPerMonthLY = vTotalBedsPerMonthLY - vOccupiedBedsPerMonthLY;
			vBedsVacantPerYearLY = vTotalBedsPerYearLY - vOccupiedBedsPerYearLY;
		EndIf;
		
		// Put rooms occupied
		If ShowRoomsOccupiedPercent Then
			If vInRooms Then
				vArea = vTemplate.GetArea("RoomsOccupancy");
				
				vArea.Parameters.mRoomsOccupied = vOccupiedRooms;
				vArea.Parameters.mRoomsOccupiedPerMonth = vOccupiedRoomsPerMonth;
				vArea.Parameters.mRoomsOccupiedPerYear = vOccupiedRoomsPerYear;

				vArea.Parameters.mRoomsVacant = vRoomsVacant;
				vArea.Parameters.mRoomsVacantPerMonth = vRoomsVacantPerMonth;
				vArea.Parameters.mRoomsVacantPerYear = vRoomsVacantPerYear;
				
				If ShowPreviousYearData Then
					vArea.Parameters.mRoomsOccupiedLY = vOccupiedRoomsLY;
					vArea.Parameters.mRoomsOccupiedPerMonthLY = vOccupiedRoomsPerMonthLY;
					vArea.Parameters.mRoomsOccupiedPerYearLY = vOccupiedRoomsPerYearLY;

					vArea.Parameters.mRoomsVacantLY = vRoomsVacantLY;
					vArea.Parameters.mRoomsVacantPerMonthLY = vRoomsVacantPerMonthLY;
					vArea.Parameters.mRoomsVacantPerYearLY = vRoomsVacantPerYearLY;
				EndIf;
				
				vArea.Parameters.mRoomsOccupancyPercent = Round(?(vTotalRooms <> 0, 100 * vOccupiedRooms / vTotalRooms, 0), 2);
				vArea.Parameters.mRoomsOccupancyPercentPerMonth = Round(?(vTotalRoomsPerMonth <> 0, 100 * vOccupiedRoomsPerMonth / vTotalRoomsPerMonth, 0), 2);
				vArea.Parameters.mRoomsOccupancyPercentPerYear = Round(?(vTotalRoomsPerYear <> 0, 100 * vOccupiedRoomsPerYear / vTotalRoomsPerYear, 0), 2);
				
				If ShowPreviousYearData Then
					vArea.Parameters.mRoomsOccupancyPercentLY = Round(?(vTotalRoomsLY <> 0, 100 * vOccupiedRoomsLY / vTotalRoomsLY, 0), 2);
					vArea.Parameters.mRoomsOccupancyPercentPerMonthLY = Round(?(vTotalRoomsPerMonthLY <> 0, 100 * vOccupiedRoomsPerMonthLY / vTotalRoomsPerMonthLY, 0), 2);
					vArea.Parameters.mRoomsOccupancyPercentPerYearLY = Round(?(vTotalRoomsPerYearLY <> 0, 100 * vOccupiedRoomsPerYearLY / vTotalRoomsPerYearLY, 0), 2);
				EndIf;
				
				pSpreadsheet.Put(vArea);
			Else
				vArea = vTemplate.GetArea("BedsOccupancy");

				vArea.Parameters.mBedsOccupied = vOccupiedBeds;
				vArea.Parameters.mBedsOccupiedPerMonth = vOccupiedBedsPerMonth;
				vArea.Parameters.mBedsOccupiedPerYear = vOccupiedBedsPerYear;

				vArea.Parameters.mBedsVacant = vBedsVacant;
				vArea.Parameters.mBedsVacantPerMonth = vBedsVacantPerMonth;
				vArea.Parameters.mBedsVacantPerYear = vBedsVacantPerYear;
				
				If ShowPreviousYearData Then
					vArea.Parameters.mBedsOccupiedLY = vOccupiedBedsLY;
					vArea.Parameters.mBedsOccupiedPerMonthLY = vOccupiedBedsPerMonthLY;
					vArea.Parameters.mBedsOccupiedPerYearLY = vOccupiedBedsPerYearLY;

					vArea.Parameters.mBedsVacantLY = vBedsVacantLY;
					vArea.Parameters.mBedsVacantPerMonthLY = vBedsVacantPerMonthLY;
					vArea.Parameters.mBedsVacantPerYearLY = vBedsVacantPerYearLY;
				EndIf;
				
				vArea.Parameters.mBedsOccupancyPercent = Round(?(vTotalBeds <> 0, 100 * vOccupiedBeds / vTotalBeds, 0), 2);
				vArea.Parameters.mBedsOccupancyPercentPerMonth = Round(?(vTotalBedsPerMonth <> 0, 100 * vOccupiedBedsPerMonth / vTotalBedsPerMonth, 0), 2);
				vArea.Parameters.mBedsOccupancyPercentPerYear = Round(?(vTotalBedsPerYear <> 0, 100 * vOccupiedBedsPerYear / vTotalBedsPerYear, 0), 2);
				
				If ShowPreviousYearData Then
					vArea.Parameters.mBedsOccupancyPercentLY = Round(?(vTotalBedsLY <> 0, 100 * vOccupiedBedsLY / vTotalBedsLY, 0), 2);
					vArea.Parameters.mBedsOccupancyPercentPerMonthLY = Round(?(vTotalBedsPerMonthLY <> 0, 100 * vOccupiedBedsPerMonthLY / vTotalBedsPerMonthLY, 0), 2);
					vArea.Parameters.mBedsOccupancyPercentPerYearLY = Round(?(vTotalBedsPerYearLY <> 0, 100 * vOccupiedBedsPerYearLY / vTotalBedsPerYearLY, 0), 2);
				EndIf;
				
				pSpreadsheet.Put(vArea);
			EndIf;
		EndIf;
		
		//
		// Room blocks
		//
		
		vSpecRoomsBlocked = 0;
		vSpecBedsBlocked = 0;
		vSpecRoomsBlockedPerMonth = 0;
		vSpecBedsBlockedPerMonth = 0;
		vSpecRoomsBlockedPerYear = 0;
		vSpecBedsBlockedPerYear = 0;
		
		If ShowRoomsOccupiedPercent Then
	 		vRoomsVacantMinusBlocks = vRoomsVacant - vRoomsBlocked;
			vRoomsVacantMinusBlocksPerMonth = vRoomsVacantPerMonth - vRoomsBlockedPerMonth;
			vRoomsVacantMinusBlocksPerYear = vRoomsVacantPerYear - vRoomsBlockedPerYear;

			vBedsVacantMinusBlocks = vBedsVacant - vBedsBlocked;
			vBedsVacantMinusBlocksPerMonth = vBedsVacantPerMonth - vBedsBlockedPerMonth;
			vBedsVacantMinusBlocksPerYear = vBedsVacantPerYear - vBedsBlockedPerYear;

			If ShowPreviousYearData Then
				vRoomsVacantMinusBlocksLY = vRoomsVacantLY - vRoomsBlockedLY;
				vRoomsVacantMinusBlocksPerMonthLY = vRoomsVacantPerMonthLY - vRoomsBlockedPerMonthLY;
				vRoomsVacantMinusBlocksPerYearLY = vRoomsVacantPerYearLY - vRoomsBlockedPerYearLY;

				vBedsVacantMinusBlocksLY = vBedsVacantLY - vBedsBlockedLY;
				vBedsVacantMinusBlocksPerMonthLY = vBedsVacantPerMonthLY - vBedsBlockedPerMonthLY;
				vBedsVacantMinusBlocksPerYearLY = vBedsVacantPerYearLY - vBedsBlockedPerYearLY;
			EndIf;
		EndIf;
		
		If ShowPreviousYearData Then
			vRoomsForSaleLY = vTotalRoomsLY - vRoomsBlockedLY;
			vBedsForSaleLY = vTotalBedsLY - vBedsBlockedLY;
			vOccupiedRoomsLY = cmCastToNumber(TotalPerDayLY.RoomsOccupiedClosingBalance);
			vOccupiedBedsLY = cmCastToNumber(TotalPerDayLY.BedsOccupiedClosingBalance);
			
			vRoomsForSalePerMonthLY = vTotalRoomsPerMonthLY - vRoomsBlockedPerMonthLY;
			vBedsForSalePerMonthLY = vTotalBedsPerMonthLY - vBedsBlockedPerMonthLY;
			vOccupiedRoomsPerMonthLY = cmCastToNumber(TotalPerMonthLY.RoomsOccupiedClosingBalance);
			vOccupiedBedsPerMonthLY = cmCastToNumber(TotalPerMonthLY.BedsOccupiedClosingBalance);
			
			vRoomsForSalePerYearLY = vTotalRoomsPerYearLY - vRoomsBlockedPerYearLY;
			vBedsForSalePerYearLY = vTotalBedsPerYearLY - vBedsBlockedPerYearLY;
			vOccupiedRoomsPerYearLY = cmCastToNumber(TotalPerYearLY.RoomsOccupiedClosingBalance);
			vOccupiedBedsPerYearLY = cmCastToNumber(TotalPerYearLY.BedsOccupiedClosingBalance);
			
			vSpecRoomsBlockedLY = 0;
			vSpecBedsBlockedLY = 0;
			vSpecRoomsBlockedPerMonthLY = 0;
			vSpecBedsBlockedPerMonthLY = 0;
			vSpecRoomsBlockedPerYearLY = 0;
			vSpecBedsBlockedPerYearLY = 0;
		EndIf;
		
		// Run query to get number of blocked rooms per room block types
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	RoomBlocksBalanceAndTurnovers.RoomBlockType AS RoomBlockType,
		|	RoomBlocksBalanceAndTurnovers.Period AS Period,
		|	SUM(RoomBlocksBalanceAndTurnovers.RoomsBlockedClosingBalance) AS RoomsBlockedClosingBalance,
		|	SUM(RoomBlocksBalanceAndTurnovers.BedsBlockedClosingBalance) AS BedsBlockedClosingBalance
		|FROM
		|	AccumulationRegister.RoomBlocks.BalanceAndTurnovers(&qPeriodFrom, &qPeriodTo, Day, RegisterRecordsAndPeriodBoundaries, Hotel IN HIERARCHY (&qHotel)) AS RoomBlocksBalanceAndTurnovers
		|
		|GROUP BY
		|	RoomBlocksBalanceAndTurnovers.RoomBlockType,
		|	RoomBlocksBalanceAndTurnovers.Period
		|
		|ORDER BY
		|	RoomBlocksBalanceAndTurnovers.RoomBlockType.SortCode,
		|	Period";
		vQry.SetParameter("qPeriodFrom", pmBegOfYear(PeriodTo));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qHotel", vHotel);
		vQryResult = vQry.Execute().Unload();
		
		// Get list of room block types
		vRoomBlockTypes = vQryResult.Copy();
		vRoomBlockTypes.GroupBy("RoomBlockType", );
		
		If ShowPreviousYearData Then
			// Run query to get number of blocked rooms per room block types
			vQryLY = New Query();
			vQryLY.Text = 
			"SELECT
			|	RoomBlocksBalanceAndTurnovers.RoomBlockType AS RoomBlockType,
			|	RoomBlocksBalanceAndTurnovers.Period AS Period,
			|	SUM(RoomBlocksBalanceAndTurnovers.RoomsBlockedClosingBalance) AS RoomsBlockedClosingBalance,
			|	SUM(RoomBlocksBalanceAndTurnovers.BedsBlockedClosingBalance) AS BedsBlockedClosingBalance
			|FROM
			|	AccumulationRegister.RoomBlocks.BalanceAndTurnovers(&qPeriodFrom, &qPeriodTo, Day, RegisterRecordsAndPeriodBoundaries, Hotel IN HIERARCHY (&qHotel)) AS RoomBlocksBalanceAndTurnovers
			|
			|GROUP BY
			|	RoomBlocksBalanceAndTurnovers.RoomBlockType,
			|	RoomBlocksBalanceAndTurnovers.Period
			|
			|ORDER BY
			|	RoomBlocksBalanceAndTurnovers.RoomBlockType.SortCode,
			|	Period";
			vQryLY.SetParameter("qPeriodFrom", pmBegOfYear(PeriodToLY));
			vQryLY.SetParameter("qPeriodTo", EndOfDay(PeriodToLY));
			vQryLY.SetParameter("qHotel", vHotel);
			vQryResultLY = vQryLY.Execute().Unload();
			
			// Get list of room block types
			vRoomBlockTypesLY = vQryResultLY.Copy();
			vRoomBlockTypesLY.GroupBy("RoomBlockType", );
			
			// Add last year room block types to the current year ones
			For Each vRBTRowLY In vRoomBlockTypesLY Do
				If vRoomBlockTypes.Find(vRBTRowLY.RoomBlockType, "RoomBlockType") = Undefined Then
					vRBTRow = vRoomBlockTypes.Add();
					vRBTRow.RoomBlockType = vRBTRowLY.RoomBlockType;
					vQRRow = vQryResult.Add();
					vQRRow.RoomBlockType = vRBTRowLY.RoomBlockType;
				EndIf;
			EndDo;
			For Each vRBTRow In vRoomBlockTypes Do
				If vRoomBlockTypesLY.Find(vRBTRow.RoomBlockType, "RoomBlockType") = Undefined Then
					vRBTRowLY = vRoomBlockTypesLY.Add();
					vRBTRowLY.RoomBlockType = vRBTRow.RoomBlockType;
					vQRRowLY = vQryResultLY.Add();
					vQRRowLY.RoomBlockType = vRBTRow.RoomBlockType;
				EndIf;
			EndDo;
		EndIf;
		
		vArea = vTemplate.GetArea("RoomBlocks");
		pSpreadsheet.Put(vArea);
		
		// Put room blocks per room block type
		For Each vRow In vRoomBlockTypes Do
			vRoomBlockType = vRow.RoomBlockType;
			
			// Get records for the current room block type only
			vQrySubresult = vQryResult.FindRows(New Structure("RoomBlockType", vRoomBlockType));
			GetQryResultTableTotals(vQrySubresult, vQryResult, "RoomsBlockedClosingBalance, BedsBlockedClosingBalance");
			
			If ShowPreviousYearData Then
				// Try to find row for the same block type in the previous year data
				vRowLY = vRoomBlockTypesLY.Find(vRoomBlockType, "RoomBlockType");
				
				// Get records for the current room block type only
				vQrySubresultLY = vQryResultLY.FindRows(New Structure("RoomBlockType", vRoomBlockType));
				GetQryResultTableTotalsLY(vQrySubresultLY, vQryResultLY, "RoomsBlockedClosingBalance, BedsBlockedClosingBalance");
			EndIf;
			
			If vInRooms Then
				vArea = vTemplate.GetArea("RoomBlockTypeRooms");
				vArea.Parameters.mRoomBlockType = vRoomBlockType;
				vArea.Parameters.mRoomsBlocked = cmCastToNumber(TotalPerDay.RoomsBlockedClosingBalance);
				vArea.Parameters.mRoomsBlockedPerMonth = cmCastToNumber(TotalPerMonth.RoomsBlockedClosingBalance);
				vArea.Parameters.mRoomsBlockedPerYear = cmCastToNumber(TotalPerYear.RoomsBlockedClosingBalance);
				If ShowPreviousYearData Then
					vArea.Parameters.mRoomsBlockedLY = cmCastToNumber(TotalPerDayLY.RoomsBlockedClosingBalance);
					vArea.Parameters.mRoomsBlockedPerMonthLY = cmCastToNumber(TotalPerMonthLY.RoomsBlockedClosingBalance);
					vArea.Parameters.mRoomsBlockedPerYearLY = cmCastToNumber(TotalPerYearLY.RoomsBlockedClosingBalance);
				EndIf;
				
				If ShowPreviousYearData Then
					If vArea.Parameters.mRoomsBlocked <> 0 
						Or vArea.Parameters.mRoomsBlockedPerMonth <> 0 
						Or vArea.Parameters.mRoomsBlockedPerYear 
						Or vArea.Parameters.mRoomsBlockedLY <> 0 
						Or vArea.Parameters.mRoomsBlockedPerMonthLY <> 0 
						Or vArea.Parameters.mRoomsBlockedPerYearLY Then 
						pSpreadsheet.Put(vArea);
					EndIf;
				Else
					If vArea.Parameters.mRoomsBlocked <> 0 
						Or vArea.Parameters.mRoomsBlockedPerMonth <> 0 
						Or vArea.Parameters.mRoomsBlockedPerYear Then
						pSpreadsheet.Put(vArea);
					EndIf;
				EndIf;
				
				If vRoomBlockType.AddToRoomsRentedInSummaryIndexes Then
					vSpecRoomsBlocked = vSpecRoomsBlocked + cmCastToNumber(TotalPerDay.RoomsBlockedClosingBalance);
					vSpecRoomsBlockedPerMonth = vSpecRoomsBlockedPerMonth + cmCastToNumber(TotalPerMonth.RoomsBlockedClosingBalance);
					vSpecRoomsBlockedPerYear = vSpecRoomsBlockedPerYear + cmCastToNumber(TotalPerYear.RoomsBlockedClosingBalance);
					If ShowPreviousYearData Then
						vSpecRoomsBlockedLY = vSpecRoomsBlockedLY + cmCastToNumber(TotalPerDayLY.RoomsBlockedClosingBalance);
						vSpecRoomsBlockedPerMonthLY = vSpecRoomsBlockedPerMonthLY + cmCastToNumber(TotalPerMonthLY.RoomsBlockedClosingBalance);
						vSpecRoomsBlockedPerYearLY = vSpecRoomsBlockedPerYearLY + cmCastToNumber(TotalPerYearLY.RoomsBlockedClosingBalance);
					EndIf;
				EndIf;
			Else
				vArea = vTemplate.GetArea("RoomBlockTypeBeds");
				vArea.Parameters.mRoomBlockType = vRoomBlockType;
				vArea.Parameters.mBedsBlocked = cmCastToNumber(TotalPerDay.BedsBlockedClosingBalance);
				vArea.Parameters.mBedsBlockedPerMonth = cmCastToNumber(TotalPerMonth.BedsBlockedClosingBalance);
				vArea.Parameters.mBedsBlockedPerYear = cmCastToNumber(TotalPerYear.BedsBlockedClosingBalance);
				If ShowPreviousYearData Then
					vArea.Parameters.mBedsBlockedLY = cmCastToNumber(TotalPerDayLY.BedsBlockedClosingBalance);
					vArea.Parameters.mBedsBlockedPerMonthLY = cmCastToNumber(TotalPerMonthLY.BedsBlockedClosingBalance);
					vArea.Parameters.mBedsBlockedPerYearLY = cmCastToNumber(TotalPerYearLY.BedsBlockedClosingBalance);
				EndIf;

				vBedsBlocked = vBedsBlocked + cmCastToNumber(TotalPerDay.BedsBlockedClosingBalance);
				vBedsBlockedPerMonth = vBedsBlockedPerMonth + cmCastToNumber(TotalPerMonth.BedsBlockedClosingBalance);
				vBedsBlockedPerYear = vBedsBlockedPerYear + cmCastToNumber(TotalPerYear.BedsBlockedClosingBalance);
				If ShowPreviousYearData Then
					vBedsBlockedLY = vBedsBlockedLY + cmCastToNumber(TotalPerDayLY.BedsBlockedClosingBalance);
					vBedsBlockedPerMonthLY = vBedsBlockedPerMonthLY + cmCastToNumber(TotalPerMonthLY.BedsBlockedClosingBalance);
					vBedsBlockedPerYearLY = vBedsBlockedPerYearLY + cmCastToNumber(TotalPerYearLY.BedsBlockedClosingBalance);
				EndIf;
				
				If ShowPreviousYearData Then
					If vArea.Parameters.mBedsBlocked <> 0 
						Or vArea.Parameters.mBedsBlockedPerMonth <> 0 
						Or vArea.Parameters.mBedsBlockedPerYear 
						Or vArea.Parameters.mBedsBlockedLY <> 0 
						Or vArea.Parameters.mBedsBlockedPerMonthLY <> 0 
						Or vArea.Parameters.mBedsBlockedPerYearLY Then
						pSpreadsheet.Put(vArea);
					EndIf;
				Else
					If vArea.Parameters.mBedsBlocked <> 0 
						Or vArea.Parameters.mBedsBlockedPerMonth <> 0 
						Or vArea.Parameters.mBedsBlockedPerYear Then
						pSpreadsheet.Put(vArea);
					EndIf;
				EndIf;
				
				If vRoomBlockType.AddToRoomsRentedInSummaryIndexes Then
					vSpecBedsBlocked = vSpecBedsBlocked + cmCastToNumber(TotalPerDay.BedsBlockedClosingBalance);
					vSpecBedsBlockedPerMonth = vSpecBedsBlockedPerMonth + cmCastToNumber(TotalPerMonth.BedsBlockedClosingBalance);
					vSpecBedsBlockedPerYear = vSpecBedsBlockedPerYear + cmCastToNumber(TotalPerYear.BedsBlockedClosingBalance);
					If ShowPreviousYearData Then
						vSpecBedsBlockedLY = vSpecBedsBlockedLY + cmCastToNumber(TotalPerDayLY.BedsBlockedClosingBalance);
						vSpecBedsBlockedPerMonthLY = vSpecBedsBlockedPerMonthLY + cmCastToNumber(TotalPerMonthLY.BedsBlockedClosingBalance);
						vSpecBedsBlockedPerYearLY = vSpecBedsBlockedPerYearLY + cmCastToNumber(TotalPerYearLY.BedsBlockedClosingBalance);
					EndIf;
				EndIf;
			EndIf;
		EndDo;
		
		// Put rooms for sale
		If vInRooms Then
			vArea = vTemplate.GetArea("RoomsForSale");
			vArea.Parameters.mRoomsForSale = vRoomsForSale + vSpecRoomsBlocked;
			vArea.Parameters.mRoomsForSalePerMonth = vRoomsForSalePerMonth + vSpecRoomsBlockedPerMonth;
			vArea.Parameters.mRoomsForSalePerYear = vRoomsForSalePerYear + vSpecRoomsBlockedPerYear;
			If ShowPreviousYearData Then
				vArea.Parameters.mRoomsForSaleLY = vRoomsForSaleLY + vSpecRoomsBlockedLY;
				vArea.Parameters.mRoomsForSalePerMonthLY = vRoomsForSalePerMonthLY + vSpecRoomsBlockedPerMonthLY;
				vArea.Parameters.mRoomsForSalePerYearLY = vRoomsForSalePerYearLY + vSpecRoomsBlockedPerYearLY;
			EndIf;
			pSpreadsheet.Put(vArea);
		Else
			vArea = vTemplate.GetArea("BedsForSale");
			vArea.Parameters.mBedsForSale = vBedsForSale + vSpecBedsBlocked;
			vArea.Parameters.mBedsForSalePerMonth = vBedsForSalePerMonth + vSpecBedsBlockedPerMonth;
			vArea.Parameters.mBedsForSalePerYear = vBedsForSalePerYear + vSpecBedsBlockedPerYear;
			If ShowPreviousYearData Then
				vArea.Parameters.mBedsForSaleLY = vBedsForSaleLY + vSpecBedsBlockedLY;
				vArea.Parameters.mBedsForSalePerMonthLY = vBedsForSalePerMonthLY + vSpecBedsBlockedPerMonthLY;
				vArea.Parameters.mBedsForSalePerYearLY = vBedsForSalePerYearLY + vSpecBedsBlockedPerYearLY;
			EndIf;
			pSpreadsheet.Put(vArea);
		EndIf;
		
		// Run query to get room sales
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	RoomSalesTurnovers.Period AS Period,
		|	RoomSalesTurnovers.RoomRate.IsComplimentary AS RoomRateIsComplimentary,
		|	RoomSalesTurnovers.RoomRate.IsHouseUse AS RoomRateIsHouseUse,
		|	SUM(RoomSalesTurnovers.SalesTurnover) AS SalesTurnover,
		|	SUM(RoomSalesTurnovers.SalesWithoutVATTurnover) AS SalesWithoutVATTurnover,
		|	SUM(RoomSalesTurnovers.RoomRevenueTurnover) AS RoomRevenueTurnover,
		|	SUM(RoomSalesTurnovers.RoomRevenueWithoutVATTurnover) AS RoomRevenueWithoutVATTurnover,
		|	SUM(RoomSalesTurnovers.RoomsRentedTurnover) AS RoomsRentedTurnover,
		|	SUM(RoomSalesTurnovers.BedsRentedTurnover) AS BedsRentedTurnover
		|FROM
		|	AccumulationRegister.Sales.Turnovers(
		|			&qPeriodFrom,
		|			&qPeriodTo,
		|			Day,
		|			NOT IsCorrection
		|				AND Hotel IN HIERARCHY (&qHotel)) AS RoomSalesTurnovers
		|
		|GROUP BY
		|	RoomSalesTurnovers.Period,
		|	RoomSalesTurnovers.RoomRate.IsComplimentary,
		|	RoomSalesTurnovers.RoomRate.IsHouseUse
		|
		|ORDER BY
		|	Period,
		|	RoomRateIsComplimentary,
		|	RoomRateIsHouseUse";
		vQry.SetParameter("qPeriodFrom", pmBegOfYear(PeriodTo));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qHotel", vHotel);
		vQryResult = vQry.Execute().Unload();
		
		If ShowPreviousYearData Then
			vQryLY = New Query();
			vQryLY.Text = 
			"SELECT
			|	RoomSalesTurnovers.Period AS Period,
			|	RoomSalesTurnovers.RoomRate.IsComplimentary AS RoomRateIsComplimentary,
			|	RoomSalesTurnovers.RoomRate.IsHouseUse AS RoomRateIsHouseUse,
			|	SUM(RoomSalesTurnovers.SalesTurnover) AS SalesTurnover,
			|	SUM(RoomSalesTurnovers.SalesWithoutVATTurnover) AS SalesWithoutVATTurnover,
			|	SUM(RoomSalesTurnovers.RoomRevenueTurnover) AS RoomRevenueTurnover,
			|	SUM(RoomSalesTurnovers.RoomRevenueWithoutVATTurnover) AS RoomRevenueWithoutVATTurnover,
			|	SUM(RoomSalesTurnovers.RoomsRentedTurnover) AS RoomsRentedTurnover,
			|	SUM(RoomSalesTurnovers.BedsRentedTurnover) AS BedsRentedTurnover
			|FROM
			|	AccumulationRegister.Sales.Turnovers(
			|			&qPeriodFrom,
			|			&qPeriodTo,
			|			Day,
			|			NOT IsCorrection
			|				AND Hotel IN HIERARCHY (&qHotel)) AS RoomSalesTurnovers
			|
			|GROUP BY
			|	RoomSalesTurnovers.Period,
			|	RoomSalesTurnovers.RoomRate.IsComplimentary,
			|	RoomSalesTurnovers.RoomRate.IsHouseUse
			|
			|ORDER BY
			|	Period,
			|	RoomRateIsComplimentary,
			|	RoomRateIsHouseUse";
			vQryLY.SetParameter("qPeriodFrom", pmBegOfYear(PeriodToLY));
			vQryLY.SetParameter("qPeriodTo", EndOfDay(PeriodToLY));
			vQryLY.SetParameter("qHotel", vHotel);
			vQryResultLY = vQryLY.Execute().Unload();
		EndIf;
		
		// Add forecast sales if period is set in the future
		If BegOfDay(PeriodTo) >= vForecastStartDate And Not DoNotShowForecast Then
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	RoomSalesForecastTurnovers.Period AS Period,
			|	RoomSalesForecastTurnovers.RoomRate.IsComplimentary AS RoomRateIsComplimentary,
			|	RoomSalesForecastTurnovers.RoomRate.IsHouseUse AS RoomRateIsHouseUse,
			|	SUM(RoomSalesForecastTurnovers.SalesTurnover) AS SalesTurnover,
			|	SUM(RoomSalesForecastTurnovers.SalesWithoutVATTurnover) AS SalesWithoutVATTurnover,
			|	SUM(RoomSalesForecastTurnovers.RoomRevenueTurnover) AS RoomRevenueTurnover,
			|	SUM(RoomSalesForecastTurnovers.RoomRevenueWithoutVATTurnover) AS RoomRevenueWithoutVATTurnover,
			|	SUM(RoomSalesForecastTurnovers.RoomsRentedTurnover) AS RoomsRentedTurnover,
			|	SUM(RoomSalesForecastTurnovers.BedsRentedTurnover) AS BedsRentedTurnover
			|FROM
			|	AccumulationRegister.SalesForecast.Turnovers(&qPeriodFrom, &qPeriodTo, Day, Hotel IN HIERARCHY (&qHotel)) AS RoomSalesForecastTurnovers
			|GROUP BY
			|	RoomSalesForecastTurnovers.Period,
			|	RoomSalesForecastTurnovers.RoomRate.IsComplimentary,
			|	RoomSalesForecastTurnovers.RoomRate.IsHouseUse
			|ORDER BY
			|	Period,
			|	RoomRateIsComplimentary,
			|	RoomRateIsHouseUse";
			vQry.SetParameter("qPeriodFrom", vForecastStartDate);
			vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
			vQry.SetParameter("qHotel", vHotel);
			vForecastQryResult = vQry.Execute().Unload();
			
			// Merge forecast sales with real ones
			For Each vForecastRow In vForecastQryResult Do
				vFound = False;
				For Each vRow In vQryResult Do
					If vRow.Period = vForecastRow.Period And
						vRow.RoomRateIsComplimentary = vForecastRow.RoomRateIsComplimentary And
						vRow.RoomRateIsHouseUse = vForecastRow.RoomRateIsHouseUse Then
						vFound = True;
						Break;
					EndIf;
				EndDo;
				If Not vFound Then
					vRow = vQryResult.Add();
					vRow.Period = vForecastRow.Period;
					vRow.RoomRateIsComplimentary = vForecastRow.RoomRateIsComplimentary;
					vRow.RoomRateIsHouseUse = vForecastRow.RoomRateIsHouseUse;
					vRow.SalesTurnover = 0;
					vRow.SalesWithoutVATTurnover = 0;
					vRow.RoomRevenueTurnover = 0;
					vRow.RoomRevenueWithoutVATTurnover = 0;
					vRow.RoomsRentedTurnover = 0;
					vRow.BedsRentedTurnover = 0;
				EndIf;
				vRow.SalesTurnover = vRow.SalesTurnover + vForecastRow.SalesTurnover;
				vRow.SalesWithoutVATTurnover = vRow.SalesWithoutVATTurnover + vForecastRow.SalesWithoutVATTurnover;
				vRow.RoomRevenueTurnover = vRow.RoomRevenueTurnover + vForecastRow.RoomRevenueTurnover;
				vRow.RoomRevenueWithoutVATTurnover = vRow.RoomRevenueWithoutVATTurnover + vForecastRow.RoomRevenueWithoutVATTurnover;
				vRow.RoomsRentedTurnover = vRow.RoomsRentedTurnover + vForecastRow.RoomsRentedTurnover;
				vRow.BedsRentedTurnover = vRow.BedsRentedTurnover + vForecastRow.BedsRentedTurnover;
			EndDo;
		EndIf;	
		
		vResources = "SalesTurnover, SalesWithoutVATTurnover, RoomRevenueTurnover, RoomRevenueWithoutVATTurnover, RoomsRentedTurnover, BedsRentedTurnover";
		vPickupResources = "RoomsReserved, ComplimentaryRoomsReserved, HouseuseRoomsReserved, DayuseRoomsReserved, BedsReserved, ComplimentaryBedsReserved, HouseuseBedsReserved, DayuseBedsReserved, RoomsCancelled, BedsCancelled, RoomsNoShow, BedsNoShow, RevenueReserved, RevenueCancelled, RevenueNoShow";
		
		// Get complimentary only
		vQryResultComplArray = vQryResult.Copy().FindRows(New Structure("RoomRateIsComplimentary", True));
		vQryResultCompl = vQryResult.CopyColumns();
		For Each vRow In vQryResultComplArray Do
			vTabRow = vQryResultCompl.Add();
			FillPropertyValues(vTabRow, vRow);
		EndDo;
		vQryResultCompl.GroupBy("Period", vResources);
		
		If ShowPreviousYearData Then
			vQryResultComplArrayLY = vQryResultLY.Copy().FindRows(New Structure("RoomRateIsComplimentary", True));
			vQryResultComplLY = vQryResultLY.CopyColumns();
			For Each vRow In vQryResultComplArrayLY Do
				vTabRow = vQryResultComplLY.Add();
				FillPropertyValues(vTabRow, vRow);
			EndDo;
			vQryResultComplLY.GroupBy("Period", vResources);
		EndIf;
		
		// Get house use only
		vQryResultHUArray = vQryResult.Copy().FindRows(New Structure("RoomRateIsHouseUse", True));
		vQryResultHU = vQryResult.CopyColumns();
		For Each vRow In vQryResultHUArray Do
			vTabRow = vQryResultHU.Add();
			FillPropertyValues(vTabRow, vRow);
		EndDo;
		vQryResultHU.GroupBy("Period", vResources);
		
		If ShowPreviousYearData Then
			vQryResultHUArrayLY = vQryResultLY.Copy().FindRows(New Structure("RoomRateIsHouseUse", True));
			vQryResultHULY = vQryResultLY.CopyColumns();
			For Each vRow In vQryResultHUArrayLY Do
				vTabRow = vQryResultHULY.Add();
				FillPropertyValues(vTabRow, vRow);
			EndDo;
			vQryResultHULY.GroupBy("Period", vResources);
		EndIf;
		
		// Put rooms rented
		vQryResult.GroupBy("Period", vResources);
		If ShowPreviousYearData Then
			vQryResultLY.GroupBy("Period", vResources);
		EndIf;
		GetQryResultTableTotals(vQryResult, vQryResult, vResources, False);
		vRoomsRented = cmCastToNumber(TotalPerDay.RoomsRentedTurnover);
		vRoomsRentedPerMonth = cmCastToNumber(TotalPerMonth.RoomsRentedTurnover);
		vRoomsRentedPerYear = cmCastToNumber(TotalPerYear.RoomsRentedTurnover);
		If ShowPreviousYearData Then
			GetQryResultTableTotalsLY(vQryResultLY, vQryResultLY, vResources, False);
			vRoomsRentedLY = cmCastToNumber(TotalPerDayLY.RoomsRentedTurnover);
			vRoomsRentedPerMonthLY = cmCastToNumber(TotalPerMonthLY.RoomsRentedTurnover);
			vRoomsRentedPerYearLY = cmCastToNumber(TotalPerYearLY.RoomsRentedTurnover);
		EndIf;
		If vInRooms Then
			vArea = vTemplate.GetArea("RoomsRented");
			vArea.Parameters.mRoomsRented = vRoomsRented;
			vArea.Parameters.mRoomsRentedPerMonth = vRoomsRentedPerMonth;
			vArea.Parameters.mRoomsRentedPerYear = vRoomsRentedPerYear;
			If ShowPreviousYearData Then
				vArea.Parameters.mRoomsRentedLY = vRoomsRentedLY;
				vArea.Parameters.mRoomsRentedPerMonthLY = vRoomsRentedPerMonthLY;
				vArea.Parameters.mRoomsRentedPerYearLY = vRoomsRentedPerYearLY;
			EndIf;
			pSpreadsheet.Put(vArea);
		Else
			vArea = vTemplate.GetArea("BedsRented");
			vBedsRented = cmCastToNumber(TotalPerDay.BedsRentedTurnover);
			vArea.Parameters.mBedsRented = vBedsRented;
			vBedsRentedPerMonth = cmCastToNumber(TotalPerMonth.BedsRentedTurnover);
			vArea.Parameters.mBedsRentedPerMonth = vBedsRentedPerMonth;
			vBedsRentedPerYear = cmCastToNumber(TotalPerYear.BedsRentedTurnover);
			vArea.Parameters.mBedsRentedPerYear = vBedsRentedPerYear;
			If ShowPreviousYearData Then
				vBedsRentedLY = cmCastToNumber(TotalPerDayLY.BedsRentedTurnover);
				vArea.Parameters.mBedsRentedLY = vBedsRentedLY;
				vBedsRentedPerMonthLY = cmCastToNumber(TotalPerMonthLY.BedsRentedTurnover);
				vArea.Parameters.mBedsRentedPerMonthLY = vBedsRentedPerMonthLY;
				vBedsRentedPerYearLY = cmCastToNumber(TotalPerYearLY.BedsRentedTurnover);
				vArea.Parameters.mBedsRentedPerYearLY = vBedsRentedPerYearLY;
			EndIf;
			pSpreadsheet.Put(vArea);
		EndIf;
		
		// Save total sales amounts
		If vWithVAT Then
			vRoomsIncome = cmCastToNumber(TotalPerDay.RoomRevenueTurnover);
			vRoomsIncomePerMonth = cmCastToNumber(TotalPerMonth.RoomRevenueTurnover);
			vRoomsIncomePerYear = cmCastToNumber(TotalPerYear.RoomRevenueTurnover);
			
			vTotalIncome = cmCastToNumber(TotalPerDay.SalesTurnover);
			vTotalIncomePerMonth = cmCastToNumber(TotalPerMonth.SalesTurnover);
			vTotalIncomePerYear = cmCastToNumber(TotalPerYear.SalesTurnover);
		Else
			vRoomsIncome = cmCastToNumber(TotalPerDay.RoomRevenueWithoutVATTurnover);
			vRoomsIncomePerMonth = cmCastToNumber(TotalPerMonth.RoomRevenueWithoutVATTurnover);
			vRoomsIncomePerYear = cmCastToNumber(TotalPerYear.RoomRevenueWithoutVATTurnover);
			
			vTotalIncome = cmCastToNumber(TotalPerDay.SalesWithoutVATTurnover);
			vTotalIncomePerMonth = cmCastToNumber(TotalPerMonth.SalesWithoutVATTurnover);
			vTotalIncomePerYear = cmCastToNumber(TotalPerYear.SalesWithoutVATTurnover);
		EndIf;
		
		vOtherIncome = vTotalIncome - vRoomsIncome;
		vOtherIncomePerMonth = vTotalIncomePerMonth - vRoomsIncomePerMonth;
		vOtherIncomePerYear = vTotalIncomePerYear - vRoomsIncomePerYear;
		
		If ShowPreviousYearData Then
			If vWithVAT Then
				vRoomsIncomeLY = cmCastToNumber(TotalPerDayLY.RoomRevenueTurnover);
				vRoomsIncomePerMonthLY = cmCastToNumber(TotalPerMonthLY.RoomRevenueTurnover);
				vRoomsIncomePerYearLY = cmCastToNumber(TotalPerYearLY.RoomRevenueTurnover);
				
				vTotalIncomeLY = cmCastToNumber(TotalPerDayLY.SalesTurnover);
				vTotalIncomePerMonthLY = cmCastToNumber(TotalPerMonthLY.SalesTurnover);
				vTotalIncomePerYearLY = cmCastToNumber(TotalPerYearLY.SalesTurnover);
			Else
				vRoomsIncomeLY = cmCastToNumber(TotalPerDayLY.RoomRevenueWithoutVATTurnover);
				vRoomsIncomePerMonthLY = cmCastToNumber(TotalPerMonthLY.RoomRevenueWithoutVATTurnover);
				vRoomsIncomePerYearLY = cmCastToNumber(TotalPerYearLY.RoomRevenueWithoutVATTurnover);
				
				vTotalIncomeLY = cmCastToNumber(TotalPerDayLY.SalesWithoutVATTurnover);
				vTotalIncomePerMonthLY = cmCastToNumber(TotalPerMonthLY.SalesWithoutVATTurnover);
				vTotalIncomePerYearLY = cmCastToNumber(TotalPerYearLY.SalesWithoutVATTurnover);
			EndIf;
			
			vOtherIncomeLY = vTotalIncomeLY - vRoomsIncomeLY;
			vOtherIncomePerMonthLY = vTotalIncomePerMonthLY - vRoomsIncomePerMonthLY;
			vOtherIncomePerYearLY = vTotalIncomePerYearLY - vRoomsIncomePerYearLY;
		EndIf;
		
		// Put complimentary rooms rented
		GetQryResultTableTotals(vQryResultCompl, vQryResultCompl, vResources, False);
		If ShowPreviousYearData Then
			GetQryResultTableTotalsLY(vQryResultComplLY, vQryResultComplLY, vResources, False);
		EndIf;
		If vInRooms Then
			vArea = vTemplate.GetArea("ComplimentaryRooms");
			
			vComplimentaryRooms = cmCastToNumber(TotalPerDay.RoomsRentedTurnover);
			vArea.Parameters.mComplimentaryRooms = vComplimentaryRooms;
			vComplimentaryRoomsPerMonth = cmCastToNumber(TotalPerMonth.RoomsRentedTurnover);
			vArea.Parameters.mComplimentaryRoomsPerMonth = vComplimentaryRoomsPerMonth;
			vComplimentaryRoomsPerYear = cmCastToNumber(TotalPerYear.RoomsRentedTurnover);
			vArea.Parameters.mComplimentaryRoomsPerYear = vComplimentaryRoomsPerYear;
			
			If ShowPreviousYearData Then
				vComplimentaryRoomsLY = cmCastToNumber(TotalPerDayLY.RoomsRentedTurnover);
				vArea.Parameters.mComplimentaryRoomsLY = vComplimentaryRoomsLY;
				vComplimentaryRoomsPerMonthLY = cmCastToNumber(TotalPerMonthLY.RoomsRentedTurnover);
				vArea.Parameters.mComplimentaryRoomsPerMonthLY = vComplimentaryRoomsPerMonthLY;
				vComplimentaryRoomsPerYearLY = cmCastToNumber(TotalPerYearLY.RoomsRentedTurnover);
				vArea.Parameters.mComplimentaryRoomsPerYearLY = vComplimentaryRoomsPerYearLY;
			EndIf;
			
			If Not DoNotShowComplimentaryRoomsRentedPercent Then
				pSpreadsheet.Put(vArea);
			EndIf;
		Else
			vArea = vTemplate.GetArea("ComplimentaryBeds");
			
			vComplimentaryBeds = cmCastToNumber(TotalPerDay.BedsRentedTurnover);
			vArea.Parameters.mComplimentaryBeds = vComplimentaryBeds;
			vComplimentaryBedsPerMonth = cmCastToNumber(TotalPerMonth.BedsRentedTurnover);
			vArea.Parameters.mComplimentaryBedsPerMonth = vComplimentaryBedsPerMonth;
			vComplimentaryBedsPerYear = cmCastToNumber(TotalPerYear.BedsRentedTurnover);
			vArea.Parameters.mComplimentaryBedsPerYear = vComplimentaryBedsPerYear;
			
			If ShowPreviousYearData Then
				vComplimentaryBedsLY = cmCastToNumber(TotalPerDayLY.BedsRentedTurnover);
				vArea.Parameters.mComplimentaryBedsLY = vComplimentaryBedsLY;
				vComplimentaryBedsPerMonthLY = cmCastToNumber(TotalPerMonthLY.BedsRentedTurnover);
				vArea.Parameters.mComplimentaryBedsPerMonthLY = vComplimentaryBedsPerMonthLY;
				vComplimentaryBedsPerYearLY = cmCastToNumber(TotalPerYearLY.BedsRentedTurnover);
				vArea.Parameters.mComplimentaryBedsPerYearLY = vComplimentaryBedsPerYearLY;
			EndIf;
			
			If Not DoNotShowComplimentaryRoomsRentedPercent Then
				pSpreadsheet.Put(vArea);
			EndIf;
		EndIf;
		
		// Put house use rooms rented
		GetQryResultTableTotals(vQryResultHU, vQryResultHU, vResources, False);
		If ShowPreviousYearData Then
			GetQryResultTableTotalsLY(vQryResultHULY, vQryResultHULY, vResources, False);
		EndIf;
		If vInRooms Then
			vArea = vTemplate.GetArea("HouseUseRooms");
			
			vHouseUseRooms = cmCastToNumber(TotalPerDay.RoomsRentedTurnover);
			vArea.Parameters.mHouseUseRooms = vHouseUseRooms;
			vHouseUseRoomsPerMonth = cmCastToNumber(TotalPerMonth.RoomsRentedTurnover);
			vArea.Parameters.mHouseUseRoomsPerMonth = vHouseUseRoomsPerMonth;
			vHouseUseRoomsPerYear = cmCastToNumber(TotalPerYear.RoomsRentedTurnover);
			vArea.Parameters.mHouseUseRoomsPerYear = vHouseUseRoomsPerYear;
			
			If ShowPreviousYearData Then
				vHouseUseRoomsLY = cmCastToNumber(TotalPerDayLY.RoomsRentedTurnover);
				vArea.Parameters.mHouseUseRoomsLY = vHouseUseRoomsLY;
				vHouseUseRoomsPerMonthLY = cmCastToNumber(TotalPerMonthLY.RoomsRentedTurnover);
				vArea.Parameters.mHouseUseRoomsPerMonthLY = vHouseUseRoomsPerMonthLY;
				vHouseUseRoomsPerYearLY = cmCastToNumber(TotalPerYearLY.RoomsRentedTurnover);
				vArea.Parameters.mHouseUseRoomsPerYearLY = vHouseUseRoomsPerYearLY;
			EndIf;
			
			If Not DoNotShowComplimentaryRoomsRentedPercent Then
				pSpreadsheet.Put(vArea);
			EndIf;
		Else
			vArea = vTemplate.GetArea("HouseUseBeds");
			
			vHouseUseBeds = cmCastToNumber(TotalPerDay.BedsRentedTurnover);
			vArea.Parameters.mHouseUseBeds = vHouseUseBeds;
			vHouseUseBedsPerMonth = cmCastToNumber(TotalPerMonth.BedsRentedTurnover);
			vArea.Parameters.mHouseUseBedsPerMonth = vHouseUseBedsPerMonth;
			vHouseUseBedsPerYear = cmCastToNumber(TotalPerYear.BedsRentedTurnover);
			vArea.Parameters.mHouseUseBedsPerYear = vHouseUseBedsPerYear;
			
			If ShowPreviousYearData Then
				vHouseUseBedsLY = cmCastToNumber(TotalPerDayLY.BedsRentedTurnover);
				vArea.Parameters.mHouseUseBedsLY = vHouseUseBedsLY;
				vHouseUseBedsPerMonthLY = cmCastToNumber(TotalPerMonthLY.BedsRentedTurnover);
				vArea.Parameters.mHouseUseBedsPerMonthLY = vHouseUseBedsPerMonthLY;
				vHouseUseBedsPerYearLY = cmCastToNumber(TotalPerYearLY.BedsRentedTurnover);
				vArea.Parameters.mHouseUseBedsPerYearLY = vHouseUseBedsPerYearLY;
			EndIf;
			
			If Not DoNotShowComplimentaryRoomsRentedPercent Then
				pSpreadsheet.Put(vArea);
			EndIf;
		EndIf;

		// Vacant rooms
		If ShowRoomsOccupiedPercent Then
			If vInRooms Then
				vArea = vTemplate.GetArea("RoomsVacantMinusBlocks");

				vArea.Parameters.mRoomsVacantMinusBlocks = vRoomsVacantMinusBlocks;
				vArea.Parameters.mRoomsVacantMinusBlocksPerMonth = vRoomsVacantMinusBlocksPerMonth;
				vArea.Parameters.mRoomsVacantMinusBlocksPerYear = vRoomsVacantMinusBlocksPerYear;
				
				If ShowPreviousYearData Then
					vArea.Parameters.mRoomsVacantMinusBlocksLY = vRoomsVacantMinusBlocksLY;
					vArea.Parameters.mRoomsVacantMinusBlocksPerMonthLY = vRoomsVacantMinusBlocksPerMonthLY;
					vArea.Parameters.mRoomsVacantMinusBlocksPerYearLY = vRoomsVacantMinusBlocksPerYearLY;
				EndIf;
				
				pSpreadsheet.Put(vArea);
			Else
				vArea = vTemplate.GetArea("BedsVacantMinusBlocks");

				vArea.Parameters.mBedsVacantMinusBlocks = vBedsVacantMinusBlocks;
				vArea.Parameters.mBedsVacantMinusBlocksPerMonth = vBedsVacantMinusBlocksPerMonth;
				vArea.Parameters.mBedsVacantPerYear = vBedsVacantMinusBlocksPerYear;
				
				If ShowPreviousYearData Then
					vArea.Parameters.mBedsVacantMinusBlocksLY = vBedsVacantMinusBlocksLY;
					vArea.Parameters.mBedsVacantMinusBlocksPerMonthLY = vBedsVacantMinusBlocksPerMonthLY;
					vArea.Parameters.mBedsVacantMinusBlocksPerYearLY = vBedsVacantMinusBlocksPerYearLY;
				EndIf;
				
				pSpreadsheet.Put(vArea);
			EndIf;
		Else
			If vInRooms Then
				vArea = vTemplate.GetArea("RoomsVacant");

				vArea.Parameters.mRoomsVacant = vTotalRooms - vRoomsRented;
				vArea.Parameters.mRoomsVacantPerMonth = vTotalRoomsPerMonth - vRoomsRentedPerMonth;
				vArea.Parameters.mRoomsVacantPerYear = vTotalRoomsPerYear - vRoomsRentedPerYear;
				
				If ShowPreviousYearData Then
					vArea.Parameters.mRoomsVacantLY = vTotalRoomsLY - vRoomsRentedLY;
					vArea.Parameters.mRoomsVacantPerMonthLY = vTotalRoomsPerMonthLY - vRoomsRentedPerMonthLY;
					vArea.Parameters.mRoomsVacantPerYearLY = vTotalRoomsPerYearLY - vRoomsRentedPerYearLY;
				EndIf;
				
				pSpreadsheet.Put(vArea);

				vArea = vTemplate.GetArea("RoomsVacantMinusBlocks");

				vArea.Parameters.mRoomsVacantMinusBlocks = vTotalRooms - vRoomsRented - vRoomsBlocked;
				vArea.Parameters.mRoomsVacantMinusBlocksPerMonth = vTotalRoomsPerMonth - vRoomsRentedPerMonth - vRoomsBlockedPerMonth;
				vArea.Parameters.mRoomsVacantMinusBlocksPerYear = vTotalRoomsPerYear - vRoomsRentedPerYear - vRoomsBlockedPerYear;
				
				If ShowPreviousYearData Then
					vArea.Parameters.mRoomsVacantMinusBlocksLY = vTotalRoomsLY - vRoomsRentedLY - vRoomsBlockedLY;
					vArea.Parameters.mRoomsVacantMinusBlocksPerMonthLY = vTotalRoomsPerMonthLY - vRoomsRentedPerMonthLY - vRoomsBlockedPerMonthLY;
					vArea.Parameters.mRoomsVacantMinusBlocksPerYearLY = vTotalRoomsPerYearLY - vRoomsRentedPerYearLY - vRoomsBlockedPerYearLY;
				EndIf;
				
				pSpreadsheet.Put(vArea);
			Else
				vArea = vTemplate.GetArea("BedsVacant");

				vArea.Parameters.mBedsVacant = vTotalBeds - vBedsRented;
				vArea.Parameters.mBedsVacantPerMonth = vTotalBedsPerMonth - vBedsRentedPerMonth;
				vArea.Parameters.mBedsVacantPerYear = vTotalBedsPerYear - vBedsRentedPerYear;
				
				If ShowPreviousYearData Then
					vArea.Parameters.mBedsVacantLY = vTotalBedsLY - vBedsRentedLY;
					vArea.Parameters.mBedsVacantPerMonthLY = vTotalBedsPerMonthLY - vBedsRentedPerMonthLY;
					vArea.Parameters.mBedsVacantPerYearLY = vTotalBedsPerYearLY - vBedsRentedPerYearLY;
				EndIf;
				
				pSpreadsheet.Put(vArea);

				vArea = vTemplate.GetArea("BedsVacantMinusBlocks");

				vArea.Parameters.mBedsVacantMinusBlocks = vTotalBeds - vBedsRented - vBedsBlocked;
				vArea.Parameters.mBedsVacantMinusBlocksPerMonth = vTotalBedsPerMonth - vBedsRentedPerMonth - vBedsBlockedPerMonth;
				vArea.Parameters.mBedsVacantMinusBlocksPerYear = vTotalBedsPerYear - vBedsRentedPerYear - vBedsBlockedPerYear;
				
				If ShowPreviousYearData Then
					vArea.Parameters.mBedsVacantMinusBlocksLY = vTotalBedsLY - vBedsRentedLY - vBedsBlockedLY;
					vArea.Parameters.mBedsVacantMinusBlocksPerMonthLY = vTotalBedsPerMonthLY - vBedsRentedPerMonthLY - vBedsBlockedPerMonthLY;
					vArea.Parameters.mBedsVacantMinusBlocksPerYearLY = vTotalBedsPerYearLY - vBedsRentedPerYearLY - vBedsBlockedPerYearLY;
				EndIf;
				
				pSpreadsheet.Put(vArea);
			EndIf;
		EndIf;
		
		// Put occupation percent header
		vArea = vTemplate.GetArea("OccupationPercentHeader");
		pSpreadsheet.Put(vArea);
		
		If vInRooms Then
			vArea = vTemplate.GetArea("OccupationPercentRooms");
			vArea.Parameters.mOccupationRooms = Round(?((vRoomsForSale + vSpecRoomsBlocked) <> 0, 100 * (vRoomsRented + vSpecRoomsBlocked)/(vRoomsForSale + vSpecRoomsBlocked), 0), 2);
			vArea.Parameters.mOccupationRoomsPerMonth = Round(?((vRoomsForSalePerMonth + vSpecRoomsBlockedPerMonth) <> 0, 100 * (vRoomsRentedPerMonth + vSpecRoomsBlockedPerMonth) / (vRoomsForSalePerMonth + vSpecRoomsBlockedPerMonth), 0), 2);
			vArea.Parameters.mOccupationRoomsPerYear = Round(?((vRoomsForSalePerYear + vSpecRoomsBlockedPerYear) <> 0, 100 * (vRoomsRentedPerYear + vSpecRoomsBlockedPerYear) / (vRoomsForSalePerYear + vSpecRoomsBlockedPerYear), 0), 2);
			If ShowPreviousYearData Then
				vArea.Parameters.mOccupationRoomsLY = Round(?((vRoomsForSaleLY + vSpecRoomsBlockedLY) <> 0, 100*(vRoomsRentedLY + vSpecRoomsBlockedLY) / (vRoomsForSaleLY + vSpecRoomsBlockedLY), 0), 2);
				vArea.Parameters.mOccupationRoomsPerMonthLY = Round(?((vRoomsForSalePerMonthLY + vSpecRoomsBlockedPerMonthLY) <> 0, 100 * (vRoomsRentedPerMonthLY + vSpecRoomsBlockedPerMonthLY) / (vRoomsForSalePerMonthLY + vSpecRoomsBlockedPerMonthLY), 0), 2);
				vArea.Parameters.mOccupationRoomsPerYearLY = Round(?((vRoomsForSalePerYearLY + vSpecRoomsBlockedPerYearLY) <> 0, 100 * (vRoomsRentedPerYearLY + vSpecRoomsBlockedPerYearLY) / (vRoomsForSalePerYearLY + vSpecRoomsBlockedPerYearLY), 0), 2);
			EndIf;
			pSpreadsheet.Put(vArea);
			
			If Not DoNotShowComplimentaryRoomsRentedPercent Then
				vArea = vTemplate.GetArea("OccupationComplPercentRooms");
				vArea.Parameters.mOccupationComplRooms = Round(?((vRoomsForSale + vSpecRoomsBlocked) <> 0, 100 * (vRoomsRented + vSpecRoomsBlocked - vComplimentaryRooms - vHouseUseRooms) / (vRoomsForSale + vSpecRoomsBlocked), 0), 2);
				vArea.Parameters.mOccupationComplRoomsPerMonth = Round(?((vRoomsForSalePerMonth + vSpecRoomsBlockedPerMonth) <> 0, 100 * (vRoomsRentedPerMonth + vSpecRoomsBlockedPerMonth - vComplimentaryRoomsPerMonth - vHouseUseRoomsPerMonth) / (vRoomsForSalePerMonth + vSpecRoomsBlockedPerMonth), 0), 2);
				vArea.Parameters.mOccupationComplRoomsPerYear = Round(?((vRoomsForSalePerYear + vSpecRoomsBlockedPerYear) <> 0, 100 * (vRoomsRentedPerYear + vSpecRoomsBlockedPerYear - vComplimentaryRoomsPerYear - vHouseUseRoomsPerYear)/(vRoomsForSalePerYear + vSpecRoomsBlockedPerYear), 0), 2);
				If ShowPreviousYearData Then
					vArea.Parameters.mOccupationComplRoomsLY = Round(?((vRoomsForSaleLY + vSpecRoomsBlockedLY) <> 0, 100 * (vRoomsRentedLY + vSpecRoomsBlockedLY - vComplimentaryRoomsLY - vHouseUseRoomsLY) / (vRoomsForSaleLY + vSpecRoomsBlockedLY), 0), 2);
					vArea.Parameters.mOccupationComplRoomsPerMonthLY = Round(?((vRoomsForSalePerMonthLY + vSpecRoomsBlockedPerMonthLY) <> 0, 100 * (vRoomsRentedPerMonthLY + vSpecRoomsBlockedPerMonthLY - vComplimentaryRoomsPerMonthLY - vHouseUseRoomsPerMonthLY) / (vRoomsForSalePerMonthLY + vSpecRoomsBlockedPerMonthLY), 0), 2);
					vArea.Parameters.mOccupationComplRoomsPerYearLY = Round(?((vRoomsForSalePerYearLY + vSpecRoomsBlockedPerYearLY) <> 0, 100 * (vRoomsRentedPerYearLY + vSpecRoomsBlockedPerYearLY - vComplimentaryRoomsPerYearLY - vHouseUseRoomsPerYearLY) / (vRoomsForSalePerYearLY + vSpecRoomsBlockedPerYearLY), 0), 2);
				EndIf;
				pSpreadsheet.Put(vArea);
			EndIf;
			
			If Not DoNotShowTotalRoomsRentedPercent Then
				vArea = vTemplate.GetArea("OccupationPercentRoomsWithoutBlocks");
				vArea.Parameters.mOccupationRoomsNoBlocks = Round(?(vTotalRooms <> 0, 100 * (vRoomsRented + vSpecRoomsBlocked) / vTotalRooms, 0), 2);
				vArea.Parameters.mOccupationRoomsNoBlocksPerMonth = Round(?(vTotalRoomsPerMonth <> 0, 100 * (vRoomsRentedPerMonth + vSpecRoomsBlockedPerMonth) / vTotalRoomsPerMonth, 0), 2);
				vArea.Parameters.mOccupationRoomsNoBlocksPerYear = Round(?(vTotalRoomsPerYear <> 0, 100 * (vRoomsRentedPerYear + vSpecRoomsBlockedPerYear) / vTotalRoomsPerYear, 0), 2);
				If ShowPreviousYearData Then
					vArea.Parameters.mOccupationRoomsNoBlocksLY = Round(?(vTotalRoomsLY <> 0, 100 * (vRoomsRentedLY + vSpecRoomsBlockedLY) / vTotalRoomsLY, 0), 2);
					vArea.Parameters.mOccupationRoomsNoBlocksPerMonthLY = Round(?(vTotalRoomsPerMonthLY <> 0, 100 * (vRoomsRentedPerMonthLY + vSpecRoomsBlockedPerMonthLY) / vTotalRoomsPerMonthLY, 0), 2);
					vArea.Parameters.mOccupationRoomsNoBlocksPerYearLY = Round(?(vTotalRoomsPerYearLY <> 0, 100 * (vRoomsRentedPerYearLY + vSpecRoomsBlockedPerYearLY) / vTotalRoomsPerYearLY, 0), 2);
				EndIf;
				pSpreadsheet.Put(vArea);
				
				If Not DoNotShowComplimentaryRoomsRentedPercent Then
					vArea = vTemplate.GetArea("OccupationPercentRoomsWithoutBlocksWithoutCompl");
					vArea.Parameters.mOccupationRoomsNoBlocksNoCompl = Round(?(vTotalRooms <> 0, 100 * (vRoomsRented - vComplimentaryRooms - vHouseUseRooms) / vTotalRooms, 0), 2);
					vArea.Parameters.mOccupationRoomsNoBlocksNoComplPerMonth = Round(?(vTotalRoomsPerMonth <> 0, 100 * (vRoomsRentedPerMonth - vComplimentaryRoomsPerMonth - vHouseUseRoomsPerMonth) / vTotalRoomsPerMonth, 0), 2);
					vArea.Parameters.mOccupationRoomsNoBlocksNoComplPerYear = Round(?(vTotalRoomsPerYear <> 0, 100 * (vRoomsRentedPerYear - vComplimentaryRoomsPerYear - vHouseUseRoomsPerYear) / vTotalRoomsPerYear, 0), 2);
					If ShowPreviousYearData Then
						vArea.Parameters.mOccupationRoomsNoBlocksNoComplLY = Round(?(vTotalRoomsLY <> 0, 100 * (vRoomsRentedLY - vComplimentaryRoomsLY - vHouseUseRoomsLY)/vTotalRoomsLY, 0), 2);
						vArea.Parameters.mOccupationRoomsNoBlocksNoComplPerMonthLY = Round(?(vTotalRoomsPerMonthLY <> 0, 100 * (vRoomsRentedPerMonthLY - vComplimentaryRoomsPerMonthLY - vHouseUseRoomsPerMonthLY) / vTotalRoomsPerMonthLY, 0), 2);
						vArea.Parameters.mOccupationRoomsNoBlocksNoComplPerYearLY = Round(?(vTotalRoomsPerYearLY <> 0, 100 * (vRoomsRentedPerYearLY - vComplimentaryRoomsPerYearLY - vHouseUseRoomsPerYearLY) / vTotalRoomsPerYearLY, 0), 2);
					EndIf;
					pSpreadsheet.Put(vArea);
				EndIf;
			EndIf;
			
			vArea = vTemplate.GetArea("AverageRoomPrice");
			vArea.Parameters.mAvgRoomPrice = Round(?(vRoomsRented <> 0, vRoomsIncome / vRoomsRented, 0), 2);
			vArea.Parameters.mAvgRoomPricePerMonth = Round(?(vRoomsRentedPerMonth <> 0, vRoomsIncomePerMonth / vRoomsRentedPerMonth, 0), 2);
			vArea.Parameters.mAvgRoomPricePerYear = Round(?(vRoomsRentedPerYear <> 0, vRoomsIncomePerYear / vRoomsRentedPerYear, 0), 2);
			vArea.Parameters.mAvgRoomPriceNoCompl = Round(?((vRoomsRented - vComplimentaryRooms - vHouseUseRooms) <> 0, vRoomsIncome / (vRoomsRented - vComplimentaryRooms - vHouseUseRooms), 0), 2);
			vArea.Parameters.mAvgRoomPriceNoComplPerMonth = Round(?((vRoomsRentedPerMonth - vComplimentaryRoomsPerMonth - vHouseUseRoomsPerMonth) <> 0, vRoomsIncomePerMonth / (vRoomsRentedPerMonth - vComplimentaryRoomsPerMonth - vHouseUseRoomsPerMonth), 0), 2);
			vArea.Parameters.mAvgRoomPriceNoComplPerYear = Round(?((vRoomsRentedPerYear - vComplimentaryRoomsPerYear - vHouseUseRoomsPerYear) <> 0, vRoomsIncomePerYear / (vRoomsRentedPerYear - vComplimentaryRoomsPerYear - vHouseUseRoomsPerYear), 0), 2);
			If ShowPreviousYearData Then
				vArea.Parameters.mAvgRoomPriceLY = Round(?(vRoomsRentedLY <> 0, vRoomsIncomeLY / vRoomsRentedLY, 0), 2);
				vArea.Parameters.mAvgRoomPricePerMonthLY = Round(?(vRoomsRentedPerMonthLY <> 0, vRoomsIncomePerMonthLY/vRoomsRentedPerMonthLY, 0), 2);
				vArea.Parameters.mAvgRoomPricePerYearLY = Round(?(vRoomsRentedPerYearLY <> 0, vRoomsIncomePerYearLY/vRoomsRentedPerYearLY, 0), 2);
				vArea.Parameters.mAvgRoomPriceNoComplLY = Round(?((vRoomsRentedLY - vComplimentaryRoomsLY - vHouseUseRoomsLY) <> 0, vRoomsIncomeLY/(vRoomsRentedLY - vComplimentaryRoomsLY - vHouseUseRoomsLY), 0), 2);
				vArea.Parameters.mAvgRoomPriceNoComplPerMonthLY = Round(?((vRoomsRentedPerMonthLY - vComplimentaryRoomsPerMonthLY - vHouseUseRoomsPerMonthLY) <> 0, vRoomsIncomePerMonthLY / (vRoomsRentedPerMonthLY - vComplimentaryRoomsPerMonthLY - vHouseUseRoomsPerMonthLY), 0), 2);
				vArea.Parameters.mAvgRoomPriceNoComplPerYearLY = Round(?((vRoomsRentedPerYearLY - vComplimentaryRoomsPerYearLY - vHouseUseRoomsPerYearLY) <> 0, vRoomsIncomePerYearLY / (vRoomsRentedPerYearLY - vComplimentaryRoomsPerYearLY - vHouseUseRoomsPerYearLY), 0), 2);
			EndIf;
			pSpreadsheet.Put(vArea);
			
			vArea = vTemplate.GetArea("AverageRoomPriceInclAddSrv");
			vArea.Parameters.mAvgRoomPriceInclAddSrv = Round(?(vRoomsRented <> 0, vTotalIncome/vRoomsRented, 0), 2);
			vArea.Parameters.mAvgRoomPriceInclAddSrvPerMonth = Round(?(vRoomsRentedPerMonth <> 0, vTotalIncomePerMonth / vRoomsRentedPerMonth, 0), 2);
			vArea.Parameters.mAvgRoomPriceInclAddSrvPerYear = Round(?(vRoomsRentedPerYear <> 0, vTotalIncomePerYear / vRoomsRentedPerYear, 0), 2);
			If ShowPreviousYearData Then
				vArea.Parameters.mAvgRoomPriceInclAddSrvLY = Round(?(vRoomsRentedLY <> 0, vTotalIncomeLY / vRoomsRentedLY, 0), 2);
				vArea.Parameters.mAvgRoomPriceInclAddSrvPerMonthLY = Round(?(vRoomsRentedPerMonthLY <> 0, vTotalIncomePerMonthLY/vRoomsRentedPerMonthLY, 0), 2);
				vArea.Parameters.mAvgRoomPriceInclAddSrvPerYearLY = Round(?(vRoomsRentedPerYearLY <> 0, vTotalIncomePerYearLY/vRoomsRentedPerYearLY, 0), 2);
			EndIf;
			pSpreadsheet.Put(vArea);
			
			vArea = vTemplate.GetArea("AverageRoomIncome");
			vArea.Parameters.mAvgAvailRoomIncome = Round(?((vRoomsForSale + vSpecRoomsBlocked) <> 0, vRoomsIncome / (vRoomsForSale + vSpecRoomsBlocked), 0), 2);
			vArea.Parameters.mAvgAvailRoomIncomePerMonth = Round(?((vRoomsForSalePerMonth + vSpecRoomsBlockedPerMonth) <> 0, vRoomsIncomePerMonth / (vRoomsForSalePerMonth + vSpecRoomsBlockedPerMonth), 0), 2);
			vArea.Parameters.mAvgAvailRoomIncomePerYear = Round(?((vRoomsForSalePerYear + vSpecRoomsBlockedPerYear) <> 0, vRoomsIncomePerYear / (vRoomsForSalePerYear + vSpecRoomsBlockedPerYear), 0), 2);
			vArea.Parameters.mAvgRoomIncome = Round(?(vTotalRooms <> 0, vRoomsIncome / vTotalRooms, 0), 2);
			vArea.Parameters.mAvgRoomIncomePerMonth = Round(?(vTotalRoomsPerMonth <> 0, vRoomsIncomePerMonth / vTotalRoomsPerMonth, 0), 2);
			vArea.Parameters.mAvgRoomIncomePerYear = Round(?(vTotalRoomsPerYear <> 0, vRoomsIncomePerYear / vTotalRoomsPerYear, 0), 2);
			If ShowPreviousYearData Then
				vArea.Parameters.mAvgAvailRoomIncomeLY = Round(?((vRoomsForSaleLY + vSpecRoomsBlockedLY) <> 0, vRoomsIncomeLY/(vRoomsForSaleLY + vSpecRoomsBlockedLY), 0), 2);
				vArea.Parameters.mAvgAvailRoomIncomePerMonthLY = Round(?((vRoomsForSalePerMonthLY + vSpecRoomsBlockedPerMonthLY) <> 0, vRoomsIncomePerMonthLY / (vRoomsForSalePerMonthLY + vSpecRoomsBlockedPerMonthLY), 0), 2);
				vArea.Parameters.mAvgAvailRoomIncomePerYearLY = Round(?((vRoomsForSalePerYearLY + vSpecRoomsBlockedPerYearLY) <> 0, vRoomsIncomePerYearLY / (vRoomsForSalePerYearLY + vSpecRoomsBlockedPerYearLY), 0), 2);
				vArea.Parameters.mAvgRoomIncomeLY = Round(?(vTotalRoomsLY <> 0, vRoomsIncomeLY / vTotalRoomsLY, 0), 2);
				vArea.Parameters.mAvgRoomIncomePerMonthLY = Round(?(vTotalRoomsPerMonthLY <> 0, vRoomsIncomePerMonthLY / vTotalRoomsPerMonthLY, 0), 2);
				vArea.Parameters.mAvgRoomIncomePerYearLY = Round(?(vTotalRoomsPerYearLY <> 0, vRoomsIncomePerYearLY / vTotalRoomsPerYearLY, 0), 2);
			EndIf;
			pSpreadsheet.Put(vArea);
		Else
			vArea = vTemplate.GetArea("OccupationPercentBeds");
			vArea.Parameters.mOccupationBeds = Round(?((vBedsForSale + vSpecBedsBlocked) <> 0, 100 * (vBedsRented + vSpecBedsBlocked)/(vBedsForSale + vSpecBedsBlocked), 0), 2);
			vArea.Parameters.mOccupationBedsPerMonth = Round(?((vBedsForSalePerMonth + vSpecBedsBlockedPerMonth) <> 0, 100 * (vBedsRentedPerMonth + vSpecBedsBlockedPerMonth) / (vBedsForSalePerMonth + vSpecBedsBlockedPerMonth), 0), 2);
			vArea.Parameters.mOccupationBedsPerYear = Round(?((vBedsForSalePerYear + vSpecBedsBlockedPerYear) <> 0, 100 * (vBedsRentedPerYear + vSpecBedsBlockedPerYear) / (vBedsForSalePerYear + vSpecBedsBlockedPerYear), 0), 2);
			If ShowPreviousYearData Then
				vArea.Parameters.mOccupationBedsLY = Round(?((vBedsForSaleLY + vSpecBedsBlockedLY) <> 0, 100*(vBedsRentedLY + vSpecBedsBlockedLY) / (vBedsForSaleLY + vSpecBedsBlockedLY), 0), 2);
				vArea.Parameters.mOccupationBedsPerMonthLY = Round(?((vBedsForSalePerMonthLY + vSpecBedsBlockedPerMonthLY) <> 0, 100 * (vBedsRentedPerMonthLY + vSpecBedsBlockedPerMonthLY) / (vBedsForSalePerMonthLY + vSpecBedsBlockedPerMonthLY), 0), 2);
				vArea.Parameters.mOccupationBedsPerYearLY = Round(?((vBedsForSalePerYearLY + vSpecBedsBlockedPerYearLY) <> 0, 100 * (vBedsRentedPerYearLY + vSpecBedsBlockedPerYearLY) / (vBedsForSalePerYearLY + vSpecBedsBlockedPerYearLY), 0), 2);
			EndIf;
			pSpreadsheet.Put(vArea);
			
			If Not DoNotShowComplimentaryRoomsRentedPercent Then
				vArea = vTemplate.GetArea("OccupationComplPercentBeds");
				vArea.Parameters.mOccupationComplBeds = Round(?((vBedsForSale + vSpecBedsBlocked) <> 0, 100 * (vBedsRented + vSpecBedsBlocked - vComplimentaryBeds) / (vBedsForSale + vSpecBedsBlocked), 0), 2);
				vArea.Parameters.mOccupationComplBedsPerMonth = Round(?((vBedsForSalePerMonth + vSpecBedsBlockedPerMonth) <> 0, 100 * (vBedsRentedPerMonth + vSpecBedsBlockedPerMonth - vComplimentaryBedsPerMonth) / (vBedsForSalePerMonth + vSpecBedsBlockedPerMonth), 0), 2);
				vArea.Parameters.mOccupationComplBedsPerYear = Round(?((vBedsForSalePerYear + vSpecBedsBlockedPerYear) <> 0, 100 * (vBedsRentedPerYear + vSpecBedsBlockedPerYear - vComplimentaryBedsPerYear) / (vBedsForSalePerYear + vSpecBedsBlockedPerYear), 0), 2);
				If ShowPreviousYearData Then
					vArea.Parameters.mOccupationComplBedsLY = Round(?((vBedsForSaleLY + vSpecBedsBlockedLY) <> 0, 100 * (vBedsRentedLY + vSpecBedsBlockedLY - vComplimentaryBedsLY) / (vBedsForSaleLY + vSpecBedsBlockedLY), 0), 2);
					vArea.Parameters.mOccupationComplBedsPerMonthLY = Round(?((vBedsForSalePerMonthLY + vSpecBedsBlockedPerMonthLY) <> 0, 100 * (vBedsRentedPerMonthLY + vSpecBedsBlockedPerMonthLY - vComplimentaryBedsPerMonthLY) / (vBedsForSalePerMonthLY + vSpecBedsBlockedPerMonthLY), 0), 2);
					vArea.Parameters.mOccupationComplBedsPerYearLY = Round(?((vBedsForSalePerYearLY + vSpecBedsBlockedPerYearLY) <> 0, 100 * (vBedsRentedPerYearLY + vSpecBedsBlockedPerYearLY - vComplimentaryBedsPerYearLY) / (vBedsForSalePerYearLY + vSpecBedsBlockedPerYearLY), 0), 2);
				EndIf;
				pSpreadsheet.Put(vArea);
			EndIf;
			
			If Not DoNotShowTotalRoomsRentedPercent Then
				vArea = vTemplate.GetArea("OccupationPercentBedsWithoutBlocks");
				vArea.Parameters.mOccupationBedsNoBlocks = Round(?(vTotalBeds <> 0, 100 * (vBedsRented + vSpecBedsBlocked) / vTotalBeds, 0), 2);
				vArea.Parameters.mOccupationBedsNoBlocksPerMonth = Round(?(vTotalBedsPerMonth <> 0, 100 * (vBedsRentedPerMonth + vSpecBedsBlockedPerMonth) / vTotalBedsPerMonth, 0), 2);
				vArea.Parameters.mOccupationBedsNoBlocksPerYear = Round(?(vTotalBedsPerYear <> 0, 100 * (vBedsRentedPerYear + vSpecRoomsBlockedPerYear) / vTotalBedsPerYear, 0), 2);
				If ShowPreviousYearData Then
					vArea.Parameters.mOccupationBedsNoBlocksLY = Round(?(vTotalBedsLY <> 0, 100 * (vBedsRentedLY + vSpecBedsBlockedLY) / vTotalBedsLY, 0), 2);
					vArea.Parameters.mOccupationBedsNoBlocksPerMonthLY = Round(?(vTotalBedsPerMonthLY <> 0, 100 * (vBedsRentedPerMonthLY + vSpecBedsBlockedPerMonthLY) / vTotalBedsPerMonthLY, 0), 2);
					vArea.Parameters.mOccupationBedsNoBlocksPerYearLY = Round(?(vTotalBedsPerYearLY <> 0, 100 * (vBedsRentedPerYearLY + vSpecRoomsBlockedPerYearLY) / vTotalBedsPerYearLY, 0), 2);
				EndIf;
				pSpreadsheet.Put(vArea);
				
				If Not DoNotShowComplimentaryRoomsRentedPercent Then
					vArea = vTemplate.GetArea("OccupationPercentBedsWithoutBlocksWithoutCompl");
					vArea.Parameters.mOccupationBedsNoBlocksNoCompl = Round(?(vTotalBeds <> 0, 100 * (vBedsRented - vComplimentaryBeds - vHouseUseBeds) / vTotalBeds, 0), 2);
					vArea.Parameters.mOccupationBedsNoBlocksNoComplPerMonth = Round(?(vTotalBedsPerMonth <> 0, 100 * (vBedsRentedPerMonth - vComplimentaryBedsPerMonth - vHouseUseBedsPerMonth) / vTotalBedsPerMonth, 0), 2);
					vArea.Parameters.mOccupationBedsNoBlocksNoComplPerYear = Round(?(vTotalBedsPerYear <> 0, 100 * (vBedsRentedPerYear - vComplimentaryBedsPerYear - vHouseUseBedsPerYear) / vTotalBedsPerYear, 0), 2);
					If ShowPreviousYearData Then
						vArea.Parameters.mOccupationBedsNoBlocksNoComplLY = Round(?(vTotalBedsLY <> 0, 100 * (vBedsRentedLY - vComplimentaryBedsLY - vHouseUseBedsLY) / vTotalBedsLY, 0), 2);
						vArea.Parameters.mOccupationBedsNoBlocksNoComplPerMonthLY = Round(?(vTotalBedsPerMonthLY <> 0, 100 * (vBedsRentedPerMonthLY - vComplimentaryBedsPerMonthLY - vHouseUseBedsPerMonthLY) / vTotalBedsPerMonthLY, 0), 2);
						vArea.Parameters.mOccupationBedsNoBlocksNoComplPerYearLY = Round(?(vTotalBedsPerYearLY <> 0, 100 * (vBedsRentedPerYearLY - vComplimentaryBedsPerYearLY - vHouseUseBedsPerYearLY) / vTotalBedsPerYearLY, 0), 2);
					EndIf;
					pSpreadsheet.Put(vArea);
				EndIf;
			EndIf;
			
			vArea = vTemplate.GetArea("AverageBedPrice");
			vArea.Parameters.mAvgBedPrice = Round(?(vBedsRented <> 0, vRoomsIncome / vBedsRented, 0), 2);
			vArea.Parameters.mAvgBedPricePerMonth = Round(?(vBedsRentedPerMonth <> 0, vRoomsIncomePerMonth / vBedsRentedPerMonth, 0), 2);
			vArea.Parameters.mAvgBedPricePerYear = Round(?(vBedsRentedPerYear <> 0, vRoomsIncomePerYear / vBedsRentedPerYear, 0), 2);
			vArea.Parameters.mAvgBedPriceNoCompl = Round(?((vBedsRented - vComplimentaryBeds - vHouseUseBeds) <> 0, vRoomsIncome / (vBedsRented - vComplimentaryBeds - vHouseUseBeds), 0), 2);
			vArea.Parameters.mAvgBedPriceNoComplPerMonth = Round(?((vBedsRentedPerMonth - vComplimentaryBedsPerMonth - vHouseUseBedsPerMonth) <> 0, vRoomsIncomePerMonth / (vBedsRentedPerMonth - vComplimentaryBedsPerMonth - vHouseUseBedsPerMonth), 0), 2);
			vArea.Parameters.mAvgBedPriceNoComplPerYear = Round(?((vBedsRentedPerYear - vComplimentaryBedsPerYear - vHouseUseBedsPerYear) <> 0, vRoomsIncomePerYear / (vBedsRentedPerYear - vComplimentaryBedsPerYear - vHouseUseBedsPerYear), 0), 2);
			If ShowPreviousYearData Then
				vArea.Parameters.mAvgBedPriceLY = Round(?(vBedsRentedLY <> 0, vRoomsIncomeLY / vBedsRentedLY, 0), 2);
				vArea.Parameters.mAvgBedPricePerMonthLY = Round(?(vBedsRentedPerMonthLY <> 0, vRoomsIncomePerMonthLY/vBedsRentedPerMonthLY, 0), 2);
				vArea.Parameters.mAvgBedPricePerYearLY = Round(?(vBedsRentedPerYearLY <> 0, vRoomsIncomePerYearLY / vBedsRentedPerYearLY, 0), 2);
				vArea.Parameters.mAvgBedPriceNoComplLY = Round(?((vBedsRentedLY - vComplimentaryBedsLY - vHouseUseBedsLY) <> 0, vRoomsIncomeLY / (vBedsRentedLY - vComplimentaryBedsLY - vHouseUseBedsLY), 0), 2);
				vArea.Parameters.mAvgBedPriceNoComplPerMonthLY = Round(?((vBedsRentedPerMonthLY - vComplimentaryBedsPerMonthLY - vHouseUseBedsPerMonthLY) <> 0, vRoomsIncomePerMonthLY / (vBedsRentedPerMonthLY - vComplimentaryBedsPerMonthLY - vHouseUseBedsPerMonthLY), 0), 2);
				vArea.Parameters.mAvgBedPriceNoComplPerYearLY = Round(?((vBedsRentedPerYearLY - vComplimentaryBedsPerYearLY - vHouseUseBedsPerYearLY) <> 0, vRoomsIncomePerYearLY / (vBedsRentedPerYearLY - vComplimentaryBedsPerYearLY - vHouseUseBedsPerYearLY), 0), 2);
			EndIf;
			pSpreadsheet.Put(vArea);
			
			vArea = vTemplate.GetArea("AverageBedPriceInclAddSrv");
			vArea.Parameters.mAvgBedPriceInclAddSrv = Round(?(vBedsRented <> 0, vTotalIncome / vBedsRented, 0), 2);
			vArea.Parameters.mAvgBedPriceInclAddSrvPerMonth = Round(?(vBedsRentedPerMonth <> 0, vTotalIncomePerMonth / vBedsRentedPerMonth, 0), 2);
			vArea.Parameters.mAvgBedPriceInclAddSrvPerYear = Round(?(vBedsRentedPerYear <> 0, vTotalIncomePerYear / vBedsRentedPerYear, 0), 2);
			If ShowPreviousYearData Then
				vArea.Parameters.mAvgBedPriceInclAddSrvLY = Round(?(vBedsRentedLY <> 0, vTotalIncomeLY / vBedsRentedLY, 0), 2);
				vArea.Parameters.mAvgBedPriceInclAddSrvPerMonthLY = Round(?(vBedsRentedPerMonthLY <> 0, vTotalIncomePerMonthLY / vBedsRentedPerMonthLY, 0), 2);
				vArea.Parameters.mAvgBedPriceInclAddSrvPerYearLY = Round(?(vBedsRentedPerYearLY <> 0, vTotalIncomePerYearLY / vBedsRentedPerYearLY, 0), 2);
			EndIf;
			pSpreadsheet.Put(vArea);
			
			vArea = vTemplate.GetArea("AverageBedIncome");
			vArea.Parameters.mAvgAvailBedIncome = Round(?((vBedsForSale + vSpecBedsBlocked) <> 0, vRoomsIncome / (vBedsForSale + vSpecBedsBlocked), 0), 2);
			vArea.Parameters.mAvgAvailBedIncomePerMonth = Round(?((vBedsForSalePerMonth + vSpecBedsBlockedPerMonth) <> 0, vRoomsIncomePerMonth / (vBedsForSalePerMonth + vSpecBedsBlockedPerMonth), 0), 2);
			vArea.Parameters.mAvgAvailBedIncomePerYear = Round(?((vBedsForSalePerYear + vSpecBedsBlockedPerYear) <> 0, vRoomsIncomePerYear / (vBedsForSalePerYear + vSpecBedsBlockedPerYear), 0), 2);
			vArea.Parameters.mAvgBedIncome = Round(?(vTotalBeds <> 0, vRoomsIncome / vTotalBeds, 0), 2);
			vArea.Parameters.mAvgBedIncomePerMonth = Round(?(vTotalBedsPerMonth <> 0, vRoomsIncomePerMonth / vTotalBedsPerMonth, 0), 2);
			vArea.Parameters.mAvgBedIncomePerYear = Round(?(vTotalBedsPerYear <> 0, vRoomsIncomePerYear / vTotalBedsPerYear, 0), 2);
			If ShowPreviousYearData Then
				vArea.Parameters.mAvgAvailBedIncomeLY = Round(?((vBedsForSaleLY + vSpecBedsBlockedLY) <> 0, vRoomsIncomeLY/(vBedsForSaleLY + vSpecBedsBlockedLY), 0), 2);
				vArea.Parameters.mAvgAvailBedIncomePerMonthLY = Round(?((vBedsForSalePerMonthLY + vSpecBedsBlockedPerMonthLY) <> 0, vRoomsIncomePerMonthLY / (vBedsForSalePerMonthLY + vSpecBedsBlockedPerMonthLY), 0), 2);
				vArea.Parameters.mAvgAvailBedIncomePerYearLY = Round(?((vBedsForSalePerYearLY + vSpecBedsBlockedPerYearLY) <> 0, vRoomsIncomePerYearLY / (vBedsForSalePerYearLY + vSpecBedsBlockedPerYearLY), 0), 2);
				vArea.Parameters.mAvgBedIncomeLY = Round(?(vTotalBedsLY <> 0, vRoomsIncomeLY / vTotalBedsLY, 0), 2);
				vArea.Parameters.mAvgBedIncomePerMonthLY = Round(?(vTotalBedsPerMonthLY <> 0, vRoomsIncomePerMonthLY / vTotalBedsPerMonthLY, 0), 2);
				vArea.Parameters.mAvgBedIncomePerYearLY = Round(?(vTotalBedsPerYearLY <> 0, vRoomsIncomePerYearLY / vTotalBedsPerYearLY, 0), 2);
			EndIf;
			pSpreadsheet.Put(vArea);
		EndIf;
		
		// 2. Guests summary indexes
		
		// Put section header
		vArea = vTemplate.GetArea("GuestsSummaryHeader");
		pSpreadsheet.Put(vArea);
		
		vArea = vTemplate.GetArea("GuestsHeader");
		pSpreadsheet.Put(vArea);
		
		// Run query to get number of guest days
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	ClientTypesTurnovers.Period AS Period,
		|	ClientTypesTurnovers.ClientType AS ClientType,
		|	ClientTypesTurnovers.ClientType.SortCode AS ClientTypeSortCode,
		|	ClientTypesTurnovers.ClientType.Description AS ClientTypeDescription,
		|	SUM(ClientTypesTurnovers.GuestDaysTurnover) AS GuestDaysTurnover,
		|	SUM(ClientTypesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover,
		|	SUM(ClientTypesTurnovers.ChildrenDaysTurnover) AS ChildrenDaysTurnover,
		|	SUM(ClientTypesTurnovers.ChildrenCheckedInTurnover) AS ChildrenCheckedInTurnover,
		|	SUM(ClientTypesTurnovers.GuestDaysTurnover - ClientTypesTurnovers.ChildrenDaysTurnover) AS AdultsDaysTurnover,
		|	SUM(ClientTypesTurnovers.GuestsCheckedInTurnover - ClientTypesTurnovers.ChildrenCheckedInTurnover) AS AdultsCheckedInTurnover
		|FROM
		|	(SELECT
		|		RoomSalesTurnovers.Period AS Period,
		|		RoomSalesTurnovers.Hotel AS Hotel,
		|		RoomSalesTurnovers.Client AS Client,
		|		RoomSalesTurnovers.ClientType AS ClientType,
		|		RoomSalesTurnovers.ClientType.SortCode AS ClientTypeSortCode,
		|		RoomSalesTurnovers.ClientType.Description AS ClientTypeDescription,
		|		RoomSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover,
		|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
		|		CASE
		|			WHEN ISNULL(RoomSalesTurnovers.Hotel.TeenagersMaxAge, 0) > 0
		|					AND ISNULL(RoomSalesTurnovers.Client.Age, 0) <> 0
		|					AND ISNULL(RoomSalesTurnovers.Client.Age, 0) <= ISNULL(RoomSalesTurnovers.Hotel.TeenagersMaxAge, 0)
		|				THEN RoomSalesTurnovers.GuestDaysTurnover
		|			WHEN ISNULL(RoomSalesTurnovers.Hotel.TeenagersMaxAge, 0) = 0
		|					AND ISNULL(RoomSalesTurnovers.Hotel.ChildrenMaxAge, 0) > 0
		|					AND ISNULL(RoomSalesTurnovers.Client.Age, 0) <> 0
		|					AND ISNULL(RoomSalesTurnovers.Client.Age, 0) <= ISNULL(RoomSalesTurnovers.Hotel.ChildrenMaxAge, 0)
		|				THEN RoomSalesTurnovers.GuestDaysTurnover
		|			WHEN ISNULL(RoomSalesTurnovers.Hotel.TeenagersMaxAge, 0) = 0
		|					AND ISNULL(RoomSalesTurnovers.Hotel.ChildrenMaxAge, 0) = 0
		|					AND ISNULL(RoomSalesTurnovers.Client.Age, 0) <> 0
		|					AND ISNULL(RoomSalesTurnovers.Client.Age, 0) <= 17
		|				THEN RoomSalesTurnovers.GuestDaysTurnover
		|			ELSE 0
		|		END AS ChildrenDaysTurnover,
		|		CASE
		|			WHEN ISNULL(RoomSalesTurnovers.Hotel.TeenagersMaxAge, 0) > 0
		|					AND ISNULL(RoomSalesTurnovers.Client.Age, 0) <> 0
		|					AND ISNULL(RoomSalesTurnovers.Client.Age, 0) <= ISNULL(RoomSalesTurnovers.Hotel.TeenagersMaxAge, 0)
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			WHEN ISNULL(RoomSalesTurnovers.Hotel.TeenagersMaxAge, 0) = 0
		|					AND ISNULL(RoomSalesTurnovers.Hotel.ChildrenMaxAge, 0) > 0
		|					AND ISNULL(RoomSalesTurnovers.Client.Age, 0) <> 0
		|					AND ISNULL(RoomSalesTurnovers.Client.Age, 0) <= ISNULL(RoomSalesTurnovers.Hotel.ChildrenMaxAge, 0)
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			WHEN ISNULL(RoomSalesTurnovers.Hotel.TeenagersMaxAge, 0) = 0
		|					AND ISNULL(RoomSalesTurnovers.Hotel.ChildrenMaxAge, 0) = 0
		|					AND ISNULL(RoomSalesTurnovers.Client.Age, 0) <> 0
		|					AND ISNULL(RoomSalesTurnovers.Client.Age, 0) <= 17
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			ELSE 0
		|		END AS ChildrenCheckedInTurnover
		|	FROM
		|		AccumulationRegister.Sales.Turnovers(
		|				&qPeriodFrom,
		|				&qPeriodTo,
		|				Day,
		|				NOT IsCorrection
		|					AND Hotel IN HIERARCHY (&qHotel)) AS RoomSalesTurnovers) AS ClientTypesTurnovers
		|
		|GROUP BY
		|	ClientTypesTurnovers.Period,
		|	ClientTypesTurnovers.ClientType,
		|	ClientTypesTurnovers.ClientType.SortCode,
		|	ClientTypesTurnovers.ClientType.Description
		|
		|ORDER BY
		|	Period,
		|	ClientTypeSortCode,
		|	ClientTypeDescription";
		vQry.SetParameter("qPeriodFrom", pmBegOfYear(PeriodTo));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qHotel", vHotel);
		vQryResult = vQry.Execute().Unload();
		
		If ShowPreviousYearData Then
			// Run query to get number of guest days
			vQryLY = New Query();
			vQryLY.Text = vQry.Text;
			vQryLY.SetParameter("qPeriodFrom", pmBegOfYear(PeriodToLY));
			vQryLY.SetParameter("qPeriodTo", EndOfDay(PeriodToLY));
			vQryLY.SetParameter("qHotel", vHotel);
			vQryResultLY = vQryLY.Execute().Unload();
		EndIf;
		
		// Add forecast guests if period is set in the future
		If BegOfDay(PeriodTo) >= vForecastStartDate And Not DoNotShowForecast Then
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	ClientTypesTurnovers.Period AS Period,
			|	ClientTypesTurnovers.ClientType AS ClientType,
			|	ClientTypesTurnovers.ClientType.SortCode AS ClientTypeSortCode,
			|	ClientTypesTurnovers.ClientType.Description AS ClientTypeDescription,
			|	SUM(ClientTypesTurnovers.GuestDaysTurnover) AS GuestDaysTurnover,
			|	SUM(ClientTypesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover,
			|	SUM(ClientTypesTurnovers.ChildrenDaysTurnover) AS ChildrenDaysTurnover,
			|	SUM(ClientTypesTurnovers.ChildrenCheckedInTurnover) AS ChildrenCheckedInTurnover,
			|	SUM(ClientTypesTurnovers.GuestDaysTurnover - ClientTypesTurnovers.ChildrenDaysTurnover) AS AdultsDaysTurnover,
			|	SUM(ClientTypesTurnovers.GuestsCheckedInTurnover - ClientTypesTurnovers.ChildrenCheckedInTurnover) AS AdultsCheckedInTurnover
			|FROM
			|	(SELECT
			|		RoomSalesTurnovers.Period AS Period,
			|		RoomSalesTurnovers.Hotel AS Hotel,
			|		RoomSalesTurnovers.Client AS Client,
			|		RoomSalesTurnovers.ClientType AS ClientType,
			|		RoomSalesTurnovers.ClientType.SortCode AS ClientTypeSortCode,
			|		RoomSalesTurnovers.ClientType.Description AS ClientTypeDescription,
			|		RoomSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover,
			|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
			|		CASE
			|			WHEN ISNULL(RoomSalesTurnovers.Hotel.TeenagersMaxAge, 0) > 0
			|					AND ISNULL(RoomSalesTurnovers.Client.Age, 0) <> 0
			|					AND ISNULL(RoomSalesTurnovers.Client.Age, 0) <= ISNULL(RoomSalesTurnovers.Hotel.TeenagersMaxAge, 0)
			|				THEN RoomSalesTurnovers.GuestDaysTurnover
			|			WHEN ISNULL(RoomSalesTurnovers.Hotel.TeenagersMaxAge, 0) = 0
			|					AND ISNULL(RoomSalesTurnovers.Hotel.ChildrenMaxAge, 0) > 0
			|					AND ISNULL(RoomSalesTurnovers.Client.Age, 0) <> 0
			|					AND ISNULL(RoomSalesTurnovers.Client.Age, 0) <= ISNULL(RoomSalesTurnovers.Hotel.ChildrenMaxAge, 0)
			|				THEN RoomSalesTurnovers.GuestDaysTurnover
			|			WHEN ISNULL(RoomSalesTurnovers.Hotel.TeenagersMaxAge, 0) = 0
			|					AND ISNULL(RoomSalesTurnovers.Hotel.ChildrenMaxAge, 0) = 0
			|					AND ISNULL(RoomSalesTurnovers.Client.Age, 0) <> 0
			|					AND ISNULL(RoomSalesTurnovers.Client.Age, 0) <= 17
			|				THEN RoomSalesTurnovers.GuestDaysTurnover
			|			ELSE 0
			|		END AS ChildrenDaysTurnover,
			|		CASE
			|			WHEN ISNULL(RoomSalesTurnovers.Hotel.TeenagersMaxAge, 0) > 0
			|					AND ISNULL(RoomSalesTurnovers.Client.Age, 0) <> 0
			|					AND ISNULL(RoomSalesTurnovers.Client.Age, 0) <= ISNULL(RoomSalesTurnovers.Hotel.TeenagersMaxAge, 0)
			|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
			|			WHEN ISNULL(RoomSalesTurnovers.Hotel.TeenagersMaxAge, 0) = 0
			|					AND ISNULL(RoomSalesTurnovers.Hotel.ChildrenMaxAge, 0) > 0
			|					AND ISNULL(RoomSalesTurnovers.Client.Age, 0) <> 0
			|					AND ISNULL(RoomSalesTurnovers.Client.Age, 0) <= ISNULL(RoomSalesTurnovers.Hotel.ChildrenMaxAge, 0)
			|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
			|			WHEN ISNULL(RoomSalesTurnovers.Hotel.TeenagersMaxAge, 0) = 0
			|					AND ISNULL(RoomSalesTurnovers.Hotel.ChildrenMaxAge, 0) = 0
			|					AND ISNULL(RoomSalesTurnovers.Client.Age, 0) <> 0
			|					AND ISNULL(RoomSalesTurnovers.Client.Age, 0) <= 17
			|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
			|			ELSE 0
			|		END AS ChildrenCheckedInTurnover
			|	FROM
			|		AccumulationRegister.SalesForecast.Turnovers(&qPeriodFrom, &qPeriodTo, Day, Hotel IN HIERARCHY (&qHotel)) AS RoomSalesTurnovers) AS ClientTypesTurnovers
			|
			|GROUP BY
			|	ClientTypesTurnovers.Period,
			|	ClientTypesTurnovers.ClientType,
			|	ClientTypesTurnovers.ClientType.SortCode,
			|	ClientTypesTurnovers.ClientType.Description
			|
			|ORDER BY
			|	Period,
			|	ClientTypeSortCode,
			|	ClientTypeDescription";
			vQry.SetParameter("qPeriodFrom", vForecastStartDate);
			vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
			vQry.SetParameter("qHotel", vHotel);
			vForecastQryResult = vQry.Execute().Unload();
			
			// Merge forecast guests with real ones
			For Each vForecastRow In vForecastQryResult Do
				vFound = False;
				For Each vRow In vQryResult Do
					If vRow.Period = vForecastRow.Period And
						vRow.ClientType = vForecastRow.ClientType Then
						vFound = True;
						Break;
					EndIf;
				EndDo;
				If Not vFound Then
					vRow = vQryResult.Add();
					vRow.Period = vForecastRow.Period;
					vRow.ClientType = vForecastRow.ClientType;
					vRow.GuestDaysTurnover = 0;
					vRow.GuestsCheckedInTurnover = 0;
					vRow.ChildrenDaysTurnover = 0;
					vRow.ChildrenCheckedInTurnover = 0;
					vRow.AdultsDaysTurnover = 0;
					vRow.AdultsCheckedInTurnover = 0;
				EndIf;
				vRow.GuestDaysTurnover = vRow.GuestDaysTurnover + vForecastRow.GuestDaysTurnover;
				vRow.GuestsCheckedInTurnover = vRow.GuestsCheckedInTurnover + vForecastRow.GuestsCheckedInTurnover;
				vRow.ChildrenDaysTurnover = vRow.ChildrenDaysTurnover + vForecastRow.ChildrenDaysTurnover;
				vRow.ChildrenCheckedInTurnover = vRow.ChildrenCheckedInTurnover + vForecastRow.ChildrenCheckedInTurnover;
				vRow.AdultsDaysTurnover = vRow.AdultsDaysTurnover +vForecastRow.AdultsDaysTurnover;
				vRow.AdultsCheckedInTurnover = vRow.AdultsCheckedInTurnover + vForecastRow.AdultsCheckedInTurnover;
			EndDo;
		EndIf;
		
		// Get list of client types
		vClientTypes = vQryResult.Copy();
		vClientTypes.GroupBy("ClientType, ClientTypeSortCode, ClientTypeDescription", );
		vClientTypes.Sort("ClientTypeSortCode, ClientTypeDescription");
		
		// Put client types
		For Each vRow In vClientTypes Do
			vClientType = vRow.ClientType;
			
			// Get records for the current client type only
			vQrySubresult = vQryResult.FindRows(New Structure("ClientType", vClientType));
			GetQryResultTableTotals(vQrySubresult, vQryResult, "GuestDaysTurnover", False);
			If ShowPreviousYearData Then
				vQrySubresultLY = vQryResultLY.FindRows(New Structure("ClientType", vClientType));
				GetQryResultTableTotalsLY(vQrySubresultLY, vQryResultLY, "GuestDaysTurnover", False);
			EndIf;
			
			vArea = vTemplate.GetArea("GuestsByClientType");
			vArea.Parameters.mClientType = ?(ValueIsFilled(vClientType), vClientType, NStr("en='<Normal guest>'; ru='<Обычный гость>'; de='<Normaler Gast>'"));
			vArea.Parameters.mGuests = cmCastToNumber(TotalPerDay.GuestDaysTurnover);
			vArea.Parameters.mGuestsPerMonth = cmCastToNumber(TotalPerMonth.GuestDaysTurnover);
			vArea.Parameters.mGuestsPerYear = cmCastToNumber(TotalPerYear.GuestDaysTurnover);
			If ShowPreviousYearData Then
				vArea.Parameters.mGuestsLY = cmCastToNumber(TotalPerDayLY.GuestDaysTurnover);
				vArea.Parameters.mGuestsPerMonthLY = cmCastToNumber(TotalPerMonthLY.GuestDaysTurnover);
				vArea.Parameters.mGuestsPerYearLY = cmCastToNumber(TotalPerYearLY.GuestDaysTurnover);
			EndIf;
			pSpreadsheet.Put(vArea);
		EndDo;
		
		vClientTypesTotals = vQryResult.Copy();
		vClientTypesTotals.GroupBy("Period", "GuestDaysTurnover, GuestsCheckedInTurnover, ChildrenDaysTurnover, ChildrenCheckedInTurnover, AdultsDaysTurnover, AdultsCheckedInTurnover");
		GetQryResultTableTotals(vClientTypesTotals, vClientTypesTotals, "GuestDaysTurnover, GuestsCheckedInTurnover, ChildrenDaysTurnover, ChildrenCheckedInTurnover, AdultsDaysTurnover, AdultsCheckedInTurnover", False);
		If ShowPreviousYearData Then
			vClientTypesTotalsLY = vQryResultLY.Copy();
			vClientTypesTotalsLY.GroupBy("Period", "GuestDaysTurnover, GuestsCheckedInTurnover, ChildrenDaysTurnover, ChildrenCheckedInTurnover, AdultsDaysTurnover, AdultsCheckedInTurnover");
			GetQryResultTableTotalsLY(vClientTypesTotalsLY, vClientTypesTotalsLY, "GuestDaysTurnover, GuestsCheckedInTurnover, ChildrenDaysTurnover, ChildrenCheckedInTurnover, AdultsDaysTurnover, AdultsCheckedInTurnover", False);
		EndIf;
		
		vArea = vTemplate.GetArea("GuestsFooter");
		vAreaByAge = vTemplate.GetArea("GuestsByAgeFooter");
		vGuests = cmCastToNumber(TotalPerDay.GuestDaysTurnover);
		vChildren = cmCastToNumber(TotalPerDay.ChildrenDaysTurnover);
		vAdults = cmCastToNumber(TotalPerDay.AdultsDaysTurnover);
		vArea.Parameters.mGuests = vGuests;
		vAreaByAge.Parameters.mChildren = vChildren;
		vAreaByAge.Parameters.mAdults = vAdults;
		vGuestsPerMonth = cmCastToNumber(TotalPerMonth.GuestDaysTurnover);
		vChildrenPerMonth = cmCastToNumber(TotalPerMonth.ChildrenDaysTurnover);
		vAdultsPerMonth = cmCastToNumber(TotalPerMonth.AdultsDaysTurnover);
		vArea.Parameters.mGuestsPerMonth = vGuestsPerMonth;
		vAreaByAge.Parameters.mChildrenPerMonth = vChildrenPerMonth;
		vAreaByAge.Parameters.mAdultsPerMonth = vAdultsPerMonth;
		vGuestsPerYear = cmCastToNumber(TotalPerYear.GuestDaysTurnover);
		vChildrenPerYear = cmCastToNumber(TotalPerYear.ChildrenDaysTurnover);
		vAdultsPerYear = cmCastToNumber(TotalPerYear.AdultsDaysTurnover);
		vArea.Parameters.mGuestsPerYear = vGuestsPerYear;
		vAreaByAge.Parameters.mChildrenPerYear = vChildrenPerYear;
		vAreaByAge.Parameters.mAdultsPerYear = vAdultsPerYear;
		If ShowPreviousYearData Then
			vGuestsLY = cmCastToNumber(TotalPerDayLY.GuestDaysTurnover);
			vChildrenLY = cmCastToNumber(TotalPerDayLY.ChildrenDaysTurnover);
			vAdultsLY = cmCastToNumber(TotalPerDayLY.AdultsDaysTurnover);
			vArea.Parameters.mGuestsLY = vGuestsLY;
			vAreaByAge.Parameters.mChildrenLY = vChildrenLY;
			vAreaByAge.Parameters.mAdultsLY = vAdultsLY;
			vGuestsPerMonthLY = cmCastToNumber(TotalPerMonthLY.GuestDaysTurnover);
			vChildrenPerMonthLY = cmCastToNumber(TotalPerMonthLY.ChildrenDaysTurnover);
			vAdultsPerMonthLY = cmCastToNumber(TotalPerMonthLY.AdultsDaysTurnover);
			vArea.Parameters.mGuestsPerMonthLY = vGuestsPerMonthLY;
			vAreaByAge.Parameters.mChildrenPerMonthLY = vChildrenPerMonthLY;
			vAreaByAge.Parameters.mAdultsPerMonthLY = vAdultsPerMonthLY;
			vGuestsPerYearLY = cmCastToNumber(TotalPerYearLY.GuestDaysTurnover);
			vChildrenPerYearLY = cmCastToNumber(TotalPerYearLY.ChildrenDaysTurnover);
			vAdultsPerYearLY = cmCastToNumber(TotalPerYearLY.AdultsDaysTurnover);
			vArea.Parameters.mGuestsPerYearLY = vGuestsPerYearLY;
			vAreaByAge.Parameters.mChildrenPerYearLY = vChildrenPerYearLY;
			vAreaByAge.Parameters.mAdultsPerYearLY = vAdultsPerYearLY;
		EndIf;
		If vClientTypes.Count() > 1 Then
			pSpreadsheet.Put(vArea);
		EndIf;
		pSpreadsheet.Put(vAreaByAge);
		
		// Initialize number of checked in guests
		vCheckedInGuests = cmCastToNumber(TotalPerDay.GuestsCheckedInTurnover);
		vCheckedInGuestsPerMonth = cmCastToNumber(TotalPerMonth.GuestsCheckedInTurnover);
		vCheckedInGuestsPerYear = cmCastToNumber(TotalPerYear.GuestsCheckedInTurnover);
		If ShowPreviousYearData Then
			vCheckedInGuestsLY = cmCastToNumber(TotalPerDayLY.GuestsCheckedInTurnover);
			vCheckedInGuestsPerMonthLY = cmCastToNumber(TotalPerMonthLY.GuestsCheckedInTurnover);
			vCheckedInGuestsPerYearLY = cmCastToNumber(TotalPerYearLY.GuestsCheckedInTurnover);
		EndIf;
		
		// Put guests statistics
		vArea = vTemplate.GetArea("AverageNumberOfGuestsPerRoom");
		vArea.Parameters.mAvgNumberOfGuests = Round(?(vRoomsRented <> 0, vGuests / vRoomsRented, 0), 2);
		vArea.Parameters.mAvgNumberOfGuestsPerMonth = Round(?(vRoomsRentedPerMonth <> 0, vGuestsPerMonth / vRoomsRentedPerMonth, 0), 2);
		vArea.Parameters.mAvgNumberOfGuestsPerYear = Round(?(vRoomsRentedPerYear <> 0, vGuestsPerYear / vRoomsRentedPerYear, 0), 2);
		If ShowPreviousYearData Then
			vArea.Parameters.mAvgNumberOfGuestsLY = Round(?(vRoomsRentedLY <> 0, vGuestsLY / vRoomsRentedLY, 0), 2);
			vArea.Parameters.mAvgNumberOfGuestsPerMonthLY = Round(?(vRoomsRentedPerMonthLY <> 0, vGuestsPerMonthLY / vRoomsRentedPerMonthLY, 0), 2);
			vArea.Parameters.mAvgNumberOfGuestsPerYearLY = Round(?(vRoomsRentedPerYearLY <> 0, vGuestsPerYearLY / vRoomsRentedPerYearLY, 0), 2);
		EndIf;
		pSpreadsheet.Put(vArea);
		
		vArea = vTemplate.GetArea("AverageGuestLengthOfStay");
		vArea.Parameters.mAvgGuestLengthOfStay = Round(?(vCheckedInGuests <> 0, vGuests / vCheckedInGuests, 0), 2);
		vArea.Parameters.mAvgGuestLengthOfStayPerMonth = Round(?(vCheckedInGuestsPerMonth <> 0, vGuestsPerMonth / vCheckedInGuestsPerMonth, 0), 2);
		vArea.Parameters.mAvgGuestLengthOfStayPerYear = Round(?(vCheckedInGuestsPerYear <> 0, vGuestsPerYear / vCheckedInGuestsPerYear, 0), 2);
		If ShowPreviousYearData Then
			vArea.Parameters.mAvgGuestLengthOfStayLY = Round(?(vCheckedInGuestsLY <> 0, vGuestsLY / vCheckedInGuestsLY, 0), 2);
			vArea.Parameters.mAvgGuestLengthOfStayPerMonthLY = Round(?(vCheckedInGuestsPerMonthLY <> 0, vGuestsPerMonthLY / vCheckedInGuestsPerMonthLY, 0), 2);
			vArea.Parameters.mAvgGuestLengthOfStayPerYearLY = Round(?(vCheckedInGuestsPerYearLY <> 0, vGuestsPerYearLY / vCheckedInGuestsPerYearLY, 0), 2);
		EndIf;
		pSpreadsheet.Put(vArea);
		
		vArea = vTemplate.GetArea("AverageGuestPrice");
		vArea.Parameters.mAvgGuestPrice = Round(?(vGuests <> 0, vRoomsIncome / vGuests, 0), 2);
		vArea.Parameters.mAvgGuestPricePerMonth = Round(?(vGuestsPerMonth <> 0, vRoomsIncomePerMonth / vGuestsPerMonth, 0), 2);
		vArea.Parameters.mAvgGuestPricePerYear = Round(?(vGuestsPerYear <> 0, vRoomsIncomePerYear / vGuestsPerYear, 0), 2);
		If ShowPreviousYearData Then
			vArea.Parameters.mAvgGuestPriceLY = Round(?(vGuestsLY <> 0, vRoomsIncomeLY / vGuestsLY, 0), 2);
			vArea.Parameters.mAvgGuestPricePerMonthLY = Round(?(vGuestsPerMonthLY <> 0, vRoomsIncomePerMonthLY / vGuestsPerMonthLY, 0), 2);
			vArea.Parameters.mAvgGuestPricePerYearLY = Round(?(vGuestsPerYearLY <> 0, vRoomsIncomePerYearLY / vGuestsPerYearLY, 0), 2);
		EndIf;
		pSpreadsheet.Put(vArea);
		
		vArea = vTemplate.GetArea("AverageGuestIncome");
		vArea.Parameters.mAvgGuestIncome = Round(?(vGuests <> 0, vTotalIncome/vGuests, 0), 2);
		vArea.Parameters.mAvgGuestIncomePerMonth = Round(?(vGuestsPerMonth <> 0, vTotalIncomePerMonth / vGuestsPerMonth, 0), 2);
		vArea.Parameters.mAvgGuestIncomePerYear = Round(?(vGuestsPerYear <> 0, vTotalIncomePerYear / vGuestsPerYear, 0), 2);
		If ShowPreviousYearData Then
			vArea.Parameters.mAvgGuestIncomeLY = Round(?(vGuestsLY <> 0, vTotalIncomeLY / vGuestsLY, 0), 2);
			vArea.Parameters.mAvgGuestIncomePerMonthLY = Round(?(vGuestsPerMonthLY <> 0, vTotalIncomePerMonthLY / vGuestsPerMonthLY, 0), 2);
			vArea.Parameters.mAvgGuestIncomePerYearLY = Round(?(vGuestsPerYearLY <> 0, vTotalIncomePerYearLY / vGuestsPerYearLY, 0), 2);
		EndIf;
		pSpreadsheet.Put(vArea);
		
		// 3. Check-in summary indexes
		
		// Put section header
		vArea = vTemplate.GetArea("CheckInSummaryHeader");
		pSpreadsheet.Put(vArea);
		
		// Run query to get number of checked-in guests
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	RoomSalesTurnovers.Period AS Period,
		|	RoomSalesTurnovers.ParentDoc.IsByReservation AS ParentDocIsByReservation,
		|	SUM(RoomSalesTurnovers.RoomsCheckedInTurnover) AS RoomsCheckedInTurnover,
		|	SUM(RoomSalesTurnovers.BedsCheckedInTurnover) AS BedsCheckedInTurnover,
		|	SUM(RoomSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
		|FROM
		|	AccumulationRegister.Sales.Turnovers(
		|			&qPeriodFrom,
		|			&qPeriodTo,
		|			Day,
		|			NOT IsCorrection
		|				AND Hotel IN HIERARCHY (&qHotel)) AS RoomSalesTurnovers
		|
		|GROUP BY
		|	RoomSalesTurnovers.Period,
		|	RoomSalesTurnovers.ParentDoc.IsByReservation
		|
		|ORDER BY
		|	Period,
		|	ParentDocIsByReservation";
		vQry.SetParameter("qPeriodFrom", pmBegOfYear(PeriodTo));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qHotel", vHotel);
		vQryResult = vQry.Execute().Unload();
		
		If ShowPreviousYearData Then
			vQryLY = New Query();
			vQryLY.Text = 
			"SELECT
			|	RoomSalesTurnovers.Period AS Period,
			|	RoomSalesTurnovers.ParentDoc.IsByReservation AS ParentDocIsByReservation,
			|	SUM(RoomSalesTurnovers.RoomsCheckedInTurnover) AS RoomsCheckedInTurnover,
			|	SUM(RoomSalesTurnovers.BedsCheckedInTurnover) AS BedsCheckedInTurnover,
			|	SUM(RoomSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
			|FROM
			|	AccumulationRegister.Sales.Turnovers(&qPeriodFrom, &qPeriodTo, Day, NOT IsCorrection AND Hotel IN HIERARCHY (&qHotel)) AS RoomSalesTurnovers
			|GROUP BY
			|	RoomSalesTurnovers.Period,
			|	RoomSalesTurnovers.ParentDoc.IsByReservation
			|ORDER BY
			|	Period,
			|	ParentDocIsByReservation";
			vQryLY.SetParameter("qPeriodFrom", pmBegOfYear(PeriodToLY));
			vQryLY.SetParameter("qPeriodTo", EndOfDay(PeriodToLY));
			vQryLY.SetParameter("qHotel", vHotel);
			vQryResultLY = vQryLY.Execute().Unload();
		EndIf;
		
		// Add forecast guests if period is set in the future
		If BegOfDay(PeriodTo) >= vForecastStartDate And Not DoNotShowForecast Then
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	RoomSalesForecastTurnovers.Period AS Period,
			|	TRUE AS ParentDocIsByReservation,
			|	SUM(RoomSalesForecastTurnovers.RoomsCheckedInTurnover) AS RoomsCheckedInTurnover,
			|	SUM(RoomSalesForecastTurnovers.BedsCheckedInTurnover) AS BedsCheckedInTurnover,
			|	SUM(RoomSalesForecastTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
			|FROM
			|	AccumulationRegister.SalesForecast.Turnovers(&qPeriodFrom, &qPeriodTo, Day, Hotel IN HIERARCHY (&qHotel)) AS RoomSalesForecastTurnovers
			|
			|GROUP BY
			|	RoomSalesForecastTurnovers.Period
			|
			|ORDER BY
			|	Period,
			|	ParentDocIsByReservation";
			vQry.SetParameter("qPeriodFrom", vForecastStartDate);
			vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
			vQry.SetParameter("qHotel", vHotel);
			vForecastQryResult = vQry.Execute().Unload();
			
			// Merge forecast guests with real ones
			For Each vForecastRow In vForecastQryResult Do
				vFound = False;
				For Each vRow In vQryResult Do
					If vRow.Period = vForecastRow.Period And
						vRow.ParentDocIsByReservation = vForecastRow.ParentDocIsByReservation Then
						vFound = True;
						Break;
					EndIf;
				EndDo;
				If Not vFound Then
					vRow = vQryResult.Add();
					vRow.Period = vForecastRow.Period;
					vRow.ParentDocIsByReservation = vForecastRow.ParentDocIsByReservation;
					vRow.RoomsCheckedInTurnover = 0;
					vRow.BedsCheckedInTurnover = 0;
					vRow.GuestsCheckedInTurnover = 0;
				EndIf;
				vRow.RoomsCheckedInTurnover = vRow.RoomsCheckedInTurnover + vForecastRow.RoomsCheckedInTurnover;
				vRow.BedsCheckedInTurnover = vRow.BedsCheckedInTurnover + vForecastRow.BedsCheckedInTurnover;
				vRow.GuestsCheckedInTurnover = vRow.GuestsCheckedInTurnover + vForecastRow.GuestsCheckedInTurnover;
			EndDo;
		EndIf;	
		
		// Split table to walk-in and check-in by reservation
		vQryResultWalkInArray = vQryResult.Copy().FindRows(New Structure("ParentDocIsByReservation", False));
		vQryResultResArray = vQryResult.Copy().FindRows(New Structure("ParentDocIsByReservation", True));
		
		vQryResultWalkIn = vQryResult.CopyColumns();
		For Each vRow In vQryResultWalkInArray Do
			vTabRow = vQryResultWalkIn.Add();
			FillPropertyValues(vTabRow, vRow);
		EndDo;
		vQryResultWalkIn.GroupBy("Period", "RoomsCheckedInTurnover, BedsCheckedInTurnover, GuestsCheckedInTurnover");
		
		vQryResultRes = vQryResult.CopyColumns();
		For Each vRow In vQryResultResArray Do
			vTabRow = vQryResultRes.Add();
			FillPropertyValues(vTabRow, vRow);
		EndDo;
		vQryResultRes.GroupBy("Period", "RoomsCheckedInTurnover, BedsCheckedInTurnover, GuestsCheckedInTurnover");
		
		GetQryResultTableTotals(vQryResultRes, vQryResultRes, "RoomsCheckedInTurnover, BedsCheckedInTurnover, GuestsCheckedInTurnover", False);
		
		If ShowPreviousYearData Then
			vQryResultWalkInArrayLY = vQryResultLY.Copy().FindRows(New Structure("ParentDocIsByReservation", False));
			vQryResultResArrayLY = vQryResultLY.Copy().FindRows(New Structure("ParentDocIsByReservation", True));
			
			vQryResultWalkInLY = vQryResultLY.CopyColumns();
			For Each vRowLY In vQryResultWalkInArrayLY Do
				vTabRowLY = vQryResultWalkInLY.Add();
				FillPropertyValues(vTabRowLY, vRowLY);
			EndDo;
			vQryResultWalkInLY.GroupBy("Period", "RoomsCheckedInTurnover, BedsCheckedInTurnover, GuestsCheckedInTurnover");
			
			vQryResultResLY = vQryResultLY.CopyColumns();
			For Each vRowLY In vQryResultResArrayLY Do
				vTabRowLY = vQryResultResLY.Add();
				FillPropertyValues(vTabRowLY, vRowLY);
			EndDo;
			vQryResultResLY.GroupBy("Period", "RoomsCheckedInTurnover, BedsCheckedInTurnover, GuestsCheckedInTurnover");
			
			GetQryResultTableTotalsLY(vQryResultResLY, vQryResultResLY, "RoomsCheckedInTurnover, BedsCheckedInTurnover, GuestsCheckedInTurnover", False);
		EndIf;
		
		If vInRooms Then
			vArea = vTemplate.GetArea("RoomsReserved");
			vArea.Parameters.mRoomsReserved = cmCastToNumber(TotalPerDay.RoomsCheckedInTurnover);
			vArea.Parameters.mRoomsReservedPerMonth = cmCastToNumber(TotalPerMonth.RoomsCheckedInTurnover);
			vArea.Parameters.mRoomsReservedPerYear = cmCastToNumber(TotalPerYear.RoomsCheckedInTurnover);
			If ShowPreviousYearData Then
				vArea.Parameters.mRoomsReservedLY = cmCastToNumber(TotalPerDayLY.RoomsCheckedInTurnover);
				vArea.Parameters.mRoomsReservedPerMonthLY = cmCastToNumber(TotalPerMonthLY.RoomsCheckedInTurnover);
				vArea.Parameters.mRoomsReservedPerYearLY = cmCastToNumber(TotalPerYearLY.RoomsCheckedInTurnover);
			EndIf;
			pSpreadsheet.Put(vArea);
		Else
			vArea = vTemplate.GetArea("BedsReserved");
			vArea.Parameters.mBedsReserved = cmCastToNumber(TotalPerDay.BedsCheckedInTurnover);
			vArea.Parameters.mBedsReservedPerMonth = cmCastToNumber(TotalPerMonth.BedsCheckedInTurnover);
			vArea.Parameters.mBedsReservedPerYear = cmCastToNumber(TotalPerYear.BedsCheckedInTurnover);
			If ShowPreviousYearData Then
				vArea.Parameters.mBedsReservedLY = cmCastToNumber(TotalPerDayLY.BedsCheckedInTurnover);
				vArea.Parameters.mBedsReservedPerMonthLY = cmCastToNumber(TotalPerMonthLY.BedsCheckedInTurnover);
				vArea.Parameters.mBedsReservedPerYearLY = cmCastToNumber(TotalPerYearLY.BedsCheckedInTurnover);
			EndIf;
			pSpreadsheet.Put(vArea);
		EndIf;

		vArea = vTemplate.GetArea("GuestsReserved");
		vArea.Parameters.mGuestsReserved = cmCastToNumber(TotalPerDay.GuestsCheckedInTurnover);
		vArea.Parameters.mGuestsReservedPerMonth = cmCastToNumber(TotalPerMonth.GuestsCheckedInTurnover);
		vArea.Parameters.mGuestsReservedPerYear = cmCastToNumber(TotalPerYear.GuestsCheckedInTurnover);
		If ShowPreviousYearData Then
			vArea.Parameters.mGuestsReservedLY = cmCastToNumber(TotalPerDayLY.GuestsCheckedInTurnover);
			vArea.Parameters.mGuestsReservedPerMonthLY = cmCastToNumber(TotalPerMonthLY.GuestsCheckedInTurnover);
			vArea.Parameters.mGuestsReservedPerYearLY = cmCastToNumber(TotalPerYearLY.GuestsCheckedInTurnover);
		EndIf;
		pSpreadsheet.Put(vArea);
		
		// Put walk-in
		GetQryResultTableTotals(vQryResultWalkIn, vQryResultWalkIn, "RoomsCheckedInTurnover, BedsCheckedInTurnover, GuestsCheckedInTurnover", False);
		If ShowPreviousYearData Then
			GetQryResultTableTotalsLY(vQryResultWalkInLY, vQryResultWalkInLY, "RoomsCheckedInTurnover, BedsCheckedInTurnover, GuestsCheckedInTurnover", False);
		EndIf;
		
		If vInRooms Then
			vArea = vTemplate.GetArea("RoomsWalkIn");
			vArea.Parameters.mRoomsWalkIn = cmCastToNumber(TotalPerDay.RoomsCheckedInTurnover);
			vArea.Parameters.mRoomsWalkInPerMonth = cmCastToNumber(TotalPerMonth.RoomsCheckedInTurnover);
			vArea.Parameters.mRoomsWalkInPerYear = cmCastToNumber(TotalPerYear.RoomsCheckedInTurnover);
			If ShowPreviousYearData Then
				vArea.Parameters.mRoomsWalkInLY = cmCastToNumber(TotalPerDayLY.RoomsCheckedInTurnover);
				vArea.Parameters.mRoomsWalkInPerMonthLY = cmCastToNumber(TotalPerMonthLY.RoomsCheckedInTurnover);
				vArea.Parameters.mRoomsWalkInPerYearLY = cmCastToNumber(TotalPerYearLY.RoomsCheckedInTurnover);
			EndIf;
			pSpreadsheet.Put(vArea);
		Else
			vArea = vTemplate.GetArea("BedsWalkIn");
			vArea.Parameters.mBedsWalkIn = cmCastToNumber(TotalPerDay.BedsCheckedInTurnover);
			vArea.Parameters.mBedsWalkInPerMonth = cmCastToNumber(TotalPerMonth.BedsCheckedInTurnover);
			vArea.Parameters.mBedsWalkInPerYear = cmCastToNumber(TotalPerYear.BedsCheckedInTurnover);
			If ShowPreviousYearData Then
				vArea.Parameters.mBedsWalkInLY = cmCastToNumber(TotalPerDayLY.BedsCheckedInTurnover);
				vArea.Parameters.mBedsWalkInPerMonthLY = cmCastToNumber(TotalPerMonthLY.BedsCheckedInTurnover);
				vArea.Parameters.mBedsWalkInPerYearLY = cmCastToNumber(TotalPerYearLY.BedsCheckedInTurnover);
			EndIf;
			pSpreadsheet.Put(vArea);
		EndIf;
		
		vArea = vTemplate.GetArea("GuestsWalkIn");
		vArea.Parameters.mGuestsWalkIn = cmCastToNumber(TotalPerDay.GuestsCheckedInTurnover);
		vArea.Parameters.mGuestsWalkInPerMonth = cmCastToNumber(TotalPerMonth.GuestsCheckedInTurnover);
		vArea.Parameters.mGuestsWalkInPerYear = cmCastToNumber(TotalPerYear.GuestsCheckedInTurnover);
		If ShowPreviousYearData Then
			vArea.Parameters.mGuestsWalkInLY = cmCastToNumber(TotalPerDayLY.GuestsCheckedInTurnover);
			vArea.Parameters.mGuestsWalkInPerMonthLY = cmCastToNumber(TotalPerMonthLY.GuestsCheckedInTurnover);
			vArea.Parameters.mGuestsWalkInPerYearLY = cmCastToNumber(TotalPerYearLY.GuestsCheckedInTurnover);
		EndIf;
		pSpreadsheet.Put(vArea);
		
		// 4. Check-out summary indexes
		
		// Put section header
		vArea = vTemplate.GetArea("CheckOutSummaryHeader");
		pSpreadsheet.Put(vArea);
		
		// Run query to get number of checked-out guests
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	CASE
		|		WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
		|				AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) < BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|				AND DATEADD(BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY), DAY, 1) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|			THEN DATEADD(BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY), DAY, 1)
		|		ELSE BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY)
		|	END AS Period,
		|	SUM(CASE
		|			WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
		|					AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|					AND BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY) <= BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|				THEN RoomSalesTurnovers.RoomsRented
		|			WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
		|					AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) < BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|					AND DATEADD(BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY), DAY, 1) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|				THEN RoomSalesTurnovers.RoomsRented
		|			ELSE 0
		|		END) AS RoomsCheckedOutTurnover,
		|	SUM(CASE
		|			WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
		|					AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|					AND BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY) <= BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|				THEN RoomSalesTurnovers.BedsRented
		|			WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
		|					AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) < BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|					AND DATEADD(BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY), DAY, 1) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|				THEN RoomSalesTurnovers.BedsRented
		|			ELSE 0
		|		END) AS BedsCheckedOutTurnover,
		|	SUM(CASE
		|			WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
		|					AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|					AND BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY) <= BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|				THEN RoomSalesTurnovers.GuestDays
		|			WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
		|					AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) < BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|					AND DATEADD(BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY), DAY, 1) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|				THEN RoomSalesTurnovers.GuestDays
		|			ELSE 0
		|		END) AS GuestsCheckedOutTurnover
		|FROM
		|	AccumulationRegister.Sales AS RoomSalesTurnovers
		|WHERE
		|	RoomSalesTurnovers.Period >= &qPeriodFrom
		|	AND RoomSalesTurnovers.Period <= &qPeriodTo
		|	AND NOT RoomSalesTurnovers.IsCorrection
		|	AND RoomSalesTurnovers.Hotel IN HIERARCHY(&qHotel)
		|
		|GROUP BY
		|	CASE
		|		WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
		|				AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) < BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|				AND DATEADD(BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY), DAY, 1) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|			THEN DATEADD(BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY), DAY, 1)
		|		ELSE BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY)
		|	END
		|
		|ORDER BY
		|	Period";
		vQry.SetParameter("qPeriodFrom", pmBegOfYear(PeriodTo) - 24*3600);
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qHotel", vHotel);
		vQryResult = vQry.Execute().Unload();
		
		If ShowPreviousYearData Then
			vQryLY = New Query();
			vQryLY.Text = 
			"SELECT
			|	CASE
			|		WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
			|				AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) < BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
			|				AND DATEADD(BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY), DAY, 1) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
			|			THEN DATEADD(BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY), DAY, 1)
			|		ELSE BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY)
			|	END AS Period,
			|	SUM(CASE
			|			WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
			|					AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
			|					AND BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY) <= BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
			|				THEN RoomSalesTurnovers.RoomsRented
			|			WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
			|					AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) < BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
			|					AND DATEADD(BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY), DAY, 1) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
			|				THEN RoomSalesTurnovers.RoomsRented
			|			ELSE 0
			|		END) AS RoomsCheckedOutTurnover,
			|	SUM(CASE
			|			WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
			|					AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
			|					AND BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY) <= BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
			|				THEN RoomSalesTurnovers.BedsRented
			|			WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
			|					AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) < BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
			|					AND DATEADD(BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY), DAY, 1) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
			|				THEN RoomSalesTurnovers.BedsRented
			|			ELSE 0
			|		END) AS BedsCheckedOutTurnover,
			|	SUM(CASE
			|			WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
			|					AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
			|					AND BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY) <= BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
			|				THEN RoomSalesTurnovers.GuestDays
			|			WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
			|					AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) < BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
			|					AND DATEADD(BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY), DAY, 1) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
			|				THEN RoomSalesTurnovers.GuestDays
			|			ELSE 0
			|		END) AS GuestsCheckedOutTurnover
			|FROM
			|	AccumulationRegister.Sales AS RoomSalesTurnovers
			|WHERE
			|	RoomSalesTurnovers.Period >= &qPeriodFrom
			|	AND RoomSalesTurnovers.Period <= &qPeriodTo
			|	AND NOT RoomSalesTurnovers.IsCorrection
			|	AND RoomSalesTurnovers.Hotel IN HIERARCHY(&qHotel)
			|
			|GROUP BY
			|	CASE
			|		WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
			|				AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) < BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
			|				AND DATEADD(BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY), DAY, 1) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
			|			THEN DATEADD(BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY), DAY, 1)
			|		ELSE BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY)
			|	END
			|
			|ORDER BY
			|	Period";
			vQryLY.SetParameter("qPeriodFrom", pmBegOfYear(PeriodToLY) - 24*3600);
			vQryLY.SetParameter("qPeriodTo", EndOfDay(PeriodToLY));
			vQryLY.SetParameter("qHotel", vHotel);
			vQryResultLY = vQryLY.Execute().Unload();
		EndIf;
		
		// Add forecast guests if period is set in the future
		If BegOfDay(PeriodTo) >= vForecastStartDate And Not DoNotShowForecast Then
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	CASE
			|		WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
			|				AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) < BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
			|				AND DATEADD(BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY), DAY, 1) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
			|			THEN DATEADD(BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY), DAY, 1)
			|		ELSE BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY)
			|	END AS Period,
			|	SUM(CASE
			|			WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
			|					AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
			|					AND BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY) <= BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
			|				THEN RoomSalesTurnovers.RoomsRented
			|			WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
			|					AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) < BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
			|					AND DATEADD(BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY), DAY, 1) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
			|				THEN RoomSalesTurnovers.RoomsRented
			|			ELSE 0
			|		END) AS RoomsCheckedOutTurnover,
			|	SUM(CASE
			|			WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
			|					AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
			|					AND BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY) <= BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
			|				THEN RoomSalesTurnovers.BedsRented
			|			WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
			|					AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) < BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
			|					AND DATEADD(BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY), DAY, 1) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
			|				THEN RoomSalesTurnovers.BedsRented
			|			ELSE 0
			|		END) AS BedsCheckedOutTurnover,
			|	SUM(CASE
			|			WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
			|					AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
			|					AND BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY) <= BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
			|				THEN RoomSalesTurnovers.GuestDays
			|			WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
			|					AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) < BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
			|					AND DATEADD(BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY), DAY, 1) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
			|				THEN RoomSalesTurnovers.GuestDays
			|			ELSE 0
			|		END) AS GuestsCheckedOutTurnover
			|FROM
			|	AccumulationRegister.SalesForecast AS RoomSalesTurnovers
			|WHERE
			|	RoomSalesTurnovers.Period >= &qPeriodFrom
			|	AND RoomSalesTurnovers.Period <= &qPeriodTo
			|	AND RoomSalesTurnovers.Hotel IN HIERARCHY(&qHotel)
			|
			|GROUP BY
			|	CASE
			|		WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
			|				AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) < BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
			|				AND DATEADD(BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY), DAY, 1) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
			|			THEN DATEADD(BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY), DAY, 1)
			|		ELSE BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY)
			|	END
			|
			|ORDER BY
			|	Period";
			vQry.SetParameter("qPeriodFrom", vForecastStartDate - 24*3600);
			vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
			vQry.SetParameter("qHotel", vHotel);
			vForecastQryResult = vQry.Execute().Unload();
			
			// Merge forecast guests with real ones
			For Each vForecastRow In vForecastQryResult Do
				vFound = False;
				For Each vRow In vQryResult Do
					If vRow.Period = vForecastRow.Period Then
						vFound = True;
						Break;
					EndIf;
				EndDo;
				If Not vFound Then
					vRow = vQryResult.Add();
					vRow.Period = vForecastRow.Period;
					vRow.RoomsCheckedOutTurnover = 0;
					vRow.BedsCheckedOutTurnover = 0;
					vRow.GuestsCheckedOutTurnover = 0;
				EndIf;
				vRow.RoomsCheckedOutTurnover = vRow.RoomsCheckedOutTurnover + vForecastRow.RoomsCheckedOutTurnover;
				vRow.BedsCheckedOutTurnover = vRow.BedsCheckedOutTurnover + vForecastRow.BedsCheckedOutTurnover;
				vRow.GuestsCheckedOutTurnover = vRow.GuestsCheckedOutTurnover + vForecastRow.GuestsCheckedOutTurnover;
			EndDo;
		EndIf;	

		GetQryResultTableTotals(vQryResult, vQryResult, "RoomsCheckedOutTurnover, BedsCheckedOutTurnover, GuestsCheckedOutTurnover", False);
		If ShowPreviousYearData Then
			GetQryResultTableTotalsLY(vQryResultLY, vQryResultLY, "RoomsCheckedOutTurnover, BedsCheckedOutTurnover, GuestsCheckedOutTurnover", False);
		EndIf;

		If vInRooms Then
			vArea = vTemplate.GetArea("RoomsCheckedOut");
			vArea.Parameters.mRoomsCheckedOut = cmCastToNumber(TotalPerDay.RoomsCheckedOutTurnover);
			vArea.Parameters.mRoomsCheckedOutPerMonth = cmCastToNumber(TotalPerMonth.RoomsCheckedOutTurnover);
			vArea.Parameters.mRoomsCheckedOutPerYear = cmCastToNumber(TotalPerYear.RoomsCheckedOutTurnover);
			If ShowPreviousYearData Then
				vArea.Parameters.mRoomsCheckedOutLY = cmCastToNumber(TotalPerDayLY.RoomsCheckedOutTurnover);
				vArea.Parameters.mRoomsCheckedOutPerMonthLY = cmCastToNumber(TotalPerMonthLY.RoomsCheckedOutTurnover);
				vArea.Parameters.mRoomsCheckedOutPerYearLY = cmCastToNumber(TotalPerYearLY.RoomsCheckedOutTurnover);
			EndIf;
			pSpreadsheet.Put(vArea);
		Else
			vArea = vTemplate.GetArea("BedsCheckedOut");
			vArea.Parameters.mBedsCheckedOut = cmCastToNumber(TotalPerDay.BedsCheckedOutTurnover);
			vArea.Parameters.mBedsCheckedOutPerMonth = cmCastToNumber(TotalPerMonth.BedsCheckedOutTurnover);
			vArea.Parameters.mBedsCheckedOutPerYear = cmCastToNumber(TotalPerYear.BedsCheckedOutTurnover);
			If ShowPreviousYearData Then
				vArea.Parameters.mBedsCheckedOutLY = cmCastToNumber(TotalPerDayLY.BedsCheckedOutTurnover);
				vArea.Parameters.mBedsCheckedOutPerMonthLY = cmCastToNumber(TotalPerMonthLY.BedsCheckedOutTurnover);
				vArea.Parameters.mBedsCheckedOutPerYearLY = cmCastToNumber(TotalPerYearLY.BedsCheckedOutTurnover);
			EndIf;
			pSpreadsheet.Put(vArea);
		EndIf;

		vArea = vTemplate.GetArea("GuestsCheckedOut");
		vArea.Parameters.mGuestsCheckedOut = cmCastToNumber(TotalPerDay.GuestsCheckedOutTurnover);
		vArea.Parameters.mGuestsCheckedOutPerMonth = cmCastToNumber(TotalPerMonth.GuestsCheckedOutTurnover);
		vArea.Parameters.mGuestsCheckedOutPerYear = cmCastToNumber(TotalPerYear.GuestsCheckedOutTurnover);
		If ShowPreviousYearData Then
			vArea.Parameters.mGuestsCheckedOutLY = cmCastToNumber(TotalPerDayLY.GuestsCheckedOutTurnover);
			vArea.Parameters.mGuestsCheckedOutPerMonthLY = cmCastToNumber(TotalPerMonthLY.GuestsCheckedOutTurnover);
			vArea.Parameters.mGuestsCheckedOutPerYearLY = cmCastToNumber(TotalPerYearLY.GuestsCheckedOutTurnover);
		EndIf;
		pSpreadsheet.Put(vArea);
		
		// 4. pickup data
		
		vArea = vTemplate.GetArea("PickupHeader");
		pSpreadsheet.Put(vArea);
		
		vPickupQry = New Query();
		vPickupQry.Text = 
		"SELECT
		|	PickupDailyData.Period AS Period,
		|	SUM(PickupDailyData.RoomsReserved) AS RoomsReserved,
		|	SUM(PickupDailyData.ComplimentaryRoomsReserved) AS ComplimentaryRoomsReserved,
		|	SUM(PickupDailyData.HouseuseRoomsReserved) AS HouseuseRoomsReserved,
		|	SUM(PickupDailyData.DayuseRoomsReserved) AS DayuseRoomsReserved,
		|	SUM(PickupDailyData.RoomsCancelled) AS RoomsCancelled,
		|	SUM(PickupDailyData.RoomsNoShow) AS RoomsNoShow,
		|	SUM(PickupDailyData.BedsReserved) AS BedsReserved,
		|	SUM(PickupDailyData.DayuseBedsReserved) AS DayuseBedsReserved,
		|	SUM(PickupDailyData.ComplimentaryBedsReserved) AS ComplimentaryBedsReserved,
		|	SUM(PickupDailyData.HouseuseBedsReserved) AS HouseuseBedsReserved,
		|	SUM(PickupDailyData.BedsCancelled) AS BedsCancelled,
		|	SUM(PickupDailyData.BedsNoShow) AS BedsNoShow,
		|	SUM(PickupDailyData.RevenueReserved) AS RevenueReserved,
		|	SUM(PickupDailyData.RevenueCancelled) AS RevenueCancelled,
		|	SUM(PickupDailyData.RevenueNoShow) AS RevenueNoShow
		|FROM
		|	(SELECT
		|		PickupTurnovers.Period AS Period,
		|		PickupTurnovers.RoomRate AS RoomRate,
		|		PickupTurnovers.IsCancel AS IsCancel,
		|		PickupTurnovers.IsNoShow AS IsNoShow,
		|		CASE
		|			WHEN NOT PickupTurnovers.IsCancel
		|				THEN PickupTurnovers.RoomsRentedTurnover
		|			ELSE 0
		|		END AS RoomsReserved,
		|		CASE
		|			WHEN NOT PickupTurnovers.IsCancel
		|					AND ISNULL(PickupTurnovers.RoomRate.IsComplimentary, FALSE)
		|				THEN PickupTurnovers.RoomsRentedTurnover
		|			ELSE 0
		|		END AS ComplimentaryRoomsReserved,
		|		CASE
		|			WHEN NOT PickupTurnovers.IsCancel
		|					AND ISNULL(PickupTurnovers.RoomRate.IsHouseUse, FALSE)
		|				THEN PickupTurnovers.RoomsRentedTurnover
		|			ELSE 0
		|		END AS HouseuseRoomsReserved,
		|		CASE
		|			WHEN NOT PickupTurnovers.IsCancel
		|					AND PickupTurnovers.IsDayuse
		|				THEN PickupTurnovers.RoomsRentedTurnover
		|			ELSE 0
		|		END AS DayuseRoomsReserved,
		|		CASE
		|			WHEN PickupTurnovers.IsCancel
		|				THEN -PickupTurnovers.RoomsRentedTurnover
		|			ELSE 0
		|		END AS RoomsCancelled,
		|		CASE
		|			WHEN PickupTurnovers.IsCancel
		|					AND PickupTurnovers.IsNoShow
		|				THEN -PickupTurnovers.RoomsRentedTurnover
		|			ELSE 0
		|		END AS RoomsNoShow,
		|		CASE
		|			WHEN NOT PickupTurnovers.IsCancel
		|				THEN PickupTurnovers.BedsRentedTurnover
		|			ELSE 0
		|		END AS BedsReserved,
		|		CASE
		|			WHEN NOT PickupTurnovers.IsCancel
		|					AND ISNULL(PickupTurnovers.RoomRate.IsComplimentary, FALSE)
		|				THEN PickupTurnovers.BedsRentedTurnover
		|			ELSE 0
		|		END AS ComplimentaryBedsReserved,
		|		CASE
		|			WHEN NOT PickupTurnovers.IsCancel
		|					AND ISNULL(PickupTurnovers.RoomRate.IsHouseUse, FALSE)
		|				THEN PickupTurnovers.BedsRentedTurnover
		|			ELSE 0
		|		END AS HouseuseBedsReserved,
		|		CASE
		|			WHEN NOT PickupTurnovers.IsCancel
		|					AND PickupTurnovers.IsDayuse
		|				THEN PickupTurnovers.BedsRentedTurnover
		|			ELSE 0
		|		END AS DayuseBedsReserved,
		|		CASE
		|			WHEN PickupTurnovers.IsCancel
		|				THEN -PickupTurnovers.BedsRentedTurnover
		|			ELSE 0
		|		END AS BedsCancelled,
		|		CASE
		|			WHEN PickupTurnovers.IsCancel
		|					AND PickupTurnovers.IsNoShow
		|				THEN -PickupTurnovers.BedsRentedTurnover
		|			ELSE 0
		|		END AS BedsNoShow,
		|		CASE
		|			WHEN NOT PickupTurnovers.IsCancel
		|				THEN CASE
		|						WHEN &qWithVAT
		|							THEN PickupTurnovers.RevenueTurnover
		|						ELSE PickupTurnovers.RevenueWithoutVATTurnover
		|					END
		|			ELSE 0
		|		END AS RevenueReserved,
		|		CASE
		|			WHEN PickupTurnovers.IsCancel
		|				THEN CASE
		|						WHEN &qWithVAT
		|							THEN -PickupTurnovers.RevenueTurnover
		|						ELSE -PickupTurnovers.RevenueWithoutVATTurnover
		|					END
		|			ELSE 0
		|		END AS RevenueCancelled,
		|		CASE
		|			WHEN PickupTurnovers.IsCancel
		|					AND PickupTurnovers.IsNoShow
		|				THEN CASE
		|						WHEN &qWithVAT
		|							THEN -PickupTurnovers.RevenueTurnover
		|						ELSE -PickupTurnovers.RevenueWithoutVATTurnover
		|					END
		|			ELSE 0
		|		END AS RevenueNoShow
		|	FROM
		|		AccumulationRegister.Pickup.Turnovers(
		|				&qPeriodFrom,
		|				&qPeriodTo,
		|				Day,
		|				Hotel IN HIERARCHY (&qHotel)
		|					AND GuestGroup <> VALUE(Catalog.GuestGroups.EmptyRef)) AS PickupTurnovers) AS PickupDailyData
		|
		|GROUP BY
		|	PickupDailyData.Period
		|
		|ORDER BY
		|	Period";
		vPickupQry.SetParameter("qPeriodFrom", pmBegOfYear(PeriodTo));
		vPickupQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vPickupQry.SetParameter("qHotel", vHotel);
		vPickupQry.SetParameter("qWithVAT", vWithVAT);
		vQryResultPickup = vPickupQry.Execute().Unload();
		
		If ShowPreviousYearData Then
			vPickupQryLY = New Query();
			vPickupQryLY.Text = vPickupQry.Text;
			vPickupQryLY.SetParameter("qPeriodFrom", pmBegOfYear(PeriodToLY));
			vPickupQryLY.SetParameter("qPeriodTo", EndOfDay(PeriodToLY));
			vPickupQryLY.SetParameter("qHotel", vHotel);
			vPickupQryLY.SetParameter("qWithVAT", vWithVAT);
			vQryResultPickupLY = vPickupQryLY.Execute().Unload();
		EndIf;
		
		// Put pickup data
		GetQryResultTableTotals(vQryResultPickup, vQryResultPickup, vPickupResources, False);
		If ShowPreviousYearData Then
			GetQryResultTableTotalsLY(vQryResultPickupLY, vQryResultPickupLY, vPickupResources, False);
		EndIf;
		If vInRooms Then
			vArea = vTemplate.GetArea("PickupRooms");
			
			vRoomsReserved = cmCastToNumber(TotalPerDay.RoomsReserved);
			vArea.Parameters.mRoomsReserved = vRoomsReserved;
			vRoomsReservedPerMonth = cmCastToNumber(TotalPerMonth.RoomsReserved);
			vArea.Parameters.mRoomsReservedPerMonth = vRoomsReservedPerMonth;
			vRoomsReservedPerYear = cmCastToNumber(TotalPerYear.RoomsReserved);
			vArea.Parameters.mRoomsReservedPerYear = vRoomsReservedPerYear;
			
			vComplimentaryRoomsReserved = cmCastToNumber(TotalPerDay.ComplimentaryRoomsReserved);
			vArea.Parameters.mComplimentaryRoomsReserved = vComplimentaryRoomsReserved;
			vComplimentaryRoomsReservedPerMonth = cmCastToNumber(TotalPerMonth.ComplimentaryRoomsReserved);
			vArea.Parameters.mComplimentaryRoomsReservedPerMonth = vComplimentaryRoomsReservedPerMonth;
			vComplimentaryRoomsReservedPerYear = cmCastToNumber(TotalPerYear.ComplimentaryRoomsReserved);
			vArea.Parameters.mComplimentaryRoomsReservedPerYear = vComplimentaryRoomsReservedPerYear;
			
			vHouseuseRoomsReserved = cmCastToNumber(TotalPerDay.HouseuseRoomsReserved);
			vArea.Parameters.mHouseuseRoomsReserved = vHouseuseRoomsReserved;
			vHouseuseRoomsReservedPerMonth = cmCastToNumber(TotalPerMonth.HouseuseRoomsReserved);
			vArea.Parameters.mHouseuseRoomsReservedPerMonth = vHouseuseRoomsReservedPerMonth;
			vHouseuseRoomsReservedPerYear = cmCastToNumber(TotalPerYear.HouseuseRoomsReserved);
			vArea.Parameters.mHouseuseRoomsReservedPerYear = vHouseuseRoomsReservedPerYear;
			
			vDayuseRoomsReserved = cmCastToNumber(TotalPerDay.DayuseRoomsReserved);
			vArea.Parameters.mDayuseRoomsReserved = vDayuseRoomsReserved;
			vDayuseRoomsReservedPerMonth = cmCastToNumber(TotalPerMonth.DayuseRoomsReserved);
			vArea.Parameters.mDayuseRoomsReservedPerMonth = vDayuseRoomsReservedPerMonth;
			vDayuseRoomsReservedPerYear = cmCastToNumber(TotalPerYear.DayuseRoomsReserved);
			vArea.Parameters.mDayuseRoomsReservedPerYear = vDayuseRoomsReservedPerYear;
			
			vRoomsCancelled = cmCastToNumber(TotalPerDay.RoomsCancelled);
			vArea.Parameters.mRoomsCancelled = vRoomsCancelled;
			vRoomsCancelledPerMonth = cmCastToNumber(TotalPerMonth.RoomsCancelled);
			vArea.Parameters.mRoomsCancelledPerMonth = vRoomsCancelledPerMonth;
			vRoomsCancelledPerYear = cmCastToNumber(TotalPerYear.RoomsCancelled);
			vArea.Parameters.mRoomsCancelledPerYear = vRoomsCancelledPerYear;
			
			vRoomsNoShow = cmCastToNumber(TotalPerDay.RoomsNoShow);
			vArea.Parameters.mNoShowRooms = vRoomsNoShow;
			vRoomsNoShowPerMonth = cmCastToNumber(TotalPerMonth.RoomsNoShow);
			vArea.Parameters.mNoShowRoomsPerMonth = vRoomsNoShowPerMonth;
			vRoomsNoShowPerYear = cmCastToNumber(TotalPerYear.RoomsNoShow);
			vArea.Parameters.mNoShowRoomsPerYear = vRoomsNoShowPerYear;
			
			vRevenueReserved = cmCastToNumber(TotalPerDay.RevenueReserved);
			vArea.Parameters.mRevenueReserved = vRevenueReserved;
			vRevenueReservedPerMonth = cmCastToNumber(TotalPerMonth.RevenueReserved);
			vArea.Parameters.mRevenueReservedPerMonth = vRevenueReservedPerMonth;
			vRevenueReservedPerYear = cmCastToNumber(TotalPerYear.RevenueReserved);
			vArea.Parameters.mRevenueReservedPerYear = vRevenueReservedPerYear;
			
			vRevenueCancelled = cmCastToNumber(TotalPerDay.RevenueCancelled);
			vArea.Parameters.mRevenueCancelled = vRevenueCancelled;
			vRevenueCancelledPerMonth = cmCastToNumber(TotalPerMonth.RevenueCancelled);
			vArea.Parameters.mRevenueCancelledPerMonth = vRevenueCancelledPerMonth;
			vRevenueCancelledPerYear = cmCastToNumber(TotalPerYear.RevenueCancelled);
			vArea.Parameters.mRevenueCancelledPerYear = vRevenueCancelledPerYear;
			
			vRevenueNoShow = cmCastToNumber(TotalPerDay.RevenueNoShow);
			vArea.Parameters.mNoShowRevenue = vRevenueNoShow;
			vRevenueNoShowPerMonth = cmCastToNumber(TotalPerMonth.RevenueNoShow);
			vArea.Parameters.mNoShowRevenuePerMonth = vRevenueNoShowPerMonth;
			vRevenueNoShowPerYear = cmCastToNumber(TotalPerYear.RevenueNoShow);
			vArea.Parameters.mNoShowRevenuePerYear = vRevenueNoShowPerYear;
			
			If ShowPreviousYearData Then
				vRoomsReservedLY = cmCastToNumber(TotalPerDayLY.RoomsReserved);
				vArea.Parameters.mRoomsReservedLY = vRoomsReservedLY;
				vRoomsReservedPerMonthLY = cmCastToNumber(TotalPerMonthLY.RoomsReserved);
				vArea.Parameters.mRoomsReservedPerMonthLY = vRoomsReservedPerMonthLY;
				vRoomsReservedPerYearLY = cmCastToNumber(TotalPerYearLY.RoomsReserved);
				vArea.Parameters.mRoomsReservedPerYearLY = vRoomsReservedPerYearLY;

				vComplimentaryRoomsReservedLY = cmCastToNumber(TotalPerDayLY.ComplimentaryRoomsReserved);
				vArea.Parameters.mComplimentaryRoomsReservedLY = vComplimentaryRoomsReservedLY;
				vComplimentaryRoomsReservedPerMonthLY = cmCastToNumber(TotalPerMonthLY.ComplimentaryRoomsReserved);
				vArea.Parameters.mComplimentaryRoomsReservedPerMonthLY = vComplimentaryRoomsReservedPerMonthLY;
				vComplimentaryRoomsReservedPerYearLY = cmCastToNumber(TotalPerYearLY.ComplimentaryRoomsReserved);
				vArea.Parameters.mComplimentaryRoomsReservedPerYearLY = vComplimentaryRoomsReservedPerYearLY;

				vHouseuseRoomsReservedLY = cmCastToNumber(TotalPerDayLY.HouseuseRoomsReserved);
				vArea.Parameters.mHouseuseRoomsReservedLY = vHouseuseRoomsReservedLY;
				vHouseuseRoomsReservedPerMonthLY = cmCastToNumber(TotalPerMonthLY.HouseuseRoomsReserved);
				vArea.Parameters.mHouseuseRoomsReservedPerMonthLY = vHouseuseRoomsReservedPerMonthLY;
				vHouseuseRoomsReservedPerYearLY = cmCastToNumber(TotalPerYearLY.HouseuseRoomsReserved);
				vArea.Parameters.mHouseuseRoomsReservedPerYearLY = vHouseuseRoomsReservedPerYearLY;
				
				vDayuseRoomsReservedLY = cmCastToNumber(TotalPerDayLY.DayuseRoomsReserved);
				vArea.Parameters.mDayuseRoomsReservedLY = vDayuseRoomsReservedLY;
				vDayuseRoomsReservedPerMonthLY = cmCastToNumber(TotalPerMonthLY.DayuseRoomsReserved);
				vArea.Parameters.mDayuseRoomsReservedPerMonthLY = vDayuseRoomsReservedPerMonthLY;
				vDayuseRoomsReservedPerYearLY = cmCastToNumber(TotalPerYearLY.DayuseRoomsReserved);
				vArea.Parameters.mDayuseRoomsReservedPerYearLY = vDayuseRoomsReservedPerYearLY;

				vRoomsCancelledLY = cmCastToNumber(TotalPerDayLY.RoomsCancelled);
				vArea.Parameters.mRoomsCancelledLY = vRoomsCancelledLY;
				vRoomsCancelledPerMonthLY = cmCastToNumber(TotalPerMonthLY.RoomsCancelled);
				vArea.Parameters.mRoomsCancelledPerMonthLY = vRoomsCancelledPerMonthLY;
				vRoomsCancelledPerYearLY = cmCastToNumber(TotalPerYearLY.RoomsCancelled);
				vArea.Parameters.mRoomsCancelledPerYearLY = vRoomsCancelledPerYearLY;

				vRoomsNoShowLY = cmCastToNumber(TotalPerDayLY.RoomsNoShow);
				vArea.Parameters.mNoShowRoomsLY = vRoomsNoShowLY;
				vRoomsNoShowPerMonthLY = cmCastToNumber(TotalPerMonthLY.RoomsNoShow);
				vArea.Parameters.mNoShowRoomsPerMonthLY = vRoomsNoShowPerMonthLY;
				vRoomsNoShowPerYearLY = cmCastToNumber(TotalPerYearLY.RoomsNoShow);
				vArea.Parameters.mNoShowRoomsPerYearLY = vRoomsNoShowPerYearLY;
				
				vRevenueReservedLY = cmCastToNumber(TotalPerDayLY.RevenueReserved);
				vArea.Parameters.mRevenueReservedLY = vRevenueReservedLY;
				vRevenueReservedPerMonthLY = cmCastToNumber(TotalPerMonthLY.RevenueReserved);
				vArea.Parameters.mRevenueReservedPerMonthLY = vRevenueReservedPerMonthLY;
				vRevenueReservedPerYearLY = cmCastToNumber(TotalPerYearLY.RevenueReserved);
				vArea.Parameters.mRevenueReservedPerYearLY = vRevenueReservedPerYearLY;
				
				vRevenueCancelledLY = cmCastToNumber(TotalPerDayLY.RevenueCancelled);
				vArea.Parameters.mRevenueCancelledLY = vRevenueCancelledLY;
				vRevenueCancelledPerMonthLY = cmCastToNumber(TotalPerMonthLY.RevenueCancelled);
				vArea.Parameters.mRevenueCancelledPerMonthLY = vRevenueCancelledPerMonthLY;
				vRevenueCancelledPerYearLY = cmCastToNumber(TotalPerYearLY.RevenueCancelled);
				vArea.Parameters.mRevenueCancelledPerYearLY = vRevenueCancelledPerYearLY;
				
				vRevenueNoShowLY = cmCastToNumber(TotalPerDayLY.RevenueNoShow);
				vArea.Parameters.mNoShowRevenueLY = vRevenueNoShowLY;
				vRevenueNoShowPerMonthLY = cmCastToNumber(TotalPerMonthLY.RevenueNoShow);
				vArea.Parameters.mNoShowRevenuePerMonthLY = vRevenueNoShowPerMonthLY;
				vRevenueNoShowPerYearLY = cmCastToNumber(TotalPerYearLY.RevenueNoShow);
				vArea.Parameters.mNoShowRevenuePerYearLY = vRevenueNoShowPerYearLY;
			EndIf;
			
			pSpreadsheet.Put(vArea);
		Else
			vArea = vTemplate.GetArea("PickupBeds");
			
			vBedsReserved = cmCastToNumber(TotalPerDay.BedsReserved);
			vArea.Parameters.mBedsReserved = vBedsReserved;
			vBedsReservedPerMonth = cmCastToNumber(TotalPerMonth.BedsReserved);
			vArea.Parameters.mBedsReservedPerMonth = vBedsReservedPerMonth;
			vBedsReservedPerYear = cmCastToNumber(TotalPerYear.BedsReserved);
			vArea.Parameters.mBedsReservedPerYear = vBedsReservedPerYear;
			
			vComplimentaryBedsReserved = cmCastToNumber(TotalPerDay.ComplimentaryBedsReserved);
			vArea.Parameters.mComplimentaryBedsReserved = vComplimentaryBedsReserved;
			vComplimentaryBedsReservedPerMonth = cmCastToNumber(TotalPerMonth.ComplimentaryBedsReserved);
			vArea.Parameters.mComplimentaryBedsReservedPerMonth = vComplimentaryBedsReservedPerMonth;
			vComplimentaryBedsReservedPerYear = cmCastToNumber(TotalPerYear.ComplimentaryBedsReserved);
			vArea.Parameters.mComplimentaryBedsReservedPerYear = vComplimentaryBedsReservedPerYear;
			
			vHouseuseBedsReserved = cmCastToNumber(TotalPerDay.HouseuseBedsReserved);
			vArea.Parameters.mHouseuseBedsReserved = vHouseuseBedsReserved;
			vHouseuseBedsReservedPerMonth = cmCastToNumber(TotalPerMonth.HouseuseBedsReserved);
			vArea.Parameters.mHouseuseBedsReservedPerMonth = vHouseuseBedsReservedPerMonth;
			vHouseuseBedsReservedPerYear = cmCastToNumber(TotalPerYear.HouseuseBedsReserved);
			vArea.Parameters.mHouseuseBedsReservedPerYear = vHouseuseBedsReservedPerYear;
			
			vDayuseBedsReserved = cmCastToNumber(TotalPerDay.DayuseBedsReserved);
			vArea.Parameters.mDayuseBedsReserved = vDayuseBedsReserved;
			vDayuseBedsReservedPerMonth = cmCastToNumber(TotalPerMonth.DayuseBedsReserved);
			vArea.Parameters.mDayuseBedsReservedPerMonth = vDayuseBedsReservedPerMonth;
			vDayuseBedsReservedPerYear = cmCastToNumber(TotalPerYear.DayuseBedsReserved);
			vArea.Parameters.mDayuseBedsReservedPerYear = vDayuseBedsReservedPerYear;
			
			vBedsCancelled = cmCastToNumber(TotalPerDay.BedsCancelled);
			vArea.Parameters.mBedsCancelled = vBedsCancelled;
			vBedsCancelledPerMonth = cmCastToNumber(TotalPerMonth.BedsCancelled);
			vArea.Parameters.mBedsCancelledPerMonth = vBedsCancelledPerMonth;
			vBedsCancelledPerYear = cmCastToNumber(TotalPerYear.BedsCancelled);
			vArea.Parameters.mBedsCancelledPerYear = vBedsCancelledPerYear;
			
			vBedsNoShow = cmCastToNumber(TotalPerDay.BedsNoShow);
			vArea.Parameters.mNoShowBeds = vBedsNoShow;
			vBedsNoShowPerMonth = cmCastToNumber(TotalPerMonth.BedsNoShow);
			vArea.Parameters.mNoShowBedsPerMonth = vBedsNoShowPerMonth;
			vBedsNoShowPerYear = cmCastToNumber(TotalPerYear.BedsNoShow);
			vArea.Parameters.mNoShowBedsPerYear = vBedsNoShowPerYear;
			
			vRevenueReserved = cmCastToNumber(TotalPerDay.RevenueReserved);
			vArea.Parameters.mRevenueReserved = vRevenueReserved;
			vRevenueReservedPerMonth = cmCastToNumber(TotalPerMonth.RevenueReserved);
			vArea.Parameters.mRevenueReservedPerMonth = vRevenueReservedPerMonth;
			vRevenueReservedPerYear = cmCastToNumber(TotalPerYear.RevenueReserved);
			vArea.Parameters.mRevenueReservedPerYear = vRevenueReservedPerYear;
			
			vRevenueCancelled = cmCastToNumber(TotalPerDay.RevenueCancelled);
			vArea.Parameters.mRevenueCancelled = vRevenueCancelled;
			vRevenueCancelledPerMonth = cmCastToNumber(TotalPerMonth.RevenueCancelled);
			vArea.Parameters.mRevenueCancelledPerMonth = vRevenueCancelledPerMonth;
			vRevenueCancelledPerYear = cmCastToNumber(TotalPerYear.RevenueCancelled);
			vArea.Parameters.mRevenueCancelledPerYear = vRevenueCancelledPerYear;
			
			vRevenueNoShow = cmCastToNumber(TotalPerDay.RevenueNoShow);
			vArea.Parameters.mNoShowRevenue = vRevenueNoShow;
			vRevenueNoShowPerMonth = cmCastToNumber(TotalPerMonth.RevenueNoShow);
			vArea.Parameters.mNoShowRevenuePerMonth = vRevenueNoShowPerMonth;
			vRevenueNoShowPerYear = cmCastToNumber(TotalPerYear.RevenueNoShow);
			vArea.Parameters.mNoShowRevenuePerYear = vRevenueNoShowPerYear;
			
			If ShowPreviousYearData Then
				vBedsReservedLY = cmCastToNumber(TotalPerDayLY.BedsReserved);
				vArea.Parameters.mBedsReservedLY = vBedsReservedLY;
				vBedsReservedPerMonthLY = cmCastToNumber(TotalPerMonthLY.BedsReserved);
				vArea.Parameters.mBedsReservedPerMonthLY = vBedsReservedPerMonthLY;
				vBedsReservedPerYearLY = cmCastToNumber(TotalPerYearLY.BedsReserved);
				vArea.Parameters.mBedsReservedPerYearLY = vBedsReservedPerYearLY;

				vComplimentaryBedsReservedLY = cmCastToNumber(TotalPerDayLY.ComplimentaryBedsReserved);
				vArea.Parameters.mComplimentaryBedsReservedLY = vComplimentaryBedsReservedLY;
				vComplimentaryBedsReservedPerMonthLY = cmCastToNumber(TotalPerMonthLY.ComplimentaryBedsReserved);
				vArea.Parameters.mComplimentaryBedsReservedPerMonthLY = vComplimentaryBedsReservedPerMonthLY;
				vComplimentaryBedsReservedPerYearLY = cmCastToNumber(TotalPerYearLY.ComplimentaryBedsReserved);
				vArea.Parameters.mComplimentaryBedsReservedPerYearLY = vComplimentaryBedsReservedPerYearLY;

				vHouseuseBedsReservedLY = cmCastToNumber(TotalPerDayLY.HouseuseBedsReserved);
				vArea.Parameters.mHouseuseBedsReservedLY = vHouseuseBedsReservedLY;
				vHouseuseBedsReservedPerMonthLY = cmCastToNumber(TotalPerMonthLY.HouseuseBedsReserved);
				vArea.Parameters.mHouseuseBedsReservedPerMonthLY = vHouseuseBedsReservedPerMonthLY;
				vHouseuseBedsReservedPerYearLY = cmCastToNumber(TotalPerYearLY.HouseuseBedsReserved);
				vArea.Parameters.mHouseuseBedsReservedPerYearLY = vHouseuseBedsReservedPerYearLY;

				vDayuseBedsReservedLY = cmCastToNumber(TotalPerDayLY.DayuseBedsReserved);
				vArea.Parameters.mDayuseBedsReservedLY = vDayuseBedsReservedLY;
				vDayuseBedsReservedPerMonthLY = cmCastToNumber(TotalPerMonthLY.DayuseBedsReserved);
				vArea.Parameters.mDayuseBedsReservedPerMonthLY = vDayuseBedsReservedPerMonthLY;
				vDayuseBedsReservedPerYearLY = cmCastToNumber(TotalPerYearLY.DayuseBedsReserved);
				vArea.Parameters.mDayuseBedsReservedPerYearLY = vDayuseBedsReservedPerYearLY;

				vBedsCancelledLY = cmCastToNumber(TotalPerDayLY.BedsCancelled);
				vArea.Parameters.mBedsCancelledLY = vBedsCancelledLY;
				vBedsCancelledPerMonthLY = cmCastToNumber(TotalPerMonthLY.BedsCancelled);
				vArea.Parameters.mBedsCancelledPerMonthLY = vBedsCancelledPerMonthLY;
				vBedsCancelledPerYearLY = cmCastToNumber(TotalPerYearLY.BedsCancelled);
				vArea.Parameters.mBedsCancelledPerYearLY = vBedsCancelledPerYearLY;

				vBedsNoShowLY = cmCastToNumber(TotalPerDayLY.BedsNoShow);
				vArea.Parameters.mNoShowBedsLY = vBedsNoShowLY;
				vBedsNoShowPerMonthLY = cmCastToNumber(TotalPerMonthLY.BedsNoShow);
				vArea.Parameters.mNoShowBedsPerMonthLY = vBedsNoShowPerMonthLY;
				vBedsNoShowPerYearLY = cmCastToNumber(TotalPerYearLY.BedsNoShow);
				vArea.Parameters.mNoShowBedsPerYearLY = vBedsNoShowPerYearLY;
				
				vRevenueReservedLY = cmCastToNumber(TotalPerDayLY.RevenueReserved);
				vArea.Parameters.mRevenueReservedLY = vRevenueReservedLY;
				vRevenueReservedPerMonthLY = cmCastToNumber(TotalPerMonthLY.RevenueReserved);
				vArea.Parameters.mRevenueReservedPerMonthLY = vRevenueReservedPerMonthLY;
				vRevenueReservedPerYearLY = cmCastToNumber(TotalPerYearLY.RevenueReserved);
				vArea.Parameters.mRevenueReservedPerYearLY = vRevenueReservedPerYearLY;
				
				vRevenueCancelledLY = cmCastToNumber(TotalPerDayLY.RevenueCancelled);
				vArea.Parameters.mRevenueCancelledLY = vRevenueCancelledLY;
				vRevenueCancelledPerMonthLY = cmCastToNumber(TotalPerMonthLY.RevenueCancelled);
				vArea.Parameters.mRevenueCancelledPerMonthLY = vRevenueCancelledPerMonthLY;
				vRevenueCancelledPerYearLY = cmCastToNumber(TotalPerYearLY.RevenueCancelled);
				vArea.Parameters.mRevenueCancelledPerYearLY = vRevenueCancelledPerYearLY;
				
				vRevenueNoShowLY = cmCastToNumber(TotalPerDayLY.RevenueNoShow);
				vArea.Parameters.mNoShowRevenueLY = vRevenueNoShowLY;
				vRevenueNoShowPerMonthLY = cmCastToNumber(TotalPerMonthLY.RevenueNoShow);
				vArea.Parameters.mNoShowRevenuePerMonthLY = vRevenueNoShowPerMonthLY;
				vRevenueNoShowPerYearLY = cmCastToNumber(TotalPerYearLY.RevenueNoShow);
				vArea.Parameters.mNoShowRevenuePerYearLY = vRevenueNoShowPerYearLY;
			EndIf;
			
			pSpreadsheet.Put(vArea);
		EndIf;
		
		// 5. Income summary indexes
		
		// Put section header
		vArea = vTemplate.GetArea("IncomeSummaryHeader");
		pSpreadsheet.Put(vArea);
		
		// Put total sales
		vArea = vTemplate.GetArea("RoomsIncome");
		vArea.Parameters.mRoomsIncome = vRoomsIncome;
		vArea.Parameters.mRoomsIncomePerMonth = vRoomsIncomePerMonth;
		vArea.Parameters.mRoomsIncomePerYear = vRoomsIncomePerYear;
		If ShowPreviousYearData Then
			vArea.Parameters.mRoomsIncomeLY = vRoomsIncomeLY;
			vArea.Parameters.mRoomsIncomePerMonthLY = vRoomsIncomePerMonthLY;
			vArea.Parameters.mRoomsIncomePerYearLY = vRoomsIncomePerYearLY;
		EndIf;
		pSpreadsheet.Put(vArea);
		
		vArea = vTemplate.GetArea("OtherIncome");
		vArea.Parameters.mOtherIncome = vOtherIncome;
		vArea.Parameters.mOtherIncomePerMonth = vOtherIncomePerMonth;
		vArea.Parameters.mOtherIncomePerYear = vOtherIncomePerYear;
		If ShowPreviousYearData Then
			vArea.Parameters.mOtherIncomeLY = vOtherIncomeLY;
			vArea.Parameters.mOtherIncomePerMonthLY = vOtherIncomePerMonthLY;
			vArea.Parameters.mOtherIncomePerYearLY = vOtherIncomePerYearLY;
		EndIf;
		pSpreadsheet.Put(vArea);
		
		vSalesTotalsArea = vTemplate.GetArea("TotalIncome");
		vSalesTotalsArea.Parameters.mTotalIncome = vTotalIncome;
		vSalesTotalsArea.Parameters.mTotalIncomePerMonth = vTotalIncomePerMonth;
		vSalesTotalsArea.Parameters.mTotalIncomePerYear = vTotalIncomePerYear;
		If ShowPreviousYearData Then
			vSalesTotalsArea.Parameters.mTotalIncomeLY = vTotalIncomeLY;
			vSalesTotalsArea.Parameters.mTotalIncomePerMonthLY = vTotalIncomePerMonthLY;
			vSalesTotalsArea.Parameters.mTotalIncomePerYearLY = vTotalIncomePerYearLY;
		EndIf;
		pSpreadsheet.Put(vSalesTotalsArea);
		
		// Put sales by service types
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	ServiceSales.Period AS Period,
		|	ServiceSales.ServiceType AS ServiceType,
		|	ServiceSales.ServiceType.SortCode AS ServiceTypeSortCode,
		|	ServiceSales.ServiceType.Description AS ServiceTypeDescription,
		|	SUM(ServiceSales.SumTurnover) AS SumTurnover,
		|	SUM(ServiceSales.SumWithoutVATTurnover) AS SumWithoutVATTurnover
		|FROM
		|	(SELECT
		|		ServiceSalesTurnovers.Period AS Period,
		|		ISNULL(ServiceSalesTurnovers.Service.ServiceType, &qEmptyServiceType) AS ServiceType,
		|		ServiceSalesTurnovers.SalesTurnover AS SumTurnover,
		|		ServiceSalesTurnovers.SalesWithoutVATTurnover AS SumWithoutVATTurnover
		|	FROM
		|		AccumulationRegister.Sales.Turnovers(
		|				&qPeriodFrom,
		|				&qPeriodTo,
		|				Day,
		|				NOT IsCorrection
		|					AND Hotel IN HIERARCHY (&qHotel)) AS ServiceSalesTurnovers
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ServiceSalesForecastTurnovers.Period,
		|		ISNULL(ServiceSalesForecastTurnovers.Service.ServiceType, &qEmptyServiceType),
		|		ServiceSalesForecastTurnovers.SalesTurnover,
		|		ServiceSalesForecastTurnovers.SalesWithoutVATTurnover
		|	FROM
		|		AccumulationRegister.SalesForecast.Turnovers(&qForecastPeriodFrom, &qForecastPeriodTo, Day, NOT &qDoNotShowForecast AND Hotel IN HIERARCHY (&qHotel)) AS ServiceSalesForecastTurnovers) AS ServiceSales
		|
		|GROUP BY
		|	ServiceSales.Period,
		|	ServiceSales.ServiceType,
		|	ServiceSales.ServiceType.SortCode,
		|	ServiceSales.ServiceType.Description
		|
		|ORDER BY
		|	Period,
		|	ServiceTypeSortCode,
		|	ServiceTypeDescription";
		vQry.SetParameter("qPeriodFrom", pmBegOfYear(PeriodTo));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qForecastPeriodFrom", vForecastStartDate);
		vQry.SetParameter("qForecastPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qHotel", vHotel);
		vQry.SetParameter("qEmptyServiceType", Catalogs.ServiceTypes.EmptyRef());
		vQry.SetParameter("qDoNotShowForecast", DoNotShowForecast);
		vQryResult = vQry.Execute().Unload();
		
		// Get list of service types
		vServiceTypes = vQryResult.Copy();
		vServiceTypes.GroupBy("ServiceType, ServiceTypeSortCode, ServiceTypeDescription", );
		vServiceTypes.Sort("ServiceTypeSortCode, ServiceTypeDescription");
		
		If ShowPreviousYearData Then
			vQryLY = New Query();
			vQryLY.Text = 
			"SELECT
			|	ServiceSales.Period AS Period,
			|	ServiceSales.ServiceType AS ServiceType,
			|	ServiceSales.ServiceType.SortCode AS ServiceTypeSortCode,
			|	ServiceSales.ServiceType.Description AS ServiceTypeDescription,
			|	SUM(ServiceSales.SumTurnover) AS SumTurnover,
			|	SUM(ServiceSales.SumWithoutVATTurnover) AS SumWithoutVATTurnover
			|FROM
			|	(SELECT
			|		ServiceSalesTurnovers.Period AS Period,
			|		ISNULL(ServiceSalesTurnovers.Service.ServiceType, &qEmptyServiceType) AS ServiceType,
			|		ServiceSalesTurnovers.SalesTurnover AS SumTurnover,
			|		ServiceSalesTurnovers.SalesWithoutVATTurnover AS SumWithoutVATTurnover
			|	FROM
			|		AccumulationRegister.Sales.Turnovers(
			|				&qPeriodFrom,
			|				&qPeriodTo,
			|				Day,
			|				NOT IsCorrection
			|					AND Hotel IN HIERARCHY (&qHotel)) AS ServiceSalesTurnovers) AS ServiceSales
			|
			|GROUP BY
			|	ServiceSales.Period,
			|	ServiceSales.ServiceType,
			|	ServiceSales.ServiceType.SortCode,
			|	ServiceSales.ServiceType.Description
			|
			|ORDER BY
			|	Period,
			|	ServiceTypeSortCode,
			|	ServiceTypeDescription";
			vQryLY.SetParameter("qPeriodFrom", pmBegOfYear(PeriodToLY));
			vQryLY.SetParameter("qPeriodTo", EndOfDay(PeriodToLY));
			vQryLY.SetParameter("qHotel", vHotel);
			vQryLY.SetParameter("qEmptyServiceType", Catalogs.ServiceTypes.EmptyRef());
			vQryResultLY = vQryLY.Execute().Unload();
			
			// Get list of service types
			vServiceTypesLY = vQryResultLY.Copy();
			vServiceTypesLY.GroupBy("ServiceType, ServiceTypeSortCode, ServiceTypeDescription", );
			vServiceTypesLY.Sort("ServiceTypeSortCode, ServiceTypeDescription");
			
			// Add rows of last year service types to the list of current ones
			For Each vSTRowLY In vServiceTypesLY Do
				If vServiceTypes.Find(vSTRowLY.ServiceType, "ServiceType") = Undefined Then
					vSTRow = vServiceTypes.Add();
					vSTRow.ServiceType = vSTRowLY.ServiceType;
					vQRRow = vQryResult.Add();
					vQRRow.ServiceType = vSTRowLY.ServiceType;
				EndIf;
			EndDo;
			For Each vSTRow In vServiceTypes Do
				If vServiceTypesLY.Find(vSTRow.ServiceType, "ServiceType") = Undefined Then
					vSTRowLY = vServiceTypesLY.Add();
					vSTRowLY.ServiceType = vSTRow.ServiceType;
					vQRRowLY = vQryResultLY.Add();
					vQRRowLY.ServiceType = vSTRow.ServiceType;
				EndIf;
			EndDo;
		EndIf;
		
		If vServiceTypes.Count() > 1 Then
			vArea = vTemplate.GetArea("ServiceTypeHeader");
			pSpreadsheet.Put(vArea);
			
			vArea = vTemplate.GetArea("ServiceTypeIncome");
			
			// Put service types summary
			For Each vRow In vServiceTypes Do
				vServiceType = vRow.ServiceType;
				vArea.Parameters.mServiceType = ?(ValueIsFilled(vServiceType), vServiceType, NStr("en = '<Not specified>'; de = '<Nicht angegeben>'; ru = '<Не указан>'"));
				
				// Get records for the current payment method only
				vQrySubresult = vQryResult.FindRows(New Structure("ServiceType", vServiceType));
				GetQryResultTableTotals(vQrySubresult, vQryResult, "SumTurnover, SumWithoutVATTurnover", False);
				If ShowPreviousYearData Then
					vRowLY = vServiceTypesLY.Find(vServiceType, "ServiceType");
					vQrySubresultLY = vQryResultLY.FindRows(New Structure("ServiceType", vServiceType));
					GetQryResultTableTotalsLY(vQrySubresultLY, vQryResultLY, "SumTurnover, SumWithoutVATTurnover", False);
				EndIf;
				
				If vWithVAT Then
					vArea.Parameters.mServiceTypeIncome = cmCastToNumber(TotalPerDay.SumTurnover);
					vArea.Parameters.mServiceTypeIncomePerMonth = cmCastToNumber(TotalPerMonth.SumTurnover);
					vArea.Parameters.mServiceTypeIncomePerYear = cmCastToNumber(TotalPerYear.SumTurnover);
					If ShowPreviousYearData Then
						vArea.Parameters.mServiceTypeIncomeLY = cmCastToNumber(TotalPerDayLY.SumTurnover);
						vArea.Parameters.mServiceTypeIncomePerMonthLY = cmCastToNumber(TotalPerMonthLY.SumTurnover);
						vArea.Parameters.mServiceTypeIncomePerYearLY = cmCastToNumber(TotalPerYearLY.SumTurnover);
					EndIf;
				Else
					vArea.Parameters.mServiceTypeIncome = cmCastToNumber(TotalPerDay.SumWithoutVATTurnover);
					vArea.Parameters.mServiceTypeIncomePerMonth = cmCastToNumber(TotalPerMonth.SumWithoutVATTurnover);
					vArea.Parameters.mServiceTypeIncomePerYear = cmCastToNumber(TotalPerYear.SumWithoutVATTurnover);
					If ShowPreviousYearData Then
						vArea.Parameters.mServiceTypeIncomeLY = cmCastToNumber(TotalPerDayLY.SumWithoutVATTurnover);
						vArea.Parameters.mServiceTypeIncomePerMonthLY = cmCastToNumber(TotalPerMonthLY.SumWithoutVATTurnover);
						vArea.Parameters.mServiceTypeIncomePerYearLY = cmCastToNumber(TotalPerYearLY.SumWithoutVATTurnover);
					EndIf;
				EndIf;
				
				pSpreadsheet.Put(vArea);
			EndDo;
			
			pSpreadsheet.Put(vSalesTotalsArea);
		EndIf;
		
		// Put sales by source of business
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	ServiceSales.Period AS Period,
		|	ServiceSales.SourceOfBusiness AS SourceOfBusiness,
		|	ServiceSales.SourceOfBusiness.SortCode AS SourceOfBusinessSortCode,
		|	ServiceSales.SourceOfBusiness.Description AS SourceOfBusinessDescription,
		|	SUM(ServiceSales.SumTurnover) AS SumTurnover,
		|	SUM(ServiceSales.SumWithoutVATTurnover) AS SumWithoutVATTurnover,
		|	SUM(ServiceSales.RoomsRentedTurnover) AS RoomsRentedTurnover,
		|	SUM(ServiceSales.BedsRentedTurnover) AS BedsRentedTurnover,
		|	SUM(ServiceSales.GuestDaysTurnover) AS GuestDaysTurnover,
		|	SUM(ServiceSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
		|FROM
		|	(SELECT
		|		ServiceSalesTurnovers.Period AS Period,
		|		ServiceSalesTurnovers.SourceOfBusiness AS SourceOfBusiness,
		|		ServiceSalesTurnovers.SalesTurnover AS SumTurnover,
		|		ServiceSalesTurnovers.SalesWithoutVATTurnover AS SumWithoutVATTurnover,
		|		ServiceSalesTurnovers.RoomsRentedTurnover AS RoomsRentedTurnover,
		|		ServiceSalesTurnovers.BedsRentedTurnover AS BedsRentedTurnover,
		|		ServiceSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover,
		|		ServiceSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover
		|	FROM
		|		AccumulationRegister.Sales.Turnovers(
		|				&qPeriodFrom,
		|				&qPeriodTo,
		|				Day,
		|				NOT IsCorrection
		|					AND Hotel IN HIERARCHY (&qHotel)) AS ServiceSalesTurnovers
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ServiceSalesForecastTurnovers.Period,
		|		ServiceSalesForecastTurnovers.SourceOfBusiness,
		|		ServiceSalesForecastTurnovers.SalesTurnover,
		|		ServiceSalesForecastTurnovers.SalesWithoutVATTurnover,
		|		ServiceSalesForecastTurnovers.RoomsRentedTurnover,
		|		ServiceSalesForecastTurnovers.BedsRentedTurnover,
		|		ServiceSalesForecastTurnovers.GuestDaysTurnover,
		|		ServiceSalesForecastTurnovers.GuestsCheckedInTurnover
		|	FROM
		|		AccumulationRegister.SalesForecast.Turnovers(
		|				&qForecastPeriodFrom,
		|				&qForecastPeriodTo,
		|				Day,
		|				NOT &qDoNotShowForecast
		|					AND Hotel IN HIERARCHY (&qHotel)) AS ServiceSalesForecastTurnovers) AS ServiceSales
		|
		|GROUP BY
		|	ServiceSales.Period,
		|	ServiceSales.SourceOfBusiness,
		|	ServiceSales.SourceOfBusiness.SortCode,
		|	ServiceSales.SourceOfBusiness.Description
		|
		|ORDER BY
		|	Period,
		|	SourceOfBusinessSortCode,
		|	SourceOfBusinessDescription";
		vQry.SetParameter("qPeriodFrom", pmBegOfYear(PeriodTo));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qForecastPeriodFrom", vForecastStartDate);
		vQry.SetParameter("qForecastPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qHotel", vHotel);
		vQry.SetParameter("qDoNotShowForecast", DoNotShowForecast);
		vQryResult = vQry.Execute().Unload();
		
		// Get list of sources
		vSourceOfBusinesses = vQryResult.Copy();
		vSourceOfBusinesses.GroupBy("SourceOfBusiness, SourceOfBusinessSortCode, SourceOfBusinessDescription", );
		vSourceOfBusinesses.Sort("SourceOfBusinessSortCode, SourceOfBusinessDescription");
		
		If ShowPreviousYearData Then
			vQryLY = New Query();
			vQryLY.Text = 
			"SELECT
			|	ServiceSales.Period AS Period,
			|	ServiceSales.SourceOfBusiness AS SourceOfBusiness,
			|	ServiceSales.SourceOfBusiness.SortCode AS SourceOfBusinessSortCode,
			|	ServiceSales.SourceOfBusiness.Description AS SourceOfBusinessDescription,
			|	SUM(ServiceSales.SumTurnover) AS SumTurnover,
			|	SUM(ServiceSales.SumWithoutVATTurnover) AS SumWithoutVATTurnover,
			|	SUM(ServiceSales.RoomsRentedTurnover) AS RoomsRentedTurnover,
			|	SUM(ServiceSales.BedsRentedTurnover) AS BedsRentedTurnover,
			|	SUM(ServiceSales.GuestDaysTurnover) AS GuestDaysTurnover,
			|	SUM(ServiceSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
			|FROM
			|	(SELECT
			|		ServiceSalesTurnovers.Period AS Period,
			|		ServiceSalesTurnovers.SourceOfBusiness AS SourceOfBusiness,
			|		ServiceSalesTurnovers.SalesTurnover AS SumTurnover,
			|		ServiceSalesTurnovers.SalesWithoutVATTurnover AS SumWithoutVATTurnover,
			|		ServiceSalesTurnovers.RoomsRentedTurnover AS RoomsRentedTurnover,
			|		ServiceSalesTurnovers.BedsRentedTurnover AS BedsRentedTurnover,
			|		ServiceSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover,
			|		ServiceSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover
			|	FROM
			|		AccumulationRegister.Sales.Turnovers(
			|				&qPeriodFrom,
			|				&qPeriodTo,
			|				Day,
			|				NOT IsCorrection
			|					AND Hotel IN HIERARCHY (&qHotel)) AS ServiceSalesTurnovers) AS ServiceSales
			|
			|GROUP BY
			|	ServiceSales.Period,
			|	ServiceSales.SourceOfBusiness,
			|	ServiceSales.SourceOfBusiness.SortCode,
			|	ServiceSales.SourceOfBusiness.Description
			|
			|ORDER BY
			|	Period,
			|	SourceOfBusinessSortCode,
			|	SourceOfBusinessDescription";
			vQryLY.SetParameter("qPeriodFrom", pmBegOfYear(PeriodToLY));
			vQryLY.SetParameter("qPeriodTo", EndOfDay(PeriodToLY));
			vQryLY.SetParameter("qHotel", vHotel);
			vQryResultLY = vQryLY.Execute().Unload();
			
			// Get list of service types
			vSourceOfBusinessesLY = vQryResultLY.Copy();
			vSourceOfBusinessesLY.GroupBy("SourceOfBusiness, SourceOfBusinessSortCode, SourceOfBusinessDescription", );
			vSourceOfBusinessesLY.Sort("SourceOfBusinessSortCode, SourceOfBusinessDescription");
			
			// Add rows of last year service types to the list of current ones
			For Each vSTRowLY In vSourceOfBusinessesLY Do
				If vSourceOfBusinesses.Find(vSTRowLY.SourceOfBusiness, "SourceOfBusiness") = Undefined Then
					vSTRow = vSourceOfBusinesses.Add();
					vSTRow.SourceOfBusiness = vSTRowLY.SourceOfBusiness;
					vQRRow = vQryResult.Add();
					vQRRow.SourceOfBusiness = vSTRowLY.SourceOfBusiness;
				EndIf;
			EndDo;
			For Each vSTRow In vSourceOfBusinesses Do
				If vSourceOfBusinessesLY.Find(vSTRow.SourceOfBusiness, "SourceOfBusiness") = Undefined Then
					vSTRowLY = vSourceOfBusinessesLY.Add();
					vSTRowLY.SourceOfBusiness = vSTRow.SourceOfBusiness;
					vQRRowLY = vQryResultLY.Add();
					vQRRowLY.SourceOfBusiness = vSTRow.SourceOfBusiness;
				EndIf;
			EndDo;
		EndIf;
		
		If vSourceOfBusinesses.Count() > 1 Then
			vArea = vTemplate.GetArea("SourceOfBusinessHeader");
			pSpreadsheet.Put(vArea);
			
			vArea = vTemplate.GetArea("SourceOfBusinessIncome");
			
			// Put service types summary
			For Each vRow In vSourceOfBusinesses Do
				vSourceOfBusiness = vRow.SourceOfBusiness;
				vArea.Parameters.mSourceOfBusiness = ?(ValueIsFilled(vSourceOfBusiness), vSourceOfBusiness, NStr("en = '<Not specified>'; de = '<Nicht angegeben>'; ru = '<Не указан>'"));
				
				// Get records for the current payment method only
				vQrySubresult = vQryResult.FindRows(New Structure("SourceOfBusiness", vSourceOfBusiness));
				GetQryResultTableTotals(vQrySubresult, vQryResult, "SumTurnover, SumWithoutVATTurnover", False);
				If ShowPreviousYearData Then
					vRowLY = vSourceOfBusinessesLY.Find(vSourceOfBusiness, "SourceOfBusiness");
					vQrySubresultLY = vQryResultLY.FindRows(New Structure("SourceOfBusiness", vSourceOfBusiness));
					GetQryResultTableTotalsLY(vQrySubresultLY, vQryResultLY, "SumTurnover, SumWithoutVATTurnover", False);
				EndIf;
				
				If vWithVAT Then
					vArea.Parameters.mSourceOfBusinessIncome = cmCastToNumber(TotalPerDay.SumTurnover);
					vArea.Parameters.mSourceOfBusinessIncomePerMonth = cmCastToNumber(TotalPerMonth.SumTurnover);
					vArea.Parameters.mSourceOfBusinessIncomePerYear = cmCastToNumber(TotalPerYear.SumTurnover);
					If ShowPreviousYearData Then
						vArea.Parameters.mSourceOfBusinessIncomeLY = cmCastToNumber(TotalPerDayLY.SumTurnover);
						vArea.Parameters.mSourceOfBusinessIncomePerMonthLY = cmCastToNumber(TotalPerMonthLY.SumTurnover);
						vArea.Parameters.mSourceOfBusinessIncomePerYearLY = cmCastToNumber(TotalPerYearLY.SumTurnover);
					EndIf;
				Else
					vArea.Parameters.mSourceOfBusinessIncome = cmCastToNumber(TotalPerDay.SumWithoutVATTurnover);
					vArea.Parameters.mSourceOfBusinessIncomePerMonth = cmCastToNumber(TotalPerMonth.SumWithoutVATTurnover);
					vArea.Parameters.mSourceOfBusinessIncomePerYear = cmCastToNumber(TotalPerYear.SumWithoutVATTurnover);
					If ShowPreviousYearData Then
						vArea.Parameters.mSourceOfBusinessIncomeLY = cmCastToNumber(TotalPerDayLY.SumWithoutVATTurnover);
						vArea.Parameters.mSourceOfBusinessIncomePerMonthLY = cmCastToNumber(TotalPerMonthLY.SumWithoutVATTurnover);
						vArea.Parameters.mSourceOfBusinessIncomePerYearLY = cmCastToNumber(TotalPerYearLY.SumWithoutVATTurnover);
					EndIf;
				EndIf;
				
				pSpreadsheet.Put(vArea);
			EndDo;
			
			pSpreadsheet.Put(vSalesTotalsArea);
		EndIf;
		
		// Put sales by marketing codes
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	ServiceSales.Period AS Period,
		|	ServiceSales.MarketingCode AS MarketingCode,
		|	ServiceSales.MarketingCode.SortCode AS MarketingCodeSortCode,
		|	ServiceSales.MarketingCode.Description AS MarketingCodeDescription,
		|	SUM(ServiceSales.SumTurnover) AS SumTurnover,
		|	SUM(ServiceSales.SumWithoutVATTurnover) AS SumWithoutVATTurnover
		|FROM
		|	(SELECT
		|		ServiceSalesTurnovers.Period AS Period,
		|		ServiceSalesTurnovers.MarketingCode AS MarketingCode,
		|		ServiceSalesTurnovers.SalesTurnover AS SumTurnover,
		|		ServiceSalesTurnovers.SalesWithoutVATTurnover AS SumWithoutVATTurnover
		|	FROM
		|		AccumulationRegister.Sales.Turnovers(
		|				&qPeriodFrom,
		|				&qPeriodTo,
		|				Day,
		|				NOT IsCorrection
		|					AND Hotel IN HIERARCHY (&qHotel)) AS ServiceSalesTurnovers
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ServiceSalesForecastTurnovers.Period,
		|		ServiceSalesForecastTurnovers.MarketingCode,
		|		ServiceSalesForecastTurnovers.SalesTurnover,
		|		ServiceSalesForecastTurnovers.SalesWithoutVATTurnover
		|	FROM
		|		AccumulationRegister.SalesForecast.Turnovers(&qForecastPeriodFrom, &qForecastPeriodTo, Day, NOT &qDoNotShowForecast AND Hotel IN HIERARCHY (&qHotel)) AS ServiceSalesForecastTurnovers) AS ServiceSales
		|
		|GROUP BY
		|	ServiceSales.Period,
		|	ServiceSales.MarketingCode,
		|	ServiceSales.MarketingCode.SortCode,
		|	ServiceSales.MarketingCode.Description
		|
		|ORDER BY
		|	Period,
		|	MarketingCodeSortCode,
		|	MarketingCodeDescription";
		vQry.SetParameter("qPeriodFrom", pmBegOfYear(PeriodTo));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qForecastPeriodFrom", vForecastStartDate);
		vQry.SetParameter("qForecastPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qHotel", vHotel);
		vQry.SetParameter("qDoNotShowForecast", DoNotShowForecast);
		vQryResult = vQry.Execute().Unload();
		
		// Get list of marketing codes
		vMarketingCodes = vQryResult.Copy();
		vMarketingCodes.GroupBy("MarketingCode, MarketingCodeSortCode, MarketingCodeDescription", );
		vMarketingCodes.Sort("MarketingCodeSortCode, MarketingCodeDescription");
		
		If ShowPreviousYearData Then
			vQryLY = New Query();
			vQryLY.Text = 
			"SELECT
			|	ServiceSales.Period AS Period,
			|	ServiceSales.MarketingCode AS MarketingCode,
			|	ServiceSales.MarketingCode.SortCode AS MarketingCodeSortCode,
			|	ServiceSales.MarketingCode.Description AS MarketingCodeDescription,
			|	SUM(ServiceSales.SumTurnover) AS SumTurnover,
			|	SUM(ServiceSales.SumWithoutVATTurnover) AS SumWithoutVATTurnover
			|FROM
			|	(SELECT
			|		ServiceSalesTurnovers.Period AS Period,
			|		ServiceSalesTurnovers.MarketingCode AS MarketingCode,
			|		ServiceSalesTurnovers.SalesTurnover AS SumTurnover,
			|		ServiceSalesTurnovers.SalesWithoutVATTurnover AS SumWithoutVATTurnover
			|	FROM
			|		AccumulationRegister.Sales.Turnovers(
			|				&qPeriodFrom,
			|				&qPeriodTo,
			|				Day,
			|				NOT IsCorrection
			|					AND Hotel IN HIERARCHY (&qHotel)) AS ServiceSalesTurnovers) AS ServiceSales
			|
			|GROUP BY
			|	ServiceSales.Period,
			|	ServiceSales.MarketingCode,
			|	ServiceSales.MarketingCode.SortCode,
			|	ServiceSales.MarketingCode.Description
			|
			|ORDER BY
			|	Period,
			|	MarketingCodeSortCode,
			|	MarketingCodeDescription";
			vQryLY.SetParameter("qPeriodFrom", pmBegOfYear(PeriodToLY));
			vQryLY.SetParameter("qPeriodTo", EndOfDay(PeriodToLY));
			vQryLY.SetParameter("qHotel", vHotel);
			vQryResultLY = vQryLY.Execute().Unload();
			
			// Get list of service types
			vMarketingCodesLY = vQryResultLY.Copy();
			vMarketingCodesLY.GroupBy("MarketingCode, MarketingCodeSortCode, MarketingCodeDescription", );
			vMarketingCodesLY.Sort("MarketingCodeSortCode, MarketingCodeDescription");
			
			// Add rows of last year service types to the list of current ones
			For Each vSTRowLY In vMarketingCodesLY Do
				If vMarketingCodes.Find(vSTRowLY.MarketingCode, "MarketingCode") = Undefined Then
					vSTRow = vMarketingCodes.Add();
					vSTRow.MarketingCode = vSTRowLY.MarketingCode;
					vQRRow = vQryResult.Add();
					vQRRow.MarketingCode = vSTRowLY.MarketingCode;
				EndIf;
			EndDo;
			For Each vSTRow In vMarketingCodes Do
				If vMarketingCodesLY.Find(vSTRow.MarketingCode, "MarketingCode") = Undefined Then
					vSTRowLY = vMarketingCodesLY.Add();
					vSTRowLY.MarketingCode = vSTRow.MarketingCode;
					vQRRowLY = vQryResultLY.Add();
					vQRRowLY.MarketingCode = vSTRow.MarketingCode;
				EndIf;
			EndDo;
		EndIf;
		
		If vMarketingCodes.Count() > 1 Then
			vArea = vTemplate.GetArea("MarketingCodeHeader");
			pSpreadsheet.Put(vArea);
			
			vArea = vTemplate.GetArea("MarketingCodeIncome");
			
			// Put service types summary
			For Each vRow In vMarketingCodes Do
				vMarketingCode = vRow.MarketingCode;
				vArea.Parameters.mMarketingCode = ?(ValueIsFilled(vMarketingCode), vMarketingCode, NStr("en = '<Not specified>'; de = '<Nicht angegeben>'; ru = '<Не указан>'"));
				
				// Get records for the current payment method only
				vQrySubresult = vQryResult.FindRows(New Structure("MarketingCode", vMarketingCode));
				GetQryResultTableTotals(vQrySubresult, vQryResult, "SumTurnover, SumWithoutVATTurnover", False);
				If ShowPreviousYearData Then
					vRowLY = vMarketingCodesLY.Find(vMarketingCode, "MarketingCode");
					vQrySubresultLY = vQryResultLY.FindRows(New Structure("MarketingCode", vMarketingCode));
					GetQryResultTableTotalsLY(vQrySubresultLY, vQryResultLY, "SumTurnover, SumWithoutVATTurnover", False);
				EndIf;
				
				If vWithVAT Then
					vArea.Parameters.mMarketingCodeIncome = cmCastToNumber(TotalPerDay.SumTurnover);
					vArea.Parameters.mMarketingCodeIncomePerMonth = cmCastToNumber(TotalPerMonth.SumTurnover);
					vArea.Parameters.mMarketingCodeIncomePerYear = cmCastToNumber(TotalPerYear.SumTurnover);
					If ShowPreviousYearData Then
						vArea.Parameters.mMarketingCodeIncomeLY = cmCastToNumber(TotalPerDayLY.SumTurnover);
						vArea.Parameters.mMarketingCodeIncomePerMonthLY = cmCastToNumber(TotalPerMonthLY.SumTurnover);
						vArea.Parameters.mMarketingCodeIncomePerYearLY = cmCastToNumber(TotalPerYearLY.SumTurnover);
					EndIf;
				Else
					vArea.Parameters.mMarketingCodeIncome = cmCastToNumber(TotalPerDay.SumWithoutVATTurnover);
					vArea.Parameters.mMarketingCodeIncomePerMonth = cmCastToNumber(TotalPerMonth.SumWithoutVATTurnover);
					vArea.Parameters.mMarketingCodeIncomePerYear = cmCastToNumber(TotalPerYear.SumWithoutVATTurnover);
					If ShowPreviousYearData Then
						vArea.Parameters.mMarketingCodeIncomeLY = cmCastToNumber(TotalPerDayLY.SumWithoutVATTurnover);
						vArea.Parameters.mMarketingCodeIncomePerMonthLY = cmCastToNumber(TotalPerMonthLY.SumWithoutVATTurnover);
						vArea.Parameters.mMarketingCodeIncomePerYearLY = cmCastToNumber(TotalPerYearLY.SumWithoutVATTurnover);
					EndIf;
				EndIf;
				
				pSpreadsheet.Put(vArea);
			EndDo;

			pSpreadsheet.Put(vSalesTotalsArea);
		EndIf;
		
		// Put sales by loyalty types in the hotel loyalty program
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	ServiceSales.Period AS Period,
		|	CASE
		|		WHEN ServiceSales.LoyaltyType IS NULL
		|			THEN VALUE(Catalog.DiscountTypes.EmptyRef)
		|		ELSE ServiceSales.LoyaltyType
		|	END AS LoyaltyType,
		|	CASE
		|		WHEN ServiceSales.LoyaltyType.SortCode IS NULL
		|			THEN 999999
		|		ELSE ServiceSales.LoyaltyType.SortCode
		|	END AS LoyaltyTypeSortCode,
		|	CASE
		|		WHEN ServiceSales.LoyaltyType.Description IS NULL
		|			THEN ""NOT LOYALTY PROGRAM MEMBER""
		|		ELSE ServiceSales.LoyaltyType.Description
		|	END AS LoyaltyTypeDescription,
		|	SUM(ServiceSales.SumTurnover) AS SumTurnover,
		|	SUM(ServiceSales.SumWithoutVATTurnover) AS SumWithoutVATTurnover,
		|	SUM(ServiceSales.RoomsRentedTurnover) AS RoomsRentedTurnover,
		|	SUM(ServiceSales.BedsRentedTurnover) AS BedsRentedTurnover,
		|	SUM(ServiceSales.GuestDaysTurnover) AS GuestDaysTurnover,
		|	SUM(ServiceSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
		|FROM
		|	(SELECT
		|		ServiceSalesTurnovers.Period AS Period,
		|		CASE
		|			WHEN ServiceSalesTurnovers.Hotel.LoyaltyProgram = ServiceSalesTurnovers.DiscountType
		|					AND ServiceSalesTurnovers.DiscountType <> VALUE(Catalog.DiscountTypes.EmptyRef)
		|				THEN ServiceSalesTurnovers.DiscountType
		|			WHEN ServiceSalesTurnovers.Hotel.LoyaltyProgram = ServiceSalesTurnovers.DiscountType.Parent
		|					AND ServiceSalesTurnovers.DiscountType <> VALUE(Catalog.DiscountTypes.EmptyRef)
		|					AND ServiceSalesTurnovers.DiscountType.Parent <> VALUE(Catalog.DiscountTypes.EmptyRef)
		|				THEN ServiceSalesTurnovers.DiscountType
		|			ELSE NULL
		|		END AS LoyaltyType,
		|		ServiceSalesTurnovers.SalesTurnover AS SumTurnover,
		|		ServiceSalesTurnovers.SalesWithoutVATTurnover AS SumWithoutVATTurnover,
		|		ServiceSalesTurnovers.RoomsRentedTurnover AS RoomsRentedTurnover,
		|		ServiceSalesTurnovers.BedsRentedTurnover AS BedsRentedTurnover,
		|		ServiceSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover,
		|		ServiceSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover
		|	FROM
		|		AccumulationRegister.Sales.Turnovers(
		|				&qPeriodFrom,
		|				&qPeriodTo,
		|				Day,
		|				NOT IsCorrection
		|					AND Hotel IN HIERARCHY (&qHotel)) AS ServiceSalesTurnovers
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ServiceSalesForecastTurnovers.Period,
		|		CASE
		|			WHEN ServiceSalesForecastTurnovers.Hotel.LoyaltyProgram = ServiceSalesForecastTurnovers.DiscountType
		|					AND ServiceSalesForecastTurnovers.DiscountType <> VALUE(Catalog.DiscountTypes.EmptyRef)
		|				THEN ServiceSalesForecastTurnovers.DiscountType
		|			WHEN ServiceSalesForecastTurnovers.Hotel.LoyaltyProgram = ServiceSalesForecastTurnovers.DiscountType.Parent
		|					AND ServiceSalesForecastTurnovers.DiscountType <> VALUE(Catalog.DiscountTypes.EmptyRef)
		|					AND ServiceSalesForecastTurnovers.DiscountType.Parent <> VALUE(Catalog.DiscountTypes.EmptyRef)
		|				THEN ServiceSalesForecastTurnovers.DiscountType
		|			ELSE NULL
		|		END,
		|		ServiceSalesForecastTurnovers.SalesTurnover,
		|		ServiceSalesForecastTurnovers.SalesWithoutVATTurnover,
		|		ServiceSalesForecastTurnovers.RoomsRentedTurnover,
		|		ServiceSalesForecastTurnovers.BedsRentedTurnover,
		|		ServiceSalesForecastTurnovers.GuestDaysTurnover,
		|		ServiceSalesForecastTurnovers.GuestsCheckedInTurnover
		|	FROM
		|		AccumulationRegister.SalesForecast.Turnovers(
		|				&qForecastPeriodFrom,
		|				&qForecastPeriodTo,
		|				Day,
		|				NOT &qDoNotShowForecast
		|					AND Hotel IN HIERARCHY (&qHotel)) AS ServiceSalesForecastTurnovers) AS ServiceSales
		|
		|GROUP BY
		|	ServiceSales.Period,
		|	CASE
		|		WHEN ServiceSales.LoyaltyType IS NULL
		|			THEN VALUE(Catalog.DiscountTypes.EmptyRef)
		|		ELSE ServiceSales.LoyaltyType
		|	END,
		|	CASE
		|		WHEN ServiceSales.LoyaltyType.SortCode IS NULL
		|			THEN 999999
		|		ELSE ServiceSales.LoyaltyType.SortCode
		|	END,
		|	CASE
		|		WHEN ServiceSales.LoyaltyType.Description IS NULL
		|			THEN ""NOT LOYALTY PROGRAM MEMBER""
		|		ELSE ServiceSales.LoyaltyType.Description
		|	END
		|
		|ORDER BY
		|	Period,
		|	LoyaltyTypeSortCode,
		|	LoyaltyTypeDescription";
		vQry.SetParameter("qPeriodFrom", pmBegOfYear(PeriodTo));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qForecastPeriodFrom", vForecastStartDate);
		vQry.SetParameter("qForecastPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qHotel", vHotel);
		vQry.SetParameter("qDoNotShowForecast", DoNotShowForecast);
		vQryResult = vQry.Execute().Unload();
		
		// Get list of sources
		vLoyaltyTypes = vQryResult.Copy();
		vLoyaltyTypes.GroupBy("LoyaltyType, LoyaltyTypeSortCode, LoyaltyTypeDescription", );
		vLoyaltyTypes.Sort("LoyaltyTypeSortCode, LoyaltyTypeDescription");
		
		If ShowPreviousYearData Then
			vQryLY = New Query();
			vQryLY.Text = 
			"SELECT
			|	ServiceSales.Period AS Period,
			|	CASE
			|		WHEN ServiceSales.LoyaltyType IS NULL
			|			THEN VALUE(Catalog.DiscountTypes.EmptyRef)
			|		ELSE ServiceSales.LoyaltyType
			|	END AS LoyaltyType,
			|	CASE
			|		WHEN ServiceSales.LoyaltyType.SortCode IS NULL
			|			THEN 999999
			|		ELSE ServiceSales.LoyaltyType.SortCode
			|	END AS LoyaltyTypeSortCode,
			|	CASE
			|		WHEN ServiceSales.LoyaltyType.Description IS NULL
			|			THEN ""NOT LOYALTY PROGRAM MEMBER""
			|		ELSE ServiceSales.LoyaltyType.Description
			|	END AS LoyaltyTypeDescription,
			|	SUM(ServiceSales.SumTurnover) AS SumTurnover,
			|	SUM(ServiceSales.SumWithoutVATTurnover) AS SumWithoutVATTurnover,
			|	SUM(ServiceSales.RoomsRentedTurnover) AS RoomsRentedTurnover,
			|	SUM(ServiceSales.BedsRentedTurnover) AS BedsRentedTurnover,
			|	SUM(ServiceSales.GuestDaysTurnover) AS GuestDaysTurnover,
			|	SUM(ServiceSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
			|FROM
			|	(SELECT
			|		ServiceSalesTurnovers.Period AS Period,
			|		CASE
			|			WHEN ServiceSalesTurnovers.Hotel.LoyaltyProgram = ServiceSalesTurnovers.DiscountType
			|					AND ServiceSalesTurnovers.DiscountType <> VALUE(Catalog.DiscountTypes.EmptyRef)
			|				THEN ServiceSalesTurnovers.DiscountType
			|			WHEN ServiceSalesTurnovers.Hotel.LoyaltyProgram = ServiceSalesTurnovers.DiscountType.Parent
			|					AND ServiceSalesTurnovers.DiscountType <> VALUE(Catalog.DiscountTypes.EmptyRef)
			|					AND ServiceSalesTurnovers.DiscountType.Parent <> VALUE(Catalog.DiscountTypes.EmptyRef)
			|				THEN ServiceSalesTurnovers.DiscountType
			|			ELSE NULL
			|		END AS LoyaltyType,
			|		ServiceSalesTurnovers.SalesTurnover AS SumTurnover,
			|		ServiceSalesTurnovers.SalesWithoutVATTurnover AS SumWithoutVATTurnover,
			|		ServiceSalesTurnovers.RoomsRentedTurnover AS RoomsRentedTurnover,
			|		ServiceSalesTurnovers.BedsRentedTurnover AS BedsRentedTurnover,
			|		ServiceSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover,
			|		ServiceSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover
			|	FROM
			|		AccumulationRegister.Sales.Turnovers(
			|				&qPeriodFrom,
			|				&qPeriodTo,
			|				Day,
			|				NOT IsCorrection
			|					AND Hotel IN HIERARCHY (&qHotel)) AS ServiceSalesTurnovers) AS ServiceSales
			|
			|GROUP BY
			|	ServiceSales.Period,
			|	CASE
			|		WHEN ServiceSales.LoyaltyType IS NULL
			|			THEN VALUE(Catalog.DiscountTypes.EmptyRef)
			|		ELSE ServiceSales.LoyaltyType
			|	END,
			|	CASE
			|		WHEN ServiceSales.LoyaltyType.SortCode IS NULL
			|			THEN 999999
			|		ELSE ServiceSales.LoyaltyType.SortCode
			|	END,
			|	CASE
			|		WHEN ServiceSales.LoyaltyType.Description IS NULL
			|			THEN ""NOT LOYALTY PROGRAM MEMBER""
			|		ELSE ServiceSales.LoyaltyType.Description
			|	END
			|
			|ORDER BY
			|	Period,
			|	LoyaltyTypeSortCode,
			|	LoyaltyTypeDescription";
			vQryLY.SetParameter("qPeriodFrom", pmBegOfYear(PeriodToLY));
			vQryLY.SetParameter("qPeriodTo", EndOfDay(PeriodToLY));
			vQryLY.SetParameter("qHotel", vHotel);
			vQryResultLY = vQryLY.Execute().Unload();
			
			// Get list of service types
			vLoyaltyTypesLY = vQryResultLY.Copy();
			vLoyaltyTypesLY.GroupBy("LoyaltyType, LoyaltyTypeSortCode, LoyaltyTypeDescription", );
			vLoyaltyTypesLY.Sort("LoyaltyTypeSortCode, LoyaltyTypeDescription");
			
			// Add rows of last year service types to the list of current ones
			For Each vSTRowLY In vLoyaltyTypesLY Do
				If vLoyaltyTypes.Find(vSTRowLY.LoyaltyType, "LoyaltyType") = Undefined Then
					vSTRow = vLoyaltyTypes.Add();
					vSTRow.LoyaltyType = vSTRowLY.LoyaltyType;
					vQRRow = vQryResult.Add();
					vQRRow.LoyaltyType = vSTRowLY.LoyaltyType;
				EndIf;
			EndDo;
			For Each vSTRow In vLoyaltyTypes Do
				If vLoyaltyTypesLY.Find(vSTRow.LoyaltyType, "LoyaltyType") = Undefined Then
					vSTRowLY = vLoyaltyTypesLY.Add();
					vSTRowLY.LoyaltyType = vSTRow.LoyaltyType;
					vQRRowLY = vQryResultLY.Add();
					vQRRowLY.LoyaltyType = vSTRow.LoyaltyType;
				EndIf;
			EndDo;
		EndIf;
		
		If vLoyaltyTypes.Count() > 1 Then
			vArea = vTemplate.GetArea("LoyaltyTypeHeader");
			pSpreadsheet.Put(vArea);
			
			// Put service types summary
			For Each vRow In vLoyaltyTypes Do
				vLoyaltyType = vRow.LoyaltyType;
				
				// Get records for the current loyalty type only
				vQrySubresult = vQryResult.FindRows(New Structure("LoyaltyType", vLoyaltyType));
				GetQryResultTableTotals(vQrySubresult, vQryResult, "SumTurnover, SumWithoutVATTurnover, RoomsRentedTurnover, BedsRentedTurnover, GuestDaysTurnover, GuestsCheckedInTurnover", False);
				If ShowPreviousYearData Then
					vRowLY = vLoyaltyTypesLY.Find(vLoyaltyType, "LoyaltyType");
					vQrySubresultLY = vQryResultLY.FindRows(New Structure("LoyaltyType", vLoyaltyType));
					GetQryResultTableTotalsLY(vQrySubresultLY, vQryResultLY, "SumTurnover, SumWithoutVATTurnover, RoomsRentedTurnover, BedsRentedTurnover, GuestDaysTurnover, GuestsCheckedInTurnover", False);
				EndIf;

				// Income
				vArea = vTemplate.GetArea("LoyaltyTypeIncome");
				vArea.Parameters.mLoyaltyType = ?(ValueIsFilled(vLoyaltyType), vLoyaltyType, NStr("en = '<Not member>'; de = '<Kein Mitglied>'; ru = '<Не участник>'"));
				
				If vWithVAT Then
					vArea.Parameters.mLoyaltyTypeIncome = cmCastToNumber(TotalPerDay.SumTurnover);
					vArea.Parameters.mLoyaltyTypeIncomePerMonth = cmCastToNumber(TotalPerMonth.SumTurnover);
					vArea.Parameters.mLoyaltyTypeIncomePerYear = cmCastToNumber(TotalPerYear.SumTurnover);
					If ShowPreviousYearData Then
						vArea.Parameters.mLoyaltyTypeIncomeLY = cmCastToNumber(TotalPerDayLY.SumTurnover);
						vArea.Parameters.mLoyaltyTypeIncomePerMonthLY = cmCastToNumber(TotalPerMonthLY.SumTurnover);
						vArea.Parameters.mLoyaltyTypeIncomePerYearLY = cmCastToNumber(TotalPerYearLY.SumTurnover);
					EndIf;
				Else
					vArea.Parameters.mLoyaltyTypeIncome = cmCastToNumber(TotalPerDay.SumWithoutVATTurnover);
					vArea.Parameters.mLoyaltyTypeIncomePerMonth = cmCastToNumber(TotalPerMonth.SumWithoutVATTurnover);
					vArea.Parameters.mLoyaltyTypeIncomePerYear = cmCastToNumber(TotalPerYear.SumWithoutVATTurnover);
					If ShowPreviousYearData Then
						vArea.Parameters.mLoyaltyTypeIncomeLY = cmCastToNumber(TotalPerDayLY.SumWithoutVATTurnover);
						vArea.Parameters.mLoyaltyTypeIncomePerMonthLY = cmCastToNumber(TotalPerMonthLY.SumWithoutVATTurnover);
						vArea.Parameters.mLoyaltyTypeIncomePerYearLY = cmCastToNumber(TotalPerYearLY.SumWithoutVATTurnover);
					EndIf;
				EndIf;
				
				pSpreadsheet.Put(vArea);
				
				// Rooms or beds
				If vInRooms Then
					vArea = vTemplate.GetArea("LoyaltyTypeRoomsRented");

					vArea.Parameters.mLoyaltyTypeRoomsRented = cmCastToNumber(TotalPerDay.RoomsRentedTurnover);
					vArea.Parameters.mLoyaltyTypeRoomsRentedPerMonth = cmCastToNumber(TotalPerMonth.RoomsRentedTurnover);
					vArea.Parameters.mLoyaltyTypeRoomsRentedPerYear = cmCastToNumber(TotalPerYear.RoomsRentedTurnover);
					If ShowPreviousYearData Then
						vArea.Parameters.mLoyaltyTypeRoomsRentedLY = cmCastToNumber(TotalPerDayLY.RoomsRentedTurnover);
						vArea.Parameters.mLoyaltyTypeRoomsRentedPerMonthLY = cmCastToNumber(TotalPerMonthLY.RoomsRentedTurnover);
						vArea.Parameters.mLoyaltyTypeRoomsRentedPerYearLY = cmCastToNumber(TotalPerYearLY.RoomsRentedTurnover);
					EndIf;
				Else
					vArea = vTemplate.GetArea("LoyaltyTypeBedsRented");

					vArea.Parameters.mLoyaltyTypeBedsRented = cmCastToNumber(TotalPerDay.RoomsRentedTurnover);
					vArea.Parameters.mLoyaltyTypeBedsRentedPerMonth = cmCastToNumber(TotalPerMonth.RoomsRentedTurnover);
					vArea.Parameters.mLoyaltyTypeBedsRentedPerYear = cmCastToNumber(TotalPerYear.RoomsRentedTurnover);
					If ShowPreviousYearData Then
						vArea.Parameters.mLoyaltyTypeBedsRentedLY = cmCastToNumber(TotalPerDayLY.BedsRentedTurnover);
						vArea.Parameters.mLoyaltyTypeBedsRentedPerMonthLY = cmCastToNumber(TotalPerMonthLY.BedsRentedTurnover);
						vArea.Parameters.mLoyaltyTypeBedsRentedPerYearLY = cmCastToNumber(TotalPerYearLY.BedsRentedTurnover);
					EndIf;
				EndIf;
				
				pSpreadsheet.Put(vArea);
				
				// Guest days
				vArea = vTemplate.GetArea("LoyaltyTypeGuestDays");

				vArea.Parameters.mLoyaltyTypeGuestDays = cmCastToNumber(TotalPerDay.GuestDaysTurnover);
				vArea.Parameters.mLoyaltyTypeGuestDaysPerMonth = cmCastToNumber(TotalPerMonth.GuestDaysTurnover);
				vArea.Parameters.mLoyaltyTypeGuestDaysPerYear = cmCastToNumber(TotalPerYear.GuestDaysTurnover);
				If ShowPreviousYearData Then
					vArea.Parameters.mLoyaltyTypeGuestDaysLY = cmCastToNumber(TotalPerDayLY.GuestDaysTurnover);
					vArea.Parameters.mLoyaltyTypeGuestDaysPerMonthLY = cmCastToNumber(TotalPerMonthLY.GuestDaysTurnover);
					vArea.Parameters.mLoyaltyTypeGuestDaysPerYearLY = cmCastToNumber(TotalPerYearLY.GuestDaysTurnover);
				EndIf;
				
				pSpreadsheet.Put(vArea);
				
				// RevPAC
				vArea = vTemplate.GetArea("LoyaltyTypeRevPAC");

				If vWithVAT Then
					vArea.Parameters.mLoyaltyTypeRevPAC = Round(?(cmCastToNumber(TotalPerDay.GuestDaysTurnover) = 0, 0, cmCastToNumber(TotalPerDay.SumTurnover) / cmCastToNumber(TotalPerDay.GuestDaysTurnover)), 2);
					vArea.Parameters.mLoyaltyTypeRevPACPerMonth = Round(?(cmCastToNumber(TotalPerMonth.GuestDaysTurnover) = 0, 0, cmCastToNumber(TotalPerMonth.SumTurnover) / cmCastToNumber(TotalPerMonth.GuestDaysTurnover)), 2);
					vArea.Parameters.mLoyaltyTypeRevPACPerYear = Round(?(cmCastToNumber(TotalPerYear.GuestDaysTurnover) = 0, 0, cmCastToNumber(TotalPerYear.SumTurnover) / cmCastToNumber(TotalPerYear.GuestDaysTurnover)), 2);
					If ShowPreviousYearData Then
						vArea.Parameters.mLoyaltyTypeRevPACLY = Round(?(cmCastToNumber(TotalPerDayLY.GuestDaysTurnover) = 0, 0, cmCastToNumber(TotalPerDayLY.SumTurnover) / cmCastToNumber(TotalPerDayLY.GuestDaysTurnover)), 2);
						vArea.Parameters.mLoyaltyTypeRevPACPerMonthLY = Round(?(cmCastToNumber(TotalPerMonthLY.GuestDaysTurnover) = 0, 0, cmCastToNumber(TotalPerMonthLY.SumTurnover) / cmCastToNumber(TotalPerMonthLY.GuestDaysTurnover)), 2);
						vArea.Parameters.mLoyaltyTypeRevPACPerYearLY = Round(?(cmCastToNumber(TotalPerYearLY.GuestDaysTurnover) = 0, 0, cmCastToNumber(TotalPerYearLY.SumTurnover) / cmCastToNumber(TotalPerYearLY.GuestDaysTurnover)), 2);
					EndIf;
				Else
					vArea.Parameters.mLoyaltyTypeRevPAC = Round(?(cmCastToNumber(TotalPerDay.GuestDaysTurnover) = 0, 0, cmCastToNumber(TotalPerDay.SumWithoutVATTurnover) / cmCastToNumber(TotalPerDay.GuestDaysTurnover)), 2);
					vArea.Parameters.mLoyaltyTypeRevPACPerMonth = Round(?(cmCastToNumber(TotalPerMonth.GuestDaysTurnover) = 0, 0, cmCastToNumber(TotalPerMonth.SumWithoutVATTurnover) / cmCastToNumber(TotalPerMonth.GuestDaysTurnover)), 2);
					vArea.Parameters.mLoyaltyTypeRevPACPerYear = Round(?(cmCastToNumber(TotalPerYear.GuestDaysTurnover) = 0, 0, cmCastToNumber(TotalPerYear.SumWithoutVATTurnover) / cmCastToNumber(TotalPerYear.GuestDaysTurnover)), 2);
					If ShowPreviousYearData Then
						vArea.Parameters.mLoyaltyTypeRevPACLY = Round(?(cmCastToNumber(TotalPerDayLY.GuestDaysTurnover) = 0, 0, cmCastToNumber(TotalPerDayLY.SumWithoutVATTurnover) / cmCastToNumber(TotalPerDayLY.GuestDaysTurnover)), 2);
						vArea.Parameters.mLoyaltyTypeRevPACPerMonthLY = Round(?(cmCastToNumber(TotalPerMonthLY.GuestDaysTurnover) = 0, 0, cmCastToNumber(TotalPerMonthLY.SumWithoutVATTurnover) / cmCastToNumber(TotalPerMonthLY.GuestDaysTurnover)), 2);
						vArea.Parameters.mLoyaltyTypeRevPACPerYearLY = Round(?(cmCastToNumber(TotalPerYearLY.GuestDaysTurnover) = 0, 0, cmCastToNumber(TotalPerYearLY.SumWithoutVATTurnover) / cmCastToNumber(TotalPerYearLY.GuestDaysTurnover)), 2);
					EndIf;
				EndIf;
				
				pSpreadsheet.Put(vArea);
			EndDo;
			
			pSpreadsheet.Put(vSalesTotalsArea);
		EndIf;
		
		// 6. Payments summary indexes
		
		// Put section header
		vArea = vTemplate.GetArea("PaymentsHeader");
		pSpreadsheet.Put(vArea);
		
		// Run query to get payments by payment method
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	PaymentsTurnovers.PaymentMethod AS PaymentMethod,
		|	PaymentsTurnovers.PaymentMethod.SortCode AS PaymentMethodSortCode,
		|	PaymentsTurnovers.PaymentMethod.Description AS PaymentMethodDescription,
		|	PaymentsTurnovers.Period AS Period,
		|	SUM(PaymentsTurnovers.SumTurnover) AS SumTurnover,
		|	SUM(PaymentsTurnovers.VATSumTurnover) AS VATSumTurnover
		|FROM
		|	AccumulationRegister.Payments.Turnovers(&qPeriodFrom, &qPeriodTo, Day, Hotel IN HIERARCHY (&qHotel)) AS PaymentsTurnovers
		|
		|GROUP BY
		|	PaymentsTurnovers.Period,
		|	PaymentsTurnovers.PaymentMethod,
		|	PaymentsTurnovers.PaymentMethod.SortCode,
		|	PaymentsTurnovers.PaymentMethod.Description
		|
		|ORDER BY
		|	PaymentMethodSortCode,
		|	PaymentMethodDescription,
		|	Period";
		vQry.SetParameter("qPeriodFrom", pmBegOfYear(PeriodTo));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qHotel", vHotel);
		vQryResult = vQry.Execute().Unload();
		
		// Get list of payment methods
		vPaymentMethods = vQryResult.Copy();
		vPaymentMethods.GroupBy("PaymentMethod, PaymentMethodSortCode, PaymentMethodDescription");
		vPaymentMethods.Sort("PaymentMethodSortCode, PaymentMethodDescription");
		
		If ShowPreviousYearData Then
			vQryLY = New Query();
			vQryLY.Text = 
			"SELECT
			|	PaymentsTurnovers.PaymentMethod AS PaymentMethod,
			|	PaymentsTurnovers.PaymentMethod.SortCode AS PaymentMethodSortCode,
			|	PaymentsTurnovers.PaymentMethod.Description AS PaymentMethodDescription,
			|	PaymentsTurnovers.Period AS Period,
			|	SUM(PaymentsTurnovers.SumTurnover) AS SumTurnover,
			|	SUM(PaymentsTurnovers.VATSumTurnover) AS VATSumTurnover
			|FROM
			|	AccumulationRegister.Payments.Turnovers(&qPeriodFrom, &qPeriodTo, Day, Hotel IN HIERARCHY (&qHotel)) AS PaymentsTurnovers
			|
			|GROUP BY
			|	PaymentsTurnovers.Period,
			|	PaymentsTurnovers.PaymentMethod,
			|	PaymentsTurnovers.PaymentMethod.SortCode,
			|	PaymentsTurnovers.PaymentMethod.Description
			|
			|ORDER BY
			|	PaymentMethodSortCode,
			|	PaymentMethodDescription,
			|	Period";
			vQryLY.SetParameter("qPeriodFrom", pmBegOfYear(PeriodToLY));
			vQryLY.SetParameter("qPeriodTo", EndOfDay(PeriodToLY));
			vQryLY.SetParameter("qHotel", vHotel);
			vQryResultLY = vQryLY.Execute().Unload();
			
			// Get list of payment methods
			vPaymentMethodsLY = vQryResultLY.Copy();
			vPaymentMethodsLY.GroupBy("PaymentMethod, PaymentMethodSortCode, PaymentMethodDescription");
			vPaymentMethodsLY.Sort("PaymentMethodSortCode, PaymentMethodDescription");
			
			For Each vPMRowLY In vPaymentMethodsLY Do
				If vPaymentMethods.Find(vPMRowLY.PaymentMethod, "PaymentMethod") = Undefined Then
					vPMRow = vPaymentMethods.Add();
					vPMRow.PaymentMethod = vPMRowLY.PaymentMethod;
					vQRRow = vQryResult.Add();
					vQRRow.PaymentMethod = vPMRowLY.PaymentMethod;
				EndIf;
			EndDo;
			For Each vPMRow In vPaymentMethods Do
				If vPaymentMethodsLY.Find(vPMRow.PaymentMethod, "PaymentMethod") = Undefined Then
					vPMRowLY = vPaymentMethodsLY.Add();
					vPMRowLY.PaymentMethod = vPMRow.PaymentMethod;
					vQRRowLY = vQryResultLY.Add();
					vQRRowLY.PaymentMethod = vPMRow.PaymentMethod;
				EndIf;
			EndDo;
		EndIf;
		
		// Put payment methods summary
		vTotalPaymentsPerDay = 0;
		vTotalPaymentsPerMonth = 0;
		vTotalPaymentsPerYear = 0;
		If ShowPreviousYearData Then
			vTotalPaymentsPerDayLY = 0;
			vTotalPaymentsPerMonthLY = 0;
			vTotalPaymentsPerYearLY = 0;
		EndIf;
		For Each vRow In vPaymentMethods Do
			vPaymentMethod = vRow.PaymentMethod;
			If vPaymentMethod = Catalogs.PaymentMethods.Settlement Then
				Continue;
			EndIf;
			
			// Get records for the current payment method only
			vQrySubresult = vQryResult.FindRows(New Structure("PaymentMethod", vPaymentMethod));
			GetQryResultTableTotals(vQrySubresult, vQryResult, "SumTurnover, VATSumTurnover", False);
			If ShowPreviousYearData Then
				vRowLY = vPaymentMethods.Find(vPaymentMethod, "PaymentMethod");
				vQrySubresultLY = vQryResultLY.FindRows(New Structure("PaymentMethod", vPaymentMethod));
				GetQryResultTableTotalsLY(vQrySubresultLY, vQryResultLY, "SumTurnover, VATSumTurnover", False);
			EndIf;
			
			vArea = vTemplate.GetArea("PaymentMethod");
			vArea.Parameters.mPaymentMethod = vPaymentMethod;
			vArea.Parameters.mSumTurnover = cmCastToNumber(TotalPerDay.SumTurnover);
			vArea.Parameters.mSumTurnoverPerMonth = cmCastToNumber(TotalPerMonth.SumTurnover);
			vArea.Parameters.mSumTurnoverPerYear = cmCastToNumber(TotalPerYear.SumTurnover);
			If ShowPreviousYearData Then
				vArea.Parameters.mSumTurnoverLY = cmCastToNumber(TotalPerDayLY.SumTurnover);
				vArea.Parameters.mSumTurnoverPerMonthLY = cmCastToNumber(TotalPerMonthLY.SumTurnover);
				vArea.Parameters.mSumTurnoverPerYearLY = cmCastToNumber(TotalPerYearLY.SumTurnover);
			EndIf;
			pSpreadsheet.Put(vArea);
			
			vTotalPaymentsPerDay = vTotalPaymentsPerDay + cmCastToNumber(TotalPerDay.SumTurnover);
			vTotalPaymentsPerMonth = vTotalPaymentsPerMonth + cmCastToNumber(TotalPerMonth.SumTurnover);
			vTotalPaymentsPerYear = vTotalPaymentsPerYear + cmCastToNumber(TotalPerYear.SumTurnover);
			If ShowPreviousYearData Then
				vTotalPaymentsPerDayLY = vTotalPaymentsPerDayLY + cmCastToNumber(TotalPerDayLY.SumTurnover);
				vTotalPaymentsPerMonthLY = vTotalPaymentsPerMonthLY + cmCastToNumber(TotalPerMonthLY.SumTurnover);
				vTotalPaymentsPerYearLY = vTotalPaymentsPerYearLY + cmCastToNumber(TotalPerYearLY.SumTurnover);
			EndIf;
		EndDo;
		
		// Payments footer
		vArea = vTemplate.GetArea("PaymentsFooter");
		vArea.Parameters.mSumTurnover = vTotalPaymentsPerDay;
		vArea.Parameters.mSumTurnoverPerMonth = vTotalPaymentsPerMonth;
		vArea.Parameters.mSumTurnoverPerYear = vTotalPaymentsPerYear;
		If ShowPreviousYearData Then
			vArea.Parameters.mSumTurnoverLY = vTotalPaymentsPerDayLY;
			vArea.Parameters.mSumTurnoverPerMonthLY = vTotalPaymentsPerMonthLY;
			vArea.Parameters.mSumTurnoverPerYearLY = vTotalPaymentsPerYearLY;
		EndIf;
		pSpreadsheet.Put(vArea);
		
		// 7. Forecast data
		
		vArea = vTemplate.GetArea("ForecastHeader");
		vArea.Parameters.mWhat = ?(vInRooms, NStr("en='rooms'; ru='номеров'; de='Zimmer'"), NStr("en='beds'; ru='мест'; de='Betten'"));
		
		// Run query to get forecast check-in data
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	CheckInData.Period AS Period,
		|	SUM(CheckInData.RoomsCheckedInTurnover) AS RoomsCheckedInTurnover,
		|	SUM(CheckInData.BedsCheckedInTurnover) AS BedsCheckedInTurnover,
		|	SUM(CheckInData.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
		|FROM
		|	(SELECT
		|		BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY) AS Period,
		|		SUM(RoomSalesTurnovers.RoomsCheckedIn) AS RoomsCheckedInTurnover,
		|		SUM(RoomSalesTurnovers.BedsCheckedIn) AS BedsCheckedInTurnover,
		|		SUM(RoomSalesTurnovers.GuestsCheckedIn) AS GuestsCheckedInTurnover
		|	FROM
		|		AccumulationRegister.Sales AS RoomSalesTurnovers
		|	WHERE
		|		RoomSalesTurnovers.Period >= &qPeriodFrom
		|		AND RoomSalesTurnovers.Period <= &qPeriodTo
		|		AND NOT RoomSalesTurnovers.IsCorrection
		|		AND RoomSalesTurnovers.Hotel IN HIERARCHY(&qHotel)
		|	
		|	GROUP BY
		|		BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY),
		|		SUM(RoomSalesTurnovers.RoomsCheckedIn),
		|		SUM(RoomSalesTurnovers.BedsCheckedIn),
		|		SUM(RoomSalesTurnovers.GuestsCheckedIn)
		|	FROM
		|		AccumulationRegister.SalesForecast AS RoomSalesTurnovers
		|	WHERE
		|		RoomSalesTurnovers.Period >= &qPeriodFrom
		|		AND RoomSalesTurnovers.Period <= &qPeriodTo
		|		AND RoomSalesTurnovers.Hotel IN HIERARCHY(&qHotel)
		|	
		|	GROUP BY
		|		BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY)) AS CheckInData
		|
		|GROUP BY
		|	CheckInData.Period
		|
		|ORDER BY
		|	Period";
		vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodTo) + 24*3600);
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo) + 24*3600);
		vQry.SetParameter("qHotel", vHotel);
		vQryResultCheckIn = vQry.Execute().Unload();
		
		vRoomsBedsCheckedInTomorrow = 0;
		vGuestsCheckedInTomorrow = 0;
		For Each vRow In vQryResultCheckIn Do
			If vRow.Period = (BegOfDay(PeriodTo) + 24*3600) Then
				vGuestsCheckedInTomorrow = vGuestsCheckedInTomorrow + vRow.GuestsCheckedInTurnover;
				vRoomsBedsCheckedInTomorrow = vRoomsBedsCheckedInTomorrow + ?(vInRooms, vRow.RoomsCheckedInTurnover, vRow.BedsCheckedInTurnover);
			EndIf;
		EndDo;
		vArea.Parameters.mGuestsCheckedInTomorrow = vGuestsCheckedInTomorrow;
		vArea.Parameters.mRoomsBedsCheckedInTomorrow = vRoomsBedsCheckedInTomorrow;
		
		// Run query to get forecast check-out data
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	CheckOutData.Period AS Period,
		|	SUM(CheckOutData.RoomsCheckedOutTurnover) AS RoomsCheckedOutTurnover,
		|	SUM(CheckOutData.BedsCheckedOutTurnover) AS BedsCheckedOutTurnover,
		|	SUM(CheckOutData.GuestsCheckedOutTurnover) AS GuestsCheckedOutTurnover
		|FROM
		|	(SELECT
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
		|					AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) < BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|					AND DATEADD(BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY), DAY, 1) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|				THEN DATEADD(BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY), DAY, 1)
		|			ELSE BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY)
		|		END AS Period,
		|		SUM(CASE
		|				WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
		|						AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|						AND BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY) <= BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|					THEN RoomSalesTurnovers.RoomsRented
		|				WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
		|						AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) < BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|						AND DATEADD(BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY), DAY, 1) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|					THEN RoomSalesTurnovers.RoomsRented
		|				ELSE 0
		|			END) AS RoomsCheckedOutTurnover,
		|		SUM(CASE
		|				WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
		|						AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|						AND BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY) <= BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|					THEN RoomSalesTurnovers.BedsRented
		|				WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
		|						AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) < BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|						AND DATEADD(BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY), DAY, 1) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|					THEN RoomSalesTurnovers.BedsRented
		|				ELSE 0
		|			END) AS BedsCheckedOutTurnover,
		|		SUM(CASE
		|				WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
		|						AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|						AND BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY) <= BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|					THEN RoomSalesTurnovers.GuestDays
		|				WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
		|						AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) < BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|						AND DATEADD(BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY), DAY, 1) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|					THEN RoomSalesTurnovers.GuestDays
		|				ELSE 0
		|			END) AS GuestsCheckedOutTurnover
		|	FROM
		|		AccumulationRegister.Sales AS RoomSalesTurnovers
		|	WHERE
		|		RoomSalesTurnovers.Period >= &qPeriodFrom
		|		AND RoomSalesTurnovers.Period <= &qPeriodTo
		|		AND NOT RoomSalesTurnovers.IsCorrection
		|		AND RoomSalesTurnovers.Hotel IN HIERARCHY(&qHotel)
		|	
		|	GROUP BY
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
		|					AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) < BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|					AND DATEADD(BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY), DAY, 1) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|				THEN DATEADD(BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY), DAY, 1)
		|			ELSE BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY)
		|		END
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
		|					AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) < BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|					AND DATEADD(BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY), DAY, 1) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|				THEN DATEADD(BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY), DAY, 1)
		|			ELSE BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY)
		|		END,
		|		SUM(CASE
		|				WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
		|						AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|						AND BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY) <= BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|					THEN RoomSalesTurnovers.RoomsRented
		|				WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
		|						AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) < BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|						AND DATEADD(BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY), DAY, 1) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|					THEN RoomSalesTurnovers.RoomsRented
		|				ELSE 0
		|			END),
		|		SUM(CASE
		|				WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
		|						AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|						AND BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY) <= BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|					THEN RoomSalesTurnovers.BedsRented
		|				WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
		|						AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) < BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|						AND DATEADD(BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY), DAY, 1) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|					THEN RoomSalesTurnovers.BedsRented
		|				ELSE 0
		|			END),
		|		SUM(CASE
		|				WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
		|						AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|						AND BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY) <= BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|					THEN RoomSalesTurnovers.GuestDays
		|				WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
		|						AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) < BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|						AND DATEADD(BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY), DAY, 1) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|					THEN RoomSalesTurnovers.GuestDays
		|				ELSE 0
		|			END)
		|	FROM
		|		AccumulationRegister.SalesForecast AS RoomSalesTurnovers
		|	WHERE
		|		RoomSalesTurnovers.Period >= &qPeriodFrom
		|		AND RoomSalesTurnovers.Period <= &qPeriodTo
		|		AND RoomSalesTurnovers.Hotel IN HIERARCHY(&qHotel)
		|	
		|	GROUP BY
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.ParentDoc.CheckOutDate IS NULL
		|					AND BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckInDate, DAY) < BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|					AND DATEADD(BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY), DAY, 1) = BEGINOFPERIOD(RoomSalesTurnovers.ParentDoc.CheckOutDate, DAY)
		|				THEN DATEADD(BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY), DAY, 1)
		|			ELSE BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY)
		|		END) AS CheckOutData
		|
		|GROUP BY
		|	CheckOutData.Period
		|
		|ORDER BY
		|	Period";
		vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodTo));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo) + 24*3600);
		vQry.SetParameter("qHotel", vHotel);
		vQryResultCheckOut = vQry.Execute().Unload();

		vRoomsBedsCheckedOutTomorrow = 0;
		vGuestsCheckedOutTomorrow = 0;
		For Each vRow In vQryResultCheckOut Do
			If vRow.Period = (BegOfDay(PeriodTo) + 24*3600) Then
				vGuestsCheckedOutTomorrow = vGuestsCheckedOutTomorrow + vRow.GuestsCheckedOutTurnover;
				vRoomsBedsCheckedOutTomorrow = vRoomsBedsCheckedOutTomorrow + ?(vInRooms, vRow.RoomsCheckedOutTurnover, vRow.BedsCheckedOutTurnover);
			EndIf;
		EndDo;
		vArea.Parameters.mGuestsCheckedOutTomorrow = vGuestsCheckedOutTomorrow;
		vArea.Parameters.mRoomsBedsCheckedOutTomorrow = vRoomsBedsCheckedOutTomorrow;
		
		// Occupancy percent for tomorrow, next week and next 28 days
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	InventoryData.AccountingDate AS AccountingDate,
		|	InventoryData.TotalRooms AS TotalRooms,
		|	InventoryData.RoomsBlocked AS RoomsBlocked,
		|	InventoryData.TotalBeds AS TotalBeds,
		|	InventoryData.BedsBlocked AS BedsBlocked,
		|	ISNULL(SalesData.RoomsRented, 0) AS RoomsRented,
		|	ISNULL(SalesData.BedsRented, 0) AS BedsRented,
		|	ISNULL(SalesData.GuaranteedRoomsRented, 0) AS GuaranteedRoomsRented,
		|	ISNULL(SalesData.GuaranteedBedsRented, 0) AS GuaranteedBedsRented,
		|	ISNULL(SalesData.NotGuaranteedRoomsRented, 0) AS NotGuaranteedRoomsRented,
		|	ISNULL(SalesData.NotGuaranteedBedsRented, 0) AS NotGuaranteedBedsRented
		|FROM
		|	(SELECT
		|		Inventory.AccountingDate AS AccountingDate,
		|		SUM(Inventory.TotalRoomsClosingBalance) AS TotalRooms,
		|		SUM(Inventory.RoomsBlockedClosingBalance) AS RoomsBlocked,
		|		SUM(Inventory.TotalBedsClosingBalance) AS TotalBeds,
		|		SUM(Inventory.BedsBlockedClosingBalance) AS BedsBlocked
		|	FROM
		|		(SELECT
		|			RoomInventoryBalanceAndTurnovers.Period AS AccountingDate,
		|			RoomInventoryBalanceAndTurnovers.RoomType AS RoomType,
		|			RoomInventoryBalanceAndTurnovers.TotalRoomsClosingBalance AS TotalRoomsClosingBalance,
		|			RoomInventoryBalanceAndTurnovers.RoomsBlockedClosingBalance AS RoomsBlockedClosingBalance,
		|			RoomInventoryBalanceAndTurnovers.TotalBedsClosingBalance AS TotalBedsClosingBalance,
		|			RoomInventoryBalanceAndTurnovers.BedsBlockedClosingBalance AS BedsBlockedClosingBalance,
		|			RoomInventoryBalanceAndTurnovers.CounterClosingBalance AS CounterClosingBalance
		|		FROM
		|			AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qPeriodFrom, &qPeriodTo, DAY, RegisterRecordsAndPeriodBoundaries, Hotel = &qHotel) AS RoomInventoryBalanceAndTurnovers) AS Inventory
		|	
		|	GROUP BY
		|		Inventory.AccountingDate) AS InventoryData
		|		LEFT JOIN (SELECT
		|			SalesByDates.AccountingDate AS AccountingDate,
		|			SUM(SalesByDates.RoomsRentedTurnover) AS RoomsRented,
		|			SUM(SalesByDates.BedsRentedTurnover) AS BedsRented,
		|			SUM(SalesByDates.GuaranteedRoomsRentedTurnover) AS GuaranteedRoomsRented,
		|			SUM(SalesByDates.GuaranteedBedsRentedTurnover) AS GuaranteedBedsRented,
		|			SUM(SalesByDates.NotGuaranteedRoomsRentedTurnover) AS NotGuaranteedRoomsRented,
		|			SUM(SalesByDates.NotGuaranteedBedsRentedTurnover) AS NotGuaranteedBedsRented
		|		FROM
		|			(SELECT
		|				SalesTurnovers.AccountingDate AS AccountingDate,
		|				SalesTurnovers.RoomsRentedTurnover AS RoomsRentedTurnover,
		|				SalesTurnovers.BedsRentedTurnover AS BedsRentedTurnover,
		|				SalesTurnovers.RoomsRentedTurnover AS GuaranteedRoomsRentedTurnover,
		|				SalesTurnovers.BedsRentedTurnover AS GuaranteedBedsRentedTurnover,
		|				0 AS NotGuaranteedRoomsRentedTurnover,
		|				0 AS NotGuaranteedBedsRentedTurnover
		|			FROM
		|				AccumulationRegister.Sales.Turnovers(&qPeriodFrom, &qPeriodTo, DAY, Hotel = &qHotel) AS SalesTurnovers
		|			
		|			UNION ALL
		|			
		|			SELECT
		|				SalesForecastTurnovers.AccountingDate,
		|				SalesForecastTurnovers.RoomsRented,
		|				SalesForecastTurnovers.BedsRented,
		|				CASE
		|					WHEN ISNULL(SalesForecastTurnovers.Recorder.ReservationStatus.IsGuaranteed, FALSE)
		|						THEN SalesForecastTurnovers.RoomsRented
		|					WHEN SalesForecastTurnovers.RoomQuota.AllotmentType = VALUE(Enum.AllotmentTypes.Definite)
		|						THEN SalesForecastTurnovers.RoomsRented
		|					ELSE 0
		|				END,
		|				CASE
		|					WHEN ISNULL(SalesForecastTurnovers.Recorder.ReservationStatus.IsGuaranteed, FALSE)
		|						THEN SalesForecastTurnovers.BedsRented
		|					WHEN SalesForecastTurnovers.RoomQuota.AllotmentType = VALUE(Enum.AllotmentTypes.Definite)
		|						THEN SalesForecastTurnovers.BedsRented
		|					ELSE 0
		|				END,
		|				CASE
		|					WHEN ISNULL(SalesForecastTurnovers.Recorder.ReservationStatus.IsGuaranteed, FALSE)
		|						THEN 0
		|					WHEN SalesForecastTurnovers.RoomQuota.AllotmentType = VALUE(Enum.AllotmentTypes.Definite)
		|						THEN 0
		|					ELSE SalesForecastTurnovers.RoomsRented
		|				END,
		|				CASE
		|					WHEN ISNULL(SalesForecastTurnovers.Recorder.ReservationStatus.IsGuaranteed, FALSE)
		|						THEN 0
		|					WHEN SalesForecastTurnovers.RoomQuota.AllotmentType = VALUE(Enum.AllotmentTypes.Definite)
		|						THEN 0
		|					ELSE SalesForecastTurnovers.BedsRented
		|				END
		|			FROM
		|				AccumulationRegister.SalesForecast AS SalesForecastTurnovers
		|			WHERE
		|				SalesForecastTurnovers.Period >= &qPeriodFrom
		|				AND SalesForecastTurnovers.Period <= &qPeriodTo
		|				AND SalesForecastTurnovers.Hotel = &qHotel) AS SalesByDates
		|		
		|		GROUP BY
		|			SalesByDates.AccountingDate) AS SalesData
		|		ON InventoryData.AccountingDate = SalesData.AccountingDate
		|
		|ORDER BY
		|	AccountingDate";
		vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodTo) + 24*3600);
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo) + 28*24*3600);
		vQry.SetParameter("qHotel", vHotel);
		vQryResultSales = vQry.Execute().Unload();
		
		vAvailableTomorrow = 0;
		vAvailableNext7Days = 0;
		vAvailableNext28Days = 0;
		vRentedTomorrow = 0;
		vRentedNext7Days = 0;
		vRentedNext28Days = 0;
		vGuaranteedRentedTomorrow = 0;
		vGuaranteedRentedNext7Days = 0;
		vGuaranteedRentedNext28Days = 0;
		vNotGuaranteedRentedTomorrow = 0;
		vNotGuaranteedRentedNext7Days = 0;
		vNotGuaranteedRentedNext28Days = 0;
		
		For Each vRow In vQryResultSales Do
			vAvailablePerDate = ?(vInRooms, ?(vRow.TotalRooms = Null, 0, vRow.TotalRooms) - ?(vRow.RoomsBlocked = Null, 0, vRow.RoomsBlocked), ?(vRow.TotalBeds = Null, 0, vRow.TotalBeds) - ?(vRow.BedsBlocked = Null, 0, vRow.BedsBlocked));
			vRentedPerDate = ?(vInRooms, ?(vRow.RoomsRented = Null, 0, vRow.RoomsRented), ?(vRow.BedsRented = Null, 0, vRow.BedsRented));
			vGuaranteedRentedPerDate = ?(vInRooms, ?(vRow.GuaranteedRoomsRented = Null, 0, vRow.GuaranteedRoomsRented), ?(vRow.GuaranteedBedsRented = Null, 0, vRow.GuaranteedBedsRented));
			vNotGuaranteedRentedPerDate = ?(vInRooms, ?(vRow.NotGuaranteedRoomsRented = Null, 0, vRow.NotGuaranteedRoomsRented), ?(vRow.NotGuaranteedBedsRented = Null, 0, vRow.NotGuaranteedBedsRented));
			
			If vRow.AccountingDate = (BegOfDay(PeriodTo) + 24*3600) Then
				vAvailableTomorrow = vAvailableTomorrow + vAvailablePerDate;
				vAvailableNext7Days = vAvailableNext7Days + vAvailablePerDate;
				vAvailableNext28Days = vAvailableNext28Days + vAvailablePerDate;

				vRentedTomorrow = vRentedTomorrow + vRentedPerDate;
				vRentedNext7Days = vRentedNext7Days + vRentedPerDate;
				vRentedNext28Days = vRentedNext28Days + vRentedPerDate;

				vGuaranteedRentedTomorrow = vGuaranteedRentedTomorrow + vGuaranteedRentedPerDate;
				vGuaranteedRentedNext7Days = vGuaranteedRentedNext7Days + vGuaranteedRentedPerDate;
				vGuaranteedRentedNext28Days = vGuaranteedRentedNext28Days + vGuaranteedRentedPerDate;

				vNotGuaranteedRentedTomorrow = vNotGuaranteedRentedTomorrow + vNotGuaranteedRentedPerDate;
				vNotGuaranteedRentedNext7Days = vNotGuaranteedRentedNext7Days + vNotGuaranteedRentedPerDate;
				vNotGuaranteedRentedNext28Days = vNotGuaranteedRentedNext28Days + vNotGuaranteedRentedPerDate;
			ElsIf vRow.AccountingDate <= (BegOfDay(PeriodTo) + 7*24*3600) Then
				vAvailableNext7Days = vAvailableNext7Days + vAvailablePerDate;
				vAvailableNext28Days = vAvailableNext28Days + vAvailablePerDate;

				vRentedNext7Days = vRentedNext7Days + vRentedPerDate;
				vRentedNext28Days = vRentedNext28Days + vRentedPerDate;

				vGuaranteedRentedNext7Days = vGuaranteedRentedNext7Days + vGuaranteedRentedPerDate;
				vGuaranteedRentedNext28Days = vGuaranteedRentedNext28Days + vGuaranteedRentedPerDate;

				vNotGuaranteedRentedNext7Days = vNotGuaranteedRentedNext7Days + vNotGuaranteedRentedPerDate;
				vNotGuaranteedRentedNext28Days = vNotGuaranteedRentedNext28Days + vNotGuaranteedRentedPerDate;
			ElsIf vRow.AccountingDate <= (BegOfDay(PeriodTo) + 28*24*3600) Then
				vAvailableNext28Days = vAvailableNext28Days + vAvailablePerDate;

				vRentedNext28Days = vRentedNext28Days + vRentedPerDate;

				vGuaranteedRentedNext28Days = vGuaranteedRentedNext28Days + vGuaranteedRentedPerDate;
				vNotGuaranteedRentedNext28Days = vNotGuaranteedRentedNext28Days + vNotGuaranteedRentedPerDate;
			EndIf;
		EndDo;
		
		vArea.Parameters.mOccupationTomorrow = ?(vAvailableTomorrow <> 0, Round(vRentedTomorrow/vAvailableTomorrow*100, 2), 0);
		vArea.Parameters.mOccupationNext7Days = ?(vAvailableNext7Days <> 0, Round(vRentedNext7Days/vAvailableNext7Days*100, 2), 0);
		vArea.Parameters.mOccupationNext4Weeks = ?(vAvailableNext28Days <> 0, Round(vRentedNext28Days/vAvailableNext28Days*100, 2), 0);
		
		vArea.Parameters.mOccupationTomorrowGuaranteed = ?(vAvailableTomorrow <> 0, Round(vGuaranteedRentedTomorrow/vAvailableTomorrow*100, 2), 0);
		vArea.Parameters.mOccupationNext7DaysGuaranteed = ?(vAvailableNext7Days <> 0, Round(vGuaranteedRentedNext7Days/vAvailableNext7Days*100, 2), 0);
		vArea.Parameters.mOccupationNext4WeeksGuaranteed = ?(vAvailableNext28Days <> 0, Round(vGuaranteedRentedNext28Days/vAvailableNext28Days*100, 2), 0);
		
		vArea.Parameters.mOccupationTomorrowNotGuaranteed = ?(vAvailableTomorrow <> 0, Round(vNotGuaranteedRentedTomorrow/vAvailableTomorrow*100, 2), 0);
		vArea.Parameters.mOccupationNext7DaysNotGuaranteed = ?(vAvailableNext7Days <> 0, Round(vNotGuaranteedRentedNext7Days/vAvailableNext7Days*100, 2), 0);
		vArea.Parameters.mOccupationNext4WeeksNotGuaranteed = ?(vAvailableNext28Days <> 0, Round(vNotGuaranteedRentedNext28Days/vAvailableNext28Days*100, 2), 0);

		pSpreadsheet.Put(vArea);
	EndIf;
	
	// Report footer
	vFooter = vTemplate.GetArea("Footer");
	pSpreadsheet.Put(vFooter);
	
	// Report title
	If ValueIsFilled(Report) And Not IsBlankString(Report.ReportHeaderText) Then
		pSpreadsheet.Area(2, 2, 2, 2).Text = cmNStr(Report.ReportHeaderText, SessionParameters.CurrentLanguage);
	EndIf;
	
	// Create new rows format and set columns width
	vSpreadsheetEndHeight = pSpreadsheet.TableHeight;
	vArea = pSpreadsheet.Area(vSpreadsheetEndHeight, , vSpreadsheetEndHeight);
	vArea.CreateFormatOfRows();
	For i = 1 To vTemplate.TableWidth Do
		pSpreadsheet.Area(1, i).ColumnWidth = vTemplate.Area(1, i).ColumnWidth;
	EndDo;
EndProcedure // pmGenerate

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure GetQryResultTableTotals(pTbl, pTemplate, pResources, pConvertToTurnover = True)
	// Convert pTbl to the value table if necessary
	vTbl = pTbl;
	If TypeOf(pTbl) = Type("Array") Then
		vTbl = pTemplate.CopyColumns();
		For Each vRow In pTbl Do
			vTblRow = vTbl.Add();
			FillPropertyValues(vTblRow, vRow);
		EndDo;
	EndIf;
	
	// Group all resources to the 3 rows - day, month, year
	vBegOfYear = pmBegOfYear(PeriodTo);
	vBegOfMonth = pmBegOfMonth(PeriodTo);
	vBegOfDay = BegOfDay(PeriodTo);
	
	vTblPerDay = pTemplate.CopyColumns();
	TotalPerDay = vTblPerDay.Add();
	vTblPerMonth = pTemplate.CopyColumns();
	TotalPerMonth = vTblPerMonth.Add();
	vTblPerYear = pTemplate.CopyColumns();
	TotalPerYear = vTblPerYear.Add();
	
	vLastDayRow = TotalPerYear;
	vLastDayRow.Period = vBegOfYear;
	
	If vTbl.Count() > 0 Then
		vDay = vBegOfYear;
		
		While vDay <= vBegOfDay Do
			vDayRow = vTbl.Find(vDay, "Period");
			If pConvertToTurnover Then
				If vDayRow = Undefined Then
					vDayRow = vLastDayRow;
				Else
					vLastDayRow = vDayRow;
				EndIf;
			Else
				If vDayRow = Undefined Then
					vDayRow = vLastDayRow;
				EndIf;
			EndIf;
			vDayRow.Period = vDay;
			
			vRowPerYear = vTblPerYear.Add();
			FillPropertyValues(vRowPerYear, vDayRow);
			
			If BegOfDay(vDayRow.Period) >= vBegOfMonth Then
				vRowPerMonth = vTblPerMonth.Add();
				FillPropertyValues(vRowPerMonth, vDayRow);
			EndIf;
			
			If BegOfDay(vDayRow.Period) = vBegOfDay Then
				vRowPerDay = vTblPerDay.Add();
				FillPropertyValues(vRowPerDay, vDayRow);
			EndIf;
			
			vDay = vDay + 24 * 3600;
		EndDo;
		
		vTblPerYear.GroupBy(, pResources);
		TotalPerYear = vTblPerYear.Get(0);
		
		vTblPerMonth.GroupBy(, pResources);
		TotalPerMonth = vTblPerMonth.Get(0);
		
		vTblPerDay.GroupBy(, pResources);
		TotalPerDay = vTblPerDay.Get(0);
	EndIf;
EndProcedure // GetQryResultTableTotals

// -----------------------------------------------------------------------------
Procedure GetQryResultTableTotalsLY(pTbl, pTemplate, pResources, pConvertToTurnover = True)
	// Convert pTbl to the value table if necessary
	vTbl = pTbl;
	If TypeOf(pTbl) = Type("Array") Then
		vTbl = pTemplate.CopyColumns();
		For Each vRow In pTbl Do
			vTblRow = vTbl.Add();
			FillPropertyValues(vTblRow, vRow);
		EndDo;
	EndIf;
	
	// Group all resources to the 3 rows - day, month, year
	vPeriodToLY = AddMonth(PeriodTo, -12);
	vBegOfYear = pmBegOfYear(vPeriodToLY);
	vBegOfMonth = pmBegOfMonth(vPeriodToLY);
	vBegOfDay = BegOfDay(vPeriodToLY);
	
	vTblPerDay = pTemplate.CopyColumns();
	TotalPerDayLY = vTblPerDay.Add();
	vTblPerMonth = pTemplate.CopyColumns();
	TotalPerMonthLY = vTblPerMonth.Add();
	vTblPerYear = pTemplate.CopyColumns();
	TotalPerYearLY = vTblPerYear.Add();
	
	vLastDayRow = TotalPerYearLY;
	vLastDayRow.Period = vBegOfYear;
	
	If vTbl.Count() > 0 Then
		vDay = vBegOfYear;
		
		While vDay <= vBegOfDay Do
			vDayRow = vTbl.Find(vDay, "Period");
			If pConvertToTurnover Then
				If vDayRow = Undefined Then
					vDayRow = vLastDayRow;
				Else
					vLastDayRow = vDayRow;
				EndIf;
			Else
				If vDayRow = Undefined Then
					vDayRow = vLastDayRow;
				EndIf;
			EndIf;
			vDayRow.Period = vDay;
			
			vRowPerYear = vTblPerYear.Add();
			FillPropertyValues(vRowPerYear, vDayRow);
			
			If BegOfDay(vDayRow.Period) >= vBegOfMonth Then
				vRowPerMonth = vTblPerMonth.Add();
				FillPropertyValues(vRowPerMonth, vDayRow);
			EndIf;
			
			If BegOfDay(vDayRow.Period) = vBegOfDay Then
				vRowPerDay = vTblPerDay.Add();
				FillPropertyValues(vRowPerDay, vDayRow);
			EndIf;
			
			vDay = vDay + 24 * 3600;
		EndDo;
		
		vTblPerYear.GroupBy(, pResources);
		TotalPerYearLY = vTblPerYear.Get(0);
		
		vTblPerMonth.GroupBy(, pResources);
		TotalPerMonthLY = vTblPerMonth.Get(0);
		
		vTblPerDay.GroupBy(, pResources);
		TotalPerDayLY = vTblPerDay.Get(0);
	EndIf;
EndProcedure // GetQryResultTableTotalsLY

// -----------------------------------------------------------------------------
Procedure FillReportByHotels(pHotelList, pSpreadsheet, pTemplate)
	vTemplate = pTemplate;

	vArea = vTemplate.GetArea("TableHeader|HeaderDescription");
	pSpreadsheet.Put(vArea);
	
	For Each vHotel In pHotelList Do
		vArea = vTemplate.GetArea("TableHeader|HeaderHotel");
		vArea.Parameters.mHotel = TrimAll(vHotel);
		vArea.Parameters.mDate = Format(PeriodTo, "DF=dd.MM.yy");
		vPeriodToLY = AddMonth(PeriodTo, -12);
		vArea.Parameters.mDateLY = Format(vPeriodToLY, "DF=dd.MM.yy");
		pSpreadsheet.Join(vArea);
	EndDo;
	
	// Put section header
	vArea = vTemplate.GetArea("OccupationHeader");
	pSpreadsheet.Put(vArea);
	
	vArea = vTemplate.GetArea("TotalRooms|HeaderDescription");
	pSpreadsheet.Put(vArea);
	
	vHotelListTotals = GetTotalSalesByHotels(pHotelList);
	For Each vHotel In pHotelList Do
		vInRooms = Not vHotel.ShowReportsInBeds;
		vArea = vTemplate.GetArea("TotalRooms|HeaderHotel");
		vHotelTotal = vHotelListTotals.FindRows(New Structure("Hotel", vHotel));
		vCurDateTotal = 0;
		vPrevDateTotal = 0;
		If vHotelTotal.Count()>0 Then
			vCurDateTotal = ?(vInRooms, vHotelTotal[0].TotalRooms, vHotelTotal[0].TotalBeds);
			vPrevDateTotal = ?(vInRooms, vHotelTotal[0].PrevTotalRooms, vHotelTotal[0].PrevTotalBeds);
		EndIf;	
		vArea.Parameters.mTotalRooms = vCurDateTotal;
		vArea.Parameters.mTotalRoomsLY = vPrevDateTotal;
		pSpreadsheet.Join(vArea);
	EndDo;

	// Put rooms occupied
	If ShowRoomsOccupiedPercent Then
		vArea = vTemplate.GetArea("RoomsOccupancy|HeaderDescription");
		pSpreadsheet.Put(vArea);
		For Each vHotel In pHotelList Do
			vInRooms = Not vHotel.ShowReportsInBeds;
			vArea = vTemplate.GetArea("RoomsOccupancy|HeaderHotel");
			vTotalRooms = 0;
			vTotalRoomsLY = 0;
			vOccupiedRooms = 0;
			vOccupiedRoomsLY = 0;
			vVacantRooms = 0;
			vVacantRoomsLY = 0;
			vRoomsForSale = 0;
			vRoomsForSaleLY = 0;
			vSpecRoomsBlocked = 0;
			vSpecRoomsBlockedLY = 0;
			vRoomsIncome = 0;
			vRoomsIncomeLY = 0;
			vFilterRows = vHotelListTotals.FindRows(New Structure("Hotel", vHotel));  
			For Each vRow In vFilterRows Do
				vTotalRooms = vTotalRooms + ?(vInRooms, vRow.TotalRooms, vRow.TotalBeds);
				vTotalRoomsLY = vTotalRoomsLY + ?(vInRooms, vRow.PrevTotalRooms, vRow.PrevTotalBeds);
				vRoomsForSale = vRoomsForSale + ?(vInRooms, vRow.RoomsForSale, vRow.BedsForSale);
				vRoomsForSaleLY = vRoomsForSaleLY + ?(vInRooms, vRow.PrevRoomsForSale, vRow.PrevBedsForSale);
				vSpecRoomsBlocked = vSpecRoomsBlocked + ?(vInRooms, vRow.CurSpecRoomsBlocked, vRow.CurSpecBedsBlocked);
				vSpecRoomsBlockedLY = vSpecRoomsBlockedLY + ?(vInRooms, vRow.PrevSpecRoomsBlocked, vRow.PrevSpecBedsBlocked);
				vOccupiedRooms = vOccupiedRooms + ?(vInRooms, vRow.RoomsOccupied, vRow.BedsOccupied);
				vOccupiedRoomsLY = vOccupiedRoomsLY + ?(vInRooms, vRow.PrevRoomsOccupied, vRow.PrevBedsOccupied);
			EndDo;
			vVacantRooms = vTotalRooms - vOccupiedRooms;
			vVacantRoomsLY = vTotalRoomsLY - vOccupiedRoomsLY;
			vArea.Parameters.mRoomsOccupied = vOccupiedRooms;
			vArea.Parameters.mRoomsOccupiedLY = vOccupiedRoomsLY;
			vArea.Parameters.mRoomsVacant = vVacantRooms;
			vArea.Parameters.mRoomsVacantLY = vVacantRoomsLY;
			vArea.Parameters.mRoomsOccupancyPercent = Round(?((vRoomsForSale + vSpecRoomsBlocked) <> 0, 100 * (vOccupiedRooms + vSpecRoomsBlocked) / (vRoomsForSale + vSpecRoomsBlocked), 0), 2);
			vArea.Parameters.mRoomsOccupancyPercentLY = Round(?((vRoomsForSaleLY + vSpecRoomsBlockedLY) <> 0, 100 * (vOccupiedRoomsLY + vSpecRoomsBlockedLY) / (vRoomsForSaleLY + vSpecRoomsBlockedLY), 0), 2);
			pSpreadsheet.Join(vArea);
		EndDo;
	EndIf;
	
	vRoomBlockTypeTotals = GetRoomBlocksByHotelList(pHotelList);
	vRoomBlockType = vRoomBlockTypeTotals.Copy(,"RoomBlockType");
	vRoomBlockType.GroupBy("RoomBlockType");	
	For Each vRowRoomBlockType In vRoomBlockType Do
		vArea = vTemplate.GetArea("RoomBlockTypeRooms|HeaderDescription");
		vArea.Parameters.mRoomBlockType = vRowRoomBlockType.RoomBlockType;
		pSpreadsheet.Put(vArea);
		For Each vHotel In pHotelList Do
			vInRooms = Not vHotel.ShowReportsInBeds;
			vArea = vTemplate.GetArea("RoomBlockTypeRooms|HeaderHotel");
			vCurDateTotal = 0;
			vPrevDateTotal = 0;
			vFilterRows = vRoomBlockTypeTotals.FindRows(New Structure("Hotel, RoomBlockType", vHotel, vRowRoomBlockType.RoomBlockType));
			If vFilterRows.Count() > 0 Then
				 vCurDateTotal = ?(vInRooms, vFilterRows[0].CurDateRoomsBlocked, vFilterRows[0].CurDateBedsBlocked);
				 vPrevDateTotal = ?(vInRooms, vFilterRows[0].PrevDateRoomsBlocked, vFilterRows[0].PrevDateBedsBlocked);
				 vHotelTotal = vHotelListTotals.FindRows(New Structure("Hotel",vHotel));
				 If vHotelTotal.Count()>0 Then
					 vHotelTotal[0].CurSpecRoomsBlocked = ?(vInRooms, vHotelTotal[0].CurSpecRoomsBlocked + vFilterRows[0].CurSpecRoomsBlocked, vHotelTotal[0].CurSpecBedsBlocked + vFilterRows[0].CurSpecBedsBlocked);
					 vHotelTotal[0].PrevSpecRoomsBlocked = ?(vInRooms, vHotelTotal[0].PrevSpecRoomsBlocked + vFilterRows[0].PrevSpecRoomsBlocked, vHotelTotal[0].PrevSpecBedsBlocked + vFilterRows[0].PrevSpecBedsBlocked);
				 EndIf;
			EndIf;	
			vArea.Parameters.mRoomsBlocked = vCurDateTotal;
			vArea.Parameters.mRoomsBlockedLY = vPrevDateTotal;
			pSpreadsheet.Join(vArea);
		EndDo;	
	EndDo;	
	
	vArea = vTemplate.GetArea("RoomsForSale|HeaderDescription");
	pSpreadsheet.Put(vArea);
	
	For Each vHotel In pHotelList Do
		vInRooms = Not vHotel.ShowReportsInBeds;
		vArea = vTemplate.GetArea("RoomsForSale|HeaderHotel");
		vCurDateTotal = 0;
		vPrevDateTotal = 0;
		vHotelTotal = vHotelListTotals.FindRows(New Structure("Hotel",vHotel));
		If vHotelTotal.Count()>0 Then
			vCurDateTotal = ?(vInRooms, vHotelTotal[0].RoomsForSale + vHotelTotal[0].CurSpecRoomsBlocked, vHotelTotal[0].BedsForSale + vHotelTotal[0].CurSpecBedsBlocked);
			vPrevDateTotal = ?(vInRooms, vHotelTotal[0].PrevRoomsForSale + vHotelTotal[0].PrevSpecRoomsBlocked, vHotelTotal[0].PrevBedsForSale + vHotelTotal[0].PrevSpecBedsBlocked);
		EndIf;
		vArea.Parameters.mRoomsForSale = vCurDateTotal;
		vArea.Parameters.mRoomsForSaleLY = vPrevDateTotal;
		pSpreadsheet.Join(vArea);
	EndDo;
	
	// Rooms rented	
	vRoomRented = GetRoomRentedTotals(pHotelList);
	vArea = vTemplate.GetArea("RoomsRented|HeaderDescription");
	pSpreadsheet.Put(vArea);
	For Each vHotel In pHotelList Do
		vInRooms = Not vHotel.ShowReportsInBeds;
		vArea = vTemplate.GetArea("RoomsRented|HeaderHotel");
		vCurDateTotal = 0;
		vPrevDateTotal = 0;
		vHotelTotal = vRoomRented.FindRows(New Structure("Hotel", vHotel));
		For Each vRow In vHotelTotal Do
			vCurDateTotal = vCurDateTotal + ?(vInRooms, vRow.RoomsRented, vRow.BedsRented);
			vPrevDateTotal = vPrevDateTotal + ?(vInRooms, vRow.PrevRoomsRented, vRow.PrevBedsRented);
		EndDo;
		vArea.Parameters.mRoomsRented = vCurDateTotal;
		vArea.Parameters.mRoomsRentedLY = vPrevDateTotal;
		pSpreadsheet.Join(vArea);
	EndDo;
	
	// Complimentary
	vArea = vTemplate.GetArea("ComplimentaryRooms|HeaderDescription");
	pSpreadsheet.Put(vArea);
	For Each vHotel In pHotelList Do
		vInRooms = Not vHotel.ShowReportsInBeds;
		vArea = vTemplate.GetArea("ComplimentaryRooms|HeaderHotel");
		vCurDateTotal = 0;
		vPrevDateTotal = 0;
		vFilterRows = vRoomRented.FindRows(New Structure("Hotel, RoomRateIsComplimentary", vHotel, True));  
		For Each vRow In vFilterRows Do
			vCurDateTotal = vCurDateTotal + ?(vInRooms, vRow.RoomsRented, vRow.BedsRented);
			vPrevDateTotal = vCurDateTotal + ?(vInRooms, vRow.PrevRoomsRented, vRow.PrevBedsRented);
		EndDo;
		vArea.Parameters.mComplimentaryRooms = vCurDateTotal;
		vArea.Parameters.mComplimentaryRoomsLY = vPrevDateTotal;
		pSpreadsheet.Join(vArea);
	EndDo;
	
	// Houseuse rooms
	vArea = vTemplate.GetArea("HouseUseRooms|HeaderDescription");
	pSpreadsheet.Put(vArea);
	For Each vHotel In pHotelList Do
		vInRooms = Not vHotel.ShowReportsInBeds;
		vArea = vTemplate.GetArea("HouseUseRooms|HeaderHotel");
		vCurDateTotal = 0;
		vPrevDateTotal = 0;
		vFilterRows = vRoomRented.FindRows(New Structure("Hotel, RoomRateIsHouseUse", vHotel, True));  
		For Each vRow In vFilterRows Do
			vCurDateTotal = vCurDateTotal + ?(vInRooms, vRow.RoomsRented, vRow.BedsRented);
			vPrevDateTotal = vCurDateTotal + ?(vInRooms, vRow.PrevRoomsRented, vRow.PrevBedsRented);
		EndDo;
		vArea.Parameters.mHouseUseRooms = vCurDateTotal;
		vArea.Parameters.mHouseUseRoomsLY = vPrevDateTotal;
		pSpreadsheet.Join(vArea);
	EndDo;
	
	If ShowRoomsOccupiedPercent Then
		vArea = vTemplate.GetArea("RoomsVacantMinusBlocks|HeaderDescription");
		pSpreadsheet.Put(vArea);

		For Each vHotel In pHotelList Do
			vInRooms = Not vHotel.ShowReportsInBeds;
			vArea = vTemplate.GetArea("RoomsVacantMinusBlocks|HeaderHotel");
			vCurDateTotal = 0;
			vPrevDateTotal = 0;
			vHotelTotal = vHotelListTotals.FindRows(New Structure("Hotel", vHotel));
			If vHotelTotal.Count()>0 Then
				vCurDateTotal = ?(vInRooms, vHotelTotal[0].TotalRooms - vHotelTotal[0].RoomsOccupied, vHotelTotal[0].TotalBeds - vHotelTotal[0].BedsOccupied);
				vPrevDateTotal = ?(vInRooms, vHotelTotal[0].PrevTotalRooms - vHotelTotal[0].PrevRoomsOccupied, vHotelTotal[0].PrevTotalBeds - vHotelTotal[0].PrevBedsOccupied);
			EndIf;
			vArea.Parameters.mRoomsVacantMinusBlocks = vCurDateTotal;
			vArea.Parameters.mRoomsVacantMinusBlocksLY = vPrevDateTotal;
			pSpreadsheet.Join(vArea);
		EndDo;
	Else
		vArea = vTemplate.GetArea("RoomsVacant|HeaderDescription");
		pSpreadsheet.Put(vArea);
		
		For Each vHotel In pHotelList Do
			vInRooms = Not vHotel.ShowReportsInBeds;
			vArea = vTemplate.GetArea("RoomsVacant|HeaderHotel");
			vCurDateTotal = 0;
			vPrevDateTotal = 0;
			vHotelTotal = vHotelListTotals.FindRows(New Structure("Hotel",vHotel));
			vRentedTotal = vRoomRented.FindRows(New Structure("Hotel", vHotel));
			If vHotelTotal.Count() > 0 Then
				If vRentedTotal.Count() > 0 Then
					vCurDateTotal = ?(vInRooms, vHotelTotal[0].TotalRooms - vRentedTotal[0].RoomsRented, vHotelTotal[0].TotalBeds - vRentedTotal[0].BedsRented);
					vPrevDateTotal = ?(vInRooms, vHotelTotal[0].PrevTotalRooms - vRentedTotal[0].PrevRoomsRented, vHotelTotal[0].PrevTotalBeds - vRentedTotal[0].PrevBedsRented);
				Else
					vCurDateTotal = ?(vInRooms, vHotelTotal[0].TotalRooms, vHotelTotal[0].TotalBeds);
					vPrevDateTotal = ?(vInRooms, vHotelTotal[0].PrevTotalRooms, vHotelTotal[0].PrevTotalBeds);
				EndIf;
			EndIf;
			vArea.Parameters.mRoomsVacant = vCurDateTotal;
			vArea.Parameters.mRoomsVacantLY = vPrevDateTotal;
			pSpreadsheet.Join(vArea);
		EndDo;

		vArea = vTemplate.GetArea("RoomsVacantMinusBlocks|HeaderDescription");
		pSpreadsheet.Put(vArea);
		
		For Each vHotel In pHotelList Do
			vInRooms = Not vHotel.ShowReportsInBeds;
			vArea = vTemplate.GetArea("RoomsVacantMinusBlocks|HeaderHotel");
			vCurDateTotal = 0;
			vPrevDateTotal = 0;
			vHotelTotal = vHotelListTotals.FindRows(New Structure("Hotel",vHotel));
			vRentedTotal = vRoomRented.FindRows(New Structure("Hotel", vHotel));
			If vHotelTotal.Count() > 0 Then
				If vRentedTotal.Count() > 0 Then
					vCurDateTotal = ?(vInRooms, vHotelTotal[0].TotalRooms - vRentedTotal[0].RoomsRented - vHotelTotal[0].RoomsBlocked, vHotelTotal[0].TotalBeds - vRentedTotal[0].BedsRented - vHotelTotal[0].BedsBlocked);
					vPrevDateTotal = ?(vInRooms, vHotelTotal[0].PrevTotalRooms - vRentedTotal[0].PrevRoomsRented - vHotelTotal[0].PrevRoomsBlocked, vHotelTotal[0].PrevTotalBeds - vRentedTotal[0].PrevBedsRented - vHotelTotal[0].PrevBedsBlocked);
				Else
					vCurDateTotal = ?(vInRooms, vHotelTotal[0].TotalRooms - vHotelTotal[0].RoomsBlocked, vHotelTotal[0].TotalBeds - vHotelTotal[0].BedsBlocked);
					vPrevDateTotal = ?(vInRooms, vHotelTotal[0].PrevTotalRooms - vHotelTotal[0].PrevRoomsBlocked, vHotelTotal[0].PrevTotalBeds - vHotelTotal[0].PrevBedsBlocked);
				EndIf;
			EndIf;
			vArea.Parameters.mRoomsVacantMinusBlocks = vCurDateTotal;
			vArea.Parameters.mRoomsVacantMinusBlocksLY = vPrevDateTotal;
			pSpreadsheet.Join(vArea);
		EndDo;
	EndIf;
	
	// Put occupation percent
	vArea = vTemplate.GetArea("OccupationPercentHeader");
	pSpreadsheet.Put(vArea);           
	vArea = vTemplate.GetArea("OccupationPercentRooms|HeaderDescription");
	pSpreadsheet.Put(vArea);
	For Each vHotel In pHotelList Do
		vInRooms = Not vHotel.ShowReportsInBeds;
		vArea = vTemplate.GetArea("OccupationPercentRooms|HeaderHotel");
		vRoomsForSale = 0;
		vPrevRoomsForSale = 0;
		vRoomsRented = 0;
		vPrevRoomsRented = 0;
		vCurSpecRoomsBlocked = 0;
		vSpecRoomsBlockedLY = 0;
		vFilterRows = vHotelListTotals.FindRows(New Structure("Hotel", vHotel));  
		For Each vRow In vFilterRows Do
			vRoomsForSale = vCurDateTotal + ?(vInRooms, vRow.RoomsForSale, vRow.BedsForSale);
			vPrevRoomsForSale = vCurDateTotal + ?(vInRooms, vRow.PrevRoomsForSale, vRow.PrevBedsForSale);
			vCurSpecRoomsBlocked = vCurSpecRoomsBlocked + ?(vInRooms, vRow.CurSpecRoomsBlocked, vRow.CurSpecBedsBlocked);
			vSpecRoomsBlockedLY = vSpecRoomsBlockedLY + ?(vInRooms, vRow.PrevSpecRoomsBlocked, vRow.PrevSpecBedsBlocked);
		EndDo;
		vFilterRows = vRoomRented.FindRows(New Structure("Hotel", vHotel));
		For Each vRow In vFilterRows Do
			vRoomsRented = vRoomsRented + ?(vInRooms, vRow.RoomsRented, vRow.BedsRented);
			vPrevRoomsRented = vPrevRoomsRented + ?(vInRooms, vRow.PrevRoomsRented, vRow.PrevBedsRented);
		EndDo;
		vArea.Parameters.mOccupationRooms = Round(?((vRoomsForSale + vCurSpecRoomsBlocked) <> 0, 100 * (vRoomsRented + vCurSpecRoomsBlocked) / (vRoomsForSale + vCurSpecRoomsBlocked), 0), 2);
		vArea.Parameters.mOccupationRoomsLY = Round(?((vPrevRoomsForSale + vSpecRoomsBlockedLY) <> 0, 100 * (vPrevRoomsRented + vSpecRoomsBlockedLY) / (vPrevRoomsForSale + vSpecRoomsBlockedLY), 0), 2);
		pSpreadsheet.Join(vArea);
	EndDo;
	If Not DoNotShowComplimentaryRoomsRentedPercent Then
		vArea = vTemplate.GetArea("OccupationComplPercentRooms|HeaderDescription");
		pSpreadsheet.Put(vArea);
		For Each vHotel In pHotelList Do
			vInRooms = Not vHotel.ShowReportsInBeds;
			vArea = vTemplate.GetArea("OccupationComplPercentRooms|HeaderHotel");
			vRoomsForSale = 0;
			vPrevRoomsForSale = 0;
			vRoomsRented = 0;
			vPrevRoomsRented = 0;
			vCurSpecRoomsBlocked = 0;
			vSpecRoomsBlockedLY = 0;
			vComplimentaryRooms = 0;
			vHouseUseRooms = 0;
			vComplimentaryRoomsLY = 0;
			vHouseUseRoomsLY = 0;
			vFilterRows = vHotelListTotals.FindRows(New Structure("Hotel", vHotel));  
			For Each vRow In vFilterRows Do
				vRoomsForSale = vCurDateTotal + ?(vInRooms, vRow.RoomsForSale, vRow.BedsForSale);
				vPrevRoomsForSale = vCurDateTotal + ?(vInRooms, vRow.PrevRoomsForSale, vRow.PrevBedsForSale);
				vCurSpecRoomsBlocked = vCurSpecRoomsBlocked + ?(vInRooms, vRow.CurSpecRoomsBlocked, vRow.CurSpecBedsBlocked);
				vSpecRoomsBlockedLY = vSpecRoomsBlockedLY + ?(vInRooms, vRow.PrevSpecRoomsBlocked, vRow.PrevSpecBedsBlocked);
			EndDo;
			vFilterRows = vRoomRented.FindRows(New Structure("Hotel", vHotel));
			For Each vRow In vFilterRows Do
				vRoomsRented = vRoomsRented + ?(vInRooms, vRow.RoomsRented, vRow.BedsRented);
				vPrevRoomsRented = vPrevRoomsRented + ?(vInRooms, vRow.PrevRoomsRented, vRow.PrevBedsRented);
				If vRow.RoomRateIsComplimentary Then
					vComplimentaryRooms = vComplimentaryRooms + ?(vInRooms, vRow.RoomsRented, vRow.BedsRented);
					vComplimentaryRoomsLY = vComplimentaryRoomsLY + ?(vInRooms, vRow.PrevRoomsRented, vRow.PrevBedsRented);
				EndIf;	
				If vRow.RoomRateIsHouseUse Then
					vHouseUseRooms = vHouseUseRooms + ?(vInRooms, vRow.RoomsRented, vRow.BedsRented);
					vHouseUseRoomsLY = vHouseUseRoomsLY + ?(vInRooms, vRow.PrevRoomsRented, vRow.PrevBedsRented);
				EndIf;
			EndDo;
			vArea.Parameters.mOccupationComplRooms = Round(?((vRoomsForSale + vCurSpecRoomsBlocked) <> 0, 100 * (vRoomsRented + vCurSpecRoomsBlocked - vComplimentaryRooms - vHouseUseRooms) / (vRoomsForSale + vCurSpecRoomsBlocked), 0), 2);
			vArea.Parameters.mOccupationComplRoomsLY = Round(?((vPrevRoomsForSale + vSpecRoomsBlockedLY) <> 0, 100 * (vPrevRoomsRented + vSpecRoomsBlockedLY - vComplimentaryRoomsLY - vHouseUseRoomsLY) / (vPrevRoomsForSale + vSpecRoomsBlockedLY), 0), 2);
			pSpreadsheet.Join(vArea);
		EndDo;
	EndIf;
	If Not DoNotShowTotalRoomsRentedPercent Then
		vArea = vTemplate.GetArea("OccupationPercentRoomsWithoutBlocks|HeaderDescription");
		pSpreadsheet.Put(vArea);
		For Each vHotel In pHotelList Do
			vInRooms = Not vHotel.ShowReportsInBeds;
			vArea = vTemplate.GetArea("OccupationPercentRoomsWithoutBlocks|HeaderHotel");
			vTotalRooms = 0;
			vPrevTotalRooms = 0;
			vRoomsRented = 0;
			vPrevRoomsRented = 0;
			vCurSpecRoomsBlocked = 0;
			vSpecRoomsBlockedLY = 0;
			vComplimentaryRooms = 0;
			vComplimentaryRoomsLY = 0;
			vFilterRows = vHotelListTotals.FindRows(New Structure("Hotel", vHotel));  
			For Each vRow In vFilterRows Do
				vTotalRooms = vTotalRooms + ?(vInRooms, vRow.TotalRooms, vRow.TotalBeds);
				vPrevTotalRooms = vPrevTotalRooms + ?(vInRooms, vRow.PrevTotalRooms, vRow.PrevTotalBeds);
				vCurSpecRoomsBlocked = vCurSpecRoomsBlocked + ?(vInRooms, vRow.CurSpecRoomsBlocked, vRow.CurSpecBedsBlocked);
				vSpecRoomsBlockedLY = vSpecRoomsBlockedLY + ?(vInRooms, vRow.PrevSpecRoomsBlocked, vRow.PrevSpecBedsBlocked);
			EndDo;
			vFilterRows = vRoomRented.FindRows(New Structure("Hotel", vHotel));
			For Each vRow In vFilterRows Do
				vRoomsRented = vRoomsRented + ?(vInRooms, vRow.RoomsRented, vRow.BedsRented);
				vPrevRoomsRented = vPrevRoomsRented + ?(vInRooms, vRow.PrevRoomsRented, vRow.PrevBedsRented);
				If vRow.RoomRateIsComplimentary Then
					vComplimentaryRooms = vComplimentaryRooms + ?(vInRooms, vRow.RoomsRented, vRow.BedsRented);
					vComplimentaryRoomsLY = vComplimentaryRoomsLY + ?(vInRooms, vRow.PrevRoomsRented, vRow.PrevBedsRented);
				EndIf;	
			EndDo;
			vArea.Parameters.mOccupationRoomsNoBlocks = Round(?(vTotalRooms <> 0, 100 * (vRoomsRented + vCurSpecRoomsBlocked) / vTotalRooms, 0), 2);
			vArea.Parameters.mOccupationRoomsNoBlocksLY = Round(?(vPrevTotalRooms <> 0, 100 * (vPrevRoomsRented + vSpecRoomsBlockedLY) / vPrevTotalRooms, 0), 2);
			pSpreadsheet.Join(vArea);
		EndDo;
	EndIf;
	If Not DoNotShowTotalRoomsRentedPercent Then
		vArea = vTemplate.GetArea("OccupationPercentRoomsWithoutBlocksWithoutCompl|HeaderDescription");
		pSpreadsheet.Put(vArea);
		For Each vHotel In pHotelList Do
			vInRooms = Not vHotel.ShowReportsInBeds;
			vArea = vTemplate.GetArea("OccupationPercentRoomsWithoutBlocksWithoutCompl|HeaderHotel");
			vTotalRooms = 0;
			vPrevTotalRooms = 0;
			vRoomsRented = 0;
			vPrevRoomsRented = 0;
			vCurSpecRoomsBlocked = 0;
			vSpecRoomsBlockedLY = 0;
			vComplimentaryRooms = 0;
			vHouseUseRooms = 0;
			vComplimentaryRoomsLY = 0;
			vHouseUseRoomsLY = 0;
			vFilterRows = vHotelListTotals.FindRows(New Structure("Hotel",vHotel));  
			For Each vRow In vFilterRows Do
				vTotalRooms = vTotalRooms + ?(vInRooms, vRow.TotalRooms, vRow.TotalBeds);
				vPrevTotalRooms = vPrevTotalRooms + ?(vInRooms, vRow.PrevTotalRooms, vRow.PrevTotalBeds);
				vCurSpecRoomsBlocked = vCurSpecRoomsBlocked + ?(vInRooms, vRow.CurSpecRoomsBlocked, vRow.CurSpecBedsBlocked);
				vSpecRoomsBlockedLY = vSpecRoomsBlockedLY + ?(vInRooms, vRow.PrevSpecRoomsBlocked, vRow.PrevSpecBedsBlocked);
			EndDo;
			vFilterRows = vRoomRented.FindRows(New Structure("Hotel",vHotel));
			For Each vRow In vFilterRows Do
				vRoomsRented = vRoomsRented + ?(vInRooms, vRow.RoomsRented, vRow.BedsRented);
				vPrevRoomsRented = vPrevRoomsRented + ?(vInRooms, vRow.PrevRoomsRented, vRow.PrevBedsRented);
				If vRow.RoomRateIsComplimentary Then
					vComplimentaryRooms = vComplimentaryRooms + ?(vInRooms, vRow.RoomsRented, vRow.BedsRented);
					vComplimentaryRoomsLY = vComplimentaryRoomsLY + ?(vInRooms, vRow.PrevRoomsRented, vRow.PrevBedsRented);
				EndIf;	
				If vRow.RoomRateIsHouseUse Then
					vHouseUseRooms = vHouseUseRooms + ?(vInRooms, vRow.RoomsRented, vRow.BedsRented);
					vHouseUseRoomsLY = vHouseUseRoomsLY + ?(vInRooms, vRow.PrevRoomsRented, vRow.PrevBedsRented);
				EndIf;
			EndDo;
			vArea.Parameters.mOccupationRoomsNoBlocksNoCompl = Round(?(vTotalRooms <> 0, 100 * (vRoomsRented + vCurSpecRoomsBlocked) / vTotalRooms, 0), 2);
			vArea.Parameters.mOccupationRoomsNoBlocksNoComplLY = Round(?(vPrevTotalRooms <> 0, 100 * (vPrevRoomsRented + vSpecRoomsBlockedLY) / vPrevTotalRooms, 0), 2);
			pSpreadsheet.Join(vArea);
		EndDo;
	EndIf;	
	vRoomTypeListBalance = GetTotalSalesByHotelsRoomTypes(pHotelList);
	If vRoomTypeListBalance.Count() Then
		// Room types
		vArea = vTemplate.GetArea("OccupationRoomTypesSalesHeader|HeaderDescription");
		pSpreadsheet.Put(vArea);   
		vIdRow = 1;
		While vIdRow <= pHotelList.Count() Do
			vArea = vTemplate.GetArea("OccupationRoomTypesSalesHeader|HeaderHotel");
			pSpreadsheet.Join(vArea); 
			vIdRow = vIdRow + 1;
		EndDo;
		// Group by room type
		vRoomTypeList = vRoomTypeListBalance.Copy(, "RoomTypeGroupingForReports");
		vRoomTypeList.GroupBy("RoomTypeGroupingForReports");
		For Each vRowRTCode In vRoomTypeList Do
			vRTCode = TrimAll(vRowRTCode.RoomTypeGroupingForReports);
			vArea = vTemplate.GetArea("OccupationRoomTypesSalesRow|HeaderDescription");
			pSpreadsheet.Put(vArea);
			For Each vHotel In pHotelList Do
				vInRooms = Not vHotel.ShowReportsInBeds;
				vArea = vTemplate.GetArea("OccupationRoomTypesSalesRow|HeaderHotel");
				vArea.Parameters.mRoomTypeCodeSalesRow = vRTCode;
				vFilterRows = vRoomTypeListBalance.FindRows(New Structure("Hotel, RoomTypeGroupingForReports", vHotel, vRTCode));
				vRoomTypeRented = 0;
				vRoomTypeRentedLY = 0;
				If vFilterRows.Count()>0 Then
					vRoomTypeRented = ?(vInRooms, vFilterRows[0].RoomsRented, vFilterRows[0].BedsRented);
					vRoomTypeRentedLY = ?(vInRooms, vFilterRows[0].PrevRoomsRented, vFilterRows[0].PrevBedsRented);
				EndIf;	
				vArea.Parameters.mRoomTypeCodeSalesValue = vRoomTypeRented;
				vArea.Parameters.mRoomTypeCodeSalesValueLY = vRoomTypeRentedLY;
				pSpreadsheet.Join(vArea);
		    EndDo;
		EndDo;
		vArea = vTemplate.GetArea("OccupationRoomTypesBalanceHeader|HeaderDescription");
		pSpreadsheet.Put(vArea);  
		vIdRow = 1;
		While vIdRow <=  pHotelList.Count() Do
			vArea = vTemplate.GetArea("OccupationRoomTypesBalanceHeader|HeaderHotel");
			pSpreadsheet.Join(vArea);   
			vIdRow = vIdRow + 1;
		EndDo;
		For Each vRowRTCode In vRoomTypeList Do
			vRTCode = TrimAll(vRowRTCode.RoomTypeGroupingForReports);
			vArea = vTemplate.GetArea("OccupationRoomTypesBalanceRow|HeaderDescription");
			pSpreadsheet.Put(vArea);
			For Each vHotel In pHotelList Do
				vInRooms = Not vHotel.ShowReportsInBeds;
				vArea = vTemplate.GetArea("OccupationRoomTypesBalanceRow|HeaderHotel");
				vArea.Parameters.mRoomTypeCodeBalanceRow = vRTCode;
				vFilterRows = vRoomTypeListBalance.FindRows(New Structure("Hotel, RoomTypeGroupingForReports", vHotel, vRTCode));
				vRoomTypeToSales = 0;
				vRoomTypeToSalesLY = 0;
				If vFilterRows.Count() > 0 Then
					vRoomTypeToSales = ?(vInRooms, vFilterRows[0].RoomBalance, vFilterRows[0].BedsBalance);
					vRoomTypeToSalesLY = ?(vInRooms, vFilterRows[0].PrevRoomBalance, vFilterRows[0].PrevBedsBalance);
				EndIf;	
				vArea.Parameters.mRoomTypeCodeBalanceValue = vRoomTypeToSales;
				vArea.Parameters.mRoomTypeCodeBalanceValueLY = vRoomTypeToSalesLY;
				pSpreadsheet.Join(vArea);
		    EndDo;
		EndDo;
	EndIf;
	
	vWithVAT = Not ShowAmountsWithoutVAT;

	// Average room income
	vArea = vTemplate.GetArea("AverageRoomPrice|HeaderDescription");
	pSpreadsheet.Put(vArea);
	For Each vHotel In pHotelList Do
		vInRooms = Not vHotel.ShowReportsInBeds;
		vArea = vTemplate.GetArea("AverageRoomPrice|HeaderHotel");
		vRoomsRented = 0;
		vRoomsRentedLY = 0;
		vRoomsIncome = 0;
		vRoomsIncomeLY = 0;
		vComplimentaryRooms = 0;
		vHouseUseRooms = 0;
		vComplimentaryRoomsLY = 0;
		vHouseUseRoomsLY = 0;
		vFilterRows = vRoomRented.FindRows(New Structure("Hotel",vHotel));
		For Each vRow In vFilterRows Do
			vRoomsRented = vRoomsRented + ?(vInRooms, vRow.RoomsRented, vRow.BedsRented);
			vRoomsRentedLY = vRoomsRentedLY + ?(vInRooms, vRow.PrevRoomsRented, vRow.PrevBedsRented);
			If vWithVAT Then
				vRoomsIncome = vRoomsIncome + vRow.RoomRevenue;
				vRoomsIncomeLY = vRoomsIncomeLY + vRow.PrevRoomRevenue;
			Else
				vRoomsIncome = vRoomsIncome + vRow.RoomRevenueWithoutVAT;
				vRoomsIncomeLY = vRoomsIncomeLY + vRow.PrevRoomRevenueWithoutVAT;
			EndIf;	
			If vRow.RoomRateIsComplimentary Then
				vComplimentaryRooms = vComplimentaryRooms + ?(vInRooms, vRow.RoomsRented, vRow.BedsRented);
				vComplimentaryRoomsLY = vComplimentaryRoomsLY + ?(vInRooms, vRow.PrevRoomsRented, vRow.PrevBedsRented);
			EndIf;	
			If vRow.RoomRateIsHouseUse Then
				vHouseUseRooms = vHouseUseRooms + ?(vInRooms, vRow.RoomsRented, vRow.BedsRented);
				vHouseUseRoomsLY = vHouseUseRoomsLY + ?(vInRooms, vRow.PrevRoomsRented, vRow.PrevBedsRented);
			EndIf;
		EndDo;
		vArea.Parameters.mAvgRoomPrice = Round(?(vRoomsRented <> 0, vRoomsIncome / vRoomsRented, 0), 2);
		vArea.Parameters.mAvgRoomPriceLY = Round(?(vRoomsRentedLY <> 0, vRoomsIncomeLY / vRoomsRentedLY, 0), 2);
		vArea.Parameters.mAvgRoomPriceNoCompl = Round(?((vRoomsRented - vComplimentaryRooms - vHouseUseRooms) <> 0, vRoomsIncome / (vRoomsRented - vComplimentaryRooms - vHouseUseRooms), 0), 2);
		vArea.Parameters.mAvgRoomPriceNoComplLY = Round(?((vRoomsRentedLY - vComplimentaryRoomsLY - vHouseUseRoomsLY) <> 0, vRoomsIncomeLY/(vRoomsRentedLY - vComplimentaryRoomsLY - vHouseUseRoomsLY), 0), 2);
		pSpreadsheet.Join(vArea);
	EndDo;
	vArea = vTemplate.GetArea("AverageRoomPriceInclAddSrv|HeaderDescription");
	pSpreadsheet.Put(vArea);
	For Each vHotel In pHotelList Do
		vInRooms = Not vHotel.ShowReportsInBeds;
		vArea = vTemplate.GetArea("AverageRoomPriceInclAddSrv|HeaderHotel");
		vRoomsRented = 0;
		vRoomsRentedLY = 0;
		vTotalIncome = 0;
		vTotalIncomeLY = 0;
		vComplimentaryRooms = 0;
		vHouseUseRooms = 0;
		vComplimentaryRoomsLY = 0;
		vHouseUseRoomsLY = 0;

		vFilterRows = vRoomRented.FindRows(New Structure("Hotel",vHotel));
		For Each vRow In vFilterRows Do
			vRoomsRented = vRoomsRented + ?(vInRooms, vRow.RoomsRented, vRow.BedsRented);
			vRoomsRentedLY = vRoomsRentedLY + ?(vInRooms, vRow.PrevRoomsRented, vRow.PrevBedsRented);
			If vWithVAT Then
				vTotalIncome = vTotalIncome + vRow.Sales;
				vTotalIncomeLY = vTotalIncomeLY + vRow.PrevSales;
			Else
				vTotalIncome = vTotalIncome + vRow.SalesWithoutVAT;
				vTotalIncomeLY = vTotalIncomeLY + vRow.PrevSalesWithoutVAT;
			EndIf;	
			If vRow.RoomRateIsComplimentary Then
				vComplimentaryRooms = vComplimentaryRooms + ?(vInRooms, vRow.RoomsRented, vRow.BedsRented);
				vComplimentaryRoomsLY = vComplimentaryRoomsLY + ?(vInRooms, vRow.PrevRoomsRented, vRow.PrevBedsRented);
			EndIf;	
			If vRow.RoomRateIsHouseUse Then
				vHouseUseRooms = vHouseUseRooms + ?(vInRooms, vRow.RoomsRented, vRow.BedsRented);
				vHouseUseRoomsLY = vHouseUseRoomsLY + ?(vInRooms, vRow.PrevRoomsRented, vRow.PrevBedsRented);
			EndIf;
		EndDo;
		vArea.Parameters.mAvgRoomPriceInclAddSrv = Round(?(vRoomsRented <> 0, vTotalIncome / vRoomsRented, 0), 2);
		vArea.Parameters.mAvgRoomPriceInclAddSrvLY = Round(?(vRoomsRentedLY <> 0, vTotalIncomeLY / vRoomsRentedLY, 0), 2);
		pSpreadsheet.Join(vArea);
	EndDo;
	vArea = vTemplate.GetArea("AverageRoomIncome|HeaderDescription");
	pSpreadsheet.Put(vArea);
	For Each vHotel In pHotelList Do
		vInRooms = Not vHotel.ShowReportsInBeds;
		vArea = vTemplate.GetArea("AverageRoomIncome|HeaderHotel");
		vRoomsForSale = 0;
		vRoomsForSaleLY = 0;
		vSpecRoomsBlocked = 0;
		vSpecRoomsBlockedLY = 0;
		vRoomsIncome = 0;
		vRoomsIncomeLY = 0;
		vTotalRooms = 0;
		vTotalRoomsLY = 0;
		vFilterRows = vHotelListTotals.FindRows(New Structure("Hotel",vHotel));  
		For Each vRow In vFilterRows Do
			vRoomsForSale = vCurDateTotal + ?(vInRooms, vRow.RoomsForSale, vRow.BedsForSale);
			vRoomsForSaleLY = vRoomsForSaleLY + ?(vInRooms, vRow.PrevRoomsForSale, vRow.PrevBedsForSale);
			vSpecRoomsBlocked = vSpecRoomsBlocked + ?(vInRooms, vRow.CurSpecRoomsBlocked, vRow.CurSpecBedsBlocked);
			vSpecRoomsBlockedLY = vSpecRoomsBlockedLY + ?(vInRooms, vRow.PrevSpecRoomsBlocked, vRow.PrevSpecBedsBlocked);
			vTotalRooms = vTotalRooms + ?(vInRooms, vRow.TotalRooms, vRow.TotalBeds);
			vTotalRoomsLY = vTotalRoomsLY + ?(vInRooms, vRow.PrevTotalRooms, vRow.PrevTotalBeds);
		EndDo;
		vFilterRows = vRoomRented.FindRows(New Structure("Hotel",vHotel));
		For Each vRow In vFilterRows Do
			If vWithVAT Then
				vRoomsIncome = vRoomsIncome + vRow.RoomRevenue;
				vRoomsIncomeLY = vRoomsIncomeLY + vRow.PrevRoomRevenue;
			Else
				vRoomsIncome = vRoomsIncome + vRow.RoomRevenueWithoutVAT;
				vRoomsIncomeLY = vRoomsIncomeLY + vRow.PrevRoomRevenueWithoutVAT;
			EndIf;	
		EndDo;
		vArea.Parameters.mAvgAvailRoomIncome = Round(?((vRoomsForSale + vSpecRoomsBlocked) <> 0, vRoomsIncome / (vRoomsForSale + vSpecRoomsBlocked), 0), 2);
		vArea.Parameters.mAvgRoomIncome = Round(?(vTotalRooms <> 0, vRoomsIncome / vTotalRooms, 0), 2);
		vArea.Parameters.mAvgAvailRoomIncomeLY = Round(?((vRoomsForSaleLY + vSpecRoomsBlockedLY) <> 0, vRoomsIncomeLY / (vRoomsForSaleLY + vSpecRoomsBlockedLY), 0), 2);
		vArea.Parameters.mAvgRoomIncomeLY = Round(?(vTotalRoomsLY <> 0, vRoomsIncomeLY / vTotalRoomsLY, 0), 2);
		pSpreadsheet.Join(vArea);
	EndDo;
	
	// 2. Guests summary indexes
	
	// Put section header
	vArea = vTemplate.GetArea("GuestsSummaryHeader");
	pSpreadsheet.Put(vArea);
	vArea = vTemplate.GetArea("GuestsHeader");
	pSpreadsheet.Put(vArea);

	// Run query to get number of guest days
	vGuestStats = GetNumberOfGuestDays(pHotelList);
	// Group by client type
	vClientTypes = vGuestStats.Copy(,"ClientType");
	vClientTypes.GroupBy("ClientType");
	For Each vClientTypeRow In vClientTypes Do
		vArea = vTemplate.GetArea("GuestsByClientType|HeaderDescription");
		vArea.Parameters.mClientType =  ?(ValueIsFilled(vClientTypeRow.ClientType), vClientTypeRow.ClientType, NStr("en = '<Normal guest>'; de = '<Normaler Gast>'; ru = '<Обычный гость>'"));
		pSpreadsheet.Put(vArea);
		For Each vHotel In pHotelList Do
			vArea = vTemplate.GetArea("GuestsByClientType|HeaderHotel");
			vGuests = 0;
			vGuestLY = 0;
			vFilterRows = vGuestStats.FindRows(New Structure("Hotel, ClientType", vHotel, vClientTypeRow.ClientType));
			For Each vRow In vFilterRows Do
				vGuests = vGuests + vRow.GuestDaysTurnover;
				vGuestLY = vGuestLY + vRow.GuestDaysTurnoverLY;
			EndDo;
			vArea.Parameters.mGuests = vGuests;
			vArea.Parameters.mGuestsLY = vGuestLY;
			pSpreadsheet.Join(vArea);
		EndDo;
	EndDo;
	If vClientTypes.Count() > 1 Then
		vArea = vTemplate.GetArea("GuestsFooter|HeaderDescription");
		pSpreadsheet.Put(vArea);
		For Each vHotel In pHotelList Do
			vArea = vTemplate.GetArea("GuestsFooter|HeaderHotel");
			vGuests = 0;
			vGuestLY = 0;
			vFilterRows = vGuestStats.FindRows(New Structure("Hotel", vHotel));
			For Each vRow In vFilterRows Do
				vGuests = vGuests + vRow.GuestDaysTurnover;
				vGuestLY = vGuestLY + vRow.GuestDaysTurnoverLY;
			EndDo;
			vArea.Parameters.mGuests = vGuests;
			vArea.Parameters.mGuestsLY = vGuestLY;
			pSpreadsheet.Join(vArea);
		EndDo;
	EndIf;
	// Put guests statistics
	vArea = vTemplate.GetArea("AverageNumberOfGuestsPerRoom|HeaderDescription");
	pSpreadsheet.Put(vArea);
	For Each vHotel In pHotelList Do
		vInRooms = Not vHotel.ShowReportsInBeds;
		vArea = vTemplate.GetArea("AverageNumberOfGuestsPerRoom|HeaderHotel");
		vRoomsRented = 0;
		vRoomsRentedLY = 0;
		vGuests = 0;
		vGuestsLY = 0;
		vFilterRows = vRoomRented.FindRows(New Structure("Hotel", vHotel));
		For Each vRow In vFilterRows Do
			vRoomsRented = vRoomsRented + ?(vInRooms, vRow.RoomsRented, vRow.BedsRented);
			vRoomsRentedLY = vRoomsRentedLY + ?(vInRooms, vRow.PrevRoomsRented, vRow.PrevBedsRented);
		EndDo;	
		vFilterRows = vGuestStats.FindRows(New Structure("Hotel", vHotel));
		For Each vRow In vFilterRows Do
			vGuests = vGuests + vRow.GuestDaysTurnover;
			vGuestsLY = vGuestsLY + vRow.GuestDaysTurnoverLY;
		EndDo;
		vArea.Parameters.mAvgNumberOfGuests = Round(?(vRoomsRented <> 0, vGuests / vRoomsRented, 0), 2);;
		vArea.Parameters.mAvgNumberOfGuestsLY = Round(?(vRoomsRentedLY <> 0, vGuestsLY / vRoomsRentedLY, 0), 2);;
		pSpreadsheet.Join(vArea);
	EndDo;	
	vArea = vTemplate.GetArea("AverageGuestLengthOfStay|HeaderDescription");
	pSpreadsheet.Put(vArea);
	For Each vHotel In pHotelList Do
		vArea = vTemplate.GetArea("AverageGuestLengthOfStay|HeaderHotel");
		vCheckedInGuests = 0;
		vCheckedInGuestsLY = 0;
		vGuests = 0;
		vGuestsLY = 0;
		vFilterRows = vGuestStats.FindRows(New Structure("Hotel", vHotel));
		For Each vRow In vFilterRows Do
			vGuests = vGuests + vRow.GuestDaysTurnover;
			vGuestsLY = vGuestsLY + vRow.GuestDaysTurnoverLY;
			vCheckedInGuests = vCheckedInGuests + vRow.GuestsCheckedInTurnover;
			vCheckedInGuestsLY = vCheckedInGuestsLY + vRow.GuestsCheckedInTurnoverLY;
		EndDo;
		vArea.Parameters.mAvgGuestLengthOfStay = Round(?(vCheckedInGuests <> 0, vGuests / vCheckedInGuests, 0), 2);
		vArea.Parameters.mAvgGuestLengthOfStayLY = Round(?(vCheckedInGuestsLY <> 0, vGuestsLY / vCheckedInGuestsLY, 0), 2);
		pSpreadsheet.Join(vArea);
	EndDo;	
	vArea = vTemplate.GetArea("AverageGuestPrice|HeaderDescription");
	pSpreadsheet.Put(vArea);
	For Each vHotel In pHotelList Do
		vArea = vTemplate.GetArea("AverageGuestPrice|HeaderHotel");
		vRoomsIncome = 0;
		vRoomsIncomeLY = 0;
		vGuests = 0;
		vGuestsLY = 0;
		vFilterRows = vGuestStats.FindRows(New Structure("Hotel", vHotel));
		For Each vRow In vFilterRows Do
			vGuests = vGuests + vRow.GuestDaysTurnover;
			vGuestsLY = vGuestsLY + vRow.GuestDaysTurnoverLY;
		EndDo;
		vFilterRows = vRoomRented.FindRows(New Structure("Hotel",vHotel));
		For Each vRow In vFilterRows Do
			If vWithVAT Then
				vRoomsIncome = vRoomsIncome + vRow.RoomRevenue;
				vRoomsIncomeLY = vRoomsIncomeLY + vRow.PrevRoomRevenue;
			Else
				vRoomsIncome = vRoomsIncome + vRow.RoomRevenueWithoutVAT;
				vRoomsIncomeLY = vRoomsIncomeLY + vRow.PrevRoomRevenueWithoutVAT;
			EndIf;	
		EndDo;
		vArea.Parameters.mAvgGuestPrice = Round(?(vGuests <> 0, vRoomsIncome / vGuests, 0), 2);
		vArea.Parameters.mAvgGuestPriceLY = Round(?(vGuestsLY <> 0, vRoomsIncomeLY / vGuestsLY, 0), 2);
		pSpreadsheet.Join(vArea);
	EndDo;
	vArea = vTemplate.GetArea("AverageGuestIncome|HeaderDescription");
	pSpreadsheet.Put(vArea);
	For Each vHotel In pHotelList Do
		vArea = vTemplate.GetArea("AverageGuestIncome|HeaderHotel");
		vTotalIncome = 0;
		vTotalIncomeLY = 0;
		vGuests = 0;
		vGuestsLY = 0;
		vFilterRows = vGuestStats.FindRows(New Structure("Hotel", vHotel));
		For Each vRow In vFilterRows Do
			vGuests = vGuests + vRow.GuestDaysTurnover;
			vGuestsLY = vGuestsLY + vRow.GuestDaysTurnoverLY;
		EndDo;
		vFilterRows = vRoomRented.FindRows(New Structure("Hotel",vHotel));
		For Each vRow In vFilterRows Do
			If vWithVAT Then
				vTotalIncome = vTotalIncome + vRow.Sales;
				vTotalIncomeLY = vTotalIncomeLY + vRow.PrevSales;
			Else
				vTotalIncome = vTotalIncome + vRow.SalesWithoutVAT;
				vTotalIncomeLY = vTotalIncomeLY + vRow.PrevSalesWithoutVAT;
			EndIf;	
		EndDo;
		vArea.Parameters.mAvgGuestIncome = Round(?(vGuests <> 0, vTotalIncome / vGuests, 0), 2);
		vArea.Parameters.mAvgGuestIncomeLY = Round(?(vGuestsLY <> 0, vTotalIncomeLY / vGuestsLY, 0), 2);
		pSpreadsheet.Join(vArea);
	EndDo;
	
	// 3. Check-in summary indexes
	
	// Put section header
	vArea = vTemplate.GetArea("CheckInSummaryHeader");
	pSpreadsheet.Put(vArea);

	// Run query to get number of checked-in guests
	vCheckedInGuests = GetCheckedInGuests(pHotelList);
	If vInRooms Then
		vArea = vTemplate.GetArea("RoomsReserved|HeaderDescription");
		pSpreadsheet.Put(vArea);
		For Each vHotel In pHotelList Do
			vArea = vTemplate.GetArea("RoomsReserved|HeaderHotel");
			vRooms = 0;
			vRoomsLY = 0;
			vFilterRows = vCheckedInGuests.FindRows(New Structure("Hotel, ParentDocIsByReservation", vHotel, True));
			For Each vRow In vFilterRows Do
				vRooms = vRooms + vRow.RoomsCheckedInTurnover;
				vRoomsLY = vRoomsLY + vRow.RoomsCheckedInTurnoverLY;
			EndDo;
			vArea.Parameters.mRoomsReserved = vRooms;
			vArea.Parameters.mRoomsReservedLY = vRoomsLY;
			pSpreadsheet.Join(vArea);
		EndDo;
	Else
		vArea = vTemplate.GetArea("BedsReserved|HeaderDescription");
		pSpreadsheet.Put(vArea);
		For Each vHotel In pHotelList Do
			vArea = vTemplate.GetArea("BedsReserved|HeaderHotel");
			vBeds = 0;
			vBedsLY = 0;
			vFilterRows = vCheckedInGuests.FindRows(New Structure("Hotel, ParentDocIsByReservation", vHotel, True));
			For Each vRow In vFilterRows Do
				vBeds = vBeds + vRow.BedsCheckedInTurnover;
				vBedsLY = vBedsLY + vRow.BedsCheckedInTurnoverLY;
			EndDo;
			vArea.Parameters.mBedsReserved = vBeds;
			vArea.Parameters.mBedsReservedLY = vBedsLY;
			pSpreadsheet.Join(vArea);
		EndDo;
	EndIf;
	vArea = vTemplate.GetArea("GuestsReserved|HeaderDescription");
	pSpreadsheet.Put(vArea);
	For Each vHotel In pHotelList Do
		vArea = vTemplate.GetArea("GuestsReserved|HeaderHotel");
		vGuests = 0;
		vGuestsLY = 0;
		vFilterRows = vCheckedInGuests.FindRows(New Structure("Hotel, ParentDocIsByReservation", vHotel, True));
		For Each vRow In vFilterRows Do
			vGuests = vGuests + vRow.GuestsCheckedInTurnover;
			vGuestsLY = vGuestsLY + vRow.GuestsCheckedInTurnoverLY;
		EndDo;
		vArea.Parameters.mGuestsReserved = vGuests;
		vArea.Parameters.mGuestsReservedLY = vGuestsLY;
		pSpreadsheet.Join(vArea);
	EndDo;
	If vInRooms Then
		vArea = vTemplate.GetArea("RoomsWalkIn|HeaderDescription");
		pSpreadsheet.Put(vArea);
		For Each vHotel In pHotelList Do
			vArea = vTemplate.GetArea("RoomsWalkIn|HeaderHotel");
			vRooms = 0;
			vRoomsLY = 0;
			vFilterRows = vCheckedInGuests.FindRows(New Structure("Hotel, ParentDocIsByReservation", vHotel, False));
			For Each vRow In vFilterRows Do
				vRooms = vRooms + vRow.RoomsCheckedInTurnover;
				vRoomsLY = vRoomsLY + vRow.RoomsCheckedInTurnoverLY;
			EndDo;
			vArea.Parameters.mRoomsWalkIn = vRooms;
			vArea.Parameters.mRoomsWalkInLY = vRoomsLY;
			pSpreadsheet.Join(vArea);
		EndDo;
	Else
		vArea = vTemplate.GetArea("BedsWalkIn|HeaderDescription");
		pSpreadsheet.Put(vArea);
		For Each vHotel In pHotelList Do
			vArea = vTemplate.GetArea("BedsWalkIn|HeaderHotel");
			vBeds = 0;
			vBedsLY = 0;
			vFilterRows = vCheckedInGuests.FindRows(New Structure("Hotel, ParentDocIsByReservation", vHotel, False));
			For Each vRow In vFilterRows Do
				vBeds = vBeds + vRow.BedsCheckedInTurnover;
				vBedsLY = vBedsLY + vRow.BedsCheckedInTurnoverLY;
			EndDo;
			vArea.Parameters.mBedsWalkIn = vBeds;
			vArea.Parameters.mBedsWalkInLY = vBedsLY;
			pSpreadsheet.Join(vArea);
		EndDo;
	EndIf;
	vArea = vTemplate.GetArea("GuestsWalkIn|HeaderDescription");
	pSpreadsheet.Put(vArea);
	For Each vHotel In pHotelList Do
		vArea = vTemplate.GetArea("GuestsWalkIn|HeaderHotel");
		vGuests = 0;
		vGuestsLY = 0;
		vFilterRows = vCheckedInGuests.FindRows(New Structure("Hotel, ParentDocIsByReservation", vHotel, False));
		For Each vRow In vFilterRows Do
			vGuests = vGuests + vRow.GuestsCheckedInTurnover;
			vGuestsLY = vGuestsLY + vRow.GuestsCheckedInTurnoverLY;
		EndDo;
		vArea.Parameters.mGuestsWalkIn = vGuests;
		vArea.Parameters.mGuestsWalkInLY = vGuestsLY;
		pSpreadsheet.Join(vArea);
	EndDo;
	
	// 4. Pickup data
	
	vArea = vTemplate.GetArea("PickupHeader");
	pSpreadsheet.Put(vArea);
	
	vPickupDataByHotels = GetPickupByHotels(pHotelList, vWithVAT);
	
	vArea = vTemplate.GetArea("PickupRooms|HeaderDescription");
	pSpreadsheet.Put(vArea);
	For Each vHotel In pHotelList Do
		vInRooms = Not vHotel.ShowReportsInBeds;
		If vInRooms Then
			vArea = vTemplate.GetArea("PickupRooms|HeaderHotel");
		Else
			vArea = vTemplate.GetArea("PickupBeds|HeaderHotel");
		EndIf;

		vHotelPickupDataRow = vPickupDataByHotels.Find(vHotel, "Hotel");
		If vHotelPickupDataRow <> Undefined Then
			If vInRooms Then
				vArea.Parameters.mRoomsReserved = vHotelPickupDataRow.RoomsReserved;
				vArea.Parameters.mComplimentaryRoomsReserved = vHotelPickupDataRow.ComplimentaryRoomsReserved;
				vArea.Parameters.mHouseuseRoomsReserved = vHotelPickupDataRow.HouseuseRoomsReserved;
				vArea.Parameters.mDayuseRoomsReserved = vHotelPickupDataRow.DayuseRoomsReserved;
				vArea.Parameters.mRoomsCancelled = vHotelPickupDataRow.RoomsCancelled;
				vArea.Parameters.mNoShowRooms = vHotelPickupDataRow.RoomsNoShow;

				vArea.Parameters.mRoomsReservedLY = vHotelPickupDataRow.PrevRoomsReserved;
				vArea.Parameters.mComplimentaryRoomsReservedLY = vHotelPickupDataRow.PrevComplimentaryRoomsReserved;
				vArea.Parameters.mHouseuseRoomsReservedLY = vHotelPickupDataRow.PrevHouseuseRoomsReserved;
				vArea.Parameters.mDayuseRoomsReservedLY = vHotelPickupDataRow.PrevDayuseRoomsReserved;
				vArea.Parameters.mRoomsCancelledLY = vHotelPickupDataRow.PrevRoomsCancelled;
				vArea.Parameters.mNoShowRoomsLY = vHotelPickupDataRow.PrevRoomsNoShow;
			Else
				vArea.Parameters.mBedsReserved = vHotelPickupDataRow.BedsReserved;
				vArea.Parameters.mComplimentaryBedsReserved = vHotelPickupDataRow.ComplimentaryBedsReserved;
				vArea.Parameters.mHouseuseBedsReserved = vHotelPickupDataRow.HouseuseBedsReserved;
				vArea.Parameters.mDayuseBedsReserved = vHotelPickupDataRow.DayuseBedsReserved;
				vArea.Parameters.mBedsCancelled = vHotelPickupDataRow.BedsCancelled;
				vArea.Parameters.mNoShowBeds = vHotelPickupDataRow.BedsNoShow;

				vArea.Parameters.mBedsReservedLY = vHotelPickupDataRow.PrevBedsReserved;
				vArea.Parameters.mComplimentaryBedsReservedLY = vHotelPickupDataRow.PrevComplimentaryBedsReserved;
				vArea.Parameters.mHouseuseBedsReservedLY = vHotelPickupDataRow.PrevHouseuseBedsReserved;
				vArea.Parameters.mDayuseBedsReservedLY = vHotelPickupDataRow.PrevDayuseBedsReserved;
				vArea.Parameters.mBedsCancelledLY = vHotelPickupDataRow.PrevBedsCancelled;
				vArea.Parameters.mNoShowBedsLY = vHotelPickupDataRow.PrevBedsNoShow;
			EndIf;
			vArea.Parameters.mRevenueReserved = vHotelPickupDataRow.RevenueReserved;
			vArea.Parameters.mRevenueCancelled = vHotelPickupDataRow.RevenueCancelled;
			vArea.Parameters.mNoShowRevenue = vHotelPickupDataRow.RevenueNoShow;

			vArea.Parameters.mRevenueReservedLY = vHotelPickupDataRow.PrevRevenueReserved;
			vArea.Parameters.mRevenueCancelledLY = vHotelPickupDataRow.PrevRevenueCancelled;
			vArea.Parameters.mNoShowRevenueLY = vHotelPickupDataRow.PrevRevenueNoShow;
		EndIf;
		
		pSpreadsheet.Join(vArea);
	EndDo;
	
	// 5. Income summary indexes
	
	// Put section header
	vArea = vTemplate.GetArea("IncomeSummaryHeader");
	pSpreadsheet.Put(vArea);
	vArea = vTemplate.GetArea("RoomsIncome|HeaderDescription");
	pSpreadsheet.Put(vArea);
	For Each vHotel In pHotelList Do
		vArea = vTemplate.GetArea("RoomsIncome|HeaderHotel");
		vRoomsIncome = 0;
		vRoomsIncomeLY = 0;
		vFilterRows = vRoomRented.FindRows(New Structure("Hotel", vHotel));
		For Each vRow In vFilterRows Do
			If vWithVAT Then
				vRoomsIncome = vRoomsIncome + vRow.RoomRevenue;
				vRoomsIncomeLY = vRoomsIncomeLY + vRow.PrevRoomRevenue;
			Else
				vRoomsIncome = vRoomsIncome + vRow.RoomRevenueWithoutVAT;
				vRoomsIncomeLY = vRoomsIncomeLY + vRow.PrevRoomRevenueWithoutVAT;
			EndIf;	
		EndDo;

		vArea.Parameters.mRoomsIncome = vRoomsIncome;
		vArea.Parameters.mRoomsIncomeLY = vRoomsIncomeLY;
		pSpreadsheet.Join(vArea);
	EndDo;
	vArea = vTemplate.GetArea("OtherIncome|HeaderDescription");
	pSpreadsheet.Put(vArea);
	For Each vHotel In pHotelList Do
		vArea = vTemplate.GetArea("OtherIncome|HeaderHotel");
		vOtherIncome = 0;
		vOtherIncomeLY = 0;
		vFilterRows = vRoomRented.FindRows(New Structure("Hotel", vHotel));
		For Each vRow In vFilterRows Do
			If vWithVAT Then
				vOtherIncome = vOtherIncome + vRow.Sales - vRow.RoomRevenue;
				vOtherIncomeLY = vOtherIncomeLY + vRow.PrevSales - vRow.PrevRoomRevenue;
			Else
				vOtherIncome = vOtherIncome + vRow.SalesWithoutVAT - vRow.RoomRevenueWithoutVAT;
				vOtherIncomeLY = vOtherIncomeLY + vRow.PrevSalesWithoutVAT - vRow.PrevRoomRevenueWithoutVAT;
			EndIf;	
		EndDo;
		vArea.Parameters.mOtherIncome = vOtherIncome;
		vArea.Parameters.mOtherIncomeLY = vOtherIncomeLY;
		pSpreadsheet.Join(vArea);
	EndDo;
	vArea = vTemplate.GetArea("TotalIncome|HeaderDescription");
	pSpreadsheet.Put(vArea);
	For Each vHotel In pHotelList Do
		vArea = vTemplate.GetArea("TotalIncome|HeaderHotel");
		vTotalIncome = 0;
		vTotalIncomeLY = 0;
		vFilterRows = vRoomRented.FindRows(New Structure("Hotel", vHotel));
		For Each vRow In vFilterRows Do
			If vWithVAT Then
				vTotalIncome = vTotalIncome + vRow.Sales;
				vTotalIncomeLY = vTotalIncomeLY + vRow.PrevSales;
			Else
				vTotalIncome = vTotalIncome + vRow.SalesWithoutVAT;
				vTotalIncomeLY = vTotalIncomeLY + vRow.PrevSalesWithoutVAT;
			EndIf;	
		EndDo;
		vArea.Parameters.mTotalIncome = vTotalIncome;
		vArea.Parameters.mTotalIncomeLY = vTotalIncomeLY;
		pSpreadsheet.Join(vArea);
	EndDo;

	// Sales by service type
	// Put sales by service types
	vSalesServiceTypeList = GetSalesServiceTypes(pHotelList);
	If vSalesServiceTypeList.Count()> 0 Then
		vArea = vTemplate.GetArea("ServiceTypeHeader");
		pSpreadsheet.Put(vArea);
		// Group by service type
		vServiceTypeList = vSalesServiceTypeList.Copy(, "ServiceType");
		vServiceTypeList.GroupBy("ServiceType");
		For Each vServiceTypeRow  In vServiceTypeList Do
			vArea = vTemplate.GetArea("ServiceTypeIncome|HeaderDescription");
			vArea.Parameters.mServiceType = ?(ValueIsFilled(vServiceTypeRow.ServiceType), vServiceTypeRow.ServiceType, NStr("en = '<Not specified>'; de = '<Nicht angegeben>'; ru = '<Не указан>'"));
			pSpreadsheet.Put(vArea);
			For Each vHotel In pHotelList Do
				vArea = vTemplate.GetArea("ServiceTypeIncome|HeaderHotel");
				vTotalIncome = 0;
				vTotalIncomeLY = 0;
				vFilterRows = vSalesServiceTypeList.FindRows(New Structure("Hotel, ServiceType", vHotel, vServiceTypeRow.ServiceType));
				For Each vRow In vFilterRows Do
					If vWithVAT Then
						vTotalIncome = vTotalIncome + vRow.SumTurnover;
						vTotalIncomeLY = vTotalIncomeLY + vRow.SumTurnoverLY;
					Else
						vTotalIncome = vTotalIncome + vRow.SumWithoutVATTurnover;
						vTotalIncomeLY = vTotalIncomeLY + vRow.SumWithoutVATTurnoverLY;
					EndIf;	
				EndDo;
				vArea.Parameters.mServiceTypeIncome = vTotalIncome;
				vArea.Parameters.mServiceTypeIncomeLY = vTotalIncomeLY;
				pSpreadsheet.Join(vArea);
			EndDo;
		EndDo;
		vArea = vTemplate.GetArea("SourceOfBusinessHeader");
		pSpreadsheet.Put(vArea);
		// Group by SourceOfBusiness
		vSourceOfBusinessList = vSalesServiceTypeList.Copy(,"SourceOfBusiness");
		vSourceOfBusinessList.GroupBy("SourceOfBusiness");
		For Each vSourceOfBusinessListRow  In vSourceOfBusinessList Do
			vArea = vTemplate.GetArea("SourceOfBusinessIncome|HeaderDescription");
			vArea.Parameters.mSourceOfBusiness = ?(ValueIsFilled(vSourceOfBusinessListRow.SourceOfBusiness), vSourceOfBusinessListRow.SourceOfBusiness, NStr("en = '<Not specified>'; de = '<Nicht angegeben>'; ru = '<Не указан>'"));
			pSpreadsheet.Put(vArea);
			For Each vHotel In pHotelList Do
				vArea = vTemplate.GetArea("SourceOfBusinessIncome|HeaderHotel");
				vTotalIncome = 0;
				vTotalIncomeLY = 0;
				vFilterRows = vSalesServiceTypeList.FindRows(New Structure("Hotel, SourceOfBusiness", vHotel, vSourceOfBusinessListRow.SourceOfBusiness));
				For Each vRow In vFilterRows Do
					If vWithVAT Then
						vTotalIncome = vTotalIncome + vRow.SumTurnover;
						vTotalIncomeLY = vTotalIncomeLY + vRow.SumTurnoverLY;
					Else
						vTotalIncome = vTotalIncome + vRow.SumWithoutVATTurnover;
						vTotalIncomeLY = vTotalIncomeLY + vRow.SumWithoutVATTurnoverLY;
					EndIf;	
				EndDo;
				vArea.Parameters.mSourceOfBusinessIncome = vTotalIncome;
				vArea.Parameters.mSourceOfBusinessIncomeLY = vTotalIncomeLY;
				pSpreadsheet.Join(vArea);
			EndDo;
		EndDo;
		vArea = vTemplate.GetArea("MarketingCodeHeader");
		pSpreadsheet.Put(vArea);
		// Group by MarketingCode
		vMarketingCodeList = vSalesServiceTypeList.Copy(, "MarketingCode");
		vMarketingCodeList.GroupBy("MarketingCode");
		For Each vMarketingCodeRow  In vMarketingCodeList Do
			vArea = vTemplate.GetArea("MarketingCodeIncome|HeaderDescription");
			vArea.Parameters.mMarketingCode = ?(ValueIsFilled(vMarketingCodeRow.MarketingCode), vMarketingCodeRow.MarketingCode, NStr("en='<Not specified>';ru='<Не указан>';de='<Nicht angegeben>'"));
			pSpreadsheet.Put(vArea);
			For Each vHotel In pHotelList Do
				vArea = vTemplate.GetArea("MarketingCodeIncome|HeaderHotel");
				vTotalIncome = 0;
				vTotalIncomeLY = 0;
				vFilterRows = vSalesServiceTypeList.FindRows(New Structure("Hotel, MarketingCode", vHotel, vMarketingCodeRow.MarketingCode));
				For Each vRow In vFilterRows Do
					If vWithVAT Then
						vTotalIncome = vTotalIncome + vRow.SumTurnover;
						vTotalIncomeLY = vTotalIncomeLY + vRow.SumTurnoverLY;
					Else
						vTotalIncome = vTotalIncome + vRow.SumWithoutVATTurnover;
						vTotalIncomeLY = vTotalIncomeLY + vRow.SumWithoutVATTurnoverLY;
					EndIf;	
				EndDo;
				vArea.Parameters.mMarketingCodeIncome = vTotalIncome;
				vArea.Parameters.mMarketingCodeIncomeLY = vTotalIncomeLY;
				pSpreadsheet.Join(vArea);
			EndDo;
		EndDo;

	EndIf; 
	
	// 6. Payments summary indexes
	
	// Put section header
	vArea = vTemplate.GetArea("PaymentsHeader");
	pSpreadsheet.Put(vArea);
	// Run query to get payments by payment method
	vPaymentList = GetPaymentList(pHotelList);
	vPaymentMethodList = vPaymentList.Copy(, "PaymentMethod");
	vPaymentMethodList.GroupBy("PaymentMethod");
	For Each vPaymentMethodListRow  In vPaymentMethodList Do
		vArea = vTemplate.GetArea("PaymentMethod|HeaderDescription");
		vArea.Parameters.mPaymentMethod = ?(ValueIsFilled(vPaymentMethodListRow.PaymentMethod), vPaymentMethodListRow.PaymentMethod, NStr("en = '<Not specified>'; de = '<Nicht angegeben>'; ru = '<Не указан>'"));
		pSpreadsheet.Put(vArea);
		For Each vHotel In pHotelList Do
			vArea = vTemplate.GetArea("PaymentMethod|HeaderHotel");
			vTotalIncome = 0;
			vTotalIncomeLY = 0;
			vFilterRows = vPaymentList.FindRows(New Structure("Hotel, PaymentMethod", vHotel, vPaymentMethodListRow.PaymentMethod));
			For Each vRow In vFilterRows Do
				vTotalIncome = vTotalIncome + vRow.SumTurnover;
				vTotalIncomeLY = vTotalIncomeLY + vRow.SumTurnoverLY;
			EndDo;
			vArea.Parameters.mSumTurnover = vTotalIncome;
			vArea.Parameters.mSumTurnoverLY = vTotalIncomeLY;
			pSpreadsheet.Join(vArea);
		EndDo;
	EndDo;
	vArea = vTemplate.GetArea("PaymentsFooter|HeaderDescription");
	pSpreadsheet.Put(vArea);
	For Each vHotel In pHotelList Do
		vArea = vTemplate.GetArea("PaymentsFooter|HeaderHotel");
		vTotalIncome = 0;
		vTotalIncomeLY = 0;
		vFilterRows = vPaymentList.FindRows(New Structure("Hotel", vHotel));
		For Each vRow In vFilterRows Do
			vTotalIncome = vTotalIncome + vRow.SumTurnover;
			vTotalIncomeLY = vTotalIncomeLY + vRow.SumTurnoverLY;
		EndDo;
		vArea.Parameters.mSumTurnover = vTotalIncome;
		vArea.Parameters.mSumTurnoverLY = vTotalIncomeLY;
		pSpreadsheet.Join(vArea);
	EndDo;
EndProcedure // FillReportByHotels

// -----------------------------------------------------------------------------
Function GetPaymentList(Val pHotelList)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PaymentList.Hotel AS Hotel,
	|	PaymentList.PaymentMethod AS PaymentMethod,
	|	PaymentList.PaymentMethodSortCode AS PaymentMethodSortCode,
	|	PaymentList.PaymentMethodDescription AS PaymentMethodDescription,
	|	SUM(PaymentList.SumTurnover) AS SumTurnover,
	|	SUM(PaymentList.VATSumTurnover) AS VATSumTurnover,
	|	SUM(PaymentList.SumTurnoverLY) AS SumTurnoverLY,
	|	SUM(PaymentList.VATSumTurnoverLY) AS VATSumTurnoverLY
	|FROM
	|	(SELECT
	|		PaymentsTurnovers.Hotel AS Hotel,
	|		PaymentsTurnovers.PaymentMethod AS PaymentMethod,
	|		PaymentsTurnovers.PaymentMethod.SortCode AS PaymentMethodSortCode,
	|		PaymentsTurnovers.PaymentMethod.Description AS PaymentMethodDescription,
	|		SUM(PaymentsTurnovers.SumTurnover) AS SumTurnover,
	|		SUM(PaymentsTurnovers.VATSumTurnover) AS VATSumTurnover,
	|		0 AS SumTurnoverLY,
	|		0 AS VATSumTurnoverLY
	|	FROM
	|		AccumulationRegister.Payments.Turnovers(&qPeriodFrom, &qPeriodTo, Day, Hotel IN (&qHotelList)) AS PaymentsTurnovers
	|	
	|	GROUP BY
	|		PaymentsTurnovers.PaymentMethod,
	|		PaymentsTurnovers.PaymentMethod.SortCode,
	|		PaymentsTurnovers.PaymentMethod.Description,
	|		PaymentsTurnovers.Hotel
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		PaymentsTurnovers.Hotel,
	|		PaymentsTurnovers.PaymentMethod,
	|		PaymentsTurnovers.PaymentMethod.SortCode,
	|		PaymentsTurnovers.PaymentMethod.Description,
	|		0,
	|		0,
	|		SUM(PaymentsTurnovers.SumTurnover),
	|		SUM(PaymentsTurnovers.VATSumTurnover)
	|	FROM
	|		AccumulationRegister.Payments.Turnovers(DATEADD(&qPeriodFrom, YEAR, -1), DATEADD(&qPeriodTo, YEAR, -1), Day, Hotel IN (&qHotelList)) AS PaymentsTurnovers
	|	
	|	GROUP BY
	|		PaymentsTurnovers.PaymentMethod,
	|		PaymentsTurnovers.PaymentMethod.SortCode,
	|		PaymentsTurnovers.PaymentMethod.Description,
	|		PaymentsTurnovers.Hotel) AS PaymentList
	|
	|GROUP BY
	|	PaymentList.Hotel,
	|	PaymentList.PaymentMethod,
	|	PaymentList.PaymentMethodSortCode,
	|	PaymentList.PaymentMethodDescription
	|
	|ORDER BY
	|	PaymentMethodSortCode,
	|	PaymentMethodDescription";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodTo));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotelList", pHotelList);
	vQryResult = vQry.Execute().Unload();
	Return vQryResult;
EndFunction

// -----------------------------------------------------------------------------
Function GetSalesServiceTypes(Val pHotelList)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ServiceSales.Hotel AS Hotel,
	|	ServiceSales.ServiceType AS ServiceType,
	|	ServiceSales.ServiceType.SortCode AS ServiceTypeSortCode,
	|	ServiceSales.ServiceType.Description AS ServiceTypeDescription,
	|	SUM(ServiceSales.SumTurnover) AS SumTurnover,
	|	SUM(ServiceSales.SumWithoutVATTurnover) AS SumWithoutVATTurnover,
	|	SUM(ServiceSales.SumTurnoverLY) AS SumTurnoverLY,
	|	SUM(ServiceSales.SumWithoutVATTurnoverLY) AS SumWithoutVATTurnoverLY,
	|	ServiceSales.SourceOfBusiness AS SourceOfBusiness,
	|	ServiceSales.MarketingCode AS MarketingCode,
	|	ServiceSales.SourceOfBusinessSortCode AS SourceOfBusinessSortCode,
	|	ServiceSales.SourceOfBusinessDescription AS SourceOfBusinessDescription,
	|	ServiceSales.MarketingCodeSortCode AS MarketingCodeSortCode,
	|	ServiceSales.MarketingCodeDescription AS MarketingCodeDescription
	|FROM
	|	(SELECT
	|		ServiceSalesTurnovers.Hotel AS Hotel,
	|		ISNULL(ServiceSalesTurnovers.Service.ServiceType, &qEmptyServiceType) AS ServiceType,
	|		ServiceSalesTurnovers.SalesTurnover AS SumTurnover,
	|		ServiceSalesTurnovers.SalesWithoutVATTurnover AS SumWithoutVATTurnover,
	|		0 AS SumTurnoverLY,
	|		0 AS SumWithoutVATTurnoverLY,
	|		ServiceSalesTurnovers.SourceOfBusiness AS SourceOfBusiness,
	|		ServiceSalesTurnovers.SourceOfBusiness.SortCode AS SourceOfBusinessSortCode,
	|		ServiceSalesTurnovers.SourceOfBusiness.Description AS SourceOfBusinessDescription,
	|		ServiceSalesTurnovers.MarketingCode AS MarketingCode,
	|		ServiceSalesTurnovers.MarketingCode.SortCode AS MarketingCodeSortCode,
	|		ServiceSalesTurnovers.MarketingCode.Description AS MarketingCodeDescription
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Day,
	|				NOT IsCorrection
	|					AND Hotel IN (&qHotelList)) AS ServiceSalesTurnovers
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ServiceSalesForecastTurnovers.Hotel,
	|		ISNULL(ServiceSalesForecastTurnovers.Service.ServiceType, &qEmptyServiceType),
	|		ServiceSalesForecastTurnovers.SalesTurnover,
	|		ServiceSalesForecastTurnovers.SalesWithoutVATTurnover,
	|		0,
	|		0,
	|		ServiceSalesForecastTurnovers.SourceOfBusiness,
	|		ServiceSalesForecastTurnovers.SourceOfBusiness.SortCode,
	|		ServiceSalesForecastTurnovers.SourceOfBusiness.Description,
	|		ServiceSalesForecastTurnovers.MarketingCode,
	|		ServiceSalesForecastTurnovers.MarketingCode.SortCode,
	|		ServiceSalesForecastTurnovers.MarketingCode.Description
	|	FROM
	|		AccumulationRegister.SalesForecast.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Day,
	|				NOT &qDoNotShowForecast
	|					AND Hotel IN (&qHotelList)) AS ServiceSalesForecastTurnovers
	|	WHERE
	|		CASE
	|				WHEN ServiceSalesForecastTurnovers.Hotel.AccountingDate > DATETIME(1, 1, 1)
	|						AND ServiceSalesForecastTurnovers.Hotel.AccountingDate <= &qPeriodFrom
	|					THEN TRUE
	|				ELSE FALSE
	|			END
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ServiceSalesTurnovers.Hotel,
	|		ISNULL(ServiceSalesTurnovers.Service.ServiceType, &qEmptyServiceType),
	|		0,
	|		0,
	|		ServiceSalesTurnovers.SalesTurnover,
	|		ServiceSalesTurnovers.SalesWithoutVATTurnover,
	|		ServiceSalesTurnovers.SourceOfBusiness,
	|		ServiceSalesTurnovers.SourceOfBusiness.SortCode,
	|		ServiceSalesTurnovers.SourceOfBusiness.Description,
	|		ServiceSalesTurnovers.MarketingCode,
	|		ServiceSalesTurnovers.MarketingCode.SortCode,
	|		ServiceSalesTurnovers.MarketingCode.Description
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(DATEADD(&qPeriodFrom, YEAR, -1), DATEADD(&qPeriodTo, YEAR, -1), Day, Hotel IN (&qHotelList)) AS ServiceSalesTurnovers) AS ServiceSales
	|
	|GROUP BY
	|	ServiceSales.ServiceType,
	|	ServiceSales.ServiceType.SortCode,
	|	ServiceSales.ServiceType.Description,
	|	ServiceSales.Hotel,
	|	ServiceSales.SourceOfBusiness,
	|	ServiceSales.MarketingCode,
	|	ServiceSales.SourceOfBusinessDescription,
	|	ServiceSales.MarketingCodeDescription,
	|	ServiceSales.SourceOfBusinessSortCode,
	|	ServiceSales.MarketingCodeSortCode
	|
	|ORDER BY
	|	ServiceTypeSortCode,
	|	ServiceTypeDescription,
	|	ServiceSales.SourceOfBusinessSortCode,
	|	ServiceSales.SourceOfBusinessDescription,
	|	ServiceSales.MarketingCodeSortCode,
	|	ServiceSales.MarketingCodeDescription";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodTo));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotelList", pHotelList);
	vQry.SetParameter("qEmptyServiceType", Catalogs.ServiceTypes.EmptyRef());
	vQry.SetParameter("qDoNotShowForecast", DoNotShowForecast);
	vQryResult = vQry.Execute().Unload();
	Return vQryResult;
EndFunction

// -----------------------------------------------------------------------------
Function GetCheckedInGuests(Val pHotelList)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	NestedSelect.Hotel AS Hotel,
	|	NestedSelect.ParentDocIsByReservation AS ParentDocIsByReservation,
	|	SUM(NestedSelect.RoomsCheckedInTurnover) AS RoomsCheckedInTurnover,
	|	SUM(NestedSelect.RoomsCheckedInTurnoverLY) AS RoomsCheckedInTurnoverLY,
	|	SUM(NestedSelect.BedsCheckedInTurnover) AS BedsCheckedInTurnover,
	|	SUM(NestedSelect.BedsCheckedInTurnoverLY) AS BedsCheckedInTurnoverLY,
	|	SUM(NestedSelect.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover,
	|	SUM(NestedSelect.GuestsCheckedInTurnoverLY) AS GuestsCheckedInTurnoverLY
	|FROM
	|	(SELECT
	|		RoomSalesTurnovers.Hotel AS Hotel,
	|		RoomSalesTurnovers.ParentDoc.IsByReservation AS ParentDocIsByReservation,
	|		SUM(RoomSalesTurnovers.RoomsCheckedInTurnover) AS RoomsCheckedInTurnover,
	|		0 AS RoomsCheckedInTurnoverLY,
	|		SUM(RoomSalesTurnovers.BedsCheckedInTurnover) AS BedsCheckedInTurnover,
	|		0 AS BedsCheckedInTurnoverLY,
	|		SUM(RoomSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover,
	|		0 AS GuestsCheckedInTurnoverLY
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Day,
	|				NOT IsCorrection
	|					AND Hotel IN (&qHotelList)) AS RoomSalesTurnovers
	|	
	|	GROUP BY
	|		RoomSalesTurnovers.ParentDoc.IsByReservation,
	|		RoomSalesTurnovers.Hotel
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RoomSalesTurnovers.Hotel,
	|		RoomSalesTurnovers.ParentDoc.IsByReservation,
	|		0,
	|		SUM(RoomSalesTurnovers.RoomsCheckedInTurnover),
	|		0,
	|		SUM(RoomSalesTurnovers.BedsCheckedInTurnover),
	|		0,
	|		SUM(RoomSalesTurnovers.GuestsCheckedInTurnover)
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				DATEADD(&qPeriodFrom, YEAR, -1),
	|				DATEADD(&qPeriodTo, YEAR, -1),
	|				Day,
	|				NOT IsCorrection
	|					AND Hotel IN (&qHotelList)) AS RoomSalesTurnovers
	|	
	|	GROUP BY
	|		RoomSalesTurnovers.ParentDoc.IsByReservation,
	|		RoomSalesTurnovers.Hotel
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RoomSalesTurnovers.Hotel,
	|		RoomSalesTurnovers.ParentDoc.IsByReservation,
	|		SUM(RoomSalesTurnovers.RoomsCheckedInTurnover),
	|		0,
	|		SUM(RoomSalesTurnovers.BedsCheckedInTurnover),
	|		0,
	|		SUM(RoomSalesTurnovers.GuestsCheckedInTurnover),
	|		0
	|	FROM
	|		AccumulationRegister.SalesForecast.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Day,
	|				NOT &qDoNotShowForecast
	|					AND Hotel IN (&qHotelList)) AS RoomSalesTurnovers
	|	WHERE
	|		CASE
	|				WHEN RoomSalesTurnovers.Hotel.AccountingDate > DATETIME(1, 1, 1)
	|						AND RoomSalesTurnovers.Hotel.AccountingDate <= &qPeriodFrom
	|					THEN TRUE
	|				ELSE FALSE
	|			END
	|	
	|	GROUP BY
	|		RoomSalesTurnovers.ParentDoc.IsByReservation,
	|		RoomSalesTurnovers.Hotel) AS NestedSelect
	|
	|GROUP BY
	|	NestedSelect.Hotel,
	|	NestedSelect.ParentDocIsByReservation";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodTo));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotelList", pHotelList);
	vQry.SetParameter("qDoNotShowForecast", DoNotShowForecast);
	vQryResult = vQry.Execute().Unload();
	Return vQryResult;
EndFunction

// -----------------------------------------------------------------------------
Function GetNumberOfGuestDays(Val pHotelList)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	NestedSelect.Hotel AS Hotel,
	|	NestedSelect.ClientType AS ClientType,
	|	ISNULL(NestedSelect.ClientTypeSortCode, """") AS ClientTypeSortCode,
	|	ISNULL(NestedSelect.ClientTypeDescription, """") AS ClientTypeDescription,
	|	SUM(NestedSelect.GuestDaysTurnover) AS GuestDaysTurnover,
	|	SUM(NestedSelect.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover,
	|	SUM(NestedSelect.GuestDaysTurnoverLY) AS GuestDaysTurnoverLY,
	|	SUM(NestedSelect.GuestsCheckedInTurnoverLY) AS GuestsCheckedInTurnoverLY
	|FROM
	|	(SELECT
	|		RoomSalesTurnovers.Hotel AS Hotel,
	|		RoomSalesTurnovers.ClientType AS ClientType,
	|		RoomSalesTurnovers.ClientType.SortCode AS ClientTypeSortCode,
	|		RoomSalesTurnovers.ClientType.Description AS ClientTypeDescription,
	|		SUM(RoomSalesTurnovers.GuestDaysTurnover) AS GuestDaysTurnover,
	|		SUM(RoomSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover,
	|		0 AS GuestDaysTurnoverLY,
	|		0 AS GuestsCheckedInTurnoverLY
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Day,
	|				NOT IsCorrection
	|					AND Hotel IN (&qHotelList)) AS RoomSalesTurnovers
	|	
	|	GROUP BY
	|		RoomSalesTurnovers.ClientType,
	|		RoomSalesTurnovers.ClientType.SortCode,
	|		RoomSalesTurnovers.ClientType.Description,
	|		RoomSalesTurnovers.Hotel
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RoomSalesTurnovers.Hotel,
	|		RoomSalesTurnovers.ClientType,
	|		RoomSalesTurnovers.ClientType.SortCode,
	|		RoomSalesTurnovers.ClientType.Description,
	|		0,
	|		0,
	|		SUM(RoomSalesTurnovers.GuestDaysTurnover),
	|		SUM(RoomSalesTurnovers.GuestsCheckedInTurnover)
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				DATEADD(&qPeriodFrom, YEAR, -1),
	|				DATEADD(&qPeriodTo, YEAR, -1),
	|				Day,
	|				NOT IsCorrection
	|					AND Hotel IN (&qHotelList)) AS RoomSalesTurnovers
	|	
	|	GROUP BY
	|		RoomSalesTurnovers.ClientType,
	|		RoomSalesTurnovers.ClientType.SortCode,
	|		RoomSalesTurnovers.ClientType.Description,
	|		RoomSalesTurnovers.Hotel
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RoomSalesTurnovers.Hotel,
	|		RoomSalesTurnovers.ClientType,
	|		RoomSalesTurnovers.ClientType.SortCode,
	|		RoomSalesTurnovers.ClientType.Description,
	|		SUM(RoomSalesTurnovers.GuestDaysTurnover),
	|		SUM(RoomSalesTurnovers.GuestsCheckedInTurnover),
	|		0,
	|		0
	|	FROM
	|		AccumulationRegister.SalesForecast.Turnovers(&qPeriodFrom, &qPeriodTo, Day, NOT &qDoNotShowForecast AND Hotel IN (&qHotelList)) AS RoomSalesTurnovers
	|	WHERE
	|		CASE
	|				WHEN RoomSalesTurnovers.Hotel.AccountingDate > DATETIME(1, 1, 1)
	|						AND RoomSalesTurnovers.Hotel.AccountingDate <= &qPeriodFrom
	|					THEN TRUE
	|				ELSE FALSE
	|			END
	|	
	|	GROUP BY
	|		RoomSalesTurnovers.ClientType,
	|		RoomSalesTurnovers.ClientType.SortCode,
	|		RoomSalesTurnovers.ClientType.Description,
	|		RoomSalesTurnovers.Hotel) AS NestedSelect
	|
	|GROUP BY
	|	NestedSelect.Hotel,
	|	NestedSelect.ClientType,
	|	NestedSelect.ClientTypeSortCode,
	|	NestedSelect.ClientTypeDescription
	|
	|ORDER BY
	|	ClientTypeSortCode,
	|	ClientTypeDescription";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodTo));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotelList", pHotelList);
	vQry.SetParameter("qDoNotShowForecast", DoNotShowForecast);
	vQryResult = vQry.Execute().Unload();
	Return vQryResult;
EndFunction

// -----------------------------------------------------------------------------
Function GetRoomRentedTotals(pHotelList)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	NestedSelect.Hotel AS Hotel,
	|	ISNULL(NestedSelect.RoomRateIsComplimentary, FALSE) AS RoomRateIsComplimentary,
	|	ISNULL(NestedSelect.RoomRateIsHouseUse, FALSE) AS RoomRateIsHouseUse,
	|	SUM(NestedSelect.SalesTurnover) AS Sales,
	|	SUM(NestedSelect.SalesWithoutVATTurnover) AS SalesWithoutVAT,
	|	SUM(NestedSelect.RoomRevenueTurnover) AS RoomRevenue,
	|	SUM(NestedSelect.RoomRevenueWithoutVATTurnover) AS RoomRevenueWithoutVAT,
	|	SUM(NestedSelect.RoomsRentedTurnover) AS RoomsRented,
	|	SUM(NestedSelect.BedsRentedTurnover) AS BedsRented,
	|	SUM(NestedSelect.PrevSales) AS PrevSales,
	|	SUM(NestedSelect.PrevSalesWithoutVAT) AS PrevSalesWithoutVAT,
	|	SUM(NestedSelect.PrevRoomRevenue) AS PrevRoomRevenue,
	|	SUM(NestedSelect.PrevRoomRevenueWithoutVAT) AS PrevRoomRevenueWithoutVAT,
	|	SUM(NestedSelect.PrevRoomsRented) AS PrevRoomsRented,
	|	SUM(NestedSelect.PrevBedsRented) AS PrevBedsRented
	|FROM
	|	(SELECT
	|		RoomSalesTurnovers.Hotel AS Hotel,
	|		RoomSalesTurnovers.RoomRate.IsComplimentary AS RoomRateIsComplimentary,
	|		RoomSalesTurnovers.RoomRate.IsHouseUse AS RoomRateIsHouseUse,
	|		SUM(RoomSalesTurnovers.SalesTurnover) AS SalesTurnover,
	|		SUM(RoomSalesTurnovers.SalesWithoutVATTurnover) AS SalesWithoutVATTurnover,
	|		SUM(RoomSalesTurnovers.RoomRevenueTurnover) AS RoomRevenueTurnover,
	|		SUM(RoomSalesTurnovers.RoomRevenueWithoutVATTurnover) AS RoomRevenueWithoutVATTurnover,
	|		SUM(RoomSalesTurnovers.RoomsRentedTurnover) AS RoomsRentedTurnover,
	|		SUM(RoomSalesTurnovers.BedsRentedTurnover) AS BedsRentedTurnover,
	|		0 AS PrevSales,
	|		0 AS PrevSalesWithoutVAT,
	|		0 AS PrevRoomRevenue,
	|		0 AS PrevRoomRevenueWithoutVAT,
	|		0 AS PrevRoomsRented,
	|		0 AS PrevBedsRented
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Day,
	|				NOT IsCorrection
	|					AND Hotel IN (&qHotelList)) AS RoomSalesTurnovers
	|	
	|	GROUP BY
	|		RoomSalesTurnovers.RoomRate.IsComplimentary,
	|		RoomSalesTurnovers.RoomRate.IsHouseUse,
	|		RoomSalesTurnovers.Hotel
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RoomSalesTurnovers.Hotel,
	|		RoomSalesTurnovers.RoomRate.IsComplimentary,
	|		RoomSalesTurnovers.RoomRate.IsHouseUse,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		SUM(RoomSalesTurnovers.SalesTurnover),
	|		SUM(RoomSalesTurnovers.SalesWithoutVATTurnover),
	|		SUM(RoomSalesTurnovers.RoomRevenueTurnover),
	|		SUM(RoomSalesTurnovers.RoomRevenueWithoutVATTurnover),
	|		SUM(RoomSalesTurnovers.RoomsRentedTurnover),
	|		SUM(RoomSalesTurnovers.BedsRentedTurnover)
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				DATEADD(&qPeriodFrom, YEAR, -1),
	|				DATEADD(&qPeriodTo, YEAR, -1),
	|				Day,
	|				NOT IsCorrection
	|					AND Hotel IN (&qHotelList)) AS RoomSalesTurnovers
	|	
	|	GROUP BY
	|		RoomSalesTurnovers.RoomRate.IsComplimentary,
	|		RoomSalesTurnovers.RoomRate.IsHouseUse,
	|		RoomSalesTurnovers.Hotel
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RoomSalesTurnovers.Hotel,
	|		RoomSalesTurnovers.RoomRate.IsComplimentary,
	|		RoomSalesTurnovers.RoomRate.IsHouseUse,
	|		SUM(RoomSalesTurnovers.SalesTurnover),
	|		SUM(RoomSalesTurnovers.SalesWithoutVATTurnover),
	|		SUM(RoomSalesTurnovers.RoomRevenueTurnover),
	|		SUM(RoomSalesTurnovers.RoomRevenueWithoutVATTurnover),
	|		SUM(RoomSalesTurnovers.RoomsRentedTurnover),
	|		SUM(RoomSalesTurnovers.BedsRentedTurnover),
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0
	|	FROM
	|		AccumulationRegister.SalesForecast.Turnovers(&qPeriodFrom, &qPeriodTo, Day, NOT &qDoNotShowForecast AND Hotel IN (&qHotelList)) AS RoomSalesTurnovers
	|	WHERE
	|		CASE
	|				WHEN RoomSalesTurnovers.Hotel.AccountingDate > DATETIME(1, 1, 1)
	|						AND RoomSalesTurnovers.Hotel.AccountingDate <= &qPeriodFrom
	|					THEN TRUE
	|				ELSE FALSE
	|			END
	|	
	|	GROUP BY
	|		RoomSalesTurnovers.RoomRate.IsComplimentary,
	|		RoomSalesTurnovers.RoomRate.IsHouseUse,
	|		RoomSalesTurnovers.Hotel) AS NestedSelect
	|
	|GROUP BY
	|	NestedSelect.Hotel,
	|	ISNULL(NestedSelect.RoomRateIsComplimentary, FALSE),
	|	ISNULL(NestedSelect.RoomRateIsHouseUse, FALSE)";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodTo));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotelList", pHotelList);
	vQry.SetParameter("qDoNotShowForecast", DoNotShowForecast);
	vQryResult = vQry.Execute().Unload();
	Return vQryResult;
EndFunction

// -----------------------------------------------------------------------------
Function GetRoomBlocksByHotelList(pHotelList)
	// Run query to get total number of rooms, rooms blocked, vacant number of rooms
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	NestedSelect.Hotel AS Hotel,
	|	NestedSelect.RoomBlockType AS RoomBlockType,
	|	SUM(NestedSelect.CurDateRoomsBlocked) AS CurDateRoomsBlocked,
	|	SUM(NestedSelect.CurDateBedsBlocked) AS CurDateBedsBlocked,
	|	SUM(NestedSelect.PrevDateRoomsBlocked) AS PrevDateRoomsBlocked,
	|	SUM(NestedSelect.PrevDateBedsBlocked) AS PrevDateBedsBlocked,
	|	SUM(NestedSelect.CurSpecRoomsBlocked) AS CurSpecRoomsBlocked,
	|	SUM(NestedSelect.CurSpecBedsBlocked) AS CurSpecBedsBlocked,
	|	SUM(NestedSelect.PrevSpecRoomsBlocked) AS PrevSpecRoomsBlocked,
	|	SUM(NestedSelect.PrevSpecBedsBlocked) AS PrevSpecBedsBlocked
	|FROM
	|	(SELECT
	|		RoomBlocksBalanceAndTurnovers.Hotel AS Hotel,
	|		RoomBlocksBalanceAndTurnovers.RoomBlockType AS RoomBlockType,
	|		SUM(RoomBlocksBalanceAndTurnovers.RoomsBlockedClosingBalance) AS CurDateRoomsBlocked,
	|		SUM(RoomBlocksBalanceAndTurnovers.BedsBlockedClosingBalance) AS CurDateBedsBlocked,
	|		0 AS PrevDateRoomsBlocked,
	|		0 AS PrevDateBedsBlocked,
	|		CASE
	|			WHEN RoomBlocksBalanceAndTurnovers.RoomBlockType.AddToRoomsRentedInSummaryIndexes
	|				THEN RoomBlocksBalanceAndTurnovers.RoomsBlockedClosingBalance
	|			ELSE 0
	|		END AS CurSpecRoomsBlocked,
	|		CASE
	|			WHEN RoomBlocksBalanceAndTurnovers.RoomBlockType.AddToRoomsRentedInSummaryIndexes
	|				THEN RoomBlocksBalanceAndTurnovers.BedsBlockedClosingBalance
	|			ELSE 0
	|		END AS CurSpecBedsBlocked,
	|		0 AS PrevSpecRoomsBlocked,
	|		0 AS PrevSpecBedsBlocked
	|	FROM
	|		AccumulationRegister.RoomBlocks.BalanceAndTurnovers(&qPeriodFrom, &qPeriodTo, Day, RegisterRecordsAndPeriodBoundaries, Hotel IN (&qHotelList)) AS RoomBlocksBalanceAndTurnovers
	|	
	|	GROUP BY
	|		RoomBlocksBalanceAndTurnovers.RoomBlockType,
	|		RoomBlocksBalanceAndTurnovers.Hotel,
	|		CASE
	|			WHEN RoomBlocksBalanceAndTurnovers.RoomBlockType.AddToRoomsRentedInSummaryIndexes
	|				THEN RoomBlocksBalanceAndTurnovers.RoomsBlockedClosingBalance
	|			ELSE 0
	|		END,
	|		CASE
	|			WHEN RoomBlocksBalanceAndTurnovers.RoomBlockType.AddToRoomsRentedInSummaryIndexes
	|				THEN RoomBlocksBalanceAndTurnovers.BedsBlockedClosingBalance
	|			ELSE 0
	|		END
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RoomBlocksBalanceAndTurnovers.Hotel,
	|		RoomBlocksBalanceAndTurnovers.RoomBlockType,
	|		0,
	|		0,
	|		SUM(RoomBlocksBalanceAndTurnovers.RoomsBlockedClosingBalance),
	|		SUM(RoomBlocksBalanceAndTurnovers.BedsBlockedClosingBalance),
	|		0,
	|		0,
	|		CASE
	|			WHEN RoomBlocksBalanceAndTurnovers.RoomBlockType.AddToRoomsRentedInSummaryIndexes
	|				THEN RoomBlocksBalanceAndTurnovers.RoomsBlockedClosingBalance
	|			ELSE 0
	|		END,
	|		CASE
	|			WHEN RoomBlocksBalanceAndTurnovers.RoomBlockType.AddToRoomsRentedInSummaryIndexes
	|				THEN RoomBlocksBalanceAndTurnovers.BedsBlockedClosingBalance
	|			ELSE 0
	|		END
	|	FROM
	|		AccumulationRegister.RoomBlocks.BalanceAndTurnovers(DATEADD(&qPeriodFrom, YEAR, -1), DATEADD(&qPeriodTo, YEAR, -1), Day, RegisterRecordsAndPeriodBoundaries, Hotel IN (&qHotelList)) AS RoomBlocksBalanceAndTurnovers
	|	
	|	GROUP BY
	|		RoomBlocksBalanceAndTurnovers.RoomBlockType,
	|		RoomBlocksBalanceAndTurnovers.Hotel,
	|		CASE
	|			WHEN RoomBlocksBalanceAndTurnovers.RoomBlockType.AddToRoomsRentedInSummaryIndexes
	|				THEN RoomBlocksBalanceAndTurnovers.RoomsBlockedClosingBalance
	|			ELSE 0
	|		END,
	|		CASE
	|			WHEN RoomBlocksBalanceAndTurnovers.RoomBlockType.AddToRoomsRentedInSummaryIndexes
	|				THEN RoomBlocksBalanceAndTurnovers.BedsBlockedClosingBalance
	|			ELSE 0
	|		END) AS NestedSelect
	|
	|GROUP BY
	|	NestedSelect.Hotel,
	|	NestedSelect.RoomBlockType";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodTo));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotelList", pHotelList);
	vQryResult = vQry.Execute().Unload();
	Return vQryResult
EndFunction

// -----------------------------------------------------------------------------
Function GetTotalSalesByHotels(pHotelList)
	// Run query to get total number of rooms, rooms blocked, vacant number of rooms
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	NestedSelect.Hotel AS Hotel,
	|	SUM(NestedSelect.TotalRooms) AS TotalRooms,
	|	SUM(NestedSelect.TotalBeds) AS TotalBeds,
	|	SUM(NestedSelect.RoomsForSale) AS RoomsForSale,
	|	SUM(NestedSelect.BedsForSale) AS BedsForSale,
	|	SUM(NestedSelect.RoomsBlocked) AS RoomsBlocked,
	|	SUM(NestedSelect.BedsBlocked) AS BedsBlocked,
	|	SUM(NestedSelect.RoomsOccupied) AS RoomsOccupied,
	|	SUM(NestedSelect.BedsOccupied) AS BedsOccupied,
	|	SUM(NestedSelect.PrevTotalRooms) AS PrevTotalRooms,
	|	SUM(NestedSelect.PrevTotalBeds) AS PrevTotalBeds,
	|	SUM(NestedSelect.PrevRoomsForSale) AS PrevRoomsForSale,
	|	SUM(NestedSelect.PrevBedsForSale) AS PrevBedsForSale,
	|	SUM(NestedSelect.PrevRoomsBlocked) AS PrevRoomsBlocked,
	|	SUM(NestedSelect.PrevBedsBlocked) AS PrevBedsBlocked,
	|	SUM(NestedSelect.PrevRoomsOccupied) AS PrevRoomsOccupied,
	|	SUM(NestedSelect.PrevBedsOccupied) AS PrevBedsOccupied,
	|	0 AS CurSpecRoomsBlocked,
	|	0 AS CurSpecBedsBlocked,
	|	0 AS PrevSpecRoomsBlocked,
	|	0 AS PrevSpecBedsBlocked
	|FROM
	|	(SELECT
	|		RoomInventoryBalanceAndTurnovers.Hotel AS Hotel,
	|		SUM(RoomInventoryBalanceAndTurnovers.TotalRoomsClosingBalance) AS TotalRooms,
	|		SUM(RoomInventoryBalanceAndTurnovers.TotalBedsClosingBalance) AS TotalBeds,
	|		SUM(RoomInventoryBalanceAndTurnovers.TotalRoomsClosingBalance) - SUM(-RoomInventoryBalanceAndTurnovers.RoomsBlockedClosingBalance) AS RoomsForSale,
	|		SUM(RoomInventoryBalanceAndTurnovers.TotalBedsClosingBalance) - SUM(-RoomInventoryBalanceAndTurnovers.BedsBlockedClosingBalance) AS BedsForSale,
	|		SUM(-RoomInventoryBalanceAndTurnovers.RoomsBlockedClosingBalance) AS RoomsBlocked,
	|		SUM(-RoomInventoryBalanceAndTurnovers.BedsBlockedClosingBalance) AS BedsBlocked,
	|		SUM(-RoomInventoryBalanceAndTurnovers.InHouseRoomsClosingBalance - RoomInventoryBalanceAndTurnovers.RoomsReservedClosingBalance) AS RoomsOccupied,
	|		SUM(-RoomInventoryBalanceAndTurnovers.InHouseBedsClosingBalance - RoomInventoryBalanceAndTurnovers.BedsReservedClosingBalance) AS BedsOccupied,
	|		0 AS PrevTotalRooms,
	|		0 AS PrevTotalBeds,
	|		0 AS PrevRoomsForSale,
	|		0 AS PrevBedsForSale,
	|		0 AS PrevRoomsBlocked,
	|		0 AS PrevBedsBlocked,
	|		0 AS PrevRoomsOccupied,
	|		0 AS PrevBedsOccupied
	|	FROM
	|		AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qPeriodFrom, ENDOFPERIOD(&qPeriodTo, DAY), Day, RegisterRecordsAndPeriodBoundaries, Hotel IN (&qHotelList)) AS RoomInventoryBalanceAndTurnovers
	|	
	|	GROUP BY
	|		RoomInventoryBalanceAndTurnovers.Period,
	|		RoomInventoryBalanceAndTurnovers.InHouseRoomsClosingBalance,
	|		RoomInventoryBalanceAndTurnovers.RoomsReservedClosingBalance,
	|		RoomInventoryBalanceAndTurnovers.Hotel
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RoomInventoryBalanceAndTurnovers.Hotel,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		SUM(RoomInventoryBalanceAndTurnovers.TotalRoomsClosingBalance),
	|		SUM(RoomInventoryBalanceAndTurnovers.TotalBedsClosingBalance),
	|		SUM(RoomInventoryBalanceAndTurnovers.TotalRoomsClosingBalance) - SUM(-RoomInventoryBalanceAndTurnovers.RoomsBlockedClosingBalance),
	|		SUM(RoomInventoryBalanceAndTurnovers.TotalBedsClosingBalance) - SUM(-RoomInventoryBalanceAndTurnovers.BedsBlockedClosingBalance),
	|		SUM(-RoomInventoryBalanceAndTurnovers.RoomsBlockedClosingBalance),
	|		SUM(-RoomInventoryBalanceAndTurnovers.BedsBlockedClosingBalance),
	|		SUM(-RoomInventoryBalanceAndTurnovers.InHouseRoomsClosingBalance - RoomInventoryBalanceAndTurnovers.RoomsReservedClosingBalance),
	|		SUM(-RoomInventoryBalanceAndTurnovers.InHouseBedsClosingBalance - RoomInventoryBalanceAndTurnovers.BedsReservedClosingBalance)
	|	FROM
	|		AccumulationRegister.RoomInventory.BalanceAndTurnovers(DATEADD(&qPeriodFrom, YEAR, -1), ENDOFPERIOD(DATEADD(&qPeriodTo, YEAR, -1), DAY), Day, RegisterRecordsAndPeriodBoundaries, Hotel IN (&qHotelList)) AS RoomInventoryBalanceAndTurnovers
	|	
	|	GROUP BY
	|		RoomInventoryBalanceAndTurnovers.Period,
	|		RoomInventoryBalanceAndTurnovers.InHouseRoomsClosingBalance,
	|		RoomInventoryBalanceAndTurnovers.RoomsReservedClosingBalance,
	|		RoomInventoryBalanceAndTurnovers.Hotel) AS NestedSelect
	|
	|GROUP BY
	|	NestedSelect.Hotel";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodTo));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotelList", pHotelList);
	vQryResult = vQry.Execute().Unload();
	Return vQryResult;
EndFunction

// -----------------------------------------------------------------------------
Function GetTotalSalesByHotelsRoomTypes(pHotelList)
	// Run query to get total number of rooms, rooms blocked, vacant number of rooms
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	NestedSelect.Hotel AS Hotel,
	|	NestedSelect.RoomType.GroupingForReports AS RoomTypeGroupingForReports,
	|	SUM(NestedSelect.RoomsForSale) AS RoomsForSale,
	|	SUM(NestedSelect.BedsForSale) AS BedsForSale,
	|	SUM(NestedSelect.RoomsOccupied) AS RoomsRented,
	|	SUM(NestedSelect.BedsOccupied) AS BedsRented,
	|	SUM(NestedSelect.RoomsForSale) - SUM(NestedSelect.RoomsOccupied) AS RoomBalance,
	|	SUM(NestedSelect.BedsForSale) - SUM(NestedSelect.BedsOccupied) AS BedsBalance,
	|	SUM(NestedSelect.PrevRoomsForSale) AS PrevRoomsForSale,
	|	SUM(NestedSelect.PrevBedsForSale) AS PrevBedsForSale,
	|	SUM(NestedSelect.PrevRoomsForSale) - SUM(NestedSelect.PrevRoomsOccupied) AS PrevRoomBalance,
	|	SUM(NestedSelect.PrevBedsForSale) - SUM(NestedSelect.PrevBedsOccupied) AS PrevBedsBalance,
	|	SUM(NestedSelect.PrevRoomsOccupied) AS PrevRoomsRented,
	|	SUM(NestedSelect.PrevBedsOccupied) AS PrevBedsRented
	|FROM
	|	(SELECT
	|		RoomInventoryBalanceAndTurnovers.Hotel AS Hotel,
	|		SUM(RoomInventoryBalanceAndTurnovers.TotalRoomsClosingBalance) AS TotalRooms,
	|		SUM(RoomInventoryBalanceAndTurnovers.TotalRoomsClosingBalance) - SUM(-RoomInventoryBalanceAndTurnovers.RoomsBlockedClosingBalance) AS RoomsForSale,
	|		SUM(-RoomInventoryBalanceAndTurnovers.RoomsBlockedClosingBalance) AS RoomsBlocked,
	|		SUM(-RoomInventoryBalanceAndTurnovers.InHouseRoomsClosingBalance - RoomInventoryBalanceAndTurnovers.RoomsReservedClosingBalance) AS RoomsOccupied,
	|		0 AS PrevTotalRooms,
	|		0 AS PrevRoomsForSale,
	|		0 AS PrevRoomsBlocked,
	|		0 AS PrevRoomsOccupied,
	|		SUM(RoomInventoryBalanceAndTurnovers.TotalBedsClosingBalance) AS TotalBeds,
	|		SUM(RoomInventoryBalanceAndTurnovers.TotalBedsClosingBalance) - SUM(-RoomInventoryBalanceAndTurnovers.BedsBlockedClosingBalance) AS BedsForSale,
	|		SUM(-RoomInventoryBalanceAndTurnovers.BedsBlockedClosingBalance) AS BedsBlocked,
	|		SUM(-RoomInventoryBalanceAndTurnovers.InHouseBedsClosingBalance - RoomInventoryBalanceAndTurnovers.BedsReservedClosingBalance) AS BedsOccupied,
	|		0 AS PrevTotalBeds,
	|		0 AS PrevBedsForSale,
	|		0 AS PrevBedsBlocked,
	|		0 AS PrevBedsOccupied,
	|		RoomInventoryBalanceAndTurnovers.RoomType AS RoomType
	|	FROM
	|		AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qPeriodFrom, ENDOFPERIOD(&qPeriodTo, DAY), Day, RegisterRecordsAndPeriodBoundaries, Hotel IN (&qHotelList)) AS RoomInventoryBalanceAndTurnovers
	|	
	|	GROUP BY
	|		RoomInventoryBalanceAndTurnovers.Period,
	|		RoomInventoryBalanceAndTurnovers.InHouseRoomsClosingBalance,
	|		RoomInventoryBalanceAndTurnovers.RoomsReservedClosingBalance,
	|		RoomInventoryBalanceAndTurnovers.Hotel,
	|		RoomInventoryBalanceAndTurnovers.RoomType
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RoomInventoryBalanceAndTurnovers.Hotel,
	|		0,
	|		0,
	|		0,
	|		0,
	|		SUM(RoomInventoryBalanceAndTurnovers.TotalRoomsClosingBalance),
	|		SUM(RoomInventoryBalanceAndTurnovers.TotalRoomsClosingBalance) - SUM(-RoomInventoryBalanceAndTurnovers.RoomsBlockedClosingBalance),
	|		SUM(-RoomInventoryBalanceAndTurnovers.RoomsBlockedClosingBalance),
	|		SUM(-RoomInventoryBalanceAndTurnovers.InHouseRoomsClosingBalance - RoomInventoryBalanceAndTurnovers.RoomsReservedClosingBalance),
	|		0,
	|		0,
	|		0,
	|		0,
	|		SUM(RoomInventoryBalanceAndTurnovers.TotalBedsClosingBalance),
	|		SUM(RoomInventoryBalanceAndTurnovers.TotalBedsClosingBalance) - SUM(-RoomInventoryBalanceAndTurnovers.BedsBlockedClosingBalance),
	|		SUM(-RoomInventoryBalanceAndTurnovers.BedsBlockedClosingBalance),
	|		SUM(-RoomInventoryBalanceAndTurnovers.InHouseBedsClosingBalance - RoomInventoryBalanceAndTurnovers.BedsReservedClosingBalance),
	|		RoomInventoryBalanceAndTurnovers.RoomType
	|	FROM
	|		AccumulationRegister.RoomInventory.BalanceAndTurnovers(DATEADD(&qPeriodFrom, YEAR, -1), ENDOFPERIOD(DATEADD(&qPeriodTo, YEAR, -1), DAY), Day, RegisterRecordsAndPeriodBoundaries, Hotel IN (&qHotelList)) AS RoomInventoryBalanceAndTurnovers
	|	
	|	GROUP BY
	|		RoomInventoryBalanceAndTurnovers.Period,
	|		RoomInventoryBalanceAndTurnovers.InHouseRoomsClosingBalance,
	|		RoomInventoryBalanceAndTurnovers.RoomsReservedClosingBalance,
	|		RoomInventoryBalanceAndTurnovers.Hotel,
	|		RoomInventoryBalanceAndTurnovers.RoomType) AS NestedSelect
	|
	|GROUP BY
	|	NestedSelect.Hotel,
	|	NestedSelect.RoomType.GroupingForReports
	|
	|ORDER BY
	|	Hotel,
	|	RoomTypeGroupingForReports";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodTo));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotelList", pHotelList);
	vQryResult = vQry.Execute().Unload();
	Return vQryResult;
EndFunction

// -----------------------------------------------------------------------------
Function GetPickupByHotels(pHotelList, pWithVAT)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PickupDailyData.Hotel AS Hotel,
	|	SUM(PickupDailyData.RoomsReserved) AS RoomsReserved,
	|	SUM(PickupDailyData.ComplimentaryRoomsReserved) AS ComplimentaryRoomsReserved,
	|	SUM(PickupDailyData.HouseuseRoomsReserved) AS HouseuseRoomsReserved,
	|	SUM(PickupDailyData.DayuseRoomsReserved) AS DayuseRoomsReserved,
	|	SUM(PickupDailyData.RoomsCancelled) AS RoomsCancelled,
	|	SUM(PickupDailyData.RoomsNoShow) AS RoomsNoShow,
	|	SUM(PickupDailyData.BedsReserved) AS BedsReserved,
	|	SUM(PickupDailyData.DayuseBedsReserved) AS DayuseBedsReserved,
	|	SUM(PickupDailyData.ComplimentaryBedsReserved) AS ComplimentaryBedsReserved,
	|	SUM(PickupDailyData.HouseuseBedsReserved) AS HouseuseBedsReserved,
	|	SUM(PickupDailyData.BedsCancelled) AS BedsCancelled,
	|	SUM(PickupDailyData.BedsNoShow) AS BedsNoShow,
	|	SUM(PickupDailyData.RevenueReserved) AS RevenueReserved,
	|	SUM(PickupDailyData.RevenueCancelled) AS RevenueCancelled,
	|	SUM(PickupDailyData.RevenueNoShow) AS RevenueNoShow,
	|	SUM(PickupDailyData.PrevRoomsReserved) AS PrevRoomsReserved,
	|	SUM(PickupDailyData.PrevComplimentaryRoomsReserved) AS PrevComplimentaryRoomsReserved,
	|	SUM(PickupDailyData.PrevHouseuseRoomsReserved) AS PrevHouseuseRoomsReserved,
	|	SUM(PickupDailyData.PrevDayuseRoomsReserved) AS PrevDayuseRoomsReserved,
	|	SUM(PickupDailyData.PrevRoomsCancelled) AS PrevRoomsCancelled,
	|	SUM(PickupDailyData.PrevRoomsNoShow) AS PrevRoomsNoShow,
	|	SUM(PickupDailyData.PrevBedsReserved) AS PrevBedsReserved,
	|	SUM(PickupDailyData.PrevDayuseBedsReserved) AS PrevDayuseBedsReserved,
	|	SUM(PickupDailyData.PrevComplimentaryBedsReserved) AS PrevComplimentaryBedsReserved,
	|	SUM(PickupDailyData.PrevHouseuseBedsReserved) AS PrevHouseuseBedsReserved,
	|	SUM(PickupDailyData.PrevBedsCancelled) AS PrevBedsCancelled,
	|	SUM(PickupDailyData.PrevBedsNoShow) AS PrevBedsNoShow,
	|	SUM(PickupDailyData.PrevRevenueReserved) AS PrevRevenueReserved,
	|	SUM(PickupDailyData.PrevRevenueCancelled) AS PrevRevenueCancelled,
	|	SUM(PickupDailyData.PrevRevenueNoShow) AS PrevRevenueNoShow
	|FROM
	|	(SELECT
	|		PickupTurnovers.Hotel AS Hotel,
	|		PickupTurnovers.Period AS Period,
	|		PickupTurnovers.RoomRate AS RoomRate,
	|		PickupTurnovers.IsCancel AS IsCancel,
	|		PickupTurnovers.IsNoShow AS IsNoShow,
	|		CASE
	|			WHEN NOT PickupTurnovers.IsCancel
	|				THEN PickupTurnovers.RoomsRentedTurnover
	|			ELSE 0
	|		END AS RoomsReserved,
	|		CASE
	|			WHEN NOT PickupTurnovers.IsCancel
	|					AND ISNULL(PickupTurnovers.RoomRate.IsComplimentary, FALSE)
	|				THEN PickupTurnovers.RoomsRentedTurnover
	|			ELSE 0
	|		END AS ComplimentaryRoomsReserved,
	|		CASE
	|			WHEN NOT PickupTurnovers.IsCancel
	|					AND ISNULL(PickupTurnovers.RoomRate.IsHouseUse, FALSE)
	|				THEN PickupTurnovers.RoomsRentedTurnover
	|			ELSE 0
	|		END AS HouseuseRoomsReserved,
	|		CASE
	|			WHEN NOT PickupTurnovers.IsCancel
	|					AND PickupTurnovers.IsDayuse
	|				THEN PickupTurnovers.RoomsRentedTurnover
	|			ELSE 0
	|		END AS DayuseRoomsReserved,
	|		CASE
	|			WHEN PickupTurnovers.IsCancel
	|				THEN -PickupTurnovers.RoomsRentedTurnover
	|			ELSE 0
	|		END AS RoomsCancelled,
	|		CASE
	|			WHEN PickupTurnovers.IsCancel
	|					AND PickupTurnovers.IsNoShow
	|				THEN -PickupTurnovers.RoomsRentedTurnover
	|			ELSE 0
	|		END AS RoomsNoShow,
	|		CASE
	|			WHEN NOT PickupTurnovers.IsCancel
	|				THEN PickupTurnovers.BedsRentedTurnover
	|			ELSE 0
	|		END AS BedsReserved,
	|		CASE
	|			WHEN NOT PickupTurnovers.IsCancel
	|					AND ISNULL(PickupTurnovers.RoomRate.IsComplimentary, FALSE)
	|				THEN PickupTurnovers.BedsRentedTurnover
	|			ELSE 0
	|		END AS ComplimentaryBedsReserved,
	|		CASE
	|			WHEN NOT PickupTurnovers.IsCancel
	|					AND ISNULL(PickupTurnovers.RoomRate.IsHouseUse, FALSE)
	|				THEN PickupTurnovers.BedsRentedTurnover
	|			ELSE 0
	|		END AS HouseuseBedsReserved,
	|		CASE
	|			WHEN NOT PickupTurnovers.IsCancel
	|					AND PickupTurnovers.IsDayuse
	|				THEN PickupTurnovers.BedsRentedTurnover
	|			ELSE 0
	|		END AS DayuseBedsReserved,
	|		CASE
	|			WHEN PickupTurnovers.IsCancel
	|				THEN -PickupTurnovers.BedsRentedTurnover
	|			ELSE 0
	|		END AS BedsCancelled,
	|		CASE
	|			WHEN PickupTurnovers.IsCancel
	|					AND PickupTurnovers.IsNoShow
	|				THEN -PickupTurnovers.BedsRentedTurnover
	|			ELSE 0
	|		END AS BedsNoShow,
	|		CASE
	|			WHEN NOT PickupTurnovers.IsCancel
	|				THEN CASE
	|						WHEN &qWithVAT
	|							THEN PickupTurnovers.RevenueTurnover
	|						ELSE PickupTurnovers.RevenueWithoutVATTurnover
	|					END
	|			ELSE 0
	|		END AS RevenueReserved,
	|		CASE
	|			WHEN PickupTurnovers.IsCancel
	|				THEN CASE
	|						WHEN &qWithVAT
	|							THEN -PickupTurnovers.RevenueTurnover
	|						ELSE -PickupTurnovers.RevenueWithoutVATTurnover
	|					END
	|			ELSE 0
	|		END AS RevenueCancelled,
	|		CASE
	|			WHEN PickupTurnovers.IsCancel
	|					AND PickupTurnovers.IsNoShow
	|				THEN CASE
	|						WHEN &qWithVAT
	|							THEN -PickupTurnovers.RevenueTurnover
	|						ELSE -PickupTurnovers.RevenueWithoutVATTurnover
	|					END
	|			ELSE 0
	|		END AS RevenueNoShow,
	|		0 AS PrevRoomsReserved,
	|		0 AS PrevComplimentaryRoomsReserved,
	|		0 AS PrevHouseuseRoomsReserved,
	|		0 AS PrevDayuseRoomsReserved,
	|		0 AS PrevRoomsCancelled,
	|		0 AS PrevRoomsNoShow,
	|		0 AS PrevBedsReserved,
	|		0 AS PrevComplimentaryBedsReserved,
	|		0 AS PrevHouseuseBedsReserved,
	|		0 AS PrevDayuseBedsReserved,
	|		0 AS PrevBedsCancelled,
	|		0 AS PrevBedsNoShow,
	|		0 AS PrevRevenueReserved,
	|		0 AS PrevRevenueCancelled,
	|		0 AS PrevRevenueNoShow
	|	FROM
	|		AccumulationRegister.Pickup.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Day,
	|				Hotel IN (&qHotelList)
	|					AND GuestGroup <> VALUE(Catalog.GuestGroups.EmptyRef)) AS PickupTurnovers
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		PrevPickupTurnovers.Hotel,
	|		PrevPickupTurnovers.Period,
	|		PrevPickupTurnovers.RoomRate,
	|		PrevPickupTurnovers.IsCancel,
	|		PrevPickupTurnovers.IsNoShow,
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
	|			WHEN NOT PrevPickupTurnovers.IsCancel
	|				THEN PrevPickupTurnovers.RoomsRentedTurnover
	|			ELSE 0
	|		END,
	|		CASE
	|			WHEN NOT PrevPickupTurnovers.IsCancel
	|					AND ISNULL(PrevPickupTurnovers.RoomRate.IsComplimentary, FALSE)
	|				THEN PrevPickupTurnovers.RoomsRentedTurnover
	|			ELSE 0
	|		END,
	|		CASE
	|			WHEN NOT PrevPickupTurnovers.IsCancel
	|					AND ISNULL(PrevPickupTurnovers.RoomRate.IsHouseUse, FALSE)
	|				THEN PrevPickupTurnovers.RoomsRentedTurnover
	|			ELSE 0
	|		END,
	|		CASE
	|			WHEN NOT PrevPickupTurnovers.IsCancel
	|					AND PrevPickupTurnovers.IsDayuse
	|				THEN PrevPickupTurnovers.RoomsRentedTurnover
	|			ELSE 0
	|		END,
	|		CASE
	|			WHEN PrevPickupTurnovers.IsCancel
	|				THEN -PrevPickupTurnovers.RoomsRentedTurnover
	|			ELSE 0
	|		END,
	|		CASE
	|			WHEN PrevPickupTurnovers.IsCancel
	|					AND PrevPickupTurnovers.IsNoShow
	|				THEN -PrevPickupTurnovers.RoomsRentedTurnover
	|			ELSE 0
	|		END,
	|		CASE
	|			WHEN NOT PrevPickupTurnovers.IsCancel
	|				THEN PrevPickupTurnovers.BedsRentedTurnover
	|			ELSE 0
	|		END,
	|		CASE
	|			WHEN NOT PrevPickupTurnovers.IsCancel
	|					AND ISNULL(PrevPickupTurnovers.RoomRate.IsComplimentary, FALSE)
	|				THEN PrevPickupTurnovers.BedsRentedTurnover
	|			ELSE 0
	|		END,
	|		CASE
	|			WHEN NOT PrevPickupTurnovers.IsCancel
	|					AND ISNULL(PrevPickupTurnovers.RoomRate.IsHouseUse, FALSE)
	|				THEN PrevPickupTurnovers.BedsRentedTurnover
	|			ELSE 0
	|		END,
	|		CASE
	|			WHEN NOT PrevPickupTurnovers.IsCancel
	|					AND PrevPickupTurnovers.IsDayuse
	|				THEN PrevPickupTurnovers.BedsRentedTurnover
	|			ELSE 0
	|		END,
	|		CASE
	|			WHEN PrevPickupTurnovers.IsCancel
	|				THEN -PrevPickupTurnovers.BedsRentedTurnover
	|			ELSE 0
	|		END,
	|		CASE
	|			WHEN PrevPickupTurnovers.IsCancel
	|					AND PrevPickupTurnovers.IsNoShow
	|				THEN -PrevPickupTurnovers.BedsRentedTurnover
	|			ELSE 0
	|		END,
	|		CASE
	|			WHEN NOT PrevPickupTurnovers.IsCancel
	|				THEN CASE
	|						WHEN &qWithVAT
	|							THEN PrevPickupTurnovers.RevenueTurnover
	|						ELSE PrevPickupTurnovers.RevenueWithoutVATTurnover
	|					END
	|			ELSE 0
	|		END,
	|		CASE
	|			WHEN PrevPickupTurnovers.IsCancel
	|				THEN CASE
	|						WHEN &qWithVAT
	|							THEN -PrevPickupTurnovers.RevenueTurnover
	|						ELSE -PrevPickupTurnovers.RevenueWithoutVATTurnover
	|					END
	|			ELSE 0
	|		END,
	|		CASE
	|			WHEN PrevPickupTurnovers.IsCancel
	|					AND PrevPickupTurnovers.IsNoShow
	|				THEN CASE
	|						WHEN &qWithVAT
	|							THEN -PrevPickupTurnovers.RevenueTurnover
	|						ELSE -PrevPickupTurnovers.RevenueWithoutVATTurnover
	|					END
	|			ELSE 0
	|		END
	|	FROM
	|		AccumulationRegister.Pickup.Turnovers(
	|				DATEADD(&qPeriodFrom, YEAR, -1),
	|				DATEADD(&qPeriodTo, YEAR, -1),
	|				DAY,
	|				Hotel IN (&qHotelList)
	|					AND GuestGroup <> VALUE(Catalog.GuestGroups.EmptyRef)) AS PrevPickupTurnovers) AS PickupDailyData
	|
	|GROUP BY
	|	PickupDailyData.Hotel
	|
	|ORDER BY
	|	PickupDailyData.Hotel.Code";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodTo));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotelList", pHotelList);
	vQry.SetParameter("qWithVAT", pWithVAT);
	vQryResult = vQry.Execute().Unload();
	Return vQryResult;
EndFunction // GetPickupByHotels

#EndRegion
