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
		PeriodTo = CurrentSessionDate(); // For now
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetReportParametersPresentation() Export
	vParamPresentation = "";
	If ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период '; en = 'Period '; de = 'Periode '") + 
		                     Format(PeriodTo, "DF='dd.MM.yyyy HH:mm:ss'") + 
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
	If ValueIsFilled(RoomQuota) Then
		If Not RoomQuota.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Allotment ';ru='Квота ';de='Allotment '") + 
			                     TrimAll(RoomQuota.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Allotments folder ';ru='Группа квот ';de='Allotmentgruppe '") + 
			                     TrimAll(RoomQuota.Description) + 
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
Procedure pmGenerate(pSpreadsheet) Export
	Var vTemplateAttributes;
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
	
	// Initialize report builder query generator attributes
	ReportBuilder.PresentationAdding = PresentationAdditionType.Add;
	
	// Fill report parameters
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qIsEmptyHotel", Not ValueIsFilled(Hotel));
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qIsEmptyRoom", Not ValueIsFilled(Room));
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qIsEmptyRoomType", Not ValueIsFilled(RoomType));
	ReportBuilder.Parameters.Insert("qRoomQuota", RoomQuota);
	ReportBuilder.Parameters.Insert("qIsEmptyRoomQuota", Not ValueIsFilled(RoomQuota));
	ReportBuilder.Parameters.Insert("qEmptyDate", '00010101');

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
	|	RoomInventoryMovements.Recorder AS Recorder,
	|	MAX(RoomInventoryMovements.Period) AS PeriodFrom
	|INTO EffectivePeriodsByRecorders
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventoryMovements
	|WHERE
	|	RoomInventoryMovements.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND RoomInventoryMovements.Period <= &qPeriodTo
	|	AND RoomInventoryMovements.PeriodFrom <= &qPeriodTo
	|	AND RoomInventoryMovements.PeriodTo > &qPeriodTo
	|	AND (RoomInventoryMovements.IsReservation
	|			OR RoomInventoryMovements.IsAccommodation)
	|	AND (RoomInventoryMovements.Hotel IN HIERARCHY (&qHotel)
	|			OR &qIsEmptyHotel)
	|	AND (RoomInventoryMovements.Room IN HIERARCHY (&qRoom)
	|			OR &qIsEmptyRoom)
	|	AND (RoomInventoryMovements.RoomQuota IN HIERARCHY (&qRoomQuota)
	|			OR &qIsEmptyRoomQuota)
	|	AND (RoomInventoryMovements.RoomType IN HIERARCHY (&qRoomType)
	|			OR &qIsEmptyRoomType)
	|
	|GROUP BY
	|	RoomInventoryMovements.Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventory.Hotel AS Hotel,
	|	RoomInventory.Status AS Status,
	|	RoomInventory.Room AS Room,
	|	RoomInventory.Customer AS Customer,
	|	RoomInventory.Contract AS Contract,
	|	RoomInventory.GuestGroup AS GuestGroup,
	|	RoomInventory.Guest AS Guest,
	|	RoomInventory.CheckInDate AS CheckInDate,
	|	RoomInventory.Duration AS Duration,
	|	RoomInventory.CheckOutDate AS CheckOutDate,
	|	RoomInventory.RoomType AS RoomType,
	|	RoomInventory.AccommodationType AS AccommodationType,
	|	RoomInventory.RoomQuota AS RoomQuota,
	|	RoomInventory.Remarks AS Remarks,
	|	RoomInventory.Recorder AS Recorder,
	|	RoomInventory.IsRoomInventory AS IsRoomInventory,
	|	RoomInventory.IsBlocking AS IsBlocking,
	|	RoomInventory.IsRoomQuota AS IsRoomQuota,
	|	RoomInventory.IsReservation AS IsReservation,
	|	RoomInventory.IsAccommodation AS IsAccommodation,
	|	RoomInventory.RoomsVacant AS RoomsVacant,
	|	RoomInventory.BedsVacant AS BedsVacant,
	|	RoomInventory.SpecialRoomsVacant AS SpecialRoomsVacant,
	|	RoomInventory.SpecialBedsVacant AS SpecialBedsVacant
	|{SELECT
	|	Hotel.*,
	|	Recorder.*,
	|	Status.*,
	|	Room.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	Guest.*,
	|	CheckInDate,
	|	Duration,
	|	CheckOutDate,
	|	RoomType.*,
	|	AccommodationType.*,
	|	RoomQuota.*,
	|	Remarks,
	|	IsRoomInventory,
	|	IsBlocking,
	|	IsRoomQuota,
	|	IsReservation,
	|	IsAccommodation,
	|	RoomsVacant,
	|	BedsVacant,
	|	SpecialRoomsVacant,
	|	SpecialBedsVacant}
	|FROM
	|	(SELECT DISTINCT
	|		RoomInventoryMovements.Hotel AS Hotel,
	|		RoomInventoryMovements.Status AS Status,
	|		RoomInventoryMovements.Room AS Room,
	|		RoomInventoryMovements.Customer AS Customer,
	|		RoomInventoryMovements.Contract AS Contract,
	|		RoomInventoryMovements.GuestGroup AS GuestGroup,
	|		RoomInventoryMovements.Guest AS Guest,
	|		RoomInventoryMovements.CheckInDate AS CheckInDate,
	|		RoomInventoryMovements.Duration AS Duration,
	|		RoomInventoryMovements.CheckOutDate AS CheckOutDate,
	|		RoomInventoryMovements.RoomType AS RoomType,
	|		RoomInventoryMovements.AccommodationType AS AccommodationType,
	|		RoomInventoryMovements.RoomQuota AS RoomQuota,
	|		CAST(RoomInventoryMovements.Remarks AS STRING(1024)) AS Remarks,
	|		RoomInventoryMovements.Recorder AS Recorder,
	|		RoomInventoryMovements.IsRoomInventory AS IsRoomInventory,
	|		RoomInventoryMovements.IsBlocking AS IsBlocking,
	|		RoomInventoryMovements.IsRoomQuota AS IsRoomQuota,
	|		RoomInventoryMovements.IsReservation AS IsReservation,
	|		RoomInventoryMovements.IsAccommodation AS IsAccommodation,
	|		RoomInventoryMovements.RoomsVacant AS RoomsVacant,
	|		RoomInventoryMovements.BedsVacant AS BedsVacant,
	|		RoomInventoryMovements.SpecialRoomsVacant AS SpecialRoomsVacant,
	|		RoomInventoryMovements.SpecialBedsVacant AS SpecialBedsVacant
	|	FROM
	|		(SELECT
	|			AvailableRooms.Hotel AS Hotel,
	|			NULL AS Status,
	|			NULL AS Room,
	|			NULL AS Customer,
	|			NULL AS Contract,
	|			NULL AS GuestGroup,
	|			NULL AS Guest,
	|			NULL AS CheckInDate,
	|			NULL AS Duration,
	|			NULL AS CheckOutDate,
	|			AvailableRooms.RoomType AS RoomType,
	|			NULL AS AccommodationType,
	|			NULL AS RoomQuota,
	|			NULL AS Remarks,
	|			NULL AS Recorder,
	|			TRUE AS IsRoomInventory,
	|			FALSE AS IsBlocking,
	|			FALSE AS IsRoomQuota,
	|			FALSE AS IsReservation,
	|			FALSE AS IsAccommodation,
	|			CASE
	|				WHEN AvailableRooms.RoomType.DoesNotAffectRoomRevenueStatistics
	|					THEN ISNULL(AvailableRooms.TotalSpecialRoomsBalance, 0)
	|				ELSE ISNULL(AvailableRooms.TotalRoomsBalance, 0)
	|			END AS RoomsVacant,
	|			CASE
	|				WHEN AvailableRooms.RoomType.DoesNotAffectRoomRevenueStatistics
	|					THEN ISNULL(AvailableRooms.TotalSpecialBedsBalance, 0)
	|				ELSE ISNULL(AvailableRooms.TotalBedsBalance, 0)
	|			END AS BedsVacant,
	|			CASE
	|				WHEN AvailableRooms.RoomType.DoesNotAffectRoomRevenueStatistics
	|					THEN ISNULL(AvailableRooms.TotalSpecialRoomsBalance, 0)
	|				ELSE 0
	|			END AS SpecialRoomsVacant,
	|			CASE
	|				WHEN AvailableRooms.RoomType.DoesNotAffectRoomRevenueStatistics
	|					THEN ISNULL(AvailableRooms.TotalSpecialBedsBalance, 0)
	|				ELSE 0
	|			END AS SpecialBedsVacant
	|		FROM
	|			AccumulationRegister.RoomInventory.Balance(
	|					&qPeriodTo,
	|					&qIsEmptyRoomQuota
	|						AND (Hotel IN HIERARCHY (&qHotel)
	|							OR &qIsEmptyHotel)
	|						AND (Room IN HIERARCHY (&qRoom)
	|							OR &qIsEmptyRoom)
	|						AND (RoomType IN HIERARCHY (&qRoomType)
	|							OR &qIsEmptyRoomType)) AS AvailableRooms
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			RoomBlocks.Hotel,
	|			RoomBlocks.RoomBlockType,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			RoomBlocks.RoomType,
	|			NULL,
	|			NULL,
	|			NULL,
	|			FALSE,
	|			TRUE,
	|			FALSE,
	|			FALSE,
	|			FALSE,
	|			-ISNULL(RoomBlocks.RoomsBlockedBalance, 0),
	|			-ISNULL(RoomBlocks.BedsBlockedBalance, 0),
	|			CASE
	|				WHEN RoomBlocks.RoomType.DoesNotAffectRoomRevenueStatistics
	|					THEN -ISNULL(RoomBlocks.RoomsBlockedBalance, 0)
	|				ELSE 0
	|			END,
	|			CASE
	|				WHEN RoomBlocks.RoomType.DoesNotAffectRoomRevenueStatistics
	|					THEN -ISNULL(RoomBlocks.BedsBlockedBalance, 0)
	|				ELSE 0
	|			END
	|		FROM
	|			AccumulationRegister.RoomBlocks.Balance(
	|					&qPeriodTo,
	|					&qIsEmptyRoomQuota
	|						AND (Hotel IN HIERARCHY (&qHotel)
	|							OR &qIsEmptyHotel)
	|						AND (Room IN HIERARCHY (&qRoom)
	|							OR &qIsEmptyRoom)
	|						AND (RoomType IN HIERARCHY (&qRoomType)
	|							OR &qIsEmptyRoomType)) AS RoomBlocks
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			RoomQuotas.Hotel,
	|			RoomQuotas.RoomQuota,
	|			NULL,
	|			RoomQuotas.RoomQuota.Customer,
	|			RoomQuotas.RoomQuota.Contract,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			RoomQuotas.RoomType,
	|			NULL,
	|			RoomQuotas.RoomQuota,
	|			NULL,
	|			NULL,
	|			FALSE,
	|			FALSE,
	|			TRUE,
	|			FALSE,
	|			FALSE,
	|			-ISNULL(RoomQuotas.RoomsRemainsBalance, 0),
	|			-ISNULL(RoomQuotas.BedsRemainsBalance, 0),
	|			CASE
	|				WHEN RoomQuotas.RoomType.DoesNotAffectRoomRevenueStatistics
	|					THEN -ISNULL(RoomQuotas.RoomsRemainsBalance, 0)
	|				ELSE 0
	|			END,
	|			CASE
	|				WHEN RoomQuotas.RoomType.DoesNotAffectRoomRevenueStatistics
	|					THEN -ISNULL(RoomQuotas.BedsRemainsBalance, 0)
	|				ELSE 0
	|			END
	|		FROM
	|			AccumulationRegister.RoomQuotaSales.Balance(
	|					&qPeriodTo,
	|					RoomQuota.DoWriteOff
	|						AND (Hotel IN HIERARCHY (&qHotel)
	|							OR &qIsEmptyHotel)
	|						AND (RoomQuota IN HIERARCHY (&qRoomQuota)
	|							OR &qIsEmptyRoomQuota)
	|						AND (Room IN HIERARCHY (&qRoom)
	|							OR &qIsEmptyRoom)
	|						AND (RoomType IN HIERARCHY (&qRoomType)
	|							OR &qIsEmptyRoomType)) AS RoomQuotas
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			Reservations.Hotel,
	|			Reservations.ReservationStatus,
	|			Reservations.Room,
	|			Reservations.Customer,
	|			Reservations.Contract,
	|			Reservations.GuestGroup,
	|			Reservations.Guest,
	|			Reservations.PeriodFrom,
	|			Reservations.PeriodDuration,
	|			Reservations.PeriodTo,
	|			Reservations.RoomType,
	|			Reservations.AccommodationType,
	|			Reservations.RoomQuota,
	|			Reservations.Remarks,
	|			Reservations.Recorder,
	|			FALSE,
	|			FALSE,
	|			FALSE,
	|			TRUE,
	|			FALSE,
	|			-Reservations.RoomsVacant,
	|			-Reservations.BedsVacant,
	|			CASE
	|				WHEN Reservations.RoomType.DoesNotAffectRoomRevenueStatistics
	|					THEN -Reservations.RoomsVacant
	|				ELSE 0
	|			END,
	|			CASE
	|				WHEN Reservations.RoomType.DoesNotAffectRoomRevenueStatistics
	|					THEN -Reservations.BedsVacant
	|				ELSE 0
	|			END
	|		FROM
	|			AccumulationRegister.RoomInventory AS Reservations
	|				INNER JOIN EffectivePeriodsByRecorders AS EffectivePeriodsByRecorders
	|				ON Reservations.Recorder = EffectivePeriodsByRecorders.Recorder
	|					AND Reservations.Period = EffectivePeriodsByRecorders.PeriodFrom
	|		WHERE
	|			Reservations.RecordType = VALUE(AccumulationRecordType.Expense)
	|			AND Reservations.IsReservation
	|			AND (Reservations.Hotel IN HIERARCHY (&qHotel)
	|					OR &qIsEmptyHotel)
	|			AND (Reservations.Room IN HIERARCHY (&qRoom)
	|					OR &qIsEmptyRoom)
	|			AND (Reservations.RoomQuota IN HIERARCHY (&qRoomQuota)
	|					OR &qIsEmptyRoomQuota)
	|			AND (Reservations.RoomType IN HIERARCHY (&qRoomType)
	|					OR &qIsEmptyRoomType)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			Accommodations.Hotel,
	|			Accommodations.AccommodationStatus,
	|			Accommodations.Room,
	|			Accommodations.Customer,
	|			Accommodations.Contract,
	|			Accommodations.GuestGroup,
	|			Accommodations.Guest,
	|			Accommodations.PeriodFrom,
	|			Accommodations.PeriodDuration,
	|			Accommodations.PeriodTo,
	|			Accommodations.RoomType,
	|			Accommodations.AccommodationType,
	|			Accommodations.RoomQuota,
	|			Accommodations.Remarks,
	|			Accommodations.Recorder,
	|			FALSE,
	|			FALSE,
	|			FALSE,
	|			FALSE,
	|			TRUE,
	|			-Accommodations.RoomsVacant,
	|			-Accommodations.BedsVacant,
	|			CASE
	|				WHEN Accommodations.RoomType.DoesNotAffectRoomRevenueStatistics
	|					THEN -Accommodations.RoomsVacant
	|				ELSE 0
	|			END,
	|			CASE
	|				WHEN Accommodations.RoomType.DoesNotAffectRoomRevenueStatistics
	|					THEN -Accommodations.BedsVacant
	|				ELSE 0
	|			END
	|		FROM
	|			AccumulationRegister.RoomInventory AS Accommodations
	|				INNER JOIN EffectivePeriodsByRecorders AS EffectivePeriodsByRecorders
	|				ON Accommodations.Recorder = EffectivePeriodsByRecorders.Recorder
	|					AND Accommodations.Period = EffectivePeriodsByRecorders.PeriodFrom
	|		WHERE
	|			Accommodations.RecordType = VALUE(AccumulationRecordType.Expense)
	|			AND Accommodations.IsAccommodation
	|			AND (Accommodations.Hotel IN HIERARCHY (&qHotel)
	|					OR &qIsEmptyHotel)
	|			AND (Accommodations.Room IN HIERARCHY (&qRoom)
	|					OR &qIsEmptyRoom)
	|			AND (Accommodations.RoomQuota IN HIERARCHY (&qRoomQuota)
	|					OR &qIsEmptyRoomQuota)
	|			AND (Accommodations.RoomType IN HIERARCHY (&qRoomType)
	|					OR &qIsEmptyRoomType)) AS RoomInventoryMovements) AS RoomInventory
	|{WHERE
	|	RoomInventory.Hotel.*,
	|	RoomInventory.Status.*,
	|	RoomInventory.Room.*,
	|	RoomInventory.Customer.*,
	|	RoomInventory.Contract.*,
	|	RoomInventory.GuestGroup.*,
	|	RoomInventory.Guest.*,
	|	RoomInventory.CheckInDate,
	|	RoomInventory.Duration,
	|	RoomInventory.CheckOutDate,
	|	RoomInventory.RoomType.*,
	|	RoomInventory.AccommodationType.*,
	|	RoomInventory.RoomQuota.*,
	|	RoomInventory.Remarks,
	|	RoomInventory.Recorder.*,
	|	RoomInventory.IsRoomInventory,
	|	RoomInventory.IsBlocking,
	|	RoomInventory.IsRoomQuota,
	|	RoomInventory.IsReservation,
	|	RoomInventory.IsAccommodation,
	|	RoomInventory.RoomsVacant,
	|	RoomInventory.BedsVacant}
	|
	|ORDER BY
	|	Hotel,
	|	IsRoomInventory DESC,
	|	IsBlocking DESC,
	|	IsRoomQuota DESC,
	|	IsReservation DESC,
	|	IsAccommodation DESC,
	|	RoomType,
	|	Room,
	|	CheckInDate,
	|	Guest
	|{ORDER BY
	|	Hotel.*,
	|	Status.*,
	|	Room.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	Guest.*,
	|	CheckInDate,
	|	Duration,
	|	CheckOutDate,
	|	RoomType.*,
	|	AccommodationType.*,
	|	RoomQuota.*,
	|	Remarks,
	|	Recorder.*,
	|	IsRoomInventory,
	|	IsBlocking,
	|	IsRoomQuota,
	|	IsReservation,
	|	IsAccommodation,
	|	RoomsVacant,
	|	BedsVacant}
	|TOTALS
	|	CASE
	|		WHEN RoomType IS NULL
	|			THEN SUM(RoomsVacant) - SUM(SpecialRoomsVacant)
	|		ELSE SUM(RoomsVacant)
	|	END AS RoomsVacant,
	|	CASE
	|		WHEN RoomType IS NULL
	|			THEN SUM(BedsVacant) - SUM(SpecialBedsVacant)
	|		ELSE SUM(BedsVacant)
	|	END AS BedsVacant,
	|	SUM(SpecialRoomsVacant),
	|	SUM(SpecialBedsVacant)
	|BY
	|	OVERALL,
	|	Hotel,
	|	RoomType
	|{TOTALS BY
	|	Hotel.*,
	|	Status.*,
	|	Room.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	Guest.*,
	|	RoomType.*,
	|	RoomQuota.*,
	|	Recorder.*,
	|	IsRoomInventory,
	|	IsBlocking,
	|	IsRoomQuota,
	|	IsReservation,
	|	IsAccommodation}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Room inventory';RU='Загрузка номеров';de='Laden von Zimmern'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
