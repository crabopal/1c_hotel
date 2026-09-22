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
		PeriodFrom = BegOfDay(CurrentSessionDate()); // For today
		PeriodTo = EndOfDay(PeriodFrom);
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
	If ValueIsFilled(Room) Then
		If Not Room.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Room ';ru='Номер ';de='Zimmer '") + 
			                     TrimAll(Room.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Rooms folder ';ru='Группа номеров ';de='Gruppe Zimmer '") + 
			                     TrimAll(Room.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(RoomType) Then
		If Not RoomType.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Room type ';ru='Тип номера ';de='Zimmertyp '") + 
			                     TrimAll(RoomType.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Room types folder ';ru='Группа типов номеров ';de='Gruppe Zimmertypen '") + 
			                     TrimAll(RoomType.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(Service) Then
		If Not Service.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Service ';ru='Услуга ';de='Dienstleistung '") + 
			                     TrimAll(Service.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа услуг '; en = 'Services folder '; de = 'Dienstleistungengruppe '") + 
			                     TrimAll(Service.Description) + 
			                     ";" + Chars.LF;
		EndIf;
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
	ReportBuilder.Parameters.Insert("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	vForecastStartDate = tcOnServer.GetForecastStartDate(Hotel);
	ReportBuilder.Parameters.Insert("qForecastPeriodFrom", Max(BegOfDay(PeriodFrom), vForecastStartDate));
	ReportBuilder.Parameters.Insert("qForecastPeriodTo", ?(ValueIsFilled(PeriodTo), Max(PeriodTo, EndOfDay(vForecastStartDate-24*3600)), '00010101'));
	ReportBuilder.Parameters.Insert("qService", Service);
	ReportBuilder.Parameters.Insert("qServiceIsEmpty", Not ValueIsFilled(Service));
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qRoomIsEmpty", Not ValueIsFilled(Room));
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qRoomTypeIsEmpty", Not ValueIsFilled(RoomType));
	ReportBuilder.Parameters.Insert("qCustomer", Customer);
	ReportBuilder.Parameters.Insert("qCustomerIsEmpty", Not ValueIsFilled(Customer));
	ReportBuilder.Parameters.Insert("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	ReportBuilder.Parameters.Insert("qContract", Contract);
	ReportBuilder.Parameters.Insert("qContractIsEmpty", Not ValueIsFilled(Contract));
	ReportBuilder.Parameters.Insert("qGuestGroup", GuestGroup);
	ReportBuilder.Parameters.Insert("qGuestGroupIsEmpty", Not ValueIsFilled(GuestGroup));
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
	Try
		ReportBuilder.Put(pSpreadsheet);
	Except
		tcCommonFunctionOnClientServer.TextMessage(cmGetRootErrorDescription(ErrorInfo()), MessageStatus.Attention);
	EndTry;
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
	|	SalesForecast.Hotel AS Hotel,
	|	SalesForecast.ReportingCurrency AS ReportingCurrency,
	|	SalesForecast.Customer AS Customer,
	|	SalesForecast.Contract AS Contract,
	|	SalesForecast.RoomsRented AS RoomsRented,
	|	SalesForecast.RoomsRentedAccommodation AS RoomsRentedAccommodation,
	|	SalesForecast.RoomsRentedReservation AS RoomsRentedReservation,
	|	SalesForecast.BedsRented AS BedsRented,
	|	SalesForecast.BedsRentedAccommodation AS BedsRentedAccommodation,
	|	SalesForecast.BedsRentedReservation AS BedsRentedReservation,
	|	SalesForecast.AdditionalBedsRented AS AdditionalBedsRented,
	|	SalesForecast.AdditionalBedsRentedAccommodation AS AdditionalBedsRentedAccommodation,
	|	SalesForecast.AdditionalBedsRentedReservation AS AdditionalBedsRentedReservation,
	|	SalesForecast.GuestDays AS GuestDays,
	|	SalesForecast.GuestDaysAccommodation AS GuestDaysAccommodation,
	|	SalesForecast.GuestDaysReservation AS GuestDaysReservation,
	|	SalesForecast.GuestsCheckedIn AS GuestsCheckedIn,
	|	SalesForecast.GuestsCheckedInAccommodation AS GuestsCheckedInAccommodation,
	|	SalesForecast.GuestsCheckedInReservation AS GuestsCheckedInReservation,
	|	SalesForecast.RoomsCheckedIn AS RoomsCheckedIn,
	|	SalesForecast.RoomsCheckedInAccommodation AS RoomsCheckedInAccommodation,
	|	SalesForecast.RoomsCheckedInReservation AS RoomsCheckedInReservation,
	|	SalesForecast.BedsCheckedIn AS BedsCheckedIn,
	|	SalesForecast.BedsCheckedInAccommodation AS BedsCheckedInAccommodation,
	|	SalesForecast.BedsCheckedInReservation AS BedsCheckedInReservation,
	|	SalesForecast.AdditionalBedsCheckedIn AS AdditionalBedsCheckedIn,
	|	SalesForecast.AdditionalBedsCheckedInAccommodation AS AdditionalBedsCheckedInAccommodation,
	|	SalesForecast.AdditionalBedsCheckedInReservation AS AdditionalBedsCheckedInReservation,
	|	SalesForecast.Quantity AS Quantity,
	|	SalesForecast.QuantityAccommodation AS QuantityAccommodation,
	|	SalesForecast.QuantityReservation AS QuantityReservation,
	|	SalesForecast.Sales AS Sales,
	|	SalesForecast.SalesAccommodation AS SalesAccommodation,
	|	SalesForecast.SalesReservation AS SalesReservation,
	|	SalesForecast.SalesWithoutVAT AS SalesWithoutVAT,
	|	SalesForecast.SalesWithoutVATAccommodation AS SalesWithoutVATAccommodation,
	|	SalesForecast.SalesWithoutVATReservation AS SalesWithoutVATReservation,
	|	SalesForecast.RoomRevenue AS RoomRevenue,
	|	SalesForecast.RoomRevenueAccommodation AS RoomRevenueAccommodation,
	|	SalesForecast.RoomRevenueReservation AS RoomRevenueReservation,
	|	SalesForecast.RoomRevenueWithoutVAT AS RoomRevenueWithoutVAT,
	|	SalesForecast.RoomRevenueWithoutVATAccommodation AS RoomRevenueWithoutVATAccommodation,
	|	SalesForecast.RoomRevenueWithoutVATReservation AS RoomRevenueWithoutVATReservation,
	|	SalesForecast.ExtraBedRevenue AS ExtraBedRevenue,
	|	SalesForecast.ExtraBedRevenueAccommodation AS ExtraBedRevenueAccommodation,
	|	SalesForecast.ExtraBedRevenueReservation AS ExtraBedRevenueReservation,
	|	SalesForecast.ExtraBedRevenueWithoutVAT AS ExtraBedRevenueWithoutVAT,
	|	SalesForecast.ExtraBedRevenueWithoutVATAccommodation AS ExtraBedRevenueWithoutVATAccommodation,
	|	SalesForecast.ExtraBedRevenueWithoutVATReservation AS ExtraBedRevenueWithoutVATReservation,
	|	SalesForecast.MainBedsRevenue AS MainBedsRevenue,
	|	SalesForecast.MainBedsRevenueAccommodation AS MainBedsRevenueAccommodation,
	|	SalesForecast.MainBedsRevenueReservation AS MainBedsRevenueReservation,
	|	SalesForecast.MainBedsRevenueWithoutVAT AS MainBedsRevenueWithoutVAT,
	|	SalesForecast.MainBedsRevenueWithoutVATAccommodation AS MainBedsRevenueWithoutVATAccommodation,
	|	SalesForecast.MainBedsRevenueWithoutVATReservation AS MainBedsRevenueWithoutVATReservation,
	|	SalesForecast.CommissionSum AS CommissionSum,
	|	SalesForecast.CommissionSumAccommodation AS CommissionSumAccommodation,
	|	SalesForecast.CommissionSumReservation AS CommissionSumReservation,
	|	SalesForecast.CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|	SalesForecast.CommissionSumWithoutVATAccommodation AS CommissionSumWithoutVATAccommodation,
	|	SalesForecast.CommissionSumWithoutVATReservation AS CommissionSumWithoutVATReservation,
	|	SalesForecast.DiscountSum AS DiscountSum,
	|	SalesForecast.DiscountSumAccommodation AS DiscountSumAccommodation,
	|	SalesForecast.DiscountSumReservation AS DiscountSumReservation,
	|	SalesForecast.DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|	SalesForecast.DiscountSumWithoutVATAccommodation AS DiscountSumWithoutVATAccommodation,
	|	SalesForecast.DiscountSumWithoutVATReservation AS DiscountSumWithoutVATReservation,
	|	SalesForecast.RoomPrice AS RoomPrice
	|{SELECT
	|	Hotel.* AS Hotel,
	|	SalesForecast.Company.* AS Company,
	|	ReportingCurrency.* AS ReportingCurrency,
	|	SalesForecast.Agent.* AS Agent,
	|	SalesForecast.PaymentMethod.* AS PaymentMethod,
	|	Customer.* AS Customer,
	|	Contract.* AS Contract,
	|	SalesForecast.RoomRate.* AS RoomRate,
	|	SalesForecast.GuestGroup.* AS GuestGroup,
	|	SalesForecast.ParentDoc.* AS ParentDoc,
	|	SalesForecast.Client.* AS Client,
	|	SalesForecast.Service.* AS Service,
	|	SalesForecast.AccountingDate AS AccountingDate,
	|	(HOUR(SalesForecast.AccountingDate)) AS AccountingHour,
	|	(DAY(SalesForecast.AccountingDate)) AS AccountingDay,
	|	(WEEK(SalesForecast.AccountingDate)) AS AccountingWeek,
	|	(MONTH(SalesForecast.AccountingDate)) AS AccountingMonth,
	|	(QUARTER(SalesForecast.AccountingDate)) AS AccountingQuarter,
	|	(YEAR(SalesForecast.AccountingDate)) AS AccountingYear,
	|	(BEGINOFPERIOD(SalesForecast.ParentDoc.CheckInDate, DAY)) AS CheckInDate,
	|	(HOUR(SalesForecast.ParentDoc.CheckInDate)) AS CheckInHour,
	|	(DAY(SalesForecast.ParentDoc.CheckInDate)) AS CheckInDay,
	|	(WEEK(SalesForecast.ParentDoc.CheckInDate)) AS CheckInWeek,
	|	(MONTH(SalesForecast.ParentDoc.CheckInDate)) AS CheckInMonth,
	|	(QUARTER(SalesForecast.ParentDoc.CheckInDate)) AS CheckInQuarter,
	|	(YEAR(SalesForecast.ParentDoc.CheckInDate)) AS CheckInYear,
	|	SalesForecast.ParentDoc.RoomRateType.* AS RoomRateType,
	|	SalesForecast.ParentDoc.Room.* AS Room,
	|	SalesForecast.ParentDoc.RoomType.* AS RoomType,
	|	SalesForecast.ParentDoc.AccommodationType.* AS AccommodationType,
	|	SalesForecast.ParentDoc.RoomQuota.* AS RoomQuota,
	|	SalesForecast.ParentDoc.Discount AS Discount,
	|	SalesForecast.ParentDoc.DiscountType.* AS DiscountType,
	|	SalesForecast.ParentDoc.DiscountCard.* AS DiscountCard,
	|	SalesForecast.ParentDoc.ClientType.* AS ClientType,
	|	SalesForecast.ParentDoc.SourceOfBusiness.* AS SourceOfBusiness,
	|	SalesForecast.ParentDoc.MarketingCode.* AS MarketingCode,
	|	SalesForecast.ParentDoc.TripPurpose.* AS TripPurpose,
	|	SalesForecast.ParentDoc.HotelProduct.* AS HotelProduct,
	|	SalesForecast.ParentDoc.AgentCommissionType.* AS AgentCommissionType,
	|	SalesForecast.ParentDoc.AgentCommission AS AgentCommission,
	|	SalesForecast.ParentDoc.Author.* AS Author,
	|	RoomsRented AS RoomsRented,
	|	RoomsRentedAccommodation AS RoomsRentedAccommodation,
	|	RoomsRentedReservation AS RoomsRentedReservation,
	|	BedsRented AS BedsRented,
	|	BedsRentedAccommodation AS BedsRentedAccommodation,
	|	BedsRentedReservation AS BedsRentedReservation,
	|	AdditionalBedsRented AS AdditionalBedsRented,
	|	AdditionalBedsRentedAccommodation AS AdditionalBedsRentedAccommodation,
	|	AdditionalBedsRentedReservation AS AdditionalBedsRentedReservation,
	|	GuestDays AS GuestDays,
	|	GuestDaysAccommodation AS GuestDaysAccommodation,
	|	GuestDaysReservation AS GuestDaysReservation,
	|	GuestsCheckedIn AS GuestsCheckedIn,
	|	GuestsCheckedInAccommodation AS GuestsCheckedInAccommodation,
	|	GuestsCheckedInReservation AS GuestsCheckedInReservation,
	|	RoomsCheckedIn AS RoomsCheckedIn,
	|	RoomsCheckedInAccommodation AS RoomsCheckedInAccommodation,
	|	RoomsCheckedInReservation AS RoomsCheckedInReservation,
	|	BedsCheckedIn AS BedsCheckedIn,
	|	BedsCheckedInAccommodation AS BedsCheckedInAccommodation,
	|	BedsCheckedInReservation AS BedsCheckedInReservation,
	|	AdditionalBedsCheckedIn AS AdditionalBedsCheckedIn,
	|	AdditionalBedsCheckedInAccommodation AS AdditionalBedsCheckedInAccommodation,
	|	AdditionalBedsCheckedInReservation AS AdditionalBedsCheckedInReservation,
	|	Quantity AS Quantity,
	|	QuantityAccommodation AS QuantityAccommodation,
	|	QuantityReservation AS QuantityReservation,
	|	Sales AS Sales,
	|	SalesAccommodation AS SalesAccommodation,
	|	SalesReservation AS SalesReservation,
	|	SalesWithoutVAT AS SalesWithoutVAT,
	|	SalesWithoutVATAccommodation AS SalesWithoutVATAccommodation,
	|	SalesWithoutVATReservation AS SalesWithoutVATReservation,
	|	RoomRevenue AS RoomRevenue,
	|	RoomRevenueAccommodation AS RoomRevenueAccommodation,
	|	RoomRevenueReservation AS RoomRevenueReservation,
	|	RoomRevenueWithoutVAT AS RoomRevenueWithoutVAT,
	|	RoomRevenueWithoutVATAccommodation AS RoomRevenueWithoutVATAccommodation,
	|	RoomRevenueWithoutVATReservation AS RoomRevenueWithoutVATReservation,
	|	ExtraBedRevenue AS ExtraBedRevenue,
	|	ExtraBedRevenueAccommodation AS ExtraBedRevenueAccommodation,
	|	ExtraBedRevenueReservation AS ExtraBedRevenueReservation,
	|	ExtraBedRevenueWithoutVAT AS ExtraBedRevenueWithoutVAT,
	|	ExtraBedRevenueWithoutVATAccommodation AS ExtraBedRevenueWithoutVATAccommodation,
	|	ExtraBedRevenueWithoutVATReservation AS ExtraBedRevenueWithoutVATReservation,
	|	MainBedsRevenue AS MainBedsRevenue,
	|	MainBedsRevenueAccommodation AS MainBedsRevenueAccommodation,
	|	MainBedsRevenueReservation AS MainBedsRevenueReservation,
	|	MainBedsRevenueWithoutVAT AS MainBedsRevenueWithoutVAT,
	|	MainBedsRevenueWithoutVATAccommodation AS MainBedsRevenueWithoutVATAccommodation,
	|	MainBedsRevenueWithoutVATReservation AS MainBedsRevenueWithoutVATReservation,
	|	CommissionSum AS CommissionSum,
	|	CommissionSumAccommodation AS CommissionSumAccommodation,
	|	CommissionSumReservation AS CommissionSumReservation,
	|	CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|	CommissionSumWithoutVATAccommodation AS CommissionSumWithoutVATAccommodation,
	|	CommissionSumWithoutVATReservation AS CommissionSumWithoutVATReservation,
	|	DiscountSum AS DiscountSum,
	|	DiscountSumAccommodation AS DiscountSumAccommodation,
	|	DiscountSumReservation AS DiscountSumReservation,
	|	DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|	DiscountSumWithoutVATAccommodation AS DiscountSumWithoutVATAccommodation,
	|	DiscountSumWithoutVATReservation AS DiscountSumWithoutVATReservation,
	|	RoomPrice}
	|FROM
	|	(SELECT
	|		CustomerSalesUnion.Hotel AS Hotel,
	|		CustomerSalesUnion.Company AS Company,
	|		CustomerSalesUnion.ReportingCurrency AS ReportingCurrency,
	|		CustomerSalesUnion.Agent AS Agent,
	|		CustomerSalesUnion.Customer AS Customer,
	|		CustomerSalesUnion.Contract AS Contract,
	|		CustomerSalesUnion.GuestGroup AS GuestGroup,
	|		CustomerSalesUnion.Client AS Client,
	|		CustomerSalesUnion.RoomRate AS RoomRate,
	|		CustomerSalesUnion.AccountingDate AS AccountingDate,
	|		CustomerSalesUnion.ParentDoc AS ParentDoc,
	|		CustomerSalesUnion.Service AS Service,
	|		CustomerSalesUnion.PaymentMethod AS PaymentMethod,
	|		SUM(CustomerSalesUnion.RoomsRented) AS RoomsRented,
	|		SUM(CustomerSalesUnion.RoomsRentedAccommodation) AS RoomsRentedAccommodation,
	|		SUM(CustomerSalesUnion.RoomsRentedReservation) AS RoomsRentedReservation,
	|		SUM(CustomerSalesUnion.BedsRented) AS BedsRented,
	|		SUM(CustomerSalesUnion.BedsRentedAccommodation) AS BedsRentedAccommodation,
	|		SUM(CustomerSalesUnion.BedsRentedReservation) AS BedsRentedReservation,
	|		SUM(CustomerSalesUnion.AdditionalBedsRented) AS AdditionalBedsRented,
	|		SUM(CustomerSalesUnion.AdditionalBedsRentedAccommodation) AS AdditionalBedsRentedAccommodation,
	|		SUM(CustomerSalesUnion.AdditionalBedsRentedReservation) AS AdditionalBedsRentedReservation,
	|		SUM(CustomerSalesUnion.GuestDays) AS GuestDays,
	|		SUM(CustomerSalesUnion.GuestDaysAccommodation) AS GuestDaysAccommodation,
	|		SUM(CustomerSalesUnion.GuestDaysReservation) AS GuestDaysReservation,
	|		SUM(CustomerSalesUnion.GuestsCheckedIn) AS GuestsCheckedIn,
	|		SUM(CustomerSalesUnion.GuestsCheckedInAccommodation) AS GuestsCheckedInAccommodation,
	|		SUM(CustomerSalesUnion.GuestsCheckedInReservation) AS GuestsCheckedInReservation,
	|		SUM(CustomerSalesUnion.RoomsCheckedIn) AS RoomsCheckedIn,
	|		SUM(CustomerSalesUnion.RoomsCheckedInAccommodation) AS RoomsCheckedInAccommodation,
	|		SUM(CustomerSalesUnion.RoomsCheckedInReservation) AS RoomsCheckedInReservation,
	|		SUM(CustomerSalesUnion.BedsCheckedIn) AS BedsCheckedIn,
	|		SUM(CustomerSalesUnion.BedsCheckedInAccommodation) AS BedsCheckedInAccommodation,
	|		SUM(CustomerSalesUnion.BedsCheckedInReservation) AS BedsCheckedInReservation,
	|		SUM(CustomerSalesUnion.AdditionalBedsCheckedIn) AS AdditionalBedsCheckedIn,
	|		SUM(CustomerSalesUnion.AdditionalBedsCheckedInAccommodation) AS AdditionalBedsCheckedInAccommodation,
	|		SUM(CustomerSalesUnion.AdditionalBedsCheckedInReservation) AS AdditionalBedsCheckedInReservation,
	|		SUM(CustomerSalesUnion.Quantity) AS Quantity,
	|		SUM(CustomerSalesUnion.QuantityAccommodation) AS QuantityAccommodation,
	|		SUM(CustomerSalesUnion.QuantityReservation) AS QuantityReservation,
	|		SUM(CustomerSalesUnion.Sales) AS Sales,
	|		SUM(CustomerSalesUnion.SalesAccommodation) AS SalesAccommodation,
	|		SUM(CustomerSalesUnion.SalesReservation) AS SalesReservation,
	|		SUM(CustomerSalesUnion.SalesWithoutVAT) AS SalesWithoutVAT,
	|		SUM(CustomerSalesUnion.SalesWithoutVATAccommodation) AS SalesWithoutVATAccommodation,
	|		SUM(CustomerSalesUnion.SalesWithoutVATReservation) AS SalesWithoutVATReservation,
	|		SUM(CustomerSalesUnion.RoomRevenue) AS RoomRevenue,
	|		SUM(CustomerSalesUnion.RoomRevenueAccommodation) AS RoomRevenueAccommodation,
	|		SUM(CustomerSalesUnion.RoomRevenueReservation) AS RoomRevenueReservation,
	|		SUM(CustomerSalesUnion.RoomRevenueWithoutVAT) AS RoomRevenueWithoutVAT,
	|		SUM(CustomerSalesUnion.RoomRevenueWithoutVATAccommodation) AS RoomRevenueWithoutVATAccommodation,
	|		SUM(CustomerSalesUnion.RoomRevenueWithoutVATReservation) AS RoomRevenueWithoutVATReservation,
	|		SUM(CustomerSalesUnion.ExtraBedRevenue) AS ExtraBedRevenue,
	|		SUM(CustomerSalesUnion.ExtraBedRevenueAccommodation) AS ExtraBedRevenueAccommodation,
	|		SUM(CustomerSalesUnion.ExtraBedRevenueReservation) AS ExtraBedRevenueReservation,
	|		SUM(CustomerSalesUnion.ExtraBedRevenueWithoutVAT) AS ExtraBedRevenueWithoutVAT,
	|		SUM(CustomerSalesUnion.ExtraBedRevenueWithoutVATAccommodation) AS ExtraBedRevenueWithoutVATAccommodation,
	|		SUM(CustomerSalesUnion.ExtraBedRevenueWithoutVATReservation) AS ExtraBedRevenueWithoutVATReservation,
	|		SUM(CustomerSalesUnion.MainBedsRevenue) AS MainBedsRevenue,
	|		SUM(CustomerSalesUnion.MainBedsRevenueAccommodation) AS MainBedsRevenueAccommodation,
	|		SUM(CustomerSalesUnion.MainBedsRevenueReservation) AS MainBedsRevenueReservation,
	|		SUM(CustomerSalesUnion.MainBedsRevenueWithoutVAT) AS MainBedsRevenueWithoutVAT,
	|		SUM(CustomerSalesUnion.MainBedsRevenueWithoutVATAccommodation) AS MainBedsRevenueWithoutVATAccommodation,
	|		SUM(CustomerSalesUnion.MainBedsRevenueWithoutVATReservation) AS MainBedsRevenueWithoutVATReservation,
	|		SUM(CustomerSalesUnion.CommissionSum) AS CommissionSum,
	|		SUM(CustomerSalesUnion.CommissionSumAccommodation) AS CommissionSumAccommodation,
	|		SUM(CustomerSalesUnion.CommissionSumReservation) AS CommissionSumReservation,
	|		SUM(CustomerSalesUnion.CommissionSumWithoutVAT) AS CommissionSumWithoutVAT,
	|		SUM(CustomerSalesUnion.CommissionSumWithoutVATAccommodation) AS CommissionSumWithoutVATAccommodation,
	|		SUM(CustomerSalesUnion.CommissionSumWithoutVATReservation) AS CommissionSumWithoutVATReservation,
	|		SUM(CustomerSalesUnion.DiscountSum) AS DiscountSum,
	|		SUM(CustomerSalesUnion.DiscountSumAccommodation) AS DiscountSumAccommodation,
	|		SUM(CustomerSalesUnion.DiscountSumReservation) AS DiscountSumReservation,
	|		SUM(CustomerSalesUnion.DiscountSumWithoutVAT) AS DiscountSumWithoutVAT,
	|		SUM(CustomerSalesUnion.DiscountSumWithoutVATAccommodation) AS DiscountSumWithoutVATAccommodation,
	|		SUM(CustomerSalesUnion.DiscountSumWithoutVATReservation) AS DiscountSumWithoutVATReservation,
	|		MAX(CustomerSalesUnion.RoomPrice) AS RoomPrice
	|	FROM
	|		(SELECT
	|			CustomerSalesTurnovers.Hotel AS Hotel,
	|			CustomerSalesTurnovers.Company AS Company,
	|			CustomerSalesTurnovers.ReportingCurrency AS ReportingCurrency,
	|			CustomerSalesTurnovers.Agent AS Agent,
	|			CASE
	|				WHEN CustomerSalesTurnovers.Customer = &qEmptyCustomer
	|					THEN CustomerSalesTurnovers.Hotel.IndividualsCustomer
	|				ELSE CustomerSalesTurnovers.Customer
	|			END AS Customer,
	|			CASE
	|				WHEN CustomerSalesTurnovers.Customer = &qEmptyCustomer
	|					THEN CustomerSalesTurnovers.Hotel.IndividualsContract
	|				ELSE CustomerSalesTurnovers.Contract
	|			END AS Contract,
	|			CustomerSalesTurnovers.GuestGroup AS GuestGroup,
	|			CustomerSalesTurnovers.Client AS Client,
	|			CustomerSalesTurnovers.RoomRate AS RoomRate,
	|			CustomerSalesTurnovers.AccountingDate AS AccountingDate,
	|			CustomerSalesTurnovers.ParentDoc AS ParentDoc,
	|			CustomerSalesTurnovers.Service AS Service,
	|			CustomerSalesTurnovers.PaymentMethod AS PaymentMethod,
	|			CustomerSalesTurnovers.RoomsRentedTurnover AS RoomsRented,
	|			CustomerSalesTurnovers.RoomsRentedTurnover AS RoomsRentedAccommodation,
	|			0 AS RoomsRentedReservation,
	|			CustomerSalesTurnovers.BedsRentedTurnover AS BedsRented,
	|			CustomerSalesTurnovers.BedsRentedTurnover AS BedsRentedAccommodation,
	|			0 AS BedsRentedReservation,
	|			CustomerSalesTurnovers.AdditionalBedsRentedTurnover AS AdditionalBedsRented,
	|			CustomerSalesTurnovers.AdditionalBedsRentedTurnover AS AdditionalBedsRentedAccommodation,
	|			0 AS AdditionalBedsRentedReservation,
	|			CustomerSalesTurnovers.GuestDaysTurnover AS GuestDays,
	|			CustomerSalesTurnovers.GuestDaysTurnover AS GuestDaysAccommodation,
	|			0 AS GuestDaysReservation,
	|			CustomerSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedIn,
	|			CustomerSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInAccommodation,
	|			0 AS GuestsCheckedInReservation,
	|			CustomerSalesTurnovers.RoomsCheckedInTurnover AS RoomsCheckedIn,
	|			CustomerSalesTurnovers.RoomsCheckedInTurnover AS RoomsCheckedInAccommodation,
	|			0 AS RoomsCheckedInReservation,
	|			CustomerSalesTurnovers.BedsCheckedInTurnover AS BedsCheckedIn,
	|			CustomerSalesTurnovers.BedsCheckedInTurnover AS BedsCheckedInAccommodation,
	|			0 AS BedsCheckedInReservation,
	|			CustomerSalesTurnovers.AdditionalBedsCheckedInTurnover AS AdditionalBedsCheckedIn,
	|			CustomerSalesTurnovers.AdditionalBedsCheckedInTurnover AS AdditionalBedsCheckedInAccommodation,
	|			0 AS AdditionalBedsCheckedInReservation,
	|			CustomerSalesTurnovers.QuantityTurnover AS Quantity,
	|			CustomerSalesTurnovers.QuantityTurnover AS QuantityAccommodation,
	|			0 AS QuantityReservation,
	|			CustomerSalesTurnovers.SalesTurnover AS Sales,
	|			CustomerSalesTurnovers.SalesTurnover AS SalesAccommodation,
	|			0 AS SalesReservation,
	|			CustomerSalesTurnovers.SalesWithoutVATTurnover AS SalesWithoutVAT,
	|			CustomerSalesTurnovers.SalesWithoutVATTurnover AS SalesWithoutVATAccommodation,
	|			0 AS SalesWithoutVATReservation,
	|			CustomerSalesTurnovers.RoomRevenueTurnover AS RoomRevenue,
	|			CustomerSalesTurnovers.RoomRevenueTurnover AS RoomRevenueAccommodation,
	|			0 AS RoomRevenueReservation,
	|			CustomerSalesTurnovers.RoomRevenueWithoutVATTurnover AS RoomRevenueWithoutVAT,
	|			CustomerSalesTurnovers.RoomRevenueWithoutVATTurnover AS RoomRevenueWithoutVATAccommodation,
	|			0 AS RoomRevenueWithoutVATReservation,
	|			CustomerSalesTurnovers.ExtraBedRevenueTurnover AS ExtraBedRevenue,
	|			CustomerSalesTurnovers.ExtraBedRevenueTurnover AS ExtraBedRevenueAccommodation,
	|			0 AS ExtraBedRevenueReservation,
	|			CustomerSalesTurnovers.ExtraBedRevenueWithoutVATTurnover AS ExtraBedRevenueWithoutVAT,
	|			CustomerSalesTurnovers.ExtraBedRevenueWithoutVATTurnover AS ExtraBedRevenueWithoutVATAccommodation,
	|			0 AS ExtraBedRevenueWithoutVATReservation,
	|			CustomerSalesTurnovers.RoomRevenueTurnover - CustomerSalesTurnovers.ExtraBedRevenueTurnover AS MainBedsRevenue,
	|			CustomerSalesTurnovers.RoomRevenueTurnover - CustomerSalesTurnovers.ExtraBedRevenueTurnover AS MainBedsRevenueAccommodation,
	|			0 AS MainBedsRevenueReservation,
	|			CustomerSalesTurnovers.RoomRevenueWithoutVATTurnover - CustomerSalesTurnovers.ExtraBedRevenueWithoutVATTurnover AS MainBedsRevenueWithoutVAT,
	|			CustomerSalesTurnovers.RoomRevenueWithoutVATTurnover - CustomerSalesTurnovers.ExtraBedRevenueWithoutVATTurnover AS MainBedsRevenueWithoutVATAccommodation,
	|			0 AS MainBedsRevenueWithoutVATReservation,
	|			CustomerSalesTurnovers.CommissionSumTurnover AS CommissionSum,
	|			CustomerSalesTurnovers.CommissionSumTurnover AS CommissionSumAccommodation,
	|			0 AS CommissionSumReservation,
	|			CustomerSalesTurnovers.CommissionSumWithoutVATTurnover AS CommissionSumWithoutVAT,
	|			CustomerSalesTurnovers.CommissionSumWithoutVATTurnover AS CommissionSumWithoutVATAccommodation,
	|			0 AS CommissionSumWithoutVATReservation,
	|			CustomerSalesTurnovers.DiscountSumTurnover AS DiscountSum,
	|			CustomerSalesTurnovers.DiscountSumTurnover AS DiscountSumAccommodation,
	|			0 AS DiscountSumReservation,
	|			CustomerSalesTurnovers.DiscountSumWithoutVATTurnover AS DiscountSumWithoutVAT,
	|			CustomerSalesTurnovers.DiscountSumWithoutVATTurnover AS DiscountSumWithoutVATAccommodation,
	|			0 AS DiscountSumWithoutVATReservation,
	|			CASE
	|				WHEN CustomerSalesTurnovers.RoomsRentedTurnover = 0
	|					THEN 0
	|				ELSE CustomerSalesTurnovers.RoomRevenueTurnover / CustomerSalesTurnovers.RoomsRentedTurnover
	|			END AS RoomPrice
	|		FROM
	|			AccumulationRegister.Sales.Turnovers(
	|					&qPeriodFrom,
	|					&qPeriodTo,
	|					Period,
	|					NOT IsCorrection AND (Hotel IN HIERARCHY (&qHotel)
	|						OR &qHotelIsEmpty)
	|						AND (Customer IN HIERARCHY (&qCustomer)
	|							OR &qCustomerIsEmpty)
	|						AND (Contract = &qContract
	|							OR &qContractIsEmpty)
	|						AND (GuestGroup = &qGuestGroup
	|							OR &qGuestGroupIsEmpty)
	|						AND (Service IN HIERARCHY (&qService)
	|							OR &qServiceIsEmpty)
	|						AND (Service IN (&qServicesList)
	|							OR NOT &qUseServicesList)
	|						AND (ParentDoc.Room IN HIERARCHY (&qRoom)
	|							OR &qRoomIsEmpty)
	|						AND (ParentDoc.RoomType IN HIERARCHY (&qRoomType)
	|							OR &qRoomTypeIsEmpty)) AS CustomerSalesTurnovers
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			CustomerSalesForecastTurnovers.Hotel,
	|			CustomerSalesForecastTurnovers.Company,
	|			CustomerSalesForecastTurnovers.ReportingCurrency,
	|			CustomerSalesForecastTurnovers.Agent,
	|			CASE
	|				WHEN CustomerSalesForecastTurnovers.Customer = &qEmptyCustomer
	|					THEN CustomerSalesForecastTurnovers.Hotel.IndividualsCustomer
	|				ELSE CustomerSalesForecastTurnovers.Customer
	|			END,
	|			CASE
	|				WHEN CustomerSalesForecastTurnovers.Customer = &qEmptyCustomer
	|					THEN CustomerSalesForecastTurnovers.Hotel.IndividualsContract
	|				ELSE CustomerSalesForecastTurnovers.Contract
	|			END,
	|			CustomerSalesForecastTurnovers.GuestGroup,
	|			CustomerSalesForecastTurnovers.Client,
	|			CustomerSalesForecastTurnovers.RoomRate,
	|			CustomerSalesForecastTurnovers.AccountingDate,
	|			CustomerSalesForecastTurnovers.ParentDoc,
	|			CustomerSalesForecastTurnovers.Service,
	|			CustomerSalesForecastTurnovers.PaymentMethod,
	|			CustomerSalesForecastTurnovers.RoomsRentedTurnover,
	|			0,
	|			CustomerSalesForecastTurnovers.RoomsRentedTurnover,
	|			CustomerSalesForecastTurnovers.BedsRentedTurnover,
	|			0,
	|			CustomerSalesForecastTurnovers.BedsRentedTurnover,
	|			CustomerSalesForecastTurnovers.AdditionalBedsRentedTurnover,
	|			0,
	|			CustomerSalesForecastTurnovers.AdditionalBedsRentedTurnover,
	|			CustomerSalesForecastTurnovers.GuestDaysTurnover,
	|			0,
	|			CustomerSalesForecastTurnovers.GuestDaysTurnover,
	|			CustomerSalesForecastTurnovers.GuestsCheckedInTurnover,
	|			0,
	|			CustomerSalesForecastTurnovers.GuestsCheckedInTurnover,
	|			CustomerSalesForecastTurnovers.RoomsCheckedInTurnover,
	|			0,
	|			CustomerSalesForecastTurnovers.RoomsCheckedInTurnover,
	|			CustomerSalesForecastTurnovers.BedsCheckedInTurnover,
	|			0,
	|			CustomerSalesForecastTurnovers.BedsCheckedInTurnover,
	|			CustomerSalesForecastTurnovers.AdditionalBedsCheckedInTurnover,
	|			0,
	|			CustomerSalesForecastTurnovers.AdditionalBedsCheckedInTurnover,
	|			CustomerSalesForecastTurnovers.QuantityTurnover,
	|			0,
	|			CustomerSalesForecastTurnovers.QuantityTurnover,
	|			CustomerSalesForecastTurnovers.SalesTurnover,
	|			0,
	|			CustomerSalesForecastTurnovers.SalesTurnover,
	|			CustomerSalesForecastTurnovers.SalesWithoutVATTurnover,
	|			0,
	|			CustomerSalesForecastTurnovers.SalesWithoutVATTurnover,
	|			CustomerSalesForecastTurnovers.RoomRevenueTurnover,
	|			0,
	|			CustomerSalesForecastTurnovers.RoomRevenueTurnover,
	|			CustomerSalesForecastTurnovers.RoomRevenueWithoutVATTurnover,
	|			0,
	|			CustomerSalesForecastTurnovers.RoomRevenueWithoutVATTurnover,
	|			CustomerSalesForecastTurnovers.ExtraBedRevenueTurnover,
	|			0,
	|			CustomerSalesForecastTurnovers.ExtraBedRevenueTurnover,
	|			CustomerSalesForecastTurnovers.ExtraBedRevenueWithoutVATTurnover,
	|			0,
	|			CustomerSalesForecastTurnovers.ExtraBedRevenueWithoutVATTurnover,
	|			CustomerSalesForecastTurnovers.RoomRevenueTurnover - CustomerSalesForecastTurnovers.ExtraBedRevenueTurnover,
	|			0,
	|			CustomerSalesForecastTurnovers.RoomRevenueTurnover - CustomerSalesForecastTurnovers.ExtraBedRevenueTurnover,
	|			CustomerSalesForecastTurnovers.RoomRevenueWithoutVATTurnover - CustomerSalesForecastTurnovers.ExtraBedRevenueWithoutVATTurnover,
	|			0,
	|			CustomerSalesForecastTurnovers.RoomRevenueWithoutVATTurnover - CustomerSalesForecastTurnovers.ExtraBedRevenueWithoutVATTurnover,
	|			CustomerSalesForecastTurnovers.CommissionSumTurnover,
	|			0,
	|			CustomerSalesForecastTurnovers.CommissionSumTurnover,
	|			CustomerSalesForecastTurnovers.CommissionSumWithoutVATTurnover,
	|			0,
	|			CustomerSalesForecastTurnovers.CommissionSumWithoutVATTurnover,
	|			CustomerSalesForecastTurnovers.DiscountSumTurnover,
	|			0,
	|			CustomerSalesForecastTurnovers.DiscountSumTurnover,
	|			CustomerSalesForecastTurnovers.DiscountSumWithoutVATTurnover,
	|			0,
	|			CustomerSalesForecastTurnovers.DiscountSumWithoutVATTurnover,
	|			CASE
	|				WHEN CustomerSalesForecastTurnovers.RoomsRentedTurnover = 0
	|					THEN 0
	|				ELSE CustomerSalesForecastTurnovers.RoomRevenueTurnover / CustomerSalesForecastTurnovers.RoomsRentedTurnover
	|			END
	|		FROM
	|			AccumulationRegister.SalesForecast.Turnovers(
	|					&qForecastPeriodFrom,
	|					&qForecastPeriodTo,
	|					Period,
	|					(Hotel IN HIERARCHY (&qHotel)
	|						OR &qHotelIsEmpty)
	|						AND (Customer IN HIERARCHY (&qCustomer)
	|							OR &qCustomerIsEmpty)
	|						AND (Contract = &qContract
	|							OR &qContractIsEmpty)
	|						AND (GuestGroup = &qGuestGroup
	|							OR &qGuestGroupIsEmpty)
	|						AND (Service IN HIERARCHY (&qService)
	|							OR &qServiceIsEmpty)
	|						AND (Service IN (&qServicesList)
	|							OR NOT &qUseServicesList)
	|						AND (ParentDoc.Room IN HIERARCHY (&qRoom)
	|							OR &qRoomIsEmpty)
	|						AND (ParentDoc.RoomType IN HIERARCHY (&qRoomType)
	|							OR &qRoomTypeIsEmpty)) AS CustomerSalesForecastTurnovers) AS CustomerSalesUnion
	|	
	|	GROUP BY
	|		CustomerSalesUnion.Hotel,
	|		CustomerSalesUnion.Company,
	|		CustomerSalesUnion.ReportingCurrency,
	|		CustomerSalesUnion.Agent,
	|		CustomerSalesUnion.Customer,
	|		CustomerSalesUnion.Contract,
	|		CustomerSalesUnion.GuestGroup,
	|		CustomerSalesUnion.Client,
	|		CustomerSalesUnion.RoomRate,
	|		CustomerSalesUnion.AccountingDate,
	|		CustomerSalesUnion.ParentDoc,
	|		CustomerSalesUnion.Service,
	|		CustomerSalesUnion.PaymentMethod) AS SalesForecast
	|{WHERE
	|	SalesForecast.Hotel.* AS Hotel,
	|	SalesForecast.Company.* AS Company,
	|	SalesForecast.ReportingCurrency.* AS ReportingCurrency,
	|	SalesForecast.Agent.* AS Agent,
	|	SalesForecast.PaymentMethod.* AS PaymentMethod,
	|	SalesForecast.Customer.* AS Customer,
	|	SalesForecast.Contract.* AS Contract,
	|	SalesForecast.RoomRate.* AS RoomRate,
	|	SalesForecast.GuestGroup.* AS GuestGroup,
	|	SalesForecast.ParentDoc.* AS ParentDoc,
	|	SalesForecast.Client.* AS Client,
	|	SalesForecast.Service.* AS Service,
	|	SalesForecast.AccountingDate AS AccountingDate,
	|	(HOUR(SalesForecast.AccountingDate)) AS AccountingHour,
	|	(DAY(SalesForecast.AccountingDate)) AS AccountingDay,
	|	(WEEK(SalesForecast.AccountingDate)) AS AccountingWeek,
	|	(MONTH(SalesForecast.AccountingDate)) AS AccountingMonth,
	|	(QUARTER(SalesForecast.AccountingDate)) AS AccountingQuarter,
	|	(YEAR(SalesForecast.AccountingDate)) AS AccountingYear,
	|	(BEGINOFPERIOD(SalesForecast.ParentDoc.CheckInDate, DAY)) AS CheckInDate,
	|	(HOUR(SalesForecast.ParentDoc.CheckInDate)) AS CheckInHour,
	|	(DAY(SalesForecast.ParentDoc.CheckInDate)) AS CheckInDay,
	|	(WEEK(SalesForecast.ParentDoc.CheckInDate)) AS CheckInWeek,
	|	(MONTH(SalesForecast.ParentDoc.CheckInDate)) AS CheckInMonth,
	|	(QUARTER(SalesForecast.ParentDoc.CheckInDate)) AS CheckInQuarter,
	|	(YEAR(SalesForecast.ParentDoc.CheckInDate)) AS CheckInYear,
	|	SalesForecast.ParentDoc.RoomRateType.* AS RoomRateType,
	|	SalesForecast.ParentDoc.Room.* AS Room,
	|	SalesForecast.ParentDoc.RoomType.* AS RoomType,
	|	SalesForecast.ParentDoc.AccommodationType.* AS AccommodationType,
	|	SalesForecast.ParentDoc.RoomQuota.* AS RoomQuota,
	|	SalesForecast.ParentDoc.Discount AS Discount,
	|	SalesForecast.ParentDoc.DiscountType.* AS DiscountType,
	|	SalesForecast.ParentDoc.DiscountCard.* AS DiscountCard,
	|	SalesForecast.ParentDoc.ClientType.* AS ClientType,
	|	SalesForecast.ParentDoc.SourceOfBusiness.* AS SourceOfBusiness,
	|	SalesForecast.ParentDoc.MarketingCode.* AS MarketingCode,
	|	SalesForecast.ParentDoc.TripPurpose.* AS TripPurpose,
	|	SalesForecast.ParentDoc.HotelProduct.* AS HotelProduct,
	|	SalesForecast.ParentDoc.AgentCommissionType.* AS AgentCommissionType,
	|	SalesForecast.ParentDoc.AgentCommission AS AgentCommission,
	|	SalesForecast.ParentDoc.Author.* AS Author,
	|	SalesForecast.RoomsRented AS RoomsRented,
	|	SalesForecast.RoomsRentedAccommodation AS RoomsRentedAccommodation,
	|	SalesForecast.RoomsRentedReservation AS RoomsRentedReservation,
	|	SalesForecast.BedsRented AS BedsRented,
	|	SalesForecast.BedsRentedAccommodation AS BedsRentedAccommodation,
	|	SalesForecast.BedsRentedReservation AS BedsRentedReservation,
	|	SalesForecast.AdditionalBedsRented AS AdditionalBedsRented,
	|	SalesForecast.AdditionalBedsRentedAccommodation AS AdditionalBedsRentedAccommodation,
	|	SalesForecast.AdditionalBedsRentedReservation AS AdditionalBedsRentedReservation,
	|	SalesForecast.GuestDays AS GuestDays,
	|	SalesForecast.GuestDaysAccommodation AS GuestDaysAccommodation,
	|	SalesForecast.GuestDaysReservation AS GuestDaysReservation,
	|	SalesForecast.GuestsCheckedIn AS GuestsCheckedIn,
	|	SalesForecast.GuestsCheckedInAccommodation AS GuestsCheckedInAccommodation,
	|	SalesForecast.GuestsCheckedInReservation AS GuestsCheckedInReservation,
	|	SalesForecast.RoomsCheckedIn AS RoomsCheckedIn,
	|	SalesForecast.RoomsCheckedInAccommodation AS RoomsCheckedInAccommodation,
	|	SalesForecast.RoomsCheckedInReservation AS RoomsCheckedInReservation,
	|	SalesForecast.BedsCheckedIn AS BedsCheckedIn,
	|	SalesForecast.BedsCheckedInAccommodation AS BedsCheckedInAccommodation,
	|	SalesForecast.BedsCheckedInReservation AS BedsCheckedInReservation,
	|	SalesForecast.AdditionalBedsCheckedIn AS AdditionalBedsCheckedIn,
	|	SalesForecast.AdditionalBedsCheckedInAccommodation AS AdditionalBedsCheckedInAccommodation,
	|	SalesForecast.AdditionalBedsCheckedInReservation AS AdditionalBedsCheckedInReservation,
	|	SalesForecast.Quantity AS Quantity,
	|	SalesForecast.QuantityAccommodation AS QuantityAccommodation,
	|	SalesForecast.QuantityReservation AS QuantityReservation,
	|	SalesForecast.Sales AS Sales,
	|	SalesForecast.SalesAccommodation AS SalesAccommodation,
	|	SalesForecast.SalesReservation AS SalesReservation,
	|	SalesForecast.SalesWithoutVAT AS SalesWithoutVAT,
	|	SalesForecast.SalesWithoutVATAccommodation AS SalesWithoutVATAccommodation,
	|	SalesForecast.SalesWithoutVATReservation AS SalesWithoutVATReservation,
	|	SalesForecast.RoomRevenue AS RoomRevenue,
	|	SalesForecast.RoomRevenueAccommodation AS RoomRevenueAccommodation,
	|	SalesForecast.RoomRevenueReservation AS RoomRevenueReservation,
	|	SalesForecast.RoomRevenueWithoutVAT AS RoomRevenueWithoutVAT,
	|	SalesForecast.RoomRevenueWithoutVATAccommodation AS RoomRevenueWithoutVATAccommodation,
	|	SalesForecast.RoomRevenueWithoutVATReservation AS RoomRevenueWithoutVATReservation,
	|	SalesForecast.ExtraBedRevenue AS ExtraBedRevenue,
	|	SalesForecast.ExtraBedRevenueAccommodation AS ExtraBedRevenueAccommodation,
	|	SalesForecast.ExtraBedRevenueReservation AS ExtraBedRevenueReservation,
	|	SalesForecast.ExtraBedRevenueWithoutVAT AS ExtraBedRevenueWithoutVAT,
	|	SalesForecast.ExtraBedRevenueWithoutVATAccommodation AS ExtraBedRevenueWithoutVATAccommodation,
	|	SalesForecast.ExtraBedRevenueWithoutVATReservation AS ExtraBedRevenueWithoutVATReservation,
	|	SalesForecast.MainBedsRevenue AS MainBedsRevenue,
	|	SalesForecast.MainBedsRevenueAccommodation AS MainBedsRevenueAccommodation,
	|	SalesForecast.MainBedsRevenueReservation AS MainBedsRevenueReservation,
	|	SalesForecast.MainBedsRevenueWithoutVAT AS MainBedsRevenueWithoutVAT,
	|	SalesForecast.MainBedsRevenueWithoutVATAccommodation AS MainBedsRevenueWithoutVATAccommodation,
	|	SalesForecast.MainBedsRevenueWithoutVATReservation AS MainBedsRevenueWithoutVATReservation,
	|	SalesForecast.CommissionSum AS CommissionSum,
	|	SalesForecast.CommissionSumAccommodation AS CommissionSumAccommodation,
	|	SalesForecast.CommissionSumReservation AS CommissionSumReservation,
	|	SalesForecast.CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|	SalesForecast.CommissionSumWithoutVATAccommodation AS CommissionSumWithoutVATAccommodation,
	|	SalesForecast.CommissionSumWithoutVATReservation AS CommissionSumWithoutVATReservation,
	|	SalesForecast.DiscountSum AS DiscountSum,
	|	SalesForecast.DiscountSumAccommodation AS DiscountSumAccommodation,
	|	SalesForecast.DiscountSumReservation AS DiscountSumReservation,
	|	SalesForecast.DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|	SalesForecast.DiscountSumWithoutVATAccommodation AS DiscountSumWithoutVATAccommodation,
	|	SalesForecast.DiscountSumWithoutVATReservation AS DiscountSumWithoutVATReservation,
	|	SalesForecast.RoomPrice AS RoomPrice}
	|
	|ORDER BY
	|	Hotel,
	|	ReportingCurrency,
	|	Customer,
	|	Contract
	|{ORDER BY
	|	Hotel.* AS Hotel,
	|	SalesForecast.Company.* AS Company,
	|	ReportingCurrency.* AS ReportingCurrency,
	|	SalesForecast.Agent.* AS Agent,
	|	SalesForecast.PaymentMethod.* AS PaymentMethod,
	|	Customer.* AS Customer,
	|	Contract.* AS Contract,
	|	SalesForecast.RoomRate.* AS RoomRate,
	|	SalesForecast.GuestGroup.* AS GuestGroup,
	|	SalesForecast.ParentDoc.* AS ParentDoc,
	|	SalesForecast.Client.* AS Client,
	|	SalesForecast.Service.* AS Service,
	|	SalesForecast.AccountingDate AS AccountingDate,
	|	(HOUR(SalesForecast.AccountingDate)) AS AccountingHour,
	|	(DAY(SalesForecast.AccountingDate)) AS AccountingDay,
	|	(WEEK(SalesForecast.AccountingDate)) AS AccountingWeek,
	|	(MONTH(SalesForecast.AccountingDate)) AS AccountingMonth,
	|	(QUARTER(SalesForecast.AccountingDate)) AS AccountingQuarter,
	|	(YEAR(SalesForecast.AccountingDate)) AS AccountingYear,
	|	(BEGINOFPERIOD(SalesForecast.ParentDoc.CheckInDate, DAY)) AS CheckInDate,
	|	(HOUR(SalesForecast.ParentDoc.CheckInDate)) AS CheckInHour,
	|	(DAY(SalesForecast.ParentDoc.CheckInDate)) AS CheckInDay,
	|	(WEEK(SalesForecast.ParentDoc.CheckInDate)) AS CheckInWeek,
	|	(MONTH(SalesForecast.ParentDoc.CheckInDate)) AS CheckInMonth,
	|	(QUARTER(SalesForecast.ParentDoc.CheckInDate)) AS CheckInQuarter,
	|	(YEAR(SalesForecast.ParentDoc.CheckInDate)) AS CheckInYear,
	|	SalesForecast.ParentDoc.RoomRateType.* AS RoomRateType,
	|	SalesForecast.ParentDoc.Room.* AS Room,
	|	SalesForecast.ParentDoc.RoomType.* AS RoomType,
	|	SalesForecast.ParentDoc.AccommodationType.* AS AccommodationType,
	|	SalesForecast.ParentDoc.RoomQuota.* AS RoomQuota,
	|	SalesForecast.ParentDoc.Discount AS Discount,
	|	SalesForecast.ParentDoc.DiscountType.* AS DiscountType,
	|	SalesForecast.ParentDoc.DiscountCard.* AS DiscountCard,
	|	SalesForecast.ParentDoc.ClientType.* AS ClientType,
	|	SalesForecast.ParentDoc.SourceOfBusiness.* AS SourceOfBusiness,
	|	SalesForecast.ParentDoc.MarketingCode.* AS MarketingCode,
	|	SalesForecast.ParentDoc.TripPurpose.* AS TripPurpose,
	|	SalesForecast.ParentDoc.HotelProduct.* AS HotelProduct,
	|	SalesForecast.ParentDoc.AgentCommissionType.* AS AgentCommissionType,
	|	SalesForecast.ParentDoc.AgentCommission AS AgentCommission,
	|	SalesForecast.ParentDoc.Author.* AS Author,
	|	RoomsRented AS RoomsRented,
	|	RoomsRentedAccommodation AS RoomsRentedAccommodation,
	|	RoomsRentedReservation AS RoomsRentedReservation,
	|	BedsRented AS BedsRented,
	|	BedsRentedAccommodation AS BedsRentedAccommodation,
	|	BedsRentedReservation AS BedsRentedReservation,
	|	AdditionalBedsRented AS AdditionalBedsRented,
	|	AdditionalBedsRentedAccommodation AS AdditionalBedsRentedAccommodation,
	|	AdditionalBedsRentedReservation AS AdditionalBedsRentedReservation,
	|	GuestDays AS GuestDays,
	|	GuestDaysAccommodation AS GuestDaysAccommodation,
	|	GuestDaysReservation AS GuestDaysReservation,
	|	GuestsCheckedIn AS GuestsCheckedIn,
	|	GuestsCheckedInAccommodation AS GuestsCheckedInAccommodation,
	|	GuestsCheckedInReservation AS GuestsCheckedInReservation,
	|	RoomsCheckedIn AS RoomsCheckedIn,
	|	RoomsCheckedInAccommodation AS RoomsCheckedInAccommodation,
	|	RoomsCheckedInReservation AS RoomsCheckedInReservation,
	|	BedsCheckedIn AS BedsCheckedIn,
	|	BedsCheckedInAccommodation AS BedsCheckedInAccommodation,
	|	BedsCheckedInReservation AS BedsCheckedInReservation,
	|	AdditionalBedsCheckedIn AS AdditionalBedsCheckedIn,
	|	AdditionalBedsCheckedInAccommodation AS AdditionalBedsCheckedInAccommodation,
	|	AdditionalBedsCheckedInReservation AS AdditionalBedsCheckedInReservation,
	|	Quantity AS Quantity,
	|	QuantityAccommodation AS QuantityAccommodation,
	|	QuantityReservation AS QuantityReservation,
	|	Sales AS Sales,
	|	SalesAccommodation AS SalesAccommodation,
	|	SalesReservation AS SalesReservation,
	|	SalesWithoutVAT AS SalesWithoutVAT,
	|	SalesWithoutVATAccommodation AS SalesWithoutVATAccommodation,
	|	SalesWithoutVATReservation AS SalesWithoutVATReservation,
	|	RoomRevenue AS RoomRevenue,
	|	RoomRevenueAccommodation AS RoomRevenueAccommodation,
	|	RoomRevenueReservation AS RoomRevenueReservation,
	|	RoomRevenueWithoutVAT AS RoomRevenueWithoutVAT,
	|	RoomRevenueWithoutVATAccommodation AS RoomRevenueWithoutVATAccommodation,
	|	RoomRevenueWithoutVATReservation AS RoomRevenueWithoutVATReservation,
	|	ExtraBedRevenue AS ExtraBedRevenue,
	|	ExtraBedRevenueAccommodation AS ExtraBedRevenueAccommodation,
	|	ExtraBedRevenueReservation AS ExtraBedRevenueReservation,
	|	ExtraBedRevenueWithoutVAT AS ExtraBedRevenueWithoutVAT,
	|	ExtraBedRevenueWithoutVATAccommodation AS ExtraBedRevenueWithoutVATAccommodation,
	|	ExtraBedRevenueWithoutVATReservation AS ExtraBedRevenueWithoutVATReservation,
	|	MainBedsRevenue AS MainBedsRevenue,
	|	MainBedsRevenueAccommodation AS MainBedsRevenueAccommodation,
	|	MainBedsRevenueReservation AS MainBedsRevenueReservation,
	|	MainBedsRevenueWithoutVAT AS MainBedsRevenueWithoutVAT,
	|	MainBedsRevenueWithoutVATAccommodation AS MainBedsRevenueWithoutVATAccommodation,
	|	MainBedsRevenueWithoutVATReservation AS MainBedsRevenueWithoutVATReservation,
	|	CommissionSum AS CommissionSum,
	|	CommissionSumAccommodation AS CommissionSumAccommodation,
	|	CommissionSumReservation AS CommissionSumReservation,
	|	CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|	CommissionSumWithoutVATAccommodation AS CommissionSumWithoutVATAccommodation,
	|	CommissionSumWithoutVATReservation AS CommissionSumWithoutVATReservation,
	|	DiscountSum AS DiscountSum,
	|	DiscountSumAccommodation AS DiscountSumAccommodation,
	|	DiscountSumReservation AS DiscountSumReservation,
	|	DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|	DiscountSumWithoutVATAccommodation AS DiscountSumWithoutVATAccommodation,
	|	DiscountSumWithoutVATReservation AS DiscountSumWithoutVATReservation,
	|	RoomPrice}
	|TOTALS
	|	SUM(RoomsRented),
	|	SUM(RoomsRentedAccommodation),
	|	SUM(RoomsRentedReservation),
	|	SUM(BedsRented),
	|	SUM(BedsRentedAccommodation),
	|	SUM(BedsRentedReservation),
	|	SUM(AdditionalBedsRented),
	|	SUM(AdditionalBedsRentedAccommodation),
	|	SUM(AdditionalBedsRentedReservation),
	|	SUM(GuestDays),
	|	SUM(GuestDaysAccommodation),
	|	SUM(GuestDaysReservation),
	|	SUM(GuestsCheckedIn),
	|	SUM(GuestsCheckedInAccommodation),
	|	SUM(GuestsCheckedInReservation),
	|	SUM(RoomsCheckedIn),
	|	SUM(RoomsCheckedInAccommodation),
	|	SUM(RoomsCheckedInReservation),
	|	SUM(BedsCheckedIn),
	|	SUM(BedsCheckedInAccommodation),
	|	SUM(BedsCheckedInReservation),
	|	SUM(AdditionalBedsCheckedIn),
	|	SUM(AdditionalBedsCheckedInAccommodation),
	|	SUM(AdditionalBedsCheckedInReservation),
	|	SUM(Quantity),
	|	SUM(QuantityAccommodation),
	|	SUM(QuantityReservation),
	|	SUM(Sales),
	|	SUM(SalesAccommodation),
	|	SUM(SalesReservation),
	|	SUM(SalesWithoutVAT),
	|	SUM(SalesWithoutVATAccommodation),
	|	SUM(SalesWithoutVATReservation),
	|	SUM(RoomRevenue),
	|	SUM(RoomRevenueAccommodation),
	|	SUM(RoomRevenueReservation),
	|	SUM(RoomRevenueWithoutVAT),
	|	SUM(RoomRevenueWithoutVATAccommodation),
	|	SUM(RoomRevenueWithoutVATReservation),
	|	SUM(ExtraBedRevenue),
	|	SUM(ExtraBedRevenueAccommodation),
	|	SUM(ExtraBedRevenueReservation),
	|	SUM(ExtraBedRevenueWithoutVAT),
	|	SUM(ExtraBedRevenueWithoutVATAccommodation),
	|	SUM(ExtraBedRevenueWithoutVATReservation),
	|	SUM(MainBedsRevenue),
	|	SUM(MainBedsRevenueAccommodation),
	|	SUM(MainBedsRevenueReservation),
	|	SUM(MainBedsRevenueWithoutVAT),
	|	SUM(MainBedsRevenueWithoutVATAccommodation),
	|	SUM(MainBedsRevenueWithoutVATReservation),
	|	SUM(CommissionSum),
	|	SUM(CommissionSumAccommodation),
	|	SUM(CommissionSumReservation),
	|	SUM(CommissionSumWithoutVAT),
	|	SUM(CommissionSumWithoutVATAccommodation),
	|	SUM(CommissionSumWithoutVATReservation),
	|	SUM(DiscountSum),
	|	SUM(DiscountSumAccommodation),
	|	SUM(DiscountSumReservation),
	|	SUM(DiscountSumWithoutVAT),
	|	SUM(DiscountSumWithoutVATAccommodation),
	|	SUM(DiscountSumWithoutVATReservation),
	|	MAX(RoomPrice)
	|BY
	|	OVERALL,
	|	Hotel,
	|	ReportingCurrency,
	|	Customer,
	|	Contract
	|{TOTALS BY
	|	Hotel.* AS Hotel,
	|	SalesForecast.Company.* AS Company,
	|	ReportingCurrency.* AS ReportingCurrency,
	|	SalesForecast.Agent.* AS Agent,
	|	SalesForecast.PaymentMethod.* AS PaymentMethod,
	|	Customer.* AS Customer,
	|	Contract.* AS Contract,
	|	SalesForecast.RoomRate.* AS RoomRate,
	|	SalesForecast.GuestGroup.* AS GuestGroup,
	|	SalesForecast.ParentDoc.* AS ParentDoc,
	|	SalesForecast.Client.* AS Client,
	|	SalesForecast.Service.* AS Service,
	|	SalesForecast.AccountingDate AS AccountingDate,
	|	(HOUR(SalesForecast.AccountingDate)) AS AccountingHour,
	|	(DAY(SalesForecast.AccountingDate)) AS AccountingDay,
	|	(WEEK(SalesForecast.AccountingDate)) AS AccountingWeek,
	|	(MONTH(SalesForecast.AccountingDate)) AS AccountingMonth,
	|	(QUARTER(SalesForecast.AccountingDate)) AS AccountingQuarter,
	|	(YEAR(SalesForecast.AccountingDate)) AS AccountingYear,
	|	(BEGINOFPERIOD(SalesForecast.ParentDoc.CheckInDate, DAY)) AS CheckInDate,
	|	(HOUR(SalesForecast.ParentDoc.CheckInDate)) AS CheckInHour,
	|	(DAY(SalesForecast.ParentDoc.CheckInDate)) AS CheckInDay,
	|	(WEEK(SalesForecast.ParentDoc.CheckInDate)) AS CheckInWeek,
	|	(MONTH(SalesForecast.ParentDoc.CheckInDate)) AS CheckInMonth,
	|	(QUARTER(SalesForecast.ParentDoc.CheckInDate)) AS CheckInQuarter,
	|	(YEAR(SalesForecast.ParentDoc.CheckInDate)) AS CheckInYear,
	|	RoomPrice,
	|	SalesForecast.ParentDoc.RoomRateType.* AS RoomRateType,
	|	SalesForecast.ParentDoc.Room.* AS Room,
	|	SalesForecast.ParentDoc.RoomType.* AS RoomType,
	|	SalesForecast.ParentDoc.AccommodationType.* AS AccommodationType,
	|	SalesForecast.ParentDoc.RoomQuota.* AS RoomQuota,
	|	SalesForecast.ParentDoc.Discount AS Discount,
	|	SalesForecast.ParentDoc.DiscountType.* AS DiscountType,
	|	SalesForecast.ParentDoc.DiscountCard.* AS DiscountCard,
	|	SalesForecast.ParentDoc.ClientType.* AS ClientType,
	|	SalesForecast.ParentDoc.SourceOfBusiness.* AS SourceOfBusiness,
	|	SalesForecast.ParentDoc.MarketingCode.* AS MarketingCode,
	|	SalesForecast.ParentDoc.TripPurpose.* AS TripPurpose,
	|	SalesForecast.ParentDoc.HotelProduct.* AS HotelProduct,
	|	SalesForecast.ParentDoc.AgentCommissionType.* AS AgentCommissionType,
	|	SalesForecast.ParentDoc.AgentCommission AS AgentCommission,
	|	SalesForecast.ParentDoc.Author.* AS Author}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Customer sales forecast';RU='Прогноз продаж по контрагентам';de='Verkaufsprognose nach Vertragspartnern'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
Function pmIsResource(pName) Export
	If pName = "RoomsRented" 
	   Or pName = "RoomsRentedAccommodation" 
	   Or pName = "RoomsRentedReservation" 
	   Or pName = "BedsRented" 
	   Or pName = "BedsRentedAccommodation" 
	   Or pName = "BedsRentedReservation" 
	   Or pName = "AdditionalBedsRented" 
	   Or pName = "AdditionalBedsRentedAccommodation" 
	   Or pName = "AdditionalBedsRentedReservation" 
	   Or pName = "GuestsCheckedIn" 
	   Or pName = "GuestsCheckedInAccommodation" 
	   Or pName = "GuestsCheckedInReservation" 
	   Or pName = "RoomsCheckedIn" 
	   Or pName = "RoomsCheckedInAccommodation" 
	   Or pName = "RoomsCheckedInReservation" 
	   Or pName = "BedsCheckedIn" 
	   Or pName = "BedsCheckedInAccommodation" 
	   Or pName = "BedsCheckedInReservation" 
	   Or pName = "AdditionalBedsCheckedIn" 
	   Or pName = "AdditionalBedsCheckedInAccommodation" 
	   Or pName = "AdditionalBedsCheckedInReservation" 
	   Or pName = "Quantity" 
	   Or pName = "QuantityAccommodation" 
	   Or pName = "QuantityReservation" 
	   Or pName = "GuestDays" 
	   Or pName = "GuestDaysAccommodation" 
	   Or pName = "GuestDaysReservation" 
	   Or pName = "Sales" 
	   Or pName = "SalesAccommodation" 
	   Or pName = "SalesReservation" 
	   Or pName = "SalesWithoutVAT" 
	   Or pName = "SalesWithoutVATAccommodation" 
	   Or pName = "SalesWithoutVATReservation" 
	   Or pName = "RoomRevenue" 
	   Or pName = "RoomRevenueAccommodation" 
	   Or pName = "RoomRevenueReservation" 
	   Or pName = "RoomRevenueWithoutVAT" 
	   Or pName = "RoomRevenueWithoutVATAccommodation" 
	   Or pName = "RoomRevenueWithoutVATReservation" 
	   Or pName = "ExtraBedRevenue" 
	   Or pName = "ExtraBedRevenueAccommodation" 
	   Or pName = "ExtraBedRevenueReservation" 
	   Or pName = "ExtraBedRevenueWithoutVAT" 
	   Or pName = "ExtraBedRevenueWithoutVATAccommodation" 
	   Or pName = "ExtraBedRevenueWithoutVATReservation" 
	   Or pName = "MainBedsRevenue" 
	   Or pName = "MainBedsRevenueAccommodation" 
	   Or pName = "MainBedsRevenueReservation" 
	   Or pName = "MainBedsRevenueWithoutVAT" 
	   Or pName = "MainBedsRevenueWithoutVATAccommodation" 
	   Or pName = "MainBedsRevenueWithoutVATReservation" 
	   Or pName = "CommissionSum" 
	   Or pName = "CommissionSumAccommodation" 
	   Or pName = "CommissionSumReservation" 
	   Or pName = "CommissionSumWithoutVAT" 
	   Or pName = "CommissionSumWithoutVATAccommodation" 
	   Or pName = "CommissionSumWithoutVATReservation" 
	   Or pName = "DiscountSum" 
	   Or pName = "DiscountSumAccommodation" 
	   Or pName = "DiscountSumReservation" 
	   Or pName = "DiscountSumWithoutVAT" 
	   Or pName = "DiscountSumWithoutVATAccommodation" 
	   Or pName = "DiscountSumWithoutVATReservation" Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // pmIsResource

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
