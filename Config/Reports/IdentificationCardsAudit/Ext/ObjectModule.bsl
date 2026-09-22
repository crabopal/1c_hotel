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
	If ValueIsFilled(Author) Then
		If Not Author.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Employee ';ru='Сотрудник ';de='Mitarbeiter '") + 
			                     TrimAll(Author.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа сотрудников '; en = 'Employees folder '; de = 'Mitarbeitergruppe '") + 
			                     TrimAll(Author.Description) + 
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
	ReportBuilder.Parameters.Insert("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodFromIsEmpty", Not ValueIsFilled(PeriodFrom));
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qPeriodToIsEmpty", Not ValueIsFilled(PeriodTo));
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qRoomIsEmpty", Not ValueIsFilled(Room));
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qRoomTypeIsEmpty", Not ValueIsFilled(RoomType));
	ReportBuilder.Parameters.Insert("qAuthor", Author);
	ReportBuilder.Parameters.Insert("qAuthorIsEmpty", Not ValueIsFilled(Author));

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
	|	IdentificationCards.Ref AS IdentificationCard,
	|	IdentificationCards.Code,
	|	IdentificationCards.Description,
	|	IdentificationCards.IsBlocked,
	|	IdentificationCards.IsCheckedOut,
	|	IdentificationCards.Identifier,
	|	IdentificationCards.IdentificationCardType,
	|	IdentificationCards.CardUID,
	|	IdentificationCards.Folio,
	|	IdentificationCards.ParentDoc,
	|	IdentificationCards.GuestGroup,
	|	IdentificationCards.Client,
	|	IdentificationCards.Room,
	|	IdentificationCards.Room.RoomType AS RoomType,
	|	IdentificationCards.DateTimeFrom,
	|	IdentificationCards.DateTimeTo,
	|	IdentificationCards.Hotel,
	|	IdentificationCards.BlockReason,
	|	IdentificationCards.CreateDate AS CreateDate,
	|	IdentificationCards.Author,
	|	FolioBalance.SumBalance AS FolioSumBalance,
	|	FolioBalance.LimitBalance AS FolioLimitBalance,
	|	1 AS Counter
	|{SELECT
	|	IdentificationCard.* AS IdentificationCard,
	|	Code,
	|	Description,
	|	IsBlocked,
	|	IsCheckedOut,
	|	Identifier,
	|	IdentificationCardType.*,
	|	CardUID,
	|	Folio.*,
	|	ParentDoc.*,
	|	GuestGroup.*,
	|	Client.*,
	|	Room.*,
	|	RoomType.*,
	|	DateTimeFrom,
	|	DateTimeTo,
	|	Hotel.*,
	|	BlockReason,
	|	CreateDate,
	|	(BEGINOFPERIOD(IdentificationCards.CreateDate, DAY)) AS AccountingDate,
	|	Author.*,
	|	FolioSumBalance,
	|	FolioLimitBalance,
	|	Counter}
	|FROM
	|	Catalog.IdentificationCards AS IdentificationCards
	|		LEFT JOIN (SELECT
	|			AccountsBalance.Hotel AS Hotel,
	|			AccountsBalance.FolioCurrency AS FolioCurrency,
	|			AccountsBalance.Folio AS Folio,
	|			AccountsBalance.SumBalance AS SumBalance,
	|			AccountsBalance.LimitBalance AS LimitBalance
	|		FROM
	|			AccumulationRegister.Accounts.Balance(
	|					,
	|					(Hotel IN HIERARCHY (&qHotel)
	|						OR &qHotelIsEmpty)
	|						AND (Folio.Room IN (&qRoom)
	|							OR &qRoomIsEmpty)
	|						AND (Folio.Room.RoomType IN (&qRoomType)
	|							OR &qRoomTypeIsEmpty)) AS AccountsBalance) AS FolioBalance
	|		ON IdentificationCards.Folio = FolioBalance.Folio
	|WHERE
	|	(IdentificationCards.Hotel IN (&qHotel)
	|			OR &qHotelIsEmpty)
	|	AND (IdentificationCards.Room IN HIERARCHY (&qRoom)
	|			OR &qRoomIsEmpty)
	|	AND (IdentificationCards.Room.RoomType IN HIERARCHY (&qRoomType)
	|			OR &qRoomTypeIsEmpty)
	|	AND (IdentificationCards.Author IN HIERARCHY (&qAuthor)
	|			OR &qAuthorIsEmpty)
	|	AND (IdentificationCards.CreateDate >= &qPeriodFrom
	|			OR &qPeriodFromIsEmpty)
	|	AND (IdentificationCards.CreateDate <= &qPeriodTo
	|			OR &qPeriodToIsEmpty)
	|{WHERE
	|	IdentificationCards.Ref.* AS IdentificationCard,
	|	IdentificationCards.Code,
	|	IdentificationCards.Description,
	|	IdentificationCards.IsBlocked,
	|	IdentificationCards.IsCheckedOut,
	|	IdentificationCards.Identifier,
	|	IdentificationCards.IdentificationCardType.*,
	|	IdentificationCards.CardUID,
	|	IdentificationCards.Folio.*,
	|	IdentificationCards.ParentDoc.*,
	|	IdentificationCards.GuestGroup.*,
	|	IdentificationCards.Client.*,
	|	IdentificationCards.Room.*,
	|	IdentificationCards.Room.RoomType.* AS RoomType,
	|	IdentificationCards.DateTimeFrom,
	|	IdentificationCards.DateTimeTo,
	|	IdentificationCards.Hotel.*,
	|	IdentificationCards.BlockReason,
	|	IdentificationCards.CreateDate,
	|	IdentificationCards.Author.*,
	|	FolioBalance.SumBalance AS FolioSumBalance,
	|	FolioBalance.LimitBalance AS FolioLimitBalance}
	|
	|ORDER BY
	|	CreateDate
	|{ORDER BY
	|	IdentificationCard.* AS IdentificationCard,
	|	Code,
	|	Description,
	|	IsBlocked,
	|	IsCheckedOut,
	|	Identifier,
	|	IdentificationCardType.*,
	|	CardUID,
	|	Folio.*,
	|	ParentDoc.*,
	|	GuestGroup.*,
	|	Client.*,
	|	Room.*,
	|	RoomType.*,
	|	DateTimeFrom,
	|	DateTimeTo,
	|	Hotel.*,
	|	BlockReason,
	|	CreateDate,
	|	Author.*,
	|	FolioSumBalance,
	|	FolioLimitBalance}
	|TOTALS
	|	CASE
	|		WHEN IdentificationCard IS NULL 
	|			THEN SUM(FolioSumBalance)
	|		ELSE 0
	|	END AS FolioSumBalance,
	|	CASE
	|		WHEN IdentificationCard IS NULL 
	|			THEN SUM(FolioLimitBalance)
	|		ELSE 0
	|	END AS FolioLimitBalance,
	|	SUM(Counter)
	|BY
	|	OVERALL,
	|	IdentificationCard
	|{TOTALS BY
	|	IdentificationCard.* AS IdentificationCard,
	|	Code,
	|	Description,
	|	IsBlocked,
	|	IsCheckedOut,
	|	Identifier,
	|	IdentificationCardType.*,
	|	CardUID,
	|	Folio.*,
	|	ParentDoc.*,
	|	GuestGroup.*,
	|	Client.*,
	|	Room.*,
	|	RoomType.*,
	|	Hotel.*,
	|	BlockReason,
	|	(BEGINOFPERIOD(IdentificationCards.CreateDate, DAY)) AS AccountingDate,
	|	Author.*}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Client identification cards audit';RU='Аудит выданных карт идентификации клиентов';de='Prüfung der ausgegebenen Identifikationskarten der Kunden'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
