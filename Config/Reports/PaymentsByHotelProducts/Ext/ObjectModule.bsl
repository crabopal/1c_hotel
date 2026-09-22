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
			vParamPresentation = vParamPresentation + NStr("de='Firmengruppe ';en='Customers folder ';ru='Группа контрагентов '") + 
			                     TrimAll(Customer.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(Contract) Then
		vParamPresentation = vParamPresentation + NStr("en='Contract ';ru='Договор ';de='Vertrag '") + 
							 TrimAll(Contract.Description) + 
							 ";" + Chars.LF;
	EndIf;							 
	If ValueIsFilled(GuestGroup) Then
		vParamPresentation = vParamPresentation + NStr("en='Guest group ';ru='Группа ';de='Gruppe '") + 
							 TrimAll(GuestGroup.Code) + 
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
	If ValueIsFilled(PaymentMethod) Then
		vParamPresentation = vParamPresentation + NStr("en='Payment method ';ru='Способ оплаты ';de='Zahlungsmethode '") + 
							 TrimAll(PaymentMethod.Description) + 
							 ";" + Chars.LF;
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
Procedure pmGenerate(pSpreadsheet, pAddChart = False) Export
	Var vTemplateAttributes;
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
	
	// Initialize report builder query generator attributes
	ReportBuilder.PresentationAdding = PresentationAdditionType.Add;
	
	// Fill report parameters
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qPeriodFrom", AddMonth(PeriodFrom, -12));
	ReportBuilder.Parameters.Insert("qPeriodTo", AddMonth(PeriodTo, 1));
	ReportBuilder.Parameters.Insert("qReportPeriodFrom", BegOfDay(PeriodFrom));
	ReportBuilder.Parameters.Insert("qReportPeriodTo", EndOfDay(PeriodTo));
	ReportBuilder.Parameters.Insert("qForecastPeriodFrom", Max(BegOfDay(PeriodFrom), tcOnServer.GetForecastStartDate(Hotel)));
	ReportBuilder.Parameters.Insert("qForecastPeriodTo", EndOfDay(PeriodTo));
	ReportBuilder.Parameters.Insert("qByDocumentTimestamp", PeriodSelectionByDocumentTimestamp);
	ReportBuilder.Parameters.Insert("qEmptyDate", '00010101');
	ReportBuilder.Parameters.Insert("qCustomer", Customer);
	ReportBuilder.Parameters.Insert("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	ReportBuilder.Parameters.Insert("qIsEmptyCustomer", Not ValueIsFilled(Customer));
	ReportBuilder.Parameters.Insert("qContract", Contract);
	ReportBuilder.Parameters.Insert("qEmptyContract", Catalogs.Contracts.EmptyRef());
	ReportBuilder.Parameters.Insert("qIsEmptyContract", Not ValueIsFilled(Contract));
	ReportBuilder.Parameters.Insert("qHotelProduct", HotelProduct);
	ReportBuilder.Parameters.Insert("qIsEmptyHotelProduct", Not ValueIsFilled(HotelProduct));
	ReportBuilder.Parameters.Insert("qEmptyHotelProduct", Catalogs.HotelProducts.EmptyRef());
	ReportBuilder.Parameters.Insert("qGuestGroup", GuestGroup);
	ReportBuilder.Parameters.Insert("qIsEmptyGuestGroup", Not ValueIsFilled(GuestGroup));
	ReportBuilder.Parameters.Insert("qPaymentMethod", PaymentMethod);
	ReportBuilder.Parameters.Insert("qIsEmptyPaymentMethod", Not ValueIsFilled(PaymentMethod));
	ReportBuilder.Parameters.Insert("qEmptyPaymentMethod", Catalogs.PaymentMethods.EmptyRef());
	ReportBuilder.Parameters.Insert("qDurationCalculationRuleTypeByDays", Enums.DurationCalculationRuleTypes.ByDays);
	ReportBuilder.Parameters.Insert("qTogether", Enums.AccomodationTypes.Together);
	ReportBuilder.Parameters.Insert("qAdditionalBed", Enums.AccomodationTypes.AdditionalBed);
	ReportBuilder.Parameters.Insert("qEmptyRoom", Catalogs.Rooms.EmptyRef());
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
	ReportBuilder.Parameters.Insert("qEmptyPaymentSection", Catalogs.PaymentSections.EmptyRef());
	ReportBuilder.Parameters.Insert("qDepositTransfer", Catalogs.PaymentMethods.DepositTransfer);
	ReportBuilder.Parameters.Insert("qSplitPaymentsByColumns", SplitPaymentsByColumns);
	If PeriodSelectionByDocumentTimestamp Then
		ReportBuilder.Parameters.Insert("qPaymentPeriodFrom", PeriodFrom);
		ReportBuilder.Parameters.Insert("qPaymentPeriodTo", PeriodTo);
	Else
		ReportBuilder.Parameters.Insert("qPaymentPeriodFrom", BegOfDay(PeriodFrom));
		ReportBuilder.Parameters.Insert("qPaymentPeriodTo", EndOfDay(PeriodTo));
	EndIf;
	If IsBlankString(Hotel.AdditionalServicesFolioCondition) Then
		ReportBuilder.Parameters.Insert("qFolioFilter", "~!999999999999");
	Else
		ReportBuilder.Parameters.Insert("qFolioFilter", "%" + TrimAll(Hotel.AdditionalServicesFolioCondition) + "%");
	EndIf;
	
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
	|	HotelProductPayments.AccountingCurrency AS AccountingCurrency,
	|	HotelProductPayments.GuestGroup AS GuestGroup,
	|	HotelProductPayments.Folio.Room AS Room,
	|	HotelProductPayments.ParentDoc AS ParentDoc,
	|	HotelProductPayments.PaymentSection AS PaymentSection,
	|	CASE
	|		WHEN NOT HotelProductPayments.Folio.HotelProduct IS NULL
	|				AND HotelProductPayments.Folio.HotelProduct <> &qEmptyHotelProduct
	|			THEN HotelProductPayments.Folio.HotelProduct
	|		WHEN NOT HotelProductPayments.Folio.ParentDoc.HotelProduct IS NULL
	|				AND HotelProductPayments.Folio.ParentDoc.HotelProduct <> &qEmptyHotelProduct
	|			THEN HotelProductPayments.Folio.ParentDoc.HotelProduct
	|		WHEN NOT HotelProductPayments.ParentDoc.HotelProduct IS NULL
	|				AND HotelProductPayments.ParentDoc.HotelProduct <> &qEmptyHotelProduct
	|			THEN HotelProductPayments.ParentDoc.HotelProduct
	|		ELSE &qEmptyHotelProduct
	|	END AS HotelProduct,
	|	SUM(HotelProductPayments.Sum) AS Sum
	|INTO HotelProductPayments
	|FROM
	|	AccumulationRegister.CustomerAccounts AS HotelProductPayments
	|WHERE
	|	HotelProductPayments.RecordType = VALUE(AccumulationrecordType.Expense)
	|	AND (&qByDocumentTimestamp
	|				AND HotelProductPayments.Recorder.Date >= &qPaymentPeriodFrom
	|				AND HotelProductPayments.Recorder.Date <= &qPaymentPeriodTo
	|			OR NOT &qByDocumentTimestamp
	|				AND HotelProductPayments.Period >= &qPaymentPeriodFrom
	|				AND HotelProductPayments.Period <= &qPaymentPeriodTo)
	|	AND (HotelProductPayments.PaymentSection = &qEmptyPaymentSection
	|				AND NOT HotelProductPayments.Folio.Description LIKE &qFolioFilter
	|			OR HotelProductPayments.PaymentSection <> &qEmptyPaymentSection
	|				AND ISNULL(HotelProductPayments.PaymentSection.IsForHotelProducts, FALSE))
	|	AND HotelProductPayments.Hotel IN HIERARCHY(&qHotel)
	|	AND (HotelProductPayments.AccountingCustomer IN HIERARCHY (&qCustomer)
	|			OR &qIsEmptyCustomer)
	|	AND (HotelProductPayments.AccountingContract = &qContract
	|			OR &qIsEmptyContract)
	|	AND (HotelProductPayments.GuestGroup = &qGuestGroup
	|			OR &qIsEmptyGuestGroup)
	|	AND (HotelProductPayments.Recorder.PaymentMethod = &qPaymentMethod
	|			OR &qIsEmptyPaymentMethod)
	|	AND CASE
	|			WHEN NOT HotelProductPayments.Folio.HotelProduct IS NULL
	|					AND HotelProductPayments.Folio.HotelProduct <> &qEmptyHotelProduct
	|				THEN HotelProductPayments.Folio.HotelProduct
	|			WHEN NOT HotelProductPayments.Folio.ParentDoc.HotelProduct IS NULL
	|					AND HotelProductPayments.Folio.ParentDoc.HotelProduct <> &qEmptyHotelProduct
	|				THEN HotelProductPayments.Folio.ParentDoc.HotelProduct
	|			WHEN NOT HotelProductPayments.ParentDoc.HotelProduct IS NULL
	|					AND HotelProductPayments.ParentDoc.HotelProduct <> &qEmptyHotelProduct
	|				THEN HotelProductPayments.ParentDoc.HotelProduct
	|			ELSE &qEmptyHotelProduct
	|		END <> &qEmptyHotelProduct
	|
	|GROUP BY
	|	HotelProductPayments.AccountingCurrency,
	|	HotelProductPayments.GuestGroup,
	|	HotelProductPayments.Folio.Room,
	|	HotelProductPayments.ParentDoc,
	|	HotelProductPayments.PaymentSection,
	|	CASE
	|		WHEN NOT HotelProductPayments.Folio.HotelProduct IS NULL
	|				AND HotelProductPayments.Folio.HotelProduct <> &qEmptyHotelProduct
	|			THEN HotelProductPayments.Folio.HotelProduct
	|		WHEN NOT HotelProductPayments.Folio.ParentDoc.HotelProduct IS NULL
	|				AND HotelProductPayments.Folio.ParentDoc.HotelProduct <> &qEmptyHotelProduct
	|			THEN HotelProductPayments.Folio.ParentDoc.HotelProduct
	|		WHEN NOT HotelProductPayments.ParentDoc.HotelProduct IS NULL
	|				AND HotelProductPayments.ParentDoc.HotelProduct <> &qEmptyHotelProduct
	|			THEN HotelProductPayments.ParentDoc.HotelProduct
	|		ELSE &qEmptyHotelProduct
	|	END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PeriodSalesTurnovers.ReportingCurrency AS ReportingCurrency,
	|	PeriodSalesTurnovers.Hotel AS Hotel,
	|	PeriodSalesTurnovers.HotelProduct AS HotelProduct,
	|	SUM(PeriodSalesTurnovers.RoomRevenueTurnover) AS RoomRevenue,
	|	SUM(PeriodSalesTurnovers.RoomRevenueWithoutVATTurnover) AS RoomRevenueWithoutVAT
	|INTO PeriodSalesTurnovers
	|FROM
	|	(SELECT
	|		SalesTurnovers.ReportingCurrency AS ReportingCurrency,
	|		SalesTurnovers.Hotel AS Hotel,
	|		SalesTurnovers.HotelProduct AS HotelProduct,
	|		SalesTurnovers.RoomRevenueTurnover AS RoomRevenueTurnover,
	|		SalesTurnovers.RoomRevenueWithoutVATTurnover AS RoomRevenueWithoutVATTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qReportPeriodFrom,
	|				&qReportPeriodTo,
	|				Period,
	|				Hotel IN HIERARCHY (&qHotel)
	|					AND (Customer IN HIERARCHY (&qCustomer)
	|						OR &qIsEmptyCustomer)
	|					AND (Contract = &qContract
	|						OR &qIsEmptyContract)
	|					AND (GuestGroup = &qGuestGroup
	|						OR &qIsEmptyGuestGroup)
	|					AND (HotelProduct IN HIERARCHY (&qHotelProduct)
	|						OR &qIsEmptyHotelProduct)
	|					AND (Service IN (&qServicesList)
	|						OR NOT &qUseServicesList)) AS SalesTurnovers
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		SalesForecastTurnovers.ReportingCurrency,
	|		SalesForecastTurnovers.Hotel,
	|		SalesForecastTurnovers.HotelProduct,
	|		SalesForecastTurnovers.RoomRevenueTurnover,
	|		SalesForecastTurnovers.RoomRevenueWithoutVATTurnover
	|	FROM
	|		AccumulationRegister.SalesForecast.Turnovers(
	|				&qForecastPeriodFrom,
	|				&qForecastPeriodTo,
	|				Period,
	|				Service.IsHotelProductService
	|					AND HotelProduct <> &qEmptyHotelProduct
	|					AND Hotel IN HIERARCHY (&qHotel)
	|					AND (Customer IN HIERARCHY (&qCustomer)
	|						OR &qIsEmptyCustomer)
	|					AND (Contract = &qContract
	|						OR &qIsEmptyContract)
	|					AND (GuestGroup = &qGuestGroup
	|						OR &qIsEmptyGuestGroup)
	|					AND (HotelProduct IN HIERARCHY (&qHotelProduct)
	|						OR &qIsEmptyHotelProduct)
	|					AND (Service IN (&qServicesList)
	|						OR NOT &qUseServicesList)) AS SalesForecastTurnovers) AS PeriodSalesTurnovers
	|
	|GROUP BY
	|	PeriodSalesTurnovers.ReportingCurrency,
	|	PeriodSalesTurnovers.Hotel,
	|	PeriodSalesTurnovers.HotelProduct
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	HotelProductSales.ReportingCurrency AS ReportingCurrency,
	|	HotelProductSales.Hotel AS Hotel,
	|	HotelProductSales.HotelProduct AS HotelProduct,
	|	CASE
	|		WHEN ISNULL(HotelProductSales.HotelProduct.IsFolder, FALSE)
	|			THEN HotelProductSales.HotelProduct
	|		ELSE HotelProductSales.HotelProduct.Parent
	|	END AS HotelProductType,
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
	|	PeriodSalesTurnovers.RoomRevenue AS ThisPeriodRoomRevenue,
	|	HotelProductSales.RoomRevenue - PeriodSalesTurnovers.RoomRevenue AS OtherPeriodRoomRevenue,
	|	HotelProductSales.SalesWithoutVAT AS SalesWithoutVAT,
	|	HotelProductSales.RoomRevenueWithoutVAT AS RoomRevenueWithoutVAT,
	|	PeriodSalesTurnovers.RoomRevenueWithoutVAT AS ThisPeriodRoomRevenueWithoutVAT,
	|	HotelProductSales.RoomRevenueWithoutVAT - PeriodSalesTurnovers.RoomRevenueWithoutVAT AS OtherPeriodRoomRevenueWithoutVAT,
	|	HotelProductSales.CommissionSum AS CommissionSum,
	|	HotelProductSales.CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|	HotelProductSales.DiscountSum AS DiscountSum,
	|	HotelProductSales.DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|	HotelProductSales.RoomsRented AS RoomsRented,
	|	HotelProductSales.BedsRented AS BedsRented,
	|	HotelProductSales.AdditionalBedsRented AS AdditionalBedsRented,
	|	HotelProductSales.GuestDays AS GuestDays,
	|	HotelProductSales.GuestsCheckedIn AS GuestsCheckedIn,
	|	HotelProductSales.PaymentAmount AS PaymentAmount,
	|	HotelProductSales.PaymentAmountWithoutVAT AS PaymentAmountWithoutVAT,
	|	HotelProductSales.CashSum AS CashSum,
	|	HotelProductSales.CreditCardSum AS CreditCardSum,
	|	HotelProductSales.BankTransferSum AS BankTransferSum
	|{SELECT
	|	ReportingCurrency.*,
	|	HotelProductSales.HotelProduct.RoomQuota.* AS RoomQuota,
	|	Hotel.*,
	|	HotelProduct.*,
	|	HotelProductType.*,
	|	Agent.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	Client.*,
	|	HotelProductSales.ParentDoc.* AS ParentDoc,
	|	HotelProductSales.NumberOfPersons AS NumberOfPersons,
	|	HotelProductSales.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	HotelProductSales.PaymentSection.* AS PaymentSection,
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
	|	Count,
	|	(CASE
	|			WHEN HotelProductSales.AccommodationType.Type = &qTogether
	|				THEN 0
	|			WHEN HotelProductSales.AccommodationType.Type = &qAdditionalBed
	|				THEN 0
	|			ELSE HotelProductSales.Count
	|		END) AS FamilyCount,
	|	Sales,
	|	RoomRevenue,
	|	ThisPeriodRoomRevenue,
	|	OtherPeriodRoomRevenue,
	|	SalesWithoutVAT,
	|	RoomRevenueWithoutVAT,
	|	ThisPeriodRoomRevenueWithoutVAT,
	|	OtherPeriodRoomRevenueWithoutVAT,
	|	CommissionSum,
	|	CommissionSumWithoutVAT,
	|	DiscountSum,
	|	DiscountSumWithoutVAT,
	|	RoomsRented,
	|	BedsRented,
	|	AdditionalBedsRented,
	|	GuestDays,
	|	GuestsCheckedIn,
	|	PaymentAmount,
	|	PaymentAmountWithoutVAT,
	|	CashSum,
	|	CreditCardSum,
	|	BankTransferSum}
	|FROM
	|	(SELECT
	|		HotelProductTotalSales.ReportingCurrency AS ReportingCurrency,
	|		HotelProductTotalSales.Hotel AS Hotel,
	|		HotelProductTotalSales.HotelProduct AS HotelProduct,
	|		HotelProductTotalSales.Agent AS Agent,
	|		HotelProductTotalSales.Customer AS Customer,
	|		HotelProductTotalSales.Contract AS Contract,
	|		HotelProductTotalSales.GuestGroup AS GuestGroup,
	|		HotelProductTotalSales.Client AS Client,
	|		HotelProductTotalSales.ParentDoc AS ParentDoc,
	|		HotelProductTotalSales.NumberOfPersons AS NumberOfPersons,
	|		HotelProductTotalSales.PaymentMethod AS PlannedPaymentMethod,
	|		HotelProductTotalSales.PaymentSection AS PaymentSection,
	|		HotelProductTotalSales.Room AS Room,
	|		HotelProductTotalSales.RoomRate AS RoomRate,
	|		HotelProductTotalSales.AccommodationType AS AccommodationType,
	|		HotelProductTotalSales.ClientType AS ClientType,
	|		HotelProductTotalSales.MarketingCode AS MarketingCode,
	|		HotelProductTotalSales.SourceOfBusiness AS SourceOfBusiness,
	|		HotelProductTotalSales.TripPurpose AS TripPurpose,
	|		HotelProductTotalSales.DiscountType AS DiscountType,
	|		MIN(HotelProductTotalSales.CheckInDate) AS CheckInDate,
	|		MAX(HotelProductTotalSales.CheckOutDate) AS CheckOutDate,
	|		SUM(HotelProductTotalSales.Sales) AS Sales,
	|		SUM(HotelProductTotalSales.RoomRevenue) AS RoomRevenue,
	|		SUM(HotelProductTotalSales.SalesWithoutVAT) AS SalesWithoutVAT,
	|		SUM(HotelProductTotalSales.RoomRevenueWithoutVAT) AS RoomRevenueWithoutVAT,
	|		SUM(HotelProductTotalSales.CommissionSum) AS CommissionSum,
	|		SUM(HotelProductTotalSales.CommissionSumWithoutVAT) AS CommissionSumWithoutVAT,
	|		SUM(HotelProductTotalSales.DiscountSum) AS DiscountSum,
	|		SUM(HotelProductTotalSales.DiscountSumWithoutVAT) AS DiscountSumWithoutVAT,
	|		SUM(HotelProductTotalSales.RoomsRented) AS RoomsRented,
	|		SUM(HotelProductTotalSales.BedsRented) AS BedsRented,
	|		SUM(HotelProductTotalSales.AdditionalBedsRented) AS AdditionalBedsRented,
	|		SUM(HotelProductTotalSales.GuestDays) AS GuestDays,
	|		SUM(HotelProductTotalSales.GuestsCheckedIn) AS GuestsCheckedIn,
	|		SUM(HotelProductTotalSales.PaymentAmount) AS PaymentAmount,
	|		SUM(HotelProductTotalSales.PaymentAmountWithoutVAT) AS PaymentAmountWithoutVAT,
	|		SUM(HotelProductTotalSales.CashSum) AS CashSum,
	|		SUM(HotelProductTotalSales.CreditCardSum) AS CreditCardSum,
	|		SUM(HotelProductTotalSales.BankTransferSum) AS BankTransferSum,
	|		COUNT(DISTINCT HotelProductTotalSales.HotelProduct) AS Count
	|	FROM
	|		(SELECT
	|			HotelProductTotalSalesTurnovers.ReportingCurrency AS ReportingCurrency,
	|			HotelProductTotalSalesTurnovers.Hotel AS Hotel,
	|			HotelProductTotalSalesTurnovers.HotelProduct AS HotelProduct,
	|			HotelProductTotalSalesTurnovers.Agent AS Agent,
	|			CASE
	|				WHEN HotelProductTotalSalesTurnovers.Customer = &qEmptyCustomer
	|					THEN HotelProductTotalSalesTurnovers.Hotel.IndividualsCustomer
	|				ELSE HotelProductTotalSalesTurnovers.Customer
	|			END AS Customer,
	|			CASE
	|				WHEN HotelProductTotalSalesTurnovers.Customer = &qEmptyCustomer
	|						AND HotelProductTotalSalesTurnovers.Contract = &qEmptyContract
	|					THEN HotelProductTotalSalesTurnovers.Hotel.IndividualsContract
	|				ELSE HotelProductTotalSalesTurnovers.Contract
	|			END AS Contract,
	|			HotelProductTotalSalesTurnovers.GuestGroup AS GuestGroup,
	|			HotelProductTotalSalesTurnovers.Client AS Client,
	|			CASE
	|				WHEN NOT HotelProductTotalSalesTurnovers.Folio.HotelProduct IS NULL
	|						AND HotelProductTotalSalesTurnovers.Folio.HotelProduct <> &qEmptyHotelProduct
	|					THEN HotelProductTotalSalesTurnovers.Folio
	|				WHEN NOT HotelProductTotalSalesTurnovers.ParentDoc IS NULL
	|					THEN HotelProductTotalSalesTurnovers.ParentDoc
	|				ELSE HotelProductTotalSalesTurnovers.Folio
	|			END AS ParentDoc,
	|			HotelProductTotalSalesTurnovers.ParentDoc.NumberOfPersons AS NumberOfPersons,
	|			CASE
	|				WHEN NOT &qSplitPaymentsByColumns
	|						AND NOT &qIsEmptyPaymentMethod
	|					THEN &qPaymentMethod
	|				WHEN NOT &qSplitPaymentsByColumns
	|						AND &qIsEmptyPaymentMethod
	|					THEN HotelProductTotalSalesTurnovers.PaymentMethod
	|				ELSE &qEmptyPaymentMethod
	|			END AS PaymentMethod,
	|			HotelProductTotalSalesTurnovers.Service.PaymentSection AS PaymentSection,
	|			HotelProductTotalSalesTurnovers.Folio.Room AS Room,
	|			HotelProductTotalSalesTurnovers.ParentDoc.RoomRate AS RoomRate,
	|			HotelProductTotalSalesTurnovers.ParentDoc.AccommodationType AS AccommodationType,
	|			HotelProductTotalSalesTurnovers.ParentDoc.ClientType AS ClientType,
	|			HotelProductTotalSalesTurnovers.ParentDoc.MarketingCode AS MarketingCode,
	|			HotelProductTotalSalesTurnovers.ParentDoc.SourceOfBusiness AS SourceOfBusiness,
	|			HotelProductTotalSalesTurnovers.ParentDoc.TripPurpose AS TripPurpose,
	|			HotelProductTotalSalesTurnovers.ParentDoc.DiscountType AS DiscountType,
	|			CASE
	|				WHEN NOT HotelProductTotalSalesTurnovers.ParentDoc.CheckInDate IS NULL
	|					THEN HotelProductTotalSalesTurnovers.ParentDoc.CheckInDate
	|				WHEN NOT HotelProductTotalSalesTurnovers.Folio.DateTimeFrom IS NULL
	|					THEN HotelProductTotalSalesTurnovers.Folio.DateTimeFrom
	|				WHEN NOT HotelProductTotalSalesTurnovers.ParentDoc.DateTimeFrom IS NULL
	|					THEN HotelProductTotalSalesTurnovers.ParentDoc.DateTimeFrom
	|				ELSE &qEmptyDate
	|			END AS CheckInDate,
	|			CASE
	|				WHEN NOT HotelProductTotalSalesTurnovers.ParentDoc.CheckOutDate IS NULL
	|					THEN HotelProductTotalSalesTurnovers.ParentDoc.CheckOutDate
	|				WHEN NOT HotelProductTotalSalesTurnovers.Folio.DateTimeTo IS NULL
	|					THEN HotelProductTotalSalesTurnovers.Folio.DateTimeTo
	|				WHEN NOT HotelProductTotalSalesTurnovers.ParentDoc.DateTimeTo IS NULL
	|					THEN HotelProductTotalSalesTurnovers.ParentDoc.DateTimeTo
	|				ELSE &qEmptyDate
	|			END AS CheckOutDate,
	|			HotelProductTotalSalesTurnovers.SalesTurnover AS Sales,
	|			HotelProductTotalSalesTurnovers.RoomRevenueTurnover AS RoomRevenue,
	|			HotelProductTotalSalesTurnovers.SalesWithoutVATTurnover AS SalesWithoutVAT,
	|			HotelProductTotalSalesTurnovers.RoomRevenueWithoutVATTurnover AS RoomRevenueWithoutVAT,
	|			HotelProductTotalSalesTurnovers.CommissionSumTurnover AS CommissionSum,
	|			HotelProductTotalSalesTurnovers.CommissionSumWithoutVATTurnover AS CommissionSumWithoutVAT,
	|			HotelProductTotalSalesTurnovers.DiscountSumTurnover AS DiscountSum,
	|			HotelProductTotalSalesTurnovers.DiscountSumWithoutVATTurnover AS DiscountSumWithoutVAT,
	|			HotelProductTotalSalesTurnovers.RoomsRentedTurnover AS RoomsRented,
	|			HotelProductTotalSalesTurnovers.BedsRentedTurnover AS BedsRented,
	|			HotelProductTotalSalesTurnovers.AdditionalBedsRentedTurnover AS AdditionalBedsRented,
	|			HotelProductTotalSalesTurnovers.GuestDaysTurnover AS GuestDays,
	|			HotelProductTotalSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedIn,
	|			0 AS PaymentAmount,
	|			0 AS PaymentAmountWithoutVAT,
	|			0 AS CashSum,
	|			0 AS CreditCardSum,
	|			0 AS BankTransferSum
	|		FROM
	|			AccumulationRegister.HotelProductSales.Turnovers(
	|					&qPeriodFrom,
	|					&qPeriodTo,
	|					Period,
	|					Hotel IN HIERARCHY (&qHotel)
	|						AND (Customer IN HIERARCHY (&qCustomer)
	|							OR &qIsEmptyCustomer)
	|						AND (Contract = &qContract
	|							OR &qIsEmptyContract)
	|						AND (GuestGroup = &qGuestGroup
	|							OR &qIsEmptyGuestGroup)
	|						AND (HotelProduct IN HIERARCHY (&qHotelProduct)
	|							OR &qIsEmptyHotelProduct)
	|						AND (Service IN (&qServicesList)
	|							OR NOT &qUseServicesList)) AS HotelProductTotalSalesTurnovers
	|				INNER JOIN HotelProductPayments AS HotelProductPayments
	|				ON HotelProductTotalSalesTurnovers.GuestGroup = HotelProductPayments.GuestGroup
	|					AND HotelProductTotalSalesTurnovers.Folio.Room = HotelProductPayments.Room
	|					AND HotelProductTotalSalesTurnovers.Service.PaymentSection = HotelProductPayments.PaymentSection
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			SalesForecastTurnovers.ReportingCurrency,
	|			SalesForecastTurnovers.Hotel,
	|			SalesForecastTurnovers.HotelProduct,
	|			SalesForecastTurnovers.Agent,
	|			CASE
	|				WHEN SalesForecastTurnovers.Customer = &qEmptyCustomer
	|					THEN SalesForecastTurnovers.Hotel.IndividualsCustomer
	|				ELSE SalesForecastTurnovers.Customer
	|			END,
	|			CASE
	|				WHEN SalesForecastTurnovers.Customer = &qEmptyCustomer
	|						AND SalesForecastTurnovers.Contract = &qEmptyContract
	|					THEN SalesForecastTurnovers.Hotel.IndividualsContract
	|				ELSE SalesForecastTurnovers.Contract
	|			END,
	|			SalesForecastTurnovers.GuestGroup,
	|			SalesForecastTurnovers.Client,
	|			CASE
	|				WHEN NOT SalesForecastTurnovers.Folio.HotelProduct IS NULL
	|						AND SalesForecastTurnovers.Folio.HotelProduct <> &qEmptyHotelProduct
	|					THEN SalesForecastTurnovers.Folio
	|				WHEN NOT SalesForecastTurnovers.ParentDoc IS NULL
	|					THEN SalesForecastTurnovers.ParentDoc
	|				ELSE SalesForecastTurnovers.Folio
	|			END,
	|			SalesForecastTurnovers.ParentDoc.NumberOfPersons,
	|			CASE
	|				WHEN NOT &qSplitPaymentsByColumns
	|						AND NOT &qIsEmptyPaymentMethod
	|					THEN &qPaymentMethod
	|				WHEN NOT &qSplitPaymentsByColumns
	|						AND &qIsEmptyPaymentMethod
	|					THEN SalesForecastTurnovers.PaymentMethod
	|				ELSE &qEmptyPaymentMethod
	|			END,
	|			SalesForecastTurnovers.Service.PaymentSection,
	|			SalesForecastTurnovers.Folio.Room,
	|			SalesForecastTurnovers.ParentDoc.RoomRate,
	|			SalesForecastTurnovers.ParentDoc.AccommodationType,
	|			SalesForecastTurnovers.ParentDoc.ClientType,
	|			SalesForecastTurnovers.ParentDoc.MarketingCode,
	|			SalesForecastTurnovers.ParentDoc.SourceOfBusiness,
	|			SalesForecastTurnovers.ParentDoc.TripPurpose,
	|			SalesForecastTurnovers.ParentDoc.DiscountType,
	|			CASE
	|				WHEN NOT SalesForecastTurnovers.ParentDoc.CheckInDate IS NULL
	|					THEN SalesForecastTurnovers.ParentDoc.CheckInDate
	|				WHEN NOT SalesForecastTurnovers.Folio.DateTimeFrom IS NULL
	|					THEN SalesForecastTurnovers.Folio.DateTimeFrom
	|				WHEN NOT SalesForecastTurnovers.ParentDoc.DateTimeFrom IS NULL
	|					THEN SalesForecastTurnovers.ParentDoc.DateTimeFrom
	|				ELSE &qEmptyDate
	|			END,
	|			CASE
	|				WHEN NOT SalesForecastTurnovers.ParentDoc.CheckOutDate IS NULL
	|					THEN SalesForecastTurnovers.ParentDoc.CheckOutDate
	|				WHEN NOT SalesForecastTurnovers.Folio.DateTimeTo IS NULL
	|					THEN SalesForecastTurnovers.Folio.DateTimeTo
	|				WHEN NOT SalesForecastTurnovers.ParentDoc.DateTimeTo IS NULL
	|					THEN SalesForecastTurnovers.ParentDoc.DateTimeTo
	|				ELSE &qEmptyDate
	|			END,
	|			SalesForecastTurnovers.SalesTurnover,
	|			SalesForecastTurnovers.RoomRevenueTurnover,
	|			SalesForecastTurnovers.SalesWithoutVATTurnover,
	|			SalesForecastTurnovers.RoomRevenueWithoutVATTurnover,
	|			SalesForecastTurnovers.CommissionSumTurnover,
	|			SalesForecastTurnovers.CommissionSumWithoutVATTurnover,
	|			SalesForecastTurnovers.DiscountSumTurnover,
	|			SalesForecastTurnovers.DiscountSumWithoutVATTurnover,
	|			SalesForecastTurnovers.RoomsRentedTurnover,
	|			SalesForecastTurnovers.BedsRentedTurnover,
	|			SalesForecastTurnovers.AdditionalBedsRentedTurnover,
	|			SalesForecastTurnovers.GuestDaysTurnover,
	|			SalesForecastTurnovers.GuestsCheckedInTurnover,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0
	|		FROM
	|			AccumulationRegister.SalesForecast.Turnovers(
	|					&qPeriodFrom,
	|					&qPeriodTo,
	|					Period,
	|					Service.IsHotelProductService
	|						AND HotelProduct <> &qEmptyHotelProduct
	|						AND Hotel IN HIERARCHY (&qHotel)
	|						AND (Customer IN HIERARCHY (&qCustomer)
	|							OR &qIsEmptyCustomer)
	|						AND (Contract = &qContract
	|							OR &qIsEmptyContract)
	|						AND (GuestGroup = &qGuestGroup
	|							OR &qIsEmptyGuestGroup)
	|						AND (HotelProduct IN HIERARCHY (&qHotelProduct)
	|							OR &qIsEmptyHotelProduct)
	|						AND (Service IN (&qServicesList)
	|							OR NOT &qUseServicesList)) AS SalesForecastTurnovers
	|				INNER JOIN HotelProductPayments AS HotelProductPayments
	|				ON SalesForecastTurnovers.GuestGroup = HotelProductPayments.GuestGroup
	|					AND (SalesForecastTurnovers.Folio.Room = HotelProductPayments.Room
	|						OR SalesForecastTurnovers.ParentDoc.Number = HotelProductPayments.ParentDoc.Number
	|							AND SalesForecastTurnovers.ParentDoc.Room = &qEmptyRoom)
	|					AND SalesForecastTurnovers.Service.PaymentSection = HotelProductPayments.PaymentSection
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			GuestGroupPayments.AccountingCurrency,
	|			GuestGroupPayments.Hotel,
	|			CASE
	|				WHEN NOT GuestGroupPayments.Folio.HotelProduct IS NULL
	|						AND GuestGroupPayments.Folio.HotelProduct <> &qEmptyHotelProduct
	|					THEN GuestGroupPayments.Folio.HotelProduct
	|				WHEN NOT GuestGroupPayments.Folio.ParentDoc.HotelProduct IS NULL
	|						AND GuestGroupPayments.Folio.ParentDoc.HotelProduct <> &qEmptyHotelProduct
	|					THEN GuestGroupPayments.Folio.ParentDoc.HotelProduct
	|				ELSE GuestGroupPayments.ParentDoc.HotelProduct
	|			END,
	|			GuestGroupPayments.Folio.Agent,
	|			GuestGroupPayments.AccountingCustomer,
	|			GuestGroupPayments.AccountingContract,
	|			GuestGroupPayments.GuestGroup,
	|			CASE
	|				WHEN NOT GuestGroupPayments.Folio.HotelProduct IS NULL
	|						AND GuestGroupPayments.Folio.HotelProduct <> &qEmptyHotelProduct
	|					THEN GuestGroupPayments.Folio.Client
	|				ELSE GuestGroupPayments.Client
	|			END,
	|			CASE
	|				WHEN NOT GuestGroupPayments.Folio.HotelProduct IS NULL
	|						AND GuestGroupPayments.Folio.HotelProduct <> &qEmptyHotelProduct
	|					THEN GuestGroupPayments.Folio
	|				WHEN NOT GuestGroupPayments.Folio.ParentDoc IS NULL
	|					THEN GuestGroupPayments.Folio.ParentDoc
	|				WHEN NOT GuestGroupPayments.ParentDoc IS NULL
	|					THEN GuestGroupPayments.ParentDoc
	|				ELSE GuestGroupPayments.Folio
	|			END,
	|			CASE
	|				WHEN NOT GuestGroupPayments.Folio.ParentDoc.NumberOfPersons IS NULL
	|					THEN GuestGroupPayments.Folio.ParentDoc.NumberOfPersons
	|				ELSE GuestGroupPayments.ParentDoc.NumberOfPersons
	|			END,
	|			CASE
	|				WHEN GuestGroupPayments.Recorder.PaymentMethod = &qDepositTransfer
	|						AND NOT &qSplitPaymentsByColumns
	|					THEN GuestGroupPayments.Folio.PaymentMethod
	|				WHEN NOT &qSplitPaymentsByColumns
	|					THEN GuestGroupPayments.Recorder.PaymentMethod
	|				ELSE &qEmptyPaymentMethod
	|			END,
	|			GuestGroupPayments.PaymentSection,
	|			CASE
	|				WHEN NOT GuestGroupPayments.Folio.Room IS NULL
	|						AND GuestGroupPayments.Folio.Room <> &qEmptyRoom
	|					THEN GuestGroupPayments.Folio.Room
	|				WHEN GuestGroupPayments.Room <> &qEmptyRoom
	|					THEN GuestGroupPayments.Room
	|				ELSE GuestGroupPayments.ParentDoc.Room
	|			END,
	|			CASE
	|				WHEN NOT GuestGroupPayments.Folio.ParentDoc.RoomRate IS NULL
	|					THEN GuestGroupPayments.Folio.ParentDoc.RoomRate
	|				ELSE GuestGroupPayments.ParentDoc.RoomRate
	|			END,
	|			CASE
	|				WHEN NOT GuestGroupPayments.Folio.ParentDoc.AccommodationType IS NULL
	|					THEN GuestGroupPayments.Folio.ParentDoc.AccommodationType
	|				ELSE GuestGroupPayments.ParentDoc.AccommodationType
	|			END,
	|			CASE
	|				WHEN NOT GuestGroupPayments.Folio.ParentDoc.ClientType IS NULL
	|					THEN GuestGroupPayments.Folio.ParentDoc.ClientType
	|				ELSE GuestGroupPayments.ParentDoc.ClientType
	|			END,
	|			CASE
	|				WHEN NOT GuestGroupPayments.Folio.ParentDoc.MarketingCode IS NULL
	|					THEN GuestGroupPayments.Folio.ParentDoc.MarketingCode
	|				ELSE GuestGroupPayments.ParentDoc.MarketingCode
	|			END,
	|			CASE
	|				WHEN NOT GuestGroupPayments.Folio.ParentDoc.SourceOfBusiness IS NULL
	|					THEN GuestGroupPayments.Folio.ParentDoc.SourceOfBusiness
	|				ELSE GuestGroupPayments.ParentDoc.SourceOfBusiness
	|			END,
	|			CASE
	|				WHEN NOT GuestGroupPayments.Folio.ParentDoc.TripPurpose IS NULL
	|					THEN GuestGroupPayments.Folio.ParentDoc.TripPurpose
	|				ELSE GuestGroupPayments.ParentDoc.TripPurpose
	|			END,
	|			CASE
	|				WHEN NOT GuestGroupPayments.Folio.ParentDoc.DiscountType IS NULL
	|					THEN GuestGroupPayments.Folio.ParentDoc.DiscountType
	|				ELSE GuestGroupPayments.ParentDoc.DiscountType
	|			END,
	|			CASE
	|				WHEN NOT GuestGroupPayments.Folio.ParentDoc.CheckInDate IS NULL
	|					THEN GuestGroupPayments.Folio.ParentDoc.CheckInDate
	|				WHEN NOT GuestGroupPayments.ParentDoc.CheckInDate IS NULL
	|					THEN GuestGroupPayments.ParentDoc.CheckInDate
	|				WHEN NOT GuestGroupPayments.Folio.DateTimeFrom IS NULL
	|					THEN GuestGroupPayments.Folio.DateTimeFrom
	|				WHEN NOT GuestGroupPayments.ParentDoc.DateTimeFrom IS NULL
	|					THEN GuestGroupPayments.ParentDoc.DateTimeFrom
	|				ELSE &qEmptyDate
	|			END,
	|			CASE
	|				WHEN NOT GuestGroupPayments.Folio.ParentDoc.CheckOutDate IS NULL
	|					THEN GuestGroupPayments.Folio.ParentDoc.CheckOutDate
	|				WHEN NOT GuestGroupPayments.ParentDoc.CheckOutDate IS NULL
	|					THEN GuestGroupPayments.ParentDoc.CheckOutDate
	|				WHEN NOT GuestGroupPayments.Folio.DateTimeTo IS NULL
	|					THEN GuestGroupPayments.Folio.DateTimeTo
	|				WHEN NOT GuestGroupPayments.ParentDoc.DateTimeTo IS NULL
	|					THEN GuestGroupPayments.ParentDoc.DateTimeTo
	|				ELSE &qEmptyDate
	|			END,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			GuestGroupPayments.Sum,
	|			GuestGroupPayments.Sum - GuestGroupPayments.VATSum,
	|			CASE
	|				WHEN GuestGroupPayments.Recorder.PaymentMethod.IsByCash
	|					THEN GuestGroupPayments.Sum
	|				ELSE 0
	|			END,
	|			CASE
	|				WHEN GuestGroupPayments.Recorder.PaymentMethod.IsByCreditCard
	|					THEN GuestGroupPayments.Sum
	|				ELSE 0
	|			END,
	|			CASE
	|				WHEN GuestGroupPayments.Recorder.PaymentMethod.IsByBankTransfer
	|					THEN GuestGroupPayments.Sum
	|				ELSE 0
	|			END
	|		FROM
	|			AccumulationRegister.CustomerAccounts AS GuestGroupPayments
	|		WHERE
	|			GuestGroupPayments.RecordType = VALUE(AccumulationrecordType.Expense)
	|			AND (&qByDocumentTimestamp
	|						AND GuestGroupPayments.Recorder.Date >= &qPaymentPeriodFrom
	|						AND GuestGroupPayments.Recorder.Date <= &qPaymentPeriodTo
	|					OR NOT &qByDocumentTimestamp
	|						AND GuestGroupPayments.Period >= &qPaymentPeriodFrom
	|						AND GuestGroupPayments.Period <= &qPaymentPeriodTo)
	|			AND (GuestGroupPayments.PaymentSection = &qEmptyPaymentSection
	|						AND NOT GuestGroupPayments.Folio.Description LIKE &qFolioFilter
	|					OR GuestGroupPayments.PaymentSection <> &qEmptyPaymentSection
	|						AND ISNULL(GuestGroupPayments.PaymentSection.IsForHotelProducts, FALSE))
	|			AND GuestGroupPayments.Hotel IN HIERARCHY(&qHotel)
	|			AND (GuestGroupPayments.AccountingCustomer IN HIERARCHY (&qCustomer)
	|					OR &qIsEmptyCustomer)
	|			AND (GuestGroupPayments.AccountingContract = &qContract
	|					OR &qIsEmptyContract)
	|			AND (GuestGroupPayments.GuestGroup = &qGuestGroup
	|					OR &qIsEmptyGuestGroup)
	|			AND (GuestGroupPayments.Recorder.PaymentMethod = &qPaymentMethod
	|					OR &qIsEmptyPaymentMethod)
	|			AND CASE
	|					WHEN NOT GuestGroupPayments.Folio.HotelProduct IS NULL
	|							AND GuestGroupPayments.Folio.HotelProduct <> &qEmptyHotelProduct
	|						THEN GuestGroupPayments.Folio.HotelProduct
	|					WHEN NOT GuestGroupPayments.Folio.ParentDoc.HotelProduct IS NULL
	|							AND GuestGroupPayments.Folio.ParentDoc.HotelProduct <> &qEmptyHotelProduct
	|						THEN GuestGroupPayments.Folio.ParentDoc.HotelProduct
	|					ELSE GuestGroupPayments.ParentDoc.HotelProduct
	|				END IN
	|					(SELECT
	|						HotelProductPayments.HotelProduct
	|					FROM
	|						HotelProductPayments AS HotelProductPayments)) AS HotelProductTotalSales
	|	
	|	GROUP BY
	|		HotelProductTotalSales.ReportingCurrency,
	|		HotelProductTotalSales.Hotel,
	|		HotelProductTotalSales.HotelProduct,
	|		HotelProductTotalSales.Agent,
	|		HotelProductTotalSales.Customer,
	|		HotelProductTotalSales.Contract,
	|		HotelProductTotalSales.GuestGroup,
	|		HotelProductTotalSales.Client,
	|		HotelProductTotalSales.ParentDoc,
	|		HotelProductTotalSales.NumberOfPersons,
	|		HotelProductTotalSales.PaymentMethod,
	|		HotelProductTotalSales.PaymentSection,
	|		HotelProductTotalSales.Room,
	|		HotelProductTotalSales.RoomRate,
	|		HotelProductTotalSales.AccommodationType,
	|		HotelProductTotalSales.ClientType,
	|		HotelProductTotalSales.MarketingCode,
	|		HotelProductTotalSales.SourceOfBusiness,
	|		HotelProductTotalSales.TripPurpose,
	|		HotelProductTotalSales.DiscountType) AS HotelProductSales
	|		LEFT JOIN PeriodSalesTurnovers AS PeriodSalesTurnovers
	|		ON HotelProductSales.HotelProduct = PeriodSalesTurnovers.HotelProduct
	|			AND HotelProductSales.ReportingCurrency = PeriodSalesTurnovers.ReportingCurrency
	|			AND HotelProductSales.Hotel = PeriodSalesTurnovers.Hotel
	|{WHERE
	|	HotelProductSales.ReportingCurrency.*,
	|	HotelProductSales.HotelProduct.RoomQuota.* AS RoomQuota,
	|	HotelProductSales.Hotel.* AS Hotel,
	|	HotelProductSales.HotelProduct.RoomType.* AS RoomType,
	|	HotelProductSales.HotelProduct.* AS HotelProduct,
	|	(CASE
	|			WHEN ISNULL(HotelProductSales.HotelProduct.IsFolder, FALSE)
	|				THEN HotelProductSales.HotelProduct
	|			ELSE HotelProductSales.HotelProduct.Parent
	|		END) AS HotelProductType,
	|	HotelProductSales.Agent.* AS Agent,
	|	HotelProductSales.Customer.* AS Customer,
	|	HotelProductSales.Contract.* AS Contract,
	|	HotelProductSales.GuestGroup.* AS GuestGroup,
	|	HotelProductSales.Client.* AS Client,
	|	HotelProductSales.ParentDoc.* AS ParentDoc,
	|	HotelProductSales.NumberOfPersons AS NumberOfPersons,
	|	HotelProductSales.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	HotelProductSales.PaymentSection.* AS PaymentSection,
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
	|	HotelProductSales.Count,
	|	(CASE
	|			WHEN HotelProductSales.AccommodationType.Type = &qTogether
	|				THEN 0
	|			WHEN HotelProductSales.AccommodationType.Type = &qAdditionalBed
	|				THEN 0
	|			ELSE HotelProductSales.Count
	|		END) AS FamilyCount,
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
	|	HotelProductSales.PaymentAmount,
	|	HotelProductSales.PaymentAmountWithoutVAT,
	|	HotelProductSales.CashSum,
	|	HotelProductSales.CreditCardSum,
	|	HotelProductSales.BankTransferSum}
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
	|	HotelProductType.*,
	|	Agent.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	Client.*,
	|	HotelProductSales.ParentDoc.* AS ParentDoc,
	|	HotelProductSales.NumberOfPersons AS NumberOfPersons,
	|	HotelProductSales.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	HotelProductSales.PaymentSection.* AS PaymentSection,
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
	|	Count,
	|	(CASE
	|			WHEN HotelProductSales.AccommodationType.Type = &qTogether
	|				THEN 0
	|			WHEN HotelProductSales.AccommodationType.Type = &qAdditionalBed
	|				THEN 0
	|			ELSE HotelProductSales.Count
	|		END) AS FamilyCount,
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
	|	PaymentAmount,
	|	PaymentAmountWithoutVAT,
	|	CashSum,
	|	CreditCardSum,
	|	BankTransferSum}
	|TOTALS
	|	SUM(Count),
	|	SUM(FamilyCount),
	|	SUM(Sales),
	|	SUM(RoomRevenue),
	|	SUM(ThisPeriodRoomRevenue),
	|	SUM(OtherPeriodRoomRevenue),
	|	SUM(SalesWithoutVAT),
	|	SUM(RoomRevenueWithoutVAT),
	|	SUM(ThisPeriodRoomRevenueWithoutVAT),
	|	SUM(OtherPeriodRoomRevenueWithoutVAT),
	|	SUM(CommissionSum),
	|	SUM(CommissionSumWithoutVAT),
	|	SUM(DiscountSum),
	|	SUM(DiscountSumWithoutVAT),
	|	SUM(RoomsRented),
	|	SUM(BedsRented),
	|	SUM(AdditionalBedsRented),
	|	SUM(GuestDays),
	|	SUM(GuestsCheckedIn),
	|	SUM(PaymentAmount),
	|	SUM(PaymentAmountWithoutVAT),
	|	SUM(CashSum),
	|	SUM(CreditCardSum),
	|	SUM(BankTransferSum)
	|BY
	|	OVERALL,
	|	ReportingCurrency,
	|	Customer HIERARCHY
	|{TOTALS BY
	|	ReportingCurrency.*,
	|	HotelProductSales.HotelProduct.RoomQuota.* AS RoomQuota,
	|	Hotel.*,
	|	HotelProduct.*,
	|	HotelProductType.*,
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
	|	HotelProductSales.ParentDoc.* AS ParentDoc,
	|	HotelProductSales.NumberOfPersons AS NumberOfPersons,
	|	HotelProductSales.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	HotelProductSales.PaymentSection.* AS PaymentSection,
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
	ReportBuilder.HeaderText = NStr("ru='Платежи по путевкам';de='Zahlungen im Reisechecks';en='Payments by vauchers'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
Function pmIsResource(pName) Export
	If pName = "Sales" 
	   Or pName = "RoomRevenue" 
	   Or pName = "ThisPeriodRoomRevenue" 
	   Or pName = "OtherPeriodRoomRevenue" 
	   Or pName = "SalesWithoutVAT" 
	   Or pName = "RoomRevenueWithoutVAT" 
	   Or pName = "ThisPeriodRoomRevenueWithoutVAT" 
	   Or pName = "OtherPeriodRoomRevenueWithoutVAT" 
	   Or pName = "CommissionSum" 
	   Or pName = "CommissionSumWithoutVAT" 
	   Or pName = "DiscountSum" 
	   Or pName = "DiscountSumWithoutVAT" 
	   Or pName = "RoomsRented" 
	   Or pName = "BedsRented" 
	   Or pName = "AdditionalBedsRented" 
	   Or pName = "Count" 
	   Or pName = "FamilyCount" 
	   Or pName = "GuestDays" 
	   Or pName = "GuestsCheckedIn" 
	   Or pName = "PaymentAmount"
	   Or pName = "PaymentAmountWithoutVAT" 
	   Or pName = "CashSum" 
	   Or pName = "CreditCardSum" 
	   Or pName = "BankTransferSum" Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // pmIsResource

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
