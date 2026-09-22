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
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qIsEmptyRoomType", Not ValueIsFilled(RoomType));
	
	// Execute report builder query
	ReportBuilder.Execute();
	
	// Apply appearance settings to the report template
	vTemplateAttributes = cmApplyReportTemplateAppearance(ThisObject);
	
	// Output report to the spreadsheet
	ReportBuilder.Put(pSpreadsheet);
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
	|	PlanFact.CheckInDay AS CheckInDay,
	|	PlanFact.RoomsCheckedIn AS RoomsCheckedIn,
	|	PlanFact.BedsCheckedIn AS BedsCheckedIn,
	|	PlanFact.AdditionalBedsCheckedIn AS AdditionalBedsCheckedIn,
	|	PlanFact.GuestsCheckedIn AS GuestsCheckedIn,
	|	PlanFact.GuestsReserved AS GuestsReserved,
	|	PlanFact.RoomsReserved AS RoomsReserved,
	|	PlanFact.BedsReserved AS BedsReserved,
	|	PlanFact.AdditionalBedsReserved AS AdditionalBedsReserved,
	|	PlanFact.GuestsReserved - PlanFact.GuestsCheckedIn AS NoShowGuests,
	|	PlanFact.RoomsReserved - PlanFact.RoomsCheckedIn AS NoShowRooms,
	|	PlanFact.BedsReserved - PlanFact.BedsCheckedIn AS NoShowBeds,
	|	PlanFact.AdditionalBedsReserved - PlanFact.AdditionalBedsCheckedIn AS NoShowAdditionalBeds
	|{SELECT
	|	CheckInDay,
	|	PlanFact.CheckInWeek,
	|	PlanFact.CheckInMonth,
	|	PlanFact.CheckInQuarter,
	|	PlanFact.CheckInYear,
	|	PlanFact.Hotel.*,
	|	PlanFact.RoomType.*,
	|	PlanFact.Reservation.*,
	|	PlanFact.ReservationStatus.*,
	|	PlanFact.Accommodation.*,
	|	PlanFact.AccommodationStatus.*,
	|	PlanFact.Customer.*,
	|	PlanFact.Contract.*,
	|	PlanFact.GuestGroup.*,
	|	PlanFact.Agent.*,
	|	PlanFact.Guest.*,
	|	PlanFact.RoomRate.*,
	|	PlanFact.AccommodationType.*,
	|	PlanFact.ParentDoc.*,
	|	RoomsCheckedIn,
	|	BedsCheckedIn,
	|	AdditionalBedsCheckedIn,
	|	GuestsCheckedIn,
	|	GuestsReserved,
	|	RoomsReserved,
	|	BedsReserved,
	|	AdditionalBedsReserved,
	|	NoShowGuests,
	|	NoShowRooms,
	|	NoShowBeds,
	|	NoShowAdditionalBeds}
	|FROM
	|	(SELECT
	|		BEGINOFPERIOD(Accommodation.CheckInDate, DAY) AS CheckInDay,
	|		WEEK(Accommodation.CheckInDate) AS CheckInWeek,
	|		MONTH(Accommodation.CheckInDate) AS CheckInMonth,
	|		QUARTER(Accommodation.CheckInDate) AS CheckInQuarter,
	|		YEAR(Accommodation.CheckInDate) AS CheckInYear,
	|		Accommodation.Hotel AS Hotel,
	|		Accommodation.RoomType AS RoomType,
	|		Accommodation.Reservation AS Reservation,
	|		Accommodation.Recorder AS Accommodation,
	|		Accommodation.ParentDoc AS ParentDoc,
	|		Accommodation.Reservation.ReservationStatus AS ReservationStatus,
	|		Accommodation.AccommodationStatus AS AccommodationStatus,
	|		Accommodation.Customer AS Customer,
	|		Accommodation.Contract AS Contract,
	|		Accommodation.GuestGroup AS GuestGroup,
	|		Accommodation.Agent AS Agent,
	|		Accommodation.Guest AS Guest,
	|		Accommodation.RoomRate AS RoomRate,
	|		Accommodation.AccommodationType AS AccommodationType,
	|		SUM(Accommodation.NumberOfPersons) AS GuestsCheckedIn,
	|		SUM(Accommodation.NumberOfRooms) AS RoomsCheckedIn,
	|		SUM(Accommodation.NumberOfBeds) AS BedsCheckedIn,
	|		SUM(Accommodation.NumberOfAdditionalBeds) AS AdditionalBedsCheckedIn,
	|		0 AS GuestsReserved,
	|		0 AS RoomsReserved,
	|		0 AS BedsReserved,
	|		0 AS AdditionalBedsReserved
	|	FROM
	|		AccumulationRegister.RoomInventory AS Accommodation
	|	WHERE
	|		Accommodation.IsAccommodation
	|		AND Accommodation.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND Accommodation.IsCheckIn
	|		AND Accommodation.CheckInDate >= &qPeriodFrom
	|		AND Accommodation.CheckInDate < &qPeriodTo
	|		AND Accommodation.Period = Accommodation.CheckInDate
	|		AND Accommodation.Hotel IN HIERARCHY(&qHotel)
	|		AND (Accommodation.RoomType IN HIERARCHY (&qRoomType)
	|				OR &qIsEmptyRoomType)
	|	
	|	GROUP BY
	|		BEGINOFPERIOD(Accommodation.CheckInDate, DAY),
	|		WEEK(Accommodation.CheckInDate),
	|		MONTH(Accommodation.CheckInDate),
	|		QUARTER(Accommodation.CheckInDate),
	|		YEAR(Accommodation.CheckInDate),
	|		Accommodation.Hotel,
	|		Accommodation.RoomType,
	|		Accommodation.Recorder,
	|		Accommodation.AccommodationStatus,
	|		Accommodation.Customer,
	|		Accommodation.Contract,
	|		Accommodation.GuestGroup,
	|		Accommodation.Agent,
	|		Accommodation.Guest,
	|		Accommodation.RoomRate,
	|		Accommodation.AccommodationType,
	|		Accommodation.Reservation,
	|		Accommodation.ParentDoc,
	|		Accommodation.Reservation.ReservationStatus
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		BEGINOFPERIOD(Reservation.CheckInDate, DAY),
	|		WEEK(Reservation.CheckInDate),
	|		MONTH(Reservation.CheckInDate),
	|		QUARTER(Reservation.CheckInDate),
	|		YEAR(Reservation.CheckInDate),
	|		Reservation.Hotel,
	|		Reservation.RoomType,
	|		Reservation.Ref,
	|		NULL,
	|		Reservation.ParentDoc,
	|		Reservation.ReservationStatus,
	|		NULL,
	|		Reservation.Customer,
	|		Reservation.Contract,
	|		Reservation.GuestGroup,
	|		Reservation.Agent,
	|		Reservation.Guest,
	|		Reservation.RoomRate,
	|		Reservation.AccommodationType,
	|		0,
	|		0,
	|		0,
	|		0,
	|		SUM(Reservation.NumberOfPersons),
	|		SUM(Reservation.NumberOfRooms),
	|		SUM(Reservation.NumberOfBeds),
	|		SUM(Reservation.NumberOfAdditionalBeds)
	|	FROM
	|		Document.Reservation AS Reservation
	|	WHERE
	|		Reservation.Posted
	|		AND Reservation.CheckInDate >= &qPeriodFrom
	|		AND Reservation.CheckInDate < &qPeriodTo
	|		AND Reservation.Hotel IN HIERARCHY(&qHotel)
	|		AND (Reservation.RoomType IN HIERARCHY (&qRoomType)
	|				OR &qIsEmptyRoomType)
	|	
	|	GROUP BY
	|		BEGINOFPERIOD(Reservation.CheckInDate, DAY),
	|		WEEK(Reservation.CheckInDate),
	|		MONTH(Reservation.CheckInDate),
	|		QUARTER(Reservation.CheckInDate),
	|		YEAR(Reservation.CheckInDate),
	|		Reservation.Hotel,
	|		Reservation.RoomType,
	|		Reservation.Ref,
	|		Reservation.ReservationStatus,
	|		Reservation.Customer,
	|		Reservation.Contract,
	|		Reservation.GuestGroup,
	|		Reservation.Agent,
	|		Reservation.Guest,
	|		Reservation.RoomRate,
	|		Reservation.AccommodationType,
	|		Reservation.ParentDoc) AS PlanFact
	|{WHERE
	|	PlanFact.CheckInDay,
	|	PlanFact.CheckInWeek,
	|	PlanFact.CheckInMonth,
	|	PlanFact.CheckInQuarter,
	|	PlanFact.CheckInYear,
	|	PlanFact.Hotel.*,
	|	PlanFact.RoomType.*,
	|	PlanFact.Reservation.*,
	|	PlanFact.Accommodation.*,
	|	PlanFact.ParentDoc.*,
	|	PlanFact.ReservationStatus.*,
	|	PlanFact.AccommodationStatus.*,
	|	PlanFact.Customer.* AS Customer,
	|	PlanFact.Contract.* AS Contract,
	|	PlanFact.GuestGroup.* AS GuestGroup,
	|	PlanFact.Agent.* AS Agent,
	|	PlanFact.Guest.* AS Guest,
	|	PlanFact.RoomRate.* AS RoomRate,
	|	PlanFact.AccommodationType.* AS AccommodationType,
	|	PlanFact.RoomsCheckedIn,
	|	PlanFact.BedsCheckedIn,
	|	PlanFact.AdditionalBedsCheckedIn,
	|	PlanFact.GuestsCheckedIn,
	|	PlanFact.GuestsReserved,
	|	PlanFact.RoomsReserved,
	|	PlanFact.BedsReserved,
	|	PlanFact.AdditionalBedsReserved,
	|	(PlanFact.GuestsReserved - PlanFact.GuestsCheckedIn) AS NoShowGuests,
	|	(PlanFact.RoomsReserved - PlanFact.RoomsCheckedIn) AS NoShowRooms,
	|	(PlanFact.BedsReserved - PlanFact.BedsCheckedIn) AS NoShowBeds,
	|	(PlanFact.AdditionalBedsReserved - PlanFact.AdditionalBedsCheckedIn) AS NoShowAdditionalBeds}
	|
	|ORDER BY
	|	CheckInDay
	|{ORDER BY
	|	CheckInDay,
	|	PlanFact.CheckInWeek,
	|	PlanFact.CheckInMonth,
	|	PlanFact.CheckInQuarter,
	|	PlanFact.CheckInYear,
	|	PlanFact.Hotel.*,
	|	PlanFact.RoomType.*,
	|	PlanFact.Reservation.*,
	|	PlanFact.Accommodation.*,
	|	PlanFact.ParentDoc.*,
	|	PlanFact.ReservationStatus.*,
	|	PlanFact.AccommodationStatus.*,
	|	PlanFact.Customer.* AS Customer,
	|	PlanFact.Contract.* AS Contract,
	|	PlanFact.GuestGroup.* AS GuestGroup,
	|	PlanFact.Agent.* AS Agent,
	|	PlanFact.Guest.* AS Guest,
	|	PlanFact.RoomRate.* AS RoomRate,
	|	PlanFact.AccommodationType.* AS AccommodationType,
	|	RoomsCheckedIn,
	|	BedsCheckedIn,
	|	AdditionalBedsCheckedIn,
	|	GuestsCheckedIn,
	|	GuestsReserved,
	|	RoomsReserved,
	|	BedsReserved,
	|	AdditionalBedsReserved}
	|TOTALS
	|	SUM(RoomsCheckedIn),
	|	SUM(BedsCheckedIn),
	|	SUM(AdditionalBedsCheckedIn),
	|	SUM(GuestsCheckedIn),
	|	SUM(GuestsReserved),
	|	SUM(RoomsReserved),
	|	SUM(BedsReserved),
	|	SUM(AdditionalBedsReserved),
	|	SUM(NoShowGuests),
	|	SUM(NoShowRooms),
	|	SUM(NoShowBeds),
	|	SUM(NoShowAdditionalBeds)
	|BY
	|	OVERALL,
	|	CheckInDay
	|{TOTALS BY
	|	CheckInDay,
	|	PlanFact.CheckInWeek,
	|	PlanFact.CheckInMonth,
	|	PlanFact.CheckInQuarter,
	|	PlanFact.CheckInYear,
	|	PlanFact.Hotel.*,
	|	PlanFact.RoomType.*,
	|	PlanFact.ReservationStatus.*,
	|	PlanFact.AccommodationStatus.*,
	|	PlanFact.Customer.* AS Customer,
	|	PlanFact.Contract.* AS Contract,
	|	PlanFact.GuestGroup.* AS GuestGroup,
	|	PlanFact.Agent.* AS Agent,
	|	PlanFact.Guest.* AS Guest,
	|	PlanFact.RoomRate.* AS RoomRate,
	|	PlanFact.AccommodationType.* AS AccommodationType,
	|	PlanFact.Reservation.*,
	|	PlanFact.Accommodation.*,
	|	PlanFact.ParentDoc.*}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Reservations plan/fact analysis';RU='План/фактный анализ брони';de='Plan-/Ist-Analyse der Buchung'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
Function pmIsResource(pName) Export
	If pName = "RoomsCheckedIn" 
	   Or pName = "BedsCheckedIn" 
	   Or pName = "AdditionalBedsCheckedIn" 
	   Or pName = "GuestsCheckedIn" 
	   Or pName = "RoomsReserved" 
	   Or pName = "BedsReserved" 
	   Or pName = "AdditionalBedsReserved" 
	   Or pName = "GuestsReserved" Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // pmIsResource

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
