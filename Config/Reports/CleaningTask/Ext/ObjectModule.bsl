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
			If Not ValueIsFilled(CheckOutCleaning) Then
				CheckOutCleaning = Hotel.CheckOutCleaning;
			EndIf;
			If Not ValueIsFilled(RegularCleaning) Then
				RegularCleaning = Hotel.RegularCleaning;
			EndIf;
			If Not ValueIsFilled(VacantRoomCleaning) Then
				VacantRoomCleaning = Hotel.VacantRoomCleaning;
			EndIf;
			If Not ValueIsFilled(RepairEndCleaning) Then
				RepairEndCleaning = Hotel.RepairEndCleaning;
			EndIf;
			If Not ValueIsFilled(RoomStatusAfterCheckOut) Then
				RoomStatusAfterCheckOut = Hotel.RoomStatusAfterCheckOut;
			EndIf;
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
	If ValueIsFilled(RoomSection) Then
		If Not RoomSection.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Section ';ru='Секция ';de='Abschnitt '") + 
			                     TrimAll(RoomSection.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Sections folder ';ru='Группа секций ';de='Abschnittgruppe '") + 
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
			vParamPresentation = vParamPresentation + NStr("en='Rooms folder ';ru='Группа номеров ';de='Zimmergruppe '") + 
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
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
	
	// Initialize report builder query generator attributes
	ReportBuilder.PresentationAdding = PresentationAdditionType.Add;
	
	// Fill report parameters
	ReportBuilder.Parameters.Insert("qPeriod", EndOfDay(PeriodTo));
	ReportBuilder.Parameters.Insert("qPeriodFrom", BegOfDay(PeriodTo));
	ReportBuilder.Parameters.Insert("qPeriodTo", EndOfDay(PeriodTo));
	ReportBuilder.Parameters.Insert("qYesterdayPeriodFrom", BegOfDay(PeriodTo)-24*3600);
	ReportBuilder.Parameters.Insert("qYesterdayPeriodTo", EndOfDay(PeriodTo)-24*3600);
	ReportBuilder.Parameters.Insert("qEmptyDate", '00010101');
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qIsEmptyHotel", Not ValueIsFilled(Hotel));
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qIsEmptyRoom", Not ValueIsFilled(Room));
	ReportBuilder.Parameters.Insert("qRoomSection", RoomSection);
	ReportBuilder.Parameters.Insert("qIsEmptyRoomSection", Not ValueIsFilled(RoomSection));
	ReportBuilder.Parameters.Insert("qExpense", AccumulationRecordType.Expense);
	ReportBuilder.Parameters.Insert("qReceipt", AccumulationRecordType.Receipt);
	ReportBuilder.Parameters.Insert("qRegularCleaning", RegularCleaning);
	ReportBuilder.Parameters.Insert("qRegularCleaningCode", ?(ValueIsFilled(RegularCleaning), RegularCleaning.Code, ""));
	ReportBuilder.Parameters.Insert("qRegularCleaningSortCode", ?(ValueIsFilled(RegularCleaning), RegularCleaning.SortCode, 0));
	ReportBuilder.Parameters.Insert("qRoomStatusAfterEarlyCheckIn", ?(ValueIsFilled(Hotel), Hotel.RoomStatusAfterEarlyCheckIn, Undefined));
	ReportBuilder.Parameters.Insert("qRoomStatusAfterEarlyCheckInIsFilled", ValueIsFilled(?(ValueIsFilled(Hotel), Hotel.RoomStatusAfterEarlyCheckIn, Undefined)));
	ReportBuilder.Parameters.Insert("qCheckOutCleaning", CheckOutCleaning);
	ReportBuilder.Parameters.Insert("qCheckOutCleaningCode", ?(ValueIsFilled(CheckOutCleaning), CheckOutCleaning.Code, ""));
	ReportBuilder.Parameters.Insert("qCheckOutCleaningSortCode", ?(ValueIsFilled(CheckOutCleaning), CheckOutCleaning.SortCode, 0));
	ReportBuilder.Parameters.Insert("qVacantRoomCleaning", VacantRoomCleaning);
	ReportBuilder.Parameters.Insert("qVacantRoomCleaningCode", ?(ValueIsFilled(VacantRoomCleaning), VacantRoomCleaning.Code, ""));
	ReportBuilder.Parameters.Insert("qVacantRoomCleaningSortCode", ?(ValueIsFilled(VacantRoomCleaning), VacantRoomCleaning.SortCode, 0));
	ReportBuilder.Parameters.Insert("qRepairEndCleaning", RepairEndCleaning);
	ReportBuilder.Parameters.Insert("qRepairEndCleaningCode", ?(ValueIsFilled(RepairEndCleaning), RepairEndCleaning.Code, ""));
	ReportBuilder.Parameters.Insert("qRepairEndCleaningSortCode", ?(ValueIsFilled(RepairEndCleaning), RepairEndCleaning.SortCode, 0));
	ReportBuilder.Parameters.Insert("qRoomStatusAfterCheckOut", RoomStatusAfterCheckOut);
	ReportBuilder.Parameters.Insert("qRoomStatusAfterCheckOutIsFilled", ValueIsFilled(RoomStatusAfterCheckOut));
    ReportBuilder.Parameters.Insert("qRegularOperationGroup", RegularOperationGroup);
	ReportBuilder.Parameters.Insert("qShowGuestGroupDescriptionInCustomerColumns", cmCheckUserPermissions("ShowGuestGroupDescriptionInCustomerColumns"));
	ReportBuilder.Parameters.Insert("qEmptyRoomType", Catalogs.RoomTypes.EmptyRef());
	ReportBuilder.Parameters.Insert("qEmptyRoomRate", Catalogs.RoomRates.EmptyRef());
	ReportBuilder.Parameters.Insert("qAccTypeRoom", Enums.AccomodationTypes.Room);
	ReportBuilder.Parameters.Insert("qAccTypeBeds", Enums.AccomodationTypes.Beds);
	vShowMainRoomGuestsOnly = False;
	For Each vReportField In ReportBuilder.SelectedFields Do
		If Find(vReportField.Name, "NumberOfInHouseGuests") > 0 Then
			vShowMainRoomGuestsOnly = True;
			Break;
		EndIf;
	EndDo;
	ReportBuilder.Parameters.Insert("qShowMainRoomGuestsOnly", vShowMainRoomGuestsOnly);
	ReportBuilder.Parameters.Insert("qAccomodationTypeRoom", Enums.AccomodationTypes.Room);
	ReportBuilder.Parameters.Insert("qAccomodationTypeBeds", Enums.AccomodationTypes.Beds);
	ReportBuilder.Parameters.Insert("qShowMainRoomGuestsOnly", ShowMainRoomGuestsOnly);
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
	|	InHouseRecords.Hotel AS Hotel,
	|	InHouseRecords.Room AS Room,
	|	InHouseRecords.Recorder AS Accommodation,
	|	InHouseRecords.Recorder.SortCode AS SortCode,
	|	InHouseRecords.Recorder.Date AS DocDate
	|INTO InHouseRecords
	|FROM
	|	AccumulationRegister.RoomInventory AS InHouseRecords
	|WHERE
	|	InHouseRecords.PeriodFrom < &qPeriodTo
	|	AND InHouseRecords.PeriodTo > &qPeriodFrom
	|	AND InHouseRecords.CheckOutDate > &qPeriodTo
	|	AND InHouseRecords.CheckInDate < &qPeriodFrom
	|	AND (InHouseRecords.Hotel IN HIERARCHY (&qHotel)
	|			OR &qIsEmptyHotel)
	|	AND (InHouseRecords.Room IN HIERARCHY (&qRoom)
	|			OR &qIsEmptyRoom)
	|	AND (InHouseRecords.Room.RoomSection IN HIERARCHY (&qRoomSection)
	|			OR &qIsEmptyRoomSection)
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
	|	ExpectedRecords.CheckInDate <= &qPeriodTo
	|	AND ExpectedRecords.CheckInDate >= &qPeriodFrom
	|	AND (ExpectedRecords.Hotel IN HIERARCHY (&qHotel)
	|			OR &qIsEmptyHotel)
	|	AND (ExpectedRecords.Room IN HIERARCHY (&qRoom)
	|			OR &qIsEmptyRoom)
	|	AND (ExpectedRecords.Room.RoomSection IN HIERARCHY (&qRoomSection)
	|			OR &qIsEmptyRoomSection)
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
	|	CheckedInRecords.PeriodFrom < &qPeriodTo
	|	AND CheckedInRecords.PeriodTo > &qPeriodFrom
	|	AND CheckedInRecords.CheckInDate >= &qPeriodFrom
	|	AND CheckedInRecords.CheckInDate <= &qPeriodTo
	|	AND (CheckedInRecords.Hotel IN HIERARCHY (&qHotel)
	|			OR &qIsEmptyHotel)
	|	AND (CheckedInRecords.Room IN HIERARCHY (&qRoom)
	|			OR &qIsEmptyRoom)
	|	AND (CheckedInRecords.Room.RoomSection IN HIERARCHY (&qRoomSection)
	|			OR &qIsEmptyRoomSection)
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
	|	ExpectedCheckOutRecords.CheckOutDate <= &qPeriodTo
	|	AND ExpectedCheckOutRecords.CheckOutDate >= &qPeriodFrom
	|	AND (ExpectedCheckOutRecords.Hotel IN HIERARCHY (&qHotel)
	|			OR &qIsEmptyHotel)
	|	AND (ExpectedCheckOutRecords.Room IN HIERARCHY (&qRoom)
	|			OR &qIsEmptyRoom)
	|	AND (ExpectedCheckOutRecords.Room.RoomSection IN HIERARCHY (&qRoomSection)
	|			OR &qIsEmptyRoomSection)
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
	|	CheckOutRecords.CheckOutDate <= &qPeriodTo
	|	AND CheckOutRecords.CheckOutDate >= &qPeriodFrom
	|	AND (CheckOutRecords.Hotel IN HIERARCHY (&qHotel)
	|			OR &qIsEmptyHotel)
	|	AND (CheckOutRecords.Room IN HIERARCHY (&qRoom)
	|			OR &qIsEmptyRoom)
	|	AND (CheckOutRecords.Room.RoomSection IN HIERARCHY (&qRoomSection)
	|			OR &qIsEmptyRoomSection)
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
	|	AND (RoomBlockRecords.Room.RoomSection IN HIERARCHY (&qRoomSection)
	|			OR &qIsEmptyRoomSection)
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
	|SELECT DISTINCT
	|	CleaningTasks.Hotel AS Hotel,
	|	CleaningTasks.Room AS Room,
	|	RoomStatusLastChangeRecord.RoomStatus AS RoomStatus,
	|	RoomStatusLastChangeRecord.Period AS RoomStatusChangeTime,
	|	RoomStatusLastChangeRecord.User AS RoomStatusChangeAuthor,
	|	CASE
	|		WHEN CleaningTasks.CheckOutCleaning IS NOT NULL 
	|			THEN CleaningTasks.CheckOutCleaningCode
	|		WHEN CleaningTasks.RegularOperation IS NOT NULL 
	|			THEN CleaningTasks.RegularOperationCode
	|		WHEN CleaningTasks.RegularCleaning IS NOT NULL 
	|			THEN CleaningTasks.RegularCleaningCode
	|		WHEN CleaningTasks.RepairEndCleaning IS NOT NULL 
	|			THEN CleaningTasks.RepairEndCleaningCode
	|		WHEN CleaningTasks.VacantRoomCleaning IS NOT NULL 
	|			THEN CleaningTasks.VacantRoomCleaningCode
	|		WHEN CleaningTasks.RoomStatusOperation IS NOT NULL 
	|			THEN CleaningTasks.RoomStatusOperationCode
	|		ELSE NULL
	|	END AS OperationCode,
	|	CASE
	|		WHEN CleaningTasks.CheckOutCleaning IS NOT NULL 
	|			THEN CleaningTasks.CheckOutCleaning
	|		WHEN CleaningTasks.RegularOperation IS NOT NULL 
	|			THEN CleaningTasks.RegularOperation
	|		WHEN CleaningTasks.RegularCleaning IS NOT NULL 
	|			THEN CleaningTasks.RegularCleaning
	|		WHEN CleaningTasks.RepairEndCleaning IS NOT NULL 
	|			THEN CleaningTasks.RepairEndCleaning
	|		WHEN CleaningTasks.VacantRoomCleaning IS NOT NULL 
	|			THEN CleaningTasks.VacantRoomCleaning
	|		WHEN CleaningTasks.RoomStatusOperation IS NOT NULL 
	|			THEN CleaningTasks.RoomStatusOperation
	|		ELSE NULL
	|	END AS Operation,
	|	CASE
	|		WHEN CleaningTasks.CheckOutCleaning IS NOT NULL 
	|			THEN CleaningTasks.CheckOutCleaningSortCode
	|		WHEN CleaningTasks.RegularOperation IS NOT NULL 
	|			THEN CleaningTasks.RegularOperationSortCode
	|		WHEN CleaningTasks.RegularCleaning IS NOT NULL 
	|			THEN CleaningTasks.RegularCleaningSortCode
	|		WHEN CleaningTasks.RepairEndCleaning IS NOT NULL 
	|			THEN CleaningTasks.RepairEndCleaningSortCode
	|		WHEN CleaningTasks.VacantRoomCleaning IS NOT NULL 
	|			THEN CleaningTasks.VacantRoomCleaningSortCode
	|		WHEN CleaningTasks.RoomStatusOperation IS NOT NULL 
	|			THEN CleaningTasks.RoomStatusOperationSortCode
	|		ELSE NULL
	|	END AS OperationSortCode,
	|	CASE
	|		WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|			THEN CleaningTasks.InHouseAccommodation.ClientType
	|		WHEN CleaningTasks.PlannedCheckedInRecorder IS NOT NULL 
	|			THEN CleaningTasks.PlannedCheckedInRecorder.ClientType
	|		WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|			THEN CleaningTasks.CheckOutAccommodation.ClientType
	|		ELSE NULL
	|	END AS ClientType,
	|	CASE
	|		WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|			THEN CleaningTasks.InHouseGuest.LastName
	|		WHEN CleaningTasks.PlannedCheckedInRecorder IS NOT NULL 
	|			THEN CleaningTasks.PlannedCheckedInGuest.LastName
	|		WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|			THEN CleaningTasks.CheckOutGuest.LastName
	|		WHEN CleaningTasks.SetRoomBlock IS NOT NULL 
	|			THEN CleaningTasks.RoomBlockType.Code
	|		ELSE NULL
	|	END AS LastName,
	|	CASE
	|		WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|			THEN CleaningTasks.InHouseGuest.FirstName
	|		WHEN CleaningTasks.PlannedCheckedInRecorder IS NOT NULL 
	|			THEN CleaningTasks.PlannedCheckedInGuest.FirstName
	|		WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|			THEN CleaningTasks.CheckOutGuest.FirstName
	|		WHEN CleaningTasks.SetRoomBlock IS NOT NULL 
	|			THEN CleaningTasks.RoomBlockType.Description
	|		ELSE NULL
	|	END AS FirstName,
	|	CASE
	|		WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|			THEN CleaningTasks.InHouseGuest.SecondName
	|		WHEN CleaningTasks.PlannedCheckedInRecorder IS NOT NULL 
	|			THEN CleaningTasks.PlannedCheckedInGuest.SecondName
	|		WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|			THEN CleaningTasks.CheckOutGuest.SecondName
	|		WHEN CleaningTasks.SetRoomBlock IS NOT NULL 
	|			THEN CleaningTasks.RoomBlockRemarks
	|		ELSE NULL
	|	END AS SecondName,
	|	CASE
	|		WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|			THEN CleaningTasks.InHouseGuest.Citizenship
	|		WHEN CleaningTasks.PlannedCheckedInRecorder IS NOT NULL 
	|			THEN CleaningTasks.PlannedCheckedInGuest.Citizenship
	|		WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|			THEN CleaningTasks.CheckOutGuest.Citizenship
	|		ELSE NULL
	|	END AS Citizenship,
	|	CASE
	|		WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|			THEN CleaningTasks.InHouseCheckInDate
	|		WHEN CleaningTasks.PlannedCheckedInRecorder IS NOT NULL 
	|			THEN CleaningTasks.PlannedCheckedInCheckInDate
	|		WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|			THEN CleaningTasks.CheckOutCheckInDate
	|		WHEN CleaningTasks.SetRoomBlock IS NOT NULL 
	|			THEN CleaningTasks.RoomBlockStartDate
	|		ELSE NULL
	|	END AS CheckInDate,
	|	CASE
	|		WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|			THEN CleaningTasks.InHouseCheckOutDate
	|		WHEN CleaningTasks.PlannedCheckedInRecorder IS NOT NULL 
	|			THEN CleaningTasks.PlannedCheckedInCheckOutDate
	|		WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|			THEN CleaningTasks.CheckOutCheckOutDate
	|		WHEN CleaningTasks.SetRoomBlock IS NOT NULL 
	|			THEN CleaningTasks.RoomBlockEndDate
	|		ELSE NULL
	|	END AS CheckOutDate,
	|	CleaningTasks.NumberOfGuests AS NumberOfGuests,
	|	CleaningTasks.NumberOfExpectedGuests AS NumberOfExpectedGuests,
	|	CleaningTasks.NumberOfInHouseGuests AS NumberOfInHouseGuests,
	|	CASE
	|		WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|				AND CleaningTasks.InHouseAccommodation.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|			THEN 1
	|		WHEN CleaningTasks.PlannedCheckedInRecorder IS NOT NULL 
	|				AND CleaningTasks.PlannedCheckedInRecorder.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|			THEN 1
	|		WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|				AND CleaningTasks.CheckOutAccommodation.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|			THEN 1
	|		WHEN CleaningTasks.InHouseAccommodation IS NULL
	|				AND CleaningTasks.PlannedCheckedInRecorder IS NULL
	|				AND CleaningTasks.CheckOutAccommodation IS NULL
	|			THEN 1
	|		ELSE 0
	|	END AS NumberOfRooms,
	|	CASE
	|		WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|			THEN ISNULL(CleaningTasks.InHouseAccommodation.AccommodationTemplate.NumberOfAdults, 0)
	|		WHEN CleaningTasks.PlannedCheckedInRecorder IS NOT NULL 
	|			THEN ISNULL(CleaningTasks.PlannedCheckedInRecorder.AccommodationTemplate.NumberOfAdults, 0)
	|		WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|			THEN ISNULL(CleaningTasks.CheckOutAccommodation.AccommodationTemplate.NumberOfAdults, 0)
	|		ELSE 0
	|	END AS NumberOfAdults,
	|	CASE
	|		WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|			THEN ISNULL(CleaningTasks.InHouseAccommodation.AccommodationTemplate.NumberOfTeenagers, 0)
	|		WHEN CleaningTasks.PlannedCheckedInRecorder IS NOT NULL 
	|			THEN ISNULL(CleaningTasks.PlannedCheckedInRecorder.AccommodationTemplate.NumberOfTeenagers, 0)
	|		WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|			THEN ISNULL(CleaningTasks.CheckOutAccommodation.AccommodationTemplate.NumberOfTeenagers, 0)
	|		ELSE 0
	|	END AS NumberOfTeenagers,
	|	CASE
	|		WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|			THEN ISNULL(CleaningTasks.InHouseAccommodation.AccommodationTemplate.NumberOfChildren, 0)
	|		WHEN CleaningTasks.PlannedCheckedInRecorder IS NOT NULL 
	|			THEN ISNULL(CleaningTasks.PlannedCheckedInRecorder.AccommodationTemplate.NumberOfChildren, 0)
	|		WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|			THEN ISNULL(CleaningTasks.CheckOutAccommodation.AccommodationTemplate.NumberOfChildren, 0)
	|		ELSE 0
	|	END AS NumberOfChildren,
	|	CASE
	|		WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|			THEN ISNULL(CleaningTasks.InHouseAccommodation.AccommodationTemplate.NumberOfInfants, 0)
	|		WHEN CleaningTasks.PlannedCheckedInRecorder IS NOT NULL 
	|			THEN ISNULL(CleaningTasks.PlannedCheckedInRecorder.AccommodationTemplate.NumberOfInfants, 0)
	|		WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|			THEN ISNULL(CleaningTasks.CheckOutAccommodation.AccommodationTemplate.NumberOfInfants, 0)
	|		ELSE 0
	|	END AS NumberOfInfants,
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
	|	END AS RoomCondition
	|{SELECT
	|	Hotel.*,
	|	Room.*,
	|	(CAST(CleaningTasks.Room.RoomPropertiesCodes AS STRING(999))) AS RoomPropertiesCodes,
	|	(CAST(CleaningTasks.Room.RoomPropertiesDescriptions AS STRING(999))) AS RoomPropertiesDescriptions,
	|	RoomStatus.*,
	|	RoomStatusChangeTime,
	|	RoomStatusChangeAuthor.*,
	|	(CASE
	|			WHEN CleaningTasks.CheckOutCleaning IS NOT NULL 
	|				THEN CleaningTasks.CheckOutCleaningCode
	|			WHEN CleaningTasks.RegularOperation IS NOT NULL 
	|				THEN CleaningTasks.RegularOperationCode
	|			WHEN CleaningTasks.RegularCleaning IS NOT NULL 
	|				THEN CleaningTasks.RegularCleaningCode
	|			WHEN CleaningTasks.RepairEndCleaning IS NOT NULL 
	|				THEN CleaningTasks.RepairEndCleaningCode
	|			WHEN CleaningTasks.VacantRoomCleaning IS NOT NULL 
	|				THEN CleaningTasks.VacantRoomCleaningCode
	|			WHEN CleaningTasks.RoomStatusOperation IS NOT NULL 
	|				THEN CleaningTasks.RoomStatusOperationCode
	|			ELSE NULL
	|		END) AS OperationCode,
	|	(CASE
	|			WHEN CleaningTasks.CheckOutCleaning IS NOT NULL 
	|				THEN CleaningTasks.CheckOutCleaning
	|			WHEN CleaningTasks.RegularOperation IS NOT NULL 
	|				THEN CleaningTasks.RegularOperation
	|			WHEN CleaningTasks.RegularCleaning IS NOT NULL 
	|				THEN CleaningTasks.RegularCleaning
	|			WHEN CleaningTasks.RepairEndCleaning IS NOT NULL 
	|				THEN CleaningTasks.RepairEndCleaning
	|			WHEN CleaningTasks.VacantRoomCleaning IS NOT NULL 
	|				THEN CleaningTasks.VacantRoomCleaning
	|			WHEN CleaningTasks.RoomStatusOperation IS NOT NULL 
	|				THEN CleaningTasks.RoomStatusOperation
	|			ELSE NULL
	|		END).* AS Operation,
	|	(CASE
	|			WHEN CleaningTasks.CheckOutCleaning IS NOT NULL 
	|				THEN CleaningTasks.CheckOutCleaningSortCode
	|			WHEN CleaningTasks.RegularOperation IS NOT NULL 
	|				THEN CleaningTasks.RegularOperationSortCode
	|			WHEN CleaningTasks.RegularCleaning IS NOT NULL 
	|				THEN CleaningTasks.RegularCleaningSortCode
	|			WHEN CleaningTasks.RepairEndCleaning IS NOT NULL 
	|				THEN CleaningTasks.RepairEndCleaningSortCode
	|			WHEN CleaningTasks.VacantRoomCleaning IS NOT NULL 
	|				THEN CleaningTasks.VacantRoomCleaningSortCode
	|			WHEN CleaningTasks.RoomStatusOperation IS NOT NULL 
	|				THEN CleaningTasks.RoomStatusOperationSortCode
	|			ELSE NULL
	|		END) AS OperationSortCode,
	|	(CASE
	|			WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|				THEN CleaningTasks.InHouseGuest
	|			WHEN CleaningTasks.PlannedCheckedInRecorder IS NOT NULL 
	|				THEN CleaningTasks.PlannedCheckedInGuest
	|			WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|				THEN CleaningTasks.CheckOutGuest
	|			ELSE NULL
	|		END).* AS Guest,
	|	ClientType.* AS ClientType,
	|	LastName AS LastName,
	|	FirstName AS FirstName,
	|	SecondName AS SecondName,
	|	Citizenship.* AS Citizenship,
	|	(CASE
	|			WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|				THEN CleaningTasks.InHouseAccommodation.AccommodationTemplate
	|			WHEN CleaningTasks.PlannedCheckedInRecorder IS NOT NULL 
	|				THEN CleaningTasks.PlannedCheckedInRecorder.AccommodationTemplate
	|			WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|				THEN CleaningTasks.CheckOutAccommodation.AccommodationTemplate
	|			ELSE NULL
	|		END).* AS AccommodationTemplate,
	|	(CASE
	|			WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|				THEN CleaningTasks.InHouseAccommodation.AccommodationType
	|			WHEN CleaningTasks.PlannedCheckedInRecorder IS NOT NULL 
	|				THEN CleaningTasks.PlannedCheckedInRecorder.AccommodationType
	|			WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|				THEN CleaningTasks.CheckOutAccommodation.AccommodationType
	|			ELSE NULL
	|		END).* AS GuestAccommodationType,
	|	CheckInDate AS CheckInDate,
	|	CheckOutDate AS CheckOutDate,
	|	(CASE
	|			WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|				THEN CleaningTasks.InHouseAccommodation
	|			WHEN CleaningTasks.PlannedCheckedInRecorder IS NOT NULL 
	|				THEN CleaningTasks.PlannedCheckedInRecorder
	|			WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|				THEN CleaningTasks.CheckOutAccommodation
	|			ELSE NULL
	|		END).* AS GuestDocument,
	|	CleaningTasks.CheckOutCleaning,
	|	CleaningTasks.RegularCleaning,
	|	CleaningTasks.RepairEndCleaning,
	|	CleaningTasks.VacantRoomCleaning,
	|	CleaningTasks.RegularOperation.*,
	|	CleaningTasks.IsCheckInWaiting,
	|	CleaningTasks.CheckOutCleaningCode,
	|	CleaningTasks.RegularCleaningCode,
	|	CleaningTasks.RepairEndCleaningCode,
	|	CleaningTasks.VacantRoomCleaningCode,
	|	CleaningTasks.RegularOperationCode,
	|	CleaningTasks.InHouseAccommodation.*,
	|	CleaningTasks.InHouseGuest.*,
	|	CleaningTasks.InHouseCheckInDate,
	|	CleaningTasks.InHouseCheckOutDate,
	|	CleaningTasks.InHouseCustomer.* AS Customer,
	|	CleaningTasks.GuestStatus.*,
	|	CleaningTasks.InHouseAccommodationType.*,
	|	(CAST(CleaningTasks.GuestHousekeepingRemarks AS STRING(999))) AS GuestHousekeepingRemarks,
	|	NumberOfGuests AS NumberOfGuests,
	|	NumberOfExpectedGuests AS NumberOfExpectedGuests,
	|	NumberOfInHouseGuests AS NumberOfInHouseGuests,
	|	CleaningTasks.CheckOutAccommodation.*,
	|	CleaningTasks.CheckOutGuest.*,
	|	CleaningTasks.CheckOutCheckInDate,
	|	CleaningTasks.CheckOutCheckOutDate,
	|	CleaningTasks.PlannedCheckedInGuest.*,
	|	CleaningTasks.PlannedCheckedInCheckInDate,
	|	CleaningTasks.PlannedCheckedInCheckOutDate,
	|	CleaningTasks.PlannedCheckedInRecorder.*,
	|	CleaningTasks.SetRoomBlock.*,
	|	CleaningTasks.RoomBlockType.*,
	|	CleaningTasks.RoomBlockRemarks,
	|	CleaningTasks.RoomBlockStartDate,
	|	CleaningTasks.RoomBlockEndDate,
	|	CleaningTasks.RoomType.*,
	|	NumberOfRooms,
	|	NumberOfAdults,
	|	NumberOfTeenagers,
	|	NumberOfChildren,
	|	NumberOfInfants,
	|	RoomCondition}
	|FROM
	|	(SELECT
	|		RoomInventoryBalance.Hotel AS Hotel,
	|		RoomInventoryBalance.Room AS Room,
	|		RoomInventoryBalance.Room.RoomStatus AS RoomStatus,
	|		RoomInventoryBalance.RoomType AS RoomType,
	|		RoomInventoryBalance.TotalRoomsBalance AS TotalRoomsBalance,
	|		RoomInventoryBalance.TotalBedsBalance AS TotalBedsBalance,
	|		InHousePersons.Recorder AS InHouseAccommodation,
	|		InHousePersons.Guest AS InHouseGuest,
	|		InHousePersons.GuestGroup AS InHouseGuestGroup,
	|		CASE
	|			WHEN &qShowGuestGroupDescriptionInCustomerColumns
	|					AND NOT InHousePersons.Recorder IS NULL
	|				THEN InHousePersons.GuestGroup.Description
	|			WHEN NOT &qShowGuestGroupDescriptionInCustomerColumns
	|					AND NOT InHousePersons.Recorder IS NULL
	|				THEN InHousePersons.Customer
	|			ELSE NULL
	|		END AS InHouseCustomer,
	|		InHousePersons.NumberOfPersons AS InHouseNumberOfPersons,
	|		InHousePersons.PeriodFrom AS InHouseCheckInDate,
	|		InHousePersons.PeriodTo AS InHouseCheckOutDate,
	|		InHousePersons.Recorder.AccommodationType AS InHouseAccommodationType,
	|		CASE
	|			WHEN NOT InHousePersons.Recorder IS NULL
	|				THEN InHousePersons.Recorder.AccommodationStatus
	|			WHEN NOT CheckedOutGuests.Recorder IS NULL
	|				THEN CheckedOutGuests.Recorder.AccommodationStatus
	|			ELSE PlannedCheckedIn.Recorder.ReservationStatus
	|		END AS GuestStatus,
	|		CASE
	|			WHEN NOT PlannedCheckedIn.Recorder IS NULL
	|				THEN CAST(PlannedCheckedIn.Recorder.HousekeepingRemarks AS STRING(999))
	|			ELSE CAST(InHousePersons.Recorder.HousekeepingRemarks AS STRING(999))
	|		END AS GuestHousekeepingRemarks,
	|		CASE
	|			WHEN NOT InHousePersonsForCleaning.Recorder IS NULL
	|					AND CheckedOutGuests.Recorder IS NULL
	|					AND (RoomInventoryBalance.Room.RoomStatus <> &qRoomStatusAfterCheckOut
	|						OR NOT &qRoomStatusAfterCheckOutIsFilled)
	|					AND &qRegularCleaning <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN &qRegularCleaning
	|			ELSE NULL
	|		END AS RegularCleaning,
	|		CASE
	|			WHEN NOT InHousePersonsForCleaning.Recorder IS NULL
	|					AND CheckedOutGuests.Recorder IS NULL
	|					AND (RoomInventoryBalance.Room.RoomStatus <> &qRoomStatusAfterCheckOut
	|						OR NOT &qRoomStatusAfterCheckOutIsFilled)
	|					AND &qRegularCleaning <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN &qRegularCleaningCode
	|			ELSE NULL
	|		END AS RegularCleaningCode,
	|		CASE
	|			WHEN NOT InHousePersonsForCleaning.Recorder IS NULL
	|					AND CheckedOutGuests.Recorder IS NULL
	|					AND (RoomInventoryBalance.Room.RoomStatus <> &qRoomStatusAfterCheckOut
	|						OR NOT &qRoomStatusAfterCheckOutIsFilled)
	|					AND &qRegularCleaning <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN &qRegularCleaningSortCode
	|			ELSE NULL
	|		END AS RegularCleaningSortCode,
	|		PlannedCheckedIn.Recorder AS PlannedCheckedInRecorder,
	|		PlannedCheckedIn.Guest AS PlannedCheckedInGuest,
	|		PlannedCheckedIn.NumberOfPersons AS PlannedCheckedInNumberOfPersons,
	|		PlannedCheckedIn.CheckInDate AS PlannedCheckedInCheckInDate,
	|		PlannedCheckedIn.CheckOutDate AS PlannedCheckedInCheckOutDate,
	|		CheckedOutGuests.Recorder AS CheckOutAccommodation,
	|		CheckedOutGuests.Guest AS CheckOutGuest,
	|		CheckedOutGuests.NumberOfPersons AS CheckOutNumberOfPersons,
	|		CheckedOutGuests.CheckInDate AS CheckOutCheckInDate,
	|		CheckedOutGuests.CheckOutDate AS CheckOutCheckOutDate,
	|		CASE
	|			WHEN NOT CheckedOutGuests.Recorder IS NULL
	|					AND &qCheckOutCleaning <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN &qCheckOutCleaning
	|			WHEN RoomInventoryBalance.Room.RoomStatus = &qRoomStatusAfterCheckOut
	|					AND &qRoomStatusAfterCheckOutIsFilled
	|					AND &qCheckOutCleaning <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN &qCheckOutCleaning
	|			ELSE NULL
	|		END AS CheckOutCleaning,
	|		CASE
	|			WHEN NOT CheckedOutGuests.Recorder IS NULL
	|					AND &qCheckOutCleaning <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN &qCheckOutCleaningCode
	|			WHEN RoomInventoryBalance.Room.RoomStatus = &qRoomStatusAfterCheckOut
	|					AND &qRoomStatusAfterCheckOutIsFilled
	|					AND &qCheckOutCleaning <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN &qCheckOutCleaningCode
	|			ELSE NULL
	|		END AS CheckOutCleaningCode,
	|		CASE
	|			WHEN NOT CheckedOutGuests.Recorder IS NULL
	|					AND &qCheckOutCleaning <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN &qCheckOutCleaningSortCode
	|			WHEN RoomInventoryBalance.Room.RoomStatus = &qRoomStatusAfterCheckOut
	|					AND &qRoomStatusAfterCheckOutIsFilled
	|					AND &qCheckOutCleaning <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN &qCheckOutCleaningSortCode
	|			ELSE NULL
	|		END AS CheckOutCleaningSortCode,
	|		FinishedRoomBlocks.Recorder AS SetRoomBlock,
	|		FinishedRoomBlocks.RoomBlockType AS RoomBlockType,
	|		CAST(FinishedRoomBlocks.Remarks AS STRING(999)) AS RoomBlockRemarks,
	|		FinishedRoomBlocks.CheckInDate AS RoomBlockStartDate,
	|		FinishedRoomBlocks.CheckOutDate AS RoomBlockEndDate,
	|		CASE
	|			WHEN NOT FinishedRoomBlocks.Recorder IS NULL
	|					AND &qRepairEndCleaning <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN &qRepairEndCleaning
	|			ELSE NULL
	|		END AS RepairEndCleaning,
	|		CASE
	|			WHEN NOT FinishedRoomBlocks.Recorder IS NULL
	|					AND &qRepairEndCleaning <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN &qRepairEndCleaningCode
	|			ELSE NULL
	|		END AS RepairEndCleaningCode,
	|		CASE
	|			WHEN NOT FinishedRoomBlocks.Recorder IS NULL
	|					AND &qRepairEndCleaning <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN &qRepairEndCleaningSortCode
	|			ELSE NULL
	|		END AS RepairEndCleaningSortCode,
	|		CASE
	|			WHEN CheckedOutGuests.Recorder IS NULL
	|					AND YesterdayCheckedOutGuests.Room IS NULL
	|					AND InHousePersons.Recorder IS NULL
	|					AND CheckedInPersons.Recorder IS NULL
	|					AND CheckedOutGuests.Recorder IS NULL
	|					AND RoomBlocks.Recorder IS NULL
	|					AND (RoomInventoryBalance.Room.RoomStatus <> &qRoomStatusAfterCheckOut
	|						OR NOT &qRoomStatusAfterCheckOutIsFilled)
	|					AND &qVacantRoomCleaning <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN &qVacantRoomCleaning
	|			ELSE NULL
	|		END AS VacantRoomCleaning,
	|		CASE
	|			WHEN CheckedOutGuests.Recorder IS NULL
	|					AND YesterdayCheckedOutGuests.Room IS NULL
	|					AND InHousePersons.Recorder IS NULL
	|					AND CheckedInPersons.Recorder IS NULL
	|					AND CheckedOutGuests.Recorder IS NULL
	|					AND RoomBlocks.Recorder IS NULL
	|					AND (RoomInventoryBalance.Room.RoomStatus <> &qRoomStatusAfterCheckOut
	|						OR NOT &qRoomStatusAfterCheckOutIsFilled)
	|					AND &qVacantRoomCleaning <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN &qVacantRoomCleaningCode
	|			ELSE NULL
	|		END AS VacantRoomCleaningCode,
	|		CASE
	|			WHEN CheckedOutGuests.Recorder IS NULL
	|					AND YesterdayCheckedOutGuests.Room IS NULL
	|					AND InHousePersons.Recorder IS NULL
	|					AND CheckedInPersons.Recorder IS NULL
	|					AND CheckedOutGuests.Recorder IS NULL
	|					AND RoomBlocks.Recorder IS NULL
	|					AND (RoomInventoryBalance.Room.RoomStatus <> &qRoomStatusAfterCheckOut
	|						OR NOT &qRoomStatusAfterCheckOutIsFilled)
	|					AND &qVacantRoomCleaning <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN &qVacantRoomCleaningSortCode
	|			ELSE NULL
	|		END AS VacantRoomCleaningSortCode,
	|		RegularOperations.RegularOperation AS RegularOperation,
	|		CASE
	|			WHEN RegularOperations.RegularOperation IS NOT NULL 
	|				THEN RegularOperations.RegularOperation.Code
	|			ELSE NULL
	|		END AS RegularOperationCode,
	|		CASE
	|			WHEN RegularOperations.RegularOperation IS NOT NULL 
	|				THEN RegularOperations.RegularOperation.SortCode
	|			ELSE NULL
	|		END AS RegularOperationSortCode,
	|		CASE
	|			WHEN PlannedCheckedIn.NumberOfPersons IS NULL
	|				THEN FALSE
	|			ELSE TRUE
	|		END AS IsCheckInWaiting,
	|		PlannedCheckedInGuests.NumberOfPersons AS NumberOfExpectedGuests,
	|		InHouseGuestsTotals.NumberOfPersons AS NumberOfInHouseGuests,
	|		CASE
	|			WHEN InHousePersons.Recorder IS NOT NULL 
	|				THEN InHousePersons.NumberOfPersons
	|			WHEN CheckedOutGuests.Recorder IS NOT NULL 
	|				THEN CheckedOutGuests.NumberOfPersons
	|			ELSE 0
	|		END AS NumberOfGuests,
	|		CASE
	|			WHEN NOT ISNULL(RoomInventoryBalance.Room.RoomStatus.DoEmployeeOperation, TRUE)
	|					AND ISNULL(RoomInventoryBalance.Room.RoomStatus.Operation, VALUE(Catalog.Operations.EmptyRef)) <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN RoomInventoryBalance.Room.RoomStatus.Operation
	|			ELSE NULL
	|		END AS RoomStatusOperation,
	|		CASE
	|			WHEN NOT ISNULL(RoomInventoryBalance.Room.RoomStatus.DoEmployeeOperation, TRUE)
	|					AND ISNULL(RoomInventoryBalance.Room.RoomStatus.Operation, VALUE(Catalog.Operations.EmptyRef)) <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN RoomInventoryBalance.Room.RoomStatus.Operation.Code
	|			ELSE NULL
	|		END AS RoomStatusOperationCode,
	|		CASE
	|			WHEN NOT ISNULL(RoomInventoryBalance.Room.RoomStatus.DoEmployeeOperation, TRUE)
	|					AND ISNULL(RoomInventoryBalance.Room.RoomStatus.Operation, VALUE(Catalog.Operations.EmptyRef)) <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN RoomInventoryBalance.Room.RoomStatus.Operation.SortCode
	|			ELSE NULL
	|		END AS RoomStatusOperationSortCode
	|	FROM
	|		AccumulationRegister.RoomInventory.Balance(
	|				&qPeriodTo,
	|				(Hotel IN HIERARCHY (&qHotel)
	|					OR &qIsEmptyHotel)
	|					AND (Room.RoomSection IN HIERARCHY (&qRoomSection)
	|						OR &qIsEmptyRoomSection)
	|					AND (Room IN HIERARCHY (&qRoom)
	|						OR &qIsEmptyRoom)) AS RoomInventoryBalance
	|			LEFT JOIN (SELECT
	|				InHousePersonRows.Room AS Room,
	|				InHousePersonRows.Recorder AS Recorder,
	|				InHousePersonRows.Guest AS Guest,
	|				InHousePersonRows.GuestGroup AS GuestGroup,
	|				InHousePersonRows.Customer AS Customer,
	|				InHousePersonRows.NumberOfPersons AS NumberOfPersons,
	|				InHousePersonRows.CheckInDate AS CheckInDate,
	|				InHousePersonRows.CheckOutDate AS CheckOutDate,
	|				MIN(InHousePersonRows.PeriodFrom) AS PeriodFrom,
	|				MAX(InHousePersonRows.PeriodTo) AS PeriodTo
	|			FROM
	|				AccumulationRegister.RoomInventory AS InHousePersonRows
	|			WHERE
	|				InHousePersonRows.RecordType = &qExpense
	|				AND InHousePersonRows.IsInHouse
	|				AND InHousePersonRows.IsAccommodation
	|				AND InHousePersonRows.PeriodFrom < &qPeriodTo
	|				AND InHousePersonRows.PeriodTo > &qPeriodFrom
	|				AND InHousePersonRows.Period = InHousePersonRows.PeriodFrom
	|				AND (NOT &qShowMainRoomGuestsOnly
	|						OR &qShowMainRoomGuestsOnly
	|							AND (InHousePersonRows.AccommodationType.Type = &qAccomodationTypeRoom
	|								OR InHousePersonRows.AccommodationType.Type = &qAccomodationTypeBeds))
	|				AND (InHousePersonRows.Hotel IN HIERARCHY (&qHotel)
	|						OR &qIsEmptyHotel)
	|			
	|			GROUP BY
	|				InHousePersonRows.Room,
	|				InHousePersonRows.Recorder,
	|				InHousePersonRows.Guest,
	|				InHousePersonRows.GuestGroup,
	|				InHousePersonRows.Customer,
	|				InHousePersonRows.NumberOfPersons,
	|				InHousePersonRows.CheckInDate,
	|				InHousePersonRows.CheckOutDate) AS InHousePersons
	|			ON RoomInventoryBalance.Room = InHousePersons.Room
	|			LEFT JOIN AccumulationRegister.RoomInventory AS InHousePersonsForCleaning
	|			ON RoomInventoryBalance.Room = InHousePersonsForCleaning.Room
	|				AND (InHousePersonsForCleaning.RecordType = &qExpense)
	|				AND (InHousePersonsForCleaning.IsInHouse)
	|				AND (InHousePersonsForCleaning.IsAccommodation)
	|				AND (InHousePersonsForCleaning.PeriodFrom < &qPeriodFrom
	|					OR &qRoomStatusAfterEarlyCheckInIsFilled
	|						AND BEGINOFPERIOD(InHousePersonsForCleaning.CheckInDate, DAY) = &qPeriodFrom
	|						AND DATEDIFF(&qPeriodFrom, InHousePersonsForCleaning.CheckInDate, MINUTE) < 360)
	|				AND (InHousePersonsForCleaning.PeriodFrom < &qPeriodTo)
	|				AND (InHousePersonsForCleaning.PeriodTo > &qPeriodFrom)
	|				AND (InHousePersonsForCleaning.Period = InHousePersonsForCleaning.PeriodFrom)
	|			LEFT JOIN (SELECT
	|				InHouseGuestsCount.Room AS Room,
	|				SUM(InHouseGuestsCount.NumberOfPersons) AS NumberOfPersons
	|			FROM
	|				AccumulationRegister.RoomInventory AS InHouseGuestsCount
	|			WHERE
	|				InHouseGuestsCount.RecordType = &qExpense
	|				AND InHouseGuestsCount.IsAccommodation
	|				AND InHouseGuestsCount.IsInHouse
	|				AND InHouseGuestsCount.PeriodFrom < &qPeriodTo
	|				AND InHouseGuestsCount.PeriodTo > &qPeriodFrom
	|				AND InHouseGuestsCount.Period = InHouseGuestsCount.PeriodFrom
	|			
	|			GROUP BY
	|				InHouseGuestsCount.Room) AS InHouseGuestsTotals
	|			ON RoomInventoryBalance.Room = InHouseGuestsTotals.Room
	|			LEFT JOIN AccumulationRegister.RoomInventory AS CheckedOutGuests
	|			ON RoomInventoryBalance.Room = CheckedOutGuests.Room
	|				AND (CheckedOutGuests.RecordType = &qReceipt)
	|				AND (CheckedOutGuests.IsCheckOut)
	|				AND (CheckedOutGuests.IsAccommodation)
	|				AND (CheckedOutGuests.CheckOutDate = CheckedOutGuests.Period)
	|				AND (CheckedOutGuests.CheckOutDate = CheckedOutGuests.PeriodTo)
	|				AND (CheckedOutGuests.CheckOutDate > &qPeriodFrom)
	|				AND (CheckedOutGuests.CheckOutDate <= &qPeriodTo)
	|				AND (NOT &qShowMainRoomGuestsOnly
	|						AND (CheckedOutGuests.IsInHouse
	|							OR NOT CheckedOutGuests.IsInHouse
	|								AND (CheckedOutGuests.AccommodationType.Type = &qAccomodationTypeRoom
	|									OR CheckedOutGuests.AccommodationType.Type = &qAccomodationTypeBeds))
	|					OR &qShowMainRoomGuestsOnly
	|						AND (CheckedOutGuests.AccommodationType.Type = &qAccomodationTypeRoom
	|							OR CheckedOutGuests.AccommodationType.Type = &qAccomodationTypeBeds))
	|			LEFT JOIN (SELECT
	|				RoomInventoryYesterdayCheckedOutGuests.Room AS Room
	|			FROM
	|				AccumulationRegister.RoomInventory AS RoomInventoryYesterdayCheckedOutGuests
	|			WHERE
	|				RoomInventoryYesterdayCheckedOutGuests.RecordType = &qReceipt
	|				AND RoomInventoryYesterdayCheckedOutGuests.IsCheckOut
	|				AND RoomInventoryYesterdayCheckedOutGuests.IsAccommodation
	|				AND (RoomInventoryYesterdayCheckedOutGuests.AccommodationType.Type = &qAccTypeRoom
	|						OR RoomInventoryYesterdayCheckedOutGuests.AccommodationType.Type = &qAccTypeBeds)
	|				AND RoomInventoryYesterdayCheckedOutGuests.CheckOutDate = RoomInventoryYesterdayCheckedOutGuests.Period
	|				AND RoomInventoryYesterdayCheckedOutGuests.CheckOutDate > &qYesterdayPeriodFrom
	|				AND RoomInventoryYesterdayCheckedOutGuests.CheckOutDate <= &qYesterdayPeriodTo
	|			
	|			GROUP BY
	|				RoomInventoryYesterdayCheckedOutGuests.Room) AS YesterdayCheckedOutGuests
	|			ON RoomInventoryBalance.Room = YesterdayCheckedOutGuests.Room
	|			LEFT JOIN (SELECT
	|				RoomInventoryLastCheckedOutGuests.Room AS Room,
	|				MAX(RoomInventoryLastCheckedOutGuests.CheckOutDate) AS LastCheckOutDate
	|			FROM
	|				AccumulationRegister.RoomInventory AS RoomInventoryLastCheckedOutGuests
	|			WHERE
	|				RoomInventoryLastCheckedOutGuests.RecordType = &qReceipt
	|				AND RoomInventoryLastCheckedOutGuests.IsAccommodation
	|				AND RoomInventoryLastCheckedOutGuests.IsCheckOut
	|				AND RoomInventoryLastCheckedOutGuests.CheckOutDate = RoomInventoryLastCheckedOutGuests.Period
	|				AND RoomInventoryLastCheckedOutGuests.CheckOutDate <= &qPeriodFrom
	|			
	|			GROUP BY
	|				RoomInventoryLastCheckedOutGuests.Room) AS LastCheckedOutGuests
	|			ON RoomInventoryBalance.Room = LastCheckedOutGuests.Room
	|			LEFT JOIN AccumulationRegister.RoomInventory AS FinishedRoomBlocks
	|			ON RoomInventoryBalance.Room = FinishedRoomBlocks.Room
	|				AND (FinishedRoomBlocks.RecordType = &qExpense)
	|				AND (FinishedRoomBlocks.IsBlocking)
	|				AND (FinishedRoomBlocks.Recorder.DateTo > &qPeriodFrom)
	|				AND (FinishedRoomBlocks.Recorder.DateTo <= &qPeriodTo)
	|				AND (FinishedRoomBlocks.RoomBlockType.IsRoomRepair)
	|				AND (FinishedRoomBlocks.CheckInDate = FinishedRoomBlocks.Period)
	|				AND (FinishedRoomBlocks.CheckInDate = FinishedRoomBlocks.Recorder.DateFrom)
	|			LEFT JOIN AccumulationRegister.RoomInventory AS RoomBlocks
	|			ON RoomInventoryBalance.Room = RoomBlocks.Room
	|				AND (RoomBlocks.RecordType = &qExpense)
	|				AND (RoomBlocks.IsBlocking)
	|				AND (RoomBlocks.Recorder.DateFrom = RoomBlocks.Period)
	|				AND (RoomBlocks.Recorder.DateTo > &qPeriodFrom
	|					OR RoomBlocks.Recorder.DateTo = &qEmptyDate)
	|				AND (RoomBlocks.Recorder.DateFrom < &qPeriodTo)
	|				AND (RoomBlocks.RoomBlockType.IsRoomRepair)
	|				AND (RoomBlocks.CheckInDate = RoomBlocks.Recorder.DateFrom)
	|			LEFT JOIN AccumulationRegister.RoomInventory AS CheckedInPersons
	|			ON RoomInventoryBalance.Room = CheckedInPersons.Room
	|				AND (CheckedInPersons.RecordType = &qExpense)
	|				AND (CheckedInPersons.IsInHouse)
	|				AND (CheckedInPersons.IsAccommodation)
	|				AND (CheckedInPersons.CheckInDate = CheckedInPersons.Period)
	|				AND (CheckedInPersons.CheckInDate >= &qPeriodFrom)
	|				AND (CheckedInPersons.CheckInDate < &qPeriodTo)
	|			LEFT JOIN (SELECT
	|				PlannedCheckedInRows.Recorder AS Recorder,
	|				PlannedCheckedInRows.Customer AS Customer,
	|				PlannedCheckedInRows.GuestGroup AS GuestGroup,
	|				PlannedCheckedInRows.Guest AS Guest,
	|				PlannedCheckedInRows.CheckInDate AS CheckInDate,
	|				PlannedCheckedInRows.CheckOutDate AS CheckOutDate,
	|				PlannedCheckedInRows.Room AS Room,
	|				PlannedCheckedInRows.AccommodationType.Type AS AccommodationTypeType,
	|				SUM(PlannedCheckedInRows.NumberOfPersons) AS NumberOfPersons
	|			FROM
	|				AccumulationRegister.RoomInventory AS PlannedCheckedInRows
	|			WHERE
	|				PlannedCheckedInRows.RecordType = &qExpense
	|				AND PlannedCheckedInRows.IsReservation
	|				AND PlannedCheckedInRows.Period = PlannedCheckedInRows.CheckInDate
	|				AND PlannedCheckedInRows.CheckInDate >= &qPeriodFrom
	|				AND PlannedCheckedInRows.CheckInDate < &qPeriodTo
	|				AND (NOT &qShowMainRoomGuestsOnly
	|						OR &qShowMainRoomGuestsOnly
	|							AND (PlannedCheckedInRows.AccommodationType.Type = &qAccomodationTypeRoom
	|								OR PlannedCheckedInRows.AccommodationType.Type = &qAccomodationTypeBeds))
	|			
	|			GROUP BY
	|				PlannedCheckedInRows.Recorder,
	|				PlannedCheckedInRows.Customer,
	|				PlannedCheckedInRows.GuestGroup,
	|				PlannedCheckedInRows.Guest,
	|				PlannedCheckedInRows.CheckInDate,
	|				PlannedCheckedInRows.CheckOutDate,
	|				PlannedCheckedInRows.Room,
	|				PlannedCheckedInRows.AccommodationType.Type) AS PlannedCheckedIn
	|			ON RoomInventoryBalance.Room = PlannedCheckedIn.Room
	|				AND (NOT &qShowMainRoomGuestsOnly
	|						AND (InHousePersons.Recorder IS NULL
	|							OR NOT InHousePersons.Recorder IS NULL
	|								AND (PlannedCheckedIn.AccommodationTypeType = &qAccomodationTypeRoom
	|									OR PlannedCheckedIn.AccommodationTypeType = &qAccomodationTypeBeds))
	|					OR &qShowMainRoomGuestsOnly)
	|			LEFT JOIN (SELECT
	|				PlannedCheckedInGuests.Room AS Room,
	|				SUM(PlannedCheckedInGuests.NumberOfPersons) AS NumberOfPersons
	|			FROM
	|				AccumulationRegister.RoomInventory AS PlannedCheckedInGuests
	|			WHERE
	|				PlannedCheckedInGuests.RecordType = &qExpense
	|				AND PlannedCheckedInGuests.IsReservation
	|				AND PlannedCheckedInGuests.Period = PlannedCheckedInGuests.CheckInDate
	|				AND PlannedCheckedInGuests.CheckInDate >= &qPeriodFrom
	|				AND PlannedCheckedInGuests.CheckInDate < &qPeriodTo
	|			
	|			GROUP BY
	|				PlannedCheckedInGuests.Room) AS PlannedCheckedInGuests
	|			ON RoomInventoryBalance.Room = PlannedCheckedInGuests.Room
	|			LEFT JOIN Catalog.RegularOperationGroups.RegularOperations AS RegularOperations
	|			ON (RegularOperations.Ref = &qRegularOperationGroup)
	|				AND (RegularOperations.PerformWhenRoomIsBusy
	|						AND InHousePersons.Recorder IS NOT NULL 
	|						AND DATEDIFF(&qPeriodFrom, BEGINOFPERIOD(InHousePersons.PeriodFrom, DAY), DAY) / RegularOperations.RegularOperationFrequency = (CAST(DATEDIFF(&qPeriodFrom, BEGINOFPERIOD(InHousePersons.PeriodFrom, DAY), DAY) / RegularOperations.RegularOperationFrequency AS NUMBER(17, 0)))
	|						AND (&qPeriodFrom = BEGINOFPERIOD(InHousePersons.PeriodFrom, DAY)
	|								AND RegularOperations.PerformOnCheckInDay
	|							OR &qPeriodFrom = BEGINOFPERIOD(InHousePersons.PeriodTo, DAY)
	|								AND RegularOperations.PerformOnCheckOutDay
	|							OR &qPeriodFrom > BEGINOFPERIOD(InHousePersons.PeriodFrom, DAY)
	|								AND &qPeriodFrom < BEGINOFPERIOD(InHousePersons.PeriodTo, DAY)
	|								AND NOT RegularOperations.PerformOnCheckInDay
	|								AND NOT RegularOperations.PerformOnCheckOutDay)
	|					OR RegularOperations.PerformWhenRoomIsBusy
	|						AND RegularOperations.PerformOnCheckInDay
	|						AND CheckedInPersons.Recorder IS NOT NULL 
	|					OR RegularOperations.PerformWhenRoomIsBusy
	|						AND RegularOperations.PerformOnCheckOutDay
	|						AND CheckedOutGuests.Recorder IS NOT NULL 
	|					OR RegularOperations.PerformWhenRoomIsFree
	|						AND InHousePersons.Recorder IS NULL
	|						AND CheckedInPersons.Recorder IS NULL
	|						AND CheckedOutGuests.Recorder IS NULL
	|						AND (RegularOperations.RegularOperationFrequency = 0
	|							OR RegularOperations.RegularOperationFrequency = 1
	|							OR RegularOperations.RegularOperationFrequency > 1
	|								AND DATEDIFF(&qPeriodFrom, BEGINOFPERIOD(LastCheckedOutGuests.LastCheckOutDate, DAY), DAY) / RegularOperations.RegularOperationFrequency = (CAST(DATEDIFF(&qPeriodFrom, BEGINOFPERIOD(LastCheckedOutGuests.LastCheckOutDate, DAY), DAY) / RegularOperations.RegularOperationFrequency AS NUMBER(17, 0)))
	|								AND DATEDIFF(&qPeriodFrom, BEGINOFPERIOD(LastCheckedOutGuests.LastCheckOutDate, DAY), DAY) <> 0))
	|				AND (NOT RegularOperations.DoNotPerformOnWeekends
	|					OR RegularOperations.DoNotPerformOnWeekends
	|						AND WEEKDAY(&qPeriodFrom) < 6)
	|				AND (RegularOperations.RoomType = &qEmptyRoomType
	|					OR RegularOperations.RoomType <> &qEmptyRoomType
	|						AND RoomInventoryBalance.RoomType = RegularOperations.RoomType
	|					OR RegularOperations.RoomType <> &qEmptyRoomType
	|						AND RoomInventoryBalance.RoomType.Parent <> &qEmptyRoomType
	|						AND RoomInventoryBalance.RoomType.Parent = RegularOperations.RoomType)
	|				AND (RegularOperations.RoomRate = &qEmptyRoomRate
	|					OR RegularOperations.RoomRate <> &qEmptyRoomRate
	|						AND NOT InHousePersons.Recorder.RoomRate IS NULL
	|						AND InHousePersons.Recorder.RoomRate <> &qEmptyRoomRate
	|						AND (InHousePersons.Recorder.RoomRate = RegularOperations.RoomRate
	|							OR InHousePersons.Recorder.RoomRate.Parent = RegularOperations.RoomRate
	|							OR InHousePersons.Recorder.RoomRate.Parent.Parent = RegularOperations.RoomRate))
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
	|		0,
	|		0,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		0,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		"""",
	|		CASE
	|			WHEN VirtualRooms.RoomStatus = &qRoomStatusAfterCheckOut
	|					AND &qRoomStatusAfterCheckOutIsFilled
	|					AND &qCheckOutCleaning <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN &qCheckOutCleaning
	|			ELSE NULL
	|		END,
	|		CASE
	|			WHEN VirtualRooms.RoomStatus = &qRoomStatusAfterCheckOut
	|					AND &qRoomStatusAfterCheckOutIsFilled
	|					AND &qCheckOutCleaning <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN &qCheckOutCleaningCode
	|			ELSE NULL
	|		END,
	|		CASE
	|			WHEN VirtualRooms.RoomStatus = &qRoomStatusAfterCheckOut
	|					AND &qRoomStatusAfterCheckOutIsFilled
	|					AND &qCheckOutCleaning <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN &qCheckOutCleaningSortCode
	|			ELSE NULL
	|		END,
	|		NULL,
	|		NULL,
	|		0,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		0,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		"""",
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
	|		FALSE,
	|		0,
	|		0,
	|		0,
	|		CASE
	|			WHEN NOT ISNULL(VirtualRooms.RoomStatus.DoEmployeeOperation, TRUE)
	|					AND ISNULL(VirtualRooms.RoomStatus.Operation, VALUE(Catalog.Operations.EmptyRef)) <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN VirtualRooms.RoomStatus.Operation
	|			ELSE NULL
	|		END,
	|		CASE
	|			WHEN NOT ISNULL(VirtualRooms.RoomStatus.DoEmployeeOperation, TRUE)
	|					AND ISNULL(VirtualRooms.RoomStatus.Operation, VALUE(Catalog.Operations.EmptyRef)) <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN VirtualRooms.RoomStatus.Operation.Code
	|			ELSE NULL
	|		END,
	|		CASE
	|			WHEN NOT ISNULL(VirtualRooms.RoomStatus.DoEmployeeOperation, TRUE)
	|					AND ISNULL(VirtualRooms.RoomStatus.Operation, VALUE(Catalog.Operations.EmptyRef)) <> VALUE(Catalog.Operations.EmptyRef)
	|				THEN VirtualRooms.RoomStatus.Operation.SortCode
	|			ELSE NULL
	|		END
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
	|		AND (VirtualRooms.RoomSection IN HIERARCHY (&qRoomSection)
	|				OR &qIsEmptyRoomSection)
	|		AND (VirtualRooms.Ref IN HIERARCHY (&qRoom)
	|				OR &qIsEmptyRoom)) AS CleaningTasks
	|		LEFT JOIN InHouseGuests AS InHouseGuests
	|		ON CleaningTasks.Room = InHouseGuests.Room
	|		LEFT JOIN ExpectedGuests AS ExpectedGuests
	|		ON CleaningTasks.Room = ExpectedGuests.Room
	|		LEFT JOIN CheckedInGuests AS CheckedInGuests
	|		ON CleaningTasks.Room = CheckedInGuests.Room
	|		LEFT JOIN ExpectedCheckOutGuests AS ExpectedCheckOutGuests
	|		ON CleaningTasks.Room = ExpectedCheckOutGuests.Room
	|		LEFT JOIN CheckOutGuests AS CheckOutGuests
	|		ON CleaningTasks.Room = CheckOutGuests.Room
	|		LEFT JOIN RoomBlocks AS RoomBlocks
	|		ON CleaningTasks.Room = RoomBlocks.Room
	|		LEFT JOIN (SELECT
	|			RoomStatusChangeHistory.Period AS Period,
	|			RoomStatusChangeHistory.User AS User,
	|			RoomStatusChangeHistory.Room AS Room,
	|			RoomStatusChangeHistory.RoomStatus AS RoomStatus
	|		FROM
	|			InformationRegister.RoomStatusChangeHistory AS RoomStatusChangeHistory
	|				INNER JOIN InformationRegister.RoomStatusChangeHistory.SliceLast(
	|						&qPeriod,
	|						(Room.Owner IN HIERARCHY (&qHotel)
	|							OR &qIsEmptyHotel)
	|							AND (Room.RoomSection IN HIERARCHY (&qRoomSection)
	|								OR &qIsEmptyRoomSection)
	|							AND (Room IN HIERARCHY (&qRoom)
	|								OR &qIsEmptyRoom)) AS RoomStatusChangeHistorySliceLast
	|				ON RoomStatusChangeHistory.Period = RoomStatusChangeHistorySliceLast.Period
	|					AND RoomStatusChangeHistory.Room = RoomStatusChangeHistorySliceLast.Room) AS RoomStatusLastChangeRecord
	|		ON CleaningTasks.Room = RoomStatusLastChangeRecord.Room
	|WHERE
	|	(NOT &qShowMainRoomGuestsOnly
	|			OR &qShowMainRoomGuestsOnly
	|				AND CASE
	|					WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|							AND CleaningTasks.InHouseAccommodation.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|						THEN TRUE
	|					WHEN CleaningTasks.PlannedCheckedInRecorder IS NOT NULL 
	|							AND CleaningTasks.PlannedCheckedInRecorder.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|						THEN TRUE
	|					WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|							AND CleaningTasks.CheckOutAccommodation.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|						THEN TRUE
	|					WHEN CleaningTasks.InHouseAccommodation IS NULL
	|							AND CleaningTasks.PlannedCheckedInRecorder IS NULL
	|							AND CleaningTasks.CheckOutAccommodation IS NULL
	|						THEN TRUE
	|					ELSE FALSE
	|				END)
	|{WHERE
	|	CleaningTasks.Hotel.*,
	|	CleaningTasks.Room.*,
	|	(CAST(CleaningTasks.Room.RoomPropertiesCodes AS STRING(999))) AS RoomPropertiesCodes,
	|	(CAST(CleaningTasks.Room.RoomPropertiesDescriptions AS STRING(999))) AS RoomPropertiesDescriptions,
	|	CleaningTasks.RoomStatus.*,
	|	CleaningTasks.CheckOutCleaning,
	|	CleaningTasks.CheckOutGuest.*,
	|	CleaningTasks.CheckOutCheckInDate,
	|	CleaningTasks.CheckOutCheckOutDate,
	|	CleaningTasks.CheckOutAccommodation.*,
	|	CleaningTasks.CheckOutGuest.*,
	|	CleaningTasks.RegularCleaning,
	|	(CASE
	|			WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|				THEN CleaningTasks.InHouseGuest
	|			WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|				THEN CleaningTasks.CheckOutGuest
	|			WHEN CleaningTasks.PlannedCheckedInRecorder IS NOT NULL 
	|				THEN CleaningTasks.PlannedCheckedInGuest
	|			ELSE NULL
	|		END).* AS Guest,
	|	(CASE
	|			WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|				THEN CleaningTasks.InHouseAccommodation
	|			WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|				THEN CleaningTasks.CheckOutAccommodation
	|			WHEN CleaningTasks.PlannedCheckedInRecorder IS NOT NULL 
	|				THEN CleaningTasks.PlannedCheckedInRecorder
	|			ELSE NULL
	|		END).* AS GuestDocument,
	|	(CASE
	|			WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|				THEN CleaningTasks.InHouseAccommodation.AccommodationTemplate
	|			WHEN CleaningTasks.PlannedCheckedInRecorder IS NOT NULL 
	|				THEN CleaningTasks.PlannedCheckedInRecorder.AccommodationTemplate
	|			WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|				THEN CleaningTasks.CheckOutAccommodation.AccommodationTemplate
	|			ELSE NULL
	|		END).* AS AccommodationTemplate,
	|	(CASE
	|			WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|				THEN CleaningTasks.InHouseAccommodation.AccommodationType
	|			WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|				THEN CleaningTasks.CheckOutAccommodation.AccommodationType
	|			WHEN CleaningTasks.PlannedCheckedInRecorder IS NOT NULL 
	|				THEN CleaningTasks.PlannedCheckedInRecorder.AccommodationType
	|			ELSE NULL
	|		END).* AS GuestAccommodationType,
	|	(CASE
	|			WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|				THEN CleaningTasks.InHouseAccommodation.ClientType
	|			WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|				THEN CleaningTasks.CheckOutAccommodation.ClientType
	|			WHEN CleaningTasks.PlannedCheckedInRecorder IS NOT NULL 
	|				THEN CleaningTasks.PlannedCheckedInRecorder.ClientType
	|			ELSE NULL
	|		END).* AS ClientType,
	|	(CASE
	|			WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|				THEN CleaningTasks.InHouseGuest.LastName
	|			WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|				THEN CleaningTasks.CheckOutGuest.LastName
	|			WHEN CleaningTasks.PlannedCheckedInRecorder IS NOT NULL 
	|				THEN CleaningTasks.PlannedCheckedInGuest.LastName
	|			WHEN CleaningTasks.SetRoomBlock IS NOT NULL 
	|				THEN CleaningTasks.RoomBlockType.Code
	|			ELSE NULL
	|		END) AS LastName,
	|	(CASE
	|			WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|				THEN CleaningTasks.InHouseGuest.FirstName
	|			WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|				THEN CleaningTasks.CheckOutGuest.FirstName
	|			WHEN CleaningTasks.PlannedCheckedInRecorder IS NOT NULL 
	|				THEN CleaningTasks.PlannedCheckedInGuest.FirstName
	|			WHEN CleaningTasks.SetRoomBlock IS NOT NULL 
	|				THEN CleaningTasks.RoomBlockType.Description
	|			ELSE NULL
	|		END) AS FirstName,
	|	(CASE
	|			WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|				THEN CleaningTasks.InHouseGuest.SecondName
	|			WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|				THEN CleaningTasks.CheckOutGuest.SecondName
	|			WHEN CleaningTasks.PlannedCheckedInRecorder IS NOT NULL 
	|				THEN CleaningTasks.PlannedCheckedInGuest.SecondName
	|			WHEN CleaningTasks.SetRoomBlock IS NOT NULL 
	|				THEN CleaningTasks.RoomBlockRemarks
	|			ELSE NULL
	|		END) AS SecondName,
	|	(CASE
	|			WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|				THEN CleaningTasks.InHouseGuest.Citizenship
	|			WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|				THEN CleaningTasks.CheckOutGuest.Citizenship
	|			WHEN CleaningTasks.PlannedCheckedInRecorder IS NOT NULL 
	|				THEN CleaningTasks.PlannedCheckedInGuest.Citizenship
	|			ELSE NULL
	|		END).* AS Citizenship,
	|	(CASE
	|			WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|				THEN CleaningTasks.InHouseCheckInDate
	|			WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|				THEN CleaningTasks.CheckOutCheckInDate
	|			WHEN CleaningTasks.PlannedCheckedInRecorder IS NOT NULL 
	|				THEN CleaningTasks.PlannedCheckedInCheckInDate
	|			WHEN CleaningTasks.SetRoomBlock IS NOT NULL 
	|				THEN CleaningTasks.RoomBlockStartDate
	|			ELSE NULL
	|		END) AS CheckInDate,
	|	(CASE
	|			WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|				THEN CleaningTasks.InHouseCheckOutDate
	|			WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|				THEN CleaningTasks.CheckOutCheckOutDate
	|			WHEN CleaningTasks.PlannedCheckedInRecorder IS NOT NULL 
	|				THEN CleaningTasks.PlannedCheckedInCheckOutDate
	|			WHEN CleaningTasks.SetRoomBlock IS NOT NULL 
	|				THEN CleaningTasks.RoomBlockEndDate
	|			ELSE NULL
	|		END) AS CheckOutDate,
	|	CleaningTasks.IsCheckInWaiting,
	|	CleaningTasks.InHouseGuest.*,
	|	CleaningTasks.InHouseCheckInDate,
	|	CleaningTasks.InHouseCheckOutDate,
	|	CleaningTasks.InHouseAccommodation.*,
	|	CleaningTasks.PlannedCheckedInGuest.*,
	|	CleaningTasks.PlannedCheckedInCheckInDate,
	|	CleaningTasks.PlannedCheckedInCheckOutDate,
	|	CleaningTasks.PlannedCheckedInRecorder.*,
	|	CleaningTasks.SetRoomBlock.*,
	|	CleaningTasks.RoomBlockType.*,
	|	CleaningTasks.RoomBlockRemarks,
	|	CleaningTasks.RoomBlockStartDate,
	|	CleaningTasks.RoomBlockEndDate,
	|	CleaningTasks.RepairEndCleaning,
	|	CleaningTasks.VacantRoomCleaning,
	|	CleaningTasks.RegularOperation,
	|	CleaningTasks.RoomType.*,
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
	|		END) AS RoomCondition}
	|
	|ORDER BY
	|	Hotel,
	|	Room
	|{ORDER BY
	|	Hotel.*,
	|	Room.*,
	|	(CAST(CleaningTasks.Room.RoomPropertiesCodes AS STRING(999))) AS RoomPropertiesCodes,
	|	(CAST(CleaningTasks.Room.RoomPropertiesDescriptions AS STRING(999))) AS RoomPropertiesDescriptions,
	|	RoomStatus.*,
	|	CleaningTasks.CheckOutCleaning,
	|	CleaningTasks.CheckOutCleaningCode,
	|	CleaningTasks.CheckOutCleaningSortCode,
	|	CleaningTasks.CheckOutGuest.*,
	|	CleaningTasks.CheckOutCheckInDate,
	|	CleaningTasks.CheckOutCheckOutDate,
	|	CleaningTasks.PlannedCheckedInGuest.*,
	|	CleaningTasks.PlannedCheckedInCheckInDate,
	|	CleaningTasks.PlannedCheckedInCheckOutDate,
	|	CleaningTasks.PlannedCheckedInRecorder.*,
	|	CleaningTasks.RegularCleaning,
	|	CleaningTasks.RegularCleaningCode,
	|	CleaningTasks.RegularCleaningSortCode,
	|	CleaningTasks.InHouseGuest.*,
	|	CleaningTasks.InHouseCheckInDate,
	|	CleaningTasks.InHouseCheckOutDate,
	|	CleaningTasks.GuestStatus.*,
	|	CleaningTasks.InHouseAccommodationType.*,
	|	CleaningTasks.RepairEndCleaning,
	|	CleaningTasks.RepairEndCleaningCode,
	|	CleaningTasks.RepairEndCleaningSortCode,
	|	CleaningTasks.RoomBlockType.*,
	|	CleaningTasks.RoomBlockRemarks,
	|	CleaningTasks.RoomBlockStartDate,
	|	CleaningTasks.RoomBlockEndDate,
	|	CleaningTasks.VacantRoomCleaning,
	|	CleaningTasks.VacantRoomCleaningCode,
	|	CleaningTasks.VacantRoomCleaningSortCode,
	|	CleaningTasks.RegularOperation,
	|	CleaningTasks.RegularOperationCode,
	|	CleaningTasks.RegularOperationSortCode,
	|	CleaningTasks.RoomType.*,
	|	CleaningTasks.InHouseAccommodation.*,
	|	CleaningTasks.CheckOutAccommodation.*,
	|	CleaningTasks.CheckOutGuest.*,
	|	CleaningTasks.SetRoomBlock.*,
	|	(CASE
	|			WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|				THEN CleaningTasks.InHouseGuest
	|			WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|				THEN CleaningTasks.CheckOutGuest
	|			WHEN CleaningTasks.PlannedCheckedInRecorder IS NOT NULL 
	|				THEN CleaningTasks.PlannedCheckedInGuest
	|			ELSE NULL
	|		END).* AS Guest,
	|	(CASE
	|			WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|				THEN CleaningTasks.InHouseAccommodation
	|			WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|				THEN CleaningTasks.CheckOutAccommodation
	|			WHEN CleaningTasks.PlannedCheckedInRecorder IS NOT NULL 
	|				THEN CleaningTasks.PlannedCheckedInRecorder
	|			ELSE NULL
	|		END).* AS GuestDocument,
	|	(CASE
	|			WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|				THEN CleaningTasks.InHouseAccommodation.AccommodationTemplate
	|			WHEN CleaningTasks.PlannedCheckedInRecorder IS NOT NULL 
	|				THEN CleaningTasks.PlannedCheckedInRecorder.AccommodationTemplate
	|			WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|				THEN CleaningTasks.CheckOutAccommodation.AccommodationTemplate
	|			ELSE NULL
	|		END).* AS AccommodationTemplate,
	|	(CASE
	|			WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|				THEN CleaningTasks.InHouseAccommodation.AccommodationType
	|			WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|				THEN CleaningTasks.CheckOutAccommodation.AccommodationType
	|			WHEN CleaningTasks.PlannedCheckedInRecorder IS NOT NULL 
	|				THEN CleaningTasks.PlannedCheckedInRecorder.AccommodationType
	|			ELSE NULL
	|		END).* AS GuestAccommodationType,
	|	Operation.*,
	|	OperationCode,
	|	OperationSortCode,
	|	CleaningTasks.IsCheckInWaiting,
	|	LastName,
	|	FirstName,
	|	SecondName,
	|	Citizenship.*,
	|	CheckInDate,
	|	CheckOutDate,
	|	RoomCondition}
	|TOTALS
	|	SUM(NumberOfGuests),
	|	SUM(NumberOfRooms),
	|	SUM(NumberOfAdults),
	|	SUM(NumberOfTeenagers),
	|	SUM(NumberOfChildren),
	|	SUM(NumberOfInfants)
	|BY
	|	OVERALL,
	|	Hotel,
	|	Room
	|{TOTALS BY
	|	Hotel.*,
	|	Room.*,
	|	RoomStatus.*,
	|	(CAST(CleaningTasks.Room.RoomPropertiesCodes AS STRING(999))) AS RoomPropertiesCodes,
	|	(CAST(CleaningTasks.Room.RoomPropertiesDescriptions AS STRING(999))) AS RoomPropertiesDescriptions,
	|	CleaningTasks.CheckOutGuest.*,
	|	CleaningTasks.CheckOutCleaning,
	|	CleaningTasks.InHouseGuest.*,
	|	CleaningTasks.RegularCleaning,
	|	CleaningTasks.RepairEndCleaning,
	|	CleaningTasks.VacantRoomCleaning,
	|	CleaningTasks.RegularOperation,
	|	CleaningTasks.RoomBlockType.*,
	|	CleaningTasks.InHouseAccommodation.*,
	|	CleaningTasks.CheckOutAccommodation.*,
	|	CleaningTasks.SetRoomBlock.*,
	|	ClientType.* AS ClientType,
	|	(CASE
	|			WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|				THEN CleaningTasks.InHouseGuest
	|			WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|				THEN CleaningTasks.CheckOutGuest
	|			WHEN CleaningTasks.PlannedCheckedInRecorder IS NOT NULL 
	|				THEN CleaningTasks.PlannedCheckedInGuest
	|			ELSE NULL
	|		END).* AS Guest,
	|	(CASE
	|			WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|				THEN CleaningTasks.InHouseAccommodation
	|			WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|				THEN CleaningTasks.CheckOutAccommodation
	|			WHEN CleaningTasks.PlannedCheckedInRecorder IS NOT NULL 
	|				THEN CleaningTasks.PlannedCheckedInRecorder
	|			ELSE NULL
	|		END).* AS GuestDocument,
	|	(CASE
	|			WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|				THEN CleaningTasks.InHouseAccommodation.AccommodationTemplate
	|			WHEN CleaningTasks.PlannedCheckedInRecorder IS NOT NULL 
	|				THEN CleaningTasks.PlannedCheckedInRecorder.AccommodationTemplate
	|			WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|				THEN CleaningTasks.CheckOutAccommodation.AccommodationTemplate
	|			ELSE NULL
	|		END).* AS AccommodationTemplate,
	|	(CASE
	|			WHEN CleaningTasks.InHouseAccommodation IS NOT NULL 
	|				THEN CleaningTasks.InHouseAccommodation.AccommodationType
	|			WHEN CleaningTasks.CheckOutAccommodation IS NOT NULL 
	|				THEN CleaningTasks.CheckOutAccommodation.AccommodationType
	|			WHEN CleaningTasks.PlannedCheckedInRecorder IS NOT NULL 
	|				THEN CleaningTasks.PlannedCheckedInRecorder.AccommodationType
	|			ELSE NULL
	|		END).* AS GuestAccommodationType,
	|	Operation}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Cleaning task';RU='Задание на уборку';de='Aufgabe der Reinigung'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
