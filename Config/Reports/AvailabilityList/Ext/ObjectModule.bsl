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
		PeriodFrom = BegOfDay(CurrentSessionDate()); // For beg of current date
		PeriodTo = EndOfDay(AddMonth(CurrentSessionDate(), 1)); // Same date of the next month
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
		                     Format(PeriodFrom, "DF=dd.MM.yyyy") + 
		                     ";" + Chars.LF;
	ElsIf Not ValueIsFilled(PeriodFrom) And ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период по '; en = 'Period to '; de = 'Periode zu '") + 
		                     Format(PeriodTo, "DF=dd.MM.yyyy") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom = PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период на '; en = 'Period on '; de = 'Periode '") + 
		                     Format(PeriodFrom, "DF=dd.MM.yyyy") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom <= PeriodTo Then
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
	If ValueIsFilled(Customer) Then
		If Not Customer.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Customer ';ru='Заказчик ';de='Firma '") + 
								 TrimAll(Customer.Description) + 
								 ";" + Chars.LF;
		 Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа заказчиков '; en = 'Customers folder '; de = 'Firmengruppe '") + 
								 TrimAll(Customer.Description) + 
								 ";" + Chars.LF;
		 EndIf;							 
	EndIf;							 
	If ValueIsFilled(Contract) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Договор '; en = 'Contract '; de = 'Vertrag '") + 
		                     TrimAll(Contract.Description) + 
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
Procedure pmGenerate(pSpreadsheet, pAddChart = False) Export
	Var vTemplateAttributes;
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
	
	// Initialize report builder query generator attributes
	ReportBuilder.PresentationAdding = PresentationAdditionType.Add;
	
	// Fill report parameters
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qPeriodFrom", BegOfDay(PeriodFrom));
	ReportBuilder.Parameters.Insert("qPeriodTo", EndOfDay(PeriodTo));
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qIsEmptyRoom", Not ValueIsFilled(Room));
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qIsEmptyRoomType", Not ValueIsFilled(RoomType));
	ReportBuilder.Parameters.Insert("qCustomer", Customer);
	ReportBuilder.Parameters.Insert("qIsEmptyCustomer", Not ValueIsFilled(Customer));
	ReportBuilder.Parameters.Insert("qContract", Contract);
	ReportBuilder.Parameters.Insert("qIsEmptyContract", Not ValueIsFilled(Contract));
	ReportBuilder.Parameters.Insert("qCheckIn", NStr("en='Arrival totals'; ru='1. Заезд'; de='1. Anreise'"));
	ReportBuilder.Parameters.Insert("qCheckOut", NStr("en='Depart. totals'; ru='2. Выезд'; de='2. Abreise'"));
	ReportBuilder.Parameters.Insert("qOccupied", NStr("en='Occup. totals'; ru='3. Занято'; de='3. Besetzt'"));
	ReportBuilder.Parameters.Insert("qEmptyMealBoardTerm", Catalogs.ServicePackages.EmptyRef());
	ReportBuilder.Parameters.Insert("qEmptyWindowView", Catalogs.RoomProperties.EmptyRef());
	
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
	"SELECT TOP 1
	|	&qEmptyMealBoardTerm AS MealBoardTerm
	|INTO EmptyMealBoardTerms
	|FROM
	|	Catalog.ServicePackages AS EmptyMealBoardTerms
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	&qEmptyWindowView AS WindowView
	|INTO EmptyWindowViews
	|FROM
	|	Catalog.RoomProperties AS EmptyWindowViews
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllMealBoardTerms.MealBoardTerm AS MealBoardTerm
	|INTO AllMealBoardTerms
	|FROM
	|	(SELECT
	|		MealBoardTerms.Ref AS MealBoardTerm
	|	FROM
	|		Catalog.ServicePackages AS MealBoardTerms
	|	WHERE
	|		MealBoardTerms.IsMealBoardTerm
	|		AND NOT MealBoardTerms.IsFolder
	|		AND NOT MealBoardTerms.DeletionMark
	|		AND (MealBoardTerms.Hotel = &qHotel
	|				OR MealBoardTerms.Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		EmptyMealBoardTerms.MealBoardTerm
	|	FROM
	|		EmptyMealBoardTerms AS EmptyMealBoardTerms) AS AllMealBoardTerms
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllWindowViews.WindowView AS WindowView
	|INTO AllWindowViews
	|FROM
	|	(SELECT
	|		WindowViews.Ref AS WindowView
	|	FROM
	|		Catalog.RoomProperties AS WindowViews
	|	WHERE
	|		WindowViews.IsView
	|		AND NOT WindowViews.IsFolder
	|		AND NOT WindowViews.DeletionMark
	|		AND (WindowViews.Hotel = &qHotel
	|				OR WindowViews.Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		EmptyWindowViews.WindowView
	|	FROM
	|		EmptyWindowViews AS EmptyWindowViews) AS AllWindowViews
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BEGINOFPERIOD(RoomInventory.Period, DAY) AS DayStart,
	|	ENDOFPERIOD(RoomInventory.Period, DAY) AS DayEnd,
	|	RoomInventory.Hotel AS Hotel,
	|	RoomInventory.RoomType AS RoomType,
	|	ISNULL(AllWindowViews.WindowView, VALUE(Catalog.RoomProperties.EmptyRef)) AS WindowView,
	|	ISNULL(AllMealBoardTerms.MealBoardTerm, VALUE(Catalog.ServicePackages.EmptyRef)) AS MealBoardTerm,
	|	0 AS NumberOfRooms,
	|	0 AS NumberOfBeds,
	|	0 AS NumberOfPersons,
	|	0 AS NumberOfAdults,
	|	0 AS NumberOfTeenagers,
	|	0 AS NumberOfChildren,
	|	0 AS NumberOfInfants,
	|	ISNULL(RoomInventory.CounterClosingBalance, 0) AS CounterClosingBalance
	|INTO PeriodsByRoomTypes
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			RegisterRecordsAndPeriodBoundaries,
	|			Hotel IN HIERARCHY (&qHotel)
	|				AND (Room IN HIERARCHY (&qRoom)
	|					OR &qIsEmptyRoom)
	|				AND (RoomType IN HIERARCHY (&qRoomType)
	|					OR &qIsEmptyRoomType)
	|				AND NOT RoomType.DeletionMark) AS RoomInventory
	|		LEFT JOIN AllWindowViews AS AllWindowViews
	|		ON (TRUE)
	|		LEFT JOIN AllMealBoardTerms AS AllMealBoardTerms
	|		ON (TRUE)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AvailabilityList.AccountingDate AS AccountingDate,
	|	AvailabilityList.Hotel AS Hotel,
	|	AvailabilityList.RoomType AS RoomType,
	|	AvailabilityList.WindowView AS WindowView,
	|	AvailabilityList.MealBoardTerm AS MealBoardTerm,
	|	AvailabilityList.RecordType AS RecordType,
	|	AvailabilityList.NumberOfRooms AS NumberOfRooms,
	|	AvailabilityList.NumberOfBeds AS NumberOfBeds,
	|	AvailabilityList.NumberOfPersons AS NumberOfPersons,
	|	AvailabilityList.NumberOfAdults AS NumberOfAdults,
	|	AvailabilityList.NumberOfTeenagers AS NumberOfTeenagers,
	|	AvailabilityList.NumberOfChildren AS NumberOfChildren,
	|	AvailabilityList.NumberOfInfants AS NumberOfInfants
	|{SELECT
	|	AccountingDate,
	|	Hotel.*,
	|	RoomType.*,
	|	WindowView.*,
	|	MealBoardTerm.*,
	|	RecordType,
	|	NumberOfRooms,
	|	NumberOfBeds,
	|	NumberOfPersons,
	|	NumberOfAdults,
	|	NumberOfTeenagers,
	|	NumberOfChildren,
	|	NumberOfInfants,
	|	(BEGINOFPERIOD(AvailabilityList.AccountingDate, WEEK)) AS AccountingWeek,
	|	(BEGINOFPERIOD(AvailabilityList.AccountingDate, MONTH)) AS AccountingMonth,
	|	(BEGINOFPERIOD(AvailabilityList.AccountingDate, QUARTER)) AS AccountingQuarter,
	|	(YEAR(AvailabilityList.AccountingDate)) AS AccountingYear}
	|FROM
	|	(SELECT
	|		AvailabilityListDetails.AccountingDate AS AccountingDate,
	|		AvailabilityListDetails.Hotel AS Hotel,
	|		AvailabilityListDetails.RoomType AS RoomType,
	|		AvailabilityListDetails.WindowView AS WindowView,
	|		AvailabilityListDetails.RecordType AS RecordType,
	|		AvailabilityListDetails.MealBoardTerm AS MealBoardTerm,
	|		SUM(AvailabilityListDetails.NumberOfRooms) AS NumberOfRooms,
	|		SUM(AvailabilityListDetails.NumberOfBeds) AS NumberOfBeds,
	|		SUM(AvailabilityListDetails.NumberOfAdults) AS NumberOfAdults,
	|		SUM(AvailabilityListDetails.NumberOfTeenagers) AS NumberOfTeenagers,
	|		SUM(AvailabilityListDetails.NumberOfChildren) AS NumberOfChildren,
	|		SUM(AvailabilityListDetails.NumberOfInfants) AS NumberOfInfants,
	|		SUM(AvailabilityListDetails.NumberOfAdults + AvailabilityListDetails.NumberOfTeenagers + AvailabilityListDetails.NumberOfChildren + AvailabilityListDetails.NumberOfInfants) AS NumberOfPersons
	|	FROM
	|		(SELECT
	|			CheckInsMarkup.DayStart AS AccountingDate,
	|			CheckInsMarkup.Hotel AS Hotel,
	|			CheckInsMarkup.RoomType AS RoomType,
	|			CheckInsMarkup.RoomType.WindowView AS WindowView,
	|			&qCheckIn AS RecordType,
	|			CASE
	|				WHEN ISNULL(CheckedInReservations.Recorder.ServicePackage.IsMealBoardTerm, FALSE)
	|					THEN CheckedInReservations.Recorder.ServicePackage
	|				ELSE VALUE(Catalog.ServicePackages.EmptyRef)
	|			END AS MealBoardTerm,
	|			CheckInsMarkup.NumberOfRooms + ISNULL(CheckedInReservations.RoomsCheckedIn, 0) + ISNULL(CheckedInReservations.ExpectedRoomsCheckedIn, 0) AS NumberOfRooms,
	|			CheckInsMarkup.NumberOfBeds + ISNULL(CheckedInReservations.BedsCheckedIn, 0) + ISNULL(CheckedInReservations.ExpectedBedsCheckedIn, 0) AS NumberOfBeds,
	|			CheckInsMarkup.NumberOfAdults + ISNULL(CheckedInReservations.Recorder.NumberOfAdults, 0) AS NumberOfAdults,
	|			CheckInsMarkup.NumberOfTeenagers + ISNULL(CheckedInReservations.Recorder.NumberOfTeenagers, 0) AS NumberOfTeenagers,
	|			CheckInsMarkup.NumberOfChildren + ISNULL(CheckedInReservations.Recorder.NumberOfChildren, 0) AS NumberOfChildren,
	|			CheckInsMarkup.NumberOfInfants + ISNULL(CheckedInReservations.Recorder.NumberOfInfants, 0) AS NumberOfInfants
	|		FROM
	|			PeriodsByRoomTypes AS CheckInsMarkup
	|				LEFT JOIN AccumulationRegister.RoomInventory AS CheckedInReservations
	|				ON (CheckedInReservations.PeriodFrom >= CheckInsMarkup.DayStart)
	|					AND (CheckedInReservations.PeriodFrom <= CheckInsMarkup.DayEnd)
	|					AND (CheckedInReservations.Hotel = CheckInsMarkup.Hotel)
	|					AND (CheckedInReservations.RoomType = CheckInsMarkup.RoomType)
	|					AND (CheckedInReservations.Recorder.ServicePackage = CheckInsMarkup.MealBoardTerm)
	|					AND (CheckedInReservations.RoomType.WindowView = CheckInsMarkup.WindowView)
	|					AND (CheckedInReservations.BedsCheckedIn <> 0
	|						OR CheckedInReservations.ExpectedBedsCheckedIn <> 0)
	|					AND (CheckedInReservations.Recorder REFS Document.Reservation
	|						OR CheckedInReservations.Recorder REFS Document.Accommodation)
	|					AND (CheckedInReservations.RecordType = VALUE(AccumulationRecordType.Expense))
	|					AND (&qIsEmptyCustomer
	|						OR NOT &qIsEmptyCustomer
	|							AND CheckedInReservations.Customer IN HIERARCHY (&qCustomer))
	|					AND (&qIsEmptyContract
	|						OR NOT &qIsEmptyContract
	|							AND CheckedInReservations.Contract = &qContract)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			CheckOutsMarkup.DayStart,
	|			CheckOutsMarkup.Hotel,
	|			CheckOutsMarkup.RoomType,
	|			CheckOutsMarkup.RoomType.WindowView,
	|			&qCheckOut,
	|			CASE
	|				WHEN ISNULL(CheckedOutReservations.Recorder.ServicePackage.IsMealBoardTerm, FALSE)
	|					THEN CheckedOutReservations.Recorder.ServicePackage
	|				ELSE VALUE(Catalog.ServicePackages.EmptyRef)
	|			END,
	|			CheckOutsMarkup.NumberOfRooms + ISNULL(CheckedOutReservations.RoomsCheckedOut, 0) + ISNULL(CheckedOutReservations.ExpectedRoomsCheckedOut, 0),
	|			CheckOutsMarkup.NumberOfBeds + ISNULL(CheckedOutReservations.BedsCheckedOut, 0) + ISNULL(CheckedOutReservations.ExpectedBedsCheckedOut, 0),
	|			CheckOutsMarkup.NumberOfAdults + ISNULL(CheckedOutReservations.Recorder.NumberOfAdults, 0),
	|			CheckOutsMarkup.NumberOfTeenagers + ISNULL(CheckedOutReservations.Recorder.NumberOfTeenagers, 0),
	|			CheckOutsMarkup.NumberOfChildren + ISNULL(CheckedOutReservations.Recorder.NumberOfChildren, 0),
	|			CheckOutsMarkup.NumberOfInfants + ISNULL(CheckedOutReservations.Recorder.NumberOfInfants, 0)
	|		FROM
	|			PeriodsByRoomTypes AS CheckOutsMarkup
	|				LEFT JOIN AccumulationRegister.RoomInventory AS CheckedOutReservations
	|				ON (CheckedOutReservations.PeriodTo >= CheckOutsMarkup.DayStart)
	|					AND (CheckedOutReservations.PeriodTo <= CheckOutsMarkup.DayEnd)
	|					AND (CheckedOutReservations.Hotel = CheckOutsMarkup.Hotel)
	|					AND (CheckedOutReservations.RoomType = CheckOutsMarkup.RoomType)
	|					AND (CheckedOutReservations.Recorder.ServicePackage = CheckOutsMarkup.MealBoardTerm)
	|					AND (CheckedOutReservations.RoomType.WindowView = CheckOutsMarkup.WindowView)
	|					AND (CheckedOutReservations.BedsCheckedOut <> 0
	|						OR CheckedOutReservations.ExpectedBedsCheckedOut <> 0)
	|					AND (CheckedOutReservations.Recorder REFS Document.Reservation
	|						OR CheckedOutReservations.Recorder REFS Document.Accommodation)
	|					AND (CheckedOutReservations.RecordType = VALUE(AccumulationRecordType.Receipt))
	|					AND (&qIsEmptyCustomer
	|						OR NOT &qIsEmptyCustomer
	|							AND CheckedOutReservations.Customer IN HIERARCHY (&qCustomer))
	|					AND (&qIsEmptyContract
	|						OR NOT &qIsEmptyContract
	|							AND CheckedOutReservations.Contract = &qContract)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			InhouseMarkup.AccountingDate,
	|			InhouseMarkup.Hotel,
	|			InhouseMarkup.RoomType,
	|			InhouseMarkup.WindowView,
	|			&qOccupied,
	|			InhouseMarkup.MealBoardTerm,
	|			SUM(InhouseMarkup.RoomsOccupied),
	|			SUM(InhouseMarkup.BedsOccupied),
	|			SUM(InhouseMarkup.AdultsOccupied),
	|			SUM(InhouseMarkup.TeenagersOccupied),
	|			SUM(InhouseMarkup.ChildrenOccupied),
	|			SUM(InhouseMarkup.InfantsOccupied)
	|		FROM
	|			(SELECT
	|				InhouseMarkupDetails.DayStart AS AccountingDate,
	|				InhouseMarkupDetails.Hotel AS Hotel,
	|				InhouseMarkupDetails.RoomType AS RoomType,
	|				InhouseMarkupDetails.RoomType.WindowView AS WindowView,
	|				CASE
	|					WHEN ISNULL(InhouseReservations.Recorder.ServicePackage.IsMealBoardTerm, FALSE)
	|						THEN InhouseReservations.Recorder.ServicePackage
	|					ELSE VALUE(Catalog.ServicePackages.EmptyRef)
	|				END AS MealBoardTerm,
	|				InhouseReservations.Recorder AS Recorder,
	|				MAX(InhouseMarkupDetails.NumberOfRooms + ISNULL(InhouseReservations.RoomsReserved, 0) + ISNULL(InhouseReservations.InHouseRooms, 0)) AS RoomsOccupied,
	|				MAX(InhouseMarkupDetails.NumberOfBeds + ISNULL(InhouseReservations.BedsReserved, 0) + ISNULL(InhouseReservations.InHouseBeds, 0)) AS BedsOccupied,
	|				MAX(InhouseMarkupDetails.NumberOfAdults + ISNULL(InhouseReservations.Recorder.NumberOfAdults, 0)) AS AdultsOccupied,
	|				MAX(InhouseMarkupDetails.NumberOfTeenagers + ISNULL(InhouseReservations.Recorder.NumberOfTeenagers, 0)) AS TeenagersOccupied,
	|				MAX(InhouseMarkupDetails.NumberOfChildren + ISNULL(InhouseReservations.Recorder.NumberOfChildren, 0)) AS ChildrenOccupied,
	|				MAX(InhouseMarkupDetails.NumberOfInfants + ISNULL(InhouseReservations.Recorder.NumberOfInfants, 0)) AS InfantsOccupied
	|			FROM
	|				PeriodsByRoomTypes AS InhouseMarkupDetails
	|					LEFT JOIN AccumulationRegister.RoomInventory AS InhouseReservations
	|					ON (InhouseReservations.PeriodFrom < InhouseMarkupDetails.DayEnd)
	|						AND (InhouseReservations.PeriodTo > InhouseMarkupDetails.DayStart)
	|						AND (InhouseReservations.PeriodTo > InhouseMarkupDetails.DayEnd)
	|						AND (InhouseReservations.Recorder.CheckOutDate > InhouseMarkupDetails.DayEnd)
	|						AND (InhouseReservations.Hotel = InhouseMarkupDetails.Hotel)
	|						AND (InhouseReservations.RoomType = InhouseMarkupDetails.RoomType)
	|						AND (InhouseReservations.Recorder.ServicePackage = InhouseMarkupDetails.MealBoardTerm)
	|						AND (InhouseReservations.RoomType.WindowView = InhouseMarkupDetails.WindowView)
	|						AND (InhouseReservations.BedsReserved <> 0
	|							OR InhouseReservations.InHouseBeds <> 0)
	|						AND (InhouseReservations.Recorder REFS Document.Reservation
	|							OR InhouseReservations.Recorder REFS Document.Accommodation)
	|						AND (InhouseReservations.RecordType = VALUE(AccumulationRecordType.Expense))
	|						AND (&qIsEmptyCustomer
	|							OR NOT &qIsEmptyCustomer
	|								AND InhouseReservations.Customer IN HIERARCHY (&qCustomer))
	|						AND (&qIsEmptyContract
	|							OR NOT &qIsEmptyContract
	|								AND InhouseReservations.Contract = &qContract)
	|			
	|			GROUP BY
	|				InhouseMarkupDetails.DayStart,
	|				InhouseMarkupDetails.Hotel,
	|				InhouseMarkupDetails.RoomType,
	|				InhouseMarkupDetails.RoomType.WindowView,
	|				CASE
	|					WHEN ISNULL(InhouseReservations.Recorder.ServicePackage.IsMealBoardTerm, FALSE)
	|						THEN InhouseReservations.Recorder.ServicePackage
	|					ELSE VALUE(Catalog.ServicePackages.EmptyRef)
	|				END,
	|				InhouseReservations.Recorder) AS InhouseMarkup
	|		
	|		GROUP BY
	|			InhouseMarkup.AccountingDate,
	|			InhouseMarkup.Hotel,
	|			InhouseMarkup.RoomType,
	|			InhouseMarkup.WindowView,
	|			InhouseMarkup.MealBoardTerm) AS AvailabilityListDetails
	|	
	|	GROUP BY
	|		AvailabilityListDetails.AccountingDate,
	|		AvailabilityListDetails.Hotel,
	|		AvailabilityListDetails.RoomType,
	|		AvailabilityListDetails.WindowView,
	|		AvailabilityListDetails.RecordType,
	|		AvailabilityListDetails.MealBoardTerm) AS AvailabilityList
	|{WHERE
	|	AvailabilityList.AccountingDate,
	|	AvailabilityList.Hotel.*,
	|	AvailabilityList.RoomType.*,
	|	AvailabilityList.WindowView.*,
	|	AvailabilityList.MealBoardTerm.*,
	|	AvailabilityList.RecordType}
	|
	|ORDER BY
	|	AccountingDate,
	|	MealBoardTerm
	|{ORDER BY
	|	AccountingDate,
	|	Hotel.*,
	|	RoomType.*,
	|	MealBoardTerm.*,
	|	WindowView.*,
	|	RecordType,
	|	(BEGINOFPERIOD(AvailabilityList.AccountingDate, WEEK)) AS AccountingWeek,
	|	(BEGINOFPERIOD(AvailabilityList.AccountingDate, MONTH)) AS AccountingMonth,
	|	(BEGINOFPERIOD(AvailabilityList.AccountingDate, QUARTER)) AS AccountingQuarter,
	|	(YEAR(AvailabilityList.AccountingDate)) AS AccountingYear}
	|TOTALS
	|	SUM(NumberOfRooms),
	|	SUM(NumberOfBeds),
	|	SUM(NumberOfPersons),
	|	SUM(NumberOfAdults),
	|	SUM(NumberOfTeenagers),
	|	SUM(NumberOfChildren),
	|	SUM(NumberOfInfants)
	|BY
	|	OVERALL,
	|	AccountingDate
	|{TOTALS BY
	|	Hotel.*,
	|	RoomType.*,
	|	WindowView.*,
	|	MealBoardTerm.*,
	|	RecordType,
	|	AccountingDate,
	|	(BEGINOFPERIOD(AvailabilityList.AccountingDate, WEEK)) AS AccountingWeek,
	|	(BEGINOFPERIOD(AvailabilityList.AccountingDate, MONTH)) AS AccountingMonth,
	|	(BEGINOFPERIOD(AvailabilityList.AccountingDate, QUARTER)) AS AccountingQuarter,
	|	(YEAR(AvailabilityList.AccountingDate)) AS AccountingYear}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Availability list';RU='Список доступности';de='Verfügbarkeit Liste'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
Function pmIsResource(pName) Export
	If pName = "NumberOfRooms" Or
	   pName = "NumberOfBeds" Or
	   pName = "NumberOfPersons" Or
	   pName = "NumberOfAdults" Or
	   pName = "NumberOfTeenagers" Or
	   pName = "NumberOfChildren" Or
	   pName = "NumberOfInfants" Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // pmIsResource

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
