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
		If ValueIsFilled(Hotel) Then
			If Not ValueIsFilled(RegularOperationGroup) Then
				RegularOperationGroup = Hotel.RegularOperationGroup;
			EndIf;
		EndIf;
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
			                     TrimAll(Room.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Room types folder ';ru='Группа типов номеров ';de='Gruppe Zimmertypen '") + 
			                     TrimAll(Room.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(RoomSection) Then
		If Not RoomSection.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Room section ';ru='Секция номеров ';de='Zimmer-Abschnitt '") + 
			                     TrimAll(Room.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Room sections folder ';ru='Группа секций ';de='Gruppe Zimmer-Abschnitten '") + 
			                     TrimAll(Room.Description) + 
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
			                     TrimAll(Hotel.Description) + ";" + Chars.LF;
		EndIf;
	EndIf;
	Return vParamPresentation;
EndFunction // pmGetReportParametersPresentation

// -----------------------------------------------------------------------------
// Runs report and returns if report form should be shown
// -----------------------------------------------------------------------------
Procedure pmGenerate(pSpreadsheet) Export
	Var vTemplateAttributes;
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
	
	// Initialize report builder query generator attributes
	ReportBuilder.PresentationAdding = PresentationAdditionType.Add;
	
	// Fill report parameters
	ReportBuilder.Parameters.Insert("qPeriodFrom", BegOfDay(PeriodTo));
	ReportBuilder.Parameters.Insert("qPeriodTo", EndOfDay(PeriodTo));
	ReportBuilder.Parameters.Insert("qEmptyDate", '00010101');
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qIsEmptyHotel", Not ValueIsFilled(Hotel));
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qIsEmptyRoom", Not ValueIsFilled(Room));
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qIsEmptyRoomType", Not ValueIsFilled(RoomType));
	ReportBuilder.Parameters.Insert("qRoomSection", RoomSection);
	ReportBuilder.Parameters.Insert("qIsEmptyRoomSection", Not ValueIsFilled(RoomSection));
	ReportBuilder.Parameters.Insert("qExpense", AccumulationRecordType.Expense);
    ReportBuilder.Parameters.Insert("qRegularOperationGroup", RegularOperationGroup);
	ReportBuilder.Parameters.Insert("qEmptyRoomType", Catalogs.RoomTypes.EmptyRef());
	ReportBuilder.Parameters.Insert("qEmptyRoomRate", Catalogs.RoomRates.EmptyRef());
	ReportBuilder.Parameters.Insert("qAccomodationTypeRoom", Enums.AccomodationTypes.Room);
	ReportBuilder.Parameters.Insert("qAccomodationTypeBeds", Enums.AccomodationTypes.Beds);
	ReportBuilder.Parameters.Insert("qExpectedArrivalClause", NStr("en='Arrival today'; ru='На заезде'; de='Anreise heute'"));
	ReportBuilder.Parameters.Insert("qCheckedInClause", NStr("en='Checked-in'; ru='Заехал'; de='Checked-in'"));
	ReportBuilder.Parameters.Insert("qStayOverClause", NStr("en='Stay over'; ru='Занят'; de='In-house'"));
	ReportBuilder.Parameters.Insert("qExpectedDepartureClause", NStr("en='Departure today'; ru='На выезде'; de='Abreise heute'"));
	ReportBuilder.Parameters.Insert("qCheckedOutClause", NStr("en='Departed'; ru='Выехал'; de='Checked-out'"));
	ReportBuilder.Parameters.Insert("qExpectedRoomMoveClause", NStr("en='Moving into'; ru='Переселение'; de='Umzug'"));
	ReportBuilder.Parameters.Insert("qVacantClause", NStr("en='Vacant'; ru='Свободен'; de='Leer'"));
	ReportBuilder.Parameters.Insert("qIsDone", 
	" 
	|_");
	
	// Execute report builder query
	ReportBuilder.Execute();
	
	// Apply appearance settings to the report template
	vTemplateAttributes = cmApplyReportTemplateAppearance(ThisObject);
	
	// Output report to the spreadsheet
	ReportBuilder.Put(pSpreadsheet);
	//ReportBuilder.Template.Show(); // For debug purpose
	
	// Some report postprocessing
	vRoomColPos = -1;
	If ReportBuilder.RowDimensions.Find("Room") = Undefined Then
		vRoomColumn = ReportBuilder.SelectedFields.Find("Room");
		If vRoomColumn <> Undefined Then
			vRoomColPos = ReportBuilder.SelectedFields.IndexOf(vRoomColumn);
		EndIf;
	EndIf;
	If vRoomColPos >= 0 Then
		vRoomColPos = vRoomColPos + 2;
		// Process all report rows
		vCurRoom = "";
		For i = 6 To pSpreadsheet.TableHeight Do
			vRoom = pSpreadsheet.Area(i, vRoomColPos, i, vRoomColPos).Text;
			If Not IsBlankString(vRoom) Then
				If vRoom <> vCurRoom Then
					vCurRoom = vRoom;
				Else
					pSpreadsheet.Area(i, vRoomColPos, i, vRoomColPos).Text = "";
					pSpreadsheet.Area(i, vRoomColPos + 1, i, vRoomColPos + 1).Text = "";
					pSpreadsheet.Area(i, vRoomColPos + 2, i, vRoomColPos + 2).Text = "";
				EndIf;
			EndIf;
		EndDo;
	EndIf;

	// Apply appearance settings to the report spreadsheet
	cmApplyReportAppearance(ThisObject, pSpreadsheet, vTemplateAttributes);
EndProcedure // pmGenerate

// -----------------------------------------------------------------------------
Procedure pmInitializeReportBuilder() Export
	ReportBuilder = New ReportBuilder();
	
	// Initialize default query text
	QueryText = 
	"SELECT
	|	RoomsState.Hotel AS Hotel,
	|	RoomsState.Room AS Room,
	|	RoomsState.RoomStatus AS RoomStatus,
	|	RoomsState.RoomType AS RoomType,
	|	RoomsState.NumberOfRooms AS NumberOfRooms,
	|	RoomsState.Recorder AS Recorder,
	|	RoomsState.Guest AS Guest,
	|	RoomsState.ClientType AS ClientType,
	|	RoomsState.GuestGroup AS GuestGroup,
	|	RoomsState.Customer AS Customer,
	|	RoomsState.AccommodationTemplate AS AccommodationTemplate,
	|	RoomsState.CheckInDate AS CheckInDate,
	|	RoomsState.Duration AS Duration,
	|	RoomsState.CheckOutDate AS CheckOutDate,
	|	RoomsState.Remarks AS Remarks,
	|	RoomsState.HousekeepingRemarks AS HousekeepingRemarks,
	|	RoomsState.GuestsSortingOrder AS GuestsSortingOrder,
	|	RoomsState.Condition AS Condition,
	|	RoomsState.RegularOperation AS RegularOperation,
	|	RoomsState.RegularOperationCode AS RegularOperationCode
	|{SELECT
	|	Hotel.* AS Hotel,
	|	Room.* AS Room,
	|	RoomStatus.* AS RoomStatus,
	|	RoomType.* AS RoomType,
	|	NumberOfRooms AS NumberOfRooms,
	|	Recorder.* AS Recorder,
	|	Guest.* AS Guest,
	|	ClientType.* AS ClientType,
	|	GuestGroup.* AS GuestGroup,
	|	Customer.* AS Customer,
	|	AccommodationTemplate.* AS AccommodationTemplate,
	|	CheckInDate AS CheckInDate,
	|	Duration AS Duration,
	|	CheckOutDate AS CheckOutDate,
	|	Remarks AS Remarks,
	|	HousekeepingRemarks AS HousekeepingRemarks,
	|	GuestsSortingOrder AS GuestsSortingOrder,
	|	Condition AS Condition,
	|	RegularOperation.* AS RegularOperation,
	|	RegularOperationCode AS RegularOperationCode,
	|	(&qIsDone) AS IsDone}
	|FROM
	|	(SELECT
	|		RoomInventoryBalance.Hotel AS Hotel,
	|		RoomInventoryBalance.Room AS Room,
	|		RoomInventoryBalance.Room.RoomStatus AS RoomStatus,
	|		RoomInventoryBalance.RoomType AS RoomType,
	|		1 AS NumberOfRooms,
	|		RoomGuests.Recorder AS Recorder,
	|		RoomGuests.Guest AS Guest,
	|		RoomGuests.ClientType AS ClientType,
	|		RoomGuests.GuestGroup AS GuestGroup,
	|		RoomGuests.Customer AS Customer,
	|		RoomGuests.AccommodationTemplate AS AccommodationTemplate,
	|		RoomGuests.CheckInDate AS CheckInDate,
	|		RoomGuests.Duration AS Duration,
	|		RoomGuests.CheckOutDate AS CheckOutDate,
	|		RoomGuests.Remarks AS Remarks,
	|		RoomGuests.HousekeepingRemarks AS HousekeepingRemarks,
	|		RoomGuests.GuestsSortingOrder AS GuestsSortingOrder,
	|		CASE
	|			WHEN RoomGuests.Condition IS NULL
	|				THEN &qVacantClause
	|			ELSE RoomGuests.Condition
	|		END AS Condition,
	|		RegularOperations.RegularOperation AS RegularOperation,
	|		RegularOperations.RegularOperation.Code AS RegularOperationCode
	|	FROM
	|		AccumulationRegister.RoomInventory.Balance(
	|				&qPeriodTo,
	|				(Hotel IN HIERARCHY (&qHotel)
	|					OR &qIsEmptyHotel)
	|					AND (Room IN HIERARCHY (&qRoom)
	|						OR &qIsEmptyRoom)
	|					AND (RoomType IN HIERARCHY (&qRoomType)
	|						OR &qIsEmptyRoomType)
	|					AND (Room.RoomSection IN HIERARCHY (&qRoomSection)
	|						OR &qIsEmptyRoomSection)) AS RoomInventoryBalance
	|			LEFT JOIN (SELECT DISTINCT
	|				StayOverPersons.Recorder AS Recorder,
	|				StayOverPersons.Guest AS Guest,
	|				StayOverPersons.Customer AS Customer,
	|				StayOverPersons.Room AS Room,
	|				StayOverPersons.PeriodFrom AS CheckInDate,
	|				StayOverPersons.Duration AS Duration,
	|				StayOverPersons.PeriodTo AS CheckOutDate,
	|				StayOverPersons.ClientType AS ClientType,
	|				StayOverPersons.GuestGroup AS GuestGroup,
	|				StayOverPersons.Recorder.AccommodationTemplate AS AccommodationTemplate,
	|				CAST(StayOverPersons.Remarks AS STRING(999)) AS Remarks,
	|				CAST(StayOverPersons.HousekeepingRemarks AS STRING(999)) AS HousekeepingRemarks,
	|				40 AS GuestsSortingOrder,
	|				&qStayOverClause AS Condition
	|			FROM
	|				AccumulationRegister.RoomInventory AS StayOverPersons
	|			WHERE
	|				StayOverPersons.RecordType = &qExpense
	|				AND (StayOverPersons.Hotel IN HIERARCHY (&qHotel)
	|						OR &qIsEmptyHotel)
	|				AND (StayOverPersons.Room IN HIERARCHY (&qRoom)
	|						OR &qIsEmptyRoom)
	|				AND (StayOverPersons.RoomType IN HIERARCHY (&qRoomType)
	|						OR &qIsEmptyRoomType)
	|				AND (StayOverPersons.Room.RoomSection IN HIERARCHY (&qRoomSection)
	|						OR &qIsEmptyRoomSection)
	|				AND StayOverPersons.IsInHouse
	|				AND StayOverPersons.IsAccommodation
	|				AND StayOverPersons.PeriodFrom < &qPeriodTo
	|				AND StayOverPersons.PeriodTo > &qPeriodFrom
	|				AND StayOverPersons.Period = StayOverPersons.PeriodFrom
	|				AND StayOverPersons.CheckInDate < &qPeriodFrom
	|				AND StayOverPersons.CheckOutDate > &qPeriodTo
	|				AND (StayOverPersons.AccommodationType.Type = &qAccomodationTypeRoom
	|						OR StayOverPersons.AccommodationType.Type = &qAccomodationTypeBeds)
	|			
	|			UNION ALL
	|			
	|			SELECT DISTINCT
	|				CheckedInGuests.Recorder,
	|				CheckedInGuests.Guest,
	|				CheckedInGuests.Customer,
	|				CheckedInGuests.Room,
	|				CheckedInGuests.CheckInDate,
	|				CheckedInGuests.Duration,
	|				CheckedInGuests.CheckOutDate,
	|				CheckedInGuests.ClientType,
	|				CheckedInGuests.GuestGroup,
	|				CheckedInGuests.Recorder.AccommodationTemplate,
	|				CAST(CheckedInGuests.Remarks AS STRING(999)),
	|				CAST(CheckedInGuests.HousekeepingRemarks AS STRING(999)),
	|				50,
	|				&qCheckedInClause
	|			FROM
	|				AccumulationRegister.RoomInventory AS CheckedInGuests
	|			WHERE
	|				CheckedInGuests.RecordType = &qExpense
	|				AND (CheckedInGuests.Hotel IN HIERARCHY (&qHotel)
	|						OR &qIsEmptyHotel)
	|				AND (CheckedInGuests.Room IN HIERARCHY (&qRoom)
	|						OR &qIsEmptyRoom)
	|				AND (CheckedInGuests.RoomType IN HIERARCHY (&qRoomType)
	|						OR &qIsEmptyRoomType)
	|				AND (CheckedInGuests.Room.RoomSection IN HIERARCHY (&qRoomSection)
	|						OR &qIsEmptyRoomSection)
	|				AND CheckedInGuests.IsInHouse
	|				AND CheckedInGuests.IsAccommodation
	|				AND CheckedInGuests.PeriodFrom < &qPeriodTo
	|				AND CheckedInGuests.PeriodTo > &qPeriodFrom
	|				AND CheckedInGuests.Period = CheckedInGuests.PeriodFrom
	|				AND CheckedInGuests.CheckInDate >= &qPeriodFrom
	|				AND CheckedInGuests.CheckInDate <= &qPeriodTo
	|				AND (CheckedInGuests.AccommodationType.Type = &qAccomodationTypeRoom
	|						OR CheckedInGuests.AccommodationType.Type = &qAccomodationTypeBeds)
	|			
	|			UNION ALL
	|			
	|			SELECT DISTINCT
	|				ExpectedArrival.Recorder,
	|				ExpectedArrival.Guest,
	|				ExpectedArrival.Customer,
	|				ExpectedArrival.Room,
	|				ExpectedArrival.CheckInDate,
	|				ExpectedArrival.Duration,
	|				ExpectedArrival.CheckOutDate,
	|				ExpectedArrival.ClientType,
	|				ExpectedArrival.GuestGroup,
	|				ExpectedArrival.Recorder.AccommodationTemplate,
	|				CAST(ExpectedArrival.Remarks AS STRING(999)),
	|				CAST(ExpectedArrival.HousekeepingRemarks AS STRING(999)),
	|				20,
	|				&qExpectedArrivalClause
	|			FROM
	|				AccumulationRegister.RoomInventory AS ExpectedArrival
	|			WHERE
	|				ExpectedArrival.RecordType = &qExpense
	|				AND (ExpectedArrival.Hotel IN HIERARCHY (&qHotel)
	|						OR &qIsEmptyHotel)
	|				AND (ExpectedArrival.Room IN HIERARCHY (&qRoom)
	|						OR &qIsEmptyRoom)
	|				AND (ExpectedArrival.RoomType IN HIERARCHY (&qRoomType)
	|						OR &qIsEmptyRoomType)
	|				AND (ExpectedArrival.Room.RoomSection IN HIERARCHY (&qRoomSection)
	|						OR &qIsEmptyRoomSection)
	|				AND ExpectedArrival.IsReservation
	|				AND ExpectedArrival.PeriodFrom < &qPeriodTo
	|				AND ExpectedArrival.PeriodTo > &qPeriodFrom
	|				AND ExpectedArrival.Period = ExpectedArrival.PeriodFrom
	|				AND ExpectedArrival.CheckInDate >= &qPeriodFrom
	|				AND ExpectedArrival.CheckInDate <= &qPeriodTo
	|				AND (ExpectedArrival.AccommodationType.Type = &qAccomodationTypeRoom
	|						OR ExpectedArrival.AccommodationType.Type = &qAccomodationTypeBeds)
	|			
	|			UNION ALL
	|			
	|			SELECT DISTINCT
	|				ExpectedRoomMove.Ref,
	|				ExpectedRoomMove.Ref.Guest,
	|				ExpectedRoomMove.Ref.Customer,
	|				ExpectedRoomMove.Room,
	|				ExpectedRoomMove.Ref.CheckInDate,
	|				ExpectedRoomMove.Ref.Duration,
	|				ExpectedRoomMove.Ref.CheckOutDate,
	|				ExpectedRoomMove.Ref.ClientType,
	|				ExpectedRoomMove.Ref.GuestGroup,
	|				ExpectedRoomMove.Ref.AccommodationTemplate,
	|				CAST(ExpectedRoomMove.Ref.Remarks AS STRING(999)),
	|				CAST(ExpectedRoomMove.Ref.HousekeepingRemarks AS STRING(999)),
	|				30,
	|				&qExpectedRoomMoveClause
	|			FROM
	|				Document.Accommodation.RoomRates AS ExpectedRoomMove
	|			WHERE
	|				ExpectedRoomMove.Ref.Posted
	|				AND ExpectedRoomMove.Ref.AccommodationStatus.IsActive
	|				AND ExpectedRoomMove.Ref.AccommodationStatus.IsInHouse
	|				AND (ExpectedRoomMove.Ref.Hotel IN HIERARCHY (&qHotel)
	|						OR &qIsEmptyHotel)
	|				AND (ExpectedRoomMove.Room IN HIERARCHY (&qRoom)
	|						OR &qIsEmptyRoom)
	|				AND (ExpectedRoomMove.Room.RoomType IN HIERARCHY (&qRoomType)
	|						OR &qIsEmptyRoomType)
	|				AND (ExpectedRoomMove.Room.RoomSection IN HIERARCHY (&qRoomSection)
	|						OR &qIsEmptyRoomSection)
	|				AND ExpectedRoomMove.AccountingDate >= &qPeriodFrom
	|				AND ExpectedRoomMove.AccountingDate <= &qPeriodTo
	|				AND ExpectedRoomMove.Room <> ExpectedRoomMove.Ref.Room
	|				AND (ExpectedRoomMove.Ref.AccommodationType.Type = &qAccomodationTypeRoom
	|						OR ExpectedRoomMove.Ref.AccommodationType.Type = &qAccomodationTypeBeds)
	|			
	|			UNION ALL
	|			
	|			SELECT
	|				ExpectedDeparture.Recorder,
	|				ExpectedDeparture.Guest,
	|				ExpectedDeparture.Customer,
	|				ExpectedDeparture.Room,
	|				ExpectedDeparture.CheckInDate,
	|				ExpectedDeparture.Duration,
	|				ExpectedDeparture.CheckOutDate,
	|				ExpectedDeparture.ClientType,
	|				ExpectedDeparture.GuestGroup,
	|				ExpectedDeparture.Recorder.AccommodationTemplate,
	|				CAST(ExpectedDeparture.Remarks AS STRING(999)),
	|				CAST(ExpectedDeparture.HousekeepingRemarks AS STRING(999)),
	|				10,
	|				&qExpectedDepartureClause
	|			FROM
	|				AccumulationRegister.RoomInventory AS ExpectedDeparture
	|			WHERE
	|				ExpectedDeparture.RecordType = &qExpense
	|				AND (ExpectedDeparture.Hotel IN HIERARCHY (&qHotel)
	|						OR &qIsEmptyHotel)
	|				AND (ExpectedDeparture.Room IN HIERARCHY (&qRoom)
	|						OR &qIsEmptyRoom)
	|				AND (ExpectedDeparture.RoomType IN HIERARCHY (&qRoomType)
	|						OR &qIsEmptyRoomType)
	|				AND (ExpectedDeparture.Room.RoomSection IN HIERARCHY (&qRoomSection)
	|						OR &qIsEmptyRoomSection)
	|				AND ExpectedDeparture.IsInHouse
	|				AND ExpectedDeparture.IsAccommodation
	|				AND ExpectedDeparture.PeriodFrom < &qPeriodTo
	|				AND ExpectedDeparture.PeriodTo > &qPeriodFrom
	|				AND ExpectedDeparture.Period = ExpectedDeparture.PeriodFrom
	|				AND ExpectedDeparture.CheckOutDate >= &qPeriodFrom
	|				AND ExpectedDeparture.CheckOutDate <= &qPeriodTo
	|				AND (ExpectedDeparture.AccommodationType.Type = &qAccomodationTypeRoom
	|						OR ExpectedDeparture.AccommodationType.Type = &qAccomodationTypeBeds)
	|			
	|			UNION ALL
	|			
	|			SELECT
	|				CheckedOutGuests.Recorder,
	|				CheckedOutGuests.Guest,
	|				CheckedOutGuests.Customer,
	|				CheckedOutGuests.Room,
	|				CheckedOutGuests.CheckInDate,
	|				CheckedOutGuests.Duration,
	|				CheckedOutGuests.CheckOutDate,
	|				CheckedOutGuests.ClientType,
	|				CheckedOutGuests.GuestGroup,
	|				CheckedOutGuests.Recorder.AccommodationTemplate,
	|				CAST(CheckedOutGuests.Remarks AS STRING(999)),
	|				CAST(CheckedOutGuests.HousekeepingRemarks AS STRING(999)),
	|				60,
	|				&qCheckedOutClause
	|			FROM
	|				AccumulationRegister.RoomInventory AS CheckedOutGuests
	|			WHERE
	|				CheckedOutGuests.RecordType = &qExpense
	|				AND (CheckedOutGuests.Hotel IN HIERARCHY (&qHotel)
	|						OR &qIsEmptyHotel)
	|				AND (CheckedOutGuests.Room IN HIERARCHY (&qRoom)
	|						OR &qIsEmptyRoom)
	|				AND (CheckedOutGuests.RoomType IN HIERARCHY (&qRoomType)
	|						OR &qIsEmptyRoomType)
	|				AND (CheckedOutGuests.Room.RoomSection IN HIERARCHY (&qRoomSection)
	|						OR &qIsEmptyRoomSection)
	|				AND NOT CheckedOutGuests.IsInHouse
	|				AND CheckedOutGuests.IsAccommodation
	|				AND CheckedOutGuests.PeriodFrom < &qPeriodTo
	|				AND CheckedOutGuests.PeriodTo > &qPeriodFrom
	|				AND CheckedOutGuests.Period = CheckedOutGuests.PeriodFrom
	|				AND CheckedOutGuests.CheckOutDate >= &qPeriodFrom
	|				AND CheckedOutGuests.CheckOutDate <= &qPeriodTo
	|				AND (CheckedOutGuests.AccommodationType.Type = &qAccomodationTypeRoom
	|						OR CheckedOutGuests.AccommodationType.Type = &qAccomodationTypeBeds)
	|			
	|			UNION ALL
	|			
	|			SELECT
	|				RoomBlocks.Ref,
	|				NULL,
	|				NULL,
	|				RoomBlocks.Room,
	|				RoomBlocks.DateFrom,
	|				RoomBlocks.Duration,
	|				RoomBlocks.DateTo,
	|				NULL,
	|				NULL,
	|				NULL,
	|				CAST(RoomBlocks.Remarks AS STRING(999)),
	|				CAST(RoomBlocks.Remarks AS STRING(999)),
	|				70,
	|				RoomBlocks.RoomBlockType.Description
	|			FROM
	|				Document.SetRoomBlock AS RoomBlocks
	|			WHERE
	|				RoomBlocks.Posted
	|				AND (RoomBlocks.Hotel IN HIERARCHY (&qHotel)
	|						OR &qIsEmptyHotel)
	|				AND (RoomBlocks.Room IN HIERARCHY (&qRoom)
	|						OR &qIsEmptyRoom)
	|				AND (RoomBlocks.Room.RoomType IN HIERARCHY (&qRoomType)
	|						OR &qIsEmptyRoomType)
	|				AND (RoomBlocks.Room.RoomSection IN HIERARCHY (&qRoomSection)
	|						OR &qIsEmptyRoomSection)
	|				AND RoomBlocks.DateFrom < &qPeriodTo
	|				AND (RoomBlocks.DateTo > &qPeriodFrom
	|						OR RoomBlocks.DateTo = &qEmptyDate)) AS RoomGuests
	|			ON (RoomGuests.Room = RoomInventoryBalance.Room)
	|			LEFT JOIN Catalog.RegularOperationGroups.RegularOperations AS RegularOperations
	|			ON (RegularOperations.Ref = &qRegularOperationGroup)
	|				AND (RegularOperations.PerformWhenRoomIsBusy
	|						AND RoomGuests.Recorder IS NOT NULL 
	|						AND RoomGuests.GuestsSortingOrder = 40
	|						AND DATEDIFF(&qPeriodFrom, BEGINOFPERIOD(RoomGuests.CheckInDate, DAY), DAY) / RegularOperations.RegularOperationFrequency = (CAST(DATEDIFF(&qPeriodFrom, BEGINOFPERIOD(RoomGuests.CheckInDate, DAY), DAY) / RegularOperations.RegularOperationFrequency AS NUMBER(17, 0)))
	|						AND DATEDIFF(&qPeriodFrom, BEGINOFPERIOD(RoomGuests.CheckInDate, DAY), DAY) <> 0
	|					OR RegularOperations.PerformWhenRoomIsBusy
	|						AND RegularOperations.PerformOnCheckInDay
	|						AND (RoomGuests.GuestsSortingOrder = 20
	|							OR RoomGuests.GuestsSortingOrder = 50)
	|						AND BEGINOFPERIOD(RoomGuests.CheckInDate, DAY) = &qPeriodFrom
	|					OR RegularOperations.PerformWhenRoomIsBusy
	|						AND RegularOperations.PerformOnCheckOutDay
	|						AND (RoomGuests.GuestsSortingOrder = 10
	|							OR RoomGuests.GuestsSortingOrder = 60)
	|						AND BEGINOFPERIOD(RoomGuests.CheckOutDate, DAY) = &qPeriodFrom
	|					OR RegularOperations.PerformWhenRoomIsFree
	|						AND RoomGuests.GuestsSortingOrder IS NULL
	|						AND (RegularOperations.RegularOperationFrequency = 0
	|							OR RegularOperations.RegularOperationFrequency = 1)
	|						AND (NOT RegularOperations.DoNotPerformOnWeekends
	|							OR RegularOperations.DoNotPerformOnWeekends
	|								AND WEEKDAY(&qPeriodFrom) < 6)
	|						AND (RegularOperations.RoomType = &qEmptyRoomType
	|							OR RegularOperations.RoomType <> &qEmptyRoomType
	|								AND RoomInventoryBalance.RoomType = RegularOperations.RoomType
	|							OR RegularOperations.RoomType <> &qEmptyRoomType
	|								AND RoomInventoryBalance.RoomType.Parent <> &qEmptyRoomType
	|								AND RoomInventoryBalance.RoomType.Parent = RegularOperations.RoomType)
	|						AND (RegularOperations.RoomRate = &qEmptyRoomRate
	|							OR RegularOperations.RoomRate <> &qEmptyRoomRate
	|								AND NOT RoomGuests.Recorder.RoomRate IS NULL
	|								AND RoomGuests.Recorder.RoomRate <> &qEmptyRoomRate
	|								AND (RoomGuests.Recorder.RoomRate = RegularOperations.RoomRate
	|									OR RoomGuests.Recorder.RoomRate.Parent = RegularOperations.RoomRate
	|									OR RoomGuests.Recorder.RoomRate.Parent.Parent = RegularOperations.RoomRate)))
	|	WHERE
	|		RoomInventoryBalance.TotalRoomsBalance > 0
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		VirtualRooms.Owner,
	|		VirtualRooms.Ref,
	|		VirtualRooms.RoomStatus,
	|		VirtualRooms.RoomType,
	|		1,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		90,
	|		NULL,
	|		NULL,
	|		NULL
	|	FROM
	|		Catalog.Rooms AS VirtualRooms
	|	WHERE
	|		VirtualRooms.IsVirtual
	|		AND NOT VirtualRooms.IsFolder
	|		AND NOT VirtualRooms.DeletionMark
	|		AND VirtualRooms.OperationStartDate <= &qPeriodTo
	|		AND (VirtualRooms.OperationEndDate = &qEmptyDate
	|				OR VirtualRooms.OperationEndDate > &qPeriodTo)
	|		AND (VirtualRooms.Owner IN HIERARCHY (&qHotel)
	|				OR &qIsEmptyHotel)
	|		AND (VirtualRooms.Ref IN HIERARCHY (&qRoom)
	|				OR &qIsEmptyRoom)
	|		AND (VirtualRooms.RoomType IN HIERARCHY (&qRoomType)
	|				OR &qIsEmptyRoomType)
	|		AND (VirtualRooms.Ref.RoomSection IN HIERARCHY (&qRoomSection)
	|				OR &qIsEmptyRoomSection)) AS RoomsState
	|{WHERE
	|	RoomsState.Hotel.* AS Hotel,
	|	RoomsState.Room.* AS Room,
	|	RoomsState.RoomStatus.* AS RoomStatus,
	|	RoomsState.RoomType.* AS RoomType,
	|	RoomsState.NumberOfRooms AS NumberOfRooms,
	|	RoomsState.Recorder.* AS Recorder,
	|	RoomsState.Guest.* AS Guest,
	|	RoomsState.ClientType.* AS ClientType,
	|	RoomsState.GuestGroup.* AS GuestGroup,
	|	RoomsState.Customer.* AS Customer,
	|	RoomsState.AccommodationTemplate.* AS AccommodationTemplate,
	|	RoomsState.CheckInDate AS CheckInDate,
	|	RoomsState.Duration AS Duration,
	|	RoomsState.CheckOutDate AS CheckOutDate,
	|	RoomsState.Remarks AS Remarks,
	|	RoomsState.HousekeepingRemarks AS HousekeepingRemarks,
	|	RoomsState.GuestsSortingOrder AS GuestsSortingOrder,
	|	RoomsState.Condition AS Condition,
	|	RoomsState.RegularOperation.* AS RegularOperation,
	|	RoomsState.RegularOperationCode AS RegularOperationCode}
	|
	|ORDER BY
	|	Hotel,
	|	Room
	|{ORDER BY
	|	Hotel.* AS Hotel,
	|	Room.* AS Room,
	|	RoomStatus.* AS RoomStatus,
	|	RoomType.* AS RoomType,
	|	NumberOfRooms AS NumberOfRooms,
	|	Recorder.* AS Recorder,
	|	Guest.* AS Guest,
	|	ClientType.* AS ClientType,
	|	GuestGroup.* AS GuestGroup,
	|	Customer.* AS Customer,
	|	AccommodationTemplate.* AS AccommodationTemplate,
	|	CheckInDate AS CheckInDate,
	|	Duration AS Duration,
	|	CheckOutDate AS CheckOutDate,
	|	Remarks AS Remarks,
	|	HousekeepingRemarks AS HousekeepingRemarks,
	|	GuestsSortingOrder AS GuestsSortingOrder,
	|	Condition AS Condition,
	|	RegularOperation.* AS RegularOperation,
	|	RegularOperationCode AS RegularOperationCode}
	|TOTALS
	|	CASE
	|		WHEN NOT Room IS NULL
	|			THEN MAX(NumberOfRooms)
	|		ELSE SUM(NumberOfRooms)
	|	END AS NumberOfRooms
	|BY
	|	OVERALL,
	|	Hotel,
	|	Room,
	|	Recorder
	|{TOTALS BY
	|	Hotel.* AS Hotel,
	|	Room.* AS Room,
	|	RoomStatus.* AS RoomStatus,
	|	RoomType.* AS RoomType,
	|	Guest.* AS Guest,
	|	ClientType.* AS ClientType,
	|	GuestGroup.* AS GuestGroup,
	|	Customer.* AS Customer,
	|	AccommodationTemplate.* AS AccommodationTemplate,
	|	RegularOperation.* AS RegularOperation}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Room attendants report';RU='Отчет горничных';de='Room attendants Bericht'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
