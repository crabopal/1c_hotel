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
		PeriodTo = CurrentSessionDate(); // For now
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetReportParametersPresentation() Export
	vParamPresentation = "";
	If ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период '; en = 'Period '; de = 'Periode '") + 
		                     Format(PeriodTo, "DF='dd.MM.yyyy HH:mm:ss'") + 
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
			vParamPresentation = vParamPresentation + NStr("en='Rooms folder ';ru='Группа номеров ';de='Zimmergruppe '") + 
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
			vParamPresentation = vParamPresentation + NStr("en='Room types folder ';ru='Группа типов номеров ';de='Zimmertypengruppe '") + 
			                     TrimAll(RoomType.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(BedsSetup) Then
		vParamPresentation = vParamPresentation + NStr("en='Beds ';ru='Кровати ';de='Betten '") + 
		                     TrimAll(BedsSetup.Description) + 
		                     ";" + Chars.LF;
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
	ReportBuilder.Parameters.Insert("qIsEmptyHotel", Not ValueIsFilled(Hotel));
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qBegOfPeriodTo", BegOfDay(PeriodTo));
	ReportBuilder.Parameters.Insert("qEndOfPeriodTo", EndOfDay(PeriodTo));
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qIsEmptyRoom", Not ValueIsFilled(Room));
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qIsEmptyRoomType", Not ValueIsFilled(RoomType));
	ReportBuilder.Parameters.Insert("qEmptyDate", '00010101');
	ReportBuilder.Parameters.Insert("qBedsSetup", BedsSetup);
	ReportBuilder.Parameters.Insert("qIsEmptyBedsSetup", Not ValueIsFilled(BedsSetup));
	ReportBuilder.Parameters.Insert("qExpense", AccumulationRecordType.Expense);
 	ReportBuilder.Parameters.Insert("qExpectedArrivalClause", NStr("en='Expected arrival'; ru='На заезде'; de='Voraus. Anreise'") + " ");
	ReportBuilder.Parameters.Insert("qCheckedInClause", NStr("en='Checked-in'; ru='Заехал'; de='Checked-in'") + " ");
	ReportBuilder.Parameters.Insert("qStayOverClause", NStr("en='Stay over'; ru='Занят'; de='In-house'") + " ");
	ReportBuilder.Parameters.Insert("qExpectedDepartureClause", NStr("en='Expected departure'; ru='На выезде'; de='Voraus. Abreise'") + " ");
	ReportBuilder.Parameters.Insert("qCheckedOutClause", NStr("en='Departed'; ru='Выехал'; de='Checked-out'") + " ");
	ReportBuilder.Parameters.Insert("qVacantClause", NStr("en='Vacant'; ru='Свободен'; de='Vakant'"));

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
	|	InHouseRecords.Hotel AS Hotel,
	|	InHouseRecords.Room AS Room,
	|	InHouseRecords.Recorder AS Accommodation,
	|	InHouseRecords.Recorder.SortCode AS SortCode,
	|	InHouseRecords.Recorder.Date AS DocDate
	|INTO InHouseRecords
	|FROM
	|	AccumulationRegister.RoomInventory AS InHouseRecords
	|WHERE
	|	InHouseRecords.PeriodFrom < &qEndOfPeriodTo
	|	AND InHouseRecords.PeriodTo > &qBegOfPeriodTo
	|	AND InHouseRecords.CheckOutDate > &qEndOfPeriodTo
	|	AND InHouseRecords.CheckInDate < &qBegOfPeriodTo
	|	AND (InHouseRecords.Hotel IN HIERARCHY (&qHotel)
	|			OR &qIsEmptyHotel)
	|	AND (InHouseRecords.Room IN HIERARCHY (&qRoom)
	|			OR &qIsEmptyRoom)
	|	AND (InHouseRecords.RoomType IN HIERARCHY (&qRoomType)
	|			OR &qIsEmptyRoomType)
	|	AND InHouseRecords.IsAccommodation
	|	AND InHouseRecords.RecordType = &qExpense
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MainInHouseRecords.Hotel AS Hotel,
	|	MainInHouseRecords.Room AS Room,
	|	MIN(MainInHouseRecords.SortCode) AS SortCode,
	|	MIN(MainInHouseRecords.DocDate) AS DocDate
	|INTO MainInHouseGuests
	|FROM
	|	InHouseRecords AS MainInHouseRecords
	|
	|GROUP BY
	|	MainInHouseRecords.Hotel,
	|	MainInHouseRecords.Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InHouseGuests.Hotel AS Hotel,
	|	InHouseGuests.Room AS Room,
	|	InHouseGuests.Accommodation AS Accommodation
	|INTO InHouseGuests
	|FROM
	|	InHouseRecords AS InHouseGuests
	|		INNER JOIN MainInHouseGuests AS MainInHouseGuests
	|		ON InHouseGuests.Hotel = MainInHouseGuests.Hotel
	|			AND InHouseGuests.Room = MainInHouseGuests.Room
	|			AND InHouseGuests.SortCode = MainInHouseGuests.SortCode
	|			AND InHouseGuests.DocDate = MainInHouseGuests.DocDate
	|
	|INDEX BY
	|	Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExpectedRecords.Hotel AS Hotel,
	|	ExpectedRecords.Room AS Room,
	|	ExpectedRecords.Recorder AS Reservation,
	|	ExpectedRecords.Recorder.SortCode AS SortCode,
	|	ExpectedRecords.Recorder.Date AS DocDate
	|INTO ExpectedRecords
	|FROM
	|	AccumulationRegister.RoomInventory AS ExpectedRecords
	|WHERE
	|	ExpectedRecords.CheckInDate <= &qEndOfPeriodTo
	|	AND ExpectedRecords.CheckInDate >= &qBegOfPeriodTo
	|	AND (ExpectedRecords.Hotel IN HIERARCHY (&qHotel)
	|			OR &qIsEmptyHotel)
	|	AND (ExpectedRecords.Room IN HIERARCHY (&qRoom)
	|			OR &qIsEmptyRoom)
	|	AND (ExpectedRecords.RoomType IN HIERARCHY (&qRoomType)
	|			OR &qIsEmptyRoomType)
	|	AND ExpectedRecords.IsReservation
	|	AND ExpectedRecords.ReservationStatus.IsActive
	|	AND NOT ExpectedRecords.ReservationStatus.IsCheckIn
	|	AND ExpectedRecords.RecordType = &qExpense
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MainExpectedRecords.Hotel AS Hotel,
	|	MainExpectedRecords.Room AS Room,
	|	MIN(MainExpectedRecords.SortCode) AS SortCode,
	|	MIN(MainExpectedRecords.DocDate) AS DocDate
	|INTO MainExpectedGuests
	|FROM
	|	ExpectedRecords AS MainExpectedRecords
	|
	|GROUP BY
	|	MainExpectedRecords.Hotel,
	|	MainExpectedRecords.Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExpectedGuests.Hotel AS Hotel,
	|	ExpectedGuests.Room AS Room,
	|	ExpectedGuests.Reservation AS Reservation
	|INTO ExpectedGuests
	|FROM
	|	ExpectedRecords AS ExpectedGuests
	|		INNER JOIN MainExpectedGuests AS MainExpectedGuests
	|		ON ExpectedGuests.Hotel = MainExpectedGuests.Hotel
	|			AND ExpectedGuests.Room = MainExpectedGuests.Room
	|			AND ExpectedGuests.SortCode = MainExpectedGuests.SortCode
	|			AND ExpectedGuests.DocDate = MainExpectedGuests.DocDate
	|
	|INDEX BY
	|	Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CheckedInRecords.Hotel AS Hotel,
	|	CheckedInRecords.Room AS Room,
	|	CheckedInRecords.Recorder AS Accommodation,
	|	CheckedInRecords.Recorder.SortCode AS SortCode,
	|	CheckedInRecords.Recorder.Date AS DocDate
	|INTO CheckedInRecords
	|FROM
	|	AccumulationRegister.RoomInventory AS CheckedInRecords
	|WHERE
	|	CheckedInRecords.PeriodFrom < &qEndOfPeriodTo
	|	AND CheckedInRecords.PeriodTo > &qBegOfPeriodTo
	|	AND CheckedInRecords.CheckInDate >= &qBegOfPeriodTo
	|	AND CheckedInRecords.CheckInDate <= &qEndOfPeriodTo
	|	AND (CheckedInRecords.Hotel IN HIERARCHY (&qHotel)
	|			OR &qIsEmptyHotel)
	|	AND (CheckedInRecords.Room IN HIERARCHY (&qRoom)
	|			OR &qIsEmptyRoom)
	|	AND (CheckedInRecords.RoomType IN HIERARCHY (&qRoomType)
	|			OR &qIsEmptyRoomType)
	|	AND CheckedInRecords.IsAccommodation
	|	AND CheckedInRecords.RecordType = &qExpense
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MainCheckedInRecords.Hotel AS Hotel,
	|	MainCheckedInRecords.Room AS Room,
	|	MIN(MainCheckedInRecords.SortCode) AS SortCode,
	|	MIN(MainCheckedInRecords.DocDate) AS DocDate
	|INTO MainCheckedInRecords
	|FROM
	|	CheckedInRecords AS MainCheckedInRecords
	|
	|GROUP BY
	|	MainCheckedInRecords.Hotel,
	|	MainCheckedInRecords.Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CheckedInGuests.Hotel AS Hotel,
	|	CheckedInGuests.Room AS Room,
	|	CheckedInGuests.Accommodation AS Accommodation
	|INTO CheckedInGuests
	|FROM
	|	CheckedInRecords AS CheckedInGuests
	|		INNER JOIN MainCheckedInRecords AS MainCheckedInGuests
	|		ON CheckedInGuests.Hotel = MainCheckedInGuests.Hotel
	|			AND CheckedInGuests.Room = MainCheckedInGuests.Room
	|			AND CheckedInGuests.SortCode = MainCheckedInGuests.SortCode
	|			AND CheckedInGuests.DocDate = MainCheckedInGuests.DocDate
	|
	|INDEX BY
	|	Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExpectedCheckOutRecords.Hotel AS Hotel,
	|	ExpectedCheckOutRecords.Room AS Room,
	|	ExpectedCheckOutRecords.Recorder AS Accommodation,
	|	ExpectedCheckOutRecords.Recorder.SortCode AS SortCode,
	|	ExpectedCheckOutRecords.Recorder.Date AS DocDate
	|INTO ExpectedCheckOutRecords
	|FROM
	|	AccumulationRegister.RoomInventory AS ExpectedCheckOutRecords
	|WHERE
	|	ExpectedCheckOutRecords.CheckOutDate <= &qEndOfPeriodTo
	|	AND ExpectedCheckOutRecords.CheckOutDate >= &qBegOfPeriodTo
	|	AND (ExpectedCheckOutRecords.Hotel IN HIERARCHY (&qHotel)
	|			OR &qIsEmptyHotel)
	|	AND (ExpectedCheckOutRecords.Room IN HIERARCHY (&qRoom)
	|			OR &qIsEmptyRoom)
	|	AND (ExpectedCheckOutRecords.RoomType IN HIERARCHY (&qRoomType)
	|			OR &qIsEmptyRoomType)
	|	AND ExpectedCheckOutRecords.IsAccommodation
	|	AND ExpectedCheckOutRecords.AccommodationStatus.IsInHouse
	|	AND ExpectedCheckOutRecords.RecordType = &qExpense
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MainExpectedCheckOutRecords.Hotel AS Hotel,
	|	MainExpectedCheckOutRecords.Room AS Room,
	|	MIN(MainExpectedCheckOutRecords.SortCode) AS SortCode,
	|	MIN(MainExpectedCheckOutRecords.DocDate) AS DocDate
	|INTO MainExpectedCheckOutGuests
	|FROM
	|	ExpectedCheckOutRecords AS MainExpectedCheckOutRecords
	|
	|GROUP BY
	|	MainExpectedCheckOutRecords.Hotel,
	|	MainExpectedCheckOutRecords.Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExpectedCheckOutGuests.Hotel AS Hotel,
	|	ExpectedCheckOutGuests.Room AS Room,
	|	ExpectedCheckOutGuests.Accommodation AS Accommodation
	|INTO ExpectedCheckOutGuests
	|FROM
	|	ExpectedCheckOutRecords AS ExpectedCheckOutGuests
	|		INNER JOIN MainExpectedCheckOutGuests AS MainExpectedCheckOutGuests
	|		ON ExpectedCheckOutGuests.Hotel = MainExpectedCheckOutGuests.Hotel
	|			AND ExpectedCheckOutGuests.Room = MainExpectedCheckOutGuests.Room
	|			AND ExpectedCheckOutGuests.SortCode = MainExpectedCheckOutGuests.SortCode
	|			AND ExpectedCheckOutGuests.DocDate = MainExpectedCheckOutGuests.DocDate
	|
	|INDEX BY
	|	Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CheckOutRecords.Hotel AS Hotel,
	|	CheckOutRecords.Room AS Room,
	|	CheckOutRecords.Recorder AS Accommodation,
	|	CheckOutRecords.Recorder.SortCode AS SortCode,
	|	CheckOutRecords.Recorder.Date AS DocDate
	|INTO CheckOutRecords
	|FROM
	|	AccumulationRegister.RoomInventory AS CheckOutRecords
	|WHERE
	|	CheckOutRecords.CheckOutDate <= &qEndOfPeriodTo
	|	AND CheckOutRecords.CheckOutDate >= &qBegOfPeriodTo
	|	AND (CheckOutRecords.Hotel IN HIERARCHY (&qHotel)
	|			OR &qIsEmptyHotel)
	|	AND (CheckOutRecords.Room IN HIERARCHY (&qRoom)
	|			OR &qIsEmptyRoom)
	|	AND (CheckOutRecords.RoomType IN HIERARCHY (&qRoomType)
	|			OR &qIsEmptyRoomType)
	|	AND CheckOutRecords.IsAccommodation
	|	AND NOT CheckOutRecords.AccommodationStatus.IsInHouse
	|	AND CheckOutRecords.RecordType = &qExpense
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MainCheckOutRecords.Hotel AS Hotel,
	|	MainCheckOutRecords.Room AS Room,
	|	MIN(MainCheckOutRecords.SortCode) AS SortCode,
	|	MIN(MainCheckOutRecords.DocDate) AS DocDate
	|INTO MainCheckOutGuests
	|FROM
	|	CheckOutRecords AS MainCheckOutRecords
	|
	|GROUP BY
	|	MainCheckOutRecords.Hotel,
	|	MainCheckOutRecords.Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CheckOutGuests.Hotel AS Hotel,
	|	CheckOutGuests.Room AS Room,
	|	CheckOutGuests.Accommodation AS Accommodation
	|INTO CheckOutGuests
	|FROM
	|	CheckOutRecords AS CheckOutGuests
	|		INNER JOIN MainCheckOutGuests AS MainCheckOutGuests
	|		ON CheckOutGuests.Hotel = MainCheckOutGuests.Hotel
	|			AND CheckOutGuests.Room = MainCheckOutGuests.Room
	|			AND CheckOutGuests.SortCode = MainCheckOutGuests.SortCode
	|			AND CheckOutGuests.DocDate = MainCheckOutGuests.DocDate
	|
	|INDEX BY
	|	Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomBlockRecords.Hotel AS Hotel,
	|	RoomBlockRecords.Room AS Room,
	|	RoomBlockRecords.Recorder AS Recorder,
	|	RoomBlockRecords.Recorder.Date AS DocDate
	|INTO RoomBlockRecords
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomBlockRecords
	|WHERE
	|	RoomBlockRecords.PeriodFrom <= &qPeriodTo
	|	AND RoomBlockRecords.PeriodTo > &qPeriodTo
	|	AND (RoomBlockRecords.Hotel IN HIERARCHY (&qHotel)
	|			OR &qIsEmptyHotel)
	|	AND (RoomBlockRecords.Room IN HIERARCHY (&qRoom)
	|			OR &qIsEmptyRoom)
	|	AND (RoomBlockRecords.RoomType IN HIERARCHY (&qRoomType)
	|			OR &qIsEmptyRoomType)
	|	AND RoomBlockRecords.IsBlocking
	|	AND RoomBlockRecords.RecordType = &qExpense
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MainRoomBlockRecords.Hotel AS Hotel,
	|	MainRoomBlockRecords.Room AS Room,
	|	MIN(MainRoomBlockRecords.DocDate) AS DocDate
	|INTO MainRoomBlockRecords
	|FROM
	|	RoomBlockRecords AS MainRoomBlockRecords
	|
	|GROUP BY
	|	MainRoomBlockRecords.Hotel,
	|	MainRoomBlockRecords.Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomBlocks.Hotel AS Hotel,
	|	RoomBlocks.Room AS Room,
	|	RoomBlocks.Recorder AS Recorder,
	|	RoomBlocks.Recorder.RoomBlockType AS RoomBlockType
	|INTO RoomBlocks
	|FROM
	|	RoomBlockRecords AS RoomBlocks
	|		INNER JOIN MainRoomBlockRecords AS MainRoomBlockRecords
	|		ON RoomBlocks.Hotel = MainRoomBlockRecords.Hotel
	|			AND RoomBlocks.Room = MainRoomBlockRecords.Room
	|			AND RoomBlocks.DocDate = MainRoomBlockRecords.DocDate
	|
	|INDEX BY
	|	Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventory.Hotel AS Hotel,
	|	RoomInventory.RoomStatus AS RoomStatus,
	|	RoomInventory.Room AS Room,
	|	RoomInventory.RoomType AS RoomType,
	|	RoomInventory.Room.Remarks AS Remarks,
	|	RoomInventory.Room.HasRoomBlocks AS HasRoomBlocks,
	|	CASE
	|		WHEN NOT ExpectedGuests.Reservation IS NULL
	|			THEN &qExpectedArrivalClause
	|		ELSE """"
	|	END + CASE
	|		WHEN NOT ExpectedCheckOutGuests.Accommodation IS NULL
	|			THEN &qExpectedDepartureClause
	|		ELSE """"
	|	END + CASE
	|		WHEN NOT CheckOutGuests.Accommodation IS NULL
	|			THEN &qCheckedOutClause
	|		ELSE """"
	|	END + CASE
	|		WHEN NOT CheckedInGuests.Accommodation IS NULL
	|			THEN &qCheckedInClause
	|		ELSE """"
	|	END + CASE
	|		WHEN NOT InHouseGuests.Accommodation IS NULL
	|			THEN &qStayOverClause
	|		ELSE """"
	|	END + CASE
	|		WHEN NOT RoomBlocks.Recorder IS NULL
	|			THEN RoomBlocks.RoomBlockType.Description
	|		ELSE """"
	|	END + CASE
	|		WHEN ExpectedGuests.Reservation IS NULL
	|				AND ExpectedCheckOutGuests.Accommodation IS NULL
	|				AND CheckedInGuests.Accommodation IS NULL
	|				AND InHouseGuests.Accommodation IS NULL
	|				AND CheckOutGuests.Accommodation IS NULL
	|				AND RoomBlocks.Recorder IS NULL
	|			THEN &qVacantClause
	|		ELSE """"
	|	END AS RoomCondition,
	|	CASE
	|		WHEN RoomInventory.RoomType.DoesNotAffectRoomRevenueStatistics
	|			THEN RoomInventory.TotalSpecialRooms
	|		ELSE RoomInventory.TotalRooms
	|	END AS TotalRooms,
	|	CASE
	|		WHEN RoomInventory.RoomType.DoesNotAffectRoomRevenueStatistics
	|			THEN RoomInventory.TotalSpecialBeds
	|		ELSE RoomInventory.TotalBeds
	|	END AS TotalBeds,
	|	RoomInventory.TotalSpecialRooms AS TotalSpecialRooms,
	|	RoomInventory.TotalSpecialBeds AS TotalSpecialBeds
	|{SELECT
	|	Hotel.*,
	|	RoomType.*,
	|	Room.*,
	|	RoomStatus.*,
	|	Remarks,
	|	HasRoomBlocks,
	|	RoomInventory.BedsSetupInRoom.* AS BedsSetupInRoom,
	|	RoomCondition,
	|	TotalRooms,
	|	TotalBeds,
	|	TotalSpecialRooms,
	|	TotalSpecialBeds}
	|FROM
	|	(SELECT
	|		AvailableRooms.Hotel AS Hotel,
	|		AvailableRooms.Room AS Room,
	|		AvailableRooms.RoomType AS RoomType,
	|		AvailableRooms.Room.BedsSetup AS BedsSetupInRoom,
	|		RoomStatuses.RoomStatus AS RoomStatus,
	|		ISNULL(AvailableRooms.TotalRoomsBalance, 0) AS TotalRooms,
	|		ISNULL(AvailableRooms.TotalBedsBalance, 0) AS TotalBeds,
	|		ISNULL(AvailableRooms.TotalSpecialRoomsBalance, 0) AS TotalSpecialRooms,
	|		ISNULL(AvailableRooms.TotalSpecialBedsBalance, 0) AS TotalSpecialBeds
	|	FROM
	|		AccumulationRegister.RoomInventory.Balance(
	|				&qPeriodTo,
	|				(Hotel IN HIERARCHY (&qHotel)
	|					OR &qIsEmptyHotel)
	|					AND (Room IN HIERARCHY (&qRoom)
	|						OR &qIsEmptyRoom)
	|					AND (RoomType IN HIERARCHY (&qRoomType)
	|						OR &qIsEmptyRoomType)) AS AvailableRooms
	|			LEFT JOIN InformationRegister.RoomStatusChangeHistory.SliceLast(
	|					&qPeriodTo,
	|					(Room.Owner IN HIERARCHY (&qHotel)
	|						OR &qIsEmptyHotel)
	|						AND (Room IN HIERARCHY (&qRoom)
	|							OR &qIsEmptyRoom)) AS RoomStatuses
	|			ON AvailableRooms.Room = RoomStatuses.Room) AS RoomInventory
	|		LEFT JOIN InHouseGuests AS InHouseGuests
	|		ON RoomInventory.Room = InHouseGuests.Room
	|		LEFT JOIN ExpectedGuests AS ExpectedGuests
	|		ON RoomInventory.Room = ExpectedGuests.Room
	|		LEFT JOIN CheckedInGuests AS CheckedInGuests
	|		ON RoomInventory.Room = CheckedInGuests.Room
	|		LEFT JOIN ExpectedCheckOutGuests AS ExpectedCheckOutGuests
	|		ON RoomInventory.Room = ExpectedCheckOutGuests.Room
	|		LEFT JOIN CheckOutGuests AS CheckOutGuests
	|		ON RoomInventory.Room = CheckOutGuests.Room
	|		LEFT JOIN RoomBlocks AS RoomBlocks
	|		ON RoomInventory.Room = RoomBlocks.Room
	|WHERE
	|	(RoomInventory.BedsSetupInRoom = &qBedsSetup
	|			OR &qIsEmptyBedsSetup)
	|{WHERE
	|	RoomInventory.Hotel.*,
	|	RoomInventory.Room.RoomStatus.*,
	|	RoomInventory.Room.*,
	|	RoomInventory.RoomType.*,
	|	RoomInventory.Room.Remarks,
	|	RoomInventory.Room.HasRoomBlocks,
	|	RoomInventory.BedsSetupInRoom.* AS BedsSetupInRoom,
	|	(CASE
	|			WHEN NOT ExpectedGuests.Reservation IS NULL
	|				THEN &qExpectedArrivalClause
	|			ELSE """"
	|		END + CASE
	|			WHEN NOT ExpectedCheckOutGuests.Accommodation IS NULL
	|				THEN &qExpectedDepartureClause
	|			ELSE """"
	|		END + CASE
	|			WHEN NOT CheckOutGuests.Accommodation IS NULL
	|				THEN &qCheckedOutClause
	|			ELSE """"
	|		END + CASE
	|			WHEN NOT CheckedInGuests.Accommodation IS NULL
	|				THEN &qCheckedInClause
	|			ELSE """"
	|		END + CASE
	|			WHEN NOT InHouseGuests.Accommodation IS NULL
	|				THEN &qStayOverClause
	|			ELSE """"
	|		END + CASE
	|			WHEN NOT RoomBlocks.Recorder IS NULL
	|				THEN RoomBlocks.RoomBlockType.Description
	|			ELSE """"
	|		END + CASE
	|			WHEN ExpectedGuests.Reservation IS NULL
	|					AND ExpectedCheckOutGuests.Accommodation IS NULL
	|					AND CheckedInGuests.Accommodation IS NULL
	|					AND InHouseGuests.Accommodation IS NULL
	|					AND CheckOutGuests.Accommodation IS NULL
	|					AND RoomBlocks.Recorder IS NULL
	|				THEN &qVacantClause
	|			ELSE """"
	|		END) AS RoomCondition,
	|	RoomInventory.TotalRooms,
	|	RoomInventory.TotalBeds,
	|	RoomInventory.TotalSpecialRooms,
	|	RoomInventory.TotalSpecialBeds}
	|
	|ORDER BY
	|	Hotel,
	|	RoomType,
	|	Room
	|{ORDER BY
	|	Hotel.*,
	|	RoomStatus.*,
	|	Room.*,
	|	RoomType.*,
	|	Remarks,
	|	HasRoomBlocks,
	|	RoomInventory.BedsSetupInRoom.* AS BedsSetupInRoom,
	|	RoomCondition,
	|	TotalRooms,
	|	TotalBeds,
	|	TotalSpecialRooms,
	|	TotalSpecialBeds}
	|TOTALS
	|	CASE
	|		WHEN RoomType IS NULL
	|			THEN SUM(TotalRooms) - SUM(TotalSpecialRooms)
	|		ELSE SUM(TotalRooms)
	|	END AS TotalRooms,
	|	CASE
	|		WHEN RoomType IS NULL
	|			THEN SUM(TotalBeds) - SUM(TotalSpecialBeds)
	|		ELSE SUM(TotalBeds)
	|	END AS TotalBeds,
	|	SUM(TotalSpecialRooms),
	|	SUM(TotalSpecialBeds)
	|BY
	|	OVERALL,
	|	Hotel AS Hotel,
	|	RoomType AS RoomType,
	|	Room
	|{TOTALS BY
	|	Hotel.*,
	|	RoomStatus.*,
	|	Room.*,
	|	RoomType.*,
	|	RoomInventory.BedsSetupInRoom.* AS BedsSetupInRoom,
	|	HasRoomBlocks}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Rooms';RU='Номерной фонд';de='Zimmern'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
