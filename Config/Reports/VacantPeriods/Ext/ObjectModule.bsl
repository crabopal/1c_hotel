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
	If Not ValueIsFilled(PeriodFrom) Then
		PeriodFrom = BegOfMonth(BegOfMonth(CurrentSessionDate()) - 1);
	EndIf;
	If Not ValueIsFilled(PeriodTo) Then
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
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	
	// Run base query
	vQry = New Query();
	vQry.Text = QueryText;
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qPeriodFrom", PeriodFrom);
	vQry.SetParameter("qPeriodTo", PeriodTo);
	vQry.SetParameter("qRoom", Room);
	vQry.SetParameter("qRoomType", RoomType);
	vTab = vQry.Execute().Unload();
		
	vPeriodsTab = ConvertToPeriodsForm(vTab);
		
	ReportBuilder.DataSource = New DataSourceDescription(vPeriodsTab);
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);

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
	|	VacantPeriods.Room AS Room,
	|	VacantPeriods.RoomType AS RoomType,
	|	VacantPeriods.PeriodFrom AS PeriodFrom,
	|	0 AS Duration,
	|	VacantPeriods.PeriodFrom AS PeriodTo,
	|	ISNULL(VacantPeriods.RoomsVacantOpeningBalance, 0) AS RoomsVacantOpeningBalance,
	|	ISNULL(VacantPeriods.RoomsVacantClosingBalance, 0) AS RoomsVacantClosingBalance
	|{SELECT
	|	VacantPeriods.Hotel.* AS Hotel,
	|	Room.* AS Room,
	|	RoomType.* AS RoomType,
	|	PeriodFrom AS PeriodFrom,
	|	Duration AS Duration,
	|	PeriodTo AS PeriodTo}
	|FROM
	|	(SELECT
	|		RoomInventoryBalance.Hotel AS Hotel,
	|		RoomInventoryBalance.Room AS Room,
	|		RoomInventoryBalance.RoomType AS RoomType,
	|		RoomInventoryBalance.Period AS PeriodFrom,
	|		RoomInventoryBalance.RoomsVacantOpeningBalance AS RoomsVacantOpeningBalance,
	|		RoomInventoryBalance.RoomsVacantClosingBalance AS RoomsVacantClosingBalance,
	|		RoomInventoryBalance.TotalRoomsClosingBalance AS TotalRoomsBalance
	|	FROM
	|		AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				SECOND,
	|				RegisterRecordsAndPeriodBoundaries,
	|				Hotel IN HIERARCHY (&qHotel)
	|					AND RoomType IN HIERARCHY (&qRoomType)
	|					AND Room IN HIERARCHY (&qRoom)) AS RoomInventoryBalance
	|	WHERE
	|		RoomInventoryBalance.TotalRoomsClosingBalance > 0) AS VacantPeriods
	|{WHERE
	|	VacantPeriods.Hotel.* AS Hotel,
	|	VacantPeriods.Room.* AS Room,
	|	VacantPeriods.RoomType.* AS RoomType}
	|
	|ORDER BY
	|	VacantPeriods.Room.SortCode,
	|	PeriodFrom
	|{ORDER BY
	|	VacantPeriods.Hotel.* AS Hotel,
	|	Room.*,
	|	RoomType.*}
	|TOTALS BY
	|	OVERALL
	|{TOTALS BY
	|	VacantPeriods.Hotel.* AS Hotel,
	|	Room.*,
	|	RoomType.*}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("en='Vacant room periods';ru='Свободные периоды номеров';de='Freie Zimmer Perioden'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Function ConvertToPeriodsForm(pTab)
	vPeriodsTab = pTab.Copy();
	vPeriodsTab.Clear();
	vPeriodsTab.Columns.Delete("RoomsVacantOpeningBalance");
	vPeriodsTab.Columns.Delete("RoomsVacantClosingBalance");
	
	vCurRoom = Undefined;
	vPeriodsTabRow = Undefined;
	For Each vTabRow In pTab Do
		If vTabRow.RoomsVacantOpeningBalance = Null Or vTabRow.RoomsVacantClosingBalance = Null Then
			Continue;
		EndIf;
		If vCurRoom <> vTabRow.Room Then
			vPeriodsTabRow = Undefined;
			vCurRoom = vTabRow.Room;
		EndIf;
		If vTabRow.RoomsVacantOpeningBalance > 0 And vTabRow.RoomsVacantClosingBalance > 0 Then
			vPeriodsTabRow = vPeriodsTab.Add();
			FillPropertyValues(vPeriodsTabRow, vTabRow);
		ElsIf vTabRow.RoomsVacantOpeningBalance <= 0 And vTabRow.RoomsVacantClosingBalance > 0 Then
			vPeriodsTabRow = vPeriodsTab.Add();
			FillPropertyValues(vPeriodsTabRow, vTabRow);
		ElsIf vTabRow.RoomsVacantOpeningBalance > 0 And vTabRow.RoomsVacantClosingBalance <= 0 Then
			If vPeriodsTabRow = Undefined Then
				vPeriodsTabRow = vPeriodsTab.Add();
				FillPropertyValues(vPeriodsTabRow, vTabRow);
			Else
				vPeriodsTabRow.PeriodTo = vTabRow.PeriodFrom;
			EndIf;
		ElsIf vTabRow.RoomsVacantOpeningBalance <= 0 And vTabRow.RoomsVacantClosingBalance <= 0 Then
			If vPeriodsTabRow = Undefined Then
				vPeriodsTabRow = vPeriodsTab.Add();
				FillPropertyValues(vPeriodsTabRow, vTabRow);
			EndIf;
		EndIf;
	EndDo;
	For Each vPeriodsTabRow In vPeriodsTab Do
		If vPeriodsTabRow.PeriodFrom = vPeriodsTabRow.PeriodTo Then
			vPeriodsTabRow.PeriodTo = PeriodTo;
		EndIf;
		vPeriodsTabRow.Duration = Round((vPeriodsTabRow.PeriodTo - vPeriodsTabRow.PeriodFrom)/(24*3600), 0);
	EndDo;
	i = 0;
	While i < vPeriodsTab.Count() Do
		vPeriodsTabRow = vPeriodsTab.Get(i);
		If vPeriodsTabRow.PeriodFrom = vPeriodsTabRow.PeriodTo And vPeriodsTabRow.PeriodTo = PeriodTo Then
			vPeriodsTab.Delete(i);
		Else
			i = i + 1;
		EndIf;
	EndDo;
	Return vPeriodsTab;
EndFunction // ConvertToPeriodsForm
