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
	If Not ValueIsFilled(Period) Then
		Period = BegOfDay(CurrentSessionDate()); // For today
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetReportParametersPresentation() Export
	vParamPresentation = "";
	If ValueIsFilled(Period) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период на '; en = 'Period on '; de = 'Periode '") + 
		                     Format(Period, "DF=dd.MM.yyyy") + 
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
	ReportBuilder.Parameters.Insert("qPeriodFrom", BegOfDay(Period));
	ReportBuilder.Parameters.Insert("qPrevPeriodFrom", BegOfDay(Period) - 24*3600);
	ReportBuilder.Parameters.Insert("qPeriodTo", EndOfDay(Period));
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qIsLeavingFromHotel", NStr("en='Leaving hotel'; ru='Покидают отель'; de='Das Hotel verlassen'"));
	ReportBuilder.Parameters.Insert("qIsBookedOut", NStr("en='Is booked out'; ru='Вне отеля'; de='Sind booked out'"));
	ReportBuilder.Parameters.Insert("qIsReturningToHotel", NStr("en='Is returning to hotel'; ru='Возвращаются в отель'; de='Rückkehr zum Hotel'"));
	ReportBuilder.Parameters.Insert("qEmptyString", "");
	ReportBuilder.Parameters.Insert("qEmptyCurrency", Catalogs.Currencies.EmptyRef());

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
	|	BookedOutGuests.Status AS Status,
	|	BookedOutGuests.Hotel AS Hotel,
	|	BookedOutGuests.Room AS Room,
	|	BookedOutGuests.RoomType AS RoomType,
	|	BookedOutGuests.Customer AS Customer,
	|	BookedOutGuests.GuestGroup AS GuestGroup,
	|	BookedOutGuests.Guest AS Guest,
	|	BookedOutGuests.CheckInDate AS CheckInDate,
	|	BookedOutGuests.Duration AS Duration,
	|	BookedOutGuests.CheckOutDate AS CheckOutDate,
	|	BookedOutGuests.AccommodationType AS AccommodationType,
	|	BookedOutGuests.RoomRate AS RoomRate,
	|	BookedOutGuests.ServicePackage AS ServicePackage,
	|	BookedOutGuests.Remarks AS Remarks,
	|	BookedOutGuests.BookOutHotel AS BookOutHotel,
	|	BookedOutGuests.BookOutPrice AS BookOutPrice,
	|	BookedOutGuests.BookOutPriceCurrency AS BookOutPriceCurrency,
	|	BookedOutGuests.NumberOfPersons AS NumberOfPersons,
	|	BookedOutGuests.NumberOfRooms AS NumberOfRooms
	|{SELECT
	|	Status AS Status,
	|	Hotel.* AS Hotel,
	|	Room.* AS Room,
	|	RoomType.* AS RoomType,
	|	Customer.* AS Customer,
	|	BookedOutGuests.Contract.* AS Contract,
	|	BookedOutGuests.Agent.* AS Agent,
	|	GuestGroup.* AS GuestGroup,
	|	Guest.* AS Guest,
	|	CheckInDate AS CheckInDate,
	|	Duration AS Duration,
	|	CheckOutDate AS CheckOutDate,
	|	AccommodationType.* AS AccommodationType,
	|	RoomRate.* AS RoomRate,
	|	ServicePackage.* AS ServicePackage,
	|	BookedOutGuests.Recorder.* AS Recorder,
	|	Remarks AS Remarks,
	|	BookOutHotel AS BookOutHotel,
	|	BookOutPrice AS BookOutPrice,
	|	BookOutPriceCurrency AS BookOutPriceCurrency,
	|	BookedOutGuests.Car AS Car,
	|	NumberOfPersons AS NumberOfPersons,
	|	NumberOfRooms AS NumberOfRooms}
	|FROM
	|	(SELECT
	|		AccommodationRoomRates.Ref AS Recorder,
	|		AccommodationRoomRates.Ref.Hotel AS Hotel,
	|		AccommodationRoomRates.Ref.Room AS Room,
	|		AccommodationRoomRates.Ref.RoomType AS RoomType,
	|		AccommodationRoomRates.Ref.CheckInDate AS CheckInDate,
	|		AccommodationRoomRates.Ref.Duration AS Duration,
	|		AccommodationRoomRates.Ref.CheckOutDate AS CheckOutDate,
	|		AccommodationRoomRates.Ref.Customer AS Customer,
	|		AccommodationRoomRates.Ref.Contract AS Contract,
	|		AccommodationRoomRates.Ref.Agent AS Agent,
	|		AccommodationRoomRates.Ref.ContactPerson AS ContactPerson,
	|		AccommodationRoomRates.Ref.GuestGroup AS GuestGroup,
	|		AccommodationRoomRates.Ref.Guest AS Guest,
	|		AccommodationRoomRates.Ref.AccommodationType AS AccommodationType,
	|		AccommodationRoomRates.Ref.RoomRate AS RoomRate,
	|		AccommodationRoomRates.Ref.ServicePackage AS ServicePackage,
	|		CAST(AccommodationRoomRates.Ref.Remarks AS STRING(1024)) AS Remarks,
	|		CAST(AccommodationRoomRates.Ref.Car AS STRING(1024)) AS Car,
	|		AccommodationRoomRates.Ref.NumberOfPersons AS NumberOfPersons,
	|		AccommodationRoomRates.Ref.NumberOfRooms AS NumberOfRooms,
	|		AccommodationRoomRates.BookOutHotel AS BookOutHotel,
	|		AccommodationRoomRates.BookOutPrice AS BookOutPrice,
	|		AccommodationRoomRates.BookOutPriceCurrency AS BookOutPriceCurrency,
	|		AccommodationRoomRates.Status AS Status
	|	FROM
	|		(SELECT
	|			AccommodationRoomRates1.Ref AS Ref,
	|			AccommodationRoomRates1.BookOutHotel AS BookOutHotel,
	|			AccommodationRoomRates1.BookOutPrice AS BookOutPrice,
	|			AccommodationRoomRates1.BookOutPriceCurrency AS BookOutPriceCurrency,
	|			CASE
	|				WHEN AccommodationRoomRates1.IsBookedOut
	|						AND NOT ISNULL(AccommodationRoomRatesPrevDate.IsBookedOut, FALSE)
	|					THEN &qIsLeavingFromHotel
	|				WHEN AccommodationRoomRates1.IsBookedOut
	|						AND ISNULL(AccommodationRoomRatesPrevDate.IsBookedOut, FALSE)
	|					THEN &qIsBookedOut
	|				WHEN NOT AccommodationRoomRates1.IsBookedOut
	|						AND ISNULL(AccommodationRoomRatesPrevDate.IsBookedOut, FALSE)
	|					THEN &qIsReturningToHotel
	|				ELSE NULL
	|			END AS Status
	|		FROM
	|			Document.Accommodation.RoomRates AS AccommodationRoomRates1
	|				LEFT JOIN Document.Accommodation.RoomRates AS AccommodationRoomRatesPrevDate
	|				ON (AccommodationRoomRatesPrevDate.Ref = AccommodationRoomRates1.Ref)
	|					AND (AccommodationRoomRatesPrevDate.AccountingDate = &qPrevPeriodFrom)
	|		WHERE
	|			AccommodationRoomRates1.Ref.Posted
	|			AND AccommodationRoomRates1.Ref.AccommodationStatus.IsActive
	|			AND AccommodationRoomRates1.Ref.Hotel IN HIERARCHY(&qHotel)
	|			AND AccommodationRoomRates1.Ref.Room IN HIERARCHY(&qRoom)
	|			AND AccommodationRoomRates1.Ref.RoomType IN HIERARCHY(&qRoomType)
	|			AND AccommodationRoomRates1.Ref.CheckInDate < &qPeriodTo
	|			AND AccommodationRoomRates1.Ref.CheckOutDate > &qPeriodFrom
	|			AND AccommodationRoomRates1.AccountingDate = &qPeriodFrom
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			AccommodationRoomRates2.Ref,
	|			&qEmptyString,
	|			0,
	|			&qEmptyCurrency,
	|			CASE
	|				WHEN AccommodationRoomRates2.IsBookedOut
	|						AND AccommodationRoomRatesNextDate.IsBookedOut IS NULL
	|					THEN &qIsReturningToHotel
	|				ELSE NULL
	|			END
	|		FROM
	|			Document.Accommodation.RoomRates AS AccommodationRoomRates2
	|				LEFT JOIN Document.Accommodation.RoomRates AS AccommodationRoomRatesNextDate
	|				ON (AccommodationRoomRatesNextDate.Ref = AccommodationRoomRates2.Ref)
	|					AND (AccommodationRoomRatesNextDate.AccountingDate = &qPeriodFrom)
	|		WHERE
	|			AccommodationRoomRates2.Ref.Posted
	|			AND AccommodationRoomRates2.Ref.AccommodationStatus.IsActive
	|			AND AccommodationRoomRates2.Ref.Hotel IN HIERARCHY(&qHotel)
	|			AND AccommodationRoomRates2.Ref.Room IN HIERARCHY(&qRoom)
	|			AND AccommodationRoomRates2.Ref.RoomType IN HIERARCHY(&qRoomType)
	|			AND AccommodationRoomRates2.Ref.CheckInDate < &qPeriodTo
	|			AND AccommodationRoomRates2.Ref.CheckOutDate > &qPeriodFrom
	|			AND AccommodationRoomRates2.AccountingDate = &qPrevPeriodFrom) AS AccommodationRoomRates
	|	
	|	GROUP BY
	|		AccommodationRoomRates.Ref,
	|		AccommodationRoomRates.Status,
	|		AccommodationRoomRates.Ref.Hotel,
	|		AccommodationRoomRates.Ref.Room,
	|		AccommodationRoomRates.Ref.RoomType,
	|		AccommodationRoomRates.Ref.CheckInDate,
	|		AccommodationRoomRates.Ref.Duration,
	|		AccommodationRoomRates.Ref.CheckOutDate,
	|		AccommodationRoomRates.Ref.Customer,
	|		AccommodationRoomRates.Ref.Contract,
	|		AccommodationRoomRates.Ref.Agent,
	|		AccommodationRoomRates.Ref.ContactPerson,
	|		AccommodationRoomRates.Ref.GuestGroup,
	|		AccommodationRoomRates.Ref.Guest,
	|		AccommodationRoomRates.Ref.AccommodationType,
	|		AccommodationRoomRates.Ref.RoomRate,
	|		AccommodationRoomRates.Ref.ServicePackage,
	|		AccommodationRoomRates.Ref.NumberOfPersons,
	|		AccommodationRoomRates.Ref.NumberOfRooms,
	|		AccommodationRoomRates.BookOutHotel,
	|		AccommodationRoomRates.BookOutPrice,
	|		AccommodationRoomRates.BookOutPriceCurrency,
	|		CAST(AccommodationRoomRates.Ref.Remarks AS STRING(1024)),
	|		CAST(AccommodationRoomRates.Ref.Car AS STRING(1024))) AS BookedOutGuests
	|WHERE
	|	NOT BookedOutGuests.Status IS NULL
	|{WHERE
	|	BookedOutGuests.Status AS Status,
	|	BookedOutGuests.Hotel.* AS Hotel,
	|	BookedOutGuests.Room.* AS Room,
	|	BookedOutGuests.RoomType.* AS RoomType,
	|	BookedOutGuests.Customer.* AS Customer,
	|	BookedOutGuests.Contract.* AS Contract,
	|	BookedOutGuests.Agent.* AS Agent,
	|	BookedOutGuests.GuestGroup.* AS GuestGroup,
	|	BookedOutGuests.Guest.* AS Guest,
	|	BookedOutGuests.CheckInDate AS CheckInDate,
	|	BookedOutGuests.Duration AS Duration,
	|	BookedOutGuests.CheckOutDate AS CheckOutDate,
	|	BookedOutGuests.AccommodationType.* AS AccommodationType,
	|	BookedOutGuests.RoomRate.* AS RoomRate,
	|	BookedOutGuests.ServicePackage.* AS ServicePackage,
	|	BookedOutGuests.Recorder.* AS Recorder,
	|	BookedOutGuests.Remarks AS Remarks,
	|	BookedOutGuests.Car AS Car,
	|	BookedOutGuests.BookOutHotel AS BookOutHotel,
	|	BookedOutGuests.BookOutPrice AS BookOutPrice,
	|	BookedOutGuests.BookOutPriceCurrency.* AS BookOutPriceCurrency,
	|	BookedOutGuests.NumberOfPersons AS NumberOfPersons,
	|	BookedOutGuests.NumberOfRooms AS NumberOfRooms}
	|
	|ORDER BY
	|	Hotel,
	|	Room,
	|	CheckInDate,
	|	AccommodationType
	|{ORDER BY
	|	Status AS Status,
	|	Hotel.* AS Hotel,
	|	Room.* AS Room,
	|	RoomType.* AS RoomType,
	|	Customer.* AS Customer,
	|	BookedOutGuests.Contract.* AS Contract,
	|	BookedOutGuests.Agent.* AS Agent,
	|	GuestGroup.* AS GuestGroup,
	|	Guest.* AS Guest,
	|	CheckInDate AS CheckInDate,
	|	Duration AS Duration,
	|	CheckOutDate AS CheckOutDate,
	|	AccommodationType.* AS AccommodationType,
	|	RoomRate.* AS RoomRate,
	|	ServicePackage.* AS ServicePackage,
	|	BookOutHotel AS BookOutHotel,
	|	BookOutPrice AS BookOutPrice,
	|	BookOutPriceCurrency.* AS BookOutPriceCurrency,
	|	BookedOutGuests.Recorder.* AS Recorder}
	|TOTALS
	|	SUM(BookOutPrice),
	|	SUM(NumberOfPersons),
	|	SUM(NumberOfRooms)
	|BY
	|	OVERALL,
	|	Status
	|{TOTALS BY
	|	Status AS Status,
	|	Hotel.* AS Hotel,
	|	Room.* AS Room,
	|	RoomType.* AS RoomType,
	|	Customer.* AS Customer,
	|	BookedOutGuests.Contract.* AS Contract,
	|	BookedOutGuests.Agent.* AS Agent,
	|	GuestGroup.* AS GuestGroup,
	|	Guest.* AS Guest,
	|	AccommodationType.* AS AccommodationType,
	|	RoomRate.* AS RoomRate,
	|	ServicePackage.* AS ServicePackage,
	|	BookOutHotel AS BookOutHotel,
	|	BookOutPriceCurrency.* AS BookOutPriceCurrency,
	|	BookedOutGuests.Recorder.* AS Recorder}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Booked out guests';RU='Гости вне отеля';de='Gäste sind booked out'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
