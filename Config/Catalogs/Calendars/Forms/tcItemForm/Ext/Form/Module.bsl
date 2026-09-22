
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	// Check user rights to use item
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		If ValueIsFilled(Object.Ref) Then
			ReadOnly = True;
		Else
			Cancel = True;
		EndIf;
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights for services and prices management!';ru='Нет прав на управление услугами и ценами!';de='Sie haben keine Rechte, Dienstleistungen und Preise zu verwalten!'"));
	EndIf;
	
	// Initialize hotel
	tcOnServer.cmInitHotel(Object);

	// Form appearance
	If Parameters.isNotEdit Then
		Items.GroupView.Visible = True;
	Else
		Items.GroupEdit.Visible = True;
	EndIf;
	Type = "CatalogRef.CalendarDayTypes";
	Items.Value.TypeRestriction = New TypeDescription(Type);
	
	ShowHistory = False;
	Items.GroupHistory.Enabled = ShowHistory;
	
	FillRoomTypeChoiceParameters();
	
	CalendarDate = BegOfYear(CurrentSessionDate());
	Items.PrevYear.Title = Format(BegOfYear(AddMonth(CalendarDate, -12)), "DF=yyyy");
	Items.NextYear.Title = Format(BegOfYear(AddMonth(CalendarDate, 12)), "DF=yyyy");
	FillType = "New";
	If ValueIsFilled(Object.Ref) Then
		FillColorTable();
		InitCalendar();
		FillCopyYear();
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SHCalendarOnActivateArea(Item)
	If ResetCurrentAreaMode Then
		Return;
	EndIf;
	
	vArea = StrSplit(Item.CurrentArea.Name,":");
	If vArea.Count() = 1 Then		
		vStruct = SHCalendar.Area(vArea[0]).Details;
		If ValueIsFilled(vStruct) And vStruct.Property("Date") Then
			CurrentDate = vStruct.Date;
			If vStruct.Property("Value") And ValueIsFilled(vStruct.Value) Then
				vDayTypeAttrs = tcOnServer.cmGetAtributeAsArray(vStruct.Value);
				CurrentValue = vStruct.Value; 
				CurrentValueDescription = Format(CurrentDate, "DF='d MMMM - '") + TrimAll(vDayTypeAttrs.Description) + " (" + TrimAll(vDayTypeAttrs.Code) + ")";
			Else
				CurrentValue = Undefined; 
				CurrentValueDescription = ""; 
			EndIf;	
		Else
			CurrentDate = '00010101';
			CurrentValue = Undefined; 
			CurrentValueDescription = ""; 
		EndIf;
	EndIf;
	SelectedDays.Clear();
	For Each vSA In SHCalendar.SelectedAreas Do
		If vSA.AreaType = SpreadsheetDocumentCellAreaType.Rectangle Then
			If vSA.Details <> Undefined Then
				SelectedDays.Add(vSA.Details.Date);	
			EndIf;
		EndIf;	
	EndDo;
	SelectedDays.SortByValue();	

	ButtonView();
	InitCalendar();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SHCalendarSelection(Item, Area, StandardProcessing)
	StandardProcessing = False;
	vStruct = SHCalendar.Area(Area.Name).Details;
	If ValueIsFilled(vStruct) And vStruct.Property("Date") Then
		vDate = vStruct.Date;		
		If ValueIsFilled(BegDate) And ValueIsFilled(EndDate) Then
			BegDate = Undefined;
			EndDate = Undefined;			
		EndIf;		
		If not ValueIsFilled(BegDate) Then
			BegDate = vDate;
		Else
			If not ValueIsFilled(EndDate) Then
				EndDate = vDate;
				If EndDate < BegDate Then
					vDate = EndDate;
					EndDate = BegDate;
					BegDate = vDate;
				EndIf;
				
			EndIf;
		EndIf;
		ButtonView();
		InitCalendar();				
	Else
		ButtonView();
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AllDaysOnChange(Item)
	For i = 1 To 7 Do
		ThisObject["Day" + i] = AllDays;		
	EndDo;
	ButtonView();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AllDaysOff(Item)
	AllDays = False;
	If Day1 And Day2 And Day3 And Day4 And Day5 And Day6 And Day7 Then
		AllDays = True;
	EndIf;
	ButtonView();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure BegDateOnChange(pItem)
	If ValueIsFilled(BegDate) And ValueIsFilled(EndDate) Then
		If EndDate < BegDate Then
			EndDate = BegDate + 24 * 3600;
		EndIf;
		ButtonView();
		InitCalendar();
	Else
		ButtonView();
	EndIf;
EndProcedure // BegDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure EndDateOnChange(pItem)
	If ValueIsFilled(BegDate) And ValueIsFilled(EndDate) Then
		If EndDate < BegDate Then
			BegDate = EndDate - 24 * 3600;
		EndIf;
		ButtonView();
		InitCalendar();
	Else
		ButtonView();
	EndIf;
EndProcedure // EndDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SHLegendsOnActivateArea(Item)
	If ValueIsFilled(Item.CurrentArea.Details) Then
		FilterType = Item.CurrentArea.Details;
		InitCalendar();
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FilterTypeOnChange(Item)
	InitCalendar();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SHLegendsDetailProcessing(Item, Details, StandardProcessing)
	StandardProcessing = False;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ValueOnChange(Item)
	ButtonView();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillTypeOnChange(Item)
	ButtonView();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CopyYearOnChange(Item)
	ButtonView();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypeOnChange(Item)
	ClearCalendar();
	FillCopyYear();
	FillColorTable();
	ButtonView();
	InitCalendar();
	ResetCurrentAreas();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelOnChange(pItem)
	FillRoomTypeChoiceParameters();
EndProcedure // HotelOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure TypeOnChange(Item)
	Value = Undefined;
	If not Type = "CatalogRef.RoomTypes" Then
		Items.Value.TypeRestriction = New TypeDescription(Type);
	Else
		Items.Value.TypeRestriction = New TypeDescription("CatalogRef.CalendarDayTypes");
	EndIf;

	ShowHistory = False;
	PriceCalculationDate = '00010101';
	BegDate = '00010101';
	EndDate = '00010101';
	HistoryPeriodYear = 0;
	HistoryPeriodMonth = 0;
	HistoryPeriodDay = 0;
	HistoryPeriod = '00010101';

	Items.HistoryPeriodYear.ChoiceList.Clear();
	Items.HistoryPeriodMonth.ChoiceList.Clear();
	Items.HistoryPeriodDay.ChoiceList.Clear();
	Items.HistoryPeriod.ChoiceList.Clear();
	Items.GroupHistory.Enabled = ShowHistory;

	ClearCalendar();
	FillColorTable();
	ButtonView();
	InitCalendar();
	ResetCurrentAreas();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CurrentValueOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	If ValueIsFilled(CurrentValue) And ValueIsFilled(CurrentDate) Then
		If Type = "CatalogRef.RoomTypes" Then
			OpenForm("InformationRegister.CalendarDaysByRoomTypes.ListForm", New Structure("Filter", New Structure("Calendar, AccountingDate, RoomType, Hotel", Object.Ref, CurrentDate, RoomType, ?(ValueIsFilled(RoomType), tcOnServer.cmGetAttributeByRef(RoomType, "Owner"), tcOnServer.cmGetSessionParametersAttribute("CurrentHotel")))), ThisObject, New UUID, , , , FormWindowOpeningMode.LockOwnerWindow);
		Else
			OpenForm("InformationRegister.CalendarDays.ListForm", New Structure("Filter", New Structure("Calendar, AccountingDate", Object.Ref, CurrentDate)), ThisObject, New UUID, , , , FormWindowOpeningMode.LockOwnerWindow);
		EndIf;
	EndIf;
EndProcedure // CurrentValueOpening

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure FillCalendar(pCommand)
	If Not ValueIsFilled(Object.Ref) Then
		ShowMessageBox(, NStr("en='Calendar is not saved yet! Press <Write> button and try again.'; ru='Календарь еще не записан! Нажмите кнопку <Записать> и попробуйте еще раз.'; de='Der Kalender ist noch nicht aufgezeichnet! Klicken Sie auf die Schaltfläche <Speichern> und versuchen Sie es erneut.'"));
		Return;
	EndIf;

	FillCalendarAtServer();
EndProcedure // FillCalendar

// -----------------------------------------------------------------------------
&AtClient
Procedure NextYear(Command)
	If Not ValueIsFilled(Object.Ref) Then
		ShowMessageBox(, NStr("en='Calendar is not saved yet! Press <Write> button and try again.'; ru='Календарь еще не записан! Нажмите кнопку <Записать> и попробуйте еще раз.'; de='Der Kalender ist noch nicht aufgezeichnet! Klicken Sie auf die Schaltfläche <Speichern> und versuchen Sie es erneut.'"));
		Return;
	EndIf;
	
	CalendarDate = BegOfYear(AddMonth(CalendarDate,12));
	Items.PrevYear.Title = Format(BegOfYear(AddMonth(CalendarDate, -12)), "DF=yyyy");
	Items.NextYear.Title = Format(BegOfYear(AddMonth(CalendarDate, 12)), "DF=yyyy");

	ShowHistory = False;
	PriceCalculationDate = '00010101';
	
	HistoryPeriodYear = 0;
	HistoryPeriodMonth = 0;
	HistoryPeriodDay = 0;
	HistoryPeriod = '00010101';

	Items.HistoryPeriodYear.ChoiceList.Clear();
	Items.HistoryPeriodMonth.ChoiceList.Clear();
	Items.HistoryPeriodDay.ChoiceList.Clear();
	Items.HistoryPeriod.ChoiceList.Clear();
	Items.GroupHistory.Enabled = ShowHistory;
	
	ClearCalendar();
	FillColorTable();
	InitCalendar(); 	
	ResetCurrentAreas();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PrevYear(Command)
	If Not ValueIsFilled(Object.Ref) Then
		ShowMessageBox(, NStr("en='Calendar is not saved yet! Press <Write> button and try again.'; ru='Календарь еще не записан! Нажмите кнопку <Записать> и попробуйте еще раз.'; de='Der Kalender ist noch nicht aufgezeichnet! Klicken Sie auf die Schaltfläche <Speichern> und versuchen Sie es erneut.'"));
		Return;
	EndIf;

	CalendarDate = BegOfYear(AddMonth(CalendarDate,-12));
	Items.PrevYear.Title = Format(BegOfYear(AddMonth(CalendarDate, -12)), "DF=yyyy");
	Items.NextYear.Title = Format(BegOfYear(AddMonth(CalendarDate, 12)), "DF=yyyy");

	ShowHistory = False;
	PriceCalculationDate = '00010101';
	
	HistoryPeriodYear = 0;
	HistoryPeriodMonth = 0;
	HistoryPeriodDay = 0;
	HistoryPeriod = '00010101';

	Items.HistoryPeriodYear.ChoiceList.Clear();
	Items.HistoryPeriodMonth.ChoiceList.Clear();
	Items.HistoryPeriodDay.ChoiceList.Clear();
	Items.HistoryPeriod.ChoiceList.Clear();
	Items.GroupHistory.Enabled = ShowHistory;
	
	ClearCalendar();
	FillColorTable();
	InitCalendar(); 	
	ResetCurrentAreas();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearPeriod(Command)
	BegDate = '00010101';
	EndDate = '00010101';
	ButtonView();
	InitCalendar();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RefreshCalendar(pCommand)
	If ValueIsFilled(Object.Ref) Then
		ShowHistoryOnChange(Items.ShowHistory);
	EndIf;
EndProcedure // RefreshCalendar

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure FillRoomTypeChoiceParameters()
	vCPA = New Array();
	If ValueIsFilled(Object.Hotel) Then
		If ValueIsFilled(RoomType) And Object.Hotel <> RoomType.Owner Then
			RoomType = Catalogs.RoomTypes.EmptyRef();
		EndIf;
		vCP = New ChoiceParameter("Filter.Owner", Object.Hotel);
		vCPA.Add(vCP);
	ElsIf ValueIsFilled(SessionParameters.CurrentHotel) Then
		If ValueIsFilled(RoomType) And SessionParameters.CurrentHotel <> RoomType.Owner Then
			RoomType = Catalogs.RoomTypes.EmptyRef();
		EndIf;
		vCP = New ChoiceParameter("Filter.Owner", SessionParameters.CurrentHotel);
		vCPA.Add(vCP);
	EndIf;
	If vCPA.Count() > 0 Then
		Items.RoomType.ChoiceParameters = New FixedArray(vCPA);
	EndIf;
EndProcedure // FillRoomTypeChoiceParameters

// -----------------------------------------------------------------------------
&AtClient
Procedure ButtonView()
	If FillType = "New" Then
		Items.Value.Visible = True;
		Items.CopyYear.Visible = False;	
		If ValueIsFilled(BegDate) And  ValueIsFilled(EndDate) Then
			Items.GroupWeekdays.Visible = True;
			If ValueIsFilled(Value) And (Day1 Or Day2 Or Day3 Or Day4 Or Day5 Or Day6 Or Day7) And  ValueIsFilled(BegDate) And ValueIsFilled(EndDate) And BegDate <= EndDate Then
				Items.FillCalendar.Enabled = True;
			Else
				Items.FillCalendar.Enabled = False;	
			EndIf;
		Else
			Items.GroupWeekdays.Visible = False;		
			If SelectedDays.Count() > 0 And ValueIsFilled(Value) Then
				Items.FillCalendar.Enabled = True;
			Else
				Items.FillCalendar.Enabled = False;	
			EndIf;
		EndIf;
	Else
		Items.GroupWeekdays.Visible = False;		
		Items.Value.Visible = False;
		Items.CopyYear.Visible = True;		
		If ValueIsFilled(CopyYear) And ValueIsFilled(BegDate) And  ValueIsFilled(EndDate) Or SelectedDays.Count() > 0 And ValueIsFilled(CopyYear) Then 
			Items.FillCalendar.Enabled = True;
		Else
			Items.FillCalendar.Enabled = False;
		EndIf;
	EndIf;
	If Type = "CatalogRef.RoomTypes" Then
		Items.RoomType.Visible = True;
	Else
		Items.RoomType.Visible = False;		
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
Procedure FillCopyYear()
	Items.CopyYear.ChoiceList.Clear();
	vQuery = New Query;
	If Type = "CatalogRef.RoomTypes" Then
		
		vQuery.Text = 
		"SELECT
		|	YEAR(CalendarDays.AccountingDate) AS Year
		|FROM
		|	InformationRegister.CalendarDaysByRoomTypes.SliceLast(
		|			,
		|			Calendar = &qCalendar
		|				AND RoomType = &qRoomType
		|				AND Hotel = &qHotel) AS CalendarDays
		|
		|GROUP BY
		|	YEAR(CalendarDays.AccountingDate)
		|
		|ORDER BY
		|	Year";

	Else
		
		vQuery.Text = 
		"SELECT
		|	YEAR(CalendarDays.AccountingDate) AS Year
		|FROM
		|	InformationRegister.CalendarDays.SliceLast(, Calendar = &qCalendar) AS CalendarDays
		|
		|GROUP BY
		|	YEAR(CalendarDays.AccountingDate)
		|
		|ORDER BY
		|	Year";
		
	EndIf;
	vQuery.SetParameter("qCalendar", Object.Ref);
	vQuery.SetParameter("qRoomType", RoomType);
	vQuery.SetParameter("qHotel", RoomType.Owner);
	
	vQueryResult = vQuery.Execute();
	
	vSelectionDetailRecords = vQueryResult.Select();
	While vSelectionDetailRecords.Next() Do
		Items.CopyYear.ChoiceList.Add(Format(vSelectionDetailRecords.Year, "NG="));
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function GetRatesByCalendar(pCalendar, pDateFrom, pDateTo)
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
		|	AND (RoomRates.DateValidTo = &qEmptyDate
		|				AND RoomRates.DateValidFrom <= &qDateTo
		|			OR RoomRates.DateValidTo <> &qEmptyDate
		|				AND RoomRates.DateValidFrom <= &qDateTo
		|				AND RoomRates.DateValidTo >= &qDateFrom)
		|
		|ORDER BY
		|	ISNULL(RoomRates.BasedOnRoomRate.SortCode, 0),
		|	ISNULL(RoomRates.BasedOnRoomRate.Code, """"),
		|	RoomRates.SortCode,
		|	RoomRates.Code";
		vQry.SetParameter("qCalendar", pCalendar);
		vQry.SetParameter("qEmptyDate", '00010101');
		vQry.SetParameter("qDateFrom", pDateFrom);
		vQry.SetParameter("qDateTo", pDateTo);
		vRates = vQry.Execute().Unload();
		vList.LoadValues(vRates.UnloadColumn("RoomRate"));
	EndIf;
	Return vList;	
EndFunction // GetRatesByCalendar

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure RunFillRoomRatePricesCacheAtServer(pHotel, pRoomRatesList, pPeriodFrom, pPeriodTo)
	vParams = New Array();
	vParams.Add(pHotel);
	vParams.Add(pRoomRatesList);
	vParams.Add(pPeriodFrom);
	vParams.Add(pPeriodTo);
	vBJ = BackgroundJobs.Execute("JobsScheduled.cmFillRoomRatePricesCache", vParams, , NStr("en='Fill room rate prices cache: '; ru='Заполнение кэша цен тарифов: '; de='Zimmerpreis Preise Cache füllen: '") + TrimAll(pHotel) + ", " + GetListPresentation(pRoomRatesList) + ", " + Format(pPeriodFrom, "DF=dd.MM.yyyy") + " - " + Format(pPeriodTo, "DF=dd.MM.yyyy")); 
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

&AtServer
Function ReadCurrentStateOfCalendar(pDateFrom, pDateTo, pCurDateTime)
	// Read current calendar state
	vActiveRecords = Undefined;
	If Type = "CatalogRef.RoomTypes" And ValueIsFilled(Value) And ValueIsFilled(RoomType) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	CalendarDaysByRoomTypesSliceLast.Period AS Period,
		|	CalendarDaysByRoomTypesSliceLast.Calendar AS Calendar,
		|	CalendarDaysByRoomTypesSliceLast.RoomType AS RoomType,
		|	CalendarDaysByRoomTypesSliceLast.AccountingDate AS AccountingDate,
		|	CalendarDaysByRoomTypesSliceLast.Hotel AS Hotel,
		|	CalendarDaysByRoomTypesSliceLast.PriceTag AS PriceTag,
		|	CalendarDaysByRoomTypesSliceLast.RoomPrice AS RoomPrice,
		|	CalendarDaysByRoomTypesSliceLast.RoomPriceCurrency AS RoomPriceCurrency,
		|	CalendarDaysByRoomTypesSliceLast.Author AS Author,
		|	CalendarDaysByRoomTypesSliceLast.Remarks AS Remarks,
		|	CalendarDaysByRoomTypesSliceLast.CalendarDayType AS CalendarDayType
		|FROM
		|	InformationRegister.CalendarDaysByRoomTypes.SliceLast(
		|			&qPeriod,
		|			Calendar = &qCalendar
		|				AND Hotel = &qHotel
		|				AND RoomType = &qRoomType
		|				AND AccountingDate >= &qDateFrom
		|				AND AccountingDate <= &qDateTo) AS CalendarDaysByRoomTypesSliceLast
		|
		|ORDER BY
		|	AccountingDate,
		|	Period";
		vQry.SetParameter("qCalendar", Object.Ref);
		vQry.SetParameter("qHotel", RoomType.Owner);
		vQry.SetParameter("qRoomType", RoomType);
		vQry.SetParameter("qDateFrom", pDateFrom);
		vQry.SetParameter("qDateTo", pDateTo);
		vQry.SetParameter("qPeriod", New Boundary(pCurDateTime, BoundaryType.Excluding));
		vActiveRecords = vQry.Execute().Unload();
		vActiveRecords.Indexes.Add("AccountingDate, RoomType");
	Else
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	CalendarDaysSliceLast.Period AS Period,
		|	CalendarDaysSliceLast.Calendar AS Calendar,
		|	CalendarDaysSliceLast.AccountingDate AS AccountingDate,
		|	CalendarDaysSliceLast.PriceTag AS PriceTag,
		|	CalendarDaysSliceLast.RoomPrice AS RoomPrice,
		|	CalendarDaysSliceLast.RoomPriceCurrency AS RoomPriceCurrency,
		|	CalendarDaysSliceLast.Author AS Author,
		|	CalendarDaysSliceLast.Remarks AS Remarks,
		|	CalendarDaysSliceLast.CalendarDayType AS CalendarDayType,
		|	CalendarDaysSliceLast.Timetable AS Timetable
		|FROM
		|	InformationRegister.CalendarDays.SliceLast(
		|			&qPeriod,
		|			Calendar = &qCalendar
		|				AND AccountingDate >= &qDateFrom
		|				AND AccountingDate <= &qDateTo) AS CalendarDaysSliceLast
		|
		|ORDER BY
		|	AccountingDate,
		|	Period";
		vQry.SetParameter("qCalendar", Object.Ref);
		vQry.SetParameter("qDateFrom", pDateFrom);
		vQry.SetParameter("qDateTo", pDateTo);
		vQry.SetParameter("qPeriod", New Boundary(pCurDateTime, BoundaryType.Excluding));
		vActiveRecords = vQry.Execute().Unload();
		vActiveRecords.Indexes.Add("AccountingDate");
	EndIf;
	Return vActiveRecords;
EndFunction // ReadCurrentStateOfCalendar

// -----------------------------------------------------------------------------
&AtServer
Procedure FillCalendarAtServer()
	vCurDateTime = CurrentSessionDate();
	
	vCacheUpdateStartDate = BegDate;
	vCacheUpdateEndDate = EndDate;
	
	// Process modes
	If FillType = "New" Then
		If Items.GroupWeekdays.Visible Then
			// Read current calendar state
			vActiveRecords = ReadCurrentStateOfCalendar(BegDate, EndDate, vCurDateTime);
			
			BeginTransaction(DataLockControlMode.Managed);
			
			vCurDate = BegDate;
			While vCurDate <= EndDate Do  
				vWeekDay = WeekDay(vCurDate);
				If ThisObject["Day" + vWeekDay] Then
					If Type = "CatalogRef.RoomTypes" And ValueIsFilled(Value) And ValueIsFilled(RoomType) Then
						// Retrieve current state
						vActiveRow = Undefined;
						vRows = vActiveRecords.FindRows(New Structure("AccountingDate, RoomType", vCurDate, RoomType));
						If vRows.Count() > 0 Then
							vActiveRow = vRows.Get(vRows.Count() - 1);
						EndIf;
						
						// Write new records for current date and time
						vIR = InformationRegisters.CalendarDaysByRoomTypes.CreateRecordManager();
						vIR.Calendar = Object.Ref;
						vIR.Period = vCurDateTime; 
						vIR.AccountingDate = vCurDate; 
						vIR.Hotel = RoomType.Owner; 
						vIR.RoomType = RoomType; 
						vIR.CalendarDayType = Value;
						If vActiveRow <> Undefined Then
							vIR.PriceTag = vActiveRow.PriceTag;
							vIR.RoomPrice = vActiveRow.RoomPrice;
							vIR.RoomPriceCurrency = vActiveRow.RoomPriceCurrency;
							vIR.Remarks = vActiveRow.Remarks;
						EndIf;
						vIR.Author = SessionParameters.CurrentUser;
						vIR.Write(True);
					Else
						// Retrieve current state
						vActiveRow = Undefined;
						vRows = vActiveRecords.FindRows(New Structure("AccountingDate", vCurDate));
						If vRows.Count() > 0 Then
							vActiveRow = vRows.Get(vRows.Count() - 1);
						EndIf;
						
						// Write new records for current date and time
						vIR = InformationRegisters.CalendarDays.CreateRecordManager();
						vIR.Calendar = Object.Ref;
						vIR.Period = vCurDateTime; 
						vIR.AccountingDate = vCurDate;
						If Type = "CatalogRef.CalendarDayTypes" And ValueIsFilled(Value) Then 
							vIR.CalendarDayType = Value;
							If vActiveRow <> Undefined Then
								vIR.Timetable = vActiveRow.Timetable;
								vIR.PriceTag = vActiveRow.PriceTag;
								vIR.RoomPrice = vActiveRow.RoomPrice;
								vIR.RoomPriceCurrency = vActiveRow.RoomPriceCurrency;
								vIR.Remarks = vActiveRow.Remarks;
							EndIf;
						ElsIf Type = "CatalogRef.TimeTables" And ValueIsFilled(Value) Then
							vIR.Timetable = Value;				
							If vActiveRow <> Undefined Then
								vIR.CalendarDayType = vActiveRow.CalendarDayType;
								vIR.PriceTag = vActiveRow.PriceTag;
								vIR.RoomPrice = vActiveRow.RoomPrice;
								vIR.RoomPriceCurrency = vActiveRow.RoomPriceCurrency;
								vIR.Remarks = vActiveRow.Remarks;
							EndIf;
						ElsIf Type = "CatalogRef.PriceTags" And ValueIsFilled(Value) Then                                   
							vIR.PriceTag = Value;
							If vActiveRow <> Undefined Then
								vIR.CalendarDayType = vActiveRow.CalendarDayType;
								vIR.Timetable = vActiveRow.Timetable;
								vIR.RoomPrice = vActiveRow.RoomPrice;
								vIR.RoomPriceCurrency = vActiveRow.RoomPriceCurrency;
								vIR.Remarks = vActiveRow.Remarks;
							EndIf;
						EndIf;	
						vIR.Author = SessionParameters.CurrentUser;
						vIR.Write(True);
					EndIf;
				EndIf;
				vCurDate = vCurDate + 24 * 60 * 60;
			EndDo;
			
			CommitTransaction();
		Else
			vMinDate = '39991231';
			vMaxDate = '00010101';
			For Each vSA In SelectedDays Do
				vCurDate = vSA.Value;
				vMinDate = Min(vMinDate, vCurDate); 
				vMaxDate = Max(vMaxDate, vCurDate); 
			EndDo;
			
			vCacheUpdateStartDate = vMinDate;
			vCacheUpdateEndDate = vMaxDate;
			
			// Read current calendar state
			vActiveRecords = ReadCurrentStateOfCalendar(vMinDate, vMaxDate, vCurDateTime);

			BeginTransaction();
			
			For Each vSA In SelectedDays Do
				vCurDate = vSA.Value;

				If Type = "CatalogRef.RoomTypes" And ValueIsFilled(Value) And ValueIsFilled(RoomType) Then 
					// Retrieve current state
					vActiveRow = Undefined;
					vRows = vActiveRecords.FindRows(New Structure("AccountingDate, RoomType", vCurDate, RoomType));
					If vRows.Count() > 0 Then
						vActiveRow = vRows.Get(vRows.Count() - 1);
					EndIf;
				
					// Write new records for current date and time
					vIR = InformationRegisters.CalendarDaysByRoomTypes.CreateRecordManager();
					vIR.Calendar = Object.Ref;
					vIR.Period = vCurDateTime;
					vIR.AccountingDate = vCurDate; 
					vIR.Hotel = RoomType.Owner; 
					vIR.RoomType = RoomType; 
					vIR.CalendarDayType = Value;
					If vActiveRow <> Undefined Then
						vIR.PriceTag = vActiveRow.PriceTag;
						vIR.RoomPrice = vActiveRow.RoomPrice;
						vIR.RoomPriceCurrency = vActiveRow.RoomPriceCurrency;
						vIR.Remarks = vActiveRow.Remarks;
					EndIf;
					vIR.Author = SessionParameters.CurrentUser;
					vIR.Write(True);
				Else
					// Retrieve current state
					vActiveRow = Undefined;
					vRows = vActiveRecords.FindRows(New Structure("AccountingDate", vCurDate));
					If vRows.Count() > 0 Then
						vActiveRow = vRows.Get(vRows.Count() - 1);
					EndIf;

					// Write new records for current date and time
					vIR = InformationRegisters.CalendarDays.CreateRecordManager();
					vIR.Calendar = Object.Ref;
					vIR.Period = vCurDateTime; 
					vIR.AccountingDate = vCurDate; 
					If Type = "CatalogRef.CalendarDayTypes" And ValueIsFilled(Value) Then
						vIR.CalendarDayType = Value;				
						If vActiveRow <> Undefined Then
							vIR.Timetable = vActiveRow.Timetable;
							vIR.PriceTag = vActiveRow.PriceTag;
							vIR.RoomPrice = vActiveRow.RoomPrice;
							vIR.RoomPriceCurrency = vActiveRow.RoomPriceCurrency;
							vIR.Remarks = vActiveRow.Remarks;
						EndIf;
					ElsIf Type = "CatalogRef.TimeTables" And ValueIsFilled(Value) Then
						vIR.Timetable = Value;				
						If vActiveRow <> Undefined Then
							vIR.CalendarDayType = vActiveRow.CalendarDayType;
							vIR.PriceTag = vActiveRow.PriceTag;
							vIR.RoomPrice = vActiveRow.RoomPrice;
							vIR.RoomPriceCurrency = vActiveRow.RoomPriceCurrency;
							vIR.Remarks = vActiveRow.Remarks;
						EndIf;
					ElsIf Type = "CatalogRef.PriceTags" And ValueIsFilled(Value) Then                                   
						vIR.PriceTag = Value;
						If vActiveRow <> Undefined Then
							vIR.CalendarDayType = vActiveRow.CalendarDayType;
							vIR.Timetable = vActiveRow.Timetable;
							vIR.RoomPrice = vActiveRow.RoomPrice;
							vIR.RoomPriceCurrency = vActiveRow.RoomPriceCurrency;
							vIR.Remarks = vActiveRow.Remarks;
						EndIf;
					EndIf;	
					vIR.Author = SessionParameters.CurrentUser;
					vIR.Write(True);
				EndIf;	
			EndDo;

			CommitTransaction();
		EndIf;                                                  
	Else
		If ValueIsFilled(BegDate) And ValueIsFilled(EndDate) Then
			vStartDate = BegOfDay(BegDate);
			vPrevYearStartDate = Date(CopyYear, Month(vStartDate), Day(vStartDate), 0, 0, 0);
			
			vEndDate = BegOfDay(EndDate);
			vPrevYearEndDate = Date(CopyYear, Month(vEndDate), Day(vEndDate), 0, 0, 0);
			
			// Read current calendar state
			vActiveRecords = ReadCurrentStateOfCalendar(vPrevYearStartDate, vPrevYearEndDate, vCurDateTime);
			
			BeginTransaction();
			
			vCurDate = vStartDate;
			vPrevYearCurDate = '00010101';
			vPrevYearRecordsRow = Undefined;
			While vCurDate <= vEndDate Do
				vSavYearRecordsRow = vPrevYearRecordsRow;
				
				vSavPrevYearCurDate = vPrevYearCurDate;
				Try
					vPrevYearCurDate = Date(CopyYear, Month(vCurDate), Day(vCurDate), 0, 0, 0);
				Except
					vPrevYearCurDate = vSavPrevYearCurDate;
				EndTry;
				
				vPrevYearRecordsRow = Undefined;
				If Type = "CatalogRef.RoomTypes" And ValueIsFilled(RoomType) Then
					vPrevYearRecordsRows = vActiveRecords.FindRows(New Structure("AccountingDate, RoomType", vPrevYearCurDate, RoomType));
					If vPrevYearRecordsRows.Count() > 0 Then
						vPrevYearRecordsRow = vPrevYearRecordsRows.Get(vPrevYearRecordsRows.Count() - 1);
					EndIf;
				Else
					vPrevYearRecordsRows = vActiveRecords.FindRows(New Structure("AccountingDate", vPrevYearCurDate));
					If vPrevYearRecordsRows.Count() > 0 Then
						vPrevYearRecordsRow = vPrevYearRecordsRows.Get(vPrevYearRecordsRows.Count() - 1);
					EndIf;
				EndIf;
				If vPrevYearRecordsRow = Undefined Then
					vPrevYearRecordsRow = vSavYearRecordsRow;
				EndIf;
				If vPrevYearRecordsRow <> Undefined Then
					If Type = "CatalogRef.RoomTypes" And ValueIsFilled(RoomType) Then
						vIR = InformationRegisters.CalendarDaysByRoomTypes.CreateRecordManager();
						vIR.Calendar = Object.Ref;
						vIR.Period = vCurDateTime; 
						vIR.AccountingDate = vCurDate; 
						vIR.Hotel = RoomType.Owner; 
						vIR.RoomType = RoomType;
						vIR.CalendarDayType = vPrevYearRecordsRow.CalendarDayType;
						vIR.PriceTag = vPrevYearRecordsRow.PriceTag;
						vIR.RoomPrice = vPrevYearRecordsRow.RoomPrice;
						vIR.RoomPriceCurrency = vPrevYearRecordsRow.RoomPriceCurrency;
						vIR.Remarks = vPrevYearRecordsRow.Remarks;
						vIR.Author = SessionParameters.CurrentUser;
						vIR.Write(True);
					Else
						vIR = InformationRegisters.CalendarDays.CreateRecordManager();
						vIR.Calendar = Object.Ref;
						vIR.Period = vCurDateTime;
						vIR.AccountingDate = vCurDate;
						vIR.CalendarDayType = vPrevYearRecordsRow.CalendarDayType;
						vIR.Timetable = vPrevYearRecordsRow.Timetable;
						vIR.PriceTag = vPrevYearRecordsRow.PriceTag;
						vIR.RoomPrice = vPrevYearRecordsRow.RoomPrice;
						vIR.RoomPriceCurrency = vPrevYearRecordsRow.RoomPriceCurrency;
						vIR.Remarks = vPrevYearRecordsRow.Remarks;
						vIR.Author = SessionParameters.CurrentUser;
						vIR.Write();
					EndIf;
				EndIf;
				
				vCurDate = vCurDate + (24 * 3600);
			EndDo;
			
			CommitTransaction();
		Else
			vMinDate = '39991231';
			vMaxDate = '00010101';

			vPrevYearMinDate = '39991231';
			vPrevYearMaxDate = '00010101';

			For Each vSA In SelectedDays Do
				vCurDate = vSA.Value;
				Try
					vMinDate = Min(vMinDate, vCurDate); 
					vMaxDate = Max(vMaxDate, vCurDate); 

					vPrevYearCurDate = Date(CopyYear, Month(vCurDate), Day(vCurDate), 0, 0, 0);
					vPrevYearMinDate = Min(vPrevYearMinDate, vPrevYearCurDate); 
					vPrevYearMaxDate = Max(vPrevYearMaxDate, vPrevYearCurDate); 
				Except
				EndTry;
			EndDo;
			
			vCacheUpdateStartDate = vMinDate;
			vCacheUpdateEndDate = vMaxDate;
			
			// Read current calendar state
			vActiveRecords = ReadCurrentStateOfCalendar(vPrevYearMinDate, vPrevYearMaxDate, vCurDateTime);

			BeginTransaction();
			
			vPrevYearCurDate = '00010101';
			vPrevYearRecordsRow = Undefined;
			For Each vSA In SelectedDays Do
				vCurDate = vSA.Value;

				vSavYearRecordsRow = vPrevYearRecordsRow;
				
				vSavPrevYearCurDate = vPrevYearCurDate;
				Try
					vPrevYearCurDate = Date(CopyYear, Month(vCurDate), Day(vCurDate), 0, 0, 0);
				Except
					vPrevYearCurDate = vSavPrevYearCurDate;
				EndTry;
				
				vPrevYearRecordsRow = Undefined;
				If Type = "CatalogRef.RoomTypes" And ValueIsFilled(RoomType) Then
					vPrevYearRecordsRows = vActiveRecords.FindRows(New Structure("AccountingDate, RoomType", vPrevYearCurDate, RoomType));
					If vPrevYearRecordsRows.Count() > 0 Then
						vPrevYearRecordsRow = vPrevYearRecordsRows.Get(vPrevYearRecordsRows.Count() - 1);
					EndIf;
				Else
					vPrevYearRecordsRows = vActiveRecords.FindRows(New Structure("AccountingDate", vPrevYearCurDate));
					If vPrevYearRecordsRows.Count() > 0 Then
						vPrevYearRecordsRow = vPrevYearRecordsRows.Get(vPrevYearRecordsRows.Count() - 1);
					EndIf;
				EndIf;
				If vPrevYearRecordsRow = Undefined Then
					vPrevYearRecordsRow = vSavYearRecordsRow;
				EndIf;
				If vPrevYearRecordsRow <> Undefined Then
					If Type = "CatalogRef.RoomTypes" And ValueIsFilled(RoomType) Then
						vIR = InformationRegisters.CalendarDaysByRoomTypes.CreateRecordManager();
						vIR.Calendar = Object.Ref;
						vIR.Period = vCurDateTime; 
						vIR.AccountingDate = vCurDate; 
						vIR.Hotel = RoomType.Owner; 
						vIR.RoomType = RoomType;
						vIR.CalendarDayType = vPrevYearRecordsRow.CalendarDayType;
						vIR.PriceTag = vPrevYearRecordsRow.PriceTag;
						vIR.RoomPrice = vPrevYearRecordsRow.RoomPrice;
						vIR.RoomPriceCurrency = vPrevYearRecordsRow.RoomPriceCurrency;
						vIR.Remarks = vPrevYearRecordsRow.Remarks;
						vIR.Author = SessionParameters.CurrentUser;
						vIR.Write(True);
					Else
						vIR = InformationRegisters.CalendarDays.CreateRecordManager();
						vIR.Calendar = Object.Ref;
						vIR.Period = vCurDateTime;
						vIR.AccountingDate = vCurDate;
						vIR.CalendarDayType = vPrevYearRecordsRow.CalendarDayType;
						vIR.Timetable = vPrevYearRecordsRow.Timetable;
						vIR.PriceTag = vPrevYearRecordsRow.PriceTag;
						vIR.RoomPrice = vPrevYearRecordsRow.RoomPrice;
						vIR.RoomPriceCurrency = vPrevYearRecordsRow.RoomPriceCurrency;
						vIR.Remarks = vPrevYearRecordsRow.Remarks;
						vIR.Author = SessionParameters.CurrentUser;
						vIR.Write();
					EndIf;
				EndIf;	
			EndDo;
			
			CommitTransaction();
		EndIf;
	EndIf;
	
	// Fill legend
	FillColorTable();
	
	// Redraw calendar
	InitCalendar();
	RefreshDayTypeName();
	
	// Update price cache if necessary
	vHotel = SessionParameters.CurrentHotel;
	If ValueIsFilled(Object.Hotel) Then
		vHotel = Object.Hotel;
	EndIf;
	If ValueIsFilled(Object.Ref) And ValueIsFilled(vHotel) And vHotel.UseRoomRateDailyPrices Then
		vToday = BegOfDay(vCurDateTime);
		vPeriodFrom = Max(vToday, vCacheUpdateStartDate);
		vPeriodTo = Max(vToday, vCacheUpdateEndDate);
		If vPeriodFrom <= vPeriodTo And ValueIsFilled(vPeriodFrom) Then
			vRatesList = GetRatesByCalendar(Object.Ref, vPeriodFrom, vPeriodTo);
			RunFillRoomRatePricesCacheAtServer(vHotel, vRatesList, vPeriodFrom, vPeriodTo);
		EndIf;
	EndIf;
EndProcedure // FillCalendarAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure InitCalendar() 
	If ValueIsFilled(BegDate) And ValueIsFilled(EndDate) Then
		vPeriodMod = True;
	Else
		vPeriodMod = False;
	EndIf;	
	vDayTypes = GetDayType(BegOfYear(CalendarDate),EndOfYear(CalendarDate));
	vColors = ColorSettings.Unload();;

	SHCalendar.Clear();
	SHCalendar.FitToPage = False;
	
	vTemplate  = FormAttributeToValue("Object").GetTemplate("CalendarMasterTemplate"); 
	vYaer = BegOfYear(CalendarDate);
	Month1 = vYaer;
	vSH = New SpreadsheetDocument;
	
	vEditDateColor         = WebColors.Khaki;
	vEditCurrDateColor     = WebColors.DarkKhaki;
	vDateColor             = WebColors.White;
    vCurrentDateTypeColor  = WebColors.LightBlue;

	vMonthTemp   = vTemplate.GetArea("Month");
	vEmptyTemp   = vTemplate.GetArea("Empty");
	vDayTemp     = vTemplate.GetArea("Day");
	vDayTypeTemp = vTemplate.GetArea("DayType");
	vEmptyDayTemp   = vTemplate.GetArea("emptyDay");       	
	Line2 = New Line(SpreadsheetDocumentCellLineType.Solid,3);
	Line0 = New Line(SpreadsheetDocumentCellLineType.None,0);
	
	For vID = 1 to 4 Do
		Month2 = AddMonth(Month1,1);
		Month3 = AddMonth(Month2,1);
		
		MaxDay = Day(EndOfMonth(Month1));
		MaxDay = ?(Day(EndOfMonth(Month2)) > MaxDay,Day(EndOfMonth(Month2)),MaxDay);
		MaxDay = ?(Day(EndOfMonth(Month3)) > MaxDay,Day(EndOfMonth(Month3)),MaxDay);
		
		MaxWeekDay = WeekDay(Month1);
		MaxWeekDay = ?(WeekDay(Month2) > MaxWeekDay,WeekDay(Month2),MaxWeekDay);
		MaxWeekDay = ?(WeekDay(Month3) > MaxWeekDay,WeekDay(Month3),MaxWeekDay);
		
		MaxDay = MaxDay + MaxWeekDay;
		
		vMonthIter = MaxDay/7;
		If MaxDay%7 > 0 Then
			vMonthIter = vMonthIter + 1;
		EndIf;
		
		// Head
		vSH.Put(vDayTypeTemp); 	
		vSH.Put(vDayTypeTemp); 	
		
		vSH.Put(vEmptyTemp); 		
		vMonthTemp.Parameters.param = Format(Month1,NStr("en = 'L=en; DF=MMMM'; ru = 'L=ru; DF=MMMM'; de = 'L=de; DF=MMMM'"));
		vSH.Join(vMonthTemp);
		
		vSH.Join(vEmptyTemp);
		vMonthTemp.Parameters.param = Format(Month2,NStr("en = 'L=en; DF=MMMM'; ru = 'L=ru; DF=MMMM'; de = 'L=de; DF=MMMM'")); 
		vSH.Join(vMonthTemp);
		
		vSH.Join(vEmptyTemp);
		vMonthTemp.Parameters.param = Format(Month3,NStr("en = 'L=en; DF=MMMM'; ru = 'L=ru; DF=MMMM'; de = 'L=de; DF=MMMM'")); 
		vSH.Join(vMonthTemp);
		
		MonthDay1 = Month1;
		MonthDay2 = Month2;
		MonthDay3 = Month3;
		
		For j = 1 To vMonthIter Do
			vSHValue = New SpreadsheetDocument;
			
			vSH.Put(vEmptyDayTemp);			
			For vDay = 1 To 7 Do		
				If WeekDay(MonthDay1) = vDay And Month(MonthDay1) = Month(Month1) Then   
					vParam = New Structure;
					vParam.Insert("Date",MonthDay1);
					vTypeRow  = vDayTypes.Find(MonthDay1, "Period");
					If ValueIsFilled(vTypeRow) And ValueIsFilled(vTypeRow.Value) Then
						vColorRow = vColors.Find(vTypeRow.Value, "Value");
						vDayTemp.CurrentArea.BottomBorder =	Line2;
						If vColorRow <> Undefined Then
							vDayTemp.CurrentArea.BorderColor = vColorRow.Color;
						EndIf;
						If vTypeRow.Value = FilterType Then 
							vDayTemp.CurrentArea.BackColor = vCurrentDateTypeColor;
						EndIf;						
						vParam.Insert("Value", vTypeRow.Value);
					Else 
						vDayTemp.CurrentArea.BottomBorder =	Line0;
					EndIf;						
					vDayTemp.Parameters.param       = Format(MonthDay1, "DF=d");
					vDayTemp.Parameters.paramDetail = vParam;
					If vPeriodMod Then
						If ValueIsFilled(BegDate) And ValueIsFilled(EndDate) Then
							If BegDate <= MonthDay1 And EndDate >= MonthDay1 Then
								If MonthDay1 = BegDate Or MonthDay1 = EndDate Then
									vDayTemp.CurrentArea.BackColor = vEditCurrDateColor;
								Else
									vDayTemp.CurrentArea.BackColor = vEditDateColor;	
								EndIf;							
							EndIf;
						EndIf;
					Else
						vDate = SelectedDays.FindByValue(MonthDay1);
						If vDate <> Undefined Then
							vDayTemp.CurrentArea.BackColor = vEditDateColor;	
						EndIf;
					EndIf;
					
					vSH.Join(vDayTemp);
					MonthDay1 = MonthDay1 + 24*60*60;
				Else					
					vDayTemp.Parameters.param = Undefined;
					vSH.Join(vDayTemp);	
				EndIf;
				vDayTemp.CurrentArea.BottomBorder =	Line0;				
				vDayTemp.CurrentArea.BackColor      = vDateColor;
				vDayTemp.Parameters.paramDetail     = Undefined;
			EndDo;			
			vSH.Join(vEmptyDayTemp);
			
			For vDay = 1 To 7 Do
				If WeekDay(MonthDay2) = vDay And Month(MonthDay2) = Month(Month2) Then                                             
					vParam = New Structure;
					vParam.Insert("Date",MonthDay2);
					vTypeRow  = vDayTypes.Find(MonthDay2,"Period");
					If ValueIsFilled(vTypeRow) And ValueIsFilled(vTypeRow.Value) Then
						vColorRow = vColors.Find(vTypeRow.Value,"Value");
						vDayTemp.CurrentArea.BottomBorder =	Line2;
						If vColorRow <> Undefined Then
							vDayTemp.CurrentArea.BorderColor = vColorRow.Color;
						EndIf;
						If vTypeRow.Value = FilterType Then 
							vDayTemp.CurrentArea.BackColor = vCurrentDateTypeColor;
						EndIf;
						vParam.Insert("Value",vTypeRow.Value);
					Else 
						vDayTemp.CurrentArea.BottomBorder =	Line0;
					EndIf;						
					vDayTemp.Parameters.param       = Format(MonthDay2,"DF=d");
					vDayTemp.Parameters.paramDetail = vParam;
					If vPeriodMod Then
						If ValueIsFilled(BegDate) And ValueIsFilled(EndDate) Then
							If BegDate <= MonthDay2 And EndDate >= MonthDay2 Then
								If MonthDay2 = BegDate Or MonthDay2 = EndDate Then
									vDayTemp.CurrentArea.BackColor = vEditCurrDateColor;
								Else
									vDayTemp.CurrentArea.BackColor = vEditDateColor;								
								EndIf;						
							EndIf;
						EndIf;	
					Else
						vDate = SelectedDays.FindByValue(MonthDay2);
						If vDate <> Undefined Then
							vDayTemp.CurrentArea.BackColor = vEditDateColor;	
						EndIf;		
					EndIf;					
					vSH.Join(vDayTemp);					
					MonthDay2 = MonthDay2 + 24*60*60;
				Else
					vDayTemp.Parameters.param = Undefined;
					vSH.Join(vDayTemp);					
				EndIf;
				vDayTemp.CurrentArea.BottomBorder =	Line0;
				vDayTemp.CurrentArea.BackColor  = vDateColor;				
				vDayTemp.Parameters.paramDetail = Undefined;				
			EndDo;			
			vSH.Join(vEmptyDayTemp);			

			For vDay = 1 To 7 Do
				If WeekDay(MonthDay3) = vDay And Month(MonthDay3) = Month(Month3) Then    
					vParam = New Structure;
					vParam.Insert("Date",MonthDay3);
					vTypeRow  = vDayTypes.Find(MonthDay3,"Period");
					If ValueIsFilled(vTypeRow) And ValueIsFilled(vTypeRow.Value) Then
						vColorRow = vColors.Find(vTypeRow.Value,"Value");
						vDayTemp.CurrentArea.BottomBorder =	Line2;
						If vColorRow <> Undefined Then
							vDayTemp.CurrentArea.BorderColor = vColorRow.Color;
						EndIf;
						If vTypeRow.Value = FilterType Then 
							vDayTemp.CurrentArea.BackColor = vCurrentDateTypeColor;
						EndIf;						
						vParam.Insert("Value",vTypeRow.Value);
					Else 
						vDayTemp.CurrentArea.BottomBorder =	Line0;						
					EndIf;						
					vDayTemp.Parameters.param       = Format(MonthDay3,"DF=d");
					vDayTemp.Parameters.paramDetail = vParam;
					If vPeriodMod Then
						If ValueIsFilled(BegDate) And ValueIsFilled(EndDate) Then
							If BegDate <= MonthDay3 And EndDate >= MonthDay3 Then
								If MonthDay3 = BegDate Or MonthDay3 = EndDate Then
									vDayTemp.CurrentArea.BackColor = vEditCurrDateColor;
								Else
									vDayTemp.CurrentArea.BackColor = vEditDateColor;								
								EndIf;							
							EndIf;
						EndIf;
					Else
						vDate = SelectedDays.FindByValue(MonthDay3);
						If vDate <> Undefined Then
							vDayTemp.CurrentArea.BackColor = vEditDateColor;	
						EndIf;	
					EndIf;					
					vSH.Join(vDayTemp);					
					MonthDay3 = MonthDay3 + 24*60*60;
				Else
					vDayTemp.Parameters.param = Undefined;
					vSH.Join(vDayTemp); 		
				EndIf;
				vDayTemp.CurrentArea.BottomBorder =	Line0;				
				vDayTemp.CurrentArea.BackColor  = vDateColor;
				vDayTemp.Parameters.paramDetail = Undefined;	
			EndDo;
			vSH.Put(vSHValue);			
		EndDo;
		vSH.Put(vEmptyTemp); 	
		Month1 = AddMonth(Month3,1);
	EndDo;
	SHCalendar = vSH;  	
	FillLegends();
EndProcedure // InitCalendar

// -----------------------------------------------------------------------------
&AtServer
Function GetDayType(BegDate, EndDate)
	If Type = "CatalogRef.CalendarDayTypes"  Then
		vQueryText = 
		"SELECT
		|	CalendarDays.CalendarDayType AS Value,
		|	CalendarDays.AccountingDate AS Period
		|FROM
		|	InformationRegister.CalendarDays.SliceLast(
		|			&qPriceCalculationDate,
		|			Calendar = &qCalendar
		|				AND (AccountingDate BETWEEN &qBegDate AND &qEndDate)) AS CalendarDays
		|
		|GROUP BY
		|	CalendarDays.CalendarDayType,
		|	CalendarDays.AccountingDate";	
	ElsIf Type = "CatalogRef.TimeTables" Then
		vQueryText = 
		"SELECT
		|	CalendarDays.Timetable AS Value,
		|	CalendarDays.AccountingDate AS Period
		|FROM
		|	InformationRegister.CalendarDays.SliceLast(
		|			&qPriceCalculationDate,
		|			Calendar = &qCalendar
		|				AND (AccountingDate BETWEEN &qBegDate AND &qEndDate)) AS CalendarDays";
	ElsIf Type = "CatalogRef.PriceTags" Then                                   
		vQueryText = 
		"SELECT
		|	CalendarDays.PriceTag AS Value,
		|	CalendarDays.AccountingDate AS Period
		|FROM
		|	InformationRegister.CalendarDays.SliceLast(
		|			&qPriceCalculationDate,
		|			Calendar = &qCalendar
		|				AND (AccountingDate BETWEEN &qBegDate AND &qEndDate)) AS CalendarDays";
	ElsIf Type = "CatalogRef.RoomTypes" Then                                   
		vQueryText = 
		"SELECT
		|	CalendarDays.CalendarDayType AS Value,
		|	CalendarDays.AccountingDate AS Period
		|FROM
		|	InformationRegister.CalendarDaysByRoomTypes.SliceLast(
		|			&qPriceCalculationDate,
		|			Calendar = &qCalendar
		|				AND (AccountingDate BETWEEN &qBegDate AND &qEndDate)
		|				AND RoomType = &qRoomType
		|				AND Hotel = &qHotel) AS CalendarDays";
	EndIf;		
	
	vQuery = New Query;
	vQuery.Text = vQueryText;
	
	vQuery.SetParameter("qRoomType", RoomType);
	vQuery.SetParameter("qHotel", RoomType.Owner);
	
	vQuery.SetParameter("qCalendar", Object.Ref);
	vQuery.SetParameter("qPriceCalculationDate", ?(ValueIsFilled(PriceCalculationDate), New Boundary(PriceCalculationDate, BoundaryType.Including), CurrentSessionDate()));

	vQuery.SetParameter("qBegDate", BegDate);
	vQuery.SetParameter("qEndDate", EndDate);
	
	vQueryResult = vQuery.Execute();
	
	Return vQueryResult.Unload();
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Procedure FillColorTable()   
	ColorSettings.Clear();
	If Type = "CatalogRef.CalendarDayTypes" Then
		vQueryText = 
		"SELECT
		|	CalendarDays.CalendarDayType AS Value
		|FROM
		|	InformationRegister.CalendarDays.SliceLast(
		|			&qPriceCalculationDate,
		|			Calendar = &qCalendar
		|				AND (AccountingDate BETWEEN &qStart AND &qFinish)) AS CalendarDays
		|
		|GROUP BY
		|	CalendarDays.CalendarDayType";	
	ElsIf Type = "CatalogRef.TimeTables" Then
		vQueryText = 
		"SELECT
		|	CalendarDays.Timetable AS Value
		|FROM
		|	InformationRegister.CalendarDays.SliceLast(
		|			&qPriceCalculationDate,
		|			Calendar = &qCalendar
		|				AND (AccountingDate BETWEEN &qStart AND &qFinish)) AS CalendarDays
		|
		|GROUP BY
		|	CalendarDays.Timetable";
	ElsIf Type = "CatalogRef.PriceTags" Then                                   
		vQueryText = 
		"SELECT
		|	CalendarDays.PriceTag AS Value
		|FROM
		|	InformationRegister.CalendarDays.SliceLast(
		|			&qPriceCalculationDate,
		|			Calendar = &qCalendar
		|				AND (AccountingDate BETWEEN &qStart AND &qFinish)) AS CalendarDays
		|
		|GROUP BY
		|	CalendarDays.PriceTag";
	ElsIf Type = "CatalogRef.RoomTypes" Then                                   
		vQueryText = 
		"SELECT
		|	CalendarDays.CalendarDayType AS Value
		|FROM
		|	InformationRegister.CalendarDaysByRoomTypes.SliceLast(
		|			&qPriceCalculationDate,
		|			Calendar = &qCalendar
		|				AND (AccountingDate BETWEEN &qStart AND &qFinish)
		|				AND RoomType = &qRoomType
		|				AND Hotel = &qHotel) AS CalendarDays
		|
		|GROUP BY
		|	CalendarDays.CalendarDayType";
	EndIf;		
	
	vQuery = New Query;
	vQuery.Text = vQueryText;
	
	vQuery.SetParameter("qRoomType", RoomType);
	vQuery.SetParameter("qHotel", RoomType.Owner);

	vQuery.SetParameter("qCalendar", Object.Ref);
	vQuery.SetParameter("qPriceCalculationDate", ?(ValueIsFilled(PriceCalculationDate), New Boundary(PriceCalculationDate, BoundaryType.Including), CurrentSessionDate()));

	vQuery.SetParameter("qStart", BegOfYear(CalendarDate));
	vQuery.SetParameter("qFinish", EndOfYear(CalendarDate));
	
	vQueryResult = vQuery.Execute();
	
	vSelectionDetailRecords = vQueryResult.Select();
	vRG = New RandomNumberGenerator;

	While vSelectionDetailRecords.Next() Do
		If ValueIsFilled(vSelectionDetailRecords.Value) Then
			vCurDT = vSelectionDetailRecords.Value;
			If Not vCurDT.IsFolder Then
				vRow = ColorSettings.Add();
				If TypeOf(vCurDT) = Type("CatalogRef.CalendarDayTypes") Then
					If vCurDT.Color <> Undefined And vCurDT.Color <> Null Then
						vColor = vCurDT.Color.Get();
					Else
						vColor = Undefined;
					EndIf;
				Else
					vColor = Undefined;
				EndIf;
				If vColor = Undefined Then 
					vRed = vRG.RandomNumber(1, 255);
					vBlue = vRG.RandomNumber(1, 255);
					vGreen = vRG.RandomNumber(1, 255);
					
					vColor = tcCommonFunctionOnClientServer.ColorConstructor(vRed, vGreen, vBlue);
					
					If TypeOf(vCurDT) = Type("CatalogRef.CalendarDayTypes") Then
						Try
							vDayObj = vCurDT.GetObject();
							vDayObj.Color = New ValueStorage(vColor);
							vDayObj.Write();
						Except
						EndTry;
					EndIf;
				EndIf;
				vRow.Color = vColor;
				vRow.Value = vCurDT;
			EndIf;
		EndIf;
	EndDo;
EndProcedure // FillColorTable

// -----------------------------------------------------------------------------
&AtServer
Procedure FillLegends()   
	If Type = "CatalogRef.CalendarDayTypes"  Then
		vQueryText = 
		"SELECT
		|	CalendarDays.CalendarDayType AS Value
		|FROM
		|	InformationRegister.CalendarDays.SliceLast(
		|			&qPriceCalculationDate,
		|			Calendar = &qCalendar
		|				AND (AccountingDate BETWEEN &qBegDate AND &qEndDate)) AS CalendarDays
		|
		|GROUP BY
		|	CalendarDays.CalendarDayType";	
	ElsIf Type = "CatalogRef.TimeTables" Then
		vQueryText = 
		"SELECT
		|	CalendarDays.Timetable AS Value
		|FROM
		|	InformationRegister.CalendarDays.SliceLast(
		|			&qPriceCalculationDate,
		|			Calendar = &qCalendar
		|				AND (AccountingDate BETWEEN &qBegDate AND &qEndDate)) AS CalendarDays
		|
		|GROUP BY
		|	CalendarDays.Timetable";
	ElsIf Type = "CatalogRef.PriceTags" Then                                   
		vQueryText = 
		"SELECT
		|	CalendarDays.PriceTag AS Value
		|FROM
		|	InformationRegister.CalendarDays.SliceLast(
		|			&qPriceCalculationDate,
		|			Calendar = &qCalendar
		|				AND (AccountingDate BETWEEN &qBegDate AND &qEndDate)) AS CalendarDays
		|
		|GROUP BY
		|	CalendarDays.PriceTag";
	ElsIf Type = "CatalogRef.RoomTypes" Then                                   
		vQueryText = 
		"SELECT
		|	CalendarDays.CalendarDayType AS Value
		|FROM
		|	InformationRegister.CalendarDaysByRoomTypes.SliceLast(
		|			&qPriceCalculationDate,
		|			Calendar = &qCalendar
		|				AND (AccountingDate BETWEEN &qBegDate AND &qEndDate)
		|				AND RoomType = &qRoomType
		|				AND Hotel = &qHotel) AS CalendarDays
		|
		|GROUP BY
		|	CalendarDays.CalendarDayType";
	EndIf;		
	
	vQuery = New Query;
	vQuery.Text = vQueryText;	
	
	vQuery.SetParameter("qRoomType", RoomType);
	vQuery.SetParameter("qHotel", RoomType.Owner);

	vQuery.SetParameter("qCalendar", Object.Ref);
	vQuery.SetParameter("qPriceCalculationDate", ?(ValueIsFilled(PriceCalculationDate), New Boundary(PriceCalculationDate, BoundaryType.Including), CurrentSessionDate()));
	vQuery.SetParameter("qBegDate", BegOfYear(CalendarDate));
	vQuery.SetParameter("qEndDate", EndOfYear(CalendarDate));
	
	vQueryResult = vQuery.Execute();	
	vSelectionDetailRecords = vQueryResult.Select();
	vColors = ColorSettings.Unload();
	
	SHLegends.Clear();
	
	vTemplate    = FormAttributeToValue("Object").GetTemplate("CalendarMasterTemplate");	
	vDayTemp     = vTemplate.GetArea("Day");	
	vMarginTemp  = vTemplate.GetArea("Margin");    
	vLegend      = vTemplate.GetArea("Legend");
	vDayTypeTemp = vTemplate.GetArea("DayType");
	vLegend.Parameters.param = NStr("en = 'Legends:'; ru = 'Легенда:'");; 
	SHLegends.Put(vMarginTemp);
	SHLegends.Join(vLegend);
	SHLegends.Put(vDayTypeTemp);
	While vSelectionDetailRecords.Next() Do
		If ValueIsFilled(vSelectionDetailRecords.Value) Then
			vColorRow = vColors.Find(vSelectionDetailRecords.Value, "Value");
			If vColorRow <> Undefined Then
				vDayTemp.CurrentArea.BackColor = vColorRow.Color;
			EndIf;
			vLegend.Parameters.param       = TrimAll(vSelectionDetailRecords.Value) + " (" + TrimAll(vSelectionDetailRecords.Value.Code) + ")"; 
			vLegend.Parameters.paramDetail = vSelectionDetailRecords.Value;
			SHLegends.Put(vMarginTemp);
			SHLegends.Join(vDayTemp);
			SHLegends.Join(vLegend);
			SHLegends.Put(vDayTypeTemp);
		EndIf;
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearCalendar() 
	ColorSettings.Clear();
	SHCalendar.Area().Clear(True, True, True);
	SHLegends.Area().Clear(True, True, True);
EndProcedure // ClearCalendar

// -----------------------------------------------------------------------------
&AtClient
Procedure ResetCurrentAreas() Export
	ResetCurrentAreaMode = True;
	Items.SHCalendar.CurrentArea = SHCalendar.Area(1, 1, 1, 1);
	Items.SHLegends.CurrentArea = SHLegends.Area(1, 1, 1, 1);
	ResetCurrentAreaMode = False;
EndProcedure // ResetCurrentAreas

// -----------------------------------------------------------------------------
&AtServer
Procedure GetHistoryYears()
	Items.HistoryPeriodYear.ChoiceList.Clear();
	Items.HistoryPeriodMonth.ChoiceList.Clear();
	Items.HistoryPeriodDay.ChoiceList.Clear();
	Items.HistoryPeriod.ChoiceList.Clear();

	CurrentValue = Undefined;
	CurrentValueDescription = "";
	CurrentDate = '00010101';
	
	SHCalendar.Clear();
	SHLegends.Clear();
	
	vQry = New Query();
	If Type = "CatalogRef.RoomTypes" Then
		vQry.Text = 
		"SELECT DISTINCT
		|	YEAR(CalendarDaysByRoomTypes.Period) AS Year
		|FROM
		|	InformationRegister.CalendarDaysByRoomTypes AS CalendarDaysByRoomTypes
		|WHERE
		|	CalendarDaysByRoomTypes.Calendar = &qCalendar
		|	AND CalendarDaysByRoomTypes.RoomType = &qRoomType
		|	AND CalendarDaysByRoomTypes.AccountingDate BETWEEN &qBegDate AND &qEndDate
		|
		|ORDER BY
		|	Year";	
		vQry.SetParameter("qRoomType", RoomType);
	Else
		vQry.Text = 
		"SELECT DISTINCT
		|	YEAR(CalendarDays.Period) AS Year
		|FROM
		|	InformationRegister.CalendarDays AS CalendarDays
		|WHERE
		|	CalendarDays.Calendar = &qCalendar
		|	AND CalendarDays.AccountingDate BETWEEN &qBegDate AND &qEndDate
		|
		|ORDER BY
		|	Year";	
	EndIf;
	vQry.SetParameter("qCalendar", Object.Ref);
	vQry.SetParameter("qBegDate", BegOfYear(CalendarDate));
	vQry.SetParameter("qEndDate", EndOfYear(CalendarDate));
	
	vHistoryYears = vQry.Execute().Unload();
	For Each vHistoryYearsRow In vHistoryYears Do
		Items.HistoryPeriodYear.ChoiceList.Add(vHistoryYearsRow.Year, Format(vHistoryYearsRow.Year, "ND=4; NFD=0; NLZ=; NG="));
	EndDo;
EndProcedure // GetHistoryYears

// -----------------------------------------------------------------------------
&AtServer
Procedure GetHistoryMonths()
	Items.HistoryPeriodMonth.ChoiceList.Clear();
	Items.HistoryPeriodDay.ChoiceList.Clear();
	Items.HistoryPeriod.ChoiceList.Clear();

	CurrentValue = Undefined;
	CurrentValueDescription = "";
	CurrentDate = '00010101';

	vQry = New Query();
	If Type = "CatalogRef.RoomTypes" Then
		vQry.Text = 
		"SELECT DISTINCT
		|	MONTH(CalendarDaysByRoomTypes.Period) AS Month
		|FROM
		|	InformationRegister.CalendarDaysByRoomTypes AS CalendarDaysByRoomTypes
		|WHERE
		|	CalendarDaysByRoomTypes.Calendar = &qCalendar
		|	AND CalendarDaysByRoomTypes.RoomType = &qRoomType
		|	AND CalendarDaysByRoomTypes.AccountingDate BETWEEN &qBegDate AND &qEndDate
		|	AND YEAR(CalendarDaysByRoomTypes.Period) = &qYear
		|
		|ORDER BY
		|	Month";	
		vQry.SetParameter("qRoomType", RoomType);
	Else
		vQry.Text = 
		"SELECT DISTINCT
		|	MONTH(CalendarDays.Period) AS Month
		|FROM
		|	InformationRegister.CalendarDays AS CalendarDays
		|WHERE
		|	CalendarDays.Calendar = &qCalendar
		|	AND CalendarDays.AccountingDate BETWEEN &qBegDate AND &qEndDate
		|	AND YEAR(CalendarDays.Period) = &qYear
		|
		|ORDER BY
		|	Month";	
	EndIf;
	vQry.SetParameter("qCalendar", Object.Ref);
	vQry.SetParameter("qBegDate", BegOfYear(CalendarDate));
	vQry.SetParameter("qEndDate", EndOfYear(CalendarDate));
	vQry.SetParameter("qYear", HistoryPeriodYear);
	
	vHistoryMonths = vQry.Execute().Unload();
	For Each vHistoryMonthsRow In vHistoryMonths Do
		vDate = Date(HistoryPeriodYear, vHistoryMonthsRow.Month, 1);
		Items.HistoryPeriodMonth.ChoiceList.Add(vHistoryMonthsRow.Month, Format(vHistoryMonthsRow.Month, "ND=2; NFD=0; NLZ=; NG=") + " - " + cmGetMonthName(vHistoryMonthsRow.Month, False) + " " + Format(HistoryPeriodYear, "ND=4; NFD=0; NLZ=; NG="));
	EndDo;
EndProcedure // GetHistoryMonths

// -----------------------------------------------------------------------------
&AtServer
Procedure GetHistoryDays()
	Items.HistoryPeriodDay.ChoiceList.Clear();
	Items.HistoryPeriod.ChoiceList.Clear();

	CurrentValue = Undefined;
	CurrentValueDescription = "";
	CurrentDate = '00010101';

	vQry = New Query();
	If Type = "CatalogRef.RoomTypes" Then
		vQry.Text = 
		"SELECT DISTINCT
		|	DAY(CalendarDaysByRoomTypes.Period) AS Day
		|FROM
		|	InformationRegister.CalendarDaysByRoomTypes AS CalendarDaysByRoomTypes
		|WHERE
		|	CalendarDaysByRoomTypes.Calendar = &qCalendar
		|	AND CalendarDaysByRoomTypes.RoomType = &qRoomType
		|	AND CalendarDaysByRoomTypes.AccountingDate BETWEEN &qBegDate AND &qEndDate
		|	AND YEAR(CalendarDaysByRoomTypes.Period) = &qYear
		|	AND MONTH(CalendarDaysByRoomTypes.Period) = &qMonth
		|
		|ORDER BY
		|	Day";	
		vQry.SetParameter("qRoomType", RoomType);
	Else
		vQry.Text = 
		"SELECT DISTINCT
		|	DAY(CalendarDays.Period) AS Day
		|FROM
		|	InformationRegister.CalendarDays AS CalendarDays
		|WHERE
		|	CalendarDays.Calendar = &qCalendar
		|	AND CalendarDays.AccountingDate BETWEEN &qBegDate AND &qEndDate
		|	AND YEAR(CalendarDays.Period) = &qYear
		|	AND MONTH(CalendarDays.Period) = &qMonth
		|
		|ORDER BY
		|	Day";	
	EndIf;
	vQry.SetParameter("qCalendar", Object.Ref);
	vQry.SetParameter("qBegDate", BegOfYear(CalendarDate));
	vQry.SetParameter("qEndDate", EndOfYear(CalendarDate));
	vQry.SetParameter("qYear", HistoryPeriodYear);
	vQry.SetParameter("qMonth", HistoryPeriodMonth);
	
	vHistoryDays = vQry.Execute().Unload();
	For Each vHistoryDaysRow In vHistoryDays Do
		vDate = Date(HistoryPeriodYear, HistoryPeriodMonth, vHistoryDaysRow.Day);
		Items.HistoryPeriodDay.ChoiceList.Add(vHistoryDaysRow.Day, Format(vDate, "DF=dd.MM.yyyy") + " - " + cmGetDayOfWeekName(WeekDay(vDate), True));
	EndDo;
EndProcedure // GetHistoryDays

// -----------------------------------------------------------------------------
&AtServer
Procedure GetHistoryPeriods()
	Items.HistoryPeriod.ChoiceList.Clear();

	CurrentValue = Undefined;
	CurrentValueDescription = "";
	CurrentDate = '00010101';

	vQry = New Query();
	If Type = "CatalogRef.RoomTypes" Then
		vQry.Text = 
		"SELECT DISTINCT
		|	CalendarDaysByRoomTypes.Period AS Period,
		|	CalendarDaysByRoomTypes.Author AS Author
		|FROM
		|	InformationRegister.CalendarDaysByRoomTypes AS CalendarDaysByRoomTypes
		|WHERE
		|	CalendarDaysByRoomTypes.Calendar = &qCalendar
		|	AND CalendarDaysByRoomTypes.RoomType = &qRoomType
		|	AND CalendarDaysByRoomTypes.AccountingDate BETWEEN &qBegDate AND &qEndDate
		|	AND YEAR(CalendarDaysByRoomTypes.Period) = &qYear
		|	AND MONTH(CalendarDaysByRoomTypes.Period) = &qMonth
		|	AND DAY(CalendarDaysByRoomTypes.Period) = &qDay
		|
		|ORDER BY
		|	Period";
		vQry.SetParameter("qRoomType", RoomType);
	Else
		vQry.Text = 
		"SELECT DISTINCT
		|	CalendarDays.Period AS Period,
		|	CalendarDays.Author AS Author
		|FROM
		|	InformationRegister.CalendarDays AS CalendarDays
		|WHERE
		|	CalendarDays.Calendar = &qCalendar
		|	AND CalendarDays.AccountingDate BETWEEN &qBegDate AND &qEndDate
		|	AND YEAR(CalendarDays.Period) = &qYear
		|	AND MONTH(CalendarDays.Period) = &qMonth
		|	AND DAY(CalendarDays.Period) = &qDay
		|
		|ORDER BY
		|	Period";
	EndIf;
	vQry.SetParameter("qCalendar", Object.Ref);
	vQry.SetParameter("qBegDate", BegOfYear(CalendarDate));
	vQry.SetParameter("qEndDate", EndOfYear(CalendarDate));
	vQry.SetParameter("qYear", HistoryPeriodYear);
	vQry.SetParameter("qMonth", HistoryPeriodMonth);
	vQry.SetParameter("qDay", HistoryPeriodDay);
	
	vHistoryPeriods = vQry.Execute().Unload();
	For Each vHistoryPeriodsRow In vHistoryPeriods Do
		Items.HistoryPeriod.ChoiceList.Add(vHistoryPeriodsRow.Period, Format(vHistoryPeriodsRow.Period, "DF=HH:mm:ss") + " - " + TrimAll(vHistoryPeriodsRow.Author));
	EndDo;
EndProcedure // GetHistoryPeriods

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowHistoryOnChange(pItem)
	If Not ValueIsFilled(Object.Ref) Then
		ShowMessageBox(, NStr("en='Calendar is not saved yet! Press <Write> button and try again.'; ru='Календарь еще не записан! Нажмите кнопку <Записать> и попробуйте еще раз.'; de='Der Kalender ist noch nicht aufgezeichnet! Klicken Sie auf die Schaltfläche <Speichern> und versuchen Sie es erneut.'"));
		ShowHistory = Not ShowHistory;
		Return;
	EndIf;

	PriceCalculationDate = '00010101';
	BegDate = '00010101';
	EndDate = '00010101';
	Items.HistoryPeriodYear.ChoiceList.Clear();
	Items.HistoryPeriodMonth.ChoiceList.Clear();
	Items.HistoryPeriodDay.ChoiceList.Clear();
	Items.HistoryPeriod.ChoiceList.Clear();
	Items.GroupHistory.Enabled = ShowHistory;

	ClearCalendar();
	If ShowHistory Then
		GetHistoryYears();
	Else
		HistoryPeriodYear = 0;
		HistoryPeriodMonth = 0;
		HistoryPeriodDay = 0;
		HistoryPeriod = '00010101';

		FillColorTable();
		InitCalendar();
	EndIf;
	FillCopyYear();
	ResetCurrentAreas();
EndProcedure // ShowHistoryOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure HistoryPeriodYearOnChange(pItem)
	HistoryPeriod = '00010101';
	Items.HistoryPeriodMonth.ChoiceList.Clear();
	Items.HistoryPeriodDay.ChoiceList.Clear();
	Items.HistoryPeriod.ChoiceList.Clear();
	If HistoryPeriodYear > 0 Then
		ClearCalendar();
		GetHistoryMonths();
	EndIf;
EndProcedure // HistoryPeriodYearOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure HistoryPeriodMonthOnChange(pItem)
	HistoryPeriod = '00010101';
	Items.HistoryPeriodDay.ChoiceList.Clear();
	Items.HistoryPeriod.ChoiceList.Clear();
	If HistoryPeriodYear > 0 And HistoryPeriodMonth > 0 Then
		ClearCalendar();
		GetHistoryDays();
	EndIf;
EndProcedure // HistoryPeriodMonthOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure HistoryPeriodDayOnChange(pItem)
	HistoryPeriod = '00010101';
	Items.HistoryPeriod.ChoiceList.Clear();
	If HistoryPeriodYear > 0 And HistoryPeriodMonth > 0 And HistoryPeriodDay > 0 Then
		ClearCalendar();
		GetHistoryPeriods();
	EndIf;
EndProcedure // HistoryPeriodDayOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure HistoryPeriodOnChange(pItem)
	If ValueIsFilled(HistoryPeriod) Then
		PriceCalculationDate = HistoryPeriod;
		FillColorTable();
		InitCalendar();
		ResetCurrentAreas();
	EndIf;
EndProcedure // HistoryPeriodOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure RefreshDayTypeName()
	vArea = StrSplit(Items.SHCalendar.CurrentArea.Name, ":");
	If vArea.Count() = 1 Then		
		vStruct = SHCalendar.Area(vArea[0]).Details;
		If ValueIsFilled(vStruct) And vStruct.Property("Date") Then
			CurrentDate = vStruct.Date;
			If vStruct.Property("Value") And ValueIsFilled(vStruct.Value) Then
				vDayTypeAttrs = tcOnServer.cmGetAtributeAsArray(vStruct.Value);
				CurrentValue = vStruct.Value; 
				CurrentValueDescription = Format(CurrentDate, "DF='d MMMM - '") + TrimAll(vDayTypeAttrs.Description) + " (" + TrimAll(vDayTypeAttrs.Code) + ")";
			Else
				CurrentValue = Undefined; 
				CurrentValueDescription = ""; 
			EndIf;	
		Else
			CurrentDate = '00010101';
			CurrentValue = Undefined; 
			CurrentValueDescription = ""; 
		EndIf;
	EndIf;
EndProcedure // RefreshDayTypeName

#EndRegion


