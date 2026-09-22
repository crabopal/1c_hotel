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
	If Not ValueIsFilled(PeriodTo) Then
		PeriodTo = CurrentSessionDate(); // Today
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetReportParametersPresentation() Export
	vParamPresentation = "";
	If Not ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("en='Report period is not set';ru='Период отчета не установлен';de='Berichtszeitraum nicht festgelegt'") + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("ru = 'Дата '; en = 'Date '; de = 'Datum '") + 
		                     Format(PeriodTo, "DF='dd.MM.yyyy'") + 
		                     ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(RoomType) Then
		If Not RoomType.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Room type ';ru='Тип номера ';de='Zimmertyp '") + 
			                     TrimAll(RoomType.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Room types folder ';ru='Группа типов номеров ';de='Gruppe Zimmertyp '") + 
			                     TrimAll(RoomType.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(RoomSection) Then
		If Not RoomSection.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Section ';ru='Секция ';de='Abschnitt '") + 
			                     TrimAll(RoomSection.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Sections folder ';ru='Группа секций ';de='Gruppe Abschnitt '") + 
			                     TrimAll(RoomSection.Description) + 
			                     ";" + Chars.LF;
		EndIf;
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
	If ValueIsFilled(RoomStatus) Then
		If Not RoomStatus.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Status ';ru='Статус ';de='Status '") + 
			                     TrimAll(RoomStatus.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Statuses folder ';ru='Группа статусов ';de='Statusengruppe '") + 
			                     TrimAll(RoomStatus.Description) + 
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
// Runs report and returns if report form should be shown
// -----------------------------------------------------------------------------
Procedure pmGenerate(pSpreadsheet) Export
	Var vTemplateAttributes;
	
	// Generate temporal report value table
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodations.Room AS Room,
	|	Accommodations.Customer AS Customer,
	|	Accommodations.ClientType AS ClientType,
	|	Accommodations.AccommodationTemplate AS AccommodationTemplate,
	|	Accommodations.Ref AS Document,
	|	CAST(Accommodations.Remarks AS STRING(999)) AS ReceptionRemarks,
	|	CAST(Accommodations.HousekeepingRemarks AS STRING(999)) AS HousekeepingRemarks,
	|	&qInHouseClause AS Clause,
	|	SUM(Accommodations.NumberOfAdults + Accommodations.NumberOfTeenagers + Accommodations.NumberOfChildren + Accommodations.NumberOfInfants) AS NumberOfGuests,
	|	SUM(Accommodations.NumberOfAdults) AS NumberOfAdults,
	|	SUM(Accommodations.NumberOfTeenagers) AS NumberOfTeenagers,
	|	SUM(Accommodations.NumberOfChildren) AS NumberOfChildren,
	|	SUM(Accommodations.NumberOfInfants) AS NumberOfInfants
	|INTO InHouseGuests
	|FROM
	|	Document.Accommodation AS Accommodations
	|WHERE
	|	Accommodations.Posted
	|	AND Accommodations.AccommodationStatus.IsActive
	|	AND Accommodations.AccommodationStatus.IsInHouse
	|	AND (&qHotelIsEmpty
	|			OR NOT &qHotelIsEmpty
	|				AND Accommodations.Hotel IN HIERARCHY (&qHotel))
	|	AND (&qRoomIsEmpty
	|			OR NOT &qRoomIsEmpty
	|				AND Accommodations.Room IN HIERARCHY (&qRoom))
	|	AND (&qRoomTypeIsEmpty
	|			OR NOT &qRoomTypeIsEmpty
	|				AND Accommodations.RoomType IN HIERARCHY (&qRoomType))
	|	AND (&qRoomSectionIsEmpty
	|			OR NOT &qRoomSectionIsEmpty
	|				AND Accommodations.Room.RoomSection IN HIERARCHY (&qRoomSection))
	|	AND Accommodations.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|
	|GROUP BY
	|	Accommodations.Room,
	|	Accommodations.Customer,
	|	Accommodations.ClientType,
	|	Accommodations.AccommodationTemplate,
	|	Accommodations.Ref,
	|	CAST(Accommodations.Remarks AS STRING(999)),
	|	CAST(Accommodations.HousekeepingRemarks AS STRING(999))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Reservations.Room AS Room,
	|	Reservations.Customer AS Customer,
	|	Reservations.ClientType AS ClientType,
	|	Reservations.AccommodationTemplate AS AccommodationTemplate,
	|	Reservations.Ref AS Document,
	|	CAST(Reservations.Remarks AS STRING(999)) AS ReceptionRemarks,
	|	CAST(Reservations.HousekeepingRemarks AS STRING(999)) AS HousekeepingRemarks,
	|	&qExpectedCheckInClause AS Clause,
	|	SUM(Reservations.NumberOfAdults + Reservations.NumberOfTeenagers + Reservations.NumberOfChildren + Reservations.NumberOfInfants) AS NumberOfGuestsOnArrival,
	|	SUM(Reservations.NumberOfAdults) AS NumberOfAdultsOnArrival,
	|	SUM(Reservations.NumberOfTeenagers) AS NumberOfTeenagersOnArrival,
	|	SUM(Reservations.NumberOfChildren) AS NumberOfChildrenOnArrival,
	|	SUM(Reservations.NumberOfInfants) AS NumberOfInfantsOnArrival
	|INTO ExpectedCheckInGuests
	|FROM
	|	Document.Reservation AS Reservations
	|WHERE
	|	Reservations.Posted
	|	AND (Reservations.ReservationStatus.IsActive
	|			OR Reservations.ReservationStatus.IsPreliminary)
	|	AND Reservations.CheckInDate >= &qBegOfPeriod
	|	AND Reservations.CheckInDate <= &qEndOfPeriod
	|	AND Reservations.Room <> VALUE(Catalog.Rooms.EmptyRef)
	|	AND (&qHotelIsEmpty
	|			OR NOT &qHotelIsEmpty
	|				AND Reservations.Hotel IN HIERARCHY (&qHotel))
	|	AND (&qRoomIsEmpty
	|			OR NOT &qRoomIsEmpty
	|				AND Reservations.Room IN HIERARCHY (&qRoom))
	|	AND (&qRoomTypeIsEmpty
	|			OR NOT &qRoomTypeIsEmpty
	|				AND Reservations.RoomType IN HIERARCHY (&qRoomType))
	|	AND (&qRoomSectionIsEmpty
	|			OR NOT &qRoomSectionIsEmpty
	|				AND Reservations.Room.RoomSection IN HIERARCHY (&qRoomSection))
	|	AND Reservations.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|
	|GROUP BY
	|	Reservations.Room,
	|	Reservations.Customer,
	|	Reservations.ClientType,
	|	Reservations.AccommodationTemplate,
	|	Reservations.Ref,
	|	CAST(Reservations.Remarks AS STRING(999)),
	|	CAST(Reservations.HousekeepingRemarks AS STRING(999))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExpectedRoomMove.Room AS ToRoom,
	|	ExpectedRoomMove.Ref.Room AS FromRoom,
	|	ExpectedRoomMove.Ref.Customer AS Customer,
	|	ExpectedRoomMove.Ref.ClientType AS ClientType,
	|	ExpectedRoomMove.Ref.AccommodationTemplate AS AccommodationTemplate,
	|	ExpectedRoomMove.Ref AS Document,
	|	CAST(ExpectedRoomMove.Ref.Remarks AS STRING(999)) AS ReceptionRemarks,
	|	CAST(ExpectedRoomMove.Ref.HousekeepingRemarks AS STRING(999)) AS HousekeepingRemarks,
	|	&qExpectedRoomMoveClause AS Clause,
	|	SUM(ExpectedRoomMove.Ref.NumberOfAdults + ExpectedRoomMove.Ref.NumberOfTeenagers + ExpectedRoomMove.Ref.NumberOfChildren + ExpectedRoomMove.Ref.NumberOfInfants) AS NumberOfGuests,
	|	SUM(ExpectedRoomMove.Ref.NumberOfAdults) AS NumberOfAdults,
	|	SUM(ExpectedRoomMove.Ref.NumberOfTeenagers) AS NumberOfTeenagers,
	|	SUM(ExpectedRoomMove.Ref.NumberOfChildren) AS NumberOfChildren,
	|	SUM(ExpectedRoomMove.Ref.NumberOfInfants) AS NumberOfInfants
	|INTO ExpectedRoomMoveGuests
	|FROM
	|	Document.Accommodation.RoomRates AS ExpectedRoomMove
	|WHERE
	|	ExpectedRoomMove.Ref.Posted
	|	AND ExpectedRoomMove.Ref.AccommodationStatus.IsActive
	|	AND ExpectedRoomMove.Ref.AccommodationStatus.IsInHouse
	|	AND ExpectedRoomMove.Room <> VALUE(Catalog.Rooms.EmptyRef)
	|	AND ExpectedRoomMove.Room <> ExpectedRoomMove.Ref.Room
	|	AND ExpectedRoomMove.AccountingDate = &qBegOfPeriod
	|	AND (&qHotelIsEmpty
	|			OR NOT &qHotelIsEmpty
	|				AND ExpectedRoomMove.Ref.Hotel IN HIERARCHY (&qHotel))
	|	AND (&qRoomIsEmpty
	|			OR NOT &qRoomIsEmpty
	|				AND ExpectedRoomMove.Ref.Room IN HIERARCHY (&qRoom))
	|	AND (&qRoomTypeIsEmpty
	|			OR NOT &qRoomTypeIsEmpty
	|				AND ExpectedRoomMove.Ref.RoomType IN HIERARCHY (&qRoomType))
	|	AND (&qRoomSectionIsEmpty
	|			OR NOT &qRoomSectionIsEmpty
	|				AND ExpectedRoomMove.Ref.Room.RoomSection IN HIERARCHY (&qRoomSection))
	|	AND ExpectedRoomMove.Ref.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|
	|GROUP BY
	|	ExpectedRoomMove.Room,
	|	ExpectedRoomMove.Ref.Room,
	|	ExpectedRoomMove.Ref.Customer,
	|	ExpectedRoomMove.Ref.ClientType,
	|	ExpectedRoomMove.Ref.AccommodationTemplate,
	|	ExpectedRoomMove.Ref,
	|	CAST(ExpectedRoomMove.Ref.Remarks AS STRING(999)),
	|	CAST(ExpectedRoomMove.Ref.HousekeepingRemarks AS STRING(999))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Accommodations.Room AS Room,
	|	Accommodations.Customer AS Customer,
	|	Accommodations.ClientType AS ClientType,
	|	Accommodations.AccommodationTemplate AS AccommodationTemplate,
	|	Accommodations.Ref AS Document,
	|	CAST(Accommodations.Remarks AS STRING(999)) AS ReceptionRemarks,
	|	CAST(Accommodations.HousekeepingRemarks AS STRING(999)) AS HousekeepingRemarks,
	|	&qExpectedCheckOutClause AS Clause,
	|	SUM(Accommodations.NumberOfAdults + Accommodations.NumberOfTeenagers + Accommodations.NumberOfChildren + Accommodations.NumberOfInfants) AS NumberOfCheckOutGuests,
	|	SUM(Accommodations.NumberOfAdults) AS NumberOfCheckOutAdults,
	|	SUM(Accommodations.NumberOfTeenagers) AS NumberOfCheckOutTeenagers,
	|	SUM(Accommodations.NumberOfChildren) AS NumberOfCheckOutChildren,
	|	SUM(Accommodations.NumberOfInfants) AS NumberOfCheckOutInfants
	|INTO ExpectedCheckOutGuests
	|FROM
	|	Document.Accommodation AS Accommodations
	|WHERE
	|	Accommodations.Posted
	|	AND Accommodations.AccommodationStatus.IsActive
	|	AND Accommodations.AccommodationStatus.IsInHouse
	|	AND Accommodations.AccommodationStatus.IsCheckOut
	|	AND Accommodations.CheckOutDate >= &qBegOfPeriod
	|	AND Accommodations.CheckOutDate <= &qEndOfPeriod
	|	AND (&qHotelIsEmpty
	|			OR NOT &qHotelIsEmpty
	|				AND Accommodations.Hotel IN HIERARCHY (&qHotel))
	|	AND (&qRoomIsEmpty
	|			OR NOT &qRoomIsEmpty
	|				AND Accommodations.Room IN HIERARCHY (&qRoom))
	|	AND (&qRoomTypeIsEmpty
	|			OR NOT &qRoomTypeIsEmpty
	|				AND Accommodations.RoomType IN HIERARCHY (&qRoomType))
	|	AND (&qRoomSectionIsEmpty
	|			OR NOT &qRoomSectionIsEmpty
	|				AND Accommodations.Room.RoomSection IN HIERARCHY (&qRoomSection))
	|	AND Accommodations.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|
	|GROUP BY
	|	Accommodations.Room,
	|	Accommodations.Customer,
	|	Accommodations.ClientType,
	|	Accommodations.AccommodationTemplate,
	|	Accommodations.Ref,
	|	CAST(Accommodations.Remarks AS STRING(999)),
	|	CAST(Accommodations.HousekeepingRemarks AS STRING(999))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Accommodations.Room AS Room,
	|	Accommodations.Customer AS Customer,
	|	Accommodations.ClientType AS ClientType,
	|	Accommodations.AccommodationTemplate AS AccommodationTemplate,
	|	Accommodations.Ref AS Document,
	|	CAST(Accommodations.Remarks AS STRING(999)) AS ReceptionRemarks,
	|	CAST(Accommodations.HousekeepingRemarks AS STRING(999)) AS HousekeepingRemarks,
	|	&qCheckedOutClause AS Clause,
	|	SUM(Accommodations.NumberOfAdults + Accommodations.NumberOfTeenagers + Accommodations.NumberOfChildren + Accommodations.NumberOfInfants) AS NumberOfCheckedOutGuests,
	|	SUM(Accommodations.NumberOfAdults) AS NumberOfCheckedOutAdults,
	|	SUM(Accommodations.NumberOfTeenagers) AS NumberOfCheckedOutTeenagers,
	|	SUM(Accommodations.NumberOfChildren) AS NumberOfCheckedOutChildren,
	|	SUM(Accommodations.NumberOfInfants) AS NumberOfCheckedOutInfants
	|INTO CheckedOutGuests
	|FROM
	|	Document.Accommodation AS Accommodations
	|WHERE
	|	Accommodations.Posted
	|	AND Accommodations.AccommodationStatus.IsActive
	|	AND NOT Accommodations.AccommodationStatus.IsInHouse
	|	AND Accommodations.AccommodationStatus.IsCheckOut
	|	AND Accommodations.CheckOutDate >= &qBegOfPeriod
	|	AND Accommodations.CheckOutDate <= &qEndOfPeriod
	|	AND (&qHotelIsEmpty
	|			OR NOT &qHotelIsEmpty
	|				AND Accommodations.Hotel IN HIERARCHY (&qHotel))
	|	AND (&qRoomIsEmpty
	|			OR NOT &qRoomIsEmpty
	|				AND Accommodations.Room IN HIERARCHY (&qRoom))
	|	AND (&qRoomTypeIsEmpty
	|			OR NOT &qRoomTypeIsEmpty
	|				AND Accommodations.RoomType IN HIERARCHY (&qRoomType))
	|	AND (&qRoomSectionIsEmpty
	|			OR NOT &qRoomSectionIsEmpty
	|				AND Accommodations.Room.RoomSection IN HIERARCHY (&qRoomSection))
	|	AND Accommodations.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|
	|GROUP BY
	|	Accommodations.Room,
	|	Accommodations.Customer,
	|	Accommodations.ClientType,
	|	Accommodations.AccommodationTemplate,
	|	Accommodations.Ref,
	|	CAST(Accommodations.Remarks AS STRING(999)),
	|	CAST(Accommodations.HousekeepingRemarks AS STRING(999))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Accommodations.Room AS Room,
	|	Accommodations.ClientType AS ClientType,
	|	Accommodations.AccommodationTemplate AS AccommodationTemplate,
	|	Accommodations.Ref AS Document,
	|	CAST(Accommodations.Remarks AS STRING(999)) AS ReceptionRemarks,
	|	CAST(Accommodations.HousekeepingRemarks AS STRING(999)) AS HousekeepingRemarks,
	|	&qCheckedInClause AS Clause,
	|	SUM(Accommodations.NumberOfAdults + Accommodations.NumberOfTeenagers + Accommodations.NumberOfChildren + Accommodations.NumberOfInfants) AS NumberOfCheckedInGuests,
	|	SUM(Accommodations.NumberOfAdults) AS NumberOfCheckedInAdults,
	|	SUM(Accommodations.NumberOfTeenagers) AS NumberOfCheckedInTeenagers,
	|	SUM(Accommodations.NumberOfChildren) AS NumberOfCheckedInChildren,
	|	SUM(Accommodations.NumberOfInfants) AS NumberOfCheckedInInfants
	|INTO CheckedInGuests
	|FROM
	|	Document.Accommodation AS Accommodations
	|WHERE
	|	Accommodations.Posted
	|	AND Accommodations.AccommodationStatus.IsActive
	|	AND Accommodations.AccommodationStatus.IsInHouse
	|	AND Accommodations.AccommodationStatus.IsCheckIn
	|	AND Accommodations.CheckInDate >= &qBegOfPeriod
	|	AND Accommodations.CheckInDate <= &qEndOfPeriod
	|	AND (&qHotelIsEmpty
	|			OR NOT &qHotelIsEmpty
	|				AND Accommodations.Hotel IN HIERARCHY (&qHotel))
	|	AND (&qRoomIsEmpty
	|			OR NOT &qRoomIsEmpty
	|				AND Accommodations.Room IN HIERARCHY (&qRoom))
	|	AND (&qRoomTypeIsEmpty
	|			OR NOT &qRoomTypeIsEmpty
	|				AND Accommodations.RoomType IN HIERARCHY (&qRoomType))
	|	AND (&qRoomSectionIsEmpty
	|			OR NOT &qRoomSectionIsEmpty
	|				AND Accommodations.Room.RoomSection IN HIERARCHY (&qRoomSection))
	|	AND Accommodations.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|
	|GROUP BY
	|	Accommodations.Room,
	|	Accommodations.Customer,
	|	Accommodations.ClientType,
	|	Accommodations.AccommodationTemplate,
	|	Accommodations.Ref,
	|	CAST(Accommodations.Remarks AS STRING(999)),
	|	CAST(Accommodations.HousekeepingRemarks AS STRING(999))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Messages.ByObject AS Room,
	|	CAST(Messages.Remarks AS STRING(999)) AS TaskRemarks
	|INTO RoomTasks
	|FROM
	|	Document.Message AS Messages
	|WHERE
	|	Messages.Posted
	|	AND NOT Messages.IsClosed
	|	AND Messages.ByObject REFS Catalog.Rooms
	|	AND (&qHotelIsEmpty
	|			OR NOT &qHotelIsEmpty
	|				AND Messages.ByObject.Owner IN HIERARCHY (&qHotel))
	|	AND (Messages.ValidFromDate = &qEmptyDate
	|			OR Messages.ValidFromDate <> &qEmptyDate
	|				AND Messages.ValidFromDate <= &qBegOfPeriod)
	|	AND (Messages.ValidToDate = &qEmptyDate
	|			OR Messages.ValidToDate <> &qEmptyDate
	|				AND Messages.ValidToDate > &qBegOfPeriod)
	|
	|GROUP BY
	|	Messages.ByObject,
	|	CAST(Messages.Remarks AS STRING(999))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomBlocks.Room AS Room,
	|	RoomBlocks.RoomBlockType AS RoomBlockType,
	|	RoomBlocks.Number AS BlockNumber,
	|	CAST(RoomBlocks.Remarks AS STRING(999)) AS RoomBlockRemarks
	|INTO RoomBlocks
	|FROM
	|	Document.SetRoomBlock AS RoomBlocks
	|WHERE
	|	RoomBlocks.Posted
	|	AND (&qHotelIsEmpty
	|			OR NOT &qHotelIsEmpty
	|				AND RoomBlocks.Hotel IN HIERARCHY (&qHotel))
	|	AND RoomBlocks.DateFrom <= &qBegOfPeriod
	|	AND (RoomBlocks.DateTo = &qEmptyDate
	|			OR RoomBlocks.DateTo <> &qEmptyDate
	|				AND RoomBlocks.DateTo > &qBegOfPeriod)
	|	AND (&qRoomIsEmpty
	|			OR NOT &qRoomIsEmpty
	|				AND RoomBlocks.Room IN HIERARCHY (&qRoom))
	|	AND (&qRoomTypeIsEmpty
	|			OR NOT &qRoomTypeIsEmpty
	|				AND RoomBlocks.Room.RoomType IN HIERARCHY (&qRoomType))
	|	AND (&qRoomSectionIsEmpty
	|			OR NOT &qRoomSectionIsEmpty
	|				AND RoomBlocks.Room.RoomSection IN HIERARCHY (&qRoomSection))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	RoomsList.Ref AS Room,
	|	RoomsList.RoomType AS RoomType,
	|	RoomsList.RoomType.Code AS RoomTypeCode,
	|	RoomsList.Floor AS Floor,
	|	RoomsList.RoomStatus AS RoomStatus,
	|	RoomsList.RoomStatus.Code AS RoomStatusCode,
	|	ExpectedRoomMoveGuests.FromRoom AS FromRoom,
	|	ExpectedRoomMoveGuests.ToRoom AS ToRoom,
	|	CASE
	|		WHEN ExpectedRoomMoveGuests.ToRoom = RoomsList.Ref
	|			THEN CAST(ISNULL(ExpectedCheckInGuests.NumberOfGuestsOnArrival, 0) + ISNULL(ExpectedRoomMoveGuests.NumberOfGuests, 0) AS NUMBER(10, 0))
	|		ELSE CAST(ISNULL(ExpectedCheckInGuests.NumberOfGuestsOnArrival, 0) AS NUMBER(10, 0))
	|	END AS NumberOfGuestsOnArrival,
	|	CAST(ISNULL(InHouseGuests.NumberOfGuests, 0) AS NUMBER(10, 0)) AS NumberOfInHouseGuests,
	|	CAST(RoomsList.Remarks AS STRING(999)) AS RoomRemarks,
	|	RoomTasks.TaskRemarks AS TaskRemarks,
	|	CASE
	|		WHEN ISNULL(ExpectedCheckInGuests.ReceptionRemarks, """") <> """"
	|			THEN ExpectedCheckInGuests.ReceptionRemarks
	|		WHEN ExpectedRoomMoveGuests.ToRoom = RoomsList.Ref
	|				AND ISNULL(ExpectedRoomMoveGuests.ReceptionRemarks, """") <> """"
	|			THEN ExpectedRoomMoveGuests.ReceptionRemarks
	|		WHEN ISNULL(CheckedInGuests.ReceptionRemarks, """") <> """"
	|			THEN CheckedInGuests.ReceptionRemarks
	|		ELSE """"
	|	END AS ReceptionRemarks,
	|	CASE
	|		WHEN ISNULL(ExpectedCheckInGuests.HousekeepingRemarks, """") <> """"
	|			THEN ExpectedCheckInGuests.HousekeepingRemarks
	|		WHEN ExpectedRoomMoveGuests.ToRoom = RoomsList.Ref
	|				AND ISNULL(ExpectedRoomMoveGuests.HousekeepingRemarks, """") <> """"
	|			THEN ExpectedRoomMoveGuests.HousekeepingRemarks
	|		WHEN ISNULL(CheckedInGuests.HousekeepingRemarks, """") <> """"
	|			THEN CheckedInGuests.HousekeepingRemarks
	|		ELSE """"
	|	END AS HousekeepingRemarks,
	|	CASE
	|		WHEN ISNULL(ExpectedCheckInGuests.Customer, VALUE(Catalog.Customers.EmptyRef)) <> VALUE(Catalog.Customers.EmptyRef)
	|			THEN ExpectedCheckInGuests.Customer
	|		WHEN ExpectedRoomMoveGuests.ToRoom = RoomsList.Ref
	|				AND ISNULL(ExpectedRoomMoveGuests.Customer, VALUE(Catalog.Customers.EmptyRef)) <> VALUE(Catalog.Customers.EmptyRef)
	|			THEN ExpectedRoomMoveGuests.Customer
	|		WHEN ISNULL(InHouseGuests.Customer, VALUE(Catalog.Customers.EmptyRef)) <> VALUE(Catalog.Customers.EmptyRef)
	|			THEN InHouseGuests.Customer
	|		ELSE NULL
	|	END AS Customer,
	|	CASE
	|		WHEN ISNULL(ExpectedCheckInGuests.ClientType, VALUE(Catalog.ClientTypes.EmptyRef)) <> VALUE(Catalog.ClientTypes.EmptyRef)
	|			THEN ExpectedCheckInGuests.ClientType
	|		WHEN ExpectedRoomMoveGuests.ToRoom = RoomsList.Ref
	|				AND ISNULL(ExpectedRoomMoveGuests.ClientType, VALUE(Catalog.ClientTypes.EmptyRef)) <> VALUE(Catalog.ClientTypes.EmptyRef)
	|			THEN ExpectedRoomMoveGuests.ClientType
	|		WHEN ISNULL(InHouseGuests.ClientType, VALUE(Catalog.ClientTypes.EmptyRef)) <> VALUE(Catalog.ClientTypes.EmptyRef)
	|			THEN InHouseGuests.ClientType
	|		ELSE NULL
	|	END AS ClientType,
	|	CASE
	|		WHEN ISNULL(ExpectedCheckInGuests.ClientType, VALUE(Catalog.ClientTypes.EmptyRef)) <> VALUE(Catalog.ClientTypes.EmptyRef)
	|			THEN ExpectedCheckInGuests.ClientType.Description
	|		WHEN ExpectedRoomMoveGuests.ToRoom = RoomsList.Ref
	|				AND ISNULL(ExpectedRoomMoveGuests.ClientType, VALUE(Catalog.ClientTypes.EmptyRef)) <> VALUE(Catalog.ClientTypes.EmptyRef)
	|			THEN ExpectedRoomMoveGuests.ClientType.Description
	|		WHEN ISNULL(InHouseGuests.ClientType, VALUE(Catalog.ClientTypes.EmptyRef)) <> VALUE(Catalog.ClientTypes.EmptyRef)
	|			THEN InHouseGuests.ClientType.Description
	|		ELSE NULL
	|	END AS ClientTypeDescription,
	|	CASE
	|		WHEN NOT ExpectedCheckInGuests.Document IS NULL
	|			THEN ExpectedCheckInGuests.Document
	|		WHEN ExpectedRoomMoveGuests.ToRoom = RoomsList.Ref
	|				AND NOT ExpectedRoomMoveGuests.Document IS NULL
	|			THEN ExpectedRoomMoveGuests.Document
	|		WHEN NOT InHouseGuests.Document IS NULL
	|			THEN InHouseGuests.Document
	|		ELSE NULL
	|	END AS Document,
	|	CASE
	|		WHEN NOT ExpectedCheckInGuests.Document IS NULL
	|			THEN ExpectedCheckInGuests.Document.GuestFullName
	|		WHEN ExpectedRoomMoveGuests.ToRoom = RoomsList.Ref
	|				AND NOT ExpectedRoomMoveGuests.Document IS NULL
	|			THEN ExpectedRoomMoveGuests.Document.GuestFullName
	|		WHEN NOT InHouseGuests.Document IS NULL
	|			THEN InHouseGuests.Document.GuestFullName
	|		ELSE NULL
	|	END AS DocumentGuestFullName,
	|	CASE
	|		WHEN NOT ExpectedCheckInGuests.Document IS NULL
	|			THEN ExpectedCheckInGuests.Document.CheckInDate
	|		WHEN ExpectedRoomMoveGuests.ToRoom = RoomsList.Ref
	|				AND NOT ExpectedRoomMoveGuests.Document IS NULL
	|			THEN ExpectedRoomMoveGuests.Document.CheckInDate
	|		WHEN NOT InHouseGuests.Document IS NULL
	|			THEN InHouseGuests.Document.CheckInDate
	|		ELSE NULL
	|	END AS DocumentCheckInDate,
	|	CASE
	|		WHEN NOT ExpectedCheckInGuests.Document IS NULL
	|			THEN ExpectedCheckInGuests.Document.CheckOutDate
	|		WHEN ExpectedRoomMoveGuests.ToRoom = RoomsList.Ref
	|				AND NOT ExpectedRoomMoveGuests.Document IS NULL
	|			THEN ExpectedRoomMoveGuests.Document.CheckOutDate
	|		WHEN NOT InHouseGuests.Document IS NULL
	|			THEN InHouseGuests.Document.CheckOutDate
	|		ELSE NULL
	|	END AS DocumentCheckOutDate,
	|	CASE
	|		WHEN NOT ExpectedCheckInGuests.Document IS NULL
	|			THEN ExpectedCheckInGuests.Document.Duration
	|		WHEN ExpectedRoomMoveGuests.ToRoom = RoomsList.Ref
	|				AND NOT ExpectedRoomMoveGuests.Document IS NULL
	|			THEN ExpectedRoomMoveGuests.Document.Duration
	|		WHEN NOT InHouseGuests.Document IS NULL
	|			THEN InHouseGuests.Document.Duration
	|		ELSE NULL
	|	END AS DocumentDuration,
	|	CASE
	|		WHEN NOT ExpectedCheckInGuests.Document IS NULL
	|			THEN ExpectedCheckInGuests.Document.GuestGroup
	|		WHEN ExpectedRoomMoveGuests.ToRoom = RoomsList.Ref
	|				AND NOT ExpectedRoomMoveGuests.Document IS NULL
	|			THEN ExpectedRoomMoveGuests.Document.GuestGroup
	|		WHEN NOT InHouseGuests.Document IS NULL
	|			THEN InHouseGuests.Document.GuestGroup
	|		ELSE NULL
	|	END AS DocumentGuestGroup,
	|	CASE
	|		WHEN NOT ExpectedCheckInGuests.Document IS NULL
	|			THEN ExpectedCheckInGuests.Document.GuestGroup.Description
	|		WHEN ExpectedRoomMoveGuests.ToRoom = RoomsList.Ref
	|				AND NOT ExpectedRoomMoveGuests.Document IS NULL
	|			THEN ExpectedRoomMoveGuests.Document.GuestGroup.Description
	|		WHEN NOT InHouseGuests.Document IS NULL
	|			THEN InHouseGuests.Document.GuestGroup.Description
	|		ELSE NULL
	|	END AS DocumentGuestGroupDescription,
	|	CASE
	|		WHEN NOT ExpectedCheckInGuests.Document IS NULL
	|			THEN ExpectedCheckInGuests.Clause
	|		WHEN ExpectedRoomMoveGuests.ToRoom = RoomsList.Ref
	|				AND NOT ExpectedRoomMoveGuests.Document IS NULL
	|			THEN ExpectedRoomMoveGuests.Clause
	|		WHEN NOT InHouseGuests.Document IS NULL
	|			THEN InHouseGuests.Clause
	|		ELSE NULL
	|	END AS DocumentClause,
	|	CASE
	|		WHEN NOT ExpectedCheckInGuests.AccommodationTemplate IS NULL
	|			THEN ExpectedCheckInGuests.AccommodationTemplate
	|		WHEN ExpectedRoomMoveGuests.ToRoom = RoomsList.Ref
	|				AND NOT ExpectedRoomMoveGuests.Document IS NULL
	|			THEN ExpectedRoomMoveGuests.AccommodationTemplate
	|		WHEN NOT InHouseGuests.Document IS NULL
	|			THEN InHouseGuests.AccommodationTemplate
	|		ELSE NULL
	|	END AS AccommodationTemplate,
	|	CASE
	|		WHEN NOT ExpectedCheckInGuests.AccommodationTemplate IS NULL
	|			THEN ExpectedCheckInGuests.NumberOfGuestsOnArrival
	|		WHEN ExpectedRoomMoveGuests.ToRoom = RoomsList.Ref
	|				AND NOT ExpectedRoomMoveGuests.Document IS NULL
	|			THEN ExpectedRoomMoveGuests.NumberOfGuests
	|		WHEN NOT InHouseGuests.Document IS NULL
	|			THEN InHouseGuests.NumberOfGuests
	|		ELSE NULL
	|	END AS NumberOfPersons,
	|	CASE
	|		WHEN NOT ExpectedCheckInGuests.AccommodationTemplate IS NULL
	|			THEN ExpectedCheckInGuests.NumberOfAdultsOnArrival
	|		WHEN ExpectedRoomMoveGuests.ToRoom = RoomsList.Ref
	|				AND NOT ExpectedRoomMoveGuests.Document IS NULL
	|			THEN ExpectedRoomMoveGuests.NumberOfAdults
	|		WHEN NOT InHouseGuests.Document IS NULL
	|			THEN InHouseGuests.NumberOfAdults
	|		ELSE NULL
	|	END AS NumberOfAdults,
	|	CASE
	|		WHEN NOT ExpectedCheckInGuests.AccommodationTemplate IS NULL
	|			THEN ExpectedCheckInGuests.NumberOfTeenagersOnArrival
	|		WHEN ExpectedRoomMoveGuests.ToRoom = RoomsList.Ref
	|				AND NOT ExpectedRoomMoveGuests.Document IS NULL
	|			THEN ExpectedRoomMoveGuests.NumberOfTeenagers
	|		WHEN NOT InHouseGuests.Document IS NULL
	|			THEN InHouseGuests.NumberOfTeenagers
	|		ELSE NULL
	|	END AS NumberOfTeenagers,
	|	CASE
	|		WHEN NOT ExpectedCheckInGuests.AccommodationTemplate IS NULL
	|			THEN ExpectedCheckInGuests.NumberOfChildrenOnArrival
	|		WHEN ExpectedRoomMoveGuests.ToRoom = RoomsList.Ref
	|				AND NOT ExpectedRoomMoveGuests.Document IS NULL
	|			THEN ExpectedRoomMoveGuests.NumberOfChildren
	|		WHEN NOT InHouseGuests.Document IS NULL
	|			THEN InHouseGuests.NumberOfChildren
	|		ELSE NULL
	|	END AS NumberOfChildren,
	|	CASE
	|		WHEN NOT ExpectedCheckInGuests.AccommodationTemplate IS NULL
	|			THEN ExpectedCheckInGuests.NumberOfInfantsOnArrival
	|		WHEN ExpectedRoomMoveGuests.ToRoom = RoomsList.Ref
	|				AND NOT ExpectedRoomMoveGuests.Document IS NULL
	|			THEN ExpectedRoomMoveGuests.NumberOfInfants
	|		WHEN NOT InHouseGuests.Document IS NULL
	|			THEN InHouseGuests.NumberOfInfants
	|		ELSE NULL
	|	END AS NumberOfInfants,
	|	RoomBlocks.RoomBlockType AS RoomBlockType,
	|	RoomBlocks.RoomBlockRemarks AS RoomBlockRemarks,
	|	RoomsList.StopSale AS StopSale,
	|	RoomsList.IsVirtual AS IsVirtual,
	|	CAST(RoomsList.RoomPropertiesCodes AS STRING(999)) AS RoomPropertiesCodes,
	|	"""" AS Condition,
	|	RoomsList.HasRoomBlocks AS HasRoomBlocks,
	|	ExpectedCheckInGuests.Clause AS ExpectedCheckInClause,
	|	CheckedInGuests.Clause AS CheckedInClause,
	|	ExpectedRoomMoveGuests.Clause AS ExpectedRoomMoveClause,
	|	InHouseGuests.Clause AS InHouseClause,
	|	ExpectedCheckOutGuests.Clause AS ExpectedCheckOutClause,
	|	CheckedOutGuests.Clause AS CheckedOutClause,
	|	RoomsList.SortCode AS SortCode,
	|	RoomStatusChangeHistory.Period AS RoomStatusLastChangeTime,
	|	CASE
	|		WHEN NOT ExpectedCheckInGuests.Clause IS NULL
	|			THEN 1
	|		ELSE 0
	|	END AS NumberOfExpectedCheckInRooms,
	|	CASE
	|		WHEN NOT CheckedInGuests.Clause IS NULL
	|			THEN 1
	|		ELSE 0
	|	END AS NumberOfCheckedInRooms,
	|	CASE
	|		WHEN NOT ExpectedCheckOutGuests.Clause IS NULL
	|			THEN 1
	|		ELSE 0
	|	END AS NumberOfExpectedCheckOutRooms,
	|	CASE
	|		WHEN NOT CheckedOutGuests.Clause IS NULL
	|			THEN 1
	|		ELSE 0
	|	END AS NumberOfCheckedOutRooms,
	|	CASE
	|		WHEN NOT InHouseGuests.Clause IS NULL
	|			THEN 1
	|		ELSE 0
	|	END AS NumberOfInHouseRooms,
	|	CASE
	|		WHEN NOT ExpectedRoomMoveGuests.Clause IS NULL
	|			THEN 1
	|		ELSE 0
	|	END AS NumberOfExpectedRoomMoveRooms,
	|	CASE
	|		WHEN NOT RoomBlocks.RoomBlockType IS NULL
	|			THEN 1
	|		ELSE 0
	|	END AS NumberOfBlockedRooms
	|FROM
	|	Catalog.Rooms AS RoomsList
	|		LEFT JOIN InformationRegister.RoomStatusChangeHistory.SliceLast(
	|				&qEndOfPeriod,
	|				&qHotelIsEmpty
	|					OR NOT &qHotelIsEmpty
	|						AND Room.Owner IN HIERARCHY (&qHotel)) AS RoomStatusChangeHistory
	|		ON (RoomStatusChangeHistory.Room = RoomsList.Ref)
	|		LEFT JOIN ExpectedCheckInGuests AS ExpectedCheckInGuests
	|		ON (ExpectedCheckInGuests.Room = RoomsList.Ref)
	|		LEFT JOIN CheckedInGuests AS CheckedInGuests
	|		ON (CheckedInGuests.Room = RoomsList.Ref)
	|		LEFT JOIN ExpectedRoomMoveGuests AS ExpectedRoomMoveGuests
	|		ON (ExpectedRoomMoveGuests.ToRoom = RoomsList.Ref
	|				OR ExpectedRoomMoveGuests.FromRoom = RoomsList.Ref)
	|		LEFT JOIN InHouseGuests AS InHouseGuests
	|		ON (InHouseGuests.Room = RoomsList.Ref)
	|		LEFT JOIN ExpectedCheckOutGuests AS ExpectedCheckOutGuests
	|		ON (ExpectedCheckOutGuests.Room = RoomsList.Ref)
	|		LEFT JOIN CheckedOutGuests AS CheckedOutGuests
	|		ON (CheckedOutGuests.Room = RoomsList.Ref)
	|		LEFT JOIN RoomTasks AS RoomTasks
	|		ON (RoomTasks.Room = RoomsList.Ref)
	|		LEFT JOIN RoomBlocks AS RoomBlocks
	|		ON (RoomBlocks.Room = RoomsList.Ref)
	|WHERE
	|	NOT RoomsList.DeletionMark
	|	AND NOT RoomsList.IsFolder
	|	AND RoomsList.OperationStartDate < &qEndOfPeriod
	|	AND (RoomsList.OperationEndDate = DATETIME(1, 1, 1)
	|			OR RoomsList.OperationEndDate > &qBegOfPeriod)
	|	AND (&qHotelIsEmpty
	|			OR NOT &qHotelIsEmpty
	|				AND RoomsList.Owner IN HIERARCHY (&qHotel))
	|	AND (&qRoomIsEmpty
	|			OR NOT &qRoomIsEmpty
	|				AND RoomsList.Ref IN HIERARCHY (&qRoom))
	|	AND (&qRoomTypeIsEmpty
	|			OR NOT &qRoomTypeIsEmpty
	|				AND RoomsList.RoomType IN HIERARCHY (&qRoomType))
	|	AND (&qRoomSectionIsEmpty
	|			OR NOT &qRoomSectionIsEmpty
	|				AND RoomsList.RoomSection IN HIERARCHY (&qRoomSection))
	|	AND (&qRoomStatusIsEmpty
	|			OR NOT &qRoomStatusIsEmpty
	|				AND RoomsList.RoomStatus IN HIERARCHY (&qRoomStatus))
	|
	|ORDER BY
	|	RoomsList.Owner.SortCode,
	|	RoomsList.Owner.Code,
	|	SortCode,
	|	HousekeepingRemarks DESC,
	|	ClientTypeDescription DESC,
	|	NumberOfGuestsOnArrival DESC,
	|	NumberOfInHouseGuests DESC";
	vQry.SetParameter("qBegOfPeriod", BegOfDay(PeriodTo));
	vQry.SetParameter("qEndOfPeriod", EndOfDay(PeriodTo));
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qEmptyFullName", "                                                                                                                                                                                                        ");
	vQry.SetParameter("qEmptyGuestGroupDescription", "                                                                                                    ");
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRoomIsEmpty", Not ValueIsFilled(Room));
	vQry.SetParameter("qRoom", Room);
	vQry.SetParameter("qRoomTypeIsEmpty", Not ValueIsFilled(RoomType));
	vQry.SetParameter("qRoomType", RoomType);
	vQry.SetParameter("qRoomSectionIsEmpty", Not ValueIsFilled(RoomSection));
	vQry.SetParameter("qRoomSection", RoomSection);
	vQry.SetParameter("qRoomStatusIsEmpty", Not ValueIsFilled(RoomStatus));
	vQry.SetParameter("qRoomStatus", RoomStatus);
	vQry.SetParameter("qExpectedCheckInClause", NStr("en='Arrival today'; ru='На заезде'; de='Anreise heute'"));
	vQry.SetParameter("qCheckedInClause", NStr("en='Checked-in'; ru='Заехал'; de='Checked-in'"));
	vQry.SetParameter("qInHouseClause", NStr("en='In house'; ru='Занят'; de='In house'"));
	vQry.SetParameter("qExpectedCheckOutClause", NStr("en='Departure today'; ru='На выезде'; de='Abreise heute'"));
	vQry.SetParameter("qCheckedOutClause", NStr("en='Checked-out'; ru='Выехал'; de='Checked-out'"));
	vQry.SetParameter("qExpectedRoomMoveClause", NStr("en='Moving'; ru='Переселение'; de='Umzug'"));
	vWrkRooms = vQry.Execute().Unload();
	
	vVacantClause = NStr("en='Vacant'; ru='Свободен'; de='Leer'");
	
	// Initialize table of rooms as a seed for the main report query
	//vRooms = vWrkRooms.Copy(, "Room, RoomTypeCode, RoomStatus, TaskRemarks, HasRoomBlocks, AccommodationTemplate, NumberOfAdults, NumberOfChildren, NumberOfInfants, RoomStatusLastChangeTime");
	vRooms = vWrkRooms.Copy();
	vRooms.Clear();
	vRooms.Columns.Delete("Condition");
	vRooms.Columns.Insert(3, "Condition", cmGetStringTypeDescription());
	vRooms.Columns.Insert(4, "Remarks", cmGetStringTypeDescription());
	
	vNumberOfAdults = 0;
	vNumberOfTeenagers = 0;
	vNumberOfChildren = 0;
	vNumberOfInfants = 0;
	
	vNumberOfExpectedCheckInRooms = 0;
	vNumberOfCheckedInRooms = 0;
	vNumberOfExpectedCheckOutRooms = 0;
	vNumberOfCheckedOutRooms = 0;
	vNumberOfInHouseRooms = 0;
	vNumberOfExpectedRoomMoveRooms = 0;
	vNumberOfBlockedRooms = 0;
	
	vCurRoom = Undefined;
	vCurRoomItem = Undefined;
	For Each vRoomsRow In vWrkRooms Do
		If Not ValueIsFilled(vRoomsRow.Room) Then
			Continue;
		EndIf;
		vDoAddRoom = True;
		If vCurRoom = vRoomsRow.Room Then
			vDoAddRoom = False;
		EndIf;
		vCurRoom = vRoomsRow.Room;
		If vDoAddRoom Then
			vCurRoomItem = vRooms.Add();
			FillPropertyValues(vCurRoomItem, vRoomsRow, , "Condition");
			
			vNumberOfAdults = vNumberOfAdults + ?(vRoomsRow.NumberOfAdults = Null, 0, vRoomsRow.NumberOfAdults);
			vNumberOfTeenagers = vNumberOfTeenagers + ?(vRoomsRow.NumberOfTeenagers = Null, 0, vRoomsRow.NumberOfTeenagers);
			vNumberOfChildren = vNumberOfChildren + ?(vRoomsRow.NumberOfChildren = Null, 0, vRoomsRow.NumberOfChildren);
			vNumberOfInfants = vNumberOfInfants + ?(vRoomsRow.NumberOfInfants = Null, 0, vRoomsRow.NumberOfInfants);
			
			vNumberOfExpectedCheckInRooms = vNumberOfExpectedCheckInRooms + vRoomsRow.NumberOfExpectedCheckInRooms;
			vNumberOfCheckedInRooms = vNumberOfCheckedInRooms + vRoomsRow.NumberOfCheckedInRooms;
			vNumberOfExpectedCheckOutRooms = vNumberOfExpectedCheckOutRooms + vRoomsRow.NumberOfExpectedCheckOutRooms;
			vNumberOfCheckedOutRooms = vNumberOfCheckedOutRooms + vRoomsRow.NumberOfCheckedOutRooms;
			vNumberOfInHouseRooms = vNumberOfInHouseRooms + vRoomsRow.NumberOfInHouseRooms;
			vNumberOfExpectedRoomMoveRooms = vNumberOfExpectedRoomMoveRooms + vRoomsRow.NumberOfExpectedRoomMoveRooms;
			vNumberOfBlockedRooms = vNumberOfBlockedRooms + vRoomsRow.NumberOfBlockedRooms;
		EndIf;
		If Not IsBlankString(vRoomsRow.ClientTypeDescription) Then
			If StrFind(vCurRoomItem.Remarks, vRoomsRow.ClientTypeDescription) = 0 Then
				vCurRoomItem.Remarks = TrimAll(vCurRoomItem.Remarks) + ?(IsBlankString(vCurRoomItem.Remarks), "", Chars.LF) + vRoomsRow.ClientTypeDescription;
			EndIf;
		EndIf;
		If ValueIsFilled(vRoomsRow.AccommodationTemplate) Then
			If StrFind(vCurRoomItem.Remarks, TrimAll(vRoomsRow.AccommodationTemplate)) = 0 Then
				vCurRoomItem.Remarks = TrimAll(vCurRoomItem.Remarks) + ?(IsBlankString(vCurRoomItem.Remarks), "", Chars.LF) + TrimAll(vRoomsRow.AccommodationTemplate);
			EndIf;
		EndIf;
		If Not IsBlankString(vRoomsRow.HousekeepingRemarks) Then
			If StrFind(vCurRoomItem.Remarks, vRoomsRow.HousekeepingRemarks) = 0 Then
				vCurRoomItem.Remarks = TrimAll(vCurRoomItem.Remarks) + ?(IsBlankString(vCurRoomItem.Remarks), "", Chars.LF) + vRoomsRow.HousekeepingRemarks;
			EndIf;
		EndIf;
		If Not IsBlankString(vRoomsRow.ReceptionRemarks) Then
			If StrFind(vCurRoomItem.Remarks, vRoomsRow.ReceptionRemarks) = 0 Then
				vCurRoomItem.Remarks = TrimAll(vCurRoomItem.Remarks) + ?(IsBlankString(vCurRoomItem.Remarks), "", Chars.LF) + vRoomsRow.ReceptionRemarks;
			EndIf;
		EndIf;
		If Not IsBlankString(vRoomsRow.RoomBlockRemarks) Then
			If StrFind(vCurRoomItem.Remarks, vRoomsRow.RoomBlockRemarks) = 0 Then
				vCurRoomItem.Remarks = TrimAll(vCurRoomItem.Remarks) + ?(IsBlankString(vCurRoomItem.Remarks), "", Chars.LF) + vRoomsRow.RoomBlockRemarks;
			EndIf;
		EndIf;
		vIsVacant = True;
		If Not IsBlankString(vRoomsRow.ExpectedCheckOutClause) Then
			If StrFind(vCurRoomItem.Condition, vRoomsRow.ExpectedCheckOutClause) = 0 Then
				vCurRoomItem.Condition = TrimAll(vCurRoomItem.Condition) + ?(IsBlankString(vCurRoomItem.Condition), "", ", ") + vRoomsRow.ExpectedCheckOutClause;
			EndIf;
			vIsVacant = False;
		EndIf;
		If Not IsBlankString(vRoomsRow.ExpectedCheckInClause) Then
			If StrFind(vCurRoomItem.Condition, vRoomsRow.ExpectedCheckInClause) = 0 Then
				vCurRoomItem.Condition = TrimAll(vCurRoomItem.Condition) + ?(IsBlankString(vCurRoomItem.Condition), "", ", ") + vRoomsRow.ExpectedCheckInClause;
			EndIf;
			vIsVacant = False;
		EndIf;
		If Not IsBlankString(vRoomsRow.ExpectedRoomMoveClause) Then
			If StrFind(vCurRoomItem.Condition, vRoomsRow.ExpectedRoomMoveClause) = 0 Then
				If vRoomsRow.Room = vRoomsRow.ToRoom Then
					vCurRoomItem.Condition = TrimAll(vCurRoomItem.Condition) + ?(IsBlankString(vCurRoomItem.Condition), "", ", ") + vRoomsRow.ExpectedRoomMoveClause + NStr("en=' in from room '; ru=' из номера '; de=' vom Zimmer '") + TrimAll(vRoomsRow.FromRoom);
				ElsIf vRoomsRow.Room = vRoomsRow.FromRoom Then
					vCurRoomItem.Condition = TrimAll(vCurRoomItem.Condition) + ?(IsBlankString(vCurRoomItem.Condition), "", ", ") + vRoomsRow.ExpectedRoomMoveClause + NStr("en=' out to room '; ru=' в номер '; de=' ins Zimmer '") + TrimAll(vRoomsRow.ToRoom);
				EndIf;
			EndIf;
			vIsVacant = False;
		EndIf;
		If Not IsBlankString(vRoomsRow.InHouseClause) And IsBlankString(vRoomsRow.CheckedInClause) And IsBlankString(vRoomsRow.ExpectedCheckOutClause) Then
			If StrFind(vCurRoomItem.Condition, vRoomsRow.InHouseClause) = 0 Then
				vCurRoomItem.Condition = TrimAll(vCurRoomItem.Condition) + ?(IsBlankString(vCurRoomItem.Condition), "", ", ") + vRoomsRow.InHouseClause;
			EndIf;
			vIsVacant = False;
		EndIf;
		If Not IsBlankString(vRoomsRow.CheckedOutClause) Then
			If StrFind(vCurRoomItem.Condition, vRoomsRow.CheckedOutClause) = 0 Then
				vCurRoomItem.Condition = TrimAll(vCurRoomItem.Condition) + ?(IsBlankString(vCurRoomItem.Condition), "", ", ") + vRoomsRow.CheckedOutClause;
			EndIf;
			vIsVacant = False;
		EndIf;
		If Not IsBlankString(vRoomsRow.CheckedInClause) Then
			If StrFind(vCurRoomItem.Condition, vRoomsRow.CheckedInClause) = 0 Then
				vCurRoomItem.Condition = TrimAll(vCurRoomItem.Condition) + ?(IsBlankString(vCurRoomItem.Condition), "", ", ") + vRoomsRow.CheckedInClause;
			EndIf;
			vIsVacant = False;
		EndIf;
		If ValueIsFilled(vRoomsRow.RoomBlockType) Then
			If StrFind(vCurRoomItem.Condition, TrimAll(vRoomsRow.RoomBlockType)) = 0 Then
				vCurRoomItem.Condition = TrimAll(vCurRoomItem.Condition) + ?(IsBlankString(vCurRoomItem.Condition), "", ", ") + TrimAll(vRoomsRow.RoomBlockType);
			EndIf;
			vIsVacant = False;
		EndIf;
		If vIsVacant Then
			If StrFind(vCurRoomItem.Condition, vVacantClause) = 0 Then
				vCurRoomItem.Condition = TrimAll(vCurRoomItem.Condition) + ?(IsBlankString(vCurRoomItem.Condition), "", ", ") + vVacantClause;
			EndIf;
		EndIf;
	EndDo;
	vTotalsRow = vRooms.Add();
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
	
	// Initialize report builder query generator attributes
	ReportBuilder.PresentationAdding = PresentationAdditionType.Add;
	
	// Fill report parameters
	ReportBuilder.Parameters.Insert("qEmptyString", "            ");
	ReportBuilder.Parameters.Insert("qEmptyDate", '00010101');
	
	// Leave columns selected for the report only
	i = 0;
	While i < vRooms.Columns.Count() Do
		vColumn = vRooms.Columns.Get(i);
		vField = ReportBuilder.SelectedFields.Find(vColumn.Name);
		If vField = Undefined Then
			vRooms.Columns.Delete(i);
		Else
			i = i + 1;
		EndIf;
	EndDo;
	// Set columns position
	i = 0;
	While i < ReportBuilder.SelectedFields.Count() Do
		vField = ReportBuilder.SelectedFields.Get(i);
		vColumn = vRooms.Columns.Find(vField.Name);
		If vColumn <> Undefined Then
			vPos = vRooms.Columns.IndexOf(vColumn);
			vOffset = i - vPos;
			If (vPos + vOffset) >= vRooms.Columns.Count() Then
				vOffset = vRooms.Columns.Count() - 1 - vPos;
			EndIf;
			vRooms.Columns.Move(vPos, vOffset);
		EndIf;
		i = i + 1;
	EndDo;
	
	// Get columns selected for the report sorting
	vSorting = "";
	For Each vOrderField In ReportBuilder.Order Do
		vSorting = vSorting + ?(IsBlankString(vSorting), "", ", ") + vOrderField.Name;
	EndDo;
	Try
		If Not IsBlankString(vSorting) Then
			vRooms.Sort(vSorting);
		EndIf;
	Except
		vError = cmGetRootErrorDescription(ErrorInfo());
		tcCommonFunctionOnClientServer.TextMessage("Sorting: " + vError);
	EndTry;
	
	// Save report conditional appearance
	vCurReportBuilderSettings = ReportBuilder.GetSettings(True, True, False, True, True);
	
	// Execute report builder query
	ReportBuilder.DataSource = New DataSourceDescription(vRooms);
	
	// Save conditional report settings
	ReportBuilder.SetSettings(vCurReportBuilderSettings, True, True, False, True, True);
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Execute report builder query
	ReportBuilder.Execute();
	
	// Apply appearance settings to the report template
	vTemplateAttributes = cmApplyReportTemplateAppearance(ThisObject);
	
	// Output report to the spreadsheet
	ReportBuilder.Put(pSpreadsheet);
	//ReportBuilder.Template.Show(); // For debug purpose
	
	// Add report totals
	vFooterArea = pSpreadsheet.Area(pSpreadsheet.TableHeight-1, 2, pSpreadsheet.TableHeight-1, 2);
	vFooterArea.Text = NStr("en='Adults: '; ru='Взрослых: '; de='Erwachsenen: '") + vNumberOfAdults + ", " + 
	                   NStr("en='Teens: '; ru='Подростков: '; de='Teens: '") + vNumberOfTeenagers + ", " + 
	                   NStr("en='Children: '; ru='Детей: '; de='Kinder: '") + vNumberOfChildren + ", " + 
	                   NStr("en='Infants: '; ru='Младенцев: '; de='Infants: '") + vNumberOfInfants + Chars.LF + 
					   NStr("en='Rooms: Expected check-in: '; ru='Номеров: На план. заезде: '; de='Zimmeren: Bei geplanter Anreise: '") + vNumberOfExpectedCheckInRooms + ", " + 
					   NStr("en='Checked-in: '; ru='Заехало: '; de='Anreise: '") + vNumberOfCheckedInRooms + ", " + 
					   NStr("en='Expected check-out: '; ru='На план. выезде: '; de='Bei geplanter Abreise: '") + vNumberOfExpectedCheckOutRooms + ", " + 
					   NStr("en='Checked-out: '; ru='Выехало: '; de='Abreise: '") + vNumberOfCheckedOutRooms + Chars.LF + 
					   NStr("en='In-house: '; ru='Проживает: '; de='In-house: '") + vNumberOfInHouseRooms + ", " + 
					   NStr("en='Blocked: '; ru='Заблокировано: '; de='Blockierte: '") + vNumberOfBlockedRooms + ", " + 
					   NStr("en='Expected room move: '; ru='План. переселение: '; de='Geplanter Umzug: '") + vNumberOfExpectedRoomMoveRooms;
	vFooterArea.HorizontalAlign = HorizontalAlign.Left;
	vFooterArea.Font = New Font(vFooterArea.Font, , , True);

	// Apply appearance settings to the report spreadsheet
	cmApplyReportAppearance(ThisObject, pSpreadsheet, vTemplateAttributes);
EndProcedure // pmGenerate

// -----------------------------------------------------------------------------
Procedure pmInitializeReportBuilder() Export
	ReportBuilder = New ReportBuilder();
	
	// Initialize default query text
	QueryText = 
	"SELECT
	|	RoomsData.Owner AS Hotel,
	|	RoomsData.Ref AS Room,
	|	RoomsData.RoomType AS RoomType,
	|	RoomsData.RoomType.Code AS RoomTypeCode,
	|	RoomsData.Floor AS Floor,
	|	RoomsData.RoomStatus AS RoomStatus,
	|	RoomsData.RoomStatus.Code AS RoomStatusCode,
	|	0 AS NumberOfGuestsOnArrival,
	|	0 AS NumberOfInHouseGuests,
	|	&qEmptyDate AS RoomStatusLastChangeTime,
	|	RoomsData.Remarks AS Remarks,
	|	RoomsData.Remarks AS ReceptionRemarks,
	|	RoomsData.Remarks AS RoomRemarks,
	|	RoomsData.Remarks AS TaskRemarks,
	|	RoomsData.Remarks AS HousekeepingRemarks,
	|	VALUE(Catalog.Customers.EmptyRef) AS Customer,
	|	VALUE(Catalog.ClientTypes.EmptyRef) AS ClientType,
	|	VALUE(Catalog.AccommodationTemplates.EmptyRef) AS AccommodationTemplate,
	|	NULL AS Document,
	|	NULL AS DocumentGuestFullName,
	|	NULL AS DocumentCheckInDate,
	|	NULL AS DocumentDuration,
	|	NULL AS DocumentCheckOutDate,
	|	NULL AS DocumentGuestGroup,
	|	NULL AS DocumentGuestGroupDescription,
	|	RoomsData.Remarks AS DocumentClause,
	|	RoomsData.HasRoomBlocks AS HasRoomBlocks,
	|	VALUE(Catalog.RoomBlockTypes.EmptyRef) AS RoomBlockType,
	|	RoomsData.Remarks AS RoomBlockRemarks,
	|	RoomsData.StopSale AS StopSale,
	|	RoomsData.IsVirtual AS IsVirtual,
	|	RoomsData.RoomPropertiesCodes AS RoomPropertiesCodes,
	|	RoomsData.Remarks AS Condition,
	|	RoomsData.Remarks AS ExpectedCheckInClause,
	|	RoomsData.Remarks AS CheckedInClause,
	|	RoomsData.Remarks AS ExpectedRoomMoveClause,
	|	RoomsData.Remarks AS InHouseClause,
	|	RoomsData.Remarks AS ExpectedCheckOutClause,
	|	RoomsData.Remarks AS CheckedOutClause,
	|	RoomsData.SortCode AS SortCode,
	|	1 AS NumberOfRooms,
	|	0 AS NumberOfAdults,
	|	0 AS NumberOfTeenagers,
	|	0 AS NumberOfChildren,
	|	0 AS NumberOfInfants,
	|	0 AS NumberOfPersons,
	|	0 AS NumberOfExpectedCheckInRooms,
	|	0 AS NumberOfCheckedInRooms,
	|	0 AS NumberOfExpectedCheckOutRooms,
	|	0 AS NumberOfCheckedOutRooms,
	|	0 AS NumberOfInHouseRooms,
	|	0 AS NumberOfExpectedRoomMoveRooms,
	|	0 AS NumberOfBlockedRooms
	|{SELECT
	|	Hotel.* AS Hotel,
	|	Room.* AS Room,
	|	RoomType.* AS RoomType,
	|	Floor AS Floor,
	|	RoomStatus.* AS RoomStatus,
	|	NumberOfGuestsOnArrival AS NumberOfGuestsOnArrival,
	|	NumberOfInHouseGuests AS NumberOfInHouseGuests,
	|	RoomStatusLastChangeTime AS RoomStatusLastChangeTime,
	|	Remarks AS Remarks,
	|	ReceptionRemarks AS ReceptionRemarks,
	|	RoomRemarks AS RoomRemarks,
	|	TaskRemarks AS TaskRemarks,
	|	HousekeepingRemarks AS HousekeepingRemarks,
	|	Customer.* AS Customer,
	|	ClientType.* AS ClientType,
	|	Document AS Document,
	|	DocumentGuestFullName AS DocumentGuestFullName,
	|	DocumentCheckInDate AS DocumentCheckInDate,
	|	DocumentDuration AS DocumentDuration,
	|	DocumentCheckOutDate AS DocumentCheckOutDate,
	|	DocumentGuestGroup AS DocumentGuestGroup,
	|	DocumentGuestGroupDescription AS DocumentGuestGroupDescription,
	|	DocumentClause AS DocumentClause,
	|	HasRoomBlocks AS HasRoomBlocks,
	|	RoomBlockType.* AS RoomBlockType,
	|	RoomBlockRemarks AS RoomBlockRemarks,
	|	StopSale AS StopSale,
	|	IsVirtual AS IsVirtual,
	|	RoomPropertiesCodes AS RoomPropertiesCodes,
	|	Condition AS Condition,
	|	ExpectedCheckInClause AS ExpectedCheckInClause,
	|	CheckedInClause AS CheckedInClause,
	|	ExpectedRoomMoveClause AS ExpectedRoomMoveClause,
	|	InHouseClause AS InHouseClause,
	|	ExpectedCheckOutClause AS ExpectedCheckOutClause,
	|	CheckedOutClause AS CheckedOutClause,
	|	SortCode AS SortCode,
	|	AccommodationTemplate.* AS AccommodationTemplate,
	|	NumberOfRooms AS NumberOfRooms,
	|	NumberOfAdults AS NumberOfAdults,
	|	NumberOfTeenagers AS NumberOfTeenagers,
	|	NumberOfChildren AS NumberOfChildren,
	|	NumberOfInfants AS NumberOfInfants,
	|	NumberOfPersons AS NumberOfPersons,
	|	NumberOfExpectedCheckInRooms AS NumberOfExpectedCheckInRooms,
	|	NumberOfCheckedInRooms AS NumberOfCheckedInRooms,
	|	NumberOfExpectedCheckOutRooms AS NumberOfExpectedCheckOutRooms,
	|	NumberOfCheckedOutRooms AS NumberOfCheckedOutRooms,
	|	NumberOfInHouseRooms AS NumberOfInHouseRooms,
	|	NumberOfExpectedRoomMoveRooms AS NumberOfExpectedRoomMoveRooms,
	|	NumberOfBlockedRooms AS NumberOfBlockedRooms}
	|FROM
	|	Catalog.Rooms AS RoomsData
	|{WHERE
	|	RoomsData.Owner.* AS Hotel,
	|	RoomsData.Ref.* AS Room,
	|	RoomsData.RoomType.* AS RoomType,
	|	RoomsData.Floor AS Floor,
	|	RoomsData.RoomStatus.* AS RoomStatus,
	|	(0) AS NumberOfGuestsOnArrival,
	|	(0) AS NumberOfGuests,
	|	(&qEmptyDate) AS RoomStatusLastChangeTime,
	|	RoomsData.Remarks AS Remarks,
	|	RoomsData.Remarks AS ReceptionRemarks,
	|	RoomsData.Remarks AS RoomRemarks,
	|	RoomsData.Remarks AS TaskRemarks,
	|	RoomsData.Remarks AS HousekeepingRemarks,
	|	(VALUE(Catalog.Customers.EmptyRef)) AS Customer,
	|	(VALUE(Catalog.ClientTypes.EmptyRef)) AS ClientType,
	|	(VALUE(Catalog.AccommodationTemplates.EmptyRef)) AS AccommodationTemplate,
	|	(NULL) AS Document,
	|	(NULL) AS DocumentGuestFullName,
	|	(NULL) AS DocumentCheckInDate,
	|	(NULL) AS DocumentDuration,
	|	(NULL) AS DocumentCheckOutDate,
	|	(NULL) AS DocumentGuestGroup,
	|	(NULL) AS DocumentGuestGroupDescription,
	|	RoomsData.Remarks AS DocumentClause,
	|	RoomsData.HasRoomBlocks AS HasRoomBlocks,
	|	(VALUE(Catalog.RoomBlockTypes.EmptyRef)) AS RoomBlockType,
	|	RoomsData.Remarks AS RoomBlockRemarks,
	|	RoomsData.StopSale AS StopSale,
	|	RoomsData.IsVirtual AS IsVirtual,
	|	RoomsData.RoomPropertiesCodes AS RoomPropertiesCodes,
	|	RoomsData.Remarks AS Condition,
	|	RoomsData.Remarks AS ExpectedCheckInClause,
	|	RoomsData.Remarks AS CheckedInClause,
	|	RoomsData.Remarks AS ExpectedRoomMoveClause,
	|	RoomsData.Remarks AS InHouseClause,
	|	RoomsData.Remarks AS ExpectedCheckOutClause,
	|	RoomsData.Remarks AS CheckedOutClause,
	|	RoomsData.SortCode AS SortCode,
	|	(0) AS NumberOfAdults,
	|	(0) AS NumberOfTeenagers,
	|	(0) AS NumberOfChildren,
	|	(0) AS NumberOfInfants,
	|	(0) AS NumberOfPersons,
	|	(0) AS NumberOfExpectedCheckInRooms,
	|	(0) AS NumberOfCheckedInRooms,
	|	(0) AS NumberOfExpectedCheckOutRooms,
	|	(0) AS NumberOfCheckedOutRooms,
	|	(0) AS NumberOfInHouseRooms,
	|	(0) AS NumberOfExpectedRoomMoveRooms,
	|	(0) AS NumberOfBlockedRooms}
	|{ORDER BY
	|	Hotel.* AS Hotel,
	|	Room.* AS Room,
	|	RoomType.* AS RoomType,
	|	Floor AS Floor,
	|	RoomStatus.* AS RoomStatus,
	|	RoomStatusLastChangeTime AS RoomStatusLastChangeTime,
	|	Remarks AS Remarks,
	|	ReceptionRemarks AS ReceptionRemarks,
	|	RoomRemarks AS RoomRemarks,
	|	TaskRemarks AS TaskRemarks,
	|	HousekeepingRemarks AS HousekeepingRemarks,
	|	Customer.* AS Customer,
	|	ClientType.* AS ClientType,
	|	AccommodationTemplate.* AS AccommodationTemplate,
	|	Document AS Document,
	|	DocumentGuestFullName AS DocumentGuestFullName,
	|	DocumentCheckInDate AS DocumentCheckInDate,
	|	DocumentDuration AS DocumentDuration,
	|	DocumentCheckOutDate AS DocumentCheckOutDate,
	|	DocumentGuestGroup AS DocumentGuestGroup,
	|	DocumentGuestGroupDescription AS DocumentGuestGroupDescription,
	|	DocumentClause AS DocumentClause,
	|	HasRoomBlocks AS HasRoomBlocks,
	|	RoomBlockType.* AS RoomBlockType,
	|	RoomBlockRemarks AS RoomBlockRemarks,
	|	StopSale AS StopSale,
	|	IsVirtual AS IsVirtual,
	|	RoomPropertiesCodes AS RoomPropertiesCodes,
	|	Condition AS Condition,
	|	ExpectedCheckInClause AS ExpectedCheckInClause,
	|	CheckedInClause AS CheckedInClause,
	|	ExpectedRoomMoveClause AS ExpectedRoomMoveClause,
	|	InHouseClause AS InHouseClause,
	|	ExpectedCheckOutClause AS ExpectedCheckOutClause,
	|	CheckedOutClause AS CheckedOutClause,
	|	SortCode AS SortCode,
	|	NumberOfAdults AS NumberOfAdults,
	|	NumberOfTeenagers AS NumberOfTeenagers,
	|	NumberOfChildren AS NumberOfChildren,
	|	NumberOfInfants AS NumberOfInfants,
	|	NumberOfPersons AS NumberOfPersons,
	|	NumberOfExpectedCheckInRooms AS NumberOfExpectedCheckInRooms,
	|	NumberOfCheckedInRooms AS NumberOfCheckedInRooms,
	|	NumberOfExpectedCheckOutRooms AS NumberOfExpectedCheckOutRooms,
	|	NumberOfCheckedOutRooms AS NumberOfCheckedOutRooms,
	|	NumberOfInHouseRooms AS NumberOfInHouseRooms,
	|	NumberOfExpectedRoomMoveRooms AS NumberOfExpectedRoomMoveRooms,
	|	NumberOfBlockedRooms AS NumberOfBlockedRooms}
	|TOTALS
	|	SUM(NumberOfGuestsOnArrival),
	|	SUM(NumberOfInHouseGuests),
	|	SUM(NumberOfRooms),
	|	SUM(NumberOfAdults),
	|	SUM(NumberOfTeenagers),
	|	SUM(NumberOfChildren),
	|	SUM(NumberOfInfants),
	|	SUM(NumberOfPersons),
	|	SUM(NumberOfExpectedCheckInRooms),
	|	SUM(NumberOfCheckedInRooms),
	|	SUM(NumberOfExpectedCheckOutRooms),
	|	SUM(NumberOfCheckedOutRooms),
	|	SUM(NumberOfInHouseRooms),
	|	SUM(NumberOfExpectedRoomMoveRooms),
	|	SUM(NumberOfBlockedRooms)
	|BY
	|	OVERALL
	|{TOTALS BY
	|	Hotel.* AS Hotel,
	|	Room.* AS Room,
	|	RoomType.* AS RoomType,
	|	Floor AS Floor,
	|	RoomStatus.* AS RoomStatus,
	|	Customer.* AS Customer,
	|	ClientType.* AS ClientType,
	|	AccommodationTemplate.* AS AccommodationTemplate,
	|	Document AS Document,
	|	DocumentClause AS DocumentClause,
	|	HasRoomBlocks AS HasRoomBlocks,
	|	RoomBlockType.* AS RoomBlockType,
	|	StopSale AS StopSale,
	|	IsVirtual AS IsVirtual,
	|	RoomPropertiesCodes AS RoomPropertiesCodes,
	|	Condition AS Condition}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("en='Housekeeping rooms'; ru='Служба номерного фонда'; de='Housekeeping Zimmern'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
