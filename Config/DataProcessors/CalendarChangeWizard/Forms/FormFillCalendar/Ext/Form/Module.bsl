
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Check permissions
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		pCancel = True;
		Return;
	EndIf;
	// Fill form attributes
	FillPropertyValues(ThisObject, Parameters, "DateFrom, DateTo, RoomRate, FieldName, Basis, Hotel");
	FillRoomTypesList();
	FillDays();
	// Fill with default values
	SetWhatToModify();
	// Fill list of allowed calendar day types
	FillListOfAllowedCalendarDayTypes();
	// Hide room price if room rate doesn't support it
	If ValueIsFilled(RoomRate) Then
		If Not RoomRate.UsePricesFromCalendar Then
			Items.GroupRoomPrice.Visible = False;
			SetRoomPrice = False;
			Items.DecorationOr.Visible = True;
			Items.OpenChangeRoomPricesWizard.Visible = True;
		Else
			Items.GroupRoomPrice.Visible = True;
			Items.DecorationOr.Visible = False;
			Items.OpenChangeRoomPricesWizard.Visible = False;
		EndIf;
		If ValueIsFilled(RoomRate.PriceTagType) Then
			Items.GroupPriceTag.Visible = True;
		Else
			Items.GroupPriceTag.Visible = False;
			SetPriceTag = False;
		EndIf;
	Else
		pCancel = True;
		Return;
	EndIf;
	// Save button enabled
	SetSaveButtonEnabled();
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// ----------------------------------------------------------------------------
&AtClient
Procedure DateFromOnChange(Item)
	// Fill list of allowed calendar day types
	FillListOfAllowedCalendarDayTypes();
	// Check period selected
	If DateFrom > DateTo Then
	    Message = New UserMessage;
		Message.Text = NStr("en = 'End date cannot be less than start date'; de = 'Das Enddatum kann nicht unter dem Startdatum liegen'; ru = 'Дата окончания не может быть меньше даты начала'");
		Message.Field = "DateTo";
		Message.Message();
	EndIf; 
EndProcedure // DateFromOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure DateToOnChange(Item)
	If DateFrom > DateTo Then
	    Message = New UserMessage;
		Message.Text = NStr("en = 'End date cannot be less than start date'; de = 'Das Enddatum kann nicht unter dem Startdatum liegen'; ru = 'Дата окончания не может быть меньше даты начала'");
		Message.Field = "DateTo";
		Message.Message();
	EndIf; 
EndProcedure // DateToOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure ResetAll(pItem)
	If Day1 And Day2 And Day3 And Day4 And Day5 And Day6 And Day7 Then
		AllDays = True;
	Else
		AllDays = False;
	EndIf;
EndProcedure // ResetAll

// -------------------------------------------------------------------------
&AtClient
Procedure RoomTypesStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	If AllRoomTypes.Count() > 0 Then
		For Each vAllRoomTypesItem In AllRoomTypes Do
			vAllRoomTypesItem.Check = False;
		EndDo;
		For Each vRoomTypesItem In RoomTypes Do
			vAllRoomTypesItem = AllRoomTypes.FindByValue(vRoomTypesItem.Value);
			If vAllRoomTypesItem <> Undefined Then
				vAllRoomTypesItem.Check = True;
			EndIf;
		EndDo;
		AllRoomTypes.ShowCheckItems(New NotifyDescription("RoomTypesWereChecked", ThisForm), NStr("en='Select room types that need to be changed'; ru='Отметьте типы номеров для изменения'; de='Markieren Sie die zu ändernden Zimmertypen'"));
	EndIf;
EndProcedure // RoomTypesStartChoice

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Fill(Command)
	ClearMessages();
	If DateFrom > DateTo Then
	    vMessage = New UserMessage;
		vMessage.Text = NStr("en = 'End date cannot be less than start date'; de = 'Das Enddatum kann nicht unter dem Startdatum liegen'; ru = 'Дата окончания не может быть меньше даты начала'");
		vMessage.Field = "DateTo";
		vMessage.Message();
		Return;
	EndIf;
	If ValueIsFilled(RoomRate) And tcOnServer.cmGetAttributeByRef(RoomRate, "UsePricesFromCalendar") Then
		If SetRoomPrice And Not ValueIsFilled(RoomPriceCurrency) Then
		    vMessage = New UserMessage;
			vMessage.Text = NStr("en = 'Currency should be filled!'; de = 'Währung sollte gefüllt sein!'; ru = 'Валюта должна быть указана!'");
			vMessage.Field = "RoomPriceCurrency";
			vMessage.Message();
			Return;
		EndIf;
		If SetCalendarDayType And Not ValueIsFilled(CalendarDayType) And Not tcOnServer.cmGetAttributeByRef(RoomRate, "UsePricesFromCalendar") Then
		    vMessage = New UserMessage;
			vMessage.Text = NStr("en = 'Calendar day type should be filled!'; de = 'Kalendertagtyp sollte gefüllt sein!'; ru = 'Тип дня календаря должен быть указан!'");
			vMessage.Field = "CalendarDayType";
			vMessage.Message();
			Return;
		EndIf;
		If SetPriceTag And Not ValueIsFilled(PriceTag) And ValueIsFilled(tcOnServer.cmGetAttributeByRef(RoomRate, "PriceTagType")) Then
		    vMessage = New UserMessage;
			vMessage.Text = NStr("en = 'Price tag should be filled!'; de = 'Preisschild sollte gefüllt sein!'; ru = 'Признак цены должен быть указан!'");
			vMessage.Field = "PriceTag";
			vMessage.Message();
			Return;
		EndIf;
	EndIf;
	
	// Fill room rate calendar
	FillCalendarAtServer();
	
	// Update prices cache
	If ValueIsFilled(Hotel) And tcOnServer.cmGetAttributeByRef(Hotel, "UseRoomRateDailyPrices") And ValueIsFilled(RoomRate) Then
		vRoomRate = RoomRate;
		vBasedOnRoomRate = tcOnServer.cmGetAttributeByRef(RoomRate, "BasedOnRoomRate");
		If ValueIsFilled(vBasedOnRoomRate) Then
			vRoomRate = vBasedOnRoomRate;
		EndIf;
		
		vParametersDataProcessor = New Structure;
		vParametersDataProcessor.Insert("Hotel", Hotel);
		vParametersDataProcessor.Insert("PeriodFrom", DateFrom);
		vParametersDataProcessor.Insert("PeriodTo", DateTo);
		vParametersDataProcessor.Insert("RoomRate", vRoomRate);
		If RoomTypes.Count() = 1 Then
			vParametersDataProcessor.Insert("RoomType", RoomTypes.Get(0).Value);
		EndIf;
		vProcedureParameters = New Array;
		vTempStorageAdress = PutToTempStorage(Null);
		vProcedureParameters.Add("FillRoomRateDailyPrices");
		vProcedureParameters.Add(vParametersDataProcessor);
		
		vBackgroundJob = StartBackgroundJob("ProlongedOperations.RunDataProcessor", vProcedureParameters, vTempStorageAdress);
		BackgroundJobUUID = vBackgroundJob.UUID;
		
		Status(NStr("en='Wait...';ru='Подождите...';de='Bitte warten...'"), , NStr("en = 'Background job for price update has started'; de = 'Der Hintergrundjob für die Preisaktualisierung wurde gestartet'; ru = 'Запущено фоновое задание обновления цен'"), PictureLib.DialogInformation); 
		
		Notify("System.Calendar.Changed", New Structure("BackgroundJobUUID", BackgroundJobUUID), "CalendarChangeWizard");
	EndIf;
	
	ThisForm.Close();
EndProcedure // Fill

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenChangeRoomPricesWizard(pCommand)
	// Main parameters
	vParams = New Structure;
	vParams.Insert("DateFrom", DateFrom);
	vParams.Insert("DateTo", DateTo);
	vParams.Insert("RoomRate", RoomRate);
	If RoomTypes.Count() > 0 Then
		vParams.Insert("Basis", RoomTypes);
	EndIf;
	vParams.Insert("Hotel", Hotel);
	
	// Days of week
	vOffDays = New Array();
	For i = 1 To 7 Do
		If Not ThisObject["Day" + i] Then
			vOffDays.Add(i);
		EndIf;
	EndDo;
	If vOffDays.Count() > 0 Then
		vParams.Insert("SwitchedOffWeekdays", vOffDays);
	EndIf;

	OpenForm("CommonForm.tcChangeRoomRatesWizard", vParams, ThisObject, ThisForm.UUID);
	
	ThisObject.Close();
EndProcedure // OpenChangeRoomPricesWizard

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure FillRoomTypesList()
	AllRoomTypes.Clear();
	RoomTypes.Clear();

	If ValueIsFilled(Hotel) Then
		vAllRoomTypes = cmGetAllRoomTypes(Hotel);
		For Each vAllRoomTypesRow In vAllRoomTypes Do
			AllRoomTypes.Add(vAllRoomTypesRow.RoomType, TrimAll(vAllRoomTypesRow.RoomType) + " (" + TrimAll(vAllRoomTypesRow.RoomClass) + ")", False);
		EndDo;
		If TypeOf(Basis) = Type("CatalogRef.RoomTypes") And ValueIsFilled(Basis) Then
			RoomTypes.Add(Basis);
			vAllRoomTypesItem = AllRoomTypes.FindByValue(Basis);
			If vAllRoomTypesItem <> Undefined Then
				vAllRoomTypesItem.Check = True;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // FillRoomTypesList

// -----------------------------------------------------------------------------
&AtServer
Procedure FillDays()
	AllDays = True;
	For i = 1 To 7 Do
		ThisForm["Day" + i] = AllDays;		
	EndDo;
EndProcedure // FillDays

// -----------------------------------------------------------------------------
&AtClient
Procedure AllDaysOnChange()
	For i = 1 To 7 Do
		ThisForm["Day" + i] = AllDays;		
	EndDo;
EndProcedure // AllDaysOnChange

// ----------------------------------------------------------------------------
&AtServer
Procedure FillCalendarAtServer()
	If SetCalendarDayType Or SetRoomPrice Or SetPriceTag Or SetTimetable Then
		If RoomTypes.Count() > 0 Then
			FillCalendarForRoomTypes();
		Else
			FillCalendarDays();  
		EndIf;
			
		// Update price cache if necessary
		If ValueIsFilled(Hotel) And Hotel.UseRoomRateDailyPrices And ValueIsFilled(RoomRate) Then
			If DateFrom <= DateTo And ValueIsFilled(DateFrom) Then
				vRoomRate = RoomRate;
				vBasedOnRoomRate = vRoomRate.BasedOnRoomRate;
				If ValueIsFilled(vBasedOnRoomRate) Then
					vRoomRate = vBasedOnRoomRate;
				EndIf;
				
				vRatesList = GetRatesByCalendar(RoomRate.Calendar, vRoomRate, DateFrom, DateTo);
				If vRatesList.Count() > 0 Then
					If RoomTypes.Count() > 0 Then 
						RunFillRoomRatePricesCacheAtServer(Hotel, vRatesList, RoomTypes, DateFrom, DateTo);
					Else
						RunFillRoomRatePricesCacheAtServer(Hotel, vRatesList, , DateFrom, DateTo);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If SetStopSale Or SetIsForOnlineOnly Or SetCTA Or SetCTD Or SetMLOS Or SetMaxLOS Or SetMinDaysBeforeCheckIn Or SetMaxDaysBeforeCheckIn Then
		SetRestrictions();
		
		// Write to room rate change history
		vRoomRateObj = RoomRate.GetObject();
		vRoomRateObj.LimitsLastChangeDate = CurrentSessionDate();
		vRoomRateObj.Write();
		vRoomRateObj.pmWriteToRoomRateChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
	EndIf;
EndProcedure // FillCalendarAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetRatesByCalendar(pCalendar, pRoomRate, pDateFrom, pDateTo)
	vList = New ValueList();
	If ValueIsFilled(pCalendar) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	RoomRates.Ref AS RoomRate
		|FROM
		|	Catalog.RoomRates AS RoomRates
		|WHERE
		|	RoomRates.Calendar = &qCalendar
		|	AND RoomRates.BasedOnRoomRate = VALUE(Catalog.RoomRates.EmptyRef)
		|	AND NOT RoomRates.DeletionMark
		|	AND NOT RoomRates.IsFolder
		|	AND RoomRates.Ref <> &qRoomRate
		|	AND (RoomRates.DateValidTo = &qEmptyDate
		|				AND RoomRates.DateValidFrom <= &qDateTo
		|			OR RoomRates.DateValidTo <> &qEmptyDate
		|				AND RoomRates.DateValidFrom <= &qDateTo
		|				AND RoomRates.DateValidTo >= &qDateFrom)
		|
		|ORDER BY
		|	RoomRates.SortCode,
		|	RoomRates.Code";
		vQry.SetParameter("qCalendar", pCalendar);
		vQry.SetParameter("qEmptyDate", '00010101');
		vQry.SetParameter("qDateFrom", pDateFrom);
		vQry.SetParameter("qDateTo", pDateTo);
		vQry.SetParameter("qRoomRate", pRoomRate);
		vRates = vQry.Execute().Unload();
		vList.LoadValues(vRates.UnloadColumn("RoomRate"));
	EndIf;
	Return vList;	
EndFunction // GetRatesByCalendar

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure RunFillRoomRatePricesCacheAtServer(pHotel, pRoomRatesList, pRoomTypesList = Undefined, pPeriodFrom, pPeriodTo)
	vParams = New Array();
	vParams.Add(pHotel);
	vParams.Add(pRoomRatesList);
	vParams.Add(pPeriodFrom);
	vParams.Add(pPeriodTo);
	vParams.Add(pPeriodTo);
	vKey = "";
	If pRoomTypesList <> Undefined Then
		vParams.Add(pRoomTypesList);
		vKey = TrimAll(pHotel) + ", " + GetListPresentation(pRoomRatesList) + ", " + GetRoomTypesListPresentation(pRoomTypesList) + ", " + Format(pPeriodFrom, "DF=dd.MM.yyyy") + " - " + Format(pPeriodTo, "DF=dd.MM.yyyy");
	Else
		vKey = TrimAll(pHotel) + ", " + GetListPresentation(pRoomRatesList) + ", " + Format(pPeriodFrom, "DF=dd.MM.yyyy") + " - " + Format(pPeriodTo, "DF=dd.MM.yyyy");
	EndIf;
	vBJ = BackgroundJobs.Execute("JobsScheduled.cmFillRoomRatePricesCache", vParams, vKey, NStr("en='Fill room rates prices cache: '; ru='Заполнение кэша цен тарифов: '; de='Zimmerpreis Preise Cache füllen: '") + vKey); 
EndProcedure // RunFillRoomRatePricesCacheAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetListPresentation(pList)
	vStr = "";
	For Each vListItem In pList Do
		vStr = vStr + ?(IsBlankString(vStr), "", ", ") + TrimAll(vListItem.Value);
	EndDo;
	Return vStr;
EndFunction // GetListPresentation

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetRoomTypesListPresentation(pList)
	vStr = "";
	For Each vListItem In pList Do
		If vListItem.Check Then
			vStr = vStr + ?(IsBlankString(vStr), "", ", ") + TrimAll(vListItem.Value.Code);
		EndIf;
	EndDo;
	Return vStr;
EndFunction // GetRoomTypesListPresentation

// ----------------------------------------------------------------------------
&AtServer
Procedure FillCalendarForRoomTypes()
	Try
		vCurDateTime = CurrentSessionDate();
		vCalendar = RoomRate.Calendar;
		If ValueIsFilled(vCalendar) Then
			BeginTransaction();
			For Each vRoomTypeItem In RoomTypes Do
				vRoomType = vRoomTypeItem.Value;
				vCurrDate = DateFrom;
				While vCurrDate <= DateTo Do 
					vDay = WeekDay(vCurrDate);
					vDaySel = ThisForm["Day" + vDay];
					If vDaySel Then
						vCurrDateMainRcd = Undefined;
						vCurrDateMainRcds = InformationRegisters.CalendarDays.SliceLast(New Boundary(vCurDateTime, BoundaryType.Excluding), New Structure("Calendar, AccountingDate", vCalendar, vCurrDate));
						If vCurrDateMainRcds.Count() > 0 Then
							vCurrDateMainRcd = vCurrDateMainRcds.Get(vCurrDateMainRcds.Count() - 1);
						EndIf;

						vCurrDateRcd = Undefined;
						vCurrDateRcds = InformationRegisters.CalendarDaysByRoomTypes.SliceLast(New Boundary(vCurDateTime, BoundaryType.Excluding), New Structure("Calendar, AccountingDate, Hotel, RoomType", vCalendar, vCurrDate, Hotel, vRoomType));
						If vCurrDateRcds.Count() > 0 Then
							vCurrDateRcd = vCurrDateRcds.Get(vCurrDateRcds.Count() - 1);
						EndIf;

						vIR = InformationRegisters.CalendarDaysByRoomTypes.CreateRecordManager();
						
						// Dimensions
						vIR.Calendar = vCalendar;
						vIR.Period = vCurDateTime; 
						vIR.AccountingDate = vCurrDate; 
						vIR.Hotel = Hotel; 
						vIR.RoomType = vRoomType;
						
						// Restore old resources
						If vCurrDateRcd <> Undefined Then
							vIR.RoomPrice = vCurrDateRcd.RoomPrice;
							vIR.RoomPriceCurrency = vCurrDateRcd.RoomPriceCurrency;
							vIR.CalendarDayType = vCurrDateRcd.CalendarDayType;
							vIR.PriceTag = vCurrDateRcd.PriceTag;
						EndIf;
						
						// Set changed resources
						If RoomRate.UsePricesFromCalendar And SetRoomPrice Then
							vIR.RoomPrice = RoomPrice;
							vIR.RoomPriceCurrency = RoomPriceCurrency;
						EndIf;
						If SetCalendarDayType Then
							vIR.CalendarDayType = CalendarDayType;
						EndIf;
						If SetPriceTag Then
							vIR.PriceTag = PriceTag;
						EndIf;
						vIR.Author = SessionParameters.CurrentUser;
						vIR.Remarks = TrimAll(Remarks);
						vIR.Write(True);
					EndIf; 
					vCurrDate = vCurrDate + 24*60*60;
				EndDo;
			EndDo;
			CommitTransaction();
		EndIf;
	Except
		vErrorText = cmGetRootErrorDescription(ErrorInfo());
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		Raise vErrorText;
	EndTry;
EndProcedure // FillCalendarForRoomTypes

// ----------------------------------------------------------------------------
&AtServer
Procedure FillCalendarDays()
	Try
		vCalendar = RoomRate.Calendar;
		vCurDateTime = CurrentSessionDate();
		vCurrDate = DateFrom;
		If ValueIsFilled(vCalendar) Then
			BeginTransaction();
			While vCurrDate <= DateTo Do 
				vDay = WeekDay(vCurrDate);
				vDaySel = ThisForm["Day" + vDay];
				If vDaySel Then
					vCurrDateRcd = Undefined;
					vCurrDateRcds = InformationRegisters.CalendarDays.SliceLast(New Boundary(vCurDateTime, BoundaryType.Excluding), New Structure("Calendar, AccountingDate", vCalendar, vCurrDate));
					If vCurrDateRcds.Count() > 0 Then
						vCurrDateRcd = vCurrDateRcds.Get(vCurrDateRcds.Count() - 1);
					EndIf;
					
					vIR = InformationRegisters.CalendarDays.CreateRecordManager();
					
					// Dimensions
					vIR.Calendar = vCalendar;
					vIR.Period = vCurDateTime; 
					vIR.AccountingDate = vCurrDate;
					
					// Restore old resources
					If vCurrDateRcd <> Undefined Then
						vIR.RoomPrice = vCurrDateRcd.RoomPrice;
						vIR.RoomPriceCurrency = vCurrDateRcd.RoomPriceCurrency;
						vIR.CalendarDayType = vCurrDateRcd.CalendarDayType;
						vIR.PriceTag = vCurrDateRcd.PriceTag;
						vIR.Timetable = vCurrDateRcd.Timetable;
					EndIf;
					
					// Set changed resources
					If RoomRate.UsePricesFromCalendar And SetRoomPrice Then
						vIR.RoomPrice = RoomPrice;
						vIR.RoomPriceCurrency = RoomPriceCurrency;
					EndIf;
					If SetCalendarDayType Then
						vIR.CalendarDayType = CalendarDayType;
					EndIf;
					If SetPriceTag Then
						vIR.PriceTag = PriceTag;
					EndIf;
					If SetTimetable Then
						vIR.Timetable = Timetable;
					EndIf;
					vIR.Author = SessionParameters.CurrentUser;
					vIR.Remarks = TrimAll(Remarks);
					vIR.Write(True);
				EndIf; 
				vCurrDate = vCurrDate + 24*60*60;
			EndDo;
			CommitTransaction();
		EndIf;
	Except
		vErrorText = cmGetRootErrorDescription(ErrorInfo());
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		Raise vErrorText;
	EndTry;
EndProcedure // FillCalendarDays

// ----------------------------------------------------------------------------
&AtServer
Procedure FillListOfAllowedCalendarDayTypes()
	If ValueIsFilled(DateFrom) Then
		vListOfAllowedDayTypes = GetAllowedDayTypesList();
		If vListOfAllowedDayTypes.Count() > 0 Then
			Items.CalendarDayType.ChoiceList.LoadValues(vListOfAllowedDayTypes.UnloadValues());
			Items.CalendarDayType.ListChoiceMode = True;
		Else
			Items.CalendarDayType.ChoiceList.Clear();
			Items.CalendarDayType.ListChoiceMode = False;
		EndIf;
	Else
		Items.CalendarDayType.ChoiceList.Clear();
		Items.CalendarDayType.ListChoiceMode = False;
	EndIf;
EndProcedure // FillListOfAllowedCalendarDayTypes

// ----------------------------------------------------------------------------
&AtServer
Function GetAllowedDayTypesList()
	vList = New ValueList();
	vRoomType = Catalogs.RoomTypes.EmptyRef();
	For Each vRoomTypesItem In RoomTypes Do
		If vRoomTypesItem.Check Then
			If ValueIsFilled(vRoomType) Then
				vRoomType = Catalogs.RoomTypes.EmptyRef();
				Break;
			Else
				vRoomType = vRoomTypesItem.Value;
			EndIf;
		EndIf;
	EndDo;
	vCalendar = RoomRate.Calendar;
	vDate = BegOfDay(DateFrom);
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CalendarDayTypes.Ref AS Ref
	|FROM
	|	Catalog.CalendarDayTypes AS CalendarDayTypes
	|		INNER JOIN InformationRegister.CalendarDayTypesAllowed AS CalendarDayTypesAllowed
	|		ON (CalendarDayTypesAllowed.Calendar = &qCalendar)
	|			AND (CalendarDayTypesAllowed.RoomType = &qRoomType)
	|			AND (CalendarDayTypesAllowed.Period = &qDate)
	|			AND (CalendarDayTypesAllowed.CalendarDayTypeFrom.Parent = CalendarDayTypes.Parent)
	|			AND (CalendarDayTypesAllowed.CalendarDayTypeFrom.Weight <= CalendarDayTypes.Weight)
	|			AND (CalendarDayTypesAllowed.CalendarDayTypeTo.Weight >= CalendarDayTypes.Weight)
	|			AND (NOT CalendarDayTypes.IsFolder)
	|			AND (NOT CalendarDayTypes.DeletionMark)
	|
	|ORDER BY
	|	CalendarDayTypes.Weight";
	vQry.SetParameter("qCalendar", vCalendar);
	vQry.SetParameter("qRoomType", vRoomType);
	vQry.SetParameter("qDate", vDate);
	vDayTypes = vQry.Execute().Unload();
	If vDayTypes.Count() > 0 Then
		vList.LoadValues(vDayTypes.UnloadColumn("Ref"));
	EndIf;
	Return vList;
EndFunction // GetAllowedDayTypesList

// ----------------------------------------------------------------------------
&AtServer
Procedure SetRestrictions()
	BeginTransaction();
	Try
		vCalendar = RoomRate.Calendar;
		vRoomTypes = New ValueList();
		For Each vRoomTypesItem In RoomTypes Do
			vRoomTypes.Add(vRoomTypesItem.Value);
		EndDo;
		If vRoomTypes.Count() = 0 Then
			vRoomTypes.Add(Catalogs.RoomTypes.EmptyRef());
		EndIf;
		For Each vRoomTypesItem In vRoomTypes Do
			vRoomType = vRoomTypesItem.Value;
			vCurrDate = DateFrom;
			While vCurrDate <= DateTo Do 
				vDay = WeekDay(vCurrDate);
				vDaySel = ThisForm["Day" + vDay];
				If vDaySel Then
					vIR = InformationRegisters.RoomRateRestrictions.CreateRecordManager();
					vIR.Hotel = Hotel; 
					vIR.RoomType = vRoomType; 
					vIR.RoomRate = RoomRate;
					vIR.AccountingDate = vCurrDate;
					vIR.Read();
					vIR.Hotel = Hotel; 
					vIR.RoomType = vRoomType; 
					vIR.RoomRate = RoomRate;
					vIR.AccountingDate = vCurrDate;
					vIR.Timestamp = CurrentSessionDate();
					If SetStopSale Then
						vIR.StopSale = StopSale;
					EndIf;
					If SetIsForOnlineOnly Then
						vIR.IsForOnlineOnly = IsForOnlineOnly;
					EndIf;
					If SetCTA Then
						vIR.CTA = CTA;
					EndIf;
					If SetCTD Then
						vIR.CTD = CTD;
					EndIf;
					If SetMLOS Then
						vIR.MLOS = MLOS;
					EndIf;
					If SetMaxLOS Then
						vIR.MaxLOS = MaxLOS;
					EndIf;
					If SetMinDaysBeforeCheckIn Then
						vIR.MinDaysBeforeCheckIn = MinDaysBeforeCheckIn;
					EndIf;
					If SetMaxDaysBeforeCheckIn Then
						vIR.MaxDaysBeforeCheckIn = MaxDaysBeforeCheckIn;
					EndIf;
					vIR.Write(True);
				EndIf; 
				vCurrDate = vCurrDate + 24*60*60;
			EndDo;
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		WriteLogEvent("Calendar.Changed",EventLogLevel.Error,,,ErrorDescription());
	EndTry;
EndProcedure // SetRestrictions

// ----------------------------------------------------------------------------
&AtServer
Procedure SetWhatToModify()
	// Read default values from the database
	If ValueIsFilled(Hotel) And ValueIsFilled(DateFrom) And ValueIsFilled(RoomRate) Then
		// Restrictions
		vRcdMgr = InformationRegisters.RoomRateRestrictions.CreateRecordManager();
		vRcdMgr.Hotel = Hotel;
		vRcdMgr.RoomRate = RoomRate;
		vRcdMgr.RoomType = ?(RoomTypes.Count() > 0, RoomTypes.Get(0).Value, Catalogs.RoomTypes.EmptyRef());
		vRcdMgr.AccountingDate = DateFrom;
		vRcdMgr.Read();
		If vRcdMgr.Selected() Then
			StopSale = vRcdMgr.StopSale;
			IsForOnlineOnly = vRcdMgr.IsForOnlineOnly;
			CTA = vRcdMgr.CTA;
			CTD = vRcdMgr.CTD;
			MLOS = vRcdMgr.MLOS;
			MaxLOS = vRcdMgr.MaxLOS;
			MinDaysBeforeCheckIn = vRcdMgr.MinDaysBeforeCheckIn;
			MaxDaysBeforeCheckIn = vRcdMgr.MaxDaysBeforeCheckIn;
		EndIf;
		// Calendar
		vRcds = InformationRegisters.CalendarDays.SliceLast(CurrentSessionDate(), New Structure("Calendar, AccountingDate", RoomRate.Calendar, DateFrom));
		If vRcds.Count() > 0 Then
			vRcd = vRcds.Get(0);
			CalendarDayType = vRcd.CalendarDayType;
			PriceTag = vRcd.PriceTag;
			Timetable = vRcd.Timetable;
		EndIf;
		If RoomTypes.Count() > 0 Then
			vRoomType = RoomTypes.Get(0).Value;
			vRTRcds = InformationRegisters.CalendarDaysByRoomTypes.SliceLast(CurrentSessionDate(), New Structure("Calendar, RoomType, AccountingDate, Hotel", RoomRate.Calendar, vRoomType, DateFrom, vRoomType.Owner));
			If vRTRcds.Count() > 0 Then
				vRTRcd = vRTRcds.Get(0);
				If ValueIsFilled(vRTRcd.CalendarDayType) Then
					CalendarDayType = vRTRcd.CalendarDayType;
				EndIf;
				If ValueIsFilled(vRTRcd.PriceTag) Then
					PriceTag = vRTRcd.PriceTag;
				EndIf;
			EndIf;
		EndIf;
		// Room price
		If RoomRate.UsePricesFromCalendar Then
			vRcds = InformationRegisters.CalendarDays.SliceLast(CurrentSessionDate(), New Structure("Calendar, AccountingDate", RoomRate.Calendar, DateFrom));
			If vRcds.Count() > 0 Then
				vRcd = vRcds.Get(0);
				RoomPrice = vRcd.RoomPrice;
				RoomPriceCurrency = vRcd.RoomPriceCurrency;
			EndIf;
			If RoomTypes.Count() > 0 Then
				vRoomType = RoomTypes.Get(0).Value;
				vRTRcds = InformationRegisters.CalendarDaysByRoomTypes.SliceLast(CurrentSessionDate(), New Structure("Calendar, RoomType, AccountingDate, Hotel", RoomRate.Calendar, vRoomType, DateFrom, vRoomType.Owner));
				If vRTRcds.Count() > 0 Then
					vRTRcd = vRTRcds.Get(0);
					If vRTRcd.RoomPrice <> 0 Then
						RoomPrice = vRTRcd.RoomPrice;
						RoomPriceCurrency = vRTRcd.RoomPriceCurrency;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // SetWhatToModify

// -------------------------------------------------------------------------
&AtServer                               
Function StartBackgroundJob(pProcedureName, pProcedureParametrs, pTempStorageAddress = Undefined)
	vKey = "";
	If RoomTypes.Count() = 1 Then
		vKey = TrimAll(Hotel) + ", " + TrimAll(RoomRate) + ", " + GetRoomTypesListPresentation(RoomTypes) + ", " + Format(DateFrom, "DF=dd.MM.yyyy") + " - " + Format(DateTo, "DF=dd.MM.yyyy");
	Else
		vKey = TrimAll(Hotel) + ", " + TrimAll(RoomRate) + ", " + Format(DateFrom, "DF=dd.MM.yyyy") + " - " + Format(DateTo, "DF=dd.MM.yyyy");
	EndIf;
	Return AsyncCalls.StartBackgroundJob(pProcedureName, pProcedureParametrs, vKey, NStr("en='Fill room rates prices cache: '; ru='Заполнение кэша цен тарифов: '; de='Zimmerpreis Preise Cache füllen: '") + vKey, pTempStorageAddress);
EndFunction // StartBackgroundJob

// -------------------------------------------------------------------------
&AtClient
Procedure RoomTypesWereChecked(pList, pExtraParams) Export
	If pList <> Undefined Then
		RoomTypes.Clear();
		For Each vListItem In pList Do
			If vListItem.Check Then
				RoomTypes.Add(vListItem.Value);
			EndIf;
		EndDo;
	EndIf;
EndProcedure // RoomTypesWereChecked

// -------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriod(pCommand)
	vChoosePeriodDialog = New StandardPeriodEditDialog();
	vChoosePeriodDialog.Period.StartDate = DateFrom;
	vChoosePeriodDialog.Period.EndDate = DateTo;
	vChoosePeriodDialog.Period.Variant = StandardPeriodVariant.Custom;
	vChoosePeriodDialog.Show(New NotifyDescription("ChoosePeriodAfterChoice", ThisForm));
EndProcedure // ChoosePeriod

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriodAfterChoice(pPeriod, pExtraParams) Export
	If pPeriod <> Undefined Then
		DateFrom = pPeriod.StartDate;
		DateTo = pPeriod.EndDate;
	EndIf;
EndProcedure // ChoosePeriodAfterChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomPriceOnChange(pItem)
	SetRoomPrice = True;
	If Not ValueIsFilled(RoomPriceCurrency) And RoomPrice <> 0 And ValueIsFilled(RoomRate) And Not tcOnServer.cmGetAttributeByRef(RoomRate, "IsFolder") Then
		RoomPriceCurrency = tcOnServer.cmGetAttributeByRef(RoomRate, "DefaultCurrency");
	EndIf;
	SetSaveButtonEnabled();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomPriceCurrencyOnChange(pItem)
	SetRoomPrice = True;
	SetSaveButtonEnabled();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CalendarDayTypeOnChange(pItem)
	SetCalendarDayType = True;
	SetSaveButtonEnabled();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PriceTagOnChange(pItem)
	SetPriceTag = True;
	SetSaveButtonEnabled();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure TimetableOnChange(pItem)
	SetTimetable = True;
	SetSaveButtonEnabled();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure StopSaleOnChange(pItem)
	SetStopSale = True;
	SetSaveButtonEnabled();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure IsForOnlineOnlyOnChange(pItem)
	SetIsForOnlineOnly = True;
	SetSaveButtonEnabled();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CTAOnChange(pItem)
	SetCTA = True;
	SetSaveButtonEnabled();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CTDOnChange(pItem)
	SetCTD = True;
	SetSaveButtonEnabled();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure MLOSOnChange(pItem)
	SetMLOS = True;
	SetSaveButtonEnabled();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure MaxLOSOnChange(pItem)
	SetMaxLOS = True;
	SetSaveButtonEnabled();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure MinDaysBeforeCheckInOnChange(pItem)
	SetMinDaysBeforeCheckIn = True;
	SetSaveButtonEnabled();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure MaxDaysBeforeCheckInOnChange(pItem)
	SetMaxDaysBeforeCheckIn = True;
	SetSaveButtonEnabled();
EndProcedure

// -----------------------------------------------------------------------------
Procedure SetSaveButtonEnabled()
	Items.Save.Enabled = False;
	If SetRoomPrice Or SetCalendarDayType Or SetPriceTag Or SetTimetable Or SetStopSale Or SetCTA Or SetCTD Or SetMLOS Or SetMaxLOS Or SetMinDaysBeforeCheckIn Or SetMaxDaysBeforeCheckIn Or SetIsForOnlineOnly Then
		Items.Save.Enabled = True;
	EndIf;
EndProcedure // SetSaveButtonEnabled

// -----------------------------------------------------------------------------
&AtClient
Procedure SetStopSaleOnChange(pItem)
	SetSaveButtonEnabled();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SetCTAOnChange(pItem)
	SetSaveButtonEnabled();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SetCTDOnChange(pItem)
	SetSaveButtonEnabled();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SetMLOSOnChange(pItem)
	SetSaveButtonEnabled();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SetMaxLOSOnChange(pItem)
	SetSaveButtonEnabled();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SetMinDaysBeforeCheckInOnChange(pItem)
	SetSaveButtonEnabled();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SetMaxDaysBeforeCheckInOnChange(pItem)
	SetSaveButtonEnabled();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SetIsForOnlineOnlyOnChange(pItem)
	SetSaveButtonEnabled();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SetPriceTagOnChange(pItem)
	SetSaveButtonEnabled();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SetCalendarDayTypeOnChange(pItem)
	SetSaveButtonEnabled();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SetRoomPriceOnChange(pItem)
	SetSaveButtonEnabled();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SetTimetableOnChange(pItem)
	SetSaveButtonEnabled();
EndProcedure

#EndRegion
