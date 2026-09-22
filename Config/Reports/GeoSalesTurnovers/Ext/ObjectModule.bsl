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
		PeriodFrom = BegOfMonth(CurrentSessionDate()); // For beg of month
		PeriodTo = EndOfDay(CurrentSessionDate());
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
		                     Format(PeriodFrom, "DF='dd.MM.yyyy HH:mm:ss'") + 
		                     ";" + Chars.LF;
	ElsIf Not ValueIsFilled(PeriodFrom) And ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период по '; en = 'Period to '; de = 'Periode zu '") + 
		                     Format(PeriodTo, "DF='dd.MM.yyyy HH:mm:ss'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom = PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период на '; en = 'Period on '; de = 'Periode '") + 
		                     Format(PeriodFrom, "DF='dd.MM.yyyy HH:mm:ss'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom < PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период '; en = 'Period '; de = 'Periode '") + PeriodPresentation(PeriodFrom, PeriodTo, cmLocalizationCode()) + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("en='Period is wrong!';ru='Неправильно задан период!';de='Der Zeitraum wurde falsch eingetragen!'") + 
		                     ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(ClientCitizenship) Then
		If Not ClientCitizenship.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Страна '; en = 'Country '; de = 'Land '") + 
			                     TrimAll(ClientCitizenship.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа стран '; en = 'Countries folder '; de = 'Landgruppe '") + 
			                     TrimAll(ClientCitizenship.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(TripPurpose) Then
		If Not TripPurpose.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Цель визита '; en = 'Trip purpose '; de = 'Reise Zweck '") + 
			                     TrimAll(TripPurpose.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа целей '; en = 'Trip purpose folder '; de = 'Reisezweckgruppe '") + 
			                     TrimAll(TripPurpose.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(SourceOfBusiness) Then
		If Not SourceOfBusiness.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Источник информации '; en = 'Source of buisiness '; de = 'Quelle '") + 
			                     TrimAll(SourceOfBusiness.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа источников '; en = 'Source of business folder '; de = 'Quellegruppe '") + 
			                     TrimAll(SourceOfBusiness.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(ServiceGroup) Then
		If Not ServiceGroup.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Набор услуг '; en = 'Service group '; de = 'Dienstgruppe '") + 
			                     TrimAll(ServiceGroup.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа наборов услуг '; en = 'Service groups folder '; de = 'Dienstgruppengruppe '") + 
			                     TrimAll(ServiceGroup.Description) + 
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
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	vForecastStartDate = tcOnServer.GetForecastStartDate(Hotel);
	ReportBuilder.Parameters.Insert("qUseForecast", ?(ValueIsFilled(PeriodTo), ?(PeriodTo > EndOfDay(vForecastStartDate-24*3600), True, False), True));
	ReportBuilder.Parameters.Insert("qForecastPeriodFrom", Max(BegOfDay(PeriodFrom), vForecastStartDate));
	ReportBuilder.Parameters.Insert("qForecastPeriodTo", ?(ValueIsFilled(PeriodTo), Max(PeriodTo, EndOfDay(vForecastStartDate-24*3600)), '00010101'));
	ReportBuilder.Parameters.Insert("qEmptyDate", '00010101');
	ReportBuilder.Parameters.Insert("qClientCitizenship", ClientCitizenship);
	ReportBuilder.Parameters.Insert("qIsEmptyClientCitizenship", Not ValueIsFilled(ClientCitizenship));
	ReportBuilder.Parameters.Insert("qTripPurpose", TripPurpose);
	ReportBuilder.Parameters.Insert("qIsEmptyTripPurpose", Not ValueIsFilled(TripPurpose));
	ReportBuilder.Parameters.Insert("qSourceOfBusiness", SourceOfBusiness);
	ReportBuilder.Parameters.Insert("qIsEmptySourceOfBusiness", Not ValueIsFilled(SourceOfBusiness));
	vUseServicesList = False;
	vServicesList = New ValueList();
	If ValueIsFilled(ServiceGroup) Then
		If Not ServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(ServiceGroup);
		EndIf;
	EndIf;
	ReportBuilder.Parameters.Insert("qUseServicesList", vUseServicesList);
	ReportBuilder.Parameters.Insert("qServicesList", vServicesList);
	ReportBuilder.Parameters.Insert("qUndefinedAge", NStr("en='1. <Undefined>';ru='1. <Не указан>';de='1. <Nicht angegeben>'"));
	ReportBuilder.Parameters.Insert("qChild", NStr("en='2. Child (1 - 14)';ru='2. Ребенок (1 - 14)';de='2. Kind (1 - 14)'"));
	ReportBuilder.Parameters.Insert("qTeenager", NStr("en='3. Teenager (15 - 21)';ru='3. Тинейджер (15 - 21)';de='3. Teenager (15-21)'"));
	ReportBuilder.Parameters.Insert("q2229", NStr("en='4. Adult (22 - 29)';ru='4. Взрослый (22 - 29)';de='4. Erwachsener (22 - 29)'"));
	ReportBuilder.Parameters.Insert("q3039", NStr("en='5. Adult (30 - 39)';ru='5. Взрослый (30 - 39)';de='5. Erwachsener (30 - 39)'"));
	ReportBuilder.Parameters.Insert("q4049", NStr("en='6. Adult (40 - 49)';ru='6. Взрослый (40 - 49)';de='6. Erwachsener (40 - 49)'"));
	ReportBuilder.Parameters.Insert("q5059", NStr("en='7. Adult (50 - 59)';ru='7. Взрослый (50 - 59)';de='7. Erwachsener (50-59)'"));
	ReportBuilder.Parameters.Insert("qGreater60", NStr("en='8. Above 60';ru='8. Старше 60';de='8. älter als 60'"));
	ReportBuilder.Parameters.Insert("qCustomAttribute1", CustomAttribute1);
	ReportBuilder.Parameters.Insert("qCustomAttribute2", CustomAttribute2);
	ReportBuilder.Parameters.Insert("qCustomAttribute3", CustomAttribute3);
	// Check report dimensions being used in current report settings
	vReportDimensionsUsage = New ValueTable();
	vReportDimensionsUsage.Columns.Add("Name");
	vReportDimensionsUsage.Columns.Add("IsUsed", cmGetBooleanTypeDescription());
	For Each vDim In Metadata.AccumulationRegisters.Sales.Dimensions Do
		vReportDimensionsUsageRow = vReportDimensionsUsage.Add();
		vReportDimensionsUsageRow.Name = vDim.Name;
		vReportDimensionsUsageRow.IsUsed = False;
	EndDo;
	vSelectedFields = cmGetReportUsedFields(ReportBuilder);
	For Each vReportDimensionsUsageRow In vReportDimensionsUsage Do
		If vReportDimensionsUsageRow.Name = "Hotel" Then
			vReportDimensionsUsageRow.IsUsed = True;
		EndIf;
		If vReportDimensionsUsageRow.Name = "GuestGroup" Then
			vReportDimensionsUsageRow.IsUsed = True;
		EndIf;
		If vReportDimensionsUsageRow.Name = "ParentDoc" Then
			vReportDimensionsUsageRow.IsUsed = True;
		EndIf;
		For Each vReportField In vSelectedFields Do
			If vReportField.DataPath = vReportDimensionsUsageRow.Name Or Left(vReportField.DataPath, StrLen(vReportDimensionsUsageRow.Name)) = vReportDimensionsUsageRow.Name Then
				vReportDimensionsUsageRow.IsUsed = True;
			EndIf;
			If vReportDimensionsUsageRow.Name = "AccountingDate" Then
				If vReportField.DataPath = "AccountingWeek" Or vReportField.DataPath = "AccountingWeekday" Or vReportField.DataPath = "AccountingWeekdayName" Or 
				   vReportField.DataPath = "AccountingMonth" Or vReportField.DataPath = "AccountingQuarter" Or vReportField.DataPath = "AccountingYear" Or
				   vReportField.DataPath = "AccountingDay" Then
					vReportDimensionsUsageRow.IsUsed = True;
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	vRBSettings = ReportBuilder.GetSettings(True, True, True, True, True);
	vQryText = ReportBuilder.Text;
	For Each vReportDimensionsUsageRow In vReportDimensionsUsage Do
		If Not vReportDimensionsUsageRow.IsUsed Then
			vQryText = StrReplace(vQryText, "GeoSalesTurnovers." + vReportDimensionsUsageRow.Name + " AS ", "NULL AS ");
			If vReportDimensionsUsageRow.Name = "Client" Then
				vQryText = StrReplace(vQryText, "GeoSalesTurnovers.Client.Citizenship IS NULL", "FALSE");
				vQryText = StrReplace(vQryText, "GeoSalesTurnovers.GuestGroup.Citizenship", "NULL");
				vQryText = StrReplace(vQryText, "GeoSalesTurnovers.Client.Citizenship", "NULL");
				vQryText = StrReplace(vQryText, "GeoSalesTurnovers.Client.DateOfBirth AS ", "NULL AS ");
				vQryText = StrReplace(vQryText, "GeoSalesTurnovers.Client.Region AS ", "NULL AS ");
				vQryText = StrReplace(vQryText, "GeoSalesTurnovers.Client.City AS ", "NULL AS ");
				vQryText = StrReplace(vQryText, "GeoSalesTurnovers.Client.Age AS ", "NULL AS ");
			EndIf;
			If vReportDimensionsUsageRow.Name = "AccountingDate" Then
				vQryText = StrReplace(vQryText, "BEGINOFPERIOD(GeoSales.AccountingDate, WEEK)", "0");
				vQryText = StrReplace(vQryText, "BEGINOFPERIOD(GeoSales.AccountingDate, MONTH)", "0");
				vQryText = StrReplace(vQryText, "BEGINOFPERIOD(GeoSales.AccountingDate, QUARTER)", "0");
				vQryText = StrReplace(vQryText, "YEAR(GeoSales.AccountingDate)", "0");
			EndIf;				
		EndIf;
	EndDo;
	ReportBuilder.Text = vQryText;
	ReportBuilder.FillSettings();
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	cmFillReportAttributesPresentations(ThisObject);
	ReportBuilder.Template = Undefined;
	
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
	
	// Restore report default query text
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	cmFillReportAttributesPresentations(ThisObject);
	ReportBuilder.Template = Undefined;
EndProcedure // pmGenerate
	
// -----------------------------------------------------------------------------
Procedure pmInitializeReportBuilder() Export
	ReportBuilder = New ReportBuilder();
	
	// Initialize default query text
	QueryText = 
	"SELECT
	|	TotalInventoryBalanceAndTurnovers.Hotel AS Hotel,
	|	SUM(TotalInventoryBalanceAndTurnovers.CounterClosingBalance) AS CounterClosingBalance,
	|	SUM(TotalInventoryBalanceAndTurnovers.TotalRoomsClosingBalance) AS TotalRooms,
	|	SUM(TotalInventoryBalanceAndTurnovers.TotalBedsClosingBalance) AS TotalBeds,
	|	-SUM(TotalInventoryBalanceAndTurnovers.RoomsBlockedClosingBalance) AS TotalRoomsBlocked,
	|	-SUM(TotalInventoryBalanceAndTurnovers.BedsBlockedClosingBalance) AS TotalBedsBlocked,
	|	SUM(TotalInventoryBalanceAndTurnovers.ExpectedGuestsCheckedInTurnover) AS TotalGuestsReservedReceipt,
	|	SUM(TotalInventoryBalanceAndTurnovers.ExpectedGuestsCheckedOutTurnover) AS TotalGuestsReservedExpense,
	|	SUM(TotalInventoryBalanceAndTurnovers.InHouseGuestsReceipt) AS TotalInHouseGuestsReceipt,
	|	SUM(TotalInventoryBalanceAndTurnovers.InHouseGuestsExpense) AS TotalInHouseGuestsExpense
	|INTO HotelInventoryTotals
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qPeriodFrom, &qPeriodTo, Day, RegisterRecordsAndPeriodBoundaries, Hotel IN HIERARCHY (&qHotel)) AS TotalInventoryBalanceAndTurnovers
	|
	|GROUP BY
	|	TotalInventoryBalanceAndTurnovers.Hotel
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TotalInventoryBalanceAndTurnoversPerYear.Hotel AS Hotel,
	|	BEGINOFPERIOD(TotalInventoryBalanceAndTurnoversPerYear.Period, YEAR) AS Period,
	|	SUM(TotalInventoryBalanceAndTurnoversPerYear.CounterClosingBalance) AS CounterClosingBalance,
	|	SUM(TotalInventoryBalanceAndTurnoversPerYear.TotalRoomsClosingBalance) AS TotalRooms,
	|	SUM(TotalInventoryBalanceAndTurnoversPerYear.TotalBedsClosingBalance) AS TotalBeds,
	|	-SUM(TotalInventoryBalanceAndTurnoversPerYear.RoomsBlockedClosingBalance) AS TotalRoomsBlocked,
	|	-SUM(TotalInventoryBalanceAndTurnoversPerYear.BedsBlockedClosingBalance) AS TotalBedsBlocked,
	|	SUM(TotalInventoryBalanceAndTurnoversPerYear.ExpectedGuestsCheckedInTurnover) AS TotalGuestsReservedReceipt,
	|	SUM(TotalInventoryBalanceAndTurnoversPerYear.ExpectedGuestsCheckedOutTurnover) AS TotalGuestsReservedExpense,
	|	SUM(TotalInventoryBalanceAndTurnoversPerYear.InHouseGuestsReceipt) AS TotalInHouseGuestsReceipt,
	|	SUM(TotalInventoryBalanceAndTurnoversPerYear.InHouseGuestsExpense) AS TotalInHouseGuestsExpense
	|INTO HotelInventoryTotalsPerYear
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qPeriodFrom, &qPeriodTo, Day, RegisterRecordsAndPeriodBoundaries, Hotel IN HIERARCHY (&qHotel)) AS TotalInventoryBalanceAndTurnoversPerYear
	|
	|GROUP BY
	|	TotalInventoryBalanceAndTurnoversPerYear.Hotel,
	|	BEGINOFPERIOD(TotalInventoryBalanceAndTurnoversPerYear.Period, YEAR)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TotalInventoryBalanceAndTurnoversPerQuarter.Hotel AS Hotel,
	|	BEGINOFPERIOD(TotalInventoryBalanceAndTurnoversPerQuarter.Period, QUARTER) AS Period,
	|	SUM(TotalInventoryBalanceAndTurnoversPerQuarter.CounterClosingBalance) AS CounterClosingBalance,
	|	SUM(TotalInventoryBalanceAndTurnoversPerQuarter.TotalRoomsClosingBalance) AS TotalRooms,
	|	SUM(TotalInventoryBalanceAndTurnoversPerQuarter.TotalBedsClosingBalance) AS TotalBeds,
	|	-SUM(TotalInventoryBalanceAndTurnoversPerQuarter.RoomsBlockedClosingBalance) AS TotalRoomsBlocked,
	|	-SUM(TotalInventoryBalanceAndTurnoversPerQuarter.BedsBlockedClosingBalance) AS TotalBedsBlocked,
	|	SUM(TotalInventoryBalanceAndTurnoversPerQuarter.ExpectedGuestsCheckedInTurnover) AS TotalGuestsReservedReceipt,
	|	SUM(TotalInventoryBalanceAndTurnoversPerQuarter.ExpectedGuestsCheckedOutTurnover) AS TotalGuestsReservedExpense,
	|	SUM(TotalInventoryBalanceAndTurnoversPerQuarter.InHouseGuestsReceipt) AS TotalInHouseGuestsReceipt,
	|	SUM(TotalInventoryBalanceAndTurnoversPerQuarter.InHouseGuestsExpense) AS TotalInHouseGuestsExpense
	|INTO HotelInventoryTotalsPerQuarter
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qPeriodFrom, &qPeriodTo, Day, RegisterRecordsAndPeriodBoundaries, Hotel IN HIERARCHY (&qHotel)) AS TotalInventoryBalanceAndTurnoversPerQuarter
	|
	|GROUP BY
	|	TotalInventoryBalanceAndTurnoversPerQuarter.Hotel,
	|	BEGINOFPERIOD(TotalInventoryBalanceAndTurnoversPerQuarter.Period, QUARTER)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TotalInventoryBalanceAndTurnoversPerMonth.Hotel AS Hotel,
	|	BEGINOFPERIOD(TotalInventoryBalanceAndTurnoversPerMonth.Period, MONTH) AS Period,
	|	SUM(TotalInventoryBalanceAndTurnoversPerMonth.CounterClosingBalance) AS CounterClosingBalance,
	|	SUM(TotalInventoryBalanceAndTurnoversPerMonth.TotalRoomsClosingBalance) AS TotalRooms,
	|	SUM(TotalInventoryBalanceAndTurnoversPerMonth.TotalBedsClosingBalance) AS TotalBeds,
	|	-SUM(TotalInventoryBalanceAndTurnoversPerMonth.RoomsBlockedClosingBalance) AS TotalRoomsBlocked,
	|	-SUM(TotalInventoryBalanceAndTurnoversPerMonth.BedsBlockedClosingBalance) AS TotalBedsBlocked,
	|	SUM(TotalInventoryBalanceAndTurnoversPerMonth.ExpectedGuestsCheckedInTurnover) AS TotalGuestsReservedReceipt,
	|	SUM(TotalInventoryBalanceAndTurnoversPerMonth.ExpectedGuestsCheckedOutTurnover) AS TotalGuestsReservedExpense,
	|	SUM(TotalInventoryBalanceAndTurnoversPerMonth.InHouseGuestsReceipt) AS TotalInHouseGuestsReceipt,
	|	SUM(TotalInventoryBalanceAndTurnoversPerMonth.InHouseGuestsExpense) AS TotalInHouseGuestsExpense
	|INTO HotelInventoryTotalsPerMonth
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qPeriodFrom, &qPeriodTo, Day, RegisterRecordsAndPeriodBoundaries, Hotel IN HIERARCHY (&qHotel)) AS TotalInventoryBalanceAndTurnoversPerMonth
	|
	|GROUP BY
	|	TotalInventoryBalanceAndTurnoversPerMonth.Hotel,
	|	BEGINOFPERIOD(TotalInventoryBalanceAndTurnoversPerMonth.Period, MONTH)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TotalInventoryBalanceAndTurnoversPerWeek.Hotel AS Hotel,
	|	BEGINOFPERIOD(TotalInventoryBalanceAndTurnoversPerWeek.Period, WEEK) AS Period,
	|	SUM(TotalInventoryBalanceAndTurnoversPerWeek.CounterClosingBalance) AS CounterClosingBalance,
	|	SUM(TotalInventoryBalanceAndTurnoversPerWeek.TotalRoomsClosingBalance) AS TotalRooms,
	|	SUM(TotalInventoryBalanceAndTurnoversPerWeek.TotalBedsClosingBalance) AS TotalBeds,
	|	-SUM(TotalInventoryBalanceAndTurnoversPerWeek.RoomsBlockedClosingBalance) AS TotalRoomsBlocked,
	|	-SUM(TotalInventoryBalanceAndTurnoversPerWeek.BedsBlockedClosingBalance) AS TotalBedsBlocked,
	|	SUM(TotalInventoryBalanceAndTurnoversPerWeek.ExpectedGuestsCheckedInTurnover) AS TotalGuestsReservedReceipt,
	|	SUM(TotalInventoryBalanceAndTurnoversPerWeek.ExpectedGuestsCheckedOutTurnover) AS TotalGuestsReservedExpense,
	|	SUM(TotalInventoryBalanceAndTurnoversPerWeek.InHouseGuestsReceipt) AS TotalInHouseGuestsReceipt,
	|	SUM(TotalInventoryBalanceAndTurnoversPerWeek.InHouseGuestsExpense) AS TotalInHouseGuestsExpense
	|INTO HotelInventoryTotalsPerWeek
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qPeriodFrom, &qPeriodTo, Day, RegisterRecordsAndPeriodBoundaries, Hotel IN HIERARCHY (&qHotel)) AS TotalInventoryBalanceAndTurnoversPerWeek
	|
	|GROUP BY
	|	TotalInventoryBalanceAndTurnoversPerWeek.Hotel,
	|	BEGINOFPERIOD(TotalInventoryBalanceAndTurnoversPerWeek.Period, WEEK)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TotalInventoryBalanceAndTurnoversPerDay.Hotel AS Hotel,
	|	BEGINOFPERIOD(TotalInventoryBalanceAndTurnoversPerDay.Period, DAY) AS Period,
	|	SUM(TotalInventoryBalanceAndTurnoversPerDay.CounterClosingBalance) AS CounterClosingBalance,
	|	SUM(TotalInventoryBalanceAndTurnoversPerDay.TotalRoomsClosingBalance) AS TotalRooms,
	|	SUM(TotalInventoryBalanceAndTurnoversPerDay.TotalBedsClosingBalance) AS TotalBeds,
	|	-SUM(TotalInventoryBalanceAndTurnoversPerDay.RoomsBlockedClosingBalance) AS TotalRoomsBlocked,
	|	-SUM(TotalInventoryBalanceAndTurnoversPerDay.BedsBlockedClosingBalance) AS TotalBedsBlocked,
	|	SUM(TotalInventoryBalanceAndTurnoversPerDay.ExpectedGuestsCheckedInTurnover) AS TotalGuestsReservedReceipt,
	|	SUM(TotalInventoryBalanceAndTurnoversPerDay.ExpectedGuestsCheckedOutTurnover) AS TotalGuestsReservedExpense,
	|	SUM(TotalInventoryBalanceAndTurnoversPerDay.InHouseGuestsReceipt) AS TotalInHouseGuestsReceipt,
	|	SUM(TotalInventoryBalanceAndTurnoversPerDay.InHouseGuestsExpense) AS TotalInHouseGuestsExpense
	|INTO HotelInventoryTotalsPerDay
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qPeriodFrom, &qPeriodTo, Day, RegisterRecordsAndPeriodBoundaries, Hotel IN HIERARCHY (&qHotel)) AS TotalInventoryBalanceAndTurnoversPerDay
	|
	|GROUP BY
	|	TotalInventoryBalanceAndTurnoversPerDay.Hotel,
	|	BEGINOFPERIOD(TotalInventoryBalanceAndTurnoversPerDay.Period, DAY)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GeoSalesTotalTurnovers.Hotel AS Hotel,
	|	BEGINOFPERIOD(GeoSalesTotalTurnovers.Period, DAY) AS Period,
	|	SUM(GeoSalesTotalTurnovers.TotalSalesAmount) AS TotalSalesAmount,
	|	SUM(GeoSalesTotalTurnovers.TotalGuestsCheckedIn) AS TotalGuestsCheckedIn,
	|	SUM(GeoSalesTotalTurnovers.TotalGuestDays) AS TotalGuestDays
	|INTO GeoSalesTotalDailyTurnovers
	|FROM
	|	(SELECT
	|		SalesTotalTurnovers.Hotel AS Hotel,
	|		SalesTotalTurnovers.Period AS Period,
	|		ISNULL(SalesTotalTurnovers.SalesTurnover, 0) AS TotalSalesAmount,
	|		ISNULL(SalesTotalTurnovers.GuestsCheckedInTurnover, 0) AS TotalGuestsCheckedIn,
	|		ISNULL(SalesTotalTurnovers.GuestDaysTurnover, 0) AS TotalGuestDays
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				DAY,
	|				NOT IsCorrection
	|					AND Hotel IN HIERARCHY (&qHotel)
	|					AND (Client.Citizenship IN HIERARCHY (&qClientCitizenship)
	|						OR &qIsEmptyClientCitizenship)
	|					AND (TripPurpose IN HIERARCHY (&qTripPurpose)
	|						OR &qIsEmptyTripPurpose)
	|					AND (SourceOfBusiness IN HIERARCHY (&qSourceOfBusiness)
	|						OR &qIsEmptySourceOfBusiness)
	|					AND (Service IN (&qServicesList)
	|						OR NOT &qUseServicesList)) AS SalesTotalTurnovers
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		SalesForecastTotalTurnovers.Hotel,
	|		SalesForecastTotalTurnovers.Period,
	|		ISNULL(SalesForecastTotalTurnovers.SalesTurnover, 0),
	|		ISNULL(SalesForecastTotalTurnovers.GuestsCheckedInTurnover, 0),
	|		ISNULL(SalesForecastTotalTurnovers.GuestDaysTurnover, 0)
	|	FROM
	|		AccumulationRegister.SalesForecast.Turnovers(
	|				&qForecastPeriodFrom,
	|				&qForecastPeriodTo,
	|				DAY,
	|				&qUseForecast
	|					AND Hotel IN HIERARCHY (&qHotel)
	|					AND (Client.Citizenship IN HIERARCHY (&qClientCitizenship)
	|						OR &qIsEmptyClientCitizenship)
	|					AND (TripPurpose IN HIERARCHY (&qTripPurpose)
	|						OR &qIsEmptyTripPurpose)
	|					AND (SourceOfBusiness IN HIERARCHY (&qSourceOfBusiness)
	|						OR &qIsEmptySourceOfBusiness)
	|					AND (Service IN (&qServicesList)
	|						OR NOT &qUseServicesList)) AS SalesForecastTotalTurnovers) AS GeoSalesTotalTurnovers
	|
	|GROUP BY
	|	GeoSalesTotalTurnovers.Hotel,
	|	BEGINOFPERIOD(GeoSalesTotalTurnovers.Period, DAY)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GeoSalesTotalTurnovers.Hotel AS Hotel,
	|	SUM(GeoSalesTotalTurnovers.TotalSalesAmount) AS TotalSalesAmount,
	|	SUM(GeoSalesTotalTurnovers.TotalGuestsCheckedIn) AS TotalGuestsCheckedIn,
	|	SUM(GeoSalesTotalTurnovers.TotalGuestDays) AS TotalGuestDays
	|INTO GeoSalesTotalTurnovers
	|FROM
	|	GeoSalesTotalDailyTurnovers AS GeoSalesTotalTurnovers
	|
	|GROUP BY
	|	GeoSalesTotalTurnovers.Hotel
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GeoSalesTotalTurnovers.Hotel AS Hotel,
	|	BEGINOFPERIOD(GeoSalesTotalTurnovers.Period, YEAR) AS Period,
	|	SUM(GeoSalesTotalTurnovers.TotalSalesAmount) AS TotalSalesAmount,
	|	SUM(GeoSalesTotalTurnovers.TotalGuestsCheckedIn) AS TotalGuestsCheckedIn,
	|	SUM(GeoSalesTotalTurnovers.TotalGuestDays) AS TotalGuestDays
	|INTO GeoSalesTotalYearlyTurnovers
	|FROM
	|	GeoSalesTotalDailyTurnovers AS GeoSalesTotalTurnovers
	|
	|GROUP BY
	|	GeoSalesTotalTurnovers.Hotel,
	|	BEGINOFPERIOD(GeoSalesTotalTurnovers.Period, YEAR)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GeoSalesTotalTurnovers.Hotel AS Hotel,
	|	BEGINOFPERIOD(GeoSalesTotalTurnovers.Period, QUARTER) AS Period,
	|	SUM(GeoSalesTotalTurnovers.TotalSalesAmount) AS TotalSalesAmount,
	|	SUM(GeoSalesTotalTurnovers.TotalGuestsCheckedIn) AS TotalGuestsCheckedIn,
	|	SUM(GeoSalesTotalTurnovers.TotalGuestDays) AS TotalGuestDays
	|INTO GeoSalesTotalQuarterlyTurnovers
	|FROM
	|	GeoSalesTotalDailyTurnovers AS GeoSalesTotalTurnovers
	|
	|GROUP BY
	|	GeoSalesTotalTurnovers.Hotel,
	|	BEGINOFPERIOD(GeoSalesTotalTurnovers.Period, QUARTER)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GeoSalesTotalTurnovers.Hotel AS Hotel,
	|	BEGINOFPERIOD(GeoSalesTotalTurnovers.Period, MONTH) AS Period,
	|	SUM(GeoSalesTotalTurnovers.TotalSalesAmount) AS TotalSalesAmount,
	|	SUM(GeoSalesTotalTurnovers.TotalGuestsCheckedIn) AS TotalGuestsCheckedIn,
	|	SUM(GeoSalesTotalTurnovers.TotalGuestDays) AS TotalGuestDays
	|INTO GeoSalesTotalMonthlyTurnovers
	|FROM
	|	GeoSalesTotalDailyTurnovers AS GeoSalesTotalTurnovers
	|
	|GROUP BY
	|	GeoSalesTotalTurnovers.Hotel,
	|	BEGINOFPERIOD(GeoSalesTotalTurnovers.Period, MONTH)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GeoSalesTotalTurnovers.Hotel AS Hotel,
	|	BEGINOFPERIOD(GeoSalesTotalTurnovers.Period, WEEK) AS Period,
	|	SUM(GeoSalesTotalTurnovers.TotalSalesAmount) AS TotalSalesAmount,
	|	SUM(GeoSalesTotalTurnovers.TotalGuestsCheckedIn) AS TotalGuestsCheckedIn,
	|	SUM(GeoSalesTotalTurnovers.TotalGuestDays) AS TotalGuestDays
	|INTO GeoSalesTotalWeeklyTurnovers
	|FROM
	|	GeoSalesTotalDailyTurnovers AS GeoSalesTotalTurnovers
	|
	|GROUP BY
	|	GeoSalesTotalTurnovers.Hotel,
	|	BEGINOFPERIOD(GeoSalesTotalTurnovers.Period, WEEK)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GeoSalesTurnovers.ReportingCurrency AS ReportingCurrency,
	|	GeoSalesTurnovers.Hotel AS Hotel,
	|	GeoSalesTurnovers.Client.DateOfBirth AS ClientDateOfBirth,
	|	CASE
	|		WHEN GeoSalesTurnovers.Client.Citizenship.Code IS NULL
	|			THEN CASE
	|					WHEN NOT GeoSalesTurnovers.ParentDoc.Number IS NULL
	|							AND NOT GeoSalesTurnovers.ParentDoc.GuestGroup.Client.Citizenship.Code IS NULL
	|						THEN GeoSalesTurnovers.ParentDoc.GuestGroup.Client.Citizenship
	|					ELSE GeoSalesTurnovers.ParentDoc.GuestGroup.Citizenship
	|				END
	|		ELSE GeoSalesTurnovers.Client.Citizenship
	|	END AS ClientCitizenship,
	|	GeoSalesTurnovers.Client.Region AS ClientRegion,
	|	GeoSalesTurnovers.Client.City AS ClientCity,
	|	GeoSalesTurnovers.Client.Age AS ClientAge,
	|	GeoSalesTurnovers.MarketingCode AS MarketingCode,
	|	GeoSalesTurnovers.SourceOfBusiness AS SourceOfBusiness,
	|	GeoSalesTurnovers.TripPurpose AS TripPurpose,
	|	GeoSalesTurnovers.Company AS Company,
	|	GeoSalesTurnovers.AccountingDate AS AccountingDate,
	|	GeoSalesTurnovers.GuestGroup AS GuestGroup,
	|	GeoSalesTurnovers.ParentDoc AS ParentDoc,
	|	GeoSalesTurnovers.Service AS Service,
	|	GeoSalesTurnovers.SalesTurnover AS Sales,
	|	GeoSalesTurnovers.RoomRevenueTurnover AS RoomRevenue,
	|	GeoSalesTurnovers.ExtraBedRevenueTurnover AS ExtraBedRevenue,
	|	GeoSalesTurnovers.RoomRevenueTurnover - GeoSalesTurnovers.ExtraBedRevenueTurnover AS MainBedsRevenue,
	|	GeoSalesTurnovers.SalesWithoutVATTurnover AS SalesWithoutVAT,
	|	GeoSalesTurnovers.RoomRevenueWithoutVATTurnover AS RoomRevenueWithoutVAT,
	|	GeoSalesTurnovers.ExtraBedRevenueWithoutVATTurnover AS ExtraBedRevenueWithoutVAT,
	|	GeoSalesTurnovers.RoomRevenueWithoutVATTurnover - GeoSalesTurnovers.ExtraBedRevenueWithoutVATTurnover AS MainBedsRevenueWithoutVAT,
	|	GeoSalesTurnovers.CommissionSumTurnover AS CommissionSum,
	|	GeoSalesTurnovers.CommissionSumWithoutVATTurnover AS CommissionSumWithoutVAT,
	|	GeoSalesTurnovers.DiscountSumTurnover AS DiscountSum,
	|	GeoSalesTurnovers.DiscountSumWithoutVATTurnover AS DiscountSumWithoutVAT,
	|	GeoSalesTurnovers.RoomsRentedTurnover AS RoomsRented,
	|	GeoSalesTurnovers.BedsRentedTurnover AS BedsRented,
	|	GeoSalesTurnovers.AdditionalBedsRentedTurnover AS AdditionalBedsRented,
	|	GeoSalesTurnovers.GuestDaysTurnover AS GuestDays,
	|	GeoSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedIn,
	|	GeoSalesTurnovers.RoomsCheckedInTurnover AS RoomsCheckedIn,
	|	GeoSalesTurnovers.BedsCheckedInTurnover AS BedsCheckedIn,
	|	GeoSalesTurnovers.AdditionalBedsCheckedInTurnover AS AdditionalBedsCheckedIn,
	|	GeoSalesTurnovers.BookingWindowTurnover AS BookingWindow,
	|	GeoSalesTurnovers.QuantityTurnover AS Quantity
	|INTO GeoSalesTurnovers
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			NOT IsCorrection
	|				AND Hotel IN HIERARCHY (&qHotel)
	|				AND (Client.Citizenship IN HIERARCHY (&qClientCitizenship)
	|					OR &qIsEmptyClientCitizenship)
	|				AND (TripPurpose IN HIERARCHY (&qTripPurpose)
	|					OR &qIsEmptyTripPurpose)
	|				AND (SourceOfBusiness IN HIERARCHY (&qSourceOfBusiness)
	|					OR &qIsEmptySourceOfBusiness)
	|				AND (Service IN (&qServicesList)
	|					OR NOT &qUseServicesList)) AS GeoSalesTurnovers
	|
	|UNION ALL
	|
	|SELECT
	|	GeoSalesForecastTurnovers.ReportingCurrency,
	|	GeoSalesForecastTurnovers.Hotel,
	|	GeoSalesForecastTurnovers.Client.DateOfBirth,
	|	CASE
	|		WHEN GeoSalesForecastTurnovers.Client.Citizenship.Code IS NULL
	|			THEN CASE
	|					WHEN NOT GeoSalesForecastTurnovers.ParentDoc.Number IS NULL
	|							AND NOT GeoSalesForecastTurnovers.ParentDoc.GuestGroup.Client.Citizenship.Code IS NULL
	|						THEN GeoSalesForecastTurnovers.ParentDoc.GuestGroup.Client.Citizenship
	|					ELSE GeoSalesForecastTurnovers.ParentDoc.GuestGroup.Citizenship
	|				END
	|		ELSE GeoSalesForecastTurnovers.Client.Citizenship
	|	END,
	|	GeoSalesForecastTurnovers.Client.Region,
	|	GeoSalesForecastTurnovers.Client.City,
	|	GeoSalesForecastTurnovers.Client.Age,
	|	GeoSalesForecastTurnovers.MarketingCode,
	|	GeoSalesForecastTurnovers.SourceOfBusiness,
	|	GeoSalesForecastTurnovers.TripPurpose,
	|	GeoSalesForecastTurnovers.Company,
	|	GeoSalesForecastTurnovers.AccountingDate,
	|	GeoSalesForecastTurnovers.GuestGroup,
	|	GeoSalesForecastTurnovers.ParentDoc,
	|	GeoSalesForecastTurnovers.Service,
	|	GeoSalesForecastTurnovers.SalesTurnover,
	|	GeoSalesForecastTurnovers.RoomRevenueTurnover,
	|	GeoSalesForecastTurnovers.ExtraBedRevenueTurnover,
	|	GeoSalesForecastTurnovers.RoomRevenueTurnover - GeoSalesForecastTurnovers.ExtraBedRevenueTurnover,
	|	GeoSalesForecastTurnovers.SalesWithoutVATTurnover,
	|	GeoSalesForecastTurnovers.RoomRevenueWithoutVATTurnover,
	|	GeoSalesForecastTurnovers.ExtraBedRevenueWithoutVATTurnover,
	|	GeoSalesForecastTurnovers.RoomRevenueWithoutVATTurnover - GeoSalesForecastTurnovers.ExtraBedRevenueWithoutVATTurnover,
	|	GeoSalesForecastTurnovers.CommissionSumTurnover,
	|	GeoSalesForecastTurnovers.CommissionSumWithoutVATTurnover,
	|	GeoSalesForecastTurnovers.DiscountSumTurnover,
	|	GeoSalesForecastTurnovers.DiscountSumWithoutVATTurnover,
	|	GeoSalesForecastTurnovers.RoomsRentedTurnover,
	|	GeoSalesForecastTurnovers.BedsRentedTurnover,
	|	GeoSalesForecastTurnovers.AdditionalBedsRentedTurnover,
	|	GeoSalesForecastTurnovers.GuestDaysTurnover,
	|	GeoSalesForecastTurnovers.GuestsCheckedInTurnover,
	|	GeoSalesForecastTurnovers.RoomsCheckedInTurnover,
	|	GeoSalesForecastTurnovers.BedsCheckedInTurnover,
	|	GeoSalesForecastTurnovers.AdditionalBedsCheckedInTurnover,
	|	GeoSalesForecastTurnovers.BookingWindowTurnover,
	|	GeoSalesForecastTurnovers.QuantityTurnover
	|FROM
	|	AccumulationRegister.SalesForecast.Turnovers(
	|			&qForecastPeriodFrom,
	|			&qForecastPeriodTo,
	|			Day,
	|			&qUseForecast
	|				AND Hotel IN HIERARCHY (&qHotel)
	|				AND (Client.Citizenship IN HIERARCHY (&qClientCitizenship)
	|					OR &qIsEmptyClientCitizenship)
	|				AND (TripPurpose IN HIERARCHY (&qTripPurpose)
	|					OR &qIsEmptyTripPurpose)
	|				AND (SourceOfBusiness IN HIERARCHY (&qSourceOfBusiness)
	|					OR &qIsEmptySourceOfBusiness)
	|				AND (Service IN (&qServicesList)
	|					OR NOT &qUseServicesList)) AS GeoSalesForecastTurnovers
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GeoSales.ReportingCurrency AS ReportingCurrency,
	|	GeoSales.Hotel AS Hotel,
	|	GeoSales.ClientCitizenship AS ClientCitizenship,
	|	GeoSales.ClientRegion AS ClientRegion,
	|	GeoSales.ClientCity AS ClientCity,
	|	GeoSales.ClientAge AS ClientAge,
	|	GeoSales.MarketingCode AS MarketingCode,
	|	GeoSales.SourceOfBusiness AS SourceOfBusiness,
	|	GeoSales.TripPurpose AS TripPurpose,
	|	GeoSales.Company AS Company,
	|	GeoSales.AccountingDate AS AccountingDate,
	|	BEGINOFPERIOD(GeoSales.AccountingDate, WEEK) AS AccountingWeek,
	|	BEGINOFPERIOD(GeoSales.AccountingDate, MONTH) AS AccountingMonth,
	|	BEGINOFPERIOD(GeoSales.AccountingDate, QUARTER) AS AccountingQuarter,
	|	YEAR(GeoSales.AccountingDate) AS AccountingYear,
	|	GeoSales.ParentDoc AS ParentDoc,
	|	GeoSales.Service AS Service,
	|	GeoSales.RoomsPerPeriod AS RoomsPerPeriod,
	|	GeoSales.BedsPerPeriod AS BedsPerPeriod,
	|	GeoSales.RoomsBlockedPerPeriod AS RoomsBlockedPerPeriod,
	|	GeoSales.BedsBlockedPerPeriod AS BedsBlockedPerPeriod,
	|	CASE
	|		WHEN GeoSales.RoomsRented = 0
	|			THEN 0
	|		ELSE GeoSales.RoomRevenue / GeoSales.RoomsRented
	|	END AS AverageRoomPrice,
	|	CASE
	|		WHEN GeoSales.BedsRented = 0
	|			THEN 0
	|		ELSE GeoSales.RoomRevenue / GeoSales.BedsRented
	|	END AS AverageBedPrice,
	|	CASE
	|		WHEN GeoSales.RoomsPerPeriod = 0
	|			THEN 0
	|		ELSE GeoSales.RoomRevenue / GeoSales.RoomsPerPeriod
	|	END AS RevPAR,
	|	CASE
	|		WHEN GeoSales.BedsPerPeriod = 0
	|			THEN 0
	|		ELSE GeoSales.RoomRevenue / GeoSales.BedsPerPeriod
	|	END AS RevPAB,
	|	CASE
	|		WHEN GeoSales.RoomsRented = 0
	|			THEN 0
	|		ELSE GeoSales.RoomRevenueWithoutVAT / GeoSales.RoomsRented
	|	END AS AverageRoomPriceWithoutVAT,
	|	CASE
	|		WHEN GeoSales.BedsRented = 0
	|			THEN 0
	|		ELSE GeoSales.RoomRevenueWithoutVAT / GeoSales.BedsRented
	|	END AS AverageBedPriceWithoutVAT,
	|	CASE
	|		WHEN GeoSales.RoomsPerPeriod = 0
	|			THEN 0
	|		ELSE GeoSales.RoomRevenueWithoutVAT / GeoSales.RoomsPerPeriod
	|	END AS RevPARWithoutVAT,
	|	CASE
	|		WHEN GeoSales.BedsPerPeriod = 0
	|			THEN 0
	|		ELSE GeoSales.RoomRevenueWithoutVAT / GeoSales.BedsPerPeriod
	|	END AS RevPABWithoutVAT,
	|	CASE
	|		WHEN GeoSales.RoomsPerPeriod = 0
	|			THEN 0
	|		ELSE GeoSales.RoomsRented * 100 / GeoSales.RoomsPerPeriod
	|	END AS RoomsRentedPercent,
	|	CASE
	|		WHEN GeoSales.BedsPerPeriod = 0
	|			THEN 0
	|		ELSE GeoSales.BedsRented * 100 / GeoSales.BedsPerPeriod
	|	END AS BedsRentedPercent,
	|	CASE
	|		WHEN GeoSales.RoomsPerPeriod - GeoSales.RoomsBlockedPerPeriod = 0
	|			THEN 0
	|		ELSE GeoSales.RoomsRented * 100 / (GeoSales.RoomsPerPeriod - GeoSales.RoomsBlockedPerPeriod)
	|	END AS RoomsRentedPercentWithRoomBlocks,
	|	CASE
	|		WHEN GeoSales.BedsPerPeriod - GeoSales.BedsBlockedPerPeriod = 0
	|			THEN 0
	|		ELSE GeoSales.BedsRented * 100 / (GeoSales.BedsPerPeriod - GeoSales.BedsBlockedPerPeriod)
	|	END AS BedsRentedPercentWithRoomBlocks,
	|	GeoSales.Sales AS Sales,
	|	GeoSales.RoomRevenue AS RoomRevenue,
	|	GeoSales.ExtraBedRevenue AS ExtraBedRevenue,
	|	GeoSales.MainBedsRevenue AS MainBedsRevenue,
	|	GeoSales.SalesWithoutVAT AS SalesWithoutVAT,
	|	GeoSales.RoomRevenueWithoutVAT AS RoomRevenueWithoutVAT,
	|	GeoSales.ExtraBedRevenueWithoutVAT AS ExtraBedRevenueWithoutVAT,
	|	GeoSales.MainBedsRevenueWithoutVAT AS MainBedsRevenueWithoutVAT,
	|	GeoSales.CommissionSum AS CommissionSum,
	|	GeoSales.CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|	GeoSales.DiscountSum AS DiscountSum,
	|	GeoSales.DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|	GeoSales.RoomsRented AS RoomsRented,
	|	GeoSales.BedsRented AS BedsRented,
	|	GeoSales.AdditionalBedsRented AS AdditionalBedsRented,
	|	GeoSales.GuestDays AS GuestDays,
	|	GeoSales.GuestsCheckedIn AS GuestsCheckedIn,
	|	GeoSales.RoomsCheckedIn AS RoomsCheckedIn,
	|	GeoSales.BedsCheckedIn AS BedsCheckedIn,
	|	GeoSales.AdditionalBedsCheckedIn AS AdditionalBedsCheckedIn,
	|	CASE
	|		WHEN GeoSales.GuestsCheckedIn > 0
	|			THEN CAST(GeoSales.BookingWindow / GeoSales.GuestsCheckedIn AS NUMBER(10, 0))
	|		ELSE 0
	|	END AS BookingWindow,
	|	GeoSales.Quantity AS Quantity,
	|	GeoSales.TotalSalesAmount AS TotalSalesAmount,
	|	0 AS TotalSalesPercent,
	|	GeoSales.TotalGuestsCheckedIn AS TotalGuestsCheckedIn,
	|	0 AS TotalGuestsCheckedInPercent,
	|	GeoSales.TotalGuestDays AS TotalGuestDays,
	|	0 AS TotalGuestDaysPercent,
	|	GeoSales.TotalSalesAmountPerYear AS TotalSalesAmountPerYear,
	|	0 AS TotalSalesPercentPerYear,
	|	GeoSales.TotalGuestsCheckedInPerYear AS TotalGuestsCheckedInPerYear,
	|	0 AS TotalGuestsCheckedInPercentPerYear,
	|	GeoSales.TotalGuestDaysPerYear AS TotalGuestDaysPerYear,
	|	0 AS TotalGuestDaysPercentPerYear,
	|	GeoSales.TotalSalesAmountPerQuarter AS TotalSalesAmountPerQuarter,
	|	0 AS TotalSalesPercentPerQuarter,
	|	GeoSales.TotalGuestsCheckedInPerQuarter AS TotalGuestsCheckedInPerQuarter,
	|	0 AS TotalGuestsCheckedInPercentPerQuarter,
	|	GeoSales.TotalGuestDaysPerQuarter AS TotalGuestDaysPerQuarter,
	|	0 AS TotalGuestDaysPercentPerQuarter,
	|	GeoSales.TotalSalesAmountPerMonth AS TotalSalesAmountPerMonth,
	|	0 AS TotalSalesPercentPerMonth,
	|	GeoSales.TotalGuestsCheckedInPerMonth AS TotalGuestsCheckedInPerMonth,
	|	0 AS TotalGuestsCheckedInPercentPerMonth,
	|	GeoSales.TotalGuestDaysPerMonth AS TotalGuestDaysPerMonth,
	|	0 AS TotalGuestDaysPercentPerMonth,
	|	GeoSales.TotalSalesAmountPerWeek AS TotalSalesAmountPerWeek,
	|	0 AS TotalSalesPercentPerWeek,
	|	GeoSales.TotalGuestsCheckedInPerWeek AS TotalGuestsCheckedInPerWeek,
	|	0 AS TotalGuestsCheckedInPercentPerWeek,
	|	GeoSales.TotalGuestDaysPerWeek AS TotalGuestDaysPerWeek,
	|	0 AS TotalGuestDaysPercentPerWeek,
	|	GeoSales.TotalSalesAmountPerDay AS TotalSalesAmountPerDay,
	|	0 AS TotalSalesPercentPerDay,
	|	GeoSales.TotalGuestsCheckedInPerDay AS TotalGuestsCheckedInPerDay,
	|	0 AS TotalGuestsCheckedInPercentPerDay,
	|	GeoSales.TotalGuestDaysPerDay AS TotalGuestDaysPerDay,
	|	0 AS TotalGuestDaysPercentPerDay,
	|	0 AS PerYearOccupancyPercent,
	|	0 AS PerYearRoomsRentedPercent,
	|	0 AS PerQuarterOccupancyPercent,
	|	0 AS PerQuarterRoomsRentedPercent,
	|	0 AS PerMonthOccupancyPercent,
	|	0 AS PerMonthRoomsRentedPercent,
	|	0 AS PerWeekOccupancyPercent,
	|	0 AS PerWeekRoomsRentedPercent,
	|	0 AS PerDayOccupancyPercent,
	|	0 AS PerDayRoomsRentedPercent,
	|	GeoSales.TotalRoomsPerYear AS TotalRoomsPerYear,
	|	GeoSales.TotalRoomsBlockedPerYear AS TotalRoomsBlockedPerYear,
	|	GeoSales.TotalRoomsPerQuarter AS TotalRoomsPerQuarter,
	|	GeoSales.TotalRoomsBlockedPerQuarter AS TotalRoomsBlockedPerQuarter,
	|	GeoSales.TotalRoomsPerMonth AS TotalRoomsPerMonth,
	|	GeoSales.TotalRoomsBlockedPerMonth AS TotalRoomsBlockedPerMonth,
	|	GeoSales.TotalRoomsPerWeek AS TotalRoomsPerWeek,
	|	GeoSales.TotalRoomsBlockedPerWeek AS TotalRoomsBlockedPerWeek,
	|	GeoSales.TotalRoomsPerDay AS TotalRoomsPerDay,
	|	GeoSales.TotalRoomsBlockedPerDay AS TotalRoomsBlockedPerDay
	|{SELECT
	|	ReportingCurrency.*,
	|	Hotel.*,
	|	ClientCitizenship.*,
	|	ClientRegion,
	|	ClientCity,
	|	ClientAge,
	|	MarketingCode.*,
	|	SourceOfBusiness.*,
	|	TripPurpose.*,
	|	Service.*,
	|	Company.*,
	|	ParentDoc.*,
	|	ReservationCustomAttributeValues1.CharacteristicValue.* AS CustomAttribute1,
	|	ReservationCustomAttributeValues2.CharacteristicValue.* AS CustomAttribute2,
	|	ReservationCustomAttributeValues3.CharacteristicValue.* AS CustomAttribute3,
	|	TotalSalesAmount,
	|	TotalSalesPercent,
	|	TotalGuestsCheckedIn,
	|	TotalGuestsCheckedInPercent,
	|	TotalGuestDays,
	|	TotalGuestDaysPercent,
	|	TotalSalesAmountPerYear,
	|	TotalSalesPercentPerYear,
	|	TotalGuestsCheckedInPerYear,
	|	TotalGuestsCheckedInPercentPerYear,
	|	TotalGuestDaysPerYear,
	|	TotalGuestDaysPercentPerYear,
	|	TotalSalesAmountPerQuarter,
	|	TotalSalesPercentPerQuarter,
	|	TotalGuestsCheckedInPerQuarter,
	|	TotalGuestsCheckedInPercentPerQuarter,
	|	TotalGuestDaysPerQuarter,
	|	TotalGuestDaysPercentPerQuarter,
	|	TotalSalesAmountPerMonth,
	|	TotalSalesPercentPerMonth,
	|	TotalGuestsCheckedInPerMonth,
	|	TotalGuestsCheckedInPercentPerMonth,
	|	TotalGuestDaysPerMonth,
	|	TotalGuestDaysPercentPerMonth,
	|	TotalSalesAmountPerWeek,
	|	TotalSalesPercentPerWeek,
	|	TotalGuestsCheckedInPerWeek,
	|	TotalGuestsCheckedInPercentPerWeek,
	|	TotalGuestDaysPerWeek,
	|	TotalGuestDaysPercentPerWeek,
	|	TotalSalesAmountPerDay,
	|	TotalSalesPercentPerDay,
	|	TotalGuestsCheckedInPerDay,
	|	TotalGuestsCheckedInPercentPerDay,
	|	TotalGuestDaysPerDay,
	|	TotalGuestDaysPercentPerDay,
	|	Sales,
	|	RoomRevenue,
	|	ExtraBedRevenue,
	|	MainBedsRevenue,
	|	SalesWithoutVAT,
	|	RoomRevenueWithoutVAT,
	|	ExtraBedRevenueWithoutVAT,
	|	MainBedsRevenueWithoutVAT,
	|	CommissionSum,
	|	CommissionSumWithoutVAT,
	|	DiscountSum,
	|	DiscountSumWithoutVAT,
	|	RoomsRented,
	|	BedsRented,
	|	AdditionalBedsRented,
	|	GuestDays,
	|	GuestsCheckedIn,
	|	RoomsCheckedIn,
	|	BedsCheckedIn,
	|	AdditionalBedsCheckedIn,
	|	BookingWindow,
	|	Quantity,
	|	RoomsPerPeriod,
	|	BedsPerPeriod,
	|	RoomsBlockedPerPeriod,
	|	BedsBlockedPerPeriod,
	|	AverageRoomPrice,
	|	AverageBedPrice,
	|	RevPAR,
	|	RevPAB,
	|	AverageRoomPriceWithoutVAT,
	|	AverageBedPriceWithoutVAT,
	|	RevPARWithoutVAT,
	|	RevPABWithoutVAT,
	|	RoomsRentedPercent,
	|	BedsRentedPercent,
	|	RoomsRentedPercentWithRoomBlocks,
	|	BedsRentedPercentWithRoomBlocks,
	|	(CASE
	|			WHEN GeoSales.ClientAge IS NULL
	|				THEN &qUndefinedAge
	|			WHEN ISNULL(GeoSales.ClientDateOfBirth, &qEmptyDate) = &qEmptyDate
	|				THEN &qUndefinedAge
	|			WHEN GeoSales.ClientAge < 15
	|				THEN &qChild
	|			WHEN GeoSales.ClientAge < 22
	|				THEN &qTeenager
	|			WHEN GeoSales.ClientAge < 30
	|				THEN &q2229
	|			WHEN GeoSales.ClientAge < 40
	|				THEN &q3039
	|			WHEN GeoSales.ClientAge < 50
	|				THEN &q4049
	|			WHEN GeoSales.ClientAge < 60
	|				THEN &q5059
	|			ELSE &qGreater60
	|		END) AS AgeRange,
	|	AccountingDate,
	|	AccountingWeek,
	|	AccountingMonth,
	|	AccountingQuarter,
	|	AccountingYear,
	|	GeoSales.GuestGroup.* AS GuestGroup,
	|	(CASE
	|			WHEN NOT GeoSales.GuestGroup.GroupType.Code IS NULL
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS IsGroupReservation,
	|	PerYearOccupancyPercent AS PerYearOccupancyPercent,
	|	PerYearRoomsRentedPercent AS PerYearRoomsRentedPercent,
	|	PerQuarterOccupancyPercent AS PerQuarterOccupancyPercent,
	|	PerQuarterRoomsRentedPercent AS PerQuarterRoomsRentedPercent,
	|	PerMonthOccupancyPercent AS PerMonthOccupancyPercent,
	|	PerMonthRoomsRentedPercent AS PerMonthRoomsRentedPercent,
	|	PerWeekOccupancyPercent AS PerWeekOccupancyPercent,
	|	PerWeekRoomsRentedPercent AS PerWeekRoomsRentedPercent,
	|	PerDayOccupancyPercent AS PerDayOccupancyPercent,
	|	PerDayRoomsRentedPercent AS PerDayRoomsRentedPercent,
	|	TotalRoomsPerYear AS TotalRoomsPerYear,
	|	TotalRoomsBlockedPerYear AS TotalRoomsBlockedPerYear,
	|	TotalRoomsPerQuarter AS TotalRoomsPerQuarter,
	|	TotalRoomsBlockedPerQuarter AS TotalRoomsBlockedPerQuarter,
	|	TotalRoomsPerMonth AS TotalRoomsPerMonth,
	|	TotalRoomsBlockedPerMonth AS TotalRoomsBlockedPerMonth,
	|	TotalRoomsPerWeek AS TotalRoomsPerWeek,
	|	TotalRoomsBlockedPerWeek AS TotalRoomsBlockedPerWeek,
	|	TotalRoomsPerDay AS TotalRoomsPerDay,
	|	TotalRoomsBlockedPerDay AS TotalRoomsBlockedPerDay}
	|FROM
	|	(SELECT
	|		GeoSalesTurnovers.ReportingCurrency AS ReportingCurrency,
	|		GeoSalesTurnovers.Hotel AS Hotel,
	|		GeoSalesTurnovers.ClientDateOfBirth AS ClientDateOfBirth,
	|		GeoSalesTurnovers.ClientCitizenship AS ClientCitizenship,
	|		GeoSalesTurnovers.ClientRegion AS ClientRegion,
	|		GeoSalesTurnovers.ClientCity AS ClientCity,
	|		GeoSalesTurnovers.ClientAge AS ClientAge,
	|		GeoSalesTurnovers.MarketingCode AS MarketingCode,
	|		GeoSalesTurnovers.SourceOfBusiness AS SourceOfBusiness,
	|		GeoSalesTurnovers.TripPurpose AS TripPurpose,
	|		GeoSalesTurnovers.Company AS Company,
	|		GeoSalesTurnovers.AccountingDate AS AccountingDate,
	|		GeoSalesTurnovers.ParentDoc AS ParentDoc,
	|		GeoSalesTurnovers.GuestGroup AS GuestGroup,
	|		GeoSalesTurnovers.Service AS Service,
	|		GeoSalesTurnovers.Sales AS Sales,
	|		GeoSalesTurnovers.RoomRevenue AS RoomRevenue,
	|		GeoSalesTurnovers.ExtraBedRevenue AS ExtraBedRevenue,
	|		GeoSalesTurnovers.MainBedsRevenue AS MainBedsRevenue,
	|		GeoSalesTurnovers.SalesWithoutVAT AS SalesWithoutVAT,
	|		GeoSalesTurnovers.RoomRevenueWithoutVAT AS RoomRevenueWithoutVAT,
	|		GeoSalesTurnovers.ExtraBedRevenueWithoutVAT AS ExtraBedRevenueWithoutVAT,
	|		GeoSalesTurnovers.MainBedsRevenueWithoutVAT AS MainBedsRevenueWithoutVAT,
	|		GeoSalesTurnovers.CommissionSum AS CommissionSum,
	|		GeoSalesTurnovers.CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|		GeoSalesTurnovers.DiscountSum AS DiscountSum,
	|		GeoSalesTurnovers.DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|		GeoSalesTurnovers.RoomsRented AS RoomsRented,
	|		GeoSalesTurnovers.BedsRented AS BedsRented,
	|		GeoSalesTurnovers.AdditionalBedsRented AS AdditionalBedsRented,
	|		GeoSalesTurnovers.GuestDays AS GuestDays,
	|		GeoSalesTurnovers.GuestsCheckedIn AS GuestsCheckedIn,
	|		GeoSalesTurnovers.RoomsCheckedIn AS RoomsCheckedIn,
	|		GeoSalesTurnovers.BedsCheckedIn AS BedsCheckedIn,
	|		GeoSalesTurnovers.AdditionalBedsCheckedIn AS AdditionalBedsCheckedIn,
	|		GeoSalesTurnovers.BookingWindow AS BookingWindow,
	|		GeoSalesTurnovers.Quantity AS Quantity,
	|		ISNULL(InventoryTotals.TotalRooms, 0) AS RoomsPerPeriod,
	|		ISNULL(InventoryTotals.TotalBeds, 0) AS BedsPerPeriod,
	|		ISNULL(InventoryTotals.TotalRoomsBlocked, 0) AS RoomsBlockedPerPeriod,
	|		ISNULL(InventoryTotals.TotalBedsBlocked, 0) AS BedsBlockedPerPeriod,
	|		ISNULL(GeoSalesTotals.TotalSalesAmount, 0) AS TotalSalesAmount,
	|		ISNULL(GeoSalesTotals.TotalGuestsCheckedIn, 0) AS TotalGuestsCheckedIn,
	|		ISNULL(GeoSalesTotals.TotalGuestDays, 0) AS TotalGuestDays,
	|		ISNULL(GeoSalesYearlyTotals.TotalSalesAmount, 0) AS TotalSalesAmountPerYear,
	|		ISNULL(GeoSalesYearlyTotals.TotalGuestsCheckedIn, 0) AS TotalGuestsCheckedInPerYear,
	|		ISNULL(GeoSalesYearlyTotals.TotalGuestDays, 0) AS TotalGuestDaysPerYear,
	|		ISNULL(GeoSalesQuarterlyTotals.TotalSalesAmount, 0) AS TotalSalesAmountPerQuarter,
	|		ISNULL(GeoSalesQuarterlyTotals.TotalGuestsCheckedIn, 0) AS TotalGuestsCheckedInPerQuarter,
	|		ISNULL(GeoSalesQuarterlyTotals.TotalGuestDays, 0) AS TotalGuestDaysPerQuarter,
	|		ISNULL(GeoSalesMonthlyTotals.TotalSalesAmount, 0) AS TotalSalesAmountPerMonth,
	|		ISNULL(GeoSalesMonthlyTotals.TotalGuestsCheckedIn, 0) AS TotalGuestsCheckedInPerMonth,
	|		ISNULL(GeoSalesMonthlyTotals.TotalGuestDays, 0) AS TotalGuestDaysPerMonth,
	|		ISNULL(GeoSalesWeeklyTotals.TotalSalesAmount, 0) AS TotalSalesAmountPerWeek,
	|		ISNULL(GeoSalesWeeklyTotals.TotalGuestsCheckedIn, 0) AS TotalGuestsCheckedInPerWeek,
	|		ISNULL(GeoSalesWeeklyTotals.TotalGuestDays, 0) AS TotalGuestDaysPerWeek,
	|		ISNULL(GeoSalesDailyTotals.TotalSalesAmount, 0) AS TotalSalesAmountPerDay,
	|		ISNULL(GeoSalesDailyTotals.TotalGuestsCheckedIn, 0) AS TotalGuestsCheckedInPerDay,
	|		ISNULL(GeoSalesDailyTotals.TotalGuestDays, 0) AS TotalGuestDaysPerDay,
	|		ISNULL(InventoryTotalsPerYear.TotalRooms, 0) AS TotalRoomsPerYear,
	|		ISNULL(InventoryTotalsPerYear.TotalRoomsBlocked, 0) AS TotalRoomsBlockedPerYear,
	|		ISNULL(InventoryTotalsPerQuarter.TotalRooms, 0) AS TotalRoomsPerQuarter,
	|		ISNULL(InventoryTotalsPerQuarter.TotalRoomsBlocked, 0) AS TotalRoomsBlockedPerQuarter,
	|		ISNULL(InventoryTotalsPerMonth.TotalRooms, 0) AS TotalRoomsPerMonth,
	|		ISNULL(InventoryTotalsPerMonth.TotalRoomsBlocked, 0) AS TotalRoomsBlockedPerMonth,
	|		ISNULL(InventoryTotalsPerWeek.TotalRooms, 0) AS TotalRoomsPerWeek,
	|		ISNULL(InventoryTotalsPerWeek.TotalRoomsBlocked, 0) AS TotalRoomsBlockedPerWeek,
	|		ISNULL(InventoryTotalsPerDay.TotalRooms, 0) AS TotalRoomsPerDay,
	|		ISNULL(InventoryTotalsPerDay.TotalRoomsBlocked, 0) AS TotalRoomsBlockedPerDay
	|	FROM
	|		GeoSalesTurnovers AS GeoSalesTurnovers
	|			LEFT JOIN (SELECT
	|				HotelInventoryTotals.Hotel AS Hotel,
	|				HotelInventoryTotals.CounterClosingBalance AS CounterClosingBalance,
	|				HotelInventoryTotals.TotalRooms AS TotalRooms,
	|				HotelInventoryTotals.TotalBeds AS TotalBeds,
	|				HotelInventoryTotals.TotalRoomsBlocked AS TotalRoomsBlocked,
	|				HotelInventoryTotals.TotalBedsBlocked AS TotalBedsBlocked,
	|				HotelInventoryTotals.TotalGuestsReservedReceipt AS TotalGuestsReservedReceipt,
	|				HotelInventoryTotals.TotalGuestsReservedExpense AS TotalGuestsReservedExpense,
	|				HotelInventoryTotals.TotalInHouseGuestsReceipt AS TotalInHouseGuestsReceipt,
	|				HotelInventoryTotals.TotalInHouseGuestsExpense AS TotalInHouseGuestsExpense
	|			FROM
	|				HotelInventoryTotals AS HotelInventoryTotals) AS InventoryTotals
	|			ON GeoSalesTurnovers.Hotel = InventoryTotals.Hotel
	|			LEFT JOIN (SELECT
	|				HotelInventoryTotalsPerYear.Hotel AS Hotel,
	|				HotelInventoryTotalsPerYear.Period AS Period,
	|				HotelInventoryTotalsPerYear.CounterClosingBalance AS CounterClosingBalance,
	|				HotelInventoryTotalsPerYear.TotalRooms AS TotalRooms,
	|				HotelInventoryTotalsPerYear.TotalBeds AS TotalBeds,
	|				HotelInventoryTotalsPerYear.TotalRoomsBlocked AS TotalRoomsBlocked,
	|				HotelInventoryTotalsPerYear.TotalBedsBlocked AS TotalBedsBlocked,
	|				HotelInventoryTotalsPerYear.TotalGuestsReservedReceipt AS TotalGuestsReservedReceipt,
	|				HotelInventoryTotalsPerYear.TotalGuestsReservedExpense AS TotalGuestsReservedExpense,
	|				HotelInventoryTotalsPerYear.TotalInHouseGuestsReceipt AS TotalInHouseGuestsReceipt,
	|				HotelInventoryTotalsPerYear.TotalInHouseGuestsExpense AS TotalInHouseGuestsExpense
	|			FROM
	|				HotelInventoryTotalsPerYear AS HotelInventoryTotalsPerYear) AS InventoryTotalsPerYear
	|			ON GeoSalesTurnovers.Hotel = InventoryTotalsPerYear.Hotel
	|				AND (BEGINOFPERIOD(GeoSalesTurnovers.AccountingDate, YEAR) = InventoryTotalsPerYear.Period)
	|			LEFT JOIN (SELECT
	|				HotelInventoryTotalsPerQuarter.Hotel AS Hotel,
	|				HotelInventoryTotalsPerQuarter.Period AS Period,
	|				HotelInventoryTotalsPerQuarter.CounterClosingBalance AS CounterClosingBalance,
	|				HotelInventoryTotalsPerQuarter.TotalRooms AS TotalRooms,
	|				HotelInventoryTotalsPerQuarter.TotalBeds AS TotalBeds,
	|				HotelInventoryTotalsPerQuarter.TotalRoomsBlocked AS TotalRoomsBlocked,
	|				HotelInventoryTotalsPerQuarter.TotalBedsBlocked AS TotalBedsBlocked,
	|				HotelInventoryTotalsPerQuarter.TotalGuestsReservedReceipt AS TotalGuestsReservedReceipt,
	|				HotelInventoryTotalsPerQuarter.TotalGuestsReservedExpense AS TotalGuestsReservedExpense,
	|				HotelInventoryTotalsPerQuarter.TotalInHouseGuestsReceipt AS TotalInHouseGuestsReceipt,
	|				HotelInventoryTotalsPerQuarter.TotalInHouseGuestsExpense AS TotalInHouseGuestsExpense
	|			FROM
	|				HotelInventoryTotalsPerQuarter AS HotelInventoryTotalsPerQuarter) AS InventoryTotalsPerQuarter
	|			ON GeoSalesTurnovers.Hotel = InventoryTotalsPerQuarter.Hotel
	|				AND (BEGINOFPERIOD(GeoSalesTurnovers.AccountingDate, QUARTER) = InventoryTotalsPerQuarter.Period)
	|			LEFT JOIN (SELECT
	|				HotelInventoryTotalsPerMonth.Hotel AS Hotel,
	|				HotelInventoryTotalsPerMonth.Period AS Period,
	|				HotelInventoryTotalsPerMonth.CounterClosingBalance AS CounterClosingBalance,
	|				HotelInventoryTotalsPerMonth.TotalRooms AS TotalRooms,
	|				HotelInventoryTotalsPerMonth.TotalBeds AS TotalBeds,
	|				HotelInventoryTotalsPerMonth.TotalRoomsBlocked AS TotalRoomsBlocked,
	|				HotelInventoryTotalsPerMonth.TotalBedsBlocked AS TotalBedsBlocked,
	|				HotelInventoryTotalsPerMonth.TotalGuestsReservedReceipt AS TotalGuestsReservedReceipt,
	|				HotelInventoryTotalsPerMonth.TotalGuestsReservedExpense AS TotalGuestsReservedExpense,
	|				HotelInventoryTotalsPerMonth.TotalInHouseGuestsReceipt AS TotalInHouseGuestsReceipt,
	|				HotelInventoryTotalsPerMonth.TotalInHouseGuestsExpense AS TotalInHouseGuestsExpense
	|			FROM
	|				HotelInventoryTotalsPerMonth AS HotelInventoryTotalsPerMonth) AS InventoryTotalsPerMonth
	|			ON GeoSalesTurnovers.Hotel = InventoryTotalsPerMonth.Hotel
	|				AND (BEGINOFPERIOD(GeoSalesTurnovers.AccountingDate, MONTH) = InventoryTotalsPerMonth.Period)
	|			LEFT JOIN (SELECT
	|				HotelInventoryTotalsPerWeek.Hotel AS Hotel,
	|				HotelInventoryTotalsPerWeek.Period AS Period,
	|				HotelInventoryTotalsPerWeek.CounterClosingBalance AS CounterClosingBalance,
	|				HotelInventoryTotalsPerWeek.TotalRooms AS TotalRooms,
	|				HotelInventoryTotalsPerWeek.TotalBeds AS TotalBeds,
	|				HotelInventoryTotalsPerWeek.TotalRoomsBlocked AS TotalRoomsBlocked,
	|				HotelInventoryTotalsPerWeek.TotalBedsBlocked AS TotalBedsBlocked,
	|				HotelInventoryTotalsPerWeek.TotalGuestsReservedReceipt AS TotalGuestsReservedReceipt,
	|				HotelInventoryTotalsPerWeek.TotalGuestsReservedExpense AS TotalGuestsReservedExpense,
	|				HotelInventoryTotalsPerWeek.TotalInHouseGuestsReceipt AS TotalInHouseGuestsReceipt,
	|				HotelInventoryTotalsPerWeek.TotalInHouseGuestsExpense AS TotalInHouseGuestsExpense
	|			FROM
	|				HotelInventoryTotalsPerWeek AS HotelInventoryTotalsPerWeek) AS InventoryTotalsPerWeek
	|			ON GeoSalesTurnovers.Hotel = InventoryTotalsPerWeek.Hotel
	|				AND (BEGINOFPERIOD(GeoSalesTurnovers.AccountingDate, WEEK) = InventoryTotalsPerWeek.Period)
	|			LEFT JOIN (SELECT
	|				HotelInventoryTotalsPerDay.Hotel AS Hotel,
	|				HotelInventoryTotalsPerDay.Period AS Period,
	|				HotelInventoryTotalsPerDay.CounterClosingBalance AS CounterClosingBalance,
	|				HotelInventoryTotalsPerDay.TotalRooms AS TotalRooms,
	|				HotelInventoryTotalsPerDay.TotalBeds AS TotalBeds,
	|				HotelInventoryTotalsPerDay.TotalRoomsBlocked AS TotalRoomsBlocked,
	|				HotelInventoryTotalsPerDay.TotalBedsBlocked AS TotalBedsBlocked,
	|				HotelInventoryTotalsPerDay.TotalGuestsReservedReceipt AS TotalGuestsReservedReceipt,
	|				HotelInventoryTotalsPerDay.TotalGuestsReservedExpense AS TotalGuestsReservedExpense,
	|				HotelInventoryTotalsPerDay.TotalInHouseGuestsReceipt AS TotalInHouseGuestsReceipt,
	|				HotelInventoryTotalsPerDay.TotalInHouseGuestsExpense AS TotalInHouseGuestsExpense
	|			FROM
	|				HotelInventoryTotalsPerDay AS HotelInventoryTotalsPerDay) AS InventoryTotalsPerDay
	|			ON GeoSalesTurnovers.Hotel = InventoryTotalsPerDay.Hotel
	|				AND GeoSalesTurnovers.AccountingDate = InventoryTotalsPerDay.Period
	|			LEFT JOIN (SELECT
	|				GeoSalesTotalTurnovers.Hotel AS Hotel,
	|				GeoSalesTotalTurnovers.TotalSalesAmount AS TotalSalesAmount,
	|				GeoSalesTotalTurnovers.TotalGuestsCheckedIn AS TotalGuestsCheckedIn,
	|				GeoSalesTotalTurnovers.TotalGuestDays AS TotalGuestDays
	|			FROM
	|				GeoSalesTotalTurnovers AS GeoSalesTotalTurnovers) AS GeoSalesTotals
	|			ON GeoSalesTurnovers.Hotel = GeoSalesTotals.Hotel
	|			LEFT JOIN (SELECT
	|				GeoSalesTotalYearlyTurnovers.Hotel AS Hotel,
	|				GeoSalesTotalYearlyTurnovers.Period AS Period,
	|				GeoSalesTotalYearlyTurnovers.TotalSalesAmount AS TotalSalesAmount,
	|				GeoSalesTotalYearlyTurnovers.TotalGuestsCheckedIn AS TotalGuestsCheckedIn,
	|				GeoSalesTotalYearlyTurnovers.TotalGuestDays AS TotalGuestDays
	|			FROM
	|				GeoSalesTotalYearlyTurnovers AS GeoSalesTotalYearlyTurnovers) AS GeoSalesYearlyTotals
	|			ON GeoSalesTurnovers.Hotel = GeoSalesYearlyTotals.Hotel
	|				AND (BEGINOFPERIOD(GeoSalesTurnovers.AccountingDate, YEAR) = GeoSalesYearlyTotals.Period)
	|			LEFT JOIN (SELECT
	|				GeoSalesTotalQuarterlyTurnovers.Hotel AS Hotel,
	|				GeoSalesTotalQuarterlyTurnovers.Period AS Period,
	|				GeoSalesTotalQuarterlyTurnovers.TotalSalesAmount AS TotalSalesAmount,
	|				GeoSalesTotalQuarterlyTurnovers.TotalGuestsCheckedIn AS TotalGuestsCheckedIn,
	|				GeoSalesTotalQuarterlyTurnovers.TotalGuestDays AS TotalGuestDays
	|			FROM
	|				GeoSalesTotalQuarterlyTurnovers AS GeoSalesTotalQuarterlyTurnovers) AS GeoSalesQuarterlyTotals
	|			ON GeoSalesTurnovers.Hotel = GeoSalesQuarterlyTotals.Hotel
	|				AND (BEGINOFPERIOD(GeoSalesTurnovers.AccountingDate, QUARTER) = GeoSalesQuarterlyTotals.Period)
	|			LEFT JOIN (SELECT
	|				GeoSalesTotalMonthlyTurnovers.Hotel AS Hotel,
	|				GeoSalesTotalMonthlyTurnovers.Period AS Period,
	|				GeoSalesTotalMonthlyTurnovers.TotalSalesAmount AS TotalSalesAmount,
	|				GeoSalesTotalMonthlyTurnovers.TotalGuestsCheckedIn AS TotalGuestsCheckedIn,
	|				GeoSalesTotalMonthlyTurnovers.TotalGuestDays AS TotalGuestDays
	|			FROM
	|				GeoSalesTotalMonthlyTurnovers AS GeoSalesTotalMonthlyTurnovers) AS GeoSalesMonthlyTotals
	|			ON GeoSalesTurnovers.Hotel = GeoSalesMonthlyTotals.Hotel
	|				AND (BEGINOFPERIOD(GeoSalesTurnovers.AccountingDate, MONTH) = GeoSalesMonthlyTotals.Period)
	|			LEFT JOIN (SELECT
	|				GeoSalesTotalWeeklyTurnovers.Hotel AS Hotel,
	|				GeoSalesTotalWeeklyTurnovers.Period AS Period,
	|				GeoSalesTotalWeeklyTurnovers.TotalSalesAmount AS TotalSalesAmount,
	|				GeoSalesTotalWeeklyTurnovers.TotalGuestsCheckedIn AS TotalGuestsCheckedIn,
	|				GeoSalesTotalWeeklyTurnovers.TotalGuestDays AS TotalGuestDays
	|			FROM
	|				GeoSalesTotalWeeklyTurnovers AS GeoSalesTotalWeeklyTurnovers) AS GeoSalesWeeklyTotals
	|			ON GeoSalesTurnovers.Hotel = GeoSalesWeeklyTotals.Hotel
	|				AND (BEGINOFPERIOD(GeoSalesTurnovers.AccountingDate, WEEK) = GeoSalesWeeklyTotals.Period)
	|			LEFT JOIN (SELECT
	|				GeoSalesTotalDailyTurnovers.Hotel AS Hotel,
	|				GeoSalesTotalDailyTurnovers.Period AS Period,
	|				GeoSalesTotalDailyTurnovers.TotalSalesAmount AS TotalSalesAmount,
	|				GeoSalesTotalDailyTurnovers.TotalGuestsCheckedIn AS TotalGuestsCheckedIn,
	|				GeoSalesTotalDailyTurnovers.TotalGuestDays AS TotalGuestDays
	|			FROM
	|				GeoSalesTotalDailyTurnovers AS GeoSalesTotalDailyTurnovers) AS GeoSalesDailyTotals
	|			ON GeoSalesTurnovers.Hotel = GeoSalesDailyTotals.Hotel
	|				AND GeoSalesTurnovers.AccountingDate = GeoSalesDailyTotals.Period) AS GeoSales
	|		LEFT JOIN InformationRegister.ReservationCustomAttributeValues AS ReservationCustomAttributeValues1
	|		ON (GeoSales.ParentDoc.Reservation = ReservationCustomAttributeValues1.Owner
	|				OR GeoSales.ParentDoc = ReservationCustomAttributeValues1.Owner
	|					AND GeoSales.ParentDoc.Reservation.Number IS NULL)
	|			AND (ReservationCustomAttributeValues1.Characteristic = &qCustomAttribute1)
	|		LEFT JOIN InformationRegister.ReservationCustomAttributeValues AS ReservationCustomAttributeValues2
	|		ON (GeoSales.ParentDoc.Reservation = ReservationCustomAttributeValues2.Owner
	|				OR GeoSales.ParentDoc = ReservationCustomAttributeValues2.Owner
	|					AND GeoSales.ParentDoc.Reservation.Number IS NULL)
	|			AND (ReservationCustomAttributeValues2.Characteristic = &qCustomAttribute2)
	|		LEFT JOIN InformationRegister.ReservationCustomAttributeValues AS ReservationCustomAttributeValues3
	|		ON (GeoSales.ParentDoc.Reservation = ReservationCustomAttributeValues3.Owner
	|				OR GeoSales.ParentDoc = ReservationCustomAttributeValues3.Owner
	|					AND GeoSales.ParentDoc.Reservation.Number IS NULL)
	|			AND (ReservationCustomAttributeValues3.Characteristic = &qCustomAttribute3)
	|{WHERE
	|	GeoSales.ReportingCurrency.*,
	|	GeoSales.Hotel.*,
	|	GeoSales.ClientCitizenship.*,
	|	GeoSales.ClientRegion,
	|	GeoSales.ClientCity,
	|	GeoSales.ClientAge,
	|	GeoSales.MarketingCode.*,
	|	GeoSales.SourceOfBusiness.*,
	|	GeoSales.TripPurpose.*,
	|	GeoSales.ParentDoc.*,
	|	ReservationCustomAttributeValues1.CharacteristicValue.* AS CustomAttribute1,
	|	ReservationCustomAttributeValues2.CharacteristicValue.* AS CustomAttribute2,
	|	ReservationCustomAttributeValues3.CharacteristicValue.* AS CustomAttribute3,
	|	GeoSales.Service.*,
	|	GeoSales.Sales AS Sales,
	|	GeoSales.RoomRevenue AS RoomRevenue,
	|	GeoSales.ExtraBedRevenue AS ExtraBedRevenue,
	|	GeoSales.MainBedsRevenue AS MainBedsRevenue,
	|	GeoSales.SalesWithoutVAT AS SalesWithoutVAT,
	|	GeoSales.RoomRevenueWithoutVAT AS RoomRevenueWithoutVAT,
	|	GeoSales.ExtraBedRevenueWithoutVAT AS ExtraBedRevenueWithoutVAT,
	|	GeoSales.MainBedsRevenueWithoutVAT AS MainBedsRevenueWithoutVAT,
	|	GeoSales.CommissionSum AS CommissionSum,
	|	GeoSales.CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|	GeoSales.DiscountSum AS DiscountSum,
	|	GeoSales.DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|	GeoSales.RoomsRented AS RoomsRented,
	|	GeoSales.BedsRented AS BedsRented,
	|	GeoSales.AdditionalBedsRented AS AdditionalBedsRented,
	|	GeoSales.GuestDays AS GuestDays,
	|	GeoSales.GuestsCheckedIn AS GuestsCheckedIn,
	|	GeoSales.RoomsCheckedIn AS RoomsCheckedIn,
	|	GeoSales.BedsCheckedIn AS BedsCheckedIn,
	|	GeoSales.AdditionalBedsCheckedIn AS AdditionalBedsCheckedIn,
	|	GeoSales.GuestGroup.* AS GuestGroup,
	|	(CASE
	|			WHEN GeoSales.GuestsCheckedIn > 0
	|				THEN CAST(GeoSales.BookingWindow / GeoSales.GuestsCheckedIn AS NUMBER(10, 0))
	|			ELSE 0
	|		END) AS BookingWindow,
	|	GeoSales.Quantity AS Quantity,
	|	(CASE
	|			WHEN NOT GeoSales.GuestGroup.GroupType.Code IS NULL
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS IsGroupReservation,
	|	(CASE
	|			WHEN GeoSales.ClientAge IS NULL
	|				THEN &qUndefinedAge
	|			WHEN ISNULL(GeoSales.ClientDateOfBirth, &qEmptyDate) = &qEmptyDate
	|				THEN &qUndefinedAge
	|			WHEN GeoSales.ClientAge < 15
	|				THEN &qChild
	|			WHEN GeoSales.ClientAge < 22
	|				THEN &qTeenager
	|			WHEN GeoSales.ClientAge < 30
	|				THEN &q2229
	|			WHEN GeoSales.ClientAge < 40
	|				THEN &q3039
	|			WHEN GeoSales.ClientAge < 50
	|				THEN &q4049
	|			WHEN GeoSales.ClientAge < 60
	|				THEN &q5059
	|			ELSE &qGreater60
	|		END) AS AgeRange,
	|	GeoSales.AccountingDate,
	|	(BEGINOFPERIOD(GeoSales.AccountingDate, WEEK)) AS AccountingWeek,
	|	(BEGINOFPERIOD(GeoSales.AccountingDate, MONTH)) AS AccountingMonth,
	|	(BEGINOFPERIOD(GeoSales.AccountingDate, QUARTER)) AS AccountingQuarter,
	|	(YEAR(GeoSales.AccountingDate)) AS AccountingYear}
	|
	|ORDER BY
	|	ReportingCurrency,
	|	ClientCitizenship,
	|	ClientRegion
	|{ORDER BY
	|	ReportingCurrency.*,
	|	Hotel.*,
	|	ClientCitizenship.*,
	|	ClientRegion,
	|	ClientCity,
	|	ClientAge,
	|	MarketingCode.*,
	|	SourceOfBusiness.*,
	|	TripPurpose.*,
	|	Company.*,
	|	Service.*,
	|	ParentDoc.*,
	|	ReservationCustomAttributeValues1.CharacteristicValue.* AS CustomAttribute1,
	|	ReservationCustomAttributeValues2.CharacteristicValue.* AS CustomAttribute2,
	|	ReservationCustomAttributeValues3.CharacteristicValue.* AS CustomAttribute3,
	|	TotalSalesAmount,
	|	TotalSalesPercent,
	|	TotalGuestsCheckedIn,
	|	TotalGuestsCheckedInPercent,
	|	TotalGuestDays,
	|	TotalGuestDaysPercent,
	|	TotalSalesAmountPerYear,
	|	TotalSalesPercentPerYear,
	|	TotalGuestsCheckedInPerYear,
	|	TotalGuestsCheckedInPercentPerYear,
	|	TotalGuestDaysPerYear,
	|	TotalGuestDaysPercentPerYear,
	|	TotalSalesAmountPerQuarter,
	|	TotalSalesPercentPerQuarter,
	|	TotalGuestsCheckedInPerQuarter,
	|	TotalGuestsCheckedInPercentPerQuarter,
	|	TotalGuestDaysPerQuarter,
	|	TotalGuestDaysPercentPerQuarter,
	|	TotalSalesAmountPerMonth,
	|	TotalSalesPercentPerMonth,
	|	TotalGuestsCheckedInPerMonth,
	|	TotalGuestsCheckedInPercentPerMonth,
	|	TotalGuestDaysPerMonth,
	|	TotalGuestDaysPercentPerMonth,
	|	TotalSalesAmountPerWeek,
	|	TotalSalesPercentPerWeek,
	|	TotalGuestsCheckedInPerWeek,
	|	TotalGuestsCheckedInPercentPerWeek,
	|	TotalGuestDaysPerWeek,
	|	TotalGuestDaysPercentPerWeek,
	|	TotalSalesAmountPerDay,
	|	TotalSalesPercentPerDay,
	|	TotalGuestsCheckedInPerDay,
	|	TotalGuestsCheckedInPercentPerDay,
	|	TotalGuestDaysPerDay,
	|	TotalGuestDaysPercentPerDay,
	|	Sales,
	|	RoomRevenue,
	|	ExtraBedRevenue,
	|	MainBedsRevenue,
	|	SalesWithoutVAT,
	|	RoomRevenueWithoutVAT,
	|	ExtraBedRevenueWithoutVAT,
	|	MainBedsRevenueWithoutVAT,
	|	CommissionSum,
	|	CommissionSumWithoutVAT,
	|	DiscountSum,
	|	DiscountSumWithoutVAT,
	|	RoomsRented,
	|	BedsRented,
	|	AdditionalBedsRented,
	|	GuestDays,
	|	GuestsCheckedIn,
	|	RoomsCheckedIn,
	|	BedsCheckedIn,
	|	AdditionalBedsCheckedIn,
	|	BookingWindow,
	|	Quantity,
	|	GeoSales.GuestGroup.* AS GuestGroup,
	|	(CASE
	|			WHEN NOT GeoSales.GuestGroup.GroupType.Code IS NULL
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS IsGroupReservation,
	|	(CASE
	|			WHEN GeoSales.ClientAge IS NULL
	|				THEN &qUndefinedAge
	|			WHEN ISNULL(GeoSales.ClientDateOfBirth, &qEmptyDate) = &qEmptyDate
	|				THEN &qUndefinedAge
	|			WHEN GeoSales.ClientAge < 15
	|				THEN &qChild
	|			WHEN GeoSales.ClientAge < 22
	|				THEN &qTeenager
	|			WHEN GeoSales.ClientAge < 30
	|				THEN &q2229
	|			WHEN GeoSales.ClientAge < 40
	|				THEN &q3039
	|			WHEN GeoSales.ClientAge < 50
	|				THEN &q4049
	|			WHEN GeoSales.ClientAge < 60
	|				THEN &q5059
	|			ELSE &qGreater60
	|		END) AS AgeRange,
	|	AccountingDate,
	|	AccountingWeek,
	|	AccountingMonth,
	|	AccountingQuarter,
	|	AccountingYear}
	|TOTALS
	|	MAX(RoomsPerPeriod),
	|	MAX(BedsPerPeriod),
	|	MAX(RoomsBlockedPerPeriod),
	|	MAX(BedsBlockedPerPeriod),
	|	CASE
	|		WHEN SUM(RoomsRented) = 0
	|			THEN 0
	|		ELSE SUM(RoomRevenue) / SUM(RoomsRented)
	|	END AS AverageRoomPrice,
	|	CASE
	|		WHEN SUM(BedsRented) = 0
	|			THEN 0
	|		ELSE SUM(RoomRevenue) / SUM(BedsRented)
	|	END AS AverageBedPrice,
	|	CASE
	|		WHEN MAX(RoomsPerPeriod) = 0
	|			THEN 0
	|		ELSE SUM(RoomRevenue) / MAX(RoomsPerPeriod)
	|	END AS RevPAR,
	|	CASE
	|		WHEN MAX(BedsPerPeriod) = 0
	|			THEN 0
	|		ELSE SUM(RoomRevenue) / MAX(BedsPerPeriod)
	|	END AS RevPAB,
	|	CASE
	|		WHEN SUM(RoomsRented) = 0
	|			THEN 0
	|		ELSE SUM(RoomRevenueWithoutVAT) / SUM(RoomsRented)
	|	END AS AverageRoomPriceWithoutVAT,
	|	CASE
	|		WHEN SUM(BedsRented) = 0
	|			THEN 0
	|		ELSE SUM(RoomRevenueWithoutVAT) / SUM(BedsRented)
	|	END AS AverageBedPriceWithoutVAT,
	|	CASE
	|		WHEN MAX(RoomsPerPeriod) = 0
	|			THEN 0
	|		ELSE SUM(RoomRevenueWithoutVAT) / MAX(RoomsPerPeriod)
	|	END AS RevPARWithoutVAT,
	|	CASE
	|		WHEN MAX(BedsPerPeriod) = 0
	|			THEN 0
	|		ELSE SUM(RoomRevenueWithoutVAT) / MAX(BedsPerPeriod)
	|	END AS RevPABWithoutVAT,
	|	CASE
	|		WHEN MAX(RoomsPerPeriod) = 0
	|			THEN 0
	|		ELSE SUM(RoomsRented) * 100 / MAX(RoomsPerPeriod)
	|	END AS RoomsRentedPercent,
	|	CASE
	|		WHEN MAX(BedsPerPeriod) = 0
	|			THEN 0
	|		ELSE SUM(BedsRented) * 100 / MAX(BedsPerPeriod)
	|	END AS BedsRentedPercent,
	|	CASE
	|		WHEN MAX(RoomsPerPeriod) - MAX(RoomsBlockedPerPeriod) = 0
	|			THEN 0
	|		ELSE SUM(RoomsRented) * 100 / (MAX(RoomsPerPeriod) - MAX(RoomsBlockedPerPeriod))
	|	END AS RoomsRentedPercentWithRoomBlocks,
	|	CASE
	|		WHEN MAX(BedsPerPeriod) - MAX(BedsBlockedPerPeriod) = 0
	|			THEN 0
	|		ELSE SUM(BedsRented) * 100 / (MAX(BedsPerPeriod) - MAX(BedsBlockedPerPeriod))
	|	END AS BedsRentedPercentWithRoomBlocks,
	|	SUM(Sales),
	|	SUM(RoomRevenue),
	|	SUM(ExtraBedRevenue),
	|	SUM(MainBedsRevenue),
	|	SUM(SalesWithoutVAT),
	|	SUM(RoomRevenueWithoutVAT),
	|	SUM(ExtraBedRevenueWithoutVAT),
	|	SUM(MainBedsRevenueWithoutVAT),
	|	SUM(CommissionSum),
	|	SUM(CommissionSumWithoutVAT),
	|	SUM(DiscountSum),
	|	SUM(DiscountSumWithoutVAT),
	|	SUM(RoomsRented),
	|	SUM(BedsRented),
	|	SUM(AdditionalBedsRented),
	|	SUM(GuestDays),
	|	SUM(GuestsCheckedIn),
	|	SUM(RoomsCheckedIn),
	|	SUM(BedsCheckedIn),
	|	SUM(AdditionalBedsCheckedIn),
	|	CASE
	|		WHEN SUM(GuestsCheckedIn) > 0
	|			THEN CAST(SUM(BookingWindow) / SUM(GuestsCheckedIn) AS NUMBER(10, 0))
	|		ELSE 0
	|	END AS BookingWindow,
	|	SUM(Quantity),
	|	MAX(TotalSalesAmount),
	|	CASE
	|		WHEN MAX(TotalSalesAmount) = 0
	|			THEN 0
	|		ELSE SUM(Sales) * 100 / MAX(TotalSalesAmount)
	|	END AS TotalSalesPercent,
	|	MAX(TotalGuestsCheckedIn),
	|	CASE
	|		WHEN MAX(TotalGuestsCheckedIn) = 0
	|			THEN 0
	|		ELSE SUM(GuestsCheckedIn) * 100 / MAX(TotalGuestsCheckedIn)
	|	END AS TotalGuestsCheckedInPercent,
	|	MAX(TotalGuestDays),
	|	CASE
	|		WHEN MAX(TotalGuestDays) = 0
	|			THEN 0
	|		ELSE SUM(GuestDays) * 100 / MAX(TotalGuestDays)
	|	END AS TotalGuestDaysPercent,
	|	MAX(TotalSalesAmountPerYear),
	|	CASE
	|		WHEN AccountingYear IS NULL
	|			THEN CASE
	|					WHEN MAX(TotalSalesAmount) = 0
	|						THEN 0
	|					ELSE SUM(Sales) * 100 / MAX(TotalSalesAmount)
	|				END
	|		ELSE CASE
	|				WHEN MAX(TotalSalesAmountPerYear) = 0
	|					THEN 0
	|				ELSE SUM(Sales) * 100 / MAX(TotalSalesAmountPerYear)
	|			END
	|	END AS TotalSalesPercentPerYear,
	|	MAX(TotalGuestsCheckedInPerYear),
	|	CASE
	|		WHEN AccountingYear IS NULL
	|			THEN CASE
	|					WHEN MAX(TotalGuestsCheckedIn) = 0
	|						THEN 0
	|					ELSE SUM(GuestsCheckedIn) * 100 / MAX(TotalGuestsCheckedIn)
	|				END
	|		ELSE CASE
	|				WHEN MAX(TotalGuestsCheckedInPerYear) = 0
	|					THEN 0
	|				ELSE SUM(GuestsCheckedIn) * 100 / MAX(TotalGuestsCheckedInPerYear)
	|			END
	|	END AS TotalGuestsCheckedInPercentPerYear,
	|	MAX(TotalGuestDaysPerYear),
	|	CASE
	|		WHEN AccountingYear IS NULL
	|			THEN CASE
	|					WHEN MAX(TotalGuestDays) = 0
	|						THEN 0
	|					ELSE SUM(GuestDays) * 100 / MAX(TotalGuestDays)
	|				END
	|		ELSE CASE
	|				WHEN MAX(TotalGuestDaysPerYear) = 0
	|					THEN 0
	|				ELSE SUM(GuestDays) * 100 / MAX(TotalGuestDaysPerYear)
	|			END
	|	END AS TotalGuestDaysPercentPerYear,
	|	MAX(TotalSalesAmountPerQuarter),
	|	CASE
	|		WHEN AccountingQuarter IS NULL
	|			THEN CASE
	|					WHEN MAX(TotalSalesAmount) = 0
	|						THEN 0
	|					ELSE SUM(Sales) * 100 / MAX(TotalSalesAmount)
	|				END
	|		ELSE CASE
	|				WHEN MAX(TotalSalesAmountPerQuarter) = 0
	|					THEN 0
	|				ELSE SUM(Sales) * 100 / MAX(TotalSalesAmountPerQuarter)
	|			END
	|	END AS TotalSalesPercentPerQuarter,
	|	MAX(TotalGuestsCheckedInPerQuarter),
	|	CASE
	|		WHEN AccountingQuarter IS NULL
	|			THEN CASE
	|					WHEN MAX(TotalGuestsCheckedIn) = 0
	|						THEN 0
	|					ELSE SUM(GuestsCheckedIn) * 100 / MAX(TotalGuestsCheckedIn)
	|				END
	|		ELSE CASE
	|				WHEN MAX(TotalGuestsCheckedInPerQuarter) = 0
	|					THEN 0
	|				ELSE SUM(GuestsCheckedIn) * 100 / MAX(TotalGuestsCheckedInPerQuarter)
	|			END
	|	END AS TotalGuestsCheckedInPercentPerQuarter,
	|	MAX(TotalGuestDaysPerQuarter),
	|	CASE
	|		WHEN AccountingQuarter IS NULL
	|			THEN CASE
	|					WHEN MAX(TotalGuestDays) = 0
	|						THEN 0
	|					ELSE SUM(GuestDays) * 100 / MAX(TotalGuestDays)
	|				END
	|		ELSE CASE
	|				WHEN MAX(TotalGuestDaysPerQuarter) = 0
	|					THEN 0
	|				ELSE SUM(GuestDays) * 100 / MAX(TotalGuestDaysPerQuarter)
	|			END
	|	END AS TotalGuestDaysPercentPerQuarter,
	|	MAX(TotalSalesAmountPerMonth),
	|	CASE
	|		WHEN AccountingMonth IS NULL
	|			THEN CASE
	|					WHEN MAX(TotalSalesAmount) = 0
	|						THEN 0
	|					ELSE SUM(Sales) * 100 / MAX(TotalSalesAmount)
	|				END
	|		ELSE CASE
	|				WHEN MAX(TotalSalesAmountPerMonth) = 0
	|					THEN 0
	|				ELSE SUM(Sales) * 100 / MAX(TotalSalesAmountPerMonth)
	|			END
	|	END AS TotalSalesPercentPerMonth,
	|	MAX(TotalGuestsCheckedInPerMonth),
	|	CASE
	|		WHEN AccountingMonth IS NULL
	|			THEN CASE
	|					WHEN MAX(TotalGuestsCheckedIn) = 0
	|						THEN 0
	|					ELSE SUM(GuestsCheckedIn) * 100 / MAX(TotalGuestsCheckedIn)
	|				END
	|		ELSE CASE
	|				WHEN MAX(TotalGuestsCheckedInPerMonth) = 0
	|					THEN 0
	|				ELSE SUM(GuestsCheckedIn) * 100 / MAX(TotalGuestsCheckedInPerMonth)
	|			END
	|	END AS TotalGuestsCheckedInPercentPerMonth,
	|	MAX(TotalGuestDaysPerMonth),
	|	CASE
	|		WHEN AccountingMonth IS NULL
	|			THEN CASE
	|					WHEN MAX(TotalGuestDays) = 0
	|						THEN 0
	|					ELSE SUM(GuestDays) * 100 / MAX(TotalGuestDays)
	|				END
	|		ELSE CASE
	|				WHEN MAX(TotalGuestDaysPerMonth) = 0
	|					THEN 0
	|				ELSE SUM(GuestDays) * 100 / MAX(TotalGuestDaysPerMonth)
	|			END
	|	END AS TotalGuestDaysPercentPerMonth,
	|	MAX(TotalSalesAmountPerWeek),
	|	CASE
	|		WHEN AccountingWeek IS NULL
	|			THEN CASE
	|					WHEN MAX(TotalSalesAmount) = 0
	|						THEN 0
	|					ELSE SUM(Sales) * 100 / MAX(TotalSalesAmount)
	|				END
	|		ELSE CASE
	|				WHEN MAX(TotalSalesAmountPerWeek) = 0
	|					THEN 0
	|				ELSE SUM(Sales) * 100 / MAX(TotalSalesAmountPerWeek)
	|			END
	|	END AS TotalSalesPercentPerWeek,
	|	MAX(TotalGuestsCheckedInPerWeek),
	|	CASE
	|		WHEN AccountingMonth IS NULL
	|			THEN CASE
	|					WHEN MAX(TotalGuestsCheckedIn) = 0
	|						THEN 0
	|					ELSE SUM(GuestsCheckedIn) * 100 / MAX(TotalGuestsCheckedIn)
	|				END
	|		ELSE CASE
	|				WHEN MAX(TotalGuestsCheckedInPerWeek) = 0
	|					THEN 0
	|				ELSE SUM(GuestsCheckedIn) * 100 / MAX(TotalGuestsCheckedInPerWeek)
	|			END
	|	END AS TotalGuestsCheckedInPercentPerWeek,
	|	MAX(TotalGuestDaysPerWeek),
	|	CASE
	|		WHEN AccountingWeek IS NULL
	|			THEN CASE
	|					WHEN MAX(TotalGuestDays) = 0
	|						THEN 0
	|					ELSE SUM(GuestDays) * 100 / MAX(TotalGuestDays)
	|				END
	|		ELSE CASE
	|				WHEN MAX(TotalGuestDaysPerWeek) = 0
	|					THEN 0
	|				ELSE SUM(GuestDays) * 100 / MAX(TotalGuestDaysPerWeek)
	|			END
	|	END AS TotalGuestDaysPercentPerWeek,
	|	MAX(TotalSalesAmountPerDay),
	|	CASE
	|		WHEN AccountingDate IS NULL
	|			THEN CASE
	|					WHEN MAX(TotalSalesAmount) = 0
	|						THEN 0
	|					ELSE SUM(Sales) * 100 / MAX(TotalSalesAmount)
	|				END
	|		ELSE CASE
	|				WHEN MAX(TotalSalesAmountPerDay) = 0
	|					THEN 0
	|				ELSE SUM(Sales) * 100 / MAX(TotalSalesAmountPerDay)
	|			END
	|	END AS TotalSalesPercentPerDay,
	|	MAX(TotalGuestsCheckedInPerDay),
	|	CASE
	|		WHEN AccountingDate IS NULL
	|			THEN CASE
	|					WHEN MAX(TotalGuestsCheckedIn) = 0
	|						THEN 0
	|					ELSE SUM(GuestsCheckedIn) * 100 / MAX(TotalGuestsCheckedIn)
	|				END
	|		ELSE CASE
	|				WHEN MAX(TotalGuestsCheckedInPerDay) = 0
	|					THEN 0
	|				ELSE SUM(GuestsCheckedIn) * 100 / MAX(TotalGuestsCheckedInPerDay)
	|			END
	|	END AS TotalGuestsCheckedInPercentPerDay,
	|	MAX(TotalGuestDaysPerDay),
	|	CASE
	|		WHEN AccountingDate IS NULL
	|			THEN CASE
	|					WHEN MAX(TotalGuestDays) = 0
	|						THEN 0
	|					ELSE SUM(GuestDays) * 100 / MAX(TotalGuestDays)
	|				END
	|		ELSE CASE
	|				WHEN MAX(TotalGuestDaysPerDay) = 0
	|					THEN 0
	|				ELSE SUM(GuestDays) * 100 / MAX(TotalGuestDaysPerDay)
	|			END
	|	END AS TotalGuestDaysPercentPerDay,
	|	CASE
	|		WHEN AccountingYear IS NULL
	|			THEN CASE
	|					WHEN MAX(RoomsPerPeriod) - MAX(RoomsBlockedPerPeriod) <> 0
	|						THEN CAST(SUM(RoomsRented) / (MAX(RoomsPerPeriod) - MAX(RoomsBlockedPerPeriod)) * 100 AS NUMBER(10, 3))
	|					ELSE 0
	|				END
	|		ELSE CASE
	|				WHEN MAX(TotalRoomsPerYear) - MAX(TotalRoomsBlockedPerYear) <> 0
	|					THEN CAST(SUM(RoomsRented) / (MAX(TotalRoomsPerYear) - MAX(TotalRoomsBlockedPerYear)) * 100 AS NUMBER(10, 3))
	|				ELSE 0
	|			END
	|	END AS PerYearOccupancyPercent,
	|	CASE
	|		WHEN AccountingYear IS NULL
	|			THEN CASE
	|					WHEN MAX(RoomsPerPeriod) <> 0
	|						THEN CAST(SUM(RoomsRented) / MAX(RoomsPerPeriod) * 100 AS NUMBER(10, 3))
	|					ELSE 0
	|				END
	|		ELSE CASE
	|				WHEN MAX(TotalRoomsPerYear) <> 0
	|					THEN CAST(SUM(RoomsRented) / MAX(TotalRoomsPerYear) * 100 AS NUMBER(10, 3))
	|				ELSE 0
	|			END
	|	END AS PerYearRoomsRentedPercent,
	|	CASE
	|		WHEN AccountingQuarter IS NULL
	|			THEN CASE
	|					WHEN MAX(RoomsPerPeriod) - MAX(RoomsBlockedPerPeriod) <> 0
	|						THEN CAST(SUM(RoomsRented) / (MAX(RoomsPerPeriod) - MAX(RoomsBlockedPerPeriod)) * 100 AS NUMBER(10, 3))
	|					ELSE 0
	|				END
	|		ELSE CASE
	|				WHEN MAX(TotalRoomsPerQuarter) - MAX(TotalRoomsBlockedPerQuarter) <> 0
	|					THEN CAST(SUM(RoomsRented) / (MAX(TotalRoomsPerQuarter) - MAX(TotalRoomsBlockedPerQuarter)) * 100 AS NUMBER(10, 3))
	|				ELSE 0
	|			END
	|	END AS PerQuarterOccupancyPercent,
	|	CASE
	|		WHEN AccountingQuarter IS NULL
	|			THEN CASE
	|					WHEN MAX(RoomsPerPeriod) <> 0
	|						THEN CAST(SUM(RoomsRented) / MAX(RoomsPerPeriod) * 100 AS NUMBER(10, 3))
	|					ELSE 0
	|				END
	|		ELSE CASE
	|				WHEN MAX(TotalRoomsPerQuarter) <> 0
	|					THEN CAST(SUM(RoomsRented) / MAX(TotalRoomsPerQuarter) * 100 AS NUMBER(10, 3))
	|				ELSE 0
	|			END
	|	END AS PerQuarterRoomsRentedPercent,
	|	CASE
	|		WHEN AccountingMonth IS NULL
	|			THEN CASE
	|					WHEN MAX(RoomsPerPeriod) - MAX(RoomsBlockedPerPeriod) <> 0
	|						THEN CAST(SUM(RoomsRented) / (MAX(RoomsPerPeriod) - MAX(RoomsBlockedPerPeriod)) * 100 AS NUMBER(10, 3))
	|					ELSE 0
	|				END
	|		ELSE CASE
	|				WHEN MAX(TotalRoomsPerMonth) - MAX(TotalRoomsBlockedPerMonth) <> 0
	|					THEN CAST(SUM(RoomsRented) / (MAX(TotalRoomsPerMonth) - MAX(TotalRoomsBlockedPerMonth)) * 100 AS NUMBER(10, 3))
	|				ELSE 0
	|			END
	|	END AS PerMonthOccupancyPercent,
	|	CASE
	|		WHEN AccountingMonth IS NULL
	|			THEN CASE
	|					WHEN MAX(RoomsPerPeriod) <> 0
	|						THEN CAST(SUM(RoomsRented) / MAX(RoomsPerPeriod) * 100 AS NUMBER(10, 3))
	|					ELSE 0
	|				END
	|		ELSE CASE
	|				WHEN MAX(TotalRoomsPerMonth) <> 0
	|					THEN CAST(SUM(RoomsRented) / MAX(TotalRoomsPerMonth) * 100 AS NUMBER(10, 3))
	|				ELSE 0
	|			END
	|	END AS PerMonthRoomsRentedPercent,
	|	CASE
	|		WHEN AccountingWeek IS NULL
	|			THEN CASE
	|					WHEN MAX(RoomsPerPeriod) - MAX(RoomsBlockedPerPeriod) <> 0
	|						THEN CAST(SUM(RoomsRented) / (MAX(RoomsPerPeriod) - MAX(RoomsBlockedPerPeriod)) * 100 AS NUMBER(10, 3))
	|					ELSE 0
	|				END
	|		ELSE CASE
	|				WHEN MAX(TotalRoomsPerWeek) - MAX(TotalRoomsBlockedPerWeek) <> 0
	|					THEN CAST(SUM(RoomsRented) / (MAX(TotalRoomsPerWeek) - MAX(TotalRoomsBlockedPerWeek)) * 100 AS NUMBER(10, 3))
	|				ELSE 0
	|			END
	|	END AS PerWeekOccupancyPercent,
	|	CASE
	|		WHEN AccountingWeek IS NULL
	|			THEN CASE
	|					WHEN MAX(RoomsPerPeriod) <> 0
	|						THEN CAST(SUM(RoomsRented) / MAX(RoomsPerPeriod) * 100 AS NUMBER(10, 3))
	|					ELSE 0
	|				END
	|		ELSE CASE
	|				WHEN MAX(TotalRoomsPerWeek) <> 0
	|					THEN CAST(SUM(RoomsRented) / MAX(TotalRoomsPerWeek) * 100 AS NUMBER(10, 3))
	|				ELSE 0
	|			END
	|	END AS PerWeekRoomsRentedPercent,
	|	CASE
	|		WHEN AccountingDate IS NULL
	|			THEN CASE
	|					WHEN MAX(RoomsPerPeriod) - MAX(RoomsBlockedPerPeriod) <> 0
	|						THEN CAST(SUM(RoomsRented) / (MAX(RoomsPerPeriod) - MAX(RoomsBlockedPerPeriod)) * 100 AS NUMBER(10, 3))
	|					ELSE 0
	|				END
	|		ELSE CASE
	|				WHEN MAX(TotalRoomsPerDay) - MAX(TotalRoomsBlockedPerDay) <> 0
	|					THEN CAST(SUM(RoomsRented) / (MAX(TotalRoomsPerDay) - MAX(TotalRoomsBlockedPerDay)) * 100 AS NUMBER(10, 3))
	|				ELSE 0
	|			END
	|	END AS PerDayOccupancyPercent,
	|	CASE
	|		WHEN AccountingDate IS NULL
	|			THEN CASE
	|					WHEN MAX(RoomsPerPeriod) <> 0
	|						THEN CAST(SUM(RoomsRented) / MAX(RoomsPerPeriod) * 100 AS NUMBER(10, 3))
	|					ELSE 0
	|				END
	|		ELSE CASE
	|				WHEN MAX(TotalRoomsPerDay) <> 0
	|					THEN CAST(SUM(RoomsRented) / MAX(TotalRoomsPerDay) * 100 AS NUMBER(10, 3))
	|				ELSE 0
	|			END
	|	END AS PerDayRoomsRentedPercent,
	|	CASE
	|		WHEN AccountingYear IS NULL
	|			THEN MAX(RoomsPerPeriod)
	|		ELSE MAX(TotalRoomsPerYear)
	|	END AS TotalRoomsPerYear,
	|	CASE
	|		WHEN AccountingYear IS NULL
	|			THEN MAX(RoomsBlockedPerPeriod)
	|		ELSE MAX(TotalRoomsBlockedPerYear)
	|	END AS TotalRoomsBlockedPerYear,
	|	CASE
	|		WHEN AccountingQuarter IS NULL
	|			THEN MAX(RoomsPerPeriod)
	|		ELSE MAX(TotalRoomsPerQuarter)
	|	END AS TotalRoomsPerQuarter,
	|	CASE
	|		WHEN AccountingQuarter IS NULL
	|			THEN MAX(RoomsBlockedPerPeriod)
	|		ELSE MAX(TotalRoomsBlockedPerQuarter)
	|	END AS TotalRoomsBlockedPerQuarter,
	|	CASE
	|		WHEN AccountingMonth IS NULL
	|			THEN MAX(RoomsPerPeriod)
	|		ELSE MAX(TotalRoomsPerMonth)
	|	END AS TotalRoomsPerMonth,
	|	CASE
	|		WHEN AccountingMonth IS NULL
	|			THEN MAX(RoomsBlockedPerPeriod)
	|		ELSE MAX(TotalRoomsBlockedPerMonth)
	|	END AS TotalRoomsBlockedPerMonth,
	|	CASE
	|		WHEN AccountingWeek IS NULL
	|			THEN MAX(RoomsPerPeriod)
	|		ELSE MAX(TotalRoomsPerWeek)
	|	END AS TotalRoomsPerWeek,
	|	CASE
	|		WHEN AccountingWeek IS NULL
	|			THEN MAX(RoomsBlockedPerPeriod)
	|		ELSE MAX(TotalRoomsBlockedPerWeek)
	|	END AS TotalRoomsBlockedPerWeek,
	|	CASE
	|		WHEN AccountingDate IS NULL
	|			THEN MAX(RoomsPerPeriod)
	|		ELSE MAX(TotalRoomsPerDay)
	|	END AS TotalRoomsPerDay,
	|	CASE
	|		WHEN AccountingDate IS NULL
	|			THEN MAX(RoomsBlockedPerPeriod)
	|		ELSE MAX(TotalRoomsBlockedPerDay)
	|	END AS TotalRoomsBlockedPerDay
	|BY
	|	OVERALL,
	|	ClientCitizenship HIERARCHY,
	|	ClientRegion,
	|	AccountingYear,
	|	AccountingQuarter,
	|	AccountingMonth,
	|	AccountingWeek,
	|	AccountingDate
	|{TOTALS BY
	|	GeoSales.ReportingCurrency.*,
	|	GeoSales.Hotel.*,
	|	GeoSales.ClientCitizenship.*,
	|	GeoSales.ClientRegion,
	|	GeoSales.ClientCity,
	|	GeoSales.ClientAge,
	|	GeoSales.MarketingCode.*,
	|	GeoSales.SourceOfBusiness.*,
	|	GeoSales.TripPurpose.*,
	|	GeoSales.Company.*,
	|	GeoSales.ParentDoc.*,
	|	ReservationCustomAttributeValues1.CharacteristicValue.* AS CustomAttribute1,
	|	ReservationCustomAttributeValues2.CharacteristicValue.* AS CustomAttribute2,
	|	ReservationCustomAttributeValues3.CharacteristicValue.* AS CustomAttribute3,
	|	GeoSales.Service.*,
	|	GeoSales.GuestGroup.* AS GuestGroup,
	|	(CASE
	|			WHEN NOT GeoSales.GuestGroup.GroupType.Code IS NULL
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS IsGroupReservation,
	|	(CASE
	|			WHEN SUM(GeoSales.RoomsCheckedIn) <> 0
	|				THEN CAST(SUM(GeoSales.BookingWindow) / SUM(GeoSales.RoomsCheckedIn) AS NUMBER(10, 0))
	|			ELSE 0
	|		END) AS BookingWindow,
	|	(CASE
	|			WHEN GeoSales.ClientAge IS NULL
	|				THEN &qUndefinedAge
	|			WHEN ISNULL(GeoSales.ClientDateOfBirth, &qEmptyDate) = &qEmptyDate
	|				THEN &qUndefinedAge
	|			WHEN GeoSales.ClientAge < 15
	|				THEN &qChild
	|			WHEN GeoSales.ClientAge < 22
	|				THEN &qTeenager
	|			WHEN GeoSales.ClientAge < 30
	|				THEN &q2229
	|			WHEN GeoSales.ClientAge < 40
	|				THEN &q3039
	|			WHEN GeoSales.ClientAge < 50
	|				THEN &q4049
	|			WHEN GeoSales.ClientAge < 60
	|				THEN &q5059
	|			ELSE &qGreater60
	|		END) AS AgeRange,
	|	AccountingDate,
	|	AccountingWeek,
	|	AccountingMonth,
	|	AccountingQuarter,
	|	AccountingYear}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Geo sales turnovers';RU='Обороты продаж по регионам';de='Verkaufsumsätze nach Regionen'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
Function pmIsResource(pName) Export
	If pName = "Sales" 
	   Or pName = "RoomRevenue" 
	   Or pName = "ExtraBedRevenue" 
	   Or pName = "MainBedsRevenue" 
	   Or pName = "SalesWithoutVAT" 
	   Or pName = "RoomRevenueWithoutVAT" 
	   Or pName = "ExtraBedRevenueWithoutVAT" 
	   Or pName = "MainBedsRevenueWithoutVAT" 
	   Or pName = "CommissionSum" 
	   Or pName = "CommissionSumWithoutVAT" 
	   Or pName = "DiscountSum" 
	   Or pName = "DiscountSumWithoutVAT" 
	   Or pName = "RoomsRented" 
	   Or pName = "BedsRented" 
	   Or pName = "AdditionalBedsRented" 
	   Or pName = "GuestDays" 
	   Or pName = "GuestsCheckedIn" 
	   Or pName = "RoomsCheckedIn" 
	   Or pName = "BedsCheckedIn" 
	   Or pName = "AdditionalBedsCheckedIn" 
	   Or pName = "Quantity" 
	   Or pName = "RoomsPerPeriod" 
	   Or pName = "BedsPerPeriod" 
	   Or pName = "RoomsBlockedPerPeriod" 
	   Or pName = "BedsBlockedPerPeriod" 
	   Or pName = "AverageRoomPrice" 
	   Or pName = "AverageBedPrice" 
	   Or pName = "RevPAR" 
	   Or pName = "RevPAB" 
	   Or pName = "AverageBedPriceWithoutVAT" 
	   Or pName = "RevPARWithoutVAT" 
	   Or pName = "RevPABWithoutVAT" 
	   Or pName = "RoomsRentedPercent" 
	   Or pName = "BedsRentedPercent" 
	   Or pName = "RoomsRentedPercentWithRoomBlocks" 
	   Or pName = "BedsRentedPercentWithRoomBlocks" 
	   Or pName = "TotalSalesAmount" 
	   Or pName = "TotalSalesPercent" 
	   Or pName = "TotalGuestsCheckedIn" 
	   Or pName = "TotalGuestsCheckedInPercent" 
	   Or pName = "TotalGuestDays" 
	   Or pName = "TotalGuestDaysPercent" 
	   Or pName = "TotalSalesAmountPerYear" 
	   Or pName = "TotalSalesPercentPerYear" 
	   Or pName = "TotalGuestsCheckedInPerYear" 
	   Or pName = "TotalGuestsCheckedInPercentPerYear" 
	   Or pName = "TotalGuestDaysPerYear" 
	   Or pName = "TotalGuestDaysPercentPerYear" 
	   Or pName = "TotalSalesAmountPerQuarter" 
	   Or pName = "TotalSalesPercentPerQuarter" 
	   Or pName = "TotalGuestsCheckedInPerQuarter" 
	   Or pName = "TotalGuestsCheckedInPercentPerQuarter" 
	   Or pName = "TotalGuestDaysPerQuarter" 
	   Or pName = "TotalGuestDaysPercentPerQuarter" 
	   Or pName = "TotalSalesAmountPerMonth" 
	   Or pName = "TotalSalesPercentPerMonth" 
	   Or pName = "TotalGuestsCheckedInPerMonth" 
	   Or pName = "TotalGuestsCheckedInPercentPerMonth" 
	   Or pName = "TotalGuestDaysPerMonth" 
	   Or pName = "TotalGuestDaysPercentPerMonth" 
	   Or pName = "TotalSalesAmountPerWeek" 
	   Or pName = "TotalSalesPercentPerWeek" 
	   Or pName = "TotalGuestsCheckedInPerWeek" 
	   Or pName = "TotalGuestsCheckedInPercentPerWeek" 
	   Or pName = "TotalGuestDaysPerWeek" 
	   Or pName = "TotalGuestDaysPercentPerWeek" 
	   Or pName = "TotalSalesAmountPerDay" 
	   Or pName = "TotalSalesPercentPerDay" 
	   Or pName = "TotalGuestsCheckedInPerDay" 
	   Or pName = "TotalGuestsCheckedInPercentPerDay" 
	   Or pName = "TotalGuestDaysPerDay" 
	   Or pName = "TotalGuestDaysPercentPerDay" 
	   Or pName = "PerYearOccupancyPercent" 
	   Or pName = "PerYearRoomsRentedPercent" 
	   Or pName = "TotalRoomsPerYear" 
	   Or pName = "TotalRoomsBlockedPerYear" 
	   Or pName = "PerQuarterOccupancyPercent" 
	   Or pName = "PerQuarterRoomsRentedPercent" 
	   Or pName = "TotalRoomsPerQuarter" 
	   Or pName = "TotalRoomsBlockedPerQuarter" 
	   Or pName = "PerMonthOccupancyPercent" 
	   Or pName = "PerMonthRoomsRentedPercent" 
	   Or pName = "TotalRoomsPerMonth" 
	   Or pName = "TotalRoomsBlockedPerMonth" 
	   Or pName = "PerWeekOccupancyPercent" 
	   Or pName = "PerWeekRoomsRentedPercent" 
	   Or pName = "TotalRoomsPerWeek" 
	   Or pName = "TotalRoomsBlockedPerWeek" 
	   Or pName = "PerDayOccupancyPercent" 
	   Or pName = "PerDayRoomsRentedPercent" 
	   Or pName = "TotalRoomsPerDay" 
	   Or pName = "TotalRoomsBlockedPerDay" 
	   Or pName = "BookingWindow" Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // pmIsResource

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
