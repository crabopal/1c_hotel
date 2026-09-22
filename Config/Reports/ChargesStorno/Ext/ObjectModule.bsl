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
		                     Format(PeriodFrom, "DF='dd.MM.yyyy HH:mm:ss'") + 
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
	If ValueIsFilled(Service) Then
		If Not Service.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Service ';ru='Услуга ';de='Dienstleistung '") + 
			                     TrimAll(Service.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа услуг '; en = 'Services folder '; de = 'Gruppe Dienstleistungen '") + 
			                     TrimAll(Service.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;					 
	If ValueIsFilled(ServiceGroup) Then
		If Not ServiceGroup.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Набор услуг '; en = 'Service group '; de = 'Dienstgruppe '") + 
			                     TrimAll(ServiceGroup.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа наборов услуг '; en = 'Service groups folder '; de = 'Gruppe Dienstgruppen '") + 
			                     TrimAll(ServiceGroup.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;					 
	If ValueIsFilled(Employee) Then
		If Not Employee.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Employee ';ru='Сотрудник ';de='Mitarbeiter '") + 
			                     TrimAll(Employee) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа сотрудников '; en = 'Employees folder '; de = 'Gruppe Mitarbeiteren '") + 
			                     TrimAll(Employee) + 
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
	ReportBuilder.Parameters.Insert("qEmployee", Employee);
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qService", Service);
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qRoomIsEmpty", Not ValueIsFilled(Room));
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
	|	ServiceSales.Period AS Period,
	|	ServiceSales.TypeOfStorno AS TypeOfStorno,
	|	ServiceSales.Company AS Company,
	|	ServiceSales.Hotel AS Hotel,
	|	ServiceSales.ReportingCurrency AS ReportingCurrency,
	|	ServiceSales.Service AS Service,
	|	ServiceSales.AccountingDate AS AccountingDate,
	|	ServiceSales.Room AS Room,
	|	ServiceSales.Customer,
	|	ServiceSales.Client AS Client,
	|	ServiceSales.Recorder,
	|	ServiceSales.ParentDoc,
	|	ServiceSales.Price,
	|	ServiceSales.Quantity AS Quantity,
	|	ServiceSales.Sum AS Sum,
	|	ServiceSales.SumWithoutVAT AS SumWithoutVAT,
	|	ServiceSales.CommissionSum AS CommissionSum,
	|	ServiceSales.CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|	ServiceSales.DiscountSum AS DiscountSum,
	|	ServiceSales.DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|	1 AS NumberOfStornos,
	|	ServiceSales.Author
	|{SELECT
	|	Period,
	|	TypeOfStorno,
	|	Company.*,
	|	Hotel.*,
	|	ReportingCurrency.*,
	|	Service.*,
	|	AccountingDate,
	|	Price,
	|	Room.*,
	|	ServiceSales.Resource.*,
	|	ServiceSales.Agent.*,
	|	Customer.*,
	|	ServiceSales.Contract.*,
	|	ServiceSales.ClientType.*,
	|	ServiceSales.MarketingCode.*,
	|	ServiceSales.SourceOfBusiness.*,
	|	Client.*,
	|	ServiceSales.Folio.*,
	|	Recorder.*,
	|	ParentDoc.*,
	|	ServiceSales.GuestGroup.*,
	|	ServiceSales.TripPurpose.*,
	|	ServiceSales.ClientAge AS ClientAge,
	|	ServiceSales.ClientCitizenship.* AS ClientCitizenship,
	|	ServiceSales.ClientRegion AS ClientRegion,
	|	ServiceSales.ClientCity AS ClientCity,
	|	ServiceSales.NumberOfAdditionalBeds,
	|	ServiceSales.NumberOfBeds,
	|	ServiceSales.NumberOfBedsPerRoom,
	|	ServiceSales.NumberOfPersons,
	|	ServiceSales.NumberOfPersonsPerRoom,
	|	ServiceSales.NumberOfRooms,
	|	ServiceSales.VATRate.*,
	|	ServiceSales.RoomType.*,
	|	ServiceSales.RoomRateType.*,
	|	ServiceSales.RoomRate.*,
	|	ServiceSales.PointInTime,
	|	Author.*,
	|	(NULL) AS EmptyColumn,
	|	Quantity,
	|	Sum,
	|	SumWithoutVAT,
	|	CommissionSum,
	|	CommissionSumWithoutVAT,
	|	DiscountSum,
	|	DiscountSumWithoutVAT,
	|	NumberOfStornos}
	|FROM
	|	(SELECT
	|		SalesStorno.Period AS Period,
	|		SalesStorno.Recorder.TypeOfStorno AS TypeOfStorno,
	|		SalesStorno.Company AS Company,
	|		SalesStorno.Hotel AS Hotel,
	|		SalesStorno.ReportingCurrency AS ReportingCurrency,
	|		SalesStorno.Service AS Service,
	|		SalesStorno.AccountingDate AS AccountingDate,
	|		SalesStorno.Price AS Price,
	|		SalesStorno.Room AS Room,
	|		SalesStorno.Resource AS Resource,
	|		SalesStorno.Agent AS Agent,
	|		SalesStorno.Customer AS Customer,
	|		SalesStorno.Contract AS Contract,
	|		SalesStorno.ClientType AS ClientType,
	|		SalesStorno.MarketingCode AS MarketingCode,
	|		SalesStorno.SourceOfBusiness AS SourceOfBusiness,
	|		SalesStorno.Client AS Client,
	|		SalesStorno.Folio AS Folio,
	|		SalesStorno.Recorder AS Recorder,
	|		SalesStorno.ParentDoc AS ParentDoc,
	|		SalesStorno.GuestGroup AS GuestGroup,
	|		SalesStorno.TripPurpose AS TripPurpose,
	|		SalesStorno.Client.Age AS ClientAge,
	|		SalesStorno.Client.Citizenship AS ClientCitizenship,
	|		SalesStorno.Client.Region AS ClientRegion,
	|		SalesStorno.Client.City AS ClientCity,
	|		SalesStorno.NumberOfAdditionalBeds AS NumberOfAdditionalBeds,
	|		SalesStorno.NumberOfBeds AS NumberOfBeds,
	|		SalesStorno.NumberOfBedsPerRoom AS NumberOfBedsPerRoom,
	|		SalesStorno.NumberOfPersons AS NumberOfPersons,
	|		SalesStorno.NumberOfPersonsPerRoom AS NumberOfPersonsPerRoom,
	|		SalesStorno.NumberOfRooms AS NumberOfRooms,
	|		SalesStorno.VATRate AS VATRate,
	|		SalesStorno.RoomType AS RoomType,
	|		SalesStorno.RoomRateType AS RoomRateType,
	|		SalesStorno.RoomRate AS RoomRate,
	|		SalesStorno.PointInTime AS PointInTime,
	|		SalesStorno.Author AS Author,
	|		-SalesStorno.Quantity AS Quantity,
	|		-SalesStorno.Sales AS Sum,
	|		-SalesStorno.SalesWithoutVAT AS SumWithoutVAT,
	|		-SalesStorno.CommissionSum AS CommissionSum,
	|		-SalesStorno.CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|		-SalesStorno.DiscountSum AS DiscountSum,
	|		-SalesStorno.DiscountSumWithoutVAT AS DiscountSumWithoutVAT
	|	FROM
	|		AccumulationRegister.Sales AS SalesStorno
	|	WHERE
	|		SalesStorno.IsStorno
	|		AND SalesStorno.Author IN HIERARCHY(&qEmployee)
	|		AND SalesStorno.Hotel IN HIERARCHY(&qHotel)
	|		AND SalesStorno.Period BETWEEN &qPeriodFrom AND &qPeriodTo
	|		AND SalesStorno.Service IN HIERARCHY(&qService)
	|		AND (SalesStorno.Room IN HIERARCHY (&qRoom)
	|				OR &qRoomIsEmpty)
	|		AND (SalesStorno.Service IN (&qServicesList)
	|				OR NOT &qUseServicesList)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ChargeDeleteEvents.Period,
	|		NULL,
	|		ChargeDeleteEvents.Charge.Company,
	|		ChargeDeleteEvents.Charge.Hotel,
	|		ChargeDeleteEvents.Charge.Hotel.ReportingCurrency,
	|		ChargeDeleteEvents.Charge.Service,
	|		BEGINOFPERIOD(ChargeDeleteEvents.Period, DAY),
	|		ChargeDeleteEvents.Charge.Price,
	|		ChargeDeleteEvents.Charge.Room,
	|		ChargeDeleteEvents.Charge.Resource,
	|		ChargeDeleteEvents.Charge.Folio.Agent,
	|		ChargeDeleteEvents.Charge.Folio.Customer,
	|		ChargeDeleteEvents.Charge.Folio.Contract,
	|		ChargeDeleteEvents.Charge.ClientType,
	|		ChargeDeleteEvents.Charge.MarketingCode,
	|		ChargeDeleteEvents.Charge.SourceOfBusiness,
	|		ChargeDeleteEvents.Charge.Folio.Client,
	|		ChargeDeleteEvents.Charge.Folio,
	|		ChargeDeleteEvents.Charge,
	|		ChargeDeleteEvents.Charge.ParentDoc,
	|		ChargeDeleteEvents.Charge.Folio.GuestGroup,
	|		ChargeDeleteEvents.Charge.ParentDoc.TripPurpose,
	|		ChargeDeleteEvents.Charge.Folio.Client.Age,
	|		ChargeDeleteEvents.Charge.Folio.Client.Citizenship,
	|		ChargeDeleteEvents.Charge.Folio.Client.Region,
	|		ChargeDeleteEvents.Charge.Folio.Client.City,
	|		ISNULL(ChargeDeleteEvents.Charge.ParentDoc.NumberOfAdditionalBeds, 0),
	|		ISNULL(ChargeDeleteEvents.Charge.ParentDoc.NumberOfBeds, 0),
	|		ISNULL(ChargeDeleteEvents.Charge.ParentDoc.NumberOfBedsPerRoom, 0),
	|		ISNULL(ChargeDeleteEvents.Charge.ParentDoc.NumberOfPersons, 0),
	|		ISNULL(ChargeDeleteEvents.Charge.ParentDoc.NumberOfPersonsPerRoom, 0),
	|		ISNULL(ChargeDeleteEvents.Charge.ParentDoc.NumberOfRooms, 0),
	|		ChargeDeleteEvents.Charge.VATRate,
	|		ChargeDeleteEvents.Charge.RoomType,
	|		ChargeDeleteEvents.Charge.RoomRate.RoomRateType,
	|		ChargeDeleteEvents.Charge.RoomRate,
	|		ChargeDeleteEvents.Period,
	|		ChargeDeleteEvents.User,
	|		ChargeDeleteEvents.Charge.Quantity,
	|		ChargeDeleteEvents.Charge.Sum,
	|		ChargeDeleteEvents.Charge.Sum - ChargeDeleteEvents.Charge.VATSum,
	|		ChargeDeleteEvents.Charge.CommissionSum,
	|		ChargeDeleteEvents.Charge.CommissionSum - ChargeDeleteEvents.Charge.VATCommissionSum,
	|		ChargeDeleteEvents.Charge.DiscountSum,
	|		ChargeDeleteEvents.Charge.DiscountSum - ChargeDeleteEvents.Charge.VATDiscountSum
	|	FROM
	|		InformationRegister.ChargeDeleteEvents AS ChargeDeleteEvents
	|	WHERE
	|		ChargeDeleteEvents.User IN HIERARCHY(&qEmployee)
	|		AND ChargeDeleteEvents.Hotel IN HIERARCHY(&qHotel)
	|		AND ChargeDeleteEvents.Period BETWEEN &qPeriodFrom AND &qPeriodTo
	|		AND ChargeDeleteEvents.Charge.Service IN HIERARCHY(&qService)
	|		AND (ChargeDeleteEvents.Charge.Room IN HIERARCHY (&qRoom)
	|				OR &qRoomIsEmpty)
	|		AND (ChargeDeleteEvents.Charge.Service IN (&qServicesList)
	|				OR NOT &qUseServicesList)) AS ServiceSales
	|{WHERE
	|	ServiceSales.TypeOfStorno AS TypeOfStorno,
	|	ServiceSales.Period,
	|	ServiceSales.Recorder.*,
	|	ServiceSales.ReportingCurrency.*,
	|	ServiceSales.Hotel.*,
	|	ServiceSales.Service.*,
	|	ServiceSales.Price,
	|	ServiceSales.ClientType.*,
	|	ServiceSales.MarketingCode.*,
	|	ServiceSales.SourceOfBusiness.*,
	|	ServiceSales.Company.*,
	|	ServiceSales.AccountingDate,
	|	ServiceSales.ParentDoc.*,
	|	ServiceSales.Folio.*,
	|	ServiceSales.GuestGroup.*,
	|	ServiceSales.Client.*,
	|	ServiceSales.TripPurpose.*,
	|	ServiceSales.ClientAge AS ClientAge,
	|	ServiceSales.ClientCitizenship.* AS ClientCitizenship,
	|	ServiceSales.ClientRegion AS ClientRegion,
	|	ServiceSales.ClientCity AS ClientCity,
	|	ServiceSales.NumberOfAdditionalBeds,
	|	ServiceSales.NumberOfBeds,
	|	ServiceSales.NumberOfBedsPerRoom,
	|	ServiceSales.NumberOfPersons,
	|	ServiceSales.NumberOfPersonsPerRoom,
	|	ServiceSales.NumberOfRooms,
	|	ServiceSales.Room.*,
	|	ServiceSales.Resource.*,
	|	ServiceSales.VATRate.*,
	|	ServiceSales.Agent.*,
	|	ServiceSales.Customer.*,
	|	ServiceSales.Contract.*,
	|	ServiceSales.RoomType.*,
	|	ServiceSales.Author.*,
	|	ServiceSales.RoomRateType.*,
	|	ServiceSales.RoomRate.*,
	|	ServiceSales.Quantity AS Quantity,
	|	ServiceSales.Sum AS Sum,
	|	ServiceSales.SumWithoutVAT AS SumWithoutVAT,
	|	ServiceSales.CommissionSum AS CommissionSum,
	|	ServiceSales.CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|	ServiceSales.DiscountSum AS DiscountSum,
	|	ServiceSales.DiscountSumWithoutVAT AS DiscountSumWithoutVAT}
	|
	|ORDER BY
	|	ReportingCurrency,
	|	Hotel,
	|	Service,
	|	ServiceSales.Period
	|{ORDER BY
	|	TypeOfStorno,
	|	ServiceSales.Period,
	|	ReportingCurrency.*,
	|	Hotel.*,
	|	Service.*,
	|	Price,
	|	ServiceSales.ClientType.*,
	|	ServiceSales.SourceOfBusiness.*,
	|	Company.*,
	|	AccountingDate,
	|	Recorder.*,
	|	ParentDoc.*,
	|	ServiceSales.Folio.*,
	|	ServiceSales.GuestGroup.*,
	|	Client.*,
	|	ServiceSales.TripPurpose.*,
	|	ServiceSales.ClientAge AS ClientAge,
	|	ServiceSales.ClientCitizenship.* AS ClientCitizenship,
	|	ServiceSales.ClientRegion AS ClientRegion,
	|	ServiceSales.ClientCity AS ClientCity,
	|	ServiceSales.NumberOfAdditionalBeds,
	|	ServiceSales.NumberOfBeds,
	|	ServiceSales.NumberOfBedsPerRoom,
	|	ServiceSales.NumberOfPersonsPerRoom,
	|	ServiceSales.NumberOfRooms,
	|	Room.*,
	|	ServiceSales.Resource.*,
	|	ServiceSales.VATRate.*,
	|	ServiceSales.Agent.*,
	|	Customer.*,
	|	ServiceSales.Contract.*,
	|	ServiceSales.RoomType.*,
	|	Author.*,
	|	ServiceSales.RoomRateType.*,
	|	ServiceSales.RoomRate.*}
	|TOTALS
	|	SUM(Quantity),
	|	SUM(Sum),
	|	SUM(SumWithoutVAT),
	|	SUM(CommissionSum),
	|	SUM(CommissionSumWithoutVAT),
	|	SUM(DiscountSum),
	|	SUM(DiscountSumWithoutVAT),
	|	SUM(NumberOfStornos)
	|BY
	|	OVERALL,
	|	ReportingCurrency,
	|	Hotel,
	|	Service
	|{TOTALS BY
	|	TypeOfStorno,
	|	Recorder.*,
	|	ReportingCurrency.*,
	|	Hotel.*,
	|	Service.*,
	|	Price,
	|	ServiceSales.ClientType.*,
	|	ServiceSales.MarketingCode.*,
	|	ServiceSales.SourceOfBusiness.*,
	|	Company.*,
	|	AccountingDate,
	|	ParentDoc.*,
	|	ServiceSales.Folio.*,
	|	ServiceSales.GuestGroup.*,
	|	Client.*,
	|	ServiceSales.TripPurpose.*,
	|	ServiceSales.ClientAge AS ClientAge,
	|	ServiceSales.ClientCitizenship.* AS ClientCitizenship,
	|	ServiceSales.ClientRegion AS ClientRegion,
	|	ServiceSales.ClientCity AS ClientCity,
	|	Room.*,
	|	ServiceSales.Resource.*,
	|	ServiceSales.VATRate.*,
	|	ServiceSales.Agent.*,
	|	Customer.*,
	|	ServiceSales.Contract.*,
	|	ServiceSales.RoomType.*,
	|	Author.*,
	|	ServiceSales.RoomRateType.*,
	|	ServiceSales.RoomRate.*}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Charges storno audit';RU='Аудит сторно начислений';de='Buchprüfung des Storno der Berechnungen'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
