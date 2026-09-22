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
	vOccupiedRoomStatus = Catalogs.RoomStatuses.EmptyRef();
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(Hotel) Then
		vOccupiedRoomStatus = Hotel.OccupiedRoomStatus;
	EndIf;
	If Not ValueIsFilled(PeriodTo) Then
		PeriodTo = CurrentSessionDate();
	EndIf;
	If RoomStatuses.Count() = 0 Then
		vAllStatuses = cmGetAllRoomStatuses();
		For Each vStatusRow In vAllStatuses Do
			If ValueIsFilled(vOccupiedRoomStatus) And 
			   vOccupiedRoomStatus = vStatusRow.RoomStatus Then
				RoomStatuses.Add(vStatusRow.RoomStatus, TrimAll(vStatusRow.RoomStatus), False, cmGetRoomStatusIcon(vStatusRow.RoomStatus));
			Else
				RoomStatuses.Add(vStatusRow.RoomStatus, TrimAll(vStatusRow.RoomStatus), True, cmGetRoomStatusIcon(vStatusRow.RoomStatus));
			EndIf;
		EndDo;
		RoomStatuses.Add(Catalogs.RoomStatuses.EmptyRef(), NStr("en='<Empty status>';ru='<Пустой статус>';de='<Leerer Status>'"), True, cmGetRoomStatusIcon(Catalogs.RoomStatuses.EmptyRef()));
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetReportParametersPresentation() Export
	vParamPresentation = "";
	If ValueIsFilled(Hotel) Then
		If Not Hotel.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Hotel ';ru='Гостиница ';de='Hotel'") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Hotels folder ';ru='Группа гостиниц ';de='Gruppe Hotels '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If Not ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("en='Report period is not set';ru='Период отчета не установлен';de='Berichtszeitraum nicht festgelegt'") + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("ru = 'Период '; en = 'Period '") + 
		                     Format(PeriodTo, "DF='dd.MM.yyyy HH:mm:ss'") + 
		                     ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(Room) Then
		If Not Room.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Room ';ru='Номер ';de='Zimmer'") + 
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
			vParamPresentation = vParamPresentation + NStr("en='Room type ';ru='Тип номера ';de='Zimmertyp'") + 
			                     TrimAll(RoomType.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Room types folder ';ru='Группа типов номеров ';de='Gruppe Zimmertypen'") + 
			                     TrimAll(RoomType.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ShowReservedRooms Then
		vParamPresentation = vParamPresentation + NStr("en='Show reserved rooms';ru='Показываются зарезервированные номера';de='Reservierte Zimmer werden angezeigt'") + 
							 ";" + Chars.LF;
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
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qPeriodToMinusDay", PeriodTo - 24*3600);
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qIsEmptyRoomStatuses", ?(RoomStatuses.Count() = 0, True, False));
	vRoomStatuses = New ValueList();
	For Each vItem In RoomStatuses Do
		If vItem.Check Then
			vRoomStatuses.Add(vItem.Value);
		EndIf;
	EndDo;
	ReportBuilder.Parameters.Insert("qRoomStatuses", vRoomStatuses);
	ReportBuilder.Parameters.Insert("qShowReservedRooms", ShowReservedRooms);

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
	
	// Add guests from occupied rooms to room folders
	vQryGuests = New Query();
	vQryGuests.Text = 
	"SELECT
	|	RoomInventory.Room AS Room,
	|	RoomInventory.IsReservation AS IsReservation,
	|	RoomInventory.Guest.Citizenship.ISOCode AS GuestCitizenship,
	|	RoomInventory.Guest.Sex AS GuestSex,
	|	COUNT(*) AS GuestCount,
	|	RoomInventory.Room.SortCode AS SortCode
	|FROM (
	|	SELECT
	|		RoomInventoryRecorders.Room AS Room,
	|		RoomInventoryRecorders.IsReservation AS IsReservation,
	|		RoomInventoryRecorders.Guest AS Guest,
	|		RoomInventoryRecorders.Recorder AS Recorder
	|	FROM
	|		AccumulationRegister.RoomInventory AS RoomInventoryRecorders
	|	WHERE " +
			?(ValueIsFilled(Hotel), "RoomInventoryRecorders.Hotel IN HIERARCHY(&qHotel)", "TRUE") + "
	|		AND RoomInventoryRecorders.RecordType = &qExpense
	|		AND RoomInventoryRecorders.PeriodFrom <= &qDateTo
	|		AND RoomInventoryRecorders.PeriodTo > &qDateTo
	|		AND (RoomInventoryRecorders.IsReservation OR RoomInventoryRecorders.IsAccommodation)
	|	GROUP BY
	|		RoomInventoryRecorders.Room,
	|		RoomInventoryRecorders.IsReservation,
	|		RoomInventoryRecorders.Guest,
	|		RoomInventoryRecorders.Recorder) AS RoomInventory
	|GROUP BY
	|	RoomInventory.Room,
	|	RoomInventory.IsReservation,
	|	RoomInventory.Guest.Citizenship.ISOCode,
	|	RoomInventory.Guest.Sex
	|ORDER BY
	|	SortCode
	|TOTALS
	|	SUM(GuestCount)
	|BY
	|	IsReservation, GuestCitizenship, GuestSex, Room HIERARCHY";
	vQryGuests.SetParameter("qHotel", Hotel);
	vQryGuests.SetParameter("qExpense", AccumulationRecordType.Expense);
	vQryGuests.SetParameter("qDateTo", PeriodTo);
	vGuests = vQryGuests.Execute().Unload();
	// Group by all dimensions to get room folders totals
	vGuests.GroupBy("IsReservation, GuestCitizenship, GuestSex, Room", "GuestCount");
	vRoomFolders = vGuests.Copy();
	vRoomFolders.GroupBy("Room", );
	// Fill guests
	For Each vRoomFoldersRow In vRoomFolders Do
		vCurRoom = vRoomFoldersRow.Room;
		If Not ValueIsFilled(vCurRoom) Then
			Continue;
		EndIf;
		vGuestsStr = "";
		If vCurRoom.IsFolder Then
			If Not vCurRoom.DoNotShowRoomGuestTotals Then
				vRowsArray = vGuests.FindRows(New Structure("Room", vCurRoom));
				For Each vRow In vRowsArray Do
					If Not IsBlankString(vGuestsStr) Then
						vGuestsStr = vGuestsStr + ", ";
					EndIf;
					vGuestCount = vRow.GuestCount;
					If Not vCurRoom.IsFolder Then
						vGuestCount = vGuestCount/2;
					EndIf;
					vGuestSex = TrimAll(String(vRow.GuestSex));
					vGuestCitizenship = TrimAll(vRow.GuestCitizenship);
					vGuestsStr = vGuestsStr + ?(vRow.IsReservation, NStr("en='r';ru='р';de='r'"), "") + 
											  String(vGuestCount) + 
											  Left(?(vGuestSex="", "?", vGuestSex), 1) + 
											  "(" + ?(vGuestCitizenship="", "?", vGuestCitizenship) + ")";
				EndDo;
				If Not IsBlankString(vGuestsStr) Then
					vCurRoomText = TrimAll(vCurRoom);
					// Try to find room folder description in the spreadsheet 
					vRoomFolderArea = pSpreadsheet.FindText(vCurRoomText, , , False, False, , True);
					If vRoomFolderArea <> Undefined Then
						vRoomFolderArea.Text = vRoomFolderArea.Text + " " + vGuestsStr;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
		
	// Apply number of pages to be printed on the one paper sheet
	cmApplyReportMultiplePages(ThisObject, pSpreadsheet)
EndProcedure // pmGenerate

// -----------------------------------------------------------------------------
Procedure pmInitializeReportBuilder() Export
	ReportBuilder = New ReportBuilder();
	
	// Initialize default query text
	QueryText = 
	"SELECT
	|	VacantRooms.Hotel AS Hotel,
	|	VacantRooms.Room AS Room,
	|	VacantRooms.RoomType.Code AS RoomTypeCode,
	|	VacantRooms.RoomStatus AS RoomStatus,
	|	VacantRooms.GuestGroup AS GuestGroup,
	|	VacantRooms.Guest AS Guest,
	|	VacantRooms.GuestSex AS GuestSex,
	|	VacantRooms.GuestCitizenship AS GuestCitizenship,
	|	VacantRooms.CheckOutDate AS CheckOutDate,
	|	VacantRooms.CheckInDate AS CheckInDate,
	|	VacantRooms.RoomsVacantBalance AS RoomsVacantBalance,
	|	VacantRooms.BedsVacantBalance AS BedsVacantBalance,
	|	VacantRooms.GuestsVacantBalance AS GuestsVacantBalance,
	|	VacantRooms.InHouseRoomsBalance AS InHouseRoomsBalance,
	|	VacantRooms.InHouseBedsBalance AS InHouseBedsBalance,
	|	VacantRooms.InHouseAdditionalBedsBalance AS InHouseAdditionalBedsBalance,
	|	VacantRooms.InHouseGuestsBalance AS InHouseGuestsBalance
	|{SELECT
	|	Hotel.* AS Hotel,
	|	Room.* AS Room,
	|	VacantRooms.RoomType.* AS RoomType,
	|	RoomStatus.* AS RoomStatus,
	|	GuestGroup.* AS GuestGroup,
	|	Guest.* AS Guest,
	|	GuestSex AS GuestSex,
	|	GuestCitizenship.* AS GuestCitizenship,
	|	VacantRooms.Recorder.* AS Recorder,
	|	VacantRooms.ParentDoc.* AS ParentDoc,
	|	CheckOutDate AS CheckOutDate,
	|	CheckInDate AS CheckInDate,
	|	RoomsVacantBalance AS RoomsVacantBalance,
	|	BedsVacantBalance AS BedsVacantBalance,
	|	GuestsVacantBalance AS GuestsVacantBalance,
	|	InHouseRoomsBalance AS InHouseRoomsBalance,
	|	InHouseBedsBalance AS InHouseBedsBalance,
	|	InHouseAdditionalBedsBalance AS InHouseAdditionalBedsBalance,
	|	InHouseGuestsBalance AS InHouseGuestsBalance}
	|FROM
	|	(SELECT
	|		RoomInventoryBalance.Hotel AS Hotel,
	|		RoomInventoryBalance.Room AS Room,
	|		RoomInventoryBalance.RoomType AS RoomType,
	|		RoomInventoryBalance.Room.RoomStatus AS RoomStatus,
	|		InHouseGuests.GuestGroup AS GuestGroup,
	|		InHouseGuests.Guest AS Guest,
	|		InHouseGuests.Guest.Sex AS GuestSex,
	|		InHouseGuests.Guest.Citizenship AS GuestCitizenship,
	|		InHouseGuests.Recorder AS Recorder,
	|		InHouseGuests.ParentDoc AS ParentDoc,
	|		CheckedOutGuests.CheckOutDate AS CheckOutDate,
	|		FutureReservations.CheckInDate AS CheckInDate,
	|		RoomInventoryBalance.RoomsVacantBalance AS RoomsVacantBalance,
	|		RoomInventoryBalance.BedsVacantBalance AS BedsVacantBalance,
	|		RoomInventoryBalance.GuestsVacantBalance AS GuestsVacantBalance,
	|		-(RoomInventoryBalance.InHouseRoomsBalance + RoomInventoryBalance.RoomsReservedBalance) AS InHouseRoomsBalance,
	|		-(RoomInventoryBalance.InHouseBedsBalance + RoomInventoryBalance.BedsReservedBalance) AS InHouseBedsBalance,
	|		-(RoomInventoryBalance.InHouseAdditionalBedsBalance + RoomInventoryBalance.AdditionalBedsReservedBalance) AS InHouseAdditionalBedsBalance,
	|		-(RoomInventoryBalance.InHouseGuestsBalance + RoomInventoryBalance.GuestsReservedBalance) AS InHouseGuestsBalance
	|	FROM
	|		AccumulationRegister.RoomInventory.Balance(
	|				&qPeriodTo,
	|				Hotel IN HIERARCHY (&qHotel)
	|					AND RoomType IN HIERARCHY (&qRoomType)
	|					AND Room IN HIERARCHY (&qRoom)) AS RoomInventoryBalance
	|			LEFT JOIN (SELECT
	|				RoomInventory.Hotel AS Hotel,
	|				RoomInventory.Room AS Room,
	|				RoomInventory.GuestGroup AS GuestGroup,
	|				RoomInventory.Guest AS Guest,
	|				RoomInventory.Guest.Sex AS GuestSex,
	|				RoomInventory.Guest.Citizenship AS GuestCitizenship,
	|				RoomInventory.Recorder AS Recorder,
	|				RoomInventory.ParentDoc AS ParentDoc
	|			FROM
	|				AccumulationRegister.RoomInventory AS RoomInventory
	|			WHERE
	|				RoomInventory.RecordType = VALUE(AccumulationRecordType.Expense)
	|				AND (RoomInventory.IsAccommodation
	|						OR RoomInventory.IsReservation)
	|				AND RoomInventory.PeriodFrom <= &qPeriodTo
	|				AND RoomInventory.PeriodTo > &qPeriodTo
	|				AND RoomInventory.GuestsVacant <> 0
	|			
	|			GROUP BY
	|				RoomInventory.Hotel,
	|				RoomInventory.Room,
	|				RoomInventory.GuestGroup,
	|				RoomInventory.Guest,
	|				RoomInventory.Guest.Sex,
	|				RoomInventory.Guest.Citizenship,
	|				RoomInventory.Recorder,
	|				RoomInventory.ParentDoc) AS InHouseGuests
	|			ON RoomInventoryBalance.Hotel = InHouseGuests.Hotel
	|				AND RoomInventoryBalance.Room = InHouseGuests.Room
	|			LEFT JOIN (SELECT
	|				RoomCheckOut.Hotel AS Hotel,
	|				RoomCheckOut.Room AS Room,
	|				MAX(RoomCheckOut.CheckOutDate) AS CheckOutDate
	|			FROM
	|				AccumulationRegister.RoomInventory AS RoomCheckOut
	|			WHERE
	|				RoomCheckOut.RecordType = VALUE(AccumulationRecordType.Expense)
	|				AND RoomCheckOut.IsAccommodation
	|				AND RoomCheckOut.CheckOutDate = RoomCheckOut.PeriodTo
	|				AND RoomCheckOut.CheckOutDate <= &qPeriodTo
	|				AND RoomCheckOut.CheckOutDate > &qPeriodToMinusDay
	|				AND RoomCheckOut.GuestsVacant <> 0
	|			
	|			GROUP BY
	|				RoomCheckOut.Hotel,
	|				RoomCheckOut.Room) AS CheckedOutGuests
	|			ON RoomInventoryBalance.Hotel = CheckedOutGuests.Hotel
	|				AND RoomInventoryBalance.Room = CheckedOutGuests.Room
	|			LEFT JOIN (SELECT
	|				Reservations.Hotel AS Hotel,
	|				Reservations.Room AS Room,
	|				MIN(Reservations.CheckInDate) AS CheckInDate
	|			FROM
	|				AccumulationRegister.RoomInventory AS Reservations
	|			WHERE
	|				Reservations.RecordType = VALUE(AccumulationRecordType.Expense)
	|				AND Reservations.IsReservation
	|				AND Reservations.CheckInDate >= &qPeriodTo
	|				AND Reservations.GuestsVacant <> 0
	|			
	|			GROUP BY
	|				Reservations.Hotel,
	|				Reservations.Room) AS FutureReservations
	|			ON RoomInventoryBalance.Hotel = FutureReservations.Hotel
	|				AND RoomInventoryBalance.Room = FutureReservations.Room
	|	WHERE
	|		(RoomInventoryBalance.BedsVacantBalance > 0
	|					AND NOT &qShowReservedRooms
	|				OR (RoomInventoryBalance.BedsVacantBalance > 0
	|					OR RoomInventoryBalance.BedsReservedBalance < 0)
	|					AND &qShowReservedRooms)
	|		AND (RoomInventoryBalance.Room.RoomStatus IN (&qRoomStatuses)
	|				OR &qIsEmptyRoomStatuses)) AS VacantRooms
	|{WHERE
	|	VacantRooms.Hotel.* AS Hotel,
	|	VacantRooms.Room.* AS Room,
	|	VacantRooms.RoomType.* AS RoomType,
	|	VacantRooms.RoomStatus.* AS RoomStatus,
	|	VacantRooms.GuestGroup.* AS GuestGroup,
	|	VacantRooms.Guest.* AS Guest,
	|	VacantRooms.GuestSex AS GuestSex,
	|	VacantRooms.GuestCitizenship.* AS GuestCitizenship,
	|	VacantRooms.Recorder.* AS Recorder,
	|	VacantRooms.ParentDoc.* AS ParentDoc,
	|	VacantRooms.CheckOutDate AS CheckOutDate,
	|	VacantRooms.CheckInDate AS CheckInDate,
	|	VacantRooms.RoomsVacantBalance AS RoomsVacantBalance,
	|	VacantRooms.BedsVacantBalance AS BedsVacantBalance,
	|	VacantRooms.GuestsVacantBalance AS GuestsVacantBalance,
	|	VacantRooms.InHouseRoomsBalance AS InHouseRoomsBalance,
	|	VacantRooms.InHouseBedsBalance AS InHouseBedsBalance,
	|	VacantRooms.InHouseAdditionalBedsBalance AS InHouseAdditionalBedsBalance,
	|	VacantRooms.InHouseGuestsBalance AS InHouseGuestsBalance}
	|
	|ORDER BY
	|	Hotel,
	|	Room
	|{ORDER BY
	|	Hotel.*,
	|	Room.*,
	|	VacantRooms.RoomType.*,
	|	RoomStatus.*,
	|	GuestGroup.*,
	|	Guest.*,
	|	GuestSex.*,
	|	GuestCitizenship.*,
	|	VacantRooms.Recorder.*,
	|	VacantRooms.ParentDoc.*,
	|	CheckOutDate,
	|	CheckInDate,
	|	RoomsVacantBalance,
	|	BedsVacantBalance,
	|	GuestsVacantBalance,
	|	InHouseRoomsBalance,
	|	InHouseBedsBalance,
	|	InHouseAdditionalBedsBalance,
	|	InHouseGuestsBalance}
	|TOTALS
	|	SUM(RoomsVacantBalance),
	|	SUM(BedsVacantBalance),
	|	SUM(GuestsVacantBalance),
	|	SUM(InHouseRoomsBalance),
	|	SUM(InHouseBedsBalance),
	|	SUM(InHouseAdditionalBedsBalance),
	|	SUM(InHouseGuestsBalance)
	|BY
	|	OVERALL,
	|	Hotel
	|{TOTALS BY
	|	Hotel.*,
	|	Room.*,
	|	VacantRooms.RoomType.*,
	|	RoomStatus.*}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("en='Vacant rooms';ru='Свободные номера';de='Freie Zimmer'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
