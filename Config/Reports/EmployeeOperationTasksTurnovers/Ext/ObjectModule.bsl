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
		If ValueIsFilled(Hotel) Then
			If Not ValueIsFilled(CheckOutCleaning) Then
				CheckOutCleaning = Hotel.CheckOutCleaning;
			EndIf;
			If Not ValueIsFilled(RegularCleaning) Then
				RegularCleaning = Hotel.RegularCleaning;
			EndIf;
			If Not ValueIsFilled(VacantRoomCleaning) Then
				VacantRoomCleaning = Hotel.VacantRoomCleaning;
			EndIf;
			If Not ValueIsFilled(RepairEndCleaning) Then
				RepairEndCleaning = Hotel.RepairEndCleaning;
			EndIf;
			If Not ValueIsFilled(RoomStatusAfterCheckOut) Then
				RoomStatusAfterCheckOut = Hotel.RoomStatusAfterCheckOut;
			EndIf;
			If Not ValueIsFilled(RegularOperationGroup) Then
				RegularOperationGroup = Hotel.RegularOperationGroup;
			EndIf;
		EndIf;
	EndIf;
	If Not ValueIsFilled(PeriodFrom) Then
		PeriodFrom = BegOfMonth(CurrentSessionDate()); // Begin of current month
	EndIf;
	If Not ValueIsFilled(PeriodTo) Then
		PeriodTo = EndOfDay(CurrentSessionDate()); // End of today
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetReportParametersPresentation() Export
	vParamPresentation = "";
	If Not ValueIsFilled(PeriodFrom) And Not ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("en='Report period is not set';ru='Период отчета не установлен';de='Berichtszeitraum nicht festgelegt'") + 
		                     ";" + Chars.LF;
	ElsIf Not ValueIsFilled(PeriodFrom) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период по '; en = 'Period to '; de = 'Periode zu '") + 
		                     Format(PeriodTo, "DF='dd.MM.yyyy'") + 
		                     ";" + Chars.LF;
	ElsIf Not ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период с '; en = 'Period from '; de = 'Periode von '") + 
		                     Format(PeriodFrom, "DF='dd.MM.yyyy'") + 
		                     ";" + Chars.LF;
	ElsIf BegOfDay(PeriodFrom) = BegOfDay(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период на '; en = 'Period on '; de = 'Periode '") + 
		                     Format(PeriodFrom, "DF='dd.MM.yyyy'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom <= PeriodTo Then
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
// Runs report and returns if report form should be shown
// -----------------------------------------------------------------------------
Procedure pmGenerate(pSpreadsheet) Export
	Var vTemplateAttributes;
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
	
	// Initialize report builder query generator attributes
	ReportBuilder.PresentationAdding = PresentationAdditionType.Add;
	
	// Save report builder settings
	vReportBuilderSettings = ReportBuilder.GetSettings(True, True, True, True, True);
	
	// Build and set report builder query
	vCurDay = BegOfDay(PeriodFrom);
	vReportBuilderText = QuerySelect;
	While EndOfDay(vCurDay) <= EndOfDay(PeriodTo) Do
		vYYYYMMDD = Format(BegOfDay(vCurDay), "DF=yyyyMMdd");
		vDDMMYYYY = Format(BegOfDay(vCurDay), "DF=ddMMyyyy");
		
		If vCurDay > BegOfDay(PeriodFrom) Then
			vReportBuilderText = vReportBuilderText + Chars.LF + "UNION ALL" + Chars.LF;
		EndIf;
		vReportBuilderText = vReportBuilderText + StrReplace(StrReplace(QueryYYYYMMDDSelect, "YYYYMMDD", vYYYYMMDD), "DDMMYYYY", vDDMMYYYY);
		
		vCurDay = vCurDay + 24*3600;
	EndDo;
	vReportBuilderText = vReportBuilderText + QueryTail;
	ReportBuilder.Text = vReportBuilderText;
	
	// Fill static report query parameters
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qIsEmptyHotel", Not ValueIsFilled(Hotel));
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qIsEmptyRoom", Not ValueIsFilled(Room));
	ReportBuilder.Parameters.Insert("qExpense", AccumulationRecordType.Expense);
	ReportBuilder.Parameters.Insert("qReceipt", AccumulationRecordType.Receipt);
	ReportBuilder.Parameters.Insert("qRegularCleaning", RegularCleaning);
	ReportBuilder.Parameters.Insert("qRegularCleaningCode", ?(ValueIsFilled(RegularCleaning), RegularCleaning.Code, ""));
	ReportBuilder.Parameters.Insert("qRegularCleaningSortCode", ?(ValueIsFilled(RegularCleaning), RegularCleaning.SortCode, 0));
	ReportBuilder.Parameters.Insert("qCheckOutCleaning", CheckOutCleaning);
	ReportBuilder.Parameters.Insert("qCheckOutCleaningCode", ?(ValueIsFilled(CheckOutCleaning), CheckOutCleaning.Code, ""));
	ReportBuilder.Parameters.Insert("qCheckOutCleaningSortCode", ?(ValueIsFilled(CheckOutCleaning), CheckOutCleaning.SortCode, 0));
	ReportBuilder.Parameters.Insert("qVacantRoomCleaning", VacantRoomCleaning);
	ReportBuilder.Parameters.Insert("qVacantRoomCleaningCode", ?(ValueIsFilled(VacantRoomCleaning), VacantRoomCleaning.Code, ""));
	ReportBuilder.Parameters.Insert("qVacantRoomCleaningSortCode", ?(ValueIsFilled(VacantRoomCleaning), VacantRoomCleaning.SortCode, 0));
	ReportBuilder.Parameters.Insert("qRepairEndCleaning", RepairEndCleaning);
	ReportBuilder.Parameters.Insert("qRepairEndCleaningCode", ?(ValueIsFilled(RepairEndCleaning), RepairEndCleaning.Code, ""));
	ReportBuilder.Parameters.Insert("qRepairEndCleaningSortCode", ?(ValueIsFilled(RepairEndCleaning), RepairEndCleaning.SortCode, 0));
    ReportBuilder.Parameters.Insert("qRegularOperationGroup", RegularOperationGroup);
	ReportBuilder.Parameters.Insert("qEmptyRoomType", Catalogs.RoomTypes.EmptyRef());
	
	// Fill dynamic report query parameters
	vCurDay = BegOfDay(PeriodFrom);
	While EndOfDay(vCurDay) <= EndOfDay(PeriodTo) Do
		vDDMMYYYY = Format(BegOfDay(vCurDay), "DF=ddMMyyyy");
		
		ReportBuilder.Parameters.Insert("qPeriodFrom" + vDDMMYYYY, BegOfDay(vCurDay));
		ReportBuilder.Parameters.Insert("qPeriodTo" + vDDMMYYYY, EndOfDay(vCurDay));
		
		vCurDay = vCurDay + 24*3600;
	EndDo;
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Load report builder settings
	ReportBuilder.SetSettings(vReportBuilderSettings, True, True, True, True, True);
	
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
	
	// Initialize main SELECT part of the query
	QuerySelect = 
	"SELECT
	|	TaskTurnovers.Hotel AS Hotel,
	|	TaskTurnovers.Room AS Room,
	|	TaskTurnovers.RoomType AS RoomType,
	|	TaskTurnovers.Guest AS Guest,
	|	TaskTurnovers.RoomBlockType AS RoomBlockType,
	|	TaskTurnovers.Citizenship AS Citizenship,
	|	TaskTurnovers.CheckInDate AS CheckInDate,
	|	TaskTurnovers.CheckOutDate AS CheckOutDate,
	|	TaskTurnovers.CheckOutCleaning AS CheckOutCleaning,
	|	TaskTurnovers.RegularCleaning AS RegularCleaning,
	|	TaskTurnovers.RepairEndCleaning AS RepairEndCleaning,
	|	TaskTurnovers.VacantRoomCleaning AS VacantRoomCleaning,
	|	TaskTurnovers.RegularOperation AS RegularOperation,
	|	TaskTurnovers.CheckOutCleaningCode AS CheckOutCleaningCode,
	|	TaskTurnovers.RegularCleaningCode AS RegularCleaningCode,
	|	TaskTurnovers.RepairEndCleaningCode AS RepairEndCleaningCode,
	|	TaskTurnovers.VacantRoomCleaningCode AS VacantRoomCleaningCode,
	|	TaskTurnovers.RegularOperationCode AS RegularOperationCode,
	|	TaskTurnovers.CheckOutCleaningSortCode AS CheckOutCleaningSortCode,
	|	TaskTurnovers.RegularCleaningSortCode AS RegularCleaningSortCode,
	|	TaskTurnovers.RepairEndCleaningSortCode AS RepairEndCleaningSortCode,
	|	TaskTurnovers.VacantRoomCleaningSortCode AS VacantRoomCleaningSortCode,
	|	TaskTurnovers.RegularOperationSortCode AS RegularOperationSortCode,
	|	SUM(TaskTurnovers.CheckOutCleaningCount) AS CheckOutCleaningCount,
	|	SUM(TaskTurnovers.RegularCleaningCount) AS RegularCleaningCount,
	|	SUM(TaskTurnovers.RepairEndCleaningCount) AS RepairEndCleaningCount,
	|	SUM(TaskTurnovers.VacantRoomCleaningCount) AS VacantRoomCleaningCount,
	|	SUM(TaskTurnovers.RegularOperationCount) AS RegularOperationCount
	|{SELECT
	|	Hotel.* AS Hotel,
	|	Room.* AS Room,
	|	RoomType.* AS RoomType,
	|	RoomBlockType.* AS RoomBlockType,
	|	Guest.* AS Guest,
	|	Citizenship.* AS Citizenship,
	|	CheckInDate AS CheckInDate,
	|	CheckOutDate AS CheckOutDate,
	|	CheckOutCleaning.* AS CheckOutCleaning,
	|	RegularCleaning.* AS RegularCleaning,
	|	RepairEndCleaning.* AS RepairEndCleaning,
	|	VacantRoomCleaning.* AS VacantRoomCleaning,
	|	RegularOperation.* AS RegularOperation,
	|	CheckOutCleaningCode AS CheckOutCleaningCode,
	|	RegularCleaningCode AS RegularCleaningCode,
	|	RepairEndCleaningCode AS RepairEndCleaningCode,
	|	VacantRoomCleaningCode AS VacantRoomCleaningCode,
	|	RegularOperationCode AS RegularOperationCode,
	|	CheckOutCleaningSortCode AS CheckOutCleaningSortCode,
	|	RegularCleaningSortCode AS RegularCleaningSortCode,
	|	RepairEndCleaningSortCode AS RepairEndCleaningSortCode,
	|	VacantRoomCleaningSortCode AS VacantRoomCleaningSortCode,
	|	RegularOperationSortCode AS RegularOperationSortCode,
	|	CheckOutCleaningCount AS CheckOutCleaningCount,
	|	RegularCleaningCount AS RegularCleaningCount,
	|	RepairEndCleaningCount AS RepairEndCleaningCount,
	|	VacantRoomCleaningCount AS VacantRoomCleaningCount,
	|	RegularOperationCount AS RegularOperationCount}
	|FROM (";
	
	// Initialize per day query text
	QueryYYYYMMDDSelect = 
	"SELECT DISTINCT
	|	TaskTurnoversYYYYMMDD.Hotel AS Hotel,
	|	TaskTurnoversYYYYMMDD.Room AS Room,
	|	TaskTurnoversYYYYMMDD.RoomType AS RoomType,
	|	CASE
	|		WHEN TaskTurnoversYYYYMMDD.CheckOutAccommodation IS NOT NULL 
	|			THEN TaskTurnoversYYYYMMDD.CheckOutGuest
	|		WHEN TaskTurnoversYYYYMMDD.InHouseAccommodation IS NOT NULL 
	|			THEN TaskTurnoversYYYYMMDD.InHouseGuest
	|		WHEN TaskTurnoversYYYYMMDD.CheckInAccommodation IS NOT NULL 
	|			THEN TaskTurnoversYYYYMMDD.CheckInGuest
	|		ELSE NULL
	|	END AS Guest,
	|	CASE
	|		WHEN TaskTurnoversYYYYMMDD.CheckOutAccommodation IS NOT NULL 
	|			THEN TaskTurnoversYYYYMMDD.CheckOutGuest.Citizenship
	|		WHEN TaskTurnoversYYYYMMDD.InHouseAccommodation IS NOT NULL 
	|			THEN TaskTurnoversYYYYMMDD.InHouseGuest.Citizenship
	|		WHEN TaskTurnoversYYYYMMDD.CheckInAccommodation IS NOT NULL 
	|			THEN TaskTurnoversYYYYMMDD.CheckInGuest.Citizenship
	|		ELSE NULL
	|	END AS Citizenship,
	|	CASE
	|		WHEN TaskTurnoversYYYYMMDD.CheckOutAccommodation IS NOT NULL 
	|			THEN NULL
	|		WHEN TaskTurnoversYYYYMMDD.InHouseAccommodation IS NOT NULL 
	|			THEN NULL
	|		WHEN TaskTurnoversYYYYMMDD.SetRoomBlock IS NOT NULL 
	|			THEN TaskTurnoversYYYYMMDD.RoomBlockType
	|		WHEN TaskTurnoversYYYYMMDD.CheckInAccommodation IS NOT NULL 
	|			THEN NULL
	|		ELSE NULL
	|	END AS RoomBlockType,
	|	CASE
	|		WHEN TaskTurnoversYYYYMMDD.CheckOutAccommodation IS NOT NULL 
	|			THEN TaskTurnoversYYYYMMDD.CheckOutCheckInDate
	|		WHEN TaskTurnoversYYYYMMDD.InHouseAccommodation IS NOT NULL 
	|			THEN TaskTurnoversYYYYMMDD.InHouseCheckInDate
	|		WHEN TaskTurnoversYYYYMMDD.SetRoomBlock IS NOT NULL 
	|			THEN TaskTurnoversYYYYMMDD.RoomBlockStartDate
	|		WHEN TaskTurnoversYYYYMMDD.CheckInAccommodation IS NOT NULL 
	|			THEN TaskTurnoversYYYYMMDD.CheckInCheckInDate
	|		ELSE NULL
	|	END AS CheckInDate,
	|	CASE
	|		WHEN TaskTurnoversYYYYMMDD.CheckOutAccommodation IS NOT NULL 
	|			THEN TaskTurnoversYYYYMMDD.CheckOutCheckOutDate
	|		WHEN TaskTurnoversYYYYMMDD.InHouseAccommodation IS NOT NULL 
	|			THEN TaskTurnoversYYYYMMDD.InHouseCheckOutDate
	|		WHEN TaskTurnoversYYYYMMDD.SetRoomBlock IS NOT NULL 
	|			THEN TaskTurnoversYYYYMMDD.RoomBlockEndDate
	|		WHEN TaskTurnoversYYYYMMDD.CheckInAccommodation IS NOT NULL 
	|			THEN TaskTurnoversYYYYMMDD.CheckInCheckOutDate
	|		ELSE NULL
	|	END AS CheckOutDate,
	|	TaskTurnoversYYYYMMDD.CheckOutCleaning AS CheckOutCleaning,
	|	TaskTurnoversYYYYMMDD.RegularCleaning AS RegularCleaning,
	|	TaskTurnoversYYYYMMDD.RepairEndCleaning AS RepairEndCleaning,
	|	TaskTurnoversYYYYMMDD.VacantRoomCleaning AS VacantRoomCleaning,
	|	TaskTurnoversYYYYMMDD.RegularOperation AS RegularOperation,
	|	TaskTurnoversYYYYMMDD.CheckOutCleaningCode AS CheckOutCleaningCode,
	|	TaskTurnoversYYYYMMDD.RegularCleaningCode AS RegularCleaningCode,
	|	TaskTurnoversYYYYMMDD.RepairEndCleaningCode AS RepairEndCleaningCode,
	|	TaskTurnoversYYYYMMDD.VacantRoomCleaningCode AS VacantRoomCleaningCode,
	|	TaskTurnoversYYYYMMDD.RegularOperationCode AS RegularOperationCode,
	|	TaskTurnoversYYYYMMDD.CheckOutCleaningSortCode AS CheckOutCleaningSortCode,
	|	TaskTurnoversYYYYMMDD.RegularCleaningSortCode AS RegularCleaningSortCode,
	|	TaskTurnoversYYYYMMDD.RepairEndCleaningSortCode AS RepairEndCleaningSortCode,
	|	TaskTurnoversYYYYMMDD.VacantRoomCleaningSortCode AS VacantRoomCleaningSortCode,
	|	TaskTurnoversYYYYMMDD.RegularOperationSortCode AS RegularOperationSortCode,
	|	CASE 
	|		WHEN TaskTurnoversYYYYMMDD.CheckOutCleaning IS NOT NULL
	|			THEN 1
	|		ELSE 0
	|	END AS CheckOutCleaningCount,
	|	CASE 
	|		WHEN TaskTurnoversYYYYMMDD.RegularCleaning IS NOT NULL
	|			THEN 1
	|		ELSE 0
	|	END AS RegularCleaningCount,
	|	CASE 
	|		WHEN TaskTurnoversYYYYMMDD.RepairEndCleaning IS NOT NULL
	|			THEN 1
	|		ELSE 0
	|	END AS RepairEndCleaningCount,
	|	CASE 
	|		WHEN TaskTurnoversYYYYMMDD.VacantRoomCleaning IS NOT NULL
	|			THEN 1
	|		ELSE 0
	|	END AS VacantRoomCleaningCount,
	|	CASE 
	|		WHEN TaskTurnoversYYYYMMDD.RegularOperation IS NOT NULL
	|			THEN 1
	|		ELSE 0
	|	END AS RegularOperationCount
	|FROM
	|	(SELECT
	|		RoomInventoryBalanceYYYYMMDD.Hotel AS Hotel,
	|		RoomInventoryBalanceYYYYMMDD.Room AS Room,
	|		RoomInventoryBalanceYYYYMMDD.RoomType AS RoomType,
	|		RoomInventoryBalanceYYYYMMDD.TotalRoomsBalance AS TotalRoomsBalance,
	|		RoomInventoryBalanceYYYYMMDD.TotalBedsBalance AS TotalBedsBalance,
	|		InHousePersonsYYYYMMDD.Recorder AS InHouseAccommodation,
	|		InHousePersonsYYYYMMDD.Guest AS InHouseGuest,
	|		InHousePersonsYYYYMMDD.PeriodFrom AS InHouseCheckInDate,
	|		InHousePersonsYYYYMMDD.PeriodTo AS InHouseCheckOutDate,
	|		CASE
	|			WHEN (NOT InHousePersonsYYYYMMDD.Recorder IS NULL )
	|					AND CheckedOutGuestsYYYYMMDD.Recorder IS NULL 
	|				THEN &qRegularCleaning
	|			ELSE NULL
	|		END AS RegularCleaning,
	|		CASE
	|			WHEN (NOT InHousePersonsYYYYMMDD.Recorder IS NULL )
	|					AND CheckedOutGuestsYYYYMMDD.Recorder IS NULL 
	|				THEN &qRegularCleaningCode
	|			ELSE NULL
	|		END AS RegularCleaningCode,
	|		CASE
	|			WHEN (NOT InHousePersonsYYYYMMDD.Recorder IS NULL )
	|					AND CheckedOutGuestsYYYYMMDD.Recorder IS NULL 
	|				THEN &qRegularCleaningSortCode
	|			ELSE NULL
	|		END AS RegularCleaningSortCode,
	|		CheckedOutGuestsYYYYMMDD.Recorder AS CheckOutAccommodation,
	|		CheckedOutGuestsYYYYMMDD.Guest AS CheckOutGuest,
	|		CheckedOutGuestsYYYYMMDD.CheckInDate AS CheckOutCheckInDate,
	|		CheckedOutGuestsYYYYMMDD.CheckOutDate AS CheckOutCheckOutDate,
	|		CASE
	|			WHEN (NOT CheckedOutGuestsYYYYMMDD.Recorder IS NULL )
	|				THEN &qCheckOutCleaning
	|			ELSE NULL
	|		END AS CheckOutCleaning,
	|		CASE
	|			WHEN (NOT CheckedOutGuestsYYYYMMDD.Recorder IS NULL )
	|				THEN &qCheckOutCleaningCode
	|			ELSE NULL
	|		END AS CheckOutCleaningCode,
	|		CASE
	|			WHEN (NOT CheckedOutGuestsYYYYMMDD.Recorder IS NULL )
	|				THEN &qCheckOutCleaningSortCode
	|			ELSE NULL
	|		END AS CheckOutCleaningSortCode,
	|		RoomBlocksYYYYMMDD.Recorder AS SetRoomBlock,
	|		RoomBlocksYYYYMMDD.RoomBlockType AS RoomBlockType,
	|		SUBSTRING(RoomBlocksYYYYMMDD.Remarks, 1, 999) AS RoomBlockRemarks,
	|		RoomBlocksYYYYMMDD.CheckInDate AS RoomBlockStartDate,
	|		RoomBlocksYYYYMMDD.CheckOutDate AS RoomBlockEndDate,
	|		CASE
	|			WHEN (NOT RoomBlocksYYYYMMDD.Recorder IS NULL )
	|				THEN &qRepairEndCleaning
	|			ELSE NULL
	|		END AS RepairEndCleaning,
	|		CASE
	|			WHEN (NOT RoomBlocksYYYYMMDD.Recorder IS NULL )
	|				THEN &qRepairEndCleaningCode
	|			ELSE NULL
	|		END AS RepairEndCleaningCode,
	|		CASE
	|			WHEN (NOT RoomBlocksYYYYMMDD.Recorder IS NULL )
	|				THEN &qRepairEndCleaningSortCode
	|			ELSE NULL
	|		END AS RepairEndCleaningSortCode,
	|		CASE
	|			WHEN CheckedOutGuestsYYYYMMDD.Recorder IS NULL 
	|					AND InHousePersonsYYYYMMDD.Recorder IS NULL 
	|					AND CheckedInPersonsYYYYMMDD.Recorder IS NULL 
	|				THEN &qVacantRoomCleaning
	|			ELSE NULL
	|		END AS VacantRoomCleaning,
	|		CASE
	|			WHEN CheckedOutGuestsYYYYMMDD.Recorder IS NULL 
	|					AND InHousePersonsYYYYMMDD.Recorder IS NULL 
	|					AND CheckedInPersonsYYYYMMDD.Recorder IS NULL 
	|				THEN &qVacantRoomCleaningCode
	|			ELSE NULL
	|		END AS VacantRoomCleaningCode,
	|		CASE
	|			WHEN CheckedOutGuestsYYYYMMDD.Recorder IS NULL 
	|					AND InHousePersonsYYYYMMDD.Recorder IS NULL 
	|					AND CheckedInPersonsYYYYMMDD.Recorder IS NULL 
	|				THEN &qVacantRoomCleaningSortCode
	|			ELSE NULL
	|		END AS VacantRoomCleaningSortCode,
	|		RegularOperationsYYYYMMDD.RegularOperation AS RegularOperation,
	|		CASE
	|			WHEN RegularOperationsYYYYMMDD.RegularOperation IS NOT NULL 
	|				THEN RegularOperationsYYYYMMDD.RegularOperation.Code
	|			ELSE NULL
	|		END AS RegularOperationCode,
	|		CASE
	|			WHEN RegularOperationsYYYYMMDD.RegularOperation IS NOT NULL 
	|				THEN RegularOperationsYYYYMMDD.RegularOperation.SortCode
	|			ELSE NULL
	|		END AS RegularOperationSortCode,
	|		CheckedInPersonsYYYYMMDD.Recorder AS CheckInAccommodation,
	|		CheckedInPersonsYYYYMMDD.Guest AS CheckInGuest,
	|		CheckedInPersonsYYYYMMDD.Recorder.CheckInDate AS CheckInCheckInDate,
	|		CheckedInPersonsYYYYMMDD.Recorder.CheckOutDate AS CheckInCheckOutDate
	|	FROM
	|		AccumulationRegister.RoomInventory.Balance(
	|				&qPeriodToDDMMYYYY,
	|				(Hotel IN HIERARCHY (&qHotel)
	|					OR &qIsEmptyHotel)
	|					AND (Room IN HIERARCHY (&qRoom)
	|						OR &qIsEmptyRoom)) AS RoomInventoryBalanceYYYYMMDD
	|			LEFT JOIN AccumulationRegister.RoomInventory AS InHousePersonsYYYYMMDD
	|			ON RoomInventoryBalanceYYYYMMDD.Room = InHousePersonsYYYYMMDD.Room
	|				AND (InHousePersonsYYYYMMDD.RecordType = &qExpense)
	|				AND (InHousePersonsYYYYMMDD.IsInHouse)
	|				AND (InHousePersonsYYYYMMDD.CheckInDate < &qPeriodFromDDMMYYYY)
	|				AND (InHousePersonsYYYYMMDD.CheckOutDate > &qPeriodToDDMMYYYY)
	|				AND (InHousePersonsYYYYMMDD.Period = InHousePersonsYYYYMMDD.CheckInDate)
	|			LEFT JOIN AccumulationRegister.RoomInventory AS CheckedOutGuestsYYYYMMDD
	|			ON RoomInventoryBalanceYYYYMMDD.Room = CheckedOutGuestsYYYYMMDD.Room
	|				AND (CheckedOutGuestsYYYYMMDD.RecordType = &qReceipt)
	|				AND (CheckedOutGuestsYYYYMMDD.IsCheckOut)
	|				AND (CheckedOutGuestsYYYYMMDD.CheckOutDate > &qPeriodFromDDMMYYYY)
	|				AND (CheckedOutGuestsYYYYMMDD.CheckOutDate <= &qPeriodToDDMMYYYY)
	|				AND (CheckedOutGuestsYYYYMMDD.Period = CheckedOutGuestsYYYYMMDD.CheckOutDate)
	|			LEFT JOIN AccumulationRegister.RoomInventory AS RoomBlocksYYYYMMDD
	|			ON RoomInventoryBalanceYYYYMMDD.Room = RoomBlocksYYYYMMDD.Room
	|				AND (RoomBlocksYYYYMMDD.RecordType = &qExpense)
	|				AND (RoomBlocksYYYYMMDD.IsBlocking)
	|				AND (RoomBlocksYYYYMMDD.CheckOutDate > &qPeriodFromDDMMYYYY)
	|				AND (RoomBlocksYYYYMMDD.CheckOutDate <= &qPeriodToDDMMYYYY)
	|				AND (RoomBlocksYYYYMMDD.RoomBlockType.IsRoomRepair)
	|			LEFT JOIN AccumulationRegister.RoomInventory AS CheckedInPersonsYYYYMMDD
	|			ON RoomInventoryBalanceYYYYMMDD.Room = CheckedInPersonsYYYYMMDD.Room
	|				AND (CheckedInPersonsYYYYMMDD.RecordType = &qExpense)
	|				AND (CheckedInPersonsYYYYMMDD.IsInHouse)
	|				AND (CheckedInPersonsYYYYMMDD.CheckInDate >= &qPeriodFromDDMMYYYY)
	|				AND (CheckedInPersonsYYYYMMDD.CheckInDate < &qPeriodToDDMMYYYY)
	|				AND (CheckedInPersonsYYYYMMDD.Period = CheckedInPersonsYYYYMMDD.CheckInDate)
	|			LEFT JOIN Catalog.RegularOperationGroups.RegularOperations AS RegularOperationsYYYYMMDD
	|			ON (RegularOperationsYYYYMMDD.Ref = &qRegularOperationGroup)
	|				AND (RegularOperationsYYYYMMDD.PerformWhenRoomIsBusy
	|						AND DATEDIFF(&qPeriodFromDDMMYYYY, BEGINOFPERIOD(InHousePersonsYYYYMMDD.CheckInDate, DAY), DAY) / RegularOperationsYYYYMMDD.RegularOperationFrequency = (CAST(DATEDIFF(&qPeriodFromDDMMYYYY, BEGINOFPERIOD(InHousePersonsYYYYMMDD.CheckInDate, DAY), DAY) / RegularOperationsYYYYMMDD.RegularOperationFrequency AS NUMBER(17, 0)))
	|						AND DATEDIFF(&qPeriodFromDDMMYYYY, BEGINOFPERIOD(InHousePersonsYYYYMMDD.CheckInDate, DAY), DAY) <> 0
	|					OR RegularOperationsYYYYMMDD.PerformWhenRoomIsBusy
	|						AND RegularOperationsYYYYMMDD.PerformOnCheckInDay
	|						AND CheckedInPersonsYYYYMMDD.Recorder IS NOT NULL 
	|					OR RegularOperationsYYYYMMDD.PerformWhenRoomIsBusy
	|						AND RegularOperationsYYYYMMDD.PerformOnCheckOutDay
	|						AND CheckedOutGuestsYYYYMMDD.Recorder IS NOT NULL 
	|					OR RegularOperationsYYYYMMDD.PerformWhenRoomIsFree
	|						AND InHousePersonsYYYYMMDD.Recorder IS NULL 
	|						AND CheckedInPersonsYYYYMMDD.Recorder IS NULL 
	|						AND CheckedOutGuestsYYYYMMDD.Recorder IS NULL )
	|				AND ((NOT RegularOperationsYYYYMMDD.DoNotPerformOnWeekends)
	|					OR RegularOperationsYYYYMMDD.DoNotPerformOnWeekends
	|						AND WEEKDAY(&qPeriodFromDDMMYYYY) < 6)
	|				AND (RegularOperationsYYYYMMDD.RoomType = &qEmptyRoomType
	|					OR RegularOperationsYYYYMMDD.RoomType <> &qEmptyRoomType
	|						AND RoomInventoryBalanceYYYYMMDD.RoomType = RegularOperationsYYYYMMDD.RoomType
	|					OR RegularOperationsYYYYMMDD.RoomType <> &qEmptyRoomType
	|						AND RoomInventoryBalanceYYYYMMDD.RoomType.Parent <> &qEmptyRoomType
	|						AND RoomInventoryBalanceYYYYMMDD.RoomType.Parent = RegularOperationsYYYYMMDD.RoomType)
	|	WHERE
	|		RoomInventoryBalanceYYYYMMDD.TotalRoomsBalance > 0) AS TaskTurnoversYYYYMMDD ";
	
	QueryTail = 
	") AS TaskTurnovers
	|GROUP BY
	|	TaskTurnovers.Hotel,
	|	TaskTurnovers.Room,
	|	TaskTurnovers.RoomType,
	|	TaskTurnovers.Guest,
	|	TaskTurnovers.RoomBlockType,
	|	TaskTurnovers.Citizenship,
	|	TaskTurnovers.CheckInDate,
	|	TaskTurnovers.CheckOutDate,
	|	TaskTurnovers.CheckOutCleaning,
	|	TaskTurnovers.RegularCleaning,
	|	TaskTurnovers.RepairEndCleaning,
	|	TaskTurnovers.VacantRoomCleaning,
	|	TaskTurnovers.RegularOperation,
	|	TaskTurnovers.CheckOutCleaningCode,
	|	TaskTurnovers.RegularCleaningCode,
	|	TaskTurnovers.RepairEndCleaningCode,
	|	TaskTurnovers.VacantRoomCleaningCode,
	|	TaskTurnovers.RegularOperationCode,
	|	TaskTurnovers.CheckOutCleaningSortCode,
	|	TaskTurnovers.RegularCleaningSortCode,
	|	TaskTurnovers.RepairEndCleaningSortCode,
	|	TaskTurnovers.VacantRoomCleaningSortCode,
	|	TaskTurnovers.RegularOperationSortCode
	|HAVING
	|	SUM(TaskTurnovers.CheckOutCleaningCount) > 0
	|	OR SUM(TaskTurnovers.RegularCleaningCount) > 0
	|	OR SUM(TaskTurnovers.RepairEndCleaningCount) > 0
	|	OR SUM(TaskTurnovers.VacantRoomCleaningCount) > 0
	|	OR SUM(TaskTurnovers.RegularOperationCount) > 0
	|{WHERE
	|	TaskTurnovers.Hotel.*,
	|	TaskTurnovers.Room.*,
	|	TaskTurnovers.RoomType.*,
	|	TaskTurnovers.RoomBlockType.*,
	|	TaskTurnovers.Guest.*,
	|	TaskTurnovers.CheckInDate,
	|	TaskTurnovers.CheckOutDate,
	|	TaskTurnovers.CheckOutCleaning.*,
	|	TaskTurnovers.RegularCleaning.*,
	|	TaskTurnovers.RepairEndCleaning.*,
	|	TaskTurnovers.VacantRoomCleaning.*,
	|	TaskTurnovers.RegularOperation.*}
	|{ORDER BY
	|	Hotel.* AS Hotel,
	|	Room.* AS Room,
	|	RoomType.* AS RoomType,
	|	Guest.* AS Guest,
	|	RoomBlockType.* AS RoomBlockType,
	|	Citizenship.* AS Citizenship,
	|	CheckInDate AS CheckInDate,
	|	CheckOutDate AS CheckOutDate,
	|	CheckOutCleaning.* AS CheckOutCleaning,
	|	RegularCleaning.* AS RegularCleaning,
	|	RepairEndCleaning.* AS RepairEndCleaning,
	|	VacantRoomCleaning.* AS VacantRoomCleaning,
	|	RegularOperation.* AS RegularOperation,
	|	CheckOutCleaningCode AS CheckOutCleaningCode,
	|	RegularCleaningCode AS RegularCleaningCode,
	|	RepairEndCleaningCode AS RepairEndCleaningCode,
	|	VacantRoomCleaningCode AS VacantRoomCleaningCode,
	|	RegularOperationCode AS RegularOperationCode,
	|	CheckOutCleaningSortCode AS CheckOutCleaningSortCode,
	|	RegularCleaningSortCode AS RegularCleaningSortCode,
	|	RepairEndCleaningSortCode AS RepairEndCleaningSortCode,
	|	VacantRoomCleaningSortCode AS VacantRoomCleaningSortCode,
	|	RegularOperationSortCode AS RegularOperationSortCode}
	|TOTALS 
	|	SUM(CheckOutCleaningCount),
	|	SUM(RegularCleaningCount),
	|	SUM(RepairEndCleaningCount),
	|	SUM(VacantRoomCleaningCount),
	|	SUM(RegularOperationCount)
	|BY
	|	OVERALL,
	|	Hotel,
	|	RoomType
	|{TOTALS BY
	|	Hotel.* AS Hotel,
	|	Room.* AS Room,
	|	RoomType.* AS RoomType,
	|	RoomBlockType.* AS RoomBlockType,
	|	Citizenship.* AS Citizenship,
	|	CheckOutCleaning.* AS CheckOutCleaning,
	|	RegularCleaning.* AS RegularCleaning,
	|	RepairEndCleaning.* AS RepairEndCleaning,
	|	VacantRoomCleaning.* AS VacantRoomCleaning,
	|	RegularOperation.* AS RegularOperation}";
	
	QueryText = QuerySelect + QueryYYYYMMDDSelect + QueryTail;
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("en='Employee room operation tasks turnovers';ru='Обороты по заданиям на выполнение работ в номерах';de='Umsätze nach Aufgaben und Erbringen von Arbeit in den Zimmern'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
