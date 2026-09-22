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
	If ValueIsFilled(RoomType) Then
		If Not RoomType.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Room type ';ru='Тип номер ';de='Zimmertyp '") + 
			                     TrimAll(RoomType.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Room types folder ';ru='Группа типов номеров ';de='Zimmertypgruppe '") + 
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
	If ValueIsFilled(Service) Then
		If Not Service.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Service ';ru='Услуга ';de='Dienstleistung '") + 
			                     TrimAll(Service.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа услуг '; en = 'Services folder '; de = 'Dienstleistungengruppe '") + 
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
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа наборов услуг '; en = 'Service groups folder '; de = 'Dienstgruppengruppe '") + 
			                     TrimAll(ServiceGroup.Description) + 
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
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qService", Service);
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qRoomIsEmpty", Not ValueIsFilled(Room));
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qRoomTypeIsEmpty", Not ValueIsFilled(RoomType));
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
	ReportBuilder.Parameters.Insert("qEmptyCountry", Catalogs.Countries.EmptyRef());
	ReportBuilder.Parameters.Insert("qEmptyString", "");
	ReportBuilder.Parameters.Insert("qEmptyResource", Catalogs.Resources.EmptyRef());
	
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
	|	ServiceSales.Company AS Company,
	|	ServiceSales.Hotel AS Hotel,
	|	ServiceSales.ReportingCurrency AS ReportingCurrency,
	|	ServiceSales.Service AS Service,
	|	ServiceSales.AccountingDate AS AccountingDate,
	|	ServiceSales.ServiceDate AS ServiceDate,
	|	ServiceSales.Room AS Room,
	|	ServiceSales.Customer AS Customer,
	|	ServiceSales.Client AS Client,
	|	ServiceSales.Recorder AS Recorder,
	|	ServiceSales.ParentDoc AS ParentDoc,
	|	ServiceSales.Price AS Price,
	|	ServiceSales.Quantity AS Quantity,
	|	ServiceSales.Sales AS Sum,
	|	ServiceSales.FullSales AS SumBeforeDiscount,
	|	ServiceSales.Sales - ServiceSales.CommissionSum AS SumWithoutCommission,
	|	ServiceSales.SalesWithoutVAT AS SumWithoutVAT,
	|	ServiceSales.CommissionSum AS CommissionSum,
	|	ServiceSales.CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|	ServiceSales.DiscountSum AS DiscountSum,
	|	ServiceSales.DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|	ServiceSales.VATSum AS VATSum,
	|	ServiceSales.RateSum AS RateSum,
	|	ServiceSales.IsStorno AS IsStorno,
	|	ServiceSales.Author AS Author,
	|	ServiceSales.Period AS Period
	|{SELECT
	|	Period,
	|	Company.*,
	|	Hotel.*,
	|	ReportingCurrency.*,
	|	Service.*,
	|	AccountingDate,
	|	ServiceDate,
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
	|	ServiceSales.Remarks AS Remarks,
	|	Recorder.*,
	|	ParentDoc.*,
	|	ServiceSales.BoardPlace.*,
	|	ServiceSales.GuestGroup.*,
	|	ServiceSales.TripPurpose.*,
	|	ServiceSales.ServicePackage.*,
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
	|	ServiceSales.Performer.* AS Performer,
	|	IsStorno,
	|	ServiceSales.IsRoomRevenue AS IsRoomRevenue,
	|	ServiceSales.IsResourceRevenue AS IsResourceRevenue,
	|	Quantity,
	|	Sum,
	|	SumBeforeDiscount,
	|	SumWithoutCommission,
	|	SumWithoutVAT,
	|	CommissionSum,
	|	CommissionSumWithoutVAT,
	|	DiscountSum,
	|	DiscountSumWithoutVAT,
	|	VATSum,
	|	RateSum}
	|FROM
	|	(SELECT
	|		ServiceSalesMovements.Period AS Period,
	|		ServiceSalesMovements.ServiceDate AS ServiceDate,
	|		ServiceSalesMovements.Company AS Company,
	|		ServiceSalesMovements.Hotel AS Hotel,
	|		ServiceSalesMovements.ReportingCurrency AS ReportingCurrency,
	|		ServiceSalesMovements.Service AS Service,
	|		ServiceSalesMovements.AccountingDate AS AccountingDate,
	|		ServiceSalesMovements.Price AS Price,
	|		ServiceSalesMovements.Room AS Room,
	|		ServiceSalesMovements.Resource AS Resource,
	|		ServiceSalesMovements.Agent AS Agent,
	|		ServiceSalesMovements.Customer AS Customer,
	|		ServiceSalesMovements.Contract AS Contract,
	|		ServiceSalesMovements.ClientType AS ClientType,
	|		ServiceSalesMovements.MarketingCode AS MarketingCode,
	|		ServiceSalesMovements.SourceOfBusiness AS SourceOfBusiness,
	|		ServiceSalesMovements.Client AS Client,
	|		ServiceSalesMovements.Folio AS Folio,
	|		ServiceSalesMovements.Recorder.Remarks AS Remarks,
	|		ServiceSalesMovements.Recorder AS Recorder,
	|		ServiceSalesMovements.ParentDoc AS ParentDoc,
	|		CASE
	|			WHEN NOT ServiceSalesMovements.BoardPlace.Code IS NULL
	|				THEN ServiceSalesMovements.BoardPlace
	|			WHEN ISNULL(ServiceSalesMovements.Service.Resource.IsBoardPlace, FALSE)
	|				THEN ServiceSalesMovements.Service.Resource
	|			ELSE &qEmptyResource
	|		END AS BoardPlace,
	|		ServiceSalesMovements.GuestGroup AS GuestGroup,
	|		ServiceSalesMovements.TripPurpose AS TripPurpose,
	|		ServiceSalesMovements.ServicePackage AS ServicePackage,
	|		ISNULL(ServiceSalesMovements.Client.Age, 0) AS ClientAge,
	|		ISNULL(ServiceSalesMovements.Client.Citizenship, &qEmptyCountry) AS ClientCitizenship,
	|		ISNULL(ServiceSalesMovements.Client.Region, &qEmptyString) AS ClientRegion,
	|		ISNULL(ServiceSalesMovements.Client.City, &qEmptyString) AS ClientCity,
	|		ServiceSalesMovements.NumberOfAdditionalBeds AS NumberOfAdditionalBeds,
	|		ServiceSalesMovements.NumberOfBeds AS NumberOfBeds,
	|		ServiceSalesMovements.NumberOfBedsPerRoom AS NumberOfBedsPerRoom,
	|		ServiceSalesMovements.NumberOfPersons AS NumberOfPersons,
	|		ServiceSalesMovements.NumberOfPersonsPerRoom AS NumberOfPersonsPerRoom,
	|		ServiceSalesMovements.NumberOfRooms AS NumberOfRooms,
	|		ServiceSalesMovements.VATRate AS VATRate,
	|		ServiceSalesMovements.RoomType AS RoomType,
	|		ServiceSalesMovements.RoomRateType AS RoomRateType,
	|		ServiceSalesMovements.RoomRate AS RoomRate,
	|		ServiceSalesMovements.PointInTime AS PointInTime,
	|		ServiceSalesMovements.Author AS Author,
	|		CASE
	|			WHEN ServiceSalesMovements.Recorder.Performer IS NULL
	|				THEN ServiceSalesMovements.Recorder.ParentCharge.Performer
	|			ELSE ServiceSalesMovements.Recorder.Performer
	|		END AS Performer,
	|		ServiceSalesMovements.IsStorno AS IsStorno,
	|		CASE
	|			WHEN ServiceSalesMovements.Recorder.IsRoomRevenue IS NULL
	|				THEN ServiceSalesMovements.Recorder.ParentCharge.IsRoomRevenue
	|			ELSE ServiceSalesMovements.Recorder.IsRoomRevenue
	|		END AS IsRoomRevenue,
	|		CASE
	|			WHEN ServiceSalesMovements.Recorder.IsResourceRevenue IS NULL
	|				THEN ServiceSalesMovements.Recorder.ParentCharge.IsResourceRevenue
	|			ELSE ServiceSalesMovements.Recorder.IsResourceRevenue
	|		END AS IsResourceRevenue,
	|		ServiceSalesMovements.Quantity AS Quantity,
	|		ServiceSalesMovements.Sales AS Sales,
	|		ServiceSalesMovements.SalesWithoutVAT AS SalesWithoutVAT,
	|		ServiceSalesMovements.CommissionSum AS CommissionSum,
	|		ServiceSalesMovements.CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|		ServiceSalesMovements.DiscountSum AS DiscountSum,
	|		ServiceSalesMovements.DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|		ServiceSalesMovements.Sales + ServiceSalesMovements.DiscountSum AS FullSales,
	|		ServiceSalesMovements.VATSum AS VATSum,
	|		ServiceSalesMovements.RateSum AS RateSum
	|	FROM
	|		AccumulationRegister.Sales AS ServiceSalesMovements
	|	WHERE
	|		NOT ServiceSalesMovements.IsCorrection
	|		AND ServiceSalesMovements.Hotel IN HIERARCHY(&qHotel)
	|		AND ServiceSalesMovements.Period BETWEEN &qPeriodFrom AND &qPeriodTo
	|		AND ServiceSalesMovements.Service IN HIERARCHY(&qService)
	|		AND (ServiceSalesMovements.RoomType IN HIERARCHY (&qRoomType)
	|				OR &qRoomTypeIsEmpty)
	|		AND (ServiceSalesMovements.Room IN HIERARCHY (&qRoom)
	|				OR &qRoomIsEmpty)
	|		AND (ServiceSalesMovements.Service IN (&qServicesList)
	|				OR NOT &qUseServicesList)) AS ServiceSales
	|{WHERE
	|	ServiceSales.Period,
	|	ServiceSales.ServiceDate,
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
	|	ServiceSales.Recorder.Remarks AS Remarks,
	|	ServiceSales.BoardPlace.*,
	|	ServiceSales.GuestGroup.*,
	|	ServiceSales.Client.*,
	|	ServiceSales.TripPurpose.*,
	|	ServiceSales.ServicePackage.*,
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
	|	ServiceSales.IsStorno,
	|	ServiceSales.IsRoomRevenue AS IsRoomRevenue,
	|	ServiceSales.IsResourceRevenue AS IsResourceRevenue,
	|	ServiceSales.Customer.*,
	|	ServiceSales.Contract.*,
	|	ServiceSales.RoomType.*,
	|	ServiceSales.Author.*,
	|	ServiceSales.Performer.* AS Performer,
	|	ServiceSales.RoomRateType.*,
	|	ServiceSales.RoomRate.*,
	|	ServiceSales.Quantity,
	|	ServiceSales.Sales AS Sum,
	|	ServiceSales.SalesWithoutVAT AS SumWithoutVAT,
	|	ServiceSales.CommissionSum,
	|	ServiceSales.CommissionSumWithoutVAT,
	|	ServiceSales.DiscountSum,
	|	ServiceSales.DiscountSumWithoutVAT,
	|	ServiceSales.VATSum,
	|	ServiceSales.RateSum}
	|
	|ORDER BY
	|	ReportingCurrency,
	|	Hotel,
	|	Service,
	|	Period
	|{ORDER BY
	|	Period,
	|	ServiceDate,
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
	|	ServiceSales.BoardPlace.*,
	|	ServiceSales.GuestGroup.*,
	|	Client.*,
	|	ServiceSales.TripPurpose.*,
	|	ServiceSales.ServicePackage.*,
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
	|	IsStorno,
	|	ServiceSales.IsRoomRevenue AS IsRoomRevenue,
	|	ServiceSales.IsResourceRevenue AS IsResourceRevenue,
	|	Customer.*,
	|	ServiceSales.Contract.*,
	|	ServiceSales.RoomType.*,
	|	Author.*,
	|	ServiceSales.Performer.* AS Performer,
	|	ServiceSales.RoomRateType.*,
	|	ServiceSales.RoomRate.*,
	|	VATSum,
	|	Sum,
	|	SumWithoutCommission,
	|	SumWithoutVAT}
	|TOTALS
	|	SUM(Quantity),
	|	SUM(Sum),
	|	SUM(SumBeforeDiscount),
	|	SUM(SumWithoutCommission),
	|	SUM(SumWithoutVAT),
	|	SUM(CommissionSum),
	|	SUM(CommissionSumWithoutVAT),
	|	SUM(DiscountSum),
	|	SUM(DiscountSumWithoutVAT),
	|	SUM(VATSum),
	|	SUM(RateSum)
	|BY
	|	OVERALL,
	|	ReportingCurrency,
	|	Hotel,
	|	Service
	|{TOTALS BY
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
	|	ServiceDate,
	|	ParentDoc.*,
	|	ServiceSales.Folio.*,
	|	ServiceSales.BoardPlace.*,
	|	ServiceSales.GuestGroup.*,
	|	Client.*,
	|	ServiceSales.TripPurpose.*,
	|	ServiceSales.ServicePackage.*,
	|	ServiceSales.ClientAge AS ClientAge,
	|	ServiceSales.ClientCitizenship.* AS ClientCitizenship,
	|	ServiceSales.ClientRegion AS ClientRegion,
	|	ServiceSales.ClientCity AS ClientCity,
	|	Room.*,
	|	ServiceSales.Resource.*,
	|	ServiceSales.VATRate.*,
	|	ServiceSales.Agent.*,
	|	IsStorno,
	|	ServiceSales.IsRoomRevenue AS IsRoomRevenue,
	|	ServiceSales.IsResourceRevenue AS IsResourceRevenue,
	|	Customer.*,
	|	ServiceSales.Contract.*,
	|	ServiceSales.RoomType.*,
	|	Author.*,
	|	ServiceSales.Performer.* AS Performer,
	|	ServiceSales.RoomRateType.*,
	|	ServiceSales.RoomRate.*}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("en='Services sales';ru='Сводка по оказанным услугам';de='Bericht zu erbrachten Dienstleistungen'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
