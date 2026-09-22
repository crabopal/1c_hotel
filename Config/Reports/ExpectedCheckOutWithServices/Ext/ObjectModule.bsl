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
			vParamPresentation = vParamPresentation + NStr("en='Agents folder ';ru='Группа агентов ';de='Vertretergruppe '") + 
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
	|	CASE
	|		WHEN CustomerTurnovers.ParentDoc.Guest IS NULL 
	|			THEN CustomerTurnovers.ParentDoc.Client
	|		ELSE CustomerTurnovers.ParentDoc.Guest
	|	END AS Client,
	|	CASE
	|		WHEN CustomerTurnovers.ParentDoc.CheckInDate IS NULL 
	|			THEN CustomerTurnovers.ParentDoc.DateTimeFrom
	|		ELSE CustomerTurnovers.ParentDoc.CheckInDate
	|	END AS CheckInDate,
	|	CASE
	|		WHEN CustomerTurnovers.ParentDoc.CheckOutDate IS NULL 
	|			THEN CustomerTurnovers.ParentDoc.DateTimeTo
	|		ELSE CustomerTurnovers.ParentDoc.CheckOutDate
	|	END AS CheckOutDate,
	|	CustomerTurnovers.ParentDoc.AccommodationType AS AccommodationType,
	|	CASE
	|		WHEN (NOT CustomerTurnovers.ParentDoc.AccommodationStatus IS NULL )
	|			THEN CustomerTurnovers.ParentDoc.AccommodationStatus
	|		WHEN (NOT CustomerTurnovers.ParentDoc.ReservationStatus IS NULL )
	|			THEN CustomerTurnovers.ParentDoc.ReservationStatus
	|		ELSE CustomerTurnovers.ParentDoc.ResourceReservationStatus
	|	END AS Status,
	|	CustomerTurnovers.ParentDoc.Room AS Room,
	|	CustomerTurnovers.ParentDoc.RoomType AS RoomType,
	|	CustomerTurnovers.ParentDoc.Resource AS Resource,
	|	CustomerTurnovers.Service AS Service,
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
	|	SUM(CustomerTurnovers.GuestsCheckedIn) AS GuestsCheckedIn
	|{SELECT
	|	Company.*,
	|	Hotel.*,
	|	ReportingCurrency.*,
	|	Agent.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	Client.*,
	|	CheckInDate,
	|	CheckOutDate,
	|	AccommodationType,
	|	Status.*,
	|	Room.*,
	|	RoomType.*,
	|	Resource.*,
	|	CustomerTurnovers.ParentDoc.RoomRate.* AS RoomRate,
	|	ParentDoc.*,
	|	Service.*,
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
	|	GuestsCheckedIn}
	|FROM
	|	(SELECT
	|		CustomerSales.Company AS Company,
	|		CustomerSales.Hotel AS Hotel,
	|		CustomerSales.ReportingCurrency AS ReportingCurrency,
	|		CustomerSales.Agent AS Agent,
	|		CustomerSales.Customer AS Customer,
	|		CustomerSales.Contract AS Contract,
	|		CustomerSales.GuestGroup AS GuestGroup,
	|		CustomerSales.ParentDoc AS ParentDoc,
	|		CustomerSales.Service AS Service,
	|		CustomerSales.SalesTurnover AS Sales,
	|		CustomerSales.SalesWithoutVATTurnover AS SalesWithoutVAT,
	|		CustomerSales.RoomRevenueTurnover AS RoomRevenue,
	|		CustomerSales.RoomRevenueWithoutVATTurnover AS RoomRevenueWithoutVAT,
	|		CustomerSales.CommissionSumTurnover AS CommissionSum,
	|		CustomerSales.CommissionSumWithoutVATTurnover AS CommissionSumWithoutVAT,
	|		CustomerSales.DiscountSumTurnover AS DiscountSum,
	|		CustomerSales.DiscountSumWithoutVATTurnover AS DiscountSumWithoutVAT,
	|		CustomerSales.RoomsRentedTurnover AS RoomsRented,
	|		CustomerSales.BedsRentedTurnover AS BedsRented,
	|		CustomerSales.AdditionalBedsRentedTurnover AS AdditionalBedsRented,
	|		CustomerSales.GuestDaysTurnover AS GuestDays,
	|		CustomerSales.GuestsCheckedInTurnover AS GuestsCheckedIn
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				,
	|				,
	|				Period,
	|				Hotel IN HIERARCHY (&qHotel)
	|					AND (Customer IN HIERARCHY (&qCustomer)
	|						OR &qCustomerIsEmpty)
	|					AND (Contract IN HIERARCHY (&qContract)
	|						OR &qContractIsEmpty)
	|					AND (GuestGroup = &qGuestGroup
	|						OR &qGuestGroupIsEmpty)
	|					AND (Agent IN HIERARCHY (&qAgent)
	|						OR &qAgentIsEmpty)
	|					AND (Service IN (&qServicesList)
	|						OR (NOT &qUseServicesList))
	|					AND (ParentDoc.CheckOutDate IS NOT NULL 
	|							AND &qPeriodFrom <= ParentDoc.CheckOutDate
	|							AND &qPeriodTo >= ParentDoc.CheckOutDate
	|							AND (ParentDoc.ReservationStatus IS NOT NULL 
	|								OR ParentDoc.AccommodationStatus IS NOT NULL 
	|									AND ParentDoc.AccommodationStatus.IsCheckOut)
	|						OR ParentDoc.DateTimeTo IS NOT NULL 
	|							AND &qPeriodFrom <= ParentDoc.DateTimeTo
	|							AND &qPeriodTo >= ParentDoc.DateTimeTo)) AS CustomerSales) AS CustomerTurnovers
	|{WHERE
	|	CustomerTurnovers.Company.*,
	|	CustomerTurnovers.Hotel.*,
	|	CustomerTurnovers.ReportingCurrency.*,
	|	CustomerTurnovers.Agent.*,
	|	CustomerTurnovers.Customer.*,
	|	CustomerTurnovers.Contract.*,
	|	CustomerTurnovers.GuestGroup.*,
	|	CustomerTurnovers.ParentDoc.*,
	|	(CASE
	|			WHEN CustomerTurnovers.ParentDoc.Guest IS NULL 
	|				THEN CustomerTurnovers.ParentDoc.Client
	|			ELSE CustomerTurnovers.ParentDoc.Guest
	|		END) AS Client,
	|	(CASE
	|			WHEN CustomerTurnovers.ParentDoc.CheckInDate IS NULL 
	|				THEN CustomerTurnovers.ParentDoc.DateTimeFrom
	|			ELSE CustomerTurnovers.ParentDoc.CheckInDate
	|		END) AS CheckInDate,
	|	(CASE
	|			WHEN CustomerTurnovers.ParentDoc.CheckOutDate IS NULL 
	|				THEN CustomerTurnovers.ParentDoc.DateTimeTo
	|			ELSE CustomerTurnovers.ParentDoc.CheckOutDate
	|		END) AS CheckOutDate,
	|	CustomerTurnovers.ParentDoc.AccommodationType AS AccommodationType,
	|	(CASE
	|			WHEN (NOT CustomerTurnovers.ParentDoc.AccommodationStatus IS NULL )
	|				THEN CustomerTurnovers.ParentDoc.AccommodationStatus
	|			WHEN (NOT CustomerTurnovers.ParentDoc.ReservationStatus IS NULL )
	|				THEN CustomerTurnovers.ParentDoc.ReservationStatus
	|			ELSE CustomerTurnovers.ParentDoc.ResourceReservationStatus
	|		END) AS Status,
	|	CustomerTurnovers.ParentDoc.Room AS Room,
	|	CustomerTurnovers.ParentDoc.RoomType AS RoomType,
	|	CustomerTurnovers.ParentDoc.Resource AS Resource,
	|	CustomerTurnovers.ParentDoc.RoomRate.* AS RoomRate,
	|	CustomerTurnovers.Service.*,
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
	|	CustomerTurnovers.GuestsCheckedIn}
	|
	|GROUP BY
	|	CustomerTurnovers.Company,
	|	CustomerTurnovers.Hotel,
	|	CustomerTurnovers.ReportingCurrency,
	|	CustomerTurnovers.Agent,
	|	CustomerTurnovers.Customer,
	|	CustomerTurnovers.Contract,
	|	CustomerTurnovers.GuestGroup,
	|	CustomerTurnovers.ParentDoc,
	|	CASE
	|		WHEN CustomerTurnovers.ParentDoc.Guest IS NULL 
	|			THEN CustomerTurnovers.ParentDoc.Client
	|		ELSE CustomerTurnovers.ParentDoc.Guest
	|	END,
	|	CASE
	|		WHEN CustomerTurnovers.ParentDoc.CheckInDate IS NULL 
	|			THEN CustomerTurnovers.ParentDoc.DateTimeFrom
	|		ELSE CustomerTurnovers.ParentDoc.CheckInDate
	|	END,
	|	CASE
	|		WHEN CustomerTurnovers.ParentDoc.CheckOutDate IS NULL 
	|			THEN CustomerTurnovers.ParentDoc.DateTimeTo
	|		ELSE CustomerTurnovers.ParentDoc.CheckOutDate
	|	END,
	|	CustomerTurnovers.ParentDoc.AccommodationType,
	|	CASE
	|		WHEN (NOT CustomerTurnovers.ParentDoc.AccommodationStatus IS NULL )
	|			THEN CustomerTurnovers.ParentDoc.AccommodationStatus
	|		WHEN (NOT CustomerTurnovers.ParentDoc.ReservationStatus IS NULL )
	|			THEN CustomerTurnovers.ParentDoc.ReservationStatus
	|		ELSE CustomerTurnovers.ParentDoc.ResourceReservationStatus
	|	END,
	|	CustomerTurnovers.ParentDoc.Room,
	|	CustomerTurnovers.ParentDoc.RoomType,
	|	CustomerTurnovers.ParentDoc.Resource,
	|	CustomerTurnovers.Service
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
	|	Service
	|{ORDER BY
	|	Company.*,
	|	Hotel.*,
	|	ReportingCurrency.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	Agent.*,
	|	Client,
	|	CheckInDate,
	|	CheckOutDate,
	|	AccommodationType.*,
	|	Status,
	|	Room.*,
	|	RoomType.*,
	|	Resource.*,
	|	ParentDoc.*,
	|	Service.*,
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
	|	GuestsCheckedIn}
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
	|	SUM(GuestsCheckedIn)
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
	|	Client,
	|	Room.*,
	|	AccommodationType.*,
	|	Status,
	|	RoomType.*,
	|	Resource.*,
	|	Service.*,
	|	ParentDoc.*}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Expected check-out with services';RU='Планируемый выезд с услугами';de='Geplante Abreise mit Diensten'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
