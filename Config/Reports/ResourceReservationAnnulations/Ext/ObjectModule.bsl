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
	// Customer
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
	// Resource type
	If ValueIsFilled(ResourceType) Then
		If Not ResourceType.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Resource type ';ru='Тип ресурса ';de='Ressourcetyp '") + 
			                     TrimAll(ResourceType.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Resource types folder ';ru='Группа типов ресурсов ';de='Ressourcetypengruppe '") + 
			                     TrimAll(ResourceType.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	// Resource
	If ValueIsFilled(Resource) Then
		vParamPresentation = vParamPresentation + NStr("en='Resource ';ru='Ресурс ';de='Ressource '") + 
		                     TrimAll(Resource.Description) + 
		                     ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(Employee) Then
		If Not Employee.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Employee ';ru='Сотрудник ';de='Mitarbeiter '") + 
			                     TrimAll(Employee) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа сотрудников '; en = 'Employees folder '; de = 'Mitarbeiterengruppe '") + 
			                     TrimAll(Employee) + 
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
	ReportBuilder.Parameters.Insert("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qCustomer", Customer);
	ReportBuilder.Parameters.Insert("qCustomerIsEmpty", Not ValueIsFilled(Customer));
	ReportBuilder.Parameters.Insert("qResourceType", ResourceType);
	ReportBuilder.Parameters.Insert("qResourceTypeIsEmpty", Not ValueIsFilled(ResourceType));
	ReportBuilder.Parameters.Insert("qResource", Resource);
	ReportBuilder.Parameters.Insert("qResourceIsEmpty", Not ValueIsFilled(Resource));
	ReportBuilder.Parameters.Insert("qEmployee", Employee);
	ReportBuilder.Parameters.Insert("qEmployeeIsEmpty", Not ValueIsFilled(Employee));
	ReportBuilder.Parameters.Insert("qEmptyDate", '00010101');

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
	|	Reservations.DateOfAnnulation AS DateOfAnnulation,
	|	BEGINOFPERIOD(Reservations.DateOfAnnulation, DAY) AS AccountingDateOfAnnulation,
	|	Reservations.AuthorOfAnnulation AS AuthorOfAnnulation,
	|	Reservations.AnnulationReason AS AnnulationReason,
	|	Reservations.Ref AS ResourceReservation,
	|	Reservations.Hotel AS Hotel,
	|	Reservations.Resource AS Resource,
	|	Reservations.Customer AS Customer,
	|	Reservations.GuestGroup AS GuestGroup,
	|	Reservations.ResourceReservationStatus AS ResourceReservationStatus,
	|	Reservations.Client AS Client,
	|	Reservations.DateTimeFrom AS DateTimeFrom,
	|	Reservations.Duration AS Duration,
	|	Reservations.DateTimeTo AS DateTimeTo,
	|	Reservations.ResourceType AS ResourceType,
	|	Reservations.PricePresentation AS PricePresentation,
	|	Reservations.Remarks AS Remarks,
	|	Reservations.NumberOfPersons AS NumberOfPersons,
	|	ReservationAmounts.Currency AS Currency,
	|	ReservationAmounts.ExpectedSales AS ExpectedSales,
	|	ReservationAmounts.ExpectedSalesWithoutVAT AS ExpectedSalesWithoutVAT,
	|	1 AS Counter
	|{SELECT
	|	DateOfAnnulation,
	|	AccountingDateOfAnnulation,
	|	AuthorOfAnnulation.*,
	|	AnnulationReason.*,
	|	ResourceReservation.*,
	|	Hotel.* AS Hotel,
	|	Resource.* AS Resource,
	|	Reservations.CustomerType.* AS CustomerType,
	|	Customer.* AS Customer,
	|	Reservations.Contract.* AS Contract,
	|	Reservations.ContactPerson AS ContactPerson,
	|	Reservations.Agent.* AS Agent,
	|	Reservations.ResourceTariff.* AS ResourceTariff,
	|	Reservations.EventActivity.* AS EventActivity,
	|	Reservations.ClientType.* AS ClientType,
	|	Client.* AS Client,
	|	DateTimeFrom AS DateTimeFrom,
	|	Duration AS Duration,
	|	DateTimeTo AS DateTimeTo,
	|	(BEGINOFPERIOD(Reservations.DateTimeFrom, DAY)) AS AccountingDateFrom,
	|	(BEGINOFPERIOD(Reservations.DateTimeTo, DAY)) AS AccountingDateTo,
	|	ResourceType.* AS ResourceType,
	|	PricePresentation AS PricePresentation,
	|	Reservations.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	Remarks AS Remarks,
	|	Reservations.Car AS Car,
	|	GuestGroup.* AS GuestGroup,
	|	ResourceReservationStatus.* AS ResourceReservationStatus,
	|	Reservations.MarketingCode.* AS MarketingCode,
	|	Reservations.SourceOfBusiness.* AS SourceOfBusiness,
	|	Reservations.Author.* AS Author,
	|	Reservations.DiscountCard.* AS DiscountCard,
	|	Reservations.DiscountType.* AS DiscountType,
	|	Reservations.Discount AS Discount,
	|	Reservations.AgentCommission AS AgentCommission,
	|	Reservations.AgentCommissionType.* AS AgentCommissionType,
	|	Reservations.ParentDoc.* AS ParentDoc,
	|	NumberOfPersons AS NumberOfPersons,
	|	Currency.* AS Currency,
	|	ExpectedSales,
	|	ExpectedSalesWithoutVAT,
	|	Counter AS Counter}
	|FROM
	|	Document.ResourceReservation AS Reservations
	|		LEFT JOIN (SELECT
	|			ReservationAmountTurnovers.ParentDoc AS Reservation,
	|			ReservationAmountTurnovers.FolioCurrency AS Currency,
	|			ReservationAmountTurnovers.ExpectedSalesTurnover AS ExpectedSales,
	|			ReservationAmountTurnovers.ExpectedSalesWithoutVATTurnover AS ExpectedSalesWithoutVAT
	|		FROM
	|			AccumulationRegister.AccountsReceivableForecast.Turnovers(, , Period, ) AS ReservationAmountTurnovers) AS ReservationAmounts
	|		ON Reservations.Ref = ReservationAmounts.Reservation
	|WHERE
	|	Reservations.Posted
	|	AND Reservations.DateOfAnnulation <> &qEmptyDate
	|	AND Reservations.DateOfAnnulation >= &qPeriodFrom
	|	AND Reservations.DateOfAnnulation <= &qPeriodTo
	|	AND (Reservations.Hotel IN HIERARCHY (&qHotel)
	|			OR &qHotelIsEmpty)
	|	AND (Reservations.Customer IN HIERARCHY (&qCustomer)
	|			OR &qCustomerIsEmpty)
	|	AND (Reservations.ResourceType IN HIERARCHY (&qResourceType)
	|			OR &qResourceTypeIsEmpty)
	|	AND (Reservations.Resource IN HIERARCHY (&qResource)
	|			OR &qResourceIsEmpty)
	|	AND (Reservations.AuthorOfAnnulation IN HIERARCHY (&qEmployee)
	|			OR &qEmployeeIsEmpty)
	|{WHERE
	|	Reservations.DateOfAnnulation,
	|	Reservations.AuthorOfAnnulation.*,
	|	Reservations.AnnulationReason.*,
	|	Reservations.Ref.* AS ResourceReservation,
	|	Reservations.Hotel.* AS Hotel,
	|	Reservations.Resource.* AS Resource,
	|	Reservations.CustomerType.* AS CustomerType,
	|	Reservations.Customer.* AS Customer,
	|	Reservations.Contract.* AS Contract,
	|	Reservations.ContactPerson AS ContactPerson,
	|	Reservations.Agent.* AS Agent,
	|	Reservations.ResourceTariff.* AS ResourceTariff,
	|	Reservations.EventActivity.* AS EventActivity,
	|	Reservations.ClientType.* AS ClientType,
	|	Reservations.Client.* AS Client,
	|	Reservations.DateTimeFrom AS DateTimeFrom,
	|	Reservations.Duration AS Duration,
	|	Reservations.DateTimeTo AS DateTimeTo,
	|	Reservations.ResourceType.* AS ResourceType,
	|	Reservations.PricePresentation AS PricePresentation,
	|	Reservations.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	Reservations.Remarks AS Remarks,
	|	Reservations.Car AS Car,
	|	Reservations.GuestGroup.* AS GuestGroup,
	|	Reservations.ResourceReservationStatus.* AS ResourceReservationStatus,
	|	Reservations.MarketingCode.* AS MarketingCode,
	|	Reservations.SourceOfBusiness.* AS SourceOfBusiness,
	|	Reservations.Author.* AS Author,
	|	Reservations.DiscountCard.* AS DiscountCard,
	|	Reservations.DiscountType.* AS DiscountType,
	|	Reservations.Discount AS Discount,
	|	Reservations.AgentCommission AS AgentCommission,
	|	Reservations.AgentCommissionType.* AS AgentCommissionType,
	|	Reservations.ParentDoc.* AS ParentDoc,
	|	Reservations.NumberOfPersons AS NumberOfPersons,
	|	ReservationAmounts.Currency.* AS Currency,
	|	ReservationAmounts.ExpectedSales AS ExpectedSales,
	|	ReservationAmounts.ExpectedSalesWithoutVAT AS ExpectedSalesWithoutVAT,
	|	(1) AS Counter}
	|
	|ORDER BY
	|	Hotel,
	|	Customer,
	|	GuestGroup,
	|	DateTimeFrom,
	|	Client
	|{ORDER BY
	|	DateOfAnnulation,
	|	AccountingDateOfAnnulation,
	|	AuthorOfAnnulation.*,
	|	AnnulationReason.*,
	|	ResourceReservation.*,
	|	Hotel.* AS Hotel,
	|	Resource.* AS Resource,
	|	Reservations.CustomerType.* AS CustomerType,
	|	Customer.* AS Customer,
	|	Reservations.Contract.* AS Contract,
	|	Reservations.ContactPerson AS ContactPerson,
	|	Reservations.Agent.* AS Agent,
	|	Reservations.ResourceTariff.* AS ResourceTariff,
	|	Reservations.EventActivity.* AS EventActivity,
	|	Reservations.ClientType.* AS ClientType,
	|	Client.* AS Client,
	|	DateTimeFrom AS DateTimeFrom,
	|	Duration AS Duration,
	|	DateTimeTo AS DateTimeTo,
	|	(BEGINOFPERIOD(Reservations.DateTimeFrom, DAY)) AS AccountingDateFrom,
	|	(BEGINOFPERIOD(Reservations.DateTimeTo, DAY)) AS AccountingDateTo,
	|	ResourceType.* AS ResourceType,
	|	PricePresentation AS PricePresentation,
	|	Reservations.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	Remarks AS Remarks,
	|	Reservations.Car AS Car,
	|	GuestGroup.* AS GuestGroup,
	|	ResourceReservationStatus.* AS ResourceReservationStatus,
	|	Reservations.MarketingCode.* AS MarketingCode,
	|	Reservations.SourceOfBusiness.* AS SourceOfBusiness,
	|	Reservations.Author.* AS Author,
	|	Reservations.DiscountCard.* AS DiscountCard,
	|	Reservations.DiscountType.* AS DiscountType,
	|	Reservations.Discount AS Discount,
	|	Reservations.AgentCommission AS AgentCommission,
	|	Reservations.AgentCommissionType.* AS AgentCommissionType,
	|	Reservations.ParentDoc.* AS ParentDoc,
	|	NumberOfPersons AS NumberOfPersons,
	|	Currency.* AS Currency,
	|	ExpectedSales,
	|	ExpectedSalesWithoutVAT,
	|	Counter AS Counter}
	|TOTALS
	|	SUM(NumberOfPersons),
	|	SUM(ExpectedSales),
	|	SUM(ExpectedSalesWithoutVAT),
	|	SUM(Counter)
	|BY
	|	OVERALL,
	|	Hotel,
	|	Customer,
	|	GuestGroup
	|{TOTALS BY
	|	AccountingDateOfAnnulation,
	|	AuthorOfAnnulation.*,
	|	AnnulationReason.*,
	|	ResourceReservation.*,
	|	Hotel.* AS Hotel,
	|	Resource.* AS Resource,
	|	Reservations.CustomerType.* AS CustomerType,
	|	Customer.* AS Customer,
	|	Reservations.Contract.* AS Contract,
	|	Reservations.ContactPerson AS ContactPerson,
	|	Reservations.Agent.* AS Agent,
	|	Reservations.ResourceTariff.* AS ResourceTariff,
	|	Reservations.EventActivity.* AS EventActivity,
	|	Reservations.ClientType.* AS ClientType,
	|	Client.* AS Client,
	|	Duration AS Duration,
	|	(BEGINOFPERIOD(Reservations.DateTimeFrom, DAY)) AS AccountingDateFrom,
	|	(BEGINOFPERIOD(Reservations.DateTimeTo, DAY)) AS AccountingDateTo,
	|	ResourceType.* AS ResourceType,
	|	PricePresentation AS PricePresentation,
	|	Reservations.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	GuestGroup.* AS GuestGroup,
	|	ResourceReservationStatus.* AS ResourceReservationStatus,
	|	Reservations.MarketingCode.* AS MarketingCode,
	|	Reservations.SourceOfBusiness.* AS SourceOfBusiness,
	|	Reservations.Author.* AS Author,
	|	Reservations.DiscountCard.* AS DiscountCard,
	|	Reservations.DiscountType.* AS DiscountType,
	|	Reservations.Discount AS Discount,
	|	Reservations.AgentCommission AS AgentCommission,
	|	Reservations.AgentCommissionType.* AS AgentCommissionType,
	|	Currency.* AS Currency,
	|	Reservations.ParentDoc.* AS ParentDoc}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Resource reservation annulations audit';RU='Аудит аннуляций брони ресурсов';de='Buchprüfung der Annullierung der Ressource Buchung'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
