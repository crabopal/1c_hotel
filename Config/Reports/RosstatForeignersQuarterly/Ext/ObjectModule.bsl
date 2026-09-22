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
		PeriodFrom = BegOfYear(CurrentSessionDate());
	EndIf;
	If Not ValueIsFilled(PeriodTo) Then
		PeriodTo = EndOfQuarter(CurrentSessionDate());
	EndIf;
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(Hotel) Then
		If Not ValueIsFilled(Company) Then
			Company = Hotel.Company;
		EndIf;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Procedure pmGenerate(pSpreadsheet) Export
	// Clear output spreadsheet
	pSpreadsheet.Clear();
	
	// Initialize totals
	vTotalGuestDays = 0;
	vTotalGuestsCheckedIn = 0;
	vTotalRoomsRented = 0;
	vTotalBedsRented = 0;
	vTotalGuestsBusiness = 0;
	vTotalGuestsTourists = 0;
	vTotalGuestsTransit = 0;
	vTotalGuestsPrivate = 0;
	
	// Choose template
	vTemplate = ThisObject.GetTemplate("Report");
	
	// Report header
	vHeader = vTemplate.GetArea("Header");
	If BegOfYear(PeriodFrom) = BegOfDay(PeriodFrom) And EndOfQuarter(PeriodTo) = EndOfDay(PeriodTo) Then
		vHeader.Parameters.mPeriodStr = PeriodPresentation(BegOfQuarter(PeriodTo), EndOfDay(PeriodTo), cmLocalizationCode());
	Else
		vHeader.Parameters.mPeriodStr = PeriodPresentation(BegOfDay(PeriodFrom), EndOfDay(PeriodTo), cmLocalizationCode());
	EndIf;
	vHeader.Parameters.mCompanyName = TrimAll(Company.LegacyName);
	vHeader.Parameters.mCompanyPostAddress = cmGetAddressPresentation(Company.PostAddress);
	vHeader.Parameters.mRosstat = TrimAll(Rosstat);
	pSpreadsheet.Put(vHeader);
	
	// Table of countries
	vArea = vTemplate.GetArea("Country");
	
	// Get table of countries
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	GeoSales.ClientCitizenship AS ClientCitizenship,
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qTransit
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 8
	|		ELSE 7
	|	END AS TripPurposeType,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover,
	|	SUM(GeoSales.GuestDaysTurnover) AS GuestDaysTurnover,
	|	SUM(GeoSales.RoomsRentedTurnover) AS RoomsRentedTurnover,
	|	SUM(GeoSales.BedsRentedTurnover) AS BedsRentedTurnover
	|FROM
	|	(SELECT
	|		GeoSalesTurnovers.Client.Citizenship AS ClientCitizenship,
	|		GeoSalesTurnovers.TripPurpose AS TripPurpose,
	|		SUM(GeoSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover,
	|		SUM(GeoSalesTurnovers.GuestDaysTurnover) AS GuestDaysTurnover,
	|		SUM(GeoSalesTurnovers.RoomsRentedTurnover) AS RoomsRentedTurnover,
	|		SUM(GeoSalesTurnovers.BedsRentedTurnover) AS BedsRentedTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection AND Hotel = &qHotel
	|					AND Company = &qCompany
	|					AND Client.Citizenship <> &qBaseCountry) AS GeoSalesTurnovers
	|	
	|	GROUP BY
	|		GeoSalesTurnovers.Client.Citizenship,
	|		GeoSalesTurnovers.TripPurpose) AS GeoSales
	|
	|GROUP BY
	|	GeoSales.ClientCitizenship,
	|	CASE
	|		WHEN GeoSales.TripPurpose = &qBusiness
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qCommerce
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qOfficial
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qHumanitarian
	|			THEN 5
	|		WHEN GeoSales.TripPurpose = &qTourism
	|			THEN 6
	|		WHEN GeoSales.TripPurpose = &qWork
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qTransit
	|			THEN 8
	|		WHEN GeoSales.TripPurpose = &qCrewman
	|			THEN 8
	|		ELSE 7
	|	END
	|
	|ORDER BY
	|	GeoSales.ClientCitizenship.Description,
	|	TripPurposeType
	|TOTALS
	|	SUM(GuestsCheckedInTurnover),
	|	SUM(GuestDaysTurnover),
	|	SUM(RoomsRentedTurnover),
	|	SUM(BedsRentedTurnover)
	|BY
	|	ClientCitizenship,
	|	TripPurposeType";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qBaseCountry", Hotel.Citizenship);
	vQry.SetParameter("qBusiness", Catalogs.TripPurposes.Business);
	vQry.SetParameter("qCommerce", Catalogs.TripPurposes.Commerce);
	vQry.SetParameter("qOfficial", Catalogs.TripPurposes.Official);
	vQry.SetParameter("qHumanitarian", Catalogs.TripPurposes.Humanitarian);
	vQry.SetParameter("qTourism", Catalogs.TripPurposes.Tourism);
	vQry.SetParameter("qWork", Catalogs.TripPurposes.Work);
	vQry.SetParameter("qTransit", Catalogs.TripPurposes.Transit);
	vQry.SetParameter("qCrewman", Catalogs.TripPurposes.Crewman);
	vQry.SetParameter("qCompany", Company);
	vQryResult = vQry.Execute();
	
	vCountries = vQryResult.Select(QueryResultIteration.ByGroups, "ClientCitizenship");
	While vCountries.Next() Do
		vArea.Parameters.mCountryCode = "";
		vArea.Parameters.mCountry = "";
		If ValueIsFilled(vCountries.ClientCitizenship) Then
			vArea.Parameters.mCountryCode = vCountries.ClientCitizenship.Code;
			vArea.Parameters.mCountry = TrimAll(vCountries.ClientCitizenship.Description);
		EndIf;
		vArea.Parameters.mGuestDays = vCountries.GuestDaysTurnover;
		vArea.Parameters.mGuestsCheckedIn = vCountries.GuestsCheckedInTurnover;
		vArea.Parameters.mRoomsRented = vCountries.RoomsRentedTurnover;
		vArea.Parameters.mBedsRented = vCountries.BedsRentedTurnover;
		
		// Totals
		vTotalGuestDays = vTotalGuestDays + vCountries.GuestDaysTurnover;
		vTotalGuestsCheckedIn = vTotalGuestsCheckedIn + vCountries.GuestsCheckedInTurnover;
		vTotalRoomsRented = vTotalRoomsRented + vCountries.RoomsRentedTurnover;
		vTotalBedsRented = vTotalBedsRented + vCountries.BedsRentedTurnover;
		
		// Output trip purpose types
		vArea.Parameters.mGuestsBusiness = 0;
		vArea.Parameters.mGuestsTourists = 0;
		vArea.Parameters.mGuestsPrivate = 0;
		vArea.Parameters.mGuestsTransit = 0;
		
		vTypes = vCountries.Select(QueryResultIteration.ByGroups, "TripPurposeType");
		While vTypes.Next() Do
			If vTypes.TripPurposeType = 5 Then
				vArea.Parameters.mGuestsBusiness = vTypes.GuestsCheckedInTurnover;
				vTotalGuestsBusiness = vTotalGuestsBusiness + vTypes.GuestsCheckedInTurnover;
			ElsIf vTypes.TripPurposeType = 6 Then
				vArea.Parameters.mGuestsTourists = vTypes.GuestsCheckedInTurnover;
				vTotalGuestsTourists = vTotalGuestsTourists + vTypes.GuestsCheckedInTurnover;
			ElsIf vTypes.TripPurposeType = 8 Then
				vArea.Parameters.mGuestsTransit = vTypes.GuestsCheckedInTurnover;
				vTotalGuestsTransit = vTotalGuestsTransit + vTypes.GuestsCheckedInTurnover;
			Else
				vArea.Parameters.mGuestsPrivate = vTypes.GuestsCheckedInTurnover;
				vTotalGuestsPrivate = vTotalGuestsPrivate + vTypes.GuestsCheckedInTurnover;
			EndIf;
		EndDo;
		
		// Put country area
		pSpreadsheet.Put(vArea);
	EndDo;
	
	// Get total rooms and beds
	vQryTotals = New Query();
	vQryTotals.Text = 
	"SELECT
	|	ISNULL(RoomInventoryBalance.TotalRoomsBalance, 0) AS TotalRoomsBalance,
	|	ISNULL(RoomInventoryBalance.TotalBedsBalance, 0) AS TotalBedsBalance
	|FROM
	|	AccumulationRegister.RoomInventory.Balance(&qPeriodTo, Hotel = &qHotel) AS RoomInventoryBalance";
	vQryTotals.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQryTotals.SetParameter("qHotel", Hotel);
	vTotals = vQryTotals.Execute().Unload();
	
	vTotalRooms = 0;
	vTotalBeds = 0;
	If vTotals.Count() > 0 Then
		vTotalsRow = vTotals.Get(0);
		vTotalRooms = vTotalsRow.TotalRoomsBalance;
		vTotalBeds = vTotalsRow.TotalBedsBalance;
	EndIf;
	
	// Report footer
	vFooter = vTemplate.GetArea("Footer");
	vFooter.Parameters.mGuestDays = vTotalGuestDays;
	vFooter.Parameters.mGuestsCheckedIn = vTotalGuestsCheckedIn;
	vFooter.Parameters.mRoomsRented = vTotalRoomsRented;
	vFooter.Parameters.mBedsRented = vTotalBedsRented;
	vFooter.Parameters.mGuestsBusiness = vTotalGuestsBusiness;
	vFooter.Parameters.mGuestsTourists = vTotalGuestsTourists;
	vFooter.Parameters.mGuestsTransit = vTotalGuestsTransit;
	vFooter.Parameters.mGuestsPrivate = vTotalGuestsPrivate;
	vFooter.Parameters.mTotalRooms = vTotalRooms;
	vFooter.Parameters.mTotalBeds = vTotalBeds;
	pSpreadsheet.Put(vFooter);
EndProcedure // pmGenerate
