
#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pGenerateOnly	 - boolean - Generate only
//
Procedure pmSaveReportAttributes(pGenerateOnly = False) Export
	cmSaveReportAttributes(ThisObject, , pGenerateOnly);
EndProcedure // pmSaveReportAttributes

// -----------------------------------------------------------------------------
//
// Parameters:
//  pParameter	 - AnyRef	 - Fill parameter
//
Procedure pmLoadReportAttributes(pParameter = Undefined) Export
	cmLoadReportAttributes(ThisObject, pParameter);
EndProcedure // pmLoadReportAttributes

// -----------------------------------------------------------------------------
//  Initialize attributes with default values
//  Attention: This procedure could be called AFTER some attributes initialization
//  routine, so it SHOULD NOT reset attributes being set before
//
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
// 
// Returns:
//  String - Parameters presentation
//
Function pmGetReportParametersPresentation() Export
	vParamPresentation = "";   
	vSep = ";" + Chars.LF;
	If Not ValueIsFilled(PeriodFrom) And Not ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("en = 'Report period is not set'; de = 'Berichtszeitraum nicht festgelegt'; ru = 'Период отчета не установлен'") + vSep;
	ElsIf ValueIsFilled(PeriodFrom) And Not ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("en = 'Period from '; de = 'Periode von '; ru = 'Период c '") + Format(PeriodFrom, "DF='dd.MM.yyyy HH:mm'") + vSep;
	ElsIf Not ValueIsFilled(PeriodFrom) And ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("en = 'Period to '; de = 'Periode zu '; ru = 'Период по '") + Format(PeriodTo, "DF='dd.MM.yyyy HH:mm'") + vSep;
	ElsIf PeriodFrom = PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период на '; en = 'Period on '; de = 'Periode '") + Format(PeriodFrom, "DF='dd.MM.yyyy HH:mm'") + vSep;
	ElsIf PeriodFrom < PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период '; en = 'Period '; de = 'Periode '") + PeriodPresentation(PeriodFrom, PeriodTo, cmLocalizationCode()) + vSep;
	Else
		vParamPresentation = vParamPresentation + NStr("en='Period is wrong!';ru='Неправильно задан период!';de='Der Zeitraum wurde falsch eingetragen!'") + vSep;
	EndIf;
	If ValueIsFilled(Room) Then
		If Not Room.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Room ';ru='Номер ';de='Zimmer '") + TrimAll(Room.Description) + vSep;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Rooms folder ';ru='Группа номеров ';de='Gruppe Zimmer '") + TrimAll(Room.Description) + vSep;
		EndIf;
	EndIf;
	If ValueIsFilled(RoomType) Then
		If Not RoomType.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Room type ';ru='Тип номера ';de='Zimmertyp '") + TrimAll(RoomType.Description) + vSep;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Room types folder ';ru='Группа типов номеров ';de='Gruppe Zimmertypen '") + TrimAll(RoomType.Description) + vSep;
		EndIf;
	EndIf;
	If ValueIsFilled(Employee) Then
		If Not Employee.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Employee ';ru='Сотрудник ';de='Mitarbeiter '") + TrimAll(Employee) + vSep;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа сотрудников '; en = 'Employees folder '; de = 'Gruppe Mitarbeiter '") + TrimAll(Employee) + vSep;
		EndIf;
	EndIf;
	If ValueIsFilled(Hotel) Then
		If Not Hotel.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en = 'Hotel '; de = 'Hotel '; ru = 'Гостиница '") + Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + vSep;
		Else
			vParamPresentation = vParamPresentation + NStr("en = 'Hotels folder '; de = 'Gruppe Hotels '; ru = 'Группа гостиниц '") + Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + vSep;
		EndIf;
	EndIf;
	Return vParamPresentation;
EndFunction // pmGetReportParametersPresentation

// -----------------------------------------------------------------------------
//  Runs report
//
// Parameters:
//  pSpreadsheet - Spreadsheet	 - Spreadsheet document
//
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
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qEmployee", Employee);

	// Execute report builder query
	ReportBuilder.Execute();
	
	// Apply appearance settings to the report template
	vTemplateAttributes = cmApplyReportTemplateAppearance(ThisObject);
	
	// Output report to the spreadsheet
	ReportBuilder.Put(pSpreadsheet);

	// Apply appearance settings to the report spreadsheet
	cmApplyReportAppearance(ThisObject, pSpreadsheet, vTemplateAttributes);
EndProcedure // pmGenerate

// -----------------------------------------------------------------------------
//
Procedure pmInitializeReportBuilder() Export
	ReportBuilder = New ReportBuilder();
	
	// Initialize default query text
	QueryText = 
	"SELECT
	|	AccommodationFirstAnnulation.Period AS TimeOfAnnulation,
	|	AccommodationFirstAnnulation.User AS AuthorOfAnnulation,
	|	DATEDIFF(RoomInventory.Recorder.CheckInDate, AccommodationFirstAnnulation.Period, MINUTE) AS MinutesBetweenAnnulationAndCheckIn,
	|	DATEDIFF(RoomInventory.Recorder.CheckInDate, AccommodationFirstAnnulation.Period, HOUR) AS HoursBetweenAnnulationAndCheckIn,
	|	Returns.Return AS Return,
	|	RoomInventory.Quantity AS Quantity,
	|	PaymentAnnulations.AnnulatedPayment AS AnnulatedPayment,
	|	RoomInventory.Recorder.Hotel AS Hotel,
	|	RoomInventory.Recorder.Room AS Room,
	|	RoomInventory.Recorder.Customer AS Customer,
	|	RoomInventory.Recorder.GuestGroup AS GuestGroup,
	|	RoomInventory.Recorder.AccommodationStatus AS AccommodationStatus,
	|	RoomInventory.Recorder.Guest AS Guest,
	|	RoomInventory.Recorder.CheckInDate AS CheckInDate,
	|	RoomInventory.Recorder.Duration AS Duration,
	|	RoomInventory.Recorder.CheckOutDate AS CheckOutDate,
	|	RoomInventory.Recorder.RoomType AS RoomType,
	|	RoomInventory.Recorder.AccommodationType AS AccommodationType,
	|	RoomInventory.Recorder.RoomRate AS RoomRate,
	|	RoomInventory.Recorder.PricePresentation AS PricePresentation,
	|	RoomInventory.Recorder.ParentDoc.RoomRate AS ParentDocRoomRate,
	|	RoomInventory.Recorder.ParentDoc.PricePresentation AS ParentDocPricePresentation,
	|	CASE
	|		WHEN RoomInventory.Recorder.ParentDoc.PricePresentation <> """"
	|				AND RoomInventory.Recorder.ParentDoc.PricePresentation <> RoomInventory.Recorder.PricePresentation
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThereIsPriceDifference,
	|	RoomInventory.Recorder.Remarks AS Remarks,
	|	RoomInventory.GuestsCheckedIn AS GuestsCheckedIn,
	|	RoomInventory.RoomsCheckedIn AS RoomsCheckedIn,
	|	RoomInventory.BedsCheckedIn AS BedsCheckedIn,
	|	RoomInventory.AdditionalBedsCheckedIn AS AdditionalBedsCheckedIn
	|{SELECT
	|	TimeOfAnnulation,
	|	AuthorOfAnnulation.*,
	|	MinutesBetweenAnnulationAndCheckIn,
	|	HoursBetweenAnnulationAndCheckIn,
	|	Return.*,
	|	AnnulatedPayment.*,
	|	Quantity,
	|	Hotel.* AS Hotel,
	|	Room.* AS Room,
	|	RoomInventory.Recorder.CustomerType.* AS CustomerType,
	|	Customer.* AS Customer,
	|	RoomInventory.Recorder.Contract.* AS Contract,
	|	RoomInventory.Recorder.ContactPerson AS ContactPerson,
	|	RoomInventory.Recorder.Agent.* AS Agent,
	|	RoomInventory.Recorder.ClientType.* AS ClientType,
	|	Guest.* AS Guest,
	|	CheckInDate AS CheckInDate,
	|	Duration AS Duration,
	|	CheckOutDate AS CheckOutDate,
	|	RoomInventory.CheckInAccountingDate AS CheckInAccountingDate,
	|	RoomInventory.CheckOutAccountingDate AS CheckOutAccountingDate,
	|	(HOUR(RoomInventory.Recorder.CheckInDate)) AS CheckInHour,
	|	(DAY(RoomInventory.Recorder.CheckInDate)) AS CheckInDay,
	|	(WEEK(RoomInventory.Recorder.CheckInDate)) AS CheckInWeek,
	|	(MONTH(RoomInventory.Recorder.CheckInDate)) AS CheckInMonth,
	|	(QUARTER(RoomInventory.Recorder.CheckInDate)) AS CheckInQuarter,
	|	(YEAR(RoomInventory.Recorder.CheckInDate)) AS CheckInYear,
	|	RoomType.* AS RoomType,
	|	AccommodationType.* AS AccommodationType,
	|	RoomInventory.Recorder.RoomRateType.* AS RoomRateType,
	|	RoomRate.* AS RoomRate,
	|	PricePresentation AS PricePresentation,
	|	RoomInventory.Recorder.ParentDoc.RoomType.* AS ParentDocRoomType,
	|	RoomInventory.Recorder.ParentDoc.AccommodationType.* AS ParentDocAccommodationType,
	|	RoomInventory.Recorder.ParentDoc.RoomRateType.* AS ParentDocRoomRateType,
	|	ParentDocRoomRate.* AS ParentDocRoomRate,
	|	ParentDocPricePresentation AS ParentDocPricePresentation,
	|	ThereIsPriceDifference AS ThereIsPriceDifference,
	|	RoomInventory.Recorder.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	Remarks AS Remarks,
	|	RoomInventory.Recorder.Car AS Car,
	|	GuestGroup.* AS GuestGroup,
	|	AccommodationStatus.* AS AccommodationStatus,
	|	RoomInventory.Recorder.IsMaster AS IsMaster,
	|	RoomInventory.Recorder.HotelProduct.* AS HotelProduct,
	|	RoomInventory.Recorder.RoomQuota.* AS RoomQuota,
	|	RoomInventory.Recorder.MarketingCode.* AS MarketingCode,
	|	RoomInventory.Recorder.TripPurpose.* AS TripPurpose,
	|	RoomInventory.Recorder.SourceOfBusiness.* AS SourceOfBusiness,
	|	RoomInventory.Recorder.Author.* AS Author,
	|	RoomInventory.Recorder.DiscountCard.* AS DiscountCard,
	|	RoomInventory.Recorder.DiscountType.* AS DiscountType,
	|	RoomInventory.Recorder.Discount AS Discount,
	|	RoomInventory.Recorder.AgentCommission AS AgentCommission,
	|	RoomInventory.Recorder.AgentCommissionType.* AS AgentCommissionType,
	|	RoomInventory.Recorder.NumberOfBedsPerRoom AS NumberOfBedsPerRoom,
	|	RoomInventory.Recorder.NumberOfPersonsPerRoom AS NumberOfPersonsPerRoom,
	|	RoomInventory.Recorder.ParentDoc.* AS ParentDoc,
	|	RoomInventory.Recorder.* AS Recorder,
	|	RoomInventory.Recorder.PointInTime AS PointInTime,
	|	GuestsCheckedIn AS GuestsCheckedIn,
	|	RoomsCheckedIn AS RoomsCheckedIn,
	|	BedsCheckedIn AS BedsCheckedIn,
	|	AdditionalBedsCheckedIn AS AdditionalBedsCheckedIn}
	|FROM
	|	(SELECT
	|		RoomInventoryMovements.Ref AS Recorder,
	|		1 AS Quantity,
	|		MIN(BEGINOFPERIOD(RoomInventoryMovements.CheckInDate, DAY)) AS CheckInAccountingDate,
	|		MAX(BEGINOFPERIOD(RoomInventoryMovements.CheckOutDate, DAY)) AS CheckOutAccountingDate,
	|		SUM(RoomInventoryMovements.NumberOfPersons) AS GuestsCheckedIn,
	|		SUM(RoomInventoryMovements.NumberOfRooms) AS RoomsCheckedIn,
	|		SUM(RoomInventoryMovements.NumberOfBeds) AS BedsCheckedIn,
	|		SUM(RoomInventoryMovements.NumberOfAdditionalBeds) AS AdditionalBedsCheckedIn
	|	FROM
	|		Document.Accommodation AS RoomInventoryMovements
	|	WHERE
	|		(NOT RoomInventoryMovements.AccommodationStatus.IsActive
	|				OR RoomInventoryMovements.DeletionMark)
	|		AND RoomInventoryMovements.Hotel IN HIERARCHY(&qHotel)
	|		AND RoomInventoryMovements.Room IN HIERARCHY(&qRoom)
	|		AND RoomInventoryMovements.RoomType IN HIERARCHY(&qRoomType)
	|		AND RoomInventoryMovements.Author IN HIERARCHY(&qEmployee)
	|	
	|	GROUP BY
	|		RoomInventoryMovements.Ref) AS RoomInventory
	|		INNER JOIN (SELECT
	|			AccommodationChangeHistorySliceFirst.Accommodation AS Accommodation,
	|			AccommodationChangeHistorySliceFirst.Period AS Period,
	|			AccommodationChangeHistorySliceFirst.User AS User
	|		FROM
	|			InformationRegister.AccommodationChangeHistory.SliceFirst(&qPeriodFrom, NOT AccommodationStatus.IsActive) AS AccommodationChangeHistorySliceFirst) AS AccommodationFirstAnnulation
	|		ON RoomInventory.Recorder = AccommodationFirstAnnulation.Accommodation
	|		LEFT JOIN (SELECT
	|			Return.Ref AS Return,
	|			Return.ParentDoc AS ParentDoc
	|		FROM
	|			Document.Return AS Return) AS Returns
	|		ON RoomInventory.Recorder = Returns.ParentDoc
	|		LEFT JOIN (SELECT
	|			Payments.Ref AS AnnulatedPayment,
	|			Payments.ParentDoc AS ParentDoc,
	|			Payments.DeletionMark AS DeletionMark
	|		FROM
	|			Document.Payment AS Payments) AS PaymentAnnulations
	|		ON RoomInventory.Recorder = PaymentAnnulations.ParentDoc
	|			AND (PaymentAnnulations.DeletionMark)
	|WHERE
	|	AccommodationFirstAnnulation.Period <= &qPeriodTo
	|{WHERE
	|	AccommodationFirstAnnulation.Period AS TimeOfAnnulation,
	|	AccommodationFirstAnnulation.User.* AS AuthorOfAnnulation,
	|	(DATEDIFF(RoomInventory.Recorder.CheckInDate, AccommodationFirstAnnulation.Period, MINUTE)) AS MinutesBetweenAnnulationAndCheckIn,
	|	(DATEDIFF(RoomInventory.Recorder.CheckInDate, AccommodationFirstAnnulation.Period, HOUR)) AS HoursBetweenAnnulationAndCheckIn,
	|	Returns.Return AS Return,
	|	PaymentAnnulations.AnnulatedPayment AS AnnulatedPayment,
	|	RoomInventory.Recorder.* AS Recorder,
	|	RoomInventory.Recorder.Hotel.* AS Hotel,
	|	RoomInventory.Recorder.Room.* AS Room,
	|	RoomInventory.Recorder.Customer.* AS Customer,
	|	RoomInventory.Recorder.CustomerType.* AS CustomerType,
	|	RoomInventory.Recorder.Contract.* AS Contract,
	|	RoomInventory.Recorder.ContactPerson AS ContactPerson,
	|	RoomInventory.Recorder.Agent.* AS Agent,
	|	RoomInventory.Recorder.GuestGroup.* AS GuestGroup,
	|	RoomInventory.Recorder.ParentDoc.* AS ParentDoc,
	|	RoomInventory.Recorder.HotelProduct.* AS HotelProduct,
	|	RoomInventory.Recorder.AccommodationStatus.* AS AccommodationStatus,
	|	RoomInventory.Recorder.CheckInDate AS CheckInDate,
	|	RoomInventory.Recorder.Duration AS Duration,
	|	RoomInventory.Recorder.CheckOutDate AS CheckOutDate,
	|	RoomInventory.CheckInAccountingDate AS CheckInAccountingDate,
	|	RoomInventory.CheckOutAccountingDate AS CheckOutAccountingDate,
	|	RoomInventory.Recorder.RoomQuota.* AS RoomQuota,
	|	RoomInventory.Recorder.ClientType.* AS ClientType,
	|	RoomInventory.Recorder.Guest.* AS Guest,
	|	RoomInventory.Recorder.MarketingCode.* AS MarketingCode,
	|	RoomInventory.Recorder.TripPurpose.* AS TripPurpose,
	|	RoomInventory.Recorder.SourceOfBusiness.* AS SourceOfBusiness,
	|	RoomInventory.Recorder.RoomType.* AS RoomType,
	|	RoomInventory.Recorder.AccommodationType.* AS AccommodationType,
	|	RoomInventory.Recorder.RoomRateType.* AS RoomRateType,
	|	RoomInventory.Recorder.RoomRate.* AS RoomRate,
	|	RoomInventory.Recorder.PricePresentation AS PricePresentation,
	|	RoomInventory.Recorder.ParentDoc.RoomType.* AS ParentDocRoomType,
	|	RoomInventory.Recorder.ParentDoc.AccommodationType.* AS ParentDocAccommodationType,
	|	RoomInventory.Recorder.ParentDoc.RoomRateType.* AS ParentDocRoomRateType,
	|	RoomInventory.Recorder.ParentDoc.RoomRate.* AS ParentDocRoomRate,
	|	RoomInventory.Recorder.ParentDoc.PricePresentation AS ParentDocPricePresentation,
	|	(CASE
	|			WHEN RoomInventory.Recorder.ParentDoc.PricePresentation <> """"
	|					AND RoomInventory.Recorder.ParentDoc.PricePresentation <> RoomInventory.Recorder.PricePresentation
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS ThereIsPriceDifference,
	|	RoomInventory.Recorder.Author.* AS Author,
	|	RoomInventory.Recorder.DiscountCard.* AS DiscountCard,
	|	RoomInventory.Recorder.DiscountType.* AS DiscountType,
	|	RoomInventory.Recorder.Discount AS Discount,
	|	RoomInventory.Recorder.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	RoomInventory.Recorder.Car AS Car,
	|	RoomInventory.Recorder.Remarks AS Remarks,
	|	RoomInventory.Recorder.AgentCommission AS AgentCommission,
	|	RoomInventory.Recorder.AgentCommissionType.* AS AgentCommissionType,
	|	RoomInventory.Recorder.IsMaster AS IsMaster,
	|	RoomInventory.RoomsCheckedIn AS RoomsCheckedIn,
	|	RoomInventory.BedsCheckedIn AS BedsCheckedIn,
	|	RoomInventory.AdditionalBedsCheckedIn AS AdditionalBedsCheckedIn,
	|	RoomInventory.GuestsCheckedIn AS GuestsCheckedIn}
	|
	|ORDER BY
	|	Hotel,
	|	Room,
	|	CheckInDate,
	|	Guest
	|{ORDER BY
	|	TimeOfAnnulation,
	|	AuthorOfAnnulation.*,
	|	MinutesBetweenAnnulationAndCheckIn,
	|	HoursBetweenAnnulationAndCheckIn,
	|	Return.*,
	|	AnnulatedPayment.*,
	|	Customer.*,
	|	RoomInventory.Recorder.CustomerType.* AS CustomerType,
	|	RoomInventory.Recorder.Contract.* AS Contract,
	|	RoomInventory.Recorder.Agent.* AS Agent,
	|	GuestGroup.* AS GuestGroup,
	|	Guest.* AS Guest,
	|	RoomInventory.Recorder.MarketingCode.* AS MarketingCode,
	|	RoomInventory.Recorder.TripPurpose.* AS TripPurpose,
	|	RoomInventory.Recorder.SourceOfBusiness.* AS SourceOfBusiness,
	|	RoomInventory.Recorder.RoomRateType.* AS RoomRateType,
	|	RoomInventory.Recorder.HotelProduct.* AS HotelProduct,
	|	RoomRate.* AS RoomRate,
	|	PricePresentation AS PricePresentation,
	|	RoomInventory.Recorder.DiscountCard.* AS DiscountCard,
	|	RoomInventory.Recorder.DiscountType.* AS DiscountType,
	|	RoomInventory.Recorder.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	Room.* AS Room,
	|	RoomType.* AS RoomType,
	|	Hotel.* AS Hotel,
	|	RoomInventory.Recorder.PointInTime AS PointInTime,
	|	CheckInDate AS CheckInDate,
	|	Duration AS Duration,
	|	CheckOutDate AS CheckOutDate,
	|	RoomInventory.CheckInAccountingDate AS CheckInAccountingDate,
	|	RoomInventory.CheckOutAccountingDate AS CheckOutAccountingDate,
	|	(HOUR(RoomInventory.Recorder.CheckInDate)) AS CheckInHour,
	|	(DAY(RoomInventory.Recorder.CheckInDate)) AS CheckInDay,
	|	(WEEK(RoomInventory.Recorder.CheckInDate)) AS CheckInWeek,
	|	(MONTH(RoomInventory.Recorder.CheckInDate)) AS CheckInMonth,
	|	(QUARTER(RoomInventory.Recorder.CheckInDate)) AS CheckInQuarter,
	|	(YEAR(RoomInventory.Recorder.CheckInDate)) AS CheckInYear,
	|	RoomInventory.Recorder.RoomQuota.* AS RoomQuota,
	|	RoomInventory.Recorder.Author.* AS Author,
	|	RoomInventory.Recorder.ParentDoc.* AS ParentDoc,
	|	RoomInventory.Recorder.* AS Recorder,
	|	RoomInventory.Recorder.ParentDoc.RoomType.* AS ParentDocRoomType,
	|	RoomInventory.Recorder.ParentDoc.AccommodationType.* AS ParentDocAccommodationType,
	|	RoomInventory.Recorder.ParentDoc.RoomRateType.* AS ParentDocRoomRateType,
	|	ParentDocRoomRate.* AS ParentDocRoomRate,
	|	RoomsCheckedIn AS RoomsCheckedIn,
	|	BedsCheckedIn AS BedsCheckedIn,
	|	AdditionalBedsCheckedIn AS AdditionalBedsCheckedIn,
	|	GuestsCheckedIn AS GuestsCheckedIn}
	|TOTALS
	|	SUM(Quantity),
	|	SUM(GuestsCheckedIn),
	|	SUM(RoomsCheckedIn),
	|	SUM(BedsCheckedIn),
	|	SUM(AdditionalBedsCheckedIn)
	|BY
	|	OVERALL,
	|	Hotel,
	|	Room
	|{TOTALS BY
	|	AuthorOfAnnulation.*,
	|	Hotel.* AS Hotel,
	|	RoomInventory.CheckInAccountingDate AS CheckInAccountingDate,
	|	RoomInventory.CheckOutAccountingDate AS CheckOutAccountingDate,
	|	(HOUR(RoomInventory.Recorder.CheckInDate)) AS CheckInHour,
	|	(DAY(RoomInventory.Recorder.CheckInDate)) AS CheckInDay,
	|	(WEEK(RoomInventory.Recorder.CheckInDate)) AS CheckInWeek,
	|	(MONTH(RoomInventory.Recorder.CheckInDate)) AS CheckInMonth,
	|	(QUARTER(RoomInventory.Recorder.CheckInDate)) AS CheckInQuarter,
	|	(YEAR(RoomInventory.Recorder.CheckInDate)) AS CheckInYear,
	|	Guest.* AS Guest,
	|	AccommodationStatus.* AS AccommodationStatus,
	|	AccommodationType.* AS AccommodationType,
	|	RoomRate.* AS RoomRate,
	|	RoomType.* AS RoomType,
	|	Room.* AS Room,
	|	Customer.* AS Customer,
	|	RoomInventory.Recorder.ParentDoc.* AS ParentDoc,
	|	RoomInventory.Recorder.* AS Recorder,
	|	RoomInventory.Recorder.CustomerType.* AS CustomerType,
	|	RoomInventory.Recorder.Contract.* AS Contract,
	|	RoomInventory.Recorder.ContactPerson AS ContactPerson,
	|	RoomInventory.Recorder.Agent.* AS Agent,
	|	GuestGroup.* AS GuestGroup,
	|	RoomInventory.Recorder.HotelProduct.* AS HotelProduct,
	|	AccommodationStatus.* AS AccommodationStatus,
	|	RoomInventory.Recorder.RoomQuota.* AS RoomQuota,
	|	RoomInventory.Recorder.ClientType.* AS ClientType,
	|	RoomInventory.Recorder.MarketingCode.* AS MarketingCode,
	|	RoomInventory.Recorder.TripPurpose.* AS TripPurpose,
	|	RoomInventory.Recorder.SourceOfBusiness.* AS SourceOfBusiness,
	|	RoomInventory.Recorder.RoomRateType.* AS RoomRateType,
	|	RoomInventory.Recorder.Author.* AS Author,
	|	PricePresentation AS PricePresentation,
	|	RoomInventory.Recorder.ParentDoc.RoomType.* AS ParentDocRoomType,
	|	RoomInventory.Recorder.ParentDoc.AccommodationType.* AS ParentDocAccommodationType,
	|	RoomInventory.Recorder.ParentDoc.RoomRateType.* AS ParentDocRoomRateType,
	|	ParentDocRoomRate.* AS ParentDocRoomRate,
	|	RoomInventory.Recorder.DiscountCard.* AS DiscountCard,
	|	RoomInventory.Recorder.DiscountType.* AS DiscountType,
	|	RoomInventory.Recorder.PlannedPaymentMethod.* AS PlannedPaymentMethod}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("en = 'Accommodation annulations audit'; de = 'Buchprüfung der Annullierung von Unterbringungen'; ru = 'Аудит аннуляций размещений'");
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

#EndRegion
