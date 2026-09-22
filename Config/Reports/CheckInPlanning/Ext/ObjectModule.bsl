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
		PeriodFrom = BegOfDay(CurrentSessionDate());
		PeriodTo = EndOfDay(PeriodFrom) + 90*24*3600;
	EndIf;
	If PeriodOfStay = 0 Then
		PeriodOfStay = 1;
	EndIf;
	If Not ValueIsFilled(DurationCalculationRuleType) Then
		DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour;
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
	If PeriodOfStay > 0 Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Продолжительность проживания '; en = 'Period of stay '; de = 'Zeitraum des Aufenthalts '") + 
							 Format(PeriodOfStay, "ND=10; NFD=0; NG=") + 
							 ";" + Chars.LF;
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
	
	// Run main query to get data
	QueryText = ReportBuilder.Text;
	
	vQry = New Query();
	vQry.Text = TrimAll(QueryText);
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qIsEmptyHotel", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qPeriodFrom", PeriodFrom);
	vQry.SetParameter("qPeriodTo", PeriodTo);
	vQry.SetParameter("qRoom", Room);
	vQry.SetParameter("qIsEmptyRoom", Not ValueIsFilled(Room));
	vQry.SetParameter("qRoomType", RoomType);
	vQry.SetParameter("qIsEmptyRoomType", Not ValueIsFilled(RoomType));
	vVacants = vQry.Execute().Unload();
	
	// Initialize results table
	vResults = vVacants.CopyColumns("Hotel, RoomType, RoomsVacant, BedsVacant, RoomsAvailable, BedsAvailable");
	vResults.Columns.Add("CheckInDate", cmGetDateTimeTypeDescription());
	vResults.Columns.Add("Duration", cmGetNumberTypeDescription(10, 0));
	vResults.Columns.Add("CheckOutDate", cmGetDateTimeTypeDescription());
	
	// Check period of stay duration
	PeriodOfStay = ?(PeriodOfStay > 0, PeriodOfStay, 1);
	
	// Check duration calculation rule
	If Not ValueIsFilled(DurationCalculationRuleType) Then
		DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour;
	EndIf;
	
	// Check minimum vacant room balances for the each possible check-in period
	vCurCheckInDate = BegOfDay(PeriodFrom);
	If DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByDays Then
		vCurCheckOutDate = vCurCheckInDate + (PeriodOfStay-1)*24*3600;
	Else
		vCurCheckOutDate = vCurCheckInDate + PeriodOfStay*24*3600;
	EndIf;
	While vCurCheckOutDate <= BegOfDay(PeriodTo) Do
		// Calculate minimum vacant rooms/beds balances for the current period
		For Each vVacantsRow In vVacants Do
			If Not ValueIsFilled(vVacantsRow.Period) Or Not ValueIsFilled(vVacantsRow.Hotel) Then
				Continue;
			EndIf;
			If vVacantsRow.Period >= vCurCheckInDate And vVacantsRow.Period < vCurCheckOutDate Then
				// Try to find results row for the given hotel, room type and day
				vResultsRows = vResults.FindRows(New Structure("Hotel, RoomType, CheckInDate", vVacantsRow.Hotel, vVacantsRow.RoomType, vCurCheckInDate));
				vResultsRow = Undefined;
				If vResultsRows.Count() > 0 Then
					vResultsRow = vResultsRows.Get(0);
					vResultsRow.RoomsVacant = Min(vResultsRow.RoomsVacant, vVacantsRow.RoomsVacant);
					vResultsRow.BedsVacant = Min(vResultsRow.BedsVacant, vVacantsRow.BedsVacant);
					vResultsRow.RoomsAvailable = Min(vResultsRow.RoomsAvailable, vVacantsRow.RoomsAvailable);
					vResultsRow.BedsAvailable = Min(vResultsRow.BedsAvailable, vVacantsRow.BedsAvailable);
				Else
					vResultsRow = vResults.Add();
					vResultsRow.Hotel = vVacantsRow.Hotel;
					vResultsRow.RoomType = vVacantsRow.RoomType;
					vResultsRow.CheckInDate = vCurCheckInDate;
					vResultsRow.CheckOutDate = vCurCheckOutDate;
					vResultsRow.Duration = PeriodOfStay;
					vResultsRow.RoomsVacant = vVacantsRow.RoomsVacant;
					vResultsRow.BedsVacant = vVacantsRow.BedsVacant;
					vResultsRow.RoomsAvailable = vVacantsRow.RoomsAvailable;
					vResultsRow.BedsAvailable = vVacantsRow.BedsAvailable;
				EndIf;
			EndIf;
		EndDo;
		
		// Subtract check-in period vacant rooms/beds from the vacants value table
		vResultsRows = vResults.FindRows(New Structure("CheckInDate", vCurCheckInDate));
		For Each vResultsRow In vResultsRows Do
			vVacantsRows = vVacants.FindRows(New Structure("Hotel, RoomType", vResultsRow.Hotel, vResultsRow.RoomType));
			For Each vVacantsRow In vVacantsRows Do
				If Not ValueIsFilled(vVacantsRow.Period) Or Not ValueIsFilled(vVacantsRow.Hotel) Then
					Continue;
				EndIf;
				If vVacantsRow.Period >= vResultsRow.CheckInDate And 
				   vVacantsRow.Period < vResultsRow.CheckOutDate Then
					If vResultsRow.RoomsVacant > 0 Then
						vVacantsRow.RoomsVacant = vVacantsRow.RoomsVacant - vResultsRow.RoomsVacant;
					EndIf;
					If vResultsRow.BedsVacant > 0 Then
						vVacantsRow.BedsVacant = vVacantsRow.BedsVacant - vResultsRow.BedsVacant;
					EndIf;
				EndIf;
			EndDo;
		EndDo;
		
		// Go to the next day
		vCurCheckInDate = vCurCheckInDate + 24*3600;
		If DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByDays Then
			vCurCheckOutDate = vCurCheckInDate + (PeriodOfStay-1)*24*3600;
		Else
			vCurCheckOutDate = vCurCheckInDate + PeriodOfStay*24*3600;
		EndIf;
	EndDo;
		
	// Delete rows with negative or zero balances from the results value table
	i = 0;
	While i < vResults.Count() Do
		vResultsRow = vResults.Get(i);
		If vResultsRow.RoomsVacant <= 0 And vResultsRow.BedsVacant <= 0 Then
			vResults.Delete(i);
		Else
			i = i + 1;
		EndIf;
	EndDo;
	
	// Add totals row
	vTotalsRow = vResults.Add();
	vTotalsRow.RoomsVacant = vResults.Total("RoomsVacant");
	vTotalsRow.BedsVacant = vResults.Total("BedsVacant");

	// Save current report builder settings
	vCurReportBuilderSettings = ReportBuilder.GetSettings(True, True, False, True, True);
	
	// Set resulting table as data source for the report builder
	ReportBuilder.DataSource = New DataSourceDescription(vResults);
	
	// Apply current report builder settings
	ReportBuilder.SetSettings(vCurReportBuilderSettings, True, True, False, True, True);
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Execute report builder
	ReportBuilder.Execute();
	
	// Apply appearance settings to the report template
	vTemplateAttributes = cmApplyReportTemplateAppearance(ThisObject);
	
	// Output report to the spreadsheet
	ReportBuilder.Put(pSpreadsheet);
	//ReportBuilder.Template.Show(); // For debug purpose

	// Add totals caption and appearance to the last report row
	vLastRepRow = pSpreadsheet.Area(pSpreadsheet.TableHeight-2, 2, pSpreadsheet.TableHeight-2, pSpreadsheet.TableWidth);
	vLastRepRow.Font = New Font(pSpreadsheet.Area(pSpreadsheet.TableHeight-2, 2, pSpreadsheet.TableHeight-2, 2).Font, , , True);
	vLastRepRow.BackColor = pSpreadsheet.Area(4, 2, 4, 2).BackColor;
	pSpreadsheet.Area(pSpreadsheet.TableHeight-2, 2, pSpreadsheet.TableHeight-2, 2).Text = NStr("en='Totals';ru='Итог';de='Ergebnis'");
	
	// Apply appearance settings to the report spreadsheet
	cmApplyReportAppearance(ThisObject, pSpreadsheet, vTemplateAttributes);
EndProcedure // pmGenerate
	
// -----------------------------------------------------------------------------
Procedure pmInitializeReportBuilder() Export
	ReportBuilder = New ReportBuilder();
	
	// Initialize default query text
	QueryText = 
	"SELECT
	|	RoomInventoryBalance.Period AS Period,
	|	RoomInventoryBalance.Hotel AS Hotel,
	|	RoomInventoryBalance.RoomType AS RoomType,
	|	RoomInventoryBalance.RoomsVacantClosingBalance AS RoomsVacant,
	|	RoomInventoryBalance.BedsVacantClosingBalance AS BedsVacant,
	|	RoomInventoryBalance.TotalRoomsClosingBalance + RoomInventoryBalance.RoomsBlockedClosingBalance AS RoomsAvailable,
	|	RoomInventoryBalance.TotalBedsClosingBalance + RoomInventoryBalance.BedsBlockedClosingBalance AS BedsAvailable,
	|	RoomInventoryBalance.Hotel.SortCode AS HotelSortCode,
	|	RoomInventoryBalance.RoomType.SortCode AS RoomTypeSortCode
	|{SELECT
	|	Period,
	|	RoomInventoryBalance.Period AS CheckInDate,
	|	(0) AS Duration,
	|	RoomInventoryBalance.Period AS CheckOutDate,
	|	Hotel.*,
	|	RoomType.*,
	|	RoomsVacant,
	|	BedsVacant,
	|	RoomsAvailable,
	|	BedsAvailable}
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			RegisterRecordsAndPeriodBoundaries,
	|			(Hotel IN HIERARCHY (&qHotel)
	|				OR &qIsEmptyHotel)
	|				AND (Room IN HIERARCHY (&qRoom)
	|					OR &qIsEmptyRoom)
	|				AND (RoomType IN HIERARCHY (&qRoomType)
	|					OR &qIsEmptyRoomType)) AS RoomInventoryBalance
	|{WHERE
	|	RoomInventoryBalance.Period,
	|	RoomInventoryBalance.Period AS CheckInDate,
	|	(0) AS Duration,
	|	RoomInventoryBalance.Period AS CheckOutDate,
	|	RoomInventoryBalance.Hotel.*,
	|	RoomInventoryBalance.RoomType.*,
	|	RoomInventoryBalance.RoomsVacantClosingBalance AS RoomsVacant,
	|	RoomInventoryBalance.BedsVacantClosingBalance AS BedsVacant,
	|	(RoomInventoryBalance.TotalRoomsClosingBalance + RoomInventoryBalance.RoomsBlockedClosingBalance) AS RoomsAvailable,
	|	(RoomInventoryBalance.TotalBedsClosingBalance + RoomInventoryBalance.BedsBlockedClosingBalance) AS BedsAvailable}
	|
	|ORDER BY
	|	HotelSortCode,
	|	RoomTypeSortCode,
	|	Period
	|{ORDER BY
	|	Period,
	|	RoomInventoryBalance.Period AS CheckInDate,
	|	(0) AS Duration,
	|	RoomInventoryBalance.Period AS CheckOutDate,
	|	Hotel.*,
	|	RoomType.*,
	|	RoomsVacant,
	|	BedsVacant,
	|	RoomsAvailable,
	|	BedsAvailable}
	|TOTALS
	|	SUM(RoomsVacant),
	|	SUM(BedsVacant),
	|	SUM(RoomsAvailable),
	|	SUM(BedsAvailable)
	|BY
	|	Hotel HIERARCHY,
	|	RoomType HIERARCHY,
	|	Period PERIODS(DAY, &qPeriodFrom, &qPeriodTo)";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Check-in planning';RU='Планирование заездов';de='Planung der Anreisen'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
