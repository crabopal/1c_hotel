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
	If IsBlankString(HotelStars) Then
		HotelStars = "3";
	EndIf;
	If FeePerNight = 0 Then
		FeePerNight = 0.51;
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
	vTotalGuestDaysAdultsCypriotsPay = 0;
	vTotalGuestDaysAdultsCypriotsComp = 0;
	vTotalGuestDaysAdultsForeignersPay = 0;
	vTotalGuestDaysAdultsForeignersComp = 0;
	
	vTotalGuestDaysChildrenCypriotsPay = 0;
	vTotalGuestDaysChildrenCypriotsComp = 0;
	vTotalGuestDaysChildrenForeignersPay = 0;
	vTotalGuestDaysChildrenForeignersComp = 0;
	
	vTotalRoomsRentedPay = 0;
	vTotalRoomsRentedComp = 0;
	
	// Initialize counters
	vGuestDaysAdultsCypriotsPay = 0;
	vGuestDaysAdultsCypriotsComp = 0;
	vGuestDaysAdultsForeignersPay = 0;
	vGuestDaysAdultsForeignersComp = 0;
	
	vGuestDaysChildrenCypriotsPay = 0;
	vGuestDaysChildrenCypriotsComp = 0;
	vGuestDaysChildrenForeignersPay = 0;
	vGuestDaysChildrenForeignersComp = 0;
	
	vRoomsRentedPay = 0;
	vRoomsRentedComp = 0;
	
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
	vHeader.Parameters.mHotelStars = TrimAll(HotelStars);
	vHeader.Parameters.mHotelPhone = TrimAll(Hotel.Phones);
	vHeader.Parameters.mHotelFax = TrimAll(Hotel.Fax);
	vAddrStruct = cmParseAddress(Hotel.PostAddress);
	vHeader.Parameters.mHotelRegion = TrimAll(vAddrStruct.Region);
	vHeader.Parameters.mHotelTown = TrimAll(vAddrStruct.City);
	vHeader.Parameters.mHotelPostCode = TrimAll(vAddrStruct.PostCode);
	vHeader.Parameters.mHotelNumberOfRooms = GetHotelNumberOfRooms();
	pSpreadsheet.Put(vHeader);
	
	// Table of countries
	vArea = vTemplate.GetArea("Date");
	
	// Get table of countries
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	GuestDaysTurnovers.AccountingDate AS Period,
	|	GuestDaysTurnovers.ClientCitizenshipGroup AS ClientCitizenshipGroup,
	|	GuestDaysTurnovers.RateTypeGroup AS RateTypeGroup,
	|	SUM(GuestDaysTurnovers.NumberOfAdults) AS NumberOfAdults,
	|	SUM(GuestDaysTurnovers.NumberOfChildren) AS NumberOfChildren,
	|	SUM(GuestDaysTurnovers.RoomsRented) AS RoomsRented
	|FROM
	|	(SELECT
	|		SalesTurnovers.AccountingDate AS AccountingDate,
	|		CASE
	|			WHEN ISNULL(SalesTurnovers.Client.Citizenship, &qBaseCountry) = &qBaseCountry
	|				THEN ""CYPRIOT""
	|			ELSE ""FOREIGNER""
	|		END AS ClientCitizenshipGroup,
	|		CASE
	|			WHEN ISNULL(SalesTurnovers.RoomRate.IsComplimentary, FALSE)
	|				THEN ""COMP""
	|			WHEN ISNULL(SalesTurnovers.ParentDoc.PricePresentation, """") LIKE ""%---%""
	|				THEN ""COMP""
	|			ELSE ""PAY""
	|		END AS RateTypeGroup,
	|		SalesTurnovers.GuestDays AS NumberOfAdults,
	|		0 AS NumberOfChildren,
	|		SalesTurnovers.RoomsRented AS RoomsRented
	|	FROM
	|		AccumulationRegister.Sales AS SalesTurnovers
	|	WHERE
	|		SalesTurnovers.AccountingDate >= &qPeriodFrom
	|		AND SalesTurnovers.AccountingDate <= &qPeriodTo
	|		AND SalesTurnovers.Hotel = &qHotel
	|		AND SalesTurnovers.Company = &qCompany
	|		AND NOT SalesTurnovers.IsCorrection
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		SalesTurnovers.AccountingDate,
	|		CASE
	|			WHEN ISNULL(SalesTurnovers.Client.Citizenship, &qBaseCountry) = &qBaseCountry
	|				THEN ""CYPRIOT""
	|			ELSE ""FOREIGNER""
	|		END,
	|		CASE
	|			WHEN ISNULL(SalesTurnovers.RoomRate.IsComplimentary, FALSE)
	|				THEN ""COMP""
	|			WHEN ISNULL(SalesTurnovers.ParentDoc.PricePresentation, """") LIKE ""%---%""
	|				THEN ""COMP""
	|			ELSE ""PAY""
	|		END,
	|		CASE
	|			WHEN SalesTurnovers.GuestDays < 0
	|				THEN SalesTurnovers.AccommodationTemplate.NumberOfTeenagers + SalesTurnovers.AccommodationTemplate.NumberOfChildren + SalesTurnovers.AccommodationTemplate.NumberOfInfants
	|			ELSE -(SalesTurnovers.AccommodationTemplate.NumberOfTeenagers + SalesTurnovers.AccommodationTemplate.NumberOfChildren + SalesTurnovers.AccommodationTemplate.NumberOfInfants)
	|		END,
	|		CASE
	|			WHEN SalesTurnovers.GuestDays < 0
	|				THEN -(SalesTurnovers.AccommodationTemplate.NumberOfTeenagers + SalesTurnovers.AccommodationTemplate.NumberOfChildren + SalesTurnovers.AccommodationTemplate.NumberOfInfants)
	|			ELSE SalesTurnovers.AccommodationTemplate.NumberOfTeenagers + SalesTurnovers.AccommodationTemplate.NumberOfChildren + SalesTurnovers.AccommodationTemplate.NumberOfInfants
	|		END,
	|		0
	|	FROM
	|		AccumulationRegister.Sales AS SalesTurnovers
	|	WHERE
	|		SalesTurnovers.AccountingDate >= &qPeriodFrom
	|		AND SalesTurnovers.AccountingDate <= &qPeriodTo
	|		AND SalesTurnovers.Hotel = &qHotel
	|		AND SalesTurnovers.Company = &qCompany
	|		AND SalesTurnovers.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|		AND (SalesTurnovers.AccommodationType.Type = VALUE(Enum.AccomodationTypes.Room)
	|				OR SalesTurnovers.AccommodationType.Type = VALUE(Enum.AccomodationTypes.Beds))
	|		AND SalesTurnovers.Service.IsRoomRevenue
	|		AND SalesTurnovers.Service.IsInPrice
	|		AND NOT SalesTurnovers.Service.RoomRevenueAmountsOnly
	|		AND NOT SalesTurnovers.IsCorrection
	|		AND SalesTurnovers.Price >= 0
	|		AND SalesTurnovers.RoomsRented <> 0) AS GuestDaysTurnovers
	|
	|GROUP BY
	|	GuestDaysTurnovers.AccountingDate,
	|	GuestDaysTurnovers.ClientCitizenshipGroup,
	|	GuestDaysTurnovers.RateTypeGroup
	|
	|ORDER BY
	|	Period,
	|	ClientCitizenshipGroup,
	|	RateTypeGroup DESC";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qBaseCountry", Hotel.Citizenship);
	vRepData = vQry.Execute().Unload();
	
	vCurDate = '00010101';
	For Each vRow In vRepData Do
		If vCurDate <> vRow.Period Then
			If vCurDate <> '00010101' Then
				// Fill area parameters
				vArea.Parameters.mDate = Format(vCurDate, "DF=dd.MM.yyyy");
				
				vArea.Parameters.mGuestDaysAdultsCypriotsPay = vGuestDaysAdultsCypriotsPay;
				vArea.Parameters.mGuestDaysAdultsCypriotsComp = vGuestDaysAdultsCypriotsComp;
				vArea.Parameters.mGuestDaysAdultsForeignersPay = vGuestDaysAdultsForeignersPay;
				vArea.Parameters.mGuestDaysAdultsForeignersComp = vGuestDaysAdultsForeignersComp;
				
				vArea.Parameters.mGuestDaysChildrenCypriotsPay = vGuestDaysChildrenCypriotsPay;
				vArea.Parameters.mGuestDaysChildrenCypriotsComp = vGuestDaysChildrenCypriotsComp;
				vArea.Parameters.mGuestDaysChildrenForeignersPay = vGuestDaysChildrenForeignersPay;
				vArea.Parameters.mGuestDaysChildrenForeignersComp = vGuestDaysChildrenForeignersComp;
				
				vArea.Parameters.mRoomsRentedPay = vRoomsRentedPay;
				vArea.Parameters.mRoomsRentedComp = vRoomsRentedComp;
				
				// Put date area
				pSpreadsheet.Put(vArea);
				
				// Reset counters
				vGuestDaysAdultsCypriotsPay = 0;
				vGuestDaysAdultsCypriotsComp = 0;
				vGuestDaysAdultsForeignersPay = 0;
				vGuestDaysAdultsForeignersComp = 0;
				
				vGuestDaysChildrenCypriotsPay = 0;
				vGuestDaysChildrenCypriotsComp = 0;
				vGuestDaysChildrenForeignersPay = 0;
				vGuestDaysChildrenForeignersComp = 0;
				
				vRoomsRentedPay = 0;
				vRoomsRentedComp = 0;
			EndIf;
				
			// Fill date
			vCurDate = vRow.Period;
		EndIf;
		
		// Fill data and totals
		If vRow.ClientCitizenshipGroup = "CYPRIOT" Then
			If vRow.RateTypeGroup = "PAY" Then
				vGuestDaysAdultsCypriotsPay = vGuestDaysAdultsCypriotsPay + Round(vRow.NumberOfAdults, 0);
				vGuestDaysChildrenCypriotsPay = vGuestDaysChildrenCypriotsPay + Round(vRow.NumberOfChildren, 0);
				vTotalGuestDaysAdultsCypriotsPay = vTotalGuestDaysAdultsCypriotsPay + Round(vRow.NumberOfAdults, 0);
				vTotalGuestDaysChildrenCypriotsPay = vTotalGuestDaysChildrenCypriotsPay + Round(vRow.NumberOfChildren, 0);
			Else
				vGuestDaysAdultsCypriotsComp = vGuestDaysAdultsCypriotsComp + Round(vRow.NumberOfAdults, 0);
				vGuestDaysChildrenCypriotsComp = vGuestDaysChildrenCypriotsComp + Round(vRow.NumberOfChildren, 0);
				vTotalGuestDaysAdultsCypriotsComp = vTotalGuestDaysAdultsCypriotsComp + Round(vRow.NumberOfAdults, 0);
				vTotalGuestDaysChildrenCypriotsComp = vTotalGuestDaysChildrenCypriotsComp + Round(vRow.NumberOfChildren, 0);
			EndIf;
		Else					
			If vRow.RateTypeGroup = "PAY" Then
				vGuestDaysAdultsForeignersPay = vGuestDaysAdultsForeignersPay + Round(vRow.NumberOfAdults, 0);
				vGuestDaysChildrenForeignersPay = vGuestDaysChildrenForeignersPay + Round(vRow.NumberOfChildren, 0);
				vTotalGuestDaysAdultsForeignersPay = vTotalGuestDaysAdultsForeignersPay + Round(vRow.NumberOfAdults, 0);
				vTotalGuestDaysChildrenForeignersPay = vTotalGuestDaysChildrenForeignersPay + Round(vRow.NumberOfChildren, 0);
			Else
				vGuestDaysAdultsForeignersComp = vGuestDaysAdultsForeignersComp + Round(vRow.NumberOfAdults, 0);
				vGuestDaysChildrenForeignersComp = vGuestDaysChildrenForeignersComp + Round(vRow.NumberOfChildren, 0);
				vTotalGuestDaysAdultsForeignersComp = vTotalGuestDaysAdultsForeignersComp + Round(vRow.NumberOfAdults, 0);
				vTotalGuestDaysChildrenForeignersComp = vTotalGuestDaysChildrenForeignersComp + Round(vRow.NumberOfChildren, 0);
			EndIf;
		EndIf;
		If vRow.RateTypeGroup = "PAY" Then
			vRoomsRentedPay = vRoomsRentedPay + Round(vRow.RoomsRented, 0);
			vTotalRoomsRentedPay = vTotalRoomsRentedPay + Round(vRow.RoomsRented, 0);
		Else
			vRoomsRentedComp = vRoomsRentedComp + Round(vRow.RoomsRented, 0);
			vTotalRoomsRentedComp = vTotalRoomsRentedComp + Round(vRow.RoomsRented, 0);
		EndIf;
	EndDo;
	If vCurDate <> '00010101' Then
		// Fill area parameters
		vArea.Parameters.mDate = Format(vCurDate, "DF=dd.MM.yyyy");
		
		vArea.Parameters.mGuestDaysAdultsCypriotsPay = vGuestDaysAdultsCypriotsPay;
		vArea.Parameters.mGuestDaysAdultsCypriotsComp = vGuestDaysAdultsCypriotsComp;
		vArea.Parameters.mGuestDaysAdultsForeignersPay = vGuestDaysAdultsForeignersPay;
		vArea.Parameters.mGuestDaysAdultsForeignersComp = vGuestDaysAdultsForeignersComp;
		
		vArea.Parameters.mGuestDaysChildrenCypriotsPay = vGuestDaysChildrenCypriotsPay;
		vArea.Parameters.mGuestDaysChildrenCypriotsComp = vGuestDaysChildrenCypriotsComp;
		vArea.Parameters.mGuestDaysChildrenForeignersPay = vGuestDaysChildrenForeignersPay;
		vArea.Parameters.mGuestDaysChildrenForeignersComp = vGuestDaysChildrenForeignersComp;
		
		vArea.Parameters.mRoomsRentedPay = vRoomsRentedPay;
		vArea.Parameters.mRoomsRentedComp = vRoomsRentedComp;
		
		// Put date area
		pSpreadsheet.Put(vArea);
	EndIf;
	
	// Report footer
	vFooter = vTemplate.GetArea("Footer");
	
	vFooter.Parameters.mGuestDaysAdultsCypriotsPay = vTotalGuestDaysAdultsCypriotsPay;
	vFooter.Parameters.mGuestDaysAdultsCypriotsComp = vTotalGuestDaysAdultsCypriotsComp;
	vFooter.Parameters.mGuestDaysAdultsForeignersPay = vTotalGuestDaysAdultsForeignersPay;
	vFooter.Parameters.mGuestDaysAdultsForeignersComp = vTotalGuestDaysAdultsForeignersComp;
	
	vFooter.Parameters.mGuestDaysChildrenCypriotsPay = vTotalGuestDaysChildrenCypriotsPay;
	vFooter.Parameters.mGuestDaysChildrenCypriotsComp = vTotalGuestDaysChildrenCypriotsComp;
	vFooter.Parameters.mGuestDaysChildrenForeignersPay = vTotalGuestDaysChildrenForeignersPay;
	vFooter.Parameters.mGuestDaysChildrenForeignersComp = vTotalGuestDaysChildrenForeignersComp;
	
	vFooter.Parameters.mRoomsRentedPay = vTotalRoomsRentedPay;
	vFooter.Parameters.mRoomsRentedComp = vTotalRoomsRentedComp;
	
	// Total number of adult days
	vTotalDaysPay = 0;
	If Not FeeIsPerRoom Then
		vFooter.Parameters.mStatementHeader = "Total Customers (Adults) stayed";
		vTotalDaysPay = vTotalGuestDaysAdultsCypriotsPay + vTotalGuestDaysAdultsForeignersPay;
	Else
		vFooter.Parameters.mStatementHeader = "Total rooms";
		vTotalDaysPay = vTotalRoomsRentedPay;
	EndIf;
	vFooter.Parameters.mTotalDaysPay = vTotalDaysPay;
	vFooter.Parameters.mFeePerNight = Format(FeePerNight, "NFD=4; NZ=");
	vFooter.Parameters.mFeeAmount = Format(Round(vTotalDaysPay * FeePerNight, 2), "NFD=2; NZ=");
	
	pSpreadsheet.Put(vFooter);
	
	// Report header and footer
	cmApplyReportHeader(pSpreadsheet);
	cmApplyReportFooter(pSpreadsheet);
EndProcedure // pmGenerate

// -----------------------------------------------------------------------------
Function GetHotelNumberOfRooms()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInventoryBalance.Hotel,
	|	ISNULL(RoomInventoryBalance.TotalRoomsBalance, 0) AS TotalRooms
	|FROM
	|	AccumulationRegister.RoomInventory.Balance(&qPeriod, Hotel = &qHotel) AS RoomInventoryBalance";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qPeriod", CurrentSessionDate());
	vRes = vQry.Execute().Unload();
	If vRes.Count() > 0 Then
		vResRow = vRes.Get(0);
		Return vResRow.TotalRooms;
	Else
		Return 0;
	EndIf;
EndFunction // GetHotelNumberOfRooms
