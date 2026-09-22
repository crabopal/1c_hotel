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
		If Not ValueIsFilled(PeriodFrom) Then
			PeriodFrom = BegOfMonth(CurrentSessionDate()); // For beg. of month
			PeriodTo = EndOfDay(CurrentSessionDate());
		EndIf;
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
	If ValueIsFilled(Employee) Then
		If Not Employee.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Employee ';ru='Сотрудник ';de='Mitarbeiter '") + 
			                     TrimAll(Employee.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа сотрудников '; en = 'Employees folder '; de = 'Mitarbeitergruppe '") + 
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
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа работ '; en = 'Operations folder '; de = 'Arbeitengruppe '") + 
			                     TrimAll(Operation.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(Article) Then
		If Not Article.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Номенклатура '; en = 'Article '; de = 'Nomenklatur '") + 
			                     TrimAll(Article.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа номенклатуры '; en = 'Articles folder '; de = 'Nomenklaturgruppe '") + 
			                     TrimAll(Article.Description) + 
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
Procedure pmGenerate(pSpreadsheet, pAddChart = False) Export
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
	ReportBuilder.Parameters.Insert("qEmployee", Employee);
	ReportBuilder.Parameters.Insert("qIsEmptyEmployee", Not ValueIsFilled(Employee));
	ReportBuilder.Parameters.Insert("qOperation", Operation);
	ReportBuilder.Parameters.Insert("qIsEmptyOperation", Not ValueIsFilled(Operation));
	ReportBuilder.Parameters.Insert("qArticle", Article);
	ReportBuilder.Parameters.Insert("qIsEmptyArticle", Not ValueIsFilled(Article));
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qIsEmptyRoom", Not ValueIsFilled(Room));
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qIsEmptyRoomType", Not ValueIsFilled(RoomType));
	vUseCancelled = False;
	For Each vSelFld In ReportBuilder.SelectedFields Do
		If vSelFld.Name = "CancelledCount" Then
			vUseCancelled = True;
			Break;
		EndIf;
	EndDo;
	ReportBuilder.Parameters.Insert("qUseCancelled", vUseCancelled);
			
	
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
	
	// Add chart 
	If pAddChart Then
		cmAddReportChart(pSpreadsheet, ThisObject);
	EndIf;
EndProcedure // pmGenerate
	
// -----------------------------------------------------------------------------
Procedure pmInitializeReportBuilder() Export
	ReportBuilder = New ReportBuilder();
	
	// Initialize default query text
	QueryText = 
	"SELECT
	|	BEGINOFPERIOD(CancelledOperations.Date, DAY) AS AccountingDate,
	|	CancelledOperations.Employee AS Employee,
	|	CancelledOperations.Hotel AS Hotel,
	|	CancelledOperations.RoomType AS RoomType,
	|	CancelledOperations.Room AS Room,
	|	CancelledOperations.Operation AS Operation,
	|	MAX(CancelledOperations.Quantity) AS CancelledCount
	|INTO CancelledOperations
	|FROM
	|	Document.EmployeeOperation AS CancelledOperations
	|WHERE
	|	CancelledOperations.Date >= &qPeriodFrom
	|	AND CancelledOperations.Date <= &qPeriodTo
	|	AND (CancelledOperations.Employee IN HIERARCHY (&qEmployee)
	|			OR &qIsEmptyEmployee)
	|	AND (CancelledOperations.Operation IN HIERARCHY (&qOperation)
	|			OR &qIsEmptyOperation)
	|	AND (CancelledOperations.RoomType IN HIERARCHY (&qRoomType)
	|			OR &qIsEmptyRoomType)
	|	AND (CancelledOperations.Room IN HIERARCHY (&qRoom)
	|			OR &qIsEmptyRoom)
	|	AND (CancelledOperations.Hotel IN HIERARCHY (&qHotel)
	|			OR &qIsEmptyHotel)
	|	AND CancelledOperations.DeletionMark
	|	AND &qUseCancelled
	|
	|GROUP BY
	|	BEGINOFPERIOD(CancelledOperations.Date, DAY),
	|	CancelledOperations.Employee,
	|	CancelledOperations.Hotel,
	|	CancelledOperations.RoomType,
	|	CancelledOperations.Room,
	|	CancelledOperations.Operation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	EmployeeOperationsTurnoverTurnovers.AccountingDate AS AccountingDate,
	|	EmployeeOperationsTurnoverTurnovers.Employee AS Employee,
	|	EmployeeOperationsTurnoverTurnovers.Hotel AS Hotel,
	|	EmployeeOperationsTurnoverTurnovers.RoomType AS RoomType,
	|	EmployeeOperationsTurnoverTurnovers.Room AS Room,
	|	EmployeeOperationsTurnoverTurnovers.Operation AS Operation,
	|	EmployeeOperationsTurnoverTurnovers.Article AS Article,
	|	EmployeeOperationsTurnoverTurnovers.Unit AS Unit,
	|	EmployeeOperationsTurnoverTurnovers.CountTurnover AS CountTurnover,
	|	EmployeeOperationsTurnoverTurnovers.CancelledCount AS CancelledCount,
	|	EmployeeOperationsTurnoverTurnovers.AssignmentDurationTurnover AS AssignmentDurationTurnover,
	|	EmployeeOperationsTurnoverTurnovers.AssignmentDurationTurnover / 60 AS AssignmentDurationInHoursTurnover,
	|	EmployeeOperationsTurnoverTurnovers.WaitDurationTurnover AS WaitDurationTurnover,
	|	EmployeeOperationsTurnoverTurnovers.WaitDurationTurnover / 60 AS WaitDurationInHoursTurnover,
	|	EmployeeOperationsTurnoverTurnovers.DurationTurnover AS DurationTurnover,
	|	EmployeeOperationsTurnoverTurnovers.DurationTurnover / 60 AS DurationInHoursTurnover,
	|	EmployeeOperationsTurnoverTurnovers.ConfirmationDurationTurnover AS ConfirmationDurationTurnover,
	|	EmployeeOperationsTurnoverTurnovers.ConfirmationDurationTurnover / 60 AS ConfirmationDurationInHoursTurnover,
	|	EmployeeOperationsTurnoverTurnovers.TotalDurationTurnover AS TotalDurationTurnover,
	|	EmployeeOperationsTurnoverTurnovers.TotalDurationTurnover / 60 AS TotalDurationInHoursTurnover,
	|	EmployeeOperationsTurnoverTurnovers.RoomSpaceTurnover AS RoomSpaceTurnover,
	|	EmployeeOperationsTurnoverTurnovers.SumTurnover AS SumTurnover,
	|	EmployeeOperationsTurnoverTurnovers.NumberOfPersonsTurnover AS NumberOfPersonsTurnover,
	|	EmployeeOperationsTurnoverTurnovers.QuantityTurnover AS QuantityTurnover,
	|	EmployeeOperationsTurnoverTurnovers.PlannedQuantityTurnover AS PlannedQuantityTurnover
	|{SELECT
	|	AccountingDate,
	|	(WEEK(EmployeeOperationsTurnoverTurnovers.AccountingDate)) AS AccountingWeek,
	|	(MONTH(EmployeeOperationsTurnoverTurnovers.AccountingDate)) AS AccountingMonth,
	|	(QUARTER(EmployeeOperationsTurnoverTurnovers.AccountingDate)) AS AccountingQuarter,
	|	(YEAR(EmployeeOperationsTurnoverTurnovers.AccountingDate)) AS AccountingYear,
	|	Employee.*,
	|	Hotel.*,
	|	RoomType.*,
	|	Operation.*,
	|	Article.*,
	|	Unit,
	|	CountTurnover,
	|	CancelledCount,
	|	AssignmentDurationTurnover,
	|	AssignmentDurationInHoursTurnover,
	|	WaitDurationTurnover,
	|	WaitDurationInHoursTurnover,
	|	DurationTurnover,
	|	DurationInHoursTurnover,
	|	ConfirmationDurationTurnover,
	|	ConfirmationDurationInHoursTurnover,
	|	TotalDurationTurnover,
	|	TotalDurationInHoursTurnover,
	|	RoomSpaceTurnover,
	|	SumTurnover,
	|	NumberOfPersonsTurnover,
	|	QuantityTurnover}
	|FROM
	|	(SELECT
	|		EmployeeOperationsTurnovers.AccountingDate AS AccountingDate,
	|		EmployeeOperationsTurnovers.Employee AS Employee,
	|		EmployeeOperationsTurnovers.Hotel AS Hotel,
	|		EmployeeOperationsTurnovers.RoomType AS RoomType,
	|		EmployeeOperationsTurnovers.Room AS Room,
	|		EmployeeOperationsTurnovers.Operation AS Operation,
	|		EmployeeOperationsTurnovers.Article AS Article,
	|		EmployeeOperationsTurnovers.Unit AS Unit,
	|		SUM(EmployeeOperationsTurnovers.CountTurnover) AS CountTurnover,
	|		SUM(EmployeeOperationsTurnovers.CancelledCount) AS CancelledCount,
	|		SUM(EmployeeOperationsTurnovers.AssignmentDurationTurnover) AS AssignmentDurationTurnover,
	|		SUM(EmployeeOperationsTurnovers.WaitDurationTurnover) AS WaitDurationTurnover,
	|		SUM(EmployeeOperationsTurnovers.DurationTurnover) AS DurationTurnover,
	|		SUM(EmployeeOperationsTurnovers.ConfirmationDurationTurnover) AS ConfirmationDurationTurnover,
	|		SUM(EmployeeOperationsTurnovers.TotalDurationTurnover) AS TotalDurationTurnover,
	|		SUM(EmployeeOperationsTurnovers.RoomSpaceTurnover) AS RoomSpaceTurnover,
	|		SUM(EmployeeOperationsTurnovers.SumTurnover) AS SumTurnover,
	|		SUM(EmployeeOperationsTurnovers.NumberOfPersonsTurnover) AS NumberOfPersonsTurnover,
	|		SUM(EmployeeOperationsTurnovers.QuantityTurnover) AS QuantityTurnover,
	|		SUM(EmployeeOperationsTurnovers.PlannedQuantityTurnover) AS PlannedQuantityTurnover
	|	FROM
	|		(SELECT
	|			EmployeeOperationsTurnoverTurnovers.Period AS AccountingDate,
	|			EmployeeOperationsTurnoverTurnovers.Employee AS Employee,
	|			EmployeeOperationsTurnoverTurnovers.Hotel AS Hotel,
	|			EmployeeOperationsTurnoverTurnovers.RoomType AS RoomType,
	|			EmployeeOperationsTurnoverTurnovers.Room AS Room,
	|			EmployeeOperationsTurnoverTurnovers.Operation AS Operation,
	|			EmployeeOperationsTurnoverTurnovers.Article AS Article,
	|			EmployeeOperationsTurnoverTurnovers.Unit AS Unit,
	|			EmployeeOperationsTurnoverTurnovers.CountTurnover AS CountTurnover,
	|			0 AS CancelledCount,
	|			EmployeeOperationsTurnoverTurnovers.AssignmentDurationTurnover AS AssignmentDurationTurnover,
	|			EmployeeOperationsTurnoverTurnovers.WaitDurationTurnover AS WaitDurationTurnover,
	|			EmployeeOperationsTurnoverTurnovers.DurationTurnover AS DurationTurnover,
	|			EmployeeOperationsTurnoverTurnovers.ConfirmationDurationTurnover AS ConfirmationDurationTurnover,
	|			EmployeeOperationsTurnoverTurnovers.TotalDurationTurnover AS TotalDurationTurnover,
	|			EmployeeOperationsTurnoverTurnovers.RoomSpaceTurnover AS RoomSpaceTurnover,
	|			EmployeeOperationsTurnoverTurnovers.SumTurnover AS SumTurnover,
	|			EmployeeOperationsTurnoverTurnovers.NumberOfPersonsTurnover AS NumberOfPersonsTurnover,
	|			EmployeeOperationsTurnoverTurnovers.QuantityTurnover AS QuantityTurnover,
	|			EmployeeOperationsTurnoverTurnovers.PlannedQuantityTurnover AS PlannedQuantityTurnover
	|		FROM
	|			AccumulationRegister.EmployeeOperationsTurnover.Turnovers(
	|					&qPeriodFrom,
	|					&qPeriodTo,
	|					Day,
	|					(Employee IN HIERARCHY (&qEmployee)
	|						OR &qIsEmptyEmployee)
	|						AND (Operation IN HIERARCHY (&qOperation)
	|							OR &qIsEmptyOperation)
	|						AND (Article IN HIERARCHY (&qArticle)
	|							OR &qIsEmptyArticle)
	|						AND (RoomType IN HIERARCHY (&qRoomType)
	|							OR &qIsEmptyRoomType)
	|						AND (Room IN HIERARCHY (&qRoom)
	|							OR &qIsEmptyRoom)
	|						AND (Hotel IN HIERARCHY (&qHotel)
	|							OR &qIsEmptyHotel)) AS EmployeeOperationsTurnoverTurnovers
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			CancelledOperations.AccountingDate,
	|			CancelledOperations.Employee,
	|			CancelledOperations.Hotel,
	|			CancelledOperations.RoomType,
	|			CancelledOperations.Room,
	|			CancelledOperations.Operation,
	|			VALUE(Catalog.Articles.EmptyRef),
	|			"""",
	|			0,
	|			CancelledOperations.CancelledCount,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0
	|		FROM
	|			CancelledOperations AS CancelledOperations) AS EmployeeOperationsTurnovers
	|	
	|	GROUP BY
	|		EmployeeOperationsTurnovers.AccountingDate,
	|		EmployeeOperationsTurnovers.Employee,
	|		EmployeeOperationsTurnovers.Hotel,
	|		EmployeeOperationsTurnovers.RoomType,
	|		EmployeeOperationsTurnovers.Room,
	|		EmployeeOperationsTurnovers.Operation,
	|		EmployeeOperationsTurnovers.Article,
	|		EmployeeOperationsTurnovers.Unit) AS EmployeeOperationsTurnoverTurnovers
	|{WHERE
	|	EmployeeOperationsTurnoverTurnovers.AccountingDate AS AccountingDate,
	|	EmployeeOperationsTurnoverTurnovers.Employee.*,
	|	EmployeeOperationsTurnoverTurnovers.Hotel.*,
	|	EmployeeOperationsTurnoverTurnovers.RoomType.*,
	|	EmployeeOperationsTurnoverTurnovers.Room.*,
	|	EmployeeOperationsTurnoverTurnovers.Operation.*,
	|	EmployeeOperationsTurnoverTurnovers.Article.*,
	|	EmployeeOperationsTurnoverTurnovers.Unit,
	|	EmployeeOperationsTurnoverTurnovers.CountTurnover,
	|	EmployeeOperationsTurnoverTurnovers.AssignmentDurationTurnover,
	|	EmployeeOperationsTurnoverTurnovers.WaitDurationTurnover,
	|	EmployeeOperationsTurnoverTurnovers.DurationTurnover,
	|	EmployeeOperationsTurnoverTurnovers.ConfirmationDurationTurnover,
	|	EmployeeOperationsTurnoverTurnovers.TotalDurationTurnover,
	|	EmployeeOperationsTurnoverTurnovers.RoomSpaceTurnover,
	|	EmployeeOperationsTurnoverTurnovers.SumTurnover,
	|	EmployeeOperationsTurnoverTurnovers.NumberOfPersonsTurnover,
	|	EmployeeOperationsTurnoverTurnovers.QuantityTurnover}
	|{ORDER BY
	|	AccountingDate,
	|	Employee.*,
	|	Hotel.*,
	|	RoomType.*,
	|	Room.*,
	|	Operation.*,
	|	Article.*,
	|	Unit,
	|	CountTurnover,
	|	AssignmentDurationTurnover,
	|	WaitDurationTurnover,
	|	DurationTurnover,
	|	ConfirmationDurationTurnover,
	|	TotalDurationTurnover,
	|	RoomSpaceTurnover,
	|	SumTurnover,
	|	NumberOfPersonsTurnover,
	|	QuantityTurnover}
	|TOTALS
	|	SUM(CountTurnover),
	|	SUM(CancelledCount),
	|	SUM(AssignmentDurationTurnover),
	|	SUM(AssignmentDurationInHoursTurnover),
	|	SUM(WaitDurationTurnover),
	|	SUM(WaitDurationInHoursTurnover),
	|	SUM(DurationTurnover),
	|	SUM(DurationInHoursTurnover),
	|	SUM(ConfirmationDurationTurnover),
	|	SUM(ConfirmationDurationInHoursTurnover),
	|	SUM(TotalDurationTurnover),
	|	SUM(TotalDurationInHoursTurnover),
	|	SUM(RoomSpaceTurnover),
	|	SUM(SumTurnover),
	|	SUM(NumberOfPersonsTurnover),
	|	SUM(QuantityTurnover),
	|	SUM(PlannedQuantityTurnover)
	|BY
	|	OVERALL,
	|	AccountingDate,
	|	Operation,
	|	Article
	|{TOTALS BY
	|	AccountingDate,
	|	(WEEK(EmployeeOperationsTurnoverTurnovers.AccountingDate)) AS AccountingWeek,
	|	(MONTH(EmployeeOperationsTurnoverTurnovers.AccountingDate)) AS AccountingMonth,
	|	(QUARTER(EmployeeOperationsTurnoverTurnovers.AccountingDate)) AS AccountingQuarter,
	|	(YEAR(EmployeeOperationsTurnoverTurnovers.AccountingDate)) AS AccountingYear,
	|	Employee.*,
	|	Hotel.*,
	|	RoomType.*,
	|	Room.*,
	|	Operation.*,
	|	Article.*,
	|	Unit}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Employee operations turnovers';RU='Обороты по работам персонала';de='Umsätze nach Arbeit des Personals'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
Function pmIsResource(pName) Export
	If pName = "CountTurnover" Or
	   pName = "CancelledCount" Or 
	   pName = "AssignmentDurationTurnover" Or 
	   pName = "AssignmentDurationInHoursTurnover" Or 
	   pName = "WaitDurationTurnover" Or 
	   pName = "WaitDurationInHoursTurnover" Or 
	   pName = "DurationTurnover" Or 
	   pName = "DurationInHoursTurnover" Or 
	   pName = "ConfirmationDurationTurnover" Or 
	   pName = "ConfirmationDurationInHoursTurnover" Or 
	   pName = "TotalDurationTurnover" Or 
	   pName = "TotalDurationInHoursTurnover" Or 
	   pName = "RoomSpaceTurnover" Or 
	   pName = "SumTurnover" Or 
	   pName = "NumberOfPersonsTurnover" Or 
	   pName = "QuantityTurnover" Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // pmIsResource

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
