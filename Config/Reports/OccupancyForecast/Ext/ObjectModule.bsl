
#Region Variables

Var SalesResources;

#EndRegion

#Region Public

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
		PeriodFrom = BegOfDay(CurrentSessionDate()); // For beg of current date
		PeriodTo = EndOfDay(AddMonth(CurrentSessionDate(), 1)); // Same date of the next month
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
		                     Format(PeriodTo, "DF='dd.MM.yyyy HH:mm:ss'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom = PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период на '; en = 'Period on '; de = 'Periode '") + 
		                     Format(PeriodFrom, "DF='dd.MM.yyyy HH:mm:ss'") + 
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
Procedure pmGenerate(pSpreadsheet, pAddChart = False) Export
	Var vTemplateAttributes;
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
	
	// Initialize report builder query generator attributes
	ReportBuilder.PresentationAdding = PresentationAdditionType.Add;
	
	// Fill report parameters
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	vForecastStartDate = tcOnServer.GetForecastStartDate(Hotel);
	ReportBuilder.Parameters.Insert("qForecastPeriodFrom", Max(vForecastStartDate, PeriodFrom));
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qIsEmptyRoom", Not ValueIsFilled(Room));
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qEmptyRoomType", Catalogs.RoomTypes.EmptyRef());
	ReportBuilder.Parameters.Insert("qIsEmptyRoomType", Not ValueIsFilled(RoomType));
	ReportBuilder.Parameters.Insert("qService", Service);
	ReportBuilder.Parameters.Insert("qIsEmptyService", Not ValueIsFilled(Service));
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
	vShowSales = False;
	vSelectedFields = cmGetReportUsedFields(ReportBuilder);
	For Each vReportField In vSelectedFields Do
		If StrFind(SalesResources, vReportField.DataPath) > 0 Then
			vShowSales = True;
			Break;
		EndIf;
	EndDo;
	ReportBuilder.Parameters.Insert("qShowSales", vShowSales);
	vAllRoomTypes = cmGetAllRoomTypes(Hotel);
	vAllRoomTypesList = New ValueList();
	vAllRoomTypesList.LoadValues(vAllRoomTypes.UnloadColumn("RoomType"));
	ReportBuilder.Parameters.Insert("qRoomTypesList", vAllRoomTypesList);
	
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
	"SELECT DISTINCT
	|	RoomTypesInSales.RoomType AS RoomType
	|INTO RoomTypesInSales
	|FROM
	|	AccumulationRegister.Sales AS RoomTypesInSales
	|WHERE
	|	RoomTypesInSales.Period >= &qPeriodFrom
	|	AND RoomTypesInSales.Period <= &qPeriodTo
	|	AND NOT RoomTypesInSales.IsCorrection
	|	AND RoomTypesInSales.Hotel IN HIERARCHY(&qHotel)
	|	AND (RoomTypesInSales.Room IN HIERARCHY (&qRoom)
	|			OR &qIsEmptyRoom)
	|	AND (RoomTypesInSales.RoomType IN HIERARCHY (&qRoomType)
	|			OR &qIsEmptyRoomType)
	|	AND (RoomTypesInSales.Service IN HIERARCHY (&qService)
	|			OR &qIsEmptyService)
	|	AND (RoomTypesInSales.Service IN (&qServicesList)
	|			OR NOT &qUseServicesList)
	|	AND RoomTypesInSales.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomQuotaSales.Period AS Period,
	|	RoomQuotaSales.RoomType AS RoomType,
	|	ISNULL(RoomQuotaSales.CounterClosingBalance, 0) AS CounterClosingBalance,
	|	ISNULL(RoomQuotaSales.RoomsInQuotaClosingBalance, 0) AS RoomsInQuotaClosingBalance,
	|	ISNULL(RoomQuotaSales.BedsInQuotaClosingBalance, 0) AS BedsInQuotaClosingBalance,
	|	-ISNULL(RoomQuotaSales.RoomsReservedClosingBalance, 0) AS RoomsReservedClosingBalance,
	|	-ISNULL(RoomQuotaSales.BedsReservedClosingBalance, 0) AS BedsReservedClosingBalance,
	|	-ISNULL(RoomQuotaSales.InHouseRoomsClosingBalance, 0) AS InHouseRoomsClosingBalance,
	|	-ISNULL(RoomQuotaSales.InHouseBedsClosingBalance, 0) AS InHouseBedsClosingBalance,
	|	CASE
	|		WHEN ISNULL(RoomQuotaSales.RoomsRemainsClosingBalance, 0) < 0
	|			THEN 0
	|		ELSE ISNULL(RoomQuotaSales.RoomsRemainsClosingBalance, 0)
	|	END AS RoomsRemainsClosingBalance,
	|	CASE
	|		WHEN ISNULL(RoomQuotaSales.BedsRemainsClosingBalance, 0) < 0
	|			THEN 0
	|		ELSE ISNULL(RoomQuotaSales.BedsRemainsClosingBalance, 0)
	|	END AS BedsRemainsClosingBalance
	|INTO RoomQuotaSales
	|FROM
	|	AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			RegisterRecordsAndPeriodBoundaries,
	|			Hotel IN HIERARCHY (&qHotel)
	|				AND (Room IN HIERARCHY (&qRoom)
	|					OR &qIsEmptyRoom)
	|				AND (RoomType IN HIERARCHY (&qRoomType)
	|					OR &qIsEmptyRoomType)
	|				AND RoomQuota.DoWriteOff
	|				AND (NOT RoomType.DeletionMark
	|					OR RoomType IN
	|						(SELECT
	|							RoomTypesInSales.RoomType
	|						FROM
	|							RoomTypesInSales AS RoomTypesInSales))) AS RoomQuotaSales
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GuaranteedBusinessBlocks.Period AS Period,
	|	GuaranteedBusinessBlocks.RoomType AS RoomType,
	|	ISNULL(GuaranteedBusinessBlocks.CounterClosingBalance, 0) AS CounterClosingBalance,
	|	ISNULL(GuaranteedBusinessBlocks.RoomsInQuotaClosingBalance, 0) AS RoomsInQuotaClosingBalance,
	|	ISNULL(GuaranteedBusinessBlocks.BedsInQuotaClosingBalance, 0) AS BedsInQuotaClosingBalance,
	|	-ISNULL(GuaranteedBusinessBlocks.RoomsReservedClosingBalance, 0) AS RoomsReservedClosingBalance,
	|	-ISNULL(GuaranteedBusinessBlocks.BedsReservedClosingBalance, 0) AS BedsReservedClosingBalance,
	|	-ISNULL(GuaranteedBusinessBlocks.InHouseRoomsClosingBalance, 0) AS InHouseRoomsClosingBalance,
	|	-ISNULL(GuaranteedBusinessBlocks.InHouseBedsClosingBalance, 0) AS InHouseBedsClosingBalance,
	|	ISNULL(GuaranteedBusinessBlocks.RoomsRemainsClosingBalance, 0) AS RoomsRemainsClosingBalance,
	|	ISNULL(GuaranteedBusinessBlocks.BedsRemainsClosingBalance, 0) AS BedsRemainsClosingBalance
	|INTO GuaranteedBusinessBlocks
	|FROM
	|	AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			RegisterRecordsAndPeriodBoundaries,
	|			Hotel IN HIERARCHY (&qHotel)
	|				AND (Room IN HIERARCHY (&qRoom)
	|					OR &qIsEmptyRoom)
	|				AND (RoomType IN HIERARCHY (&qRoomType)
	|					OR &qIsEmptyRoomType)
	|				AND RoomQuota.AllotmentType = VALUE(Enum.AllotmentTypes.Definite)
	|				AND RoomQuota.AllotmentBusinessType = VALUE(Enum.AllotmentBusinessTypes.BusinessBlock)
	|				AND (NOT RoomType.DeletionMark
	|					OR RoomType IN
	|						(SELECT
	|							RoomTypesInSales.RoomType
	|						FROM
	|							RoomTypesInSales AS RoomTypesInSales))) AS GuaranteedBusinessBlocks
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NotGuaranteedBusinessBlocks.Period AS Period,
	|	NotGuaranteedBusinessBlocks.RoomType AS RoomType,
	|	ISNULL(NotGuaranteedBusinessBlocks.CounterClosingBalance, 0) AS CounterClosingBalance,
	|	ISNULL(NotGuaranteedBusinessBlocks.RoomsInQuotaClosingBalance, 0) AS RoomsInQuotaClosingBalance,
	|	ISNULL(NotGuaranteedBusinessBlocks.BedsInQuotaClosingBalance, 0) AS BedsInQuotaClosingBalance,
	|	-ISNULL(NotGuaranteedBusinessBlocks.RoomsReservedClosingBalance, 0) AS RoomsReservedClosingBalance,
	|	-ISNULL(NotGuaranteedBusinessBlocks.BedsReservedClosingBalance, 0) AS BedsReservedClosingBalance,
	|	-ISNULL(NotGuaranteedBusinessBlocks.InHouseRoomsClosingBalance, 0) AS InHouseRoomsClosingBalance,
	|	-ISNULL(NotGuaranteedBusinessBlocks.InHouseBedsClosingBalance, 0) AS InHouseBedsClosingBalance,
	|	ISNULL(NotGuaranteedBusinessBlocks.RoomsRemainsClosingBalance, 0) AS RoomsRemainsClosingBalance,
	|	ISNULL(NotGuaranteedBusinessBlocks.BedsRemainsClosingBalance, 0) AS BedsRemainsClosingBalance
	|INTO NotGuaranteedBusinessBlocks
	|FROM
	|	AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			RegisterRecordsAndPeriodBoundaries,
	|			Hotel IN HIERARCHY (&qHotel)
	|				AND (Room IN HIERARCHY (&qRoom)
	|					OR &qIsEmptyRoom)
	|				AND (RoomType IN HIERARCHY (&qRoomType)
	|					OR &qIsEmptyRoomType)
	|				AND (RoomQuota.AllotmentType = VALUE(Enum.AllotmentTypes.DefiniteNotGuaranteed)
	|					OR RoomQuota.AllotmentType = VALUE(Enum.AllotmentTypes.Tentative))
	|				AND (NOT RoomType.DeletionMark
	|					OR RoomType IN
	|						(SELECT
	|							RoomTypesInSales.RoomType
	|						FROM
	|							RoomTypesInSales AS RoomTypesInSales))) AS NotGuaranteedBusinessBlocks
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NotCommitmentAllotments.Period AS Period,
	|	NotCommitmentAllotments.RoomType AS RoomType,
	|	ISNULL(NotCommitmentAllotments.CounterClosingBalance, 0) AS CounterClosingBalance,
	|	ISNULL(NotCommitmentAllotments.RoomsInQuotaClosingBalance, 0) AS RoomsInQuotaClosingBalance,
	|	ISNULL(NotCommitmentAllotments.BedsInQuotaClosingBalance, 0) AS BedsInQuotaClosingBalance,
	|	-ISNULL(NotCommitmentAllotments.RoomsReservedClosingBalance, 0) AS RoomsReservedClosingBalance,
	|	-ISNULL(NotCommitmentAllotments.BedsReservedClosingBalance, 0) AS BedsReservedClosingBalance,
	|	-ISNULL(NotCommitmentAllotments.InHouseRoomsClosingBalance, 0) AS InHouseRoomsClosingBalance,
	|	-ISNULL(NotCommitmentAllotments.InHouseBedsClosingBalance, 0) AS InHouseBedsClosingBalance,
	|	CASE
	|		WHEN ISNULL(NotCommitmentAllotments.RoomsRemainsClosingBalance, 0) < 0
	|			THEN 0
	|		ELSE ISNULL(NotCommitmentAllotments.RoomsRemainsClosingBalance, 0)
	|	END AS RoomsRemainsClosingBalance,
	|	CASE
	|		WHEN ISNULL(NotCommitmentAllotments.BedsRemainsClosingBalance, 0) < 0
	|			THEN 0
	|		ELSE ISNULL(NotCommitmentAllotments.BedsRemainsClosingBalance, 0)
	|	END AS BedsRemainsClosingBalance
	|INTO NotCommitmentAllotments
	|FROM
	|	AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			RegisterRecordsAndPeriodBoundaries,
	|			Hotel IN HIERARCHY (&qHotel)
	|				AND (Room IN HIERARCHY (&qRoom)
	|					OR &qIsEmptyRoom)
	|				AND (RoomType IN HIERARCHY (&qRoomType)
	|					OR &qIsEmptyRoomType)
	|				AND NOT RoomQuota.IsCommitment
	|				AND (NOT RoomType.DeletionMark
	|					OR RoomType IN
	|						(SELECT
	|							RoomTypesInSales.RoomType
	|						FROM
	|							RoomTypesInSales AS RoomTypesInSales))) AS NotCommitmentAllotments
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CommitmentAllotments.Period AS Period,
	|	CommitmentAllotments.RoomType AS RoomType,
	|	ISNULL(CommitmentAllotments.CounterClosingBalance, 0) AS CounterClosingBalance,
	|	ISNULL(CommitmentAllotments.RoomsInQuotaClosingBalance, 0) AS RoomsInQuotaClosingBalance,
	|	ISNULL(CommitmentAllotments.BedsInQuotaClosingBalance, 0) AS BedsInQuotaClosingBalance,
	|	ISNULL(CommitmentAllotments.RoomsInQuotaOpeningBalance, 0) AS RoomsInQuotaOpeningBalance,
	|	ISNULL(CommitmentAllotments.BedsInQuotaOpeningBalance, 0) AS BedsInQuotaOpeningBalance,
	|	-ISNULL(CommitmentAllotments.RoomsReservedClosingBalance, 0) AS RoomsReservedClosingBalance,
	|	-ISNULL(CommitmentAllotments.BedsReservedClosingBalance, 0) AS BedsReservedClosingBalance,
	|	-ISNULL(CommitmentAllotments.RoomsReservedOpeningBalance, 0) AS RoomsReservedOpeningBalance,
	|	-ISNULL(CommitmentAllotments.BedsReservedOpeningBalance, 0) AS BedsReservedOpeningBalance,
	|	-ISNULL(CommitmentAllotments.InHouseRoomsClosingBalance, 0) AS InHouseRoomsClosingBalance,
	|	-ISNULL(CommitmentAllotments.InHouseBedsClosingBalance, 0) AS InHouseBedsClosingBalance,
	|	-ISNULL(CommitmentAllotments.InHouseRoomsOpeningBalance, 0) AS InHouseRoomsOpeningBalance,
	|	-ISNULL(CommitmentAllotments.InHouseBedsOpeningBalance, 0) AS InHouseBedsOpeningBalance,
	|	CASE
	|		WHEN ISNULL(CommitmentAllotments.RoomsRemainsClosingBalance, 0) < 0
	|			THEN 0
	|		ELSE ISNULL(CommitmentAllotments.RoomsRemainsClosingBalance, 0)
	|	END AS RoomsRemainsClosingBalance,
	|	CASE
	|		WHEN ISNULL(CommitmentAllotments.BedsRemainsClosingBalance, 0) < 0
	|			THEN 0
	|		ELSE ISNULL(CommitmentAllotments.BedsRemainsClosingBalance, 0)
	|	END AS BedsRemainsClosingBalance,
	|	CASE
	|		WHEN ISNULL(CommitmentAllotments.RoomsRemainsOpeningBalance, 0) < 0
	|			THEN 0
	|		ELSE ISNULL(CommitmentAllotments.RoomsRemainsOpeningBalance, 0)
	|	END AS RoomsRemainsOpeningBalance,
	|	CASE
	|		WHEN ISNULL(CommitmentAllotments.BedsRemainsOpeningBalance, 0) < 0
	|			THEN 0
	|		ELSE ISNULL(CommitmentAllotments.BedsRemainsOpeningBalance, 0)
	|	END AS BedsRemainsOpeningBalance
	|INTO CommitmentAllotments
	|FROM
	|	AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			RegisterRecordsAndPeriodBoundaries,
	|			Hotel IN HIERARCHY (&qHotel)
	|				AND (Room IN HIERARCHY (&qRoom)
	|					OR &qIsEmptyRoom)
	|				AND (RoomType IN HIERARCHY (&qRoomType)
	|					OR &qIsEmptyRoomType)
	|				AND RoomQuota.IsCommitment
	|				AND (NOT RoomType.DeletionMark
	|					OR RoomType IN
	|						(SELECT
	|							RoomTypesInSales.RoomType
	|						FROM
	|							RoomTypesInSales AS RoomTypesInSales))) AS CommitmentAllotments
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TentativeGroups.Period AS Period,
	|	TentativeGroups.RoomType AS RoomType,
	|	ISNULL(TentativeGroups.RoomsReservedTurnover, 0) AS TentativeRooms,
	|	ISNULL(TentativeGroups.BedsReservedTurnover, 0) AS TentativeBeds,
	|	ISNULL(TentativeGroups.AdditionalBedsReservedTurnover, 0) AS TentativeAdditionalBeds,
	|	ISNULL(TentativeGroups.GuestsReservedTurnover, 0) AS TentativeGuests
	|INTO TentativeGroups
	|FROM
	|	AccumulationRegister.ExpectedGuestGroups.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			Hotel IN HIERARCHY (&qHotel)
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
	|				END
	|				AND (NOT RoomType.DeletionMark
	|					OR RoomType IN
	|						(SELECT
	|							RoomTypesInSales.RoomType
	|						FROM
	|							RoomTypesInSales AS RoomTypesInSales))) AS TentativeGroups
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OccupancyForecast.AccountingDate AS AccountingDate,
	|	OccupancyForecast.RoomType AS RoomType,
	|	OccupancyForecast.TotalRooms AS TotalRooms,
	|	OccupancyForecast.TotalBeds AS TotalBeds,
	|	OccupancyForecast.RoomsAvailable AS RoomsAvailable,
	|	OccupancyForecast.BedsAvailable AS BedsAvailable,
	|	OccupancyForecast.OccupiedRooms AS OccupiedRooms,
	|	OccupancyForecast.OccupiedBeds AS OccupiedBeds,
	|	OccupancyForecast.OccupiedAdditionalBeds AS OccupiedAdditionalBeds,
	|	OccupancyForecast.OccupiedGuests AS OccupiedGuests,
	|	OccupancyForecast.OccupiedRoomsAtMorning AS OccupiedRoomsAtMorning,
	|	OccupancyForecast.OccupiedBedsAtMorning AS OccupiedBedsAtMorning,
	|	OccupancyForecast.UsedRooms AS UsedRooms,
	|	OccupancyForecast.UsedBeds AS UsedBeds,
	|	OccupancyForecast.RoomsReserved AS RoomsReserved,
	|	OccupancyForecast.BedsReserved AS BedsReserved,
	|	OccupancyForecast.GuaranteedRoomsReserved AS GuaranteedRoomsReserved,
	|	OccupancyForecast.GuaranteedBedsReserved AS GuaranteedBedsReserved,
	|	OccupancyForecast.GuaranteedGuestsReserved AS GuaranteedGuestsReserved,
	|	OccupancyForecast.NonGuaranteedRoomsReserved AS NonGuaranteedRoomsReserved,
	|	OccupancyForecast.NonGuaranteedBedsReserved AS NonGuaranteedBedsReserved,
	|	OccupancyForecast.NonGuaranteedGuestsReserved AS NonGuaranteedGuestsReserved,
	|	OccupancyForecast.NonGuaranteedRoomsReservedWithTentativeBusinessBlocks AS NonGuaranteedRoomsReservedWithTentativeBusinessBlocks,
	|	OccupancyForecast.NonGuaranteedBedsReservedWithTentativeBusinessBlocks AS NonGuaranteedBedsReservedWithTentativeBusinessBlocks,
	|	OccupancyForecast.OccupiedRoomsWithBusinessBlocks AS OccupiedRoomsWithBusinessBlocks,
	|	OccupancyForecast.OccupiedBedsWithBusinessBlocks AS OccupiedBedsWithBusinessBlocks,
	|	OccupancyForecast.InHouseRooms AS InHouseRooms,
	|	OccupancyForecast.InHouseBeds AS InHouseBeds,
	|	OccupancyForecast.InHouseGuests AS InHouseGuests,
	|	OccupancyForecast.GuaranteedAndInHouseRooms AS GuaranteedAndInHouseRooms,
	|	OccupancyForecast.GuaranteedAndInHouseBeds AS GuaranteedAndInHouseBeds,
	|	OccupancyForecast.GuaranteedAndInHouseGuests AS GuaranteedAndInHouseGuests,
	|	OccupancyForecast.GuaranteedAndInHouseRoomsWithDefiniteBusinessBlocks AS GuaranteedAndInHouseRoomsWithDefiniteBusinessBlocks,
	|	OccupancyForecast.GuaranteedAndInHouseBedsWithDefiniteBusinessBlocks AS GuaranteedAndInHouseBedsWithDefiniteBusinessBlocks,
	|	OccupancyForecast.RoomsInDefiniteBusinessBlocks AS RoomsInDefiniteBusinessBlocks,
	|	OccupancyForecast.BedsInDefiniteBusinessBlocks AS BedsInDefiniteBusinessBlocks,
	|	OccupancyForecast.RoomsInTentativeBusinessBlocks AS RoomsInTentativeBusinessBlocks,
	|	OccupancyForecast.BedsInTentativeBusinessBlocks AS BedsInTentativeBusinessBlocks,
	|	OccupancyForecast.RoomsCheckedOut AS RoomsCheckedOut,
	|	OccupancyForecast.BedsCheckedOut AS BedsCheckedOut,
	|	OccupancyForecast.AdditionalBedsCheckedOut AS AdditionalBedsCheckedOut,
	|	ISNULL(OccupancyForecast.RoomsInQuota, 0) AS RoomsInQuota,
	|	ISNULL(OccupancyForecast.BedsInQuota, 0) AS BedsInQuota,
	|	ISNULL(OccupancyForecast.RoomsRemainsInQuota, 0) AS RoomsRemainsInQuota,
	|	ISNULL(OccupancyForecast.BedsRemainsInQuota, 0) AS BedsRemainsInQuota,
	|	ISNULL(OccupancyForecast.RoomsReservedInQuota, 0) AS RoomsReservedInQuota,
	|	ISNULL(OccupancyForecast.BedsReservedInQuota, 0) AS BedsReservedInQuota,
	|	ISNULL(OccupancyForecast.RoomsInHouseInQuota, 0) AS RoomsInHouseInQuota,
	|	ISNULL(OccupancyForecast.BedsInHouseInQuota, 0) AS BedsInHouseInQuota,
	|	ISNULL(OccupancyForecast.RoomsOccupiedInQuota, 0) AS RoomsOccupiedInQuota,
	|	ISNULL(OccupancyForecast.BedsOccupiedInQuota, 0) AS BedsOccupiedInQuota,
	|	OccupancyForecast.RoomsSold AS RoomsSold,
	|	OccupancyForecast.BedsSold AS BedsSold,
	|	OccupancyForecast.RoomsSoldAtMorning AS RoomsSoldAtMorning,
	|	OccupancyForecast.BedsSoldAtMorning AS BedsSoldAtMorning,
	|	OccupancyForecast.GuaranteedRoomsRentedPercent AS GuaranteedRoomsRentedPercent,
	|	OccupancyForecast.GuaranteedBedsRentedPercent AS GuaranteedBedsRentedPercent,
	|	OccupancyForecast.NonGuaranteedRoomsRentedPercent AS NonGuaranteedRoomsRentedPercent,
	|	OccupancyForecast.NonGuaranteedBedsRentedPercent AS NonGuaranteedBedsRentedPercent,
	|	OccupancyForecast.RoomsRentedPercent AS RoomsRentedPercent,
	|	OccupancyForecast.BedsRentedPercent AS BedsRentedPercent,
	|	OccupancyForecast.RoomsRentedPercentWithoutBlocks AS RoomsRentedPercentWithoutBlocks,
	|	OccupancyForecast.BedsRentedPercentWithoutBlocks AS BedsRentedPercentWithoutBlocks,
	|	OccupancyForecast.RoomsOccupancyPercent AS RoomsOccupancyPercent,
	|	OccupancyForecast.BedsOccupancyPercent AS BedsOccupancyPercent,
	|	OccupancyForecast.GuaranteedRoomsOccupancyPercent AS GuaranteedRoomsOccupancyPercent,
	|	OccupancyForecast.GuaranteedBedsOccupancyPercent AS GuaranteedBedsOccupancyPercent,
	|	OccupancyForecast.NonGuaranteedRoomsOccupancyPercent AS NonGuaranteedRoomsOccupancyPercent,
	|	OccupancyForecast.NonGuaranteedBedsOccupancyPercent AS NonGuaranteedBedsOccupancyPercent,
	|	OccupancyForecast.RoomsUsedPercent AS RoomsUsedPercent,
	|	OccupancyForecast.BedsUsedPercent AS BedsUsedPercent,
	|	OccupancyForecast.GuaranteedRoomsUsedPercent AS GuaranteedRoomsUsedPercent,
	|	OccupancyForecast.GuaranteedBedsUsedPercent AS GuaranteedBedsUsedPercent,
	|	OccupancyForecast.NonGuaranteedRoomsUsedPercent AS NonGuaranteedRoomsUsedPercent,
	|	OccupancyForecast.NonGuaranteedBedsUsedPercent AS NonGuaranteedBedsUsedPercent,
	|	OccupancyForecast.RoomsBlocked AS RoomsBlocked,
	|	OccupancyForecast.BedsBlocked AS BedsBlocked,
	|	OccupancyForecast.RoomsVacant AS RoomsVacant,
	|	OccupancyForecast.BedsVacant AS BedsVacant,
	|	ISNULL(OccupancyForecast.NotCommitmentRoomsInQuota, 0) AS NotCommitmentRoomsInQuota,
	|	ISNULL(OccupancyForecast.NotCommitmentBedsInQuota, 0) AS NotCommitmentBedsInQuota,
	|	ISNULL(OccupancyForecast.NotCommitmentRoomsReserved, 0) AS NotCommitmentRoomsReserved,
	|	ISNULL(OccupancyForecast.NotCommitmentBedsReserved, 0) AS NotCommitmentBedsReserved,
	|	ISNULL(OccupancyForecast.NotCommitmentRoomsInHouse, 0) AS NotCommitmentRoomsInHouse,
	|	ISNULL(OccupancyForecast.NotCommitmentBedsInHouse, 0) AS NotCommitmentBedsInHouse,
	|	ISNULL(OccupancyForecast.NotCommitmentRoomsOccupied, 0) AS NotCommitmentRoomsOccupied,
	|	ISNULL(OccupancyForecast.NotCommitmentBedsOccupied, 0) AS NotCommitmentBedsOccupied,
	|	ISNULL(OccupancyForecast.NotCommitmentRoomsRemains, 0) AS NotCommitmentRoomsRemains,
	|	ISNULL(OccupancyForecast.NotCommitmentBedsRemains, 0) AS NotCommitmentBedsRemains,
	|	ISNULL(OccupancyForecast.CommitmentRoomsInQuota, 0) AS CommitmentRoomsInQuota,
	|	ISNULL(OccupancyForecast.CommitmentBedsInQuota, 0) AS CommitmentBedsInQuota,
	|	ISNULL(OccupancyForecast.CommitmentRoomsInQuotaAtMorning, 0) AS CommitmentRoomsInQuotaAtMorning,
	|	ISNULL(OccupancyForecast.CommitmentBedsInQuotaAtMorning, 0) AS CommitmentBedsInQuotaAtMorning,
	|	ISNULL(OccupancyForecast.CommitmentRoomsReserved, 0) AS CommitmentRoomsReserved,
	|	ISNULL(OccupancyForecast.CommitmentBedsReserved, 0) AS CommitmentBedsReserved,
	|	ISNULL(OccupancyForecast.CommitmentRoomsReservedAtMorning, 0) AS CommitmentRoomsReservedAtMorning,
	|	ISNULL(OccupancyForecast.CommitmentBedsReservedAtMorning, 0) AS CommitmentBedsReservedAtMorning,
	|	ISNULL(OccupancyForecast.CommitmentRoomsInHouse, 0) AS CommitmentRoomsInHouse,
	|	ISNULL(OccupancyForecast.CommitmentBedsInHouse, 0) AS CommitmentBedsInHouse,
	|	ISNULL(OccupancyForecast.CommitmentRoomsInHouseAtMorning, 0) AS CommitmentRoomsInHouseAtMorning,
	|	ISNULL(OccupancyForecast.CommitmentBedsInHouseAtMorning, 0) AS CommitmentBedsInHouseAtMorning,
	|	ISNULL(OccupancyForecast.CommitmentRoomsOccupied, 0) AS CommitmentRoomsOccupied,
	|	ISNULL(OccupancyForecast.CommitmentBedsOccupied, 0) AS CommitmentBedsOccupied,
	|	ISNULL(OccupancyForecast.CommitmentRoomsOccupiedAtMorning, 0) AS CommitmentRoomsOccupiedAtMorning,
	|	ISNULL(OccupancyForecast.CommitmentBedsOccupiedAtMorning, 0) AS CommitmentBedsOccupiedAtMorning,
	|	ISNULL(OccupancyForecast.CommitmentRoomsRemains, 0) AS CommitmentRoomsRemains,
	|	ISNULL(OccupancyForecast.CommitmentBedsRemains, 0) AS CommitmentBedsRemains,
	|	ISNULL(OccupancyForecast.CommitmentRoomsUsagePercent, 0) AS CommitmentRoomsUsagePercent,
	|	ISNULL(OccupancyForecast.CommitmentBedsUsagePercent, 0) AS CommitmentBedsUsagePercent,
	|	ISNULL(OccupancyForecast.CommitmentRoomsRemainsPercent, 0) AS CommitmentRoomsRemainsPercent,
	|	ISNULL(OccupancyForecast.CommitmentBedsRemainsPercent, 0) AS CommitmentBedsRemainsPercent,
	|	ISNULL(OccupancyForecast.RoomsVacantWithAllotments, 0) AS RoomsVacantWithAllotments,
	|	ISNULL(OccupancyForecast.BedsVacantWithAllotments, 0) AS BedsVacantWithAllotments,
	|	ISNULL(OccupancyForecast.RoomsVacantWithoutCommitment, 0) AS RoomsVacantWithoutCommitment,
	|	ISNULL(OccupancyForecast.BedsVacantWithoutCommitment, 0) AS BedsVacantWithoutCommitment,
	|	ISNULL(OccupancyForecast.CommitmentRoomsRemainsAtMorning, 0) AS CommitmentRoomsRemainsAtMorning,
	|	ISNULL(OccupancyForecast.CommitmentBedsRemainsAtMorning, 0) AS CommitmentBedsRemainsAtMorning,
	|	OccupancyForecast.RoomsCheckedIn AS RoomsCheckedIn,
	|	OccupancyForecast.BedsCheckedIn AS BedsCheckedIn,
	|	OccupancyForecast.AdditionalBedsCheckedIn AS AdditionalBedsCheckedIn,
	|	OccupancyForecast.GuestsCheckedIn AS GuestsCheckedIn,
	|	OccupancyForecast.ExpectedRoomsCheckedIn AS ExpectedRoomsCheckedIn,
	|	OccupancyForecast.ExpectedBedsCheckedIn AS ExpectedBedsCheckedIn,
	|	OccupancyForecast.ExpectedGuestsCheckedIn AS ExpectedGuestsCheckedIn,
	|	OccupancyForecast.GuaranteedExpectedRoomsCheckedIn AS GuaranteedExpectedRoomsCheckedIn,
	|	OccupancyForecast.GuaranteedExpectedBedsCheckedIn AS GuaranteedExpectedBedsCheckedIn,
	|	OccupancyForecast.GuaranteedExpectedGuestsCheckedIn AS GuaranteedExpectedGuestsCheckedIn,
	|	OccupancyForecast.NonGuaranteedExpectedRoomsCheckedIn AS NonGuaranteedExpectedRoomsCheckedIn,
	|	OccupancyForecast.NonGuaranteedExpectedBedsCheckedIn AS NonGuaranteedExpectedBedsCheckedIn,
	|	OccupancyForecast.NonGuaranteedExpectedGuestsCheckedIn AS NonGuaranteedExpectedGuestsCheckedIn,
	|	OccupancyForecast.ExpectedRoomsCheckedOut AS ExpectedRoomsCheckedOut,
	|	OccupancyForecast.ExpectedBedsCheckedOut AS ExpectedBedsCheckedOut,
	|	OccupancyForecast.ExpectedGuestsCheckedOut AS ExpectedGuestsCheckedOut,
	|	OccupancyForecast.GuestsReserved AS GuestsReserved,
	|	OccupancyForecast.GuestsCheckedOut AS GuestsCheckedOut,
	|	OccupancyForecast.TotalGuests AS TotalGuests,
	|	OccupancyForecast.TotalGuestsAtMorning AS TotalGuestsAtMorning,
	|	OccupancyForecast.RevPAR AS RevPAR,
	|	OccupancyForecast.RevPAB AS RevPAB,
	|	OccupancyForecast.RevPARWithoutVAT AS RevPARWithoutVAT,
	|	OccupancyForecast.RevPABWithoutVAT AS RevPABWithoutVAT,
	|	OccupancyForecast.AvgRoomPrice AS AvgRoomPrice,
	|	OccupancyForecast.AvgBedPrice AS AvgBedPrice,
	|	OccupancyForecast.AvgRoomPriceWithoutVAT AS AvgRoomPriceWithoutVAT,
	|	OccupancyForecast.AvgBedPriceWithoutVAT AS AvgBedPriceWithoutVAT,
	|	OccupancyForecast.GuaranteedAvgRoomPrice AS GuaranteedAvgRoomPrice,
	|	OccupancyForecast.GuaranteedAvgBedPrice AS GuaranteedAvgBedPrice,
	|	OccupancyForecast.NonGuaranteedAvgRoomPrice AS NonGuaranteedAvgRoomPrice,
	|	OccupancyForecast.NonGuaranteedAvgBedPrice AS NonGuaranteedAvgBedPrice,
	|	OccupancyForecast.GuaranteedAvgRoomPriceWithoutVAT AS GuaranteedAvgRoomPriceWithoutVAT,
	|	OccupancyForecast.GuaranteedAvgBedPriceWithoutVAT AS GuaranteedAvgBedPriceWithoutVAT,
	|	OccupancyForecast.NonGuaranteedAvgRoomPriceWithoutVAT AS NonGuaranteedAvgRoomPriceWithoutVAT,
	|	OccupancyForecast.NonGuaranteedAvgBedPriceWithoutVAT AS NonGuaranteedAvgBedPriceWithoutVAT,
	|	OccupancyForecast.AvgDailyRoomRate AS AvgDailyRoomRate,
	|	OccupancyForecast.AvgDailyBedRate AS AvgDailyBedRate,
	|	OccupancyForecast.AvgDailyRoomRateWithoutVAT AS AvgDailyRoomRateWithoutVAT,
	|	OccupancyForecast.AvgDailyBedRateWithoutVAT AS AvgDailyBedRateWithoutVAT,
	|	OccupancyForecast.GuaranteedRoomsRented AS GuaranteedRoomsRented,
	|	OccupancyForecast.GuaranteedBedsRented AS GuaranteedBedsRented,
	|	OccupancyForecast.NonGuaranteedRoomsRented AS NonGuaranteedRoomsRented,
	|	OccupancyForecast.NonGuaranteedBedsRented AS NonGuaranteedBedsRented,
	|	OccupancyForecast.RoomsRented AS RoomsRented,
	|	OccupancyForecast.BedsRented AS BedsRented,
	|	OccupancyForecast.Sales AS Sales,
	|	OccupancyForecast.RoomRevenue AS RoomRevenue,
	|	OccupancyForecast.SalesWithoutVAT AS SalesWithoutVAT,
	|	OccupancyForecast.RoomRevenueWithoutVAT AS RoomRevenueWithoutVAT,
	|	OccupancyForecast.GuaranteedSales AS GuaranteedSales,
	|	OccupancyForecast.GuaranteedRoomRevenue AS GuaranteedRoomRevenue,
	|	OccupancyForecast.GuaranteedSalesWithoutVAT AS GuaranteedSalesWithoutVAT,
	|	OccupancyForecast.GuaranteedRoomRevenueWithoutVAT AS GuaranteedRoomRevenueWithoutVAT,
	|	OccupancyForecast.NonGuaranteedSales AS NonGuaranteedSales,
	|	OccupancyForecast.NonGuaranteedRoomRevenue AS NonGuaranteedRoomRevenue,
	|	OccupancyForecast.NonGuaranteedSalesWithoutVAT AS NonGuaranteedSalesWithoutVAT,
	|	OccupancyForecast.NonGuaranteedRoomRevenueWithoutVAT AS NonGuaranteedRoomRevenueWithoutVAT,
	|	OccupancyForecast.DefinitiveSales AS DefinitiveSales,
	|	OccupancyForecast.DefinitiveRoomRevenue AS DefinitiveRoomRevenue,
	|	OccupancyForecast.DefinitiveSalesWithoutVAT AS DefinitiveSalesWithoutVAT,
	|	OccupancyForecast.DefinitiveRoomRevenueWithoutVAT AS DefinitiveRoomRevenueWithoutVAT,
	|	OccupancyForecast.TentativeSales AS TentativeSales,
	|	OccupancyForecast.TentativeRoomRevenue AS TentativeRoomRevenue,
	|	OccupancyForecast.TentativeSalesWithoutVAT AS TentativeSalesWithoutVAT,
	|	OccupancyForecast.TentativeRoomRevenueWithoutVAT AS TentativeRoomRevenueWithoutVAT,
	|	OccupancyForecast.TentativeRooms AS TentativeRooms,
	|	OccupancyForecast.TentativeBeds AS TentativeBeds,
	|	OccupancyForecast.TentativeAdditionalBeds AS TentativeAdditionalBeds,
	|	OccupancyForecast.DefinitiveAdults AS DefinitiveAdults,
	|	OccupancyForecast.DefinitiveChildren AS DefinitiveChildren,
	|	OccupancyForecast.DefinitiveGuests AS DefinitiveGuests,
	|	OccupancyForecast.TentativeAdults AS TentativeAdults,
	|	OccupancyForecast.TentativeChildren AS TentativeChildren,
	|	OccupancyForecast.TentativeGuests AS TentativeGuests,
	|	OccupancyForecast.ForecastSales AS ForecastSales,
	|	OccupancyForecast.ForecastRoomRevenue AS ForecastRoomRevenue,
	|	OccupancyForecast.ForecastSalesWithoutVAT AS ForecastSalesWithoutVAT,
	|	OccupancyForecast.ForecastRoomRevenueWithoutVAT AS ForecastRoomRevenueWithoutVAT,
	|	OccupancyForecast.InHouseSales AS InHouseSales,
	|	OccupancyForecast.InHouseRoomRevenue AS InHouseRoomRevenue,
	|	OccupancyForecast.InHouseSalesWithoutVAT AS InHouseSalesWithoutVAT,
	|	OccupancyForecast.InHouseRoomRevenueWithoutVAT AS InHouseRoomRevenueWithoutVAT,
	|	OccupancyForecast.CommissionSum AS CommissionSum,
	|	OccupancyForecast.CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|	OccupancyForecast.ForecastCommissionSum AS ForecastCommissionSum,
	|	OccupancyForecast.ForecastCommissionSumWithoutVAT AS ForecastCommissionSumWithoutVAT,
	|	OccupancyForecast.InHouseCommissionSum AS InHouseCommissionSum,
	|	OccupancyForecast.InHouseCommissionSumWithoutVAT AS InHouseCommissionSumWithoutVAT,
	|	OccupancyForecast.DiscountSum AS DiscountSum,
	|	OccupancyForecast.DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|	OccupancyForecast.ForecastDiscountSum AS ForecastDiscountSum,
	|	OccupancyForecast.ForecastDiscountSumWithoutVAT AS ForecastDiscountSumWithoutVAT,
	|	OccupancyForecast.InHouseDiscountSum AS InHouseDiscountSum,
	|	OccupancyForecast.InHouseDiscountSumWithoutVAT AS InHouseDiscountSumWithoutVAT,
	|	OccupancyForecast.DefinitiveTeenagers AS DefinitiveTeenagers,
	|	OccupancyForecast.DefinitiveChildrenOnly AS DefinitiveChildrenOnly,
	|	OccupancyForecast.DefinitiveInfants AS DefinitiveInfants,
	|	OccupancyForecast.TentativeTeenagers AS TentativeTeenagers,
	|	OccupancyForecast.TentativeChildrenOnly AS TentativeChildrenOnly,
	|	OccupancyForecast.TentativeInfants AS TentativeInfants
	|{SELECT
	|	AccountingDate,
	|	RoomType.*,
	|	TotalRooms,
	|	TotalBeds,
	|	RoomsAvailable,
	|	BedsAvailable,
	|	OccupiedRooms,
	|	OccupiedBeds,
	|	OccupiedAdditionalBeds,
	|	OccupiedGuests,
	|	OccupiedRoomsAtMorning,
	|	OccupiedBedsAtMorning,
	|	UsedRooms,
	|	UsedBeds,
	|	RoomsReserved,
	|	BedsReserved,
	|	GuaranteedRoomsReserved,
	|	GuaranteedBedsReserved,
	|	GuaranteedGuestsReserved,
	|	GuaranteedAndInHouseRooms,
	|	GuaranteedAndInHouseBeds,
	|	GuaranteedAndInHouseGuests,
	|	GuaranteedAndInHouseRoomsWithDefiniteBusinessBlocks,
	|	GuaranteedAndInHouseBedsWithDefiniteBusinessBlocks,
	|	RoomsInDefiniteBusinessBlocks,
	|	BedsInDefiniteBusinessBlocks,
	|	RoomsInTentativeBusinessBlocks,
	|	BedsInTentativeBusinessBlocks,
	|	NonGuaranteedRoomsReserved,
	|	NonGuaranteedBedsReserved,
	|	NonGuaranteedGuestsReserved,
	|	NonGuaranteedRoomsReservedWithTentativeBusinessBlocks,
	|	NonGuaranteedBedsReservedWithTentativeBusinessBlocks,
	|	OccupiedRoomsWithBusinessBlocks,
	|	OccupiedBedsWithBusinessBlocks,
	|	InHouseRooms,
	|	InHouseBeds,
	|	RoomsCheckedOut,
	|	BedsCheckedOut,
	|	AdditionalBedsCheckedOut,
	|	RoomsInQuota,
	|	BedsInQuota,
	|	RoomsRemainsInQuota,
	|	BedsRemainsInQuota,
	|	RoomsReservedInQuota,
	|	BedsReservedInQuota,
	|	RoomsInHouseInQuota,
	|	BedsInHouseInQuota,
	|	RoomsOccupiedInQuota,
	|	BedsOccupiedInQuota,
	|	RoomsSold,
	|	BedsSold,
	|	RoomsSoldAtMorning,
	|	BedsSoldAtMorning,
	|	GuaranteedRoomsRentedPercent,
	|	GuaranteedBedsRentedPercent,
	|	NonGuaranteedRoomsRentedPercent,
	|	NonGuaranteedBedsRentedPercent,
	|	RoomsRentedPercent,
	|	BedsRentedPercent,
	|	RoomsRentedPercentWithoutBlocks,
	|	BedsRentedPercentWithoutBlocks,
	|	RoomsOccupancyPercent,
	|	BedsOccupancyPercent,
	|	GuaranteedRoomsOccupancyPercent,
	|	GuaranteedBedsOccupancyPercent,
	|	NonGuaranteedRoomsOccupancyPercent,
	|	NonGuaranteedBedsOccupancyPercent,
	|	RoomsUsedPercent,
	|	BedsUsedPercent,
	|	GuaranteedRoomsUsedPercent,
	|	GuaranteedBedsUsedPercent,
	|	NonGuaranteedRoomsUsedPercent,
	|	NonGuaranteedBedsUsedPercent,
	|	RoomsBlocked,
	|	BedsBlocked,
	|	RoomsVacant,
	|	BedsVacant,
	|	NotCommitmentRoomsInQuota,
	|	NotCommitmentBedsInQuota,
	|	NotCommitmentRoomsReserved,
	|	NotCommitmentBedsReserved,
	|	NotCommitmentRoomsInHouse,
	|	NotCommitmentBedsInHouse,
	|	NotCommitmentRoomsOccupied,
	|	NotCommitmentBedsOccupied,
	|	NotCommitmentRoomsRemains,
	|	NotCommitmentBedsRemains,
	|	CommitmentRoomsInQuota,
	|	CommitmentBedsInQuota,
	|	CommitmentRoomsInQuotaAtMorning,
	|	CommitmentBedsInQuotaAtMorning,
	|	CommitmentRoomsReserved,
	|	CommitmentBedsReserved,
	|	CommitmentRoomsReservedAtMorning,
	|	CommitmentBedsReservedAtMorning,
	|	CommitmentRoomsInHouse,
	|	CommitmentBedsInHouse,
	|	CommitmentRoomsInHouseAtMorning,
	|	CommitmentBedsInHouseAtMorning,
	|	CommitmentRoomsOccupied,
	|	CommitmentBedsOccupied,
	|	CommitmentRoomsOccupiedAtMorning,
	|	CommitmentBedsOccupiedAtMorning,
	|	CommitmentRoomsRemains,
	|	CommitmentBedsRemains,
	|	CommitmentRoomsUsagePercent,
	|	CommitmentBedsUsagePercent,
	|	CommitmentRoomsRemainsPercent,
	|	CommitmentBedsRemainsPercent,
	|	CommitmentRoomsRemainsAtMorning,
	|	CommitmentBedsRemainsAtMorning,
	|	RoomsVacantWithAllotments,
	|	BedsVacantWithAllotments,
	|	RoomsVacantWithoutCommitment,
	|	BedsVacantWithoutCommitment,
	|	RoomsCheckedIn,
	|	BedsCheckedIn,
	|	AdditionalBedsCheckedIn,
	|	GuestsCheckedIn,
	|	ExpectedRoomsCheckedIn,
	|	ExpectedBedsCheckedIn,
	|	ExpectedGuestsCheckedIn,
	|	GuaranteedExpectedRoomsCheckedIn,
	|	GuaranteedExpectedBedsCheckedIn,
	|	GuaranteedExpectedGuestsCheckedIn,
	|	NonGuaranteedExpectedRoomsCheckedIn,
	|	NonGuaranteedExpectedBedsCheckedIn,
	|	NonGuaranteedExpectedGuestsCheckedIn,
	|	ExpectedRoomsCheckedOut,
	|	ExpectedBedsCheckedOut,
	|	ExpectedGuestsCheckedOut,
	|	GuestsReserved,
	|	InHouseGuests,
	|	GuestsCheckedOut,
	|	TotalGuests,
	|	TotalGuestsAtMorning,
	|	GuaranteedRoomsRented,
	|	GuaranteedBedsRented,
	|	NonGuaranteedRoomsRented,
	|	NonGuaranteedBedsRented,
	|	RoomsRented,
	|	BedsRented,
	|	Sales,
	|	RoomRevenue,
	|	SalesWithoutVAT,
	|	RoomRevenueWithoutVAT,
	|	RevPAR,
	|	RevPAB,
	|	RevPARWithoutVAT,
	|	RevPABWithoutVAT,
	|	AvgRoomPrice,
	|	AvgBedPrice,
	|	AvgRoomPriceWithoutVAT,
	|	AvgBedPriceWithoutVAT,
	|	GuaranteedAvgRoomPrice,
	|	GuaranteedAvgBedPrice,
	|	NonGuaranteedAvgRoomPrice,
	|	NonGuaranteedAvgBedPrice,
	|	GuaranteedAvgRoomPriceWithoutVAT,
	|	GuaranteedAvgBedPriceWithoutVAT,
	|	NonGuaranteedAvgRoomPriceWithoutVAT,
	|	NonGuaranteedAvgBedPriceWithoutVAT,
	|	AvgDailyRoomRate,
	|	AvgDailyBedRate,
	|	AvgDailyRoomRateWithoutVAT,
	|	AvgDailyBedRateWithoutVAT,
	|	GuaranteedSales,
	|	GuaranteedRoomRevenue,
	|	GuaranteedSalesWithoutVAT,
	|	GuaranteedRoomRevenueWithoutVAT,
	|	NonGuaranteedSales,
	|	NonGuaranteedRoomRevenue,
	|	NonGuaranteedSalesWithoutVAT,
	|	NonGuaranteedRoomRevenueWithoutVAT,
	|	ForecastSales,
	|	ForecastRoomRevenue,
	|	ForecastSalesWithoutVAT,
	|	ForecastRoomRevenueWithoutVAT,
	|	InHouseSales,
	|	InHouseRoomRevenue,
	|	InHouseSalesWithoutVAT,
	|	InHouseRoomRevenueWithoutVAT,
	|	CommissionSum,
	|	CommissionSumWithoutVAT,
	|	ForecastCommissionSum,
	|	ForecastCommissionSumWithoutVAT,
	|	InHouseCommissionSum,
	|	InHouseCommissionSumWithoutVAT,
	|	DiscountSum,
	|	DiscountSumWithoutVAT,
	|	ForecastDiscountSum,
	|	ForecastDiscountSumWithoutVAT,
	|	InHouseDiscountSum,
	|	InHouseDiscountSumWithoutVAT,
	|	DefinitiveSales,
	|	DefinitiveRoomRevenue,
	|	DefinitiveSalesWithoutVAT,
	|	DefinitiveRoomRevenueWithoutVAT,
	|	TentativeSales,
	|	TentativeRoomRevenue,
	|	TentativeSalesWithoutVAT,
	|	TentativeRoomRevenueWithoutVAT,
	|	TentativeRooms,
	|	TentativeBeds,
	|	TentativeAdditionalBeds,
	|	DefinitiveAdults,
	|	DefinitiveChildren,
	|	DefinitiveGuests,
	|	TentativeAdults,
	|	TentativeChildren,
	|	TentativeGuests,
	|	(BEGINOFPERIOD(OccupancyForecast.AccountingDate, WEEK)) AS AccountingWeek,
	|	(BEGINOFPERIOD(OccupancyForecast.AccountingDate, MONTH)) AS AccountingMonth,
	|	(BEGINOFPERIOD(OccupancyForecast.AccountingDate, QUARTER)) AS AccountingQuarter,
	|	(YEAR(OccupancyForecast.AccountingDate)) AS AccountingYear,
	|	DefinitiveTeenagers,
	|	DefinitiveChildrenOnly,
	|	DefinitiveInfants,
	|	TentativeTeenagers,
	|	TentativeChildrenOnly,
	|	TentativeInfants}
	|FROM
	|	(SELECT
	|		RoomInventory.Period AS AccountingDate,
	|		RoomInventory.RoomType AS RoomType,
	|		ISNULL(RoomInventory.CounterClosingBalance, 0) AS Counter,
	|		ISNULL(RoomQuotaSales.CounterClosingBalance, 0) AS CounterRoomQuotaSales,
	|		ISNULL(NotCommitmentAllotments.CounterClosingBalance, 0) AS CounterNotCommitmentAllotments,
	|		ISNULL(CommitmentAllotments.CounterClosingBalance, 0) AS CounterCommitmentAllotments,
	|		ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) + ISNULL(RoomInventory.RoomsBlockedClosingBalance, 0) - ISNULL(RoomInventory.RoomsBlockedClosingBalance, 0) AS TotalRooms,
	|		ISNULL(RoomInventory.TotalBedsClosingBalance, 0) + ISNULL(RoomInventory.BedsBlockedClosingBalance, 0) - ISNULL(RoomInventory.BedsBlockedClosingBalance, 0) AS TotalBeds,
	|		ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) + ISNULL(RoomInventory.RoomsBlockedClosingBalance, 0) AS RoomsAvailable,
	|		ISNULL(RoomInventory.TotalBedsClosingBalance, 0) + ISNULL(RoomInventory.BedsBlockedClosingBalance, 0) AS BedsAvailable,
	|		-ISNULL(RoomInventory.RoomsBlockedClosingBalance, 0) + ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) - ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) AS RoomsBlocked,
	|		-ISNULL(RoomInventory.BedsBlockedClosingBalance, 0) + ISNULL(RoomInventory.TotalBedsClosingBalance, 0) - ISNULL(RoomInventory.TotalBedsClosingBalance, 0) AS BedsBlocked,
	|		-ISNULL(RoomInventory.RoomsReservedClosingBalance, 0) - ISNULL(RoomInventory.InHouseRoomsClosingBalance, 0) + ISNULL(RoomInventory.InHouseRoomsClosingBalance, 0) AS RoomsReserved,
	|		-ISNULL(RoomInventory.BedsReservedClosingBalance, 0) - ISNULL(RoomInventory.InHouseBedsClosingBalance, 0) + ISNULL(RoomInventory.InHouseBedsClosingBalance, 0) AS BedsReserved,
	|		-ISNULL(RoomInventory.GuestsReservedClosingBalance, 0) - ISNULL(RoomInventory.InHouseGuestsClosingBalance, 0) + ISNULL(RoomInventory.InHouseGuestsClosingBalance, 0) AS GuestsReserved,
	|		-ISNULL(RoomInventory.InHouseRoomsClosingBalance, 0) - ISNULL(RoomInventory.RoomsReservedClosingBalance, 0) + ISNULL(RoomInventory.RoomsReservedClosingBalance, 0) AS InHouseRooms,
	|		-ISNULL(RoomInventory.InHouseBedsClosingBalance, 0) - ISNULL(RoomInventory.BedsReservedClosingBalance, 0) + ISNULL(RoomInventory.BedsReservedClosingBalance, 0) AS InHouseBeds,
	|		-ISNULL(RoomInventory.InHouseGuestsClosingBalance, 0) - ISNULL(RoomInventory.GuestsReservedClosingBalance, 0) + ISNULL(RoomInventory.GuestsReservedClosingBalance, 0) AS InHouseGuests,
	|		-ISNULL(RoomInventory.RoomsReservedClosingBalance, 0) - ISNULL(RoomInventory.InHouseRoomsClosingBalance, 0) AS OccupiedRooms,
	|		-ISNULL(RoomInventory.BedsReservedClosingBalance, 0) - ISNULL(RoomInventory.InHouseBedsClosingBalance, 0) AS OccupiedBeds,
	|		-ISNULL(RoomInventory.AdditionalBedsReservedClosingBalance, 0) - ISNULL(RoomInventory.InHouseAdditionalBedsClosingBalance, 0) AS OccupiedAdditionalBeds,
	|		-ISNULL(RoomInventory.GuestsReservedClosingBalance, 0) - ISNULL(RoomInventory.InHouseGuestsClosingBalance, 0) AS OccupiedGuests,
	|		-ISNULL(RoomInventory.RoomsReservedClosingBalance, 0) - ISNULL(RoomInventory.InHouseRoomsClosingBalance, 0) + ISNULL(RoomQuotaSales.RoomsRemainsClosingBalance, 0) AS UsedRooms,
	|		-ISNULL(RoomInventory.BedsReservedClosingBalance, 0) - ISNULL(RoomInventory.InHouseBedsClosingBalance, 0) + ISNULL(RoomQuotaSales.BedsRemainsClosingBalance, 0) AS UsedBeds,
	|		-ISNULL(RoomInventory.GuaranteedRoomsReservedClosingBalance, 0) - ISNULL(RoomInventory.RoomsReservedClosingBalance, 0) + ISNULL(RoomInventory.RoomsReservedClosingBalance, 0) AS GuaranteedRoomsReserved,
	|		-ISNULL(RoomInventory.GuaranteedBedsReservedClosingBalance, 0) - ISNULL(RoomInventory.BedsReservedClosingBalance, 0) + ISNULL(RoomInventory.BedsReservedClosingBalance, 0) AS GuaranteedBedsReserved,
	|		-ISNULL(RoomInventory.GuaranteedGuestsReservedClosingBalance, 0) - ISNULL(RoomInventory.InHouseGuestsClosingBalance, 0) + ISNULL(RoomInventory.InHouseGuestsClosingBalance, 0) AS GuaranteedGuestsReserved,
	|		-ISNULL(RoomInventory.RoomsReservedClosingBalance, 0) + ISNULL(RoomInventory.GuaranteedRoomsReservedClosingBalance, 0) + ISNULL(NotGuaranteedBusinessBlocks.RoomsRemainsClosingBalance, 0) + ISNULL(NotGuaranteedBusinessBlocks.CounterClosingBalance, 0) - ISNULL(NotGuaranteedBusinessBlocks.CounterClosingBalance, 0) AS NonGuaranteedRoomsReservedWithTentativeBusinessBlocks,
	|		-ISNULL(RoomInventory.BedsReservedClosingBalance, 0) + ISNULL(RoomInventory.GuaranteedBedsReservedClosingBalance, 0) + ISNULL(NotGuaranteedBusinessBlocks.BedsRemainsClosingBalance, 0) + ISNULL(NotGuaranteedBusinessBlocks.CounterClosingBalance, 0) - ISNULL(NotGuaranteedBusinessBlocks.CounterClosingBalance, 0) AS NonGuaranteedBedsReservedWithTentativeBusinessBlocks,
	|		-ISNULL(RoomInventory.InHouseRoomsClosingBalance, 0) - ISNULL(RoomInventory.RoomsReservedClosingBalance, 0) + ISNULL(NotGuaranteedBusinessBlocks.RoomsRemainsClosingBalance, 0) + ISNULL(GuaranteedBusinessBlocks.RoomsRemainsClosingBalance, 0) + ISNULL(GuaranteedBusinessBlocks.CounterClosingBalance, 0) - ISNULL(GuaranteedBusinessBlocks.CounterClosingBalance, 0) + ISNULL(NotGuaranteedBusinessBlocks.CounterClosingBalance, 0) - ISNULL(NotGuaranteedBusinessBlocks.CounterClosingBalance, 0) AS OccupiedRoomsWithBusinessBlocks,
	|		-ISNULL(RoomInventory.InHouseBedsClosingBalance, 0) - ISNULL(RoomInventory.BedsReservedClosingBalance, 0) + ISNULL(NotGuaranteedBusinessBlocks.BedsRemainsClosingBalance, 0) + ISNULL(GuaranteedBusinessBlocks.BedsRemainsClosingBalance, 0) + ISNULL(GuaranteedBusinessBlocks.CounterClosingBalance, 0) - ISNULL(GuaranteedBusinessBlocks.CounterClosingBalance, 0) + ISNULL(NotGuaranteedBusinessBlocks.CounterClosingBalance, 0) - ISNULL(NotGuaranteedBusinessBlocks.CounterClosingBalance, 0) AS OccupiedBedsWithBusinessBlocks,
	|		-ISNULL(RoomInventory.RoomsReservedClosingBalance, 0) + ISNULL(RoomInventory.GuaranteedRoomsReservedClosingBalance, 0) AS NonGuaranteedRoomsReserved,
	|		-ISNULL(RoomInventory.BedsReservedClosingBalance, 0) + ISNULL(RoomInventory.GuaranteedBedsReservedClosingBalance, 0) AS NonGuaranteedBedsReserved,
	|		-ISNULL(RoomInventory.GuestsReservedClosingBalance, 0) + ISNULL(RoomInventory.GuaranteedGuestsReservedClosingBalance, 0) AS NonGuaranteedGuestsReserved,
	|		-ISNULL(RoomInventory.GuaranteedRoomsReservedClosingBalance, 0) - ISNULL(RoomInventory.InHouseRoomsClosingBalance, 0) AS GuaranteedAndInHouseRooms,
	|		-ISNULL(RoomInventory.GuaranteedBedsReservedClosingBalance, 0) - ISNULL(RoomInventory.InHouseBedsClosingBalance, 0) AS GuaranteedAndInHouseBeds,
	|		-ISNULL(RoomInventory.GuaranteedGuestsReservedClosingBalance, 0) - ISNULL(RoomInventory.InHouseGuestsClosingBalance, 0) AS GuaranteedAndInHouseGuests,
	|		-ISNULL(RoomInventory.GuaranteedRoomsReservedClosingBalance, 0) - ISNULL(RoomInventory.InHouseRoomsClosingBalance, 0) + ISNULL(GuaranteedBusinessBlocks.RoomsRemainsClosingBalance, 0) + ISNULL(GuaranteedBusinessBlocks.CounterClosingBalance, 0) - ISNULL(GuaranteedBusinessBlocks.CounterClosingBalance, 0) AS GuaranteedAndInHouseRoomsWithDefiniteBusinessBlocks,
	|		-ISNULL(RoomInventory.GuaranteedBedsReservedClosingBalance, 0) - ISNULL(RoomInventory.InHouseBedsClosingBalance, 0) + ISNULL(GuaranteedBusinessBlocks.BedsRemainsClosingBalance, 0) + ISNULL(GuaranteedBusinessBlocks.CounterClosingBalance, 0) - ISNULL(GuaranteedBusinessBlocks.CounterClosingBalance, 0) AS GuaranteedAndInHouseBedsWithDefiniteBusinessBlocks,
	|		ISNULL(GuaranteedBusinessBlocks.RoomsRemainsClosingBalance, 0) + ISNULL(GuaranteedBusinessBlocks.CounterClosingBalance, 0) - ISNULL(GuaranteedBusinessBlocks.CounterClosingBalance, 0) AS RoomsInDefiniteBusinessBlocks,
	|		ISNULL(GuaranteedBusinessBlocks.BedsRemainsClosingBalance, 0) + ISNULL(GuaranteedBusinessBlocks.CounterClosingBalance, 0) - ISNULL(GuaranteedBusinessBlocks.CounterClosingBalance, 0) AS BedsInDefiniteBusinessBlocks,
	|		ISNULL(NotGuaranteedBusinessBlocks.RoomsRemainsClosingBalance, 0) + ISNULL(NotGuaranteedBusinessBlocks.CounterClosingBalance, 0) - ISNULL(NotGuaranteedBusinessBlocks.CounterClosingBalance, 0) AS RoomsInTentativeBusinessBlocks,
	|		ISNULL(NotGuaranteedBusinessBlocks.BedsRemainsClosingBalance, 0) + ISNULL(NotGuaranteedBusinessBlocks.CounterClosingBalance, 0) - ISNULL(NotGuaranteedBusinessBlocks.CounterClosingBalance, 0) AS BedsInTentativeBusinessBlocks,
	|		-ISNULL(RoomInventory.ExpectedRoomsCheckedInTurnover, 0) - ISNULL(RoomInventory.GuaranteedExpectedRoomsCheckedInTurnover, 0) + ISNULL(RoomInventory.GuaranteedExpectedRoomsCheckedInTurnover, 0) AS ExpectedRoomsCheckedIn,
	|		-ISNULL(RoomInventory.ExpectedBedsCheckedInTurnover, 0) - ISNULL(RoomInventory.GuaranteedExpectedBedsCheckedInTurnover, 0) + ISNULL(RoomInventory.GuaranteedExpectedBedsCheckedInTurnover, 0) AS ExpectedBedsCheckedIn,
	|		-ISNULL(RoomInventory.ExpectedGuestsCheckedInTurnover, 0) - ISNULL(RoomInventory.GuaranteedExpectedGuestsCheckedInTurnover, 0) + ISNULL(RoomInventory.GuaranteedExpectedGuestsCheckedInTurnover, 0) AS ExpectedGuestsCheckedIn,
	|		-ISNULL(RoomInventory.GuaranteedExpectedRoomsCheckedInTurnover, 0) - ISNULL(RoomInventory.ExpectedRoomsCheckedInTurnover, 0) + ISNULL(RoomInventory.ExpectedRoomsCheckedInTurnover, 0) AS GuaranteedExpectedRoomsCheckedIn,
	|		-ISNULL(RoomInventory.GuaranteedExpectedBedsCheckedInTurnover, 0) - ISNULL(RoomInventory.ExpectedBedsCheckedInTurnover, 0) + ISNULL(RoomInventory.ExpectedBedsCheckedInTurnover, 0) AS GuaranteedExpectedBedsCheckedIn,
	|		-ISNULL(RoomInventory.GuaranteedExpectedGuestsCheckedInTurnover, 0) - ISNULL(RoomInventory.ExpectedGuestsCheckedInTurnover, 0) + ISNULL(RoomInventory.ExpectedGuestsCheckedInTurnover, 0) AS GuaranteedExpectedGuestsCheckedIn,
	|		-ISNULL(RoomInventory.ExpectedRoomsCheckedInTurnover, 0) + ISNULL(RoomInventory.GuaranteedExpectedRoomsCheckedInTurnover, 0) AS NonGuaranteedExpectedRoomsCheckedIn,
	|		-ISNULL(RoomInventory.ExpectedBedsCheckedInTurnover, 0) + ISNULL(RoomInventory.GuaranteedExpectedBedsCheckedInTurnover, 0) AS NonGuaranteedExpectedBedsCheckedIn,
	|		-ISNULL(RoomInventory.ExpectedGuestsCheckedInTurnover, 0) + ISNULL(RoomInventory.GuaranteedExpectedGuestsCheckedInTurnover, 0) AS NonGuaranteedExpectedGuestsCheckedIn,
	|		-ISNULL(RoomInventory.RoomsCheckedInTurnover, 0) - ISNULL(RoomInventory.ExpectedRoomsCheckedInTurnover, 0) AS RoomsCheckedIn,
	|		-ISNULL(RoomInventory.BedsCheckedInTurnover, 0) - ISNULL(RoomInventory.ExpectedBedsCheckedInTurnover, 0) AS BedsCheckedIn,
	|		-ISNULL(RoomInventory.AdditionalBedsCheckedInTurnover, 0) - ISNULL(RoomInventory.ExpectedAdditionalBedsCheckedInTurnover, 0) AS AdditionalBedsCheckedIn,
	|		-ISNULL(RoomInventory.GuestsCheckedInTurnover, 0) - ISNULL(RoomInventory.ExpectedGuestsCheckedInTurnover, 0) AS GuestsCheckedIn,
	|		ISNULL(RoomInventory.RoomsCheckedOutTurnover, 0) + ISNULL(RoomInventory.ExpectedRoomsCheckedOutTurnover, 0) AS RoomsCheckedOut,
	|		ISNULL(RoomInventory.BedsCheckedOutTurnover, 0) + ISNULL(RoomInventory.ExpectedBedsCheckedOutTurnover, 0) AS BedsCheckedOut,
	|		ISNULL(RoomInventory.AdditionalBedsCheckedOutTurnover, 0) + ISNULL(RoomInventory.ExpectedAdditionalBedsCheckedOutTurnover, 0) AS AdditionalBedsCheckedOut,
	|		ISNULL(RoomInventory.GuestsCheckedOutTurnover, 0) + ISNULL(RoomInventory.ExpectedGuestsCheckedOutTurnover, 0) AS GuestsCheckedOut,
	|		ISNULL(RoomInventory.ExpectedRoomsCheckedOutTurnover, 0) - ISNULL(RoomInventory.ExpectedRoomsCheckedInTurnover, 0) + ISNULL(RoomInventory.ExpectedRoomsCheckedInTurnover, 0) AS ExpectedRoomsCheckedOut,
	|		ISNULL(RoomInventory.ExpectedBedsCheckedOutTurnover, 0) - ISNULL(RoomInventory.ExpectedBedsCheckedInTurnover, 0) + ISNULL(RoomInventory.ExpectedBedsCheckedInTurnover, 0) AS ExpectedBedsCheckedOut,
	|		ISNULL(RoomInventory.ExpectedGuestsCheckedOutTurnover, 0) - ISNULL(RoomInventory.ExpectedGuestsCheckedInTurnover, 0) + ISNULL(RoomInventory.ExpectedGuestsCheckedInTurnover, 0) AS ExpectedGuestsCheckedOut,
	|		ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) + ISNULL(RoomInventory.RoomsBlockedClosingBalance, 0) + ISNULL(RoomInventory.InHouseRoomsClosingBalance, 0) + ISNULL(RoomInventory.RoomsReservedClosingBalance, 0) - ISNULL(RoomQuotaSales.RoomsRemainsClosingBalance, 0) AS RoomsVacant,
	|		ISNULL(RoomInventory.TotalBedsClosingBalance, 0) + ISNULL(RoomInventory.BedsBlockedClosingBalance, 0) + ISNULL(RoomInventory.InHouseBedsClosingBalance, 0) + ISNULL(RoomInventory.BedsReservedClosingBalance, 0) - ISNULL(RoomQuotaSales.BedsRemainsClosingBalance, 0) AS BedsVacant,
	|		ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) + ISNULL(RoomInventory.RoomsBlockedClosingBalance, 0) + ISNULL(RoomInventory.InHouseRoomsClosingBalance, 0) + ISNULL(RoomInventory.RoomsReservedClosingBalance, 0) - CASE
	|			WHEN ISNULL(CommitmentAllotments.RoomsRemainsClosingBalance, 0) < 0
	|				THEN 0
	|			ELSE ISNULL(CommitmentAllotments.RoomsRemainsClosingBalance, 0)
	|		END AS RoomsVacantWithoutCommitment,
	|		ISNULL(RoomInventory.TotalBedsClosingBalance, 0) + ISNULL(RoomInventory.BedsBlockedClosingBalance, 0) + ISNULL(RoomInventory.InHouseBedsClosingBalance, 0) + ISNULL(RoomInventory.BedsReservedClosingBalance, 0) - CASE
	|			WHEN ISNULL(CommitmentAllotments.BedsRemainsClosingBalance, 0) < 0
	|				THEN 0
	|			ELSE ISNULL(CommitmentAllotments.BedsRemainsClosingBalance, 0)
	|		END AS BedsVacantWithoutCommitment,
	|		ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) + ISNULL(RoomInventory.RoomsBlockedClosingBalance, 0) + ISNULL(RoomInventory.InHouseRoomsClosingBalance, 0) + ISNULL(RoomInventory.RoomsReservedClosingBalance, 0) AS RoomsVacantWithAllotments,
	|		ISNULL(RoomInventory.TotalBedsClosingBalance, 0) + ISNULL(RoomInventory.BedsBlockedClosingBalance, 0) + ISNULL(RoomInventory.InHouseBedsClosingBalance, 0) + ISNULL(RoomInventory.BedsReservedClosingBalance, 0) AS BedsVacantWithAllotments,
	|		ISNULL(RoomQuotaSales.RoomsInQuotaClosingBalance, 0) - ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) + ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) AS RoomsInQuota,
	|		ISNULL(RoomQuotaSales.BedsInQuotaClosingBalance, 0) - ISNULL(RoomInventory.TotalBedsClosingBalance, 0) + ISNULL(RoomInventory.TotalBedsClosingBalance, 0) AS BedsInQuota,
	|		ISNULL(RoomQuotaSales.RoomsRemainsClosingBalance, 0) - ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) + ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) AS RoomsRemainsInQuota,
	|		ISNULL(RoomQuotaSales.BedsRemainsClosingBalance, 0) - ISNULL(RoomInventory.TotalBedsClosingBalance, 0) + ISNULL(RoomInventory.TotalBedsClosingBalance, 0) AS BedsRemainsInQuota,
	|		ISNULL(RoomQuotaSales.RoomsReservedClosingBalance, 0) - ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) + ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) AS RoomsReservedInQuota,
	|		ISNULL(RoomQuotaSales.BedsReservedClosingBalance, 0) - ISNULL(RoomInventory.TotalBedsClosingBalance, 0) + ISNULL(RoomInventory.TotalBedsClosingBalance, 0) AS BedsReservedInQuota,
	|		ISNULL(RoomQuotaSales.InHouseRoomsClosingBalance, 0) - ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) + ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) AS RoomsInHouseInQuota,
	|		ISNULL(RoomQuotaSales.InHouseBedsClosingBalance, 0) - ISNULL(RoomInventory.TotalBedsClosingBalance, 0) + ISNULL(RoomInventory.TotalBedsClosingBalance, 0) AS BedsInHouseInQuota,
	|		ISNULL(RoomQuotaSales.RoomsReservedClosingBalance, 0) + ISNULL(RoomQuotaSales.InHouseRoomsClosingBalance, 0) AS RoomsOccupiedInQuota,
	|		ISNULL(RoomQuotaSales.BedsReservedClosingBalance, 0) + ISNULL(RoomQuotaSales.InHouseBedsClosingBalance, 0) AS BedsOccupiedInQuota,
	|		ISNULL(NotCommitmentAllotments.RoomsInQuotaClosingBalance, 0) - ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) + ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) AS NotCommitmentRoomsInQuota,
	|		ISNULL(NotCommitmentAllotments.BedsInQuotaClosingBalance, 0) - ISNULL(RoomInventory.TotalBedsClosingBalance, 0) + ISNULL(RoomInventory.TotalBedsClosingBalance, 0) AS NotCommitmentBedsInQuota,
	|		ISNULL(NotCommitmentAllotments.RoomsReservedClosingBalance, 0) - ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) + ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) AS NotCommitmentRoomsReserved,
	|		ISNULL(NotCommitmentAllotments.BedsReservedClosingBalance, 0) - ISNULL(RoomInventory.TotalBedsClosingBalance, 0) + ISNULL(RoomInventory.TotalBedsClosingBalance, 0) AS NotCommitmentBedsReserved,
	|		ISNULL(NotCommitmentAllotments.InHouseRoomsClosingBalance, 0) - ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) + ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) AS NotCommitmentRoomsInHouse,
	|		ISNULL(NotCommitmentAllotments.InHouseBedsClosingBalance, 0) - ISNULL(RoomInventory.TotalBedsClosingBalance, 0) + ISNULL(RoomInventory.TotalBedsClosingBalance, 0) AS NotCommitmentBedsInHouse,
	|		ISNULL(NotCommitmentAllotments.RoomsReservedClosingBalance, 0) + ISNULL(NotCommitmentAllotments.InHouseRoomsClosingBalance, 0) AS NotCommitmentRoomsOccupied,
	|		ISNULL(NotCommitmentAllotments.BedsReservedClosingBalance, 0) + ISNULL(NotCommitmentAllotments.InHouseBedsClosingBalance, 0) AS NotCommitmentBedsOccupied,
	|		ISNULL(NotCommitmentAllotments.RoomsRemainsClosingBalance, 0) - ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) + ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) AS NotCommitmentRoomsRemains,
	|		ISNULL(NotCommitmentAllotments.BedsRemainsClosingBalance, 0) - ISNULL(RoomInventory.TotalBedsClosingBalance, 0) + ISNULL(RoomInventory.TotalBedsClosingBalance, 0) AS NotCommitmentBedsRemains,
	|		ISNULL(CommitmentAllotments.RoomsInQuotaClosingBalance, 0) - ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) + ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) AS CommitmentRoomsInQuota,
	|		ISNULL(CommitmentAllotments.BedsInQuotaClosingBalance, 0) - ISNULL(RoomInventory.TotalBedsClosingBalance, 0) + ISNULL(RoomInventory.TotalBedsClosingBalance, 0) AS CommitmentBedsInQuota,
	|		ISNULL(CommitmentAllotments.RoomsInQuotaOpeningBalance, 0) - ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) + ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) AS CommitmentRoomsInQuotaAtMorning,
	|		ISNULL(CommitmentAllotments.BedsInQuotaOpeningBalance, 0) - ISNULL(RoomInventory.TotalBedsClosingBalance, 0) + ISNULL(RoomInventory.TotalBedsClosingBalance, 0) AS CommitmentBedsInQuotaAtMorning,
	|		ISNULL(CommitmentAllotments.RoomsReservedClosingBalance, 0) - ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) + ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) AS CommitmentRoomsReserved,
	|		ISNULL(CommitmentAllotments.BedsReservedClosingBalance, 0) - ISNULL(RoomInventory.TotalBedsClosingBalance, 0) + ISNULL(RoomInventory.TotalBedsClosingBalance, 0) AS CommitmentBedsReserved,
	|		ISNULL(CommitmentAllotments.InHouseRoomsClosingBalance, 0) - ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) + ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) AS CommitmentRoomsInHouse,
	|		ISNULL(CommitmentAllotments.InHouseBedsClosingBalance, 0) - ISNULL(RoomInventory.TotalBedsClosingBalance, 0) + ISNULL(RoomInventory.TotalBedsClosingBalance, 0) AS CommitmentBedsInHouse,
	|		ISNULL(CommitmentAllotments.RoomsReservedOpeningBalance, 0) - ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) + ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) AS CommitmentRoomsReservedAtMorning,
	|		ISNULL(CommitmentAllotments.BedsReservedOpeningBalance, 0) - ISNULL(RoomInventory.TotalBedsClosingBalance, 0) + ISNULL(RoomInventory.TotalBedsClosingBalance, 0) AS CommitmentBedsReservedAtMorning,
	|		ISNULL(CommitmentAllotments.InHouseRoomsOpeningBalance, 0) - ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) + ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) AS CommitmentRoomsInHouseAtMorning,
	|		ISNULL(CommitmentAllotments.InHouseBedsOpeningBalance, 0) - ISNULL(RoomInventory.TotalBedsClosingBalance, 0) + ISNULL(RoomInventory.TotalBedsClosingBalance, 0) AS CommitmentBedsInHouseAtMorning,
	|		ISNULL(CommitmentAllotments.RoomsReservedClosingBalance, 0) + ISNULL(CommitmentAllotments.InHouseRoomsClosingBalance, 0) AS CommitmentRoomsOccupied,
	|		ISNULL(CommitmentAllotments.BedsReservedClosingBalance, 0) + ISNULL(CommitmentAllotments.InHouseBedsClosingBalance, 0) AS CommitmentBedsOccupied,
	|		ISNULL(CommitmentAllotments.RoomsReservedOpeningBalance, 0) + ISNULL(CommitmentAllotments.InHouseRoomsOpeningBalance, 0) AS CommitmentRoomsOccupiedAtMorning,
	|		ISNULL(CommitmentAllotments.BedsReservedOpeningBalance, 0) + ISNULL(CommitmentAllotments.InHouseBedsOpeningBalance, 0) AS CommitmentBedsOccupiedAtMorning,
	|		ISNULL(CommitmentAllotments.RoomsRemainsClosingBalance, 0) - ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) + ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) AS CommitmentRoomsRemains,
	|		ISNULL(CommitmentAllotments.BedsRemainsClosingBalance, 0) - ISNULL(RoomInventory.TotalBedsClosingBalance, 0) + ISNULL(RoomInventory.TotalBedsClosingBalance, 0) AS CommitmentBedsRemains,
	|		ISNULL(CommitmentAllotments.RoomsRemainsOpeningBalance, 0) - ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) + ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) AS CommitmentRoomsRemainsAtMorning,
	|		ISNULL(CommitmentAllotments.BedsRemainsOpeningBalance, 0) - ISNULL(RoomInventory.TotalBedsClosingBalance, 0) + ISNULL(RoomInventory.TotalBedsClosingBalance, 0) AS CommitmentBedsRemainsAtMorning,
	|		CASE
	|			WHEN ISNULL(CommitmentAllotments.RoomsInQuotaClosingBalance, 0) = 0
	|				THEN 0
	|			ELSE (ISNULL(CommitmentAllotments.RoomsReservedClosingBalance, 0) + ISNULL(CommitmentAllotments.InHouseRoomsClosingBalance, 0)) * 100 / ISNULL(CommitmentAllotments.RoomsInQuotaClosingBalance, 0)
	|		END AS CommitmentRoomsUsagePercent,
	|		CASE
	|			WHEN ISNULL(CommitmentAllotments.BedsInQuotaClosingBalance, 0) = 0
	|				THEN 0
	|			ELSE (ISNULL(CommitmentAllotments.BedsReservedClosingBalance, 0) + ISNULL(CommitmentAllotments.InHouseBedsClosingBalance, 0)) * 100 / ISNULL(CommitmentAllotments.BedsInQuotaClosingBalance, 0)
	|		END AS CommitmentBedsUsagePercent,
	|		CASE
	|			WHEN ISNULL(CommitmentAllotments.RoomsInQuotaClosingBalance, 0) = 0
	|				THEN 0
	|			ELSE 100 - (ISNULL(CommitmentAllotments.RoomsReservedClosingBalance, 0) + ISNULL(CommitmentAllotments.InHouseRoomsClosingBalance, 0)) * 100 / ISNULL(CommitmentAllotments.RoomsInQuotaClosingBalance, 0)
	|		END AS CommitmentRoomsRemainsPercent,
	|		CASE
	|			WHEN ISNULL(CommitmentAllotments.BedsInQuotaClosingBalance, 0) = 0
	|				THEN 0
	|			ELSE 100 - (ISNULL(CommitmentAllotments.BedsReservedClosingBalance, 0) + ISNULL(CommitmentAllotments.InHouseBedsClosingBalance, 0)) * 100 / ISNULL(CommitmentAllotments.BedsInQuotaClosingBalance, 0)
	|		END AS CommitmentBedsRemainsPercent,
	|		-ISNULL(RoomInventory.InHouseRoomsClosingBalance, 0) - ISNULL(RoomInventory.RoomsReservedClosingBalance, 0) + CASE
	|			WHEN ISNULL(CommitmentAllotments.RoomsRemainsClosingBalance, 0) < 0
	|				THEN 0
	|			ELSE ISNULL(CommitmentAllotments.RoomsRemainsClosingBalance, 0)
	|		END AS RoomsSold,
	|		-ISNULL(RoomInventory.InHouseBedsClosingBalance, 0) - ISNULL(RoomInventory.BedsReservedClosingBalance, 0) + CASE
	|			WHEN ISNULL(CommitmentAllotments.BedsRemainsClosingBalance, 0) < 0
	|				THEN 0
	|			ELSE ISNULL(CommitmentAllotments.BedsRemainsClosingBalance, 0)
	|		END AS BedsSold,
	|		-ISNULL(RoomInventory.InHouseGuestsClosingBalance, 0) - ISNULL(RoomInventory.GuestsReservedClosingBalance, 0) AS TotalGuests,
	|		-ISNULL(RoomInventory.InHouseRoomsOpeningBalance, 0) - ISNULL(RoomInventory.RoomsReservedOpeningBalance, 0) AS OccupiedRoomsAtMorning,
	|		-ISNULL(RoomInventory.InHouseBedsOpeningBalance, 0) - ISNULL(RoomInventory.BedsReservedOpeningBalance, 0) AS OccupiedBedsAtMorning,
	|		-ISNULL(RoomInventory.InHouseRoomsOpeningBalance, 0) - ISNULL(RoomInventory.RoomsReservedOpeningBalance, 0) + CASE
	|			WHEN ISNULL(CommitmentAllotments.RoomsRemainsOpeningBalance, 0) < 0
	|				THEN 0
	|			ELSE ISNULL(CommitmentAllotments.RoomsRemainsOpeningBalance, 0)
	|		END AS RoomsSoldAtMorning,
	|		-ISNULL(RoomInventory.InHouseBedsOpeningBalance, 0) - ISNULL(RoomInventory.BedsReservedOpeningBalance, 0) + CASE
	|			WHEN ISNULL(CommitmentAllotments.BedsRemainsOpeningBalance, 0) < 0
	|				THEN 0
	|			ELSE ISNULL(CommitmentAllotments.BedsRemainsOpeningBalance, 0)
	|		END AS BedsSoldAtMorning,
	|		-ISNULL(RoomInventory.InHouseGuestsOpeningBalance, 0) - ISNULL(RoomInventory.GuestsReservedOpeningBalance, 0) AS TotalGuestsAtMorning,
	|		CASE
	|			WHEN ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) + ISNULL(RoomInventory.RoomsBlockedClosingBalance, 0) = 0
	|				THEN 0
	|			ELSE ISNULL(RoomSalesTurnovers.GuaranteedRoomsRented, 0) * 100 / (ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) + ISNULL(RoomInventory.RoomsBlockedClosingBalance, 0))
	|		END AS GuaranteedRoomsRentedPercent,
	|		CASE
	|			WHEN ISNULL(RoomInventory.TotalBedsClosingBalance, 0) + ISNULL(RoomInventory.BedsBlockedClosingBalance, 0) = 0
	|				THEN 0
	|			ELSE ISNULL(RoomSalesTurnovers.GuaranteedBedsRented, 0) * 100 / (ISNULL(RoomInventory.TotalBedsClosingBalance, 0) + ISNULL(RoomInventory.BedsBlockedClosingBalance, 0))
	|		END AS GuaranteedBedsRentedPercent,
	|		CASE
	|			WHEN ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) + ISNULL(RoomInventory.RoomsBlockedClosingBalance, 0) = 0
	|				THEN 0
	|			ELSE ISNULL(RoomSalesTurnovers.NonGuaranteedRoomsRented, 0) * 100 / (ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) + ISNULL(RoomInventory.RoomsBlockedClosingBalance, 0))
	|		END AS NonGuaranteedRoomsRentedPercent,
	|		CASE
	|			WHEN ISNULL(RoomInventory.TotalBedsClosingBalance, 0) + ISNULL(RoomInventory.BedsBlockedClosingBalance, 0) = 0
	|				THEN 0
	|			ELSE ISNULL(RoomSalesTurnovers.NonGuaranteedBedsRented, 0) * 100 / (ISNULL(RoomInventory.TotalBedsClosingBalance, 0) + ISNULL(RoomInventory.BedsBlockedClosingBalance, 0))
	|		END AS NonGuaranteedBedsRentedPercent,
	|		CASE
	|			WHEN ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) + ISNULL(RoomInventory.RoomsBlockedClosingBalance, 0) = 0
	|				THEN 0
	|			ELSE ISNULL(RoomSalesTurnovers.RoomsRented, 0) * 100 / (ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) + ISNULL(RoomInventory.RoomsBlockedClosingBalance, 0))
	|		END AS RoomsRentedPercent,
	|		CASE
	|			WHEN ISNULL(RoomInventory.TotalBedsClosingBalance, 0) + ISNULL(RoomInventory.BedsBlockedClosingBalance, 0) = 0
	|				THEN 0
	|			ELSE ISNULL(RoomSalesTurnovers.BedsRented, 0) * 100 / (ISNULL(RoomInventory.TotalBedsClosingBalance, 0) + ISNULL(RoomInventory.BedsBlockedClosingBalance, 0))
	|		END AS BedsRentedPercent,
	|		CASE
	|			WHEN ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) = 0
	|				THEN 0
	|			ELSE ISNULL(RoomSalesTurnovers.RoomsRented, 0) * 100 / ISNULL(RoomInventory.TotalRoomsClosingBalance, 0)
	|		END AS RoomsRentedPercentWithoutBlocks,
	|		CASE
	|			WHEN ISNULL(RoomInventory.TotalBedsClosingBalance, 0) = 0
	|				THEN 0
	|			ELSE ISNULL(RoomSalesTurnovers.BedsRented, 0) * 100 / ISNULL(RoomInventory.TotalBedsClosingBalance, 0)
	|		END AS BedsRentedPercentWithoutBlocks,
	|		CASE
	|			WHEN ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) + ISNULL(RoomInventory.RoomsBlockedClosingBalance, 0) = 0
	|				THEN 0
	|			ELSE (-ISNULL(RoomInventory.InHouseRoomsClosingBalance, 0) - ISNULL(RoomInventory.RoomsReservedClosingBalance, 0) + CASE
	|					WHEN ISNULL(CommitmentAllotments.RoomsRemainsClosingBalance, 0) < 0
	|						THEN 0
	|					ELSE ISNULL(CommitmentAllotments.RoomsRemainsClosingBalance, 0)
	|				END + CASE
	|					WHEN ISNULL(GuaranteedBusinessBlocks.RoomsRemainsClosingBalance, 0) < 0
	|						THEN 0
	|					ELSE ISNULL(GuaranteedBusinessBlocks.RoomsRemainsClosingBalance, 0)
	|				END + CASE
	|					WHEN ISNULL(NotGuaranteedBusinessBlocks.RoomsRemainsClosingBalance, 0) < 0
	|						THEN 0
	|					ELSE ISNULL(NotGuaranteedBusinessBlocks.RoomsRemainsClosingBalance, 0)
	|				END + ISNULL(GuaranteedBusinessBlocks.CounterClosingBalance, 0) - ISNULL(GuaranteedBusinessBlocks.CounterClosingBalance, 0) + ISNULL(NotGuaranteedBusinessBlocks.CounterClosingBalance, 0) - ISNULL(NotGuaranteedBusinessBlocks.CounterClosingBalance, 0)) * 100 / (ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) + ISNULL(RoomInventory.RoomsBlockedClosingBalance, 0))
	|		END AS RoomsOccupancyPercent,
	|		CASE
	|			WHEN ISNULL(RoomInventory.TotalBedsClosingBalance, 0) + ISNULL(RoomInventory.BedsBlockedClosingBalance, 0) = 0
	|				THEN 0
	|			ELSE (-ISNULL(RoomInventory.InHouseBedsClosingBalance, 0) - ISNULL(RoomInventory.BedsReservedClosingBalance, 0) + CASE
	|					WHEN ISNULL(CommitmentAllotments.BedsRemainsClosingBalance, 0) < 0
	|						THEN 0
	|					ELSE ISNULL(CommitmentAllotments.BedsRemainsClosingBalance, 0)
	|				END + CASE
	|					WHEN ISNULL(GuaranteedBusinessBlocks.BedsRemainsClosingBalance, 0) < 0
	|						THEN 0
	|					ELSE ISNULL(GuaranteedBusinessBlocks.BedsRemainsClosingBalance, 0)
	|				END + CASE
	|					WHEN ISNULL(NotGuaranteedBusinessBlocks.BedsRemainsClosingBalance, 0) < 0
	|						THEN 0
	|					ELSE ISNULL(NotGuaranteedBusinessBlocks.BedsRemainsClosingBalance, 0)
	|				END + ISNULL(GuaranteedBusinessBlocks.CounterClosingBalance, 0) - ISNULL(GuaranteedBusinessBlocks.CounterClosingBalance, 0) + ISNULL(NotGuaranteedBusinessBlocks.CounterClosingBalance, 0) - ISNULL(NotGuaranteedBusinessBlocks.CounterClosingBalance, 0)) * 100 / (ISNULL(RoomInventory.TotalBedsClosingBalance, 0) + ISNULL(RoomInventory.BedsBlockedClosingBalance, 0))
	|		END AS BedsOccupancyPercent,
	|		CASE
	|			WHEN ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) + ISNULL(RoomInventory.RoomsBlockedClosingBalance, 0) = 0
	|				THEN 0
	|			ELSE (-ISNULL(RoomInventory.InHouseRoomsClosingBalance, 0) - ISNULL(RoomInventory.GuaranteedRoomsReservedClosingBalance, 0) + CASE
	|					WHEN ISNULL(CommitmentAllotments.RoomsRemainsClosingBalance, 0) < 0
	|						THEN 0
	|					ELSE ISNULL(CommitmentAllotments.RoomsRemainsClosingBalance, 0)
	|				END + CASE
	|					WHEN ISNULL(GuaranteedBusinessBlocks.RoomsRemainsClosingBalance, 0) < 0
	|						THEN 0
	|					ELSE ISNULL(GuaranteedBusinessBlocks.RoomsRemainsClosingBalance, 0)
	|				END + ISNULL(GuaranteedBusinessBlocks.CounterClosingBalance, 0) - ISNULL(GuaranteedBusinessBlocks.CounterClosingBalance, 0)) * 100 / (ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) + ISNULL(RoomInventory.RoomsBlockedClosingBalance, 0))
	|		END AS GuaranteedRoomsOccupancyPercent,
	|		CASE
	|			WHEN ISNULL(RoomInventory.TotalBedsClosingBalance, 0) + ISNULL(RoomInventory.BedsBlockedClosingBalance, 0) = 0
	|				THEN 0
	|			ELSE (-ISNULL(RoomInventory.InHouseBedsClosingBalance, 0) - ISNULL(RoomInventory.GuaranteedBedsReservedClosingBalance, 0) + CASE
	|					WHEN ISNULL(CommitmentAllotments.BedsRemainsClosingBalance, 0) < 0
	|						THEN 0
	|					ELSE ISNULL(CommitmentAllotments.BedsRemainsClosingBalance, 0)
	|				END + CASE
	|					WHEN ISNULL(GuaranteedBusinessBlocks.BedsRemainsClosingBalance, 0) < 0
	|						THEN 0
	|					ELSE ISNULL(GuaranteedBusinessBlocks.BedsRemainsClosingBalance, 0)
	|				END + ISNULL(GuaranteedBusinessBlocks.CounterClosingBalance, 0) - ISNULL(GuaranteedBusinessBlocks.CounterClosingBalance, 0)) * 100 / (ISNULL(RoomInventory.TotalBedsClosingBalance, 0) + ISNULL(RoomInventory.BedsBlockedClosingBalance, 0))
	|		END AS GuaranteedBedsOccupancyPercent,
	|		CASE
	|			WHEN ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) + ISNULL(RoomInventory.RoomsBlockedClosingBalance, 0) = 0
	|				THEN 0
	|			ELSE (-ISNULL(RoomInventory.RoomsReservedClosingBalance, 0) + ISNULL(RoomInventory.GuaranteedRoomsReservedClosingBalance, 0) + ISNULL(NotGuaranteedBusinessBlocks.RoomsRemainsClosingBalance, 0) + ISNULL(NotGuaranteedBusinessBlocks.CounterClosingBalance, 0) - ISNULL(NotGuaranteedBusinessBlocks.CounterClosingBalance, 0)) * 100 / (ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) + ISNULL(RoomInventory.RoomsBlockedClosingBalance, 0))
	|		END AS NonGuaranteedRoomsOccupancyPercent,
	|		CASE
	|			WHEN ISNULL(RoomInventory.TotalBedsClosingBalance, 0) + ISNULL(RoomInventory.BedsBlockedClosingBalance, 0) = 0
	|				THEN 0
	|			ELSE (-ISNULL(RoomInventory.BedsReservedClosingBalance, 0) + ISNULL(RoomInventory.GuaranteedBedsReservedClosingBalance, 0) + ISNULL(NotGuaranteedBusinessBlocks.BedsRemainsClosingBalance, 0) + ISNULL(NotGuaranteedBusinessBlocks.CounterClosingBalance, 0) - ISNULL(NotGuaranteedBusinessBlocks.CounterClosingBalance, 0)) * 100 / (ISNULL(RoomInventory.TotalBedsClosingBalance, 0) + ISNULL(RoomInventory.BedsBlockedClosingBalance, 0))
	|		END AS NonGuaranteedBedsOccupancyPercent,
	|		CASE
	|			WHEN ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) = 0
	|				THEN 0
	|			ELSE (-ISNULL(RoomInventory.InHouseRoomsClosingBalance, 0) - ISNULL(RoomInventory.RoomsReservedClosingBalance, 0) + CASE
	|					WHEN ISNULL(CommitmentAllotments.RoomsRemainsClosingBalance, 0) < 0
	|						THEN 0
	|					ELSE ISNULL(CommitmentAllotments.RoomsRemainsClosingBalance, 0)
	|				END + CASE
	|					WHEN ISNULL(GuaranteedBusinessBlocks.RoomsRemainsClosingBalance, 0) < 0
	|						THEN 0
	|					ELSE ISNULL(GuaranteedBusinessBlocks.RoomsRemainsClosingBalance, 0)
	|				END + CASE
	|					WHEN ISNULL(NotGuaranteedBusinessBlocks.RoomsRemainsClosingBalance, 0) < 0
	|						THEN 0
	|					ELSE ISNULL(NotGuaranteedBusinessBlocks.RoomsRemainsClosingBalance, 0)
	|				END + ISNULL(GuaranteedBusinessBlocks.CounterClosingBalance, 0) - ISNULL(GuaranteedBusinessBlocks.CounterClosingBalance, 0) + ISNULL(NotGuaranteedBusinessBlocks.CounterClosingBalance, 0) - ISNULL(NotGuaranteedBusinessBlocks.CounterClosingBalance, 0)) * 100 / ISNULL(RoomInventory.TotalRoomsClosingBalance, 0)
	|		END AS RoomsUsedPercent,
	|		CASE
	|			WHEN ISNULL(RoomInventory.TotalBedsClosingBalance, 0) = 0
	|				THEN 0
	|			ELSE (-ISNULL(RoomInventory.InHouseBedsClosingBalance, 0) - ISNULL(RoomInventory.BedsReservedClosingBalance, 0) + CASE
	|					WHEN ISNULL(CommitmentAllotments.BedsRemainsClosingBalance, 0) < 0
	|						THEN 0
	|					ELSE ISNULL(CommitmentAllotments.BedsRemainsClosingBalance, 0)
	|				END + CASE
	|					WHEN ISNULL(GuaranteedBusinessBlocks.BedsRemainsClosingBalance, 0) < 0
	|						THEN 0
	|					ELSE ISNULL(GuaranteedBusinessBlocks.BedsRemainsClosingBalance, 0)
	|				END + CASE
	|					WHEN ISNULL(NotGuaranteedBusinessBlocks.BedsRemainsClosingBalance, 0) < 0
	|						THEN 0
	|					ELSE ISNULL(NotGuaranteedBusinessBlocks.BedsRemainsClosingBalance, 0)
	|				END + ISNULL(GuaranteedBusinessBlocks.CounterClosingBalance, 0) - ISNULL(GuaranteedBusinessBlocks.CounterClosingBalance, 0) + ISNULL(NotGuaranteedBusinessBlocks.CounterClosingBalance, 0) - ISNULL(NotGuaranteedBusinessBlocks.CounterClosingBalance, 0)) * 100 / ISNULL(RoomInventory.TotalBedsClosingBalance, 0)
	|		END AS BedsUsedPercent,
	|		CASE
	|			WHEN ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) = 0
	|				THEN 0
	|			ELSE (-ISNULL(RoomInventory.InHouseRoomsClosingBalance, 0) - ISNULL(RoomInventory.GuaranteedRoomsReservedClosingBalance, 0) + CASE
	|					WHEN ISNULL(CommitmentAllotments.RoomsRemainsClosingBalance, 0) < 0
	|						THEN 0
	|					ELSE ISNULL(CommitmentAllotments.RoomsRemainsClosingBalance, 0)
	|				END + CASE
	|					WHEN ISNULL(GuaranteedBusinessBlocks.RoomsRemainsClosingBalance, 0) < 0
	|						THEN 0
	|					ELSE ISNULL(GuaranteedBusinessBlocks.RoomsRemainsClosingBalance, 0)
	|				END + ISNULL(GuaranteedBusinessBlocks.CounterClosingBalance, 0) - ISNULL(GuaranteedBusinessBlocks.CounterClosingBalance, 0)) * 100 / ISNULL(RoomInventory.TotalRoomsClosingBalance, 0)
	|		END AS GuaranteedRoomsUsedPercent,
	|		CASE
	|			WHEN ISNULL(RoomInventory.TotalBedsClosingBalance, 0) = 0
	|				THEN 0
	|			ELSE (-ISNULL(RoomInventory.InHouseBedsClosingBalance, 0) - ISNULL(RoomInventory.GuaranteedBedsReservedClosingBalance, 0) + CASE
	|					WHEN ISNULL(CommitmentAllotments.BedsRemainsClosingBalance, 0) < 0
	|						THEN 0
	|					ELSE ISNULL(CommitmentAllotments.BedsRemainsClosingBalance, 0)
	|				END + CASE
	|					WHEN ISNULL(GuaranteedBusinessBlocks.BedsRemainsClosingBalance, 0) < 0
	|						THEN 0
	|					ELSE ISNULL(GuaranteedBusinessBlocks.BedsRemainsClosingBalance, 0)
	|				END + ISNULL(GuaranteedBusinessBlocks.CounterClosingBalance, 0) - ISNULL(GuaranteedBusinessBlocks.CounterClosingBalance, 0)) * 100 / ISNULL(RoomInventory.TotalBedsClosingBalance, 0)
	|		END AS GuaranteedBedsUsedPercent,
	|		CASE
	|			WHEN ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) = 0
	|				THEN 0
	|			ELSE (-ISNULL(RoomInventory.RoomsReservedClosingBalance, 0) + ISNULL(RoomInventory.GuaranteedRoomsReservedClosingBalance, 0) + ISNULL(NotGuaranteedBusinessBlocks.RoomsRemainsClosingBalance, 0) + ISNULL(NotGuaranteedBusinessBlocks.CounterClosingBalance, 0) - ISNULL(NotGuaranteedBusinessBlocks.CounterClosingBalance, 0)) * 100 / ISNULL(RoomInventory.TotalRoomsClosingBalance, 0)
	|		END AS NonGuaranteedRoomsUsedPercent,
	|		CASE
	|			WHEN ISNULL(RoomInventory.TotalBedsClosingBalance, 0) = 0
	|				THEN 0
	|			ELSE (-ISNULL(RoomInventory.BedsReservedClosingBalance, 0) + ISNULL(RoomInventory.GuaranteedBedsReservedClosingBalance, 0) + ISNULL(NotGuaranteedBusinessBlocks.BedsRemainsClosingBalance, 0) + ISNULL(NotGuaranteedBusinessBlocks.CounterClosingBalance, 0) - ISNULL(NotGuaranteedBusinessBlocks.CounterClosingBalance, 0)) * 100 / ISNULL(RoomInventory.TotalBedsClosingBalance, 0)
	|		END AS NonGuaranteedBedsUsedPercent,
	|		CASE
	|			WHEN ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) + ISNULL(RoomInventory.RoomsBlockedClosingBalance, 0) = 0
	|				THEN 0
	|			ELSE ISNULL(RoomSalesTurnovers.RoomRevenue, 0) / (ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) + ISNULL(RoomInventory.RoomsBlockedClosingBalance, 0))
	|		END AS RevPAR,
	|		CASE
	|			WHEN ISNULL(RoomInventory.TotalBedsClosingBalance, 0) + ISNULL(RoomInventory.BedsBlockedClosingBalance, 0) = 0
	|				THEN 0
	|			ELSE ISNULL(RoomSalesTurnovers.RoomRevenue, 0) / (ISNULL(RoomInventory.TotalBedsClosingBalance, 0) + ISNULL(RoomInventory.BedsBlockedClosingBalance, 0))
	|		END AS RevPAB,
	|		CASE
	|			WHEN ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) + ISNULL(RoomInventory.RoomsBlockedClosingBalance, 0) = 0
	|				THEN 0
	|			ELSE ISNULL(RoomSalesTurnovers.RoomRevenueWithoutVAT, 0) / (ISNULL(RoomInventory.TotalRoomsClosingBalance, 0) + ISNULL(RoomInventory.RoomsBlockedClosingBalance, 0))
	|		END AS RevPARWithoutVAT,
	|		CASE
	|			WHEN ISNULL(RoomInventory.TotalBedsClosingBalance, 0) + ISNULL(RoomInventory.BedsBlockedClosingBalance, 0) = 0
	|				THEN 0
	|			ELSE ISNULL(RoomSalesTurnovers.RoomRevenueWithoutVAT, 0) / (ISNULL(RoomInventory.TotalBedsClosingBalance, 0) + ISNULL(RoomInventory.BedsBlockedClosingBalance, 0))
	|		END AS RevPABWithoutVAT,
	|		CASE
	|			WHEN ISNULL(RoomSalesTurnovers.RoomsRented, 0) = 0
	|				THEN 0
	|			ELSE ISNULL(RoomSalesTurnovers.RoomRevenue, 0) / ISNULL(RoomSalesTurnovers.RoomsRented, 0)
	|		END AS AvgRoomPrice,
	|		CASE
	|			WHEN ISNULL(RoomSalesTurnovers.BedsRented, 0) = 0
	|				THEN 0
	|			ELSE ISNULL(RoomSalesTurnovers.RoomRevenue, 0) / ISNULL(RoomSalesTurnovers.BedsRented, 0)
	|		END AS AvgBedPrice,
	|		CASE
	|			WHEN ISNULL(RoomSalesTurnovers.RoomsRented, 0) = 0
	|				THEN 0
	|			ELSE ISNULL(RoomSalesTurnovers.RoomRevenueWithoutVAT, 0) / ISNULL(RoomSalesTurnovers.RoomsRented, 0)
	|		END AS AvgRoomPriceWithoutVAT,
	|		CASE
	|			WHEN ISNULL(RoomSalesTurnovers.BedsRented, 0) = 0
	|				THEN 0
	|			ELSE ISNULL(RoomSalesTurnovers.RoomRevenueWithoutVAT, 0) / ISNULL(RoomSalesTurnovers.BedsRented, 0)
	|		END AS AvgBedPriceWithoutVAT,
	|		CASE
	|			WHEN ISNULL(RoomSalesTurnovers.GuaranteedRoomsRented, 0) = 0
	|				THEN 0
	|			ELSE ISNULL(RoomSalesTurnovers.GuaranteedRoomRevenue, 0) / ISNULL(RoomSalesTurnovers.GuaranteedRoomsRented, 0)
	|		END AS GuaranteedAvgRoomPrice,
	|		CASE
	|			WHEN ISNULL(RoomSalesTurnovers.GuaranteedBedsRented, 0) = 0
	|				THEN 0
	|			ELSE ISNULL(RoomSalesTurnovers.GuaranteedRoomRevenue, 0) / ISNULL(RoomSalesTurnovers.GuaranteedBedsRented, 0)
	|		END AS GuaranteedAvgBedPrice,
	|		CASE
	|			WHEN ISNULL(RoomSalesTurnovers.NonGuaranteedRoomsRented, 0) = 0
	|				THEN 0
	|			ELSE ISNULL(RoomSalesTurnovers.NonGuaranteedRoomRevenue, 0) / ISNULL(RoomSalesTurnovers.NonGuaranteedRoomsRented, 0)
	|		END AS NonGuaranteedAvgRoomPrice,
	|		CASE
	|			WHEN ISNULL(RoomSalesTurnovers.NonGuaranteedBedsRented, 0) = 0
	|				THEN 0
	|			ELSE ISNULL(RoomSalesTurnovers.NonGuaranteedRoomRevenue, 0) / ISNULL(RoomSalesTurnovers.NonGuaranteedBedsRented, 0)
	|		END AS NonGuaranteedAvgBedPrice,
	|		CASE
	|			WHEN ISNULL(RoomSalesTurnovers.GuaranteedRoomsRented, 0) = 0
	|				THEN 0
	|			ELSE ISNULL(RoomSalesTurnovers.GuaranteedRoomRevenueWithoutVAT, 0) / ISNULL(RoomSalesTurnovers.GuaranteedRoomsRented, 0)
	|		END AS GuaranteedAvgRoomPriceWithoutVAT,
	|		CASE
	|			WHEN ISNULL(RoomSalesTurnovers.GuaranteedBedsRented, 0) = 0
	|				THEN 0
	|			ELSE ISNULL(RoomSalesTurnovers.GuaranteedRoomRevenueWithoutVAT, 0) / ISNULL(RoomSalesTurnovers.GuaranteedBedsRented, 0)
	|		END AS GuaranteedAvgBedPriceWithoutVAT,
	|		CASE
	|			WHEN ISNULL(RoomSalesTurnovers.NonGuaranteedRoomsRented, 0) = 0
	|				THEN 0
	|			ELSE ISNULL(RoomSalesTurnovers.NonGuaranteedRoomRevenueWithoutVAT, 0) / ISNULL(RoomSalesTurnovers.NonGuaranteedRoomsRented, 0)
	|		END AS NonGuaranteedAvgRoomPriceWithoutVAT,
	|		CASE
	|			WHEN ISNULL(RoomSalesTurnovers.NonGuaranteedBedsRented, 0) = 0
	|				THEN 0
	|			ELSE ISNULL(RoomSalesTurnovers.NonGuaranteedRoomRevenueWithoutVAT, 0) / ISNULL(RoomSalesTurnovers.NonGuaranteedBedsRented, 0)
	|		END AS NonGuaranteedAvgBedPriceWithoutVAT,
	|		CASE
	|			WHEN ISNULL(RoomSalesTurnovers.RoomsRented, 0) = 0
	|				THEN 0
	|			ELSE ISNULL(RoomSalesTurnovers.Sales, 0) / ISNULL(RoomSalesTurnovers.RoomsRented, 0)
	|		END AS AvgDailyRoomRate,
	|		CASE
	|			WHEN ISNULL(RoomSalesTurnovers.BedsRented, 0) = 0
	|				THEN 0
	|			ELSE ISNULL(RoomSalesTurnovers.Sales, 0) / ISNULL(RoomSalesTurnovers.BedsRented, 0)
	|		END AS AvgDailyBedRate,
	|		CASE
	|			WHEN ISNULL(RoomSalesTurnovers.RoomsRented, 0) = 0
	|				THEN 0
	|			ELSE ISNULL(RoomSalesTurnovers.SalesWithoutVAT, 0) / ISNULL(RoomSalesTurnovers.RoomsRented, 0)
	|		END AS AvgDailyRoomRateWithoutVAT,
	|		CASE
	|			WHEN ISNULL(RoomSalesTurnovers.BedsRented, 0) = 0
	|				THEN 0
	|			ELSE ISNULL(RoomSalesTurnovers.SalesWithoutVAT, 0) / ISNULL(RoomSalesTurnovers.BedsRented, 0)
	|		END AS AvgDailyBedRateWithoutVAT,
	|		ISNULL(RoomSalesTurnovers.RoomsRented, 0) AS RoomsRented,
	|		ISNULL(RoomSalesTurnovers.BedsRented, 0) AS BedsRented,
	|		ISNULL(RoomSalesTurnovers.GuaranteedRoomsRented, 0) AS GuaranteedRoomsRented,
	|		ISNULL(RoomSalesTurnovers.GuaranteedBedsRented, 0) AS GuaranteedBedsRented,
	|		ISNULL(RoomSalesTurnovers.NonGuaranteedRoomsRented, 0) AS NonGuaranteedRoomsRented,
	|		ISNULL(RoomSalesTurnovers.NonGuaranteedBedsRented, 0) AS NonGuaranteedBedsRented,
	|		ISNULL(RoomSalesTurnovers.Sales, 0) AS Sales,
	|		ISNULL(RoomSalesTurnovers.RoomRevenue, 0) AS RoomRevenue,
	|		ISNULL(RoomSalesTurnovers.SalesWithoutVAT, 0) AS SalesWithoutVAT,
	|		ISNULL(RoomSalesTurnovers.RoomRevenueWithoutVAT, 0) AS RoomRevenueWithoutVAT,
	|		ISNULL(RoomSalesTurnovers.GuaranteedSales, 0) AS GuaranteedSales,
	|		ISNULL(RoomSalesTurnovers.GuaranteedRoomRevenue, 0) AS GuaranteedRoomRevenue,
	|		ISNULL(RoomSalesTurnovers.GuaranteedSalesWithoutVAT, 0) AS GuaranteedSalesWithoutVAT,
	|		ISNULL(RoomSalesTurnovers.GuaranteedRoomRevenueWithoutVAT, 0) AS GuaranteedRoomRevenueWithoutVAT,
	|		ISNULL(RoomSalesTurnovers.NonGuaranteedSales, 0) AS NonGuaranteedSales,
	|		ISNULL(RoomSalesTurnovers.NonGuaranteedRoomRevenue, 0) AS NonGuaranteedRoomRevenue,
	|		ISNULL(RoomSalesTurnovers.NonGuaranteedSalesWithoutVAT, 0) AS NonGuaranteedSalesWithoutVAT,
	|		ISNULL(RoomSalesTurnovers.NonGuaranteedRoomRevenueWithoutVAT, 0) AS NonGuaranteedRoomRevenueWithoutVAT,
	|		ISNULL(RoomSalesTurnovers.ForecastSales, 0) AS ForecastSales,
	|		ISNULL(RoomSalesTurnovers.ForecastRoomRevenue, 0) AS ForecastRoomRevenue,
	|		ISNULL(RoomSalesTurnovers.ForecastSalesWithoutVAT, 0) AS ForecastSalesWithoutVAT,
	|		ISNULL(RoomSalesTurnovers.ForecastRoomRevenueWithoutVAT, 0) AS ForecastRoomRevenueWithoutVAT,
	|		ISNULL(RoomSalesTurnovers.InHouseSales, 0) AS InHouseSales,
	|		ISNULL(RoomSalesTurnovers.InHouseRoomRevenue, 0) AS InHouseRoomRevenue,
	|		ISNULL(RoomSalesTurnovers.InHouseSalesWithoutVAT, 0) AS InHouseSalesWithoutVAT,
	|		ISNULL(RoomSalesTurnovers.InHouseRoomRevenueWithoutVAT, 0) AS InHouseRoomRevenueWithoutVAT,
	|		ISNULL(RoomSalesTurnovers.CommissionSum, 0) AS CommissionSum,
	|		ISNULL(RoomSalesTurnovers.CommissionSumWithoutVAT, 0) AS CommissionSumWithoutVAT,
	|		ISNULL(RoomSalesTurnovers.ForecastCommissionSum, 0) AS ForecastCommissionSum,
	|		ISNULL(RoomSalesTurnovers.ForecastCommissionSumWithoutVAT, 0) AS ForecastCommissionSumWithoutVAT,
	|		ISNULL(RoomSalesTurnovers.InHouseCommissionSum, 0) AS InHouseCommissionSum,
	|		ISNULL(RoomSalesTurnovers.InHouseCommissionSumWithoutVAT, 0) AS InHouseCommissionSumWithoutVAT,
	|		ISNULL(RoomSalesTurnovers.DiscountSum, 0) AS DiscountSum,
	|		ISNULL(RoomSalesTurnovers.DiscountSumWithoutVAT, 0) AS DiscountSumWithoutVAT,
	|		ISNULL(RoomSalesTurnovers.ForecastDiscountSum, 0) AS ForecastDiscountSum,
	|		ISNULL(RoomSalesTurnovers.ForecastDiscountSumWithoutVAT, 0) AS ForecastDiscountSumWithoutVAT,
	|		ISNULL(RoomSalesTurnovers.InHouseDiscountSum, 0) AS InHouseDiscountSum,
	|		ISNULL(RoomSalesTurnovers.InHouseDiscountSumWithoutVAT, 0) AS InHouseDiscountSumWithoutVAT,
	|		ISNULL(RoomSalesTurnovers.DefinitiveSales, 0) AS DefinitiveSales,
	|		ISNULL(RoomSalesTurnovers.DefinitiveRoomRevenue, 0) AS DefinitiveRoomRevenue,
	|		ISNULL(RoomSalesTurnovers.DefinitiveSalesWithoutVAT, 0) AS DefinitiveSalesWithoutVAT,
	|		ISNULL(RoomSalesTurnovers.DefinitiveRoomRevenueWithoutVAT, 0) AS DefinitiveRoomRevenueWithoutVAT,
	|		ISNULL(RoomSalesTurnovers.TentativeSales, 0) AS TentativeSales,
	|		ISNULL(RoomSalesTurnovers.TentativeRoomRevenue, 0) AS TentativeRoomRevenue,
	|		ISNULL(RoomSalesTurnovers.TentativeSalesWithoutVAT, 0) AS TentativeSalesWithoutVAT,
	|		ISNULL(RoomSalesTurnovers.TentativeRoomRevenueWithoutVAT, 0) AS TentativeRoomRevenueWithoutVAT,
	|		ISNULL(TentativeGroups.TentativeRooms, 0) AS TentativeRooms,
	|		ISNULL(TentativeGroups.TentativeBeds, 0) AS TentativeBeds,
	|		ISNULL(TentativeGroups.TentativeAdditionalBeds, 0) AS TentativeAdditionalBeds,
	|		ISNULL(RoomSalesTurnovers.DefinitiveAdults, 0) AS DefinitiveAdults,
	|		ISNULL(RoomSalesTurnovers.DefinitiveChildren, 0) AS DefinitiveChildren,
	|		ISNULL(RoomSalesTurnovers.DefinitiveGuests, 0) AS DefinitiveGuests,
	|		ISNULL(RoomSalesTurnovers.TentativeAdults, 0) AS TentativeAdults,
	|		ISNULL(RoomSalesTurnovers.TentativeChildren, 0) AS TentativeChildren,
	|		ISNULL(RoomSalesTurnovers.TentativeGuests, 0) AS TentativeGuests,
	|		ISNULL(RoomSalesTurnovers.DefinitiveTeenagers, 0) AS DefinitiveTeenagers,
	|		ISNULL(RoomSalesTurnovers.DefinitiveChildrenOnly, 0) AS DefinitiveChildrenOnly,
	|		ISNULL(RoomSalesTurnovers.DefinitiveInfants, 0) AS DefinitiveInfants,
	|		ISNULL(RoomSalesTurnovers.TentativeTeenagers, 0) AS TentativeTeenagers,
	|		ISNULL(RoomSalesTurnovers.TentativeChildrenOnly, 0) AS TentativeChildrenOnly,
	|		ISNULL(RoomSalesTurnovers.TentativeInfants, 0) AS TentativeInfants
	|	FROM
	|		(SELECT
	|			BEGINOFPERIOD(RoomInventoryBalanceAndTurnovers.Period, DAY) AS Period,
	|			RoomInventoryBalanceAndTurnovers.Hotel AS Hotel,
	|			RoomInventoryBalanceAndTurnovers.RoomType AS RoomType,
	|			RoomInventoryBalanceAndTurnovers.CounterClosingBalance AS CounterClosingBalance,
	|			RoomInventoryBalanceAndTurnovers.TotalRoomsClosingBalance AS TotalRoomsClosingBalance,
	|			RoomInventoryBalanceAndTurnovers.RoomsBlockedClosingBalance AS RoomsBlockedClosingBalance,
	|			RoomInventoryBalanceAndTurnovers.TotalBedsClosingBalance AS TotalBedsClosingBalance,
	|			RoomInventoryBalanceAndTurnovers.BedsBlockedClosingBalance AS BedsBlockedClosingBalance,
	|			RoomInventoryBalanceAndTurnovers.RoomsReservedClosingBalance AS RoomsReservedClosingBalance,
	|			RoomInventoryBalanceAndTurnovers.BedsReservedClosingBalance AS BedsReservedClosingBalance,
	|			RoomInventoryBalanceAndTurnovers.GuestsReservedClosingBalance AS GuestsReservedClosingBalance,
	|			RoomInventoryBalanceAndTurnovers.InHouseRoomsClosingBalance AS InHouseRoomsClosingBalance,
	|			RoomInventoryBalanceAndTurnovers.InHouseBedsClosingBalance AS InHouseBedsClosingBalance,
	|			RoomInventoryBalanceAndTurnovers.InHouseGuestsClosingBalance AS InHouseGuestsClosingBalance,
	|			RoomInventoryBalanceAndTurnovers.AdditionalBedsReservedClosingBalance AS AdditionalBedsReservedClosingBalance,
	|			RoomInventoryBalanceAndTurnovers.InHouseAdditionalBedsClosingBalance AS InHouseAdditionalBedsClosingBalance,
	|			RoomInventoryBalanceAndTurnovers.GuaranteedRoomsReservedClosingBalance AS GuaranteedRoomsReservedClosingBalance,
	|			RoomInventoryBalanceAndTurnovers.GuaranteedBedsReservedClosingBalance AS GuaranteedBedsReservedClosingBalance,
	|			RoomInventoryBalanceAndTurnovers.GuaranteedGuestsReservedClosingBalance AS GuaranteedGuestsReservedClosingBalance,
	|			RoomInventoryBalanceAndTurnovers.RoomsCheckedInTurnover AS RoomsCheckedInTurnover,
	|			RoomInventoryBalanceAndTurnovers.BedsCheckedInTurnover AS BedsCheckedInTurnover,
	|			RoomInventoryBalanceAndTurnovers.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
	|			RoomInventoryBalanceAndTurnovers.AdditionalBedsCheckedInTurnover AS AdditionalBedsCheckedInTurnover,
	|			RoomInventoryBalanceAndTurnovers.ExpectedRoomsCheckedInTurnover AS ExpectedRoomsCheckedInTurnover,
	|			RoomInventoryBalanceAndTurnovers.ExpectedBedsCheckedInTurnover AS ExpectedBedsCheckedInTurnover,
	|			RoomInventoryBalanceAndTurnovers.ExpectedGuestsCheckedInTurnover AS ExpectedGuestsCheckedInTurnover,
	|			RoomInventoryBalanceAndTurnovers.ExpectedAdditionalBedsCheckedInTurnover AS ExpectedAdditionalBedsCheckedInTurnover,
	|			RoomInventoryBalanceAndTurnovers.GuaranteedExpectedRoomsCheckedInTurnover AS GuaranteedExpectedRoomsCheckedInTurnover,
	|			RoomInventoryBalanceAndTurnovers.GuaranteedExpectedBedsCheckedInTurnover AS GuaranteedExpectedBedsCheckedInTurnover,
	|			RoomInventoryBalanceAndTurnovers.GuaranteedExpectedGuestsCheckedInTurnover AS GuaranteedExpectedGuestsCheckedInTurnover,
	|			RoomInventoryBalanceAndTurnovers.RoomsCheckedOutTurnover AS RoomsCheckedOutTurnover,
	|			RoomInventoryBalanceAndTurnovers.ExpectedRoomsCheckedOutTurnover AS ExpectedRoomsCheckedOutTurnover,
	|			RoomInventoryBalanceAndTurnovers.BedsCheckedOutTurnover AS BedsCheckedOutTurnover,
	|			RoomInventoryBalanceAndTurnovers.ExpectedBedsCheckedOutTurnover AS ExpectedBedsCheckedOutTurnover,
	|			RoomInventoryBalanceAndTurnovers.AdditionalBedsCheckedOutTurnover AS AdditionalBedsCheckedOutTurnover,
	|			RoomInventoryBalanceAndTurnovers.ExpectedAdditionalBedsCheckedOutTurnover AS ExpectedAdditionalBedsCheckedOutTurnover,
	|			RoomInventoryBalanceAndTurnovers.GuestsCheckedOutTurnover AS GuestsCheckedOutTurnover,
	|			RoomInventoryBalanceAndTurnovers.ExpectedGuestsCheckedOutTurnover AS ExpectedGuestsCheckedOutTurnover,
	|			RoomInventoryBalanceAndTurnovers.RoomsReservedClosingBalance AS RoomsReservedClosingBalance1,
	|			RoomInventoryBalanceAndTurnovers.BedsReservedClosingBalance AS BedsReservedClosingBalance1,
	|			RoomInventoryBalanceAndTurnovers.InHouseRoomsOpeningBalance AS InHouseRoomsOpeningBalance,
	|			RoomInventoryBalanceAndTurnovers.InHouseBedsOpeningBalance AS InHouseBedsOpeningBalance,
	|			RoomInventoryBalanceAndTurnovers.InHouseGuestsOpeningBalance AS InHouseGuestsOpeningBalance,
	|			RoomInventoryBalanceAndTurnovers.RoomsReservedOpeningBalance AS RoomsReservedOpeningBalance,
	|			RoomInventoryBalanceAndTurnovers.BedsReservedOpeningBalance AS BedsReservedOpeningBalance,
	|			RoomInventoryBalanceAndTurnovers.GuestsReservedOpeningBalance AS GuestsReservedOpeningBalance
	|		FROM
	|			AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|					&qPeriodFrom,
	|					&qPeriodTo,
	|					Day,
	|					RegisterRecords,
	|					Hotel IN HIERARCHY (&qHotel)
	|						AND (Room IN HIERARCHY (&qRoom)
	|							OR &qIsEmptyRoom)
	|						AND (NOT RoomType.DeletionMark
	|							OR RoomType IN
	|								(SELECT
	|									RoomTypesInSales.RoomType
	|								FROM
	|									RoomTypesInSales AS RoomTypesInSales))
	|						AND (RoomType IN HIERARCHY (&qRoomType)
	|							OR &qIsEmptyRoomType)) AS RoomInventoryBalanceAndTurnovers
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			BEGINOFPERIOD(EmptyRoomTypesRecords.Period, DAY),
	|			EmptyRoomTypesRecords.Hotel,
	|			VALUE(Catalog.RoomTypes.EmptyRef),
	|			EmptyRoomTypesRecords.CounterClosingBalance,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0
	|		FROM
	|			AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qPeriodFrom, &qPeriodTo, Day, RegisterRecords, Hotel IN HIERARCHY (&qHotel)) AS EmptyRoomTypesRecords
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			BEGINOFPERIOD(VirtualRoomTypesRecords.Period, DAY),
	|			VirtualRoomTypesRecords.Hotel,
	|			VirtualRoomTypes.Ref,
	|			VirtualRoomTypesRecords.CounterClosingBalance,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0
	|		FROM
	|			AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qPeriodFrom, &qPeriodTo, Day, RegisterRecords, Hotel IN HIERARCHY (&qHotel)) AS VirtualRoomTypesRecords
	|				LEFT JOIN Catalog.RoomTypes AS VirtualRoomTypes
	|				ON VirtualRoomTypesRecords.Hotel = VirtualRoomTypes.Owner
	|					AND (VirtualRoomTypes.IsVirtual)
	|					AND (NOT VirtualRoomTypes.IsFolder)
	|					AND (NOT VirtualRoomTypes.DeletionMark
	|						OR VirtualRoomTypesRecords.RoomType IN
	|							(SELECT
	|								RoomTypesInSales.RoomType
	|							FROM
	|								RoomTypesInSales AS RoomTypesInSales))
	|					AND (&qShowSales)) AS RoomInventory
	|			LEFT JOIN RoomQuotaSales AS RoomQuotaSales
	|			ON RoomInventory.RoomType = RoomQuotaSales.RoomType
	|				AND RoomInventory.Period = RoomQuotaSales.Period
	|			LEFT JOIN NotCommitmentAllotments AS NotCommitmentAllotments
	|			ON RoomInventory.RoomType = NotCommitmentAllotments.RoomType
	|				AND RoomInventory.Period = NotCommitmentAllotments.Period
	|			LEFT JOIN CommitmentAllotments AS CommitmentAllotments
	|			ON RoomInventory.RoomType = CommitmentAllotments.RoomType
	|				AND RoomInventory.Period = CommitmentAllotments.Period
	|			LEFT JOIN TentativeGroups AS TentativeGroups
	|			ON RoomInventory.RoomType = TentativeGroups.RoomType
	|				AND RoomInventory.Period = TentativeGroups.Period
	|			LEFT JOIN GuaranteedBusinessBlocks AS GuaranteedBusinessBlocks
	|			ON RoomInventory.RoomType = GuaranteedBusinessBlocks.RoomType
	|				AND RoomInventory.Period = GuaranteedBusinessBlocks.Period
	|			LEFT JOIN NotGuaranteedBusinessBlocks AS NotGuaranteedBusinessBlocks
	|			ON RoomInventory.RoomType = NotGuaranteedBusinessBlocks.RoomType
	|				AND RoomInventory.Period = NotGuaranteedBusinessBlocks.Period
	|			LEFT JOIN (SELECT
	|				RoomPlanFactSales.Period AS Period,
	|				RoomPlanFactSales.RoomType AS RoomType,
	|				SUM(RoomPlanFactSales.RoomsRented) AS RoomsRented,
	|				SUM(RoomPlanFactSales.BedsRented) AS BedsRented,
	|				SUM(RoomPlanFactSales.GuaranteedRoomsRented) AS GuaranteedRoomsRented,
	|				SUM(RoomPlanFactSales.GuaranteedBedsRented) AS GuaranteedBedsRented,
	|				SUM(RoomPlanFactSales.NonGuaranteedRoomsRented) AS NonGuaranteedRoomsRented,
	|				SUM(RoomPlanFactSales.NonGuaranteedBedsRented) AS NonGuaranteedBedsRented,
	|				SUM(RoomPlanFactSales.Sales) AS Sales,
	|				SUM(RoomPlanFactSales.RoomRevenue) AS RoomRevenue,
	|				SUM(RoomPlanFactSales.SalesWithoutVAT) AS SalesWithoutVAT,
	|				SUM(RoomPlanFactSales.RoomRevenueWithoutVAT) AS RoomRevenueWithoutVAT,
	|				SUM(RoomPlanFactSales.GuaranteedSales) AS GuaranteedSales,
	|				SUM(RoomPlanFactSales.GuaranteedRoomRevenue) AS GuaranteedRoomRevenue,
	|				SUM(RoomPlanFactSales.GuaranteedSalesWithoutVAT) AS GuaranteedSalesWithoutVAT,
	|				SUM(RoomPlanFactSales.GuaranteedRoomRevenueWithoutVAT) AS GuaranteedRoomRevenueWithoutVAT,
	|				SUM(RoomPlanFactSales.NonGuaranteedSales) AS NonGuaranteedSales,
	|				SUM(RoomPlanFactSales.NonGuaranteedRoomRevenue) AS NonGuaranteedRoomRevenue,
	|				SUM(RoomPlanFactSales.NonGuaranteedSalesWithoutVAT) AS NonGuaranteedSalesWithoutVAT,
	|				SUM(RoomPlanFactSales.NonGuaranteedRoomRevenueWithoutVAT) AS NonGuaranteedRoomRevenueWithoutVAT,
	|				SUM(RoomPlanFactSales.InHouseSales) AS InHouseSales,
	|				SUM(RoomPlanFactSales.InHouseRoomRevenue) AS InHouseRoomRevenue,
	|				SUM(RoomPlanFactSales.InHouseSalesWithoutVAT) AS InHouseSalesWithoutVAT,
	|				SUM(RoomPlanFactSales.InHouseRoomRevenueWithoutVAT) AS InHouseRoomRevenueWithoutVAT,
	|				SUM(RoomPlanFactSales.ForecastSales) AS ForecastSales,
	|				SUM(RoomPlanFactSales.ForecastRoomRevenue) AS ForecastRoomRevenue,
	|				SUM(RoomPlanFactSales.ForecastSalesWithoutVAT) AS ForecastSalesWithoutVAT,
	|				SUM(RoomPlanFactSales.ForecastRoomRevenueWithoutVAT) AS ForecastRoomRevenueWithoutVAT,
	|				SUM(RoomPlanFactSales.CommissionSum) AS CommissionSum,
	|				SUM(RoomPlanFactSales.CommissionSumWithoutVAT) AS CommissionSumWithoutVAT,
	|				SUM(RoomPlanFactSales.InHouseCommissionSum) AS InHouseCommissionSum,
	|				SUM(RoomPlanFactSales.InHouseCommissionSumWithoutVAT) AS InHouseCommissionSumWithoutVAT,
	|				SUM(RoomPlanFactSales.ForecastCommissionSum) AS ForecastCommissionSum,
	|				SUM(RoomPlanFactSales.ForecastCommissionSumWithoutVAT) AS ForecastCommissionSumWithoutVAT,
	|				SUM(RoomPlanFactSales.DiscountSum) AS DiscountSum,
	|				SUM(RoomPlanFactSales.DiscountSumWithoutVAT) AS DiscountSumWithoutVAT,
	|				SUM(RoomPlanFactSales.InHouseDiscountSum) AS InHouseDiscountSum,
	|				SUM(RoomPlanFactSales.InHouseDiscountSumWithoutVAT) AS InHouseDiscountSumWithoutVAT,
	|				SUM(RoomPlanFactSales.ForecastDiscountSum) AS ForecastDiscountSum,
	|				SUM(RoomPlanFactSales.ForecastDiscountSumWithoutVAT) AS ForecastDiscountSumWithoutVAT,
	|				SUM(RoomPlanFactSales.DefinitiveSales) AS DefinitiveSales,
	|				SUM(RoomPlanFactSales.DefinitiveRoomRevenue) AS DefinitiveRoomRevenue,
	|				SUM(RoomPlanFactSales.DefinitiveSalesWithoutVAT) AS DefinitiveSalesWithoutVAT,
	|				SUM(RoomPlanFactSales.DefinitiveRoomRevenueWithoutVAT) AS DefinitiveRoomRevenueWithoutVAT,
	|				SUM(RoomPlanFactSales.TentativeSales) AS TentativeSales,
	|				SUM(RoomPlanFactSales.TentativeRoomRevenue) AS TentativeRoomRevenue,
	|				SUM(RoomPlanFactSales.TentativeSalesWithoutVAT) AS TentativeSalesWithoutVAT,
	|				SUM(RoomPlanFactSales.TentativeRoomRevenueWithoutVAT) AS TentativeRoomRevenueWithoutVAT,
	|				SUM(RoomPlanFactSales.DefinitiveAdults) AS DefinitiveAdults,
	|				SUM(RoomPlanFactSales.DefinitiveChildren) AS DefinitiveChildren,
	|				SUM(RoomPlanFactSales.DefinitiveGuests) AS DefinitiveGuests,
	|				SUM(RoomPlanFactSales.TentativeAdults) AS TentativeAdults,
	|				SUM(RoomPlanFactSales.TentativeChildren) AS TentativeChildren,
	|				SUM(RoomPlanFactSales.TentativeGuests) AS TentativeGuests,
	|				SUM(RoomPlanFactSales.DefinitiveTeenagers) AS DefinitiveTeenagers,
	|				SUM(RoomPlanFactSales.DefinitiveChildrenOnly) AS DefinitiveChildrenOnly,
	|				SUM(RoomPlanFactSales.DefinitiveInfants) AS DefinitiveInfants,
	|				SUM(RoomPlanFactSales.TentativeTeenagers) AS TentativeTeenagers,
	|				SUM(RoomPlanFactSales.TentativeChildrenOnly) AS TentativeChildrenOnly,
	|				SUM(RoomPlanFactSales.TentativeInfants) AS TentativeInfants
	|			FROM
	|				(SELECT
	|					RoomSales.Period AS Period,
	|					RoomSales.RoomType AS RoomType,
	|					RoomSales.ParentDoc AS ParentDoc,
	|					RoomSales.RoomsRentedTurnover AS RoomsRented,
	|					RoomSales.BedsRentedTurnover AS BedsRented,
	|					RoomSales.RoomsRentedTurnover AS GuaranteedRoomsRented,
	|					RoomSales.BedsRentedTurnover AS GuaranteedBedsRented,
	|					0 AS NonGuaranteedRoomsRented,
	|					0 AS NonGuaranteedBedsRented,
	|					RoomSales.SalesTurnover AS Sales,
	|					RoomSales.RoomRevenueTurnover AS RoomRevenue,
	|					RoomSales.SalesWithoutVATTurnover AS SalesWithoutVAT,
	|					RoomSales.RoomRevenueWithoutVATTurnover AS RoomRevenueWithoutVAT,
	|					RoomSales.SalesTurnover AS GuaranteedSales,
	|					RoomSales.RoomRevenueTurnover AS GuaranteedRoomRevenue,
	|					RoomSales.SalesWithoutVATTurnover AS GuaranteedSalesWithoutVAT,
	|					RoomSales.RoomRevenueWithoutVATTurnover AS GuaranteedRoomRevenueWithoutVAT,
	|					0 AS NonGuaranteedSales,
	|					0 AS NonGuaranteedRoomRevenue,
	|					0 AS NonGuaranteedSalesWithoutVAT,
	|					0 AS NonGuaranteedRoomRevenueWithoutVAT,
	|					RoomSales.SalesTurnover AS InHouseSales,
	|					RoomSales.RoomRevenueTurnover AS InHouseRoomRevenue,
	|					RoomSales.SalesWithoutVATTurnover AS InHouseSalesWithoutVAT,
	|					RoomSales.RoomRevenueWithoutVATTurnover AS InHouseRoomRevenueWithoutVAT,
	|					0 AS ForecastSales,
	|					0 AS ForecastRoomRevenue,
	|					0 AS ForecastSalesWithoutVAT,
	|					0 AS ForecastRoomRevenueWithoutVAT,
	|					RoomSales.CommissionSumTurnover AS CommissionSum,
	|					RoomSales.CommissionSumWithoutVATTurnover AS CommissionSumWithoutVAT,
	|					RoomSales.CommissionSumTurnover AS InHouseCommissionSum,
	|					RoomSales.CommissionSumWithoutVATTurnover AS InHouseCommissionSumWithoutVAT,
	|					0 AS ForecastCommissionSum,
	|					0 AS ForecastCommissionSumWithoutVAT,
	|					RoomSales.DiscountSumTurnover AS DiscountSum,
	|					RoomSales.DiscountSumWithoutVATTurnover AS DiscountSumWithoutVAT,
	|					RoomSales.DiscountSumTurnover AS InHouseDiscountSum,
	|					RoomSales.DiscountSumWithoutVATTurnover AS InHouseDiscountSumWithoutVAT,
	|					0 AS ForecastDiscountSum,
	|					0 AS ForecastDiscountSumWithoutVAT,
	|					RoomSales.SalesTurnover AS DefinitiveSales,
	|					RoomSales.RoomRevenueTurnover AS DefinitiveRoomRevenue,
	|					RoomSales.SalesWithoutVATTurnover AS DefinitiveSalesWithoutVAT,
	|					RoomSales.RoomRevenueWithoutVATTurnover AS DefinitiveRoomRevenueWithoutVAT,
	|					0 AS TentativeSales,
	|					0 AS TentativeRoomRevenue,
	|					0 AS TentativeSalesWithoutVAT,
	|					0 AS TentativeRoomRevenueWithoutVAT,
	|					ISNULL(RoomSales.ParentDoc.NumberOfAdults, 0) AS DefinitiveAdults,
	|					ISNULL(RoomSales.ParentDoc.NumberOfTeenagers, 0) + ISNULL(RoomSales.ParentDoc.NumberOfChildren, 0) + ISNULL(RoomSales.ParentDoc.NumberOfInfants, 0) AS DefinitiveChildren,
	|					ISNULL(RoomSales.ParentDoc.NumberOfAdults, 0) + ISNULL(RoomSales.ParentDoc.NumberOfTeenagers, 0) + ISNULL(RoomSales.ParentDoc.NumberOfChildren, 0) + ISNULL(RoomSales.ParentDoc.NumberOfInfants, 0) AS DefinitiveGuests,
	|					0 AS TentativeAdults,
	|					0 AS TentativeChildren,
	|					0 AS TentativeGuests,
	|					ISNULL(RoomSales.ParentDoc.NumberOfTeenagers, 0) AS DefinitiveTeenagers,
	|					ISNULL(RoomSales.ParentDoc.NumberOfChildren, 0) AS DefinitiveChildrenOnly,
	|					ISNULL(RoomSales.ParentDoc.NumberOfInfants, 0) AS DefinitiveInfants,
	|					0 AS TentativeTeenagers,
	|					0 AS TentativeChildrenOnly,
	|					0 AS TentativeInfants
	|				FROM
	|					AccumulationRegister.Sales.Turnovers(
	|							&qPeriodFrom,
	|							&qPeriodTo,
	|							Day,
	|							NOT IsCorrection
	|								AND Hotel IN HIERARCHY (&qHotel)
	|								AND (Room IN HIERARCHY (&qRoom)
	|									OR &qIsEmptyRoom)
	|								AND (RoomType IN HIERARCHY (&qRoomType)
	|									OR &qIsEmptyRoomType)
	|								AND (Service IN HIERARCHY (&qService)
	|									OR &qIsEmptyService)
	|								AND (Service IN (&qServicesList)
	|									OR NOT &qUseServicesList)) AS RoomSales
	|				
	|				UNION ALL
	|				
	|				SELECT
	|					RoomSalesForecast.Period,
	|					RoomSalesForecast.RoomType,
	|					RoomSalesForecast.ParentDoc,
	|					RoomSalesForecast.RoomsRentedTurnover,
	|					RoomSalesForecast.BedsRentedTurnover,
	|					CASE
	|						WHEN RoomSalesForecast.ParentDoc = UNDEFINED
	|								AND RoomSalesForecast.RoomQuota.AllotmentBusinessType = VALUE(Enum.AllotmentBusinessTypes.BusinessBlock)
	|								AND RoomSalesForecast.RoomQuota.AllotmentType <> VALUE(Enum.AllotmentTypes.Definite)
	|							THEN 0
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT ISNULL(RoomSalesForecast.ParentDoc.ReservationStatus.IsGuaranteed, TRUE)
	|							THEN 0
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT ISNULL(RoomSalesForecast.ParentDoc.ResourceReservationStatus.IsGuaranteed, TRUE)
	|							THEN 0
	|						ELSE RoomSalesForecast.RoomsRentedTurnover
	|					END,
	|					CASE
	|						WHEN RoomSalesForecast.ParentDoc = UNDEFINED
	|								AND RoomSalesForecast.RoomQuota.AllotmentBusinessType = VALUE(Enum.AllotmentBusinessTypes.BusinessBlock)
	|								AND RoomSalesForecast.RoomQuota.AllotmentType <> VALUE(Enum.AllotmentTypes.Definite)
	|							THEN 0
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT ISNULL(RoomSalesForecast.ParentDoc.ReservationStatus.IsGuaranteed, TRUE)
	|							THEN 0
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT ISNULL(RoomSalesForecast.ParentDoc.ResourceReservationStatus.IsGuaranteed, TRUE)
	|							THEN 0
	|						ELSE RoomSalesForecast.BedsRentedTurnover
	|					END,
	|					CASE
	|						WHEN RoomSalesForecast.ParentDoc = UNDEFINED
	|								AND RoomSalesForecast.RoomQuota.AllotmentBusinessType = VALUE(Enum.AllotmentBusinessTypes.BusinessBlock)
	|								AND (RoomSalesForecast.RoomQuota.AllotmentType = VALUE(Enum.AllotmentTypes.Tentative)
	|									OR RoomSalesForecast.RoomQuota.AllotmentType = VALUE(Enum.AllotmentTypes.DefiniteNotGuaranteed))
	|							THEN RoomSalesForecast.RoomsRentedTurnover
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT ISNULL(RoomSalesForecast.ParentDoc.ReservationStatus.IsGuaranteed, TRUE)
	|							THEN RoomSalesForecast.RoomsRentedTurnover
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT ISNULL(RoomSalesForecast.ParentDoc.ResourceReservationStatus.IsGuaranteed, TRUE)
	|							THEN RoomSalesForecast.RoomsRentedTurnover
	|						ELSE 0
	|					END,
	|					CASE
	|						WHEN RoomSalesForecast.ParentDoc = UNDEFINED
	|								AND RoomSalesForecast.RoomQuota.AllotmentBusinessType = VALUE(Enum.AllotmentBusinessTypes.BusinessBlock)
	|								AND (RoomSalesForecast.RoomQuota.AllotmentType = VALUE(Enum.AllotmentTypes.Tentative)
	|									OR RoomSalesForecast.RoomQuota.AllotmentType = VALUE(Enum.AllotmentTypes.DefiniteNotGuaranteed))
	|							THEN RoomSalesForecast.BedsRentedTurnover
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT ISNULL(RoomSalesForecast.ParentDoc.ReservationStatus.IsGuaranteed, TRUE)
	|							THEN RoomSalesForecast.BedsRentedTurnover
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT ISNULL(RoomSalesForecast.ParentDoc.ResourceReservationStatus.IsGuaranteed, TRUE)
	|							THEN RoomSalesForecast.BedsRentedTurnover
	|						ELSE 0
	|					END,
	|					RoomSalesForecast.SalesTurnover,
	|					RoomSalesForecast.RoomRevenueTurnover,
	|					RoomSalesForecast.SalesWithoutVATTurnover,
	|					RoomSalesForecast.RoomRevenueWithoutVATTurnover,
	|					CASE
	|						WHEN RoomSalesForecast.ParentDoc = UNDEFINED
	|								AND RoomSalesForecast.RoomQuota.AllotmentBusinessType = VALUE(Enum.AllotmentBusinessTypes.BusinessBlock)
	|								AND RoomSalesForecast.RoomQuota.AllotmentType <> VALUE(Enum.AllotmentTypes.Definite)
	|							THEN 0
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT ISNULL(RoomSalesForecast.ParentDoc.ReservationStatus.IsGuaranteed, TRUE)
	|							THEN 0
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT ISNULL(RoomSalesForecast.ParentDoc.ResourceReservationStatus.IsGuaranteed, TRUE)
	|							THEN 0
	|						ELSE RoomSalesForecast.SalesTurnover
	|					END,
	|					CASE
	|						WHEN RoomSalesForecast.ParentDoc = UNDEFINED
	|								AND RoomSalesForecast.RoomQuota.AllotmentBusinessType = VALUE(Enum.AllotmentBusinessTypes.BusinessBlock)
	|								AND RoomSalesForecast.RoomQuota.AllotmentType <> VALUE(Enum.AllotmentTypes.Definite)
	|							THEN 0
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT ISNULL(RoomSalesForecast.ParentDoc.ReservationStatus.IsGuaranteed, TRUE)
	|							THEN 0
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT ISNULL(RoomSalesForecast.ParentDoc.ResourceReservationStatus.IsGuaranteed, TRUE)
	|							THEN 0
	|						ELSE RoomSalesForecast.RoomRevenueTurnover
	|					END,
	|					CASE
	|						WHEN RoomSalesForecast.ParentDoc = UNDEFINED
	|								AND RoomSalesForecast.RoomQuota.AllotmentBusinessType = VALUE(Enum.AllotmentBusinessTypes.BusinessBlock)
	|								AND RoomSalesForecast.RoomQuota.AllotmentType <> VALUE(Enum.AllotmentTypes.Definite)
	|							THEN 0
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT ISNULL(RoomSalesForecast.ParentDoc.ReservationStatus.IsGuaranteed, TRUE)
	|							THEN 0
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT ISNULL(RoomSalesForecast.ParentDoc.ResourceReservationStatus.IsGuaranteed, TRUE)
	|							THEN 0
	|						ELSE RoomSalesForecast.SalesWithoutVATTurnover
	|					END,
	|					CASE
	|						WHEN RoomSalesForecast.ParentDoc = UNDEFINED
	|								AND RoomSalesForecast.RoomQuota.AllotmentBusinessType = VALUE(Enum.AllotmentBusinessTypes.BusinessBlock)
	|								AND RoomSalesForecast.RoomQuota.AllotmentType <> VALUE(Enum.AllotmentTypes.Definite)
	|							THEN 0
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT ISNULL(RoomSalesForecast.ParentDoc.ReservationStatus.IsGuaranteed, TRUE)
	|							THEN 0
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT ISNULL(RoomSalesForecast.ParentDoc.ResourceReservationStatus.IsGuaranteed, TRUE)
	|							THEN 0
	|						ELSE RoomSalesForecast.RoomRevenueWithoutVATTurnover
	|					END,
	|					CASE
	|						WHEN RoomSalesForecast.ParentDoc = UNDEFINED
	|								AND RoomSalesForecast.RoomQuota.AllotmentBusinessType = VALUE(Enum.AllotmentBusinessTypes.BusinessBlock)
	|								AND (RoomSalesForecast.RoomQuota.AllotmentType = VALUE(Enum.AllotmentTypes.Tentative)
	|									OR RoomSalesForecast.RoomQuota.AllotmentType = VALUE(Enum.AllotmentTypes.DefiniteNotGuaranteed))
	|							THEN RoomSalesForecast.SalesTurnover
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT ISNULL(RoomSalesForecast.ParentDoc.ReservationStatus.IsGuaranteed, TRUE)
	|							THEN RoomSalesForecast.SalesTurnover
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT ISNULL(RoomSalesForecast.ParentDoc.ResourceReservationStatus.IsGuaranteed, TRUE)
	|							THEN RoomSalesForecast.SalesTurnover
	|						ELSE 0
	|					END,
	|					CASE
	|						WHEN RoomSalesForecast.ParentDoc = UNDEFINED
	|								AND RoomSalesForecast.RoomQuota.AllotmentBusinessType = VALUE(Enum.AllotmentBusinessTypes.BusinessBlock)
	|								AND (RoomSalesForecast.RoomQuota.AllotmentType = VALUE(Enum.AllotmentTypes.Tentative)
	|									OR RoomSalesForecast.RoomQuota.AllotmentType = VALUE(Enum.AllotmentTypes.DefiniteNotGuaranteed))
	|							THEN RoomSalesForecast.RoomRevenueTurnover
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT ISNULL(RoomSalesForecast.ParentDoc.ReservationStatus.IsGuaranteed, TRUE)
	|							THEN RoomSalesForecast.RoomRevenueTurnover
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT ISNULL(RoomSalesForecast.ParentDoc.ResourceReservationStatus.IsGuaranteed, TRUE)
	|							THEN RoomSalesForecast.RoomRevenueTurnover
	|						ELSE 0
	|					END,
	|					CASE
	|						WHEN RoomSalesForecast.ParentDoc = UNDEFINED
	|								AND RoomSalesForecast.RoomQuota.AllotmentBusinessType = VALUE(Enum.AllotmentBusinessTypes.BusinessBlock)
	|								AND (RoomSalesForecast.RoomQuota.AllotmentType = VALUE(Enum.AllotmentTypes.Tentative)
	|									OR RoomSalesForecast.RoomQuota.AllotmentType = VALUE(Enum.AllotmentTypes.DefiniteNotGuaranteed))
	|							THEN RoomSalesForecast.SalesWithoutVATTurnover
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT ISNULL(RoomSalesForecast.ParentDoc.ReservationStatus.IsGuaranteed, TRUE)
	|							THEN RoomSalesForecast.SalesWithoutVATTurnover
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT ISNULL(RoomSalesForecast.ParentDoc.ResourceReservationStatus.IsGuaranteed, TRUE)
	|							THEN RoomSalesForecast.SalesWithoutVATTurnover
	|						ELSE 0
	|					END,
	|					CASE
	|						WHEN RoomSalesForecast.ParentDoc = UNDEFINED
	|								AND RoomSalesForecast.RoomQuota.AllotmentBusinessType = VALUE(Enum.AllotmentBusinessTypes.BusinessBlock)
	|								AND (RoomSalesForecast.RoomQuota.AllotmentType = VALUE(Enum.AllotmentTypes.Tentative)
	|									OR RoomSalesForecast.RoomQuota.AllotmentType = VALUE(Enum.AllotmentTypes.DefiniteNotGuaranteed))
	|							THEN RoomSalesForecast.RoomRevenueWithoutVATTurnover
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT ISNULL(RoomSalesForecast.ParentDoc.ReservationStatus.IsGuaranteed, TRUE)
	|							THEN RoomSalesForecast.RoomRevenueWithoutVATTurnover
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT ISNULL(RoomSalesForecast.ParentDoc.ResourceReservationStatus.IsGuaranteed, TRUE)
	|							THEN RoomSalesForecast.RoomRevenueWithoutVATTurnover
	|						ELSE 0
	|					END,
	|					0,
	|					0,
	|					0,
	|					0,
	|					RoomSalesForecast.SalesTurnover,
	|					RoomSalesForecast.RoomRevenueTurnover,
	|					RoomSalesForecast.SalesWithoutVATTurnover,
	|					RoomSalesForecast.RoomRevenueWithoutVATTurnover,
	|					RoomSalesForecast.CommissionSumTurnover,
	|					RoomSalesForecast.CommissionSumWithoutVATTurnover,
	|					0,
	|					0,
	|					RoomSalesForecast.CommissionSumTurnover,
	|					RoomSalesForecast.CommissionSumWithoutVATTurnover,
	|					RoomSalesForecast.DiscountSumTurnover,
	|					RoomSalesForecast.DiscountSumWithoutVATTurnover,
	|					0,
	|					0,
	|					RoomSalesForecast.DiscountSumTurnover,
	|					RoomSalesForecast.DiscountSumWithoutVATTurnover,
	|					CASE
	|						WHEN RoomSalesForecast.ParentDoc = UNDEFINED
	|								AND RoomSalesForecast.RoomQuota.AllotmentBusinessType = VALUE(Enum.AllotmentBusinessTypes.BusinessBlock)
	|								AND RoomSalesForecast.RoomQuota.AllotmentType = VALUE(Enum.AllotmentTypes.Tentative)
	|							THEN 0
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ReservationStatus IS NULL
	|								AND RoomSalesForecast.ParentDoc.ReservationStatus.IsPreliminary
	|							THEN 0
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus IS NULL
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus.IsGuaranteed
	|							THEN 0
	|						ELSE RoomSalesForecast.SalesTurnover
	|					END,
	|					CASE
	|						WHEN RoomSalesForecast.ParentDoc = UNDEFINED
	|								AND RoomSalesForecast.RoomQuota.AllotmentBusinessType = VALUE(Enum.AllotmentBusinessTypes.BusinessBlock)
	|								AND RoomSalesForecast.RoomQuota.AllotmentType = VALUE(Enum.AllotmentTypes.Tentative)
	|							THEN 0
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ReservationStatus IS NULL
	|								AND RoomSalesForecast.ParentDoc.ReservationStatus.IsPreliminary
	|							THEN 0
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus IS NULL
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus.IsGuaranteed
	|							THEN 0
	|						ELSE RoomSalesForecast.RoomRevenueTurnover
	|					END,
	|					CASE
	|						WHEN RoomSalesForecast.ParentDoc = UNDEFINED
	|								AND RoomSalesForecast.RoomQuota.AllotmentBusinessType = VALUE(Enum.AllotmentBusinessTypes.BusinessBlock)
	|								AND RoomSalesForecast.RoomQuota.AllotmentType = VALUE(Enum.AllotmentTypes.Tentative)
	|							THEN 0
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ReservationStatus IS NULL
	|								AND RoomSalesForecast.ParentDoc.ReservationStatus.IsPreliminary
	|							THEN 0
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus IS NULL
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus.IsGuaranteed
	|							THEN 0
	|						ELSE RoomSalesForecast.SalesWithoutVATTurnover
	|					END,
	|					CASE
	|						WHEN RoomSalesForecast.ParentDoc = UNDEFINED
	|								AND RoomSalesForecast.RoomQuota.AllotmentBusinessType = VALUE(Enum.AllotmentBusinessTypes.BusinessBlock)
	|								AND RoomSalesForecast.RoomQuota.AllotmentType = VALUE(Enum.AllotmentTypes.Tentative)
	|							THEN 0
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ReservationStatus IS NULL
	|								AND RoomSalesForecast.ParentDoc.ReservationStatus.IsPreliminary
	|							THEN 0
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus IS NULL
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus.IsGuaranteed
	|							THEN 0
	|						ELSE RoomSalesForecast.RoomRevenueWithoutVATTurnover
	|					END,
	|					CASE
	|						WHEN RoomSalesForecast.ParentDoc = UNDEFINED
	|								AND RoomSalesForecast.RoomQuota.AllotmentBusinessType = VALUE(Enum.AllotmentBusinessTypes.BusinessBlock)
	|								AND RoomSalesForecast.RoomQuota.AllotmentType = VALUE(Enum.AllotmentTypes.Tentative)
	|							THEN RoomSalesForecast.SalesTurnover
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ReservationStatus IS NULL
	|								AND RoomSalesForecast.ParentDoc.ReservationStatus.IsPreliminary
	|							THEN RoomSalesForecast.SalesTurnover
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus IS NULL
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus.IsGuaranteed
	|							THEN RoomSalesForecast.SalesTurnover
	|						ELSE 0
	|					END,
	|					CASE
	|						WHEN RoomSalesForecast.ParentDoc = UNDEFINED
	|								AND RoomSalesForecast.RoomQuota.AllotmentBusinessType = VALUE(Enum.AllotmentBusinessTypes.BusinessBlock)
	|								AND RoomSalesForecast.RoomQuota.AllotmentType = VALUE(Enum.AllotmentTypes.Tentative)
	|							THEN RoomSalesForecast.RoomRevenueTurnover
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ReservationStatus IS NULL
	|								AND RoomSalesForecast.ParentDoc.ReservationStatus.IsPreliminary
	|							THEN RoomSalesForecast.RoomRevenueTurnover
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus IS NULL
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus.IsGuaranteed
	|							THEN RoomSalesForecast.RoomRevenueTurnover
	|						ELSE 0
	|					END,
	|					CASE
	|						WHEN RoomSalesForecast.ParentDoc = UNDEFINED
	|								AND RoomSalesForecast.RoomQuota.AllotmentBusinessType = VALUE(Enum.AllotmentBusinessTypes.BusinessBlock)
	|								AND RoomSalesForecast.RoomQuota.AllotmentType = VALUE(Enum.AllotmentTypes.Tentative)
	|							THEN RoomSalesForecast.SalesWithoutVATTurnover
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ReservationStatus IS NULL
	|								AND RoomSalesForecast.ParentDoc.ReservationStatus.IsPreliminary
	|							THEN RoomSalesForecast.SalesWithoutVATTurnover
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus IS NULL
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus.IsGuaranteed
	|							THEN RoomSalesForecast.SalesWithoutVATTurnover
	|						ELSE 0
	|					END,
	|					CASE
	|						WHEN RoomSalesForecast.ParentDoc = UNDEFINED
	|								AND RoomSalesForecast.RoomQuota.AllotmentBusinessType = VALUE(Enum.AllotmentBusinessTypes.BusinessBlock)
	|								AND RoomSalesForecast.RoomQuota.AllotmentType = VALUE(Enum.AllotmentTypes.Tentative)
	|							THEN RoomSalesForecast.RoomRevenueWithoutVATTurnover
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ReservationStatus IS NULL
	|								AND RoomSalesForecast.ParentDoc.ReservationStatus.IsPreliminary
	|							THEN RoomSalesForecast.RoomRevenueWithoutVATTurnover
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus IS NULL
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus.IsGuaranteed
	|							THEN RoomSalesForecast.RoomRevenueWithoutVATTurnover
	|						ELSE 0
	|					END,
	|					CASE
	|						WHEN RoomSalesForecast.ParentDoc = UNDEFINED
	|							THEN 0
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ReservationStatus IS NULL
	|								AND RoomSalesForecast.ParentDoc.ReservationStatus.IsPreliminary
	|							THEN 0
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus IS NULL
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus.IsGuaranteed
	|							THEN 0
	|						ELSE ISNULL(RoomSalesForecast.ParentDoc.NumberOfAdults, 0)
	|					END,
	|					CASE
	|						WHEN RoomSalesForecast.ParentDoc = UNDEFINED
	|							THEN 0
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ReservationStatus IS NULL
	|								AND RoomSalesForecast.ParentDoc.ReservationStatus.IsPreliminary
	|							THEN 0
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus IS NULL
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus.IsGuaranteed
	|							THEN 0
	|						ELSE ISNULL(RoomSalesForecast.ParentDoc.NumberOfTeenagers, 0) + ISNULL(RoomSalesForecast.ParentDoc.NumberOfChildren, 0) + ISNULL(RoomSalesForecast.ParentDoc.NumberOfInfants, 0)
	|					END,
	|					CASE
	|						WHEN RoomSalesForecast.ParentDoc = UNDEFINED
	|							THEN 0
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ReservationStatus IS NULL
	|								AND RoomSalesForecast.ParentDoc.ReservationStatus.IsPreliminary
	|							THEN 0
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus IS NULL
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus.IsGuaranteed
	|							THEN 0
	|						ELSE ISNULL(RoomSalesForecast.ParentDoc.NumberOfAdults, 0) + ISNULL(RoomSalesForecast.ParentDoc.NumberOfTeenagers, 0) + ISNULL(RoomSalesForecast.ParentDoc.NumberOfChildren, 0) + ISNULL(RoomSalesForecast.ParentDoc.NumberOfInfants, 0)
	|					END,
	|					CASE
	|						WHEN RoomSalesForecast.ParentDoc = UNDEFINED
	|							THEN 0
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ReservationStatus IS NULL
	|								AND RoomSalesForecast.ParentDoc.ReservationStatus.IsPreliminary
	|							THEN ISNULL(RoomSalesForecast.ParentDoc.NumberOfAdults, 0)
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus IS NULL
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus.IsGuaranteed
	|							THEN ISNULL(RoomSalesForecast.ParentDoc.NumberOfAdults, 0)
	|						ELSE 0
	|					END,
	|					CASE
	|						WHEN RoomSalesForecast.ParentDoc = UNDEFINED
	|							THEN 0
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ReservationStatus IS NULL
	|								AND RoomSalesForecast.ParentDoc.ReservationStatus.IsPreliminary
	|							THEN ISNULL(RoomSalesForecast.ParentDoc.NumberOfTeenagers, 0) + ISNULL(RoomSalesForecast.ParentDoc.NumberOfChildren, 0) + ISNULL(RoomSalesForecast.ParentDoc.NumberOfInfants, 0)
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus IS NULL
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus.IsGuaranteed
	|							THEN ISNULL(RoomSalesForecast.ParentDoc.NumberOfTeenagers, 0) + ISNULL(RoomSalesForecast.ParentDoc.NumberOfChildren, 0) + ISNULL(RoomSalesForecast.ParentDoc.NumberOfInfants, 0)
	|						ELSE 0
	|					END,
	|					CASE
	|						WHEN RoomSalesForecast.ParentDoc = UNDEFINED
	|							THEN 0
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ReservationStatus IS NULL
	|								AND RoomSalesForecast.ParentDoc.ReservationStatus.IsPreliminary
	|							THEN ISNULL(RoomSalesForecast.ParentDoc.NumberOfAdults, 0) + ISNULL(RoomSalesForecast.ParentDoc.NumberOfTeenagers, 0) + ISNULL(RoomSalesForecast.ParentDoc.NumberOfChildren, 0) + ISNULL(RoomSalesForecast.ParentDoc.NumberOfInfants, 0)
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus IS NULL
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus.IsGuaranteed
	|							THEN ISNULL(RoomSalesForecast.ParentDoc.NumberOfAdults, 0) + ISNULL(RoomSalesForecast.ParentDoc.NumberOfTeenagers, 0) + ISNULL(RoomSalesForecast.ParentDoc.NumberOfChildren, 0) + ISNULL(RoomSalesForecast.ParentDoc.NumberOfInfants, 0)
	|						ELSE 0
	|					END,
	|					CASE
	|						WHEN RoomSalesForecast.ParentDoc = UNDEFINED
	|							THEN 0
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ReservationStatus IS NULL
	|								AND RoomSalesForecast.ParentDoc.ReservationStatus.IsPreliminary
	|							THEN 0
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus IS NULL
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus.IsGuaranteed
	|							THEN 0
	|						ELSE ISNULL(RoomSalesForecast.ParentDoc.NumberOfTeenagers, 0)
	|					END,
	|					CASE
	|						WHEN RoomSalesForecast.ParentDoc = UNDEFINED
	|							THEN 0
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ReservationStatus IS NULL
	|								AND RoomSalesForecast.ParentDoc.ReservationStatus.IsPreliminary
	|							THEN 0
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus IS NULL
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus.IsGuaranteed
	|							THEN 0
	|						ELSE ISNULL(RoomSalesForecast.ParentDoc.NumberOfChildren, 0)
	|					END,
	|					CASE
	|						WHEN RoomSalesForecast.ParentDoc = UNDEFINED
	|							THEN 0
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ReservationStatus IS NULL
	|								AND RoomSalesForecast.ParentDoc.ReservationStatus.IsPreliminary
	|							THEN 0
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus IS NULL
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus.IsGuaranteed
	|							THEN 0
	|						ELSE ISNULL(RoomSalesForecast.ParentDoc.NumberOfInfants, 0)
	|					END,
	|					CASE
	|						WHEN RoomSalesForecast.ParentDoc = UNDEFINED
	|							THEN 0
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ReservationStatus IS NULL
	|								AND RoomSalesForecast.ParentDoc.ReservationStatus.IsPreliminary
	|							THEN ISNULL(RoomSalesForecast.ParentDoc.NumberOfTeenagers, 0)
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus IS NULL
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus.IsGuaranteed
	|							THEN ISNULL(RoomSalesForecast.ParentDoc.NumberOfTeenagers, 0)
	|						ELSE 0
	|					END,
	|					CASE
	|						WHEN RoomSalesForecast.ParentDoc = UNDEFINED
	|							THEN 0
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ReservationStatus IS NULL
	|								AND RoomSalesForecast.ParentDoc.ReservationStatus.IsPreliminary
	|							THEN ISNULL(RoomSalesForecast.ParentDoc.NumberOfChildren, 0)
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus IS NULL
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus.IsGuaranteed
	|							THEN ISNULL(RoomSalesForecast.ParentDoc.NumberOfChildren, 0)
	|						ELSE 0
	|					END,
	|					CASE
	|						WHEN RoomSalesForecast.ParentDoc = UNDEFINED
	|							THEN 0
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ReservationStatus IS NULL
	|								AND RoomSalesForecast.ParentDoc.ReservationStatus.IsPreliminary
	|							THEN ISNULL(RoomSalesForecast.ParentDoc.NumberOfInfants, 0)
	|						WHEN RoomSalesForecast.ParentDoc <> UNDEFINED
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus IS NULL
	|								AND NOT RoomSalesForecast.ParentDoc.ResourceReservationStatus.IsGuaranteed
	|							THEN ISNULL(RoomSalesForecast.ParentDoc.NumberOfInfants, 0)
	|						ELSE 0
	|					END
	|				FROM
	|					AccumulationRegister.SalesForecast.Turnovers(
	|							&qForecastPeriodFrom,
	|							&qPeriodTo,
	|							Day,
	|							Hotel IN HIERARCHY (&qHotel)
	|								AND (Room IN HIERARCHY (&qRoom)
	|									OR &qIsEmptyRoom)
	|								AND (RoomType IN HIERARCHY (&qRoomType)
	|									OR &qIsEmptyRoomType)
	|								AND (Service IN HIERARCHY (&qService)
	|									OR &qIsEmptyService)
	|								AND (Service IN (&qServicesList)
	|									OR NOT &qUseServicesList)) AS RoomSalesForecast) AS RoomPlanFactSales
	|			
	|			GROUP BY
	|				RoomPlanFactSales.Period,
	|				RoomPlanFactSales.RoomType) AS RoomSalesTurnovers
	|			ON RoomInventory.RoomType = RoomSalesTurnovers.RoomType
	|				AND RoomInventory.Period = RoomSalesTurnovers.Period) AS OccupancyForecast
	|WHERE
	|	(&qShowSales
	|			OR NOT &qShowSales
	|				AND OccupancyForecast.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef))
	|{WHERE
	|	OccupancyForecast.RoomType.*,
	|	OccupancyForecast.AccountingDate}
	|
	|ORDER BY
	|	AccountingDate,
	|	OccupancyForecast.RoomType.SortCode
	|{ORDER BY
	|	RoomType.*,
	|	AccountingDate,
	|	(BEGINOFPERIOD(OccupancyForecast.AccountingDate, WEEK)) AS AccountingWeek,
	|	(BEGINOFPERIOD(OccupancyForecast.AccountingDate, MONTH)) AS AccountingMonth,
	|	(BEGINOFPERIOD(OccupancyForecast.AccountingDate, QUARTER)) AS AccountingQuarter,
	|	(YEAR(OccupancyForecast.AccountingDate)) AS AccountingYear}
	|TOTALS
	|	SUM(TotalRooms),
	|	SUM(TotalBeds),
	|	SUM(RoomsAvailable),
	|	SUM(BedsAvailable),
	|	SUM(OccupiedRooms),
	|	SUM(OccupiedBeds),
	|	SUM(OccupiedGuests),
	|	SUM(OccupiedRoomsAtMorning),
	|	SUM(OccupiedBedsAtMorning),
	|	CASE
	|		WHEN RoomType IN (&qRoomTypesList)
	|			THEN SUM(OccupiedRooms) + CASE
	|					WHEN SUM(RoomsRemainsInQuota) >= 0
	|						THEN SUM(RoomsRemainsInQuota)
	|					ELSE 0
	|				END
	|		ELSE SUM(OccupiedRooms) + CASE
	|				WHEN SUM(RoomsInQuota) - SUM(RoomsOccupiedInQuota) < 0
	|					THEN 0
	|				ELSE SUM(RoomsInQuota) - SUM(RoomsOccupiedInQuota)
	|			END
	|	END AS UsedRooms,
	|	CASE
	|		WHEN RoomType IN (&qRoomTypesList)
	|			THEN SUM(OccupiedBeds) + CASE
	|					WHEN SUM(BedsRemainsInQuota) >= 0
	|						THEN SUM(BedsRemainsInQuota)
	|					ELSE 0
	|				END
	|		ELSE SUM(OccupiedBeds) + CASE
	|				WHEN SUM(BedsInQuota) - SUM(BedsOccupiedInQuota) < 0
	|					THEN 0
	|				ELSE SUM(BedsInQuota) - SUM(BedsOccupiedInQuota)
	|			END
	|	END AS UsedBeds,
	|	SUM(RoomsReserved),
	|	SUM(BedsReserved),
	|	SUM(GuaranteedRoomsReserved),
	|	SUM(GuaranteedBedsReserved),
	|	SUM(GuaranteedGuestsReserved),
	|	SUM(NonGuaranteedRoomsReserved),
	|	SUM(NonGuaranteedBedsReserved),
	|	SUM(NonGuaranteedGuestsReserved),
	|	SUM(NonGuaranteedRoomsReservedWithTentativeBusinessBlocks),
	|	SUM(NonGuaranteedBedsReservedWithTentativeBusinessBlocks),
	|	SUM(OccupiedRoomsWithBusinessBlocks),
	|	SUM(OccupiedBedsWithBusinessBlocks),
	|	SUM(InHouseRooms),
	|	SUM(InHouseBeds),
	|	SUM(InHouseGuests),
	|	SUM(GuaranteedAndInHouseRooms),
	|	SUM(GuaranteedAndInHouseBeds),
	|	SUM(GuaranteedAndInHouseGuests),
	|	SUM(GuaranteedAndInHouseRoomsWithDefiniteBusinessBlocks),
	|	SUM(GuaranteedAndInHouseBedsWithDefiniteBusinessBlocks),
	|	SUM(RoomsInDefiniteBusinessBlocks),
	|	SUM(BedsInDefiniteBusinessBlocks),
	|	SUM(RoomsInTentativeBusinessBlocks),
	|	SUM(BedsInTentativeBusinessBlocks),
	|	SUM(RoomsCheckedOut),
	|	SUM(BedsCheckedOut),
	|	SUM(RoomsInQuota),
	|	SUM(BedsInQuota),
	|	CASE
	|		WHEN RoomType IN (&qRoomTypesList)
	|			THEN SUM(RoomsRemainsInQuota)
	|		ELSE SUM(RoomsInQuota) - SUM(RoomsOccupiedInQuota)
	|	END AS RoomsRemainsInQuota,
	|	CASE
	|		WHEN RoomType IN (&qRoomTypesList)
	|			THEN SUM(BedsRemainsInQuota)
	|		ELSE SUM(BedsInQuota) - SUM(BedsOccupiedInQuota)
	|	END AS BedsRemainsInQuota,
	|	CASE
	|		WHEN RoomType IN (&qRoomTypesList)
	|			THEN SUM(OccupiedRooms) + CASE
	|					WHEN SUM(CommitmentRoomsRemains) >= 0
	|						THEN SUM(CommitmentRoomsRemains)
	|					ELSE 0
	|				END
	|		ELSE SUM(OccupiedRooms) + CASE
	|				WHEN SUM(CommitmentRoomsInQuota) - SUM(CommitmentRoomsOccupied) < 0
	|					THEN 0
	|				ELSE SUM(CommitmentRoomsInQuota) - SUM(CommitmentRoomsOccupied)
	|			END
	|	END AS RoomsSold,
	|	CASE
	|		WHEN RoomType IN (&qRoomTypesList)
	|			THEN SUM(OccupiedBeds) + CASE
	|					WHEN SUM(CommitmentBedsRemains) >= 0
	|						THEN SUM(CommitmentBedsRemains)
	|					ELSE 0
	|				END
	|		ELSE SUM(OccupiedBeds) + CASE
	|				WHEN SUM(CommitmentBedsInQuota) - SUM(CommitmentBedsOccupied) < 0
	|					THEN 0
	|				ELSE SUM(CommitmentBedsInQuota) - SUM(CommitmentBedsOccupied)
	|			END
	|	END AS BedsSold,
	|	CASE
	|		WHEN RoomType IN (&qRoomTypesList)
	|			THEN SUM(OccupiedRoomsAtMorning) + CASE
	|					WHEN SUM(CommitmentRoomsRemainsAtMorning) >= 0
	|						THEN SUM(CommitmentRoomsRemainsAtMorning)
	|					ELSE 0
	|				END
	|		ELSE SUM(OccupiedRoomsAtMorning) + CASE
	|				WHEN SUM(CommitmentRoomsInQuotaAtMorning) - SUM(CommitmentRoomsOccupiedAtMorning) < 0
	|					THEN 0
	|				ELSE SUM(CommitmentRoomsInQuotaAtMorning) - SUM(CommitmentRoomsOccupiedAtMorning)
	|			END
	|	END AS RoomsSoldAtMorning,
	|	CASE
	|		WHEN RoomType IN (&qRoomTypesList)
	|			THEN SUM(OccupiedBedsAtMorning) + CASE
	|					WHEN SUM(CommitmentBedsRemainsAtMorning) >= 0
	|						THEN SUM(CommitmentBedsRemainsAtMorning)
	|					ELSE 0
	|				END
	|		ELSE SUM(OccupiedBedsAtMorning) + CASE
	|				WHEN SUM(CommitmentBedsInQuotaAtMorning) - SUM(CommitmentBedsOccupiedAtMorning) < 0
	|					THEN 0
	|				ELSE SUM(CommitmentBedsInQuotaAtMorning) - SUM(CommitmentBedsOccupiedAtMorning)
	|			END
	|	END AS BedsSoldAtMorning,
	|	CASE
	|		WHEN SUM(RoomsAvailable) = 0
	|			THEN 0
	|		ELSE SUM(GuaranteedRoomsRented) * 100 / SUM(RoomsAvailable)
	|	END AS GuaranteedRoomsRentedPercent,
	|	CASE
	|		WHEN SUM(BedsAvailable) = 0
	|			THEN 0
	|		ELSE SUM(GuaranteedBedsRented) * 100 / SUM(BedsAvailable)
	|	END AS GuaranteedBedsRentedPercent,
	|	CASE
	|		WHEN SUM(RoomsAvailable) = 0
	|			THEN 0
	|		ELSE SUM(NonGuaranteedRoomsRented) * 100 / SUM(RoomsAvailable)
	|	END AS NonGuaranteedRoomsRentedPercent,
	|	CASE
	|		WHEN SUM(BedsAvailable) = 0
	|			THEN 0
	|		ELSE SUM(NonGuaranteedBedsRented) * 100 / SUM(BedsAvailable)
	|	END AS NonGuaranteedBedsRentedPercent,
	|	CASE
	|		WHEN SUM(RoomsAvailable) = 0
	|			THEN 0
	|		ELSE SUM(RoomsRented) * 100 / SUM(RoomsAvailable)
	|	END AS RoomsRentedPercent,
	|	CASE
	|		WHEN SUM(BedsAvailable) = 0
	|			THEN 0
	|		ELSE SUM(BedsRented) * 100 / SUM(BedsAvailable)
	|	END AS BedsRentedPercent,
	|	CASE
	|		WHEN SUM(TotalRooms) = 0
	|			THEN 0
	|		ELSE SUM(RoomsRented) * 100 / SUM(TotalRooms)
	|	END AS RoomsRentedPercentWithoutBlocks,
	|	CASE
	|		WHEN SUM(TotalBeds) = 0
	|			THEN 0
	|		ELSE SUM(BedsRented) * 100 / SUM(TotalBeds)
	|	END AS BedsRentedPercentWithoutBlocks,
	|	CASE
	|		WHEN RoomType IN (&qRoomTypesList)
	|			THEN CASE
	|					WHEN SUM(RoomsAvailable) = 0
	|						THEN 0
	|					ELSE (SUM(OccupiedRoomsWithBusinessBlocks) + CASE
	|							WHEN SUM(CommitmentRoomsRemains) >= 0
	|								THEN SUM(CommitmentRoomsRemains)
	|							ELSE 0
	|						END) * 100 / SUM(RoomsAvailable)
	|				END
	|		ELSE CASE
	|				WHEN SUM(RoomsAvailable) = 0
	|					THEN 0
	|				ELSE (SUM(OccupiedRoomsWithBusinessBlocks) + CASE
	|						WHEN SUM(CommitmentRoomsInQuota) - SUM(CommitmentRoomsOccupied) < 0
	|							THEN 0
	|						ELSE SUM(CommitmentRoomsInQuota) - SUM(CommitmentRoomsOccupied)
	|					END) * 100 / SUM(RoomsAvailable)
	|			END
	|	END AS RoomsOccupancyPercent,
	|	CASE
	|		WHEN RoomType IN (&qRoomTypesList)
	|			THEN CASE
	|					WHEN SUM(BedsAvailable) = 0
	|						THEN 0
	|					ELSE (SUM(OccupiedBedsWithBusinessBlocks) + CASE
	|							WHEN SUM(CommitmentBedsRemains) >= 0
	|								THEN SUM(CommitmentBedsRemains)
	|							ELSE 0
	|						END) * 100 / SUM(BedsAvailable)
	|				END
	|		ELSE CASE
	|				WHEN SUM(BedsAvailable) = 0
	|					THEN 0
	|				ELSE (SUM(OccupiedBedsWithBusinessBlocks) + CASE
	|						WHEN SUM(CommitmentBedsInQuota) - SUM(CommitmentBedsOccupied) < 0
	|							THEN 0
	|						ELSE SUM(CommitmentBedsInQuota) - SUM(CommitmentBedsOccupied)
	|					END) * 100 / SUM(BedsAvailable)
	|			END
	|	END AS BedsOccupancyPercent,
	|	CASE
	|		WHEN RoomType IN (&qRoomTypesList)
	|			THEN CASE
	|					WHEN SUM(RoomsAvailable) = 0
	|						THEN 0
	|					ELSE (SUM(GuaranteedAndInHouseRoomsWithDefiniteBusinessBlocks) + CASE
	|							WHEN SUM(CommitmentRoomsRemains) >= 0
	|								THEN SUM(CommitmentRoomsRemains)
	|							ELSE 0
	|						END) * 100 / SUM(RoomsAvailable)
	|				END
	|		ELSE CASE
	|				WHEN SUM(RoomsAvailable) = 0
	|					THEN 0
	|				ELSE (SUM(GuaranteedAndInHouseRoomsWithDefiniteBusinessBlocks) + CASE
	|						WHEN SUM(CommitmentRoomsInQuota) - SUM(CommitmentRoomsOccupied) < 0
	|							THEN 0
	|						ELSE SUM(CommitmentRoomsInQuota) - SUM(CommitmentRoomsOccupied)
	|					END) * 100 / SUM(RoomsAvailable)
	|			END
	|	END AS GuaranteedRoomsOccupancyPercent,
	|	CASE
	|		WHEN RoomType IN (&qRoomTypesList)
	|			THEN CASE
	|					WHEN SUM(BedsAvailable) = 0
	|						THEN 0
	|					ELSE (SUM(GuaranteedAndInHouseBedsWithDefiniteBusinessBlocks) + CASE
	|							WHEN SUM(CommitmentBedsRemains) >= 0
	|								THEN SUM(CommitmentBedsRemains)
	|							ELSE 0
	|						END) * 100 / SUM(BedsAvailable)
	|				END
	|		ELSE CASE
	|				WHEN SUM(BedsAvailable) = 0
	|					THEN 0
	|				ELSE (SUM(GuaranteedAndInHouseBedsWithDefiniteBusinessBlocks) + CASE
	|						WHEN SUM(CommitmentBedsInQuota) - SUM(CommitmentBedsOccupied) < 0
	|							THEN 0
	|						ELSE SUM(CommitmentBedsInQuota) - SUM(CommitmentBedsOccupied)
	|					END) * 100 / SUM(BedsAvailable)
	|			END
	|	END AS GuaranteedBedsOccupancyPercent,
	|	CASE
	|		WHEN SUM(RoomsAvailable) = 0
	|			THEN 0
	|		ELSE SUM(NonGuaranteedRoomsReservedWithTentativeBusinessBlocks) * 100 / SUM(RoomsAvailable)
	|	END AS NonGuaranteedRoomsOccupancyPercent,
	|	CASE
	|		WHEN SUM(BedsAvailable) = 0
	|			THEN 0
	|		ELSE SUM(NonGuaranteedBedsReservedWithTentativeBusinessBlocks) * 100 / SUM(BedsAvailable)
	|	END AS NonGuaranteedBedsOccupancyPercent,
	|	CASE
	|		WHEN RoomType IN (&qRoomTypesList)
	|			THEN CASE
	|					WHEN SUM(TotalRooms) = 0
	|						THEN 0
	|					ELSE (SUM(OccupiedRoomsWithBusinessBlocks) + CASE
	|							WHEN SUM(CommitmentRoomsRemains) >= 0
	|								THEN SUM(CommitmentRoomsRemains)
	|							ELSE 0
	|						END) * 100 / SUM(TotalRooms)
	|				END
	|		ELSE CASE
	|				WHEN SUM(TotalRooms) = 0
	|					THEN 0
	|				ELSE (SUM(OccupiedRoomsWithBusinessBlocks) + CASE
	|						WHEN SUM(CommitmentRoomsInQuota) - SUM(CommitmentRoomsOccupied) < 0
	|							THEN 0
	|						ELSE SUM(CommitmentRoomsInQuota) - SUM(CommitmentRoomsOccupied)
	|					END) * 100 / SUM(TotalRooms)
	|			END
	|	END AS RoomsUsedPercent,
	|	CASE
	|		WHEN RoomType IN (&qRoomTypesList)
	|			THEN CASE
	|					WHEN SUM(TotalBeds) = 0
	|						THEN 0
	|					ELSE (SUM(OccupiedBedsWithBusinessBlocks) + CASE
	|							WHEN SUM(CommitmentBedsRemains) >= 0
	|								THEN SUM(CommitmentBedsRemains)
	|							ELSE 0
	|						END) * 100 / SUM(TotalBeds)
	|				END
	|		ELSE CASE
	|				WHEN SUM(TotalBeds) = 0
	|					THEN 0
	|				ELSE (SUM(OccupiedBedsWithBusinessBlocks) + CASE
	|						WHEN SUM(CommitmentBedsInQuota) - SUM(CommitmentBedsOccupied) < 0
	|							THEN 0
	|						ELSE SUM(CommitmentBedsInQuota) - SUM(CommitmentBedsOccupied)
	|					END) * 100 / SUM(TotalBeds)
	|			END
	|	END AS BedsUsedPercent,
	|	CASE
	|		WHEN RoomType IN (&qRoomTypesList)
	|			THEN CASE
	|					WHEN SUM(TotalRooms) = 0
	|						THEN 0
	|					ELSE (SUM(GuaranteedAndInHouseRoomsWithDefiniteBusinessBlocks) + CASE
	|							WHEN SUM(CommitmentRoomsRemains) >= 0
	|								THEN SUM(CommitmentRoomsRemains)
	|							ELSE 0
	|						END) * 100 / SUM(TotalRooms)
	|				END
	|		ELSE CASE
	|				WHEN SUM(TotalRooms) = 0
	|					THEN 0
	|				ELSE (SUM(GuaranteedAndInHouseRoomsWithDefiniteBusinessBlocks) + CASE
	|						WHEN SUM(CommitmentRoomsInQuota) - SUM(CommitmentRoomsOccupied) < 0
	|							THEN 0
	|						ELSE SUM(CommitmentRoomsInQuota) - SUM(CommitmentRoomsOccupied)
	|					END) * 100 / SUM(TotalRooms)
	|			END
	|	END AS GuaranteedRoomsUsedPercent,
	|	CASE
	|		WHEN RoomType IN (&qRoomTypesList)
	|			THEN CASE
	|					WHEN SUM(TotalBeds) = 0
	|						THEN 0
	|					ELSE (SUM(GuaranteedAndInHouseBedsWithDefiniteBusinessBlocks) + CASE
	|							WHEN SUM(CommitmentBedsRemains) >= 0
	|								THEN SUM(CommitmentBedsRemains)
	|							ELSE 0
	|						END) * 100 / SUM(TotalBeds)
	|				END
	|		ELSE CASE
	|				WHEN SUM(TotalBeds) = 0
	|					THEN 0
	|				ELSE (SUM(GuaranteedAndInHouseBedsWithDefiniteBusinessBlocks) + CASE
	|						WHEN SUM(CommitmentBedsInQuota) - SUM(CommitmentBedsOccupied) < 0
	|							THEN 0
	|						ELSE SUM(CommitmentBedsInQuota) - SUM(CommitmentBedsOccupied)
	|					END) * 100 / SUM(TotalBeds)
	|			END
	|	END AS GuaranteedBedsUsedPercent,
	|	CASE
	|		WHEN SUM(TotalRooms) = 0
	|			THEN 0
	|		ELSE SUM(NonGuaranteedRoomsReservedWithTentativeBusinessBlocks) * 100 / SUM(TotalRooms)
	|	END AS NonGuaranteedRoomsUsedPercent,
	|	CASE
	|		WHEN SUM(TotalBeds) = 0
	|			THEN 0
	|		ELSE SUM(NonGuaranteedBedsReservedWithTentativeBusinessBlocks) * 100 / SUM(TotalBeds)
	|	END AS NonGuaranteedBedsUsedPercent,
	|	SUM(RoomsBlocked),
	|	SUM(BedsBlocked),
	|	CASE
	|		WHEN RoomType IN (&qRoomTypesList)
	|			THEN SUM(RoomsAvailable) - SUM(OccupiedRooms) - CASE
	|					WHEN SUM(RoomsRemainsInQuota) >= 0
	|						THEN SUM(RoomsRemainsInQuota)
	|					ELSE 0
	|				END
	|		ELSE SUM(RoomsAvailable) - SUM(OccupiedRooms) - CASE
	|				WHEN SUM(RoomsInQuota) - SUM(RoomsOccupiedInQuota) < 0
	|					THEN 0
	|				ELSE SUM(RoomsInQuota) - SUM(RoomsOccupiedInQuota)
	|			END
	|	END AS RoomsVacant,
	|	CASE
	|		WHEN RoomType IN (&qRoomTypesList)
	|			THEN SUM(BedsAvailable) - SUM(OccupiedBeds) - CASE
	|					WHEN SUM(BedsRemainsInQuota) >= 0
	|						THEN SUM(BedsRemainsInQuota)
	|					ELSE 0
	|				END
	|		ELSE SUM(BedsAvailable) - SUM(OccupiedBeds) - CASE
	|				WHEN SUM(BedsInQuota) - SUM(BedsOccupiedInQuota) < 0
	|					THEN 0
	|				ELSE SUM(BedsInQuota) - SUM(BedsOccupiedInQuota)
	|			END
	|	END AS BedsVacant,
	|	SUM(NotCommitmentRoomsInQuota),
	|	SUM(NotCommitmentBedsInQuota),
	|	SUM(NotCommitmentRoomsReserved),
	|	SUM(NotCommitmentBedsReserved),
	|	SUM(NotCommitmentRoomsInHouse),
	|	SUM(NotCommitmentBedsInHouse),
	|	SUM(NotCommitmentRoomsOccupied),
	|	SUM(NotCommitmentBedsOccupied),
	|	CASE
	|		WHEN RoomType IN (&qRoomTypesList)
	|			THEN SUM(NotCommitmentRoomsRemains)
	|		ELSE SUM(NotCommitmentRoomsInQuota) - SUM(NotCommitmentRoomsOccupied)
	|	END AS NotCommitmentRoomsRemains,
	|	CASE
	|		WHEN RoomType IN (&qRoomTypesList)
	|			THEN SUM(NotCommitmentBedsRemains)
	|		ELSE SUM(NotCommitmentBedsInQuota) - SUM(NotCommitmentBedsOccupied)
	|	END AS NotCommitmentBedsRemains,
	|	SUM(CommitmentRoomsInQuota),
	|	SUM(CommitmentBedsInQuota),
	|	SUM(CommitmentRoomsInQuotaAtMorning),
	|	SUM(CommitmentBedsInQuotaAtMorning),
	|	SUM(CommitmentRoomsReserved),
	|	SUM(CommitmentBedsReserved),
	|	SUM(CommitmentRoomsReservedAtMorning),
	|	SUM(CommitmentBedsReservedAtMorning),
	|	SUM(CommitmentRoomsInHouse),
	|	SUM(CommitmentBedsInHouse),
	|	SUM(CommitmentRoomsInHouseAtMorning),
	|	SUM(CommitmentBedsInHouseAtMorning),
	|	SUM(CommitmentRoomsOccupied),
	|	SUM(CommitmentBedsOccupied),
	|	SUM(CommitmentRoomsOccupiedAtMorning),
	|	SUM(CommitmentBedsOccupiedAtMorning),
	|	CASE
	|		WHEN RoomType IN (&qRoomTypesList)
	|			THEN SUM(CommitmentRoomsRemains)
	|		ELSE SUM(CommitmentRoomsInQuota) - SUM(CommitmentRoomsOccupied)
	|	END AS CommitmentRoomsRemains,
	|	CASE
	|		WHEN RoomType IN (&qRoomTypesList)
	|			THEN SUM(CommitmentBedsRemains)
	|		ELSE SUM(CommitmentBedsInQuota) - SUM(CommitmentBedsOccupied)
	|	END AS CommitmentBedsRemains,
	|	CASE
	|		WHEN SUM(CommitmentRoomsInQuota) = 0
	|			THEN 0
	|		ELSE SUM(CommitmentRoomsOccupied) * 100 / SUM(CommitmentRoomsInQuota)
	|	END AS CommitmentRoomsUsagePercent,
	|	CASE
	|		WHEN SUM(CommitmentBedsInQuota) = 0
	|			THEN 0
	|		ELSE SUM(CommitmentBedsOccupied) * 100 / SUM(CommitmentBedsInQuota)
	|	END AS CommitmentBedsUsagePercent,
	|	CASE
	|		WHEN SUM(CommitmentRoomsInQuota) = 0
	|			THEN 0
	|		ELSE 100 - SUM(CommitmentRoomsOccupied) * 100 / SUM(CommitmentRoomsInQuota)
	|	END AS CommitmentRoomsRemainsPercent,
	|	CASE
	|		WHEN SUM(CommitmentBedsInQuota) = 0
	|			THEN 0
	|		ELSE 100 - SUM(CommitmentBedsOccupied) * 100 / SUM(CommitmentBedsInQuota)
	|	END AS CommitmentBedsRemainsPercent,
	|	SUM(RoomsVacantWithAllotments),
	|	SUM(BedsVacantWithAllotments),
	|	CASE
	|		WHEN RoomType IN (&qRoomTypesList)
	|			THEN SUM(RoomsAvailable) - SUM(OccupiedRooms) - SUM(CASE
	|						WHEN CommitmentRoomsRemains < 0
	|							THEN 0
	|						ELSE CommitmentRoomsRemains
	|					END)
	|		ELSE SUM(RoomsAvailable) - SUM(OccupiedRooms) - CASE
	|				WHEN SUM(CommitmentRoomsInQuota) - SUM(CommitmentRoomsOccupied) < 0
	|					THEN 0
	|				ELSE SUM(CommitmentRoomsInQuota) - SUM(CommitmentRoomsOccupied)
	|			END
	|	END AS RoomsVacantWithoutCommitment,
	|	CASE
	|		WHEN RoomType IN (&qRoomTypesList)
	|			THEN SUM(BedsAvailable) - SUM(OccupiedBeds) - SUM(CASE
	|						WHEN CommitmentBedsRemains < 0
	|							THEN 0
	|						ELSE CommitmentBedsRemains
	|					END)
	|		ELSE SUM(BedsAvailable) - SUM(OccupiedBeds) - CASE
	|				WHEN SUM(CommitmentBedsInQuota) - SUM(CommitmentBedsOccupied) < 0
	|					THEN 0
	|				ELSE SUM(CommitmentBedsInQuota) - SUM(CommitmentBedsOccupied)
	|			END
	|	END AS BedsVacantWithoutCommitment,
	|	CASE
	|		WHEN RoomType IN (&qRoomTypesList)
	|			THEN SUM(CommitmentRoomsRemainsAtMorning)
	|		ELSE SUM(CommitmentRoomsInQuotaAtMorning) - SUM(CommitmentRoomsOccupiedAtMorning)
	|	END AS CommitmentRoomsRemainsAtMorning,
	|	CASE
	|		WHEN RoomType IN (&qRoomTypesList)
	|			THEN SUM(CommitmentBedsRemainsAtMorning)
	|		ELSE SUM(CommitmentBedsInQuotaAtMorning) - SUM(CommitmentBedsOccupiedAtMorning)
	|	END AS CommitmentBedsRemainsAtMorning,
	|	SUM(RoomsCheckedIn),
	|	SUM(BedsCheckedIn),
	|	SUM(GuestsCheckedIn),
	|	SUM(ExpectedRoomsCheckedIn),
	|	SUM(ExpectedBedsCheckedIn),
	|	SUM(ExpectedGuestsCheckedIn),
	|	SUM(GuaranteedExpectedRoomsCheckedIn),
	|	SUM(GuaranteedExpectedBedsCheckedIn),
	|	SUM(GuaranteedExpectedGuestsCheckedIn),
	|	SUM(NonGuaranteedExpectedRoomsCheckedIn),
	|	SUM(NonGuaranteedExpectedBedsCheckedIn),
	|	SUM(NonGuaranteedExpectedGuestsCheckedIn),
	|	SUM(ExpectedRoomsCheckedOut),
	|	SUM(ExpectedBedsCheckedOut),
	|	SUM(ExpectedGuestsCheckedOut),
	|	SUM(GuestsReserved),
	|	SUM(GuestsCheckedOut),
	|	SUM(TotalGuests),
	|	SUM(TotalGuestsAtMorning),
	|	CASE
	|		WHEN SUM(RoomsAvailable) = 0
	|			THEN 0
	|		ELSE SUM(RoomRevenue) / SUM(RoomsAvailable)
	|	END AS RevPAR,
	|	CASE
	|		WHEN SUM(BedsAvailable) = 0
	|			THEN 0
	|		ELSE SUM(RoomRevenue) / SUM(BedsAvailable)
	|	END AS RevPAB,
	|	CASE
	|		WHEN SUM(RoomsAvailable) = 0
	|			THEN 0
	|		ELSE SUM(RoomRevenueWithoutVAT) / SUM(RoomsAvailable)
	|	END AS RevPARWithoutVAT,
	|	CASE
	|		WHEN SUM(BedsAvailable) = 0
	|			THEN 0
	|		ELSE SUM(RoomRevenueWithoutVAT) / SUM(BedsAvailable)
	|	END AS RevPABWithoutVAT,
	|	CASE
	|		WHEN SUM(RoomsRented) = 0
	|			THEN 0
	|		ELSE SUM(RoomRevenue) / SUM(RoomsRented)
	|	END AS AvgRoomPrice,
	|	CASE
	|		WHEN SUM(BedsRented) = 0
	|			THEN 0
	|		ELSE SUM(RoomRevenue) / SUM(BedsRented)
	|	END AS AvgBedPrice,
	|	CASE
	|		WHEN SUM(RoomsRented) = 0
	|			THEN 0
	|		ELSE SUM(RoomRevenueWithoutVAT) / SUM(RoomsRented)
	|	END AS AvgRoomPriceWithoutVAT,
	|	CASE
	|		WHEN SUM(BedsRented) = 0
	|			THEN 0
	|		ELSE SUM(RoomRevenueWithoutVAT) / SUM(BedsRented)
	|	END AS AvgBedPriceWithoutVAT,
	|	CASE
	|		WHEN SUM(GuaranteedRoomsRented) = 0
	|			THEN 0
	|		ELSE SUM(GuaranteedRoomRevenue) / SUM(GuaranteedRoomsRented)
	|	END AS GuaranteedAvgRoomPrice,
	|	CASE
	|		WHEN SUM(GuaranteedBedsRented) = 0
	|			THEN 0
	|		ELSE SUM(GuaranteedRoomRevenue) / SUM(GuaranteedBedsRented)
	|	END AS GuaranteedAvgBedPrice,
	|	CASE
	|		WHEN SUM(NonGuaranteedRoomsRented) = 0
	|			THEN 0
	|		ELSE SUM(NonGuaranteedRoomRevenue) / SUM(NonGuaranteedRoomsRented)
	|	END AS NonGuaranteedAvgRoomPrice,
	|	CASE
	|		WHEN SUM(NonGuaranteedBedsRented) = 0
	|			THEN 0
	|		ELSE SUM(NonGuaranteedRoomRevenue) / SUM(NonGuaranteedBedsRented)
	|	END AS NonGuaranteedAvgBedPrice,
	|	CASE
	|		WHEN SUM(GuaranteedRoomsRented) = 0
	|			THEN 0
	|		ELSE SUM(GuaranteedRoomRevenueWithoutVAT) / SUM(GuaranteedRoomsRented)
	|	END AS GuaranteedAvgRoomPriceWithoutVAT,
	|	CASE
	|		WHEN SUM(GuaranteedBedsRented) = 0
	|			THEN 0
	|		ELSE SUM(GuaranteedRoomRevenueWithoutVAT) / SUM(GuaranteedBedsRented)
	|	END AS GuaranteedAvgBedPriceWithoutVAT,
	|	CASE
	|		WHEN SUM(NonGuaranteedRoomsRented) = 0
	|			THEN 0
	|		ELSE SUM(NonGuaranteedRoomRevenueWithoutVAT) / SUM(NonGuaranteedRoomsRented)
	|	END AS NonGuaranteedAvgRoomPriceWithoutVAT,
	|	CASE
	|		WHEN SUM(NonGuaranteedBedsRented) = 0
	|			THEN 0
	|		ELSE SUM(NonGuaranteedRoomRevenueWithoutVAT) / SUM(NonGuaranteedBedsRented)
	|	END AS NonGuaranteedAvgBedPriceWithoutVAT,
	|	CASE
	|		WHEN SUM(RoomsRented) = 0
	|			THEN 0
	|		ELSE SUM(Sales) / SUM(RoomsRented)
	|	END AS AvgDailyRoomRate,
	|	CASE
	|		WHEN SUM(BedsRented) = 0
	|			THEN 0
	|		ELSE SUM(Sales) / SUM(BedsRented)
	|	END AS AvgDailyBedRate,
	|	CASE
	|		WHEN SUM(RoomsRented) = 0
	|			THEN 0
	|		ELSE SUM(SalesWithoutVAT) / SUM(RoomsRented)
	|	END AS AvgDailyRoomRateWithoutVAT,
	|	CASE
	|		WHEN SUM(BedsRented) = 0
	|			THEN 0
	|		ELSE SUM(SalesWithoutVAT) / SUM(BedsRented)
	|	END AS AvgDailyBedRateWithoutVAT,
	|	SUM(GuaranteedRoomsRented),
	|	SUM(GuaranteedBedsRented),
	|	SUM(NonGuaranteedRoomsRented),
	|	SUM(NonGuaranteedBedsRented),
	|	SUM(RoomsRented),
	|	SUM(BedsRented),
	|	SUM(Sales),
	|	SUM(RoomRevenue),
	|	SUM(SalesWithoutVAT),
	|	SUM(RoomRevenueWithoutVAT),
	|	SUM(GuaranteedSales),
	|	SUM(GuaranteedRoomRevenue),
	|	SUM(GuaranteedSalesWithoutVAT),
	|	SUM(GuaranteedRoomRevenueWithoutVAT),
	|	SUM(NonGuaranteedSales),
	|	SUM(NonGuaranteedRoomRevenue),
	|	SUM(NonGuaranteedSalesWithoutVAT),
	|	SUM(NonGuaranteedRoomRevenueWithoutVAT),
	|	SUM(DefinitiveSales),
	|	SUM(DefinitiveRoomRevenue),
	|	SUM(DefinitiveSalesWithoutVAT),
	|	SUM(DefinitiveRoomRevenueWithoutVAT),
	|	SUM(TentativeSales),
	|	SUM(TentativeRoomRevenue),
	|	SUM(TentativeSalesWithoutVAT),
	|	SUM(TentativeRoomRevenueWithoutVAT),
	|	SUM(TentativeRooms),
	|	SUM(TentativeBeds),
	|	SUM(TentativeAdditionalBeds),
	|	SUM(DefinitiveAdults),
	|	SUM(DefinitiveChildren),
	|	SUM(DefinitiveGuests),
	|	SUM(TentativeAdults),
	|	SUM(TentativeChildren),
	|	SUM(TentativeGuests),
	|	SUM(ForecastSales),
	|	SUM(ForecastRoomRevenue),
	|	SUM(ForecastSalesWithoutVAT),
	|	SUM(ForecastRoomRevenueWithoutVAT),
	|	SUM(InHouseSales),
	|	SUM(InHouseRoomRevenue),
	|	SUM(InHouseSalesWithoutVAT),
	|	SUM(InHouseRoomRevenueWithoutVAT),
	|	SUM(CommissionSum),
	|	SUM(CommissionSumWithoutVAT),
	|	SUM(ForecastCommissionSum),
	|	SUM(ForecastCommissionSumWithoutVAT),
	|	SUM(InHouseCommissionSum),
	|	SUM(InHouseCommissionSumWithoutVAT),
	|	SUM(DiscountSum),
	|	SUM(DiscountSumWithoutVAT),
	|	SUM(ForecastDiscountSum),
	|	SUM(ForecastDiscountSumWithoutVAT),
	|	SUM(InHouseDiscountSum),
	|	SUM(InHouseDiscountSumWithoutVAT),
	|	SUM(DefinitiveTeenagers),
	|	SUM(DefinitiveChildrenOnly),
	|	SUM(DefinitiveInfants),
	|	SUM(TentativeTeenagers),
	|	SUM(TentativeChildrenOnly),
	|	SUM(TentativeInfants)
	|BY
	|	OVERALL,
	|	AccountingDate,
	|	RoomType
	|{TOTALS BY
	|	RoomType.*,
	|	AccountingDate,
	|	(BEGINOFPERIOD(OccupancyForecast.AccountingDate, WEEK)) AS AccountingWeek,
	|	(BEGINOFPERIOD(OccupancyForecast.AccountingDate, MONTH)) AS AccountingMonth,
	|	(BEGINOFPERIOD(OccupancyForecast.AccountingDate, QUARTER)) AS AccountingQuarter,
	|	(YEAR(OccupancyForecast.AccountingDate)) AS AccountingYear}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Room inventory occupancy forecast';RU='Прогноз загрузки номерного фонда';de='Prognose zur Zimmerbestandauslastung'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
Function pmIsResource(pName) Export
	If pName = "Sales" 
	   Or pName = "RoomRevenue" 
	   Or pName = "SalesWithoutVAT" 
	   Or pName = "RoomRevenueWithoutVAT" 
	   Or pName = "GuaranteedSales" 
	   Or pName = "GuaranteedRoomRevenue" 
	   Or pName = "GuaranteedSalesWithoutVAT" 
	   Or pName = "GuaranteedRoomRevenueWithoutVAT" 
	   Or pName = "NonGuaranteedSales" 
	   Or pName = "NonGuaranteedRoomRevenue" 
	   Or pName = "NonGuaranteedSalesWithoutVAT" 
	   Or pName = "NonGuaranteedRoomRevenueWithoutVAT" 
	   Or pName = "ForecastSales" 
	   Or pName = "ForecastRoomRevenue" 
	   Or pName = "ForecastSalesWithoutVAT" 
	   Or pName = "ForecastRoomRevenueWithoutVAT" 
	   Or pName = "InHouseSales" 
	   Or pName = "InHouseRoomRevenue" 
	   Or pName = "InHouseSalesWithoutVAT" 
	   Or pName = "InHouseRoomRevenueWithoutVAT" 
	   Or pName = "CommissionSum" 
	   Or pName = "CommissionSumWithoutVAT" 
	   Or pName = "ForecastCommissionSum" 
	   Or pName = "ForecastCommissionSumWithoutVAT" 
	   Or pName = "InHouseCommissionSum" 
	   Or pName = "InHouseCommissionSumWithoutVAT" 
	   Or pName = "DiscountSum" 
	   Or pName = "DiscountSumWithoutVAT" 
	   Or pName = "ForecastDiscountSum" 
	   Or pName = "ForecastDiscountSumWithoutVAT" 
	   Or pName = "InHouseDiscountSum" 
	   Or pName = "InHouseDiscountSumWithoutVAT" 
	   Or pName = "RevPAR" 
	   Or pName = "RevPAB" 
	   Or pName = "RevPARWithoutVAT" 
	   Or pName = "RevPABWithoutVAT" 
	   Or pName = "AvgRoomPrice" 
	   Or pName = "AvgBedPrice" 
	   Or pName = "GuaranteedAvgRoomPrice" 
	   Or pName = "GuaranteedAvgBedPrice" 
	   Or pName = "NonGuaranteedAvgRoomPrice" 
	   Or pName = "NonGuaranteedAvgBedPrice" 
	   Or pName = "AvgRoomPriceWithoutVAT" 
	   Or pName = "AvgBedPriceWithoutVAT" 
	   Or pName = "GuaranteedAvgRoomPriceWithoutVAT" 
	   Or pName = "GuaranteedAvgBedPriceWithoutVAT" 
	   Or pName = "NonGuaranteedAvgRoomPriceWithoutVAT" 
	   Or pName = "NonGuaranteedAvgBedPriceWithoutVAT" 
	   Or pName = "AvgDailyRoomRate" 
	   Or pName = "AvgDailyRoomRateWithoutVAT" 
	   Or pName = "AvgDailyBedRate" 
	   Or pName = "AvgDailyBedRateWithoutVAT" 
	   Or pName = "TotalRooms"
	   Or pName = "TotalBeds"
	   Or pName = "TotalGuests"
	   Or pName = "TotalGuestsAtMorning"
	   Or pName = "RoomsRentedPercent"
	   Or pName = "BedsRentedPercent"
	   Or pName = "RoomsRentedPercentWithoutBlocks"
	   Or pName = "BedsRentedPercentWithoutBlocks"
	   Or pName = "RoomsOccupancyPercent"
	   Or pName = "BedsOccupancyPercent"
	   Or pName = "GuaranteedRoomsOccupancyPercent"
	   Or pName = "GuaranteedBedsOccupancyPercent"
	   Or pName = "NonGuaranteedRoomsOccupancyPercent"
	   Or pName = "NonGuaranteedBedsOccupancyPercent"
	   Or pName = "RoomsUsedPercent"
	   Or pName = "BedsUsedPercent"
	   Or pName = "GuaranteedRoomsUsedPercent"
	   Or pName = "GuaranteedBedsUsedPercent"
	   Or pName = "NonGuaranteedRoomsUsedPercent"
	   Or pName = "NonGuaranteedBedsUsedPercent"
	   Or pName = "GuaranteedRoomsRentedPercent"
	   Or pName = "GuaranteedBedsRentedPercent"
	   Or pName = "NonGuaranteedRoomsRentedPercent"
	   Or pName = "NonGuaranteedBedsRentedPercent"
	   Or pName = "RoomsRented"
	   Or pName = "BedsRented"
	   Or pName = "GuaranteedRoomsRented"
	   Or pName = "GuaranteedBedsRented"
	   Or pName = "NonGuaranteedRoomsRented"
	   Or pName = "NonGuaranteedBedsRented"
	   Or pName = "RoomsBlocked"
	   Or pName = "BedsBlocked"
	   Or pName = "OccupiedRooms"
	   Or pName = "OccupiedBeds"
	   Or pName = "OccupiedAdditionalBeds"
	   Or pName = "OccupiedGuests"
	   Or pName = "OccupiedRoomsAtMorning"
	   Or pName = "OccupiedBedsAtMorning"
	   Or pName = "UsedRooms"
	   Or pName = "UsedBeds"
	   Or pName = "RoomsReserved"
	   Or pName = "BedsReserved"
	   Or pName = "GuestsReserved"
	   Or pName = "GuaranteedAndInHouseRooms"
	   Or pName = "GuaranteedAndInHouseBeds"
	   Or pName = "GuaranteedAndInHouseGuests"
	   Or pName = "GuaranteedAndInHouseRoomsWithDefiniteBusinessBlocks"
	   Or pName = "GuaranteedAndInHouseBedsWithDefiniteBusinessBlocks"
	   Or pName = "RoomsInDefiniteBusinessBlocks"
	   Or pName = "BedsInDefiniteBusinessBlocks"
	   Or pName = "RoomsInTentativeBusinessBlocks"
	   Or pName = "BedsInTentativeBusinessBlocks"
	   Or pName = "GuaranteedRoomsReserved"
	   Or pName = "GuaranteedBedsReserved"
	   Or pName = "GuaranteedGuestsReserved"
	   Or pName = "NonGuaranteedRoomsReserved"
	   Or pName = "NonGuaranteedBedsReserved"
	   Or pName = "NonGuaranteedGuestsReserved"
	   Or pName = "NonGuaranteedRoomsReservedWithTentativeBusinessBlocks"
	   Or pName = "NonGuaranteedBedsReservedWithTentativeBusinessBlocks"
	   Or pName = "OccupiedRoomsWithBusinessBlocks"
	   Or pName = "OccupiedBedsWithBusinessBlocks"
	   Or pName = "RoomsCheckedIn"
	   Or pName = "BedsCheckedIn"
	   Or pName = "AdditionalBedsCheckedIn"
	   Or pName = "GuestsCheckedIn"
	   Or pName = "InHouseRooms"
	   Or pName = "InHouseBeds"
	   Or pName = "InHouseGuests"
	   Or pName = "RoomsCheckedOut"
	   Or pName = "BedsCheckedOut"
	   Or pName = "AdditionalBedsCheckedOut"
	   Or pName = "GuestsCheckedOut"
	   Or pName = "RoomsVacant"
	   Or pName = "BedsVacant"
	   Or pName = "RoomsVacantWithAllotments"
	   Or pName = "BedsVacantWithAllotments"
	   Or pName = "RoomsVacantWithoutCommitment"
	   Or pName = "BedsVacantWithoutCommitment"
	   Or pName = "RoomsSold"
	   Or pName = "BedsSold"
	   Or pName = "RoomsSoldAtMorning"
	   Or pName = "BedsSoldAtMorning"
	   Or pName = "ExpectedRoomsCheckedIn"
	   Or pName = "ExpectedBedsCheckedIn"
	   Or pName = "ExpectedGuestsCheckedIn"
	   Or pName = "GuaranteedExpectedRoomsCheckedIn"
	   Or pName = "GuaranteedExpectedBedsCheckedIn"
	   Or pName = "GuaranteedExpectedGuestsCheckedIn"
	   Or pName = "NonGuaranteedExpectedRoomsCheckedIn"
	   Or pName = "NonGuaranteedExpectedBedsCheckedIn"
	   Or pName = "NonGuaranteedExpectedGuestsCheckedIn"
	   Or pName = "ExpectedRoomsCheckedOut"
	   Or pName = "ExpectedBedsCheckedOut"
	   Or pName = "ExpectedGuestsCheckedOut"
	   Or pName = "RoomsInQuota"
	   Or pName = "BedsInQuota"
	   Or pName = "RoomsRemainsInQuota"
	   Or pName = "BedsRemainsInQuota"
	   Or pName = "RoomsReservedInQuota"
	   Or pName = "BedsReservedInQuota"
	   Or pName = "RoomsInHouseInQuota"
	   Or pName = "BedsInHouseInQuota"
	   Or pName = "RoomsOccupiedInQuota"
	   Or pName = "BedsOccupiedInQuota"
	   Or pName = "NotCommitmentRoomsInQuota"
	   Or pName = "NotCommitmentBedsInQuota"
	   Or pName = "NotCommitmentRoomsRemains"
	   Or pName = "NotCommitmentBedsRemains"
	   Or pName = "NotCommitmentRoomsReserved"
	   Or pName = "NotCommitmentBedsReserved"
	   Or pName = "NotCommitmentRoomsInHouse"
	   Or pName = "NotCommitmentBedsInHouse"
	   Or pName = "NotCommitmentRoomsOccupied"
	   Or pName = "NotCommitmentBedsOccupied"
	   Or pName = "CommitmentRoomsInQuota"
	   Or pName = "CommitmentBedsInQuota"
	   Or pName = "CommitmentRoomsInQuotaAtMorning"
	   Or pName = "CommitmentBedsInQuotaAtMorning"
	   Or pName = "CommitmentRoomsReserved"
	   Or pName = "CommitmentBedsReserved"
	   Or pName = "CommitmentRoomsReservedAtMorning"
	   Or pName = "CommitmentBedsReservedAtMorning"
	   Or pName = "CommitmentRoomsInHouse"
	   Or pName = "CommitmentBedsInHouse"
	   Or pName = "CommitmentRoomsInHouseAtMorning"
	   Or pName = "CommitmentBedsInHouseAtMorning"
	   Or pName = "CommitmentRoomsOccupied"
	   Or pName = "CommitmentBedsOccupied"
	   Or pName = "CommitmentRoomsOccupiedAtMorning"
	   Or pName = "CommitmentBedsOccupiedAtMorning"
	   Or pName = "CommitmentRoomsRemains"
	   Or pName = "CommitmentBedsRemains" 
	   Or pName = "CommitmentRoomsRemainsAtMorning"
	   Or pName = "CommitmentBedsRemainsAtMorning" 
	   Or pName = "CommitmentRoomsUsagePercent" 
	   Or pName = "CommitmentBedsUsagePercent" 
	   Or pName = "CommitmentRoomsRemainsPercent" 
	   Or pName = "CommitmentBedsRemainsPercent" Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // pmIsResource

#EndRegion

#Region Initialize    

SalesResources = 
"Sales,
|RoomRevenue,
|SalesWithoutVAT,
|RoomRevenueWithoutVAT,
|GuaranteedRoomRevenue,
|GuaranteedSalesWithoutVAT,
|GuaranteedRoomRevenueWithoutVAT,
|NonGuaranteedSales,
|NonGuaranteedRoomRevenue,
|NonGuaranteedSalesWithoutVAT,
|NonGuaranteedRoomRevenueWithoutVAT,
|RevPAR,
|RevPAB,
|RevPARWithoutVAT,
|RevPABWithoutVAT,
|AvgRoomPrice,
|AvgBedPrice,
|AvgRoomPriceWithoutVAT,
|AvgBedPriceWithoutVAT,
|GuaranteedAvgRoomPrice,
|GuaranteedAvgBedPrice,
|GuaranteedAvgRoomPriceWithoutVAT,
|GuaranteedAvgBedPriceWithoutVAT,
|NonGuaranteedAvgRoomPrice,
|NonGuaranteedAvgBedPrice,
|NonGuaranteedAvgRoomPriceWithoutVAT,
|NonGuaranteedAvgBedPriceWithoutVAT,
|AvgDailyRoomRate,
|AvgDailyBedRate,
|AvgDailyRoomRateWithoutVAT,
|AvgDailyBedRateWithoutVAT,
|ForecastSales,
|ForecastRoomRevenue,
|ForecastSalesWithoutVAT,
|ForecastRoomRevenueWithoutVAT,
|InHouseSales,
|InHouseRoomRevenue,
|InHouseSalesWithoutVAT,
|InHouseRoomRevenueWithoutVAT,
|CommissionSum,
|CommissionSumWithoutVAT,
|ForecastCommissionSum,
|ForecastCommissionSumWithoutVAT,
|InHouseCommissionSum,
|InHouseCommissionSumWithoutVAT,
|DiscountSum,
|DiscountSumWithoutVAT,
|ForecastDiscountSum,
|ForecastDiscountSumWithoutVAT,
|InHouseDiscountSum,
|InHouseDiscountSumWithoutVAT,
|DefinitiveSales,
|DefinitiveRoomRevenue,
|DefinitiveSalesWithoutVAT,
|DefinitiveRoomRevenueWithoutVAT,
|TentativeSales,
|TentativeRoomRevenue,
|TentativeSalesWithoutVAT,
|TentativeRoomRevenueWithoutVAT";

#EndRegion
