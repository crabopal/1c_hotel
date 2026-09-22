
#Region Public

// -----------------------------------------------------------------------------
// Returns cached room rate prices for the given accommodation templates and period
// -----------------------------------------------------------------------------
Function GetCachedPrices(pHotel, pClientType, pPeriodFrom, pPeriodTo, pPriceTag, pRoomRatesList, pAccTemplates, pWithoutOnline = False, pWithoutLOSAndCTs = False, pDiscountType = Undefined, pExternalSystemCode = Undefined, rDiscount = 0, pPromoCodeStruct = Undefined) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomRates.RoomRateInCache AS RoomRateInCache,
	|	RoomRates.RoomRate AS RoomRate,
	|	RoomRates.RoomRateCode AS RoomRateCode,
	|	RoomRates.RoomRateSortCode AS RoomRateSortCode,
	|	RoomRates.RoomRateDescription AS RoomRateDescription,
	|	RoomRates.RoomRateCalendar AS RoomRateCalendar
	|INTO CacheRoomRates
	|FROM
	|	&qRoomRates AS RoomRates
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CacheRoomRates.RoomRate AS RoomRate,
	|	&qHotel AS Hotel,
	|	AccommodationTemplatesAccommodationTypes.Ref AS AccommodationTemplate,
	|	HotelRoomTypes.Ref AS RoomType,
	|	HotelRoomTypes.RoomClass AS RoomClass,
	|	CASE
	|		WHEN NOT RoomRateOverrides.ToAccommodationType IS NULL
	|			THEN RoomRateOverrides.ToAccommodationType
	|		ELSE AccommodationTemplatesAccommodationTypes.AccommodationType
	|	END AS AccommodationType,
	|	AccommodationTemplatesAccommodationTypes.LineNumber AS LineNumber
	|INTO AccommodationTypesInTemplatesNoRoomTypeLimits
	|FROM
	|	CacheRoomRates AS CacheRoomRates
	|		LEFT JOIN Catalog.RoomTypes AS HotelRoomTypes
	|		ON (HotelRoomTypes.Owner = &qHotel)
	|			AND (NOT HotelRoomTypes.DeletionMark)
	|			AND (NOT HotelRoomTypes.IsFolder)
	|		INNER JOIN Catalog.AccommodationTemplates.AccommodationTypes AS AccommodationTemplatesAccommodationTypes
	|		ON (AccommodationTemplatesAccommodationTypes.Ref IN (&qTemplatesNoRoomTypeLimits))
	|		LEFT JOIN InformationRegister.RoomRateOverrides AS RoomRateOverrides
	|		ON CacheRoomRates.RoomRate = RoomRateOverrides.RoomRate
	|			AND (&qHotel = RoomRateOverrides.Hotel)
	|			AND (AccommodationTemplatesAccommodationTypes.Ref = RoomRateOverrides.AccommodationTemplate)
	|			AND (HotelRoomTypes.Ref = RoomRateOverrides.RoomType
	|				OR RoomRateOverrides.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
	|			AND (AccommodationTemplatesAccommodationTypes.AccommodationType = RoomRateOverrides.AccommodationType)
	|			AND (AccommodationTemplatesAccommodationTypes.LineNumber = RoomRateOverrides.TemplateLineNumber)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CacheRoomRates.RoomRate AS RoomRate,
	|	&qHotel AS Hotel,
	|	AccommodationTemplatesAccommodationTypes.Ref AS AccommodationTemplate,
	|	HotelRoomTypes.Ref AS RoomType,
	|	HotelRoomTypes.RoomClass AS RoomClass,
	|	CASE
	|		WHEN NOT RoomRateOverrides.ToAccommodationType IS NULL
	|			THEN RoomRateOverrides.ToAccommodationType
	|		ELSE AccommodationTemplatesAccommodationTypes.AccommodationType
	|	END AS AccommodationType,
	|	AccommodationTemplatesAccommodationTypes.LineNumber AS LineNumber
	|INTO AccommodationTypesInTemplatesWithRoomTypeLimits
	|FROM
	|	CacheRoomRates AS CacheRoomRates
	|		LEFT JOIN Catalog.RoomTypes AS HotelRoomTypes
	|		ON (HotelRoomTypes.Owner = &qHotel)
	|			AND (NOT HotelRoomTypes.DeletionMark)
	|			AND (NOT HotelRoomTypes.IsFolder)
	|		INNER JOIN Catalog.AccommodationTemplates.AccommodationTypes AS AccommodationTemplatesAccommodationTypes
	|		ON (AccommodationTemplatesAccommodationTypes.Ref IN (&qTemplatesWithRoomTypeLimits))
	|		INNER JOIN Catalog.AccommodationTemplates.RoomTypes AS AccommodationTemplatesRoomTypes
	|		ON (AccommodationTemplatesAccommodationTypes.Ref = AccommodationTemplatesRoomTypes.Ref)
	|			AND (HotelRoomTypes.Ref = AccommodationTemplatesRoomTypes.RoomType
	|					AND AccommodationTemplatesRoomTypes.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
	|				OR HotelRoomTypes.RoomClass = AccommodationTemplatesRoomTypes.RoomClass
	|					AND AccommodationTemplatesRoomTypes.RoomClass <> VALUE(Catalog.RoomTypeClasses.EmptyRef))
	|		LEFT JOIN InformationRegister.RoomRateOverrides AS RoomRateOverrides
	|		ON CacheRoomRates.RoomRate = RoomRateOverrides.RoomRate
	|			AND (&qHotel = RoomRateOverrides.Hotel)
	|			AND (AccommodationTemplatesAccommodationTypes.Ref = RoomRateOverrides.AccommodationTemplate)
	|			AND (HotelRoomTypes.Ref = RoomRateOverrides.RoomType
	|				OR RoomRateOverrides.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
	|			AND (AccommodationTemplatesAccommodationTypes.AccommodationType = RoomRateOverrides.AccommodationType)
	|			AND (AccommodationTemplatesAccommodationTypes.LineNumber = RoomRateOverrides.TemplateLineNumber)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomRatesSliceLast.SetRoomRateFormulas AS Recorder,
	|	RoomRatesSliceLast.RoomRate AS RoomRate
	|INTO ActiveSetRoomRateFormulas
	|FROM
	|	InformationRegister.RoomRates.SliceLast(
	|			&qPriceCalculationDate,
	|			RoomRate IN (&qRoomRatesList)
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
	|SELECT
	|	RoomRateDailyPrices.Period AS Period,
	|	RoomRateDailyPrices.Hotel AS Hotel,
	|	RoomRateDailyPrices.Hotel.Code AS HotelCode,
	|	RoomRateDailyPrices.Hotel.SortCode AS HotelSortCode,
	|	RoomRateDailyPrices.Hotel.Description AS HotelDescription,
	|	CacheRoomRates.RoomRate AS RoomRate,
	|	CacheRoomRates.RoomRateCode AS RoomRateCode,
	|	CacheRoomRates.RoomRateSortCode AS RoomRateSortCode,
	|	CacheRoomRates.RoomRateDescription AS RoomRateDescription,
	|	CacheRoomRates.RoomRateCalendar AS RoomRateCalendar,
	|	AccommodationTemplatesAccommodationTypes.AccommodationTemplate AS AccommodationTemplate,
	|	AccommodationTemplatesAccommodationTypes.AccommodationTemplate.Code AS AccommodationTemplateCode,
	|	RoomRateDailyPrices.RoomType AS RoomType,
	|	RoomRateDailyPrices.RoomType.Code AS RoomTypeCode,
	|	RoomRateDailyPrices.RoomType.SortCode AS RoomTypeSortCode,
	|	RoomRateDailyPrices.RoomType.Description AS RoomTypeDescription,
	|	RoomRateDailyPrices.RoomType.RoomClass AS RoomTypeClass,
	|	RoomRateDailyPrices.AccommodationType AS AccommodationType,
	|	RoomRateDailyPrices.AccommodationType.Code AS AccommodationTypeCode,
	|	RoomRateDailyPrices.AccommodationType.SortCode AS AccommodationTypeSortCode,
	|	RoomRateDailyPrices.AccommodationType.Description AS AccommodationTypeDescription,
	|	RoomRateDailyPrices.Currency AS Currency,
	|	RoomRateDailyPrices.Currency.Code AS CurrencyCode,
	|	RoomRateDailyPrices.Currency.Description AS CurrencyDescription,
	|	RoomRateDailyPrices.ClientType AS ClientType,
	|	RoomRateDailyPrices.PriceTag AS PriceTag,
	|	RoomRateDailyPrices.Price AS Price,
	|	CAST(RoomRateDailyPrices.RoomType.RoomTypePictureLink AS STRING(1024)) AS RoomTypePictureLink,
	|	CAST(RoomRateDailyPrices.RoomType.RoomTypeInfoLink AS STRING(1024)) AS RoomTypeInfoLink,
	|	AccommodationTemplatesAccommodationTypes.LineNumber AS LineNumber
	|INTO RoomRateDailyPricesNoRoomTypeLimits
	|FROM
	|	InformationRegister.RoomRateDailyPrices AS RoomRateDailyPrices
	|		INNER JOIN CacheRoomRates AS CacheRoomRates
	|		ON RoomRateDailyPrices.RoomRate = CacheRoomRates.RoomRateInCache
	|		INNER JOIN AccommodationTypesInTemplatesNoRoomTypeLimits AS AccommodationTemplatesAccommodationTypes
	|		ON (AccommodationTemplatesAccommodationTypes.AccommodationType = RoomRateDailyPrices.AccommodationType)
	|			AND (AccommodationTemplatesAccommodationTypes.RoomRate = CacheRoomRates.RoomRate)
	|			AND (AccommodationTemplatesAccommodationTypes.Hotel = RoomRateDailyPrices.Hotel)
	|			AND (AccommodationTemplatesAccommodationTypes.RoomType = RoomRateDailyPrices.RoomType)
	|WHERE
	|	RoomRateDailyPrices.Period >= &qPeriodFrom
	|	AND (RoomRateDailyPrices.Period < &qPeriodTo
	|				AND RoomRateDailyPrices.RoomRate.DurationCalculationRuleType <> VALUE(Enum.DurationCalculationRuleTypes.ByDays)
	|			OR RoomRateDailyPrices.Period <= &qPeriodTo
	|				AND RoomRateDailyPrices.RoomRate.DurationCalculationRuleType = VALUE(Enum.DurationCalculationRuleTypes.ByDays))
	|	AND RoomRateDailyPrices.Hotel = &qHotel
	|	AND RoomRateDailyPrices.ClientType = &qClientType
	|	AND RoomRateDailyPrices.PriceTag = &qPriceTag
	|
	|INDEX BY
	|	CacheRoomRates.RoomRateCalendar,
	|	RoomRateDailyPrices.Period,
	|	RoomRateDailyPrices.RoomType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	RoomRateDailyPricesNoRoomTypeLimits.Period AS Period,
	|	RoomRateDailyPricesNoRoomTypeLimits.Hotel AS Hotel,
	|	RoomRateDailyPricesNoRoomTypeLimits.HotelCode AS HotelCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.HotelSortCode AS HotelSortCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.HotelDescription AS HotelDescription,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomRate AS RoomRate,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomRateCode AS RoomRateCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomRateSortCode AS RoomRateSortCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomRateDescription AS RoomRateDescription,
	|	RoomRateDailyPricesNoRoomTypeLimits.AccommodationTemplate AS AccommodationTemplate,
	|	RoomRateDailyPricesNoRoomTypeLimits.AccommodationTemplateCode AS AccommodationTemplateCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomType AS RoomType,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomTypeCode AS RoomTypeCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomTypeSortCode AS RoomTypeSortCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomTypeDescription AS RoomTypeDescription,
	|	RoomRateDailyPricesNoRoomTypeLimits.AccommodationType AS AccommodationType,
	|	RoomRateDailyPricesNoRoomTypeLimits.AccommodationTypeCode AS AccommodationTypeCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.AccommodationTypeSortCode AS AccommodationTypeSortCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.AccommodationTypeDescription AS AccommodationTypeDescription,
	|	RoomRateDailyPricesNoRoomTypeLimits.Currency AS Currency,
	|	RoomRateDailyPricesNoRoomTypeLimits.CurrencyCode AS CurrencyCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.CurrencyDescription AS CurrencyDescription,
	|	CASE
	|		WHEN RoomRateDailyPricesNoRoomTypeLimits.Period IN (&qZeroPriceDays)
	|			THEN 0
	|		ELSE (RoomRateDailyPricesNoRoomTypeLimits.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0)
	|	END AS Amount,
	|	CASE
	|		WHEN BEGINOFPERIOD(RoomRateDailyPricesNoRoomTypeLimits.Period, DAY) = BEGINOFPERIOD(&qPeriodFrom, DAY)
	|			THEN (RoomRateDailyPricesNoRoomTypeLimits.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0)
	|		ELSE 0
	|	END AS FirstDaySum,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomTypePictureLink AS RoomTypePictureLink,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomTypeInfoLink AS RoomTypeInfoLink,
	|	RoomRateDailyPricesNoRoomTypeLimits.LineNumber AS LineNumber
	|INTO RoomRateDailyPricesNoRoomTypeLimitsEnriched
	|FROM
	|	RoomRateDailyPricesNoRoomTypeLimits AS RoomRateDailyPricesNoRoomTypeLimits
	|		LEFT JOIN InformationRegister.CalendarDays.SliceLast(&qPriceCalculationDate, ) AS CalendarDays
	|		ON RoomRateDailyPricesNoRoomTypeLimits.RoomRateCalendar = CalendarDays.Calendar
	|			AND RoomRateDailyPricesNoRoomTypeLimits.Period = CalendarDays.AccountingDate
	|		LEFT JOIN InformationRegister.CalendarDaysByRoomTypes.SliceLast(&qPriceCalculationDate, ) AS CalendarDaysByRoomTypes
	|		ON RoomRateDailyPricesNoRoomTypeLimits.RoomRateCalendar = CalendarDaysByRoomTypes.Calendar
	|			AND RoomRateDailyPricesNoRoomTypeLimits.Period = CalendarDaysByRoomTypes.AccountingDate
	|			AND RoomRateDailyPricesNoRoomTypeLimits.RoomType = CalendarDaysByRoomTypes.RoomType
	|		LEFT JOIN RoomRateFormulas AS RoomRateFormulas
	|		ON RoomRateDailyPricesNoRoomTypeLimits.RoomRate = RoomRateFormulas.RoomRate
	|			AND RoomRateDailyPricesNoRoomTypeLimits.Hotel = RoomRateFormulas.Hotel
	|			AND (NOT RoomRateFormulas.IsFormula
	|				OR RoomRateFormulas.IsFormula
	|					AND RoomRateDailyPricesNoRoomTypeLimits.RoomType = RoomRateFormulas.RoomType
	|					AND RoomRateDailyPricesNoRoomTypeLimits.ClientType = &qClientType
	|					AND RoomRateDailyPricesNoRoomTypeLimits.AccommodationType = RoomRateFormulas.AccommodationType
	|					AND (CalendarDaysByRoomTypes.CalendarDayType = RoomRateFormulas.CalendarDayType
	|							AND NOT CalendarDaysByRoomTypes.CalendarDayType IS NULL
	|							AND NOT CalendarDaysByRoomTypes.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef)
	|						OR CalendarDays.CalendarDayType = RoomRateFormulas.CalendarDayType
	|							AND NOT CalendarDays.CalendarDayType IS NULL
	|							AND (CalendarDaysByRoomTypes.CalendarDayType IS NULL OR CalendarDaysByRoomTypes.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef))
	|						OR RoomRateFormulas.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef)))
	|			AND (RoomRateFormulas.BasedOnPriceTag = VALUE(Catalog.PriceTags.EmptyRef)
	|				OR RoomRateDailyPricesNoRoomTypeLimits.PriceTag = RoomRateFormulas.BasedOnPriceTag
	|					AND RoomRateFormulas.BasedOnPriceTag <> VALUE(Catalog.PriceTags.EmptyRef))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomRateDailyPrices.Period AS Period,
	|	RoomRateDailyPrices.Hotel AS Hotel,
	|	RoomRateDailyPrices.Hotel.Code AS HotelCode,
	|	RoomRateDailyPrices.Hotel.SortCode AS HotelSortCode,
	|	RoomRateDailyPrices.Hotel.Description AS HotelDescription,
	|	CacheRoomRates.RoomRate AS RoomRate,
	|	CacheRoomRates.RoomRateCode AS RoomRateCode,
	|	CacheRoomRates.RoomRateSortCode AS RoomRateSortCode,
	|	CacheRoomRates.RoomRateDescription AS RoomRateDescription,
	|	CacheRoomRates.RoomRateCalendar AS RoomRateCalendar,
	|	AccommodationTemplatesAccommodationTypes.AccommodationTemplate AS AccommodationTemplate,
	|	AccommodationTemplatesAccommodationTypes.AccommodationTemplate.Code AS AccommodationTemplateCode,
	|	RoomRateDailyPrices.RoomType AS RoomType,
	|	RoomRateDailyPrices.RoomType.Code AS RoomTypeCode,
	|	RoomRateDailyPrices.RoomType.SortCode AS RoomTypeSortCode,
	|	RoomRateDailyPrices.RoomType.Description AS RoomTypeDescription,
	|	RoomRateDailyPrices.AccommodationType AS AccommodationType,
	|	RoomRateDailyPrices.AccommodationType.Code AS AccommodationTypeCode,
	|	RoomRateDailyPrices.AccommodationType.SortCode AS AccommodationTypeSortCode,
	|	RoomRateDailyPrices.AccommodationType.Description AS AccommodationTypeDescription,
	|	RoomRateDailyPrices.Currency AS Currency,
	|	RoomRateDailyPrices.Currency.Code AS CurrencyCode,
	|	RoomRateDailyPrices.Currency.Description AS CurrencyDescription,
	|	RoomRateDailyPrices.ClientType AS ClientType,
	|	RoomRateDailyPrices.PriceTag AS PriceTag,
	|	RoomRateDailyPrices.Price AS Price,
	|	CAST(RoomRateDailyPrices.RoomType.RoomTypePictureLink AS STRING(1024)) AS RoomTypePictureLink,
	|	CAST(RoomRateDailyPrices.RoomType.RoomTypeInfoLink AS STRING(1024)) AS RoomTypeInfoLink,
	|	AccommodationTemplatesAccommodationTypes.LineNumber AS LineNumber
	|INTO RoomRateDailyPricesRoomTypeLimits
	|FROM
	|	InformationRegister.RoomRateDailyPrices AS RoomRateDailyPrices
	|		INNER JOIN CacheRoomRates AS CacheRoomRates
	|		ON RoomRateDailyPrices.RoomRate = CacheRoomRates.RoomRateInCache
	|		INNER JOIN AccommodationTypesInTemplatesWithRoomTypeLimits AS AccommodationTemplatesAccommodationTypes
	|		ON (AccommodationTemplatesAccommodationTypes.AccommodationType = RoomRateDailyPrices.AccommodationType)
	|			AND (AccommodationTemplatesAccommodationTypes.RoomRate = CacheRoomRates.RoomRate)
	|			AND (AccommodationTemplatesAccommodationTypes.Hotel = RoomRateDailyPrices.Hotel)
	|			AND (AccommodationTemplatesAccommodationTypes.RoomType = RoomRateDailyPrices.RoomType)
	|WHERE
	|	RoomRateDailyPrices.Period >= &qPeriodFrom
	|	AND (RoomRateDailyPrices.Period < &qPeriodTo
	|				AND RoomRateDailyPrices.RoomRate.DurationCalculationRuleType <> VALUE(Enum.DurationCalculationRuleTypes.ByDays)
	|			OR RoomRateDailyPrices.Period <= &qPeriodTo
	|				AND RoomRateDailyPrices.RoomRate.DurationCalculationRuleType = VALUE(Enum.DurationCalculationRuleTypes.ByDays))
	|	AND RoomRateDailyPrices.Hotel = &qHotel
	|	AND RoomRateDailyPrices.ClientType = &qClientType
	|	AND RoomRateDailyPrices.PriceTag = &qPriceTag
	|
	|INDEX BY
	|	CacheRoomRates.RoomRateCalendar,
	|	RoomRateDailyPrices.Period,
	|	RoomRateDailyPrices.RoomType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	RoomRateDailyPricesRoomTypeLimits.Period AS Period,
	|	RoomRateDailyPricesRoomTypeLimits.Hotel AS Hotel,
	|	RoomRateDailyPricesRoomTypeLimits.HotelCode AS HotelCode,
	|	RoomRateDailyPricesRoomTypeLimits.HotelSortCode AS HotelSortCode,
	|	RoomRateDailyPricesRoomTypeLimits.HotelDescription AS HotelDescription,
	|	RoomRateDailyPricesRoomTypeLimits.RoomRate AS RoomRate,
	|	RoomRateDailyPricesRoomTypeLimits.RoomRateCode AS RoomRateCode,
	|	RoomRateDailyPricesRoomTypeLimits.RoomRateSortCode AS RoomRateSortCode,
	|	RoomRateDailyPricesRoomTypeLimits.RoomRateDescription AS RoomRateDescription,
	|	RoomRateDailyPricesRoomTypeLimits.AccommodationTemplate AS AccommodationTemplate,
	|	RoomRateDailyPricesRoomTypeLimits.AccommodationTemplateCode AS AccommodationTemplateCode,
	|	RoomRateDailyPricesRoomTypeLimits.RoomType AS RoomType,
	|	RoomRateDailyPricesRoomTypeLimits.RoomTypeCode AS RoomTypeCode,
	|	RoomRateDailyPricesRoomTypeLimits.RoomTypeSortCode AS RoomTypeSortCode,
	|	RoomRateDailyPricesRoomTypeLimits.RoomTypeDescription AS RoomTypeDescription,
	|	RoomRateDailyPricesRoomTypeLimits.AccommodationType AS AccommodationType,
	|	RoomRateDailyPricesRoomTypeLimits.AccommodationTypeCode AS AccommodationTypeCode,
	|	RoomRateDailyPricesRoomTypeLimits.AccommodationTypeSortCode AS AccommodationTypeSortCode,
	|	RoomRateDailyPricesRoomTypeLimits.AccommodationTypeDescription AS AccommodationTypeDescription,
	|	RoomRateDailyPricesRoomTypeLimits.Currency AS Currency,
	|	RoomRateDailyPricesRoomTypeLimits.Currency.Code AS CurrencyCode,
	|	RoomRateDailyPricesRoomTypeLimits.CurrencyDescription AS CurrencyDescription,
	|	CASE
	|		WHEN RoomRateDailyPricesRoomTypeLimits.Period IN (&qZeroPriceDays)
	|			THEN 0
	|		ELSE (RoomRateDailyPricesRoomTypeLimits.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0)
	|	END AS Amount,
	|	CASE
	|		WHEN BEGINOFPERIOD(RoomRateDailyPricesRoomTypeLimits.Period, DAY) = BEGINOFPERIOD(&qPeriodFrom, DAY)
	|			THEN (RoomRateDailyPricesRoomTypeLimits.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0)
	|		ELSE 0
	|	END AS FirstDaySum,
	|	RoomRateDailyPricesRoomTypeLimits.RoomTypePictureLink AS RoomTypePictureLink,
	|	RoomRateDailyPricesRoomTypeLimits.RoomTypeInfoLink AS RoomTypeInfoLink,
	|	RoomRateDailyPricesRoomTypeLimits.LineNumber AS LineNumber
	|INTO RoomRateDailyPricesRoomTypeLimitsEnriched
	|FROM
	|	RoomRateDailyPricesRoomTypeLimits AS RoomRateDailyPricesRoomTypeLimits
	|		LEFT JOIN InformationRegister.CalendarDays.SliceLast(&qPriceCalculationDate, ) AS CalendarDays
	|		ON RoomRateDailyPricesRoomTypeLimits.RoomRateCalendar = CalendarDays.Calendar
	|			AND RoomRateDailyPricesRoomTypeLimits.Period = CalendarDays.AccountingDate
	|		LEFT JOIN InformationRegister.CalendarDaysByRoomTypes.SliceLast(&qPriceCalculationDate, ) AS CalendarDaysByRoomTypes
	|		ON RoomRateDailyPricesRoomTypeLimits.RoomRateCalendar = CalendarDaysByRoomTypes.Calendar
	|			AND RoomRateDailyPricesRoomTypeLimits.Period = CalendarDaysByRoomTypes.AccountingDate
	|			AND RoomRateDailyPricesRoomTypeLimits.RoomType = CalendarDaysByRoomTypes.RoomType
	|		LEFT JOIN RoomRateFormulas AS RoomRateFormulas
	|		ON RoomRateDailyPricesRoomTypeLimits.RoomRate = RoomRateFormulas.RoomRate
	|			AND RoomRateDailyPricesRoomTypeLimits.Hotel = RoomRateFormulas.Hotel
	|			AND (NOT RoomRateFormulas.IsFormula
	|				OR RoomRateFormulas.IsFormula
	|					AND RoomRateDailyPricesRoomTypeLimits.RoomType = RoomRateFormulas.RoomType
	|					AND RoomRateDailyPricesRoomTypeLimits.ClientType = &qClientType
	|					AND RoomRateDailyPricesRoomTypeLimits.AccommodationType = RoomRateFormulas.AccommodationType
	|					AND (CalendarDaysByRoomTypes.CalendarDayType = RoomRateFormulas.CalendarDayType
	|							AND NOT CalendarDaysByRoomTypes.CalendarDayType IS NULL
	|							AND CalendarDaysByRoomTypes.CalendarDayType <> VALUE(Catalog.CalendarDayTypes.EmptyRef)
	|						OR CalendarDays.CalendarDayType = RoomRateFormulas.CalendarDayType
	|							AND NOT CalendarDays.CalendarDayType IS NULL
	|							AND (CalendarDaysByRoomTypes.CalendarDayType IS NULL OR CalendarDaysByRoomTypes.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef))
	|						OR RoomRateFormulas.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef)))
	|			AND (RoomRateFormulas.BasedOnPriceTag = VALUE(Catalog.PriceTags.EmptyRef)
	|				OR RoomRateDailyPricesRoomTypeLimits.PriceTag = RoomRateFormulas.BasedOnPriceTag
	|					AND RoomRateFormulas.BasedOnPriceTag <> VALUE(Catalog.PriceTags.EmptyRef))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomRatePrices.Period AS Period,
	|	RoomRatePrices.Hotel AS Hotel,
	|	RoomRatePrices.HotelCode AS HotelCode,
	|	RoomRatePrices.HotelSortCode AS HotelSortCode,
	|	RoomRatePrices.HotelDescription AS HotelDescription,
	|	RoomRatePrices.RoomRate AS RoomRate,
	|	RoomRatePrices.RoomRateCode AS RoomRateCode,
	|	RoomRatePrices.RoomRateSortCode AS RoomRateSortCode,
	|	RoomRatePrices.RoomRateDescription AS RoomRateDescription,
	|	RoomRatePrices.AccommodationTemplate AS AccommodationTemplate,
	|	RoomRatePrices.AccommodationTemplateCode AS AccommodationTemplateCode,
	|	RoomRatePrices.RoomType AS RoomType,
	|	RoomRatePrices.RoomTypeCode AS RoomTypeCode,
	|	RoomRatePrices.RoomTypeSortCode AS RoomTypeSortCode,
	|	RoomRatePrices.RoomTypeDescription AS RoomTypeDescription,
	|	RoomRatePrices.AccommodationType AS AccommodationType,
	|	RoomRatePrices.AccommodationTypeCode AS AccommodationTypeCode,
	|	RoomRatePrices.AccommodationTypeSortCode AS AccommodationTypeSortCode,
	|	RoomRatePrices.AccommodationTypeDescription AS AccommodationTypeDescription,
	|	RoomRatePrices.Currency AS Currency,
	|	RoomRatePrices.CurrencyCode AS CurrencyCode,
	|	RoomRatePrices.CurrencyDescription AS CurrencyDescription,
	|	RoomRatePrices.RoomTypePictureLink AS RoomTypePictureLink,
	|	RoomRatePrices.RoomTypeInfoLink AS RoomTypeInfoLink,
	|	RoomRatePrices.LineNumber AS LineNumber,
	|	SUM(RoomRatePrices.Amount) AS AmountBeforeDiscount,
	|	SUM(RoomRatePrices.Amount) AS Amount,
	|	SUM(RoomRatePrices.FirstDaySum) AS FirstDaySum
	|FROM
	|	(SELECT
	|		RoomRateDailyPricesNoRoomTypeLimits.Period AS Period,
	|		RoomRateDailyPricesNoRoomTypeLimits.Hotel AS Hotel,
	|		RoomRateDailyPricesNoRoomTypeLimits.HotelCode AS HotelCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.HotelSortCode AS HotelSortCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.HotelDescription AS HotelDescription,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomRate AS RoomRate,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomRateCode AS RoomRateCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomRateSortCode AS RoomRateSortCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomRateDescription AS RoomRateDescription,
	|		RoomRateDailyPricesNoRoomTypeLimits.AccommodationTemplate AS AccommodationTemplate,
	|		RoomRateDailyPricesNoRoomTypeLimits.AccommodationTemplateCode AS AccommodationTemplateCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomType AS RoomType,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomTypeCode AS RoomTypeCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomTypeSortCode AS RoomTypeSortCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomTypeDescription AS RoomTypeDescription,
	|		RoomRateDailyPricesNoRoomTypeLimits.AccommodationType AS AccommodationType,
	|		RoomRateDailyPricesNoRoomTypeLimits.AccommodationTypeCode AS AccommodationTypeCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.AccommodationTypeSortCode AS AccommodationTypeSortCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.AccommodationTypeDescription AS AccommodationTypeDescription,
	|		RoomRateDailyPricesNoRoomTypeLimits.Currency AS Currency,
	|		RoomRateDailyPricesNoRoomTypeLimits.CurrencyCode AS CurrencyCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.CurrencyDescription AS CurrencyDescription,
	|		RoomRateDailyPricesNoRoomTypeLimits.Amount AS Amount,
	|		RoomRateDailyPricesNoRoomTypeLimits.FirstDaySum AS FirstDaySum,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomTypePictureLink AS RoomTypePictureLink,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomTypeInfoLink AS RoomTypeInfoLink,
	|		RoomRateDailyPricesNoRoomTypeLimits.LineNumber AS LineNumber
	|	FROM
	|		RoomRateDailyPricesNoRoomTypeLimitsEnriched AS RoomRateDailyPricesNoRoomTypeLimits
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RoomRateDailyPricesRoomTypeLimits.Period,
	|		RoomRateDailyPricesRoomTypeLimits.Hotel,
	|		RoomRateDailyPricesRoomTypeLimits.HotelCode,
	|		RoomRateDailyPricesRoomTypeLimits.HotelSortCode,
	|		RoomRateDailyPricesRoomTypeLimits.HotelDescription,
	|		RoomRateDailyPricesRoomTypeLimits.RoomRate,
	|		RoomRateDailyPricesRoomTypeLimits.RoomRateCode,
	|		RoomRateDailyPricesRoomTypeLimits.RoomRateSortCode,
	|		RoomRateDailyPricesRoomTypeLimits.RoomRateDescription,
	|		RoomRateDailyPricesRoomTypeLimits.AccommodationTemplate,
	|		RoomRateDailyPricesRoomTypeLimits.AccommodationTemplateCode,
	|		RoomRateDailyPricesRoomTypeLimits.RoomType,
	|		RoomRateDailyPricesRoomTypeLimits.RoomTypeCode,
	|		RoomRateDailyPricesRoomTypeLimits.RoomTypeSortCode,
	|		RoomRateDailyPricesRoomTypeLimits.RoomTypeDescription,
	|		RoomRateDailyPricesRoomTypeLimits.AccommodationType,
	|		RoomRateDailyPricesRoomTypeLimits.AccommodationTypeCode,
	|		RoomRateDailyPricesRoomTypeLimits.AccommodationTypeSortCode,
	|		RoomRateDailyPricesRoomTypeLimits.AccommodationTypeDescription,
	|		RoomRateDailyPricesRoomTypeLimits.Currency,
	|		RoomRateDailyPricesRoomTypeLimits.Currency.Code,
	|		RoomRateDailyPricesRoomTypeLimits.CurrencyDescription,
	|		RoomRateDailyPricesRoomTypeLimits.Amount,
	|		RoomRateDailyPricesRoomTypeLimits.FirstDaySum,
	|		RoomRateDailyPricesRoomTypeLimits.RoomTypePictureLink,
	|		RoomRateDailyPricesRoomTypeLimits.RoomTypeInfoLink,
	|		RoomRateDailyPricesRoomTypeLimits.LineNumber
	|	FROM
	|		RoomRateDailyPricesRoomTypeLimitsEnriched AS RoomRateDailyPricesRoomTypeLimits) AS RoomRatePrices
	|
	|GROUP BY
	|	RoomRatePrices.Period,
	|	RoomRatePrices.Hotel,
	|	RoomRatePrices.HotelCode,
	|	RoomRatePrices.HotelSortCode,
	|	RoomRatePrices.HotelDescription,
	|	RoomRatePrices.RoomRate,
	|	RoomRatePrices.RoomRateCode,
	|	RoomRatePrices.RoomRateSortCode,
	|	RoomRatePrices.RoomRateDescription,
	|	RoomRatePrices.AccommodationTemplate,
	|	RoomRatePrices.AccommodationTemplateCode,
	|	RoomRatePrices.RoomType,
	|	RoomRatePrices.RoomTypeCode,
	|	RoomRatePrices.RoomTypeSortCode,
	|	RoomRatePrices.RoomTypeDescription,
	|	RoomRatePrices.AccommodationType,
	|	RoomRatePrices.AccommodationTypeCode,
	|	RoomRatePrices.AccommodationTypeSortCode,
	|	RoomRatePrices.AccommodationTypeDescription,
	|	RoomRatePrices.Currency,
	|	RoomRatePrices.CurrencyCode,
	|	RoomRatePrices.CurrencyDescription,
	|	RoomRatePrices.RoomTypePictureLink,
	|	RoomRatePrices.RoomTypeInfoLink,
	|	RoomRatePrices.LineNumber
	|
	|ORDER BY
	|	RoomRatePrices.HotelSortCode,
	|	RoomRatePrices.HotelDescription,
	|	RoomRatePrices.RoomRateSortCode,
	|	RoomRatePrices.RoomRateDescription,
	|	RoomRatePrices.RoomTypeSortCode,
	|	RoomRatePrices.Period,
	|	RoomRatePrices.AccommodationTemplateCode,
	|	RoomRatePrices.AccommodationTypeSortCode";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qClientType", pClientType);
	vQry.SetParameter("qPeriodFrom", pPeriodFrom);
	vQry.SetParameter("qPeriodTo", pPeriodTo);
	vQry.SetParameter("qPriceTag", pPriceTag);
	vQry.SetParameter("qZeroPriceDays", cmGetZeroPriceDaysByDiscountType(pDiscountType, pPeriodFrom, pPeriodTo));
	
	vRoomRatesList = New ValueList();
	If TypeOf(pRoomRatesList) = Type("ValueList") Then
		vRoomRatesList = pRoomRatesList;
	Else
		vRoomRatesList.Add(pRoomRatesList);
	EndIf;
	vQry.SetParameter("qRoomRatesList", vRoomRatesList);
	
	vRoomRates = New ValueTable();
	vRoomRates.Columns.Add("RoomRateInCache", cmGetCatalogTypeDescription("RoomRates"));
	vRoomRates.Columns.Add("RoomRate", cmGetCatalogTypeDescription("RoomRates"));
	vRoomRates.Columns.Add("RoomRateCode", cmGetStringTypeDescription(25));
	vRoomRates.Columns.Add("RoomRateSortCode", cmGetNumberTypeDescription(6, 0, True));
	vRoomRates.Columns.Add("RoomRateDescription", cmGetStringTypeDescription(100));
	vRoomRates.Columns.Add("RoomRateCalendar", cmGetCatalogTypeDescription("Calendars"));
	For Each vRoomRatesListItem In vRoomRatesList Do
		vRoomRateRef = vRoomRatesListItem.Value;
		vRoomRatesRow = vRoomRates.Add();
		vRoomRatesRow.RoomRateInCache = ?(ValueIsFilled(vRoomRateRef.BasedOnRoomRate), vRoomRateRef.BasedOnRoomRate, vRoomRateRef);
		vRoomRatesRow.RoomRate = vRoomRateRef;
		vRoomRatesRow.RoomRateCode = vRoomRateRef.Code;
		vRoomRatesRow.RoomRateSortCode = vRoomRateRef.SortCode;
		vRoomRatesRow.RoomRateDescription = vRoomRateRef.Description;
		vRoomRatesRow.RoomRateCalendar = vRoomRateRef.Calendar;
	EndDo;
	vQry.SetParameter("qRoomRates", vRoomRates);

	vRoomTypesList = New ValueList();
	vRoomTypes = cmGetAllRoomTypes(pHotel);
	vRoomTypesList.LoadValues(vRoomTypes.UnloadColumn("RoomType"));
	
	vTemplatesNoRoomTypeLimits = New ValueList();
	vTemplatesWithRoomTypeLimits = New ValueList();
	For Each vAccTemplateItem In pAccTemplates Do
		vAccTemplateRef = vAccTemplateItem.Value;
		If vAccTemplateRef.RoomTypes.Count() = 0 Then
			vTemplatesNoRoomTypeLimits.Add(vAccTemplateRef);
		Else
			vTemplatesWithRoomTypeLimits.Add(vAccTemplateRef);
		EndIf;
	EndDo;
	vQry.SetParameter("qTemplatesNoRoomTypeLimits", vTemplatesNoRoomTypeLimits);
	vQry.SetParameter("qTemplatesWithRoomTypeLimits", vTemplatesWithRoomTypeLimits);
	
	vQry.SetParameter("qPriceCalculationDate", CurrentSessionDate());
	
	// Execute query
	vPrices = vQry.Execute().Unload();
	vServicePackagesList = New ValueList();
	vServicePackagesCache = Undefined;
	vPricesRowsToDelete = New Array();
	
	vDiscountsCache = Undefined;
	rRoomDiscount = 0;
	vRoomDiscount = 0;
	If pDiscountType <> Undefined And pExternalSystemCode <> Undefined Then
		vRoomDiscount = GetDiscountByType(pExternalSystemCode, pDiscountType, pHotel, , vDiscountsCache);
		rRoomDiscount = vRoomDiscount;
	EndIf;
	
	// Get room rate restrictions
	vRestrictions = cmGetRoomRatesRestrictions(pHotel, vRoomRatesList, vRoomTypesList, cm1SecondShift(pPeriodFrom), cm0SecondShift(pPeriodTo), pWithoutOnline);
	
	vRestrictionsCache = New ValueTable();
	vRestrictionsCache.Columns.Add("RoomRate", cmGetCatalogTypeDescription("RoomRates"));
	vRestrictionsCache.Columns.Add("RoomType", cmGetCatalogTypeDescription("RoomTypes"));
	vRestrictionsCache.Columns.Add("PeriodFrom", cmGetDateTypeDescription());
	vRestrictionsCache.Columns.Add("PeriodTo", cmGetDateTypeDescription());
	vRestrictionsCache.Columns.Add("IsRestricted", cmGetBooleanTypeDescription());
	
	// Process prices
	vCurRoomRate = Undefined;
	vCurRoomType1 = Undefined;
	vCurRoomType2 = Undefined;
	For Each vPriceRow In vPrices Do
		vCurDate = vPriceRow.Period;
		
		If vCurRoomRate <> vPriceRow.RoomRate Then
			vCurRoomRate = vPriceRow.RoomRate;
			vCurRoomRateBasedOnRoomRate = vCurRoomRate.BasedOnRoomRate;
			vCurRoomType1 = Undefined;
			vCurRoomType2 = Undefined;
			
			vServicePackagesList = New ValueList();
			
			If ValueIsFilled(vCurRoomRateBasedOnRoomRate) Then
				// We have to take differencies in the packages into account only
				vServicePackagesListForBasedOnRoomRate = vCurRoomRateBasedOnRoomRate.GetObject().pmGetRoomRateServicePackagesList(, True);
				vServicePackagesList = vCurRoomRate.GetObject().pmGetRoomRateServicePackagesList(, True);

				// Add to the current rate service packages list service packages that were removed from the base room rate
				i = 0;
				While i < vServicePackagesListForBasedOnRoomRate.Count() Do
					vSPRemovedFromBasedRR = vServicePackagesListForBasedOnRoomRate.Get(i).Value;
					If vServicePackagesList.FindByValue(vSPRemovedFromBasedRR) = Undefined Then
						vServicePackagesList.Add(vSPRemovedFromBasedRR, , True);
					EndIf;
					i = i + 1;
				EndDo;
				
				// Delete service packages that are present in the based on room rate list of service packages
				If vServicePackagesListForBasedOnRoomRate.Count() > 0 Then
					i = 0;
					While i < vServicePackagesList.Count() Do
						vServicePackagesListItem = vServicePackagesList.Get(i);
						If Not vServicePackagesListItem.Check Then
							vCurServicePackage = vServicePackagesListItem.Value;
							If vServicePackagesListForBasedOnRoomRate.FindByValue(vCurServicePackage) <> Undefined Then
								vDeleteSP = True;
								For Each vSPRow In vCurServicePackage.Services Do
									If vSPRow.IsInPrice And (vSPRow.AccountingDayNumber <> 0 Or ValueIsFilled(vSPRow.AccountingDate)) Then
										vDeleteSP = False;
										Break;
									EndIf;
								EndDo;
								If vDeleteSP Then
									vServicePackagesList.Delete(i);
								Else
									vServicePackagesListItem.Presentation = "<<DO_NOT_PROCESS>>";
									i = i + 1;
								EndIf;
							Else
								i = i + 1;
							EndIf;
						Else
							i = i + 1;
						EndIf;
					EndDo;
				EndIf;
			Else
				vServicePackagesList = vCurRoomRate.GetObject().pmGetRoomRateServicePackagesList(, True);
				i = 0;
				While i < vServicePackagesList.Count() Do
					vCurServicePackage = vServicePackagesList.Get(i).Value;
					vDeleteSP = True;
					For Each vSPRow In vCurServicePackage.Services Do
						If vSPRow.IsInPrice And (vSPRow.AccountingDayNumber <> 0 Or ValueIsFilled(vSPRow.AccountingDate)) Then
							vDeleteSP = False;
							Break;
						EndIf;
					EndDo;
					If vDeleteSP Then
						vServicePackagesList.Delete(i);
					Else
						i = i + 1;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		
		// Check room rate restrictions
		vRestrictionsCacheRows = vRestrictionsCache.FindRows(New Structure("RoomRate, RoomType, PeriodFrom, PeriodTo", vCurRoomRate, vPriceRow.RoomType, BegOfDay(pPeriodFrom), BegOfDay(pPeriodTo)));
		If vRestrictionsCacheRows.Count() > 0 Then
			vRestrictionsCacheRow = vRestrictionsCacheRows.Get(0);
			If vRestrictionsCacheRow.IsRestricted Then
				vPricesRowsToDelete.Add(vPriceRow);
				Continue;
			EndIf;
		Else
			If vCurRoomType1 <> vPriceRow.RoomType Then 
				vCurRoomType1 = vPriceRow.RoomType;

				vRestrictionsCacheRow = vRestrictionsCache.Add();
				vRestrictionsCacheRow.RoomRate = vCurRoomRate;
				vRestrictionsCacheRow.RoomType = vPriceRow.RoomType;
				vRestrictionsCacheRow.PeriodFrom = BegOfDay(pPeriodFrom);
				vRestrictionsCacheRow.PeriodTo = BegOfDay(pPeriodTo);
				vRestrictionsCacheRow.IsRestricted = False;
				If Not cmCheckRestrictions(vRestrictions, pHotel, vCurRoomRate, vCurRoomType1, cm1SecondShift(pPeriodFrom), cm0SecondShift(pPeriodTo), pWithoutLOSAndCTs) Then
					vRestrictionsCacheRow.IsRestricted = True;
					vPricesRowsToDelete.Add(vPriceRow);
					Continue;
				EndIf;
			EndIf;
		EndIf;
				
		// Get discounts by promo code
		If vCurRoomType2 <> vPriceRow.RoomType Then 
			vCurRoomType2 = vPriceRow.RoomType;
			
			vPromoCodeDiscounts = New ValueTable();
			vPromoCodeDiscounts.Columns.Add("AccountingDate", cmGetDateTypeDescription());
			vPromoCodeDiscounts.Columns.Add("Discount", cmGetNumberTypeDescription(7, 3));
			If pPromoCodeStruct <> Undefined And Not IsBlankString(pPromoCodeStruct.PromoCode) Then
				vDatesList = Undefined;
				vSpecialOfferByPromoCode = Catalogs.SpecialOffers.GetSpecialOfferByPromoCode(pPromoCodeStruct.PromoCode, vCurRoomType2.Owner, pPromoCodeStruct.Date, pPromoCodeStruct.PeriodFrom, pPromoCodeStruct.Duration, pPromoCodeStruct.PeriodTo, vCurRoomRate, vCurRoomRate.RoomRateType, pPromoCodeStruct.ClientType, pPromoCodeStruct.CustomerType, pPromoCodeStruct.SourceOfBusiness, pPromoCodeStruct.MarketingCode, pPromoCodeStruct.TripPurpose, vCurRoomType2, vDatesList);
				If ValueIsFilled(vSpecialOfferByPromoCode) And ValueIsFilled(vSpecialOfferByPromoCode.DiscountType) Then
					For Each vDatesListItem In vDatesList Do
						vPromoCodeDiscount = GetDiscountByType(pExternalSystemCode, vSpecialOfferByPromoCode.DiscountType, pPromoCodeStruct.Hotel, vDatesListItem.Value, vDiscountsCache);
						If vPromoCodeDiscount <> 0 Then
							vPromoCodeDiscountsRow = vPromoCodeDiscounts.Add();
							vPromoCodeDiscountsRow.AccountingDate = vDatesListItem.Value;
							vPromoCodeDiscountsRow.Discount = vPromoCodeDiscount;
						EndIf;
					EndDo;
				EndIf;
			EndIf;
		EndIf;

		// Apply room rate rounding rules 
		If ValueIsFilled(vCurRoomRate) Then
			If vCurRoomRate.RoundPrice Then
				vPriceRow.Amount = Round(vPriceRow.Amount, vCurRoomRate.RoundPriceDigits);
				vPriceRow.AmountBeforeDiscount = Round(vPriceRow.AmountBeforeDiscount, vCurRoomRate.RoundPriceDigits);
				vPriceRow.FirstDaySum = Round(vPriceRow.FirstDaySum, vCurRoomRate.RoundPriceDigits);
			EndIf;
		EndIf;

		// Apply discounts
		vDiscount = 0;
		If ValueIsFilled(vCurRoomRate) And Not vCurRoomRate.NoDiscounts Then
			vDiscount = vRoomDiscount;
			If pPromoCodeStruct <> Undefined And vPromoCodeDiscounts.Count() > 0 Then
				vPromoCodeDiscountsRows = vPromoCodeDiscounts.FindRows(New Structure("AccountingDate", vCurDate));
				If vPromoCodeDiscountsRows.Count() > 0 Then
					vPromoCodeDiscountsRow = vPromoCodeDiscountsRows.Get(0);
					vDiscount = Max(vPromoCodeDiscountsRow.Discount, vDiscount);
				EndIf;
			EndIf;
		EndIf;
		If vDiscount <> 0 Then
			rRoomDiscount = Max(rRoomDiscount, vDiscount);
			vPriceRow.Amount = vPriceRow.Amount - (vPriceRow.Amount * (vDiscount/100));
			vPriceRow.FirstDaySum = vPriceRow.FirstDaySum - (vPriceRow.FirstDaySum * (vDiscount/100));
			// Apply room rate price rounding rule
			If vCurRoomRate.RoundPrice Then
				vPriceRow.Amount = Round(vPriceRow.Amount, vCurRoomRate.RoundPriceDigits);
				vPriceRow.FirstDaySum = Round(vPriceRow.FirstDaySum, vCurRoomRate.RoundPriceDigits);
			EndIf;
		EndIf;
		
		For Each vServicePackagesItem In vServicePackagesList Do
			vCurServicePackage = vServicePackagesItem.Value;
			vServicePackagesItemPresentation = vServicePackagesItem.Presentation;
			// Check service package is valid period
			If vCurServicePackage.DateValidFrom <= BegOfDay(pPeriodFrom) And (vCurServicePackage.DateValidTo >= BegOfDay(pPeriodFrom) Or Not ValueIsFilled(vCurServicePackage.DateValidTo)) Then
				vCurCalendarDayType = Undefined;
				
				// Get service package services
				vCurServicePackageServices = Undefined;
				If vServicePackagesCache <> Undefined Then
					vCurServicePackageServices = vServicePackagesCache.FindRows(New Structure("ServicePackage, Period", vCurServicePackage, vCurDate));
					If vCurServicePackageServices.Count() = 0 Then
						vCurServicePackageServices = Undefined;
					EndIf;
				EndIf;
				If vCurServicePackageServices = Undefined Then
					vCurServicePackageServices = Catalogs.ServicePackages.GetServices(vCurServicePackage, vCurDate);
					If vServicePackagesCache = Undefined Then
						vServicePackagesCache = vCurServicePackageServices.Copy();
						vServicePackagesCache.Indexes.Add("ServicePackage, Period");
					Else
						For Each vCurServicePackageServicesRow In vCurServicePackageServices Do
							vServicePackagesCacheRow = vServicePackagesCache.Add();
							FillPropertyValues(vServicePackagesCacheRow, vCurServicePackageServicesRow);
						EndDo;
					EndIf;
				EndIf;
				For Each vSPRow In vCurServicePackageServices Do
					If vSPRow.IsInPrice And ValueIsFilled(vCurRoomRate) And 
					  (vSPRow.AccountingDayNumber <> 0 And ((vCurDate - BegOfDay(pPeriodFrom))/(24*3600) + 1) = vSPRow.AccountingDayNumber Or 
					   vSPRow.AccountingDayNumber = 9999 And BegOfDay(pPeriodTo) = vCurDate Or 
					   ValueIsFilled(vSPRow.AccountingDate) And vSPRow.AccountingDate = vCurDate Or 
					   vSPRow.AccountingDayNumber = 0 And Not ValueIsFilled(vSPRow.AccountingDate) And ValueIsFilled(vCurRoomRateBasedOnRoomRate) And vCurDate < BegOfDay(pPeriodTo) And vServicePackagesItemPresentation <> "<<DO_NOT_PROCESS>>") Then
						If vServicePackagesItem.Check And (vSPRow.AccountingDayNumber <> 0 Or ValueIsFilled(vSPRow.AccountingDate)) Then
						   Continue;
						EndIf;
					   
						// Check accounting date time for service package
						If ValueIsFilled(vSPRow.AccountingDate) And vSPRow.AccountingDate <> BegOfDay(vSPRow.AccountingDate) Then
							If BegOfDay(pPeriodFrom) = BegOfDay(vSPRow.AccountingDate) And vSPRow.AccountingDate <= pPeriodFrom Then
								Continue;
							EndIf;
							If BegOfDay(pPeriodTo) = BegOfDay(vSPRow.AccountingDate) And vSPRow.AccountingDate >= pPeriodTo Then
								Continue;
							EndIf;
						EndIf;
						
						// Check current client type
						If pClientType <> vSPRow.ClientType Then
							Continue;
						EndIf;
											
						// Get and check date calendar day type
						If ValueIsFilled(vSPRow.CalendarDayType) Then
							If vCurCalendarDayType = Undefined Then
								vPriceTag = Undefined;
								vCurCalendarDayType = cmGetCalendarDayType(vCurRoomRate, vCurDate, pPeriodFrom, pPeriodTo, vPriceTag, vPriceRow.RoomType);
							EndIf;
							If vSPRow.CalendarDayType <> vCurCalendarDayType Then
								Continue;
							EndIf;
						EndIf;
						
						// Update price rows in prices
						If (Not ValueIsFilled(vSPRow.RoomType) Or ValueIsFilled(vSPRow.RoomType) And vSPRow.RoomType = vPriceRow.RoomType) And 
						   (Not ValueIsFilled(vSPRow.AccommodationType) Or ValueIsFilled(vSPRow.AccommodationType) And vSPRow.AccommodationType = vPriceRow.AccommodationType) Then
							vPrice = Round(cmConvertCurrencies(vSPRow.Price * ?(vSPRow.Quantity > 0, vSPRow.Quantity, 1), vSPRow.Currency, , vPriceRow.Currency, , vCurDate, pHotel), 2);
							vPriceAfterDiscount = vPrice - (vPrice * (vDiscount/100));
							// Apply room rate price rounding rule
							If vCurRoomRate.RoundPrice Then
								If Not ValueIsFilled(vCurRoomRate.RoundPriceServiceGroup) Or 
								   ValueIsFilled(vCurRoomRate.RoundPriceServiceGroup) And cmIsServiceInServiceGroup(vSPRow.Service, vCurRoomRate.RoundPriceServiceGroup) Then
									vPriceAfterDiscount = Round(vPriceAfterDiscount, vCurRoomRate.RoundPriceDigits);
								EndIf;
							EndIf;
							
							vPriceRow.AmountBeforeDiscount = vPriceRow.AmountBeforeDiscount + ?(vServicePackagesItem.Check, -vPrice, vPrice);
							vPriceRow.Amount = vPriceRow.Amount + ?(vServicePackagesItem.Check, -vPriceAfterDiscount, vPriceAfterDiscount);
							If vCurDate = BegOfDay(pPeriodFrom) Then
								vPriceRow.FirstDaySum = vPriceRow.FirstDaySum + ?(vServicePackagesItem.Check, -vPriceAfterDiscount, vPriceAfterDiscount);
							EndIf;
						EndIf;
					EndIf;
				EndDo; // by service package services
			EndIf;
		EndDo; // by service packages
	EndDo;
	For Each vRowToDelete In vPricesRowsToDelete Do
		vPrices.Delete(vRowToDelete);
	EndDo;
	vPrices.GroupBy("Hotel, HotelCode, HotelSortCode, HotelDescription, RoomRate, RoomRateCode, RoomRateSortCode, RoomRateDescription, AccommodationTemplate, AccommodationTemplateCode, RoomType, RoomTypeCode, RoomTypeSortCode, RoomTypeDescription, AccommodationType, AccommodationTypeCode, AccommodationTypeSortCode, AccommodationTypeDescription, Currency, CurrencyCode, CurrencyDescription, RoomTypePictureLink, RoomTypeInfoLink, LineNumber", 
	                "AmountBeforeDiscount, Amount, FirstDaySum");
	vPrices.Sort("HotelSortCode, HotelDescription, RoomRateSortCode, RoomRateDescription, RoomTypeSortCode, AccommodationTemplateCode, AccommodationTypeSortCode");
	Return vPrices;
EndFunction // GetCachedPrices

// -----------------------------------------------------------------------------
// Returns cached room rate prices for the given accommodation templates and period
// -----------------------------------------------------------------------------
Function GetCachedPricesByDays(pHotel, pClientType, pPeriodFrom, pPeriodTo, pPriceTag, pRoomRatesList, pAccTemplates, pWithoutOnline = False, pWithoutLOSAndCTs = False, pDiscountType = Undefined, pExternalSystemCode = Undefined, rRoomDiscount = 0, pRoomType = Undefined) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomRates.RoomRateInCache AS RoomRateInCache,
	|	RoomRates.RoomRate AS RoomRate,
	|	RoomRates.RoomRateCode AS RoomRateCode,
	|	RoomRates.RoomRateSortCode AS RoomRateSortCode,
	|	RoomRates.RoomRateDescription AS RoomRateDescription,
	|	RoomRates.RoomRateCalendar AS RoomRateCalendar
	|INTO CacheRoomRates
	|FROM
	|	&qRoomRates AS RoomRates
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomRatesSliceLast.SetRoomRateFormulas AS Recorder,
	|	RoomRatesSliceLast.RoomRate AS RoomRate
	|INTO ActiveSetRoomRateFormulas
	|FROM
	|	InformationRegister.RoomRates.SliceLast(
	|			&qPriceCalculationDate,
	|			RoomRate IN (&qRoomRatesList)
	|				AND Hotel = &qHotel
	|				AND IsFormula) AS RoomRatesSliceLast
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CacheRoomRates.RoomRate AS RoomRate,
	|	&qHotel AS Hotel,
	|	AccommodationTemplatesAccommodationTypes.Ref AS AccommodationTemplate,
	|	HotelRoomTypes.Ref AS RoomType,
	|	HotelRoomTypes.RoomClass AS RoomClass,
	|	CASE
	|		WHEN NOT RoomRateOverrides.ToAccommodationType IS NULL
	|			THEN RoomRateOverrides.ToAccommodationType
	|		ELSE AccommodationTemplatesAccommodationTypes.AccommodationType
	|	END AS AccommodationType,
	|	AccommodationTemplatesAccommodationTypes.LineNumber AS LineNumber
	|INTO AccommodationTypesInTemplatesNoRoomTypeLimits
	|FROM
	|	CacheRoomRates AS CacheRoomRates
	|		LEFT JOIN Catalog.RoomTypes AS HotelRoomTypes
	|		ON (HotelRoomTypes.Owner = &qHotel)
	|			AND (&qRoomTypeIsEmpty OR NOT &qRoomTypeIsEmpty AND HotelRoomTypes.Ref = &qRoomType)
	|			AND (NOT HotelRoomTypes.DeletionMark)
	|			AND (NOT HotelRoomTypes.IsFolder)
	|		INNER JOIN Catalog.AccommodationTemplates.AccommodationTypes AS AccommodationTemplatesAccommodationTypes
	|		ON (AccommodationTemplatesAccommodationTypes.Ref IN (&qTemplatesNoRoomTypeLimits))
	|		LEFT JOIN InformationRegister.RoomRateOverrides AS RoomRateOverrides
	|		ON CacheRoomRates.RoomRate = RoomRateOverrides.RoomRate
	|			AND (&qHotel = RoomRateOverrides.Hotel)
	|			AND (AccommodationTemplatesAccommodationTypes.Ref = RoomRateOverrides.AccommodationTemplate)
	|			AND (HotelRoomTypes.Ref = RoomRateOverrides.RoomType
	|				OR RoomRateOverrides.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
	|			AND (AccommodationTemplatesAccommodationTypes.AccommodationType = RoomRateOverrides.AccommodationType)
	|			AND (AccommodationTemplatesAccommodationTypes.LineNumber = RoomRateOverrides.TemplateLineNumber)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CacheRoomRates.RoomRate AS RoomRate,
	|	&qHotel AS Hotel,
	|	AccommodationTemplatesAccommodationTypes.Ref AS AccommodationTemplate,
	|	HotelRoomTypes.Ref AS RoomType,
	|	HotelRoomTypes.RoomClass AS RoomClass,
	|	CASE
	|		WHEN NOT RoomRateOverrides.ToAccommodationType IS NULL
	|			THEN RoomRateOverrides.ToAccommodationType
	|		ELSE AccommodationTemplatesAccommodationTypes.AccommodationType
	|	END AS AccommodationType,
	|	AccommodationTemplatesAccommodationTypes.LineNumber AS LineNumber
	|INTO AccommodationTypesInTemplatesWithRoomTypeLimits
	|FROM
	|	CacheRoomRates AS CacheRoomRates
	|		LEFT JOIN Catalog.RoomTypes AS HotelRoomTypes
	|		ON (HotelRoomTypes.Owner = &qHotel)
	|			AND (&qRoomTypeIsEmpty OR NOT &qRoomTypeIsEmpty AND HotelRoomTypes.Ref = &qRoomType)
	|			AND (NOT HotelRoomTypes.DeletionMark)
	|			AND (NOT HotelRoomTypes.IsFolder)
	|		INNER JOIN Catalog.AccommodationTemplates.AccommodationTypes AS AccommodationTemplatesAccommodationTypes
	|		ON (AccommodationTemplatesAccommodationTypes.Ref IN (&qTemplatesWithRoomTypeLimits))
	|		INNER JOIN Catalog.AccommodationTemplates.RoomTypes AS AccommodationTemplatesRoomTypes
	|		ON (AccommodationTemplatesAccommodationTypes.Ref = AccommodationTemplatesRoomTypes.Ref)
	|			AND (HotelRoomTypes.Ref = AccommodationTemplatesRoomTypes.RoomType
	|					AND AccommodationTemplatesRoomTypes.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
	|				OR HotelRoomTypes.RoomClass = AccommodationTemplatesRoomTypes.RoomClass
	|					AND AccommodationTemplatesRoomTypes.RoomClass <> VALUE(Catalog.RoomTypeClasses.EmptyRef))
	|		LEFT JOIN InformationRegister.RoomRateOverrides AS RoomRateOverrides
	|		ON CacheRoomRates.RoomRate = RoomRateOverrides.RoomRate
	|			AND (&qHotel = RoomRateOverrides.Hotel)
	|			AND (AccommodationTemplatesAccommodationTypes.Ref = RoomRateOverrides.AccommodationTemplate)
	|			AND (HotelRoomTypes.Ref = RoomRateOverrides.RoomType
	|				OR RoomRateOverrides.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
	|			AND (AccommodationTemplatesAccommodationTypes.AccommodationType = RoomRateOverrides.AccommodationType)
	|			AND (AccommodationTemplatesAccommodationTypes.LineNumber = RoomRateOverrides.TemplateLineNumber)
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
	|	RoomRateDailyPrices.Period AS Period,
	|	RoomRateDailyPrices.Hotel AS Hotel,
	|	RoomRateDailyPrices.Hotel.Code AS HotelCode,
	|	RoomRateDailyPrices.Hotel.SortCode AS HotelSortCode,
	|	RoomRateDailyPrices.Hotel.Description AS HotelDescription,
	|	CacheRoomRates.RoomRate AS RoomRate,
	|	CacheRoomRates.RoomRateCode AS RoomRateCode,
	|	CacheRoomRates.RoomRateSortCode AS RoomRateSortCode,
	|	CacheRoomRates.RoomRateDescription AS RoomRateDescription,
	|	CacheRoomRates.RoomRateCalendar AS RoomRateCalendar,
	|	AccommodationTemplatesAccommodationTypes.AccommodationTemplate AS AccommodationTemplate,
	|	AccommodationTemplatesAccommodationTypes.AccommodationTemplate.Code AS AccommodationTemplateCode,
	|	RoomRateDailyPrices.RoomType AS RoomType,
	|	RoomRateDailyPrices.RoomType.Code AS RoomTypeCode,
	|	RoomRateDailyPrices.RoomType.SortCode AS RoomTypeSortCode,
	|	RoomRateDailyPrices.RoomType.Description AS RoomTypeDescription,
	|	RoomRateDailyPrices.AccommodationType AS AccommodationType,
	|	RoomRateDailyPrices.AccommodationType.Code AS AccommodationTypeCode,
	|	RoomRateDailyPrices.AccommodationType.SortCode AS AccommodationTypeSortCode,
	|	RoomRateDailyPrices.AccommodationType.Description AS AccommodationTypeDescription,
	|	RoomRateDailyPrices.Currency AS Currency,
	|	RoomRateDailyPrices.Currency.Code AS CurrencyCode,
	|	RoomRateDailyPrices.Currency.Description AS CurrencyDescription,
	|	RoomRateDailyPrices.ClientType AS ClientType,
	|	RoomRateDailyPrices.PriceTag AS PriceTag,
	|	RoomRateDailyPrices.Price AS Price,
	|	CAST(RoomRateDailyPrices.RoomType.RoomTypePictureLink AS STRING(1024)) AS RoomTypePictureLink,
	|	CAST(RoomRateDailyPrices.RoomType.RoomTypeInfoLink AS STRING(1024)) AS RoomTypeInfoLink,
	|	AccommodationTemplatesAccommodationTypes.LineNumber AS LineNumber
	|INTO RoomRateDailyPricesNoRoomTypeLimits
	|FROM
	|	InformationRegister.RoomRateDailyPrices AS RoomRateDailyPrices
	|		INNER JOIN CacheRoomRates AS CacheRoomRates
	|		ON RoomRateDailyPrices.RoomRate = CacheRoomRates.RoomRateInCache
	|		INNER JOIN AccommodationTypesInTemplatesNoRoomTypeLimits AS AccommodationTemplatesAccommodationTypes
	|		ON (AccommodationTemplatesAccommodationTypes.AccommodationType = RoomRateDailyPrices.AccommodationType)
	|			AND (AccommodationTemplatesAccommodationTypes.RoomRate = CacheRoomRates.RoomRate)
	|			AND (AccommodationTemplatesAccommodationTypes.Hotel = RoomRateDailyPrices.Hotel)
	|			AND (AccommodationTemplatesAccommodationTypes.RoomType = RoomRateDailyPrices.RoomType)
	|WHERE
	|	RoomRateDailyPrices.Period >= &qPeriodFrom
	|	AND (RoomRateDailyPrices.Period < &qPeriodTo
	|				AND RoomRateDailyPrices.RoomRate.DurationCalculationRuleType <> VALUE(Enum.DurationCalculationRuleTypes.ByDays)
	|			OR RoomRateDailyPrices.Period <= &qPeriodTo
	|				AND RoomRateDailyPrices.RoomRate.DurationCalculationRuleType = VALUE(Enum.DurationCalculationRuleTypes.ByDays))
	|	AND RoomRateDailyPrices.Hotel = &qHotel
	|	AND RoomRateDailyPrices.ClientType = &qClientType
	|	AND RoomRateDailyPrices.PriceTag = &qPriceTag
	|	AND (&qRoomTypeIsEmpty OR NOT &qRoomTypeIsEmpty AND RoomRateDailyPrices.RoomType = &qRoomType)
	|
	|INDEX BY
	|	CacheRoomRates.RoomRateCalendar,
	|	RoomRateDailyPrices.Period,
	|	RoomRateDailyPrices.RoomType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	RoomRateDailyPricesNoRoomTypeLimits.Period AS Period,
	|	RoomRateDailyPricesNoRoomTypeLimits.Hotel AS Hotel,
	|	RoomRateDailyPricesNoRoomTypeLimits.HotelCode AS HotelCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.HotelSortCode AS HotelSortCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.HotelDescription AS HotelDescription,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomRate AS RoomRate,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomRateCode AS RoomRateCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomRateSortCode AS RoomRateSortCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomRateDescription AS RoomRateDescription,
	|	RoomRateDailyPricesNoRoomTypeLimits.AccommodationTemplate AS AccommodationTemplate,
	|	RoomRateDailyPricesNoRoomTypeLimits.AccommodationTemplateCode AS AccommodationTemplateCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomType AS RoomType,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomTypeCode AS RoomTypeCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomTypeSortCode AS RoomTypeSortCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomTypeDescription AS RoomTypeDescription,
	|	RoomRateDailyPricesNoRoomTypeLimits.AccommodationType AS AccommodationType,
	|	RoomRateDailyPricesNoRoomTypeLimits.AccommodationTypeCode AS AccommodationTypeCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.AccommodationTypeSortCode AS AccommodationTypeSortCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.AccommodationTypeDescription AS AccommodationTypeDescription,
	|	RoomRateDailyPricesNoRoomTypeLimits.Currency AS Currency,
	|	RoomRateDailyPricesNoRoomTypeLimits.CurrencyCode AS CurrencyCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.Currency.Description AS CurrencyDescription,
	|	CASE
	|		WHEN RoomRateDailyPricesNoRoomTypeLimits.Period IN (&qZeroPriceDays)
	|			THEN 0
	|		ELSE (RoomRateDailyPricesNoRoomTypeLimits.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0)
	|	END AS Amount,
	|	CASE
	|		WHEN BEGINOFPERIOD(RoomRateDailyPricesNoRoomTypeLimits.Period, DAY) = BEGINOFPERIOD(&qPeriodFrom, DAY)
	|			THEN (RoomRateDailyPricesNoRoomTypeLimits.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0)
	|		ELSE 0
	|	END AS FirstDaySum,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomTypePictureLink AS RoomTypePictureLink,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomTypeInfoLink AS RoomTypeInfoLink,
	|	RoomRateDailyPricesNoRoomTypeLimits.LineNumber AS LineNumber
	|INTO RoomRateDailyPricesNoRoomTypeLimitsEnriched
	|FROM
	|	RoomRateDailyPricesNoRoomTypeLimits AS RoomRateDailyPricesNoRoomTypeLimits
	|		LEFT JOIN InformationRegister.CalendarDays.SliceLast(&qPriceCalculationDate, ) AS CalendarDays
	|		ON RoomRateDailyPricesNoRoomTypeLimits.RoomRateCalendar = CalendarDays.Calendar
	|			AND RoomRateDailyPricesNoRoomTypeLimits.Period = CalendarDays.AccountingDate
	|		LEFT JOIN InformationRegister.CalendarDaysByRoomTypes.SliceLast(&qPriceCalculationDate, ) AS CalendarDaysByRoomTypes
	|		ON RoomRateDailyPricesNoRoomTypeLimits.RoomRateCalendar = CalendarDaysByRoomTypes.Calendar
	|			AND RoomRateDailyPricesNoRoomTypeLimits.Period = CalendarDaysByRoomTypes.AccountingDate
	|			AND RoomRateDailyPricesNoRoomTypeLimits.RoomType = CalendarDaysByRoomTypes.RoomType
	|		LEFT JOIN RoomRateFormulas AS RoomRateFormulas
	|		ON RoomRateDailyPricesNoRoomTypeLimits.RoomRate = RoomRateFormulas.RoomRate
	|			AND RoomRateDailyPricesNoRoomTypeLimits.Hotel = RoomRateFormulas.Hotel
	|			AND (NOT RoomRateFormulas.IsFormula
	|				OR RoomRateFormulas.IsFormula
	|					AND RoomRateDailyPricesNoRoomTypeLimits.RoomType = RoomRateFormulas.RoomType
	|					AND RoomRateDailyPricesNoRoomTypeLimits.ClientType = &qClientType
	|					AND RoomRateDailyPricesNoRoomTypeLimits.AccommodationType = RoomRateFormulas.AccommodationType
	|					AND (CalendarDaysByRoomTypes.CalendarDayType = RoomRateFormulas.CalendarDayType
	|							AND NOT CalendarDaysByRoomTypes.CalendarDayType IS NULL
	|							AND CalendarDaysByRoomTypes.CalendarDayType <> VALUE(Catalog.CalendarDayTypes.EmptyRef)
	|						OR CalendarDays.CalendarDayType = RoomRateFormulas.CalendarDayType
	|							AND NOT CalendarDays.CalendarDayType IS NULL
	|							AND (CalendarDaysByRoomTypes.CalendarDayType IS NULL OR CalendarDaysByRoomTypes.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef))
	|						OR RoomRateFormulas.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef)))
	|			AND (RoomRateFormulas.BasedOnPriceTag = VALUE(Catalog.PriceTags.EmptyRef)
	|				OR RoomRateDailyPricesNoRoomTypeLimits.PriceTag = RoomRateFormulas.BasedOnPriceTag
	|					AND RoomRateFormulas.BasedOnPriceTag <> VALUE(Catalog.PriceTags.EmptyRef))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomRateDailyPrices.Period AS Period,
	|	RoomRateDailyPrices.Hotel AS Hotel,
	|	RoomRateDailyPrices.Hotel.Code AS HotelCode,
	|	RoomRateDailyPrices.Hotel.SortCode AS HotelSortCode,
	|	RoomRateDailyPrices.Hotel.Description AS HotelDescription,
	|	CacheRoomRates.RoomRate AS RoomRate,
	|	CacheRoomRates.RoomRateCode AS RoomRateCode,
	|	CacheRoomRates.RoomRateSortCode AS RoomRateSortCode,
	|	CacheRoomRates.RoomRateDescription AS RoomRateDescription,
	|	CacheRoomRates.RoomRateCalendar AS RoomRateCalendar,
	|	AccommodationTemplatesAccommodationTypes.AccommodationTemplate AS AccommodationTemplate,
	|	AccommodationTemplatesAccommodationTypes.AccommodationTemplate.Code AS AccommodationTemplateCode,
	|	RoomRateDailyPrices.RoomType AS RoomType,
	|	RoomRateDailyPrices.RoomType.Code AS RoomTypeCode,
	|	RoomRateDailyPrices.RoomType.SortCode AS RoomTypeSortCode,
	|	RoomRateDailyPrices.RoomType.Description AS RoomTypeDescription,
	|	RoomRateDailyPrices.AccommodationType AS AccommodationType,
	|	RoomRateDailyPrices.AccommodationType.Code AS AccommodationTypeCode,
	|	RoomRateDailyPrices.AccommodationType.SortCode AS AccommodationTypeSortCode,
	|	RoomRateDailyPrices.AccommodationType.Description AS AccommodationTypeDescription,
	|	RoomRateDailyPrices.Currency AS Currency,
	|	RoomRateDailyPrices.Currency.Code AS CurrencyCode,
	|	RoomRateDailyPrices.Currency.Description AS CurrencyDescription,
	|	RoomRateDailyPrices.ClientType AS ClientType,
	|	RoomRateDailyPrices.PriceTag AS PriceTag,
	|	RoomRateDailyPrices.Price AS Price,
	|	CAST(RoomRateDailyPrices.RoomType.RoomTypePictureLink AS STRING(1024)) AS RoomTypePictureLink,
	|	CAST(RoomRateDailyPrices.RoomType.RoomTypeInfoLink AS STRING(1024)) AS RoomTypeInfoLink,
	|	AccommodationTemplatesAccommodationTypes.LineNumber AS LineNumber
	|INTO RoomRateDailyPricesRoomTypeLimits
	|FROM
	|	InformationRegister.RoomRateDailyPrices AS RoomRateDailyPrices
	|		INNER JOIN CacheRoomRates AS CacheRoomRates
	|		ON RoomRateDailyPrices.RoomRate = CacheRoomRates.RoomRateInCache
	|		INNER JOIN AccommodationTypesInTemplatesWithRoomTypeLimits AS AccommodationTemplatesAccommodationTypes
	|		ON (AccommodationTemplatesAccommodationTypes.AccommodationType = RoomRateDailyPrices.AccommodationType)
	|			AND (AccommodationTemplatesAccommodationTypes.RoomRate = CacheRoomRates.RoomRate)
	|			AND (AccommodationTemplatesAccommodationTypes.Hotel = RoomRateDailyPrices.Hotel)
	|			AND (AccommodationTemplatesAccommodationTypes.RoomType = RoomRateDailyPrices.RoomType)
	|WHERE
	|	RoomRateDailyPrices.Period >= &qPeriodFrom
	|	AND (RoomRateDailyPrices.Period < &qPeriodTo
	|				AND RoomRateDailyPrices.RoomRate.DurationCalculationRuleType <> VALUE(Enum.DurationCalculationRuleTypes.ByDays)
	|			OR RoomRateDailyPrices.Period <= &qPeriodTo
	|				AND RoomRateDailyPrices.RoomRate.DurationCalculationRuleType = VALUE(Enum.DurationCalculationRuleTypes.ByDays))
	|	AND RoomRateDailyPrices.Hotel = &qHotel
	|	AND RoomRateDailyPrices.ClientType = &qClientType
	|	AND RoomRateDailyPrices.PriceTag = &qPriceTag
	|	AND (&qRoomTypeIsEmpty OR NOT &qRoomTypeIsEmpty AND RoomRateDailyPrices.RoomType = &qRoomType)
	|
	|INDEX BY
	|	CacheRoomRates.RoomRateCalendar,
	|	RoomRateDailyPrices.Period,
	|	RoomRateDailyPrices.RoomType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	RoomRateDailyPricesRoomTypeLimits.Period AS Period,
	|	RoomRateDailyPricesRoomTypeLimits.Hotel AS Hotel,
	|	RoomRateDailyPricesRoomTypeLimits.HotelCode AS HotelCode,
	|	RoomRateDailyPricesRoomTypeLimits.HotelSortCode AS HotelSortCode,
	|	RoomRateDailyPricesRoomTypeLimits.HotelDescription AS HotelDescription,
	|	RoomRateDailyPricesRoomTypeLimits.RoomRate AS RoomRate,
	|	RoomRateDailyPricesRoomTypeLimits.RoomRateCode AS RoomRateCode,
	|	RoomRateDailyPricesRoomTypeLimits.RoomRateSortCode AS RoomRateSortCode,
	|	RoomRateDailyPricesRoomTypeLimits.RoomRateDescription AS RoomRateDescription,
	|	RoomRateDailyPricesRoomTypeLimits.AccommodationTemplate AS AccommodationTemplate,
	|	RoomRateDailyPricesRoomTypeLimits.AccommodationTemplateCode AS AccommodationTemplateCode,
	|	RoomRateDailyPricesRoomTypeLimits.RoomType AS RoomType,
	|	RoomRateDailyPricesRoomTypeLimits.RoomTypeCode AS RoomTypeCode,
	|	RoomRateDailyPricesRoomTypeLimits.RoomTypeSortCode AS RoomTypeSortCode,
	|	RoomRateDailyPricesRoomTypeLimits.RoomTypeDescription AS RoomTypeDescription,
	|	RoomRateDailyPricesRoomTypeLimits.AccommodationType AS AccommodationType,
	|	RoomRateDailyPricesRoomTypeLimits.AccommodationTypeCode AS AccommodationTypeCode,
	|	RoomRateDailyPricesRoomTypeLimits.AccommodationTypeSortCode AS AccommodationTypeSortCode,
	|	RoomRateDailyPricesRoomTypeLimits.AccommodationTypeDescription AS AccommodationTypeDescription,
	|	RoomRateDailyPricesRoomTypeLimits.Currency AS Currency,
	|	RoomRateDailyPricesRoomTypeLimits.CurrencyCode AS CurrencyCode,
	|	RoomRateDailyPricesRoomTypeLimits.CurrencyDescription AS CurrencyDescription,
	|	CASE
	|		WHEN RoomRateDailyPricesRoomTypeLimits.Period IN (&qZeroPriceDays)
	|			THEN 0
	|		ELSE (RoomRateDailyPricesRoomTypeLimits.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0)
	|	END AS Amount,
	|	CASE
	|		WHEN BEGINOFPERIOD(RoomRateDailyPricesRoomTypeLimits.Period, DAY) = BEGINOFPERIOD(&qPeriodFrom, DAY)
	|			THEN (RoomRateDailyPricesRoomTypeLimits.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0)
	|		ELSE 0
	|	END AS FirstDaySum,
	|	RoomRateDailyPricesRoomTypeLimits.RoomTypePictureLink AS RoomTypePictureLink,
	|	RoomRateDailyPricesRoomTypeLimits.RoomTypeInfoLink AS RoomTypeInfoLink,
	|	RoomRateDailyPricesRoomTypeLimits.LineNumber AS LineNumber
	|INTO RoomRateDailyPricesRoomTypeLimitsEnriched
	|FROM
	|	RoomRateDailyPricesRoomTypeLimits AS RoomRateDailyPricesRoomTypeLimits
	|		LEFT JOIN InformationRegister.CalendarDays.SliceLast(&qPriceCalculationDate, ) AS CalendarDays
	|		ON RoomRateDailyPricesRoomTypeLimits.RoomRateCalendar = CalendarDays.Calendar
	|			AND RoomRateDailyPricesRoomTypeLimits.Period = CalendarDays.AccountingDate
	|		LEFT JOIN InformationRegister.CalendarDaysByRoomTypes.SliceLast(&qPriceCalculationDate, ) AS CalendarDaysByRoomTypes
	|		ON RoomRateDailyPricesRoomTypeLimits.RoomRateCalendar = CalendarDaysByRoomTypes.Calendar
	|			AND RoomRateDailyPricesRoomTypeLimits.Period = CalendarDaysByRoomTypes.AccountingDate
	|			AND RoomRateDailyPricesRoomTypeLimits.RoomType = CalendarDaysByRoomTypes.RoomType
	|		LEFT JOIN RoomRateFormulas AS RoomRateFormulas
	|		ON RoomRateDailyPricesRoomTypeLimits.RoomRate = RoomRateFormulas.RoomRate
	|			AND RoomRateDailyPricesRoomTypeLimits.Hotel = RoomRateFormulas.Hotel
	|			AND (NOT RoomRateFormulas.IsFormula
	|				OR RoomRateFormulas.IsFormula
	|					AND RoomRateDailyPricesRoomTypeLimits.RoomType = RoomRateFormulas.RoomType
	|					AND RoomRateDailyPricesRoomTypeLimits.ClientType = &qClientType
	|					AND RoomRateDailyPricesRoomTypeLimits.AccommodationType = RoomRateFormulas.AccommodationType
	|					AND (CalendarDaysByRoomTypes.CalendarDayType = RoomRateFormulas.CalendarDayType
	|							AND NOT CalendarDaysByRoomTypes.CalendarDayType IS NULL
	|							AND CalendarDaysByRoomTypes.CalendarDayType <> VALUE(Catalog.CalendarDayTypes.EmptyRef)
	|						OR CalendarDays.CalendarDayType = RoomRateFormulas.CalendarDayType
	|							AND NOT CalendarDays.CalendarDayType IS NULL
	|							AND (CalendarDaysByRoomTypes.CalendarDayType IS NULL OR CalendarDaysByRoomTypes.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef))
	|						OR RoomRateFormulas.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef)))
	|			AND (RoomRateFormulas.BasedOnPriceTag = VALUE(Catalog.PriceTags.EmptyRef)
	|				OR RoomRateDailyPricesRoomTypeLimits.PriceTag = RoomRateFormulas.BasedOnPriceTag
	|					AND RoomRateFormulas.BasedOnPriceTag <> VALUE(Catalog.PriceTags.EmptyRef))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomRatePrices.Period AS Period,
	|	RoomRatePrices.Hotel AS Hotel,
	|	RoomRatePrices.HotelCode AS HotelCode,
	|	RoomRatePrices.HotelSortCode AS HotelSortCode,
	|	RoomRatePrices.HotelDescription AS HotelDescription,
	|	RoomRatePrices.RoomRate AS RoomRate,
	|	RoomRatePrices.RoomRateCode AS RoomRateCode,
	|	RoomRatePrices.RoomRateSortCode AS RoomRateSortCode,
	|	RoomRatePrices.RoomRateDescription AS RoomRateDescription,
	|	RoomRatePrices.AccommodationTemplate AS AccommodationTemplate,
	|	RoomRatePrices.AccommodationTemplateCode AS AccommodationTemplateCode,
	|	RoomRatePrices.RoomType AS RoomType,
	|	RoomRatePrices.RoomTypeCode AS RoomTypeCode,
	|	RoomRatePrices.RoomTypeSortCode AS RoomTypeSortCode,
	|	RoomRatePrices.RoomTypeDescription AS RoomTypeDescription,
	|	RoomRatePrices.AccommodationType AS AccommodationType,
	|	RoomRatePrices.AccommodationTypeCode AS AccommodationTypeCode,
	|	RoomRatePrices.AccommodationTypeSortCode AS AccommodationTypeSortCode,
	|	RoomRatePrices.AccommodationTypeDescription AS AccommodationTypeDescription,
	|	RoomRatePrices.Currency AS Currency,
	|	RoomRatePrices.CurrencyCode AS CurrencyCode,
	|	RoomRatePrices.CurrencyDescription AS CurrencyDescription,
	|	RoomRatePrices.RoomTypePictureLink AS RoomTypePictureLink,
	|	RoomRatePrices.RoomTypeInfoLink AS RoomTypeInfoLink,
	|	RoomRatePrices.LineNumber AS LineNumber,
	|	SUM(RoomRatePrices.Amount) AS AmountBeforeDiscount,
	|	SUM(RoomRatePrices.Amount) AS Amount,
	|	SUM(RoomRatePrices.FirstDaySum) AS FirstDaySum
	|FROM
	|	(SELECT
	|		RoomRateDailyPricesNoRoomTypeLimits.Period AS Period,
	|		RoomRateDailyPricesNoRoomTypeLimits.Hotel AS Hotel,
	|		RoomRateDailyPricesNoRoomTypeLimits.HotelCode AS HotelCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.HotelSortCode AS HotelSortCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.HotelDescription AS HotelDescription,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomRate AS RoomRate,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomRateCode AS RoomRateCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomRateSortCode AS RoomRateSortCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomRateDescription AS RoomRateDescription,
	|		RoomRateDailyPricesNoRoomTypeLimits.AccommodationTemplate AS AccommodationTemplate,
	|		RoomRateDailyPricesNoRoomTypeLimits.AccommodationTemplateCode AS AccommodationTemplateCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomType AS RoomType,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomTypeCode AS RoomTypeCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomTypeSortCode AS RoomTypeSortCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomTypeDescription AS RoomTypeDescription,
	|		RoomRateDailyPricesNoRoomTypeLimits.AccommodationType AS AccommodationType,
	|		RoomRateDailyPricesNoRoomTypeLimits.AccommodationTypeCode AS AccommodationTypeCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.AccommodationTypeSortCode AS AccommodationTypeSortCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.AccommodationTypeDescription AS AccommodationTypeDescription,
	|		RoomRateDailyPricesNoRoomTypeLimits.Currency AS Currency,
	|		RoomRateDailyPricesNoRoomTypeLimits.CurrencyCode AS CurrencyCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.Currency.Description AS CurrencyDescription,
	|		RoomRateDailyPricesNoRoomTypeLimits.Amount AS Amount,
	|		RoomRateDailyPricesNoRoomTypeLimits.FirstDaySum AS FirstDaySum,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomTypePictureLink AS RoomTypePictureLink,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomTypeInfoLink AS RoomTypeInfoLink,
	|		RoomRateDailyPricesNoRoomTypeLimits.LineNumber AS LineNumber
	|	FROM
	|		RoomRateDailyPricesNoRoomTypeLimitsEnriched AS RoomRateDailyPricesNoRoomTypeLimits
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RoomRateDailyPricesRoomTypeLimits.Period,
	|		RoomRateDailyPricesRoomTypeLimits.Hotel,
	|		RoomRateDailyPricesRoomTypeLimits.HotelCode,
	|		RoomRateDailyPricesRoomTypeLimits.HotelSortCode,
	|		RoomRateDailyPricesRoomTypeLimits.HotelDescription,
	|		RoomRateDailyPricesRoomTypeLimits.RoomRate,
	|		RoomRateDailyPricesRoomTypeLimits.RoomRateCode,
	|		RoomRateDailyPricesRoomTypeLimits.RoomRateSortCode,
	|		RoomRateDailyPricesRoomTypeLimits.RoomRateDescription,
	|		RoomRateDailyPricesRoomTypeLimits.AccommodationTemplate,
	|		RoomRateDailyPricesRoomTypeLimits.AccommodationTemplateCode,
	|		RoomRateDailyPricesRoomTypeLimits.RoomType,
	|		RoomRateDailyPricesRoomTypeLimits.RoomTypeCode,
	|		RoomRateDailyPricesRoomTypeLimits.RoomTypeSortCode,
	|		RoomRateDailyPricesRoomTypeLimits.RoomTypeDescription,
	|		RoomRateDailyPricesRoomTypeLimits.AccommodationType,
	|		RoomRateDailyPricesRoomTypeLimits.AccommodationTypeCode,
	|		RoomRateDailyPricesRoomTypeLimits.AccommodationTypeSortCode,
	|		RoomRateDailyPricesRoomTypeLimits.AccommodationTypeDescription,
	|		RoomRateDailyPricesRoomTypeLimits.Currency,
	|		RoomRateDailyPricesRoomTypeLimits.CurrencyCode,
	|		RoomRateDailyPricesRoomTypeLimits.CurrencyDescription,
	|		RoomRateDailyPricesRoomTypeLimits.Amount,
	|		RoomRateDailyPricesRoomTypeLimits.FirstDaySum,
	|		RoomRateDailyPricesRoomTypeLimits.RoomTypePictureLink,
	|		RoomRateDailyPricesRoomTypeLimits.RoomTypeInfoLink,
	|		RoomRateDailyPricesRoomTypeLimits.LineNumber
	|	FROM
	|		RoomRateDailyPricesRoomTypeLimitsEnriched AS RoomRateDailyPricesRoomTypeLimits) AS RoomRatePrices
	|
	|GROUP BY
	|	RoomRatePrices.Period,
	|	RoomRatePrices.Hotel,
	|	RoomRatePrices.HotelCode,
	|	RoomRatePrices.HotelSortCode,
	|	RoomRatePrices.HotelDescription,
	|	RoomRatePrices.RoomRate,
	|	RoomRatePrices.RoomRateCode,
	|	RoomRatePrices.RoomRateSortCode,
	|	RoomRatePrices.RoomRateDescription,
	|	RoomRatePrices.AccommodationTemplate,
	|	RoomRatePrices.AccommodationTemplateCode,
	|	RoomRatePrices.RoomType,
	|	RoomRatePrices.RoomTypeCode,
	|	RoomRatePrices.RoomTypeSortCode,
	|	RoomRatePrices.RoomTypeDescription,
	|	RoomRatePrices.AccommodationType,
	|	RoomRatePrices.AccommodationTypeCode,
	|	RoomRatePrices.AccommodationTypeSortCode,
	|	RoomRatePrices.AccommodationTypeDescription,
	|	RoomRatePrices.Currency,
	|	RoomRatePrices.CurrencyCode,
	|	RoomRatePrices.CurrencyDescription,
	|	RoomRatePrices.RoomTypePictureLink,
	|	RoomRatePrices.RoomTypeInfoLink,
	|	RoomRatePrices.LineNumber
	|
	|ORDER BY
	|	RoomRatePrices.HotelSortCode,
	|	RoomRatePrices.HotelDescription,
	|	RoomRatePrices.RoomRateSortCode,
	|	RoomRatePrices.RoomRateDescription,
	|	RoomRatePrices.RoomTypeSortCode,
	|	Period,
	|	RoomRatePrices.AccommodationTemplateCode,
	|	RoomRatePrices.AccommodationTypeSortCode";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qClientType", pClientType);
	vQry.SetParameter("qPeriodFrom", pPeriodFrom);
	vQry.SetParameter("qPeriodTo", pPeriodTo);
	vQry.SetParameter("qPriceTag", pPriceTag);
	vQry.SetParameter("qZeroPriceDays", cmGetZeroPriceDaysByDiscountType(pDiscountType, pPeriodFrom, pPeriodTo));
	vRoomRatesList = New ValueList();
	If TypeOf(pRoomRatesList) = Type("ValueList") Then
		vRoomRatesList = pRoomRatesList;
	Else
		vRoomRatesList.Add(pRoomRatesList);
	EndIf;
	vQry.SetParameter("qRoomRatesList", vRoomRatesList);
	vRoomRates = New ValueTable();
	vRoomRates.Columns.Add("RoomRateInCache", cmGetCatalogTypeDescription("RoomRates"));
	vRoomRates.Columns.Add("RoomRate", cmGetCatalogTypeDescription("RoomRates"));
	vRoomRates.Columns.Add("RoomRateCode", cmGetStringTypeDescription(25));
	vRoomRates.Columns.Add("RoomRateSortCode", cmGetNumberTypeDescription(6, 0, True));
	vRoomRates.Columns.Add("RoomRateDescription", cmGetStringTypeDescription(100));
	vRoomRates.Columns.Add("RoomRateCalendar", cmGetCatalogTypeDescription("Calendars"));
	For Each vRoomRatesListItem In vRoomRatesList Do
		vRoomRateRef = vRoomRatesListItem.Value;
		vRoomRatesRow = vRoomRates.Add();
		vRoomRatesRow.RoomRateInCache = ?(ValueIsFilled(vRoomRateRef.BasedOnRoomRate), vRoomRateRef.BasedOnRoomRate, vRoomRateRef);
		vRoomRatesRow.RoomRate = vRoomRateRef;
		vRoomRatesRow.RoomRateCode = vRoomRateRef.Code;
		vRoomRatesRow.RoomRateSortCode = vRoomRateRef.SortCode;
		vRoomRatesRow.RoomRateDescription = vRoomRateRef.Description;
		vRoomRatesRow.RoomRateCalendar = vRoomRateRef.Calendar;
	EndDo;
	vQry.SetParameter("qRoomRates", vRoomRates);
	vTemplatesNoRoomTypeLimits = New ValueList();
	vTemplatesWithRoomTypeLimits = New ValueList();
	For Each vAccTemplateItem In pAccTemplates Do
		vAccTemplateRef = vAccTemplateItem.Value;
		If vAccTemplateRef.RoomTypes.Count() = 0 Then
			vTemplatesNoRoomTypeLimits.Add(vAccTemplateRef);
		Else
			vTemplatesWithRoomTypeLimits.Add(vAccTemplateRef);
		EndIf;
	EndDo;
	vQry.SetParameter("qTemplatesNoRoomTypeLimits", vTemplatesNoRoomTypeLimits);
	vQry.SetParameter("qTemplatesWithRoomTypeLimits", vTemplatesWithRoomTypeLimits);
	vQry.SetParameter("qPriceCalculationDate", CurrentSessionDate());
	vQry.SetParameter("qRoomType", pRoomType);
	vQry.SetParameter("qRoomTypeIsEmpty", Not ValueIsFilled(pRoomType));
	
	// Execute query
	vPrices = vQry.Execute().Unload();
	vServicePackagesList = New ValueList();
	vServicePackagesCache = Undefined;
	vCurRoomRate = Undefined;
	rRoomDiscount = 0;
	If pDiscountType <> Undefined and pExternalSystemCode <> Undefined Then
		rRoomDiscount = GetDiscountByType(pExternalSystemCode, pDiscountType, pHotel);
	EndIf;	
	
	For Each vPriceRow In vPrices Do
		If vCurRoomRate <> vPriceRow.RoomRate Then
			vCurRoomRate = vPriceRow.RoomRate;
			vCurRoomRateBasedOnRoomRate = vCurRoomRate.BasedOnRoomRate;
			
			vServicePackagesList = New ValueList();
			
			If ValueIsFilled(vCurRoomRateBasedOnRoomRate) Then
				// We have to take differencies in the packages into account only
				vServicePackagesListForBasedOnRoomRate = vCurRoomRateBasedOnRoomRate.GetObject().pmGetRoomRateServicePackagesList(, True);
				vServicePackagesList = vCurRoomRate.GetObject().pmGetRoomRateServicePackagesList(, True);

				// Add to the current rate service packages list service packages that were removed from the base room rate
				i = 0;
				While i < vServicePackagesListForBasedOnRoomRate.Count() Do
					vSPRemovedFromBasedRR = vServicePackagesListForBasedOnRoomRate.Get(i).Value;
					If vServicePackagesList.FindByValue(vSPRemovedFromBasedRR) = Undefined Then
						vServicePackagesList.Add(vSPRemovedFromBasedRR, , True);
					EndIf;
					i = i + 1;
				EndDo;
				
				// Delete service packages that are present in the based on room rate list of service packages
				If vServicePackagesListForBasedOnRoomRate.Count() > 0 Then
					i = 0;
					While i < vServicePackagesList.Count() Do
						vServicePackagesListItem = vServicePackagesList.Get(i);
						If Not vServicePackagesListItem.Check Then
							vCurServicePackage = vServicePackagesListItem.Value;
							If vServicePackagesListForBasedOnRoomRate.FindByValue(vCurServicePackage) <> Undefined Then
								vDeleteSP = True;
								For Each vSPRow In vCurServicePackage.Services Do
									If vSPRow.IsInPrice And (vSPRow.AccountingDayNumber <> 0 Or ValueIsFilled(vSPRow.AccountingDate)) Then
										vDeleteSP = False;
										Break;
									EndIf;
								EndDo;
								If vDeleteSP Then
									vServicePackagesList.Delete(i);
								Else
									vServicePackagesListItem.Presentation = "<<DO_NOT_PROCESS>>";
									i = i + 1;
								EndIf;
							Else
								i = i + 1;
							EndIf;
						Else
							i = i + 1;
						EndIf;
					EndDo;
				EndIf;
			Else
				vServicePackagesList = vCurRoomRate.GetObject().pmGetRoomRateServicePackagesList(, True);
				i = 0;
				While i < vServicePackagesList.Count() Do
					vCurServicePackage = vServicePackagesList.Get(i).Value;
					vDeleteSP = True;
					For Each vSPRow In vCurServicePackage.Services Do
						If vSPRow.IsInPrice And (vSPRow.AccountingDayNumber <> 0 Or ValueIsFilled(vSPRow.AccountingDate)) Then
							vDeleteSP = False;
							Break;
						EndIf;
					EndDo;
					If vDeleteSP Then
						vServicePackagesList.Delete(i);
					Else
						i = i + 1;
					EndIf;
				EndDo;
			EndIf;
		EndIf;

		// Apply room rate rounding rules 
		If ValueIsFilled(vCurRoomRate) Then
			If vCurRoomRate.RoundPrice Then
				vPriceRow.Amount = Round(vPriceRow.Amount, vCurRoomRate.RoundPriceDigits);
				vPriceRow.AmountBeforeDiscount = Round(vPriceRow.AmountBeforeDiscount, vCurRoomRate.RoundPriceDigits);
				vPriceRow.FirstDaySum = Round(vPriceRow.FirstDaySum, vCurRoomRate.RoundPriceDigits);
			EndIf;
		EndIf;

		If rRoomDiscount <> 0 Then
			vPriceRow.Amount = vPriceRow.Amount - (vPriceRow.Amount * (rRoomDiscount/100));
			// Apply room rate price rounding rule
			If vCurRoomRate.RoundPrice Then
				vPriceRow.Amount = Round(vPriceRow.Amount, vCurRoomRate.RoundPriceDigits);
			EndIf;
		EndIf;
		
		For Each vServicePackagesItem In vServicePackagesList Do
			vCurServicePackage = vServicePackagesItem.Value;
			vServicePackagesItemPresentation = vServicePackagesItem.Presentation;
			// Check service package is valid period
			If vCurServicePackage.DateValidFrom <= BegOfDay(pPeriodFrom) And 
			  (vCurServicePackage.DateValidTo >= BegOfDay(pPeriodFrom) Or Not ValueIsFilled(vCurServicePackage.DateValidTo)) Then
				vCurDate = BegOfDay(vPriceRow.Period);
				vCurCalendarDayType = Undefined;
				
				// Get service package services
				vCurServicePackageServices = Undefined;
				If vServicePackagesCache <> Undefined Then
					vCurServicePackageServices = vServicePackagesCache.FindRows(New Structure("ServicePackage, Period", vCurServicePackage, vCurDate));
					If vCurServicePackageServices.Count() = 0 Then
						vCurServicePackageServices = Undefined;
					EndIf;
				EndIf;
				If vCurServicePackageServices = Undefined Then
					vCurServicePackageServices = Catalogs.ServicePackages.GetServices(vCurServicePackage, vCurDate);
					If vServicePackagesCache = Undefined Then
						vServicePackagesCache = vCurServicePackageServices.Copy();
						vServicePackagesCache.Indexes.Add("ServicePackage, Period");
					Else
						For Each vCurServicePackageServicesRow In vCurServicePackageServices Do
							vServicePackagesCacheRow = vServicePackagesCache.Add();
							FillPropertyValues(vServicePackagesCacheRow, vCurServicePackageServicesRow);
						EndDo;
					EndIf;
				EndIf;
				For Each vSPRow In vCurServicePackageServices Do
					If vSPRow.IsInPrice And ValueIsFilled(vCurRoomRate) And 
					  (vSPRow.AccountingDayNumber <> 0 And ((vCurDate - BegOfDay(pPeriodFrom))/(tcCommonFunctionOnClientServer.cmOneDay()) + 1) = vSPRow.AccountingDayNumber Or 
					   vSPRow.AccountingDayNumber = 9999 And BegOfDay(pPeriodTo) = vCurDate Or 
					   ValueIsFilled(vSPRow.AccountingDate) And vSPRow.AccountingDate = vCurDate Or
					   vSPRow.AccountingDayNumber = 0 And Not ValueIsFilled(vSPRow.AccountingDate) And ValueIsFilled(vCurRoomRateBasedOnRoomRate) And vCurDate < BegOfDay(pPeriodTo) And vServicePackagesItemPresentation <> "<<DO_NOT_PROCESS>>") Then
						If vServicePackagesItem.Check And (vSPRow.AccountingDayNumber <> 0 Or ValueIsFilled(vSPRow.AccountingDate)) Then
						   Continue;
						EndIf;
						
						// Check accounting date time for service package
						If ValueIsFilled(vSPRow.AccountingDate) And vSPRow.AccountingDate <> BegOfDay(vSPRow.AccountingDate) Then
							If BegOfDay(pPeriodFrom) = BegOfDay(vSPRow.AccountingDate) And vSPRow.AccountingDate <= pPeriodFrom Then
								Continue;
							EndIf;
							If BegOfDay(pPeriodTo) = BegOfDay(vSPRow.AccountingDate) And vSPRow.AccountingDate >= pPeriodTo Then
								Continue;
							EndIf;
						EndIf;
						
						// Check current client type
						If pClientType <> vSPRow.ClientType Then
							Continue;
						EndIf;
											
						// Get and check date calendar day type
						If ValueIsFilled(vSPRow.CalendarDayType) Then
							If vCurCalendarDayType = Undefined Then
								vPriceTag = Undefined;
								vCurCalendarDayType = cmGetCalendarDayType(vCurRoomRate, vCurDate, pPeriodFrom, pPeriodTo, vPriceTag, vPriceRow.RoomType);
							EndIf;
							If vSPRow.CalendarDayType <> vCurCalendarDayType Then
								Continue;
							EndIf;
						EndIf;
						
						// Update price rows in prices
						If (Not ValueIsFilled(vSPRow.RoomType) Or ValueIsFilled(vSPRow.RoomType) And vSPRow.RoomType = vPriceRow.RoomType) And 
						   (Not ValueIsFilled(vSPRow.AccommodationType) Or ValueIsFilled(vSPRow.AccommodationType) And vSPRow.AccommodationType = vPriceRow.AccommodationType) Then
							vPrice = Round(cmConvertCurrencies(vSPRow.Price * ?(vSPRow.Quantity > 0, vSPRow.Quantity, 1), vSPRow.Currency, , vPriceRow.Currency, , vCurDate, pHotel), 2);
							vPriceAfterDiscount = vPrice - (vPrice * (rRoomDiscount/100));
							// Apply room rate price rounding rule
							If vCurRoomRate.RoundPrice Then
								If Not ValueIsFilled(vCurRoomRate.RoundPriceServiceGroup) Or 
								   ValueIsFilled(vCurRoomRate.RoundPriceServiceGroup) And cmIsServiceInServiceGroup(vSPRow.Service, vCurRoomRate.RoundPriceServiceGroup) Then
									vPriceAfterDiscount = Round(vPriceAfterDiscount, vCurRoomRate.RoundPriceDigits);
								EndIf;
							EndIf;
							
							vPriceRow.AmountBeforeDiscount = vPriceRow.AmountBeforeDiscount + ?(vServicePackagesItem.Check, -vPrice, vPrice);
							vPriceRow.Amount = vPriceRow.Amount + ?(vServicePackagesItem.Check, -vPriceAfterDiscount, vPriceAfterDiscount);
							If vCurDate = BegOfDay(pPeriodFrom) Then
								vPriceRow.FirstDaySum = vPriceRow.FirstDaySum + ?(vServicePackagesItem.Check, -vPriceAfterDiscount, vPriceAfterDiscount);
							EndIf;
						EndIf;
					EndIf;
				EndDo; // By service package services
			EndIf;
		EndDo; // By service packages
	EndDo;
	Return vPrices;
EndFunction // GetCachedPricesByDays

// -----------------------------------------------------------------------------
// Returns cached room rate prices for the given accommodation templates and period
// -----------------------------------------------------------------------------
Function GetCachedPricesForPriceTags(pHotel, pClientType, pPeriodFrom, pPeriodTo, pRoomRatesList, pRoomType, pAccTemplates, pWithoutOnline = False, pWithoutLOSAndCTs = False, pDiscountType = Undefined, pExternalSystemCode = Undefined, rRoomDiscount = 0, pPromoCodeStruct = Undefined) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomRates.RoomRateInCache AS RoomRateInCache,
	|	RoomRates.RoomRate AS RoomRate,
	|	RoomRates.RoomRateCode AS RoomRateCode,
	|	RoomRates.RoomRateSortCode AS RoomRateSortCode,
	|	RoomRates.RoomRateDescription AS RoomRateDescription,
	|	RoomRates.RoomRateCalendar AS RoomRateCalendar
	|INTO CacheRoomRates
	|FROM
	|	&qRoomRates AS RoomRates
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	EffectivePriceTags.Period AS Period,
	|	EffectivePriceTags.RoomRate AS RoomRate,
	|	EffectivePriceTags.RoomRateInCache AS RoomRateInCache,
	|	EffectivePriceTags.RoomType AS RoomType,
	|	EffectivePriceTags.PriceTag AS PriceTag
	|INTO EffectivePriceTags
	|FROM
	|	&qEffectivePriceTags AS EffectivePriceTags
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomRatesSliceLast.SetRoomRateFormulas AS Recorder,
	|	RoomRatesSliceLast.RoomRate AS RoomRate
	|INTO ActiveSetRoomRateFormulas
	|FROM
	|	InformationRegister.RoomRates.SliceLast(
	|			&qPriceCalculationDate,
	|			RoomRate IN (&qRoomRatesList)
	|				AND Hotel = &qHotel
	|				AND IsFormula) AS RoomRatesSliceLast
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CacheRoomRates.RoomRate AS RoomRate,
	|	&qHotel AS Hotel,
	|	AccommodationTemplatesAccommodationTypes.Ref AS AccommodationTemplate,
	|	HotelRoomTypes.Ref AS RoomType,
	|	HotelRoomTypes.RoomClass AS RoomClass,
	|	CASE
	|		WHEN NOT RoomRateOverrides.ToAccommodationType IS NULL
	|			THEN RoomRateOverrides.ToAccommodationType
	|		ELSE AccommodationTemplatesAccommodationTypes.AccommodationType
	|	END AS AccommodationType,
	|	AccommodationTemplatesAccommodationTypes.LineNumber AS LineNumber
	|INTO AccommodationTypesInTemplatesNoRoomTypeLimits
	|FROM
	|	CacheRoomRates AS CacheRoomRates
	|		LEFT JOIN Catalog.RoomTypes AS HotelRoomTypes
	|		ON (HotelRoomTypes.Owner = &qHotel)
	|			AND (NOT HotelRoomTypes.DeletionMark)
	|			AND (NOT HotelRoomTypes.IsFolder)
	|		INNER JOIN Catalog.AccommodationTemplates.AccommodationTypes AS AccommodationTemplatesAccommodationTypes
	|		ON (AccommodationTemplatesAccommodationTypes.Ref IN (&qTemplatesNoRoomTypeLimits))
	|		LEFT JOIN InformationRegister.RoomRateOverrides AS RoomRateOverrides
	|		ON CacheRoomRates.RoomRate = RoomRateOverrides.RoomRate
	|			AND (&qHotel = RoomRateOverrides.Hotel)
	|			AND (AccommodationTemplatesAccommodationTypes.Ref = RoomRateOverrides.AccommodationTemplate)
	|			AND (HotelRoomTypes.Ref = RoomRateOverrides.RoomType
	|				OR RoomRateOverrides.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
	|			AND (AccommodationTemplatesAccommodationTypes.AccommodationType = RoomRateOverrides.AccommodationType)
	|			AND (AccommodationTemplatesAccommodationTypes.LineNumber = RoomRateOverrides.TemplateLineNumber)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CacheRoomRates.RoomRate AS RoomRate,
	|	&qHotel AS Hotel,
	|	AccommodationTemplatesAccommodationTypes.Ref AS AccommodationTemplate,
	|	HotelRoomTypes.Ref AS RoomType,
	|	HotelRoomTypes.RoomClass AS RoomClass,
	|	CASE
	|		WHEN NOT RoomRateOverrides.ToAccommodationType IS NULL
	|			THEN RoomRateOverrides.ToAccommodationType
	|		ELSE AccommodationTemplatesAccommodationTypes.AccommodationType
	|	END AS AccommodationType,
	|	AccommodationTemplatesAccommodationTypes.LineNumber AS LineNumber
	|INTO AccommodationTypesInTemplatesWithRoomTypeLimits
	|FROM
	|	CacheRoomRates AS CacheRoomRates
	|		LEFT JOIN Catalog.RoomTypes AS HotelRoomTypes
	|		ON (HotelRoomTypes.Owner = &qHotel)
	|			AND (NOT HotelRoomTypes.DeletionMark)
	|			AND (NOT HotelRoomTypes.IsFolder)
	|		INNER JOIN Catalog.AccommodationTemplates.AccommodationTypes AS AccommodationTemplatesAccommodationTypes
	|		ON (AccommodationTemplatesAccommodationTypes.Ref IN (&qTemplatesWithRoomTypeLimits))
	|		INNER JOIN Catalog.AccommodationTemplates.RoomTypes AS AccommodationTemplatesRoomTypes
	|		ON (AccommodationTemplatesAccommodationTypes.Ref = AccommodationTemplatesRoomTypes.Ref)
	|			AND (HotelRoomTypes.Ref = AccommodationTemplatesRoomTypes.RoomType
	|					AND AccommodationTemplatesRoomTypes.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
	|				OR HotelRoomTypes.RoomClass = AccommodationTemplatesRoomTypes.RoomClass
	|					AND AccommodationTemplatesRoomTypes.RoomClass <> VALUE(Catalog.RoomTypeClasses.EmptyRef))
	|		LEFT JOIN InformationRegister.RoomRateOverrides AS RoomRateOverrides
	|		ON CacheRoomRates.RoomRate = RoomRateOverrides.RoomRate
	|			AND (&qHotel = RoomRateOverrides.Hotel)
	|			AND (AccommodationTemplatesAccommodationTypes.Ref = RoomRateOverrides.AccommodationTemplate)
	|			AND (HotelRoomTypes.Ref = RoomRateOverrides.RoomType
	|				OR RoomRateOverrides.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
	|			AND (AccommodationTemplatesAccommodationTypes.AccommodationType = RoomRateOverrides.AccommodationType)
	|			AND (AccommodationTemplatesAccommodationTypes.LineNumber = RoomRateOverrides.TemplateLineNumber)
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
	|	RoomRateDailyPrices.Period AS Period,
	|	RoomRateDailyPrices.Hotel AS Hotel,
	|	RoomRateDailyPrices.Hotel.Code AS HotelCode,
	|	RoomRateDailyPrices.Hotel.SortCode AS HotelSortCode,
	|	RoomRateDailyPrices.Hotel.Description AS HotelDescription,
	|	CacheRoomRates.RoomRate AS RoomRate,
	|	CacheRoomRates.RoomRateCode AS RoomRateCode,
	|	CacheRoomRates.RoomRateSortCode AS RoomRateSortCode,
	|	CacheRoomRates.RoomRateDescription AS RoomRateDescription,
	|	CacheRoomRates.RoomRateCalendar AS RoomRateCalendar,
	|	AccommodationTemplatesAccommodationTypes.AccommodationTemplate AS AccommodationTemplate,
	|	AccommodationTemplatesAccommodationTypes.AccommodationTemplate.Code AS AccommodationTemplateCode,
	|	RoomRateDailyPrices.RoomType AS RoomType,
	|	RoomRateDailyPrices.RoomType.Code AS RoomTypeCode,
	|	RoomRateDailyPrices.RoomType.SortCode AS RoomTypeSortCode,
	|	RoomRateDailyPrices.RoomType.Description AS RoomTypeDescription,
	|	RoomRateDailyPrices.AccommodationType AS AccommodationType,
	|	RoomRateDailyPrices.AccommodationType.Code AS AccommodationTypeCode,
	|	RoomRateDailyPrices.AccommodationType.SortCode AS AccommodationTypeSortCode,
	|	RoomRateDailyPrices.AccommodationType.Description AS AccommodationTypeDescription,
	|	RoomRateDailyPrices.Currency AS Currency,
	|	RoomRateDailyPrices.Currency.Code AS CurrencyCode,
	|	RoomRateDailyPrices.Currency.Description AS CurrencyDescription,
	|	RoomRateDailyPrices.ClientType AS ClientType,
	|	RoomRateDailyPrices.PriceTag AS PriceTag,
	|	RoomRateDailyPrices.Price AS Price,
	|	CAST(RoomRateDailyPrices.RoomType.RoomTypePictureLink AS STRING(1024)) AS RoomTypePictureLink,
	|	CAST(RoomRateDailyPrices.RoomType.RoomTypeInfoLink AS STRING(1024)) AS RoomTypeInfoLink,
	|	AccommodationTemplatesAccommodationTypes.LineNumber AS LineNumber
	|INTO RoomRateDailyPricesNoRoomTypeLimits
	|FROM
	|	InformationRegister.RoomRateDailyPrices AS RoomRateDailyPrices
	|		INNER JOIN CacheRoomRates AS CacheRoomRates
	|		ON RoomRateDailyPrices.RoomRate = CacheRoomRates.RoomRateInCache
	|		INNER JOIN AccommodationTypesInTemplatesNoRoomTypeLimits AS AccommodationTemplatesAccommodationTypes
	|		ON (AccommodationTemplatesAccommodationTypes.AccommodationType = RoomRateDailyPrices.AccommodationType)
	|			AND (AccommodationTemplatesAccommodationTypes.RoomRate = CacheRoomRates.RoomRate)
	|			AND (AccommodationTemplatesAccommodationTypes.Hotel = RoomRateDailyPrices.Hotel)
	|			AND (AccommodationTemplatesAccommodationTypes.RoomType = RoomRateDailyPrices.RoomType)
	|		INNER JOIN EffectivePriceTags AS EffectivePriceTags
	|		ON RoomRateDailyPrices.Period = EffectivePriceTags.Period
	|			AND RoomRateDailyPrices.RoomRate = EffectivePriceTags.RoomRateInCache
	|			AND CacheRoomRates.RoomRate = EffectivePriceTags.RoomRate
	|			AND (RoomRateDailyPrices.RoomType = EffectivePriceTags.RoomType
	|				OR EffectivePriceTags.RoomType = &qEmptyRoomType)
	|			AND RoomRateDailyPrices.PriceTag = EffectivePriceTags.PriceTag
	|WHERE
	|	RoomRateDailyPrices.Period >= &qPeriodFrom
	|	AND (RoomRateDailyPrices.Period < &qPeriodTo
	|				AND RoomRateDailyPrices.RoomRate.DurationCalculationRuleType <> VALUE(Enum.DurationCalculationRuleTypes.ByDays)
	|			OR RoomRateDailyPrices.Period <= &qPeriodTo
	|				AND RoomRateDailyPrices.RoomRate.DurationCalculationRuleType = VALUE(Enum.DurationCalculationRuleTypes.ByDays))
	|	AND RoomRateDailyPrices.Hotel = &qHotel
	|	AND RoomRateDailyPrices.ClientType = &qClientType
	|
	|INDEX BY
	|	CacheRoomRates.RoomRateCalendar,
	|	RoomRateDailyPrices.Period,
	|	RoomRateDailyPrices.RoomType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	RoomRateDailyPricesNoRoomTypeLimits.Period AS Period,
	|	RoomRateDailyPricesNoRoomTypeLimits.Hotel AS Hotel,
	|	RoomRateDailyPricesNoRoomTypeLimits.HotelCode AS HotelCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.HotelSortCode AS HotelSortCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.HotelDescription AS HotelDescription,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomRate AS RoomRate,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomRateCode AS RoomRateCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomRateSortCode AS RoomRateSortCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomRateDescription AS RoomRateDescription,
	|	RoomRateDailyPricesNoRoomTypeLimits.AccommodationTemplate AS AccommodationTemplate,
	|	RoomRateDailyPricesNoRoomTypeLimits.AccommodationTemplateCode AS AccommodationTemplateCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomType AS RoomType,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomTypeCode AS RoomTypeCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomTypeSortCode AS RoomTypeSortCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomTypeDescription AS RoomTypeDescription,
	|	RoomRateDailyPricesNoRoomTypeLimits.AccommodationType AS AccommodationType,
	|	RoomRateDailyPricesNoRoomTypeLimits.AccommodationTypeCode AS AccommodationTypeCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.AccommodationTypeSortCode AS AccommodationTypeSortCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.AccommodationTypeDescription AS AccommodationTypeDescription,
	|	RoomRateDailyPricesNoRoomTypeLimits.Currency AS Currency,
	|	RoomRateDailyPricesNoRoomTypeLimits.CurrencyCode AS CurrencyCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.CurrencyDescription AS CurrencyDescription,
	|	CASE
	|		WHEN RoomRateDailyPricesNoRoomTypeLimits.Period IN (&qZeroPriceDays)
	|			THEN 0
	|		ELSE (RoomRateDailyPricesNoRoomTypeLimits.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0)
	|	END AS Amount,
	|	CASE
	|		WHEN RoomRateDailyPricesNoRoomTypeLimits.Period = BEGINOFPERIOD(&qPeriodFrom, DAY)
	|			THEN (RoomRateDailyPricesNoRoomTypeLimits.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0)
	|		ELSE 0
	|	END AS FirstDaySum,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomTypePictureLink AS RoomTypePictureLink,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomTypeInfoLink AS RoomTypeInfoLink,
	|	RoomRateDailyPricesNoRoomTypeLimits.LineNumber AS LineNumber
	|INTO RoomRateDailyPricesNoRoomTypeLimitsEnriched
	|FROM
	|	RoomRateDailyPricesNoRoomTypeLimits AS RoomRateDailyPricesNoRoomTypeLimits
	|		LEFT JOIN InformationRegister.CalendarDays.SliceLast(&qPriceCalculationDate, ) AS CalendarDays
	|		ON RoomRateDailyPricesNoRoomTypeLimits.RoomRateCalendar = CalendarDays.Calendar
	|			AND RoomRateDailyPricesNoRoomTypeLimits.Period = CalendarDays.AccountingDate
	|		LEFT JOIN InformationRegister.CalendarDaysByRoomTypes.SliceLast(&qPriceCalculationDate, ) AS CalendarDaysByRoomTypes
	|		ON RoomRateDailyPricesNoRoomTypeLimits.RoomRateCalendar = CalendarDaysByRoomTypes.Calendar
	|			AND RoomRateDailyPricesNoRoomTypeLimits.Period = CalendarDaysByRoomTypes.AccountingDate
	|			AND RoomRateDailyPricesNoRoomTypeLimits.RoomType = CalendarDaysByRoomTypes.RoomType
	|		LEFT JOIN RoomRateFormulas AS RoomRateFormulas
	|		ON RoomRateDailyPricesNoRoomTypeLimits.RoomRate = RoomRateFormulas.RoomRate
	|			AND RoomRateDailyPricesNoRoomTypeLimits.Hotel = RoomRateFormulas.Hotel
	|			AND (NOT RoomRateFormulas.IsFormula
	|				OR RoomRateFormulas.IsFormula
	|					AND RoomRateDailyPricesNoRoomTypeLimits.RoomType = RoomRateFormulas.RoomType
	|					AND RoomRateDailyPricesNoRoomTypeLimits.ClientType = &qClientType
	|					AND RoomRateDailyPricesNoRoomTypeLimits.AccommodationType = RoomRateFormulas.AccommodationType
	|					AND (CalendarDaysByRoomTypes.CalendarDayType = RoomRateFormulas.CalendarDayType
	|							AND NOT CalendarDaysByRoomTypes.CalendarDayType IS NULL
	|							AND CalendarDaysByRoomTypes.CalendarDayType <> VALUE(Catalog.CalendarDayTypes.EmptyRef)
	|						OR CalendarDays.CalendarDayType = RoomRateFormulas.CalendarDayType
	|							AND NOT CalendarDays.CalendarDayType IS NULL
	|							AND (CalendarDaysByRoomTypes.CalendarDayType IS NULL OR CalendarDaysByRoomTypes.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef))
	|						OR RoomRateFormulas.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef)))
	|			AND (RoomRateFormulas.BasedOnPriceTag = VALUE(Catalog.PriceTags.EmptyRef)
	|				OR RoomRateDailyPricesNoRoomTypeLimits.PriceTag = RoomRateFormulas.BasedOnPriceTag
	|					AND RoomRateFormulas.BasedOnPriceTag <> VALUE(Catalog.PriceTags.EmptyRef))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	RoomRateDailyPrices.Period AS Period,
	|	RoomRateDailyPrices.Hotel AS Hotel,
	|	RoomRateDailyPrices.Hotel.Code AS HotelCode,
	|	RoomRateDailyPrices.Hotel.SortCode AS HotelSortCode,
	|	RoomRateDailyPrices.Hotel.Description AS HotelDescription,
	|	CacheRoomRates.RoomRate AS RoomRate,
	|	CacheRoomRates.RoomRateCode AS RoomRateCode,
	|	CacheRoomRates.RoomRateSortCode AS RoomRateSortCode,
	|	CacheRoomRates.RoomRateDescription AS RoomRateDescription,
	|	CacheRoomRates.RoomRateCalendar AS RoomRateCalendar,
	|	AccommodationTemplatesAccommodationTypes.AccommodationTemplate AS AccommodationTemplate,
	|	AccommodationTemplatesAccommodationTypes.AccommodationTemplate.Code AS AccommodationTemplateCode,
	|	RoomRateDailyPrices.RoomType AS RoomType,
	|	RoomRateDailyPrices.RoomType.Code AS RoomTypeCode,
	|	RoomRateDailyPrices.RoomType.SortCode AS RoomTypeSortCode,
	|	RoomRateDailyPrices.RoomType.Description AS RoomTypeDescription,
	|	RoomRateDailyPrices.AccommodationType AS AccommodationType,
	|	RoomRateDailyPrices.AccommodationType.Code AS AccommodationTypeCode,
	|	RoomRateDailyPrices.AccommodationType.SortCode AS AccommodationTypeSortCode,
	|	RoomRateDailyPrices.AccommodationType.Description AS AccommodationTypeDescription,
	|	RoomRateDailyPrices.Currency AS Currency,
	|	RoomRateDailyPrices.Currency.Code AS CurrencyCode,
	|	RoomRateDailyPrices.Currency.Description AS CurrencyDescription,
	|	RoomRateDailyPrices.Price AS Price,
	|	RoomRateDailyPrices.ClientType AS ClientType,
	|	RoomRateDailyPrices.PriceTag AS PriceTag,
	|	CAST(RoomRateDailyPrices.RoomType.RoomTypePictureLink AS STRING(1024)) AS RoomTypePictureLink,
	|	CAST(RoomRateDailyPrices.RoomType.RoomTypeInfoLink AS STRING(1024)) AS RoomTypeInfoLink,
	|	AccommodationTemplatesAccommodationTypes.LineNumber AS LineNumber
	|INTO RoomRateDailyPricesRoomTypeLimits
	|FROM
	|	InformationRegister.RoomRateDailyPrices AS RoomRateDailyPrices
	|		INNER JOIN CacheRoomRates AS CacheRoomRates
	|		ON RoomRateDailyPrices.RoomRate = CacheRoomRates.RoomRateInCache
	|		INNER JOIN AccommodationTypesInTemplatesWithRoomTypeLimits AS AccommodationTemplatesAccommodationTypes
	|		ON (AccommodationTemplatesAccommodationTypes.AccommodationType = RoomRateDailyPrices.AccommodationType)
	|			AND (AccommodationTemplatesAccommodationTypes.RoomRate = CacheRoomRates.RoomRate)
	|			AND (AccommodationTemplatesAccommodationTypes.Hotel = RoomRateDailyPrices.Hotel)
	|			AND (AccommodationTemplatesAccommodationTypes.RoomType = RoomRateDailyPrices.RoomType)
	|		INNER JOIN EffectivePriceTags AS EffectivePriceTags
	|		ON RoomRateDailyPrices.Period = EffectivePriceTags.Period
	|			AND RoomRateDailyPrices.RoomRate = EffectivePriceTags.RoomRateInCache
	|			AND CacheRoomRates.RoomRate = EffectivePriceTags.RoomRate
	|			AND (RoomRateDailyPrices.RoomType = EffectivePriceTags.RoomType
	|				OR EffectivePriceTags.RoomType = &qEmptyRoomType)
	|			AND RoomRateDailyPrices.PriceTag = EffectivePriceTags.PriceTag
	|WHERE
	|	RoomRateDailyPrices.Period >= &qPeriodFrom
	|	AND (RoomRateDailyPrices.Period < &qPeriodTo
	|				AND RoomRateDailyPrices.RoomRate.DurationCalculationRuleType <> VALUE(Enum.DurationCalculationRuleTypes.ByDays)
	|			OR RoomRateDailyPrices.Period <= &qPeriodTo
	|				AND RoomRateDailyPrices.RoomRate.DurationCalculationRuleType = VALUE(Enum.DurationCalculationRuleTypes.ByDays))
	|	AND RoomRateDailyPrices.Hotel = &qHotel
	|	AND RoomRateDailyPrices.ClientType = &qClientType
	|
	|INDEX BY
	|	CacheRoomRates.RoomRateCalendar,
	|	RoomRateDailyPrices.Period,
	|	RoomRateDailyPrices.RoomType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	RoomRateDailyPricesRoomTypeLimits.Period AS Period,
	|	RoomRateDailyPricesRoomTypeLimits.Hotel AS Hotel,
	|	RoomRateDailyPricesRoomTypeLimits.HotelCode AS HotelCode,
	|	RoomRateDailyPricesRoomTypeLimits.HotelSortCode AS HotelSortCode,
	|	RoomRateDailyPricesRoomTypeLimits.HotelDescription AS HotelDescription,
	|	RoomRateDailyPricesRoomTypeLimits.RoomRate AS RoomRate,
	|	RoomRateDailyPricesRoomTypeLimits.RoomRateCode AS RoomRateCode,
	|	RoomRateDailyPricesRoomTypeLimits.RoomRateSortCode AS RoomRateSortCode,
	|	RoomRateDailyPricesRoomTypeLimits.RoomRateDescription AS RoomRateDescription,
	|	RoomRateDailyPricesRoomTypeLimits.AccommodationTemplate AS AccommodationTemplate,
	|	RoomRateDailyPricesRoomTypeLimits.AccommodationTemplateCode AS AccommodationTemplateCode,
	|	RoomRateDailyPricesRoomTypeLimits.RoomType AS RoomType,
	|	RoomRateDailyPricesRoomTypeLimits.RoomTypeCode AS RoomTypeCode,
	|	RoomRateDailyPricesRoomTypeLimits.RoomTypeSortCode AS RoomTypeSortCode,
	|	RoomRateDailyPricesRoomTypeLimits.RoomTypeDescription AS RoomTypeDescription,
	|	RoomRateDailyPricesRoomTypeLimits.AccommodationType AS AccommodationType,
	|	RoomRateDailyPricesRoomTypeLimits.AccommodationTypeCode AS AccommodationTypeCode,
	|	RoomRateDailyPricesRoomTypeLimits.AccommodationTypeSortCode AS AccommodationTypeSortCode,
	|	RoomRateDailyPricesRoomTypeLimits.AccommodationTypeDescription AS AccommodationTypeDescription,
	|	RoomRateDailyPricesRoomTypeLimits.Currency AS Currency,
	|	RoomRateDailyPricesRoomTypeLimits.CurrencyCode AS CurrencyCode,
	|	RoomRateDailyPricesRoomTypeLimits.CurrencyDescription AS CurrencyDescription,
	|	CASE
	|		WHEN RoomRateDailyPricesRoomTypeLimits.Period IN (&qZeroPriceDays)
	|			THEN 0
	|		ELSE (RoomRateDailyPricesRoomTypeLimits.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0)
	|	END AS Amount,
	|	CASE
	|		WHEN BEGINOFPERIOD(RoomRateDailyPricesRoomTypeLimits.Period, DAY) = BEGINOFPERIOD(&qPeriodFrom, DAY)
	|			THEN (RoomRateDailyPricesRoomTypeLimits.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0)
	|		ELSE 0
	|	END AS FirstDaySum,
	|	RoomRateDailyPricesRoomTypeLimits.RoomTypePictureLink AS RoomTypePictureLink,
	|	RoomRateDailyPricesRoomTypeLimits.RoomTypeInfoLink AS RoomTypeInfoLink,
	|	RoomRateDailyPricesRoomTypeLimits.LineNumber AS LineNumber
	|INTO RoomRateDailyPricesRoomTypeLimitsEnriched
	|FROM
	|	RoomRateDailyPricesRoomTypeLimits AS RoomRateDailyPricesRoomTypeLimits
	|		LEFT JOIN InformationRegister.CalendarDays.SliceLast(&qPriceCalculationDate, ) AS CalendarDays
	|		ON RoomRateDailyPricesRoomTypeLimits.RoomRateCalendar = CalendarDays.Calendar
	|			AND RoomRateDailyPricesRoomTypeLimits.Period = CalendarDays.AccountingDate
	|		LEFT JOIN InformationRegister.CalendarDaysByRoomTypes.SliceLast(&qPriceCalculationDate, ) AS CalendarDaysByRoomTypes
	|		ON RoomRateDailyPricesRoomTypeLimits.RoomRateCalendar = CalendarDaysByRoomTypes.Calendar
	|			AND RoomRateDailyPricesRoomTypeLimits.Period = CalendarDaysByRoomTypes.AccountingDate
	|			AND RoomRateDailyPricesRoomTypeLimits.RoomType = CalendarDaysByRoomTypes.RoomType
	|		LEFT JOIN RoomRateFormulas AS RoomRateFormulas
	|		ON RoomRateDailyPricesRoomTypeLimits.RoomRate = RoomRateFormulas.RoomRate
	|			AND RoomRateDailyPricesRoomTypeLimits.Hotel = RoomRateFormulas.Hotel
	|			AND (NOT RoomRateFormulas.IsFormula
	|				OR RoomRateFormulas.IsFormula
	|					AND RoomRateDailyPricesRoomTypeLimits.RoomType = RoomRateFormulas.RoomType
	|					AND RoomRateDailyPricesRoomTypeLimits.ClientType = &qClientType
	|					AND RoomRateDailyPricesRoomTypeLimits.AccommodationType = RoomRateFormulas.AccommodationType
	|					AND (CalendarDaysByRoomTypes.CalendarDayType = RoomRateFormulas.CalendarDayType
	|							AND NOT CalendarDaysByRoomTypes.CalendarDayType IS NULL
	|							AND CalendarDaysByRoomTypes.CalendarDayType <> VALUE(Catalog.CalendarDayTypes.EmptyRef)
	|						OR CalendarDays.CalendarDayType = RoomRateFormulas.CalendarDayType
	|							AND NOT CalendarDays.CalendarDayType IS NULL
	|							AND (CalendarDaysByRoomTypes.CalendarDayType IS NULL OR CalendarDaysByRoomTypes.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef))
	|						OR RoomRateFormulas.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef)))
	|			AND (RoomRateFormulas.BasedOnPriceTag = VALUE(Catalog.PriceTags.EmptyRef)
	|				OR RoomRateDailyPricesRoomTypeLimits.PriceTag = RoomRateFormulas.BasedOnPriceTag
	|					AND RoomRateFormulas.BasedOnPriceTag <> VALUE(Catalog.PriceTags.EmptyRef))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomRatePrices.Period AS Period,
	|	RoomRatePrices.Hotel AS Hotel,
	|	RoomRatePrices.HotelCode AS HotelCode,
	|	RoomRatePrices.HotelSortCode AS HotelSortCode,
	|	RoomRatePrices.HotelDescription AS HotelDescription,
	|	RoomRatePrices.RoomRate AS RoomRate,
	|	RoomRatePrices.RoomRateCode AS RoomRateCode,
	|	RoomRatePrices.RoomRateSortCode AS RoomRateSortCode,
	|	RoomRatePrices.RoomRateDescription AS RoomRateDescription,
	|	RoomRatePrices.AccommodationTemplate AS AccommodationTemplate,
	|	RoomRatePrices.AccommodationTemplateCode AS AccommodationTemplateCode,
	|	RoomRatePrices.RoomType AS RoomType,
	|	RoomRatePrices.RoomTypeCode AS RoomTypeCode,
	|	RoomRatePrices.RoomTypeSortCode AS RoomTypeSortCode,
	|	RoomRatePrices.RoomTypeDescription AS RoomTypeDescription,
	|	RoomRatePrices.AccommodationType AS AccommodationType,
	|	RoomRatePrices.AccommodationTypeCode AS AccommodationTypeCode,
	|	RoomRatePrices.AccommodationTypeSortCode AS AccommodationTypeSortCode,
	|	RoomRatePrices.AccommodationTypeDescription AS AccommodationTypeDescription,
	|	RoomRatePrices.Currency AS Currency,
	|	RoomRatePrices.CurrencyCode AS CurrencyCode,
	|	RoomRatePrices.CurrencyDescription AS CurrencyDescription,
	|	RoomRatePrices.RoomTypePictureLink AS RoomTypePictureLink,
	|	RoomRatePrices.RoomTypeInfoLink AS RoomTypeInfoLink,
	|	RoomRatePrices.LineNumber AS LineNumber,
	|	SUM(RoomRatePrices.Amount) AS AmountBeforeDiscount,
	|	SUM(RoomRatePrices.Amount) AS Amount,
	|	SUM(RoomRatePrices.FirstDaySum) AS FirstDaySum
	|FROM
	|	(SELECT
	|		RoomRateDailyPricesNoRoomTypeLimits.Period AS Period,
	|		RoomRateDailyPricesNoRoomTypeLimits.Hotel AS Hotel,
	|		RoomRateDailyPricesNoRoomTypeLimits.HotelCode AS HotelCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.HotelSortCode AS HotelSortCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.HotelDescription AS HotelDescription,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomRate AS RoomRate,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomRateCode AS RoomRateCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomRateSortCode AS RoomRateSortCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomRateDescription AS RoomRateDescription,
	|		RoomRateDailyPricesNoRoomTypeLimits.AccommodationTemplate AS AccommodationTemplate,
	|		RoomRateDailyPricesNoRoomTypeLimits.AccommodationTemplateCode AS AccommodationTemplateCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomType AS RoomType,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomTypeCode AS RoomTypeCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomTypeSortCode AS RoomTypeSortCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomTypeDescription AS RoomTypeDescription,
	|		RoomRateDailyPricesNoRoomTypeLimits.AccommodationType AS AccommodationType,
	|		RoomRateDailyPricesNoRoomTypeLimits.AccommodationTypeCode AS AccommodationTypeCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.AccommodationTypeSortCode AS AccommodationTypeSortCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.AccommodationTypeDescription AS AccommodationTypeDescription,
	|		RoomRateDailyPricesNoRoomTypeLimits.Currency AS Currency,
	|		RoomRateDailyPricesNoRoomTypeLimits.CurrencyCode AS CurrencyCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.CurrencyDescription AS CurrencyDescription,
	|		RoomRateDailyPricesNoRoomTypeLimits.Amount AS Amount,
	|		RoomRateDailyPricesNoRoomTypeLimits.FirstDaySum AS FirstDaySum,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomTypePictureLink AS RoomTypePictureLink,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomTypeInfoLink AS RoomTypeInfoLink,
	|		RoomRateDailyPricesNoRoomTypeLimits.LineNumber AS LineNumber
	|	FROM
	|		RoomRateDailyPricesNoRoomTypeLimitsEnriched AS RoomRateDailyPricesNoRoomTypeLimits
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RoomRateDailyPricesRoomTypeLimits.Period,
	|		RoomRateDailyPricesRoomTypeLimits.Hotel,
	|		RoomRateDailyPricesRoomTypeLimits.HotelCode,
	|		RoomRateDailyPricesRoomTypeLimits.HotelSortCode,
	|		RoomRateDailyPricesRoomTypeLimits.HotelDescription,
	|		RoomRateDailyPricesRoomTypeLimits.RoomRate,
	|		RoomRateDailyPricesRoomTypeLimits.RoomRateCode,
	|		RoomRateDailyPricesRoomTypeLimits.RoomRateSortCode,
	|		RoomRateDailyPricesRoomTypeLimits.RoomRateDescription,
	|		RoomRateDailyPricesRoomTypeLimits.AccommodationTemplate,
	|		RoomRateDailyPricesRoomTypeLimits.AccommodationTemplateCode,
	|		RoomRateDailyPricesRoomTypeLimits.RoomType,
	|		RoomRateDailyPricesRoomTypeLimits.RoomTypeCode,
	|		RoomRateDailyPricesRoomTypeLimits.RoomTypeSortCode,
	|		RoomRateDailyPricesRoomTypeLimits.RoomTypeDescription,
	|		RoomRateDailyPricesRoomTypeLimits.AccommodationType,
	|		RoomRateDailyPricesRoomTypeLimits.AccommodationTypeCode,
	|		RoomRateDailyPricesRoomTypeLimits.AccommodationTypeSortCode,
	|		RoomRateDailyPricesRoomTypeLimits.AccommodationTypeDescription,
	|		RoomRateDailyPricesRoomTypeLimits.Currency,
	|		RoomRateDailyPricesRoomTypeLimits.CurrencyCode,
	|		RoomRateDailyPricesRoomTypeLimits.CurrencyDescription,
	|		RoomRateDailyPricesRoomTypeLimits.Amount,
	|		RoomRateDailyPricesRoomTypeLimits.FirstDaySum,
	|		RoomRateDailyPricesRoomTypeLimits.RoomTypePictureLink,
	|		RoomRateDailyPricesRoomTypeLimits.RoomTypeInfoLink,
	|		RoomRateDailyPricesRoomTypeLimits.LineNumber
	|	FROM
	|		RoomRateDailyPricesRoomTypeLimitsEnriched AS RoomRateDailyPricesRoomTypeLimits) AS RoomRatePrices
	|
	|GROUP BY
	|	RoomRatePrices.Period,
	|	RoomRatePrices.Hotel,
	|	RoomRatePrices.HotelCode,
	|	RoomRatePrices.HotelSortCode,
	|	RoomRatePrices.HotelDescription,
	|	RoomRatePrices.RoomRate,
	|	RoomRatePrices.RoomRateCode,
	|	RoomRatePrices.RoomRateSortCode,
	|	RoomRatePrices.RoomRateDescription,
	|	RoomRatePrices.AccommodationTemplate,
	|	RoomRatePrices.AccommodationTemplateCode,
	|	RoomRatePrices.RoomType,
	|	RoomRatePrices.RoomTypeCode,
	|	RoomRatePrices.RoomTypeSortCode,
	|	RoomRatePrices.RoomTypeDescription,
	|	RoomRatePrices.AccommodationType,
	|	RoomRatePrices.AccommodationTypeCode,
	|	RoomRatePrices.AccommodationTypeSortCode,
	|	RoomRatePrices.AccommodationTypeDescription,
	|	RoomRatePrices.Currency,
	|	RoomRatePrices.CurrencyCode,
	|	RoomRatePrices.CurrencyDescription,
	|	RoomRatePrices.RoomTypePictureLink,
	|	RoomRatePrices.RoomTypeInfoLink,
	|	RoomRatePrices.LineNumber
	|
	|ORDER BY
	|	RoomRatePrices.HotelSortCode,
	|	RoomRatePrices.HotelDescription,
	|	RoomRatePrices.RoomRateSortCode,
	|	RoomRatePrices.RoomRateDescription,
	|	RoomRatePrices.RoomTypeSortCode,
	|	RoomRatePrices.Period,
	|	RoomRatePrices.AccommodationTemplateCode,
	|	RoomRatePrices.AccommodationTypeSortCode";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qClientType", pClientType);
	vQry.SetParameter("qPeriodFrom", pPeriodFrom);
	vQry.SetParameter("qPeriodTo", pPeriodTo);
	vQry.SetParameter("qZeroPriceDays", cmGetZeroPriceDaysByDiscountType(pDiscountType, pPeriodFrom, pPeriodTo));
	
	vRoomRatesList = New ValueList();
	If TypeOf(pRoomRatesList) = Type("ValueList") Then
		vRoomRatesList = pRoomRatesList;
	Else
		vRoomRatesList.Add(pRoomRatesList);
	EndIf;
	vQry.SetParameter("qRoomRatesList", vRoomRatesList);
	
	vRoomRates = New ValueTable();
	vRoomRates.Columns.Add("RoomRateInCache", cmGetCatalogTypeDescription("RoomRates"));
	vRoomRates.Columns.Add("RoomRate", cmGetCatalogTypeDescription("RoomRates"));
	vRoomRates.Columns.Add("RoomRateCode", cmGetStringTypeDescription(25));
	vRoomRates.Columns.Add("RoomRateSortCode", cmGetNumberTypeDescription(6, 0, True));
	vRoomRates.Columns.Add("RoomRateDescription", cmGetStringTypeDescription(100));
	vRoomRates.Columns.Add("RoomRateCalendar", cmGetCatalogTypeDescription("Calendars"));
	For Each vRoomRatesListItem In vRoomRatesList Do
		vRoomRateRef = vRoomRatesListItem.Value;
		vRoomRatesRow = vRoomRates.Add();
		vRoomRatesRow.RoomRateInCache = ?(ValueIsFilled(vRoomRateRef.BasedOnRoomRate), vRoomRateRef.BasedOnRoomRate, vRoomRateRef);
		vRoomRatesRow.RoomRate = vRoomRateRef;
		vRoomRatesRow.RoomRateCode = vRoomRateRef.Code;
		vRoomRatesRow.RoomRateSortCode = vRoomRateRef.SortCode;
		vRoomRatesRow.RoomRateDescription = vRoomRateRef.Description;
		vRoomRatesRow.RoomRateCalendar = vRoomRateRef.Calendar;
	EndDo;
	vQry.SetParameter("qRoomRates", vRoomRates);

	vQry.SetParameter("qEmptyRoomType", Catalogs.RoomTypes.EmptyRef());
	vRoomTypesList = New ValueList();
	If TypeOf(pRoomType) = Type("ValueList") Then
		vRoomTypesList = pRoomType;
	Else
		If ValueIsFilled(pRoomType) Then
			If Not pRoomType.IsFolder Then
				vRoomTypesList.Add(pRoomType);
			Else
				vRoomTypes = cmGetAllRoomTypes(pHotel, pRoomType);
				vRoomTypesList.LoadValues(vRoomTypes.UnloadColumn("RoomType"));
			EndIf;
		Else
			vRoomTypes = cmGetAllRoomTypes(pHotel);
			vRoomTypesList.LoadValues(vRoomTypes.UnloadColumn("RoomType"));
		EndIf;
	EndIf;
	
	vTemplatesNoRoomTypeLimits = New ValueList();
	vTemplatesWithRoomTypeLimits = New ValueList();
	For Each vAccTemplateItem In pAccTemplates Do
		vAccTemplateRef = vAccTemplateItem.Value;
		If vAccTemplateRef.RoomTypes.Count() = 0 Then
			vTemplatesNoRoomTypeLimits.Add(vAccTemplateRef);
		Else
			vTemplatesWithRoomTypeLimits.Add(vAccTemplateRef);
		EndIf;
	EndDo;
	vQry.SetParameter("qTemplatesNoRoomTypeLimits", vTemplatesNoRoomTypeLimits);
	vQry.SetParameter("qTemplatesWithRoomTypeLimits", vTemplatesWithRoomTypeLimits);
	
	vPriceCalculationDate = CurrentSessionDate();
	
	vPriceTagsList = New ValueList();
	vEffectivePriceTags = cmGetEffectivePriceTags(pHotel, vRoomRatesList, pRoomType, pPeriodFrom, pPeriodTo, vPriceTagsList, , vPriceCalculationDate);
	vQry.SetParameter("qEffectivePriceTags", vEffectivePriceTags);
	
	vQry.SetParameter("qPriceCalculationDate", vPriceCalculationDate);
	
	// Execute query
	vPrices = vQry.Execute().Unload();
	vServicePackagesList = New ValueList();
	vServicePackagesCache = Undefined;
	vPricesRowsToDelete = New Array();
	vCurRoomRate = Undefined;
	
	vDiscountsCache = Undefined;
	rRoomDiscount = 0;
	vRoomDiscount = 0;
	If pDiscountType <> Undefined and pExternalSystemCode <> Undefined Then
		vRoomDiscount = GetDiscountByType(pExternalSystemCode, pDiscountType, pHotel, , vDiscountsCache);
		rRoomDiscount = vRoomDiscount;
	EndIf;
	
	// Get room rate restrictions
	vRestrictions = cmGetRoomRatesRestrictions(pHotel, vRoomRatesList, vRoomTypesList, cm1SecondShift(pPeriodFrom), cm0SecondShift(pPeriodTo), pWithoutOnline);
	vRestrictionsCache = New ValueTable();
	vRestrictionsCache.Columns.Add("RoomRate", cmGetCatalogTypeDescription("RoomRates"));
	vRestrictionsCache.Columns.Add("RoomType", cmGetCatalogTypeDescription("RoomTypes"));
	vRestrictionsCache.Columns.Add("PeriodFrom", cmGetDateTypeDescription());
	vRestrictionsCache.Columns.Add("PeriodTo", cmGetDateTypeDescription());
	vRestrictionsCache.Columns.Add("IsRestricted", cmGetBooleanTypeDescription());
	
	vCurRoomRate = Undefined;
	vCurRoomType1 = Undefined;
	vCurRoomType2 = Undefined;
	vSpecialOfferByPromoCode = Undefined;
	For Each vPriceRow In vPrices Do
		vCurDate = vPriceRow.Period;

		If vCurRoomRate <> vPriceRow.RoomRate Then
			vCurRoomRate = vPriceRow.RoomRate;
			vCurRoomRateBasedOnRoomRate = vCurRoomRate.BasedOnRoomRate;
			vCurRoomType1 = Undefined;
			vCurRoomType2 = Undefined;
			
			vServicePackagesList = New ValueList();

			If ValueIsFilled(vCurRoomRateBasedOnRoomRate) Then
				// We have to take differencies in the packages into account only
				vServicePackagesListForBasedOnRoomRate = vCurRoomRateBasedOnRoomRate.GetObject().pmGetRoomRateServicePackagesList(, True);
				vServicePackagesList = vCurRoomRate.GetObject().pmGetRoomRateServicePackagesList(, True);

				// Add to the current rate service packages list service packages that were removed from the base room rate
				i = 0;
				While i < vServicePackagesListForBasedOnRoomRate.Count() Do
					vSPRemovedFromBasedRR = vServicePackagesListForBasedOnRoomRate.Get(i).Value;
					If vServicePackagesList.FindByValue(vSPRemovedFromBasedRR) = Undefined Then
						vServicePackagesList.Add(vSPRemovedFromBasedRR, , True);
					EndIf;
					i = i + 1;
				EndDo;
				
				// Delete service packages that are present in the based on room rate list of service packages
				If vServicePackagesListForBasedOnRoomRate.Count() > 0 Then
					i = 0;
					While i < vServicePackagesList.Count() Do
						vServicePackagesListItem = vServicePackagesList.Get(i);
						If Not vServicePackagesListItem.Check Then
							vCurServicePackage = vServicePackagesListItem.Value;
							If vServicePackagesListForBasedOnRoomRate.FindByValue(vCurServicePackage) <> Undefined Then
								vDeleteSP = True;
								For Each vSPRow In vCurServicePackage.Services Do
									If vSPRow.IsInPrice And (vSPRow.AccountingDayNumber <> 0 Or ValueIsFilled(vSPRow.AccountingDate)) Then
										vDeleteSP = False;
										Break;
									EndIf;
								EndDo;
								If vDeleteSP Then
									vServicePackagesList.Delete(i);
								Else
									vServicePackagesListItem.Presentation = "<<DO_NOT_PROCESS>>";
									i = i + 1;
								EndIf;
							Else
								i = i + 1;
							EndIf;
						Else
							i = i + 1;
						EndIf;
					EndDo;
				EndIf;
			Else
				vServicePackagesList = vCurRoomRate.GetObject().pmGetRoomRateServicePackagesList(, True);
				i = 0;
				While i < vServicePackagesList.Count() Do
					vCurServicePackage = vServicePackagesList.Get(i).Value;
					vDeleteSP = True;
					For Each vSPRow In vCurServicePackage.Services Do
						If vSPRow.IsInPrice And (vSPRow.AccountingDayNumber <> 0 Or ValueIsFilled(vSPRow.AccountingDate)) Then
							vDeleteSP = False;
							Break;
						EndIf;
					EndDo;
					If vDeleteSP Then
						vServicePackagesList.Delete(i);
					Else
						i = i + 1;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		
		// Check room rate restrictions
		vRestrictionsCacheRows = vRestrictionsCache.FindRows(New Structure("RoomRate, RoomType, PeriodFrom, PeriodTo", vCurRoomRate, vPriceRow.RoomType, BegOfDay(pPeriodFrom), BegOfDay(pPeriodTo)));
		If vRestrictionsCacheRows.Count() > 0 Then
			vRestrictionsCacheRow = vRestrictionsCacheRows.Get(0);
			If vRestrictionsCacheRow.IsRestricted Then
				vPricesRowsToDelete.Add(vPriceRow);
				Continue;
			EndIf;
		Else
			If vCurRoomType1 <> vPriceRow.RoomType Then 
				vCurRoomType1 = vPriceRow.RoomType;

				vRestrictionsCacheRow = vRestrictionsCache.Add();
				vRestrictionsCacheRow.RoomRate = vCurRoomRate;
				vRestrictionsCacheRow.RoomType = vPriceRow.RoomType;
				vRestrictionsCacheRow.PeriodFrom = BegOfDay(pPeriodFrom);
				vRestrictionsCacheRow.PeriodTo = BegOfDay(pPeriodTo);
				vRestrictionsCacheRow.IsRestricted = False;
				If Not cmCheckRestrictions(vRestrictions, pHotel, vCurRoomRate, vCurRoomType1, cm1SecondShift(pPeriodFrom), cm0SecondShift(pPeriodTo), pWithoutLOSAndCTs) Then
					vRestrictionsCacheRow.IsRestricted = True;
					vPricesRowsToDelete.Add(vPriceRow);
					Continue;
				EndIf;
			EndIf;
		EndIf;
 	
		// Get discounts by promo code
		If vCurRoomType2 <> vPriceRow.RoomType Then 
			vCurRoomType2 = vPriceRow.RoomType;

			vPromoCodeDiscounts = New ValueTable();
			vPromoCodeDiscounts.Columns.Add("AccountingDate", cmGetDateTypeDescription());
			vPromoCodeDiscounts.Columns.Add("Discount", cmGetNumberTypeDescription(7, 3));
			If pPromoCodeStruct <> Undefined And Not IsBlankString(pPromoCodeStruct.PromoCode) Then
				vDatesList = Undefined;
				vSpecialOfferByPromoCode = Catalogs.SpecialOffers.GetSpecialOfferByPromoCode(pPromoCodeStruct.PromoCode, vCurRoomType2.Owner, pPromoCodeStruct.Date, pPromoCodeStruct.PeriodFrom, pPromoCodeStruct.Duration, pPromoCodeStruct.PeriodTo, vCurRoomRate, vCurRoomRate.RoomRateType, pPromoCodeStruct.ClientType, pPromoCodeStruct.CustomerType, pPromoCodeStruct.SourceOfBusiness, pPromoCodeStruct.MarketingCode, pPromoCodeStruct.TripPurpose, vCurRoomType2, vDatesList);
				If ValueIsFilled(vSpecialOfferByPromoCode) And ValueIsFilled(vSpecialOfferByPromoCode.DiscountType) Then
					For Each vDatesListItem In vDatesList Do
						vPromoCodeDiscount = GetDiscountByType(pExternalSystemCode, vSpecialOfferByPromoCode.DiscountType, pPromoCodeStruct.Hotel, vDatesListItem.Value, vDiscountsCache);
						If vPromoCodeDiscount <> 0 Then
							vPromoCodeDiscountsRow = vPromoCodeDiscounts.Add();
							vPromoCodeDiscountsRow.AccountingDate = vDatesListItem.Value;
							vPromoCodeDiscountsRow.Discount = vPromoCodeDiscount;
						EndIf;
					EndDo;
				EndIf;
			EndIf;
		EndIf;

		// Apply room rate rounding rules 
		If ValueIsFilled(vCurRoomRate) Then
			If vCurRoomRate.RoundPrice Then
				vPriceRow.Amount = Round(vPriceRow.Amount, vCurRoomRate.RoundPriceDigits);
				vPriceRow.AmountBeforeDiscount = Round(vPriceRow.AmountBeforeDiscount, vCurRoomRate.RoundPriceDigits);
				vPriceRow.FirstDaySum = Round(vPriceRow.FirstDaySum, vCurRoomRate.RoundPriceDigits);
			EndIf;
		EndIf;

		vDiscount = 0;
		If ValueIsFilled(vCurRoomRate) And Not vCurRoomRate.NoDiscounts Then
			vDiscount = vRoomDiscount;
			If pPromoCodeStruct <> Undefined And vPromoCodeDiscounts.Count() > 0 Then
				vPromoCodeDiscountsRows = vPromoCodeDiscounts.FindRows(New Structure("AccountingDate", vCurDate));
				If vPromoCodeDiscountsRows.Count() > 0 Then
					vPromoCodeDiscountsRow = vPromoCodeDiscountsRows.Get(0);
					vDiscount = Max(vPromoCodeDiscountsRow.Discount, vDiscount);
				EndIf;
			EndIf;
		EndIf;
		If vDiscount <> 0 And vPriceRow.Amount > 0 Then
			rRoomDiscount = Max(rRoomDiscount, vDiscount); 
			vDiscountSum = Round(vPriceRow.Amount * (vDiscount / 100), 2);
			If ValueIsFilled(vSpecialOfferByPromoCode) And ValueIsFilled(vSpecialOfferByPromoCode.DiscountType) 
				And vSpecialOfferByPromoCode.DiscountType.RoundPrice Then
				vDiscountSum = cmRoundDiscountAmount(vDiscountSum, vSpecialOfferByPromoCode.DiscountType.RoundPriceDigits, vSpecialOfferByPromoCode.DiscountType.RoundPriceType);
			EndIf;
			vPriceRow.Amount = vPriceRow.Amount - vDiscountSum;  
			vPriceRow.FirstDaySum = vPriceRow.FirstDaySum - (vPriceRow.FirstDaySum * (vDiscount / 100));
			// Apply room rate price rounding rule
			If vCurRoomRate.RoundPrice Then
				vPriceRow.Amount = Round(vPriceRow.Amount, vCurRoomRate.RoundPriceDigits);
				vPriceRow.FirstDaySum = Round(vPriceRow.FirstDaySum, vCurRoomRate.RoundPriceDigits);  
			EndIf;
		EndIf;
		
		For Each vServicePackagesItem In vServicePackagesList Do
			vCurServicePackage = vServicePackagesItem.Value;
			vServicePackagesItemPresentation = vServicePackagesItem.Presentation;
			// Check service package is valid period
			If vCurServicePackage.DateValidFrom <= BegOfDay(pPeriodFrom) And (vCurServicePackage.DateValidTo >= BegOfDay(pPeriodFrom) Or Not ValueIsFilled(vCurServicePackage.DateValidTo)) Then
				vCurCalendarDayType = Undefined;
				
				// Get service package services
				vCurServicePackageServices = Undefined;
				If vServicePackagesCache <> Undefined Then
					vCurServicePackageServices = vServicePackagesCache.FindRows(New Structure("ServicePackage, Period", vCurServicePackage, vCurDate));
					If vCurServicePackageServices.Count() = 0 Then
						vCurServicePackageServices = Undefined;
					EndIf;
				EndIf;
				If vCurServicePackageServices = Undefined Then
					vCurServicePackageServices = Catalogs.ServicePackages.GetServices(vCurServicePackage, vCurDate);
					If vServicePackagesCache = Undefined Then
						vServicePackagesCache = vCurServicePackageServices.Copy();
						vServicePackagesCache.Indexes.Add("ServicePackage, Period");
					Else
						For Each vCurServicePackageServicesRow In vCurServicePackageServices Do
							vServicePackagesCacheRow = vServicePackagesCache.Add();
							FillPropertyValues(vServicePackagesCacheRow, vCurServicePackageServicesRow);
						EndDo;
					EndIf;
				EndIf;
				For Each vSPRow In vCurServicePackageServices Do
					If vSPRow.IsInPrice And ValueIsFilled(vCurRoomRate) And 
					  (vSPRow.AccountingDayNumber <> 0 And ((vCurDate - BegOfDay(pPeriodFrom))/(tcCommonFunctionOnClientServer.cmOneDay()) + 1) = vSPRow.AccountingDayNumber Or 
					   vSPRow.AccountingDayNumber = 9999 And BegOfDay(pPeriodTo) = vCurDate Or 
					   ValueIsFilled(vSPRow.AccountingDate) And vSPRow.AccountingDate = vCurDate Or
					   vSPRow.AccountingDayNumber = 0 And Not ValueIsFilled(vSPRow.AccountingDate) And ValueIsFilled(vCurRoomRateBasedOnRoomRate) And vCurDate < BegOfDay(pPeriodTo) And vServicePackagesItemPresentation <> "<<DO_NOT_PROCESS>>") Then
						If vServicePackagesItem.Check And (vSPRow.AccountingDayNumber <> 0 Or ValueIsFilled(vSPRow.AccountingDate)) Then
						   Continue;
						EndIf;

						// Check accounting date time for service package
						If ValueIsFilled(vSPRow.AccountingDate) And vSPRow.AccountingDate <> BegOfDay(vSPRow.AccountingDate) Then
							If BegOfDay(pPeriodFrom) = BegOfDay(vSPRow.AccountingDate) And vSPRow.AccountingDate <= pPeriodFrom Then
								Continue;
							EndIf;
							If BegOfDay(pPeriodTo) = BegOfDay(vSPRow.AccountingDate) And vSPRow.AccountingDate >= pPeriodTo Then
								Continue;
							EndIf;
						EndIf;
						
						// Check current client type
						If pClientType <> vSPRow.ClientType Then
							Continue;
						EndIf;
											
						// Get and check date calendar day type
						If ValueIsFilled(vSPRow.CalendarDayType) Then
							If vCurCalendarDayType = Undefined Then
								vPriceTag = Undefined;
								vCurCalendarDayType = cmGetCalendarDayType(vCurRoomRate, vCurDate, pPeriodFrom, pPeriodTo, vPriceTag, vPriceRow.RoomType);
							EndIf;
							If vSPRow.CalendarDayType <> vCurCalendarDayType Then
								Continue;
							EndIf;
						EndIf;
						
						// Update price rows in prices
						If (Not ValueIsFilled(vSPRow.RoomType) Or ValueIsFilled(vSPRow.RoomType) And vSPRow.RoomType = vPriceRow.RoomType) And 
						   (Not ValueIsFilled(vSPRow.AccommodationType) Or ValueIsFilled(vSPRow.AccommodationType) And vSPRow.AccommodationType = vPriceRow.AccommodationType) Then
							vPrice = Round(cmConvertCurrencies(vSPRow.Price * ?(vSPRow.Quantity > 0, vSPRow.Quantity, 1), vSPRow.Currency, , vPriceRow.Currency, , vCurDate, pHotel), 2);
							vPriceAfterDiscount = vPrice - (vPrice * (vDiscount / 100));
							// Apply room rate price rounding rule
							If vCurRoomRate.RoundPrice Then
								If Not ValueIsFilled(vCurRoomRate.RoundPriceServiceGroup) Or 
								   ValueIsFilled(vCurRoomRate.RoundPriceServiceGroup) And cmIsServiceInServiceGroup(vSPRow.Service, vCurRoomRate.RoundPriceServiceGroup) Then
									vPriceAfterDiscount = Round(vPriceAfterDiscount, vCurRoomRate.RoundPriceDigits);
								EndIf;
							EndIf;
							
							vPriceRow.AmountBeforeDiscount = vPriceRow.AmountBeforeDiscount + ?(vServicePackagesItem.Check, -vPrice, vPrice);
							vPriceRow.Amount = vPriceRow.Amount + ?(vServicePackagesItem.Check, -vPriceAfterDiscount, vPriceAfterDiscount);
							If vCurDate = BegOfDay(pPeriodFrom) Then
								vPriceRow.FirstDaySum = vPriceRow.FirstDaySum + ?(vServicePackagesItem.Check, -vPriceAfterDiscount, vPriceAfterDiscount);
							EndIf;
						EndIf;
					EndIf;
				EndDo; // By service package services
			EndIf;
		EndDo; // By service packages
	EndDo;
	For Each vRowToDelete In vPricesRowsToDelete Do
		vPrices.Delete(vRowToDelete);
	EndDo;
	vPrices.GroupBy("Hotel, HotelCode, HotelSortCode, HotelDescription, RoomRate, RoomRateCode, RoomRateSortCode, RoomRateDescription, RoomType, RoomTypeCode, RoomTypeSortCode, AccommodationTemplate, AccommodationTemplateCode, RoomTypeDescription, AccommodationType, AccommodationTypeCode, AccommodationTypeSortCode, AccommodationTypeDescription, Currency, CurrencyCode, CurrencyDescription, RoomTypePictureLink, RoomTypeInfoLink, LineNumber", 
	                "AmountBeforeDiscount, Amount, FirstDaySum");
	vPrices.Sort("HotelSortCode, HotelDescription, RoomRateSortCode, RoomRateDescription, RoomTypeSortCode, AccommodationTemplateCode, AccommodationTypeSortCode");
	Return vPrices;
EndFunction // GetCachedPricesForPriceTags

// -----------------------------------------------------------------------------
// Returns cached room rate prices for the given accommodation templates and period
// -----------------------------------------------------------------------------
Function GetCachedPricesForPriceTagsByDays(pHotel, pClientType, pPeriodFrom, pPeriodTo, pRoomRatesList, pAccTemplates, pWithoutOnline = False, pWithoutLOSAndCTs = False, pDiscountType = Undefined, pExternalSystemCode = Undefined, pDurationForPriceTags = 1, pRoomType = Undefined, rRoomDiscount = 0) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomRates.RoomRateInCache AS RoomRateInCache,
	|	RoomRates.RoomRate AS RoomRate,
	|	RoomRates.RoomRateCode AS RoomRateCode,
	|	RoomRates.RoomRateSortCode AS RoomRateSortCode,
	|	RoomRates.RoomRateDescription AS RoomRateDescription,
	|	RoomRates.RoomRateCalendar AS RoomRateCalendar
	|INTO CacheRoomRates
	|FROM
	|	&qRoomRates AS RoomRates
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	EffectivePriceTags.Period AS Period,
	|	EffectivePriceTags.RoomRate AS RoomRate,
	|	EffectivePriceTags.RoomRateInCache AS RoomRateInCache,
	|	EffectivePriceTags.RoomType AS RoomType,
	|	EffectivePriceTags.PriceTag AS PriceTag
	|INTO EffectivePriceTags
	|FROM
	|	&qEffectivePriceTags AS EffectivePriceTags
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomRatesSliceLast.SetRoomRateFormulas AS Recorder,
	|	RoomRatesSliceLast.RoomRate AS RoomRate
	|INTO ActiveSetRoomRateFormulas
	|FROM
	|	InformationRegister.RoomRates.SliceLast(
	|			&qPriceCalculationDate,
	|			RoomRate IN (&qRoomRatesList)
	|				AND Hotel = &qHotel
	|				AND IsFormula) AS RoomRatesSliceLast
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CacheRoomRates.RoomRate AS RoomRate,
	|	&qHotel AS Hotel,
	|	AccommodationTemplatesAccommodationTypes.Ref AS AccommodationTemplate,
	|	HotelRoomTypes.Ref AS RoomType,
	|	HotelRoomTypes.RoomClass AS RoomClass,
	|	CASE
	|		WHEN NOT RoomRateOverrides.ToAccommodationType IS NULL
	|			THEN RoomRateOverrides.ToAccommodationType
	|		ELSE AccommodationTemplatesAccommodationTypes.AccommodationType
	|	END AS AccommodationType,
	|	AccommodationTemplatesAccommodationTypes.LineNumber AS LineNumber
	|INTO AccommodationTypesInTemplatesNoRoomTypeLimits
	|FROM
	|	CacheRoomRates AS CacheRoomRates
	|		LEFT JOIN Catalog.RoomTypes AS HotelRoomTypes
	|		ON (HotelRoomTypes.Owner = &qHotel)
	|			AND (NOT HotelRoomTypes.DeletionMark)
	|			AND (NOT HotelRoomTypes.IsFolder)
	|		INNER JOIN Catalog.AccommodationTemplates.AccommodationTypes AS AccommodationTemplatesAccommodationTypes
	|		ON (AccommodationTemplatesAccommodationTypes.Ref IN (&qTemplatesNoRoomTypeLimits))
	|		LEFT JOIN InformationRegister.RoomRateOverrides AS RoomRateOverrides
	|		ON CacheRoomRates.RoomRate = RoomRateOverrides.RoomRate
	|			AND (&qHotel = RoomRateOverrides.Hotel)
	|			AND (AccommodationTemplatesAccommodationTypes.Ref = RoomRateOverrides.AccommodationTemplate)
	|			AND (HotelRoomTypes.Ref = RoomRateOverrides.RoomType
	|				OR RoomRateOverrides.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
	|			AND (AccommodationTemplatesAccommodationTypes.AccommodationType = RoomRateOverrides.AccommodationType)
	|			AND (AccommodationTemplatesAccommodationTypes.LineNumber = RoomRateOverrides.TemplateLineNumber)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CacheRoomRates.RoomRate AS RoomRate,
	|	&qHotel AS Hotel,
	|	AccommodationTemplatesAccommodationTypes.Ref AS AccommodationTemplate,
	|	HotelRoomTypes.Ref AS RoomType,
	|	HotelRoomTypes.RoomClass AS RoomClass,
	|	CASE
	|		WHEN NOT RoomRateOverrides.ToAccommodationType IS NULL
	|			THEN RoomRateOverrides.ToAccommodationType
	|		ELSE AccommodationTemplatesAccommodationTypes.AccommodationType
	|	END AS AccommodationType,
	|	AccommodationTemplatesAccommodationTypes.LineNumber AS LineNumber
	|INTO AccommodationTypesInTemplatesWithRoomTypeLimits
	|FROM
	|	CacheRoomRates AS CacheRoomRates
	|		LEFT JOIN Catalog.RoomTypes AS HotelRoomTypes
	|		ON (HotelRoomTypes.Owner = &qHotel)
	|			AND (NOT HotelRoomTypes.DeletionMark)
	|			AND (NOT HotelRoomTypes.IsFolder)
	|		INNER JOIN Catalog.AccommodationTemplates.AccommodationTypes AS AccommodationTemplatesAccommodationTypes
	|		ON (AccommodationTemplatesAccommodationTypes.Ref IN (&qTemplatesWithRoomTypeLimits))
	|		INNER JOIN Catalog.AccommodationTemplates.RoomTypes AS AccommodationTemplatesRoomTypes
	|		ON (AccommodationTemplatesAccommodationTypes.Ref = AccommodationTemplatesRoomTypes.Ref)
	|			AND (HotelRoomTypes.Ref = AccommodationTemplatesRoomTypes.RoomType
	|					AND AccommodationTemplatesRoomTypes.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
	|				OR HotelRoomTypes.RoomClass = AccommodationTemplatesRoomTypes.RoomClass
	|					AND AccommodationTemplatesRoomTypes.RoomClass <> VALUE(Catalog.RoomTypeClasses.EmptyRef))
	|		LEFT JOIN InformationRegister.RoomRateOverrides AS RoomRateOverrides
	|		ON CacheRoomRates.RoomRate = RoomRateOverrides.RoomRate
	|			AND (&qHotel = RoomRateOverrides.Hotel)
	|			AND (AccommodationTemplatesAccommodationTypes.Ref = RoomRateOverrides.AccommodationTemplate)
	|			AND (HotelRoomTypes.Ref = RoomRateOverrides.RoomType
	|				OR RoomRateOverrides.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
	|			AND (AccommodationTemplatesAccommodationTypes.AccommodationType = RoomRateOverrides.AccommodationType)
	|			AND (AccommodationTemplatesAccommodationTypes.LineNumber = RoomRateOverrides.TemplateLineNumber)
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
	|	RoomRateDailyPrices.Period AS Period,
	|	RoomRateDailyPrices.Hotel AS Hotel,
	|	RoomRateDailyPrices.Hotel.Code AS HotelCode,
	|	RoomRateDailyPrices.Hotel.SortCode AS HotelSortCode,
	|	RoomRateDailyPrices.Hotel.Description AS HotelDescription,
	|	CacheRoomRates.RoomRate AS RoomRate,
	|	CacheRoomRates.RoomRateCode AS RoomRateCode,
	|	CacheRoomRates.RoomRateSortCode AS RoomRateSortCode,
	|	CacheRoomRates.RoomRateDescription AS RoomRateDescription,
	|	CacheRoomRates.RoomRateCalendar AS RoomRateCalendar,
	|	AccommodationTemplatesAccommodationTypes.AccommodationTemplate AS AccommodationTemplate,
	|	AccommodationTemplatesAccommodationTypes.AccommodationTemplate.Code AS AccommodationTemplateCode,
	|	RoomRateDailyPrices.RoomType AS RoomType,
	|	RoomRateDailyPrices.RoomType.Code AS RoomTypeCode,
	|	RoomRateDailyPrices.RoomType.SortCode AS RoomTypeSortCode,
	|	RoomRateDailyPrices.RoomType.Description AS RoomTypeDescription,
	|	RoomRateDailyPrices.AccommodationType AS AccommodationType,
	|	RoomRateDailyPrices.AccommodationType.Code AS AccommodationTypeCode,
	|	RoomRateDailyPrices.AccommodationType.SortCode AS AccommodationTypeSortCode,
	|	RoomRateDailyPrices.AccommodationType.Description AS AccommodationTypeDescription,
	|	RoomRateDailyPrices.Currency AS Currency,
	|	RoomRateDailyPrices.Currency.Code AS CurrencyCode,
	|	RoomRateDailyPrices.Currency.Description AS CurrencyDescription,
	|	RoomRateDailyPrices.ClientType AS ClientType,
	|	RoomRateDailyPrices.PriceTag AS PriceTag,
	|	RoomRateDailyPrices.Price AS Price,
	|	CAST(RoomRateDailyPrices.RoomType.RoomTypePictureLink AS STRING(1024)) AS RoomTypePictureLink,
	|	CAST(RoomRateDailyPrices.RoomType.RoomTypeInfoLink AS STRING(1024)) AS RoomTypeInfoLink,
	|	AccommodationTemplatesAccommodationTypes.LineNumber AS LineNumber
	|INTO RoomRateDailyPricesNoRoomTypeLimits
	|FROM
	|	InformationRegister.RoomRateDailyPrices AS RoomRateDailyPrices
	|		INNER JOIN CacheRoomRates AS CacheRoomRates
	|		ON RoomRateDailyPrices.RoomRate = CacheRoomRates.RoomRateInCache
	|		INNER JOIN AccommodationTypesInTemplatesNoRoomTypeLimits AS AccommodationTemplatesAccommodationTypes
	|		ON (AccommodationTemplatesAccommodationTypes.AccommodationType = RoomRateDailyPrices.AccommodationType)
	|			AND (AccommodationTemplatesAccommodationTypes.RoomRate = CacheRoomRates.RoomRate)
	|			AND (AccommodationTemplatesAccommodationTypes.Hotel = RoomRateDailyPrices.Hotel)
	|			AND (AccommodationTemplatesAccommodationTypes.RoomType = RoomRateDailyPrices.RoomType)
	|		INNER JOIN EffectivePriceTags AS EffectivePriceTags
	|		ON RoomRateDailyPrices.Period = EffectivePriceTags.Period
	|			AND RoomRateDailyPrices.RoomRate = EffectivePriceTags.RoomRateInCache
	|			AND CacheRoomRates.RoomRate = EffectivePriceTags.RoomRate
	|			AND (RoomRateDailyPrices.RoomType = EffectivePriceTags.RoomType
	|				OR EffectivePriceTags.RoomType = &qEmptyRoomType)
	|			AND RoomRateDailyPrices.PriceTag = EffectivePriceTags.PriceTag
	|WHERE
	|	RoomRateDailyPrices.Period >= &qPeriodFrom
	|	AND (RoomRateDailyPrices.Period < &qPeriodTo
	|				AND RoomRateDailyPrices.RoomRate.DurationCalculationRuleType <> VALUE(Enum.DurationCalculationRuleTypes.ByDays)
	|			OR RoomRateDailyPrices.Period <= &qPeriodTo
	|				AND RoomRateDailyPrices.RoomRate.DurationCalculationRuleType = VALUE(Enum.DurationCalculationRuleTypes.ByDays))
	|	AND RoomRateDailyPrices.Hotel = &qHotel
	|	AND RoomRateDailyPrices.ClientType = &qClientType
	|	AND (NOT &qRoomTypeIsSet
	|			OR &qRoomTypeIsSet
	|				AND RoomRateDailyPrices.RoomType = &qRoomType)
	|
	|INDEX BY
	|	CacheRoomRates.RoomRateCalendar,
	|	RoomRateDailyPrices.Period,
	|	RoomRateDailyPrices.RoomType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	RoomRateDailyPricesNoRoomTypeLimits.Period AS Period,
	|	RoomRateDailyPricesNoRoomTypeLimits.Hotel AS Hotel,
	|	RoomRateDailyPricesNoRoomTypeLimits.HotelCode AS HotelCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.HotelSortCode AS HotelSortCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.HotelDescription AS HotelDescription,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomRate AS RoomRate,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomRateCode AS RoomRateCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomRateSortCode AS RoomRateSortCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomRateDescription AS RoomRateDescription,
	|	RoomRateDailyPricesNoRoomTypeLimits.AccommodationTemplate AS AccommodationTemplate,
	|	RoomRateDailyPricesNoRoomTypeLimits.AccommodationTemplateCode AS AccommodationTemplateCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomType AS RoomType,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomTypeCode AS RoomTypeCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomTypeSortCode AS RoomTypeSortCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomTypeDescription AS RoomTypeDescription,
	|	RoomRateDailyPricesNoRoomTypeLimits.AccommodationType AS AccommodationType,
	|	RoomRateDailyPricesNoRoomTypeLimits.AccommodationTypeCode AS AccommodationTypeCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.AccommodationTypeSortCode AS AccommodationTypeSortCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.AccommodationTypeDescription AS AccommodationTypeDescription,
	|	RoomRateDailyPricesNoRoomTypeLimits.Currency AS Currency,
	|	RoomRateDailyPricesNoRoomTypeLimits.CurrencyCode AS CurrencyCode,
	|	RoomRateDailyPricesNoRoomTypeLimits.CurrencyDescription AS CurrencyDescription,
	|	CASE
	|		WHEN RoomRateDailyPricesNoRoomTypeLimits.Period IN (&qZeroPriceDays)
	|			THEN 0
	|		ELSE (RoomRateDailyPricesNoRoomTypeLimits.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0)
	|	END AS Amount,
	|	CASE
	|		WHEN BEGINOFPERIOD(RoomRateDailyPricesNoRoomTypeLimits.Period, DAY) = BEGINOFPERIOD(&qPeriodFrom, DAY)
	|			THEN (RoomRateDailyPricesNoRoomTypeLimits.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0)
	|		ELSE 0
	|	END AS FirstDaySum,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomTypePictureLink AS RoomTypePictureLink,
	|	RoomRateDailyPricesNoRoomTypeLimits.RoomTypeInfoLink AS RoomTypeInfoLink,
	|	RoomRateDailyPricesNoRoomTypeLimits.LineNumber AS LineNumber
	|INTO RoomRateDailyPricesNoRoomTypeLimitsEnriched
	|FROM
	|	RoomRateDailyPricesNoRoomTypeLimits AS RoomRateDailyPricesNoRoomTypeLimits
	|		LEFT JOIN InformationRegister.CalendarDays.SliceLast(&qPriceCalculationDate, ) AS CalendarDays
	|		ON RoomRateDailyPricesNoRoomTypeLimits.RoomRateCalendar = CalendarDays.Calendar
	|			AND RoomRateDailyPricesNoRoomTypeLimits.Period = CalendarDays.AccountingDate
	|		LEFT JOIN InformationRegister.CalendarDaysByRoomTypes.SliceLast(&qPriceCalculationDate, ) AS CalendarDaysByRoomTypes
	|		ON RoomRateDailyPricesNoRoomTypeLimits.RoomRateCalendar = CalendarDaysByRoomTypes.Calendar
	|			AND RoomRateDailyPricesNoRoomTypeLimits.Period = CalendarDaysByRoomTypes.AccountingDate
	|			AND RoomRateDailyPricesNoRoomTypeLimits.RoomType = CalendarDaysByRoomTypes.RoomType
	|		LEFT JOIN RoomRateFormulas AS RoomRateFormulas
	|		ON RoomRateDailyPricesNoRoomTypeLimits.RoomRate = RoomRateFormulas.RoomRate
	|			AND RoomRateDailyPricesNoRoomTypeLimits.Hotel = RoomRateFormulas.Hotel
	|			AND (NOT RoomRateFormulas.IsFormula
	|				OR RoomRateFormulas.IsFormula
	|					AND RoomRateDailyPricesNoRoomTypeLimits.RoomType = RoomRateFormulas.RoomType
	|					AND RoomRateDailyPricesNoRoomTypeLimits.ClientType = &qClientType
	|					AND RoomRateDailyPricesNoRoomTypeLimits.AccommodationType = RoomRateFormulas.AccommodationType
	|					AND (CalendarDaysByRoomTypes.CalendarDayType = RoomRateFormulas.CalendarDayType
	|							AND NOT CalendarDaysByRoomTypes.CalendarDayType IS NULL
	|							AND CalendarDaysByRoomTypes.CalendarDayType <> VALUE(Catalog.CalendarDayTypes.EmptyRef)
	|						OR CalendarDays.CalendarDayType = RoomRateFormulas.CalendarDayType
	|							AND NOT CalendarDays.CalendarDayType IS NULL
	|							AND (CalendarDaysByRoomTypes.CalendarDayType IS NULL OR CalendarDaysByRoomTypes.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef))
	|						OR RoomRateFormulas.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef)))
	|			AND (RoomRateFormulas.BasedOnPriceTag = VALUE(Catalog.PriceTags.EmptyRef)
	|				OR RoomRateDailyPricesNoRoomTypeLimits.PriceTag = RoomRateFormulas.BasedOnPriceTag
	|					AND RoomRateFormulas.BasedOnPriceTag <> VALUE(Catalog.PriceTags.EmptyRef))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	RoomRateDailyPrices.Period AS Period,
	|	RoomRateDailyPrices.Hotel AS Hotel,
	|	RoomRateDailyPrices.Hotel.Code AS HotelCode,
	|	RoomRateDailyPrices.Hotel.SortCode AS HotelSortCode,
	|	RoomRateDailyPrices.Hotel.Description AS HotelDescription,
	|	CacheRoomRates.RoomRate AS RoomRate,
	|	CacheRoomRates.RoomRateCode AS RoomRateCode,
	|	CacheRoomRates.RoomRateSortCode AS RoomRateSortCode,
	|	CacheRoomRates.RoomRateDescription AS RoomRateDescription,
	|	CacheRoomRates.RoomRateCalendar AS RoomRateCalendar,
	|	AccommodationTemplatesAccommodationTypes.AccommodationTemplate AS AccommodationTemplate,
	|	AccommodationTemplatesAccommodationTypes.AccommodationTemplate.Code AS AccommodationTemplateCode,
	|	RoomRateDailyPrices.RoomType AS RoomType,
	|	RoomRateDailyPrices.RoomType.Code AS RoomTypeCode,
	|	RoomRateDailyPrices.RoomType.SortCode AS RoomTypeSortCode,
	|	RoomRateDailyPrices.RoomType.Description AS RoomTypeDescription,
	|	RoomRateDailyPrices.AccommodationType AS AccommodationType,
	|	RoomRateDailyPrices.AccommodationType.Code AS AccommodationTypeCode,
	|	RoomRateDailyPrices.AccommodationType.SortCode AS AccommodationTypeSortCode,
	|	RoomRateDailyPrices.AccommodationType.Description AS AccommodationTypeDescription,
	|	RoomRateDailyPrices.Currency AS Currency,
	|	RoomRateDailyPrices.Currency.Code AS CurrencyCode,
	|	RoomRateDailyPrices.Currency.Description AS CurrencyDescription,
	|	RoomRateDailyPrices.ClientType AS ClientType,
	|	RoomRateDailyPrices.PriceTag AS PriceTag,
	|	RoomRateDailyPrices.Price AS Price,
	|	CAST(RoomRateDailyPrices.RoomType.RoomTypePictureLink AS STRING(1024)) AS RoomTypePictureLink,
	|	CAST(RoomRateDailyPrices.RoomType.RoomTypeInfoLink AS STRING(1024)) AS RoomTypeInfoLink,
	|	AccommodationTemplatesAccommodationTypes.LineNumber AS LineNumber
	|INTO RoomRateDailyPricesRoomTypesLimits
	|FROM
	|	InformationRegister.RoomRateDailyPrices AS RoomRateDailyPrices
	|		INNER JOIN CacheRoomRates AS CacheRoomRates
	|		ON RoomRateDailyPrices.RoomRate = CacheRoomRates.RoomRateInCache
	|		INNER JOIN AccommodationTypesInTemplatesWithRoomTypeLimits AS AccommodationTemplatesAccommodationTypes
	|		ON (AccommodationTemplatesAccommodationTypes.AccommodationType = RoomRateDailyPrices.AccommodationType)
	|			AND (AccommodationTemplatesAccommodationTypes.RoomRate = CacheRoomRates.RoomRate)
	|			AND (AccommodationTemplatesAccommodationTypes.Hotel = RoomRateDailyPrices.Hotel)
	|			AND (AccommodationTemplatesAccommodationTypes.RoomType = RoomRateDailyPrices.RoomType)
	|		INNER JOIN EffectivePriceTags AS EffectivePriceTags
	|		ON RoomRateDailyPrices.Period = EffectivePriceTags.Period
	|			AND RoomRateDailyPrices.RoomRate = EffectivePriceTags.RoomRateInCache
	|			AND CacheRoomRates.RoomRate = EffectivePriceTags.RoomRate
	|			AND (RoomRateDailyPrices.RoomType = EffectivePriceTags.RoomType
	|				OR EffectivePriceTags.RoomType = &qEmptyRoomType)
	|			AND RoomRateDailyPrices.PriceTag = EffectivePriceTags.PriceTag
	|WHERE
	|	RoomRateDailyPrices.Period >= &qPeriodFrom
	|	AND (RoomRateDailyPrices.Period < &qPeriodTo
	|				AND RoomRateDailyPrices.RoomRate.DurationCalculationRuleType <> VALUE(Enum.DurationCalculationRuleTypes.ByDays)
	|			OR RoomRateDailyPrices.Period <= &qPeriodTo
	|				AND RoomRateDailyPrices.RoomRate.DurationCalculationRuleType = VALUE(Enum.DurationCalculationRuleTypes.ByDays))
	|	AND RoomRateDailyPrices.Hotel = &qHotel
	|	AND RoomRateDailyPrices.ClientType = &qClientType
	|	AND (NOT &qRoomTypeIsSet
	|			OR &qRoomTypeIsSet
	|				AND RoomRateDailyPrices.RoomType = &qRoomType)
	|
	|INDEX BY
	|	CacheRoomRates.RoomRateCalendar,
	|	RoomRateDailyPrices.Period,
	|	RoomRateDailyPrices.RoomType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	RoomRateDailyPricesRoomTypesLimits.Period AS Period,
	|	RoomRateDailyPricesRoomTypesLimits.Hotel AS Hotel,
	|	RoomRateDailyPricesRoomTypesLimits.HotelCode AS HotelCode,
	|	RoomRateDailyPricesRoomTypesLimits.HotelSortCode AS HotelSortCode,
	|	RoomRateDailyPricesRoomTypesLimits.HotelDescription AS HotelDescription,
	|	RoomRateDailyPricesRoomTypesLimits.RoomRate AS RoomRate,
	|	RoomRateDailyPricesRoomTypesLimits.RoomRateCode AS RoomRateCode,
	|	RoomRateDailyPricesRoomTypesLimits.RoomRateSortCode AS RoomRateSortCode,
	|	RoomRateDailyPricesRoomTypesLimits.RoomRateDescription AS RoomRateDescription,
	|	RoomRateDailyPricesRoomTypesLimits.AccommodationTemplate AS AccommodationTemplate,
	|	RoomRateDailyPricesRoomTypesLimits.AccommodationTemplateCode AS AccommodationTemplateCode,
	|	RoomRateDailyPricesRoomTypesLimits.RoomType AS RoomType,
	|	RoomRateDailyPricesRoomTypesLimits.RoomTypeCode AS RoomTypeCode,
	|	RoomRateDailyPricesRoomTypesLimits.RoomTypeSortCode AS RoomTypeSortCode,
	|	RoomRateDailyPricesRoomTypesLimits.RoomTypeDescription AS RoomTypeDescription,
	|	RoomRateDailyPricesRoomTypesLimits.AccommodationType AS AccommodationType,
	|	RoomRateDailyPricesRoomTypesLimits.AccommodationTypeCode AS AccommodationTypeCode,
	|	RoomRateDailyPricesRoomTypesLimits.AccommodationTypeSortCode AS AccommodationTypeSortCode,
	|	RoomRateDailyPricesRoomTypesLimits.AccommodationTypeDescription AS AccommodationTypeDescription,
	|	RoomRateDailyPricesRoomTypesLimits.Currency AS Currency,
	|	RoomRateDailyPricesRoomTypesLimits.CurrencyCode AS CurrencyCode,
	|	RoomRateDailyPricesRoomTypesLimits.CurrencyDescription AS CurrencyDescription,
	|	CASE
	|		WHEN RoomRateDailyPricesRoomTypesLimits.Period IN (&qZeroPriceDays)
	|			THEN 0
	|		ELSE (RoomRateDailyPricesRoomTypesLimits.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0)
	|	END AS Amount,
	|	CASE
	|		WHEN BEGINOFPERIOD(RoomRateDailyPricesRoomTypesLimits.Period, DAY) = BEGINOFPERIOD(&qPeriodFrom, DAY)
	|			THEN (RoomRateDailyPricesRoomTypesLimits.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0)
	|		ELSE 0
	|	END AS FirstDaySum,
	|	RoomRateDailyPricesRoomTypesLimits.RoomTypePictureLink AS RoomTypePictureLink,
	|	RoomRateDailyPricesRoomTypesLimits.RoomTypeInfoLink AS RoomTypeInfoLink,
	|	RoomRateDailyPricesRoomTypesLimits.LineNumber AS LineNumber
	|INTO RoomRateDailyPricesRoomTypesLimitsEnriched
	|FROM
	|	RoomRateDailyPricesRoomTypesLimits AS RoomRateDailyPricesRoomTypesLimits
	|		LEFT JOIN InformationRegister.CalendarDays.SliceLast(&qPriceCalculationDate, ) AS CalendarDays
	|		ON RoomRateDailyPricesRoomTypesLimits.RoomRateCalendar = CalendarDays.Calendar
	|			AND RoomRateDailyPricesRoomTypesLimits.Period = CalendarDays.AccountingDate
	|		LEFT JOIN InformationRegister.CalendarDaysByRoomTypes.SliceLast(&qPriceCalculationDate, ) AS CalendarDaysByRoomTypes
	|		ON RoomRateDailyPricesRoomTypesLimits.RoomRateCalendar = CalendarDaysByRoomTypes.Calendar
	|			AND RoomRateDailyPricesRoomTypesLimits.Period = CalendarDaysByRoomTypes.AccountingDate
	|			AND RoomRateDailyPricesRoomTypesLimits.RoomType = CalendarDaysByRoomTypes.RoomType
	|		LEFT JOIN RoomRateFormulas AS RoomRateFormulas
	|		ON RoomRateDailyPricesRoomTypesLimits.RoomRate = RoomRateFormulas.RoomRate
	|			AND RoomRateDailyPricesRoomTypesLimits.Hotel = RoomRateFormulas.Hotel
	|			AND (NOT RoomRateFormulas.IsFormula
	|				OR RoomRateFormulas.IsFormula
	|					AND RoomRateDailyPricesRoomTypesLimits.RoomType = RoomRateFormulas.RoomType
	|					AND RoomRateDailyPricesRoomTypesLimits.ClientType = &qClientType
	|					AND RoomRateDailyPricesRoomTypesLimits.AccommodationType = RoomRateFormulas.AccommodationType
	|					AND (CalendarDaysByRoomTypes.CalendarDayType = RoomRateFormulas.CalendarDayType
	|							AND NOT CalendarDaysByRoomTypes.CalendarDayType IS NULL
	|							AND CalendarDaysByRoomTypes.CalendarDayType <> VALUE(Catalog.CalendarDayTypes.EmptyRef)
	|						OR CalendarDays.CalendarDayType = RoomRateFormulas.CalendarDayType
	|							AND NOT CalendarDays.CalendarDayType IS NULL
	|							AND (CalendarDaysByRoomTypes.CalendarDayType IS NULL OR CalendarDaysByRoomTypes.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef))
	|						OR RoomRateFormulas.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef)))
	|			AND (RoomRateFormulas.BasedOnPriceTag = VALUE(Catalog.PriceTags.EmptyRef)
	|				OR RoomRateDailyPricesRoomTypesLimits.PriceTag = RoomRateFormulas.BasedOnPriceTag
	|					AND RoomRateFormulas.BasedOnPriceTag <> VALUE(Catalog.PriceTags.EmptyRef))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomRatePrices.Period AS Period,
	|	RoomRatePrices.Hotel AS Hotel,
	|	RoomRatePrices.HotelCode AS HotelCode,
	|	RoomRatePrices.HotelSortCode AS HotelSortCode,
	|	RoomRatePrices.HotelDescription AS HotelDescription,
	|	RoomRatePrices.RoomRate AS RoomRate,
	|	RoomRatePrices.RoomRateCode AS RoomRateCode,
	|	RoomRatePrices.RoomRateSortCode AS RoomRateSortCode,
	|	RoomRatePrices.RoomRateDescription AS RoomRateDescription,
	|	RoomRatePrices.AccommodationTemplate AS AccommodationTemplate,
	|	RoomRatePrices.AccommodationTemplateCode AS AccommodationTemplateCode,
	|	RoomRatePrices.RoomType AS RoomType,
	|	RoomRatePrices.RoomTypeCode AS RoomTypeCode,
	|	RoomRatePrices.RoomTypeSortCode AS RoomTypeSortCode,
	|	RoomRatePrices.RoomTypeDescription AS RoomTypeDescription,
	|	RoomRatePrices.AccommodationType AS AccommodationType,
	|	RoomRatePrices.AccommodationTypeCode AS AccommodationTypeCode,
	|	RoomRatePrices.AccommodationTypeSortCode AS AccommodationTypeSortCode,
	|	RoomRatePrices.AccommodationTypeDescription AS AccommodationTypeDescription,
	|	RoomRatePrices.Currency AS Currency,
	|	RoomRatePrices.CurrencyCode AS CurrencyCode,
	|	RoomRatePrices.CurrencyDescription AS CurrencyDescription,
	|	RoomRatePrices.RoomTypePictureLink AS RoomTypePictureLink,
	|	RoomRatePrices.RoomTypeInfoLink AS RoomTypeInfoLink,
	|	RoomRatePrices.LineNumber AS LineNumber,
	|	SUM(RoomRatePrices.Amount) AS AmountBeforeDiscount,
	|	SUM(RoomRatePrices.Amount) AS Amount,
	|	SUM(RoomRatePrices.FirstDaySum) AS FirstDaySum
	|FROM
	|	(SELECT
	|		RoomRateDailyPricesNoRoomTypeLimits.Period AS Period,
	|		RoomRateDailyPricesNoRoomTypeLimits.Hotel AS Hotel,
	|		RoomRateDailyPricesNoRoomTypeLimits.HotelCode AS HotelCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.HotelSortCode AS HotelSortCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.HotelDescription AS HotelDescription,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomRate AS RoomRate,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomRateCode AS RoomRateCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomRateSortCode AS RoomRateSortCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomRateDescription AS RoomRateDescription,
	|		RoomRateDailyPricesNoRoomTypeLimits.AccommodationTemplate AS AccommodationTemplate,
	|		RoomRateDailyPricesNoRoomTypeLimits.AccommodationTemplateCode AS AccommodationTemplateCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomType AS RoomType,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomTypeCode AS RoomTypeCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomTypeSortCode AS RoomTypeSortCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomTypeDescription AS RoomTypeDescription,
	|		RoomRateDailyPricesNoRoomTypeLimits.AccommodationType AS AccommodationType,
	|		RoomRateDailyPricesNoRoomTypeLimits.AccommodationTypeCode AS AccommodationTypeCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.AccommodationTypeSortCode AS AccommodationTypeSortCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.AccommodationTypeDescription AS AccommodationTypeDescription,
	|		RoomRateDailyPricesNoRoomTypeLimits.Currency AS Currency,
	|		RoomRateDailyPricesNoRoomTypeLimits.CurrencyCode AS CurrencyCode,
	|		RoomRateDailyPricesNoRoomTypeLimits.CurrencyDescription AS CurrencyDescription,
	|		RoomRateDailyPricesNoRoomTypeLimits.Amount AS Amount,
	|		RoomRateDailyPricesNoRoomTypeLimits.FirstDaySum AS FirstDaySum,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomTypePictureLink AS RoomTypePictureLink,
	|		RoomRateDailyPricesNoRoomTypeLimits.RoomTypeInfoLink AS RoomTypeInfoLink,
	|		RoomRateDailyPricesNoRoomTypeLimits.LineNumber AS LineNumber
	|	FROM
	|		RoomRateDailyPricesNoRoomTypeLimitsEnriched AS RoomRateDailyPricesNoRoomTypeLimits
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RoomRateDailyPricesRoomTypesLimits.Period,
	|		RoomRateDailyPricesRoomTypesLimits.Hotel,
	|		RoomRateDailyPricesRoomTypesLimits.HotelCode,
	|		RoomRateDailyPricesRoomTypesLimits.HotelSortCode,
	|		RoomRateDailyPricesRoomTypesLimits.HotelDescription,
	|		RoomRateDailyPricesRoomTypesLimits.RoomRate,
	|		RoomRateDailyPricesRoomTypesLimits.RoomRateCode,
	|		RoomRateDailyPricesRoomTypesLimits.RoomRateSortCode,
	|		RoomRateDailyPricesRoomTypesLimits.RoomRateDescription,
	|		RoomRateDailyPricesRoomTypesLimits.AccommodationTemplate,
	|		RoomRateDailyPricesRoomTypesLimits.AccommodationTemplateCode,
	|		RoomRateDailyPricesRoomTypesLimits.RoomType,
	|		RoomRateDailyPricesRoomTypesLimits.RoomTypeCode,
	|		RoomRateDailyPricesRoomTypesLimits.RoomTypeSortCode,
	|		RoomRateDailyPricesRoomTypesLimits.RoomTypeDescription,
	|		RoomRateDailyPricesRoomTypesLimits.AccommodationType,
	|		RoomRateDailyPricesRoomTypesLimits.AccommodationTypeCode,
	|		RoomRateDailyPricesRoomTypesLimits.AccommodationTypeSortCode,
	|		RoomRateDailyPricesRoomTypesLimits.AccommodationTypeDescription,
	|		RoomRateDailyPricesRoomTypesLimits.Currency,
	|		RoomRateDailyPricesRoomTypesLimits.CurrencyCode,
	|		RoomRateDailyPricesRoomTypesLimits.CurrencyDescription,
	|		RoomRateDailyPricesRoomTypesLimits.Amount,
	|		RoomRateDailyPricesRoomTypesLimits.FirstDaySum,
	|		RoomRateDailyPricesRoomTypesLimits.RoomTypePictureLink,
	|		RoomRateDailyPricesRoomTypesLimits.RoomTypeInfoLink,
	|		RoomRateDailyPricesRoomTypesLimits.LineNumber
	|	FROM
	|		RoomRateDailyPricesRoomTypesLimitsEnriched AS RoomRateDailyPricesRoomTypesLimits) AS RoomRatePrices
	|
	|GROUP BY
	|	RoomRatePrices.Period,
	|	RoomRatePrices.Hotel,
	|	RoomRatePrices.HotelCode,
	|	RoomRatePrices.HotelSortCode,
	|	RoomRatePrices.HotelDescription,
	|	RoomRatePrices.RoomRate,
	|	RoomRatePrices.RoomRateCode,
	|	RoomRatePrices.RoomRateSortCode,
	|	RoomRatePrices.RoomRateDescription,
	|	RoomRatePrices.AccommodationTemplate,
	|	RoomRatePrices.AccommodationTemplateCode,
	|	RoomRatePrices.RoomType,
	|	RoomRatePrices.RoomTypeCode,
	|	RoomRatePrices.RoomTypeSortCode,
	|	RoomRatePrices.RoomTypeDescription,
	|	RoomRatePrices.AccommodationType,
	|	RoomRatePrices.AccommodationTypeCode,
	|	RoomRatePrices.AccommodationTypeSortCode,
	|	RoomRatePrices.AccommodationTypeDescription,
	|	RoomRatePrices.Currency,
	|	RoomRatePrices.CurrencyCode,
	|	RoomRatePrices.CurrencyDescription,
	|	RoomRatePrices.RoomTypePictureLink,
	|	RoomRatePrices.RoomTypeInfoLink,
	|	RoomRatePrices.LineNumber
	|
	|ORDER BY
	|	RoomRatePrices.HotelSortCode,
	|	RoomRatePrices.HotelDescription,
	|	RoomRatePrices.RoomRateSortCode,
	|	RoomRatePrices.RoomRateDescription,
	|	RoomRatePrices.RoomTypeSortCode,
	|	RoomRatePrices.Period,
	|	RoomRatePrices.AccommodationTemplateCode,
	|	RoomRatePrices.AccommodationTypeSortCode";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qClientType", pClientType);
	vQry.SetParameter("qPeriodFrom", pPeriodFrom);
	vQry.SetParameter("qPeriodTo", pPeriodTo);
	vQry.SetParameter("qEmptyRoomType", Catalogs.RoomTypes.EmptyRef());
	vQry.SetParameter("qRoomType", pRoomType);
	vQry.SetParameter("qRoomTypeIsSet", ValueIsFilled(pRoomType));
	vQry.SetParameter("qZeroPriceDays", cmGetZeroPriceDaysByDiscountType(pDiscountType, pPeriodFrom, pPeriodTo));
	
	vRoomRatesList = New ValueList();
	If TypeOf(pRoomRatesList) = Type("ValueList") Then
		vRoomRatesList = pRoomRatesList;
	Else
		vRoomRatesList.Add(pRoomRatesList);
	EndIf;
	vQry.SetParameter("qRoomRatesList", vRoomRatesList);
	
	vRoomRates = New ValueTable();
	vRoomRates.Columns.Add("RoomRateInCache", cmGetCatalogTypeDescription("RoomRates"));
	vRoomRates.Columns.Add("RoomRate", cmGetCatalogTypeDescription("RoomRates"));
	vRoomRates.Columns.Add("RoomRateCode", cmGetStringTypeDescription(25));
	vRoomRates.Columns.Add("RoomRateSortCode", cmGetNumberTypeDescription(6, 0, True));
	vRoomRates.Columns.Add("RoomRateDescription", cmGetStringTypeDescription(100));
	vRoomRates.Columns.Add("RoomRateCalendar", cmGetCatalogTypeDescription("Calendars"));
	For Each vRoomRatesListItem In vRoomRatesList Do
		vRoomRateRef = vRoomRatesListItem.Value;
		vRoomRatesRow = vRoomRates.Add();
		vRoomRatesRow.RoomRateInCache = ?(ValueIsFilled(vRoomRateRef.BasedOnRoomRate), vRoomRateRef.BasedOnRoomRate, vRoomRateRef);
		vRoomRatesRow.RoomRate = vRoomRateRef;
		vRoomRatesRow.RoomRateCode = vRoomRateRef.Code;
		vRoomRatesRow.RoomRateSortCode = vRoomRateRef.SortCode;
		vRoomRatesRow.RoomRateDescription = vRoomRateRef.Description;
		vRoomRatesRow.RoomRateCalendar = vRoomRateRef.Calendar;
	EndDo;
	vQry.SetParameter("qRoomRates", vRoomRates);
	
	vTemplatesNoRoomTypeLimits = New ValueList();
	vTemplatesWithRoomTypeLimits = New ValueList();
	For Each vAccTemplateItem In pAccTemplates Do
		vAccTemplateRef = vAccTemplateItem.Value;
		If vAccTemplateRef.RoomTypes.Count() = 0 Then
			vTemplatesNoRoomTypeLimits.Add(vAccTemplateRef);
		Else
			vTemplatesWithRoomTypeLimits.Add(vAccTemplateRef);
		EndIf;
	EndDo;
	vQry.SetParameter("qTemplatesNoRoomTypeLimits", vTemplatesNoRoomTypeLimits);
	vQry.SetParameter("qTemplatesWithRoomTypeLimits", vTemplatesWithRoomTypeLimits);
	
	vPriceCalculationDate = CurrentSessionDate();
	
	vPriceTagsList = New ValueList();
	vEffectivePriceTags = cmGetEffectivePriceTags(pHotel, vRoomRatesList, Undefined, pPeriodFrom, pPeriodTo, vPriceTagsList, pDurationForPriceTags, vPriceCalculationDate);
	vQry.SetParameter("qEffectivePriceTags", vEffectivePriceTags);
	
	vQry.SetParameter("qPriceCalculationDate", vPriceCalculationDate);
	
	// Execute query
	vPrices = vQry.Execute().Unload();
	vServicePackagesList = New ValueList();
	vServicePackagesCache = Undefined;
	vCurRoomRate = Undefined;
	rRoomDiscount = 0;
	If pDiscountType <> Undefined and pExternalSystemCode <> Undefined Then
		rRoomDiscount = GetDiscountByType(pExternalSystemCode, pDiscountType, pHotel);
	EndIf;
	
	For Each vPriceRow In vPrices Do
		If vCurRoomRate <> vPriceRow.RoomRate Then
			vCurRoomRate = vPriceRow.RoomRate;
			vCurRoomRateBasedOnRoomRate = vCurRoomRate.BasedOnRoomRate;
			
			vServicePackagesList = New ValueList();

			If ValueIsFilled(vCurRoomRateBasedOnRoomRate) Then
				
				// We have to take differencies in the packages into account only
				vServicePackagesListForBasedOnRoomRate = vCurRoomRateBasedOnRoomRate.GetObject().pmGetRoomRateServicePackagesList(, True);
				vServicePackagesList = vCurRoomRate.GetObject().pmGetRoomRateServicePackagesList(, True);

				// Add to the current rate service packages list service packages that were removed from the base room rate
				i = 0;
				While i < vServicePackagesListForBasedOnRoomRate.Count() Do
					vSPRemovedFromBasedRR = vServicePackagesListForBasedOnRoomRate.Get(i).Value;
					If vServicePackagesList.FindByValue(vSPRemovedFromBasedRR) = Undefined Then
						vServicePackagesList.Add(vSPRemovedFromBasedRR, , True);
					EndIf;
					i = i + 1;
				EndDo;
				
				// Delete service packages that are present in the based on room rate list of service packages
				If vServicePackagesListForBasedOnRoomRate.Count() > 0 Then
					i = 0;
					While i < vServicePackagesList.Count() Do
						vServicePackagesListItem = vServicePackagesList.Get(i);
						If Not vServicePackagesListItem.Check Then
							vCurServicePackage = vServicePackagesListItem.Value;
							If vServicePackagesListForBasedOnRoomRate.FindByValue(vCurServicePackage) <> Undefined Then
								vDeleteSP = True;
								For Each vSPRow In vCurServicePackage.Services Do
									If vSPRow.IsInPrice And (vSPRow.AccountingDayNumber <> 0 Or ValueIsFilled(vSPRow.AccountingDate)) Then
										vDeleteSP = False;
										Break;
									EndIf;
								EndDo;
								If vDeleteSP Then
									vServicePackagesList.Delete(i);
								Else
									vServicePackagesListItem.Presentation = "<<DO_NOT_PROCESS>>";
									i = i + 1;
								EndIf;
							Else
								i = i + 1;
							EndIf;
						Else
							i = i + 1;
						EndIf;
					EndDo;
				EndIf;
			Else
				vServicePackagesList = vCurRoomRate.GetObject().pmGetRoomRateServicePackagesList(, True);
				i = 0;
				While i < vServicePackagesList.Count() Do
					vCurServicePackage = vServicePackagesList.Get(i).Value;
					vDeleteSP = True;
					For Each vSPRow In vCurServicePackage.Services Do
						If vSPRow.IsInPrice And (vSPRow.AccountingDayNumber <> 0 Or ValueIsFilled(vSPRow.AccountingDate)) Then
							vDeleteSP = False;
							Break;
						EndIf;
					EndDo;
					If vDeleteSP Then
						vServicePackagesList.Delete(i);
					Else
						i = i + 1;
					EndIf;
				EndDo;
			EndIf;
		EndIf;

		// Apply room rate rounding rules 
		If ValueIsFilled(vCurRoomRate) Then
			If vCurRoomRate.RoundPrice Then
				vPriceRow.Amount = Round(vPriceRow.Amount, vCurRoomRate.RoundPriceDigits);
				vPriceRow.AmountBeforeDiscount = Round(vPriceRow.AmountBeforeDiscount, vCurRoomRate.RoundPriceDigits);
				vPriceRow.FirstDaySum = Round(vPriceRow.FirstDaySum, vCurRoomRate.RoundPriceDigits);
			EndIf;
		EndIf;
				
		If rRoomDiscount <> 0 Then
			vPriceRow.Amount = vPriceRow.Amount - (vPriceRow.Amount * (rRoomDiscount/100));
			// Apply room rate price rounding rule
			If vCurRoomRate.RoundPrice Then
				vPriceRow.Amount = Round(vPriceRow.Amount, vCurRoomRate.RoundPriceDigits);
			EndIf;
		EndIf;
		
		For Each vServicePackagesItem In vServicePackagesList Do
			vCurServicePackage = vServicePackagesItem.Value;
			vServicePackagesItemPresentation = vServicePackagesItem.Presentation;
			// Check if service package is valid
			If vCurServicePackage.DateValidFrom <= BegOfDay(pPeriodFrom) And (vCurServicePackage.DateValidTo >= BegOfDay(pPeriodFrom) Or Not ValueIsFilled(vCurServicePackage.DateValidTo)) Then
				vCurDate = BegOfDay(vPriceRow.Period);
				vCurCalendarDayType = Undefined;
				
				// Get service package services
				vCurServicePackageServices = Undefined;
				If vServicePackagesCache <> Undefined Then
					vCurServicePackageServices = vServicePackagesCache.FindRows(New Structure("ServicePackage, Period", vCurServicePackage, vCurDate));
					If vCurServicePackageServices.Count() = 0 Then
						vCurServicePackageServices = Undefined;
					EndIf;
				EndIf;
				If vCurServicePackageServices = Undefined Then
					vCurServicePackageServices = Catalogs.ServicePackages.GetServices(vCurServicePackage, vCurDate);
					If vServicePackagesCache = Undefined Then
						vServicePackagesCache = vCurServicePackageServices.Copy();
						vServicePackagesCache.Indexes.Add("ServicePackage, Period");
					Else
						For Each vCurServicePackageServicesRow In vCurServicePackageServices Do
							vServicePackagesCacheRow = vServicePackagesCache.Add();
							FillPropertyValues(vServicePackagesCacheRow, vCurServicePackageServicesRow);
						EndDo;
					EndIf;
				EndIf;
				For Each vSPRow In vCurServicePackageServices Do
					If vSPRow.IsInPrice And ValueIsFilled(vCurRoomRate) And 
					  (vSPRow.AccountingDayNumber <> 0 And ((vCurDate - BegOfDay(pPeriodFrom)) / (tcCommonFunctionOnClientServer.cmOneDay()) + 1) = vSPRow.AccountingDayNumber Or 
					   vSPRow.AccountingDayNumber = 9999 And BegOfDay(pPeriodTo) = vCurDate Or 
					   ValueIsFilled(vSPRow.AccountingDate) And vSPRow.AccountingDate = vCurDate Or
					   vSPRow.AccountingDayNumber = 0 And Not ValueIsFilled(vSPRow.AccountingDate) And ValueIsFilled(vCurRoomRateBasedOnRoomRate) And vCurDate < BegOfDay(pPeriodTo) And vServicePackagesItemPresentation <> "<<DO_NOT_PROCESS>>") Then
						If vServicePackagesItem.Check And (vSPRow.AccountingDayNumber <> 0 Or ValueIsFilled(vSPRow.AccountingDate)) Then
						   Continue;
						EndIf;

						// Check accounting date time for service package
						If ValueIsFilled(vSPRow.AccountingDate) And vSPRow.AccountingDate <> BegOfDay(vSPRow.AccountingDate) Then
							If BegOfDay(pPeriodFrom) = BegOfDay(vSPRow.AccountingDate) And vSPRow.AccountingDate <= pPeriodFrom Then
								Continue;
							EndIf;
							If BegOfDay(pPeriodTo) = BegOfDay(vSPRow.AccountingDate) And vSPRow.AccountingDate >= pPeriodTo Then
								Continue;
							EndIf;
						EndIf;
						
						// Check current client type
						If pClientType <> vSPRow.ClientType Then
							Continue;
						EndIf;
											
						// Get and check date calendar day type
						If ValueIsFilled(vSPRow.CalendarDayType) Then
							If vCurCalendarDayType = Undefined Then
								vPriceTag = Undefined;
								vCurCalendarDayType = cmGetCalendarDayType(vCurRoomRate, vCurDate, pPeriodFrom, pPeriodTo, vPriceTag, vPriceRow.RoomType);
							EndIf;
							If vSPRow.CalendarDayType <> vCurCalendarDayType Then
								Continue;
							EndIf;
						EndIf;
						
						// Update price rows in prices
						If (Not ValueIsFilled(vSPRow.RoomType) Or ValueIsFilled(vSPRow.RoomType) And vSPRow.RoomType = vPriceRow.RoomType) And 
						   (Not ValueIsFilled(vSPRow.AccommodationType) Or ValueIsFilled(vSPRow.AccommodationType) And vSPRow.AccommodationType = vPriceRow.AccommodationType) Then
							vPrice = Round(cmConvertCurrencies(vSPRow.Price * ?(vSPRow.Quantity > 0, vSPRow.Quantity, 1), vSPRow.Currency, , vPriceRow.Currency, , vCurDate, pHotel), 2);
							vPriceAfterDiscount = vPrice - (vPrice * (rRoomDiscount/100));
							// Apply room rate price rounding rule
							If vCurRoomRate.RoundPrice Then
								If Not ValueIsFilled(vCurRoomRate.RoundPriceServiceGroup) Or 
								   ValueIsFilled(vCurRoomRate.RoundPriceServiceGroup) And cmIsServiceInServiceGroup(vSPRow.Service, vCurRoomRate.RoundPriceServiceGroup) Then
									vPriceAfterDiscount = Round(vPriceAfterDiscount, vCurRoomRate.RoundPriceDigits);
								EndIf;
							EndIf;
							
							vPriceRow.AmountBeforeDiscount = vPriceRow.AmountBeforeDiscount + ?(vServicePackagesItem.Check, -vPrice, vPrice);
							vPriceRow.Amount = vPriceRow.Amount + ?(vServicePackagesItem.Check, -vPriceAfterDiscount, vPriceAfterDiscount);
							If vCurDate = BegOfDay(pPeriodFrom) Then
								vPriceRow.FirstDaySum = vPriceRow.FirstDaySum + ?(vServicePackagesItem.Check, -vPriceAfterDiscount, vPriceAfterDiscount);
							EndIf;
						EndIf;
					EndIf;
				EndDo; // By service package services
			EndIf;
		EndDo; // By service packages
	EndDo;
	Return vPrices;
EndFunction // GetCachedPricesForPriceTagsByDays

// -----------------------------------------------------------------------------
Function GetDiscountByType(pExternalSystemCode, pDiscountType, pHotel, pDate = '00010101', rCache = Undefined) Export
 	vResult = Undefined;
	
	If rCache = Undefined Then
		rCache = New ValueTable();
		rCache.Columns.Add("ExternalSystemCode", cmGetStringTypeDescription(100));
		rCache.Columns.Add("DicountType", cmGetCatalogTypeDescription("DiscountTypes"));
		rCache.Columns.Add("Hotel", cmGetCatalogTypeDescription("Hotels"));
		rCache.Columns.Add("AccountingDate", cmGetDateTypeDescription());
		rCache.Columns.Add("Discount", cmGetNumberTypeDescription(7, 3));

		rCache.Indexes.Add("DicountType, AccountingDate, ExternalSystemCode, Hotel");
	EndIf;
	
	vCacheRows = rCache.FindRows(New Structure("DicountType, AccountingDate, ExternalSystemCode, Hotel", pDiscountType, pDate, pExternalSystemCode, pHotel));
	If vCacheRows.Count() > 0 Then
		vResult = vCacheRows.Get(0).Discount;
	Else
		vServiceGroup = Undefined;
		If ValueIsFilled(pHotel) Then
			vServiceGroup = cmGetObjectRefByExternalSystemCode(pHotel, pExternalSystemCode, "ServiceGroups", "Rooms");
		EndIf;
		
		If ValueIsFilled(vServiceGroup) And Not vServiceGroup.DeletionMark And 
		   pDiscountType.DifferentDiscountPercentsForServiceGroupsAllowed Then
			vQuery = New Query;
			vQuery.Text = 
			"SELECT
			|	DiscountsSliceLast.DiscountType AS DiscountType,
			|	DiscountsSliceLast.ServiceGroup AS ServiceGroup,
			|	DiscountsSliceLast.Discount AS Discount
			|FROM
			|	InformationRegister.Discounts.SliceLast(
			|			&qDate,
			|			DiscountType = &qDiscountType
			|				AND ServiceGroup = &qServiceGroup
			|				AND (Hotel = &qHotel
			|					OR Hotel = VALUE(Catalog.Hotels.EmptyRef))) AS DiscountsSliceLast
			|WHERE
			|	NOT DiscountsSliceLast.DiscountType.DeletionMark
			|
			|GROUP BY
			|	DiscountsSliceLast.DiscountType,
			|	DiscountsSliceLast.ServiceGroup,
			|	DiscountsSliceLast.Discount";
			
			vQuery.SetParameter("qDiscountType", pDiscountType);
			vQuery.SetParameter("qHotel", pHotel);
			vQuery.SetParameter("qServiceGroup", vServiceGroup);
			vQuery.SetParameter("qDate", ?(ValueIsFilled(pDate), EndOfDay(pDate), '39991231235959'));
			
			vQueryResult = vQuery.Execute().Unload();
			For Each vRow In vQueryResult Do
				vResult = vRow.Discount; 
				Break;
			EndDo;	
		EndIf;
		
		If vResult = Undefined Then
			vQuery = New Query;
			If pDiscountType.DifferentDiscountPercentsForServiceGroupsAllowed Then 
				vQuery.Text = 
				"SELECT
				|	DiscountsSliceLast.DiscountType AS DiscountType,
				|	DiscountsSliceLast.ServiceGroup AS ServiceGroup,
				|	ServiceGroupsServices.Service AS Service,
				|	DiscountsSliceLast.Discount AS Discount
				|FROM
				|	InformationRegister.Discounts.SliceLast(
				|			&qDate,
				|			DiscountType = &qDiscountType
				|				AND (Hotel = &qHotel
				|					OR Hotel = VALUE(Catalog.Hotels.EmptyRef))) AS DiscountsSliceLast
				|		INNER JOIN Catalog.ServiceGroups.Services AS ServiceGroupsServices
				|		ON DiscountsSliceLast.ServiceGroup = ServiceGroupsServices.Ref
				|			AND (ISNULL(ServiceGroupsServices.Service.IsRoomRevenue, FALSE))
				|			AND (ISNULL(ServiceGroupsServices.Service.IsInPrice, FALSE))
				|			AND (NOT ServiceGroupsServices.Ref.DeletionMark)
				|WHERE
				|	NOT DiscountsSliceLast.DiscountType.DeletionMark
				|
				|GROUP BY
				|	DiscountsSliceLast.DiscountType,
				|	DiscountsSliceLast.ServiceGroup,
				|	ServiceGroupsServices.Service,
				|	DiscountsSliceLast.Discount";
			Else
				vQuery.Text = 
				"SELECT
				|	DiscountsSliceLast.DiscountType AS DiscountType,
				|	DiscountsSliceLast.Discount AS Discount
				|FROM
				|	InformationRegister.Discounts.SliceLast(
				|			&qDate,
				|			DiscountType = &qDiscountType
				|				AND ServiceGroup = VALUE(Catalog.ServiceGroups.EmptyRef)
				|				AND (Hotel = &qHotel
				|					OR Hotel = VALUE(Catalog.Hotels.EmptyRef))) AS DiscountsSliceLast
				|WHERE
				|	NOT DiscountsSliceLast.DiscountType.DeletionMark
				|
				|GROUP BY
				|	DiscountsSliceLast.DiscountType,
				|	DiscountsSliceLast.Discount";
			EndIf;
			vQuery.SetParameter("qDiscountType", pDiscountType);
			vQuery.SetParameter("qHotel", pHotel);
			vQuery.SetParameter("qDate", ?(ValueIsFilled(pDate), EndOfDay(pDate), '39991231235959'));
			
			vQueryResult = vQuery.Execute().Unload();
			For Each vRow In vQueryResult Do
				vResult = vRow.Discount; 
				Break;
			EndDo;	
		EndIf;

		If vResult = Undefined Then
			vResult = 0;
		EndIf;
		
		vCacheRow = rCache.Add();
		vCacheRow.ExternalSystemCode = pExternalSystemCode;
		vCacheRow.DicountType = pDiscountType;
		vCacheRow.Hotel = pHotel;
		vCacheRow.AccountingDate = pDate;
		vCacheRow.Discount = vResult;
	EndIf;
	
	Return vResult;
EndFunction // GetDiscountByType

// -----------------------------------------------------------------------------
Function GetServicesDiscount(pExternalSystemCode, pDiscountType, pHotel) Export
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	DiscountsSliceLast.DiscountType AS DiscountType,
	|	DiscountsSliceLast.ServiceGroup AS ServiceGroup,
	|	ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode,
	|	DiscountsSliceLast.Discount AS Discount
	|FROM
	|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
	|		INNER JOIN InformationRegister.Discounts.SliceLast(
	|				,
	|				DiscountType = &qDiscountType
	|					AND NOT DiscountType.DeletionMark
	|					AND NOT ServiceGroup.DeletionMark
	|					AND (Hotel = &qHotel
	|						OR Hotel = VALUE(Catalog.Hotels.EmptyRef))) AS DiscountsSliceLast
	|		ON ExternalSystemsObjectCodesMappings.ObjectRef = DiscountsSliceLast.ServiceGroup
	|WHERE
	|	ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
	|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = ""ServiceGroups""
	|	AND ExternalSystemsObjectCodesMappings.ObjectExternalCode <> ""Rooms""
	|	AND (ExternalSystemsObjectCodesMappings.Hotel = &qHotel
	|			OR ExternalSystemsObjectCodesMappings.Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|
	|GROUP BY
	|	DiscountsSliceLast.DiscountType,
	|	DiscountsSliceLast.ServiceGroup,
	|	ExternalSystemsObjectCodesMappings.ObjectExternalCode,
	|	DiscountsSliceLast.Discount";
	
	vQuery.SetParameter("qDiscountType", pDiscountType);
	vQuery.SetParameter("qHotel", pHotel);
	vQuery.SetParameter("qExternalSystemCode", pExternalSystemCode);

	vQueryResult = vQuery.Execute().Unload();
	
	Return vQueryResult;
EndFunction
 
#EndRegion
