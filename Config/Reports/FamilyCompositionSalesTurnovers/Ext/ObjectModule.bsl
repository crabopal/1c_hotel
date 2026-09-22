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
	If ValueIsFilled(GuestGroup) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Группа гостей '; en = 'Guest group '; de = 'Gastgruppe '") + 
							 TrimAll(TrimAll(GuestGroup.Code) + " " + TrimAll(GuestGroup.Description)) + 
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
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	vForecastStartDate = tcOnServer.GetForecastStartDate(Hotel);
	ReportBuilder.Parameters.Insert("qForecastPeriodFrom", Max(BegOfDay(PeriodFrom), vForecastStartDate));
	ReportBuilder.Parameters.Insert("qForecastPeriodTo", ?(ValueIsFilled(PeriodTo), Max(PeriodTo, EndOfDay(vForecastStartDate-24*3600)), '00010101'));
	ReportBuilder.Parameters.Insert("qCustomer", Customer);
	ReportBuilder.Parameters.Insert("qIsEmptyCustomer", Not ValueIsFilled(Customer));
	ReportBuilder.Parameters.Insert("qContract", Contract);
	ReportBuilder.Parameters.Insert("qIsEmptyContract", Not ValueIsFilled(Contract));
	ReportBuilder.Parameters.Insert("qGuestGroup", GuestGroup);
	ReportBuilder.Parameters.Insert("qIsEmptyGuestGroup", Not ValueIsFilled(GuestGroup));
	ReportBuilder.Parameters.Insert("qExtraTemplate", "extra");
	ReportBuilder.Parameters.Insert("qEmptyRoom", Catalogs.Rooms.EmptyRef());
	ReportBuilder.Parameters.Insert("qEmptyHotel", Catalogs.Hotels.EmptyRef());
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
	|	SalesByFamily.Hotel AS Hotel,
	|	SalesByFamily.GuestGroup AS GuestGroup,
	|	SalesByFamily.FamilyRoom AS FamilyRoom,
	|	SalesByFamily.FamilyCheckInDate AS FamilyCheckInDate,
	|	SalesByFamily.ParentDoc AS ParentDoc,
	|	ISNULL(SalesByFamily.FamilyAccommodationType.SortCode, 0) AS FamilyAccommodationTypeSortCode
	|INTO RawSales
	|FROM
	|	(SELECT
	|		SalesTurnovers.Hotel AS Hotel,
	|		SalesTurnovers.GuestGroup AS GuestGroup,
	|		SalesTurnovers.ParentDoc.Number AS FamilyRoom,
	|		SalesTurnovers.ParentDoc AS ParentDoc,
	|		BEGINOFPERIOD(SalesTurnovers.ParentDoc.CheckInDate, DAY) AS FamilyCheckInDate,
	|		SalesTurnovers.ParentDoc.AccommodationType AS FamilyAccommodationType
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection
	|					AND Hotel IN HIERARCHY (&qHotel)
	|					AND (Customer IN HIERARCHY (&qCustomer)
	|						OR &qIsEmptyCustomer)
	|					AND (Contract = &qContract
	|						OR &qIsEmptyContract)
	|					AND (GuestGroup = &qGuestGroup
	|						OR &qIsEmptyGuestGroup)
	|					AND Service.IsRoomRevenue) AS SalesTurnovers
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		SalesForecastTurnovers.Hotel,
	|		SalesForecastTurnovers.GuestGroup,
	|		SalesForecastTurnovers.ParentDoc.Number,
	|		SalesForecastTurnovers.ParentDoc,
	|		BEGINOFPERIOD(SalesForecastTurnovers.ParentDoc.CheckInDate, DAY),
	|		SalesForecastTurnovers.ParentDoc.AccommodationType
	|	FROM
	|		AccumulationRegister.SalesForecast.Turnovers(
	|				&qForecastPeriodFrom,
	|				&qForecastPeriodTo,
	|				Period,
	|				Hotel IN HIERARCHY (&qHotel)
	|					AND (Customer IN HIERARCHY (&qCustomer)
	|						OR &qIsEmptyCustomer)
	|					AND (Contract = &qContract
	|						OR &qIsEmptyContract)
	|					AND (GuestGroup = &qGuestGroup
	|						OR &qIsEmptyGuestGroup)
	|					AND Service.IsRoomRevenue) AS SalesForecastTurnovers) AS SalesByFamily
	|
	|GROUP BY
	|	SalesByFamily.Hotel,
	|	SalesByFamily.GuestGroup,
	|	SalesByFamily.FamilyRoom,
	|	SalesByFamily.FamilyCheckInDate,
	|	SalesByFamily.ParentDoc,
	|	ISNULL(SalesByFamily.FamilyAccommodationType.SortCode, 0)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	HashCodes.Hotel AS Hotel,
	|	HashCodes.GuestGroup AS GuestGroup,
	|	HashCodes.FamilyRoom AS FamilyRoom,
	|	HashCodes.FamilyCheckInDate AS FamilyCheckInDate,
	|	SUM(HashCodes.FamilyAccommodationTypeSortCode) * AVG(HashCodes.FamilyAccommodationTypeSortCode) * MAX(HashCodes.FamilyAccommodationTypeSortCode) * MIN(HashCodes.FamilyAccommodationTypeSortCode) AS HashCode
	|INTO HashCodes
	|FROM
	|	RawSales AS HashCodes
	|
	|GROUP BY
	|	HashCodes.Hotel,
	|	HashCodes.GuestGroup,
	|	HashCodes.FamilyRoom,
	|	HashCodes.FamilyCheckInDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccTemplates.Ref AS AccommodationTemplate,
	|	SUM(AccTemplates.AccommodationType.SortCode) * AVG(AccTemplates.AccommodationType.SortCode) * MAX(AccTemplates.AccommodationType.SortCode) * MIN(AccTemplates.AccommodationType.SortCode) AS HashCode
	|INTO AccTemplates
	|FROM
	|	Catalog.AccommodationTemplates.AccommodationTypes AS AccTemplates
	|WHERE
	|	NOT AccTemplates.Ref.DeletionMark
	|	AND (AccTemplates.Ref.Hotel = &qHotel
	|			OR AccTemplates.Ref.Hotel = &qEmptyHotel)
	|	AND (CAST(AccTemplates.Ref.Remarks AS STRING(100))) <> &qExtraTemplate
	|
	|GROUP BY
	|	AccTemplates.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RawSales.Hotel AS Hotel,
	|	RawSales.GuestGroup AS GuestGroup,
	|	RawSales.FamilyRoom AS FamilyRoom,
	|	RawSales.FamilyCheckInDate AS FamilyCheckInDate,
	|	RawSales.ParentDoc AS ParentDoc,
	|	ISNULL(HashCodes.HashCode, 0) AS HashCode
	|INTO SalesWithAccTemplateHashCodes
	|FROM
	|	RawSales AS RawSales
	|		LEFT JOIN HashCodes AS HashCodes
	|		ON RawSales.Hotel = HashCodes.Hotel
	|			AND RawSales.GuestGroup = HashCodes.GuestGroup
	|			AND RawSales.FamilyRoom = HashCodes.FamilyRoom
	|			AND RawSales.FamilyCheckInDate = HashCodes.FamilyCheckInDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP RawSales
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP HashCodes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SalesWithAccTemplateHashCodes.Hotel AS Hotel,
	|	SalesWithAccTemplateHashCodes.GuestGroup AS GuestGroup,
	|	SalesWithAccTemplateHashCodes.FamilyRoom AS FamilyRoom,
	|	SalesWithAccTemplateHashCodes.FamilyCheckInDate AS FamilyCheckInDate,
	|	SalesWithAccTemplateHashCodes.ParentDoc AS ParentDoc,
	|	AccTemplates.AccommodationTemplate AS AccommodationTemplate
	|INTO AccTemplatesByParentDoc
	|FROM
	|	SalesWithAccTemplateHashCodes AS SalesWithAccTemplateHashCodes
	|		LEFT JOIN AccTemplates AS AccTemplates
	|		ON SalesWithAccTemplateHashCodes.HashCode = AccTemplates.HashCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP SalesWithAccTemplateHashCodes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CustomerTotals.Hotel AS Hotel,
	|	SUM(CustomerTotals.TotalSales) AS TotalSales,
	|	SUM(CustomerTotals.TotalRoomsRented) AS TotalRoomsRented,
	|	SUM(CustomerTotals.TotalBedsRented) AS TotalBedsRented,
	|	SUM(CustomerTotals.TotalRoomRevenue) AS TotalRoomRevenue
	|INTO CustomerTotals
	|FROM
	|	(SELECT
	|		SalesTurnovers.Hotel AS Hotel,
	|		SalesTurnovers.SalesTurnover AS TotalSales,
	|		SalesTurnovers.RoomsRentedTurnover AS TotalRoomsRented,
	|		SalesTurnovers.BedsRentedTurnover AS TotalBedsRented,
	|		SalesTurnovers.RoomRevenueTurnover AS TotalRoomRevenue
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				NOT IsCorrection
	|					AND Hotel IN HIERARCHY (&qHotel)
	|					AND (Service IN (&qServicesList)
	|						OR NOT &qUseServicesList)) AS SalesTurnovers
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		SalesForecastTurnovers.Hotel,
	|		SalesForecastTurnovers.SalesTurnover,
	|		SalesForecastTurnovers.RoomsRentedTurnover,
	|		SalesForecastTurnovers.BedsRentedTurnover,
	|		SalesForecastTurnovers.RoomRevenueTurnover
	|	FROM
	|		AccumulationRegister.SalesForecast.Turnovers(
	|				&qForecastPeriodFrom,
	|				&qForecastPeriodTo,
	|				Period,
	|				Hotel IN HIERARCHY (&qHotel)
	|					AND (Service IN (&qServicesList)
	|						OR NOT &qUseServicesList)) AS SalesForecastTurnovers) AS CustomerTotals
	|
	|GROUP BY
	|	CustomerTotals.Hotel
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CustomerSales.AccommodationTemplate AS AccommodationTemplate,
	|	CustomerSales.Hotel AS Hotel,
	|	CustomerSales.Company AS Company,
	|	CustomerSales.ReportingCurrency AS ReportingCurrency,
	|	CustomerSales.Agent AS Agent,
	|	CustomerSales.Customer AS Customer,
	|	CustomerSales.Contract AS Contract,
	|	CustomerSales.GuestGroup AS GuestGroup,
	|	CustomerSales.RoomRate AS RoomRate,
	|	CustomerSales.AccountingDate AS AccountingDate,
	|	CustomerSales.ParentDoc AS ParentDoc,
	|	CustomerSales.Service AS Service,
	|	CustomerSales.Sales AS Sales,
	|	CustomerSales.RoomRevenue AS RoomRevenue,
	|	CustomerSales.ExtraBedRevenue AS ExtraBedRevenue,
	|	CustomerSales.RoomRevenue - CustomerSales.ExtraBedRevenue AS MainBedsRevenue,
	|	CustomerSales.SalesWithoutVAT AS SalesWithoutVAT,
	|	CustomerSales.RoomRevenueWithoutVAT AS RoomRevenueWithoutVAT,
	|	CustomerSales.ExtraBedRevenueWithoutVAT AS ExtraBedRevenueWithoutVAT,
	|	CustomerSales.RoomRevenueWithoutVAT - CustomerSales.ExtraBedRevenueWithoutVAT AS MainBedsRevenueWithoutVAT,
	|	CustomerSales.CommissionSum AS CommissionSum,
	|	CustomerSales.CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|	CustomerSales.DiscountSum AS DiscountSum,
	|	CustomerSales.DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|	CustomerSales.RoomsRented AS RoomsRented,
	|	CustomerSales.BedsRented AS BedsRented,
	|	CustomerSales.AdditionalBedsRented AS AdditionalBedsRented,
	|	CustomerSales.GuestDays AS GuestDays,
	|	CustomerSales.GuestsCheckedIn AS GuestsCheckedIn,
	|	CustomerSales.RoomsCheckedIn AS RoomsCheckedIn,
	|	CustomerSales.BedsCheckedIn AS BedsCheckedIn,
	|	CustomerSales.AdditionalBedsCheckedIn AS AdditionalBedsCheckedIn,
	|	CASE
	|		WHEN CustomerSales.RoomsCheckedIn <> 0
	|			THEN CAST(CustomerSales.BookingWindow / CustomerSales.RoomsCheckedIn AS NUMBER(10, 0))
	|		ELSE 0
	|	END AS BookingWindow,
	|	CustomerSales.Quantity AS Quantity,
	|	CustomerSales.TotalSales AS TotalSales,
	|	CustomerSales.TotalRoomRevenue AS TotalRoomRevenue,
	|	CustomerSales.TotalRoomsRented AS TotalRoomsRented,
	|	CustomerSales.TotalBedsRented AS TotalBedsRented,
	|	CustomerSales.TotalSalesPercent AS TotalSalesPercent,
	|	CustomerSales.TotalRoomRevenuePercent AS TotalRoomRevenuePercent,
	|	CustomerSales.TotalRoomsRentedPercent AS TotalRoomsRentedPercent,
	|	CustomerSales.TotalBedsRentedPercent AS TotalBedsRentedPercent,
	|	CustomerSales.ADR AS ADR,
	|	CustomerSales.ADBR AS ADBR,
	|	CustomerSales.ADRWithoutVAT AS ADRWithoutVAT,
	|	CustomerSales.ADBRWithoutVAT AS ADBRWithoutVAT,
	|	CustomerSales.RevPAC AS RevPAC,
	|	CustomerSales.RevPACWithoutVAT AS RevPACWithoutVAT,
	|	CustomerSales.ALS AS ALS
	|{SELECT
	|	AccommodationTemplate.*,
	|	Hotel.*,
	|	Company.*,
	|	ReportingCurrency.*,
	|	Agent.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	CustomerSales.Client.*,
	|	RoomRate.*,
	|	Service.*,
	|	ParentDoc.*,
	|	CustomerSales.PaymentMethod.*,
	|	CustomerSales.ClientType.*,
	|	CustomerSales.Folio.*,
	|	CustomerSales.Room.*,
	|	CustomerSales.RoomType.*,
	|	CustomerSales.AccommodationType.*,
	|	CustomerSales.TripPurpose.*,
	|	CustomerSales.MarketingCode.*,
	|	CustomerSales.SourceOfBusiness.*,
	|	CustomerSales.Resource.*,
	|	CustomerSales.ResourceType.*,
	|	CustomerSales.Author.*,
	|	CustomerSales.Discount,
	|	CustomerSales.DiscountType.*,
	|	CustomerSales.DiscountCard.*,
	|	CustomerSales.AgentCommissionType,
	|	CustomerSales.AgentCommission,
	|	CustomerSales.VATRate.*,
	|	CustomerSales.Price AS Price,
	|	CustomerSales.HotelProduct.* AS HotelProduct,
	|	Sales,
	|	RoomRevenue,
	|	ExtraBedRevenue,
	|	MainBedsRevenue,
	|	SalesWithoutVAT,
	|	RoomRevenueWithoutVAT,
	|	ExtraBedRevenueWithoutVAT,
	|	MainBedsRevenueWithoutVAT,
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
	|	AdditionalBedsCheckedIn,
	|	BookingWindow,
	|	Quantity,
	|	AccountingDate,
	|	(WEEK(CustomerSales.AccountingDate)) AS AccountingWeek,
	|	(MONTH(CustomerSales.AccountingDate)) AS AccountingMonth,
	|	(QUARTER(CustomerSales.AccountingDate)) AS AccountingQuarter,
	|	(YEAR(CustomerSales.AccountingDate)) AS AccountingYear,
	|	TotalSales,
	|	TotalRoomRevenue,
	|	TotalRoomsRented,
	|	TotalBedsRented,
	|	TotalSalesPercent,
	|	TotalRoomRevenuePercent,
	|	TotalRoomsRentedPercent,
	|	TotalBedsRentedPercent,
	|	ADR,
	|	ADBR,
	|	ADRWithoutVAT,
	|	ADBRWithoutVAT,
	|	RevPAC,
	|	RevPACWithoutVAT,
	|	ALS}
	|FROM
	|	(SELECT
	|		AccTemplatesByParentDoc.AccommodationTemplate AS AccommodationTemplate,
	|		CustomerSalesFull.Hotel AS Hotel,
	|		CustomerSalesFull.Company AS Company,
	|		CustomerSalesFull.ReportingCurrency AS ReportingCurrency,
	|		CustomerSalesFull.Agent AS Agent,
	|		CustomerSalesFull.Customer AS Customer,
	|		CustomerSalesFull.Contract AS Contract,
	|		CustomerSalesFull.GuestGroup AS GuestGroup,
	|		CustomerSalesFull.AccountingDate AS AccountingDate,
	|		CustomerSalesFull.Client AS Client,
	|		CustomerSalesFull.ParentDoc AS ParentDoc,
	|		CustomerSalesFull.Service AS Service,
	|		CustomerSalesFull.PaymentMethod AS PaymentMethod,
	|		CustomerSalesFull.ClientType AS ClientType,
	|		CustomerSalesFull.Folio AS Folio,
	|		CustomerSalesFull.RoomRate AS RoomRate,
	|		CustomerSalesFull.Room AS Room,
	|		CustomerSalesFull.RoomType AS RoomType,
	|		CustomerSalesFull.AccommodationType AS AccommodationType,
	|		CustomerSalesFull.TripPurpose AS TripPurpose,
	|		CustomerSalesFull.MarketingCode AS MarketingCode,
	|		CustomerSalesFull.SourceOfBusiness AS SourceOfBusiness,
	|		CustomerSalesFull.Resource AS Resource,
	|		CustomerSalesFull.ResourceType AS ResourceType,
	|		CustomerSalesFull.Author AS Author,
	|		CustomerSalesFull.Discount AS Discount,
	|		CustomerSalesFull.DiscountType AS DiscountType,
	|		CustomerSalesFull.DiscountCard AS DiscountCard,
	|		CustomerSalesFull.AgentCommissionType AS AgentCommissionType,
	|		CustomerSalesFull.AgentCommission AS AgentCommission,
	|		CustomerSalesFull.VATRate AS VATRate,
	|		CustomerSalesFull.Price AS Price,
	|		CustomerSalesFull.HotelProduct AS HotelProduct,
	|		CustomerSalesFull.SalesTurnover AS Sales,
	|		CustomerSalesFull.RoomRevenueTurnover AS RoomRevenue,
	|		CustomerSalesFull.ExtraBedRevenueTurnover AS ExtraBedRevenue,
	|		CustomerSalesFull.SalesWithoutVATTurnover AS SalesWithoutVAT,
	|		CustomerSalesFull.RoomRevenueWithoutVATTurnover AS RoomRevenueWithoutVAT,
	|		CustomerSalesFull.ExtraBedRevenueWithoutVATTurnover AS ExtraBedRevenueWithoutVAT,
	|		CustomerSalesFull.CommissionSumTurnover AS CommissionSum,
	|		CustomerSalesFull.CommissionSumWithoutVATTurnover AS CommissionSumWithoutVAT,
	|		CustomerSalesFull.DiscountSumTurnover AS DiscountSum,
	|		CustomerSalesFull.DiscountSumWithoutVATTurnover AS DiscountSumWithoutVAT,
	|		CustomerSalesFull.RoomsRentedTurnover AS RoomsRented,
	|		CustomerSalesFull.BedsRentedTurnover AS BedsRented,
	|		CustomerSalesFull.AdditionalBedsRentedTurnover AS AdditionalBedsRented,
	|		CustomerSalesFull.GuestDaysTurnover AS GuestDays,
	|		CustomerSalesFull.GuestsCheckedInTurnover AS GuestsCheckedIn,
	|		CustomerSalesFull.RoomsCheckedInTurnover AS RoomsCheckedIn,
	|		CustomerSalesFull.BedsCheckedInTurnover AS BedsCheckedIn,
	|		CustomerSalesFull.AdditionalBedsCheckedInTurnover AS AdditionalBedsCheckedIn,
	|		CustomerSalesFull.BookingWindowTurnover AS BookingWindow,
	|		CustomerSalesFull.QuantityTurnover AS Quantity,
	|		CustomerTotalSales.TotalSales AS TotalSales,
	|		CustomerTotalSales.TotalRoomRevenue AS TotalRoomRevenue,
	|		CustomerTotalSales.TotalRoomsRented AS TotalRoomsRented,
	|		CustomerTotalSales.TotalBedsRented AS TotalBedsRented,
	|		CASE
	|			WHEN CustomerTotalSales.TotalSales = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.SalesTurnover * 100 / CustomerTotalSales.TotalSales
	|		END AS TotalSalesPercent,
	|		CASE
	|			WHEN CustomerTotalSales.TotalRoomRevenue = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.RoomRevenueTurnover * 100 / CustomerTotalSales.TotalRoomRevenue
	|		END AS TotalRoomRevenuePercent,
	|		CASE
	|			WHEN CustomerTotalSales.TotalRoomsRented = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.RoomsRentedTurnover * 100 / CustomerTotalSales.TotalRoomsRented
	|		END AS TotalRoomsRentedPercent,
	|		CASE
	|			WHEN CustomerTotalSales.TotalBedsRented = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.BedsRentedTurnover * 100 / CustomerTotalSales.TotalBedsRented
	|		END AS TotalBedsRentedPercent,
	|		CASE
	|			WHEN CustomerSalesFull.RoomsRentedTurnover = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.RoomRevenueTurnover / CustomerSalesFull.RoomsRentedTurnover
	|		END AS ADR,
	|		CASE
	|			WHEN CustomerSalesFull.BedsRentedTurnover = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.RoomRevenueTurnover / CustomerSalesFull.BedsRentedTurnover
	|		END AS ADBR,
	|		CASE
	|			WHEN CustomerSalesFull.RoomsRentedTurnover = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.RoomRevenueWithoutVATTurnover / CustomerSalesFull.RoomsRentedTurnover
	|		END AS ADRWithoutVAT,
	|		CASE
	|			WHEN CustomerSalesFull.BedsRentedTurnover = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.RoomRevenueWithoutVATTurnover / CustomerSalesFull.BedsRentedTurnover
	|		END AS ADBRWithoutVAT,
	|		CASE
	|			WHEN CustomerSalesFull.GuestDaysTurnover = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.RoomRevenueTurnover / CustomerSalesFull.GuestDaysTurnover
	|		END AS RevPAC,
	|		CASE
	|			WHEN CustomerSalesFull.GuestDaysTurnover = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.RoomRevenueWithoutVATTurnover / CustomerSalesFull.GuestDaysTurnover
	|		END AS RevPACWithoutVAT,
	|		CASE
	|			WHEN CustomerSalesFull.GuestsCheckedInTurnover = 0
	|				THEN 0
	|			ELSE CustomerSalesFull.GuestDaysTurnover / CustomerSalesFull.GuestsCheckedInTurnover
	|		END AS ALS
	|	FROM
	|		(SELECT
	|			SalesTurnovers.Hotel AS Hotel,
	|			SalesTurnovers.Company AS Company,
	|			SalesTurnovers.ReportingCurrency AS ReportingCurrency,
	|			SalesTurnovers.Agent AS Agent,
	|			SalesTurnovers.Customer AS Customer,
	|			SalesTurnovers.Contract AS Contract,
	|			SalesTurnovers.GuestGroup AS GuestGroup,
	|			SalesTurnovers.AccountingDate AS AccountingDate,
	|			SalesTurnovers.Client AS Client,
	|			SalesTurnovers.ParentDoc AS ParentDoc,
	|			SalesTurnovers.Service AS Service,
	|			SalesTurnovers.PaymentMethod AS PaymentMethod,
	|			SalesTurnovers.ClientType AS ClientType,
	|			SalesTurnovers.Folio AS Folio,
	|			SalesTurnovers.RoomRate AS RoomRate,
	|			SalesTurnovers.Room AS Room,
	|			SalesTurnovers.RoomType AS RoomType,
	|			SalesTurnovers.AccommodationType AS AccommodationType,
	|			SalesTurnovers.TripPurpose AS TripPurpose,
	|			SalesTurnovers.MarketingCode AS MarketingCode,
	|			SalesTurnovers.SourceOfBusiness AS SourceOfBusiness,
	|			SalesTurnovers.Resource AS Resource,
	|			SalesTurnovers.ResourceType AS ResourceType,
	|			SalesTurnovers.Author AS Author,
	|			SalesTurnovers.Discount AS Discount,
	|			SalesTurnovers.DiscountType AS DiscountType,
	|			SalesTurnovers.DiscountCard AS DiscountCard,
	|			SalesTurnovers.AgentCommissionType AS AgentCommissionType,
	|			SalesTurnovers.AgentCommission AS AgentCommission,
	|			SalesTurnovers.VATRate AS VATRate,
	|			SalesTurnovers.Price AS Price,
	|			SalesTurnovers.HotelProduct AS HotelProduct,
	|			SalesTurnovers.SalesTurnover AS SalesTurnover,
	|			SalesTurnovers.RoomRevenueTurnover AS RoomRevenueTurnover,
	|			SalesTurnovers.ExtraBedRevenueTurnover AS ExtraBedRevenueTurnover,
	|			SalesTurnovers.SalesWithoutVATTurnover AS SalesWithoutVATTurnover,
	|			SalesTurnovers.RoomRevenueWithoutVATTurnover AS RoomRevenueWithoutVATTurnover,
	|			SalesTurnovers.ExtraBedRevenueWithoutVATTurnover AS ExtraBedRevenueWithoutVATTurnover,
	|			SalesTurnovers.CommissionSumTurnover AS CommissionSumTurnover,
	|			SalesTurnovers.CommissionSumWithoutVATTurnover AS CommissionSumWithoutVATTurnover,
	|			SalesTurnovers.DiscountSumTurnover AS DiscountSumTurnover,
	|			SalesTurnovers.DiscountSumWithoutVATTurnover AS DiscountSumWithoutVATTurnover,
	|			SalesTurnovers.RoomsRentedTurnover AS RoomsRentedTurnover,
	|			SalesTurnovers.BedsRentedTurnover AS BedsRentedTurnover,
	|			SalesTurnovers.AdditionalBedsRentedTurnover AS AdditionalBedsRentedTurnover,
	|			SalesTurnovers.GuestDaysTurnover AS GuestDaysTurnover,
	|			SalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
	|			SalesTurnovers.RoomsCheckedInTurnover AS RoomsCheckedInTurnover,
	|			SalesTurnovers.BedsCheckedInTurnover AS BedsCheckedInTurnover,
	|			SalesTurnovers.AdditionalBedsCheckedInTurnover AS AdditionalBedsCheckedInTurnover,
	|			SalesTurnovers.BookingWindowTurnover AS BookingWindowTurnover,
	|			SalesTurnovers.QuantityTurnover AS QuantityTurnover
	|		FROM
	|			AccumulationRegister.Sales.Turnovers(
	|					&qPeriodFrom,
	|					&qPeriodTo,
	|					Period,
	|					NOT IsCorrection
	|						AND Hotel IN HIERARCHY (&qHotel)
	|						AND (Customer IN HIERARCHY (&qCustomer)
	|							OR &qIsEmptyCustomer)
	|						AND (Contract = &qContract
	|							OR &qIsEmptyContract)
	|						AND (GuestGroup = &qGuestGroup
	|							OR &qIsEmptyGuestGroup)
	|						AND (Service IN (&qServicesList)
	|							OR NOT &qUseServicesList)) AS SalesTurnovers
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			SalesForecastTurnovers.Hotel,
	|			SalesForecastTurnovers.Company,
	|			SalesForecastTurnovers.ReportingCurrency,
	|			SalesForecastTurnovers.Agent,
	|			SalesForecastTurnovers.Customer,
	|			SalesForecastTurnovers.Contract,
	|			SalesForecastTurnovers.GuestGroup,
	|			SalesForecastTurnovers.AccountingDate,
	|			SalesForecastTurnovers.Client,
	|			SalesForecastTurnovers.ParentDoc,
	|			SalesForecastTurnovers.Service,
	|			SalesForecastTurnovers.PaymentMethod,
	|			SalesForecastTurnovers.ClientType,
	|			SalesForecastTurnovers.Folio,
	|			SalesForecastTurnovers.RoomRate,
	|			SalesForecastTurnovers.Room,
	|			SalesForecastTurnovers.RoomType,
	|			SalesForecastTurnovers.AccommodationType,
	|			SalesForecastTurnovers.TripPurpose,
	|			SalesForecastTurnovers.MarketingCode,
	|			SalesForecastTurnovers.SourceOfBusiness,
	|			SalesForecastTurnovers.Resource,
	|			SalesForecastTurnovers.ResourceType,
	|			SalesForecastTurnovers.Author,
	|			SalesForecastTurnovers.Discount,
	|			SalesForecastTurnovers.DiscountType,
	|			SalesForecastTurnovers.DiscountCard,
	|			SalesForecastTurnovers.AgentCommissionType,
	|			SalesForecastTurnovers.AgentCommission,
	|			SalesForecastTurnovers.VATRate,
	|			SalesForecastTurnovers.Price,
	|			SalesForecastTurnovers.HotelProduct,
	|			SalesForecastTurnovers.SalesTurnover,
	|			SalesForecastTurnovers.RoomRevenueTurnover,
	|			SalesForecastTurnovers.ExtraBedRevenueTurnover,
	|			SalesForecastTurnovers.SalesWithoutVATTurnover,
	|			SalesForecastTurnovers.RoomRevenueWithoutVATTurnover,
	|			SalesForecastTurnovers.ExtraBedRevenueWithoutVATTurnover,
	|			SalesForecastTurnovers.CommissionSumTurnover,
	|			SalesForecastTurnovers.CommissionSumWithoutVATTurnover,
	|			SalesForecastTurnovers.DiscountSumTurnover,
	|			SalesForecastTurnovers.DiscountSumWithoutVATTurnover,
	|			SalesForecastTurnovers.RoomsRentedTurnover,
	|			SalesForecastTurnovers.BedsRentedTurnover,
	|			SalesForecastTurnovers.AdditionalBedsRentedTurnover,
	|			SalesForecastTurnovers.GuestDaysTurnover,
	|			SalesForecastTurnovers.GuestsCheckedInTurnover,
	|			SalesForecastTurnovers.RoomsCheckedInTurnover,
	|			SalesForecastTurnovers.BedsCheckedInTurnover,
	|			SalesForecastTurnovers.AdditionalBedsCheckedInTurnover,
	|			SalesForecastTurnovers.BookingWindowTurnover,
	|			SalesForecastTurnovers.QuantityTurnover
	|		FROM
	|			AccumulationRegister.SalesForecast.Turnovers(
	|					&qForecastPeriodFrom,
	|					&qForecastPeriodTo,
	|					Period,
	|					Hotel IN HIERARCHY (&qHotel)
	|						AND (Customer IN HIERARCHY (&qCustomer)
	|							OR &qIsEmptyCustomer)
	|						AND (Contract = &qContract
	|							OR &qIsEmptyContract)
	|						AND (GuestGroup = &qGuestGroup
	|							OR &qIsEmptyGuestGroup)
	|						AND (Service IN (&qServicesList)
	|							OR NOT &qUseServicesList)) AS SalesForecastTurnovers) AS CustomerSalesFull
	|			LEFT JOIN AccTemplatesByParentDoc AS AccTemplatesByParentDoc
	|			ON CustomerSalesFull.ParentDoc = AccTemplatesByParentDoc.ParentDoc
	|				AND CustomerSalesFull.GuestGroup = AccTemplatesByParentDoc.GuestGroup
	|			LEFT JOIN (SELECT
	|				CustomerTotals.Hotel AS Hotel,
	|				CustomerTotals.TotalRoomRevenue AS TotalRoomRevenue,
	|				CustomerTotals.TotalRoomsRented AS TotalRoomsRented,
	|				CustomerTotals.TotalBedsRented AS TotalBedsRented,
	|				CustomerTotals.TotalSales AS TotalSales
	|			FROM
	|				CustomerTotals AS CustomerTotals) AS CustomerTotalSales
	|			ON CustomerSalesFull.Hotel = CustomerTotalSales.Hotel) AS CustomerSales
	|{WHERE
	|	CustomerSales.AccommodationTemplate.* AS AccommodationTemplate,
	|	CustomerSales.Hotel.*,
	|	CustomerSales.Company.*,
	|	CustomerSales.ReportingCurrency.*,
	|	CustomerSales.Agent.*,
	|	CustomerSales.Customer.*,
	|	CustomerSales.Contract.*,
	|	CustomerSales.GuestGroup.*,
	|	CustomerSales.Client.*,
	|	CustomerSales.RoomRate.*,
	|	CustomerSales.ParentDoc.*,
	|	CustomerSales.PaymentMethod.*,
	|	CustomerSales.Service.*,
	|	CustomerSales.PaymentMethod.*,
	|	CustomerSales.ClientType.*,
	|	CustomerSales.Folio.*,
	|	CustomerSales.Room.*,
	|	CustomerSales.RoomType.*,
	|	CustomerSales.AccommodationType.*,
	|	CustomerSales.TripPurpose.*,
	|	CustomerSales.MarketingCode.*,
	|	CustomerSales.SourceOfBusiness.*,
	|	CustomerSales.Resource.*,
	|	CustomerSales.ResourceType.*,
	|	CustomerSales.Author.*,
	|	CustomerSales.Discount,
	|	CustomerSales.DiscountType.*,
	|	CustomerSales.DiscountCard.*,
	|	CustomerSales.AgentCommissionType,
	|	CustomerSales.AgentCommission,
	|	CustomerSales.VATRate.*,
	|	CustomerSales.Price AS Price,
	|	CustomerSales.HotelProduct.* AS HotelProduct,
	|	CustomerSales.Sales AS Sales,
	|	CustomerSales.RoomRevenue AS RoomRevenue,
	|	CustomerSales.ExtraBedRevenue AS ExtraBedRevenue,
	|	CustomerSales.SalesWithoutVAT AS SalesWithoutVAT,
	|	CustomerSales.RoomRevenueWithoutVAT AS RoomRevenueWithoutVAT,
	|	CustomerSales.ExtraBedRevenueWithoutVAT AS ExtraBedRevenueWithoutVAT,
	|	CustomerSales.CommissionSum AS CommissionSum,
	|	CustomerSales.CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|	CustomerSales.DiscountSum AS DiscountSum,
	|	CustomerSales.DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|	CustomerSales.RoomsRented AS RoomsRented,
	|	CustomerSales.BedsRented AS BedsRented,
	|	CustomerSales.AdditionalBedsRented AS AdditionalBedsRented,
	|	CustomerSales.GuestDays AS GuestDays,
	|	CustomerSales.GuestsCheckedIn AS GuestsCheckedIn,
	|	CustomerSales.RoomsCheckedIn AS RoomsCheckedIn,
	|	CustomerSales.BedsCheckedIn AS BedsCheckedIn,
	|	CustomerSales.AdditionalBedsCheckedIn AS AdditionalBedsCheckedIn,
	|	(CASE
	|			WHEN CustomerSales.RoomsCheckedIn <> 0
	|				THEN CAST(CustomerSales.BookingWindow / CustomerSales.RoomsCheckedIn AS NUMBER(10, 0))
	|			ELSE 0
	|		END) AS BookingWindow,
	|	CustomerSales.Quantity AS Quantity,
	|	CustomerSales.AccountingDate,
	|	(WEEK(CustomerSales.AccountingDate)) AS AccountingWeek,
	|	(MONTH(CustomerSales.AccountingDate)) AS AccountingMonth,
	|	(QUARTER(CustomerSales.AccountingDate)) AS AccountingQuarter,
	|	(YEAR(CustomerSales.AccountingDate)) AS AccountingYear,
	|	CustomerSales.TotalSales AS TotalSales,
	|	CustomerSales.TotalRoomRevenue AS TotalRoomRevenue,
	|	CustomerSales.TotalRoomsRented AS TotalRoomsRented,
	|	CustomerSales.TotalBedsRented AS TotalBedsRented,
	|	CustomerSales.TotalSalesPercent AS TotalSalesPercent,
	|	CustomerSales.TotalRoomRevenuePercent AS TotalRoomRevenuePercent,
	|	CustomerSales.TotalRoomsRentedPercent AS TotalRoomsRentedPercent,
	|	CustomerSales.TotalBedsRentedPercent AS TotalBedsRentedPercent,
	|	CustomerSales.ADR AS ADR,
	|	CustomerSales.ADBR AS ADBR,
	|	CustomerSales.ADRWithoutVAT AS ADRWithoutVAT,
	|	CustomerSales.ADBRWithoutVAT AS ADBRWithoutVAT,
	|	CustomerSales.RevPAC AS RevPAC,
	|	CustomerSales.RevPACWithoutVAT AS RevPACWithoutVAT,
	|	CustomerSales.ALS AS ALS}
	|
	|ORDER BY
	|	ReportingCurrency,
	|	Customer
	|{ORDER BY
	|	AccommodationTemplate.*,
	|	Hotel.*,
	|	Company.*,
	|	ReportingCurrency.*,
	|	Agent.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	CustomerSales.Client.*,
	|	RoomRate.*,
	|	Service.*,
	|	ParentDoc.*,
	|	CustomerSales.PaymentMethod.*,
	|	CustomerSales.PaymentMethod.*,
	|	CustomerSales.ClientType.*,
	|	CustomerSales.Folio.*,
	|	CustomerSales.Room.*,
	|	CustomerSales.RoomType.*,
	|	CustomerSales.AccommodationType.*,
	|	CustomerSales.TripPurpose.*,
	|	CustomerSales.MarketingCode.*,
	|	CustomerSales.SourceOfBusiness.*,
	|	CustomerSales.Resource.*,
	|	CustomerSales.ResourceType.*,
	|	CustomerSales.Author.*,
	|	CustomerSales.Discount,
	|	CustomerSales.DiscountType.*,
	|	CustomerSales.DiscountCard.*,
	|	CustomerSales.AgentCommissionType,
	|	CustomerSales.AgentCommission,
	|	CustomerSales.VATRate.*,
	|	CustomerSales.Price AS Price,
	|	CustomerSales.HotelProduct.* AS HotelProduct,
	|	Sales,
	|	RoomRevenue,
	|	ExtraBedRevenue,
	|	SalesWithoutVAT,
	|	RoomRevenueWithoutVAT,
	|	ExtraBedRevenueWithoutVAT,
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
	|	AdditionalBedsCheckedIn,
	|	BookingWindow,
	|	Quantity,
	|	AccountingDate,
	|	(WEEK(CustomerSales.AccountingDate)) AS AccountingWeek,
	|	(MONTH(CustomerSales.AccountingDate)) AS AccountingMonth,
	|	(QUARTER(CustomerSales.AccountingDate)) AS AccountingQuarter,
	|	(YEAR(CustomerSales.AccountingDate)) AS AccountingYear,
	|	TotalSales,
	|	TotalRoomRevenue,
	|	TotalRoomsRented,
	|	TotalBedsRented,
	|	TotalSalesPercent,
	|	TotalRoomRevenuePercent,
	|	TotalRoomsRentedPercent,
	|	TotalBedsRentedPercent,
	|	ADR,
	|	ADBR,
	|	ADRWithoutVAT,
	|	ADBRWithoutVAT,
	|	RevPAC,
	|	RevPACWithoutVAT,
	|	ALS}
	|TOTALS
	|	SUM(Sales),
	|	SUM(RoomRevenue),
	|	SUM(ExtraBedRevenue),
	|	SUM(MainBedsRevenue),
	|	SUM(SalesWithoutVAT),
	|	SUM(RoomRevenueWithoutVAT),
	|	SUM(ExtraBedRevenueWithoutVAT),
	|	SUM(MainBedsRevenueWithoutVAT),
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
	|	SUM(AdditionalBedsCheckedIn),
	|	CASE
	|		WHEN SUM(RoomsCheckedIn) <> 0
	|			THEN CAST(SUM(BookingWindow) / SUM(RoomsCheckedIn) AS NUMBER(10, 0))
	|		ELSE 0
	|	END AS BookingWindow,
	|	SUM(Quantity),
	|	MAX(TotalSales),
	|	MAX(TotalRoomRevenue),
	|	MAX(TotalRoomsRented),
	|	MAX(TotalBedsRented),
	|	CASE
	|		WHEN MAX(TotalSales) = 0
	|			THEN 0
	|		ELSE SUM(Sales) * 100 / MAX(TotalSales)
	|	END AS TotalSalesPercent,
	|	CASE
	|		WHEN MAX(TotalRoomRevenue) = 0
	|			THEN 0
	|		ELSE SUM(RoomRevenue) * 100 / MAX(TotalRoomRevenue)
	|	END AS TotalRoomRevenuePercent,
	|	CASE
	|		WHEN MAX(TotalRoomsRented) = 0
	|			THEN 0
	|		ELSE SUM(RoomsRented) * 100 / MAX(TotalRoomsRented)
	|	END AS TotalRoomsRentedPercent,
	|	CASE
	|		WHEN MAX(TotalBedsRented) = 0
	|			THEN 0
	|		ELSE SUM(BedsRented) * 100 / MAX(TotalBedsRented)
	|	END AS TotalBedsRentedPercent,
	|	CASE
	|		WHEN SUM(RoomsRented) = 0
	|			THEN 0
	|		ELSE SUM(RoomRevenue) / SUM(RoomsRented)
	|	END AS ADR,
	|	CASE
	|		WHEN SUM(BedsRented) = 0
	|			THEN 0
	|		ELSE SUM(RoomRevenue) / SUM(BedsRented)
	|	END AS ADBR,
	|	CASE
	|		WHEN SUM(RoomsRented) = 0
	|			THEN 0
	|		ELSE SUM(RoomRevenueWithoutVAT) / SUM(RoomsRented)
	|	END AS ADRWithoutVAT,
	|	CASE
	|		WHEN SUM(BedsRented) = 0
	|			THEN 0
	|		ELSE SUM(RoomRevenueWithoutVAT) / SUM(BedsRented)
	|	END AS ADBRWithoutVAT,
	|	CASE
	|		WHEN SUM(GuestDays) = 0
	|			THEN 0
	|		ELSE SUM(RoomRevenue) / SUM(GuestDays)
	|	END AS RevPAC,
	|	CASE
	|		WHEN SUM(GuestDays) = 0
	|			THEN 0
	|		ELSE SUM(RoomRevenueWithoutVAT) / SUM(GuestDays)
	|	END AS RevPACWithoutVAT,
	|	CASE
	|		WHEN SUM(GuestsCheckedIn) = 0
	|			THEN 0
	|		ELSE SUM(GuestDays) / SUM(GuestsCheckedIn)
	|	END AS ALS
	|BY
	|	OVERALL,
	|	ReportingCurrency,
	|	AccommodationTemplate
	|{TOTALS BY
	|	AccommodationTemplate.*,
	|	Hotel.*,
	|	Company.*,
	|	ReportingCurrency.*,
	|	Agent.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	CustomerSales.Client.*,
	|	RoomRate.*,
	|	ParentDoc.*,
	|	CustomerSales.PaymentMethod.*,
	|	Service.*,
	|	AccountingDate,
	|	CustomerSales.PaymentMethod.*,
	|	CustomerSales.ClientType.*,
	|	CustomerSales.Folio.*,
	|	CustomerSales.Room.*,
	|	CustomerSales.RoomType.*,
	|	CustomerSales.AccommodationType.*,
	|	CustomerSales.TripPurpose.*,
	|	CustomerSales.MarketingCode.*,
	|	CustomerSales.SourceOfBusiness.*,
	|	CustomerSales.Resource.*,
	|	CustomerSales.ResourceType.*,
	|	CustomerSales.Author.*,
	|	CustomerSales.Discount,
	|	CustomerSales.DiscountType.*,
	|	CustomerSales.DiscountCard.*,
	|	CustomerSales.AgentCommissionType,
	|	CustomerSales.AgentCommission,
	|	CustomerSales.VATRate.*,
	|	CustomerSales.Price AS Price,
	|	CustomerSales.HotelProduct.* AS HotelProduct,
	|	(CASE
	|			WHEN SUM(CustomerSales.RoomsCheckedIn) <> 0
	|				THEN CAST(SUM(CustomerSales.BookingWindow) / SUM(CustomerSales.RoomsCheckedIn) AS NUMBER(10, 0))
	|			ELSE 0
	|		END) AS BookingWindow,
	|	ADR,
	|	(WEEK(CustomerSales.AccountingDate)) AS AccountingWeek,
	|	(MONTH(CustomerSales.AccountingDate)) AS AccountingMonth,
	|	(QUARTER(CustomerSales.AccountingDate)) AS AccountingQuarter,
	|	(YEAR(CustomerSales.AccountingDate)) AS AccountingYear}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Family composition sales turnovers';RU='Обороты продаж по составам семьи';de='Verkaufsumsätze nach Zusammensetzung der Familie'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
Function pmIsResource(pName) Export
	If pName = "Sales" 
	   Or pName = "RoomRevenue" 
	   Or pName = "ExtraBedRevenue" 
	   Or pName = "MainBedsRevenue" 
	   Or pName = "SalesWithoutVAT" 
	   Or pName = "RoomRevenueWithoutVAT" 
	   Or pName = "ExtraBedRevenueWithoutVAT" 
	   Or pName = "MainBedsRevenueWithoutVAT" 
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
	   Or pName = "Quantity" 
	   Or pName = "TotalRoomRevenue" 
	   Or pName = "TotalSales" 
	   Or pName = "TotalRoomsRented" 
	   Or pName = "TotalBedsRented" 
	   Or pName = "TotalRoomRevenuePercent" 
	   Or pName = "TotalSalesPercent"
	   Or pName = "TotalRoomsRentedPercent" 
	   Or pName = "TotalBedsRentedPercent" 
	   Or pName = "ADR"
	   Or pName = "ADBR"
	   Or pName = "ADRWithoutVAT"
	   Or pName = "ADBRWithoutVAT"
	   Or pName = "RevPAC"
	   Or pName = "RevPACWithoutVAT"
	   Or pName = "ALS" 
	   Or pName = "BookingWindow" Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // pmIsResource

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
