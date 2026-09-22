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
		vParamPresentation = vParamPresentation + NStr("ru = 'Период по '; en = 'Period to '; de = 'Period zu '") + 
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
	If ShowInHouseOnly Then
		vParamPresentation = vParamPresentation + NStr("en='In-house guests only';ru='Только проживающие (невыселенные) гости';de='Nur übernachtende (nicht ausquartierte) Gäste'") + 
							 ";" + Chars.LF;
	EndIf;
	If ShowNotInHouseOnly Then
		vParamPresentation = vParamPresentation + NStr("en='Checked-out guests only';ru='Только выселенные гости';de='Nur ausquartierte Gäste'") + 
							 ";" + Chars.LF;
	EndIf;
	If ShowForeignersOnly Then
		vParamPresentation = vParamPresentation + NStr("en='Foreigners only';ru='Только иностранцы';de='Nur Ausländer'") + 
							 ";" + Chars.LF;
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
	ReportBuilder.Parameters.Insert("qAccommodation", Enums.PeriodCheckTypes.Intersection);
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qShowInHouseOnly", ShowInHouseOnly);
	ReportBuilder.Parameters.Insert("qShowNotInHouseOnly", ShowNotInHouseOnly);
	ReportBuilder.Parameters.Insert("qShowForeignersOnly", ShowForeignersOnly);
	ReportBuilder.Parameters.Insert("qEndOfTime", '39991231235959');
	ReportBuilder.Parameters.Insert("qEmptyDate", '00010101');
	ReportBuilder.Parameters.Insert("qEmptyClient", Catalogs.Clients.EmptyRef());

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
	|	RoomInventory.Recorder.Room AS Room,
	|	RoomInventory.Recorder.Customer AS Customer,
	|	RoomInventory.Recorder.AccommodationStatus AS AccommodationStatus,
	|	RoomInventory.Recorder.Guest AS Guest,
	|	RoomInventory.Recorder.CheckInDate AS CheckInDate,
	|	RoomInventory.Recorder.Duration AS Duration,
	|	RoomInventory.Recorder.CheckOutDate AS CheckOutDate,
	|	RoomInventory.Recorder.RoomType AS RoomType,
	|	RoomInventory.Recorder.AccommodationType AS AccommodationType,
	|	RoomInventory.Recorder.RoomRate AS RoomRate,
	|	RoomInventory.Recorder.Remarks AS Remarks,
	|	RoomInventory.Recorder.GuestGroup AS GuestGroup,
	|	RoomInventory.Recorder.PricePresentation AS PricePresentation,
	|	RoomInventory.FirstStateRoom AS FirstStateRoom,
	|	RoomInventory.FirstStateCheckInDate AS FirstStateCheckInDate,
	|	RoomInventory.FirstStateDuration AS FirstStateDuration,
	|	RoomInventory.FirstStateCheckOutDate AS FirstStateCheckOutDate,
	|	RoomInventory.Recorder.NumberOfPersons AS InHouseGuests,
	|	RoomInventory.Recorder.NumberOfRooms AS InHouseRooms,
	|	RoomInventory.Recorder.NumberOfBeds AS InHouseBeds,
	|	RoomInventory.Recorder.NumberOfAdditionalBeds AS InHouseAdditionalBeds
	|{SELECT
	|	Hotel.*,
	|	Room.*,
	|	RoomInventory.Recorder.CustomerType.* AS CustomerType,
	|	Customer.*,
	|	RoomInventory.Recorder.Contract.* AS Contract,
	|	RoomInventory.Recorder.ContactPerson AS ContactPerson,
	|	RoomInventory.Recorder.Agent.* AS Agent,
	|	RoomInventory.Recorder.ClientType.* AS ClientType,
	|	Guest.*,
	|	CheckInDate,
	|	Duration,
	|	CheckOutDate,
	|	RoomType.*,
	|	AccommodationType.*,
	|	RoomInventory.Recorder.RoomRateType.* AS RoomRateType,
	|	RoomRate.*,
	|	PricePresentation,
	|	RoomInventory.Recorder.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	FirstStateRoom.* AS FirstStateRoom,
	|	FirstStateCheckInDate AS FirstStateCheckInDate,
	|	FirstStateDuration AS FirstStateDuration,
	|	FirstStateCheckOutDate AS FirstStateCheckOutDate,
	|	InHouseGuests,
	|	InHouseRooms,
	|	InHouseBeds,
	|	InHouseAdditionalBeds,
	|	Remarks,
	|	RoomInventory.Recorder.Car AS Car,
	|	GuestGroup.*,
	|	AccommodationStatus.*,
	|	RoomInventory.Recorder.IsMaster AS IsMaster,
	|	RoomInventory.Recorder.HotelProduct.* AS HotelProduct,
	|	RoomInventory.Recorder.RoomQuota.* AS RoomQuota,
	|	RoomInventory.Recorder.MarketingCode.* AS MarketingCode,
	|	RoomInventory.Recorder.TripPurpose.* AS TripPurpose,
	|	RoomInventory.Recorder.SourceOfBusiness.* AS SourceOfBusiness,
	|	RoomInventory.Recorder.DiscountCard.* AS DiscountCard,
	|	RoomInventory.Recorder.DiscountType.* AS DiscountType,
	|	RoomInventory.Recorder.Discount AS Discount,
	|	RoomInventory.Recorder.AgentCommission AS AgentCommission,
	|	RoomInventory.Recorder.AgentCommissionType AS AgentCommissionType,
	|	RoomInventory.Recorder.NumberOfBedsPerRoom AS NumberOfBedsPerRoom,
	|	RoomInventory.Recorder.NumberOfPersonsPerRoom AS NumberOfPersonsPerRoom,
	|	RoomInventory.Recorder.ParentDoc.* AS ParentDoc,
	|	RoomInventory.Recorder.Author.* AS Author,
	|	RoomInventory.Recorder.* AS Recorder,
	|	RoomInventory.ForeignerRegistryRecord.* AS ForeignerRegistryRecord,
	|	(CASE
	|			WHEN RoomInventory.ForeignerRegistryRecord.MigrationCardDateTo <> &qEmptyDate
	|				THEN DATEDIFF(RoomInventory.ForeignerRegistryRecord.MigrationCardDateTo, RoomInventory.Recorder.CheckOutDate, DAY)
	|			ELSE 0
	|		END) AS MigrationCardDateToDeviance,
	|	(CASE
	|			WHEN RoomInventory.ForeignerRegistryRecord.VisaToDate <> &qEmptyDate
	|				THEN DATEDIFF(RoomInventory.ForeignerRegistryRecord.VisaToDate, RoomInventory.Recorder.CheckOutDate, DAY)
	|			ELSE 0
	|		END) AS VisaToDateDeviance,
	|	RoomInventory.Recorder.PointInTime AS PointInTime,
	|	(CASE
	|			WHEN RoomInventory.FirstStateDuration < RoomInventory.Recorder.Duration
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS PeriodOfStayExtension,
	|	(CASE
	|			WHEN RoomInventory.FirstStateDuration > RoomInventory.Recorder.Duration
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS PeriodOfStayShortage}
	|FROM
	|	(SELECT
	|		ChangedAccommodations.Recorder AS Recorder,
	|		ForeignerRegistryRecords.ForeignerRegistryRecord AS ForeignerRegistryRecord,
	|		ChangedAccommodations.FirstStateCheckInDate AS FirstStateCheckInDate,
	|		ChangedAccommodations.FirstStateDuration AS FirstStateDuration,
	|		ChangedAccommodations.FirstStateCheckOutDate AS FirstStateCheckOutDate,
	|		ChangedAccommodations.FirstStateRoom AS FirstStateRoom
	|	FROM
	|		(SELECT
	|			AccommodationChangeHistory.Accommodation AS Recorder,
	|			FirstState.CheckInDate AS FirstStateCheckInDate,
	|			FirstState.Duration AS FirstStateDuration,
	|			FirstState.CheckOutDate AS FirstStateCheckOutDate,
	|			FirstState.Room AS FirstStateRoom
	|		FROM
	|			InformationRegister.AccommodationChangeHistory.SliceLast(
	|					&qPeriodTo,
	|					Hotel IN HIERARCHY (&qHotel)
	|						AND Room IN HIERARCHY (&qRoom)
	|						AND RoomType IN HIERARCHY (&qRoomType)
	|						AND (ISNULL(Accommodation.AccommodationStatus.IsInHouse, FALSE)
	|							OR NOT &qShowInHouseOnly)
	|						AND (NOT ISNULL(Accommodation.AccommodationStatus.IsInHouse, FALSE)
	|							OR NOT &qShowNotInHouseOnly)
	|						AND (ISNULL(Guest.Citizenship, VALUE(Catalog.Countries.EmptyRef)) <> Hotel.Citizenship
	|								AND &qShowForeignersOnly
	|							OR NOT &qShowForeignersOnly)) AS AccommodationChangeHistory
	|				LEFT JOIN (SELECT
	|					FirstStateAccommodations.Accommodation AS Accommodation,
	|					FirstStateAccommodations.Guest AS Guest,
	|					FirstStateAccommodations.Room AS Room,
	|					BEGINOFPERIOD(FirstStateAccommodations.CheckInDate, DAY) AS CheckInDate,
	|					FirstStateAccommodations.Duration AS Duration,
	|					BEGINOFPERIOD(FirstStateAccommodations.CheckOutDate, DAY) AS CheckOutDate
	|				FROM
	|					InformationRegister.AccommodationChangeHistory.SliceLast(
	|							&qPeriodFrom,
	|							Hotel IN HIERARCHY (&qHotel)
	|								AND Room IN HIERARCHY (&qRoom)
	|								AND RoomType IN HIERARCHY (&qRoomType)) AS FirstStateAccommodations) AS FirstState
	|				ON AccommodationChangeHistory.Accommodation = FirstState.Accommodation
	|		WHERE
	|			NOT FirstState.Accommodation IS NULL
	|			AND NOT AccommodationChangeHistory.Accommodation IN
	|						(SELECT
	|							NotChangedAccommodations.Accommodation
	|						FROM
	|							(SELECT
	|								LastState.Accommodation,
	|								LastState.Guest,
	|								LastState.Room,
	|								BEGINOFPERIOD(LastState.CheckInDate, DAY) AS CheckInDate,
	|								BEGINOFPERIOD(LastState.CheckOutDate, DAY) AS CheckOutDate
	|							FROM
	|								InformationRegister.AccommodationChangeHistory.SliceLast(&qPeriodTo, Hotel IN HIERARCHY (&qHotel)
	|									AND Room IN HIERARCHY (&qRoom)
	|									AND RoomType IN HIERARCHY (&qRoomType)) AS LastState
	|									INNER JOIN (SELECT
	|										FirstStateAccommodations.Accommodation,
	|										FirstStateAccommodations.Guest,
	|										FirstStateAccommodations.Room,
	|										BEGINOFPERIOD(FirstStateAccommodations.CheckInDate, DAY) AS CheckInDate,
	|										BEGINOFPERIOD(FirstStateAccommodations.CheckOutDate, DAY) AS CheckOutDate
	|									FROM
	|										InformationRegister.AccommodationChangeHistory.SliceLast(&qPeriodFrom, Hotel IN HIERARCHY (&qHotel)
	|											AND Room IN HIERARCHY (&qRoom)
	|											AND RoomType IN HIERARCHY (&qRoomType)) AS FirstStateAccommodations) AS FirstState
	|									ON
	|										LastState.Accommodation = FirstState.Accommodation
	|											AND LastState.Guest = FirstState.Guest
	|											AND LastState.Room = FirstState.Room
	|											AND BEGINOFPERIOD(LastState.CheckInDate, DAY) = BEGINOFPERIOD(FirstState.CheckInDate, DAY)
	|											AND BEGINOFPERIOD(LastState.CheckOutDate, DAY) = BEGINOFPERIOD(FirstState.CheckOutDate, DAY)) AS NotChangedAccommodations
	|						GROUP BY
	|							NotChangedAccommodations.Accommodation)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			ChangeRoomAccommodations.Recorder,
	|			ChangeRoomAccommodations.PeriodFrom,
	|			ChangeRoomAccommodations.PeriodDuration,
	|			ChangeRoomAccommodations.PeriodTo,
	|			ChangeRoomAccommodations.Room
	|		FROM
	|			AccumulationRegister.RoomInventory AS ChangeRoomAccommodations
	|		WHERE
	|			ChangeRoomAccommodations.IsAccommodation
	|			AND ChangeRoomAccommodations.RecordType = VALUE(AccumulationRecordType.Expense)
	|			AND ChangeRoomAccommodations.IsRoomChange
	|			AND ChangeRoomAccommodations.PeriodFrom >= &qPeriodFrom
	|			AND ChangeRoomAccommodations.PeriodFrom < &qPeriodTo
	|			AND ChangeRoomAccommodations.Hotel IN HIERARCHY(&qHotel)
	|			AND ChangeRoomAccommodations.Room IN HIERARCHY(&qRoom)
	|			AND ChangeRoomAccommodations.RoomType IN HIERARCHY(&qRoomType)
	|			AND (ChangeRoomAccommodations.IsInHouse
	|					OR NOT &qShowInHouseOnly)
	|			AND (NOT ChangeRoomAccommodations.IsInHouse
	|					OR NOT &qShowNotInHouseOnly)
	|			AND (ISNULL(ChangeRoomAccommodations.Guest.Citizenship, VALUE(Catalog.Countries.EmptyRef)) <> ChangeRoomAccommodations.Hotel.Citizenship
	|						AND &qShowForeignersOnly
	|					OR NOT &qShowForeignersOnly)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			SameDayCheckInAccommodations.Recorder,
	|			SameDayCheckInAccommodations.PeriodFrom,
	|			SameDayCheckInAccommodations.PeriodDuration,
	|			SameDayCheckInAccommodations.PeriodTo,
	|			SameDayCheckInAccommodations.Room
	|		FROM
	|			AccumulationRegister.RoomInventory AS SameDayCheckInAccommodations
	|				INNER JOIN (SELECT
	|					PrevCheckOuts.Guest AS Guest,
	|					MAX(PrevCheckOuts.PeriodTo) AS CheckOutDate
	|				FROM
	|					AccumulationRegister.RoomInventory AS PrevCheckOuts
	|				WHERE
	|					PrevCheckOuts.IsAccommodation
	|					AND PrevCheckOuts.RecordType = VALUE(AccumulationRecordType.Expense)
	|					AND PrevCheckOuts.Guest <> &qEmptyClient
	|					AND PrevCheckOuts.IsCheckOut
	|					AND PrevCheckOuts.PeriodTo >= &qPeriodFrom
	|					AND PrevCheckOuts.PeriodTo < &qPeriodTo
	|					AND PrevCheckOuts.Hotel IN HIERARCHY(&qHotel)
	|				
	|				GROUP BY
	|					PrevCheckOuts.Guest) AS GuestLastCheckOut
	|				ON SameDayCheckInAccommodations.Guest = GuestLastCheckOut.Guest
	|					AND SameDayCheckInAccommodations.CheckOutDate <> GuestLastCheckOut.CheckOutDate
	|					AND (BEGINOFPERIOD(SameDayCheckInAccommodations.CheckInDate, DAY) = BEGINOFPERIOD(GuestLastCheckOut.CheckOutDate, DAY))
	|		WHERE
	|			SameDayCheckInAccommodations.IsAccommodation
	|			AND SameDayCheckInAccommodations.RecordType = VALUE(AccumulationRecordType.Expense)
	|			AND SameDayCheckInAccommodations.Guest <> &qEmptyClient
	|			AND SameDayCheckInAccommodations.IsCheckIn
	|			AND SameDayCheckInAccommodations.CheckInDate >= &qPeriodFrom
	|			AND SameDayCheckInAccommodations.CheckInDate < &qPeriodTo
	|			AND SameDayCheckInAccommodations.Hotel IN HIERARCHY(&qHotel)
	|			AND SameDayCheckInAccommodations.Room IN HIERARCHY(&qRoom)
	|			AND SameDayCheckInAccommodations.RoomType IN HIERARCHY(&qRoomType)
	|			AND (SameDayCheckInAccommodations.IsInHouse
	|					OR NOT &qShowInHouseOnly)
	|			AND (NOT SameDayCheckInAccommodations.IsInHouse
	|					OR NOT &qShowNotInHouseOnly)
	|			AND (ISNULL(SameDayCheckInAccommodations.Guest.Citizenship, VALUE(Catalog.Countries.EmptyRef)) <> SameDayCheckInAccommodations.Hotel.Citizenship
	|						AND &qShowForeignersOnly
	|					OR NOT &qShowForeignersOnly)) AS ChangedAccommodations
	|			LEFT JOIN InformationRegister.AccommodationForeignerRegistryRecords.SliceLast(&qEndOfTime, ) AS ForeignerRegistryRecords
	|			ON ChangedAccommodations.Recorder = ForeignerRegistryRecords.Accommodation
	|	
	|	GROUP BY
	|		ChangedAccommodations.Recorder,
	|		ForeignerRegistryRecords.ForeignerRegistryRecord,
	|		ChangedAccommodations.FirstStateCheckInDate,
	|		ChangedAccommodations.FirstStateDuration,
	|		ChangedAccommodations.FirstStateCheckOutDate,
	|		ChangedAccommodations.FirstStateRoom) AS RoomInventory
	|{WHERE
	|	RoomInventory.Recorder.* AS Recorder,
	|	RoomInventory.ForeignerRegistryRecord.* AS ForeignerRegistryRecord,
	|	RoomInventory.Recorder.Hotel.* AS Hotel,
	|	RoomInventory.Recorder.RoomType.* AS RoomType,
	|	RoomInventory.Recorder.Room.* AS Room,
	|	RoomInventory.Recorder.Customer.* AS Customer,
	|	RoomInventory.Recorder.CustomerType AS CustomerType,
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
	|	RoomInventory.FirstStateRoom.* AS FirstStateRoom,
	|	RoomInventory.FirstStateCheckInDate AS FirstStateCheckInDate,
	|	RoomInventory.FirstStateDuration AS FirstStateDuration,
	|	RoomInventory.FirstStateCheckOutDate AS FirstStateCheckOutDate,
	|	RoomInventory.Recorder.NumberOfPersons AS InHouseGuests,
	|	RoomInventory.Recorder.NumberOfRooms AS InHouseRooms,
	|	RoomInventory.Recorder.NumberOfBeds AS InHouseBeds,
	|	RoomInventory.Recorder.NumberOfAdditionalBeds AS InHouseAdditionalBeds,
	|	RoomInventory.Recorder.RoomQuota.* AS RoomQuota,
	|	RoomInventory.Recorder.ClientType.* AS ClientType,
	|	RoomInventory.Recorder.Guest.* AS Guest,
	|	RoomInventory.Recorder.MarketingCode.* AS MarketingCode,
	|	RoomInventory.Recorder.TripPurpose.* AS TripPurpose,
	|	RoomInventory.Recorder.SourceOfBusiness.* AS SourceOfBusiness,
	|	RoomInventory.Recorder.RoomRateType.* AS RoomRateType,
	|	RoomInventory.Recorder.RoomRate.* AS RoomRate,
	|	RoomInventory.Recorder.PricePresentation AS PricePresentation,
	|	RoomInventory.Recorder.DiscountCard.* AS DiscountCard,
	|	RoomInventory.Recorder.DiscountType.* AS DiscountType,
	|	RoomInventory.Recorder.Discount AS Discount,
	|	RoomInventory.Recorder.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	RoomInventory.Recorder.Car AS Car,
	|	RoomInventory.Recorder.Remarks AS Remarks,
	|	RoomInventory.Recorder.Author.* AS Author,
	|	RoomInventory.Recorder.AgentCommission AS AgentCommission,
	|	RoomInventory.Recorder.AgentCommissionType.* AS AgentCommissionType,
	|	RoomInventory.Recorder.IsMaster AS IsMaster,
	|	(CASE
	|			WHEN RoomInventory.ForeignerRegistryRecord.MigrationCardDateTo <> &qEmptyDate
	|				THEN DATEDIFF(RoomInventory.ForeignerRegistryRecord.MigrationCardDateTo, RoomInventory.Recorder.CheckOutDate, DAY)
	|			ELSE 0
	|		END) AS MigrationCardDateToDeviance,
	|	(CASE
	|			WHEN RoomInventory.ForeignerRegistryRecord.VisaToDate <> &qEmptyDate
	|				THEN DATEDIFF(RoomInventory.ForeignerRegistryRecord.VisaToDate, RoomInventory.Recorder.CheckOutDate, DAY)
	|			ELSE 0
	|		END) AS VisaToDateDeviance,
	|	RoomInventory.Recorder.AccommodationStatus.IsCheckIn AS IsCheckIn,
	|	RoomInventory.Recorder.AccommodationStatus.IsCheckOut AS IsCheckOut,
	|	RoomInventory.Recorder.AccommodationStatus.IsRoomChange AS IsRoomChange,
	|	RoomInventory.Recorder.AccommodationStatus.IsInHouse AS IsInHouse,
	|	(CASE
	|			WHEN RoomInventory.FirstStateDuration < RoomInventory.Recorder.Duration
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS PeriodOfStayExtension,
	|	(CASE
	|			WHEN RoomInventory.FirstStateDuration > RoomInventory.Recorder.Duration
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS PeriodOfStayShortage}
	|
	|ORDER BY
	|	Hotel,
	|	Room,
	|	CheckInDate,
	|	Guest
	|{ORDER BY
	|	RoomInventory.Recorder.* AS Recorder,
	|	RoomInventory.ForeignerRegistryRecord.* AS ForeignerRegistryRecord,
	|	Customer.* AS Customer,
	|	RoomInventory.Recorder.CustomerType.* AS CustomerType,
	|	RoomInventory.Recorder.Contract.* AS Contract,
	|	RoomInventory.Recorder.Agent.* AS Agent,
	|	GuestGroup.* AS GuestGroup,
	|	Guest.* AS Guest,
	|	RoomInventory.Recorder.MarketingCode.* AS MarketingCode,
	|	RoomInventory.Recorder.TripPurpose.* AS TripPurpose,
	|	RoomInventory.Recorder.SourceOfBusiness.* AS SourceOfBusiness,
	|	RoomRate.* AS RoomRate,
	|	RoomInventory.Recorder.RoomRateType.* AS RoomRateType,
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
	|	RoomInventory.Recorder.RoomRateType.* AS RoomRateType,
	|	RoomRate.* AS RoomRate,
	|	PricePresentation AS PricePresentation,
	|	RoomInventory.Recorder.Author.* AS Author,
	|	FirstStateRoom.* AS FirstStateRoom,
	|	FirstStateCheckInDate AS FirstStateCheckInDate,
	|	FirstStateDuration AS FirstStateDuration,
	|	FirstStateCheckOutDate AS FirstStateCheckOutDate,
	|	InHouseGuests AS InHouseGuests,
	|	InHouseRooms AS InHouseRooms,
	|	InHouseBeds AS InHouseBeds,
	|	InHouseAdditionalBeds AS InHouseAdditionalBeds,
	|	RoomInventory.Recorder.RoomQuota.* AS RoomQuota}
	|TOTALS
	|	SUM(InHouseGuests),
	|	SUM(InHouseRooms),
	|	SUM(InHouseBeds),
	|	SUM(InHouseAdditionalBeds)
	|BY
	|	OVERALL,
	|	Hotel,
	|	Room
	|{TOTALS BY
	|	Hotel.* AS Hotel,
	|	RoomType.* AS RoomType,
	|	Room.* AS Room,
	|	Customer.* AS Customer,
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
	|	RoomRate.* AS RoomRate,
	|	PricePresentation AS PricePresentation,
	|	FirstStateRoom.* AS FirstStateRoom,
	|	RoomInventory.Recorder.DiscountCard.* AS DiscountCard,
	|	RoomInventory.Recorder.DiscountType.* AS DiscountType,
	|	RoomInventory.Recorder.Author.* AS Author,
	|	RoomInventory.Recorder.* AS Recorder,
	|	RoomInventory.ForeignerRegistryRecord.* AS ForeignerRegistryRecord,
	|	RoomInventory.Recorder.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	(CASE
	|			WHEN RoomInventory.FirstStateDuration < RoomInventory.Recorder.Duration
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS PeriodOfStayExtension,
	|	(CASE
	|			WHEN RoomInventory.FirstStateDuration > RoomInventory.Recorder.Duration
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS PeriodOfStayShortage}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='List of changed accommodations';RU='Список измененных размещений';de='Liste der veränderten Unterbringungen'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
