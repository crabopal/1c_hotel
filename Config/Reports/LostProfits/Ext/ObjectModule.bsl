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
		vParamPresentation = vParamPresentation + NStr("en='Guest group ';ru='Группа ';de='Gruppe '") + 
							 TrimAll(GuestGroup.Code) + 
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
	If ValueIsFilled(Hotel) Then
		If Not Hotel.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Hotel ';ru='Гостиница ';de='Hotel '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Hotels folder ';ru='Группа гостиниц ';de='Hotelsgruppe '") + 
			                     TrimAll(Hotel.Description) + 
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
	ReportBuilder.Parameters.Insert("qServicesPeriodFrom", '00010101');
	ReportBuilder.Parameters.Insert("qServicesPeriodTo", '39991231');
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
	ReportBuilder.Parameters.Insert("qEndOfTime", '39991231');
	
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
	|	CustomerTurnovers.Company AS Company,
	|	CustomerTurnovers.Hotel AS Hotel,
	|	CustomerTurnovers.FolioCurrency AS FolioCurrency,
	|	CustomerTurnovers.Agent AS Agent,
	|	CustomerTurnovers.Customer AS Customer,
	|	CustomerTurnovers.Contract AS Contract,
	|	CustomerTurnovers.GuestGroup AS GuestGroup,
	|	CustomerTurnovers.Client AS Client,
	|	CustomerTurnovers.CheckInDate AS CheckInDate,
	|	CustomerTurnovers.CheckOutDate,
	|	CustomerTurnovers.AccommodationType AS AccommodationType,
	|	CustomerTurnovers.Status AS Status,
	|	CustomerTurnovers.Room AS Room,
	|	CustomerTurnovers.RoomType AS RoomType,
	|	CustomerTurnovers.Resource AS Resource,
	|	CustomerTurnovers.RoomRate AS RoomRate,
	|	CustomerTurnovers.ParentDoc AS ParentDoc,
	|	CustomerTurnovers.PaymentMethod AS PaymentMethod,
	|	SUM(CustomerTurnovers.Sales) AS Sales,
	|	SUM(CustomerTurnovers.SalesWithoutVAT) AS SalesWithoutVAT,
	|	SUM(CustomerTurnovers.RoomRevenue) AS RoomRevenue,
	|	SUM(CustomerTurnovers.RoomRevenueWithoutVAT) AS RoomRevenueWithoutVAT,
	|	SUM(CustomerTurnovers.CommissionSum) AS CommissionSum,
	|	SUM(CustomerTurnovers.CommissionSumWithoutVAT) AS CommissionSumWithoutVAT,
	|	SUM(CustomerTurnovers.DiscountSum) AS DiscountSum,
	|	SUM(CustomerTurnovers.DiscountSumWithoutVAT) AS DiscountSumWithoutVAT,
	|	SUM(CustomerTurnovers.RoomsRented) AS RoomsRented,
	|	SUM(CustomerTurnovers.BedsRented) AS BedsRented,
	|	SUM(CustomerTurnovers.AdditionalBedsRented) AS AdditionalBedsRented,
	|	SUM(CustomerTurnovers.GuestDays) AS GuestDays,
	|	SUM(CustomerTurnovers.GuestsCheckedIn) AS GuestsCheckedIn,
	|	SUM(CustomerTurnovers.RoomsCheckedIn) AS RoomsCheckedIn,
	|	SUM(CustomerTurnovers.BedsCheckedIn) AS BedsCheckedIn,
	|	SUM(CustomerTurnovers.AdditionalBedsCheckedIn) AS AdditionalBedsCheckedIn,
	|	SUM(CustomerTurnovers.Quantity) AS Quantity
	|{SELECT
	|	Company.*,
	|	Hotel.*,
	|	FolioCurrency.*,
	|	Agent.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	Client.*,
	|	CheckInDate,
	|	CheckOutDate,
	|	AccommodationType.*,
	|	Status.*,
	|	Room.*,
	|	RoomType.*,
	|	Resource.*,
	|	RoomRate.*,
	|	ParentDoc.*,
	|	ForeignerRegistryRecords.ForeignerRegistryRecord.* AS ForeignerRegistryRecord,
	|	PaymentMethod.*,
	|	Sales,
	|	SalesWithoutVAT,
	|	RoomRevenue,
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
	|	AdditionalBedsCheckedIn,
	|	Quantity}
	|FROM
	|	(SELECT
	|		CustomerSales.Company AS Company,
	|		CustomerSales.Hotel AS Hotel,
	|		CustomerSales.FolioCurrency AS FolioCurrency,
	|		CustomerSales.Agent AS Agent,
	|		CustomerSales.ParentDoc.Customer AS Customer,
	|		CustomerSales.ParentDoc.Contract AS Contract,
	|		CustomerSales.ParentDoc AS ParentDoc,
	|		CustomerSales.GuestGroup AS GuestGroup,
	|		CustomerSales.Client AS Client,
	|		CASE
	|			WHEN CustomerSales.ParentDoc.CheckInDate IS NULL 
	|				THEN CustomerSales.ParentDoc.DateTimeFrom
	|			ELSE CustomerSales.ParentDoc.CheckInDate
	|		END AS CheckInDate,
	|		CASE
	|			WHEN CustomerSales.ParentDoc.CheckOutDate IS NULL 
	|				THEN CustomerSales.ParentDoc.DateTimeTo
	|			ELSE CustomerSales.ParentDoc.CheckOutDate
	|		END AS CheckOutDate,
	|		CASE
	|			WHEN (NOT CustomerSales.ParentDoc.AccommodationStatus IS NULL )
	|				THEN CustomerSales.ParentDoc.AccommodationStatus
	|			WHEN (NOT CustomerSales.ParentDoc.ReservationStatus IS NULL )
	|				THEN CustomerSales.ParentDoc.ReservationStatus
	|			ELSE CustomerSales.ParentDoc.ResourceReservationStatus
	|		END AS Status,
	|		CustomerSales.ParentDoc.AccommodationType AS AccommodationType,
	|		CustomerSales.ParentDoc.Room AS Room,
	|		CustomerSales.ParentDoc.RoomType AS RoomType,
	|		CustomerSales.RoomRate AS RoomRate,
	|		CustomerSales.ParentDoc.Resource AS Resource,
	|		CustomerSales.PaymentMethod AS PaymentMethod,
	|		CustomerSales.Service AS Service,
	|		CustomerSales.ExpectedSalesTurnover AS Sales,
	|		CustomerSales.ExpectedSalesWithoutVATTurnover AS SalesWithoutVAT,
	|		CustomerSales.ExpectedRoomRevenueTurnover AS RoomRevenue,
	|		CustomerSales.ExpectedRoomRevenueWithoutVATTurnover AS RoomRevenueWithoutVAT,
	|		CustomerSales.ExpectedCommissionSumTurnover AS CommissionSum,
	|		CustomerSales.ExpectedCommissionSumWithoutVATTurnover AS CommissionSumWithoutVAT,
	|		CustomerSales.ExpectedDiscountSumTurnover AS DiscountSum,
	|		CustomerSales.ExpectedDiscountSumWithoutVATTurnover AS DiscountSumWithoutVAT,
	|		CustomerSales.ExpectedRoomsRentedTurnover AS RoomsRented,
	|		CustomerSales.ExpectedBedsRentedTurnover AS BedsRented,
	|		CustomerSales.ExpectedAdditionalBedsRentedTurnover AS AdditionalBedsRented,
	|		CustomerSales.ExpectedGuestDaysTurnover AS GuestDays,
	|		CustomerSales.ExpectedGuestsCheckedInTurnover AS GuestsCheckedIn,
	|		CustomerSales.ExpectedRoomsCheckedInTurnover AS RoomsCheckedIn,
	|		CustomerSales.ExpectedBedsCheckedInTurnover AS BedsCheckedIn,
	|		CustomerSales.ExpectedAdditionalBedsCheckedInTurnover AS AdditionalBedsCheckedIn,
	|		CustomerSales.ExpectedQuantityTurnover AS Quantity
	|	FROM
	|		AccumulationRegister.AccountsReceivableForecast.Turnovers(
	|				&qServicesPeriodFrom,
	|				&qServicesPeriodTo,
	|				Period,
	|				Hotel IN HIERARCHY (&qHotel)
	|					AND (ParentDoc.Customer IN HIERARCHY (&qCustomer)
	|						OR &qCustomerIsEmpty)
	|					AND (ParentDoc.Contract IN HIERARCHY (&qContract)
	|						OR &qContractIsEmpty)
	|					AND (GuestGroup = &qGuestGroup
	|						OR &qGuestGroupIsEmpty)
	|					AND (Agent IN HIERARCHY (&qAgent)
	|						OR &qAgentIsEmpty)
	|					AND (Service IN (&qServicesList)
	|						OR (NOT &qUseServicesList))
	|					AND (ParentDoc.CheckInDate >= &qPeriodFrom
	|						AND ParentDoc.CheckInDate <= &qPeriodTo)) AS CustomerSales) AS CustomerTurnovers
	|		LEFT JOIN InformationRegister.AccommodationForeignerRegistryRecords.SliceLast(&qEndOfTime, ) AS ForeignerRegistryRecords
	|		ON CustomerTurnovers.ParentDoc = ForeignerRegistryRecords.Accommodation
	|WHERE
	|	(NOT ISNULL(CustomerTurnovers.Status.IsActive, TRUE))
	|	AND (NOT ISNULL(CustomerTurnovers.Status.IsCheckIn, TRUE))
	|	AND (NOT ISNULL(CustomerTurnovers.Status.IsAnnulation, TRUE))
	|	AND (NOT ISNULL(CustomerTurnovers.Status.DoNoShowCharging, TRUE))
	|	AND (NOT ISNULL(CustomerTurnovers.Status.DoLateAnnulationCharging, TRUE))
	|{WHERE
	|	CustomerTurnovers.Company.*,
	|	CustomerTurnovers.Hotel.*,
	|	CustomerTurnovers.FolioCurrency.*,
	|	CustomerTurnovers.Customer.*,
	|	CustomerTurnovers.Contract.*,
	|	CustomerTurnovers.GuestGroup.*,
	|	CustomerTurnovers.Agent.*,
	|	CustomerTurnovers.Client.*,
	|	CustomerTurnovers.CheckInDate,
	|	CustomerTurnovers.CheckOutDate,
	|	CustomerTurnovers.AccommodationType.*,
	|	CustomerTurnovers.Status.*,
	|	CustomerTurnovers.Room.*,
	|	CustomerTurnovers.RoomType.*,
	|	CustomerTurnovers.Resource.*,
	|	CustomerTurnovers.RoomRate.*,
	|	CustomerTurnovers.ParentDoc.*,
	|	ForeignerRegistryRecords.ForeignerRegistryRecord.* AS ForeignerRegistryRecord,
	|	CustomerTurnovers.PaymentMethod.*,
	|	CustomerTurnovers.Sales,
	|	CustomerTurnovers.SalesWithoutVAT,
	|	CustomerTurnovers.RoomRevenue,
	|	CustomerTurnovers.RoomRevenueWithoutVAT,
	|	CustomerTurnovers.CommissionSum,
	|	CustomerTurnovers.CommissionSumWithoutVAT,
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
	|	CustomerTurnovers.Quantity}
	|
	|GROUP BY
	|	CustomerTurnovers.Company,
	|	CustomerTurnovers.Hotel,
	|	CustomerTurnovers.FolioCurrency,
	|	CustomerTurnovers.Agent,
	|	CustomerTurnovers.Customer,
	|	CustomerTurnovers.Contract,
	|	CustomerTurnovers.GuestGroup,
	|	CustomerTurnovers.Client,
	|	CustomerTurnovers.CheckInDate,
	|	CustomerTurnovers.CheckOutDate,
	|	CustomerTurnovers.AccommodationType,
	|	CustomerTurnovers.Status,
	|	CustomerTurnovers.Room,
	|	CustomerTurnovers.RoomType,
	|	CustomerTurnovers.Resource,
	|	CustomerTurnovers.RoomRate,
	|	CustomerTurnovers.ParentDoc,
	|	CustomerTurnovers.PaymentMethod
	|
	|ORDER BY
	|	Company,
	|	Hotel,
	|	FolioCurrency,
	|	Agent,
	|	Customer,
	|	Contract,
	|	GuestGroup,
	|	CheckInDate,
	|	Client
	|{ORDER BY
	|	Company.*,
	|	Hotel.*,
	|	FolioCurrency.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	Client.*,
	|	Agent.*,
	|	CheckInDate,
	|	CheckOutDate,
	|	AccommodationType.*,
	|	Status.*,
	|	Room.*,
	|	RoomType.*,
	|	Resource.*,
	|	RoomRate.*,
	|	ParentDoc.*,
	|	ForeignerRegistryRecords.ForeignerRegistryRecord.* AS ForeignerRegistryRecord,
	|	PaymentMethod.*,
	|	Sales,
	|	SalesWithoutVAT,
	|	RoomRevenue,
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
	|	AdditionalBedsCheckedIn,
	|	Quantity}
	|TOTALS
	|	SUM(Sales),
	|	SUM(SalesWithoutVAT),
	|	SUM(RoomRevenue),
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
	|	SUM(AdditionalBedsCheckedIn),
	|	SUM(Quantity)
	|BY
	|	OVERALL,
	|	Hotel,
	|	FolioCurrency,
	|	Agent,
	|	Customer,
	|	Contract,
	|	GuestGroup
	|{TOTALS BY
	|	Company.*,
	|	Hotel.*,
	|	FolioCurrency.*,
	|	Agent.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	Client.*,
	|	Room.*,
	|	AccommodationType.*,
	|	Status.*,
	|	RoomType.*,
	|	RoomRate.*,
	|	Resource.*,
	|	PaymentMethod.*,
	|	ForeignerRegistryRecords.ForeignerRegistryRecord.* AS ForeignerRegistryRecord,
	|	ParentDoc.*}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Lost profits';RU='Упущенная выгода';de='Entgangener Gewinn'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
