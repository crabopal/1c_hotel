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
	If Not ValueIsFilled(PeriodFrom) Then
		PeriodFrom = BegOfMonth(CurrentSessionDate()); // For beg of month
		PeriodTo = EndOfDay(CurrentSessionDate());
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetReportParametersPresentation() Export
	vParamPresentation = "";
	If Not ValueIsFilled(PeriodFrom) And Not ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("en='Report period is not set';ru='Период отчета не установлен';de='Berichtszeitraum nicht festgelegt'") + 
		                     ";" + Chars.LF;
	ElsIf ValueIsFilled(PeriodFrom) And Not ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период c '; en = 'Period from '; de = 'Periode von '") + 
		                     Format(PeriodFrom, "DF='dd.MM.yyyy HH:mm'") + 
		                     ";" + Chars.LF;
	ElsIf Not ValueIsFilled(PeriodFrom) And ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период по '; en = 'Period to '; de = 'Periode zu '") + 
		                     Format(PeriodTo, "DF='dd.MM.yyyy HH:mm'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom = PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период на '; en = 'Period on '; de = 'Periode '") + 
		                     Format(PeriodFrom, "DF='dd.MM.yyyy HH:mm'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom < PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период '; en = 'Period '; de = 'Periode '") + PeriodPresentation(PeriodFrom, PeriodTo, cmLocalizationCode()) + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("en='Period is wrong!';ru='Неправильно задан период!';de='Der Zeitraum wurde falsch eingetragen!'") + 
		                     ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(HotelProduct) Then
		If Not HotelProduct.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Путевка '; en = 'Hotel product '; de = 'Einweisung '") + 
			                     TrimAll(HotelProduct.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Тип путевок/курсовок '; en = 'Vauchers type '; de = 'Einweisungtyp '") + 
			                     TrimAll(HotelProduct.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(Customer) Then
		If Not Customer.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("de='Firma ';en='Customer ';ru='Контрагент '") + 
			                     TrimAll(Customer.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("de='Gruppe Firmen ';en='Customers folder ';ru='Группа контрагентов '") + 
			                     TrimAll(Customer.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(Contract) Then
		vParamPresentation = vParamPresentation + NStr("en='Contract ';ru='Договор ';de='Vertrag '") + 
							 TrimAll(Contract.Description) + 
							 ";" + Chars.LF;
	EndIf;							 
	If ValueIsFilled(ServiceGroup) Then
		If Not ServiceGroup.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Набор услуг '; en = 'Service group '; de = 'Dienstgruppe '") + 
			                     TrimAll(ServiceGroup.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа наборов услуг '; en = 'Service groups folder '; de = 'Dienstgruppengruppe '") + 
			                     TrimAll(ServiceGroup.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;					 
	If ValueIsFilled(Hotel) Then
		If Not Hotel.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Hotel ';ru='Гостиница ';de='Hotel '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Hotels folder ';ru='Группа гостиниц ';de='Gruppe Hotels '") + 
			                     TrimAll(Hotel.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	Return vParamPresentation;
EndFunction // pmGetReportParametersPresentation

// -----------------------------------------------------------------------------
// Runs report
// -----------------------------------------------------------------------------
Procedure pmGenerate(pSpreadsheet, pAddChart = False) Export
	Var vTemplateAttributes;
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
	
	// Initialize report builder query generator attributes
	ReportBuilder.PresentationAdding = PresentationAdditionType.Add;
	
	// Fill report parameters
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qEmptyDate", '00010101');
	ReportBuilder.Parameters.Insert("qCustomer", Customer);
	ReportBuilder.Parameters.Insert("qIsEmptyCustomer", Not ValueIsFilled(Customer));
	ReportBuilder.Parameters.Insert("qContract", Contract);
	ReportBuilder.Parameters.Insert("qIsEmptyContract", Not ValueIsFilled(Contract));
	ReportBuilder.Parameters.Insert("qHotelProduct", HotelProduct);
	ReportBuilder.Parameters.Insert("qIsEmptyHotelProduct", Not ValueIsFilled(HotelProduct));
	ReportBuilder.Parameters.Insert("qEmptyHotelProduct", Catalogs.HotelProducts.EmptyRef());
	ReportBuilder.Parameters.Insert("qDurationCalculationRuleTypeByDays", Enums.DurationCalculationRuleTypes.ByDays);
	ReportBuilder.Parameters.Insert("qTogether", Enums.AccomodationTypes.Together);
	ReportBuilder.Parameters.Insert("qAdditionalBed", Enums.AccomodationTypes.AdditionalBed);
	vUseServicesList = False;
	vServicesList = New ValueList();
	If ValueIsFilled(ServiceGroup) Then
		If Not ServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(ServiceGroup);
		EndIf;
	EndIf;
	ReportBuilder.Parameters.Insert("qUseServicesList", vUseServicesList);
	ReportBuilder.Parameters.Insert("qServicesList", vServicesList);
	
	// Execute report builder query
	ReportBuilder.Execute();
	
	// Apply appearance settings to the report template
	vTemplateAttributes = cmApplyReportTemplateAppearance(ThisObject);
	
	// Output report to the spreadsheet
	ReportBuilder.Put(pSpreadsheet);
	//ReportBuilder.Template.Show(); // For debug purpose

	// Apply appearance settings to the report spreadsheet
	cmApplyReportAppearance(ThisObject, pSpreadsheet, vTemplateAttributes);
	
	// Add chart 
	If pAddChart Then
		cmAddReportChart(pSpreadsheet, ThisObject);
	EndIf;
EndProcedure // pmGenerate

// -----------------------------------------------------------------------------
Procedure pmInitializeReportBuilder() Export
	ReportBuilder = New ReportBuilder();
	
	// Initialize default query text
	QueryText = 
	"SELECT
	|	HotelProductSales.ReportingCurrency AS ReportingCurrency,
	|	HotelProductSales.Hotel AS Hotel,
	|	HotelProductSales.HotelProduct AS HotelProduct,
	|	HotelProductSales.Agent AS Agent,
	|	HotelProductSales.Customer AS Customer,
	|	HotelProductSales.Contract AS Contract,
	|	HotelProductSales.GuestGroup AS GuestGroup,
	|	HotelProductSales.Client AS Client,
	|	HotelProductSales.Count AS Count,
	|	CASE
	|		WHEN HotelProductSales.AccommodationType.Type = &qTogether
	|			THEN 0
	|		WHEN HotelProductSales.AccommodationType.Type = &qAdditionalBed
	|			THEN 0
	|		ELSE HotelProductSales.Count
	|	END AS FamilyCount,
	|	HotelProductSales.Sales AS Sales,
	|	HotelProductSales.RoomRevenue AS RoomRevenue,
	|	HotelProductSales.SalesWithoutVAT AS SalesWithoutVAT,
	|	HotelProductSales.RoomRevenueWithoutVAT AS RoomRevenueWithoutVAT,
	|	HotelProductSales.CommissionSum AS CommissionSum,
	|	HotelProductSales.CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|	HotelProductSales.DiscountSum AS DiscountSum,
	|	HotelProductSales.DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|	HotelProductSales.RoomsRented AS RoomsRented,
	|	HotelProductSales.BedsRented AS BedsRented,
	|	HotelProductSales.AdditionalBedsRented AS AdditionalBedsRented,
	|	HotelProductSales.GuestDays AS GuestDays,
	|	HotelProductSales.GuestsCheckedIn AS GuestsCheckedIn,
	|	HotelProductSales.RoomsCheckedIn AS RoomsCheckedIn,
	|	HotelProductSales.BedsCheckedIn AS BedsCheckedIn,
	|	HotelProductSales.AdditionalBedsCheckedIn AS AdditionalBedsCheckedIn
	|{SELECT
	|	ReportingCurrency.*,
	|	HotelProductSales.HotelProduct.RoomQuota.* AS RoomQuota,
	|	Hotel.*,
	|	HotelProduct.*,
	|	HotelProductSales.HotelProduct.Parent.* AS HotelProductParent,
	|	Agent.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	Client.*,
	|	Count,
	|	(CASE
	|			WHEN HotelProductSales.AccommodationType.Type = &qTogether
	|				THEN 0
	|			WHEN HotelProductSales.AccommodationType.Type = &qAdditionalBed
	|				THEN 0
	|			ELSE HotelProductSales.Count
	|		END) AS FamilyCount,
	|	HotelProductSales.NumberOfPersons AS NumberOfPersons,
	|	HotelProductSales.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	HotelProductSales.RoomRate.* AS RoomRate,
	|	HotelProductSales.AccommodationType.* AS AccommodationType,
	|	HotelProductSales.ClientType.* AS ClientType,
	|	HotelProductSales.MarketingCode.* AS MarketingCode,
	|	HotelProductSales.SourceOfBusiness.* AS SourceOfBusiness,
	|	HotelProductSales.TripPurpose.* AS TripPurpose,
	|	HotelProductSales.DiscountType.* AS DiscountType,
	|	HotelProductSales.Room.* AS Room,
	|	HotelProductSales.Room.RoomType.* AS RoomType,
	|	HotelProductSales.CheckInDate AS CheckInDate,
	|	(CASE
	|			WHEN HotelProductSales.RoomRate.DurationCalculationRuleType = &qDurationCalculationRuleTypeByDays
	|				THEN DATEDIFF(BEGINOFPERIOD(HotelProductSales.CheckInDate, DAY), ENDOFPERIOD(HotelProductSales.CheckOutDate, DAY), DAY)
	|			WHEN BEGINOFPERIOD(HotelProductSales.CheckInDate, DAY) = BEGINOFPERIOD(HotelProductSales.CheckOutDate, DAY)
	|				THEN 1
	|			ELSE DATEDIFF(BEGINOFPERIOD(HotelProductSales.CheckInDate, DAY), BEGINOFPERIOD(HotelProductSales.CheckOutDate, DAY), DAY)
	|		END) AS Duration,
	|	HotelProductSales.CheckOutDate AS CheckOutDate,
	|	Sales,
	|	RoomRevenue,
	|	SalesWithoutVAT,
	|	RoomRevenueWithoutVAT,
	|	CommissionSum,
	|	CommissionSumWithoutVAT,
	|	DiscountSum,
	|	DiscountSumWithoutVAT,
	|	RoomsRented,
	|	BedsRented,
	|	AdditionalBedsRented,
	|	GuestDays,
	|	GuestsCheckedIn,
	|	RoomsCheckedIn,
	|	BedsCheckedIn,
	|	AdditionalBedsCheckedIn}
	|FROM
	|	(SELECT
	|		HotelProductSalesTurnovers.ReportingCurrency AS ReportingCurrency,
	|		HotelProductSalesTurnovers.Hotel AS Hotel,
	|		HotelProductSalesTurnovers.HotelProduct AS HotelProduct,
	|		HotelProductSalesTurnovers.Agent AS Agent,
	|		HotelProductSalesTurnovers.Customer AS Customer,
	|		HotelProductSalesTurnovers.Contract AS Contract,
	|		HotelProductSalesTurnovers.GuestGroup AS GuestGroup,
	|		HotelProductSalesTurnovers.Client AS Client,
	|		HotelProductSalesTurnovers.ParentDoc.NumberOfPersons AS NumberOfPersons,
	|		HotelProductSalesTurnovers.PaymentMethod AS PlannedPaymentMethod,
	|		HotelProductSalesTurnovers.Folio.Room AS Room,
	|		HotelProductSalesTurnovers.ParentDoc.RoomRate AS RoomRate,
	|		HotelProductSalesTurnovers.ParentDoc.AccommodationType AS AccommodationType,
	|		HotelProductSalesTurnovers.ParentDoc.ClientType AS ClientType,
	|		HotelProductSalesTurnovers.ParentDoc.MarketingCode AS MarketingCode,
	|		HotelProductSalesTurnovers.ParentDoc.SourceOfBusiness AS SourceOfBusiness,
	|		HotelProductSalesTurnovers.ParentDoc.TripPurpose AS TripPurpose,
	|		HotelProductSalesTurnovers.ParentDoc.DiscountType AS DiscountType,
	|		MIN(CASE
	|				WHEN NOT HotelProductSalesTurnovers.ParentDoc.CheckInDate IS NULL 
	|					THEN HotelProductSalesTurnovers.ParentDoc.CheckInDate
	|				WHEN NOT HotelProductSalesTurnovers.Folio.DateTimeFrom IS NULL 
	|					THEN HotelProductSalesTurnovers.Folio.DateTimeFrom
	|				WHEN NOT HotelProductSalesTurnovers.ParentDoc.DateTimeFrom IS NULL 
	|					THEN HotelProductSalesTurnovers.ParentDoc.DateTimeFrom
	|				ELSE &qEmptyDate
	|			END) AS CheckInDate,
	|		MAX(CASE
	|				WHEN NOT HotelProductSalesTurnovers.ParentDoc.CheckOutDate IS NULL 
	|					THEN HotelProductSalesTurnovers.ParentDoc.CheckOutDate
	|				WHEN NOT HotelProductSalesTurnovers.Folio.DateTimeTo IS NULL 
	|					THEN HotelProductSalesTurnovers.Folio.DateTimeTo
	|				WHEN NOT HotelProductSalesTurnovers.ParentDoc.DateTimeTo IS NULL 
	|					THEN HotelProductSalesTurnovers.ParentDoc.DateTimeTo
	|				ELSE &qEmptyDate
	|			END) AS CheckOutDate,
	|		SUM(HotelProductSalesTurnovers.SalesTurnover) AS Sales,
	|		SUM(HotelProductSalesTurnovers.RoomRevenueTurnover) AS RoomRevenue,
	|		SUM(HotelProductSalesTurnovers.SalesWithoutVATTurnover) AS SalesWithoutVAT,
	|		SUM(HotelProductSalesTurnovers.RoomRevenueWithoutVATTurnover) AS RoomRevenueWithoutVAT,
	|		SUM(HotelProductSalesTurnovers.CommissionSumTurnover) AS CommissionSum,
	|		SUM(HotelProductSalesTurnovers.CommissionSumWithoutVATTurnover) AS CommissionSumWithoutVAT,
	|		SUM(HotelProductSalesTurnovers.DiscountSumTurnover) AS DiscountSum,
	|		SUM(HotelProductSalesTurnovers.DiscountSumWithoutVATTurnover) AS DiscountSumWithoutVAT,
	|		SUM(HotelProductSalesTurnovers.RoomsRentedTurnover) AS RoomsRented,
	|		SUM(HotelProductSalesTurnovers.BedsRentedTurnover) AS BedsRented,
	|		SUM(HotelProductSalesTurnovers.AdditionalBedsRentedTurnover) AS AdditionalBedsRented,
	|		SUM(HotelProductSalesTurnovers.GuestDaysTurnover) AS GuestDays,
	|		SUM(HotelProductSalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedIn,
	|		SUM(HotelProductSalesTurnovers.RoomsCheckedInTurnover) AS RoomsCheckedIn,
	|		SUM(HotelProductSalesTurnovers.BedsCheckedInTurnover) AS BedsCheckedIn,
	|		SUM(HotelProductSalesTurnovers.AdditionalBedsCheckedInTurnover) AS AdditionalBedsCheckedIn,
	|		COUNT(DISTINCT HotelProductSalesTurnovers.HotelProduct) AS Count
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Day,
	|				Hotel IN HIERARCHY (&qHotel)
	|					AND (Customer IN HIERARCHY (&qCustomer)
	|						OR &qIsEmptyCustomer)
	|					AND (Contract = &qContract
	|						OR &qIsEmptyContract)
	|					AND (HotelProduct IN HIERARCHY (&qHotelProduct)
	|						OR &qIsEmptyHotelProduct)
	|					AND HotelProduct <> &qEmptyHotelProduct
	|					AND (Service IN (&qServicesList)
	|						OR NOT &qUseServicesList)) AS HotelProductSalesTurnovers
	|	
	|	GROUP BY
	|		HotelProductSalesTurnovers.ReportingCurrency,
	|		HotelProductSalesTurnovers.Hotel,
	|		HotelProductSalesTurnovers.HotelProduct,
	|		HotelProductSalesTurnovers.Agent,
	|		HotelProductSalesTurnovers.Customer,
	|		HotelProductSalesTurnovers.Contract,
	|		HotelProductSalesTurnovers.GuestGroup,
	|		HotelProductSalesTurnovers.Client,
	|		HotelProductSalesTurnovers.ParentDoc.NumberOfPersons,
	|		HotelProductSalesTurnovers.PaymentMethod,
	|		HotelProductSalesTurnovers.Folio.Room,
	|		HotelProductSalesTurnovers.ParentDoc.RoomRate,
	|		HotelProductSalesTurnovers.ParentDoc.AccommodationType,
	|		HotelProductSalesTurnovers.ParentDoc.ClientType,
	|		HotelProductSalesTurnovers.ParentDoc.MarketingCode,
	|		HotelProductSalesTurnovers.ParentDoc.SourceOfBusiness,
	|		HotelProductSalesTurnovers.ParentDoc.TripPurpose,
	|		HotelProductSalesTurnovers.ParentDoc.DiscountType) AS HotelProductSales
	|{WHERE
	|	HotelProductSales.ReportingCurrency.*,
	|	HotelProductSales.HotelProduct.RoomQuota.* AS RoomQuota,
	|	HotelProductSales.Hotel.*,
	|	HotelProductSales.HotelProduct.*,
	|	HotelProductSales.HotelProduct.Parent.* AS HotelProductParent,
	|	HotelProductSales.Agent.*,
	|	HotelProductSales.Customer.*,
	|	HotelProductSales.Contract.*,
	|	HotelProductSales.GuestGroup.*,
	|	HotelProductSales.Client.*,
	|	HotelProductSales.Count AS Count,
	|	(CASE
	|			WHEN HotelProductSales.AccommodationType.Type = &qTogether
	|				THEN 0
	|			WHEN HotelProductSales.AccommodationType.Type = &qAdditionalBed
	|				THEN 0
	|			ELSE HotelProductSales.Count
	|		END) AS FamilyCount,
	|	HotelProductSales.NumberOfPersons AS NumberOfPersons,
	|	HotelProductSales.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	HotelProductSales.RoomRate.* AS RoomRate,
	|	HotelProductSales.AccommodationType.* AS AccommodationType,
	|	HotelProductSales.ClientType.* AS ClientType,
	|	HotelProductSales.MarketingCode.* AS MarketingCode,
	|	HotelProductSales.SourceOfBusiness.* AS SourceOfBusiness,
	|	HotelProductSales.TripPurpose.* AS TripPurpose,
	|	HotelProductSales.DiscountType.* AS DiscountType,
	|	HotelProductSales.Room.* AS Room,
	|	HotelProductSales.Room.RoomType.* AS RoomType,
	|	HotelProductSales.CheckInDate AS CheckInDate,
	|	(CASE
	|			WHEN HotelProductSales.RoomRate.DurationCalculationRuleType = &qDurationCalculationRuleTypeByDays
	|				THEN DATEDIFF(BEGINOFPERIOD(HotelProductSales.CheckInDate, DAY), ENDOFPERIOD(HotelProductSales.CheckOutDate, DAY), DAY)
	|			WHEN BEGINOFPERIOD(HotelProductSales.CheckInDate, DAY) = BEGINOFPERIOD(HotelProductSales.CheckOutDate, DAY)
	|				THEN 1
	|			ELSE DATEDIFF(BEGINOFPERIOD(HotelProductSales.CheckInDate, DAY), BEGINOFPERIOD(HotelProductSales.CheckOutDate, DAY), DAY)
	|		END) AS Duration,
	|	HotelProductSales.CheckOutDate AS CheckOutDate,
	|	HotelProductSales.Sales,
	|	HotelProductSales.RoomRevenue,
	|	HotelProductSales.SalesWithoutVAT,
	|	HotelProductSales.RoomRevenueWithoutVAT,
	|	HotelProductSales.CommissionSum,
	|	HotelProductSales.CommissionSumWithoutVAT,
	|	HotelProductSales.DiscountSum,
	|	HotelProductSales.DiscountSumWithoutVAT,
	|	HotelProductSales.RoomsRented,
	|	HotelProductSales.BedsRented,
	|	HotelProductSales.AdditionalBedsRented,
	|	HotelProductSales.GuestDays,
	|	HotelProductSales.GuestsCheckedIn,
	|	HotelProductSales.RoomsCheckedIn,
	|	HotelProductSales.BedsCheckedIn,
	|	HotelProductSales.AdditionalBedsCheckedIn}
	|
	|ORDER BY
	|	ReportingCurrency,
	|	Customer,
	|	HotelProduct
	|{ORDER BY
	|	ReportingCurrency.*,
	|	HotelProductSales.HotelProduct.RoomQuota.* AS RoomQuota,
	|	Hotel.*,
	|	HotelProduct.*,
	|	HotelProductSales.HotelProduct.Parent.* AS HotelProductParent,
	|	Agent.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	Client.*,
	|	HotelProductSales.NumberOfPersons AS NumberOfPersons,
	|	HotelProductSales.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	HotelProductSales.RoomRate.* AS RoomRate,
	|	HotelProductSales.AccommodationType.* AS AccommodationType,
	|	HotelProductSales.ClientType.* AS ClientType,
	|	HotelProductSales.MarketingCode.* AS MarketingCode,
	|	HotelProductSales.SourceOfBusiness.* AS SourceOfBusiness,
	|	HotelProductSales.TripPurpose.* AS TripPurpose,
	|	HotelProductSales.DiscountType.* AS DiscountType,
	|	HotelProductSales.Room.* AS Room,
	|	HotelProductSales.Room.RoomType.* AS RoomType,
	|	HotelProductSales.CheckInDate AS CheckInDate,
	|	(CASE
	|			WHEN HotelProductSales.RoomRate.DurationCalculationRuleType = &qDurationCalculationRuleTypeByDays
	|				THEN DATEDIFF(BEGINOFPERIOD(HotelProductSales.CheckInDate, DAY), ENDOFPERIOD(HotelProductSales.CheckOutDate, DAY), DAY)
	|			WHEN BEGINOFPERIOD(HotelProductSales.CheckInDate, DAY) = BEGINOFPERIOD(HotelProductSales.CheckOutDate, DAY)
	|				THEN 1
	|			ELSE DATEDIFF(BEGINOFPERIOD(HotelProductSales.CheckInDate, DAY), BEGINOFPERIOD(HotelProductSales.CheckOutDate, DAY), DAY)
	|		END) AS Duration,
	|	HotelProductSales.CheckOutDate AS CheckOutDate,
	|	Sales,
	|	RoomRevenue,
	|	SalesWithoutVAT,
	|	RoomRevenueWithoutVAT,
	|	CommissionSum,
	|	CommissionSumWithoutVAT,
	|	DiscountSum,
	|	DiscountSumWithoutVAT,
	|	RoomsRented,
	|	BedsRented,
	|	AdditionalBedsRented,
	|	GuestDays,
	|	GuestsCheckedIn,
	|	RoomsCheckedIn,
	|	BedsCheckedIn,
	|	AdditionalBedsCheckedIn}
	|TOTALS
	|	SUM(Count),
	|	SUM(FamilyCount),
	|	SUM(Sales),
	|	SUM(RoomRevenue),
	|	SUM(SalesWithoutVAT),
	|	SUM(RoomRevenueWithoutVAT),
	|	SUM(CommissionSum),
	|	SUM(CommissionSumWithoutVAT),
	|	SUM(DiscountSum),
	|	SUM(DiscountSumWithoutVAT),
	|	SUM(RoomsRented),
	|	SUM(BedsRented),
	|	SUM(AdditionalBedsRented),
	|	SUM(GuestDays),
	|	SUM(GuestsCheckedIn),
	|	SUM(RoomsCheckedIn),
	|	SUM(BedsCheckedIn),
	|	SUM(AdditionalBedsCheckedIn)
	|BY
	|	OVERALL,
	|	ReportingCurrency,
	|	Customer HIERARCHY
	|{TOTALS BY
	|	ReportingCurrency.*,
	|	HotelProductSales.HotelProduct.RoomQuota.* AS RoomQuota,
	|	Hotel.*,
	|	HotelProduct.*,
	|	HotelProductSales.HotelProduct.Parent.* AS HotelProductParent,
	|	Agent.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	Client.*,
	|	(CASE
	|			WHEN HotelProductSales.RoomRate.DurationCalculationRuleType = &qDurationCalculationRuleTypeByDays
	|				THEN DATEDIFF(BEGINOFPERIOD(HotelProductSales.CheckInDate, DAY), ENDOFPERIOD(HotelProductSales.CheckOutDate, DAY), DAY)
	|			WHEN BEGINOFPERIOD(HotelProductSales.CheckInDate, DAY) = BEGINOFPERIOD(HotelProductSales.CheckOutDate, DAY)
	|				THEN 1
	|			ELSE DATEDIFF(BEGINOFPERIOD(HotelProductSales.CheckInDate, DAY), BEGINOFPERIOD(HotelProductSales.CheckOutDate, DAY), DAY)
	|		END) AS Duration,
	|	HotelProductSales.NumberOfPersons AS NumberOfPersons,
	|	HotelProductSales.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	HotelProductSales.Room.* AS Room,
	|	HotelProductSales.Room.RoomType.* AS RoomType,
	|	HotelProductSales.RoomRate.* AS RoomRate,
	|	HotelProductSales.AccommodationType.* AS AccommodationType,
	|	HotelProductSales.ClientType.* AS ClientType,
	|	HotelProductSales.MarketingCode.* AS MarketingCode,
	|	HotelProductSales.SourceOfBusiness.* AS SourceOfBusiness,
	|	HotelProductSales.TripPurpose.* AS TripPurpose,
	|	HotelProductSales.DiscountType.* AS DiscountType}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Hotel product sales';RU='Продажи путевок';de='Verkauf von Reiseschecks'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
Function pmIsResource(pName) Export
	If pName = "Sales" 
	   Or pName = "RoomRevenue" 
	   Or pName = "SalesWithoutVAT" 
	   Or pName = "RoomRevenueWithoutVAT" 
	   Or pName = "CommissionSum" 
	   Or pName = "CommissionSumWithoutVAT" 
	   Or pName = "DiscountSum" 
	   Or pName = "DiscountSumWithoutVAT" 
	   Or pName = "RoomsRented" 
	   Or pName = "BedsRented" 
	   Or pName = "AdditionalBedsRented" 
	   Or pName = "GuestDays" 
	   Or pName = "GuestsCheckedIn" 
	   Or pName = "RoomsCheckedIn" 
	   Or pName = "BedsCheckedIn" 
	   Or pName = "AdditionalBedsCheckedIn" 
	   Or pName = "FamilyCount" 
	   Or pName = "Count" Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // pmIsResource

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
