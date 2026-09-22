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
			vParamPresentation = vParamPresentation + NStr("de='Firmengruppe ';en='Customers folder ';ru='Группа контрагентов '") + 
			                     TrimAll(Customer.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(RoomType) Then
		If Not RoomType.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Room type ';ru='Тип номера ';de='Zimmertyp '") + 
			                     TrimAll(RoomType.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Room types folder ';ru='Группа типов номеров ';de='Zimmertypengruppe '") + 
			                     TrimAll(RoomType.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(Employee) Then
		If Not Employee.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Employee '; ru='Сотрудник '; de='Mitarbeiter '") + 
			                     TrimAll(Employee) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа сотрудников '; en = 'Employees folder '; de = 'Mitarbeitergruppe '") + 
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
			vParamPresentation = vParamPresentation + NStr("en='Hotels folder ';ru='Группа гостиниц ';de='Hotelgruppe '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     TrimAll(Hotel.Description) + ";" + Chars.LF;
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
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qRoomTypeIsEmpty", Not ValueIsFilled(RoomType));
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
	|	ReservationsToShow.Ref AS Reservation,
	|	ReservationsToShow.DateOfAnnulation AS DateOfAnnulation,
	|	ReservationsToShow.AuthorOfAnnulation AS AuthorOfAnnulation,
	|	ReservationsToShow.AnnulationReason AS AnnulationReason,
	|	ReservationsToShow.Hotel AS Hotel,
	|	ReservationsToShow.Room AS Room,
	|	ReservationsToShow.CustomerType AS CustomerType,
	|	ReservationsToShow.Customer AS Customer,
	|	ReservationsToShow.Contract AS Contract,
	|	ReservationsToShow.ContactPerson AS ContactPerson,
	|	ReservationsToShow.Agent AS Agent,
	|	ReservationsToShow.ClientType AS ClientType,
	|	ReservationsToShow.Guest AS Guest,
	|	ReservationsToShow.CheckInDate AS CheckInDate,
	|	ReservationsToShow.Duration AS Duration,
	|	ReservationsToShow.CheckOutDate AS CheckOutDate,
	|	ReservationsToShow.RoomType AS RoomType,
	|	ReservationsToShow.AccommodationType AS AccommodationType,
	|	ReservationsToShow.RoomRateType AS RoomRateType,
	|	ReservationsToShow.RoomRate AS RoomRate,
	|	ReservationsToShow.PricePresentation AS PricePresentation,
	|	ReservationsToShow.PlannedPaymentMethod AS PlannedPaymentMethod,
	|	ReservationsToShow.Remarks AS Remarks,
	|	ReservationsToShow.Car AS Car,
	|	ReservationsToShow.GuestGroup AS GuestGroup,
	|	ReservationsToShow.ReservationStatus AS ReservationStatus,
	|	ReservationsToShow.IsMaster AS IsMaster,
	|	ReservationsToShow.HotelProduct AS HotelProduct,
	|	ReservationsToShow.RoomQuota AS RoomQuota,
	|	ReservationsToShow.MarketingCode AS MarketingCode,
	|	ReservationsToShow.TripPurpose AS TripPurpose,
	|	ReservationsToShow.SourceOfBusiness AS SourceOfBusiness,
	|	ReservationsToShow.Author AS Author,
	|	ReservationsToShow.DiscountCard AS DiscountCard,
	|	ReservationsToShow.DiscountType AS DiscountType,
	|	ReservationsToShow.Discount AS Discount,
	|	ReservationsToShow.AgentCommission AS AgentCommission,
	|	ReservationsToShow.AgentCommissionType AS AgentCommissionType,
	|	ReservationsToShow.NumberOfBedsPerRoom AS NumberOfBedsPerRoom,
	|	ReservationsToShow.NumberOfPersonsPerRoom AS NumberOfPersonsPerRoom,
	|	ReservationsToShow.ParentDoc AS ParentDoc,
	|	ReservationsToShow.NumberOfPersons AS NumberOfPersons,
	|	ReservationsToShow.RoomQuantity AS RoomQuantity,
	|	CASE
	|		WHEN ReservationsToShow.NumberOfRooms = 0 AND ReservationsToShow.NumberOfBeds <> 0 AND ReservationsToShow.NumberOfBedsPerRoom <> 0 
	|			THEN ReservationsToShow.NumberOfBeds / ReservationsToShow.NumberOfBedsPerRoom
	|		ELSE ReservationsToShow.NumberOfRooms 
	|	END AS NumberOfRooms,
	|	ReservationsToShow.NumberOfBeds AS NumberOfBeds,
	|	ReservationsToShow.NumberOfAdditionalBeds AS NumberOfAdditionalBeds
	|INTO ReservationsToShow
	|FROM
	|	Document.Reservation AS ReservationsToShow
	|WHERE
	|	ReservationsToShow.Posted
	|	AND ReservationsToShow.DateOfAnnulation <> &qEmptyDate
	|	AND ReservationsToShow.DateOfAnnulation >= &qPeriodFrom
	|	AND ReservationsToShow.DateOfAnnulation <= &qPeriodTo
	|	AND (ReservationsToShow.Hotel IN HIERARCHY (&qHotel)
	|			OR &qHotelIsEmpty)
	|	AND (ReservationsToShow.Customer IN HIERARCHY (&qCustomer)
	|			OR &qCustomerIsEmpty)
	|	AND (ReservationsToShow.RoomType IN HIERARCHY (&qRoomType)
	|			OR &qRoomTypeIsEmpty)
	|	AND (ReservationsToShow.AuthorOfAnnulation IN HIERARCHY (&qEmployee)
	|			OR &qEmployeeIsEmpty)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Reservations.DateOfAnnulation AS DateOfAnnulation,
	|	BEGINOFPERIOD(Reservations.DateOfAnnulation, DAY) AS AccountingDateOfAnnulation,
	|	Reservations.AuthorOfAnnulation AS AuthorOfAnnulation,
	|	Reservations.AnnulationReason AS AnnulationReason,
	|	Reservations.Reservation AS Reservation,
	|	Reservations.Hotel AS Hotel,
	|	Reservations.Room AS Room,
	|	Reservations.Customer AS Customer,
	|	Reservations.GuestGroup AS GuestGroup,
	|	Reservations.ReservationStatus AS ReservationStatus,
	|	Reservations.Guest AS Guest,
	|	Reservations.CheckInDate AS CheckInDate,
	|	Reservations.Duration AS Duration,
	|	Reservations.CheckOutDate AS CheckOutDate,
	|	Reservations.RoomType AS RoomType,
	|	Reservations.AccommodationType AS AccommodationType,
	|	Reservations.RoomRate AS RoomRate,
	|	Reservations.PricePresentation AS PricePresentation,
	|	Reservations.Remarks AS Remarks,
	|	Reservations.NumberOfPersons AS NumberOfPersons,
	|	Reservations.RoomQuantity AS RoomQuantity,
	|	Reservations.NumberOfRooms AS NumberOfRooms,
	|	Reservations.NumberOfBeds AS NumberOfBeds,
	|	Reservations.NumberOfAdditionalBeds AS NumberOfAdditionalBeds,
	|	ReservationAmounts.Currency AS Currency,
	|	ReservationAmounts.ExpectedGuestDays AS ExpectedGuestDays,
	|	ReservationAmounts.ExpectedRoomsRented AS ExpectedRoomsRented,
	|	ReservationAmounts.ExpectedBedsRented AS ExpectedBedsRented,
	|	ReservationAmounts.ExpectedAdditionalBedsRented AS ExpectedAdditionalBedsRented,
	|	ReservationAmounts.ExpectedSales AS ExpectedSales,
	|	ReservationAmounts.ExpectedSalesWithoutVAT AS ExpectedSalesWithoutVAT,
	|	1 AS Counter
	|{SELECT
	|	DateOfAnnulation,
	|	AccountingDateOfAnnulation,
	|	AuthorOfAnnulation.*,
	|	AnnulationReason.*,
	|	Reservation.*,
	|	Hotel.* AS Hotel,
	|	Room.* AS Room,
	|	Reservations.CustomerType.* AS CustomerType,
	|	Customer.* AS Customer,
	|	Reservations.Contract.* AS Contract,
	|	Reservations.ContactPerson AS ContactPerson,
	|	Reservations.Agent.* AS Agent,
	|	Reservations.ClientType.* AS ClientType,
	|	Guest.* AS Guest,
	|	CheckInDate AS CheckInDate,
	|	Duration AS Duration,
	|	CheckOutDate AS CheckOutDate,
	|	(BEGINOFPERIOD(Reservations.CheckInDate, DAY)) AS CheckInAccountingDate,
	|	(BEGINOFPERIOD(Reservations.CheckOutDate, DAY)) AS CheckOutAccountingDate,
	|	RoomType.* AS RoomType,
	|	AccommodationType.* AS AccommodationType,
	|	Reservations.RoomRateType.* AS RoomRateType,
	|	RoomRate.* AS RoomRate,
	|	PricePresentation AS PricePresentation,
	|	Reservations.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	Remarks AS Remarks,
	|	Reservations.Car AS Car,
	|	GuestGroup.* AS GuestGroup,
	|	ReservationStatus.* AS ReservationStatus,
	|	Reservations.IsMaster AS IsMaster,
	|	Reservations.HotelProduct.* AS HotelProduct,
	|	Reservations.RoomQuota.* AS RoomQuota,
	|	Reservations.MarketingCode.* AS MarketingCode,
	|	Reservations.TripPurpose.* AS TripPurpose,
	|	Reservations.SourceOfBusiness.* AS SourceOfBusiness,
	|	Reservations.Author.* AS Author,
	|	Reservations.DiscountCard.* AS DiscountCard,
	|	Reservations.DiscountType.* AS DiscountType,
	|	Reservations.Discount AS Discount,
	|	Reservations.AgentCommission AS AgentCommission,
	|	Reservations.AgentCommissionType.* AS AgentCommissionType,
	|	Reservations.NumberOfBedsPerRoom AS NumberOfBedsPerRoom,
	|	Reservations.NumberOfPersonsPerRoom AS NumberOfPersonsPerRoom,
	|	Reservations.ParentDoc.* AS ParentDoc,
	|	NumberOfPersons AS NumberOfPersons,
	|	RoomQuantity AS RoomQuantity,
	|	NumberOfRooms AS NumberOfRooms,
	|	NumberOfBeds AS NumberOfBeds,
	|	NumberOfAdditionalBeds AS NumberOfAdditionalBeds,
	|	Currency.* AS Currency,
	|	ExpectedGuestDays,
	|	ExpectedRoomsRented,
	|	ExpectedBedsRented,
	|	ExpectedAdditionalBedsRented,
	|	ExpectedSales,
	|	ExpectedSalesWithoutVAT,
	|	Counter AS Counter}
	|FROM
	|	ReservationsToShow AS Reservations
	|		LEFT JOIN (SELECT
	|			ReservationAmountTurnovers.ParentDoc AS Reservation,
	|			ReservationAmountTurnovers.FolioCurrency AS Currency,
	|			ReservationAmountTurnovers.ExpectedGuestDaysTurnover AS ExpectedGuestDays,
	|			ReservationAmountTurnovers.ExpectedRoomsRentedTurnover AS ExpectedRoomsRented,
	|			ReservationAmountTurnovers.ExpectedBedsRentedTurnover AS ExpectedBedsRented,
	|			ReservationAmountTurnovers.ExpectedAdditionalBedsRentedTurnover AS ExpectedAdditionalBedsRented,
	|			ReservationAmountTurnovers.ExpectedSalesTurnover AS ExpectedSales,
	|			ReservationAmountTurnovers.ExpectedSalesWithoutVATTurnover AS ExpectedSalesWithoutVAT
	|		FROM
	|			AccumulationRegister.AccountsReceivableForecast.Turnovers(
	|					,
	|					,
	|					Period,
	|					ParentDoc IN
	|						(SELECT
	|							ReservationsToShow.Reservation
	|						FROM
	|							ReservationsToShow AS ReservationsToShow)) AS ReservationAmountTurnovers) AS ReservationAmounts
	|		ON Reservations.Reservation = ReservationAmounts.Reservation
	|{WHERE
	|	Reservations.DateOfAnnulation,
	|	Reservations.AuthorOfAnnulation.*,
	|	Reservations.AnnulationReason.*,
	|	Reservations.Reservation.* AS Reservation,
	|	Reservations.Hotel.* AS Hotel,
	|	Reservations.Room.* AS Room,
	|	Reservations.CustomerType.* AS CustomerType,
	|	Reservations.Customer.* AS Customer,
	|	Reservations.Contract.* AS Contract,
	|	Reservations.ContactPerson AS ContactPerson,
	|	Reservations.Agent.* AS Agent,
	|	Reservations.ClientType.* AS ClientType,
	|	Reservations.Guest.* AS Guest,
	|	Reservations.CheckInDate AS CheckInDate,
	|	Reservations.Duration AS Duration,
	|	Reservations.CheckOutDate AS CheckOutDate,
	|	Reservations.RoomType.* AS RoomType,
	|	Reservations.AccommodationType.* AS AccommodationType,
	|	Reservations.RoomRateType.* AS RoomRateType,
	|	Reservations.RoomRate.* AS RoomRate,
	|	Reservations.PricePresentation AS PricePresentation,
	|	Reservations.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	Reservations.Remarks AS Remarks,
	|	Reservations.Car AS Car,
	|	Reservations.GuestGroup.* AS GuestGroup,
	|	Reservations.ReservationStatus.* AS ReservationStatus,
	|	Reservations.IsMaster AS IsMaster,
	|	Reservations.HotelProduct.* AS HotelProduct,
	|	Reservations.RoomQuota.* AS RoomQuota,
	|	Reservations.MarketingCode.* AS MarketingCode,
	|	Reservations.TripPurpose.* AS TripPurpose,
	|	Reservations.SourceOfBusiness.* AS SourceOfBusiness,
	|	Reservations.Author.* AS Author,
	|	Reservations.DiscountCard.* AS DiscountCard,
	|	Reservations.DiscountType.* AS DiscountType,
	|	Reservations.Discount AS Discount,
	|	Reservations.AgentCommission AS AgentCommission,
	|	Reservations.AgentCommissionType.* AS AgentCommissionType,
	|	Reservations.NumberOfBedsPerRoom AS NumberOfBedsPerRoom,
	|	Reservations.NumberOfPersonsPerRoom AS NumberOfPersonsPerRoom,
	|	Reservations.ParentDoc.* AS ParentDoc,
	|	Reservations.NumberOfPersons AS NumberOfPersons,
	|	Reservations.RoomQuantity AS RoomQuantity,
	|	Reservations.NumberOfBeds AS NumberOfBeds,
	|	Reservations.NumberOfAdditionalBeds AS NumberOfAdditionalBeds,
	|	ReservationAmounts.Currency.* AS Currency,
	|	ReservationAmounts.ExpectedGuestDays AS ExpectedGuestDays,
	|	ReservationAmounts.ExpectedRoomsRented AS ExpectedRoomsRented,
	|	ReservationAmounts.ExpectedBedsRented AS ExpectedBedsRented,
	|	ReservationAmounts.ExpectedAdditionalBedsRented AS ExpectedAdditionalBedsRented,
	|	ReservationAmounts.ExpectedSales AS ExpectedSales,
	|	ReservationAmounts.ExpectedSalesWithoutVAT AS ExpectedSalesWithoutVAT,
	|	(1) AS Counter}
	|
	|ORDER BY
	|	Hotel,
	|	Customer,
	|	GuestGroup,
	|	CheckInDate,
	|	AccommodationType,
	|	Guest
	|{ORDER BY
	|	DateOfAnnulation,
	|	AccountingDateOfAnnulation,
	|	AuthorOfAnnulation.*,
	|	AnnulationReason.*,
	|	Reservation.*,
	|	Hotel.* AS Hotel,
	|	Room.* AS Room,
	|	Reservations.CustomerType.* AS CustomerType,
	|	Customer.* AS Customer,
	|	Reservations.Contract.* AS Contract,
	|	Reservations.ContactPerson AS ContactPerson,
	|	Reservations.Agent.* AS Agent,
	|	Reservations.ClientType.* AS ClientType,
	|	Guest.* AS Guest,
	|	CheckInDate AS CheckInDate,
	|	Duration AS Duration,
	|	CheckOutDate AS CheckOutDate,
	|	(BEGINOFPERIOD(Reservations.CheckInDate, DAY)) AS CheckInAccountingDate,
	|	(BEGINOFPERIOD(Reservations.CheckOutDate, DAY)) AS CheckOutAccountingDate,
	|	RoomType.* AS RoomType,
	|	AccommodationType.* AS AccommodationType,
	|	Reservations.RoomRateType.* AS RoomRateType,
	|	RoomRate.* AS RoomRate,
	|	PricePresentation AS PricePresentation,
	|	Reservations.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	Remarks AS Remarks,
	|	Reservations.Car AS Car,
	|	GuestGroup.* AS GuestGroup,
	|	ReservationStatus.* AS ReservationStatus,
	|	Reservations.IsMaster AS IsMaster,
	|	Reservations.HotelProduct.* AS HotelProduct,
	|	Reservations.RoomQuota.* AS RoomQuota,
	|	Reservations.MarketingCode.* AS MarketingCode,
	|	Reservations.TripPurpose.* AS TripPurpose,
	|	Reservations.SourceOfBusiness.* AS SourceOfBusiness,
	|	Reservations.Author.* AS Author,
	|	Reservations.DiscountCard.* AS DiscountCard,
	|	Reservations.DiscountType.* AS DiscountType,
	|	Reservations.Discount AS Discount,
	|	Reservations.AgentCommission AS AgentCommission,
	|	Reservations.AgentCommissionType.* AS AgentCommissionType,
	|	Reservations.NumberOfBedsPerRoom AS NumberOfBedsPerRoom,
	|	Reservations.NumberOfPersonsPerRoom AS NumberOfPersonsPerRoom,
	|	Reservations.ParentDoc.* AS ParentDoc,
	|	NumberOfPersons AS NumberOfPersons,
	|	RoomQuantity AS RoomQuantity,
	|	NumberOfRooms AS NumberOfRooms,
	|	NumberOfBeds AS NumberOfBeds,
	|	NumberOfAdditionalBeds AS NumberOfAdditionalBeds,
	|	Currency.* AS Currency,
	|	ExpectedGuestDays,
	|	ExpectedRoomsRented,
	|	ExpectedBedsRented,
	|	ExpectedAdditionalBedsRented,
	|	ExpectedSales,
	|	ExpectedSalesWithoutVAT,
	|	Counter AS Counter}
	|TOTALS
	|	SUM(NumberOfPersons),
	|	SUM(RoomQuantity),
	|	SUM(NumberOfRooms),
	|	SUM(NumberOfBeds),
	|	SUM(NumberOfAdditionalBeds),
	|	SUM(ExpectedGuestDays),
	|	SUM(ExpectedRoomsRented),
	|	SUM(ExpectedBedsRented),
	|	SUM(ExpectedAdditionalBedsRented),
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
	|	Reservation.*,
	|	Hotel.* AS Hotel,
	|	Room.* AS Room,
	|	Reservations.CustomerType.* AS CustomerType,
	|	Customer.* AS Customer,
	|	Reservations.Contract.* AS Contract,
	|	Reservations.ContactPerson AS ContactPerson,
	|	Reservations.Agent.* AS Agent,
	|	Reservations.ClientType.* AS ClientType,
	|	Guest.* AS Guest,
	|	Duration AS Duration,
	|	(BEGINOFPERIOD(Reservations.CheckInDate, DAY)) AS CheckInAccountingDate,
	|	(BEGINOFPERIOD(Reservations.CheckOutDate, DAY)) AS CheckOutAccountingDate,
	|	RoomType.* AS RoomType,
	|	AccommodationType.* AS AccommodationType,
	|	Reservations.RoomRateType.* AS RoomRateType,
	|	RoomRate.* AS RoomRate,
	|	PricePresentation AS PricePresentation,
	|	Reservations.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	GuestGroup.* AS GuestGroup,
	|	ReservationStatus.* AS ReservationStatus,
	|	Reservations.HotelProduct.* AS HotelProduct,
	|	Reservations.RoomQuota.* AS RoomQuota,
	|	Reservations.MarketingCode.* AS MarketingCode,
	|	Reservations.TripPurpose.* AS TripPurpose,
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
	ReportBuilder.HeaderText = NStr("EN='Reservation annulations audit';RU='Аудит аннуляций брони';de='Buchprüfung der Annullierung der Buchung'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
