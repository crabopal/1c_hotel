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
	If Not ValueIsFilled(PeriodCheckType) Then
		PeriodCheckType = Enums.PeriodCheckTypes.Intersection;
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
	If Not ValueIsFilled(PeriodCheckType) Then
		vParamPresentation = vParamPresentation + NStr("en='Report period check type is not set';ru='Вид проверки периода отчета не установлен';de='Art der Kontrolle des Berichtszeitraums nicht festgelegt'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodCheckType = Enums.PeriodCheckTypes.Intersection Then
		vParamPresentation = vParamPresentation + NStr("en='Blocks in rooms for the period selected';ru='Отбор блокировок пересекающихся с выбранным периодом';de='Auswahl der sich mit dem ausgewählten Zeitraum überschneidenden Blockierungen'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodCheckType = Enums.PeriodCheckTypes.StartsInPeriod Then
		vParamPresentation = vParamPresentation + NStr("en='Blocks started during the period selected';ru='Отбор блокировок начавшихся в выбранном периоде';de='Auswahl der im ausgewählten Zeitraum beginnenden Blockierung'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodCheckType = Enums.PeriodCheckTypes.EndsInPeriod Then
		vParamPresentation = vParamPresentation + NStr("en='Blocks finished during the period selected';ru='Отбор блокировок закончившихся в выбранном периоде';de='Auswahl der im ausgewählten Zeitraum beendeten Blockierungen'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodCheckType = Enums.PeriodCheckTypes.StartsOrEndsInPeriod Then
		vParamPresentation = vParamPresentation + NStr("en='Blocks started or finished during the period selected';ru='Отбор блокировок начавшихся или закончившихся в выбранном периоде';de='Auswahl der im ausgewählten Zeitraum beginnenden oder Endenden Blockierungen'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodCheckType = Enums.PeriodCheckTypes.DocDateInPeriod Then
		vParamPresentation = vParamPresentation + NStr("en='Blocks registered during the period selected';ru='Отбор блокировок с датой и временем регистрации в выбранном периоде';de='Auswahl der Blockierungen mit Datum und Uhrzeit der Registrierung im ausgewählten Zeitraum'") + 
		                     ";" + Chars.LF;
	Endif;		
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
	If ValueIsFilled(Hotel) Then
		If Not Hotel.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Hotel ';ru='Гостиница ';de='Hotel '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Hotels folder ';ru='Группа гостиниц ';de='Hotelsgruppe '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     TrimAll(Hotel.Description) + ";" + Chars.LF;
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
	ReportBuilder.Parameters.Insert("qPeriodCheckType", PeriodCheckType);
	ReportBuilder.Parameters.Insert("qIntersection", Enums.PeriodCheckTypes.Intersection);
	ReportBuilder.Parameters.Insert("qStartsInPeriod", Enums.PeriodCheckTypes.StartsInPeriod);
	ReportBuilder.Parameters.Insert("qEndsInPeriod", Enums.PeriodCheckTypes.EndsInPeriod);
	ReportBuilder.Parameters.Insert("qStartsOrEndsInPeriod", Enums.PeriodCheckTypes.StartsOrEndsInPeriod);
	ReportBuilder.Parameters.Insert("qDocDateInPeriod", Enums.PeriodCheckTypes.DocDateInPeriod);
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
	|	RoomInventory.Hotel AS Hotel,
	|	RoomInventory.RoomBlockType AS RoomBlockType,
	|	RoomInventory.Room AS Room,
	|	RoomInventory.CheckInDate AS CheckInDate,
	|	RoomInventory.Duration AS Duration,
	|	RoomInventory.CheckOutDate AS CheckOutDate,
	|	RoomInventory.IsFinished AS IsFinished,
	|	RoomInventory.Remarks AS Remarks,
	|	RoomInventory.RoomsBlocked AS RoomsBlocked,
	|	RoomInventory.BedsBlocked AS BedsBlocked,
	|	CASE
	|		WHEN RoomInventory.CheckInDate < &qPeriodFrom
	|				AND RoomInventory.CheckOutDate < &qPeriodTo
	|				AND RoomInventory.CheckOutDate > &qEmptyDate
	|			THEN CAST((DATEDIFF(&qPeriodFrom, RoomInventory.CheckOutDate, SECOND) + 60) / (24*3600) * RoomInventory.RoomsBlocked AS NUMBER(10, 2))
	|		WHEN RoomInventory.CheckInDate < &qPeriodFrom
	|				AND (RoomInventory.CheckOutDate >= &qPeriodTo
	|					OR RoomInventory.CheckOutDate = &qEmptyDate)
	|			THEN CAST(DATEDIFF(&qPeriodFrom, &qPeriodTo, SECOND) / (24*3600) * RoomInventory.RoomsBlocked AS NUMBER(10, 2))
	|		WHEN RoomInventory.CheckInDate >= &qPeriodFrom
	|				AND (RoomInventory.CheckOutDate >= &qPeriodTo
	|					OR RoomInventory.CheckOutDate = &qEmptyDate)
	|			THEN CAST(DATEDIFF(RoomInventory.CheckInDate, &qPeriodTo, SECOND) / (24*3600) * RoomInventory.RoomsBlocked AS NUMBER(10, 2))
	|		WHEN RoomInventory.CheckInDate >= &qPeriodFrom
	|				AND RoomInventory.CheckOutDate < &qPeriodTo
	|				AND RoomInventory.CheckOutDate > &qEmptyDate
	|			THEN CAST((DATEDIFF(RoomInventory.CheckInDate, RoomInventory.CheckOutDate, SECOND) + 60) / (24*3600) * RoomInventory.RoomsBlocked AS NUMBER(10, 2))
	|	END AS DaysBlocked,
	|	CASE
	|		WHEN RoomInventory.CheckInDate < &qPeriodFrom
	|				AND RoomInventory.CheckOutDate < &qPeriodTo
	|				AND RoomInventory.CheckOutDate > &qEmptyDate
	|			THEN CAST((DATEDIFF(&qPeriodFrom, RoomInventory.CheckOutDate, SECOND) + 60) / (3600) * RoomInventory.RoomsBlocked AS NUMBER(10, 2))
	|		WHEN RoomInventory.CheckInDate < &qPeriodFrom
	|				AND (RoomInventory.CheckOutDate >= &qPeriodTo
	|					OR RoomInventory.CheckOutDate = &qEmptyDate)
	|			THEN CAST(DATEDIFF(&qPeriodFrom, &qPeriodTo, SECOND) / (3600) * RoomInventory.RoomsBlocked AS NUMBER(10, 2))
	|		WHEN RoomInventory.CheckInDate >= &qPeriodFrom
	|				AND (RoomInventory.CheckOutDate >= &qPeriodTo
	|					OR RoomInventory.CheckOutDate = &qEmptyDate)
	|			THEN CAST(DATEDIFF(RoomInventory.CheckInDate, &qPeriodTo, SECOND) / (3600) * RoomInventory.RoomsBlocked AS NUMBER(10, 2))
	|		WHEN RoomInventory.CheckInDate >= &qPeriodFrom
	|				AND RoomInventory.CheckOutDate < &qPeriodTo
	|				AND RoomInventory.CheckOutDate > &qEmptyDate
	|			THEN CAST((DATEDIFF(RoomInventory.CheckInDate, RoomInventory.CheckOutDate, SECOND) + 60) / (3600) * RoomInventory.RoomsBlocked AS NUMBER(10, 2))
	|	END AS HoursBlocked,
	|	RoomInventory.Recorder AS Recorder
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
	|	RoomsBlocked AS RoomsBlocked,
	|	BedsBlocked AS BedsBlocked,
	|	HoursBlocked AS HoursBlocked,
	|	DaysBlocked AS DaysBlocked}
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventory
	|WHERE
	|	RoomInventory.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND RoomInventory.IsBlocking = TRUE
	|	AND RoomInventory.Hotel IN HIERARCHY(&qHotel)
	|	AND RoomInventory.Room IN HIERARCHY(&qRoom)
	|	AND (RoomInventory.RoomType IN HIERARCHY (&qRoomType)
	|			OR &qIsEmptyRoomType)
	|	AND RoomInventory.RoomBlockType IN HIERARCHY(&qRoomBlockType)
	|	AND (RoomInventory.CheckInDate < &qPeriodTo
	|				AND (RoomInventory.CheckOutDate > &qPeriodFrom
	|					OR RoomInventory.CheckOutDate = &qEmptyDate)
	|				AND &qPeriodCheckType = &qIntersection
	|			OR RoomInventory.CheckInDate >= &qPeriodFrom
	|				AND RoomInventory.CheckInDate < &qPeriodTo
	|				AND (&qPeriodCheckType = &qStartsInPeriod
	|					OR &qPeriodCheckType = &qStartsOrEndsInPeriod)
	|			OR (RoomInventory.CheckOutDate > &qPeriodFrom
	|				OR RoomInventory.CheckOutDate = &qEmptyDate)
	|				AND (RoomInventory.CheckOutDate <= &qPeriodTo
	|					OR RoomInventory.CheckOutDate = &qEmptyDate)
	|				AND (&qPeriodCheckType = &qEndsInPeriod
	|					OR &qPeriodCheckType = &qStartsOrEndsInPeriod)
	|			OR RoomInventory.Recorder.Date >= &qPeriodFrom
	|				AND RoomInventory.Recorder.Date < &qPeriodTo
	|				AND &qPeriodCheckType = &qDocDateInPeriod)
	|{WHERE
	|	RoomInventory.Hotel,
	|	RoomInventory.RoomType,
	|	RoomInventory.Room,
	|	RoomInventory.RoomBlockType.*,
	|	RoomInventory.CheckInDate,
	|	RoomInventory.Duration,
	|	RoomInventory.CheckOutDate,
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
	|	HoursBlocked,
	|	DaysBlocked,
	|	BedsBlocked,
	|	RoomsBlocked}
	|TOTALS
	|	SUM(RoomsBlocked),
	|	SUM(BedsBlocked),
	|	SUM(DaysBlocked),
	|	SUM(HoursBlocked)
	|BY
	|	OVERALL,
	|	Hotel,
	|	RoomBlockType
	|{TOTALS BY
	|	Hotel,
	|	RoomBlockType.*,
	|	Room,
	|	RoomInventory.RoomType,
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
	ReportBuilder.HeaderText = NStr("EN='Room blocks history';RU='История блокировок номеров';de='Zimmerblockierungsverlauf'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
