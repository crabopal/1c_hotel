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
		PeriodTo = EndOfDay(PeriodFrom);
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
	If Not IsBlankString(EventType) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Тип события '; en = 'Event type '; de = 'Ereignistyp '") + 
							 TrimAll(EventType) + 
							 ";" + Chars.LF;
	EndIf;					 
	If Not IsBlankString(CardType) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Тип карты '; en = 'Card type '; de = 'Kartentyp '") + 
							 TrimAll(CardType) + 
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
	If ShowSuspiciousEventsOnly Then
		vParamPresentation = vParamPresentation + NStr("en='Show vacant rooms events only';ru='Показывать только события в свободных номерах';de='Nur Ereignissen in freien Zimmern anzeigen'") + 
							 ";" + Chars.LF;
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
	ReportBuilder.Parameters.Insert("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qEventType", EventType);
	ReportBuilder.Parameters.Insert("qEventTypeIsEmpty", IsBlankString(EventType));
	ReportBuilder.Parameters.Insert("qCardType", CardType);
	ReportBuilder.Parameters.Insert("qCardTypeIsEmpty", IsBlankString(CardType));
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qRoomTypeIsEmpty", Not ValueIsFilled(RoomType));
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qRoomIsEmpty", Not ValueIsFilled(Room));
	ReportBuilder.Parameters.Insert("qShowSuspiciousEventsOnly", ShowSuspiciousEventsOnly);
	
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
EndProcedure // pmGenerate
	
// -----------------------------------------------------------------------------
Procedure pmInitializeReportBuilder() Export
	ReportBuilder = New ReportBuilder();
	
	// Initialize default query text
	QueryText = 
	"SELECT
	|	SafetySystemEvents.Period AS Period,
	|	SafetySystemEvents.Author AS Author,
	|	SafetySystemEvents.Hotel AS Hotel,
	|	SafetySystemEvents.EventType AS EventType,
	|	SafetySystemEvents.Room AS Room,
	|	SafetySystemEvents.CardType AS CardType,
	|	SafetySystemEvents.CardCode AS CardCode,
	|	SafetySystemEvents.EventDescription AS EventDescription,
	|	SafetySystemEvents.PeriodFrom AS CardPeriodFrom,
	|	SafetySystemEvents.PeriodTo AS CardPeriodTo,
	|	SafetySystemEvents.ParentDoc AS CardDoc,
	|	SafetySystemEvents.Guest AS CardGuest,
	|	SafetySystemEvents.IsActive AS IsActive,
	|	Accommodation.Recorder AS Doc,
	|	Accommodation.Guest AS Guest,
	|	Accommodation.CheckInDate AS CheckInDate,
	|	Accommodation.Duration AS Duration,
	|	Accommodation.CheckOutDate AS CheckOutDate,
	|	1 AS Counter,
	|	SafetySystemEvents.NumberOfKeys AS NumberOfKeys
	|{SELECT
	|	Period,
	|	Author.*,
	|	(HOUR(SafetySystemEvents.Period)) AS AccountingHour,
	|	(BEGINOFPERIOD(SafetySystemEvents.Period, DAY)) AS AccountingDate,
	|	(WEEK(SafetySystemEvents.Period)) AS AccountingWeek,
	|	(MONTH(SafetySystemEvents.Period)) AS AccountingMonth,
	|	(QUARTER(SafetySystemEvents.Period)) AS AccountingQuarter,
	|	(YEAR(SafetySystemEvents.Period)) AS AccountingYear,
	|	Hotel.*,
	|	EventType,
	|	Room.*,
	|	CardType,
	|	CardCode,
	|	EventDescription,
	|	CardPeriodFrom,
	|	CardPeriodTo,
	|	CardDoc.*,
	|	CardGuest.*,
	|	IsActive,
	|	Doc.*,
	|	Guest.*,
	|	CheckInDate,
	|	Duration,
	|	CheckOutDate,
	|	Accommodation.ClientType.* AS ClientType,
	|	Accommodation.Customer.* AS Customer,
	|	Accommodation.CustomerType.* AS CustomerType,
	|	Accommodation.Contract.* AS Contract,
	|	Accommodation.Agent.* AS Agent,
	|	Accommodation.AccommodationStatus.* AS AccommodationStatus,
	|	Accommodation.RoomType.* AS RoomType,
	|	Accommodation.AccommodationType.* AS AccommodationType,
	|	Accommodation.RoomRate.* AS RoomRate,
	|	Accommodation.Remarks AS Remarks,
	|	Accommodation.GuestGroup.* AS GuestGroup,
	|	Accommodation.NumberOfPersons AS NumberOfPersons,
	|	Accommodation.HotelProduct.* AS HotelProduct,
	|	Accommodation.RoomQuota.* AS RoomQuota,
	|	Accommodation.MarketingCode.* AS MarketingCode,
	|	Accommodation.TripPurpose.* AS TripPurpose,
	|	Accommodation.SourceOfBusiness.* AS SourceOfBusiness,
	|	Accommodation.DiscountCard.* AS DiscountCard,
	|	Accommodation.DiscountType.* AS DiscountType,
	|	Accommodation.Discount AS Discount,
	|	Accommodation.AgentCommission AS AgentCommission,
	|	Accommodation.AgentCommissionType AS AgentCommissionType,
	|	Accommodation.PricePresentation AS PricePresentation,
	|	Accommodation.Reservation.* AS Reservation,
	|	Accommodation.IsMaster AS IsMaster,
	|	Counter,
	|	NumberOfKeys}
	|FROM
	|	InformationRegister.SafetySystemEvents AS SafetySystemEvents
	|		LEFT JOIN AccumulationRegister.RoomInventory AS Accommodation
	|		ON (Accommodation.Guest = SafetySystemEvents.Guest)
	|			AND (Accommodation.Recorder.Number = SafetySystemEvents.ParentDoc.Number)
	|			AND (Accommodation.Period = Accommodation.CheckInDate)
	|			AND (Accommodation.RecordType = VALUE(AccumulationRecordType.Expense))
	|WHERE
	|	SafetySystemEvents.Period >= &qPeriodFrom
	|	AND SafetySystemEvents.Period <= &qPeriodTo
	|	AND (SafetySystemEvents.EventType = &qEventType
	|			OR &qEventTypeIsEmpty)
	|	AND (SafetySystemEvents.CardType = &qCardType
	|			OR &qCardTypeIsEmpty)
	|	AND (SafetySystemEvents.Room.RoomType IN HIERARCHY (&qRoomType)
	|			OR &qRoomTypeIsEmpty)
	|	AND (SafetySystemEvents.Room IN HIERARCHY (&qRoom)
	|			OR &qRoomIsEmpty)
	|	AND (SafetySystemEvents.Hotel IN HIERARCHY (&qHotel)
	|			OR &qHotelIsEmpty)
	|	AND (&qShowSuspiciousEventsOnly
	|				AND Accommodation.Recorder IS NULL
	|			OR NOT &qShowSuspiciousEventsOnly)
	|{WHERE
	|	SafetySystemEvents.Period,
	|	SafetySystemEvents.Author.* AS Author,
	|	SafetySystemEvents.Hotel.* AS Hotel,
	|	SafetySystemEvents.EventType AS EventType,
	|	SafetySystemEvents.Room.* AS Room,
	|	SafetySystemEvents.CardType AS CardType,
	|	SafetySystemEvents.CardCode AS CardCode,
	|	SafetySystemEvents.EventDescription AS EventDescription,
	|	SafetySystemEvents.PeriodFrom AS CardPeriodFrom,
	|	SafetySystemEvents.PeriodTo AS CardPeriodTo,
	|	SafetySystemEvents.ParentDoc.* AS CardDoc,
	|	SafetySystemEvents.Guest.* AS CardGuest,
	|	SafetySystemEvents.IsActive AS IsActive,
	|	Accommodation.Recorder.* AS Doc,
	|	Accommodation.Guest.* AS Guest,
	|	Accommodation.CheckInDate AS CheckInDate,
	|	Accommodation.Duration AS Duration,
	|	Accommodation.CheckOutDate AS CheckOutDate,
	|	Accommodation.ClientType.* AS ClientType,
	|	Accommodation.Customer.* AS Customer,
	|	Accommodation.CustomerType.* AS CustomerType,
	|	Accommodation.Contract.* AS Contract,
	|	Accommodation.Agent.* AS Agent,
	|	Accommodation.AccommodationStatus.* AS AccommodationStatus,
	|	Accommodation.RoomType.* AS RoomType,
	|	Accommodation.AccommodationType.* AS AccommodationType,
	|	Accommodation.RoomRate.* AS RoomRate,
	|	Accommodation.Remarks AS Remarks,
	|	Accommodation.GuestGroup.* AS GuestGroup,
	|	Accommodation.NumberOfPersons AS NumberOfPersons,
	|	Accommodation.HotelProduct.* AS HotelProduct,
	|	Accommodation.RoomQuota.* AS RoomQuota,
	|	Accommodation.MarketingCode.* AS MarketingCode,
	|	Accommodation.TripPurpose.* AS TripPurpose,
	|	Accommodation.SourceOfBusiness.* AS SourceOfBusiness,
	|	Accommodation.DiscountCard.* AS DiscountCard,
	|	Accommodation.DiscountType.* AS DiscountType,
	|	Accommodation.Discount AS Discount,
	|	Accommodation.AgentCommission AS AgentCommission,
	|	Accommodation.AgentCommissionType AS AgentCommissionType,
	|	Accommodation.PricePresentation AS PricePresentation,
	|	Accommodation.Reservation.* AS Reservation,
	|	Accommodation.IsMaster AS IsMaster,
	|	SafetySystemEvents.NumberOfKeys}
	|
	|ORDER BY
	|	Hotel,
	|	Room,
	|	Period
	|{ORDER BY
	|	Period,
	|	Hotel.*,
	|	EventType,
	|	Room.*,
	|	Author.*,
	|	CardType,
	|	CardCode,
	|	CardPeriodFrom,
	|	CardPeriodTo,
	|	CardDoc.*,
	|	CardGuest.*,
	|	IsActive,
	|	Doc.*,
	|	Accommodation.Reservation.*,
	|	Guest.*,
	|	CheckInDate,
	|	Duration,
	|	CheckOutDate,
	|	Accommodation.ClientType.* AS ClientType,
	|	Accommodation.Customer.* AS Customer,
	|	Accommodation.CustomerType.* AS CustomerType,
	|	Accommodation.Contract.* AS Contract,
	|	Accommodation.Agent.* AS Agent,
	|	Accommodation.AccommodationStatus.* AS AccommodationStatus,
	|	Accommodation.RoomType.* AS RoomType,
	|	Accommodation.AccommodationType.* AS AccommodationType,
	|	Accommodation.RoomRate.* AS RoomRate,
	|	Accommodation.Remarks AS Remarks,
	|	Accommodation.GuestGroup.* AS GuestGroup,
	|	Accommodation.NumberOfPersons AS NumberOfPersons,
	|	Accommodation.HotelProduct.* AS HotelProduct,
	|	Accommodation.RoomQuota.* AS RoomQuota,
	|	Accommodation.MarketingCode.* AS MarketingCode,
	|	Accommodation.TripPurpose.* AS TripPurpose,
	|	Accommodation.SourceOfBusiness.* AS SourceOfBusiness,
	|	Accommodation.DiscountCard.* AS DiscountCard,
	|	Accommodation.DiscountType.* AS DiscountType,
	|	Accommodation.Discount AS Discount,
	|	Accommodation.AgentCommission AS AgentCommission,
	|	Accommodation.AgentCommissionType AS AgentCommissionType,
	|	Accommodation.PricePresentation AS PricePresentation,
	|	Accommodation.IsMaster AS IsMaster,
	|	NumberOfKeys}
	|TOTALS
	|	SUM(Counter),
	|	SUM(NumberOfKeys)
	|BY
	|	OVERALL
	|{TOTALS BY
	|	Period,
	|	(HOUR(SafetySystemEvents.Period)) AS AccountingHour,
	|	(BEGINOFPERIOD(SafetySystemEvents.Period, DAY)) AS AccountingDate,
	|	(WEEK(SafetySystemEvents.Period)) AS AccountingWeek,
	|	(MONTH(SafetySystemEvents.Period)) AS AccountingMonth,
	|	(QUARTER(SafetySystemEvents.Period)) AS AccountingQuarter,
	|	(YEAR(SafetySystemEvents.Period)) AS AccountingYear,
	|	Hotel.*,
	|	EventType,
	|	Room.*,
	|	CardType,
	|	CardCode,
	|	Doc.*,
	|	Guest.*,
	|	CheckInDate,
	|	Duration,
	|	CheckOutDate,
	|	Accommodation.ClientType.* AS ClientType,
	|	Accommodation.Customer.* AS Customer,
	|	Accommodation.CustomerType.* AS CustomerType,
	|	Accommodation.Contract.* AS Contract,
	|	Accommodation.Agent.* AS Agent,
	|	Accommodation.AccommodationStatus.* AS AccommodationStatus,
	|	Accommodation.RoomType.* AS RoomType,
	|	Accommodation.AccommodationType.* AS AccommodationType,
	|	Accommodation.RoomRate.* AS RoomRate,
	|	Accommodation.Remarks AS Remarks,
	|	Accommodation.GuestGroup.* AS GuestGroup,
	|	Accommodation.NumberOfPersons AS NumberOfPersons,
	|	Accommodation.HotelProduct.* AS HotelProduct,
	|	Accommodation.RoomQuota.* AS RoomQuota,
	|	Accommodation.MarketingCode.* AS MarketingCode,
	|	Accommodation.TripPurpose.* AS TripPurpose,
	|	Accommodation.SourceOfBusiness.* AS SourceOfBusiness,
	|	Accommodation.DiscountCard.* AS DiscountCard,
	|	Accommodation.DiscountType.* AS DiscountType,
	|	Accommodation.Discount AS Discount,
	|	Accommodation.AgentCommission AS AgentCommission,
	|	Accommodation.AgentCommissionType AS AgentCommissionType,
	|	Accommodation.PricePresentation AS PricePresentation,
	|	Accommodation.IsMaster AS IsMaster}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("en='Safety system events audit';ru='Аудит событий системы безопасности';de='Audit der Ereignisse des Sicherheitssystems'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
