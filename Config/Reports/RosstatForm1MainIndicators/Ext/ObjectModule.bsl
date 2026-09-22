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
	If Not ValueIsFilled(PeriodFrom) Then
		PeriodFrom = AddMonth(BegOfMonth(CurrentSessionDate()), - 1);
		PeriodTo = EndOfMonth(PeriodFrom);
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
	If PeriodTo < '20230101' Then
		pmGenerate2022(pSpreadsheet);
	ElsIf PeriodTo < '20240101' Then
		pmGenerate2023(pSpreadsheet);
	ElsIf PeriodTo < '20260101' Then
		pmGenerate2024(pSpreadsheet);
	Else
		pmGenerate2026(pSpreadsheet);
	EndIf;
EndProcedure // pmGenerate

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
	vPage3FArea = vTemplate.GetArea("Page3Footer");
	
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
	|					OR RoomType.Company = &qEmptyCompany) 
	|				AND (Room IN HIERARCHY (&qRoomParent)  
	|					OR &qEmptyRoomParent)
	|				AND (RoomType IN HIERARCHY (&qRoomTypeParent)  
	|					OR &qEmptyRoomTypeParent)
	|	) AS RoomInventoryBalance";
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyCompany", Catalogs.Companies.EmptyRef());
	vQry.SetParameter("qRoomParent", RoomParent);
	vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
	vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
	vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
	vQryResult = vQry.Execute().Unload();

	vPage3Area.Parameters.mTotalRooms = 0;
	vPage3Area.Parameters.mTotalBeds = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vPage3Area.Parameters.mTotalRooms = vRow.TotalRoomsBalance;
		vPage3Area.Parameters.mTotalBeds = vRow.TotalBedsBalance;
	EndIf;
	
	// 3.2 Get total number of guest days and number of checked in guests
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SUM(ISNULL(RoomSales.GuestDaysTurnover, 0)) AS GuestDaysTurnover,
	|	SUM(ISNULL(RoomSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover,
	|	SUM(ISNULL(RoomSales.SalesWithoutVATTurnover, 0)) AS SalesWithoutVATTurnover,
	|	SUM(ISNULL(RoomSales.RoomRevenueWithoutVATTurnover, 0)) AS RoomRevenueWithoutVATTurnover
	|FROM
	|	(SELECT
	|		RoomSalesTurnovers.Client AS Client,
	|		RoomSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover,
	|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
	|		RoomSalesTurnovers.SalesWithoutVATTurnover AS SalesWithoutVATTurnover,
	|		RoomSalesTurnovers.RoomRevenueWithoutVATTurnover AS RoomRevenueWithoutVATTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection
	|					AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND (Room IN HIERARCHY (&qRoomParent)  
	|						OR &qEmptyRoomParent)
	|					AND (RoomType IN HIERARCHY (&qRoomTypeParent)  
	|						OR &qEmptyRoomTypeParent)
	|		) AS RoomSalesTurnovers) AS RoomSales";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qRoomParent", RoomParent);
	vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
	vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
	vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
	vQryResult = vQry.Execute().Unload();

	vTotalGuestDays = 0;
	vTotalGuests = 0;
	vTotalSalesWithoutVAT = 0;
	vTotalRoomRevenueWithoutVAT = 0;
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
		vTotalRoomRevenueWithoutVAT = vRow.RoomRevenueWithoutVATTurnover;
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
	|					AND (Room IN HIERARCHY (&qRoomParent)  
	|						OR &qEmptyRoomParent)
	|					AND (RoomType IN HIERARCHY (&qRoomTypeParent)  
	|						OR &qEmptyRoomTypeParent)
	|					AND (Client.Citizenship = &qRussia
	|						OR ISNULL(Client.Citizenship.Description, """") = """")) AS GeoSalesTurnovers) AS GeoSales";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qRoomParent", RoomParent);
	vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
	vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
	vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
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
	
	pSpreadsheet.Put(vPage3Area);

	// Page 3 footer
	pSpreadsheet.Put(vPage3FArea);
EndProcedure // pmGenerate2022

// -----------------------------------------------------------------------------
Procedure pmGenerate2023(pSpreadsheet) Export;
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
	vPage4TArea = vTemplate.GetArea("Page4Total");
	vPage4FArea = vTemplate.GetArea("Page4Footer");
	vPage5HArea = vTemplate.GetArea("Page5Header");
	vPage5PArea = vTemplate.GetArea("Page5Period");
	vPage5FArea = vTemplate.GetArea("Page5Footer");
	vPage5TArea = vTemplate.GetArea("Page5Total");
	vReportFArea = vTemplate.GetArea("ReportFooter");
	
	// Page 1
	vPage1Area.Parameters.mPeriodStr = PeriodPresentation(BegOfDay(PeriodFrom), EndOfDay(PeriodTo), cmLocalizationCode());
	vPage1Area.Parameters.mHotelName = TrimAll(Hotel.LegacyName);
	vPage1Area.Parameters.mHotelPostAddress = cmGetAddressPresentation(Hotel.PostAddress);
	vPage1Area.Parameters.mCompanyName = TrimAll(Company.LegacyName);
	//vPage1Area.Parameters.mCompanyPostAddress = cmGetAddressPresentation(Company.PostAddress);
	vPage1Area.Parameters.mCompanyPostAddress = Company.AccountantEmail;
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
	|					OR RoomType.Company = &qEmptyCompany)
	|				AND (Room IN HIERARCHY (&qRoomParent)  
	|					OR &qEmptyRoomParent)
	|				AND (RoomType IN HIERARCHY (&qRoomTypeParent)  
	|					OR &qEmptyRoomTypeParent)
	|	) AS RoomInventoryBalance";
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyCompany", Catalogs.Companies.EmptyRef());
	vQry.SetParameter("qRoomParent", RoomParent);
	vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
	vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
	vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
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
		|					OR RoomType.Company = &qEmptyCompany)
		|				AND (Room IN HIERARCHY (&qRoomParent)  
		|					OR &qEmptyRoomParent)
		|				AND (RoomType IN HIERARCHY (&qRoomTypeParent)  
		|					OR &qEmptyRoomTypeParent)
		|	) AS RoomInventoryBalance";
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qCompany", Company);
		vQry.SetParameter("qEmptyCompany", Catalogs.Companies.EmptyRef());
		vQry.SetParameter("qTopRoomTypes", TopRoomTypes);
		vQry.SetParameter("qRoomParent", RoomParent);
		vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
		vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
		vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
		vQryResult = vQry.Execute().Unload();

		If vQryResult.Count() > 0 Then
			vRow = vQryResult.Get(0);
			vPage3Area.Parameters.mTotalTopRooms = vRow.TotalRoomsBalance;
		EndIf;
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
	|					AND Company = &qCompany
	|				AND (Room IN HIERARCHY (&qRoomParent)  
	|					OR &qEmptyRoomParent)
	|				AND (RoomType IN HIERARCHY (&qRoomTypeParent)  
	|					OR &qEmptyRoomTypeParent)
	|	) AS RoomSalesTurnovers) AS RoomSales";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qRoomParent", RoomParent);
	vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
	vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
	vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
	vQryResult = vQry.Execute().Unload();

	vPage3Area.Parameters.mTotalGuestDays = 0;
	vPage3Area.Parameters.mTotalGuestDaysRus = 0;
	vPage3Area.Parameters.mTotalGuestDaysFor = 0;
	vPage3Area.Parameters.mTotalGuests = 0;
	vPage3Area.Parameters.mTotalGuestsRus = 0;
	vPage3Area.Parameters.mTotalGuestsFor = 0;
	vPage3Area.Parameters.mTotalGuestsCheckedIn = 0;
	vPage3Area.Parameters.mTotalGuestsCheckedInRus = 0;
	vPage3Area.Parameters.mTotalGuestsCheckedInFor = 0;
	vPage3Area.Parameters.mTotalSumWithoutVAT = 0;

	vTotalGuestDays = 0;
	vTotalGuestsCheckedIn = 0;
	vTotalSalesWithoutVAT = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		If vRow.GuestDaysTurnover <> Null Then 
			vPage3Area.Parameters.mTotalGuestDays = vRow.GuestDaysTurnover;
		EndIf;
		If vRow.GuestsCheckedInTurnover <> Null Then 
			vPage3Area.Parameters.mTotalGuestsCheckedIn = vRow.GuestsCheckedInTurnover;
		EndIf;
		If vRow.SalesWithoutVATTurnover <> Null Then 
			vPage3Area.Parameters.mTotalSumWithoutVAT = Round(vRow.SalesWithoutVATTurnover/1000, 0);
		EndIf;
		vTotalGuestDays = vRow.GuestDaysTurnover;
		vTotalGuestsCheckedIn = vRow.GuestsCheckedInTurnover; 
		vTotalSalesWithoutVAT = vRow.SalesWithoutVATTurnover;
	EndIf;

	vTotalGuests = vTotalGuestsCheckedIn;
	vPage3Area.Parameters.mTotalGuests = vTotalGuestsCheckedIn;
	
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
	|					AND (Room IN HIERARCHY (&qRoomParent)  
	|						OR &qEmptyRoomParent)
	|					AND (RoomType IN HIERARCHY (&qRoomTypeParent)  
	|						OR &qEmptyRoomTypeParent)
	|					AND (Client.Citizenship = &qRussia
	|						OR ISNULL(Client.Citizenship.Description, """") = """")) AS GeoSalesTurnovers) AS GeoSales";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qRoomParent", RoomParent);
	vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
	vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
	vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
	vQryResult = vQry.Execute().Unload();

	vRussiaGuestDays = 0;
	vRussiaGuestsCheckedIn = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vPage3Area.Parameters.mTotalGuestDaysRus = vRow.GuestDaysTurnover;
		vPage3Area.Parameters.mTotalGuestsCheckedInRus = vRow.GuestsCheckedInTurnover;
		vRussiaGuestDays = vRow.GuestDaysTurnover;
		vRussiaGuestsCheckedIn = vRow.GuestsCheckedInTurnover;
	EndIf;

	vRussiaGuests = vRussiaGuestsCheckedIn;
	vPage3Area.Parameters.mTotalGuestsRus = vRussiaGuestsCheckedIn;
	
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
	If vTotalGuestsCheckedIn <> Null And vRussiaGuestsCheckedIn <> Null Then
		vPage3Area.Parameters.mTotalGuestsCheckedInFor = vTotalGuestsCheckedIn - vRussiaGuestsCheckedIn;
	Else
		vPage3Area.Parameters.mTotalGuestsCheckedInFor = 0;
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
		|					AND (Room IN HIERARCHY (&qRoomParent)  
		|						OR &qEmptyRoomParent)
		|					AND (RoomType IN HIERARCHY (&qRoomTypeParent)  
		|						OR &qEmptyRoomTypeParent)
		|					AND (Service IN HIERARCHY (&qTourTicketServices)
		|						OR NOT &qUseServicesList)
		|					) AS RoomSalesTurnovers) AS RoomSales";
		vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qCompany", Company);
		vQry.SetParameter("qRoomParent", RoomParent);
		vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
		vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
		vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
		vUseServicesList = False;
		vServicesList = New ValueList();
		If Not TourTicketIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(TourTicketIncomeServiceGroup);
		EndIf;
		vQry.SetParameter("qUseServicesList", vUseServicesList);
		vQry.SetParameter("qTourTicketServices", vServicesList);
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
		|					AND (Room IN HIERARCHY (&qRoomParent)  
		|						OR &qEmptyRoomParent)
		|					AND (RoomType IN HIERARCHY (&qRoomTypeParent)  
		|						OR &qEmptyRoomTypeParent)
		|					AND (Service IN HIERARCHY (&qTourTicketServices)
		|						OR NOT &qUseServicesList)
		|					AND (Client.Citizenship = &qRussia
		|						OR ISNULL(Client.Citizenship.Description, """") = """")) AS RoomSalesTurnovers) AS RoomSales";
		vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qRussia", RussiaCountry);
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qCompany", Company);
		vQry.SetParameter("qRoomParent", RoomParent);
		vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
		vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
		vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
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
			vPage3Area.Parameters.mTotalTourTicketGuestsRus = vRow.GuestsCheckedInTurnover;
			
			vPage3Area.Parameters.mTotalTourTicketGuestsFor = vTotalTourTicketGuests - vRow.GuestsCheckedInTurnover;
		Else
			vPage3Area.Parameters.mTotalTourTicketGuestsRus = 0;
			
			vPage3Area.Parameters.mTotalTourTicketGuestsFor = vTotalTourTicketGuests;
		EndIf;
	EndIf;
	
	pSpreadsheet.Put(vPage3Area);

	// Print page 4 and 5 for end of quarters only	
	If Month(PeriodTo) = 3 Or Month(PeriodTo) = 6 Or Month(PeriodTo) = 9 Or Month(PeriodTo) = 12 Then
		
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
		|		ELSE 406
		|	END AS PeriodNumber,
		|	GeoSales.Country AS Country,
		|	ISNULL(GeoSales.Country.Code, """") AS CountryCode,
		|	CASE
		|		WHEN GeoSales.TripPurpose = &qBusiness
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qCommerce
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qOfficial
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qWork
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qScientific
		|			THEN 2
		|		WHEN GeoSales.TripPurpose = &qCrewman
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qHumanitarian
		|			THEN 6
		|		WHEN GeoSales.TripPurpose = &qTourism
		|			THEN 1
		|		WHEN GeoSales.TripPurpose = &qBeachRecreation
		|			THEN 2
		|		WHEN GeoSales.TripPurpose = &qCulturalAndEducational
		|			THEN 3
		|		WHEN GeoSales.TripPurpose = &qCruiseTourism
		|			THEN 4
		|		WHEN GeoSales.TripPurpose = &qPrivate
		|			THEN 6
		|		WHEN GeoSales.TripPurpose = &qStudy
		|			THEN 2
		|		WHEN GeoSales.TripPurpose = &qRecreation
		|			THEN 3
		|		WHEN GeoSales.TripPurpose = &qShopping
		|			THEN 5
		|		WHEN GeoSales.TripPurpose = &qPilgrims
		|			THEN 4
		|		WHEN GeoSales.TripPurpose = &qTransit
		|			THEN 1
		|		WHEN GeoSales.TripPurpose = &qOther
		|			THEN 6
		|		ELSE 6
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
		|					AND (Room IN HIERARCHY (&qRoomParent)  
		|						OR &qEmptyRoomParent)
		|					AND (RoomType IN HIERARCHY (&qRoomTypeParent)  
		|						OR &qEmptyRoomTypeParent)
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
		|		ELSE 406
		|	END,
		|	GeoSales.Country,
		|	ISNULL(GeoSales.Country.Code, """"),
		|	CASE
		|		WHEN GeoSales.TripPurpose = &qBusiness
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qCommerce
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qOfficial
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qWork
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qScientific
		|			THEN 2
		|		WHEN GeoSales.TripPurpose = &qCrewman
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qHumanitarian
		|			THEN 6
		|		WHEN GeoSales.TripPurpose = &qTourism
		|			THEN 1
		|		WHEN GeoSales.TripPurpose = &qBeachRecreation
		|			THEN 2
		|		WHEN GeoSales.TripPurpose = &qCulturalAndEducational
		|			THEN 3
		|		WHEN GeoSales.TripPurpose = &qCruiseTourism
		|			THEN 4
		|		WHEN GeoSales.TripPurpose = &qPrivate
		|			THEN 6
		|		WHEN GeoSales.TripPurpose = &qStudy
		|			THEN 2
		|		WHEN GeoSales.TripPurpose = &qRecreation
		|			THEN 3
		|		WHEN GeoSales.TripPurpose = &qShopping
		|			THEN 5
		|		WHEN GeoSales.TripPurpose = &qPilgrims
		|			THEN 4
		|		WHEN GeoSales.TripPurpose = &qTransit
		|			THEN 1
		|		WHEN GeoSales.TripPurpose = &qOther
		|			THEN 6
		|		ELSE 6
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
		vQry.SetParameter("qPeriodFrom", BegOfQuarter(PeriodFrom));
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
		vQry.SetParameter("qRoomParent", RoomParent);
		vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
		vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
		vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
		vQryResult = vQry.Execute();
		
		vPeriodsList = New ValueList();
		vPeriodsList.Add(401, "Без ночевки - всего");
		vPeriodsList.Add(402, "1 - 4 ночевки - всего");
		vPeriodsList.Add(403, "5 - 7 ночевок - всего");
		vPeriodsList.Add(404, "8 - 14 ночевок - всего");
		vPeriodsList.Add(405, "15 - 28 ночевок - всего");
		vPeriodsList.Add(406, "29 - 91 ночевок - всего");
		
		vTotalGuests1 = 0;
		vTotalGuests2 = 0;
		vTotalGuests3 = 0;
		vTotalGuests4 = 0;
		vTotalGuests5 = 0;
		vTotalGuests6 = 0;
		vTotalGuests7 = 0;
		vTotalGuests = 0;
		
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
			vGuestsTotal = 0;
			
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
						EndIf;
						vGuestsTotal = vGuestsTotal + vTotalsByTripType.GuestsCheckedInTurnover;
					EndDo;
					
					vPage4PArea.Parameters.mGuestsTourists = vGuests1;
					vPage4PArea.Parameters.mGuestsEducation = vGuests2;
					vPage4PArea.Parameters.mGuestsRecreation = vGuests3;
					vPage4PArea.Parameters.mGuestsPilgrims = vGuests4;
					vPage4PArea.Parameters.mGuestsShoping = vGuests5;
					vPage4PArea.Parameters.mGuestsPrivateOther = vGuests6;
					vPage4PArea.Parameters.mGuestsBusiness = vGuests7;
					vPage4PArea.Parameters.mGuestsTotal = vGuestsTotal;
					
					pSpreadsheet.Put(vPage4PArea);
					
					vTotalGuests1 = vTotalGuests1 + vGuests1;
					vTotalGuests2 = vTotalGuests2 + vGuests2;
					vTotalGuests3 = vTotalGuests3 + vGuests3;
					vTotalGuests4 = vTotalGuests4 + vGuests4;
					vTotalGuests5 = vTotalGuests5 + vGuests5;
					vTotalGuests6 = vTotalGuests6 + vGuests6;
					vTotalGuests7 = vTotalGuests7 + vGuests7;
					vTotalGuests = vTotalGuests + vGuestsTotal;
					
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
						vGuestsTotal = 0;
						
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
							EndIf;
							vGuestsTotal = vGuestsTotal + vTotalsByTripType.GuestsCheckedInTurnover;
						EndDo;
						
						vPage4CArea.Parameters.mCountry = TrimAll(vTotalsByCountry.Country);
						vPage4CArea.Parameters.mCountryCode = TrimAll(vTotalsByCountry.Country.Code);
						
						vPage4CArea.Parameters.mGuestsTourists = vGuests1;
						vPage4CArea.Parameters.mGuestsEducation = vGuests2;
						vPage4CArea.Parameters.mGuestsRecreation = vGuests3;
						vPage4CArea.Parameters.mGuestsPilgrims = vGuests4;
						vPage4CArea.Parameters.mGuestsShoping = vGuests5;
						vPage4CArea.Parameters.mGuestsPrivateOther = vGuests6;
						vPage4CArea.Parameters.mGuestsBusiness = vGuests7;
						vPage4CArea.Parameters.mGuestsTotal = vGuestsTotal;
						
						pSpreadsheet.Put(vPage4CArea);
					EndDo;
				EndIf;
			EndDo;
		EndDo;
		
		vPage4TArea.Parameters.mGuestsTourists = vTotalGuests1;
		vPage4TArea.Parameters.mGuestsEducation = vTotalGuests2;
		vPage4TArea.Parameters.mGuestsRecreation = vTotalGuests3;
		vPage4TArea.Parameters.mGuestsPilgrims = vTotalGuests4;
		vPage4TArea.Parameters.mGuestsShoping = vTotalGuests5;
		vPage4TArea.Parameters.mGuestsPrivateOther = vTotalGuests6;
		vPage4TArea.Parameters.mGuestsBusiness = vTotalGuests7;
		vPage4TArea.Parameters.mGuestsTotal = vTotalGuests;
		
		pSpreadsheet.Put(vPage4TArea);
		
		// By countries
		vTotalsByCountry = vQryResult.Select(QueryResultIteration.ByGroups, "Country");
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
			vGuestsTotal = 0;
			
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
				EndIf;
				vGuestsTotal = vGuestsTotal + vTotalsByTripType.GuestsCheckedInTurnover;
			EndDo;
			
			vPage4CArea.Parameters.mCountry = TrimAll(vTotalsByCountry.Country);
			vPage4CArea.Parameters.mCountryCode = TrimAll(vTotalsByCountry.Country.Code);
			
			vPage4CArea.Parameters.mGuestsTourists = vGuests1;
			vPage4CArea.Parameters.mGuestsEducation = vGuests2;
			vPage4CArea.Parameters.mGuestsRecreation = vGuests3;
			vPage4CArea.Parameters.mGuestsPilgrims = vGuests4;
			vPage4CArea.Parameters.mGuestsShoping = vGuests5;
			vPage4CArea.Parameters.mGuestsPrivateOther = vGuests6;
			vPage4CArea.Parameters.mGuestsBusiness = vGuests7;
			vPage4CArea.Parameters.mGuestsTotal = vGuestsTotal;
			
			pSpreadsheet.Put(vPage4CArea);
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
		|		ELSE 506
		|	END AS PeriodNumber,
		|	CASE
		|		WHEN GeoSales.TripPurpose = &qBusiness
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qCommerce
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qOfficial
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qWork
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qScientific
		|			THEN 2
		|		WHEN GeoSales.TripPurpose = &qCrewman
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qHumanitarian
		|			THEN 6
		|		WHEN GeoSales.TripPurpose = &qTourism
		|			THEN 1
		|		WHEN GeoSales.TripPurpose = &qBeachRecreation
		|			THEN 2
		|		WHEN GeoSales.TripPurpose = &qCulturalAndEducational
		|			THEN 3
		|		WHEN GeoSales.TripPurpose = &qCruiseTourism
		|			THEN 4
		|		WHEN GeoSales.TripPurpose = &qPrivate
		|			THEN 6
		|		WHEN GeoSales.TripPurpose = &qStudy
		|			THEN 2
		|		WHEN GeoSales.TripPurpose = &qRecreation
		|			THEN 3
		|		WHEN GeoSales.TripPurpose = &qShopping
		|			THEN 5
		|		WHEN GeoSales.TripPurpose = &qPilgrims
		|			THEN 4
		|		WHEN GeoSales.TripPurpose = &qTransit
		|			THEN 1
		|		WHEN GeoSales.TripPurpose = &qOther
		|			THEN 6
		|		ELSE 6
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
		|					AND (Room IN HIERARCHY (&qRoomParent)  
		|						OR &qEmptyRoomParent)
		|					AND (RoomType IN HIERARCHY (&qRoomTypeParent)  
		|						OR &qEmptyRoomTypeParent)
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
		|		ELSE 506
		|	END,
		|	CASE
		|		WHEN GeoSales.TripPurpose = &qBusiness
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qCommerce
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qOfficial
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qWork
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qScientific
		|			THEN 2
		|		WHEN GeoSales.TripPurpose = &qCrewman
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qHumanitarian
		|			THEN 6
		|		WHEN GeoSales.TripPurpose = &qTourism
		|			THEN 1
		|		WHEN GeoSales.TripPurpose = &qBeachRecreation
		|			THEN 2
		|		WHEN GeoSales.TripPurpose = &qCulturalAndEducational
		|			THEN 3
		|		WHEN GeoSales.TripPurpose = &qCruiseTourism
		|			THEN 4
		|		WHEN GeoSales.TripPurpose = &qPrivate
		|			THEN 6
		|		WHEN GeoSales.TripPurpose = &qStudy
		|			THEN 2
		|		WHEN GeoSales.TripPurpose = &qRecreation
		|			THEN 3
		|		WHEN GeoSales.TripPurpose = &qShopping
		|			THEN 5
		|		WHEN GeoSales.TripPurpose = &qPilgrims
		|			THEN 4
		|		WHEN GeoSales.TripPurpose = &qTransit
		|			THEN 1
		|		WHEN GeoSales.TripPurpose = &qOther
		|			THEN 6
		|		ELSE 6
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
		vQry.SetParameter("qPeriodFrom", BegOfQuarter(PeriodFrom));
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
		vQry.SetParameter("qRoomParent", RoomParent);
		vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
		vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
		vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
		vQryResult = vQry.Execute();
		
		vPeriodsList = New ValueList();
		vPeriodsList.Add(501, "Без ночевки - всего");
		vPeriodsList.Add(502, "1 - 4 ночевки - всего");
		vPeriodsList.Add(503, "5 - 7 ночевок - всего");
		vPeriodsList.Add(504, "8 - 14 ночевок - всего");
		vPeriodsList.Add(505, "15 - 28 ночевок - всего");
		vPeriodsList.Add(506, "29 - 91 ночевок - всего");
		
		vTotalGuests1 = 0;
		vTotalGuests2 = 0;
		vTotalGuests3 = 0;
		vTotalGuests4 = 0;
		vTotalGuests5 = 0;
		vTotalGuests6 = 0;
		vTotalGuests7 = 0;
		vTotalGuests = 0;
		
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
			vGuestsTotal = 0;
			
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
						EndIf;
						vGuestsTotal = vGuestsTotal + vTotalsByTripType.GuestsCheckedInTurnover;
					EndDo;
					
					vPage5PArea.Parameters.mGuestsTourists = vGuests1;
					vPage5PArea.Parameters.mGuestsEducation = vGuests2;
					vPage5PArea.Parameters.mGuestsRecreation = vGuests3;
					vPage5PArea.Parameters.mGuestsPilgrims = vGuests4;
					vPage5PArea.Parameters.mGuestsShoping = vGuests5;
					vPage5PArea.Parameters.mGuestsPrivateOther = vGuests6;
					vPage5PArea.Parameters.mGuestsBusiness = vGuests7;
					vPage5PArea.Parameters.mGuestsTotal = vGuestsTotal;
					
					pSpreadsheet.Put(vPage5PArea);
					
					
					vTotalGuests1 = vTotalGuests1 + vGuests1;
					vTotalGuests2 = vTotalGuests2 + vGuests2;
					vTotalGuests3 = vTotalGuests3 + vGuests3;
					vTotalGuests4 = vTotalGuests4 + vGuests4;
					vTotalGuests5 = vTotalGuests5 + vGuests5;
					vTotalGuests6 = vTotalGuests6 + vGuests6;
					vTotalGuests7 = vTotalGuests7 + vGuests7;
					vTotalGuests = vTotalGuests + vGuestsTotal;
				EndIf;
			EndDo;
		EndDo;
		
		vPage5TArea.Parameters.mGuestsTourists = vTotalGuests1;
		vPage5TArea.Parameters.mGuestsEducation = vTotalGuests2;
		vPage5TArea.Parameters.mGuestsRecreation = vTotalGuests3;
		vPage5TArea.Parameters.mGuestsPilgrims = vTotalGuests4;
		vPage5TArea.Parameters.mGuestsShoping = vTotalGuests5;
		vPage5TArea.Parameters.mGuestsPrivateOther = vTotalGuests6;
		vPage5TArea.Parameters.mGuestsBusiness = vTotalGuests7;
		vPage5TArea.Parameters.mGuestsTotal = vTotalGuests;
		
		// Page 5 totals (507)
		pSpreadsheet.Put(vPage5TArea);
		
		// Page 5 footer
		pSpreadsheet.Put(vPage5FArea);
	EndIf; // End of quarter
	
	// Report footer
	pSpreadsheet.Put(vReportFArea);
EndProcedure // pmGenerate2023

// -----------------------------------------------------------------------------
Procedure pmGenerate2024(pSpreadsheet) Export;
	// Clear output spreadsheet
	pSpreadsheet.Clear();
	
	// Choose template
	vTemplate = ThisObject.GetTemplate("Report2024");
	
	// Report pages
	vPage1Area = vTemplate.GetArea("Page1");
	vPage2Area = vTemplate.GetArea("Page2");
	vPage3Area = vTemplate.GetArea("Page3");
	vPage4HArea = vTemplate.GetArea("Page4Header");
	vPage4PArea = vTemplate.GetArea("Page4Period");
	vPage4CArea = vTemplate.GetArea("Page4Country");
	vPage4TArea = vTemplate.GetArea("Page4Total");
	vPage4FArea = vTemplate.GetArea("Page4Footer");
	vPage5HArea = vTemplate.GetArea("Page5Header");
	vPage5PArea = vTemplate.GetArea("Page5Period");
	vPage5FArea = vTemplate.GetArea("Page5Footer");
	vPage5TArea = vTemplate.GetArea("Page5Total");
	vReportFArea = vTemplate.GetArea("ReportFooter");
	
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
	|					OR RoomType.Company = &qEmptyCompany)
	|				AND (Room IN HIERARCHY (&qRoomParent)  
	|					OR &qEmptyRoomParent)
	|				AND (RoomType IN HIERARCHY (&qRoomTypeParent)  
	|					OR &qEmptyRoomTypeParent)
	|	) AS RoomInventoryBalance";
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyCompany", Catalogs.Companies.EmptyRef());
	vQry.SetParameter("qRoomParent", RoomParent);
	vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
	vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
	vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
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
		|					OR RoomType.Company = &qEmptyCompany)
		|				AND (Room IN HIERARCHY (&qRoomParent)  
		|					OR &qEmptyRoomParent)
		|				AND (RoomType IN HIERARCHY (&qRoomTypeParent)  
		|					OR &qEmptyRoomTypeParent)
		|	) AS RoomInventoryBalance";
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qCompany", Company);
		vQry.SetParameter("qEmptyCompany", Catalogs.Companies.EmptyRef());
		vQry.SetParameter("qTopRoomTypes", TopRoomTypes);
		vQry.SetParameter("qRoomParent", RoomParent);
		vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
		vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
		vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
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
	|					OR AddRooms.RoomType.Company = &qEmptyCompany)
	|	AND (AddRooms.Room IN HIERARCHY (&qRoomParent)  
	|			OR &qEmptyRoomParent)
	|	AND (AddRooms.RoomType IN HIERARCHY (&qRoomTypeParent)  
	|					OR &qEmptyRoomTypeParent)
	|";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyCompany", Catalogs.Companies.EmptyRef());
	vQry.SetParameter("qRoomParent", RoomParent);
	vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
	vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
	vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
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
	|	SUM(ISNULL(RoomSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover,
	|	SUM(ISNULL(RoomSales.RoomsRentedTurnover, 0)) AS RoomsRentedTurnover,
	|	SUM(ISNULL(RoomSales.SalesWithoutVATTurnover, 0)) AS SalesWithoutVATTurnover
	|FROM
	|	(SELECT
	|		RoomSalesTurnovers.Client AS Client,
	|		RoomSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover,
	|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
	|		RoomSalesTurnovers.RoomsRentedTurnover AS RoomsRentedTurnover,
	|		RoomSalesTurnovers.SalesWithoutVATTurnover AS SalesWithoutVATTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection
	|					AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND (Room IN HIERARCHY (&qRoomParent)  
	|						OR &qEmptyRoomParent)
	|					AND (RoomType IN HIERARCHY (&qRoomTypeParent)  
	|						OR &qEmptyRoomTypeParent)
	|		) AS RoomSalesTurnovers) AS RoomSales";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qRoomParent", RoomParent);
	vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
	vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
	vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
	vQryResult = vQry.Execute().Unload();

	vPage3Area.Parameters.mTotalGuestDays = 0;
	vPage3Area.Parameters.mTotalGuestDaysRus = 0;
	vPage3Area.Parameters.mTotalGuestDaysFor = 0;
	vPage3Area.Parameters.mTotalGuests = 0;
	vPage3Area.Parameters.mTotalGuestsRus = 0;
	vPage3Area.Parameters.mTotalGuestsFor = 0;
	vPage3Area.Parameters.mTotalGuestsCheckedIn = 0;
	vPage3Area.Parameters.mTotalGuestsCheckedInRus = 0;
	vPage3Area.Parameters.mTotalGuestsCheckedInFor = 0;
	vPage3Area.Parameters.mTotalSumWithoutVAT = 0;
	vPage3Area.Parameters.mRoomsSold = 0;

	vTotalGuestDays = 0;
	vTotalGuestsCheckedIn = 0;
	vTotalSalesWithoutVAT = 0;
	vTotalRoomsSold = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		If vRow.GuestDaysTurnover <> Null Then 
			vPage3Area.Parameters.mTotalGuestDays = vRow.GuestDaysTurnover;
		EndIf;
		If vRow.GuestsCheckedInTurnover <> Null Then 
			vPage3Area.Parameters.mTotalGuestsCheckedIn = vRow.GuestsCheckedInTurnover;
		EndIf;
		If vRow.SalesWithoutVATTurnover <> Null Then 
			vPage3Area.Parameters.mTotalSumWithoutVAT = Round(vRow.SalesWithoutVATTurnover/1000, 0);
		EndIf;
		vTotalGuestDays = vRow.GuestDaysTurnover;
		vTotalGuestsCheckedIn = vRow.GuestsCheckedInTurnover; 
		vTotalSalesWithoutVAT = vRow.SalesWithoutVATTurnover;
		vTotalRoomsSold = vRow.RoomsRentedTurnover;
	EndIf;

	vTotalGuests = vTotalGuestsCheckedIn;
	vPage3Area.Parameters.mTotalGuests = vTotalGuestsCheckedIn;
	vPage3Area.Parameters.mRoomsSold = vTotalRoomsSold;
	
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
	|					AND (Room IN HIERARCHY (&qRoomParent)  
	|						OR &qEmptyRoomParent)
	|					AND (RoomType IN HIERARCHY (&qRoomTypeParent)  
	|						OR &qEmptyRoomTypeParent)
	|					AND (Client.Citizenship = &qRussia
	|						OR ISNULL(Client.Citizenship.Description, """") = """")) AS GeoSalesTurnovers) AS GeoSales";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qRoomParent", RoomParent);
	vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
	vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
	vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
	vQryResult = vQry.Execute().Unload();

	vRussiaGuestDays = 0;
	vRussiaGuestsCheckedIn = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vPage3Area.Parameters.mTotalGuestDaysRus = vRow.GuestDaysTurnover;
		vPage3Area.Parameters.mTotalGuestsCheckedInRus = vRow.GuestsCheckedInTurnover;
		vRussiaGuestDays = vRow.GuestDaysTurnover;
		vRussiaGuestsCheckedIn = vRow.GuestsCheckedInTurnover;
	EndIf;

	vRussiaGuests = vRussiaGuestsCheckedIn;
	vPage3Area.Parameters.mTotalGuestsRus = vRussiaGuestsCheckedIn;
	
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
	If vTotalGuestsCheckedIn <> Null And vRussiaGuestsCheckedIn <> Null Then
		vPage3Area.Parameters.mTotalGuestsCheckedInFor = vTotalGuestsCheckedIn - vRussiaGuestsCheckedIn;
	Else
		vPage3Area.Parameters.mTotalGuestsCheckedInFor = 0;
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
		|					AND (Room IN HIERARCHY (&qRoomParent)  
		|						OR &qEmptyRoomParent)
		|					AND (RoomType IN HIERARCHY (&qRoomTypeParent)  
		|						OR &qEmptyRoomTypeParent)
		|					AND (Service IN HIERARCHY (&qTourTicketServices)
		|						OR NOT &qUseServicesList)
		|					) AS RoomSalesTurnovers) AS RoomSales";
		vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qCompany", Company);
		vQry.SetParameter("qRoomParent", RoomParent);
		vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
		vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
		vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
		vUseServicesList = False;
		vServicesList = New ValueList();
		If Not TourTicketIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(TourTicketIncomeServiceGroup);
		EndIf;
		vQry.SetParameter("qUseServicesList", vUseServicesList);
		vQry.SetParameter("qTourTicketServices", vServicesList);
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
		|					AND (Room IN HIERARCHY (&qRoomParent)  
		|						OR &qEmptyRoomParent)
		|					AND (RoomType IN HIERARCHY (&qRoomTypeParent)  
		|						OR &qEmptyRoomTypeParent)
		|					AND (Service IN HIERARCHY (&qTourTicketServices)
		|						OR NOT &qUseServicesList)
		|					AND (Client.Citizenship = &qRussia
		|						OR ISNULL(Client.Citizenship.Description, """") = """")) AS RoomSalesTurnovers) AS RoomSales";
		vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qRussia", RussiaCountry);
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qCompany", Company);
		vQry.SetParameter("qRoomParent", RoomParent);
		vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
		vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
		vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
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
			vPage3Area.Parameters.mTotalTourTicketGuestsRus = vRow.GuestsCheckedInTurnover;
			
			vPage3Area.Parameters.mTotalTourTicketGuestsFor = vTotalTourTicketGuests - vRow.GuestsCheckedInTurnover;
		Else
			vPage3Area.Parameters.mTotalTourTicketGuestsRus = 0;
			
			vPage3Area.Parameters.mTotalTourTicketGuestsFor = vTotalTourTicketGuests;
		EndIf;
	EndIf;

	// 3.7 Get total sales
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
 	|				AND (Room IN HIERARCHY (&qRoomParent)  
	|					OR &qEmptyRoomParent)
	|				AND (RoomType IN HIERARCHY (&qRoomTypeParent)  
	|					OR &qEmptyRoomTypeParent)
	|				AND (Service IN HIERARCHY (&qIncomeServices)
	|					OR (NOT &qUseServicesList))) AS RoomSalesTurnovers";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qRoomParent", RoomParent);
	vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
	vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
	vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
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

	vPage3Area.Parameters.mTotalSumWithoutVAT = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vPage3Area.Parameters.mTotalSumWithoutVAT = Round(vRow.SalesWithoutVATTurnover/1000, 0);
	EndIf;

	// 3.8 Get room revenue sales
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomSalesTurnovers.RoomRevenueWithoutVATTurnover AS RoomRevenueWithoutVATTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			NOT IsCorrection
	|				AND Hotel = &qHotel
	|				AND Company = &qCompany
 	|				AND (Room IN HIERARCHY (&qRoomParent)  
	|					OR &qEmptyRoomParent)
	|				AND (RoomType IN HIERARCHY (&qRoomTypeParent)  
	|					OR &qEmptyRoomTypeParent)
	|	) AS RoomSalesTurnovers";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qRoomParent", RoomParent);
	vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
	vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
	vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
	vQryResult = vQry.Execute().Unload();

	vPage3Area.Parameters.mTotalRoomRevenueWithoutVAT = 0;
	If vQryResult.Count() > 0 Then
		vRow = vQryResult.Get(0);
		vPage3Area.Parameters.mTotalRoomRevenueWithoutVAT = Round(vRow.RoomRevenueWithoutVATTurnover/1000, 0);
	EndIf;

	// 3.9 Get meal board sales
	vPage3Area.Parameters.mTotalMealsWithoutVAT = 0;
	If ValueIsFilled(MealIncomeServiceGroup) Then
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
		|				AND (Room IN HIERARCHY (&qRoomParent)  
		|					OR &qEmptyRoomParent)
		|				AND (RoomType IN HIERARCHY (&qRoomTypeParent)  
		|					OR &qEmptyRoomTypeParent)
		|				AND (Service IN HIERARCHY (&qMealsServices)
		|					OR (NOT &qUseServicesList))) AS RoomSalesTurnovers";
		vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qCompany", Company);
		vQry.SetParameter("qRoomParent", RoomParent);
		vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
		vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
		vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
		vUseServicesList = False;
		vServicesList = New ValueList();
		If Not MealIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(MealIncomeServiceGroup);
		EndIf;
		vQry.SetParameter("qUseServicesList", vUseServicesList);
		vQry.SetParameter("qMealsServices", vServicesList);
		vQryResult = vQry.Execute().Unload();

		If vQryResult.Count() > 0 Then
			vRow = vQryResult.Get(0);
			vPage3Area.Parameters.mTotalMealsWithoutVAT = Round(vRow.SalesWithoutVATTurnover/1000, 0);
		EndIf;
	EndIf;
	
	pSpreadsheet.Put(vPage3Area);

	// Print page 4 and 5 for end of quarters only	
	If Month(PeriodTo) = 3 Or Month(PeriodTo) = 6 Or Month(PeriodTo) = 9 Or Month(PeriodTo) = 12 Then
		
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
		|		ELSE 406
		|	END AS PeriodNumber,
		|	GeoSales.Country AS Country,
		|	ISNULL(GeoSales.Country.Code, """") AS CountryCode,
		|	CASE
		|		WHEN GeoSales.TripPurpose = &qBusiness
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qCommerce
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qOfficial
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qWork
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qScientific
		|			THEN 2
		|		WHEN GeoSales.TripPurpose = &qCrewman
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qHumanitarian
		|			THEN 6
		|		WHEN GeoSales.TripPurpose = &qTourism
		|			THEN 1
		|		WHEN GeoSales.TripPurpose = &qBeachRecreation
		|			THEN 2
		|		WHEN GeoSales.TripPurpose = &qCulturalAndEducational
		|			THEN 3
		|		WHEN GeoSales.TripPurpose = &qCruiseTourism
		|			THEN 4
		|		WHEN GeoSales.TripPurpose = &qPrivate
		|			THEN 6
		|		WHEN GeoSales.TripPurpose = &qStudy
		|			THEN 2
		|		WHEN GeoSales.TripPurpose = &qRecreation
		|			THEN 3
		|		WHEN GeoSales.TripPurpose = &qShopping
		|			THEN 5
		|		WHEN GeoSales.TripPurpose = &qPilgrims
		|			THEN 4
		|		WHEN GeoSales.TripPurpose = &qTransit
		|			THEN 1
		|		WHEN GeoSales.TripPurpose = &qOther
		|			THEN 6
		|		ELSE 6
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
		|				AND (Room IN HIERARCHY (&qRoomParent)  
		|					OR &qEmptyRoomParent)
		|				AND (RoomType IN HIERARCHY (&qRoomTypeParent)  
		|					OR &qEmptyRoomTypeParent)
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
		|		ELSE 406
		|	END,
		|	GeoSales.Country,
		|	ISNULL(GeoSales.Country.Code, """"),
		|	CASE
		|		WHEN GeoSales.TripPurpose = &qBusiness
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qCommerce
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qOfficial
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qWork
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qScientific
		|			THEN 2
		|		WHEN GeoSales.TripPurpose = &qCrewman
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qHumanitarian
		|			THEN 6
		|		WHEN GeoSales.TripPurpose = &qTourism
		|			THEN 1
		|		WHEN GeoSales.TripPurpose = &qBeachRecreation
		|			THEN 2
		|		WHEN GeoSales.TripPurpose = &qCulturalAndEducational
		|			THEN 3
		|		WHEN GeoSales.TripPurpose = &qCruiseTourism
		|			THEN 4
		|		WHEN GeoSales.TripPurpose = &qPrivate
		|			THEN 6
		|		WHEN GeoSales.TripPurpose = &qStudy
		|			THEN 2
		|		WHEN GeoSales.TripPurpose = &qRecreation
		|			THEN 3
		|		WHEN GeoSales.TripPurpose = &qShopping
		|			THEN 5
		|		WHEN GeoSales.TripPurpose = &qPilgrims
		|			THEN 4
		|		WHEN GeoSales.TripPurpose = &qTransit
		|			THEN 1
		|		WHEN GeoSales.TripPurpose = &qOther
		|			THEN 6
		|		ELSE 6
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
		vQry.SetParameter("qPeriodFrom", BegOfQuarter(PeriodFrom));
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
		vQry.SetParameter("qRoomParent", RoomParent);
		vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
		vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
		vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
		vQryResult = vQry.Execute();
		
		vPeriodsList = New ValueList();
		vPeriodsList.Add(401, "Без ночевки - всего");
		vPeriodsList.Add(402, "1 - 4 ночевки - всего");
		vPeriodsList.Add(403, "5 - 7 ночевок - всего");
		vPeriodsList.Add(404, "8 - 14 ночевок - всего");
		vPeriodsList.Add(405, "15 - 28 ночевок - всего");
		vPeriodsList.Add(406, "29 - 91 ночевок - всего");
		
		vTotalGuests1 = 0;
		vTotalGuests2 = 0;
		vTotalGuests3 = 0;
		vTotalGuests4 = 0;
		vTotalGuests5 = 0;
		vTotalGuests6 = 0;
		vTotalGuests7 = 0;
		vTotalGuests = 0;
		
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
			vGuestsTotal = 0;
			
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
						EndIf;
						vGuestsTotal = vGuestsTotal + vTotalsByTripType.GuestsCheckedInTurnover;
					EndDo;
					
					vPage4PArea.Parameters.mGuestsTourists = vGuests1;
					vPage4PArea.Parameters.mGuestsEducation = vGuests2;
					vPage4PArea.Parameters.mGuestsRecreation = vGuests3;
					vPage4PArea.Parameters.mGuestsPilgrims = vGuests4;
					vPage4PArea.Parameters.mGuestsShoping = vGuests5;
					vPage4PArea.Parameters.mGuestsPrivateOther = vGuests6;
					vPage4PArea.Parameters.mGuestsBusiness = vGuests7;
					vPage4PArea.Parameters.mGuestsTotal = vGuestsTotal;
					
					pSpreadsheet.Put(vPage4PArea);
					
					vTotalGuests1 = vTotalGuests1 + vGuests1;
					vTotalGuests2 = vTotalGuests2 + vGuests2;
					vTotalGuests3 = vTotalGuests3 + vGuests3;
					vTotalGuests4 = vTotalGuests4 + vGuests4;
					vTotalGuests5 = vTotalGuests5 + vGuests5;
					vTotalGuests6 = vTotalGuests6 + vGuests6;
					vTotalGuests7 = vTotalGuests7 + vGuests7;
					vTotalGuests = vTotalGuests + vGuestsTotal;
					
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
						vGuestsTotal = 0;
						
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
							EndIf;
							vGuestsTotal = vGuestsTotal + vTotalsByTripType.GuestsCheckedInTurnover;
						EndDo;
						
						vPage4CArea.Parameters.mCountry = TrimAll(vTotalsByCountry.Country);
						vPage4CArea.Parameters.mCountryCode = TrimAll(vTotalsByCountry.Country.Code);
						
						vPage4CArea.Parameters.mGuestsTourists = vGuests1;
						vPage4CArea.Parameters.mGuestsEducation = vGuests2;
						vPage4CArea.Parameters.mGuestsRecreation = vGuests3;
						vPage4CArea.Parameters.mGuestsPilgrims = vGuests4;
						vPage4CArea.Parameters.mGuestsShoping = vGuests5;
						vPage4CArea.Parameters.mGuestsPrivateOther = vGuests6;
						vPage4CArea.Parameters.mGuestsBusiness = vGuests7;
						vPage4CArea.Parameters.mGuestsTotal = vGuestsTotal;
						
						pSpreadsheet.Put(vPage4CArea);
					EndDo;
				EndIf;
			EndDo;
		EndDo;
		
		vPage4TArea.Parameters.mGuestsTourists = vTotalGuests1;
		vPage4TArea.Parameters.mGuestsEducation = vTotalGuests2;
		vPage4TArea.Parameters.mGuestsRecreation = vTotalGuests3;
		vPage4TArea.Parameters.mGuestsPilgrims = vTotalGuests4;
		vPage4TArea.Parameters.mGuestsShoping = vTotalGuests5;
		vPage4TArea.Parameters.mGuestsPrivateOther = vTotalGuests6;
		vPage4TArea.Parameters.mGuestsBusiness = vTotalGuests7;
		vPage4TArea.Parameters.mGuestsTotal = vTotalGuests;
		
		pSpreadsheet.Put(vPage4TArea);
		
		// By countries
		vTotalsByCountry = vQryResult.Select(QueryResultIteration.ByGroups, "Country");
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
			vGuestsTotal = 0;
			
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
				EndIf;
				vGuestsTotal = vGuestsTotal + vTotalsByTripType.GuestsCheckedInTurnover;
			EndDo;
			
			vPage4CArea.Parameters.mCountry = TrimAll(vTotalsByCountry.Country);
			vPage4CArea.Parameters.mCountryCode = TrimAll(vTotalsByCountry.Country.Code);
			
			vPage4CArea.Parameters.mGuestsTourists = vGuests1;
			vPage4CArea.Parameters.mGuestsEducation = vGuests2;
			vPage4CArea.Parameters.mGuestsRecreation = vGuests3;
			vPage4CArea.Parameters.mGuestsPilgrims = vGuests4;
			vPage4CArea.Parameters.mGuestsShoping = vGuests5;
			vPage4CArea.Parameters.mGuestsPrivateOther = vGuests6;
			vPage4CArea.Parameters.mGuestsBusiness = vGuests7;
			vPage4CArea.Parameters.mGuestsTotal = vGuestsTotal;
			
			pSpreadsheet.Put(vPage4CArea);
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
		|		ELSE 506
		|	END AS PeriodNumber,
		|	CASE
		|		WHEN GeoSales.TripPurpose = &qBusiness
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qCommerce
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qOfficial
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qWork
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qScientific
		|			THEN 2
		|		WHEN GeoSales.TripPurpose = &qCrewman
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qHumanitarian
		|			THEN 6
		|		WHEN GeoSales.TripPurpose = &qTourism
		|			THEN 1
		|		WHEN GeoSales.TripPurpose = &qBeachRecreation
		|			THEN 2
		|		WHEN GeoSales.TripPurpose = &qCulturalAndEducational
		|			THEN 3
		|		WHEN GeoSales.TripPurpose = &qCruiseTourism
		|			THEN 4
		|		WHEN GeoSales.TripPurpose = &qPrivate
		|			THEN 6
		|		WHEN GeoSales.TripPurpose = &qStudy
		|			THEN 2
		|		WHEN GeoSales.TripPurpose = &qRecreation
		|			THEN 3
		|		WHEN GeoSales.TripPurpose = &qShopping
		|			THEN 5
		|		WHEN GeoSales.TripPurpose = &qPilgrims
		|			THEN 4
		|		WHEN GeoSales.TripPurpose = &qTransit
		|			THEN 1
		|		WHEN GeoSales.TripPurpose = &qOther
		|			THEN 6
		|		ELSE 6
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
		|				AND (Room IN HIERARCHY (&qRoomParent)  
		|					OR &qEmptyRoomParent)
		|				AND (RoomType IN HIERARCHY (&qRoomTypeParent)  
		|					OR &qEmptyRoomTypeParent)
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
		|		ELSE 506
		|	END,
		|	CASE
		|		WHEN GeoSales.TripPurpose = &qBusiness
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qCommerce
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qOfficial
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qWork
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qScientific
		|			THEN 2
		|		WHEN GeoSales.TripPurpose = &qCrewman
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qHumanitarian
		|			THEN 6
		|		WHEN GeoSales.TripPurpose = &qTourism
		|			THEN 1
		|		WHEN GeoSales.TripPurpose = &qBeachRecreation
		|			THEN 2
		|		WHEN GeoSales.TripPurpose = &qCulturalAndEducational
		|			THEN 3
		|		WHEN GeoSales.TripPurpose = &qCruiseTourism
		|			THEN 4
		|		WHEN GeoSales.TripPurpose = &qPrivate
		|			THEN 6
		|		WHEN GeoSales.TripPurpose = &qStudy
		|			THEN 2
		|		WHEN GeoSales.TripPurpose = &qRecreation
		|			THEN 3
		|		WHEN GeoSales.TripPurpose = &qShopping
		|			THEN 5
		|		WHEN GeoSales.TripPurpose = &qPilgrims
		|			THEN 4
		|		WHEN GeoSales.TripPurpose = &qTransit
		|			THEN 1
		|		WHEN GeoSales.TripPurpose = &qOther
		|			THEN 6
		|		ELSE 6
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
		vQry.SetParameter("qPeriodFrom", BegOfQuarter(PeriodFrom));
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
		vQry.SetParameter("qRoomParent", RoomParent);
		vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
		vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
		vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
		vQryResult = vQry.Execute();
		
		vPeriodsList = New ValueList();
		vPeriodsList.Add(501, "Без ночевки - всего");
		vPeriodsList.Add(502, "1 - 4 ночевки - всего");
		vPeriodsList.Add(503, "5 - 7 ночевок - всего");
		vPeriodsList.Add(504, "8 - 14 ночевок - всего");
		vPeriodsList.Add(505, "15 - 28 ночевок - всего");
		vPeriodsList.Add(506, "29 - 91 ночевок - всего");
		
		vTotalGuests1 = 0;
		vTotalGuests2 = 0;
		vTotalGuests3 = 0;
		vTotalGuests4 = 0;
		vTotalGuests5 = 0;
		vTotalGuests6 = 0;
		vTotalGuests7 = 0;
		vTotalGuests = 0;
		
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
			vGuestsTotal = 0;
			
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
						EndIf;
						vGuestsTotal = vGuestsTotal + vTotalsByTripType.GuestsCheckedInTurnover;
					EndDo;
					
					vPage5PArea.Parameters.mGuestsTourists = vGuests1;
					vPage5PArea.Parameters.mGuestsEducation = vGuests2;
					vPage5PArea.Parameters.mGuestsRecreation = vGuests3;
					vPage5PArea.Parameters.mGuestsPilgrims = vGuests4;
					vPage5PArea.Parameters.mGuestsShoping = vGuests5;
					vPage5PArea.Parameters.mGuestsPrivateOther = vGuests6;
					vPage5PArea.Parameters.mGuestsBusiness = vGuests7;
					vPage5PArea.Parameters.mGuestsTotal = vGuestsTotal;
					
					pSpreadsheet.Put(vPage5PArea);
					
					
					vTotalGuests1 = vTotalGuests1 + vGuests1;
					vTotalGuests2 = vTotalGuests2 + vGuests2;
					vTotalGuests3 = vTotalGuests3 + vGuests3;
					vTotalGuests4 = vTotalGuests4 + vGuests4;
					vTotalGuests5 = vTotalGuests5 + vGuests5;
					vTotalGuests6 = vTotalGuests6 + vGuests6;
					vTotalGuests7 = vTotalGuests7 + vGuests7;
					vTotalGuests = vTotalGuests + vGuestsTotal;
				EndIf;
			EndDo;
		EndDo;
		
		vPage5TArea.Parameters.mGuestsTourists = vTotalGuests1;
		vPage5TArea.Parameters.mGuestsEducation = vTotalGuests2;
		vPage5TArea.Parameters.mGuestsRecreation = vTotalGuests3;
		vPage5TArea.Parameters.mGuestsPilgrims = vTotalGuests4;
		vPage5TArea.Parameters.mGuestsShoping = vTotalGuests5;
		vPage5TArea.Parameters.mGuestsPrivateOther = vTotalGuests6;
		vPage5TArea.Parameters.mGuestsBusiness = vTotalGuests7;
		vPage5TArea.Parameters.mGuestsTotal = vTotalGuests;
		
		// Page 5 totals (507)
		pSpreadsheet.Put(vPage5TArea);
		
		// Page 5 footer
		pSpreadsheet.Put(vPage5FArea);
	EndIf; // End of quarter
	
	// Report footer
	pSpreadsheet.Put(vReportFArea);
	
EndProcedure // pmGenerate2024

// -----------------------------------------------------------------------------
Procedure pmGenerate2026(pSpreadsheet) Export;
	// Clear output spreadsheet
	pSpreadsheet.Clear();
	
	// Choose template
	vTemplate = ThisObject.GetTemplate("Report2026");
	
	// Report pages
	vPage1Area = vTemplate.GetArea("Page1");
	vPage2Area = vTemplate.GetArea("Page2");
	vPage3Area = vTemplate.GetArea("Page3");
	vPage4HArea = vTemplate.GetArea("Page4Header");
	vPage4PArea = vTemplate.GetArea("Page4Period");
	vPage4CArea = vTemplate.GetArea("Page4Country");
	vPage4TArea = vTemplate.GetArea("Page4Total");
	vPage4FArea = vTemplate.GetArea("Page4Footer");
	vPage5HArea = vTemplate.GetArea("Page5Header");
	vPage5PArea = vTemplate.GetArea("Page5Period");
	vPage5FArea = vTemplate.GetArea("Page5Footer");
	vPage5TArea = vTemplate.GetArea("Page5Total");
	vReportFArea = vTemplate.GetArea("ReportFooter");
	
	// Page 1
	vPage1Area.Parameters.mPeriodStr = PeriodPresentation(BegOfDay(PeriodFrom), EndOfDay(PeriodTo), cmLocalizationCode());
	vPage1Area.Parameters.mHotelName = TrimAll(Hotel.LegacyName);
	vPage1Area.Parameters.mHotelPostAddress = cmGetAddressPresentation(Hotel.PostAddress);
	vPage1Area.Parameters.mCompanyName = TrimAll(Company.LegacyName);
	vPage1Area.Parameters.mCompanyPostAddress = cmGetAddressPresentation(Company.PostAddress);
	vPage1Area.Parameters.mCompanyOKPOCode = TrimAll(Company.OKPO);
	pSpreadsheet.Put(vPage1Area);
	WriteAreaParametersIntoReportParameters(vPage1Area.Parameters, New Structure(
		"mCompanyName,
		|mCompanyOKPOCode,
		|mCompanyPostAddress,
		|mHotelName,
		|mHotelPostAddress,
		|mPeriodStr"));
	pSpreadsheet.PutHorizontalPageBreak();
	
	// Page 2
	
	// Type
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
	vPage2Area.Parameters.m118 = "1";
	vPage2Area.Parameters.m119 = "";
	If ValueIsFilled(Hotel) And Hotel.IsSeasonal Then
		vPage2Area.Parameters.m118 = "";
		vPage2Area.Parameters.m119 = "1";
	EndIf;
	
	// Classifiaction
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
	|				AND (Room IN HIERARCHY (&qRoomParent)  
	|					OR &qEmptyRoomParent)
	|				AND (RoomType IN HIERARCHY (&qRoomTypeParent)  
	|					OR &qEmptyRoomTypeParent)
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
	vQry.SetParameter("qRoomParent", RoomParent);
	vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
	vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
	vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
	
	vData = vQry.Execute().Unload();
	
	v127 = "";
	v128 = "";
	v129 = "";
	v130 = "";
	v131 = "";
	v132 = "";
	
	For Each vDataRow In vData Do
		If vDataRow.RoomTypeIsNotPermanentBuilding <> Null And vDataRow.RoomTypeIsModularStructure <> Null Then
			If Not vDataRow.RoomTypeIsNotPermanentBuilding And Not vDataRow.RoomTypeIsModularStructure Then
				v127 = "1";
				v131 = "1";
			ElsIf vDataRow.RoomTypeIsNotPermanentBuilding Then
				If v127 = "1" Then
					v127 = "";
					v129 = "1";
				Else
					v128 = "1";
				EndIf;
				If Not vDataRow.RoomTypeIsModularStructure Then
					v131 = "1";
				Else
					If v131 = "1" Then
						v132 = "1";
						v131 = "";
					Else
						v130 = "1";
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndDo;

	vPage2Area.Parameters.m127 = v127;
	vPage2Area.Parameters.m128 = v128;
	vPage2Area.Parameters.m129 = v129;
	vPage2Area.Parameters.m130 = v130;
	vPage2Area.Parameters.m131 = v131;
	vPage2Area.Parameters.m132 = v132;

	pSpreadsheet.Put(vPage2Area);
	WriteAreaParametersIntoReportParameters(vPage2Area.Parameters, New Structure(
		"m101	,
		|m102	,
		|m103	,
		|m104	,
		|m105	,
		|m106	,
		|m107	,
		|m108	,
		|m109	,
		|m110	,
		|m111	,
		|m112	,
		|m113	,
		|m114	,
		|m115	,
		|m116	,
		|m117	,
		|m118	,
		|m119	,
		|m127	,
		|m128	,
		|m129	,
		|m130	,
		|m131	,
		|m132	,
		|m1Star	,
		|m2Star	,
		|m3Star	,
		|m4Star	,
		|m5Star	,
		|mNoStar	,
		|mNotClassified"));		
	
	pSpreadsheet.PutHorizontalPageBreak();
	
	// Page 3
	
	// 3.1 Get total number of rooms/beds per end of period
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
	|					OR RoomType.Company = &qEmptyCompany)
	|				AND (Room IN HIERARCHY (&qRoomParent)  
	|					OR &qEmptyRoomParent)
	|				AND (RoomType IN HIERARCHY (&qRoomTypeParent)  
	|					OR &qEmptyRoomTypeParent)
	|	) AS RoomInventoryBalance
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
	vQry.SetParameter("qRoomParent", RoomParent);
	vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
	vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
	vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
	vQryResult = vQry.Execute().Unload();

	vTotalRoomsBalance = 0;
	vTotalBedsBalance = 0;
	
	vPage3Area.Parameters.mTotalRooms = 0;
	vPage3Area.Parameters.mTotalBeds = 0;
	vPage3Area.Parameters.mTotalModularRooms = 0;
	vPage3Area.Parameters.mTotalModularBeds = 0;
	
	For N = 0 To vPage3Area.Parameters.Count()-1 Do
		If vPage3Area.Parameters[N] = Undefined Then
			vPage3Area.Parameters.Set(N,0); 
		EndIf; 
	EndDo;
	For Each vQryResultRow In vQryResult Do
		vTotalRoomsBalance = vTotalRoomsBalance + vQryResultRow.TotalRoomsBalance;
		vTotalBedsBalance = vTotalBedsBalance + vQryResultRow.TotalBedsBalance;
		
		If vQryResultRow.RoomTypeIsModularStructure <> Null And vQryResultRow.RoomTypeIsModularStructure Then
			vPage3Area.Parameters.mTotalModularRooms = vQryResultRow.TotalRoomsBalance;
			vPage3Area.Parameters.mTotalModularBeds = vQryResultRow.TotalBedsBalance;
		EndIf;
	EndDo;

	vPage3Area.Parameters.mTotalRooms = vTotalRoomsBalance;
	vPage3Area.Parameters.mTotalBeds = vTotalBedsBalance;
	
	// 3.2 Get total number of rooms/beds for top room types per end of period
	vPage3Area.Parameters.mTotalTopRooms = 0;
	vPage3Area.Parameters.mTotalTopModularRooms = 0;
	
	vTotalTopRooms = 0;
	
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
		|					OR RoomType.Company = &qEmptyCompany)
		|				AND (Room IN HIERARCHY (&qRoomParent)  
		|					OR &qEmptyRoomParent)
		|				AND (RoomType IN HIERARCHY (&qRoomTypeParent)  
		|					OR &qEmptyRoomTypeParent)
		|	) AS RoomInventoryBalance
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
		vQry.SetParameter("qRoomParent", RoomParent);
		vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
		vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
		vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
		vQryResult = vQry.Execute().Unload();

		For Each vQryResultRow In vQryResult Do
			vTotalTopRooms = vTotalTopRooms + vQryResultRow.TotalRoomsBalance;
			
			If vQryResultRow.RoomTypeIsModularStructure <> Null And vQryResultRow.RoomTypeIsModularStructure Then
				vPage3Area.Parameters.mTotalTopModularRooms = vQryResultRow.TotalRoomsBalance;
			EndIf;
		EndDo;
	EndIf;

	vPage3Area.Parameters.mTotalTopRooms = vTotalTopRooms;

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
	|	AND (AddRooms.Room IN HIERARCHY (&qRoomParent)  
	|			OR &qEmptyRoomParent)
	|	AND (AddRooms.RoomType IN HIERARCHY (&qRoomTypeParent)  
	|					OR &qEmptyRoomTypeParent)
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
	vQry.SetParameter("qRoomParent", RoomParent);
	vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
	vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
	vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
	vQryResult = vQry.Execute().Unload();

	vPage3Area.Parameters.mNewRooms = 0;
	vPage3Area.Parameters.mNewModularRooms = 0;
	
	vTotalNewRooms = 0;
	
	For Each vQryResultRow In vQryResult Do
		vTotalNewRooms = vTotalNewRooms + vQryResultRow.NewRoomsCount;
		
		If vQryResultRow.RoomTypeIsModularStructure <> Null And vQryResultRow.RoomTypeIsModularStructure Then
			vPage3Area.Parameters.mNewModularRooms = vQryResultRow.NewRoomsCount;
		EndIf;
	EndDo;

	vPage3Area.Parameters.mNewRooms = vTotalNewRooms;
	
	// Guest days and checked-in guests per period
	vPage3Area.Parameters.mTotalGuestDays = 0;
	vPage3Area.Parameters.mTotalModularGuestDays = 0;
	vPage3Area.Parameters.mTotalGuestDaysRus = 0;
	vPage3Area.Parameters.mTotalModularGuestDaysRus = 0;
	vPage3Area.Parameters.mTotalGuestDaysFor = 0;
	vPage3Area.Parameters.mTotalModularGuestDaysFor = 0;

	vPage3Area.Parameters.mTotalGuests = 0;
	vPage3Area.Parameters.mTotalModularGuests = 0;
	vPage3Area.Parameters.mTotalGuestsRus = 0;
	vPage3Area.Parameters.mTotalModularGuestsRus = 0;
	vPage3Area.Parameters.mTotalGuestsFor = 0;
	vPage3Area.Parameters.mTotalModularGuestsFor = 0;

	vTotalGuestDays = 0;
	vTotalGuestDaysRus = 0;
	vTotalGuestDaysFor = 0;

	vTotalGuests = 0;
	vTotalGuestsRus = 0;
	vTotalGuestsFor = 0;

	// Checked-in guests per accounting month
	vPage3Area.Parameters.mTotalGuestsCheckedIn = 0;
	vPage3Area.Parameters.mTotalModularGuestsCheckedIn = 0;
	vPage3Area.Parameters.mTotalGuestsCheckedInRus = 0;
	vPage3Area.Parameters.mTotalModularGuestsCheckedInRus = 0;
	vPage3Area.Parameters.mTotalGuestsCheckedInFor = 0;
	vPage3Area.Parameters.mTotalModularGuestsCheckedInFor = 0;

	vTotalGuestsCheckedIn = 0;
	vTotalGuestsCheckedInRus = 0;
	vTotalGuestsCheckedInFor = 0;
	
	// Sales per period
	vPage3Area.Parameters.mTotalSalesWithoutVAT = 0;
	vPage3Area.Parameters.mTotalModularSalesWithoutVAT = 0;

	vTotalSalesWithoutVAT = 0;
	vTotalRoomRevenueWithoutVAT = 0;
	
	// Rooms rented per period
	vPage3Area.Parameters.mRoomsSold = 0;
	vPage3Area.Parameters.mModularRoomsSold = 0;
	
	vTotalRoomsSold = 0;

	// Guest days data per report period
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ISNULL(RoomSales.RoomType.IsModularStructure, FALSE) AS RoomTypeIsModularStructure,
	|	SUM(ISNULL(RoomSales.GuestDaysTurnover, 0)) AS GuestDaysTurnover
	|FROM
	|	(SELECT
	|		RoomSalesTurnovers.RoomType AS RoomType,
	|		RoomSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection
	|					AND Hotel = &qHotel
	|					AND Company = &qCompany
 	|					AND (Room IN HIERARCHY (&qRoomParent)  
	|						OR &qEmptyRoomParent)
	|					AND (RoomType IN HIERARCHY (&qRoomTypeParent)  
	|						OR &qEmptyRoomTypeParent)
	|	) AS RoomSalesTurnovers) AS RoomSales
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
	vQry.SetParameter("qRoomParent", RoomParent);
	vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
	vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
	vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
	vQryResult = vQry.Execute().Unload();

	For Each vQryResultRow In vQryResult Do
		If vQryResultRow.GuestDaysTurnover <> Null Then 
			vTotalGuestDays = vTotalGuestDays + vQryResultRow.GuestDaysTurnover;
			
			If vQryResultRow.RoomTypeIsModularStructure <> Null And vQryResultRow.RoomTypeIsModularStructure Then
				vPage3Area.Parameters.mTotalModularGuestDays = vQryResultRow.GuestDaysTurnover;
			EndIf;
		EndIf;
	EndDo;

	// Guests data per report period
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ISNULL(RoomSales.RoomType.IsModularStructure, FALSE) AS RoomTypeIsModularStructure,
	|	SUM(ISNULL(RoomSales.GuestsCheckedInTurnover, 0)) AS GuestsCountTurnover
	|FROM
	|	(SELECT
	|		RoomSalesTurnovers.RoomType AS RoomType,
	|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qEmptyDate,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection
	|					AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND NOT ParentDoc.CheckInDate IS NULL
	|					AND ParentDoc.CheckInDate < &qPeriodTo
	|					AND ParentDoc.CheckOutDate > &qPeriodFrom  
 	|					AND (Room IN HIERARCHY (&qRoomParent)  
	|						OR &qEmptyRoomParent)
	|					AND (RoomType IN HIERARCHY (&qRoomTypeParent)  
	|						OR &qEmptyRoomTypeParent)
	|	) AS RoomSalesTurnovers) AS RoomSales
	|
	|GROUP BY
	|	ISNULL(RoomSales.RoomType.IsModularStructure, FALSE)
	|
	|ORDER BY
	|	RoomTypeIsModularStructure";
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qRoomParent", RoomParent);
	vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
	vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
	vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
	vQryResult = vQry.Execute().Unload();

	For Each vQryResultRow In vQryResult Do
		If vQryResultRow.GuestsCountTurnover <> Null Then 
			vTotalGuests = vTotalGuests + vQryResultRow.GuestsCountTurnover;

			If vQryResultRow.RoomTypeIsModularStructure <> Null And vQryResultRow.RoomTypeIsModularStructure Then
				vPage3Area.Parameters.mTotalModularGuests = vQryResultRow.GuestsCountTurnover;
			EndIf;
		EndIf;
	EndDo;

	// Sales data per report period
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ISNULL(RoomSales.RoomType.IsModularStructure, FALSE) AS RoomTypeIsModularStructure,
	|	SUM(ISNULL(RoomSales.RoomsRentedTurnover, 0)) AS RoomsRentedTurnover,
	|	SUM(ISNULL(RoomSales.SalesWithoutVATTurnover, 0)) AS SalesWithoutVATTurnover,
	|	SUM(ISNULL(RoomSales.RoomRevenueWithoutVATTurnover, 0)) AS RoomRevenueWithoutVATTurnover
	|FROM
	|	(SELECT
	|		RoomSalesTurnovers.RoomType AS RoomType,
	|		RoomSalesTurnovers.RoomsRentedTurnover AS RoomsRentedTurnover,
	|		RoomSalesTurnovers.SalesWithoutVATTurnover AS SalesWithoutVATTurnover,
	|		RoomSalesTurnovers.RoomRevenueWithoutVATTurnover AS RoomRevenueWithoutVATTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection
	|					AND Hotel = &qHotel
	|					AND Company = &qCompany
 	|					AND (Room IN HIERARCHY (&qRoomParent)  
	|						OR &qEmptyRoomParent)
	|					AND (RoomType IN HIERARCHY (&qRoomTypeParent)  
	|						OR &qEmptyRoomTypeParent)
	|	) AS RoomSalesTurnovers) AS RoomSales
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
	vQry.SetParameter("qRoomParent", RoomParent);
	vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
	vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
	vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
	vQryResult = vQry.Execute().Unload();

	vPage3Area.Parameters.mTotalRoomRevenueWithoutVAT = 0;
	vPage3Area.Parameters.mTotalModularRoomRevenueWithoutVAT = 0;
	For Each vQryResultRow In vQryResult Do
		If vQryResultRow.SalesWithoutVATTurnover <> Null Then
			vTotalSalesWithoutVAT = vTotalSalesWithoutVAT + vQryResultRow.SalesWithoutVATTurnover;
			
			If vQryResultRow.RoomTypeIsModularStructure <> Null And vQryResultRow.RoomTypeIsModularStructure Then
				vPage3Area.Parameters.mTotalModularSalesWithoutVAT = Round(vQryResultRow.SalesWithoutVATTurnover/1000, 0);
			EndIf;
		EndIf;
		If vQryResultRow.RoomRevenueWithoutVATTurnover <> Null Then
			vTotalRoomRevenueWithoutVAT = vTotalRoomRevenueWithoutVAT + vQryResultRow.RoomRevenueWithoutVATTurnover;
			
			If vQryResultRow.RoomTypeIsModularStructure <> Null And vQryResultRow.RoomTypeIsModularStructure Then
				vPage3Area.Parameters.mTotalModularRoomRevenueWithoutVAT = Round(vQryResultRow.RoomRevenueWithoutVATTurnover/1000, 0);
			EndIf;
		EndIf;
		
		If vQryResultRow.RoomsRentedTurnover <> Null Then
			vTotalRoomsSold = vTotalRoomsSold + vQryResultRow.RoomsRentedTurnover;
			
			If vQryResultRow.RoomTypeIsModularStructure <> Null And vQryResultRow.RoomTypeIsModularStructure Then
				vPage3Area.Parameters.mModularRoomsSold = vQryResultRow.RoomsRentedTurnover;
			EndIf;
		EndIf;
	EndDo;

	vPage3Area.Parameters.mTotalGuestDays = vTotalGuestDays;
	vPage3Area.Parameters.mTotalGuests = vTotalGuests;
	vPage3Area.Parameters.mRoomsSold = vTotalRoomsSold;
	vPage3Area.Parameters.mTotalSalesWithoutVAT = Round(vTotalSalesWithoutVAT/1000, 0);
	vPage3Area.Parameters.mTotalRoomRevenueWithoutVAT = Round(vTotalRoomRevenueWithoutVAT/1000, 0);
	
	// Get total number of guest days from Russia
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ISNULL(GeoSales.RoomType.IsModularStructure, FALSE) AS RoomTypeIsModularStructure,
	|	SUM(ISNULL(GeoSales.GuestDaysTurnover, 0)) AS GuestDaysTurnover
	|FROM
	|	(SELECT
	|		GeoSalesTurnovers.RoomType AS RoomType,
	|		GeoSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection
	|					AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND (Room IN HIERARCHY (&qRoomParent)  
	|						OR &qEmptyRoomParent)
	|					AND (RoomType IN HIERARCHY (&qRoomTypeParent)  
	|						OR &qEmptyRoomTypeParent)
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
	vQry.SetParameter("qRoomParent", RoomParent);
	vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
	vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
	vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
	vQryResult = vQry.Execute().Unload();

	vRussiaGuestDays = 0;
	For Each vQryResultRow In vQryResult Do
		If vQryResultRow.GuestDaysTurnover <> Null Then
			vRussiaGuestDays = vRussiaGuestDays + vQryResultRow.GuestDaysTurnover;
			
			If vQryResultRow.RoomTypeIsModularStructure <> Null And vQryResultRow.RoomTypeIsModularStructure Then
				vPage3Area.Parameters.mTotalModularGuestDaysRus = vQryResultRow.GuestDaysTurnover;
			EndIf;
		EndIf;
	EndDo;
	vPage3Area.Parameters.mTotalGuestDaysRus = vRussiaGuestDays;
	
	// Get total number of guests from Russia
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ISNULL(GeoSales.RoomType.IsModularStructure, FALSE) AS RoomTypeIsModularStructure,
	|	SUM(ISNULL(GeoSales.GuestsCheckedInTurnover, 0)) AS GuestsCountTurnover
	|FROM
	|	(SELECT
	|		GeoSalesTurnovers.RoomType AS RoomType,
	|		GeoSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qEmptyDate,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection
	|					AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND (Room IN HIERARCHY (&qRoomParent)  
	|						OR &qEmptyRoomParent)
	|					AND (RoomType IN HIERARCHY (&qRoomTypeParent)  
	|						OR &qEmptyRoomTypeParent)
	|					AND (Client.Citizenship = &qRussia
	|						OR ISNULL(Client.Citizenship.Description, """") = """")
	|					AND NOT ParentDoc.CheckInDate IS NULL
	|					AND ParentDoc.CheckInDate < &qPeriodTo
	|					AND ParentDoc.CheckOutDate > &qPeriodFrom) AS GeoSalesTurnovers) AS GeoSales
	|
	|GROUP BY
	|	ISNULL(GeoSales.RoomType.IsModularStructure, FALSE)
	|
	|ORDER BY
	|	RoomTypeIsModularStructure";
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussia", RussiaCountry);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qRoomParent", RoomParent);
	vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
	vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
	vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
	vQryResult = vQry.Execute().Unload();

	vRussiaGuests = 0;
	For Each vQryResultRow In vQryResult Do
		If vQryResultRow.GuestsCountTurnover <> Null Then
			vRussiaGuests = vRussiaGuests + vQryResultRow.GuestsCountTurnover;
			
			If vQryResultRow.RoomTypeIsModularStructure <> Null And vQryResultRow.RoomTypeIsModularStructure Then
				vPage3Area.Parameters.mTotalModularGuestsRus = vQryResultRow.GuestsCountTurnover;
			EndIf;
		EndIf;
	EndDo;
	vPage3Area.Parameters.mTotalGuestsRus = vRussiaGuests;
	
	// Get total number of guest days and checked-in foreigner guests
	If vPage3Area.Parameters.mTotalGuestDays >= vPage3Area.Parameters.mTotalGuestDaysRus Then
		vPage3Area.Parameters.mTotalGuestDaysFor = vPage3Area.Parameters.mTotalGuestDays - vPage3Area.Parameters.mTotalGuestDaysRus;
	Else
		vPage3Area.Parameters.mTotalGuestDaysFor = 0;
	EndIf;
	If vPage3Area.Parameters.mTotalModularGuestDays >= vPage3Area.Parameters.mTotalModularGuestDaysRus Then
		vPage3Area.Parameters.mTotalModularGuestDaysFor = vPage3Area.Parameters.mTotalModularGuestDays - vPage3Area.Parameters.mTotalModularGuestDaysRus;
	Else
		vPage3Area.Parameters.mTotalModularGuestDaysFor = 0;
	EndIf;
	If vPage3Area.Parameters.mTotalGuests >= vPage3Area.Parameters.mTotalGuestsRus Then
		vPage3Area.Parameters.mTotalGuestsFor = vPage3Area.Parameters.mTotalGuests - vPage3Area.Parameters.mTotalGuestsRus;
	Else
		vPage3Area.Parameters.mTotalGuestsFor = 0;
	EndIf;
	If vPage3Area.Parameters.mTotalModularGuests >= vPage3Area.Parameters.mTotalModularGuestsRus Then
		vPage3Area.Parameters.mTotalModularGuestsFor = vPage3Area.Parameters.mTotalModularGuests - vPage3Area.Parameters.mTotalModularGuestsRus;
	Else
		vPage3Area.Parameters.mTotalModularGuestsFor = 0;
	EndIf;

	// Get total number of checked-in guests per report period

	// Data per report period
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ISNULL(RoomSales.RoomType.IsModularStructure, FALSE) AS RoomTypeIsModularStructure,
	|	SUM(ISNULL(RoomSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		RoomSalesTurnovers.RoomType AS RoomType,
	|		RoomSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection
	|					AND Hotel = &qHotel
	|					AND Company = &qCompany
 	|					AND (Room IN HIERARCHY (&qRoomParent)  
	|						OR &qEmptyRoomParent)
	|					AND (RoomType IN HIERARCHY (&qRoomTypeParent)  
	|						OR &qEmptyRoomTypeParent)
	|		) AS RoomSalesTurnovers) AS RoomSales
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
	vQry.SetParameter("qRoomParent", RoomParent);
	vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
	vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
	vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
	vQryResult = vQry.Execute().Unload();

	For Each vQryResultRow In vQryResult Do
		If vQryResultRow.GuestsCheckedInTurnover <> Null Then 
			vTotalGuestsCheckedIn = vTotalGuestsCheckedIn + vQryResultRow.GuestsCheckedInTurnover;

			If vQryResultRow.RoomTypeIsModularStructure <> Null And vQryResultRow.RoomTypeIsModularStructure Then
				vPage3Area.Parameters.mTotalModularGuestsCheckedIn = vQryResultRow.GuestsCheckedInTurnover;
			EndIf;
		EndIf;
	EndDo;

	vPage3Area.Parameters.mTotalGuestsCheckedIn = vTotalGuestsCheckedIn;
	
	// Get total number of checked-in guests from Russia
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ISNULL(GeoSales.RoomType.IsModularStructure, FALSE) AS RoomTypeIsModularStructure,
	|	SUM(ISNULL(GeoSales.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover
	|FROM
	|	(SELECT
	|		GeoSalesTurnovers.RoomType AS RoomType,
	|		GeoSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection
	|					AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND (Room IN HIERARCHY (&qRoomParent)  
	|						OR &qEmptyRoomParent)
	|					AND (RoomType IN HIERARCHY (&qRoomTypeParent)  
	|						OR &qEmptyRoomTypeParent)
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
	vQry.SetParameter("qRoomParent", RoomParent);
	vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
	vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
	vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
	vQryResult = vQry.Execute().Unload();

	vTotalGuestsCheckedInRus = 0;
	For Each vQryResultRow In vQryResult Do
		If vQryResultRow.GuestsCheckedInTurnover <> Null Then
			vTotalGuestsCheckedInRus = vTotalGuestsCheckedInRus + vQryResultRow.GuestsCheckedInTurnover;
			
			If vQryResultRow.RoomTypeIsModularStructure <> Null And vQryResultRow.RoomTypeIsModularStructure Then
				vPage3Area.Parameters.mTotalModularGuestsCheckedInRus = vQryResultRow.GuestsCheckedInTurnover;
			EndIf;
		EndIf;
	EndDo;
	vPage3Area.Parameters.mTotalGuestsCheckedInRus = vTotalGuestsCheckedInRus;
	
	If vPage3Area.Parameters.mTotalGuestsCheckedIn >= vPage3Area.Parameters.mTotalGuestsCheckedInRus Then
		vPage3Area.Parameters.mTotalGuestsCheckedInFor = vPage3Area.Parameters.mTotalGuestsCheckedIn - vPage3Area.Parameters.mTotalGuestsCheckedInRus;
	Else
		vPage3Area.Parameters.mTotalGuestsCheckedInFor = 0;
	EndIf;
	If vPage3Area.Parameters.mTotalModularGuestsCheckedIn >= vPage3Area.Parameters.mTotalModularGuestsCheckedInRus Then
		vPage3Area.Parameters.mTotalModularGuestsCheckedInFor = vPage3Area.Parameters.mTotalModularGuestsCheckedIn - vPage3Area.Parameters.mTotalModularGuestsCheckedInRus;
	Else
		vPage3Area.Parameters.mTotalModularGuestsCheckedInFor = 0;
	EndIf;
	
	// Get total number of checked-in guests with tour tickets
	vPage3Area.Parameters.mTotalTourTicketGuests = 0;
	If ValueIsFilled(TourTicketIncomeServiceGroup) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	ISNULL(RoomSales.RoomType.IsModularStructure, FALSE) AS RoomTypeIsModularStructure,
		|	COUNT(RoomSales.Client) AS GuestsCountTurnover,
		|	SUM(ISNULL(RoomSales.GuestDaysTurnover, 0)) AS GuestDaysTurnover
		|FROM
		|	(SELECT
		|		RoomSalesTurnovers.RoomType AS RoomType,
		|		RoomSalesTurnovers.Client AS Client,
		|		RoomSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover
		|	FROM
		|		AccumulationRegister.Sales.Turnovers(
		|				&qPeriodFrom,
		|				&qPeriodTo,
		|				Period,
		|				NOT IsCorrection
		|					AND Hotel = &qHotel
		|					AND Company = &qCompany 
		|					AND (Room IN HIERARCHY (&qRoomParent)  
		|						OR &qEmptyRoomParent)
		|					AND (RoomType IN HIERARCHY (&qRoomTypeParent)  
		|						OR &qEmptyRoomTypeParent)
		|					AND (Service IN HIERARCHY (&qTourTicketServices)
		|						OR NOT &qUseServicesList)) AS RoomSalesTurnovers
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
		vQry.SetParameter("qRoomParent", RoomParent);
		vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
		vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
		vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
		vUseServicesList = False;
		vServicesList = New ValueList();
		If Not TourTicketIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(TourTicketIncomeServiceGroup);
		EndIf;
		vQry.SetParameter("qUseServicesList", vUseServicesList);
		vQry.SetParameter("qTourTicketServices", vServicesList);
		vQryResult = vQry.Execute().Unload();

		vTotalTourTicketGuests = 0;
		For Each vQryResultRow In vQryResult Do
			If vQryResultRow.GuestsCountTurnover <> Null Then
				vTotalTourTicketGuests = vTotalTourTicketGuests + vQryResultRow.GuestsCountTurnover;
				
				If vQryResultRow.RoomTypeIsModularStructure <> Null And vQryResultRow.RoomTypeIsModularStructure Then
					vPage3Area.Parameters.mTotalModularTourTicketGuests = vQryResultRow.GuestsCountTurnover;
				EndIf;
			EndIf;
		EndDo;
		vPage3Area.Parameters.mTotalTourTicketGuests = vTotalTourTicketGuests;
		
		// The same from russia
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	ISNULL(RoomSales.RoomType.IsModularStructure, FALSE) AS RoomTypeIsModularStructure,
		|	COUNT(RoomSales.Client) AS GuestsCountTurnover,
		|	SUM(ISNULL(RoomSales.GuestDaysTurnover, 0)) AS GuestDaysTurnover
		|FROM
		|	(SELECT
		|		RoomSalesTurnovers.RoomType AS RoomType,
		|		RoomSalesTurnovers.Client AS Client,
		|		RoomSalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover
		|	FROM
		|		AccumulationRegister.Sales.Turnovers(
		|				&qPeriodFrom,
		|				&qPeriodTo,
		|				Period,
		|				NOT IsCorrection
		|					AND Hotel = &qHotel
		|					AND Company = &qCompany
	 	|					AND (Room IN HIERARCHY (&qRoomParent)  
		|						OR &qEmptyRoomParent)
		|					AND (RoomType IN HIERARCHY (&qRoomTypeParent)  
		|						OR &qEmptyRoomTypeParent)
		|					AND (Service IN HIERARCHY (&qTourTicketServices)
		|						OR NOT &qUseServicesList)
		|					AND (Client.Citizenship = &qRussia
		|						OR ISNULL(Client.Citizenship.Description, """") = """")) AS RoomSalesTurnovers
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
		vQry.SetParameter("qRussia", RussiaCountry);
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qCompany", Company);
		vQry.SetParameter("qRoomParent", RoomParent);
		vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
		vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
		vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
		vUseServicesList = False;
		vServicesList = New ValueList();
		If Not TourTicketIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(TourTicketIncomeServiceGroup);
		EndIf;
		vQry.SetParameter("qUseServicesList", vUseServicesList);
		vQry.SetParameter("qTourTicketServices", vServicesList);
		vQryResult = vQry.Execute().Unload();

		vTotalTourTicketGuestsRus = 0;
		For Each vQryResultRow In vQryResult Do
			If vQryResultRow.GuestsCountTurnover <> Null Then
				vTotalTourTicketGuestsRus = vTotalTourTicketGuestsRus + vQryResultRow.GuestsCountTurnover;
				
				If vQryResultRow.RoomTypeIsModularStructure <> Null And vQryResultRow.RoomTypeIsModularStructure Then
					vPage3Area.Parameters.mTotalModularTourTicketGuestsRus = vQryResultRow.GuestsCountTurnover;
				EndIf;
			EndIf;
		EndDo;
		vPage3Area.Parameters.mTotalTourTicketGuestsRus = vTotalTourTicketGuestsRus;

		If vPage3Area.Parameters.mTotalTourTicketGuests >= vPage3Area.Parameters.mTotalTourTicketGuestsRus Then
			vPage3Area.Parameters.mTotalTourTicketGuestsFor = vPage3Area.Parameters.mTotalTourTicketGuests - vPage3Area.Parameters.mTotalTourTicketGuestsRus;
		Else
			vPage3Area.Parameters.mTotalTourTicketGuestsFor = 0;
		EndIf;
		If vPage3Area.Parameters.mTotalModularTourTicketGuests >= vPage3Area.Parameters.mTotalModularTourTicketGuestsRus Then
			vPage3Area.Parameters.mTotalModularTourTicketGuestsFor = vPage3Area.Parameters.mTotalModularTourTicketGuests - vPage3Area.Parameters.mTotalModularTourTicketGuestsRus;
		Else
			vPage3Area.Parameters.mTotalModularTourTicketGuestsFor = 0;
		EndIf;
	EndIf;

	// Get meal board sales
	vPage3Area.Parameters.mTotalMealsWithoutVAT = 0;
	vPage3Area.Parameters.mTotalModularMealsWithoutVAT = 0;
	If ValueIsFilled(MealIncomeServiceGroup) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	ISNULL(RoomSalesTurnovers.RoomType.IsModularStructure, FALSE) AS RoomTypeIsModularStructure,
		|	SUM(RoomSalesTurnovers.SalesWithoutVATTurnover) AS SalesWithoutVATTurnover
		|FROM
		|	AccumulationRegister.Sales.Turnovers(
		|			&qPeriodFrom,
		|			&qPeriodTo,
		|			Period,
		|			NOT IsCorrection 
		|				AND Hotel = &qHotel
		|				AND Company = &qCompany
		|					AND (Room IN HIERARCHY (&qRoomParent)  
		|						OR &qEmptyRoomParent)
		|					AND (RoomType IN HIERARCHY (&qRoomTypeParent)  
		|						OR &qEmptyRoomTypeParent)
		|				AND (Service IN HIERARCHY (&qMealsServices)
		|					OR (NOT &qUseServicesList))) AS RoomSalesTurnovers
		|GROUP BY
		|	ISNULL(RoomSalesTurnovers.RoomType.IsModularStructure, FALSE)
		|ORDER BY
		|	RoomTypeIsModularStructure";
		vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
		vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qCompany", Company);
		vQry.SetParameter("qRoomParent", RoomParent);
		vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
		vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
		vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
		vUseServicesList = False;
		vServicesList = New ValueList();
		If Not MealIncomeServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(MealIncomeServiceGroup);
		EndIf;
		vQry.SetParameter("qUseServicesList", vUseServicesList);
		vQry.SetParameter("qMealsServices", vServicesList);
		vQryResult = vQry.Execute().Unload();

		vTotalMealsWithoutVAT = 0;
		For Each vQryResultRow In vQryResult Do
			If vQryResultRow.SalesWithoutVATTurnover <> Null Then
				vTotalMealsWithoutVAT = vTotalMealsWithoutVAT + vQryResultRow.SalesWithoutVATTurnover;
				
				If vQryResultRow.RoomTypeIsModularStructure <> Null And vQryResultRow.RoomTypeIsModularStructure Then
					vPage3Area.Parameters.mTotalModularMealsWithoutVAT = Round(vQryResultRow.SalesWithoutVATTurnover/1000, 0);
				EndIf;
			EndIf;
		EndDo;
		vPage3Area.Parameters.mTotalMealsWithoutVAT = Round(vTotalMealsWithoutVAT/1000, 0);
	EndIf;
	
	// Get extras sales
	If vPage3Area.Parameters.mTotalSalesWithoutVAT >= (vPage3Area.Parameters.mTotalRoomRevenueWithoutVAT + vPage3Area.Parameters.mTotalMealsWithoutVAT) Then
		vPage3Area.Parameters.mTotalExtraWithoutVAT = vPage3Area.Parameters.mTotalSalesWithoutVAT - (vPage3Area.Parameters.mTotalRoomRevenueWithoutVAT + vPage3Area.Parameters.mTotalMealsWithoutVAT);
	Else	
		vPage3Area.Parameters.mTotalExtraWithoutVAT = 0;
	EndIf;
	If vPage3Area.Parameters.mTotalModularSalesWithoutVAT >= (vPage3Area.Parameters.mTotalModularRoomRevenueWithoutVAT + vPage3Area.Parameters.mTotalModularMealsWithoutVAT) Then
		vPage3Area.Parameters.mTotalModularExtraWithoutVAT = vPage3Area.Parameters.mTotalModularSalesWithoutVAT - (vPage3Area.Parameters.mTotalModularRoomRevenueWithoutVAT + vPage3Area.Parameters.mTotalModularMealsWithoutVAT);
	Else	
		vPage3Area.Parameters.mTotalModularExtraWithoutVAT = 0;
	EndIf;
	
	pSpreadsheet.Put(vPage3Area);
	WriteAreaParametersIntoReportParameters(vPage3Area.Parameters, New Structure(
		"mModularRoomsSold	,
		|mNewModularRooms	,
		|mNewRooms	,
		|mRoomsSold	,
		|mTotalBeds	,
		|mTotalExtraWithoutVAT	,
		|mTotalGuestDays	,
		|mTotalGuestDaysFor	,
		|mTotalGuestDaysRus	,
		|mTotalGuests	,
		|mTotalGuestsCheckedIn	,
		|mTotalGuestsCheckedInFor	,
		|mTotalGuestsCheckedInRus	,
		|mTotalGuestsFor	,
		|mTotalGuestsRus	,
		|mTotalMealsWithoutVAT	,
		|mTotalModularBeds	,
		|mTotalModularExtraWithoutVAT	,
		|mTotalModularGuestDays	,
		|mTotalModularGuestDaysFor	,
		|mTotalModularGuestDaysRus	,
		|mTotalModularGuests	,
		|mTotalModularGuestsCheckedIn	,
		|mTotalModularGuestsCheckedInFor	,
		|mTotalModularGuestsCheckedInRus	,
		|mTotalModularGuestsFor	,
		|mTotalModularGuestsRus	,
		|mTotalModularMealsWithoutVAT	,
		|mTotalModularRoomRevenueWithoutVAT	,
		|mTotalModularRooms	,
		|mTotalModularSalesWithoutVAT	,
		|mTotalModularTourTicketGuests	,
		|mTotalModularTourTicketGuestsFor	,
		|mTotalModularTourTicketGuestsRus	,
		|mTotalRoomRevenueWithoutVAT	,
		|mTotalRooms	,
		|mTotalSalesWithoutVAT	,
		|mTotalTopModularRooms	,
		|mTotalTopRooms	,
		|mTotalTourTicketGuests	,
		|mTotalTourTicketGuestsFor	,
		|mTotalTourTicketGuestsRus"));	
	// Print page 4 and 5 for end of quarters only	
	If Month(PeriodTo) = 3 Or Month(PeriodTo) = 6 Or Month(PeriodTo) = 9 Or Month(PeriodTo) = 12 Then
		
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
		|		ELSE 406
		|	END AS PeriodNumber,
		|	GeoSales.Country AS Country,
		|	ISNULL(GeoSales.Country.Code, """") AS CountryCode,
		|	CASE
		|		WHEN GeoSales.TripPurpose = &qBusiness
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qCommerce
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qOfficial
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qWork
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qScientific
		|			THEN 2
		|		WHEN GeoSales.TripPurpose = &qCrewman
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qHumanitarian
		|			THEN 6
		|		WHEN GeoSales.TripPurpose = &qTourism
		|			THEN 1
		|		WHEN GeoSales.TripPurpose = &qBeachRecreation
		|			THEN 2
		|		WHEN GeoSales.TripPurpose = &qCulturalAndEducational
		|			THEN 3
		|		WHEN GeoSales.TripPurpose = &qCruiseTourism
		|			THEN 4
		|		WHEN GeoSales.TripPurpose = &qPrivate
		|			THEN 6
		|		WHEN GeoSales.TripPurpose = &qStudy
		|			THEN 2
		|		WHEN GeoSales.TripPurpose = &qRecreation
		|			THEN 3
		|		WHEN GeoSales.TripPurpose = &qPilgrims
		|			THEN 4
		|		WHEN GeoSales.TripPurpose = &qTransit
		|			THEN 1
		|		WHEN GeoSales.TripPurpose = &qOther
		|			THEN 6
		|		ELSE 6
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
		|				&qEmptyDate,
		|				&qPeriodTo,
		|				Period,
		|				NOT IsCorrection
		|					AND Hotel = &qHotel
		|					AND Company = &qCompany 
		|					AND (Room IN HIERARCHY (&qRoomParent)  
		|						OR &qEmptyRoomParent)
		|					AND (RoomType IN HIERARCHY (&qRoomTypeParent)  
		|						OR &qEmptyRoomTypeParent)
		|					AND (Client.Citizenship <> &qRussia
		|						AND ISNULL(Client.Citizenship.Description, """") <> """")
		|					AND NOT ParentDoc.CheckInDate IS NULL
		|					AND ParentDoc.CheckInDate < &qPeriodTo
		|					AND ParentDoc.CheckOutDate > &qPeriodFrom) AS GeoSalesTurnovers
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
		|		ELSE 406
		|	END,
		|	GeoSales.Country,
		|	ISNULL(GeoSales.Country.Code, """"),
		|	CASE
		|		WHEN GeoSales.TripPurpose = &qBusiness
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qCommerce
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qOfficial
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qWork
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qScientific
		|			THEN 2
		|		WHEN GeoSales.TripPurpose = &qCrewman
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qHumanitarian
		|			THEN 6
		|		WHEN GeoSales.TripPurpose = &qTourism
		|			THEN 1
		|		WHEN GeoSales.TripPurpose = &qBeachRecreation
		|			THEN 2
		|		WHEN GeoSales.TripPurpose = &qCulturalAndEducational
		|			THEN 3
		|		WHEN GeoSales.TripPurpose = &qCruiseTourism
		|			THEN 4
		|		WHEN GeoSales.TripPurpose = &qPrivate
		|			THEN 6
		|		WHEN GeoSales.TripPurpose = &qStudy
		|			THEN 2
		|		WHEN GeoSales.TripPurpose = &qRecreation
		|			THEN 3
		|		WHEN GeoSales.TripPurpose = &qPilgrims
		|			THEN 4
		|		WHEN GeoSales.TripPurpose = &qTransit
		|			THEN 1
		|		WHEN GeoSales.TripPurpose = &qOther
		|			THEN 6
		|		ELSE 6
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
		vQry.SetParameter("qEmptyDate", '00010101');
		vQry.SetParameter("qPeriodFrom", BegOfQuarter(PeriodFrom));
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
		vQry.SetParameter("qPilgrims", Catalogs.TripPurposes.Pilgrims);
		vQry.SetParameter("qTransit", Catalogs.TripPurposes.Transit);
		vQry.SetParameter("qOther", Catalogs.TripPurposes.Other);
		vQry.SetParameter("qCompany", Company);
		vQry.SetParameter("qRoomParent", RoomParent);
		vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
		vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
		vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
		vQryResult = vQry.Execute();
		
		vPeriodsList = New ValueList();
		vPeriodsList.Add(401, "Без ночевки - всего");
		vPeriodsList.Add(402, "1 - 4 ночевки - всего");
		vPeriodsList.Add(403, "5 - 7 ночевок - всего");
		vPeriodsList.Add(404, "8 - 14 ночевок - всего");
		vPeriodsList.Add(405, "15 - 28 ночевок - всего");
		vPeriodsList.Add(406, "29 - 91 ночевок - всего");
		
		vTotalGuests1 = 0;
		vTotalGuests2 = 0;
		vTotalGuests3 = 0;
		vTotalGuests4 = 0;
		vTotalGuests6 = 0;
		vTotalGuests7 = 0;
		vTotalGuests = 0;
		
		//SavedReportParameters = ValueFromStringInternal(ValueToStringInternal(ReportParameters));
		//ReportParameters = New Structure;
		vPage4Periods = New Array;
		
		
		
		For Each vPeriodsListItem In vPeriodsList Do
			vPage4PArea.Parameters.mPeriodName = vPeriodsListItem.Presentation;
			vPage4PArea.Parameters.mRowNumber = vPeriodsListItem.Value;
			
			vGuests1 = 0;
			vGuests2 = 0;
			vGuests3 = 0;
			vGuests4 = 0;
			vGuests6 = 0;
			vGuests7 = 0;
			vGuestsTotal = 0;
			
			vPage4Periods.Add(New Structure("mPeriodName, mRowNumber, mRowContent, mRowsArray",vPeriodsListItem.Presentation, vPeriodsListItem.Value, Undefined, New Array)); 
			
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
						ElsIf vTotalsByTripType.TripPurposeType = 6 Then
							vGuests6 = vTotalsByTripType.GuestsCheckedInTurnover;
						ElsIf vTotalsByTripType.TripPurposeType = 7 Then
							vGuests7 = vTotalsByTripType.GuestsCheckedInTurnover;
						EndIf;
						vGuestsTotal = vGuestsTotal + vTotalsByTripType.GuestsCheckedInTurnover;
					EndDo;
					
					vPage4PArea.Parameters.mGuestsTourists = vGuests1;
					vPage4PArea.Parameters.mGuestsEducation = vGuests2;
					vPage4PArea.Parameters.mGuestsRecreation = vGuests3;
					vPage4PArea.Parameters.mGuestsPilgrims = vGuests4;
					vPage4PArea.Parameters.mGuestsPrivateOther = vGuests6;
					vPage4PArea.Parameters.mGuestsBusiness = vGuests7;
					vPage4PArea.Parameters.mGuestsTotal = vGuestsTotal;
					
					pSpreadsheet.Put(vPage4PArea);
					vPage4Periods[vPage4Periods.UBound()].mRowContent = WriteAreaParametersIntoStructure(vPage4PArea.Parameters, New Structure(
						"mGuestsBusiness	,
						|mGuestsEducation	,
						|mGuestsPilgrims	,
						|mGuestsPrivateOther	,
						|mGuestsRecreation	,
						|mGuestsTotal	,
						|mGuestsTourists	,
						|mPeriodName	,
						|mRowNumber"));						
					
					vTotalGuests1 = vTotalGuests1 + vGuests1;
					vTotalGuests2 = vTotalGuests2 + vGuests2;
					vTotalGuests3 = vTotalGuests3 + vGuests3;
					vTotalGuests4 = vTotalGuests4 + vGuests4;
					vTotalGuests6 = vTotalGuests6 + vGuests6;
					vTotalGuests7 = vTotalGuests7 + vGuests7;
					vTotalGuests = vTotalGuests + vGuestsTotal;
					
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
						vGuests6 = 0;
						vGuests7 = 0;
						vGuestsTotal = 0;
						
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
							ElsIf vTotalsByTripType.TripPurposeType = 6 Then
								vGuests6 = vTotalsByTripType.GuestsCheckedInTurnover;
							ElsIf vTotalsByTripType.TripPurposeType = 7 Then
								vGuests7 = vTotalsByTripType.GuestsCheckedInTurnover;
							EndIf;
							vGuestsTotal = vGuestsTotal + vTotalsByTripType.GuestsCheckedInTurnover;
						EndDo;
						
						vPage4CArea.Parameters.mCountry = TrimAll(vTotalsByCountry.Country);
						vPage4CArea.Parameters.mCountryCode = TrimAll(vTotalsByCountry.Country.Code);
						
						vPage4CArea.Parameters.mGuestsTourists = vGuests1;
						vPage4CArea.Parameters.mGuestsEducation = vGuests2;
						vPage4CArea.Parameters.mGuestsRecreation = vGuests3;
						vPage4CArea.Parameters.mGuestsPilgrims = vGuests4;
						vPage4CArea.Parameters.mGuestsPrivateOther = vGuests6;
						vPage4CArea.Parameters.mGuestsBusiness = vGuests7;
						vPage4CArea.Parameters.mGuestsTotal = vGuestsTotal;
						
						pSpreadsheet.Put(vPage4CArea);
						
						vPage4Periods[vPage4Periods.UBound()].mRowsArray.Add(WriteAreaParametersIntoStructure(vPage4CArea.Parameters, New Structure(
							"mCountry	,
							|mCountryCode	,
							|mGuestsBusiness	,
							|mGuestsEducation	,
							|mGuestsPilgrims	,
							|mGuestsPrivateOther	,
							|mGuestsRecreation	,
							|mGuestsTotal	,
							|mGuestsTourists	")));
						
					EndDo;
				EndIf;
			EndDo;
		EndDo;
		
		vPage4TArea.Parameters.mGuestsTourists = vTotalGuests1;
		vPage4TArea.Parameters.mGuestsEducation = vTotalGuests2;
		vPage4TArea.Parameters.mGuestsRecreation = vTotalGuests3;
		vPage4TArea.Parameters.mGuestsPilgrims = vTotalGuests4;
		vPage4TArea.Parameters.mGuestsPrivateOther = vTotalGuests6;
		vPage4TArea.Parameters.mGuestsBusiness = vTotalGuests7;
		vPage4TArea.Parameters.mGuestsTotal = vTotalGuests;
		
		pSpreadsheet.Put(vPage4TArea);

		vPage4Periods.Add(New Structure("mPeriodName, mRowNumber, mRowContent, mRowsArray", "Периоды итог", 407, 
			WriteAreaParametersIntoStructure(vPage4TArea.Parameters, New Structure(
			"mGuestsBusiness	,
			|mGuestsEducation	,
			|mGuestsPilgrims	,
			|mGuestsPrivateOther	,
			|mGuestsRecreation	,
			|mGuestsTotal	,
			|mGuestsTourists")), New Array));
		
		// By countries
		vTotalsByCountry = vQryResult.Select(QueryResultIteration.ByGroups, "Country");
		While vTotalsByCountry.Next() Do
			If Not ValueIsFilled(vTotalsByCountry.Country) Then
				Continue;
			EndIf;

			vGuests1 = 0;
			vGuests2 = 0;
			vGuests3 = 0;
			vGuests4 = 0;
			vGuests6 = 0;
			vGuests7 = 0;
			vGuestsTotal = 0;
			
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
				ElsIf vTotalsByTripType.TripPurposeType = 6 Then
					vGuests6 = vTotalsByTripType.GuestsCheckedInTurnover;
				ElsIf vTotalsByTripType.TripPurposeType = 7 Then
					vGuests7 = vTotalsByTripType.GuestsCheckedInTurnover;
				EndIf;
				vGuestsTotal = vGuestsTotal + vTotalsByTripType.GuestsCheckedInTurnover;
			EndDo;
			
			vPage4CArea.Parameters.mCountry = TrimAll(vTotalsByCountry.Country);
			vPage4CArea.Parameters.mCountryCode = TrimAll(vTotalsByCountry.Country.Code);
			
			vPage4CArea.Parameters.mGuestsTourists = vGuests1;
			vPage4CArea.Parameters.mGuestsEducation = vGuests2;
			vPage4CArea.Parameters.mGuestsRecreation = vGuests3;
			vPage4CArea.Parameters.mGuestsPilgrims = vGuests4;
			vPage4CArea.Parameters.mGuestsPrivateOther = vGuests6;
			vPage4CArea.Parameters.mGuestsBusiness = vGuests7;
			vPage4CArea.Parameters.mGuestsTotal = vGuestsTotal;
			
			pSpreadsheet.Put(vPage4CArea);

			vPage4Periods[vPage4Periods.UBound()].mRowsArray.Add(WriteAreaParametersIntoStructure(vPage4CArea.Parameters, New Structure(
				"mCountry,
				|mCountryCode,
				|mGuestsBusiness,
				|mGuestsEducation,
				|mGuestsPilgrims,
				|mGuestsPrivateOther,
				|mGuestsRecreation,
				|mGuestsTotal,
				|mGuestsTourists")));
			
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
		|		ELSE 506
		|	END AS PeriodNumber,
		|	CASE
		|		WHEN GeoSales.TripPurpose = &qBusiness
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qCommerce
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qOfficial
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qWork
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qScientific
		|			THEN 2
		|		WHEN GeoSales.TripPurpose = &qCrewman
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qHumanitarian
		|			THEN 6
		|		WHEN GeoSales.TripPurpose = &qTourism
		|			THEN 1
		|		WHEN GeoSales.TripPurpose = &qBeachRecreation
		|			THEN 2
		|		WHEN GeoSales.TripPurpose = &qCulturalAndEducational
		|			THEN 3
		|		WHEN GeoSales.TripPurpose = &qCruiseTourism
		|			THEN 4
		|		WHEN GeoSales.TripPurpose = &qPrivate
		|			THEN 6
		|		WHEN GeoSales.TripPurpose = &qStudy
		|			THEN 2
		|		WHEN GeoSales.TripPurpose = &qRecreation
		|			THEN 3
		|		WHEN GeoSales.TripPurpose = &qPilgrims
		|			THEN 4
		|		WHEN GeoSales.TripPurpose = &qTransit
		|			THEN 1
		|		WHEN GeoSales.TripPurpose = &qOther
		|			THEN 6
		|		ELSE 6
		|	END AS TripPurposeType,
		|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
		|FROM
		|	(SELECT
		|		ISNULL(GeoSalesTurnovers.ParentDoc.Duration, 0) AS Duration,
		|		GeoSalesTurnovers.TripPurpose AS TripPurpose,
		|		SUM(GeoSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
		|	FROM
		|		AccumulationRegister.Sales.Turnovers(
		|				&qEmptyDate,
		|				&qPeriodTo,
		|				Period,
		|				NOT IsCorrection
		|					AND Hotel = &qHotel
		|					AND Company = &qCompany  
		|					AND (Room IN HIERARCHY (&qRoomParent)  
		|						OR &qEmptyRoomParent)
		|					AND (RoomType IN HIERARCHY (&qRoomTypeParent)  
		|						OR &qEmptyRoomTypeParent)
		|					AND (Client.Citizenship = &qRussia
		|						OR ISNULL(Client.Citizenship.Description, """") = """")
		|					AND NOT ParentDoc.CheckInDate IS NULL
		|					AND ParentDoc.CheckInDate < &qPeriodTo
		|					AND ParentDoc.CheckOutDate > &qPeriodFrom) AS GeoSalesTurnovers
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
		|		ELSE 506
		|	END,
		|	CASE
		|		WHEN GeoSales.TripPurpose = &qBusiness
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qCommerce
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qOfficial
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qWork
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qScientific
		|			THEN 2
		|		WHEN GeoSales.TripPurpose = &qCrewman
		|			THEN 7
		|		WHEN GeoSales.TripPurpose = &qHumanitarian
		|			THEN 6
		|		WHEN GeoSales.TripPurpose = &qTourism
		|			THEN 1
		|		WHEN GeoSales.TripPurpose = &qBeachRecreation
		|			THEN 2
		|		WHEN GeoSales.TripPurpose = &qCulturalAndEducational
		|			THEN 3
		|		WHEN GeoSales.TripPurpose = &qCruiseTourism
		|			THEN 4
		|		WHEN GeoSales.TripPurpose = &qPrivate
		|			THEN 6
		|		WHEN GeoSales.TripPurpose = &qStudy
		|			THEN 2
		|		WHEN GeoSales.TripPurpose = &qRecreation
		|			THEN 3
		|		WHEN GeoSales.TripPurpose = &qPilgrims
		|			THEN 4
		|		WHEN GeoSales.TripPurpose = &qTransit
		|			THEN 1
		|		WHEN GeoSales.TripPurpose = &qOther
		|			THEN 6
		|		ELSE 6
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
		vQry.SetParameter("qEmptyDate", '00010101');
		vQry.SetParameter("qPeriodFrom", BegOfQuarter(PeriodFrom));
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
		vQry.SetParameter("qPilgrims", Catalogs.TripPurposes.Pilgrims);
		vQry.SetParameter("qTransit", Catalogs.TripPurposes.Transit);
		vQry.SetParameter("qOther", Catalogs.TripPurposes.Other);
		vQry.SetParameter("qCompany", Company);
		vQry.SetParameter("qRoomParent", RoomParent);
		vQry.SetParameter("qEmptyRoomParent", ?(RoomParent = Undefined,  True, False));
		vQry.SetParameter("qRoomTypeParent", RoomTypeParent);
		vQry.SetParameter("qEmptyRoomTypeParent", ?(RoomTypeParent = Undefined,  True, False));
		vQryResult = vQry.Execute();
		
		vPeriodsList = New ValueList();
		vPeriodsList.Add(501, "Без ночевки - всего");
		vPeriodsList.Add(502, "1 - 4 ночевки - всего");
		vPeriodsList.Add(503, "5 - 7 ночевок - всего");
		vPeriodsList.Add(504, "8 - 14 ночевок - всего");
		vPeriodsList.Add(505, "15 - 28 ночевок - всего");
		vPeriodsList.Add(506, "29 - 91 ночевок - всего");
		
		vTotalGuests1 = 0;
		vTotalGuests2 = 0;
		vTotalGuests3 = 0;
		vTotalGuests4 = 0;
		vTotalGuests6 = 0;
		vTotalGuests7 = 0;
		vTotalGuests = 0;
		
		vPage5Periods = New Array;
		
		For Each vPeriodsListItem In vPeriodsList Do
			vPage5PArea.Parameters.mPeriodName = vPeriodsListItem.Presentation;
			vPage5PArea.Parameters.mRowNumber = vPeriodsListItem.Value;
			
			vGuests1 = 0;
			vGuests2 = 0;
			vGuests3 = 0;
			vGuests4 = 0;
			vGuests6 = 0;
			vGuests7 = 0;
			vGuestsTotal = 0;
			
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
						ElsIf vTotalsByTripType.TripPurposeType = 6 Then
							vGuests6 = vTotalsByTripType.GuestsCheckedInTurnover;
						ElsIf vTotalsByTripType.TripPurposeType = 7 Then
							vGuests7 = vTotalsByTripType.GuestsCheckedInTurnover;
						EndIf;
						vGuestsTotal = vGuestsTotal + vTotalsByTripType.GuestsCheckedInTurnover;
					EndDo;
					
					vPage5PArea.Parameters.mGuestsTourists = vGuests1;
					vPage5PArea.Parameters.mGuestsEducation = vGuests2;
					vPage5PArea.Parameters.mGuestsRecreation = vGuests3;
					vPage5PArea.Parameters.mGuestsPilgrims = vGuests4;
					vPage5PArea.Parameters.mGuestsPrivateOther = vGuests6;
					vPage5PArea.Parameters.mGuestsBusiness = vGuests7;
					vPage5PArea.Parameters.mGuestsTotal = vGuestsTotal;
					
					pSpreadsheet.Put(vPage5PArea);
					
					vPage5Periods.Add(WriteAreaParametersIntoStructure(vPage5PArea.Parameters, New Structure(
						"mGuestsBusiness	,
						|mGuestsEducation	,
						|mGuestsPilgrims	,
						|mGuestsPrivateOther	,
						|mGuestsRecreation	,
						|mGuestsTotal	,
						|mGuestsTourists	,
						|mPeriodName	,
						|mRowNumber")));
					
					vTotalGuests1 = vTotalGuests1 + vGuests1;
					vTotalGuests2 = vTotalGuests2 + vGuests2;
					vTotalGuests3 = vTotalGuests3 + vGuests3;
					vTotalGuests4 = vTotalGuests4 + vGuests4;
					vTotalGuests6 = vTotalGuests6 + vGuests6;
					vTotalGuests7 = vTotalGuests7 + vGuests7;
					vTotalGuests = vTotalGuests + vGuestsTotal;
				EndIf;
			EndDo;
		EndDo;
		
		vPage5TArea.Parameters.mGuestsTourists = vTotalGuests1;
		vPage5TArea.Parameters.mGuestsEducation = vTotalGuests2;
		vPage5TArea.Parameters.mGuestsRecreation = vTotalGuests3;
		vPage5TArea.Parameters.mGuestsPilgrims = vTotalGuests4;
		vPage5TArea.Parameters.mGuestsPrivateOther = vTotalGuests6;
		vPage5TArea.Parameters.mGuestsBusiness = vTotalGuests7;
		vPage5TArea.Parameters.mGuestsTotal = vTotalGuests;
		
		// Page 5 totals (507)
		pSpreadsheet.Put(vPage5TArea);
		
		vPage5Periods.Add(WriteAreaParametersIntoStructure(vPage5TArea.Parameters, New Structure(
			"mGuestsBusiness	,
			|mGuestsEducation	,
			|mGuestsPilgrims	,
			|mGuestsPrivateOther	,
			|mGuestsRecreation	,
			|mGuestsTotal	,
			|mGuestsTourists, mRowNumber")));
		vPage5Periods[vPage5Periods.Ubound()].mRowNumber = 507;
		
		// Page 5 footer
		pSpreadsheet.Put(vPage5FArea);
	EndIf; // End of quarter
	
	// Report footer
	pSpreadsheet.Put(vReportFArea);
	
	ReportParameters.Insert("mPage4", vPage4Periods);
	ReportParameters.Insert("mPage5", vPage5Periods);

EndProcedure // pmGenerate2025

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
// Unload report data to XML-file
// -----------------------------------------------------------------------------
Procedure pmUnloadToXML(pParameter = Undefined, pIsInteractive = False, pAddressStorage = "", pFormUUID ) Export
	
	vPath = cmGetFullFileName("KSR", TempFilesDir());
	DeleteFiles(vPath);
	CreateDirectory(vPath);
	
	Try
			vFullFilePath = vPath + "\" + "KSRMainIndicators" + ".xml";
			vSections = MainIndicatorsReportSections();
			vReportDetails = MainIndicatorsReportDetails();
			pAddressStorage = WriteReportXML(vFullFilePath, pFormUUID, vSections, vReportDetails);
	Except
		vMessage = BriefErrorDescription(ErrorInfo());
		tcCommonFunctionOnClientServer.UserMessage(vMessage);	
	EndTry;
	
EndProcedure // pmUnloadToXML

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
Function MainIndicatorsReportDetails() Export
	
	vReportDetails = New Structure;
	vReportDetails.Insert("code", "0609407");
	vReportDetails.Insert("form", "004");
	vReportDetails.Insert("shifr", "to_1ksrOD");
	vReportDetails.Insert("year", Format(PeriodTo, "DF=yyyy"));
	vReportDetails.Insert("period",  Format(PeriodTo, "DF=12MM"));
	MainIndicatorsReportVersion = '20241210';
	vReportDetails.Insert("version", Format(MainIndicatorsReportVersion, "DF=dd-MM-yyyy"));
	
	Return vReportDetails;
	
EndFunction // MainIndicatorsReportDetails

// -----------------------------------------------------------------------------
// 
// Returns:
//  Array - Main Indicators report sections.
//
//#Region MainIndicatorsReportSections
Function MainIndicatorsReportSections()
	
	vSections = New Array;
	
	// Table 1
	vSection0 = New ValueTable;
	vSection0.Columns.Add("code");
	vSection0.Columns.Add("_1");
	
	vNewRow = vSection0.Add();
	vNewRow.code = KSRType();
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
	vNewRow._2 = ReportParameters.mTotalTopModularRooms;
	
	vNewRow = vSection1.Add();
	vNewRow.code = "203";
	vNewRow._1 = ReportParameters.mNewRooms;
	vNewRow._2 = ReportParameters.mNewModularRooms;
	
	vNewRow = vSection1.Add();
	vNewRow.code = "204";
	vNewRow._1 = ReportParameters.mRoomsSold;
	vNewRow._2 = ReportParameters.mModularRoomsSold;
	
	vNewRow = vSection1.Add();
	vNewRow.code = "205";
	vNewRow._1 = ReportParameters.mTotalBeds;
	vNewRow._2 = ReportParameters.mTotalModularBeds;
	
	vSections.Add(vSection1);
	
	// Table 3
	vSection2 = New ValueTable;
	vSection2.Columns.Add("code");
	vSection2.Columns.Add("_1");
	vSection2.Columns.Add("_2");
	
	vNewRow = vSection2.Add();
	vNewRow.code = "301";
	vNewRow._1 = ReportParameters.mTotalGuestDays;
	vNewRow._2 = ReportParameters.mTotalModularGuestDays;					
	
	vNewRow = vSection2.Add();
	vNewRow.code = "302";
	vNewRow._1 = ReportParameters.mTotalGuestDaysRus;
	vNewRow._2 = ReportParameters.mTotalModularGuestDaysRus;
	
	vNewRow = vSection2.Add();
	vNewRow.code = "303";
	vNewRow._1 = ReportParameters.mTotalGuestDaysFor;
	vNewRow._2 = ReportParameters.mTotalModularGuestDaysFor;					
	
	vNewRow = vSection2.Add();
	vNewRow.code = "304";
	vNewRow._1 = ReportParameters.mTotalGuests;
	vNewRow._2 = ReportParameters.mTotalModularGuests;					
	
	vNewRow = vSection2.Add();
	vNewRow.code = "305";
	vNewRow._1 = ReportParameters.mTotalGuestsRus;
	vNewRow._2 = ReportParameters.mTotalModularGuestsRus;					
	
	vNewRow = vSection2.Add();
	vNewRow.code = "306";
	vNewRow._1 = ReportParameters.mTotalGuestsFor;
	vNewRow._2 = ReportParameters.mTotalModularGuestsFor;
	
	vNewRow = vSection2.Add();
	vNewRow.code = "307";
	vNewRow._1 = ReportParameters.mTotalTourTicketGuests;
	vNewRow._2 = ReportParameters.mTotalModularTourTicketGuests;					
	
	vNewRow = vSection2.Add();
	vNewRow.code = "308";
	vNewRow._1 = ReportParameters.mTotalTourTicketGuestsRus;
	vNewRow._2 = ReportParameters.mTotalModularTourTicketGuestsRus;
	
	vNewRow = vSection2.Add();
	vNewRow.code = "309";
	vNewRow._1 = ReportParameters.mTotalTourTicketGuestsFor;
	vNewRow._2 = ReportParameters.mTotalModularTourTicketGuestsFor;
	
	vNewRow = vSection2.Add();
	vNewRow.code = "310";
	vNewRow._1 = ReportParameters.mTotalGuestsCheckedIn;
	vNewRow._2 = ReportParameters.mTotalModularTourTicketGuestsFor;
	
	vNewRow = vSection2.Add();
	vNewRow.code = "311";
	vNewRow._1 = ReportParameters.mTotalGuestsCheckedInRus;
	vNewRow._2 = ReportParameters.mTotalModularGuestsCheckedInRus;
	
	vNewRow = vSection2.Add();
	vNewRow.code = "312";
	vNewRow._1 = ReportParameters.mTotalGuestsCheckedInFor;
	vNewRow._2 = ReportParameters.mTotalModularGuestsCheckedInFor;
	
	vNewRow = vSection2.Add();
	vNewRow.code = "313";
	vNewRow._1 = ReportParameters.mTotalSalesWithoutVAT;
	vNewRow._2 = ReportParameters.mTotalModularSalesWithoutVAT					;
	
	vNewRow = vSection2.Add();
	vNewRow.code = "314";
	vNewRow._1 = ReportParameters.mTotalRoomRevenueWithoutVAT;
	vNewRow._2 = ReportParameters.mTotalModularRoomRevenueWithoutVAT;
	
	vNewRow = vSection2.Add();
	vNewRow.code = "315";
	vNewRow._1 = ReportParameters.mTotalMealsWithoutVAT;
	vNewRow._2 = ReportParameters.mTotalModularMealsWithoutVAT;
	
	vNewRow = vSection2.Add();
	vNewRow.code = "316";
	vNewRow._1 = ReportParameters.mTotalExtraWithoutVAT;
	vNewRow._2 = ReportParameters.mTotalModularExtraWithoutVAT;
	
	vSections.Add(vSection2);
	
	// Table 4
	vSection3 = New ValueTable;
	vSection3.Columns.Add("code");
	vSection3.Columns.Add("s1");
	vSection3.Columns.Add("_1");
	vSection3.Columns.Add("_2");
	vSection3.Columns.Add("_3");
	vSection3.Columns.Add("_4");
	vSection3.Columns.Add("_5");
	vSection3.Columns.Add("_6");
	vSection3.Columns.Add("_7");
	
	// Table 5
	vSection4 = New ValueTable;
	vSection4.Columns.Add("code");
	vSection4.Columns.Add("_1");
	vSection4.Columns.Add("_2");
	vSection4.Columns.Add("_3");
	vSection4.Columns.Add("_4");
	vSection4.Columns.Add("_5");
	vSection4.Columns.Add("_6");
	vSection4.Columns.Add("_7");

	If Month(PeriodTo) = 3 Or Month(PeriodTo) = 6 Or Month(PeriodTo) = 9 Or Month(PeriodTo) = 12 Then

		For Each vPageItem In ReportParameters.mPage4 Do

			If ValueIsFilled(vPageItem.mRowContent) Then
				
				vNewRow = vSection3.Add();
				vNewRow.code = String(vPageItem.mRowNumber);
				vNewRow.s1 = "1900";
				vNewRow._1 = vPageItem.mRowContent.mGuestsTourists;
				vNewRow._2 = vPageItem.mRowContent.mGuestsEducation;
				vNewRow._3 = vPageItem.mRowContent.mGuestsRecreation;
				vNewRow._4 = vPageItem.mRowContent.mGuestsPilgrims;
				vNewRow._5 = vPageItem.mRowContent.mGuestsPrivateOther;
				vNewRow._6 = vPageItem.mRowContent.mGuestsBusiness;
				vNewRow._7 = vPageItem.mRowContent.mGuestsTotal;
			
				For Each vRow In vPageItem.mRowsArray Do
					vNewRow = vSection3.Add();
					vNewRow.code = String(vPageItem.mRowNumber) + "1";
					vNewRow.s1 = vRow.mCountryCode;
					vNewRow._1 = vRow.mGuestsTourists;
					vNewRow._2 = vRow.mGuestsEducation;
					vNewRow._3 = vRow.mGuestsRecreation;
					vNewRow._4 = vRow.mGuestsPilgrims;
					vNewRow._5 = vRow.mGuestsPrivateOther;
					vNewRow._6 = vRow.mGuestsBusiness;
					vNewRow._7 = vRow.mGuestsTotal;
				EndDo;
				
			EndIf;

		EndDo;			

		For Each vPageItem In ReportParameters.mPage5 Do
			vNewRow = vSection4.Add();
			vNewRow.code = String(vPageItem.mRowNumber);
			vNewRow._1 = vPageItem.mGuestsTourists;
			vNewRow._2 = vPageItem.mGuestsEducation;
			vNewRow._3 = vPageItem.mGuestsRecreation;
			vNewRow._4 = vPageItem.mGuestsPilgrims;
			vNewRow._5 = vPageItem.mGuestsPrivateOther;
			vNewRow._6 = vPageItem.mGuestsBusiness;
			vNewRow._7 = vPageItem.mGuestsTotal;
		EndDo;			

		vSections.Add(vSection3);
		vSections.Add(vSection4);
		
	Endif;
	
	Return vSections;
	
EndFunction // MainIndicatorsReportSections

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
Function PeriodOfOperation()
	Result = "Err";	
	For N = 118 To 119 Do
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
	For N = 120 To 124 Do
		If ReportParameters["m" + String(N-119) + "Star"] = "1" Then
			Result = String(N);
			Break;
		EndIf;
	EndDo;
	If Result = "Err" Then
		If ReportParameters.mNoStar = "1" Then
			Result = "125";
		ElsIf ReportParameters.mNotClassified = "1" Then
			Result = "126";
		EndIf;
	
	EndIf;
	Return Result;
EndFunction

// -----------------------------------------------------------------------------
Function KSRBuildingTypes()
	Result = "Err";	
	For N = 127 To 129 Do
		If ReportParameters["m" + String(N)] = "1" Then
			Result = String(N);
			Break;
		EndIf;
	EndDo;
	Return Result;
EndFunction

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
Procedure WriteAreaParametersIntoReportParameters(pAreaParameters, pNamesStructure)
	If ReportParameters = Undefined Then
		ReportParameters = New Structure;
	EndIf;
	For Each StructureItem In pNamesStructure Do
		ReportParameters.Insert(StructureItem.Key, pAreaParameters[StructureItem.Key]);
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
Function WriteAreaParametersIntoStructure(pAreaParameters, pNamesStructure)
	For Each StructureItem In pNamesStructure Do
		Try
			pNamesStructure[StructureItem.Key] = pAreaParameters[StructureItem.Key];
		Except
		EndTry;
	EndDo;
	
	Return pNamesStructure;
	
EndFunction // WriteAreaParametersIntoStructure()



#EndRegion

