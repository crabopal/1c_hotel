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
	ReportBuilder.Parameters.Insert("qCustomer", Customer);
	ReportBuilder.Parameters.Insert("qCustomerIsEmpty", Not ValueIsFilled(Customer));
	ReportBuilder.Parameters.Insert("qContract", Contract);
	ReportBuilder.Parameters.Insert("qContractIsEmpty", Not ValueIsFilled(Contract));
	ReportBuilder.Parameters.Insert("qGuestGroup", GuestGroup);
	ReportBuilder.Parameters.Insert("qGuestGroupIsEmpty", Not ValueIsFilled(GuestGroup));
	ReportBuilder.Parameters.Insert("qAgent", Agent);
	ReportBuilder.Parameters.Insert("qAgentIsEmpty", Not ValueIsFilled(Agent));
	ReportBuilder.Parameters.Insert("qAgentCommission", AgentCommission);
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
	ReportBuilder.Parameters.Insert("qShowForecastByReservations", ShowForecastByReservations);
	ReportBuilder.Parameters.Insert("qEndOfTime", '39991231');
	ReportBuilder.Parameters.Insert("qEmptyString", "");
	ReportBuilder.Parameters.Insert("qShowPayedAmount", ShowPayedAmount);
	ReportBuilder.Parameters.Insert("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	ReportBuilder.Parameters.Insert("qEvent", Event);
	ReportBuilder.Parameters.Insert("qEventIsEmpty", Not ValueIsFilled(Event));
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
	|	GuestGroups.GuestGroup AS GuestGroup
	|INTO GuestGroups
	|FROM
	|	(SELECT
	|		CustomerSales.GuestGroup AS GuestGroup
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qServicesPeriodFrom,
	|				&qServicesPeriodTo,
	|				Period,
	|				NOT IsCorrection
	|					AND Hotel IN HIERARCHY (&qHotel)
	|					AND (Customer IN HIERARCHY (&qCustomer)
	|						OR &qCustomerIsEmpty)
	|					AND (Contract IN HIERARCHY (&qContract)
	|						OR &qContractIsEmpty)
	|					AND (GuestGroup = &qGuestGroup
	|						OR &qGuestGroupIsEmpty)
	|					AND (GuestGroup.Event IN HIERARCHY (&qEvent)
	|						OR &qEventIsEmpty)
	|					AND (Agent IN HIERARCHY (&qAgent)
	|						OR &qAgentIsEmpty)
	|					AND (Service IN (&qServicesList)
	|						OR NOT &qUseServicesList)
	|					AND (NOT &qByCheckInDates
	|						OR &qByCheckInDates
	|							AND CASE
	|								WHEN NOT ParentDoc.CheckInDate IS NULL
	|									THEN ParentDoc.CheckInDate
	|								WHEN NOT ParentDoc.DateTimeFrom IS NULL
	|									THEN ParentDoc.DateTimeFrom
	|								ELSE Folio.DateTimeFrom
	|							END >= &qPeriodFrom
	|							AND CASE
	|								WHEN NOT ParentDoc.CheckInDate IS NULL
	|									THEN ParentDoc.CheckInDate
	|								WHEN NOT ParentDoc.DateTimeFrom IS NULL
	|									THEN ParentDoc.DateTimeFrom
	|								ELSE Folio.DateTimeFrom
	|							END <= &qPeriodTo)
	|					AND (NOT &qByCheckOutDates
	|						OR &qByCheckOutDates
	|							AND CASE
	|								WHEN NOT ParentDoc.CheckOutDate IS NULL
	|									THEN ParentDoc.CheckOutDate
	|								WHEN NOT ParentDoc.DateTimeTo IS NULL
	|									THEN ParentDoc.DateTimeTo
	|								ELSE Folio.DateTimeTo
	|							END >= &qPeriodFrom
	|							AND CASE
	|								WHEN NOT ParentDoc.CheckOutDate IS NULL
	|									THEN ParentDoc.CheckOutDate
	|								WHEN NOT ParentDoc.DateTimeTo IS NULL
	|									THEN ParentDoc.DateTimeTo
	|								ELSE Folio.DateTimeTo
	|							END <= &qPeriodTo)
	|					AND (NOT &qByBookingDates
	|						OR &qByBookingDates
	|							AND ISNULL(ParentDoc.Reservation.Date, ParentDoc.Date) >= &qPeriodFrom
	|							AND ISNULL(ParentDoc.Reservation.Date, ParentDoc.Date) <= &qPeriodTo)) AS CustomerSales
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CustomerSalesForecast.GuestGroup
	|	FROM
	|		AccumulationRegister.SalesForecast.Turnovers(
	|				&qForecastPeriodFrom,
	|				&qForecastPeriodTo,
	|				Period,
	|				&qShowForecastByReservations
	|					AND Hotel IN HIERARCHY (&qHotel)
	|					AND (Customer IN HIERARCHY (&qCustomer)
	|						OR &qCustomerIsEmpty)
	|					AND (Contract IN HIERARCHY (&qContract)
	|						OR &qContractIsEmpty)
	|					AND (GuestGroup = &qGuestGroup
	|						OR &qGuestGroupIsEmpty)
	|					AND (GuestGroup.Event IN HIERARCHY (&qEvent)
	|						OR &qEventIsEmpty)
	|					AND (Agent IN HIERARCHY (&qAgent)
	|						OR &qAgentIsEmpty)
	|					AND (Service IN (&qServicesList)
	|						OR NOT &qUseServicesList)
	|					AND (NOT &qByCheckInDates
	|						OR &qByCheckInDates
	|							AND CASE
	|								WHEN NOT ParentDoc.CheckInDate IS NULL
	|									THEN ParentDoc.CheckInDate
	|								WHEN NOT ParentDoc.DateTimeFrom IS NULL
	|									THEN ParentDoc.DateTimeFrom
	|								ELSE Folio.DateTimeFrom
	|							END >= &qPeriodFrom
	|							AND CASE
	|								WHEN NOT ParentDoc.CheckInDate IS NULL
	|									THEN ParentDoc.CheckInDate
	|								WHEN NOT ParentDoc.DateTimeFrom IS NULL
	|									THEN ParentDoc.DateTimeFrom
	|								ELSE Folio.DateTimeFrom
	|							END <= &qPeriodTo)
	|					AND (NOT &qByCheckOutDates
	|						OR &qByCheckOutDates
	|							AND CASE
	|								WHEN NOT ParentDoc.CheckOutDate IS NULL
	|									THEN ParentDoc.CheckOutDate
	|								WHEN NOT ParentDoc.DateTimeTo IS NULL
	|									THEN ParentDoc.DateTimeTo
	|								ELSE Folio.DateTimeTo
	|							END >= &qPeriodFrom
	|							AND CASE
	|								WHEN NOT ParentDoc.CheckOutDate IS NULL
	|									THEN ParentDoc.CheckOutDate
	|								WHEN NOT ParentDoc.DateTimeTo IS NULL
	|									THEN ParentDoc.DateTimeTo
	|								ELSE Folio.DateTimeTo
	|							END <= &qPeriodTo)
	|					AND (NOT &qByBookingDates
	|						OR &qByBookingDates
	|							AND ISNULL(ParentDoc.Reservation.Date, ParentDoc.Date) >= &qPeriodFrom
	|							AND ISNULL(ParentDoc.Reservation.Date, ParentDoc.Date) <= &qPeriodTo)) AS CustomerSalesForecast) AS GuestGroups
	|
	|GROUP BY
	|	GuestGroups.GuestGroup
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CustomerSales.Company AS Company,
	|	CustomerSales.Hotel AS Hotel,
	|	CustomerSales.ReportingCurrency AS ReportingCurrency,
	|	CustomerSales.Agent AS Agent,
	|	CustomerSales.Customer AS Customer,
	|	CustomerSales.Contract AS Contract,
	|	CustomerSales.GuestGroup AS GuestGroup,
	|	CustomerSales.Client AS Client,
	|	CustomerSales.ClientType AS ClientType,
	|	CustomerSales.TripPurpose AS TripPurpose,
	|	CustomerSales.SourceOfBusiness AS SourceOfBusiness,
	|	CustomerSales.MarketingCode AS MarketingCode,
	|	CustomerSales.CheckInDate AS CheckInDate,
	|	CustomerSales.CheckOutDate AS CheckOutDate,
	|	CustomerSales.AccommodationType AS AccommodationType,
	|	CustomerSales.Status AS Status,
	|	CustomerSales.Room AS Room,
	|	CustomerSales.RoomType AS RoomType,
	|	CustomerSales.Resource AS Resource,
	|	CustomerSales.RoomRate AS RoomRate,
	|	CustomerSales.ParentDoc AS ParentDoc,
	|	CustomerSales.PaymentMethod AS PaymentMethod,
	|	CustomerSales.NumberOfAdults AS NumberOfAdults,
	|	CustomerSales.NumberOfTeenagers AS NumberOfTeenagers,
	|	CustomerSales.NumberOfChildren AS NumberOfChildren,
	|	CustomerSales.NumberOfInfants AS NumberOfInfants,
	|	CustomerSales.NumberOfPersons AS NumberOfPersons,
	|	CustomerSales.Sales AS Sales,
	|	CustomerSales.SalesWithoutVAT AS SalesWithoutVAT,
	|	CustomerSales.RoomRevenue AS RoomRevenue,
	|	CustomerSales.RoomRevenueWithoutCommission AS RoomRevenueWithoutCommission,
	|	CustomerSales.RoomRevenueWithoutVAT AS RoomRevenueWithoutVAT,
	|	CustomerSales.RoomRevenueWithoutVATWithoutCommission AS RoomRevenueWithoutVATWithoutCommission,
	|	CustomerSales.ExtraBedRevenue AS ExtraBedRevenue,
	|	CustomerSales.ExtraBedRevenueWithoutVAT AS ExtraBedRevenueWithoutVAT,
	|	CustomerSales.MainBedsRevenue AS MainBedsRevenue,
	|	CustomerSales.MainBedsRevenueWithoutVAT AS MainBedsRevenueWithoutVAT,
	|	CustomerSales.Sales - CustomerSales.RoomRevenue AS ExtraServicesRevenue,
	|	CustomerSales.SalesWithoutVAT - CustomerSales.RoomRevenueWithoutVAT AS ExtraServicesRevenueWithoutVAT,
	|	CustomerSales.CommissionSum AS CommissionSum,
	|	CustomerSales.CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|	CustomerSales.CalculatedCommissionSum AS CalculatedCommissionSum,
	|	CustomerSales.CalculatedCommissionSumWithoutVAT AS CalculatedCommissionSumWithoutVAT,
	|	CustomerSales.DiscountSum AS DiscountSum,
	|	CustomerSales.DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|	CustomerSales.BruttoSales AS BruttoSales,
	|	CustomerSales.BruttoSalesWithoutVAT AS BruttoSalesWithoutVAT,
	|	CustomerSales.SalesWithoutCommission AS SalesWithoutCommission,
	|	CustomerSales.SalesWithoutCommissionWithoutVAT AS SalesWithoutCommissionWithoutVAT,
	|	CustomerSales.SalesWithoutCalculatedCommission AS SalesWithoutCalculatedCommission,
	|	CustomerSales.SalesWithoutCalculatedCommissionWithoutVAT AS SalesWithoutCalculatedCommissionWithoutVAT,
	|	CustomerSales.RoomsRented AS RoomsRented,
	|	CustomerSales.BedsRented AS BedsRented,
	|	CustomerSales.AdditionalBedsRented AS AdditionalBedsRented,
	|	CustomerSales.GuestDays AS GuestDays,
	|	CustomerSales.GuestsCheckedIn AS GuestsCheckedIn,
	|	CustomerSales.RoomsCheckedIn AS RoomsCheckedIn,
	|	CustomerSales.BedsCheckedIn AS BedsCheckedIn,
	|	CustomerSales.AdditionalBedsCheckedIn AS AdditionalBedsCheckedIn,
	|	CustomerSales.Quantity AS Quantity,
	|	CustomerSales.VATSum AS VATSum,
	|	CustomerSales.PayedAmount AS PayedAmount,
	|	CustomerSales.PayedByCashAmount AS PayedByCashAmount,
	|	CustomerSales.PayedByCreditCardAmount AS PayedByCreditCardAmount,
	|	CustomerSales.PayedByBankTransferAmount AS PayedByBankTransferAmount,
	|	CustomerSales.PayedByInternetAcquiringAmount AS PayedByInternetAcquiringAmount,
	|	CustomerSales.PayedByBonusesAmount AS PayedByBonusesAmount,
	|	CustomerSales.PayedByGiftCertificatesAmount AS PayedByGiftCertificatesAmount,
	|	CustomerSales.RevenueSegmentRoomSales AS RevenueSegmentRoomSales,
	|	CustomerSales.RevenueSegmentRoomSalesWithoutVAT AS RevenueSegmentRoomSalesWithoutVAT,
	|	CustomerSales.RevenueSegmentFaBSales AS RevenueSegmentFaBSales,
	|	CustomerSales.RevenueSegmentFaBSalesWithoutVAT AS RevenueSegmentFaBSalesWithoutVAT,
	|	CustomerSales.RevenueSegmentSPASales AS RevenueSegmentSPASales,
	|	CustomerSales.RevenueSegmentSPASalesWithoutVAT AS RevenueSegmentSPASalesWithoutVAT,
	|	CustomerSales.RevenueSegmentConferenceSales AS RevenueSegmentConferenceSales,
	|	CustomerSales.RevenueSegmentConferenceSalesWithoutVAT AS RevenueSegmentConferenceSalesWithoutVAT,
	|	CustomerSales.RevenueSegmentOtherSales AS RevenueSegmentOtherSales,
	|	CustomerSales.RevenueSegmentOtherSalesWithoutVAT AS RevenueSegmentOtherSalesWithoutVAT,
	|	CASE
	|		WHEN CustomerSales.RoomsRented = 0
	|			THEN 0
	|		ELSE CustomerSales.RoomRevenue / CustomerSales.RoomsRented
	|	END AS ADR,
	|	CASE
	|		WHEN CustomerSales.RoomsRented = 0
	|			THEN 0
	|		ELSE CustomerSales.RoomRevenueWithoutVAT / CustomerSales.RoomsRented
	|	END AS ADRWithoutVAT
	|{SELECT
	|	Company.*,
	|	Hotel.*,
	|	ReportingCurrency.*,
	|	Agent.*,
	|	CustomerSales.RoomQuota.* AS RoomQuota,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	CustomerSales.Folio.* AS Folio,
	|	CustomerSales.VATRate.* AS VATRate,
	|	Client.*,
	|	ClientType.* AS ClientType,
	|	TripPurpose.* AS TripPurpose,
	|	SourceOfBusiness.* AS SourceOfBusiness,
	|	MarketingCode.* AS MarketingCode,
	|	CheckInDate,
	|	CheckOutDate,
	|	AccommodationType.*,
	|	CustomerSales.AccommodationTemplate.*,
	|	Status.*,
	|	Room.*,
	|	RoomType.*,
	|	CustomerSales.RoomTypeUpgrade.*,
	|	CustomerSales.IsRoomTypeUpgrade,
	|	Resource.*,
	|	RoomRate.*,
	|	(BEGINOFPERIOD(CustomerSales.CheckInDate, DAY)) AS CheckInDateNoTime,
	|	(BEGINOFPERIOD(CustomerSales.CheckOutDate, DAY)) AS CheckOutDateNoTime,
	|	(BEGINOFPERIOD(CustomerSales.GuestGroup.CheckInDate, DAY)) AS GuestGroupCheckInDateNoTime,
	|	(BEGINOFPERIOD(CustomerSales.GuestGroup.CheckOutDate, DAY)) AS GuestGroupCheckOutDateNoTime,
	|	ParentDoc.*,
	|	CustomerSales.Remarks AS Remarks,
	|	CustomerSales.ForeignerRegistryRecord.* AS ForeignerRegistryRecord,
	|	ReservationCustomAttributeValues1.CharacteristicValue.* AS CustomAttribute1,
	|	ReservationCustomAttributeValues2.CharacteristicValue.* AS CustomAttribute2,
	|	ReservationCustomAttributeValues3.CharacteristicValue.* AS CustomAttribute3,
	|	PaymentMethod.*,
	|	NumberOfAdults,
	|	NumberOfTeenagers,
	|	NumberOfChildren,
	|	NumberOfInfants,
	|	NumberOfPersons,
	|	Sales,
	|	SalesWithoutVAT,
	|	RoomRevenue,
	|	RoomRevenueWithoutCommission,
	|	RoomRevenueWithoutVAT,
	|	RoomRevenueWithoutVATWithoutCommission,
	|	ExtraBedRevenue,
	|	ExtraBedRevenueWithoutVAT,
	|	MainBedsRevenue,
	|	MainBedsRevenueWithoutVAT,
	|	ExtraServicesRevenue,
	|	ExtraServicesRevenueWithoutVAT,
	|	CommissionSum,
	|	CommissionSumWithoutVAT,
	|	CalculatedCommissionSum,
	|	CalculatedCommissionSumWithoutVAT,
	|	DiscountSum,
	|	DiscountSumWithoutVAT,
	|	BruttoSales,
	|	BruttoSalesWithoutVAT,
	|	SalesWithoutCommission,
	|	SalesWithoutCommissionWithoutVAT,
	|	SalesWithoutCalculatedCommission,
	|	SalesWithoutCalculatedCommissionWithoutVAT,
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
	|	NumberOfAdults,
	|	NumberOfTeenagers,
	|	NumberOfChildren,
	|	NumberOfInfants,
	|	NumberOfPersons,
	|	RevenueSegmentRoomSales,
	|	RevenueSegmentRoomSalesWithoutVAT,
	|	RevenueSegmentFaBSales,
	|	RevenueSegmentFaBSalesWithoutVAT,
	|	RevenueSegmentSPASales,
	|	RevenueSegmentSPASalesWithoutVAT,
	|	RevenueSegmentConferenceSales,
	|	RevenueSegmentConferenceSalesWithoutVAT,
	|	RevenueSegmentOtherSales,
	|	RevenueSegmentOtherSalesWithoutVAT,
	|	PayedAmount,
	|	PayedByCashAmount,
	|	PayedByCreditCardAmount,
	|	PayedByBankTransferAmount,
	|	PayedByInternetAcquiringAmount,
	|	PayedByBonusesAmount,
	|	PayedByGiftCertificatesAmount,
	|	(CASE
	|			WHEN CustomerSales.RoomsRented = 0
	|				THEN 0
	|			ELSE CustomerSales.RoomRevenue / CustomerSales.RoomsRented
	|		END) AS ADR,
	|	(CASE
	|			WHEN CustomerSales.RoomsRented = 0
	|				THEN 0
	|			ELSE CustomerSales.RoomRevenueWithoutVAT / CustomerSales.RoomsRented
	|		END) AS ADRWithoutVAT}
	|FROM
	|	(SELECT
	|		CustomerTurnovers.Company AS Company,
	|		CustomerTurnovers.Hotel AS Hotel,
	|		CustomerTurnovers.ReportingCurrency AS ReportingCurrency,
	|		CustomerTurnovers.Agent AS Agent,
	|		CustomerTurnovers.RoomQuota AS RoomQuota,
	|		CASE
	|			WHEN CustomerTurnovers.Customer = &qEmptyCustomer
	|				THEN CustomerTurnovers.Hotel.IndividualsCustomer
	|			ELSE CustomerTurnovers.Customer
	|		END AS Customer,
	|		CASE
	|			WHEN CustomerTurnovers.Customer = &qEmptyCustomer
	|				THEN CustomerTurnovers.Hotel.IndividualsContract
	|			ELSE CustomerTurnovers.Contract
	|		END AS Contract,
	|		CustomerTurnovers.GuestGroup AS GuestGroup,
	|		CustomerTurnovers.Folio AS Folio,
	|		CustomerTurnovers.VATRate AS VATRate,
	|		CustomerTurnovers.Client AS Client,
	|		CustomerTurnovers.ClientType AS ClientType,
	|		CustomerTurnovers.TripPurpose AS TripPurpose,
	|		CustomerTurnovers.SourceOfBusiness AS SourceOfBusiness,
	|		CustomerTurnovers.MarketingCode AS MarketingCode,
	|		CustomerTurnovers.CheckInDate AS CheckInDate,
	|		CustomerTurnovers.CheckOutDate AS CheckOutDate,
	|		CustomerTurnovers.AccommodationType AS AccommodationType,
	|		CASE
	|			WHEN CustomerTurnovers.AccommodationTemplate.Code IS NULL
	|				THEN CustomerTurnovers.ParentDoc.AccommodationTemplate
	|			ELSE CustomerTurnovers.AccommodationTemplate
	|		END AS AccommodationTemplate,
	|		CustomerTurnovers.Status AS Status,
	|		CustomerTurnovers.Room AS Room,
	|		CustomerTurnovers.RoomType AS RoomType,
	|		CustomerTurnovers.ParentDoc.RoomTypeUpgrade AS RoomTypeUpgrade,
	|		CASE
	|			WHEN CustomerTurnovers.ParentDoc.RoomTypeUpgrade <> CustomerTurnovers.RoomType
	|					AND NOT CustomerTurnovers.ParentDoc.RoomTypeUpgrade.Code IS NULL
	|				THEN TRUE
	|			ELSE FALSE
	|		END AS IsRoomTypeUpgrade,
	|		CustomerTurnovers.Resource AS Resource,
	|		CustomerTurnovers.RoomRate AS RoomRate,
	|		CustomerTurnovers.ParentDoc AS ParentDoc,
	|		CustomerTurnovers.PaymentMethod AS PaymentMethod,
	|		CustomerTurnovers.Remarks AS Remarks,
	|		ForeignerRegistryRecords.ForeignerRegistryRecord AS ForeignerRegistryRecord,
	|		SUM(CustomerTurnovers.Sales) AS Sales,
	|		SUM(CustomerTurnovers.SalesWithoutVAT) AS SalesWithoutVAT,
	|		SUM(CustomerTurnovers.RoomRevenue) AS RoomRevenue,
	|		SUM(CustomerTurnovers.RoomRevenue - CustomerTurnovers.CommissionSum) AS RoomRevenueWithoutCommission,
	|		SUM(CustomerTurnovers.RoomRevenueWithoutVAT) AS RoomRevenueWithoutVAT,
	|		SUM(CustomerTurnovers.RoomRevenueWithoutVAT - CustomerTurnovers.CommissionSumWithoutVAT) AS RoomRevenueWithoutVATWithoutCommission,
	|		SUM(CustomerTurnovers.ExtraBedRevenue) AS ExtraBedRevenue,
	|		SUM(CustomerTurnovers.ExtraBedRevenueWithoutVAT) AS ExtraBedRevenueWithoutVAT,
	|		SUM(CustomerTurnovers.MainBedsRevenue) AS MainBedsRevenue,
	|		SUM(CustomerTurnovers.MainBedsRevenueWithoutVAT) AS MainBedsRevenueWithoutVAT,
	|		SUM(CustomerTurnovers.CommissionSum) AS CommissionSum,
	|		SUM(CustomerTurnovers.CommissionSumWithoutVAT) AS CommissionSumWithoutVAT,
	|		SUM(CustomerTurnovers.CalculatedCommissionSum) AS CalculatedCommissionSum,
	|		SUM(CustomerTurnovers.CalculatedCommissionSumWithoutVAT) AS CalculatedCommissionSumWithoutVAT,
	|		SUM(CustomerTurnovers.DiscountSum) AS DiscountSum,
	|		SUM(CustomerTurnovers.DiscountSumWithoutVAT) AS DiscountSumWithoutVAT,
	|		SUM(CustomerTurnovers.Sales + CustomerTurnovers.DiscountSum) AS BruttoSales,
	|		SUM(CustomerTurnovers.SalesWithoutVAT + CustomerTurnovers.SalesWithoutVAT) AS BruttoSalesWithoutVAT,
	|		SUM(CustomerTurnovers.Sales - CustomerTurnovers.CommissionSum) AS SalesWithoutCommission,
	|		SUM(CustomerTurnovers.SalesWithoutVAT - CustomerTurnovers.CommissionSumWithoutVAT) AS SalesWithoutCommissionWithoutVAT,
	|		SUM(CustomerTurnovers.Sales + CustomerTurnovers.DiscountSum - CustomerTurnovers.CalculatedCommissionSum) AS SalesWithoutCalculatedCommission,
	|		SUM(CustomerTurnovers.SalesWithoutVAT + CustomerTurnovers.DiscountSumWithoutVAT - CustomerTurnovers.CalculatedCommissionSumWithoutVAT) AS SalesWithoutCalculatedCommissionWithoutVAT,
	|		SUM(CustomerTurnovers.RoomsRented) AS RoomsRented,
	|		SUM(CustomerTurnovers.BedsRented) AS BedsRented,
	|		SUM(CustomerTurnovers.AdditionalBedsRented) AS AdditionalBedsRented,
	|		SUM(CustomerTurnovers.GuestDays) AS GuestDays,
	|		SUM(CustomerTurnovers.GuestsCheckedIn) AS GuestsCheckedIn,
	|		SUM(CustomerTurnovers.RoomsCheckedIn) AS RoomsCheckedIn,
	|		SUM(CustomerTurnovers.BedsCheckedIn) AS BedsCheckedIn,
	|		SUM(CustomerTurnovers.AdditionalBedsCheckedIn) AS AdditionalBedsCheckedIn,
	|		SUM(CustomerTurnovers.Quantity) AS Quantity,
	|		SUM(CustomerTurnovers.PayedAmount) AS PayedAmount,
	|		SUM(CustomerTurnovers.PayedByCashAmount) AS PayedByCashAmount,
	|		SUM(CustomerTurnovers.PayedByCreditCardAmount) AS PayedByCreditCardAmount,
	|		SUM(CustomerTurnovers.PayedByBankTransferAmount) AS PayedByBankTransferAmount,
	|		SUM(CustomerTurnovers.PayedByInternetAcquiringAmount) AS PayedByInternetAcquiringAmount,
	|		SUM(CustomerTurnovers.PayedByBonusesAmount) AS PayedByBonusesAmount,
	|		SUM(CustomerTurnovers.PayedByGiftCertificatesAmount) AS PayedByGiftCertificatesAmount,
	|		SUM(CustomerTurnovers.VATSum) AS VATSum,
	|		SUM(CASE
	|				WHEN NOT CustomerTurnovers.AccommodationTemplate.NumberOfAdults IS NULL
	|					THEN CustomerTurnovers.AccommodationTemplate.NumberOfAdults
	|				WHEN CustomerTurnovers.ParentDoc.AccommodationType = CustomerTurnovers.AccommodationType
	|					THEN ISNULL(CustomerTurnovers.ParentDoc.NumberOfAdults, 0)
	|				ELSE 0
	|			END) AS NumberOfAdults,
	|		SUM(CASE
	|				WHEN NOT CustomerTurnovers.AccommodationTemplate.NumberOfTeenagers IS NULL
	|					THEN CustomerTurnovers.AccommodationTemplate.NumberOfTeenagers
	|				WHEN CustomerTurnovers.ParentDoc.AccommodationType = CustomerTurnovers.AccommodationType
	|					THEN ISNULL(CustomerTurnovers.ParentDoc.NumberOfTeenagers, 0)
	|				ELSE 0
	|			END) AS NumberOfTeenagers,
	|		SUM(CASE
	|				WHEN NOT CustomerTurnovers.AccommodationTemplate.NumberOfChildren IS NULL
	|					THEN CustomerTurnovers.AccommodationTemplate.NumberOfChildren
	|				WHEN CustomerTurnovers.ParentDoc.AccommodationType = CustomerTurnovers.AccommodationType
	|					THEN ISNULL(CustomerTurnovers.ParentDoc.NumberOfChildren, 0)
	|				ELSE 0
	|			END) AS NumberOfChildren,
	|		SUM(CASE
	|				WHEN NOT CustomerTurnovers.AccommodationTemplate.NumberOfInfants IS NULL
	|					THEN CustomerTurnovers.AccommodationTemplate.NumberOfInfants
	|				WHEN CustomerTurnovers.ParentDoc.AccommodationType = CustomerTurnovers.AccommodationType
	|					THEN ISNULL(CustomerTurnovers.ParentDoc.NumberOfInfants, 0)
	|				ELSE 0
	|			END) AS NumberOfInfants,
	|		SUM(CASE
	|				WHEN NOT CustomerTurnovers.AccommodationTemplate.NumberOfAdults IS NULL
	|					THEN CustomerTurnovers.AccommodationTemplate.NumberOfAdults + CustomerTurnovers.AccommodationTemplate.NumberOfTeenagers + CustomerTurnovers.AccommodationTemplate.NumberOfChildren + CustomerTurnovers.AccommodationTemplate.NumberOfInfants
	|				WHEN CustomerTurnovers.ParentDoc.AccommodationType = CustomerTurnovers.AccommodationType
	|					THEN ISNULL(CustomerTurnovers.ParentDoc.NumberOfAdults, 0) + ISNULL(CustomerTurnovers.ParentDoc.NumberOfTeenagers, 0) + ISNULL(CustomerTurnovers.ParentDoc.NumberOfChildren, 0) + ISNULL(CustomerTurnovers.ParentDoc.NumberOfInfants, 0)
	|			END) AS NumberOfPersons,
	|		SUM(CustomerTurnovers.RevenueSegmentRoomSales) AS RevenueSegmentRoomSales,
	|		SUM(CustomerTurnovers.RevenueSegmentRoomSalesWithoutVAT) AS RevenueSegmentRoomSalesWithoutVAT,
	|		SUM(CustomerTurnovers.RevenueSegmentFaBSales) AS RevenueSegmentFaBSales,
	|		SUM(CustomerTurnovers.RevenueSegmentFaBSalesWithoutVAT) AS RevenueSegmentFaBSalesWithoutVAT,
	|		SUM(CustomerTurnovers.RevenueSegmentSPASales) AS RevenueSegmentSPASales,
	|		SUM(CustomerTurnovers.RevenueSegmentSPASalesWithoutVAT) AS RevenueSegmentSPASalesWithoutVAT,
	|		SUM(CustomerTurnovers.RevenueSegmentConferenceSales) AS RevenueSegmentConferenceSales,
	|		SUM(CustomerTurnovers.RevenueSegmentConferenceSalesWithoutVAT) AS RevenueSegmentConferenceSalesWithoutVAT,
	|		SUM(CustomerTurnovers.RevenueSegmentOtherSales) AS RevenueSegmentOtherSales,
	|		SUM(CustomerTurnovers.RevenueSegmentOtherSalesWithoutVAT) AS RevenueSegmentOtherSalesWithoutVAT
	|	FROM
	|		(SELECT
	|			CustomerSales.Company AS Company,
	|			CustomerSales.Hotel AS Hotel,
	|			CustomerSales.ReportingCurrency AS ReportingCurrency,
	|			CustomerSales.Agent AS Agent,
	|			CustomerSales.RoomQuota AS RoomQuota,
	|			CustomerSales.Customer AS Customer,
	|			CustomerSales.Contract AS Contract,
	|			CustomerSales.ParentDoc AS ParentDoc,
	|			CustomerSales.Folio AS Folio,
	|			CustomerSales.VATRate AS VATRate,
	|			CAST(CustomerSales.ParentDoc.Remarks AS STRING(1024)) AS Remarks,
	|			CustomerSales.GuestGroup AS GuestGroup,
	|			CustomerSales.Client AS Client,
	|			CustomerSales.ClientType AS ClientType,
	|			CustomerSales.TripPurpose AS TripPurpose,
	|			CustomerSales.SourceOfBusiness AS SourceOfBusiness,
	|			CustomerSales.MarketingCode AS MarketingCode,
	|			CASE
	|				WHEN NOT CustomerSales.ParentDoc.CheckInDate IS NULL
	|					THEN CustomerSales.ParentDoc.CheckInDate
	|				WHEN NOT CustomerSales.ParentDoc.DateTimeFrom IS NULL
	|					THEN CustomerSales.ParentDoc.DateTimeFrom
	|				ELSE CustomerSales.Folio.DateTimeFrom
	|			END AS CheckInDate,
	|			CASE
	|				WHEN NOT CustomerSales.ParentDoc.CheckOutDate IS NULL
	|					THEN CustomerSales.ParentDoc.CheckOutDate
	|				WHEN NOT CustomerSales.ParentDoc.DateTimeTo IS NULL
	|					THEN CustomerSales.ParentDoc.DateTimeTo
	|				ELSE CustomerSales.Folio.DateTimeTo
	|			END AS CheckOutDate,
	|			CASE
	|				WHEN NOT CustomerSales.ParentDoc.AccommodationStatus IS NULL
	|					THEN CustomerSales.ParentDoc.AccommodationStatus
	|				WHEN NOT CustomerSales.ParentDoc.ReservationStatus IS NULL
	|					THEN CustomerSales.ParentDoc.ReservationStatus
	|				ELSE CustomerSales.ParentDoc.ResourceReservationStatus
	|			END AS Status,
	|			CustomerSales.AccommodationType AS AccommodationType,
	|			CustomerSales.AccommodationTemplate AS AccommodationTemplate,
	|			CustomerSales.Room AS Room,
	|			CustomerSales.RoomType AS RoomType,
	|			CustomerSales.RoomRate AS RoomRate,
	|			CustomerSales.Resource AS Resource,
	|			CustomerSales.PaymentMethod AS PaymentMethod,
	|			CustomerSales.SalesTurnover AS Sales,
	|			CustomerSales.SalesWithoutVATTurnover AS SalesWithoutVAT,
	|			CustomerSales.RoomRevenueTurnover AS RoomRevenue,
	|			CustomerSales.RoomRevenueWithoutVATTurnover AS RoomRevenueWithoutVAT,
	|			CustomerSales.ExtraBedRevenueTurnover AS ExtraBedRevenue,
	|			CustomerSales.ExtraBedRevenueWithoutVATTurnover AS ExtraBedRevenueWithoutVAT,
	|			CustomerSales.RoomRevenueTurnover - CustomerSales.ExtraBedRevenueTurnover AS MainBedsRevenue,
	|			CustomerSales.RoomRevenueWithoutVATTurnover - CustomerSales.ExtraBedRevenueWithoutVATTurnover AS MainBedsRevenueWithoutVAT,
	|			CustomerSales.CommissionSumTurnover AS CommissionSum,
	|			CustomerSales.CommissionSumWithoutVATTurnover AS CommissionSumWithoutVAT,
	|			(CustomerSales.SalesTurnover + CustomerSales.DiscountSumTurnover) * &qAgentCommission / 100 AS CalculatedCommissionSum,
	|			(CustomerSales.SalesWithoutVATTurnover + CustomerSales.DiscountSumWithoutVATTurnover) * &qAgentCommission / 100 AS CalculatedCommissionSumWithoutVAT,
	|			CustomerSales.DiscountSumTurnover AS DiscountSum,
	|			CustomerSales.DiscountSumWithoutVATTurnover AS DiscountSumWithoutVAT,
	|			CustomerSales.RoomsRentedTurnover AS RoomsRented,
	|			CustomerSales.BedsRentedTurnover AS BedsRented,
	|			CustomerSales.AdditionalBedsRentedTurnover AS AdditionalBedsRented,
	|			CustomerSales.GuestDaysTurnover AS GuestDays,
	|			CustomerSales.GuestsCheckedInTurnover AS GuestsCheckedIn,
	|			CustomerSales.RoomsCheckedInTurnover AS RoomsCheckedIn,
	|			CustomerSales.BedsCheckedInTurnover AS BedsCheckedIn,
	|			CustomerSales.AdditionalBedsCheckedInTurnover AS AdditionalBedsCheckedIn,
	|			CustomerSales.QuantityTurnover AS Quantity,
	|			CustomerSales.VATSumTurnover AS VATSum,
	|			0 AS PayedAmount,
	|			0 AS PayedByCashAmount,
	|			0 AS PayedByCreditCardAmount,
	|			0 AS PayedByBankTransferAmount,
	|			0 AS PayedByInternetAcquiringAmount,
	|			0 AS PayedByBonusesAmount,
	|			0 AS PayedByGiftCertificatesAmount,
	|			CASE
	|				WHEN CustomerSales.Service.ServiceType.RevenueSegment = VALUE(Enum.RevenueSegments.Room)
	|					THEN ISNULL(CustomerSales.SalesTurnover, 0)
	|				ELSE 0
	|			END AS RevenueSegmentRoomSales,
	|			CASE
	|				WHEN CustomerSales.Service.ServiceType.RevenueSegment = VALUE(Enum.RevenueSegments.Room)
	|					THEN ISNULL(CustomerSales.SalesWithoutVATTurnover, 0)
	|				ELSE 0
	|			END AS RevenueSegmentRoomSalesWithoutVAT,
	|			CASE
	|				WHEN CustomerSales.Service.ServiceType.RevenueSegment = VALUE(Enum.RevenueSegments.FaB)
	|					THEN ISNULL(CustomerSales.SalesTurnover, 0)
	|				ELSE 0
	|			END AS RevenueSegmentFaBSales,
	|			CASE
	|				WHEN CustomerSales.Service.ServiceType.RevenueSegment = VALUE(Enum.RevenueSegments.FaB)
	|					THEN ISNULL(CustomerSales.SalesWithoutVATTurnover, 0)
	|				ELSE 0
	|			END AS RevenueSegmentFaBSalesWithoutVAT,
	|			CASE
	|				WHEN CustomerSales.Service.ServiceType.RevenueSegment = VALUE(Enum.RevenueSegments.SPA)
	|					THEN ISNULL(CustomerSales.SalesTurnover, 0)
	|				ELSE 0
	|			END AS RevenueSegmentSPASales,
	|			CASE
	|				WHEN CustomerSales.Service.ServiceType.RevenueSegment = VALUE(Enum.RevenueSegments.SPA)
	|					THEN ISNULL(CustomerSales.SalesWithoutVATTurnover, 0)
	|				ELSE 0
	|			END AS RevenueSegmentSPASalesWithoutVAT,
	|			CASE
	|				WHEN CustomerSales.Service.ServiceType.RevenueSegment = VALUE(Enum.RevenueSegments.Conference)
	|					THEN ISNULL(CustomerSales.SalesTurnover, 0)
	|				ELSE 0
	|			END AS RevenueSegmentConferenceSales,
	|			CASE
	|				WHEN CustomerSales.Service.ServiceType.RevenueSegment = VALUE(Enum.RevenueSegments.Conference)
	|					THEN ISNULL(CustomerSales.SalesWithoutVATTurnover, 0)
	|				ELSE 0
	|			END AS RevenueSegmentConferenceSalesWithoutVAT,
	|			CASE
	|				WHEN CustomerSales.Service.ServiceType.RevenueSegment <> VALUE(Enum.RevenueSegments.Room)
	|						AND CustomerSales.Service.ServiceType.RevenueSegment <> VALUE(Enum.RevenueSegments.FaB)
	|						AND CustomerSales.Service.ServiceType.RevenueSegment <> VALUE(Enum.RevenueSegments.SPA)
	|						AND CustomerSales.Service.ServiceType.RevenueSegment <> VALUE(Enum.RevenueSegments.Conference)
	|					THEN ISNULL(CustomerSales.SalesTurnover, 0)
	|				ELSE 0
	|			END AS RevenueSegmentOtherSales,
	|			CASE
	|				WHEN CustomerSales.Service.ServiceType.RevenueSegment <> VALUE(Enum.RevenueSegments.Room)
	|						AND CustomerSales.Service.ServiceType.RevenueSegment <> VALUE(Enum.RevenueSegments.FaB)
	|						AND CustomerSales.Service.ServiceType.RevenueSegment <> VALUE(Enum.RevenueSegments.SPA)
	|						AND CustomerSales.Service.ServiceType.RevenueSegment <> VALUE(Enum.RevenueSegments.Conference)
	|					THEN ISNULL(CustomerSales.SalesWithoutVATTurnover, 0)
	|				ELSE 0
	|			END AS RevenueSegmentOtherSalesWithoutVAT
	|		FROM
	|			AccumulationRegister.Sales.Turnovers(
	|					&qServicesPeriodFrom,
	|					&qServicesPeriodTo,
	|					Period,
	|					NOT IsCorrection
	|						AND Hotel IN HIERARCHY (&qHotel)
	|						AND (GuestGroup = &qGuestGroup
	|							OR &qGuestGroupIsEmpty)
	|						AND (GuestGroup.Event IN HIERARCHY (&qEvent)
	|							OR &qEventIsEmpty)
	|						AND (Agent IN HIERARCHY (&qAgent)
	|							OR &qAgentIsEmpty)
	|						AND (Service IN (&qServicesList)
	|							OR NOT &qUseServicesList)
	|						AND (NOT &qByCheckInDates
	|							OR &qByCheckInDates
	|								AND CASE
	|									WHEN NOT ParentDoc.CheckInDate IS NULL
	|										THEN ParentDoc.CheckInDate
	|									WHEN NOT ParentDoc.DateTimeFrom IS NULL
	|										THEN ParentDoc.DateTimeFrom
	|									ELSE Folio.DateTimeFrom
	|								END >= &qPeriodFrom
	|								AND CASE
	|									WHEN NOT ParentDoc.CheckInDate IS NULL
	|										THEN ParentDoc.CheckInDate
	|									WHEN NOT ParentDoc.DateTimeFrom IS NULL
	|										THEN ParentDoc.DateTimeFrom
	|									ELSE Folio.DateTimeFrom
	|								END <= &qPeriodTo)
	|						AND (NOT &qByCheckOutDates
	|							OR &qByCheckOutDates
	|								AND CASE
	|									WHEN NOT ParentDoc.CheckOutDate IS NULL
	|										THEN ParentDoc.CheckOutDate
	|									WHEN NOT ParentDoc.DateTimeTo IS NULL
	|										THEN ParentDoc.DateTimeTo
	|									ELSE Folio.DateTimeTo
	|								END >= &qPeriodFrom
	|								AND CASE
	|									WHEN NOT ParentDoc.CheckOutDate IS NULL
	|										THEN ParentDoc.CheckOutDate
	|									WHEN NOT ParentDoc.DateTimeTo IS NULL
	|										THEN ParentDoc.DateTimeTo
	|									ELSE Folio.DateTimeTo
	|								END <= &qPeriodTo)
	|						AND (NOT &qByBookingDates
	|							OR &qByBookingDates
	|								AND ISNULL(ParentDoc.Reservation.Date, ParentDoc.Date) >= &qPeriodFrom
	|								AND ISNULL(ParentDoc.Reservation.Date, ParentDoc.Date) <= &qPeriodTo)) AS CustomerSales
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			CustomerSalesForecast.Company,
	|			CustomerSalesForecast.Hotel,
	|			CustomerSalesForecast.ReportingCurrency,
	|			CustomerSalesForecast.Agent,
	|			CustomerSalesForecast.RoomQuota,
	|			CustomerSalesForecast.Customer,
	|			CustomerSalesForecast.Contract,
	|			CustomerSalesForecast.ParentDoc,
	|			CustomerSalesForecast.Folio,
	|			CustomerSalesForecast.VATRate,
	|			CAST(CustomerSalesForecast.ParentDoc.Remarks AS STRING(1024)),
	|			CustomerSalesForecast.GuestGroup,
	|			CustomerSalesForecast.Client,
	|			CustomerSalesForecast.ClientType,
	|			CustomerSalesForecast.TripPurpose,
	|			CustomerSalesForecast.SourceOfBusiness,
	|			CustomerSalesForecast.MarketingCode,
	|			CASE
	|				WHEN NOT CustomerSalesForecast.ParentDoc.CheckInDate IS NULL
	|					THEN CustomerSalesForecast.ParentDoc.CheckInDate
	|				WHEN NOT CustomerSalesForecast.ParentDoc.DateTimeFrom IS NULL
	|					THEN CustomerSalesForecast.ParentDoc.DateTimeFrom
	|				ELSE CustomerSalesForecast.Folio.DateTimeFrom
	|			END,
	|			CASE
	|				WHEN NOT CustomerSalesForecast.ParentDoc.CheckOutDate IS NULL
	|					THEN CustomerSalesForecast.ParentDoc.CheckOutDate
	|				WHEN NOT CustomerSalesForecast.ParentDoc.DateTimeTo IS NULL
	|					THEN CustomerSalesForecast.ParentDoc.DateTimeTo
	|				ELSE CustomerSalesForecast.Folio.DateTimeTo
	|			END,
	|			CASE
	|				WHEN NOT CustomerSalesForecast.ParentDoc.AccommodationStatus IS NULL
	|					THEN CustomerSalesForecast.ParentDoc.AccommodationStatus
	|				WHEN NOT CustomerSalesForecast.ParentDoc.ReservationStatus IS NULL
	|					THEN CustomerSalesForecast.ParentDoc.ReservationStatus
	|				ELSE CustomerSalesForecast.ParentDoc.ResourceReservationStatus
	|			END,
	|			CustomerSalesForecast.AccommodationType,
	|			CustomerSalesForecast.AccommodationTemplate,
	|			CustomerSalesForecast.Room,
	|			CustomerSalesForecast.RoomType,
	|			CustomerSalesForecast.RoomRate,
	|			CustomerSalesForecast.Resource,
	|			CustomerSalesForecast.PaymentMethod,
	|			CustomerSalesForecast.SalesTurnover,
	|			CustomerSalesForecast.SalesWithoutVATTurnover,
	|			CustomerSalesForecast.RoomRevenueTurnover,
	|			CustomerSalesForecast.RoomRevenueWithoutVATTurnover,
	|			CustomerSalesForecast.ExtraBedRevenueTurnover,
	|			CustomerSalesForecast.ExtraBedRevenueWithoutVATTurnover,
	|			CustomerSalesForecast.RoomRevenueTurnover - CustomerSalesForecast.ExtraBedRevenueTurnover,
	|			CustomerSalesForecast.RoomRevenueWithoutVATTurnover - CustomerSalesForecast.ExtraBedRevenueWithoutVATTurnover,
	|			CustomerSalesForecast.CommissionSumTurnover,
	|			CustomerSalesForecast.CommissionSumWithoutVATTurnover,
	|			(CustomerSalesForecast.SalesTurnover + CustomerSalesForecast.DiscountSumTurnover) * &qAgentCommission / 100,
	|			(CustomerSalesForecast.SalesWithoutVATTurnover + CustomerSalesForecast.DiscountSumWithoutVATTurnover) * &qAgentCommission / 100,
	|			CustomerSalesForecast.DiscountSumTurnover,
	|			CustomerSalesForecast.DiscountSumWithoutVATTurnover,
	|			CustomerSalesForecast.RoomsRentedTurnover,
	|			CustomerSalesForecast.BedsRentedTurnover,
	|			CustomerSalesForecast.AdditionalBedsRentedTurnover,
	|			CustomerSalesForecast.GuestDaysTurnover,
	|			CustomerSalesForecast.GuestsCheckedInTurnover,
	|			CustomerSalesForecast.RoomsCheckedInTurnover,
	|			CustomerSalesForecast.BedsCheckedInTurnover,
	|			CustomerSalesForecast.AdditionalBedsCheckedInTurnover,
	|			CustomerSalesForecast.QuantityTurnover,
	|			CustomerSalesForecast.VATSumTurnover,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			CASE
	|				WHEN CustomerSalesForecast.Service.ServiceType.RevenueSegment = VALUE(Enum.RevenueSegments.Room)
	|					THEN ISNULL(CustomerSalesForecast.SalesTurnover, 0)
	|				ELSE 0
	|			END,
	|			CASE
	|				WHEN CustomerSalesForecast.Service.ServiceType.RevenueSegment = VALUE(Enum.RevenueSegments.Room)
	|					THEN ISNULL(CustomerSalesForecast.SalesWithoutVATTurnover, 0)
	|				ELSE 0
	|			END,
	|			CASE
	|				WHEN CustomerSalesForecast.Service.ServiceType.RevenueSegment = VALUE(Enum.RevenueSegments.FaB)
	|					THEN ISNULL(CustomerSalesForecast.SalesTurnover, 0)
	|				ELSE 0
	|			END,
	|			CASE
	|				WHEN CustomerSalesForecast.Service.ServiceType.RevenueSegment = VALUE(Enum.RevenueSegments.FaB)
	|					THEN ISNULL(CustomerSalesForecast.SalesWithoutVATTurnover, 0)
	|				ELSE 0
	|			END,
	|			CASE
	|				WHEN CustomerSalesForecast.Service.ServiceType.RevenueSegment = VALUE(Enum.RevenueSegments.SPA)
	|					THEN ISNULL(CustomerSalesForecast.SalesTurnover, 0)
	|				ELSE 0
	|			END,
	|			CASE
	|				WHEN CustomerSalesForecast.Service.ServiceType.RevenueSegment = VALUE(Enum.RevenueSegments.SPA)
	|					THEN ISNULL(CustomerSalesForecast.SalesWithoutVATTurnover, 0)
	|				ELSE 0
	|			END,
	|			CASE
	|				WHEN CustomerSalesForecast.Service.ServiceType.RevenueSegment = VALUE(Enum.RevenueSegments.Conference)
	|					THEN ISNULL(CustomerSalesForecast.SalesTurnover, 0)
	|				ELSE 0
	|			END,
	|			CASE
	|				WHEN CustomerSalesForecast.Service.ServiceType.RevenueSegment = VALUE(Enum.RevenueSegments.Conference)
	|					THEN ISNULL(CustomerSalesForecast.SalesWithoutVATTurnover, 0)
	|				ELSE 0
	|			END,
	|			CASE
	|				WHEN CustomerSalesForecast.Service.ServiceType.RevenueSegment <> VALUE(Enum.RevenueSegments.Room)
	|						AND CustomerSalesForecast.Service.ServiceType.RevenueSegment <> VALUE(Enum.RevenueSegments.FaB)
	|						AND CustomerSalesForecast.Service.ServiceType.RevenueSegment <> VALUE(Enum.RevenueSegments.SPA)
	|						AND CustomerSalesForecast.Service.ServiceType.RevenueSegment <> VALUE(Enum.RevenueSegments.Conference)
	|					THEN ISNULL(CustomerSalesForecast.SalesTurnover, 0)
	|				ELSE 0
	|			END,
	|			CASE
	|				WHEN CustomerSalesForecast.Service.ServiceType.RevenueSegment <> VALUE(Enum.RevenueSegments.Room)
	|						AND CustomerSalesForecast.Service.ServiceType.RevenueSegment <> VALUE(Enum.RevenueSegments.FaB)
	|						AND CustomerSalesForecast.Service.ServiceType.RevenueSegment <> VALUE(Enum.RevenueSegments.SPA)
	|						AND CustomerSalesForecast.Service.ServiceType.RevenueSegment <> VALUE(Enum.RevenueSegments.Conference)
	|					THEN ISNULL(CustomerSalesForecast.SalesWithoutVATTurnover, 0)
	|				ELSE 0
	|			END
	|		FROM
	|			AccumulationRegister.SalesForecast.Turnovers(
	|					&qForecastPeriodFrom,
	|					&qForecastPeriodTo,
	|					Period,
	|					&qShowForecastByReservations
	|						AND Hotel IN HIERARCHY (&qHotel)
	|						AND (GuestGroup = &qGuestGroup
	|							OR &qGuestGroupIsEmpty)
	|						AND (GuestGroup.Event IN HIERARCHY (&qEvent)
	|							OR &qEventIsEmpty)
	|						AND (Agent IN HIERARCHY (&qAgent)
	|							OR &qAgentIsEmpty)
	|						AND (Service IN (&qServicesList)
	|							OR NOT &qUseServicesList)
	|						AND (NOT &qByCheckInDates
	|							OR &qByCheckInDates
	|								AND CASE
	|									WHEN NOT ParentDoc.CheckInDate IS NULL
	|										THEN ParentDoc.CheckInDate
	|									WHEN NOT ParentDoc.DateTimeFrom IS NULL
	|										THEN ParentDoc.DateTimeFrom
	|									ELSE Folio.DateTimeFrom
	|								END >= &qPeriodFrom
	|								AND CASE
	|									WHEN NOT ParentDoc.CheckInDate IS NULL
	|										THEN ParentDoc.CheckInDate
	|									WHEN NOT ParentDoc.DateTimeFrom IS NULL
	|										THEN ParentDoc.DateTimeFrom
	|									ELSE Folio.DateTimeFrom
	|								END <= &qPeriodTo)
	|						AND (NOT &qByCheckOutDates
	|							OR &qByCheckOutDates
	|								AND CASE
	|									WHEN NOT ParentDoc.CheckOutDate IS NULL
	|										THEN ParentDoc.CheckOutDate
	|									WHEN NOT ParentDoc.DateTimeTo IS NULL
	|										THEN ParentDoc.DateTimeTo
	|									ELSE Folio.DateTimeTo
	|								END >= &qPeriodFrom
	|								AND CASE
	|									WHEN NOT ParentDoc.CheckOutDate IS NULL
	|										THEN ParentDoc.CheckOutDate
	|									WHEN NOT ParentDoc.DateTimeTo IS NULL
	|										THEN ParentDoc.DateTimeTo
	|									ELSE Folio.DateTimeTo
	|								END <= &qPeriodTo)
	|						AND (NOT &qByBookingDates
	|							OR &qByBookingDates
	|								AND ISNULL(ParentDoc.Reservation.Date, ParentDoc.Date) >= &qPeriodFrom
	|								AND ISNULL(ParentDoc.Reservation.Date, ParentDoc.Date) <= &qPeriodTo)) AS CustomerSalesForecast
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			CustomerAccounts.Company,
	|			CustomerAccounts.Hotel,
	|			CustomerAccounts.AccountingCurrency,
	|			CustomerAccounts.Folio.Agent,
	|			CustomerAccounts.ParentDoc.RoomQuota,
	|			CustomerAccounts.AccountingCustomer,
	|			CustomerAccounts.AccountingContract,
	|			CustomerAccounts.ParentDoc,
	|			CustomerAccounts.Folio,
	|			CustomerAccounts.VATRate,
	|			CAST(CustomerAccounts.ParentDoc.Remarks AS STRING(1024)),
	|			CustomerAccounts.GuestGroup,
	|			CustomerAccounts.Client,
	|			CustomerAccounts.ParentDoc.ClientType,
	|			CustomerAccounts.ParentDoc.TripPurpose,
	|			CustomerAccounts.ParentDoc.SourceOfBusiness,
	|			CustomerAccounts.ParentDoc.MarketingCode,
	|			CASE
	|				WHEN NOT CustomerAccounts.ParentDoc.CheckInDate IS NULL
	|					THEN CustomerAccounts.ParentDoc.CheckInDate
	|				WHEN NOT CustomerAccounts.ParentDoc.DateTimeFrom IS NULL
	|					THEN CustomerAccounts.ParentDoc.DateTimeFrom
	|				ELSE CustomerAccounts.Folio.DateTimeFrom
	|			END,
	|			CASE
	|				WHEN NOT CustomerAccounts.ParentDoc.CheckOutDate IS NULL
	|					THEN CustomerAccounts.ParentDoc.CheckOutDate
	|				WHEN NOT CustomerAccounts.ParentDoc.DateTimeTo IS NULL
	|					THEN CustomerAccounts.ParentDoc.DateTimeTo
	|				ELSE CustomerAccounts.Folio.DateTimeTo
	|			END,
	|			CASE
	|				WHEN NOT CustomerAccounts.ParentDoc.AccommodationStatus IS NULL
	|					THEN CustomerAccounts.ParentDoc.AccommodationStatus
	|				WHEN NOT CustomerAccounts.ParentDoc.ReservationStatus IS NULL
	|					THEN CustomerAccounts.ParentDoc.ReservationStatus
	|				ELSE CustomerAccounts.ParentDoc.ResourceReservationStatus
	|			END,
	|			CustomerAccounts.ParentDoc.AccommodationType,
	|			CustomerAccounts.ParentDoc.AccommodationTemplate,
	|			CustomerAccounts.Room,
	|			CustomerAccounts.ParentDoc.RoomType,
	|			CustomerAccounts.ParentDoc.RoomRate,
	|			CustomerAccounts.Resource,
	|			CustomerAccounts.Folio.PaymentMethod,
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
	|			CustomerAccounts.Sum,
	|			CASE
	|				WHEN CustomerAccounts.Recorder.PaymentMethod.IsByCash
	|					THEN CustomerAccounts.Sum
	|				ELSE 0
	|			END,
	|			CASE
	|				WHEN CustomerAccounts.Recorder.PaymentMethod.IsByCreditCard
	|					THEN CustomerAccounts.Sum
	|				ELSE 0
	|			END,
	|			CASE
	|				WHEN CustomerAccounts.Recorder.PaymentMethod.IsByBankTransfer
	|					THEN CustomerAccounts.Sum
	|				ELSE 0
	|			END,
	|			CASE
	|				WHEN CustomerAccounts.Recorder.PaymentMethod.IsViaInternetAcquiring
	|					THEN CustomerAccounts.Sum
	|				ELSE 0
	|			END,
	|			CASE
	|				WHEN CustomerAccounts.Recorder.PaymentMethod.IsByBonuses
	|					THEN CustomerAccounts.Sum
	|				ELSE 0
	|			END,
	|			CASE
	|				WHEN CustomerAccounts.Recorder.PaymentMethod.IsByGiftCertificate
	|					THEN CustomerAccounts.Sum
	|				ELSE 0
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
	|			0
	|		FROM
	|			AccumulationRegister.CustomerAccounts AS CustomerAccounts
	|		WHERE
	|			&qShowPayedAmount
	|			AND NOT CustomerAccounts.Recorder REFS Document.Settlement
	|			AND NOT CustomerAccounts.Recorder REFS Document.CreditNote
	|			AND NOT CustomerAccounts.Recorder REFS Document.DebitNote
	|			AND CustomerAccounts.Hotel IN HIERARCHY(&qHotel)
	|			AND (CustomerAccounts.GuestGroup = &qGuestGroup
	|					OR &qGuestGroupIsEmpty)
	|			AND CustomerAccounts.GuestGroup IN
	|					(SELECT
	|						GuestGroups.GuestGroup
	|					FROM
	|						GuestGroups AS GuestGroups)) AS CustomerTurnovers
	|			LEFT JOIN InformationRegister.AccommodationForeignerRegistryRecords.SliceLast(&qEndOfTime, ) AS ForeignerRegistryRecords
	|			ON CustomerTurnovers.ParentDoc = ForeignerRegistryRecords.Accommodation
	|	
	|	GROUP BY
	|		CustomerTurnovers.Company,
	|		CustomerTurnovers.Hotel,
	|		CustomerTurnovers.ReportingCurrency,
	|		CustomerTurnovers.Agent,
	|		CustomerTurnovers.RoomQuota,
	|		CASE
	|			WHEN CustomerTurnovers.Customer = &qEmptyCustomer
	|				THEN CustomerTurnovers.Hotel.IndividualsCustomer
	|			ELSE CustomerTurnovers.Customer
	|		END,
	|		CASE
	|			WHEN CustomerTurnovers.Customer = &qEmptyCustomer
	|				THEN CustomerTurnovers.Hotel.IndividualsContract
	|			ELSE CustomerTurnovers.Contract
	|		END,
	|		CustomerTurnovers.GuestGroup,
	|		CustomerTurnovers.Folio,
	|		CustomerTurnovers.VATRate,
	|		CustomerTurnovers.Client,
	|		CustomerTurnovers.ClientType,
	|		CustomerTurnovers.TripPurpose,
	|		CustomerTurnovers.SourceOfBusiness,
	|		CustomerTurnovers.MarketingCode,
	|		CustomerTurnovers.CheckInDate,
	|		CustomerTurnovers.CheckOutDate,
	|		CustomerTurnovers.AccommodationType,
	|		CASE
	|			WHEN CustomerTurnovers.AccommodationTemplate.Code IS NULL
	|				THEN CustomerTurnovers.ParentDoc.AccommodationTemplate
	|			ELSE CustomerTurnovers.AccommodationTemplate
	|		END,
	|		CustomerTurnovers.Status,
	|		CustomerTurnovers.Room,
	|		CustomerTurnovers.RoomType,
	|		CustomerTurnovers.ParentDoc.RoomTypeUpgrade,
	|		CASE
	|			WHEN CustomerTurnovers.ParentDoc.RoomTypeUpgrade <> CustomerTurnovers.RoomType
	|					AND NOT CustomerTurnovers.ParentDoc.RoomTypeUpgrade.Code IS NULL
	|				THEN TRUE
	|			ELSE FALSE
	|		END,
	|		CustomerTurnovers.Resource,
	|		CustomerTurnovers.RoomRate,
	|		CustomerTurnovers.ParentDoc,
	|		CustomerTurnovers.PaymentMethod,
	|		CustomerTurnovers.Remarks,
	|		ForeignerRegistryRecords.ForeignerRegistryRecord) AS CustomerSales
	|		LEFT JOIN InformationRegister.ReservationCustomAttributeValues AS ReservationCustomAttributeValues1
	|		ON (CustomerSales.ParentDoc.Reservation = ReservationCustomAttributeValues1.Owner
	|				OR CustomerSales.ParentDoc = ReservationCustomAttributeValues1.Owner
	|					AND CustomerSales.ParentDoc.Reservation.Number IS NULL)
	|			AND (ReservationCustomAttributeValues1.Characteristic = &qCustomAttribute1)
	|		LEFT JOIN InformationRegister.ReservationCustomAttributeValues AS ReservationCustomAttributeValues2
	|		ON (CustomerSales.ParentDoc.Reservation = ReservationCustomAttributeValues2.Owner
	|				OR CustomerSales.ParentDoc = ReservationCustomAttributeValues2.Owner
	|					AND CustomerSales.ParentDoc.Reservation.Number IS NULL)
	|			AND (ReservationCustomAttributeValues2.Characteristic = &qCustomAttribute2)
	|		LEFT JOIN InformationRegister.ReservationCustomAttributeValues AS ReservationCustomAttributeValues3
	|		ON (CustomerSales.ParentDoc.Reservation = ReservationCustomAttributeValues3.Owner
	|				OR CustomerSales.ParentDoc = ReservationCustomAttributeValues3.Owner
	|					AND CustomerSales.ParentDoc.Reservation.Number IS NULL)
	|			AND (ReservationCustomAttributeValues3.Characteristic = &qCustomAttribute3)
	|WHERE
	|	(&qCustomerIsEmpty
	|			OR NOT &qCustomerIsEmpty
	|				AND CustomerSales.Customer IN HIERARCHY (&qCustomer))
	|	AND (&qContractIsEmpty
	|			OR NOT &qContractIsEmpty
	|				AND CustomerSales.Contract IN HIERARCHY (&qContract))
	|{WHERE
	|	CustomerSales.Company.*,
	|	CustomerSales.Hotel.*,
	|	CustomerSales.ReportingCurrency.*,
	|	CustomerSales.Customer.*,
	|	CustomerSales.Contract.*,
	|	CustomerSales.GuestGroup.*,
	|	CustomerSales.Folio.*,
	|	CustomerSales.VATRate.*,
	|	CustomerSales.RoomQuota.* AS RoomQuota,
	|	CustomerSales.Agent.*,
	|	CustomerSales.Client.*,
	|	CustomerSales.ClientType.* AS ClientType,
	|	CustomerSales.TripPurpose.* AS TripPurpose,
	|	CustomerSales.SourceOfBusiness.* AS SourceOfBusiness,
	|	CustomerSales.MarketingCode.* AS MarketingCode,
	|	CustomerSales.CheckInDate,
	|	CustomerSales.CheckOutDate,
	|	CustomerSales.AccommodationType.*,
	|	CustomerSales.AccommodationTemplate.*,
	|	CustomerSales.Status.*,
	|	CustomerSales.Room.*,
	|	CustomerSales.RoomType.*,
	|	CustomerSales.RoomTypeUpgrade.*,
	|	CustomerSales.IsRoomTypeUpgrade,
	|	CustomerSales.Resource.*,
	|	CustomerSales.RoomRate.*,
	|	(BEGINOFPERIOD(CustomerSales.CheckInDate, DAY)) AS CheckInDateNoTime,
	|	(BEGINOFPERIOD(CustomerSales.CheckOutDate, DAY)) AS CheckOutDateNoTime,
	|	(BEGINOFPERIOD(CustomerSales.GuestGroup.CheckInDate, DAY)) AS GuestGroupCheckInDateNoTime,
	|	(BEGINOFPERIOD(CustomerSales.GuestGroup.CheckOutDate, DAY)) AS GuestGroupCheckOutDateNoTime,
	|	CustomerSales.ParentDoc.*,
	|	CustomerSales.Remarks AS Remarks,
	|	CustomerSales.ForeignerRegistryRecord.* AS ForeignerRegistryRecord,
	|	ReservationCustomAttributeValues1.CharacteristicValue.* AS CustomAttribute1,
	|	ReservationCustomAttributeValues2.CharacteristicValue.* AS CustomAttribute2,
	|	ReservationCustomAttributeValues3.CharacteristicValue.* AS CustomAttribute3,
	|	CustomerSales.PaymentMethod.*,
	|	CustomerSales.Sales,
	|	CustomerSales.SalesWithoutVAT,
	|	CustomerSales.RoomRevenue,
	|	CustomerSales.RoomRevenueWithoutVAT,
	|	CustomerSales.ExtraBedRevenue,
	|	CustomerSales.ExtraBedRevenueWithoutVAT,
	|	CustomerSales.MainBedsRevenue,
	|	CustomerSales.MainBedsRevenueWithoutVAT,
	|	(CustomerSales.Sales - CustomerSales.RoomRevenue) AS ExtraServicesRevenue,
	|	(CustomerSales.SalesWithoutVAT - CustomerSales.RoomRevenueWithoutVAT) AS ExtraServicesRevenueWithoutVAT,
	|	CustomerSales.CommissionSum,
	|	CustomerSales.CommissionSumWithoutVAT,
	|	CustomerSales.CalculatedCommissionSum,
	|	CustomerSales.CalculatedCommissionSumWithoutVAT,
	|	CustomerSales.DiscountSum,
	|	CustomerSales.DiscountSumWithoutVAT,
	|	CustomerSales.RoomsRented,
	|	CustomerSales.BedsRented,
	|	CustomerSales.AdditionalBedsRented,
	|	CustomerSales.GuestDays,
	|	CustomerSales.GuestsCheckedIn,
	|	CustomerSales.RoomsCheckedIn,
	|	CustomerSales.BedsCheckedIn,
	|	CustomerSales.AdditionalBedsCheckedIn,
	|	CustomerSales.Quantity,
	|	CustomerSales.RevenueSegmentRoomSales AS RevenueSegmentRoomSales,
	|	CustomerSales.RevenueSegmentRoomSalesWithoutVAT AS RevenueSegmentRoomSalesWithoutVAT,
	|	CustomerSales.RevenueSegmentFaBSales AS RevenueSegmentFaBSales,
	|	CustomerSales.RevenueSegmentFaBSalesWithoutVAT AS RevenueSegmentFaBSalesWithoutVAT,
	|	CustomerSales.RevenueSegmentSPASales AS RevenueSegmentSPASales,
	|	CustomerSales.RevenueSegmentSPASalesWithoutVAT AS RevenueSegmentSPASalesWithoutVAT,
	|	CustomerSales.RevenueSegmentConferenceSales AS RevenueSegmentConferenceSales,
	|	CustomerSales.RevenueSegmentConferenceSalesWithoutVAT AS RevenueSegmentConferenceSalesWithoutVAT,
	|	CustomerSales.RevenueSegmentOtherSales AS RevenueSegmentOtherSales,
	|	CustomerSales.RevenueSegmentOtherSalesWithoutVAT AS RevenueSegmentOtherSalesWithoutVAT,
	|	CustomerSales.PayedAmount,
	|	CustomerSales.PayedByCashAmount,
	|	CustomerSales.PayedByCreditCardAmount,
	|	CustomerSales.PayedByBankTransferAmount,
	|	CustomerSales.PayedByInternetAcquiringAmount,
	|	CustomerSales.PayedByBonusesAmount,
	|	CustomerSales.PayedByGiftCertificatesAmount}
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
	|	Client
	|{ORDER BY
	|	Company.*,
	|	Hotel.*,
	|	ReportingCurrency.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	CustomerSales.Folio.*,
	|	CustomerSales.VATRate.*,
	|	Client.*,
	|	ClientType.* AS ClientType,
	|	TripPurpose.* AS TripPurpose,
	|	SourceOfBusiness.* AS SourceOfBusiness,
	|	MarketingCode.* AS MarketingCode,
	|	Agent.*,
	|	CustomerSales.RoomQuota.* AS RoomQuota,
	|	CheckInDate,
	|	CheckOutDate,
	|	AccommodationType.*,
	|	CustomerSales.AccommodationTemplate.*,
	|	Status.*,
	|	Room.*,
	|	RoomType.*,
	|	CustomerSales.RoomTypeUpgrade.*,
	|	Resource.*,
	|	RoomRate.*,
	|	(BEGINOFPERIOD(CustomerSales.CheckInDate, DAY)) AS CheckInDateNoTime,
	|	(BEGINOFPERIOD(CustomerSales.CheckOutDate, DAY)) AS CheckOutDateNoTime,
	|	(BEGINOFPERIOD(CustomerSales.GuestGroup.CheckInDate, DAY)) AS GuestGroupCheckInDateNoTime,
	|	(BEGINOFPERIOD(CustomerSales.GuestGroup.CheckOutDate, DAY)) AS GuestGroupCheckOutDateNoTime,
	|	ParentDoc.*,
	|	CustomerSales.ForeignerRegistryRecord.* AS ForeignerRegistryRecord,
	|	ReservationCustomAttributeValues1.CharacteristicValue.* AS CustomAttribute1,
	|	ReservationCustomAttributeValues2.CharacteristicValue.* AS CustomAttribute2,
	|	ReservationCustomAttributeValues3.CharacteristicValue.* AS CustomAttribute3,
	|	PaymentMethod.*,
	|	Sales,
	|	SalesWithoutVAT,
	|	RoomRevenue,
	|	RoomRevenueWithoutVAT,
	|	ExtraBedRevenue,
	|	ExtraBedRevenueWithoutVAT,
	|	MainBedsRevenue,
	|	MainBedsRevenueWithoutVAT,
	|	ExtraServicesRevenue,
	|	ExtraServicesRevenueWithoutVAT,
	|	CommissionSum,
	|	CommissionSumWithoutVAT,
	|	CalculatedCommissionSum,
	|	CalculatedCommissionSumWithoutVAT,
	|	DiscountSum,
	|	DiscountSumWithoutVAT,
	|	BruttoSales,
	|	BruttoSalesWithoutVAT,
	|	SalesWithoutCommission,
	|	SalesWithoutCommissionWithoutVAT,
	|	SalesWithoutCalculatedCommission,
	|	SalesWithoutCalculatedCommissionWithoutVAT,
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
	|	RevenueSegmentRoomSales,
	|	RevenueSegmentRoomSalesWithoutVAT,
	|	RevenueSegmentFaBSales,
	|	RevenueSegmentFaBSalesWithoutVAT,
	|	RevenueSegmentSPASales,
	|	RevenueSegmentSPASalesWithoutVAT,
	|	RevenueSegmentConferenceSales,
	|	RevenueSegmentConferenceSalesWithoutVAT,
	|	RevenueSegmentOtherSales,
	|	RevenueSegmentOtherSalesWithoutVAT,
	|	PayedAmount,
	|	PayedByCashAmount,
	|	PayedByCreditCardAmount,
	|	PayedByBankTransferAmount,
	|	PayedByInternetAcquiringAmount,
	|	PayedByBonusesAmount,
	|	PayedByGiftCertificatesAmount}
	|TOTALS
	|	SUM(NumberOfAdults),
	|	SUM(NumberOfTeenagers),
	|	SUM(NumberOfChildren),
	|	SUM(NumberOfInfants),
	|	SUM(NumberOfPersons),
	|	SUM(Sales),
	|	SUM(SalesWithoutVAT),
	|	SUM(RoomRevenue),
	|	SUM(RoomRevenueWithoutCommission),
	|	SUM(RoomRevenueWithoutVAT),
	|	SUM(RoomRevenueWithoutVATWithoutCommission),
	|	SUM(ExtraBedRevenue),
	|	SUM(ExtraBedRevenueWithoutVAT),
	|	SUM(MainBedsRevenue),
	|	SUM(MainBedsRevenueWithoutVAT),
	|	SUM(ExtraServicesRevenue),
	|	SUM(ExtraServicesRevenueWithoutVAT),
	|	SUM(CommissionSum),
	|	SUM(CommissionSumWithoutVAT),
	|	SUM(CalculatedCommissionSum),
	|	SUM(CalculatedCommissionSumWithoutVAT),
	|	SUM(DiscountSum),
	|	SUM(DiscountSumWithoutVAT),
	|	SUM(BruttoSales),
	|	SUM(BruttoSalesWithoutVAT),
	|	SUM(SalesWithoutCommission),
	|	SUM(SalesWithoutCommissionWithoutVAT),
	|	SUM(SalesWithoutCalculatedCommission),
	|	SUM(SalesWithoutCalculatedCommissionWithoutVAT),
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
	|	SUM(PayedAmount),
	|	SUM(PayedByCashAmount),
	|	SUM(PayedByCreditCardAmount),
	|	SUM(PayedByBankTransferAmount),
	|	SUM(PayedByInternetAcquiringAmount),
	|	SUM(PayedByBonusesAmount),
	|	SUM(PayedByGiftCertificatesAmount),
	|	SUM(RevenueSegmentRoomSales),
	|	SUM(RevenueSegmentRoomSalesWithoutVAT),
	|	SUM(RevenueSegmentFaBSales),
	|	SUM(RevenueSegmentFaBSalesWithoutVAT),
	|	SUM(RevenueSegmentSPASales),
	|	SUM(RevenueSegmentSPASalesWithoutVAT),
	|	SUM(RevenueSegmentConferenceSales),
	|	SUM(RevenueSegmentConferenceSalesWithoutVAT),
	|	SUM(RevenueSegmentOtherSales),
	|	SUM(RevenueSegmentOtherSalesWithoutVAT),
	|	CASE
	|		WHEN SUM(RoomsRented) = 0
	|			THEN 0
	|		ELSE SUM(RoomRevenue) / SUM(RoomsRented)
	|	END AS ADR,
	|	CASE
	|		WHEN SUM(RoomsRented) = 0
	|			THEN 0
	|		ELSE SUM(RoomRevenueWithoutVAT) / SUM(RoomsRented)
	|	END AS ADRWithoutVAT
	|BY
	|	OVERALL,
	|	Hotel,
	|	ReportingCurrency,
	|	Agent,
	|	Customer,
	|	Contract,
	|	GuestGroup
	|{TOTALS BY
	|	Company.*,
	|	Hotel.*,
	|	ReportingCurrency.*,
	|	Agent.*,
	|	CustomerSales.RoomQuota.* AS RoomQuota,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	CustomerSales.Folio.*,
	|	CustomerSales.VATRate.*,
	|	Client.*,
	|	ClientType.* AS ClientType,
	|	TripPurpose.* AS TripPurpose,
	|	SourceOfBusiness.* AS SourceOfBusiness,
	|	MarketingCode.* AS MarketingCode,
	|	Room.*,
	|	AccommodationType.*,
	|	CustomerSales.AccommodationTemplate.*,
	|	Status.*,
	|	RoomType.*,
	|	CustomerSales.RoomTypeUpgrade.*,
	|	RoomRate.*,
	|	(BEGINOFPERIOD(CustomerSales.CheckInDate, DAY)) AS CheckInDateNoTime,
	|	(BEGINOFPERIOD(CustomerSales.CheckOutDate, DAY)) AS CheckOutDateNoTime,
	|	(BEGINOFPERIOD(CustomerSales.GuestGroup.CheckInDate, DAY)) AS GuestGroupCheckInDateNoTime,
	|	(BEGINOFPERIOD(CustomerSales.GuestGroup.CheckOutDate, DAY)) AS GuestGroupCheckOutDateNoTime,
	|	Resource.*,
	|	PaymentMethod.*,
	|	CustomerSales.ForeignerRegistryRecord.* AS ForeignerRegistryRecord,
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
	ReportBuilder.HeaderText = NStr("EN='Customer sales';RU='Продажи по гостям оплачиваемым контрагентами';de='Verkäufe nach Gästen, die vom Vertragspartner bezahlt werden'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
