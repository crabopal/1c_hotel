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
	If Not ValueIsFilled(RoomRate) Then
		If ValueIsFilled(Hotel) Then
			RoomRate = Hotel.RoomRate;
		EndIf;
	EndIf;
	If Not ValueIsFilled(DateFrom) Then
		DateFrom = BegOfDay(CurrentSessionDate());
		DateTo = DateFrom;
	EndIf;
	If Not ValueIsFilled(PriceCalculationDate) Then
		PriceCalculationDate = CurrentSessionDate(); // For today
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetReportParametersPresentation() Export
	vParamPresentation = "";
	If Not ValueIsFilled(DateFrom) Or Not ValueIsFilled(DateTo) Then
		vParamPresentation = vParamPresentation + NStr("en='Report period is not set';ru='Период отчета не установлен';de='Berichtszeitraum nicht festgelegt'") + 
		                     ";" + Chars.LF;
	ElsIf DateFrom = DateTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период на '; en = 'Period on '; de = 'Periode '") + 
		                     Format(DateFrom, "DF=dd.MM.yyyy") + 
		                     ";" + Chars.LF;
	ElsIf DateFrom < DateTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период '; en = 'Period '; de = 'Periode '") + Format(DateFrom, "DF=dd.MM.yyyy") + " - " + Format(DateTo, "DF=dd.MM.yyyy") + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("en='Period is wrong!';ru='Неправильно задан период!';de='Der Zeitraum wurde falsch eingetragen!'") + 
		                     ";" + Chars.LF;
	EndIf;
	If Not ValueIsFilled(PriceCalculationDate) Then
		vParamPresentation = vParamPresentation + NStr("en='Price calculation date is not set';ru='Дата получения цен не установлена';de='Das Datum für den Erhalt der Preise wurde nicht festgelegt'") + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("ru = 'Цены на '; en = 'Prices per '; de = 'Preise pro '") + 
		                     Format(PriceCalculationDate, "DF='dd.MM.yyyy HH:mm'") + 
		                     ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(RoomRate) Then
		vParamPresentation = vParamPresentation + NStr("en='Room rate ';ru='Тариф ';de='Tarif '") + 
							 TrimAll(RoomRate.Description) + 
							 ";" + Chars.LF;
	EndIf;							 
	If ValueIsFilled(ClientType) Then
		vParamPresentation = vParamPresentation + NStr("en='Client type ';ru='Тип клиента ';de='Kundentyp '") + 
							 TrimAll(ClientType.Description) + 
							 ";" + Chars.LF;
	EndIf;							 
	If ValueIsFilled(CalendarDayType) Then
		If Not CalendarDayType.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Тип дня '; en = 'Day type '; de = 'Tagetyp '") + 
			                     CalendarDayType.GetObject().pmGetDayTypeDescription(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа типов дней '; en = 'Day types folder '; de = 'Tagetypgruppe '") + 
			                     CalendarDayType.GetObject().pmGetDayTypeDescription(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(Hotel) Then
		If Not Hotel.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Hotel ';ru='Гостиница ';de='Hotel '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Hotels folder ';ru='Группа гостиниц ';de='Hotelgruppe '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	Return vParamPresentation;
EndFunction // pmGetReportParametersPresentation

// -----------------------------------------------------------------------------
// Runs report
// -----------------------------------------------------------------------------
Procedure pmGenerate(pSpreadsheet) Export
	Var vTemplateAttributes;
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
	
	// Initialize report builder query generator attributes
	ReportBuilder.PresentationAdding = PresentationAdditionType.Add;
	
	// Fill report parameters
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qDateFrom", DateFrom);
	ReportBuilder.Parameters.Insert("qDateTo", DateTo);
	ReportBuilder.Parameters.Insert("qEmptyDate", '00010101');
	ReportBuilder.Parameters.Insert("qPriceCalculationDate", New Boundary(PriceCalculationDate, BoundaryType.Including));
	ReportBuilder.Parameters.Insert("qRoomRate", RoomRate);
	ReportBuilder.Parameters.Insert("qCalendar", ?(ValueIsFilled(RoomRate), RoomRate.Calendar, Catalogs.Calendars.EmptyRef()));
	ReportBuilder.Parameters.Insert("qAccommodationService", ?(ValueIsFilled(RoomRate), RoomRate.AccommodationService, Catalogs.Services.EmptyRef()));
	ReportBuilder.Parameters.Insert("qPricesRoomRate", ?(ValueIsFilled(RoomRate.BasedOnRoomRate), RoomRate.BasedOnRoomRate, RoomRate));
	ReportBuilder.Parameters.Insert("qUsePricesFromCalendar", ?(ValueIsFilled(RoomRate), RoomRate.UsePricesFromCalendar, False));
	ReportBuilder.Parameters.Insert("qClientType", ClientType);
	ReportBuilder.Parameters.Insert("qCalendarDayType", CalendarDayType);
	ReportBuilder.Parameters.Insert("qIsEmptyCalendarDayType", Not ValueIsFilled(CalendarDayType));
	
	// Execute report builder query
	ReportBuilder.Execute();
	
	// Apply appearance settings to the report template
	vTemplateAttributes = cmApplyReportTemplateAppearance(ThisObject);
	
	// Output report to the spreadsheet
	ReportBuilder.Put(pSpreadsheet);
	//ReportBuilder.Template.Show(); // For debug purpose

	// Apply appearance settings to the report spreadsheet
	cmApplyReportAppearance(ThisObject, pSpreadsheet, vTemplateAttributes);
EndProcedure // pmGenerate
	
// -----------------------------------------------------------------------------
Procedure pmInitializeReportBuilder() Export
	ReportBuilder = New ReportBuilder();
	
	// Initialize default query text
	QueryText = 
	"SELECT
	|	RoomRatesSliceLast.SetRoomRateFormulas AS Recorder,
	|	RoomRatesSliceLast.RoomRate AS RoomRate
	|INTO ActiveSetRoomRateFormulas
	|FROM
	|	InformationRegister.RoomRates.SliceLast(
	|			&qPriceCalculationDate,
	|			RoomRate = &qRoomRate
	|				AND Hotel = &qHotel
	|				AND IsFormula) AS RoomRatesSliceLast
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomRatesSliceLast.SetRoomRatePrices AS Recorder,
	|	RoomRatesSliceLast.RoomRate AS RoomRate,
	|	RoomRatesSliceLast.CalendarDayType AS CalendarDayType,
	|	RoomRatesSliceLast.PriceTag AS PriceTag
	|INTO ActiveSetRoomRatePrices
	|FROM
	|	InformationRegister.RoomRates.SliceLast(
	|			&qPriceCalculationDate,
	|			RoomRate = &qPricesRoomRate
	|				AND Hotel = &qHotel
	|				AND NOT IsFormula) AS RoomRatesSliceLast
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccommodationTypeFormulas.Ref.RoomRate AS RoomRate,
	|	AccommodationTypeFormulas.Ref.Hotel AS Hotel,
	|	AccommodationTypeFormulas.Ref AS SetRoomRatePrices,
	|	ActiveSetRoomRatePrices.CalendarDayType AS CalendarDayType,
	|	ActiveSetRoomRatePrices.PriceTag AS PriceTag,
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
	|		INNER JOIN ActiveSetRoomRatePrices AS ActiveSetRoomRatePrices
	|		ON AccommodationTypeFormulas.Ref = ActiveSetRoomRatePrices.Recorder
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
	|		INNER JOIN ActiveSetRoomRatePrices AS ActiveSetRoomRatePrices
	|		ON FormulasForPriceTags.Ref = ActiveSetRoomRatePrices.Recorder
	|			AND FormulasForPriceTags.CalendarDayType = ActiveSetRoomRatePrices.CalendarDayType
	|			AND FormulasForPriceTags.PriceTag = ActiveSetRoomRatePrices.PriceTag
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
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
	|	RateServices.Ref = &qAccommodationService
	|	AND NOT RateServices.IsFolder
	|	AND NOT RateServices.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DaysByRoomTypes.AccountingDate AS AccountingDate,
	|	DaysByRoomTypes.RoomType AS RoomType,
	|	DaysByRoomTypes.CalendarDayType AS CalendarDayType,
	|	DaysByRoomTypes.PriceTag AS PriceTag,
	|	DaysByRoomTypes.RoomPrice AS RoomPrice,
	|	DaysByRoomTypes.RoomPriceCurrency AS RoomPriceCurrency
	|INTO DaysByRoomTypes
	|FROM
	|	(SELECT
	|		RoomTypes.Ref AS RoomType,
	|		CalendarDays.AccountingDate AS AccountingDate,
	|		CASE
	|			WHEN CalendarDaysByRoomTypes.CalendarDayType IS NULL
	|				THEN CalendarDays.CalendarDayType
	|			WHEN CalendarDaysByRoomTypes.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef)
	|				THEN CalendarDays.CalendarDayType
	|			ELSE CalendarDaysByRoomTypes.CalendarDayType
	|		END AS CalendarDayType,
	|		CASE
	|			WHEN CalendarDaysByRoomTypes.PriceTag IS NULL
	|				THEN CalendarDays.PriceTag
	|			WHEN CalendarDaysByRoomTypes.PriceTag = VALUE(Catalog.PriceTags.EmptyRef)
	|				THEN CalendarDays.PriceTag
	|			ELSE CalendarDaysByRoomTypes.PriceTag
	|		END AS PriceTag,
	|		CASE
	|			WHEN CalendarDaysByRoomTypes.RoomPrice IS NULL
	|				THEN CalendarDays.RoomPrice
	|			WHEN CalendarDaysByRoomTypes.RoomPrice = 0
	|				THEN CalendarDays.RoomPrice
	|			ELSE CalendarDaysByRoomTypes.RoomPrice
	|		END AS RoomPrice,
	|		CASE
	|			WHEN CalendarDaysByRoomTypes.RoomPriceCurrency IS NULL
	|				THEN CalendarDays.RoomPriceCurrency
	|			WHEN CalendarDaysByRoomTypes.RoomPriceCurrency = VALUE(Catalog.Currencies.EmptyRef)
	|				THEN CalendarDays.RoomPriceCurrency
	|			ELSE CalendarDaysByRoomTypes.RoomPriceCurrency
	|		END AS RoomPriceCurrency
	|	FROM
	|		InformationRegister.CalendarDays.SliceLast(
	|				&qPriceCalculationDate,
	|				Calendar = &qCalendar
	|					AND AccountingDate >= &qDateFrom
	|					AND AccountingDate <= &qDateTo) AS CalendarDays
	|			LEFT JOIN Catalog.RoomTypes AS RoomTypes
	|			ON (RoomTypes.Owner = &qHotel)
	|				AND (NOT RoomTypes.IsFolder)
	|				AND (NOT RoomTypes.DeletionMark)
	|			LEFT JOIN InformationRegister.CalendarDaysByRoomTypes.SliceLast(
	|					&qPriceCalculationDate,
	|					Calendar = &qCalendar
	|						AND AccountingDate >= &qDateFrom
	|						AND AccountingDate <= &qDateTo) AS CalendarDaysByRoomTypes
	|			ON CalendarDays.AccountingDate = CalendarDaysByRoomTypes.AccountingDate
	|				AND (RoomTypes.Ref = CalendarDaysByRoomTypes.RoomType)) AS DaysByRoomTypes
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
	|	RoomTypePricesByDates.AccountingDate AS AccountingDate,
	|	RoomTypePricesByDates.CalendarDayType AS CalendarDayType,
	|	RoomTypePricesByDates.PriceTag AS PriceTag,
	|	RoomTypePricesByDates.RoomPrice AS Price,
	|	RoomTypePricesByDates.RoomPriceCurrency AS Currency
	|INTO RoomTypePricesByDates
	|FROM
	|	DaysByRoomTypes AS RoomTypePricesByDates
	|		LEFT JOIN RateServices AS RateServices
	|		ON (TRUE)
	|WHERE
	|	&qUsePricesFromCalendar
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RawRoomRatePrices.AccountingDate AS AccountingDate,
	|	RateAccommodationTypeFormulas.RoomRate AS RoomRate,
	|	CASE
	|		WHEN RawRoomRatePrices.CalendarDayType <> VALUE(Catalog.CalendarDayTypes.EmptyRef)
	|			THEN RawRoomRatePrices.CalendarDayType
	|		ELSE RateAccommodationTypeFormulas.CalendarDayType
	|	END AS CalendarDayType,
	|	CASE
	|		WHEN RawRoomRatePrices.PriceTag <> VALUE(Catalog.PriceTags.EmptyRef)
	|			THEN RawRoomRatePrices.PriceTag
	|		ELSE RateAccommodationTypeFormulas.PriceTag
	|	END AS PriceTag,
	|	RateAccommodationTypeFormulas.ClientType AS ClientType,
	|	RawRoomRatePrices.RoomType AS RoomType,
	|	RateAccommodationTypeFormulas.AccommodationType AS AccommodationType,
	|	RateAccommodationTypeFormulas.SetRoomRatePrices AS SetRoomRatePrices,
	|	RateAccommodationTypeFormulas.SortCode AS SortCode,
	|	RateAccommodationTypeFormulas.LineNumber AS LineNumber,
	|	RateAccommodationTypeFormulas.Hotel AS Hotel,
	|	RawRoomRatePrices.Service AS Service,
	|	(RawRoomRatePrices.Price + ISNULL(RateAccommodationTypeFormulas.BracketsConstant, 0)) * ISNULL(RateAccommodationTypeFormulas.Multiplier, 0) + ISNULL(RateAccommodationTypeFormulas.Constant, 0) AS Price,
	|	RawRoomRatePrices.Currency AS Currency,
	|	0 AS MinimumQuantity,
	|	ISNULL(ServicePrices.VATRate, RateAccommodationTypeFormulas.Hotel.Company.VATRate) AS VATRate,
	|	RawRoomRatePrices.QuantityCalculationRule AS QuantityCalculationRule,
	|	RawRoomRatePrices.QuantityCalculationRuleType AS QuantityCalculationRuleType,
	|	RawRoomRatePrices.IsRoomRevenue AS IsRoomRevenue,
	|	RawRoomRatePrices.IsInPrice AS IsInPrice,
	|	RawRoomRatePrices.ChargePerPerson AS ChargePerPerson,
	|	RawRoomRatePrices.ChargeToEachGuestSeparately AS ChargeToEachGuestSeparately,
	|	RawRoomRatePrices.Unit AS Unit,
	|	RawRoomRatePrices.RoomRevenueAmountsOnly AS RoomRevenueAmountsOnly
	|INTO RawRoomRatePrices
	|FROM
	|	RoomTypePricesByDates AS RawRoomRatePrices
	|		LEFT JOIN RateAccommodationTypeFormulas AS RateAccommodationTypeFormulas
	|		ON (RawRoomRatePrices.Service = RateAccommodationTypeFormulas.Service
	|				OR RateAccommodationTypeFormulas.Service = VALUE(Catalog.Services.EmptyRef))
	|			AND (RawRoomRatePrices.RoomType = RateAccommodationTypeFormulas.RoomType
	|					AND RateAccommodationTypeFormulas.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
	|				OR RawRoomRatePrices.RoomType.RoomClass = RateAccommodationTypeFormulas.RoomClass
	|					AND RateAccommodationTypeFormulas.RoomClass <> VALUE(Catalog.RoomTypeClasses.EmptyRef)
	|				OR RateAccommodationTypeFormulas.RoomType = VALUE(Catalog.RoomTypes.EmptyRef)
	|					AND RateAccommodationTypeFormulas.RoomClass = VALUE(Catalog.RoomTypeClasses.EmptyRef))
	|		LEFT JOIN InformationRegister.ServicePrices.SliceLast(
	|				&qPriceCalculationDate,
	|				Service = &qAccommodationService
	|					AND Hotel = &qHotel) AS ServicePrices
	|		ON RawRoomRatePrices.Service = ServicePrices.Service
	|			AND (RateAccommodationTypeFormulas.ClientType = ServicePrices.ClientType)
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
	|	RoomRatePrices.AccommodationType AS AccommodationType,
	|	RoomRatePrices.SetRoomRatePrices AS SetRoomRatePrices,
	|	RoomRatePrices.SortCode AS SortCode,
	|	RoomRatePrices.LineNumber AS LineNumber,
	|	RoomRatePrices.Hotel AS Hotel,
	|	RoomRatePrices.Service AS Service,
	|	CASE
	|		WHEN ISNULL(FormulasForPriceTags.Discount, 0) <> 0
	|			THEN RoomRatePrices.Price - RoomRatePrices.Price * ISNULL(FormulasForPriceTags.Discount, 0) / 100
	|		ELSE (RoomRatePrices.Price + ISNULL(FormulasForPriceTags.BracketsConstant, 0)) * ISNULL(FormulasForPriceTags.Multiplier, 1) + ISNULL(FormulasForPriceTags.Constant, 0)
	|	END AS Price,
	|	RoomRatePrices.Currency AS Currency,
	|	RoomRatePrices.MinimumQuantity AS MinimumQuantity,
	|	RoomRatePrices.VATRate AS VATRate,
	|	RoomRatePrices.QuantityCalculationRule AS QuantityCalculationRule,
	|	RoomRatePrices.QuantityCalculationRuleType AS QuantityCalculationRuleType,
	|	RoomRatePrices.IsRoomRevenue AS IsRoomRevenue,
	|	RoomRatePrices.IsInPrice AS IsInPrice,
	|	RoomRatePrices.ChargePerPerson AS IsPricePerPerson,
	|	RoomRatePrices.ChargeToEachGuestSeparately AS ChargeToEachGuestSeparately,
	|	RoomRatePrices.Unit AS Unit,
	|	RoomRatePrices.RoomRevenueAmountsOnly AS RoomRevenueAmountsOnly
	|INTO RoomRatePricesByCalendar
	|FROM
	|	RawRoomRatePrices AS RoomRatePrices
	|		LEFT JOIN FormulasForPriceTags AS FormulasForPriceTags
	|		ON (RoomRatePrices.Service = FormulasForPriceTags.Service
	|					AND FormulasForPriceTags.Service <> VALUE(Catalog.Services.EmptyRef)
	|				OR FormulasForPriceTags.Service = VALUE(Catalog.Services.EmptyRef))
	|			AND RoomRatePrices.ClientType = FormulasForPriceTags.ClientType
	|			AND RoomRatePrices.PriceTag = FormulasForPriceTags.PriceTag
	|			AND RoomRatePrices.CalendarDayType = FormulasForPriceTags.CalendarDayType
	|			AND (RoomRatePrices.AccommodationType = FormulasForPriceTags.AccommodationType
	|					AND FormulasForPriceTags.AccommodationType <> VALUE(Catalog.AccommodationTypes.EmptyRef)
	|				OR FormulasForPriceTags.AccommodationType = VALUE(Catalog.AccommodationTypes.EmptyRef))
	|			AND (RoomRatePrices.RoomType = FormulasForPriceTags.RoomType
	|					AND FormulasForPriceTags.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
	|				OR RoomRatePrices.RoomType.RoomClass = FormulasForPriceTags.RoomClass
	|					AND FormulasForPriceTags.RoomClass <> VALUE(Catalog.RoomTypeClasses.EmptyRef)
	|				OR FormulasForPriceTags.RoomType = VALUE(Catalog.RoomTypes.EmptyRef)
	|					AND FormulasForPriceTags.RoomClass = VALUE(Catalog.RoomTypeClasses.EmptyRef))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DaysByRoomTypes.AccountingDate AS AccountingDate,
	|	RoomRatePrices.Hotel AS Hotel,
	|	RoomRatePrices.RoomRate AS RoomRate,
	|	RoomRatePrices.ClientType AS ClientType,
	|	RoomRatePrices.RoomType AS RoomType,
	|	RoomRatePrices.AccommodationType AS AccommodationType,
	|	RoomRatePrices.CalendarDayType AS CalendarDayType,
	|	RoomRatePrices.PriceTag AS PriceTag,
	|	RoomRatePrices.IsPricePerPerson AS IsPricePerPerson,
	|	RoomRatePrices.Service AS Service,
	|	RoomRatePrices.Currency AS Currency,
	|	RoomRatePrices.Price AS Price
	|INTO RoomRatePricesByDocuments
	|FROM
	|	InformationRegister.RoomRatePrices AS RoomRatePrices
	|		INNER JOIN ActiveSetRoomRatePrices AS ActiveSetRoomRatePrices
	|		ON RoomRatePrices.Recorder = ActiveSetRoomRatePrices.Recorder
	|			AND RoomRatePrices.CalendarDayType = ActiveSetRoomRatePrices.CalendarDayType
	|			AND RoomRatePrices.PriceTag = ActiveSetRoomRatePrices.PriceTag
	|		INNER JOIN DaysByRoomTypes AS DaysByRoomTypes
	|		ON RoomRatePrices.RoomType = DaysByRoomTypes.RoomType
	|			AND RoomRatePrices.CalendarDayType = DaysByRoomTypes.CalendarDayType
	|WHERE
	|	NOT &qUsePricesFromCalendar
	|	AND RoomRatePrices.Hotel = &qHotel
	|	AND RoomRatePrices.RoomRate = &qPricesRoomRate
	|	AND RoomRatePrices.ClientType = &qClientType
	|	AND (RoomRatePrices.CalendarDayType IN HIERARCHY (&qCalendarDayType)
	|			OR &qIsEmptyCalendarDayType)
	|	AND RoomRatePrices.IsInPrice = TRUE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomRatePrices.AccountingDate AS AccountingDate,
	|	RoomRatePrices.Hotel AS Hotel,
	|	RoomRatePrices.RoomRate AS RoomRate,
	|	RoomRatePrices.ClientType AS ClientType,
	|	RoomRatePrices.RoomType AS RoomType,
	|	RoomRatePrices.AccommodationType AS AccommodationType,
	|	RoomRatePrices.CalendarDayType AS CalendarDayType,
	|	RoomRatePrices.PriceTag AS PriceTag,
	|	RoomRatePrices.IsPricePerPerson AS IsPricePerPerson,
	|	RoomRatePrices.Service AS Service,
	|	RoomRatePrices.Currency AS Currency,
	|	RoomRatePrices.Price AS Price
	|INTO RoomRatePrices
	|FROM
	|	(SELECT
	|		RoomRatePricesByDocuments.AccountingDate AS AccountingDate,
	|		RoomRatePricesByDocuments.Hotel AS Hotel,
	|		RoomRatePricesByDocuments.RoomRate AS RoomRate,
	|		RoomRatePricesByDocuments.ClientType AS ClientType,
	|		RoomRatePricesByDocuments.RoomType AS RoomType,
	|		RoomRatePricesByDocuments.AccommodationType AS AccommodationType,
	|		RoomRatePricesByDocuments.CalendarDayType AS CalendarDayType,
	|		RoomRatePricesByDocuments.PriceTag AS PriceTag,
	|		RoomRatePricesByDocuments.IsPricePerPerson AS IsPricePerPerson,
	|		RoomRatePricesByDocuments.Service AS Service,
	|		RoomRatePricesByDocuments.Currency AS Currency,
	|		RoomRatePricesByDocuments.Price AS Price
	|	FROM
	|		RoomRatePricesByDocuments AS RoomRatePricesByDocuments
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RoomRatePricesByCalendar.AccountingDate,
	|		RoomRatePricesByCalendar.Hotel,
	|		RoomRatePricesByCalendar.RoomRate,
	|		RoomRatePricesByCalendar.ClientType,
	|		RoomRatePricesByCalendar.RoomType,
	|		RoomRatePricesByCalendar.AccommodationType,
	|		RoomRatePricesByCalendar.CalendarDayType,
	|		RoomRatePricesByCalendar.PriceTag,
	|		RoomRatePricesByCalendar.IsPricePerPerson,
	|		RoomRatePricesByCalendar.Service,
	|		RoomRatePricesByCalendar.Currency,
	|		RoomRatePricesByCalendar.Price
	|	FROM
	|		RoomRatePricesByCalendar AS RoomRatePricesByCalendar) AS RoomRatePrices
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
	|SELECT
	|	RoomRatePrices.AccountingDate AS AccountingDate,
	|	RoomRatePrices.RoomType AS RoomType,
	|	RoomRatePrices.RoomType.SortCode AS RoomTypeSortCode,
	|	RoomRatePrices.AccommodationType AS AccommodationType,
	|	RoomRatePrices.AccommodationType.SortCode AS AccommodationTypeSortCode,
	|	RoomRatePrices.CalendarDayType AS CalendarDayType,
	|	RoomRatePrices.CalendarDayType.SortCode AS CalendarDayTypeSortCode,
	|	RoomRatePrices.PriceTag AS PriceTag,
	|	RoomRatePrices.PriceTag.SortCode AS PriceTagSortCode,
	|	RoomRatePrices.Currency AS Currency,
	|	RoomRateFormulas.BracketsConstant AS BracketsConstant,
	|	RoomRateFormulas.Constant AS Constant,
	|	RoomRateFormulas.Multiplier AS Multiplier,
	|	SUM(CASE
	|			WHEN RoomRatePrices.IsPricePerPerson
	|					AND RoomRatePrices.AccommodationType.NumberOfPersons4Reservation > 1
	|				THEN ((RoomRatePrices.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0)) * RoomRatePrices.AccommodationType.NumberOfPersons4Reservation
	|			WHEN RoomRatePrices.IsPricePerPerson
	|					AND RoomRatePrices.AccommodationType.NumberOfPersons > 1
	|				THEN ((RoomRatePrices.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0)) * RoomRatePrices.AccommodationType.NumberOfPersons
	|			ELSE (RoomRatePrices.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0)
	|		END) AS Price
	|{SELECT
	|	AccountingDate,
	|	RoomType.*,
	|	AccommodationType.*,
	|	CalendarDayType.*,
	|	PriceTag.*,
	|	Price,
	|	Currency.*}
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
	|{WHERE
	|	RoomRatePrices.AccountingDate,
	|	RoomRatePrices.Hotel.*,
	|	RoomRatePrices.RoomRate.*,
	|	RoomRatePrices.CalendarDayType.*,
	|	RoomRatePrices.PriceTag.*,
	|	RoomRatePrices.ClientType.*,
	|	RoomRatePrices.RoomType.*,
	|	RoomRatePrices.AccommodationType.*}
	|
	|GROUP BY
	|	RoomRatePrices.AccountingDate,
	|	RoomRatePrices.RoomType,
	|	RoomRatePrices.AccommodationType,
	|	RoomRatePrices.CalendarDayType,
	|	RoomRatePrices.PriceTag,
	|	RoomRatePrices.Currency,
	|	RoomRatePrices.RoomType.SortCode,
	|	RoomRatePrices.AccommodationType.SortCode,
	|	RoomRatePrices.CalendarDayType.SortCode,
	|	RoomRatePrices.PriceTag.SortCode,
	|	RoomRateFormulas.BracketsConstant,
	|	RoomRateFormulas.Constant,
	|	RoomRateFormulas.Multiplier
	|
	|ORDER BY
	|	AccountingDate,
	|	RoomTypeSortCode,
	|	AccommodationTypeSortCode,
	|	CalendarDayTypeSortCode,
	|	PriceTagSortCode,
	|	Currency
	|{ORDER BY
	|	AccountingDate,
	|	RoomType.*,
	|	RoomTypeSortCode,
	|	AccommodationType.*,
	|	AccommodationTypeSortCode,
	|	CalendarDayType.*,
	|	CalendarDayTypeSortCode,
	|	PriceTag.*,
	|	PriceTagSortCode,
	|	Currency.*,
	|	Price}
	|TOTALS
	|	MAX(Price)
	|BY
	|	AccountingDate,
	|	RoomType,
	|	AccommodationType
	|{TOTALS BY
	|	AccountingDate,
	|	RoomType.*,
	|	AccommodationType.*,
	|	CalendarDayType.*,
	|	PriceTag.*,
	|	Currency.*}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Price list';RU='Прайс-лист';de='Preisliste'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
