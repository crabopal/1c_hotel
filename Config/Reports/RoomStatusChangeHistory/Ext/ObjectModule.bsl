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
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qIsEmptyRoom", Not ValueIsFilled(Room));
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qIsEmptyRoomType", Not ValueIsFilled(RoomType));
	ReportBuilder.Parameters.Insert("qEmployee", Employee);
	ReportBuilder.Parameters.Insert("qIsEmptyEmployee", Not ValueIsFilled(Employee));
	ReportBuilder.Parameters.Insert("qRoomStatus", RoomStatus);
	ReportBuilder.Parameters.Insert("qIsEmptyRoomStatus", Not ValueIsFilled(RoomStatus));

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
	|	RoomStatusChangeHistory.Period AS Period,
	|	BEGINOFPERIOD(RoomStatusChangeHistory.Period, DAY) AS AccountingDate,
	|	DAY(RoomStatusChangeHistory.Period) AS AccountingDay,
	|	WEEK(RoomStatusChangeHistory.Period) AS AccountingWeek,
	|	MONTH(RoomStatusChangeHistory.Period) AS AccountingMonth,
	|	QUARTER(RoomStatusChangeHistory.Period) AS AccountingQuarter,
	|	YEAR(RoomStatusChangeHistory.Period) AS AccountingYear,
	|	RoomStatusChangeHistory.User AS Employee,
	|	RoomStatusChangeHistory.Room.Owner AS Hotel,
	|	RoomStatusChangeHistory.Room,
	|	RoomStatusChangeHistory.Room.RoomType AS RoomType,
	|	RoomStatusChangeHistory.RoomStatus,
	|	RoomStatusChangeHistory.Remarks
	|{SELECT
	|	Period,
	|	Room.*,
	|	RoomType.*,
	|	Employee.*,
	|	RoomStatus.*,
	|	Remarks,
	|	(BEGINOFPERIOD(RoomStatusChangeHistory.Period, DAY)) AS AccountingDate,
	|	(DAY(RoomStatusChangeHistory.Period)) AS AccountingDay,
	|	(WEEK(RoomStatusChangeHistory.Period)) AS AccountingWeek,
	|	(MONTH(RoomStatusChangeHistory.Period)) AS AccountingMonth,
	|	(QUARTER(RoomStatusChangeHistory.Period)) AS AccountingQuarter,
	|	(YEAR(RoomStatusChangeHistory.Period)) AS AccountingYear,
	|	Hotel.*}
	|FROM
	|	InformationRegister.RoomStatusChangeHistory AS RoomStatusChangeHistory
	|WHERE
	|	(RoomStatusChangeHistory.User IN HIERARCHY (&qEmployee)
	|			OR &qIsEmptyEmployee)
	|	AND (RoomStatusChangeHistory.Room.Owner IN HIERARCHY (&qHotel)
	|			OR &qIsEmptyHotel)
	|	AND (RoomStatusChangeHistory.Room IN HIERARCHY (&qRoom)
	|			OR &qIsEmptyRoom)
	|	AND (RoomStatusChangeHistory.Room.RoomType IN HIERARCHY (&qRoomType)
	|			OR &qIsEmptyRoomType)
	|	AND (RoomStatusChangeHistory.RoomStatus IN HIERARCHY (&qRoomStatus)
	|			OR &qIsEmptyRoomStatus)
	|	AND RoomStatusChangeHistory.Period >= &qPeriodFrom
	|	AND RoomStatusChangeHistory.Period <= &qPeriodTo
	|{WHERE
	|	RoomStatusChangeHistory.Period,
	|	RoomStatusChangeHistory.User.* AS Employee,
	|	RoomStatusChangeHistory.Room.Owner.* AS Hotel,
	|	RoomStatusChangeHistory.Room.*,
	|	RoomStatusChangeHistory.Room.RoomType.* AS RoomType,
	|	RoomStatusChangeHistory.RoomStatus.*,
	|	RoomStatusChangeHistory.Remarks}
	|
	|ORDER BY
	|	Period
	|{ORDER BY
	|	Period,
	|	Employee.*,
	|	Hotel.*,
	|	Room.*,
	|	RoomType.*,
	|	RoomStatus.*,
	|	Remarks}
	|TOTALS BY
	|	OVERALL
	|{TOTALS BY
	|	AccountingDate,
	|	AccountingDay,
	|	AccountingWeek,
	|	AccountingMonth,
	|	AccountingQuarter,
	|	AccountingYear,
	|	Employee.*,
	|	Hotel.*,
	|	Room.*,
	|	RoomType.*,
	|	RoomStatus.*}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Room status change history';RU='История изменения статусов номеров';de=' Änderungsverlauf der Zimmerstatus'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
