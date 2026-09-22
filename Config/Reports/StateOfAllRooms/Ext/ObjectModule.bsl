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
	If Not ValueIsFilled(PeriodTo) Then
		PeriodTo = EndOfDay(CurrentSessionDate()); // End of today
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetReportParametersPresentation() Export
	vParamPresentation = "";
	If Not ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("en='Report period is not set';ru='Период отчета не установлен';de='Berichtszeitraum nicht festgelegt'") + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("ru = 'На дату и время '; en = 'Period '; de = 'Periode '") + 
		                     Format(PeriodTo, "DF='dd.MM.yyyy HH:mm:ss'") + 
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
	If DoNotShowReservations Then
		vParamPresentation = vParamPresentation + NStr("en='Without reservations';ru='Без брони';de='Ohne Buchung'") + 
							 ";" + Chars.LF;
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
// Runs report and returns if report form should be shown
// -----------------------------------------------------------------------------
Procedure pmGenerate(pSpreadsheet) Export
	Var vTemplateAttributes;
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
	
	// Initialize report builder query generator attributes
	ReportBuilder.PresentationAdding = PresentationAdditionType.Add;
	
	// Fill report parameters
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qEmptyDate", '00010101');
	ReportBuilder.Parameters.Insert("qExpense", AccumulationRecordType.Expense);
	ReportBuilder.Parameters.Insert("qIsEmptyHotel", Not ValueIsFilled(Hotel));
	ReportBuilder.Parameters.Insert("qIsEmptyRoomType", Not ValueIsFilled(RoomType));
	ReportBuilder.Parameters.Insert("qIsEmptyRoom", Not ValueIsFilled(Room));
	ReportBuilder.Parameters.Insert("qDoNotShowReservations", DoNotShowReservations);

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
		
	// Apply number of pages to be printed on the one paper sheet
	cmApplyReportMultiplePages(ThisObject, pSpreadsheet)
EndProcedure // pmGenerate

// -----------------------------------------------------------------------------
Procedure pmInitializeReportBuilder() Export
	ReportBuilder = New ReportBuilder();
	
	// Initialize default query text
	QueryText = 
	"SELECT
	|	Accommodations.Hotel AS Hotel,
	|	Accommodations.Room AS Room,
	|	Accommodations.RoomType AS RoomType,
	|	Accommodations.Document AS Document,
	|	Accommodations.ParentDoc AS ParentDoc,
	|	Accommodations.Guest AS Guest,
	|	Accommodations.CheckInDate AS CheckInDate,
	|	Accommodations.CheckOutDate AS CheckOutDate,
	|	Accommodations.AccommodationType AS AccommodationType,
	|	Accommodations.Status AS Status,
	|	Accommodations.GuestGroup AS GuestGroup,
	|	Accommodations.Agent AS Agent,
	|	Accommodations.Customer AS Customer,
	|	Accommodations.Contract AS Contract,
	|	Accommodations.ContactPerson AS ContactPerson,
	|	Accommodations.PlannedPaymentMethod AS PlannedPaymentMethod,
	|	Accommodations.Remarks AS Remarks,
	|	Accommodations.IsAccommodation AS IsAccommodation,
	|	Accommodations.IsReservation AS IsReservation,
	|	Accommodations.IsBlocking AS IsBlocking,
	|	1 AS RoomsCount
	|{SELECT
	|	Hotel.*,
	|	Room.*,
	|	RoomType.*,
	|	Status.*,
	|	Guest.*,
	|	CheckInDate,
	|	CheckOutDate,
	|	AccommodationType.*,
	|	PlannedPaymentMethod.*,
	|	Agent.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	ContactPerson,
	|	Remarks,
	|	Document.*,
	|	ParentDoc.*,
	|	IsAccommodation,
	|	IsReservation,
	|	IsBlocking,
	|	RoomsCount}
	|FROM
	|	(SELECT
	|		RoomInventoryBalance.Hotel AS Hotel,
	|		RoomInventoryBalance.Room AS Room,
	|		RoomInventoryBalance.RoomType AS RoomType,
	|		RoomInventoryBalance.TotalRoomsBalance AS TotalRoomsBalance,
	|		RoomInventoryBalance.TotalBedsBalance AS TotalBedsBalance,
	|		Documents.Document AS Document,
	|		Documents.Status AS Status,
	|		Documents.ParentDoc AS ParentDoc,
	|		Documents.Guest AS Guest,
	|		Documents.CheckInDate AS CheckInDate,
	|		Documents.CheckOutDate AS CheckOutDate,
	|		Documents.AccommodationType AS AccommodationType,
	|		Documents.Agent AS Agent,
	|		Documents.Customer AS Customer,
	|		Documents.Contract AS Contract,
	|		Documents.GuestGroup AS GuestGroup,
	|		Documents.PlannedPaymentMethod AS PlannedPaymentMethod,
	|		Documents.ContactPerson AS ContactPerson,
	|		Documents.Remarks AS Remarks,
	|		Documents.IsAccommodation AS IsAccommodation,
	|		Documents.IsReservation AS IsReservation,
	|		Documents.IsBlocking AS IsBlocking
	|	FROM
	|		AccumulationRegister.RoomInventory.Balance(
	|				&qPeriodTo,
	|				(Hotel IN HIERARCHY (&qHotel)
	|					OR &qIsEmptyHotel)
	|					AND (RoomType IN HIERARCHY (&qRoomType)
	|						OR &qIsEmptyRoomType)
	|					AND (Room IN HIERARCHY (&qRoom)
	|						OR &qIsEmptyRoom)) AS RoomInventoryBalance
	|			LEFT JOIN (SELECT
	|				AccommodationDocs.Recorder AS Document,
	|				AccommodationDocs.Room AS Room,
	|				AccommodationDocs.AccommodationStatus AS Status,
	|				AccommodationDocs.ParentDoc AS ParentDoc,
	|				AccommodationDocs.Guest AS Guest,
	|				AccommodationDocs.PeriodFrom AS CheckInDate,
	|				AccommodationDocs.PeriodTo AS CheckOutDate,
	|				AccommodationDocs.AccommodationType AS AccommodationType,
	|				AccommodationDocs.Agent AS Agent,
	|				AccommodationDocs.Customer AS Customer,
	|				AccommodationDocs.Contract AS Contract,
	|				AccommodationDocs.GuestGroup AS GuestGroup,
	|				AccommodationDocs.PlannedPaymentMethod AS PlannedPaymentMethod,
	|				AccommodationDocs.ContactPerson AS ContactPerson,
	|				AccommodationDocs.Remarks AS Remarks,
	|				TRUE AS IsAccommodation,
	|				FALSE AS IsReservation,
	|				FALSE AS IsBlocking
	|			FROM
	|				AccumulationRegister.RoomInventory AS AccommodationDocs
	|			WHERE
	|				AccommodationDocs.IsAccommodation = TRUE
	|				AND AccommodationDocs.RecordType = VALUE(AccumulationRecordType.Expense)
	|				AND AccommodationDocs.IsInHouse = TRUE
	|				AND AccommodationDocs.PeriodFrom <= &qPeriodTo
	|				AND AccommodationDocs.PeriodTo > &qPeriodTo
	|				AND AccommodationDocs.Period = AccommodationDocs.PeriodFrom
	|			
	|			UNION ALL
	|			
	|			SELECT
	|				ReservationDocs.Recorder,
	|				ReservationDocs.Room,
	|				ReservationDocs.ReservationStatus,
	|				ReservationDocs.ParentDoc,
	|				ReservationDocs.Guest,
	|				ReservationDocs.PeriodFrom,
	|				ReservationDocs.PeriodTo,
	|				ReservationDocs.AccommodationType,
	|				ReservationDocs.Agent,
	|				ReservationDocs.Customer,
	|				ReservationDocs.Contract,
	|				ReservationDocs.GuestGroup,
	|				ReservationDocs.PlannedPaymentMethod,
	|				ReservationDocs.ContactPerson,
	|				ReservationDocs.Remarks,
	|				FALSE,
	|				TRUE,
	|				FALSE
	|			FROM
	|				AccumulationRegister.RoomInventory AS ReservationDocs
	|			WHERE
	|				ReservationDocs.IsReservation = TRUE
	|				AND ReservationDocs.RecordType = VALUE(AccumulationRecordType.Expense)
	|				AND ReservationDocs.Period = ReservationDocs.PeriodFrom
	|				AND NOT &qDoNotShowReservations
	|			
	|			UNION ALL
	|			
	|			SELECT
	|				RoomBlocks.Recorder,
	|				RoomBlocks.Room,
	|				RoomBlocks.RoomBlockType,
	|				NULL,
	|				NULL,
	|				RoomBlocks.CheckInDate,
	|				RoomBlocks.CheckOutDate,
	|				NULL,
	|				NULL,
	|				NULL,
	|				NULL,
	|				NULL,
	|				NULL,
	|				NULL,
	|				RoomBlocks.Remarks,
	|				FALSE,
	|				FALSE,
	|				TRUE
	|			FROM
	|				AccumulationRegister.RoomInventory AS RoomBlocks
	|			WHERE
	|				RoomBlocks.RecordType = &qExpense
	|				AND RoomBlocks.IsBlocking = TRUE
	|				AND RoomBlocks.CheckInDate <= &qPeriodTo
	|				AND (RoomBlocks.CheckOutDate > &qPeriodTo
	|						OR RoomBlocks.CheckOutDate = &qEmptyDate)) AS Documents
	|			ON RoomInventoryBalance.Room = Documents.Room
	|				AND (RoomInventoryBalance.TotalRoomsBalance > 0)) AS Accommodations
	|{WHERE
	|	Accommodations.Hotel.*,
	|	Accommodations.Room.*,
	|	Accommodations.RoomType.*,
	|	Accommodations.Document.*,
	|	Accommodations.ParentDoc.*,
	|	Accommodations.Guest.*,
	|	Accommodations.CheckInDate,
	|	Accommodations.CheckOutDate,
	|	Accommodations.AccommodationType.*,
	|	Accommodations.Status.*,
	|	Accommodations.Agent.*,
	|	Accommodations.Customer.*,
	|	Accommodations.Contract.*,
	|	Accommodations.GuestGroup.*,
	|	Accommodations.PlannedPaymentMethod.*,
	|	Accommodations.ContactPerson,
	|	Accommodations.Remarks,
	|	Accommodations.IsAccommodation,
	|	Accommodations.IsReservation,
	|	Accommodations.IsBlocking}
	|
	|ORDER BY
	|	Hotel,
	|	Room,
	|	CheckInDate,
	|	Guest
	|{ORDER BY
	|	Hotel.*,
	|	Room.*,
	|	CheckInDate,
	|	Guest.*,
	|	RoomType.*,
	|	Document.*,
	|	ParentDoc.*,
	|	CheckOutDate,
	|	AccommodationType.*,
	|	Status.*,
	|	Agent.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	PlannedPaymentMethod.*,
	|	ContactPerson,
	|	Remarks}
	|TOTALS
	|	SUM(RoomsCount)
	|BY
	|	OVERALL,
	|	Hotel,
	|	Room
	|{TOTALS BY
	|	Hotel,
	|	Room.*,
	|	Agent.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	RoomType.*,
	|	Status,
	|	PlannedPaymentMethod}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("en='State of all rooms';ru='Шахматка';de='Schachbretttabelle'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
