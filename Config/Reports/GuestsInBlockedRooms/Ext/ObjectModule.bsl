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
	vParamPresentation = vParamPresentation + NStr("en='Blocks in rooms for the period selected';ru='Отбор блокировок пересекающихся с выбранным периодом';de='Auswahl der sich mit dem ausgewählten Zeitraum überschneidenden Blockierungen'") + 
						 ";" + Chars.LF;
	If ValueIsFilled(RoomBlockType) Then
		If Not RoomBlockType.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Тип блокировки '; en = 'Room block type '; de = 'Zimmerblocktyp '") + 
			                     TrimAll(RoomBlockType.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа типов блокировок '; en = 'Room block types folder '; de = 'Zimmerblocktypgruppe '") + 
			                     TrimAll(RoomBlockType.Description) + 
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
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qRoomBlockType", RoomBlockType);
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qIsEmptyRoomType", Not ValueIsFilled(RoomType));
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
	|	Accommodations.Guest AS AccommodationGuest,
	|	Accommodations.CheckInDate AS AccommodationCheckInDate,
	|	Accommodations.CheckOutDate AS AccommodationCheckOutDate,
	|	RoomInventory.Hotel AS Hotel,
	|	RoomInventory.RoomBlockType AS RoomBlockType,
	|	RoomInventory.Room AS Room,
	|	RoomInventory.CheckInDate AS CheckInDate,
	|	RoomInventory.Duration AS Duration,
	|	RoomInventory.CheckOutDate AS CheckOutDate,
	|	RoomInventory.IsFinished AS IsFinished,
	|	RoomInventory.Remarks AS Remarks,
	|	RoomInventory.Recorder AS Recorder,
	|	1 AS GuestsCount
	|{SELECT
	|	Hotel.* AS Hotel,
	|	RoomBlockType.* AS RoomBlockType,
	|	Room.* AS Room,
	|	RoomInventory.RoomType.* AS RoomType,
	|	CheckInDate AS CheckInDate,
	|	Duration AS Duration,
	|	CheckOutDate AS CheckOutDate,
	|	IsFinished AS IsFinished,
	|	Remarks AS Remarks,
	|	RoomInventory.Author.* AS Author,
	|	Recorder.* AS Recorder,
	|	AccommodationGuest.*,
	|	AccommodationCheckInDate,
	|	AccommodationCheckOutDate,
	|	Accommodations.Accommodation.* AS Accommodation,
	|	RoomInventory.PointInTime AS PointInTime,
	|	RoomInventory.Period AS Period,
	|	RoomInventory.CheckInAccountingDate AS CheckInAccountingDate,
	|	RoomInventory.CheckOutAccountingDate AS CheckOutAccountingDate,
	|	(HOUR(RoomInventory.CheckInDate)) AS CheckInHour,
	|	(DAY(RoomInventory.CheckInDate)) AS CheckInDay,
	|	(WEEK(RoomInventory.CheckInDate)) AS CheckInWeek,
	|	(MONTH(RoomInventory.CheckInDate)) AS CheckInMonth,
	|	(QUARTER(RoomInventory.CheckInDate)) AS CheckInQuarter,
	|	(YEAR(RoomInventory.CheckInDate)) AS CheckInYear,
	|	RoomInventory.RoomsBlocked AS RoomsBlocked,
	|	RoomInventory.BedsBlocked AS BedsBlocked,
	|	GuestsCount}
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventory
	|		LEFT JOIN (SELECT
	|			Accommodation.Guest AS Guest,
	|			Accommodation.Room AS AccommodationRoom,
	|			Accommodation.PeriodFrom AS CheckInDate,
	|			Accommodation.PeriodTo AS CheckOutDate,
	|			Accommodation.Recorder AS Accommodation
	|		FROM
	|			AccumulationRegister.RoomInventory AS Accommodation
	|		WHERE
	|			Accommodation.IsAccommodation = TRUE
	|			AND Accommodation.Hotel IN HIERARCHY(&qHotel)
	|			AND Accommodation.Room IN HIERARCHY(&qRoom)
	|			AND (Accommodation.RoomType IN HIERARCHY (&qRoomType)
	|					OR &qIsEmptyRoomType)
	|			AND Accommodation.RecordType = VALUE(AccumulationRecordType.Expense)
	|		
	|		GROUP BY
	|			Accommodation.Guest,
	|			Accommodation.Room,
	|			Accommodation.PeriodFrom,
	|			Accommodation.PeriodTo,
	|			Accommodation.Recorder) AS Accommodations
	|		ON RoomInventory.Room = Accommodations.AccommodationRoom
	|			AND (Accommodations.CheckInDate < &qPeriodTo)
	|			AND (Accommodations.CheckOutDate > &qPeriodFrom)
	|			AND (Accommodations.CheckInDate < RoomInventory.PeriodTo
	|				OR RoomInventory.PeriodTo = &qEmptyDate)
	|			AND (Accommodations.CheckOutDate > RoomInventory.PeriodFrom)
	|WHERE
	|	RoomInventory.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND RoomInventory.IsBlocking = TRUE
	|	AND RoomInventory.Hotel IN HIERARCHY(&qHotel)
	|	AND RoomInventory.Room IN HIERARCHY(&qRoom)
	|	AND (RoomInventory.RoomType IN HIERARCHY (&qRoomType)
	|			OR &qIsEmptyRoomType)
	|	AND RoomInventory.RoomBlockType IN HIERARCHY(&qRoomBlockType)
	|	AND RoomInventory.PeriodFrom < &qPeriodTo
	|	AND (RoomInventory.PeriodTo > &qPeriodFrom
	|			OR RoomInventory.PeriodTo = &qEmptyDate)
	|{WHERE
	|	RoomInventory.Hotel,
	|	RoomInventory.RoomType,
	|	RoomInventory.Room,
	|	RoomInventory.RoomBlockType.*,
	|	RoomInventory.CheckInDate,
	|	RoomInventory.Duration,
	|	RoomInventory.CheckOutDate,
	|	Accommodations.Guest.* AS AccommodationGuest,
	|	Accommodations.CheckInDate AS AccommodationCheckInDate,
	|	Accommodations.CheckOutDate AS AccommodationCheckOutDate,
	|	Accommodations.Accommodation.* AS Accommodation,
	|	RoomInventory.CheckInAccountingDate,
	|	RoomInventory.CheckOutAccountingDate,
	|	RoomInventory.Period,
	|	RoomInventory.IsFinished,
	|	RoomInventory.Remarks,
	|	RoomInventory.Author.*,
	|	RoomInventory.Recorder.*,
	|	RoomInventory.BedsBlocked,
	|	RoomInventory.RoomsBlocked}
	|
	|ORDER BY
	|	Hotel,
	|	RoomBlockType,
	|	Room,
	|	CheckInDate
	|{ORDER BY
	|	Hotel.*,
	|	RoomInventory.RoomType.*,
	|	Room.*,
	|	RoomBlockType.*,
	|	CheckInDate,
	|	Duration,
	|	CheckOutDate,
	|	AccommodationGuest.*,
	|	AccommodationCheckInDate,
	|	AccommodationCheckOutDate,
	|	Accommodations.Accommodation.* AS Accommodation,
	|	IsFinished,
	|	Remarks,
	|	RoomInventory.Author.*,
	|	RoomInventory.CheckInAccountingDate,
	|	RoomInventory.CheckOutAccountingDate,
	|	(HOUR(RoomInventory.CheckInDate)) AS CheckInHour,
	|	(DAY(RoomInventory.CheckInDate)) AS CheckInDay,
	|	(WEEK(RoomInventory.CheckInDate)) AS CheckInWeek,
	|	(MONTH(RoomInventory.CheckInDate)) AS CheckInMonth,
	|	(QUARTER(RoomInventory.CheckInDate)) AS CheckInQuarter,
	|	(YEAR(RoomInventory.CheckInDate)) AS CheckInYear,
	|	RoomInventory.PointInTime,
	|	RoomInventory.Period,
	|	Recorder.*,
	|	RoomInventory.RoomsBlocked AS RoomsBlocked,
	|	RoomInventory.BedsBlocked AS BedsBlocked}
	|TOTALS
	|	SUM(GuestsCount)
	|BY
	|	OVERALL,
	|	Hotel,
	|	RoomBlockType,
	|	Room
	|{TOTALS BY
	|	Hotel,
	|	RoomBlockType.*,
	|	Room,
	|	RoomInventory.RoomType,
	|	AccommodationGuest.*,
	|	Accommodations.Accommodation.* AS Accommodation,
	|	RoomInventory.CheckInAccountingDate,
	|	RoomInventory.CheckOutAccountingDate,
	|	(HOUR(RoomInventory.CheckInDate)) AS CheckInHour,
	|	(DAY(RoomInventory.CheckInDate)) AS CheckInDay,
	|	(WEEK(RoomInventory.CheckInDate)) AS CheckInWeek,
	|	(MONTH(RoomInventory.CheckInDate)) AS CheckInMonth,
	|	(QUARTER(RoomInventory.CheckInDate)) AS CheckInQuarter,
	|	(YEAR(RoomInventory.CheckInDate)) AS CheckInYear,
	|	Recorder.*,
	|	RoomInventory.Author.*}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Guests in blocked rooms';RU='Гости в заблокированных номерах';de='Gäste in blockierten Zimmern'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
