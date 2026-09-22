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
		PeriodTo = PeriodFrom + 7*24*3600;
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
	ReportBuilder.Parameters.Insert("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qEmptyDate", '00010101');
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qEmptyRoom", Catalogs.Rooms.EmptyRef());
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qOvernights", NStr("en = '1. Overnights'; ru = '1. Проживающие'; de = '1. Übernachtungen'"));
	ReportBuilder.Parameters.Insert("qArrivals", NStr("en = '2. Arrivals'; ru = '2. Заезд'; de = '2. Anreise'"));
	ReportBuilder.Parameters.Insert("qDepartures", NStr("en = '3. Departures'; ru = '3. Выезд'; de = '3. Abreise'"));
	ReportBuilder.Parameters.Insert("qEmptyMealBoardTerm", Catalogs.Services.EmptyRef());
	ReportBuilder.Parameters.Insert("qBedAndBreakfastTerm", GetBeadAndBreakfastTerm());

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
	|	BEGINOFPERIOD(Days.Period, DAY) AS Period
	|INTO Days
	|FROM
	|	AccumulationRegister.RoomInventory AS Days
	|WHERE
	|	Days.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND Days.Period = BEGINOFPERIOD(Days.Period, DAY)
	|	AND Days.Period >= &qPeriodFrom
	|	AND Days.Period <= &qPeriodTo
	|	AND Days.Counter > 0
	|	AND NOT Days.IsRoomInventory
	|	AND NOT Days.IsBlocking
	|	AND NOT Days.IsReservation
	|	AND NOT Days.IsAccommodation
	|	AND NOT Days.IsRoomQuota
	|	AND NOT Days.IsRoomChange
	|
	|GROUP BY
	|	BEGINOFPERIOD(Days.Period, DAY)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Guests.Hotel AS Hotel,
	|	Guests.Period AS Period,
	|	Guests.GuestType AS GuestType,
	|	Guests.MealBoardTerm AS MealBoardTerm,
	|	Guests.NumberOfRooms AS NumberOfRooms,
	|	Guests.NumberOfAdults AS NumberOfAdults,
	|	Guests.NumberOfChildren AS NumberOfChildren,
	|	Guests.NumberOfPersons AS NumberOfPersons
	|{SELECT
	|	Hotel.* AS Hotel,
	|	Period AS Period,
	|	GuestType AS GuestType,
	|	MealBoardTerm.* AS MealBoardTerm,
	|	NumberOfRooms,
	|	NumberOfAdults,
	|	NumberOfChildren,
	|	NumberOfPersons}
	|FROM
	|	(SELECT
	|		GuestsRows.Hotel AS Hotel,
	|		GuestsRows.Period AS Period,
	|		GuestsRows.GuestType AS GuestType,
	|		GuestsRows.MealBoardTerm AS MealBoardTerm,
	|		SUM(GuestsRows.NumberOfRooms) AS NumberOfRooms,
	|		SUM(GuestsRows.NumberOfAdults) AS NumberOfAdults,
	|		SUM(GuestsRows.NumberOfChildren) AS NumberOfChildren,
	|		SUM(GuestsRows.NumberOfPersons) AS NumberOfPersons
	|	FROM
	|		(SELECT
	|			Days.Period AS Period,
	|			Overnights.Hotel AS Hotel,
	|			&qOvernights AS GuestType,
	|			CASE
	|				WHEN NOT TermsUpgrade.Service IS NULL
	|					THEN TermsUpgrade.Service.UpgradeToTerms
	|				WHEN ISNULL(Overnights.Recorder.ServicePackage.IsMealBoardTerm, FALSE)
	|					THEN CASE
	|							WHEN Overnights.Recorder.ServicePackage.KitchenDailyMovementReportService <> &qEmptyMealBoardTerm
	|								THEN Overnights.Recorder.ServicePackage.KitchenDailyMovementReportService
	|							ELSE Overnights.Recorder.ServicePackage.RoomRevenueService
	|						END
	|				ELSE &qEmptyMealBoardTerm
	|			END AS MealBoardTerm,
	|			Overnights.Recorder.NumberOfTeenagers + Overnights.Recorder.NumberOfChildren AS NumberOfChildren,
	|			Overnights.Recorder.NumberOfAdults AS NumberOfAdults,
	|			Overnights.Recorder.NumberOfAdults + Overnights.Recorder.NumberOfTeenagers + Overnights.Recorder.NumberOfChildren AS NumberOfPersons,
	|			Overnights.NumberOfRooms AS NumberOfRooms
	|		FROM
	|			Days AS Days
	|				LEFT JOIN AccumulationRegister.RoomInventory AS Overnights
	|				ON (Overnights.RecordType = VALUE(AccumulationRecordType.Expense))
	|					AND (Overnights.IsReservation
	|						OR Overnights.IsAccommodation)
	|					AND (Overnights.Hotel IN HIERARCHY (&qHotel))
	|					AND (Overnights.Room IN HIERARCHY (&qRoom)
	|						OR Overnights.Room = &qEmptyRoom)
	|					AND (Overnights.RoomType IN HIERARCHY (&qRoomType))
	|					AND (Overnights.CheckInDate = Overnights.Period)
	|					AND (Overnights.CheckInAccountingDate < Days.Period)
	|					AND (Overnights.CheckOutAccountingDate > Days.Period)
	|				LEFT JOIN AccumulationRegister.Sales AS TermsUpgrade
	|				ON Days.Period = TermsUpgrade.ServiceDate
	|					AND (CASE
	|							WHEN ISNULL(Overnights.Recorder.ServicePackage.IsMealBoardTerm, FALSE)
	|								THEN CASE
	|										WHEN Overnights.Recorder.ServicePackage.KitchenDailyMovementReportService <> &qEmptyMealBoardTerm
	|											THEN Overnights.Recorder.ServicePackage.KitchenDailyMovementReportService
	|										ELSE Overnights.Recorder.ServicePackage.RoomRevenueService
	|									END
	|							ELSE NULL
	|						END = TermsUpgrade.Service.UpgradeFromTerms
	|						OR TermsUpgrade.Service.UpgradeFromTerms = &qEmptyMealBoardTerm)
	|					AND (Overnights.Recorder = TermsUpgrade.ParentDoc)
	|					AND (NOT TermsUpgrade.ParentDoc.Number IS NULL)
	|					AND (NOT TermsUpgrade.Service.UpgradeToTerms.Code IS NULL)
	|					AND (TermsUpgrade.Hotel IN HIERARCHY (&qHotel))
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			Days.Period,
	|			Arrivals.Hotel,
	|			&qArrivals,
	|			CASE
	|				WHEN NOT TermsUpgrade.Service IS NULL
	|					THEN TermsUpgrade.Service.UpgradeToTerms
	|				WHEN ISNULL(Arrivals.Recorder.ServicePackage.IsMealBoardTerm, FALSE)
	|					THEN CASE
	|							WHEN Arrivals.Recorder.ServicePackage.KitchenDailyMovementReportService <> &qEmptyMealBoardTerm
	|								THEN Arrivals.Recorder.ServicePackage.KitchenDailyMovementReportService
	|							ELSE Arrivals.Recorder.ServicePackage.RoomRevenueService
	|						END
	|				ELSE &qEmptyMealBoardTerm
	|			END,
	|			Arrivals.Recorder.NumberOfTeenagers + Arrivals.Recorder.NumberOfChildren,
	|			Arrivals.Recorder.NumberOfAdults,
	|			Arrivals.Recorder.NumberOfAdults + Arrivals.Recorder.NumberOfTeenagers + Arrivals.Recorder.NumberOfChildren,
	|			Arrivals.NumberOfRooms
	|		FROM
	|			Days AS Days
	|				LEFT JOIN AccumulationRegister.RoomInventory AS Arrivals
	|				ON (Arrivals.RecordType = VALUE(AccumulationRecordType.Expense))
	|					AND (Arrivals.IsReservation
	|						OR Arrivals.IsAccommodation)
	|					AND (Arrivals.Hotel IN HIERARCHY (&qHotel))
	|					AND (Arrivals.Room IN HIERARCHY (&qRoom)
	|						OR Arrivals.Room = &qEmptyRoom)
	|					AND (Arrivals.RoomType IN HIERARCHY (&qRoomType))
	|					AND (Arrivals.CheckInDate = Arrivals.Period)
	|					AND (Arrivals.CheckInAccountingDate = Days.Period)
	|				LEFT JOIN AccumulationRegister.Sales AS TermsUpgrade
	|				ON Days.Period = TermsUpgrade.ServiceDate
	|					AND (CASE
	|							WHEN ISNULL(Arrivals.Recorder.ServicePackage.IsMealBoardTerm, FALSE)
	|								THEN CASE
	|										WHEN Arrivals.Recorder.ServicePackage.KitchenDailyMovementReportService <> &qEmptyMealBoardTerm
	|											THEN Arrivals.Recorder.ServicePackage.KitchenDailyMovementReportService
	|										ELSE Arrivals.Recorder.ServicePackage.RoomRevenueService
	|									END
	|							ELSE NULL
	|						END = TermsUpgrade.Service.UpgradeFromTerms
	|						OR TermsUpgrade.Service.UpgradeFromTerms = &qEmptyMealBoardTerm)
	|					AND (Arrivals.Recorder = TermsUpgrade.ParentDoc)
	|					AND (NOT TermsUpgrade.ParentDoc.Number IS NULL)
	|					AND (NOT TermsUpgrade.Service.UpgradeToTerms.Code IS NULL)
	|					AND (TermsUpgrade.Hotel IN HIERARCHY (&qHotel))
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			Days.Period,
	|			Departures.Hotel,
	|			&qDepartures,
	|			CASE
	|				WHEN ISNULL(Departures.Recorder.ServicePackage.IsMealBoardTerm, FALSE)
	|					THEN &qBedAndBreakfastTerm
	|				ELSE &qEmptyMealBoardTerm
	|			END,
	|			Departures.Recorder.NumberOfTeenagers + Departures.Recorder.NumberOfChildren,
	|			Departures.Recorder.NumberOfAdults,
	|			Departures.Recorder.NumberOfAdults + Departures.Recorder.NumberOfTeenagers + Departures.Recorder.NumberOfChildren,
	|			Departures.NumberOfRooms
	|		FROM
	|			Days AS Days
	|				LEFT JOIN AccumulationRegister.RoomInventory AS Departures
	|				ON (Departures.RecordType = VALUE(AccumulationRecordType.Expense))
	|					AND (Departures.IsReservation
	|						OR Departures.IsAccommodation)
	|					AND (Departures.Hotel IN HIERARCHY (&qHotel))
	|					AND (Departures.Room IN HIERARCHY (&qRoom)
	|						OR Departures.Room = &qEmptyRoom)
	|					AND (Departures.RoomType IN HIERARCHY (&qRoomType))
	|					AND (Departures.CheckInDate = Departures.Period)
	|					AND (Departures.CheckOutAccountingDate = Days.Period)) AS GuestsRows
	|	WHERE
	|		GuestsRows.Hotel <> &qEmptyHotel
	|		AND GuestsRows.MealBoardTerm <> &qEmptyMealBoardTerm
	|	
	|	GROUP BY
	|		GuestsRows.Hotel,
	|		GuestsRows.Period,
	|		GuestsRows.GuestType,
	|		GuestsRows.MealBoardTerm) AS Guests
	|{WHERE
	|	Guests.Hotel.* AS Hotel,
	|	Guests.Period AS Period,
	|	Guests.GuestType AS GuestType,
	|	Guests.MealBoardTerm.* AS MealBoardTerm}
	|
	|ORDER BY
	|	Guests.Hotel,
	|	Guests.Period,
	|	Guests.GuestType,
	|	Guests.MealBoardTerm
	|{ORDER BY
	|	Hotel.* AS Hotel,
	|	Period AS Period,
	|	GuestType AS GuestType,
	|	MealBoardTerm.* AS MealBoardTerm}
	|TOTALS
	|	SUM(NumberOfRooms),
	|	SUM(NumberOfAdults),
	|	SUM(NumberOfChildren),
	|	SUM(NumberOfPersons)
	|BY
	|	Period,
	|	MealBoardTerm
	|{TOTALS BY
	|	Hotel.* AS Hotel,
	|	Period AS Period,
	|	GuestType AS GuestType,
	|	MealBoardTerm.* AS MealBoardTerm}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Kitchen daily movements';RU='Движение гостей по дням для кухни';de='Tägliche Bewegung der Küche'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Function GetBeadAndBreakfastTerm()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ServicePackages.Ref,
	|	ServicePackages.RoomRevenueService,
	|	ServicePackages.KitchenDailyMovementReportService
	|FROM
	|	Catalog.ServicePackages AS ServicePackages
	|WHERE
	|	NOT ServicePackages.IsFolder
	|	AND NOT ServicePackages.DeletionMark
	|	AND ServicePackages.IsBB
	|	AND (ServicePackages.Hotel = &qHotel
	|			OR ServicePackages.Hotel = &qEmptyHotel)
	|
	|ORDER BY
	|	ServicePackages.Code,
	|	ServicePackages.SortCode";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vTerms = vQry.Execute().Unload();
	If vTerms.Count() > 0 Then
		vTermsRow = vTerms.Get(0);
		If ValueIsFilled(vTermsRow.KitchenDailyMovementReportService) Then
			Return vTermsRow.KitchenDailyMovementReportService;
		ElsIf ValueIsFilled(vTermsRow.RoomRevenueService) Then
			Return vTermsRow.RoomRevenueService;
		Else
			Return Catalogs.Services.EmptyRef();
		EndIf;
	Else
		Return Catalogs.Services.EmptyRef();
	EndIf;
EndFunction // GetBeadAndBreakfastTerm
