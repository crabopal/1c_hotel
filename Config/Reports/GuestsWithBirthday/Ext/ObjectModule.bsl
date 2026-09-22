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
	If Not ValueIsFilled(BirthDateFrom) Then
		BirthDateFrom = Date(2000, Month(PeriodFrom), Day(PeriodFrom));
	EndIf;
	If Not ValueIsFilled(BirthDateTo) Then
		BirthDateTo = Date(2000, Month(PeriodTo), Day(PeriodTo));
	EndIf;
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
		ShowOnSiteGuestsOnly = True;
	EndIf;
	If Not ValueIsFilled(BirthDateFrom) Then
		BirthDateFrom = Date(2000, Month(PeriodFrom), Day(PeriodFrom));
	EndIf;
	If Not ValueIsFilled(BirthDateTo) Then
		BirthDateTo = Date(2000, Month(PeriodTo), Day(PeriodTo));
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
		                     Format(PeriodFrom, "DF=dd.MM.yyyy") + 
		                     ";" + Chars.LF;
	ElsIf Not ValueIsFilled(PeriodFrom) And ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период по '; en = 'Period to '; de = 'Periode zu '") + 
		                     Format(PeriodTo, "DF=dd.MM.yyyy") + 
		                     ";" + Chars.LF;
	ElsIf BegOfDay(PeriodFrom) = BegOfDay(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период на '; en = 'Period on '; de = 'Periode '") + 
		                     Format(PeriodFrom, "DF=dd.MM.yyyy") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom < PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период с '; en = 'Period from '; de = 'Periode von '") + 
		                     Format(PeriodFrom, "DF=dd.MM.yyyy") + NStr("en=' to '; ru=' по '; de=' zu '") + 
							 Format(PeriodTo, "DF=dd.MM.yyyy") + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("en='Period is wrong!';ru='Неправильно задан период!';de='Der Zeitraum wurde falsch eingetragen!'") + 
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
	ReportBuilder.Parameters.Insert("qPeriodFrom", BegOfDay(PeriodFrom));
	ReportBuilder.Parameters.Insert("qPeriodTo", EndOfDay(PeriodTo));
	ReportBuilder.Parameters.Insert("qBirthDateFrom", ?(ValueIsFilled(BirthDateFrom), BirthDateFrom, Date(2000, Month(PeriodFrom), Day(PeriodFrom))));
	ReportBuilder.Parameters.Insert("qBirthDateTo", ?(ValueIsFilled(BirthDateTo), BirthDateTo, Date(2000, Month(PeriodTo), Day(PeriodTo))));
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qEndOfTime", '39991231');
	ReportBuilder.Parameters.Insert("qEmptyDate", '00010101');
	ReportBuilder.Parameters.Insert("qEmptyRoom", Catalogs.Rooms.EmptyRef());
	ReportBuilder.Parameters.Insert("qShowOnSiteGuestsOnly", ShowOnSiteGuestsOnly);

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
	|	RoomInventory.Recorder.Hotel AS Hotel,
	|	RoomInventory.Room AS Room,
	|	RoomInventory.Recorder.Customer AS Customer,
	|	RoomInventory.Recorder.GuestGroup AS GuestGroup,
	|	CASE
	|		WHEN RoomInventory.Recorder.AccommodationStatus IS NULL
	|			THEN RoomInventory.Recorder.ReservationStatus
	|		ELSE RoomInventory.Recorder.AccommodationStatus
	|	END AS Status,
	|	RoomInventory.Recorder.Guest AS Guest,
	|	RoomInventory.Recorder.Guest.DateOfBirth AS GuestDateOfBirth,
	|	CASE
	|		WHEN RoomInventory.Recorder.Guest.DateOfBirth IS NULL
	|			THEN NULL
	|		WHEN RoomInventory.Recorder.Guest.DateOfBirth = &qEmptyDate
	|			THEN NULL
	|		WHEN DAYOFYEAR(RoomInventory.Recorder.Guest.DateOfBirth) < DAYOFYEAR(RoomInventory.Recorder.CheckInDate)
	|			THEN YEAR(RoomInventory.Recorder.CheckInDate) - YEAR(RoomInventory.Recorder.Guest.DateOfBirth) - 1
	|		ELSE YEAR(RoomInventory.Recorder.CheckInDate) - YEAR(RoomInventory.Recorder.Guest.DateOfBirth)
	|	END AS GuestAge,
	|	RoomInventory.Recorder.CheckInDate AS CheckInDate,
	|	RoomInventory.Recorder.Duration AS Duration,
	|	RoomInventory.Recorder.CheckOutDate AS CheckOutDate,
	|	RoomInventory.RoomType AS RoomType,
	|	RoomInventory.Recorder.AccommodationType AS AccommodationType,
	|	RoomInventory.Recorder.RoomRate AS RoomRate,
	|	RoomInventory.Recorder.PricePresentation AS PricePresentation,
	|	RoomInventory.Recorder.Remarks AS Remarks,
	|	1 AS NumberOfGuests
	|{SELECT
	|	Hotel.* AS Hotel,
	|	Room.* AS Room,
	|	RoomInventory.Recorder.CustomerType.* AS CustomerType,
	|	Customer.* AS Customer,
	|	RoomInventory.Recorder.Contract.* AS Contract,
	|	RoomInventory.Recorder.ContactPerson AS ContactPerson,
	|	RoomInventory.Recorder.Agent.* AS Agent,
	|	RoomInventory.Recorder.ClientType.* AS ClientType,
	|	Guest.* AS Guest,
	|	GuestDateOfBirth AS GuestDateOfBirth,
	|	GuestAge AS GuestAge,
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
	|	RoomInventory.Recorder.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	Remarks AS Remarks,
	|	RoomInventory.Recorder.Car AS Car,
	|	GuestGroup.* AS GuestGroup,
	|	Status.* AS Status,
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
	|	ForeignerRegistryRecords.ForeignerRegistryRecord.* AS ForeignerRegistryRecord,
	|	NumberOfGuests AS NumberOfGuests}
	|FROM
	|	(SELECT
	|		RoomInventoryMovements.Recorder AS Recorder,
	|		RoomInventoryMovements.Recorder.Room AS Room,
	|		RoomInventoryMovements.Recorder.RoomType AS RoomType,
	|		MIN(RoomInventoryMovements.CheckInAccountingDate) AS CheckInAccountingDate,
	|		MAX(RoomInventoryMovements.CheckOutAccountingDate) AS CheckOutAccountingDate
	|	FROM
	|		AccumulationRegister.RoomInventory AS RoomInventoryMovements
	|	WHERE
	|		RoomInventoryMovements.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND (RoomInventoryMovements.IsAccommodation
	|				OR RoomInventoryMovements.IsReservation)
	|		AND RoomInventoryMovements.Hotel IN HIERARCHY(&qHotel)
	|		AND (RoomInventoryMovements.Room IN HIERARCHY (&qRoom)
	|				OR RoomInventoryMovements.Room = &qEmptyRoom
	|					AND &qRoom = &qEmptyRoom)
	|		AND RoomInventoryMovements.RoomType IN HIERARCHY(&qRoomType)
	|		AND RoomInventoryMovements.CheckInDate < &qPeriodTo
	|		AND RoomInventoryMovements.CheckOutDate > &qPeriodFrom
	|		AND RoomInventoryMovements.CheckInDate = RoomInventoryMovements.PeriodFrom
	|		AND RoomInventoryMovements.Guest.DateOfBirth > &qEmptyDate
	|		AND (&qBirthDateTo >= &qBirthDateFrom
	|					AND MONTH(RoomInventoryMovements.Guest.DateOfBirth) * 100 + DAY(RoomInventoryMovements.Guest.DateOfBirth) >= MONTH(&qBirthDateFrom) * 100 + DAY(&qBirthDateFrom)
	|					AND MONTH(RoomInventoryMovements.Guest.DateOfBirth) * 100 + DAY(RoomInventoryMovements.Guest.DateOfBirth) <= MONTH(&qBirthDateTo) * 100 + DAY(&qBirthDateTo)
	|				OR &qBirthDateTo < &qBirthDateFrom
	|					AND (MONTH(RoomInventoryMovements.Guest.DateOfBirth) * 100 + DAY(RoomInventoryMovements.Guest.DateOfBirth) >= MONTH(&qBirthDateFrom) * 100 + DAY(&qBirthDateFrom)
	|							AND MONTH(RoomInventoryMovements.Guest.DateOfBirth) * 100 + DAY(RoomInventoryMovements.Guest.DateOfBirth) <= 1231
	|						OR MONTH(RoomInventoryMovements.Guest.DateOfBirth) * 100 + DAY(RoomInventoryMovements.Guest.DateOfBirth) <= MONTH(&qBirthDateTo) * 100 + DAY(&qBirthDateTo)
	|							AND MONTH(RoomInventoryMovements.Guest.DateOfBirth) * 100 + DAY(RoomInventoryMovements.Guest.DateOfBirth) >= 101))
	|		AND (NOT &qShowOnSiteGuestsOnly
	|				OR &qShowOnSiteGuestsOnly
	|					AND (YEAR(RoomInventoryMovements.CheckOutDate) = YEAR(RoomInventoryMovements.CheckInDate)
	|							AND MONTH(RoomInventoryMovements.Guest.DateOfBirth) * 100 + DAY(RoomInventoryMovements.Guest.DateOfBirth) >= MONTH(RoomInventoryMovements.CheckInDate) * 100 + DAY(RoomInventoryMovements.CheckInDate)
	|							AND MONTH(RoomInventoryMovements.Guest.DateOfBirth) * 100 + DAY(RoomInventoryMovements.Guest.DateOfBirth) <= MONTH(RoomInventoryMovements.CheckOutDate) * 100 + DAY(RoomInventoryMovements.CheckOutDate)
	|						OR YEAR(RoomInventoryMovements.CheckOutDate) <> YEAR(RoomInventoryMovements.CheckInDate)
	|							AND (MONTH(RoomInventoryMovements.Guest.DateOfBirth) * 100 + DAY(RoomInventoryMovements.Guest.DateOfBirth) >= MONTH(RoomInventoryMovements.CheckInDate) * 100 + DAY(RoomInventoryMovements.CheckInDate)
	|									AND MONTH(RoomInventoryMovements.Guest.DateOfBirth) * 100 + DAY(RoomInventoryMovements.Guest.DateOfBirth) <= 1231
	|								OR MONTH(RoomInventoryMovements.Guest.DateOfBirth) * 100 + DAY(RoomInventoryMovements.Guest.DateOfBirth) <= MONTH(RoomInventoryMovements.CheckOutDate) * 100 + DAY(RoomInventoryMovements.CheckOutDate)
	|									AND MONTH(RoomInventoryMovements.Guest.DateOfBirth) * 100 + DAY(RoomInventoryMovements.Guest.DateOfBirth) >= 101)))
	|	
	|	GROUP BY
	|		RoomInventoryMovements.Recorder,
	|		RoomInventoryMovements.Recorder.Room,
	|		RoomInventoryMovements.Recorder.RoomType) AS RoomInventory
	|		LEFT JOIN InformationRegister.AccommodationForeignerRegistryRecords.SliceLast(&qEndOfTime, ) AS ForeignerRegistryRecords
	|		ON RoomInventory.Recorder = ForeignerRegistryRecords.Accommodation
	|{WHERE
	|	RoomInventory.Recorder.* AS Recorder,
	|	RoomInventory.Recorder.Hotel.* AS Hotel,
	|	RoomInventory.Room.* AS Room,
	|	RoomInventory.Recorder.Customer.* AS Customer,
	|	RoomInventory.Recorder.CustomerType.* AS CustomerType,
	|	RoomInventory.Recorder.Contract.* AS Contract,
	|	RoomInventory.Recorder.ContactPerson AS ContactPerson,
	|	RoomInventory.Recorder.Agent.* AS Agent,
	|	RoomInventory.Recorder.GuestGroup.* AS GuestGroup,
	|	RoomInventory.Recorder.ParentDoc.* AS ParentDoc,
	|	RoomInventory.Recorder.HotelProduct.* AS HotelProduct,
	|	(CASE
	|			WHEN RoomInventory.Recorder.AccommodationStatus IS NULL
	|				THEN RoomInventory.Recorder.ReservationStatus
	|			ELSE RoomInventory.Recorder.AccommodationStatus
	|		END).* AS Status,
	|	RoomInventory.Recorder.CheckInDate AS CheckInDate,
	|	RoomInventory.Recorder.Duration AS Duration,
	|	RoomInventory.Recorder.CheckOutDate AS CheckOutDate,
	|	RoomInventory.CheckInAccountingDate AS CheckInAccountingDate,
	|	RoomInventory.CheckOutAccountingDate AS CheckOutAccountingDate,
	|	(HOUR(RoomInventory.Recorder.CheckInDate)) AS CheckInHour,
	|	RoomInventory.Recorder.RoomQuota.* AS RoomQuota,
	|	RoomInventory.Recorder.ClientType.* AS ClientType,
	|	RoomInventory.Recorder.Guest.* AS Guest,
	|	RoomInventory.Recorder.Guest.DateOfBirth AS GuestDateOfBirth,
	|	(CASE
	|			WHEN RoomInventory.Recorder.Guest.DateOfBirth IS NULL
	|				THEN NULL
	|			WHEN RoomInventory.Recorder.Guest.DateOfBirth = &qEmptyDate
	|				THEN NULL
	|			WHEN DAYOFYEAR(RoomInventory.Recorder.Guest.DateOfBirth) < DAYOFYEAR(RoomInventory.Recorder.CheckInDate)
	|				THEN YEAR(RoomInventory.Recorder.CheckInDate) - YEAR(RoomInventory.Recorder.Guest.DateOfBirth) - 1
	|			ELSE YEAR(RoomInventory.Recorder.CheckInDate) - YEAR(RoomInventory.Recorder.Guest.DateOfBirth)
	|		END) AS GuestAge,
	|	RoomInventory.Recorder.MarketingCode.* AS MarketingCode,
	|	RoomInventory.Recorder.TripPurpose.* AS TripPurpose,
	|	RoomInventory.Recorder.SourceOfBusiness.* AS SourceOfBusiness,
	|	RoomInventory.RoomType.* AS RoomType,
	|	RoomInventory.Recorder.AccommodationType.* AS AccommodationType,
	|	RoomInventory.Recorder.RoomRateType.* AS RoomRateType,
	|	RoomInventory.Recorder.RoomRate.* AS RoomRate,
	|	RoomInventory.Recorder.PricePresentation AS PricePresentation,
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
	|	ForeignerRegistryRecords.ForeignerRegistryRecord.* AS ForeignerRegistryRecord,
	|	(1) AS NumberOfGuests}
	|
	|ORDER BY
	|	Hotel,
	|	CheckInDate,
	|	Guest
	|{ORDER BY
	|	Customer.*,
	|	RoomInventory.Recorder.CustomerType.* AS CustomerType,
	|	RoomInventory.Recorder.Contract.* AS Contract,
	|	RoomInventory.Recorder.Agent.* AS Agent,
	|	GuestGroup.* AS GuestGroup,
	|	Guest.* AS Guest,
	|	GuestDateOfBirth AS GuestDateOfBirth,
	|	GuestAge AS GuestAge,
	|	RoomInventory.Recorder.MarketingCode.* AS MarketingCode,
	|	RoomInventory.Recorder.TripPurpose.* AS TripPurpose,
	|	RoomInventory.Recorder.SourceOfBusiness.* AS SourceOfBusiness,
	|	RoomInventory.Recorder.RoomRateType.* AS RoomRateType,
	|	RoomInventory.Recorder.HotelProduct.* AS HotelProduct,
	|	RoomRate.* AS RoomRate,
	|	Status.* AS Status,
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
	|	ForeignerRegistryRecords.ForeignerRegistryRecord.* AS ForeignerRegistryRecord}
	|TOTALS
	|	SUM(NumberOfGuests)
	|BY
	|	OVERALL,
	|	Hotel,
	|	Room
	|{TOTALS BY
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
	|	GuestAge AS GuestAge,
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
	|	Status.* AS Status,
	|	RoomInventory.Recorder.RoomQuota.* AS RoomQuota,
	|	RoomInventory.Recorder.ClientType.* AS ClientType,
	|	RoomInventory.Recorder.MarketingCode.* AS MarketingCode,
	|	RoomInventory.Recorder.TripPurpose.* AS TripPurpose,
	|	RoomInventory.Recorder.SourceOfBusiness.* AS SourceOfBusiness,
	|	RoomInventory.Recorder.RoomRateType.* AS RoomRateType,
	|	RoomInventory.Recorder.Author.* AS Author,
	|	PricePresentation AS PricePresentation,
	|	ForeignerRegistryRecords.ForeignerRegistryRecord.* AS ForeignerRegistryRecord,
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
	ReportBuilder.HeaderText = NStr("EN='Guests with birthday';RU='Гости, у которых день рождения';de='Gäste, die im angegebenen Zeitraum Geburtstag haben'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
