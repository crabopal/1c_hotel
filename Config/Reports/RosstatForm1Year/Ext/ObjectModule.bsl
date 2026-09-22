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
	If Not ValueIsFilled(PeriodFrom) Then
		PeriodFrom = AddMonth(BegOfYear(CurrentSessionDate()), -12);
		PeriodTo = EndOfYear(PeriodFrom);
	EndIf;
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(Hotel) Then
		If Not ValueIsFilled(Company) Then
			Company = Hotel.Company;
		EndIf;
		If Not ValueIsFilled(RussiaCountry) Then
			RussiaCountry = Hotel.Citizenship;
		EndIf;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Procedure pmGenerate(pSpreadsheet) Export
	// Generate spreadsheet
	If PeriodTo < '20200101' Then
		pmGenerate2019(pSpreadsheet);
	ElsIf PeriodTo < '20210101' Then
		pmGenerate2020(pSpreadsheet);
	ElsIf PeriodTo < '20220101' Then
		pmGenerate2021(pSpreadsheet);
	ElsIf PeriodTo < '20230101' Then
		pmGenerate2022(pSpreadsheet);
	ElsIf PeriodTo < '20240101' Then
		pmGenerate2023(pSpreadsheet);
	ElsIf PeriodTo < '20250101' Then
		pmGenerate2024(pSpreadsheet);
	Else
		pmGenerate2025(pSpreadsheet);
	EndIf;
EndProcedure // pmGenerate

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Procedure pmGenerate2019(pSpreadsheet) Export
	// Clear output spreadsheet
	pSpreadsheet.Clear();
	
	// Choose template
	vTemplate = ThisObject.GetTemplate("Report2019");
	
	// Report pages
	vPage1Area = vTemplate.GetArea("Page1");
	vPage2Area = vTemplate.GetArea("Page2");
	vPage3Area = vTemplate.GetArea("Page3");
	vPage3H1Area = vTemplate.GetArea("Page3H1");
	vPage3H1RowArea = vTemplate.GetArea("Page3H1Row");
	vPage3H2Area = vTemplate.GetArea("Page3H2");
	vPage4Area = vTemplate.GetArea("Page4");
	vPage5Area = vTemplate.GetArea("Page5");
	
	// Page 1
	vPage1Area.Parameters.mPeriodStr = PeriodPresentation(BegOfDay(PeriodFrom), EndOfDay(PeriodTo), cmLocalizationCode());
	vPage1Area.Parameters.mHotelName = TrimAll(Hotel.LegacyName);
	vPage1Area.Parameters.mHotelPostAddress = cmGetAddressPresentation(Hotel.PostAddress);
	vPage1Area.Parameters.mCompanyName = TrimAll(Company.LegacyName);
	vPage1Area.Parameters.mCompanyPostAddress = cmGetAddressPresentation(Company.PostAddress);
	vPage1Area.Parameters.mCompanyOKPOCode = TrimAll(Company.OKPO);
	pSpreadsheet.Put(vPage1Area);
	pSpreadsheet.PutHorizontalPageBreak();
	
	// Page 2
	pSpreadsheet.Put(vPage2Area);
	pSpreadsheet.PutHorizontalPageBreak();
	
	// Page 3
	
	// 3.1 Get total number of rooms/beds per end of period
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInventoryBalance.TotalRoomsBalance AS TotalRoomsBalance,
	|	RoomInventoryBalance.TotalBedsBalance AS TotalBedsBalance
	|FROM
	|	AccumulationRegister.RoomInventory.Balance(
	|			&qPeriodTo,
	|			Hotel = &qHotel
	|				AND (Room.Company = &qCompany
	|					OR Room.Company = &qEmptyCompany)
	|				AND (RoomType.Company = &qCompany
	|					OR RoomType.Company = &qEmptyCompany)) AS RoomInventoryBalance";
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyCompany", Catalogs.Companies.EmptyRef());
	vQryResult = vQry.Execute().Unload();

	vPage3Area.Parameters.mTotalRooms = 0;
	vPage3Area.Parameters.mTotalBeds = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vPage3Area.Parameters.mTotalRooms = vRow.TotalRoomsBalance;
		vPage3Area.Parameters.mTotalBeds = vRow.TotalBedsBalance;
	EndIf;
	
	// 3.2 Get total number of rooms/beds for top room types per end of period
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInventoryBalance.TotalRoomsBalance AS TotalRoomsBalance,
	|	RoomInventoryBalance.TotalBedsBalance AS TotalBedsBalance
	|FROM
	|	AccumulationRegister.RoomInventory.Balance(
	|			&qPeriodTo,
	|			Hotel = &qHotel
	|				AND (&qNoTopRoomTypes
	|					OR NOT &qNoTopRoomTypes
	|						AND RoomType IN HIERARCHY (&qTopRoomTypes))
	|				AND (Room.Company = &qCompany
	|					OR Room.Company = &qEmptyCompany)
	|				AND (RoomType.Company = &qCompany
	|					OR RoomType.Company = &qEmptyCompany)) AS RoomInventoryBalance";
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyCompany", Catalogs.Companies.EmptyRef());
	vQry.SetParameter("qNoTopRoomTypes", Not ValueIsFilled(TopRoomTypes));
	vQry.SetParameter("qTopRoomTypes", TopRoomTypes);
	vQryResult = vQry.Execute().Unload();

	vPage3Area.Parameters.mTotalTopRooms = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vPage3Area.Parameters.mTotalTopRooms = vRow.TotalRoomsBalance;
	EndIf;
	
	// 3.3 Get total number of guest days and number of checked in guests
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SUM(ISNULL(RoomSales.GuestDaysTurnover, 0)) AS GuestDaysTurnover,
	|	SUM(ISNULL(RoomSales.GuestDays18Turnover, 0)) AS GuestDays18Turnover,
	|	SUM(ISNULL(RoomSales.GuestDays55Turnover, 0)) AS GuestDays55Turnover,
	|	SUM(ISNULL(RoomSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover,
	|	SUM(ISNULL(RoomSales.GuestsCheckedIn18Turnover, 0)) AS GuestsCheckedIn18Turnover,
	|	SUM(ISNULL(RoomSales.GuestsCheckedIn55Turnover, 0)) AS GuestsCheckedIn55Turnover
	|FROM
	|	(SELECT
	|		RoomSalesTurnovers.Client AS Client,
	|		RoomSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover,
	|		CASE
	|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND RoomSalesTurnovers.Client.Age < 18
	|				THEN RoomSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays18Turnover,
	|		CASE
	|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND RoomSalesTurnovers.Client.Age >= 55
	|				THEN RoomSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays55Turnover,
	|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
	|		CASE
	|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND RoomSalesTurnovers.Client.Age < 18
	|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn18Turnover,
	|		CASE
	|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND RoomSalesTurnovers.Client.Age >= 55
	|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn55Turnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany) AS RoomSalesTurnovers) AS RoomSales";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyDate", '00010101');
	vQryResult = vQry.Execute().Unload();

	vTotalGuestDays = 0;
	vTotalGuestDays18 = 0;
	vTotalGuestDays55 = 0;
	vTotalGuests = 0;
	vTotalGuests18 = 0;
	vTotalGuests55 = 0;
	vPage3Area.Parameters.mTotalGuestDays = 0;
	vPage3Area.Parameters.mTotalGuestDays18 = 0;
	vPage3Area.Parameters.mTotalGuestDays55 = 0;
	vPage3Area.Parameters.mTotalGuests = 0;
	vPage3Area.Parameters.mTotalGuests18 = 0;
	vPage3Area.Parameters.mTotalGuests55 = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vPage3Area.Parameters.mTotalGuestDays = vRow.GuestDaysTurnover;
		vPage3Area.Parameters.mTotalGuestDays18 = vRow.GuestDays18Turnover;
		vPage3Area.Parameters.mTotalGuestDays55 = vRow.GuestDays55Turnover;
		vPage3Area.Parameters.mTotalGuests = vRow.GuestsCheckedInTurnover;
		vPage3Area.Parameters.mTotalGuests18 = vRow.GuestsCheckedIn18Turnover;
		vPage3Area.Parameters.mTotalGuests55 = vRow.GuestsCheckedIn55Turnover;
		vTotalGuestDays = vRow.GuestDaysTurnover;
		vTotalGuestDays18 = vRow.GuestDays18Turnover;
		vTotalGuestDays55 = vRow.GuestDays55Turnover;
		vTotalGuests = vRow.GuestsCheckedInTurnover;
		vTotalGuests18 = vRow.GuestsCheckedIn18Turnover;
		vTotalGuests55 = vRow.GuestsCheckedIn55Turnover;
	EndIf;
	
	// 3.4 Get total number of guest days and checked-in guests from Russia
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SUM(ISNULL(GeoSales.GuestDaysTurnover, 0)) AS GuestDaysTurnover,
	|	SUM(ISNULL(GeoSales.GuestDays18Turnover, 0)) AS GuestDays18Turnover,
	|	SUM(ISNULL(GeoSales.GuestDays55Turnover, 0)) AS GuestDays55Turnover,
	|	SUM(ISNULL(GeoSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover,
	|	SUM(ISNULL(GeoSales.GuestsCheckedIn18Turnover, 0)) AS GuestsCheckedIn18Turnover,
	|	SUM(ISNULL(GeoSales.GuestsCheckedIn55Turnover, 0)) AS GuestsCheckedIn55Turnover
	|FROM
	|	(SELECT
	|		GeoSalesTurnovers.Client AS Client,
	|		GeoSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age < 18
	|				THEN GeoSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays18Turnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age >= 55
	|				THEN GeoSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays55Turnover,
	|		GeoSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age < 18
	|				THEN GeoSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn18Turnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age >= 55
	|				THEN GeoSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn55Turnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND (Client.Citizenship = &qRussia
	|						OR ISNULL(Client.Citizenship.Description, """") = """")) AS GeoSalesTurnovers) AS GeoSales";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyDate", '00010101');
	vQryResult = vQry.Execute().Unload();

	vRussiaGuestDays = 0;
	vRussiaGuestDays18 = 0;
	vRussiaGuestDays55 = 0;
	vRussiaGuests = 0;
	vRussiaGuests18 = 0;
	vRussiaGuests55 = 0;
	vPage3Area.Parameters.mTotalGuestsRus = 0;
	vPage3Area.Parameters.mTotalGuestsRus18 = 0;
	vPage3Area.Parameters.mTotalGuestsRus55 = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vPage3Area.Parameters.mTotalGuestsRus = vRow.GuestsCheckedInTurnover;
		vPage3Area.Parameters.mTotalGuestsRus18 = vRow.GuestsCheckedIn18Turnover;
		vPage3Area.Parameters.mTotalGuestsRus55 = vRow.GuestsCheckedIn55Turnover;
		vRussiaGuestDays = vRow.GuestDaysTurnover;
		vRussiaGuestDays18 = vRow.GuestDays18Turnover;
		vRussiaGuestDays55 = vRow.GuestDays55Turnover;
		vRussiaGuests = vRow.GuestsCheckedInTurnover;
		vRussiaGuests18 = vRow.GuestsCheckedIn18Turnover;
		vRussiaGuests55 = vRow.GuestsCheckedIn55Turnover;
	EndIf;
	
	// 3.5 Get total number of guest days and checked-in foreigner guests
	If vTotalGuests <> Null And vRussiaGuests <> Null Then
		vPage3Area.Parameters.mTotalGuestsForeigners = vTotalGuests - vRussiaGuests;
		vPage3Area.Parameters.mTotalGuestsForeigners18 = vTotalGuests18 - vRussiaGuests18;
		vPage3Area.Parameters.mTotalGuestsForeigners55 = vTotalGuests55 - vRussiaGuests55;
	Else
		vPage3Area.Parameters.mTotalGuestsForeigners = 0;
		vPage3Area.Parameters.mTotalGuestsForeigners18 = 0;
		vPage3Area.Parameters.mTotalGuestsForeigners55 = 0;
	EndIf;
	
	// 3.6 Get total number of checked-in guests with tour tickets
	vPage3Area.Parameters.mTotalTourTicketGuests = 0;
	vPage3Area.Parameters.mTotalTourTicketGuests18 = 0;
	vPage3Area.Parameters.mTotalTourTicketGuests55 = 0;
	If ValueIsFilled(TourTicketIncomeServiceGroup) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	SUM(ISNULL(RoomSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover,
		|	SUM(ISNULL(RoomSales.GuestsCheckedIn18Turnover, 0)) AS GuestsCheckedIn18Turnover,
		|	SUM(ISNULL(RoomSales.GuestsCheckedIn55Turnover, 0)) AS GuestsCheckedIn55Turnover
		|FROM
		|	(SELECT
		|		RoomSalesTurnovers.Client AS Client,
		|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
		|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					AND RoomSalesTurnovers.Client.Age < 18
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			ELSE 0
		|		END AS GuestsCheckedIn18Turnover,
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
		|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					AND RoomSalesTurnovers.Client.Age >= 55
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			ELSE 0
		|		END AS GuestsCheckedIn55Turnover
		|	FROM
		|		AccumulationRegister.Sales.Turnovers(
		|				&qPeriodFrom,
		|				&qPeriodTo,
		|				Period,
		|				NOT IsCorrection AND Hotel = &qHotel
		|					AND Company = &qCompany
		|					AND (Service IN HIERARCHY (&qTourTicketServices)
		|						OR NOT &qUseServicesList)
		|					) AS RoomSalesTurnovers) AS RoomSales";
		vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qCompany", Company);
		vUseServicesList = False;
		vServicesList = New ValueList();
		If Not TourTicketIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(TourTicketIncomeServiceGroup);
		EndIf;
		vQry.SetParameter("qUseServicesList", vUseServicesList);
		vQry.SetParameter("qTourTicketServices", vServicesList);
		vQry.SetParameter("qEmptyDate", '00010101');
		vQryResult = vQry.Execute().Unload();

		If vQryResult.Count() > 0 Then
			vRow = vQryResult.Get(0);
			vPage3Area.Parameters.mTotalTourTicketGuests = vRow.GuestsCheckedInTurnover;
			vPage3Area.Parameters.mTotalTourTicketGuests18 = vRow.GuestsCheckedIn18Turnover;
			vPage3Area.Parameters.mTotalTourTicketGuests55 = vRow.GuestsCheckedIn55Turnover;
		EndIf;
		
		// The same from russia
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	SUM(ISNULL(RoomSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover,
		|	SUM(ISNULL(RoomSales.GuestsCheckedIn18Turnover, 0)) AS GuestsCheckedIn18Turnover,
		|	SUM(ISNULL(RoomSales.GuestsCheckedIn55Turnover, 0)) AS GuestsCheckedIn55Turnover
		|FROM
		|	(SELECT
		|		RoomSalesTurnovers.Client AS Client,
		|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL
		|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					AND RoomSalesTurnovers.Client.Age < 18
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			ELSE 0
		|		END AS GuestsCheckedIn18Turnover,
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL
		|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					AND RoomSalesTurnovers.Client.Age >= 55
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			ELSE 0
		|		END AS GuestsCheckedIn55Turnover
		|	FROM
		|		AccumulationRegister.Sales.Turnovers(
		|				&qPeriodFrom,
		|				&qPeriodTo,
		|				Period,
		|				NOT IsCorrection
		|					AND Hotel = &qHotel
		|					AND Company = &qCompany
		|					AND (Service IN HIERARCHY (&qTourTicketServices)
		|						OR NOT &qUseServicesList)
		|					AND (Client.Citizenship = &qRussia
		|						OR ISNULL(Client.Citizenship.Description, """") = """")) AS RoomSalesTurnovers) AS RoomSales";
		vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qRussia", RussiaCountry);
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qCompany", Company);
		vUseServicesList = False;
		vServicesList = New ValueList();
		If Not TourTicketIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(TourTicketIncomeServiceGroup);
		EndIf;
		vQry.SetParameter("qUseServicesList", vUseServicesList);
		vQry.SetParameter("qTourTicketServices", vServicesList);
		vQry.SetParameter("qEmptyDate", '00010101');
		vQryResult = vQry.Execute().Unload();

		If vQryResult.Count() > 0 Then
			vRow = vQryResult.Get(0);
			vPage3Area.Parameters.mTotalTourTicketGuestsRus = vRow.GuestsCheckedInTurnover;
			vPage3Area.Parameters.mTotalTourTicketGuestsRus18 = vRow.GuestsCheckedIn18Turnover;
			vPage3Area.Parameters.mTotalTourTicketGuestsRus55 = vRow.GuestsCheckedIn55Turnover;
			
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners = vPage3Area.Parameters.mTotalTourTicketGuests - vRow.GuestsCheckedInTurnover;
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners18 = vPage3Area.Parameters.mTotalTourTicketGuests18 - vRow.GuestsCheckedIn18Turnover;
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners55 = vPage3Area.Parameters.mTotalTourTicketGuests55 - vRow.GuestsCheckedIn55Turnover;
		Else
			vPage3Area.Parameters.mTotalTourTicketGuestsRus = 0;
			vPage3Area.Parameters.mTotalTourTicketGuestsRus18 = 0;
			vPage3Area.Parameters.mTotalTourTicketGuestsRus55 = 0;
			
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners = 0;
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners18 = 0;
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners55 = 0;
		EndIf;
	EndIf;
	
	pSpreadsheet.Put(vPage3Area);
	
	// Page 3 header Spr. 1
	pSpreadsheet.Put(vPage3H1Area);
	
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ISNULL(GeoSales.Client.Citizenship.Description, """") AS CountryDescription,
	|	ISNULL(GeoSales.Client.Citizenship.Code, 0) AS CountryCode,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			NOT IsCorrection AND Hotel = &qHotel
	|				AND Company = &qCompany
	|				AND Client.Citizenship <> &qRussia
	|				AND ISNULL(Client.Citizenship.Description, """") <> """") AS GeoSales
	|
	|GROUP BY
	|	GeoSales.Client.Citizenship.Description,
	|	GeoSales.Client.Citizenship.Code
	|
	|ORDER BY
	|	GeoSales.Client.Citizenship.Code";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQryResult = vQry.Execute().Unload();
	c = 0;
	While c < vQryResult.Count() Do
		vQryResultLRow = vQryResult.Get(c);
		
		vPage3H1RowArea.Parameters.mCountryL = TrimAll(vQryResultLRow.CountryDescription);
		vPage3H1RowArea.Parameters.mCountryCodeL = TrimAll(vQryResultLRow.CountryCode);
		vPage3H1RowArea.Parameters.mCountryGuestsL = vQryResultLRow.GuestsCheckedInTurnover;
		
		If c < (vQryResult.Count() - 1) Then
			vQryResultRRow = vQryResult.Get(c + 1);
			
			vPage3H1RowArea.Parameters.mCountryR = TrimAll(vQryResultRRow.CountryDescription);
			vPage3H1RowArea.Parameters.mCountryCodeR = TrimAll(vQryResultRRow.CountryCode);
			vPage3H1RowArea.Parameters.mCountryGuestsR = vQryResultRRow.GuestsCheckedInTurnover;
		Else
			vPage3H1RowArea.Parameters.mCountryR = "";
			vPage3H1RowArea.Parameters.mCountryCodeR = "";
			vPage3H1RowArea.Parameters.mCountryGuestsR = 0;
		EndIf;
		
		pSpreadsheet.Put(vPage3H1RowArea);
		
		c = c + 2;
	EndDo;
	
	// Get number of checked in guests by hotel products (Page 3. Spr 2)
	vPage3H2Area.Parameters.mVaucherQuantity = 0;
	vPage3H2Area.Parameters.mVaucher18Quantity = 0;
	vPage3H2Area.Parameters.mVaucher55Quantity = 0;
	
	If ValueIsFilled(VaucherIncomeServiceGroup) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	SUM(AgeSales.VaucherQuantity) AS VaucherQuantity,
		|	SUM(AgeSales.Vaucher18Quantity) AS Vaucher18Quantity,
		|	SUM(AgeSales.Vaucher55Quantity) AS Vaucher55Quantity
		|FROM
		|	(SELECT
		|		RoomSalesTurnovers.Client AS Client,
		|		RoomSalesTurnovers.Client.Age AS ClientAge,
		|		MAX(1) AS VaucherQuantity,
		|		MAX(CASE
		|				WHEN RoomSalesTurnovers.Client.Age < 18
		|						AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					THEN 1
		|				ELSE 0
		|			END) AS Vaucher18Quantity,
		|		MAX(CASE
		|				WHEN RoomSalesTurnovers.Client.Age >= 55
		|					THEN 1
		|				ELSE 0
		|			END) AS Vaucher55Quantity
		|	FROM
		|		AccumulationRegister.Sales.Turnovers(
		|				&qPeriodFrom,
		|				&qPeriodTo,
		|				Period,
		|				NOT IsCorrection AND Hotel = &qHotel
		|					AND Company = &qCompany
		|					AND (Service IN HIERARCHY (&qVaucherServices)
		|						OR NOT &qUseServicesList)) AS RoomSalesTurnovers
		|	
		|	GROUP BY
		|		RoomSalesTurnovers.Client,
		|		RoomSalesTurnovers.Client.Age) AS AgeSales";
		vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qCompany", Company);
		vQry.SetParameter("qEmptyDate", '00010101');
		vUseServicesList = False;
		vServicesList = New ValueList();
		If Not TourTicketIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(VaucherIncomeServiceGroup);
		EndIf;
		vQry.SetParameter("qUseServicesList", vUseServicesList);
		vQry.SetParameter("qVaucherServices", vServicesList);
		vQryResult = vQry.Execute().Unload();

		If vQryResult.Count() > 0 Then
			vRow = vQryResult.Get(0);
			
			vPage3H2Area.Parameters.mVaucherQuantity = vRow.VaucherQuantity;
			vPage3H2Area.Parameters.mVaucher18Quantity = vRow.Vaucher18Quantity;
			vPage3H2Area.Parameters.mVaucher55Quantity = vRow.Vaucher55Quantity;
		EndIf;
	EndIf;
	
	pSpreadsheet.Put(vPage3H2Area);
	
	pSpreadsheet.PutHorizontalPageBreak();
	
	// Page 4
	
	// 4.1.1 Get total number of russian checked-in guests per trip purposes
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qEducation
	|			THEN 4
	|		ELSE 7
	|	END AS TripPurposeType,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		GeoSalesTurnovers.TripPurpose AS TripPurpose,
	|		SUM(GeoSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND (Client.Citizenship = &qRussia
	|						OR ISNULL(Client.Citizenship.Description, """") = """")) AS GeoSalesTurnovers
	|	
	|	GROUP BY
	|		GeoSalesTurnovers.TripPurpose) AS GeoSales
	|
	|GROUP BY
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qEducation
	|			THEN 4
	|		ELSE 7
	|	END
	|
	|ORDER BY
	|	TripPurposeType";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qBusiness", Catalogs.TripPurposes.Business);
	vQry.SetParameter("qCommerce", Catalogs.TripPurposes.Commerce);
	vQry.SetParameter("qOfficial", Catalogs.TripPurposes.Official);
	vQry.SetParameter("qWork", Catalogs.TripPurposes.Work);
	vQry.SetParameter("qCrewman", Catalogs.TripPurposes.Crewman);
	vQry.SetParameter("qHumanitarian", Catalogs.TripPurposes.Humanitarian);
	vQry.SetParameter("qTourism", Catalogs.TripPurposes.Tourism);
	vQry.SetParameter("qPrivate", Catalogs.TripPurposes.Private);
	vQry.SetParameter("qScientific", Catalogs.TripPurposes.Scientific);
	vQry.SetParameter("qEducation", Catalogs.TripPurposes.Study);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyCountry", Catalogs.Countries.EmptyRef());
	vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vQry.SetParameter("qEmptyCountry", Catalogs.Countries.EmptyRef());
	vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vQryResult = vQry.Execute().Unload();
	
	vPage4Area.Parameters.mGuestsTouristsRus = 0;
	vPage4Area.Parameters.mGuestsEducationRus = 0;
	vPage4Area.Parameters.mGuestsBusinessRus = 0;
	vPage4Area.Parameters.mGuestsCureRus = 0;
	vPage4Area.Parameters.mGuestsPilgrimRus = 0;
	vPage4Area.Parameters.mGuestsOtherRus = 0;

	For Each vRow In vQryResult Do
		If vRow.TripPurposeType = 3 Then
			vPage4Area.Parameters.mGuestsTouristsRus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 4 Then
			vPage4Area.Parameters.mGuestsEducationRus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 8 Then
			vPage4Area.Parameters.mGuestsBusinessRus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 5 Then
			vPage4Area.Parameters.mGuestsCureRus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 6 Then
			vPage4Area.Parameters.mGuestsPilgrimRus = vRow.GuestsCheckedInTurnover;
		Else
			vPage4Area.Parameters.mGuestsOtherRus = vRow.GuestsCheckedInTurnover;
		EndIf;
	EndDo;
	
	// 4.1.4 Get total number of checked-in foreigner guests per trip purposes
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qEducation
	|			THEN 4
	|		ELSE 7
	|	END AS TripPurposeType,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		GeoSalesTurnovers.TripPurpose AS TripPurpose,
	|		SUM(GeoSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND Client.Citizenship <> &qRussia
	|					AND ISNULL(Client.Citizenship.Description, """") <> """") AS GeoSalesTurnovers
	|	
	|	GROUP BY
	|		GeoSalesTurnovers.TripPurpose) AS GeoSales
	|
	|GROUP BY
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qEducation
	|			THEN 4
	|		ELSE 7
	|	END
	|
	|ORDER BY
	|	TripPurposeType";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qBusiness", Catalogs.TripPurposes.Business);
	vQry.SetParameter("qCommerce", Catalogs.TripPurposes.Commerce);
	vQry.SetParameter("qOfficial", Catalogs.TripPurposes.Official);
	vQry.SetParameter("qWork", Catalogs.TripPurposes.Work);
	vQry.SetParameter("qCrewman", Catalogs.TripPurposes.Crewman);
	vQry.SetParameter("qHumanitarian", Catalogs.TripPurposes.Humanitarian);
	vQry.SetParameter("qTourism", Catalogs.TripPurposes.Tourism);
	vQry.SetParameter("qPrivate", Catalogs.TripPurposes.Private);
	vQry.SetParameter("qScientific", Catalogs.TripPurposes.Scientific);
	vQry.SetParameter("qEducation", Catalogs.TripPurposes.Study);
	vQry.SetParameter("qCompany", Company);
	vQryResult = vQry.Execute().Unload();
	
	vPage4Area.Parameters.mGuestsTouristsForeigners = 0;
	vPage4Area.Parameters.mGuestsEducationForeigners = 0;
	vPage4Area.Parameters.mGuestsBusinessForeigners = 0;
	vPage4Area.Parameters.mGuestsCureForeigners = 0;
	vPage4Area.Parameters.mGuestsPilgrimForeigners = 0;
	vPage4Area.Parameters.mGuestsOtherForeigners = 0;

	For Each vRow In vQryResult Do
		If vRow.TripPurposeType = 3 Then
			vPage4Area.Parameters.mGuestsTouristsForeigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 4 Then
			vPage4Area.Parameters.mGuestsEducationForeigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 8 Then
			vPage4Area.Parameters.mGuestsBusinessForeigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 5 Then
			vPage4Area.Parameters.mGuestsCureForeigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 6 Then
			vPage4Area.Parameters.mGuestsPilgrimForeigners = vRow.GuestsCheckedInTurnover;
		Else
			vPage4Area.Parameters.mGuestsOtherForeigners = vRow.GuestsCheckedInTurnover;
		EndIf;
	EndDo;
	
	// 4.2.1 Get total number of russian checked-in guests per duration
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 0
	|		WHEN GeoSales.Duration < 5
	|			THEN 4
	|		WHEN GeoSales.Duration < 8
	|			THEN 7
	|		WHEN GeoSales.Duration < 15
	|			THEN 14
	|		WHEN GeoSales.Duration < 29
	|			THEN 28
	|		WHEN GeoSales.Duration < 91
	|			THEN 90
	|		WHEN GeoSales.Duration < 183
	|			THEN 182
	|		ELSE 183
	|	END AS DurationType,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0) AS Duration,
	|		SUM(GeoSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND (Client.Citizenship = &qRussia
	|						OR ISNULL(Client.Citizenship.Description, """") = """")) AS GeoSalesTurnovers
	|	
	|	GROUP BY
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0)) AS GeoSales
	|
	|GROUP BY
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 0
	|		WHEN GeoSales.Duration < 5
	|			THEN 4
	|		WHEN GeoSales.Duration < 8
	|			THEN 7
	|		WHEN GeoSales.Duration < 15
	|			THEN 14
	|		WHEN GeoSales.Duration < 29
	|			THEN 28
	|		WHEN GeoSales.Duration < 91
	|			THEN 90
	|		WHEN GeoSales.Duration < 183
	|			THEN 182
	|		ELSE 183
	|	END
	|
	|ORDER BY
	|	DurationType";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyCountry", Catalogs.Countries.EmptyRef());
	vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vQryResult = vQry.Execute().Unload();
	
	vPage4Area.Parameters.mGuests0Rus = 0;
	vPage4Area.Parameters.mGuests1_4Rus = 0;
	vPage4Area.Parameters.mGuests5_7Rus = 0;
	vPage4Area.Parameters.mGuests8_14Rus = 0;
	vPage4Area.Parameters.mGuests15_28Rus = 0;
	vPage4Area.Parameters.mGuests29_90Rus = 0;
	vPage4Area.Parameters.mGuests91_182Rus = 0;
	vPage4Area.Parameters.mGuests183Rus = 0;

	For Each vRow In vQryResult Do
		If vRow.DurationType = 0 Then
			vPage4Area.Parameters.mGuests0Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 4 Then
			vPage4Area.Parameters.mGuests1_4Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 7 Then
			vPage4Area.Parameters.mGuests5_7Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 14 Then
			vPage4Area.Parameters.mGuests8_14Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 28 Then
			vPage4Area.Parameters.mGuests15_28Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 90 Then
			vPage4Area.Parameters.mGuests29_90Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 182 Then
			vPage4Area.Parameters.mGuests91_182Rus = vRow.GuestsCheckedInTurnover;
		Else
			vPage4Area.Parameters.mGuests183Rus = vRow.GuestsCheckedInTurnover;
		EndIf;
	EndDo;
	
	// 4.2.2 Get total number of foreigner checked-in guests per duration
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 0
	|		WHEN GeoSales.Duration < 5
	|			THEN 4
	|		WHEN GeoSales.Duration < 8
	|			THEN 7
	|		WHEN GeoSales.Duration < 15
	|			THEN 14
	|		WHEN GeoSales.Duration < 29
	|			THEN 28
	|		WHEN GeoSales.Duration < 91
	|			THEN 90
	|		WHEN GeoSales.Duration < 183
	|			THEN 182
	|		ELSE 183
	|	END AS DurationType,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0) AS Duration,
	|		SUM(GeoSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND Client.Citizenship <> &qRussia
	|					AND ISNULL(Client.Citizenship.Description, """") <> """") AS GeoSalesTurnovers
	|	
	|	GROUP BY
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0)) AS GeoSales
	|
	|GROUP BY
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 0
	|		WHEN GeoSales.Duration < 5
	|			THEN 4
	|		WHEN GeoSales.Duration < 8
	|			THEN 7
	|		WHEN GeoSales.Duration < 15
	|			THEN 14
	|		WHEN GeoSales.Duration < 29
	|			THEN 28
	|		WHEN GeoSales.Duration < 91
	|			THEN 90
	|		WHEN GeoSales.Duration < 183
	|			THEN 182
	|		ELSE 183
	|	END
	|
	|ORDER BY
	|	DurationType";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qCompany", Company);
	vQryResult = vQry.Execute().Unload();
	
	vPage4Area.Parameters.mGuests0Foreigners = 0;
	vPage4Area.Parameters.mGuests1_4Foreigners = 0;
	vPage4Area.Parameters.mGuests5_7Foreigners = 0;
	vPage4Area.Parameters.mGuests8_14Foreigners = 0;
	vPage4Area.Parameters.mGuests15_28Foreigners = 0;
	vPage4Area.Parameters.mGuests29_90Foreigners = 0;
	vPage4Area.Parameters.mGuests91_182Foreigners = 0;
	vPage4Area.Parameters.mGuests183Foreigners = 0;

	For Each vRow In vQryResult Do
		If vRow.DurationType = 0 Then
			vPage4Area.Parameters.mGuests0Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 4 Then
			vPage4Area.Parameters.mGuests1_4Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 7 Then
			vPage4Area.Parameters.mGuests5_7Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 14 Then
			vPage4Area.Parameters.mGuests8_14Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 28 Then
			vPage4Area.Parameters.mGuests15_28Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 90 Then
			vPage4Area.Parameters.mGuests29_90Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 182 Then
			vPage4Area.Parameters.mGuests91_182Foreigners = vRow.GuestsCheckedInTurnover;
		Else
			vPage4Area.Parameters.mGuests183Foreigners = vRow.GuestsCheckedInTurnover;
		EndIf;
	EndDo;
	
	pSpreadsheet.Put(vPage4Area);
	pSpreadsheet.PutHorizontalPageBreak();
	
	// Page 5
	
	// 7.1 Get total sales
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomSalesTurnovers.RoomRevenueWithoutVATTurnover,
	|	RoomSalesTurnovers.SalesWithoutVATTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			NOT IsCorrection AND Hotel = &qHotel
	|				AND Company = &qCompany
	|				AND (Service IN HIERARCHY (&qIncomeServices)
	|					OR (NOT &qUseServicesList))) AS RoomSalesTurnovers";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vUseServicesList = False;
	vServicesList = New ValueList();
	If ValueIsFilled(TotalIncomeServiceGroup) Then
		If Not TotalIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(TotalIncomeServiceGroup);
		EndIf;
	EndIf;
	vQry.SetParameter("qUseServicesList", vUseServicesList);
	vQry.SetParameter("qIncomeServices", vServicesList);
	vQryResult = vQry.Execute().Unload();

	vTotalIncome = 0;
	vPage5Area.Parameters.mTotalIncome = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vTotalIncome = Round(vRow.SalesWithoutVATTurnover/1000, 1);
		vPage5Area.Parameters.mTotalIncome = vTotalIncome;
	EndIf;
	
	pSpreadsheet.Put(vPage5Area);
	pSpreadsheet.PutHorizontalPageBreak();
EndProcedure // pmGenerate2019

// -----------------------------------------------------------------------------
Procedure pmGenerate2020(pSpreadsheet) Export
	// Clear output spreadsheet
	pSpreadsheet.Clear();
	
	// Choose template
	vTemplate = ThisObject.GetTemplate("Report2020");
	
	// Report pages
	vPage1Area = vTemplate.GetArea("Page1");
	vPage2Area = vTemplate.GetArea("Page2");
	vPage3Area = vTemplate.GetArea("Page3");
	vPage3H1Area = vTemplate.GetArea("Page3H1");
	vPage3H1RowArea = vTemplate.GetArea("Page3H1Row");
	vPage3H2Area = vTemplate.GetArea("Page3H2");
	vPage4Area = vTemplate.GetArea("Page4");
	vPage5Area = vTemplate.GetArea("Page5");
	
	// Page 1
	vPage1Area.Parameters.mPeriodStr = PeriodPresentation(BegOfDay(PeriodFrom), EndOfDay(PeriodTo), cmLocalizationCode());
	vPage1Area.Parameters.mHotelName = TrimAll(Hotel.LegacyName);
	vPage1Area.Parameters.mHotelPostAddress = cmGetAddressPresentation(Hotel.PostAddress);
	vPage1Area.Parameters.mCompanyName = TrimAll(Company.LegacyName);
	vPage1Area.Parameters.mCompanyPostAddress = cmGetAddressPresentation(Company.PostAddress);
	vPage1Area.Parameters.mCompanyOKPOCode = TrimAll(Company.OKPO);
	pSpreadsheet.Put(vPage1Area);
	pSpreadsheet.PutHorizontalPageBreak();
	
	// Page 2
	pSpreadsheet.Put(vPage2Area);
	pSpreadsheet.PutHorizontalPageBreak();
	
	// Page 3
	
	// 3.1 Get total number of rooms/beds per end of period
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInventoryBalance.TotalRoomsBalance AS TotalRoomsBalance,
	|	RoomInventoryBalance.TotalBedsBalance AS TotalBedsBalance
	|FROM
	|	AccumulationRegister.RoomInventory.Balance(
	|			&qPeriodTo,
	|			Hotel = &qHotel
	|				AND (Room.Company = &qCompany
	|					OR Room.Company = &qEmptyCompany)
	|				AND (RoomType.Company = &qCompany
	|					OR RoomType.Company = &qEmptyCompany)) AS RoomInventoryBalance";
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyCompany", Catalogs.Companies.EmptyRef());
	vQryResult = vQry.Execute().Unload();

	vPage3Area.Parameters.mTotalRooms = 0;
	vPage3Area.Parameters.mTotalBeds = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vPage3Area.Parameters.mTotalRooms = vRow.TotalRoomsBalance;
		vPage3Area.Parameters.mTotalBeds = vRow.TotalBedsBalance;
	EndIf;
	
	// 3.2 Get total number of rooms/beds for top room types per end of period
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInventoryBalance.TotalRoomsBalance AS TotalRoomsBalance,
	|	RoomInventoryBalance.TotalBedsBalance AS TotalBedsBalance
	|FROM
	|	AccumulationRegister.RoomInventory.Balance(
	|			&qPeriodTo,
	|			Hotel = &qHotel
	|				AND (&qNoTopRoomTypes
	|					OR NOT &qNoTopRoomTypes
	|						AND RoomType IN HIERARCHY (&qTopRoomTypes))
	|				AND (Room.Company = &qCompany
	|					OR Room.Company = &qEmptyCompany)
	|				AND (RoomType.Company = &qCompany
	|					OR RoomType.Company = &qEmptyCompany)) AS RoomInventoryBalance";
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyCompany", Catalogs.Companies.EmptyRef());
	vQry.SetParameter("qNoTopRoomTypes", Not ValueIsFilled(TopRoomTypes));
	vQry.SetParameter("qTopRoomTypes", TopRoomTypes);
	vQryResult = vQry.Execute().Unload();

	vPage3Area.Parameters.mTotalTopRooms = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vPage3Area.Parameters.mTotalTopRooms = vRow.TotalRoomsBalance;
	EndIf;
	
	// 3.3 Get total number of guest days and number of checked in guests
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SUM(ISNULL(RoomSales.GuestDaysTurnover, 0)) AS GuestDaysTurnover,
	|	SUM(ISNULL(RoomSales.GuestDays18Turnover, 0)) AS GuestDays18Turnover,
	|	SUM(ISNULL(RoomSales.GuestDays55Turnover, 0)) AS GuestDays55Turnover,
	|	SUM(ISNULL(RoomSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover,
	|	SUM(ISNULL(RoomSales.GuestsCheckedIn18Turnover, 0)) AS GuestsCheckedIn18Turnover,
	|	SUM(ISNULL(RoomSales.GuestsCheckedIn55Turnover, 0)) AS GuestsCheckedIn55Turnover
	|FROM
	|	(SELECT
	|		RoomSalesTurnovers.Client AS Client,
	|		RoomSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover,
	|		CASE
	|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND RoomSalesTurnovers.Client.Age < 18
	|				THEN RoomSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays18Turnover,
	|		CASE
	|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND RoomSalesTurnovers.Client.Age >= 55
	|				THEN RoomSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays55Turnover,
	|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
	|		CASE
	|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND RoomSalesTurnovers.Client.Age < 18
	|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn18Turnover,
	|		CASE
	|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND RoomSalesTurnovers.Client.Age >= 55
	|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn55Turnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany) AS RoomSalesTurnovers) AS RoomSales";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyDate", '00010101');
	vQryResult = vQry.Execute().Unload();

	vTotalGuestDays = 0;
	vTotalGuestDays18 = 0;
	vTotalGuestDays55 = 0;
	vTotalGuests = 0;
	vTotalGuests18 = 0;
	vTotalGuests55 = 0;
	vPage3Area.Parameters.mTotalGuestDays = 0;
	vPage3Area.Parameters.mTotalGuestDays18 = 0;
	vPage3Area.Parameters.mTotalGuestDays55 = 0;
	vPage3Area.Parameters.mTotalGuests = 0;
	vPage3Area.Parameters.mTotalGuests18 = 0;
	vPage3Area.Parameters.mTotalGuests55 = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vPage3Area.Parameters.mTotalGuestDays = vRow.GuestDaysTurnover;
		vPage3Area.Parameters.mTotalGuestDays18 = vRow.GuestDays18Turnover;
		vPage3Area.Parameters.mTotalGuestDays55 = vRow.GuestDays55Turnover;
		vPage3Area.Parameters.mTotalGuests = vRow.GuestsCheckedInTurnover;
		vPage3Area.Parameters.mTotalGuests18 = vRow.GuestsCheckedIn18Turnover;
		vPage3Area.Parameters.mTotalGuests55 = vRow.GuestsCheckedIn55Turnover;
		vTotalGuestDays = vRow.GuestDaysTurnover;
		vTotalGuestDays18 = vRow.GuestDays18Turnover;
		vTotalGuestDays55 = vRow.GuestDays55Turnover;
		vTotalGuests = vRow.GuestsCheckedInTurnover;
		vTotalGuests18 = vRow.GuestsCheckedIn18Turnover;
		vTotalGuests55 = vRow.GuestsCheckedIn55Turnover;
	EndIf;
	
	// 3.4 Get total number of guest days and checked-in guests from Russia
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SUM(ISNULL(GeoSales.GuestDaysTurnover, 0)) AS GuestDaysTurnover,
	|	SUM(ISNULL(GeoSales.GuestDays18Turnover, 0)) AS GuestDays18Turnover,
	|	SUM(ISNULL(GeoSales.GuestDays55Turnover, 0)) AS GuestDays55Turnover,
	|	SUM(ISNULL(GeoSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover,
	|	SUM(ISNULL(GeoSales.GuestsCheckedIn18Turnover, 0)) AS GuestsCheckedIn18Turnover,
	|	SUM(ISNULL(GeoSales.GuestsCheckedIn55Turnover, 0)) AS GuestsCheckedIn55Turnover
	|FROM
	|	(SELECT
	|		GeoSalesTurnovers.Client AS Client,
	|		GeoSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age < 18
	|				THEN GeoSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays18Turnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age >= 55
	|				THEN GeoSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays55Turnover,
	|		GeoSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age < 18
	|				THEN GeoSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn18Turnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age >= 55
	|				THEN GeoSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn55Turnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND (Client.Citizenship = &qRussia
	|						OR ISNULL(Client.Citizenship.Description, """") = """")) AS GeoSalesTurnovers) AS GeoSales";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyDate", '00010101');
	vQryResult = vQry.Execute().Unload();

	vRussiaGuestDays = 0;
	vRussiaGuestDays18 = 0;
	vRussiaGuestDays55 = 0;
	vRussiaGuests = 0;
	vRussiaGuests18 = 0;
	vRussiaGuests55 = 0;
	vPage3Area.Parameters.mTotalGuestsRus = 0;
	vPage3Area.Parameters.mTotalGuestsRus18 = 0;
	vPage3Area.Parameters.mTotalGuestsRus55 = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vPage3Area.Parameters.mTotalGuestsRus = vRow.GuestsCheckedInTurnover;
		vPage3Area.Parameters.mTotalGuestsRus18 = vRow.GuestsCheckedIn18Turnover;
		vPage3Area.Parameters.mTotalGuestsRus55 = vRow.GuestsCheckedIn55Turnover;
		vRussiaGuestDays = vRow.GuestDaysTurnover;
		vRussiaGuestDays18 = vRow.GuestDays18Turnover;
		vRussiaGuestDays55 = vRow.GuestDays55Turnover;
		vRussiaGuests = vRow.GuestsCheckedInTurnover;
		vRussiaGuests18 = vRow.GuestsCheckedIn18Turnover;
		vRussiaGuests55 = vRow.GuestsCheckedIn55Turnover;
	EndIf;
	
	// 3.5 Get total number of guest days and checked-in foreigner guests
	If vTotalGuests <> Null And vRussiaGuests <> Null Then
		vPage3Area.Parameters.mTotalGuestsForeigners = vTotalGuests - vRussiaGuests;
		vPage3Area.Parameters.mTotalGuestsForeigners18 = vTotalGuests18 - vRussiaGuests18;
		vPage3Area.Parameters.mTotalGuestsForeigners55 = vTotalGuests55 - vRussiaGuests55;
	Else
		vPage3Area.Parameters.mTotalGuestsForeigners = 0;
		vPage3Area.Parameters.mTotalGuestsForeigners18 = 0;
		vPage3Area.Parameters.mTotalGuestsForeigners55 = 0;
	EndIf;
	
	// 3.6 Get total number of checked-in guests with tour tickets
	vPage3Area.Parameters.mTotalTourTicketGuests = 0;
	vPage3Area.Parameters.mTotalTourTicketGuests18 = 0;
	vPage3Area.Parameters.mTotalTourTicketGuests55 = 0;
	If ValueIsFilled(TourTicketIncomeServiceGroup) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	SUM(ISNULL(RoomSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover,
		|	SUM(ISNULL(RoomSales.GuestsCheckedIn18Turnover, 0)) AS GuestsCheckedIn18Turnover,
		|	SUM(ISNULL(RoomSales.GuestsCheckedIn55Turnover, 0)) AS GuestsCheckedIn55Turnover
		|FROM
		|	(SELECT
		|		RoomSalesTurnovers.Client AS Client,
		|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
		|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					AND RoomSalesTurnovers.Client.Age < 18
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			ELSE 0
		|		END AS GuestsCheckedIn18Turnover,
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
		|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					AND RoomSalesTurnovers.Client.Age >= 55
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			ELSE 0
		|		END AS GuestsCheckedIn55Turnover
		|	FROM
		|		AccumulationRegister.Sales.Turnovers(
		|				&qPeriodFrom,
		|				&qPeriodTo,
		|				Period,
		|				NOT IsCorrection AND Hotel = &qHotel
		|					AND Company = &qCompany
		|					AND (Service IN HIERARCHY (&qTourTicketServices)
		|						OR NOT &qUseServicesList)
		|					) AS RoomSalesTurnovers) AS RoomSales";
		vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qCompany", Company);
		vUseServicesList = False;
		vServicesList = New ValueList();
		If Not TourTicketIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(TourTicketIncomeServiceGroup);
		EndIf;
		vQry.SetParameter("qUseServicesList", vUseServicesList);
		vQry.SetParameter("qTourTicketServices", vServicesList);
		vQry.SetParameter("qEmptyDate", '00010101');
		vQryResult = vQry.Execute().Unload();

		If vQryResult.Count() > 0 Then
			vRow = vQryResult.Get(0);
			vPage3Area.Parameters.mTotalTourTicketGuests = vRow.GuestsCheckedInTurnover;
			vPage3Area.Parameters.mTotalTourTicketGuests18 = vRow.GuestsCheckedIn18Turnover;
			vPage3Area.Parameters.mTotalTourTicketGuests55 = vRow.GuestsCheckedIn55Turnover;
		EndIf;
		
		// The same from russia
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	SUM(ISNULL(RoomSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover,
		|	SUM(ISNULL(RoomSales.GuestsCheckedIn18Turnover, 0)) AS GuestsCheckedIn18Turnover,
		|	SUM(ISNULL(RoomSales.GuestsCheckedIn55Turnover, 0)) AS GuestsCheckedIn55Turnover
		|FROM
		|	(SELECT
		|		RoomSalesTurnovers.Client AS Client,
		|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL
		|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					AND RoomSalesTurnovers.Client.Age < 18
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			ELSE 0
		|		END AS GuestsCheckedIn18Turnover,
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL
		|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					AND RoomSalesTurnovers.Client.Age >= 55
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			ELSE 0
		|		END AS GuestsCheckedIn55Turnover
		|	FROM
		|		AccumulationRegister.Sales.Turnovers(
		|				&qPeriodFrom,
		|				&qPeriodTo,
		|				Period,
		|				NOT IsCorrection
		|					AND Hotel = &qHotel
		|					AND Company = &qCompany
		|					AND (Service IN HIERARCHY (&qTourTicketServices)
		|						OR NOT &qUseServicesList)
		|					AND (Client.Citizenship = &qRussia
		|						OR ISNULL(Client.Citizenship.Description, """") = """")) AS RoomSalesTurnovers) AS RoomSales";
		vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qRussia", RussiaCountry);
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qCompany", Company);
		vUseServicesList = False;
		vServicesList = New ValueList();
		If Not TourTicketIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(TourTicketIncomeServiceGroup);
		EndIf;
		vQry.SetParameter("qUseServicesList", vUseServicesList);
		vQry.SetParameter("qTourTicketServices", vServicesList);
		vQry.SetParameter("qEmptyDate", '00010101');
		vQryResult = vQry.Execute().Unload();

		If vQryResult.Count() > 0 Then
			vRow = vQryResult.Get(0);
			vPage3Area.Parameters.mTotalTourTicketGuestsRus = ?(vRow.GuestsCheckedInTurnover = Null, 0, vRow.GuestsCheckedInTurnover);
			vPage3Area.Parameters.mTotalTourTicketGuestsRus18 = ?(vRow.GuestsCheckedIn18Turnover = Null, 0, vRow.GuestsCheckedIn18Turnover);
			vPage3Area.Parameters.mTotalTourTicketGuestsRus55 = ?(vRow.GuestsCheckedIn55Turnover = Null, 0, vRow.GuestsCheckedIn55Turnover);
			
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners = ?(vPage3Area.Parameters.mTotalTourTicketGuests = Null, 0, vPage3Area.Parameters.mTotalTourTicketGuests) - ?(vRow.GuestsCheckedInTurnover = Null, 0, vRow.GuestsCheckedInTurnover);
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners18 = ?(vPage3Area.Parameters.mTotalTourTicketGuests18 = Null, 0, vPage3Area.Parameters.mTotalTourTicketGuests18) - ?(vRow.GuestsCheckedIn18Turnover = Null, 0, vRow.GuestsCheckedIn18Turnover);
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners55 = ?(vPage3Area.Parameters.mTotalTourTicketGuests55 = Null, 0, vPage3Area.Parameters.mTotalTourTicketGuests55) - ?(vRow.GuestsCheckedIn55Turnover = Null, 0, vRow.GuestsCheckedIn55Turnover);
		Else
			vPage3Area.Parameters.mTotalTourTicketGuestsRus = 0;
			vPage3Area.Parameters.mTotalTourTicketGuestsRus18 = 0;
			vPage3Area.Parameters.mTotalTourTicketGuestsRus55 = 0;
			
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners = 0;
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners18 = 0;
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners55 = 0;
		EndIf;
	EndIf;
	
	pSpreadsheet.Put(vPage3Area);
	
	// Page 3 header Spr. 1
	pSpreadsheet.Put(vPage3H1Area);
	
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ISNULL(GeoSales.Client.Citizenship.Description, """") AS CountryDescription,
	|	ISNULL(GeoSales.Client.Citizenship.Code, 0) AS CountryCode,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			NOT IsCorrection AND Hotel = &qHotel
	|				AND Company = &qCompany
	|				AND Client.Citizenship <> &qRussia
	|				AND ISNULL(Client.Citizenship.Description, """") <> """") AS GeoSales
	|
	|GROUP BY
	|	GeoSales.Client.Citizenship.Description,
	|	GeoSales.Client.Citizenship.Code
	|
	|ORDER BY
	|	GeoSales.Client.Citizenship.Code";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQryResult = vQry.Execute().Unload();
	c = 0;
	While c < vQryResult.Count() Do
		vQryResultLRow = vQryResult.Get(c);
		
		vPage3H1RowArea.Parameters.mCountryL = TrimAll(vQryResultLRow.CountryDescription);
		vPage3H1RowArea.Parameters.mCountryCodeL = TrimAll(vQryResultLRow.CountryCode);
		vPage3H1RowArea.Parameters.mCountryGuestsL = vQryResultLRow.GuestsCheckedInTurnover;
		
		If c < (vQryResult.Count() - 1) Then
			vQryResultRRow = vQryResult.Get(c + 1);
			
			vPage3H1RowArea.Parameters.mCountryR = TrimAll(vQryResultRRow.CountryDescription);
			vPage3H1RowArea.Parameters.mCountryCodeR = TrimAll(vQryResultRRow.CountryCode);
			vPage3H1RowArea.Parameters.mCountryGuestsR = vQryResultRRow.GuestsCheckedInTurnover;
		Else
			vPage3H1RowArea.Parameters.mCountryR = "";
			vPage3H1RowArea.Parameters.mCountryCodeR = "";
			vPage3H1RowArea.Parameters.mCountryGuestsR = 0;
		EndIf;
		
		pSpreadsheet.Put(vPage3H1RowArea);
		
		c = c + 2;
	EndDo;
	
	// Get number of checked in guests by hotel products (Page 3. Spr 2)
	vPage3H2Area.Parameters.mVaucherQuantity = 0;
	vPage3H2Area.Parameters.mVaucher18Quantity = 0;
	vPage3H2Area.Parameters.mVaucher55Quantity = 0;
	
	If ValueIsFilled(VaucherIncomeServiceGroup) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	SUM(AgeSales.VaucherQuantity) AS VaucherQuantity,
		|	SUM(AgeSales.Vaucher18Quantity) AS Vaucher18Quantity,
		|	SUM(AgeSales.Vaucher55Quantity) AS Vaucher55Quantity
		|FROM
		|	(SELECT
		|		RoomSalesTurnovers.Client AS Client,
		|		RoomSalesTurnovers.Client.Age AS ClientAge,
		|		MAX(1) AS VaucherQuantity,
		|		MAX(CASE
		|				WHEN RoomSalesTurnovers.Client.Age < 18
		|						AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					THEN 1
		|				ELSE 0
		|			END) AS Vaucher18Quantity,
		|		MAX(CASE
		|				WHEN RoomSalesTurnovers.Client.Age >= 55
		|					THEN 1
		|				ELSE 0
		|			END) AS Vaucher55Quantity
		|	FROM
		|		AccumulationRegister.Sales.Turnovers(
		|				&qPeriodFrom,
		|				&qPeriodTo,
		|				Period,
		|				NOT IsCorrection AND Hotel = &qHotel
		|					AND Company = &qCompany
		|					AND (Service IN HIERARCHY (&qVaucherServices)
		|						OR NOT &qUseServicesList)) AS RoomSalesTurnovers
		|	
		|	GROUP BY
		|		RoomSalesTurnovers.Client,
		|		RoomSalesTurnovers.Client.Age) AS AgeSales";
		vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qCompany", Company);
		vQry.SetParameter("qEmptyDate", '00010101');
		vUseServicesList = False;
		vServicesList = New ValueList();
		If Not TourTicketIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(VaucherIncomeServiceGroup);
		EndIf;
		vQry.SetParameter("qUseServicesList", vUseServicesList);
		vQry.SetParameter("qVaucherServices", vServicesList);
		vQryResult = vQry.Execute().Unload();

		If vQryResult.Count() > 0 Then
			vRow = vQryResult.Get(0);
			
			vPage3H2Area.Parameters.mVaucherQuantity = vRow.VaucherQuantity;
			vPage3H2Area.Parameters.mVaucher18Quantity = vRow.Vaucher18Quantity;
			vPage3H2Area.Parameters.mVaucher55Quantity = vRow.Vaucher55Quantity;
		EndIf;
	EndIf;
	
	pSpreadsheet.Put(vPage3H2Area);
	
	pSpreadsheet.PutHorizontalPageBreak();
	
	// Page 4
	
	// 4.1.1 Get total number of russian checked-in guests per trip purposes
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qEducation
	|			THEN 4
	|		ELSE 7
	|	END AS TripPurposeType,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		GeoSalesTurnovers.TripPurpose AS TripPurpose,
	|		SUM(GeoSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND (Client.Citizenship = &qRussia
	|						OR ISNULL(Client.Citizenship.Description, """") = """")) AS GeoSalesTurnovers
	|	
	|	GROUP BY
	|		GeoSalesTurnovers.TripPurpose) AS GeoSales
	|
	|GROUP BY
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qEducation
	|			THEN 4
	|		ELSE 7
	|	END
	|
	|ORDER BY
	|	TripPurposeType";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qBusiness", Catalogs.TripPurposes.Business);
	vQry.SetParameter("qCommerce", Catalogs.TripPurposes.Commerce);
	vQry.SetParameter("qOfficial", Catalogs.TripPurposes.Official);
	vQry.SetParameter("qWork", Catalogs.TripPurposes.Work);
	vQry.SetParameter("qCrewman", Catalogs.TripPurposes.Crewman);
	vQry.SetParameter("qHumanitarian", Catalogs.TripPurposes.Humanitarian);
	vQry.SetParameter("qTourism", Catalogs.TripPurposes.Tourism);
	vQry.SetParameter("qPrivate", Catalogs.TripPurposes.Private);
	vQry.SetParameter("qScientific", Catalogs.TripPurposes.Scientific);
	vQry.SetParameter("qEducation", Catalogs.TripPurposes.Study);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyCountry", Catalogs.Countries.EmptyRef());
	vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vQry.SetParameter("qEmptyCountry", Catalogs.Countries.EmptyRef());
	vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vQryResult = vQry.Execute().Unload();
	
	vPage4Area.Parameters.mGuestsTouristsRus = 0;
	vPage4Area.Parameters.mGuestsEducationRus = 0;
	vPage4Area.Parameters.mGuestsBusinessRus = 0;
	vPage4Area.Parameters.mGuestsCureRus = 0;
	vPage4Area.Parameters.mGuestsPilgrimRus = 0;
	vPage4Area.Parameters.mGuestsOtherRus = 0;

	For Each vRow In vQryResult Do
		If vRow.TripPurposeType = 3 Then
			vPage4Area.Parameters.mGuestsTouristsRus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 4 Then
			vPage4Area.Parameters.mGuestsEducationRus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 8 Then
			vPage4Area.Parameters.mGuestsBusinessRus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 5 Then
			vPage4Area.Parameters.mGuestsCureRus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 6 Then
			vPage4Area.Parameters.mGuestsPilgrimRus = vRow.GuestsCheckedInTurnover;
		Else
			vPage4Area.Parameters.mGuestsOtherRus = vRow.GuestsCheckedInTurnover;
		EndIf;
	EndDo;
	
	// 4.1.4 Get total number of checked-in foreigner guests per trip purposes
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qEducation
	|			THEN 4
	|		ELSE 7
	|	END AS TripPurposeType,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		GeoSalesTurnovers.TripPurpose AS TripPurpose,
	|		SUM(GeoSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND Client.Citizenship <> &qRussia
	|					AND ISNULL(Client.Citizenship.Description, """") <> """") AS GeoSalesTurnovers
	|	
	|	GROUP BY
	|		GeoSalesTurnovers.TripPurpose) AS GeoSales
	|
	|GROUP BY
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qEducation
	|			THEN 4
	|		ELSE 7
	|	END
	|
	|ORDER BY
	|	TripPurposeType";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qBusiness", Catalogs.TripPurposes.Business);
	vQry.SetParameter("qCommerce", Catalogs.TripPurposes.Commerce);
	vQry.SetParameter("qOfficial", Catalogs.TripPurposes.Official);
	vQry.SetParameter("qWork", Catalogs.TripPurposes.Work);
	vQry.SetParameter("qCrewman", Catalogs.TripPurposes.Crewman);
	vQry.SetParameter("qHumanitarian", Catalogs.TripPurposes.Humanitarian);
	vQry.SetParameter("qTourism", Catalogs.TripPurposes.Tourism);
	vQry.SetParameter("qPrivate", Catalogs.TripPurposes.Private);
	vQry.SetParameter("qScientific", Catalogs.TripPurposes.Scientific);
	vQry.SetParameter("qEducation", Catalogs.TripPurposes.Study);
	vQry.SetParameter("qCompany", Company);
	vQryResult = vQry.Execute().Unload();
	
	vPage4Area.Parameters.mGuestsTouristsForeigners = 0;
	vPage4Area.Parameters.mGuestsEducationForeigners = 0;
	vPage4Area.Parameters.mGuestsBusinessForeigners = 0;
	vPage4Area.Parameters.mGuestsCureForeigners = 0;
	vPage4Area.Parameters.mGuestsPilgrimForeigners = 0;
	vPage4Area.Parameters.mGuestsOtherForeigners = 0;

	For Each vRow In vQryResult Do
		If vRow.TripPurposeType = 3 Then
			vPage4Area.Parameters.mGuestsTouristsForeigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 4 Then
			vPage4Area.Parameters.mGuestsEducationForeigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 8 Then
			vPage4Area.Parameters.mGuestsBusinessForeigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 5 Then
			vPage4Area.Parameters.mGuestsCureForeigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 6 Then
			vPage4Area.Parameters.mGuestsPilgrimForeigners = vRow.GuestsCheckedInTurnover;
		Else
			vPage4Area.Parameters.mGuestsOtherForeigners = vRow.GuestsCheckedInTurnover;
		EndIf;
	EndDo;
	
	// 4.2.1 Get total number of russian checked-in guests per duration
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 0
	|		WHEN GeoSales.Duration < 5
	|			THEN 4
	|		WHEN GeoSales.Duration < 8
	|			THEN 7
	|		WHEN GeoSales.Duration < 15
	|			THEN 14
	|		WHEN GeoSales.Duration < 29
	|			THEN 28
	|		WHEN GeoSales.Duration < 91
	|			THEN 90
	|		WHEN GeoSales.Duration < 183
	|			THEN 182
	|		ELSE 183
	|	END AS DurationType,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0) AS Duration,
	|		SUM(GeoSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND (Client.Citizenship = &qRussia
	|						OR ISNULL(Client.Citizenship.Description, """") = """")) AS GeoSalesTurnovers
	|	
	|	GROUP BY
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0)) AS GeoSales
	|
	|GROUP BY
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 0
	|		WHEN GeoSales.Duration < 5
	|			THEN 4
	|		WHEN GeoSales.Duration < 8
	|			THEN 7
	|		WHEN GeoSales.Duration < 15
	|			THEN 14
	|		WHEN GeoSales.Duration < 29
	|			THEN 28
	|		WHEN GeoSales.Duration < 91
	|			THEN 90
	|		WHEN GeoSales.Duration < 183
	|			THEN 182
	|		ELSE 183
	|	END
	|
	|ORDER BY
	|	DurationType";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyCountry", Catalogs.Countries.EmptyRef());
	vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vQryResult = vQry.Execute().Unload();
	
	vPage4Area.Parameters.mGuests0Rus = 0;
	vPage4Area.Parameters.mGuests1_4Rus = 0;
	vPage4Area.Parameters.mGuests5_7Rus = 0;
	vPage4Area.Parameters.mGuests8_14Rus = 0;
	vPage4Area.Parameters.mGuests15_28Rus = 0;
	vPage4Area.Parameters.mGuests29_90Rus = 0;
	vPage4Area.Parameters.mGuests91_182Rus = 0;
	vPage4Area.Parameters.mGuests183Rus = 0;

	For Each vRow In vQryResult Do
		If vRow.DurationType = 0 Then
			vPage4Area.Parameters.mGuests0Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 4 Then
			vPage4Area.Parameters.mGuests1_4Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 7 Then
			vPage4Area.Parameters.mGuests5_7Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 14 Then
			vPage4Area.Parameters.mGuests8_14Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 28 Then
			vPage4Area.Parameters.mGuests15_28Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 90 Then
			vPage4Area.Parameters.mGuests29_90Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 182 Then
			vPage4Area.Parameters.mGuests91_182Rus = vRow.GuestsCheckedInTurnover;
		Else
			vPage4Area.Parameters.mGuests183Rus = vRow.GuestsCheckedInTurnover;
		EndIf;
	EndDo;
	
	// 4.2.2 Get total number of foreigner checked-in guests per duration
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 0
	|		WHEN GeoSales.Duration < 5
	|			THEN 4
	|		WHEN GeoSales.Duration < 8
	|			THEN 7
	|		WHEN GeoSales.Duration < 15
	|			THEN 14
	|		WHEN GeoSales.Duration < 29
	|			THEN 28
	|		WHEN GeoSales.Duration < 91
	|			THEN 90
	|		WHEN GeoSales.Duration < 183
	|			THEN 182
	|		ELSE 183
	|	END AS DurationType,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0) AS Duration,
	|		SUM(GeoSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND Client.Citizenship <> &qRussia
	|					AND ISNULL(Client.Citizenship.Description, """") <> """") AS GeoSalesTurnovers
	|	
	|	GROUP BY
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0)) AS GeoSales
	|
	|GROUP BY
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 0
	|		WHEN GeoSales.Duration < 5
	|			THEN 4
	|		WHEN GeoSales.Duration < 8
	|			THEN 7
	|		WHEN GeoSales.Duration < 15
	|			THEN 14
	|		WHEN GeoSales.Duration < 29
	|			THEN 28
	|		WHEN GeoSales.Duration < 91
	|			THEN 90
	|		WHEN GeoSales.Duration < 183
	|			THEN 182
	|		ELSE 183
	|	END
	|
	|ORDER BY
	|	DurationType";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qCompany", Company);
	vQryResult = vQry.Execute().Unload();
	
	vPage4Area.Parameters.mGuests0Foreigners = 0;
	vPage4Area.Parameters.mGuests1_4Foreigners = 0;
	vPage4Area.Parameters.mGuests5_7Foreigners = 0;
	vPage4Area.Parameters.mGuests8_14Foreigners = 0;
	vPage4Area.Parameters.mGuests15_28Foreigners = 0;
	vPage4Area.Parameters.mGuests29_90Foreigners = 0;
	vPage4Area.Parameters.mGuests91_182Foreigners = 0;
	vPage4Area.Parameters.mGuests183Foreigners = 0;

	For Each vRow In vQryResult Do
		If vRow.DurationType = 0 Then
			vPage4Area.Parameters.mGuests0Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 4 Then
			vPage4Area.Parameters.mGuests1_4Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 7 Then
			vPage4Area.Parameters.mGuests5_7Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 14 Then
			vPage4Area.Parameters.mGuests8_14Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 28 Then
			vPage4Area.Parameters.mGuests15_28Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 90 Then
			vPage4Area.Parameters.mGuests29_90Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 182 Then
			vPage4Area.Parameters.mGuests91_182Foreigners = vRow.GuestsCheckedInTurnover;
		Else
			vPage4Area.Parameters.mGuests183Foreigners = vRow.GuestsCheckedInTurnover;
		EndIf;
	EndDo;
	
	pSpreadsheet.Put(vPage4Area);
	pSpreadsheet.PutHorizontalPageBreak();
	
	// Page 5
	
	// 7.1 Get total sales
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomSalesTurnovers.RoomRevenueWithoutVATTurnover,
	|	RoomSalesTurnovers.SalesWithoutVATTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			NOT IsCorrection AND Hotel = &qHotel
	|				AND Company = &qCompany
	|				AND (Service IN HIERARCHY (&qIncomeServices)
	|					OR (NOT &qUseServicesList))) AS RoomSalesTurnovers";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vUseServicesList = False;
	vServicesList = New ValueList();
	If ValueIsFilled(TotalIncomeServiceGroup) Then
		If Not TotalIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(TotalIncomeServiceGroup);
		EndIf;
	EndIf;
	vQry.SetParameter("qUseServicesList", vUseServicesList);
	vQry.SetParameter("qIncomeServices", vServicesList);
	vQryResult = vQry.Execute().Unload();

	vTotalIncome = 0;
	vPage5Area.Parameters.mTotalIncome = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vTotalIncome = Round(vRow.SalesWithoutVATTurnover/1000, 1);
		vPage5Area.Parameters.mTotalIncome = vTotalIncome;
	EndIf;
	
	pSpreadsheet.Put(vPage5Area);
	pSpreadsheet.PutHorizontalPageBreak();
EndProcedure // pmGenerate2020

// -----------------------------------------------------------------------------
Procedure pmGenerate2021(pSpreadsheet) Export
	// Clear output spreadsheet
	pSpreadsheet.Clear();
	
	// Choose template
	vTemplate = ThisObject.GetTemplate("Report2021");
	
	// Report pages
	vPage1Area = vTemplate.GetArea("Page1");
	vPage2Area = vTemplate.GetArea("Page2");
	vPage3Area = vTemplate.GetArea("Page3");
	vPage3H1Area = vTemplate.GetArea("Page3H1");
	vPage3H1RowArea = vTemplate.GetArea("Page3H1Row");
	vPage3H2Area = vTemplate.GetArea("Page3H2");
	vPage4Area = vTemplate.GetArea("Page4");
	vPage5Area = vTemplate.GetArea("Page5");
	
	// Page 1
	vPage1Area.Parameters.mPeriodStr = PeriodPresentation(BegOfDay(PeriodFrom), EndOfDay(PeriodTo), cmLocalizationCode());
	vPage1Area.Parameters.mHotelName = TrimAll(Hotel.LegacyName);
	vPage1Area.Parameters.mHotelPostAddress = cmGetAddressPresentation(Hotel.PostAddress);
	vPage1Area.Parameters.mCompanyName = TrimAll(Company.LegacyName);
	vPage1Area.Parameters.mCompanyPostAddress = cmGetAddressPresentation(Company.PostAddress);
	vPage1Area.Parameters.mCompanyOKPOCode = TrimAll(Company.OKPO);
	pSpreadsheet.Put(vPage1Area);
	pSpreadsheet.PutHorizontalPageBreak();
	
	// Page 2
	pSpreadsheet.Put(vPage2Area);
	pSpreadsheet.PutHorizontalPageBreak();
	
	// Page 3
	
	// 3.1 Get total number of rooms/beds per end of period
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInventoryBalance.TotalRoomsBalance AS TotalRoomsBalance,
	|	RoomInventoryBalance.TotalBedsBalance AS TotalBedsBalance
	|FROM
	|	AccumulationRegister.RoomInventory.Balance(
	|			&qPeriodTo,
	|			Hotel = &qHotel
	|				AND (Room.Company = &qCompany
	|					OR Room.Company = &qEmptyCompany)
	|				AND (RoomType.Company = &qCompany
	|					OR RoomType.Company = &qEmptyCompany)) AS RoomInventoryBalance";
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyCompany", Catalogs.Companies.EmptyRef());
	vQryResult = vQry.Execute().Unload();

	vPage3Area.Parameters.mTotalRooms = 0;
	vPage3Area.Parameters.mTotalBeds = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vPage3Area.Parameters.mTotalRooms = vRow.TotalRoomsBalance;
		vPage3Area.Parameters.mTotalBeds = vRow.TotalBedsBalance;
	EndIf;
	
	// 3.2 Get total number of rooms/beds for top room types per end of period
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInventoryBalance.TotalRoomsBalance AS TotalRoomsBalance,
	|	RoomInventoryBalance.TotalBedsBalance AS TotalBedsBalance
	|FROM
	|	AccumulationRegister.RoomInventory.Balance(
	|			&qPeriodTo,
	|			Hotel = &qHotel
	|				AND (&qNoTopRoomTypes
	|					OR NOT &qNoTopRoomTypes
	|						AND RoomType IN HIERARCHY (&qTopRoomTypes))
	|				AND (Room.Company = &qCompany
	|					OR Room.Company = &qEmptyCompany)
	|				AND (RoomType.Company = &qCompany
	|					OR RoomType.Company = &qEmptyCompany)) AS RoomInventoryBalance";
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyCompany", Catalogs.Companies.EmptyRef());
	vQry.SetParameter("qNoTopRoomTypes", Not ValueIsFilled(TopRoomTypes));
	vQry.SetParameter("qTopRoomTypes", TopRoomTypes);
	vQryResult = vQry.Execute().Unload();

	vPage3Area.Parameters.mTotalTopRooms = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vPage3Area.Parameters.mTotalTopRooms = vRow.TotalRoomsBalance;
	EndIf;
	
	// 3.3 Get total number of guest days and number of checked in guests
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SUM(ISNULL(RoomSales.GuestDaysTurnover, 0)) AS GuestDaysTurnover,
	|	SUM(ISNULL(RoomSales.GuestDays18Turnover, 0)) AS GuestDays18Turnover,
	|	SUM(ISNULL(RoomSales.GuestDays55Turnover, 0)) AS GuestDays55Turnover,
	|	SUM(ISNULL(RoomSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover,
	|	SUM(ISNULL(RoomSales.GuestsCheckedIn18Turnover, 0)) AS GuestsCheckedIn18Turnover,
	|	SUM(ISNULL(RoomSales.GuestsCheckedIn55Turnover, 0)) AS GuestsCheckedIn55Turnover
	|FROM
	|	(SELECT
	|		RoomSalesTurnovers.Client AS Client,
	|		RoomSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover,
	|		CASE
	|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND RoomSalesTurnovers.Client.Age < 18
	|				THEN RoomSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays18Turnover,
	|		CASE
	|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND RoomSalesTurnovers.Client.Age >= 55
	|				THEN RoomSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays55Turnover,
	|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
	|		CASE
	|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND RoomSalesTurnovers.Client.Age < 18
	|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn18Turnover,
	|		CASE
	|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND RoomSalesTurnovers.Client.Age >= 55
	|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn55Turnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany) AS RoomSalesTurnovers) AS RoomSales";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyDate", '00010101');
	vQryResult = vQry.Execute().Unload();

	vTotalGuestDays = 0;
	vTotalGuestDays18 = 0;
	vTotalGuestDays55 = 0;
	vTotalGuests = 0;
	vTotalGuests18 = 0;
	vTotalGuests55 = 0;
	vPage3Area.Parameters.mTotalGuestDays = 0;
	vPage3Area.Parameters.mTotalGuestDays18 = 0;
	vPage3Area.Parameters.mTotalGuestDays55 = 0;
	vPage3Area.Parameters.mTotalGuests = 0;
	vPage3Area.Parameters.mTotalGuests18 = 0;
	vPage3Area.Parameters.mTotalGuests55 = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vPage3Area.Parameters.mTotalGuestDays = vRow.GuestDaysTurnover;
		vPage3Area.Parameters.mTotalGuestDays18 = vRow.GuestDays18Turnover;
		vPage3Area.Parameters.mTotalGuestDays55 = vRow.GuestDays55Turnover;
		vPage3Area.Parameters.mTotalGuests = vRow.GuestsCheckedInTurnover;
		vPage3Area.Parameters.mTotalGuests18 = vRow.GuestsCheckedIn18Turnover;
		vPage3Area.Parameters.mTotalGuests55 = vRow.GuestsCheckedIn55Turnover;
		vTotalGuestDays = vRow.GuestDaysTurnover;
		vTotalGuestDays18 = vRow.GuestDays18Turnover;
		vTotalGuestDays55 = vRow.GuestDays55Turnover;
		vTotalGuests = vRow.GuestsCheckedInTurnover;
		vTotalGuests18 = vRow.GuestsCheckedIn18Turnover;
		vTotalGuests55 = vRow.GuestsCheckedIn55Turnover;
	EndIf;
	
	// 3.4 Get total number of guest days and checked-in guests from Russia
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SUM(ISNULL(GeoSales.GuestDaysTurnover, 0)) AS GuestDaysTurnover,
	|	SUM(ISNULL(GeoSales.GuestDays18Turnover, 0)) AS GuestDays18Turnover,
	|	SUM(ISNULL(GeoSales.GuestDays55Turnover, 0)) AS GuestDays55Turnover,
	|	SUM(ISNULL(GeoSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover,
	|	SUM(ISNULL(GeoSales.GuestsCheckedIn18Turnover, 0)) AS GuestsCheckedIn18Turnover,
	|	SUM(ISNULL(GeoSales.GuestsCheckedIn55Turnover, 0)) AS GuestsCheckedIn55Turnover
	|FROM
	|	(SELECT
	|		GeoSalesTurnovers.Client AS Client,
	|		GeoSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age < 18
	|				THEN GeoSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays18Turnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age >= 55
	|				THEN GeoSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays55Turnover,
	|		GeoSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age < 18
	|				THEN GeoSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn18Turnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age >= 55
	|				THEN GeoSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn55Turnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND (Client.Citizenship = &qRussia
	|						OR ISNULL(Client.Citizenship.Description, """") = """")) AS GeoSalesTurnovers) AS GeoSales";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyDate", '00010101');
	vQryResult = vQry.Execute().Unload();

	vRussiaGuestDays = 0;
	vRussiaGuestDays18 = 0;
	vRussiaGuestDays55 = 0;
	vRussiaGuests = 0;
	vRussiaGuests18 = 0;
	vRussiaGuests55 = 0;
	vPage3Area.Parameters.mTotalGuestDaysRus = 0;
	vPage3Area.Parameters.mTotalGuestDaysRus18 = 0;
	vPage3Area.Parameters.mTotalGuestDaysRus55 = 0;
	vPage3Area.Parameters.mTotalGuestsRus = 0;
	vPage3Area.Parameters.mTotalGuestsRus18 = 0;
	vPage3Area.Parameters.mTotalGuestsRus55 = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vPage3Area.Parameters.mTotalGuestDaysRus = vRow.GuestDaysTurnover;
		vPage3Area.Parameters.mTotalGuestDaysRus18 = vRow.GuestDays18Turnover;
		vPage3Area.Parameters.mTotalGuestDaysRus55 = vRow.GuestDays55Turnover;
		vPage3Area.Parameters.mTotalGuestsRus = vRow.GuestsCheckedInTurnover;
		vPage3Area.Parameters.mTotalGuestsRus18 = vRow.GuestsCheckedIn18Turnover;
		vPage3Area.Parameters.mTotalGuestsRus55 = vRow.GuestsCheckedIn55Turnover;
		vRussiaGuestDays = vRow.GuestDaysTurnover;
		vRussiaGuestDays18 = vRow.GuestDays18Turnover;
		vRussiaGuestDays55 = vRow.GuestDays55Turnover;
		vRussiaGuests = vRow.GuestsCheckedInTurnover;
		vRussiaGuests18 = vRow.GuestsCheckedIn18Turnover;
		vRussiaGuests55 = vRow.GuestsCheckedIn55Turnover;
	EndIf;
	
	// 3.5 Get total number of guest days and checked-in foreigner guests
	If vTotalGuests <> Null And vRussiaGuests <> Null Then
		vPage3Area.Parameters.mTotalGuestDaysForeigners = vTotalGuestDays - vRussiaGuestDays;
		vPage3Area.Parameters.mTotalGuestDaysForeigners18 = vTotalGuestDays18 - vRussiaGuestDays18;
		vPage3Area.Parameters.mTotalGuestDaysForeigners55 = vTotalGuestDays55 - vRussiaGuestDays55;
		vPage3Area.Parameters.mTotalGuestsForeigners = vTotalGuests - vRussiaGuests;
		vPage3Area.Parameters.mTotalGuestsForeigners18 = vTotalGuests18 - vRussiaGuests18;
		vPage3Area.Parameters.mTotalGuestsForeigners55 = vTotalGuests55 - vRussiaGuests55;
	Else
		vPage3Area.Parameters.mTotalGuestDaysForeigners = 0;
		vPage3Area.Parameters.mTotalGuestDaysForeigners18 = 0;
		vPage3Area.Parameters.mTotalGuestDaysForeigners55 = 0;
		vPage3Area.Parameters.mTotalGuestsForeigners = 0;
		vPage3Area.Parameters.mTotalGuestsForeigners18 = 0;
		vPage3Area.Parameters.mTotalGuestsForeigners55 = 0;
	EndIf;
	
	// 3.6 Get total number of checked-in guests with tour tickets
	vPage3Area.Parameters.mTotalTourTicketGuests = 0;
	vPage3Area.Parameters.mTotalTourTicketGuests18 = 0;
	vPage3Area.Parameters.mTotalTourTicketGuests55 = 0;
	If ValueIsFilled(TourTicketIncomeServiceGroup) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	SUM(ISNULL(RoomSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover,
		|	SUM(ISNULL(RoomSales.GuestsCheckedIn18Turnover, 0)) AS GuestsCheckedIn18Turnover,
		|	SUM(ISNULL(RoomSales.GuestsCheckedIn55Turnover, 0)) AS GuestsCheckedIn55Turnover
		|FROM
		|	(SELECT
		|		RoomSalesTurnovers.Client AS Client,
		|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
		|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					AND RoomSalesTurnovers.Client.Age < 18
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			ELSE 0
		|		END AS GuestsCheckedIn18Turnover,
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
		|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					AND RoomSalesTurnovers.Client.Age >= 55
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			ELSE 0
		|		END AS GuestsCheckedIn55Turnover
		|	FROM
		|		AccumulationRegister.Sales.Turnovers(
		|				&qPeriodFrom,
		|				&qPeriodTo,
		|				Period,
		|				NOT IsCorrection AND Hotel = &qHotel
		|					AND Company = &qCompany
		|					AND (Service IN HIERARCHY (&qTourTicketServices)
		|						OR NOT &qUseServicesList)
		|					) AS RoomSalesTurnovers) AS RoomSales";
		vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qCompany", Company);
		vUseServicesList = False;
		vServicesList = New ValueList();
		If Not TourTicketIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(TourTicketIncomeServiceGroup);
		EndIf;
		vQry.SetParameter("qUseServicesList", vUseServicesList);
		vQry.SetParameter("qTourTicketServices", vServicesList);
		vQry.SetParameter("qEmptyDate", '00010101');
		vQryResult = vQry.Execute().Unload();

		If vQryResult.Count() > 0 Then
			vRow = vQryResult.Get(0);
			
			vPage3Area.Parameters.mTotalTourTicketGuests = vRow.GuestsCheckedInTurnover;
			vPage3Area.Parameters.mTotalTourTicketGuests18 = vRow.GuestsCheckedIn18Turnover;
			vPage3Area.Parameters.mTotalTourTicketGuests55 = vRow.GuestsCheckedIn55Turnover;
		EndIf;
		
		// The same from russia
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	SUM(ISNULL(RoomSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover,
		|	SUM(ISNULL(RoomSales.GuestsCheckedIn18Turnover, 0)) AS GuestsCheckedIn18Turnover,
		|	SUM(ISNULL(RoomSales.GuestsCheckedIn55Turnover, 0)) AS GuestsCheckedIn55Turnover
		|FROM
		|	(SELECT
		|		RoomSalesTurnovers.Client AS Client,
		|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL
		|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					AND RoomSalesTurnovers.Client.Age < 18
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			ELSE 0
		|		END AS GuestsCheckedIn18Turnover,
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL
		|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					AND RoomSalesTurnovers.Client.Age >= 55
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			ELSE 0
		|		END AS GuestsCheckedIn55Turnover
		|	FROM
		|		AccumulationRegister.Sales.Turnovers(
		|				&qPeriodFrom,
		|				&qPeriodTo,
		|				Period,
		|				NOT IsCorrection
		|					AND Hotel = &qHotel
		|					AND Company = &qCompany
		|					AND (Service IN HIERARCHY (&qTourTicketServices)
		|						OR NOT &qUseServicesList)
		|					AND (Client.Citizenship = &qRussia
		|						OR ISNULL(Client.Citizenship.Description, """") = """")) AS RoomSalesTurnovers) AS RoomSales";
		vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qRussia", RussiaCountry);
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qCompany", Company);
		vUseServicesList = False;
		vServicesList = New ValueList();
		If Not TourTicketIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(TourTicketIncomeServiceGroup);
		EndIf;
		vQry.SetParameter("qUseServicesList", vUseServicesList);
		vQry.SetParameter("qTourTicketServices", vServicesList);
		vQry.SetParameter("qEmptyDate", '00010101');
		vQryResult = vQry.Execute().Unload();

		If vQryResult.Count() > 0 Then
			vRow = vQryResult.Get(0);
			vPage3Area.Parameters.mTotalTourTicketGuestsRus = ?(vRow.GuestsCheckedInTurnover = Null, 0, vRow.GuestsCheckedInTurnover);
			vPage3Area.Parameters.mTotalTourTicketGuestsRus18 = ?(vRow.GuestsCheckedIn18Turnover = Null, 0, vRow.GuestsCheckedIn18Turnover);
			vPage3Area.Parameters.mTotalTourTicketGuestsRus55 = ?(vRow.GuestsCheckedIn55Turnover = Null, 0, vRow.GuestsCheckedIn55Turnover);
			
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners = ?(vPage3Area.Parameters.mTotalTourTicketGuests = Null, 0, vPage3Area.Parameters.mTotalTourTicketGuests) - ?(vRow.GuestsCheckedInTurnover = Null, 0, vRow.GuestsCheckedInTurnover);
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners18 = ?(vPage3Area.Parameters.mTotalTourTicketGuests18 = Null, 0, vPage3Area.Parameters.mTotalTourTicketGuests18) - ?(vRow.GuestsCheckedIn18Turnover = Null, 0, vRow.GuestsCheckedIn18Turnover);
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners55 = ?(vPage3Area.Parameters.mTotalTourTicketGuests55 = Null, 0, vPage3Area.Parameters.mTotalTourTicketGuests55) - ?(vRow.GuestsCheckedIn55Turnover = Null, 0, vRow.GuestsCheckedIn55Turnover);
		Else
			vPage3Area.Parameters.mTotalTourTicketGuestsRus = 0;
			vPage3Area.Parameters.mTotalTourTicketGuestsRus18 = 0;
			vPage3Area.Parameters.mTotalTourTicketGuestsRus55 = 0;
			
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners = 0;
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners18 = 0;
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners55 = 0;
		EndIf;
	EndIf;
	
	pSpreadsheet.Put(vPage3Area);
	
	// Page 3 header Spr. 1
	pSpreadsheet.Put(vPage3H1Area);
	
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ISNULL(GeoSales.Client.Citizenship.Description, """") AS CountryDescription,
	|	ISNULL(GeoSales.Client.Citizenship.Code, 0) AS CountryCode,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			NOT IsCorrection AND Hotel = &qHotel
	|				AND Company = &qCompany
	|				AND Client.Citizenship <> &qRussia
	|				AND ISNULL(Client.Citizenship.Description, """") <> """") AS GeoSales
	|
	|GROUP BY
	|	GeoSales.Client.Citizenship.Description,
	|	GeoSales.Client.Citizenship.Code
	|
	|ORDER BY
	|	GeoSales.Client.Citizenship.Code";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQryResult = vQry.Execute().Unload();
	c = 0;
	While c < vQryResult.Count() Do
		vQryResultLRow = vQryResult.Get(c);
		
		vPage3H1RowArea.Parameters.mCountryL = TrimAll(vQryResultLRow.CountryDescription);
		vPage3H1RowArea.Parameters.mCountryCodeL = TrimAll(vQryResultLRow.CountryCode);
		vPage3H1RowArea.Parameters.mCountryGuestsL = vQryResultLRow.GuestsCheckedInTurnover;
		
		If c < (vQryResult.Count() - 1) Then
			vQryResultRRow = vQryResult.Get(c + 1);
			
			vPage3H1RowArea.Parameters.mCountryR = TrimAll(vQryResultRRow.CountryDescription);
			vPage3H1RowArea.Parameters.mCountryCodeR = TrimAll(vQryResultRRow.CountryCode);
			vPage3H1RowArea.Parameters.mCountryGuestsR = vQryResultRRow.GuestsCheckedInTurnover;
		Else
			vPage3H1RowArea.Parameters.mCountryR = "";
			vPage3H1RowArea.Parameters.mCountryCodeR = "";
			vPage3H1RowArea.Parameters.mCountryGuestsR = 0;
		EndIf;
		
		pSpreadsheet.Put(vPage3H1RowArea);
		
		c = c + 2;
	EndDo;
	
	// Get number of checked in guests by hotel products (Page 3. Spr 2)
	vPage3H2Area.Parameters.mVaucherQuantity = 0;
	vPage3H2Area.Parameters.mVaucher18Quantity = 0;
	vPage3H2Area.Parameters.mVaucher55Quantity = 0;
	
	If ValueIsFilled(VaucherIncomeServiceGroup) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	SUM(AgeSales.VaucherQuantity) AS VaucherQuantity,
		|	SUM(AgeSales.Vaucher18Quantity) AS Vaucher18Quantity,
		|	SUM(AgeSales.Vaucher55Quantity) AS Vaucher55Quantity
		|FROM
		|	(SELECT
		|		RoomSalesTurnovers.Client AS Client,
		|		RoomSalesTurnovers.Client.Age AS ClientAge,
		|		MAX(1) AS VaucherQuantity,
		|		MAX(CASE
		|				WHEN RoomSalesTurnovers.Client.Age < 18
		|						AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					THEN 1
		|				ELSE 0
		|			END) AS Vaucher18Quantity,
		|		MAX(CASE
		|				WHEN RoomSalesTurnovers.Client.Age >= 55
		|					THEN 1
		|				ELSE 0
		|			END) AS Vaucher55Quantity
		|	FROM
		|		AccumulationRegister.Sales.Turnovers(
		|				&qPeriodFrom,
		|				&qPeriodTo,
		|				Period,
		|				NOT IsCorrection AND Hotel = &qHotel
		|					AND Company = &qCompany
		|					AND (Service IN HIERARCHY (&qVaucherServices)
		|						OR NOT &qUseServicesList)) AS RoomSalesTurnovers
		|	
		|	GROUP BY
		|		RoomSalesTurnovers.Client,
		|		RoomSalesTurnovers.Client.Age) AS AgeSales";
		vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qCompany", Company);
		vQry.SetParameter("qEmptyDate", '00010101');
		vUseServicesList = False;
		vServicesList = New ValueList();
		If Not TourTicketIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(VaucherIncomeServiceGroup);
		EndIf;
		vQry.SetParameter("qUseServicesList", vUseServicesList);
		vQry.SetParameter("qVaucherServices", vServicesList);
		vQryResult = vQry.Execute().Unload();

		If vQryResult.Count() > 0 Then
			vRow = vQryResult.Get(0);
			
			vPage3H2Area.Parameters.mVaucherQuantity = vRow.VaucherQuantity;
			vPage3H2Area.Parameters.mVaucher18Quantity = vRow.Vaucher18Quantity;
			vPage3H2Area.Parameters.mVaucher55Quantity = vRow.Vaucher55Quantity;
		EndIf;
	EndIf;
	
	pSpreadsheet.Put(vPage3H2Area);
	
	pSpreadsheet.PutHorizontalPageBreak();
	
	// Page 4
	
	// 4.1.1 Get total number of russian checked-in guests per trip purposes
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qStudy
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qOther
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTransit
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qRecreation
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qPilgrims
	|			THEN 4
	|		WHEN GeoSales.TripPurpose = &qShopping
	|			THEN 5
	|		ELSE 5
	|	END AS TripPurposeType,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		GeoSalesTurnovers.TripPurpose AS TripPurpose,
	|		SUM(GeoSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND (Client.Citizenship = &qRussia
	|						OR ISNULL(Client.Citizenship.Description, """") = """")) AS GeoSalesTurnovers
	|	
	|	GROUP BY
	|		GeoSalesTurnovers.TripPurpose) AS GeoSales
	|
	|GROUP BY
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qStudy
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qOther
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTransit
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qRecreation
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qPilgrims
	|			THEN 4
	|		WHEN GeoSales.TripPurpose = &qShopping
	|			THEN 5
	|		ELSE 5
	|	END
	|
	|ORDER BY
	|	TripPurposeType";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qBusiness", Catalogs.TripPurposes.Business);
	vQry.SetParameter("qCommerce", Catalogs.TripPurposes.Commerce);
	vQry.SetParameter("qOfficial", Catalogs.TripPurposes.Official);
	vQry.SetParameter("qWork", Catalogs.TripPurposes.Work);
	vQry.SetParameter("qCrewman", Catalogs.TripPurposes.Crewman);
	vQry.SetParameter("qHumanitarian", Catalogs.TripPurposes.Humanitarian);
	vQry.SetParameter("qTourism", Catalogs.TripPurposes.Tourism);
	vQry.SetParameter("qPrivate", Catalogs.TripPurposes.Private);
	vQry.SetParameter("qScientific", Catalogs.TripPurposes.Scientific);
	vQry.SetParameter("qStudy", Catalogs.TripPurposes.Study);
	vQry.SetParameter("qRecreation", Catalogs.TripPurposes.Recreation);
	vQry.SetParameter("qShopping", Catalogs.TripPurposes.Shopping);
	vQry.SetParameter("qPilgrims", Catalogs.TripPurposes.Pilgrims);
	vQry.SetParameter("qTransit", Catalogs.TripPurposes.Transit);
	vQry.SetParameter("qOther", Catalogs.TripPurposes.Other);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyCountry", Catalogs.Countries.EmptyRef());
	vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vQry.SetParameter("qEmptyCountry", Catalogs.Countries.EmptyRef());
	vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vQryResult = vQry.Execute().Unload();
	
	vPage4Area.Parameters.mGuestsTouristsRus = 0;
	vPage4Area.Parameters.mGuestsEducationRus = 0;
	vPage4Area.Parameters.mGuestsBusinessRus = 0;
	vPage4Area.Parameters.mGuestsCureRus = 0;
	vPage4Area.Parameters.mGuestsPilgrimRus = 0;
	vPage4Area.Parameters.mGuestsOtherRus = 0;

	For Each vRow In vQryResult Do
		If vRow.TripPurposeType = 1 Then
			vPage4Area.Parameters.mGuestsTouristsRus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 2 Then
			vPage4Area.Parameters.mGuestsEducationRus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 6 Then
			vPage4Area.Parameters.mGuestsBusinessRus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 3 Then
			vPage4Area.Parameters.mGuestsCureRus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 4 Then
			vPage4Area.Parameters.mGuestsPilgrimRus = vRow.GuestsCheckedInTurnover;
		Else
			vPage4Area.Parameters.mGuestsOtherRus = vRow.GuestsCheckedInTurnover;
		EndIf;
	EndDo;
	
	// 4.1.4 Get total number of checked-in foreigner guests per trip purposes
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qStudy
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qOther
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTransit
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qRecreation
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qPilgrims
	|			THEN 4
	|		WHEN GeoSales.TripPurpose = &qShopping
	|			THEN 5
	|		ELSE 5
	|	END AS TripPurposeType,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		GeoSalesTurnovers.TripPurpose AS TripPurpose,
	|		SUM(GeoSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND Client.Citizenship <> &qRussia
	|					AND ISNULL(Client.Citizenship.Description, """") <> """") AS GeoSalesTurnovers
	|	
	|	GROUP BY
	|		GeoSalesTurnovers.TripPurpose) AS GeoSales
	|
	|GROUP BY
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qStudy
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qOther
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTransit
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qRecreation
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qPilgrims
	|			THEN 4
	|		WHEN GeoSales.TripPurpose = &qShopping
	|			THEN 5
	|		ELSE 5
	|	END
	|
	|ORDER BY
	|	TripPurposeType";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qBusiness", Catalogs.TripPurposes.Business);
	vQry.SetParameter("qCommerce", Catalogs.TripPurposes.Commerce);
	vQry.SetParameter("qOfficial", Catalogs.TripPurposes.Official);
	vQry.SetParameter("qWork", Catalogs.TripPurposes.Work);
	vQry.SetParameter("qCrewman", Catalogs.TripPurposes.Crewman);
	vQry.SetParameter("qHumanitarian", Catalogs.TripPurposes.Humanitarian);
	vQry.SetParameter("qTourism", Catalogs.TripPurposes.Tourism);
	vQry.SetParameter("qPrivate", Catalogs.TripPurposes.Private);
	vQry.SetParameter("qScientific", Catalogs.TripPurposes.Scientific);
	vQry.SetParameter("qStudy", Catalogs.TripPurposes.Study);
	vQry.SetParameter("qRecreation", Catalogs.TripPurposes.Recreation);
	vQry.SetParameter("qShopping", Catalogs.TripPurposes.Shopping);
	vQry.SetParameter("qPilgrims", Catalogs.TripPurposes.Pilgrims);
	vQry.SetParameter("qTransit", Catalogs.TripPurposes.Transit);
	vQry.SetParameter("qOther", Catalogs.TripPurposes.Other);
	vQry.SetParameter("qCompany", Company);
	vQryResult = vQry.Execute().Unload();
	
	vPage4Area.Parameters.mGuestsTouristsForeigners = 0;
	vPage4Area.Parameters.mGuestsEducationForeigners = 0;
	vPage4Area.Parameters.mGuestsBusinessForeigners = 0;
	vPage4Area.Parameters.mGuestsCureForeigners = 0;
	vPage4Area.Parameters.mGuestsPilgrimForeigners = 0;
	vPage4Area.Parameters.mGuestsOtherForeigners = 0;

	For Each vRow In vQryResult Do
		If vRow.TripPurposeType = 1 Then
			vPage4Area.Parameters.mGuestsTouristsForeigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 2 Then
			vPage4Area.Parameters.mGuestsEducationForeigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 6 Then
			vPage4Area.Parameters.mGuestsBusinessForeigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 3 Then
			vPage4Area.Parameters.mGuestsCureForeigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 4 Then
			vPage4Area.Parameters.mGuestsPilgrimForeigners = vRow.GuestsCheckedInTurnover;
		Else
			vPage4Area.Parameters.mGuestsOtherForeigners = vRow.GuestsCheckedInTurnover;
		EndIf;
	EndDo;
	
	// 4.2.1 Get total number of russian checked-in guests per duration
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 0
	|		WHEN GeoSales.Duration < 5
	|			THEN 4
	|		WHEN GeoSales.Duration < 8
	|			THEN 7
	|		WHEN GeoSales.Duration < 15
	|			THEN 14
	|		WHEN GeoSales.Duration < 29
	|			THEN 28
	|		WHEN GeoSales.Duration < 91
	|			THEN 90
	|		WHEN GeoSales.Duration < 183
	|			THEN 182
	|		ELSE 183
	|	END AS DurationType,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0) AS Duration,
	|		SUM(GeoSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND (Client.Citizenship = &qRussia
	|						OR ISNULL(Client.Citizenship.Description, """") = """")) AS GeoSalesTurnovers
	|	
	|	GROUP BY
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0)) AS GeoSales
	|
	|GROUP BY
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 0
	|		WHEN GeoSales.Duration < 5
	|			THEN 4
	|		WHEN GeoSales.Duration < 8
	|			THEN 7
	|		WHEN GeoSales.Duration < 15
	|			THEN 14
	|		WHEN GeoSales.Duration < 29
	|			THEN 28
	|		WHEN GeoSales.Duration < 91
	|			THEN 90
	|		WHEN GeoSales.Duration < 183
	|			THEN 182
	|		ELSE 183
	|	END
	|
	|ORDER BY
	|	DurationType";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyCountry", Catalogs.Countries.EmptyRef());
	vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vQryResult = vQry.Execute().Unload();
	
	vPage4Area.Parameters.mGuests0Rus = 0;
	vPage4Area.Parameters.mGuests1_4Rus = 0;
	vPage4Area.Parameters.mGuests5_7Rus = 0;
	vPage4Area.Parameters.mGuests8_14Rus = 0;
	vPage4Area.Parameters.mGuests15_28Rus = 0;
	vPage4Area.Parameters.mGuests29_90Rus = 0;
	vPage4Area.Parameters.mGuests91_182Rus = 0;
	vPage4Area.Parameters.mGuests183Rus = 0;

	For Each vRow In vQryResult Do
		If vRow.DurationType = 0 Then
			vPage4Area.Parameters.mGuests0Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 4 Then
			vPage4Area.Parameters.mGuests1_4Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 7 Then
			vPage4Area.Parameters.mGuests5_7Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 14 Then
			vPage4Area.Parameters.mGuests8_14Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 28 Then
			vPage4Area.Parameters.mGuests15_28Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 90 Then
			vPage4Area.Parameters.mGuests29_90Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 182 Then
			vPage4Area.Parameters.mGuests91_182Rus = vRow.GuestsCheckedInTurnover;
		Else
			vPage4Area.Parameters.mGuests183Rus = vRow.GuestsCheckedInTurnover;
		EndIf;
	EndDo;
	
	// 4.2.2 Get total number of foreigner checked-in guests per duration
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 0
	|		WHEN GeoSales.Duration < 5
	|			THEN 4
	|		WHEN GeoSales.Duration < 8
	|			THEN 7
	|		WHEN GeoSales.Duration < 15
	|			THEN 14
	|		WHEN GeoSales.Duration < 29
	|			THEN 28
	|		WHEN GeoSales.Duration < 91
	|			THEN 90
	|		WHEN GeoSales.Duration < 183
	|			THEN 182
	|		ELSE 183
	|	END AS DurationType,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0) AS Duration,
	|		SUM(GeoSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND Client.Citizenship <> &qRussia
	|					AND ISNULL(Client.Citizenship.Description, """") <> """") AS GeoSalesTurnovers
	|	
	|	GROUP BY
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0)) AS GeoSales
	|
	|GROUP BY
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 0
	|		WHEN GeoSales.Duration < 5
	|			THEN 4
	|		WHEN GeoSales.Duration < 8
	|			THEN 7
	|		WHEN GeoSales.Duration < 15
	|			THEN 14
	|		WHEN GeoSales.Duration < 29
	|			THEN 28
	|		WHEN GeoSales.Duration < 91
	|			THEN 90
	|		WHEN GeoSales.Duration < 183
	|			THEN 182
	|		ELSE 183
	|	END
	|
	|ORDER BY
	|	DurationType";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qCompany", Company);
	vQryResult = vQry.Execute().Unload();
	
	vPage4Area.Parameters.mGuests0Foreigners = 0;
	vPage4Area.Parameters.mGuests1_4Foreigners = 0;
	vPage4Area.Parameters.mGuests5_7Foreigners = 0;
	vPage4Area.Parameters.mGuests8_14Foreigners = 0;
	vPage4Area.Parameters.mGuests15_28Foreigners = 0;
	vPage4Area.Parameters.mGuests29_90Foreigners = 0;
	vPage4Area.Parameters.mGuests91_182Foreigners = 0;
	vPage4Area.Parameters.mGuests183Foreigners = 0;

	For Each vRow In vQryResult Do
		If vRow.DurationType = 0 Then
			vPage4Area.Parameters.mGuests0Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 4 Then
			vPage4Area.Parameters.mGuests1_4Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 7 Then
			vPage4Area.Parameters.mGuests5_7Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 14 Then
			vPage4Area.Parameters.mGuests8_14Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 28 Then
			vPage4Area.Parameters.mGuests15_28Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 90 Then
			vPage4Area.Parameters.mGuests29_90Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 182 Then
			vPage4Area.Parameters.mGuests91_182Foreigners = vRow.GuestsCheckedInTurnover;
		Else
			vPage4Area.Parameters.mGuests183Foreigners = vRow.GuestsCheckedInTurnover;
		EndIf;
	EndDo;
	
	pSpreadsheet.Put(vPage4Area);
	pSpreadsheet.PutHorizontalPageBreak();
	
	// Page 5
	
	// 7.1 Get total sales
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomSalesTurnovers.RoomRevenueWithoutVATTurnover,
	|	RoomSalesTurnovers.SalesWithoutVATTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			NOT IsCorrection AND Hotel = &qHotel
	|				AND Company = &qCompany
	|				AND (Service IN HIERARCHY (&qIncomeServices)
	|					OR (NOT &qUseServicesList))) AS RoomSalesTurnovers";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vUseServicesList = False;
	vServicesList = New ValueList();
	If ValueIsFilled(TotalIncomeServiceGroup) Then
		If Not TotalIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(TotalIncomeServiceGroup);
		EndIf;
	EndIf;
	vQry.SetParameter("qUseServicesList", vUseServicesList);
	vQry.SetParameter("qIncomeServices", vServicesList);
	vQryResult = vQry.Execute().Unload();

	vTotalIncome = 0;
	vPage5Area.Parameters.mTotalIncome = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vTotalIncome = Round(vRow.SalesWithoutVATTurnover/1000, 1);
		vPage5Area.Parameters.mTotalIncome = vTotalIncome;
	EndIf;
	
	// 7.2 Get total meals sales
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomSalesTurnovers.RoomRevenueWithoutVATTurnover,
	|	RoomSalesTurnovers.SalesWithoutVATTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			NOT IsCorrection AND Hotel = &qHotel
	|				AND Company = &qCompany
	|				AND (Service IN HIERARCHY (&qIncomeServices)
	|					OR (NOT &qUseServicesList))) AS RoomSalesTurnovers";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vUseServicesList = False;
	vServicesList = New ValueList();
	If ValueIsFilled(MealIncomeServiceGroup) Then
		If Not MealIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(MealIncomeServiceGroup);
		EndIf;
	EndIf;
	vQry.SetParameter("qUseServicesList", vUseServicesList);
	vQry.SetParameter("qIncomeServices", vServicesList);
	vQryResult = vQry.Execute().Unload();
	
	vTotalMealsIncome = 0;
	vPage5Area.Parameters.mTotalMealsIncome = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vTotalMealsIncome = Round(vRow.SalesWithoutVATTurnover/1000, 1);
		vPage5Area.Parameters.mTotalMealsIncome = vTotalMealsIncome;
	EndIf;
	
	pSpreadsheet.Put(vPage5Area);
	pSpreadsheet.PutHorizontalPageBreak();
EndProcedure // pmGenerate2021

// -----------------------------------------------------------------------------
Procedure pmGenerate2022(pSpreadsheet) Export
	// Clear output spreadsheet
	pSpreadsheet.Clear();
	
	// Choose template
	vTemplate = ThisObject.GetTemplate("Report2022");
	
	// Report pages
	vPage1Area = vTemplate.GetArea("Page1");
	vPage2Area = vTemplate.GetArea("Page2");
	vPage3Area = vTemplate.GetArea("Page3");
	vPage3H1Area = vTemplate.GetArea("Page3H1");
	vPage3H1RowArea = vTemplate.GetArea("Page3H1Row");
	vPage3H2Area = vTemplate.GetArea("Page3H2");
	vPage4Area = vTemplate.GetArea("Page4");
	vPage5Area = vTemplate.GetArea("Page5");
	
	// Page 1
	vPage1Area.Parameters.mPeriodStr = PeriodPresentation(BegOfDay(PeriodFrom), EndOfDay(PeriodTo), cmLocalizationCode());
	vPage1Area.Parameters.mHotelName = TrimAll(Hotel.LegacyName);
	vPage1Area.Parameters.mHotelPostAddress = cmGetAddressPresentation(Hotel.PostAddress);
	vPage1Area.Parameters.mCompanyName = TrimAll(Company.LegacyName);
	vPage1Area.Parameters.mCompanyPostAddress = cmGetAddressPresentation(Company.PostAddress);
	vPage1Area.Parameters.mCompanyOKPOCode = TrimAll(Company.OKPO);
	pSpreadsheet.Put(vPage1Area);
	pSpreadsheet.PutHorizontalPageBreak();
	
	// Page 2
	pSpreadsheet.Put(vPage2Area);
	pSpreadsheet.PutHorizontalPageBreak();
	
	// Page 3
	
	// 3.1 Get total number of rooms/beds per end of period
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInventoryBalance.TotalRoomsBalance AS TotalRoomsBalance,
	|	RoomInventoryBalance.TotalBedsBalance AS TotalBedsBalance
	|FROM
	|	AccumulationRegister.RoomInventory.Balance(
	|			&qPeriodTo,
	|			Hotel = &qHotel
	|				AND (Room.Company = &qCompany
	|					OR Room.Company = &qEmptyCompany)
	|				AND (RoomType.Company = &qCompany
	|					OR RoomType.Company = &qEmptyCompany)) AS RoomInventoryBalance";
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyCompany", Catalogs.Companies.EmptyRef());
	vQryResult = vQry.Execute().Unload();

	vPage3Area.Parameters.mTotalRooms = 0;
	vPage3Area.Parameters.mTotalBeds = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vPage3Area.Parameters.mTotalRooms = vRow.TotalRoomsBalance;
		vPage3Area.Parameters.mTotalBeds = vRow.TotalBedsBalance;
	EndIf;
	
	// 3.2 Get total number of rooms/beds for top room types per end of period
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInventoryBalance.TotalRoomsBalance AS TotalRoomsBalance,
	|	RoomInventoryBalance.TotalBedsBalance AS TotalBedsBalance
	|FROM
	|	AccumulationRegister.RoomInventory.Balance(
	|			&qPeriodTo,
	|			Hotel = &qHotel
	|				AND (&qNoTopRoomTypes
	|					OR NOT &qNoTopRoomTypes
	|						AND RoomType IN HIERARCHY (&qTopRoomTypes))
	|				AND (Room.Company = &qCompany
	|					OR Room.Company = &qEmptyCompany)
	|				AND (RoomType.Company = &qCompany
	|					OR RoomType.Company = &qEmptyCompany)) AS RoomInventoryBalance";
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyCompany", Catalogs.Companies.EmptyRef());
	vQry.SetParameter("qNoTopRoomTypes", Not ValueIsFilled(TopRoomTypes));
	vQry.SetParameter("qTopRoomTypes", TopRoomTypes);
	vQryResult = vQry.Execute().Unload();

	vPage3Area.Parameters.mTotalTopRooms = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vPage3Area.Parameters.mTotalTopRooms = vRow.TotalRoomsBalance;
	EndIf;
	
	// 3.3 Get total number of guest days and number of checked in guests
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SUM(ISNULL(RoomSales.GuestDaysTurnover, 0)) AS GuestDaysTurnover,
	|	SUM(ISNULL(RoomSales.GuestDays18Turnover, 0)) AS GuestDays18Turnover,
	|	SUM(ISNULL(RoomSales.GuestDays1855Turnover, 0)) AS GuestDays1855Turnover,
	|	SUM(ISNULL(RoomSales.GuestDays55Turnover, 0)) AS GuestDays55Turnover,
	|	SUM(ISNULL(RoomSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover,
	|	SUM(ISNULL(RoomSales.GuestsCheckedIn18Turnover, 0)) AS GuestsCheckedIn18Turnover,
	|	SUM(ISNULL(RoomSales.GuestsCheckedIn1855Turnover, 0)) AS GuestsCheckedIn1855Turnover,
	|	SUM(ISNULL(RoomSales.GuestsCheckedIn55Turnover, 0)) AS GuestsCheckedIn55Turnover
	|FROM
	|	(SELECT
	|		RoomSalesTurnovers.Client AS Client,
	|		RoomSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover,
	|		CASE
	|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND RoomSalesTurnovers.Client.Age < 18
	|				THEN RoomSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays18Turnover,
	|		CASE
	|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND RoomSalesTurnovers.Client.Age >= 18
	|					AND RoomSalesTurnovers.Client.Age < 55 
	|				THEN RoomSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays1855Turnover,
	|		CASE
	|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND RoomSalesTurnovers.Client.Age >= 55
	|				THEN RoomSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays55Turnover,
	|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
	|		CASE
	|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND RoomSalesTurnovers.Client.Age < 18
	|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn18Turnover,
	|		CASE
	|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND RoomSalesTurnovers.Client.Age >= 18
	|					AND RoomSalesTurnovers.Client.Age < 55
	|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn1855Turnover,
	|		CASE
	|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND RoomSalesTurnovers.Client.Age >= 55
	|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn55Turnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany) AS RoomSalesTurnovers) AS RoomSales";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyDate", '00010101');
	vQryResult = vQry.Execute().Unload();

	vTotalGuestDays = 0;
	vTotalGuestDays18 = 0;
	vTotalGuestDays1855 = 0;
	vTotalGuestDays55 = 0;
	vTotalGuests = 0;
	vTotalGuests18 = 0;
	vTotalGuests1855 = 0;
	vTotalGuests55 = 0;
	vPage3Area.Parameters.mTotalGuestDays = 0;
	vPage3Area.Parameters.mTotalGuestDays18 = 0;
	vPage3Area.Parameters.mTotalGuestDays1855 = 0;
	vPage3Area.Parameters.mTotalGuestDays55 = 0;
	vPage3Area.Parameters.mTotalGuests = 0;
	vPage3Area.Parameters.mTotalGuests18 = 0;
	vPage3Area.Parameters.mTotalGuests1855 = 0;
	vPage3Area.Parameters.mTotalGuests55 = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vPage3Area.Parameters.mTotalGuestDays = vRow.GuestDaysTurnover;
		vPage3Area.Parameters.mTotalGuestDays18 = vRow.GuestDays18Turnover;
		vPage3Area.Parameters.mTotalGuestDays1855 = vRow.GuestDays1855Turnover;
		vPage3Area.Parameters.mTotalGuestDays55 = vRow.GuestDays55Turnover;
		vPage3Area.Parameters.mTotalGuests = vRow.GuestsCheckedInTurnover;
		vPage3Area.Parameters.mTotalGuests18 = vRow.GuestsCheckedIn18Turnover;
		vPage3Area.Parameters.mTotalGuests1855 = vRow.GuestsCheckedIn1855Turnover;
		vPage3Area.Parameters.mTotalGuests55 = vRow.GuestsCheckedIn55Turnover;
		vTotalGuestDays = vRow.GuestDaysTurnover;
		vTotalGuestDays18 = vRow.GuestDays18Turnover;
		vTotalGuestDays1855 = vRow.GuestDays1855Turnover;
		vTotalGuestDays55 = vRow.GuestDays55Turnover;
		vTotalGuests = vRow.GuestsCheckedInTurnover;
		vTotalGuests18 = vRow.GuestsCheckedIn18Turnover;
		vTotalGuests1855 = vRow.GuestsCheckedIn1855Turnover;
		vTotalGuests55 = vRow.GuestsCheckedIn55Turnover;
	EndIf;
	
	// 3.4 Get total number of guest days and checked-in guests from Russia
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SUM(ISNULL(GeoSales.GuestDaysTurnover, 0)) AS GuestDaysTurnover,
	|	SUM(ISNULL(GeoSales.GuestDays18Turnover, 0)) AS GuestDays18Turnover,
	|	SUM(ISNULL(GeoSales.GuestDays1855Turnover, 0)) AS GuestDays1855Turnover,
	|	SUM(ISNULL(GeoSales.GuestDays55Turnover, 0)) AS GuestDays55Turnover,
	|	SUM(ISNULL(GeoSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover,
	|	SUM(ISNULL(GeoSales.GuestsCheckedIn18Turnover, 0)) AS GuestsCheckedIn18Turnover,
	|	SUM(ISNULL(GeoSales.GuestsCheckedIn1855Turnover, 0)) AS GuestsCheckedIn1855Turnover,
	|	SUM(ISNULL(GeoSales.GuestsCheckedIn55Turnover, 0)) AS GuestsCheckedIn55Turnover
	|FROM
	|	(SELECT
	|		GeoSalesTurnovers.Client AS Client,
	|		GeoSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age < 18
	|				THEN GeoSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays18Turnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age >= 18
	|					AND GeoSalesTurnovers.Client.Age < 55
	|				THEN GeoSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays1855Turnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age >= 55
	|				THEN GeoSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays55Turnover,
	|		GeoSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age < 18
	|				THEN GeoSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn18Turnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age >= 18
	|					AND GeoSalesTurnovers.Client.Age < 55
	|				THEN GeoSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn1855Turnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age >= 55
	|				THEN GeoSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn55Turnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND (Client.Citizenship = &qRussia
	|						OR ISNULL(Client.Citizenship.Description, """") = """")) AS GeoSalesTurnovers) AS GeoSales";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyDate", '00010101');
	vQryResult = vQry.Execute().Unload();

	vRussiaGuestDays = 0;
	vRussiaGuestDays18 = 0;
	vRussiaGuestDays1855 = 0;
	vRussiaGuestDays55 = 0;
	vRussiaGuests = 0;
	vRussiaGuests18 = 0;
	vRussiaGuests1855 = 0;
	vRussiaGuests55 = 0;
	vPage3Area.Parameters.mTotalGuestDaysRus = 0;
	vPage3Area.Parameters.mTotalGuestDaysRus18 = 0;
	vPage3Area.Parameters.mTotalGuestDaysRus1855 = 0;
	vPage3Area.Parameters.mTotalGuestDaysRus55 = 0;
	vPage3Area.Parameters.mTotalGuestsRus = 0;
	vPage3Area.Parameters.mTotalGuestsRus18 = 0;
	vPage3Area.Parameters.mTotalGuestsRus1855 = 0;
	vPage3Area.Parameters.mTotalGuestsRus55 = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vPage3Area.Parameters.mTotalGuestDaysRus = vRow.GuestDaysTurnover;
		vPage3Area.Parameters.mTotalGuestDaysRus18 = vRow.GuestDays18Turnover;
		vPage3Area.Parameters.mTotalGuestDaysRus1855 = vRow.GuestDays1855Turnover;
		vPage3Area.Parameters.mTotalGuestDaysRus55 = vRow.GuestDays55Turnover;
		vPage3Area.Parameters.mTotalGuestsRus = vRow.GuestsCheckedInTurnover;
		vPage3Area.Parameters.mTotalGuestsRus18 = vRow.GuestsCheckedIn18Turnover;
		vPage3Area.Parameters.mTotalGuestsRus1855 = vRow.GuestsCheckedIn1855Turnover;
		vPage3Area.Parameters.mTotalGuestsRus55 = vRow.GuestsCheckedIn55Turnover;
		vRussiaGuestDays = vRow.GuestDaysTurnover;
		vRussiaGuestDays18 = vRow.GuestDays18Turnover;
		vRussiaGuestDays1855 = vRow.GuestDays1855Turnover;
		vRussiaGuestDays55 = vRow.GuestDays55Turnover;
		vRussiaGuests = vRow.GuestsCheckedInTurnover;
		vRussiaGuests18 = vRow.GuestsCheckedIn18Turnover;
		vRussiaGuests1855 = vRow.GuestsCheckedIn1855Turnover;
		vRussiaGuests55 = vRow.GuestsCheckedIn55Turnover;
	EndIf;
	
	// 3.5 Get total number of guest days and checked-in foreigner guests
	If vTotalGuests <> Null And vRussiaGuests <> Null Then
		vPage3Area.Parameters.mTotalGuestDaysForeigners = vTotalGuestDays - vRussiaGuestDays;
		vPage3Area.Parameters.mTotalGuestDaysForeigners18 = vTotalGuestDays18 - vRussiaGuestDays18;
		vPage3Area.Parameters.mTotalGuestDaysForeigners1855 = vTotalGuestDays1855 - vRussiaGuestDays1855;
		vPage3Area.Parameters.mTotalGuestDaysForeigners55 = vTotalGuestDays55 - vRussiaGuestDays55;
		vPage3Area.Parameters.mTotalGuestsForeigners = vTotalGuests - vRussiaGuests;
		vPage3Area.Parameters.mTotalGuestsForeigners18 = vTotalGuests18 - vRussiaGuests18;
		vPage3Area.Parameters.mTotalGuestsForeigners1855 = vTotalGuests1855 - vRussiaGuests1855;
		vPage3Area.Parameters.mTotalGuestsForeigners55 = vTotalGuests55 - vRussiaGuests55;
	Else
		vPage3Area.Parameters.mTotalGuestDaysForeigners = 0;
		vPage3Area.Parameters.mTotalGuestDaysForeigners18 = 0;
		vPage3Area.Parameters.mTotalGuestDaysForeigners1855 = 0;
		vPage3Area.Parameters.mTotalGuestDaysForeigners55 = 0;
		vPage3Area.Parameters.mTotalGuestsForeigners = 0;
		vPage3Area.Parameters.mTotalGuestsForeigners18 = 0;
		vPage3Area.Parameters.mTotalGuestsForeigners1855 = 0;
		vPage3Area.Parameters.mTotalGuestsForeigners55 = 0;
	EndIf;
	
	// 3.6 Get total number of checked-in guests with tour tickets
	vPage3Area.Parameters.mTotalTourTicketGuests = 0;
	vPage3Area.Parameters.mTotalTourTicketGuests18 = 0;
	vPage3Area.Parameters.mTotalTourTicketGuests1855 = 0;
	vPage3Area.Parameters.mTotalTourTicketGuests55 = 0;
	If ValueIsFilled(TourTicketIncomeServiceGroup) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	SUM(ISNULL(RoomSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover,
		|	SUM(ISNULL(RoomSales.GuestsCheckedIn18Turnover, 0)) AS GuestsCheckedIn18Turnover,
		|	SUM(ISNULL(RoomSales.GuestsCheckedIn1855Turnover, 0)) AS GuestsCheckedIn1855Turnover,
		|	SUM(ISNULL(RoomSales.GuestsCheckedIn55Turnover, 0)) AS GuestsCheckedIn55Turnover
		|FROM
		|	(SELECT
		|		RoomSalesTurnovers.Client AS Client,
		|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
		|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					AND RoomSalesTurnovers.Client.Age < 18
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			ELSE 0
		|		END AS GuestsCheckedIn18Turnover,
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
		|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					AND RoomSalesTurnovers.Client.Age >= 18
		|					AND RoomSalesTurnovers.Client.Age < 55
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			ELSE 0
		|		END AS GuestsCheckedIn1855Turnover,
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
		|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					AND RoomSalesTurnovers.Client.Age >= 55
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			ELSE 0
		|		END AS GuestsCheckedIn55Turnover
		|	FROM
		|		AccumulationRegister.Sales.Turnovers(
		|				&qPeriodFrom,
		|				&qPeriodTo,
		|				Period,
		|				NOT IsCorrection AND Hotel = &qHotel
		|					AND Company = &qCompany
		|					AND (Service IN HIERARCHY (&qTourTicketServices)
		|						OR NOT &qUseServicesList)
		|					) AS RoomSalesTurnovers) AS RoomSales";
		vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qCompany", Company);
		vUseServicesList = False;
		vServicesList = New ValueList();
		If Not TourTicketIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(TourTicketIncomeServiceGroup);
		EndIf;
		vQry.SetParameter("qUseServicesList", vUseServicesList);
		vQry.SetParameter("qTourTicketServices", vServicesList);
		vQry.SetParameter("qEmptyDate", '00010101');
		vQryResult = vQry.Execute().Unload();

		If vQryResult.Count() > 0 Then
			vRow = vQryResult.Get(0);
			
			vPage3Area.Parameters.mTotalTourTicketGuests = vRow.GuestsCheckedInTurnover;
			vPage3Area.Parameters.mTotalTourTicketGuests18 = vRow.GuestsCheckedIn18Turnover;
			vPage3Area.Parameters.mTotalTourTicketGuests1855 = vRow.GuestsCheckedIn1855Turnover;
			vPage3Area.Parameters.mTotalTourTicketGuests55 = vRow.GuestsCheckedIn55Turnover;
		EndIf;
		
		// The same from russia
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	SUM(ISNULL(RoomSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover,
		|	SUM(ISNULL(RoomSales.GuestsCheckedIn18Turnover, 0)) AS GuestsCheckedIn18Turnover,
		|	SUM(ISNULL(RoomSales.GuestsCheckedIn1855Turnover, 0)) AS GuestsCheckedIn1855Turnover,
		|	SUM(ISNULL(RoomSales.GuestsCheckedIn55Turnover, 0)) AS GuestsCheckedIn55Turnover
		|FROM
		|	(SELECT
		|		RoomSalesTurnovers.Client AS Client,
		|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL
		|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					AND RoomSalesTurnovers.Client.Age < 18
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			ELSE 0
		|		END AS GuestsCheckedIn18Turnover,
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL
		|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					AND RoomSalesTurnovers.Client.Age >= 18
		|					AND RoomSalesTurnovers.Client.Age < 55
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			ELSE 0
		|		END AS GuestsCheckedIn1855Turnover,
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL
		|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					AND RoomSalesTurnovers.Client.Age >= 55
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			ELSE 0
		|		END AS GuestsCheckedIn55Turnover
		|	FROM
		|		AccumulationRegister.Sales.Turnovers(
		|				&qPeriodFrom,
		|				&qPeriodTo,
		|				Period,
		|				NOT IsCorrection
		|					AND Hotel = &qHotel
		|					AND Company = &qCompany
		|					AND (Service IN HIERARCHY (&qTourTicketServices)
		|						OR NOT &qUseServicesList)
		|					AND (Client.Citizenship = &qRussia
		|						OR ISNULL(Client.Citizenship.Description, """") = """")) AS RoomSalesTurnovers) AS RoomSales";
		vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qRussia", RussiaCountry);
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qCompany", Company);
		vUseServicesList = False;
		vServicesList = New ValueList();
		If Not TourTicketIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(TourTicketIncomeServiceGroup);
		EndIf;
		vQry.SetParameter("qUseServicesList", vUseServicesList);
		vQry.SetParameter("qTourTicketServices", vServicesList);
		vQry.SetParameter("qEmptyDate", '00010101');
		vQryResult = vQry.Execute().Unload();

		If vQryResult.Count() > 0 Then
			vRow = vQryResult.Get(0);
			vPage3Area.Parameters.mTotalTourTicketGuestsRus = ?(vRow.GuestsCheckedInTurnover = Null, 0, vRow.GuestsCheckedInTurnover);
			vPage3Area.Parameters.mTotalTourTicketGuestsRus18 = ?(vRow.GuestsCheckedIn18Turnover = Null, 0, vRow.GuestsCheckedIn18Turnover);
			vPage3Area.Parameters.mTotalTourTicketGuestsRus1855 = ?(vRow.GuestsCheckedIn1855Turnover = Null, 0, vRow.GuestsCheckedIn1855Turnover);
			vPage3Area.Parameters.mTotalTourTicketGuestsRus55 = ?(vRow.GuestsCheckedIn55Turnover = Null, 0, vRow.GuestsCheckedIn55Turnover);
			
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners = ?(vPage3Area.Parameters.mTotalTourTicketGuests = Null, 0, vPage3Area.Parameters.mTotalTourTicketGuests) - ?(vRow.GuestsCheckedInTurnover = Null, 0, vRow.GuestsCheckedInTurnover);
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners18 = ?(vPage3Area.Parameters.mTotalTourTicketGuests18 = Null, 0, vPage3Area.Parameters.mTotalTourTicketGuests18) - ?(vRow.GuestsCheckedIn18Turnover = Null, 0, vRow.GuestsCheckedIn18Turnover);
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners1855 = ?(vPage3Area.Parameters.mTotalTourTicketGuests1855 = Null, 0, vPage3Area.Parameters.mTotalTourTicketGuests1855) - ?(vRow.GuestsCheckedIn1855Turnover = Null, 0, vRow.GuestsCheckedIn1855Turnover);
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners55 = ?(vPage3Area.Parameters.mTotalTourTicketGuests55 = Null, 0, vPage3Area.Parameters.mTotalTourTicketGuests55) - ?(vRow.GuestsCheckedIn55Turnover = Null, 0, vRow.GuestsCheckedIn55Turnover);
		Else
			vPage3Area.Parameters.mTotalTourTicketGuestsRus = 0;
			vPage3Area.Parameters.mTotalTourTicketGuestsRus18 = 0;
			vPage3Area.Parameters.mTotalTourTicketGuestsRus1855 = 0;
			vPage3Area.Parameters.mTotalTourTicketGuestsRus55 = 0;
			
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners = 0;
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners18 = 0;
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners1855 = 0;
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners55 = 0;
		EndIf;
	EndIf;
	
	pSpreadsheet.Put(vPage3Area);
	
	// Page 3 header Spr. 1
	pSpreadsheet.Put(vPage3H1Area);
	
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ISNULL(GeoSales.Client.Citizenship.Description, """") AS CountryDescription,
	|	ISNULL(GeoSales.Client.Citizenship.Code, 0) AS CountryCode,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			NOT IsCorrection AND Hotel = &qHotel
	|				AND Company = &qCompany
	|				AND Client.Citizenship <> &qRussia
	|				AND ISNULL(Client.Citizenship.Description, """") <> """") AS GeoSales
	|
	|GROUP BY
	|	GeoSales.Client.Citizenship.Description,
	|	GeoSales.Client.Citizenship.Code
	|
	|ORDER BY
	|	GeoSales.Client.Citizenship.Code";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQryResult = vQry.Execute().Unload();
	c = 0;
	While c < vQryResult.Count() Do
		vQryResultLRow = vQryResult.Get(c);
		
		vPage3H1RowArea.Parameters.mCountryL = TrimAll(vQryResultLRow.CountryDescription);
		vPage3H1RowArea.Parameters.mCountryCodeL = TrimAll(vQryResultLRow.CountryCode);
		vPage3H1RowArea.Parameters.mCountryGuestsL = vQryResultLRow.GuestsCheckedInTurnover;
		
		If c < (vQryResult.Count() - 1) Then
			vQryResultRRow = vQryResult.Get(c + 1);
			
			vPage3H1RowArea.Parameters.mCountryR = TrimAll(vQryResultRRow.CountryDescription);
			vPage3H1RowArea.Parameters.mCountryCodeR = TrimAll(vQryResultRRow.CountryCode);
			vPage3H1RowArea.Parameters.mCountryGuestsR = vQryResultRRow.GuestsCheckedInTurnover;
		Else
			vPage3H1RowArea.Parameters.mCountryR = "";
			vPage3H1RowArea.Parameters.mCountryCodeR = "";
			vPage3H1RowArea.Parameters.mCountryGuestsR = 0;
		EndIf;
		
		pSpreadsheet.Put(vPage3H1RowArea);
		
		c = c + 2;
	EndDo;
	
	// Get number of checked in guests by hotel products (Page 3. Spr 2)
	vPage3H2Area.Parameters.mVaucherQuantity = 0;
	vPage3H2Area.Parameters.mVaucher18Quantity = 0;
	vPage3H2Area.Parameters.mVaucher1855Quantity = 0;
	vPage3H2Area.Parameters.mVaucher55Quantity = 0;
	
	If ValueIsFilled(VaucherIncomeServiceGroup) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	SUM(AgeSales.VaucherQuantity) AS VaucherQuantity,
		|	SUM(AgeSales.Vaucher18Quantity) AS Vaucher18Quantity,
		|	SUM(AgeSales.Vaucher1855Quantity) AS Vaucher1855Quantity,
		|	SUM(AgeSales.Vaucher55Quantity) AS Vaucher55Quantity
		|FROM
		|	(SELECT
		|		RoomSalesTurnovers.Client AS Client,
		|		RoomSalesTurnovers.Client.Age AS ClientAge,
		|		MAX(1) AS VaucherQuantity,
		|		MAX(CASE
		|				WHEN RoomSalesTurnovers.Client.Age < 18
		|						AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					THEN 1
		|				ELSE 0
		|			END) AS Vaucher18Quantity,
		|		MAX(CASE
		|				WHEN RoomSalesTurnovers.Client.Age >= 18
		|				WHEN RoomSalesTurnovers.Client.Age < 54
		|						AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					THEN 1
		|				ELSE 0
		|			END) AS Vaucher1855Quantity,
		|		MAX(CASE
		|				WHEN RoomSalesTurnovers.Client.Age >= 55
		|					THEN 1
		|				ELSE 0
		|			END) AS Vaucher55Quantity
		|	FROM
		|		AccumulationRegister.Sales.Turnovers(
		|				&qPeriodFrom,
		|				&qPeriodTo,
		|				Period,
		|				NOT IsCorrection AND Hotel = &qHotel
		|					AND Company = &qCompany
		|					AND (Service IN HIERARCHY (&qVaucherServices)
		|						OR NOT &qUseServicesList)) AS RoomSalesTurnovers
		|	
		|	GROUP BY
		|		RoomSalesTurnovers.Client,
		|		RoomSalesTurnovers.Client.Age) AS AgeSales";
		vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qCompany", Company);
		vQry.SetParameter("qEmptyDate", '00010101');
		vUseServicesList = False;
		vServicesList = New ValueList();
		If Not TourTicketIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(VaucherIncomeServiceGroup);
		EndIf;
		vQry.SetParameter("qUseServicesList", vUseServicesList);
		vQry.SetParameter("qVaucherServices", vServicesList);
		vQryResult = vQry.Execute().Unload();

		If vQryResult.Count() > 0 Then
			vRow = vQryResult.Get(0);
			
			vPage3H2Area.Parameters.mVaucherQuantity = vRow.VaucherQuantity;
			vPage3H2Area.Parameters.mVaucher18Quantity = vRow.Vaucher18Quantity;
			vPage3H2Area.Parameters.mVaucher1855Quantity = vRow.Vaucher1855Quantity;
			vPage3H2Area.Parameters.mVaucher55Quantity = vRow.Vaucher55Quantity;
		EndIf;
	EndIf;
	
	pSpreadsheet.Put(vPage3H2Area);
	
	pSpreadsheet.PutHorizontalPageBreak();
	
	// Page 4
	
	// 4.1.1 Get total number of russian checked-in guests per trip purposes
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qStudy
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qOther
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTransit
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qRecreation
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qPilgrims
	|			THEN 4
	|		WHEN GeoSales.TripPurpose = &qShopping
	|			THEN 5
	|		ELSE 5
	|	END AS TripPurposeType,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		GeoSalesTurnovers.TripPurpose AS TripPurpose,
	|		SUM(GeoSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND (Client.Citizenship = &qRussia
	|						OR ISNULL(Client.Citizenship.Description, """") = """")) AS GeoSalesTurnovers
	|	
	|	GROUP BY
	|		GeoSalesTurnovers.TripPurpose) AS GeoSales
	|
	|GROUP BY
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qStudy
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qOther
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTransit
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qRecreation
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qPilgrims
	|			THEN 4
	|		WHEN GeoSales.TripPurpose = &qShopping
	|			THEN 5
	|		ELSE 5
	|	END
	|
	|ORDER BY
	|	TripPurposeType";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qBusiness", Catalogs.TripPurposes.Business);
	vQry.SetParameter("qCommerce", Catalogs.TripPurposes.Commerce);
	vQry.SetParameter("qOfficial", Catalogs.TripPurposes.Official);
	vQry.SetParameter("qWork", Catalogs.TripPurposes.Work);
	vQry.SetParameter("qCrewman", Catalogs.TripPurposes.Crewman);
	vQry.SetParameter("qHumanitarian", Catalogs.TripPurposes.Humanitarian);
	vQry.SetParameter("qTourism", Catalogs.TripPurposes.Tourism);
	vQry.SetParameter("qPrivate", Catalogs.TripPurposes.Private);
	vQry.SetParameter("qScientific", Catalogs.TripPurposes.Scientific);
	vQry.SetParameter("qStudy", Catalogs.TripPurposes.Study);
	vQry.SetParameter("qRecreation", Catalogs.TripPurposes.Recreation);
	vQry.SetParameter("qShopping", Catalogs.TripPurposes.Shopping);
	vQry.SetParameter("qPilgrims", Catalogs.TripPurposes.Pilgrims);
	vQry.SetParameter("qTransit", Catalogs.TripPurposes.Transit);
	vQry.SetParameter("qOther", Catalogs.TripPurposes.Other);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyCountry", Catalogs.Countries.EmptyRef());
	vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vQry.SetParameter("qEmptyCountry", Catalogs.Countries.EmptyRef());
	vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vQryResult = vQry.Execute().Unload();
	
	vPage4Area.Parameters.mGuestsTouristsRus = 0;
	vPage4Area.Parameters.mGuestsEducationRus = 0;
	vPage4Area.Parameters.mGuestsBusinessRus = 0;
	vPage4Area.Parameters.mGuestsCureRus = 0;
	vPage4Area.Parameters.mGuestsPilgrimRus = 0;
	vPage4Area.Parameters.mGuestsOtherRus = 0;

	For Each vRow In vQryResult Do
		If vRow.TripPurposeType = 1 Then
			vPage4Area.Parameters.mGuestsTouristsRus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 2 Then
			vPage4Area.Parameters.mGuestsEducationRus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 6 Then
			vPage4Area.Parameters.mGuestsBusinessRus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 3 Then
			vPage4Area.Parameters.mGuestsCureRus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 4 Then
			vPage4Area.Parameters.mGuestsPilgrimRus = vRow.GuestsCheckedInTurnover;
		Else
			vPage4Area.Parameters.mGuestsOtherRus = vRow.GuestsCheckedInTurnover;
		EndIf;
	EndDo;
	
	// 4.1.4 Get total number of checked-in foreigner guests per trip purposes
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qStudy
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qOther
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTransit
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qRecreation
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qPilgrims
	|			THEN 4
	|		WHEN GeoSales.TripPurpose = &qShopping
	|			THEN 5
	|		ELSE 5
	|	END AS TripPurposeType,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		GeoSalesTurnovers.TripPurpose AS TripPurpose,
	|		SUM(GeoSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND Client.Citizenship <> &qRussia
	|					AND ISNULL(Client.Citizenship.Description, """") <> """") AS GeoSalesTurnovers
	|	
	|	GROUP BY
	|		GeoSalesTurnovers.TripPurpose) AS GeoSales
	|
	|GROUP BY
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qStudy
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qOther
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTransit
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qRecreation
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qPilgrims
	|			THEN 4
	|		WHEN GeoSales.TripPurpose = &qShopping
	|			THEN 5
	|		ELSE 5
	|	END
	|
	|ORDER BY
	|	TripPurposeType";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qBusiness", Catalogs.TripPurposes.Business);
	vQry.SetParameter("qCommerce", Catalogs.TripPurposes.Commerce);
	vQry.SetParameter("qOfficial", Catalogs.TripPurposes.Official);
	vQry.SetParameter("qWork", Catalogs.TripPurposes.Work);
	vQry.SetParameter("qCrewman", Catalogs.TripPurposes.Crewman);
	vQry.SetParameter("qHumanitarian", Catalogs.TripPurposes.Humanitarian);
	vQry.SetParameter("qTourism", Catalogs.TripPurposes.Tourism);
	vQry.SetParameter("qPrivate", Catalogs.TripPurposes.Private);
	vQry.SetParameter("qScientific", Catalogs.TripPurposes.Scientific);
	vQry.SetParameter("qStudy", Catalogs.TripPurposes.Study);
	vQry.SetParameter("qRecreation", Catalogs.TripPurposes.Recreation);
	vQry.SetParameter("qShopping", Catalogs.TripPurposes.Shopping);
	vQry.SetParameter("qPilgrims", Catalogs.TripPurposes.Pilgrims);
	vQry.SetParameter("qTransit", Catalogs.TripPurposes.Transit);
	vQry.SetParameter("qOther", Catalogs.TripPurposes.Other);
	vQry.SetParameter("qCompany", Company);
	vQryResult = vQry.Execute().Unload();
	
	vPage4Area.Parameters.mGuestsTouristsForeigners = 0;
	vPage4Area.Parameters.mGuestsEducationForeigners = 0;
	vPage4Area.Parameters.mGuestsBusinessForeigners = 0;
	vPage4Area.Parameters.mGuestsCureForeigners = 0;
	vPage4Area.Parameters.mGuestsPilgrimForeigners = 0;
	vPage4Area.Parameters.mGuestsOtherForeigners = 0;

	For Each vRow In vQryResult Do
		If vRow.TripPurposeType = 1 Then
			vPage4Area.Parameters.mGuestsTouristsForeigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 2 Then
			vPage4Area.Parameters.mGuestsEducationForeigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 6 Then
			vPage4Area.Parameters.mGuestsBusinessForeigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 3 Then
			vPage4Area.Parameters.mGuestsCureForeigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 4 Then
			vPage4Area.Parameters.mGuestsPilgrimForeigners = vRow.GuestsCheckedInTurnover;
		Else
			vPage4Area.Parameters.mGuestsOtherForeigners = vRow.GuestsCheckedInTurnover;
		EndIf;
	EndDo;
	
	// 4.2.1 Get total number of russian checked-in guests per duration
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 0
	|		WHEN GeoSales.Duration < 5
	|			THEN 4
	|		WHEN GeoSales.Duration < 8
	|			THEN 7
	|		WHEN GeoSales.Duration < 15
	|			THEN 14
	|		WHEN GeoSales.Duration < 29
	|			THEN 28
	|		WHEN GeoSales.Duration < 91
	|			THEN 90
	|		WHEN GeoSales.Duration < 183
	|			THEN 182
	|		ELSE 183
	|	END AS DurationType,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0) AS Duration,
	|		SUM(GeoSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND (Client.Citizenship = &qRussia
	|						OR ISNULL(Client.Citizenship.Description, """") = """")) AS GeoSalesTurnovers
	|	
	|	GROUP BY
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0)) AS GeoSales
	|
	|GROUP BY
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 0
	|		WHEN GeoSales.Duration < 5
	|			THEN 4
	|		WHEN GeoSales.Duration < 8
	|			THEN 7
	|		WHEN GeoSales.Duration < 15
	|			THEN 14
	|		WHEN GeoSales.Duration < 29
	|			THEN 28
	|		WHEN GeoSales.Duration < 91
	|			THEN 90
	|		WHEN GeoSales.Duration < 183
	|			THEN 182
	|		ELSE 183
	|	END
	|
	|ORDER BY
	|	DurationType";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyCountry", Catalogs.Countries.EmptyRef());
	vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vQryResult = vQry.Execute().Unload();
	
	vPage4Area.Parameters.mGuests0Rus = 0;
	vPage4Area.Parameters.mGuests1_4Rus = 0;
	vPage4Area.Parameters.mGuests5_7Rus = 0;
	vPage4Area.Parameters.mGuests8_14Rus = 0;
	vPage4Area.Parameters.mGuests15_28Rus = 0;
	vPage4Area.Parameters.mGuests29_90Rus = 0;
	vPage4Area.Parameters.mGuests91_182Rus = 0;
	vPage4Area.Parameters.mGuests183Rus = 0;

	For Each vRow In vQryResult Do
		If vRow.DurationType = 0 Then
			vPage4Area.Parameters.mGuests0Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 4 Then
			vPage4Area.Parameters.mGuests1_4Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 7 Then
			vPage4Area.Parameters.mGuests5_7Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 14 Then
			vPage4Area.Parameters.mGuests8_14Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 28 Then
			vPage4Area.Parameters.mGuests15_28Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 90 Then
			vPage4Area.Parameters.mGuests29_90Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 182 Then
			vPage4Area.Parameters.mGuests91_182Rus = vRow.GuestsCheckedInTurnover;
		Else
			vPage4Area.Parameters.mGuests183Rus = vRow.GuestsCheckedInTurnover;
		EndIf;
	EndDo;
	
	// 4.2.2 Get total number of foreigner checked-in guests per duration
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 0
	|		WHEN GeoSales.Duration < 5
	|			THEN 4
	|		WHEN GeoSales.Duration < 8
	|			THEN 7
	|		WHEN GeoSales.Duration < 15
	|			THEN 14
	|		WHEN GeoSales.Duration < 29
	|			THEN 28
	|		WHEN GeoSales.Duration < 91
	|			THEN 90
	|		WHEN GeoSales.Duration < 183
	|			THEN 182
	|		ELSE 183
	|	END AS DurationType,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0) AS Duration,
	|		SUM(GeoSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND Client.Citizenship <> &qRussia
	|					AND ISNULL(Client.Citizenship.Description, """") <> """") AS GeoSalesTurnovers
	|	
	|	GROUP BY
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0)) AS GeoSales
	|
	|GROUP BY
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 0
	|		WHEN GeoSales.Duration < 5
	|			THEN 4
	|		WHEN GeoSales.Duration < 8
	|			THEN 7
	|		WHEN GeoSales.Duration < 15
	|			THEN 14
	|		WHEN GeoSales.Duration < 29
	|			THEN 28
	|		WHEN GeoSales.Duration < 91
	|			THEN 90
	|		WHEN GeoSales.Duration < 183
	|			THEN 182
	|		ELSE 183
	|	END
	|
	|ORDER BY
	|	DurationType";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qCompany", Company);
	vQryResult = vQry.Execute().Unload();
	
	vPage4Area.Parameters.mGuests0Foreigners = 0;
	vPage4Area.Parameters.mGuests1_4Foreigners = 0;
	vPage4Area.Parameters.mGuests5_7Foreigners = 0;
	vPage4Area.Parameters.mGuests8_14Foreigners = 0;
	vPage4Area.Parameters.mGuests15_28Foreigners = 0;
	vPage4Area.Parameters.mGuests29_90Foreigners = 0;
	vPage4Area.Parameters.mGuests91_182Foreigners = 0;
	vPage4Area.Parameters.mGuests183Foreigners = 0;

	For Each vRow In vQryResult Do
		If vRow.DurationType = 0 Then
			vPage4Area.Parameters.mGuests0Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 4 Then
			vPage4Area.Parameters.mGuests1_4Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 7 Then
			vPage4Area.Parameters.mGuests5_7Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 14 Then
			vPage4Area.Parameters.mGuests8_14Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 28 Then
			vPage4Area.Parameters.mGuests15_28Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 90 Then
			vPage4Area.Parameters.mGuests29_90Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 182 Then
			vPage4Area.Parameters.mGuests91_182Foreigners = vRow.GuestsCheckedInTurnover;
		Else
			vPage4Area.Parameters.mGuests183Foreigners = vRow.GuestsCheckedInTurnover;
		EndIf;
	EndDo;
	
	pSpreadsheet.Put(vPage4Area);
	pSpreadsheet.PutHorizontalPageBreak();
	
	// Page 5
	
	// 7.1 Get total sales
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomSalesTurnovers.RoomRevenueWithoutVATTurnover,
	|	RoomSalesTurnovers.SalesWithoutVATTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			NOT IsCorrection AND Hotel = &qHotel
	|				AND Company = &qCompany
	|				AND (Service IN HIERARCHY (&qIncomeServices)
	|					OR (NOT &qUseServicesList))) AS RoomSalesTurnovers";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vUseServicesList = False;
	vServicesList = New ValueList();
	If ValueIsFilled(TotalIncomeServiceGroup) Then
		If Not TotalIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(TotalIncomeServiceGroup);
		EndIf;
	EndIf;
	vQry.SetParameter("qUseServicesList", vUseServicesList);
	vQry.SetParameter("qIncomeServices", vServicesList);
	vQryResult = vQry.Execute().Unload();

	vTotalIncome = 0;
	vPage5Area.Parameters.mTotalIncome = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vTotalIncome = Round(vRow.SalesWithoutVATTurnover/1000, 1);
		vPage5Area.Parameters.mTotalIncome = vTotalIncome;
	EndIf;
	
	// 7.2 Get total meals sales
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomSalesTurnovers.RoomRevenueWithoutVATTurnover,
	|	RoomSalesTurnovers.SalesWithoutVATTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			NOT IsCorrection AND Hotel = &qHotel
	|				AND Company = &qCompany
	|				AND (Service IN HIERARCHY (&qIncomeServices)
	|					OR (NOT &qUseServicesList))) AS RoomSalesTurnovers";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vUseServicesList = False;
	vServicesList = New ValueList();
	If ValueIsFilled(MealIncomeServiceGroup) Then
		If Not MealIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(MealIncomeServiceGroup);
		EndIf;
	EndIf;
	vQry.SetParameter("qUseServicesList", vUseServicesList);
	vQry.SetParameter("qIncomeServices", vServicesList);
	vQryResult = vQry.Execute().Unload();
	
	vTotalMealsIncome = 0;
	vPage5Area.Parameters.mTotalMealsIncome = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vTotalMealsIncome = Round(vRow.SalesWithoutVATTurnover/1000, 1);
		vPage5Area.Parameters.mTotalMealsIncome = vTotalMealsIncome;
	EndIf;
	
	pSpreadsheet.Put(vPage5Area);
	pSpreadsheet.PutHorizontalPageBreak();
EndProcedure // pmGenerate2022

// -----------------------------------------------------------------------------
Procedure pmGenerate2023(pSpreadsheet) Export
	// Clear output spreadsheet
	pSpreadsheet.Clear();
	
	// Choose template
	vTemplate = ThisObject.GetTemplate("Report2023");
	
	// Report pages
	vPage1Area = vTemplate.GetArea("Page1");
	vPage2Area = vTemplate.GetArea("Page2");
	vPage3Area = vTemplate.GetArea("Page3");
	vPage3H1Area = vTemplate.GetArea("Page3H1");
	vPage3H1RowArea = vTemplate.GetArea("Page3H1Row");
	vPage3H2Area = vTemplate.GetArea("Page3H2");
	vPage4Area = vTemplate.GetArea("Page4");
	vPage5Area = vTemplate.GetArea("Page5");
	
	// Page 1
	vPage1Area.Parameters.mPeriodStr = PeriodPresentation(BegOfDay(PeriodFrom), EndOfDay(PeriodTo), cmLocalizationCode());
	vPage1Area.Parameters.mHotelName = TrimAll(Hotel.LegacyName);
	vPage1Area.Parameters.mHotelPostAddress = cmGetAddressPresentation(Hotel.PostAddress);
	vPage1Area.Parameters.mCompanyName = TrimAll(Company.LegacyName);
	vPage1Area.Parameters.mCompanyPostAddress = cmGetAddressPresentation(Company.PostAddress);
	vPage1Area.Parameters.mCompanyOKPOCode = TrimAll(Company.OKPO);
	pSpreadsheet.Put(vPage1Area);
	pSpreadsheet.PutHorizontalPageBreak();
	
	// Page 2
	pSpreadsheet.Put(vPage2Area);
	pSpreadsheet.PutHorizontalPageBreak();
	
	// Page 3
	
	// 3.1 Get total number of rooms/beds per end of period
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInventoryBalance.TotalRoomsBalance AS TotalRoomsBalance,
	|	RoomInventoryBalance.TotalBedsBalance AS TotalBedsBalance
	|FROM
	|	AccumulationRegister.RoomInventory.Balance(
	|			&qPeriodTo,
	|			Hotel = &qHotel
	|				AND (Room.Company = &qCompany
	|					OR Room.Company = &qEmptyCompany)
	|				AND (RoomType.Company = &qCompany
	|					OR RoomType.Company = &qEmptyCompany)) AS RoomInventoryBalance";
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyCompany", Catalogs.Companies.EmptyRef());
	vQryResult = vQry.Execute().Unload();

	vPage3Area.Parameters.mTotalRooms = 0;
	vPage3Area.Parameters.mTotalBeds = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vPage3Area.Parameters.mTotalRooms = vRow.TotalRoomsBalance;
		vPage3Area.Parameters.mTotalBeds = vRow.TotalBedsBalance;
	EndIf;
	
	// 3.2 Get total number of rooms/beds for top room types per end of period
	vPage3Area.Parameters.mTotalTopRooms = 0;
	If ValueIsFilled(TopRoomTypes) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	RoomInventoryBalance.TotalRoomsBalance AS TotalRoomsBalance,
		|	RoomInventoryBalance.TotalBedsBalance AS TotalBedsBalance
		|FROM
		|	AccumulationRegister.RoomInventory.Balance(
		|			&qPeriodTo,
		|			Hotel = &qHotel
		|				AND RoomType IN HIERARCHY (&qTopRoomTypes)
		|				AND (Room.Company = &qCompany
		|					OR Room.Company = &qEmptyCompany)
		|				AND (RoomType.Company = &qCompany
		|					OR RoomType.Company = &qEmptyCompany)) AS RoomInventoryBalance";
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qCompany", Company);
		vQry.SetParameter("qEmptyCompany", Catalogs.Companies.EmptyRef());
		vQry.SetParameter("qTopRoomTypes", TopRoomTypes);
		vQryResult = vQry.Execute().Unload();

		If vQryResult.Count() > 0 Then
			vRow = vQryResult.Get(0);
			vPage3Area.Parameters.mTotalTopRooms = vRow.TotalRoomsBalance;
		EndIf;
	EndIf;

	// Get number of new rooms added in period
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	COUNT(AddRooms.Ref) AS NewRoomsCount
	|FROM
	|	Document.AddRoom AS AddRooms
	|WHERE
	|	AddRooms.Date >= &qPeriodFrom
	|	AND AddRooms.Date <= &qPeriodTo
	|	AND AddRooms.Hotel = &qHotel
	|	AND (AddRooms.Room.Company = &qCompany
	|					OR AddRooms.Room.Company = &qEmptyCompany)
	|	AND (AddRooms.RoomType.Company = &qCompany
	|					OR AddRooms.RoomType.Company = &qEmptyCompany)";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyCompany", Catalogs.Companies.EmptyRef());
	vQryResult = vQry.Execute().Unload();

	vPage3Area.Parameters.mNewRooms = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vPage3Area.Parameters.mNewRooms = vRow.NewRoomsCount;
	EndIf;
	
	// 3.3 Get total number of guest days and number of checked in guests
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SUM(ISNULL(RoomSales.GuestDaysTurnover, 0)) AS GuestDaysTurnover,
	|	SUM(ISNULL(RoomSales.GuestDays18Turnover, 0)) AS GuestDays18Turnover,
	|	SUM(ISNULL(RoomSales.GuestDays1855Turnover, 0)) AS GuestDays1855Turnover,
	|	SUM(ISNULL(RoomSales.GuestDays55Turnover, 0)) AS GuestDays55Turnover,
	|	SUM(ISNULL(RoomSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover,
	|	SUM(ISNULL(RoomSales.GuestsCheckedIn18Turnover, 0)) AS GuestsCheckedIn18Turnover,
	|	SUM(ISNULL(RoomSales.GuestsCheckedIn1855Turnover, 0)) AS GuestsCheckedIn1855Turnover,
	|	SUM(ISNULL(RoomSales.GuestsCheckedIn55Turnover, 0)) AS GuestsCheckedIn55Turnover
	|FROM
	|	(SELECT
	|		RoomSalesTurnovers.Client AS Client,
	|		RoomSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover,
	|		CASE
	|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND RoomSalesTurnovers.Client.Age < 18
	|				THEN RoomSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays18Turnover,
	|		CASE
	|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND RoomSalesTurnovers.Client.Age >= 18
	|					AND RoomSalesTurnovers.Client.Age < 55 
	|				THEN RoomSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays1855Turnover,
	|		CASE
	|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND RoomSalesTurnovers.Client.Age >= 55
	|				THEN RoomSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays55Turnover,
	|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
	|		CASE
	|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND RoomSalesTurnovers.Client.Age < 18
	|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn18Turnover,
	|		CASE
	|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND RoomSalesTurnovers.Client.Age >= 18
	|					AND RoomSalesTurnovers.Client.Age < 55
	|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn1855Turnover,
	|		CASE
	|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND RoomSalesTurnovers.Client.Age >= 55
	|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn55Turnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany) AS RoomSalesTurnovers) AS RoomSales";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyDate", '00010101');
	vQryResult = vQry.Execute().Unload();

	vTotalGuestDays = 0;
	vTotalGuestDays18 = 0;
	vTotalGuestDays1855 = 0;
	vTotalGuestDays55 = 0;
	vTotalGuests = 0;
	vTotalGuests18 = 0;
	vTotalGuests1855 = 0;
	vTotalGuests55 = 0;
	vPage3Area.Parameters.mTotalGuestDays = 0;
	vPage3Area.Parameters.mTotalGuestDays18 = 0;
	vPage3Area.Parameters.mTotalGuestDays1855 = 0;
	vPage3Area.Parameters.mTotalGuestDays55 = 0;
	vPage3Area.Parameters.mTotalGuests = 0;
	vPage3Area.Parameters.mTotalGuests18 = 0;
	vPage3Area.Parameters.mTotalGuests1855 = 0;
	vPage3Area.Parameters.mTotalGuests55 = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vPage3Area.Parameters.mTotalGuestDays = vRow.GuestDaysTurnover;
		vPage3Area.Parameters.mTotalGuestDays18 = vRow.GuestDays18Turnover;
		vPage3Area.Parameters.mTotalGuestDays1855 = vRow.GuestDays1855Turnover;
		vPage3Area.Parameters.mTotalGuestDays55 = vRow.GuestDays55Turnover;
		vPage3Area.Parameters.mTotalGuests = vRow.GuestsCheckedInTurnover;
		vPage3Area.Parameters.mTotalGuests18 = vRow.GuestsCheckedIn18Turnover;
		vPage3Area.Parameters.mTotalGuests1855 = vRow.GuestsCheckedIn1855Turnover;
		vPage3Area.Parameters.mTotalGuests55 = vRow.GuestsCheckedIn55Turnover;
		vTotalGuestDays = vRow.GuestDaysTurnover;
		vTotalGuestDays18 = vRow.GuestDays18Turnover;
		vTotalGuestDays1855 = vRow.GuestDays1855Turnover;
		vTotalGuestDays55 = vRow.GuestDays55Turnover;
		vTotalGuests = vRow.GuestsCheckedInTurnover;
		vTotalGuests18 = vRow.GuestsCheckedIn18Turnover;
		vTotalGuests1855 = vRow.GuestsCheckedIn1855Turnover;
		vTotalGuests55 = vRow.GuestsCheckedIn55Turnover;
	EndIf;
	
	// 3.4 Get total number of guest days and checked-in guests from Russia
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SUM(ISNULL(GeoSales.GuestDaysTurnover, 0)) AS GuestDaysTurnover,
	|	SUM(ISNULL(GeoSales.GuestDays18Turnover, 0)) AS GuestDays18Turnover,
	|	SUM(ISNULL(GeoSales.GuestDays1855Turnover, 0)) AS GuestDays1855Turnover,
	|	SUM(ISNULL(GeoSales.GuestDays55Turnover, 0)) AS GuestDays55Turnover,
	|	SUM(ISNULL(GeoSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover,
	|	SUM(ISNULL(GeoSales.GuestsCheckedIn18Turnover, 0)) AS GuestsCheckedIn18Turnover,
	|	SUM(ISNULL(GeoSales.GuestsCheckedIn1855Turnover, 0)) AS GuestsCheckedIn1855Turnover,
	|	SUM(ISNULL(GeoSales.GuestsCheckedIn55Turnover, 0)) AS GuestsCheckedIn55Turnover
	|FROM
	|	(SELECT
	|		GeoSalesTurnovers.Client AS Client,
	|		GeoSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age < 18
	|				THEN GeoSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays18Turnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age >= 18
	|					AND GeoSalesTurnovers.Client.Age < 55
	|				THEN GeoSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays1855Turnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age >= 55
	|				THEN GeoSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays55Turnover,
	|		GeoSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age < 18
	|				THEN GeoSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn18Turnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age >= 18
	|					AND GeoSalesTurnovers.Client.Age < 55
	|				THEN GeoSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn1855Turnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age >= 55
	|				THEN GeoSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn55Turnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND (Client.Citizenship = &qRussia
	|						OR ISNULL(Client.Citizenship.Description, """") = """")) AS GeoSalesTurnovers) AS GeoSales";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyDate", '00010101');
	vQryResult = vQry.Execute().Unload();

	vRussiaGuestDays = 0;
	vRussiaGuestDays18 = 0;
	vRussiaGuestDays1855 = 0;
	vRussiaGuestDays55 = 0;
	vRussiaGuests = 0;
	vRussiaGuests18 = 0;
	vRussiaGuests1855 = 0;
	vRussiaGuests55 = 0;
	vPage3Area.Parameters.mTotalGuestDaysRus = 0;
	vPage3Area.Parameters.mTotalGuestDaysRus18 = 0;
	vPage3Area.Parameters.mTotalGuestDaysRus1855 = 0;
	vPage3Area.Parameters.mTotalGuestDaysRus55 = 0;
	vPage3Area.Parameters.mTotalGuestsRus = 0;
	vPage3Area.Parameters.mTotalGuestsRus18 = 0;
	vPage3Area.Parameters.mTotalGuestsRus1855 = 0;
	vPage3Area.Parameters.mTotalGuestsRus55 = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vPage3Area.Parameters.mTotalGuestDaysRus = vRow.GuestDaysTurnover;
		vPage3Area.Parameters.mTotalGuestDaysRus18 = vRow.GuestDays18Turnover;
		vPage3Area.Parameters.mTotalGuestDaysRus1855 = vRow.GuestDays1855Turnover;
		vPage3Area.Parameters.mTotalGuestDaysRus55 = vRow.GuestDays55Turnover;
		vPage3Area.Parameters.mTotalGuestsRus = vRow.GuestsCheckedInTurnover;
		vPage3Area.Parameters.mTotalGuestsRus18 = vRow.GuestsCheckedIn18Turnover;
		vPage3Area.Parameters.mTotalGuestsRus1855 = vRow.GuestsCheckedIn1855Turnover;
		vPage3Area.Parameters.mTotalGuestsRus55 = vRow.GuestsCheckedIn55Turnover;
		vRussiaGuestDays = vRow.GuestDaysTurnover;
		vRussiaGuestDays18 = vRow.GuestDays18Turnover;
		vRussiaGuestDays1855 = vRow.GuestDays1855Turnover;
		vRussiaGuestDays55 = vRow.GuestDays55Turnover;
		vRussiaGuests = vRow.GuestsCheckedInTurnover;
		vRussiaGuests18 = vRow.GuestsCheckedIn18Turnover;
		vRussiaGuests1855 = vRow.GuestsCheckedIn1855Turnover;
		vRussiaGuests55 = vRow.GuestsCheckedIn55Turnover;
	EndIf;
	
	// 3.5 Get total number of guest days and checked-in foreigner guests
	If vTotalGuests <> Null And vRussiaGuests <> Null Then
		vPage3Area.Parameters.mTotalGuestDaysForeigners = vTotalGuestDays - vRussiaGuestDays;
		vPage3Area.Parameters.mTotalGuestDaysForeigners18 = vTotalGuestDays18 - vRussiaGuestDays18;
		vPage3Area.Parameters.mTotalGuestDaysForeigners1855 = vTotalGuestDays1855 - vRussiaGuestDays1855;
		vPage3Area.Parameters.mTotalGuestDaysForeigners55 = vTotalGuestDays55 - vRussiaGuestDays55;
		vPage3Area.Parameters.mTotalGuestsForeigners = vTotalGuests - vRussiaGuests;
		vPage3Area.Parameters.mTotalGuestsForeigners18 = vTotalGuests18 - vRussiaGuests18;
		vPage3Area.Parameters.mTotalGuestsForeigners1855 = vTotalGuests1855 - vRussiaGuests1855;
		vPage3Area.Parameters.mTotalGuestsForeigners55 = vTotalGuests55 - vRussiaGuests55;
	Else
		vPage3Area.Parameters.mTotalGuestDaysForeigners = 0;
		vPage3Area.Parameters.mTotalGuestDaysForeigners18 = 0;
		vPage3Area.Parameters.mTotalGuestDaysForeigners1855 = 0;
		vPage3Area.Parameters.mTotalGuestDaysForeigners55 = 0;
		vPage3Area.Parameters.mTotalGuestsForeigners = 0;
		vPage3Area.Parameters.mTotalGuestsForeigners18 = 0;
		vPage3Area.Parameters.mTotalGuestsForeigners1855 = 0;
		vPage3Area.Parameters.mTotalGuestsForeigners55 = 0;
	EndIf;
	
	// 3.6 Get total number of checked-in guests with tour tickets
	vPage3Area.Parameters.mTotalTourTicketGuests = 0;
	vPage3Area.Parameters.mTotalTourTicketGuests18 = 0;
	vPage3Area.Parameters.mTotalTourTicketGuests1855 = 0;
	vPage3Area.Parameters.mTotalTourTicketGuests55 = 0;
	If ValueIsFilled(TourTicketIncomeServiceGroup) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	SUM(ISNULL(RoomSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover,
		|	SUM(ISNULL(RoomSales.GuestsCheckedIn18Turnover, 0)) AS GuestsCheckedIn18Turnover,
		|	SUM(ISNULL(RoomSales.GuestsCheckedIn1855Turnover, 0)) AS GuestsCheckedIn1855Turnover,
		|	SUM(ISNULL(RoomSales.GuestsCheckedIn55Turnover, 0)) AS GuestsCheckedIn55Turnover
		|FROM
		|	(SELECT
		|		RoomSalesTurnovers.Client AS Client,
		|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
		|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					AND RoomSalesTurnovers.Client.Age < 18
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			ELSE 0
		|		END AS GuestsCheckedIn18Turnover,
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
		|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					AND RoomSalesTurnovers.Client.Age >= 18
		|					AND RoomSalesTurnovers.Client.Age < 55
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			ELSE 0
		|		END AS GuestsCheckedIn1855Turnover,
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
		|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					AND RoomSalesTurnovers.Client.Age >= 55
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			ELSE 0
		|		END AS GuestsCheckedIn55Turnover
		|	FROM
		|		AccumulationRegister.Sales.Turnovers(
		|				&qPeriodFrom,
		|				&qPeriodTo,
		|				Period,
		|				NOT IsCorrection AND Hotel = &qHotel
		|					AND Company = &qCompany
		|					AND (Service IN HIERARCHY (&qTourTicketServices)
		|						OR NOT &qUseServicesList)
		|					) AS RoomSalesTurnovers) AS RoomSales";
		vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qCompany", Company);
		vUseServicesList = False;
		vServicesList = New ValueList();
		If Not TourTicketIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(TourTicketIncomeServiceGroup);
		EndIf;
		vQry.SetParameter("qUseServicesList", vUseServicesList);
		vQry.SetParameter("qTourTicketServices", vServicesList);
		vQry.SetParameter("qEmptyDate", '00010101');
		vQryResult = vQry.Execute().Unload();

		If vQryResult.Count() > 0 Then
			vRow = vQryResult.Get(0);
			
			vPage3Area.Parameters.mTotalTourTicketGuests = vRow.GuestsCheckedInTurnover;
			vPage3Area.Parameters.mTotalTourTicketGuests18 = vRow.GuestsCheckedIn18Turnover;
			vPage3Area.Parameters.mTotalTourTicketGuests1855 = vRow.GuestsCheckedIn1855Turnover;
			vPage3Area.Parameters.mTotalTourTicketGuests55 = vRow.GuestsCheckedIn55Turnover;
		EndIf;
		
		// The same from russia
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	SUM(ISNULL(RoomSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover,
		|	SUM(ISNULL(RoomSales.GuestsCheckedIn18Turnover, 0)) AS GuestsCheckedIn18Turnover,
		|	SUM(ISNULL(RoomSales.GuestsCheckedIn1855Turnover, 0)) AS GuestsCheckedIn1855Turnover,
		|	SUM(ISNULL(RoomSales.GuestsCheckedIn55Turnover, 0)) AS GuestsCheckedIn55Turnover
		|FROM
		|	(SELECT
		|		RoomSalesTurnovers.Client AS Client,
		|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL
		|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					AND RoomSalesTurnovers.Client.Age < 18
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			ELSE 0
		|		END AS GuestsCheckedIn18Turnover,
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL
		|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					AND RoomSalesTurnovers.Client.Age >= 18
		|					AND RoomSalesTurnovers.Client.Age < 55
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			ELSE 0
		|		END AS GuestsCheckedIn1855Turnover,
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL
		|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					AND RoomSalesTurnovers.Client.Age >= 55
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			ELSE 0
		|		END AS GuestsCheckedIn55Turnover
		|	FROM
		|		AccumulationRegister.Sales.Turnovers(
		|				&qPeriodFrom,
		|				&qPeriodTo,
		|				Period,
		|				NOT IsCorrection
		|					AND Hotel = &qHotel
		|					AND Company = &qCompany
		|					AND (Service IN HIERARCHY (&qTourTicketServices)
		|						OR NOT &qUseServicesList)
		|					AND (Client.Citizenship = &qRussia
		|						OR ISNULL(Client.Citizenship.Description, """") = """")) AS RoomSalesTurnovers) AS RoomSales";
		vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qRussia", RussiaCountry);
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qCompany", Company);
		vUseServicesList = False;
		vServicesList = New ValueList();
		If Not TourTicketIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(TourTicketIncomeServiceGroup);
		EndIf;
		vQry.SetParameter("qUseServicesList", vUseServicesList);
		vQry.SetParameter("qTourTicketServices", vServicesList);
		vQry.SetParameter("qEmptyDate", '00010101');
		vQryResult = vQry.Execute().Unload();

		If vQryResult.Count() > 0 Then
			vRow = vQryResult.Get(0);
			vPage3Area.Parameters.mTotalTourTicketGuestsRus = ?(vRow.GuestsCheckedInTurnover = Null, 0, vRow.GuestsCheckedInTurnover);
			vPage3Area.Parameters.mTotalTourTicketGuestsRus18 = ?(vRow.GuestsCheckedIn18Turnover = Null, 0, vRow.GuestsCheckedIn18Turnover);
			vPage3Area.Parameters.mTotalTourTicketGuestsRus1855 = ?(vRow.GuestsCheckedIn1855Turnover = Null, 0, vRow.GuestsCheckedIn1855Turnover);
			vPage3Area.Parameters.mTotalTourTicketGuestsRus55 = ?(vRow.GuestsCheckedIn55Turnover = Null, 0, vRow.GuestsCheckedIn55Turnover);
			
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners = ?(vPage3Area.Parameters.mTotalTourTicketGuests = Null, 0, vPage3Area.Parameters.mTotalTourTicketGuests) - ?(vRow.GuestsCheckedInTurnover = Null, 0, vRow.GuestsCheckedInTurnover);
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners18 = ?(vPage3Area.Parameters.mTotalTourTicketGuests18 = Null, 0, vPage3Area.Parameters.mTotalTourTicketGuests18) - ?(vRow.GuestsCheckedIn18Turnover = Null, 0, vRow.GuestsCheckedIn18Turnover);
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners1855 = ?(vPage3Area.Parameters.mTotalTourTicketGuests1855 = Null, 0, vPage3Area.Parameters.mTotalTourTicketGuests1855) - ?(vRow.GuestsCheckedIn1855Turnover = Null, 0, vRow.GuestsCheckedIn1855Turnover);
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners55 = ?(vPage3Area.Parameters.mTotalTourTicketGuests55 = Null, 0, vPage3Area.Parameters.mTotalTourTicketGuests55) - ?(vRow.GuestsCheckedIn55Turnover = Null, 0, vRow.GuestsCheckedIn55Turnover);
		Else
			vPage3Area.Parameters.mTotalTourTicketGuestsRus = 0;
			vPage3Area.Parameters.mTotalTourTicketGuestsRus18 = 0;
			vPage3Area.Parameters.mTotalTourTicketGuestsRus1855 = 0;
			vPage3Area.Parameters.mTotalTourTicketGuestsRus55 = 0;
			
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners = 0;
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners18 = 0;
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners1855 = 0;
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners55 = 0;
		EndIf;
	EndIf;
	
	pSpreadsheet.Put(vPage3Area);
	
	// Page 3 header Spr. 1
	pSpreadsheet.Put(vPage3H1Area);
	
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ISNULL(GeoSales.Client.Citizenship.Description, """") AS CountryDescription,
	|	ISNULL(GeoSales.Client.Citizenship.Code, 0) AS CountryCode,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			NOT IsCorrection AND Hotel = &qHotel
	|				AND Company = &qCompany
	|				AND Client.Citizenship <> &qRussia
	|				AND ISNULL(Client.Citizenship.Description, """") <> """") AS GeoSales
	|
	|GROUP BY
	|	GeoSales.Client.Citizenship.Description,
	|	GeoSales.Client.Citizenship.Code
	|
	|ORDER BY
	|	GeoSales.Client.Citizenship.Code";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQryResult = vQry.Execute().Unload();
	c = 0;
	While c < vQryResult.Count() Do
		vQryResultRow = vQryResult.Get(c);
		
		vPage3H1RowArea.Parameters.mCountry = TrimAll(vQryResultRow.CountryDescription);
		vPage3H1RowArea.Parameters.mCountryCode = TrimAll(vQryResultRow.CountryCode);
		vPage3H1RowArea.Parameters.mCountryGuests = vQryResultRow.GuestsCheckedInTurnover;
		
		pSpreadsheet.Put(vPage3H1RowArea);
		
		c = c + 1;
	EndDo;
	
	// Get number of checked in guests by hotel products (Page 3. Spr 2)
	vPage3H2Area.Parameters.mVaucherQuantity = 0;
	vPage3H2Area.Parameters.mVaucher18Quantity = 0;
	vPage3H2Area.Parameters.mVaucher1855Quantity = 0;
	vPage3H2Area.Parameters.mVaucher55Quantity = 0;
	
	If ValueIsFilled(VaucherIncomeServiceGroup) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	SUM(AgeSales.VaucherQuantity) AS VaucherQuantity,
		|	SUM(AgeSales.Vaucher18Quantity) AS Vaucher18Quantity,
		|	SUM(AgeSales.Vaucher1855Quantity) AS Vaucher1855Quantity,
		|	SUM(AgeSales.Vaucher55Quantity) AS Vaucher55Quantity
		|FROM
		|	(SELECT
		|		RoomSalesTurnovers.Client AS Client,
		|		RoomSalesTurnovers.Client.Age AS ClientAge,
		|		MAX(1) AS VaucherQuantity,
		|		MAX(CASE
		|				WHEN RoomSalesTurnovers.Client.Age < 18
		|						AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					THEN 1
		|				ELSE 0
		|			END) AS Vaucher18Quantity,
		|		MAX(CASE
		|				WHEN RoomSalesTurnovers.Client.Age >= 18
		|				WHEN RoomSalesTurnovers.Client.Age < 54
		|						AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					THEN 1
		|				ELSE 0
		|			END) AS Vaucher1855Quantity,
		|		MAX(CASE
		|				WHEN RoomSalesTurnovers.Client.Age >= 55
		|					THEN 1
		|				ELSE 0
		|			END) AS Vaucher55Quantity
		|	FROM
		|		AccumulationRegister.Sales.Turnovers(
		|				&qPeriodFrom,
		|				&qPeriodTo,
		|				Period,
		|				NOT IsCorrection AND Hotel = &qHotel
		|					AND Company = &qCompany
		|					AND (Service IN HIERARCHY (&qVaucherServices)
		|						OR NOT &qUseServicesList)) AS RoomSalesTurnovers
		|	
		|	GROUP BY
		|		RoomSalesTurnovers.Client,
		|		RoomSalesTurnovers.Client.Age) AS AgeSales";
		vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qCompany", Company);
		vQry.SetParameter("qEmptyDate", '00010101');
		vUseServicesList = False;
		vServicesList = New ValueList();
		If Not TourTicketIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(VaucherIncomeServiceGroup);
		EndIf;
		vQry.SetParameter("qUseServicesList", vUseServicesList);
		vQry.SetParameter("qVaucherServices", vServicesList);
		vQryResult = vQry.Execute().Unload();

		If vQryResult.Count() > 0 Then
			vRow = vQryResult.Get(0);
			
			vPage3H2Area.Parameters.mVaucherQuantity = vRow.VaucherQuantity;
			vPage3H2Area.Parameters.mVaucher18Quantity = vRow.Vaucher18Quantity;
			vPage3H2Area.Parameters.mVaucher1855Quantity = vRow.Vaucher1855Quantity;
			vPage3H2Area.Parameters.mVaucher55Quantity = vRow.Vaucher55Quantity;
		EndIf;
	EndIf;
	
	pSpreadsheet.Put(vPage3H2Area);
	
	pSpreadsheet.PutHorizontalPageBreak();
	
	// Page 4
	
	// 4.1.1 Get total number of russian checked-in guests per trip purposes
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qStudy
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qOther
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTransit
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qRecreation
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qPilgrims
	|			THEN 4
	|		WHEN GeoSales.TripPurpose = &qShopping
	|			THEN 5
	|		ELSE 5
	|	END AS TripPurposeType,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		GeoSalesTurnovers.TripPurpose AS TripPurpose,
	|		SUM(GeoSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND (Client.Citizenship = &qRussia
	|						OR ISNULL(Client.Citizenship.Description, """") = """")) AS GeoSalesTurnovers
	|	
	|	GROUP BY
	|		GeoSalesTurnovers.TripPurpose) AS GeoSales
	|
	|GROUP BY
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qStudy
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qOther
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTransit
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qRecreation
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qPilgrims
	|			THEN 4
	|		WHEN GeoSales.TripPurpose = &qShopping
	|			THEN 5
	|		ELSE 5
	|	END
	|
	|ORDER BY
	|	TripPurposeType";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qBusiness", Catalogs.TripPurposes.Business);
	vQry.SetParameter("qCommerce", Catalogs.TripPurposes.Commerce);
	vQry.SetParameter("qOfficial", Catalogs.TripPurposes.Official);
	vQry.SetParameter("qWork", Catalogs.TripPurposes.Work);
	vQry.SetParameter("qCrewman", Catalogs.TripPurposes.Crewman);
	vQry.SetParameter("qHumanitarian", Catalogs.TripPurposes.Humanitarian);
	vQry.SetParameter("qTourism", Catalogs.TripPurposes.Tourism);
	vQry.SetParameter("qPrivate", Catalogs.TripPurposes.Private);
	vQry.SetParameter("qScientific", Catalogs.TripPurposes.Scientific);
	vQry.SetParameter("qStudy", Catalogs.TripPurposes.Study);
	vQry.SetParameter("qRecreation", Catalogs.TripPurposes.Recreation);
	vQry.SetParameter("qShopping", Catalogs.TripPurposes.Shopping);
	vQry.SetParameter("qPilgrims", Catalogs.TripPurposes.Pilgrims);
	vQry.SetParameter("qTransit", Catalogs.TripPurposes.Transit);
	vQry.SetParameter("qOther", Catalogs.TripPurposes.Other);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyCountry", Catalogs.Countries.EmptyRef());
	vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vQry.SetParameter("qEmptyCountry", Catalogs.Countries.EmptyRef());
	vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vQryResult = vQry.Execute().Unload();
	
	vPage4Area.Parameters.mGuestsTouristsRus = 0;
	vPage4Area.Parameters.mGuestsEducationRus = 0;
	vPage4Area.Parameters.mGuestsBusinessRus = 0;
	vPage4Area.Parameters.mGuestsCureRus = 0;
	vPage4Area.Parameters.mGuestsPilgrimRus = 0;
	vPage4Area.Parameters.mGuestsOtherRus = 0;

	For Each vRow In vQryResult Do
		If vRow.TripPurposeType = 1 Then
			vPage4Area.Parameters.mGuestsTouristsRus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 2 Then
			vPage4Area.Parameters.mGuestsEducationRus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 6 Then
			vPage4Area.Parameters.mGuestsBusinessRus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 3 Then
			vPage4Area.Parameters.mGuestsCureRus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 4 Then
			vPage4Area.Parameters.mGuestsPilgrimRus = vRow.GuestsCheckedInTurnover;
		Else
			vPage4Area.Parameters.mGuestsOtherRus = vRow.GuestsCheckedInTurnover;
		EndIf;
	EndDo;
	
	// 4.1.4 Get total number of checked-in foreigner guests per trip purposes
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qStudy
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qOther
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTransit
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qRecreation
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qPilgrims
	|			THEN 4
	|		WHEN GeoSales.TripPurpose = &qShopping
	|			THEN 5
	|		ELSE 5
	|	END AS TripPurposeType,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		GeoSalesTurnovers.TripPurpose AS TripPurpose,
	|		SUM(GeoSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND Client.Citizenship <> &qRussia
	|					AND ISNULL(Client.Citizenship.Description, """") <> """") AS GeoSalesTurnovers
	|	
	|	GROUP BY
	|		GeoSalesTurnovers.TripPurpose) AS GeoSales
	|
	|GROUP BY
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qStudy
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qOther
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTransit
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qRecreation
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qPilgrims
	|			THEN 4
	|		WHEN GeoSales.TripPurpose = &qShopping
	|			THEN 5
	|		ELSE 5
	|	END
	|
	|ORDER BY
	|	TripPurposeType";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qBusiness", Catalogs.TripPurposes.Business);
	vQry.SetParameter("qCommerce", Catalogs.TripPurposes.Commerce);
	vQry.SetParameter("qOfficial", Catalogs.TripPurposes.Official);
	vQry.SetParameter("qWork", Catalogs.TripPurposes.Work);
	vQry.SetParameter("qCrewman", Catalogs.TripPurposes.Crewman);
	vQry.SetParameter("qHumanitarian", Catalogs.TripPurposes.Humanitarian);
	vQry.SetParameter("qTourism", Catalogs.TripPurposes.Tourism);
	vQry.SetParameter("qPrivate", Catalogs.TripPurposes.Private);
	vQry.SetParameter("qScientific", Catalogs.TripPurposes.Scientific);
	vQry.SetParameter("qStudy", Catalogs.TripPurposes.Study);
	vQry.SetParameter("qRecreation", Catalogs.TripPurposes.Recreation);
	vQry.SetParameter("qShopping", Catalogs.TripPurposes.Shopping);
	vQry.SetParameter("qPilgrims", Catalogs.TripPurposes.Pilgrims);
	vQry.SetParameter("qTransit", Catalogs.TripPurposes.Transit);
	vQry.SetParameter("qOther", Catalogs.TripPurposes.Other);
	vQry.SetParameter("qCompany", Company);
	vQryResult = vQry.Execute().Unload();
	
	vPage4Area.Parameters.mGuestsTouristsForeigners = 0;
	vPage4Area.Parameters.mGuestsEducationForeigners = 0;
	vPage4Area.Parameters.mGuestsBusinessForeigners = 0;
	vPage4Area.Parameters.mGuestsCureForeigners = 0;
	vPage4Area.Parameters.mGuestsPilgrimForeigners = 0;
	vPage4Area.Parameters.mGuestsOtherForeigners = 0;

	For Each vRow In vQryResult Do
		If vRow.TripPurposeType = 1 Then
			vPage4Area.Parameters.mGuestsTouristsForeigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 2 Then
			vPage4Area.Parameters.mGuestsEducationForeigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 6 Then
			vPage4Area.Parameters.mGuestsBusinessForeigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 3 Then
			vPage4Area.Parameters.mGuestsCureForeigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 4 Then
			vPage4Area.Parameters.mGuestsPilgrimForeigners = vRow.GuestsCheckedInTurnover;
		Else
			vPage4Area.Parameters.mGuestsOtherForeigners = vRow.GuestsCheckedInTurnover;
		EndIf;
	EndDo;
	
	// 4.2.1 Get total number of russian checked-in guests per duration
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 0
	|		WHEN GeoSales.Duration < 5
	|			THEN 4
	|		WHEN GeoSales.Duration < 8
	|			THEN 7
	|		WHEN GeoSales.Duration < 15
	|			THEN 14
	|		WHEN GeoSales.Duration < 29
	|			THEN 28
	|		WHEN GeoSales.Duration < 91
	|			THEN 90
	|		WHEN GeoSales.Duration < 183
	|			THEN 182
	|		ELSE 183
	|	END AS DurationType,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0) AS Duration,
	|		SUM(GeoSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND (Client.Citizenship = &qRussia
	|						OR ISNULL(Client.Citizenship.Description, """") = """")) AS GeoSalesTurnovers
	|	
	|	GROUP BY
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0)) AS GeoSales
	|
	|GROUP BY
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 0
	|		WHEN GeoSales.Duration < 5
	|			THEN 4
	|		WHEN GeoSales.Duration < 8
	|			THEN 7
	|		WHEN GeoSales.Duration < 15
	|			THEN 14
	|		WHEN GeoSales.Duration < 29
	|			THEN 28
	|		WHEN GeoSales.Duration < 91
	|			THEN 90
	|		WHEN GeoSales.Duration < 183
	|			THEN 182
	|		ELSE 183
	|	END
	|
	|ORDER BY
	|	DurationType";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyCountry", Catalogs.Countries.EmptyRef());
	vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vQryResult = vQry.Execute().Unload();
	
	vPage4Area.Parameters.mGuests0Rus = 0;
	vPage4Area.Parameters.mGuests1_4Rus = 0;
	vPage4Area.Parameters.mGuests5_7Rus = 0;
	vPage4Area.Parameters.mGuests8_14Rus = 0;
	vPage4Area.Parameters.mGuests15_28Rus = 0;
	vPage4Area.Parameters.mGuests29_90Rus = 0;
	vPage4Area.Parameters.mGuests91_182Rus = 0;
	vPage4Area.Parameters.mGuests183Rus = 0;

	For Each vRow In vQryResult Do
		If vRow.DurationType = 0 Then
			vPage4Area.Parameters.mGuests0Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 4 Then
			vPage4Area.Parameters.mGuests1_4Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 7 Then
			vPage4Area.Parameters.mGuests5_7Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 14 Then
			vPage4Area.Parameters.mGuests8_14Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 28 Then
			vPage4Area.Parameters.mGuests15_28Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 90 Then
			vPage4Area.Parameters.mGuests29_90Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 182 Then
			vPage4Area.Parameters.mGuests91_182Rus = vRow.GuestsCheckedInTurnover;
		Else
			vPage4Area.Parameters.mGuests183Rus = vRow.GuestsCheckedInTurnover;
		EndIf;
	EndDo;
	
	// 4.2.2 Get total number of foreigner checked-in guests per duration
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 0
	|		WHEN GeoSales.Duration < 5
	|			THEN 4
	|		WHEN GeoSales.Duration < 8
	|			THEN 7
	|		WHEN GeoSales.Duration < 15
	|			THEN 14
	|		WHEN GeoSales.Duration < 29
	|			THEN 28
	|		WHEN GeoSales.Duration < 91
	|			THEN 90
	|		WHEN GeoSales.Duration < 183
	|			THEN 182
	|		ELSE 183
	|	END AS DurationType,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0) AS Duration,
	|		SUM(GeoSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND Client.Citizenship <> &qRussia
	|					AND ISNULL(Client.Citizenship.Description, """") <> """") AS GeoSalesTurnovers
	|	
	|	GROUP BY
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0)) AS GeoSales
	|
	|GROUP BY
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 0
	|		WHEN GeoSales.Duration < 5
	|			THEN 4
	|		WHEN GeoSales.Duration < 8
	|			THEN 7
	|		WHEN GeoSales.Duration < 15
	|			THEN 14
	|		WHEN GeoSales.Duration < 29
	|			THEN 28
	|		WHEN GeoSales.Duration < 91
	|			THEN 90
	|		WHEN GeoSales.Duration < 183
	|			THEN 182
	|		ELSE 183
	|	END
	|
	|ORDER BY
	|	DurationType";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qCompany", Company);
	vQryResult = vQry.Execute().Unload();
	
	vPage4Area.Parameters.mGuests0Foreigners = 0;
	vPage4Area.Parameters.mGuests1_4Foreigners = 0;
	vPage4Area.Parameters.mGuests5_7Foreigners = 0;
	vPage4Area.Parameters.mGuests8_14Foreigners = 0;
	vPage4Area.Parameters.mGuests15_28Foreigners = 0;
	vPage4Area.Parameters.mGuests29_90Foreigners = 0;
	vPage4Area.Parameters.mGuests91_182Foreigners = 0;
	vPage4Area.Parameters.mGuests183Foreigners = 0;

	For Each vRow In vQryResult Do
		If vRow.DurationType = 0 Then
			vPage4Area.Parameters.mGuests0Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 4 Then
			vPage4Area.Parameters.mGuests1_4Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 7 Then
			vPage4Area.Parameters.mGuests5_7Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 14 Then
			vPage4Area.Parameters.mGuests8_14Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 28 Then
			vPage4Area.Parameters.mGuests15_28Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 90 Then
			vPage4Area.Parameters.mGuests29_90Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 182 Then
			vPage4Area.Parameters.mGuests91_182Foreigners = vRow.GuestsCheckedInTurnover;
		Else
			vPage4Area.Parameters.mGuests183Foreigners = vRow.GuestsCheckedInTurnover;
		EndIf;
	EndDo;
	
	pSpreadsheet.Put(vPage4Area);
	pSpreadsheet.PutHorizontalPageBreak();
	
	// Page 5
	
	// 7.1 Get total sales
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomSalesTurnovers.RoomRevenueWithoutVATTurnover,
	|	RoomSalesTurnovers.SalesWithoutVATTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			NOT IsCorrection AND Hotel = &qHotel
	|				AND Company = &qCompany
	|				AND (Service IN HIERARCHY (&qIncomeServices)
	|					OR (NOT &qUseServicesList))) AS RoomSalesTurnovers";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vUseServicesList = False;
	vServicesList = New ValueList();
	If ValueIsFilled(TotalIncomeServiceGroup) Then
		If Not TotalIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(TotalIncomeServiceGroup);
		EndIf;
	EndIf;
	vQry.SetParameter("qUseServicesList", vUseServicesList);
	vQry.SetParameter("qIncomeServices", vServicesList);
	vQryResult = vQry.Execute().Unload();

	vTotalIncome = 0;
	vPage5Area.Parameters.mTotalIncome = 0;
	vPage5Area.Parameters.mTotalRoomRevenueIncome = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vTotalIncome = Round(vRow.SalesWithoutVATTurnover/1000, 1);
		vPage5Area.Parameters.mTotalIncome = vTotalIncome;
		vTotalRoomRevenueIncome = Round(vRow.RoomRevenueWithoutVATTurnover/1000, 1);
		vPage5Area.Parameters.mTotalRoomRevenueIncome = vTotalRoomRevenueIncome;
	EndIf;
	
	// 7.2 Get total meals sales
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomSalesTurnovers.SalesWithoutVATTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			NOT IsCorrection AND Hotel = &qHotel
	|				AND Company = &qCompany
	|				AND (Service IN HIERARCHY (&qIncomeServices)
	|					OR (NOT &qUseServicesList))) AS RoomSalesTurnovers";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vUseServicesList = False;
	vServicesList = New ValueList();
	If ValueIsFilled(MealIncomeServiceGroup) Then
		If Not MealIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(MealIncomeServiceGroup);
		EndIf;
	EndIf;
	vQry.SetParameter("qUseServicesList", vUseServicesList);
	vQry.SetParameter("qIncomeServices", vServicesList);
	vQryResult = vQry.Execute().Unload();
	
	vTotalMealsIncome = 0;
	vPage5Area.Parameters.mTotalMealsIncome = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vTotalMealsIncome = Round(vRow.SalesWithoutVATTurnover/1000, 1);
		vPage5Area.Parameters.mTotalMealsIncome = vTotalMealsIncome;
	EndIf;
	
	pSpreadsheet.Put(vPage5Area);
	pSpreadsheet.PutHorizontalPageBreak();
EndProcedure // pmGenerate2023

// -----------------------------------------------------------------------------
Procedure pmGenerate2024(pSpreadsheet) Export
	// Clear output spreadsheet
	pSpreadsheet.Clear();
	
	// Choose template
	vTemplate = ThisObject.GetTemplate("Report2024");
	
	// Report pages
	vPage1Area = vTemplate.GetArea("Page1");
	vPage2Area = vTemplate.GetArea("Page2");
	vPage3Area = vTemplate.GetArea("Page3");
	vPage3H1Area = vTemplate.GetArea("Page3H1");
	vPage3H1RowArea = vTemplate.GetArea("Page3H1Row");
	vPage3H2Area = vTemplate.GetArea("Page3H2");
	vPage4Area = vTemplate.GetArea("Page4");
	vPage5Area = vTemplate.GetArea("Page5");
	
	// Page 1
	vPage1Area.Parameters.mPeriodStr = PeriodPresentation(BegOfDay(PeriodFrom), EndOfDay(PeriodTo), cmLocalizationCode());
	vPage1Area.Parameters.mHotelName = TrimAll(Hotel.LegacyName);
	vPage1Area.Parameters.mHotelPostAddress = cmGetAddressPresentation(Hotel.PostAddress);
	vPage1Area.Parameters.mCompanyName = TrimAll(Company.LegacyName);
	vPage1Area.Parameters.mCompanyPostAddress = cmGetAddressPresentation(Company.PostAddress);
	vPage1Area.Parameters.mCompanyOKPOCode = TrimAll(Company.OKPO);
	pSpreadsheet.Put(vPage1Area);
	pSpreadsheet.PutHorizontalPageBreak();
	
	// Page 2
	pSpreadsheet.Put(vPage2Area);
	pSpreadsheet.PutHorizontalPageBreak();
	
	// Page 3
	
	// 3.1 Get total number of rooms/beds per end of period
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInventoryBalance.TotalRoomsBalance AS TotalRoomsBalance,
	|	RoomInventoryBalance.TotalBedsBalance AS TotalBedsBalance
	|FROM
	|	AccumulationRegister.RoomInventory.Balance(
	|			&qPeriodTo,
	|			Hotel = &qHotel
	|				AND (Room.Company = &qCompany
	|					OR Room.Company = &qEmptyCompany)
	|				AND (RoomType.Company = &qCompany
	|					OR RoomType.Company = &qEmptyCompany)) AS RoomInventoryBalance";
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyCompany", Catalogs.Companies.EmptyRef());
	vQryResult = vQry.Execute().Unload();

	vPage3Area.Parameters.mTotalRooms = 0;
	vPage3Area.Parameters.mTotalBeds = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vPage3Area.Parameters.mTotalRooms = vRow.TotalRoomsBalance;
		vPage3Area.Parameters.mTotalBeds = vRow.TotalBedsBalance;
	EndIf;
	
	// 3.2 Get total number of rooms/beds for top room types per end of period
	vPage3Area.Parameters.mTotalTopRooms = 0;
	If ValueIsFilled(TopRoomTypes) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	RoomInventoryBalance.TotalRoomsBalance AS TotalRoomsBalance,
		|	RoomInventoryBalance.TotalBedsBalance AS TotalBedsBalance
		|FROM
		|	AccumulationRegister.RoomInventory.Balance(
		|			&qPeriodTo,
		|			Hotel = &qHotel
		|				AND RoomType IN HIERARCHY (&qTopRoomTypes)
		|				AND (Room.Company = &qCompany
		|					OR Room.Company = &qEmptyCompany)
		|				AND (RoomType.Company = &qCompany
		|					OR RoomType.Company = &qEmptyCompany)) AS RoomInventoryBalance";
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qCompany", Company);
		vQry.SetParameter("qEmptyCompany", Catalogs.Companies.EmptyRef());
		vQry.SetParameter("qTopRoomTypes", TopRoomTypes);
		vQryResult = vQry.Execute().Unload();

		If vQryResult.Count() > 0 Then
			vRow = vQryResult.Get(0);
			vPage3Area.Parameters.mTotalTopRooms = vRow.TotalRoomsBalance;
		EndIf;
	EndIf;

	// Get number of new rooms added in period
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	COUNT(AddRooms.Ref) AS NewRoomsCount
	|FROM
	|	Document.AddRoom AS AddRooms
	|WHERE
	|	AddRooms.Date >= &qPeriodFrom
	|	AND AddRooms.Date <= &qPeriodTo
	|	AND AddRooms.Hotel = &qHotel
	|	AND (AddRooms.Room.Company = &qCompany
	|					OR AddRooms.Room.Company = &qEmptyCompany)
	|	AND (AddRooms.RoomType.Company = &qCompany
	|					OR AddRooms.RoomType.Company = &qEmptyCompany)";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyCompany", Catalogs.Companies.EmptyRef());
	vQryResult = vQry.Execute().Unload();

	vPage3Area.Parameters.mNewRooms = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vPage3Area.Parameters.mNewRooms = vRow.NewRoomsCount;
	EndIf;
	
	// 3.3 Get total number of guest days and number of checked in guests
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SUM(ISNULL(RoomSales.GuestDaysTurnover, 0)) AS GuestDaysTurnover,
	|	SUM(ISNULL(RoomSales.GuestDays18Turnover, 0)) AS GuestDays18Turnover,
	|	SUM(ISNULL(RoomSales.GuestDays1855Turnover, 0)) AS GuestDays1855Turnover,
	|	SUM(ISNULL(RoomSales.GuestDays55Turnover, 0)) AS GuestDays55Turnover,
	|	SUM(ISNULL(RoomSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover,
	|	SUM(ISNULL(RoomSales.GuestsCheckedIn18Turnover, 0)) AS GuestsCheckedIn18Turnover,
	|	SUM(ISNULL(RoomSales.GuestsCheckedIn1855Turnover, 0)) AS GuestsCheckedIn1855Turnover,
	|	SUM(ISNULL(RoomSales.GuestsCheckedIn55Turnover, 0)) AS GuestsCheckedIn55Turnover
	|FROM
	|	(SELECT
	|		RoomSalesTurnovers.Client AS Client,
	|		RoomSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover,
	|		CASE
	|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND RoomSalesTurnovers.Client.Age < 18
	|				THEN RoomSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays18Turnover,
	|		CASE
	|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND RoomSalesTurnovers.Client.Age >= 18
	|					AND RoomSalesTurnovers.Client.Age < 55 
	|				THEN RoomSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays1855Turnover,
	|		CASE
	|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND RoomSalesTurnovers.Client.Age >= 55
	|				THEN RoomSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays55Turnover,
	|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
	|		CASE
	|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND RoomSalesTurnovers.Client.Age < 18
	|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn18Turnover,
	|		CASE
	|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND RoomSalesTurnovers.Client.Age >= 18
	|					AND RoomSalesTurnovers.Client.Age < 55
	|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn1855Turnover,
	|		CASE
	|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND RoomSalesTurnovers.Client.Age >= 55
	|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn55Turnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany) AS RoomSalesTurnovers) AS RoomSales";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyDate", '00010101');
	vQryResult = vQry.Execute().Unload();

	vTotalGuestDays = 0;
	vTotalGuestDays18 = 0;
	vTotalGuestDays1855 = 0;
	vTotalGuestDays55 = 0;
	vTotalGuests = 0;
	vTotalGuests18 = 0;
	vTotalGuests1855 = 0;
	vTotalGuests55 = 0;
	vPage3Area.Parameters.mTotalGuestDays = 0;
	vPage3Area.Parameters.mTotalGuestDays18 = 0;
	vPage3Area.Parameters.mTotalGuestDays1855 = 0;
	vPage3Area.Parameters.mTotalGuestDays55 = 0;
	vPage3Area.Parameters.mTotalGuests = 0;
	vPage3Area.Parameters.mTotalGuests18 = 0;
	vPage3Area.Parameters.mTotalGuests1855 = 0;
	vPage3Area.Parameters.mTotalGuests55 = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vPage3Area.Parameters.mTotalGuestDays = vRow.GuestDaysTurnover;
		vPage3Area.Parameters.mTotalGuestDays18 = vRow.GuestDays18Turnover;
		vPage3Area.Parameters.mTotalGuestDays1855 = vRow.GuestDays1855Turnover;
		vPage3Area.Parameters.mTotalGuestDays55 = vRow.GuestDays55Turnover;
		vPage3Area.Parameters.mTotalGuests = vRow.GuestsCheckedInTurnover;
		vPage3Area.Parameters.mTotalGuests18 = vRow.GuestsCheckedIn18Turnover;
		vPage3Area.Parameters.mTotalGuests1855 = vRow.GuestsCheckedIn1855Turnover;
		vPage3Area.Parameters.mTotalGuests55 = vRow.GuestsCheckedIn55Turnover;
		vTotalGuestDays = vRow.GuestDaysTurnover;
		vTotalGuestDays18 = vRow.GuestDays18Turnover;
		vTotalGuestDays1855 = vRow.GuestDays1855Turnover;
		vTotalGuestDays55 = vRow.GuestDays55Turnover;
		vTotalGuests = vRow.GuestsCheckedInTurnover;
		vTotalGuests18 = vRow.GuestsCheckedIn18Turnover;
		vTotalGuests1855 = vRow.GuestsCheckedIn1855Turnover;
		vTotalGuests55 = vRow.GuestsCheckedIn55Turnover;
	EndIf;
	
	// 3.4 Get total number of guest days and checked-in guests from Russia
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SUM(ISNULL(GeoSales.GuestDaysTurnover, 0)) AS GuestDaysTurnover,
	|	SUM(ISNULL(GeoSales.GuestDays18Turnover, 0)) AS GuestDays18Turnover,
	|	SUM(ISNULL(GeoSales.GuestDays1855Turnover, 0)) AS GuestDays1855Turnover,
	|	SUM(ISNULL(GeoSales.GuestDays55Turnover, 0)) AS GuestDays55Turnover,
	|	SUM(ISNULL(GeoSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover,
	|	SUM(ISNULL(GeoSales.GuestsCheckedIn18Turnover, 0)) AS GuestsCheckedIn18Turnover,
	|	SUM(ISNULL(GeoSales.GuestsCheckedIn1855Turnover, 0)) AS GuestsCheckedIn1855Turnover,
	|	SUM(ISNULL(GeoSales.GuestsCheckedIn55Turnover, 0)) AS GuestsCheckedIn55Turnover
	|FROM
	|	(SELECT
	|		GeoSalesTurnovers.Client AS Client,
	|		GeoSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age < 18
	|				THEN GeoSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays18Turnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age >= 18
	|					AND GeoSalesTurnovers.Client.Age < 55
	|				THEN GeoSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays1855Turnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age >= 55
	|				THEN GeoSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays55Turnover,
	|		GeoSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age < 18
	|				THEN GeoSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn18Turnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age >= 18
	|					AND GeoSalesTurnovers.Client.Age < 55
	|				THEN GeoSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn1855Turnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL 
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age >= 55
	|				THEN GeoSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn55Turnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND (Client.Citizenship = &qRussia
	|						OR ISNULL(Client.Citizenship.Description, """") = """")) AS GeoSalesTurnovers) AS GeoSales";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyDate", '00010101');
	vQryResult = vQry.Execute().Unload();

	vRussiaGuestDays = 0;
	vRussiaGuestDays18 = 0;
	vRussiaGuestDays1855 = 0;
	vRussiaGuestDays55 = 0;
	vRussiaGuests = 0;
	vRussiaGuests18 = 0;
	vRussiaGuests1855 = 0;
	vRussiaGuests55 = 0;
	vPage3Area.Parameters.mTotalGuestDaysRus = 0;
	vPage3Area.Parameters.mTotalGuestDaysRus18 = 0;
	vPage3Area.Parameters.mTotalGuestDaysRus1855 = 0;
	vPage3Area.Parameters.mTotalGuestDaysRus55 = 0;
	vPage3Area.Parameters.mTotalGuestsRus = 0;
	vPage3Area.Parameters.mTotalGuestsRus18 = 0;
	vPage3Area.Parameters.mTotalGuestsRus1855 = 0;
	vPage3Area.Parameters.mTotalGuestsRus55 = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vPage3Area.Parameters.mTotalGuestDaysRus = vRow.GuestDaysTurnover;
		vPage3Area.Parameters.mTotalGuestDaysRus18 = vRow.GuestDays18Turnover;
		vPage3Area.Parameters.mTotalGuestDaysRus1855 = vRow.GuestDays1855Turnover;
		vPage3Area.Parameters.mTotalGuestDaysRus55 = vRow.GuestDays55Turnover;
		vPage3Area.Parameters.mTotalGuestsRus = vRow.GuestsCheckedInTurnover;
		vPage3Area.Parameters.mTotalGuestsRus18 = vRow.GuestsCheckedIn18Turnover;
		vPage3Area.Parameters.mTotalGuestsRus1855 = vRow.GuestsCheckedIn1855Turnover;
		vPage3Area.Parameters.mTotalGuestsRus55 = vRow.GuestsCheckedIn55Turnover;
		vRussiaGuestDays = vRow.GuestDaysTurnover;
		vRussiaGuestDays18 = vRow.GuestDays18Turnover;
		vRussiaGuestDays1855 = vRow.GuestDays1855Turnover;
		vRussiaGuestDays55 = vRow.GuestDays55Turnover;
		vRussiaGuests = vRow.GuestsCheckedInTurnover;
		vRussiaGuests18 = vRow.GuestsCheckedIn18Turnover;
		vRussiaGuests1855 = vRow.GuestsCheckedIn1855Turnover;
		vRussiaGuests55 = vRow.GuestsCheckedIn55Turnover;
	EndIf;
	
	// 3.5 Get total number of guest days and checked-in foreigner guests
	If vTotalGuests <> Null And vRussiaGuests <> Null Then
		vPage3Area.Parameters.mTotalGuestDaysForeigners = vTotalGuestDays - vRussiaGuestDays;
		vPage3Area.Parameters.mTotalGuestDaysForeigners18 = vTotalGuestDays18 - vRussiaGuestDays18;
		vPage3Area.Parameters.mTotalGuestDaysForeigners1855 = vTotalGuestDays1855 - vRussiaGuestDays1855;
		vPage3Area.Parameters.mTotalGuestDaysForeigners55 = vTotalGuestDays55 - vRussiaGuestDays55;
		vPage3Area.Parameters.mTotalGuestsForeigners = vTotalGuests - vRussiaGuests;
		vPage3Area.Parameters.mTotalGuestsForeigners18 = vTotalGuests18 - vRussiaGuests18;
		vPage3Area.Parameters.mTotalGuestsForeigners1855 = vTotalGuests1855 - vRussiaGuests1855;
		vPage3Area.Parameters.mTotalGuestsForeigners55 = vTotalGuests55 - vRussiaGuests55;
	Else
		vPage3Area.Parameters.mTotalGuestDaysForeigners = 0;
		vPage3Area.Parameters.mTotalGuestDaysForeigners18 = 0;
		vPage3Area.Parameters.mTotalGuestDaysForeigners1855 = 0;
		vPage3Area.Parameters.mTotalGuestDaysForeigners55 = 0;
		vPage3Area.Parameters.mTotalGuestsForeigners = 0;
		vPage3Area.Parameters.mTotalGuestsForeigners18 = 0;
		vPage3Area.Parameters.mTotalGuestsForeigners1855 = 0;
		vPage3Area.Parameters.mTotalGuestsForeigners55 = 0;
	EndIf;
	
	// 3.6 Get total number of checked-in guests with tour tickets
	vPage3Area.Parameters.mTotalTourTicketGuests = 0;
	vPage3Area.Parameters.mTotalTourTicketGuests18 = 0;
	vPage3Area.Parameters.mTotalTourTicketGuests1855 = 0;
	vPage3Area.Parameters.mTotalTourTicketGuests55 = 0;
	If ValueIsFilled(TourTicketIncomeServiceGroup) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	SUM(ISNULL(RoomSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover,
		|	SUM(ISNULL(RoomSales.GuestsCheckedIn18Turnover, 0)) AS GuestsCheckedIn18Turnover,
		|	SUM(ISNULL(RoomSales.GuestsCheckedIn1855Turnover, 0)) AS GuestsCheckedIn1855Turnover,
		|	SUM(ISNULL(RoomSales.GuestsCheckedIn55Turnover, 0)) AS GuestsCheckedIn55Turnover
		|FROM
		|	(SELECT
		|		RoomSalesTurnovers.Client AS Client,
		|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
		|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					AND RoomSalesTurnovers.Client.Age < 18
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			ELSE 0
		|		END AS GuestsCheckedIn18Turnover,
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
		|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					AND RoomSalesTurnovers.Client.Age >= 18
		|					AND RoomSalesTurnovers.Client.Age < 55
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			ELSE 0
		|		END AS GuestsCheckedIn1855Turnover,
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL 
		|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					AND RoomSalesTurnovers.Client.Age >= 55
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			ELSE 0
		|		END AS GuestsCheckedIn55Turnover
		|	FROM
		|		AccumulationRegister.Sales.Turnovers(
		|				&qPeriodFrom,
		|				&qPeriodTo,
		|				Period,
		|				NOT IsCorrection AND Hotel = &qHotel
		|					AND Company = &qCompany
		|					AND (Service IN HIERARCHY (&qTourTicketServices)
		|						OR NOT &qUseServicesList)
		|					) AS RoomSalesTurnovers) AS RoomSales";
		vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qCompany", Company);
		vUseServicesList = False;
		vServicesList = New ValueList();
		If Not TourTicketIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(TourTicketIncomeServiceGroup);
		EndIf;
		vQry.SetParameter("qUseServicesList", vUseServicesList);
		vQry.SetParameter("qTourTicketServices", vServicesList);
		vQry.SetParameter("qEmptyDate", '00010101');
		vQryResult = vQry.Execute().Unload();

		If vQryResult.Count() > 0 Then
			vRow = vQryResult.Get(0);
			
			vPage3Area.Parameters.mTotalTourTicketGuests = vRow.GuestsCheckedInTurnover;
			vPage3Area.Parameters.mTotalTourTicketGuests18 = vRow.GuestsCheckedIn18Turnover;
			vPage3Area.Parameters.mTotalTourTicketGuests1855 = vRow.GuestsCheckedIn1855Turnover;
			vPage3Area.Parameters.mTotalTourTicketGuests55 = vRow.GuestsCheckedIn55Turnover;
		EndIf;
		
		// The same from russia
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	SUM(ISNULL(RoomSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover,
		|	SUM(ISNULL(RoomSales.GuestsCheckedIn18Turnover, 0)) AS GuestsCheckedIn18Turnover,
		|	SUM(ISNULL(RoomSales.GuestsCheckedIn1855Turnover, 0)) AS GuestsCheckedIn1855Turnover,
		|	SUM(ISNULL(RoomSales.GuestsCheckedIn55Turnover, 0)) AS GuestsCheckedIn55Turnover
		|FROM
		|	(SELECT
		|		RoomSalesTurnovers.Client AS Client,
		|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL
		|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					AND RoomSalesTurnovers.Client.Age < 18
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			ELSE 0
		|		END AS GuestsCheckedIn18Turnover,
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL
		|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					AND RoomSalesTurnovers.Client.Age >= 18
		|					AND RoomSalesTurnovers.Client.Age < 55
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			ELSE 0
		|		END AS GuestsCheckedIn1855Turnover,
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL
		|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					AND RoomSalesTurnovers.Client.Age >= 55
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			ELSE 0
		|		END AS GuestsCheckedIn55Turnover
		|	FROM
		|		AccumulationRegister.Sales.Turnovers(
		|				&qPeriodFrom,
		|				&qPeriodTo,
		|				Period,
		|				NOT IsCorrection
		|					AND Hotel = &qHotel
		|					AND Company = &qCompany
		|					AND (Service IN HIERARCHY (&qTourTicketServices)
		|						OR NOT &qUseServicesList)
		|					AND (Client.Citizenship = &qRussia
		|						OR ISNULL(Client.Citizenship.Description, """") = """")) AS RoomSalesTurnovers) AS RoomSales";
		vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qRussia", RussiaCountry);
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qCompany", Company);
		vUseServicesList = False;
		vServicesList = New ValueList();
		If Not TourTicketIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(TourTicketIncomeServiceGroup);
		EndIf;
		vQry.SetParameter("qUseServicesList", vUseServicesList);
		vQry.SetParameter("qTourTicketServices", vServicesList);
		vQry.SetParameter("qEmptyDate", '00010101');
		vQryResult = vQry.Execute().Unload();

		If vQryResult.Count() > 0 Then
			vRow = vQryResult.Get(0);
			vPage3Area.Parameters.mTotalTourTicketGuestsRus = ?(vRow.GuestsCheckedInTurnover = Null, 0, vRow.GuestsCheckedInTurnover);
			vPage3Area.Parameters.mTotalTourTicketGuestsRus18 = ?(vRow.GuestsCheckedIn18Turnover = Null, 0, vRow.GuestsCheckedIn18Turnover);
			vPage3Area.Parameters.mTotalTourTicketGuestsRus1855 = ?(vRow.GuestsCheckedIn1855Turnover = Null, 0, vRow.GuestsCheckedIn1855Turnover);
			vPage3Area.Parameters.mTotalTourTicketGuestsRus55 = ?(vRow.GuestsCheckedIn55Turnover = Null, 0, vRow.GuestsCheckedIn55Turnover);
			
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners = ?(vPage3Area.Parameters.mTotalTourTicketGuests = Null, 0, vPage3Area.Parameters.mTotalTourTicketGuests) - ?(vRow.GuestsCheckedInTurnover = Null, 0, vRow.GuestsCheckedInTurnover);
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners18 = ?(vPage3Area.Parameters.mTotalTourTicketGuests18 = Null, 0, vPage3Area.Parameters.mTotalTourTicketGuests18) - ?(vRow.GuestsCheckedIn18Turnover = Null, 0, vRow.GuestsCheckedIn18Turnover);
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners1855 = ?(vPage3Area.Parameters.mTotalTourTicketGuests1855 = Null, 0, vPage3Area.Parameters.mTotalTourTicketGuests1855) - ?(vRow.GuestsCheckedIn1855Turnover = Null, 0, vRow.GuestsCheckedIn1855Turnover);
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners55 = ?(vPage3Area.Parameters.mTotalTourTicketGuests55 = Null, 0, vPage3Area.Parameters.mTotalTourTicketGuests55) - ?(vRow.GuestsCheckedIn55Turnover = Null, 0, vRow.GuestsCheckedIn55Turnover);
		Else
			vPage3Area.Parameters.mTotalTourTicketGuestsRus = 0;
			vPage3Area.Parameters.mTotalTourTicketGuestsRus18 = 0;
			vPage3Area.Parameters.mTotalTourTicketGuestsRus1855 = 0;
			vPage3Area.Parameters.mTotalTourTicketGuestsRus55 = 0;
			
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners = 0;
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners18 = 0;
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners1855 = 0;
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners55 = 0;
		EndIf;
	EndIf;
	
	pSpreadsheet.Put(vPage3Area);
	
	// Page 3 header Spr. 1
	pSpreadsheet.Put(vPage3H1Area);
	
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ISNULL(GeoSales.Client.Citizenship.Description, """") AS CountryDescription,
	|	ISNULL(GeoSales.Client.Citizenship.Code, 0) AS CountryCode,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			NOT IsCorrection AND Hotel = &qHotel
	|				AND Company = &qCompany
	|				AND Client.Citizenship <> &qRussia
	|				AND ISNULL(Client.Citizenship.Description, """") <> """") AS GeoSales
	|
	|GROUP BY
	|	GeoSales.Client.Citizenship.Description,
	|	GeoSales.Client.Citizenship.Code
	|
	|ORDER BY
	|	GeoSales.Client.Citizenship.Code";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQryResult = vQry.Execute().Unload();
	c = 0;
	While c < vQryResult.Count() Do
		vQryResultRow = vQryResult.Get(c);
		
		vPage3H1RowArea.Parameters.mCountry = TrimAll(vQryResultRow.CountryDescription);
		vPage3H1RowArea.Parameters.mCountryCode = TrimAll(vQryResultRow.CountryCode);
		vPage3H1RowArea.Parameters.mCountryGuests = vQryResultRow.GuestsCheckedInTurnover;
		
		pSpreadsheet.Put(vPage3H1RowArea);
		
		c = c + 1;
	EndDo;
	
	// Get number of checked in guests by hotel products (Page 3. Spr 2)
	vPage3H2Area.Parameters.mVaucherQuantity = 0;
	vPage3H2Area.Parameters.mVaucher18Quantity = 0;
	vPage3H2Area.Parameters.mVaucher1855Quantity = 0;
	vPage3H2Area.Parameters.mVaucher55Quantity = 0;
	
	If ValueIsFilled(VaucherIncomeServiceGroup) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	SUM(AgeSales.VaucherQuantity) AS VaucherQuantity,
		|	SUM(AgeSales.Vaucher18Quantity) AS Vaucher18Quantity,
		|	SUM(AgeSales.Vaucher1855Quantity) AS Vaucher1855Quantity,
		|	SUM(AgeSales.Vaucher55Quantity) AS Vaucher55Quantity
		|FROM
		|	(SELECT
		|		RoomSalesTurnovers.Client AS Client,
		|		RoomSalesTurnovers.Client.Age AS ClientAge,
		|		MAX(1) AS VaucherQuantity,
		|		MAX(CASE
		|				WHEN RoomSalesTurnovers.Client.Age < 18
		|						AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					THEN 1
		|				ELSE 0
		|			END) AS Vaucher18Quantity,
		|		MAX(CASE
		|				WHEN RoomSalesTurnovers.Client.Age >= 18
		|						AND RoomSalesTurnovers.Client.Age < 54
		|						AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					THEN 1
		|				ELSE 0
		|			END) AS Vaucher1855Quantity,
		|		MAX(CASE
		|				WHEN RoomSalesTurnovers.Client.Age >= 55
		|					THEN 1
		|				ELSE 0
		|			END) AS Vaucher55Quantity
		|	FROM
		|		AccumulationRegister.Sales.Turnovers(
		|				&qPeriodFrom,
		|				&qPeriodTo,
		|				Period,
		|				NOT IsCorrection
		|					AND Hotel = &qHotel
		|					AND Company = &qCompany
		|					AND (Service IN HIERARCHY (&qVaucherServices)
		|						OR NOT &qUseServicesList)) AS RoomSalesTurnovers
		|	
		|	GROUP BY
		|		RoomSalesTurnovers.Client,
		|		RoomSalesTurnovers.Client.Age) AS AgeSales";
		vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qCompany", Company);
		vQry.SetParameter("qEmptyDate", '00010101');
		vUseServicesList = False;
		vServicesList = New ValueList();
		If Not TourTicketIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(VaucherIncomeServiceGroup);
		EndIf;
		vQry.SetParameter("qUseServicesList", vUseServicesList);
		vQry.SetParameter("qVaucherServices", vServicesList);
		vQryResult = vQry.Execute().Unload();

		If vQryResult.Count() > 0 Then
			vRow = vQryResult.Get(0);
			
			vPage3H2Area.Parameters.mVaucherQuantity = vRow.VaucherQuantity;
			vPage3H2Area.Parameters.mVaucher18Quantity = vRow.Vaucher18Quantity;
			vPage3H2Area.Parameters.mVaucher1855Quantity = vRow.Vaucher1855Quantity;
			vPage3H2Area.Parameters.mVaucher55Quantity = vRow.Vaucher55Quantity;
		EndIf;
	EndIf;
	
	pSpreadsheet.Put(vPage3H2Area);
	
	pSpreadsheet.PutHorizontalPageBreak();
	
	// Page 4
	
	// 4.1.1 Get total number of russian checked-in guests per trip purposes
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qStudy
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qOther
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTransit
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qRecreation
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qPilgrims
	|			THEN 4
	|		WHEN GeoSales.TripPurpose = &qShopping
	|			THEN 5
	|		ELSE 5
	|	END AS TripPurposeType,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		GeoSalesTurnovers.TripPurpose AS TripPurpose,
	|		SUM(GeoSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND (Client.Citizenship = &qRussia
	|						OR ISNULL(Client.Citizenship.Description, """") = """")) AS GeoSalesTurnovers
	|	
	|	GROUP BY
	|		GeoSalesTurnovers.TripPurpose) AS GeoSales
	|
	|GROUP BY
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qStudy
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qOther
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTransit
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qRecreation
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qPilgrims
	|			THEN 4
	|		WHEN GeoSales.TripPurpose = &qShopping
	|			THEN 5
	|		ELSE 5
	|	END
	|
	|ORDER BY
	|	TripPurposeType";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qBusiness", Catalogs.TripPurposes.Business);
	vQry.SetParameter("qCommerce", Catalogs.TripPurposes.Commerce);
	vQry.SetParameter("qOfficial", Catalogs.TripPurposes.Official);
	vQry.SetParameter("qWork", Catalogs.TripPurposes.Work);
	vQry.SetParameter("qCrewman", Catalogs.TripPurposes.Crewman);
	vQry.SetParameter("qHumanitarian", Catalogs.TripPurposes.Humanitarian);
	vQry.SetParameter("qTourism", Catalogs.TripPurposes.Tourism);
	vQry.SetParameter("qPrivate", Catalogs.TripPurposes.Private);
	vQry.SetParameter("qScientific", Catalogs.TripPurposes.Scientific);
	vQry.SetParameter("qStudy", Catalogs.TripPurposes.Study);
	vQry.SetParameter("qRecreation", Catalogs.TripPurposes.Recreation);
	vQry.SetParameter("qShopping", Catalogs.TripPurposes.Shopping);
	vQry.SetParameter("qPilgrims", Catalogs.TripPurposes.Pilgrims);
	vQry.SetParameter("qTransit", Catalogs.TripPurposes.Transit);
	vQry.SetParameter("qOther", Catalogs.TripPurposes.Other);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyCountry", Catalogs.Countries.EmptyRef());
	vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vQry.SetParameter("qEmptyCountry", Catalogs.Countries.EmptyRef());
	vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vQryResult = vQry.Execute().Unload();
	
	vPage4Area.Parameters.mGuestsTouristsRus = 0;
	vPage4Area.Parameters.mGuestsEducationRus = 0;
	vPage4Area.Parameters.mGuestsBusinessRus = 0;
	vPage4Area.Parameters.mGuestsCureRus = 0;
	vPage4Area.Parameters.mGuestsPilgrimRus = 0;
	vPage4Area.Parameters.mGuestsOtherRus = 0;

	For Each vRow In vQryResult Do
		If vRow.TripPurposeType = 1 Then
			vPage4Area.Parameters.mGuestsTouristsRus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 2 Then
			vPage4Area.Parameters.mGuestsEducationRus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 6 Then
			vPage4Area.Parameters.mGuestsBusinessRus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 3 Then
			vPage4Area.Parameters.mGuestsCureRus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 4 Then
			vPage4Area.Parameters.mGuestsPilgrimRus = vRow.GuestsCheckedInTurnover;
		Else
			vPage4Area.Parameters.mGuestsOtherRus = vRow.GuestsCheckedInTurnover;
		EndIf;
	EndDo;
	
	// 4.1.4 Get total number of checked-in foreigner guests per trip purposes
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qStudy
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qOther
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTransit
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qRecreation
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qPilgrims
	|			THEN 4
	|		WHEN GeoSales.TripPurpose = &qShopping
	|			THEN 5
	|		ELSE 5
	|	END AS TripPurposeType,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		GeoSalesTurnovers.TripPurpose AS TripPurpose,
	|		SUM(GeoSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND Client.Citizenship <> &qRussia
	|					AND ISNULL(Client.Citizenship.Description, """") <> """") AS GeoSalesTurnovers
	|	
	|	GROUP BY
	|		GeoSalesTurnovers.TripPurpose) AS GeoSales
	|
	|GROUP BY
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qStudy
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qOther
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTransit
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qRecreation
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qPilgrims
	|			THEN 4
	|		WHEN GeoSales.TripPurpose = &qShopping
	|			THEN 5
	|		ELSE 5
	|	END
	|
	|ORDER BY
	|	TripPurposeType";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qBusiness", Catalogs.TripPurposes.Business);
	vQry.SetParameter("qCommerce", Catalogs.TripPurposes.Commerce);
	vQry.SetParameter("qOfficial", Catalogs.TripPurposes.Official);
	vQry.SetParameter("qWork", Catalogs.TripPurposes.Work);
	vQry.SetParameter("qCrewman", Catalogs.TripPurposes.Crewman);
	vQry.SetParameter("qHumanitarian", Catalogs.TripPurposes.Humanitarian);
	vQry.SetParameter("qTourism", Catalogs.TripPurposes.Tourism);
	vQry.SetParameter("qPrivate", Catalogs.TripPurposes.Private);
	vQry.SetParameter("qScientific", Catalogs.TripPurposes.Scientific);
	vQry.SetParameter("qStudy", Catalogs.TripPurposes.Study);
	vQry.SetParameter("qRecreation", Catalogs.TripPurposes.Recreation);
	vQry.SetParameter("qShopping", Catalogs.TripPurposes.Shopping);
	vQry.SetParameter("qPilgrims", Catalogs.TripPurposes.Pilgrims);
	vQry.SetParameter("qTransit", Catalogs.TripPurposes.Transit);
	vQry.SetParameter("qOther", Catalogs.TripPurposes.Other);
	vQry.SetParameter("qCompany", Company);
	vQryResult = vQry.Execute().Unload();
	
	vPage4Area.Parameters.mGuestsTouristsForeigners = 0;
	vPage4Area.Parameters.mGuestsEducationForeigners = 0;
	vPage4Area.Parameters.mGuestsBusinessForeigners = 0;
	vPage4Area.Parameters.mGuestsCureForeigners = 0;
	vPage4Area.Parameters.mGuestsPilgrimForeigners = 0;
	vPage4Area.Parameters.mGuestsOtherForeigners = 0;

	For Each vRow In vQryResult Do
		If vRow.TripPurposeType = 1 Then
			vPage4Area.Parameters.mGuestsTouristsForeigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 2 Then
			vPage4Area.Parameters.mGuestsEducationForeigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 6 Then
			vPage4Area.Parameters.mGuestsBusinessForeigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 3 Then
			vPage4Area.Parameters.mGuestsCureForeigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 4 Then
			vPage4Area.Parameters.mGuestsPilgrimForeigners = vRow.GuestsCheckedInTurnover;
		Else
			vPage4Area.Parameters.mGuestsOtherForeigners = vRow.GuestsCheckedInTurnover;
		EndIf;
	EndDo;
	
	// 4.2.1 Get total number of russian checked-in guests per duration
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 0
	|		WHEN GeoSales.Duration < 5
	|			THEN 4
	|		WHEN GeoSales.Duration < 8
	|			THEN 7
	|		WHEN GeoSales.Duration < 15
	|			THEN 14
	|		WHEN GeoSales.Duration < 29
	|			THEN 28
	|		WHEN GeoSales.Duration < 91
	|			THEN 90
	|		WHEN GeoSales.Duration < 183
	|			THEN 182
	|		ELSE 183
	|	END AS DurationType,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0) AS Duration,
	|		SUM(GeoSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND (Client.Citizenship = &qRussia
	|						OR ISNULL(Client.Citizenship.Description, """") = """")) AS GeoSalesTurnovers
	|	
	|	GROUP BY
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0)) AS GeoSales
	|
	|GROUP BY
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 0
	|		WHEN GeoSales.Duration < 5
	|			THEN 4
	|		WHEN GeoSales.Duration < 8
	|			THEN 7
	|		WHEN GeoSales.Duration < 15
	|			THEN 14
	|		WHEN GeoSales.Duration < 29
	|			THEN 28
	|		WHEN GeoSales.Duration < 91
	|			THEN 90
	|		WHEN GeoSales.Duration < 183
	|			THEN 182
	|		ELSE 183
	|	END
	|
	|ORDER BY
	|	DurationType";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyCountry", Catalogs.Countries.EmptyRef());
	vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vQryResult = vQry.Execute().Unload();
	
	vPage4Area.Parameters.mGuests0Rus = 0;
	vPage4Area.Parameters.mGuests1_4Rus = 0;
	vPage4Area.Parameters.mGuests5_7Rus = 0;
	vPage4Area.Parameters.mGuests8_14Rus = 0;
	vPage4Area.Parameters.mGuests15_28Rus = 0;
	vPage4Area.Parameters.mGuests29_90Rus = 0;
	vPage4Area.Parameters.mGuests91_182Rus = 0;
	vPage4Area.Parameters.mGuests183Rus = 0;

	For Each vRow In vQryResult Do
		If vRow.DurationType = 0 Then
			vPage4Area.Parameters.mGuests0Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 4 Then
			vPage4Area.Parameters.mGuests1_4Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 7 Then
			vPage4Area.Parameters.mGuests5_7Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 14 Then
			vPage4Area.Parameters.mGuests8_14Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 28 Then
			vPage4Area.Parameters.mGuests15_28Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 90 Then
			vPage4Area.Parameters.mGuests29_90Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 182 Then
			vPage4Area.Parameters.mGuests91_182Rus = vRow.GuestsCheckedInTurnover;
		Else
			vPage4Area.Parameters.mGuests183Rus = vRow.GuestsCheckedInTurnover;
		EndIf;
	EndDo;
	
	// 4.2.2 Get total number of foreigner checked-in guests per duration
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 0
	|		WHEN GeoSales.Duration < 5
	|			THEN 4
	|		WHEN GeoSales.Duration < 8
	|			THEN 7
	|		WHEN GeoSales.Duration < 15
	|			THEN 14
	|		WHEN GeoSales.Duration < 29
	|			THEN 28
	|		WHEN GeoSales.Duration < 91
	|			THEN 90
	|		WHEN GeoSales.Duration < 183
	|			THEN 182
	|		ELSE 183
	|	END AS DurationType,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0) AS Duration,
	|		SUM(GeoSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND Client.Citizenship <> &qRussia
	|					AND ISNULL(Client.Citizenship.Description, """") <> """") AS GeoSalesTurnovers
	|	
	|	GROUP BY
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0)) AS GeoSales
	|
	|GROUP BY
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 0
	|		WHEN GeoSales.Duration < 5
	|			THEN 4
	|		WHEN GeoSales.Duration < 8
	|			THEN 7
	|		WHEN GeoSales.Duration < 15
	|			THEN 14
	|		WHEN GeoSales.Duration < 29
	|			THEN 28
	|		WHEN GeoSales.Duration < 91
	|			THEN 90
	|		WHEN GeoSales.Duration < 183
	|			THEN 182
	|		ELSE 183
	|	END
	|
	|ORDER BY
	|	DurationType";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qCompany", Company);
	vQryResult = vQry.Execute().Unload();
	
	vPage4Area.Parameters.mGuests0Foreigners = 0;
	vPage4Area.Parameters.mGuests1_4Foreigners = 0;
	vPage4Area.Parameters.mGuests5_7Foreigners = 0;
	vPage4Area.Parameters.mGuests8_14Foreigners = 0;
	vPage4Area.Parameters.mGuests15_28Foreigners = 0;
	vPage4Area.Parameters.mGuests29_90Foreigners = 0;
	vPage4Area.Parameters.mGuests91_182Foreigners = 0;
	vPage4Area.Parameters.mGuests183Foreigners = 0;

	For Each vRow In vQryResult Do
		If vRow.DurationType = 0 Then
			vPage4Area.Parameters.mGuests0Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 4 Then
			vPage4Area.Parameters.mGuests1_4Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 7 Then
			vPage4Area.Parameters.mGuests5_7Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 14 Then
			vPage4Area.Parameters.mGuests8_14Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 28 Then
			vPage4Area.Parameters.mGuests15_28Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 90 Then
			vPage4Area.Parameters.mGuests29_90Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 182 Then
			vPage4Area.Parameters.mGuests91_182Foreigners = vRow.GuestsCheckedInTurnover;
		Else
			vPage4Area.Parameters.mGuests183Foreigners = vRow.GuestsCheckedInTurnover;
		EndIf;
	EndDo;
	
	pSpreadsheet.Put(vPage4Area);
	pSpreadsheet.PutHorizontalPageBreak();
	
	// Page 5
	
	// 7.1 Get total sales
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomSalesTurnovers.RoomRevenueWithoutVATTurnover,
	|	RoomSalesTurnovers.SalesWithoutVATTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			NOT IsCorrection AND Hotel = &qHotel
	|				AND Company = &qCompany
	|				AND (Service IN HIERARCHY (&qIncomeServices)
	|					OR (NOT &qUseServicesList))) AS RoomSalesTurnovers";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vUseServicesList = False;
	vServicesList = New ValueList();
	If ValueIsFilled(TotalIncomeServiceGroup) Then
		If Not TotalIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(TotalIncomeServiceGroup);
		EndIf;
	EndIf;
	vQry.SetParameter("qUseServicesList", vUseServicesList);
	vQry.SetParameter("qIncomeServices", vServicesList);
	vQryResult = vQry.Execute().Unload();

	vTotalIncome = 0;
	vPage5Area.Parameters.mTotalIncome = 0;
	vPage5Area.Parameters.mTotalRoomRevenueIncome = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vTotalIncome = Round(vRow.SalesWithoutVATTurnover/1000, 1);
		vPage5Area.Parameters.mTotalIncome = vTotalIncome;
		vTotalRoomRevenueIncome = Round(vRow.RoomRevenueWithoutVATTurnover/1000, 1);
		vPage5Area.Parameters.mTotalRoomRevenueIncome = vTotalRoomRevenueIncome;
	EndIf;
	
	// 7.2 Get total meals sales
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomSalesTurnovers.SalesWithoutVATTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			NOT IsCorrection AND Hotel = &qHotel
	|				AND Company = &qCompany
	|				AND (Service IN HIERARCHY (&qIncomeServices)
	|					OR (NOT &qUseServicesList))) AS RoomSalesTurnovers";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vUseServicesList = False;
	vServicesList = New ValueList();
	If ValueIsFilled(MealIncomeServiceGroup) Then
		If Not MealIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(MealIncomeServiceGroup);
		EndIf;
	EndIf;
	vQry.SetParameter("qUseServicesList", vUseServicesList);
	vQry.SetParameter("qIncomeServices", vServicesList);
	vQryResult = vQry.Execute().Unload();
	
	vTotalMealsIncome = 0;
	vPage5Area.Parameters.mTotalMealsIncome = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vTotalMealsIncome = Round(vRow.SalesWithoutVATTurnover/1000, 1);
		vPage5Area.Parameters.mTotalMealsIncome = vTotalMealsIncome;
	EndIf;
	
	pSpreadsheet.Put(vPage5Area);
	pSpreadsheet.PutHorizontalPageBreak();
EndProcedure // pmGenerate2024

// -----------------------------------------------------------------------------
Procedure pmGenerate2025(pSpreadsheet) Export
	// Clear output spreadsheet
	pSpreadsheet.Clear();
	
	// Choose template
	vTemplate = ThisObject.GetTemplate("Report2025");

	If ReportParameters = Undefined Then
		ReportParameters = New Structure(GetReportParametersNames());
	EndIf;
	
	// Report pages
	vPage1Area = vTemplate.GetArea("Page1");
	vPage2Area = vTemplate.GetArea("Page2");
	vPage3Area = vTemplate.GetArea("Page3");
	vPage3H1Area = vTemplate.GetArea("Page3H1");
	vPage3H1RowArea = vTemplate.GetArea("Page3H1Row");
	vPage3H2Area = vTemplate.GetArea("Page3H2");
	vPage4Area = vTemplate.GetArea("Page4");
	vPage5Area = vTemplate.GetArea("Page5");
	
	// Page 1
	vPage1Area.Parameters.mPeriodStr = PeriodPresentation(BegOfDay(PeriodFrom), EndOfDay(PeriodTo), cmLocalizationCode());
	vPage1Area.Parameters.mHotelName = TrimAll(Hotel.LegacyName);
	vPage1Area.Parameters.mHotelPostAddress = cmGetAddressPresentation(Hotel.PostAddress);
	vPage1Area.Parameters.mCompanyName = TrimAll(Company.LegacyName);
	vPage1Area.Parameters.mCompanyPostAddress = cmGetAddressPresentation(Company.PostAddress);
	vPage1Area.Parameters.mCompanyOKPOCode = TrimAll(Company.OKPO);
	
	pSpreadsheet.Put(vPage1Area);
	pSpreadsheet.PutHorizontalPageBreak();
	
	FillPropertyValues(ReportParameters, vPage1Area.Parameters);
	
	// Page 2
	
	// Hotel type
	vPage2Area.Parameters.m101 = "";
	vPage2Area.Parameters.m102 = "";
	vPage2Area.Parameters.m103 = "";
	vPage2Area.Parameters.m104 = "";
	vPage2Area.Parameters.m105 = "";
	vPage2Area.Parameters.m106 = "";
	vPage2Area.Parameters.m107 = "";
	vPage2Area.Parameters.m108 = "";
	vPage2Area.Parameters.m109 = "";
	vPage2Area.Parameters.m110 = "";
	vPage2Area.Parameters.m111 = "";
	vPage2Area.Parameters.m112 = "";
	vPage2Area.Parameters.m113 = "";
	vPage2Area.Parameters.m114 = "";
	vPage2Area.Parameters.m115 = "";
	vPage2Area.Parameters.m116 = "";
	vPage2Area.Parameters.m117 = "";
	
	If ValueIsFilled(Hotel) Then
		If Hotel.HotelClassification = Enums.HotelClassification.CityHotel Then
			vPage2Area.Parameters.m101 = "1";
		ElsIf Hotel.HotelClassification = Enums.HotelClassification.CountryHotelRecreationCenter Then
			vPage2Area.Parameters.m113 = "1";
		ElsIf Hotel.HotelClassification = Enums.HotelClassification.Hostel Then
			vPage2Area.Parameters.m103 = "1";
		ElsIf Hotel.HotelClassification = Enums.HotelClassification.HotelCulturalHeritageSite Then
			vPage2Area.Parameters.m101 = "1";
		ElsIf Hotel.HotelClassification = Enums.HotelClassification.ApartHotel Then
			vPage2Area.Parameters.m101 = "1";
		ElsIf Hotel.HotelClassification = Enums.HotelClassification.ApartmentComplex Then
			vPage2Area.Parameters.m105 = "1";
		ElsIf Hotel.HotelClassification = Enums.HotelClassification.Motel Then
			vPage2Area.Parameters.m102 = "1";
		ElsIf Hotel.HotelClassification = Enums.HotelClassification.ResortHotelHolidayHouse Then
			vPage2Area.Parameters.m104 = "1";
		EndIf;
	EndIf;
	
	// Seasonal work
	vPage2Area.Parameters.m122 = "1";
	vPage2Area.Parameters.m123 = "";
	If ValueIsFilled(Hotel) And Hotel.IsSeasonal Then
		vPage2Area.Parameters.m122 = "";
		vPage2Area.Parameters.m123 = "1";
	EndIf;
	
	// Taxation type
	vPage2Area.Parameters.m118 = "";
	vPage2Area.Parameters.m119 = "";
	vPage2Area.Parameters.m120 = "";
	vPage2Area.Parameters.m121 = "";
	
	If ValueIsFilled(Company) Then
		If Company.TaxationSystem = Enums.TaxationSystems.Common Then
			vPage2Area.Parameters.m118 = "1";
		ElsIf Company.TaxationSystem = Enums.TaxationSystems.SimplifiedIncome Then
			vPage2Area.Parameters.m119 = "1";
		ElsIf Company.TaxationSystem = Enums.TaxationSystems.SimplifiedIncomeMinusOutcome Then
			vPage2Area.Parameters.m119 = "1";
		ElsIf Company.TaxationSystem = Enums.TaxationSystems.UnifiedTaxOnImputedIncome Then
			vPage2Area.Parameters.m120 = "1";
		ElsIf Company.TaxationSystem = Enums.TaxationSystems.PatentTaxationSystem Then
			vPage2Area.Parameters.m121 = "1";
		EndIf;
	EndIf;
	
	// Classification
	
	vPage2Area.Parameters.m1Star = "";
	vPage2Area.Parameters.m2Star = "";
	vPage2Area.Parameters.m3Star = "";
	vPage2Area.Parameters.m4Star = "";
	vPage2Area.Parameters.m5Star = "";
	vPage2Area.Parameters.mNoStar = "";
	vPage2Area.Parameters.mNotClassified = "";
	
	If ValueIsFilled(Hotel) Then
		If Hotel.Category = Enums.HotelCategory.OneStar Then
			vPage2Area.Parameters.m1Star = "1";
		ElsIf Hotel.Category = Enums.HotelCategory.TwoStar Then
			vPage2Area.Parameters.m2Star = "1";
		ElsIf Hotel.Category = Enums.HotelCategory.ThreeStars Then
			vPage2Area.Parameters.m3Star = "1";
		ElsIf Hotel.Category = Enums.HotelCategory.FourStars Then
			vPage2Area.Parameters.m4Star = "1";
		ElsIf Hotel.Category = Enums.HotelCategory.FiveStars Then
			vPage2Area.Parameters.m5Star = "1";
		ElsIf Hotel.Category = Enums.HotelCategory.NoStars Then
			vPage2Area.Parameters.mNoStar = "1";
		ElsIf Hotel.Category = Enums.HotelCategory.NotClassified Then
			vPage2Area.Parameters.mNotClassified = "1";
		EndIf;
	EndIf;
	
	// Check if hotel has not permanent buildings and modular buildings
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInventoryBalance.RoomType.IsNotPermanentBuilding AS RoomTypeIsNotPermanentBuilding,
	|	RoomInventoryBalance.RoomType.IsModularStructure AS RoomTypeIsModularStructure,
	|	SUM(RoomInventoryBalance.TotalRoomsBalance) AS TotalRoomsBalance
	|FROM
	|	AccumulationRegister.RoomInventory.Balance(
	|			&qPeriodTo,
	|			Hotel = &qHotel
	|				AND (Room.Company = &qCompany
	|					OR Room.Company = &qEmptyCompany)
	|				AND (RoomType.Company = &qCompany
	|					OR RoomType.Company = &qEmptyCompany)
	|				AND NOT RoomType.DeletionMark) AS RoomInventoryBalance
	|
	|GROUP BY
	|	RoomInventoryBalance.RoomType.IsNotPermanentBuilding,
	|	RoomInventoryBalance.RoomType.IsModularStructure
	|
	|HAVING
	|	SUM(RoomInventoryBalance.TotalRoomsBalance) > 0
	|
	|ORDER BY
	|	RoomTypeIsNotPermanentBuilding,
	|	RoomTypeIsModularStructure";
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyCompany", Catalogs.Companies.EmptyRef());
	vData = vQry.Execute().Unload();
	
	v131 = "";
	v132 = "";
	v133 = "";
	v134 = "";
	v135 = "";
	v136 = "";
	
	For Each vDataRow In vData Do
		If vDataRow.RoomTypeIsNotPermanentBuilding <> Null And vDataRow.RoomTypeIsModularStructure <> Null Then
			If Not vDataRow.RoomTypeIsNotPermanentBuilding And Not vDataRow.RoomTypeIsModularStructure Then
				v131 = "1";
				v135 = "1";
			ElsIf vDataRow.RoomTypeIsNotPermanentBuilding Then
				If v131 = "1" Then
					v131 = "";
					v133 = "1";
				Else
					v132 = "1";
				EndIf;
				If Not vDataRow.RoomTypeIsModularStructure Then
					v135 = "1";
				Else
					If v135 = "1" Then
						v136 = "1";
						v135 = "";
					Else
						v134 = "1";
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndDo;

	vPage2Area.Parameters.m131 = v131;
	vPage2Area.Parameters.m132 = v132;
	vPage2Area.Parameters.m133 = v133;
	vPage2Area.Parameters.m134 = v134;
	vPage2Area.Parameters.m135 = v135;
	vPage2Area.Parameters.m136 = v136;

	pSpreadsheet.Put(vPage2Area);
	
	FillPropertyValues(ReportParameters, vPage2Area.Parameters);

	pSpreadsheet.PutHorizontalPageBreak();
	
	// Page 3
	
	// Get total number of rooms/beds per end of period
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInventoryBalance.RoomType.IsModularStructure AS RoomTypeIsModularStructure,
	|	SUM(RoomInventoryBalance.TotalRoomsBalance) AS TotalRoomsBalance,
	|	SUM(RoomInventoryBalance.TotalBedsBalance) AS TotalBedsBalance
	|FROM
	|	AccumulationRegister.RoomInventory.Balance(
	|			&qPeriodTo,
	|			Hotel = &qHotel
	|				AND (Room.Company = &qCompany
	|					OR Room.Company = &qEmptyCompany)
	|				AND (RoomType.Company = &qCompany
	|					OR RoomType.Company = &qEmptyCompany)) AS RoomInventoryBalance
	|
	|GROUP BY
	|	RoomInventoryBalance.RoomType.IsModularStructure
	|
	|ORDER BY
	|	RoomTypeIsModularStructure";
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyCompany", Catalogs.Companies.EmptyRef());
	vQryResult = vQry.Execute().Unload();

	vPage3Area.Parameters.mTotalRooms = 0;
	vPage3Area.Parameters.mTotalModularRooms = 0;
	vPage3Area.Parameters.mTotalBeds = 0;
	vPage3Area.Parameters.mTotalModularBeds = 0;
	For Each vQryResultRow In  vQryResult Do
		vPage3Area.Parameters.mTotalRooms = vPage3Area.Parameters.mTotalRooms + vQryResultRow.TotalRoomsBalance;
		vPage3Area.Parameters.mTotalBeds = vPage3Area.Parameters.mTotalBeds + vQryResultRow.TotalBedsBalance;
		
		If vQryResultRow.RoomTypeIsModularStructure <> Null And vQryResultRow.RoomTypeIsModularStructure Then
			vPage3Area.Parameters.mTotalModularRooms = vQryResultRow.TotalRoomsBalance;
			vPage3Area.Parameters.mTotalModularBeds = vQryResultRow.TotalBedsBalance;
		EndIf;
	EndDo;
	
	// Get total number of rooms/beds for top room types per end of period
	vPage3Area.Parameters.mTotalTopRooms = 0;
	vPage3Area.Parameters.mTotalModularTopRooms = 0;
	If ValueIsFilled(TopRoomTypes) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	RoomInventoryBalance.RoomType.IsModularStructure AS RoomTypeIsModularStructure,
		|	SUM(RoomInventoryBalance.TotalRoomsBalance) AS TotalRoomsBalance,
		|	SUM(RoomInventoryBalance.TotalBedsBalance) AS TotalBedsBalance
		|FROM
		|	AccumulationRegister.RoomInventory.Balance(
		|			&qPeriodTo,
		|			Hotel = &qHotel
		|				AND RoomType IN HIERARCHY (&qTopRoomTypes)
		|				AND (Room.Company = &qCompany
		|					OR Room.Company = &qEmptyCompany)
		|				AND (RoomType.Company = &qCompany
		|					OR RoomType.Company = &qEmptyCompany)) AS RoomInventoryBalance
		|
		|GROUP BY
		|	RoomInventoryBalance.RoomType.IsModularStructure
		|
		|ORDER BY
		|	RoomTypeIsModularStructure";
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qCompany", Company);
		vQry.SetParameter("qEmptyCompany", Catalogs.Companies.EmptyRef());
		vQry.SetParameter("qTopRoomTypes", TopRoomTypes);
		vQryResult = vQry.Execute().Unload();

		For Each vQryResultRow In vQryResult Do
			vPage3Area.Parameters.mTotalTopRooms = vPage3Area.Parameters.mTotalTopRooms + vQryResultRow.TotalRoomsBalance;
			
			If vQryResultRow.RoomTypeIsModularStructure <> Null And vQryResultRow.RoomTypeIsModularStructure Then
				vPage3Area.Parameters.mTotalModularTopRooms = vQryResultRow.TotalRoomsBalance;
			EndIf;
		EndDo;
	EndIf;

	// Get number of new rooms added in period
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	AddRooms.RoomType.IsModularStructure AS RoomTypeIsModularStructure,
	|	COUNT(AddRooms.Ref) AS NewRoomsCount
	|FROM
	|	Document.AddRoom AS AddRooms
	|WHERE
	|	AddRooms.Date >= &qPeriodFrom
	|	AND AddRooms.Date <= &qPeriodTo
	|	AND AddRooms.Hotel = &qHotel
	|	AND (AddRooms.Room.Company = &qCompany
	|			OR AddRooms.Room.Company = &qEmptyCompany)
	|	AND (AddRooms.RoomType.Company = &qCompany
	|			OR AddRooms.RoomType.Company = &qEmptyCompany)
	|
	|GROUP BY
	|	AddRooms.RoomType.IsModularStructure
	|
	|ORDER BY
	|	RoomTypeIsModularStructure";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyCompany", Catalogs.Companies.EmptyRef());
	vQryResult = vQry.Execute().Unload();

	vPage3Area.Parameters.mNewRooms = 0;
	vPage3Area.Parameters.mNewModularRooms = 0;
	For Each vQryResultRow In vQryResult Do
		vPage3Area.Parameters.mNewRooms = vPage3Area.Parameters.mNewRooms + vQryResultRow.NewRoomsCount;
			
		If vQryResultRow.RoomTypeIsModularStructure <> Null And vQryResultRow.RoomTypeIsModularStructure Then
			vPage3Area.Parameters.mNewModularRooms = vQryResultRow.NewRoomsCount;
		EndIf;
	EndDo;
	
	// Get total number of rooms adopted for disabled
	vPage3Area.Parameters.mTotalAdoptedForDisabledRooms = 0;
	vPage3Area.Parameters.mTotalModularAdoptedForDisabledRooms = 0;
	If ValueIsFilled(TopRoomTypes) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	RoomsAdoptedForDisabled.RoomTypeIsModularStructure AS RoomTypeIsModularStructure,
		|	SUM(RoomsAdoptedForDisabled.TotalRoomsBalance) AS RoomsCount,
		|	SUM(RoomsAdoptedForDisabled.TotalBedsBalance) AS BedsCount
		|FROM
		|	(SELECT
		|		RoomInventoryBalance.Room AS Room,
		|		RoomInventoryBalance.RoomType.IsModularStructure AS RoomTypeIsModularStructure,
		|		RoomInventoryBalance.TotalRoomsBalance AS TotalRoomsBalance,
		|		RoomInventoryBalance.TotalBedsBalance AS TotalBedsBalance
		|	FROM
		|		AccumulationRegister.RoomInventory.Balance(
		|				&qPeriodTo,
		|				Hotel = &qHotel
		|					AND (Room.Company = &qCompany
		|						OR Room.Company = &qEmptyCompany)
		|					AND (RoomType.Company = &qCompany
		|						OR RoomType.Company = &qEmptyCompany)) AS RoomInventoryBalance
		|			INNER JOIN InformationRegister.RoomCharacteristics AS RoomChars
		|			ON RoomInventoryBalance.Room = RoomChars.Room
		|				AND (RoomChars.RoomCharacteristic = VALUE(ChartOfCharacteristicTypes.RoomCharacteristicTypes.IsAdaptedForDisabled))
		|				AND (CAST(RoomChars.RoomCharacteristicValue AS BOOLEAN))) AS RoomsAdoptedForDisabled
		|
		|GROUP BY
		|	RoomsAdoptedForDisabled.RoomTypeIsModularStructure
		|
		|ORDER BY
		|	RoomTypeIsModularStructure";
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qCompany", Company);
		vQry.SetParameter("qEmptyCompany", Catalogs.Companies.EmptyRef());
		vQryResult = vQry.Execute().Unload();

		For Each vQryResultRow In vQryResult Do
			vPage3Area.Parameters.mTotalAdoptedForDisabledRooms = vPage3Area.Parameters.mTotalAdoptedForDisabledRooms + vQryResultRow.RoomsCount;
			
			If vQryResultRow.RoomTypeIsModularStructure <> Null And vQryResultRow.RoomTypeIsModularStructure Then
				vPage3Area.Parameters.mTotalModularAdoptedForDisabledRooms = vQryResultRow.RoomsCount;
			EndIf;
		EndDo;
	EndIf;
	
	// Get total living area of rooms
	vPage3Area.Parameters.mTotalLivingArea = 0;
	vPage3Area.Parameters.mTotalModularLivingArea = 0;
	If ValueIsFilled(TopRoomTypes) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	RoomLivingAreas.RoomTypeIsModularStructure AS RoomTypeIsModularStructure,
		|	SUM(RoomLivingAreas.LivingArea) AS LivingArea
		|FROM
		|	(SELECT
		|		RoomInventoryBalance.Room AS Room,
		|		RoomInventoryBalance.RoomType.IsModularStructure AS RoomTypeIsModularStructure,
		|		RoomInventoryBalance.TotalRoomsBalance AS TotalRoomsBalance,
		|		CAST(RoomChars.RoomCharacteristicValue AS NUMBER(19, 7)) AS LivingArea
		|	FROM
		|		AccumulationRegister.RoomInventory.Balance(
		|				&qPeriodTo,
		|				Hotel = &qHotel
		|					AND (Room.Company = &qCompany
		|						OR Room.Company = &qEmptyCompany)
		|					AND (RoomType.Company = &qCompany
		|						OR RoomType.Company = &qEmptyCompany)) AS RoomInventoryBalance
		|			INNER JOIN InformationRegister.RoomCharacteristics AS RoomChars
		|			ON RoomInventoryBalance.Room = RoomChars.Room
		|				AND (RoomChars.RoomCharacteristic = VALUE(ChartOfCharacteristicTypes.RoomCharacteristicTypes.LivingArea))
		|				AND ((CAST(RoomChars.RoomCharacteristicValue AS NUMBER(19, 7))) <> 0)) AS RoomLivingAreas
		|
		|GROUP BY
		|	RoomLivingAreas.RoomTypeIsModularStructure
		|
		|ORDER BY
		|	RoomTypeIsModularStructure";
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qCompany", Company);
		vQry.SetParameter("qEmptyCompany", Catalogs.Companies.EmptyRef());
		vQryResult = vQry.Execute().Unload();

		For Each vQryResultRow In vQryResult Do
			vPage3Area.Parameters.mTotalLivingArea = vPage3Area.Parameters.mTotalLivingArea + vQryResultRow.LivingArea;
			
			If vQryResultRow.RoomTypeIsModularStructure <> Null And vQryResultRow.RoomTypeIsModularStructure Then
				vPage3Area.Parameters.mTotalModularLivingArea = vQryResultRow.LivingArea;
			EndIf;
		EndDo;
	EndIf;
	
	// Get total number of working days in the season
	If ValueIsFilled(Hotel) And Hotel.IsSeasonal Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	ISNULL(RoomSales.RoomType.IsModularStructure, FALSE) AS RoomTypeIsModularStructure,
		|	MIN(RoomSales.AccountingDate) AS MinAccountingDate,
		|	MAX(RoomSales.AccountingDate) AS MaxAccountingDate
		|FROM
		|	(SELECT
		|		RoomSalesTurnovers.RoomType AS RoomType,
		|		RoomSalesTurnovers.AccountingDate AS AccountingDate,
		|		RoomSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover
		|	FROM
		|		AccumulationRegister.Sales.Turnovers(
		|				&qPeriodFrom,
		|				&qPeriodTo,
		|				Period,
		|				NOT IsCorrection
		|					AND Hotel = &qHotel
		|					AND Company = &qCompany) AS RoomSalesTurnovers
		|	WHERE
		|		RoomSalesTurnovers.GuestDaysTurnover <> 0) AS RoomSales
		|
		|GROUP BY
		|	ISNULL(RoomSales.RoomType.IsModularStructure, FALSE)
		|
		|ORDER BY
		|	RoomTypeIsModularStructure";
		vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qCompany", Company);
		vQryResult = vQry.Execute().Unload();

		vPage3Area.Parameters.mWorkingDays = 0;
		vPage3Area.Parameters.mModularWorkingDays = 0;
		
		vMinAccountingDate = '39991231';
		vMaxAccountingDate = '00010101';
		
		For Each vQryResultRow In vQryResult Do
			If vQryResultRow.MinAccountingDate <> Null And vQryResultRow.MaxAccountingDate <> Null Then
				vMinAccountingDate = Min(vMinAccountingDate, vQryResultRow.MinAccountingDate);
				vMaxAccountingDate = Max(vMaxAccountingDate, vQryResultRow.MaxAccountingDate);
				
				If vQryResultRow.RoomTypeIsModularStructure <> Null And vQryResultRow.RoomTypeIsModularStructure Then
					vPage3Area.Parameters.mModularWorkingDays = (EndOfDay(vQryResultRow.MaxAccountingDate) - BegOfDay(vQryResultRow.MinAccountingDate))/(24*3600);
				EndIf;
			EndIf;
		EndDo;
		
		vPage3Area.Parameters.mWorkingDays = (EndOfDay(vMaxAccountingDate) - BegOfDay(vMinAccountingDate))/(24*3600);
		If vPage3Area.Parameters.mWorkingDays > 365 Then
			vPage3Area.Parameters.mWorkingDays = 365;
		EndIf;
		If vPage3Area.Parameters.mModularWorkingDays > 365 Then
			vPage3Area.Parameters.mModularWorkingDays = 365;
		EndIf;
	EndIf;
	
	// Get total number of guest days and number of checked in guests
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ISNULL(RoomSales.RoomType.IsModularStructure, FALSE) AS RoomTypeIsModularStructure,
	|	SUM(ISNULL(RoomSales.GuestDaysTurnover, 0)) AS GuestDaysTurnover,
	|	SUM(ISNULL(RoomSales.GuestDays18Turnover, 0)) AS GuestDays18Turnover,
	|	SUM(ISNULL(RoomSales.GuestDays1855Turnover, 0)) AS GuestDays1855Turnover,
	|	SUM(ISNULL(RoomSales.GuestDays55Turnover, 0)) AS GuestDays55Turnover,
	|	SUM(ISNULL(RoomSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover,
	|	SUM(ISNULL(RoomSales.GuestsCheckedIn18Turnover, 0)) AS GuestsCheckedIn18Turnover,
	|	SUM(ISNULL(RoomSales.GuestsCheckedIn1855Turnover, 0)) AS GuestsCheckedIn1855Turnover,
	|	SUM(ISNULL(RoomSales.GuestsCheckedIn55Turnover, 0)) AS GuestsCheckedIn55Turnover
	|FROM
	|	(SELECT
	|		RoomSalesTurnovers.RoomType AS RoomType,
	|		RoomSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover,
	|		CASE
	|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL
	|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND RoomSalesTurnovers.Client.Age < 18
	|				THEN RoomSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays18Turnover,
	|		CASE
	|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL
	|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND RoomSalesTurnovers.Client.Age >= 18
	|					AND RoomSalesTurnovers.Client.Age < 55
	|				THEN RoomSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays1855Turnover,
	|		CASE
	|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL
	|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND RoomSalesTurnovers.Client.Age >= 55
	|				THEN RoomSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays55Turnover,
	|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
	|		CASE
	|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL
	|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND RoomSalesTurnovers.Client.Age < 18
	|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn18Turnover,
	|		CASE
	|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL
	|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND RoomSalesTurnovers.Client.Age >= 18
	|					AND RoomSalesTurnovers.Client.Age < 55
	|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn1855Turnover,
	|		CASE
	|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL
	|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND RoomSalesTurnovers.Client.Age >= 55
	|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn55Turnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection
	|					AND Hotel = &qHotel
	|					AND Company = &qCompany) AS RoomSalesTurnovers) AS RoomSales
	|
	|GROUP BY
	|	ISNULL(RoomSales.RoomType.IsModularStructure, FALSE)
	|
	|ORDER BY
	|	RoomTypeIsModularStructure";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyDate", '00010101');
	vQryResult = vQry.Execute().Unload();

	vTotalGuestDays = 0;
	vTotalGuestDays18 = 0;
	vTotalGuestDays1855 = 0;
	vTotalGuestDays55 = 0;
	
	vTotalGuests = 0;
	vTotalGuests18 = 0;
	vTotalGuests1855 = 0;
	vTotalGuests55 = 0;

	vTotalModularGuestDays = 0;
	vTotalModularGuestDays18 = 0;
	vTotalModularGuestDays1855 = 0;
	vTotalModularGuestDays55 = 0;
	
	vTotalModularGuests = 0;
	vTotalModularGuests18 = 0;
	vTotalModularGuests1855 = 0;
	vTotalModularGuests55 = 0;

	vPage3Area.Parameters.mTotalGuestDays = 0;
	vPage3Area.Parameters.mTotalGuestDays18 = 0;
	vPage3Area.Parameters.mTotalGuestDays1855 = 0;
	vPage3Area.Parameters.mTotalGuestDays55 = 0;
	vPage3Area.Parameters.mTotalGuests = 0;
	vPage3Area.Parameters.mTotalGuests18 = 0;
	vPage3Area.Parameters.mTotalGuests1855 = 0;
	vPage3Area.Parameters.mTotalGuests55 = 0;

	vPage3Area.Parameters.mTotalModularGuestDays = 0;
	vPage3Area.Parameters.mTotalModularGuestDays18 = 0;
	vPage3Area.Parameters.mTotalModularGuestDays1855 = 0;
	vPage3Area.Parameters.mTotalModularGuestDays55 = 0;
	vPage3Area.Parameters.mTotalModularGuests = 0;
	vPage3Area.Parameters.mTotalModularGuests18 = 0;
	vPage3Area.Parameters.mTotalModularGuests1855 = 0;
	vPage3Area.Parameters.mTotalModularGuests55 = 0;
	
	For Each vQryResultRow In vQryResult Do
		vPage3Area.Parameters.mTotalGuestDays = vPage3Area.Parameters.mTotalGuestDays + vQryResultRow.GuestDaysTurnover;
		vPage3Area.Parameters.mTotalGuestDays18 = vPage3Area.Parameters.mTotalGuestDays18 + vQryResultRow.GuestDays18Turnover;
		vPage3Area.Parameters.mTotalGuestDays1855 = vPage3Area.Parameters.mTotalGuestDays1855 + vQryResultRow.GuestDays1855Turnover;
		vPage3Area.Parameters.mTotalGuestDays55 = vPage3Area.Parameters.mTotalGuestDays55 + vQryResultRow.GuestDays55Turnover;
		vPage3Area.Parameters.mTotalGuests = vPage3Area.Parameters.mTotalGuests + vQryResultRow.GuestsCheckedInTurnover;
		vPage3Area.Parameters.mTotalGuests18 = vPage3Area.Parameters.mTotalGuests18 + vQryResultRow.GuestsCheckedIn18Turnover;
		vPage3Area.Parameters.mTotalGuests1855 = vPage3Area.Parameters.mTotalGuests1855 + vQryResultRow.GuestsCheckedIn1855Turnover;
		vPage3Area.Parameters.mTotalGuests55 = vPage3Area.Parameters.mTotalGuests55 + vQryResultRow.GuestsCheckedIn55Turnover;

		vTotalGuestDays = vTotalGuestDays + vQryResultRow.GuestDaysTurnover;
		vTotalGuestDays18 = vTotalGuestDays18 + vQryResultRow.GuestDays18Turnover;
		vTotalGuestDays1855 = vTotalGuestDays1855 + vQryResultRow.GuestDays1855Turnover;
		vTotalGuestDays55 = vTotalGuestDays55 + vQryResultRow.GuestDays55Turnover;
		vTotalGuests = vTotalGuests + vQryResultRow.GuestsCheckedInTurnover;
		vTotalGuests18 = vTotalGuests18 + vQryResultRow.GuestsCheckedIn18Turnover;
		vTotalGuests1855 = vTotalGuests1855 + vQryResultRow.GuestsCheckedIn1855Turnover;
		vTotalGuests55 = vTotalGuests55 + vQryResultRow.GuestsCheckedIn55Turnover;
		
		If vQryResultRow.RoomTypeIsModularStructure <> Null And vQryResultRow.RoomTypeIsModularStructure Then
			vPage3Area.Parameters.mTotalModularGuestDays = vQryResultRow.GuestDaysTurnover;
			vPage3Area.Parameters.mTotalModularGuestDays18 = vQryResultRow.GuestDays18Turnover;
			vPage3Area.Parameters.mTotalModularGuestDays1855 = vQryResultRow.GuestDays1855Turnover;
			vPage3Area.Parameters.mTotalModularGuestDays55 = vQryResultRow.GuestDays55Turnover;
			vPage3Area.Parameters.mTotalModularGuests = vQryResultRow.GuestsCheckedInTurnover;
			vPage3Area.Parameters.mTotalModularGuests18 = vQryResultRow.GuestsCheckedIn18Turnover;
			vPage3Area.Parameters.mTotalModularGuests1855 = vQryResultRow.GuestsCheckedIn1855Turnover;
			vPage3Area.Parameters.mTotalModularGuests55 = vQryResultRow.GuestsCheckedIn55Turnover;

			vTotalModularGuestDays = vQryResultRow.GuestDaysTurnover;
			vTotalModularGuestDays18 = vQryResultRow.GuestDays18Turnover;
			vTotalModularGuestDays1855 = vQryResultRow.GuestDays1855Turnover;
			vTotalModularGuestDays55 = vQryResultRow.GuestDays55Turnover;
			vTotalModularGuests = vQryResultRow.GuestsCheckedInTurnover;
			vTotalModularGuests18 = vQryResultRow.GuestsCheckedIn18Turnover;
			vTotalModularGuests1855 = vQryResultRow.GuestsCheckedIn1855Turnover;
			vTotalModularGuests55 = vQryResultRow.GuestsCheckedIn55Turnover;
		EndIf;
	EndDo;
	
	// 3.4 Get total number of guest days and checked-in guests from Russia
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ISNULL(GeoSales.RoomType.IsModularStructure, FALSE) AS RoomTypeIsModularStructure,
	|	SUM(ISNULL(GeoSales.GuestDaysTurnover, 0)) AS GuestDaysTurnover,
	|	SUM(ISNULL(GeoSales.GuestDays18Turnover, 0)) AS GuestDays18Turnover,
	|	SUM(ISNULL(GeoSales.GuestDays1855Turnover, 0)) AS GuestDays1855Turnover,
	|	SUM(ISNULL(GeoSales.GuestDays55Turnover, 0)) AS GuestDays55Turnover,
	|	SUM(ISNULL(GeoSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover,
	|	SUM(ISNULL(GeoSales.GuestsCheckedIn18Turnover, 0)) AS GuestsCheckedIn18Turnover,
	|	SUM(ISNULL(GeoSales.GuestsCheckedIn1855Turnover, 0)) AS GuestsCheckedIn1855Turnover,
	|	SUM(ISNULL(GeoSales.GuestsCheckedIn55Turnover, 0)) AS GuestsCheckedIn55Turnover
	|FROM
	|	(SELECT
	|		GeoSalesTurnovers.RoomType AS RoomType,
	|		GeoSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age < 18
	|				THEN GeoSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays18Turnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age >= 18
	|					AND GeoSalesTurnovers.Client.Age < 55
	|				THEN GeoSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays1855Turnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age >= 55
	|				THEN GeoSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays55Turnover,
	|		GeoSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age < 18
	|				THEN GeoSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn18Turnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age >= 18
	|					AND GeoSalesTurnovers.Client.Age < 55
	|				THEN GeoSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn1855Turnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age >= 55
	|				THEN GeoSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn55Turnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection
	|					AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND (Client.Citizenship = &qRussia
	|						OR ISNULL(Client.Citizenship.Description, """") = """")) AS GeoSalesTurnovers) AS GeoSales
	|
	|GROUP BY
	|	ISNULL(GeoSales.RoomType.IsModularStructure, FALSE)
	|
	|ORDER BY
	|	RoomTypeIsModularStructure";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyDate", '00010101');
	vQryResult = vQry.Execute().Unload();

	vRussiaGuestDays = 0;
	vRussiaGuestDays18 = 0;
	vRussiaGuestDays1855 = 0;
	vRussiaGuestDays55 = 0;
	vRussiaGuests = 0;
	vRussiaGuests18 = 0;
	vRussiaGuests1855 = 0;
	vRussiaGuests55 = 0;

	vRussiaModularGuestDays = 0;
	vRussiaModularGuestDays18 = 0;
	vRussiaModularGuestDays1855 = 0;
	vRussiaModularGuestDays55 = 0;
	vRussiaModularGuests = 0;
	vRussiaModularGuests18 = 0;
	vRussiaModularGuests1855 = 0;
	vRussiaModularGuests55 = 0;
	
	vPage3Area.Parameters.mTotalGuestDaysRus = 0;
	vPage3Area.Parameters.mTotalGuestDaysRus18 = 0;
	vPage3Area.Parameters.mTotalGuestDaysRus1855 = 0;
	vPage3Area.Parameters.mTotalGuestDaysRus55 = 0;
	vPage3Area.Parameters.mTotalGuestsRus = 0;
	vPage3Area.Parameters.mTotalGuestsRus18 = 0;
	vPage3Area.Parameters.mTotalGuestsRus1855 = 0;
	vPage3Area.Parameters.mTotalGuestsRus55 = 0;
	
	vPage3Area.Parameters.mTotalModularGuestDaysRus = 0;
	vPage3Area.Parameters.mTotalModularGuestDaysRus18 = 0;
	vPage3Area.Parameters.mTotalModularGuestDaysRus1855 = 0;
	vPage3Area.Parameters.mTotalModularGuestDaysRus55 = 0;
	vPage3Area.Parameters.mTotalModularGuestsRus = 0;
	vPage3Area.Parameters.mTotalModularGuestsRus18 = 0;
	vPage3Area.Parameters.mTotalModularGuestsRus1855 = 0;
	vPage3Area.Parameters.mTotalModularGuestsRus55 = 0;

	For Each vQryResultRow In vQryResult Do
		vPage3Area.Parameters.mTotalGuestDaysRus = vPage3Area.Parameters.mTotalGuestDaysRus + vQryResultRow.GuestDaysTurnover;
		vPage3Area.Parameters.mTotalGuestDaysRus18 = vPage3Area.Parameters.mTotalGuestDaysRus18 + vQryResultRow.GuestDays18Turnover;
		vPage3Area.Parameters.mTotalGuestDaysRus1855 = vPage3Area.Parameters.mTotalGuestDaysRus1855 + vQryResultRow.GuestDays1855Turnover;
		vPage3Area.Parameters.mTotalGuestDaysRus55 = vPage3Area.Parameters.mTotalGuestDaysRus55 + vQryResultRow.GuestDays55Turnover;
		vPage3Area.Parameters.mTotalGuestsRus = vPage3Area.Parameters.mTotalGuestsRus + vQryResultRow.GuestsCheckedInTurnover;
		vPage3Area.Parameters.mTotalGuestsRus18 = vPage3Area.Parameters.mTotalGuestsRus18 + vQryResultRow.GuestsCheckedIn18Turnover;
		vPage3Area.Parameters.mTotalGuestsRus1855 = vPage3Area.Parameters.mTotalGuestsRus1855 + vQryResultRow.GuestsCheckedIn1855Turnover;
		vPage3Area.Parameters.mTotalGuestsRus55 = vPage3Area.Parameters.mTotalGuestsRus55 + vQryResultRow.GuestsCheckedIn55Turnover;
		
		vRussiaGuestDays = vRussiaGuestDays + vQryResultRow.GuestDaysTurnover;
		vRussiaGuestDays18 = vRussiaGuestDays18 + vQryResultRow.GuestDays18Turnover;
		vRussiaGuestDays1855 = vRussiaGuestDays1855 + vQryResultRow.GuestDays1855Turnover;
		vRussiaGuestDays55 = vRussiaGuestDays55 + vQryResultRow.GuestDays55Turnover;
		vRussiaGuests = vRussiaGuests + vQryResultRow.GuestsCheckedInTurnover;
		vRussiaGuests18 = vRussiaGuests18 + vQryResultRow.GuestsCheckedIn18Turnover;
		vRussiaGuests1855 = vRussiaGuests1855 + vQryResultRow.GuestsCheckedIn1855Turnover;
		vRussiaGuests55 = vRussiaGuests55 + vQryResultRow.GuestsCheckedIn55Turnover;
		
		If vQryResultRow.RoomTypeIsModularStructure <> Null And vQryResultRow.RoomTypeIsModularStructure Then
			vPage3Area.Parameters.mTotalModularGuestDaysRus = vQryResultRow.GuestDaysTurnover;
			vPage3Area.Parameters.mTotalModularGuestDaysRus18 = vQryResultRow.GuestDays18Turnover;
			vPage3Area.Parameters.mTotalModularGuestDaysRus1855 = vQryResultRow.GuestDays1855Turnover;
			vPage3Area.Parameters.mTotalModularGuestDaysRus55 = vQryResultRow.GuestDays55Turnover;
			vPage3Area.Parameters.mTotalModularGuestsRus = vQryResultRow.GuestsCheckedInTurnover;
			vPage3Area.Parameters.mTotalModularGuestsRus18 = vQryResultRow.GuestsCheckedIn18Turnover;
			vPage3Area.Parameters.mTotalModularGuestsRus1855 = vQryResultRow.GuestsCheckedIn1855Turnover;
			vPage3Area.Parameters.mTotalModularGuestsRus55 = vQryResultRow.GuestsCheckedIn55Turnover;
			
			vRussiaModularGuestDays = vQryResultRow.GuestDaysTurnover;
			vRussiaModularGuestDays18 = vQryResultRow.GuestDays18Turnover;
			vRussiaModularGuestDays1855 = vQryResultRow.GuestDays1855Turnover;
			vRussiaModularGuestDays55 = vQryResultRow.GuestDays55Turnover;
			vRussiaModularGuests = vQryResultRow.GuestsCheckedInTurnover;
			vRussiaModularGuests18 = vQryResultRow.GuestsCheckedIn18Turnover;
			vRussiaModularGuests1855 = vQryResultRow.GuestsCheckedIn1855Turnover;
			vRussiaModularGuests55 = vQryResultRow.GuestsCheckedIn55Turnover;
		EndIf;
	EndDo;
	
	// 3.5 Get total number of guest days and checked-in foreigner guests
	If vTotalGuests <> Null And vRussiaGuests <> Null Then
		vPage3Area.Parameters.mTotalGuestDaysForeigners = vTotalGuestDays - vRussiaGuestDays;
		vPage3Area.Parameters.mTotalGuestDaysForeigners18 = vTotalGuestDays18 - vRussiaGuestDays18;
		vPage3Area.Parameters.mTotalGuestDaysForeigners1855 = vTotalGuestDays1855 - vRussiaGuestDays1855;
		vPage3Area.Parameters.mTotalGuestDaysForeigners55 = vTotalGuestDays55 - vRussiaGuestDays55;
		vPage3Area.Parameters.mTotalGuestsForeigners = vTotalGuests - vRussiaGuests;
		vPage3Area.Parameters.mTotalGuestsForeigners18 = vTotalGuests18 - vRussiaGuests18;
		vPage3Area.Parameters.mTotalGuestsForeigners1855 = vTotalGuests1855 - vRussiaGuests1855;
		vPage3Area.Parameters.mTotalGuestsForeigners55 = vTotalGuests55 - vRussiaGuests55;

		vPage3Area.Parameters.mTotalModularGuestDaysForeigners = vTotalModularGuestDays - vRussiaModularGuestDays;
		vPage3Area.Parameters.mTotalModularGuestDaysForeigners18 = vTotalModularGuestDays18 - vRussiaModularGuestDays18;
		vPage3Area.Parameters.mTotalModularGuestDaysForeigners1855 = vTotalModularGuestDays1855 - vRussiaModularGuestDays1855;
		vPage3Area.Parameters.mTotalModularGuestDaysForeigners55 = vTotalModularGuestDays55 - vRussiaModularGuestDays55;
		vPage3Area.Parameters.mTotalModularGuestsForeigners = vTotalModularGuests - vRussiaModularGuests;
		vPage3Area.Parameters.mTotalModularGuestsForeigners18 = vTotalModularGuests18 - vRussiaModularGuests18;
		vPage3Area.Parameters.mTotalModularGuestsForeigners1855 = vTotalModularGuests1855 - vRussiaModularGuests1855;
		vPage3Area.Parameters.mTotalModularGuestsForeigners55 = vTotalModularGuests55 - vRussiaModularGuests55;
	Else
		vPage3Area.Parameters.mTotalGuestDaysForeigners = 0;
		vPage3Area.Parameters.mTotalGuestDaysForeigners18 = 0;
		vPage3Area.Parameters.mTotalGuestDaysForeigners1855 = 0;
		vPage3Area.Parameters.mTotalGuestDaysForeigners55 = 0;
		vPage3Area.Parameters.mTotalGuestsForeigners = 0;
		vPage3Area.Parameters.mTotalGuestsForeigners18 = 0;
		vPage3Area.Parameters.mTotalGuestsForeigners1855 = 0;
		vPage3Area.Parameters.mTotalGuestsForeigners55 = 0;

		vPage3Area.Parameters.mTotalModularGuestDaysForeigners = 0;
		vPage3Area.Parameters.mTotalModularGuestDaysForeigners18 = 0;
		vPage3Area.Parameters.mTotalModularGuestDaysForeigners1855 = 0;
		vPage3Area.Parameters.mTotalModularGuestDaysForeigners55 = 0;
		vPage3Area.Parameters.mTotalModularGuestsForeigners = 0;
		vPage3Area.Parameters.mTotalModularGuestsForeigners18 = 0;
		vPage3Area.Parameters.mTotalModularGuestsForeigners1855 = 0;
		vPage3Area.Parameters.mTotalModularGuestsForeigners55 = 0;
	EndIf;
	
	// 3.6 Get total number of checked-in guests with tour tickets
	vPage3Area.Parameters.mTotalTourTicketGuests = 0;
	vPage3Area.Parameters.mTotalTourTicketGuests18 = 0;
	vPage3Area.Parameters.mTotalTourTicketGuests1855 = 0;
	vPage3Area.Parameters.mTotalTourTicketGuests55 = 0;
	If ValueIsFilled(TourTicketIncomeServiceGroup) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	SUM(ISNULL(RoomSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover,
		|	SUM(ISNULL(RoomSales.GuestsCheckedIn18Turnover, 0)) AS GuestsCheckedIn18Turnover,
		|	SUM(ISNULL(RoomSales.GuestsCheckedIn1855Turnover, 0)) AS GuestsCheckedIn1855Turnover,
		|	SUM(ISNULL(RoomSales.GuestsCheckedIn55Turnover, 0)) AS GuestsCheckedIn55Turnover
		|FROM
		|	(SELECT
		|		RoomSalesTurnovers.Client AS Client,
		|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL
		|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					AND RoomSalesTurnovers.Client.Age < 18
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			ELSE 0
		|		END AS GuestsCheckedIn18Turnover,
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL
		|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					AND RoomSalesTurnovers.Client.Age >= 18
		|					AND RoomSalesTurnovers.Client.Age < 55
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			ELSE 0
		|		END AS GuestsCheckedIn1855Turnover,
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL
		|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					AND RoomSalesTurnovers.Client.Age >= 55
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			ELSE 0
		|		END AS GuestsCheckedIn55Turnover
		|	FROM
		|		AccumulationRegister.Sales.Turnovers(
		|				&qPeriodFrom,
		|				&qPeriodTo,
		|				Period,
		|				NOT IsCorrection
		|					AND Hotel = &qHotel
		|					AND Company = &qCompany
		|					AND (Service IN HIERARCHY (&qTourTicketServices)
		|						OR NOT &qUseServicesList)) AS RoomSalesTurnovers) AS RoomSales";
		vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qCompany", Company);
		vUseServicesList = False;
		vServicesList = New ValueList();
		If Not TourTicketIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(TourTicketIncomeServiceGroup);
		EndIf;
		vQry.SetParameter("qUseServicesList", vUseServicesList);
		vQry.SetParameter("qTourTicketServices", vServicesList);
		vQry.SetParameter("qEmptyDate", '00010101');
		vQryResult = vQry.Execute().Unload();

		If vQryResult.Count() > 0 Then
			vRow = vQryResult.Get(0);
			
			vPage3Area.Parameters.mTotalTourTicketGuests = vRow.GuestsCheckedInTurnover;
			vPage3Area.Parameters.mTotalTourTicketGuests18 = vRow.GuestsCheckedIn18Turnover;
			vPage3Area.Parameters.mTotalTourTicketGuests1855 = vRow.GuestsCheckedIn1855Turnover;
			vPage3Area.Parameters.mTotalTourTicketGuests55 = vRow.GuestsCheckedIn55Turnover;
		EndIf;
		
		// The same from russia
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	SUM(ISNULL(RoomSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover,
		|	SUM(ISNULL(RoomSales.GuestsCheckedIn18Turnover, 0)) AS GuestsCheckedIn18Turnover,
		|	SUM(ISNULL(RoomSales.GuestsCheckedIn1855Turnover, 0)) AS GuestsCheckedIn1855Turnover,
		|	SUM(ISNULL(RoomSales.GuestsCheckedIn55Turnover, 0)) AS GuestsCheckedIn55Turnover
		|FROM
		|	(SELECT
		|		RoomSalesTurnovers.Client AS Client,
		|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL
		|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					AND RoomSalesTurnovers.Client.Age < 18
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			ELSE 0
		|		END AS GuestsCheckedIn18Turnover,
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL
		|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					AND RoomSalesTurnovers.Client.Age >= 18
		|					AND RoomSalesTurnovers.Client.Age < 55
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			ELSE 0
		|		END AS GuestsCheckedIn1855Turnover,
		|		CASE
		|			WHEN NOT RoomSalesTurnovers.Client.DateOfBirth IS NULL
		|					AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					AND RoomSalesTurnovers.Client.Age >= 55
		|				THEN RoomSalesTurnovers.GuestsCheckedInTurnover
		|			ELSE 0
		|		END AS GuestsCheckedIn55Turnover
		|	FROM
		|		AccumulationRegister.Sales.Turnovers(
		|				&qPeriodFrom,
		|				&qPeriodTo,
		|				Period,
		|				NOT IsCorrection
		|					AND Hotel = &qHotel
		|					AND Company = &qCompany
		|					AND (Service IN HIERARCHY (&qTourTicketServices)
		|						OR NOT &qUseServicesList)
		|					AND (Client.Citizenship = &qRussia
		|						OR ISNULL(Client.Citizenship.Description, """") = """")) AS RoomSalesTurnovers) AS RoomSales";
		vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qRussia", RussiaCountry);
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qCompany", Company);
		vUseServicesList = False;
		vServicesList = New ValueList();
		If Not TourTicketIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(TourTicketIncomeServiceGroup);
		EndIf;
		vQry.SetParameter("qUseServicesList", vUseServicesList);
		vQry.SetParameter("qTourTicketServices", vServicesList);
		vQry.SetParameter("qEmptyDate", '00010101');
		vQryResult = vQry.Execute().Unload();

		If vQryResult.Count() > 0 Then
			vRow = vQryResult.Get(0);
			vPage3Area.Parameters.mTotalTourTicketGuestsRus = ?(vRow.GuestsCheckedInTurnover = Null, 0, vRow.GuestsCheckedInTurnover);
			vPage3Area.Parameters.mTotalTourTicketGuestsRus18 = ?(vRow.GuestsCheckedIn18Turnover = Null, 0, vRow.GuestsCheckedIn18Turnover);
			vPage3Area.Parameters.mTotalTourTicketGuestsRus1855 = ?(vRow.GuestsCheckedIn1855Turnover = Null, 0, vRow.GuestsCheckedIn1855Turnover);
			vPage3Area.Parameters.mTotalTourTicketGuestsRus55 = ?(vRow.GuestsCheckedIn55Turnover = Null, 0, vRow.GuestsCheckedIn55Turnover);
			
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners = ?(vPage3Area.Parameters.mTotalTourTicketGuests = Null, 0, vPage3Area.Parameters.mTotalTourTicketGuests) - ?(vRow.GuestsCheckedInTurnover = Null, 0, vRow.GuestsCheckedInTurnover);
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners18 = ?(vPage3Area.Parameters.mTotalTourTicketGuests18 = Null, 0, vPage3Area.Parameters.mTotalTourTicketGuests18) - ?(vRow.GuestsCheckedIn18Turnover = Null, 0, vRow.GuestsCheckedIn18Turnover);
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners1855 = ?(vPage3Area.Parameters.mTotalTourTicketGuests1855 = Null, 0, vPage3Area.Parameters.mTotalTourTicketGuests1855) - ?(vRow.GuestsCheckedIn1855Turnover = Null, 0, vRow.GuestsCheckedIn1855Turnover);
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners55 = ?(vPage3Area.Parameters.mTotalTourTicketGuests55 = Null, 0, vPage3Area.Parameters.mTotalTourTicketGuests55) - ?(vRow.GuestsCheckedIn55Turnover = Null, 0, vRow.GuestsCheckedIn55Turnover);
		Else
			vPage3Area.Parameters.mTotalTourTicketGuestsRus = 0;
			vPage3Area.Parameters.mTotalTourTicketGuestsRus18 = 0;
			vPage3Area.Parameters.mTotalTourTicketGuestsRus1855 = 0;
			vPage3Area.Parameters.mTotalTourTicketGuestsRus55 = 0;
			
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners = 0;
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners18 = 0;
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners1855 = 0;
			vPage3Area.Parameters.mTotalTourTicketGuestsForeigners55 = 0;
		EndIf;
	EndIf;
	
	// Disabled guests
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SUM(ISNULL(GeoSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover,
	|	SUM(ISNULL(GeoSales.GuestsCheckedIn18Turnover, 0)) AS GuestsCheckedIn18Turnover,
	|	SUM(ISNULL(GeoSales.GuestsCheckedIn1855Turnover, 0)) AS GuestsCheckedIn1855Turnover,
	|	SUM(ISNULL(GeoSales.GuestsCheckedIn55Turnover, 0)) AS GuestsCheckedIn55Turnover
	|FROM
	|	(SELECT
	|		GeoSalesTurnovers.RoomType AS RoomType,
	|		GeoSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age < 18
	|				THEN GeoSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays18Turnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age >= 18
	|					AND GeoSalesTurnovers.Client.Age < 55
	|				THEN GeoSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays1855Turnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age >= 55
	|				THEN GeoSalesTurnovers.GuestDaysTurnover
	|			ELSE 0
	|		END AS GuestDays55Turnover,
	|		GeoSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age < 18
	|				THEN GeoSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn18Turnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age >= 18
	|					AND GeoSalesTurnovers.Client.Age < 55
	|				THEN GeoSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn1855Turnover,
	|		CASE
	|			WHEN NOT GeoSalesTurnovers.Client.DateOfBirth IS NULL
	|					AND GeoSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
	|					AND GeoSalesTurnovers.Client.Age >= 55
	|				THEN GeoSalesTurnovers.GuestsCheckedInTurnover
	|			ELSE 0
	|		END AS GuestsCheckedIn55Turnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection
	|					AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND (Client.Citizenship = &qRussia
	|						OR ISNULL(Client.Citizenship.Description, """") = """")
	|					AND Client.Disablement <> """") AS GeoSalesTurnovers) AS GeoSales";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyDate", '00010101');
	vQryResult = vQry.Execute().Unload();

	vPage3Area.Parameters.mTotalDisabledGuests = 0;
	vPage3Area.Parameters.mTotalDisabledGuests18 = 0;
	vPage3Area.Parameters.mTotalDisabledGuests1855 = 0;
	vPage3Area.Parameters.mTotalDisabledGuests55 = 0;
	
	If vQryResult.Count() > 0 Then
		vQryResultRow = vQryResult.Get(0);

		vPage3Area.Parameters.mTotalDisabledGuests = vQryResultRow.GuestsCheckedInTurnover;
		vPage3Area.Parameters.mTotalDisabledGuests18 = vQryResultRow.GuestsCheckedIn18Turnover;
		vPage3Area.Parameters.mTotalDisabledGuests1855 = vQryResultRow.GuestsCheckedIn1855Turnover;
		vPage3Area.Parameters.mTotalDisabledGuests55 = vQryResultRow.GuestsCheckedIn55Turnover;
	EndIf;
	
	pSpreadsheet.Put(vPage3Area);
	
	FillPropertyValues(ReportParameters, vPage3Area.Parameters);
	
	// Page 3 header Spr. 1
	pSpreadsheet.Put(vPage3H1Area);
	
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ISNULL(GeoSales.Client.Citizenship.Description, """") AS CountryDescription,
	|	ISNULL(GeoSales.Client.Citizenship.Code, 0) AS CountryCode,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover,
	|	SUM(GeoSales.GuestDaysTurnover) AS GuestDaysTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			NOT IsCorrection
	|				AND Hotel = &qHotel
	|				AND Company = &qCompany
	|				AND Client.Citizenship <> &qRussia
	|				AND ISNULL(Client.Citizenship.Description, """") <> """") AS GeoSales
	|
	|GROUP BY
	|	GeoSales.Client.Citizenship.Description,
	|	GeoSales.Client.Citizenship.Code
	|
	|ORDER BY
	|	GeoSales.Client.Citizenship.Code";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQryResult = vQry.Execute().Unload();
	
	ReportParameters.mCountry = New Structure("RowsArray", New Array);
	c = 0;
	While c < vQryResult.Count() Do
		vQryResultRow = vQryResult.Get(c);
		
		vPage3H1RowArea.Parameters.mCountry = TrimAll(vQryResultRow.CountryDescription);
		vPage3H1RowArea.Parameters.mCountryCode = TrimAll(vQryResultRow.CountryCode);
		vPage3H1RowArea.Parameters.mCountryGuests = vQryResultRow.GuestsCheckedInTurnover;
		vPage3H1RowArea.Parameters.mCountryGuestDays = vQryResultRow.GuestDaysTurnover;
		
		pSpreadsheet.Put(vPage3H1RowArea);
		
		c = c + 1;
		
		ReportParameters.mCountry.RowsArray.Add(New Structure("mCountry, mCountryCode, mCountryGuests, mCountryGuestDays",
			vPage3H1RowArea.Parameters.mCountry,
			vPage3H1RowArea.Parameters.mCountryCode,
			vPage3H1RowArea.Parameters.mCountryGuests,
			vPage3H1RowArea.Parameters.mCountryGuestDays));
		
	EndDo;
	
	// Get number of checked in guests by hotel products (Page 3. Spr 2)
	vPage3H2Area.Parameters.mVaucherQuantity = 0;
	vPage3H2Area.Parameters.mVaucher18Quantity = 0;
	vPage3H2Area.Parameters.mVaucher1855Quantity = 0;
	vPage3H2Area.Parameters.mVaucher55Quantity = 0;
	
	If ValueIsFilled(VaucherIncomeServiceGroup) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	SUM(AgeSales.VaucherQuantity) AS VaucherQuantity,
		|	SUM(AgeSales.Vaucher18Quantity) AS Vaucher18Quantity,
		|	SUM(AgeSales.Vaucher1855Quantity) AS Vaucher1855Quantity,
		|	SUM(AgeSales.Vaucher55Quantity) AS Vaucher55Quantity
		|FROM
		|	(SELECT
		|		RoomSalesTurnovers.Client AS Client,
		|		RoomSalesTurnovers.Client.Age AS ClientAge,
		|		MAX(1) AS VaucherQuantity,
		|		MAX(CASE
		|				WHEN RoomSalesTurnovers.Client.Age < 18
		|						AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					THEN 1
		|				ELSE 0
		|			END) AS Vaucher18Quantity,
		|		MAX(CASE
		|				WHEN RoomSalesTurnovers.Client.Age >= 18
		|						AND RoomSalesTurnovers.Client.Age < 54
		|						AND RoomSalesTurnovers.Client.DateOfBirth <> &qEmptyDate
		|					THEN 1
		|				ELSE 0
		|			END) AS Vaucher1855Quantity,
		|		MAX(CASE
		|				WHEN RoomSalesTurnovers.Client.Age >= 55
		|					THEN 1
		|				ELSE 0
		|			END) AS Vaucher55Quantity
		|	FROM
		|		AccumulationRegister.Sales.Turnovers(
		|				&qPeriodFrom,
		|				&qPeriodTo,
		|				Period,
		|				NOT IsCorrection
		|					AND Hotel = &qHotel
		|					AND Company = &qCompany
		|					AND (Service IN HIERARCHY (&qVaucherServices)
		|						OR NOT &qUseServicesList)) AS RoomSalesTurnovers
		|	
		|	GROUP BY
		|		RoomSalesTurnovers.Client,
		|		RoomSalesTurnovers.Client.Age) AS AgeSales";
		vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qCompany", Company);
		vQry.SetParameter("qEmptyDate", '00010101');
		vUseServicesList = False;
		vServicesList = New ValueList();
		If Not TourTicketIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(VaucherIncomeServiceGroup);
		EndIf;
		vQry.SetParameter("qUseServicesList", vUseServicesList);
		vQry.SetParameter("qVaucherServices", vServicesList);
		vQryResult = vQry.Execute().Unload();

		If vQryResult.Count() > 0 Then
			vRow = vQryResult.Get(0);
			
			vPage3H2Area.Parameters.mVaucherQuantity = vRow.VaucherQuantity;
			vPage3H2Area.Parameters.mVaucher18Quantity = vRow.Vaucher18Quantity;
			vPage3H2Area.Parameters.mVaucher1855Quantity = vRow.Vaucher1855Quantity;
			vPage3H2Area.Parameters.mVaucher55Quantity = vRow.Vaucher55Quantity;
		EndIf;
	EndIf;
	
	pSpreadsheet.Put(vPage3H2Area);
	
	FillPropertyValues(ReportParameters, vPage3H2Area.Parameters);
	
	pSpreadsheet.PutHorizontalPageBreak();
	
	// Page 4
	
	// 4.1.1 Get total number of russian checked-in guests per trip purposes
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qStudy
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qOther
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTransit
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qRecreation
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qPilgrims
	|			THEN 4
	|		WHEN GeoSales.TripPurpose = &qShopping
	|			THEN 5
	|		ELSE 5
	|	END AS TripPurposeType,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		GeoSalesTurnovers.TripPurpose AS TripPurpose,
	|		SUM(GeoSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND (Client.Citizenship = &qRussia
	|						OR ISNULL(Client.Citizenship.Description, """") = """")) AS GeoSalesTurnovers
	|	
	|	GROUP BY
	|		GeoSalesTurnovers.TripPurpose) AS GeoSales
	|
	|GROUP BY
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qStudy
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qOther
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTransit
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qRecreation
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qPilgrims
	|			THEN 4
	|		WHEN GeoSales.TripPurpose = &qShopping
	|			THEN 5
	|		ELSE 5
	|	END
	|
	|ORDER BY
	|	TripPurposeType";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qBusiness", Catalogs.TripPurposes.Business);
	vQry.SetParameter("qCommerce", Catalogs.TripPurposes.Commerce);
	vQry.SetParameter("qOfficial", Catalogs.TripPurposes.Official);
	vQry.SetParameter("qWork", Catalogs.TripPurposes.Work);
	vQry.SetParameter("qCrewman", Catalogs.TripPurposes.Crewman);
	vQry.SetParameter("qHumanitarian", Catalogs.TripPurposes.Humanitarian);
	vQry.SetParameter("qTourism", Catalogs.TripPurposes.Tourism);
	vQry.SetParameter("qPrivate", Catalogs.TripPurposes.Private);
	vQry.SetParameter("qScientific", Catalogs.TripPurposes.Scientific);
	vQry.SetParameter("qStudy", Catalogs.TripPurposes.Study);
	vQry.SetParameter("qRecreation", Catalogs.TripPurposes.Recreation);
	vQry.SetParameter("qShopping", Catalogs.TripPurposes.Shopping);
	vQry.SetParameter("qPilgrims", Catalogs.TripPurposes.Pilgrims);
	vQry.SetParameter("qTransit", Catalogs.TripPurposes.Transit);
	vQry.SetParameter("qOther", Catalogs.TripPurposes.Other);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyCountry", Catalogs.Countries.EmptyRef());
	vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vQry.SetParameter("qEmptyCountry", Catalogs.Countries.EmptyRef());
	vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vQryResult = vQry.Execute().Unload();
	
	vPage4Area.Parameters.mGuestsTouristsRus = 0;
	vPage4Area.Parameters.mGuestsEducationRus = 0;
	vPage4Area.Parameters.mGuestsBusinessRus = 0;
	vPage4Area.Parameters.mGuestsCureRus = 0;
	vPage4Area.Parameters.mGuestsPilgrimRus = 0;
	vPage4Area.Parameters.mGuestsOtherRus = 0;

	For Each vRow In vQryResult Do
		If vRow.TripPurposeType = 1 Then
			vPage4Area.Parameters.mGuestsTouristsRus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 2 Then
			vPage4Area.Parameters.mGuestsEducationRus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 6 Then
			vPage4Area.Parameters.mGuestsBusinessRus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 3 Then
			vPage4Area.Parameters.mGuestsCureRus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 4 Then
			vPage4Area.Parameters.mGuestsPilgrimRus = vRow.GuestsCheckedInTurnover;
		Else
			vPage4Area.Parameters.mGuestsOtherRus = vRow.GuestsCheckedInTurnover;
		EndIf;
	EndDo;
	
	// 4.1.4 Get total number of checked-in foreigner guests per trip purposes
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qStudy
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qOther
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTransit
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qRecreation
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qPilgrims
	|			THEN 4
	|		WHEN GeoSales.TripPurpose = &qShopping
	|			THEN 5
	|		ELSE 5
	|	END AS TripPurposeType,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		GeoSalesTurnovers.TripPurpose AS TripPurpose,
	|		SUM(GeoSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND Client.Citizenship <> &qRussia
	|					AND ISNULL(Client.Citizenship.Description, """") <> """") AS GeoSalesTurnovers
	|	
	|	GROUP BY
	|		GeoSalesTurnovers.TripPurpose) AS GeoSales
	|
	|GROUP BY
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qStudy
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qOther
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTransit
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qRecreation
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qPilgrims
	|			THEN 4
	|		WHEN GeoSales.TripPurpose = &qShopping
	|			THEN 5
	|		ELSE 5
	|	END
	|
	|ORDER BY
	|	TripPurposeType";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qBusiness", Catalogs.TripPurposes.Business);
	vQry.SetParameter("qCommerce", Catalogs.TripPurposes.Commerce);
	vQry.SetParameter("qOfficial", Catalogs.TripPurposes.Official);
	vQry.SetParameter("qWork", Catalogs.TripPurposes.Work);
	vQry.SetParameter("qCrewman", Catalogs.TripPurposes.Crewman);
	vQry.SetParameter("qHumanitarian", Catalogs.TripPurposes.Humanitarian);
	vQry.SetParameter("qTourism", Catalogs.TripPurposes.Tourism);
	vQry.SetParameter("qPrivate", Catalogs.TripPurposes.Private);
	vQry.SetParameter("qScientific", Catalogs.TripPurposes.Scientific);
	vQry.SetParameter("qStudy", Catalogs.TripPurposes.Study);
	vQry.SetParameter("qRecreation", Catalogs.TripPurposes.Recreation);
	vQry.SetParameter("qShopping", Catalogs.TripPurposes.Shopping);
	vQry.SetParameter("qPilgrims", Catalogs.TripPurposes.Pilgrims);
	vQry.SetParameter("qTransit", Catalogs.TripPurposes.Transit);
	vQry.SetParameter("qOther", Catalogs.TripPurposes.Other);
	vQry.SetParameter("qCompany", Company);
	vQryResult = vQry.Execute().Unload();
	
	vPage4Area.Parameters.mGuestsTouristsForeigners = 0;
	vPage4Area.Parameters.mGuestsEducationForeigners = 0;
	vPage4Area.Parameters.mGuestsBusinessForeigners = 0;
	vPage4Area.Parameters.mGuestsCureForeigners = 0;
	vPage4Area.Parameters.mGuestsPilgrimForeigners = 0;
	vPage4Area.Parameters.mGuestsOtherForeigners = 0;

	For Each vRow In vQryResult Do
		If vRow.TripPurposeType = 1 Then
			vPage4Area.Parameters.mGuestsTouristsForeigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 2 Then
			vPage4Area.Parameters.mGuestsEducationForeigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 6 Then
			vPage4Area.Parameters.mGuestsBusinessForeigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 3 Then
			vPage4Area.Parameters.mGuestsCureForeigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.TripPurposeType = 4 Then
			vPage4Area.Parameters.mGuestsPilgrimForeigners = vRow.GuestsCheckedInTurnover;
		Else
			vPage4Area.Parameters.mGuestsOtherForeigners = vRow.GuestsCheckedInTurnover;
		EndIf;
	EndDo;
	
	// 4.2.1 Get total number of russian checked-in guests per duration
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 0
	|		WHEN GeoSales.Duration < 5
	|			THEN 4
	|		WHEN GeoSales.Duration < 8
	|			THEN 7
	|		WHEN GeoSales.Duration < 15
	|			THEN 14
	|		WHEN GeoSales.Duration < 29
	|			THEN 28
	|		WHEN GeoSales.Duration < 91
	|			THEN 90
	|		WHEN GeoSales.Duration < 183
	|			THEN 182
	|		ELSE 183
	|	END AS DurationType,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0) AS Duration,
	|		SUM(GeoSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND (Client.Citizenship = &qRussia
	|						OR ISNULL(Client.Citizenship.Description, """") = """")) AS GeoSalesTurnovers
	|	
	|	GROUP BY
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0)) AS GeoSales
	|
	|GROUP BY
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 0
	|		WHEN GeoSales.Duration < 5
	|			THEN 4
	|		WHEN GeoSales.Duration < 8
	|			THEN 7
	|		WHEN GeoSales.Duration < 15
	|			THEN 14
	|		WHEN GeoSales.Duration < 29
	|			THEN 28
	|		WHEN GeoSales.Duration < 91
	|			THEN 90
	|		WHEN GeoSales.Duration < 183
	|			THEN 182
	|		ELSE 183
	|	END
	|
	|ORDER BY
	|	DurationType";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyCountry", Catalogs.Countries.EmptyRef());
	vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vQryResult = vQry.Execute().Unload();
	
	vPage4Area.Parameters.mGuests0Rus = 0;
	vPage4Area.Parameters.mGuests1_4Rus = 0;
	vPage4Area.Parameters.mGuests5_7Rus = 0;
	vPage4Area.Parameters.mGuests8_14Rus = 0;
	vPage4Area.Parameters.mGuests15_28Rus = 0;
	vPage4Area.Parameters.mGuests29_90Rus = 0;
	vPage4Area.Parameters.mGuests91_182Rus = 0;
	vPage4Area.Parameters.mGuests183Rus = 0;

	For Each vRow In vQryResult Do
		If vRow.DurationType = 0 Then
			vPage4Area.Parameters.mGuests0Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 4 Then
			vPage4Area.Parameters.mGuests1_4Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 7 Then
			vPage4Area.Parameters.mGuests5_7Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 14 Then
			vPage4Area.Parameters.mGuests8_14Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 28 Then
			vPage4Area.Parameters.mGuests15_28Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 90 Then
			vPage4Area.Parameters.mGuests29_90Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 182 Then
			vPage4Area.Parameters.mGuests91_182Rus = vRow.GuestsCheckedInTurnover;
		Else
			vPage4Area.Parameters.mGuests183Rus = vRow.GuestsCheckedInTurnover;
		EndIf;
	EndDo;
	
	// 4.2.2 Get total number of foreigner checked-in guests per duration
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 0
	|		WHEN GeoSales.Duration < 5
	|			THEN 4
	|		WHEN GeoSales.Duration < 8
	|			THEN 7
	|		WHEN GeoSales.Duration < 15
	|			THEN 14
	|		WHEN GeoSales.Duration < 29
	|			THEN 28
	|		WHEN GeoSales.Duration < 91
	|			THEN 90
	|		WHEN GeoSales.Duration < 183
	|			THEN 182
	|		ELSE 183
	|	END AS DurationType,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0) AS Duration,
	|		SUM(GeoSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND Client.Citizenship <> &qRussia
	|					AND ISNULL(Client.Citizenship.Description, """") <> """") AS GeoSalesTurnovers
	|	
	|	GROUP BY
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0)) AS GeoSales
	|
	|GROUP BY
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 0
	|		WHEN GeoSales.Duration < 5
	|			THEN 4
	|		WHEN GeoSales.Duration < 8
	|			THEN 7
	|		WHEN GeoSales.Duration < 15
	|			THEN 14
	|		WHEN GeoSales.Duration < 29
	|			THEN 28
	|		WHEN GeoSales.Duration < 91
	|			THEN 90
	|		WHEN GeoSales.Duration < 183
	|			THEN 182
	|		ELSE 183
	|	END
	|
	|ORDER BY
	|	DurationType";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qCompany", Company);
	vQryResult = vQry.Execute().Unload();
	
	vPage4Area.Parameters.mGuests0Foreigners = 0;
	vPage4Area.Parameters.mGuests1_4Foreigners = 0;
	vPage4Area.Parameters.mGuests5_7Foreigners = 0;
	vPage4Area.Parameters.mGuests8_14Foreigners = 0;
	vPage4Area.Parameters.mGuests15_28Foreigners = 0;
	vPage4Area.Parameters.mGuests29_90Foreigners = 0;
	vPage4Area.Parameters.mGuests91_182Foreigners = 0;
	vPage4Area.Parameters.mGuests183Foreigners = 0;

	For Each vRow In vQryResult Do
		If vRow.DurationType = 0 Then
			vPage4Area.Parameters.mGuests0Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 4 Then
			vPage4Area.Parameters.mGuests1_4Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 7 Then
			vPage4Area.Parameters.mGuests5_7Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 14 Then
			vPage4Area.Parameters.mGuests8_14Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 28 Then
			vPage4Area.Parameters.mGuests15_28Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 90 Then
			vPage4Area.Parameters.mGuests29_90Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 182 Then
			vPage4Area.Parameters.mGuests91_182Foreigners = vRow.GuestsCheckedInTurnover;
		Else
			vPage4Area.Parameters.mGuests183Foreigners = vRow.GuestsCheckedInTurnover;
		EndIf;
	EndDo;
	
	// 4.2.3 Get total number of russian checked-in guests per duration in modular buildings
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 0
	|		WHEN GeoSales.Duration < 5
	|			THEN 4
	|		WHEN GeoSales.Duration < 8
	|			THEN 7
	|		WHEN GeoSales.Duration < 15
	|			THEN 14
	|		WHEN GeoSales.Duration < 29
	|			THEN 28
	|		WHEN GeoSales.Duration < 91
	|			THEN 90
	|		WHEN GeoSales.Duration < 183
	|			THEN 182
	|		ELSE 183
	|	END AS DurationType,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0) AS Duration,
	|		SUM(GeoSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection
	|					AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND (Client.Citizenship = &qRussia
	|						OR ISNULL(Client.Citizenship.Description, """") = """")
	|					AND ISNULL(RoomType.IsModularStructure, FALSE)) AS GeoSalesTurnovers
	|	
	|	GROUP BY
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0)) AS GeoSales
	|
	|GROUP BY
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 0
	|		WHEN GeoSales.Duration < 5
	|			THEN 4
	|		WHEN GeoSales.Duration < 8
	|			THEN 7
	|		WHEN GeoSales.Duration < 15
	|			THEN 14
	|		WHEN GeoSales.Duration < 29
	|			THEN 28
	|		WHEN GeoSales.Duration < 91
	|			THEN 90
	|		WHEN GeoSales.Duration < 183
	|			THEN 182
	|		ELSE 183
	|	END
	|
	|ORDER BY
	|	DurationType";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyCountry", Catalogs.Countries.EmptyRef());
	vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vQryResult = vQry.Execute().Unload();
	
	vPage4Area.Parameters.mModularGuests0Rus = 0;
	vPage4Area.Parameters.mModularGuests1_4Rus = 0;
	vPage4Area.Parameters.mModularGuests5_7Rus = 0;
	vPage4Area.Parameters.mModularGuests8_14Rus = 0;
	vPage4Area.Parameters.mModularGuests15_28Rus = 0;
	vPage4Area.Parameters.mModularGuests29_90Rus = 0;
	vPage4Area.Parameters.mModularGuests91_182Rus = 0;
	vPage4Area.Parameters.mModularGuests183Rus = 0;

	For Each vRow In vQryResult Do
		If vRow.DurationType = 0 Then
			vPage4Area.Parameters.mModularGuests0Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 4 Then
			vPage4Area.Parameters.mModularGuests1_4Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 7 Then
			vPage4Area.Parameters.mModularGuests5_7Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 14 Then
			vPage4Area.Parameters.mModularGuests8_14Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 28 Then
			vPage4Area.Parameters.mModularGuests15_28Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 90 Then
			vPage4Area.Parameters.mModularGuests29_90Rus = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 182 Then
			vPage4Area.Parameters.mModularGuests91_182Rus = vRow.GuestsCheckedInTurnover;
		Else
			vPage4Area.Parameters.mModularGuests183Rus = vRow.GuestsCheckedInTurnover;
		EndIf;
	EndDo;
	
	// 4.2.2 Get total number of foreigner checked-in guests per duration
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 0
	|		WHEN GeoSales.Duration < 5
	|			THEN 4
	|		WHEN GeoSales.Duration < 8
	|			THEN 7
	|		WHEN GeoSales.Duration < 15
	|			THEN 14
	|		WHEN GeoSales.Duration < 29
	|			THEN 28
	|		WHEN GeoSales.Duration < 91
	|			THEN 90
	|		WHEN GeoSales.Duration < 183
	|			THEN 182
	|		ELSE 183
	|	END AS DurationType,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0) AS Duration,
	|		SUM(GeoSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection
	|					AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND Client.Citizenship <> &qRussia
	|					AND ISNULL(Client.Citizenship.Description, """") <> """"
	|					AND ISNULL(RoomType.IsModularStructure, FALSE)) AS GeoSalesTurnovers
	|	
	|	GROUP BY
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0)) AS GeoSales
	|
	|GROUP BY
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 0
	|		WHEN GeoSales.Duration < 5
	|			THEN 4
	|		WHEN GeoSales.Duration < 8
	|			THEN 7
	|		WHEN GeoSales.Duration < 15
	|			THEN 14
	|		WHEN GeoSales.Duration < 29
	|			THEN 28
	|		WHEN GeoSales.Duration < 91
	|			THEN 90
	|		WHEN GeoSales.Duration < 183
	|			THEN 182
	|		ELSE 183
	|	END
	|
	|ORDER BY
	|	DurationType";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qCompany", Company);
	vQryResult = vQry.Execute().Unload();
	
	vPage4Area.Parameters.mModularGuests0Foreigners = 0;
	vPage4Area.Parameters.mModularGuests1_4Foreigners = 0;
	vPage4Area.Parameters.mModularGuests5_7Foreigners = 0;
	vPage4Area.Parameters.mModularGuests8_14Foreigners = 0;
	vPage4Area.Parameters.mModularGuests15_28Foreigners = 0;
	vPage4Area.Parameters.mModularGuests29_90Foreigners = 0;
	vPage4Area.Parameters.mModularGuests91_182Foreigners = 0;
	vPage4Area.Parameters.mModularGuests183Foreigners = 0;

	For Each vRow In vQryResult Do
		If vRow.DurationType = 0 Then
			vPage4Area.Parameters.mModularGuests0Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 4 Then
			vPage4Area.Parameters.mModularGuests1_4Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 7 Then
			vPage4Area.Parameters.mModularGuests5_7Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 14 Then
			vPage4Area.Parameters.mModularGuests8_14Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 28 Then
			vPage4Area.Parameters.mModularGuests15_28Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 90 Then
			vPage4Area.Parameters.mModularGuests29_90Foreigners = vRow.GuestsCheckedInTurnover;
		ElsIf vRow.DurationType = 182 Then
			vPage4Area.Parameters.mModularGuests91_182Foreigners = vRow.GuestsCheckedInTurnover;
		Else
			vPage4Area.Parameters.mModularGuests183Foreigners = vRow.GuestsCheckedInTurnover;
		EndIf;
	EndDo;
	
	pSpreadsheet.Put(vPage4Area);
	pSpreadsheet.PutHorizontalPageBreak();
	
	FillPropertyValues(ReportParameters, vPage4Area.Parameters);
	
	// Page 5
	
	// 7.1 Get total sales
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomSalesTurnovers.RoomRevenueWithoutVATTurnover,
	|	RoomSalesTurnovers.SalesWithoutVATTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			NOT IsCorrection AND Hotel = &qHotel
	|				AND Company = &qCompany
	|				AND (Service IN HIERARCHY (&qIncomeServices)
	|					OR (NOT &qUseServicesList))) AS RoomSalesTurnovers";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vUseServicesList = False;
	vServicesList = New ValueList();
	If ValueIsFilled(TotalIncomeServiceGroup) Then
		If Not TotalIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(TotalIncomeServiceGroup);
		EndIf;
	EndIf;
	vQry.SetParameter("qUseServicesList", vUseServicesList);
	vQry.SetParameter("qIncomeServices", vServicesList);
	vQryResult = vQry.Execute().Unload();

	vTotalIncome = 0;
	vTotalRoomRevenueIncome = 0;
	vPage5Area.Parameters.mTotalIncome = 0;
	vPage5Area.Parameters.mTotalRoomRevenueIncome = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vTotalIncome = Round(vRow.SalesWithoutVATTurnover/1000, 1);
		vPage5Area.Parameters.mTotalIncome = vTotalIncome;
		vTotalRoomRevenueIncome = Round(vRow.RoomRevenueWithoutVATTurnover/1000, 1);
		vPage5Area.Parameters.mTotalRoomRevenueIncome = vTotalRoomRevenueIncome;
	EndIf;
	
	// 7.2 Get total meals sales
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomSalesTurnovers.SalesWithoutVATTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			NOT IsCorrection AND Hotel = &qHotel
	|				AND Company = &qCompany
	|				AND (Service IN HIERARCHY (&qIncomeServices)
	|					OR (NOT &qUseServicesList))) AS RoomSalesTurnovers";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vUseServicesList = False;
	vServicesList = New ValueList();
	If ValueIsFilled(MealIncomeServiceGroup) Then
		If Not MealIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(MealIncomeServiceGroup);
		EndIf;
	EndIf;
	vQry.SetParameter("qUseServicesList", vUseServicesList);
	vQry.SetParameter("qIncomeServices", vServicesList);
	vQryResult = vQry.Execute().Unload();
	
	vTotalMealsIncome = 0;
	vPage5Area.Parameters.mTotalMealsIncome = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vTotalMealsIncome = Round(vRow.SalesWithoutVATTurnover/1000, 1);
		If vTotalMealsIncome > (vTotalIncome - vTotalRoomRevenueIncome) Then
			vTotalMealsIncome = vTotalIncome - vTotalRoomRevenueIncome;
		EndIf;
		vPage5Area.Parameters.mTotalMealsIncome = vTotalMealsIncome;
	EndIf;
	
	vTotalOtherIncome = vTotalIncome - (vTotalRoomRevenueIncome + vTotalMealsIncome);
	If vTotalOtherIncome < 0 Then
		vTotalOtherIncome = 0;
	EndIf;
	vPage5Area.Parameters.mTotalOtherIncome = vTotalOtherIncome;
	
	pSpreadsheet.Put(vPage5Area);
	pSpreadsheet.PutHorizontalPageBreak();
	
	FillPropertyValues(ReportParameters, vPage5Area.Parameters);
EndProcedure // pmGenerate2024

// -----------------------------------------------------------------------------
Function GetReportParametersNames()
	Return 
	"m101,
	|m102,
	|m103,
	|m104,
	|m105,
	|m106,
	|m107,
	|m108,
	|m109,
	|m110,
	|m111,
	|m112,
	|m113,
	|m114,
	|m115,
	|m116,
	|m117,
	|m118,
	|m119,
	|m120,
	|m121,
	|m122,
	|m123,
	|m131,
	|m132,
	|m133,
	|m134,
	|m135,
	|m136,
	|m1Star,
	|m2Star,
	|m3Star,
	|m4Star,
	|m5Star,
	|mCompanyName,
	|mCompanyOKPOCode,
	|mCompanyPostAddress,
	|mCountry,
	|mCountryCode,
	|mCountryGuestDays,
	|mCountryGuests,
	|mGuests0Foreigners,
	|mGuests0Rus,
	|mGuests15_28Foreigners,
	|mGuests15_28Rus,
	|mGuests183Foreigners,
	|mGuests183Rus,
	|mGuests1_4Foreigners,
	|mGuests1_4Rus,
	|mGuests29_90Foreigners,
	|mGuests29_90Rus,
	|mGuests5_7Foreigners,
	|mGuests5_7Rus,
	|mGuests8_14Foreigners,
	|mGuests8_14Rus,
	|mGuests91_182Foreigners,
	|mGuests91_182Rus,
	|mGuestsBusinessForeigners,
	|mGuestsBusinessRus,
	|mGuestsCureForeigners,
	|mGuestsCureRus,
	|mGuestsEducationForeigners,
	|mGuestsEducationRus,
	|mGuestsOtherForeigners,
	|mGuestsOtherRus,
	|mGuestsPilgrimForeigners,
	|mGuestsPilgrimRus,
	|mGuestsTouristsForeigners,
	|mGuestsTouristsRus,
	|mHotelName,
	|mHotelPostAddress,
	|mModularGuests0Foreigners,
	|mModularGuests0Rus,
	|mModularGuests15_28Foreigners,
	|mModularGuests15_28Rus,
	|mModularGuests183Foreigners,
	|mModularGuests183Rus,
	|mModularGuests1_4Foreigners,
	|mModularGuests1_4Rus,
	|mModularGuests29_90Foreigners,
	|mModularGuests29_90Rus,
	|mModularGuests5_7Foreigners,
	|mModularGuests5_7Rus,
	|mModularGuests8_14Foreigners,
	|mModularGuests8_14Rus,
	|mModularGuests91_182Foreigners,
	|mModularGuests91_182Rus,
	|mModularWorkingDays,
	|mNewModularRooms,
	|mNewRooms,
	|mNoStar,
	|mNotClassified,
	|mPeriodStr,
	|mTotalAdoptedForDisabledRooms,
	|mTotalBeds,
	|mTotalDisabledGuests,
	|mTotalDisabledGuests18,
	|mTotalDisabledGuests1855,
	|mTotalDisabledGuests55,
	|mTotalGuestDays,
	|mTotalGuestDays18,
	|mTotalGuestDays1855,
	|mTotalGuestDays55,
	|mTotalGuestDaysForeigners,
	|mTotalGuestDaysForeigners18,
	|mTotalGuestDaysForeigners1855,
	|mTotalGuestDaysForeigners55,
	|mTotalGuestDaysRus,
	|mTotalGuestDaysRus18,
	|mTotalGuestDaysRus1855,
	|mTotalGuestDaysRus55,
	|mTotalGuests,
	|mTotalGuests18,
	|mTotalGuests1855,
	|mTotalGuests55,
	|mTotalGuestsForeigners,
	|mTotalGuestsForeigners18,
	|mTotalGuestsForeigners1855,
	|mTotalGuestsForeigners55,
	|mTotalGuestsRus,
	|mTotalGuestsRus18,
	|mTotalGuestsRus1855,
	|mTotalGuestsRus55,
	|mTotalIncome,
	|mTotalLivingArea,
	|mTotalMealsIncome,
	|mTotalModularAdoptedForDisabledRooms,
	|mTotalModularBeds,
	|mTotalModularGuestDays,
	|mTotalModularGuestDays18,
	|mTotalModularGuestDays1855,
	|mTotalModularGuestDays55,
	|mTotalModularGuestDaysForeigners,
	|mTotalModularGuestDaysForeigners18,
	|mTotalModularGuestDaysForeigners1855,
	|mTotalModularGuestDaysForeigners55,
	|mTotalModularGuestDaysRus,
	|mTotalModularGuestDaysRus18,
	|mTotalModularGuestDaysRus1855,
	|mTotalModularGuestDaysRus55,
	|mTotalModularGuests,
	|mTotalModularGuests18,
	|mTotalModularGuests1855,
	|mTotalModularGuests55,
	|mTotalModularGuestsForeigners,
	|mTotalModularGuestsForeigners18,
	|mTotalModularGuestsForeigners1855,
	|mTotalModularGuestsForeigners55,
	|mTotalModularGuestsRus,
	|mTotalModularGuestsRus18,
	|mTotalModularGuestsRus1855,
	|mTotalModularGuestsRus55,
	|mTotalModularLivingArea,
	|mTotalModularRooms,
	|mTotalModularTopRooms,
	|mTotalOtherIncome,
	|mTotalRoomRevenueIncome,
	|mTotalRooms,
	|mTotalTopRooms,
	|mTotalTourTicketGuests,
	|mTotalTourTicketGuests18,
	|mTotalTourTicketGuests1855,
	|mTotalTourTicketGuests55,
	|mTotalTourTicketGuestsForeigners,
	|mTotalTourTicketGuestsForeigners18,
	|mTotalTourTicketGuestsForeigners1855,
	|mTotalTourTicketGuestsForeigners55,
	|mTotalTourTicketGuestsRus,
	|mTotalTourTicketGuestsRus18,
	|mTotalTourTicketGuestsRus1855,
	|mTotalTourTicketGuestsRus55,
	|mVaucher1855Quantity,
	|mVaucher18Quantity,
	|mVaucher55Quantity,
	|mVaucherQuantity,
	|mWorkingDays,
	|m605,
	|m606,
	|m607,
	|m608,
	|m701,
	|m702,
	|m703"
EndFunction // GetReportParametersNames()

// -----------------------------------------------------------------------------
Function KSRType()
	Result = "Err";	
	For N = 101 To 117 Do
		If ReportParameters["m" + String(N)] = "1" Then
			Result = String(N);
			Break;
		EndIf;
	EndDo;
	Return Result;
EndFunction

// -----------------------------------------------------------------------------
Function TaxSystem()
	Result = "Err";	
	For N = 118 To 121 Do
		If ReportParameters["m" + String(N)] = "1" Then
			Result = String(N);
			Break;
		EndIf;
	EndDo;
	Return Result;
EndFunction

// -----------------------------------------------------------------------------
Function PeriodOfOperation()
	Result = "Err";	
	For N = 122 To 123 Do
		If ReportParameters["m" + String(N)] = "1" Then
			Result = String(N);
			Break;
		EndIf;
	EndDo;
	Return Result;
EndFunction

// -----------------------------------------------------------------------------
Function KSRCategories()
	Result = "Err";	
	For N = 124 To 128 Do
		If ReportParameters["m" + String(N-123) + "Star"] = "1" Then
			Result = String(N);
			Break;
		EndIf;
	EndDo;
	If Result = "Err" Then
		If ReportParameters.mNoStar = "1" Then
			Result = "129";
		ElsIf ReportParameters.mNotClassified = "1" Then
			Result = "130";
		EndIf;
	
	EndIf;
	Return Result;
EndFunction

// -----------------------------------------------------------------------------
Function KSRBuildingTypes()
	Result = "Err";	
	For N = 134 To 136 Do
		If ReportParameters["m" + String(N)] = "1" Then
			Result = String(N);
			Break;
		EndIf;
	EndDo;
	Return Result;
EndFunction

// -----------------------------------------------------------------------------
// Unload report data to XML-file
// -----------------------------------------------------------------------------
Procedure pmUnloadToXML(pParameter = Undefined, pIsInteractive = False, pAddressStorage = "", pFormUUID ) Export
	vPath = cmGetFullFileName("KSR", TempFilesDir());
	DeleteFiles(vPath);
	CreateDirectory(vPath);
	
	Try
		vFullFilePath = vPath + "\" + "KSRAnnual" + ".xml";
		vSections = AnnualReportSections();
		vReportDetails = AnnualReportDetails();
		pAddressStorage = WriteReportXML(vFullFilePath, pFormUUID, vSections, vReportDetails);
	Except
		vMessage = BriefErrorDescription(ErrorInfo());
		tcCommonFunctionOnClientServer.UserMessage(vMessage);	
	EndTry;
EndProcedure // pmUnloadToXML

#Region Private

// -----------------------------------------------------------------------------
//
// Parameters:
//  pFullFilePath	 - String	 - Full file path
//  pUUID			 - UUID		 - Form UUID
//  pSections		 - Array	 - Sections of unloading file
//  pReportDetails	 - Structure:
//  						* code - The code of the OKUD form
//  						* form - Form ID
//  						* shifr - Shifr
//  						* year - Year of the reporting period
//  						* period - Number of the report period
//  						* version - Version (from SBIS site)
// 
// Returns:
//  String - Temp storage address
//
Function WriteReportXML(pFullFilePath, pUUID, pSections, pReportDetails)
	vXMLWriter = New XMLWriter;
	vFileName = pFullFilePath;
	vXMLWriter.OpenFile(vFileName, "UTF-8");
	vXMLWriter.WriteXMLDeclaration();
	
	vXMLWriter.WriteStartElement("report");

		For Each vAttr In pReportDetails Do
			vXMLWriter.WriteAttribute(vAttr.Key, vAttr.Value);
		EndDo;
		
		vXMLWriter.WriteStartElement("title");
			vTitle = ReportTitle();
			For Each vAttr In vTitle Do
				vXMLWriter.WriteStartElement("item");
					vXMLWriter.WriteAttribute("name", vAttr.Key);
					vXMLWriter.WriteAttribute("value", vAttr.Value);
				vXMLWriter.WriteEndElement();
			EndDo;
		vXMLWriter.WriteEndElement();
		
		vXMLWriter.WriteStartElement("sections");
			vIter = 1;
			For Each vSection In pSections Do
				vXMLWriter.WriteStartElement("section");
					vXMLWriter.WriteAttribute("code", String(vIter));
					For Each vRow In vSection Do
						vXMLWriter.WriteStartElement("row");
							vXMLWriter.WriteAttribute("code", vRow.code);
							If vSection.Columns.Find("s1") <> Undefined Then
								vXMLWriter.WriteAttribute("s1", vRow.s1);	
							EndIf;
							For Each vColumn In vSection.Columns Do
								vColumnName = vColumn.Name;
								If vColumnName <> "code" And vColumnName <> "s1" Then
									If ValueIsFilled(vRow[vColumnName]) Then
										vXMLWriter.WriteStartElement("col");
											vXMLWriter.WriteAttribute("code", StrReplace(vColumnName, "_", ""));
											vXMLWriter.WriteText(Format(vRow[vColumnName], "NFD=0; NGS=; NG="));
										vXMLWriter.WriteEndElement();
									EndIf;
								EndIf;
							EndDo;
						vXMLWriter.WriteEndElement();
					EndDo;
				vXMLWriter.WriteEndElement();
				vIter = vIter + 1;
			EndDo;
		vXMLWriter.WriteEndElement();
		
	vXMLWriter.WriteEndElement();
	
	vXMLWriter.Close();
    
    Return PutToTempStorage(New BinaryData(vFileName), pUUID);
EndFunction // WriteInvoiceCase

// -----------------------------------------------------------------------------
// 
// Returns:
//  Structure:
//  	* okpo - Company OKPO
//  	* name - Company name
//  	* leader_fio - Company director full name
//  	* post - Company post address
//  	* responsible_post - Hotel director position
//  	* responsible_fio - Hotel director full name
//  	* phone - Hotel phone
//  	* email - Hotel email
//  	* nameksr - Hotel legacy name
//  	* postksr - Hotel post address
//
Function ReportTitle()
	
	vTitle = New Structure();
	vMsg = New Array;
	
	If ValueIsFilled(Company.OKPO) Then
		vTitle.Insert("okpo", TrimAll(Company.OKPO));
	Else
		vMsg.Add(NStr("en = 'The OKPO is not filled in the company settings!';
					  |de = 'The OKPO is not filled in the company settings!';
					  |ru = 'В настройках фирмы не заполнен ОКПО!'"));
	EndIf;
	If ValueIsFilled(Company.LegacyName) Then
		vTitle.Insert("name", TrimAll(Company.LegacyName));
	Else
		vMsg.Add(NStr("en = 'The legacy name is not filled in the company settings!';
				      |de = 'The legacy name is not filled in the company settings!';
				      |ru = 'В настройках фирмы не заполнено официальное наименование!'"));
	EndIf;	
	If ValueIsFilled(Company.Director) Then
		vTitle.Insert("leader_fio", TrimAll(NStr(Company.Director)));
		If Not ValueIsFilled(vTitle.leader_fio) Then
			vTitle.leader_fio = TrimAll(Company.Director);
		EndIf;
	Else
		vMsg.Add(NStr("en = 'The director`s full name is not filled in the company settings!';
				      |de = 'The director`s full name OKPO is not filled in the company settings!';
				      |ru = 'В настройках фирмы не заполнено ФИО руководителя!'"));
	EndIf;	
	If ValueIsFilled(Company.PostAddress) Then
		vTitle.Insert("post", cmGetAddressPresentation(Company.PostAddress));
	Else
		vMsg.Add(NStr("en = 'The address is not filled in the company settings!';
				      |de = 'The address is not filled in the company settings!';
				      |ru = 'В настройках фирмы не заполнен адрес!'"));
	EndIf;	
	If ValueIsFilled(Hotel.DirectorPosition) Then
		vTitle.Insert("responsible_post", TrimAll(NStr(Hotel.DirectorPosition)));
		If Not ValueIsFilled(vTitle.responsible_post) Then
			vTitle.responsible_post = TrimAll(Hotel.DirectorPosition);
		EndIf;
	Else
		vMsg.Add(NStr("en = 'The director`s post is not filled in the hotel settings!';
				      |de = 'The director`s post is not filled in the hotel settings!';
				      |ru = 'В настройках гостиницы не заполнена должность руководителя!'"));
	EndIf;	
	If ValueIsFilled(Hotel.Director) Then
		vTitle.Insert("responsible_fio", TrimAll(NStr(Hotel.Director)));
		If Not ValueIsFilled(vTitle.responsible_fio) Then
			vTitle.responsible_fio = TrimAll(Hotel.Director);
		EndIf;
	Else
		vMsg.Add(NStr("en = 'The director`s full name is not filled in the hotel settings!';
				      |de = 'The director`s full name is not filled in the hotel settings!';
				      |ru = 'В настройках гостиницы не заполнено ФИО руководителя!'"));
	EndIf;	
	If ValueIsFilled(Hotel.Phones) Then
		vTitle.Insert("phone", TrimAll(Hotel.Phones));
	Else
		vMsg.Add(NStr("en = 'The phone is not filled in the hotel settings!';
				      |de = 'The phone is not filled in the hotel settings!';
				      |ru = 'В настройках гостиницы не заполнен телефон!'"));
	EndIf;	
	If ValueIsFilled(Hotel.Email) Then
		vTitle.Insert("email", TrimAll(Hotel.Email));
	Else
		vMsg.Add(NStr("en = 'The email is not filled in the hotel settings!';
				      |de = 'The email is not filled in the hotel settings!';
				      |ru = 'В настройках гостиницы не заполнен email!'"));
	EndIf;	
	If ValueIsFilled(Hotel.LegacyName) Then
		vTitle.Insert("nameksr", TrimAll(Hotel.LegacyName));
	Else
		vMsg.Add(NStr("en = 'The legacy name is not filled in the hotel settings!';
				      |de = 'The legacy name is not filled in the hotel settings!';
				      |ru = 'В настройках гостиницы не заполнено официальное наименование!'"));
	EndIf;	
	If ValueIsFilled(Hotel.PostAddress) Then
		vTitle.Insert("postksr", cmGetAddressPresentation(Hotel.PostAddress));
	Else
		vMsg.Add(NStr("en = 'The address is not filled in the hotel settings!';
				      |de = 'The address is not filled in the hotel settings!';
				      |ru = 'В настройках гостиницы не заполнен адрес!'"));
	EndIf;
	
	If vMsg.Count() > 0 Then
		Raise StrConcat(vMsg, Chars.LF);	
	EndIf;
	
	Return vTitle;
	
EndFunction // ReportTitleStructure

// -----------------------------------------------------------------------------
Function AnnualReportSections() Export
	
	vSections = New Array;
	
	// Table 1
	vSection0 = New ValueTable;
	vSection0.Columns.Add("code");
	vSection0.Columns.Add("_1");
	
	vNewRow = vSection0.Add();
	vNewRow.code = KSRType();
	vNewRow._1 = "1";
	
	vNewRow = vSection0.Add();
	vNewRow.code = TaxSystem();
	vNewRow._1 = "1";
	
	vNewRow = vSection0.Add();
	vNewRow.code = PeriodOfOperation();
	vNewRow._1 = "1";
	
	vNewRow = vSection0.Add();
	vNewRow.code = KSRCategories();
	vNewRow._1 = "1";
	
	vNewRow = vSection0.Add();
	vNewRow.code = KSRBuildingTypes();
	vNewRow._1 = "1";
	
	vSections.Add(vSection0);
	
	// Table 2
	vSection1 = New ValueTable;
	vSection1.Columns.Add("code");
	vSection1.Columns.Add("_1");
	vSection1.Columns.Add("_2");
	
	vNewRow = vSection1.Add();
	vNewRow.code = "201";
	vNewRow._1 = ReportParameters.mTotalRooms;
	vNewRow._2 = ReportParameters.mTotalModularRooms;
	
	vNewRow = vSection1.Add();
	vNewRow.code = "202";
	vNewRow._1 = ReportParameters.mTotalTopRooms;
	vNewRow._2 = ReportParameters.mTotalModularTopRooms;
	
	vNewRow = vSection1.Add();
	vNewRow.code = "203";
	vNewRow._1 = ReportParameters.mTotalAdoptedForDisabledRooms;
	vNewRow._2 = ReportParameters.mTotalModularAdoptedForDisabledRooms;
	
	vNewRow = vSection1.Add();
	vNewRow.code = "204";
	vNewRow._1 = ReportParameters.mNewRooms;
	vNewRow._2 = ReportParameters.mNewModularRooms;
	
	vNewRow = vSection1.Add();
	vNewRow.code = "205";
	vNewRow._1 = ReportParameters.mTotalLivingArea;
	vNewRow._2 = ReportParameters.mTotalModularLivingArea;
	
	vNewRow = vSection1.Add();
	vNewRow.code = "206";
	vNewRow._1 = ReportParameters.mTotalBeds;
	vNewRow._2 = ReportParameters.mTotalModularBeds;
	
	vNewRow = vSection1.Add();
	vNewRow.code = "207";
	vNewRow._1 = ReportParameters.mWorkingDays;
	vNewRow._2 = ReportParameters.mModularWorkingDays;
	
	vSections.Add(vSection1);
	
	// Table 3
	vSection2 = New ValueTable;
	vSection2.Columns.Add("code");
	vSection2.Columns.Add("_1");
	vSection2.Columns.Add("_2");
	vSection2.Columns.Add("_3");
	vSection2.Columns.Add("_4");

	vNewRow = vSection2.Add();
	vNewRow.code = "301";
	vNewRow._1 = ReportParameters.mTotalGuestDays;
	vNewRow._2 = ReportParameters.mTotalGuestDays18;
	vNewRow._3 = ReportParameters.mTotalGuestDays1855;
	vNewRow._4 = ReportParameters.mTotalGuestDays55;
	
	vNewRow = vSection2.Add();
	vNewRow.code = "302";
	vNewRow._1 = ReportParameters.mTotalGuestDaysRus;
	vNewRow._2 = ReportParameters.mTotalGuestDaysRus18;
	vNewRow._3 = ReportParameters.mTotalGuestDaysRus1855;
	vNewRow._4 = ReportParameters.mTotalGuestDaysRus55;
	
	vNewRow = vSection2.Add();
	vNewRow.code = "303";
	vNewRow._1 = ReportParameters.mTotalGuestDaysForeigners;
	vNewRow._2 = ReportParameters.mTotalGuestDaysForeigners18;
	vNewRow._3 = ReportParameters.mTotalGuestDaysForeigners1855;
	vNewRow._4 = ReportParameters.mTotalGuestDaysForeigners55;
	
	vNewRow = vSection2.Add();
	vNewRow.code = "304";
	vNewRow._1 = ReportParameters.mTotalGuests;
	vNewRow._2 = ReportParameters.mTotalGuests18;
	vNewRow._3 = ReportParameters.mTotalGuests1855;
	vNewRow._4 = ReportParameters.mTotalGuests55;
	
	vNewRow = vSection2.Add();
	vNewRow.code = "305";
	vNewRow._1 = ReportParameters.mTotalGuestsRus;
	vNewRow._2 = ReportParameters.mTotalGuestsRus18;
	vNewRow._3 = ReportParameters.mTotalGuestsRus1855;
	vNewRow._4 = ReportParameters.mTotalGuestsRus55;
	
	vNewRow = vSection2.Add();
	vNewRow.code = "306";
	vNewRow._1 = ReportParameters.mTotalGuestsForeigners;
	vNewRow._2 = ReportParameters.mTotalGuestsForeigners18;
	vNewRow._3 = ReportParameters.mTotalGuestsForeigners1855;
	vNewRow._4 = ReportParameters.mTotalGuestsForeigners55;
	
	vNewRow = vSection2.Add();
	vNewRow.code = "307";
	vNewRow._1 = ReportParameters.mTotalTourTicketGuests;
	vNewRow._2 = ReportParameters.mTotalTourTicketGuests18;
	vNewRow._3 = ReportParameters.mTotalTourTicketGuests1855;
	vNewRow._4 = ReportParameters.mTotalTourTicketGuests55;
	
	vNewRow = vSection2.Add();
	vNewRow.code = "308";
	vNewRow._1 = ReportParameters.mTotalTourTicketGuestsRus;
	vNewRow._2 = ReportParameters.mTotalTourTicketGuestsRus18;
	vNewRow._3 = ReportParameters.mTotalTourTicketGuestsRus1855;
	vNewRow._4 = ReportParameters.mTotalTourTicketGuestsRus55;
	
	vNewRow = vSection2.Add();
	vNewRow.code = "309";
	vNewRow._1 = ReportParameters.mTotalTourTicketGuestsForeigners;
	vNewRow._2 = ReportParameters.mTotalTourTicketGuestsForeigners18;
	vNewRow._3 = ReportParameters.mTotalTourTicketGuestsForeigners1855;
	vNewRow._4 = ReportParameters.mTotalTourTicketGuestsForeigners55;
	
	vNewRow = vSection2.Add();
	vNewRow.code = "310";

	vNewRow._1 = ReportParameters.mTotalDisabledGuests;
	vNewRow._2 = ReportParameters.mTotalDisabledGuests18;
	vNewRow._3 = ReportParameters.mTotalDisabledGuests1855;
	vNewRow._4 = ReportParameters.mTotalDisabledGuests55;
	
	vNewRow = vSection2.Add();
	vNewRow.code = "311";
	vNewRow._1 = ReportParameters.mTotalModularGuestDays;
	vNewRow._2 = ReportParameters.mTotalModularGuestDays18;
	vNewRow._3 = ReportParameters.mTotalModularGuestDays1855;
	vNewRow._4 = ReportParameters.mTotalModularGuestDays55;
	
	vNewRow = vSection2.Add();
	vNewRow.code = "312";
	vNewRow._1 = ReportParameters.mTotalModularGuestDaysRus;
	vNewRow._2 = ReportParameters.mTotalModularGuestDaysRus18;
	vNewRow._3 = ReportParameters.mTotalModularGuestDaysRus1855;
	vNewRow._4 = ReportParameters.mTotalModularGuestDaysRus55;
	
	vNewRow = vSection2.Add();
	vNewRow.code = "313";
	vNewRow._1 = ReportParameters.mTotalModularGuestDaysForeigners;
	vNewRow._2 = ReportParameters.mTotalModularGuestDaysForeigners18;
	vNewRow._3 = ReportParameters.mTotalModularGuestDaysForeigners1855;
	vNewRow._4 = ReportParameters.mTotalModularGuestDaysForeigners55;
						
	vNewRow = vSection2.Add();
	vNewRow.code = "314";
	vNewRow._1 = ReportParameters.mTotalModularGuests;
	vNewRow._2 = ReportParameters.mTotalModularGuests18;
	vNewRow._3 = ReportParameters.mTotalModularGuests1855;
	vNewRow._4 = ReportParameters.mTotalModularGuests55;
	
	vNewRow = vSection2.Add();
	vNewRow.code = "315";
	vNewRow._1 = ReportParameters.mTotalModularGuestsRus;
	vNewRow._2 = ReportParameters.mTotalModularGuestsRus18;
	vNewRow._3 = ReportParameters.mTotalModularGuestsRus1855;
	vNewRow._4 = ReportParameters.mTotalModularGuestsRus55;
	
	vNewRow = vSection2.Add();
	vNewRow.code = "316";
	vNewRow._1 = ReportParameters.mTotalModularGuestsForeigners;
	vNewRow._2 = ReportParameters.mTotalModularGuestsForeigners18;
	vNewRow._3 = ReportParameters.mTotalModularGuestsForeigners1855;
	vNewRow._4 = ReportParameters.mTotalModularGuestsForeigners55;

	vSections.Add(vSection2);
	
	// Table 4
	vSection3 = New ValueTable;
	vSection3.Columns.Add("code");
	vSection3.Columns.Add("s1");
	vSection3.Columns.Add("_1");
	vSection3.Columns.Add("_2");

	For Each vRow In ReportParameters.mCountry.RowsArray Do
		vNewRow = vSection3.Add();
		vNewRow.code = "317";
		vNewRow.s1 = vRow.mCountry;
		vNewRow._1 = vRow.mCountryCode;
		vNewRow._2 = vRow.mCountryGuests;
	EndDo;
	
	vSections.Add(vSection3);
	
	// Table 5
	vSection4 = New ValueTable;
	vSection4.Columns.Add("code");
	vSection4.Columns.Add("_1");

	vNewRow = vSection4.Add();
	vNewRow.code = "318";
	vNewRow._1 = ReportParameters.mVaucherQuantity;
	
	vNewRow = vSection4.Add();
	vNewRow.code = "319";
	vNewRow._1 = ReportParameters.mVaucher18Quantity;
	
	vNewRow = vSection4.Add();
	vNewRow.code = "320";
	vNewRow._1 = ReportParameters.mVaucher1855Quantity;
	
	vNewRow = vSection4.Add();
	vNewRow.code = "321";
	vNewRow._1 = ReportParameters.mVaucher55Quantity;
	
	vSections.Add(vSection4);
	
	// Table 6
	vSection5 = New ValueTable;
	vSection5.Columns.Add("code");
	vSection5.Columns.Add("_1");
	vSection5.Columns.Add("_2");
	vSection5.Columns.Add("_3");
	vSection5.Columns.Add("_4");
	vSection5.Columns.Add("_5");
	vSection5.Columns.Add("_6");
	
	// 4.1.1 Get total number of russian checked-in guests per trip purposes

	vNewRow = vSection5.Add();
	vNewRow.code = "401";
	vNewRow._1 = ReportParameters.mGuestsTouristsRus;
	vNewRow._2 = ReportParameters.mGuestsEducationRus;
	vNewRow._3 = ReportParameters.mGuestsCureRus;
	vNewRow._4 = ReportParameters.mGuestsPilgrimRus;
	vNewRow._5 = ReportParameters.mGuestsOtherRus;
	vNewRow._6 = ReportParameters.mGuestsBusinessRus;
	
	vNewRow = vSection5.Add();
	vNewRow.code = "402";
	vNewRow._1 = ReportParameters.mGuestsTouristsForeigners;
	vNewRow._2 = ReportParameters.mGuestsEducationForeigners;
	vNewRow._3 = ReportParameters.mGuestsCureForeigners;
	vNewRow._4 = ReportParameters.mGuestsPilgrimForeigners;
	vNewRow._5 = ReportParameters.mGuestsOtherForeigners;
	vNewRow._6 = ReportParameters.mGuestsBusinessForeigners;
	
	vSections.Add(vSection5);
	
	// Table 7
	vSection6 = New ValueTable;
	vSection6.Columns.Add("code");
	vSection6.Columns.Add("_1");
	vSection6.Columns.Add("_2");
	vSection6.Columns.Add("_3");
	vSection6.Columns.Add("_4");
	vSection6.Columns.Add("_5");
	vSection6.Columns.Add("_6");
	vSection6.Columns.Add("_7");
	vSection6.Columns.Add("_8");

	vNewRow = vSection6.Add();
	vNewRow.code = "501";
	vNewRow._1 = ReportParameters.mGuests0Rus;
	vNewRow._2 = ReportParameters.mGuests1_4Rus;
	vNewRow._3 = ReportParameters.mGuests5_7Rus;
	vNewRow._4 = ReportParameters.mGuests8_14Rus;
	vNewRow._5 = ReportParameters.mGuests15_28Rus;
	vNewRow._6 = ReportParameters.mGuests29_90Rus;
	vNewRow._7 = ReportParameters.mGuests91_182Rus;
	vNewRow._8 = ReportParameters.mGuests183Rus;
	
	vNewRow = vSection6.Add();
	vNewRow.code = "502";
	vNewRow._1 = ReportParameters.mGuests0Foreigners;
	vNewRow._2 = ReportParameters.mGuests1_4Foreigners;
	vNewRow._3 = ReportParameters.mGuests5_7Foreigners;
	vNewRow._4 = ReportParameters.mGuests8_14Foreigners;
	vNewRow._5 = ReportParameters.mGuests15_28Foreigners;
	vNewRow._6 = ReportParameters.mGuests29_90Foreigners;
	vNewRow._7 = ReportParameters.mGuests91_182Foreigners;
	vNewRow._8 = ReportParameters.mGuests183Foreigners;
	
	vNewRow = vSection6.Add();
	vNewRow.code = "503";
	vNewRow._1 = ReportParameters.mModularGuests0Rus;
	vNewRow._2 = ReportParameters.mModularGuests1_4Rus;
	vNewRow._3 = ReportParameters.mModularGuests5_7Rus;
	vNewRow._4 = ReportParameters.mModularGuests8_14Rus;
	vNewRow._5 = ReportParameters.mModularGuests15_28Rus;
	vNewRow._6 = ReportParameters.mModularGuests29_90Rus;
	vNewRow._7 = ReportParameters.mModularGuests91_182Rus;
	vNewRow._8 = ReportParameters.mModularGuests183Rus;
	
	vNewRow = vSection6.Add();
	vNewRow.code = "504";
	vNewRow._1 = ReportParameters.mModularGuests0Foreigners;
	vNewRow._2 = ReportParameters.mModularGuests1_4Foreigners;
	vNewRow._3 = ReportParameters.mModularGuests5_7Foreigners;
	vNewRow._4 = ReportParameters.mModularGuests8_14Foreigners;
	vNewRow._5 = ReportParameters.mModularGuests15_28Foreigners;
	vNewRow._6 = ReportParameters.mModularGuests29_90Foreigners;
	vNewRow._7 = ReportParameters.mModularGuests91_182Foreigners;
	vNewRow._8 = ReportParameters.mModularGuests183Foreigners;
											
	vSections.Add(vSection6);
	
	// Table 8
	vSection7 = New ValueTable;
	vSection7.Columns.Add("code");
	vSection7.Columns.Add("_1");

	vNewRow = vSection7.Add();
	vNewRow.code = "601";
	vNewRow._1 = ReportParameters.mTotalIncome;
	
	vNewRow = vSection7.Add();
	vNewRow.code = "602";
	vNewRow._1 = ReportParameters.mTotalRoomRevenueIncome;
	
	vNewRow = vSection7.Add();
	vNewRow.code = "603";
	vNewRow._1 = ReportParameters.mTotalMealsIncome;
	
	vNewRow = vSection7.Add();
	vNewRow.code = "604";
	vNewRow._1 = ReportParameters.mTotalOtherIncome;
	
	vNewRow = vSection7.Add();
	vNewRow.code = "605";
	vNewRow._1 = ReportParameters.m605;
	
	vNewRow = vSection7.Add();
	vNewRow.code = "606";
	vNewRow._1 = ReportParameters.m606;
	
	vNewRow = vSection7.Add();
	vNewRow.code = "607";
	vNewRow._1 = ReportParameters.m607;
	
	vNewRow = vSection7.Add();
	vNewRow.code = "608";
	vNewRow._1 = ReportParameters.m608;
	
	vSections.Add(vSection7);
	
	// Table 9
	vSection8 = New ValueTable;
	vSection8.Columns.Add("code");
	vSection8.Columns.Add("_1");
	
	vNewRow = vSection8.Add();
	vNewRow.code = "701";
	vNewRow._1 = ReportParameters.m701;
	
	vNewRow = vSection8.Add();
	vNewRow.code = "702";
	vNewRow._1 = ReportParameters.m702;
	
	vNewRow = vSection8.Add();
	vNewRow.code = "703";
	vNewRow._1 = ReportParameters.m703;
	
	vSections.Add(vSection8);
	
	Return vSections;
	
EndFunction // AnnualReportSections

// -----------------------------------------------------------------------------
// 
// Returns:
//  Structure:
//  	* code - The code of the OKUD form
//  	* form - Form ID
//  	* shifr - Shifr
//  	* year - Year of the reporting period
//  	* period - Number of the report period
//  	* version - Version (from SBIS site)
//
Function AnnualReportDetails() Export
	//code: 609400007001 , idp: 01 , idf: 7 , shifr: to_1ksr , name: 1-КСР.СВЕДЕНИЯ О ДЕЯТЕЛЬНОСТИ СРЕДСТВА РАЗМЕЩЕНИЯ , obj: okpo , OKUD: 0609400 , version: 16-10-2025 , format-version: 1.3 , cdate: 2025-10-16 16:49:58	
	//OKUD_IDF_IDP_OKPO_YEAR_PERIOD_EXTINFO_SYSINFO

	vReportDetails = New Map;
	vReportDetails.Insert("format-version", "1.3");
	vReportDetails.Insert("version", "16.10.2025");
	vReportDetails.Insert("period",  "0101");
	vReportDetails.Insert("year", Format(PeriodTo, "DF=yyyy"));
	vReportDetails.Insert("shifr", "to_1ksr");
	vReportDetails.Insert("form", "007");
	vReportDetails.Insert("code", "0609400");
	
	Return vReportDetails;
EndFunction // AnnualReportDetails

#EndRegion
