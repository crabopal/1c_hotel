Var ProgressForm;

// -----------------------------------------------------------------------------
Function GetPeriodHash(pHotel, pRoomType, pDate)
	Return pHotel.Code + pRoomType.Code + Year(pDate) + Format(DayOfYear(pDate), "ND=3; NLZ=");
EndFunction // GetPeriodHash

// -----------------------------------------------------------------------------
Function GetQueryResource(pQryHours, pShowReportsInBeds, pLastVacant)
	vVacant = 0;	
	If pShowReportsInBeds Then
		If pQryHours.BedsVacant = Null Then
			vVacant = pLastVacant;
		Else
			vVacant = pQryHours.BedsVacant;
		EndIf;
	Else
		If pQryHours.RoomsVacant = Null Then
			vVacant = pLastVacant;
		Else
			vVacant = pQryHours.RoomsVacant;
		EndIf;
	EndIf;
	Return vVacant;
EndFunction // GetQueryResource

// -----------------------------------------------------------------------------
Function GetRoomsQueryResource(pQry, pShowReportsInBeds, pRoomType = Undefined)
	vVacant = 0;
	If pRoomType = Undefined Then
		If pShowReportsInBeds Then
			vVacant = pQry.Total("BedsVacant");
		Else
			vVacant = pQry.Total("RoomsVacant");
		EndIf;
	Else
		If pRoomType.IsFolder Then
			For Each vRow In pQry Do
				If vRow.RoomType.BelongsToItem(pRoomType) Then
					If pShowReportsInBeds Then
						vVacant = vVacant + vRow.BedsVacant;
					Else
						vVacant = vVacant + vRow.RoomsVacant;
					EndIf;
				EndIf;
			EndDo;
		Else
			For Each vRow In pQry Do
				If pRoomType = vRow.RoomType Then
					If pShowReportsInBeds Then
						vVacant = vVacant + vRow.BedsVacant;
					Else
						vVacant = vVacant + vRow.RoomsVacant;
					EndIf;
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	Return vVacant;
EndFunction // GetRoomsQueryResource

// -----------------------------------------------------------------------------
Procedure pmGenerate(vSpreadsheet, pHeader) Export
	// Initialize number of days to output and period
	NumberOfDays = ?(NumberOfDays <= 0, 28, NumberOfDays);
	vNumberOfDays = NumberOfDays;
	vDateFrom = BegOfDay(DateFrom);
	vCurrentDateTime = ?(vDateFrom = BegOfDay(CurrentSessionDate()), CurrentSessionDate(), vDateFrom);
	vCurrentDate = BegOfDay(vCurrentDateTime);
	vDateTimeFrom = ?(vDateFrom = vCurrentDate, vCurrentDateTime, vDateFrom);
	vDateTo = vDateFrom + 24*3600*(vNumberOfDays - 1);
	vDateTimeTo = EndOfDay(vDateTo);
	vShowReportsInBeds = ShowInBeds;
	
	// Show progress bar
	ProgressForm = GetCommonForm("Progress");
	ProgressForm.Open();
	ProgressForm.Value = 0;
	ProgressForm.MaxValue = 0;
	If vShowReportsInBeds Then
		ProgressForm.ActionRemarks = NStr("en='Vacant beds';ru='Свободные места';de='Freie Betten'");
	Else
		ProgressForm.ActionRemarks = NStr("en='Vacant rooms';ru='Свободные номера';de='Freie Zimmer'");
	EndIf;
	ProgressForm.ValueRemarks = NStr("en='Run query';ru='Выполнение запроса';de='Ausführung einer Nachfrage'");
	
	// Get active events
	vEvents = cmGetEvents(vDateTimeFrom, vDateTimeTo, Hotel);
	
	// Build and run query with room inventory balances
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInventoryBalance.Period AS Period,
	|	RoomInventoryBalance.Hotel AS Hotel,
	|	RoomInventoryBalance.RoomType AS RoomType,
	|	RoomInventoryBalance.CounterClosingBalance AS CounterClosingBalance,
	|	RoomInventoryBalance.RoomsVacantClosingBalance AS RoomsVacant,
	|	RoomInventoryBalance.BedsVacantClosingBalance AS BedsVacant,
	|	RoomInventoryBalance.Hotel.SortCode AS HotelSortCode,
	|	RoomInventoryBalance.RoomType.SortCode AS RoomTypeSortCode
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|			&qDateTimeFrom,
	|			&qDateTimeTo,
	|			Hour,
	|			RegisterRecordsAndPeriodBoundaries,
	|			&qHotelIsEmpty
	|				OR NOT &qHotelIsEmpty
	|					AND Hotel IN HIERARCHY (&qHotel)) AS RoomInventoryBalance
	|WHERE
	|	NOT RoomInventoryBalance.RoomType.DeletionMark
	|
	|ORDER BY
	|	HotelSortCode,
	|	RoomTypeSortCode,
	|	Period
	|TOTALS
	|	SUM(CounterClosingBalance),
	|	SUM(RoomsVacant),
	|	SUM(BedsVacant)
	|BY
	|	Hotel HIERARCHY,
	|	RoomType HIERARCHY,
	|	Period PERIODS(HOUR, &qDateTimeFrom, &qDateTimeTo)";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qDateTimeFrom", vDateTimeFrom);
	vQry.SetParameter("qDateTimeTo", vDateTimeTo);
	vQryRes = vQry.Execute();
	
	// Fill end of day balances and periods
	vPeriods = New ValueList();
	vEndOfDayBalances = New Map();
	vQryHotels = vQryRes.Select(QueryResultIteration.ByGroups, "Hotel");
	While vQryHotels.Next() Do
		// Save all periods where vacant resource is changed
		vLastVacant = Undefined;
		vQryHours = vQryHotels.Select(QueryResultIteration.ByGroups, "Period", "ALL");
		While vQryHours.Next() Do
			vPeriod = vQryHours.Period;
			If (vPeriod < vDateTimeFrom) Or (vPeriod > vDateTimeTo) Then
				Continue;
			EndIf;
			vBegOfDay = BegOfDay(vPeriod);
			vVacant = GetQueryResource(vQryHours, vShowReportsInBeds, vLastVacant);
			If vLastVacant = Undefined Or 
			   vLastVacant <> vVacant Or
			   vPeriod = (vBegOfDay + 23*3600) Then
				vLastVacant = vVacant;
				If vPeriods.FindByValue(vPeriod) = Undefined Then
					vPeriods.Add(vPeriod); 
				EndIf;
			EndIf;
		EndDo;
		// Process room types
		vQryRoomTypes = vQryHotels.Select(QueryResultIteration.ByGroups, "RoomType");
		While vQryRoomTypes.Next() Do
			// Save all periods where vacant resource is changed and save periods where last change per day took place
			vLastVacant = Undefined;
			vQryHours = vQryRoomTypes.Select(QueryResultIteration.ByGroups, "Period", "ALL");
			While vQryHours.Next() Do
				vPeriod = vQryHours.Period;
				If (vPeriod < vDateTimeFrom) Or (vPeriod > vDateTimeTo) Then
					Continue;
				EndIf;
				vBegOfDay = BegOfDay(vPeriod);
				vVacant = GetQueryResource(vQryHours, vShowReportsInBeds, vLastVacant);
				If vLastVacant = Undefined Or 
				   vLastVacant <> vVacant Or
				   vPeriod = (vBegOfDay + 23*3600) Then
					vLastVacant = vVacant;
					If vPeriods.FindByValue(vPeriod) = Undefined Then
						vPeriods.Add(vPeriod); 
					EndIf;
				EndIf;
				If vPeriod = (vBegOfDay + 23*3600) Then
					vKey = GetPeriodHash(vQryHotels.Hotel, vQryRoomTypes.RoomType, vBegOfDay);
					If vShowReportsInBeds Then
						vEndOfDayBalances.Insert(vKey, vQryHours.BedsVacant);
					Else
						vEndOfDayBalances.Insert(vKey, vQryHours.RoomsVacant);
					EndIf;
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	// Sort periods chronologically
	vPeriods.SortByValue();	
	
	// Fill table of first periods per day
	vFirstPeriodsPerDays = New ValueTable();
	vFirstPeriodsPerDays.Columns.Add("BegOfDay", cmGetDateTimeTypeDescription());
	vFirstPeriodsPerDays.Columns.Add("Period", cmGetDateTimeTypeDescription());
	vHourOnTime = Hour(OnTime);
	For Each vPeriodItem In vPeriods Do
		vPeriod = vPeriodItem.Value;
		vBegOfDay = BegOfDay(vPeriod);
		vRow = vFirstPeriodsPerDays.Find(vBegOfDay, "BegOfDay");
		If vHourOnTime <> 23 Then
			If Hour(vPeriod) <= vHourOnTime Then
				If vRow = Undefined Then
					vRow = vFirstPeriodsPerDays.Add();
					vRow.BegOfDay = vBegOfDay;
				EndIf;
				vRow.Period = vPeriod;
			Else
				If vRow = Undefined Then
					vRow = vFirstPeriodsPerDays.Add();
					vRow.BegOfDay = vBegOfDay;
					vRow.Period = vPeriod;
				EndIf;
			EndIf;
		Else
			If vRow = Undefined Then
				vRow = vFirstPeriodsPerDays.Add();
				vRow.BegOfDay = vBegOfDay;
				vRow.Period = vPeriod;
			EndIf;
		EndIf;
	EndDo;
	
	// Show progress status
	ProgressForm.ValueRemarks  = NStr("en='Draw header';ru='Построение заголовка отчета';de='Konstruktion der Überschrift des Berichts'");

	// Draw header
	vSpreadsheet.Clear();
	vSpreadsheet.ShowGroups = True;
	
	vTemplate = GetTemplate("Report");
	vArea = vTemplate.GetArea("Header|NamesColumn");
	If vShowReportsInBeds Then
		pHeader.Caption = NStr("en='Vacant beds &on:';ru='Свободные места &на:';de='Freie Betten &für:'");
	Else
		pHeader.Caption = NStr("en='Vacant rooms &on:';ru='Свободные номера &на:';de='Freie Zimmer &für:'");
	EndIf;
	If vShowReportsInBeds Then
		vArea.Parameters.mHeader1 = NStr("en='Vacant beds';ru='Свободные места';de='Freie Betten'");
	Else
		vArea.Parameters.mHeader1 = NStr("en='Vacant rooms';ru='Свободные номера';de='Freie Zimmer'");
	EndIf;
	vArea.Parameters.mHeader2 = NStr("en='on ';ru='на ';de='für '") + Format(OnTime, "DF=HH:mm");
	vArea.Parameters.mHeader3 = "";
	vArea.Parameters.mHeader4 = "";
	vSpreadsheet.Put(vArea);

	vEndOfPrevDay = False;
	vDayGroup = False;
	vLastDate = Undefined;
	For Each vPeriodItem In vPeriods Do
		vPeriod = vPeriodItem.Value;
		vCurDate = BegOfDay(vPeriod);
		vCurHour = Hour(vPeriod);
		If vLastDate = Undefined Or vCurDate <> vLastDate Then
			vLastDate = vCurDate;
			vEndOfPrevDay = True;
		EndIf;
		mDay = Day(vCurDate);
		mDayOfWeek = cmGetDayOfWeekName(WeekDay(vCurDate), True);
		mMonth = Format(vPeriod, "DF=MMMM");
		If BegOfMonth(vCurDate) = BegOfMonth(DateFrom) Then
			mMonth = mMonth + " " + Format(vPeriod, "DF=yyyy");
		EndIf;
		vGroupName = Format(vCurDate, NStr("ru = 'L=ru; DLF=DD'; en = 'L=en; DLF=DD'"));
		
		// Check should we print this period
		vFirstHourPerDay = 23;
		If vHourOnTime <> 23 Then
			vRow = vFirstPeriodsPerDays.Find(vCurDate, "BegOfDay");
			If vRow <> Undefined Then
				If vRow.Period > vPeriod Then
					Continue;
				EndIf;
			Else
				Continue;
			EndIf;
			vFirstHourPerDay = Hour(vRow.Period);
		EndIf;
		
		vCloseColumnGroup = False;
		If vEndOfPrevDay Then
			vEndOfPrevDay = False;
			If Not vDayGroup Then
				If vHourOnTime = 23 Then
					If vCurHour <> 23 Then
						vSpreadsheet.StartColumnGroup(vGroupName, False);
						vDayGroup = True;
					EndIf;
				Else
					If vCurHour > vHourOnTime And vCurHour > vFirstHourPerDay Then
						vSpreadsheet.StartColumnGroup(vGroupName, False);
						vDayGroup = True;
					EndIf;
				EndIf;
			EndIf;
			If vCurDate = BegOfMonth(vCurDate) Or vCurDate = vDateFrom Then
				If vCurHour = 23 Then
					vArea = vTemplate.GetArea("Header|LastFirstDayOfMonth");
				Else
					vArea = vTemplate.GetArea("Header|FirstDayOfMonth");
				EndIf;
				vArea.Parameters.mMonth = mMonth;
			ElsIf WeekDay(vCurDate) = 1 Then
				If vCurHour = 23 Then
					vArea = vTemplate.GetArea("Header|LastFirstDayOfWeek");
				Else
					vArea = vTemplate.GetArea("Header|FirstDayOfWeek");
				EndIf;
			Else
				If vCurHour = 23 Then
					vArea = vTemplate.GetArea("Header|LastFirstHourOfDay");
				Else
					vArea = vTemplate.GetArea("Header|FirstHourOfDay");
				EndIf;
			EndIf;
			vArea.Parameters.mDay = mDay;
			vArea.Parameters.mDayOfWeek = mDayOfWeek;
		Else
			If vCurHour = 23 Then
				If vHourOnTime <> 23 Then
					If Not vDayGroup And vFirstHourPerDay <> 23 Then
						vSpreadsheet.StartColumnGroup(vGroupName, False);
						vDayGroup = True;
					EndIf;
					vCloseColumnGroup = True;
				Else
					If vDayGroup Then
						vSpreadsheet.EndColumnGroup();
						vDayGroup = False;
					EndIf;
				EndIf;
				If vCurDate = BegOfDay(EndOfMonth(vCurDate)) Then
					vArea = vTemplate.GetArea("Header|LastDayOfMonth");
				ElsIf WeekDay(vCurDate) = 7 Then
					vArea = vTemplate.GetArea("Header|LastDayOfWeek");
				Else
					vArea = vTemplate.GetArea("Header|LastHourOfDay");
				EndIf;
			Else
				If Not vDayGroup Then
					If vHourOnTime <> 23 Then
						If vCurHour > vHourOnTime And vCurHour > vFirstHourPerDay Then
							vSpreadsheet.StartColumnGroup(vGroupName, False);
							vDayGroup = True;
						EndIf;
					EndIf;
				EndIf;
				vArea = vTemplate.GetArea("Header|Day");
			EndIf;
		EndIf;
		vArea.Parameters.mHour = ?(vCurHour=23, "", Format(vCurHour+1, "ND=2; NZ=; NLZ=")+":00");
		vSpreadsheet.Join(vArea);
		If vCloseColumnGroup Then
			If vDayGroup Then
				vSpreadsheet.EndColumnGroup();
				vDayGroup = False;
			EndIf;
		EndIf;
	EndDo;
	
	// Show progress status
	ProgressForm.ValueRemarks = NStr("en='Draw report data. Events.';ru='Вывод данных. Мероприятия.';de='Output von Daten. Veranstaltungen.'");

	// Output events
	If vEvents.Count() > 0 Then
		vArea = vTemplate.GetArea("EventRow|NamesColumn");
		vSpreadsheet.Put(vArea);
		
		vEventsRow = Undefined;
		vEndOfPrevDay = False;
		vLastDate = Undefined;
		vCommentIsPlaced = False;
		For Each vPeriodItem In vPeriods Do
			vPeriod = vPeriodItem.Value;
			vCurDate = BegOfDay(vPeriod);
			vCurHour = Hour(vPeriod);
			If vLastDate = Undefined Or vCurDate <> vLastDate Then
				vLastDate = vCurDate;
				vEndOfPrevDay = True;
			EndIf;
			
			// Check should we print this period
			vFirstHourPerDay = 23;
			If vHourOnTime <> 23 Then
				vRow = vFirstPeriodsPerDays.Find(vCurDate, "BegOfDay");
				If vRow <> Undefined Then
					If vRow.Period > vPeriod Then
						Continue;
					EndIf;
				Else
					Continue;
				EndIf;
				vFirstHourPerDay = Hour(vRow.Period);
			EndIf;
			
			// Try to find event starting from this date
			vThisIsFirstPeriodOfEvent = False;
			vProbeEventsRow = vEvents.Find(vCurDate, "DateFrom");
			If vProbeEventsRow <> Undefined Then
				If vEventsRow = Undefined Then
					vEventsRow = vProbeEventsRow;
					vThisIsFirstPeriodOfEvent = True;
					vCommentIsPlaced = False;
				Else
					If vEventsRow <> vProbeEventsRow Then
						vEventsRow = vProbeEventsRow;
						vThisIsFirstPeriodOfEvent = True;
						vCommentIsPlaced = False;
					EndIf;
				EndIf;
			EndIf;
			
			vAreaRowName = "NoEventRow";
			If vEventsRow <> Undefined Then
				If vCurDate > vEventsRow.DateTo Or vCurDate < vEventsRow.DateFrom Then
					vEventsRow = Undefined;
				Else
					vAreaRowName = "EventRow";
				EndIf;
			EndIf;
			
			If vEndOfPrevDay Then
				vEndOfPrevDay = False;
				If vCurDate = BegOfMonth(vCurDate) Or vCurDate = vDateFrom Then
					If vCurHour = 23 Then
						vArea = vTemplate.GetArea(vAreaRowName + "|LastFirstDayOfMonth");
					Else
						vArea = vTemplate.GetArea(vAreaRowName + "|FirstDayOfMonth");
					EndIf;
				ElsIf WeekDay(vCurDate) = 1 Then
					If vCurHour = 23 Then
						vArea = vTemplate.GetArea(vAreaRowName + "|LastFirstDayOfWeek");
					Else
						vArea = vTemplate.GetArea(vAreaRowName + "|FirstDayOfWeek");
					EndIf;
				Else
					If vCurHour = 23 Then
						vArea = vTemplate.GetArea(vAreaRowName + "|LastFirstHourOfDay");
					Else
						vArea = vTemplate.GetArea(vAreaRowName + "|FirstHourOfDay");
					EndIf;
				EndIf;
			Else
				If vCurHour = 23 Then
					If vCurDate = BegOfDay(EndOfMonth(vCurDate)) Then
						vArea = vTemplate.GetArea(vAreaRowName + "|LastDayOfMonth");
					ElsIf WeekDay(vCurDate) = 7 Then
						vArea = vTemplate.GetArea(vAreaRowName + "|LastDayOfWeek");
					Else
						vArea = vTemplate.GetArea(vAreaRowName + "|LastHourOfDay");
					EndIf;
				Else
					vArea = vTemplate.GetArea(vAreaRowName + "|Day");
				EndIf;
			EndIf;
			If vEventsRow <> Undefined And vAreaRowName = "EventRow" Then
				If vThisIsFirstPeriodOfEvent Then
					vArea.Parameters.mEventDescription = TrimAll(vEventsRow.Description);
				Else
					vArea.Parameters.mEventDescription = "";
				EndIf;
				vArea.Parameters.mEvent = vEventsRow.Ref;
			ElsIf vAreaRowName = "NoEventRow" Then
				vArea.Parameters.mEvent = Catalogs.Events.EmptyRef();
			EndIf;
			vOutputArea = vSpreadsheet.Join(vArea);
			If vEventsRow <> Undefined And vAreaRowName = "EventRow" Then
				vEventColor = Undefined;
				If vEventsRow.Color <> Undefined Then
					vEventColor = vEventsRow.Color.Get();
				EndIf;
				If vEventColor <> Undefined Then
					vOutputArea.BackColor = vEventColor;
				EndIf;
				vOutputArea.RightBorder = New Line(SpreadsheetDocumentCellLineType.None, 1);
				If Not vThisIsFirstPeriodOfEvent Then
					vOutputArea.LeftBorder = New Line(SpreadsheetDocumentCellLineType.None, 1);
					vOutputArea.Clear(True);
				EndIf;
				If vEventsRow.DateTo = BegOfDay(vCurDate) And Not vCommentIsPlaced Then
					vCommentIsPlaced = True;
					vOutputArea.Comment.Text = Chars.LF + Chars.LF + TrimAll(Format(vEventsRow.DateFrom, "DF=dd.MM.yyyy") + " - " + Format(vEventsRow.DateTo, "DF=dd.MM.yyyy") + Chars.LF +
											   TrimAll(vEventsRow.Remarks));
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	// Show progress status
	ProgressForm.ValueRemarks = NStr("en='Draw report data. Hotel totals.';ru='Вывод данных. Итог по гостинице.';de='Output von Daten. Ergebnis nach Hotel.'");
	
	// Count maximum value for progress bar
	vNHotels = vQryRes.Select(QueryResultIteration.ByGroups, "Hotel").Count();
	vNRoomTypes = vQryRes.Select(QueryResultIteration.ByGroups, "RoomType").Count();
	vNHours = 1;
	If vQryRoomTypes <> Undefined Then
		vNHours = vQryRoomTypes.Select(QueryResultIteration.ByGroups, "Period", "ALL").Count();
	EndIf;
	ProgressForm.MaxValue = vNHotels*vNRoomTypes;
	vProgressValue = 1;
	
	// Build report form
	vQryHotels = vQryRes.Select(QueryResultIteration.ByGroups, "Hotel");
	While vQryHotels.Next() Do
		// Show hotel
		vArea = vTemplate.GetArea("HotelRow|NamesColumn");
		vArea.Parameters.mHotel = vQryHotels.Hotel;
		vSpreadsheet.Put(vArea);
		
		// Show hotel totals by days and hours
		vEndOfPrevDay = False;
		vLastDate = Undefined;
		vLastVacant = 0;
		vCommentHour = 0;
		vQryHours = vQryHotels.Select(QueryResultIteration.ByGroups, "Period", "ALL");
		While vQryHours.Next() Do
			vPeriod = vQryHours.Period;
			If (vPeriod < vDateTimeFrom) Or (vPeriod > vDateTimeTo) Then
				Continue;
			EndIf;
			If vPeriods.FindByValue(vPeriod) = Undefined Then
				Continue;
			EndIf;
			
			vCurDate = BegOfDay(vPeriod);
			vCurHour = Hour(vPeriod);
			If vLastDate = Undefined Or vCurDate <> vLastDate Then
				vLastDate = vCurDate;
				vEndOfPrevDay = True;
			EndIf;
			
			// Check should we print this period
			If vHourOnTime <> 23 Then
				vRow = vFirstPeriodsPerDays.Find(vCurDate, "BegOfDay");
				If vRow <> Undefined Then
					If vRow.Period > vPeriod Then
						Continue;
					EndIf;
				Else
					Continue;
				EndIf;
			EndIf;
			
			// Get necessary report template area
			If vEndOfPrevDay Then
				vEndOfPrevDay = False;
				If vCurDate = BegOfMonth(vCurDate) Or vCurDate = vDateFrom Then
					If vCurHour = 23 Then
						vArea = vTemplate.GetArea("HotelRow|LastFirstDayOfMonth");
					Else
						vArea = vTemplate.GetArea("HotelRow|FirstDayOfMonth");
					EndIf;
				ElsIf WeekDay(vCurDate) = 1 Then
					If vCurHour = 23 Then
						vArea = vTemplate.GetArea("HotelRow|LastFirstDayOfWeek");
					Else
						vArea = vTemplate.GetArea("HotelRow|FirstDayOfWeek");
					EndIf;
				Else
					If vCurHour = 23 Then
						vArea = vTemplate.GetArea("HotelRow|LastFirstHourOfDay");
					Else
						vArea = vTemplate.GetArea("HotelRow|FirstHourOfDay");
					EndIf;
				EndIf;
			Else
				If vCurHour = 23 Then
					If vCurDate = BegOfDay(EndOfMonth(vCurDate)) Then
						vArea = vTemplate.GetArea("HotelRow|LastDayOfMonth");
					ElsIf WeekDay(vCurDate) = 7 Then
						vArea = vTemplate.GetArea("HotelRow|LastDayOfWeek");
					Else
						vArea = vTemplate.GetArea("HotelRow|LastHourOfDay");
					EndIf;
				Else
					vArea = vTemplate.GetArea("HotelRow|Day");
				EndIf;
			EndIf;
			
			// Fill parameters and join area
			vArea.Parameters.mVacant = GetQueryResource(vQryHours, vShowReportsInBeds, vLastVacant);
			vArea.Parameters.mDetails = New Structure("Hotel, RoomType, PeriodTo", 
			                                           vQryHotels.Hotel, 
			                                           Catalogs.RoomTypes.EmptyRef(), 
			                                           vPeriod);
			If vArea.Parameters.mVacant < 0 Then
				vCell = vArea.Area(1,1,1,1);
				vCell.TextColor = WebColors.Red;
			EndIf;
			vSpreadsheet.Join(vArea);
			
			vLastVacant = vArea.Parameters.mVacant;
		EndDo;
		
		// Show room types for this hotel
		vQryRoomTypes = vQryHotels.Select(QueryResultIteration.ByGroups, "RoomType");
		While vQryRoomTypes.Next() Do
			// Show progress status
			ProgressForm.ValueRemarks  = NStr("ru = 'Вывод данных по типу номера: '; en = 'Draw report data. Room type: '") + TrimR(vQryRoomTypes.RoomType.Description);
			ProgressForm.Value = vProgressValue;
			vProgressValue = vProgressValue + 1;
			
			// Show room type
			vAreaCol = "RoomTypeRow";
			If vQryRoomTypes.RoomType.IsFolder Then
				vAreaCol = "RoomTypeFolderRow";
			EndIf;
			vArea = vTemplate.GetArea(vAreaCol + "|NamesColumn");
			If vQryRoomTypes.RoomType.IsFolder Then
				vArea.Parameters.mRoomType = cmGetIndent(vQryRoomTypes.RoomType, +1) + TrimR(vQryRoomTypes.RoomType.Description);
			Else
				vArea.Parameters.mRoomType = cmGetIndent(vQryRoomTypes.RoomType, +1) + TrimR(vQryRoomTypes.RoomType.Code);
			EndIf;
			vSpreadsheet.Put(vArea);
			
			// Show room type totals by days
			vLastVacant = 0;
			vCommentHour = 0;
			vEndOfPrevDay = False;
			vLastDate = Undefined;
			vQryHours = vQryRoomTypes.Select(QueryResultIteration.ByGroups, "Period", "ALL");
			While vQryHours.Next() Do
				vPeriod = vQryHours.Period;
				If (vPeriod < vDateTimeFrom) Or (vPeriod > vDateTimeTo) Then
					Continue;
				EndIf;
				If vPeriods.FindByValue(vPeriod) = Undefined Then
					Continue;
				EndIf;
				
				vCurDate = BegOfDay(vPeriod);
				vCurHour = Hour(vPeriod);
				If vLastDate = Undefined Or vCurDate <> vLastDate Then
					vLastDate = vCurDate;
					vEndOfPrevDay = True;
				EndIf;
				
				// Check should we print this period
				If vHourOnTime <> 23 Then
					vRow = vFirstPeriodsPerDays.Find(vCurDate, "BegOfDay");
					If vRow <> Undefined Then
						If vRow.Period > vPeriod Then
							Continue;
						EndIf;
					Else
						Continue;
					EndIf;
				EndIf;
				
				// Check room type stop sale
				vStopSaleRemarks = "";
				vAreaCol = "RoomTypeRow";
				If vQryRoomTypes.RoomType.IsFolder Then
					vAreaCol = "RoomTypeFolderRow";
				Else
					If vQryRoomTypes.RoomType.StopSale Then
						If cmIsStopSalePeriod(vQryRoomTypes.RoomType, vPeriod, vPeriod, vStopSaleRemarks) Then
							vAreaCol = "RoomTypeStopSaleRow";
						EndIf;
					EndIf;
				EndIf;
				
				// Get necessary report template area
				If vEndOfPrevDay Then
					vEndOfPrevDay = False;
					If vCurDate = BegOfMonth(vCurDate) Or vCurDate = vDateFrom Then
						If vCurHour = 23 Then
							vArea = vTemplate.GetArea(vAreaCol + "|LastFirstDayOfMonth");
						Else
							vArea = vTemplate.GetArea(vAreaCol + "|FirstDayOfMonth");
						EndIf;
					ElsIf WeekDay(vCurDate) = 1 Then
						If vCurHour = 23 Then
							vArea = vTemplate.GetArea(vAreaCol + "|LastFirstDayOfWeek");
						Else
							vArea = vTemplate.GetArea(vAreaCol + "|FirstDayOfWeek");
						EndIf;
					Else
						If vCurHour = 23 Then
							vArea = vTemplate.GetArea(vAreaCol + "|LastFirstHourOfDay");
						Else
							vArea = vTemplate.GetArea(vAreaCol + "|FirstHourOfDay");
						EndIf;
					EndIf;
					// Reset comment on first period of a day
					vCommentHour = 0;
				Else
					If vCurHour = 23 Then
						If vCurDate = BegOfDay(EndOfMonth(vCurDate)) Then
							vArea = vTemplate.GetArea(vAreaCol + "|LastDayOfMonth");
						ElsIf WeekDay(vCurDate) = 7 Then
							vArea = vTemplate.GetArea(vAreaCol + "|LastDayOfWeek");
						Else
							vArea = vTemplate.GetArea(vAreaCol + "|LastHourOfDay");
						EndIf;
					Else
						vArea = vTemplate.GetArea(vAreaCol + "|Day");
					EndIf;
				EndIf;
				//Set weekend backgroud color
				If WeekDay(vCurDate) = 7 OR WeekDay(vCurDate) = 6 Then
					vArea = vTemplate.GetArea(vAreaCol + "|LastDayOfWeek");
				EndIf;

				// Set area parameters
				vVacant = GetQueryResource(vQryHours, vShowReportsInBeds, vLastVacant);
				vArea.Parameters.mVacant = vVacant;
				vArea.Parameters.mDetails = New Structure("Hotel, RoomType, PeriodTo", 
				                                           vQryHotels.Hotel, 
				                                           vQryRoomTypes.RoomType, 
				                                           vPeriod);
				If vArea.Parameters.mVacant < 0 Then
					vCell = vArea.Area(1,1,1,1);
					vCell.TextColor = WebColors.Red;
				EndIf;
				
				// Check should we add comment with time when vacant rooms became available
				If vCurHour >= 11 And vCurHour <= 23 Then
					vKey = GetPeriodHash(vQryHotels.Hotel, vQryRoomTypes.RoomType, vCurDate);
					vEndOfDayBalance = vEndOfDayBalances.Get(vKey);
					If vEndOfDayBalance <> Undefined Then
						If vVacant < vEndOfDayBalance Then
							vCommentHour = -1;
						ElsIf vVacant = vEndOfDayBalance Then
							If vCurHour > 12 Then
								If vCommentHour = -1 Then
									vCommentHour = vCurHour;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
				If vCurHour = 23 Then
					If vCommentHour > 0 Then
						vComment = Format(vCommentHour+1, "ND=2; NLZ=") + ":00";
						vArea.Area("T").Comment.Text = vComment;
					EndIf;
				EndIf;
				If Not IsBlankString(vStopSaleRemarks) Then
					vArea.Area("T").Comment.Text = TrimAll(vArea.Area("T").Comment.Text) + ?(IsBlankString(vArea.Area("T").Comment.Text), "", Chars.LF) + vStopSaleRemarks;
				EndIf;
				
				// Join template area to the report
				vSpreadsheet.Join(vArea);
				
				vLastVacant = vVacant;
			EndDo;
		EndDo;
	EndDo;
	If ProgressForm.IsOpen() Then
		ProgressForm.Close();
	EndIf;
	
	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Landscape);
	
	// Set report protection
	cmSetSpreadsheetProtection(vSpreadsheet);
	
	// Set report header
	cmApplyReportHeader(vSpreadsheet);
	// Add configuration name to the right report header
	vSpreadsheet.Header.LeftText = ?(ValueIsFilled(SessionParameters.CurrentHotel), 
									 SessionParameters.CurrentHotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage), "") + " - " + 
									TrimAll(SessionParameters.ConfigurationPresentation);
	vSpreadsheet.Header.RightText = TrimAll(SessionParameters.CurrentUser) + " - " + Format(CurrentSessionDate(), "DF='dd.MM.yyyy HH:mm'");
	// Set footer
	cmApplyReportFooter(vSpreadsheet);
	
	// Fix report header and room type codes
	vSpreadsheet.FixedTop = 4;
	//vSpreadsheet.FixedLeft = 2;
EndProcedure // pmGenerate

// -----------------------------------------------------------------------------
Procedure pmGenerateByDuration(vSpreadsheet, pHeader) Export
	// Initialize number of days to output and period
	NumberOfDays = ?(NumberOfDays <= 0, 28, NumberOfDays);
	vNumberOfDays = NumberOfDays;
	vDateFrom = BegOfDay(DateFrom);
	vCurrentDate = BegOfDay(CurrentSessionDate());
	vCurrentDateTime = ?(vDateFrom = BegOfDay(CurrentSessionDate()), CurrentSessionDate(), vDateFrom);
	vDateTimeFrom = ?(vDateFrom = vCurrentDate, vCurrentDateTime, vDateFrom);
	vDateTo = vDateFrom + 24*3600*(vNumberOfDays - 1);
	vDateTimeTo = EndOfDay(vDateTo);
	vShowReportsInBeds = ShowInBeds;
	
	// Show progress bar
	ProgressForm = GetCommonForm("Progress");
	ProgressForm.Open();
	ProgressForm.Value = 0;
	ProgressForm.MaxValue = 0;
	If vShowReportsInBeds Then
		ProgressForm.ActionRemarks = NStr("en='Vacant beds';ru='Свободные места';de='Freie Betten'");
	Else
		ProgressForm.ActionRemarks = NStr("en='Vacant rooms';ru='Свободные номера';de='Freie Zimmer'");
	EndIf;
	ProgressForm.ValueRemarks = NStr("en='Run query';ru='Выполнение запроса';de='Ausführung einer Nachfrage'");
	
	// Get active events
	vEvents = cmGetEvents(vDateTimeFrom, vDateTimeTo, Hotel);
	
	// Build and run query with room inventory balances
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInventoryBalance.Hotel AS Hotel,
	|	RoomInventoryBalance.RoomType AS RoomType,
	|	BEGINOFPERIOD(DATEADD(RoomInventoryBalance.Period, SECOND, &qShiftInSeconds), DAY) AS Period,
	|	MIN(ISNULL(RoomInventoryBalance.CounterClosingBalance, 0)) AS CounterClosingBalance,
	|	MIN(ISNULL(RoomInventoryBalance.RoomsVacantClosingBalance, 0)) AS RoomsVacant,
	|	MIN(ISNULL(RoomInventoryBalance.BedsVacantClosingBalance, 0)) AS BedsVacant
	|INTO RoomInventoryDailyBalance
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|			&qDateTimeFrom,
	|			&qDateTimeTo,
	|			Minute,
	|			RegisterRecordsAndPeriodBoundaries,
	|			&qHotelIsEmpty
	|				OR NOT &qHotelIsEmpty
	|					AND Hotel IN HIERARCHY (&qHotel)) AS RoomInventoryBalance
	|
	|GROUP BY
	|	RoomInventoryBalance.Hotel,
	|	RoomInventoryBalance.RoomType,
	|	BEGINOFPERIOD(DATEADD(RoomInventoryBalance.Period, SECOND, &qShiftInSeconds), DAY)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventoryDailyBalance.Hotel AS Hotel,
	|	RoomInventoryDailyBalance.RoomType AS RoomType,
	|	RoomInventoryDailyBalance.Period AS Period,
	|	RoomInventoryDailyBalance.Hotel.SortCode AS HotelSortCode,
	|	RoomInventoryDailyBalance.RoomType.SortCode AS RoomTypeSortCode,
	|	RoomInventoryDailyBalance.RoomsVacant AS RoomsVacant,
	|	RoomInventoryDailyBalance.BedsVacant AS BedsVacant
	|FROM
	|	RoomInventoryDailyBalance AS RoomInventoryDailyBalance
	|WHERE
	|	NOT RoomInventoryDailyBalance.RoomType.DeletionMark
	|
	|ORDER BY
	|	HotelSortCode,
	|	RoomTypeSortCode,
	|	Period
	|TOTALS
	|	SUM(RoomsVacant),
	|	SUM(BedsVacant)
	|BY
	|	Hotel HIERARCHY,
	|	RoomType HIERARCHY,
	|	Period PERIODS(DAY, &qDateTimeFrom, &qDateTimeTo)";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qShiftInSeconds", ?(ValueIsFilled(Hotel) And ValueIsFilled(Hotel.RoomRate) And ValueIsFilled(Hotel.RoomRate.ReferenceHour), -(Hotel.RoomRate.ReferenceHour - BegOfDay(Hotel.RoomRate.ReferenceHour)), -43200));
	vQry.SetParameter("qDateTimeFrom", vDateTimeFrom);
	vQry.SetParameter("qDateTimeTo", vDateTimeTo);
	vQryRes = vQry.Execute();
	
	// Initialize query by rooms
	vQryByRooms = New Query();
	vQryByRooms.Text = 
	"SELECT
	|	RoomsBalance.Hotel AS Hotel,
	|	RoomsBalance.RoomType AS RoomType,
	|	RoomsBalance.RoomsVacant AS RoomsVacant,
	|	RoomsBalance.BedsVacant AS BedsVacant
	|FROM
	|	(SELECT
	|		RoomsBalanceByRooms.Hotel AS Hotel,
	|		RoomsBalanceByRooms.RoomType AS RoomType,
	|		SUM(RoomsBalanceByRooms.RoomsVacant) AS RoomsVacant,
	|		SUM(RoomsBalanceByRooms.BedsVacant) AS BedsVacant
	|	FROM
	|		(SELECT
	|			RoomInventoryRoomsBalance.Hotel AS Hotel,
	|			RoomInventoryRoomsBalance.RoomType AS RoomType,
	|			RoomInventoryRoomsBalance.Room AS Room,
	|			MIN(RoomInventoryRoomsBalance.RoomsVacantClosingBalance) AS RoomsVacant,
	|			MIN(RoomInventoryRoomsBalance.BedsVacantClosingBalance) AS BedsVacant
	|		FROM
	|			(SELECT
	|				RoomInventoryRoomsBalanceAndTurnovers.Hotel AS Hotel,
	|				RoomInventoryRoomsBalanceAndTurnovers.RoomType AS RoomType,
	|				RoomInventoryRoomsBalanceAndTurnovers.Room AS Room,
	|				RoomInventoryRoomsBalanceAndTurnovers.Period AS Period,
	|				ISNULL(RoomInventoryRoomsBalanceAndTurnovers.TotalRoomsClosingBalance, 0) AS TotalRoomsClosingBalance,
	|				ISNULL(RoomInventoryRoomsBalanceAndTurnovers.RoomsVacantClosingBalance, 0) AS RoomsVacantClosingBalance,
	|				ISNULL(RoomInventoryRoomsBalanceAndTurnovers.BedsVacantClosingBalance, 0) AS BedsVacantClosingBalance
	|			FROM
	|				AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|						&qDateTimeFrom,
	|						&qDateTimeTo,
	|						Minute,
	|						RegisterRecordsAndPeriodBoundaries,
	|						Hotel IN HIERARCHY (&qHotel)
	|							AND (&qRoomTypeIsEmpty
	|								OR NOT &qRoomTypeIsEmpty
	|									AND RoomType IN HIERARCHY (&qRoomType))) AS RoomInventoryRoomsBalanceAndTurnovers) AS RoomInventoryRoomsBalance
	|		
	|		GROUP BY
	|			RoomInventoryRoomsBalance.Hotel,
	|			RoomInventoryRoomsBalance.RoomType,
	|			RoomInventoryRoomsBalance.Room) AS RoomsBalanceByRooms
	|	
	|	GROUP BY
	|		RoomsBalanceByRooms.Hotel,
	|		RoomsBalanceByRooms.RoomType) AS RoomsBalance
	|WHERE
	|	NOT RoomsBalance.RoomType.DeletionMark
	|
	|ORDER BY
	|	RoomsBalance.Hotel.SortCode,
	|	RoomsBalance.Hotel.Description,
	|	RoomsBalance.RoomType.SortCode,
	|	RoomsBalance.RoomType.Description";
	
	// Show progress status
	ProgressForm.ValueRemarks  = NStr("en='Draw header';ru='Построение заголовка отчета';de='Konstruktion der Überschrift des Berichts'");

	// Draw header
	vSpreadsheet.Clear();
	vSpreadsheet.ShowGroups = True;
	
	vTemplate = GetTemplate("Report");
	vArea = vTemplate.GetArea("Header|NamesColumn");
	If vShowReportsInBeds Then
		pHeader.Caption = NStr("en='Vacant beds for ref. hour:';ru='Своб. места по р/ч:';de='Freie Betten für St.:'");
	Else
		pHeader.Caption = NStr("en='Vacant rooms for ref. hour:';ru='Своб. номера по р/ч:';de='Freie Zimmern für St.:'");
	EndIf;
	If vShowReportsInBeds Then
		vArea.Parameters.mHeader1 = NStr("en='Vacant beds';ru='Свободные места';de='Freie Betten'");
	Else
		vArea.Parameters.mHeader1 = NStr("en='Vacant rooms';ru='Свободные номера';de='Freie Zimmer'");
	EndIf;
	vArea.Parameters.mHeader2 = NStr("en='min. from/to ref. hour ';ru='мин. с/по р/ч ';de='min. von/zu St. '") + Format(OnTime, "DF=HH:mm");
	vArea.Parameters.mHeader3 = NStr("en='Period of stay';ru='Продолжительность проживания';de='Zeitraum dauer'");
	vArea.Parameters.mHeader4 = Format(Duration, "NFD=0; NZ=; NG=") + NStr("en=' days';ru=' дней';de=' Tage'");
	vSpreadsheet.Put(vArea);

	vQryDays = vQryRes.Select(QueryResultIteration.ByGroups, "Period", "ALL");
	While vQryDays.Next() Do
		vPeriod = vQryDays.Period;
		vCurDate = BegOfDay(vPeriod);
		If (?(vDateFrom = vCurrentDate, (vPeriod + 24*3600), vPeriod) < vDateTimeFrom) Or (vPeriod > vDateTimeTo) Then
			Continue;
		EndIf;
	
		mDay = Day(vCurDate);
		mDayOfWeek = cmGetDayOfWeekName(WeekDay(vCurDate), True);
		mMonth = Format(vPeriod, "DF=MMMM");
		If BegOfMonth(vCurDate) = BegOfMonth(DateFrom) Then
			mMonth = mMonth + " " + Format(vPeriod, "DF=yyyy");
		EndIf;
		
		If vCurDate = BegOfMonth(vCurDate) Or vCurDate = vDateFrom Then
			vArea = vTemplate.GetArea("Header|LastFirstDayOfMonth");
			vArea.Parameters.mMonth = mMonth;
		ElsIf WeekDay(vCurDate) = 1 Then
			vArea = vTemplate.GetArea("Header|LastFirstDayOfWeek");
		Else
			vArea = vTemplate.GetArea("Header|LastFirstHourOfDay");
		EndIf;
		vArea.Parameters.mDay = mDay;
		vArea.Parameters.mDayOfWeek = mDayOfWeek;
		vArea.Parameters.mHour = "";
		vSpreadsheet.Join(vArea);
	EndDo;
	
	// Show progress status
	ProgressForm.ValueRemarks = NStr("en='Draw report data. Events.';ru='Вывод данных. Мероприятия.';de='Output von Daten. Veranstaltungen.'");

	// Output events
	If vEvents.Count() > 0 Then
		vArea = vTemplate.GetArea("EventRow|NamesColumn");
		vSpreadsheet.Put(vArea);
		
		vEventsRow = Undefined;
		vCommentIsPlaced = False;
		
		vQryDays = vQryRes.Select(QueryResultIteration.ByGroups, "Period", "ALL");
		While vQryDays.Next() Do
			vPeriod = vQryDays.Period;
			If (?(vDateFrom = vCurrentDate, (vPeriod + 24*3600), vPeriod) < vDateTimeFrom) Or (vPeriod > vDateTimeTo) Then
				Continue;
			EndIf;
			vCurDate = BegOfDay(vPeriod);
			
			// Try to find event starting from this date
			vThisIsFirstPeriodOfEvent = False;
			vProbeEventsRow = vEvents.Find(vCurDate, "DateFrom");
			If vProbeEventsRow <> Undefined Then
				If vEventsRow = Undefined Then
					vEventsRow = vProbeEventsRow;
					vThisIsFirstPeriodOfEvent = True;
					vCommentIsPlaced = False;
				Else
					If vEventsRow <> vProbeEventsRow Then
						vEventsRow = vProbeEventsRow;
						vThisIsFirstPeriodOfEvent = True;
						vCommentIsPlaced = False;
					EndIf;
				EndIf;
			EndIf;
			
			vAreaRowName = "NoEventRow";
			If vEventsRow <> Undefined Then
				If vCurDate > vEventsRow.DateTo Or vCurDate < vEventsRow.DateFrom Then
					vEventsRow = Undefined;
				Else
					vAreaRowName = "EventRow";
				EndIf;
			EndIf;
			
			If vCurDate = BegOfMonth(vCurDate) Or vCurDate = vDateFrom Then
				vArea = vTemplate.GetArea(vAreaRowName + "|LastFirstDayOfMonth");
			ElsIf WeekDay(vCurDate) = 1 Then
				vArea = vTemplate.GetArea(vAreaRowName + "|LastFirstDayOfWeek");
			Else
				vArea = vTemplate.GetArea(vAreaRowName + "|LastFirstHourOfDay");
			EndIf;
			If vEventsRow <> Undefined And vAreaRowName = "EventRow" Then
				If vThisIsFirstPeriodOfEvent Then
					vArea.Parameters.mEventDescription = TrimAll(vEventsRow.Description);
				Else
					vArea.Parameters.mEventDescription = "";
				EndIf;
				vArea.Parameters.mEvent = vEventsRow.Ref;
			ElsIf vAreaRowName = "NoEventRow" Then
				vArea.Parameters.mEvent = Catalogs.Events.EmptyRef();
			EndIf;
			vOutputArea = vSpreadsheet.Join(vArea);
			If vEventsRow <> Undefined And vAreaRowName = "EventRow" Then
				vEventColor = Undefined;
				If vEventsRow.Color <> Undefined Then
					vEventColor = vEventsRow.Color.Get();
				EndIf;
				If vEventColor <> Undefined Then
					vOutputArea.BackColor = vEventColor;
				EndIf;
				vOutputArea.RightBorder = New Line(SpreadsheetDocumentCellLineType.None, 1);
				If Not vThisIsFirstPeriodOfEvent Then
					vOutputArea.LeftBorder = New Line(SpreadsheetDocumentCellLineType.None, 1);
					vOutputArea.Clear(True);
				EndIf;
				If vEventsRow.DateTo = BegOfDay(vCurDate) And Not vCommentIsPlaced Then
					vCommentIsPlaced = True;
					vOutputArea.Comment.Text = Chars.LF + Chars.LF + TrimAll(Format(vEventsRow.DateFrom, "DF=dd.MM.yyyy") + " - " + Format(vEventsRow.DateTo, "DF=dd.MM.yyyy") + Chars.LF +
											   TrimAll(vEventsRow.Remarks));
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	// Show progress status
	ProgressForm.ValueRemarks = NStr("en='Draw report data. Hotel totals.';ru='Вывод данных. Итог по гостинице.';de='Output von Daten. Ergebnis nach Hotel.'");
	
	// Count maximum value for progress bar
	vNHotels = vQryRes.Select(QueryResultIteration.ByGroups, "Hotel").Count();
	vNRoomTypes = vQryRes.Select(QueryResultIteration.ByGroups, "RoomType").Count();
	ProgressForm.MaxValue = vNHotels*NumberOfDays;
	vProgressValue = 1;
	
	// Build report form
	vQryHotels = vQryRes.Select(QueryResultIteration.ByGroups, "Hotel");
	While vQryHotels.Next() Do
		// Show hotel
		vHotel = vQryHotels.Hotel; 
		vArea = vTemplate.GetArea("HotelRow|NamesColumn");
		vArea.Parameters.mHotel = vHotel;
		vSpreadsheet.Put(vArea);
		vShiftInSeconds = 43200;
		If ValueIsFilled(vHotel) And ValueIsFilled(vHotel.RoomRate) And ValueIsFilled(vHotel.RoomRate.ReferenceHour) Then
			vShiftInSeconds = vHotel.RoomRate.ReferenceHour - BegOfDay(vHotel.RoomRate.ReferenceHour);
		EndIf;
		
		// Show hotel totals by days and hours
		vLastVacant = 0;
		vQryDays = vQryHotels.Select(QueryResultIteration.ByGroups, "Period", "ALL");
		While vQryDays.Next() Do
			vPeriod = vQryDays.Period;
			vCurDate = BegOfDay(vPeriod);
			If (?(vDateFrom = vCurrentDate, (vPeriod + 24*3600), vPeriod) < vDateTimeFrom) Or (vPeriod > vDateTimeTo) Then
				Continue;
			EndIf;
			
			// Get necessary report template area
			If vCurDate = BegOfMonth(vCurDate) Or vCurDate = vDateFrom Then
				vArea = vTemplate.GetArea("HotelRow|LastFirstDayOfMonth");
			ElsIf WeekDay(vCurDate) = 1 Then
				vArea = vTemplate.GetArea("HotelRow|LastFirstDayOfWeek");
			Else
				vArea = vTemplate.GetArea("HotelRow|LastFirstHourOfDay");
			EndIf;
			
			// Get vacant rooms/beds for one date
			vVacant = GetQueryResource(vQryDays, vShowReportsInBeds, vLastVacant);
			
			// Show progress status
			ProgressForm.ValueRemarks  = NStr("ru = 'Вывод данных по дате: '; en = 'Draw report data. Date: '; de = 'Zeichnen Sie Berichtsdaten. Datum: '") + Format(vCurDate, "DF=dd.MM.yyyy");
			ProgressForm.Value = vProgressValue;
			vProgressValue = vProgressValue + 1;
			
			// Get number of vacant rooms per several days
			vQryByRoomsRes = Undefined;
			If Duration > 1 Then
				vQryByRooms.SetParameter("qHotel", vHotel);
				vQryByRooms.SetParameter("qRoomType", Catalogs.RoomTypes.EmptyRef());
				vQryByRooms.SetParameter("qRoomTypeIsEmpty", True);
				vQryByRooms.SetParameter("qDateTimeFrom", cm1SecondShift(vCurDate + vShiftInSeconds));
				vQryByRooms.SetParameter("qDateTimeTo", cm0SecondShift(vCurDate + vShiftInSeconds + Duration * 24 * 3600));
				vQryByRoomsRes = vQryByRooms.Execute().Unload();
				vVacantByRooms = GetRoomsQueryResource(vQryByRoomsRes, vShowReportsInBeds);
				If vVacantByRooms <> Null Then
					If vVacant > vVacantByRooms Then
						vVacant = vVacantByRooms;
					EndIf;
				EndIf;
				If vVacant < 0 Then
					vVacant = 0;
				EndIf;
			EndIf;
			
			// Fill report area parameters
			vArea.Parameters.mVacant = vVacant;
			vArea.Parameters.mDetails = New Structure("Hotel, RoomType, PeriodTo", 
			                                           vHotel, 
			                                           Catalogs.RoomTypes.EmptyRef(), 
			                                           EndOfDay(vPeriod));
			If vVacant < 0 Then
				vCell = vArea.Area(1,1,1,1);
				vCell.TextColor = WebColors.Red;
			EndIf;
			vSpreadsheet.Join(vArea);
			
			vLastVacant = vVacant;
		EndDo;
		
		// Show room types for this hotel
		vQryRoomTypes = vQryHotels.Select(QueryResultIteration.ByGroups, "RoomType");
		While vQryRoomTypes.Next() Do
			// Show room type
			vAreaCol = "RoomTypeRow";
			If vQryRoomTypes.RoomType.IsFolder Then
				vAreaCol = "RoomTypeFolderRow";
			EndIf;
			vArea = vTemplate.GetArea(vAreaCol + "|NamesColumn");
			If vQryRoomTypes.RoomType.IsFolder Then
				vArea.Parameters.mRoomType = cmGetIndent(vQryRoomTypes.RoomType, +1) + TrimR(vQryRoomTypes.RoomType.Description);
			Else
				vArea.Parameters.mRoomType = cmGetIndent(vQryRoomTypes.RoomType, +1) + TrimR(vQryRoomTypes.RoomType.Code);
			EndIf;
			vSpreadsheet.Put(vArea);
			
			// Show room type totals by days
			vLastVacant = 0;
			vQryDays = vQryRoomTypes.Select(QueryResultIteration.ByGroups, "Period", "ALL");
			While vQryDays.Next() Do
				vPeriod = vQryDays.Period;
				vCurDate = BegOfDay(vPeriod);
				If (?(vDateFrom = vCurrentDate, (vPeriod + 24*3600), vPeriod) < vDateTimeFrom) Or (vPeriod > vDateTimeTo) Then
					Continue;
				EndIf;
				
				// Check room type stop sale
				vStopSaleRemarks = "";
				vAreaCol = "RoomTypeRow";
				If vQryRoomTypes.RoomType.IsFolder Then
					vAreaCol = "RoomTypeFolderRow";
				Else
					If vQryRoomTypes.RoomType.StopSale Then
						If cmIsStopSalePeriod(vQryRoomTypes.RoomType, vPeriod, vPeriod, vStopSaleRemarks) Then
							vAreaCol = "RoomTypeStopSaleRow";
						EndIf;
					EndIf;
				EndIf;
				
				// Get necessary report template area
				If vCurDate = BegOfMonth(vCurDate) Or vCurDate = vDateFrom Then
					vArea = vTemplate.GetArea(vAreaCol + "|LastFirstDayOfMonth");
				ElsIf WeekDay(vCurDate) = 1 Then
					vArea = vTemplate.GetArea(vAreaCol + "|LastFirstDayOfWeek");
				Else
					vArea = vTemplate.GetArea(vAreaCol + "|LastFirstHourOfDay");
				EndIf;
				// Set weekend backgroud color
				If WeekDay(vCurDate) = 7 OR WeekDay(vCurDate) = 6 Then
					vArea = vTemplate.GetArea(vAreaCol + "|LastDayOfWeek");
				EndIf;

				// Get number of vacant rooms/beds
				vVacant = GetQueryResource(vQryDays, vShowReportsInBeds, vLastVacant);
				
				// Get number of vacant rooms per several days
				If Duration > 1 Then
					vVacantByRooms = GetRoomsQueryResource(vQryByRoomsRes, vShowReportsInBeds, vQryRoomTypes.RoomType);
					If vVacantByRooms <> Null Then
						If vVacant > vVacantByRooms Then
							vVacant = vVacantByRooms;
						EndIf;
					EndIf;
					If vVacant < 0 Then
						vVacant = 0;
					EndIf;
				EndIf;
				
				// Set area parameters
				vArea.Parameters.mVacant = vVacant;
				vArea.Parameters.mDetails = New Structure("Hotel, RoomType, PeriodTo", 
				                                           vQryHotels.Hotel, 
				                                           vQryRoomTypes.RoomType, 
				                                           EndOfDay(vPeriod));
				If vVacant < 0 Then
					vCell = vArea.Area(1,1,1,1);
					vCell.TextColor = WebColors.Red;
				EndIf;
				
				// Join template area to the report
				vSpreadsheet.Join(vArea);
				
				vLastVacant = vVacant;
			EndDo;
		EndDo;
	EndDo;
	If ProgressForm.IsOpen() Then
		ProgressForm.Close();
	EndIf;
	
	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Landscape);
	
	// Set report protection
	cmSetSpreadsheetProtection(vSpreadsheet);
	
	// Set report header
	cmApplyReportHeader(vSpreadsheet);
	// Add configuration name to the right report header
	vSpreadsheet.Header.LeftText = ?(ValueIsFilled(SessionParameters.CurrentHotel), 
									 SessionParameters.CurrentHotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage), "") + " - " + 
									TrimAll(SessionParameters.ConfigurationPresentation);
	vSpreadsheet.Header.RightText = TrimAll(SessionParameters.CurrentUser) + " - " + Format(CurrentSessionDate(), "DF='dd.MM.yyyy HH:mm'");
	// Set footer
	cmApplyReportFooter(vSpreadsheet);
	
	// Fix report header and room type codes
	vSpreadsheet.FixedTop = 4;
	//vSpreadsheet.FixedLeft = 2;
EndProcedure // pmGenerateByDuration
