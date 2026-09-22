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
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetReportParametersPresentation() Export
	vParamPresentation = "";
	If ValueIsFilled(PointInTime) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'На момент времени '; en = 'Point in time '; de = 'Zeitpunkt '") + 
		                     Format(PointInTime, "DF='dd.MM.yyyy HH:mm'") + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("ru = 'На момент времени '; en = 'Point in time '; de = 'Zeitpunkt '") + 
		                     Format(CurrentSessionDate(), "DF='dd.MM.yyyy HH:mm'") + 
		                     ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(RoomStatus) Then
		If Not RoomStatus.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Статус номеров '; en = 'Room status '; de = 'Zimmerstatus '") + 
			                     TrimAll(RoomStatus.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа статусов номеров '; en = 'Room statuses folder '; de = 'Zimmerstatusgruppe '") + 
			                     TrimAll(RoomStatus.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(RoomGroup) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Группа номеров '; en = 'Room folder '; de = 'Zimmergruppe '") + 
		                     TrimAll(RoomGroup.Description) + 
		                     ";" + Chars.LF;
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
	If ValueIsFilled(RoomSection) Then
		If Not RoomSection.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Секция номеров '; en = 'Room section '; de = 'Zimmersektion '") + 
			                     TrimAll(RoomStatus.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа cекций номеров '; en = 'Room section folder '; de = 'Zimmersectiongruppe '") + 
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
	
	// Run main query to get data
	QueryText = ReportBuilder.Text;
	
	vQry = New Query();
	vQry.Text = TrimAll(QueryText);
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qPointInTime", ?(ValueIsFilled(PointInTime), PointInTime, CurrentSessionDate()));
	vQry.SetParameter("qRoomStatus", RoomStatus);
	vQry.SetParameter("qRoomType", RoomType);
	vQry.SetParameter("qRoomGroup", RoomGroup);
	vQry.SetParameter("qRoomSection", RoomSection);
	vQry.SetParameter("qExpectedCheckInClause", NStr("en='Arrival today'; ru='На заезде'; de='Anreise heute'"));
	vQry.SetParameter("qCheckedInClause", NStr("en='Checked-in'; ru='Заехал'; de='Checked-in'"));
	vQry.SetParameter("qInHouseClause", NStr("en='In house'; ru='Занят'; de='In house'"));
	vQry.SetParameter("qExpectedCheckOutClause", NStr("en='Departure today'; ru='На выезде'; de='Abreise heute'"));
	vQry.SetParameter("qCheckedOutClause", NStr("en='Checked-out'; ru='Выехал'; de='Checked-out'"));
	vQry.SetParameter("qExpectedRoomMoveClause", NStr("en='Moving'; ru='Переселение'; de='Umzug'"));
	
	vRoomStatusTimes = vQry.Execute().Unload();
	vResults = vRoomStatusTimes.CopyColumns("RoomParent, Room, RoomStatus, Period, CurrentStatusTime, Condition, Remarks, Quantity");	
	For Each vRow In vRoomStatusTimes Do
		vNewRow = vResults.Add();
		FillPropertyValues(vNewRow, vRow, "Period, Room, RoomStatus, Remarks, Condition, CurrentStatusTime, RoomParent, Quantity"); 	
		vCurrentStatusTimeStr = "";
		If vRow.DayOfStay > 0 Then
			vCurrentStatusTimeStr = Format(vRow.DayOfStay, "NFD=0; NZ=0; NG=") +  NStr("en = 'days '; de = 'Tage '; ru = 'дн. '");	
		EndIf;
		vNewRow.CurrentStatusTime = vCurrentStatusTimeStr + Format(vRow.HoursOfStay, "ND=2; NFD=0; NZ=00; NLZ=") + ":" + Format(vRow.MinutesOfStay, "ND=2; NFD=0; NZ=00; NLZ=");
		
		vIsVacant = True;
		If Not IsBlankString(vRow.ExpectedCheckOutClause) Then
			If StrFind(vNewRow.Condition, vRow.ExpectedCheckOutClause) = 0 Then
				vNewRow.Condition = vNewRow.Condition + ?(IsBlankString(vNewRow.Condition), "", ", ") + vRow.ExpectedCheckOutClause;
			EndIf;
			vIsVacant = False;
		EndIf;
		If Not IsBlankString(vRow.ExpectedCheckInClause) Then
			If StrFind(vNewRow.Condition, vRow.ExpectedCheckInClause) = 0 Then
				vNewRow.Condition = vNewRow.Condition + ?(IsBlankString(vNewRow.Condition), "", ", ") + vRow.ExpectedCheckInClause;
			EndIf;
			vIsVacant = False;
		EndIf;
		If Not IsBlankString(vRow.CheckedInClause) Then
			If StrFind(vNewRow.Condition, vRow.CheckedInClause) = 0 Then
				vNewRow.Condition = vNewRow.Condition + ?(IsBlankString(vNewRow.Condition), "", ", ") + vRow.CheckedInClause;
			EndIf;
			vIsVacant = False;
		EndIf;
		If Not IsBlankString(vRow.InHouseClause) And IsBlankString(vRow.CheckedInClause) And IsBlankString(vRow.ExpectedCheckOutClause) Then
			If StrFind(vNewRow.Condition, vRow.InHouseClause) = 0 Then
				vNewRow.Condition = vNewRow.Condition + ?(IsBlankString(vNewRow.Condition), "", ", ") + vRow.InHouseClause;
			EndIf;
			vIsVacant = False;
		ElsIf Not IsBlankString(vRow.CheckedOutClause) Then
			If StrFind(vNewRow.Condition, vRow.CheckedOutClause) = 0 Then
				vNewRow.Condition = vNewRow.Condition + ?(IsBlankString(vNewRow.Condition), "", ", ") + vRow.CheckedOutClause;
			EndIf;
			vIsVacant = False;
		EndIf;
		If vIsVacant Then
			vVacantClause = NStr("en='Vacant'; ru='Свободен'; de='Leer'");
			If StrFind(vNewRow.Condition, vVacantClause) = 0 Then
				vNewRow.Condition = vNewRow.Condition + ?(IsBlankString(vNewRow.Condition), "", ", ") + vVacantClause;
			EndIf;
		EndIf;
	EndDo;
	
	// Save current report builder settings
	vCurReportBuilderSettings = ReportBuilder.GetSettings(True, True, False, True, True);
	
	// Set resulting table as data source for the report builder
	ReportBuilder.DataSource = New DataSourceDescription(vResults);
		
	// Apply current report builder settings
	ReportBuilder.SetSettings(vCurReportBuilderSettings, True, True, False, True, True);
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	ReportBuilder.DataSource.Columns["RoomParent"].Dimension = True;
	ReportBuilder.DataSource.Columns["Quantity"].Total = "SUM(Quantity)";
	
	ReportBuilder.FillSettings();
	
	// Execute report builder
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
	|	Accommodations.Room AS Room,
	|	&qInHouseClause AS Clause
	|INTO InHouseGuests
	|FROM
	|	InformationRegister.AccommodationChangeHistory.SliceLast(
	|			&qPointInTime,
	|			Accommodation.Posted
	|				AND AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)) AS Accommodations
	|WHERE
	|	Accommodations.AccommodationStatus.IsActive
	|	AND Accommodations.AccommodationStatus.IsInHouse
	|
	|GROUP BY
	|	Accommodations.Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Reservations.Room AS Room,
	|	&qExpectedCheckInClause AS Clause
	|INTO ExpectedCheckInGuests
	|FROM
	|	InformationRegister.ReservationChangeHistory.SliceLast(
	|			&qPointInTime,
	|			Reservation.Posted
	|				AND AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)) AS Reservations
	|WHERE
	|	BEGINOFPERIOD(Reservations.CheckInDate, DAY) = BEGINOFPERIOD(&qPointInTime, DAY)
	|	AND (Reservations.ReservationStatus.IsActive
	|			OR Reservations.ReservationStatus.IsPreliminary)
	|
	|GROUP BY
	|	Reservations.Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Accommodations.Room AS Room,
	|	&qExpectedCheckOutClause AS Clause
	|INTO ExpectedCheckOutGuests
	|FROM
	|	InformationRegister.AccommodationChangeHistory.SliceLast(
	|			&qPointInTime,
	|			Accommodation.Posted
	|				AND AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)) AS Accommodations
	|WHERE
	|	BEGINOFPERIOD(Accommodations.CheckOutDate, DAY) = BEGINOFPERIOD(&qPointInTime, DAY)
	|	AND Accommodations.AccommodationStatus.IsActive
	|	AND Accommodations.AccommodationStatus.IsInHouse
	|	AND Accommodations.AccommodationStatus.IsCheckOut
	|
	|GROUP BY
	|	Accommodations.Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Accommodations.Room AS Room,
	|	&qCheckedOutClause AS Clause
	|INTO CheckedOutGuests
	|FROM
	|	InformationRegister.AccommodationChangeHistory.SliceLast(
	|			&qPointInTime,
	|			Accommodation.Posted
	|				AND AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)) AS Accommodations
	|WHERE
	|	Accommodations.AccommodationStatus.IsActive
	|	AND NOT Accommodations.AccommodationStatus.IsInHouse
	|	AND Accommodations.AccommodationStatus.IsCheckOut
	|	AND BEGINOFPERIOD(Accommodations.CheckOutDate, DAY) = BEGINOFPERIOD(&qPointInTime, DAY)
	|
	|GROUP BY
	|	Accommodations.Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Accommodations.Room AS Room,
	|	&qCheckedInClause AS Clause
	|INTO CheckedInGuests
	|FROM
	|	InformationRegister.AccommodationChangeHistory.SliceLast(
	|			&qPointInTime,
	|			Accommodation.Posted
	|				AND AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)) AS Accommodations
	|WHERE
	|	Accommodations.AccommodationStatus.IsActive
	|	AND Accommodations.AccommodationStatus.IsInHouse
	|	AND Accommodations.AccommodationStatus.IsCheckIn
	|	AND BEGINOFPERIOD(Accommodations.CheckInDate, DAY) = BEGINOFPERIOD(&qPointInTime, DAY)
	|
	|GROUP BY
	|	Accommodations.Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomStatusChangeHistorySliceLast.Period AS Period,
	|	CAST(DATEDIFF(RoomStatusChangeHistorySliceLast.Period, &qPointInTime, SECOND) / (3600 * 24) - 0.5 AS NUMBER(10, 0)) AS DayOfStay,
	|	(CAST(DATEDIFF(RoomStatusChangeHistorySliceLast.Period, &qPointInTime, SECOND) / 3600 - 0.5 AS NUMBER(10, 0))) - (CAST(DATEDIFF(RoomStatusChangeHistorySliceLast.Period, &qPointInTime, SECOND) / (3600 * 24) - 0.5 AS NUMBER(10, 0))) * 24 AS HoursOfStay,
	|	(CAST(DATEDIFF(RoomStatusChangeHistorySliceLast.Period, &qPointInTime, SECOND) / 60 - 0.5 AS NUMBER(10, 0))) - (CAST(DATEDIFF(RoomStatusChangeHistorySliceLast.Period, &qPointInTime, SECOND) / 3600 - 0.5 AS NUMBER(10, 0))) * 60 AS MinutesOfStay,
	|	RoomStatusChangeHistorySliceLast.Room AS Room,
	|	RoomStatusChangeHistorySliceLast.Room.Parent AS RoomParent,
	|	RoomStatusChangeHistorySliceLast.RoomStatus AS RoomStatus,
	|	RoomStatusChangeHistorySliceLast.Remarks AS Remarks,
	|	CAST("""" AS STRING) AS Condition,
	|	ExpectedCheckInGuests.Clause AS ExpectedCheckInClause,
	|	CheckedInGuests.Clause AS CheckedInClause,
	|	InHouseGuests.Clause AS InHouseClause,
	|	ExpectedCheckOutGuests.Clause AS ExpectedCheckOutClause,
	|	CheckedOutGuests.Clause AS CheckedOutClause,
	|	CAST("""" AS STRING) AS CurrentStatusTime,
	|	1 AS Quantity
	|{SELECT
	|	Room.*,
	|	RoomParent.*,
	|	RoomStatus.*,
	|	Period,
	|	CurrentStatusTime,
	|	Condition,
	|	Remarks}
	|FROM
	|	InformationRegister.RoomStatusChangeHistory.SliceLast(
	|			&qPointInTime,
	|			NOT Room.IsFolder
	|				AND NOT Room.DeletionMark
	|				AND CASE
	|					WHEN &qHotel <> VALUE(Catalog.Hotels.EmptyRef)
	|						THEN Room.Owner = &qHotel
	|					ELSE TRUE
	|				END
	|				AND CASE
	|					WHEN &qRoomGroup <> VALUE(Catalog.Rooms.EmptyRef)
	|						THEN Room.Parent = &qRoomGroup
	|					ELSE TRUE
	|				END
	|				AND CASE
	|					WHEN &qRoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
	|						THEN Room.RoomType = &qRoomType
	|					ELSE TRUE
	|				END
	|				AND CASE
	|					WHEN &qRoomSection <> VALUE(Catalog.RoomSections.EmptyRef)
	|						THEN Room.RoomSection = &qRoomSection
	|					ELSE TRUE
	|				END) AS RoomStatusChangeHistorySliceLast
	|		{LEFT JOIN InHouseGuests AS InHouseGuests
	|		ON RoomStatusChangeHistorySliceLast.Room = InHouseGuests.Room
	|		LEFT JOIN ExpectedCheckInGuests AS ExpectedCheckInGuests
	|		ON RoomStatusChangeHistorySliceLast.Room = ExpectedCheckInGuests.Room
	|		LEFT JOIN ExpectedCheckOutGuests AS ExpectedCheckOutGuests
	|		ON RoomStatusChangeHistorySliceLast.Room = ExpectedCheckOutGuests.Room
	|		LEFT JOIN CheckedOutGuests AS CheckedOutGuests
	|		ON RoomStatusChangeHistorySliceLast.Room = CheckedOutGuests.Room
	|		LEFT JOIN CheckedInGuests AS CheckedInGuests
	|		ON RoomStatusChangeHistorySliceLast.Room = CheckedInGuests.Room}
	|WHERE
	|	CASE
	|			WHEN &qRoomStatus <> VALUE(Catalog.RoomStatuses.EmptyRef)
	|				THEN RoomStatusChangeHistorySliceLast.RoomStatus = &qRoomStatus
	|			ELSE TRUE
	|		END
	|{WHERE
	|	RoomStatusChangeHistorySliceLast.Room.*,
	|	RoomStatusChangeHistorySliceLast.Room.Parent.*,
	|	RoomStatusChangeHistorySliceLast.RoomStatus.*,
	|	RoomStatusChangeHistorySliceLast.Period}
	|
	|ORDER BY
	|	RoomStatusChangeHistorySliceLast.Room.Owner.SortCode,
	|	RoomStatusChangeHistorySliceLast.Room.Parent.SortCode,
	|	RoomStatusChangeHistorySliceLast.Room.SortCode
	|{TOTALS BY
	|	Room.*,
	|	RoomParent.*,
	|	RoomStatus.*,
	|	Period,
	|	CurrentStatusTime,
	|	Condition,
	|	Remarks}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("en='Room status time';ru='Время статуса комнаты';de='Zimmerstatuszeit'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
