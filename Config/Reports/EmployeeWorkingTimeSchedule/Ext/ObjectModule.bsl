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
		PeriodFrom = BegOfMonth(CurrentSessionDate()); // Current month
		PeriodTo = EndOfMonth(PeriodFrom);
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
		                     Format(PeriodFrom, "DF='dd.MM.yyyy'") + 
		                     ";" + Chars.LF;
	ElsIf Not ValueIsFilled(PeriodFrom) And ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период по '; en = 'Period to '; de = 'Periode zu '") + 
		                     Format(PeriodTo, "DF='dd.MM.yyyy'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom = PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период на '; en = 'Period on '; de = 'Periode '") + 
		                     Format(PeriodFrom, "DF='dd.MM.yyyy'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom < PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период '; en = 'Period '; de = 'Periode '") + PeriodPresentation(BegOfDay(PeriodFrom), EndOfDay(PeriodTo), cmLocalizationCode()) + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("en='Period is wrong!';ru='Неправильно задан период!';de='Der Zeitraum wurde falsch eingetragen!'") + 
		                     ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(Employee) Then
		If Not Employee.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Employee ';ru='Сотрудник ';de='Mitarbeiter '") + 
			                     TrimAll(Employee.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа сотрудников '; en = 'Employees folder '; de = 'Mitarbeiterengruppe '") + 
			                     TrimAll(Employee.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(Department) Then
		If Not Department.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Отдел '; en = 'Department '; de = 'Department '") + 
			                     TrimAll(Department.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа отделов '; en = 'Departments folder '; de = 'Departmentgruppe '") + 
			                     TrimAll(Department.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(RoomSection) Then
		If Not RoomSection.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Room section ';ru='Секция номеров ';de='Zimmersektion '") + 
			                     TrimAll(RoomSection.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа секций номеров '; en = 'Room sections folder '; de = 'Zimmersektiongruppe '") + 
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
	ReportBuilder.Parameters.Insert("qPeriodFrom", BegOfDay(PeriodFrom));
	ReportBuilder.Parameters.Insert("qPeriodTo", EndOfDay(PeriodTo));
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qIsEmptyHotel", Not ValueIsFilled(Hotel));
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qIsEmptyRoom", Not ValueIsFilled(Room));
	ReportBuilder.Parameters.Insert("qRoomSection", RoomSection);
	ReportBuilder.Parameters.Insert("qIsEmptyRoomSection", Not ValueIsFilled(RoomSection));
	ReportBuilder.Parameters.Insert("qEmployee", Employee);
	ReportBuilder.Parameters.Insert("qIsEmptyEmployee", Not ValueIsFilled(Employee));
	ReportBuilder.Parameters.Insert("qDepartment", Department);
	ReportBuilder.Parameters.Insert("qIsEmptyDepartment", Not ValueIsFilled(Department));

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
	|	EmployeeWorkingTimeSchedule.Employee AS Employee,
	|	EmployeeWorkingTimeSchedule.Room,
	|	EmployeeWorkingTimeSchedule.RoomSection,
	|	EmployeeWorkingTimeSchedule.Period AS Period,
	|	WEEK(EmployeeWorkingTimeSchedule.Period) AS AccountingWeek,
	|	MONTH(EmployeeWorkingTimeSchedule.Period) AS AccountingMonth,
	|	QUARTER(EmployeeWorkingTimeSchedule.Period) AS AccountingQuarter,
	|	YEAR(EmployeeWorkingTimeSchedule.Period) AS AccountingYear,
	|	EmployeeWorkingTimeSchedule.Hours AS Hours,
	|	EmployeeWorkingTimeSchedule.ScheduleDayType
	|{SELECT
	|	Employee.*,
	|	EmployeeWorkingTimeSchedule.Department.*,
	|	RoomSection.*,
	|	Room.*,
	|	Period,
	|	AccountingWeek,
	|	AccountingMonth,
	|	AccountingQuarter,
	|	AccountingYear,
	|	Hours,
	|	ScheduleDayType.*,
	|	EmployeeWorkingTimeSchedule.Timetable.*,
	|	EmployeeWorkingTimeSchedule.Hotel.*,
	|	EmployeeWorkingTimeSchedule.Remarks}
	|FROM
	|	InformationRegister.EmployeeWorkingTimeSchedule AS EmployeeWorkingTimeSchedule
	|WHERE
	|	(EmployeeWorkingTimeSchedule.Employee IN HIERARCHY (&qEmployee)
	|			OR &qIsEmptyEmployee)
	|	AND (EmployeeWorkingTimeSchedule.Hotel IN HIERARCHY (&qHotel)
	|			OR &qIsEmptyHotel)
	|	AND (EmployeeWorkingTimeSchedule.Room IN HIERARCHY (&qRoom)
	|			OR &qIsEmptyRoom)
	|	AND (EmployeeWorkingTimeSchedule.RoomSection IN HIERARCHY (&qRoomSection)
	|			OR &qIsEmptyRoomSection)
	|	AND (EmployeeWorkingTimeSchedule.Department IN HIERARCHY (&qDepartment)
	|			OR &qIsEmptyDepartment)
	|	AND EmployeeWorkingTimeSchedule.Period >= &qPeriodFrom
	|	AND EmployeeWorkingTimeSchedule.Period <= &qPeriodTo
	|{WHERE
	|	EmployeeWorkingTimeSchedule.Employee.*,
	|	EmployeeWorkingTimeSchedule.Department.*,
	|	EmployeeWorkingTimeSchedule.RoomSection.*,
	|	EmployeeWorkingTimeSchedule.Room.*,
	|	EmployeeWorkingTimeSchedule.Period,
	|	EmployeeWorkingTimeSchedule.Hours,
	|	EmployeeWorkingTimeSchedule.ScheduleDayType.*,
	|	EmployeeWorkingTimeSchedule.Timetable.*,
	|	EmployeeWorkingTimeSchedule.Hotel.*,
	|	EmployeeWorkingTimeSchedule.Remarks}
	|
	|ORDER BY
	|	EmployeeWorkingTimeSchedule.Employee.SortCode,
	|	Employee,
	|	Period
	|{ORDER BY
	|	Employee.*,
	|	EmployeeWorkingTimeSchedule.Department.*,
	|	RoomSection.*,
	|	Room.*,
	|	Period,
	|	Hours,
	|	ScheduleDayType.*,
	|	EmployeeWorkingTimeSchedule.Timetable.*,
	|	EmployeeWorkingTimeSchedule.Hotel.*,
	|	EmployeeWorkingTimeSchedule.Remarks}
	|TOTALS
	|	SUM(Hours)
	|BY
	|	OVERALL,
	|	Employee,
	|	Period
	|{TOTALS BY
	|	Period,
	|	AccountingWeek,
	|	AccountingMonth,
	|	AccountingQuarter,
	|	AccountingYear,
	|	Employee.*,
	|	EmployeeWorkingTimeSchedule.Department.*,
	|	RoomSection.*,
	|	Room.*,
	|	Hours,
	|	ScheduleDayType.*,
	|	EmployeeWorkingTimeSchedule.Timetable.*,
	|	EmployeeWorkingTimeSchedule.Hotel.*}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Employee working time schedule';RU='График рабочего времени сотрудников';de='Arbeitszeitplan der Mitarbeiter'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
