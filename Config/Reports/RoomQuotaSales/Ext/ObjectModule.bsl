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
		If Not ValueIsFilled(PeriodFrom) Then
			PeriodFrom = BegOfMonth(CurrentSessionDate()); // For beg. of month
			PeriodTo = EndOfDay(CurrentSessionDate());
		EndIf;
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
	ElsIf PeriodFrom < PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период '; en = 'Period '; de = 'Periode '") + PeriodPresentation(PeriodFrom, PeriodTo, cmLocalizationCode()) + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("en='Period is wrong!';ru='Неправильно задан период!';de='Der Zeitraum wurde falsch eingetragen!'") + 
		                     ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(Agent) Then
		If Not Agent.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Agent ';ru='Агент ';de='Vertreter '") + 
			                     TrimAll(Agent.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Agents folder ';ru='Группа агентов ';de='Vertretergruppe '") + 
			                     TrimAll(Agent.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(Customer) Then
		If Not Customer.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("de='Firma ';en='Customer ';ru='Контрагент '") + 
			                     TrimAll(Customer.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("de='Firmengruppe ';en='Customers folder ';ru='Группа контрагентов '") + 
			                     TrimAll(Customer.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(Contract) Then
		vParamPresentation = vParamPresentation + NStr("en='Contract ';ru='Договор ';de='Vertrag '") + 
							 TrimAll(Contract.Description) + 
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
	If ValueIsFilled(RoomQuota) Then
		If Not RoomQuota.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Квота номеров '; en = 'Allotment '; de = 'Allotment '") + 
			                     TrimAll(RoomQuota.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа квот номеров '; en = 'Allotments folder '; de = 'Allotmentgruppe '") + 
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
Procedure pmGenerate(pSpreadsheet, pAddChart = False) Export
	Var vTemplateAttributes;
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
	
	// Initialize report builder query generator attributes
	ReportBuilder.PresentationAdding = PresentationAdditionType.Add;
	
	// Fill report parameters
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qIsEmptyHotel", Not ValueIsFilled(Hotel));
	ReportBuilder.Parameters.Insert("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	ReportBuilder.Parameters.Insert("qPeriodFrom", BegOfDay(PeriodFrom));
	ReportBuilder.Parameters.Insert("qPeriodTo", EndOfDay(PeriodTo));
	vForecastStartDate = tcOnServer.GetForecastStartDate(Hotel);
	ReportBuilder.Parameters.Insert("qForecastPeriodFrom", Max(BegOfDay(PeriodFrom), vForecastStartDate));
	ReportBuilder.Parameters.Insert("qForecastPeriodTo", ?(ValueIsFilled(PeriodTo), Max(EndOfDay(PeriodTo), EndOfDay(vForecastStartDate-24*3600)), '00010101'));
	ReportBuilder.Parameters.Insert("qAgent", Agent);
	ReportBuilder.Parameters.Insert("qIsEmptyAgent", Not ValueIsFilled(Agent));
	ReportBuilder.Parameters.Insert("qCustomer", Customer);
	ReportBuilder.Parameters.Insert("qIsEmptyCustomer", Not ValueIsFilled(Customer));
	ReportBuilder.Parameters.Insert("qContract", Contract);
	ReportBuilder.Parameters.Insert("qIsEmptyContract", Not ValueIsFilled(Contract));
	ReportBuilder.Parameters.Insert("qRoomQuota", RoomQuota);
	ReportBuilder.Parameters.Insert("qIsEmptyRoomQuota", Not ValueIsFilled(RoomQuota));
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qIsEmptyRoomType", Not ValueIsFilled(RoomType));
	vRoomTypeIsUsed = True;
	If ReportBuilder.ColumnDimensions.Find("RoomType") = Undefined And 
	   ReportBuilder.RowDimensions.Find("RoomType") = Undefined And 
	   ReportBuilder.SelectedFields.Find("RoomType") = Undefined Then
		vRoomTypeIsUsed = False;
	EndIf;
	ReportBuilder.Parameters.Insert("qRoomTypeIsUsed", vRoomTypeIsUsed);
	vRoomIsUsed = True;
	If ReportBuilder.ColumnDimensions.Find("Room") = Undefined And 
	   ReportBuilder.RowDimensions.Find("Room") = Undefined And 
	   ReportBuilder.SelectedFields.Find("Room") = Undefined Then
		vRoomIsUsed = False;
	EndIf;
	ReportBuilder.Parameters.Insert("qRoomIsUsed", vRoomIsUsed);
	ReportBuilder.Parameters.Insert("qFlatRateIsUsedForUnderallotmentPenaltyCalculation", ?(ValueIsFilled(RoomQuota) And Not RoomQuota.IsFolder, RoomQuota.FlatRateIsUsedForUnderallotmentPenaltyCalculation, False));
	vGuestsStatisticsIsUsed = True;
	If ReportBuilder.SelectedFields.Find("GuestsCheckedIn") = Undefined And ReportBuilder.SelectedFields.Find("GuestDays") = Undefined Then
		vGuestsStatisticsIsUsed = False;
	EndIf;
	ReportBuilder.Parameters.Insert("qGuestsStatisticsIsUsed", vGuestsStatisticsIsUsed);
	ReportBuilder.Parameters.Insert("qEmptyDate", '00010101');
	
	// Execute report builder query
	ReportBuilder.Execute();
	
	// Apply appearance settings to the report template
	vTemplateAttributes = cmApplyReportTemplateAppearance(ThisObject);
	
	// Add details parameter to the report dates
	vPeriodArea = ReportBuilder.Template.FindText("Period", ReportBuilder.Template.Area(5, 1));
	If vPeriodArea <> Undefined Then
		vPeriodArea.DetailsParameter = vPeriodArea.Parameter;
	EndIf;
	
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
	|	GuestsStatistics.Hotel AS Hotel,
	|	GuestsStatistics.RoomQuota AS RoomQuota,
	|	ISNULL(GuestsStatistics.RoomQuota.IsQuotaForRooms, FALSE) AS IsQuotaForRooms,
	|	GuestsStatistics.RoomType AS RoomType,
	|	CASE
	|		WHEN &qRoomIsUsed
	|				AND ISNULL(GuestsStatistics.RoomQuota.IsQuotaForRooms, FALSE)
	|			THEN GuestsStatistics.Room
	|		ELSE VALUE(Catalog.Rooms.EmptyRef)
	|	END AS Room,
	|	GuestsStatistics.Period AS Period,
	|	SUM(GuestsStatistics.GuestsCheckedIn) AS GuestsCheckedIn,
	|	SUM(GuestsStatistics.GuestDays) AS GuestDays
	|INTO GuestsStatistics
	|FROM
	|	(SELECT
	|		GuestsStatisticsSales.Hotel AS Hotel,
	|		GuestsStatisticsSales.ParentDoc.RoomQuota AS RoomQuota,
	|		GuestsStatisticsSales.RoomType AS RoomType,
	|		GuestsStatisticsSales.Room AS Room,
	|		GuestsStatisticsSales.Period AS Period,
	|		GuestsStatisticsSales.GuestsCheckedInTurnover AS GuestsCheckedIn,
	|		GuestsStatisticsSales.GuestDaysTurnover AS GuestDays
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				DAY,
	|				&qGuestsStatisticsIsUsed
	|					AND NOT ParentDoc.RoomQuota.Code IS NULL
	|					AND (Hotel IN HIERARCHY (&qHotel)
	|						OR &qIsEmptyHotel)
	|					AND (ParentDoc.RoomQuota IN HIERARCHY (&qRoomQuota)
	|						OR &qIsEmptyRoomQuota)
	|					AND (ParentDoc.RoomQuota.Agent IN HIERARCHY (&qAgent)
	|						OR &qIsEmptyAgent)
	|					AND (ParentDoc.RoomQuota.Customer IN HIERARCHY (&qCustomer)
	|						OR &qIsEmptyCustomer)
	|					AND (ParentDoc.RoomQuota.Contract = &qContract
	|						OR &qIsEmptyContract)
	|					AND (RoomType IN HIERARCHY (&qRoomType)
	|						OR &qIsEmptyRoomType)) AS GuestsStatisticsSales
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GuestsStatisticsForecast.Hotel,
	|		GuestsStatisticsForecast.ParentDoc.RoomQuota,
	|		GuestsStatisticsForecast.RoomType,
	|		GuestsStatisticsForecast.Room,
	|		GuestsStatisticsForecast.Period,
	|		GuestsStatisticsForecast.GuestsCheckedInTurnover,
	|		GuestsStatisticsForecast.GuestDaysTurnover
	|	FROM
	|		AccumulationRegister.SalesForecast.Turnovers(
	|				&qForecastPeriodFrom,
	|				&qForecastPeriodTo,
	|				DAY,
	|				&qGuestsStatisticsIsUsed
	|					AND NOT ParentDoc.RoomQuota.Code IS NULL
	|					AND (Hotel IN HIERARCHY (&qHotel)
	|						OR &qIsEmptyHotel)
	|					AND (ParentDoc.RoomQuota IN HIERARCHY (&qRoomQuota)
	|						OR &qIsEmptyRoomQuota)
	|					AND (ParentDoc.RoomQuota.Agent IN HIERARCHY (&qAgent)
	|						OR &qIsEmptyAgent)
	|					AND (ParentDoc.RoomQuota.Customer IN HIERARCHY (&qCustomer)
	|						OR &qIsEmptyCustomer)
	|					AND (ParentDoc.RoomQuota.Contract = &qContract
	|						OR &qIsEmptyContract)
	|					AND (RoomType IN HIERARCHY (&qRoomType)
	|						OR &qIsEmptyRoomType)) AS GuestsStatisticsForecast) AS GuestsStatistics
	|
	|GROUP BY
	|	GuestsStatistics.Hotel,
	|	GuestsStatistics.RoomQuota,
	|	ISNULL(GuestsStatistics.RoomQuota.IsQuotaForRooms, FALSE),
	|	GuestsStatistics.RoomType,
	|	CASE
	|		WHEN &qRoomIsUsed
	|				AND ISNULL(GuestsStatistics.RoomQuota.IsQuotaForRooms, FALSE)
	|			THEN GuestsStatistics.Room
	|		ELSE VALUE(Catalog.Rooms.EmptyRef)
	|	END,
	|	GuestsStatistics.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Allotments.Ref AS RoomQuota,
	|	Allotments.UnderAllotmentRoomRate AS RoomRate,
	|	AccommodationTypes.AccommodationType AS AccommodationType
	|INTO AllotmentsWithAccommodationTypes
	|FROM
	|	Catalog.RoomQuotas AS Allotments
	|		INNER JOIN (SELECT
	|			AccommodationTypes.Ref.NumberOfAdults AS NumberOfAdults,
	|			AccommodationTypes.AccommodationType AS AccommodationType
	|		FROM
	|			Catalog.AccommodationTemplates.AccommodationTypes AS AccommodationTypes
	|		WHERE
	|			NOT AccommodationTypes.Ref.DeletionMark
	|			AND AccommodationTypes.Ref.NumberOfTeenagers = 0
	|			AND AccommodationTypes.Ref.NumberOfChildren = 0
	|			AND AccommodationTypes.Ref.NumberOfInfants = 0
	|			AND NOT AccommodationTypes.Ref.IsForFolioSplit
	|			AND (AccommodationTypes.Ref.Hotel = &qEmptyHotel
	|					OR NOT &qIsEmptyHotel
	|						AND AccommodationTypes.Ref.Hotel <> &qEmptyHotel
	|						AND AccommodationTypes.Ref.Hotel IN HIERARCHY (&qHotel)
	|					OR &qIsEmptyHotel)) AS AccommodationTypes
	|		ON Allotments.PriceNumberOfAdults = AccommodationTypes.NumberOfAdults
	|WHERE
	|	NOT Allotments.DeletionMark
	|	AND NOT Allotments.IsFolder
	|	AND Allotments.UnderAllotmentRoomRate <> VALUE(Catalog.RoomRates.EmptyRef)
	|	AND Allotments.PriceNumberOfAdults <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllotmentsWithAccommodationTypes.RoomQuota AS RoomQuota,
	|	RoomRateDailyPrices.Hotel AS Hotel,
	|	RoomRateDailyPrices.RoomRate AS RoomRate,
	|	RoomRateDailyPrices.Period AS Period,
	|	RoomRateDailyPrices.RoomType AS RoomType,
	|	SUM(RoomRateDailyPrices.Price) AS Price
	|INTO AllotmentDailyPrices
	|FROM
	|	InformationRegister.RoomRateDailyPrices AS RoomRateDailyPrices
	|		INNER JOIN AllotmentsWithAccommodationTypes AS AllotmentsWithAccommodationTypes
	|		ON RoomRateDailyPrices.RoomRate = AllotmentsWithAccommodationTypes.RoomRate
	|			AND RoomRateDailyPrices.AccommodationType = AllotmentsWithAccommodationTypes.AccommodationType
	|WHERE
	|	&qRoomTypeIsUsed
	|	AND RoomRateDailyPrices.Period >= &qPeriodFrom
	|	AND RoomRateDailyPrices.Period <= &qPeriodTo
	|	AND (NOT &qIsEmptyHotel
	|				AND RoomRateDailyPrices.Hotel IN HIERARCHY (&qHotel)
	|			OR &qIsEmptyHotel)
	|
	|GROUP BY
	|	AllotmentsWithAccommodationTypes.RoomQuota,
	|	RoomRateDailyPrices.Hotel,
	|	RoomRateDailyPrices.RoomRate,
	|	RoomRateDailyPrices.Period,
	|	RoomRateDailyPrices.RoomType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomQuotaSales.Hotel AS Hotel,
	|	RoomQuotaSales.RoomQuota AS RoomQuota,
	|	ISNULL(RoomQuotaSales.RoomQuota.IsQuotaForRooms, FALSE) AS IsQuotaForRooms,
	|	ISNULL(RoomQuotaSales.RoomQuota.FlatRateIsUsedForUnderallotmentPenaltyCalculation, FALSE) AS FlatRateIsUsedForUnderallotmentPenaltyCalculation,
	|	ISNULL(RoomQuotaSales.RoomQuota.FlatRateRoomType, VALUE(Catalog.RoomTypes.EmptyRef)) AS FlatRateRoomType,
	|	RoomQuotaSales.RoomType AS RoomType,
	|	CASE
	|		WHEN &qRoomIsUsed
	|				AND ISNULL(RoomQuotaSales.RoomQuota.IsQuotaForRooms, FALSE)
	|			THEN RoomQuotaSales.Room
	|		ELSE VALUE(Catalog.Rooms.EmptyRef)
	|	END AS Room,
	|	RoomQuotaSales.Period AS Period,
	|	SUM(ISNULL(RoomQuotaSales.CounterClosingBalance, 0)) AS CounterClosingBalance,
	|	SUM(ISNULL(RoomQuotaSales.RoomsInQuotaClosingBalance, 0)) + SUM(ISNULL(RoomQuotaSales.CounterClosingBalance, 0)) - SUM(ISNULL(RoomQuotaSales.CounterClosingBalance, 0)) AS RoomsInQuotaClosingBalance,
	|	SUM(ISNULL(RoomQuotaSales.BedsInQuotaClosingBalance, 0)) + SUM(ISNULL(RoomQuotaSales.CounterClosingBalance, 0)) - SUM(ISNULL(RoomQuotaSales.CounterClosingBalance, 0)) AS BedsInQuotaClosingBalance,
	|	-SUM(ISNULL(RoomQuotaSales.RoomsReservedClosingBalance, 0)) + SUM(ISNULL(RoomQuotaSales.CounterClosingBalance, 0)) - SUM(ISNULL(RoomQuotaSales.CounterClosingBalance, 0)) AS RoomsReservedClosingBalance,
	|	-SUM(ISNULL(RoomQuotaSales.BedsReservedClosingBalance, 0)) + SUM(ISNULL(RoomQuotaSales.CounterClosingBalance, 0)) - SUM(ISNULL(RoomQuotaSales.CounterClosingBalance, 0)) AS BedsReservedClosingBalance,
	|	-SUM(ISNULL(RoomQuotaSales.GuaranteedRoomsReservedClosingBalance, 0)) + SUM(ISNULL(RoomQuotaSales.CounterClosingBalance, 0)) - SUM(ISNULL(RoomQuotaSales.CounterClosingBalance, 0)) AS GuaranteedRoomsReservedClosingBalance,
	|	-SUM(ISNULL(RoomQuotaSales.GuaranteedBedsReservedClosingBalance, 0)) + SUM(ISNULL(RoomQuotaSales.CounterClosingBalance, 0)) - SUM(ISNULL(RoomQuotaSales.CounterClosingBalance, 0)) AS GuaranteedBedsReservedClosingBalance,
	|	-SUM(ISNULL(RoomQuotaSales.InHouseRoomsClosingBalance, 0)) + SUM(ISNULL(RoomQuotaSales.CounterClosingBalance, 0)) - SUM(ISNULL(RoomQuotaSales.CounterClosingBalance, 0)) AS InHouseRoomsClosingBalance,
	|	-SUM(ISNULL(RoomQuotaSales.InHouseBedsClosingBalance, 0)) + SUM(ISNULL(RoomQuotaSales.CounterClosingBalance, 0)) - SUM(ISNULL(RoomQuotaSales.CounterClosingBalance, 0)) AS InHouseBedsClosingBalance,
	|	-SUM(ISNULL(RoomQuotaSales.RoomsReservedClosingBalance, 0)) - SUM(ISNULL(RoomQuotaSales.InHouseRoomsClosingBalance, 0)) AS OccupiedRoomsClosingBalance,
	|	-SUM(ISNULL(RoomQuotaSales.BedsReservedClosingBalance, 0)) - SUM(ISNULL(RoomQuotaSales.InHouseBedsClosingBalance, 0)) AS OccupiedBedsClosingBalance,
	|	SUM(ISNULL(RoomQuotaSales.RoomsRemainsClosingBalance, 0)) + SUM(ISNULL(RoomQuotaSales.CounterClosingBalance, 0)) - SUM(ISNULL(RoomQuotaSales.CounterClosingBalance, 0)) AS RoomsRemainsClosingBalance,
	|	SUM(ISNULL(RoomQuotaSales.BedsRemainsClosingBalance, 0)) + SUM(ISNULL(RoomQuotaSales.CounterClosingBalance, 0)) - SUM(ISNULL(RoomQuotaSales.CounterClosingBalance, 0)) AS BedsRemainsClosingBalance
	|INTO RoomQuotaSales
	|FROM
	|	AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			DAY,
	|			RegisterRecordsAndPeriodBoundaries,
	|			(Hotel IN HIERARCHY (&qHotel)
	|				OR &qIsEmptyHotel)
	|				AND (RoomQuota IN HIERARCHY (&qRoomQuota)
	|					OR &qIsEmptyRoomQuota)
	|				AND (RoomQuota.Agent IN HIERARCHY (&qAgent)
	|					OR &qIsEmptyAgent)
	|				AND (RoomQuota.Customer IN HIERARCHY (&qCustomer)
	|					OR &qIsEmptyCustomer)
	|				AND (RoomQuota.Contract = &qContract
	|					OR &qIsEmptyContract)
	|				AND (RoomType IN HIERARCHY (&qRoomType)
	|					OR &qIsEmptyRoomType)) AS RoomQuotaSales
	|
	|GROUP BY
	|	RoomQuotaSales.Hotel,
	|	RoomQuotaSales.RoomQuota,
	|	ISNULL(RoomQuotaSales.RoomQuota.IsQuotaForRooms, FALSE),
	|	ISNULL(RoomQuotaSales.RoomQuota.FlatRateIsUsedForUnderallotmentPenaltyCalculation, FALSE),
	|	ISNULL(RoomQuotaSales.RoomQuota.FlatRateRoomType, VALUE(Catalog.RoomTypes.EmptyRef)),
	|	RoomQuotaSales.RoomType,
	|	CASE
	|		WHEN &qRoomIsUsed
	|				AND ISNULL(RoomQuotaSales.RoomQuota.IsQuotaForRooms, FALSE)
	|			THEN RoomQuotaSales.Room
	|		ELSE VALUE(Catalog.Rooms.EmptyRef)
	|	END,
	|	RoomQuotaSales.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ForecastData.Hotel AS Hotel,
	|	ForecastData.RoomQuota AS RoomQuota,
	|	ISNULL(ForecastData.RoomQuota.IsQuotaForRooms, FALSE) AS IsQuotaForRooms,
	|	ISNULL(ForecastData.RoomQuota.FlatRateIsUsedForUnderallotmentPenaltyCalculation, FALSE) AS FlatRateIsUsedForUnderallotmentPenaltyCalculation,
	|	ISNULL(ForecastData.RoomQuota.FlatRateRoomType, VALUE(Catalog.RoomTypes.EmptyRef)) AS FlatRateRoomType,
	|	ForecastData.RoomType AS RoomType,
	|	VALUE(Catalog.Rooms.EmptyRef) AS Room,
	|	ForecastData.Period AS Period,
	|	ForecastData.RoomsReservedTurnover AS RoomsForecastClosingBalance,
	|	ForecastData.BedsReservedTurnover AS BedsForecastClosingBalance
	|INTO ForecastData
	|FROM
	|	AccumulationRegister.ExpectedGuestGroups.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			(Hotel IN HIERARCHY (&qHotel)
	|				OR &qIsEmptyHotel)
	|				AND (RoomQuota IN HIERARCHY (&qRoomQuota)
	|					OR &qIsEmptyRoomQuota)
	|				AND (RoomQuota.Agent IN HIERARCHY (&qAgent)
	|					OR &qIsEmptyAgent)
	|				AND (RoomQuota.Customer IN HIERARCHY (&qCustomer)
	|					OR &qIsEmptyCustomer)
	|				AND (RoomQuota.Contract = &qContract
	|					OR &qIsEmptyContract)
	|				AND (RoomType IN HIERARCHY (&qRoomType)
	|					OR &qIsEmptyRoomType)
	|				AND CASE
	|					WHEN RoomQuota = VALUE(Catalog.RoomQuotas.EmptyRef)
	|						THEN TRUE
	|					WHEN GuestGroup <> VALUE(Catalog.GuestGroups.EmptyRef)
	|						THEN TRUE
	|					WHEN NOT ISNULL(RoomQuota.DoWriteOff, FALSE)
	|						THEN TRUE
	|					ELSE FALSE
	|				END) AS ForecastData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllotmentRawSales.Hotel AS Hotel,
	|	AllotmentRawSales.RoomQuota AS RoomQuota,
	|	AllotmentRawSales.IsQuotaForRooms AS IsQuotaForRooms,
	|	AllotmentRawSales.FlatRateIsUsedForUnderallotmentPenaltyCalculation AS FlatRateIsUsedForUnderallotmentPenaltyCalculation,
	|	AllotmentRawSales.FlatRateRoomType AS FlatRateRoomType,
	|	AllotmentRawSales.RoomType AS RoomType,
	|	AllotmentRawSales.Room AS Room,
	|	AllotmentRawSales.Period AS Period,
	|	SUM(AllotmentRawSales.CounterClosingBalance) AS CounterClosingBalance,
	|	SUM(AllotmentRawSales.RoomsInQuotaClosingBalance) AS RoomsInQuotaClosingBalance,
	|	SUM(AllotmentRawSales.BedsInQuotaClosingBalance) AS BedsInQuotaClosingBalance,
	|	SUM(AllotmentRawSales.RoomsReservedClosingBalance) AS RoomsReservedClosingBalance,
	|	SUM(AllotmentRawSales.BedsReservedClosingBalance) AS BedsReservedClosingBalance,
	|	SUM(AllotmentRawSales.GuaranteedRoomsReservedClosingBalance) AS GuaranteedRoomsReservedClosingBalance,
	|	SUM(AllotmentRawSales.GuaranteedBedsReservedClosingBalance) AS GuaranteedBedsReservedClosingBalance,
	|	SUM(AllotmentRawSales.InHouseRoomsClosingBalance) AS InHouseRoomsClosingBalance,
	|	SUM(AllotmentRawSales.InHouseBedsClosingBalance) AS InHouseBedsClosingBalance,
	|	SUM(AllotmentRawSales.OccupiedRoomsClosingBalance) AS OccupiedRoomsClosingBalance,
	|	SUM(AllotmentRawSales.OccupiedBedsClosingBalance) AS OccupiedBedsClosingBalance,
	|	SUM(AllotmentRawSales.RoomsRemainsClosingBalance) AS RoomsRemainsClosingBalance,
	|	SUM(AllotmentRawSales.BedsRemainsClosingBalance) AS BedsRemainsClosingBalance,
	|	SUM(AllotmentRawSales.RoomsForecastClosingBalance) AS RoomsForecastClosingBalance,
	|	SUM(AllotmentRawSales.BedsForecastClosingBalance) AS BedsForecastClosingBalance
	|INTO AllotmentRawSales
	|FROM
	|	(SELECT
	|		RoomQuotaSales.Hotel AS Hotel,
	|		RoomQuotaSales.RoomQuota AS RoomQuota,
	|		RoomQuotaSales.IsQuotaForRooms AS IsQuotaForRooms,
	|		RoomQuotaSales.FlatRateIsUsedForUnderallotmentPenaltyCalculation AS FlatRateIsUsedForUnderallotmentPenaltyCalculation,
	|		RoomQuotaSales.FlatRateRoomType AS FlatRateRoomType,
	|		RoomQuotaSales.RoomType AS RoomType,
	|		RoomQuotaSales.Room AS Room,
	|		RoomQuotaSales.Period AS Period,
	|		RoomQuotaSales.CounterClosingBalance AS CounterClosingBalance,
	|		RoomQuotaSales.RoomsInQuotaClosingBalance AS RoomsInQuotaClosingBalance,
	|		RoomQuotaSales.BedsInQuotaClosingBalance AS BedsInQuotaClosingBalance,
	|		RoomQuotaSales.RoomsReservedClosingBalance AS RoomsReservedClosingBalance,
	|		RoomQuotaSales.BedsReservedClosingBalance AS BedsReservedClosingBalance,
	|		RoomQuotaSales.GuaranteedRoomsReservedClosingBalance AS GuaranteedRoomsReservedClosingBalance,
	|		RoomQuotaSales.GuaranteedBedsReservedClosingBalance AS GuaranteedBedsReservedClosingBalance,
	|		RoomQuotaSales.InHouseRoomsClosingBalance AS InHouseRoomsClosingBalance,
	|		RoomQuotaSales.InHouseBedsClosingBalance AS InHouseBedsClosingBalance,
	|		RoomQuotaSales.OccupiedRoomsClosingBalance AS OccupiedRoomsClosingBalance,
	|		RoomQuotaSales.OccupiedBedsClosingBalance AS OccupiedBedsClosingBalance,
	|		RoomQuotaSales.RoomsRemainsClosingBalance AS RoomsRemainsClosingBalance,
	|		RoomQuotaSales.BedsRemainsClosingBalance AS BedsRemainsClosingBalance,
	|		0 AS RoomsForecastClosingBalance,
	|		0 AS BedsForecastClosingBalance
	|	FROM
	|		RoomQuotaSales AS RoomQuotaSales
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ForecastData.Hotel,
	|		ForecastData.RoomQuota,
	|		ForecastData.IsQuotaForRooms,
	|		ForecastData.FlatRateIsUsedForUnderallotmentPenaltyCalculation,
	|		ForecastData.FlatRateRoomType,
	|		ForecastData.RoomType,
	|		ForecastData.Room,
	|		ForecastData.Period,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		ForecastData.RoomsForecastClosingBalance,
	|		ForecastData.BedsForecastClosingBalance
	|	FROM
	|		ForecastData AS ForecastData) AS AllotmentRawSales
	|
	|GROUP BY
	|	AllotmentRawSales.Hotel,
	|	AllotmentRawSales.RoomQuota,
	|	AllotmentRawSales.IsQuotaForRooms,
	|	AllotmentRawSales.FlatRateIsUsedForUnderallotmentPenaltyCalculation,
	|	AllotmentRawSales.FlatRateRoomType,
	|	AllotmentRawSales.RoomType,
	|	AllotmentRawSales.Room,
	|	AllotmentRawSales.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllotmentSales.Hotel AS Hotel,
	|	AllotmentSales.RoomQuota AS RoomQuota,
	|	AllotmentSales.IsQuotaForRooms AS IsQuotaForRooms,
	|	AllotmentSales.RoomType AS RoomType,
	|	AllotmentSales.Room AS Room,
	|	AllotmentSales.Period AS Period,
	|	AllotmentSales.CounterClosingBalance AS CounterClosingBalance,
	|	AllotmentSales.RoomsInQuotaClosingBalance AS RoomsInQuotaClosingBalance,
	|	AllotmentSales.BedsInQuotaClosingBalance AS BedsInQuotaClosingBalance,
	|	AllotmentSales.RoomsReservedClosingBalance AS RoomsReservedClosingBalance,
	|	AllotmentSales.BedsReservedClosingBalance AS BedsReservedClosingBalance,
	|	AllotmentSales.GuaranteedRoomsReservedClosingBalance AS GuaranteedRoomsReservedClosingBalance,
	|	AllotmentSales.GuaranteedBedsReservedClosingBalance AS GuaranteedBedsReservedClosingBalance,
	|	AllotmentSales.InHouseRoomsClosingBalance AS InHouseRoomsClosingBalance,
	|	AllotmentSales.InHouseBedsClosingBalance AS InHouseBedsClosingBalance,
	|	AllotmentSales.OccupiedRoomsClosingBalance AS OccupiedRoomsClosingBalance,
	|	AllotmentSales.OccupiedBedsClosingBalance AS OccupiedBedsClosingBalance,
	|	AllotmentSales.RoomsRemainsClosingBalance AS RoomsRemainsClosingBalance,
	|	AllotmentSales.BedsRemainsClosingBalance AS BedsRemainsClosingBalance,
	|	AllotmentSales.RoomsForecastClosingBalance AS RoomsForecastClosingBalance,
	|	AllotmentSales.BedsForecastClosingBalance AS BedsForecastClosingBalance,
	|	AllotmentDailyPrices.RoomRate AS UnderAllotmentRoomRate,
	|	AllotmentDailyPrices.Price AS UnderAllotmentPrice,
	|	ISNULL(AllotmentDailyPrices.Price, 0) * AllotmentSales.RoomsRemainsClosingBalance AS UnderAllotmentSum,
	|	ISNULL(GuestsStatistics.GuestsCheckedIn, 0) AS GuestsCheckedIn,
	|	ISNULL(GuestsStatistics.GuestDays, 0) AS GuestDays
	|INTO AllotmentSalesWithPricesAndGuests
	|FROM
	|	AllotmentRawSales AS AllotmentSales
	|		LEFT JOIN AllotmentDailyPrices AS AllotmentDailyPrices
	|		ON (AllotmentDailyPrices.Hotel = AllotmentSales.Hotel)
	|			AND (AllotmentDailyPrices.RoomQuota = AllotmentSales.RoomQuota)
	|			AND (AllotmentDailyPrices.RoomType = AllotmentSales.RoomType
	|					AND NOT AllotmentSales.FlatRateIsUsedForUnderallotmentPenaltyCalculation
	|				OR AllotmentDailyPrices.RoomType = AllotmentSales.RoomType
	|					AND AllotmentSales.FlatRateIsUsedForUnderallotmentPenaltyCalculation
	|					AND AllotmentSales.FlatRateRoomType = VALUE(Catalog.RoomTypes.EmptyRef)
	|				OR AllotmentDailyPrices.RoomType = AllotmentSales.FlatRateRoomType
	|					AND AllotmentSales.FlatRateIsUsedForUnderallotmentPenaltyCalculation
	|					AND AllotmentSales.FlatRateRoomType <> VALUE(Catalog.RoomTypes.EmptyRef))
	|			AND (AllotmentDailyPrices.Period = AllotmentSales.Period)
	|		LEFT JOIN GuestsStatistics AS GuestsStatistics
	|		ON (GuestsStatistics.Hotel = AllotmentSales.Hotel)
	|			AND (GuestsStatistics.RoomQuota = AllotmentSales.RoomQuota)
	|			AND (GuestsStatistics.Period = AllotmentSales.Period)
	|			AND (GuestsStatistics.RoomType = AllotmentSales.RoomType)
	|			AND (GuestsStatistics.IsQuotaForRooms
	|					AND GuestsStatistics.Room = AllotmentSales.Room
	|				OR NOT GuestsStatistics.IsQuotaForRooms)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllotmentSalesWithPricesAndGuests.Hotel AS Hotel,
	|	AllotmentSalesWithPricesAndGuests.RoomQuota AS RoomQuota,
	|	AllotmentSalesWithPricesAndGuests.RoomQuota.Customer AS Customer,
	|	AllotmentSalesWithPricesAndGuests.RoomQuota.Contract AS Contract,
	|	AllotmentSalesWithPricesAndGuests.RoomQuota.Agent AS Agent,
	|	AllotmentSalesWithPricesAndGuests.IsQuotaForRooms AS IsQuotaForRooms,
	|	CASE
	|		WHEN &qRoomTypeIsUsed
	|			THEN AllotmentSalesWithPricesAndGuests.RoomType
	|		ELSE VALUE(Catalog.RoomTypes.EmptyRef)
	|	END AS RoomType,
	|	AllotmentSalesWithPricesAndGuests.Room AS Room,
	|	AllotmentSalesWithPricesAndGuests.Period AS Period,
	|	AllotmentSalesWithPricesAndGuests.CounterClosingBalance AS CounterClosingBalance,
	|	AllotmentSalesWithPricesAndGuests.RoomsInQuotaClosingBalance AS RoomsInQuotaClosingBalance,
	|	AllotmentSalesWithPricesAndGuests.BedsInQuotaClosingBalance AS BedsInQuotaClosingBalance,
	|	AllotmentSalesWithPricesAndGuests.RoomsReservedClosingBalance AS RoomsReservedClosingBalance,
	|	AllotmentSalesWithPricesAndGuests.BedsReservedClosingBalance AS BedsReservedClosingBalance,
	|	AllotmentSalesWithPricesAndGuests.GuaranteedRoomsReservedClosingBalance AS GuaranteedRoomsReservedClosingBalance,
	|	AllotmentSalesWithPricesAndGuests.GuaranteedBedsReservedClosingBalance AS GuaranteedBedsReservedClosingBalance,
	|	AllotmentSalesWithPricesAndGuests.InHouseRoomsClosingBalance AS InHouseRoomsClosingBalance,
	|	AllotmentSalesWithPricesAndGuests.InHouseBedsClosingBalance AS InHouseBedsClosingBalance,
	|	AllotmentSalesWithPricesAndGuests.OccupiedRoomsClosingBalance AS OccupiedRoomsClosingBalance,
	|	AllotmentSalesWithPricesAndGuests.OccupiedBedsClosingBalance AS OccupiedBedsClosingBalance,
	|	AllotmentSalesWithPricesAndGuests.RoomsRemainsClosingBalance AS RoomsRemainsClosingBalance,
	|	AllotmentSalesWithPricesAndGuests.BedsRemainsClosingBalance AS BedsRemainsClosingBalance,
	|	AllotmentSalesWithPricesAndGuests.RoomsForecastClosingBalance AS RoomsForecastClosingBalance,
	|	AllotmentSalesWithPricesAndGuests.BedsForecastClosingBalance AS BedsForecastClosingBalance,
	|	AllotmentSalesWithPricesAndGuests.UnderAllotmentRoomRate AS UnderAllotmentRoomRate,
	|	AllotmentSalesWithPricesAndGuests.UnderAllotmentPrice AS UnderAllotmentPrice,
	|	AllotmentSalesWithPricesAndGuests.UnderAllotmentSum AS UnderAllotmentSum,
	|	AllotmentSalesWithPricesAndGuests.GuestsCheckedIn AS GuestsCheckedIn,
	|	AllotmentSalesWithPricesAndGuests.GuestDays AS GuestDays,
	|	CASE
	|		WHEN AllotmentSalesWithPricesAndGuests.RoomsInQuotaClosingBalance <> 0
	|			THEN AllotmentSalesWithPricesAndGuests.OccupiedRoomsClosingBalance / AllotmentSalesWithPricesAndGuests.RoomsInQuotaClosingBalance * 100
	|		ELSE 0
	|	END AS AllotmentRoomsOccupancyPercent,
	|	CASE
	|		WHEN AllotmentSalesWithPricesAndGuests.BedsInQuotaClosingBalance <> 0
	|			THEN AllotmentSalesWithPricesAndGuests.OccupiedBedsClosingBalance / AllotmentSalesWithPricesAndGuests.BedsInQuotaClosingBalance * 100
	|		ELSE 0
	|	END AS AllotmentBedsOccupancyPercent,
	|	CASE
	|		WHEN AllotmentSalesWithPricesAndGuests.RoomsInQuotaClosingBalance <> 0
	|			THEN 100 - AllotmentSalesWithPricesAndGuests.OccupiedRoomsClosingBalance / AllotmentSalesWithPricesAndGuests.RoomsInQuotaClosingBalance * 100
	|		ELSE 0
	|	END AS AllotmentRoomsVacantPercent,
	|	CASE
	|		WHEN AllotmentSalesWithPricesAndGuests.BedsInQuotaClosingBalance <> 0
	|			THEN 100 - AllotmentSalesWithPricesAndGuests.OccupiedBedsClosingBalance / AllotmentSalesWithPricesAndGuests.BedsInQuotaClosingBalance * 100
	|		ELSE 0
	|	END AS AllotmentBedsVacantPercent
	|INTO AllotmentSales
	|FROM
	|	AllotmentSalesWithPricesAndGuests AS AllotmentSalesWithPricesAndGuests
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllotmentSales.Hotel AS Hotel,
	|	AllotmentSales.Agent AS Agent,
	|	AllotmentSales.Customer AS Customer,
	|	AllotmentSales.Contract AS Contract,
	|	AllotmentSales.RoomQuota AS RoomQuota,
	|	AllotmentSales.RoomType AS RoomType,
	|	AllotmentSales.Room AS Room,
	|	AllotmentSales.Period AS Period,
	|	AllotmentSales.CounterClosingBalance AS CounterClosingBalance,
	|	AllotmentSales.RoomsInQuotaClosingBalance AS RoomsInQuotaClosingBalance,
	|	AllotmentSales.BedsInQuotaClosingBalance AS BedsInQuotaClosingBalance,
	|	AllotmentSales.RoomsReservedClosingBalance AS RoomsReservedClosingBalance,
	|	AllotmentSales.BedsReservedClosingBalance AS BedsReservedClosingBalance,
	|	AllotmentSales.GuaranteedRoomsReservedClosingBalance AS GuaranteedRoomsReservedClosingBalance,
	|	AllotmentSales.GuaranteedBedsReservedClosingBalance AS GuaranteedBedsReservedClosingBalance,
	|	AllotmentSales.InHouseRoomsClosingBalance AS InHouseRoomsClosingBalance,
	|	AllotmentSales.InHouseBedsClosingBalance AS InHouseBedsClosingBalance,
	|	AllotmentSales.OccupiedRoomsClosingBalance AS OccupiedRoomsClosingBalance,
	|	AllotmentSales.OccupiedBedsClosingBalance AS OccupiedBedsClosingBalance,
	|	AllotmentSales.RoomsRemainsClosingBalance AS RoomsRemainsClosingBalance,
	|	AllotmentSales.BedsRemainsClosingBalance AS BedsRemainsClosingBalance,
	|	AllotmentSales.RoomsForecastClosingBalance AS RoomsForecastClosingBalance,
	|	AllotmentSales.BedsForecastClosingBalance AS BedsForecastClosingBalance,
	|	AllotmentSales.AllotmentRoomsOccupancyPercent AS AllotmentRoomsOccupancyPercent,
	|	AllotmentSales.AllotmentBedsOccupancyPercent AS AllotmentBedsOccupancyPercent,
	|	AllotmentSales.AllotmentRoomsVacantPercent AS AllotmentRoomsVacantPercent,
	|	AllotmentSales.AllotmentBedsVacantPercent AS AllotmentBedsVacantPercent,
	|	AllotmentSales.UnderAllotmentRoomRate AS UnderAllotmentRoomRate,
	|	AllotmentSales.UnderAllotmentPrice AS UnderAllotmentPrice,
	|	AllotmentSales.UnderAllotmentSum AS UnderAllotmentSum,
	|	AllotmentSales.GuestsCheckedIn AS GuestsCheckedIn,
	|	AllotmentSales.GuestDays AS GuestDays,
	|	RoomTypeSales.TotalRooms AS TotalRooms,
	|	RoomTypeSales.VacantRooms AS TotalVacantRooms,
	|	RoomTypeSales.BlockedRooms AS TotalBlockedRooms,
	|	RoomTypeSales.OccupiedRooms AS TotalOccupiedRooms
	|{SELECT
	|	Agent.* AS Agent,
	|	Customer.* AS Customer,
	|	Contract.* AS Contract,
	|	RoomQuota.* AS RoomQuota,
	|	RoomType.* AS RoomType,
	|	Hotel.* AS Hotel,
	|	Room.* AS Room,
	|	Period,
	|	(BEGINOFPERIOD(AllotmentSales.Period, MONTH)) AS PeriodMonth,
	|	(DAY(AllotmentSales.Period)) AS PeriodDay,
	|	CounterClosingBalance,
	|	RoomsInQuotaClosingBalance,
	|	BedsInQuotaClosingBalance,
	|	RoomsReservedClosingBalance,
	|	BedsReservedClosingBalance,
	|	GuaranteedRoomsReservedClosingBalance,
	|	GuaranteedBedsReservedClosingBalance,
	|	InHouseRoomsClosingBalance,
	|	InHouseBedsClosingBalance,
	|	OccupiedRoomsClosingBalance,
	|	OccupiedBedsClosingBalance,
	|	RoomsRemainsClosingBalance,
	|	BedsRemainsClosingBalance,
	|	RoomsForecastClosingBalance,
	|	BedsForecastClosingBalance,
	|	AllotmentRoomsOccupancyPercent,
	|	AllotmentBedsOccupancyPercent,
	|	AllotmentRoomsVacantPercent,
	|	AllotmentBedsVacantPercent,
	|	UnderAllotmentRoomRate.*,
	|	UnderAllotmentPrice,
	|	UnderAllotmentSum,
	|	GuestsCheckedIn,
	|	GuestDays,
	|	TotalRooms,
	|	TotalVacantRooms,
	|	TotalBlockedRooms,
	|	TotalOccupiedRooms}
	|FROM
	|	AllotmentSales AS AllotmentSales
	|		LEFT JOIN (SELECT
	|			RoomTypeSales.Hotel AS Hotel,
	|			RoomTypeSales.RoomType AS RoomType,
	|			RoomTypeSales.Period AS Period,
	|			RoomTypeSales.TotalRoomsClosingBalance AS TotalRooms,
	|			RoomTypeSales.RoomsVacantClosingBalance AS VacantRooms,
	|			-RoomTypeSales.RoomsBlockedClosingBalance AS BlockedRooms,
	|			RoomTypeSales.TotalRoomsClosingBalance + RoomTypeSales.RoomsBlockedClosingBalance - RoomTypeSales.RoomsVacantClosingBalance AS OccupiedRooms
	|		FROM
	|			AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|					&qPeriodFrom,
	|					&qPeriodTo,
	|					DAY,
	|					RegisterRecordsAndPeriodBoundaries,
	|					(Hotel IN HIERARCHY (&qHotel)
	|						OR &qIsEmptyHotel)
	|						AND (RoomType IN HIERARCHY (&qRoomType)
	|							OR &qIsEmptyRoomType)) AS RoomTypeSales) AS RoomTypeSales
	|		ON AllotmentSales.Period = RoomTypeSales.Period
	|			AND AllotmentSales.RoomType = RoomTypeSales.RoomType
	|			AND AllotmentSales.Hotel = RoomTypeSales.Hotel
	|			AND (NOT AllotmentSales.RoomQuota.IsQuotaForRooms)
	|WHERE
	|	(AllotmentSales.RoomQuota.PeriodFrom < &qPeriodTo
	|			OR AllotmentSales.RoomQuota.PeriodFrom = &qEmptyDate)
	|	AND (AllotmentSales.RoomQuota.PeriodTo > &qPeriodFrom
	|			OR AllotmentSales.RoomQuota.PeriodTo = &qEmptyDate)
	|{WHERE
	|	AllotmentSales.Agent.* AS Agent,
	|	AllotmentSales.Customer.* AS Customer,
	|	AllotmentSales.Contract.* AS Contract,
	|	AllotmentSales.RoomQuota.* AS RoomQuota,
	|	AllotmentSales.Hotel.* AS Hotel,
	|	AllotmentSales.RoomType.* AS RoomType,
	|	AllotmentSales.Room.* AS Room,
	|	AllotmentSales.Period AS Period,
	|	(BEGINOFPERIOD(AllotmentSales.Period, MONTH)) AS PeriodMonth,
	|	(DAY(AllotmentSales.Period)) AS PeriodDay,
	|	AllotmentSales.RoomsInQuotaClosingBalance AS RoomsInQuotaClosingBalance,
	|	AllotmentSales.BedsInQuotaClosingBalance AS BedsInQuotaClosingBalance,
	|	AllotmentSales.RoomsReservedClosingBalance AS RoomsReservedClosingBalance,
	|	AllotmentSales.BedsReservedClosingBalance AS BedsReservedClosingBalance,
	|	AllotmentSales.GuaranteedRoomsReservedClosingBalance AS GuaranteedRoomsReservedClosingBalance,
	|	AllotmentSales.GuaranteedBedsReservedClosingBalance AS GuaranteedBedsReservedClosingBalance,
	|	AllotmentSales.InHouseRoomsClosingBalance AS InHouseRoomsClosingBalance,
	|	AllotmentSales.InHouseBedsClosingBalance AS InHouseBedsClosingBalance,
	|	AllotmentSales.OccupiedRoomsClosingBalance AS OccupiedRoomsClosingBalance,
	|	AllotmentSales.OccupiedBedsClosingBalance AS OccupiedBedsClosingBalance,
	|	AllotmentSales.RoomsRemainsClosingBalance AS RoomsRemainsClosingBalance,
	|	AllotmentSales.BedsRemainsClosingBalance AS BedsRemainsClosingBalance,
	|	AllotmentSales.RoomsForecastClosingBalance AS RoomsForecastClosingBalance,
	|	AllotmentSales.BedsForecastClosingBalance AS BedsForecastClosingBalance,
	|	AllotmentSales.AllotmentRoomsOccupancyPercent AS AllotmentRoomsOccupancyPercent,
	|	AllotmentSales.AllotmentBedsOccupancyPercent AS AllotmentBedsOccupancyPercent,
	|	AllotmentSales.AllotmentRoomsVacantPercent AS AllotmentRoomsVacantPercent,
	|	AllotmentSales.AllotmentBedsVacantPercent AS AllotmentBedsVacantPercent,
	|	AllotmentSales.UnderAllotmentRoomRate.* AS UnderAllotmentRoomRate,
	|	AllotmentSales.UnderAllotmentPrice AS UnderAllotmentPrice,
	|	AllotmentSales.UnderAllotmentSum AS UnderAllotmentSum}
	|
	|ORDER BY
	|	RoomQuota,
	|	RoomType,
	|	Period
	|{ORDER BY
	|	Agent.* AS Agent,
	|	Customer.* AS Customer,
	|	Contract.* AS Contract,
	|	RoomQuota.* AS RoomQuota,
	|	(BEGINOFPERIOD(AllotmentSales.Period, MONTH)) AS PeriodMonth,
	|	(DAY(AllotmentSales.Period)) AS PeriodDay,
	|	Hotel.* AS Hotel,
	|	RoomType.* AS RoomType,
	|	Room.* AS Room,
	|	RoomsInQuotaClosingBalance,
	|	BedsInQuotaClosingBalance,
	|	RoomsReservedClosingBalance,
	|	BedsReservedClosingBalance,
	|	GuaranteedRoomsReservedClosingBalance,
	|	GuaranteedBedsReservedClosingBalance,
	|	InHouseRoomsClosingBalance,
	|	InHouseBedsClosingBalance,
	|	OccupiedRoomsClosingBalance,
	|	OccupiedBedsClosingBalance,
	|	RoomsRemainsClosingBalance,
	|	BedsRemainsClosingBalance,
	|	RoomsForecastClosingBalance,
	|	BedsForecastClosingBalance,
	|	AllotmentRoomsOccupancyPercent,
	|	AllotmentBedsOccupancyPercent,
	|	AllotmentRoomsVacantPercent,
	|	AllotmentBedsVacantPercent,
	|	Period,
	|	UnderAllotmentRoomRate.*,
	|	UnderAllotmentPrice,
	|	UnderAllotmentSum}
	|TOTALS
	|	SUM(RoomsInQuotaClosingBalance),
	|	SUM(BedsInQuotaClosingBalance),
	|	SUM(RoomsReservedClosingBalance),
	|	SUM(BedsReservedClosingBalance),
	|	SUM(GuaranteedRoomsReservedClosingBalance),
	|	SUM(GuaranteedBedsReservedClosingBalance),
	|	SUM(InHouseRoomsClosingBalance),
	|	SUM(InHouseBedsClosingBalance),
	|	SUM(OccupiedRoomsClosingBalance),
	|	SUM(OccupiedBedsClosingBalance),
	|	SUM(RoomsRemainsClosingBalance),
	|	SUM(BedsRemainsClosingBalance),
	|	SUM(RoomsForecastClosingBalance),
	|	SUM(BedsForecastClosingBalance),
	|	CASE
	|		WHEN SUM(RoomsInQuotaClosingBalance) <> 0
	|			THEN SUM(OccupiedRoomsClosingBalance) / SUM(RoomsInQuotaClosingBalance) * 100
	|		ELSE 0
	|	END AS AllotmentRoomsOccupancyPercent,
	|	CASE
	|		WHEN SUM(BedsInQuotaClosingBalance) <> 0
	|			THEN SUM(OccupiedBedsClosingBalance) / SUM(BedsInQuotaClosingBalance) * 100
	|		ELSE 0
	|	END AS AllotmentBedsOccupancyPercent,
	|	CASE
	|		WHEN SUM(RoomsInQuotaClosingBalance) <> 0
	|			THEN 100 - SUM(OccupiedRoomsClosingBalance) / SUM(RoomsInQuotaClosingBalance) * 100
	|		ELSE 0
	|	END AS AllotmentRoomsVacantPercent,
	|	CASE
	|		WHEN SUM(BedsInQuotaClosingBalance) <> 0
	|			THEN 100 - SUM(OccupiedBedsClosingBalance) / SUM(BedsInQuotaClosingBalance) * 100
	|		ELSE 0
	|	END AS AllotmentBedsVacantPercent,
	|	CASE
	|		WHEN &qFlatRateIsUsedForUnderallotmentPenaltyCalculation
	|			THEN CASE
	|					WHEN RoomType IS NULL
	|						THEN CASE
	|								WHEN SUM(UnderAllotmentSum) < 0
	|									THEN 0
	|								ELSE SUM(UnderAllotmentSum)
	|							END
	|					ELSE SUM(UnderAllotmentSum)
	|				END
	|		ELSE CASE
	|				WHEN SUM(UnderAllotmentSum) < 0
	|					THEN 0
	|				ELSE SUM(UnderAllotmentSum)
	|			END
	|	END AS UnderAllotmentSum,
	|	SUM(GuestsCheckedIn),
	|	SUM(GuestDays),
	|	CASE
	|		WHEN NOT RoomQuota IS NULL
	|			THEN MAX(TotalRooms)
	|		WHEN NOT RoomType IS NULL
	|			THEN MAX(TotalRooms)
	|		ELSE SUM(TotalRooms)
	|	END AS TotalRooms,
	|	CASE
	|		WHEN NOT RoomQuota IS NULL
	|			THEN MIN(TotalVacantRooms)
	|		WHEN NOT RoomType IS NULL
	|			THEN MIN(TotalVacantRooms)
	|		ELSE SUM(TotalVacantRooms)
	|	END AS TotalVacantRooms,
	|	CASE
	|		WHEN NOT RoomQuota IS NULL
	|			THEN MAX(TotalBlockedRooms)
	|		WHEN NOT RoomType IS NULL
	|			THEN MAX(TotalBlockedRooms)
	|		ELSE SUM(TotalBlockedRooms)
	|	END AS TotalBlockedRooms,
	|	CASE
	|		WHEN NOT RoomQuota IS NULL
	|			THEN MAX(TotalOccupiedRooms)
	|		WHEN NOT RoomType IS NULL
	|			THEN MAX(TotalOccupiedRooms)
	|		ELSE SUM(TotalOccupiedRooms)
	|	END AS TotalOccupiedRooms
	|BY
	|	OVERALL,
	|	RoomQuota,
	|	RoomType,
	|	Period
	|{TOTALS BY
	|	Agent.* AS Agent,
	|	Customer.* AS Customer,
	|	Contract.* AS Contract,
	|	RoomQuota.* AS RoomQuota,
	|	(BEGINOFPERIOD(AllotmentSales.Period, MONTH)) AS PeriodMonth,
	|	(DAY(AllotmentSales.Period)) AS PeriodDay,
	|	Hotel.* AS Hotel,
	|	RoomType.* AS RoomType,
	|	Room.* AS Room,
	|	Period,
	|	UnderAllotmentRoomRate.*,
	|	UnderAllotmentPrice}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("en='Allotment sales';ru='Продажи квот номеров';de='Allotmentverkaufsbericht'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
Function pmIsResource(pName) Export
	If pName = "RoomsInQuotaClosingBalance" Or
	   pName = "BedsInQuotaClosingBalance" Or 
	   pName = "RoomsReservedClosingBalance" Or 
	   pName = "BedsReservedClosingBalance" Or 
	   pName = "GuaranteedRoomsReservedClosingBalance" Or 
	   pName = "GuaranteedBedsReservedClosingBalance" Or 
	   pName = "InHouseRoomsClosingBalance" Or 
	   pName = "InHouseBedsClosingBalance" Or 
	   pName = "OccupiedRoomsClosingBalance" Or 
	   pName = "OccupiedBedsClosingBalance" Or 
	   pName = "RoomsRemainsClosingBalance" Or 
	   pName = "BedsRemainsClosingBalance" Or
	   pName = "AllotmentRoomsOccupancyPercent" Or 
	   pName = "AllotmentBedsOccupancyPercent" Or 
	   pName = "AllotmentRoomsVacantPercent" Or 
	   pName = "UnderAllotmentSum" Or
	   pName = "GuestsCheckedIn" Or
	   pName = "GuestDays" Or
	   pName = "RoomsForecastClosingBalance" Or 
	   pName = "BedsForecastClosingBalance" Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // pmIsResource

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
