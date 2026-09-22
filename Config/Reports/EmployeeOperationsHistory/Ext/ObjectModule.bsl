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
		vParamPresentation = vParamPresentation + NStr("en='Report period check type is by operation registration time';ru='Проверка периода по дате и времени регистрации работы';de='Kontrolle des Zeitraums nach Datum und Uhrzeit der Registrierung der Arbeit'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodCheckType = Enums.PeriodCheckTypes.Intersection Then
		vParamPresentation = vParamPresentation + NStr("en='Operations for the period selected';ru='Отбор работ в выбранном периоде';de='Auswahl von Arbeiten im gewählten Zeitraum'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodCheckType = Enums.PeriodCheckTypes.StartsInPeriod Then
		vParamPresentation = vParamPresentation + NStr("en='Operations with start time in the period selected';ru='Отбор работ с временем начала работы в выбранном периоде';de='Auswahl von Arbeiten mit dem Zeitpunkt des Arbeitsbeginns im ausgewählten Zeitraum'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodCheckType = Enums.PeriodCheckTypes.EndsInPeriod Then
		vParamPresentation = vParamPresentation + NStr("en='Operations with finish time in the period selected';ru='Отбор работ с временем завершения работы в выбранном периоде';de='Auswahl von Arbeiten mit dem Zeitpunkt der Beendigung der Arbeit im ausgewählten Zeitraum'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodCheckType = Enums.PeriodCheckTypes.StartsOrEndsInPeriod Then
		vParamPresentation = vParamPresentation + NStr("en='Operations with start or finish time in the period selected';ru='Отбор работ с временем начала или завершения в выбранном периоде';de='Auswahl von Arbeiten mit dem Zeitpunkt des Beginns oder der Beendigung im ausgewählten Zeitraum'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodCheckType = Enums.PeriodCheckTypes.DocDateInPeriod Then
		vParamPresentation = vParamPresentation + NStr("en='Operations with registration time in the period selected';ru='Отбор работ с временем регистрации в выбранном периоде';de='Auswahl von Arbeiten mit dem Zeitpunkt der Registrierung im ausgewählten Zeitraum'") + 
		                     ";" + Chars.LF;
	Endif;		
	If ValueIsFilled(Employee) Then
		If Not Employee.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Employee '; ru='Сотрудник '; de='Mitarbeiter '") + 
			                     TrimAll(Employee.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа сотрудников '; en = 'Employees folder '; de='Mitarbeiterengruppe '") + 
			                     TrimAll(Employee.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(Operation) Then
		If Not Operation.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Работа '; en = 'Operation '; de = 'Arbeit '") + 
			                     TrimAll(Operation.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа работ '; en = 'Operations folder '; de = 'Gruppe von arbeiten '") + 
			                     TrimAll(Operation.Description) + 
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
	ReportBuilder.Parameters.Insert("qIsEmptyHotel", Not ValueIsFilled(Hotel));
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qPeriodCheckType", PeriodCheckType);
	ReportBuilder.Parameters.Insert("qIntersection", Enums.PeriodCheckTypes.Intersection);
	ReportBuilder.Parameters.Insert("qCheckIn", Enums.PeriodCheckTypes.StartsInPeriod);
	ReportBuilder.Parameters.Insert("qCheckOut", Enums.PeriodCheckTypes.EndsInPeriod);
	ReportBuilder.Parameters.Insert("qCheckInOrCheckOut", Enums.PeriodCheckTypes.StartsOrEndsInPeriod);
	ReportBuilder.Parameters.Insert("qDocDateInPeriod", Enums.PeriodCheckTypes.DocDateInPeriod);
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qIsEmptyRoom", Not ValueIsFilled(Room));
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qIsEmptyRoomType", Not ValueIsFilled(RoomType));
	ReportBuilder.Parameters.Insert("qEmployee", Employee);
	ReportBuilder.Parameters.Insert("qIsEmptyEmployee", Not ValueIsFilled(Employee));
	ReportBuilder.Parameters.Insert("qOperation", Operation);
	ReportBuilder.Parameters.Insert("qIsEmptyOperation", Not ValueIsFilled(Operation));

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
	|	EmployeeOperationsHistory.Period AS Period,
	|	BEGINOFPERIOD(EmployeeOperationsHistory.Period, DAY) AS AccountingDate,
	|	DAY(EmployeeOperationsHistory.Period) AS AccountingDay,
	|	WEEK(EmployeeOperationsHistory.Period) AS AccountingWeek,
	|	MONTH(EmployeeOperationsHistory.Period) AS AccountingMonth,
	|	QUARTER(EmployeeOperationsHistory.Period) AS AccountingQuarter,
	|	YEAR(EmployeeOperationsHistory.Period) AS AccountingYear,
	|	EmployeeOperationsHistory.Recorder AS Recorder,
	|	EmployeeOperationsHistory.Employee AS Employee,
	|	EmployeeOperationsHistory.Hotel AS Hotel,
	|	EmployeeOperationsHistory.Room AS Room,
	|	EmployeeOperationsHistory.RoomType AS RoomType,
	|	EmployeeOperationsHistory.Operation AS Operation,
	|	EmployeeOperationsHistory.OperationStartTime AS OperationStartTime,
	|	EmployeeOperationsHistory.Duration AS Duration,
	|	EmployeeOperationsHistory.Duration / 60 AS DurationHour,
	|	EmployeeOperationsHistory.OperationEndTime AS OperationEndTime,
	|	EmployeeOperationsHistory.RoomSpace AS RoomSpace,
	|	EmployeeOperationsHistory.NumberOfPersons AS NumberOfPersons,
	|	EmployeeOperationsHistory.PBXStartCode AS PBXStartCode,
	|	EmployeeOperationsHistory.PBXEndCode AS PBXEndCode,
	|	EmployeeOperationsHistory.Remarks AS Remarks,
	|	EmployeeOperationsHistory.Author AS Author,
	|	EmployeeOperationsHistory.Recorder.Quantity AS OperationQuantity
	|{SELECT
	|	Period,
	|	Room.*,
	|	RoomType.*,
	|	Employee.*,
	|	Operation.*,
	|	OperationStartTime,
	|	Duration,
	|	DurationHour,
	|	OperationEndTime,
	|	RoomSpace,
	|	NumberOfPersons,
	|	PBXStartCode,
	|	PBXEndCode,
	|	Remarks,
	|	AccountingDate,
	|	AccountingDay,
	|	AccountingWeek,
	|	AccountingMonth,
	|	AccountingQuarter,
	|	AccountingYear,
	|	Hotel.*,
	|	Recorder.*,
	|	Author.*,
	|	EmployeeOperationsHistory.PointInTime}
	|FROM
	|	InformationRegister.EmployeeOperationsHistory AS EmployeeOperationsHistory
	|WHERE
	|	(EmployeeOperationsHistory.Employee IN HIERARCHY (&qEmployee)
	|			OR &qIsEmptyEmployee)
	|	AND (EmployeeOperationsHistory.Hotel IN HIERARCHY (&qHotel)
	|			OR &qIsEmptyHotel)
	|	AND (EmployeeOperationsHistory.Room IN HIERARCHY (&qRoom)
	|			OR &qIsEmptyRoom)
	|	AND (EmployeeOperationsHistory.RoomType IN HIERARCHY (&qRoomType)
	|			OR &qIsEmptyRoomType)
	|	AND (EmployeeOperationsHistory.Operation IN HIERARCHY (&qOperation)
	|			OR &qIsEmptyOperation)
	|	AND (EmployeeOperationsHistory.OperationStartTime < &qPeriodTo
	|				AND EmployeeOperationsHistory.OperationEndTime > &qPeriodFrom
	|				AND &qPeriodCheckType = &qIntersection
	|			OR EmployeeOperationsHistory.OperationStartTime >= &qPeriodFrom
	|				AND EmployeeOperationsHistory.OperationStartTime < &qPeriodTo
	|				AND (&qPeriodCheckType = &qCheckIn
	|					OR &qPeriodCheckType = &qCheckInOrCheckOut)
	|			OR EmployeeOperationsHistory.OperationEndTime > &qPeriodFrom
	|				AND EmployeeOperationsHistory.OperationEndTime <= &qPeriodTo
	|				AND (&qPeriodCheckType = &qCheckOut
	|					OR &qPeriodCheckType = &qCheckInOrCheckOut)
	|			OR EmployeeOperationsHistory.Recorder.Date >= &qPeriodFrom
	|				AND EmployeeOperationsHistory.Recorder.Date < &qPeriodTo
	|				AND &qPeriodCheckType = &qDocDateInPeriod)
	|{WHERE
	|	EmployeeOperationsHistory.Period,
	|	EmployeeOperationsHistory.Recorder.*,
	|	EmployeeOperationsHistory.Employee.*,
	|	EmployeeOperationsHistory.Hotel.*,
	|	EmployeeOperationsHistory.Room.*,
	|	EmployeeOperationsHistory.RoomType.*,
	|	EmployeeOperationsHistory.Operation.*,
	|	EmployeeOperationsHistory.OperationStartTime,
	|	EmployeeOperationsHistory.Duration,
	|	(EmployeeOperationsHistory.Duration / 60) AS DurationHour,
	|	EmployeeOperationsHistory.OperationEndTime,
	|	EmployeeOperationsHistory.RoomSpace,
	|	EmployeeOperationsHistory.NumberOfPersons,
	|	EmployeeOperationsHistory.PBXStartCode,
	|	EmployeeOperationsHistory.PBXEndCode,
	|	EmployeeOperationsHistory.Remarks,
	|	EmployeeOperationsHistory.Author.*,
	|	EmployeeOperationsHistory.PointInTime}
	|
	|ORDER BY
	|	Period
	|{ORDER BY
	|	Period,
	|	Recorder.*,
	|	Employee.*,
	|	Hotel.*,
	|	Room.*,
	|	RoomType.*,
	|	Operation.*,
	|	OperationStartTime,
	|	Duration,
	|	DurationHour,
	|	OperationEndTime,
	|	RoomSpace,
	|	NumberOfPersons,
	|	PBXStartCode,
	|	PBXEndCode,
	|	Remarks,
	|	Author.*,
	|	EmployeeOperationsHistory.PointInTime}
	|TOTALS
	|	SUM(Duration),
	|	SUM(DurationHour),
	|	SUM(RoomSpace),
	|	SUM(NumberOfPersons),
	|	SUM(OperationQuantity)
	|BY
	|	OVERALL
	|{TOTALS BY
	|	AccountingDate,
	|	AccountingDay,
	|	AccountingWeek,
	|	AccountingMonth,
	|	AccountingQuarter,
	|	AccountingYear,
	|	Recorder.*,
	|	Employee.*,
	|	Hotel.*,
	|	Room.*,
	|	RoomType.*,
	|	Operation.*,
	|	PBXStartCode,
	|	PBXEndCode,
	|	Author.*}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Employee operations history';RU='Протокол выполнения работ персоналом';de='Protokoll der Arbeitsausführung des Personals'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
