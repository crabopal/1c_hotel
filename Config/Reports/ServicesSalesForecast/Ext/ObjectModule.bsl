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
	If ValueIsFilled(BoardPlace) Then
		If Not BoardPlace.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Место питания '; en = 'Board place '; de = 'Essenort '") + 
			                     TrimAll(BoardPlace.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа мест питания '; en = 'Board places folder '; de = 'Essenortgruppe '") + 
			                     TrimAll(BoardPlace.Description) + 
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
	vForecastStartDate = tcOnServer.GetForecastStartDate(Hotel);
	ReportBuilder.Parameters.Insert("qForecastPeriodFrom", Max(BegOfDay(PeriodFrom), vForecastStartDate));
	ReportBuilder.Parameters.Insert("qForecastPeriodTo", ?(ValueIsFilled(PeriodTo), Max(PeriodTo, EndOfDay(vForecastStartDate-24*3600)), '00010101'));
	ReportBuilder.Parameters.Insert("qService", Service);
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qRoomTypeIsEmpty", Not ValueIsFilled(RoomType));
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
	ReportBuilder.Parameters.Insert("qEmptyResource", Catalogs.Resources.EmptyRef());
	ReportBuilder.Parameters.Insert("qRoundQuantityUp", RoundQuantityUp);
	ReportBuilder.Parameters.Insert("qEmptyDate", '00010101');
	ReportBuilder.Parameters.Insert("qHotelAccountingDate", vForecastStartDate);
	ReportBuilder.Parameters.Insert("qBoardPlace", BoardPlace);
	ReportBuilder.Parameters.Insert("qBoardPlaceIsEmpty", Not ValueIsFilled(BoardPlace));

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
	|	SalesForecast.Period AS Period,
	|	SalesForecast.Hotel AS Hotel,
	|	SalesForecast.Service AS Service,
	|	SalesForecast.Price AS Price,
	|	SalesForecast.Room AS Room,
	|	SalesForecast.RoomRate AS RoomRate,
	|	SalesForecast.Client AS Client,
	|	SalesForecast.Resource AS Resource,
	|	SalesForecast.TimeFrom AS TimeFrom,
	|	SalesForecast.TimeTo AS TimeTo,
	|	SalesForecast.Remarks AS Remarks,
	|	SalesForecast.Recorder AS Recorder,
	|	SalesForecast.ParentDoc AS ParentDoc,
	|	SalesForecast.IsStorno AS IsStorno,
	|	SalesForecast.ReportingCurrency AS ReportingCurrency,
	|	SalesForecast.Quantity AS Quantity,
	|	SalesForecast.QuantityAccommodation AS QuantityAccommodation,
	|	SalesForecast.QuantityReservation AS QuantityReservation,
	|	ISNULL(CASE
	|			WHEN SalesForecast.Recorder REFS Document.Charge
	|				THEN SalesForecast.ParentDoc.NumberOfAdults
	|			ELSE SalesForecast.Recorder.NumberOfAdults
	|		END, 0) AS NumberOfAdults,
	|	ISNULL(CASE
	|			WHEN SalesForecast.Recorder REFS Document.Charge
	|				THEN SalesForecast.ParentDoc.NumberOfTeenagers
	|			ELSE SalesForecast.Recorder.NumberOfTeenagers
	|		END, 0) AS NumberOfTeenagers,
	|	ISNULL(CASE
	|			WHEN SalesForecast.Recorder REFS Document.Charge
	|				THEN SalesForecast.ParentDoc.NumberOfChildren
	|			ELSE SalesForecast.Recorder.NumberOfChildren
	|		END, 0) AS NumberOfChildren,
	|	ISNULL(CASE
	|			WHEN SalesForecast.Recorder REFS Document.Charge
	|				THEN SalesForecast.ParentDoc.NumberOfInfants
	|			ELSE SalesForecast.Recorder.NumberOfInfants
	|		END, 0) AS NumberOfInfants,
	|	SalesForecast.Sum AS Sum,
	|	SalesForecast.SumAccommodation AS SumAccommodation,
	|	SalesForecast.SumReservation AS SumReservation,
	|	SalesForecast.SumWithoutVAT AS SumWithoutVAT,
	|	SalesForecast.SumWithoutVATAccommodation AS SumWithoutVATAccommodation,
	|	SalesForecast.SumWithoutVATReservation AS SumWithoutVATReservation,
	|	SalesForecast.CommissionSum AS CommissionSum,
	|	SalesForecast.CommissionSumAccommodation AS CommissionSumAccommodation,
	|	SalesForecast.CommissionSumReservation AS CommissionSumReservation,
	|	SalesForecast.CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|	SalesForecast.CommissionSumWithoutVATAccommodation AS CommissionSumWithoutVATAccommodation,
	|	SalesForecast.CommissionSumWithoutVATReservation AS CommissionSumWithoutVATReservation,
	|	SalesForecast.DiscountSum AS DiscountSum,
	|	SalesForecast.DiscountSumAccommodation AS DiscountSumAccommodation,
	|	SalesForecast.DiscountSumReservation AS DiscountSumReservation,
	|	SalesForecast.DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|	SalesForecast.DiscountSumWithoutVATAccommodation AS DiscountSumWithoutVATAccommodation,
	|	SalesForecast.DiscountSumWithoutVATReservation AS DiscountSumWithoutVATReservation,
	|	SalesForecast.RateSum AS RateSum,
	|	SalesForecast.DiscountType AS DiscountType,
	|	SalesForecast.RoomsRented AS RoomsRented,
	|	SalesForecast.BedsRented AS BedsRented,
	|	SalesForecast.GuestDays AS GuestDays
	|{SELECT
	|	Period AS Period,
	|	Hotel.* AS Hotel,
	|	SalesForecast.Company.* AS Company,
	|	ReportingCurrency.* AS ReportingCurrency,
	|	Service.* AS Service,
	|	SalesForecast.AccountingDate AS AccountingDate,
	|	(HOUR(SalesForecast.Period)) AS AccountingHour,
	|	(DAY(SalesForecast.AccountingDate)) AS AccountingDay,
	|	(WEEK(SalesForecast.AccountingDate)) AS AccountingWeek,
	|	(MONTH(SalesForecast.AccountingDate)) AS AccountingMonth,
	|	(QUARTER(SalesForecast.AccountingDate)) AS AccountingQuarter,
	|	(YEAR(SalesForecast.AccountingDate)) AS AccountingYear,
	|	SalesForecast.CheckInDate AS CheckInDate,
	|	(HOUR(SalesForecast.CheckInDate)) AS CheckInHour,
	|	(DAY(SalesForecast.CheckInDate)) AS CheckInDay,
	|	(WEEK(SalesForecast.CheckInDate)) AS CheckInWeek,
	|	(MONTH(SalesForecast.CheckInDate)) AS CheckInMonth,
	|	(QUARTER(SalesForecast.CheckInDate)) AS CheckInQuarter,
	|	(YEAR(SalesForecast.CheckInDate)) AS CheckInYear,
	|	SalesForecast.CheckOutDate AS CheckOutDate,
	|	SalesForecast.Status.* AS Status,
	|	Price AS Price,
	|	Client.* AS Client,
	|	SalesForecast.ClientType.* AS ClientType,
	|	SalesForecast.ClientAge AS ClientAge,
	|	SalesForecast.ClientAgeRange.* AS ClientAgeRange,
	|	SalesForecast.ClientCitizenship.* AS ClientCitizenship,
	|	SalesForecast.ClientRegion AS ClientRegion,
	|	SalesForecast.ClientCity AS ClientCity,
	|	SalesForecast.Agent.* AS Agent,
	|	SalesForecast.Customer.* AS Customer,
	|	SalesForecast.Contract.* AS Contract,
	|	SalesForecast.GuestGroup.* AS GuestGroup,
	|	SalesForecast.MarketingCode.* AS MarketingCode,
	|	SalesForecast.SourceOfBusiness.* AS SourceOfBusiness,
	|	SalesForecast.TripPurpose.* AS TripPurpose,
	|	SalesForecast.ServicePackage.* AS ServicePackage,
	|	SalesForecast.PaymentMethod.* AS PaymentMethod,
	|	SalesForecast.AccommodationType.* AS AccommodationType,
	|	SalesForecast.Folio.* AS Folio,
	|	Remarks AS Remarks,
	|	Recorder.* AS Recorder,
	|	ParentDoc.* AS ParentDoc,
	|	SalesForecast.BoardPlace.* AS BoardPlace,
	|	SalesForecast.NumberOfRooms AS NumberOfRooms,
	|	SalesForecast.NumberOfBeds AS NumberOfBeds,
	|	SalesForecast.NumberOfAdditionalBeds AS NumberOfAdditionalBeds,
	|	SalesForecast.NumberOfPersons AS NumberOfPersons,
	|	NumberOfAdults,
	|	NumberOfTeenagers,
	|	NumberOfChildren,
	|	NumberOfInfants,
	|	SalesForecast.NumberOfBedsPerRoom AS NumberOfBedsPerRoom,
	|	SalesForecast.NumberOfPersonsPerRoom AS NumberOfPersonsPerRoom,
	|	SalesForecast.RoomType.* AS RoomType,
	|	Room.* AS Room,
	|	SalesForecast.RoomRateType.* AS RoomRateType,
	|	RoomRate.* AS RoomRate,
	|	SalesForecast.VATRate.* AS VATRate,
	|	SalesForecast.Author.* AS Author,
	|	IsStorno AS IsStorno,
	|	SalesForecast.RateSum AS RateSum,
	|	Resource.* AS Resource,
	|	TimeFrom AS TimeFrom,
	|	TimeTo AS TimeTo,
	|	Quantity AS Quantity,
	|	QuantityReservation AS QuantityReservation,
	|	QuantityAccommodation AS QuantityAccommodation,
	|	Sum AS Sum,
	|	SumReservation AS SumReservation,
	|	SumAccommodation AS SumAccommodation,
	|	SumWithoutVAT AS SumWithoutVAT,
	|	SumWithoutVATReservation AS SumWithoutVATReservation,
	|	SumWithoutVATAccommodation AS SumWithoutVATAccommodation,
	|	CommissionSum AS CommissionSum,
	|	CommissionSumReservation AS CommissionSumReservation,
	|	CommissionSumAccommodation AS CommissionSumAccommodation,
	|	CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|	CommissionSumWithoutVATReservation AS CommissionSumWithoutVATReservation,
	|	CommissionSumWithoutVATAccommodation AS CommissionSumWithoutVATAccommodation,
	|	DiscountSum AS DiscountSum,
	|	DiscountSumReservation AS DiscountSumReservation,
	|	DiscountSumAccommodation AS DiscountSumAccommodation,
	|	DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|	DiscountSumWithoutVATReservation AS DiscountSumWithoutVATReservation,
	|	DiscountSumWithoutVATAccommodation AS DiscountSumWithoutVATAccommodation,
	|	RateSum AS RateSum,
	|	DiscountType.*,
	|	RoomsRented AS RoomsRented,
	|	BedsRented AS BedsRented,
	|	GuestDays AS GuestDays}
	|FROM
	|	(SELECT
	|		ServiceSales.Period AS Period,
	|		ServiceSales.Hotel AS Hotel,
	|		ServiceSales.Company AS Company,
	|		ServiceSales.ReportingCurrency AS ReportingCurrency,
	|		ServiceSales.Service AS Service,
	|		CASE
	|			WHEN ServiceSales.ServiceDate = &qEmptyDate
	|				THEN ServiceSales.AccountingDate
	|			ELSE ServiceSales.ServiceDate
	|		END AS AccountingDate,
	|		ServiceSales.Folio.DateTimeFrom AS CheckInDate,
	|		ServiceSales.Folio.DateTimeTo AS CheckOutDate,
	|		CASE
	|			WHEN ServiceSales.ParentDoc.AccommodationStatus IS NOT NULL 
	|				THEN ServiceSales.ParentDoc.AccommodationStatus
	|			WHEN ServiceSales.ParentDoc.ReservationStatus IS NOT NULL 
	|				THEN ServiceSales.ParentDoc.ReservationStatus
	|			WHEN ServiceSales.ParentDoc.ResourceReservationStatus IS NOT NULL 
	|				THEN ServiceSales.ParentDoc.ResourceReservationStatus
	|			ELSE NULL
	|		END AS Status,
	|		ServiceSales.Price AS Price,
	|		ServiceSales.Room AS Room,
	|		ServiceSales.Client AS Client,
	|		ServiceSales.ClientType AS ClientType,
	|		ServiceSales.Client.Age AS ClientAge,
	|		ServiceSales.Client.AgeRange AS ClientAgeRange,
	|		ServiceSales.Client.Citizenship AS ClientCitizenship,
	|		ServiceSales.Client.Region AS ClientRegion,
	|		ServiceSales.Client.City AS ClientCity,
	|		ServiceSales.Agent AS Agent,
	|		ServiceSales.Customer AS Customer,
	|		ServiceSales.Contract AS Contract,
	|		ServiceSales.GuestGroup AS GuestGroup,
	|		ServiceSales.MarketingCode AS MarketingCode,
	|		ServiceSales.SourceOfBusiness AS SourceOfBusiness,
	|		ServiceSales.Folio AS Folio,
	|		ServiceSales.Recorder.Remarks AS Remarks,
	|		ServiceSales.Recorder AS Recorder,
	|		ServiceSales.ParentDoc AS ParentDoc,
	|		ServiceSales.TripPurpose AS TripPurpose,
	|		ServiceSales.ServicePackage AS ServicePackage,
	|		ServiceSales.PaymentMethod AS PaymentMethod,
	|		ServiceSales.AccommodationType AS AccommodationType,
	|		ServiceSales.NumberOfAdditionalBeds AS NumberOfAdditionalBeds,
	|		ServiceSales.NumberOfBeds AS NumberOfBeds,
	|		ServiceSales.NumberOfBedsPerRoom AS NumberOfBedsPerRoom,
	|		ServiceSales.NumberOfPersons AS NumberOfPersons,
	|		ServiceSales.NumberOfPersonsPerRoom AS NumberOfPersonsPerRoom,
	|		ServiceSales.NumberOfRooms AS NumberOfRooms,
	|		ServiceSales.RoomType AS RoomType,
	|		ServiceSales.RoomRateType AS RoomRateType,
	|		ServiceSales.RoomRate AS RoomRate,
	|		ServiceSales.VATRate AS VATRate,
	|		ServiceSales.Author AS Author,
	|		ServiceSales.IsStorno AS IsStorno,
	|		ServiceSales.RateSum AS RateSum,
	|		CASE
	|			WHEN NOT ServiceSales.BoardPlace.Code IS NULL
	|				THEN ServiceSales.BoardPlace
	|			WHEN ISNULL(ServiceSales.Service.Resource.IsBoardPlace, FALSE)
	|				THEN ServiceSales.Service.Resource
	|			ELSE &qEmptyResource
	|		END AS BoardPlace,
	|		ServiceSales.Resource AS Resource,
	|		ServiceSales.TimeFrom AS TimeFrom,
	|		ServiceSales.TimeTo AS TimeTo,
	|		CASE
	|			WHEN &qRoundQuantityUp
	|					AND ServiceSales.Quantity > 0
	|					AND ServiceSales.Quantity < 1
	|				THEN 1
	|			WHEN &qRoundQuantityUp
	|					AND ServiceSales.Quantity < 0
	|					AND ServiceSales.Quantity > -1
	|				THEN -1
	|			WHEN &qRoundQuantityUp
	|					AND ServiceSales.Quantity > 1
	|					AND ServiceSales.Quantity < 2
	|				THEN 1
	|			WHEN &qRoundQuantityUp
	|					AND ServiceSales.Quantity < -1
	|					AND ServiceSales.Quantity > -2
	|				THEN -1
	|			ELSE ServiceSales.Quantity
	|		END AS Quantity,
	|		0 AS QuantityReservation,
	|		CASE
	|			WHEN &qRoundQuantityUp
	|					AND ServiceSales.Quantity > 0
	|					AND ServiceSales.Quantity < 1
	|				THEN 1
	|			WHEN &qRoundQuantityUp
	|					AND ServiceSales.Quantity < 0
	|					AND ServiceSales.Quantity > -1
	|				THEN -1
	|			WHEN &qRoundQuantityUp
	|					AND ServiceSales.Quantity > 1
	|					AND ServiceSales.Quantity < 2
	|				THEN 1
	|			WHEN &qRoundQuantityUp
	|					AND ServiceSales.Quantity < -1
	|					AND ServiceSales.Quantity > -2
	|				THEN -1
	|			ELSE ServiceSales.Quantity
	|		END AS QuantityAccommodation,
	|		ServiceSales.Sales AS Sum,
	|		0 AS SumReservation,
	|		ServiceSales.Sales AS SumAccommodation,
	|		ServiceSales.SalesWithoutVAT AS SumWithoutVAT,
	|		0 AS SumWithoutVATReservation,
	|		ServiceSales.SalesWithoutVAT AS SumWithoutVATAccommodation,
	|		ServiceSales.CommissionSum AS CommissionSum,
	|		0 AS CommissionSumReservation,
	|		ServiceSales.CommissionSum AS CommissionSumAccommodation,
	|		ServiceSales.CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|		0 AS CommissionSumWithoutVATReservation,
	|		ServiceSales.CommissionSumWithoutVAT AS CommissionSumWithoutVATAccommodation,
	|		ServiceSales.DiscountSum AS DiscountSum,
	|		0 AS DiscountSumReservation,
	|		ServiceSales.DiscountSum AS DiscountSumAccommodation,
	|		ServiceSales.DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|		0 AS DiscountSumWithoutVATReservation,
	|		ServiceSales.DiscountSumWithoutVAT AS DiscountSumWithoutVATAccommodation,
	|		ServiceSales.DiscountType AS DiscountType,
	|		ServiceSales.RoomsRented AS RoomsRented,
	|		ServiceSales.BedsRented AS BedsRented,
	|		ServiceSales.GuestDays AS GuestDays
	|	FROM
	|		AccumulationRegister.Sales AS ServiceSales
	|	WHERE
	|		NOT ServiceSales.IsCorrection
	|		AND ServiceSales.Hotel IN HIERARCHY(&qHotel)
	|		AND ServiceSales.Service IN HIERARCHY(&qService)
	|		AND (ServiceSales.Service IN (&qServicesList)
	|				OR NOT &qUseServicesList)
	|		AND (ServiceSales.RoomType IN HIERARCHY (&qRoomType)
	|				OR &qRoomTypeIsEmpty)
	|		AND (ServiceSales.Room IN HIERARCHY (&qRoom)
	|				OR &qRoomIsEmpty)
	|		AND CASE
	|				WHEN ServiceSales.ServiceDate = &qEmptyDate
	|					THEN ServiceSales.Period BETWEEN &qPeriodFrom AND &qPeriodTo
	|				ELSE ServiceSales.ServiceDate BETWEEN &qPeriodFrom AND &qPeriodTo
	|			END
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ServiceSalesForecast.Period,
	|		ServiceSalesForecast.Hotel,
	|		ServiceSalesForecast.Company,
	|		ServiceSalesForecast.ReportingCurrency,
	|		ServiceSalesForecast.Service,
	|		CASE
	|			WHEN ServiceSalesForecast.ServiceDate = &qEmptyDate
	|				THEN ServiceSalesForecast.AccountingDate
	|			ELSE ServiceSalesForecast.ServiceDate
	|		END,
	|		ServiceSalesForecast.Recorder.CheckInDate,
	|		ServiceSalesForecast.Recorder.CheckOutDate,
	|		CASE
	|			WHEN ServiceSalesForecast.Recorder.ReservationStatus IS NOT NULL 
	|				THEN ServiceSalesForecast.Recorder.ReservationStatus
	|			WHEN ServiceSalesForecast.Recorder.ResourceReservationStatus IS NOT NULL 
	|				THEN ServiceSalesForecast.Recorder.ResourceReservationStatus
	|			ELSE NULL
	|		END,
	|		ServiceSalesForecast.Price,
	|		ServiceSalesForecast.Room,
	|		ServiceSalesForecast.Client,
	|		ServiceSalesForecast.ClientType,
	|		ServiceSalesForecast.Client.Age,
	|		ServiceSalesForecast.Client.AgeRange,
	|		ServiceSalesForecast.Client.Citizenship,
	|		ServiceSalesForecast.Client.Region,
	|		ServiceSalesForecast.Client.City,
	|		ServiceSalesForecast.Agent,
	|		ServiceSalesForecast.Customer,
	|		ServiceSalesForecast.Contract,
	|		ServiceSalesForecast.GuestGroup,
	|		ServiceSalesForecast.MarketingCode,
	|		ServiceSalesForecast.SourceOfBusiness,
	|		ServiceSalesForecast.Folio,
	|		ServiceSalesForecast.Remarks,
	|		ServiceSalesForecast.Recorder,
	|		ServiceSalesForecast.Recorder,
	|		ServiceSalesForecast.TripPurpose,
	|		ServiceSalesForecast.ServicePackage,
	|		ServiceSalesForecast.PaymentMethod,
	|		ServiceSalesForecast.AccommodationType,
	|		ServiceSalesForecast.NumberOfAdditionalBeds,
	|		ServiceSalesForecast.NumberOfBeds,
	|		ServiceSalesForecast.NumberOfBedsPerRoom,
	|		ServiceSalesForecast.NumberOfPersons,
	|		ServiceSalesForecast.NumberOfPersonsPerRoom,
	|		ServiceSalesForecast.NumberOfRooms,
	|		ServiceSalesForecast.RoomType,
	|		ServiceSalesForecast.RoomRateType,
	|		ServiceSalesForecast.RoomRate,
	|		ServiceSalesForecast.VATRate,
	|		ServiceSalesForecast.Author,
	|		ServiceSalesForecast.IsStorno,
	|		ServiceSalesForecast.RateSum,
	|		CASE
	|			WHEN NOT ServiceSalesForecast.BoardPlace.Code IS NULL
	|				THEN ServiceSalesForecast.BoardPlace
	|			WHEN ISNULL(ServiceSalesForecast.Service.Resource.IsBoardPlace, FALSE)
	|				THEN ServiceSalesForecast.Service.Resource
	|			ELSE &qEmptyResource
	|		END,
	|		ServiceSalesForecast.Resource,
	|		ServiceSalesForecast.TimeFrom,
	|		ServiceSalesForecast.TimeTo,
	|		CASE
	|			WHEN &qRoundQuantityUp
	|					AND ServiceSalesForecast.Quantity > 0
	|					AND ServiceSalesForecast.Quantity < 1
	|				THEN 1
	|			WHEN &qRoundQuantityUp
	|					AND ServiceSalesForecast.Quantity < 0
	|					AND ServiceSalesForecast.Quantity > -1
	|				THEN -1
	|			WHEN &qRoundQuantityUp
	|					AND ServiceSalesForecast.Quantity > 1
	|					AND ServiceSalesForecast.Quantity < 2
	|				THEN 1
	|			WHEN &qRoundQuantityUp
	|					AND ServiceSalesForecast.Quantity < -1
	|					AND ServiceSalesForecast.Quantity > -2
	|				THEN -1
	|			ELSE ServiceSalesForecast.Quantity
	|		END,
	|		CASE
	|			WHEN &qRoundQuantityUp
	|					AND ServiceSalesForecast.Quantity > 0
	|					AND ServiceSalesForecast.Quantity < 1
	|				THEN 1
	|			WHEN &qRoundQuantityUp
	|					AND ServiceSalesForecast.Quantity < 0
	|					AND ServiceSalesForecast.Quantity > -1
	|				THEN -1
	|			WHEN &qRoundQuantityUp
	|					AND ServiceSalesForecast.Quantity > 1
	|					AND ServiceSalesForecast.Quantity < 2
	|				THEN 1
	|			WHEN &qRoundQuantityUp
	|					AND ServiceSalesForecast.Quantity < -1
	|					AND ServiceSalesForecast.Quantity > -2
	|				THEN -1
	|			ELSE ServiceSalesForecast.Quantity
	|		END,
	|		0,
	|		ServiceSalesForecast.Sales,
	|		ServiceSalesForecast.Sales,
	|		0,
	|		ServiceSalesForecast.SalesWithoutVAT,
	|		ServiceSalesForecast.SalesWithoutVAT,
	|		0,
	|		ServiceSalesForecast.CommissionSum,
	|		ServiceSalesForecast.CommissionSum,
	|		0,
	|		ServiceSalesForecast.CommissionSumWithoutVAT,
	|		ServiceSalesForecast.CommissionSumWithoutVAT,
	|		0,
	|		ServiceSalesForecast.DiscountSum,
	|		ServiceSalesForecast.DiscountSum,
	|		0,
	|		ServiceSalesForecast.DiscountSumWithoutVAT,
	|		ServiceSalesForecast.DiscountSumWithoutVAT,
	|		0,
	|		ServiceSalesForecast.DiscountType,
	|		ServiceSalesForecast.RoomsRented,
	|		ServiceSalesForecast.BedsRented,
	|		ServiceSalesForecast.GuestDays
	|	FROM
	|		AccumulationRegister.SalesForecast AS ServiceSalesForecast
	|	WHERE
	|		ServiceSalesForecast.Hotel IN HIERARCHY(&qHotel)
	|		AND ServiceSalesForecast.Service IN HIERARCHY(&qService)
	|		AND (ServiceSalesForecast.Service IN (&qServicesList)
	|				OR NOT &qUseServicesList)
	|		AND (ServiceSalesForecast.RoomType IN HIERARCHY (&qRoomType)
	|				OR &qRoomTypeIsEmpty)
	|		AND (ServiceSalesForecast.Room IN HIERARCHY (&qRoom)
	|				OR &qRoomIsEmpty)
	|		AND ServiceSalesForecast.AccountingDate >= &qHotelAccountingDate
	|		AND &qPeriodTo > &qForecastPeriodFrom
	|		AND CASE
	|				WHEN ServiceSalesForecast.ServiceDate = &qEmptyDate
	|					THEN ServiceSalesForecast.Period BETWEEN &qForecastPeriodFrom AND &qForecastPeriodTo
	|				ELSE ServiceSalesForecast.ServiceDate BETWEEN &qForecastPeriodFrom AND &qForecastPeriodTo
	|			END) AS SalesForecast
	|WHERE
	|	(&qBoardPlaceIsEmpty
	|			OR NOT &qBoardPlaceIsEmpty
	|				AND SalesForecast.BoardPlace IN HIERARCHY (&qBoardPlace))
	|{WHERE
	|	SalesForecast.Period AS Period,
	|	SalesForecast.Hotel.* AS Hotel,
	|	SalesForecast.Company.* AS Company,
	|	SalesForecast.ReportingCurrency.* AS ReportingCurrency,
	|	SalesForecast.Service.* AS Service,
	|	SalesForecast.AccountingDate AS AccountingDate,
	|	SalesForecast.CheckInDate AS CheckInDate,
	|	SalesForecast.CheckOutDate AS CheckOutDate,
	|	SalesForecast.Status AS Status,
	|	SalesForecast.Price AS Price,
	|	SalesForecast.Client.* AS Client,
	|	SalesForecast.ClientType.* AS ClientType,
	|	SalesForecast.ClientAge AS ClientAge,
	|	SalesForecast.ClientAgeRange.* AS ClientAgeRange,
	|	SalesForecast.ClientCitizenship.* AS ClientCitizenship,
	|	SalesForecast.ClientRegion AS ClientRegion,
	|	SalesForecast.ClientCity AS ClientCity,
	|	SalesForecast.Agent.* AS Agent,
	|	SalesForecast.Customer.* AS Customer,
	|	SalesForecast.Contract.* AS Contract,
	|	SalesForecast.GuestGroup.* AS GuestGroup,
	|	SalesForecast.MarketingCode.* AS MarketingCode,
	|	SalesForecast.SourceOfBusiness.* AS SourceOfBusiness,
	|	SalesForecast.TripPurpose.* AS TripPurpose,
	|	SalesForecast.ServicePackage.* AS ServicePackage,
	|	SalesForecast.PaymentMethod.* AS PaymentMethod,
	|	SalesForecast.AccommodationType.* AS AccommodationType,
	|	SalesForecast.Folio.* AS Folio,
	|	SalesForecast.Remarks AS Remarks,
	|	SalesForecast.Recorder.* AS Recorder,
	|	SalesForecast.ParentDoc.* AS ParentDoc,
	|	SalesForecast.BoardPlace.* AS BoardPlace,
	|	SalesForecast.NumberOfRooms AS NumberOfRooms,
	|	SalesForecast.NumberOfBeds AS NumberOfBeds,
	|	SalesForecast.NumberOfAdditionalBeds AS NumberOfAdditionalBeds,
	|	SalesForecast.NumberOfPersons AS NumberOfPersons,
	|	(ISNULL(CASE
	|				WHEN SalesForecast.Recorder REFS Document.Charge
	|					THEN SalesForecast.ParentDoc.NumberOfAdults
	|				ELSE SalesForecast.Recorder.NumberOfAdults
	|			END, 0)) AS NumberOfAdults,
	|	(ISNULL(CASE
	|				WHEN SalesForecast.Recorder REFS Document.Charge
	|					THEN SalesForecast.ParentDoc.NumberOfTeenagers
	|				ELSE SalesForecast.Recorder.NumberOfTeenagers
	|			END, 0)) AS NumberOfTeenagers,
	|	(ISNULL(CASE
	|				WHEN SalesForecast.Recorder REFS Document.Charge
	|					THEN SalesForecast.ParentDoc.NumberOfChildren
	|				ELSE SalesForecast.Recorder.NumberOfChildren
	|			END, 0)) AS NumberOfChildren,
	|	(ISNULL(CASE
	|				WHEN SalesForecast.Recorder REFS Document.Charge
	|					THEN SalesForecast.ParentDoc.NumberOfInfants
	|				ELSE SalesForecast.Recorder.NumberOfInfants
	|			END, 0)) AS NumberOfInfants,
	|	SalesForecast.NumberOfBedsPerRoom AS NumberOfBedsPerRoom,
	|	SalesForecast.NumberOfPersonsPerRoom AS NumberOfPersonsPerRoom,
	|	SalesForecast.RoomType.* AS RoomType,
	|	SalesForecast.Room.* AS Room,
	|	SalesForecast.RoomRateType.* AS RoomRateType,
	|	SalesForecast.RoomRate.* AS RoomRate,
	|	SalesForecast.VATRate.* AS VATRate,
	|	SalesForecast.Author.* AS Author,
	|	SalesForecast.IsStorno AS IsStorno,
	|	SalesForecast.RateSum AS RateSum,
	|	SalesForecast.Resource.* AS Resource,
	|	SalesForecast.TimeFrom AS TimeFrom,
	|	SalesForecast.TimeTo AS TimeTo,
	|	SalesForecast.Quantity AS Quantity,
	|	SalesForecast.QuantityReservation AS QuantityReservation,
	|	SalesForecast.QuantityAccommodation AS QuantityAccommodation,
	|	SalesForecast.Sum AS Sum,
	|	SalesForecast.SumReservation AS SumReservation,
	|	SalesForecast.SumAccommodation AS SumAccommodation,
	|	SalesForecast.SumWithoutVAT AS SumWithoutVAT,
	|	SalesForecast.SumWithoutVATReservation AS SumWithoutVATReservation,
	|	SalesForecast.SumWithoutVATAccommodation AS SumWithoutVATAccommodation,
	|	SalesForecast.CommissionSum AS CommissionSum,
	|	SalesForecast.CommissionSumReservation AS CommissionSumReservation,
	|	SalesForecast.CommissionSumAccommodation AS CommissionSumAccommodation,
	|	SalesForecast.CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|	SalesForecast.CommissionSumWithoutVATReservation AS CommissionSumWithoutVATReservation,
	|	SalesForecast.CommissionSumWithoutVATAccommodation AS CommissionSumWithoutVATAccommodation,
	|	SalesForecast.DiscountSum AS DiscountSum,
	|	SalesForecast.DiscountSumReservation AS DiscountSumReservation,
	|	SalesForecast.DiscountSumAccommodation AS DiscountSumAccommodation,
	|	SalesForecast.DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|	SalesForecast.DiscountSumWithoutVATReservation AS DiscountSumWithoutVATReservation,
	|	SalesForecast.DiscountSumWithoutVATAccommodation AS DiscountSumWithoutVATAccommodation,
	|	SalesForecast.RateSum AS RateSum,
	|	SalesForecast.DiscountType.*,
	|	SalesForecast.RoomsRented AS RoomsRented,
	|	SalesForecast.BedsRented AS BedsRented,
	|	SalesForecast.GuestDays AS GuestDays}
	|
	|ORDER BY
	|	ReportingCurrency,
	|	Hotel,
	|	Service,
	|	Room,
	|	Period
	|{ORDER BY
	|	Period AS Period,
	|	Hotel.* AS Hotel,
	|	SalesForecast.Company.* AS Company,
	|	ReportingCurrency.* AS ReportingCurrency,
	|	Service.* AS Service,
	|	SalesForecast.AccountingDate AS AccountingDate,
	|	SalesForecast.CheckInDate AS CheckInDate,
	|	SalesForecast.CheckOutDate AS CheckOutDate,
	|	SalesForecast.Status.* AS Status,
	|	Price AS Price,
	|	Client.* AS Client,
	|	SalesForecast.ClientType.* AS ClientType,
	|	SalesForecast.ClientAge AS ClientAge,
	|	SalesForecast.ClientAgeRange.* AS ClientAgeRange,
	|	SalesForecast.ClientCitizenship.* AS ClientCitizenship,
	|	SalesForecast.ClientRegion AS ClientRegion,
	|	SalesForecast.ClientCity AS ClientCity,
	|	SalesForecast.Agent.* AS Agent,
	|	SalesForecast.Customer.* AS Customer,
	|	SalesForecast.Contract.* AS Contract,
	|	SalesForecast.GuestGroup.* AS GuestGroup,
	|	SalesForecast.MarketingCode.* AS MarketingCode,
	|	SalesForecast.SourceOfBusiness.* AS SourceOfBusiness,
	|	SalesForecast.TripPurpose.* AS TripPurpose,
	|	SalesForecast.ServicePackage.* AS ServicePackage,
	|	SalesForecast.PaymentMethod.* AS PaymentMethod,
	|	SalesForecast.AccommodationType.* AS AccommodationType,
	|	SalesForecast.Folio.* AS Folio,
	|	Recorder.* AS Recorder,
	|	ParentDoc.* AS ParentDoc,
	|	SalesForecast.BoardPlace.* AS BoardPlace,
	|	SalesForecast.NumberOfRooms AS NumberOfRooms,
	|	SalesForecast.NumberOfBeds AS NumberOfBeds,
	|	SalesForecast.NumberOfAdditionalBeds AS NumberOfAdditionalBeds,
	|	SalesForecast.NumberOfPersons AS NumberOfPersons,
	|	NumberOfAdults,
	|	NumberOfTeenagers,
	|	NumberOfChildren,
	|	NumberOfInfants,
	|	SalesForecast.NumberOfBedsPerRoom AS NumberOfBedsPerRoom,
	|	SalesForecast.NumberOfPersonsPerRoom AS NumberOfPersonsPerRoom,
	|	SalesForecast.RoomType.* AS RoomType,
	|	Room.* AS Room,
	|	SalesForecast.RoomRateType.* AS RoomRateType,
	|	RoomRate.* AS RoomRate,
	|	SalesForecast.VATRate.* AS VATRate,
	|	SalesForecast.Author.* AS Author,
	|	IsStorno AS IsStorno,
	|	SalesForecast.RateSum AS RateSum,
	|	Resource.* AS Resource,
	|	TimeFrom AS TimeFrom,
	|	TimeTo AS TimeTo,
	|	Quantity AS Quantity,
	|	QuantityReservation AS QuantityReservation,
	|	QuantityAccommodation AS QuantityAccommodation,
	|	Sum AS Sum,
	|	SumReservation AS SumReservation,
	|	SumAccommodation AS SumAccommodation,
	|	SumWithoutVAT AS SumWithoutVAT,
	|	SumWithoutVATReservation AS SumWithoutVATReservation,
	|	SumWithoutVATAccommodation AS SumWithoutVATAccommodation,
	|	CommissionSum AS CommissionSum,
	|	CommissionSumReservation AS CommissionSumReservation,
	|	CommissionSumAccommodation AS CommissionSumAccommodation,
	|	CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|	CommissionSumWithoutVATReservation AS CommissionSumWithoutVATReservation,
	|	CommissionSumWithoutVATAccommodation AS CommissionSumWithoutVATAccommodation,
	|	DiscountSum AS DiscountSum,
	|	DiscountSumReservation AS DiscountSumReservation,
	|	DiscountSumAccommodation AS DiscountSumAccommodation,
	|	DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|	DiscountSumWithoutVATReservation AS DiscountSumWithoutVATReservation,
	|	DiscountSumWithoutVATAccommodation AS DiscountSumWithoutVATAccommodation,
	|	DiscountType.*,
	|	RoomsRented AS RoomsRented,
	|	BedsRented AS BedsRented,
	|	GuestDays AS GuestDays}
	|TOTALS
	|	SUM(Quantity),
	|	SUM(QuantityAccommodation),
	|	SUM(QuantityReservation),
	|	SUM(NumberOfAdults),
	|	SUM(NumberOfTeenagers),
	|	SUM(NumberOfChildren),
	|	SUM(NumberOfInfants),
	|	SUM(Sum),
	|	SUM(SumAccommodation),
	|	SUM(SumReservation),
	|	SUM(SumWithoutVAT),
	|	SUM(SumWithoutVATAccommodation),
	|	SUM(SumWithoutVATReservation),
	|	SUM(CommissionSum),
	|	SUM(CommissionSumAccommodation),
	|	SUM(CommissionSumReservation),
	|	SUM(CommissionSumWithoutVAT),
	|	SUM(CommissionSumWithoutVATAccommodation),
	|	SUM(CommissionSumWithoutVATReservation),
	|	SUM(DiscountSum),
	|	SUM(DiscountSumAccommodation),
	|	SUM(DiscountSumReservation),
	|	SUM(DiscountSumWithoutVAT),
	|	SUM(DiscountSumWithoutVATAccommodation),
	|	SUM(DiscountSumWithoutVATReservation),
	|	SUM(RateSum),
	|	SUM(RoomsRented),
	|	SUM(BedsRented),
	|	SUM(GuestDays)
	|BY
	|	OVERALL,
	|	ReportingCurrency,
	|	Hotel,
	|	Service,
	|	Room,
	|	Period
	|{TOTALS BY
	|	Period AS Period,
	|	SalesForecast.AccountingDate AS AccountingDate,
	|	(HOUR(SalesForecast.Period)) AS AccountingHour,
	|	(DAY(SalesForecast.AccountingDate)) AS AccountingDay,
	|	(WEEK(SalesForecast.AccountingDate)) AS AccountingWeek,
	|	(MONTH(SalesForecast.AccountingDate)) AS AccountingMonth,
	|	(QUARTER(SalesForecast.AccountingDate)) AS AccountingQuarter,
	|	(YEAR(SalesForecast.AccountingDate)) AS AccountingYear,
	|	(HOUR(SalesForecast.CheckInDate)) AS CheckInHour,
	|	(DAY(SalesForecast.CheckInDate)) AS CheckInDay,
	|	(WEEK(SalesForecast.CheckInDate)) AS CheckInWeek,
	|	(MONTH(SalesForecast.CheckInDate)) AS CheckInMonth,
	|	(QUARTER(SalesForecast.CheckInDate)) AS CheckInQuarter,
	|	(YEAR(SalesForecast.CheckInDate)) AS CheckInYear,
	|	SalesForecast.Status.* AS Status,
	|	Hotel.* AS Hotel,
	|	SalesForecast.Company.* AS Company,
	|	ReportingCurrency.* AS ReportingCurrency,
	|	Service.* AS Service,
	|	Price AS Price,
	|	Client.* AS Client,
	|	SalesForecast.ClientType.* AS ClientType,
	|	SalesForecast.ClientAge AS ClientAge,
	|	SalesForecast.ClientAgeRange.* AS ClientAgeRange,
	|	SalesForecast.ClientCitizenship.* AS ClientCitizenship,
	|	SalesForecast.ClientRegion AS ClientRegion,
	|	SalesForecast.ClientCity AS ClientCity,
	|	SalesForecast.Agent.* AS Agent,
	|	SalesForecast.Customer.* AS Customer,
	|	SalesForecast.Contract.* AS Contract,
	|	SalesForecast.GuestGroup.* AS GuestGroup,
	|	SalesForecast.MarketingCode.* AS MarketingCode,
	|	SalesForecast.SourceOfBusiness.* AS SourceOfBusiness,
	|	SalesForecast.TripPurpose.* AS TripPurpose,
	|	SalesForecast.ServicePackage.* AS ServicePackage,
	|	SalesForecast.PaymentMethod.* AS PaymentMethod,
	|	SalesForecast.AccommodationType.* AS AccommodationType,
	|	SalesForecast.Folio.* AS Folio,
	|	Recorder.* AS Recorder,
	|	ParentDoc.* AS ParentDoc,
	|	SalesForecast.BoardPlace.* AS BoardPlace,
	|	SalesForecast.NumberOfRooms AS NumberOfRooms,
	|	SalesForecast.NumberOfBeds AS NumberOfBeds,
	|	SalesForecast.NumberOfAdditionalBeds AS NumberOfAdditionalBeds,
	|	SalesForecast.NumberOfPersons AS NumberOfPersons,
	|	SalesForecast.NumberOfBedsPerRoom AS NumberOfBedsPerRoom,
	|	SalesForecast.NumberOfPersonsPerRoom AS NumberOfPersonsPerRoom,
	|	SalesForecast.RoomType.* AS RoomType,
	|	Room.* AS Room,
	|	SalesForecast.RoomRateType.* AS RoomRateType,
	|	RoomRate.* AS RoomRate,
	|	Resource.* AS Resource,
	|	TimeFrom AS TimeFrom,
	|	TimeTo AS TimeTo,
	|	SalesForecast.VATRate.* AS VATRate,
	|	SalesForecast.Author.* AS Author,
	|	IsStorno AS IsStorno,
	|	DiscountType.*}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("en='Services sales forecast';ru='Планируемое оказание услуг';de='Geplante Leistungserbringung'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
Function pmIsResource(pName) Export
	If pName = "Quantity" 
	   Or pName = "QuantityAccommodation" 
	   Or pName = "QuantityReservation" 
	   Or pName = "Sum" 
	   Or pName = "SumAccommodation" 
	   Or pName = "SumReservation" 
	   Or pName = "SumWithoutVAT" 
	   Or pName = "SumWithoutVATAccommodation" 
	   Or pName = "SumWithoutVATReservation" 
	   Or pName = "CommissionSum" 
	   Or pName = "CommissionSumAccommodation" 
	   Or pName = "CommissionSumReservation" 
	   Or pName = "CommissionSumWithoutVAT" 
	   Or pName = "CommissionSumWithoutVATAccommodation" 
	   Or pName = "CommissionSumWithoutVATReservation" 
	   Or pName = "DiscountSum" 
	   Or pName = "DiscountSumAccommodation" 
	   Or pName = "DiscountSumReservation" 
	   Or pName = "DiscountSumWithoutVAT" 
	   Or pName = "DiscountSumWithoutVATAccommodation" 
	   Or pName = "DiscountSumWithoutVATReservation" 
	   Or pName = "NumberOfAdults" 
	   Or pName = "NumberOfTeenagers" 
	   Or pName = "NumberOfChildren" 
	   Or pName = "NumberOfInfants" 
	   Or pName = "RateSum" 
	   Or pName = "RoomsRented" 
	   Or pName = "BedsRented"
	   Or pName = "GuestDays" Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // pmIsResource

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
