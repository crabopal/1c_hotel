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
		PeriodFrom = BegOfMonth(BegOfMonth(CurrentSessionDate()) - 1);
	EndIf;
	If Not ValueIsFilled(PeriodTo) Then
		PeriodTo = EndOfMonth(PeriodFrom);
	EndIf;
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If Not ValueIsFilled(Company) Then
		If ValueIsFilled(Hotel) Then
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
	
	// Choose template
	vTemplate = ThisObject.GetTemplate("Report");
	
	// Report header
	vHeader = vTemplate.GetArea("Header");
	If BegOfYear(PeriodFrom) = BegOfDay(PeriodFrom) And EndOfQuarter(PeriodTo) = EndOfDay(PeriodTo) Then
		vHeader.Parameters.mPeriodStr = PeriodPresentation(BegOfQuarter(PeriodTo), EndOfDay(PeriodTo), cmLocalizationCode());
	Else
		vHeader.Parameters.mPeriodStr = PeriodPresentation(BegOfDay(PeriodFrom), EndOfDay(PeriodTo), cmLocalizationCode());
	EndIf;
	vHeader.Parameters.mHotelName = TrimAll(Hotel.PrintName);
	vHeader.Parameters.mCTOOffice = TrimAll(CTOOffice);
	vHeader.Parameters.mCTOFax = TrimAll(CTOFax);
	vAddrStruct = cmParseAddress(Hotel.PostAddress);
	If Not IsBlankString(vAddrStruct.City) Then
		vHeader.Parameters.mHotelTown = TrimAll(vAddrStruct.City);
	Else
		vHeader.Parameters.mHotelTown = TrimAll(vAddrStruct.Region);
	EndIf;
	pSpreadsheet.Put(vHeader);
	
	// Table of countries
	vArea = vTemplate.GetArea("Country");
	
	// Get table of countries
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN GeoSales.ClientCitizenship.ISOCode IS NULL
	|			THEN ""Cyprus""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""CY""
	|			THEN ""Cyprus""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""GB""
	|			THEN ""U.K.""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""GR""
	|			THEN ""Greece""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""DE""
	|			THEN ""Germany""
	|		WHEN GeoSales.ClientCitizenship.Code = 998
	|			THEN ""European Common Market""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""AT""
	|			THEN ""Austria""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""BE""
	|			THEN ""Belgium""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""FR""
	|			THEN ""France""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""DK""
	|			THEN ""Denmark""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""IE""
	|			THEN ""Ireland""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""SP""
	|			THEN ""Spain""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""IT""
	|			THEN ""Italy""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""LU""
	|			THEN ""Luxembourg""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""NL""
	|			THEN ""Netherlands""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""PT""
	|			THEN ""Portugal""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""SE""
	|			THEN ""Sweden""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""FI""
	|			THEN ""Finland""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""CZ""
	|			THEN ""Czech Republic""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""EE""
	|			THEN ""Estonia""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""HU""
	|			THEN ""Hungary""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""MT""
	|			THEN ""Malta""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""PL""
	|			THEN ""Poland""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""SI""
	|			THEN ""Slovenia""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""SK""
	|			THEN ""Slovakia""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""NO""
	|			THEN ""Norway""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""CH""
	|			THEN ""Switzerland""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""RU""
	|			THEN ""Russia""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""IS""
	|			THEN ""Islande""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""RO""
	|			THEN ""Romania""
	|		WHEN GeoSales.ClientCitizenship.Code IN (&qEuropeanCountriesList)
	|			THEN ""Other European Countries""
	|		ELSE ""Other Countries""
	|	END AS CountryName,
	|	CASE
	|		WHEN GeoSales.ClientCitizenship.ISOCode IS NULL
	|			THEN 1
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""CY""
	|			THEN 1
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""GB""
	|			THEN 2
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""GR""
	|			THEN 3
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""DE""
	|			THEN 4
	|		WHEN GeoSales.ClientCitizenship.Code = 998
	|			THEN 4.1
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""AT""
	|			THEN 5
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""BE""
	|			THEN 6
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""FR""
	|			THEN 7
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""DK""
	|			THEN 8
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""IE""
	|			THEN 9
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""SP""
	|			THEN 10
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""IT""
	|			THEN 11
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""LU""
	|			THEN 12
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""NL""
	|			THEN 13
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""PT""
	|			THEN 14
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""SE""
	|			THEN 15
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""FI""
	|			THEN 16
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""CZ""
	|			THEN 17
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""EE""
	|			THEN 18
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""HU""
	|			THEN 21
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""MT""
	|			THEN 22
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""PL""
	|			THEN 23
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""SI""
	|			THEN 24
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""SK""
	|			THEN 25
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""NO""
	|			THEN 30
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""CH""
	|			THEN 31
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""RU""
	|			THEN 32
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""IS""
	|			THEN 33
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""RO""
	|			THEN 36
	|		WHEN GeoSales.ClientCitizenship.Code IN (&qEuropeanCountriesList)
	|			THEN 40
	|		ELSE 45
	|	END AS CountryCode,
	|	SUM(GeoSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover,
	|	SUM(GeoSales.GuestDaysTurnover) AS GuestDaysTurnover
	|FROM
	|	(SELECT
	|		GeoSalesTurnovers.Client.Citizenship AS ClientCitizenship,
	|		SUM(GeoSalesTurnovers.GuestsCheckedIn)  AS GuestsCheckedInTurnover,
	|		SUM(GeoSalesTurnovers.GuestDays) AS GuestDaysTurnover
	|	FROM
	|		AccumulationRegister.Sales AS GeoSalesTurnovers
	|	WHERE
	|		GeoSalesTurnovers.AccountingDate >= &qPeriodFrom
	|		AND GeoSalesTurnovers.AccountingDate <= &qPeriodTo
	|		AND GeoSalesTurnovers.Hotel = &qHotel
	|		AND GeoSalesTurnovers.Company = &qCompany
	|		AND NOT GeoSalesTurnovers.IsCorrection
	|	
	|	GROUP BY
	|		GeoSalesTurnovers.Client.Citizenship) AS GeoSales
	|
	|GROUP BY
	|	CASE
	|		WHEN GeoSales.ClientCitizenship.ISOCode IS NULL
	|			THEN ""Cyprus""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""CY""
	|			THEN ""Cyprus""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""GB""
	|			THEN ""U.K.""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""GR""
	|			THEN ""Greece""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""DE""
	|			THEN ""Germany""
	|		WHEN GeoSales.ClientCitizenship.Code = 998
	|			THEN ""European Common Market""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""AT""
	|			THEN ""Austria""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""BE""
	|			THEN ""Belgium""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""FR""
	|			THEN ""France""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""DK""
	|			THEN ""Denmark""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""IE""
	|			THEN ""Ireland""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""SP""
	|			THEN ""Spain""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""IT""
	|			THEN ""Italy""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""LU""
	|			THEN ""Luxembourg""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""NL""
	|			THEN ""Netherlands""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""PT""
	|			THEN ""Portugal""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""SE""
	|			THEN ""Sweden""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""FI""
	|			THEN ""Finland""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""CZ""
	|			THEN ""Czech Republic""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""EE""
	|			THEN ""Estonia""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""HU""
	|			THEN ""Hungary""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""MT""
	|			THEN ""Malta""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""PL""
	|			THEN ""Poland""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""SI""
	|			THEN ""Slovenia""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""SK""
	|			THEN ""Slovakia""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""NO""
	|			THEN ""Norway""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""CH""
	|			THEN ""Switzerland""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""RU""
	|			THEN ""Russia""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""IS""
	|			THEN ""Islande""
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""RO""
	|			THEN ""Romania""
	|		WHEN GeoSales.ClientCitizenship.Code IN (&qEuropeanCountriesList)
	|			THEN ""Other European Countries""
	|		ELSE ""Other Countries""
	|	END,
	|	CASE
	|		WHEN GeoSales.ClientCitizenship.ISOCode IS NULL
	|			THEN 1
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""CY""
	|			THEN 1
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""GB""
	|			THEN 2
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""GR""
	|			THEN 3
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""DE""
	|			THEN 4
	|		WHEN GeoSales.ClientCitizenship.Code = 998
	|			THEN 4.1
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""AT""
	|			THEN 5
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""BE""
	|			THEN 6
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""FR""
	|			THEN 7
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""DK""
	|			THEN 8
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""IE""
	|			THEN 9
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""SP""
	|			THEN 10
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""IT""
	|			THEN 11
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""LU""
	|			THEN 12
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""NL""
	|			THEN 13
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""PT""
	|			THEN 14
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""SE""
	|			THEN 15
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""FI""
	|			THEN 16
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""CZ""
	|			THEN 17
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""EE""
	|			THEN 18
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""HU""
	|			THEN 21
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""MT""
	|			THEN 22
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""PL""
	|			THEN 23
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""SI""
	|			THEN 24
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""SK""
	|			THEN 25
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""NO""
	|			THEN 30
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""CH""
	|			THEN 31
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""RU""
	|			THEN 32
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""IS""
	|			THEN 33
	|		WHEN GeoSales.ClientCitizenship.ISOCode = ""RO""
	|			THEN 36
	|		WHEN GeoSales.ClientCitizenship.Code IN (&qEuropeanCountriesList)
	|			THEN 40
	|		ELSE 45
	|	END
	|
	|ORDER BY
	|	CountryCode";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEuropeanCountriesList", GetEuropeanCountriesList());
	vCountries = vQry.Execute().Unload();
	
	vListOfCodes = GetListOfCodesToPrint();
	For Each vCodeItem In vListOfCodes Do
		vCountryCode = vCodeItem.Value;
		vCountryName = vCodeItem.Presentation;
		
		vCountriesRow = vCountries.Find(vCountryCode, "CountryCode");
		If vCountriesRow = Undefined Then
			vArea.Parameters.mCountryCode = Int(vCountryCode);
			vArea.Parameters.mCountryName = vCountryName;
			vArea.Parameters.mGuestsCheckedIn = 0;
			vArea.Parameters.mGuestDays = 0;
		Else
			vArea.Parameters.mCountryCode = Int(vCountriesRow.CountryCode);
			vArea.Parameters.mCountryName = vCountriesRow.CountryName;
			vArea.Parameters.mGuestsCheckedIn = vCountriesRow.GuestsCheckedInTurnover;
			vArea.Parameters.mGuestDays = vCountriesRow.GuestDaysTurnover;
			
			// Totals
			vTotalGuestDays = vTotalGuestDays + vCountriesRow.GuestDaysTurnover;
			vTotalGuestsCheckedIn = vTotalGuestsCheckedIn + vCountriesRow.GuestsCheckedInTurnover;
		EndIf;
		
		// Put country area
		pSpreadsheet.Put(vArea);
	EndDo;
	
	// Put total area
	vArea.Parameters.mCountryCode = 100;
	vArea.Parameters.mCountryName = "TOTAL";
	vArea.Parameters.mGuestsCheckedIn = vTotalGuestsCheckedIn;
	vArea.Parameters.mGuestDays = vTotalGuestDays;
	pSpreadsheet.Put(vArea);
	
	// Get total rooms rented for each day in the month
	vQryTotals = New Query();
	vQryTotals.Text = 
	"SELECT
	|	SaleTurnover.AccountingDate AS AccountingDate,
	|	SUM(SaleTurnover.RoomsRented) AS RoomsRented
	|FROM
	|	AccumulationRegister.Sales AS SaleTurnover
	|WHERE
	|	SaleTurnover.AccountingDate >= &qPeriodFrom
	|	AND SaleTurnover.AccountingDate <= &qPeriodTo
	|	AND SaleTurnover.Hotel = &qHotel
	|	AND SaleTurnover.Company = &qCompany
	|	AND NOT SaleTurnover.IsCorrection
	|
	|GROUP BY
	|	SaleTurnover.AccountingDate
	|
	|ORDER BY
	|	SaleTurnover.AccountingDate";
	vQryTotals.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQryTotals.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQryTotals.SetParameter("qHotel", Hotel);
	vQryTotals.SetParameter("qCompany", Company);
	vTotals = vQryTotals.Execute().Unload();
	
	// Report footer
	vFooter = vTemplate.GetArea("Footer");
	vRoomsRented = 0;
	For Each vTotalsRow In vTotals Do
		vFooter.Parameters["mRoomsRented"+Day(vTotalsRow.AccountingDate)] = Round(vTotalsRow.RoomsRented, 0);
		vRoomsRented = vRoomsRented + Round(vTotalsRow.RoomsRented, 0);
	EndDo;
	vFooter.Parameters.mRoomsRented = vRoomsRented;
	vFooter.Parameters.mDate = Format(CurrentSessionDate(), "DF=dd.MM.yyyy");
	vFooter.Parameters.mManager = TrimAll(TrimAll(SessionParameters.CurrentUser.LastName) + " " + TrimAll(SessionParameters.CurrentUser.FirstName));
	If IsBlankString(vFooter.Parameters.mManager) Then
		vFooter.Parameters.mManager = TrimAll(SessionParameters.CurrentUser);
	EndIf;
	pSpreadsheet.Put(vFooter);
	
	// Report header and footer
	cmApplyReportHeader(pSpreadsheet);
	cmApplyReportFooter(pSpreadsheet);
EndProcedure // pmGenerate

// -----------------------------------------------------------------------------
Function GetListOfCodesToPrint()
	vList = New valueList();
	vList.Add(1, "Cyprus");
	vList.Add(2, "U.K.");
	vList.Add(3, "Greece");
	vList.Add(4, "Germany");
	vList.Add(4.1, "European Common Market");
	vList.Add(5, "Austria");
	vList.Add(6, "Belgium");
	vList.Add(7, "France");
	vList.Add(8, "Denmark");
	vList.Add(9, "Ireland");
	vList.Add(10, "Spain");
	vList.Add(11, "Italy");
	vList.Add(12, "Luxembourg");
	vList.Add(13, "Netherlands");
	vList.Add(14, "Portugal");
	vList.Add(15, "Sweden");
	vList.Add(16, "Finland");
	vList.Add(17, "Czech Republic");
	vList.Add(18, "Esthonia");
	vList.Add(21, "Hungary");
	vList.Add(22, "Malta");
	vList.Add(23, "Poland");
	vList.Add(24, "Slovenia");
	vList.Add(25, "Slovakia");
	vList.Add(30, "Norway");
	vList.Add(31, "Switzerland");
	vList.Add(32, "Russia");
	vList.Add(33, "Islande");
	vList.Add(36, "Romania");
	vList.Add(40, "Other European Countries");
	vList.Add(45, "Other Countries");
	Return vList;
EndFunction // GetListOfCodesToPrint

// -----------------------------------------------------------------------------
Function GetEuropeanCountriesList()
	vList = New valueList();
	vList.Add(8);
	vList.Add(20);
	vList.Add(40);
	vList.Add(56);
	vList.Add(70);
	vList.Add(100);
	vList.Add(191);
	vList.Add(196);
	vList.Add(203);
	vList.Add(233);
	vList.Add(246);
	vList.Add(250);
	vList.Add(276);
	vList.Add(300);
	vList.Add(348);
	vList.Add(352);
	vList.Add(372);
	vList.Add(833);
	vList.Add(380);
	vList.Add(428);
	vList.Add(438);
	vList.Add(440);
	vList.Add(442);
	vList.Add(807);
	vList.Add(470);
	vList.Add(492);
	vList.Add(499);
	vList.Add(528);
	vList.Add(578);
	vList.Add(616);
	vList.Add(620);
	vList.Add(642);
	vList.Add(674);
	vList.Add(688);
	vList.Add(703);
	vList.Add(705);
	vList.Add(724);
	vList.Add(752);
	vList.Add(756);
	vList.Add(34);
	vList.Add(280);
	vList.Add(891);
	vList.Add(826);
	Return vList;
EndFunction // GetEuropeanCountriesList
