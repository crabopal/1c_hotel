
// -----------------------------------------------------------------------------
// Description: Returns value table with active set room rate prices orders for the given list of room rates
// Parameters: Value list with room rates, Date to get active set room rate prices orders
// Return value: Value table with set room rate prices orders
// -----------------------------------------------------------------------------
Function GetActiveSetRoomRatePrices(pRoomRates, pPeriod, pCheckInDate, pCheckOutDate, pCalendarDayTypesList = Undefined, pHotel = Undefined, pRoomType = Undefined) Export
	// Check room rates list
	vRoomRates = New ValueList();
	If TypeOf(pRoomRates) = Type("Structure") Then
		For Each vRoomRatesItem In pRoomRates Do
			vRoomRate = vRoomRatesItem.Value;
			vRoomRates.Add(?(ValueIsFilled(vRoomRate.BasedOnRoomRate), vRoomRate.BasedOnRoomRate, vRoomRate));
		EndDo;
	Else
		vRoomRates.Add(?(ValueIsFilled(pRoomRates.BasedOnRoomRate), pRoomRates.BasedOnRoomRate, pRoomRates));
	EndIf;
	
	// Check calendar day types list
	vCalendarDayTypesList = New ValueList();
	If pCalendarDayTypesList <> Undefined Then
		For Each vCalendarDayTypesListItem In pCalendarDayTypesList Do
			vCalendarDayTypesList.Add(vCalendarDayTypesListItem.Value);
		EndDo;
	EndIf;
	
	// Check period
	If Not ValueIsFilled(pPeriod) Then
		pPeriod = CurrentSessionDate();
	EndIf;
	
	vAccommodationPeriodIsSet = ValueIsFilled(pCheckInDate) And ValueIsFilled(pCheckOutDate);
	
	// Run query
	If vAccommodationPeriodIsSet Then
		vQry = New Query();
		vQry.Text = 
		"SELECT DISTINCT
		|	CalendarDayTypes.CalendarDayType AS CalendarDayType
		|INTO CalendarDayTypes
		|FROM
		|	(SELECT
		|		CalendarDays.CalendarDayType AS CalendarDayType
		|	FROM
		|		InformationRegister.CalendarDays.SliceLast(
		|				&qPeriod,
		|					AccountingDate BETWEEN &qPeriodFrom AND &qPeriodTo
		|					AND Calendar IN (&qCalendars)) AS CalendarDays
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CalendarDaysByRoomTypes.CalendarDayType
		|	FROM
		|		InformationRegister.CalendarDaysByRoomTypes.SliceLast(
		|				&qPeriod,
		|					AccountingDate BETWEEN &qPeriodFrom AND &qPeriodTo 
		|					AND Calendar IN (&qCalendars)
		|					AND (NOT &qHotelIsEmpty
		|							AND Hotel = &qHotel
		|						OR &qHotelIsEmpty)
		|					AND (RoomType = &qRoomType
		|							AND &qRoomType <> UNDEFINED
		|						OR &qRoomType = UNDEFINED)) AS CalendarDaysByRoomTypes
		|	WHERE
		|		CalendarDaysByRoomTypes.CalendarDayType <> VALUE(Catalog.CalendarDayTypes.EmptyRef)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CalendarDayTypesByLengthOfStay.CalendarDayType
		|	FROM
		|		InformationRegister.CalendarDayTypesByLengthOfStay AS CalendarDayTypesByLengthOfStay
		|	WHERE
		|		CalendarDayTypesByLengthOfStay.Calendar IN(&qCalendars)
		|		AND CalendarDayTypesByLengthOfStay.CalendarDayType <> VALUE(Catalog.CalendarDayTypes.EmptyRef)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CalendarDayTypes.Ref
		|	FROM
		|		Catalog.CalendarDayTypes AS CalendarDayTypes
		|	WHERE
		|		CalendarDayTypes.Ref IN(&qCalendarDayTypesList)) AS CalendarDayTypes
		|
		|INDEX BY
		|	CalendarDayTypes.CalendarDayType
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	RoomRatesSliceLast.SetRoomRatePrices AS SetRoomRatePrices,
		|	RoomRatesSliceLast.RoomRate AS RoomRate,
		|	RoomRatesSliceLast.RoomRate.SortCode AS RoomRateSortCode,
		|	RoomRatesSliceLast.CalendarDayType AS CalendarDayType,
		|	ISNULL(RoomRatesSliceLast.CalendarDayType.SortCode, 0) AS CalendarDayTypeSortCode,
		|	RoomRatesSliceLast.PriceTag AS PriceTag,
		|	ISNULL(RoomRatesSliceLast.PriceTag.SortCode, 0) AS PriceTagSortCode
		|FROM
		|	InformationRegister.RoomRates.SliceLast(
		|			&qPeriod,
		|			RoomRate IN (&qRoomRates)
		|				AND (NOT &qHotelIsEmpty
		|						AND Hotel = &qHotel
		|					OR &qHotelIsEmpty)
		|				AND IsFormula = FALSE) AS RoomRatesSliceLast
		|		INNER JOIN CalendarDayTypes AS CalendarDayTypes
		|		ON RoomRatesSliceLast.CalendarDayType = CalendarDayTypes.CalendarDayType
		|
		|ORDER BY
		|	RoomRateSortCode,
		|	CalendarDayTypeSortCode,
		|	PriceTagSortCode";
		vCalendars = New ValueList();
		If TypeOf(vRoomRates) = Type("ValueList") Then 
			For Each vRoomRatesItem In vRoomRates Do
				vCalendar = vRoomRatesItem.Value.Calendar;
				If ValueIsFilled(vCalendar) Then
					If vCalendars.FindByValue(vCalendar) = Undefined Then
						vCalendars.Add(vCalendar);
					EndIf;
				EndIf;
			EndDo;
		Else
			vCalendars.Add(vRoomRates.Calendar);
		EndIf;
		vQry.SetParameter("qPeriod", pPeriod);
		vQry.SetParameter("qRoomRates", vRoomRates);
		vQry.SetParameter("qCalendars", vCalendars);
		vQry.SetParameter("qPeriodFrom", BegOfDay(pCheckInDate));
		vQry.SetParameter("qPeriodTo", BegOfDay(pCheckOutDate));
		vQry.SetParameter("qCalendarDayTypesList", vCalendarDayTypesList);
		vQry.SetParameter("qHotel", pHotel);
		vQry.SetParameter("qRoomType", pRoomType);
		vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(pHotel));
	Else
		vQry = New Query();
		vQry.Text = 
		"SELECT DISTINCT
		|	RoomRatesSliceLast.SetRoomRatePrices AS SetRoomRatePrices,
		|	RoomRatesSliceLast.RoomRate AS RoomRate,
		|	RoomRatesSliceLast.RoomRate.SortCode AS RoomRateSortCode,
		|	RoomRatesSliceLast.CalendarDayType AS CalendarDayType,
		|	ISNULL(RoomRatesSliceLast.CalendarDayType.SortCode, 0) AS CalendarDayTypeSortCode,
		|	RoomRatesSliceLast.PriceTag AS PriceTag,
		|	ISNULL(RoomRatesSliceLast.PriceTag.SortCode, 0) AS PriceTagSortCode
		|FROM
		|	InformationRegister.RoomRates.SliceLast(
		|			&qPeriod,
		|			RoomRate IN (&qRoomRates)
		|				AND (NOT &qHotelIsEmpty
		|						AND Hotel = &qHotel
		|					OR &qHotelIsEmpty)
		|				AND NOT IsFormula) AS RoomRatesSliceLast
		|
		|ORDER BY
		|	RoomRateSortCode,
		|	CalendarDayTypeSortCode,
		|	PriceTagSortCode";
		vQry.SetParameter("qPeriod", pPeriod);
		vQry.SetParameter("qRoomRates", vRoomRates);
		vQry.SetParameter("qHotel", pHotel);
		vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(pHotel));
	EndIf;
	vActiveSetRoomRatePricesTable = vQry.Execute().Unload();
	
	// Convert table to structure of table rows
	i = 1;
	vActiveSetRoomRatePricesStruct = New Structure();
	For Each vActiveSetRoomRatePricesTableRow In vActiveSetRoomRatePricesTable Do
		vActiveSetRoomRatePricesStruct.Insert("Row" + Format(i, "ND=10; NFD=; NG="), 
		                                      New Structure("SetRoomRatePrices, RoomRate, RoomRateSortCode, CalendarDayType, CalendarDayTypeSortCode, PriceTag, PriceTagSortCode", 
		                                                    vActiveSetRoomRatePricesTableRow.SetRoomRatePrices, 
															vActiveSetRoomRatePricesTableRow.RoomRate, 
															vActiveSetRoomRatePricesTableRow.RoomRateSortCode, 
															vActiveSetRoomRatePricesTableRow.CalendarDayType, 
															vActiveSetRoomRatePricesTableRow.CalendarDayTypeSortCode, 
															vActiveSetRoomRatePricesTableRow.PriceTag, 
															vActiveSetRoomRatePricesTableRow.PriceTagSortCode));
		i = i + 1;
	EndDo;
	
	Return New FixedStructure(vActiveSetRoomRatePricesStruct);
EndFunction // GetActiveSetRoomRatePrices

// -----------------------------------------------------------------------------
Function GetActiveSetRoomRateFormulas(pRoomRates, pPeriod, pHotel = Undefined) Export
	// Check room rates list
	vRoomRates = New ValueList();
	If TypeOf(pRoomRates) = Type("Structure") Then
		For Each vRoomRatesItem In pRoomRates Do
			vRoomRate = vRoomRatesItem.Value;
			vRoomRates.Add(?(ValueIsFilled(vRoomRate.BasedOnRoomRate), vRoomRate.BasedOnRoomRate, vRoomRate));
		EndDo;
	Else
		vRoomRates.Add(?(ValueIsFilled(pRoomRates.BasedOnRoomRate), pRoomRates.BasedOnRoomRate, pRoomRates));
	EndIf;
	
	// Check period
	If Not ValueIsFilled(pPeriod) Then
		pPeriod = CurrentSessionDate();
	EndIf;

	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomRatesSliceLast.SetRoomRateFormulas AS SetRoomRateFormulas,
	|	RoomRatesSliceLast.RoomRate AS RoomRate
	|FROM
	|	InformationRegister.RoomRates.SliceLast(
	|			&qPeriod,
	|			RoomRate IN (&qRoomRates)
	|				AND (NOT &qHotelIsEmpty
	|						AND Hotel = &qHotel
	|					OR &qHotelIsEmpty)) AS RoomRatesSliceLast";
	vQry.SetParameter("qPeriod", pPeriod);
	vQry.SetParameter("qRoomRates", vRoomRates);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(pHotel));
	
	vRows = vQry.Execute().Unload();

	i = 1;
	vDocsStruct = New Structure();
	For Each vRow In vRows Do
		vDocsStruct.Insert("SetRoomRateFormulas" + Format(i, "ND=10; NFD=; NG="), vRow.SetRoomRateFormulas);
		i = i + 1;
	EndDo;

	Return New FixedStructure(vDocsStruct);
EndFunction // GetActiveSetRoomRateFormulas

// -----------------------------------------------------------------------------
// Get list of prices for given room rate and parameters
// - pDate is optional. If is not specified, then function gets current prices
// - pClientType is optional. If is not specified then it is being set to empty ref.
// - pRoomType is optional. If is specified, then prices for this given room type 
//   are returned.
// - pAccommodationType is optional. If is specified, then prices for this given 
//   accommodation type are returned.
// -----------------------------------------------------------------------------
Function GetRoomRatePrices(pRoomRate, Val pDate = Undefined, Val pPriceCalculationDate = Undefined, Val pClientType = Undefined, 
                           pRoomType = Undefined, pAccommodationType = Undefined, 
                           pServicePackagesList = Undefined, pPriceTag = Undefined, 
						   pCheckInDate = Undefined, pCheckOutDate = Undefined, pMinimizeOutput = False, pSortByPointInTime = False, 
						   pCalendarDayTypesList = Undefined, pHotel = Undefined, pAccommodationTemplate = Undefined, 
						   pIsForFolioSplit = False, pSplitPackagesByGuests = Undefined, pSharePercentIsSet = False) Export
	// Check calendar day types list
	vCalendarDayTypesList = New ValueList();
	If pCalendarDayTypesList <> Undefined Then
		If TypeOf(pCalendarDayTypesList) = Type("Structure") Then
			For Each vCalendarDayTypesListItem In pCalendarDayTypesList Do
				vCalendarDayTypesList.Add(vCalendarDayTypesListItem.Value);
			EndDo;
		Else
			vCalendarDayTypesList.LoadValues(pCalendarDayTypesList.UnloadValues());
		EndIf;
	EndIf;
	
	// Hotel
	vHotel = pHotel;
	If Not ValueIsFilled(vHotel) And 
	   ValueIsFilled(pRoomRate) And Not pRoomRate.IsFolder And ValueIsFilled(pRoomRate.Hotel) Then
		vHotel = pRoomRate.Hotel;
	EndIf;
	If Not ValueIsFilled(vHotel) And ValueIsFilled(pRoomType) Then
		vHotel = pRoomType.Owner;
	EndIf;
	If Not ValueIsFilled(vHotel) Then
		vHotel = SessionParameters.CurrentHotel;
	EndIf;
						   
	// Fill parameter default values 
	If Not ValueIsFilled(pDate) Then
		pDate = CurrentSessionDate();
	EndIf;
	If Not ValueIsFilled(pClientType) Then
		pClientType = Catalogs.ClientTypes.EmptyRef();
	EndIf;
	
	// Rate charges direction
	vRateChargeDirection = pRoomRate.RateChargeDirection;
	If pSharePercentIsSet Then
		vRateChargeDirection = Enums.RateChargeDirections.MergeToTheMainRoomGuest;
	EndIf;
	
	// Check if accommodation type from parameters is the first accommodation type in template
	vUseTemplate = True;
	vSplitPackagesByGuests = False;
	If pIsForFolioSplit Then
		vUseTemplate = False;
		vSplitPackagesByGuests = True;
	EndIf;
	If pSplitPackagesByGuests <> Undefined Then
		vSplitPackagesByGuests = pSplitPackagesByGuests;
	EndIf;
	If vUseTemplate Then
		If ValueIsFilled(pAccommodationType) And pAccommodationType.Type = Enums.AccomodationTypes.Beds Then
			vUseTemplate = False;
			If pSplitPackagesByGuests = Undefined Then
				vSplitPackagesByGuests = True;
			EndIf;
		EndIf;
	EndIf;
	
	// Packages
	vServicePackages = New ValueTable();
	vServicePackages.Columns.Add("ServicePackage", cmGetCatalogTypeDescription("ServicePackages"));
	vServicePackages.Columns.Add("Quantity", cmGetQuantityTypeDescription());
	vServicePackages.Columns.Add("DateFrom", cmGetDateTypeDescription());
	vServicePackages.Columns.Add("DateTo", cmGetDateTypeDescription());
	vServicePackages.Columns.Add("PacketPriceIsIncludedInRoomRate", cmGetBooleanTypeDescription());
	vServicePackages.Columns.Add("IsExtraPackage", cmGetBooleanTypeDescription());
	vServicePackages.Columns.Add("IsMealBoardTerm", cmGetBooleanTypeDescription());
	vServicePackages.Columns.Add("IsPerPerson", cmGetBooleanTypeDescription());
	vServicePackages.Columns.Add("DateValidFrom", cmGetDateTimeTypeDescription());
	vServicePackages.Columns.Add("DateValidTo", cmGetDateTimeTypeDescription());
	vServicePackages.Columns.Add("UsageType", cmGetEnumTypeDescription("ServicePackageUsageType"));
	vServicePackages.Columns.Add("SkipOnMinimizedOutput", cmGetBooleanTypeDescription());
	
	// Document packages
	If pServicePackagesList <> Undefined Then
		For Each vServicePackagesListItem In pServicePackagesList Do
			vServicePackagesRow = vServicePackages.Add();
			If TypeOf(vServicePackagesListItem) = Type("KeyAndValue") Then
				FillPropertyValues(vServicePackagesRow, vServicePackagesListItem.Value);
			ElsIf TypeOf(vServicePackagesListItem) = Type("Structure") Then
				FillPropertyValues(vServicePackagesRow, vServicePackagesListItem);
			Else
				vServicePackagesRow.ServicePackage = vServicePackagesListItem.Value;
				vServicePackagesRow.Quantity = 1;
				vServicePackagesRow.DateFrom = '00010101';
				vServicePackagesRow.DateTo = '39991231';
			EndIf;
			If ValueIsFilled(vServicePackagesRow.ServicePackage) Then
				vServicePackage = vServicePackagesRow.ServicePackage;
				If vServicePackage.UsageType = Enums.ServicePackageUsageType.SubtractFromRoomRatePrice Then
					vServicePackagesRow.SkipOnMinimizedOutput = True;
				EndIf;
				vServicePackagesRow.IsMealBoardTerm = vServicePackage.IsMealBoardTerm;
				vServicePackagesRow.IsPerPerson = vServicePackage.IsPerPerson;
				vServicePackagesRow.DateValidFrom = vServicePackage.DateValidFrom;
				vServicePackagesRow.DateValidTo = vServicePackage.DateValidTo;
				vServicePackagesRow.UsageType = vServicePackage.UsageType;
			EndIf;
			vServicePackagesRow.IsExtraPackage = True;
		EndDo;
	EndIf;
	
	// Room rate packages
	vSkipRoomRatePackages = False;
	If pAccommodationTemplate <> Undefined And vRateChargeDirection = Enums.RateChargeDirections.MergeToTheMainRoomGuest And vUseTemplate Then
		If Not ValueIsFilled(pAccommodationTemplate) Or ValueIsFilled(pAccommodationTemplate) And pAccommodationTemplate = Catalogs.AccommodationTemplates.NoTemplate Then
			vSkipRoomRatePackages = True;
		EndIf;
	EndIf;
	If ValueIsFilled(pRoomRate.ServicePackage) Then
		vCurServicePackage = pRoomRate.ServicePackage;
		If Not vSkipRoomRatePackages Or vSkipRoomRatePackages And vCurServicePackage.IsPerPerson Then
			vServicePackagesRow = vServicePackages.Add();
			vServicePackagesRow.ServicePackage = vCurServicePackage;
			vServicePackagesRow.Quantity = 1;
			vServicePackagesRow.DateFrom = '00010101';
			vServicePackagesRow.DateTo = '39991231';
			If vCurServicePackage.UsageType = Enums.ServicePackageUsageType.SubtractFromRoomRatePrice Then
				vServicePackagesRow.SkipOnMinimizedOutput = True;
			EndIf;
			If vSkipRoomRatePackages And vCurServicePackage.IsPerPerson Then
				vServicePackagesRow.IsExtraPackage = True;
			EndIf;
			If ValueIsFilled(vCurServicePackage) Then
				vServicePackagesRow.IsMealBoardTerm = vCurServicePackage.IsMealBoardTerm;
				vServicePackagesRow.IsPerPerson = vCurServicePackage.IsPerPerson;
				vServicePackagesRow.DateValidFrom = vCurServicePackage.DateValidFrom;
				vServicePackagesRow.DateValidTo = vCurServicePackage.DateValidTo;
				vServicePackagesRow.UsageType = vCurServicePackage.UsageType;
			EndIf;
		EndIf;
	EndIf;
 	For Each vSPRow In pRoomRate.ServicePackages Do
		If ValueIsFilled(vSPRow.ServicePackage) Then
			vCurServicePackage = vSPRow.ServicePackage;
			If Not vSkipRoomRatePackages Or vSkipRoomRatePackages And vCurServicePackage.IsPerPerson Then
				vServicePackagesRow = vServicePackages.Add();
				vServicePackagesRow.ServicePackage = vCurServicePackage;
				vServicePackagesRow.Quantity = 1;
				vServicePackagesRow.DateFrom = '00010101';
				vServicePackagesRow.DateTo = '39991231';
				vServicePackagesRow.PacketPriceIsIncludedInRoomRate = vSPRow.PacketPriceIsIncludedInRoomRate;
				If vCurServicePackage.UsageType = Enums.ServicePackageUsageType.SubtractFromRoomRatePrice Or
				   vSPRow.PacketPriceIsIncludedInRoomRate Then
					vServicePackagesRow.SkipOnMinimizedOutput = True;
				EndIf;
				If vSkipRoomRatePackages And vCurServicePackage.IsPerPerson Then
					vServicePackagesRow.IsExtraPackage = True;
				EndIf;
				If ValueIsFilled(vCurServicePackage) Then
					vServicePackagesRow.IsMealBoardTerm = vCurServicePackage.IsMealBoardTerm;
					vServicePackagesRow.IsPerPerson = vCurServicePackage.IsPerPerson;
					vServicePackagesRow.DateValidFrom = vCurServicePackage.DateValidFrom;
					vServicePackagesRow.DateValidTo = vCurServicePackage.DateValidTo;
					vServicePackagesRow.UsageType = vCurServicePackage.UsageType;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
	// Check should we update price calculation date
	vDoUpdatePCDate = False;
	If pPriceCalculationDate <> Undefined And pPriceCalculationDate = '00010101' Then
		vDoUpdatePCDate = True;
	EndIf;
	
	// First get active for check in date set room rate prices documents
	vResStruct = GetActiveSetRoomRatePrices(pRoomRate, ?(ValueIsFilled(pPriceCalculationDate), pPriceCalculationDate, pDate), pCheckInDate, pCheckOutDate, vCalendarDayTypesList, vHotel, pRoomType);   
	
	vOrders = New ValueTable();
	vOrders.Columns.Add("SetRoomRatePrices", cmGetDocumentTypeDescription("SetRoomRatePrices"));
	vOrders.Columns.Add("RoomRate", cmGetCatalogTypeDescription("RoomRates"));
	vOrders.Columns.Add("RoomRateSortCode", cmGetSortCodeTypeDescription());
	vOrders.Columns.Add("CalendarDayType", cmGetCatalogTypeDescription("CalendarDayTypes"));
	vOrders.Columns.Add("CalendarDayTypeSortCode", cmGetSortCodeTypeDescription());
	vOrders.Columns.Add("PriceTag", cmGetCatalogTypeDescription("PriceTags"));
	vOrders.Columns.Add("PriceTagSortCode", cmGetSortCodeTypeDescription());
	
	For Each vReturnStructKeyAndValue In vResStruct Do
		vOrdersTableRow = vOrders.Add();
		FillPropertyValues(vOrdersTableRow, vReturnStructKeyAndValue.Value);
	EndDo;

	vDocsOnly = vOrders.Copy();
	vDocsOnly.GroupBy("SetRoomRatePrices");
	vSetRoomRatePrices = New ValueList();
	vSetRoomRatePrices.LoadValues(vDocsOnly.UnloadColumn("SetRoomRatePrices"));
	
	// Fill price calculation date
	vPriceCalculationDate = pPriceCalculationDate;
	If vDoUpdatePCDate Then
		vPriceCalculationDate = CurrentSessionDate();
		If BegOfDay(vPriceCalculationDate) = vPriceCalculationDate Then
			vPriceCalculationDate = vPriceCalculationDate + 1;
		EndIf;
	EndIf;
	
	// Remove service packages that could be skipped
	If pMinimizeOutput Then
		r = 0;
		While r < vServicePackages.Count() Do
			vSPRow = vServicePackages.Get(r);
			If vSPRow.SkipOnMinimizedOutput Then
				vServicePackages.Delete(r);
			Else
				r = r + 1;
			EndIf;
		EndDo;
	EndIf;
	
	// Check if day types filter has to be applied
	vAccommodationPeriodIsSet = ValueIsFilled(pCheckInDate) And ValueIsFilled(pCheckOutDate);
	
	// Get list of active calendar day types
	// The reason to build dynamic filter is that 2 inner joins over the main prices table are not working fast enough
	vDayTypesList = New ValueList();
	vFilterByCalendarDayTypes = "TRUE";
	
	vDayTypesQry = New Query();
	If vAccommodationPeriodIsSet Then
		vDayTypesQry.Text = 
		"SELECT DISTINCT
		|	CalendarDayTypes.CalendarDayType AS CalendarDayType
		|FROM
		|	(SELECT
		|		CalendarDays.CalendarDayType AS CalendarDayType
		|	FROM
		|		InformationRegister.CalendarDays.SliceLast(
		|				&qPriceCalculationDate,
		|				AccountingDate BETWEEN &qCheckInDate AND &qCheckOutDate
		|				AND Calendar = &qCalendar) AS CalendarDays
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CalendarDaysByRoomTypes.CalendarDayType
		|	FROM
		|		InformationRegister.CalendarDaysByRoomTypes.SliceLast(
		|				&qPriceCalculationDate,
		|					AccountingDate BETWEEN &qCheckInDate AND &qCheckOutDate
		|					AND Calendar = &qCalendar
		|					AND (&qRoomTypeIsUndefined
		|						OR RoomType = &qRoomType)) AS CalendarDaysByRoomTypes
		|	WHERE
		|		CalendarDaysByRoomTypes.CalendarDayType <> VALUE(Catalog.CalendarDayTypes.EmptyRef)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CalendarDayTypesByLengthOfStay.CalendarDayType
		|	FROM
		|		InformationRegister.CalendarDayTypesByLengthOfStay AS CalendarDayTypesByLengthOfStay
		|	WHERE
		|		CalendarDayTypesByLengthOfStay.Calendar = &qCalendar
		|		AND CalendarDayTypesByLengthOfStay.CalendarDayType <> VALUE(Catalog.CalendarDayTypes.EmptyRef)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CalendarDayTypes.Ref
		|	FROM
		|		Catalog.CalendarDayTypes AS CalendarDayTypes
		|	WHERE
		|		CalendarDayTypes.Ref IN(&qCalendarDayTypesList)) AS CalendarDayTypes";
		vDayTypesQry.SetParameter("qRoomType", pRoomType);
		vDayTypesQry.SetParameter("qRoomTypeIsUndefined", ?(pRoomType = Undefined, True, False));
		vDayTypesQry.SetParameter("qCalendar", pRoomRate.Calendar);
		vDayTypesQry.SetParameter("qCheckInDate", BegOfDay(pCheckInDate) - 24*3600);
		vDayTypesQry.SetParameter("qCheckOutDate", BegOfDay(pCheckOutDate) + 24*3600);
		vDayTypesQry.SetParameter("qPriceCalculationDate", ?(ValueIsFilled(vPriceCalculationDate), vPriceCalculationDate, pDate));
	Else
		vDayTypesQry.Text = 
		"SELECT
		|	CalendarDayTypes.Ref AS CalendarDayType
		|FROM
		|	Catalog.CalendarDayTypes AS CalendarDayTypes
		|WHERE
		|	CalendarDayTypes.Ref IN(&qCalendarDayTypesList)";
	EndIf;
	vDayTypesQry.SetParameter("qCalendarDayTypesList", vCalendarDayTypesList);
	vDayTypes = vDayTypesQry.Execute().Unload();
	If vDayTypes.Count() > 0 Then
		vFilterByCalendarDayTypes = "(";
		For Each vDayTypesRow In vDayTypes Do
			vDayTypeIndex = vDayTypes.IndexOf(vDayTypesRow);
			If vDayTypeIndex > 0 Then
				vFilterByCalendarDayTypes = vFilterByCalendarDayTypes + " OR ";
			EndIf;
			vFilterByCalendarDayTypes = vFilterByCalendarDayTypes + "RoomRatePrices.CalendarDayType = &qCalendarDayType" + Format(vDayTypeIndex, "NFD=0; NZ=; NG=");
			vDayTypesList.Add(vDayTypesRow.CalendarDayType);
		EndDo;
		vFilterByCalendarDayTypes = vFilterByCalendarDayTypes + ")";
	EndIf;
	
	// Then get all set room rate prices rows
	vPrices = New ValueTable();
	If Not pRoomRate.UsePricesFromCalendar Then
		If pAccommodationTemplate <> Undefined And vRateChargeDirection = Enums.RateChargeDirections.MergeToTheMainRoomGuest And vUseTemplate Then
			If ValueIsFilled(pAccommodationTemplate) And pAccommodationTemplate <> Catalogs.AccommodationTemplates.NoTemplate Then
				vQry = New Query;
				vQry.Text = 
				"SELECT
				|	ServicePackages.ServicePackage AS ServicePackage,
				|	ServicePackages.Quantity AS Quantity,
				|	ServicePackages.DateFrom AS DateFrom,
				|	ServicePackages.DateTo AS DateTo,
				|	ServicePackages.PacketPriceIsIncludedInRoomRate AS PacketPriceIsIncludedInRoomRate,
				|	ServicePackages.IsExtraPackage AS IsExtraPackage,
				|	ServicePackages.IsMealBoardTerm AS IsMealBoardTerm,
				|	ServicePackages.IsPerPerson AS IsPerPerson,
				|	ServicePackages.UsageType AS UsageType,
				|	ServicePackages.DateValidFrom AS DateValidFrom,
				|	ServicePackages.DateValidTo AS DateValidTo
				|INTO ServicePackages
				|FROM
				|	&qServicePackages AS ServicePackages
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	ServicePackagePeriods.ServicePackage AS ServicePackage,
				|	MAX(ServicePackagePeriods.Period) AS ActivePeriod
				|INTO ServicePackagesActivePeriods
				|FROM
				|	InformationRegister.ServicePackageRecords.SliceLast(&qDate, ) AS ServicePackagePeriods
				|		INNER JOIN ServicePackages AS ServicePackages
				|		ON (ServicePackages.ServicePackage = ServicePackagePeriods.ServicePackage)
				|
				|GROUP BY
				|	ServicePackagePeriods.ServicePackage
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	Orders.CalendarDayType AS CalendarDayType,
				|	Orders.PriceTag AS PriceTag,
				|	Orders.SetRoomRatePrices AS SetRoomRatePrices
				|INTO Orders
				|FROM
				|	&qOrders AS Orders
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	RoomRatesSliceLast.SetRoomRateFormulas AS Recorder,
				|	RoomRatesSliceLast.RoomRate AS RoomRate
				|INTO ActiveSetRoomRateFormulas
				|FROM
				|	InformationRegister.RoomRates.SliceLast(
				|			&qDate,
				|			RoomRate = &qRoomRate
				|				AND Hotel = &qHotel
				|				AND IsFormula) AS RoomRatesSliceLast
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	RoomRateFormulas.RoomRate.BasedOnRoomRate AS BasedOnRoomRate,
				|	RoomRateFormulas.RoomRate.BasedOnPriceTag AS BasedOnPriceTag,
				|	RoomRateFormulas.RoomRate AS RoomRate,
				|	RoomRateFormulas.Hotel AS Hotel,
				|	RoomRateFormulas.IsFormula AS IsFormula,
				|	RoomRateFormulas.Service AS Service,
				|	RoomRateFormulas.RoomType AS RoomType,
				|	RoomRateFormulas.AccommodationType AS AccommodationType,
				|	RoomRateFormulas.ClientType AS ClientType,
				|	RoomRateFormulas.CalendarDayType AS CalendarDayType,
				|	RoomRateFormulas.Recorder AS Recorder,
				|	RoomRateFormulas.Period AS Period,
				|	RoomRateFormulas.BracketsConstant AS BracketsConstant,
				|	RoomRateFormulas.Constant AS Constant,
				|	RoomRateFormulas.Multiplier AS Multiplier,
				|	RoomRateFormulas.ReplaceWithService AS ReplaceWithService
				|INTO RoomRateFormulas
				|FROM
				|	InformationRegister.RoomRateFormulas AS RoomRateFormulas
				|		INNER JOIN ActiveSetRoomRateFormulas AS ActiveSetRoomRateFormulas
				|		ON RoomRateFormulas.Recorder = ActiveSetRoomRateFormulas.Recorder
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT DISTINCT
				|	ActivePriceTags.PriceTag AS PriceTag
				|INTO ActivePriceTags
				|FROM
				|	InformationRegister.RoomRatePrices AS ActivePriceTags
				|		INNER JOIN Orders AS Orders
				|		ON ActivePriceTags.SetRoomRatePrices = Orders.SetRoomRatePrices
				|			AND ActivePriceTags.CalendarDayType = Orders.CalendarDayType
				|			AND ActivePriceTags.PriceTag = Orders.PriceTag
				|WHERE
				|	ActivePriceTags.RoomRate = &qPricesRoomRate
				|	AND ActivePriceTags.ClientType = &qClientType
				|	AND (&qPriceTagIsFilled
				|				AND ActivePriceTags.PriceTag = &qPriceTag
				|			OR NOT &qPriceTagIsFilled)
				|	AND (ActivePriceTags.RoomType = &qRoomType
				|			OR ActivePriceTags.RoomType = &qEmptyRoomTypeRef
				|			OR &qRoomTypeIsUndefined)
				|	AND (ActivePriceTags.AccommodationType = &qAccommodationType
				|			OR ActivePriceTags.AccommodationType = &qEmptyAccommodationTypeRef
				|			OR &qAccommodationTypeIsUndefined)
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	&qHotel AS Hotel,
				|	&qAccommodationTemplate AS AccommodationTemplate,
				|	HotelRoomTypes.Ref AS RoomType,
				|	HotelRoomTypes.RoomClass AS RoomClass,
				|	CASE
				|		WHEN NOT RoomRateOverrides.ToAccommodationType IS NULL
				|			THEN RoomRateOverrides.ToAccommodationType
				|		ELSE AccommodationTemplatesAccommodationTypes.AccommodationType
				|	END AS AccommodationType,
				|	AccommodationTemplatesAccommodationTypes.LineNumber AS LineNumber
				|INTO TemplateAccommodationTypes
				|FROM
				|	Catalog.RoomTypes AS HotelRoomTypes
				|		LEFT JOIN Catalog.AccommodationTemplates.AccommodationTypes AS AccommodationTemplatesAccommodationTypes
				|		ON (AccommodationTemplatesAccommodationTypes.Ref = &qAccommodationTemplate)
				|		LEFT JOIN InformationRegister.RoomRateOverrides AS RoomRateOverrides
				|		ON (RoomRateOverrides.RoomRate = &qRoomRate)
				|			AND (RoomRateOverrides.Hotel = &qHotel)
				|			AND (RoomRateOverrides.AccommodationTemplate = &qAccommodationTemplate)
				|			AND (HotelRoomTypes.Ref = RoomRateOverrides.RoomType
				|				OR RoomRateOverrides.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
				|			AND (AccommodationTemplatesAccommodationTypes.AccommodationType = RoomRateOverrides.AccommodationType)
				|			AND (AccommodationTemplatesAccommodationTypes.LineNumber = RoomRateOverrides.TemplateLineNumber)
				|WHERE
				|	HotelRoomTypes.Owner = &qHotel
				|	AND (HotelRoomTypes.Ref = &qRoomType
				|			OR &qRoomTypeIsUndefined)
				|	AND NOT HotelRoomTypes.DeletionMark
				|	AND NOT HotelRoomTypes.IsFolder
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	MergedRoomRatePrices.Recorder AS Recorder,
				|	MergedRoomRatePrices.Hotel AS Hotel,
				|	MergedRoomRatePrices.RoomRate AS RoomRate,
				|	MergedRoomRatePrices.CalendarDayType AS CalendarDayType,
				|	MergedRoomRatePrices.PriceTag AS PriceTag,
				|	MergedRoomRatePrices.ClientType AS ClientType,
				|	MergedRoomRatePrices.RoomType AS RoomType,
				|	MergedRoomRatePrices.RoomTypeSortCode AS RoomTypeSortCode,
				|	MergedRoomRatePrices.AccommodationType AS AccommodationType,
				|	MergedRoomRatePrices.AccommodationTypeSortCode AS AccommodationTypeSortCode,
				|	MergedRoomRatePrices.SetRoomRatePrices AS SetRoomRatePrices,
				|	MergedRoomRatePrices.Service AS Service,
				|	MergedRoomRatePrices.Unit AS Unit,
				|	MergedRoomRatePrices.PricesService AS PricesService,
				|	MergedRoomRatePrices.Currency AS Currency,
				|	MergedRoomRatePrices.MinimumQuantity AS MinimumQuantity,
				|	MergedRoomRatePrices.VATRate AS VATRate,
				|	MergedRoomRatePrices.QuantityCalculationRule AS QuantityCalculationRule,
				|	MergedRoomRatePrices.IsRoomRevenue AS IsRoomRevenue,
				|	MergedRoomRatePrices.IsInPrice AS IsInPrice,
				|	MergedRoomRatePrices.IsPricePerPerson AS IsPricePerPerson,
				|	MergedRoomRatePrices.RoomRevenueAmountsOnly AS RoomRevenueAmountsOnly,
				|	&qEmptyDate AS AccountingDate,
				|	0 AS AccountingDayNumber,
				|	&qEmptyString AS Remarks,
				|	NULL AS ServicePackage,
				|	&qEmptyDate AS ServicePackageDateValidFrom,
				|	&qEmptyDate AS ServicePackageDateValidTo,
				|	&qEmptyDate AS ServicePackagePeriodFrom,
				|	&qEmptyDate AS ServicePackagePeriodTo,
				|	MergedRoomRatePrices.PointInTime AS PointInTime,
				|	FALSE AS PacketPriceIsIncludedInRoomRate,
				|	UNDEFINED AS ServicePackageUsageType,
				|	&qEmptyDate AS ServicePackageDateFrom,
				|	&qEndOfTime AS ServicePackageDateTo,
				|	MIN(MergedRoomRatePrices.LineNumber) AS LineNumber,
				|	MIN(MergedRoomRatePrices.SortCode) AS SortCode,
				|	SUM(MergedRoomRatePrices.Price) AS Price,
				|	CASE
				|		WHEN MergedRoomRatePrices.IsRoomRevenue
				|				AND MergedRoomRatePrices.IsInPrice
				|			THEN 1
				|		WHEN MergedRoomRatePrices.QuantityCalculationRuleType = VALUE(Enum.QuantityCalculationRuleTypes.EarlyCheckIn)
				|			THEN 1
				|		WHEN MergedRoomRatePrices.QuantityCalculationRuleType = VALUE(Enum.QuantityCalculationRuleTypes.EarlyCheckInNoDateShift)
				|			THEN 1
				|		WHEN MergedRoomRatePrices.QuantityCalculationRuleType = VALUE(Enum.QuantityCalculationRuleTypes.LateCheckOut)
				|			THEN 1
				|		WHEN MergedRoomRatePrices.Service = MergedRoomRatePrices.EarlyCheckInService
				|			THEN 1
				|		WHEN MergedRoomRatePrices.Service = MergedRoomRatePrices.LateCheckOutService
				|			THEN 1
				|		ELSE SUM(1)
				|	END AS Quantity,
				|	SUM(MergedRoomRatePrices.NumberOfPersons) AS NumberOfPersons,
				|	SUM(MergedRoomRatePrices.NumberOfPersonsInRoom) AS NumberOfPersonsInRoom,
				|	SUM(MergedRoomRatePrices.NumberOfRooms) AS NumberOfRooms,
				|	SUM(MergedRoomRatePrices.NumberOfBeds) AS NumberOfBeds,
				|	SUM(MergedRoomRatePrices.NumberOfAdditionalBeds) AS NumberOfAdditionalBeds
				|FROM
				|	(SELECT
				|		RoomRatePrices.Recorder AS Recorder,
				|		RoomRatePrices.Hotel AS Hotel,
				|		RoomRatePrices.RoomRate AS RoomRate,
				|		RoomRatePrices.CalendarDayType AS CalendarDayType,
				|		RoomRatePrices.PriceTag AS PriceTag,
				|		RoomRatePrices.ClientType AS ClientType,
				|		RoomRatePrices.RoomType AS RoomType,
				|		RoomRatePrices.RoomType.SortCode AS RoomTypeSortCode,
				|		CASE
				|			WHEN &qAccommodationTypeIsUndefined
				|				THEN TemplateAccommodationTypes.AccommodationType
				|			WHEN ISNULL(RoomRatePrices.Service.ChargeToEachGuestSeparately, FALSE)
				|					AND NOT TemplateAccommodationTypes.AccommodationType.Code IS NULL
				|				THEN TemplateAccommodationTypes.AccommodationType
				|			ELSE &qAccommodationType
				|		END AS AccommodationType,
				|		CASE
				|			WHEN &qAccommodationTypeIsUndefined
				|				THEN TemplateAccommodationTypes.AccommodationType.SortCode
				|			WHEN ISNULL(RoomRatePrices.Service.ChargeToEachGuestSeparately, FALSE)
				|					AND NOT TemplateAccommodationTypes.AccommodationType.Code IS NULL
				|				THEN TemplateAccommodationTypes.AccommodationType.SortCode
				|			ELSE &qAccommodationTypeSortCode
				|		END AS AccommodationTypeSortCode,
				|		RoomRatePrices.SetRoomRatePrices AS SetRoomRatePrices,
				|		CASE
				|			WHEN RoomRateFormulas.ReplaceWithService.Code IS NULL
				|				THEN RoomRatePrices.Service
				|			ELSE RoomRateFormulas.ReplaceWithService
				|		END AS Service,
				|		CASE
				|			WHEN RoomRateFormulas.ReplaceWithService.Code IS NULL
				|				THEN RoomRatePrices.Service.Unit
				|			ELSE RoomRateFormulas.ReplaceWithService.Unit
				|		END AS Unit,
				|		RoomRatePrices.Service AS PricesService,
				|		RoomRatePrices.Currency AS Currency,
				|		RoomRatePrices.MinimumQuantity AS MinimumQuantity,
				|		RoomRatePrices.VATRate AS VATRate,
				|		RoomRatePrices.QuantityCalculationRule AS QuantityCalculationRule,
				|		RoomRatePrices.IsRoomRevenue AS IsRoomRevenue,
				|		RoomRatePrices.IsInPrice AS IsInPrice,
				|		CASE
				|			WHEN RoomRatePrices.IsRoomRevenue
				|					AND RoomRatePrices.IsInPrice
				|				THEN FALSE
				|			ELSE RoomRatePrices.IsPricePerPerson
				|		END AS IsPricePerPerson,
				|		RoomRatePrices.Service.RoomRevenueAmountsOnly AS RoomRevenueAmountsOnly,
				|		RoomRatePrices.SetRoomRatePrices.PointInTime AS PointInTime,
				|		RoomRatePrices.LineNumber AS LineNumber,
				|		RoomRatePrices.SortCode AS SortCode,
				|		(RoomRatePrices.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0) AS Price,
				|		CASE
				|			WHEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons4Reservation, 0) > 0
				|					AND RoomRatePrices.IsPricePerPerson
				|				THEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons4Reservation, 0)
				|			WHEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons, 0) > 0
				|				THEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons, 0)
				|			ELSE 1
				|		END AS NumberOfPersons,
				|		CASE
				|			WHEN RoomRatePrices.IsRoomRevenue
				|				THEN CASE
				|						WHEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons4Reservation, 0) > 0
				|								AND RoomRatePrices.IsPricePerPerson
				|							THEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons4Reservation, 0)
				|						WHEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons, 0) > 0
				|							THEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons, 0)
				|						ELSE 1
				|					END
				|			ELSE 0
				|		END AS NumberOfPersonsInRoom,
				|		CASE
				|			WHEN RoomRatePrices.IsRoomRevenue
				|				THEN ISNULL(RoomRatePrices.AccommodationType.NumberOfRooms, 0)
				|			ELSE 0
				|		END AS NumberOfRooms,
				|		CASE
				|			WHEN RoomRatePrices.IsRoomRevenue
				|				THEN ISNULL(RoomRatePrices.AccommodationType.NumberOfBeds, 0)
				|			ELSE 0
				|		END AS NumberOfBeds,
				|		CASE
				|			WHEN RoomRatePrices.IsRoomRevenue
				|				THEN ISNULL(RoomRatePrices.AccommodationType.NumberOfAdditionalBeds, 0)
				|			ELSE 0
				|		END AS NumberOfAdditionalBeds,
				|		RoomRateFormulas.BracketsConstant AS BracketsConstant,
				|		RoomRateFormulas.Constant AS Constant,
				|		RoomRateFormulas.Multiplier AS Multiplier,
				|		RoomRatePrices.Service.QuantityCalculationRule.QuantityCalculationRuleType AS QuantityCalculationRuleType,
				|		RoomRatePrices.RoomRate.EarlyCheckInService AS EarlyCheckInService,
				|		RoomRatePrices.RoomRate.LateCheckOutService AS LateCheckOutService
				|	FROM
				|		InformationRegister.RoomRatePrices AS RoomRatePrices
				|			INNER JOIN Orders AS Orders
				|			ON (RoomRatePrices.RoomRate = &qPricesRoomRate)
				|				AND (RoomRatePrices.ClientType = &qClientType)
				|				AND RoomRatePrices.SetRoomRatePrices = Orders.SetRoomRatePrices
				|				AND RoomRatePrices.PriceTag = Orders.PriceTag
				|				AND RoomRatePrices.CalendarDayType = Orders.CalendarDayType
				|			INNER JOIN TemplateAccommodationTypes AS TemplateAccommodationTypes
				|			ON (TemplateAccommodationTypes.AccommodationTemplate = &qAccommodationTemplate)
				|				AND RoomRatePrices.Hotel = TemplateAccommodationTypes.Hotel
				|				AND RoomRatePrices.RoomType = TemplateAccommodationTypes.RoomType
				|				AND (TemplateAccommodationTypes.AccommodationType = RoomRatePrices.AccommodationType
				|					OR RoomRatePrices.AccommodationType = &qEmptyAccommodationTypeRef)
				|			LEFT JOIN RoomRateFormulas AS RoomRateFormulas
				|			ON RoomRatePrices.RoomRate = RoomRateFormulas.BasedOnRoomRate
				|				AND RoomRatePrices.Hotel = RoomRateFormulas.Hotel
				|				AND (NOT RoomRateFormulas.IsFormula
				|					OR RoomRateFormulas.IsFormula
				|						AND RoomRatePrices.RoomType = RoomRateFormulas.RoomType
				|						AND RoomRatePrices.ClientType = RoomRateFormulas.ClientType
				|						AND RoomRatePrices.AccommodationType = RoomRateFormulas.AccommodationType
				|						AND (RoomRatePrices.CalendarDayType = RoomRateFormulas.CalendarDayType
				|							OR RoomRateFormulas.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef))
				|						AND (RoomRatePrices.Service = RoomRateFormulas.Service
				|							OR RoomRateFormulas.Service = VALUE(Catalog.Services.EmptyRef)))
				|				AND (RoomRateFormulas.BasedOnPriceTag = VALUE(Catalog.PriceTags.EmptyRef)
				|					OR RoomRatePrices.PriceTag = RoomRateFormulas.BasedOnPriceTag
				|						AND RoomRateFormulas.BasedOnPriceTag <> VALUE(Catalog.PriceTags.EmptyRef))
				|	WHERE
				|		&qFilterByCalendarDayTypes
				|		AND (&qPriceTagIsFilled
				|					AND RoomRatePrices.PriceTag = &qPriceTag
				|				OR NOT &qPriceTagIsFilled)
				|		AND (RoomRatePrices.RoomType = &qRoomType
				|				OR RoomRatePrices.RoomType = &qEmptyRoomTypeRef
				|				OR &qRoomTypeIsUndefined)
				|		AND (NOT &qMinimizeOutput
				|				OR &qMinimizeOutput
				|					AND (RoomRatePrices.IsRoomRevenue
				|						OR NOT RoomRatePrices.IsRoomRevenue
				|							AND RoomRatePrices.IsInPrice
				|							AND RoomRatePrices.Price <> 0))) AS MergedRoomRatePrices
				|
				|GROUP BY
				|	MergedRoomRatePrices.Recorder,
				|	MergedRoomRatePrices.Hotel,
				|	MergedRoomRatePrices.RoomRate,
				|	MergedRoomRatePrices.CalendarDayType,
				|	MergedRoomRatePrices.PriceTag,
				|	MergedRoomRatePrices.ClientType,
				|	MergedRoomRatePrices.RoomType,
				|	MergedRoomRatePrices.RoomTypeSortCode,
				|	MergedRoomRatePrices.AccommodationType,
				|	MergedRoomRatePrices.AccommodationTypeSortCode,
				|	MergedRoomRatePrices.SetRoomRatePrices,
				|	MergedRoomRatePrices.Service,
				|	MergedRoomRatePrices.Unit,
				|	MergedRoomRatePrices.PricesService,
				|	MergedRoomRatePrices.Currency,
				|	MergedRoomRatePrices.MinimumQuantity,
				|	MergedRoomRatePrices.VATRate,
				|	MergedRoomRatePrices.QuantityCalculationRule,
				|	MergedRoomRatePrices.IsRoomRevenue,
				|	MergedRoomRatePrices.IsInPrice,
				|	MergedRoomRatePrices.IsPricePerPerson,
				|	MergedRoomRatePrices.RoomRevenueAmountsOnly,
				|	MergedRoomRatePrices.PointInTime,
				|	MergedRoomRatePrices.QuantityCalculationRuleType,
				|	MergedRoomRatePrices.EarlyCheckInService,
				|	MergedRoomRatePrices.LateCheckOutService
				|
				|UNION ALL
				|
				|SELECT
				|	&qEmptySetRoomRatePricesRef,
				|	&qHotel,
				|	&qRoomRate,
				|	MergedPackageServicesForAccommodationTemplate.CalendarDayType,
				|	MergedPackageServicesForAccommodationTemplate.PriceTag,
				|	MergedPackageServicesForAccommodationTemplate.ClientType,
				|	MergedPackageServicesForAccommodationTemplate.RoomType,
				|	MergedPackageServicesForAccommodationTemplate.RoomTypeSortCode,
				|	MergedPackageServicesForAccommodationTemplate.AccommodationType,
				|	MergedPackageServicesForAccommodationTemplate.AccommodationTypeSortCode,
				|	&qEmptySetRoomRatePricesRef,
				|	MergedPackageServicesForAccommodationTemplate.Service,
				|	MergedPackageServicesForAccommodationTemplate.Unit,
				|	MergedPackageServicesForAccommodationTemplate.PricesService,
				|	MergedPackageServicesForAccommodationTemplate.Currency,
				|	0,
				|	MergedPackageServicesForAccommodationTemplate.VATRate,
				|	MergedPackageServicesForAccommodationTemplate.QuantityCalculationRule,
				|	MergedPackageServicesForAccommodationTemplate.IsRoomRevenue,
				|	MergedPackageServicesForAccommodationTemplate.IsInPrice,
				|	MergedPackageServicesForAccommodationTemplate.IsServicePerPerson,
				|	MergedPackageServicesForAccommodationTemplate.RoomRevenueAmountsOnly,
				|	MergedPackageServicesForAccommodationTemplate.AccountingDate,
				|	MergedPackageServicesForAccommodationTemplate.AccountingDayNumber,
				|	MergedPackageServicesForAccommodationTemplate.Remarks,
				|	MergedPackageServicesForAccommodationTemplate.ServicePackage,
				|	MergedPackageServicesForAccommodationTemplate.ServicePackageDateValidFrom,
				|	MergedPackageServicesForAccommodationTemplate.ServicePackageDateValidTo,
				|	MergedPackageServicesForAccommodationTemplate.ServicePackagePeriodFrom,
				|	MergedPackageServicesForAccommodationTemplate.ServicePackagePeriodTo,
				|	NULL,
				|	MergedPackageServicesForAccommodationTemplate.PacketPriceIsIncludedInRoomRate,
				|	MergedPackageServicesForAccommodationTemplate.ServicePackageUsageType,
				|	MergedPackageServicesForAccommodationTemplate.ServicePackageDateFrom,
				|	MergedPackageServicesForAccommodationTemplate.ServicePackageDateTo,
				|	MIN(MergedPackageServicesForAccommodationTemplate.RowNumber),
				|	999999999,
				|	MergedPackageServicesForAccommodationTemplate.Price,
				|	CASE
				|		WHEN ISNULL(MergedPackageServicesForAccommodationTemplate.Service.IsRoomRevenue, FALSE)
				|				AND NOT ISNULL(MergedPackageServicesForAccommodationTemplate.ServicePackage.IsMealBoardTerm, FALSE)
				|				AND NOT ISNULL(MergedPackageServicesForAccommodationTemplate.Service.RoomRevenueAmountsOnly, FALSE)
				|			THEN MAX(MergedPackageServicesForAccommodationTemplate.Quantity)
				|		ELSE SUM(MergedPackageServicesForAccommodationTemplate.Quantity)
				|	END,
				|	SUM(MergedPackageServicesForAccommodationTemplate.NumberOfPersons),
				|	SUM(MergedPackageServicesForAccommodationTemplate.NumberOfPersonsInRoom),
				|	SUM(MergedPackageServicesForAccommodationTemplate.NumberOfRooms),
				|	SUM(MergedPackageServicesForAccommodationTemplate.NumberOfBeds),
				|	SUM(MergedPackageServicesForAccommodationTemplate.NumberOfAdditionalBeds)
				|FROM
				|	(SELECT
				|		PackageServicesForAccommodationTemplate.CalendarDayType AS CalendarDayType,
				|		ActivePriceTagsList.PriceTag AS PriceTag,
				|		PackageServicesForAccommodationTemplate.ClientType AS ClientType,
				|		PackageServicesForAccommodationTemplate.RoomType AS RoomType,
				|		ISNULL(PackageServicesForAccommodationTemplate.RoomType.SortCode, 0) AS RoomTypeSortCode,
				|		CASE
				|			WHEN &qAccommodationTypeIsUndefined
				|				THEN TemplateAccommodationTypes.AccommodationType
				|			WHEN ISNULL(PackageServicesForAccommodationTemplate.Service.ChargeToEachGuestSeparately, FALSE)
				|					AND NOT TemplateAccommodationTypes.AccommodationType.Code IS NULL
				|				THEN TemplateAccommodationTypes.AccommodationType
				|			ELSE &qAccommodationType
				|		END AS AccommodationType,
				|		CASE
				|			WHEN &qAccommodationTypeIsUndefined
				|				THEN TemplateAccommodationTypes.AccommodationType.SortCode
				|			WHEN ISNULL(PackageServicesForAccommodationTemplate.Service.ChargeToEachGuestSeparately, FALSE)
				|					AND NOT TemplateAccommodationTypes.AccommodationType.Code IS NULL
				|				THEN TemplateAccommodationTypes.AccommodationType.SortCode
				|			ELSE &qAccommodationTypeSortCode
				|		END AS AccommodationTypeSortCode,
				|		CASE
				|			WHEN RoomRateFormulas.ReplaceWithService.Code IS NULL
				|				THEN PackageServicesForAccommodationTemplate.Service
				|			ELSE RoomRateFormulas.ReplaceWithService
				|		END AS Service,
				|		CASE
				|			WHEN RoomRateFormulas.ReplaceWithService.Code IS NULL
				|				THEN PackageServicesForAccommodationTemplate.Unit
				|			ELSE RoomRateFormulas.ReplaceWithService.Unit
				|		END AS Unit,
				|		PackageServicesForAccommodationTemplate.Service AS PricesService,
				|		PackageServicesForAccommodationTemplate.Currency AS Currency,
				|		PackageServicesForAccommodationTemplate.VATRate AS VATRate,
				|		PackageServicesForAccommodationTemplate.QuantityCalculationRule AS QuantityCalculationRule,
				|		CASE
				|			WHEN ISNULL(PackageServicesForAccommodationTemplate.ServicePackage.IsMealBoardTerm, FALSE)
				|				THEN FALSE
				|			ELSE ISNULL(PackageServicesForAccommodationTemplate.Service.IsRoomRevenue, FALSE)
				|		END AS IsRoomRevenue,
				|		PackageServicesForAccommodationTemplate.IsInPrice AS IsInPrice,
				|		PackageServicesForAccommodationTemplate.IsServicePerPerson AS IsServicePerPerson,
				|		ISNULL(PackageServicesForAccommodationTemplate.Service.RoomRevenueAmountsOnly, FALSE) AS RoomRevenueAmountsOnly,
				|		PackageServicesForAccommodationTemplate.AccountingDate AS AccountingDate,
				|		PackageServicesForAccommodationTemplate.AccountingDayNumber AS AccountingDayNumber,
				|		CAST(PackageServicesForAccommodationTemplate.Remarks AS STRING(100)) AS Remarks,
				|		PackageServicesForAccommodationTemplate.ServicePackage AS ServicePackage,
				|		ISNULL(ServicePackages.DateValidFrom, &qEmptyDate) AS ServicePackageDateValidFrom,
				|		ISNULL(ServicePackages.DateValidTo, &qEmptyDate) AS ServicePackageDateValidTo,
				|		ISNULL(PackageServicesForAccommodationTemplate.PeriodFrom, &qEmptyDate) AS ServicePackagePeriodFrom,
				|		ISNULL(PackageServicesForAccommodationTemplate.PeriodTo, &qEmptyDate) AS ServicePackagePeriodTo,
				|		ISNULL(ServicePackages.PacketPriceIsIncludedInRoomRate, FALSE) AS PacketPriceIsIncludedInRoomRate,
				|		ServicePackages.UsageType AS ServicePackageUsageType,
				|		ServicePackages.DateFrom AS ServicePackageDateFrom,
				|		ServicePackages.DateTo AS ServicePackageDateTo,
				|		PackageServicesForAccommodationTemplate.RowNumber AS RowNumber,
				|		(PackageServicesForAccommodationTemplate.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0) AS Price,
				|		PackageServicesForAccommodationTemplate.Quantity * ServicePackages.Quantity AS Quantity,
				|		CASE
				|			WHEN ISNULL(PackageServicesForAccommodationTemplate.AccommodationType.NumberOfPersons4Reservation, 0) > 0
				|					AND PackageServicesForAccommodationTemplate.IsServicePerPerson
				|				THEN ISNULL(PackageServicesForAccommodationTemplate.AccommodationType.NumberOfPersons4Reservation, 0)
				|			WHEN ISNULL(PackageServicesForAccommodationTemplate.AccommodationType.NumberOfPersons, 0) > 0
				|				THEN ISNULL(PackageServicesForAccommodationTemplate.AccommodationType.NumberOfPersons, 0)
				|			ELSE 1
				|		END AS NumberOfPersons,
				|		CASE
				|			WHEN ISNULL(PackageServicesForAccommodationTemplate.Service.IsRoomRevenue, FALSE)
				|					AND NOT ISNULL(ServicePackages.IsMealBoardTerm, FALSE)
				|					AND NOT ISNULL(PackageServicesForAccommodationTemplate.Service.RoomRevenueAmountsOnly, FALSE)
				|				THEN CASE
				|						WHEN ISNULL(PackageServicesForAccommodationTemplate.AccommodationType.NumberOfPersons4Reservation, 0) > 0
				|								AND PackageServicesForAccommodationTemplate.IsServicePerPerson
				|							THEN ISNULL(PackageServicesForAccommodationTemplate.AccommodationType.NumberOfPersons4Reservation, 0)
				|						WHEN ISNULL(PackageServicesForAccommodationTemplate.AccommodationType.NumberOfPersons, 0) > 0
				|							THEN ISNULL(PackageServicesForAccommodationTemplate.AccommodationType.NumberOfPersons, 0)
				|						ELSE 1
				|					END
				|			ELSE 0
				|		END AS NumberOfPersonsInRoom,
				|		CASE
				|			WHEN ISNULL(PackageServicesForAccommodationTemplate.Service.IsRoomRevenue, FALSE)
				|					AND NOT ISNULL(ServicePackages.IsMealBoardTerm, FALSE)
				|					AND NOT ISNULL(PackageServicesForAccommodationTemplate.Service.RoomRevenueAmountsOnly, FALSE)
				|				THEN ISNULL(PackageServicesForAccommodationTemplate.AccommodationType.NumberOfRooms, 0)
				|			ELSE 0
				|		END AS NumberOfRooms,
				|		CASE
				|			WHEN ISNULL(PackageServicesForAccommodationTemplate.Service.IsRoomRevenue, FALSE)
				|					AND NOT ISNULL(ServicePackages.IsMealBoardTerm, FALSE)
				|					AND NOT ISNULL(PackageServicesForAccommodationTemplate.Service.RoomRevenueAmountsOnly, FALSE)
				|				THEN ISNULL(PackageServicesForAccommodationTemplate.AccommodationType.NumberOfBeds, 0)
				|			ELSE 0
				|		END AS NumberOfBeds,
				|		CASE
				|			WHEN ISNULL(PackageServicesForAccommodationTemplate.Service.IsRoomRevenue, FALSE)
				|					AND NOT ISNULL(ServicePackages.IsMealBoardTerm, FALSE)
				|					AND NOT ISNULL(PackageServicesForAccommodationTemplate.Service.RoomRevenueAmountsOnly, FALSE)
				|				THEN ISNULL(PackageServicesForAccommodationTemplate.AccommodationType.NumberOfAdditionalBeds, 0)
				|			ELSE 0
				|		END AS NumberOfAdditionalBeds
				|	FROM
				|		InformationRegister.ServicePackageRecords AS PackageServicesForAccommodationTemplate
				|			INNER JOIN ServicePackages AS ServicePackages
				|			ON PackageServicesForAccommodationTemplate.ServicePackage = ServicePackages.ServicePackage
				|			INNER JOIN ServicePackagesActivePeriods AS ServicePackagesActivePeriods
				|			ON PackageServicesForAccommodationTemplate.ServicePackage = ServicePackagesActivePeriods.ServicePackage
				|				AND PackageServicesForAccommodationTemplate.Period = ServicePackagesActivePeriods.ActivePeriod
				|			LEFT JOIN ActivePriceTags AS ActivePriceTagsList
				|			ON (TRUE)
				|			INNER JOIN TemplateAccommodationTypes AS TemplateAccommodationTypes
				|			ON (TemplateAccommodationTypes.AccommodationTemplate = &qAccommodationTemplate)
				|				AND (TemplateAccommodationTypes.RoomType = PackageServicesForAccommodationTemplate.RoomType
				|					OR PackageServicesForAccommodationTemplate.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
				|				AND (TemplateAccommodationTypes.AccommodationType = PackageServicesForAccommodationTemplate.AccommodationType
				|					OR PackageServicesForAccommodationTemplate.AccommodationType = &qEmptyAccommodationTypeRef)
				|				AND (NOT PackageServicesForAccommodationTemplate.ServicePackage.IsPerPerson
				|						AND NOT &qSplitPackagesByGuests
				|					OR NOT PackageServicesForAccommodationTemplate.ServicePackage.IsPerPerson
				|						AND &qSplitPackagesByGuests
				|						AND TemplateAccommodationTypes.AccommodationType = &qAccommodationType
				|						AND TemplateAccommodationTypes.LineNumber = &qAccommodationTypeLineNumber
				|					OR PackageServicesForAccommodationTemplate.ServicePackage.IsPerPerson
				|						AND TemplateAccommodationTypes.AccommodationType = &qAccommodationType
				|						AND TemplateAccommodationTypes.LineNumber = &qAccommodationTypeLineNumber)
				|			LEFT JOIN RoomRateFormulas AS RoomRateFormulas
				|			ON (RoomRateFormulas.RoomRate = &qRoomRate)
				|				AND (RoomRateFormulas.Hotel = &qHotel)
				|				AND (RoomRateFormulas.IsFormula)
				|				AND PackageServicesForAccommodationTemplate.Service = RoomRateFormulas.Service
				|				AND PackageServicesForAccommodationTemplate.RoomType = RoomRateFormulas.RoomType
				|				AND PackageServicesForAccommodationTemplate.ClientType = RoomRateFormulas.ClientType
				|				AND (PackageServicesForAccommodationTemplate.AccommodationType = RoomRateFormulas.AccommodationType
				|					OR PackageServicesForAccommodationTemplate.AccommodationType = VALUE(Catalog.AccommodationTypes.EmptyRef))
				|				AND (PackageServicesForAccommodationTemplate.CalendarDayType = RoomRateFormulas.CalendarDayType
				|					OR RoomRateFormulas.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef))
				|	WHERE
				|		ServicePackages.DateValidFrom <= &qCheckInDate
				|		AND (ENDOFPERIOD(ServicePackages.DateValidTo, DAY) >= &qCheckInDate
				|				OR ServicePackages.DateValidTo = &qEmptyDate)
				|		AND PackageServicesForAccommodationTemplate.ClientType = &qClientType
				|		AND (PackageServicesForAccommodationTemplate.RoomType = &qRoomType
				|				OR PackageServicesForAccommodationTemplate.RoomType = &qEmptyRoomTypeRef
				|				OR &qRoomTypeIsUndefined)
				|		AND (PackageServicesForAccommodationTemplate.RoomClass = &qRoomClass
				|				OR PackageServicesForAccommodationTemplate.RoomClass = &qEmptyRoomClassRef
				|				OR &qRoomTypeIsUndefined)
				|		AND (NOT &qAccommodationPeriodIsSet
				|				OR &qAccommodationPeriodIsSet
				|					AND (PackageServicesForAccommodationTemplate.CalendarDayType IN (&qCalendarDayTypesList)
				|						OR PackageServicesForAccommodationTemplate.CalendarDayType = &qEmptyCalendarDayType))
				|		AND PackageServicesForAccommodationTemplate.Service IS NOT NULL 
				|		AND PackageServicesForAccommodationTemplate.Service <> &qEmptyService
				|		AND (NOT &qMinimizeOutput
				|				OR &qMinimizeOutput
				|					AND (PackageServicesForAccommodationTemplate.IsInPrice
				|						AND PackageServicesForAccommodationTemplate.Price <> 0))) AS MergedPackageServicesForAccommodationTemplate
				|
				|GROUP BY
				|	MergedPackageServicesForAccommodationTemplate.CalendarDayType,
				|	MergedPackageServicesForAccommodationTemplate.PriceTag,
				|	MergedPackageServicesForAccommodationTemplate.ClientType,
				|	MergedPackageServicesForAccommodationTemplate.RoomType,
				|	MergedPackageServicesForAccommodationTemplate.RoomTypeSortCode,
				|	MergedPackageServicesForAccommodationTemplate.AccommodationType,
				|	MergedPackageServicesForAccommodationTemplate.AccommodationTypeSortCode,
				|	MergedPackageServicesForAccommodationTemplate.Service,
				|	MergedPackageServicesForAccommodationTemplate.Unit,
				|	MergedPackageServicesForAccommodationTemplate.PricesService,
				|	MergedPackageServicesForAccommodationTemplate.Currency,
				|	MergedPackageServicesForAccommodationTemplate.VATRate,
				|	MergedPackageServicesForAccommodationTemplate.QuantityCalculationRule,
				|	MergedPackageServicesForAccommodationTemplate.IsRoomRevenue,
				|	MergedPackageServicesForAccommodationTemplate.IsInPrice,
				|	MergedPackageServicesForAccommodationTemplate.IsServicePerPerson,
				|	MergedPackageServicesForAccommodationTemplate.RoomRevenueAmountsOnly,
				|	MergedPackageServicesForAccommodationTemplate.AccountingDate,
				|	MergedPackageServicesForAccommodationTemplate.AccountingDayNumber,
				|	MergedPackageServicesForAccommodationTemplate.Remarks,
				|	MergedPackageServicesForAccommodationTemplate.ServicePackage,
				|	MergedPackageServicesForAccommodationTemplate.ServicePackageDateValidFrom,
				|	MergedPackageServicesForAccommodationTemplate.ServicePackageDateValidTo,
				|	MergedPackageServicesForAccommodationTemplate.ServicePackagePeriodFrom,
				|	MergedPackageServicesForAccommodationTemplate.ServicePackagePeriodTo,
				|	MergedPackageServicesForAccommodationTemplate.PacketPriceIsIncludedInRoomRate,
				|	MergedPackageServicesForAccommodationTemplate.ServicePackageUsageType,
				|	MergedPackageServicesForAccommodationTemplate.ServicePackageDateFrom,
				|	MergedPackageServicesForAccommodationTemplate.ServicePackageDateTo,
				|	MergedPackageServicesForAccommodationTemplate.Price,
				|	MergedPackageServicesForAccommodationTemplate.Service.IsRoomRevenue,
				|	MergedPackageServicesForAccommodationTemplate.ServicePackage.IsMealBoardTerm,
				|	MergedPackageServicesForAccommodationTemplate.Service.RoomRevenueAmountsOnly
				|
				|UNION ALL
				|
				|SELECT
				|	&qEmptySetRoomRatePricesRef,
				|	&qHotel,
				|	&qRoomRate,
				|	MergedPackageServicesForAccommodationType.CalendarDayType,
				|	MergedPackageServicesForAccommodationType.PriceTag,
				|	MergedPackageServicesForAccommodationType.ClientType,
				|	MergedPackageServicesForAccommodationType.RoomType,
				|	MergedPackageServicesForAccommodationType.RoomTypeSortCode,
				|	&qAccommodationType,
				|	&qAccommodationTypeSortCode,
				|	&qEmptySetRoomRatePricesRef,
				|	MergedPackageServicesForAccommodationType.Service,
				|	MergedPackageServicesForAccommodationType.Unit,
				|	MergedPackageServicesForAccommodationType.PricesService,
				|	MergedPackageServicesForAccommodationType.Currency,
				|	0,
				|	MergedPackageServicesForAccommodationType.VATRate,
				|	MergedPackageServicesForAccommodationType.QuantityCalculationRule,
				|	MergedPackageServicesForAccommodationType.IsRoomRevenue,
				|	MergedPackageServicesForAccommodationType.IsInPrice,
				|	MergedPackageServicesForAccommodationType.IsServicePerPerson,
				|	MergedPackageServicesForAccommodationType.RoomRevenueAmountsOnly,
				|	MergedPackageServicesForAccommodationType.AccountingDate,
				|	MergedPackageServicesForAccommodationType.AccountingDayNumber,
				|	MergedPackageServicesForAccommodationType.Remarks,
				|	MergedPackageServicesForAccommodationType.ServicePackage,
				|	MergedPackageServicesForAccommodationType.ServicePackageDateValidFrom,
				|	MergedPackageServicesForAccommodationType.ServicePackageDateValidTo,
				|	MergedPackageServicesForAccommodationType.ServicePackagePeriodFrom,
				|	MergedPackageServicesForAccommodationType.ServicePackagePeriodTo,
				|	NULL,
				|	MergedPackageServicesForAccommodationType.PacketPriceIsIncludedInRoomRate,
				|	MergedPackageServicesForAccommodationType.ServicePackageUsageType,
				|	MergedPackageServicesForAccommodationType.ServicePackageDateFrom,
				|	MergedPackageServicesForAccommodationType.ServicePackageDateTo,
				|	MIN(MergedPackageServicesForAccommodationType.RowNumber),
				|	999999999,
				|	MergedPackageServicesForAccommodationType.Price,
				|	SUM(MergedPackageServicesForAccommodationType.Quantity),
				|	SUM(MergedPackageServicesForAccommodationType.NumberOfPersons),
				|	SUM(MergedPackageServicesForAccommodationType.NumberOfPersonsInRoom),
				|	SUM(MergedPackageServicesForAccommodationType.NumberOfRooms),
				|	SUM(MergedPackageServicesForAccommodationType.NumberOfBeds),
				|	SUM(MergedPackageServicesForAccommodationType.NumberOfAdditionalBeds)
				|FROM
				|	(SELECT
				|		PackageServicesForAccommodationType.CalendarDayType AS CalendarDayType,
				|		ActivePriceTagsList.PriceTag AS PriceTag,
				|		PackageServicesForAccommodationType.ClientType AS ClientType,
				|		PackageServicesForAccommodationType.RoomType AS RoomType,
				|		ISNULL(PackageServicesForAccommodationType.RoomType.SortCode, 0) AS RoomTypeSortCode,
				|		CASE
				|			WHEN RoomRateFormulas.ReplaceWithService.Code IS NULL
				|				THEN PackageServicesForAccommodationType.Service
				|			ELSE RoomRateFormulas.ReplaceWithService
				|		END AS Service,
				|		CASE
				|			WHEN RoomRateFormulas.ReplaceWithService.Code IS NULL
				|				THEN PackageServicesForAccommodationType.Unit
				|			ELSE RoomRateFormulas.ReplaceWithService.Unit
				|		END AS Unit,
				|		PackageServicesForAccommodationType.Service AS PricesService,
				|		PackageServicesForAccommodationType.Currency AS Currency,
				|		PackageServicesForAccommodationType.VATRate AS VATRate,
				|		PackageServicesForAccommodationType.QuantityCalculationRule AS QuantityCalculationRule,
				|		CASE
				|			WHEN ISNULL(ServicePackages.IsMealBoardTerm, FALSE)
				|				THEN FALSE
				|			ELSE ISNULL(PackageServicesForAccommodationType.Service.IsRoomRevenue, FALSE)
				|		END AS IsRoomRevenue,
				|		PackageServicesForAccommodationType.IsInPrice AS IsInPrice,
				|		PackageServicesForAccommodationType.IsServicePerPerson AS IsServicePerPerson,
				|		ISNULL(PackageServicesForAccommodationType.Service.RoomRevenueAmountsOnly, FALSE) AS RoomRevenueAmountsOnly,
				|		PackageServicesForAccommodationType.AccountingDate AS AccountingDate,
				|		PackageServicesForAccommodationType.AccountingDayNumber AS AccountingDayNumber,
				|		CAST(PackageServicesForAccommodationType.Remarks AS STRING(100)) AS Remarks,
				|		PackageServicesForAccommodationType.ServicePackage AS ServicePackage,
				|		ISNULL(ServicePackages.DateValidFrom, &qEmptyDate) AS ServicePackageDateValidFrom,
				|		ISNULL(ServicePackages.DateValidTo, &qEmptyDate) AS ServicePackageDateValidTo,
				|		ISNULL(PackageServicesForAccommodationType.PeriodFrom, &qEmptyDate) AS ServicePackagePeriodFrom,
				|		ISNULL(PackageServicesForAccommodationType.PeriodTo, &qEmptyDate) AS ServicePackagePeriodTo,
				|		ISNULL(ServicePackages.PacketPriceIsIncludedInRoomRate, FALSE) AS PacketPriceIsIncludedInRoomRate,
				|		ServicePackages.UsageType AS ServicePackageUsageType,
				|		ServicePackages.DateFrom AS ServicePackageDateFrom,
				|		ServicePackages.DateTo AS ServicePackageDateTo,
				|		PackageServicesForAccommodationType.RowNumber AS RowNumber,
				|		(PackageServicesForAccommodationType.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0) AS Price,
				|		PackageServicesForAccommodationType.Quantity * ServicePackages.Quantity AS Quantity,
				|		CASE
				|			WHEN ISNULL(PackageServicesForAccommodationType.AccommodationType.NumberOfPersons4Reservation, 0) > 0
				|					AND PackageServicesForAccommodationType.IsServicePerPerson
				|				THEN ISNULL(PackageServicesForAccommodationType.AccommodationType.NumberOfPersons4Reservation, 0)
				|			WHEN ISNULL(PackageServicesForAccommodationType.AccommodationType.NumberOfPersons, 0) > 0
				|				THEN ISNULL(PackageServicesForAccommodationType.AccommodationType.NumberOfPersons, 0)
				|			ELSE 1
				|		END AS NumberOfPersons,
				|		CASE
				|			WHEN ISNULL(PackageServicesForAccommodationType.Service.IsRoomRevenue, FALSE)
				|					AND NOT ISNULL(ServicePackages.IsMealBoardTerm, FALSE)
				|					AND NOT ISNULL(PackageServicesForAccommodationType.Service.RoomRevenueAmountsOnly, FALSE)
				|				THEN CASE
				|						WHEN ISNULL(PackageServicesForAccommodationType.AccommodationType.NumberOfPersons4Reservation, 0) > 0
				|								AND PackageServicesForAccommodationType.IsServicePerPerson
				|							THEN ISNULL(PackageServicesForAccommodationType.AccommodationType.NumberOfPersons4Reservation, 0)
				|						WHEN ISNULL(PackageServicesForAccommodationType.AccommodationType.NumberOfPersons, 0) > 0
				|							THEN ISNULL(PackageServicesForAccommodationType.AccommodationType.NumberOfPersons, 0)
				|						ELSE 1
				|					END
				|			ELSE 0
				|		END AS NumberOfPersonsInRoom,
				|		CASE
				|			WHEN ISNULL(PackageServicesForAccommodationType.Service.IsRoomRevenue, FALSE)
				|					AND NOT ISNULL(ServicePackages.IsMealBoardTerm, FALSE)
				|					AND NOT ISNULL(PackageServicesForAccommodationType.Service.RoomRevenueAmountsOnly, FALSE)
				|				THEN ISNULL(PackageServicesForAccommodationType.AccommodationType.NumberOfRooms, 0)
				|			ELSE 0
				|		END AS NumberOfRooms,
				|		CASE
				|			WHEN ISNULL(PackageServicesForAccommodationType.Service.IsRoomRevenue, FALSE)
				|					AND NOT ISNULL(ServicePackages.IsMealBoardTerm, FALSE)
				|					AND NOT ISNULL(PackageServicesForAccommodationType.Service.RoomRevenueAmountsOnly, FALSE)
				|				THEN ISNULL(PackageServicesForAccommodationType.AccommodationType.NumberOfBeds, 0)
				|			ELSE 0
				|		END AS NumberOfBeds,
				|		CASE
				|			WHEN ISNULL(PackageServicesForAccommodationType.Service.IsRoomRevenue, FALSE)
				|					AND NOT ISNULL(ServicePackages.IsMealBoardTerm, FALSE)
				|					AND NOT ISNULL(PackageServicesForAccommodationType.Service.RoomRevenueAmountsOnly, FALSE)
				|				THEN ISNULL(PackageServicesForAccommodationType.AccommodationType.NumberOfAdditionalBeds, 0)
				|			ELSE 0
				|		END AS NumberOfAdditionalBeds,
				|		RoomRateFormulas.BracketsConstant AS BracketsConstant,
				|		RoomRateFormulas.Constant AS Constant,
				|		RoomRateFormulas.Multiplier AS Multiplier
				|	FROM
				|		InformationRegister.ServicePackageRecords AS PackageServicesForAccommodationType
				|			INNER JOIN ServicePackages AS ServicePackages
				|			ON PackageServicesForAccommodationType.ServicePackage = ServicePackages.ServicePackage
				|			INNER JOIN ServicePackagesActivePeriods AS ServicePackagesActivePeriods
				|			ON PackageServicesForAccommodationType.ServicePackage = ServicePackagesActivePeriods.ServicePackage
				|				AND PackageServicesForAccommodationType.Period = ServicePackagesActivePeriods.ActivePeriod
				|			LEFT JOIN ActivePriceTags AS ActivePriceTagsList
				|			ON (TRUE)
				|			LEFT JOIN RoomRateFormulas AS RoomRateFormulas
				|			ON (RoomRateFormulas.RoomRate = &qRoomRate)
				|				AND (RoomRateFormulas.Hotel = &qHotel)
				|				AND (RoomRateFormulas.IsFormula)
				|				AND PackageServicesForAccommodationType.Service = RoomRateFormulas.Service
				|				AND PackageServicesForAccommodationType.RoomType = RoomRateFormulas.RoomType
				|				AND PackageServicesForAccommodationType.ClientType = RoomRateFormulas.ClientType
				|				AND (PackageServicesForAccommodationType.AccommodationType = RoomRateFormulas.AccommodationType
				|					OR PackageServicesForAccommodationType.AccommodationType = VALUE(Catalog.AccommodationTypes.EmptyRef))
				|				AND (PackageServicesForAccommodationType.CalendarDayType = RoomRateFormulas.CalendarDayType
				|					OR RoomRateFormulas.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef))
				|	WHERE
				|		ServicePackages.DateValidFrom <= &qCheckInDate
				|		AND (ENDOFPERIOD(ServicePackages.DateValidTo, DAY) >= &qCheckInDate
				|				OR ServicePackages.DateValidTo = &qEmptyDate)
				|		AND PackageServicesForAccommodationType.ClientType = &qClientType
				|		AND (PackageServicesForAccommodationType.RoomType = &qRoomType
				|				OR PackageServicesForAccommodationType.RoomType = &qEmptyRoomTypeRef
				|				OR &qRoomTypeIsUndefined)
				|		AND (PackageServicesForAccommodationType.RoomClass = &qRoomClass
				|				OR PackageServicesForAccommodationType.RoomClass = &qEmptyRoomClassRef
				|				OR &qRoomTypeIsUndefined)
				|		AND (NOT &qAccommodationPeriodIsSet
				|				OR &qAccommodationPeriodIsSet
				|					AND (PackageServicesForAccommodationType.CalendarDayType IN (&qCalendarDayTypesList)
				|						OR PackageServicesForAccommodationType.CalendarDayType = &qEmptyCalendarDayType))
				|		AND PackageServicesForAccommodationType.AccommodationType = &qAccommodationType
				|		AND &qAccommodationTypeIsFilled
				|		AND NOT PackageServicesForAccommodationType.AccommodationType IN
				|					(SELECT DISTINCT
				|						TemplateAccommodationTypes.AccommodationType
				|					FROM
				|						TemplateAccommodationTypes AS TemplateAccommodationTypes
				|					WHERE
				|						TemplateAccommodationTypes.AccommodationTemplate = &qAccommodationTemplate)
				|		AND PackageServicesForAccommodationType.Service IS NOT NULL 
				|		AND PackageServicesForAccommodationType.Service <> &qEmptyService
				|		AND (NOT &qMinimizeOutput
				|				OR &qMinimizeOutput
				|					AND (PackageServicesForAccommodationType.IsInPrice
				|						AND PackageServicesForAccommodationType.Price <> 0))) AS MergedPackageServicesForAccommodationType
				|
				|GROUP BY
				|	MergedPackageServicesForAccommodationType.CalendarDayType,
				|	MergedPackageServicesForAccommodationType.PriceTag,
				|	MergedPackageServicesForAccommodationType.ClientType,
				|	MergedPackageServicesForAccommodationType.RoomType,
				|	MergedPackageServicesForAccommodationType.RoomTypeSortCode,
				|	MergedPackageServicesForAccommodationType.Service,
				|	MergedPackageServicesForAccommodationType.Unit,
				|	MergedPackageServicesForAccommodationType.PricesService,
				|	MergedPackageServicesForAccommodationType.Currency,
				|	MergedPackageServicesForAccommodationType.VATRate,
				|	MergedPackageServicesForAccommodationType.QuantityCalculationRule,
				|	MergedPackageServicesForAccommodationType.IsRoomRevenue,
				|	MergedPackageServicesForAccommodationType.IsInPrice,
				|	MergedPackageServicesForAccommodationType.IsServicePerPerson,
				|	MergedPackageServicesForAccommodationType.RoomRevenueAmountsOnly,
				|	MergedPackageServicesForAccommodationType.AccountingDate,
				|	MergedPackageServicesForAccommodationType.AccountingDayNumber,
				|	MergedPackageServicesForAccommodationType.Remarks,
				|	MergedPackageServicesForAccommodationType.ServicePackage,
				|	MergedPackageServicesForAccommodationType.ServicePackageDateValidFrom,
				|	MergedPackageServicesForAccommodationType.ServicePackageDateValidTo,
				|	MergedPackageServicesForAccommodationType.ServicePackagePeriodFrom,
				|	MergedPackageServicesForAccommodationType.ServicePackagePeriodTo,
				|	MergedPackageServicesForAccommodationType.PacketPriceIsIncludedInRoomRate,
				|	MergedPackageServicesForAccommodationType.ServicePackageUsageType,
				|	MergedPackageServicesForAccommodationType.ServicePackageDateFrom,
				|	MergedPackageServicesForAccommodationType.ServicePackageDateTo,
				|	MergedPackageServicesForAccommodationType.Price 
				|ORDER BY " + 
				?(pSortByPointInTime, "PointInTime DESC, ", "") + "
				|	SortCode,
				|	LineNumber";
				vQry.SetParameter("qOrders", vOrders);
				vQry.SetParameter("qServicePackages", vServicePackages);
				vQry.SetParameter("qCalendarDayTypesList", vDayTypesList);
				vQry.SetParameter("qHotel", vHotel);
				vQry.SetParameter("qRoomRate", pRoomRate);
				vQry.SetParameter("qPricesRoomRate", ?(ValueIsFilled(pRoomRate.BasedOnRoomRate), pRoomRate.BasedOnRoomRate, pRoomRate));
				vQry.SetParameter("qPriceTagType", pRoomRate.PriceTagType);
				vQry.SetParameter("qPriceTag", ?(pPriceTag = Undefined, Catalogs.PriceTags.EmptyRef(), pPriceTag));
				vQry.SetParameter("qPriceTagIsFilled", ?(pPriceTag = Undefined, False, True));
				vQry.SetParameter("qClientType", pClientType);
				vQry.SetParameter("qRoomType", pRoomType);
				vQry.SetParameter("qEmptyRoomTypeRef", Catalogs.RoomTypes.EmptyRef());
				vQry.SetParameter("qRoomTypeIsUndefined", ?(pRoomType = Undefined, True, False));
				vQry.SetParameter("qRoomClass", ?(ValueIsFilled(pRoomType) And Not pRoomType.IsFolder, pRoomType.RoomClass, Catalogs.RoomTypeClasses.EmptyRef()));
				vQry.SetParameter("qEmptyRoomClassRef", Catalogs.RoomTypeClasses.EmptyRef());
				vQry.SetParameter("qAccommodationTemplate", pAccommodationTemplate);
				vQry.SetParameter("qAccommodationType", pAccommodationType);
				vQry.SetParameter("qAccommodationTypeIsFilled", ValueIsFilled(pAccommodationType));
				vQry.SetParameter("qAccommodationTypeSortCode", ?(ValueIsFilled(pAccommodationType), pAccommodationType.SortCode, 999999999));
				vQry.SetParameter("qEmptyAccommodationTypeRef", Catalogs.AccommodationTypes.EmptyRef());
				vQry.SetParameter("qAccommodationTypeIsUndefined", ?(pAccommodationType = Undefined, True, False));
				vQry.SetParameter("qEmptySetRoomRatePricesRef", Documents.SetRoomRatePrices.EmptyRef());
				vQry.SetParameter("qDate", ?(ValueIsFilled(vPriceCalculationDate), vPriceCalculationDate, pDate));
				vQry.SetParameter("qCheckInDate", ?(ValueIsFilled(pCheckInDate), BegOfDay(pCheckInDate), pDate));
				vQry.SetParameter("qCheckOutDate", ?(ValueIsFilled(pCheckOutDate), BegOfDay(pCheckOutDate), BegOfDay(pDate)));
				vQry.SetParameter("qAccommodationPeriodIsSet", vAccommodationPeriodIsSet);
				vQry.SetParameter("qMinimizeOutput", pMinimizeOutput);
				vQry.SetParameter("qEmptyDate", '00010101');
				vQry.SetParameter("qEndOfTime", '39991231');
				vQry.SetParameter("qEmptyString", "");
				vQry.SetParameter("qEmptyService", Catalogs.Services.EmptyRef());
				vQry.SetParameter("qSplitPackagesByGuests", vSplitPackagesByGuests);
				If ValueIsFilled(pAccommodationTemplate) And ValueIsFilled(pAccommodationType) Then
					vAccommodationTemplateAccommodationTypesRow = pAccommodationTemplate.AccommodationTypes.Find(pAccommodationType, "AccommodationType");
					If vAccommodationTemplateAccommodationTypesRow <> Undefined Then
						vQry.SetParameter("qAccommodationTypeLineNumber", vAccommodationTemplateAccommodationTypesRow.LineNumber);
					Else
						vQry.SetParameter("qAccommodationTypeLineNumber", 0);
					EndIf;
				Else
					vQry.SetParameter("qAccommodationTypeLineNumber", 0);
				EndIf;
				vQry.SetParameter("qEmptyCalendarDayType", Catalogs.CalendarDayTypes.EmptyRef());
				If vDayTypes.Count() > 0 Then
					For i = 0 To (vDayTypes.Count() - 1) Do
						vDayTypesRow = vDayTypes.Get(i);
						vQry.SetParameter("qCalendarDayType" + Format(i, "NFD=0; NZ=; NG="), vDayTypesRow.CalendarDayType);
					EndDo;
				EndIf;
				vQry.Text = StrReplace(vQry.Text, "&qFilterByCalendarDayTypes", vFilterByCalendarDayTypes);
				vPrices = vQry.Execute().Unload();
			Else
				vQry = New Query;
				vQry.Text = 
				"SELECT
				|	ServicePackages.ServicePackage AS ServicePackage,
				|	ServicePackages.Quantity AS Quantity,
				|	ServicePackages.DateFrom AS DateFrom,
				|	ServicePackages.DateTo AS DateTo,
				|	ServicePackages.PacketPriceIsIncludedInRoomRate AS PacketPriceIsIncludedInRoomRate,
				|	ServicePackages.IsExtraPackage AS IsExtraPackage,
				|	ServicePackages.IsMealBoardTerm AS IsMealBoardTerm,
				|	ServicePackages.IsPerPerson AS IsPerPerson,
				|	ServicePackages.UsageType AS UsageType,
				|	ServicePackages.DateValidFrom AS DateValidFrom,
				|	ServicePackages.DateValidTo AS DateValidTo
				|INTO ServicePackages
				|FROM
				|	&qServicePackages AS ServicePackages
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	ServicePackagePeriods.ServicePackage AS ServicePackage,
				|	MAX(ServicePackagePeriods.Period) AS ActivePeriod
				|INTO ServicePackagesActivePeriods
				|FROM
				|	InformationRegister.ServicePackageRecords.SliceLast(&qDate, ) AS ServicePackagePeriods
				|		INNER JOIN ServicePackages AS ServicePackages
				|		ON (ServicePackages.ServicePackage = ServicePackagePeriods.ServicePackage)
				|
				|GROUP BY
				|	ServicePackagePeriods.ServicePackage
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	Orders.CalendarDayType AS CalendarDayType,
				|	Orders.PriceTag AS PriceTag,
				|	Orders.SetRoomRatePrices AS SetRoomRatePrices
				|INTO Orders
				|FROM
				|	&qOrders AS Orders
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	RoomRatesSliceLast.SetRoomRateFormulas AS Recorder,
				|	RoomRatesSliceLast.RoomRate AS RoomRate
				|INTO ActiveSetRoomRateFormulas
				|FROM
				|	InformationRegister.RoomRates.SliceLast(
				|			&qDate,
				|			RoomRate = &qRoomRate
				|				AND Hotel = &qHotel
				|				AND IsFormula) AS RoomRatesSliceLast
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	RoomRateFormulas.RoomRate.BasedOnRoomRate AS BasedOnRoomRate,
				|	RoomRateFormulas.RoomRate.BasedOnPriceTag AS BasedOnPriceTag,
				|	RoomRateFormulas.RoomRate AS RoomRate,
				|	RoomRateFormulas.Hotel AS Hotel,
				|	RoomRateFormulas.IsFormula AS IsFormula,
				|	RoomRateFormulas.Service AS Service,
				|	RoomRateFormulas.RoomType AS RoomType,
				|	RoomRateFormulas.AccommodationType AS AccommodationType,
				|	RoomRateFormulas.ClientType AS ClientType,
				|	RoomRateFormulas.CalendarDayType AS CalendarDayType,
				|	RoomRateFormulas.Recorder AS Recorder,
				|	RoomRateFormulas.Period AS Period,
				|	RoomRateFormulas.BracketsConstant AS BracketsConstant,
				|	RoomRateFormulas.Constant AS Constant,
				|	RoomRateFormulas.Multiplier AS Multiplier,
				|	RoomRateFormulas.ReplaceWithService AS ReplaceWithService
				|INTO RoomRateFormulas
				|FROM
				|	InformationRegister.RoomRateFormulas AS RoomRateFormulas
				|		INNER JOIN ActiveSetRoomRateFormulas AS ActiveSetRoomRateFormulas
				|		ON RoomRateFormulas.Recorder = ActiveSetRoomRateFormulas.Recorder
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT DISTINCT
				|	ActivePriceTags.PriceTag AS PriceTag
				|INTO ActivePriceTags
				|FROM
				|	InformationRegister.RoomRatePrices AS ActivePriceTags
				|		INNER JOIN Orders AS Orders
				|		ON ActivePriceTags.SetRoomRatePrices = Orders.SetRoomRatePrices
				|			AND ActivePriceTags.CalendarDayType = Orders.CalendarDayType
				|			AND ActivePriceTags.PriceTag = Orders.PriceTag
				|WHERE
				|	ActivePriceTags.RoomRate = &qPricesRoomRate
				|	AND ActivePriceTags.ClientType = &qClientType
				|	AND (&qPriceTagIsFilled
				|				AND ActivePriceTags.PriceTag = &qPriceTag
				|			OR NOT &qPriceTagIsFilled)
				|	AND (ActivePriceTags.RoomType = &qRoomType
				|			OR ActivePriceTags.RoomType = &qEmptyRoomTypeRef
				|			OR &qRoomTypeIsUndefined)
				|	AND (ActivePriceTags.AccommodationType = &qAccommodationType
				|			OR ActivePriceTags.AccommodationType = &qEmptyAccommodationTypeRef
				|			OR &qAccommodationTypeIsUndefined)
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	RoomRatePrices.Recorder AS Recorder,
				|	RoomRatePrices.Hotel AS Hotel,
				|	RoomRatePrices.RoomRate AS RoomRate,
				|	RoomRatePrices.CalendarDayType AS CalendarDayType,
				|	RoomRatePrices.PriceTag AS PriceTag,
				|	RoomRatePrices.ClientType AS ClientType,
				|	RoomRatePrices.RoomType AS RoomType,
				|	RoomRatePrices.RoomType.SortCode AS RoomTypeSortCode,
				|	RoomRatePrices.AccommodationType AS AccommodationType,
				|	RoomRatePrices.AccommodationType.SortCode AS AccommodationTypeSortCode,
				|	RoomRatePrices.SetRoomRatePrices AS SetRoomRatePrices,
				|	RoomRatePrices.SortCode AS SortCode,
				|	RoomRatePrices.Service AS Service,
				|	RoomRatePrices.Service.Unit AS Unit,
				|	RoomRatePrices.Service AS PricesService,
				|	RoomRatePrices.Currency AS Currency,
				|	RoomRatePrices.MinimumQuantity AS MinimumQuantity,
				|	RoomRatePrices.VATRate AS VATRate,
				|	RoomRatePrices.QuantityCalculationRule AS QuantityCalculationRule,
				|	RoomRatePrices.IsRoomRevenue AS IsRoomRevenue,
				|	RoomRatePrices.IsInPrice AS IsInPrice,
				|	RoomRatePrices.IsPricePerPerson AS IsPricePerPerson,
				|	RoomRatePrices.Service.RoomRevenueAmountsOnly AS RoomRevenueAmountsOnly,
				|	&qEmptyDate AS AccountingDate,
				|	0 AS AccountingDayNumber,
				|	&qEmptyString AS Remarks,
				|	NULL AS ServicePackage,
				|	&qEmptyDate AS ServicePackageDateValidFrom,
				|	&qEmptyDate AS ServicePackageDateValidTo,
				|	&qEmptyDate AS ServicePackagePeriodFrom,
				|	&qEmptyDate AS ServicePackagePeriodTo,
				|	RoomRatePrices.SetRoomRatePrices.PointInTime AS PointInTime,
				|	FALSE AS PacketPriceIsIncludedInRoomRate,
				|	UNDEFINED AS ServicePackageUsageType,
				|	&qEmptyDate AS ServicePackageDateFrom,
				|	&qEndOfTime AS ServicePackageDateTo,
				|	0 AS LineNumber,
				|	RoomRatePrices.Price AS Price,
				|	1 AS Quantity,
				|	CASE
				|		WHEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons4Reservation, 0) > 0
				|				AND RoomRatePrices.IsPricePerPerson
				|			THEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons4Reservation, 0)
				|		WHEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons, 0) > 0
				|			THEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons, 0)
				|		ELSE 1
				|	END AS NumberOfPersons,
				|	0 AS NumberOfPersonsInRoom,
				|	0 AS NumberOfRooms,
				|	0 AS NumberOfBeds,
				|	0 AS NumberOfAdditionalBeds
				|FROM
				|	InformationRegister.RoomRatePrices AS RoomRatePrices
				|WHERE
				|	FALSE
				|
				|UNION ALL
				|
				|SELECT
				|	&qEmptySetRoomRatePricesRef,
				|	&qHotel,
				|	&qRoomRate,
				|	PackageServicesForPriceTags.CalendarDayType,
				|	ActivePriceTagsList.PriceTag,
				|	PackageServicesForPriceTags.ClientType,
				|	PackageServicesForPriceTags.RoomType,
				|	0,
				|	&qAccommodationType,
				|	&qAccommodationTypeSortCode,
				|	&qEmptySetRoomRatePricesRef,
				|	0,
				|	CASE
				|		WHEN RoomRateFormulas.ReplaceWithService.Code IS NULL
				|			THEN PackageServicesForPriceTags.Service
				|		ELSE RoomRateFormulas.ReplaceWithService
				|	END,
				|	CASE
				|		WHEN RoomRateFormulas.ReplaceWithService.Code IS NULL
				|			THEN PackageServicesForPriceTags.Unit
				|		ELSE RoomRateFormulas.ReplaceWithService.Unit
				|	END,
				|	PackageServicesForPriceTags.Service,
				|	PackageServicesForPriceTags.Currency,
				|	0,
				|	PackageServicesForPriceTags.VATRate,
				|	PackageServicesForPriceTags.QuantityCalculationRule,
				|	CASE
				|		WHEN ISNULL(ServicePackages.IsMealBoardTerm, FALSE)
				|			THEN FALSE
				|		ELSE ISNULL(PackageServicesForPriceTags.Service.IsRoomRevenue, FALSE)
				|	END,
				|	PackageServicesForPriceTags.IsInPrice,
				|	PackageServicesForPriceTags.IsServicePerPerson,
				|	ISNULL(PackageServicesForPriceTags.Service.RoomRevenueAmountsOnly, FALSE),
				|	PackageServicesForPriceTags.AccountingDate,
				|	PackageServicesForPriceTags.AccountingDayNumber,
				|	CAST(PackageServicesForPriceTags.Remarks AS STRING(100)),
				|	PackageServicesForPriceTags.ServicePackage,
				|	ISNULL(ServicePackages.DateValidFrom, &qEmptyDate),
				|	ISNULL(ServicePackages.DateValidTo, &qEmptyDate),
				|	ISNULL(PackageServicesForPriceTags.PeriodFrom, &qEmptyDate),
				|	ISNULL(PackageServicesForPriceTags.PeriodTo, &qEmptyDate),
				|	NULL,
				|	FALSE,
				|	ServicePackages.UsageType,
				|	ServicePackages.DateFrom,
				|	ServicePackages.DateTo,
				|	MIN(PackageServicesForPriceTags.RowNumber),
				|	(PackageServicesForPriceTags.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0),
				|	SUM(PackageServicesForPriceTags.Quantity * ServicePackages.Quantity),
				|	SUM(CASE
				|			WHEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfPersons4Reservation, 0) > 0
				|					AND PackageServicesForPriceTags.IsServicePerPerson
				|				THEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfPersons4Reservation, 0)
				|			WHEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfPersons, 0) > 0
				|				THEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfPersons, 0)
				|			ELSE 1
				|		END),
				|	SUM(CASE
				|			WHEN ISNULL(PackageServicesForPriceTags.Service.IsRoomRevenue, FALSE)
				|					AND NOT ISNULL(ServicePackages.IsMealBoardTerm, FALSE)
				|				THEN CASE
				|						WHEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfPersons4Reservation, 0) > 0
				|								AND PackageServicesForPriceTags.IsServicePerPerson
				|							THEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfPersons4Reservation, 0)
				|						WHEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfPersons, 0) > 0
				|							THEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfPersons, 0)
				|						ELSE 1
				|					END
				|			ELSE 0
				|		END),
				|	SUM(CASE
				|			WHEN ISNULL(PackageServicesForPriceTags.Service.IsRoomRevenue, FALSE)
				|					AND NOT ISNULL(ServicePackages.IsMealBoardTerm, FALSE)
				|				THEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfRooms, 0)
				|			ELSE 0
				|		END),
				|	SUM(CASE
				|			WHEN ISNULL(PackageServicesForPriceTags.Service.IsRoomRevenue, FALSE)
				|					AND NOT ISNULL(ServicePackages.IsMealBoardTerm, FALSE)
				|				THEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfBeds, 0)
				|			ELSE 0
				|		END),
				|	SUM(CASE
				|			WHEN ISNULL(PackageServicesForPriceTags.Service.IsRoomRevenue, FALSE)
				|					AND NOT ISNULL(ServicePackages.IsMealBoardTerm, FALSE)
				|				THEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfAdditionalBeds, 0)
				|			ELSE 0
				|		END)
				|FROM
				|	InformationRegister.ServicePackageRecords AS PackageServicesForPriceTags
				|		INNER JOIN ServicePackages AS ServicePackages
				|		ON (ServicePackages.ServicePackage = PackageServicesForPriceTags.ServicePackage)
				|			AND (ServicePackages.IsExtraPackage)
				|		INNER JOIN ServicePackagesActivePeriods AS ServicePackagesActivePeriods
				|		ON PackageServicesForPriceTags.ServicePackage = ServicePackagesActivePeriods.ServicePackage
				|			AND PackageServicesForPriceTags.Period = ServicePackagesActivePeriods.ActivePeriod
				|		LEFT JOIN ActivePriceTags AS ActivePriceTagsList
				|		ON (TRUE)
				|		LEFT JOIN RoomRateFormulas AS RoomRateFormulas
				|		ON (RoomRateFormulas.RoomRate = &qRoomRate)
				|			AND (RoomRateFormulas.Hotel = &qHotel)
				|			AND (RoomRateFormulas.IsFormula)
				|			AND PackageServicesForPriceTags.Service = RoomRateFormulas.Service
				|			AND PackageServicesForPriceTags.RoomType = RoomRateFormulas.RoomType
				|			AND PackageServicesForPriceTags.ClientType = RoomRateFormulas.ClientType
				|			AND (PackageServicesForPriceTags.AccommodationType = RoomRateFormulas.AccommodationType
				|				OR PackageServicesForPriceTags.AccommodationType = VALUE(Catalog.AccommodationTypes.EmptyRef))
				|			AND (PackageServicesForPriceTags.CalendarDayType = RoomRateFormulas.CalendarDayType
				|				OR RoomRateFormulas.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef))
				|WHERE
				|	ServicePackages.DateValidFrom <= &qCheckInDate
				|	AND (ENDOFPERIOD(ServicePackages.DateValidTo, DAY) >= &qCheckInDate
				|			OR ServicePackages.DateValidTo = &qEmptyDate)
				|	AND PackageServicesForPriceTags.ClientType = &qClientType
				|	AND (PackageServicesForPriceTags.AccommodationType = &qAccommodationType
				|			OR PackageServicesForPriceTags.AccommodationType = &qEmptyAccommodationTypeRef
				|			OR &qAccommodationTypeIsUndefined)
				|	AND (PackageServicesForPriceTags.RoomType = &qRoomType
				|			OR PackageServicesForPriceTags.RoomType = &qEmptyRoomTypeRef
				|			OR &qRoomTypeIsUndefined)
				|	AND (PackageServicesForPriceTags.RoomClass = &qRoomClass
				|			OR PackageServicesForPriceTags.RoomClass = &qEmptyRoomClassRef
				|			OR &qRoomTypeIsUndefined)
				|	AND (NOT &qAccommodationPeriodIsSet
				|			OR &qAccommodationPeriodIsSet
				|				AND (PackageServicesForPriceTags.CalendarDayType IN (&qCalendarDayTypesList)
				|					OR PackageServicesForPriceTags.CalendarDayType = &qEmptyCalendarDayType))
				|	AND PackageServicesForPriceTags.Service IS NOT NULL 
				|	AND PackageServicesForPriceTags.Service <> &qEmptyService
				|	AND (NOT &qMinimizeOutput
				|			OR &qMinimizeOutput
				|				AND (PackageServicesForPriceTags.IsInPrice
				|					AND PackageServicesForPriceTags.Price <> 0))
				|
				|GROUP BY
				|	PackageServicesForPriceTags.CalendarDayType,
				|	PackageServicesForPriceTags.RowNumber,
				|	ActivePriceTagsList.PriceTag,
				|	PackageServicesForPriceTags.ClientType,
				|	PackageServicesForPriceTags.RoomType,
				|	CASE
				|		WHEN RoomRateFormulas.ReplaceWithService.Code IS NULL
				|			THEN PackageServicesForPriceTags.Service
				|		ELSE RoomRateFormulas.ReplaceWithService
				|	END,
				|	CASE
				|		WHEN RoomRateFormulas.ReplaceWithService.Code IS NULL
				|			THEN PackageServicesForPriceTags.Unit
				|		ELSE RoomRateFormulas.ReplaceWithService.Unit
				|	END,
				|	PackageServicesForPriceTags.Service,
				|	PackageServicesForPriceTags.Currency,
				|	PackageServicesForPriceTags.VATRate,
				|	PackageServicesForPriceTags.QuantityCalculationRule,
				|	CASE
				|		WHEN ISNULL(ServicePackages.IsMealBoardTerm, FALSE)
				|			THEN FALSE
				|		ELSE ISNULL(PackageServicesForPriceTags.Service.IsRoomRevenue, FALSE)
				|	END,
				|	PackageServicesForPriceTags.IsInPrice,
				|	PackageServicesForPriceTags.IsServicePerPerson,
				|	ISNULL(PackageServicesForPriceTags.Service.RoomRevenueAmountsOnly, FALSE),
				|	PackageServicesForPriceTags.AccountingDate,
				|	PackageServicesForPriceTags.AccountingDayNumber,
				|	CAST(PackageServicesForPriceTags.Remarks AS STRING(100)),
				|	PackageServicesForPriceTags.ServicePackage,
				|	ISNULL(ServicePackages.DateValidFrom, &qEmptyDate),
				|	ISNULL(ServicePackages.DateValidTo, &qEmptyDate),
				|	ISNULL(PackageServicesForPriceTags.PeriodFrom, &qEmptyDate),
				|	ISNULL(PackageServicesForPriceTags.PeriodTo, &qEmptyDate),
				|	ServicePackages.UsageType,
				|	ServicePackages.DateFrom,
				|	ServicePackages.DateTo,
				|	PackageServicesForPriceTags.Price,
				|	RoomRateFormulas.BracketsConstant,
				|	RoomRateFormulas.Constant,
				|	RoomRateFormulas.Multiplier
				|ORDER BY " + 
				?(pSortByPointInTime, "PointInTime DESC, ", "") + "
				|	SortCode,
				|	LineNumber";
				vQry.SetParameter("qOrders", vOrders);
				vQry.SetParameter("qServicePackages", vServicePackages);
				vQry.SetParameter("qCalendarDayTypesList", vDayTypesList);
				vQry.SetParameter("qHotel", vHotel);
				vQry.SetParameter("qRoomRate", pRoomRate);
				vQry.SetParameter("qPricesRoomRate", ?(ValueIsFilled(pRoomRate.BasedOnRoomRate), pRoomRate.BasedOnRoomRate, pRoomRate));
				vQry.SetParameter("qPriceTag", ?(pPriceTag = Undefined, Catalogs.PriceTags.EmptyRef(), pPriceTag));
				vQry.SetParameter("qPriceTagIsFilled", ?(pPriceTag = Undefined, False, True));
				vQry.SetParameter("qClientType", pClientType);
				vQry.SetParameter("qRoomType", pRoomType);
				vQry.SetParameter("qEmptyRoomTypeRef", Catalogs.RoomTypes.EmptyRef());
				vQry.SetParameter("qRoomTypeIsUndefined", ?(pRoomType = Undefined, True, False));
				vQry.SetParameter("qRoomClass", ?(ValueIsFilled(pRoomType) And Not pRoomType.IsFolder, pRoomType.RoomClass, Catalogs.RoomTypeClasses.EmptyRef()));
				vQry.SetParameter("qEmptyRoomClassRef", Catalogs.RoomTypeClasses.EmptyRef());
				vQry.SetParameter("qAccommodationType", pAccommodationType);
				vQry.SetParameter("qAccommodationTypeSortCode", ?(ValueIsFilled(pAccommodationType), pAccommodationType.SortCode, 999999999));
				vQry.SetParameter("qEmptyAccommodationTypeRef", Catalogs.AccommodationTypes.EmptyRef());
				vQry.SetParameter("qAccommodationTypeIsUndefined", ?(pAccommodationType = Undefined, True, False));
				vQry.SetParameter("qEmptySetRoomRatePricesRef", Documents.SetRoomRatePrices.EmptyRef());
				vQry.SetParameter("qDate", ?(ValueIsFilled(vPriceCalculationDate), vPriceCalculationDate, pDate));
				vQry.SetParameter("qCheckInDate", ?(ValueIsFilled(pCheckInDate), BegOfDay(pCheckInDate), pDate));
				vQry.SetParameter("qCheckOutDate", ?(ValueIsFilled(pCheckOutDate), BegOfDay(pCheckOutDate), BegOfDay(pDate)));
				vQry.SetParameter("qAccommodationPeriodIsSet", vAccommodationPeriodIsSet);
				vQry.SetParameter("qMinimizeOutput", pMinimizeOutput);
				vQry.SetParameter("qEmptyDate", '00010101');
				vQry.SetParameter("qEndOfTime", '39991231');
				vQry.SetParameter("qEmptyString", "");
				vQry.SetParameter("qEmptyService", Catalogs.Services.EmptyRef());
				vQry.SetParameter("qEmptyCalendarDayType", Catalogs.CalendarDayTypes.EmptyRef());
				vPrices = vQry.Execute().Unload();
			EndIf;
		Else
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	ServicePackages.ServicePackage AS ServicePackage,
			|	ServicePackages.Quantity AS Quantity,
			|	ServicePackages.DateFrom AS DateFrom,
			|	ServicePackages.DateTo AS DateTo,
			|	ServicePackages.PacketPriceIsIncludedInRoomRate AS PacketPriceIsIncludedInRoomRate,
			|	ServicePackages.IsExtraPackage AS IsExtraPackage,
			|	ServicePackages.IsMealBoardTerm AS IsMealBoardTerm,
			|	ServicePackages.IsPerPerson AS IsPerPerson,
			|	ServicePackages.UsageType AS UsageType,
			|	ServicePackages.DateValidFrom AS DateValidFrom,
			|	ServicePackages.DateValidTo AS DateValidTo
			|INTO ServicePackages
			|FROM
			|	&qServicePackages AS ServicePackages
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	ServicePackagePeriods.ServicePackage AS ServicePackage,
			|	MAX(ServicePackagePeriods.Period) AS ActivePeriod
			|INTO ServicePackagesActivePeriods
			|FROM
			|	InformationRegister.ServicePackageRecords.SliceLast(&qDate, ) AS ServicePackagePeriods
			|		INNER JOIN ServicePackages AS ServicePackages
			|		ON (ServicePackages.ServicePackage = ServicePackagePeriods.ServicePackage)
			|
			|GROUP BY
			|	ServicePackagePeriods.ServicePackage
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	Orders.CalendarDayType AS CalendarDayType,
			|	Orders.PriceTag AS PriceTag,
			|	Orders.SetRoomRatePrices AS SetRoomRatePrices
			|INTO Orders
			|FROM
			|	&qOrders AS Orders
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	RoomRatesSliceLast.SetRoomRateFormulas AS Recorder,
			|	RoomRatesSliceLast.RoomRate AS RoomRate
			|INTO ActiveSetRoomRateFormulas
			|FROM
			|	InformationRegister.RoomRates.SliceLast(
			|			&qDate,
			|			RoomRate = &qRoomRate
			|				AND Hotel = &qHotel
			|				AND IsFormula) AS RoomRatesSliceLast
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	RoomRateFormulas.RoomRate.BasedOnRoomRate AS BasedOnRoomRate,
			|	RoomRateFormulas.RoomRate.BasedOnPriceTag AS BasedOnPriceTag,
			|	RoomRateFormulas.RoomRate AS RoomRate,
			|	RoomRateFormulas.Hotel AS Hotel,
			|	RoomRateFormulas.IsFormula AS IsFormula,
			|	RoomRateFormulas.Service AS Service,
			|	RoomRateFormulas.RoomType AS RoomType,
			|	RoomRateFormulas.AccommodationType AS AccommodationType,
			|	RoomRateFormulas.ClientType AS ClientType,
			|	RoomRateFormulas.CalendarDayType AS CalendarDayType,
			|	RoomRateFormulas.Recorder AS Recorder,
			|	RoomRateFormulas.Period AS Period,
			|	RoomRateFormulas.BracketsConstant AS BracketsConstant,
			|	RoomRateFormulas.Constant AS Constant,
			|	RoomRateFormulas.Multiplier AS Multiplier,
			|	RoomRateFormulas.ReplaceWithService AS ReplaceWithService
			|INTO RoomRateFormulas
			|FROM
			|	InformationRegister.RoomRateFormulas AS RoomRateFormulas
			|		INNER JOIN ActiveSetRoomRateFormulas AS ActiveSetRoomRateFormulas
			|		ON RoomRateFormulas.Recorder = ActiveSetRoomRateFormulas.Recorder
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT DISTINCT
			|	ActivePriceTags.PriceTag AS PriceTag
			|INTO ActivePriceTags
			|FROM
			|	InformationRegister.RoomRatePrices AS ActivePriceTags
			|		INNER JOIN Orders AS Orders
			|		ON ActivePriceTags.SetRoomRatePrices = Orders.SetRoomRatePrices
			|			AND ActivePriceTags.CalendarDayType = Orders.CalendarDayType
			|			AND ActivePriceTags.PriceTag = Orders.PriceTag
			|WHERE
			|	ActivePriceTags.RoomRate = &qPricesRoomRate
			|	AND ActivePriceTags.ClientType = &qClientType
			|	AND (&qPriceTagIsFilled
			|				AND ActivePriceTags.PriceTag = &qPriceTag
			|			OR NOT &qPriceTagIsFilled)
			|	AND (ActivePriceTags.RoomType = &qRoomType
			|			OR ActivePriceTags.RoomType = &qEmptyRoomTypeRef
			|			OR &qRoomTypeIsUndefined)
			|	AND (ActivePriceTags.AccommodationType = &qAccommodationType
			|			OR ActivePriceTags.AccommodationType = &qEmptyAccommodationTypeRef
			|			OR &qAccommodationTypeIsUndefined)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	RoomRatePrices.Recorder AS Recorder,
			|	RoomRatePrices.LineNumber AS LineNumber,
			|	RoomRatePrices.Hotel AS Hotel,
			|	RoomRatePrices.RoomRate AS RoomRate,
			|	RoomRatePrices.CalendarDayType AS CalendarDayType,
			|	RoomRatePrices.PriceTag AS PriceTag,
			|	RoomRatePrices.ClientType AS ClientType,
			|	RoomRatePrices.RoomType AS RoomType,
			|	RoomRatePrices.RoomType.SortCode AS RoomTypeSortCode,
			|	RoomRatePrices.AccommodationType AS AccommodationType,
			|	RoomRatePrices.AccommodationType.SortCode AS AccommodationTypeSortCode,
			|	RoomRatePrices.SetRoomRatePrices AS SetRoomRatePrices,
			|	RoomRatePrices.SortCode AS SortCode,
			|	CASE
			|		WHEN RoomRateFormulas.ReplaceWithService.Code IS NULL
			|			THEN RoomRatePrices.Service
			|		ELSE RoomRateFormulas.ReplaceWithService
			|	END AS Service,
			|	CASE
			|		WHEN RoomRateFormulas.ReplaceWithService.Code IS NULL
			|			THEN RoomRatePrices.Service.Unit
			|		ELSE RoomRateFormulas.ReplaceWithService.Unit
			|	END AS Unit,
			|	RoomRatePrices.Service AS PricesService,
			|	RoomRatePrices.Currency AS Currency,
			|	RoomRatePrices.MinimumQuantity AS MinimumQuantity,
			|	RoomRatePrices.VATRate AS VATRate,
			|	RoomRatePrices.QuantityCalculationRule AS QuantityCalculationRule,
			|	RoomRatePrices.IsRoomRevenue AS IsRoomRevenue,
			|	RoomRatePrices.IsInPrice AS IsInPrice,
			|	RoomRatePrices.IsPricePerPerson AS IsPricePerPerson,
			|	RoomRatePrices.Service.RoomRevenueAmountsOnly AS RoomRevenueAmountsOnly,
			|	&qEmptyDate AS AccountingDate,
			|	0 AS AccountingDayNumber,
			|	&qEmptyString AS Remarks,
			|	NULL AS ServicePackage,
			|	&qEmptyDate AS ServicePackageDateValidFrom,
			|	&qEmptyDate AS ServicePackageDateValidTo,
			|	&qEmptyDate AS ServicePackagePeriodFrom,
			|	&qEmptyDate AS ServicePackagePeriodTo,
			|	RoomRatePrices.SetRoomRatePrices.PointInTime AS PointInTime,
			|	FALSE AS PacketPriceIsIncludedInRoomRate,
			|	UNDEFINED AS ServicePackageUsageType,
			|	&qEmptyDate AS ServicePackageDateFrom,
			|	&qEndOfTime AS ServicePackageDateTo,
			|	(RoomRatePrices.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0) AS Price,
			|	1 AS Quantity,
			|	CASE
			|		WHEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons4Reservation, 0) > 0
			|				AND RoomRatePrices.IsPricePerPerson
			|			THEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons4Reservation, 0)
			|		WHEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons, 0) > 0
			|			THEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons, 0)
			|		ELSE 1
			|	END AS NumberOfPersons,
			|	CASE
			|		WHEN RoomRatePrices.IsRoomRevenue
			|			THEN CASE
			|					WHEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons4Reservation, 0) > 0
			|							AND RoomRatePrices.IsPricePerPerson
			|						THEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons4Reservation, 0)
			|					WHEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons, 0) > 0
			|						THEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons, 0)
			|					ELSE 1
			|				END
			|		ELSE 0
			|	END AS NumberOfPersonsInRoom,
			|	CASE
			|		WHEN RoomRatePrices.IsRoomRevenue
			|			THEN ISNULL(RoomRatePrices.AccommodationType.NumberOfRooms, 0)
			|		ELSE 0
			|	END AS NumberOfRooms,
			|	CASE
			|		WHEN RoomRatePrices.IsRoomRevenue
			|			THEN ISNULL(RoomRatePrices.AccommodationType.NumberOfBeds, 0)
			|		ELSE 0
			|	END AS NumberOfBeds,
			|	CASE
			|		WHEN RoomRatePrices.IsRoomRevenue
			|			THEN ISNULL(RoomRatePrices.AccommodationType.NumberOfAdditionalBeds, 0)
			|		ELSE 0
			|	END AS NumberOfAdditionalBeds
			|FROM
			|	InformationRegister.RoomRatePrices AS RoomRatePrices
			|		INNER JOIN Orders AS Orders
			|		ON (RoomRatePrices.RoomRate = &qPricesRoomRate)
			|			AND (RoomRatePrices.ClientType = &qClientType)
			|			AND RoomRatePrices.SetRoomRatePrices = Orders.SetRoomRatePrices
			|			AND RoomRatePrices.PriceTag = Orders.PriceTag
			|			AND RoomRatePrices.CalendarDayType = Orders.CalendarDayType
			|		LEFT JOIN RoomRateFormulas AS RoomRateFormulas
			|		ON RoomRatePrices.RoomRate = RoomRateFormulas.BasedOnRoomRate
			|			AND RoomRatePrices.Hotel = RoomRateFormulas.Hotel
			|			AND (NOT RoomRateFormulas.IsFormula
			|				OR RoomRateFormulas.IsFormula
			|					AND RoomRatePrices.RoomType = RoomRateFormulas.RoomType
			|					AND RoomRatePrices.ClientType = RoomRateFormulas.ClientType
			|					AND RoomRatePrices.AccommodationType = RoomRateFormulas.AccommodationType
			|					AND (RoomRatePrices.CalendarDayType = RoomRateFormulas.CalendarDayType
			|						OR RoomRateFormulas.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef))
			|					AND (RoomRatePrices.Service = RoomRateFormulas.Service
			|						OR RoomRateFormulas.Service = VALUE(Catalog.Services.EmptyRef)))
			|			AND (RoomRateFormulas.BasedOnPriceTag = VALUE(Catalog.PriceTags.EmptyRef)
			|				OR RoomRatePrices.PriceTag = RoomRateFormulas.BasedOnPriceTag
			|					AND RoomRateFormulas.BasedOnPriceTag <> VALUE(Catalog.PriceTags.EmptyRef))
			|WHERE
			|	&qFilterByCalendarDayTypes
			|	AND (&qPriceTagIsFilled
			|				AND RoomRatePrices.PriceTag = &qPriceTag
			|			OR NOT &qPriceTagIsFilled)
			|	AND (RoomRatePrices.RoomType = &qRoomType
			|			OR RoomRatePrices.RoomType = &qEmptyRoomTypeRef
			|			OR &qRoomTypeIsUndefined)
			|	AND (RoomRatePrices.AccommodationType = &qAccommodationType
			|			OR RoomRatePrices.AccommodationType = &qEmptyAccommodationTypeRef
			|			OR &qAccommodationTypeIsUndefined)
			|	AND (NOT &qMinimizeOutput
			|			OR &qMinimizeOutput
			|				AND (RoomRatePrices.IsRoomRevenue
			|					OR NOT RoomRatePrices.IsRoomRevenue
			|						AND RoomRatePrices.IsInPrice
			|						AND RoomRatePrices.Price <> 0))
			|
			|UNION ALL
			|
			|SELECT
			|	&qEmptySetRoomRatePricesRef,
			|	PackageServicesForPriceTags.RowNumber,
			|	&qHotel,
			|	&qRoomRate,
			|	PackageServicesForPriceTags.CalendarDayType,
			|	ActivePriceTagsList.PriceTag,
			|	PackageServicesForPriceTags.ClientType,
			|	PackageServicesForPriceTags.RoomType,
			|	0,
			|	PackageServicesForPriceTags.AccommodationType,
			|	PackageServicesForPriceTags.AccommodationType.SortCode,
			|	&qEmptySetRoomRatePricesRef,
			|	999999999,
			|	CASE
			|		WHEN RoomRateFormulas.ReplaceWithService.Code IS NULL
			|			THEN PackageServicesForPriceTags.Service
			|		ELSE RoomRateFormulas.ReplaceWithService
			|	END,
			|	CASE
			|		WHEN RoomRateFormulas.ReplaceWithService.Code IS NULL
			|			THEN PackageServicesForPriceTags.Unit
			|		ELSE RoomRateFormulas.ReplaceWithService.Unit
			|	END,
			|	PackageServicesForPriceTags.Service,
			|	PackageServicesForPriceTags.Currency,
			|	0,
			|	PackageServicesForPriceTags.VATRate,
			|	PackageServicesForPriceTags.QuantityCalculationRule,
			|	CASE
			|		WHEN ISNULL(PackageServicesForPriceTags.ServicePackage.IsMealBoardTerm, FALSE)
			|			THEN FALSE
			|		ELSE ISNULL(PackageServicesForPriceTags.Service.IsRoomRevenue, FALSE)
			|	END,
			|	PackageServicesForPriceTags.IsInPrice,
			|	PackageServicesForPriceTags.IsServicePerPerson,
			|	ISNULL(PackageServicesForPriceTags.Service.RoomRevenueAmountsOnly, FALSE),
			|	PackageServicesForPriceTags.AccountingDate,
			|	PackageServicesForPriceTags.AccountingDayNumber,
			|	PackageServicesForPriceTags.Remarks,
			|	PackageServicesForPriceTags.ServicePackage,
			|	ISNULL(ServicePackages.DateValidFrom, &qEmptyDate),
			|	ISNULL(ServicePackages.DateValidTo, &qEmptyDate),
			|	ISNULL(PackageServicesForPriceTags.PeriodFrom, &qEmptyDate),
			|	ISNULL(PackageServicesForPriceTags.PeriodTo, &qEmptyDate),
			|	NULL,
			|	ISNULL(ServicePackages.PacketPriceIsIncludedInRoomRate, FALSE),
			|	ServicePackages.UsageType,
			|	ServicePackages.DateFrom,
			|	ServicePackages.DateTo,
			|	(PackageServicesForPriceTags.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0),
			|	PackageServicesForPriceTags.Quantity * ServicePackages.Quantity,
			|	CASE
			|		WHEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfPersons4Reservation, 0) > 0
			|				AND PackageServicesForPriceTags.IsServicePerPerson
			|			THEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfPersons4Reservation, 0)
			|		WHEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfPersons, 0) > 0
			|			THEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfPersons, 0)
			|		ELSE 1
			|	END,
			|	CASE
			|		WHEN ISNULL(PackageServicesForPriceTags.Service.IsRoomRevenue, FALSE)
			|				AND NOT ISNULL(ServicePackages.IsMealBoardTerm, FALSE)
			|			THEN CASE
			|					WHEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfPersons4Reservation, 0) > 0
			|							AND PackageServicesForPriceTags.IsServicePerPerson
			|						THEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfPersons4Reservation, 0)
			|					WHEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfPersons, 0) > 0
			|						THEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfPersons, 0)
			|					ELSE 1
			|				END
			|		ELSE 0
			|	END,
			|	CASE
			|		WHEN ISNULL(PackageServicesForPriceTags.Service.IsRoomRevenue, FALSE)
			|				AND NOT ISNULL(ServicePackages.IsMealBoardTerm, FALSE)
			|			THEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfRooms, 0)
			|		ELSE 0
			|	END,
			|	CASE
			|		WHEN ISNULL(PackageServicesForPriceTags.Service.IsRoomRevenue, FALSE)
			|				AND NOT ISNULL(ServicePackages.IsMealBoardTerm, FALSE)
			|			THEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfBeds, 0)
			|		ELSE 0
			|	END,
			|	CASE
			|		WHEN ISNULL(PackageServicesForPriceTags.Service.IsRoomRevenue, FALSE)
			|				AND NOT ISNULL(ServicePackages.IsMealBoardTerm, FALSE)
			|			THEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfAdditionalBeds, 0)
			|		ELSE 0
			|	END
			|FROM
			|	InformationRegister.ServicePackageRecords AS PackageServicesForPriceTags
			|		INNER JOIN ServicePackages AS ServicePackages
			|		ON (ServicePackages.ServicePackage = PackageServicesForPriceTags.ServicePackage)
			|		INNER JOIN ServicePackagesActivePeriods AS ServicePackagesActivePeriods
			|		ON PackageServicesForPriceTags.ServicePackage = ServicePackagesActivePeriods.ServicePackage
			|			AND PackageServicesForPriceTags.Period = ServicePackagesActivePeriods.ActivePeriod
			|		LEFT JOIN ActivePriceTags AS ActivePriceTagsList
			|		ON (TRUE)
			|		LEFT JOIN RoomRateFormulas AS RoomRateFormulas
			|		ON (RoomRateFormulas.RoomRate = &qRoomRate)
			|			AND (RoomRateFormulas.Hotel = &qHotel)
			|			AND (RoomRateFormulas.IsFormula)
			|			AND PackageServicesForPriceTags.Service = RoomRateFormulas.Service
			|			AND PackageServicesForPriceTags.RoomType = RoomRateFormulas.RoomType
			|			AND PackageServicesForPriceTags.ClientType = RoomRateFormulas.ClientType
			|			AND (PackageServicesForPriceTags.AccommodationType = RoomRateFormulas.AccommodationType
			|				OR PackageServicesForPriceTags.AccommodationType = VALUE(Catalog.AccommodationTypes.EmptyRef))
			|			AND (PackageServicesForPriceTags.CalendarDayType = RoomRateFormulas.CalendarDayType
			|				OR RoomRateFormulas.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef))
			|WHERE
			|	ServicePackages.DateValidFrom <= &qCheckInDate
			|	AND (ENDOFPERIOD(ServicePackages.DateValidTo, DAY) >= &qCheckInDate
			|			OR ServicePackages.DateValidTo = &qEmptyDate)
			|	AND PackageServicesForPriceTags.ClientType = &qClientType
			|	AND (PackageServicesForPriceTags.RoomType = &qRoomType
			|			OR PackageServicesForPriceTags.RoomType = &qEmptyRoomTypeRef
			|			OR &qRoomTypeIsUndefined)
			|	AND (PackageServicesForPriceTags.RoomClass = &qRoomClass
			|			OR PackageServicesForPriceTags.RoomClass = &qEmptyRoomClassRef
			|			OR &qRoomTypeIsUndefined)
			|	AND (PackageServicesForPriceTags.AccommodationType = &qAccommodationType
			|			OR PackageServicesForPriceTags.AccommodationType = &qEmptyAccommodationTypeRef
			|			OR &qAccommodationTypeIsUndefined)
			|	AND (NOT &qAccommodationPeriodIsSet
			|			OR &qAccommodationPeriodIsSet
			|				AND (PackageServicesForPriceTags.CalendarDayType IN (&qCalendarDayTypesList)
			|					OR PackageServicesForPriceTags.CalendarDayType = &qEmptyCalendarDayType))
			|	AND PackageServicesForPriceTags.Service IS NOT NULL 
			|	AND PackageServicesForPriceTags.Service <> &qEmptyService
			|	AND (NOT &qMinimizeOutput
			|			OR &qMinimizeOutput
			|				AND (PackageServicesForPriceTags.IsInPrice
			|					AND PackageServicesForPriceTags.Price <> 0))
			|ORDER BY " + 
			?(pSortByPointInTime, "PointInTime DESC, ", "") + "
			|	SortCode,
			|	LineNumber";
			vQry.SetParameter("qOrders", vOrders);
			vQry.SetParameter("qServicePackages", vServicePackages);
			vQry.SetParameter("qCalendarDayTypesList", vDayTypesList);
			vQry.SetParameter("qHotel", vHotel);
			vQry.SetParameter("qRoomRate", pRoomRate);
			vQry.SetParameter("qPricesRoomRate", ?(ValueIsFilled(pRoomRate.BasedOnRoomRate), pRoomRate.BasedOnRoomRate, pRoomRate));
			vQry.SetParameter("qPriceTagType", pRoomRate.PriceTagType);
			vQry.SetParameter("qPriceTag", ?(pPriceTag = Undefined, Catalogs.PriceTags.EmptyRef(), pPriceTag));
			vQry.SetParameter("qPriceTagIsFilled", ?(pPriceTag = Undefined, False, True));
			vQry.SetParameter("qClientType", pClientType);
			vQry.SetParameter("qRoomType", pRoomType);
			vQry.SetParameter("qEmptyRoomTypeRef", Catalogs.RoomTypes.EmptyRef());
			vQry.SetParameter("qRoomTypeIsUndefined", ?(pRoomType = Undefined, True, False));
			vQry.SetParameter("qRoomClass", ?(ValueIsFilled(pRoomType) And Not pRoomType.IsFolder, pRoomType.RoomClass, Catalogs.RoomTypeClasses.EmptyRef()));
			vQry.SetParameter("qEmptyRoomClassRef", Catalogs.RoomTypeClasses.EmptyRef());
			vQry.SetParameter("qAccommodationType", pAccommodationType);
			vQry.SetParameter("qEmptyAccommodationTypeRef", Catalogs.AccommodationTypes.EmptyRef());
			vQry.SetParameter("qAccommodationTypeIsUndefined", ?(pAccommodationType = Undefined, True, False));
			vQry.SetParameter("qEmptySetRoomRatePricesRef", Documents.SetRoomRatePrices.EmptyRef());
			vQry.SetParameter("qDate", ?(ValueIsFilled(vPriceCalculationDate), vPriceCalculationDate, pDate));
			vQry.SetParameter("qCheckInDate", ?(ValueIsFilled(pCheckInDate), BegOfDay(pCheckInDate), BegOfDay(pDate)));
			vQry.SetParameter("qCheckOutDate", ?(ValueIsFilled(pCheckOutDate), BegOfDay(pCheckOutDate), BegOfDay(pDate)));
			vQry.SetParameter("qAccommodationPeriodIsSet", vAccommodationPeriodIsSet);
			vQry.SetParameter("qMinimizeOutput", pMinimizeOutput);
			vQry.SetParameter("qEmptyDate", '00010101');
			vQry.SetParameter("qEndOfTime", '39991231');
			vQry.SetParameter("qEmptyString", "");
			vQry.SetParameter("qEmptyService", Catalogs.Services.EmptyRef());
			vQry.SetParameter("qEmptyCalendarDayType", Catalogs.CalendarDayTypes.EmptyRef());
			If vDayTypes.Count() > 0 Then
				For i = 0 To (vDayTypes.Count() - 1) Do
					vDayTypesRow = vDayTypes.Get(i);
					vQry.SetParameter("qCalendarDayType" + Format(i, "NFD=0; NZ=; NG="), vDayTypesRow.CalendarDayType);
				EndDo;
			EndIf;
			vQry.Text = StrReplace(vQry.Text, "&qFilterByCalendarDayTypes", vFilterByCalendarDayTypes);
			vPrices = vQry.Execute().Unload();
		EndIf;
	Else // Prices are in the calendar days
		If pAccommodationTemplate <> Undefined And vRateChargeDirection = Enums.RateChargeDirections.MergeToTheMainRoomGuest And vUseTemplate Then
			If ValueIsFilled(pAccommodationTemplate) And pAccommodationTemplate <> Catalogs.AccommodationTemplates.NoTemplate Then
				vQry = New Query;
				vQry.Text = 
				"SELECT
				|	Orders.CalendarDayType AS CalendarDayType,
				|	Orders.PriceTag AS PriceTag,
				|	Orders.SetRoomRatePrices AS SetRoomRatePrices
				|INTO Orders
				|FROM
				|	&qOrders AS Orders
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	AccommodationTypeFormulas.Ref.RoomRate AS RoomRate,
				|	AccommodationTypeFormulas.Ref.Hotel AS Hotel,
				|	AccommodationTypeFormulas.Ref AS SetRoomRatePrices,
				|	Orders.CalendarDayType AS CalendarDayType,
				|	Orders.PriceTag AS PriceTag,
				|	AccommodationTypeFormulas.ClientType AS ClientType,
				|	AccommodationTypeFormulas.Service AS Service,
				|	AccommodationTypeFormulas.RoomClass AS RoomClass,
				|	AccommodationTypeFormulas.RoomType AS RoomType,
				|	AccommodationTypeFormulas.AccommodationType AS AccommodationType,
				|	AccommodationTypeFormulas.Multiplier AS Multiplier,
				|	AccommodationTypeFormulas.BracketsConstant AS BracketsConstant,
				|	AccommodationTypeFormulas.Constant AS Constant,
				|	AccommodationTypeFormulas.LineNumber AS LineNumber,
				|	AccommodationTypeFormulas.LineNumber AS SortCode
				|INTO RateAccommodationTypeFormulas
				|FROM
				|	Document.SetRoomRatePrices.Formulas AS AccommodationTypeFormulas
				|		INNER JOIN Orders AS Orders
				|		ON AccommodationTypeFormulas.Ref = Orders.SetRoomRatePrices
				|
				|INDEX BY
				|	AccommodationTypeFormulas.Service,
				|	AccommodationTypeFormulas.RoomType,
				|	AccommodationTypeFormulas.RoomClass
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT DISTINCT
				|	FormulasForPriceTags.Ref.RoomRate AS RoomRate,
				|	FormulasForPriceTags.Ref.Hotel AS Hotel,
				|	FormulasForPriceTags.Ref AS SetRoomRatePrices,
				|	FormulasForPriceTags.CalendarDayType AS CalendarDayType,
				|	FormulasForPriceTags.PriceTag AS PriceTag,
				|	FormulasForPriceTags.ClientType AS ClientType,
				|	FormulasForPriceTags.Service AS Service,
				|	FormulasForPriceTags.RoomClass AS RoomClass,
				|	FormulasForPriceTags.RoomType AS RoomType,
				|	FormulasForPriceTags.AccommodationType AS AccommodationType,
				|	FormulasForPriceTags.Discount AS Discount,
				|	FormulasForPriceTags.Multiplier AS Multiplier,
				|	FormulasForPriceTags.BracketsConstant AS BracketsConstant,
				|	FormulasForPriceTags.Constant AS Constant,
				|	FormulasForPriceTags.LineNumber AS LineNumber,
				|	FormulasForPriceTags.LineNumber AS SortCode
				|INTO FormulasForPriceTags
				|FROM
				|	Document.SetRoomRatePrices.FormulasForDayTypesAndPricetags AS FormulasForPriceTags
				|		INNER JOIN Orders AS Orders
				|		ON FormulasForPriceTags.Ref = Orders.SetRoomRatePrices
				|			AND FormulasForPriceTags.PriceTag = Orders.PriceTag
				|			AND FormulasForPriceTags.CalendarDayType = Orders.CalendarDayType
				|
				|INDEX BY
				|	FormulasForPriceTags.ClientType,
				|	FormulasForPriceTags.PriceTag,
				|	FormulasForPriceTags.CalendarDayType,
				|	FormulasForPriceTags.Service,
				|	FormulasForPriceTags.RoomType,
				|	FormulasForPriceTags.RoomClass,
				|	FormulasForPriceTags.AccommodationType
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT TOP 3
				|	RateServices.Ref AS Service,
				|	RateServices.QuantityCalculationRule AS QuantityCalculationRule,
				|	RateServices.QuantityCalculationRule.QuantityCalculationRuleType AS QuantityCalculationRuleType,
				|	RateServices.IsRoomRevenue AS IsRoomRevenue,
				|	RateServices.IsInPrice AS IsInPrice,
				|	RateServices.ChargePerPerson AS ChargePerPerson,
				|	RateServices.ChargeToEachGuestSeparately AS ChargeToEachGuestSeparately,
				|	RateServices.Unit AS Unit,
				|	RateServices.RoomRevenueAmountsOnly AS RoomRevenueAmountsOnly
				|INTO RateServices
				|FROM
				|	Catalog.Services AS RateServices
				|WHERE
				|	(RateServices.Ref = &qAccommodationService
				|			OR RateServices.Ref = &qLateCheckOutService
				|			OR RateServices.Ref = &qEarlyCheckInService)
				|	AND NOT RateServices.IsFolder
				|
				|ORDER BY
				|	RateServices.SortCode,
				|	RateServices.Code
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	&qHotel AS Hotel,
				|	&qAccommodationTemplate AS AccommodationTemplate,
				|	HotelRoomTypes.Ref AS RoomType,
				|	HotelRoomTypes.RoomClass AS RoomClass,
				|	CASE
				|		WHEN NOT RoomRateOverrides.ToAccommodationType IS NULL
				|			THEN RoomRateOverrides.ToAccommodationType
				|		ELSE AccommodationTemplatesAccommodationTypes.AccommodationType
				|	END AS AccommodationType,
				|	AccommodationTemplatesAccommodationTypes.LineNumber AS LineNumber
				|INTO TemplateAccommodationTypes
				|FROM
				|	Catalog.RoomTypes AS HotelRoomTypes
				|		LEFT JOIN Catalog.AccommodationTemplates.AccommodationTypes AS AccommodationTemplatesAccommodationTypes
				|		ON (AccommodationTemplatesAccommodationTypes.Ref = &qAccommodationTemplate)
				|		LEFT JOIN InformationRegister.RoomRateOverrides AS RoomRateOverrides
				|		ON (RoomRateOverrides.RoomRate = &qRoomRate)
				|			AND (RoomRateOverrides.Hotel = &qHotel)
				|			AND (RoomRateOverrides.AccommodationTemplate = &qAccommodationTemplate)
				|			AND (HotelRoomTypes.Ref = RoomRateOverrides.RoomType
				|				OR RoomRateOverrides.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
				|			AND (AccommodationTemplatesAccommodationTypes.AccommodationType = RoomRateOverrides.AccommodationType)
				|			AND (AccommodationTemplatesAccommodationTypes.LineNumber = RoomRateOverrides.TemplateLineNumber)
				|WHERE
				|	HotelRoomTypes.Owner = &qHotel
				|	AND (HotelRoomTypes.Ref = &qRoomType
				|			OR &qRoomTypeIsUndefined)
				|	AND NOT HotelRoomTypes.DeletionMark
				|	AND NOT HotelRoomTypes.IsFolder
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	CalendarDaysByRoomTypes.RoomType AS RoomType,
				|	CalendarDaysByRoomTypes.AccountingDate AS AccountingDate,
				|	CalendarDaysByRoomTypes.CalendarDayType AS CalendarDayType,
				|	CalendarDaysByRoomTypes.PriceTag AS PriceTag,
				|	CalendarDaysByRoomTypes.RoomPrice AS RoomPrice,
				|	CalendarDaysByRoomTypes.RoomPriceCurrency AS RoomPriceCurrency
				|INTO CalendarDaysByRoomTypes
				|FROM
				|	InformationRegister.CalendarDaysByRoomTypes.SliceLast(
				|			&qDate,
				|				AccountingDate BETWEEN &qCheckInDate AND &qCheckOutDate 
				|				AND Calendar = &qCalendar
				|				AND Hotel = &qHotel
				|				AND (RoomType = &qRoomType OR &qRoomTypeIsUndefined)) AS CalendarDaysByRoomTypes
				|WHERE
				|	(CalendarDaysByRoomTypes.CalendarDayType <> VALUE(Catalog.CalendarDayTypes.EmptyRef)
				|			OR CalendarDaysByRoomTypes.PriceTag <> VALUE(Catalog.PriceTags.EmptyRef)
				|			OR CalendarDaysByRoomTypes.RoomPrice <> 0)
				|
				|INDEX BY
				|	CalendarDaysByRoomTypes.AccountingDate,
				|	CalendarDaysByRoomTypes.RoomType
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	RateServices.Service AS Service,
				|	RateServices.QuantityCalculationRule AS QuantityCalculationRule,
				|	RateServices.QuantityCalculationRuleType AS QuantityCalculationRuleType,
				|	RateServices.IsRoomRevenue AS IsRoomRevenue,
				|	RateServices.IsInPrice AS IsInPrice,
				|	RateServices.ChargePerPerson AS ChargePerPerson,
				|	RateServices.ChargeToEachGuestSeparately AS ChargeToEachGuestSeparately,
				|	RateServices.Unit AS Unit,
				|	RateServices.RoomRevenueAmountsOnly AS RoomRevenueAmountsOnly,
				|	RoomTypePricesByDates.RoomType AS RoomType,
				|	RoomTypePricesByDates.RoomType.RoomClass AS RoomTypeRoomClass,
				|	RoomTypePricesByDates.AccountingDate AS AccountingDate,
				|	RoomTypePricesByDates.CalendarDayType AS CalendarDayType,
				|	RoomTypePricesByDates.PriceTag AS PriceTag,
				|	RoomTypePricesByDates.RoomPrice AS Price,
				|	RoomTypePricesByDates.RoomPriceCurrency AS Currency
				|INTO RoomTypePricesByDates
				|FROM
				|	(SELECT DISTINCT
				|		DaysByRoomTypes.RoomType AS RoomType,
				|		DaysByRoomTypes.AccountingDate AS AccountingDate,
				|		DaysByRoomTypes.CalendarDayType AS CalendarDayType,
				|		DaysByRoomTypes.PriceTag AS PriceTag,
				|		DaysByRoomTypes.RoomPrice AS RoomPrice,
				|		DaysByRoomTypes.RoomPriceCurrency AS RoomPriceCurrency
				|	FROM
				|		(SELECT
				|			RoomTypes.Ref AS RoomType,
				|			CalendarDays.AccountingDate AS AccountingDate,
				|			CASE
				|				WHEN CalendarDaysByRoomTypes.CalendarDayType IS NULL
				|					THEN CalendarDays.CalendarDayType
				|				WHEN CalendarDaysByRoomTypes.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef)
				|					THEN CalendarDays.CalendarDayType
				|				ELSE CalendarDaysByRoomTypes.CalendarDayType
				|			END AS CalendarDayType,
				|			CASE
				|				WHEN CalendarDaysByRoomTypes.PriceTag IS NULL
				|					THEN CalendarDays.PriceTag
				|				WHEN CalendarDaysByRoomTypes.PriceTag = VALUE(Catalog.PriceTags.EmptyRef)
				|					THEN CalendarDays.PriceTag
				|				ELSE CalendarDaysByRoomTypes.PriceTag
				|			END AS PriceTag,
				|			CASE
				|				WHEN CalendarDaysByRoomTypes.RoomPrice IS NULL
				|					THEN CalendarDays.RoomPrice
				|				WHEN CalendarDaysByRoomTypes.RoomPrice = 0
				|					THEN CalendarDays.RoomPrice
				|				ELSE CalendarDaysByRoomTypes.RoomPrice
				|			END AS RoomPrice,
				|			CASE
				|				WHEN CalendarDaysByRoomTypes.RoomPriceCurrency IS NULL
				|					THEN CalendarDays.RoomPriceCurrency
				|				WHEN CalendarDaysByRoomTypes.RoomPriceCurrency = VALUE(Catalog.Currencies.EmptyRef)
				|					THEN CalendarDays.RoomPriceCurrency
				|				ELSE CalendarDaysByRoomTypes.RoomPriceCurrency
				|			END AS RoomPriceCurrency
				|		FROM
				|			InformationRegister.CalendarDays.SliceLast(
				|					&qDate,
				|					AccountingDate BETWEEN &qCheckInDate AND &qCheckOutDate
				|					AND Calendar = &qCalendar) AS CalendarDays
				|				LEFT JOIN Catalog.RoomTypes AS RoomTypes
				|				ON (RoomTypes.Owner = &qHotel)
				|					AND (NOT RoomTypes.IsFolder)
				|					AND (RoomTypes.Ref = &qRoomType
				|						OR &qRoomTypeIsUndefined)
				|				LEFT JOIN CalendarDaysByRoomTypes AS CalendarDaysByRoomTypes
				|				ON CalendarDays.AccountingDate = CalendarDaysByRoomTypes.AccountingDate
				|					AND (RoomTypes.Ref = CalendarDaysByRoomTypes.RoomType)) AS DaysByRoomTypes) AS RoomTypePricesByDates
				|		LEFT JOIN RateServices AS RateServices
				|		ON (TRUE)
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	ServicePrices.Service AS Service,
				|	ServicePrices.ClientType AS ClientType,
				|	ServicePrices.VATRate AS VATRate
				|INTO ServicePrices
				|FROM
				|	InformationRegister.ServicePrices.SliceLast(
				|			&qDate,
				|			(Service = &qAccommodationService
				|				OR Service = &qLateCheckOutService
				|				OR Service = &qEarlyCheckInService)
				|				AND Hotel = &qHotel) AS ServicePrices
				|
				|INDEX BY
				|	ServicePrices.Service,
				|	ServicePrices.ClientType
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	RawRoomRatePrices.AccountingDate AS AccountingDate,
				|	RawRoomRatePrices.RoomRate AS RoomRate,
				|	RawRoomRatePrices.CalendarDayType AS CalendarDayType,
				|	RawRoomRatePrices.PriceTag AS PriceTag,
				|	RawRoomRatePrices.ClientType AS ClientType,
				|	RawRoomRatePrices.RoomType AS RoomType,
				|	RawRoomRatePrices.RoomTypeRoomClass AS RoomTypeRoomClass,
				|	RawRoomRatePrices.AccommodationType AS AccommodationType,
				|	RawRoomRatePrices.SetRoomRatePrices AS SetRoomRatePrices,
				|	RawRoomRatePrices.SortCode AS SortCode,
				|	RawRoomRatePrices.LineNumber AS LineNumber,
				|	RawRoomRatePrices.Hotel AS Hotel,
				|	RawRoomRatePrices.Service AS Service,
				|	RawRoomRatePrices.Price AS Price,
				|	RawRoomRatePrices.Currency AS Currency,
				|	RawRoomRatePrices.QuantityCalculationRule AS QuantityCalculationRule,
				|	RawRoomRatePrices.QuantityCalculationRuleType AS QuantityCalculationRuleType,
				|	RawRoomRatePrices.IsRoomRevenue AS IsRoomRevenue,
				|	RawRoomRatePrices.IsInPrice AS IsInPrice,
				|	RawRoomRatePrices.ChargePerPerson AS IsPricePerPerson,
				|	RawRoomRatePrices.ChargeToEachGuestSeparately AS ChargeToEachGuestSeparately,
				|	RawRoomRatePrices.Unit AS Unit,
				|	RawRoomRatePrices.RoomRevenueAmountsOnly AS RoomRevenueAmountsOnly,
				|	0 AS MinimumQuantity,
				|	ISNULL(ServicePrices.VATRate, &qDefaultVATRate) AS VATRate
				|INTO RawRoomRatePrices
				|FROM
				|	(SELECT
				|		RoomTypePricesByDates1.AccountingDate AS AccountingDate,
				|		RateAccommodationTypeFormulas.RoomRate AS RoomRate,
				|		CASE
				|			WHEN RateAccommodationTypeFormulas.CalendarDayType <> VALUE(Catalog.CalendarDayTypes.EmptyRef)
				|				THEN RateAccommodationTypeFormulas.CalendarDayType
				|			ELSE RoomTypePricesByDates1.CalendarDayType
				|		END AS CalendarDayType,
				|		CASE
				|			WHEN RateAccommodationTypeFormulas.PriceTag <> VALUE(Catalog.PriceTags.EmptyRef)
				|				THEN RateAccommodationTypeFormulas.PriceTag
				|			ELSE RoomTypePricesByDates1.PriceTag
				|		END AS PriceTag,
				|		RateAccommodationTypeFormulas.ClientType AS ClientType,
				|		RoomTypePricesByDates1.RoomType AS RoomType,
				|		RoomTypePricesByDates1.RoomTypeRoomClass AS RoomTypeRoomClass,
				|		RateAccommodationTypeFormulas.AccommodationType AS AccommodationType,
				|		RateAccommodationTypeFormulas.SetRoomRatePrices AS SetRoomRatePrices,
				|		RateAccommodationTypeFormulas.SortCode AS SortCode,
				|		RateAccommodationTypeFormulas.LineNumber AS LineNumber,
				|		RateAccommodationTypeFormulas.Hotel AS Hotel,
				|		RoomTypePricesByDates1.Service AS Service,
				|		(RoomTypePricesByDates1.Price + ISNULL(RateAccommodationTypeFormulas.BracketsConstant, 0)) * ISNULL(RateAccommodationTypeFormulas.Multiplier, 0) + ISNULL(RateAccommodationTypeFormulas.Constant, 0) AS Price,
				|		RoomTypePricesByDates1.Currency AS Currency,
				|		RoomTypePricesByDates1.QuantityCalculationRule AS QuantityCalculationRule,
				|		RoomTypePricesByDates1.QuantityCalculationRuleType AS QuantityCalculationRuleType,
				|		RoomTypePricesByDates1.IsRoomRevenue AS IsRoomRevenue,
				|		RoomTypePricesByDates1.IsInPrice AS IsInPrice,
				|		RoomTypePricesByDates1.ChargePerPerson AS ChargePerPerson,
				|		RoomTypePricesByDates1.ChargeToEachGuestSeparately AS ChargeToEachGuestSeparately,
				|		RoomTypePricesByDates1.Unit AS Unit,
				|		RoomTypePricesByDates1.RoomRevenueAmountsOnly AS RoomRevenueAmountsOnly
				|	FROM
				|		RoomTypePricesByDates AS RoomTypePricesByDates1
				|			INNER JOIN RateAccommodationTypeFormulas AS RateAccommodationTypeFormulas
				|			ON RoomTypePricesByDates1.Service = RateAccommodationTypeFormulas.Service
				|				AND RoomTypePricesByDates1.RoomType = RateAccommodationTypeFormulas.RoomType
				|				AND (RateAccommodationTypeFormulas.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef))
				|				AND (RateAccommodationTypeFormulas.RoomClass = VALUE(Catalog.RoomTypeClasses.EmptyRef))
				|				AND (RateAccommodationTypeFormulas.Service <> VALUE(Catalog.Services.EmptyRef))
				|	
				|	UNION ALL
				|	
				|	SELECT
				|		RoomTypePricesByDates2.AccountingDate,
				|		RateAccommodationTypeFormulas.RoomRate,
				|		CASE
				|			WHEN RateAccommodationTypeFormulas.CalendarDayType <> VALUE(Catalog.CalendarDayTypes.EmptyRef)
				|				THEN RateAccommodationTypeFormulas.CalendarDayType
				|			ELSE RoomTypePricesByDates2.CalendarDayType
				|		END,
				|		CASE
				|			WHEN RateAccommodationTypeFormulas.PriceTag <> VALUE(Catalog.PriceTags.EmptyRef)
				|				THEN RateAccommodationTypeFormulas.PriceTag
				|			ELSE RoomTypePricesByDates2.PriceTag
				|		END,
				|		RateAccommodationTypeFormulas.ClientType,
				|		RoomTypePricesByDates2.RoomType,
				|		RoomTypePricesByDates2.RoomTypeRoomClass,
				|		RateAccommodationTypeFormulas.AccommodationType,
				|		RateAccommodationTypeFormulas.SetRoomRatePrices,
				|		RateAccommodationTypeFormulas.SortCode,
				|		RateAccommodationTypeFormulas.LineNumber,
				|		RateAccommodationTypeFormulas.Hotel,
				|		RoomTypePricesByDates2.Service,
				|		(RoomTypePricesByDates2.Price + ISNULL(RateAccommodationTypeFormulas.BracketsConstant, 0)) * ISNULL(RateAccommodationTypeFormulas.Multiplier, 0) + ISNULL(RateAccommodationTypeFormulas.Constant, 0),
				|		RoomTypePricesByDates2.Currency,
				|		RoomTypePricesByDates2.QuantityCalculationRule,
				|		RoomTypePricesByDates2.QuantityCalculationRuleType,
				|		RoomTypePricesByDates2.IsRoomRevenue,
				|		RoomTypePricesByDates2.IsInPrice,
				|		RoomTypePricesByDates2.ChargePerPerson,
				|		RoomTypePricesByDates2.ChargeToEachGuestSeparately,
				|		RoomTypePricesByDates2.Unit,
				|		RoomTypePricesByDates2.RoomRevenueAmountsOnly
				|	FROM
				|		RoomTypePricesByDates AS RoomTypePricesByDates2
				|			INNER JOIN RateAccommodationTypeFormulas AS RateAccommodationTypeFormulas
				|			ON RoomTypePricesByDates2.Service = RateAccommodationTypeFormulas.Service
				|				AND RoomTypePricesByDates2.RoomTypeRoomClass = RateAccommodationTypeFormulas.RoomClass
				|				AND (RateAccommodationTypeFormulas.RoomClass <> VALUE(Catalog.RoomTypeClasses.EmptyRef))
				|				AND (RateAccommodationTypeFormulas.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
				|				AND (RateAccommodationTypeFormulas.Service <> VALUE(Catalog.Services.EmptyRef))
				|	
				|	UNION ALL
				|	
				|	SELECT
				|		RoomTypePricesByDates3.AccountingDate,
				|		RateAccommodationTypeFormulas.RoomRate,
				|		CASE
				|			WHEN RateAccommodationTypeFormulas.CalendarDayType <> VALUE(Catalog.CalendarDayTypes.EmptyRef)
				|				THEN RateAccommodationTypeFormulas.CalendarDayType
				|			ELSE RoomTypePricesByDates3.CalendarDayType
				|		END,
				|		CASE
				|			WHEN RateAccommodationTypeFormulas.PriceTag <> VALUE(Catalog.PriceTags.EmptyRef)
				|				THEN RateAccommodationTypeFormulas.PriceTag
				|			ELSE RoomTypePricesByDates3.PriceTag
				|		END,
				|		RateAccommodationTypeFormulas.ClientType,
				|		RoomTypePricesByDates3.RoomType,
				|		RoomTypePricesByDates3.RoomTypeRoomClass,
				|		RateAccommodationTypeFormulas.AccommodationType,
				|		RateAccommodationTypeFormulas.SetRoomRatePrices,
				|		RateAccommodationTypeFormulas.SortCode,
				|		RateAccommodationTypeFormulas.LineNumber,
				|		RateAccommodationTypeFormulas.Hotel,
				|		RoomTypePricesByDates3.Service,
				|		(RoomTypePricesByDates3.Price + ISNULL(RateAccommodationTypeFormulas.BracketsConstant, 0)) * ISNULL(RateAccommodationTypeFormulas.Multiplier, 0) + ISNULL(RateAccommodationTypeFormulas.Constant, 0),
				|		RoomTypePricesByDates3.Currency,
				|		RoomTypePricesByDates3.QuantityCalculationRule,
				|		RoomTypePricesByDates3.QuantityCalculationRuleType,
				|		RoomTypePricesByDates3.IsRoomRevenue,
				|		RoomTypePricesByDates3.IsInPrice,
				|		RoomTypePricesByDates3.ChargePerPerson,
				|		RoomTypePricesByDates3.ChargeToEachGuestSeparately,
				|		RoomTypePricesByDates3.Unit,
				|		RoomTypePricesByDates3.RoomRevenueAmountsOnly
				|	FROM
				|		RoomTypePricesByDates AS RoomTypePricesByDates3
				|			INNER JOIN RateAccommodationTypeFormulas AS RateAccommodationTypeFormulas
				|			ON RoomTypePricesByDates3.Service = RateAccommodationTypeFormulas.Service
				|				AND (RateAccommodationTypeFormulas.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
				|				AND (RateAccommodationTypeFormulas.RoomClass = VALUE(Catalog.RoomTypeClasses.EmptyRef))
				|				AND (RateAccommodationTypeFormulas.Service <> VALUE(Catalog.Services.EmptyRef))
				|	
				|	UNION ALL
				|	
				|	SELECT
				|		RoomTypePricesByDates4.AccountingDate,
				|		RateAccommodationTypeFormulas.RoomRate,
				|		CASE
				|			WHEN RateAccommodationTypeFormulas.CalendarDayType <> VALUE(Catalog.CalendarDayTypes.EmptyRef)
				|				THEN RateAccommodationTypeFormulas.CalendarDayType
				|			ELSE RoomTypePricesByDates4.CalendarDayType
				|		END,
				|		CASE
				|			WHEN RateAccommodationTypeFormulas.PriceTag <> VALUE(Catalog.PriceTags.EmptyRef)
				|				THEN RateAccommodationTypeFormulas.PriceTag
				|			ELSE RoomTypePricesByDates4.PriceTag
				|		END,
				|		RateAccommodationTypeFormulas.ClientType,
				|		RoomTypePricesByDates4.RoomType,
				|		RoomTypePricesByDates4.RoomTypeRoomClass,
				|		RateAccommodationTypeFormulas.AccommodationType,
				|		RateAccommodationTypeFormulas.SetRoomRatePrices,
				|		RateAccommodationTypeFormulas.SortCode,
				|		RateAccommodationTypeFormulas.LineNumber,
				|		RateAccommodationTypeFormulas.Hotel,
				|		RoomTypePricesByDates4.Service,
				|		(RoomTypePricesByDates4.Price + ISNULL(RateAccommodationTypeFormulas.BracketsConstant, 0)) * ISNULL(RateAccommodationTypeFormulas.Multiplier, 0) + ISNULL(RateAccommodationTypeFormulas.Constant, 0),
				|		RoomTypePricesByDates4.Currency,
				|		RoomTypePricesByDates4.QuantityCalculationRule,
				|		RoomTypePricesByDates4.QuantityCalculationRuleType,
				|		RoomTypePricesByDates4.IsRoomRevenue,
				|		RoomTypePricesByDates4.IsInPrice,
				|		RoomTypePricesByDates4.ChargePerPerson,
				|		RoomTypePricesByDates4.ChargeToEachGuestSeparately,
				|		RoomTypePricesByDates4.Unit,
				|		RoomTypePricesByDates4.RoomRevenueAmountsOnly
				|	FROM
				|		RoomTypePricesByDates AS RoomTypePricesByDates4
				|			INNER JOIN RateAccommodationTypeFormulas AS RateAccommodationTypeFormulas
				|			ON RoomTypePricesByDates4.RoomType = RateAccommodationTypeFormulas.RoomType
				|				AND (RateAccommodationTypeFormulas.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef))
				|				AND (RateAccommodationTypeFormulas.RoomClass = VALUE(Catalog.RoomTypeClasses.EmptyRef))
				|				AND (RateAccommodationTypeFormulas.Service = VALUE(Catalog.Services.EmptyRef))
				|	
				|	UNION ALL
				|	
				|	SELECT
				|		RoomTypePricesByDates5.AccountingDate,
				|		RateAccommodationTypeFormulas.RoomRate,
				|		CASE
				|			WHEN RateAccommodationTypeFormulas.CalendarDayType <> VALUE(Catalog.CalendarDayTypes.EmptyRef)
				|				THEN RateAccommodationTypeFormulas.CalendarDayType
				|			ELSE RoomTypePricesByDates5.CalendarDayType
				|		END,
				|		CASE
				|			WHEN RateAccommodationTypeFormulas.PriceTag <> VALUE(Catalog.PriceTags.EmptyRef)
				|				THEN RateAccommodationTypeFormulas.PriceTag
				|			ELSE RoomTypePricesByDates5.PriceTag
				|		END,
				|		RateAccommodationTypeFormulas.ClientType,
				|		RoomTypePricesByDates5.RoomType,
				|		RoomTypePricesByDates5.RoomTypeRoomClass,
				|		RateAccommodationTypeFormulas.AccommodationType,
				|		RateAccommodationTypeFormulas.SetRoomRatePrices,
				|		RateAccommodationTypeFormulas.SortCode,
				|		RateAccommodationTypeFormulas.LineNumber,
				|		RateAccommodationTypeFormulas.Hotel,
				|		RoomTypePricesByDates5.Service,
				|		(RoomTypePricesByDates5.Price + ISNULL(RateAccommodationTypeFormulas.BracketsConstant, 0)) * ISNULL(RateAccommodationTypeFormulas.Multiplier, 0) + ISNULL(RateAccommodationTypeFormulas.Constant, 0),
				|		RoomTypePricesByDates5.Currency,
				|		RoomTypePricesByDates5.QuantityCalculationRule,
				|		RoomTypePricesByDates5.QuantityCalculationRuleType,
				|		RoomTypePricesByDates5.IsRoomRevenue,
				|		RoomTypePricesByDates5.IsInPrice,
				|		RoomTypePricesByDates5.ChargePerPerson,
				|		RoomTypePricesByDates5.ChargeToEachGuestSeparately,
				|		RoomTypePricesByDates5.Unit,
				|		RoomTypePricesByDates5.RoomRevenueAmountsOnly
				|	FROM
				|		RoomTypePricesByDates AS RoomTypePricesByDates5
				|			INNER JOIN RateAccommodationTypeFormulas AS RateAccommodationTypeFormulas
				|			ON RoomTypePricesByDates5.RoomTypeRoomClass = RateAccommodationTypeFormulas.RoomClass
				|				AND (RateAccommodationTypeFormulas.RoomClass <> VALUE(Catalog.RoomTypeClasses.EmptyRef))
				|				AND (RateAccommodationTypeFormulas.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
				|				AND (RateAccommodationTypeFormulas.Service = VALUE(Catalog.Services.EmptyRef))
				|	
				|	UNION ALL
				|	
				|	SELECT
				|		RoomTypePricesByDates6.AccountingDate,
				|		RateAccommodationTypeFormulas.RoomRate,
				|		CASE
				|			WHEN RateAccommodationTypeFormulas.CalendarDayType <> VALUE(Catalog.CalendarDayTypes.EmptyRef)
				|				THEN RateAccommodationTypeFormulas.CalendarDayType
				|			ELSE RoomTypePricesByDates6.CalendarDayType
				|		END,
				|		CASE
				|			WHEN RateAccommodationTypeFormulas.PriceTag <> VALUE(Catalog.PriceTags.EmptyRef)
				|				THEN RateAccommodationTypeFormulas.PriceTag
				|			ELSE RoomTypePricesByDates6.PriceTag
				|		END,
				|		RateAccommodationTypeFormulas.ClientType,
				|		RoomTypePricesByDates6.RoomType,
				|		RoomTypePricesByDates6.RoomTypeRoomClass,
				|		RateAccommodationTypeFormulas.AccommodationType,
				|		RateAccommodationTypeFormulas.SetRoomRatePrices,
				|		RateAccommodationTypeFormulas.SortCode,
				|		RateAccommodationTypeFormulas.LineNumber,
				|		RateAccommodationTypeFormulas.Hotel,
				|		RoomTypePricesByDates6.Service,
				|		(RoomTypePricesByDates6.Price + ISNULL(RateAccommodationTypeFormulas.BracketsConstant, 0)) * ISNULL(RateAccommodationTypeFormulas.Multiplier, 0) + ISNULL(RateAccommodationTypeFormulas.Constant, 0),
				|		RoomTypePricesByDates6.Currency,
				|		RoomTypePricesByDates6.QuantityCalculationRule,
				|		RoomTypePricesByDates6.QuantityCalculationRuleType,
				|		RoomTypePricesByDates6.IsRoomRevenue,
				|		RoomTypePricesByDates6.IsInPrice,
				|		RoomTypePricesByDates6.ChargePerPerson,
				|		RoomTypePricesByDates6.ChargeToEachGuestSeparately,
				|		RoomTypePricesByDates6.Unit,
				|		RoomTypePricesByDates6.RoomRevenueAmountsOnly
				|	FROM
				|		RoomTypePricesByDates AS RoomTypePricesByDates6
				|			INNER JOIN RateAccommodationTypeFormulas AS RateAccommodationTypeFormulas
				|			ON (RateAccommodationTypeFormulas.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
				|				AND (RateAccommodationTypeFormulas.RoomClass = VALUE(Catalog.RoomTypeClasses.EmptyRef))
				|				AND (RateAccommodationTypeFormulas.Service = VALUE(Catalog.Services.EmptyRef))) AS RawRoomRatePrices
				|		LEFT JOIN ServicePrices AS ServicePrices
				|		ON RawRoomRatePrices.Service = ServicePrices.Service
				|			AND RawRoomRatePrices.ClientType = ServicePrices.ClientType
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|DROP RoomTypePricesByDates
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	RoomRatePricesJoinedWithFormulas.AccountingDate AS AccountingDate,
				|	RoomRatePricesJoinedWithFormulas.RoomRate AS RoomRate,
				|	RoomRatePricesJoinedWithFormulas.CalendarDayType AS CalendarDayType,
				|	RoomRatePricesJoinedWithFormulas.PriceTag AS PriceTag,
				|	RoomRatePricesJoinedWithFormulas.ClientType AS ClientType,
				|	RoomRatePricesJoinedWithFormulas.RoomType AS RoomType,
				|	RoomRatePricesJoinedWithFormulas.RoomTypeRoomClass AS RoomTypeRoomClass,
				|	RoomRatePricesJoinedWithFormulas.AccommodationType AS AccommodationType,
				|	RoomRatePricesJoinedWithFormulas.SetRoomRatePrices AS SetRoomRatePrices,
				|	RoomRatePricesJoinedWithFormulas.SortCode AS SortCode,
				|	RoomRatePricesJoinedWithFormulas.LineNumber AS LineNumber,
				|	RoomRatePricesJoinedWithFormulas.Hotel AS Hotel,
				|	RoomRatePricesJoinedWithFormulas.Service AS Service,
				|	RoomRatePricesJoinedWithFormulas.Price AS Price,
				|	RoomRatePricesJoinedWithFormulas.Currency AS Currency,
				|	RoomRatePricesJoinedWithFormulas.MinimumQuantity AS MinimumQuantity,
				|	RoomRatePricesJoinedWithFormulas.VATRate AS VATRate,
				|	RoomRatePricesJoinedWithFormulas.QuantityCalculationRule AS QuantityCalculationRule,
				|	RoomRatePricesJoinedWithFormulas.QuantityCalculationRuleType AS QuantityCalculationRuleType,
				|	RoomRatePricesJoinedWithFormulas.IsRoomRevenue AS IsRoomRevenue,
				|	RoomRatePricesJoinedWithFormulas.IsInPrice AS IsInPrice,
				|	RoomRatePricesJoinedWithFormulas.IsPricePerPerson AS IsPricePerPerson,
				|	RoomRatePricesJoinedWithFormulas.ChargeToEachGuestSeparately AS ChargeToEachGuestSeparately,
				|	RoomRatePricesJoinedWithFormulas.Unit AS Unit,
				|	RoomRatePricesJoinedWithFormulas.RoomRevenueAmountsOnly AS RoomRevenueAmountsOnly
				|INTO RoomRatePricesJoinedWithFormulas
				|FROM
				|	(SELECT
				|		RoomRatePrices1.AccountingDate AS AccountingDate,
				|		RoomRatePrices1.RoomRate AS RoomRate,
				|		RoomRatePrices1.CalendarDayType AS CalendarDayType,
				|		RoomRatePrices1.PriceTag AS PriceTag,
				|		RoomRatePrices1.ClientType AS ClientType,
				|		RoomRatePrices1.RoomType AS RoomType,
				|		RoomRatePrices1.RoomTypeRoomClass AS RoomTypeRoomClass,
				|		RoomRatePrices1.AccommodationType AS AccommodationType,
				|		RoomRatePrices1.SetRoomRatePrices AS SetRoomRatePrices,
				|		RoomRatePrices1.SortCode AS SortCode,
				|		RoomRatePrices1.LineNumber AS LineNumber,
				|		RoomRatePrices1.Hotel AS Hotel,
				|		RoomRatePrices1.Service AS Service,
				|		CASE
				|			WHEN ISNULL(FormulasForPriceTags.Discount, 0) <> 0
				|				THEN RoomRatePrices1.Price - RoomRatePrices1.Price * ISNULL(FormulasForPriceTags.Discount, 0) / 100
				|			ELSE (RoomRatePrices1.Price + ISNULL(FormulasForPriceTags.BracketsConstant, 0)) * ISNULL(FormulasForPriceTags.Multiplier, 1) + ISNULL(FormulasForPriceTags.Constant, 0)
				|		END AS Price,
				|		RoomRatePrices1.Currency AS Currency,
				|		RoomRatePrices1.MinimumQuantity AS MinimumQuantity,
				|		RoomRatePrices1.VATRate AS VATRate,
				|		RoomRatePrices1.QuantityCalculationRule AS QuantityCalculationRule,
				|		RoomRatePrices1.QuantityCalculationRuleType AS QuantityCalculationRuleType,
				|		RoomRatePrices1.IsRoomRevenue AS IsRoomRevenue,
				|		RoomRatePrices1.IsInPrice AS IsInPrice,
				|		RoomRatePrices1.IsPricePerPerson AS IsPricePerPerson,
				|		RoomRatePrices1.ChargeToEachGuestSeparately AS ChargeToEachGuestSeparately,
				|		RoomRatePrices1.Unit AS Unit,
				|		RoomRatePrices1.RoomRevenueAmountsOnly AS RoomRevenueAmountsOnly
				|	FROM
				|		RawRoomRatePrices AS RoomRatePrices1
				|			INNER JOIN FormulasForPriceTags AS FormulasForPriceTags
				|			ON RoomRatePrices1.ClientType = FormulasForPriceTags.ClientType
				|				AND RoomRatePrices1.PriceTag = FormulasForPriceTags.PriceTag
				|				AND RoomRatePrices1.CalendarDayType = FormulasForPriceTags.CalendarDayType
				|				AND RoomRatePrices1.Service = FormulasForPriceTags.Service
				|				AND RoomRatePrices1.RoomType = FormulasForPriceTags.RoomType
				|				AND RoomRatePrices1.AccommodationType = FormulasForPriceTags.AccommodationType
				|				AND (FormulasForPriceTags.Service <> VALUE(Catalog.Services.EmptyRef))
				|				AND (FormulasForPriceTags.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef))
				|				AND (FormulasForPriceTags.RoomClass = VALUE(Catalog.RoomTypeClasses.EmptyRef))
				|				AND (FormulasForPriceTags.AccommodationType <> VALUE(Catalog.AccommodationTypes.EmptyRef))
				|	
				|	UNION ALL
				|	
				|	SELECT
				|		RoomRatePrices2.AccountingDate,
				|		RoomRatePrices2.RoomRate,
				|		RoomRatePrices2.CalendarDayType,
				|		RoomRatePrices2.PriceTag,
				|		RoomRatePrices2.ClientType,
				|		RoomRatePrices2.RoomType,
				|		RoomRatePrices2.RoomTypeRoomClass,
				|		RoomRatePrices2.AccommodationType,
				|		RoomRatePrices2.SetRoomRatePrices,
				|		RoomRatePrices2.SortCode,
				|		RoomRatePrices2.LineNumber,
				|		RoomRatePrices2.Hotel,
				|		RoomRatePrices2.Service,
				|		CASE
				|			WHEN ISNULL(FormulasForPriceTags.Discount, 0) <> 0
				|				THEN RoomRatePrices2.Price - RoomRatePrices2.Price * ISNULL(FormulasForPriceTags.Discount, 0) / 100
				|			ELSE (RoomRatePrices2.Price + ISNULL(FormulasForPriceTags.BracketsConstant, 0)) * ISNULL(FormulasForPriceTags.Multiplier, 1) + ISNULL(FormulasForPriceTags.Constant, 0)
				|		END,
				|		RoomRatePrices2.Currency,
				|		RoomRatePrices2.MinimumQuantity,
				|		RoomRatePrices2.VATRate,
				|		RoomRatePrices2.QuantityCalculationRule,
				|		RoomRatePrices2.QuantityCalculationRuleType,
				|		RoomRatePrices2.IsRoomRevenue,
				|		RoomRatePrices2.IsInPrice,
				|		RoomRatePrices2.IsPricePerPerson,
				|		RoomRatePrices2.ChargeToEachGuestSeparately,
				|		RoomRatePrices2.Unit,
				|		RoomRatePrices2.RoomRevenueAmountsOnly
				|	FROM
				|		RawRoomRatePrices AS RoomRatePrices2
				|			INNER JOIN FormulasForPriceTags AS FormulasForPriceTags
				|			ON RoomRatePrices2.ClientType = FormulasForPriceTags.ClientType
				|				AND RoomRatePrices2.PriceTag = FormulasForPriceTags.PriceTag
				|				AND RoomRatePrices2.CalendarDayType = FormulasForPriceTags.CalendarDayType
				|				AND RoomRatePrices2.Service = FormulasForPriceTags.Service
				|				AND RoomRatePrices2.RoomTypeRoomClass = FormulasForPriceTags.RoomClass
				|				AND RoomRatePrices2.AccommodationType = FormulasForPriceTags.AccommodationType
				|				AND (FormulasForPriceTags.Service <> VALUE(Catalog.Services.EmptyRef))
				|				AND (FormulasForPriceTags.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
				|				AND (FormulasForPriceTags.RoomClass <> VALUE(Catalog.RoomTypeClasses.EmptyRef))
				|				AND (FormulasForPriceTags.AccommodationType <> VALUE(Catalog.AccommodationTypes.EmptyRef))
				|	
				|	UNION ALL
				|	
				|	SELECT
				|		RoomRatePrices3.AccountingDate,
				|		RoomRatePrices3.RoomRate,
				|		RoomRatePrices3.CalendarDayType,
				|		RoomRatePrices3.PriceTag,
				|		RoomRatePrices3.ClientType,
				|		RoomRatePrices3.RoomType,
				|		RoomRatePrices3.RoomTypeRoomClass,
				|		RoomRatePrices3.AccommodationType,
				|		RoomRatePrices3.SetRoomRatePrices,
				|		RoomRatePrices3.SortCode,
				|		RoomRatePrices3.LineNumber,
				|		RoomRatePrices3.Hotel,
				|		RoomRatePrices3.Service,
				|		CASE
				|			WHEN ISNULL(FormulasForPriceTags.Discount, 0) <> 0
				|				THEN RoomRatePrices3.Price - RoomRatePrices3.Price * ISNULL(FormulasForPriceTags.Discount, 0) / 100
				|			ELSE (RoomRatePrices3.Price + ISNULL(FormulasForPriceTags.BracketsConstant, 0)) * ISNULL(FormulasForPriceTags.Multiplier, 1) + ISNULL(FormulasForPriceTags.Constant, 0)
				|		END,
				|		RoomRatePrices3.Currency,
				|		RoomRatePrices3.MinimumQuantity,
				|		RoomRatePrices3.VATRate,
				|		RoomRatePrices3.QuantityCalculationRule,
				|		RoomRatePrices3.QuantityCalculationRuleType,
				|		RoomRatePrices3.IsRoomRevenue,
				|		RoomRatePrices3.IsInPrice,
				|		RoomRatePrices3.IsPricePerPerson,
				|		RoomRatePrices3.ChargeToEachGuestSeparately,
				|		RoomRatePrices3.Unit,
				|		RoomRatePrices3.RoomRevenueAmountsOnly
				|	FROM
				|		RawRoomRatePrices AS RoomRatePrices3
				|			INNER JOIN FormulasForPriceTags AS FormulasForPriceTags
				|			ON RoomRatePrices3.ClientType = FormulasForPriceTags.ClientType
				|				AND RoomRatePrices3.PriceTag = FormulasForPriceTags.PriceTag
				|				AND RoomRatePrices3.CalendarDayType = FormulasForPriceTags.CalendarDayType
				|				AND RoomRatePrices3.Service = FormulasForPriceTags.Service
				|				AND RoomRatePrices3.AccommodationType = FormulasForPriceTags.AccommodationType
				|				AND (FormulasForPriceTags.Service <> VALUE(Catalog.Services.EmptyRef))
				|				AND (FormulasForPriceTags.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
				|				AND (FormulasForPriceTags.RoomClass = VALUE(Catalog.RoomTypeClasses.EmptyRef))
				|				AND (FormulasForPriceTags.AccommodationType <> VALUE(Catalog.AccommodationTypes.EmptyRef))
				|	
				|	UNION ALL
				|	
				|	SELECT
				|		RoomRatePrices4.AccountingDate,
				|		RoomRatePrices4.RoomRate,
				|		RoomRatePrices4.CalendarDayType,
				|		RoomRatePrices4.PriceTag,
				|		RoomRatePrices4.ClientType,
				|		RoomRatePrices4.RoomType,
				|		RoomRatePrices4.RoomTypeRoomClass,
				|		RoomRatePrices4.AccommodationType,
				|		RoomRatePrices4.SetRoomRatePrices,
				|		RoomRatePrices4.SortCode,
				|		RoomRatePrices4.LineNumber,
				|		RoomRatePrices4.Hotel,
				|		RoomRatePrices4.Service,
				|		CASE
				|			WHEN ISNULL(FormulasForPriceTags.Discount, 0) <> 0
				|				THEN RoomRatePrices4.Price - RoomRatePrices4.Price * ISNULL(FormulasForPriceTags.Discount, 0) / 100
				|			ELSE (RoomRatePrices4.Price + ISNULL(FormulasForPriceTags.BracketsConstant, 0)) * ISNULL(FormulasForPriceTags.Multiplier, 1) + ISNULL(FormulasForPriceTags.Constant, 0)
				|		END,
				|		RoomRatePrices4.Currency,
				|		RoomRatePrices4.MinimumQuantity,
				|		RoomRatePrices4.VATRate,
				|		RoomRatePrices4.QuantityCalculationRule,
				|		RoomRatePrices4.QuantityCalculationRuleType,
				|		RoomRatePrices4.IsRoomRevenue,
				|		RoomRatePrices4.IsInPrice,
				|		RoomRatePrices4.IsPricePerPerson,
				|		RoomRatePrices4.ChargeToEachGuestSeparately,
				|		RoomRatePrices4.Unit,
				|		RoomRatePrices4.RoomRevenueAmountsOnly
				|	FROM
				|		RawRoomRatePrices AS RoomRatePrices4
				|			INNER JOIN FormulasForPriceTags AS FormulasForPriceTags
				|			ON RoomRatePrices4.ClientType = FormulasForPriceTags.ClientType
				|				AND RoomRatePrices4.PriceTag = FormulasForPriceTags.PriceTag
				|				AND RoomRatePrices4.CalendarDayType = FormulasForPriceTags.CalendarDayType
				|				AND RoomRatePrices4.RoomType = FormulasForPriceTags.RoomType
				|				AND RoomRatePrices4.AccommodationType = FormulasForPriceTags.AccommodationType
				|				AND (FormulasForPriceTags.Service = VALUE(Catalog.Services.EmptyRef))
				|				AND (FormulasForPriceTags.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef))
				|				AND (FormulasForPriceTags.RoomClass = VALUE(Catalog.RoomTypeClasses.EmptyRef))
				|				AND (FormulasForPriceTags.AccommodationType <> VALUE(Catalog.AccommodationTypes.EmptyRef))
				|	
				|	UNION ALL
				|	
				|	SELECT
				|		RoomRatePrices5.AccountingDate,
				|		RoomRatePrices5.RoomRate,
				|		RoomRatePrices5.CalendarDayType,
				|		RoomRatePrices5.PriceTag,
				|		RoomRatePrices5.ClientType,
				|		RoomRatePrices5.RoomType,
				|		RoomRatePrices5.RoomTypeRoomClass,
				|		RoomRatePrices5.AccommodationType,
				|		RoomRatePrices5.SetRoomRatePrices,
				|		RoomRatePrices5.SortCode,
				|		RoomRatePrices5.LineNumber,
				|		RoomRatePrices5.Hotel,
				|		RoomRatePrices5.Service,
				|		CASE
				|			WHEN ISNULL(FormulasForPriceTags.Discount, 0) <> 0
				|				THEN RoomRatePrices5.Price - RoomRatePrices5.Price * ISNULL(FormulasForPriceTags.Discount, 0) / 100
				|			ELSE (RoomRatePrices5.Price + ISNULL(FormulasForPriceTags.BracketsConstant, 0)) * ISNULL(FormulasForPriceTags.Multiplier, 1) + ISNULL(FormulasForPriceTags.Constant, 0)
				|		END,
				|		RoomRatePrices5.Currency,
				|		RoomRatePrices5.MinimumQuantity,
				|		RoomRatePrices5.VATRate,
				|		RoomRatePrices5.QuantityCalculationRule,
				|		RoomRatePrices5.QuantityCalculationRuleType,
				|		RoomRatePrices5.IsRoomRevenue,
				|		RoomRatePrices5.IsInPrice,
				|		RoomRatePrices5.IsPricePerPerson,
				|		RoomRatePrices5.ChargeToEachGuestSeparately,
				|		RoomRatePrices5.Unit,
				|		RoomRatePrices5.RoomRevenueAmountsOnly
				|	FROM
				|		RawRoomRatePrices AS RoomRatePrices5
				|			INNER JOIN FormulasForPriceTags AS FormulasForPriceTags
				|			ON RoomRatePrices5.ClientType = FormulasForPriceTags.ClientType
				|				AND RoomRatePrices5.PriceTag = FormulasForPriceTags.PriceTag
				|				AND RoomRatePrices5.CalendarDayType = FormulasForPriceTags.CalendarDayType
				|				AND RoomRatePrices5.RoomTypeRoomClass = FormulasForPriceTags.RoomClass
				|				AND RoomRatePrices5.AccommodationType = FormulasForPriceTags.AccommodationType
				|				AND (FormulasForPriceTags.Service = VALUE(Catalog.Services.EmptyRef))
				|				AND (FormulasForPriceTags.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
				|				AND (FormulasForPriceTags.RoomClass <> VALUE(Catalog.RoomTypeClasses.EmptyRef))
				|				AND (FormulasForPriceTags.AccommodationType <> VALUE(Catalog.AccommodationTypes.EmptyRef))
				|	
				|	UNION ALL
				|	
				|	SELECT
				|		RoomRatePrices6.AccountingDate,
				|		RoomRatePrices6.RoomRate,
				|		RoomRatePrices6.CalendarDayType,
				|		RoomRatePrices6.PriceTag,
				|		RoomRatePrices6.ClientType,
				|		RoomRatePrices6.RoomType,
				|		RoomRatePrices6.RoomTypeRoomClass,
				|		RoomRatePrices6.AccommodationType,
				|		RoomRatePrices6.SetRoomRatePrices,
				|		RoomRatePrices6.SortCode,
				|		RoomRatePrices6.LineNumber,
				|		RoomRatePrices6.Hotel,
				|		RoomRatePrices6.Service,
				|		CASE
				|			WHEN ISNULL(FormulasForPriceTags.Discount, 0) <> 0
				|				THEN RoomRatePrices6.Price - RoomRatePrices6.Price * ISNULL(FormulasForPriceTags.Discount, 0) / 100
				|			ELSE (RoomRatePrices6.Price + ISNULL(FormulasForPriceTags.BracketsConstant, 0)) * ISNULL(FormulasForPriceTags.Multiplier, 1) + ISNULL(FormulasForPriceTags.Constant, 0)
				|		END,
				|		RoomRatePrices6.Currency,
				|		RoomRatePrices6.MinimumQuantity,
				|		RoomRatePrices6.VATRate,
				|		RoomRatePrices6.QuantityCalculationRule,
				|		RoomRatePrices6.QuantityCalculationRuleType,
				|		RoomRatePrices6.IsRoomRevenue,
				|		RoomRatePrices6.IsInPrice,
				|		RoomRatePrices6.IsPricePerPerson,
				|		RoomRatePrices6.ChargeToEachGuestSeparately,
				|		RoomRatePrices6.Unit,
				|		RoomRatePrices6.RoomRevenueAmountsOnly
				|	FROM
				|		RawRoomRatePrices AS RoomRatePrices6
				|			INNER JOIN FormulasForPriceTags AS FormulasForPriceTags
				|			ON RoomRatePrices6.ClientType = FormulasForPriceTags.ClientType
				|				AND RoomRatePrices6.PriceTag = FormulasForPriceTags.PriceTag
				|				AND RoomRatePrices6.CalendarDayType = FormulasForPriceTags.CalendarDayType
				|				AND RoomRatePrices6.AccommodationType = FormulasForPriceTags.AccommodationType
				|				AND (FormulasForPriceTags.Service = VALUE(Catalog.Services.EmptyRef))
				|				AND (FormulasForPriceTags.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
				|				AND (FormulasForPriceTags.RoomClass = VALUE(Catalog.RoomTypeClasses.EmptyRef))
				|				AND (FormulasForPriceTags.AccommodationType <> VALUE(Catalog.AccommodationTypes.EmptyRef))
				|	
				|	UNION ALL
				|	
				|	SELECT
				|		RoomRatePrices7.AccountingDate,
				|		RoomRatePrices7.RoomRate,
				|		RoomRatePrices7.CalendarDayType,
				|		RoomRatePrices7.PriceTag,
				|		RoomRatePrices7.ClientType,
				|		RoomRatePrices7.RoomType,
				|		RoomRatePrices7.RoomTypeRoomClass,
				|		RoomRatePrices7.AccommodationType,
				|		RoomRatePrices7.SetRoomRatePrices,
				|		RoomRatePrices7.SortCode,
				|		RoomRatePrices7.LineNumber,
				|		RoomRatePrices7.Hotel,
				|		RoomRatePrices7.Service,
				|		CASE
				|			WHEN ISNULL(FormulasForPriceTags.Discount, 0) <> 0
				|				THEN RoomRatePrices7.Price - RoomRatePrices7.Price * ISNULL(FormulasForPriceTags.Discount, 0) / 100
				|			ELSE (RoomRatePrices7.Price + ISNULL(FormulasForPriceTags.BracketsConstant, 0)) * ISNULL(FormulasForPriceTags.Multiplier, 1) + ISNULL(FormulasForPriceTags.Constant, 0)
				|		END,
				|		RoomRatePrices7.Currency,
				|		RoomRatePrices7.MinimumQuantity,
				|		RoomRatePrices7.VATRate,
				|		RoomRatePrices7.QuantityCalculationRule,
				|		RoomRatePrices7.QuantityCalculationRuleType,
				|		RoomRatePrices7.IsRoomRevenue,
				|		RoomRatePrices7.IsInPrice,
				|		RoomRatePrices7.IsPricePerPerson,
				|		RoomRatePrices7.ChargeToEachGuestSeparately,
				|		RoomRatePrices7.Unit,
				|		RoomRatePrices7.RoomRevenueAmountsOnly
				|	FROM
				|		RawRoomRatePrices AS RoomRatePrices7
				|			INNER JOIN FormulasForPriceTags AS FormulasForPriceTags
				|			ON RoomRatePrices7.ClientType = FormulasForPriceTags.ClientType
				|				AND RoomRatePrices7.PriceTag = FormulasForPriceTags.PriceTag
				|				AND RoomRatePrices7.CalendarDayType = FormulasForPriceTags.CalendarDayType
				|				AND RoomRatePrices7.Service = FormulasForPriceTags.Service
				|				AND RoomRatePrices7.RoomType = FormulasForPriceTags.RoomType
				|				AND (FormulasForPriceTags.Service <> VALUE(Catalog.Services.EmptyRef))
				|				AND (FormulasForPriceTags.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef))
				|				AND (FormulasForPriceTags.RoomClass = VALUE(Catalog.RoomTypeClasses.EmptyRef))
				|				AND (FormulasForPriceTags.AccommodationType = VALUE(Catalog.AccommodationTypes.EmptyRef))
				|	
				|	UNION ALL
				|	
				|	SELECT
				|		RoomRatePrices8.AccountingDate,
				|		RoomRatePrices8.RoomRate,
				|		RoomRatePrices8.CalendarDayType,
				|		RoomRatePrices8.PriceTag,
				|		RoomRatePrices8.ClientType,
				|		RoomRatePrices8.RoomType,
				|		RoomRatePrices8.RoomTypeRoomClass,
				|		RoomRatePrices8.AccommodationType,
				|		RoomRatePrices8.SetRoomRatePrices,
				|		RoomRatePrices8.SortCode,
				|		RoomRatePrices8.LineNumber,
				|		RoomRatePrices8.Hotel,
				|		RoomRatePrices8.Service,
				|		CASE
				|			WHEN ISNULL(FormulasForPriceTags.Discount, 0) <> 0
				|				THEN RoomRatePrices8.Price - RoomRatePrices8.Price * ISNULL(FormulasForPriceTags.Discount, 0) / 100
				|			ELSE (RoomRatePrices8.Price + ISNULL(FormulasForPriceTags.BracketsConstant, 0)) * ISNULL(FormulasForPriceTags.Multiplier, 1) + ISNULL(FormulasForPriceTags.Constant, 0)
				|		END,
				|		RoomRatePrices8.Currency,
				|		RoomRatePrices8.MinimumQuantity,
				|		RoomRatePrices8.VATRate,
				|		RoomRatePrices8.QuantityCalculationRule,
				|		RoomRatePrices8.QuantityCalculationRuleType,
				|		RoomRatePrices8.IsRoomRevenue,
				|		RoomRatePrices8.IsInPrice,
				|		RoomRatePrices8.IsPricePerPerson,
				|		RoomRatePrices8.ChargeToEachGuestSeparately,
				|		RoomRatePrices8.Unit,
				|		RoomRatePrices8.RoomRevenueAmountsOnly
				|	FROM
				|		RawRoomRatePrices AS RoomRatePrices8
				|			INNER JOIN FormulasForPriceTags AS FormulasForPriceTags
				|			ON RoomRatePrices8.ClientType = FormulasForPriceTags.ClientType
				|				AND RoomRatePrices8.PriceTag = FormulasForPriceTags.PriceTag
				|				AND RoomRatePrices8.CalendarDayType = FormulasForPriceTags.CalendarDayType
				|				AND RoomRatePrices8.Service = FormulasForPriceTags.Service
				|				AND RoomRatePrices8.RoomTypeRoomClass = FormulasForPriceTags.RoomClass
				|				AND (FormulasForPriceTags.Service <> VALUE(Catalog.Services.EmptyRef))
				|				AND (FormulasForPriceTags.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
				|				AND (FormulasForPriceTags.RoomClass <> VALUE(Catalog.RoomTypeClasses.EmptyRef))
				|				AND (FormulasForPriceTags.AccommodationType = VALUE(Catalog.AccommodationTypes.EmptyRef))
				|	
				|	UNION ALL
				|	
				|	SELECT
				|		RoomRatePrices9.AccountingDate,
				|		RoomRatePrices9.RoomRate,
				|		RoomRatePrices9.CalendarDayType,
				|		RoomRatePrices9.PriceTag,
				|		RoomRatePrices9.ClientType,
				|		RoomRatePrices9.RoomType,
				|		RoomRatePrices9.RoomTypeRoomClass,
				|		RoomRatePrices9.AccommodationType,
				|		RoomRatePrices9.SetRoomRatePrices,
				|		RoomRatePrices9.SortCode,
				|		RoomRatePrices9.LineNumber,
				|		RoomRatePrices9.Hotel,
				|		RoomRatePrices9.Service,
				|		CASE
				|			WHEN ISNULL(FormulasForPriceTags.Discount, 0) <> 0
				|				THEN RoomRatePrices9.Price - RoomRatePrices9.Price * ISNULL(FormulasForPriceTags.Discount, 0) / 100
				|			ELSE (RoomRatePrices9.Price + ISNULL(FormulasForPriceTags.BracketsConstant, 0)) * ISNULL(FormulasForPriceTags.Multiplier, 1) + ISNULL(FormulasForPriceTags.Constant, 0)
				|		END,
				|		RoomRatePrices9.Currency,
				|		RoomRatePrices9.MinimumQuantity,
				|		RoomRatePrices9.VATRate,
				|		RoomRatePrices9.QuantityCalculationRule,
				|		RoomRatePrices9.QuantityCalculationRuleType,
				|		RoomRatePrices9.IsRoomRevenue,
				|		RoomRatePrices9.IsInPrice,
				|		RoomRatePrices9.IsPricePerPerson,
				|		RoomRatePrices9.ChargeToEachGuestSeparately,
				|		RoomRatePrices9.Unit,
				|		RoomRatePrices9.RoomRevenueAmountsOnly
				|	FROM
				|		RawRoomRatePrices AS RoomRatePrices9
				|			INNER JOIN FormulasForPriceTags AS FormulasForPriceTags
				|			ON RoomRatePrices9.ClientType = FormulasForPriceTags.ClientType
				|				AND RoomRatePrices9.PriceTag = FormulasForPriceTags.PriceTag
				|				AND RoomRatePrices9.CalendarDayType = FormulasForPriceTags.CalendarDayType
				|				AND RoomRatePrices9.Service = FormulasForPriceTags.Service
				|				AND (FormulasForPriceTags.Service <> VALUE(Catalog.Services.EmptyRef))
				|				AND (FormulasForPriceTags.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
				|				AND (FormulasForPriceTags.RoomClass = VALUE(Catalog.RoomTypeClasses.EmptyRef))
				|				AND (FormulasForPriceTags.AccommodationType = VALUE(Catalog.AccommodationTypes.EmptyRef))
				|	
				|	UNION ALL
				|	
				|	SELECT
				|		RoomRatePrices10.AccountingDate,
				|		RoomRatePrices10.RoomRate,
				|		RoomRatePrices10.CalendarDayType,
				|		RoomRatePrices10.PriceTag,
				|		RoomRatePrices10.ClientType,
				|		RoomRatePrices10.RoomType,
				|		RoomRatePrices10.RoomTypeRoomClass,
				|		RoomRatePrices10.AccommodationType,
				|		RoomRatePrices10.SetRoomRatePrices,
				|		RoomRatePrices10.SortCode,
				|		RoomRatePrices10.LineNumber,
				|		RoomRatePrices10.Hotel,
				|		RoomRatePrices10.Service,
				|		CASE
				|			WHEN ISNULL(FormulasForPriceTags.Discount, 0) <> 0
				|				THEN RoomRatePrices10.Price - RoomRatePrices10.Price * ISNULL(FormulasForPriceTags.Discount, 0) / 100
				|			ELSE (RoomRatePrices10.Price + ISNULL(FormulasForPriceTags.BracketsConstant, 0)) * ISNULL(FormulasForPriceTags.Multiplier, 1) + ISNULL(FormulasForPriceTags.Constant, 0)
				|		END,
				|		RoomRatePrices10.Currency,
				|		RoomRatePrices10.MinimumQuantity,
				|		RoomRatePrices10.VATRate,
				|		RoomRatePrices10.QuantityCalculationRule,
				|		RoomRatePrices10.QuantityCalculationRuleType,
				|		RoomRatePrices10.IsRoomRevenue,
				|		RoomRatePrices10.IsInPrice,
				|		RoomRatePrices10.IsPricePerPerson,
				|		RoomRatePrices10.ChargeToEachGuestSeparately,
				|		RoomRatePrices10.Unit,
				|		RoomRatePrices10.RoomRevenueAmountsOnly
				|	FROM
				|		RawRoomRatePrices AS RoomRatePrices10
				|			INNER JOIN FormulasForPriceTags AS FormulasForPriceTags
				|			ON RoomRatePrices10.ClientType = FormulasForPriceTags.ClientType
				|				AND RoomRatePrices10.PriceTag = FormulasForPriceTags.PriceTag
				|				AND RoomRatePrices10.CalendarDayType = FormulasForPriceTags.CalendarDayType
				|				AND RoomRatePrices10.RoomType = FormulasForPriceTags.RoomType
				|				AND (FormulasForPriceTags.Service = VALUE(Catalog.Services.EmptyRef))
				|				AND (FormulasForPriceTags.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef))
				|				AND (FormulasForPriceTags.RoomClass = VALUE(Catalog.RoomTypeClasses.EmptyRef))
				|				AND (FormulasForPriceTags.AccommodationType = VALUE(Catalog.AccommodationTypes.EmptyRef))
				|	
				|	UNION ALL
				|	
				|	SELECT
				|		RoomRatePrices11.AccountingDate,
				|		RoomRatePrices11.RoomRate,
				|		RoomRatePrices11.CalendarDayType,
				|		RoomRatePrices11.PriceTag,
				|		RoomRatePrices11.ClientType,
				|		RoomRatePrices11.RoomType,
				|		RoomRatePrices11.RoomTypeRoomClass,
				|		RoomRatePrices11.AccommodationType,
				|		RoomRatePrices11.SetRoomRatePrices,
				|		RoomRatePrices11.SortCode,
				|		RoomRatePrices11.LineNumber,
				|		RoomRatePrices11.Hotel,
				|		RoomRatePrices11.Service,
				|		CASE
				|			WHEN ISNULL(FormulasForPriceTags.Discount, 0) <> 0
				|				THEN RoomRatePrices11.Price - RoomRatePrices11.Price * ISNULL(FormulasForPriceTags.Discount, 0) / 100
				|			ELSE (RoomRatePrices11.Price + ISNULL(FormulasForPriceTags.BracketsConstant, 0)) * ISNULL(FormulasForPriceTags.Multiplier, 1) + ISNULL(FormulasForPriceTags.Constant, 0)
				|		END,
				|		RoomRatePrices11.Currency,
				|		RoomRatePrices11.MinimumQuantity,
				|		RoomRatePrices11.VATRate,
				|		RoomRatePrices11.QuantityCalculationRule,
				|		RoomRatePrices11.QuantityCalculationRuleType,
				|		RoomRatePrices11.IsRoomRevenue,
				|		RoomRatePrices11.IsInPrice,
				|		RoomRatePrices11.IsPricePerPerson,
				|		RoomRatePrices11.ChargeToEachGuestSeparately,
				|		RoomRatePrices11.Unit,
				|		RoomRatePrices11.RoomRevenueAmountsOnly
				|	FROM
				|		RawRoomRatePrices AS RoomRatePrices11
				|			INNER JOIN FormulasForPriceTags AS FormulasForPriceTags
				|			ON RoomRatePrices11.ClientType = FormulasForPriceTags.ClientType
				|				AND RoomRatePrices11.PriceTag = FormulasForPriceTags.PriceTag
				|				AND RoomRatePrices11.CalendarDayType = FormulasForPriceTags.CalendarDayType
				|				AND RoomRatePrices11.RoomTypeRoomClass = FormulasForPriceTags.RoomClass
				|				AND (FormulasForPriceTags.Service = VALUE(Catalog.Services.EmptyRef))
				|				AND (FormulasForPriceTags.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
				|				AND (FormulasForPriceTags.RoomClass <> VALUE(Catalog.RoomTypeClasses.EmptyRef))
				|				AND (FormulasForPriceTags.AccommodationType = VALUE(Catalog.AccommodationTypes.EmptyRef))
				|	
				|	UNION ALL
				|	
				|	SELECT
				|		RoomRatePrices12.AccountingDate,
				|		RoomRatePrices12.RoomRate,
				|		RoomRatePrices12.CalendarDayType,
				|		RoomRatePrices12.PriceTag,
				|		RoomRatePrices12.ClientType,
				|		RoomRatePrices12.RoomType,
				|		RoomRatePrices12.RoomTypeRoomClass,
				|		RoomRatePrices12.AccommodationType,
				|		RoomRatePrices12.SetRoomRatePrices,
				|		RoomRatePrices12.SortCode,
				|		RoomRatePrices12.LineNumber,
				|		RoomRatePrices12.Hotel,
				|		RoomRatePrices12.Service,
				|		CASE
				|			WHEN ISNULL(FormulasForPriceTags.Discount, 0) <> 0
				|				THEN RoomRatePrices12.Price - RoomRatePrices12.Price * ISNULL(FormulasForPriceTags.Discount, 0) / 100
				|			ELSE (RoomRatePrices12.Price + ISNULL(FormulasForPriceTags.BracketsConstant, 0)) * ISNULL(FormulasForPriceTags.Multiplier, 1) + ISNULL(FormulasForPriceTags.Constant, 0)
				|		END,
				|		RoomRatePrices12.Currency,
				|		RoomRatePrices12.MinimumQuantity,
				|		RoomRatePrices12.VATRate,
				|		RoomRatePrices12.QuantityCalculationRule,
				|		RoomRatePrices12.QuantityCalculationRuleType,
				|		RoomRatePrices12.IsRoomRevenue,
				|		RoomRatePrices12.IsInPrice,
				|		RoomRatePrices12.IsPricePerPerson,
				|		RoomRatePrices12.ChargeToEachGuestSeparately,
				|		RoomRatePrices12.Unit,
				|		RoomRatePrices12.RoomRevenueAmountsOnly
				|	FROM
				|		RawRoomRatePrices AS RoomRatePrices12
				|			INNER JOIN FormulasForPriceTags AS FormulasForPriceTags
				|			ON RoomRatePrices12.ClientType = FormulasForPriceTags.ClientType
				|				AND RoomRatePrices12.PriceTag = FormulasForPriceTags.PriceTag
				|				AND RoomRatePrices12.CalendarDayType = FormulasForPriceTags.CalendarDayType
				|				AND (FormulasForPriceTags.Service = VALUE(Catalog.Services.EmptyRef))
				|				AND (FormulasForPriceTags.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
				|				AND (FormulasForPriceTags.RoomClass = VALUE(Catalog.RoomTypeClasses.EmptyRef))
				|				AND (FormulasForPriceTags.AccommodationType = VALUE(Catalog.AccommodationTypes.EmptyRef))) AS RoomRatePricesJoinedWithFormulas
				|
				|INDEX BY
				|	RoomRatePricesJoinedWithFormulas.AccountingDate,
				|	RoomRatePricesJoinedWithFormulas.RoomRate,
				|	RoomRatePricesJoinedWithFormulas.SetRoomRatePrices,
				|	RoomRatePricesJoinedWithFormulas.LineNumber,
				|	RoomRatePricesJoinedWithFormulas.Service,
				|	RoomRatePricesJoinedWithFormulas.ClientType,
				|	RoomRatePricesJoinedWithFormulas.PriceTag
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	RoomRatePrices.AccountingDate AS AccountingDate,
				|	RoomRatePrices.RoomRate AS RoomRate,
				|	RoomRatePrices.CalendarDayType AS CalendarDayType,
				|	RoomRatePrices.PriceTag AS PriceTag,
				|	RoomRatePrices.ClientType AS ClientType,
				|	RoomRatePrices.RoomType AS RoomType,
				|	RoomRatePrices.RoomTypeRoomClass AS RoomTypeRoomClass,
				|	RoomRatePrices.AccommodationType AS AccommodationType,
				|	RoomRatePrices.SetRoomRatePrices AS SetRoomRatePrices,
				|	RoomRatePrices.SortCode AS SortCode,
				|	RoomRatePrices.LineNumber AS LineNumber,
				|	RoomRatePrices.Hotel AS Hotel,
				|	RoomRatePrices.Service AS Service,
				|	CASE
				|		WHEN RoomRatePricesJoinedWithFormulas.Price IS NULL
				|			THEN RoomRatePrices.Price
				|		ELSE RoomRatePricesJoinedWithFormulas.Price
				|	END AS Price,
				|	RoomRatePrices.Currency AS Currency,
				|	RoomRatePrices.MinimumQuantity AS MinimumQuantity,
				|	RoomRatePrices.VATRate AS VATRate,
				|	RoomRatePrices.QuantityCalculationRule AS QuantityCalculationRule,
				|	RoomRatePrices.QuantityCalculationRuleType AS QuantityCalculationRuleType,
				|	RoomRatePrices.IsRoomRevenue AS IsRoomRevenue,
				|	RoomRatePrices.IsInPrice AS IsInPrice,
				|	RoomRatePrices.IsPricePerPerson AS IsPricePerPerson,
				|	RoomRatePrices.ChargeToEachGuestSeparately AS ChargeToEachGuestSeparately,
				|	RoomRatePrices.Unit AS Unit,
				|	RoomRatePrices.RoomRevenueAmountsOnly AS RoomRevenueAmountsOnly
				|INTO RoomRatePrices
				|FROM
				|	RawRoomRatePrices AS RoomRatePrices
				|		LEFT JOIN RoomRatePricesJoinedWithFormulas AS RoomRatePricesJoinedWithFormulas
				|		ON RoomRatePrices.AccountingDate = RoomRatePricesJoinedWithFormulas.AccountingDate
				|			AND RoomRatePrices.RoomRate = RoomRatePricesJoinedWithFormulas.RoomRate
				|			AND RoomRatePrices.SetRoomRatePrices = RoomRatePricesJoinedWithFormulas.SetRoomRatePrices
				|			AND RoomRatePrices.LineNumber = RoomRatePricesJoinedWithFormulas.LineNumber
				|			AND RoomRatePrices.Service = RoomRatePricesJoinedWithFormulas.Service
				|			AND RoomRatePrices.ClientType = RoomRatePricesJoinedWithFormulas.ClientType
				|			AND RoomRatePrices.PriceTag = RoomRatePricesJoinedWithFormulas.PriceTag
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|DROP RawRoomRatePrices
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|DROP RoomRatePricesJoinedWithFormulas
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	ServicePackages.ServicePackage AS ServicePackage,
				|	ServicePackages.Quantity AS Quantity,
				|	ServicePackages.DateFrom AS DateFrom,
				|	ServicePackages.DateTo AS DateTo,
				|	ServicePackages.PacketPriceIsIncludedInRoomRate AS PacketPriceIsIncludedInRoomRate,
				|	ServicePackages.IsExtraPackage AS IsExtraPackage,
				|	ServicePackages.IsMealBoardTerm AS IsMealBoardTerm,
				|	ServicePackages.IsPerPerson AS IsPerPerson,
				|	ServicePackages.UsageType AS UsageType,
				|	ServicePackages.DateValidFrom AS DateValidFrom,
				|	ServicePackages.DateValidTo AS DateValidTo
				|INTO ServicePackages
				|FROM
				|	&qServicePackages AS ServicePackages
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	ServicePackagePeriods.ServicePackage AS ServicePackage,
				|	MAX(ServicePackagePeriods.Period) AS ActivePeriod
				|INTO ServicePackagesActivePeriods
				|FROM
				|	InformationRegister.ServicePackageRecords.SliceLast(&qDate, ) AS ServicePackagePeriods
				|		INNER JOIN ServicePackages AS ServicePackages
				|		ON (ServicePackages.ServicePackage = ServicePackagePeriods.ServicePackage)
				|
				|GROUP BY
				|	ServicePackagePeriods.ServicePackage
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	RoomRatesSliceLast.SetRoomRateFormulas AS Recorder,
				|	RoomRatesSliceLast.RoomRate AS RoomRate
				|INTO ActiveSetRoomRateFormulas
				|FROM
				|	InformationRegister.RoomRates.SliceLast(
				|			&qDate,
				|			RoomRate = &qRoomRate
				|				AND Hotel = &qHotel
				|				AND IsFormula) AS RoomRatesSliceLast
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	RoomRateFormulas.RoomRate.BasedOnRoomRate AS BasedOnRoomRate,
				|	RoomRateFormulas.RoomRate.BasedOnPriceTag AS BasedOnPriceTag,
				|	RoomRateFormulas.RoomRate AS RoomRate,
				|	RoomRateFormulas.Hotel AS Hotel,
				|	RoomRateFormulas.IsFormula AS IsFormula,
				|	RoomRateFormulas.Service AS Service,
				|	RoomRateFormulas.RoomType AS RoomType,
				|	RoomRateFormulas.AccommodationType AS AccommodationType,
				|	RoomRateFormulas.ClientType AS ClientType,
				|	RoomRateFormulas.CalendarDayType AS CalendarDayType,
				|	RoomRateFormulas.Recorder AS Recorder,
				|	RoomRateFormulas.Period AS Period,
				|	RoomRateFormulas.BracketsConstant AS BracketsConstant,
				|	RoomRateFormulas.Constant AS Constant,
				|	RoomRateFormulas.Multiplier AS Multiplier,
				|	RoomRateFormulas.ReplaceWithService AS ReplaceWithService
				|INTO RoomRateFormulas
				|FROM
				|	InformationRegister.RoomRateFormulas AS RoomRateFormulas
				|		INNER JOIN ActiveSetRoomRateFormulas AS ActiveSetRoomRateFormulas
				|		ON RoomRateFormulas.Recorder = ActiveSetRoomRateFormulas.Recorder
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT DISTINCT
				|	ActivePriceTags.PriceTag AS PriceTag
				|INTO ActivePriceTags
				|FROM
				|	Document.SetRoomRatePrices.FormulasForDayTypesAndPricetags AS ActivePriceTags
				|		INNER JOIN Orders AS Orders
				|		ON ActivePriceTags.Ref = Orders.SetRoomRatePrices
				|			AND ActivePriceTags.PriceTag = Orders.PriceTag
				|			AND ActivePriceTags.CalendarDayType = Orders.CalendarDayType
				|WHERE
				|	ActivePriceTags.Ref.RoomRate = &qPricesRoomRate
				|	AND ActivePriceTags.ClientType = &qClientType
				|	AND (&qPriceTagIsFilled
				|				AND ActivePriceTags.PriceTag = &qPriceTag
				|			OR NOT &qPriceTagIsFilled)
				|	AND (ActivePriceTags.RoomType = &qRoomType
				|			OR ActivePriceTags.RoomType = &qEmptyRoomTypeRef
				|			OR &qRoomTypeIsUndefined)
				|	AND (ActivePriceTags.AccommodationType = &qAccommodationType
				|			OR ActivePriceTags.AccommodationType = &qEmptyAccommodationTypeRef
				|			OR &qAccommodationTypeIsUndefined)
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	MergedRoomRatePrices.Recorder AS Recorder,
				|	MergedRoomRatePrices.Hotel AS Hotel,
				|	MergedRoomRatePrices.RoomRate AS RoomRate,
				|	MergedRoomRatePrices.CalendarDayType AS CalendarDayType,
				|	MergedRoomRatePrices.PriceTag AS PriceTag,
				|	MergedRoomRatePrices.ClientType AS ClientType,
				|	MergedRoomRatePrices.RoomType AS RoomType,
				|	MergedRoomRatePrices.RoomTypeSortCode AS RoomTypeSortCode,
				|	MergedRoomRatePrices.AccommodationType AS AccommodationType,
				|	MergedRoomRatePrices.AccommodationTypeSortCode AS AccommodationTypeSortCode,
				|	MergedRoomRatePrices.SetRoomRatePrices AS SetRoomRatePrices,
				|	MergedRoomRatePrices.Service AS Service,
				|	MergedRoomRatePrices.Unit AS Unit,
				|	MergedRoomRatePrices.PricesService AS PricesService,
				|	MergedRoomRatePrices.Currency AS Currency,
				|	MergedRoomRatePrices.MinimumQuantity AS MinimumQuantity,
				|	MergedRoomRatePrices.VATRate AS VATRate,
				|	MergedRoomRatePrices.QuantityCalculationRule AS QuantityCalculationRule,
				|	MergedRoomRatePrices.IsRoomRevenue AS IsRoomRevenue,
				|	MergedRoomRatePrices.IsInPrice AS IsInPrice,
				|	MergedRoomRatePrices.IsPricePerPerson AS IsPricePerPerson,
				|	MergedRoomRatePrices.RoomRevenueAmountsOnly AS RoomRevenueAmountsOnly,
				|	MergedRoomRatePrices.AccountingDate AS AccountingDate,
				|	0 AS AccountingDayNumber,
				|	&qEmptyString AS Remarks,
				|	NULL AS ServicePackage,
				|	&qEmptyDate AS ServicePackageDateValidFrom,
				|	&qEmptyDate AS ServicePackageDateValidTo,
				|	&qEmptyDate AS ServicePackagePeriodFrom,
				|	&qEmptyDate AS ServicePackagePeriodTo,
				|	MergedRoomRatePrices.PointInTime AS PointInTime,
				|	FALSE AS PacketPriceIsIncludedInRoomRate,
				|	UNDEFINED AS ServicePackageUsageType,
				|	&qEmptyDate AS ServicePackageDateFrom,
				|	&qEndOfTime AS ServicePackageDateTo,
				|	MIN(MergedRoomRatePrices.LineNumber) AS LineNumber,
				|	MIN(MergedRoomRatePrices.SortCode) AS SortCode,
				|	SUM(MergedRoomRatePrices.Price) AS Price,
				|	CASE
				|		WHEN MergedRoomRatePrices.IsRoomRevenue
				|				AND MergedRoomRatePrices.IsInPrice
				|			THEN 1
				|		WHEN MergedRoomRatePrices.QuantityCalculationRuleType = VALUE(Enum.QuantityCalculationRuleTypes.EarlyCheckIn)
				|			THEN 1
				|		WHEN MergedRoomRatePrices.QuantityCalculationRuleType = VALUE(Enum.QuantityCalculationRuleTypes.EarlyCheckInNoDateShift)
				|			THEN 1
				|		WHEN MergedRoomRatePrices.QuantityCalculationRuleType = VALUE(Enum.QuantityCalculationRuleTypes.LateCheckOut)
				|			THEN 1
				|		WHEN MergedRoomRatePrices.Service = MergedRoomRatePrices.EarlyCheckInService
				|			THEN 1
				|		WHEN MergedRoomRatePrices.Service = MergedRoomRatePrices.LateCheckOutService
				|			THEN 1
				|		ELSE SUM(1)
				|	END AS Quantity,
				|	SUM(MergedRoomRatePrices.NumberOfPersons) AS NumberOfPersons,
				|	SUM(MergedRoomRatePrices.NumberOfPersonsInRoom) AS NumberOfPersonsInRoom,
				|	SUM(MergedRoomRatePrices.NumberOfRooms) AS NumberOfRooms,
				|	SUM(MergedRoomRatePrices.NumberOfBeds) AS NumberOfBeds,
				|	SUM(MergedRoomRatePrices.NumberOfAdditionalBeds) AS NumberOfAdditionalBeds
				|FROM
				|	(SELECT
				|		RoomRatePrices.AccountingDate AS AccountingDate,
				|		RoomRatePrices.SetRoomRatePrices AS Recorder,
				|		RoomRatePrices.Hotel AS Hotel,
				|		RoomRatePrices.RoomRate AS RoomRate,
				|		RoomRatePrices.CalendarDayType AS CalendarDayType,
				|		RoomRatePrices.PriceTag AS PriceTag,
				|		RoomRatePrices.ClientType AS ClientType,
				|		RoomRatePrices.RoomType AS RoomType,
				|		RoomRatePrices.RoomType.SortCode AS RoomTypeSortCode,
				|		CASE
				|			WHEN &qAccommodationTypeIsUndefined
				|				THEN TemplateAccommodationTypes.AccommodationType
				|			WHEN ISNULL(RoomRatePrices.ChargeToEachGuestSeparately, FALSE)
				|					AND NOT TemplateAccommodationTypes.AccommodationType.Code IS NULL
				|				THEN TemplateAccommodationTypes.AccommodationType
				|			ELSE &qAccommodationType
				|		END AS AccommodationType,
				|		CASE
				|			WHEN &qAccommodationTypeIsUndefined
				|				THEN TemplateAccommodationTypes.AccommodationType.SortCode
				|			WHEN ISNULL(RoomRatePrices.ChargeToEachGuestSeparately, FALSE)
				|					AND NOT TemplateAccommodationTypes.AccommodationType.Code IS NULL
				|				THEN TemplateAccommodationTypes.AccommodationType.SortCode
				|			ELSE &qAccommodationTypeSortCode
				|		END AS AccommodationTypeSortCode,
				|		RoomRatePrices.SetRoomRatePrices AS SetRoomRatePrices,
				|		CASE
				|			WHEN RoomRateFormulas.ReplaceWithService.Code IS NULL
				|				THEN RoomRatePrices.Service
				|			ELSE RoomRateFormulas.ReplaceWithService
				|		END AS Service,
				|		CASE
				|			WHEN RoomRateFormulas.ReplaceWithService.Code IS NULL
				|				THEN RoomRatePrices.Unit
				|			ELSE RoomRateFormulas.ReplaceWithService.Unit
				|		END AS Unit,
				|		RoomRatePrices.Service AS PricesService,
				|		RoomRatePrices.Currency AS Currency,
				|		RoomRatePrices.MinimumQuantity AS MinimumQuantity,
				|		RoomRatePrices.VATRate AS VATRate,
				|		RoomRatePrices.QuantityCalculationRule AS QuantityCalculationRule,
				|		RoomRatePrices.IsRoomRevenue AS IsRoomRevenue,
				|		RoomRatePrices.IsInPrice AS IsInPrice,
				|		CASE
				|			WHEN RoomRatePrices.IsRoomRevenue
				|					AND RoomRatePrices.IsInPrice
				|				THEN FALSE
				|			ELSE RoomRatePrices.IsPricePerPerson
				|		END AS IsPricePerPerson,
				|		RoomRatePrices.RoomRevenueAmountsOnly AS RoomRevenueAmountsOnly,
				|		RoomRatePrices.SetRoomRatePrices.PointInTime AS PointInTime,
				|		RoomRatePrices.LineNumber AS LineNumber,
				|		RoomRatePrices.SortCode AS SortCode,
				|		(RoomRatePrices.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0) AS Price,
				|		CASE
				|			WHEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons4Reservation, 0) > 0
				|					AND RoomRatePrices.IsPricePerPerson
				|				THEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons4Reservation, 0)
				|			WHEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons, 0) > 0
				|				THEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons, 0)
				|			ELSE 1
				|		END AS NumberOfPersons,
				|		CASE
				|			WHEN RoomRatePrices.IsRoomRevenue
				|				THEN CASE
				|						WHEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons4Reservation, 0) > 0
				|								AND RoomRatePrices.IsPricePerPerson
				|							THEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons4Reservation, 0)
				|						WHEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons, 0) > 0
				|							THEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons, 0)
				|						ELSE 1
				|					END
				|			ELSE 0
				|		END AS NumberOfPersonsInRoom,
				|		CASE
				|			WHEN RoomRatePrices.IsRoomRevenue
				|				THEN ISNULL(RoomRatePrices.AccommodationType.NumberOfRooms, 0)
				|			ELSE 0
				|		END AS NumberOfRooms,
				|		CASE
				|			WHEN RoomRatePrices.IsRoomRevenue
				|				THEN ISNULL(RoomRatePrices.AccommodationType.NumberOfBeds, 0)
				|			ELSE 0
				|		END AS NumberOfBeds,
				|		CASE
				|			WHEN RoomRatePrices.IsRoomRevenue
				|				THEN ISNULL(RoomRatePrices.AccommodationType.NumberOfAdditionalBeds, 0)
				|			ELSE 0
				|		END AS NumberOfAdditionalBeds,
				|		RoomRateFormulas.BracketsConstant AS BracketsConstant,
				|		RoomRateFormulas.Constant AS Constant,
				|		RoomRateFormulas.Multiplier AS Multiplier,
				|		RoomRatePrices.QuantityCalculationRuleType AS QuantityCalculationRuleType,
				|		RoomRatePrices.RoomRate.EarlyCheckInService AS EarlyCheckInService,
				|		RoomRatePrices.RoomRate.LateCheckOutService AS LateCheckOutService
				|	FROM
				|		RoomRatePrices AS RoomRatePrices
				|			INNER JOIN TemplateAccommodationTypes AS TemplateAccommodationTypes
				|			ON (TemplateAccommodationTypes.AccommodationTemplate = &qAccommodationTemplate)
				|				AND (TemplateAccommodationTypes.AccommodationType = RoomRatePrices.AccommodationType
				|					OR RoomRatePrices.AccommodationType = &qEmptyAccommodationTypeRef)
				|			LEFT JOIN RoomRateFormulas AS RoomRateFormulas
				|			ON RoomRatePrices.RoomRate = RoomRateFormulas.BasedOnRoomRate
				|				AND RoomRatePrices.Hotel = RoomRateFormulas.Hotel
				|				AND (NOT RoomRateFormulas.IsFormula
				|					OR RoomRateFormulas.IsFormula
				|						AND RoomRatePrices.RoomType = RoomRateFormulas.RoomType
				|						AND RoomRatePrices.ClientType = RoomRateFormulas.ClientType
				|						AND RoomRatePrices.AccommodationType = RoomRateFormulas.AccommodationType
				|						AND (RoomRatePrices.CalendarDayType = RoomRateFormulas.CalendarDayType
				|							OR RoomRateFormulas.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef))
				|						AND (RoomRatePrices.Service = RoomRateFormulas.Service
				|							OR RoomRateFormulas.Service = VALUE(Catalog.Services.EmptyRef)))
				|				AND (RoomRateFormulas.BasedOnPriceTag = VALUE(Catalog.PriceTags.EmptyRef)
				|					OR RoomRatePrices.PriceTag = RoomRateFormulas.BasedOnPriceTag
				|						AND RoomRateFormulas.BasedOnPriceTag <> VALUE(Catalog.PriceTags.EmptyRef))
				|	WHERE
				|		&qFilterByCalendarDayTypes
				|		AND (&qPriceTagIsFilled
				|					AND RoomRatePrices.PriceTag = &qPriceTag
				|				OR NOT &qPriceTagIsFilled)
				|		AND (RoomRatePrices.RoomType = &qRoomType
				|				OR RoomRatePrices.RoomType = &qEmptyRoomTypeRef
				|				OR &qRoomTypeIsUndefined)
				|		AND (NOT &qMinimizeOutput
				|				OR &qMinimizeOutput
				|					AND (RoomRatePrices.IsRoomRevenue
				|						OR NOT RoomRatePrices.IsRoomRevenue
				|							AND RoomRatePrices.IsInPrice
				|							AND RoomRatePrices.Price <> 0))) AS MergedRoomRatePrices
				|
				|GROUP BY
				|	MergedRoomRatePrices.AccountingDate,
				|	MergedRoomRatePrices.Recorder,
				|	MergedRoomRatePrices.Hotel,
				|	MergedRoomRatePrices.RoomRate,
				|	MergedRoomRatePrices.CalendarDayType,
				|	MergedRoomRatePrices.PriceTag,
				|	MergedRoomRatePrices.ClientType,
				|	MergedRoomRatePrices.RoomType,
				|	MergedRoomRatePrices.RoomTypeSortCode,
				|	MergedRoomRatePrices.AccommodationType,
				|	MergedRoomRatePrices.AccommodationTypeSortCode,
				|	MergedRoomRatePrices.SetRoomRatePrices,
				|	MergedRoomRatePrices.Service,
				|	MergedRoomRatePrices.Unit,
				|	MergedRoomRatePrices.PricesService,
				|	MergedRoomRatePrices.Currency,
				|	MergedRoomRatePrices.MinimumQuantity,
				|	MergedRoomRatePrices.VATRate,
				|	MergedRoomRatePrices.QuantityCalculationRule,
				|	MergedRoomRatePrices.IsRoomRevenue,
				|	MergedRoomRatePrices.IsInPrice,
				|	MergedRoomRatePrices.IsPricePerPerson,
				|	MergedRoomRatePrices.RoomRevenueAmountsOnly,
				|	MergedRoomRatePrices.PointInTime,
				|	MergedRoomRatePrices.QuantityCalculationRuleType,
				|	MergedRoomRatePrices.EarlyCheckInService,
				|	MergedRoomRatePrices.LateCheckOutService
				|
				|UNION ALL
				|
				|SELECT
				|	&qEmptySetRoomRatePricesRef,
				|	&qHotel,
				|	&qRoomRate,
				|	MergedPackageServicesForAccommodationTemplate.CalendarDayType,
				|	MergedPackageServicesForAccommodationTemplate.PriceTag,
				|	MergedPackageServicesForAccommodationTemplate.ClientType,
				|	MergedPackageServicesForAccommodationTemplate.RoomType,
				|	MergedPackageServicesForAccommodationTemplate.RoomTypeSortCode,
				|	MergedPackageServicesForAccommodationTemplate.AccommodationType,
				|	MergedPackageServicesForAccommodationTemplate.AccommodationTypeSortCode,
				|	&qEmptySetRoomRatePricesRef,
				|	MergedPackageServicesForAccommodationTemplate.Service,
				|	MergedPackageServicesForAccommodationTemplate.Unit,
				|	MergedPackageServicesForAccommodationTemplate.PricesService,
				|	MergedPackageServicesForAccommodationTemplate.Currency,
				|	0,
				|	MergedPackageServicesForAccommodationTemplate.VATRate,
				|	MergedPackageServicesForAccommodationTemplate.QuantityCalculationRule,
				|	MergedPackageServicesForAccommodationTemplate.IsRoomRevenue,
				|	MergedPackageServicesForAccommodationTemplate.IsInPrice,
				|	MergedPackageServicesForAccommodationTemplate.IsServicePerPerson,
				|	MergedPackageServicesForAccommodationTemplate.RoomRevenueAmountsOnly,
				|	MergedPackageServicesForAccommodationTemplate.AccountingDate,
				|	MergedPackageServicesForAccommodationTemplate.AccountingDayNumber,
				|	MergedPackageServicesForAccommodationTemplate.Remarks,
				|	MergedPackageServicesForAccommodationTemplate.ServicePackage,
				|	MergedPackageServicesForAccommodationTemplate.ServicePackageDateValidFrom,
				|	MergedPackageServicesForAccommodationTemplate.ServicePackageDateValidTo,
				|	MergedPackageServicesForAccommodationTemplate.ServicePackagePeriodFrom,
				|	MergedPackageServicesForAccommodationTemplate.ServicePackagePeriodTo,
				|	NULL,
				|	MergedPackageServicesForAccommodationTemplate.PacketPriceIsIncludedInRoomRate,
				|	MergedPackageServicesForAccommodationTemplate.ServicePackageUsageType,
				|	MergedPackageServicesForAccommodationTemplate.ServicePackageDateFrom,
				|	MergedPackageServicesForAccommodationTemplate.ServicePackageDateTo,
				|	MIN(MergedPackageServicesForAccommodationTemplate.RowNumber),
				|	999999999,
				|	MergedPackageServicesForAccommodationTemplate.Price,
				|	CASE
				|		WHEN ISNULL(MergedPackageServicesForAccommodationTemplate.Service.IsRoomRevenue, FALSE)
				|				AND NOT ISNULL(MergedPackageServicesForAccommodationTemplate.ServicePackage.IsMealBoardTerm, FALSE)
				|				AND NOT ISNULL(MergedPackageServicesForAccommodationTemplate.Service.RoomRevenueAmountsOnly, FALSE)
				|			THEN MAX(MergedPackageServicesForAccommodationTemplate.Quantity)
				|		ELSE SUM(MergedPackageServicesForAccommodationTemplate.Quantity)
				|	END,
				|	SUM(MergedPackageServicesForAccommodationTemplate.NumberOfPersons),
				|	SUM(MergedPackageServicesForAccommodationTemplate.NumberOfPersonsInRoom),
				|	SUM(MergedPackageServicesForAccommodationTemplate.NumberOfRooms),
				|	SUM(MergedPackageServicesForAccommodationTemplate.NumberOfBeds),
				|	SUM(MergedPackageServicesForAccommodationTemplate.NumberOfAdditionalBeds)
				|FROM
				|	(SELECT
				|		PackageServicesForAccommodationTemplate.CalendarDayType AS CalendarDayType,
				|		ActivePriceTagsList.PriceTag AS PriceTag,
				|		PackageServicesForAccommodationTemplate.ClientType AS ClientType,
				|		PackageServicesForAccommodationTemplate.RoomType AS RoomType,
				|		ISNULL(PackageServicesForAccommodationTemplate.RoomType.SortCode, 0) AS RoomTypeSortCode,
				|		CASE
				|			WHEN &qAccommodationTypeIsUndefined
				|				THEN TemplateAccommodationTypes.AccommodationType
				|			WHEN ISNULL(PackageServicesForAccommodationTemplate.Service.ChargeToEachGuestSeparately, FALSE)
				|					AND NOT TemplateAccommodationTypes.AccommodationType.Code IS NULL
				|				THEN TemplateAccommodationTypes.AccommodationType
				|			ELSE &qAccommodationType
				|		END AS AccommodationType,
				|		CASE
				|			WHEN &qAccommodationTypeIsUndefined
				|				THEN TemplateAccommodationTypes.AccommodationType.SortCode
				|			WHEN ISNULL(PackageServicesForAccommodationTemplate.Service.ChargeToEachGuestSeparately, FALSE)
				|					AND NOT TemplateAccommodationTypes.AccommodationType.Code IS NULL
				|				THEN TemplateAccommodationTypes.AccommodationType.SortCode
				|			ELSE &qAccommodationTypeSortCode
				|		END AS AccommodationTypeSortCode,
				|		CASE
				|			WHEN RoomRateFormulas.ReplaceWithService.Code IS NULL
				|				THEN PackageServicesForAccommodationTemplate.Service
				|			ELSE RoomRateFormulas.ReplaceWithService
				|		END AS Service,
				|		CASE
				|			WHEN RoomRateFormulas.ReplaceWithService.Code IS NULL
				|				THEN PackageServicesForAccommodationTemplate.Unit
				|			ELSE RoomRateFormulas.ReplaceWithService.Unit
				|		END AS Unit,
				|		PackageServicesForAccommodationTemplate.Service AS PricesService,
				|		PackageServicesForAccommodationTemplate.Currency AS Currency,
				|		PackageServicesForAccommodationTemplate.VATRate AS VATRate,
				|		PackageServicesForAccommodationTemplate.QuantityCalculationRule AS QuantityCalculationRule,
				|		CASE
				|			WHEN ISNULL(ServicePackages.IsMealBoardTerm, FALSE)
				|				THEN FALSE
				|			ELSE ISNULL(PackageServicesForAccommodationTemplate.Service.IsRoomRevenue, FALSE)
				|		END AS IsRoomRevenue,
				|		PackageServicesForAccommodationTemplate.IsInPrice AS IsInPrice,
				|		PackageServicesForAccommodationTemplate.IsServicePerPerson AS IsServicePerPerson,
				|		ISNULL(PackageServicesForAccommodationTemplate.Service.RoomRevenueAmountsOnly, FALSE) AS RoomRevenueAmountsOnly,
				|		PackageServicesForAccommodationTemplate.AccountingDate AS AccountingDate,
				|		PackageServicesForAccommodationTemplate.AccountingDayNumber AS AccountingDayNumber,
				|		CAST(PackageServicesForAccommodationTemplate.Remarks AS STRING(100)) AS Remarks,
				|		PackageServicesForAccommodationTemplate.ServicePackage AS ServicePackage,
				|		ISNULL(ServicePackages.DateValidFrom, &qEmptyDate) AS ServicePackageDateValidFrom,
				|		ISNULL(ServicePackages.DateValidTo, &qEmptyDate) AS ServicePackageDateValidTo,
				|		ISNULL(PackageServicesForAccommodationTemplate.PeriodFrom, &qEmptyDate) AS ServicePackagePeriodFrom,
				|		ISNULL(PackageServicesForAccommodationTemplate.PeriodTo, &qEmptyDate) AS ServicePackagePeriodTo,
				|		ISNULL(ServicePackages.PacketPriceIsIncludedInRoomRate, FALSE) AS PacketPriceIsIncludedInRoomRate,
				|		ServicePackages.UsageType AS ServicePackageUsageType,
				|		ServicePackages.DateFrom AS ServicePackageDateFrom,
				|		ServicePackages.DateTo AS ServicePackageDateTo,
				|		PackageServicesForAccommodationTemplate.RowNumber AS RowNumber,
				|		(PackageServicesForAccommodationTemplate.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0) AS Price,
				|		PackageServicesForAccommodationTemplate.Quantity * ServicePackages.Quantity AS Quantity,
				|		CASE
				|			WHEN ISNULL(PackageServicesForAccommodationTemplate.AccommodationType.NumberOfPersons4Reservation, 0) > 0
				|					AND PackageServicesForAccommodationTemplate.IsServicePerPerson
				|				THEN ISNULL(PackageServicesForAccommodationTemplate.AccommodationType.NumberOfPersons4Reservation, 0)
				|			WHEN ISNULL(PackageServicesForAccommodationTemplate.AccommodationType.NumberOfPersons, 0) > 0
				|				THEN ISNULL(PackageServicesForAccommodationTemplate.AccommodationType.NumberOfPersons, 0)
				|			ELSE 1
				|		END AS NumberOfPersons,
				|		CASE
				|			WHEN ISNULL(PackageServicesForAccommodationTemplate.Service.IsRoomRevenue, FALSE)
				|					AND NOT ISNULL(ServicePackages.IsMealBoardTerm, FALSE)
				|					AND NOT ISNULL(PackageServicesForAccommodationTemplate.Service.RoomRevenueAmountsOnly, FALSE)
				|				THEN CASE
				|						WHEN ISNULL(PackageServicesForAccommodationTemplate.AccommodationType.NumberOfPersons4Reservation, 0) > 0
				|								AND PackageServicesForAccommodationTemplate.IsServicePerPerson
				|							THEN ISNULL(PackageServicesForAccommodationTemplate.AccommodationType.NumberOfPersons4Reservation, 0)
				|						WHEN ISNULL(PackageServicesForAccommodationTemplate.AccommodationType.NumberOfPersons, 0) > 0
				|							THEN ISNULL(PackageServicesForAccommodationTemplate.AccommodationType.NumberOfPersons, 0)
				|						ELSE 1
				|					END
				|			ELSE 0
				|		END AS NumberOfPersonsInRoom,
				|		CASE
				|			WHEN ISNULL(PackageServicesForAccommodationTemplate.Service.IsRoomRevenue, FALSE)
				|					AND NOT ISNULL(ServicePackages.IsMealBoardTerm, FALSE)
				|					AND NOT ISNULL(PackageServicesForAccommodationTemplate.Service.RoomRevenueAmountsOnly, FALSE)
				|				THEN ISNULL(PackageServicesForAccommodationTemplate.AccommodationType.NumberOfRooms, 0)
				|			ELSE 0
				|		END AS NumberOfRooms,
				|		CASE
				|			WHEN ISNULL(PackageServicesForAccommodationTemplate.Service.IsRoomRevenue, FALSE)
				|					AND NOT ISNULL(ServicePackages.IsMealBoardTerm, FALSE)
				|					AND NOT ISNULL(PackageServicesForAccommodationTemplate.Service.RoomRevenueAmountsOnly, FALSE)
				|				THEN ISNULL(PackageServicesForAccommodationTemplate.AccommodationType.NumberOfBeds, 0)
				|			ELSE 0
				|		END AS NumberOfBeds,
				|		CASE
				|			WHEN ISNULL(PackageServicesForAccommodationTemplate.Service.IsRoomRevenue, FALSE)
				|					AND NOT ISNULL(ServicePackages.IsMealBoardTerm, FALSE)
				|					AND NOT ISNULL(PackageServicesForAccommodationTemplate.Service.RoomRevenueAmountsOnly, FALSE)
				|				THEN ISNULL(PackageServicesForAccommodationTemplate.AccommodationType.NumberOfAdditionalBeds, 0)
				|			ELSE 0
				|		END AS NumberOfAdditionalBeds
				|	FROM
				|		InformationRegister.ServicePackageRecords AS PackageServicesForAccommodationTemplate
				|			INNER JOIN ServicePackages AS ServicePackages
				|			ON PackageServicesForAccommodationTemplate.ServicePackage = ServicePackages.ServicePackage
				|			INNER JOIN ServicePackagesActivePeriods AS ServicePackagesActivePeriods
				|			ON PackageServicesForAccommodationTemplate.ServicePackage = ServicePackagesActivePeriods.ServicePackage
				|				AND PackageServicesForAccommodationTemplate.Period = ServicePackagesActivePeriods.ActivePeriod
				|			LEFT JOIN ActivePriceTags AS ActivePriceTagsList
				|			ON (TRUE)
				|			INNER JOIN TemplateAccommodationTypes AS TemplateAccommodationTypes
				|			ON (TemplateAccommodationTypes.AccommodationTemplate = &qAccommodationTemplate)
				|				AND (TemplateAccommodationTypes.AccommodationType = PackageServicesForAccommodationTemplate.AccommodationType
				|					OR PackageServicesForAccommodationTemplate.AccommodationType = &qEmptyAccommodationTypeRef)
				|				AND (NOT PackageServicesForAccommodationTemplate.ServicePackage.IsPerPerson
				|						AND NOT &qSplitPackagesByGuests
				|					OR NOT PackageServicesForAccommodationTemplate.ServicePackage.IsPerPerson
				|						AND &qSplitPackagesByGuests
				|						AND TemplateAccommodationTypes.AccommodationType = &qAccommodationType
				|						AND TemplateAccommodationTypes.LineNumber = &qAccommodationTypeLineNumber
				|					OR PackageServicesForAccommodationTemplate.ServicePackage.IsPerPerson
				|						AND TemplateAccommodationTypes.AccommodationType = &qAccommodationType
				|						AND TemplateAccommodationTypes.LineNumber = &qAccommodationTypeLineNumber)
				|			LEFT JOIN RoomRateFormulas AS RoomRateFormulas
				|			ON (RoomRateFormulas.RoomRate = &qRoomRate)
				|				AND (RoomRateFormulas.Hotel = &qHotel)
				|				AND (RoomRateFormulas.IsFormula)
				|				AND PackageServicesForAccommodationTemplate.Service = RoomRateFormulas.Service
				|				AND PackageServicesForAccommodationTemplate.RoomType = RoomRateFormulas.RoomType
				|				AND PackageServicesForAccommodationTemplate.ClientType = RoomRateFormulas.ClientType
				|				AND (PackageServicesForAccommodationTemplate.AccommodationType = RoomRateFormulas.AccommodationType
				|					OR PackageServicesForAccommodationTemplate.AccommodationType = VALUE(Catalog.AccommodationTypes.EmptyRef))
				|				AND (PackageServicesForAccommodationTemplate.CalendarDayType = RoomRateFormulas.CalendarDayType
				|					OR RoomRateFormulas.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef))
				|	WHERE
				|		ServicePackages.DateValidFrom <= &qCheckInDate
				|		AND (ENDOFPERIOD(ServicePackages.DateValidTo, DAY) >= &qCheckInDate
				|				OR ServicePackages.DateValidTo = &qEmptyDate)
				|		AND PackageServicesForAccommodationTemplate.ClientType = &qClientType
				|		AND (PackageServicesForAccommodationTemplate.RoomType = &qRoomType
				|				OR PackageServicesForAccommodationTemplate.RoomType = &qEmptyRoomTypeRef
				|				OR &qRoomTypeIsUndefined)
				|		AND (PackageServicesForAccommodationTemplate.RoomClass = &qRoomClass
				|				OR PackageServicesForAccommodationTemplate.RoomClass = &qEmptyRoomClassRef
				|				OR &qRoomTypeIsUndefined)
				|		AND (NOT &qAccommodationPeriodIsSet
				|				OR &qAccommodationPeriodIsSet
				|					AND (PackageServicesForAccommodationTemplate.CalendarDayType IN (&qCalendarDayTypesList)
				|						OR PackageServicesForAccommodationTemplate.CalendarDayType = &qEmptyCalendarDayType))
				|		AND PackageServicesForAccommodationTemplate.Service IS NOT NULL 
				|		AND PackageServicesForAccommodationTemplate.Service <> &qEmptyService
				|		AND (NOT &qMinimizeOutput
				|				OR &qMinimizeOutput
				|					AND (PackageServicesForAccommodationTemplate.IsInPrice
				|						AND PackageServicesForAccommodationTemplate.Price <> 0))) AS MergedPackageServicesForAccommodationTemplate
				|
				|GROUP BY
				|	MergedPackageServicesForAccommodationTemplate.CalendarDayType,
				|	MergedPackageServicesForAccommodationTemplate.PriceTag,
				|	MergedPackageServicesForAccommodationTemplate.ClientType,
				|	MergedPackageServicesForAccommodationTemplate.RoomType,
				|	MergedPackageServicesForAccommodationTemplate.RoomTypeSortCode,
				|	MergedPackageServicesForAccommodationTemplate.AccommodationType,
				|	MergedPackageServicesForAccommodationTemplate.AccommodationTypeSortCode,
				|	MergedPackageServicesForAccommodationTemplate.Service,
				|	MergedPackageServicesForAccommodationTemplate.Unit,
				|	MergedPackageServicesForAccommodationTemplate.PricesService,
				|	MergedPackageServicesForAccommodationTemplate.Currency,
				|	MergedPackageServicesForAccommodationTemplate.VATRate,
				|	MergedPackageServicesForAccommodationTemplate.QuantityCalculationRule,
				|	MergedPackageServicesForAccommodationTemplate.IsRoomRevenue,
				|	MergedPackageServicesForAccommodationTemplate.IsInPrice,
				|	MergedPackageServicesForAccommodationTemplate.IsServicePerPerson,
				|	MergedPackageServicesForAccommodationTemplate.RoomRevenueAmountsOnly,
				|	MergedPackageServicesForAccommodationTemplate.AccountingDate,
				|	MergedPackageServicesForAccommodationTemplate.AccountingDayNumber,
				|	MergedPackageServicesForAccommodationTemplate.Remarks,
				|	MergedPackageServicesForAccommodationTemplate.ServicePackage,
				|	MergedPackageServicesForAccommodationTemplate.ServicePackageDateValidFrom,
				|	MergedPackageServicesForAccommodationTemplate.ServicePackageDateValidTo,
				|	MergedPackageServicesForAccommodationTemplate.ServicePackagePeriodFrom,
				|	MergedPackageServicesForAccommodationTemplate.ServicePackagePeriodTo,
				|	MergedPackageServicesForAccommodationTemplate.PacketPriceIsIncludedInRoomRate,
				|	MergedPackageServicesForAccommodationTemplate.ServicePackageUsageType,
				|	MergedPackageServicesForAccommodationTemplate.ServicePackageDateFrom,
				|	MergedPackageServicesForAccommodationTemplate.ServicePackageDateTo,
				|	MergedPackageServicesForAccommodationTemplate.Price,
				|	MergedPackageServicesForAccommodationTemplate.Service.IsRoomRevenue,
				|	MergedPackageServicesForAccommodationTemplate.ServicePackage.IsMealBoardTerm,
				|	MergedPackageServicesForAccommodationTemplate.Service.RoomRevenueAmountsOnly
				|
				|UNION ALL
				|
				|SELECT
				|	&qEmptySetRoomRatePricesRef,
				|	&qHotel,
				|	&qRoomRate,
				|	MergedPackageServicesForAccommodationType.CalendarDayType,
				|	MergedPackageServicesForAccommodationType.PriceTag,
				|	MergedPackageServicesForAccommodationType.ClientType,
				|	MergedPackageServicesForAccommodationType.RoomType,
				|	MergedPackageServicesForAccommodationType.RoomTypeSortCode,
				|	&qAccommodationType,
				|	&qAccommodationTypeSortCode,
				|	&qEmptySetRoomRatePricesRef,
				|	MergedPackageServicesForAccommodationType.Service,
				|	MergedPackageServicesForAccommodationType.Unit,
				|	MergedPackageServicesForAccommodationType.PricesService,
				|	MergedPackageServicesForAccommodationType.Currency,
				|	0,
				|	MergedPackageServicesForAccommodationType.VATRate,
				|	MergedPackageServicesForAccommodationType.QuantityCalculationRule,
				|	MergedPackageServicesForAccommodationType.IsRoomRevenue,
				|	MergedPackageServicesForAccommodationType.IsInPrice,
				|	MergedPackageServicesForAccommodationType.IsServicePerPerson,
				|	MergedPackageServicesForAccommodationType.RoomRevenueAmountsOnly,
				|	MergedPackageServicesForAccommodationType.AccountingDate,
				|	MergedPackageServicesForAccommodationType.AccountingDayNumber,
				|	MergedPackageServicesForAccommodationType.Remarks,
				|	MergedPackageServicesForAccommodationType.ServicePackage,
				|	MergedPackageServicesForAccommodationType.ServicePackageDateValidFrom,
				|	MergedPackageServicesForAccommodationType.ServicePackageDateValidTo,
				|	MergedPackageServicesForAccommodationType.ServicePackagePeriodFrom,
				|	MergedPackageServicesForAccommodationType.ServicePackagePeriodTo,
				|	NULL,
				|	MergedPackageServicesForAccommodationType.PacketPriceIsIncludedInRoomRate,
				|	MergedPackageServicesForAccommodationType.ServicePackageUsageType,
				|	MergedPackageServicesForAccommodationType.ServicePackageDateFrom,
				|	MergedPackageServicesForAccommodationType.ServicePackageDateTo,
				|	MIN(MergedPackageServicesForAccommodationType.RowNumber),
				|	999999999,
				|	MergedPackageServicesForAccommodationType.Price,
				|	SUM(MergedPackageServicesForAccommodationType.Quantity),
				|	SUM(MergedPackageServicesForAccommodationType.NumberOfPersons),
				|	SUM(MergedPackageServicesForAccommodationType.NumberOfPersonsInRoom),
				|	SUM(MergedPackageServicesForAccommodationType.NumberOfRooms),
				|	SUM(MergedPackageServicesForAccommodationType.NumberOfBeds),
				|	SUM(MergedPackageServicesForAccommodationType.NumberOfAdditionalBeds)
				|FROM
				|	(SELECT
				|		PackageServicesForAccommodationType.CalendarDayType AS CalendarDayType,
				|		ActivePriceTagsList.PriceTag AS PriceTag,
				|		PackageServicesForAccommodationType.ClientType AS ClientType,
				|		PackageServicesForAccommodationType.RoomType AS RoomType,
				|		ISNULL(PackageServicesForAccommodationType.RoomType.SortCode, 0) AS RoomTypeSortCode,
				|		CASE
				|			WHEN RoomRateFormulas.ReplaceWithService.Code IS NULL
				|				THEN PackageServicesForAccommodationType.Service
				|			ELSE RoomRateFormulas.ReplaceWithService
				|		END AS Service,
				|		CASE
				|			WHEN RoomRateFormulas.ReplaceWithService.Code IS NULL
				|				THEN PackageServicesForAccommodationType.Unit
				|			ELSE RoomRateFormulas.ReplaceWithService.Unit
				|		END AS Unit,
				|		PackageServicesForAccommodationType.Service AS PricesService,
				|		PackageServicesForAccommodationType.Currency AS Currency,
				|		PackageServicesForAccommodationType.VATRate AS VATRate,
				|		PackageServicesForAccommodationType.QuantityCalculationRule AS QuantityCalculationRule,
				|		CASE
				|			WHEN ISNULL(ServicePackages.IsMealBoardTerm, FALSE)
				|				THEN FALSE
				|			ELSE ISNULL(PackageServicesForAccommodationType.Service.IsRoomRevenue, FALSE)
				|		END AS IsRoomRevenue,
				|		PackageServicesForAccommodationType.IsInPrice AS IsInPrice,
				|		PackageServicesForAccommodationType.IsServicePerPerson AS IsServicePerPerson,
				|		ISNULL(PackageServicesForAccommodationType.Service.RoomRevenueAmountsOnly, FALSE) AS RoomRevenueAmountsOnly,
				|		PackageServicesForAccommodationType.AccountingDate AS AccountingDate,
				|		PackageServicesForAccommodationType.AccountingDayNumber AS AccountingDayNumber,
				|		CAST(PackageServicesForAccommodationType.Remarks AS STRING(100)) AS Remarks,
				|		PackageServicesForAccommodationType.ServicePackage AS ServicePackage,
				|		ISNULL(ServicePackages.DateValidFrom, &qEmptyDate) AS ServicePackageDateValidFrom,
				|		ISNULL(ServicePackages.DateValidTo, &qEmptyDate) AS ServicePackageDateValidTo,
				|		ISNULL(PackageServicesForAccommodationType.PeriodFrom, &qEmptyDate) AS ServicePackagePeriodFrom,
				|		ISNULL(PackageServicesForAccommodationType.PeriodTo, &qEmptyDate) AS ServicePackagePeriodTo,
				|		ISNULL(ServicePackages.PacketPriceIsIncludedInRoomRate, FALSE) AS PacketPriceIsIncludedInRoomRate,
				|		ServicePackages.UsageType AS ServicePackageUsageType,
				|		ServicePackages.DateFrom AS ServicePackageDateFrom,
				|		ServicePackages.DateTo AS ServicePackageDateTo,
				|		PackageServicesForAccommodationType.RowNumber AS RowNumber,
				|		(PackageServicesForAccommodationType.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0) AS Price,
				|		PackageServicesForAccommodationType.Quantity * ServicePackages.Quantity AS Quantity,
				|		CASE
				|			WHEN ISNULL(PackageServicesForAccommodationType.AccommodationType.NumberOfPersons4Reservation, 0) > 0
				|					AND PackageServicesForAccommodationType.IsServicePerPerson
				|				THEN ISNULL(PackageServicesForAccommodationType.AccommodationType.NumberOfPersons4Reservation, 0)
				|			WHEN ISNULL(PackageServicesForAccommodationType.AccommodationType.NumberOfPersons, 0) > 0
				|				THEN ISNULL(PackageServicesForAccommodationType.AccommodationType.NumberOfPersons, 0)
				|			ELSE 1
				|		END AS NumberOfPersons,
				|		CASE
				|			WHEN ISNULL(PackageServicesForAccommodationType.Service.IsRoomRevenue, FALSE)
				|					AND NOT ISNULL(ServicePackages.IsMealBoardTerm, FALSE)
				|					AND NOT ISNULL(PackageServicesForAccommodationType.Service.RoomRevenueAmountsOnly, FALSE)
				|				THEN CASE
				|						WHEN ISNULL(PackageServicesForAccommodationType.AccommodationType.NumberOfPersons4Reservation, 0) > 0
				|								AND PackageServicesForAccommodationType.IsServicePerPerson
				|							THEN ISNULL(PackageServicesForAccommodationType.AccommodationType.NumberOfPersons4Reservation, 0)
				|						WHEN ISNULL(PackageServicesForAccommodationType.AccommodationType.NumberOfPersons, 0) > 0
				|							THEN ISNULL(PackageServicesForAccommodationType.AccommodationType.NumberOfPersons, 0)
				|						ELSE 1
				|					END
				|			ELSE 0
				|		END AS NumberOfPersonsInRoom,
				|		CASE
				|			WHEN ISNULL(PackageServicesForAccommodationType.Service.IsRoomRevenue, FALSE)
				|					AND NOT ISNULL(ServicePackages.IsMealBoardTerm, FALSE)
				|					AND NOT ISNULL(PackageServicesForAccommodationType.Service.RoomRevenueAmountsOnly, FALSE)
				|				THEN ISNULL(PackageServicesForAccommodationType.AccommodationType.NumberOfRooms, 0)
				|			ELSE 0
				|		END AS NumberOfRooms,
				|		CASE
				|			WHEN ISNULL(PackageServicesForAccommodationType.Service.IsRoomRevenue, FALSE)
				|					AND NOT ISNULL(ServicePackages.IsMealBoardTerm, FALSE)
				|					AND NOT ISNULL(PackageServicesForAccommodationType.Service.RoomRevenueAmountsOnly, FALSE)
				|				THEN ISNULL(PackageServicesForAccommodationType.AccommodationType.NumberOfBeds, 0)
				|			ELSE 0
				|		END AS NumberOfBeds,
				|		CASE
				|			WHEN ISNULL(PackageServicesForAccommodationType.Service.IsRoomRevenue, FALSE)
				|					AND NOT ISNULL(ServicePackages.IsMealBoardTerm, FALSE)
				|					AND NOT ISNULL(PackageServicesForAccommodationType.Service.RoomRevenueAmountsOnly, FALSE)
				|				THEN ISNULL(PackageServicesForAccommodationType.AccommodationType.NumberOfAdditionalBeds, 0)
				|			ELSE 0
				|		END AS NumberOfAdditionalBeds,
				|		RoomRateFormulas.BracketsConstant AS BracketsConstant,
				|		RoomRateFormulas.Constant AS Constant,
				|		RoomRateFormulas.Multiplier AS Multiplier
				|	FROM
				|		InformationRegister.ServicePackageRecords AS PackageServicesForAccommodationType
				|			INNER JOIN ServicePackages AS ServicePackages
				|			ON PackageServicesForAccommodationType.ServicePackage = ServicePackages.ServicePackage
				|			INNER JOIN ServicePackagesActivePeriods AS ServicePackagesActivePeriods
				|			ON PackageServicesForAccommodationType.ServicePackage = ServicePackagesActivePeriods.ServicePackage
				|				AND PackageServicesForAccommodationType.Period = ServicePackagesActivePeriods.ActivePeriod
				|			LEFT JOIN ActivePriceTags AS ActivePriceTagsList
				|			ON (TRUE)
				|			LEFT JOIN RoomRateFormulas AS RoomRateFormulas
				|			ON (RoomRateFormulas.RoomRate = &qRoomRate)
				|				AND (RoomRateFormulas.Hotel = &qHotel)
				|				AND (RoomRateFormulas.IsFormula)
				|				AND PackageServicesForAccommodationType.Service = RoomRateFormulas.Service
				|				AND PackageServicesForAccommodationType.RoomType = RoomRateFormulas.RoomType
				|				AND PackageServicesForAccommodationType.ClientType = RoomRateFormulas.ClientType
				|				AND (PackageServicesForAccommodationType.AccommodationType = RoomRateFormulas.AccommodationType
				|					OR PackageServicesForAccommodationType.AccommodationType = VALUE(Catalog.AccommodationTypes.EmptyRef))
				|				AND (PackageServicesForAccommodationType.CalendarDayType = RoomRateFormulas.CalendarDayType
				|					OR RoomRateFormulas.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef))
				|	WHERE
				|		ServicePackages.DateValidFrom <= &qCheckInDate
				|		AND (ENDOFPERIOD(ServicePackages.DateValidTo, DAY) >= &qCheckInDate
				|				OR ServicePackages.DateValidTo = &qEmptyDate)
				|		AND PackageServicesForAccommodationType.ClientType = &qClientType
				|		AND (PackageServicesForAccommodationType.RoomType = &qRoomType
				|				OR PackageServicesForAccommodationType.RoomType = &qEmptyRoomTypeRef
				|				OR &qRoomTypeIsUndefined)
				|		AND (PackageServicesForAccommodationType.RoomClass = &qRoomClass
				|				OR PackageServicesForAccommodationType.RoomClass = &qEmptyRoomClassRef
				|				OR &qRoomTypeIsUndefined)
				|		AND (NOT &qAccommodationPeriodIsSet
				|				OR &qAccommodationPeriodIsSet
				|					AND (PackageServicesForAccommodationType.CalendarDayType IN (&qCalendarDayTypesList)
				|						OR PackageServicesForAccommodationType.CalendarDayType = &qEmptyCalendarDayType))
				|		AND PackageServicesForAccommodationType.AccommodationType = &qAccommodationType
				|		AND &qAccommodationTypeIsFilled
				|		AND NOT PackageServicesForAccommodationType.AccommodationType IN
				|					(SELECT DISTINCT
				|						TemplateAccommodationTypes.AccommodationType
				|					FROM
				|						TemplateAccommodationTypes AS TemplateAccommodationTypes
				|					WHERE
				|						TemplateAccommodationTypes.AccommodationTemplate = &qAccommodationTemplate)
				|		AND PackageServicesForAccommodationType.Service IS NOT NULL 
				|		AND PackageServicesForAccommodationType.Service <> &qEmptyService
				|		AND (NOT &qMinimizeOutput
				|				OR &qMinimizeOutput
				|					AND (PackageServicesForAccommodationType.IsInPrice
				|						AND PackageServicesForAccommodationType.Price <> 0))) AS MergedPackageServicesForAccommodationType
				|
				|GROUP BY
				|	MergedPackageServicesForAccommodationType.CalendarDayType,
				|	MergedPackageServicesForAccommodationType.PriceTag,
				|	MergedPackageServicesForAccommodationType.ClientType,
				|	MergedPackageServicesForAccommodationType.RoomType,
				|	MergedPackageServicesForAccommodationType.RoomTypeSortCode,
				|	MergedPackageServicesForAccommodationType.Service,
				|	MergedPackageServicesForAccommodationType.Unit,
				|	MergedPackageServicesForAccommodationType.PricesService,
				|	MergedPackageServicesForAccommodationType.Currency,
				|	MergedPackageServicesForAccommodationType.VATRate,
				|	MergedPackageServicesForAccommodationType.QuantityCalculationRule,
				|	MergedPackageServicesForAccommodationType.IsRoomRevenue,
				|	MergedPackageServicesForAccommodationType.IsInPrice,
				|	MergedPackageServicesForAccommodationType.IsServicePerPerson,
				|	MergedPackageServicesForAccommodationType.RoomRevenueAmountsOnly,
				|	MergedPackageServicesForAccommodationType.AccountingDate,
				|	MergedPackageServicesForAccommodationType.AccountingDayNumber,
				|	MergedPackageServicesForAccommodationType.Remarks,
				|	MergedPackageServicesForAccommodationType.ServicePackage,
				|	MergedPackageServicesForAccommodationType.ServicePackageDateValidFrom,
				|	MergedPackageServicesForAccommodationType.ServicePackageDateValidTo,
				|	MergedPackageServicesForAccommodationType.ServicePackagePeriodFrom,
				|	MergedPackageServicesForAccommodationType.ServicePackagePeriodTo,
				|	MergedPackageServicesForAccommodationType.PacketPriceIsIncludedInRoomRate,
				|	MergedPackageServicesForAccommodationType.ServicePackageUsageType,
				|	MergedPackageServicesForAccommodationType.ServicePackageDateFrom,
				|	MergedPackageServicesForAccommodationType.ServicePackageDateTo,
				|	MergedPackageServicesForAccommodationType.Price
				|ORDER BY " + 
				?(pSortByPointInTime, "PointInTime DESC, ", "") + "
				|	SortCode,
				|	LineNumber";
				vQry.SetParameter("qAccommodationService", pRoomRate.AccommodationService);
				vQry.SetParameter("qLateCheckOutService", pRoomRate.LateCheckOutService);
				vQry.SetParameter("qEarlyCheckInService", pRoomRate.EarlyCheckInService);
				vQry.SetParameter("qCalendar", pRoomRate.Calendar);
				vQry.SetParameter("qOrders", vOrders);
				vQry.SetParameter("qServicePackages", vServicePackages);
				vQry.SetParameter("qCalendarDayTypesList", vDayTypesList);
				vQry.SetParameter("qHotel", vHotel);
				vQry.SetParameter("qDefaultVATRate", vHotel.Company.VATRate);
				vQry.SetParameter("qRoomRate", pRoomRate);
				vQry.SetParameter("qPricesRoomRate", ?(ValueIsFilled(pRoomRate.BasedOnRoomRate), pRoomRate.BasedOnRoomRate, pRoomRate));
				vQry.SetParameter("qPriceTagType", pRoomRate.PriceTagType);
				vQry.SetParameter("qPriceTag", ?(pPriceTag = Undefined, Catalogs.PriceTags.EmptyRef(), pPriceTag));
				vQry.SetParameter("qPriceTagIsFilled", ?(pPriceTag = Undefined, False, True));
				vQry.SetParameter("qClientType", pClientType);
				vQry.SetParameter("qRoomType", pRoomType);
				vQry.SetParameter("qEmptyRoomTypeRef", Catalogs.RoomTypes.EmptyRef());
				vQry.SetParameter("qRoomTypeIsUndefined", ?(pRoomType = Undefined, True, False));
				vQry.SetParameter("qRoomClass", ?(ValueIsFilled(pRoomType) And Not pRoomType.IsFolder, pRoomType.RoomClass, Catalogs.RoomTypeClasses.EmptyRef()));
				vQry.SetParameter("qEmptyRoomClassRef", Catalogs.RoomTypeClasses.EmptyRef());
				vQry.SetParameter("qAccommodationTemplate", pAccommodationTemplate);
				vQry.SetParameter("qAccommodationType", pAccommodationType);
				vQry.SetParameter("qAccommodationTypeIsFilled", ValueIsFilled(pAccommodationType));
				vQry.SetParameter("qAccommodationTypeSortCode", ?(ValueIsFilled(pAccommodationType), pAccommodationType.SortCode, 999999999));
				vQry.SetParameter("qEmptyAccommodationTypeRef", Catalogs.AccommodationTypes.EmptyRef());
				vQry.SetParameter("qAccommodationTypeIsUndefined", ?(pAccommodationType = Undefined, True, False));
				vQry.SetParameter("qEmptySetRoomRatePricesRef", Documents.SetRoomRatePrices.EmptyRef());
				vQry.SetParameter("qDate", ?(ValueIsFilled(vPriceCalculationDate), vPriceCalculationDate, pDate));
				vQry.SetParameter("qCheckInDate", ?(ValueIsFilled(pCheckInDate), BegOfDay(pCheckInDate), BegOfDay(pDate)));
				vQry.SetParameter("qCheckOutDate", ?(ValueIsFilled(pCheckOutDate), BegOfDay(pCheckOutDate), BegOfDay(pDate)));
				vQry.SetParameter("qAccommodationPeriodIsSet", vAccommodationPeriodIsSet);
				vQry.SetParameter("qMinimizeOutput", pMinimizeOutput);
				vQry.SetParameter("qEmptyDate", '00010101');
				vQry.SetParameter("qEndOfTime", '39991231');
				vQry.SetParameter("qEmptyString", "");
				vQry.SetParameter("qEmptyService", Catalogs.Services.EmptyRef());
				vQry.SetParameter("qSplitPackagesByGuests", vSplitPackagesByGuests);
				If ValueIsFilled(pAccommodationTemplate) And ValueIsFilled(pAccommodationType) Then
					vAccommodationTemplateAccommodationTypesRow = pAccommodationTemplate.AccommodationTypes.Find(pAccommodationType, "AccommodationType");
					If vAccommodationTemplateAccommodationTypesRow <> Undefined Then
						vQry.SetParameter("qAccommodationTypeLineNumber", vAccommodationTemplateAccommodationTypesRow.LineNumber);
					Else
						vQry.SetParameter("qAccommodationTypeLineNumber", 0);
					EndIf;
				Else
					vQry.SetParameter("qAccommodationTypeLineNumber", 0);
				EndIf;
				vQry.SetParameter("qEmptyCalendarDayType", Catalogs.CalendarDayTypes.EmptyRef());
				If vDayTypes.Count() > 0 Then
					For i = 0 To (vDayTypes.Count() - 1) Do
						vDayTypesRow = vDayTypes.Get(i);
						vQry.SetParameter("qCalendarDayType" + Format(i, "NFD=0; NZ=; NG="), vDayTypesRow.CalendarDayType);
					EndDo;
				EndIf;
				vQry.Text = StrReplace(vQry.Text, "&qFilterByCalendarDayTypes", vFilterByCalendarDayTypes);
				vPrices = vQry.Execute().Unload();
			Else
				vQry = New Query;
				vQry.Text = 
				"SELECT
				|	ServicePackages.ServicePackage AS ServicePackage,
				|	ServicePackages.Quantity AS Quantity,
				|	ServicePackages.DateFrom AS DateFrom,
				|	ServicePackages.DateTo AS DateTo,
				|	ServicePackages.PacketPriceIsIncludedInRoomRate AS PacketPriceIsIncludedInRoomRate,
				|	ServicePackages.IsExtraPackage AS IsExtraPackage,
				|	ServicePackages.IsMealBoardTerm AS IsMealBoardTerm,
				|	ServicePackages.IsPerPerson AS IsPerPerson,
				|	ServicePackages.UsageType AS UsageType,
				|	ServicePackages.DateValidFrom AS DateValidFrom,
				|	ServicePackages.DateValidTo AS DateValidTo
				|INTO ServicePackages
				|FROM
				|	&qServicePackages AS ServicePackages
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	ServicePackagePeriods.ServicePackage AS ServicePackage,
				|	MAX(ServicePackagePeriods.Period) AS ActivePeriod
				|INTO ServicePackagesActivePeriods
				|FROM
				|	InformationRegister.ServicePackageRecords.SliceLast(&qDate, ) AS ServicePackagePeriods
				|		INNER JOIN ServicePackages AS ServicePackages
				|		ON (ServicePackages.ServicePackage = ServicePackagePeriods.ServicePackage)
				|
				|GROUP BY
				|	ServicePackagePeriods.ServicePackage
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	Orders.CalendarDayType AS CalendarDayType,
				|	Orders.PriceTag AS PriceTag,
				|	Orders.SetRoomRatePrices AS SetRoomRatePrices
				|INTO Orders
				|FROM
				|	&qOrders AS Orders
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	RoomRatesSliceLast.SetRoomRateFormulas AS Recorder,
				|	RoomRatesSliceLast.RoomRate AS RoomRate
				|INTO ActiveSetRoomRateFormulas
				|FROM
				|	InformationRegister.RoomRates.SliceLast(
				|			&qDate,
				|			RoomRate = &qRoomRate
				|				AND Hotel = &qHotel
				|				AND IsFormula) AS RoomRatesSliceLast
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	RoomRateFormulas.RoomRate.BasedOnRoomRate AS BasedOnRoomRate,
				|	RoomRateFormulas.RoomRate.BasedOnPriceTag AS BasedOnPriceTag,
				|	RoomRateFormulas.RoomRate AS RoomRate,
				|	RoomRateFormulas.Hotel AS Hotel,
				|	RoomRateFormulas.IsFormula AS IsFormula,
				|	RoomRateFormulas.Service AS Service,
				|	RoomRateFormulas.RoomType AS RoomType,
				|	RoomRateFormulas.AccommodationType AS AccommodationType,
				|	RoomRateFormulas.ClientType AS ClientType,
				|	RoomRateFormulas.CalendarDayType AS CalendarDayType,
				|	RoomRateFormulas.Recorder AS Recorder,
				|	RoomRateFormulas.Period AS Period,
				|	RoomRateFormulas.BracketsConstant AS BracketsConstant,
				|	RoomRateFormulas.Constant AS Constant,
				|	RoomRateFormulas.Multiplier AS Multiplier,
				|	RoomRateFormulas.ReplaceWithService AS ReplaceWithService
				|INTO RoomRateFormulas
				|FROM
				|	InformationRegister.RoomRateFormulas AS RoomRateFormulas
				|		INNER JOIN ActiveSetRoomRateFormulas AS ActiveSetRoomRateFormulas
				|		ON RoomRateFormulas.Recorder = ActiveSetRoomRateFormulas.Recorder
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT DISTINCT
				|	ActivePriceTags.PriceTag AS PriceTag
				|INTO ActivePriceTags
				|FROM
				|	InformationRegister.RoomRatePrices AS ActivePriceTags
				|		INNER JOIN Orders AS Orders
				|		ON ActivePriceTags.SetRoomRatePrices = Orders.SetRoomRatePrices
				|			AND ActivePriceTags.CalendarDayType = Orders.CalendarDayType
				|			AND ActivePriceTags.PriceTag = Orders.PriceTag
				|WHERE
				|	ActivePriceTags.RoomRate = &qPricesRoomRate
				|	AND ActivePriceTags.ClientType = &qClientType
				|	AND (&qPriceTagIsFilled
				|				AND ActivePriceTags.PriceTag = &qPriceTag
				|			OR NOT &qPriceTagIsFilled)
				|	AND (ActivePriceTags.RoomType = &qRoomType
				|			OR ActivePriceTags.RoomType = &qEmptyRoomTypeRef
				|			OR &qRoomTypeIsUndefined)
				|	AND (ActivePriceTags.AccommodationType = &qAccommodationType
				|			OR ActivePriceTags.AccommodationType = &qEmptyAccommodationTypeRef
				|			OR &qAccommodationTypeIsUndefined)
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	RoomRatePrices.Recorder AS Recorder,
				|	RoomRatePrices.Hotel AS Hotel,
				|	RoomRatePrices.RoomRate AS RoomRate,
				|	RoomRatePrices.CalendarDayType AS CalendarDayType,
				|	RoomRatePrices.PriceTag AS PriceTag,
				|	RoomRatePrices.ClientType AS ClientType,
				|	RoomRatePrices.RoomType AS RoomType,
				|	RoomRatePrices.RoomType.SortCode AS RoomTypeSortCode,
				|	RoomRatePrices.AccommodationType AS AccommodationType,
				|	RoomRatePrices.AccommodationType.SortCode AS AccommodationTypeSortCode,
				|	RoomRatePrices.SetRoomRatePrices AS SetRoomRatePrices,
				|	RoomRatePrices.SortCode AS SortCode,
				|	RoomRatePrices.Service AS Service,
				|	RoomRatePrices.Service.Unit AS Unit,
				|	RoomRatePrices.Service AS PricesService,
				|	RoomRatePrices.Currency AS Currency,
				|	RoomRatePrices.MinimumQuantity AS MinimumQuantity,
				|	RoomRatePrices.VATRate AS VATRate,
				|	RoomRatePrices.QuantityCalculationRule AS QuantityCalculationRule,
				|	RoomRatePrices.IsRoomRevenue AS IsRoomRevenue,
				|	RoomRatePrices.IsInPrice AS IsInPrice,
				|	RoomRatePrices.IsPricePerPerson AS IsPricePerPerson,
				|	RoomRatePrices.Service.RoomRevenueAmountsOnly AS RoomRevenueAmountsOnly,
				|	&qEmptyDate AS AccountingDate,
				|	0 AS AccountingDayNumber,
				|	&qEmptyString AS Remarks,
				|	NULL AS ServicePackage,
				|	&qEmptyDate AS ServicePackageDateValidFrom,
				|	&qEmptyDate AS ServicePackageDateValidTo,
				|	&qEmptyDate AS ServicePackagePeriodFrom,
				|	&qEmptyDate AS ServicePackagePeriodTo,
				|	RoomRatePrices.SetRoomRatePrices.PointInTime AS PointInTime,
				|	FALSE AS PacketPriceIsIncludedInRoomRate,
				|	UNDEFINED AS ServicePackageUsageType,
				|	&qEmptyDate AS ServicePackageDateFrom,
				|	&qEndOfTime AS ServicePackageDateTo,
				|	0 AS LineNumber,
				|	RoomRatePrices.Price AS Price,
				|	1 AS Quantity,
				|	CASE
				|		WHEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons4Reservation, 0) > 0
				|				AND RoomRatePrices.IsPricePerPerson
				|			THEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons4Reservation, 0)
				|		WHEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons, 0) > 0
				|			THEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons, 0)
				|		ELSE 1
				|	END AS NumberOfPersons,
				|	0 AS NumberOfPersonsInRoom,
				|	0 AS NumberOfRooms,
				|	0 AS NumberOfBeds,
				|	0 AS NumberOfAdditionalBeds
				|FROM
				|	InformationRegister.RoomRatePrices AS RoomRatePrices
				|WHERE
				|	FALSE
				|
				|UNION ALL
				|
				|SELECT
				|	&qEmptySetRoomRatePricesRef,
				|	&qHotel,
				|	&qRoomRate,
				|	PackageServicesForPriceTags.CalendarDayType,
				|	ActivePriceTagsList.PriceTag,
				|	PackageServicesForPriceTags.ClientType,
				|	PackageServicesForPriceTags.RoomType,
				|	0,
				|	&qAccommodationType,
				|	&qAccommodationTypeSortCode,
				|	&qEmptySetRoomRatePricesRef,
				|	0,
				|	CASE
				|		WHEN RoomRateFormulas.ReplaceWithService.Code IS NULL
				|			THEN PackageServicesForPriceTags.Service
				|		ELSE RoomRateFormulas.ReplaceWithService
				|	END,
				|	CASE
				|		WHEN RoomRateFormulas.ReplaceWithService.Code IS NULL
				|			THEN PackageServicesForPriceTags.Unit
				|		ELSE RoomRateFormulas.ReplaceWithService.Unit
				|	END,
				|	PackageServicesForPriceTags.Service,
				|	PackageServicesForPriceTags.Currency,
				|	0,
				|	PackageServicesForPriceTags.VATRate,
				|	PackageServicesForPriceTags.QuantityCalculationRule,
				|	CASE
				|		WHEN ISNULL(ServicePackages.IsMealBoardTerm, FALSE)
				|			THEN FALSE
				|		ELSE ISNULL(PackageServicesForPriceTags.Service.IsRoomRevenue, FALSE)
				|	END,
				|	PackageServicesForPriceTags.IsInPrice,
				|	PackageServicesForPriceTags.IsServicePerPerson,
				|	ISNULL(PackageServicesForPriceTags.Service.RoomRevenueAmountsOnly, FALSE),
				|	PackageServicesForPriceTags.AccountingDate,
				|	PackageServicesForPriceTags.AccountingDayNumber,
				|	CAST(PackageServicesForPriceTags.Remarks AS STRING(100)),
				|	PackageServicesForPriceTags.ServicePackage,
				|	ISNULL(ServicePackages.DateValidFrom, &qEmptyDate),
				|	ISNULL(ServicePackages.DateValidTo, &qEmptyDate),
				|	ISNULL(PackageServicesForPriceTags.PeriodFrom, &qEmptyDate),
				|	ISNULL(PackageServicesForPriceTags.PeriodTo, &qEmptyDate),
				|	NULL,
				|	FALSE,
				|	ServicePackages.UsageType,
				|	ServicePackages.DateFrom,
				|	ServicePackages.DateTo,
				|	MIN(PackageServicesForPriceTags.RowNumber),
				|	(PackageServicesForPriceTags.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0),
				|	SUM(PackageServicesForPriceTags.Quantity * ServicePackages.Quantity),
				|	SUM(CASE
				|			WHEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfPersons4Reservation, 0) > 0
				|					AND PackageServicesForPriceTags.IsServicePerPerson
				|				THEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfPersons4Reservation, 0)
				|			WHEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfPersons, 0) > 0
				|				THEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfPersons, 0)
				|			ELSE 1
				|		END),
				|	SUM(CASE
				|			WHEN ISNULL(PackageServicesForPriceTags.Service.IsRoomRevenue, FALSE)
				|					AND NOT ISNULL(ServicePackages.IsMealBoardTerm, FALSE)
				|				THEN CASE
				|						WHEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfPersons4Reservation, 0) > 0
				|								AND PackageServicesForPriceTags.IsServicePerPerson
				|							THEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfPersons4Reservation, 0)
				|						WHEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfPersons, 0) > 0
				|							THEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfPersons, 0)
				|						ELSE 1
				|					END
				|			ELSE 0
				|		END),
				|	SUM(CASE
				|			WHEN ISNULL(PackageServicesForPriceTags.Service.IsRoomRevenue, FALSE)
				|					AND NOT ISNULL(ServicePackages.IsMealBoardTerm, FALSE)
				|				THEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfRooms, 0)
				|			ELSE 0
				|		END),
				|	SUM(CASE
				|			WHEN ISNULL(PackageServicesForPriceTags.Service.IsRoomRevenue, FALSE)
				|					AND NOT ISNULL(ServicePackages.IsMealBoardTerm, FALSE)
				|				THEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfBeds, 0)
				|			ELSE 0
				|		END),
				|	SUM(CASE
				|			WHEN ISNULL(PackageServicesForPriceTags.Service.IsRoomRevenue, FALSE)
				|					AND NOT ISNULL(ServicePackages.IsMealBoardTerm, FALSE)
				|				THEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfAdditionalBeds, 0)
				|			ELSE 0
				|		END)
				|FROM
				|	InformationRegister.ServicePackageRecords AS PackageServicesForPriceTags
				|		INNER JOIN ServicePackages AS ServicePackages
				|		ON (ServicePackages.ServicePackage = PackageServicesForPriceTags.ServicePackage)
				|			AND (ServicePackages.IsExtraPackage)
				|		INNER JOIN ServicePackagesActivePeriods AS ServicePackagesActivePeriods
				|		ON PackageServicesForPriceTags.ServicePackage = ServicePackagesActivePeriods.ServicePackage
				|			AND PackageServicesForPriceTags.Period = ServicePackagesActivePeriods.ActivePeriod
				|		LEFT JOIN ActivePriceTags AS ActivePriceTagsList
				|		ON (TRUE)
				|		LEFT JOIN RoomRateFormulas AS RoomRateFormulas
				|		ON (RoomRateFormulas.RoomRate = &qRoomRate)
				|			AND (RoomRateFormulas.Hotel = &qHotel)
				|			AND (RoomRateFormulas.IsFormula)
				|			AND PackageServicesForPriceTags.Service = RoomRateFormulas.Service
				|			AND PackageServicesForPriceTags.RoomType = RoomRateFormulas.RoomType
				|			AND PackageServicesForPriceTags.ClientType = RoomRateFormulas.ClientType
				|			AND (PackageServicesForPriceTags.AccommodationType = RoomRateFormulas.AccommodationType
				|				OR PackageServicesForPriceTags.AccommodationType = VALUE(Catalog.AccommodationTypes.EmptyRef))
				|			AND (PackageServicesForPriceTags.CalendarDayType = RoomRateFormulas.CalendarDayType
				|				OR RoomRateFormulas.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef))
				|WHERE
				|	ServicePackages.DateValidFrom <= &qCheckInDate
				|	AND (ENDOFPERIOD(ServicePackages.DateValidTo, DAY) >= &qCheckInDate
				|			OR ServicePackages.DateValidTo = &qEmptyDate)
				|	AND PackageServicesForPriceTags.ClientType = &qClientType
				|	AND (PackageServicesForPriceTags.AccommodationType = &qAccommodationType
				|			OR PackageServicesForPriceTags.AccommodationType = &qEmptyAccommodationTypeRef
				|			OR &qAccommodationTypeIsUndefined)
				|	AND (PackageServicesForPriceTags.RoomType = &qRoomType
				|			OR PackageServicesForPriceTags.RoomType = &qEmptyRoomTypeRef
				|			OR &qRoomTypeIsUndefined)
				|	AND (PackageServicesForPriceTags.RoomClass = &qRoomClass
				|			OR PackageServicesForPriceTags.RoomClass = &qEmptyRoomClassRef
				|			OR &qRoomTypeIsUndefined)
				|	AND (NOT &qAccommodationPeriodIsSet
				|			OR &qAccommodationPeriodIsSet
				|				AND (PackageServicesForPriceTags.CalendarDayType IN (&qCalendarDayTypesList)
				|					OR PackageServicesForPriceTags.CalendarDayType = &qEmptyCalendarDayType))
				|	AND PackageServicesForPriceTags.Service IS NOT NULL 
				|	AND PackageServicesForPriceTags.Service <> &qEmptyService
				|	AND (NOT &qMinimizeOutput
				|			OR &qMinimizeOutput
				|				AND (PackageServicesForPriceTags.IsInPrice
				|					AND PackageServicesForPriceTags.Price <> 0))
				|
				|GROUP BY
				|	PackageServicesForPriceTags.CalendarDayType,
				|	PackageServicesForPriceTags.RowNumber,
				|	ActivePriceTagsList.PriceTag,
				|	PackageServicesForPriceTags.ClientType,
				|	PackageServicesForPriceTags.RoomType,
				|	CASE
				|		WHEN RoomRateFormulas.ReplaceWithService.Code IS NULL
				|			THEN PackageServicesForPriceTags.Service
				|		ELSE RoomRateFormulas.ReplaceWithService
				|	END,
				|	CASE
				|		WHEN RoomRateFormulas.ReplaceWithService.Code IS NULL
				|			THEN PackageServicesForPriceTags.Unit
				|		ELSE RoomRateFormulas.ReplaceWithService.Unit
				|	END,
				|	PackageServicesForPriceTags.Service,
				|	PackageServicesForPriceTags.Currency,
				|	PackageServicesForPriceTags.VATRate,
				|	PackageServicesForPriceTags.QuantityCalculationRule,
				|	CASE
				|		WHEN ISNULL(ServicePackages.IsMealBoardTerm, FALSE)
				|			THEN FALSE
				|		ELSE ISNULL(PackageServicesForPriceTags.Service.IsRoomRevenue, FALSE)
				|	END,
				|	PackageServicesForPriceTags.IsInPrice,
				|	PackageServicesForPriceTags.IsServicePerPerson,
				|	ISNULL(PackageServicesForPriceTags.Service.RoomRevenueAmountsOnly, FALSE),
				|	PackageServicesForPriceTags.AccountingDate,
				|	PackageServicesForPriceTags.AccountingDayNumber,
				|	CAST(PackageServicesForPriceTags.Remarks AS STRING(100)),
				|	PackageServicesForPriceTags.ServicePackage,
				|	ISNULL(ServicePackages.DateValidFrom, &qEmptyDate),
				|	ISNULL(ServicePackages.DateValidTo, &qEmptyDate),
				|	ISNULL(PackageServicesForPriceTags.PeriodFrom, &qEmptyDate),
				|	ISNULL(PackageServicesForPriceTags.PeriodTo, &qEmptyDate),
				|	ServicePackages.UsageType,
				|	ServicePackages.DateFrom,
				|	ServicePackages.DateTo,
				|	PackageServicesForPriceTags.Price,
				|	RoomRateFormulas.BracketsConstant,
				|	RoomRateFormulas.Constant,
				|	RoomRateFormulas.Multiplier
				|ORDER BY " + 
				?(pSortByPointInTime, "PointInTime DESC, ", "") + "
				|	SortCode,
				|	LineNumber";
				vQry.SetParameter("qOrders", vOrders);
				vQry.SetParameter("qServicePackages", vServicePackages);
				vQry.SetParameter("qCalendarDayTypesList", vDayTypesList);
				vQry.SetParameter("qHotel", vHotel);
				vQry.SetParameter("qRoomRate", pRoomRate);
				vQry.SetParameter("qPricesRoomRate", ?(ValueIsFilled(pRoomRate.BasedOnRoomRate), pRoomRate.BasedOnRoomRate, pRoomRate));
				vQry.SetParameter("qPriceTag", ?(pPriceTag = Undefined, Catalogs.PriceTags.EmptyRef(), pPriceTag));
				vQry.SetParameter("qPriceTagIsFilled", ?(pPriceTag = Undefined, False, True));
				vQry.SetParameter("qClientType", pClientType);
				vQry.SetParameter("qRoomType", pRoomType);
				vQry.SetParameter("qEmptyRoomTypeRef", Catalogs.RoomTypes.EmptyRef());
				vQry.SetParameter("qRoomTypeIsUndefined", ?(pRoomType = Undefined, True, False));
				vQry.SetParameter("qRoomClass", ?(ValueIsFilled(pRoomType) And Not pRoomType.IsFolder, pRoomType.RoomClass, Catalogs.RoomTypeClasses.EmptyRef()));
				vQry.SetParameter("qEmptyRoomClassRef", Catalogs.RoomTypeClasses.EmptyRef());
				vQry.SetParameter("qAccommodationType", pAccommodationType);
				vQry.SetParameter("qAccommodationTypeSortCode", ?(ValueIsFilled(pAccommodationType), pAccommodationType.SortCode, 999999999));
				vQry.SetParameter("qEmptyAccommodationTypeRef", Catalogs.AccommodationTypes.EmptyRef());
				vQry.SetParameter("qAccommodationTypeIsUndefined", ?(pAccommodationType = Undefined, True, False));
				vQry.SetParameter("qEmptySetRoomRatePricesRef", Documents.SetRoomRatePrices.EmptyRef());
				vQry.SetParameter("qDate", ?(ValueIsFilled(vPriceCalculationDate), vPriceCalculationDate, pDate));
				vQry.SetParameter("qCheckInDate", ?(ValueIsFilled(pCheckInDate), BegOfDay(pCheckInDate), BegOfDay(pDate)));
				vQry.SetParameter("qCheckOutDate", ?(ValueIsFilled(pCheckOutDate), BegOfDay(pCheckOutDate), BegOfDay(pDate)));
				vQry.SetParameter("qAccommodationPeriodIsSet", vAccommodationPeriodIsSet);
				vQry.SetParameter("qMinimizeOutput", pMinimizeOutput);
				vQry.SetParameter("qEmptyDate", '00010101');
				vQry.SetParameter("qEndOfTime", '39991231');
				vQry.SetParameter("qEmptyString", "");
				vQry.SetParameter("qEmptyService", Catalogs.Services.EmptyRef());
				vQry.SetParameter("qEmptyCalendarDayType", Catalogs.CalendarDayTypes.EmptyRef());
				vPrices = vQry.Execute().Unload();
			EndIf;
		Else
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	Orders.CalendarDayType AS CalendarDayType,
			|	Orders.PriceTag AS PriceTag,
			|	Orders.SetRoomRatePrices AS SetRoomRatePrices
			|INTO Orders
			|FROM
			|	&qOrders AS Orders
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	AccommodationTypeFormulas.Ref.RoomRate AS RoomRate,
			|	AccommodationTypeFormulas.Ref.Hotel AS Hotel,
			|	AccommodationTypeFormulas.Ref AS SetRoomRatePrices,
			|	Orders.CalendarDayType AS CalendarDayType,
			|	Orders.PriceTag AS PriceTag,
			|	AccommodationTypeFormulas.ClientType AS ClientType,
			|	AccommodationTypeFormulas.Service AS Service,
			|	AccommodationTypeFormulas.RoomClass AS RoomClass,
			|	AccommodationTypeFormulas.RoomType AS RoomType,
			|	AccommodationTypeFormulas.AccommodationType AS AccommodationType,
			|	AccommodationTypeFormulas.Multiplier AS Multiplier,
			|	AccommodationTypeFormulas.BracketsConstant AS BracketsConstant,
			|	AccommodationTypeFormulas.Constant AS Constant,
			|	AccommodationTypeFormulas.LineNumber AS LineNumber,
			|	AccommodationTypeFormulas.LineNumber AS SortCode
			|INTO RateAccommodationTypeFormulas
			|FROM
			|	Document.SetRoomRatePrices.Formulas AS AccommodationTypeFormulas
			|		INNER JOIN Orders AS Orders
			|		ON AccommodationTypeFormulas.Ref = Orders.SetRoomRatePrices
			|
			|INDEX BY
			|	AccommodationTypeFormulas.Service,
			|	AccommodationTypeFormulas.RoomType,
			|	AccommodationTypeFormulas.RoomClass
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT DISTINCT
			|	FormulasForPriceTags.Ref.RoomRate AS RoomRate,
			|	FormulasForPriceTags.Ref.Hotel AS Hotel,
			|	FormulasForPriceTags.Ref AS SetRoomRatePrices,
			|	FormulasForPriceTags.CalendarDayType AS CalendarDayType,
			|	FormulasForPriceTags.PriceTag AS PriceTag,
			|	FormulasForPriceTags.ClientType AS ClientType,
			|	FormulasForPriceTags.Service AS Service,
			|	FormulasForPriceTags.RoomClass AS RoomClass,
			|	FormulasForPriceTags.RoomType AS RoomType,
			|	FormulasForPriceTags.AccommodationType AS AccommodationType,
			|	FormulasForPriceTags.Discount AS Discount,
			|	FormulasForPriceTags.Multiplier AS Multiplier,
			|	FormulasForPriceTags.BracketsConstant AS BracketsConstant,
			|	FormulasForPriceTags.Constant AS Constant,
			|	FormulasForPriceTags.LineNumber AS LineNumber,
			|	FormulasForPriceTags.LineNumber AS SortCode
			|INTO FormulasForPriceTags
			|FROM
			|	Document.SetRoomRatePrices.FormulasForDayTypesAndPricetags AS FormulasForPriceTags
			|		INNER JOIN Orders AS Orders
			|		ON FormulasForPriceTags.Ref = Orders.SetRoomRatePrices
			|			AND FormulasForPriceTags.PriceTag = Orders.PriceTag
			|			AND FormulasForPriceTags.CalendarDayType = Orders.CalendarDayType
			|
			|INDEX BY
			|	FormulasForPriceTags.ClientType,
			|	FormulasForPriceTags.PriceTag,
			|	FormulasForPriceTags.CalendarDayType,
			|	FormulasForPriceTags.Service,
			|	FormulasForPriceTags.RoomType,
			|	FormulasForPriceTags.RoomClass,
			|	FormulasForPriceTags.AccommodationType
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT TOP 3
			|	RateServices.Ref AS Service,
			|	RateServices.QuantityCalculationRule AS QuantityCalculationRule,
			|	RateServices.QuantityCalculationRule.QuantityCalculationRuleType AS QuantityCalculationRuleType,
			|	RateServices.IsRoomRevenue AS IsRoomRevenue,
			|	RateServices.IsInPrice AS IsInPrice,
			|	RateServices.ChargePerPerson AS ChargePerPerson,
			|	RateServices.ChargeToEachGuestSeparately AS ChargeToEachGuestSeparately,
			|	RateServices.Unit AS Unit,
			|	RateServices.RoomRevenueAmountsOnly AS RoomRevenueAmountsOnly
			|INTO RateServices
			|FROM
			|	Catalog.Services AS RateServices
			|WHERE
			|	(RateServices.Ref = &qAccommodationService
			|			OR RateServices.Ref = &qLateCheckOutService
			|			OR RateServices.Ref = &qEarlyCheckInService)
			|	AND NOT RateServices.IsFolder
			|
			|ORDER BY
			|	RateServices.SortCode,
			|	RateServices.Code
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	CalendarDaysByRoomTypes.RoomType AS RoomType,
			|	CalendarDaysByRoomTypes.AccountingDate AS AccountingDate,
			|	CalendarDaysByRoomTypes.CalendarDayType AS CalendarDayType,
			|	CalendarDaysByRoomTypes.PriceTag AS PriceTag,
			|	CalendarDaysByRoomTypes.RoomPrice AS RoomPrice,
			|	CalendarDaysByRoomTypes.RoomPriceCurrency AS RoomPriceCurrency
			|INTO CalendarDaysByRoomTypes
			|FROM
			|	InformationRegister.CalendarDaysByRoomTypes.SliceLast(
			|			&qDate,
			|			AccountingDate BETWEEN &qCheckInDate AND &qCheckOutDate 
			|				AND Calendar = &qCalendar
			|				AND Hotel = &qHotel
			|				AND (RoomType = &qRoomType OR &qRoomTypeIsUndefined)) AS CalendarDaysByRoomTypes
			|WHERE
			|	(CalendarDaysByRoomTypes.CalendarDayType <> VALUE(Catalog.CalendarDayTypes.EmptyRef)
			|			OR CalendarDaysByRoomTypes.PriceTag <> VALUE(Catalog.PriceTags.EmptyRef)
			|			OR CalendarDaysByRoomTypes.RoomPrice <> 0)
			|
			|INDEX BY
			|	CalendarDaysByRoomTypes.AccountingDate,
			|	CalendarDaysByRoomTypes.RoomType
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	RateServices.Service AS Service,
			|	RateServices.QuantityCalculationRule AS QuantityCalculationRule,
			|	RateServices.QuantityCalculationRuleType AS QuantityCalculationRuleType,
			|	RateServices.IsRoomRevenue AS IsRoomRevenue,
			|	RateServices.IsInPrice AS IsInPrice,
			|	RateServices.ChargePerPerson AS ChargePerPerson,
			|	RateServices.ChargeToEachGuestSeparately AS ChargeToEachGuestSeparately,
			|	RateServices.Unit AS Unit,
			|	RateServices.RoomRevenueAmountsOnly AS RoomRevenueAmountsOnly,
			|	RoomTypePricesByDates.RoomType AS RoomType,
			|	RoomTypePricesByDates.RoomType.RoomClass AS RoomTypeRoomClass,
			|	RoomTypePricesByDates.AccountingDate AS AccountingDate,
			|	RoomTypePricesByDates.CalendarDayType AS CalendarDayType,
			|	RoomTypePricesByDates.PriceTag AS PriceTag,
			|	RoomTypePricesByDates.RoomPrice AS Price,
			|	RoomTypePricesByDates.RoomPriceCurrency AS Currency
			|INTO RoomTypePricesByDates
			|FROM
			|	(SELECT DISTINCT
			|		DaysByRoomTypes.RoomType AS RoomType,
			|		DaysByRoomTypes.AccountingDate AS AccountingDate,
			|		DaysByRoomTypes.CalendarDayType AS CalendarDayType,
			|		DaysByRoomTypes.PriceTag AS PriceTag,
			|		DaysByRoomTypes.RoomPrice AS RoomPrice,
			|		DaysByRoomTypes.RoomPriceCurrency AS RoomPriceCurrency
			|	FROM
			|		(SELECT
			|			RoomTypes.Ref AS RoomType,
			|			CalendarDays.AccountingDate AS AccountingDate,
			|			CASE
			|				WHEN CalendarDaysByRoomTypes.CalendarDayType IS NULL
			|					THEN CalendarDays.CalendarDayType
			|				WHEN CalendarDaysByRoomTypes.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef)
			|					THEN CalendarDays.CalendarDayType
			|				ELSE CalendarDaysByRoomTypes.CalendarDayType
			|			END AS CalendarDayType,
			|			CASE
			|				WHEN CalendarDaysByRoomTypes.PriceTag IS NULL
			|					THEN CalendarDays.PriceTag
			|				WHEN CalendarDaysByRoomTypes.PriceTag = VALUE(Catalog.PriceTags.EmptyRef)
			|					THEN CalendarDays.PriceTag
			|				ELSE CalendarDaysByRoomTypes.PriceTag
			|			END AS PriceTag,
			|			CASE
			|				WHEN CalendarDaysByRoomTypes.RoomPrice IS NULL
			|					THEN CalendarDays.RoomPrice
			|				WHEN CalendarDaysByRoomTypes.RoomPrice = 0
			|					THEN CalendarDays.RoomPrice
			|				ELSE CalendarDaysByRoomTypes.RoomPrice
			|			END AS RoomPrice,
			|			CASE
			|				WHEN CalendarDaysByRoomTypes.RoomPriceCurrency IS NULL
			|					THEN CalendarDays.RoomPriceCurrency
			|				WHEN CalendarDaysByRoomTypes.RoomPriceCurrency = VALUE(Catalog.Currencies.EmptyRef)
			|					THEN CalendarDays.RoomPriceCurrency
			|				ELSE CalendarDaysByRoomTypes.RoomPriceCurrency
			|			END AS RoomPriceCurrency
			|		FROM
			|			InformationRegister.CalendarDays.SliceLast(
			|					&qDate,
			|					AccountingDate BETWEEN &qCheckInDate AND &qCheckOutDate
			|					AND Calendar = &qCalendar) AS CalendarDays
			|				LEFT JOIN Catalog.RoomTypes AS RoomTypes
			|				ON (RoomTypes.Owner = &qHotel)
			|					AND (NOT RoomTypes.IsFolder)
			|					AND (RoomTypes.Ref = &qRoomType
			|						OR &qRoomTypeIsUndefined)
			|				LEFT JOIN CalendarDaysByRoomTypes AS CalendarDaysByRoomTypes
			|				ON CalendarDays.AccountingDate = CalendarDaysByRoomTypes.AccountingDate
			|					AND (RoomTypes.Ref = CalendarDaysByRoomTypes.RoomType)) AS DaysByRoomTypes) AS RoomTypePricesByDates
			|		LEFT JOIN RateServices AS RateServices
			|		ON (TRUE)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	ServicePrices.Service AS Service,
			|	ServicePrices.ClientType AS ClientType,
			|	ServicePrices.VATRate AS VATRate
			|INTO ServicePrices
			|FROM
			|	InformationRegister.ServicePrices.SliceLast(
			|			&qDate,
			|			(Service = &qAccommodationService
			|				OR Service = &qLateCheckOutService
			|				OR Service = &qEarlyCheckInService)
			|				AND Hotel = &qHotel) AS ServicePrices
			|
			|INDEX BY
			|	ServicePrices.Service,
			|	ServicePrices.ClientType
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	RawRoomRatePrices.AccountingDate AS AccountingDate,
			|	RawRoomRatePrices.RoomRate AS RoomRate,
			|	RawRoomRatePrices.CalendarDayType AS CalendarDayType,
			|	RawRoomRatePrices.PriceTag AS PriceTag,
			|	RawRoomRatePrices.ClientType AS ClientType,
			|	RawRoomRatePrices.RoomType AS RoomType,
			|	RawRoomRatePrices.RoomTypeRoomClass AS RoomTypeRoomClass,
			|	RawRoomRatePrices.AccommodationType AS AccommodationType,
			|	RawRoomRatePrices.SetRoomRatePrices AS SetRoomRatePrices,
			|	RawRoomRatePrices.SortCode AS SortCode,
			|	RawRoomRatePrices.LineNumber AS LineNumber,
			|	RawRoomRatePrices.Hotel AS Hotel,
			|	RawRoomRatePrices.Service AS Service,
			|	RawRoomRatePrices.Price AS Price,
			|	RawRoomRatePrices.Currency AS Currency,
			|	RawRoomRatePrices.QuantityCalculationRule AS QuantityCalculationRule,
			|	RawRoomRatePrices.QuantityCalculationRuleType AS QuantityCalculationRuleType,
			|	RawRoomRatePrices.IsRoomRevenue AS IsRoomRevenue,
			|	RawRoomRatePrices.IsInPrice AS IsInPrice,
			|	RawRoomRatePrices.ChargePerPerson AS IsPricePerPerson,
			|	RawRoomRatePrices.ChargeToEachGuestSeparately AS ChargeToEachGuestSeparately,
			|	RawRoomRatePrices.Unit AS Unit,
			|	RawRoomRatePrices.RoomRevenueAmountsOnly AS RoomRevenueAmountsOnly,
			|	0 AS MinimumQuantity,
			|	ISNULL(ServicePrices.VATRate, &qDefaultVATRate) AS VATRate
			|INTO RawRoomRatePrices
			|FROM
			|	(SELECT
			|		RoomTypePricesByDates1.AccountingDate AS AccountingDate,
			|		RateAccommodationTypeFormulas.RoomRate AS RoomRate,
			|		CASE
			|			WHEN RateAccommodationTypeFormulas.CalendarDayType <> VALUE(Catalog.CalendarDayTypes.EmptyRef)
			|				THEN RateAccommodationTypeFormulas.CalendarDayType
			|			ELSE RoomTypePricesByDates1.CalendarDayType
			|		END AS CalendarDayType,
			|		CASE
			|			WHEN RateAccommodationTypeFormulas.PriceTag <> VALUE(Catalog.PriceTags.EmptyRef)
			|				THEN RateAccommodationTypeFormulas.PriceTag
			|			ELSE RoomTypePricesByDates1.PriceTag
			|		END AS PriceTag,
			|		RateAccommodationTypeFormulas.ClientType AS ClientType,
			|		RoomTypePricesByDates1.RoomType AS RoomType,
			|		RoomTypePricesByDates1.RoomTypeRoomClass AS RoomTypeRoomClass,
			|		RateAccommodationTypeFormulas.AccommodationType AS AccommodationType,
			|		RateAccommodationTypeFormulas.SetRoomRatePrices AS SetRoomRatePrices,
			|		RateAccommodationTypeFormulas.SortCode AS SortCode,
			|		RateAccommodationTypeFormulas.LineNumber AS LineNumber,
			|		RateAccommodationTypeFormulas.Hotel AS Hotel,
			|		RoomTypePricesByDates1.Service AS Service,
			|		(RoomTypePricesByDates1.Price + ISNULL(RateAccommodationTypeFormulas.BracketsConstant, 0)) * ISNULL(RateAccommodationTypeFormulas.Multiplier, 0) + ISNULL(RateAccommodationTypeFormulas.Constant, 0) AS Price,
			|		RoomTypePricesByDates1.Currency AS Currency,
			|		RoomTypePricesByDates1.QuantityCalculationRule AS QuantityCalculationRule,
			|		RoomTypePricesByDates1.QuantityCalculationRuleType AS QuantityCalculationRuleType,
			|		RoomTypePricesByDates1.IsRoomRevenue AS IsRoomRevenue,
			|		RoomTypePricesByDates1.IsInPrice AS IsInPrice,
			|		RoomTypePricesByDates1.ChargePerPerson AS ChargePerPerson,
			|		RoomTypePricesByDates1.ChargeToEachGuestSeparately AS ChargeToEachGuestSeparately,
			|		RoomTypePricesByDates1.Unit AS Unit,
			|		RoomTypePricesByDates1.RoomRevenueAmountsOnly AS RoomRevenueAmountsOnly
			|	FROM
			|		RoomTypePricesByDates AS RoomTypePricesByDates1
			|			INNER JOIN RateAccommodationTypeFormulas AS RateAccommodationTypeFormulas
			|			ON RoomTypePricesByDates1.Service = RateAccommodationTypeFormulas.Service
			|				AND RoomTypePricesByDates1.RoomType = RateAccommodationTypeFormulas.RoomType
			|				AND (RateAccommodationTypeFormulas.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef))
			|				AND (RateAccommodationTypeFormulas.RoomClass = VALUE(Catalog.RoomTypeClasses.EmptyRef))
			|				AND (RateAccommodationTypeFormulas.Service <> VALUE(Catalog.Services.EmptyRef))
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		RoomTypePricesByDates2.AccountingDate,
			|		RateAccommodationTypeFormulas.RoomRate,
			|		CASE
			|			WHEN RateAccommodationTypeFormulas.CalendarDayType <> VALUE(Catalog.CalendarDayTypes.EmptyRef)
			|				THEN RateAccommodationTypeFormulas.CalendarDayType
			|			ELSE RoomTypePricesByDates2.CalendarDayType
			|		END,
			|		CASE
			|			WHEN RateAccommodationTypeFormulas.PriceTag <> VALUE(Catalog.PriceTags.EmptyRef)
			|				THEN RateAccommodationTypeFormulas.PriceTag
			|			ELSE RoomTypePricesByDates2.PriceTag
			|		END,
			|		RateAccommodationTypeFormulas.ClientType,
			|		RoomTypePricesByDates2.RoomType,
			|		RoomTypePricesByDates2.RoomTypeRoomClass,
			|		RateAccommodationTypeFormulas.AccommodationType,
			|		RateAccommodationTypeFormulas.SetRoomRatePrices,
			|		RateAccommodationTypeFormulas.SortCode,
			|		RateAccommodationTypeFormulas.LineNumber,
			|		RateAccommodationTypeFormulas.Hotel,
			|		RoomTypePricesByDates2.Service,
			|		(RoomTypePricesByDates2.Price + ISNULL(RateAccommodationTypeFormulas.BracketsConstant, 0)) * ISNULL(RateAccommodationTypeFormulas.Multiplier, 0) + ISNULL(RateAccommodationTypeFormulas.Constant, 0),
			|		RoomTypePricesByDates2.Currency,
			|		RoomTypePricesByDates2.QuantityCalculationRule,
			|		RoomTypePricesByDates2.QuantityCalculationRuleType,
			|		RoomTypePricesByDates2.IsRoomRevenue,
			|		RoomTypePricesByDates2.IsInPrice,
			|		RoomTypePricesByDates2.ChargePerPerson,
			|		RoomTypePricesByDates2.ChargeToEachGuestSeparately,
			|		RoomTypePricesByDates2.Unit,
			|		RoomTypePricesByDates2.RoomRevenueAmountsOnly
			|	FROM
			|		RoomTypePricesByDates AS RoomTypePricesByDates2
			|			INNER JOIN RateAccommodationTypeFormulas AS RateAccommodationTypeFormulas
			|			ON RoomTypePricesByDates2.Service = RateAccommodationTypeFormulas.Service
			|				AND RoomTypePricesByDates2.RoomTypeRoomClass = RateAccommodationTypeFormulas.RoomClass
			|				AND (RateAccommodationTypeFormulas.RoomClass <> VALUE(Catalog.RoomTypeClasses.EmptyRef))
			|				AND (RateAccommodationTypeFormulas.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
			|				AND (RateAccommodationTypeFormulas.Service <> VALUE(Catalog.Services.EmptyRef))
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		RoomTypePricesByDates3.AccountingDate,
			|		RateAccommodationTypeFormulas.RoomRate,
			|		CASE
			|			WHEN RateAccommodationTypeFormulas.CalendarDayType <> VALUE(Catalog.CalendarDayTypes.EmptyRef)
			|				THEN RateAccommodationTypeFormulas.CalendarDayType
			|			ELSE RoomTypePricesByDates3.CalendarDayType
			|		END,
			|		CASE
			|			WHEN RateAccommodationTypeFormulas.PriceTag <> VALUE(Catalog.PriceTags.EmptyRef)
			|				THEN RateAccommodationTypeFormulas.PriceTag
			|			ELSE RoomTypePricesByDates3.PriceTag
			|		END,
			|		RateAccommodationTypeFormulas.ClientType,
			|		RoomTypePricesByDates3.RoomType,
			|		RoomTypePricesByDates3.RoomTypeRoomClass,
			|		RateAccommodationTypeFormulas.AccommodationType,
			|		RateAccommodationTypeFormulas.SetRoomRatePrices,
			|		RateAccommodationTypeFormulas.SortCode,
			|		RateAccommodationTypeFormulas.LineNumber,
			|		RateAccommodationTypeFormulas.Hotel,
			|		RoomTypePricesByDates3.Service,
			|		(RoomTypePricesByDates3.Price + ISNULL(RateAccommodationTypeFormulas.BracketsConstant, 0)) * ISNULL(RateAccommodationTypeFormulas.Multiplier, 0) + ISNULL(RateAccommodationTypeFormulas.Constant, 0),
			|		RoomTypePricesByDates3.Currency,
			|		RoomTypePricesByDates3.QuantityCalculationRule,
			|		RoomTypePricesByDates3.QuantityCalculationRuleType,
			|		RoomTypePricesByDates3.IsRoomRevenue,
			|		RoomTypePricesByDates3.IsInPrice,
			|		RoomTypePricesByDates3.ChargePerPerson,
			|		RoomTypePricesByDates3.ChargeToEachGuestSeparately,
			|		RoomTypePricesByDates3.Unit,
			|		RoomTypePricesByDates3.RoomRevenueAmountsOnly
			|	FROM
			|		RoomTypePricesByDates AS RoomTypePricesByDates3
			|			INNER JOIN RateAccommodationTypeFormulas AS RateAccommodationTypeFormulas
			|			ON RoomTypePricesByDates3.Service = RateAccommodationTypeFormulas.Service
			|				AND (RateAccommodationTypeFormulas.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
			|				AND (RateAccommodationTypeFormulas.RoomClass = VALUE(Catalog.RoomTypeClasses.EmptyRef))
			|				AND (RateAccommodationTypeFormulas.Service <> VALUE(Catalog.Services.EmptyRef))
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		RoomTypePricesByDates4.AccountingDate,
			|		RateAccommodationTypeFormulas.RoomRate,
			|		CASE
			|			WHEN RateAccommodationTypeFormulas.CalendarDayType <> VALUE(Catalog.CalendarDayTypes.EmptyRef)
			|				THEN RateAccommodationTypeFormulas.CalendarDayType
			|			ELSE RoomTypePricesByDates4.CalendarDayType
			|		END,
			|		CASE
			|			WHEN RateAccommodationTypeFormulas.PriceTag <> VALUE(Catalog.PriceTags.EmptyRef)
			|				THEN RateAccommodationTypeFormulas.PriceTag
			|			ELSE RoomTypePricesByDates4.PriceTag
			|		END,
			|		RateAccommodationTypeFormulas.ClientType,
			|		RoomTypePricesByDates4.RoomType,
			|		RoomTypePricesByDates4.RoomTypeRoomClass,
			|		RateAccommodationTypeFormulas.AccommodationType,
			|		RateAccommodationTypeFormulas.SetRoomRatePrices,
			|		RateAccommodationTypeFormulas.SortCode,
			|		RateAccommodationTypeFormulas.LineNumber,
			|		RateAccommodationTypeFormulas.Hotel,
			|		RoomTypePricesByDates4.Service,
			|		(RoomTypePricesByDates4.Price + ISNULL(RateAccommodationTypeFormulas.BracketsConstant, 0)) * ISNULL(RateAccommodationTypeFormulas.Multiplier, 0) + ISNULL(RateAccommodationTypeFormulas.Constant, 0),
			|		RoomTypePricesByDates4.Currency,
			|		RoomTypePricesByDates4.QuantityCalculationRule,
			|		RoomTypePricesByDates4.QuantityCalculationRuleType,
			|		RoomTypePricesByDates4.IsRoomRevenue,
			|		RoomTypePricesByDates4.IsInPrice,
			|		RoomTypePricesByDates4.ChargePerPerson,
			|		RoomTypePricesByDates4.ChargeToEachGuestSeparately,
			|		RoomTypePricesByDates4.Unit,
			|		RoomTypePricesByDates4.RoomRevenueAmountsOnly
			|	FROM
			|		RoomTypePricesByDates AS RoomTypePricesByDates4
			|			INNER JOIN RateAccommodationTypeFormulas AS RateAccommodationTypeFormulas
			|			ON RoomTypePricesByDates4.RoomType = RateAccommodationTypeFormulas.RoomType
			|				AND (RateAccommodationTypeFormulas.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef))
			|				AND (RateAccommodationTypeFormulas.RoomClass = VALUE(Catalog.RoomTypeClasses.EmptyRef))
			|				AND (RateAccommodationTypeFormulas.Service = VALUE(Catalog.Services.EmptyRef))
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		RoomTypePricesByDates5.AccountingDate,
			|		RateAccommodationTypeFormulas.RoomRate,
			|		CASE
			|			WHEN RateAccommodationTypeFormulas.CalendarDayType <> VALUE(Catalog.CalendarDayTypes.EmptyRef)
			|				THEN RateAccommodationTypeFormulas.CalendarDayType
			|			ELSE RoomTypePricesByDates5.CalendarDayType
			|		END,
			|		CASE
			|			WHEN RateAccommodationTypeFormulas.PriceTag <> VALUE(Catalog.PriceTags.EmptyRef)
			|				THEN RateAccommodationTypeFormulas.PriceTag
			|			ELSE RoomTypePricesByDates5.PriceTag
			|		END,
			|		RateAccommodationTypeFormulas.ClientType,
			|		RoomTypePricesByDates5.RoomType,
			|		RoomTypePricesByDates5.RoomTypeRoomClass,
			|		RateAccommodationTypeFormulas.AccommodationType,
			|		RateAccommodationTypeFormulas.SetRoomRatePrices,
			|		RateAccommodationTypeFormulas.SortCode,
			|		RateAccommodationTypeFormulas.LineNumber,
			|		RateAccommodationTypeFormulas.Hotel,
			|		RoomTypePricesByDates5.Service,
			|		(RoomTypePricesByDates5.Price + ISNULL(RateAccommodationTypeFormulas.BracketsConstant, 0)) * ISNULL(RateAccommodationTypeFormulas.Multiplier, 0) + ISNULL(RateAccommodationTypeFormulas.Constant, 0),
			|		RoomTypePricesByDates5.Currency,
			|		RoomTypePricesByDates5.QuantityCalculationRule,
			|		RoomTypePricesByDates5.QuantityCalculationRuleType,
			|		RoomTypePricesByDates5.IsRoomRevenue,
			|		RoomTypePricesByDates5.IsInPrice,
			|		RoomTypePricesByDates5.ChargePerPerson,
			|		RoomTypePricesByDates5.ChargeToEachGuestSeparately,
			|		RoomTypePricesByDates5.Unit,
			|		RoomTypePricesByDates5.RoomRevenueAmountsOnly
			|	FROM
			|		RoomTypePricesByDates AS RoomTypePricesByDates5
			|			INNER JOIN RateAccommodationTypeFormulas AS RateAccommodationTypeFormulas
			|			ON RoomTypePricesByDates5.RoomTypeRoomClass = RateAccommodationTypeFormulas.RoomClass
			|				AND (RateAccommodationTypeFormulas.RoomClass <> VALUE(Catalog.RoomTypeClasses.EmptyRef))
			|				AND (RateAccommodationTypeFormulas.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
			|				AND (RateAccommodationTypeFormulas.Service = VALUE(Catalog.Services.EmptyRef))
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		RoomTypePricesByDates6.AccountingDate,
			|		RateAccommodationTypeFormulas.RoomRate,
			|		CASE
			|			WHEN RateAccommodationTypeFormulas.CalendarDayType <> VALUE(Catalog.CalendarDayTypes.EmptyRef)
			|				THEN RateAccommodationTypeFormulas.CalendarDayType
			|			ELSE RoomTypePricesByDates6.CalendarDayType
			|		END,
			|		CASE
			|			WHEN RateAccommodationTypeFormulas.PriceTag <> VALUE(Catalog.PriceTags.EmptyRef)
			|				THEN RateAccommodationTypeFormulas.PriceTag
			|			ELSE RoomTypePricesByDates6.PriceTag
			|		END,
			|		RateAccommodationTypeFormulas.ClientType,
			|		RoomTypePricesByDates6.RoomType,
			|		RoomTypePricesByDates6.RoomTypeRoomClass,
			|		RateAccommodationTypeFormulas.AccommodationType,
			|		RateAccommodationTypeFormulas.SetRoomRatePrices,
			|		RateAccommodationTypeFormulas.SortCode,
			|		RateAccommodationTypeFormulas.LineNumber,
			|		RateAccommodationTypeFormulas.Hotel,
			|		RoomTypePricesByDates6.Service,
			|		(RoomTypePricesByDates6.Price + ISNULL(RateAccommodationTypeFormulas.BracketsConstant, 0)) * ISNULL(RateAccommodationTypeFormulas.Multiplier, 0) + ISNULL(RateAccommodationTypeFormulas.Constant, 0),
			|		RoomTypePricesByDates6.Currency,
			|		RoomTypePricesByDates6.QuantityCalculationRule,
			|		RoomTypePricesByDates6.QuantityCalculationRuleType,
			|		RoomTypePricesByDates6.IsRoomRevenue,
			|		RoomTypePricesByDates6.IsInPrice,
			|		RoomTypePricesByDates6.ChargePerPerson,
			|		RoomTypePricesByDates6.ChargeToEachGuestSeparately,
			|		RoomTypePricesByDates6.Unit,
			|		RoomTypePricesByDates6.RoomRevenueAmountsOnly
			|	FROM
			|		RoomTypePricesByDates AS RoomTypePricesByDates6
			|			INNER JOIN RateAccommodationTypeFormulas AS RateAccommodationTypeFormulas
			|			ON (RateAccommodationTypeFormulas.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
			|				AND (RateAccommodationTypeFormulas.RoomClass = VALUE(Catalog.RoomTypeClasses.EmptyRef))
			|				AND (RateAccommodationTypeFormulas.Service = VALUE(Catalog.Services.EmptyRef))) AS RawRoomRatePrices
			|		LEFT JOIN ServicePrices AS ServicePrices
			|		ON RawRoomRatePrices.Service = ServicePrices.Service
			|			AND RawRoomRatePrices.ClientType = ServicePrices.ClientType
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|DROP RoomTypePricesByDates
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	RoomRatePricesJoinedWithFormulas.AccountingDate AS AccountingDate,
			|	RoomRatePricesJoinedWithFormulas.RoomRate AS RoomRate,
			|	RoomRatePricesJoinedWithFormulas.CalendarDayType AS CalendarDayType,
			|	RoomRatePricesJoinedWithFormulas.PriceTag AS PriceTag,
			|	RoomRatePricesJoinedWithFormulas.ClientType AS ClientType,
			|	RoomRatePricesJoinedWithFormulas.RoomType AS RoomType,
			|	RoomRatePricesJoinedWithFormulas.RoomTypeRoomClass AS RoomTypeRoomClass,
			|	RoomRatePricesJoinedWithFormulas.AccommodationType AS AccommodationType,
			|	RoomRatePricesJoinedWithFormulas.SetRoomRatePrices AS SetRoomRatePrices,
			|	RoomRatePricesJoinedWithFormulas.SortCode AS SortCode,
			|	RoomRatePricesJoinedWithFormulas.LineNumber AS LineNumber,
			|	RoomRatePricesJoinedWithFormulas.Hotel AS Hotel,
			|	RoomRatePricesJoinedWithFormulas.Service AS Service,
			|	RoomRatePricesJoinedWithFormulas.Price AS Price,
			|	RoomRatePricesJoinedWithFormulas.Currency AS Currency,
			|	RoomRatePricesJoinedWithFormulas.MinimumQuantity AS MinimumQuantity,
			|	RoomRatePricesJoinedWithFormulas.VATRate AS VATRate,
			|	RoomRatePricesJoinedWithFormulas.QuantityCalculationRule AS QuantityCalculationRule,
			|	RoomRatePricesJoinedWithFormulas.QuantityCalculationRuleType AS QuantityCalculationRuleType,
			|	RoomRatePricesJoinedWithFormulas.IsRoomRevenue AS IsRoomRevenue,
			|	RoomRatePricesJoinedWithFormulas.IsInPrice AS IsInPrice,
			|	RoomRatePricesJoinedWithFormulas.IsPricePerPerson AS IsPricePerPerson,
			|	RoomRatePricesJoinedWithFormulas.ChargeToEachGuestSeparately AS ChargeToEachGuestSeparately,
			|	RoomRatePricesJoinedWithFormulas.Unit AS Unit,
			|	RoomRatePricesJoinedWithFormulas.RoomRevenueAmountsOnly AS RoomRevenueAmountsOnly
			|INTO RoomRatePricesJoinedWithFormulas
			|FROM
			|	(SELECT
			|		RoomRatePrices1.AccountingDate AS AccountingDate,
			|		RoomRatePrices1.RoomRate AS RoomRate,
			|		RoomRatePrices1.CalendarDayType AS CalendarDayType,
			|		RoomRatePrices1.PriceTag AS PriceTag,
			|		RoomRatePrices1.ClientType AS ClientType,
			|		RoomRatePrices1.RoomType AS RoomType,
			|		RoomRatePrices1.RoomTypeRoomClass AS RoomTypeRoomClass,
			|		RoomRatePrices1.AccommodationType AS AccommodationType,
			|		RoomRatePrices1.SetRoomRatePrices AS SetRoomRatePrices,
			|		RoomRatePrices1.SortCode AS SortCode,
			|		RoomRatePrices1.LineNumber AS LineNumber,
			|		RoomRatePrices1.Hotel AS Hotel,
			|		RoomRatePrices1.Service AS Service,
			|		CASE
			|			WHEN ISNULL(FormulasForPriceTags.Discount, 0) <> 0
			|				THEN RoomRatePrices1.Price - RoomRatePrices1.Price * ISNULL(FormulasForPriceTags.Discount, 0) / 100
			|			ELSE (RoomRatePrices1.Price + ISNULL(FormulasForPriceTags.BracketsConstant, 0)) * ISNULL(FormulasForPriceTags.Multiplier, 1) + ISNULL(FormulasForPriceTags.Constant, 0)
			|		END AS Price,
			|		RoomRatePrices1.Currency AS Currency,
			|		RoomRatePrices1.MinimumQuantity AS MinimumQuantity,
			|		RoomRatePrices1.VATRate AS VATRate,
			|		RoomRatePrices1.QuantityCalculationRule AS QuantityCalculationRule,
			|		RoomRatePrices1.QuantityCalculationRuleType AS QuantityCalculationRuleType,
			|		RoomRatePrices1.IsRoomRevenue AS IsRoomRevenue,
			|		RoomRatePrices1.IsInPrice AS IsInPrice,
			|		RoomRatePrices1.IsPricePerPerson AS IsPricePerPerson,
			|		RoomRatePrices1.ChargeToEachGuestSeparately AS ChargeToEachGuestSeparately,
			|		RoomRatePrices1.Unit AS Unit,
			|		RoomRatePrices1.RoomRevenueAmountsOnly AS RoomRevenueAmountsOnly
			|	FROM
			|		RawRoomRatePrices AS RoomRatePrices1
			|			INNER JOIN FormulasForPriceTags AS FormulasForPriceTags
			|			ON RoomRatePrices1.ClientType = FormulasForPriceTags.ClientType
			|				AND RoomRatePrices1.PriceTag = FormulasForPriceTags.PriceTag
			|				AND RoomRatePrices1.CalendarDayType = FormulasForPriceTags.CalendarDayType
			|				AND RoomRatePrices1.Service = FormulasForPriceTags.Service
			|				AND RoomRatePrices1.RoomType = FormulasForPriceTags.RoomType
			|				AND RoomRatePrices1.AccommodationType = FormulasForPriceTags.AccommodationType
			|				AND (FormulasForPriceTags.Service <> VALUE(Catalog.Services.EmptyRef))
			|				AND (FormulasForPriceTags.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef))
			|				AND (FormulasForPriceTags.RoomClass = VALUE(Catalog.RoomTypeClasses.EmptyRef))
			|				AND (FormulasForPriceTags.AccommodationType <> VALUE(Catalog.AccommodationTypes.EmptyRef))
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		RoomRatePrices2.AccountingDate,
			|		RoomRatePrices2.RoomRate,
			|		RoomRatePrices2.CalendarDayType,
			|		RoomRatePrices2.PriceTag,
			|		RoomRatePrices2.ClientType,
			|		RoomRatePrices2.RoomType,
			|		RoomRatePrices2.RoomTypeRoomClass,
			|		RoomRatePrices2.AccommodationType,
			|		RoomRatePrices2.SetRoomRatePrices,
			|		RoomRatePrices2.SortCode,
			|		RoomRatePrices2.LineNumber,
			|		RoomRatePrices2.Hotel,
			|		RoomRatePrices2.Service,
			|		CASE
			|			WHEN ISNULL(FormulasForPriceTags.Discount, 0) <> 0
			|				THEN RoomRatePrices2.Price - RoomRatePrices2.Price * ISNULL(FormulasForPriceTags.Discount, 0) / 100
			|			ELSE (RoomRatePrices2.Price + ISNULL(FormulasForPriceTags.BracketsConstant, 0)) * ISNULL(FormulasForPriceTags.Multiplier, 1) + ISNULL(FormulasForPriceTags.Constant, 0)
			|		END,
			|		RoomRatePrices2.Currency,
			|		RoomRatePrices2.MinimumQuantity,
			|		RoomRatePrices2.VATRate,
			|		RoomRatePrices2.QuantityCalculationRule,
			|		RoomRatePrices2.QuantityCalculationRuleType,
			|		RoomRatePrices2.IsRoomRevenue,
			|		RoomRatePrices2.IsInPrice,
			|		RoomRatePrices2.IsPricePerPerson,
			|		RoomRatePrices2.ChargeToEachGuestSeparately,
			|		RoomRatePrices2.Unit,
			|		RoomRatePrices2.RoomRevenueAmountsOnly
			|	FROM
			|		RawRoomRatePrices AS RoomRatePrices2
			|			INNER JOIN FormulasForPriceTags AS FormulasForPriceTags
			|			ON RoomRatePrices2.ClientType = FormulasForPriceTags.ClientType
			|				AND RoomRatePrices2.PriceTag = FormulasForPriceTags.PriceTag
			|				AND RoomRatePrices2.CalendarDayType = FormulasForPriceTags.CalendarDayType
			|				AND RoomRatePrices2.Service = FormulasForPriceTags.Service
			|				AND RoomRatePrices2.RoomTypeRoomClass = FormulasForPriceTags.RoomClass
			|				AND RoomRatePrices2.AccommodationType = FormulasForPriceTags.AccommodationType
			|				AND (FormulasForPriceTags.Service <> VALUE(Catalog.Services.EmptyRef))
			|				AND (FormulasForPriceTags.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
			|				AND (FormulasForPriceTags.RoomClass <> VALUE(Catalog.RoomTypeClasses.EmptyRef))
			|				AND (FormulasForPriceTags.AccommodationType <> VALUE(Catalog.AccommodationTypes.EmptyRef))
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		RoomRatePrices3.AccountingDate,
			|		RoomRatePrices3.RoomRate,
			|		RoomRatePrices3.CalendarDayType,
			|		RoomRatePrices3.PriceTag,
			|		RoomRatePrices3.ClientType,
			|		RoomRatePrices3.RoomType,
			|		RoomRatePrices3.RoomTypeRoomClass,
			|		RoomRatePrices3.AccommodationType,
			|		RoomRatePrices3.SetRoomRatePrices,
			|		RoomRatePrices3.SortCode,
			|		RoomRatePrices3.LineNumber,
			|		RoomRatePrices3.Hotel,
			|		RoomRatePrices3.Service,
			|		CASE
			|			WHEN ISNULL(FormulasForPriceTags.Discount, 0) <> 0
			|				THEN RoomRatePrices3.Price - RoomRatePrices3.Price * ISNULL(FormulasForPriceTags.Discount, 0) / 100
			|			ELSE (RoomRatePrices3.Price + ISNULL(FormulasForPriceTags.BracketsConstant, 0)) * ISNULL(FormulasForPriceTags.Multiplier, 1) + ISNULL(FormulasForPriceTags.Constant, 0)
			|		END,
			|		RoomRatePrices3.Currency,
			|		RoomRatePrices3.MinimumQuantity,
			|		RoomRatePrices3.VATRate,
			|		RoomRatePrices3.QuantityCalculationRule,
			|		RoomRatePrices3.QuantityCalculationRuleType,
			|		RoomRatePrices3.IsRoomRevenue,
			|		RoomRatePrices3.IsInPrice,
			|		RoomRatePrices3.IsPricePerPerson,
			|		RoomRatePrices3.ChargeToEachGuestSeparately,
			|		RoomRatePrices3.Unit,
			|		RoomRatePrices3.RoomRevenueAmountsOnly
			|	FROM
			|		RawRoomRatePrices AS RoomRatePrices3
			|			INNER JOIN FormulasForPriceTags AS FormulasForPriceTags
			|			ON RoomRatePrices3.ClientType = FormulasForPriceTags.ClientType
			|				AND RoomRatePrices3.PriceTag = FormulasForPriceTags.PriceTag
			|				AND RoomRatePrices3.CalendarDayType = FormulasForPriceTags.CalendarDayType
			|				AND RoomRatePrices3.Service = FormulasForPriceTags.Service
			|				AND RoomRatePrices3.AccommodationType = FormulasForPriceTags.AccommodationType
			|				AND (FormulasForPriceTags.Service <> VALUE(Catalog.Services.EmptyRef))
			|				AND (FormulasForPriceTags.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
			|				AND (FormulasForPriceTags.RoomClass = VALUE(Catalog.RoomTypeClasses.EmptyRef))
			|				AND (FormulasForPriceTags.AccommodationType <> VALUE(Catalog.AccommodationTypes.EmptyRef))
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		RoomRatePrices4.AccountingDate,
			|		RoomRatePrices4.RoomRate,
			|		RoomRatePrices4.CalendarDayType,
			|		RoomRatePrices4.PriceTag,
			|		RoomRatePrices4.ClientType,
			|		RoomRatePrices4.RoomType,
			|		RoomRatePrices4.RoomTypeRoomClass,
			|		RoomRatePrices4.AccommodationType,
			|		RoomRatePrices4.SetRoomRatePrices,
			|		RoomRatePrices4.SortCode,
			|		RoomRatePrices4.LineNumber,
			|		RoomRatePrices4.Hotel,
			|		RoomRatePrices4.Service,
			|		CASE
			|			WHEN ISNULL(FormulasForPriceTags.Discount, 0) <> 0
			|				THEN RoomRatePrices4.Price - RoomRatePrices4.Price * ISNULL(FormulasForPriceTags.Discount, 0) / 100
			|			ELSE (RoomRatePrices4.Price + ISNULL(FormulasForPriceTags.BracketsConstant, 0)) * ISNULL(FormulasForPriceTags.Multiplier, 1) + ISNULL(FormulasForPriceTags.Constant, 0)
			|		END,
			|		RoomRatePrices4.Currency,
			|		RoomRatePrices4.MinimumQuantity,
			|		RoomRatePrices4.VATRate,
			|		RoomRatePrices4.QuantityCalculationRule,
			|		RoomRatePrices4.QuantityCalculationRuleType,
			|		RoomRatePrices4.IsRoomRevenue,
			|		RoomRatePrices4.IsInPrice,
			|		RoomRatePrices4.IsPricePerPerson,
			|		RoomRatePrices4.ChargeToEachGuestSeparately,
			|		RoomRatePrices4.Unit,
			|		RoomRatePrices4.RoomRevenueAmountsOnly
			|	FROM
			|		RawRoomRatePrices AS RoomRatePrices4
			|			INNER JOIN FormulasForPriceTags AS FormulasForPriceTags
			|			ON RoomRatePrices4.ClientType = FormulasForPriceTags.ClientType
			|				AND RoomRatePrices4.PriceTag = FormulasForPriceTags.PriceTag
			|				AND RoomRatePrices4.CalendarDayType = FormulasForPriceTags.CalendarDayType
			|				AND RoomRatePrices4.RoomType = FormulasForPriceTags.RoomType
			|				AND RoomRatePrices4.AccommodationType = FormulasForPriceTags.AccommodationType
			|				AND (FormulasForPriceTags.Service = VALUE(Catalog.Services.EmptyRef))
			|				AND (FormulasForPriceTags.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef))
			|				AND (FormulasForPriceTags.RoomClass = VALUE(Catalog.RoomTypeClasses.EmptyRef))
			|				AND (FormulasForPriceTags.AccommodationType <> VALUE(Catalog.AccommodationTypes.EmptyRef))
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		RoomRatePrices5.AccountingDate,
			|		RoomRatePrices5.RoomRate,
			|		RoomRatePrices5.CalendarDayType,
			|		RoomRatePrices5.PriceTag,
			|		RoomRatePrices5.ClientType,
			|		RoomRatePrices5.RoomType,
			|		RoomRatePrices5.RoomTypeRoomClass,
			|		RoomRatePrices5.AccommodationType,
			|		RoomRatePrices5.SetRoomRatePrices,
			|		RoomRatePrices5.SortCode,
			|		RoomRatePrices5.LineNumber,
			|		RoomRatePrices5.Hotel,
			|		RoomRatePrices5.Service,
			|		CASE
			|			WHEN ISNULL(FormulasForPriceTags.Discount, 0) <> 0
			|				THEN RoomRatePrices5.Price - RoomRatePrices5.Price * ISNULL(FormulasForPriceTags.Discount, 0) / 100
			|			ELSE (RoomRatePrices5.Price + ISNULL(FormulasForPriceTags.BracketsConstant, 0)) * ISNULL(FormulasForPriceTags.Multiplier, 1) + ISNULL(FormulasForPriceTags.Constant, 0)
			|		END,
			|		RoomRatePrices5.Currency,
			|		RoomRatePrices5.MinimumQuantity,
			|		RoomRatePrices5.VATRate,
			|		RoomRatePrices5.QuantityCalculationRule,
			|		RoomRatePrices5.QuantityCalculationRuleType,
			|		RoomRatePrices5.IsRoomRevenue,
			|		RoomRatePrices5.IsInPrice,
			|		RoomRatePrices5.IsPricePerPerson,
			|		RoomRatePrices5.ChargeToEachGuestSeparately,
			|		RoomRatePrices5.Unit,
			|		RoomRatePrices5.RoomRevenueAmountsOnly
			|	FROM
			|		RawRoomRatePrices AS RoomRatePrices5
			|			INNER JOIN FormulasForPriceTags AS FormulasForPriceTags
			|			ON RoomRatePrices5.ClientType = FormulasForPriceTags.ClientType
			|				AND RoomRatePrices5.PriceTag = FormulasForPriceTags.PriceTag
			|				AND RoomRatePrices5.CalendarDayType = FormulasForPriceTags.CalendarDayType
			|				AND RoomRatePrices5.RoomTypeRoomClass = FormulasForPriceTags.RoomClass
			|				AND RoomRatePrices5.AccommodationType = FormulasForPriceTags.AccommodationType
			|				AND (FormulasForPriceTags.Service = VALUE(Catalog.Services.EmptyRef))
			|				AND (FormulasForPriceTags.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
			|				AND (FormulasForPriceTags.RoomClass <> VALUE(Catalog.RoomTypeClasses.EmptyRef))
			|				AND (FormulasForPriceTags.AccommodationType <> VALUE(Catalog.AccommodationTypes.EmptyRef))
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		RoomRatePrices6.AccountingDate,
			|		RoomRatePrices6.RoomRate,
			|		RoomRatePrices6.CalendarDayType,
			|		RoomRatePrices6.PriceTag,
			|		RoomRatePrices6.ClientType,
			|		RoomRatePrices6.RoomType,
			|		RoomRatePrices6.RoomTypeRoomClass,
			|		RoomRatePrices6.AccommodationType,
			|		RoomRatePrices6.SetRoomRatePrices,
			|		RoomRatePrices6.SortCode,
			|		RoomRatePrices6.LineNumber,
			|		RoomRatePrices6.Hotel,
			|		RoomRatePrices6.Service,
			|		CASE
			|			WHEN ISNULL(FormulasForPriceTags.Discount, 0) <> 0
			|				THEN RoomRatePrices6.Price - RoomRatePrices6.Price * ISNULL(FormulasForPriceTags.Discount, 0) / 100
			|			ELSE (RoomRatePrices6.Price + ISNULL(FormulasForPriceTags.BracketsConstant, 0)) * ISNULL(FormulasForPriceTags.Multiplier, 1) + ISNULL(FormulasForPriceTags.Constant, 0)
			|		END,
			|		RoomRatePrices6.Currency,
			|		RoomRatePrices6.MinimumQuantity,
			|		RoomRatePrices6.VATRate,
			|		RoomRatePrices6.QuantityCalculationRule,
			|		RoomRatePrices6.QuantityCalculationRuleType,
			|		RoomRatePrices6.IsRoomRevenue,
			|		RoomRatePrices6.IsInPrice,
			|		RoomRatePrices6.IsPricePerPerson,
			|		RoomRatePrices6.ChargeToEachGuestSeparately,
			|		RoomRatePrices6.Unit,
			|		RoomRatePrices6.RoomRevenueAmountsOnly
			|	FROM
			|		RawRoomRatePrices AS RoomRatePrices6
			|			INNER JOIN FormulasForPriceTags AS FormulasForPriceTags
			|			ON RoomRatePrices6.ClientType = FormulasForPriceTags.ClientType
			|				AND RoomRatePrices6.PriceTag = FormulasForPriceTags.PriceTag
			|				AND RoomRatePrices6.CalendarDayType = FormulasForPriceTags.CalendarDayType
			|				AND RoomRatePrices6.AccommodationType = FormulasForPriceTags.AccommodationType
			|				AND (FormulasForPriceTags.Service = VALUE(Catalog.Services.EmptyRef))
			|				AND (FormulasForPriceTags.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
			|				AND (FormulasForPriceTags.RoomClass = VALUE(Catalog.RoomTypeClasses.EmptyRef))
			|				AND (FormulasForPriceTags.AccommodationType <> VALUE(Catalog.AccommodationTypes.EmptyRef))
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		RoomRatePrices7.AccountingDate,
			|		RoomRatePrices7.RoomRate,
			|		RoomRatePrices7.CalendarDayType,
			|		RoomRatePrices7.PriceTag,
			|		RoomRatePrices7.ClientType,
			|		RoomRatePrices7.RoomType,
			|		RoomRatePrices7.RoomTypeRoomClass,
			|		RoomRatePrices7.AccommodationType,
			|		RoomRatePrices7.SetRoomRatePrices,
			|		RoomRatePrices7.SortCode,
			|		RoomRatePrices7.LineNumber,
			|		RoomRatePrices7.Hotel,
			|		RoomRatePrices7.Service,
			|		CASE
			|			WHEN ISNULL(FormulasForPriceTags.Discount, 0) <> 0
			|				THEN RoomRatePrices7.Price - RoomRatePrices7.Price * ISNULL(FormulasForPriceTags.Discount, 0) / 100
			|			ELSE (RoomRatePrices7.Price + ISNULL(FormulasForPriceTags.BracketsConstant, 0)) * ISNULL(FormulasForPriceTags.Multiplier, 1) + ISNULL(FormulasForPriceTags.Constant, 0)
			|		END,
			|		RoomRatePrices7.Currency,
			|		RoomRatePrices7.MinimumQuantity,
			|		RoomRatePrices7.VATRate,
			|		RoomRatePrices7.QuantityCalculationRule,
			|		RoomRatePrices7.QuantityCalculationRuleType,
			|		RoomRatePrices7.IsRoomRevenue,
			|		RoomRatePrices7.IsInPrice,
			|		RoomRatePrices7.IsPricePerPerson,
			|		RoomRatePrices7.ChargeToEachGuestSeparately,
			|		RoomRatePrices7.Unit,
			|		RoomRatePrices7.RoomRevenueAmountsOnly
			|	FROM
			|		RawRoomRatePrices AS RoomRatePrices7
			|			INNER JOIN FormulasForPriceTags AS FormulasForPriceTags
			|			ON RoomRatePrices7.ClientType = FormulasForPriceTags.ClientType
			|				AND RoomRatePrices7.PriceTag = FormulasForPriceTags.PriceTag
			|				AND RoomRatePrices7.CalendarDayType = FormulasForPriceTags.CalendarDayType
			|				AND RoomRatePrices7.Service = FormulasForPriceTags.Service
			|				AND RoomRatePrices7.RoomType = FormulasForPriceTags.RoomType
			|				AND (FormulasForPriceTags.Service <> VALUE(Catalog.Services.EmptyRef))
			|				AND (FormulasForPriceTags.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef))
			|				AND (FormulasForPriceTags.RoomClass = VALUE(Catalog.RoomTypeClasses.EmptyRef))
			|				AND (FormulasForPriceTags.AccommodationType = VALUE(Catalog.AccommodationTypes.EmptyRef))
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		RoomRatePrices8.AccountingDate,
			|		RoomRatePrices8.RoomRate,
			|		RoomRatePrices8.CalendarDayType,
			|		RoomRatePrices8.PriceTag,
			|		RoomRatePrices8.ClientType,
			|		RoomRatePrices8.RoomType,
			|		RoomRatePrices8.RoomTypeRoomClass,
			|		RoomRatePrices8.AccommodationType,
			|		RoomRatePrices8.SetRoomRatePrices,
			|		RoomRatePrices8.SortCode,
			|		RoomRatePrices8.LineNumber,
			|		RoomRatePrices8.Hotel,
			|		RoomRatePrices8.Service,
			|		CASE
			|			WHEN ISNULL(FormulasForPriceTags.Discount, 0) <> 0
			|				THEN RoomRatePrices8.Price - RoomRatePrices8.Price * ISNULL(FormulasForPriceTags.Discount, 0) / 100
			|			ELSE (RoomRatePrices8.Price + ISNULL(FormulasForPriceTags.BracketsConstant, 0)) * ISNULL(FormulasForPriceTags.Multiplier, 1) + ISNULL(FormulasForPriceTags.Constant, 0)
			|		END,
			|		RoomRatePrices8.Currency,
			|		RoomRatePrices8.MinimumQuantity,
			|		RoomRatePrices8.VATRate,
			|		RoomRatePrices8.QuantityCalculationRule,
			|		RoomRatePrices8.QuantityCalculationRuleType,
			|		RoomRatePrices8.IsRoomRevenue,
			|		RoomRatePrices8.IsInPrice,
			|		RoomRatePrices8.IsPricePerPerson,
			|		RoomRatePrices8.ChargeToEachGuestSeparately,
			|		RoomRatePrices8.Unit,
			|		RoomRatePrices8.RoomRevenueAmountsOnly
			|	FROM
			|		RawRoomRatePrices AS RoomRatePrices8
			|			INNER JOIN FormulasForPriceTags AS FormulasForPriceTags
			|			ON RoomRatePrices8.ClientType = FormulasForPriceTags.ClientType
			|				AND RoomRatePrices8.PriceTag = FormulasForPriceTags.PriceTag
			|				AND RoomRatePrices8.CalendarDayType = FormulasForPriceTags.CalendarDayType
			|				AND RoomRatePrices8.Service = FormulasForPriceTags.Service
			|				AND RoomRatePrices8.RoomTypeRoomClass = FormulasForPriceTags.RoomClass
			|				AND (FormulasForPriceTags.Service <> VALUE(Catalog.Services.EmptyRef))
			|				AND (FormulasForPriceTags.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
			|				AND (FormulasForPriceTags.RoomClass <> VALUE(Catalog.RoomTypeClasses.EmptyRef))
			|				AND (FormulasForPriceTags.AccommodationType = VALUE(Catalog.AccommodationTypes.EmptyRef))
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		RoomRatePrices9.AccountingDate,
			|		RoomRatePrices9.RoomRate,
			|		RoomRatePrices9.CalendarDayType,
			|		RoomRatePrices9.PriceTag,
			|		RoomRatePrices9.ClientType,
			|		RoomRatePrices9.RoomType,
			|		RoomRatePrices9.RoomTypeRoomClass,
			|		RoomRatePrices9.AccommodationType,
			|		RoomRatePrices9.SetRoomRatePrices,
			|		RoomRatePrices9.SortCode,
			|		RoomRatePrices9.LineNumber,
			|		RoomRatePrices9.Hotel,
			|		RoomRatePrices9.Service,
			|		CASE
			|			WHEN ISNULL(FormulasForPriceTags.Discount, 0) <> 0
			|				THEN RoomRatePrices9.Price - RoomRatePrices9.Price * ISNULL(FormulasForPriceTags.Discount, 0) / 100
			|			ELSE (RoomRatePrices9.Price + ISNULL(FormulasForPriceTags.BracketsConstant, 0)) * ISNULL(FormulasForPriceTags.Multiplier, 1) + ISNULL(FormulasForPriceTags.Constant, 0)
			|		END,
			|		RoomRatePrices9.Currency,
			|		RoomRatePrices9.MinimumQuantity,
			|		RoomRatePrices9.VATRate,
			|		RoomRatePrices9.QuantityCalculationRule,
			|		RoomRatePrices9.QuantityCalculationRuleType,
			|		RoomRatePrices9.IsRoomRevenue,
			|		RoomRatePrices9.IsInPrice,
			|		RoomRatePrices9.IsPricePerPerson,
			|		RoomRatePrices9.ChargeToEachGuestSeparately,
			|		RoomRatePrices9.Unit,
			|		RoomRatePrices9.RoomRevenueAmountsOnly
			|	FROM
			|		RawRoomRatePrices AS RoomRatePrices9
			|			INNER JOIN FormulasForPriceTags AS FormulasForPriceTags
			|			ON RoomRatePrices9.ClientType = FormulasForPriceTags.ClientType
			|				AND RoomRatePrices9.PriceTag = FormulasForPriceTags.PriceTag
			|				AND RoomRatePrices9.CalendarDayType = FormulasForPriceTags.CalendarDayType
			|				AND RoomRatePrices9.Service = FormulasForPriceTags.Service
			|				AND (FormulasForPriceTags.Service <> VALUE(Catalog.Services.EmptyRef))
			|				AND (FormulasForPriceTags.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
			|				AND (FormulasForPriceTags.RoomClass = VALUE(Catalog.RoomTypeClasses.EmptyRef))
			|				AND (FormulasForPriceTags.AccommodationType = VALUE(Catalog.AccommodationTypes.EmptyRef))
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		RoomRatePrices10.AccountingDate,
			|		RoomRatePrices10.RoomRate,
			|		RoomRatePrices10.CalendarDayType,
			|		RoomRatePrices10.PriceTag,
			|		RoomRatePrices10.ClientType,
			|		RoomRatePrices10.RoomType,
			|		RoomRatePrices10.RoomTypeRoomClass,
			|		RoomRatePrices10.AccommodationType,
			|		RoomRatePrices10.SetRoomRatePrices,
			|		RoomRatePrices10.SortCode,
			|		RoomRatePrices10.LineNumber,
			|		RoomRatePrices10.Hotel,
			|		RoomRatePrices10.Service,
			|		CASE
			|			WHEN ISNULL(FormulasForPriceTags.Discount, 0) <> 0
			|				THEN RoomRatePrices10.Price - RoomRatePrices10.Price * ISNULL(FormulasForPriceTags.Discount, 0) / 100
			|			ELSE (RoomRatePrices10.Price + ISNULL(FormulasForPriceTags.BracketsConstant, 0)) * ISNULL(FormulasForPriceTags.Multiplier, 1) + ISNULL(FormulasForPriceTags.Constant, 0)
			|		END,
			|		RoomRatePrices10.Currency,
			|		RoomRatePrices10.MinimumQuantity,
			|		RoomRatePrices10.VATRate,
			|		RoomRatePrices10.QuantityCalculationRule,
			|		RoomRatePrices10.QuantityCalculationRuleType,
			|		RoomRatePrices10.IsRoomRevenue,
			|		RoomRatePrices10.IsInPrice,
			|		RoomRatePrices10.IsPricePerPerson,
			|		RoomRatePrices10.ChargeToEachGuestSeparately,
			|		RoomRatePrices10.Unit,
			|		RoomRatePrices10.RoomRevenueAmountsOnly
			|	FROM
			|		RawRoomRatePrices AS RoomRatePrices10
			|			INNER JOIN FormulasForPriceTags AS FormulasForPriceTags
			|			ON RoomRatePrices10.ClientType = FormulasForPriceTags.ClientType
			|				AND RoomRatePrices10.PriceTag = FormulasForPriceTags.PriceTag
			|				AND RoomRatePrices10.CalendarDayType = FormulasForPriceTags.CalendarDayType
			|				AND RoomRatePrices10.RoomType = FormulasForPriceTags.RoomType
			|				AND (FormulasForPriceTags.Service = VALUE(Catalog.Services.EmptyRef))
			|				AND (FormulasForPriceTags.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef))
			|				AND (FormulasForPriceTags.RoomClass = VALUE(Catalog.RoomTypeClasses.EmptyRef))
			|				AND (FormulasForPriceTags.AccommodationType = VALUE(Catalog.AccommodationTypes.EmptyRef))
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		RoomRatePrices11.AccountingDate,
			|		RoomRatePrices11.RoomRate,
			|		RoomRatePrices11.CalendarDayType,
			|		RoomRatePrices11.PriceTag,
			|		RoomRatePrices11.ClientType,
			|		RoomRatePrices11.RoomType,
			|		RoomRatePrices11.RoomTypeRoomClass,
			|		RoomRatePrices11.AccommodationType,
			|		RoomRatePrices11.SetRoomRatePrices,
			|		RoomRatePrices11.SortCode,
			|		RoomRatePrices11.LineNumber,
			|		RoomRatePrices11.Hotel,
			|		RoomRatePrices11.Service,
			|		CASE
			|			WHEN ISNULL(FormulasForPriceTags.Discount, 0) <> 0
			|				THEN RoomRatePrices11.Price - RoomRatePrices11.Price * ISNULL(FormulasForPriceTags.Discount, 0) / 100
			|			ELSE (RoomRatePrices11.Price + ISNULL(FormulasForPriceTags.BracketsConstant, 0)) * ISNULL(FormulasForPriceTags.Multiplier, 1) + ISNULL(FormulasForPriceTags.Constant, 0)
			|		END,
			|		RoomRatePrices11.Currency,
			|		RoomRatePrices11.MinimumQuantity,
			|		RoomRatePrices11.VATRate,
			|		RoomRatePrices11.QuantityCalculationRule,
			|		RoomRatePrices11.QuantityCalculationRuleType,
			|		RoomRatePrices11.IsRoomRevenue,
			|		RoomRatePrices11.IsInPrice,
			|		RoomRatePrices11.IsPricePerPerson,
			|		RoomRatePrices11.ChargeToEachGuestSeparately,
			|		RoomRatePrices11.Unit,
			|		RoomRatePrices11.RoomRevenueAmountsOnly
			|	FROM
			|		RawRoomRatePrices AS RoomRatePrices11
			|			INNER JOIN FormulasForPriceTags AS FormulasForPriceTags
			|			ON RoomRatePrices11.ClientType = FormulasForPriceTags.ClientType
			|				AND RoomRatePrices11.PriceTag = FormulasForPriceTags.PriceTag
			|				AND RoomRatePrices11.CalendarDayType = FormulasForPriceTags.CalendarDayType
			|				AND RoomRatePrices11.RoomTypeRoomClass = FormulasForPriceTags.RoomClass
			|				AND (FormulasForPriceTags.Service = VALUE(Catalog.Services.EmptyRef))
			|				AND (FormulasForPriceTags.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
			|				AND (FormulasForPriceTags.RoomClass <> VALUE(Catalog.RoomTypeClasses.EmptyRef))
			|				AND (FormulasForPriceTags.AccommodationType = VALUE(Catalog.AccommodationTypes.EmptyRef))
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		RoomRatePrices12.AccountingDate,
			|		RoomRatePrices12.RoomRate,
			|		RoomRatePrices12.CalendarDayType,
			|		RoomRatePrices12.PriceTag,
			|		RoomRatePrices12.ClientType,
			|		RoomRatePrices12.RoomType,
			|		RoomRatePrices12.RoomTypeRoomClass,
			|		RoomRatePrices12.AccommodationType,
			|		RoomRatePrices12.SetRoomRatePrices,
			|		RoomRatePrices12.SortCode,
			|		RoomRatePrices12.LineNumber,
			|		RoomRatePrices12.Hotel,
			|		RoomRatePrices12.Service,
			|		CASE
			|			WHEN ISNULL(FormulasForPriceTags.Discount, 0) <> 0
			|				THEN RoomRatePrices12.Price - RoomRatePrices12.Price * ISNULL(FormulasForPriceTags.Discount, 0) / 100
			|			ELSE (RoomRatePrices12.Price + ISNULL(FormulasForPriceTags.BracketsConstant, 0)) * ISNULL(FormulasForPriceTags.Multiplier, 1) + ISNULL(FormulasForPriceTags.Constant, 0)
			|		END,
			|		RoomRatePrices12.Currency,
			|		RoomRatePrices12.MinimumQuantity,
			|		RoomRatePrices12.VATRate,
			|		RoomRatePrices12.QuantityCalculationRule,
			|		RoomRatePrices12.QuantityCalculationRuleType,
			|		RoomRatePrices12.IsRoomRevenue,
			|		RoomRatePrices12.IsInPrice,
			|		RoomRatePrices12.IsPricePerPerson,
			|		RoomRatePrices12.ChargeToEachGuestSeparately,
			|		RoomRatePrices12.Unit,
			|		RoomRatePrices12.RoomRevenueAmountsOnly
			|	FROM
			|		RawRoomRatePrices AS RoomRatePrices12
			|			INNER JOIN FormulasForPriceTags AS FormulasForPriceTags
			|			ON RoomRatePrices12.ClientType = FormulasForPriceTags.ClientType
			|				AND RoomRatePrices12.PriceTag = FormulasForPriceTags.PriceTag
			|				AND RoomRatePrices12.CalendarDayType = FormulasForPriceTags.CalendarDayType
			|				AND (FormulasForPriceTags.Service = VALUE(Catalog.Services.EmptyRef))
			|				AND (FormulasForPriceTags.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
			|				AND (FormulasForPriceTags.RoomClass = VALUE(Catalog.RoomTypeClasses.EmptyRef))
			|				AND (FormulasForPriceTags.AccommodationType = VALUE(Catalog.AccommodationTypes.EmptyRef))) AS RoomRatePricesJoinedWithFormulas
			|
			|INDEX BY
			|	RoomRatePricesJoinedWithFormulas.AccountingDate,
			|	RoomRatePricesJoinedWithFormulas.RoomRate,
			|	RoomRatePricesJoinedWithFormulas.SetRoomRatePrices,
			|	RoomRatePricesJoinedWithFormulas.LineNumber,
			|	RoomRatePricesJoinedWithFormulas.Service,
			|	RoomRatePricesJoinedWithFormulas.ClientType,
			|	RoomRatePricesJoinedWithFormulas.PriceTag
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	RoomRatePrices.AccountingDate AS AccountingDate,
			|	RoomRatePrices.RoomRate AS RoomRate,
			|	RoomRatePrices.CalendarDayType AS CalendarDayType,
			|	RoomRatePrices.PriceTag AS PriceTag,
			|	RoomRatePrices.ClientType AS ClientType,
			|	RoomRatePrices.RoomType AS RoomType,
			|	RoomRatePrices.RoomTypeRoomClass AS RoomTypeRoomClass,
			|	RoomRatePrices.AccommodationType AS AccommodationType,
			|	RoomRatePrices.SetRoomRatePrices AS SetRoomRatePrices,
			|	RoomRatePrices.SortCode AS SortCode,
			|	RoomRatePrices.LineNumber AS LineNumber,
			|	RoomRatePrices.Hotel AS Hotel,
			|	RoomRatePrices.Service AS Service,
			|	CASE
			|		WHEN RoomRatePricesJoinedWithFormulas.Price IS NULL
			|			THEN RoomRatePrices.Price
			|		ELSE RoomRatePricesJoinedWithFormulas.Price
			|	END AS Price,
			|	RoomRatePrices.Currency AS Currency,
			|	RoomRatePrices.MinimumQuantity AS MinimumQuantity,
			|	RoomRatePrices.VATRate AS VATRate,
			|	RoomRatePrices.QuantityCalculationRule AS QuantityCalculationRule,
			|	RoomRatePrices.QuantityCalculationRuleType AS QuantityCalculationRuleType,
			|	RoomRatePrices.IsRoomRevenue AS IsRoomRevenue,
			|	RoomRatePrices.IsInPrice AS IsInPrice,
			|	RoomRatePrices.IsPricePerPerson AS IsPricePerPerson,
			|	RoomRatePrices.ChargeToEachGuestSeparately AS ChargeToEachGuestSeparately,
			|	RoomRatePrices.Unit AS Unit,
			|	RoomRatePrices.RoomRevenueAmountsOnly AS RoomRevenueAmountsOnly
			|INTO RoomRatePrices
			|FROM
			|	RawRoomRatePrices AS RoomRatePrices
			|		LEFT JOIN RoomRatePricesJoinedWithFormulas AS RoomRatePricesJoinedWithFormulas
			|		ON RoomRatePrices.AccountingDate = RoomRatePricesJoinedWithFormulas.AccountingDate
			|			AND RoomRatePrices.RoomRate = RoomRatePricesJoinedWithFormulas.RoomRate
			|			AND RoomRatePrices.SetRoomRatePrices = RoomRatePricesJoinedWithFormulas.SetRoomRatePrices
			|			AND RoomRatePrices.LineNumber = RoomRatePricesJoinedWithFormulas.LineNumber
			|			AND RoomRatePrices.Service = RoomRatePricesJoinedWithFormulas.Service
			|			AND RoomRatePrices.ClientType = RoomRatePricesJoinedWithFormulas.ClientType
			|			AND RoomRatePrices.PriceTag = RoomRatePricesJoinedWithFormulas.PriceTag
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|DROP RawRoomRatePrices
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|DROP RoomRatePricesJoinedWithFormulas
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	ServicePackages.ServicePackage AS ServicePackage,
			|	ServicePackages.Quantity AS Quantity,
			|	ServicePackages.DateFrom AS DateFrom,
			|	ServicePackages.DateTo AS DateTo,
			|	ServicePackages.PacketPriceIsIncludedInRoomRate AS PacketPriceIsIncludedInRoomRate,
			|	ServicePackages.IsExtraPackage AS IsExtraPackage,
			|	ServicePackages.IsMealBoardTerm AS IsMealBoardTerm,
			|	ServicePackages.IsPerPerson AS IsPerPerson,
			|	ServicePackages.UsageType AS UsageType,
			|	ServicePackages.DateValidFrom AS DateValidFrom,
			|	ServicePackages.DateValidTo AS DateValidTo
			|INTO ServicePackages
			|FROM
			|	&qServicePackages AS ServicePackages
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	ServicePackagePeriods.ServicePackage AS ServicePackage,
			|	MAX(ServicePackagePeriods.Period) AS ActivePeriod
			|INTO ServicePackagesActivePeriods
			|FROM
			|	InformationRegister.ServicePackageRecords.SliceLast(&qDate, ) AS ServicePackagePeriods
			|		INNER JOIN ServicePackages AS ServicePackages
			|		ON (ServicePackages.ServicePackage = ServicePackagePeriods.ServicePackage)
			|
			|GROUP BY
			|	ServicePackagePeriods.ServicePackage
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	RoomRatesSliceLast.SetRoomRateFormulas AS Recorder,
			|	RoomRatesSliceLast.RoomRate AS RoomRate
			|INTO ActiveSetRoomRateFormulas
			|FROM
			|	InformationRegister.RoomRates.SliceLast(
			|			&qDate,
			|			RoomRate = &qRoomRate
			|				AND Hotel = &qHotel
			|				AND IsFormula) AS RoomRatesSliceLast
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	RoomRateFormulas.RoomRate.BasedOnRoomRate AS BasedOnRoomRate,
			|	RoomRateFormulas.RoomRate.BasedOnPriceTag AS BasedOnPriceTag,
			|	RoomRateFormulas.RoomRate AS RoomRate,
			|	RoomRateFormulas.Hotel AS Hotel,
			|	RoomRateFormulas.IsFormula AS IsFormula,
			|	RoomRateFormulas.Service AS Service,
			|	RoomRateFormulas.RoomType AS RoomType,
			|	RoomRateFormulas.AccommodationType AS AccommodationType,
			|	RoomRateFormulas.ClientType AS ClientType,
			|	RoomRateFormulas.CalendarDayType AS CalendarDayType,
			|	RoomRateFormulas.Recorder AS Recorder,
			|	RoomRateFormulas.Period AS Period,
			|	RoomRateFormulas.BracketsConstant AS BracketsConstant,
			|	RoomRateFormulas.Constant AS Constant,
			|	RoomRateFormulas.Multiplier AS Multiplier,
			|	RoomRateFormulas.ReplaceWithService AS ReplaceWithService
			|INTO RoomRateFormulas
			|FROM
			|	InformationRegister.RoomRateFormulas AS RoomRateFormulas
			|		INNER JOIN ActiveSetRoomRateFormulas AS ActiveSetRoomRateFormulas
			|		ON RoomRateFormulas.Recorder = ActiveSetRoomRateFormulas.Recorder
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT DISTINCT
			|	ActivePriceTags.PriceTag AS PriceTag
			|INTO ActivePriceTags
			|FROM
			|	InformationRegister.RoomRatePrices AS ActivePriceTags
			|		INNER JOIN Orders AS Orders
			|		ON ActivePriceTags.SetRoomRatePrices = Orders.SetRoomRatePrices
			|			AND ActivePriceTags.CalendarDayType = Orders.CalendarDayType
			|			AND ActivePriceTags.PriceTag = Orders.PriceTag
			|WHERE
			|	ActivePriceTags.RoomRate = &qPricesRoomRate
			|	AND ActivePriceTags.ClientType = &qClientType
			|	AND (&qPriceTagIsFilled
			|				AND ActivePriceTags.PriceTag = &qPriceTag
			|			OR NOT &qPriceTagIsFilled)
			|	AND (ActivePriceTags.RoomType = &qRoomType
			|			OR ActivePriceTags.RoomType = &qEmptyRoomTypeRef
			|			OR &qRoomTypeIsUndefined)
			|	AND (ActivePriceTags.AccommodationType = &qAccommodationType
			|			OR ActivePriceTags.AccommodationType = &qEmptyAccommodationTypeRef
			|			OR &qAccommodationTypeIsUndefined)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	RoomRatePrices.SetRoomRatePrices AS Recorder,
			|	RoomRatePrices.LineNumber AS LineNumber,
			|	RoomRatePrices.Hotel AS Hotel,
			|	RoomRatePrices.RoomRate AS RoomRate,
			|	RoomRatePrices.CalendarDayType AS CalendarDayType,
			|	RoomRatePrices.PriceTag AS PriceTag,
			|	RoomRatePrices.ClientType AS ClientType,
			|	RoomRatePrices.RoomType AS RoomType,
			|	RoomRatePrices.RoomType.SortCode AS RoomTypeSortCode,
			|	RoomRatePrices.AccommodationType AS AccommodationType,
			|	RoomRatePrices.AccommodationType.SortCode AS AccommodationTypeSortCode,
			|	RoomRatePrices.SetRoomRatePrices AS SetRoomRatePrices,
			|	RoomRatePrices.SortCode AS SortCode,
			|	CASE
			|		WHEN RoomRateFormulas.ReplaceWithService.Code IS NULL
			|			THEN RoomRatePrices.Service
			|		ELSE RoomRateFormulas.ReplaceWithService
			|	END AS Service,
			|	CASE
			|		WHEN RoomRateFormulas.ReplaceWithService.Code IS NULL
			|			THEN RoomRatePrices.Unit
			|		ELSE RoomRateFormulas.ReplaceWithService.Unit
			|	END AS Unit,
			|	RoomRatePrices.Service AS PricesService,
			|	RoomRatePrices.Currency AS Currency,
			|	RoomRatePrices.MinimumQuantity AS MinimumQuantity,
			|	RoomRatePrices.VATRate AS VATRate,
			|	RoomRatePrices.QuantityCalculationRule AS QuantityCalculationRule,
			|	RoomRatePrices.IsRoomRevenue AS IsRoomRevenue,
			|	RoomRatePrices.IsInPrice AS IsInPrice,
			|	RoomRatePrices.IsPricePerPerson AS IsPricePerPerson,
			|	RoomRatePrices.RoomRevenueAmountsOnly AS RoomRevenueAmountsOnly,
			|	RoomRatePrices.AccountingDate AS AccountingDate,
			|	0 AS AccountingDayNumber,
			|	&qEmptyString AS Remarks,
			|	NULL AS ServicePackage,
			|	&qEmptyDate AS ServicePackageDateValidFrom,
			|	&qEmptyDate AS ServicePackageDateValidTo,
			|	&qEmptyDate AS ServicePackagePeriodFrom,
			|	&qEmptyDate AS ServicePackagePeriodTo,
			|	RoomRatePrices.SetRoomRatePrices.PointInTime AS PointInTime,
			|	FALSE AS PacketPriceIsIncludedInRoomRate,
			|	UNDEFINED AS ServicePackageUsageType,
			|	&qEmptyDate AS ServicePackageDateFrom,
			|	&qEndOfTime AS ServicePackageDateTo,
			|	(RoomRatePrices.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0) AS Price,
			|	1 AS Quantity,
			|	CASE
			|		WHEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons4Reservation, 0) > 0
			|				AND RoomRatePrices.IsPricePerPerson
			|			THEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons4Reservation, 0)
			|		WHEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons, 0) > 0
			|			THEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons, 0)
			|		ELSE 1
			|	END AS NumberOfPersons,
			|	CASE
			|		WHEN RoomRatePrices.IsRoomRevenue
			|			THEN CASE
			|					WHEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons4Reservation, 0) > 0
			|							AND RoomRatePrices.IsPricePerPerson
			|						THEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons4Reservation, 0)
			|					WHEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons, 0) > 0
			|						THEN ISNULL(RoomRatePrices.AccommodationType.NumberOfPersons, 0)
			|					ELSE 1
			|				END
			|		ELSE 0
			|	END AS NumberOfPersonsInRoom,
			|	CASE
			|		WHEN RoomRatePrices.IsRoomRevenue
			|			THEN ISNULL(RoomRatePrices.AccommodationType.NumberOfRooms, 0)
			|		ELSE 0
			|	END AS NumberOfRooms,
			|	CASE
			|		WHEN RoomRatePrices.IsRoomRevenue
			|			THEN ISNULL(RoomRatePrices.AccommodationType.NumberOfBeds, 0)
			|		ELSE 0
			|	END AS NumberOfBeds,
			|	CASE
			|		WHEN RoomRatePrices.IsRoomRevenue
			|			THEN ISNULL(RoomRatePrices.AccommodationType.NumberOfAdditionalBeds, 0)
			|		ELSE 0
			|	END AS NumberOfAdditionalBeds
			|FROM
			|	RoomRatePrices AS RoomRatePrices
			|		LEFT JOIN RoomRateFormulas AS RoomRateFormulas
			|		ON RoomRatePrices.RoomRate = RoomRateFormulas.BasedOnRoomRate
			|			AND RoomRatePrices.Hotel = RoomRateFormulas.Hotel
			|			AND (NOT RoomRateFormulas.IsFormula
			|				OR RoomRateFormulas.IsFormula
			|					AND RoomRatePrices.RoomType = RoomRateFormulas.RoomType
			|					AND RoomRatePrices.ClientType = RoomRateFormulas.ClientType
			|					AND RoomRatePrices.AccommodationType = RoomRateFormulas.AccommodationType
			|					AND (RoomRatePrices.CalendarDayType = RoomRateFormulas.CalendarDayType
			|						OR RoomRateFormulas.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef))
			|					AND (RoomRatePrices.Service = RoomRateFormulas.Service
			|						OR RoomRateFormulas.Service = VALUE(Catalog.Services.EmptyRef)))
			|			AND (RoomRateFormulas.BasedOnPriceTag = VALUE(Catalog.PriceTags.EmptyRef)
			|				OR RoomRatePrices.PriceTag = RoomRateFormulas.BasedOnPriceTag
			|					AND RoomRateFormulas.BasedOnPriceTag <> VALUE(Catalog.PriceTags.EmptyRef))
			|WHERE
			|	&qFilterByCalendarDayTypes
			|	AND (&qPriceTagIsFilled
			|				AND RoomRatePrices.PriceTag = &qPriceTag
			|			OR NOT &qPriceTagIsFilled)
			|	AND (RoomRatePrices.RoomType = &qRoomType
			|			OR RoomRatePrices.RoomType = &qEmptyRoomTypeRef
			|			OR &qRoomTypeIsUndefined)
			|	AND (RoomRatePrices.AccommodationType = &qAccommodationType
			|			OR RoomRatePrices.AccommodationType = &qEmptyAccommodationTypeRef
			|			OR &qAccommodationTypeIsUndefined)
			|	AND (NOT &qMinimizeOutput
			|			OR &qMinimizeOutput
			|				AND (RoomRatePrices.IsRoomRevenue
			|					OR NOT RoomRatePrices.IsRoomRevenue
			|						AND RoomRatePrices.IsInPrice
			|						AND RoomRatePrices.Price <> 0))
			|
			|UNION ALL
			|
			|SELECT
			|	&qEmptySetRoomRatePricesRef,
			|	PackageServicesForPriceTags.RowNumber,
			|	&qHotel,
			|	&qRoomRate,
			|	PackageServicesForPriceTags.CalendarDayType,
			|	ISNULL(ActivePriceTagsList.PriceTag, VALUE(Catalog.PriceTags.EmptyRef)),
			|	PackageServicesForPriceTags.ClientType,
			|	PackageServicesForPriceTags.RoomType,
			|	0,
			|	PackageServicesForPriceTags.AccommodationType,
			|	PackageServicesForPriceTags.AccommodationType.SortCode,
			|	&qEmptySetRoomRatePricesRef,
			|	999999999,
			|	CASE
			|		WHEN RoomRateFormulas.ReplaceWithService.Code IS NULL
			|			THEN PackageServicesForPriceTags.Service
			|		ELSE RoomRateFormulas.ReplaceWithService
			|	END,
			|	CASE
			|		WHEN RoomRateFormulas.ReplaceWithService.Code IS NULL
			|			THEN PackageServicesForPriceTags.Unit
			|		ELSE RoomRateFormulas.ReplaceWithService.Unit
			|	END,
			|	PackageServicesForPriceTags.Service,
			|	PackageServicesForPriceTags.Currency,
			|	0,
			|	PackageServicesForPriceTags.VATRate,
			|	PackageServicesForPriceTags.QuantityCalculationRule,
			|	CASE
			|		WHEN ISNULL(PackageServicesForPriceTags.ServicePackage.IsMealBoardTerm, FALSE)
			|			THEN FALSE
			|		ELSE ISNULL(PackageServicesForPriceTags.Service.IsRoomRevenue, FALSE)
			|	END,
			|	PackageServicesForPriceTags.IsInPrice,
			|	PackageServicesForPriceTags.IsServicePerPerson,
			|	ISNULL(PackageServicesForPriceTags.Service.RoomRevenueAmountsOnly, FALSE),
			|	PackageServicesForPriceTags.AccountingDate,
			|	PackageServicesForPriceTags.AccountingDayNumber,
			|	PackageServicesForPriceTags.Remarks,
			|	PackageServicesForPriceTags.ServicePackage,
			|	ISNULL(ServicePackages.DateValidFrom, &qEmptyDate),
			|	ISNULL(ServicePackages.DateValidTo, &qEmptyDate),
			|	ISNULL(PackageServicesForPriceTags.PeriodFrom, &qEmptyDate),
			|	ISNULL(PackageServicesForPriceTags.PeriodTo, &qEmptyDate),
			|	NULL,
			|	ISNULL(ServicePackages.PacketPriceIsIncludedInRoomRate, FALSE),
			|	ServicePackages.UsageType,
			|	ServicePackages.DateFrom,
			|	ServicePackages.DateTo,
			|	(PackageServicesForPriceTags.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0),
			|	PackageServicesForPriceTags.Quantity * ServicePackages.Quantity,
			|	CASE
			|		WHEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfPersons4Reservation, 0) > 0
			|				AND PackageServicesForPriceTags.IsServicePerPerson
			|			THEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfPersons4Reservation, 0)
			|		WHEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfPersons, 0) > 0
			|			THEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfPersons, 0)
			|		ELSE 1
			|	END,
			|	CASE
			|		WHEN ISNULL(PackageServicesForPriceTags.Service.IsRoomRevenue, FALSE)
			|				AND NOT ISNULL(PackageServicesForPriceTags.ServicePackage.IsMealBoardTerm, FALSE)
			|			THEN CASE
			|					WHEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfPersons4Reservation, 0) > 0
			|							AND PackageServicesForPriceTags.IsServicePerPerson
			|						THEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfPersons4Reservation, 0)
			|					WHEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfPersons, 0) > 0
			|						THEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfPersons, 0)
			|					ELSE 1
			|				END
			|		ELSE 0
			|	END,
			|	CASE
			|		WHEN ISNULL(PackageServicesForPriceTags.Service.IsRoomRevenue, FALSE)
			|				AND NOT ISNULL(ServicePackages.IsMealBoardTerm, FALSE)
			|			THEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfRooms, 0)
			|		ELSE 0
			|	END,
			|	CASE
			|		WHEN ISNULL(PackageServicesForPriceTags.Service.IsRoomRevenue, FALSE)
			|				AND NOT ISNULL(ServicePackages.IsMealBoardTerm, FALSE)
			|			THEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfBeds, 0)
			|		ELSE 0
			|	END,
			|	CASE
			|		WHEN ISNULL(PackageServicesForPriceTags.Service.IsRoomRevenue, FALSE)
			|				AND NOT ISNULL(ServicePackages.IsMealBoardTerm, FALSE)
			|			THEN ISNULL(PackageServicesForPriceTags.AccommodationType.NumberOfAdditionalBeds, 0)
			|		ELSE 0
			|	END
			|FROM
			|	InformationRegister.ServicePackageRecords AS PackageServicesForPriceTags
			|		INNER JOIN ServicePackages AS ServicePackages
			|		ON (ServicePackages.ServicePackage = PackageServicesForPriceTags.ServicePackage)
			|		INNER JOIN ServicePackagesActivePeriods AS ServicePackagesActivePeriods
			|		ON PackageServicesForPriceTags.ServicePackage = ServicePackagesActivePeriods.ServicePackage
			|			AND PackageServicesForPriceTags.Period = ServicePackagesActivePeriods.ActivePeriod
			|		LEFT JOIN ActivePriceTags AS ActivePriceTagsList
			|		ON (TRUE)
			|		LEFT JOIN RoomRateFormulas AS RoomRateFormulas
			|		ON (RoomRateFormulas.RoomRate = &qRoomRate)
			|			AND (RoomRateFormulas.Hotel = &qHotel)
			|			AND (RoomRateFormulas.IsFormula)
			|			AND PackageServicesForPriceTags.Service = RoomRateFormulas.Service
			|			AND PackageServicesForPriceTags.RoomType = RoomRateFormulas.RoomType
			|			AND PackageServicesForPriceTags.ClientType = RoomRateFormulas.ClientType
			|			AND (PackageServicesForPriceTags.AccommodationType = RoomRateFormulas.AccommodationType
			|				OR PackageServicesForPriceTags.AccommodationType = VALUE(Catalog.AccommodationTypes.EmptyRef))
			|			AND (PackageServicesForPriceTags.CalendarDayType = RoomRateFormulas.CalendarDayType
			|				OR RoomRateFormulas.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef))
			|WHERE
			|	ServicePackages.DateValidFrom <= &qCheckInDate
			|	AND (ENDOFPERIOD(ServicePackages.DateValidTo, DAY) >= &qCheckInDate
			|			OR ServicePackages.DateValidTo = &qEmptyDate)
			|	AND PackageServicesForPriceTags.ClientType = &qClientType
			|	AND (PackageServicesForPriceTags.RoomType = &qRoomType
			|			OR PackageServicesForPriceTags.RoomType = &qEmptyRoomTypeRef
			|			OR &qRoomTypeIsUndefined)
			|	AND (PackageServicesForPriceTags.RoomClass = &qRoomClass
			|			OR PackageServicesForPriceTags.RoomClass = &qEmptyRoomClassRef
			|			OR &qRoomTypeIsUndefined)
			|	AND (PackageServicesForPriceTags.AccommodationType = &qAccommodationType
			|			OR PackageServicesForPriceTags.AccommodationType = &qEmptyAccommodationTypeRef
			|			OR &qAccommodationTypeIsUndefined)
			|	AND (NOT &qAccommodationPeriodIsSet
			|			OR &qAccommodationPeriodIsSet
			|				AND (PackageServicesForPriceTags.CalendarDayType IN (&qCalendarDayTypesList)
			|					OR PackageServicesForPriceTags.CalendarDayType = &qEmptyCalendarDayType))
			|	AND PackageServicesForPriceTags.Service IS NOT NULL 
			|	AND PackageServicesForPriceTags.Service <> &qEmptyService
			|	AND (NOT &qMinimizeOutput
			|			OR &qMinimizeOutput
			|				AND (PackageServicesForPriceTags.IsInPrice
			|					AND PackageServicesForPriceTags.Price <> 0))
			|ORDER BY " + 
			?(pSortByPointInTime, "PointInTime DESC, ", "") + "
			|	SortCode,
			|	LineNumber";
			vQry.SetParameter("qAccommodationService", pRoomRate.AccommodationService);
			vQry.SetParameter("qLateCheckOutService", pRoomRate.LateCheckOutService);
			vQry.SetParameter("qEarlyCheckInService", pRoomRate.EarlyCheckInService);
			vQry.SetParameter("qCalendar", pRoomRate.Calendar);
			vQry.SetParameter("qOrders", vOrders);
			vQry.SetParameter("qServicePackages", vServicePackages);
			vQry.SetParameter("qCalendarDayTypesList", vDayTypesList);
			vQry.SetParameter("qHotel", vHotel);
			vQry.SetParameter("qDefaultVATRate", vHotel.Company.VATRate);
			vQry.SetParameter("qRoomRate", pRoomRate);
			vQry.SetParameter("qPricesRoomRate", ?(ValueIsFilled(pRoomRate.BasedOnRoomRate), pRoomRate.BasedOnRoomRate, pRoomRate));
			vQry.SetParameter("qPriceTagType", pRoomRate.PriceTagType);
			vQry.SetParameter("qPriceTag", ?(pPriceTag = Undefined, Catalogs.PriceTags.EmptyRef(), pPriceTag));
			vQry.SetParameter("qPriceTagIsFilled", ?(pPriceTag = Undefined, False, True));
			vQry.SetParameter("qClientType", pClientType);
			vQry.SetParameter("qRoomType", pRoomType);
			vQry.SetParameter("qEmptyRoomTypeRef", Catalogs.RoomTypes.EmptyRef());
			vQry.SetParameter("qRoomTypeIsUndefined", ?(pRoomType = Undefined, True, False));
			vQry.SetParameter("qRoomClass", ?(ValueIsFilled(pRoomType) And Not pRoomType.IsFolder, pRoomType.RoomClass, Catalogs.RoomTypeClasses.EmptyRef()));
			vQry.SetParameter("qEmptyRoomClassRef", Catalogs.RoomTypeClasses.EmptyRef());
			vQry.SetParameter("qAccommodationType", pAccommodationType);
			vQry.SetParameter("qEmptyAccommodationTypeRef", Catalogs.AccommodationTypes.EmptyRef());
			vQry.SetParameter("qAccommodationTypeIsUndefined", ?(pAccommodationType = Undefined, True, False));
			vQry.SetParameter("qEmptySetRoomRatePricesRef", Documents.SetRoomRatePrices.EmptyRef());
			vQry.SetParameter("qDate", ?(ValueIsFilled(vPriceCalculationDate), vPriceCalculationDate, pDate));
			vQry.SetParameter("qCheckInDate", ?(ValueIsFilled(pCheckInDate), BegOfDay(pCheckInDate), BegOfDay(pDate)));
			vQry.SetParameter("qCheckOutDate", ?(ValueIsFilled(pCheckOutDate), BegOfDay(pCheckOutDate), BegOfDay(pDate)));
			vQry.SetParameter("qAccommodationPeriodIsSet", vAccommodationPeriodIsSet);
			vQry.SetParameter("qMinimizeOutput", pMinimizeOutput);
			vQry.SetParameter("qEmptyDate", '00010101');
			vQry.SetParameter("qEndOfTime", '39991231');
			vQry.SetParameter("qEmptyString", "");
			vQry.SetParameter("qEmptyService", Catalogs.Services.EmptyRef());
			vQry.SetParameter("qEmptyCalendarDayType", Catalogs.CalendarDayTypes.EmptyRef());
			If vDayTypes.Count() > 0 Then
				For i = 0 To (vDayTypes.Count() - 1) Do
					vDayTypesRow = vDayTypes.Get(i);
					vQry.SetParameter("qCalendarDayType" + Format(i, "NFD=0; NZ=; NG="), vDayTypesRow.CalendarDayType);
				EndDo;
			EndIf;
			vQry.Text = StrReplace(vQry.Text, "&qFilterByCalendarDayTypes", vFilterByCalendarDayTypes);
			vPrices = vQry.Execute().Unload();
		EndIf;
	EndIf;
	
	vReturnStructure = New Structure("Prices, PriceCalculationDate", vPrices, vPriceCalculationDate);
	Return New FixedStructure(vReturnStructure);
EndFunction // GetRoomRatePrices

// -----------------------------------------------------------------------------
Function GetRoomRateServicePackagesList(pRoomRate, pServicePackagesList = Undefined, pMinimizeOutput = False) Export
	vPackagesList = New ValueList();
	If ValueIsFilled(pRoomRate.ServicePackage) And 
	  (Not pMinimizeOutput Or pMinimizeOutput And pRoomRate.ServicePackage.UsageType <> Enums.ServicePackageUsageType.SubtractFromRoomRatePrice) Then
		vPackagesList.Add(pRoomRate.ServicePackage);
	EndIf;
	For Each vServicePackagesRow In pRoomRate.ServicePackages Do
		If ValueIsFilled(vServicePackagesRow.ServicePackage) And 
		  (Not pMinimizeOutput Or pMinimizeOutput And Not vServicePackagesRow.PacketPriceIsIncludedInRoomRate And vServicePackagesRow.ServicePackage.UsageType <> Enums.ServicePackageUsageType.SubtractFromRoomRatePrice) Then
			If vPackagesList.FindByValue(vServicePackagesRow.ServicePackage) = Undefined Then
				vPackagesList.Add(vServicePackagesRow.ServicePackage);
			EndIf;
		EndIf;
	EndDo;
	If pServicePackagesList <> Undefined Then
		For Each vServicePackagesListItem In pServicePackagesList Do
			vServicePackage = vServicePackagesListItem.Value;
			If ValueIsFilled(vServicePackage) And
			  (Not pMinimizeOutput Or pMinimizeOutput And vServicePackage.UsageType <> Enums.ServicePackageUsageType.SubtractFromRoomRatePrice) Then
				vPackagesList.Add(vServicePackage);
			EndIf;
		EndDo;
	EndIf;
	i = 1;
	vPackagesStruct = New Structure();
	For Each vPackagesListItem In vPackagesList Do
		vPackagesStruct.Insert("ServicePackage" + Format(i, "ND=10; NFD=; NG="), vPackagesListItem.Value);
		i = i + 1;
	EndDo;
	Return New FixedStructure(vPackagesStruct);
EndFunction // GetRoomRateServicePackagesList

// -----------------------------------------------------------------------------
Function GetVATTaxRate(pVATRate, pDate) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	VATRatesHistorySliceLast.TaxRate
	|FROM
	|	InformationRegister.VATRatesHistory.SliceLast(&qDate, VATRate = &qVATRate) AS VATRatesHistorySliceLast";
	vQry.SetParameter("qVATRate", pVATRate);
	vQry.SetParameter("qDate", New Boundary(pDate, BoundaryType.Including));
	vRes = vQry.Execute().Unload();
	If vRes.Count() > 0 Then
		vResRow = vRes.Get(0);
		If vResRow.TaxRate = Null Then
			Return pVATRate.TaxRate;
		Else
			Return vResRow.TaxRate;
		EndIf;
	Else
		Return pVATRate.TaxRate;
	EndIf;
EndFunction // GetVATTaxRate

// -----------------------------------------------------------------------------
Function GetServiceBreakdownList(pService, pDate, pHotel, pRoomRate, pRoomType, pAccommodationType) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	BreakDownListSettings.Service AS Service,
	|	BreakDownListSettings.Period AS Period,
	|	BreakDownListSettings.Hotel AS Hotel,
	|	BreakDownListSettings.RoomRateType AS RoomRateType,
	|	BreakDownListSettings.RoomRate AS RoomRate,
	|	BreakDownListSettings.RoomType AS RoomType,
	|	BreakDownListSettings.AccommodationType AS AccommodationType,
	|	BreakDownListSettings.RuleNumber AS RuleNumber,
	|	BreakDownListSettings.Item AS Item,
	|	CASE
	|		WHEN BreakDownListSettings.BreakdownListFormula <> VALUE(Catalog.BreakdownListFormulas.EmptyRef)
	|			THEN BreakDownListSettings.BreakdownListFormula.IsTax
	|		ELSE BreakDownListSettings.IsTax
	|	END AS IsTax,
	|	CASE
	|		WHEN BreakDownListSettings.BreakdownListFormula <> VALUE(Catalog.BreakdownListFormulas.EmptyRef)
	|			THEN BreakDownListSettings.BreakdownListFormula.VATRate
	|		ELSE BreakDownListSettings.VATRate
	|	END AS VATRate,
	|	CASE
	|		WHEN BreakDownListSettings.BreakdownListFormula <> VALUE(Catalog.BreakdownListFormulas.EmptyRef)
	|			THEN BreakDownListSettings.BreakdownListFormula.Price
	|		ELSE BreakDownListSettings.Price
	|	END AS Price,
	|	CASE
	|		WHEN BreakDownListSettings.BreakdownListFormula <> VALUE(Catalog.BreakdownListFormulas.EmptyRef)
	|			THEN BreakDownListSettings.BreakdownListFormula.Currency
	|		ELSE BreakDownListSettings.Currency
	|	END AS Currency,
	|	CASE
	|		WHEN BreakDownListSettings.BreakdownListFormula <> VALUE(Catalog.BreakdownListFormulas.EmptyRef)
	|			THEN BreakDownListSettings.BreakdownListFormula.PriceCalculationFormula
	|		ELSE BreakDownListSettings.PriceCalculationFormula
	|	END AS PriceCalculationFormula,
	|	CASE
	|		WHEN BreakDownListSettings.BreakdownListFormula <> VALUE(Catalog.BreakdownListFormulas.EmptyRef)
	|			THEN BreakDownListSettings.BreakdownListFormula.Quantity
	|		ELSE BreakDownListSettings.Quantity
	|	END AS Quantity,
	|	CASE
	|		WHEN BreakDownListSettings.BreakdownListFormula <> VALUE(Catalog.BreakdownListFormulas.EmptyRef)
	|			THEN BreakDownListSettings.BreakdownListFormula.QuantityCalculationFormula
	|		ELSE BreakDownListSettings.QuantityCalculationFormula
	|	END AS QuantityCalculationFormula,
	|	CASE
	|		WHEN BreakDownListSettings.BreakdownListFormula <> VALUE(Catalog.BreakdownListFormulas.EmptyRef)
	|			THEN BreakDownListSettings.BreakdownListFormula.QuantityCalculationRule
	|		ELSE BreakDownListSettings.QuantityCalculationRule
	|	END AS QuantityCalculationRule,
	|	CASE
	|		WHEN BreakDownListSettings.BreakdownListFormula <> VALUE(Catalog.BreakdownListFormulas.EmptyRef)
	|			THEN BreakDownListSettings.BreakdownListFormula.ServiceDateShift
	|		ELSE BreakDownListSettings.ServiceDateShift
	|	END AS ServiceDateShift,
	|	CASE
	|		WHEN BreakDownListSettings.BreakdownListFormula <> VALUE(Catalog.BreakdownListFormulas.EmptyRef)
	|			THEN BreakDownListSettings.BreakdownListFormula.ServiceDateNumber
	|		ELSE BreakDownListSettings.ServiceDateNumber
	|	END AS ServiceDateNumber,
	|	CASE
	|		WHEN BreakDownListSettings.BreakdownListFormula <> VALUE(Catalog.BreakdownListFormulas.EmptyRef)
	|			THEN BreakDownListSettings.BreakdownListFormula.IsInRoomRevenue
	|		ELSE BreakDownListSettings.IsInRoomRevenue
	|	END AS IsInRoomRevenue,
	|	CASE
	|		WHEN BreakDownListSettings.BreakdownListFormula <> VALUE(Catalog.BreakdownListFormulas.EmptyRef)
	|			THEN BreakDownListSettings.BreakdownListFormula.IsNotInForecast
	|		ELSE BreakDownListSettings.IsNotInForecast
	|	END AS IsNotInForecast
	|FROM
	|	InformationRegister.BreakDownListSettings AS BreakDownListSettings
	|WHERE
	|	BreakDownListSettings.Service = &qService
	|	AND BreakDownListSettings.Period = &qDate
	|	AND (BreakDownListSettings.Hotel = &qHotel
	|			OR BreakDownListSettings.Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|	AND (BreakDownListSettings.RoomRateType = &qRoomRateType
	|			OR BreakDownListSettings.RoomRateType = VALUE(Catalog.RoomRateTypes.EmptyRef)
	|			OR BreakDownListSettings.RoomRateType = &qRoomRateTypeParent
	|				AND &qRoomRateTypeParentIsFilled)
	|	AND (BreakDownListSettings.RoomRate = &qRoomRate
	|			OR BreakDownListSettings.RoomRate = VALUE(Catalog.RoomRates.EmptyRef)
	|			OR BreakDownListSettings.RoomRate = &qRoomRateParent
	|				AND &qRoomRateParentIsFilled)
	|	AND (BreakDownListSettings.RoomType = &qRoomType
	|			OR BreakDownListSettings.RoomType = VALUE(Catalog.RoomTypes.EmptyRef)
	|			OR BreakDownListSettings.RoomType = &qRoomTypeParent
	|				AND &qRoomTypeParentIsFilled)
	|	AND (BreakDownListSettings.AccommodationType = &qAccommodationType
	|			OR BreakDownListSettings.AccommodationType = VALUE(Catalog.AccommodationTypes.EmptyRef)
	|			OR BreakDownListSettings.AccommodationType = &qAccommodationTypeParent
	|				AND &qAccommodationTypeParentIsFilled)
	|
	|ORDER BY
	|	ISNULL(BreakDownListSettings.Hotel.SortCode, 0),
	|	ISNULL(BreakDownListSettings.Hotel.Code, """"),
	|	ISNULL(BreakDownListSettings.Item.SortCode, 0) DESC,
	|	ISNULL(BreakDownListSettings.Item.Code, """") DESC,
	|	ISNULL(BreakDownListSettings.RoomRate.SortCode, 0) DESC,
	|	ISNULL(BreakDownListSettings.RoomRate.Description, """") DESC,
	|	ISNULL(BreakDownListSettings.RoomRateType.SortCode, 0) DESC,
	|	ISNULL(BreakDownListSettings.RoomRateType.Description, """") DESC,
	|	ISNULL(BreakDownListSettings.RoomType.SortCode, 0) DESC,
	|	ISNULL(BreakDownListSettings.RoomType.Description, """") DESC,
	|	ISNULL(BreakDownListSettings.AccommodationType.SortCode, 0) DESC,
	|	ISNULL(BreakDownListSettings.AccommodationType.Description, """") DESC,
	|	BreakDownListSettings.RuleNumber";
	vQry.SetParameter("qDate", pDate);
	vQry.SetParameter("qService", pService);
	vQry.SetParameter("qHotel", pHotel);
	If ValueIsFilled(pRoomRate) Then
		vQry.SetParameter("qRoomRateType", pRoomRate.RoomRateType);
		If ValueIsFilled(pRoomRate.RoomRateType) And ValueIsFilled(pRoomRate.RoomRateType.Parent) Then
			vQry.SetParameter("qRoomRateTypeParent", pRoomRate.RoomRateType.Parent);
			vQry.SetParameter("qRoomRateTypeParentIsFilled", True);
		Else
			vQry.SetParameter("qRoomRateTypeParent", Catalogs.RoomRateTypes.EmptyRef());
			vQry.SetParameter("qRoomRateTypeParentIsFilled", False);
		EndIf;
		vQry.SetParameter("qRoomRate", pRoomRate);
		If ValueIsFilled(pRoomRate) And ValueIsFilled(pRoomRate.Parent) Then
			vQry.SetParameter("qRoomRateParent", pRoomRate.Parent);
			vQry.SetParameter("qRoomRateParentIsFilled", True);
		Else
			vQry.SetParameter("qRoomRateParent", Catalogs.RoomRates.EmptyRef());
			vQry.SetParameter("qRoomRateParentIsFilled", False);
		EndIf;
	Else
		vQry.SetParameter("qRoomRateType", Catalogs.RoomRateTypes.EmptyRef());
		vQry.SetParameter("qRoomRateTypeParent", Catalogs.RoomRateTypes.EmptyRef());
		vQry.SetParameter("qRoomRateTypeParentIsFilled", False);
		vQry.SetParameter("qRoomRate", Catalogs.RoomRates.EmptyRef());
		vQry.SetParameter("qRoomRateParent", Catalogs.RoomRates.EmptyRef());
		vQry.SetParameter("qRoomRateParentIsFilled", False);
	EndIf;
	vQry.SetParameter("qRoomType", pRoomType);
	If ValueIsFilled(pRoomType) And ValueIsFilled(pRoomType.Parent) Then
		vQry.SetParameter("qRoomTypeParent", pRoomType.Parent);
		vQry.SetParameter("qRoomTypeParentIsFilled", True);
	Else
		vQry.SetParameter("qRoomTypeParent", Catalogs.RoomTypes.EmptyRef());
		vQry.SetParameter("qRoomTypeParentIsFilled", False);
	EndIf;
	vQry.SetParameter("qAccommodationType", pAccommodationType);
	If ValueIsFilled(pAccommodationType) And ValueIsFilled(pAccommodationType.Parent) Then
		vQry.SetParameter("qAccommodationTypeParent", pAccommodationType.Parent);
		vQry.SetParameter("qAccommodationTypeParentIsFilled", True);
	Else
		vQry.SetParameter("qAccommodationTypeParent", Catalogs.AccommodationTypes.EmptyRef());
		vQry.SetParameter("qAccommodationTypeParentIsFilled", False);
	EndIf;
	vBDLSettings = vQry.Execute().Unload();
	// Remove rule lines dublicated for the same item
	vCurItem = Undefined;
	vCurIsTax = False;
	vCurVATRate = Undefined;
	vCurPrice = 0;
	vCurCurrency = Undefined;
	vCurPriceCalculationFormula = Undefined;
	vCurQuantity = 0;
	vCurQuantityCalculationFormula = Undefined;
	vCurQuantityCalculationRule = Undefined;
	vCurServiceDateShift = 0;
	vCurServiceDateNumber = 0;
	vCurIsInRoomRevenue = False;
	vCurIsNotInForecast = False;
	i = 0;
	While i < vBDLSettings.Count() Do
		vBDLSettingsRow = vBDLSettings.Get(i);
		If vCurItem = vBDLSettingsRow.Item And 
		   vCurIsTax = vBDLSettingsRow.IsTax And 
		   vCurVATRate = vBDLSettingsRow.VATRate And 
		   vCurPrice = vBDLSettingsRow.Price And 
		   vCurCurrency = vBDLSettingsRow.Currency And 
		   vCurPriceCalculationFormula = vBDLSettingsRow.PriceCalculationFormula And 
		   vCurQuantity = vBDLSettingsRow.Quantity And 
		   vCurQuantityCalculationFormula = vBDLSettingsRow.QuantityCalculationFormula And 
		   vCurQuantityCalculationRule = vBDLSettingsRow.QuantityCalculationRule And 
		   vCurServiceDateShift = vBDLSettingsRow.ServiceDateShift And 
		   vCurServiceDateNumber = vBDLSettingsRow.ServiceDateNumber And 
		   vCurIsInRoomRevenue = vBDLSettingsRow.IsInRoomRevenue And 
		   vCurIsNotInForecast = vBDLSettingsRow.IsNotInForecast Then
			vBDLSettings.Delete(i);
		Else
			vCurItem = vBDLSettingsRow.Item;
			vCurIsTax = vBDLSettingsRow.IsTax;
			vCurVATRate = vBDLSettingsRow.VATRate;
			vCurPrice = vBDLSettingsRow.Price;
			vCurCurrency = vBDLSettingsRow.Currency;
			vCurPriceCalculationFormula = vBDLSettingsRow.PriceCalculationFormula;
			vCurQuantity = vBDLSettingsRow.Quantity;
			vCurQuantityCalculationFormula = vBDLSettingsRow.QuantityCalculationFormula;
			vCurQuantityCalculationRule = vBDLSettingsRow.QuantityCalculationRule;
			vCurServiceDateShift = vBDLSettingsRow.ServiceDateShift;
			vCurServiceDateNumber = vBDLSettingsRow.ServiceDateNumber;
			vCurIsInRoomRevenue = vBDLSettingsRow.IsInRoomRevenue;
			vCurIsNotInForecast = vBDLSettingsRow.IsNotInForecast;
			i = i + 1;
		EndIf;
	EndDo;
	vBDLSettings.Sort("RuleNumber");
	// Return
	vStruct = New Structure("BreakdownList", vBDLSettings);
	Return New FixedStructure(vStruct);
EndFunction // GetServiceBreakdownList

// -----------------------------------------------------------------------------
Function IsServiceInServiceGroup(pService, pServiceGroup) Export
	If Not ValueIsFilled(pService) Then
		Return False;
	EndIf;
	If Not ValueIsFilled(pServiceGroup) Then
		Return True;
	EndIf;
	If pServiceGroup.IncludeAll Then
		Return True;
	EndIf;
	vSrvGrpRow = pServiceGroup.Services.Find(pService, "Service");
	If vSrvGrpRow <> Undefined Then
		Return True;
	Else
		vParent = pService.Parent;
		While ValueIsFilled(vParent) Do
			vSrvGrpRow = pServiceGroup.Services.Find(vParent, "Service");
			If vSrvGrpRow <> Undefined Then
				Return True;
			EndIf;
			vParent = vParent.Parent;
		EndDo;
	EndIf;
	Return False;
EndFunction // IsServiceInServiceGroup

// -----------------------------------------------------------------------------
// Description: Returns list of service groups with service given
// Parameters: Service
// Return value: Value list of service groups
// -----------------------------------------------------------------------------
Function GetListOfServiceServiceGroups(pService) Export
	vServiceGroupsStruct = New Structure();
	// Run query to find all service groups with service choosen
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ServiceGroupsServices.Ref AS ServiceGroup
	|FROM
	|	Catalog.ServiceGroups.Services AS ServiceGroupsServices
	|WHERE
	|	NOT ServiceGroupsServices.Ref.DeletionMark
	|	AND NOT ServiceGroupsServices.Ref.IsFolder
	|	AND (ServiceGroupsServices.Service = &qService
	|			OR ServiceGroupsServices.Service = &qServiceParent
	|				AND &qServiceParent <> VALUE(Catalog.Services.EmptyRef)
	|			OR ServiceGroupsServices.Service = &qServiceParentParent
	|				AND &qServiceParentParent <> VALUE(Catalog.Services.EmptyRef))
	|
	|GROUP BY
	|	ServiceGroupsServices.Ref
	|
	|ORDER BY
	|	ServiceGroupsServices.Ref.SortCode";
	vQry.SetParameter("qService", pService);
	If ValueIsFilled(pService) And ValueIsFilled(pService.Parent) Then
		vQry.SetParameter("qServiceParent", pService.Parent);
	Else
		vQry.SetParameter("qServiceParent", Catalogs.Services.EmptyRef());
	EndIf;
	If ValueIsFilled(pService) And ValueIsFilled(pService.Parent) And ValueIsFilled(pService.Parent.Parent) Then
		vQry.SetParameter("qServiceParentParent", pService.Parent.Parent);
	Else
		vQry.SetParameter("qServiceParentParent", Catalogs.Services.EmptyRef());
	EndIf;
	vQryRes = vQry.Execute().Select();
	i = 1;
	While vQryRes.Next() Do
		vServiceGroupsStruct.Insert("ServiceGroup" + Format(i, "ND=10; NFD=; NG="), vQryRes.ServiceGroup);
		i = i + 1;
	EndDo;
	Return New FixedStructure(vServiceGroupsStruct);
EndFunction // GetListOfServiceServiceGroups

// -----------------------------------------------------------------------------
Function GetConfirmedSpecialOffersForReservation(pParentDoc, pHotel, pRoomRate, pRoomRateType, pClient, pClientType, pCustomer, pCustomerType, pGuestGroup, pSourceOfBusiness, pMarketingCode, pTripPurpose, pCheckInDate, pDuration, pCheckOutDate, pReservationDate, pRoomType, pAccommodationType = Undefined) Export
	vReservation = Undefined;
	vAccommodation = Undefined;
	If ValueIsFilled(pParentDoc) Then
		If TypeOf(pParentDoc) = Type("DocumentRef.Accommodation") Then
			vAccommodation = pParentDoc;
			If ValueIsFilled(vAccommodation.Reservation) Then
				vReservation = vAccommodation.Reservation;
			EndIf;
		Else
			vReservation = pParentDoc;
		EndIf;
	EndIf;
	vQry = New Query();
	vQry.Text = 
	"SELECT DISTINCT
	|	SpecialOffers.SpecialOffer AS SpecialOffer
	|FROM
	|	(SELECT
	|		SpecialOffersForReservations.SpecialOffer AS SpecialOffer
	|	FROM
	|		InformationRegister.SpecialOffersForReservations AS SpecialOffersForReservations
	|	WHERE
	|		SpecialOffersForReservations.OfferStatus = VALUE(Enum.OfferStatuses.Confirmed)
	|		AND (SpecialOffersForReservations.GuestGroup = &qGuestGroup
	|					AND SpecialOffersForReservations.GuestGroup <> VALUE(Catalog.GuestGroups.EmptyRef)
	|				OR SpecialOffersForReservations.ParentDoc = &qReservation
	|					AND NOT SpecialOffersForReservations.ParentDoc.Number IS NULL
	|				OR SpecialOffersForReservations.ParentDoc = &qAccommodation
	|					AND NOT SpecialOffersForReservations.ParentDoc.Number IS NULL)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		SpecialOffersForClients.SpecialOffer
	|	FROM
	|		InformationRegister.SpecialOffersForClients AS SpecialOffersForClients
	|	WHERE
	|		SpecialOffersForClients.OfferStatus = VALUE(Enum.OfferStatuses.Confirmed)
	|		AND (&qCustomerIsFilled
	|					AND SpecialOffersForClients.Customer = &qCustomer
	|				OR &qClientIsFilled
	|					AND SpecialOffersForClients.Client = &qClient)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AutoSpecialOffers.Ref
	|	FROM
	|		Catalog.SpecialOffers AS AutoSpecialOffers
	|	WHERE
	|		AutoSpecialOffers.ApplyAutomatically) AS SpecialOffers
	|		INNER JOIN InformationRegister.SpecialOfferPeriods AS SpecialOfferPeriods
	|		ON SpecialOffers.SpecialOffer = SpecialOfferPeriods.SpecialOffer
	|			AND (SpecialOfferPeriods.Hotel = &qHotel
	|				OR SpecialOfferPeriods.Hotel = &qHotelParent
	|					AND &qHotelParent <> VALUE(Catalog.Hotels.EmptyRef)
	|				OR SpecialOfferPeriods.Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|			AND (SpecialOfferPeriods.DateValidFrom <= &qDate)
	|			AND (SpecialOfferPeriods.DateValidTo = &qEmptyDate
	|				OR SpecialOfferPeriods.DateValidTo >= &qDate)
	|			AND (SpecialOfferPeriods.CheckInDateFrom <= &qCheckInDate)
	|			AND (SpecialOfferPeriods.CheckInDateTo = &qEmptyDate
	|				OR SpecialOfferPeriods.CheckInDateTo >= &qCheckInDate)
	|			AND (NOT SpecialOfferPeriods.ApplyToDatesInsidePeriodOfStayOnly
	|					AND SpecialOfferPeriods.PeriodOfStayFrom <= &qCheckInDate
	|					AND (SpecialOfferPeriods.PeriodOfStayTo = &qEmptyDate
	|						OR SpecialOfferPeriods.PeriodOfStayTo >= &qCheckOutDate)
	|				OR SpecialOfferPeriods.ApplyToDatesInsidePeriodOfStayOnly
	|					AND SpecialOfferPeriods.PeriodOfStayFrom < &qCheckOutDate
	|					AND (SpecialOfferPeriods.PeriodOfStayTo = &qEmptyDate
	|						OR SpecialOfferPeriods.PeriodOfStayTo > &qCheckInDate))
	|		INNER JOIN InformationRegister.SpecialOffersForRoomTypes AS SpecialOffersForRoomTypes
	|		ON SpecialOffers.SpecialOffer = SpecialOffersForRoomTypes.SpecialOffer
	|			AND (SpecialOffersForRoomTypes.Hotel = &qHotel
	|				OR SpecialOffersForRoomTypes.Hotel = &qHotelParent
	|				OR SpecialOffersForRoomTypes.Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|			AND (SpecialOffersForRoomTypes.RoomType = &qRoomType
	|					AND &qRoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
	|				OR SpecialOffersForRoomTypes.RoomClass = &qRoomClass
	|					AND &qRoomClass <> VALUE(Catalog.RoomTypeClasses.EmptyRef)
	|				OR SpecialOffersForRoomTypes.RoomType = VALUE(Catalog.RoomTypes.EmptyRef)
	|					AND SpecialOffersForRoomTypes.RoomClass = VALUE(Catalog.RoomTypeClasses.EmptyRef))
	|			AND (SpecialOffersForRoomTypes.AccommodationType = VALUE(Catalog.AccommodationTypes.EmptyRef)
	|				OR SpecialOffersForRoomTypes.AccommodationType IN HIERARCHY (&qAccommodationType)
	|					AND &qAccommodationType <> VALUE(Catalog.AccommodationTypes.EmptyRef))
	|		INNER JOIN InformationRegister.SpecialOffersForRates AS SpecialOffersForRates
	|		ON SpecialOffers.SpecialOffer = SpecialOffersForRates.SpecialOffer
	|			AND (SpecialOffersForRates.Hotel = &qHotel
	|				OR SpecialOffersForRates.Hotel = &qHotelParent
	|				OR SpecialOffersForRates.Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|			AND (SpecialOffersForRates.RoomRate = &qRoomRate
	|				OR SpecialOffersForRates.RoomRate = &qRoomRateParent
	|				OR SpecialOffersForRates.RoomRate = &qRoomRateParentParent
	|				OR SpecialOffersForRates.RoomRate = VALUE(Catalog.RoomRates.EmptyRef))
	|			AND (SpecialOffersForRates.RoomRateType = &qRoomRateType
	|				OR SpecialOffersForRates.RoomRateType = &qRoomRateTypeParent
	|				OR SpecialOffersForRates.RoomRateType = VALUE(Catalog.RoomRateTypes.EmptyRef))
	|			AND (SpecialOffersForRates.ClientType = &qClientType
	|				OR SpecialOffersForRates.ClientType = &qClientTypeParent
	|				OR SpecialOffersForRates.ClientType = VALUE(Catalog.ClientTypes.EmptyRef))
	|			AND (SpecialOffersForRates.CustomerType = &qCustomerType
	|				OR SpecialOffersForRates.CustomerType = &qCustomerTypeParent
	|				OR SpecialOffersForRates.CustomerType = VALUE(Catalog.CustomerTypes.EmptyRef))
	|			AND (SpecialOffersForRates.SourceOfBusiness = &qSourceOfBusiness
	|				OR SpecialOffersForRates.SourceOfBusiness = &qSourceOfBusinessParent
	|				OR SpecialOffersForRates.SourceOfBusiness = VALUE(Catalog.SourcesOfBusiness.EmptyRef))
	|			AND (SpecialOffersForRates.MarketingCode = &qMarketingCode
	|				OR SpecialOffersForRates.MarketingCode = &qMarketingCodeParent
	|				OR SpecialOffersForRates.MarketingCode = VALUE(Catalog.MarketingCodes.EmptyRef))
	|			AND (SpecialOffersForRates.TripPurpose = &qTripPurpose
	|				OR SpecialOffersForRates.TripPurpose = VALUE(Catalog.TripPurposes.EmptyRef))
	|			AND (&qDuration >= SpecialOffersForRates.MLOS
	|				OR SpecialOffersForRates.MLOS = 0)
	|			AND (&qDuration <= SpecialOffersForRates.MaxLOS
	|				OR SpecialOffersForRates.MaxLOS = 0)
	|			AND (&qDaysBeforeCheckIn >= SpecialOffersForRates.MinDaysBeforeCheckIn
	|				OR SpecialOffersForRates.MinDaysBeforeCheckIn = 0
	|				OR &qDaysBeforeCheckIn = -1)
	|			AND (&qDaysBeforeCheckIn <= SpecialOffersForRates.MaxDaysBeforeCheckIn
	|				OR SpecialOffersForRates.MaxDaysBeforeCheckIn = 0
	|				OR &qDaysBeforeCheckIn = -1)
	|WHERE
	|	NOT SpecialOffers.SpecialOffer.DeletionMark
	|	AND NOT SpecialOffers.SpecialOffer.IsFolder
	|
	|GROUP BY
	|	SpecialOffers.SpecialOffer
	|
	|ORDER BY
	|	SpecialOffers.SpecialOffer.Code";
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	vQry.SetParameter("qReservation", vReservation);
	vQry.SetParameter("qAccommodation", vAccommodation);
	vQry.SetParameter("qDuration", pDuration);
	vReservationDate = pReservationDate;
	If Not ValueIsFilled(vReservationDate) Then
		vReservationDate = CurrentSessionDate();
	EndIf;
	If ValueIsFilled(vReservationDate) And ValueIsFilled(pCheckInDate) And pCheckInDate > vReservationDate Then
		vQry.SetParameter("qDaysBeforeCheckIn", (BegOfDay(pCheckInDate) - BegOfDay(vReservationDate))/(24*3600));
	Else
		vQry.SetParameter("qDaysBeforeCheckIn", -1);
	EndIf;
	vQry.SetParameter("qCustomer", pCustomer);
	vQry.SetParameter("qCustomerIsFilled", ValueIsFilled(pCustomer));
	vQry.SetParameter("qClient", pClient);
	vQry.SetParameter("qClientIsFilled", ValueIsFilled(pClient));
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qDate", BegOfDay(vReservationDate));
	vQry.SetParameter("qCheckInDate", BegOfDay(pCheckInDate));
	vQry.SetParameter("qCheckOutDate", BegOfDay(pCheckOutDate));
	vQry.SetParameter("qHotel", pHotel);
	If ValueIsFilled(pHotel) And ValueIsFilled(pHotel.Parent) Then
		vQry.SetParameter("qHotelParent", pHotel.Parent);
	Else
		vQry.SetParameter("qHotelParent", Undefined);
	EndIf;
	vQry.SetParameter("qRoomType", pRoomType);
	If ValueIsFilled(pRoomType) And ValueIsFilled(pRoomType.RoomClass) Then
		vQry.SetParameter("qRoomClass", pRoomType.RoomClass);
	Else
		vQry.SetParameter("qRoomClass", Catalogs.RoomTypeClasses.EmptyRef());
	EndIf;
	vQry.SetParameter("qRoomRate", pRoomRate);
	If ValueIsFilled(pRoomRate) And ValueIsFilled(pRoomRate.Parent) Then
		vQry.SetParameter("qRoomRateParent", pRoomRate.Parent);
		If ValueIsFilled(pRoomRate.Parent.Parent) Then
			vQry.SetParameter("qRoomRateParentParent", pRoomRate.Parent.Parent);
		Else
			vQry.SetParameter("qRoomRateParentParent", Undefined);
		EndIf;
	Else
		vQry.SetParameter("qRoomRateParent", Undefined);
		vQry.SetParameter("qRoomRateParentParent", Undefined);
	EndIf;
	vQry.SetParameter("qRoomRateType", pRoomRateType);
	If ValueIsFilled(pRoomRateType) And ValueIsFilled(pRoomRateType.Parent) Then
		vQry.SetParameter("qRoomRateTypeParent", pRoomRateType.Parent);
	Else
		vQry.SetParameter("qRoomRateTypeParent", Undefined);
	EndIf;
	vQry.SetParameter("qClientType", pClientType);
	If ValueIsFilled(pClientType) And ValueIsFilled(pClientType.Parent) Then
		vQry.SetParameter("qClientTypeParent", pClientType.Parent);
	Else
		vQry.SetParameter("qClientTypeParent", Undefined);
	EndIf;
	vQry.SetParameter("qCustomerType", pCustomerType);
	If ValueIsFilled(pCustomerType) And ValueIsFilled(pCustomerType.Parent) Then
		vQry.SetParameter("qCustomerTypeParent", pCustomerType.Parent);
	Else
		vQry.SetParameter("qCustomerTypeParent", Undefined);
	EndIf;
	vQry.SetParameter("qSourceOfBusiness", pSourceOfBusiness);
	If ValueIsFilled(pSourceOfBusiness) And ValueIsFilled(pSourceOfBusiness.Parent) Then
		vQry.SetParameter("qSourceOfBusinessParent", pSourceOfBusiness.Parent);
	Else
		vQry.SetParameter("qSourceOfBusinessParent", Undefined);
	EndIf;
	vQry.SetParameter("qMarketingCode", pMarketingCode);
	If ValueIsFilled(pMarketingCode) And ValueIsFilled(pMarketingCode.Parent) Then
		vQry.SetParameter("qMarketingCodeParent", pMarketingCode.Parent);
	Else
		vQry.SetParameter("qMarketingCodeParent", Undefined);
	EndIf;
	vQry.SetParameter("qTripPurpose", pTripPurpose);
	vQry.SetParameter("qAccommodationType", ?(ValueIsFilled(pAccommodationType), pAccommodationType, Catalogs.AccommodationTypes.EmptyRef()));
	vOffers = vQry.Execute().Unload();
	Return vOffers;	
EndFunction // GetConfirmedSpecialOffersForReservation
