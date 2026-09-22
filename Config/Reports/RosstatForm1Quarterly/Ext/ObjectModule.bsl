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
		PeriodFrom = AddMonth(BegOfMonth(CurrentSessionDate()), -3);
		PeriodTo = BegOfMonth(CurrentSessionDate()) - 1;
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
Procedure pmInitializeReportBuilder() Export
	
EndProcedure // pmInitializeReportBuilder

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
	Else
		pmGenerate2023(pSpreadsheet);
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
	
	// Report header
	vForm1Area = vTemplate.GetArea("Form1Quarterly");
	vPage2 = vTemplate.GetArea("Page2");
	
	// 1. Header parameters
	vForm1Area.Parameters.mPeriodStr = PeriodPresentation(BegOfQuarter(PeriodTo), EndOfDay(PeriodTo), cmLocalizationCode());
	vForm1Area.Parameters.mHotelName = TrimAll(Hotel.LegacyName);
	vForm1Area.Parameters.mHotelPostAddress = cmGetAddressPresentation(Hotel.PostAddress);
	vForm1Area.Parameters.mCompanyName = TrimAll(Company.LegacyName);
	vForm1Area.Parameters.mCompanyPostAddress = cmGetAddressPresentation(Company.PostAddress);
	vForm1Area.Parameters.mCompanyOKPOCode = TrimAll(Company.OKPO);
	
	// Put form
	pSpreadsheet.Put(vForm1Area);
	
	pSpreadsheet.PutHorizontalPageBreak();
	
	// 2. Table parameters
	
	// 2.1 Get total number of beds per end of period
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

	vPage2.Parameters.mTotalRooms = 0;
	vPage2.Parameters.mTotalBeds = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		// Total number of rooms and beds
		vPage2.Parameters.mTotalRooms = vRow.TotalRoomsBalance;
		vPage2.Parameters.mTotalBeds = vRow.TotalBedsBalance;
	EndIf;
	
	// 2.2 Get total number of top category rooms
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

	vPage2.Parameters.mTotalTopRooms = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		// Total number of rooms
		vPage2.Parameters.mTotalTopRooms = vRow.TotalRoomsBalance;
	EndIf;
	
	// 2.3 Get total number of guest days and number of checked in guests
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover,
	|	RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			NOT IsCorrection
	|				AND Hotel = &qHotel
	|				AND Company = &qCompany) AS RoomSalesTurnovers";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQryResult = vQry.Execute().Unload();

	vTotalGuests = 0;
	vPage2.Parameters.mTotalGuestdays = 0;
	vPage2.Parameters.mTotalGuests = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vPage2.Parameters.mTotalGuestdays = vRow.GuestDaysTurnover;
		vPage2.Parameters.mTotalGuests = vRow.GuestsCheckedInTurnover;
		
		If cmIsNumber(vRow.GuestsCheckedInTurnover) Then
			vTotalGuests = Number(vRow.GuestsCheckedInTurnover);
		EndIf;
	EndIf;
	
	// 2.4 Get total number of guests checked-in from Russia
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SUM(RoomSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			NOT IsCorrection AND Hotel = &qHotel
	|				AND Company = &qCompany) AS RoomSalesTurnovers
	|WHERE
	|	(RoomSalesTurnovers.Client.Citizenship = &qCitizenship
	|			OR ISNULL(RoomSalesTurnovers.Client.Citizenship, """") = """")";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCitizenship", RussiaCountry);
	vQryResult = vQry.Execute().Unload();

	vPage2.Parameters.mTotalGuestsRus = 0;
	vPage2.Parameters.mTotalGuestsFor = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		If cmIsNumber(vRow.GuestsCheckedInTurnover) Then
			vPage2.Parameters.mTotalGuestsRus = Number(vRow.GuestsCheckedInTurnover);
			vPage2.Parameters.mTotalGuestsFor = vTotalGuests - Number(vRow.GuestsCheckedInTurnover);
		EndIf;
	EndIf;

	// 2.5 Get total sales to guests with tour tickets
	vPage2.Parameters.mTotalTourTicketGuests = 0;
	
	If ValueIsFilled(TourTicketIncomeServiceGroup) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	RoomSalesTurnovers.GuestsCheckedInTurnover,
		|	RoomSalesTurnovers.RoomRevenueWithoutVATTurnover
		|FROM
		|	AccumulationRegister.Sales.Turnovers(
		|			&qPeriodFrom,
		|			&qPeriodTo,
		|			Period,
		|			NOT IsCorrection AND Hotel = &qHotel
		|				AND Company = &qCompany
		|				AND (Service IN HIERARCHY (&qTourTicketServices)
		|					OR (NOT &qUseServicesList))) AS RoomSalesTurnovers";
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
		vQryResult = vQry.Execute().Unload();

		If vQryResult.Count() > 0 Then
			vRow = vQryResult.Get(0);
			vPage2.Parameters.mTotalTourTicketGuests = vRow.GuestsCheckedInTurnover;
		EndIf;
	EndIf;

	// 2.6 Get total sales
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

	vPage2.Parameters.mTotalSumWithoutVAT = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vPage2.Parameters.mTotalSumWithoutVAT = Round(vRow.SalesWithoutVATTurnover/1000, 0);
	EndIf;
	
	// Report footer
	pSpreadsheet.Put(vPage2);
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
	vPage4HArea = vTemplate.GetArea("Page4Header");
	vPage4PArea = vTemplate.GetArea("Page4Period");
	vPage4CArea = vTemplate.GetArea("Page4Country");
	vPage4FArea = vTemplate.GetArea("Page4Footer");
	
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
	|	SUM(ISNULL(RoomSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover,
	|	SUM(ISNULL(RoomSales.SalesWithoutVATTurnover, 0)) AS SalesWithoutVATTurnover
	|FROM
	|	(SELECT
	|		RoomSalesTurnovers.Client AS Client,
	|		RoomSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover,
	|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
	|		RoomSalesTurnovers.SalesWithoutVATTurnover AS SalesWithoutVATTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection
	|					AND Hotel = &qHotel
	|					AND Company = &qCompany) AS RoomSalesTurnovers) AS RoomSales";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQryResult = vQry.Execute().Unload();

	vTotalGuestDays = 0;
	vTotalGuests = 0;
	vTotalSalesWithoutVAT = 0;
	vPage3Area.Parameters.mTotalGuestDays = 0;
	vPage3Area.Parameters.mTotalGuests = 0;
	vPage3Area.Parameters.mTotalSumWithoutVAT = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		If vRow.GuestDaysTurnover <> Null Then 
			vPage3Area.Parameters.mTotalGuestDays = vRow.GuestDaysTurnover;
		EndIf;
		If vRow.GuestsCheckedInTurnover <> Null Then 
			vPage3Area.Parameters.mTotalGuests = vRow.GuestsCheckedInTurnover;
		EndIf;
		If vRow.SalesWithoutVATTurnover <> Null Then 
			vPage3Area.Parameters.mTotalSumWithoutVAT = Round(vRow.SalesWithoutVATTurnover/1000, 0);
		EndIf;
		vTotalGuestDays = vRow.GuestDaysTurnover;
		vTotalGuests = vRow.GuestsCheckedInTurnover; 
		vTotalSalesWithoutVAT = vRow.SalesWithoutVATTurnover;
	EndIf;
	
	// 3.4 Get total number of checked-in guests from Russia
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SUM(ISNULL(GeoSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		GeoSalesTurnovers.Client AS Client,
	|		GeoSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection
	|					AND Hotel = &qHotel
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

	vRussiaGuests = 0;
	vPage3Area.Parameters.mTotalGuestsRus = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vPage3Area.Parameters.mTotalGuestsRus = vRow.GuestsCheckedInTurnover;
		vRussiaGuests = vRow.GuestsCheckedInTurnover;
	EndIf;
	
	// 3.5 Get total number of guest days and checked-in foreigner guests
	If vTotalGuests <> Null And vRussiaGuests <> Null Then
		vPage3Area.Parameters.mTotalGuestsFor = vTotalGuests - vRussiaGuests;
	Else
		vPage3Area.Parameters.mTotalGuestsFor = 0;
	EndIf;
	
	// 3.6 Get total number of checked-in guests with tour tickets
	vPage3Area.Parameters.mTotalTourTicketGuests = 0;
	If ValueIsFilled(TourTicketIncomeServiceGroup) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	SUM(ISNULL(RoomSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover
		|FROM
		|	(SELECT
		|		RoomSalesTurnovers.Client AS Client,
		|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover
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

		vTotalTourTicketGuests = 0;
		If vQryResult.Count() > 0 Then
			vRow = vQryResult.Get(0);
			vPage3Area.Parameters.mTotalTourTicketGuests = vRow.GuestsCheckedInTurnover;
			vTotalTourTicketGuests = vRow.GuestsCheckedInTurnover;
		EndIf;
		
		// The same from russia
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	SUM(ISNULL(RoomSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover
		|FROM
		|	(SELECT
		|		RoomSalesTurnovers.Client AS Client,
		|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover
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
			
			vPage3Area.Parameters.mTotalTourTicketGuestsFor = vTotalTourTicketGuests - vRow.GuestsCheckedInTurnover;
		Else
			vPage3Area.Parameters.mTotalTourTicketGuestsRus = 0;
			
			vPage3Area.Parameters.mTotalTourTicketGuestsFor = vTotalTourTicketGuests;
		EndIf;
	EndIf;
	
	pSpreadsheet.Put(vPage3Area);
	
	pSpreadsheet.PutHorizontalPageBreak();
	
	// Page 4
	pSpreadsheet.Put(vPage4HArea);
	
	// 4.1.1 Get total number of russian checked-in guests per trip purposes
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 401
	|		WHEN GeoSales.Duration < 5
	|			THEN 402
	|		WHEN GeoSales.Duration < 8
	|			THEN 403
	|		WHEN GeoSales.Duration < 15
	|			THEN 404
	|		WHEN GeoSales.Duration < 29
	|			THEN 405
	|		WHEN GeoSales.Duration < 91
	|			THEN 406
	|		ELSE 407
	|	END AS PeriodNumber,
	|	GeoSales.Country AS Country,
	|	ISNULL(GeoSales.Country.Code, """") AS CountryCode,
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 7
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 9
	|		WHEN GeoSales.TripPurpose = &qEducation
	|			THEN 5
	|		ELSE 9
	|	END AS TripPurposeType,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0) AS Duration,
	|		GeoSalesTurnovers.Client.Citizenship AS Country,
	|		GeoSalesTurnovers.TripPurpose AS TripPurpose,
	|		SUM(GeoSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection
	|					AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND (Client.Citizenship <> &qRussia
	|						AND ISNULL(Client.Citizenship.Description, """") <> """")) AS GeoSalesTurnovers
	|	
	|	GROUP BY
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0),
	|		GeoSalesTurnovers.Client.Citizenship,
	|		GeoSalesTurnovers.TripPurpose) AS GeoSales
	|
	|GROUP BY
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 401
	|		WHEN GeoSales.Duration < 5
	|			THEN 402
	|		WHEN GeoSales.Duration < 8
	|			THEN 403
	|		WHEN GeoSales.Duration < 15
	|			THEN 404
	|		WHEN GeoSales.Duration < 29
	|			THEN 405
	|		WHEN GeoSales.Duration < 91
	|			THEN 406
	|		ELSE 407
	|	END,
	|	GeoSales.Country,
	|	ISNULL(GeoSales.Country.Code, """"),
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 7
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 9
	|		WHEN GeoSales.TripPurpose = &qEducation
	|			THEN 5
	|		ELSE 9
	|	END
	|
	|ORDER BY
	|	PeriodNumber,
	|	CountryCode,
	|	TripPurposeType
	|TOTALS
	|	SUM(GuestsCheckedInTurnover)
	|BY
	|	PeriodNumber,
	|	Country,
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
	vQryResult = vQry.Execute();
	
	vPeriodsList = New ValueList();
	vPeriodsList.Add(401, "Без ночевки - всего");
	vPeriodsList.Add(402, "1 - 4 ночевки - всего");
	vPeriodsList.Add(403, "5 - 7 ночевок - всего");
	vPeriodsList.Add(404, "8 - 14 ночевок - всего");
	vPeriodsList.Add(405, "15 - 28 ночевок - всего");
	vPeriodsList.Add(406, "29 - 90 ночевок - всего");
	vPeriodsList.Add(407, "91 и более ночевок");
	
	For Each vPeriodsListItem In vPeriodsList Do
		vPage4PArea.Parameters.mPeriodName = vPeriodsListItem.Presentation;
		vPage4PArea.Parameters.mRowNumber = vPeriodsListItem.Value;
		
		vGuests1 = 0;
		vGuests2 = 0;
		vGuests3 = 0;
		vGuests4 = 0;
		vGuests5 = 0;
		vGuests6 = 0;
		vGuests7 = 0;
		vGuests8 = 0;
		vGuests9 = 0;
		vGuests10 = 0;
		
		vTotalsByPeriod = vQryResult.Select(QueryResultIteration.ByGroups, "PeriodNumber");
		While vTotalsByPeriod.Next() Do
			vPeriodNumber = vTotalsByPeriod.PeriodNumber;
			If vPeriodsListItem.Value = vPeriodNumber Then
				// By trip purpose
				vTotalsByTripType = vTotalsByPeriod.Select(QueryResultIteration.ByGroups, "TripPurposeType");
				While vTotalsByTripType.Next() Do
					If vTotalsByTripType.TripPurposeType = 1 Then
						vGuests1 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 2 Then
						vGuests2 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 3 Then
						vGuests3 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 4 Then
						vGuests4 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 5 Then
						vGuests5 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 6 Then
						vGuests6 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 7 Then
						vGuests7 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 8 Then
						vGuests8 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 9 Then
						vGuests9 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 10 Then
						vGuests10 = vTotalsByTripType.GuestsCheckedInTurnover;
					EndIf;
				EndDo;
				
				vPage4PArea.Parameters.mGuestsTourists = vGuests1;
				vPage4PArea.Parameters.mGuestsTouristsBeach = vGuests2;
				vPage4PArea.Parameters.mGuestsTouristsCulture = vGuests3;
				vPage4PArea.Parameters.mGuestsTouristsCruises = vGuests4;
				vPage4PArea.Parameters.mGuestsEducation = vGuests5;
				vPage4PArea.Parameters.mGuestsRecreation = vGuests6;
				vPage4PArea.Parameters.mGuestsPilgrims = vGuests7;
				vPage4PArea.Parameters.mGuestsShoping = vGuests8;
				vPage4PArea.Parameters.mGuestsPrivateOther = vGuests9;
				vPage4PArea.Parameters.mGuestsBusiness = vGuests10;
				
				pSpreadsheet.Put(vPage4PArea);
				
				// By countries
				vTotalsByCountry = vTotalsByPeriod.Select(QueryResultIteration.ByGroups, "Country");
				While vTotalsByCountry.Next() Do
					If Not ValueIsFilled(vTotalsByCountry.Country) Then
						Continue;
					EndIf;
		
					vGuests1 = 0;
					vGuests2 = 0;
					vGuests3 = 0;
					vGuests4 = 0;
					vGuests5 = 0;
					vGuests6 = 0;
					vGuests7 = 0;
					vGuests8 = 0;
					vGuests9 = 0;
					vGuests10 = 0;
					
					// By trip purpose
					vTotalsByTripType = vTotalsByCountry.Select(QueryResultIteration.ByGroups, "TripPurposeType");
					While vTotalsByTripType.Next() Do
						If vTotalsByTripType.TripPurposeType = 1 Then
							vGuests1 = vTotalsByTripType.GuestsCheckedInTurnover;
						ElsIf vTotalsByTripType.TripPurposeType = 2 Then
							vGuests2 = vTotalsByTripType.GuestsCheckedInTurnover;
						ElsIf vTotalsByTripType.TripPurposeType = 3 Then
							vGuests3 = vTotalsByTripType.GuestsCheckedInTurnover;
						ElsIf vTotalsByTripType.TripPurposeType = 4 Then
							vGuests4 = vTotalsByTripType.GuestsCheckedInTurnover;
						ElsIf vTotalsByTripType.TripPurposeType = 5 Then
							vGuests5 = vTotalsByTripType.GuestsCheckedInTurnover;
						ElsIf vTotalsByTripType.TripPurposeType = 6 Then
							vGuests6 = vTotalsByTripType.GuestsCheckedInTurnover;
						ElsIf vTotalsByTripType.TripPurposeType = 7 Then
							vGuests7 = vTotalsByTripType.GuestsCheckedInTurnover;
						ElsIf vTotalsByTripType.TripPurposeType = 8 Then
							vGuests8 = vTotalsByTripType.GuestsCheckedInTurnover;
						ElsIf vTotalsByTripType.TripPurposeType = 9 Then
							vGuests9 = vTotalsByTripType.GuestsCheckedInTurnover;
						ElsIf vTotalsByTripType.TripPurposeType = 10 Then
							vGuests10 = vTotalsByTripType.GuestsCheckedInTurnover;
						EndIf;
					EndDo;
					
					vPage4CArea.Parameters.mCountry = TrimAll(vTotalsByCountry.Country);
					vPage4CArea.Parameters.mCountryCode = TrimAll(vTotalsByCountry.Country.Code);
					
					vPage4CArea.Parameters.mGuestsTourists = vGuests1;
					vPage4CArea.Parameters.mGuestsTouristsBeach = vGuests2;
					vPage4CArea.Parameters.mGuestsTouristsCulture = vGuests3;
					vPage4CArea.Parameters.mGuestsTouristsCruises = vGuests4;
					vPage4CArea.Parameters.mGuestsEducation = vGuests5;
					vPage4CArea.Parameters.mGuestsRecreation = vGuests6;
					vPage4CArea.Parameters.mGuestsPilgrims = vGuests7;
					vPage4CArea.Parameters.mGuestsShoping = vGuests8;
					vPage4CArea.Parameters.mGuestsPrivateOther = vGuests9;
					vPage4CArea.Parameters.mGuestsBusiness = vGuests10;
					
					pSpreadsheet.Put(vPage4CArea);
				EndDo;
			EndIf;
		EndDo;
	EndDo;
	
	// Page 4 footer
	pSpreadsheet.Put(vPage4FArea);
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
	vPage4HArea = vTemplate.GetArea("Page4Header");
	vPage4PArea = vTemplate.GetArea("Page4Period");
	vPage4CArea = vTemplate.GetArea("Page4Country");
	vPage4FArea = vTemplate.GetArea("Page4Footer");
	
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
	|	SUM(ISNULL(RoomSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover,
	|	SUM(ISNULL(RoomSales.SalesWithoutVATTurnover, 0)) AS SalesWithoutVATTurnover
	|FROM
	|	(SELECT
	|		RoomSalesTurnovers.Client AS Client,
	|		RoomSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover,
	|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
	|		RoomSalesTurnovers.SalesWithoutVATTurnover AS SalesWithoutVATTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection
	|					AND Hotel = &qHotel
	|					AND Company = &qCompany) AS RoomSalesTurnovers) AS RoomSales";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQryResult = vQry.Execute().Unload();

	vTotalGuestDays = 0;
	vTotalGuests = 0;
	vTotalSalesWithoutVAT = 0;
	vPage3Area.Parameters.mTotalGuestDays = 0;
	vPage3Area.Parameters.mTotalGuests = 0;
	vPage3Area.Parameters.mTotalSumWithoutVAT = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		If vRow.GuestDaysTurnover <> Null Then 
			vPage3Area.Parameters.mTotalGuestDays = vRow.GuestDaysTurnover;
		EndIf;
		If vRow.GuestsCheckedInTurnover <> Null Then 
			vPage3Area.Parameters.mTotalGuests = vRow.GuestsCheckedInTurnover;
		EndIf;
		If vRow.SalesWithoutVATTurnover <> Null Then 
			vPage3Area.Parameters.mTotalSumWithoutVAT = Round(vRow.SalesWithoutVATTurnover/1000, 0);
		EndIf;
		vTotalGuestDays = vRow.GuestDaysTurnover;
		vTotalGuests = vRow.GuestsCheckedInTurnover; 
		vTotalSalesWithoutVAT = vRow.SalesWithoutVATTurnover;
	EndIf;
	
	// 3.4 Get total number of checked-in guests from Russia
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SUM(ISNULL(GeoSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		GeoSalesTurnovers.Client AS Client,
	|		GeoSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection
	|					AND Hotel = &qHotel
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

	vRussiaGuests = 0;
	vPage3Area.Parameters.mTotalGuestsRus = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vPage3Area.Parameters.mTotalGuestsRus = vRow.GuestsCheckedInTurnover;
		vRussiaGuests = vRow.GuestsCheckedInTurnover;
	EndIf;
	
	// 3.5 Get total number of guest days and checked-in foreigner guests
	If vTotalGuests <> Null And vRussiaGuests <> Null Then
		vPage3Area.Parameters.mTotalGuestsFor = vTotalGuests - vRussiaGuests;
	Else
		vPage3Area.Parameters.mTotalGuestsFor = 0;
	EndIf;
	
	// 3.6 Get total number of checked-in guests with tour tickets
	vPage3Area.Parameters.mTotalTourTicketGuests = 0;
	If ValueIsFilled(TourTicketIncomeServiceGroup) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	SUM(ISNULL(RoomSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover
		|FROM
		|	(SELECT
		|		RoomSalesTurnovers.Client AS Client,
		|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover
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

		vTotalTourTicketGuests = 0;
		If vQryResult.Count() > 0 Then
			vRow = vQryResult.Get(0);
			vPage3Area.Parameters.mTotalTourTicketGuests = vRow.GuestsCheckedInTurnover;
			vTotalTourTicketGuests = vRow.GuestsCheckedInTurnover;
		EndIf;
		
		// The same from russia
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	SUM(ISNULL(RoomSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover
		|FROM
		|	(SELECT
		|		RoomSalesTurnovers.Client AS Client,
		|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover
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
			
			vPage3Area.Parameters.mTotalTourTicketGuestsFor = vTotalTourTicketGuests - vRow.GuestsCheckedInTurnover;
		Else
			vPage3Area.Parameters.mTotalTourTicketGuestsRus = 0;
			
			vPage3Area.Parameters.mTotalTourTicketGuestsFor = vTotalTourTicketGuests;
		EndIf;
	EndIf;
	
	pSpreadsheet.Put(vPage3Area);
	
	pSpreadsheet.PutHorizontalPageBreak();
	
	// Page 4
	pSpreadsheet.Put(vPage4HArea);
	
	// 4.1.1 Get total number of russian checked-in guests per trip purposes
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 401
	|		WHEN GeoSales.Duration < 5
	|			THEN 402
	|		WHEN GeoSales.Duration < 8
	|			THEN 403
	|		WHEN GeoSales.Duration < 15
	|			THEN 404
	|		WHEN GeoSales.Duration < 29
	|			THEN 405
	|		WHEN GeoSales.Duration < 91
	|			THEN 406
	|		ELSE 407
	|	END AS PeriodNumber,
	|	GeoSales.Country AS Country,
	|	ISNULL(GeoSales.Country.Code, """") AS CountryCode,
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 7
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 9
	|		WHEN GeoSales.TripPurpose = &qEducation
	|			THEN 5
	|		ELSE 9
	|	END AS TripPurposeType,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0) AS Duration,
	|		GeoSalesTurnovers.Client.Citizenship AS Country,
	|		GeoSalesTurnovers.TripPurpose AS TripPurpose,
	|		SUM(GeoSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection
	|					AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND (Client.Citizenship <> &qRussia
	|						AND ISNULL(Client.Citizenship.Description, """") <> """")) AS GeoSalesTurnovers
	|	
	|	GROUP BY
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0),
	|		GeoSalesTurnovers.Client.Citizenship,
	|		GeoSalesTurnovers.TripPurpose) AS GeoSales
	|
	|GROUP BY
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 401
	|		WHEN GeoSales.Duration < 5
	|			THEN 402
	|		WHEN GeoSales.Duration < 8
	|			THEN 403
	|		WHEN GeoSales.Duration < 15
	|			THEN 404
	|		WHEN GeoSales.Duration < 29
	|			THEN 405
	|		WHEN GeoSales.Duration < 91
	|			THEN 406
	|		ELSE 407
	|	END,
	|	GeoSales.Country,
	|	ISNULL(GeoSales.Country.Code, """"),
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 7
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 9
	|		WHEN GeoSales.TripPurpose = &qEducation
	|			THEN 5
	|		ELSE 9
	|	END
	|
	|ORDER BY
	|	PeriodNumber,
	|	CountryCode,
	|	TripPurposeType
	|TOTALS
	|	SUM(GuestsCheckedInTurnover)
	|BY
	|	PeriodNumber,
	|	Country,
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
	vQryResult = vQry.Execute();
	
	vPeriodsList = New ValueList();
	vPeriodsList.Add(401, "Без ночевки - всего");
	vPeriodsList.Add(402, "1 - 4 ночевки - всего");
	vPeriodsList.Add(403, "5 - 7 ночевок - всего");
	vPeriodsList.Add(404, "8 - 14 ночевок - всего");
	vPeriodsList.Add(405, "15 - 28 ночевок - всего");
	vPeriodsList.Add(406, "29 - 90 ночевок - всего");
	vPeriodsList.Add(407, "91 и более ночевок");
	
	For Each vPeriodsListItem In vPeriodsList Do
		vPage4PArea.Parameters.mPeriodName = vPeriodsListItem.Presentation;
		vPage4PArea.Parameters.mRowNumber = vPeriodsListItem.Value;
		
		vGuests1 = 0;
		vGuests2 = 0;
		vGuests3 = 0;
		vGuests4 = 0;
		vGuests5 = 0;
		vGuests6 = 0;
		vGuests7 = 0;
		vGuests8 = 0;
		vGuests9 = 0;
		vGuests10 = 0;
		
		vTotalsByPeriod = vQryResult.Select(QueryResultIteration.ByGroups, "PeriodNumber");
		While vTotalsByPeriod.Next() Do
			vPeriodNumber = vTotalsByPeriod.PeriodNumber;
			If vPeriodsListItem.Value = vPeriodNumber Then
				// By trip purpose
				vTotalsByTripType = vTotalsByPeriod.Select(QueryResultIteration.ByGroups, "TripPurposeType");
				While vTotalsByTripType.Next() Do
					If vTotalsByTripType.TripPurposeType = 1 Then
						vGuests1 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 2 Then
						vGuests2 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 3 Then
						vGuests3 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 4 Then
						vGuests4 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 5 Then
						vGuests5 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 6 Then
						vGuests6 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 7 Then
						vGuests7 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 8 Then
						vGuests8 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 9 Then
						vGuests9 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 10 Then
						vGuests10 = vTotalsByTripType.GuestsCheckedInTurnover;
					EndIf;
				EndDo;
				
				vPage4PArea.Parameters.mGuestsTourists = vGuests1;
				vPage4PArea.Parameters.mGuestsTouristsBeach = vGuests2;
				vPage4PArea.Parameters.mGuestsTouristsCulture = vGuests3;
				vPage4PArea.Parameters.mGuestsTouristsCruises = vGuests4;
				vPage4PArea.Parameters.mGuestsEducation = vGuests5;
				vPage4PArea.Parameters.mGuestsRecreation = vGuests6;
				vPage4PArea.Parameters.mGuestsPilgrims = vGuests7;
				vPage4PArea.Parameters.mGuestsShoping = vGuests8;
				vPage4PArea.Parameters.mGuestsPrivateOther = vGuests9;
				vPage4PArea.Parameters.mGuestsBusiness = vGuests10;
				
				pSpreadsheet.Put(vPage4PArea);
				
				// By countries
				vTotalsByCountry = vTotalsByPeriod.Select(QueryResultIteration.ByGroups, "Country");
				While vTotalsByCountry.Next() Do
					If Not ValueIsFilled(vTotalsByCountry.Country) Then
						Continue;
					EndIf;
		
					vGuests1 = 0;
					vGuests2 = 0;
					vGuests3 = 0;
					vGuests4 = 0;
					vGuests5 = 0;
					vGuests6 = 0;
					vGuests7 = 0;
					vGuests8 = 0;
					vGuests9 = 0;
					vGuests10 = 0;
					
					// By trip purpose
					vTotalsByTripType = vTotalsByCountry.Select(QueryResultIteration.ByGroups, "TripPurposeType");
					While vTotalsByTripType.Next() Do
						If vTotalsByTripType.TripPurposeType = 1 Then
							vGuests1 = vTotalsByTripType.GuestsCheckedInTurnover;
						ElsIf vTotalsByTripType.TripPurposeType = 2 Then
							vGuests2 = vTotalsByTripType.GuestsCheckedInTurnover;
						ElsIf vTotalsByTripType.TripPurposeType = 3 Then
							vGuests3 = vTotalsByTripType.GuestsCheckedInTurnover;
						ElsIf vTotalsByTripType.TripPurposeType = 4 Then
							vGuests4 = vTotalsByTripType.GuestsCheckedInTurnover;
						ElsIf vTotalsByTripType.TripPurposeType = 5 Then
							vGuests5 = vTotalsByTripType.GuestsCheckedInTurnover;
						ElsIf vTotalsByTripType.TripPurposeType = 6 Then
							vGuests6 = vTotalsByTripType.GuestsCheckedInTurnover;
						ElsIf vTotalsByTripType.TripPurposeType = 7 Then
							vGuests7 = vTotalsByTripType.GuestsCheckedInTurnover;
						ElsIf vTotalsByTripType.TripPurposeType = 8 Then
							vGuests8 = vTotalsByTripType.GuestsCheckedInTurnover;
						ElsIf vTotalsByTripType.TripPurposeType = 9 Then
							vGuests9 = vTotalsByTripType.GuestsCheckedInTurnover;
						ElsIf vTotalsByTripType.TripPurposeType = 10 Then
							vGuests10 = vTotalsByTripType.GuestsCheckedInTurnover;
						EndIf;
					EndDo;
					
					vPage4CArea.Parameters.mCountry = TrimAll(vTotalsByCountry.Country);
					vPage4CArea.Parameters.mCountryCode = TrimAll(vTotalsByCountry.Country.Code);
					
					vPage4CArea.Parameters.mGuestsTourists = vGuests1;
					vPage4CArea.Parameters.mGuestsTouristsBeach = vGuests2;
					vPage4CArea.Parameters.mGuestsTouristsCulture = vGuests3;
					vPage4CArea.Parameters.mGuestsTouristsCruises = vGuests4;
					vPage4CArea.Parameters.mGuestsEducation = vGuests5;
					vPage4CArea.Parameters.mGuestsRecreation = vGuests6;
					vPage4CArea.Parameters.mGuestsPilgrims = vGuests7;
					vPage4CArea.Parameters.mGuestsShoping = vGuests8;
					vPage4CArea.Parameters.mGuestsPrivateOther = vGuests9;
					vPage4CArea.Parameters.mGuestsBusiness = vGuests10;
					
					pSpreadsheet.Put(vPage4CArea);
				EndDo;
			EndIf;
		EndDo;
	EndDo;
	
	// Page 4 footer
	pSpreadsheet.Put(vPage4FArea);
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
	vPage4HArea = vTemplate.GetArea("Page4Header");
	vPage4PArea = vTemplate.GetArea("Page4Period");
	vPage4CArea = vTemplate.GetArea("Page4Country");
	vPage4FArea = vTemplate.GetArea("Page4Footer");
	vPage5HArea = vTemplate.GetArea("Page5Header");
	vPage5PArea = vTemplate.GetArea("Page5Period");
	vPage5FArea = vTemplate.GetArea("Page5Footer");
	
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
	|	SUM(ISNULL(RoomSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover,
	|	SUM(ISNULL(RoomSales.SalesWithoutVATTurnover, 0)) AS SalesWithoutVATTurnover
	|FROM
	|	(SELECT
	|		RoomSalesTurnovers.Client AS Client,
	|		RoomSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover,
	|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
	|		RoomSalesTurnovers.SalesWithoutVATTurnover AS SalesWithoutVATTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection
	|					AND Hotel = &qHotel
	|					AND Company = &qCompany) AS RoomSalesTurnovers) AS RoomSales";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQryResult = vQry.Execute().Unload();

	vTotalGuestDays = 0;
	vTotalGuests = 0;
	vTotalSalesWithoutVAT = 0;
	vPage3Area.Parameters.mTotalGuestDays = 0;
	vPage3Area.Parameters.mTotalGuestDaysRus = 0;
	vPage3Area.Parameters.mTotalGuestDaysFor = 0;
	vPage3Area.Parameters.mTotalGuests = 0;
	vPage3Area.Parameters.mTotalSumWithoutVAT = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		If vRow.GuestDaysTurnover <> Null Then 
			vPage3Area.Parameters.mTotalGuestDays = vRow.GuestDaysTurnover;
		EndIf;
		If vRow.GuestsCheckedInTurnover <> Null Then 
			vPage3Area.Parameters.mTotalGuests = vRow.GuestsCheckedInTurnover;
		EndIf;
		If vRow.SalesWithoutVATTurnover <> Null Then 
			vPage3Area.Parameters.mTotalSumWithoutVAT = Round(vRow.SalesWithoutVATTurnover/1000, 0);
		EndIf;
		vTotalGuestDays = vRow.GuestDaysTurnover;
		vTotalGuests = vRow.GuestsCheckedInTurnover; 
		vTotalSalesWithoutVAT = vRow.SalesWithoutVATTurnover;
	EndIf;
	
	// 3.4 Get total number of checked-in guests from Russia
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SUM(ISNULL(GeoSales.GuestDaysTurnover, 0)) AS GuestDaysTurnover,
	|	SUM(ISNULL(GeoSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		GeoSalesTurnovers.Client AS Client,
	|		GeoSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
	|		GeoSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection
	|					AND Hotel = &qHotel
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
	vRussiaGuests = 0;
	vPage3Area.Parameters.mTotalGuestDaysRus = 0;
	vPage3Area.Parameters.mTotalGuestsRus = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vPage3Area.Parameters.mTotalGuestDaysRus = vRow.GuestDaysTurnover;
		vPage3Area.Parameters.mTotalGuestsRus = vRow.GuestsCheckedInTurnover;
		vRussiaGuestDays = vRow.GuestDaysTurnover;
		vRussiaGuests = vRow.GuestsCheckedInTurnover;
	EndIf;
	
	// 3.5 Get total number of guest days and checked-in foreigner guests
	If vTotalGuestDays <> Null And vRussiaGuestDays <> Null Then
		vPage3Area.Parameters.mTotalGuestDaysFor = vTotalGuestDays - vRussiaGuestDays;
	Else
		vPage3Area.Parameters.mTotalGuestDaysFor = 0;
	EndIf;
	If vTotalGuests <> Null And vRussiaGuests <> Null Then
		vPage3Area.Parameters.mTotalGuestsFor = vTotalGuests - vRussiaGuests;
	Else
		vPage3Area.Parameters.mTotalGuestsFor = 0;
	EndIf;
	
	// 3.6 Get total number of checked-in guests with tour tickets
	vPage3Area.Parameters.mTotalTourTicketGuests = 0;
	If ValueIsFilled(TourTicketIncomeServiceGroup) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	SUM(ISNULL(RoomSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover
		|FROM
		|	(SELECT
		|		RoomSalesTurnovers.Client AS Client,
		|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover
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

		vTotalTourTicketGuests = 0;
		If vQryResult.Count() > 0 Then
			vRow = vQryResult.Get(0);
			vPage3Area.Parameters.mTotalTourTicketGuests = vRow.GuestsCheckedInTurnover;
			vTotalTourTicketGuests = vRow.GuestsCheckedInTurnover;
		EndIf;
		
		// The same from russia
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	SUM(ISNULL(RoomSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover
		|FROM
		|	(SELECT
		|		RoomSalesTurnovers.Client AS Client,
		|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover
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
			
			vPage3Area.Parameters.mTotalTourTicketGuestsFor = vTotalTourTicketGuests - vRow.GuestsCheckedInTurnover;
		Else
			vPage3Area.Parameters.mTotalTourTicketGuestsRus = 0;
			
			vPage3Area.Parameters.mTotalTourTicketGuestsFor = vTotalTourTicketGuests;
		EndIf;
	EndIf;
	
	pSpreadsheet.Put(vPage3Area);
	
	pSpreadsheet.PutHorizontalPageBreak();
	
	// Page 4
	pSpreadsheet.Put(vPage4HArea);
	
	// 4.1.1 Get total number of foreign checked-in guests per trip duration
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 401
	|		WHEN GeoSales.Duration < 5
	|			THEN 402
	|		WHEN GeoSales.Duration < 8
	|			THEN 403
	|		WHEN GeoSales.Duration < 15
	|			THEN 404
	|		WHEN GeoSales.Duration < 29
	|			THEN 405
	|		WHEN GeoSales.Duration < 91
	|			THEN 406
	|		ELSE 407
	|	END AS PeriodNumber,
	|	GeoSales.Country AS Country,
	|	ISNULL(GeoSales.Country.Code, """") AS CountryCode,
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 9
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qBeachRecreation
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qCulturalAndEducational
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qCruiseTourism
	|			THEN 4
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 9
	|		WHEN GeoSales.TripPurpose = &qStudy
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qOther
	|			THEN 9
	|		WHEN GeoSales.TripPurpose = &qTransit
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qRecreation
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qPilgrims
	|			THEN 7
	|		WHEN GeoSales.TripPurpose = &qShopping
	|			THEN 8
	|		ELSE 9
	|	END AS TripPurposeType,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0) AS Duration,
	|		GeoSalesTurnovers.Client.Citizenship AS Country,
	|		GeoSalesTurnovers.TripPurpose AS TripPurpose,
	|		SUM(GeoSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection
	|					AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND (Client.Citizenship <> &qRussia
	|						AND ISNULL(Client.Citizenship.Description, """") <> """")) AS GeoSalesTurnovers
	|	
	|	GROUP BY
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0),
	|		GeoSalesTurnovers.Client.Citizenship,
	|		GeoSalesTurnovers.TripPurpose) AS GeoSales
	|
	|GROUP BY
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 401
	|		WHEN GeoSales.Duration < 5
	|			THEN 402
	|		WHEN GeoSales.Duration < 8
	|			THEN 403
	|		WHEN GeoSales.Duration < 15
	|			THEN 404
	|		WHEN GeoSales.Duration < 29
	|			THEN 405
	|		WHEN GeoSales.Duration < 91
	|			THEN 406
	|		ELSE 407
	|	END,
	|	GeoSales.Country,
	|	ISNULL(GeoSales.Country.Code, """"),
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 9
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qBeachRecreation
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qCulturalAndEducational
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qCruiseTourism
	|			THEN 4
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 9
	|		WHEN GeoSales.TripPurpose = &qStudy
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qOther
	|			THEN 9
	|		WHEN GeoSales.TripPurpose = &qTransit
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qRecreation
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qPilgrims
	|			THEN 7
	|		WHEN GeoSales.TripPurpose = &qShopping
	|			THEN 8
	|		ELSE 9
	|	END
	|
	|ORDER BY
	|	PeriodNumber,
	|	CountryCode,
	|	TripPurposeType
	|TOTALS
	|	SUM(GuestsCheckedInTurnover)
	|BY
	|	PeriodNumber,
	|	Country,
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
	vQry.SetParameter("qBeachRecreation", Catalogs.TripPurposes.BeachRecreation);
	vQry.SetParameter("qCulturalAndEducational", Catalogs.TripPurposes.CulturalAndEducational);
	vQry.SetParameter("qCruiseTourism", Catalogs.TripPurposes.CruiseTourism);
	vQry.SetParameter("qPrivate", Catalogs.TripPurposes.Private);
	vQry.SetParameter("qScientific", Catalogs.TripPurposes.Scientific);
	vQry.SetParameter("qStudy", Catalogs.TripPurposes.Study);
	vQry.SetParameter("qRecreation", Catalogs.TripPurposes.Recreation);
	vQry.SetParameter("qShopping", Catalogs.TripPurposes.Shopping);
	vQry.SetParameter("qPilgrims", Catalogs.TripPurposes.Pilgrims);
	vQry.SetParameter("qTransit", Catalogs.TripPurposes.Transit);
	vQry.SetParameter("qOther", Catalogs.TripPurposes.Other);
	vQry.SetParameter("qCompany", Company);
	vQryResult = vQry.Execute();
	
	vPeriodsList = New ValueList();
	vPeriodsList.Add(401, "Без ночевки - всего");
	vPeriodsList.Add(402, "1 - 4 ночевки - всего");
	vPeriodsList.Add(403, "5 - 7 ночевок - всего");
	vPeriodsList.Add(404, "8 - 14 ночевок - всего");
	vPeriodsList.Add(405, "15 - 28 ночевок - всего");
	vPeriodsList.Add(406, "29 - 90 ночевок - всего");
	vPeriodsList.Add(407, "91 и более ночевок");
	
	For Each vPeriodsListItem In vPeriodsList Do
		vPage4PArea.Parameters.mPeriodName = vPeriodsListItem.Presentation;
		vPage4PArea.Parameters.mRowNumber = vPeriodsListItem.Value;
		
		vGuests1 = 0;
		vGuests2 = 0;
		vGuests3 = 0;
		vGuests4 = 0;
		vGuests5 = 0;
		vGuests6 = 0;
		vGuests7 = 0;
		vGuests8 = 0;
		vGuests9 = 0;
		vGuests10 = 0;
		
		vPeriodIsFound = False;
		vTotalsByPeriod = vQryResult.Select(QueryResultIteration.ByGroups, "PeriodNumber");
		While vTotalsByPeriod.Next() Do
			vPeriodNumber = vTotalsByPeriod.PeriodNumber;
			If vPeriodsListItem.Value = vPeriodNumber Then
				vPeriodIsFound = True;

				// By trip purpose
				vTotalsByTripType = vTotalsByPeriod.Select(QueryResultIteration.ByGroups, "TripPurposeType");
				While vTotalsByTripType.Next() Do
					If vTotalsByTripType.TripPurposeType = 1 Then
						vGuests1 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 2 Then
						vGuests2 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 3 Then
						vGuests3 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 4 Then
						vGuests4 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 5 Then
						vGuests5 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 6 Then
						vGuests6 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 7 Then
						vGuests7 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 8 Then
						vGuests8 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 9 Then
						vGuests9 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 10 Then
						vGuests10 = vTotalsByTripType.GuestsCheckedInTurnover;
					EndIf;
				EndDo;
				
				vPage4PArea.Parameters.mGuestsTourists = vGuests1;
				vPage4PArea.Parameters.mGuestsTouristsBeach = vGuests2;
				vPage4PArea.Parameters.mGuestsTouristsCulture = vGuests3;
				vPage4PArea.Parameters.mGuestsTouristsCruises = vGuests4;
				vPage4PArea.Parameters.mGuestsEducation = vGuests5;
				vPage4PArea.Parameters.mGuestsRecreation = vGuests6;
				vPage4PArea.Parameters.mGuestsPilgrims = vGuests7;
				vPage4PArea.Parameters.mGuestsShoping = vGuests8;
				vPage4PArea.Parameters.mGuestsPrivateOther = vGuests9;
				vPage4PArea.Parameters.mGuestsBusiness = vGuests10;
				
				pSpreadsheet.Put(vPage4PArea);
				
				// By countries
				vTotalsByCountry = vTotalsByPeriod.Select(QueryResultIteration.ByGroups, "Country");
				While vTotalsByCountry.Next() Do
					If Not ValueIsFilled(vTotalsByCountry.Country) Then
						Continue;
					EndIf;
		
					vGuests1 = 0;
					vGuests2 = 0;
					vGuests3 = 0;
					vGuests4 = 0;
					vGuests5 = 0;
					vGuests6 = 0;
					vGuests7 = 0;
					vGuests8 = 0;
					vGuests9 = 0;
					vGuests10 = 0;
					
					// By trip purpose
					vTotalsByTripType = vTotalsByCountry.Select(QueryResultIteration.ByGroups, "TripPurposeType");
					While vTotalsByTripType.Next() Do
						If vTotalsByTripType.TripPurposeType = 1 Then
							vGuests1 = vTotalsByTripType.GuestsCheckedInTurnover;
						ElsIf vTotalsByTripType.TripPurposeType = 2 Then
							vGuests2 = vTotalsByTripType.GuestsCheckedInTurnover;
						ElsIf vTotalsByTripType.TripPurposeType = 3 Then
							vGuests3 = vTotalsByTripType.GuestsCheckedInTurnover;
						ElsIf vTotalsByTripType.TripPurposeType = 4 Then
							vGuests4 = vTotalsByTripType.GuestsCheckedInTurnover;
						ElsIf vTotalsByTripType.TripPurposeType = 5 Then
							vGuests5 = vTotalsByTripType.GuestsCheckedInTurnover;
						ElsIf vTotalsByTripType.TripPurposeType = 6 Then
							vGuests6 = vTotalsByTripType.GuestsCheckedInTurnover;
						ElsIf vTotalsByTripType.TripPurposeType = 7 Then
							vGuests7 = vTotalsByTripType.GuestsCheckedInTurnover;
						ElsIf vTotalsByTripType.TripPurposeType = 8 Then
							vGuests8 = vTotalsByTripType.GuestsCheckedInTurnover;
						ElsIf vTotalsByTripType.TripPurposeType = 9 Then
							vGuests9 = vTotalsByTripType.GuestsCheckedInTurnover;
						ElsIf vTotalsByTripType.TripPurposeType = 10 Then
							vGuests10 = vTotalsByTripType.GuestsCheckedInTurnover;
						EndIf;
					EndDo;
					
					vPage4CArea.Parameters.mCountry = TrimAll(vTotalsByCountry.Country);
					vPage4CArea.Parameters.mCountryCode = TrimAll(vTotalsByCountry.Country.Code);
					
					vPage4CArea.Parameters.mGuestsTourists = vGuests1;
					vPage4CArea.Parameters.mGuestsTouristsBeach = vGuests2;
					vPage4CArea.Parameters.mGuestsTouristsCulture = vGuests3;
					vPage4CArea.Parameters.mGuestsTouristsCruises = vGuests4;
					vPage4CArea.Parameters.mGuestsEducation = vGuests5;
					vPage4CArea.Parameters.mGuestsRecreation = vGuests6;
					vPage4CArea.Parameters.mGuestsPilgrims = vGuests7;
					vPage4CArea.Parameters.mGuestsShoping = vGuests8;
					vPage4CArea.Parameters.mGuestsPrivateOther = vGuests9;
					vPage4CArea.Parameters.mGuestsBusiness = vGuests10;
					
					pSpreadsheet.Put(vPage4CArea);
				EndDo;
			EndIf;
		EndDo;
		If Not vPeriodIsFound Then
			vPage4PArea.Parameters.mGuestsTourists = vGuests1;
			vPage4PArea.Parameters.mGuestsTouristsBeach = vGuests2;
			vPage4PArea.Parameters.mGuestsTouristsCulture = vGuests3;
			vPage4PArea.Parameters.mGuestsTouristsCruises = vGuests4;
			vPage4PArea.Parameters.mGuestsEducation = vGuests5;
			vPage4PArea.Parameters.mGuestsRecreation = vGuests6;
			vPage4PArea.Parameters.mGuestsPilgrims = vGuests7;
			vPage4PArea.Parameters.mGuestsShoping = vGuests8;
			vPage4PArea.Parameters.mGuestsPrivateOther = vGuests9;
			vPage4PArea.Parameters.mGuestsBusiness = vGuests10;
			
			pSpreadsheet.Put(vPage4PArea);
		EndIf;
	EndDo;
	
	// Page 4 footer
	pSpreadsheet.Put(vPage4FArea);
	
	// Page 5
	pSpreadsheet.Put(vPage5HArea);
	
	// 5.1.1 Get total number of russian checked-in guests per trip duration
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 501
	|		WHEN GeoSales.Duration < 5
	|			THEN 502
	|		WHEN GeoSales.Duration < 8
	|			THEN 503
	|		WHEN GeoSales.Duration < 15
	|			THEN 504
	|		WHEN GeoSales.Duration < 29
	|			THEN 505
	|		WHEN GeoSales.Duration < 91
	|			THEN 506
	|		ELSE 507
	|	END AS PeriodNumber,
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 9
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qBeachRecreation
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qCulturalAndEducational
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qCruiseTourism
	|			THEN 4
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 9
	|		WHEN GeoSales.TripPurpose = &qStudy
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qOther
	|			THEN 9
	|		WHEN GeoSales.TripPurpose = &qTransit
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qRecreation
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qPilgrims
	|			THEN 7
	|		WHEN GeoSales.TripPurpose = &qShopping
	|			THEN 8
	|		ELSE 9
	|	END AS TripPurposeType,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0) AS Duration,
	|		GeoSalesTurnovers.TripPurpose AS TripPurpose,
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
	|						OR ISNULL(Client.Citizenship.Description, """") = """")) AS GeoSalesTurnovers
	|	
	|	GROUP BY
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0),
	|		GeoSalesTurnovers.TripPurpose) AS GeoSales
	|
	|GROUP BY
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 501
	|		WHEN GeoSales.Duration < 5
	|			THEN 502
	|		WHEN GeoSales.Duration < 8
	|			THEN 503
	|		WHEN GeoSales.Duration < 15
	|			THEN 504
	|		WHEN GeoSales.Duration < 29
	|			THEN 505
	|		WHEN GeoSales.Duration < 91
	|			THEN 506
	|		ELSE 507
	|	END,
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 9
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qBeachRecreation
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qCulturalAndEducational
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qCruiseTourism
	|			THEN 4
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 9
	|		WHEN GeoSales.TripPurpose = &qStudy
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qOther
	|			THEN 9
	|		WHEN GeoSales.TripPurpose = &qTransit
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qRecreation
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qPilgrims
	|			THEN 7
	|		WHEN GeoSales.TripPurpose = &qShopping
	|			THEN 8
	|		ELSE 9
	|	END
	|
	|ORDER BY
	|	PeriodNumber,
	|	TripPurposeType
	|TOTALS
	|	SUM(GuestsCheckedInTurnover)
	|BY
	|	PeriodNumber,
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
	vQry.SetParameter("qBeachRecreation", Catalogs.TripPurposes.BeachRecreation);
	vQry.SetParameter("qCulturalAndEducational", Catalogs.TripPurposes.CulturalAndEducational);
	vQry.SetParameter("qCruiseTourism", Catalogs.TripPurposes.CruiseTourism);
	vQry.SetParameter("qPrivate", Catalogs.TripPurposes.Private);
	vQry.SetParameter("qScientific", Catalogs.TripPurposes.Scientific);
	vQry.SetParameter("qStudy", Catalogs.TripPurposes.Study);
	vQry.SetParameter("qRecreation", Catalogs.TripPurposes.Recreation);
	vQry.SetParameter("qShopping", Catalogs.TripPurposes.Shopping);
	vQry.SetParameter("qPilgrims", Catalogs.TripPurposes.Pilgrims);
	vQry.SetParameter("qTransit", Catalogs.TripPurposes.Transit);
	vQry.SetParameter("qOther", Catalogs.TripPurposes.Other);
	vQry.SetParameter("qCompany", Company);
	vQryResult = vQry.Execute();
	
	vPeriodsList = New ValueList();
	vPeriodsList.Add(501, "Без ночевки - всего");
	vPeriodsList.Add(502, "1 - 4 ночевки - всего");
	vPeriodsList.Add(503, "5 - 7 ночевок - всего");
	vPeriodsList.Add(504, "8 - 14 ночевок - всего");
	vPeriodsList.Add(505, "15 - 28 ночевок - всего");
	vPeriodsList.Add(506, "29 - 90 ночевок - всего");
	vPeriodsList.Add(507, "91 и более ночевок");
	
	For Each vPeriodsListItem In vPeriodsList Do
		vPage5PArea.Parameters.mPeriodName = vPeriodsListItem.Presentation;
		vPage5PArea.Parameters.mRowNumber = vPeriodsListItem.Value;
		
		vGuests1 = 0;
		vGuests2 = 0;
		vGuests3 = 0;
		vGuests4 = 0;
		vGuests5 = 0;
		vGuests6 = 0;
		vGuests7 = 0;
		vGuests8 = 0;
		vGuests9 = 0;
		vGuests10 = 0;
		
		vPeriodIsFound = False;
		vTotalsByPeriod = vQryResult.Select(QueryResultIteration.ByGroups, "PeriodNumber");
		While vTotalsByPeriod.Next() Do
			vPeriodNumber = vTotalsByPeriod.PeriodNumber;
			If vPeriodsListItem.Value = vPeriodNumber Then
				vPeriodIsFound = True;

				// By trip purpose
				vTotalsByTripType = vTotalsByPeriod.Select(QueryResultIteration.ByGroups, "TripPurposeType");
				While vTotalsByTripType.Next() Do
					If vTotalsByTripType.TripPurposeType = 1 Then
						vGuests1 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 2 Then
						vGuests2 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 3 Then
						vGuests3 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 4 Then
						vGuests4 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 5 Then
						vGuests5 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 6 Then
						vGuests6 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 7 Then
						vGuests7 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 8 Then
						vGuests8 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 9 Then
						vGuests9 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 10 Then
						vGuests10 = vTotalsByTripType.GuestsCheckedInTurnover;
					EndIf;
				EndDo;
				
				vPage5PArea.Parameters.mGuestsTourists = vGuests1;
				vPage5PArea.Parameters.mGuestsTouristsBeach = vGuests2;
				vPage5PArea.Parameters.mGuestsTouristsCulture = vGuests3;
				vPage5PArea.Parameters.mGuestsTouristsCruises = vGuests4;
				vPage5PArea.Parameters.mGuestsEducation = vGuests5;
				vPage5PArea.Parameters.mGuestsRecreation = vGuests6;
				vPage5PArea.Parameters.mGuestsPilgrims = vGuests7;
				vPage5PArea.Parameters.mGuestsShoping = vGuests8;
				vPage5PArea.Parameters.mGuestsPrivateOther = vGuests9;
				vPage5PArea.Parameters.mGuestsBusiness = vGuests10;
				
				pSpreadsheet.Put(vPage5PArea);
			EndIf;
		EndDo;
		If Not vPeriodIsFound Then
			vPage5PArea.Parameters.mGuestsTourists = vGuests1;
			vPage5PArea.Parameters.mGuestsTouristsBeach = vGuests2;
			vPage5PArea.Parameters.mGuestsTouristsCulture = vGuests3;
			vPage5PArea.Parameters.mGuestsTouristsCruises = vGuests4;
			vPage5PArea.Parameters.mGuestsEducation = vGuests5;
			vPage5PArea.Parameters.mGuestsRecreation = vGuests6;
			vPage5PArea.Parameters.mGuestsPilgrims = vGuests7;
			vPage5PArea.Parameters.mGuestsShoping = vGuests8;
			vPage5PArea.Parameters.mGuestsPrivateOther = vGuests9;
			vPage5PArea.Parameters.mGuestsBusiness = vGuests10;
			
			pSpreadsheet.Put(vPage5PArea);
		EndIf;
	EndDo;
	
	// Page 5 footer
	pSpreadsheet.Put(vPage5FArea);
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
	vPage4HArea = vTemplate.GetArea("Page4Header");
	vPage4PArea = vTemplate.GetArea("Page4Period");
	vPage4CArea = vTemplate.GetArea("Page4Country");
	vPage4FArea = vTemplate.GetArea("Page4Footer");
	vPage5HArea = vTemplate.GetArea("Page5Header");
	vPage5PArea = vTemplate.GetArea("Page5Period");
	vPage5FArea = vTemplate.GetArea("Page5Footer");
	
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
	|	SUM(ISNULL(RoomSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover,
	|	SUM(ISNULL(RoomSales.SalesWithoutVATTurnover, 0)) AS SalesWithoutVATTurnover
	|FROM
	|	(SELECT
	|		RoomSalesTurnovers.Client AS Client,
	|		RoomSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover,
	|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
	|		RoomSalesTurnovers.SalesWithoutVATTurnover AS SalesWithoutVATTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection
	|					AND Hotel = &qHotel
	|					AND Company = &qCompany) AS RoomSalesTurnovers) AS RoomSales";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQryResult = vQry.Execute().Unload();

	vTotalGuestDays = 0;
	vTotalGuests = 0;
	vTotalSalesWithoutVAT = 0;
	vPage3Area.Parameters.mTotalGuestDays = 0;
	vPage3Area.Parameters.mTotalGuestDaysRus = 0;
	vPage3Area.Parameters.mTotalGuestDaysFor = 0;
	vPage3Area.Parameters.mTotalGuests = 0;
	vPage3Area.Parameters.mTotalSumWithoutVAT = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		If vRow.GuestDaysTurnover <> Null Then 
			vPage3Area.Parameters.mTotalGuestDays = vRow.GuestDaysTurnover;
		EndIf;
		If vRow.GuestsCheckedInTurnover <> Null Then 
			vPage3Area.Parameters.mTotalGuests = vRow.GuestsCheckedInTurnover;
		EndIf;
		If vRow.SalesWithoutVATTurnover <> Null Then 
			vPage3Area.Parameters.mTotalSumWithoutVAT = Round(vRow.SalesWithoutVATTurnover/1000, 0);
		EndIf;
		vTotalGuestDays = vRow.GuestDaysTurnover;
		vTotalGuests = vRow.GuestsCheckedInTurnover; 
		vTotalSalesWithoutVAT = vRow.SalesWithoutVATTurnover;
	EndIf;
	
	// 3.4 Get total number of checked-in guests from Russia
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SUM(ISNULL(GeoSales.GuestDaysTurnover, 0)) AS GuestDaysTurnover,
	|	SUM(ISNULL(GeoSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		GeoSalesTurnovers.Client AS Client,
	|		GeoSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
	|		GeoSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection
	|					AND Hotel = &qHotel
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
	vRussiaGuests = 0;
	vPage3Area.Parameters.mTotalGuestDaysRus = 0;
	vPage3Area.Parameters.mTotalGuestsRus = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vPage3Area.Parameters.mTotalGuestDaysRus = vRow.GuestDaysTurnover;
		vPage3Area.Parameters.mTotalGuestsRus = vRow.GuestsCheckedInTurnover;
		vRussiaGuestDays = vRow.GuestDaysTurnover;
		vRussiaGuests = vRow.GuestsCheckedInTurnover;
	EndIf;
	
	// 3.5 Get total number of guest days and checked-in foreigner guests
	If vTotalGuestDays <> Null And vRussiaGuestDays <> Null Then
		vPage3Area.Parameters.mTotalGuestDaysFor = vTotalGuestDays - vRussiaGuestDays;
	Else
		vPage3Area.Parameters.mTotalGuestDaysFor = 0;
	EndIf;
	If vTotalGuests <> Null And vRussiaGuests <> Null Then
		vPage3Area.Parameters.mTotalGuestsFor = vTotalGuests - vRussiaGuests;
	Else
		vPage3Area.Parameters.mTotalGuestsFor = 0;
	EndIf;
	
	// 3.6 Get total number of checked-in guests with tour tickets
	vPage3Area.Parameters.mTotalTourTicketGuests = 0;
	If ValueIsFilled(TourTicketIncomeServiceGroup) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	SUM(ISNULL(RoomSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover
		|FROM
		|	(SELECT
		|		RoomSalesTurnovers.Client AS Client,
		|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover
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

		vTotalTourTicketGuests = 0;
		If vQryResult.Count() > 0 Then
			vRow = vQryResult.Get(0);
			vPage3Area.Parameters.mTotalTourTicketGuests = vRow.GuestsCheckedInTurnover;
			vTotalTourTicketGuests = vRow.GuestsCheckedInTurnover;
		EndIf;
		
		// The same from russia
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	SUM(ISNULL(RoomSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover
		|FROM
		|	(SELECT
		|		RoomSalesTurnovers.Client AS Client,
		|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover
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
			
			vPage3Area.Parameters.mTotalTourTicketGuestsFor = vTotalTourTicketGuests - vRow.GuestsCheckedInTurnover;
		Else
			vPage3Area.Parameters.mTotalTourTicketGuestsRus = 0;
			
			vPage3Area.Parameters.mTotalTourTicketGuestsFor = vTotalTourTicketGuests;
		EndIf;
	EndIf;
	
	pSpreadsheet.Put(vPage3Area);
	
	pSpreadsheet.PutHorizontalPageBreak();
	
	// Page 4
	pSpreadsheet.Put(vPage4HArea);
	
	// 4.1.1 Get total number of foreign checked-in guests per trip duration
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 401
	|		WHEN GeoSales.Duration < 5
	|			THEN 402
	|		WHEN GeoSales.Duration < 8
	|			THEN 403
	|		WHEN GeoSales.Duration < 15
	|			THEN 404
	|		WHEN GeoSales.Duration < 29
	|			THEN 405
	|		WHEN GeoSales.Duration < 91
	|			THEN 406
	|		ELSE 407
	|	END AS PeriodNumber,
	|	GeoSales.Country AS Country,
	|	ISNULL(GeoSales.Country.Code, """") AS CountryCode,
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 9
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qBeachRecreation
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qCulturalAndEducational
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qCruiseTourism
	|			THEN 4
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 9
	|		WHEN GeoSales.TripPurpose = &qStudy
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qOther
	|			THEN 9
	|		WHEN GeoSales.TripPurpose = &qTransit
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qRecreation
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qPilgrims
	|			THEN 7
	|		WHEN GeoSales.TripPurpose = &qShopping
	|			THEN 8
	|		ELSE 9
	|	END AS TripPurposeType,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0) AS Duration,
	|		GeoSalesTurnovers.Client.Citizenship AS Country,
	|		GeoSalesTurnovers.TripPurpose AS TripPurpose,
	|		SUM(GeoSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection
	|					AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND (Client.Citizenship <> &qRussia
	|						AND ISNULL(Client.Citizenship.Description, """") <> """")) AS GeoSalesTurnovers
	|	
	|	GROUP BY
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0),
	|		GeoSalesTurnovers.Client.Citizenship,
	|		GeoSalesTurnovers.TripPurpose) AS GeoSales
	|
	|GROUP BY
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 401
	|		WHEN GeoSales.Duration < 5
	|			THEN 402
	|		WHEN GeoSales.Duration < 8
	|			THEN 403
	|		WHEN GeoSales.Duration < 15
	|			THEN 404
	|		WHEN GeoSales.Duration < 29
	|			THEN 405
	|		WHEN GeoSales.Duration < 91
	|			THEN 406
	|		ELSE 407
	|	END,
	|	GeoSales.Country,
	|	ISNULL(GeoSales.Country.Code, """"),
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 9
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qBeachRecreation
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qCulturalAndEducational
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qCruiseTourism
	|			THEN 4
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 9
	|		WHEN GeoSales.TripPurpose = &qStudy
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qOther
	|			THEN 9
	|		WHEN GeoSales.TripPurpose = &qTransit
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qRecreation
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qPilgrims
	|			THEN 7
	|		WHEN GeoSales.TripPurpose = &qShopping
	|			THEN 8
	|		ELSE 9
	|	END
	|
	|ORDER BY
	|	PeriodNumber,
	|	CountryCode,
	|	TripPurposeType
	|TOTALS
	|	SUM(GuestsCheckedInTurnover)
	|BY
	|	PeriodNumber,
	|	Country,
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
	vQry.SetParameter("qBeachRecreation", Catalogs.TripPurposes.BeachRecreation);
	vQry.SetParameter("qCulturalAndEducational", Catalogs.TripPurposes.CulturalAndEducational);
	vQry.SetParameter("qCruiseTourism", Catalogs.TripPurposes.CruiseTourism);
	vQry.SetParameter("qPrivate", Catalogs.TripPurposes.Private);
	vQry.SetParameter("qScientific", Catalogs.TripPurposes.Scientific);
	vQry.SetParameter("qStudy", Catalogs.TripPurposes.Study);
	vQry.SetParameter("qRecreation", Catalogs.TripPurposes.Recreation);
	vQry.SetParameter("qShopping", Catalogs.TripPurposes.Shopping);
	vQry.SetParameter("qPilgrims", Catalogs.TripPurposes.Pilgrims);
	vQry.SetParameter("qTransit", Catalogs.TripPurposes.Transit);
	vQry.SetParameter("qOther", Catalogs.TripPurposes.Other);
	vQry.SetParameter("qCompany", Company);
	vQryResult = vQry.Execute();
	
	vPeriodsList = New ValueList();
	vPeriodsList.Add(401, "Без ночевки - всего");
	vPeriodsList.Add(402, "1 - 4 ночевки - всего");
	vPeriodsList.Add(403, "5 - 7 ночевок - всего");
	vPeriodsList.Add(404, "8 - 14 ночевок - всего");
	vPeriodsList.Add(405, "15 - 28 ночевок - всего");
	vPeriodsList.Add(406, "29 - 90 ночевок - всего");
	vPeriodsList.Add(407, "91 и более ночевок");
	
	For Each vPeriodsListItem In vPeriodsList Do
		vPage4PArea.Parameters.mPeriodName = vPeriodsListItem.Presentation;
		vPage4PArea.Parameters.mRowNumber = vPeriodsListItem.Value;
		
		vGuests1 = 0;
		vGuests2 = 0;
		vGuests3 = 0;
		vGuests4 = 0;
		vGuests5 = 0;
		vGuests6 = 0;
		vGuests7 = 0;
		vGuests8 = 0;
		vGuests9 = 0;
		vGuests10 = 0;
		
		vPeriodIsFound = False;
		vTotalsByPeriod = vQryResult.Select(QueryResultIteration.ByGroups, "PeriodNumber");
		While vTotalsByPeriod.Next() Do
			vPeriodNumber = vTotalsByPeriod.PeriodNumber;
			If vPeriodsListItem.Value = vPeriodNumber Then
				vPeriodIsFound = True;
				
				// By trip purpose
				vTotalsByTripType = vTotalsByPeriod.Select(QueryResultIteration.ByGroups, "TripPurposeType");
				While vTotalsByTripType.Next() Do
					If vTotalsByTripType.TripPurposeType = 1 Then
						vGuests1 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 2 Then
						vGuests2 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 3 Then
						vGuests3 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 4 Then
						vGuests4 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 5 Then
						vGuests5 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 6 Then
						vGuests6 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 7 Then
						vGuests7 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 8 Then
						vGuests8 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 9 Then
						vGuests9 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 10 Then
						vGuests10 = vTotalsByTripType.GuestsCheckedInTurnover;
					EndIf;
				EndDo;
				
				vPage4PArea.Parameters.mGuestsTourists = vGuests1;
				vPage4PArea.Parameters.mGuestsTouristsBeach = vGuests2;
				vPage4PArea.Parameters.mGuestsTouristsCulture = vGuests3;
				vPage4PArea.Parameters.mGuestsTouristsCruises = vGuests4;
				vPage4PArea.Parameters.mGuestsEducation = vGuests5;
				vPage4PArea.Parameters.mGuestsRecreation = vGuests6;
				vPage4PArea.Parameters.mGuestsPilgrims = vGuests7;
				vPage4PArea.Parameters.mGuestsShoping = vGuests8;
				vPage4PArea.Parameters.mGuestsPrivateOther = vGuests9;
				vPage4PArea.Parameters.mGuestsBusiness = vGuests10;
				
				pSpreadsheet.Put(vPage4PArea);
				
				// By countries
				vTotalsByCountry = vTotalsByPeriod.Select(QueryResultIteration.ByGroups, "Country");
				While vTotalsByCountry.Next() Do
					If Not ValueIsFilled(vTotalsByCountry.Country) Then
						Continue;
					EndIf;
		
					vGuests1 = 0;
					vGuests2 = 0;
					vGuests3 = 0;
					vGuests4 = 0;
					vGuests5 = 0;
					vGuests6 = 0;
					vGuests7 = 0;
					vGuests8 = 0;
					vGuests9 = 0;
					vGuests10 = 0;
					
					// By trip purpose
					vTotalsByTripType = vTotalsByCountry.Select(QueryResultIteration.ByGroups, "TripPurposeType");
					While vTotalsByTripType.Next() Do
						If vTotalsByTripType.TripPurposeType = 1 Then
							vGuests1 = vTotalsByTripType.GuestsCheckedInTurnover;
						ElsIf vTotalsByTripType.TripPurposeType = 2 Then
							vGuests2 = vTotalsByTripType.GuestsCheckedInTurnover;
						ElsIf vTotalsByTripType.TripPurposeType = 3 Then
							vGuests3 = vTotalsByTripType.GuestsCheckedInTurnover;
						ElsIf vTotalsByTripType.TripPurposeType = 4 Then
							vGuests4 = vTotalsByTripType.GuestsCheckedInTurnover;
						ElsIf vTotalsByTripType.TripPurposeType = 5 Then
							vGuests5 = vTotalsByTripType.GuestsCheckedInTurnover;
						ElsIf vTotalsByTripType.TripPurposeType = 6 Then
							vGuests6 = vTotalsByTripType.GuestsCheckedInTurnover;
						ElsIf vTotalsByTripType.TripPurposeType = 7 Then
							vGuests7 = vTotalsByTripType.GuestsCheckedInTurnover;
						ElsIf vTotalsByTripType.TripPurposeType = 8 Then
							vGuests8 = vTotalsByTripType.GuestsCheckedInTurnover;
						ElsIf vTotalsByTripType.TripPurposeType = 9 Then
							vGuests9 = vTotalsByTripType.GuestsCheckedInTurnover;
						ElsIf vTotalsByTripType.TripPurposeType = 10 Then
							vGuests10 = vTotalsByTripType.GuestsCheckedInTurnover;
						EndIf;
					EndDo;
					
					vPage4CArea.Parameters.mCountry = TrimAll(vTotalsByCountry.Country);
					vPage4CArea.Parameters.mCountryCode = TrimAll(vTotalsByCountry.Country.Code);
					
					vPage4CArea.Parameters.mGuestsTourists = vGuests1;
					vPage4CArea.Parameters.mGuestsTouristsBeach = vGuests2;
					vPage4CArea.Parameters.mGuestsTouristsCulture = vGuests3;
					vPage4CArea.Parameters.mGuestsTouristsCruises = vGuests4;
					vPage4CArea.Parameters.mGuestsEducation = vGuests5;
					vPage4CArea.Parameters.mGuestsRecreation = vGuests6;
					vPage4CArea.Parameters.mGuestsPilgrims = vGuests7;
					vPage4CArea.Parameters.mGuestsShoping = vGuests8;
					vPage4CArea.Parameters.mGuestsPrivateOther = vGuests9;
					vPage4CArea.Parameters.mGuestsBusiness = vGuests10;
					
					pSpreadsheet.Put(vPage4CArea);
				EndDo;
			EndIf;
		EndDo;
		If Not vPeriodIsFound Then
			vPage4PArea.Parameters.mGuestsTourists = vGuests1;
			vPage4PArea.Parameters.mGuestsTouristsBeach = vGuests2;
			vPage4PArea.Parameters.mGuestsTouristsCulture = vGuests3;
			vPage4PArea.Parameters.mGuestsTouristsCruises = vGuests4;
			vPage4PArea.Parameters.mGuestsEducation = vGuests5;
			vPage4PArea.Parameters.mGuestsRecreation = vGuests6;
			vPage4PArea.Parameters.mGuestsPilgrims = vGuests7;
			vPage4PArea.Parameters.mGuestsShoping = vGuests8;
			vPage4PArea.Parameters.mGuestsPrivateOther = vGuests9;
			vPage4PArea.Parameters.mGuestsBusiness = vGuests10;
			
			pSpreadsheet.Put(vPage4PArea);
		EndIf;
	EndDo;
	
	// Page 4 footer
	pSpreadsheet.Put(vPage4FArea);
	
	// Page 5
	pSpreadsheet.Put(vPage5HArea);
	
	// 5.1.1 Get total number of russian checked-in guests per trip duration
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 501
	|		WHEN GeoSales.Duration < 5
	|			THEN 502
	|		WHEN GeoSales.Duration < 8
	|			THEN 503
	|		WHEN GeoSales.Duration < 15
	|			THEN 504
	|		WHEN GeoSales.Duration < 29
	|			THEN 505
	|		WHEN GeoSales.Duration < 91
	|			THEN 506
	|		ELSE 507
	|	END AS PeriodNumber,
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 9
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qBeachRecreation
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qCulturalAndEducational
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qCruiseTourism
	|			THEN 4
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 9
	|		WHEN GeoSales.TripPurpose = &qStudy
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qOther
	|			THEN 9
	|		WHEN GeoSales.TripPurpose = &qTransit
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qRecreation
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qPilgrims
	|			THEN 7
	|		WHEN GeoSales.TripPurpose = &qShopping
	|			THEN 8
	|		ELSE 9
	|	END AS TripPurposeType,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0) AS Duration,
	|		GeoSalesTurnovers.TripPurpose AS TripPurpose,
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
	|						OR ISNULL(Client.Citizenship.Description, """") = """")) AS GeoSalesTurnovers
	|	
	|	GROUP BY
	|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0),
	|		GeoSalesTurnovers.TripPurpose) AS GeoSales
	|
	|GROUP BY
	|	CASE
	|		WHEN GeoSales.Duration = 0
	|			THEN 501
	|		WHEN GeoSales.Duration < 5
	|			THEN 502
	|		WHEN GeoSales.Duration < 8
	|			THEN 503
	|		WHEN GeoSales.Duration < 15
	|			THEN 504
	|		WHEN GeoSales.Duration < 29
	|			THEN 505
	|		WHEN GeoSales.Duration < 91
	|			THEN 506
	|		ELSE 507
	|	END,
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qScientific
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 10
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 9
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qBeachRecreation
	|			THEN 2
	|		WHEN GeoSales.TripPurpose = &qCulturalAndEducational
	|			THEN 3
	|		WHEN GeoSales.TripPurpose = &qCruiseTourism
	|			THEN 4
	|		WHEN GeoSales.TripPurpose = &qPrivate
	|			THEN 9
	|		WHEN GeoSales.TripPurpose = &qStudy
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qOther
	|			THEN 9
	|		WHEN GeoSales.TripPurpose = &qTransit
	|			THEN 1
	|		WHEN GeoSales.TripPurpose = &qRecreation
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qPilgrims
	|			THEN 7
	|		WHEN GeoSales.TripPurpose = &qShopping
	|			THEN 8
	|		ELSE 9
	|	END
	|
	|ORDER BY
	|	PeriodNumber,
	|	TripPurposeType
	|TOTALS
	|	SUM(GuestsCheckedInTurnover)
	|BY
	|	PeriodNumber,
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
	vQry.SetParameter("qBeachRecreation", Catalogs.TripPurposes.BeachRecreation);
	vQry.SetParameter("qCulturalAndEducational", Catalogs.TripPurposes.CulturalAndEducational);
	vQry.SetParameter("qCruiseTourism", Catalogs.TripPurposes.CruiseTourism);
	vQry.SetParameter("qPrivate", Catalogs.TripPurposes.Private);
	vQry.SetParameter("qScientific", Catalogs.TripPurposes.Scientific);
	vQry.SetParameter("qStudy", Catalogs.TripPurposes.Study);
	vQry.SetParameter("qRecreation", Catalogs.TripPurposes.Recreation);
	vQry.SetParameter("qShopping", Catalogs.TripPurposes.Shopping);
	vQry.SetParameter("qPilgrims", Catalogs.TripPurposes.Pilgrims);
	vQry.SetParameter("qTransit", Catalogs.TripPurposes.Transit);
	vQry.SetParameter("qOther", Catalogs.TripPurposes.Other);
	vQry.SetParameter("qCompany", Company);
	vQryResult = vQry.Execute();
	
	vPeriodsList = New ValueList();
	vPeriodsList.Add(501, "Без ночевки - всего");
	vPeriodsList.Add(502, "1 - 4 ночевки - всего");
	vPeriodsList.Add(503, "5 - 7 ночевок - всего");
	vPeriodsList.Add(504, "8 - 14 ночевок - всего");
	vPeriodsList.Add(505, "15 - 28 ночевок - всего");
	vPeriodsList.Add(506, "29 - 90 ночевок - всего");
	vPeriodsList.Add(507, "91 и более ночевок");
	
	For Each vPeriodsListItem In vPeriodsList Do
		vPage5PArea.Parameters.mPeriodName = vPeriodsListItem.Presentation;
		vPage5PArea.Parameters.mRowNumber = vPeriodsListItem.Value;
		
		vGuests1 = 0;
		vGuests2 = 0;
		vGuests3 = 0;
		vGuests4 = 0;
		vGuests5 = 0;
		vGuests6 = 0;
		vGuests7 = 0;
		vGuests8 = 0;
		vGuests9 = 0;
		vGuests10 = 0;
		
		vPeriodIsFound = False;
		vTotalsByPeriod = vQryResult.Select(QueryResultIteration.ByGroups, "PeriodNumber");
		While vTotalsByPeriod.Next() Do
			vPeriodNumber = vTotalsByPeriod.PeriodNumber;
			If vPeriodsListItem.Value = vPeriodNumber Then
				vPeriodIsFound = True;
				
				// By trip purpose
				vTotalsByTripType = vTotalsByPeriod.Select(QueryResultIteration.ByGroups, "TripPurposeType");
				While vTotalsByTripType.Next() Do
					If vTotalsByTripType.TripPurposeType = 1 Then
						vGuests1 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 2 Then
						vGuests2 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 3 Then
						vGuests3 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 4 Then
						vGuests4 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 5 Then
						vGuests5 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 6 Then
						vGuests6 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 7 Then
						vGuests7 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 8 Then
						vGuests8 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 9 Then
						vGuests9 = vTotalsByTripType.GuestsCheckedInTurnover;
					ElsIf vTotalsByTripType.TripPurposeType = 10 Then
						vGuests10 = vTotalsByTripType.GuestsCheckedInTurnover;
					EndIf;
				EndDo;
				
				vPage5PArea.Parameters.mGuestsTourists = vGuests1;
				vPage5PArea.Parameters.mGuestsTouristsBeach = vGuests2;
				vPage5PArea.Parameters.mGuestsTouristsCulture = vGuests3;
				vPage5PArea.Parameters.mGuestsTouristsCruises = vGuests4;
				vPage5PArea.Parameters.mGuestsEducation = vGuests5;
				vPage5PArea.Parameters.mGuestsRecreation = vGuests6;
				vPage5PArea.Parameters.mGuestsPilgrims = vGuests7;
				vPage5PArea.Parameters.mGuestsShoping = vGuests8;
				vPage5PArea.Parameters.mGuestsPrivateOther = vGuests9;
				vPage5PArea.Parameters.mGuestsBusiness = vGuests10;
				
				pSpreadsheet.Put(vPage5PArea);
			EndIf;
		EndDo;
		If Not vPeriodIsFound Then
			vPage5PArea.Parameters.mGuestsTourists = vGuests1;
			vPage5PArea.Parameters.mGuestsTouristsBeach = vGuests2;
			vPage5PArea.Parameters.mGuestsTouristsCulture = vGuests3;
			vPage5PArea.Parameters.mGuestsTouristsCruises = vGuests4;
			vPage5PArea.Parameters.mGuestsEducation = vGuests5;
			vPage5PArea.Parameters.mGuestsRecreation = vGuests6;
			vPage5PArea.Parameters.mGuestsPilgrims = vGuests7;
			vPage5PArea.Parameters.mGuestsShoping = vGuests8;
			vPage5PArea.Parameters.mGuestsPrivateOther = vGuests9;
			vPage5PArea.Parameters.mGuestsBusiness = vGuests10;
			
			pSpreadsheet.Put(vPage5PArea);
		EndIf;
	EndDo;
	
	// Page 5 footer
	pSpreadsheet.Put(vPage5FArea);
EndProcedure // pmGenerate2023
