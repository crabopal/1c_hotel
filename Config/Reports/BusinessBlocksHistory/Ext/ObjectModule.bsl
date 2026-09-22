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
	If Not ValueIsFilled(PeriodCheckType) Then
		PeriodCheckType = Enums.BusinessBlocksPeriodCheckTypes.CreatedInPeriod;
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
	If Not ValueIsFilled(PeriodCheckType) Then
		vParamPresentation = vParamPresentation + NStr("en='Report period check type is not set';ru='Вид проверки периода отчета не установлен';de='Art der Kontrolle des Berichtszeitraums nicht festgelegt'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodCheckType = Enums.BusinessBlocksPeriodCheckTypes.CreatedInPeriod Then
		vParamPresentation = vParamPresentation + NStr("en='Business blocks created in the period selected';ru='Бизнес-блоки созданные в указанном периоде';de='Im angegebenen Zeitraum erstellte Geschäftsblöcke'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodCheckType = Enums.BusinessBlocksPeriodCheckTypes.CancelledInPeriod Then
		vParamPresentation = vParamPresentation + NStr("en='Business blocks cancelled in the period selected';ru='Бизнес-блоки отмененные в указанном периоде';de='Im angegebenen Zeitraum stornierte Geschäftsblöcke'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodCheckType = Enums.BusinessBlocksPeriodCheckTypes.Intersection Then
		vParamPresentation = vParamPresentation + NStr("en='Business blocks intersected with the period selected';ru='Бизнес-блоки пересекающиеся с указанным периодом';de='Geschäftsblöcke, die sich mit dem angegebenen Zeitraum überschneiden'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodCheckType = Enums.BusinessBlocksPeriodCheckTypes.StartsInPeriod Then
		vParamPresentation = vParamPresentation + NStr("en='Business blocks started in the period selected';ru='Бизнес-блоки начинающиеся в указанном периоде';de='Geschäftsblöcke beginnen im angegebenen Zeitraum'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodCheckType = Enums.BusinessBlocksPeriodCheckTypes.DateOfDefInPeriod Then
		vParamPresentation = vParamPresentation + NStr("en='Business blocks with decision date in the period selected';ru='Бизнес-блоки с датой принятия решения в указанном периоде';de='Geschäftsblöcke mit Entscheidungsdatum im angegebenen Zeitraum'") + 
		                     ";" + Chars.LF;
	Endif;		
	If ValueIsFilled(Customer) Then
		If Not Customer.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Customer ';ru='Заказчик ';de='Firma '") + 
			                     TrimAll(Customer.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Customers folder ';ru='Группа контрагентов ';de='Firmengruppe '") + 
			                     TrimAll(Customer.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(Author) Then
		If Not Author.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Employee ';ru='Сотрудник ';de='Mitarbeiter '") + 
			                     TrimAll(Author.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Employees folder ';ru='Группа сотрудников ';de='Mitarbeitergruppe '") + 
			                     TrimAll(Author.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(Status) Then
		vParamPresentation = vParamPresentation + NStr("en='Status ';ru='Статус ';de='Status '") + 
		                     TrimAll(Status) + 
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
	If ShowActiveOnly Then
		vParamPresentation = vParamPresentation + NStr("en='Active business blocks only';ru='Только действующие бизнес-блоки';de='Nur aktive Geschäftsblöcke'") + 
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
// Runs report
// -----------------------------------------------------------------------------
Procedure pmGenerate(pSpreadsheet) Export
	Var vTemplateAttributes;
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
	
	// Initialize report builder query generator attributes
	ReportBuilder.PresentationAdding = PresentationAdditionType.Add;
	
	// Fill report parameters
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qPeriodCheckType", PeriodCheckType);
	ReportBuilder.Parameters.Insert("qCustomer", Customer);
	ReportBuilder.Parameters.Insert("qAuthor", Author);
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qStatus", Status);
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qShowActiveOnly", ShowActiveOnly);

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
	|	ReportBusinessBlocks.Ref AS Ref
	|INTO BusinessBlocks
	|FROM
	|	Catalog.RoomQuotas AS ReportBusinessBlocks
	|WHERE
	|	NOT ReportBusinessBlocks.IsFolder
	|	AND NOT ReportBusinessBlocks.DeletionMark
	|	AND ReportBusinessBlocks.AllotmentBusinessType = VALUE(Enum.AllotmentBusinessTypes.BusinessBlock)
	|	AND CASE
	|			WHEN &qPeriodCheckType = VALUE(Enum.BusinessBlocksPeriodCheckTypes.CreatedInPeriod)
	|				THEN ReportBusinessBlocks.CreateDate BETWEEN &qPeriodFrom AND &qPeriodTo
	|			WHEN &qPeriodCheckType = VALUE(Enum.BusinessBlocksPeriodCheckTypes.CancelledInPeriod)
	|				THEN ReportBusinessBlocks.DateOfAnnulation BETWEEN &qPeriodFrom AND &qPeriodTo
	|			WHEN &qPeriodCheckType = VALUE(Enum.BusinessBlocksPeriodCheckTypes.Intersection)
	|				THEN ReportBusinessBlocks.PeriodFrom < &qPeriodTo
	|						AND ReportBusinessBlocks.PeriodTo > &qPeriodFrom
	|			WHEN &qPeriodCheckType = VALUE(Enum.BusinessBlocksPeriodCheckTypes.StartsInPeriod)
	|				THEN ReportBusinessBlocks.PeriodFrom BETWEEN &qPeriodFrom AND &qPeriodTo
	|			WHEN &qPeriodCheckType = VALUE(Enum.BusinessBlocksPeriodCheckTypes.DateOfDefInPeriod)
	|				THEN ReportBusinessBlocks.DateOfDef BETWEEN &qPeriodFrom AND &qPeriodTo
	|		END
	|	AND (ReportBusinessBlocks.Customer IN HIERARCHY (&qCustomer)
	|			OR &qCustomer = VALUE(Catalog.Customers.EmptyRef))
	|	AND (ReportBusinessBlocks.AllotmentType = &qStatus
	|			OR &qStatus = VALUE(Enum.AllotmentTypes.EmptyRef))
	|	AND CASE
	|			WHEN &qAuthor = VALUE(Catalog.Employees.EmptyRef)
	|				THEN TRUE
	|			WHEN &qPeriodCheckType = VALUE(Enum.BusinessBlocksPeriodCheckTypes.CreatedInPeriod)
	|				THEN ReportBusinessBlocks.Author IN HIERARCHY (&qAuthor)
	|			WHEN &qPeriodCheckType = VALUE(Enum.BusinessBlocksPeriodCheckTypes.CancelledInPeriod)
	|				THEN ReportBusinessBlocks.AuthorOfAnnulation IN HIERARCHY (&qAuthor)
	|			WHEN &qPeriodCheckType = VALUE(Enum.BusinessBlocksPeriodCheckTypes.Intersection)
	|				THEN ReportBusinessBlocks.Author IN HIERARCHY (&qAuthor)
	|			WHEN &qPeriodCheckType = VALUE(Enum.BusinessBlocksPeriodCheckTypes.StartsInPeriod)
	|				THEN ReportBusinessBlocks.Author IN HIERARCHY (&qAuthor)
	|			WHEN &qPeriodCheckType = VALUE(Enum.BusinessBlocksPeriodCheckTypes.DateOfDefInPeriod)
	|				THEN ReportBusinessBlocks.Author IN HIERARCHY (&qAuthor)
	|		END
	|	AND (NOT &qShowActiveOnly
	|			OR &qShowActiveOnly
	|				AND ReportBusinessBlocks.AllotmentType <> VALUE(Enum.AllotmentTypes.Cancelled))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BusinessBlockBalancesByRoomTypes.Hotel AS Hotel,
	|	BusinessBlockBalancesByRoomTypes.RoomQuota AS RoomQuota,
	|	BusinessBlockBalancesByRoomTypes.RoomType AS RoomType,
	|	SUM(BusinessBlockBalancesByRoomTypes.InitialRoomsInQuota) AS InitialRoomsInQuota,
	|	SUM(BusinessBlockBalancesByRoomTypes.InitialBedsInQuota) AS InitialBedsInQuota,
	|	SUM(BusinessBlockBalancesByRoomTypes.RoomsInQuota) AS RoomsInQuota,
	|	SUM(BusinessBlockBalancesByRoomTypes.BedsInQuota) AS BedsInQuota,
	|	SUM(BusinessBlockBalancesByRoomTypes.PickupRooms) AS PickupRooms,
	|	SUM(BusinessBlockBalancesByRoomTypes.PickupBeds) AS PickupBeds,
	|	SUM(BusinessBlockBalancesByRoomTypes.RoomsRemains) AS RoomsRemains,
	|	SUM(BusinessBlockBalancesByRoomTypes.BedsRemains) AS BedsRemains,
	|	MAX(BusinessBlockBalancesByRoomTypes.Counter) AS Counter
	|INTO BusinessBlockBalancesByRoomTypes
	|FROM
	|	(SELECT
	|		BusinessBlockBalances.Period AS PeriodDate,
	|		BusinessBlockBalances.Hotel AS Hotel,
	|		BusinessBlockBalances.RoomQuota AS RoomQuota,
	|		BusinessBlockBalances.RoomType AS RoomType,
	|		BusinessBlockBalances.InitialRoomsInQuotaClosingBalance AS InitialRoomsInQuota,
	|		BusinessBlockBalances.InitialBedsInQuotaClosingBalance AS InitialBedsInQuota,
	|		BusinessBlockBalances.RoomsInQuotaClosingBalance AS RoomsInQuota,
	|		BusinessBlockBalances.BedsInQuotaClosingBalance AS BedsInQuota,
	|		BusinessBlockBalances.RoomsInQuotaClosingBalance - BusinessBlockBalances.RoomsRemainsClosingBalance AS PickupRooms,
	|		BusinessBlockBalances.BedsInQuotaClosingBalance - BusinessBlockBalances.BedsRemainsClosingBalance AS PickupBeds,
	|		BusinessBlockBalances.RoomsRemainsClosingBalance AS RoomsRemains,
	|		BusinessBlockBalances.BedsRemainsClosingBalance AS BedsRemains,
	|		BusinessBlockBalances.CounterClosingBalance AS Counter
	|	FROM
	|		AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
	|				,
	|				,
	|				DAY,
	|				RegisterRecordsAndPeriodBoundaries,
	|				RoomQuota IN
	|						(SELECT
	|							BusinessBlocks.Ref
	|						FROM
	|							BusinessBlocks AS BusinessBlocks)
	|					AND NOT RoomType.IsVirtual
	|					AND NOT RoomType.DeletionMark) AS BusinessBlockBalances) AS BusinessBlockBalancesByRoomTypes
	|
	|GROUP BY
	|	BusinessBlockBalancesByRoomTypes.Hotel,
	|	BusinessBlockBalancesByRoomTypes.RoomQuota,
	|	BusinessBlockBalancesByRoomTypes.RoomType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BusinessBlockBalances.Hotel AS Hotel,
	|	BusinessBlockBalances.RoomQuota AS RoomQuota,
	|	SUM(BusinessBlockBalances.InitialRoomsInQuota) AS InitialRoomsInQuota,
	|	SUM(BusinessBlockBalances.InitialBedsInQuota) AS InitialBedsInQuota,
	|	SUM(BusinessBlockBalances.RoomsInQuota) AS RoomsInQuota,
	|	SUM(BusinessBlockBalances.BedsInQuota) AS BedsInQuota,
	|	SUM(BusinessBlockBalances.PickupRooms) AS PickupRooms,
	|	SUM(BusinessBlockBalances.PickupBeds) AS PickupBeds,
	|	SUM(BusinessBlockBalances.RoomsRemains) AS RoomsRemains,
	|	SUM(BusinessBlockBalances.BedsRemains) AS BedsRemains,
	|	MAX(BusinessBlockBalances.Counter) AS Counter
	|INTO BusinessBlockBalances
	|FROM
	|	BusinessBlockBalancesByRoomTypes AS BusinessBlockBalances
	|
	|GROUP BY
	|	BusinessBlockBalances.Hotel,
	|	BusinessBlockBalances.RoomQuota
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	EffectiveBuisinessBlocks.Hotel AS Hotel,
	|	EffectiveBuisinessBlocks.RoomQuota AS RoomQuota
	|INTO EffectiveBuisinessBlocks
	|FROM
	|	BusinessBlockBalancesByRoomTypes AS EffectiveBuisinessBlocks
	|WHERE
	|	(EffectiveBuisinessBlocks.RoomType IN HIERARCHY (&qRoomType)
	|			OR &qRoomType = VALUE(Catalog.RoomTypes.EmptyRef))
	|	AND (EffectiveBuisinessBlocks.RoomsRemains <> 0
	|			OR EffectiveBuisinessBlocks.BedsRemains <> 0)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BusinessBlocks.Ref.Hotel AS Hotel,
	|	BusinessBlocks.Ref AS BusinessBlock,
	|	BusinessBlocks.Ref.Code AS Code,
	|	BusinessBlocks.Ref.Description AS Description,
	|	BusinessBlocks.Ref.AllotmentType AS Status,
	|	BusinessBlocks.Ref.AnnulationReason AS AnnulationReason,
	|	BusinessBlocks.Ref.PeriodFrom AS PeriodFrom,
	|	BusinessBlocks.Ref.PeriodTo AS PeriodTo,
	|	BusinessBlocks.Ref.RoomRate AS RoomRate,
	|	BusinessBlocks.Ref.CreateDate AS CreateDate,
	|	BusinessBlocks.Ref.Author AS Author,
	|	BusinessBlocks.Ref.MarketingCode AS MarketingCode,
	|	BusinessBlocks.Ref.TripPurpose AS TripPurpose,
	|	BusinessBlocks.Ref.SourceOfBusiness AS SourceOfBusiness,
	|	BusinessBlocks.Ref.Remarks AS Remarks,
	|	BusinessBlocks.Ref.DateOfDef AS DateOfDef,
	|	BusinessBlocks.Ref.DateOfAnnulation AS DateOfAnnulation,
	|	BusinessBlocks.Ref.AuthorOfAnnulation AS AuthorOfAnnulation,
	|	BusinessBlocks.Ref.Customer AS Customer,
	|	BusinessBlocks.Ref.RoomNights AS RoomNights,
	|	BusinessBlocks.Ref.BudgetADR AS BudgetADR,
	|	BusinessBlocks.Ref.BudgetReservationAmount AS BudgetReservationAmount,
	|	BusinessBlocks.Ref.BudgetMICEAmount AS BudgetMICEAmount,
	|	BusinessBlocks.Ref.BudgetAmount AS BudgetAmount,
	|	BusinessBlocks.Ref.BudgetCurrency AS BudgetCurrency,
	|	ISNULL(BusinessBlockBalances.InitialRoomsInQuota, 0) AS InitialRoomsInQuota,
	|	ISNULL(BusinessBlockBalances.InitialBedsInQuota, 0) AS InitialBedsInQuota,
	|	ISNULL(BusinessBlockBalances.RoomsInQuota, 0) AS RoomsInQuota,
	|	ISNULL(BusinessBlockBalances.BedsInQuota, 0) AS BedsInQuota,
	|	ISNULL(BusinessBlockBalances.PickupRooms, 0) AS PickupRooms,
	|	ISNULL(BusinessBlockBalances.PickupBeds, 0) AS PickupBeds,
	|	ISNULL(BusinessBlockBalances.RoomsRemains, 0) AS RoomsRemains,
	|	ISNULL(BusinessBlockBalances.BedsInQuota, 0) AS BedsRemains,
	|	1 AS Counter
	|{SELECT
	|	Hotel.* AS Hotel,
	|	BusinessBlocks.Ref.* AS BusinessBlock,
	|	Code AS Code,
	|	Description AS Description,
	|	BusinessBlocks.Ref.SortCode AS SortCode,
	|	Status AS Status,
	|	AnnulationReason.* AS AnnulationReason,
	|	PeriodFrom AS PeriodFrom,
	|	PeriodTo AS PeriodTo,
	|	RoomRate.* AS RoomRate,
	|	CreateDate AS CreateDate,
	|	Author.* AS Author,
	|	MarketingCode.* AS MarketingCode,
	|	TripPurpose.* AS TripPurpose,
	|	SourceOfBusiness.* AS SourceOfBusiness,
	|	Remarks AS Remarks,
	|	BusinessBlocks.Ref.DateOfDef AS DateOfDef,
	|	BusinessBlocks.Ref.ReleaseDate AS ReleaseDate,
	|	BusinessBlocks.Ref.ReleaseTime AS ReleaseTime,
	|	DateOfAnnulation AS DateOfAnnulation,
	|	AuthorOfAnnulation.* AS AuthorOfAnnulation,
	|	Customer.* AS Customer,
	|	BusinessBlocks.Ref.Contract.* AS Contract,
	|	BusinessBlocks.Ref.Agent.* AS Agent,
	|	BusinessBlocks.Ref.Company.* AS Company,
	|	BusinessBlocks.Ref.ReservationManager.* AS ReservationManager,
	|	BusinessBlocks.Ref.MICEManager.* AS MICEManager,
	|	BusinessBlocks.Ref.RevenueManager.* AS RevenueManager,
	|	RoomNights AS RoomNights,
	|	BudgetADR AS BudgetADR,
	|	BudgetReservationAmount AS BudgetReservationAmount,
	|	BudgetMICEAmount AS BudgetMICEAmount,
	|	BudgetAmount AS BudgetAmount,
	|	BudgetCurrency AS BudgetCurrency,
	|	InitialRoomsInQuota,
	|	InitialBedsInQuota,
	|	RoomsInQuota,
	|	BedsInQuota,
	|	PickupRooms,
	|	PickupBeds,
	|	RoomsRemains,
	|	BedsRemains,
	|	Counter}
	|FROM
	|	BusinessBlocks AS BusinessBlocks
	|		LEFT JOIN BusinessBlockBalances AS BusinessBlockBalances
	|		ON BusinessBlocks.Ref.Hotel = BusinessBlockBalances.Hotel
	|			AND BusinessBlocks.Ref = BusinessBlockBalances.RoomQuota
	|WHERE
	|	(&qRoomType = VALUE(Catalog.RoomTypes.EmptyRef)
	|			OR BusinessBlocks.Ref IN
	|				(SELECT
	|					EffectiveBuisinessBlocks.RoomQuota
	|				FROM
	|					EffectiveBuisinessBlocks AS EffectiveBuisinessBlocks))
	|{WHERE
	|	BusinessBlocks.Ref.Hotel.* AS Hotel,
	|	BusinessBlocks.Ref.* AS BusinessBlock,
	|	BusinessBlocks.Ref.Code AS Code,
	|	BusinessBlocks.Ref.Description AS Description,
	|	BusinessBlocks.Ref.SortCode AS SortCode,
	|	BusinessBlocks.Ref.AllotmentType AS Status,
	|	BusinessBlocks.Ref.AnnulationReason.* AS AnnulationReason,
	|	BusinessBlocks.Ref.PeriodFrom AS PeriodFrom,
	|	BusinessBlocks.Ref.PeriodTo AS PeriodTo,
	|	BusinessBlocks.Ref.RoomRate.* AS RoomRate,
	|	BusinessBlocks.Ref.CreateDate AS CreateDate,
	|	BusinessBlocks.Ref.DateOfDef AS DateOfDef,
	|	BusinessBlocks.Ref.ReleaseDate AS ReleaseDate,
	|	BusinessBlocks.Ref.ReleaseTime AS ReleaseTime,
	|	BusinessBlocks.Ref.Author.* AS Author,
	|	BusinessBlocks.Ref.MarketingCode.* AS MarketingCode,
	|	BusinessBlocks.Ref.TripPurpose.* AS TripPurpose,
	|	BusinessBlocks.Ref.SourceOfBusiness.* AS SourceOfBusiness,
	|	BusinessBlocks.Ref.Remarks AS Remarks,
	|	BusinessBlocks.Ref.DateOfAnnulation AS DateOfAnnulation,
	|	BusinessBlocks.Ref.AuthorOfAnnulation.* AS AuthorOfAnnulation,
	|	BusinessBlocks.Ref.Customer.* AS Customer,
	|	BusinessBlocks.Ref.Contract.* AS Contract,
	|	BusinessBlocks.Ref.Agent.* AS Agent,
	|	BusinessBlocks.Ref.ReservationManager.* AS ReservationManager,
	|	BusinessBlocks.Ref.MICEManager.* AS MICEManager,
	|	BusinessBlocks.Ref.RevenueManager.* AS RevenueManager,
	|	BusinessBlocks.Ref.RoomNights AS RoomNights,
	|	BusinessBlocks.Ref.BudgetADR AS BudgetADR,
	|	BusinessBlocks.Ref.BudgetReservationAmount AS BudgetReservationAmount,
	|	BusinessBlocks.Ref.BudgetMICEAmount AS BudgetMICEAmount,
	|	BusinessBlocks.Ref.BudgetAmount AS BudgetAmount,
	|	BusinessBlocks.Ref.BudgetCurrency AS BudgetCurrency,
	|	(ISNULL(BusinessBlockBalances.InitialRoomsInQuota, 0)) AS InitialRoomsInQuota,
	|	(ISNULL(BusinessBlockBalances.InitialBedsInQuota, 0)) AS InitialBedsInQuota,
	|	(ISNULL(BusinessBlockBalances.RoomsInQuota, 0)) AS RoomsInQuota,
	|	(ISNULL(BusinessBlockBalances.BedsInQuota, 0)) AS BedsInQuota,
	|	(ISNULL(BusinessBlockBalances.PickupRooms, 0)) AS PickupRooms,
	|	(ISNULL(BusinessBlockBalances.PickupBeds, 0)) AS PickupBeds,
	|	(ISNULL(BusinessBlockBalances.RoomsRemains, 0)) AS RoomsRemains,
	|	(ISNULL(BusinessBlockBalances.BedsInQuota, 0)) AS BedsRemains,
	|	BusinessBlocks.Ref.Company.* AS Company}
	|
	|ORDER BY
	|	Hotel,
	|	PeriodFrom,
	|	PeriodTo,
	|	BusinessBlocks.Ref.SortCode,
	|	Description
	|{ORDER BY
	|	Hotel.* AS Hotel,
	|	BusinessBlocks.Ref.* AS BusinessBlock,
	|	Code AS Code,
	|	Description AS Description,
	|	BusinessBlocks.Ref.SortCode AS SortCode,
	|	Status AS Status,
	|	AnnulationReason.* AS AnnulationReason,
	|	PeriodFrom AS PeriodFrom,
	|	PeriodTo AS PeriodTo,
	|	RoomRate.* AS RoomRate,
	|	CreateDate AS CreateDate,
	|	BusinessBlocks.Ref.DateOfDef AS DateOfDef,
	|	BusinessBlocks.Ref.ReleaseDate AS ReleaseDate,
	|	BusinessBlocks.Ref.ReleaseTime AS ReleaseTime,
	|	Author.* AS Author,
	|	MarketingCode.* AS MarketingCode,
	|	TripPurpose.* AS TripPurpose,
	|	SourceOfBusiness.* AS SourceOfBusiness,
	|	Remarks AS Remarks,
	|	DateOfAnnulation AS DateOfAnnulation,
	|	AuthorOfAnnulation.* AS AuthorOfAnnulation,
	|	Customer.* AS Customer,
	|	BusinessBlocks.Ref.Contract.* AS Contract,
	|	BusinessBlocks.Ref.Agent.* AS Agent,
	|	BusinessBlocks.Ref.ReservationManager.* AS ReservationManager,
	|	BusinessBlocks.Ref.MICEManager.* AS MICEManager,
	|	BusinessBlocks.Ref.RevenueManager.* AS RevenueManager,
	|	RoomNights AS RoomNights,
	|	BudgetADR AS BudgetADR,
	|	BudgetReservationAmount AS BudgetReservationAmount,
	|	BudgetMICEAmount AS BudgetMICEAmount,
	|	BudgetAmount AS BudgetAmount,
	|	BudgetCurrency AS BudgetCurrency,
	|	InitialRoomsInQuota,
	|	InitialBedsInQuota,
	|	RoomsInQuota,
	|	BedsInQuota,
	|	PickupRooms,
	|	PickupBeds,
	|	RoomsRemains,
	|	BedsRemains,
	|	BusinessBlocks.Ref.Company.* AS Company}
	|TOTALS
	|	SUM(RoomNights),
	|	SUM(BudgetReservationAmount),
	|	SUM(BudgetMICEAmount),
	|	SUM(BudgetAmount),
	|	SUM(InitialRoomsInQuota),
	|	SUM(InitialBedsInQuota),
	|	SUM(RoomsInQuota),
	|	SUM(BedsInQuota),
	|	SUM(PickupRooms),
	|	SUM(PickupBeds),
	|	SUM(RoomsRemains),
	|	SUM(BedsRemains),
	|	SUM(Counter)
	|BY
	|	OVERALL
	|{TOTALS BY
	|	Hotel.* AS Hotel,
	|	BusinessBlocks.Ref.* AS BusinessBlock,
	|	Status AS Status,
	|	AnnulationReason.* AS AnnulationReason,
	|	RoomRate.* AS RoomRate,
	|	(BEGINOFPERIOD(BusinessBlocks.Ref.CreateDate, DAY)) AS CreateDate,
	|	Author.* AS Author,
	|	MarketingCode.* AS MarketingCode,
	|	TripPurpose.* AS TripPurpose,
	|	SourceOfBusiness.* AS SourceOfBusiness,
	|	(BEGINOFPERIOD(BusinessBlocks.Ref.DateOfAnnulation, DAY)) AS DateOfAnnulation,
	|	AuthorOfAnnulation.* AS AuthorOfAnnulation,
	|	BusinessBlocks.Ref.DateOfDef AS DateOfDef,
	|	BusinessBlocks.Ref.ReleaseDate AS ReleaseDate,
	|	BusinessBlocks.Ref.ReleaseTime AS ReleaseTime,
	|	Customer.* AS Customer,
	|	BusinessBlocks.Ref.Contract.* AS Contract,
	|	BusinessBlocks.Ref.Agent.* AS Agent,
	|	BusinessBlocks.Ref.ReservationManager.* AS ReservationManager,
	|	BusinessBlocks.Ref.MICEManager.* AS MICEManager,
	|	BusinessBlocks.Ref.RevenueManager.* AS RevenueManager,
	|	BusinessBlocks.Ref.Company.* AS Company}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("en='Business blocks history'; ru='История бизнес-блоков'; de='Geschichte der Geschäftsblöcke'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
