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
	If Not ValueIsFilled(PeriodCheckType) Then
		PeriodCheckType = Enums.SalesReportsPeriodCheckTypes.ByChargeDates;
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
	If PeriodCheckType = Enums.SalesReportsPeriodCheckTypes.ByCheckInDates Then
		vParamPresentation = vParamPresentation + NStr("en='By checked-in guests';ru='По заезду гостей';de='Nach Anreise der Gäste'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodCheckType = Enums.SalesReportsPeriodCheckTypes.ByCheckOutDates Then
		vParamPresentation = vParamPresentation + NStr("en='By checked-out guests';ru='По выезду гостей';de='Nach Abreise der Gäste'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodCheckType = Enums.SalesReportsPeriodCheckTypes.ByBookingDates Then
		vParamPresentation = vParamPresentation + NStr("en='By booking dates';ru='По датам бронирования';de='Nach Buchungsdaten'") + 
		                     ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(DateFrom) And Not ValueIsFilled(DateTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Выезд гостей в периоде c '; en = 'Guests checked-out in period from '; de = 'Abreise Periode von '") + 
		                     Format(DateFrom, "DF=dd.MM.yyyy") + 
		                     ";" + Chars.LF;
	ElsIf Not ValueIsFilled(DateFrom) And ValueIsFilled(DateTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Выезд гостей в периоде по '; en = 'Guests checked-out in period to '; de = 'Abreise Periode zu '") + 
		                     Format(DateTo, "DF=dd.MM.yyyy") + 
		                     ";" + Chars.LF;
	ElsIf DateFrom = DateTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Выезд гостей в '; en = 'Guests checked-out at '; de = 'Abreise Periode '") + 
		                     Format(DateFrom, "DF=dd.MM.yyyy") + 
		                     ";" + Chars.LF;
	ElsIf DateFrom < DateTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период выезда гостей '; en = 'Guests checked-out period '; de = 'Abreise Periode '") + PeriodPresentation(DateFrom, DateTo, cmLocalizationCode()) + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("en='Check-out period is wrong!';ru='Неправильно задан период выезда!';de='Der Abreise Zeitraum wurde falsch eingetragen!'") + 
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
		vParamPresentation = vParamPresentation + NStr("en='Guest group ';ru='Группа ';de='Gruppe '") + 
							 TrimAll(TrimAll(GuestGroup.Code) + " " + TrimAll(GuestGroup.Description)) + 
							 ";" + Chars.LF;
	EndIf;							 
	If ValueIsFilled(Event) Then
		vParamPresentation = vParamPresentation + NStr("en='Event ';ru='Мероприятие ';de='Veranstaltung '") + 
							 TrimAll(Event.Description) + 
							 ";" + Chars.LF;
	EndIf;							 
	If ValueIsFilled(Agent) Then
		If Not Agent.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Agent ';ru='Агент ';de='Vertreter '") + 
			                     TrimAll(Agent.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Agents folder ';ru='Группа агентов ';de='Gruppe Vertreter '") + 
			                     TrimAll(Agent.Description) + 
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
	If ShowForecastByReservations Then
		vParamPresentation = vParamPresentation + NStr("en='With forecast reservation sales';ru='С учетом планируемых продаж по брони';de='Unter Berücksichtigung geplanter Verkäufe aus Buchung'") + 
		                     ";" + Chars.LF;
	EndIf;
	If AgentCommission > 0 Then
		vParamPresentation = vParamPresentation + NStr("en='Commission calculated by ';ru='Расчет комиссии выполнен по ';de='Kommission berechnet von '") + Format(AgentCommission, "ND=6; NFD=2; NZ=; NG=") + 
		                     "%;" + Chars.LF;
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
Procedure pmGenerate(pSpreadsheet) Export
	Var vTemplateAttributes;
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
	
	// Initialize report builder query generator attributes
	ReportBuilder.PresentationAdding = PresentationAdditionType.Add;
	
	// Fill report parameters
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qByCheckInDates", False);
	ReportBuilder.Parameters.Insert("qByCheckOutDates", False);
	ReportBuilder.Parameters.Insert("qByBookingDates", False);
	If PeriodCheckType = Enums.SalesReportsPeriodCheckTypes.ByCheckInDates Then
		ReportBuilder.Parameters.Insert("qByCheckInDates", True);
	EndIf;
	If PeriodCheckType = Enums.SalesReportsPeriodCheckTypes.ByCheckOutDates Then
		ReportBuilder.Parameters.Insert("qByCheckOutDates", True);
	EndIf;
	If PeriodCheckType = Enums.SalesReportsPeriodCheckTypes.ByBookingDates Then
		ReportBuilder.Parameters.Insert("qByBookingDates", True);
	EndIf;
	vForecastStartDate = tcOnServer.GetForecastStartDate(Hotel);
	If PeriodCheckType = Enums.SalesReportsPeriodCheckTypes.ByCheckInDates Or 
	   PeriodCheckType = Enums.SalesReportsPeriodCheckTypes.ByCheckOutDates Or
	   PeriodCheckType = Enums.SalesReportsPeriodCheckTypes.ByBookingDates Then
		ReportBuilder.Parameters.Insert("qServicesPeriodFrom", '00010101');
		ReportBuilder.Parameters.Insert("qServicesPeriodTo", '39991231');
		ReportBuilder.Parameters.Insert("qForecastPeriodFrom", vForecastStartDate);
		ReportBuilder.Parameters.Insert("qForecastPeriodTo", '39991231');
	Else
		ReportBuilder.Parameters.Insert("qServicesPeriodFrom", PeriodFrom);
		ReportBuilder.Parameters.Insert("qServicesPeriodTo", PeriodTo);
		ReportBuilder.Parameters.Insert("qForecastPeriodFrom", Max(BegOfDay(PeriodFrom), vForecastStartDate));
		ReportBuilder.Parameters.Insert("qForecastPeriodTo", ?(ValueIsFilled(PeriodTo), Max(PeriodTo, EndOfDay(vForecastStartDate-24*3600)), '00010101'));
	EndIf;
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qDateFrom", BegOfDay(DateFrom));
	ReportBuilder.Parameters.Insert("qDateTo", EndOfDay(DateTo));
	ReportBuilder.Parameters.Insert("qCustomer", Customer);
	ReportBuilder.Parameters.Insert("qCustomerIsEmpty", Not ValueIsFilled(Customer));
	ReportBuilder.Parameters.Insert("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	ReportBuilder.Parameters.Insert("qContract", Contract);
	ReportBuilder.Parameters.Insert("qContractIsEmpty", Not ValueIsFilled(Contract));
	ReportBuilder.Parameters.Insert("qGuestGroup", GuestGroup);
	ReportBuilder.Parameters.Insert("qGuestGroupIsEmpty", Not ValueIsFilled(GuestGroup));
	ReportBuilder.Parameters.Insert("qAgent", Agent);
	ReportBuilder.Parameters.Insert("qAgentIsEmpty", Not ValueIsFilled(Agent));
	ReportBuilder.Parameters.Insert("qAgentCommission", AgentCommission);
	ReportBuilder.Parameters.Insert("qByDays", ByDays);
	ReportBuilder.Parameters.Insert("qEmptyDate", '00010101');
	ReportBuilder.Parameters.Insert("qEndOfTime", '39991231');
	ReportBuilder.Parameters.Insert("qShowForecastByReservations", ShowForecastByReservations);
	ReportBuilder.Parameters.Insert("qShowMainRoomGuestsOnly", ShowMainRoomGuestsOnly);
	ReportBuilder.Parameters.Insert("qEvent", Event);
	ReportBuilder.Parameters.Insert("qEventIsEmpty", Not ValueIsFilled(Event));
	
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
	
	ReportBuilder.Parameters.Insert("qHideRowsNotInTheCheckOutPeriod", HideRowsNotInTheCheckOutPeriod);

	ReportBuilder.Parameters.Insert("qCustomAttribute1", CustomAttribute1);
	ReportBuilder.Parameters.Insert("qCustomAttribute2", CustomAttribute2);
	ReportBuilder.Parameters.Insert("qCustomAttribute3", CustomAttribute3);
	
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
EndProcedure // pmGenerate
	
// -----------------------------------------------------------------------------
Procedure pmInitializeReportBuilder() Export
	ReportBuilder = New ReportBuilder();
	
	// Initialize default query text
	QueryText = 
	"SELECT
	|	CustomerTurnovers.Company AS Company,
	|	CustomerTurnovers.Hotel AS Hotel,
	|	CustomerTurnovers.ReportingCurrency AS ReportingCurrency,
	|	CustomerTurnovers.Agent AS Agent,
	|	CustomerTurnovers.Customer AS Customer,
	|	CustomerTurnovers.Contract AS Contract,
	|	CustomerTurnovers.GuestGroup AS GuestGroup,
	|	CustomerTurnovers.ParentDoc AS ParentDoc,
	|	CustomerTurnovers.Client AS Client,
	|	CustomerTurnovers.ClientType AS ClientType,
	|	CustomerTurnovers.TripPurpose AS TripPurpose,
	|	CustomerTurnovers.SourceOfBusiness AS SourceOfBusiness,
	|	CustomerTurnovers.MarketingCode AS MarketingCode,
	|	CustomerTurnovers.CheckInDate AS CheckInDate,
	|	CustomerTurnovers.CheckOutDate AS CheckOutDate,
	|	CustomerTurnovers.AccommodationType AS AccommodationType,
	|	CustomerTurnovers.Status AS Status,
	|	CustomerTurnovers.Room AS Room,
	|	CustomerTurnovers.RoomType AS RoomType,
	|	CustomerTurnovers.Resource AS Resource,
	|	CustomerTurnovers.Service AS Service,
	|	CustomerTurnovers.AccountingDate AS AccountingDate,
	|	CustomerTurnovers.Sales AS Sales,
	|	CustomerTurnovers.SalesWithoutVAT AS SalesWithoutVAT,
	|	CustomerTurnovers.RoomRevenue AS RoomRevenue,
	|	CustomerTurnovers.RoomRevenueWithoutVAT AS RoomRevenueWithoutVAT,
	|	CustomerTurnovers.ExtraBedRevenue AS ExtraBedRevenue,
	|	CustomerTurnovers.ExtraBedRevenueWithoutVAT AS ExtraBedRevenueWithoutVAT,
	|	CustomerTurnovers.MainBedsRevenue AS MainBedsRevenue,
	|	CustomerTurnovers.MainBedsRevenueWithoutVAT AS MainBedsRevenueWithoutVAT,
	|	CustomerTurnovers.CommissionSum AS CommissionSum,
	|	CustomerTurnovers.CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|	CustomerTurnovers.CalculatedCommissionSum AS CalculatedCommissionSum,
	|	CustomerTurnovers.CalculatedCommissionSumWithoutVAT AS CalculatedCommissionSumWithoutVAT,
	|	CustomerTurnovers.SalesWithoutCommission AS SalesWithoutCommission,
	|	CustomerTurnovers.SalesWithoutCommissionWithoutVAT AS SalesWithoutCommissionWithoutVAT,
	|	CustomerTurnovers.Sales + CustomerTurnovers.DiscountSum - CustomerTurnovers.CalculatedCommissionSum AS SalesWithoutCalculatedCommission,
	|	CustomerTurnovers.SalesWithoutVAT + CustomerTurnovers.DiscountSumWithoutVAT - CustomerTurnovers.CalculatedCommissionSumWithoutVAT AS SalesWithoutCalculatedCommissionWithoutVAT,
	|	CustomerTurnovers.BruttoSales AS BruttoSales,
	|	CustomerTurnovers.BruttoSalesWithoutVAT AS BruttoSalesWithoutVAT,
	|	CustomerTurnovers.DiscountSum AS DiscountSum,
	|	CustomerTurnovers.DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|	CustomerTurnovers.RoomsRented AS RoomsRented,
	|	CustomerTurnovers.BedsRented AS BedsRented,
	|	CustomerTurnovers.AdditionalBedsRented AS AdditionalBedsRented,
	|	CustomerTurnovers.GuestDays AS GuestDays,
	|	CustomerTurnovers.GuestsCheckedIn AS GuestsCheckedIn,
	|	CustomerTurnovers.RoomsCheckedIn AS RoomsCheckedIn,
	|	CustomerTurnovers.BedsCheckedIn AS BedsCheckedIn,
	|	CustomerTurnovers.AdditionalBedsCheckedIn AS AdditionalBedsCheckedIn,
	|	CustomerTurnovers.Quantity AS Quantity,
	|	CustomerTurnovers.VATSum AS VATSum,
	|	CustomerTurnovers.RateSum AS RateSum
	|{SELECT
	|	Company.*,
	|	Hotel.*,
	|	ReportingCurrency.*,
	|	Agent.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	CustomerTurnovers.Folio.* AS Folio,
	|	CustomerTurnovers.VATRate.* AS VATRate,
	|	Client.*,
	|	ClientType.* AS ClientType,
	|	TripPurpose.* AS TripPurpose,
	|	SourceOfBusiness.* AS SourceOfBusiness,
	|	MarketingCode.* AS MarketingCode,
	|	CheckInDate,
	|	CheckOutDate,
	|	AccommodationType.*,
	|	Status.*,
	|	Room.*,
	|	RoomType.*,
	|	Resource.*,
	|	CustomerTurnovers.RoomRate.* AS RoomRate,
	|	CustomerTurnovers.PaymentMethod.* AS PaymentMethod,
	|	CustomerTurnovers.IsCheckedOutAtThePeriodSelected AS IsCheckedOutAtThePeriodSelected,
	|	ParentDoc.*,
	|	ForeignerRegistryRecords.ForeignerRegistryRecord.* AS ForeignerRegistryRecord,
	|	ReservationCustomAttributeValues1.CharacteristicValue.* AS CustomAttribute1,
	|	ReservationCustomAttributeValues2.CharacteristicValue.* AS CustomAttribute2,
	|	ReservationCustomAttributeValues3.CharacteristicValue.* AS CustomAttribute3,
	|	Service.*,
	|	AccountingDate,
	|	CustomerTurnovers.Price AS Price,
	|	Sales,
	|	SalesWithoutVAT,
	|	RoomRevenue,
	|	RoomRevenueWithoutVAT,
	|	ExtraBedRevenue,
	|	ExtraBedRevenueWithoutVAT,
	|	MainBedsRevenue,
	|	MainBedsRevenueWithoutVAT,
	|	CommissionSum,
	|	CommissionSumWithoutVAT,
	|	CalculatedCommissionSum,
	|	CalculatedCommissionSumWithoutVAT,
	|	SalesWithoutCommission,
	|	SalesWithoutCommissionWithoutVAT,
	|	SalesWithoutCalculatedCommission,
	|	SalesWithoutCalculatedCommissionWithoutVAT,
	|	BruttoSales,
	|	BruttoSalesWithoutVAT,
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
	|	Quantity,
	|	VATSum,
	|	RateSum}
	|FROM
	|	(SELECT
	|		CustomerSales.Company AS Company,
	|		CustomerSales.Hotel AS Hotel,
	|		CustomerSales.ReportingCurrency AS ReportingCurrency,
	|		CustomerSales.Agent AS Agent,
	|		CASE
	|			WHEN CustomerSales.Customer = &qEmptyCustomer
	|				THEN CustomerSales.Hotel.IndividualsCustomer
	|			ELSE CustomerSales.Customer
	|		END AS Customer,
	|		CASE
	|			WHEN CustomerSales.Customer = &qEmptyCustomer
	|				THEN CustomerSales.Hotel.IndividualsContract
	|			ELSE CustomerSales.Contract
	|		END AS Contract,
	|		CustomerSales.GuestGroup AS GuestGroup,
	|		CustomerSales.ParentDoc AS ParentDoc,
	|		CustomerSales.Folio AS Folio,
	|		CustomerSales.VATRate AS VATRate,
	|		CustomerSales.Service AS Service,
	|		CASE
	|			WHEN &qByDays
	|				THEN CustomerSales.AccountingDate
	|			ELSE &qEmptyDate
	|		END AS AccountingDate,
	|		CustomerSales.Client AS Client,
	|		CustomerSales.ClientType AS ClientType,
	|		CustomerSales.TripPurpose AS TripPurpose,
	|		CustomerSales.SourceOfBusiness AS SourceOfBusiness,
	|		CustomerSales.MarketingCode AS MarketingCode,
	|		CASE
	|			WHEN NOT CustomerSales.ParentDoc.CheckInDate IS NULL
	|				THEN CustomerSales.ParentDoc.CheckInDate
	|			WHEN NOT CustomerSales.ParentDoc.DateTimeFrom IS NULL
	|				THEN CustomerSales.ParentDoc.DateTimeFrom
	|			ELSE CustomerSales.Folio.DateTimeFrom
	|		END AS CheckInDate,
	|		CASE
	|			WHEN NOT CustomerSales.ParentDoc.CheckOutDate IS NULL
	|				THEN CustomerSales.ParentDoc.CheckOutDate
	|			WHEN NOT CustomerSales.ParentDoc.DateTimeTo IS NULL
	|				THEN CustomerSales.ParentDoc.DateTimeTo
	|			ELSE CustomerSales.Folio.DateTimeTo
	|		END AS CheckOutDate,
	|		CASE
	|			WHEN NOT CustomerSales.ParentDoc.AccommodationStatus IS NULL
	|				THEN CustomerSales.ParentDoc.AccommodationStatus
	|			WHEN NOT CustomerSales.ParentDoc.ReservationStatus IS NULL
	|				THEN CustomerSales.ParentDoc.ReservationStatus
	|			ELSE CustomerSales.ParentDoc.ResourceReservationStatus
	|		END AS Status,
	|		CustomerSales.AccommodationType AS AccommodationType,
	|		CustomerSales.Room AS Room,
	|		CustomerSales.RoomType AS RoomType,
	|		CustomerSales.Resource AS Resource,
	|		CustomerSales.RoomRate AS RoomRate,
	|		CustomerSales.PaymentMethod AS PaymentMethod,
	|		CASE
	|			WHEN CustomerSales.Quantity = 0
	|				THEN CustomerSales.Sales
	|			ELSE CAST(CustomerSales.Sales / CustomerSales.Quantity AS NUMBER(17, 2))
	|		END AS Price,
	|		CASE
	|			WHEN NOT CustomerSales.ParentDoc.CheckOutDate IS NULL
	|					AND CustomerSales.ParentDoc.CheckOutDate <= &qDateTo
	|					AND CustomerSales.ParentDoc.CheckOutDate >= &qDateFrom
	|					AND CustomerSales.ParentDoc.CheckOutDate > &qEmptyDate
	|				THEN TRUE
	|			WHEN NOT CustomerSales.ParentDoc.DateTimeTo IS NULL
	|					AND CustomerSales.ParentDoc.DateTimeTo <= &qDateTo
	|					AND CustomerSales.ParentDoc.DateTimeTo >= &qDateFrom
	|					AND CustomerSales.ParentDoc.DateTimeTo > &qEmptyDate
	|				THEN TRUE
	|			WHEN NOT CustomerSales.Folio.DateTimeTo IS NULL
	|					AND CustomerSales.Folio.DateTimeTo <= &qDateTo
	|					AND CustomerSales.Folio.DateTimeTo >= &qDateFrom
	|					AND CustomerSales.Folio.DateTimeTo > &qEmptyDate
	|				THEN TRUE
	|			ELSE FALSE
	|		END AS IsCheckedOutAtThePeriodSelected,
	|		SUM(CustomerSales.Sales) AS Sales,
	|		SUM(CustomerSales.SalesWithoutVAT) AS SalesWithoutVAT,
	|		SUM(CustomerSales.RoomRevenue) AS RoomRevenue,
	|		SUM(CustomerSales.RoomRevenueWithoutVAT) AS RoomRevenueWithoutVAT,
	|		SUM(CustomerSales.ExtraBedRevenue) AS ExtraBedRevenue,
	|		SUM(CustomerSales.ExtraBedRevenueWithoutVAT) AS ExtraBedRevenueWithoutVAT,
	|		SUM(CustomerSales.RoomRevenue) - SUM(CustomerSales.ExtraBedRevenue) AS MainBedsRevenue,
	|		SUM(CustomerSales.RoomRevenueWithoutVAT) - SUM(CustomerSales.ExtraBedRevenueWithoutVAT) AS MainBedsRevenueWithoutVAT,
	|		SUM(CustomerSales.CommissionSum) AS CommissionSum,
	|		SUM(CustomerSales.CommissionSumWithoutVAT) AS CommissionSumWithoutVAT,
	|		SUM((CustomerSales.Sales + CustomerSales.DiscountSum) * &qAgentCommission / 100) AS CalculatedCommissionSum,
	|		SUM((CustomerSales.SalesWithoutVAT + CustomerSales.DiscountSumWithoutVAT) * &qAgentCommission / 100) AS CalculatedCommissionSumWithoutVAT,
	|		SUM(CustomerSales.Sales) + SUM(CustomerSales.DiscountSum) AS BruttoSales,
	|		SUM(CustomerSales.SalesWithoutVAT) + SUM(CustomerSales.DiscountSumWithoutVAT) AS BruttoSalesWithoutVAT,
	|		SUM(CustomerSales.Sales) - SUM(CustomerSales.CommissionSum) AS SalesWithoutCommission,
	|		SUM(CustomerSales.SalesWithoutVAT) - SUM(CustomerSales.CommissionSumWithoutVAT) AS SalesWithoutCommissionWithoutVAT,
	|		SUM(CustomerSales.DiscountSum) AS DiscountSum,
	|		SUM(CustomerSales.DiscountSumWithoutVAT) AS DiscountSumWithoutVAT,
	|		SUM(CustomerSales.RoomsRented) AS RoomsRented,
	|		SUM(CustomerSales.BedsRented) AS BedsRented,
	|		SUM(CustomerSales.AdditionalBedsRented) AS AdditionalBedsRented,
	|		SUM(CustomerSales.GuestDays) AS GuestDays,
	|		SUM(CustomerSales.GuestsCheckedIn) AS GuestsCheckedIn,
	|		SUM(CustomerSales.RoomsCheckedIn) AS RoomsCheckedIn,
	|		SUM(CustomerSales.BedsCheckedIn) AS BedsCheckedIn,
	|		SUM(CustomerSales.AdditionalBedsCheckedIn) AS AdditionalBedsCheckedIn,
	|		SUM(CustomerSales.Quantity) AS Quantity,
	|		SUM(CustomerSales.VATSum) AS VATSum,
	|		SUM(CASE
	|				WHEN CustomerSales.GuestDays <> 0
	|					THEN CustomerSales.RateSum
	|				ELSE 0
	|			END) AS RateSum
	|	FROM
	|		AccumulationRegister.Sales AS CustomerSales
	|	WHERE
	|		CustomerSales.Period >= &qServicesPeriodFrom
	|		AND CustomerSales.Period <= &qServicesPeriodTo
	|		AND NOT CustomerSales.IsCorrection
	|		AND CustomerSales.Hotel IN HIERARCHY(&qHotel)
	|		AND (CustomerSales.GuestGroup = &qGuestGroup
	|				OR &qGuestGroupIsEmpty)
	|		AND (CustomerSales.GuestGroup.Event = &qEvent
	|				OR &qEventIsEmpty)
	|		AND (CustomerSales.Agent IN HIERARCHY (&qAgent)
	|				OR &qAgentIsEmpty)
	|		AND (CustomerSales.Service IN (&qServicesList)
	|				OR NOT &qUseServicesList)
	|		AND (NOT &qByCheckInDates
	|				OR &qByCheckInDates
	|					AND CASE
	|						WHEN NOT CustomerSales.ParentDoc.CheckInDate IS NULL
	|							THEN CustomerSales.ParentDoc.CheckInDate
	|						WHEN NOT CustomerSales.ParentDoc.DateTimeFrom IS NULL
	|							THEN CustomerSales.ParentDoc.DateTimeFrom
	|						ELSE CustomerSales.Folio.DateTimeFrom
	|					END >= &qPeriodFrom
	|					AND CASE
	|						WHEN NOT CustomerSales.ParentDoc.CheckInDate IS NULL
	|							THEN CustomerSales.ParentDoc.CheckInDate
	|						WHEN NOT CustomerSales.ParentDoc.DateTimeFrom IS NULL
	|							THEN CustomerSales.ParentDoc.DateTimeFrom
	|						ELSE CustomerSales.Folio.DateTimeFrom
	|					END <= &qPeriodTo)
	|		AND (NOT &qByCheckOutDates
	|				OR &qByCheckOutDates
	|					AND CASE
	|						WHEN NOT CustomerSales.ParentDoc.CheckOutDate IS NULL
	|							THEN CustomerSales.ParentDoc.CheckOutDate
	|						WHEN NOT CustomerSales.ParentDoc.DateTimeTo IS NULL
	|							THEN CustomerSales.ParentDoc.DateTimeTo
	|						ELSE CustomerSales.Folio.DateTimeTo
	|					END >= &qPeriodFrom
	|					AND CASE
	|						WHEN NOT CustomerSales.ParentDoc.CheckOutDate IS NULL
	|							THEN CustomerSales.ParentDoc.CheckOutDate
	|						WHEN NOT CustomerSales.ParentDoc.DateTimeTo IS NULL
	|							THEN CustomerSales.ParentDoc.DateTimeTo
	|						ELSE CustomerSales.Folio.DateTimeTo
	|					END <= &qPeriodTo)
	|		AND (NOT &qByBookingDates
	|				OR &qByBookingDates
	|					AND ISNULL(CustomerSales.ParentDoc.Reservation.Date, CustomerSales.ParentDoc.Date) >= &qPeriodFrom
	|					AND ISNULL(CustomerSales.ParentDoc.Reservation.Date, CustomerSales.ParentDoc.Date) <= &qPeriodTo)
	|		AND (NOT &qShowMainRoomGuestsOnly
	|				OR &qShowMainRoomGuestsOnly
	|					AND (ISNULL(CustomerSales.ParentDoc.AccommodationTemplate, VALUE(Catalog.AccommodationTemplates.EmptyRef)) <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|						OR ISNULL(CustomerSales.ParentDoc.IsForFolioSplit, FALSE)))
	|	
	|	GROUP BY
	|		CustomerSales.Company,
	|		CustomerSales.Hotel,
	|		CustomerSales.ReportingCurrency,
	|		CustomerSales.Agent,
	|		CASE
	|			WHEN CustomerSales.Customer = &qEmptyCustomer
	|				THEN CustomerSales.Hotel.IndividualsCustomer
	|			ELSE CustomerSales.Customer
	|		END,
	|		CASE
	|			WHEN CustomerSales.Customer = &qEmptyCustomer
	|				THEN CustomerSales.Hotel.IndividualsContract
	|			ELSE CustomerSales.Contract
	|		END,
	|		CustomerSales.GuestGroup,
	|		CustomerSales.ParentDoc,
	|		CustomerSales.Folio,
	|		CustomerSales.VATRate,
	|		CustomerSales.Service,
	|		CustomerSales.Client,
	|		CustomerSales.ClientType,
	|		CustomerSales.TripPurpose,
	|		CustomerSales.SourceOfBusiness,
	|		CustomerSales.MarketingCode,
	|		CASE
	|			WHEN NOT CustomerSales.ParentDoc.CheckInDate IS NULL
	|				THEN CustomerSales.ParentDoc.CheckInDate
	|			WHEN NOT CustomerSales.ParentDoc.DateTimeFrom IS NULL
	|				THEN CustomerSales.ParentDoc.DateTimeFrom
	|			ELSE CustomerSales.Folio.DateTimeFrom
	|		END,
	|		CASE
	|			WHEN NOT CustomerSales.ParentDoc.CheckOutDate IS NULL
	|				THEN CustomerSales.ParentDoc.CheckOutDate
	|			WHEN NOT CustomerSales.ParentDoc.DateTimeTo IS NULL
	|				THEN CustomerSales.ParentDoc.DateTimeTo
	|			ELSE CustomerSales.Folio.DateTimeTo
	|		END,
	|		CASE
	|			WHEN NOT CustomerSales.ParentDoc.AccommodationStatus IS NULL
	|				THEN CustomerSales.ParentDoc.AccommodationStatus
	|			WHEN NOT CustomerSales.ParentDoc.ReservationStatus IS NULL
	|				THEN CustomerSales.ParentDoc.ReservationStatus
	|			ELSE CustomerSales.ParentDoc.ResourceReservationStatus
	|		END,
	|		CASE
	|			WHEN &qByDays
	|				THEN CustomerSales.AccountingDate
	|			ELSE &qEmptyDate
	|		END,
	|		CustomerSales.AccommodationType,
	|		CustomerSales.Room,
	|		CustomerSales.RoomType,
	|		CustomerSales.Resource,
	|		CustomerSales.RoomRate,
	|		CustomerSales.PaymentMethod,
	|		CASE
	|			WHEN NOT CustomerSales.ParentDoc.CheckOutDate IS NULL
	|					AND CustomerSales.ParentDoc.CheckOutDate <= &qDateTo
	|					AND CustomerSales.ParentDoc.CheckOutDate >= &qDateFrom
	|					AND CustomerSales.ParentDoc.CheckOutDate > &qEmptyDate
	|				THEN TRUE
	|			WHEN NOT CustomerSales.ParentDoc.DateTimeTo IS NULL
	|					AND CustomerSales.ParentDoc.DateTimeTo <= &qDateTo
	|					AND CustomerSales.ParentDoc.DateTimeTo >= &qDateFrom
	|					AND CustomerSales.ParentDoc.DateTimeTo > &qEmptyDate
	|				THEN TRUE
	|			WHEN NOT CustomerSales.Folio.DateTimeTo IS NULL
	|					AND CustomerSales.Folio.DateTimeTo <= &qDateTo
	|					AND CustomerSales.Folio.DateTimeTo >= &qDateFrom
	|					AND CustomerSales.Folio.DateTimeTo > &qEmptyDate
	|				THEN TRUE
	|			ELSE FALSE
	|		END,
	|		CASE
	|			WHEN CustomerSales.Quantity = 0
	|				THEN CustomerSales.Sales
	|			ELSE CAST(CustomerSales.Sales / CustomerSales.Quantity AS NUMBER(17, 2))
	|		END
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CustomerSalesForecast.Company,
	|		CustomerSalesForecast.Hotel,
	|		CustomerSalesForecast.ReportingCurrency,
	|		CustomerSalesForecast.Agent,
	|		CASE
	|			WHEN CustomerSalesForecast.Customer = &qEmptyCustomer
	|				THEN CustomerSalesForecast.Hotel.IndividualsCustomer
	|			ELSE CustomerSalesForecast.Customer
	|		END,
	|		CASE
	|			WHEN CustomerSalesForecast.Customer = &qEmptyCustomer
	|				THEN CustomerSalesForecast.Hotel.IndividualsContract
	|			ELSE CustomerSalesForecast.Contract
	|		END,
	|		CustomerSalesForecast.GuestGroup,
	|		CustomerSalesForecast.ParentDoc,
	|		CustomerSalesForecast.Folio,
	|		CustomerSalesForecast.VATRate,
	|		CustomerSalesForecast.Service,
	|		CASE
	|			WHEN &qByDays
	|				THEN CustomerSalesForecast.AccountingDate
	|			ELSE &qEmptyDate
	|		END,
	|		CustomerSalesForecast.Client,
	|		CustomerSalesForecast.ClientType,
	|		CustomerSalesForecast.TripPurpose,
	|		CustomerSalesForecast.SourceOfBusiness,
	|		CustomerSalesForecast.MarketingCode,
	|		CASE
	|			WHEN NOT CustomerSalesForecast.ParentDoc.CheckInDate IS NULL
	|				THEN CustomerSalesForecast.ParentDoc.CheckInDate
	|			WHEN NOT CustomerSalesForecast.ParentDoc.DateTimeFrom IS NULL
	|				THEN CustomerSalesForecast.ParentDoc.DateTimeFrom
	|			ELSE CustomerSalesForecast.Folio.DateTimeFrom
	|		END,
	|		CASE
	|			WHEN NOT CustomerSalesForecast.ParentDoc.CheckOutDate IS NULL
	|				THEN CustomerSalesForecast.ParentDoc.CheckOutDate
	|			WHEN NOT CustomerSalesForecast.ParentDoc.DateTimeTo IS NULL
	|				THEN CustomerSalesForecast.ParentDoc.DateTimeTo
	|			ELSE CustomerSalesForecast.Folio.DateTimeTo
	|		END,
	|		CASE
	|			WHEN NOT CustomerSalesForecast.ParentDoc.AccommodationStatus IS NULL
	|				THEN CustomerSalesForecast.ParentDoc.AccommodationStatus
	|			WHEN NOT CustomerSalesForecast.ParentDoc.ReservationStatus IS NULL
	|				THEN CustomerSalesForecast.ParentDoc.ReservationStatus
	|			ELSE CustomerSalesForecast.ParentDoc.ResourceReservationStatus
	|		END,
	|		CustomerSalesForecast.AccommodationType,
	|		CustomerSalesForecast.Room,
	|		CustomerSalesForecast.RoomType,
	|		CustomerSalesForecast.Resource,
	|		CustomerSalesForecast.RoomRate,
	|		CustomerSalesForecast.PaymentMethod,
	|		CASE
	|			WHEN CustomerSalesForecast.Quantity = 0
	|				THEN CustomerSalesForecast.Sales
	|			ELSE CAST(CustomerSalesForecast.Sales / CustomerSalesForecast.Quantity AS NUMBER(17, 2))
	|		END,
	|		FALSE,
	|		SUM(CustomerSalesForecast.Sales),
	|		SUM(CustomerSalesForecast.SalesWithoutVAT),
	|		SUM(CustomerSalesForecast.RoomRevenue),
	|		SUM(CustomerSalesForecast.RoomRevenueWithoutVAT),
	|		SUM(CustomerSalesForecast.ExtraBedRevenue),
	|		SUM(CustomerSalesForecast.ExtraBedRevenueWithoutVAT),
	|		SUM(CustomerSalesForecast.RoomRevenue) - SUM(CustomerSalesForecast.ExtraBedRevenue),
	|		SUM(CustomerSalesForecast.RoomRevenueWithoutVAT) - SUM(CustomerSalesForecast.ExtraBedRevenueWithoutVAT),
	|		SUM(CustomerSalesForecast.CommissionSum),
	|		SUM(CustomerSalesForecast.CommissionSumWithoutVAT),
	|		SUM((CustomerSalesForecast.Sales + CustomerSalesForecast.DiscountSum) * &qAgentCommission / 100),
	|		SUM((CustomerSalesForecast.SalesWithoutVAT + CustomerSalesForecast.DiscountSumWithoutVAT) * &qAgentCommission / 100),
	|		SUM(CustomerSalesForecast.Sales) + SUM(CustomerSalesForecast.DiscountSum),
	|		SUM(CustomerSalesForecast.SalesWithoutVAT) + SUM(CustomerSalesForecast.DiscountSumWithoutVAT),
	|		SUM(CustomerSalesForecast.Sales) - SUM(CustomerSalesForecast.CommissionSum),
	|		SUM(CustomerSalesForecast.SalesWithoutVAT) - SUM(CustomerSalesForecast.CommissionSumWithoutVAT),
	|		SUM(CustomerSalesForecast.DiscountSum),
	|		SUM(CustomerSalesForecast.DiscountSumWithoutVAT),
	|		SUM(CustomerSalesForecast.RoomsRented),
	|		SUM(CustomerSalesForecast.BedsRented),
	|		SUM(CustomerSalesForecast.AdditionalBedsRented),
	|		SUM(CustomerSalesForecast.GuestDays),
	|		SUM(CustomerSalesForecast.GuestsCheckedIn),
	|		SUM(CustomerSalesForecast.RoomsCheckedIn),
	|		SUM(CustomerSalesForecast.BedsCheckedIn),
	|		SUM(CustomerSalesForecast.AdditionalBedsCheckedIn),
	|		SUM(CustomerSalesForecast.Quantity),
	|		SUM(CustomerSalesForecast.VATSum),
	|		SUM(CASE
	|				WHEN CustomerSalesForecast.GuestDays <> 0
	|					THEN CustomerSalesForecast.RateSum
	|				ELSE 0
	|			END)
	|	FROM
	|		AccumulationRegister.SalesForecast AS CustomerSalesForecast
	|	WHERE
	|		CustomerSalesForecast.Period >= &qServicesPeriodFrom
	|		AND CustomerSalesForecast.Period <= &qServicesPeriodTo
	|		AND &qShowForecastByReservations
	|		AND CustomerSalesForecast.Hotel IN HIERARCHY(&qHotel)
	|		AND (CustomerSalesForecast.GuestGroup = &qGuestGroup
	|				OR &qGuestGroupIsEmpty)
	|		AND (CustomerSalesForecast.GuestGroup.Event = &qEvent
	|				OR &qEventIsEmpty)
	|		AND (CustomerSalesForecast.Agent IN HIERARCHY (&qAgent)
	|				OR &qAgentIsEmpty)
	|		AND (CustomerSalesForecast.Service IN (&qServicesList)
	|				OR NOT &qUseServicesList)
	|		AND (NOT &qByCheckInDates
	|				OR &qByCheckInDates
	|					AND CASE
	|						WHEN NOT CustomerSalesForecast.ParentDoc.CheckInDate IS NULL
	|							THEN CustomerSalesForecast.ParentDoc.CheckInDate
	|						WHEN NOT CustomerSalesForecast.ParentDoc.DateTimeFrom IS NULL
	|							THEN CustomerSalesForecast.ParentDoc.DateTimeFrom
	|						ELSE CustomerSalesForecast.Folio.DateTimeFrom
	|					END >= &qPeriodFrom
	|					AND CASE
	|						WHEN NOT CustomerSalesForecast.ParentDoc.CheckInDate IS NULL
	|							THEN CustomerSalesForecast.ParentDoc.CheckInDate
	|						WHEN NOT CustomerSalesForecast.ParentDoc.DateTimeFrom IS NULL
	|							THEN CustomerSalesForecast.ParentDoc.DateTimeFrom
	|						ELSE CustomerSalesForecast.Folio.DateTimeFrom
	|					END <= &qPeriodTo)
	|		AND (NOT &qByCheckOutDates
	|				OR &qByCheckOutDates
	|					AND CASE
	|						WHEN NOT CustomerSalesForecast.ParentDoc.CheckOutDate IS NULL
	|							THEN CustomerSalesForecast.ParentDoc.CheckOutDate
	|						WHEN NOT CustomerSalesForecast.ParentDoc.DateTimeTo IS NULL
	|							THEN CustomerSalesForecast.ParentDoc.DateTimeTo
	|						ELSE CustomerSalesForecast.Folio.DateTimeTo
	|					END >= &qPeriodFrom
	|					AND CASE
	|						WHEN NOT CustomerSalesForecast.ParentDoc.CheckOutDate IS NULL
	|							THEN CustomerSalesForecast.ParentDoc.CheckOutDate
	|						WHEN NOT CustomerSalesForecast.ParentDoc.DateTimeTo IS NULL
	|							THEN CustomerSalesForecast.ParentDoc.DateTimeTo
	|						ELSE CustomerSalesForecast.Folio.DateTimeTo
	|					END <= &qPeriodTo)
	|		AND (NOT &qByBookingDates
	|				OR &qByBookingDates
	|					AND ISNULL(CustomerSalesForecast.ParentDoc.Reservation.Date, CustomerSalesForecast.ParentDoc.Date) >= &qPeriodFrom
	|					AND ISNULL(CustomerSalesForecast.ParentDoc.Reservation.Date, CustomerSalesForecast.ParentDoc.Date) <= &qPeriodTo)
	|		AND (NOT &qShowMainRoomGuestsOnly
	|				OR &qShowMainRoomGuestsOnly
	|					AND (ISNULL(CustomerSalesForecast.ParentDoc.AccommodationTemplate, VALUE(Catalog.AccommodationTemplates.EmptyRef)) <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|						OR ISNULL(CustomerSalesForecast.ParentDoc.IsForFolioSplit, FALSE)))
	|	
	|	GROUP BY
	|		CustomerSalesForecast.Company,
	|		CustomerSalesForecast.Hotel,
	|		CustomerSalesForecast.ReportingCurrency,
	|		CustomerSalesForecast.Agent,
	|		CASE
	|			WHEN CustomerSalesForecast.Customer = &qEmptyCustomer
	|				THEN CustomerSalesForecast.Hotel.IndividualsCustomer
	|			ELSE CustomerSalesForecast.Customer
	|		END,
	|		CASE
	|			WHEN CustomerSalesForecast.Customer = &qEmptyCustomer
	|				THEN CustomerSalesForecast.Hotel.IndividualsContract
	|			ELSE CustomerSalesForecast.Contract
	|		END,
	|		CustomerSalesForecast.GuestGroup,
	|		CustomerSalesForecast.ParentDoc,
	|		CustomerSalesForecast.Folio,
	|		CustomerSalesForecast.VATRate,
	|		CustomerSalesForecast.Service,
	|		CustomerSalesForecast.Client,
	|		CustomerSalesForecast.ClientType,
	|		CustomerSalesForecast.TripPurpose,
	|		CustomerSalesForecast.SourceOfBusiness,
	|		CustomerSalesForecast.MarketingCode,
	|		CASE
	|			WHEN NOT CustomerSalesForecast.ParentDoc.CheckInDate IS NULL
	|				THEN CustomerSalesForecast.ParentDoc.CheckInDate
	|			WHEN NOT CustomerSalesForecast.ParentDoc.DateTimeFrom IS NULL
	|				THEN CustomerSalesForecast.ParentDoc.DateTimeFrom
	|			ELSE CustomerSalesForecast.Folio.DateTimeFrom
	|		END,
	|		CASE
	|			WHEN NOT CustomerSalesForecast.ParentDoc.CheckOutDate IS NULL
	|				THEN CustomerSalesForecast.ParentDoc.CheckOutDate
	|			WHEN NOT CustomerSalesForecast.ParentDoc.DateTimeTo IS NULL
	|				THEN CustomerSalesForecast.ParentDoc.DateTimeTo
	|			ELSE CustomerSalesForecast.Folio.DateTimeTo
	|		END,
	|		CASE
	|			WHEN NOT CustomerSalesForecast.ParentDoc.AccommodationStatus IS NULL
	|				THEN CustomerSalesForecast.ParentDoc.AccommodationStatus
	|			WHEN NOT CustomerSalesForecast.ParentDoc.ReservationStatus IS NULL
	|				THEN CustomerSalesForecast.ParentDoc.ReservationStatus
	|			ELSE CustomerSalesForecast.ParentDoc.ResourceReservationStatus
	|		END,
	|		CASE
	|			WHEN &qByDays
	|				THEN CustomerSalesForecast.AccountingDate
	|			ELSE &qEmptyDate
	|		END,
	|		CustomerSalesForecast.AccommodationType,
	|		CustomerSalesForecast.Room,
	|		CustomerSalesForecast.RoomType,
	|		CustomerSalesForecast.Resource,
	|		CustomerSalesForecast.RoomRate,
	|		CustomerSalesForecast.PaymentMethod,
	|		CASE
	|			WHEN CustomerSalesForecast.Quantity = 0
	|				THEN CustomerSalesForecast.Sales
	|			ELSE CAST(CustomerSalesForecast.Sales / CustomerSalesForecast.Quantity AS NUMBER(17, 2))
	|		END) AS CustomerTurnovers
	|		LEFT JOIN InformationRegister.AccommodationForeignerRegistryRecords.SliceLast(&qEndOfTime, ) AS ForeignerRegistryRecords
	|		ON CustomerTurnovers.ParentDoc = ForeignerRegistryRecords.Accommodation
	|		LEFT JOIN InformationRegister.ReservationCustomAttributeValues AS ReservationCustomAttributeValues1
	|		ON (CustomerTurnovers.ParentDoc.Reservation = ReservationCustomAttributeValues1.Owner
	|				OR CustomerTurnovers.ParentDoc = ReservationCustomAttributeValues1.Owner
	|					AND CustomerTurnovers.ParentDoc.Reservation.Number IS NULL)
	|			AND (ReservationCustomAttributeValues1.Characteristic = &qCustomAttribute1)
	|		LEFT JOIN InformationRegister.ReservationCustomAttributeValues AS ReservationCustomAttributeValues2
	|		ON (CustomerTurnovers.ParentDoc.Reservation = ReservationCustomAttributeValues2.Owner
	|				OR CustomerTurnovers.ParentDoc = ReservationCustomAttributeValues2.Owner
	|					AND CustomerTurnovers.ParentDoc.Reservation.Number IS NULL)
	|			AND (ReservationCustomAttributeValues2.Characteristic = &qCustomAttribute2)
	|		LEFT JOIN InformationRegister.ReservationCustomAttributeValues AS ReservationCustomAttributeValues3
	|		ON (CustomerTurnovers.ParentDoc.Reservation = ReservationCustomAttributeValues3.Owner
	|				OR CustomerTurnovers.ParentDoc = ReservationCustomAttributeValues3.Owner
	|					AND CustomerTurnovers.ParentDoc.Reservation.Number IS NULL)
	|			AND (ReservationCustomAttributeValues3.Characteristic = &qCustomAttribute3)
	|WHERE
	|	(&qCustomerIsEmpty
	|			OR NOT &qCustomerIsEmpty
	|				AND CustomerTurnovers.Customer IN HIERARCHY (&qCustomer))
	|	AND (&qContractIsEmpty
	|			OR NOT &qContractIsEmpty
	|				AND CustomerTurnovers.Contract IN HIERARCHY (&qContract))
	|	AND (NOT &qHideRowsNotInTheCheckOutPeriod
	|			OR &qHideRowsNotInTheCheckOutPeriod
	|				AND CustomerTurnovers.CheckOutDate >= &qDateFrom
	|				AND (CustomerTurnovers.CheckOutDate < &qDateTo
	|					OR &qDateTo = &qEmptyDate))
	|{WHERE
	|	CustomerTurnovers.Company.*,
	|	CustomerTurnovers.Hotel.*,
	|	CustomerTurnovers.ReportingCurrency.*,
	|	CustomerTurnovers.Agent.*,
	|	CustomerTurnovers.Customer.*,
	|	CustomerTurnovers.Contract.*,
	|	CustomerTurnovers.GuestGroup.*,
	|	CustomerTurnovers.ParentDoc.*,
	|	CustomerTurnovers.Folio.*,
	|	CustomerTurnovers.VATRate.*,
	|	ForeignerRegistryRecords.ForeignerRegistryRecord.* AS ForeignerRegistryRecord,
	|	ReservationCustomAttributeValues1.CharacteristicValue.* AS CustomAttribute1,
	|	ReservationCustomAttributeValues2.CharacteristicValue.* AS CustomAttribute2,
	|	ReservationCustomAttributeValues3.CharacteristicValue.* AS CustomAttribute3,
	|	CustomerTurnovers.Client.* AS Client,
	|	CustomerTurnovers.ClientType.* AS ClientType,
	|	CustomerTurnovers.TripPurpose.* AS TripPurpose,
	|	CustomerTurnovers.SourceOfBusiness.* AS SourceOfBusiness,
	|	CustomerTurnovers.MarketingCode.* AS MarketingCode,
	|	CustomerTurnovers.CheckInDate AS CheckInDate,
	|	CustomerTurnovers.CheckOutDate AS CheckOutDate,
	|	CustomerTurnovers.AccommodationType.* AS AccommodationType,
	|	CustomerTurnovers.Status.* AS Status,
	|	CustomerTurnovers.Room.* AS Room,
	|	CustomerTurnovers.RoomType.* AS RoomType,
	|	CustomerTurnovers.Resource.* AS Resource,
	|	CustomerTurnovers.RoomRate.* AS RoomRate,
	|	CustomerTurnovers.PaymentMethod.* AS PaymentMethod,
	|	CustomerTurnovers.IsCheckedOutAtThePeriodSelected AS IsCheckedOutAtThePeriodSelected,
	|	CustomerTurnovers.Service.*,
	|	CustomerTurnovers.AccountingDate AS AccountingDate,
	|	CustomerTurnovers.Price AS Price,
	|	CustomerTurnovers.Sales,
	|	CustomerTurnovers.SalesWithoutVAT,
	|	CustomerTurnovers.RoomRevenue,
	|	CustomerTurnovers.RoomRevenueWithoutVAT,
	|	CustomerTurnovers.ExtraBedRevenue,
	|	CustomerTurnovers.ExtraBedRevenueWithoutVAT,
	|	CustomerTurnovers.MainBedsRevenue,
	|	CustomerTurnovers.MainBedsRevenueWithoutVAT,
	|	CustomerTurnovers.CommissionSum,
	|	CustomerTurnovers.CommissionSumWithoutVAT,
	|	CustomerTurnovers.CalculatedCommissionSum,
	|	CustomerTurnovers.CalculatedCommissionSumWithoutVAT,
	|	CustomerTurnovers.SalesWithoutCommission,
	|	CustomerTurnovers.SalesWithoutCommissionWithoutVAT,
	|	CustomerTurnovers.BruttoSales,
	|	CustomerTurnovers.BruttoSalesWithoutVAT,
	|	CustomerTurnovers.DiscountSum,
	|	CustomerTurnovers.DiscountSumWithoutVAT,
	|	CustomerTurnovers.RoomsRented,
	|	CustomerTurnovers.BedsRented,
	|	CustomerTurnovers.AdditionalBedsRented,
	|	CustomerTurnovers.GuestDays,
	|	CustomerTurnovers.GuestsCheckedIn,
	|	CustomerTurnovers.RoomsCheckedIn,
	|	CustomerTurnovers.BedsCheckedIn,
	|	CustomerTurnovers.AdditionalBedsCheckedIn,
	|	CustomerTurnovers.Quantity,
	|	CustomerTurnovers.VATSum,
	|	CustomerTurnovers.RateSum}
	|
	|ORDER BY
	|	Company,
	|	Hotel,
	|	ReportingCurrency,
	|	Agent,
	|	Customer,
	|	Contract,
	|	GuestGroup,
	|	CheckInDate,
	|	Client,
	|	Service,
	|	AccountingDate
	|{ORDER BY
	|	Company.*,
	|	Hotel.*,
	|	ReportingCurrency.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	CustomerTurnovers.Folio.* AS Folio,
	|	CustomerTurnovers.VATRate.* AS VATRate,
	|	Agent.*,
	|	Client.*,
	|	ClientType.* AS ClientType,
	|	TripPurpose.* AS TripPurpose,
	|	SourceOfBusiness.* AS SourceOfBusiness,
	|	MarketingCode.* AS MarketingCode,
	|	CheckInDate,
	|	CheckOutDate,
	|	AccommodationType.*,
	|	Status.*,
	|	Room.*,
	|	RoomType.*,
	|	Resource.*,
	|	CustomerTurnovers.RoomRate.* AS RoomRate,
	|	CustomerTurnovers.PaymentMethod.* AS PaymentMethod,
	|	CustomerTurnovers.IsCheckedOutAtThePeriodSelected AS IsCheckedOutAtThePeriodSelected,
	|	ParentDoc.*,
	|	ForeignerRegistryRecords.ForeignerRegistryRecord.* AS ForeignerRegistryRecord,
	|	ReservationCustomAttributeValues1.CharacteristicValue.* AS CustomAttribute1,
	|	ReservationCustomAttributeValues2.CharacteristicValue.* AS CustomAttribute2,
	|	ReservationCustomAttributeValues3.CharacteristicValue.* AS CustomAttribute3,
	|	Service.*,
	|	AccountingDate,
	|	CustomerTurnovers.Price AS Price,
	|	Sales,
	|	SalesWithoutVAT,
	|	RoomRevenue,
	|	RoomRevenueWithoutVAT,
	|	ExtraBedRevenue,
	|	ExtraBedRevenueWithoutVAT,
	|	MainBedsRevenue,
	|	MainBedsRevenueWithoutVAT,
	|	CommissionSum,
	|	CommissionSumWithoutVAT,
	|	CalculatedCommissionSum,
	|	CalculatedCommissionSumWithoutVAT,
	|	BruttoSales,
	|	BruttoSalesWithoutVAT,
	|	SalesWithoutCommission,
	|	SalesWithoutCommissionWithoutVAT,
	|	SalesWithoutCalculatedCommission,
	|	SalesWithoutCalculatedCommissionWithoutVAT,
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
	|	Quantity,
	|	VATSum,
	|	RateSum}
	|TOTALS
	|	SUM(Sales),
	|	SUM(SalesWithoutVAT),
	|	SUM(RoomRevenue),
	|	SUM(RoomRevenueWithoutVAT),
	|	SUM(ExtraBedRevenue),
	|	SUM(ExtraBedRevenueWithoutVAT),
	|	SUM(MainBedsRevenue),
	|	SUM(MainBedsRevenueWithoutVAT),
	|	SUM(CommissionSum),
	|	SUM(CommissionSumWithoutVAT),
	|	SUM(CalculatedCommissionSum),
	|	SUM(CalculatedCommissionSumWithoutVAT),
	|	SUM(SalesWithoutCommission),
	|	SUM(SalesWithoutCommissionWithoutVAT),
	|	SUM(SalesWithoutCalculatedCommission),
	|	SUM(SalesWithoutCalculatedCommissionWithoutVAT),
	|	SUM(BruttoSales),
	|	SUM(BruttoSalesWithoutVAT),
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
	|	SUM(Quantity),
	|	SUM(VATSum),
	|	SUM(RateSum)
	|BY
	|	OVERALL,
	|	Hotel,
	|	ReportingCurrency,
	|	Agent,
	|	Customer,
	|	Contract,
	|	GuestGroup,
	|	ParentDoc
	|{TOTALS BY
	|	Company.*,
	|	Hotel.*,
	|	ReportingCurrency.*,
	|	Agent.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	CustomerTurnovers.Folio.* AS Folio,
	|	CustomerTurnovers.VATRate.* AS VATRate,
	|	Client.*,
	|	ClientType.* AS ClientType,
	|	TripPurpose.* AS TripPurpose,
	|	SourceOfBusiness.* AS SourceOfBusiness,
	|	MarketingCode.* AS MarketingCode,
	|	Room.*,
	|	AccommodationType.*,
	|	Status.*,
	|	RoomType.*,
	|	Resource.*,
	|	CustomerTurnovers.RoomRate.* AS RoomRate,
	|	CustomerTurnovers.PaymentMethod.* AS PaymentMethod,
	|	CustomerTurnovers.IsCheckedOutAtThePeriodSelected AS IsCheckedOutAtThePeriodSelected,
	|	Service.*,
	|	AccountingDate,
	|	CustomerTurnovers.Price AS Price,
	|	ForeignerRegistryRecords.ForeignerRegistryRecord.* AS ForeignerRegistryRecord,
	|	ReservationCustomAttributeValues1.CharacteristicValue.* AS CustomAttribute1,
	|	ReservationCustomAttributeValues2.CharacteristicValue.* AS CustomAttribute2,
	|	ReservationCustomAttributeValues3.CharacteristicValue.* AS CustomAttribute3,
	|	ParentDoc.*}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Customer sales with services';RU='Сводка по оказанным контрагентам услугам';de='Sammelbericht nach den Vertragspartnern geleisteten Diensten'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
