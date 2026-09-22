
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
		PeriodFrom = BegOfMonth(CurrentSessionDate()); // For beg of month
		PeriodTo = EndOfDay(CurrentSessionDate());
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
	If ReservationPeriodIsWithoutYear Then
		If Not ByGroupCreationDate Then
			If ValueIsFilled(DateFrom) And Not ValueIsFilled(DateTo) Then
				vParamPresentation = vParamPresentation + NStr("ru = 'Отбор брони созданной c '; en = 'Reservation date from '; de = 'Reservierungsdatum von '") + 
				                     Format(DateFrom, "DF=dd.MM") + 
				                     ";" + Chars.LF;
			ElsIf Not ValueIsFilled(DateFrom) And ValueIsFilled(DateTo) Then
				vParamPresentation = vParamPresentation + NStr("ru = 'Отбор брони созданной по '; en = 'Reservation date to '; de = 'Reservierungsdatum zu '") + 
				                     Format(DateTo, "DF=dd.MM") + 
				                     ";" + Chars.LF;
			ElsIf DateFrom = DateTo And (ValueIsFilled(DateFrom) Or ValueIsFilled(DateTo)) Then
				vParamPresentation = vParamPresentation + NStr("ru = 'Отбор брони созданной на '; en = 'Reservation date on '; de = 'Reservierungsdatum '") + 
				                     Format(DateFrom, "DF=dd.MM") + 
				                     ";" + Chars.LF;
			ElsIf ValueIsFilled(DateFrom) Or ValueIsFilled(DateTo) Then
				vParamPresentation = vParamPresentation + NStr("ru = 'Отбор брони созданной '; en = 'Reservation date '; de = 'Reservierungsdatum '") + Format(DateFrom, "DF=dd.MM") + " - " + Format(DateTo, "DF=dd.MM") + 
				                     ";" + Chars.LF;
			EndIf;
		Else
			If ValueIsFilled(DateFrom) And Not ValueIsFilled(DateTo) Then
				vParamPresentation = vParamPresentation + NStr("ru = 'Отбор брони с датой создания группы c '; en = 'Group creation date from '; de = 'Datum der Gruppenerstellung von '") + 
				                     Format(DateFrom, "DF=dd.MM") + 
				                     ";" + Chars.LF;
			ElsIf Not ValueIsFilled(DateFrom) And ValueIsFilled(DateTo) Then
				vParamPresentation = vParamPresentation + NStr("ru = 'Отбор брони с датой создания группы по '; en = 'Group creation date to '; de = 'Datum der Gruppenerstellung zu '") + 
				                     Format(DateTo, "DF=dd.MM") + 
				                     ";" + Chars.LF;
			ElsIf DateFrom = DateTo And (ValueIsFilled(DateFrom) Or ValueIsFilled(DateTo)) Then
				vParamPresentation = vParamPresentation + NStr("ru = 'Отбор брони с датой создания группы на '; en = 'Group creation date on '; de = 'Datum der Gruppenerstellung '") + 
				                     Format(DateFrom, "DF=dd.MM") + 
				                     ";" + Chars.LF;
			ElsIf ValueIsFilled(DateFrom) Or ValueIsFilled(DateTo) Then
				vParamPresentation = vParamPresentation + NStr("ru = 'Отбор брони с датой создания группы '; en = 'Group creation date '; de = 'Datum der Gruppenerstellung '") + Format(DateFrom, "DF=dd.MM") + " - " + Format(DateTo, "DF=dd.MM") + 
				                     ";" + Chars.LF;
			EndIf;
		EndIf;
	Else
		If Not ByGroupCreationDate Then
			If ValueIsFilled(DateFrom) And Not ValueIsFilled(DateTo) Then
				vParamPresentation = vParamPresentation + NStr("ru = 'Отбор брони созданной c '; en = 'Reservation date from '; de = 'Reservierungsdatum von '") + 
				                     Format(DateFrom, "DF='dd.MM.yyyy HH:mm'") + 
				                     ";" + Chars.LF;
			ElsIf Not ValueIsFilled(DateFrom) And ValueIsFilled(DateTo) Then
				vParamPresentation = vParamPresentation + NStr("ru = 'Отбор брони созданной по '; en = 'Reservation date to '; de = 'Reservierungsdatum zu '") + 
				                     Format(DateTo, "DF='dd.MM.yyyy HH:mm'") + 
				                     ";" + Chars.LF;
			ElsIf DateFrom = DateTo And (ValueIsFilled(DateFrom) Or ValueIsFilled(DateTo)) Then
				vParamPresentation = vParamPresentation + NStr("ru = 'Отбор брони созданной на '; en = 'Reservation date on '; de = 'Reservierungsdatum '") + 
				                     Format(DateFrom, "DF='dd.MM.yyyy HH:mm'") + 
				                     ";" + Chars.LF;
			ElsIf DateFrom < DateTo And (ValueIsFilled(DateFrom) Or ValueIsFilled(DateTo)) Then
				vParamPresentation = vParamPresentation + NStr("ru = 'Отбор брони созданной '; en = 'Reservation date '; de = 'Reservierungsdatum '") + PeriodPresentation(DateFrom, DateTo, cmLocalizationCode()) + 
				                     ";" + Chars.LF;
			ElsIf ValueIsFilled(DateFrom) Or ValueIsFilled(DateTo) Then
				vParamPresentation = vParamPresentation + NStr("en='Reservation period is wrong!';ru='Неправильно задан период создания брони!';de='Zeitraum der Buchungserstellung ist falsch angegeben!'") + 
				                     ";" + Chars.LF;
			EndIf;
		Else
			If ValueIsFilled(DateFrom) And Not ValueIsFilled(DateTo) Then
				vParamPresentation = vParamPresentation + NStr("ru = 'Отбор брони с датой создания группы c '; en = 'Group creation date from '; de = 'Datum der Gruppenerstellung von '") + 
				                     Format(DateFrom, "DF=dd.MM.yyyy") + 
				                     ";" + Chars.LF;
			ElsIf Not ValueIsFilled(DateFrom) And ValueIsFilled(DateTo) Then
				vParamPresentation = vParamPresentation + NStr("ru = 'Отбор брони с датой создания группы по '; en = 'Group creation date to '; de = 'Datum der Gruppenerstellung zu '") + 
				                     Format(DateTo, "DF=dd.MM.yyyy") + 
				                     ";" + Chars.LF;
			ElsIf BegOfDay(DateFrom) = BegOfDay(DateTo) And ValueIsFilled(DateFrom) And ValueIsFilled(DateTo) Then
				vParamPresentation = vParamPresentation + NStr("ru = 'Отбор брони с датой создания группы на '; en = 'Group creation date on '; de = 'Datum der Gruppenerstellung '") + 
				                     Format(DateFrom, "DF=dd.MM.yyyy") + 
				                     ";" + Chars.LF;
			ElsIf DateFrom < DateTo And (ValueIsFilled(DateFrom) Or ValueIsFilled(DateTo)) Then
				vParamPresentation = vParamPresentation + NStr("ru = 'Отбор брони с датой создания группы '; en = 'Group creation date '; de = 'Datum der Gruppenerstellung '") + Format(DateFrom, "DF=dd.MM.yyyy") + " - " + Format(DateTo, "DF=dd.MM.yyyy") + 
				                     ";" + Chars.LF;
			ElsIf ValueIsFilled(DateFrom) Or ValueIsFilled(DateTo) Then
				vParamPresentation = vParamPresentation + NStr("en='Reservation period is wrong!';ru='Неправильно задан период создания брони!';de='Zeitraum der Buchungserstellung ist falsch angegeben!'") + 
				                     ";" + Chars.LF;
			EndIf;
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
	If Rooms2IgnoreList.Count() > 0 Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Исключая номера '; en = 'Ignoring rooms '; de = 'Ohne Zimmeren '") + 
		                     TrimAll(Rooms2IgnoreList) + 
		                     ";" + Chars.LF;
	EndIf;
	If TakeAllotmentsIntoAccount Then
		vParamPresentation = vParamPresentation + NStr("en='Taking allotments into account';ru='С учетом <жестких> блоков';de='Unter Berücksichtigung <fester> Blöcke'") + 
		                     ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(Hotel) Then
		If Not Hotel.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Hotel ';ru='Гостиница ';de='Hotel '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Hotels folder ';ru='Группа гостиниц ';de='Hotelsgruppe '") + 
			                     TrimAll(Hotel.Description) + 
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
	ReportBuilder.Parameters.Insert("qBegOfPeriodFrom", BegOfDay(PeriodFrom));
	ReportBuilder.Parameters.Insert("qBegOfPeriodTo", BegOfDay(PeriodTo));
	ReportBuilder.Parameters.Insert("qPriceCalculationDate", CurrentSessionDate());
	vForecastStartDate = tcOnServer.GetForecastStartDate(Hotel);
	ReportBuilder.Parameters.Insert("qUseForecast", ?(ValueIsFilled(PeriodTo), ?(PeriodTo > EndOfDay(vForecastStartDate-24*3600), True, False), True));
	ReportBuilder.Parameters.Insert("qForecastPeriodFrom", Max(BegOfDay(PeriodFrom), vForecastStartDate));
	ReportBuilder.Parameters.Insert("qForecastPeriodTo", ?(ValueIsFilled(PeriodTo), Max(PeriodTo, EndOfDay(vForecastStartDate-24*3600)), '00010101'));
	ReportBuilder.Parameters.Insert("qDateToIsEmpty", Not ValueIsFilled(DateTo));
	vShiftFrom = 2;
	If ReservationPeriodIsWithoutYear Then
		vDateFrom = Date(2, Month(DateFrom), Day(DateFrom));
		vDateTo = Date(2, Month(DateTo), Day(DateTo));
		If vDateTo < vDateFrom Then
			vDateFrom = Date(1, Month(DateFrom), Day(DateFrom));
			vShiftFrom = 1;
		EndIf;
		ReportBuilder.Parameters.Insert("qDateFrom", vDateFrom);
		ReportBuilder.Parameters.Insert("qDateTo", Date(2, Month(vDateTo), Day(vDateTo), 23, 59, 59));
	Else
		If ByGroupCreationDate Then
			ReportBuilder.Parameters.Insert("qDateFrom", BegOfDay(DateFrom));
			If ValueIsFilled(DateTo) Then
				ReportBuilder.Parameters.Insert("qDateTo", EndOfDay(DateTo));
			Else
				ReportBuilder.Parameters.Insert("qDateTo", DateTo);
			EndIf;
		Else
			ReportBuilder.Parameters.Insert("qDateFrom", DateFrom);
			ReportBuilder.Parameters.Insert("qDateTo", DateTo);
		EndIf;
	EndIf;
	ReportBuilder.Parameters.Insert("qShiftFrom", vShiftFrom);
	ReportBuilder.Parameters.Insert("qFilterByReservationCreationDate", ?(ValueIsFilled(DateFrom), True, ?(ValueIsFilled(DateTo), True, False)));
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qIsEmptyRoom", Not ValueIsFilled(Room));
	ReportBuilder.Parameters.Insert("qRooms2IgnoreList", Rooms2IgnoreList);
	ReportBuilder.Parameters.Insert("qRooms2IgnoreListIsEmpty", ?(Rooms2IgnoreList.Count() = 0, True, False));
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
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
	ReportBuilder.Parameters.Insert("qCalendar", Calendar);
	ReportBuilder.Parameters.Insert("qUseServicesList", vUseServicesList);
	ReportBuilder.Parameters.Insert("qServicesList", vServicesList);
	ReportBuilder.Parameters.Insert("qMonday", NStr("en='1. Monday';ru='1. Понедельник';de='1. Montag'"));
	ReportBuilder.Parameters.Insert("qTuesday", NStr("en='2. Tuesday';ru='2. Вторник';de='2. Dienstag'"));
	ReportBuilder.Parameters.Insert("qWednesday", NStr("en='3. Wednesday';ru='3. Среда';de='3 Mittwoch'"));
	ReportBuilder.Parameters.Insert("qThursday", NStr("en='4. Thursday';ru='4. Четверг';de='4. Donnerstag'"));
	ReportBuilder.Parameters.Insert("qFriday", NStr("en='5. Friday';ru='5. Пятница';de='5. Freitag'"));
	ReportBuilder.Parameters.Insert("qSaturday", NStr("en='6. Saturday';ru='6. Суббота';de='6. Sonnabend'"));
	ReportBuilder.Parameters.Insert("qSunday", NStr("en='7. Sunday';ru='7. Воскресенье';de='7. Sonntag'"));

	ReportBuilder.Parameters.Insert("qTodaysDay", DayOfYear(CurrentSessionDate()) - 1);
	ReportBuilder.Parameters.Insert("qLimitByTodaysDate", LimitPreviousYearDataByTodaysDateInThePast);
	ReportBuilder.Parameters.Insert("qNoYear", ReservationPeriodIsWithoutYear);
	
	ReportBuilder.Parameters.Insert("qHideCorrections", HideCorrections);
	
	vUsePerDayStats = False;
	vUsePerMonthStats = False;
	vUsePerPeriodStats = False;
	vUsePerRoomTypeStats = False;
	vUseCalendarStats = False;
	vUseChoosenCalendarStats = False;
	For Each vReportField In ReportBuilder.SelectedFields Do
		If Find(vReportField.Name, "AccountingDate") > 0 Then
			vUsePerDayStats = True;
		EndIf;			
		If Find(vReportField.Name, "PerDay") > 0 Then
			vUsePerDayStats = True;
		EndIf;			
		If Find(vReportField.Name, "AccountingMonth") > 0 Then
			vUsePerMonthStats = True;
		EndIf;
		If Find(vReportField.Name, "PerMonth") > 0 Then
			vUsePerMonthStats = True;
		EndIf;
		If Find(vReportField.Name, "PerPeriod") > 0 Then
			vUsePerPeriodStats = True;
		EndIf;
		If Find(vReportField.Name, "PerRoomType") > 0 Then
			vUsePerRoomTypeStats = True;
		EndIf;
		If Find(vReportField.Name, "AndCalendarDayType") > 0 Then
			vUseCalendarStats = True;
		EndIf;
		If Find(vReportField.Name, "AndChoosenCalendarDayType") > 0 Then
			vUseChoosenCalendarStats = True;
		EndIf;
	EndDo;
	ReportBuilder.Parameters.Insert("qUsePerDayStats", vUsePerDayStats);
	ReportBuilder.Parameters.Insert("qUsePerMonthStats", vUsePerMonthStats);
	ReportBuilder.Parameters.Insert("qUsePerPeriodStats", vUsePerPeriodStats);
	ReportBuilder.Parameters.Insert("qUsePerRoomTypeStats", vUsePerRoomTypeStats);
	ReportBuilder.Parameters.Insert("qUseCalendarStats", vUseCalendarStats);
	ReportBuilder.Parameters.Insert("qUseChoosenCalendarStats", vUseChoosenCalendarStats);
	ReportBuilder.Parameters.Insert("qWithAllotments", TakeAllotmentsIntoAccount);
	ReportBuilder.Parameters.Insert("qEmptyPriceTag", Catalogs.PriceTags.EmptyRef());
	ReportBuilder.Parameters.Insert("qBedAccommodationType", cmGetAccommodationTypeBed(Hotel));
	ReportBuilder.Parameters.Insert("qEmptyClientType", Catalogs.ClientTypes.EmptyRef());
	ReportBuilder.Parameters.Insert("qReportingCurrency", ?(ValueIsFilled(Hotel), Hotel.ReportingCurrency, Catalogs.Currencies.FindByCode(643)));
	ReportBuilder.Parameters.Insert("qEmptyDate", '00010101');
	ReportBuilder.Parameters.Insert("qByGroupCreationDate", ByGroupCreationDate);
	ReportBuilder.Parameters.Insert("qCustomAttribute1", CustomAttribute1);
	ReportBuilder.Parameters.Insert("qCustomAttribute2", CustomAttribute2);
	ReportBuilder.Parameters.Insert("qCustomAttribute3", CustomAttribute3);
	
	// Check report dimensions being used in current report settings
	vReportDimensionsUsage = New ValueTable();
	vReportDimensionsUsage.Columns.Add("Name");
	vReportDimensionsUsage.Columns.Add("IsUsed", cmGetBooleanTypeDescription());
	For Each vDim In Metadata.AccumulationRegisters.Sales.Dimensions Do
		vReportDimensionsUsageRow = vReportDimensionsUsage.Add();
		vReportDimensionsUsageRow.Name = vDim.Name;
		vReportDimensionsUsageRow.IsUsed = False;
		If vDim.Name = "Hotel" Or 
		   vDim.Name = "Room" Or 
		   vDim.Name = "RoomType" Or 
		   vDim.Name = "Service" Or
		   vDim.Name = "ParentDoc" Or
		   vDim.Name = "GuestGroup" Or 
		   vDim.Name = "AccountingDate" Then
			vReportDimensionsUsageRow.IsUsed = True;
		EndIf;
	EndDo;
	vSelectedFields = cmGetReportUsedFields(ReportBuilder);
	For Each vReportDimensionsUsageRow In vReportDimensionsUsage Do
		For Each vReportField In vSelectedFields Do
			If vReportField.DataPath = vReportDimensionsUsageRow.Name Or 
			   Left(vReportField.DataPath, StrLen(vReportDimensionsUsageRow.Name)) = vReportDimensionsUsageRow.Name Then
				vReportDimensionsUsageRow.IsUsed = True;
			EndIf;
		EndDo;
	EndDo;
	vRBSettings = ReportBuilder.GetSettings(True, True, True, True, True);
	vQryText = ReportBuilder.Text;
	For Each vReportDimensionsUsageRow In vReportDimensionsUsage Do
		If Not vReportDimensionsUsageRow.IsUsed Then
			vQryText = StrReplace(vQryText, "RoomSalesTotals." + vReportDimensionsUsageRow.Name + " AS ", "NULL AS ");
			vQryText = StrReplace(vQryText, "RoomSalesTotals.ParentDoc." + vReportDimensionsUsageRow.Name + " AS ", "NULL AS ");
			vQryText = StrReplace(vQryText, "RoomSalesForecastTotals." + vReportDimensionsUsageRow.Name + ",", "NULL,");
			vQryText = StrReplace(vQryText, "RoomSalesForecastTotals.ParentDoc." + vReportDimensionsUsageRow.Name + ",", "NULL,");
			vQryText = StrReplace(vQryText, "RoomTypesListPerDay." + vReportDimensionsUsageRow.Name + ",", "NULL,");
			vQryText = StrReplace(vQryText, "RoomTypesListPerDay.Hotel." + vReportDimensionsUsageRow.Name + ",", "NULL,");
			vQryText = StrReplace(vQryText, "RoomQuotaSales." + vReportDimensionsUsageRow.Name + ",", "NULL,");
			vQryText = StrReplace(vQryText, "RoomQuotaSales.Hotel." + vReportDimensionsUsageRow.Name + ",", "NULL,");
			vQryText = StrReplace(vQryText, "RoomQuotaSales.RoomQuota." + vReportDimensionsUsageRow.Name + ",", "NULL,");
			vQryText = StrReplace(vQryText, "RoomQuotaSales.RoomQuota.Customer." + vReportDimensionsUsageRow.Name + ",", "NULL,");
			vQryText = StrReplace(vQryText, "RoomQuotaSales.RoomQuota.Agent." + vReportDimensionsUsageRow.Name + ",", "NULL,");
			vQryText = StrReplace(vQryText, "RoomQuotaSales.Allotment" + vReportDimensionsUsageRow.Name + ",", "NULL,");
			vQryText = StrReplace(vQryText, "RoomQuotaSales.RoomQuota.RoomRate." + vReportDimensionsUsageRow.Name + ",", "NULL,");
			If vReportDimensionsUsageRow.Name = "PaymentMethod" Then
				vQryText = StrReplace(vQryText, "RoomQuotaSales.RoomQuota.Customer.PlannedPaymentMethod", "NULL");
			EndIf;
		EndIf;
	EndDo;
	vQryText = StrReplace(vQryText, "ISNULL(NULL, NULL)", "NULL");
	vQryText = StrReplace(vQryText, "ISNULL(NULL, &qEmptyDate)", "&qEmptyDate");
	vQryText = StrReplace(vQryText, "ISNULL(NULL, FALSE)", "FALSE");
	vQryText = StrReplace(vQryText, "YEAR(NULL)", "NULL");
	vQryText = StrReplace(vQryText, "WEEK(NULL)", "NULL");
	ReportBuilder.Text = vQryText;
	ReportBuilder.FillSettings();
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	cmFillReportAttributesPresentations(ThisObject);
	ReportBuilder.Template = Undefined;
	
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
	
	// Restore report default query text
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	cmFillReportAttributesPresentations(ThisObject);
	ReportBuilder.Template = Undefined;
EndProcedure // pmGenerate

// -----------------------------------------------------------------------------
Procedure pmInitializeReportBuilder() Export
	ReportBuilder = New ReportBuilder();
	
	// Initialize default query text
	QueryText = 
	"SELECT
	|	AllDaysPerHotel.Hotel AS Hotel,
	|	BEGINOFPERIOD(AllDaysPerHotel.Period, DAY) AS Period,
	|	AllDaysPerHotel.CounterClosingBalance AS CounterClosingBalance
	|INTO AllDaysPerHotel
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qPeriodFrom, &qPeriodTo, Day, RegisterRecordsAndPeriodBoundaries, Hotel IN HIERARCHY (&qHotel)) AS AllDaysPerHotel
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllSourcesOfBusiness.Ref AS SourceOfBusiness
	|INTO AllSourcesOfBusiness
	|FROM
	|	Catalog.SourcesOfBusiness AS AllSourcesOfBusiness
	|WHERE
	|	NOT AllSourcesOfBusiness.IsFolder
	|	AND NOT AllSourcesOfBusiness.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllMarketingCodes.Ref AS MarketingCode
	|INTO AllMarketingCodes
	|FROM
	|	Catalog.MarketingCodes AS AllMarketingCodes
	|WHERE
	|	(AllMarketingCodes.Hotel IN HIERARCHY (&qHotel)
	|			OR AllMarketingCodes.Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|	AND NOT AllMarketingCodes.IsFolder
	|	AND NOT AllMarketingCodes.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllDaysPerHotel.Hotel AS Hotel,
	|	AllDaysPerHotel.Period AS Period,
	|	AllSourcesOfBusiness.SourceOfBusiness AS SourceOfBusiness
	|INTO SourcesOfBusinessPerDayPerHotel
	|FROM
	|	AllDaysPerHotel AS AllDaysPerHotel
	|		LEFT JOIN AllSourcesOfBusiness AS AllSourcesOfBusiness
	|		ON (TRUE)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllDaysPerHotel.Hotel AS Hotel,
	|	AllDaysPerHotel.Period AS Period,
	|	AllMarketingCodes.MarketingCode AS MarketingCode
	|INTO MarketingCodesPerDayPerHotel
	|FROM
	|	AllDaysPerHotel AS AllDaysPerHotel
	|		LEFT JOIN AllMarketingCodes AS AllMarketingCodes
	|		ON (TRUE)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllotmentRoomRates.Hotel AS Hotel,
	|	AllotmentRoomRates.RoomQuota.RoomRate AS RoomRate,
	|	AllotmentRoomRates.RoomQuota.RoomRate.Calendar AS Calendar,
	|	CASE
	|		WHEN AllotmentRoomRates.RoomQuota.RoomRate.BasedOnRoomRate <> VALUE(Catalog.RoomRates.EmptyRef)
	|				AND NOT AllotmentRoomRates.RoomQuota.RoomRate.BasedOnRoomRate IS NULL
	|			THEN AllotmentRoomRates.RoomQuota.RoomRate.BasedOnRoomRate
	|		ELSE AllotmentRoomRates.RoomQuota.RoomRate
	|	END AS PricesRoomRate,
	|	SUM(AllotmentRoomRates.CounterClosingBalance) AS Counter
	|INTO AllotmentRates
	|FROM
	|	AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			PERIOD,
	|			RegisterRecordsAndPeriodBoundaries,
	|			&qWithAllotments
	|				AND Hotel IN HIERARCHY (&qHotel)
	|				AND (Room IN HIERARCHY (&qRoom)
	|					OR &qIsEmptyRoom)
	|				AND (RoomType IN HIERARCHY (&qRoomType)
	|					OR &qIsEmptyRoomType)
	|				AND RoomQuota.IsCommitment
	|				AND RoomQuota.DoWriteOff) AS AllotmentRoomRates
	|WHERE
	|	NOT AllotmentRoomRates.RoomQuota.RoomRate IS NULL
	|	AND AllotmentRoomRates.RoomQuota.RoomRate <> VALUE(Catalog.RoomRates.EmptyRef)
	|	AND NOT AllotmentRoomRates.RoomQuota.RoomRate.DeletionMark
	|	AND NOT AllotmentRoomRates.RoomQuota.RoomRate.IsFolder
	|
	|GROUP BY
	|	AllotmentRoomRates.Hotel,
	|	AllotmentRoomRates.RoomQuota.RoomRate,
	|	AllotmentRoomRates.RoomQuota.RoomRate.Calendar,
	|	CASE
	|		WHEN AllotmentRoomRates.RoomQuota.RoomRate.BasedOnRoomRate <> VALUE(Catalog.RoomRates.EmptyRef)
	|				AND NOT AllotmentRoomRates.RoomQuota.RoomRate.BasedOnRoomRate IS NULL
	|			THEN AllotmentRoomRates.RoomQuota.RoomRate.BasedOnRoomRate
	|		ELSE AllotmentRoomRates.RoomQuota.RoomRate
	|	END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	AllotmentRates.RoomRate AS RoomRate,
	|	AllotmentRates.RoomRate.AccommodationService AS Service,
	|	AllotmentRates.RoomRate.AccommodationService.QuantityCalculationRule AS QuantityCalculationRule,
	|	AllotmentRates.RoomRate.AccommodationService.QuantityCalculationRule.QuantityCalculationRuleType AS QuantityCalculationRuleType,
	|	AllotmentRates.RoomRate.AccommodationService.IsRoomRevenue AS IsRoomRevenue,
	|	AllotmentRates.RoomRate.AccommodationService.IsInPrice AS IsInPrice,
	|	AllotmentRates.RoomRate.AccommodationService.ChargePerPerson AS ChargePerPerson,
	|	AllotmentRates.RoomRate.AccommodationService.ChargeToEachGuestSeparately AS ChargeToEachGuestSeparately,
	|	AllotmentRates.RoomRate.AccommodationService.Unit AS Unit,
	|	AllotmentRates.RoomRate.AccommodationService.RoomRevenueAmountsOnly AS RoomRevenueAmountsOnly
	|INTO AllotmentRateServices
	|FROM
	|	AllotmentRates AS AllotmentRates
	|WHERE
	|	AllotmentRates.RoomRate.AccommodationService <> VALUE(Catalog.Services.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DaysByRoomTypes.Calendar AS Calendar,
	|	DaysByRoomTypes.AccountingDate AS AccountingDate,
	|	DaysByRoomTypes.RoomType AS RoomType,
	|	DaysByRoomTypes.CalendarDayType AS CalendarDayType,
	|	DaysByRoomTypes.PriceTag AS PriceTag,
	|	DaysByRoomTypes.RoomPrice AS RoomPrice,
	|	DaysByRoomTypes.RoomPriceCurrency AS RoomPriceCurrency
	|INTO CalendarDays
	|FROM
	|	(SELECT
	|		CalendarDays.Calendar AS Calendar,
	|		RoomTypes.Ref AS RoomType,
	|		CalendarDays.AccountingDate AS AccountingDate,
	|		CASE
	|			WHEN CalendarDaysByRoomTypes.CalendarDayType IS NULL
	|				THEN CalendarDays.CalendarDayType
	|			WHEN CalendarDaysByRoomTypes.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef)
	|				THEN CalendarDays.CalendarDayType
	|			ELSE CalendarDaysByRoomTypes.CalendarDayType
	|		END AS CalendarDayType,
	|		CASE
	|			WHEN CalendarDaysByRoomTypes.PriceTag IS NULL
	|				THEN CalendarDays.PriceTag
	|			WHEN CalendarDaysByRoomTypes.PriceTag = VALUE(Catalog.PriceTags.EmptyRef)
	|				THEN CalendarDays.PriceTag
	|			ELSE CalendarDaysByRoomTypes.PriceTag
	|		END AS PriceTag,
	|		CASE
	|			WHEN CalendarDaysByRoomTypes.RoomPrice IS NULL
	|				THEN CalendarDays.RoomPrice
	|			WHEN CalendarDaysByRoomTypes.RoomPrice = 0
	|				THEN CalendarDays.RoomPrice
	|			ELSE CalendarDaysByRoomTypes.RoomPrice
	|		END AS RoomPrice,
	|		CASE
	|			WHEN CalendarDaysByRoomTypes.RoomPriceCurrency IS NULL
	|				THEN CalendarDays.RoomPriceCurrency
	|			WHEN CalendarDaysByRoomTypes.RoomPriceCurrency = VALUE(Catalog.Currencies.EmptyRef)
	|				THEN CalendarDays.RoomPriceCurrency
	|			ELSE CalendarDaysByRoomTypes.RoomPriceCurrency
	|		END AS RoomPriceCurrency
	|	FROM
	|		InformationRegister.CalendarDays.SliceLast(
	|				&qPriceCalculationDate,
	|				AccountingDate BETWEEN &qBegOfPeriodFrom AND &qBegOfPeriodTo
	|					AND Calendar IN
	|						(SELECT
	|							AllotmentRates.Calendar
	|						FROM
	|							AllotmentRates AS AllotmentRates)) AS CalendarDays
	|			LEFT JOIN Catalog.RoomTypes AS RoomTypes
	|			ON (RoomTypes.Owner = &qHotel)
	|				AND (NOT RoomTypes.IsFolder)
	|				AND (NOT RoomTypes.DeletionMark)
	|			LEFT JOIN InformationRegister.CalendarDaysByRoomTypes.SliceLast(
	|					&qPriceCalculationDate,
	|					AccountingDate BETWEEN &qBegOfPeriodFrom AND &qBegOfPeriodTo
	|						AND Calendar IN
	|							(SELECT
	|								AllotmentRates.Calendar
	|							FROM
	|								AllotmentRates AS AllotmentRates)) AS CalendarDaysByRoomTypes
	|			ON CalendarDays.AccountingDate = CalendarDaysByRoomTypes.AccountingDate
	|				AND (RoomTypes.Ref = CalendarDaysByRoomTypes.RoomType)) AS DaysByRoomTypes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomRatesSliceLast.SetRoomRateFormulas AS Recorder,
	|	RoomRatesSliceLast.RoomRate AS RoomRate
	|INTO ActiveSetRoomRateFormulas
	|FROM
	|	InformationRegister.RoomRates.SliceLast(
	|			&qPriceCalculationDate,
	|			Hotel IN HIERARCHY (&qHotel)
	|				AND RoomRate IN
	|					(SELECT
	|						AllotmentRates.RoomRate
	|					FROM
	|						AllotmentRates AS AllotmentRates)
	|				AND IsFormula) AS RoomRatesSliceLast
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomRatesSliceLast.SetRoomRatePrices AS Recorder,
	|	RoomRatesSliceLast.RoomRate AS RoomRate,
	|	RoomRatesSliceLast.CalendarDayType AS CalendarDayType,
	|	RoomRatesSliceLast.PriceTag AS PriceTag
	|INTO ActiveSetRoomRatePrices
	|FROM
	|	InformationRegister.RoomRates.SliceLast(
	|			&qPriceCalculationDate,
	|			RoomRate IN
	|					(SELECT
	|						AllotmentRates.PricesRoomRate
	|					FROM
	|						AllotmentRates AS AllotmentRates)
	|				AND Hotel IN HIERARCHY (&qHotel)
	|				AND NOT IsFormula) AS RoomRatesSliceLast
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccommodationTypeFormulas.Ref.RoomRate AS RoomRate,
	|	AccommodationTypeFormulas.Ref.Hotel AS Hotel,
	|	AccommodationTypeFormulas.Ref AS SetRoomRatePrices,
	|	ActiveSetRoomRatePrices.CalendarDayType AS CalendarDayType,
	|	ActiveSetRoomRatePrices.PriceTag AS PriceTag,
	|	AccommodationTypeFormulas.ClientType AS ClientType,
	|	AccommodationTypeFormulas.Service AS Service,
	|	AccommodationTypeFormulas.RoomClass AS RoomClass,
	|	AccommodationTypeFormulas.RoomType AS RoomType,
	|	AccommodationTypeFormulas.AccommodationType AS AccommodationType,
	|	AccommodationTypeFormulas.Multiplier AS Multiplier,
	|	AccommodationTypeFormulas.BracketsConstant AS BracketsConstant,
	|	AccommodationTypeFormulas.Constant AS Constant,
	|	AccommodationTypeFormulas.LineNumber AS LineNumber,
	|	AccommodationTypeFormulas.LineNumber AS SortCode
	|INTO RateAccommodationTypeFormulas
	|FROM
	|	Document.SetRoomRatePrices.Formulas AS AccommodationTypeFormulas
	|		INNER JOIN ActiveSetRoomRatePrices AS ActiveSetRoomRatePrices
	|		ON AccommodationTypeFormulas.Ref = ActiveSetRoomRatePrices.Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	FormulasForPriceTags.Ref.RoomRate AS RoomRate,
	|	FormulasForPriceTags.Ref.Hotel AS Hotel,
	|	FormulasForPriceTags.Ref AS SetRoomRatePrices,
	|	FormulasForPriceTags.CalendarDayType AS CalendarDayType,
	|	FormulasForPriceTags.PriceTag AS PriceTag,
	|	FormulasForPriceTags.ClientType AS ClientType,
	|	FormulasForPriceTags.Service AS Service,
	|	FormulasForPriceTags.RoomClass AS RoomClass,
	|	FormulasForPriceTags.RoomType AS RoomType,
	|	FormulasForPriceTags.AccommodationType AS AccommodationType,
	|	FormulasForPriceTags.Discount AS Discount,
	|	FormulasForPriceTags.Multiplier AS Multiplier,
	|	FormulasForPriceTags.BracketsConstant AS BracketsConstant,
	|	FormulasForPriceTags.Constant AS Constant,
	|	FormulasForPriceTags.LineNumber AS LineNumber,
	|	FormulasForPriceTags.LineNumber AS SortCode
	|INTO FormulasForPriceTags
	|FROM
	|	Document.SetRoomRatePrices.FormulasForDayTypesAndPricetags AS FormulasForPriceTags
	|		INNER JOIN ActiveSetRoomRatePrices AS ActiveSetRoomRatePrices
	|		ON FormulasForPriceTags.Ref = ActiveSetRoomRatePrices.Recorder
	|			AND FormulasForPriceTags.CalendarDayType = ActiveSetRoomRatePrices.CalendarDayType
	|			AND FormulasForPriceTags.PriceTag = ActiveSetRoomRatePrices.PriceTag
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomRateFormulas.RoomRate.BasedOnRoomRate AS BasedOnRoomRate,
	|	RoomRateFormulas.RoomRate.BasedOnPriceTag AS BasedOnPriceTag,
	|	RoomRateFormulas.RoomRate AS RoomRate,
	|	RoomRateFormulas.Hotel AS Hotel,
	|	RoomRateFormulas.IsFormula AS IsFormula,
	|	RoomRateFormulas.Service AS Service,
	|	RoomRateFormulas.RoomType AS RoomType,
	|	RoomRateFormulas.AccommodationType AS AccommodationType,
	|	RoomRateFormulas.ClientType AS ClientType,
	|	RoomRateFormulas.CalendarDayType AS CalendarDayType,
	|	RoomRateFormulas.Recorder AS Recorder,
	|	RoomRateFormulas.Period AS Period,
	|	RoomRateFormulas.BracketsConstant AS BracketsConstant,
	|	RoomRateFormulas.Constant AS Constant,
	|	RoomRateFormulas.Multiplier AS Multiplier,
	|	RoomRateFormulas.ReplaceWithService AS ReplaceWithService
	|INTO RoomRateFormulas
	|FROM
	|	InformationRegister.RoomRateFormulas AS RoomRateFormulas
	|		INNER JOIN ActiveSetRoomRateFormulas AS ActiveSetRoomRateFormulas
	|		ON RoomRateFormulas.RoomRate = ActiveSetRoomRateFormulas.RoomRate
	|			AND RoomRateFormulas.Recorder = ActiveSetRoomRateFormulas.Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RateServices.RoomRate AS RoomRate,
	|	RateServices.Service AS Service,
	|	RateServices.QuantityCalculationRule AS QuantityCalculationRule,
	|	RateServices.QuantityCalculationRuleType AS QuantityCalculationRuleType,
	|	RateServices.IsRoomRevenue AS IsRoomRevenue,
	|	RateServices.IsInPrice AS IsInPrice,
	|	RateServices.ChargePerPerson AS ChargePerPerson,
	|	RateServices.ChargeToEachGuestSeparately AS ChargeToEachGuestSeparately,
	|	RateServices.Unit AS Unit,
	|	RateServices.RoomRevenueAmountsOnly AS RoomRevenueAmountsOnly,
	|	RoomTypePricesByDates.RoomType AS RoomType,
	|	RoomTypePricesByDates.AccountingDate AS AccountingDate,
	|	RoomTypePricesByDates.CalendarDayType AS CalendarDayType,
	|	RoomTypePricesByDates.PriceTag AS PriceTag,
	|	RoomTypePricesByDates.RoomPrice AS Price,
	|	RoomTypePricesByDates.RoomPriceCurrency AS Currency
	|INTO RoomTypePricesByDates
	|FROM
	|	CalendarDays AS RoomTypePricesByDates
	|		LEFT JOIN AllotmentRateServices AS RateServices
	|		ON (RateServices.RoomRate.UsePricesFromCalendar)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RawRoomRatePrices.AccountingDate AS AccountingDate,
	|	RateAccommodationTypeFormulas.RoomRate AS RoomRate,
	|	CASE
	|		WHEN RawRoomRatePrices.CalendarDayType <> VALUE(Catalog.CalendarDayTypes.EmptyRef)
	|			THEN RawRoomRatePrices.CalendarDayType
	|		ELSE RateAccommodationTypeFormulas.CalendarDayType
	|	END AS CalendarDayType,
	|	CASE
	|		WHEN RawRoomRatePrices.PriceTag <> VALUE(Catalog.PriceTags.EmptyRef)
	|			THEN RawRoomRatePrices.PriceTag
	|		ELSE RateAccommodationTypeFormulas.PriceTag
	|	END AS PriceTag,
	|	RateAccommodationTypeFormulas.ClientType AS ClientType,
	|	RawRoomRatePrices.RoomType AS RoomType,
	|	RateAccommodationTypeFormulas.AccommodationType AS AccommodationType,
	|	RateAccommodationTypeFormulas.SetRoomRatePrices AS SetRoomRatePrices,
	|	RateAccommodationTypeFormulas.SortCode AS SortCode,
	|	RateAccommodationTypeFormulas.LineNumber AS LineNumber,
	|	RateAccommodationTypeFormulas.Hotel AS Hotel,
	|	RawRoomRatePrices.Service AS Service,
	|	(RawRoomRatePrices.Price + ISNULL(RateAccommodationTypeFormulas.BracketsConstant, 0)) * ISNULL(RateAccommodationTypeFormulas.Multiplier, 0) + ISNULL(RateAccommodationTypeFormulas.Constant, 0) AS Price,
	|	RawRoomRatePrices.Currency AS Currency,
	|	0 AS MinimumQuantity,
	|	ISNULL(ServicePrices.VATRate, RateAccommodationTypeFormulas.Hotel.Company.VATRate) AS VATRate,
	|	RawRoomRatePrices.QuantityCalculationRule AS QuantityCalculationRule,
	|	RawRoomRatePrices.QuantityCalculationRuleType AS QuantityCalculationRuleType,
	|	RawRoomRatePrices.IsRoomRevenue AS IsRoomRevenue,
	|	RawRoomRatePrices.IsInPrice AS IsInPrice,
	|	RawRoomRatePrices.ChargePerPerson AS ChargePerPerson,
	|	RawRoomRatePrices.ChargeToEachGuestSeparately AS ChargeToEachGuestSeparately,
	|	RawRoomRatePrices.Unit AS Unit,
	|	RawRoomRatePrices.RoomRevenueAmountsOnly AS RoomRevenueAmountsOnly
	|INTO RawRoomRatePrices
	|FROM
	|	RoomTypePricesByDates AS RawRoomRatePrices
	|		LEFT JOIN RateAccommodationTypeFormulas AS RateAccommodationTypeFormulas
	|		ON (RawRoomRatePrices.Service = RateAccommodationTypeFormulas.Service
	|				OR RateAccommodationTypeFormulas.Service = VALUE(Catalog.Services.EmptyRef))
	|			AND (RawRoomRatePrices.RoomType = RateAccommodationTypeFormulas.RoomType
	|					AND RateAccommodationTypeFormulas.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
	|				OR RawRoomRatePrices.RoomType.RoomClass = RateAccommodationTypeFormulas.RoomClass
	|					AND RateAccommodationTypeFormulas.RoomClass <> VALUE(Catalog.RoomTypeClasses.EmptyRef)
	|				OR RateAccommodationTypeFormulas.RoomType = VALUE(Catalog.RoomTypes.EmptyRef)
	|					AND RateAccommodationTypeFormulas.RoomClass = VALUE(Catalog.RoomTypeClasses.EmptyRef))
	|		LEFT JOIN InformationRegister.ServicePrices.SliceLast(
	|				&qPriceCalculationDate,
	|				Service IN
	|						(SELECT
	|							AllotmentRateServices.Service
	|						FROM
	|							AllotmentRateServices AS AllotmentRateServices)
	|					AND Hotel IN HIERARCHY (&qHotel)) AS ServicePrices
	|		ON RawRoomRatePrices.Service = ServicePrices.Service
	|			AND (RateAccommodationTypeFormulas.ClientType = ServicePrices.ClientType)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomRatePrices.AccountingDate AS AccountingDate,
	|	RoomRatePrices.RoomRate AS RoomRate,
	|	RoomRatePrices.CalendarDayType AS CalendarDayType,
	|	RoomRatePrices.PriceTag AS PriceTag,
	|	RoomRatePrices.ClientType AS ClientType,
	|	RoomRatePrices.RoomType AS RoomType,
	|	RoomRatePrices.AccommodationType AS AccommodationType,
	|	RoomRatePrices.SetRoomRatePrices AS SetRoomRatePrices,
	|	RoomRatePrices.SortCode AS SortCode,
	|	RoomRatePrices.LineNumber AS LineNumber,
	|	RoomRatePrices.Hotel AS Hotel,
	|	RoomRatePrices.Service AS Service,
	|	CASE
	|		WHEN ISNULL(FormulasForPriceTags.Discount, 0) <> 0
	|			THEN RoomRatePrices.Price - RoomRatePrices.Price * ISNULL(FormulasForPriceTags.Discount, 0) / 100
	|		ELSE (RoomRatePrices.Price + ISNULL(FormulasForPriceTags.BracketsConstant, 0)) * ISNULL(FormulasForPriceTags.Multiplier, 1) + ISNULL(FormulasForPriceTags.Constant, 0)
	|	END AS Price,
	|	RoomRatePrices.Currency AS Currency,
	|	RoomRatePrices.MinimumQuantity AS MinimumQuantity,
	|	RoomRatePrices.VATRate AS VATRate,
	|	RoomRatePrices.QuantityCalculationRule AS QuantityCalculationRule,
	|	RoomRatePrices.QuantityCalculationRuleType AS QuantityCalculationRuleType,
	|	RoomRatePrices.IsRoomRevenue AS IsRoomRevenue,
	|	RoomRatePrices.IsInPrice AS IsInPrice,
	|	RoomRatePrices.ChargePerPerson AS IsPricePerPerson,
	|	RoomRatePrices.ChargeToEachGuestSeparately AS ChargeToEachGuestSeparately,
	|	RoomRatePrices.Unit AS Unit,
	|	RoomRatePrices.RoomRevenueAmountsOnly AS RoomRevenueAmountsOnly
	|INTO RoomRatePricesByCalendar
	|FROM
	|	RawRoomRatePrices AS RoomRatePrices
	|		LEFT JOIN FormulasForPriceTags AS FormulasForPriceTags
	|		ON (RoomRatePrices.Service = FormulasForPriceTags.Service
	|					AND FormulasForPriceTags.Service <> VALUE(Catalog.Services.EmptyRef)
	|				OR FormulasForPriceTags.Service = VALUE(Catalog.Services.EmptyRef))
	|			AND RoomRatePrices.ClientType = FormulasForPriceTags.ClientType
	|			AND RoomRatePrices.PriceTag = FormulasForPriceTags.PriceTag
	|			AND RoomRatePrices.CalendarDayType = FormulasForPriceTags.CalendarDayType
	|			AND (RoomRatePrices.AccommodationType = FormulasForPriceTags.AccommodationType
	|					AND FormulasForPriceTags.AccommodationType <> VALUE(Catalog.AccommodationTypes.EmptyRef)
	|				OR FormulasForPriceTags.AccommodationType = VALUE(Catalog.AccommodationTypes.EmptyRef))
	|			AND (RoomRatePrices.RoomType = FormulasForPriceTags.RoomType
	|					AND FormulasForPriceTags.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
	|				OR RoomRatePrices.RoomType.RoomClass = FormulasForPriceTags.RoomClass
	|					AND FormulasForPriceTags.RoomClass <> VALUE(Catalog.RoomTypeClasses.EmptyRef)
	|				OR FormulasForPriceTags.RoomType = VALUE(Catalog.RoomTypes.EmptyRef)
	|					AND FormulasForPriceTags.RoomClass = VALUE(Catalog.RoomTypeClasses.EmptyRef))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CalendarDays.AccountingDate AS AccountingDate,
	|	RoomRatePrices.Hotel AS Hotel,
	|	RoomRatePrices.RoomRate AS RoomRate,
	|	RoomRatePrices.ClientType AS ClientType,
	|	RoomRatePrices.RoomType AS RoomType,
	|	RoomRatePrices.AccommodationType AS AccommodationType,
	|	RoomRatePrices.CalendarDayType AS CalendarDayType,
	|	RoomRatePrices.PriceTag AS PriceTag,
	|	RoomRatePrices.IsPricePerPerson AS IsPricePerPerson,
	|	RoomRatePrices.Service AS Service,
	|	RoomRatePrices.VATRate AS VATRate,
	|	RoomRatePrices.Currency AS Currency,
	|	RoomRatePrices.Price AS Price
	|INTO RoomRatePricesByDocuments
	|FROM
	|	InformationRegister.RoomRatePrices AS RoomRatePrices
	|		INNER JOIN ActiveSetRoomRatePrices AS ActiveSetRoomRatePrices
	|		ON RoomRatePrices.Recorder = ActiveSetRoomRatePrices.Recorder
	|			AND RoomRatePrices.CalendarDayType = ActiveSetRoomRatePrices.CalendarDayType
	|			AND RoomRatePrices.PriceTag = ActiveSetRoomRatePrices.PriceTag
	|		INNER JOIN CalendarDays AS CalendarDays
	|		ON RoomRatePrices.RoomType = CalendarDays.RoomType
	|			AND RoomRatePrices.CalendarDayType = CalendarDays.CalendarDayType
	|WHERE
	|	NOT RoomRatePrices.RoomRate.UsePricesFromCalendar
	|	AND RoomRatePrices.Hotel IN HIERARCHY(&qHotel)
	|	AND RoomRatePrices.RoomRate IN
	|			(SELECT
	|				AllotmentRates.PricesRoomRate
	|			FROM
	|				AllotmentRates AS AllotmentRates)
	|	AND RoomRatePrices.ClientType = &qEmptyClientType
	|	AND RoomRatePrices.IsInPrice
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomRatePrices.AccountingDate AS AccountingDate,
	|	RoomRatePrices.Hotel AS Hotel,
	|	RoomRatePrices.RoomRate AS RoomRate,
	|	RoomRatePrices.ClientType AS ClientType,
	|	RoomRatePrices.RoomType AS RoomType,
	|	RoomRatePrices.AccommodationType AS AccommodationType,
	|	RoomRatePrices.CalendarDayType AS CalendarDayType,
	|	RoomRatePrices.PriceTag AS PriceTag,
	|	RoomRatePrices.IsPricePerPerson AS IsPricePerPerson,
	|	RoomRatePrices.Service AS Service,
	|	RoomRatePrices.VATRate AS VATRate,
	|	RoomRatePrices.Currency AS Currency,
	|	RoomRatePrices.Price AS Price
	|INTO RoomRatePrices
	|FROM
	|	(SELECT
	|		RoomRatePricesByDocuments.AccountingDate AS AccountingDate,
	|		RoomRatePricesByDocuments.Hotel AS Hotel,
	|		RoomRatePricesByDocuments.RoomRate AS RoomRate,
	|		RoomRatePricesByDocuments.ClientType AS ClientType,
	|		RoomRatePricesByDocuments.RoomType AS RoomType,
	|		RoomRatePricesByDocuments.AccommodationType AS AccommodationType,
	|		RoomRatePricesByDocuments.CalendarDayType AS CalendarDayType,
	|		RoomRatePricesByDocuments.PriceTag AS PriceTag,
	|		RoomRatePricesByDocuments.IsPricePerPerson AS IsPricePerPerson,
	|		RoomRatePricesByDocuments.Service AS Service,
	|		RoomRatePricesByDocuments.VATRate AS VATRate,
	|		RoomRatePricesByDocuments.Currency AS Currency,
	|		RoomRatePricesByDocuments.Price AS Price
	|	FROM
	|		RoomRatePricesByDocuments AS RoomRatePricesByDocuments
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RoomRatePricesByCalendar.AccountingDate,
	|		RoomRatePricesByCalendar.Hotel,
	|		RoomRatePricesByCalendar.RoomRate,
	|		RoomRatePricesByCalendar.ClientType,
	|		RoomRatePricesByCalendar.RoomType,
	|		RoomRatePricesByCalendar.AccommodationType,
	|		RoomRatePricesByCalendar.CalendarDayType,
	|		RoomRatePricesByCalendar.PriceTag,
	|		RoomRatePricesByCalendar.IsPricePerPerson,
	|		RoomRatePricesByCalendar.Service,
	|		RoomRatePricesByCalendar.VATRate,
	|		RoomRatePricesByCalendar.Currency,
	|		RoomRatePricesByCalendar.Price
	|	FROM
	|		RoomRatePricesByCalendar AS RoomRatePricesByCalendar) AS RoomRatePrices
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomRatePrices.Hotel AS Hotel,
	|	RoomRatePrices.RoomRate AS RoomRate,
	|	RoomRatePrices.ClientType AS ClientType,
	|	RoomRatePrices.AccountingDate AS AccountingDate,
	|	RoomRatePrices.RoomType AS RoomType,
	|	RoomRatePrices.AccommodationType AS AccommodationType,
	|	RoomRatePrices.CalendarDayType AS CalendarDayType,
	|	RoomRatePrices.PriceTag AS PriceTag,
	|	RoomRatePrices.Currency AS Currency,
	|	RoomRatePrices.Service AS Service,
	|	RoomRatePrices.VATRate AS VATRate,
	|	SUM(CASE
	|			WHEN RoomRatePrices.IsPricePerPerson
	|					AND RoomRatePrices.AccommodationType.NumberOfPersons4Reservation > 1
	|				THEN ((RoomRatePrices.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0)) * RoomRatePrices.AccommodationType.NumberOfPersons4Reservation
	|			WHEN RoomRatePrices.IsPricePerPerson
	|					AND RoomRatePrices.AccommodationType.NumberOfPersons > 1
	|				THEN ((RoomRatePrices.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0)) * RoomRatePrices.AccommodationType.NumberOfPersons
	|			ELSE (RoomRatePrices.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0)
	|		END) AS Price
	|INTO AllotmentRatesPrices
	|FROM
	|	RoomRatePrices AS RoomRatePrices
	|		LEFT JOIN RoomRateFormulas AS RoomRateFormulas
	|		ON RoomRatePrices.RoomRate = RoomRateFormulas.BasedOnRoomRate
	|			AND RoomRatePrices.Hotel = RoomRateFormulas.Hotel
	|			AND (NOT RoomRateFormulas.IsFormula
	|				OR RoomRateFormulas.IsFormula
	|					AND RoomRatePrices.RoomType = RoomRateFormulas.RoomType
	|					AND RoomRatePrices.ClientType = RoomRateFormulas.ClientType
	|					AND RoomRatePrices.AccommodationType = RoomRateFormulas.AccommodationType
	|					AND (RoomRatePrices.CalendarDayType = RoomRateFormulas.CalendarDayType
	|						OR RoomRateFormulas.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef))
	|					AND (RoomRatePrices.Service = RoomRateFormulas.Service
	|						OR RoomRateFormulas.Service = VALUE(Catalog.Services.EmptyRef)))
	|			AND (RoomRateFormulas.BasedOnPriceTag = VALUE(Catalog.PriceTags.EmptyRef)
	|				OR RoomRatePrices.PriceTag = RoomRateFormulas.BasedOnPriceTag
	|					AND RoomRateFormulas.BasedOnPriceTag <> VALUE(Catalog.PriceTags.EmptyRef))
	|
	|GROUP BY
	|	RoomRatePrices.Hotel,
	|	RoomRatePrices.RoomRate,
	|	RoomRatePrices.ClientType,
	|	RoomRatePrices.AccountingDate,
	|	RoomRatePrices.RoomType,
	|	RoomRatePrices.AccommodationType,
	|	RoomRatePrices.CalendarDayType,
	|	RoomRatePrices.PriceTag,
	|	RoomRatePrices.Currency,
	|	RoomRatePrices.Service,
	|	RoomRatePrices.VATRate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomQuotaSales.Hotel AS Hotel,
	|	RoomQuotaSales.Period AS Period,
	|	RoomQuotaSales.RoomQuota AS RoomQuota,
	|	RoomQuotaSales.RoomType AS RoomType,
	|	RoomRatePrices.Service AS Service,
	|	RoomRatePrices.VATRate AS VATRate,
	|	RoomRatePrices.CalendarDayType AS CalendarDayType,
	|	RoomQuotaSales.CounterClosingBalance AS Counter,
	|	RoomQuotaSales.RoomsInQuotaClosingBalance AS RoomsInQuotaClosingBalance,
	|	RoomQuotaSales.BedsInQuotaClosingBalance AS BedsInQuotaClosingBalance,
	|	RoomRatePrices.Price AS AllotmentPrice,
	|	RoomQuotaSales.BedsInQuotaClosingBalance * RoomRatePrices.Price AS AllotmentAmount
	|INTO RoomQuotaSales
	|FROM
	|	AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			RegisterRecordsAndPeriodBoundaries,
	|			&qWithAllotments
	|				AND Hotel IN HIERARCHY (&qHotel)
	|				AND (Room IN HIERARCHY (&qRoom)
	|					OR &qIsEmptyRoom)
	|				AND (RoomType IN HIERARCHY (&qRoomType)
	|					OR &qIsEmptyRoomType)
	|				AND RoomQuota.IsCommitment
	|				AND RoomQuota.DoWriteOff) AS RoomQuotaSales
	|		LEFT JOIN AllotmentRatesPrices AS RoomRatePrices
	|		ON RoomQuotaSales.Hotel = RoomRatePrices.Hotel
	|			AND RoomQuotaSales.RoomQuota.RoomRate = RoomRatePrices.RoomRate
	|			AND RoomQuotaSales.Period = RoomRatePrices.AccountingDate
	|			AND (RoomRatePrices.PriceTag = &qEmptyPriceTag)
	|			AND (RoomRatePrices.ClientType = &qEmptyClientType)
	|			AND RoomQuotaSales.RoomType = RoomRatePrices.RoomType
	|			AND (RoomRatePrices.AccommodationType = &qBedAccommodationType)
	|			AND (RoomRatePrices.Currency = &qReportingCurrency)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomQuotaTotalSales.Hotel AS Hotel,
	|	SUM(RoomQuotaTotalSales.RoomsInQuotaClosingBalance) AS RoomsInQuotaClosingBalance,
	|	SUM(RoomQuotaTotalSales.BedsInQuotaClosingBalance) AS BedsInQuotaClosingBalance,
	|	SUM(RoomQuotaTotalSales.AllotmentAmount) AS AllotmentAmount
	|INTO RoomQuotaTotalSales
	|FROM
	|	RoomQuotaSales AS RoomQuotaTotalSales
	|
	|GROUP BY
	|	RoomQuotaTotalSales.Hotel
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TotalInventoryBalanceAndTurnovers.Hotel AS Hotel,
	|	SUM(TotalInventoryBalanceAndTurnovers.CounterClosingBalance) AS CounterClosingBalance,
	|	SUM(TotalInventoryBalanceAndTurnovers.TotalRoomsClosingBalance) AS TotalRooms,
	|	SUM(TotalInventoryBalanceAndTurnovers.TotalBedsClosingBalance) AS TotalBeds,
	|	-SUM(TotalInventoryBalanceAndTurnovers.RoomsBlockedClosingBalance) AS TotalRoomsBlocked,
	|	-SUM(TotalInventoryBalanceAndTurnovers.BedsBlockedClosingBalance) AS TotalBedsBlocked,
	|	SUM(TotalInventoryBalanceAndTurnovers.GuestsReservedReceipt) AS TotalGuestsReservedReceipt,
	|	SUM(TotalInventoryBalanceAndTurnovers.GuestsReservedExpense) AS TotalGuestsReservedExpense,
	|	SUM(TotalInventoryBalanceAndTurnovers.InHouseGuestsReceipt) AS TotalInHouseGuestsReceipt,
	|	SUM(TotalInventoryBalanceAndTurnovers.InHouseGuestsExpense) AS TotalInHouseGuestsExpense
	|INTO HotelInventoryTotals
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			RegisterRecordsAndPeriodBoundaries,
	|			Hotel IN HIERARCHY (&qHotel)
	|				AND (Room IN HIERARCHY (&qRoom)
	|					OR &qIsEmptyRoom)
	|				AND (NOT Room IN (&qRooms2IgnoreList)
	|					OR &qRooms2IgnoreListIsEmpty)
	|				AND (RoomType IN HIERARCHY (&qRoomType)
	|					OR &qIsEmptyRoomType)) AS TotalInventoryBalanceAndTurnovers
	|
	|GROUP BY
	|	TotalInventoryBalanceAndTurnovers.Hotel
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventoryBlocks.Hotel AS Hotel,
	|	RoomInventoryBlocks.Room AS Room,
	|	SUM(CASE
	|			WHEN &qPeriodFrom < RoomInventoryBlocks.CheckInDate
	|					AND (&qPeriodTo < RoomInventoryBlocks.CheckOutDate
	|						OR RoomInventoryBlocks.CheckOutDate = &qEmptyDate)
	|				THEN DATEDIFF(RoomInventoryBlocks.CheckInDate, &qPeriodTo, DAY)
	|			WHEN &qPeriodFrom < RoomInventoryBlocks.CheckInDate
	|					AND (&qPeriodTo >= RoomInventoryBlocks.CheckOutDate
	|						AND RoomInventoryBlocks.CheckOutDate <> &qEmptyDate)
	|				THEN DATEDIFF(RoomInventoryBlocks.CheckInDate, RoomInventoryBlocks.CheckOutDate, DAY)
	|			WHEN &qPeriodFrom >= RoomInventoryBlocks.CheckInDate
	|					AND (&qPeriodTo < RoomInventoryBlocks.CheckOutDate
	|						OR RoomInventoryBlocks.CheckOutDate = &qEmptyDate)
	|				THEN DATEDIFF(&qPeriodFrom, &qPeriodTo, DAY)
	|			WHEN &qPeriodFrom >= RoomInventoryBlocks.CheckInDate
	|					AND (&qPeriodTo >= RoomInventoryBlocks.CheckOutDate
	|						AND RoomInventoryBlocks.CheckOutDate <> &qEmptyDate)
	|				THEN DATEDIFF(&qPeriodFrom, RoomInventoryBlocks.CheckOutDate, DAY)
	|		END) AS RoomsBlocked,
	|	SUM(CASE
	|			WHEN &qPeriodFrom < RoomInventoryBlocks.CheckInDate
	|					AND (&qPeriodTo < RoomInventoryBlocks.CheckOutDate
	|						OR RoomInventoryBlocks.CheckOutDate = &qEmptyDate)
	|				THEN DATEDIFF(RoomInventoryBlocks.CheckInDate, &qPeriodTo, DAY) * RoomInventoryBlocks.Room.NumberOfBedsPerRoom
	|			WHEN &qPeriodFrom < RoomInventoryBlocks.CheckInDate
	|					AND (&qPeriodTo >= RoomInventoryBlocks.CheckOutDate
	|						AND RoomInventoryBlocks.CheckOutDate <> &qEmptyDate)
	|				THEN DATEDIFF(RoomInventoryBlocks.CheckInDate, RoomInventoryBlocks.CheckOutDate, DAY) * RoomInventoryBlocks.Room.NumberOfBedsPerRoom
	|			WHEN &qPeriodFrom >= RoomInventoryBlocks.CheckInDate
	|					AND (&qPeriodTo < RoomInventoryBlocks.CheckOutDate
	|						OR RoomInventoryBlocks.CheckOutDate = &qEmptyDate)
	|				THEN DATEDIFF(&qPeriodFrom, &qPeriodTo, DAY) * RoomInventoryBlocks.Room.NumberOfBedsPerRoom
	|			WHEN &qPeriodFrom >= RoomInventoryBlocks.CheckInDate
	|					AND (&qPeriodTo >= RoomInventoryBlocks.CheckOutDate
	|						AND RoomInventoryBlocks.CheckOutDate <> &qEmptyDate)
	|				THEN DATEDIFF(&qPeriodFrom, RoomInventoryBlocks.CheckOutDate, DAY) * RoomInventoryBlocks.Room.NumberOfBedsPerRoom
	|		END) AS BedsBlocked
	|INTO RoomInventoryBlocks
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventoryBlocks
	|WHERE
	|	RoomInventoryBlocks.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND RoomInventoryBlocks.IsBlocking
	|	AND (RoomInventoryBlocks.CheckOutDate > &qPeriodFrom
	|			OR RoomInventoryBlocks.CheckOutDate = &qEmptyDate)
	|	AND RoomInventoryBlocks.CheckInDate < &qPeriodTo
	|	AND RoomInventoryBlocks.Hotel IN HIERARCHY(&qHotel)
	|	AND (RoomInventoryBlocks.Room IN HIERARCHY (&qRoom)
	|			OR &qIsEmptyRoom)
	|	AND (NOT RoomInventoryBlocks.Room IN (&qRooms2IgnoreList)
	|			OR &qRooms2IgnoreListIsEmpty)
	|	AND (RoomInventoryBlocks.RoomType IN HIERARCHY (&qRoomType)
	|			OR &qIsEmptyRoomType)
	|
	|GROUP BY
	|	RoomInventoryBlocks.Hotel,
	|	RoomInventoryBlocks.Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TotalRoomInventoryBalanceAndTurnovers.Hotel AS Hotel,
	|	TotalRoomInventoryBalanceAndTurnovers.Room AS Room,
	|	ISNULL(TotalRoomInventoryBalanceAndTurnovers.TotalRoomsBalance, 0) * (DATEDIFF(&qPeriodFrom, &qPeriodTo, DAY) + 1) AS TotalRooms,
	|	ISNULL(TotalRoomInventoryBalanceAndTurnovers.TotalRoomsBalance, 0) * (DATEDIFF(&qPeriodFrom, &qPeriodTo, DAY) + 1) * TotalRoomInventoryBalanceAndTurnovers.Room.NumberOfBedsPerRoom AS TotalBeds,
	|	ISNULL(RoomInventoryBlocks.RoomsBlocked, 0) AS TotalRoomsBlocked,
	|	ISNULL(RoomInventoryBlocks.BedsBlocked, 0) AS TotalBedsBlocked
	|INTO RoomInventoryTotals
	|FROM
	|	AccumulationRegister.RoomInventory.Balance(
	|			&qPeriodFrom,
	|			Hotel IN HIERARCHY (&qHotel)
	|				AND (Room IN HIERARCHY (&qRoom)
	|					OR &qIsEmptyRoom)
	|				AND (NOT Room IN (&qRooms2IgnoreList)
	|					OR &qRooms2IgnoreListIsEmpty)
	|				AND (RoomType IN HIERARCHY (&qRoomType)
	|					OR &qIsEmptyRoomType)) AS TotalRoomInventoryBalanceAndTurnovers
	|		LEFT JOIN RoomInventoryBlocks AS RoomInventoryBlocks
	|		ON TotalRoomInventoryBalanceAndTurnovers.Hotel = RoomInventoryBlocks.Hotel
	|			AND TotalRoomInventoryBalanceAndTurnovers.Room = RoomInventoryBlocks.Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TotalRoomTypeInventoryBalanceAndTurnoversPerDay.Hotel AS Hotel,
	|	TotalRoomTypeInventoryBalanceAndTurnoversPerDay.RoomType AS RoomType,
	|	TotalRoomTypeInventoryBalanceAndTurnoversPerDay.Period AS Period,
	|	TotalRoomTypeInventoryBalanceAndTurnoversPerDay.CounterClosingBalance AS CounterClosingBalance,
	|	TotalRoomTypeInventoryBalanceAndTurnoversPerDay.TotalRoomsClosingBalance AS TotalRooms,
	|	TotalRoomTypeInventoryBalanceAndTurnoversPerDay.TotalBedsClosingBalance AS TotalBeds,
	|	-TotalRoomTypeInventoryBalanceAndTurnoversPerDay.RoomsBlockedClosingBalance AS TotalRoomsBlocked,
	|	-TotalRoomTypeInventoryBalanceAndTurnoversPerDay.BedsBlockedClosingBalance AS TotalBedsBlocked,
	|	TotalRoomTypeInventoryBalanceAndTurnoversPerDay.GuestsReservedReceipt AS TotalGuestsReservedReceipt,
	|	TotalRoomTypeInventoryBalanceAndTurnoversPerDay.GuestsReservedExpense AS TotalGuestsReservedExpense,
	|	TotalRoomTypeInventoryBalanceAndTurnoversPerDay.InHouseGuestsReceipt AS TotalInHouseGuestsReceipt,
	|	TotalRoomTypeInventoryBalanceAndTurnoversPerDay.InHouseGuestsExpense AS TotalInHouseGuestsExpense
	|INTO HotelInventoryTotalsPerDay
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			RegisterRecordsAndPeriodBoundaries,
	|			&qUsePerDayStats
	|				AND Hotel IN HIERARCHY (&qHotel)
	|				AND (Room IN HIERARCHY (&qRoom)
	|					OR &qIsEmptyRoom)
	|				AND (NOT Room IN (&qRooms2IgnoreList)
	|					OR &qRooms2IgnoreListIsEmpty)
	|				AND (RoomType IN HIERARCHY (&qRoomType)
	|					OR &qIsEmptyRoomType)) AS TotalRoomTypeInventoryBalanceAndTurnoversPerDay
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TotalRoomTypeInventoryBalanceAndTurnoversPerMonth.Hotel AS Hotel,
	|	TotalRoomTypeInventoryBalanceAndTurnoversPerMonth.RoomType AS RoomType,
	|	BEGINOFPERIOD(TotalRoomTypeInventoryBalanceAndTurnoversPerMonth.Period, MONTH) AS Period,
	|	SUM(TotalRoomTypeInventoryBalanceAndTurnoversPerMonth.CounterClosingBalance) AS CounterClosingBalance,
	|	SUM(TotalRoomTypeInventoryBalanceAndTurnoversPerMonth.TotalRoomsClosingBalance) AS TotalRooms,
	|	SUM(TotalRoomTypeInventoryBalanceAndTurnoversPerMonth.TotalBedsClosingBalance) AS TotalBeds,
	|	-SUM(TotalRoomTypeInventoryBalanceAndTurnoversPerMonth.RoomsBlockedClosingBalance) AS TotalRoomsBlocked,
	|	-SUM(TotalRoomTypeInventoryBalanceAndTurnoversPerMonth.BedsBlockedClosingBalance) AS TotalBedsBlocked,
	|	SUM(TotalRoomTypeInventoryBalanceAndTurnoversPerMonth.GuestsReservedReceipt) AS TotalGuestsReservedReceipt,
	|	SUM(TotalRoomTypeInventoryBalanceAndTurnoversPerMonth.GuestsReservedExpense) AS TotalGuestsReservedExpense,
	|	SUM(TotalRoomTypeInventoryBalanceAndTurnoversPerMonth.InHouseGuestsReceipt) AS TotalInHouseGuestsReceipt,
	|	SUM(TotalRoomTypeInventoryBalanceAndTurnoversPerMonth.InHouseGuestsExpense) AS TotalInHouseGuestsExpense
	|INTO HotelInventoryTotalsPerMonth
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			RegisterRecordsAndPeriodBoundaries,
	|			&qUsePerMonthStats
	|				AND Hotel IN HIERARCHY (&qHotel)
	|				AND (Room IN HIERARCHY (&qRoom)
	|					OR &qIsEmptyRoom)
	|				AND (NOT Room IN (&qRooms2IgnoreList)
	|					OR &qRooms2IgnoreListIsEmpty)
	|				AND (RoomType IN HIERARCHY (&qRoomType)
	|					OR &qIsEmptyRoomType)) AS TotalRoomTypeInventoryBalanceAndTurnoversPerMonth
	|
	|GROUP BY
	|	TotalRoomTypeInventoryBalanceAndTurnoversPerMonth.Hotel,
	|	TotalRoomTypeInventoryBalanceAndTurnoversPerMonth.RoomType,
	|	BEGINOFPERIOD(TotalRoomTypeInventoryBalanceAndTurnoversPerMonth.Period, MONTH)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TotalRoomTypeInventoryBalanceAndTurnoversPerPeriod.Hotel AS Hotel,
	|	TotalRoomTypeInventoryBalanceAndTurnoversPerPeriod.RoomType AS RoomType,
	|	SUM(TotalRoomTypeInventoryBalanceAndTurnoversPerPeriod.CounterClosingBalance) AS CounterClosingBalance,
	|	SUM(TotalRoomTypeInventoryBalanceAndTurnoversPerPeriod.TotalRoomsClosingBalance) AS TotalRooms,
	|	SUM(TotalRoomTypeInventoryBalanceAndTurnoversPerPeriod.TotalBedsClosingBalance) AS TotalBeds,
	|	-SUM(TotalRoomTypeInventoryBalanceAndTurnoversPerPeriod.RoomsBlockedClosingBalance) AS TotalRoomsBlocked,
	|	-SUM(TotalRoomTypeInventoryBalanceAndTurnoversPerPeriod.BedsBlockedClosingBalance) AS TotalBedsBlocked,
	|	SUM(TotalRoomTypeInventoryBalanceAndTurnoversPerPeriod.GuestsReservedReceipt) AS TotalGuestsReservedReceipt,
	|	SUM(TotalRoomTypeInventoryBalanceAndTurnoversPerPeriod.GuestsReservedExpense) AS TotalGuestsReservedExpense,
	|	SUM(TotalRoomTypeInventoryBalanceAndTurnoversPerPeriod.InHouseGuestsReceipt) AS TotalInHouseGuestsReceipt,
	|	SUM(TotalRoomTypeInventoryBalanceAndTurnoversPerPeriod.InHouseGuestsExpense) AS TotalInHouseGuestsExpense
	|INTO HotelInventoryTotalsPerPeriod
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			RegisterRecordsAndPeriodBoundaries,
	|			&qUsePerPeriodStats
	|				AND Hotel IN HIERARCHY (&qHotel)
	|				AND (Room IN HIERARCHY (&qRoom)
	|					OR &qIsEmptyRoom)
	|				AND (NOT Room IN (&qRooms2IgnoreList)
	|					OR &qRooms2IgnoreListIsEmpty)
	|				AND (RoomType IN HIERARCHY (&qRoomType)
	|					OR &qIsEmptyRoomType)) AS TotalRoomTypeInventoryBalanceAndTurnoversPerPeriod
	|
	|GROUP BY
	|	TotalRoomTypeInventoryBalanceAndTurnoversPerPeriod.Hotel,
	|	TotalRoomTypeInventoryBalanceAndTurnoversPerPeriod.RoomType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomSalesPerRoomTypePerDay.Hotel AS Hotel,
	|	RoomSalesPerRoomTypePerDay.RoomType AS RoomType,
	|	RoomSalesPerRoomTypePerDay.Period AS Period,
	|	SUM(RoomSalesPerRoomTypePerDay.SalesTurnover) AS SalesTurnover,
	|	SUM(RoomSalesPerRoomTypePerDay.RoomRevenueTurnover) AS RoomRevenueTurnover,
	|	SUM(RoomSalesPerRoomTypePerDay.ExtraBedRevenueTurnover) AS ExtraBedRevenueTurnover,
	|	SUM(RoomSalesPerRoomTypePerDay.SalesWithoutVATTurnover) AS SalesWithoutVATTurnover,
	|	SUM(RoomSalesPerRoomTypePerDay.RoomRevenueWithoutVATTurnover) AS RoomRevenueWithoutVATTurnover,
	|	SUM(RoomSalesPerRoomTypePerDay.ExtraBedRevenueWithoutVATTurnover) AS ExtraBedRevenueWithoutVATTurnover,
	|	SUM(RoomSalesPerRoomTypePerDay.CommissionSumTurnover) AS CommissionSumTurnover,
	|	SUM(RoomSalesPerRoomTypePerDay.CommissionSumWithoutVATTurnover) AS CommissionSumWithoutVATTurnover,
	|	SUM(RoomSalesPerRoomTypePerDay.DiscountSumTurnover) AS DiscountSumTurnover,
	|	SUM(RoomSalesPerRoomTypePerDay.DiscountSumWithoutVATTurnover) AS DiscountSumWithoutVATTurnover,
	|	SUM(RoomSalesPerRoomTypePerDay.RoomsRentedTurnover) AS RoomsRentedTurnover,
	|	SUM(RoomSalesPerRoomTypePerDay.BedsRentedTurnover) AS BedsRentedTurnover,
	|	SUM(RoomSalesPerRoomTypePerDay.AdditionalBedsRentedTurnover) AS AdditionalBedsRentedTurnover,
	|	SUM(RoomSalesPerRoomTypePerDay.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover,
	|	SUM(RoomSalesPerRoomTypePerDay.RoomsCheckedInTurnover) AS RoomsCheckedInTurnover,
	|	SUM(RoomSalesPerRoomTypePerDay.BedsCheckedInTurnover) AS BedsCheckedInTurnover,
	|	SUM(RoomSalesPerRoomTypePerDay.AdditionalBedsCheckedInTurnover) AS AdditionalBedsCheckedInTurnover,
	|	SUM(RoomSalesPerRoomTypePerDay.BookingWindowTurnover) AS BookingWindowTurnover,
	|	SUM(RoomSalesPerRoomTypePerDay.Counter) AS Counter,
	|	SUM(RoomSalesPerRoomTypePerDay.GuestDaysTurnover) AS GuestDaysTurnover,
	|	SUM(RoomSalesPerRoomTypePerDay.NumberOfDetailedRows) AS NumberOfDetailedRows,
	|	RoomSalesPerRoomTypePerDay.ServiceDate AS ServiceDate
	|INTO RoomSalesPerRoomTypePerDay
	|FROM
	|	(SELECT
	|		RoomSales.Period AS Period,
	|		RoomSales.Hotel AS Hotel,
	|		RoomSales.RoomType AS RoomType,
	|		RoomSales.SalesTurnover AS SalesTurnover,
	|		RoomSales.RoomRevenueTurnover AS RoomRevenueTurnover,
	|		RoomSales.ExtraBedRevenueTurnover AS ExtraBedRevenueTurnover,
	|		RoomSales.SalesWithoutVATTurnover AS SalesWithoutVATTurnover,
	|		RoomSales.RoomRevenueWithoutVATTurnover AS RoomRevenueWithoutVATTurnover,
	|		RoomSales.ExtraBedRevenueWithoutVATTurnover AS ExtraBedRevenueWithoutVATTurnover,
	|		RoomSales.CommissionSumTurnover AS CommissionSumTurnover,
	|		RoomSales.CommissionSumWithoutVATTurnover AS CommissionSumWithoutVATTurnover,
	|		RoomSales.DiscountSumTurnover AS DiscountSumTurnover,
	|		RoomSales.DiscountSumWithoutVATTurnover AS DiscountSumWithoutVATTurnover,
	|		RoomSales.RoomsRentedTurnover AS RoomsRentedTurnover,
	|		RoomSales.BedsRentedTurnover AS BedsRentedTurnover,
	|		RoomSales.AdditionalBedsRentedTurnover AS AdditionalBedsRentedTurnover,
	|		RoomSales.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
	|		RoomSales.RoomsCheckedInTurnover AS RoomsCheckedInTurnover,
	|		RoomSales.BedsCheckedInTurnover AS BedsCheckedInTurnover,
	|		RoomSales.AdditionalBedsCheckedInTurnover AS AdditionalBedsCheckedInTurnover,
	|		RoomSales.BookingWindowTurnover AS BookingWindowTurnover,
	|		RoomSales.Counter AS Counter,
	|		RoomSales.GuestDaysTurnover AS GuestDaysTurnover,
	|		RoomSales.NumberOfDetailedRows AS NumberOfDetailedRows,
	|		RoomSales.ServiceDate AS ServiceDate
	|	FROM
	|		(SELECT
	|			BEGINOFPERIOD(RoomSalesTotals.Period, DAY) AS Period,
	|			RoomSalesTotals.Company AS Company,
	|			RoomSalesTotals.Hotel AS Hotel,
	|			RoomSalesTotals.ReportingCurrency AS ReportingCurrency,
	|			RoomSalesTotals.Room AS Room,
	|			RoomSalesTotals.RoomType AS RoomType,
	|			RoomSalesTotals.RoomRate AS RoomRate,
	|			RoomSalesTotals.AccommodationType AS AccommodationType,
	|			RoomSalesTotals.ClientType AS ClientType,
	|			RoomSalesTotals.MarketingCode AS MarketingCode,
	|			RoomSalesTotals.SourceOfBusiness AS SourceOfBusiness,
	|			RoomSalesTotals.Service AS Service,
	|			RoomSalesTotals.CalendarDayType AS CalendarDayType,
	|			RoomSalesTotals.PriceTag AS PriceTag,
	|			RoomSalesTotals.AccountingDate AS AccountingDate,
	|			RoomSalesTotals.ParentDoc AS ParentDoc,
	|			RoomSalesTotals.ParentDoc.RoomQuota AS RoomQuota,
	|			RoomSalesTotals.GuestGroup AS GuestGroup,
	|			RoomSalesTotals.Customer AS Customer,
	|			RoomSalesTotals.Contract AS Contract,
	|			RoomSalesTotals.Agent AS Agent,
	|			RoomSalesTotals.Client AS Client,
	|			RoomSalesTotals.Resource AS Resource,
	|			RoomSalesTotals.Folio AS Folio,
	|			RoomSalesTotals.Price AS Price,
	|			RoomSalesTotals.ResourceType AS ResourceType,
	|			RoomSalesTotals.TripPurpose AS TripPurpose,
	|			RoomSalesTotals.HotelProduct AS HotelProduct,
	|			RoomSalesTotals.Author AS Author,
	|			RoomSalesTotals.Discount AS Discount,
	|			RoomSalesTotals.DiscountType AS DiscountType,
	|			RoomSalesTotals.DiscountCard AS DiscountCard,
	|			RoomSalesTotals.AgentCommission AS AgentCommission,
	|			RoomSalesTotals.AgentCommissionType AS AgentCommissionType,
	|			RoomSalesTotals.PaymentMethod AS PaymentMethod,
	|			RoomSalesTotals.VATRate AS VATRate,
	|			RoomSalesTotals.Sales AS SalesTurnover,
	|			RoomSalesTotals.RoomRevenue AS RoomRevenueTurnover,
	|			RoomSalesTotals.ExtraBedRevenue AS ExtraBedRevenueTurnover,
	|			RoomSalesTotals.SalesWithoutVAT AS SalesWithoutVATTurnover,
	|			RoomSalesTotals.RoomRevenueWithoutVAT AS RoomRevenueWithoutVATTurnover,
	|			RoomSalesTotals.ExtraBedRevenueWithoutVAT AS ExtraBedRevenueWithoutVATTurnover,
	|			RoomSalesTotals.CommissionSum AS CommissionSumTurnover,
	|			RoomSalesTotals.CommissionSumWithoutVAT AS CommissionSumWithoutVATTurnover,
	|			RoomSalesTotals.DiscountSum AS DiscountSumTurnover,
	|			RoomSalesTotals.DiscountSumWithoutVAT AS DiscountSumWithoutVATTurnover,
	|			RoomSalesTotals.RoomsRented AS RoomsRentedTurnover,
	|			RoomSalesTotals.BedsRented AS BedsRentedTurnover,
	|			RoomSalesTotals.AdditionalBedsRented AS AdditionalBedsRentedTurnover,
	|			RoomSalesTotals.GuestsCheckedIn AS GuestsCheckedInTurnover,
	|			RoomSalesTotals.RoomsCheckedIn AS RoomsCheckedInTurnover,
	|			RoomSalesTotals.BedsCheckedIn AS BedsCheckedInTurnover,
	|			RoomSalesTotals.AdditionalBedsCheckedIn AS AdditionalBedsCheckedInTurnover,
	|			RoomSalesTotals.BookingWindow AS BookingWindowTurnover,
	|			RoomSalesTotals.Quantity AS Counter,
	|			RoomSalesTotals.GuestDays AS GuestDaysTurnover,
	|			1 AS NumberOfDetailedRows,
	|			RoomSalesTotals.ServiceDate AS ServiceDate
	|		FROM
	|			AccumulationRegister.Sales AS RoomSalesTotals
	|		WHERE
	|			RoomSalesTotals.Period >= &qPeriodFrom
	|			AND RoomSalesTotals.Period <= &qPeriodTo
	|			AND &qUsePerDayStats
	|			AND (&qHideCorrections
	|					OR NOT &qHideCorrections
	|						AND NOT RoomSalesTotals.IsCorrection)
	|			AND &qUsePerRoomTypeStats
	|			AND RoomSalesTotals.Hotel IN HIERARCHY(&qHotel)
	|			AND (RoomSalesTotals.Room IN HIERARCHY (&qRoom)
	|					OR &qIsEmptyRoom)
	|			AND (NOT RoomSalesTotals.Room IN (&qRooms2IgnoreList)
	|					OR &qRooms2IgnoreListIsEmpty)
	|			AND (RoomSalesTotals.RoomType IN HIERARCHY (&qRoomType)
	|					OR &qIsEmptyRoomType)
	|			AND (RoomSalesTotals.Service IN HIERARCHY (&qService)
	|					OR &qIsEmptyService)
	|			AND (RoomSalesTotals.Service IN (&qServicesList)
	|					OR NOT &qUseServicesList)
	|			AND (NOT &qWithAllotments
	|					OR &qWithAllotments
	|						AND NOT ISNULL(RoomSalesTotals.ParentDoc.RoomQuota.IsCommitment, FALSE))
	|			AND (NOT &qFilterByReservationCreationDate
	|						AND NOT &qLimitByTodaysDate
	|					OR NOT &qFilterByReservationCreationDate
	|						AND &qLimitByTodaysDate
	|						AND NOT &qByGroupCreationDate
	|						AND (RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesTotals.ParentDoc.Date <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(RoomSalesTotals.AccountingDate, YEAR), DAY, &qTodaysDay), DAY)
	|							OR NOT RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesTotals.ParentDoc.Reservation.Date <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(RoomSalesTotals.AccountingDate, YEAR), DAY, &qTodaysDay), DAY))
	|					OR NOT &qFilterByReservationCreationDate
	|						AND &qLimitByTodaysDate
	|						AND &qByGroupCreationDate
	|						AND NOT RoomSalesTotals.GuestGroup.CreateDate IS NULL
	|						AND RoomSalesTotals.GuestGroup.CreateDate <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(RoomSalesTotals.AccountingDate, YEAR), DAY, &qTodaysDay), DAY)
	|					OR &qFilterByReservationCreationDate
	|						AND NOT &qNoYear
	|						AND NOT &qByGroupCreationDate
	|						AND (RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesTotals.ParentDoc.Date >= &qDateFrom
	|							OR NOT RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesTotals.ParentDoc.Reservation.Date >= &qDateFrom)
	|						AND (&qDateToIsEmpty
	|							OR RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesTotals.ParentDoc.Date <= &qDateTo
	|							OR NOT RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesTotals.ParentDoc.Reservation.Date <= &qDateTo)
	|					OR &qFilterByReservationCreationDate
	|						AND NOT &qNoYear
	|						AND &qByGroupCreationDate
	|						AND NOT RoomSalesTotals.GuestGroup.CreateDate IS NULL
	|						AND RoomSalesTotals.GuestGroup.CreateDate >= &qDateFrom
	|						AND (&qDateToIsEmpty
	|							OR RoomSalesTotals.GuestGroup.CreateDate <= &qDateTo)
	|					OR &qFilterByReservationCreationDate
	|						AND &qNoYear
	|						AND NOT &qByGroupCreationDate
	|						AND CASE
	|							WHEN &qShiftFrom = 1
	|									AND RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Date, YEAR, 2 - YEAR(RoomSalesTotals.ParentDoc.Date)) <= &qDateTo
	|								THEN TRUE
	|							WHEN &qShiftFrom = 1
	|									AND RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Date, YEAR, 1 - YEAR(RoomSalesTotals.ParentDoc.Date)) >= &qDateFrom
	|								THEN TRUE
	|							WHEN &qShiftFrom = 2
	|									AND RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Date, YEAR, 2 - YEAR(RoomSalesTotals.ParentDoc.Date)) >= &qDateFrom
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Date, YEAR, 2 - YEAR(RoomSalesTotals.ParentDoc.Date)) <= &qDateTo
	|								THEN TRUE
	|							WHEN &qShiftFrom = 1
	|									AND NOT RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Reservation.Date, YEAR, 2 - YEAR(RoomSalesTotals.ParentDoc.Reservation.Date)) <= &qDateTo
	|								THEN TRUE
	|							WHEN &qShiftFrom = 1
	|									AND NOT RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Reservation.Date, YEAR, 1 - YEAR(RoomSalesTotals.ParentDoc.Reservation.Date)) >= &qDateFrom
	|								THEN TRUE
	|							WHEN &qShiftFrom = 2
	|									AND NOT RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Reservation.Date, YEAR, 2 - YEAR(RoomSalesTotals.ParentDoc.Reservation.Date)) >= &qDateFrom
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Reservation.Date, YEAR, 2 - YEAR(RoomSalesTotals.ParentDoc.Reservation.Date)) <= &qDateTo
	|								THEN TRUE
	|							ELSE FALSE
	|						END
	|					OR &qFilterByReservationCreationDate
	|						AND &qNoYear
	|						AND &qByGroupCreationDate
	|						AND NOT RoomSalesTotals.GuestGroup.CreateDate IS NULL
	|						AND CASE
	|							WHEN &qShiftFrom = 1
	|									AND DATEADD(RoomSalesTotals.GuestGroup.CreateDate, YEAR, 2 - YEAR(RoomSalesTotals.GuestGroup.CreateDate)) <= &qDateTo
	|								THEN TRUE
	|							WHEN &qShiftFrom = 1
	|									AND DATEADD(RoomSalesTotals.GuestGroup.CreateDate, YEAR, 1 - YEAR(RoomSalesTotals.GuestGroup.CreateDate)) >= &qDateFrom
	|								THEN TRUE
	|							WHEN &qShiftFrom = 2
	|									AND DATEADD(RoomSalesTotals.GuestGroup.CreateDate, YEAR, 2 - YEAR(RoomSalesTotals.GuestGroup.CreateDate)) >= &qDateFrom
	|									AND DATEADD(RoomSalesTotals.GuestGroup.CreateDate, YEAR, 2 - YEAR(RoomSalesTotals.GuestGroup.CreateDate)) <= &qDateTo
	|								THEN TRUE
	|							ELSE FALSE
	|						END)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			BEGINOFPERIOD(RoomSalesForecastTotals.Period, DAY),
	|			RoomSalesForecastTotals.Company,
	|			RoomSalesForecastTotals.Hotel,
	|			RoomSalesForecastTotals.ReportingCurrency,
	|			RoomSalesForecastTotals.Room,
	|			RoomSalesForecastTotals.RoomType,
	|			RoomSalesForecastTotals.RoomRate,
	|			RoomSalesForecastTotals.AccommodationType,
	|			RoomSalesForecastTotals.ClientType,
	|			RoomSalesForecastTotals.MarketingCode,
	|			RoomSalesForecastTotals.SourceOfBusiness,
	|			RoomSalesForecastTotals.Service,
	|			RoomSalesForecastTotals.CalendarDayType,
	|			RoomSalesForecastTotals.PriceTag,
	|			RoomSalesForecastTotals.AccountingDate,
	|			RoomSalesForecastTotals.ParentDoc,
	|			RoomSalesForecastTotals.ParentDoc.RoomQuota,
	|			RoomSalesForecastTotals.GuestGroup,
	|			RoomSalesForecastTotals.Customer,
	|			RoomSalesForecastTotals.Contract,
	|			RoomSalesForecastTotals.Agent,
	|			RoomSalesForecastTotals.Client,
	|			RoomSalesForecastTotals.Resource,
	|			RoomSalesForecastTotals.Folio,
	|			RoomSalesForecastTotals.Price,
	|			RoomSalesForecastTotals.ResourceType,
	|			RoomSalesForecastTotals.TripPurpose,
	|			RoomSalesForecastTotals.HotelProduct,
	|			RoomSalesForecastTotals.Author,
	|			RoomSalesForecastTotals.Discount,
	|			RoomSalesForecastTotals.DiscountType,
	|			RoomSalesForecastTotals.DiscountCard,
	|			RoomSalesForecastTotals.AgentCommission,
	|			RoomSalesForecastTotals.AgentCommissionType,
	|			RoomSalesForecastTotals.PaymentMethod,
	|			RoomSalesForecastTotals.VATRate,
	|			RoomSalesForecastTotals.Sales,
	|			RoomSalesForecastTotals.RoomRevenue,
	|			RoomSalesForecastTotals.ExtraBedRevenue,
	|			RoomSalesForecastTotals.SalesWithoutVAT,
	|			RoomSalesForecastTotals.RoomRevenueWithoutVAT,
	|			RoomSalesForecastTotals.ExtraBedRevenueWithoutVAT,
	|			RoomSalesForecastTotals.CommissionSum,
	|			RoomSalesForecastTotals.CommissionSumWithoutVAT,
	|			RoomSalesForecastTotals.DiscountSum,
	|			RoomSalesForecastTotals.DiscountSumWithoutVAT,
	|			RoomSalesForecastTotals.RoomsRented,
	|			RoomSalesForecastTotals.BedsRented,
	|			RoomSalesForecastTotals.AdditionalBedsRented,
	|			RoomSalesForecastTotals.GuestsCheckedIn,
	|			RoomSalesForecastTotals.RoomsCheckedIn,
	|			RoomSalesForecastTotals.BedsCheckedIn,
	|			RoomSalesForecastTotals.AdditionalBedsCheckedIn,
	|			RoomSalesForecastTotals.BookingWindow,
	|			RoomSalesForecastTotals.Quantity,
	|			RoomSalesForecastTotals.GuestDays,
	|			1,
	|			RoomSalesForecastTotals.ServiceDate
	|		FROM
	|			AccumulationRegister.SalesForecast AS RoomSalesForecastTotals
	|		WHERE
	|			RoomSalesForecastTotals.Period >= &qForecastPeriodFrom
	|			AND RoomSalesForecastTotals.Period <= &qForecastPeriodTo
	|			AND &qUsePerDayStats
	|			AND &qUsePerRoomTypeStats
	|			AND &qUseForecast
	|			AND RoomSalesForecastTotals.Hotel IN HIERARCHY(&qHotel)
	|			AND (RoomSalesForecastTotals.Room IN HIERARCHY (&qRoom)
	|					OR &qIsEmptyRoom)
	|			AND (NOT RoomSalesForecastTotals.Room IN (&qRooms2IgnoreList)
	|					OR &qRooms2IgnoreListIsEmpty)
	|			AND (RoomSalesForecastTotals.RoomType IN HIERARCHY (&qRoomType)
	|					OR &qIsEmptyRoomType)
	|			AND (RoomSalesForecastTotals.Service IN HIERARCHY (&qService)
	|					OR &qIsEmptyService)
	|			AND (RoomSalesForecastTotals.Service IN (&qServicesList)
	|					OR NOT &qUseServicesList)
	|			AND (NOT &qWithAllotments
	|					OR &qWithAllotments
	|						AND NOT ISNULL(RoomSalesForecastTotals.ParentDoc.RoomQuota.IsCommitment, FALSE))
	|			AND (NOT &qFilterByReservationCreationDate
	|						AND NOT &qLimitByTodaysDate
	|					OR NOT &qFilterByReservationCreationDate
	|						AND &qLimitByTodaysDate
	|						AND NOT &qByGroupCreationDate
	|						AND (RoomSalesForecastTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesForecastTotals.ParentDoc.Date <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(RoomSalesForecastTotals.AccountingDate, YEAR), DAY, &qTodaysDay), DAY)
	|							OR NOT RoomSalesForecastTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesForecastTotals.ParentDoc.Reservation.Date <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(RoomSalesForecastTotals.AccountingDate, YEAR), DAY, &qTodaysDay), DAY))
	|					OR NOT &qFilterByReservationCreationDate
	|						AND &qLimitByTodaysDate
	|						AND &qByGroupCreationDate
	|						AND NOT RoomSalesForecastTotals.GuestGroup.CreateDate IS NULL
	|						AND RoomSalesForecastTotals.GuestGroup.CreateDate <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(RoomSalesForecastTotals.AccountingDate, YEAR), DAY, &qTodaysDay), DAY)
	|					OR &qFilterByReservationCreationDate
	|						AND NOT &qNoYear
	|						AND NOT &qByGroupCreationDate
	|						AND NOT RoomSalesForecastTotals.ParentDoc.Date IS NULL
	|						AND RoomSalesForecastTotals.ParentDoc.Date >= &qDateFrom
	|						AND (RoomSalesForecastTotals.ParentDoc.Date <= &qDateTo
	|							OR &qDateToIsEmpty)
	|					OR &qFilterByReservationCreationDate
	|						AND NOT &qNoYear
	|						AND &qByGroupCreationDate
	|						AND NOT RoomSalesForecastTotals.GuestGroup.CreateDate IS NULL
	|						AND RoomSalesForecastTotals.GuestGroup.CreateDate >= &qDateFrom
	|						AND (&qDateToIsEmpty
	|							OR RoomSalesForecastTotals.GuestGroup.CreateDate <= &qDateTo)
	|					OR &qFilterByReservationCreationDate
	|						AND &qNoYear
	|						AND NOT &qByGroupCreationDate
	|						AND NOT RoomSalesForecastTotals.ParentDoc.Date IS NULL
	|						AND CASE
	|							WHEN &qShiftFrom = 1
	|									AND DATEADD(RoomSalesForecastTotals.ParentDoc.Date, YEAR, 2 - YEAR(RoomSalesForecastTotals.ParentDoc.Date)) <= &qDateTo
	|								THEN TRUE
	|							WHEN &qShiftFrom = 1
	|									AND DATEADD(RoomSalesForecastTotals.ParentDoc.Date, YEAR, 1 - YEAR(RoomSalesForecastTotals.ParentDoc.Date)) >= &qDateFrom
	|								THEN TRUE
	|							WHEN &qShiftFrom = 2
	|									AND DATEADD(RoomSalesForecastTotals.ParentDoc.Date, YEAR, 2 - YEAR(RoomSalesForecastTotals.ParentDoc.Date)) >= &qDateFrom
	|									AND DATEADD(RoomSalesForecastTotals.ParentDoc.Date, YEAR, 2 - YEAR(RoomSalesForecastTotals.ParentDoc.Date)) <= &qDateTo
	|								THEN TRUE
	|							ELSE FALSE
	|						END
	|					OR &qFilterByReservationCreationDate
	|						AND &qNoYear
	|						AND &qByGroupCreationDate
	|						AND NOT RoomSalesForecastTotals.GuestGroup.CreateDate IS NULL
	|						AND CASE
	|							WHEN &qShiftFrom = 1
	|									AND DATEADD(RoomSalesForecastTotals.GuestGroup.CreateDate, YEAR, 2 - YEAR(RoomSalesForecastTotals.GuestGroup.CreateDate)) <= &qDateTo
	|								THEN TRUE
	|							WHEN &qShiftFrom = 1
	|									AND DATEADD(RoomSalesForecastTotals.GuestGroup.CreateDate, YEAR, 1 - YEAR(RoomSalesForecastTotals.GuestGroup.CreateDate)) >= &qDateFrom
	|								THEN TRUE
	|							WHEN &qShiftFrom = 2
	|									AND DATEADD(RoomSalesForecastTotals.GuestGroup.CreateDate, YEAR, 2 - YEAR(RoomSalesForecastTotals.GuestGroup.CreateDate)) >= &qDateFrom
	|									AND DATEADD(RoomSalesForecastTotals.GuestGroup.CreateDate, YEAR, 2 - YEAR(RoomSalesForecastTotals.GuestGroup.CreateDate)) <= &qDateTo
	|								THEN TRUE
	|							ELSE FALSE
	|						END)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			RoomTypesListPerDay.Period,
	|			NULL,
	|			RoomTypesListPerDay.Hotel,
	|			RoomTypesListPerDay.Hotel.ReportingCurrency,
	|			NULL,
	|			RoomTypesListPerDay.RoomType,
	|			NULL,
	|			NULL,
	|			NULL,
	|			VALUE(Catalog.MarketingCodes.EmptyRef),
	|			VALUE(Catalog.SourcesOfBusiness.EmptyRef),
	|			NULL,
	|			NULL,
	|			NULL,
	|			RoomTypesListPerDay.Period,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
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
	|			1,
	|			NULL
	|		FROM
	|			HotelInventoryTotalsPerDay AS RoomTypesListPerDay
	|		WHERE
	|			&qUsePerDayStats
	|			AND &qUsePerRoomTypeStats
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			SourcesOfBusinessPerDayPerHotel.Period,
	|			NULL,
	|			SourcesOfBusinessPerDayPerHotel.Hotel,
	|			SourcesOfBusinessPerDayPerHotel.Hotel.ReportingCurrency,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			VALUE(Catalog.MarketingCodes.EmptyRef),
	|			SourcesOfBusinessPerDayPerHotel.SourceOfBusiness,
	|			NULL,
	|			NULL,
	|			NULL,
	|			SourcesOfBusinessPerDayPerHotel.Period,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
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
	|			1,
	|			NULL
	|		FROM
	|			SourcesOfBusinessPerDayPerHotel AS SourcesOfBusinessPerDayPerHotel
	|		WHERE
	|			&qUsePerDayStats
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			MarketingCodesPerDayPerHotel.Period,
	|			NULL,
	|			MarketingCodesPerDayPerHotel.Hotel,
	|			MarketingCodesPerDayPerHotel.Hotel.ReportingCurrency,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			MarketingCodesPerDayPerHotel.MarketingCode,
	|			VALUE(Catalog.SourcesOfBusiness.EmptyRef),
	|			NULL,
	|			NULL,
	|			NULL,
	|			MarketingCodesPerDayPerHotel.Period,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
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
	|			1,
	|			NULL
	|		FROM
	|			MarketingCodesPerDayPerHotel AS MarketingCodesPerDayPerHotel
	|		WHERE
	|			&qUsePerDayStats
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			RoomQuotaSales.Period,
	|			RoomQuotaSales.Hotel.Company,
	|			RoomQuotaSales.Hotel,
	|			RoomQuotaSales.Hotel.ReportingCurrency,
	|			NULL,
	|			RoomQuotaSales.RoomType,
	|			RoomQuotaSales.RoomQuota.RoomRate,
	|			NULL,
	|			RoomQuotaSales.RoomQuota.ClientType,
	|			RoomQuotaSales.RoomQuota.MarketingCode,
	|			RoomQuotaSales.RoomQuota.SourceOfBusiness,
	|			RoomQuotaSales.Service,
	|			RoomQuotaSales.CalendarDayType,
	|			NULL,
	|			RoomQuotaSales.Period,
	|			NULL,
	|			RoomQuotaSales.RoomQuota,
	|			NULL,
	|			RoomQuotaSales.RoomQuota.Customer,
	|			RoomQuotaSales.RoomQuota.Contract,
	|			RoomQuotaSales.RoomQuota.Agent,
	|			NULL,
	|			NULL,
	|			NULL,
	|			RoomQuotaSales.AllotmentPrice,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			RoomQuotaSales.RoomQuota.RoomRate.Discount,
	|			RoomQuotaSales.RoomQuota.RoomRate.DiscountType,
	|			NULL,
	|			RoomQuotaSales.RoomQuota.Agent.AgentCommission,
	|			RoomQuotaSales.RoomQuota.Agent.AgentCommissionType,
	|			RoomQuotaSales.RoomQuota.Customer.PlannedPaymentMethod,
	|			RoomQuotaSales.VATRate,
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
	|			RoomQuotaSales.Counter,
	|			0,
	|			1,
	|			NULL
	|		FROM
	|			RoomQuotaSales AS RoomQuotaSales
	|		WHERE
	|			&qWithAllotments) AS RoomSales) AS RoomSalesPerRoomTypePerDay
	|
	|GROUP BY
	|	RoomSalesPerRoomTypePerDay.Hotel,
	|	RoomSalesPerRoomTypePerDay.RoomType,
	|	RoomSalesPerRoomTypePerDay.Period,
	|	RoomSalesPerRoomTypePerDay.ServiceDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomSalesPerRoomTypePerMonth.Hotel AS Hotel,
	|	RoomSalesPerRoomTypePerMonth.RoomType AS RoomType,
	|	RoomSalesPerRoomTypePerMonth.Period AS Period,
	|	SUM(RoomSalesPerRoomTypePerMonth.SalesTurnover) AS SalesTurnover,
	|	SUM(RoomSalesPerRoomTypePerMonth.RoomRevenueTurnover) AS RoomRevenueTurnover,
	|	SUM(RoomSalesPerRoomTypePerMonth.ExtraBedRevenueTurnover) AS ExtraBedRevenueTurnover,
	|	SUM(RoomSalesPerRoomTypePerMonth.SalesWithoutVATTurnover) AS SalesWithoutVATTurnover,
	|	SUM(RoomSalesPerRoomTypePerMonth.RoomRevenueWithoutVATTurnover) AS RoomRevenueWithoutVATTurnover,
	|	SUM(RoomSalesPerRoomTypePerMonth.ExtraBedRevenueWithoutVATTurnover) AS ExtraBedRevenueWithoutVATTurnover,
	|	SUM(RoomSalesPerRoomTypePerMonth.CommissionSumTurnover) AS CommissionSumTurnover,
	|	SUM(RoomSalesPerRoomTypePerMonth.CommissionSumWithoutVATTurnover) AS CommissionSumWithoutVATTurnover,
	|	SUM(RoomSalesPerRoomTypePerMonth.DiscountSumTurnover) AS DiscountSumTurnover,
	|	SUM(RoomSalesPerRoomTypePerMonth.DiscountSumWithoutVATTurnover) AS DiscountSumWithoutVATTurnover,
	|	SUM(RoomSalesPerRoomTypePerMonth.RoomsRentedTurnover) AS RoomsRentedTurnover,
	|	SUM(RoomSalesPerRoomTypePerMonth.BedsRentedTurnover) AS BedsRentedTurnover,
	|	SUM(RoomSalesPerRoomTypePerMonth.AdditionalBedsRentedTurnover) AS AdditionalBedsRentedTurnover,
	|	SUM(RoomSalesPerRoomTypePerMonth.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover,
	|	SUM(RoomSalesPerRoomTypePerMonth.RoomsCheckedInTurnover) AS RoomsCheckedInTurnover,
	|	SUM(RoomSalesPerRoomTypePerMonth.BedsCheckedInTurnover) AS BedsCheckedInTurnover,
	|	SUM(RoomSalesPerRoomTypePerMonth.AdditionalBedsCheckedInTurnover) AS AdditionalBedsCheckedInTurnover,
	|	SUM(RoomSalesPerRoomTypePerMonth.BookingWindowTurnover) AS BookingWindowTurnover,
	|	SUM(RoomSalesPerRoomTypePerMonth.Counter) AS Counter,
	|	SUM(RoomSalesPerRoomTypePerMonth.GuestDaysTurnover) AS GuestDaysTurnover,
	|	SUM(RoomSalesPerRoomTypePerMonth.NumberOfDetailedRows) AS NumberOfDetailedRows,
	|	RoomSalesPerRoomTypePerMonth.ServiceDate AS ServiceDate
	|INTO RoomSalesPerRoomTypePerMonth
	|FROM
	|	(SELECT
	|		RoomSales.Period AS Period,
	|		RoomSales.Hotel AS Hotel,
	|		RoomSales.RoomType AS RoomType,
	|		RoomSales.SalesTurnover AS SalesTurnover,
	|		RoomSales.RoomRevenueTurnover AS RoomRevenueTurnover,
	|		RoomSales.ExtraBedRevenueTurnover AS ExtraBedRevenueTurnover,
	|		RoomSales.SalesWithoutVATTurnover AS SalesWithoutVATTurnover,
	|		RoomSales.RoomRevenueWithoutVATTurnover AS RoomRevenueWithoutVATTurnover,
	|		RoomSales.ExtraBedRevenueWithoutVATTurnover AS ExtraBedRevenueWithoutVATTurnover,
	|		RoomSales.CommissionSumTurnover AS CommissionSumTurnover,
	|		RoomSales.CommissionSumWithoutVATTurnover AS CommissionSumWithoutVATTurnover,
	|		RoomSales.DiscountSumTurnover AS DiscountSumTurnover,
	|		RoomSales.DiscountSumWithoutVATTurnover AS DiscountSumWithoutVATTurnover,
	|		RoomSales.RoomsRentedTurnover AS RoomsRentedTurnover,
	|		RoomSales.BedsRentedTurnover AS BedsRentedTurnover,
	|		RoomSales.AdditionalBedsRentedTurnover AS AdditionalBedsRentedTurnover,
	|		RoomSales.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
	|		RoomSales.RoomsCheckedInTurnover AS RoomsCheckedInTurnover,
	|		RoomSales.BedsCheckedInTurnover AS BedsCheckedInTurnover,
	|		RoomSales.AdditionalBedsCheckedInTurnover AS AdditionalBedsCheckedInTurnover,
	|		RoomSales.BookingWindowTurnover AS BookingWindowTurnover,
	|		RoomSales.Counter AS Counter,
	|		RoomSales.GuestDaysTurnover AS GuestDaysTurnover,
	|		RoomSales.NumberOfDetailedRows AS NumberOfDetailedRows,
	|		RoomSales.ServiceDate AS ServiceDate
	|	FROM
	|		(SELECT
	|			BEGINOFPERIOD(RoomSalesTotals.Period, MONTH) AS Period,
	|			RoomSalesTotals.Company AS Company,
	|			RoomSalesTotals.Hotel AS Hotel,
	|			RoomSalesTotals.ReportingCurrency AS ReportingCurrency,
	|			RoomSalesTotals.Room AS Room,
	|			RoomSalesTotals.RoomType AS RoomType,
	|			RoomSalesTotals.RoomRate AS RoomRate,
	|			RoomSalesTotals.AccommodationType AS AccommodationType,
	|			RoomSalesTotals.ClientType AS ClientType,
	|			RoomSalesTotals.MarketingCode AS MarketingCode,
	|			RoomSalesTotals.SourceOfBusiness AS SourceOfBusiness,
	|			RoomSalesTotals.Service AS Service,
	|			RoomSalesTotals.CalendarDayType AS CalendarDayType,
	|			RoomSalesTotals.PriceTag AS PriceTag,
	|			RoomSalesTotals.AccountingDate AS AccountingDate,
	|			RoomSalesTotals.ParentDoc AS ParentDoc,
	|			RoomSalesTotals.ParentDoc.RoomQuota AS RoomQuota,
	|			RoomSalesTotals.GuestGroup AS GuestGroup,
	|			RoomSalesTotals.Customer AS Customer,
	|			RoomSalesTotals.Contract AS Contract,
	|			RoomSalesTotals.Agent AS Agent,
	|			RoomSalesTotals.Client AS Client,
	|			RoomSalesTotals.Resource AS Resource,
	|			RoomSalesTotals.Folio AS Folio,
	|			RoomSalesTotals.Price AS Price,
	|			RoomSalesTotals.ResourceType AS ResourceType,
	|			RoomSalesTotals.TripPurpose AS TripPurpose,
	|			RoomSalesTotals.HotelProduct AS HotelProduct,
	|			RoomSalesTotals.Author AS Author,
	|			RoomSalesTotals.Discount AS Discount,
	|			RoomSalesTotals.DiscountType AS DiscountType,
	|			RoomSalesTotals.DiscountCard AS DiscountCard,
	|			RoomSalesTotals.AgentCommission AS AgentCommission,
	|			RoomSalesTotals.AgentCommissionType AS AgentCommissionType,
	|			RoomSalesTotals.PaymentMethod AS PaymentMethod,
	|			RoomSalesTotals.VATRate AS VATRate,
	|			RoomSalesTotals.Sales AS SalesTurnover,
	|			RoomSalesTotals.RoomRevenue AS RoomRevenueTurnover,
	|			RoomSalesTotals.ExtraBedRevenue AS ExtraBedRevenueTurnover,
	|			RoomSalesTotals.SalesWithoutVAT AS SalesWithoutVATTurnover,
	|			RoomSalesTotals.RoomRevenueWithoutVAT AS RoomRevenueWithoutVATTurnover,
	|			RoomSalesTotals.ExtraBedRevenueWithoutVAT AS ExtraBedRevenueWithoutVATTurnover,
	|			RoomSalesTotals.CommissionSum AS CommissionSumTurnover,
	|			RoomSalesTotals.CommissionSumWithoutVAT AS CommissionSumWithoutVATTurnover,
	|			RoomSalesTotals.DiscountSum AS DiscountSumTurnover,
	|			RoomSalesTotals.DiscountSumWithoutVAT AS DiscountSumWithoutVATTurnover,
	|			RoomSalesTotals.RoomsRented AS RoomsRentedTurnover,
	|			RoomSalesTotals.BedsRented AS BedsRentedTurnover,
	|			RoomSalesTotals.AdditionalBedsRented AS AdditionalBedsRentedTurnover,
	|			RoomSalesTotals.GuestsCheckedIn AS GuestsCheckedInTurnover,
	|			RoomSalesTotals.RoomsCheckedIn AS RoomsCheckedInTurnover,
	|			RoomSalesTotals.BedsCheckedIn AS BedsCheckedInTurnover,
	|			RoomSalesTotals.AdditionalBedsCheckedIn AS AdditionalBedsCheckedInTurnover,
	|			RoomSalesTotals.BookingWindow AS BookingWindowTurnover,
	|			RoomSalesTotals.Quantity AS Counter,
	|			RoomSalesTotals.GuestDays AS GuestDaysTurnover,
	|			1 AS NumberOfDetailedRows,
	|			RoomSalesTotals.ServiceDate AS ServiceDate
	|		FROM
	|			AccumulationRegister.Sales AS RoomSalesTotals
	|		WHERE
	|			RoomSalesTotals.Period >= &qPeriodFrom
	|			AND RoomSalesTotals.Period <= &qPeriodTo
	|			AND &qUsePerMonthStats
	|			AND (&qHideCorrections
	|					OR NOT &qHideCorrections
	|						AND NOT RoomSalesTotals.IsCorrection)
	|			AND &qUsePerRoomTypeStats
	|			AND RoomSalesTotals.Hotel IN HIERARCHY(&qHotel)
	|			AND (RoomSalesTotals.Room IN HIERARCHY (&qRoom)
	|					OR &qIsEmptyRoom)
	|			AND (NOT RoomSalesTotals.Room IN (&qRooms2IgnoreList)
	|					OR &qRooms2IgnoreListIsEmpty)
	|			AND (RoomSalesTotals.RoomType IN HIERARCHY (&qRoomType)
	|					OR &qIsEmptyRoomType)
	|			AND (RoomSalesTotals.Service IN HIERARCHY (&qService)
	|					OR &qIsEmptyService)
	|			AND (RoomSalesTotals.Service IN (&qServicesList)
	|					OR NOT &qUseServicesList)
	|			AND (NOT &qWithAllotments
	|					OR &qWithAllotments
	|						AND NOT ISNULL(RoomSalesTotals.ParentDoc.RoomQuota.IsCommitment, FALSE))
	|			AND (NOT &qFilterByReservationCreationDate
	|						AND NOT &qLimitByTodaysDate
	|					OR NOT &qFilterByReservationCreationDate
	|						AND &qLimitByTodaysDate
	|						AND NOT &qByGroupCreationDate
	|						AND (RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesTotals.ParentDoc.Date <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(RoomSalesTotals.AccountingDate, YEAR), DAY, &qTodaysDay), DAY)
	|							OR NOT RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesTotals.ParentDoc.Reservation.Date <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(RoomSalesTotals.AccountingDate, YEAR), DAY, &qTodaysDay), DAY))
	|					OR NOT &qFilterByReservationCreationDate
	|						AND &qLimitByTodaysDate
	|						AND &qByGroupCreationDate
	|						AND NOT RoomSalesTotals.GuestGroup.CreateDate IS NULL
	|						AND RoomSalesTotals.GuestGroup.CreateDate <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(RoomSalesTotals.AccountingDate, YEAR), DAY, &qTodaysDay), DAY)
	|					OR &qFilterByReservationCreationDate
	|						AND NOT &qNoYear
	|						AND NOT &qByGroupCreationDate
	|						AND (RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesTotals.ParentDoc.Date >= &qDateFrom
	|							OR NOT RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesTotals.ParentDoc.Reservation.Date >= &qDateFrom)
	|						AND (&qDateToIsEmpty
	|							OR RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesTotals.ParentDoc.Date <= &qDateTo
	|							OR NOT RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesTotals.ParentDoc.Reservation.Date <= &qDateTo)
	|					OR &qFilterByReservationCreationDate
	|						AND NOT &qNoYear
	|						AND &qByGroupCreationDate
	|						AND NOT RoomSalesTotals.GuestGroup.CreateDate IS NULL
	|						AND RoomSalesTotals.GuestGroup.CreateDate >= &qDateFrom
	|						AND (&qDateToIsEmpty
	|							OR RoomSalesTotals.GuestGroup.CreateDate <= &qDateTo)
	|					OR &qFilterByReservationCreationDate
	|						AND &qNoYear
	|						AND NOT &qByGroupCreationDate
	|						AND CASE
	|							WHEN &qShiftFrom = 1
	|									AND RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Date, YEAR, 2 - YEAR(RoomSalesTotals.ParentDoc.Date)) <= &qDateTo
	|								THEN TRUE
	|							WHEN &qShiftFrom = 1
	|									AND RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Date, YEAR, 1 - YEAR(RoomSalesTotals.ParentDoc.Date)) >= &qDateFrom
	|								THEN TRUE
	|							WHEN &qShiftFrom = 2
	|									AND RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Date, YEAR, 2 - YEAR(RoomSalesTotals.ParentDoc.Date)) >= &qDateFrom
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Date, YEAR, 2 - YEAR(RoomSalesTotals.ParentDoc.Date)) <= &qDateTo
	|								THEN TRUE
	|							WHEN &qShiftFrom = 1
	|									AND NOT RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Reservation.Date, YEAR, 2 - YEAR(RoomSalesTotals.ParentDoc.Reservation.Date)) <= &qDateTo
	|								THEN TRUE
	|							WHEN &qShiftFrom = 1
	|									AND NOT RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Reservation.Date, YEAR, 1 - YEAR(RoomSalesTotals.ParentDoc.Reservation.Date)) >= &qDateFrom
	|								THEN TRUE
	|							WHEN &qShiftFrom = 2
	|									AND NOT RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Reservation.Date, YEAR, 2 - YEAR(RoomSalesTotals.ParentDoc.Reservation.Date)) >= &qDateFrom
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Reservation.Date, YEAR, 2 - YEAR(RoomSalesTotals.ParentDoc.Reservation.Date)) <= &qDateTo
	|								THEN TRUE
	|							ELSE FALSE
	|						END
	|					OR &qFilterByReservationCreationDate
	|						AND &qNoYear
	|						AND &qByGroupCreationDate
	|						AND NOT RoomSalesTotals.GuestGroup.CreateDate IS NULL
	|						AND CASE
	|							WHEN &qShiftFrom = 1
	|									AND DATEADD(RoomSalesTotals.GuestGroup.CreateDate, YEAR, 2 - YEAR(RoomSalesTotals.GuestGroup.CreateDate)) <= &qDateTo
	|								THEN TRUE
	|							WHEN &qShiftFrom = 1
	|									AND DATEADD(RoomSalesTotals.GuestGroup.CreateDate, YEAR, 1 - YEAR(RoomSalesTotals.GuestGroup.CreateDate)) >= &qDateFrom
	|								THEN TRUE
	|							WHEN &qShiftFrom = 2
	|									AND DATEADD(RoomSalesTotals.GuestGroup.CreateDate, YEAR, 2 - YEAR(RoomSalesTotals.GuestGroup.CreateDate)) >= &qDateFrom
	|									AND DATEADD(RoomSalesTotals.GuestGroup.CreateDate, YEAR, 2 - YEAR(RoomSalesTotals.GuestGroup.CreateDate)) <= &qDateTo
	|								THEN TRUE
	|							ELSE FALSE
	|						END)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			BEGINOFPERIOD(RoomSalesForecastTotals.Period, MONTH),
	|			RoomSalesForecastTotals.Company,
	|			RoomSalesForecastTotals.Hotel,
	|			RoomSalesForecastTotals.ReportingCurrency,
	|			RoomSalesForecastTotals.Room,
	|			RoomSalesForecastTotals.RoomType,
	|			RoomSalesForecastTotals.RoomRate,
	|			RoomSalesForecastTotals.AccommodationType,
	|			RoomSalesForecastTotals.ClientType,
	|			RoomSalesForecastTotals.MarketingCode,
	|			RoomSalesForecastTotals.SourceOfBusiness,
	|			RoomSalesForecastTotals.Service,
	|			RoomSalesForecastTotals.CalendarDayType,
	|			RoomSalesForecastTotals.PriceTag,
	|			RoomSalesForecastTotals.AccountingDate,
	|			RoomSalesForecastTotals.ParentDoc,
	|			RoomSalesForecastTotals.ParentDoc.RoomQuota,
	|			RoomSalesForecastTotals.GuestGroup,
	|			RoomSalesForecastTotals.Customer,
	|			RoomSalesForecastTotals.Contract,
	|			RoomSalesForecastTotals.Agent,
	|			RoomSalesForecastTotals.Client,
	|			RoomSalesForecastTotals.Resource,
	|			RoomSalesForecastTotals.Folio,
	|			RoomSalesForecastTotals.Price,
	|			RoomSalesForecastTotals.ResourceType,
	|			RoomSalesForecastTotals.TripPurpose,
	|			RoomSalesForecastTotals.HotelProduct,
	|			RoomSalesForecastTotals.Author,
	|			RoomSalesForecastTotals.Discount,
	|			RoomSalesForecastTotals.DiscountType,
	|			RoomSalesForecastTotals.DiscountCard,
	|			RoomSalesForecastTotals.AgentCommission,
	|			RoomSalesForecastTotals.AgentCommissionType,
	|			RoomSalesForecastTotals.PaymentMethod,
	|			RoomSalesForecastTotals.VATRate,
	|			RoomSalesForecastTotals.Sales,
	|			RoomSalesForecastTotals.RoomRevenue,
	|			RoomSalesForecastTotals.ExtraBedRevenue,
	|			RoomSalesForecastTotals.SalesWithoutVAT,
	|			RoomSalesForecastTotals.RoomRevenueWithoutVAT,
	|			RoomSalesForecastTotals.ExtraBedRevenueWithoutVAT,
	|			RoomSalesForecastTotals.CommissionSum,
	|			RoomSalesForecastTotals.CommissionSumWithoutVAT,
	|			RoomSalesForecastTotals.DiscountSum,
	|			RoomSalesForecastTotals.DiscountSumWithoutVAT,
	|			RoomSalesForecastTotals.RoomsRented,
	|			RoomSalesForecastTotals.BedsRented,
	|			RoomSalesForecastTotals.AdditionalBedsRented,
	|			RoomSalesForecastTotals.GuestsCheckedIn,
	|			RoomSalesForecastTotals.RoomsCheckedIn,
	|			RoomSalesForecastTotals.BedsCheckedIn,
	|			RoomSalesForecastTotals.AdditionalBedsCheckedIn,
	|			RoomSalesForecastTotals.BookingWindow,
	|			RoomSalesForecastTotals.Quantity,
	|			RoomSalesForecastTotals.GuestDays,
	|			1,
	|			RoomSalesForecastTotals.ServiceDate
	|		FROM
	|			AccumulationRegister.SalesForecast AS RoomSalesForecastTotals
	|		WHERE
	|			RoomSalesForecastTotals.Period >= &qForecastPeriodFrom
	|			AND RoomSalesForecastTotals.Period <= &qForecastPeriodTo
	|			AND &qUsePerMonthStats
	|			AND &qUsePerRoomTypeStats
	|			AND &qUseForecast
	|			AND RoomSalesForecastTotals.Hotel IN HIERARCHY(&qHotel)
	|			AND (RoomSalesForecastTotals.Room IN HIERARCHY (&qRoom)
	|					OR &qIsEmptyRoom)
	|			AND (NOT RoomSalesForecastTotals.Room IN (&qRooms2IgnoreList)
	|					OR &qRooms2IgnoreListIsEmpty)
	|			AND (RoomSalesForecastTotals.RoomType IN HIERARCHY (&qRoomType)
	|					OR &qIsEmptyRoomType)
	|			AND (RoomSalesForecastTotals.Service IN HIERARCHY (&qService)
	|					OR &qIsEmptyService)
	|			AND (RoomSalesForecastTotals.Service IN (&qServicesList)
	|					OR NOT &qUseServicesList)
	|			AND (NOT &qWithAllotments
	|					OR &qWithAllotments
	|						AND NOT ISNULL(RoomSalesForecastTotals.ParentDoc.RoomQuota.IsCommitment, FALSE))
	|			AND (NOT &qFilterByReservationCreationDate
	|						AND NOT &qLimitByTodaysDate
	|					OR NOT &qFilterByReservationCreationDate
	|						AND &qLimitByTodaysDate
	|						AND NOT &qByGroupCreationDate
	|						AND (RoomSalesForecastTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesForecastTotals.ParentDoc.Date <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(RoomSalesForecastTotals.AccountingDate, YEAR), DAY, &qTodaysDay), DAY)
	|							OR NOT RoomSalesForecastTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesForecastTotals.ParentDoc.Reservation.Date <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(RoomSalesForecastTotals.AccountingDate, YEAR), DAY, &qTodaysDay), DAY))
	|					OR NOT &qFilterByReservationCreationDate
	|						AND &qLimitByTodaysDate
	|						AND &qByGroupCreationDate
	|						AND NOT RoomSalesForecastTotals.GuestGroup.CreateDate IS NULL
	|						AND RoomSalesForecastTotals.GuestGroup.CreateDate <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(RoomSalesForecastTotals.AccountingDate, YEAR), DAY, &qTodaysDay), DAY)
	|					OR &qFilterByReservationCreationDate
	|						AND NOT &qNoYear
	|						AND NOT &qByGroupCreationDate
	|						AND RoomSalesForecastTotals.ParentDoc.Date >= &qDateFrom
	|						AND (RoomSalesForecastTotals.ParentDoc.Date <= &qDateTo
	|							OR &qDateToIsEmpty)
	|					OR &qFilterByReservationCreationDate
	|						AND NOT &qNoYear
	|						AND &qByGroupCreationDate
	|						AND NOT RoomSalesForecastTotals.GuestGroup.CreateDate IS NULL
	|						AND RoomSalesForecastTotals.GuestGroup.CreateDate >= &qDateFrom
	|						AND (&qDateToIsEmpty
	|							OR RoomSalesForecastTotals.GuestGroup.CreateDate <= &qDateTo)
	|					OR &qFilterByReservationCreationDate
	|						AND &qNoYear
	|						AND NOT &qByGroupCreationDate
	|						AND NOT RoomSalesForecastTotals.ParentDoc.Date IS NULL
	|						AND CASE
	|							WHEN &qShiftFrom = 1
	|									AND DATEADD(RoomSalesForecastTotals.ParentDoc.Date, YEAR, 2 - YEAR(RoomSalesForecastTotals.ParentDoc.Date)) <= &qDateTo
	|								THEN TRUE
	|							WHEN &qShiftFrom = 1
	|									AND DATEADD(RoomSalesForecastTotals.ParentDoc.Date, YEAR, 1 - YEAR(RoomSalesForecastTotals.ParentDoc.Date)) >= &qDateFrom
	|								THEN TRUE
	|							WHEN &qShiftFrom = 2
	|									AND DATEADD(RoomSalesForecastTotals.ParentDoc.Date, YEAR, 2 - YEAR(RoomSalesForecastTotals.ParentDoc.Date)) >= &qDateFrom
	|									AND DATEADD(RoomSalesForecastTotals.ParentDoc.Date, YEAR, 2 - YEAR(RoomSalesForecastTotals.ParentDoc.Date)) <= &qDateTo
	|								THEN TRUE
	|							ELSE FALSE
	|						END
	|					OR &qFilterByReservationCreationDate
	|						AND &qNoYear
	|						AND &qByGroupCreationDate
	|						AND NOT RoomSalesForecastTotals.GuestGroup.CreateDate IS NULL
	|						AND CASE
	|							WHEN &qShiftFrom = 1
	|									AND DATEADD(RoomSalesForecastTotals.GuestGroup.CreateDate, YEAR, 2 - YEAR(RoomSalesForecastTotals.GuestGroup.CreateDate)) <= &qDateTo
	|								THEN TRUE
	|							WHEN &qShiftFrom = 1
	|									AND DATEADD(RoomSalesForecastTotals.GuestGroup.CreateDate, YEAR, 1 - YEAR(RoomSalesForecastTotals.GuestGroup.CreateDate)) >= &qDateFrom
	|								THEN TRUE
	|							WHEN &qShiftFrom = 2
	|									AND DATEADD(RoomSalesForecastTotals.GuestGroup.CreateDate, YEAR, 2 - YEAR(RoomSalesForecastTotals.GuestGroup.CreateDate)) >= &qDateFrom
	|									AND DATEADD(RoomSalesForecastTotals.GuestGroup.CreateDate, YEAR, 2 - YEAR(RoomSalesForecastTotals.GuestGroup.CreateDate)) <= &qDateTo
	|								THEN TRUE
	|							ELSE FALSE
	|						END)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			RoomTypesListPerMonth.Period,
	|			NULL,
	|			RoomTypesListPerMonth.Hotel,
	|			RoomTypesListPerMonth.Hotel.ReportingCurrency,
	|			NULL,
	|			RoomTypesListPerMonth.RoomType,
	|			NULL,
	|			NULL,
	|			NULL,
	|			VALUE(Catalog.MarketingCodes.EmptyRef),
	|			VALUE(Catalog.SourcesOfBusiness.EmptyRef),
	|			NULL,
	|			NULL,
	|			NULL,
	|			RoomTypesListPerMonth.Period,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
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
	|			1,
	|			NULL
	|		FROM
	|			HotelInventoryTotalsPerMonth AS RoomTypesListPerMonth
	|		WHERE
	|			&qUsePerMonthStats
	|			AND &qUsePerRoomTypeStats
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			RoomQuotaSales.Period,
	|			RoomQuotaSales.Hotel.Company,
	|			RoomQuotaSales.Hotel,
	|			RoomQuotaSales.Hotel.ReportingCurrency,
	|			NULL,
	|			RoomQuotaSales.RoomType,
	|			RoomQuotaSales.RoomQuota.RoomRate,
	|			NULL,
	|			RoomQuotaSales.RoomQuota.ClientType,
	|			RoomQuotaSales.RoomQuota.MarketingCode,
	|			RoomQuotaSales.RoomQuota.SourceOfBusiness,
	|			RoomQuotaSales.Service,
	|			RoomQuotaSales.CalendarDayType,
	|			NULL,
	|			RoomQuotaSales.Period,
	|			NULL,
	|			RoomQuotaSales.RoomQuota,
	|			NULL,
	|			RoomQuotaSales.RoomQuota.Customer,
	|			RoomQuotaSales.RoomQuota.Contract,
	|			RoomQuotaSales.RoomQuota.Agent,
	|			NULL,
	|			NULL,
	|			NULL,
	|			RoomQuotaSales.AllotmentPrice,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			RoomQuotaSales.RoomQuota.RoomRate.Discount,
	|			RoomQuotaSales.RoomQuota.RoomRate.DiscountType,
	|			NULL,
	|			RoomQuotaSales.RoomQuota.Agent.AgentCommission,
	|			RoomQuotaSales.RoomQuota.Agent.AgentCommissionType,
	|			RoomQuotaSales.RoomQuota.Customer.PlannedPaymentMethod,
	|			RoomQuotaSales.VATRate,
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
	|			RoomQuotaSales.Counter,
	|			0,
	|			1,
	|			NULL
	|		FROM
	|			RoomQuotaSales AS RoomQuotaSales
	|		WHERE
	|			&qWithAllotments) AS RoomSales) AS RoomSalesPerRoomTypePerMonth
	|
	|GROUP BY
	|	RoomSalesPerRoomTypePerMonth.Hotel,
	|	RoomSalesPerRoomTypePerMonth.RoomType,
	|	RoomSalesPerRoomTypePerMonth.Period,
	|	RoomSalesPerRoomTypePerMonth.ServiceDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomSalesPerRoomTypePerPeriod.Hotel AS Hotel,
	|	RoomSalesPerRoomTypePerPeriod.RoomType AS RoomType,
	|	SUM(RoomSalesPerRoomTypePerPeriod.SalesTurnover) AS SalesTurnover,
	|	SUM(RoomSalesPerRoomTypePerPeriod.RoomRevenueTurnover) AS RoomRevenueTurnover,
	|	SUM(RoomSalesPerRoomTypePerPeriod.ExtraBedRevenueTurnover) AS ExtraBedRevenueTurnover,
	|	SUM(RoomSalesPerRoomTypePerPeriod.SalesWithoutVATTurnover) AS SalesWithoutVATTurnover,
	|	SUM(RoomSalesPerRoomTypePerPeriod.RoomRevenueWithoutVATTurnover) AS RoomRevenueWithoutVATTurnover,
	|	SUM(RoomSalesPerRoomTypePerPeriod.ExtraBedRevenueWithoutVATTurnover) AS ExtraBedRevenueWithoutVATTurnover,
	|	SUM(RoomSalesPerRoomTypePerPeriod.CommissionSumTurnover) AS CommissionSumTurnover,
	|	SUM(RoomSalesPerRoomTypePerPeriod.CommissionSumWithoutVATTurnover) AS CommissionSumWithoutVATTurnover,
	|	SUM(RoomSalesPerRoomTypePerPeriod.DiscountSumTurnover) AS DiscountSumTurnover,
	|	SUM(RoomSalesPerRoomTypePerPeriod.DiscountSumWithoutVATTurnover) AS DiscountSumWithoutVATTurnover,
	|	SUM(RoomSalesPerRoomTypePerPeriod.RoomsRentedTurnover) AS RoomsRentedTurnover,
	|	SUM(RoomSalesPerRoomTypePerPeriod.BedsRentedTurnover) AS BedsRentedTurnover,
	|	SUM(RoomSalesPerRoomTypePerPeriod.AdditionalBedsRentedTurnover) AS AdditionalBedsRentedTurnover,
	|	SUM(RoomSalesPerRoomTypePerPeriod.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover,
	|	SUM(RoomSalesPerRoomTypePerPeriod.RoomsCheckedInTurnover) AS RoomsCheckedInTurnover,
	|	SUM(RoomSalesPerRoomTypePerPeriod.BedsCheckedInTurnover) AS BedsCheckedInTurnover,
	|	SUM(RoomSalesPerRoomTypePerPeriod.AdditionalBedsCheckedInTurnover) AS AdditionalBedsCheckedInTurnover,
	|	SUM(RoomSalesPerRoomTypePerPeriod.BookingWindowTurnover) AS BookingWindowTurnover,
	|	SUM(RoomSalesPerRoomTypePerPeriod.Counter) AS Counter,
	|	SUM(RoomSalesPerRoomTypePerPeriod.GuestDaysTurnover) AS GuestDaysTurnover,
	|	SUM(RoomSalesPerRoomTypePerPeriod.NumberOfDetailedRows) AS NumberOfDetailedRows,
	|	RoomSalesPerRoomTypePerPeriod.ServiceDate AS ServiceDate
	|INTO RoomSalesPerRoomTypePerPeriod
	|FROM
	|	(SELECT
	|		RoomSales.Hotel AS Hotel,
	|		RoomSales.RoomType AS RoomType,
	|		RoomSales.SalesTurnover AS SalesTurnover,
	|		RoomSales.RoomRevenueTurnover AS RoomRevenueTurnover,
	|		RoomSales.ExtraBedRevenueTurnover AS ExtraBedRevenueTurnover,
	|		RoomSales.SalesWithoutVATTurnover AS SalesWithoutVATTurnover,
	|		RoomSales.RoomRevenueWithoutVATTurnover AS RoomRevenueWithoutVATTurnover,
	|		RoomSales.ExtraBedRevenueWithoutVATTurnover AS ExtraBedRevenueWithoutVATTurnover,
	|		RoomSales.CommissionSumTurnover AS CommissionSumTurnover,
	|		RoomSales.CommissionSumWithoutVATTurnover AS CommissionSumWithoutVATTurnover,
	|		RoomSales.DiscountSumTurnover AS DiscountSumTurnover,
	|		RoomSales.DiscountSumWithoutVATTurnover AS DiscountSumWithoutVATTurnover,
	|		RoomSales.RoomsRentedTurnover AS RoomsRentedTurnover,
	|		RoomSales.BedsRentedTurnover AS BedsRentedTurnover,
	|		RoomSales.AdditionalBedsRentedTurnover AS AdditionalBedsRentedTurnover,
	|		RoomSales.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
	|		RoomSales.RoomsCheckedInTurnover AS RoomsCheckedInTurnover,
	|		RoomSales.BedsCheckedInTurnover AS BedsCheckedInTurnover,
	|		RoomSales.AdditionalBedsCheckedInTurnover AS AdditionalBedsCheckedInTurnover,
	|		RoomSales.BookingWindowTurnover AS BookingWindowTurnover,
	|		RoomSales.Counter AS Counter,
	|		RoomSales.GuestDaysTurnover AS GuestDaysTurnover,
	|		RoomSales.NumberOfDetailedRows AS NumberOfDetailedRows,
	|		RoomSales.ServiceDate AS ServiceDate
	|	FROM
	|		(SELECT
	|			BEGINOFPERIOD(RoomSalesTotals.Period, DAY) AS Period,
	|			RoomSalesTotals.Company AS Company,
	|			RoomSalesTotals.Hotel AS Hotel,
	|			RoomSalesTotals.ReportingCurrency AS ReportingCurrency,
	|			RoomSalesTotals.Room AS Room,
	|			RoomSalesTotals.RoomType AS RoomType,
	|			RoomSalesTotals.RoomRate AS RoomRate,
	|			RoomSalesTotals.AccommodationType AS AccommodationType,
	|			RoomSalesTotals.ClientType AS ClientType,
	|			RoomSalesTotals.MarketingCode AS MarketingCode,
	|			RoomSalesTotals.SourceOfBusiness AS SourceOfBusiness,
	|			RoomSalesTotals.Service AS Service,
	|			RoomSalesTotals.CalendarDayType AS CalendarDayType,
	|			RoomSalesTotals.PriceTag AS PriceTag,
	|			RoomSalesTotals.AccountingDate AS AccountingDate,
	|			RoomSalesTotals.ParentDoc AS ParentDoc,
	|			RoomSalesTotals.ParentDoc.RoomQuota AS RoomQuota,
	|			RoomSalesTotals.GuestGroup AS GuestGroup,
	|			RoomSalesTotals.Customer AS Customer,
	|			RoomSalesTotals.Contract AS Contract,
	|			RoomSalesTotals.Agent AS Agent,
	|			RoomSalesTotals.Client AS Client,
	|			RoomSalesTotals.Resource AS Resource,
	|			RoomSalesTotals.Folio AS Folio,
	|			RoomSalesTotals.Price AS Price,
	|			RoomSalesTotals.ResourceType AS ResourceType,
	|			RoomSalesTotals.TripPurpose AS TripPurpose,
	|			RoomSalesTotals.HotelProduct AS HotelProduct,
	|			RoomSalesTotals.Author AS Author,
	|			RoomSalesTotals.Discount AS Discount,
	|			RoomSalesTotals.DiscountType AS DiscountType,
	|			RoomSalesTotals.DiscountCard AS DiscountCard,
	|			RoomSalesTotals.AgentCommission AS AgentCommission,
	|			RoomSalesTotals.AgentCommissionType AS AgentCommissionType,
	|			RoomSalesTotals.PaymentMethod AS PaymentMethod,
	|			RoomSalesTotals.VATRate AS VATRate,
	|			RoomSalesTotals.Sales AS SalesTurnover,
	|			RoomSalesTotals.RoomRevenue AS RoomRevenueTurnover,
	|			RoomSalesTotals.ExtraBedRevenue AS ExtraBedRevenueTurnover,
	|			RoomSalesTotals.SalesWithoutVAT AS SalesWithoutVATTurnover,
	|			RoomSalesTotals.RoomRevenueWithoutVAT AS RoomRevenueWithoutVATTurnover,
	|			RoomSalesTotals.ExtraBedRevenueWithoutVAT AS ExtraBedRevenueWithoutVATTurnover,
	|			RoomSalesTotals.CommissionSum AS CommissionSumTurnover,
	|			RoomSalesTotals.CommissionSumWithoutVAT AS CommissionSumWithoutVATTurnover,
	|			RoomSalesTotals.DiscountSum AS DiscountSumTurnover,
	|			RoomSalesTotals.DiscountSumWithoutVAT AS DiscountSumWithoutVATTurnover,
	|			RoomSalesTotals.RoomsRented AS RoomsRentedTurnover,
	|			RoomSalesTotals.BedsRented AS BedsRentedTurnover,
	|			RoomSalesTotals.AdditionalBedsRented AS AdditionalBedsRentedTurnover,
	|			RoomSalesTotals.GuestsCheckedIn AS GuestsCheckedInTurnover,
	|			RoomSalesTotals.RoomsCheckedIn AS RoomsCheckedInTurnover,
	|			RoomSalesTotals.BedsCheckedIn AS BedsCheckedInTurnover,
	|			RoomSalesTotals.AdditionalBedsCheckedIn AS AdditionalBedsCheckedInTurnover,
	|			RoomSalesTotals.BookingWindow AS BookingWindowTurnover,
	|			RoomSalesTotals.Quantity AS Counter,
	|			RoomSalesTotals.GuestDays AS GuestDaysTurnover,
	|			1 AS NumberOfDetailedRows,
	|			RoomSalesTotals.ServiceDate AS ServiceDate
	|		FROM
	|			AccumulationRegister.Sales AS RoomSalesTotals
	|		WHERE
	|			RoomSalesTotals.Period >= &qPeriodFrom
	|			AND RoomSalesTotals.Period <= &qPeriodTo
	|			AND &qUsePerPeriodStats
	|			AND (&qHideCorrections
	|					OR NOT &qHideCorrections
	|						AND NOT RoomSalesTotals.IsCorrection)
	|			AND &qUsePerRoomTypeStats
	|			AND RoomSalesTotals.Hotel IN HIERARCHY(&qHotel)
	|			AND (RoomSalesTotals.Room IN HIERARCHY (&qRoom)
	|					OR &qIsEmptyRoom)
	|			AND (NOT RoomSalesTotals.Room IN (&qRooms2IgnoreList)
	|					OR &qRooms2IgnoreListIsEmpty)
	|			AND (RoomSalesTotals.RoomType IN HIERARCHY (&qRoomType)
	|					OR &qIsEmptyRoomType)
	|			AND (RoomSalesTotals.Service IN HIERARCHY (&qService)
	|					OR &qIsEmptyService)
	|			AND (RoomSalesTotals.Service IN (&qServicesList)
	|					OR NOT &qUseServicesList)
	|			AND (NOT &qWithAllotments
	|					OR &qWithAllotments
	|						AND NOT ISNULL(RoomSalesTotals.ParentDoc.RoomQuota.IsCommitment, FALSE))
	|			AND (NOT &qFilterByReservationCreationDate
	|						AND NOT &qLimitByTodaysDate
	|					OR NOT &qFilterByReservationCreationDate
	|						AND &qLimitByTodaysDate
	|						AND NOT &qByGroupCreationDate
	|						AND (RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesTotals.ParentDoc.Date <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(RoomSalesTotals.AccountingDate, YEAR), DAY, &qTodaysDay), DAY)
	|							OR NOT RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesTotals.ParentDoc.Reservation.Date <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(RoomSalesTotals.AccountingDate, YEAR), DAY, &qTodaysDay), DAY))
	|					OR NOT &qFilterByReservationCreationDate
	|						AND &qLimitByTodaysDate
	|						AND &qByGroupCreationDate
	|						AND NOT RoomSalesTotals.GuestGroup.CreateDate IS NULL
	|						AND RoomSalesTotals.GuestGroup.CreateDate <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(RoomSalesTotals.AccountingDate, YEAR), DAY, &qTodaysDay), DAY)
	|					OR &qFilterByReservationCreationDate
	|						AND NOT &qNoYear
	|						AND NOT &qByGroupCreationDate
	|						AND (RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesTotals.ParentDoc.Date >= &qDateFrom
	|							OR NOT RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesTotals.ParentDoc.Reservation.Date >= &qDateFrom)
	|						AND (&qDateToIsEmpty
	|							OR RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesTotals.ParentDoc.Date <= &qDateTo
	|							OR NOT RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesTotals.ParentDoc.Reservation.Date <= &qDateTo)
	|					OR &qFilterByReservationCreationDate
	|						AND NOT &qNoYear
	|						AND &qByGroupCreationDate
	|						AND NOT RoomSalesTotals.GuestGroup.CreateDate IS NULL
	|						AND RoomSalesTotals.GuestGroup.CreateDate >= &qDateFrom
	|						AND (&qDateToIsEmpty
	|							OR RoomSalesTotals.GuestGroup.CreateDate <= &qDateTo)
	|					OR &qFilterByReservationCreationDate
	|						AND &qNoYear
	|						AND NOT &qByGroupCreationDate
	|						AND CASE
	|							WHEN &qShiftFrom = 1
	|									AND RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Date, YEAR, 2 - YEAR(RoomSalesTotals.ParentDoc.Date)) <= &qDateTo
	|								THEN TRUE
	|							WHEN &qShiftFrom = 1
	|									AND RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Date, YEAR, 1 - YEAR(RoomSalesTotals.ParentDoc.Date)) >= &qDateFrom
	|								THEN TRUE
	|							WHEN &qShiftFrom = 2
	|									AND RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Date, YEAR, 2 - YEAR(RoomSalesTotals.ParentDoc.Date)) >= &qDateFrom
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Date, YEAR, 2 - YEAR(RoomSalesTotals.ParentDoc.Date)) <= &qDateTo
	|								THEN TRUE
	|							WHEN &qShiftFrom = 1
	|									AND NOT RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Reservation.Date, YEAR, 2 - YEAR(RoomSalesTotals.ParentDoc.Reservation.Date)) <= &qDateTo
	|								THEN TRUE
	|							WHEN &qShiftFrom = 1
	|									AND NOT RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Reservation.Date, YEAR, 1 - YEAR(RoomSalesTotals.ParentDoc.Reservation.Date)) >= &qDateFrom
	|								THEN TRUE
	|							WHEN &qShiftFrom = 2
	|									AND NOT RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Reservation.Date, YEAR, 2 - YEAR(RoomSalesTotals.ParentDoc.Reservation.Date)) >= &qDateFrom
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Reservation.Date, YEAR, 2 - YEAR(RoomSalesTotals.ParentDoc.Reservation.Date)) <= &qDateTo
	|								THEN TRUE
	|							ELSE FALSE
	|						END
	|					OR &qFilterByReservationCreationDate
	|						AND &qNoYear
	|						AND &qByGroupCreationDate
	|						AND NOT RoomSalesTotals.GuestGroup.CreateDate IS NULL
	|						AND CASE
	|							WHEN &qShiftFrom = 1
	|									AND DATEADD(RoomSalesTotals.GuestGroup.CreateDate, YEAR, 2 - YEAR(RoomSalesTotals.GuestGroup.CreateDate)) <= &qDateTo
	|								THEN TRUE
	|							WHEN &qShiftFrom = 1
	|									AND DATEADD(RoomSalesTotals.GuestGroup.CreateDate, YEAR, 1 - YEAR(RoomSalesTotals.GuestGroup.CreateDate)) >= &qDateFrom
	|								THEN TRUE
	|							WHEN &qShiftFrom = 2
	|									AND DATEADD(RoomSalesTotals.GuestGroup.CreateDate, YEAR, 2 - YEAR(RoomSalesTotals.GuestGroup.CreateDate)) >= &qDateFrom
	|									AND DATEADD(RoomSalesTotals.GuestGroup.CreateDate, YEAR, 2 - YEAR(RoomSalesTotals.GuestGroup.CreateDate)) <= &qDateTo
	|								THEN TRUE
	|							ELSE FALSE
	|						END)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			BEGINOFPERIOD(RoomSalesForecastTotals.Period, DAY),
	|			RoomSalesForecastTotals.Company,
	|			RoomSalesForecastTotals.Hotel,
	|			RoomSalesForecastTotals.ReportingCurrency,
	|			RoomSalesForecastTotals.Room,
	|			RoomSalesForecastTotals.RoomType,
	|			RoomSalesForecastTotals.RoomRate,
	|			RoomSalesForecastTotals.AccommodationType,
	|			RoomSalesForecastTotals.ClientType,
	|			RoomSalesForecastTotals.MarketingCode,
	|			RoomSalesForecastTotals.SourceOfBusiness,
	|			RoomSalesForecastTotals.Service,
	|			RoomSalesForecastTotals.CalendarDayType,
	|			RoomSalesForecastTotals.PriceTag,
	|			RoomSalesForecastTotals.AccountingDate,
	|			RoomSalesForecastTotals.ParentDoc,
	|			RoomSalesForecastTotals.ParentDoc.RoomQuota,
	|			RoomSalesForecastTotals.GuestGroup,
	|			RoomSalesForecastTotals.Customer,
	|			RoomSalesForecastTotals.Contract,
	|			RoomSalesForecastTotals.Agent,
	|			RoomSalesForecastTotals.Client,
	|			RoomSalesForecastTotals.Resource,
	|			RoomSalesForecastTotals.Folio,
	|			RoomSalesForecastTotals.Price,
	|			RoomSalesForecastTotals.ResourceType,
	|			RoomSalesForecastTotals.TripPurpose,
	|			RoomSalesForecastTotals.HotelProduct,
	|			RoomSalesForecastTotals.Author,
	|			RoomSalesForecastTotals.Discount,
	|			RoomSalesForecastTotals.DiscountType,
	|			RoomSalesForecastTotals.DiscountCard,
	|			RoomSalesForecastTotals.AgentCommission,
	|			RoomSalesForecastTotals.AgentCommissionType,
	|			RoomSalesForecastTotals.PaymentMethod,
	|			RoomSalesForecastTotals.VATRate,
	|			RoomSalesForecastTotals.Sales,
	|			RoomSalesForecastTotals.RoomRevenue,
	|			RoomSalesForecastTotals.ExtraBedRevenue,
	|			RoomSalesForecastTotals.SalesWithoutVAT,
	|			RoomSalesForecastTotals.RoomRevenueWithoutVAT,
	|			RoomSalesForecastTotals.ExtraBedRevenueWithoutVAT,
	|			RoomSalesForecastTotals.CommissionSum,
	|			RoomSalesForecastTotals.CommissionSumWithoutVAT,
	|			RoomSalesForecastTotals.DiscountSum,
	|			RoomSalesForecastTotals.DiscountSumWithoutVAT,
	|			RoomSalesForecastTotals.RoomsRented,
	|			RoomSalesForecastTotals.BedsRented,
	|			RoomSalesForecastTotals.AdditionalBedsRented,
	|			RoomSalesForecastTotals.GuestsCheckedIn,
	|			RoomSalesForecastTotals.RoomsCheckedIn,
	|			RoomSalesForecastTotals.BedsCheckedIn,
	|			RoomSalesForecastTotals.AdditionalBedsCheckedIn,
	|			RoomSalesForecastTotals.BookingWindow,
	|			RoomSalesForecastTotals.Quantity,
	|			RoomSalesForecastTotals.GuestDays,
	|			1,
	|			RoomSalesForecastTotals.ServiceDate
	|		FROM
	|			AccumulationRegister.SalesForecast AS RoomSalesForecastTotals
	|		WHERE
	|			RoomSalesForecastTotals.Period >= &qForecastPeriodFrom
	|			AND RoomSalesForecastTotals.Period <= &qForecastPeriodTo
	|			AND &qUsePerPeriodStats
	|			AND &qUsePerRoomTypeStats
	|			AND &qUseForecast
	|			AND RoomSalesForecastTotals.Hotel IN HIERARCHY(&qHotel)
	|			AND (RoomSalesForecastTotals.Room IN HIERARCHY (&qRoom)
	|					OR &qIsEmptyRoom)
	|			AND (NOT RoomSalesForecastTotals.Room IN (&qRooms2IgnoreList)
	|					OR &qRooms2IgnoreListIsEmpty)
	|			AND (RoomSalesForecastTotals.RoomType IN HIERARCHY (&qRoomType)
	|					OR &qIsEmptyRoomType)
	|			AND (RoomSalesForecastTotals.Service IN HIERARCHY (&qService)
	|					OR &qIsEmptyService)
	|			AND (RoomSalesForecastTotals.Service IN (&qServicesList)
	|					OR NOT &qUseServicesList)
	|			AND (NOT &qWithAllotments
	|					OR &qWithAllotments
	|						AND NOT ISNULL(RoomSalesForecastTotals.ParentDoc.RoomQuota.IsCommitment, FALSE))
	|			AND (NOT &qFilterByReservationCreationDate
	|						AND NOT &qLimitByTodaysDate
	|					OR NOT &qFilterByReservationCreationDate
	|						AND &qLimitByTodaysDate
	|						AND NOT &qByGroupCreationDate
	|						AND (RoomSalesForecastTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesForecastTotals.ParentDoc.Date <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(RoomSalesForecastTotals.AccountingDate, YEAR), DAY, &qTodaysDay), DAY)
	|							OR NOT RoomSalesForecastTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesForecastTotals.ParentDoc.Reservation.Date <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(RoomSalesForecastTotals.AccountingDate, YEAR), DAY, &qTodaysDay), DAY))
	|					OR NOT &qFilterByReservationCreationDate
	|						AND &qLimitByTodaysDate
	|						AND &qByGroupCreationDate
	|						AND NOT RoomSalesForecastTotals.GuestGroup.CreateDate IS NULL
	|						AND RoomSalesForecastTotals.GuestGroup.CreateDate <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(RoomSalesForecastTotals.AccountingDate, YEAR), DAY, &qTodaysDay), DAY)
	|					OR &qFilterByReservationCreationDate
	|						AND NOT &qNoYear
	|						AND NOT &qByGroupCreationDate
	|						AND RoomSalesForecastTotals.ParentDoc.Date >= &qDateFrom
	|						AND (RoomSalesForecastTotals.ParentDoc.Date <= &qDateTo
	|							OR &qDateToIsEmpty)
	|					OR &qFilterByReservationCreationDate
	|						AND NOT &qNoYear
	|						AND &qByGroupCreationDate
	|						AND NOT RoomSalesForecastTotals.GuestGroup.CreateDate IS NULL
	|						AND RoomSalesForecastTotals.GuestGroup.CreateDate >= &qDateFrom
	|						AND (&qDateToIsEmpty
	|							OR RoomSalesForecastTotals.GuestGroup.CreateDate <= &qDateTo)
	|					OR &qFilterByReservationCreationDate
	|						AND &qNoYear
	|						AND NOT &qByGroupCreationDate
	|						AND NOT RoomSalesForecastTotals.ParentDoc.Date IS NULL
	|						AND CASE
	|							WHEN &qShiftFrom = 1
	|									AND DATEADD(RoomSalesForecastTotals.ParentDoc.Date, YEAR, 2 - YEAR(RoomSalesForecastTotals.ParentDoc.Date)) <= &qDateTo
	|								THEN TRUE
	|							WHEN &qShiftFrom = 1
	|									AND DATEADD(RoomSalesForecastTotals.ParentDoc.Date, YEAR, 1 - YEAR(RoomSalesForecastTotals.ParentDoc.Date)) >= &qDateFrom
	|								THEN TRUE
	|							WHEN &qShiftFrom = 2
	|									AND DATEADD(RoomSalesForecastTotals.ParentDoc.Date, YEAR, 2 - YEAR(RoomSalesForecastTotals.ParentDoc.Date)) >= &qDateFrom
	|									AND DATEADD(RoomSalesForecastTotals.ParentDoc.Date, YEAR, 2 - YEAR(RoomSalesForecastTotals.ParentDoc.Date)) <= &qDateTo
	|								THEN TRUE
	|							ELSE FALSE
	|						END
	|					OR &qFilterByReservationCreationDate
	|						AND &qNoYear
	|						AND &qByGroupCreationDate
	|						AND NOT RoomSalesForecastTotals.GuestGroup.CreateDate IS NULL
	|						AND CASE
	|							WHEN &qShiftFrom = 1
	|									AND DATEADD(RoomSalesForecastTotals.GuestGroup.CreateDate, YEAR, 2 - YEAR(RoomSalesForecastTotals.GuestGroup.CreateDate)) <= &qDateTo
	|								THEN TRUE
	|							WHEN &qShiftFrom = 1
	|									AND DATEADD(RoomSalesForecastTotals.GuestGroup.CreateDate, YEAR, 1 - YEAR(RoomSalesForecastTotals.GuestGroup.CreateDate)) >= &qDateFrom
	|								THEN TRUE
	|							WHEN &qShiftFrom = 2
	|									AND DATEADD(RoomSalesForecastTotals.GuestGroup.CreateDate, YEAR, 2 - YEAR(RoomSalesForecastTotals.GuestGroup.CreateDate)) >= &qDateFrom
	|									AND DATEADD(RoomSalesForecastTotals.GuestGroup.CreateDate, YEAR, 2 - YEAR(RoomSalesForecastTotals.GuestGroup.CreateDate)) <= &qDateTo
	|								THEN TRUE
	|							ELSE FALSE
	|						END)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			RoomTypesListPerDay.Period,
	|			NULL,
	|			RoomTypesListPerDay.Hotel,
	|			RoomTypesListPerDay.Hotel.ReportingCurrency,
	|			NULL,
	|			RoomTypesListPerDay.RoomType,
	|			NULL,
	|			NULL,
	|			NULL,
	|			VALUE(Catalog.MarketingCodes.EmptyRef),
	|			VALUE(Catalog.SourcesOfBusiness.EmptyRef),
	|			NULL,
	|			NULL,
	|			NULL,
	|			RoomTypesListPerDay.Period,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
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
	|			1,
	|			NULL
	|		FROM
	|			HotelInventoryTotalsPerDay AS RoomTypesListPerDay
	|		WHERE
	|			&qUsePerPeriodStats
	|			AND &qUsePerRoomTypeStats
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			RoomQuotaSales.Period,
	|			RoomQuotaSales.Hotel.Company,
	|			RoomQuotaSales.Hotel,
	|			RoomQuotaSales.Hotel.ReportingCurrency,
	|			NULL,
	|			RoomQuotaSales.RoomType,
	|			RoomQuotaSales.RoomQuota.RoomRate,
	|			NULL,
	|			RoomQuotaSales.RoomQuota.ClientType,
	|			RoomQuotaSales.RoomQuota.MarketingCode,
	|			RoomQuotaSales.RoomQuota.SourceOfBusiness,
	|			RoomQuotaSales.Service,
	|			RoomQuotaSales.CalendarDayType,
	|			NULL,
	|			RoomQuotaSales.Period,
	|			NULL,
	|			RoomQuotaSales.RoomQuota,
	|			NULL,
	|			RoomQuotaSales.RoomQuota.Customer,
	|			RoomQuotaSales.RoomQuota.Contract,
	|			RoomQuotaSales.RoomQuota.Agent,
	|			NULL,
	|			NULL,
	|			NULL,
	|			RoomQuotaSales.AllotmentPrice,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			RoomQuotaSales.RoomQuota.RoomRate.Discount,
	|			RoomQuotaSales.RoomQuota.RoomRate.DiscountType,
	|			NULL,
	|			RoomQuotaSales.RoomQuota.Agent.AgentCommission,
	|			RoomQuotaSales.RoomQuota.Agent.AgentCommissionType,
	|			RoomQuotaSales.RoomQuota.Customer.PlannedPaymentMethod,
	|			RoomQuotaSales.VATRate,
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
	|			RoomQuotaSales.Counter,
	|			0,
	|			1,
	|			NULL
	|		FROM
	|			RoomQuotaSales AS RoomQuotaSales
	|		WHERE
	|			&qWithAllotments) AS RoomSales) AS RoomSalesPerRoomTypePerPeriod
	|
	|GROUP BY
	|	RoomSalesPerRoomTypePerPeriod.Hotel,
	|	RoomSalesPerRoomTypePerPeriod.RoomType,
	|	RoomSalesPerRoomTypePerPeriod.ServiceDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomSalesPerRoomTypeAndCalendarDayTypePerDay.Hotel AS Hotel,
	|	RoomSalesPerRoomTypeAndCalendarDayTypePerDay.RoomType AS RoomType,
	|	RoomSalesPerRoomTypeAndCalendarDayTypePerDay.CalendarDayType AS CalendarDayType,
	|	RoomSalesPerRoomTypeAndCalendarDayTypePerDay.Period AS Period,
	|	SUM(RoomSalesPerRoomTypeAndCalendarDayTypePerDay.SalesTurnover) AS SalesTurnover,
	|	SUM(RoomSalesPerRoomTypeAndCalendarDayTypePerDay.RoomRevenueTurnover) AS RoomRevenueTurnover,
	|	SUM(RoomSalesPerRoomTypeAndCalendarDayTypePerDay.ExtraBedRevenueTurnover) AS ExtraBedRevenueTurnover,
	|	SUM(RoomSalesPerRoomTypeAndCalendarDayTypePerDay.SalesWithoutVATTurnover) AS SalesWithoutVATTurnover,
	|	SUM(RoomSalesPerRoomTypeAndCalendarDayTypePerDay.RoomRevenueWithoutVATTurnover) AS RoomRevenueWithoutVATTurnover,
	|	SUM(RoomSalesPerRoomTypeAndCalendarDayTypePerDay.ExtraBedRevenueWithoutVATTurnover) AS ExtraBedRevenueWithoutVATTurnover,
	|	SUM(RoomSalesPerRoomTypeAndCalendarDayTypePerDay.CommissionSumTurnover) AS CommissionSumTurnover,
	|	SUM(RoomSalesPerRoomTypeAndCalendarDayTypePerDay.CommissionSumWithoutVATTurnover) AS CommissionSumWithoutVATTurnover,
	|	SUM(RoomSalesPerRoomTypeAndCalendarDayTypePerDay.DiscountSumTurnover) AS DiscountSumTurnover,
	|	SUM(RoomSalesPerRoomTypeAndCalendarDayTypePerDay.DiscountSumWithoutVATTurnover) AS DiscountSumWithoutVATTurnover,
	|	SUM(RoomSalesPerRoomTypeAndCalendarDayTypePerDay.RoomsRentedTurnover) AS RoomsRentedTurnover,
	|	SUM(RoomSalesPerRoomTypeAndCalendarDayTypePerDay.BedsRentedTurnover) AS BedsRentedTurnover,
	|	SUM(RoomSalesPerRoomTypeAndCalendarDayTypePerDay.AdditionalBedsRentedTurnover) AS AdditionalBedsRentedTurnover,
	|	SUM(RoomSalesPerRoomTypeAndCalendarDayTypePerDay.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover,
	|	SUM(RoomSalesPerRoomTypeAndCalendarDayTypePerDay.RoomsCheckedInTurnover) AS RoomsCheckedInTurnover,
	|	SUM(RoomSalesPerRoomTypeAndCalendarDayTypePerDay.BedsCheckedInTurnover) AS BedsCheckedInTurnover,
	|	SUM(RoomSalesPerRoomTypeAndCalendarDayTypePerDay.AdditionalBedsCheckedInTurnover) AS AdditionalBedsCheckedInTurnover,
	|	SUM(RoomSalesPerRoomTypeAndCalendarDayTypePerDay.BookingWindowTurnover) AS BookingWindowTurnover,
	|	SUM(RoomSalesPerRoomTypeAndCalendarDayTypePerDay.Counter) AS Counter,
	|	SUM(RoomSalesPerRoomTypeAndCalendarDayTypePerDay.GuestDaysTurnover) AS GuestDaysTurnover,
	|	SUM(RoomSalesPerRoomTypeAndCalendarDayTypePerDay.NumberOfDetailedRows) AS NumberOfDetailedRows,
	|	RoomSalesPerRoomTypeAndCalendarDayTypePerDay.ServiceDate AS ServiceDate
	|INTO RoomSalesPerRoomTypeAndCalendarDayTypePerDay
	|FROM
	|	(SELECT
	|		RoomSales.Period AS Period,
	|		RoomSales.Hotel AS Hotel,
	|		RoomSales.RoomType AS RoomType,
	|		RoomSales.RoomRate AS RoomRate,
	|		RoomSales.CalendarDayType AS CalendarDayType,
	|		RoomSales.SalesTurnover AS SalesTurnover,
	|		RoomSales.RoomRevenueTurnover AS RoomRevenueTurnover,
	|		RoomSales.ExtraBedRevenueTurnover AS ExtraBedRevenueTurnover,
	|		RoomSales.SalesWithoutVATTurnover AS SalesWithoutVATTurnover,
	|		RoomSales.RoomRevenueWithoutVATTurnover AS RoomRevenueWithoutVATTurnover,
	|		RoomSales.ExtraBedRevenueWithoutVATTurnover AS ExtraBedRevenueWithoutVATTurnover,
	|		RoomSales.CommissionSumTurnover AS CommissionSumTurnover,
	|		RoomSales.CommissionSumWithoutVATTurnover AS CommissionSumWithoutVATTurnover,
	|		RoomSales.DiscountSumTurnover AS DiscountSumTurnover,
	|		RoomSales.DiscountSumWithoutVATTurnover AS DiscountSumWithoutVATTurnover,
	|		RoomSales.RoomsRentedTurnover AS RoomsRentedTurnover,
	|		RoomSales.BedsRentedTurnover AS BedsRentedTurnover,
	|		RoomSales.AdditionalBedsRentedTurnover AS AdditionalBedsRentedTurnover,
	|		RoomSales.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
	|		RoomSales.RoomsCheckedInTurnover AS RoomsCheckedInTurnover,
	|		RoomSales.BedsCheckedInTurnover AS BedsCheckedInTurnover,
	|		RoomSales.AdditionalBedsCheckedInTurnover AS AdditionalBedsCheckedInTurnover,
	|		RoomSales.BookingWindowTurnover AS BookingWindowTurnover,
	|		RoomSales.Counter AS Counter,
	|		RoomSales.GuestDaysTurnover AS GuestDaysTurnover,
	|		RoomSales.NumberOfDetailedRows AS NumberOfDetailedRows,
	|		RoomSales.ServiceDate AS ServiceDate
	|	FROM
	|		(SELECT
	|			BEGINOFPERIOD(RoomSalesTotals.Period, DAY) AS Period,
	|			RoomSalesTotals.Company AS Company,
	|			RoomSalesTotals.Hotel AS Hotel,
	|			RoomSalesTotals.ReportingCurrency AS ReportingCurrency,
	|			RoomSalesTotals.Room AS Room,
	|			RoomSalesTotals.RoomType AS RoomType,
	|			RoomSalesTotals.RoomRate AS RoomRate,
	|			RoomSalesTotals.AccommodationType AS AccommodationType,
	|			RoomSalesTotals.ClientType AS ClientType,
	|			RoomSalesTotals.MarketingCode AS MarketingCode,
	|			RoomSalesTotals.SourceOfBusiness AS SourceOfBusiness,
	|			RoomSalesTotals.Service AS Service,
	|			RoomSalesTotals.CalendarDayType AS CalendarDayType,
	|			RoomSalesTotals.PriceTag AS PriceTag,
	|			RoomSalesTotals.AccountingDate AS AccountingDate,
	|			RoomSalesTotals.ParentDoc AS ParentDoc,
	|			RoomSalesTotals.ParentDoc.RoomQuota AS RoomQuota,
	|			RoomSalesTotals.GuestGroup AS GuestGroup,
	|			RoomSalesTotals.Customer AS Customer,
	|			RoomSalesTotals.Contract AS Contract,
	|			RoomSalesTotals.Agent AS Agent,
	|			RoomSalesTotals.Client AS Client,
	|			RoomSalesTotals.Resource AS Resource,
	|			RoomSalesTotals.Folio AS Folio,
	|			RoomSalesTotals.Price AS Price,
	|			RoomSalesTotals.ResourceType AS ResourceType,
	|			RoomSalesTotals.TripPurpose AS TripPurpose,
	|			RoomSalesTotals.HotelProduct AS HotelProduct,
	|			RoomSalesTotals.Author AS Author,
	|			RoomSalesTotals.Discount AS Discount,
	|			RoomSalesTotals.DiscountType AS DiscountType,
	|			RoomSalesTotals.DiscountCard AS DiscountCard,
	|			RoomSalesTotals.AgentCommission AS AgentCommission,
	|			RoomSalesTotals.AgentCommissionType AS AgentCommissionType,
	|			RoomSalesTotals.PaymentMethod AS PaymentMethod,
	|			RoomSalesTotals.VATRate AS VATRate,
	|			RoomSalesTotals.Sales AS SalesTurnover,
	|			RoomSalesTotals.RoomRevenue AS RoomRevenueTurnover,
	|			RoomSalesTotals.ExtraBedRevenue AS ExtraBedRevenueTurnover,
	|			RoomSalesTotals.SalesWithoutVAT AS SalesWithoutVATTurnover,
	|			RoomSalesTotals.RoomRevenueWithoutVAT AS RoomRevenueWithoutVATTurnover,
	|			RoomSalesTotals.ExtraBedRevenueWithoutVAT AS ExtraBedRevenueWithoutVATTurnover,
	|			RoomSalesTotals.CommissionSum AS CommissionSumTurnover,
	|			RoomSalesTotals.CommissionSumWithoutVAT AS CommissionSumWithoutVATTurnover,
	|			RoomSalesTotals.DiscountSum AS DiscountSumTurnover,
	|			RoomSalesTotals.DiscountSumWithoutVAT AS DiscountSumWithoutVATTurnover,
	|			RoomSalesTotals.RoomsRented AS RoomsRentedTurnover,
	|			RoomSalesTotals.BedsRented AS BedsRentedTurnover,
	|			RoomSalesTotals.AdditionalBedsRented AS AdditionalBedsRentedTurnover,
	|			RoomSalesTotals.GuestsCheckedIn AS GuestsCheckedInTurnover,
	|			RoomSalesTotals.RoomsCheckedIn AS RoomsCheckedInTurnover,
	|			RoomSalesTotals.BedsCheckedIn AS BedsCheckedInTurnover,
	|			RoomSalesTotals.AdditionalBedsCheckedIn AS AdditionalBedsCheckedInTurnover,
	|			RoomSalesTotals.BookingWindow AS BookingWindowTurnover,
	|			RoomSalesTotals.Quantity AS Counter,
	|			RoomSalesTotals.GuestDays AS GuestDaysTurnover,
	|			1 AS NumberOfDetailedRows,
	|			RoomSalesTotals.ServiceDate AS ServiceDate
	|		FROM
	|			AccumulationRegister.Sales AS RoomSalesTotals
	|		WHERE
	|			RoomSalesTotals.Period >= &qPeriodFrom
	|			AND RoomSalesTotals.Period <= &qPeriodTo
	|			AND &qUsePerDayStats
	|			AND (&qHideCorrections
	|					OR NOT &qHideCorrections
	|						AND NOT RoomSalesTotals.IsCorrection)
	|			AND &qUsePerRoomTypeStats
	|			AND &qUseCalendarStats
	|			AND RoomSalesTotals.Hotel IN HIERARCHY(&qHotel)
	|			AND (RoomSalesTotals.Room IN HIERARCHY (&qRoom)
	|					OR &qIsEmptyRoom)
	|			AND (NOT RoomSalesTotals.Room IN (&qRooms2IgnoreList)
	|					OR &qRooms2IgnoreListIsEmpty)
	|			AND (RoomSalesTotals.RoomType IN HIERARCHY (&qRoomType)
	|					OR &qIsEmptyRoomType)
	|			AND (RoomSalesTotals.Service IN HIERARCHY (&qService)
	|					OR &qIsEmptyService)
	|			AND (RoomSalesTotals.Service IN (&qServicesList)
	|					OR NOT &qUseServicesList)
	|			AND (NOT &qWithAllotments
	|					OR &qWithAllotments
	|						AND NOT ISNULL(RoomSalesTotals.ParentDoc.RoomQuota.IsCommitment, FALSE))
	|			AND (NOT &qFilterByReservationCreationDate
	|						AND NOT &qLimitByTodaysDate
	|					OR NOT &qFilterByReservationCreationDate
	|						AND &qLimitByTodaysDate
	|						AND NOT &qByGroupCreationDate
	|						AND (RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesTotals.ParentDoc.Date <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(RoomSalesTotals.AccountingDate, YEAR), DAY, &qTodaysDay), DAY)
	|							OR NOT RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesTotals.ParentDoc.Reservation.Date <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(RoomSalesTotals.AccountingDate, YEAR), DAY, &qTodaysDay), DAY))
	|					OR NOT &qFilterByReservationCreationDate
	|						AND &qLimitByTodaysDate
	|						AND &qByGroupCreationDate
	|						AND NOT RoomSalesTotals.GuestGroup.CreateDate IS NULL
	|						AND RoomSalesTotals.GuestGroup.CreateDate <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(RoomSalesTotals.AccountingDate, YEAR), DAY, &qTodaysDay), DAY)
	|					OR &qFilterByReservationCreationDate
	|						AND NOT &qNoYear
	|						AND &qByGroupCreationDate
	|						AND (RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesTotals.ParentDoc.Date >= &qDateFrom
	|							OR NOT RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesTotals.ParentDoc.Reservation.Date >= &qDateFrom)
	|						AND (&qDateToIsEmpty
	|							OR RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesTotals.ParentDoc.Date <= &qDateTo
	|							OR NOT RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesTotals.ParentDoc.Reservation.Date <= &qDateTo)
	|					OR &qFilterByReservationCreationDate
	|						AND NOT &qNoYear
	|						AND &qByGroupCreationDate
	|						AND NOT RoomSalesTotals.GuestGroup.CreateDate IS NULL
	|						AND RoomSalesTotals.GuestGroup.CreateDate >= &qDateFrom
	|						AND (&qDateToIsEmpty
	|							OR RoomSalesTotals.GuestGroup.CreateDate <= &qDateTo)
	|					OR &qFilterByReservationCreationDate
	|						AND &qNoYear
	|						AND NOT &qByGroupCreationDate
	|						AND CASE
	|							WHEN &qShiftFrom = 1
	|									AND RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Date, YEAR, 2 - YEAR(RoomSalesTotals.ParentDoc.Date)) <= &qDateTo
	|								THEN TRUE
	|							WHEN &qShiftFrom = 1
	|									AND RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Date, YEAR, 1 - YEAR(RoomSalesTotals.ParentDoc.Date)) >= &qDateFrom
	|								THEN TRUE
	|							WHEN &qShiftFrom = 2
	|									AND RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Date, YEAR, 2 - YEAR(RoomSalesTotals.ParentDoc.Date)) >= &qDateFrom
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Date, YEAR, 2 - YEAR(RoomSalesTotals.ParentDoc.Date)) <= &qDateTo
	|								THEN TRUE
	|							WHEN &qShiftFrom = 1
	|									AND NOT RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Reservation.Date, YEAR, 2 - YEAR(RoomSalesTotals.ParentDoc.Reservation.Date)) <= &qDateTo
	|								THEN TRUE
	|							WHEN &qShiftFrom = 1
	|									AND NOT RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Reservation.Date, YEAR, 1 - YEAR(RoomSalesTotals.ParentDoc.Reservation.Date)) >= &qDateFrom
	|								THEN TRUE
	|							WHEN &qShiftFrom = 2
	|									AND NOT RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Reservation.Date, YEAR, 2 - YEAR(RoomSalesTotals.ParentDoc.Reservation.Date)) >= &qDateFrom
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Reservation.Date, YEAR, 2 - YEAR(RoomSalesTotals.ParentDoc.Reservation.Date)) <= &qDateTo
	|								THEN TRUE
	|							ELSE FALSE
	|						END
	|					OR &qFilterByReservationCreationDate
	|						AND &qNoYear
	|						AND &qByGroupCreationDate
	|						AND NOT RoomSalesTotals.GuestGroup.CreateDate IS NULL
	|						AND CASE
	|							WHEN &qShiftFrom = 1
	|									AND DATEADD(RoomSalesTotals.GuestGroup.CreateDate, YEAR, 2 - YEAR(RoomSalesTotals.GuestGroup.CreateDate)) <= &qDateTo
	|								THEN TRUE
	|							WHEN &qShiftFrom = 1
	|									AND DATEADD(RoomSalesTotals.GuestGroup.CreateDate, YEAR, 1 - YEAR(RoomSalesTotals.GuestGroup.CreateDate)) >= &qDateFrom
	|								THEN TRUE
	|							WHEN &qShiftFrom = 2
	|									AND DATEADD(RoomSalesTotals.GuestGroup.CreateDate, YEAR, 2 - YEAR(RoomSalesTotals.GuestGroup.CreateDate)) >= &qDateFrom
	|									AND DATEADD(RoomSalesTotals.GuestGroup.CreateDate, YEAR, 2 - YEAR(RoomSalesTotals.GuestGroup.CreateDate)) <= &qDateTo
	|								THEN TRUE
	|							ELSE FALSE
	|						END)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			BEGINOFPERIOD(RoomSalesForecastTotals.Period, DAY),
	|			RoomSalesForecastTotals.Company,
	|			RoomSalesForecastTotals.Hotel,
	|			RoomSalesForecastTotals.ReportingCurrency,
	|			RoomSalesForecastTotals.Room,
	|			RoomSalesForecastTotals.RoomType,
	|			RoomSalesForecastTotals.RoomRate,
	|			RoomSalesForecastTotals.AccommodationType,
	|			RoomSalesForecastTotals.ClientType,
	|			RoomSalesForecastTotals.MarketingCode,
	|			RoomSalesForecastTotals.SourceOfBusiness,
	|			RoomSalesForecastTotals.Service,
	|			RoomSalesForecastTotals.CalendarDayType,
	|			RoomSalesForecastTotals.PriceTag,
	|			RoomSalesForecastTotals.AccountingDate,
	|			RoomSalesForecastTotals.ParentDoc,
	|			RoomSalesForecastTotals.ParentDoc.RoomQuota,
	|			RoomSalesForecastTotals.GuestGroup,
	|			RoomSalesForecastTotals.Customer,
	|			RoomSalesForecastTotals.Contract,
	|			RoomSalesForecastTotals.Agent,
	|			RoomSalesForecastTotals.Client,
	|			RoomSalesForecastTotals.Resource,
	|			RoomSalesForecastTotals.Folio,
	|			RoomSalesForecastTotals.Price,
	|			RoomSalesForecastTotals.ResourceType,
	|			RoomSalesForecastTotals.TripPurpose,
	|			RoomSalesForecastTotals.HotelProduct,
	|			RoomSalesForecastTotals.Author,
	|			RoomSalesForecastTotals.Discount,
	|			RoomSalesForecastTotals.DiscountType,
	|			RoomSalesForecastTotals.DiscountCard,
	|			RoomSalesForecastTotals.AgentCommission,
	|			RoomSalesForecastTotals.AgentCommissionType,
	|			RoomSalesForecastTotals.PaymentMethod,
	|			RoomSalesForecastTotals.VATRate,
	|			RoomSalesForecastTotals.Sales,
	|			RoomSalesForecastTotals.RoomRevenue,
	|			RoomSalesForecastTotals.ExtraBedRevenue,
	|			RoomSalesForecastTotals.SalesWithoutVAT,
	|			RoomSalesForecastTotals.RoomRevenueWithoutVAT,
	|			RoomSalesForecastTotals.ExtraBedRevenueWithoutVAT,
	|			RoomSalesForecastTotals.CommissionSum,
	|			RoomSalesForecastTotals.CommissionSumWithoutVAT,
	|			RoomSalesForecastTotals.DiscountSum,
	|			RoomSalesForecastTotals.DiscountSumWithoutVAT,
	|			RoomSalesForecastTotals.RoomsRented,
	|			RoomSalesForecastTotals.BedsRented,
	|			RoomSalesForecastTotals.AdditionalBedsRented,
	|			RoomSalesForecastTotals.GuestsCheckedIn,
	|			RoomSalesForecastTotals.RoomsCheckedIn,
	|			RoomSalesForecastTotals.BedsCheckedIn,
	|			RoomSalesForecastTotals.AdditionalBedsCheckedIn,
	|			RoomSalesForecastTotals.BookingWindow,
	|			RoomSalesForecastTotals.Quantity,
	|			RoomSalesForecastTotals.GuestDays,
	|			1,
	|			RoomSalesForecastTotals.ServiceDate
	|		FROM
	|			AccumulationRegister.SalesForecast AS RoomSalesForecastTotals
	|		WHERE
	|			RoomSalesForecastTotals.Period >= &qForecastPeriodFrom
	|			AND RoomSalesForecastTotals.Period <= &qForecastPeriodTo
	|			AND &qUsePerDayStats
	|			AND &qUsePerRoomTypeStats
	|			AND &qUseCalendarStats
	|			AND &qUseForecast
	|			AND RoomSalesForecastTotals.Hotel IN HIERARCHY(&qHotel)
	|			AND (RoomSalesForecastTotals.Room IN HIERARCHY (&qRoom)
	|					OR &qIsEmptyRoom)
	|			AND (NOT RoomSalesForecastTotals.Room IN (&qRooms2IgnoreList)
	|					OR &qRooms2IgnoreListIsEmpty)
	|			AND (RoomSalesForecastTotals.RoomType IN HIERARCHY (&qRoomType)
	|					OR &qIsEmptyRoomType)
	|			AND (RoomSalesForecastTotals.Service IN HIERARCHY (&qService)
	|					OR &qIsEmptyService)
	|			AND (RoomSalesForecastTotals.Service IN (&qServicesList)
	|					OR NOT &qUseServicesList)
	|			AND (NOT &qWithAllotments
	|					OR &qWithAllotments
	|						AND NOT ISNULL(RoomSalesForecastTotals.ParentDoc.RoomQuota.IsCommitment, FALSE))
	|			AND (NOT &qFilterByReservationCreationDate
	|						AND NOT &qLimitByTodaysDate
	|					OR NOT &qFilterByReservationCreationDate
	|						AND &qLimitByTodaysDate
	|						AND NOT &qByGroupCreationDate
	|						AND (RoomSalesForecastTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesForecastTotals.ParentDoc.Date <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(RoomSalesForecastTotals.AccountingDate, YEAR), DAY, &qTodaysDay), DAY)
	|							OR NOT RoomSalesForecastTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesForecastTotals.ParentDoc.Reservation.Date <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(RoomSalesForecastTotals.AccountingDate, YEAR), DAY, &qTodaysDay), DAY))
	|					OR NOT &qFilterByReservationCreationDate
	|						AND &qLimitByTodaysDate
	|						AND &qByGroupCreationDate
	|						AND NOT RoomSalesForecastTotals.GuestGroup.CreateDate IS NULL
	|						AND RoomSalesForecastTotals.GuestGroup.CreateDate <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(RoomSalesForecastTotals.AccountingDate, YEAR), DAY, &qTodaysDay), DAY)
	|						AND NOT &qByGroupCreationDate
	|					OR &qFilterByReservationCreationDate
	|						AND NOT &qNoYear
	|						AND RoomSalesForecastTotals.ParentDoc.Date >= &qDateFrom
	|						AND (RoomSalesForecastTotals.ParentDoc.Date <= &qDateTo
	|							OR &qDateToIsEmpty)
	|					OR &qFilterByReservationCreationDate
	|						AND NOT &qNoYear
	|						AND &qByGroupCreationDate
	|						AND NOT RoomSalesForecastTotals.GuestGroup.CreateDate IS NULL
	|						AND RoomSalesForecastTotals.GuestGroup.CreateDate >= &qDateFrom
	|						AND (&qDateToIsEmpty
	|							OR RoomSalesForecastTotals.GuestGroup.CreateDate <= &qDateTo)
	|					OR &qFilterByReservationCreationDate
	|						AND &qNoYear
	|						AND NOT &qByGroupCreationDate
	|						AND NOT RoomSalesForecastTotals.ParentDoc.Date IS NULL
	|						AND CASE
	|							WHEN &qShiftFrom = 1
	|									AND DATEADD(RoomSalesForecastTotals.ParentDoc.Date, YEAR, 2 - YEAR(RoomSalesForecastTotals.ParentDoc.Date)) <= &qDateTo
	|								THEN TRUE
	|							WHEN &qShiftFrom = 1
	|									AND DATEADD(RoomSalesForecastTotals.ParentDoc.Date, YEAR, 1 - YEAR(RoomSalesForecastTotals.ParentDoc.Date)) >= &qDateFrom
	|								THEN TRUE
	|							WHEN &qShiftFrom = 2
	|									AND DATEADD(RoomSalesForecastTotals.ParentDoc.Date, YEAR, 2 - YEAR(RoomSalesForecastTotals.ParentDoc.Date)) >= &qDateFrom
	|									AND DATEADD(RoomSalesForecastTotals.ParentDoc.Date, YEAR, 2 - YEAR(RoomSalesForecastTotals.ParentDoc.Date)) <= &qDateTo
	|								THEN TRUE
	|							ELSE FALSE
	|						END
	|					OR &qFilterByReservationCreationDate
	|						AND &qNoYear
	|						AND &qByGroupCreationDate
	|						AND NOT RoomSalesForecastTotals.GuestGroup.CreateDate IS NULL
	|						AND CASE
	|							WHEN &qShiftFrom = 1
	|									AND DATEADD(RoomSalesForecastTotals.GuestGroup.CreateDate, YEAR, 2 - YEAR(RoomSalesForecastTotals.GuestGroup.CreateDate)) <= &qDateTo
	|								THEN TRUE
	|							WHEN &qShiftFrom = 1
	|									AND DATEADD(RoomSalesForecastTotals.GuestGroup.CreateDate, YEAR, 1 - YEAR(RoomSalesForecastTotals.GuestGroup.CreateDate)) >= &qDateFrom
	|								THEN TRUE
	|							WHEN &qShiftFrom = 2
	|									AND DATEADD(RoomSalesForecastTotals.GuestGroup.CreateDate, YEAR, 2 - YEAR(RoomSalesForecastTotals.GuestGroup.CreateDate)) >= &qDateFrom
	|									AND DATEADD(RoomSalesForecastTotals.GuestGroup.CreateDate, YEAR, 2 - YEAR(RoomSalesForecastTotals.GuestGroup.CreateDate)) <= &qDateTo
	|								THEN TRUE
	|							ELSE FALSE
	|						END)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			RoomTypesListPerDay.Period,
	|			NULL,
	|			RoomTypesListPerDay.Hotel,
	|			RoomTypesListPerDay.Hotel.ReportingCurrency,
	|			NULL,
	|			RoomTypesListPerDay.RoomType,
	|			NULL,
	|			NULL,
	|			NULL,
	|			VALUE(Catalog.MarketingCodes.EmptyRef),
	|			VALUE(Catalog.SourcesOfBusiness.EmptyRef),
	|			NULL,
	|			NULL,
	|			NULL,
	|			RoomTypesListPerDay.Period,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
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
	|			1,
	|			NULL
	|		FROM
	|			HotelInventoryTotalsPerDay AS RoomTypesListPerDay
	|		WHERE
	|			&qUsePerDayStats
	|			AND &qUsePerRoomTypeStats
	|			AND &qUseCalendarStats
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			RoomQuotaSales.Period,
	|			RoomQuotaSales.Hotel.Company,
	|			RoomQuotaSales.Hotel,
	|			RoomQuotaSales.Hotel.ReportingCurrency,
	|			NULL,
	|			RoomQuotaSales.RoomType,
	|			RoomQuotaSales.RoomQuota.RoomRate,
	|			NULL,
	|			RoomQuotaSales.RoomQuota.ClientType,
	|			RoomQuotaSales.RoomQuota.MarketingCode,
	|			RoomQuotaSales.RoomQuota.SourceOfBusiness,
	|			RoomQuotaSales.Service,
	|			RoomQuotaSales.CalendarDayType,
	|			NULL,
	|			RoomQuotaSales.Period,
	|			NULL,
	|			RoomQuotaSales.RoomQuota,
	|			NULL,
	|			RoomQuotaSales.RoomQuota.Customer,
	|			RoomQuotaSales.RoomQuota.Contract,
	|			RoomQuotaSales.RoomQuota.Agent,
	|			NULL,
	|			NULL,
	|			NULL,
	|			RoomQuotaSales.AllotmentPrice,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			RoomQuotaSales.RoomQuota.RoomRate.Discount,
	|			RoomQuotaSales.RoomQuota.RoomRate.DiscountType,
	|			NULL,
	|			RoomQuotaSales.RoomQuota.Agent.AgentCommission,
	|			RoomQuotaSales.RoomQuota.Agent.AgentCommissionType,
	|			RoomQuotaSales.RoomQuota.Customer.PlannedPaymentMethod,
	|			RoomQuotaSales.VATRate,
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
	|			RoomQuotaSales.Counter,
	|			0,
	|			1,
	|			NULL
	|		FROM
	|			RoomQuotaSales AS RoomQuotaSales
	|		WHERE
	|			&qWithAllotments) AS RoomSales) AS RoomSalesPerRoomTypeAndCalendarDayTypePerDay
	|
	|GROUP BY
	|	RoomSalesPerRoomTypeAndCalendarDayTypePerDay.Hotel,
	|	RoomSalesPerRoomTypeAndCalendarDayTypePerDay.RoomType,
	|	RoomSalesPerRoomTypeAndCalendarDayTypePerDay.CalendarDayType,
	|	RoomSalesPerRoomTypeAndCalendarDayTypePerDay.Period,
	|	RoomSalesPerRoomTypeAndCalendarDayTypePerDay.ServiceDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.Hotel AS Hotel,
	|	RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.RoomType AS RoomType,
	|	RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.CalendarDayType AS CalendarDayType,
	|	RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.Period AS Period,
	|	SUM(RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.SalesTurnover) AS SalesTurnover,
	|	SUM(RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.RoomRevenueTurnover) AS RoomRevenueTurnover,
	|	SUM(RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.ExtraBedRevenueTurnover) AS ExtraBedRevenueTurnover,
	|	SUM(RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.SalesWithoutVATTurnover) AS SalesWithoutVATTurnover,
	|	SUM(RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.RoomRevenueWithoutVATTurnover) AS RoomRevenueWithoutVATTurnover,
	|	SUM(RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.ExtraBedRevenueWithoutVATTurnover) AS ExtraBedRevenueWithoutVATTurnover,
	|	SUM(RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.CommissionSumTurnover) AS CommissionSumTurnover,
	|	SUM(RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.CommissionSumWithoutVATTurnover) AS CommissionSumWithoutVATTurnover,
	|	SUM(RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.DiscountSumTurnover) AS DiscountSumTurnover,
	|	SUM(RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.DiscountSumWithoutVATTurnover) AS DiscountSumWithoutVATTurnover,
	|	SUM(RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.RoomsRentedTurnover) AS RoomsRentedTurnover,
	|	SUM(RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.BedsRentedTurnover) AS BedsRentedTurnover,
	|	SUM(RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.AdditionalBedsRentedTurnover) AS AdditionalBedsRentedTurnover,
	|	SUM(RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover,
	|	SUM(RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.RoomsCheckedInTurnover) AS RoomsCheckedInTurnover,
	|	SUM(RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.BedsCheckedInTurnover) AS BedsCheckedInTurnover,
	|	SUM(RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.AdditionalBedsCheckedInTurnover) AS AdditionalBedsCheckedInTurnover,
	|	SUM(RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.BookingWindowTurnover) AS BookingWindowTurnover,
	|	SUM(RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.Counter) AS Counter,
	|	SUM(RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.GuestDaysTurnover) AS GuestDaysTurnover,
	|	SUM(RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.NumberOfDetailedRows) AS NumberOfDetailedRows,
	|	RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.ServiceDate AS ServiceDate
	|INTO RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay
	|FROM
	|	(SELECT
	|		RoomSales.Period AS Period,
	|		RoomSales.Hotel AS Hotel,
	|		RoomSales.RoomType AS RoomType,
	|		CalendarDayTypesByChoosenCalendar.CalendarDayType AS CalendarDayType,
	|		RoomSales.SalesTurnover AS SalesTurnover,
	|		RoomSales.RoomRevenueTurnover AS RoomRevenueTurnover,
	|		RoomSales.ExtraBedRevenueTurnover AS ExtraBedRevenueTurnover,
	|		RoomSales.SalesWithoutVATTurnover AS SalesWithoutVATTurnover,
	|		RoomSales.RoomRevenueWithoutVATTurnover AS RoomRevenueWithoutVATTurnover,
	|		RoomSales.ExtraBedRevenueWithoutVATTurnover AS ExtraBedRevenueWithoutVATTurnover,
	|		RoomSales.CommissionSumTurnover AS CommissionSumTurnover,
	|		RoomSales.CommissionSumWithoutVATTurnover AS CommissionSumWithoutVATTurnover,
	|		RoomSales.DiscountSumTurnover AS DiscountSumTurnover,
	|		RoomSales.DiscountSumWithoutVATTurnover AS DiscountSumWithoutVATTurnover,
	|		RoomSales.RoomsRentedTurnover AS RoomsRentedTurnover,
	|		RoomSales.BedsRentedTurnover AS BedsRentedTurnover,
	|		RoomSales.AdditionalBedsRentedTurnover AS AdditionalBedsRentedTurnover,
	|		RoomSales.GuestsCheckedInTurnover AS GuestsCheckedInTurnover,
	|		RoomSales.RoomsCheckedInTurnover AS RoomsCheckedInTurnover,
	|		RoomSales.BedsCheckedInTurnover AS BedsCheckedInTurnover,
	|		RoomSales.AdditionalBedsCheckedInTurnover AS AdditionalBedsCheckedInTurnover,
	|		RoomSales.BookingWindowTurnover AS BookingWindowTurnover,
	|		RoomSales.Counter AS Counter,
	|		RoomSales.GuestDaysTurnover AS GuestDaysTurnover,
	|		RoomSales.NumberOfDetailedRows AS NumberOfDetailedRows,
	|		RoomSales.ServiceDate AS ServiceDate
	|	FROM
	|		(SELECT
	|			BEGINOFPERIOD(RoomSalesTotals.Period, DAY) AS Period,
	|			RoomSalesTotals.Company AS Company,
	|			RoomSalesTotals.Hotel AS Hotel,
	|			RoomSalesTotals.ReportingCurrency AS ReportingCurrency,
	|			RoomSalesTotals.Room AS Room,
	|			RoomSalesTotals.RoomType AS RoomType,
	|			RoomSalesTotals.RoomRate AS RoomRate,
	|			RoomSalesTotals.AccommodationType AS AccommodationType,
	|			RoomSalesTotals.ClientType AS ClientType,
	|			RoomSalesTotals.MarketingCode AS MarketingCode,
	|			RoomSalesTotals.SourceOfBusiness AS SourceOfBusiness,
	|			RoomSalesTotals.Service AS Service,
	|			RoomSalesTotals.CalendarDayType AS CalendarDayType,
	|			RoomSalesTotals.PriceTag AS PriceTag,
	|			RoomSalesTotals.AccountingDate AS AccountingDate,
	|			RoomSalesTotals.ParentDoc AS ParentDoc,
	|			RoomSalesTotals.ParentDoc.RoomQuota AS RoomQuota,
	|			RoomSalesTotals.GuestGroup AS GuestGroup,
	|			RoomSalesTotals.Customer AS Customer,
	|			RoomSalesTotals.Contract AS Contract,
	|			RoomSalesTotals.Agent AS Agent,
	|			RoomSalesTotals.Client AS Client,
	|			RoomSalesTotals.Resource AS Resource,
	|			RoomSalesTotals.Folio AS Folio,
	|			RoomSalesTotals.Price AS Price,
	|			RoomSalesTotals.ResourceType AS ResourceType,
	|			RoomSalesTotals.TripPurpose AS TripPurpose,
	|			RoomSalesTotals.HotelProduct AS HotelProduct,
	|			RoomSalesTotals.Author AS Author,
	|			RoomSalesTotals.Discount AS Discount,
	|			RoomSalesTotals.DiscountType AS DiscountType,
	|			RoomSalesTotals.DiscountCard AS DiscountCard,
	|			RoomSalesTotals.AgentCommission AS AgentCommission,
	|			RoomSalesTotals.AgentCommissionType AS AgentCommissionType,
	|			RoomSalesTotals.PaymentMethod AS PaymentMethod,
	|			RoomSalesTotals.VATRate AS VATRate,
	|			RoomSalesTotals.Sales AS SalesTurnover,
	|			RoomSalesTotals.RoomRevenue AS RoomRevenueTurnover,
	|			RoomSalesTotals.ExtraBedRevenue AS ExtraBedRevenueTurnover,
	|			RoomSalesTotals.SalesWithoutVAT AS SalesWithoutVATTurnover,
	|			RoomSalesTotals.RoomRevenueWithoutVAT AS RoomRevenueWithoutVATTurnover,
	|			RoomSalesTotals.ExtraBedRevenueWithoutVAT AS ExtraBedRevenueWithoutVATTurnover,
	|			RoomSalesTotals.CommissionSum AS CommissionSumTurnover,
	|			RoomSalesTotals.CommissionSumWithoutVAT AS CommissionSumWithoutVATTurnover,
	|			RoomSalesTotals.DiscountSum AS DiscountSumTurnover,
	|			RoomSalesTotals.DiscountSumWithoutVAT AS DiscountSumWithoutVATTurnover,
	|			RoomSalesTotals.RoomsRented AS RoomsRentedTurnover,
	|			RoomSalesTotals.BedsRented AS BedsRentedTurnover,
	|			RoomSalesTotals.AdditionalBedsRented AS AdditionalBedsRentedTurnover,
	|			RoomSalesTotals.GuestsCheckedIn AS GuestsCheckedInTurnover,
	|			RoomSalesTotals.RoomsCheckedIn AS RoomsCheckedInTurnover,
	|			RoomSalesTotals.BedsCheckedIn AS BedsCheckedInTurnover,
	|			RoomSalesTotals.AdditionalBedsCheckedIn AS AdditionalBedsCheckedInTurnover,
	|			RoomSalesTotals.BookingWindow AS BookingWindowTurnover,
	|			RoomSalesTotals.Quantity AS Counter,
	|			RoomSalesTotals.GuestDays AS GuestDaysTurnover,
	|			1 AS NumberOfDetailedRows,
	|			RoomSalesTotals.ServiceDate AS ServiceDate
	|		FROM
	|			AccumulationRegister.Sales AS RoomSalesTotals
	|		WHERE
	|			RoomSalesTotals.Period >= &qPeriodFrom
	|			AND RoomSalesTotals.Period <= &qPeriodTo
	|			AND &qUsePerDayStats
	|			AND (&qHideCorrections
	|					OR NOT &qHideCorrections
	|						AND NOT RoomSalesTotals.IsCorrection)
	|			AND &qUsePerRoomTypeStats
	|			AND &qUseChoosenCalendarStats
	|			AND RoomSalesTotals.Hotel IN HIERARCHY(&qHotel)
	|			AND (RoomSalesTotals.Room IN HIERARCHY (&qRoom)
	|					OR &qIsEmptyRoom)
	|			AND (NOT RoomSalesTotals.Room IN (&qRooms2IgnoreList)
	|					OR &qRooms2IgnoreListIsEmpty)
	|			AND (RoomSalesTotals.RoomType IN HIERARCHY (&qRoomType)
	|					OR &qIsEmptyRoomType)
	|			AND (RoomSalesTotals.Service IN HIERARCHY (&qService)
	|					OR &qIsEmptyService)
	|			AND (RoomSalesTotals.Service IN (&qServicesList)
	|					OR NOT &qUseServicesList)
	|			AND (NOT &qWithAllotments
	|					OR &qWithAllotments
	|						AND NOT ISNULL(RoomSalesTotals.ParentDoc.RoomQuota.IsCommitment, FALSE))
	|			AND (NOT &qFilterByReservationCreationDate
	|						AND NOT &qLimitByTodaysDate
	|					OR NOT &qFilterByReservationCreationDate
	|						AND &qLimitByTodaysDate
	|						AND NOT &qByGroupCreationDate
	|						AND (RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesTotals.ParentDoc.Date <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(RoomSalesTotals.AccountingDate, YEAR), DAY, &qTodaysDay), DAY)
	|							OR NOT RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesTotals.ParentDoc.Reservation.Date <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(RoomSalesTotals.AccountingDate, YEAR), DAY, &qTodaysDay), DAY))
	|					OR NOT &qFilterByReservationCreationDate
	|						AND &qLimitByTodaysDate
	|						AND &qByGroupCreationDate
	|						AND NOT RoomSalesTotals.GuestGroup.CreateDate IS NULL
	|						AND RoomSalesTotals.GuestGroup.CreateDate <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(RoomSalesTotals.AccountingDate, YEAR), DAY, &qTodaysDay), DAY)
	|					OR &qFilterByReservationCreationDate
	|						AND NOT &qNoYear
	|						AND NOT &qByGroupCreationDate
	|						AND (RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesTotals.ParentDoc.Date >= &qDateFrom
	|							OR NOT RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesTotals.ParentDoc.Reservation.Date >= &qDateFrom)
	|						AND (&qDateToIsEmpty
	|							OR RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesTotals.ParentDoc.Date <= &qDateTo
	|							OR NOT RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesTotals.ParentDoc.Reservation.Date <= &qDateTo)
	|					OR &qFilterByReservationCreationDate
	|						AND NOT &qNoYear
	|						AND &qByGroupCreationDate
	|						AND NOT RoomSalesTotals.GuestGroup.CreateDate IS NULL
	|						AND RoomSalesTotals.GuestGroup.CreateDate >= &qDateFrom
	|						AND (&qDateToIsEmpty
	|							OR RoomSalesTotals.GuestGroup.CreateDate <= &qDateTo)
	|					OR &qFilterByReservationCreationDate
	|						AND &qNoYear
	|						AND NOT &qByGroupCreationDate
	|						AND CASE
	|							WHEN &qShiftFrom = 1
	|									AND RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Date, YEAR, 2 - YEAR(RoomSalesTotals.ParentDoc.Date)) <= &qDateTo
	|								THEN TRUE
	|							WHEN &qShiftFrom = 1
	|									AND RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Date, YEAR, 1 - YEAR(RoomSalesTotals.ParentDoc.Date)) >= &qDateFrom
	|								THEN TRUE
	|							WHEN &qShiftFrom = 2
	|									AND RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Date, YEAR, 2 - YEAR(RoomSalesTotals.ParentDoc.Date)) >= &qDateFrom
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Date, YEAR, 2 - YEAR(RoomSalesTotals.ParentDoc.Date)) <= &qDateTo
	|								THEN TRUE
	|							WHEN &qShiftFrom = 1
	|									AND NOT RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Reservation.Date, YEAR, 2 - YEAR(RoomSalesTotals.ParentDoc.Reservation.Date)) <= &qDateTo
	|								THEN TRUE
	|							WHEN &qShiftFrom = 1
	|									AND NOT RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Reservation.Date, YEAR, 1 - YEAR(RoomSalesTotals.ParentDoc.Reservation.Date)) >= &qDateFrom
	|								THEN TRUE
	|							WHEN &qShiftFrom = 2
	|									AND NOT RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Reservation.Date, YEAR, 2 - YEAR(RoomSalesTotals.ParentDoc.Reservation.Date)) >= &qDateFrom
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Reservation.Date, YEAR, 2 - YEAR(RoomSalesTotals.ParentDoc.Reservation.Date)) <= &qDateTo
	|								THEN TRUE
	|							ELSE FALSE
	|						END
	|					OR &qFilterByReservationCreationDate
	|						AND &qNoYear
	|						AND &qByGroupCreationDate
	|						AND NOT RoomSalesTotals.GuestGroup.CreateDate IS NULL
	|						AND CASE
	|							WHEN &qShiftFrom = 1
	|									AND DATEADD(RoomSalesTotals.GuestGroup.CreateDate, YEAR, 2 - YEAR(RoomSalesTotals.GuestGroup.CreateDate)) <= &qDateTo
	|								THEN TRUE
	|							WHEN &qShiftFrom = 1
	|									AND DATEADD(RoomSalesTotals.GuestGroup.CreateDate, YEAR, 1 - YEAR(RoomSalesTotals.GuestGroup.CreateDate)) >= &qDateFrom
	|								THEN TRUE
	|							WHEN &qShiftFrom = 2
	|									AND DATEADD(RoomSalesTotals.GuestGroup.CreateDate, YEAR, 2 - YEAR(RoomSalesTotals.GuestGroup.CreateDate)) >= &qDateFrom
	|									AND DATEADD(RoomSalesTotals.GuestGroup.CreateDate, YEAR, 2 - YEAR(RoomSalesTotals.GuestGroup.CreateDate)) <= &qDateTo
	|								THEN TRUE
	|							ELSE FALSE
	|						END)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			BEGINOFPERIOD(RoomSalesForecastTotals.Period, DAY),
	|			RoomSalesForecastTotals.Company,
	|			RoomSalesForecastTotals.Hotel,
	|			RoomSalesForecastTotals.ReportingCurrency,
	|			RoomSalesForecastTotals.Room,
	|			RoomSalesForecastTotals.RoomType,
	|			RoomSalesForecastTotals.RoomRate,
	|			RoomSalesForecastTotals.AccommodationType,
	|			RoomSalesForecastTotals.ClientType,
	|			RoomSalesForecastTotals.MarketingCode,
	|			RoomSalesForecastTotals.SourceOfBusiness,
	|			RoomSalesForecastTotals.Service,
	|			RoomSalesForecastTotals.CalendarDayType,
	|			RoomSalesForecastTotals.PriceTag,
	|			RoomSalesForecastTotals.AccountingDate,
	|			RoomSalesForecastTotals.ParentDoc,
	|			RoomSalesForecastTotals.ParentDoc.RoomQuota,
	|			RoomSalesForecastTotals.GuestGroup,
	|			RoomSalesForecastTotals.Customer,
	|			RoomSalesForecastTotals.Contract,
	|			RoomSalesForecastTotals.Agent,
	|			RoomSalesForecastTotals.Client,
	|			RoomSalesForecastTotals.Resource,
	|			RoomSalesForecastTotals.Folio,
	|			RoomSalesForecastTotals.Price,
	|			RoomSalesForecastTotals.ResourceType,
	|			RoomSalesForecastTotals.TripPurpose,
	|			RoomSalesForecastTotals.HotelProduct,
	|			RoomSalesForecastTotals.Author,
	|			RoomSalesForecastTotals.Discount,
	|			RoomSalesForecastTotals.DiscountType,
	|			RoomSalesForecastTotals.DiscountCard,
	|			RoomSalesForecastTotals.AgentCommission,
	|			RoomSalesForecastTotals.AgentCommissionType,
	|			RoomSalesForecastTotals.PaymentMethod,
	|			RoomSalesForecastTotals.VATRate,
	|			RoomSalesForecastTotals.Sales,
	|			RoomSalesForecastTotals.RoomRevenue,
	|			RoomSalesForecastTotals.ExtraBedRevenue,
	|			RoomSalesForecastTotals.SalesWithoutVAT,
	|			RoomSalesForecastTotals.RoomRevenueWithoutVAT,
	|			RoomSalesForecastTotals.ExtraBedRevenueWithoutVAT,
	|			RoomSalesForecastTotals.CommissionSum,
	|			RoomSalesForecastTotals.CommissionSumWithoutVAT,
	|			RoomSalesForecastTotals.DiscountSum,
	|			RoomSalesForecastTotals.DiscountSumWithoutVAT,
	|			RoomSalesForecastTotals.RoomsRented,
	|			RoomSalesForecastTotals.BedsRented,
	|			RoomSalesForecastTotals.AdditionalBedsRented,
	|			RoomSalesForecastTotals.GuestsCheckedIn,
	|			RoomSalesForecastTotals.RoomsCheckedIn,
	|			RoomSalesForecastTotals.BedsCheckedIn,
	|			RoomSalesForecastTotals.AdditionalBedsCheckedIn,
	|			RoomSalesForecastTotals.BookingWindow,
	|			RoomSalesForecastTotals.Quantity,
	|			RoomSalesForecastTotals.GuestDays,
	|			1,
	|			RoomSalesForecastTotals.ServiceDate
	|		FROM
	|			AccumulationRegister.SalesForecast AS RoomSalesForecastTotals
	|		WHERE
	|			RoomSalesForecastTotals.Period >= &qForecastPeriodFrom
	|			AND RoomSalesForecastTotals.Period <= &qForecastPeriodTo
	|			AND &qUsePerDayStats
	|			AND &qUsePerRoomTypeStats
	|			AND &qUseChoosenCalendarStats
	|			AND &qUseForecast
	|			AND RoomSalesForecastTotals.Hotel IN HIERARCHY(&qHotel)
	|			AND (RoomSalesForecastTotals.Room IN HIERARCHY (&qRoom)
	|					OR &qIsEmptyRoom)
	|			AND (NOT RoomSalesForecastTotals.Room IN (&qRooms2IgnoreList)
	|					OR &qRooms2IgnoreListIsEmpty)
	|			AND (RoomSalesForecastTotals.RoomType IN HIERARCHY (&qRoomType)
	|					OR &qIsEmptyRoomType)
	|			AND (RoomSalesForecastTotals.Service IN HIERARCHY (&qService)
	|					OR &qIsEmptyService)
	|			AND (RoomSalesForecastTotals.Service IN (&qServicesList)
	|					OR NOT &qUseServicesList)
	|			AND (NOT &qWithAllotments
	|					OR &qWithAllotments
	|						AND NOT ISNULL(RoomSalesForecastTotals.ParentDoc.RoomQuota.IsCommitment, FALSE))
	|			AND (NOT &qFilterByReservationCreationDate
	|						AND NOT &qLimitByTodaysDate
	|					OR NOT &qFilterByReservationCreationDate
	|						AND &qLimitByTodaysDate
	|						AND NOT &qByGroupCreationDate
	|						AND (RoomSalesForecastTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesForecastTotals.ParentDoc.Date <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(RoomSalesForecastTotals.AccountingDate, YEAR), DAY, &qTodaysDay), DAY)
	|							OR NOT RoomSalesForecastTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesForecastTotals.ParentDoc.Reservation.Date <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(RoomSalesForecastTotals.AccountingDate, YEAR), DAY, &qTodaysDay), DAY))
	|					OR NOT &qFilterByReservationCreationDate
	|						AND &qLimitByTodaysDate
	|						AND &qByGroupCreationDate
	|						AND NOT RoomSalesForecastTotals.GuestGroup.CreateDate IS NULL
	|						AND RoomSalesForecastTotals.GuestGroup.CreateDate <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(RoomSalesForecastTotals.AccountingDate, YEAR), DAY, &qTodaysDay), DAY)
	|					OR &qFilterByReservationCreationDate
	|						AND NOT &qNoYear
	|						AND NOT &qByGroupCreationDate
	|						AND RoomSalesForecastTotals.ParentDoc.Date >= &qDateFrom
	|						AND (RoomSalesForecastTotals.ParentDoc.Date <= &qDateTo
	|							OR &qDateToIsEmpty)
	|					OR &qFilterByReservationCreationDate
	|						AND NOT &qNoYear
	|						AND &qByGroupCreationDate
	|						AND NOT RoomSalesForecastTotals.GuestGroup.CreateDate IS NULL
	|						AND RoomSalesForecastTotals.GuestGroup.CreateDate >= &qDateFrom
	|						AND (&qDateToIsEmpty
	|							OR RoomSalesForecastTotals.GuestGroup.CreateDate <= &qDateTo)
	|					OR &qFilterByReservationCreationDate
	|						AND &qNoYear
	|						AND NOT &qByGroupCreationDate
	|						AND NOT RoomSalesForecastTotals.ParentDoc.Date IS NULL
	|						AND CASE
	|							WHEN &qShiftFrom = 1
	|									AND DATEADD(RoomSalesForecastTotals.ParentDoc.Date, YEAR, 2 - YEAR(RoomSalesForecastTotals.ParentDoc.Date)) <= &qDateTo
	|								THEN TRUE
	|							WHEN &qShiftFrom = 1
	|									AND DATEADD(RoomSalesForecastTotals.ParentDoc.Date, YEAR, 1 - YEAR(RoomSalesForecastTotals.ParentDoc.Date)) >= &qDateFrom
	|								THEN TRUE
	|							WHEN &qShiftFrom = 2
	|									AND DATEADD(RoomSalesForecastTotals.ParentDoc.Date, YEAR, 2 - YEAR(RoomSalesForecastTotals.ParentDoc.Date)) >= &qDateFrom
	|									AND DATEADD(RoomSalesForecastTotals.ParentDoc.Date, YEAR, 2 - YEAR(RoomSalesForecastTotals.ParentDoc.Date)) <= &qDateTo
	|								THEN TRUE
	|							ELSE FALSE
	|						END
	|					OR &qFilterByReservationCreationDate
	|						AND &qNoYear
	|						AND &qByGroupCreationDate
	|						AND NOT RoomSalesForecastTotals.GuestGroup.CreateDate IS NULL
	|						AND CASE
	|							WHEN &qShiftFrom = 1
	|									AND DATEADD(RoomSalesForecastTotals.GuestGroup.CreateDate, YEAR, 2 - YEAR(RoomSalesForecastTotals.GuestGroup.CreateDate)) <= &qDateTo
	|								THEN TRUE
	|							WHEN &qShiftFrom = 1
	|									AND DATEADD(RoomSalesForecastTotals.GuestGroup.CreateDate, YEAR, 1 - YEAR(RoomSalesForecastTotals.GuestGroup.CreateDate)) >= &qDateFrom
	|								THEN TRUE
	|							WHEN &qShiftFrom = 2
	|									AND DATEADD(RoomSalesForecastTotals.GuestGroup.CreateDate, YEAR, 2 - YEAR(RoomSalesForecastTotals.GuestGroup.CreateDate)) >= &qDateFrom
	|									AND DATEADD(RoomSalesForecastTotals.GuestGroup.CreateDate, YEAR, 2 - YEAR(RoomSalesForecastTotals.GuestGroup.CreateDate)) <= &qDateTo
	|								THEN TRUE
	|							ELSE FALSE
	|						END)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			RoomTypesListPerDay.Period,
	|			NULL,
	|			RoomTypesListPerDay.Hotel,
	|			RoomTypesListPerDay.Hotel.ReportingCurrency,
	|			NULL,
	|			RoomTypesListPerDay.RoomType,
	|			NULL,
	|			NULL,
	|			NULL,
	|			VALUE(Catalog.MarketingCodes.EmptyRef),
	|			VALUE(Catalog.SourcesOfBusiness.EmptyRef),
	|			NULL,
	|			NULL,
	|			NULL,
	|			RoomTypesListPerDay.Period,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
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
	|			1,
	|			NULL
	|		FROM
	|			HotelInventoryTotalsPerDay AS RoomTypesListPerDay
	|		WHERE
	|			&qUsePerDayStats
	|			AND &qUsePerRoomTypeStats
	|			AND &qUseChoosenCalendarStats
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			RoomQuotaSales.Period,
	|			RoomQuotaSales.Hotel.Company,
	|			RoomQuotaSales.Hotel,
	|			RoomQuotaSales.Hotel.ReportingCurrency,
	|			NULL,
	|			RoomQuotaSales.RoomType,
	|			RoomQuotaSales.RoomQuota.RoomRate,
	|			NULL,
	|			RoomQuotaSales.RoomQuota.ClientType,
	|			RoomQuotaSales.RoomQuota.MarketingCode,
	|			RoomQuotaSales.RoomQuota.SourceOfBusiness,
	|			RoomQuotaSales.Service,
	|			RoomQuotaSales.CalendarDayType,
	|			NULL,
	|			RoomQuotaSales.Period,
	|			NULL,
	|			RoomQuotaSales.RoomQuota,
	|			NULL,
	|			RoomQuotaSales.RoomQuota.Customer,
	|			RoomQuotaSales.RoomQuota.Contract,
	|			RoomQuotaSales.RoomQuota.Agent,
	|			NULL,
	|			NULL,
	|			NULL,
	|			RoomQuotaSales.AllotmentPrice,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			RoomQuotaSales.RoomQuota.RoomRate.Discount,
	|			RoomQuotaSales.RoomQuota.RoomRate.DiscountType,
	|			NULL,
	|			RoomQuotaSales.RoomQuota.Agent.AgentCommission,
	|			RoomQuotaSales.RoomQuota.Agent.AgentCommissionType,
	|			RoomQuotaSales.RoomQuota.Customer.PlannedPaymentMethod,
	|			RoomQuotaSales.VATRate,
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
	|			RoomQuotaSales.Counter,
	|			0,
	|			1,
	|			NULL
	|		FROM
	|			RoomQuotaSales AS RoomQuotaSales
	|		WHERE
	|			&qWithAllotments) AS RoomSales
	|			LEFT JOIN (SELECT
	|				CalendarDays.CalendarDayType AS CalendarDayType,
	|				CalendarDays.AccountingDate AS AccountingDate
	|			FROM
	|				InformationRegister.CalendarDays.SliceLast(&qPriceCalculationDate, Calendar = &qCalendar) AS CalendarDays) AS CalendarDayTypesByChoosenCalendar
	|			ON RoomSales.AccountingDate = CalendarDayTypesByChoosenCalendar.AccountingDate) AS RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay
	|
	|GROUP BY
	|	RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.Hotel,
	|	RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.RoomType,
	|	RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.CalendarDayType,
	|	RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.Period,
	|	RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.ServiceDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomTotalSales.Hotel AS Hotel,
	|	CASE
	|		WHEN &qWithAllotments
	|			THEN ISNULL(RoomTotalSales.TotalSalesAmount, 0) + ISNULL(RoomQuotaTotalSales.AllotmentAmount, 0)
	|		ELSE ISNULL(RoomTotalSales.TotalSalesAmount, 0)
	|	END AS TotalSalesAmount,
	|	CASE
	|		WHEN &qWithAllotments
	|			THEN ISNULL(RoomTotalSales.TotalBedsRented, 0) + ISNULL(RoomQuotaTotalSales.BedsInQuotaClosingBalance, 0)
	|		ELSE ISNULL(RoomTotalSales.TotalBedsRented, 0)
	|	END AS TotalBedsRented,
	|	CASE
	|		WHEN &qWithAllotments
	|			THEN ISNULL(RoomTotalSales.TotalRoomsRented, 0) + ISNULL(RoomQuotaTotalSales.RoomsInQuotaClosingBalance, 0)
	|		ELSE ISNULL(RoomTotalSales.TotalRoomsRented, 0)
	|	END AS TotalRoomsRented
	|INTO RoomTotalSales
	|FROM
	|	(SELECT
	|		TotalSales.Hotel AS Hotel,
	|		SUM(TotalSales.SalesTurnover) AS TotalSalesAmount,
	|		SUM(TotalSales.GuestDaysTurnover) AS TotalGuestDays,
	|		SUM(TotalSales.BedsRentedTurnover) AS TotalBedsRented,
	|		SUM(TotalSales.RoomsRentedTurnover) AS TotalRoomsRented
	|	FROM
	|		(SELECT
	|			RoomTotalSales.Hotel AS Hotel,
	|			RoomTotalSales.SalesTurnover AS SalesTurnover,
	|			RoomTotalSales.GuestDaysTurnover AS GuestDaysTurnover,
	|			RoomTotalSales.BedsRentedTurnover AS BedsRentedTurnover,
	|			RoomTotalSales.RoomsRentedTurnover AS RoomsRentedTurnover
	|		FROM
	|			AccumulationRegister.Sales.Turnovers(
	|					&qPeriodFrom,
	|					&qPeriodTo,
	|					Period,
	|					Hotel IN HIERARCHY (&qHotel)
	|						AND (&qHideCorrections
	|							OR NOT &qHideCorrections
	|								AND NOT IsCorrection)
	|						AND (Room IN HIERARCHY (&qRoom)
	|							OR &qIsEmptyRoom)
	|						AND (NOT Room IN (&qRooms2IgnoreList)
	|							OR &qRooms2IgnoreListIsEmpty)
	|						AND (RoomType IN HIERARCHY (&qRoomType)
	|							OR &qIsEmptyRoomType)
	|						AND (Service IN HIERARCHY (&qService)
	|							OR &qIsEmptyService)
	|						AND (Service IN (&qServicesList)
	|							OR NOT &qUseServicesList)
	|						AND (NOT &qWithAllotments
	|							OR &qWithAllotments
	|								AND NOT ISNULL(ParentDoc.RoomQuota.IsCommitment, FALSE))
	|						AND (NOT &qFilterByReservationCreationDate
	|								AND NOT &qLimitByTodaysDate
	|							OR NOT &qFilterByReservationCreationDate
	|								AND &qLimitByTodaysDate
	|								AND NOT &qByGroupCreationDate
	|								AND (ParentDoc.Reservation.Date IS NULL
	|										AND ParentDoc.Date <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(AccountingDate, YEAR), DAY, &qTodaysDay), DAY)
	|									OR NOT ParentDoc.Reservation.Date IS NULL
	|										AND ParentDoc.Reservation.Date <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(AccountingDate, YEAR), DAY, &qTodaysDay), DAY))
	|							OR NOT &qFilterByReservationCreationDate
	|								AND &qLimitByTodaysDate
	|								AND &qByGroupCreationDate
	|								AND NOT GuestGroup.CreateDate IS NULL
	|								AND GuestGroup.CreateDate <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(AccountingDate, YEAR), DAY, &qTodaysDay), DAY)
	|							OR &qFilterByReservationCreationDate
	|								AND NOT &qNoYear
	|								AND NOT &qByGroupCreationDate
	|								AND (ParentDoc.Reservation.Date IS NULL
	|										AND ParentDoc.Date >= &qDateFrom
	|									OR NOT ParentDoc.Reservation.Date IS NULL
	|										AND ParentDoc.Reservation.Date >= &qDateFrom)
	|								AND (&qDateToIsEmpty
	|									OR ParentDoc.Reservation.Date IS NULL
	|										AND ParentDoc.Date <= &qDateTo
	|									OR NOT ParentDoc.Reservation.Date IS NULL
	|										AND ParentDoc.Reservation.Date <= &qDateTo)
	|							OR &qFilterByReservationCreationDate
	|								AND NOT &qNoYear
	|								AND &qByGroupCreationDate
	|								AND NOT GuestGroup.CreateDate IS NULL
	|								AND GuestGroup.CreateDate >= &qDateFrom
	|								AND (&qDateToIsEmpty
	|									OR GuestGroup.CreateDate <= &qDateTo)
	|							OR &qFilterByReservationCreationDate
	|								AND &qNoYear
	|								AND NOT &qByGroupCreationDate
	|								AND CASE
	|									WHEN &qShiftFrom = 1
	|											AND ParentDoc.Reservation.Date IS NULL
	|											AND DATEADD(ParentDoc.Date, YEAR, 2 - YEAR(ParentDoc.Date)) <= &qDateTo
	|										THEN TRUE
	|									WHEN &qShiftFrom = 1
	|											AND ParentDoc.Reservation.Date IS NULL
	|											AND DATEADD(ParentDoc.Date, YEAR, 1 - YEAR(ParentDoc.Date)) >= &qDateFrom
	|										THEN TRUE
	|									WHEN &qShiftFrom = 2
	|											AND ParentDoc.Reservation.Date IS NULL
	|											AND DATEADD(ParentDoc.Date, YEAR, 2 - YEAR(ParentDoc.Date)) >= &qDateFrom
	|											AND DATEADD(ParentDoc.Date, YEAR, 2 - YEAR(ParentDoc.Date)) <= &qDateTo
	|										THEN TRUE
	|									WHEN &qShiftFrom = 1
	|											AND NOT ParentDoc.Reservation.Date IS NULL
	|											AND DATEADD(ParentDoc.Reservation.Date, YEAR, 2 - YEAR(ParentDoc.Reservation.Date)) <= &qDateTo
	|										THEN TRUE
	|									WHEN &qShiftFrom = 1
	|											AND NOT ParentDoc.Reservation.Date IS NULL
	|											AND DATEADD(ParentDoc.Reservation.Date, YEAR, 1 - YEAR(ParentDoc.Reservation.Date)) >= &qDateFrom
	|										THEN TRUE
	|									WHEN &qShiftFrom = 2
	|											AND NOT ParentDoc.Reservation.Date IS NULL
	|											AND DATEADD(ParentDoc.Reservation.Date, YEAR, 2 - YEAR(ParentDoc.Reservation.Date)) >= &qDateFrom
	|											AND DATEADD(ParentDoc.Reservation.Date, YEAR, 2 - YEAR(ParentDoc.Reservation.Date)) <= &qDateTo
	|										THEN TRUE
	|									ELSE FALSE
	|								END
	|							OR &qFilterByReservationCreationDate
	|								AND &qNoYear
	|								AND &qByGroupCreationDate
	|								AND NOT GuestGroup.CreateDate IS NULL
	|								AND CASE
	|									WHEN &qShiftFrom = 1
	|											AND DATEADD(GuestGroup.CreateDate, YEAR, 2 - YEAR(GuestGroup.CreateDate)) <= &qDateTo
	|										THEN TRUE
	|									WHEN &qShiftFrom = 1
	|											AND DATEADD(GuestGroup.CreateDate, YEAR, 1 - YEAR(GuestGroup.CreateDate)) >= &qDateFrom
	|										THEN TRUE
	|									WHEN &qShiftFrom = 2
	|											AND DATEADD(GuestGroup.CreateDate, YEAR, 2 - YEAR(GuestGroup.CreateDate)) >= &qDateFrom
	|											AND DATEADD(GuestGroup.CreateDate, YEAR, 2 - YEAR(GuestGroup.CreateDate)) <= &qDateTo
	|										THEN TRUE
	|									ELSE FALSE
	|								END)) AS RoomTotalSales
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			RoomTotalSalesForecast.Hotel,
	|			RoomTotalSalesForecast.SalesTurnover,
	|			RoomTotalSalesForecast.GuestDaysTurnover,
	|			RoomTotalSalesForecast.BedsRentedTurnover,
	|			RoomTotalSalesForecast.RoomsRentedTurnover
	|		FROM
	|			AccumulationRegister.SalesForecast.Turnovers(
	|					&qForecastPeriodFrom,
	|					&qForecastPeriodTo,
	|					Period,
	|					Hotel IN HIERARCHY (&qHotel)
	|						AND &qUseForecast
	|						AND (Room IN HIERARCHY (&qRoom)
	|							OR &qIsEmptyRoom)
	|						AND (NOT Room IN (&qRooms2IgnoreList)
	|							OR &qRooms2IgnoreListIsEmpty)
	|						AND (RoomType IN HIERARCHY (&qRoomType)
	|							OR &qIsEmptyRoomType)
	|						AND (Service IN HIERARCHY (&qService)
	|							OR &qIsEmptyService)
	|						AND (Service IN (&qServicesList)
	|							OR NOT &qUseServicesList)
	|						AND (NOT &qWithAllotments
	|							OR &qWithAllotments
	|								AND NOT ISNULL(ParentDoc.RoomQuota.IsCommitment, FALSE))
	|						AND (NOT &qFilterByReservationCreationDate
	|								AND NOT &qLimitByTodaysDate
	|							OR NOT &qFilterByReservationCreationDate
	|								AND &qLimitByTodaysDate
	|								AND NOT &qByGroupCreationDate
	|								AND (ParentDoc.Reservation.Date IS NULL
	|										AND ParentDoc.Date <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(AccountingDate, YEAR), DAY, &qTodaysDay), DAY)
	|									OR NOT ParentDoc.Reservation.Date IS NULL
	|										AND ParentDoc.Reservation.Date <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(AccountingDate, YEAR), DAY, &qTodaysDay), DAY))
	|							OR NOT &qFilterByReservationCreationDate
	|								AND &qLimitByTodaysDate
	|								AND &qByGroupCreationDate
	|								AND NOT GuestGroup.CreateDate IS NULL
	|								AND GuestGroup.CreateDate <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(AccountingDate, YEAR), DAY, &qTodaysDay), DAY)
	|							OR &qFilterByReservationCreationDate
	|								AND NOT &qNoYear
	|								AND NOT &qByGroupCreationDate
	|								AND ParentDoc.Date >= &qDateFrom
	|								AND (ParentDoc.Date <= &qDateTo
	|									OR &qDateToIsEmpty)
	|							OR &qFilterByReservationCreationDate
	|								AND NOT &qNoYear
	|								AND &qByGroupCreationDate
	|								AND NOT GuestGroup.CreateDate IS NULL
	|								AND GuestGroup.CreateDate >= &qDateFrom
	|								AND (&qDateToIsEmpty
	|									OR GuestGroup.CreateDate <= &qDateTo)
	|							OR &qFilterByReservationCreationDate
	|								AND &qNoYear
	|								AND NOT &qByGroupCreationDate
	|								AND NOT ParentDoc.Date IS NULL
	|								AND CASE
	|									WHEN &qShiftFrom = 1
	|											AND DATEADD(ParentDoc.Date, YEAR, 2 - YEAR(ParentDoc.Date)) <= &qDateTo
	|										THEN TRUE
	|									WHEN &qShiftFrom = 1
	|											AND DATEADD(ParentDoc.Date, YEAR, 1 - YEAR(ParentDoc.Date)) >= &qDateFrom
	|										THEN TRUE
	|									WHEN &qShiftFrom = 2
	|											AND DATEADD(ParentDoc.Date, YEAR, 2 - YEAR(ParentDoc.Date)) >= &qDateFrom
	|											AND DATEADD(ParentDoc.Date, YEAR, 2 - YEAR(ParentDoc.Date)) <= &qDateTo
	|										THEN TRUE
	|									ELSE FALSE
	|								END
	|							OR &qFilterByReservationCreationDate
	|								AND &qNoYear
	|								AND &qByGroupCreationDate
	|								AND NOT GuestGroup.CreateDate IS NULL
	|								AND CASE
	|									WHEN &qShiftFrom = 1
	|											AND DATEADD(GuestGroup.CreateDate, YEAR, 2 - YEAR(GuestGroup.CreateDate)) <= &qDateTo
	|										THEN TRUE
	|									WHEN &qShiftFrom = 1
	|											AND DATEADD(GuestGroup.CreateDate, YEAR, 1 - YEAR(GuestGroup.CreateDate)) >= &qDateFrom
	|										THEN TRUE
	|									WHEN &qShiftFrom = 2
	|											AND DATEADD(GuestGroup.CreateDate, YEAR, 2 - YEAR(GuestGroup.CreateDate)) >= &qDateFrom
	|											AND DATEADD(GuestGroup.CreateDate, YEAR, 2 - YEAR(GuestGroup.CreateDate)) <= &qDateTo
	|										THEN TRUE
	|									ELSE FALSE
	|								END)) AS RoomTotalSalesForecast) AS TotalSales
	|	
	|	GROUP BY
	|		TotalSales.Hotel) AS RoomTotalSales
	|		LEFT JOIN RoomQuotaTotalSales AS RoomQuotaTotalSales
	|		ON RoomTotalSales.Hotel = RoomQuotaTotalSales.Hotel
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomSalesTurnovers.Company AS Company,
	|	RoomSalesTurnovers.Hotel AS Hotel,
	|	RoomSalesTurnovers.ReportingCurrency AS ReportingCurrency,
	|	RoomSalesTurnovers.RoomQuota AS RoomQuota,
	|	RoomSalesTurnovers.Room AS Room,
	|	RoomSalesTurnovers.RoomType AS RoomType,
	|	RoomSalesTurnovers.RoomRate AS RoomRate,
	|	RoomSalesTurnovers.CalendarDayType AS CalendarDayType,
	|	RoomSalesTurnovers.PriceTag AS PriceTag,
	|	RoomSalesTurnovers.AccommodationType AS AccommodationType,
	|	RoomSalesTurnovers.ClientType AS ClientType,
	|	RoomSalesTurnovers.MarketingCode AS MarketingCode,
	|	RoomSalesTurnovers.SourceOfBusiness AS SourceOfBusiness,
	|	RoomSalesTurnovers.Service AS Service,
	|	RoomSalesTurnovers.AccountingDate AS AccountingDate,
	|	RoomSalesTurnovers.ParentDoc AS ParentDoc,
	|	RoomSalesTurnovers.RoomPrice AS RoomPrice,
	|	RoomSalesTurnovers.Sales AS Sales,
	|	RoomSalesTurnovers.SalesWithoutCommission AS SalesWithoutCommission,
	|	RoomSalesTurnovers.RoomRevenue AS RoomRevenue,
	|	RoomSalesTurnovers.RoomRevenueWithoutCommission AS RoomRevenueWithoutCommission,
	|	RoomSalesTurnovers.InPriceRevenue AS InPriceRevenue,
	|	RoomSalesTurnovers.InPriceRevenueWithoutCommission AS InPriceRevenueWithoutCommission,
	|	RoomSalesTurnovers.ExtraBedRevenue AS ExtraBedRevenue,
	|	RoomSalesTurnovers.RoomRevenueWithoutExtraBed AS RoomRevenueWithoutExtraBed,
	|	RoomSalesTurnovers.SalesWithoutVAT AS SalesWithoutVAT,
	|	RoomSalesTurnovers.SalesWithoutVATWithoutCommission AS SalesWithoutVATWithoutCommission,
	|	RoomSalesTurnovers.RoomRevenueWithoutVAT AS RoomRevenueWithoutVAT,
	|	RoomSalesTurnovers.RoomRevenueWithoutVATWithoutCommission AS RoomRevenueWithoutVATWithoutCommission,
	|	RoomSalesTurnovers.Sales - RoomSalesTurnovers.RoomRevenue AS ExtraServicesRevenue,
	|	RoomSalesTurnovers.SalesWithoutVAT - RoomSalesTurnovers.RoomRevenueWithoutVAT AS ExtraServicesRevenueWithoutVAT,
	|	RoomSalesTurnovers.InPriceRevenueWithoutVAT AS InPriceRevenueWithoutVAT,
	|	RoomSalesTurnovers.InPriceRevenueWithoutVATWithoutCommission AS InPriceRevenueWithoutVATWithoutCommission,
	|	RoomSalesTurnovers.ExtraBedRevenueWithoutVAT AS ExtraBedRevenueWithoutVAT,
	|	RoomSalesTurnovers.RoomRevenueWithoutExtraBedWithoutVAT AS RoomRevenueWithoutExtraBedWithoutVAT,
	|	RoomSalesTurnovers.CommissionSum AS CommissionSum,
	|	RoomSalesTurnovers.CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|	RoomSalesTurnovers.DiscountSum AS DiscountSum,
	|	RoomSalesTurnovers.DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|	RoomSalesTurnovers.ExtraBedDiscountSum AS ExtraBedDiscountSum,
	|	RoomSalesTurnovers.DiscountSumWithoutExtraBed AS DiscountSumWithoutExtraBed,
	|	RoomSalesTurnovers.RevenueSegmentRoomSales AS RevenueSegmentRoomSales,
	|	RoomSalesTurnovers.RevenueSegmentRoomSalesWithoutVAT AS RevenueSegmentRoomSalesWithoutVAT,
	|	RoomSalesTurnovers.RevenueSegmentFaBSales AS RevenueSegmentFaBSales,
	|	RoomSalesTurnovers.RevenueSegmentFaBSalesWithoutVAT AS RevenueSegmentFaBSalesWithoutVAT,
	|	RoomSalesTurnovers.RevenueSegmentSPASales AS RevenueSegmentSPASales,
	|	RoomSalesTurnovers.RevenueSegmentSPASalesWithoutVAT AS RevenueSegmentSPASalesWithoutVAT,
	|	RoomSalesTurnovers.RevenueSegmentConferenceSales AS RevenueSegmentConferenceSales,
	|	RoomSalesTurnovers.RevenueSegmentConferenceSalesWithoutVAT AS RevenueSegmentConferenceSalesWithoutVAT,
	|	RoomSalesTurnovers.RevenueSegmentOtherSales AS RevenueSegmentOtherSales,
	|	RoomSalesTurnovers.RevenueSegmentOtherSalesWithoutVAT AS RevenueSegmentOtherSalesWithoutVAT,
	|	RoomSalesTurnovers.RoomsRented AS RoomsRented,
	|	RoomSalesTurnovers.BedsRented AS BedsRented,
	|	RoomSalesTurnovers.AdditionalBedsRented AS AdditionalBedsRented,
	|	RoomSalesTurnovers.GuestDays AS GuestDays,
	|	RoomSalesTurnovers.GuestDaysWithoutExtraBed AS GuestDaysWithoutExtraBed,
	|	RoomSalesTurnovers.ExtraBedGuestDays AS ExtraBedGuestDays,
	|	RoomSalesTurnovers.GuestsCheckedIn AS GuestsCheckedIn,
	|	RoomSalesTurnovers.RoomsCheckedIn AS RoomsCheckedIn,
	|	RoomSalesTurnovers.BedsCheckedIn AS BedsCheckedIn,
	|	RoomSalesTurnovers.AdditionalBedsCheckedIn AS AdditionalBedsCheckedIn,
	|	CASE
	|		WHEN RoomSalesTurnovers.RoomsCheckedIn <> 0
	|			THEN CAST(RoomSalesTurnovers.BookingWindow / RoomSalesTurnovers.RoomsCheckedIn AS NUMBER(10, 0))
	|		ELSE 0
	|	END AS BookingWindow,
	|	CASE
	|		WHEN RoomSalesTurnovers.RoomsCheckedIn <> 0
	|			THEN CAST(RoomSalesTurnovers.BookingWindow / RoomSalesTurnovers.RoomsCheckedIn AS NUMBER(10, 0))
	|		ELSE 0
	|	END AS BookingWindowDimension,
	|	CASE
	|		WHEN ISNULL(RoomSalesTurnovers.GuestsCheckedIn, 0) = 0
	|			THEN 0
	|		ELSE ISNULL(RoomSalesTurnovers.GuestDays, 0) / ISNULL(RoomSalesTurnovers.GuestsCheckedIn, 0)
	|	END AS ALS,
	|	RoomSalesTurnovers.Quantity AS Quantity,
	|	RoomSalesTurnovers.RoomsPerPeriod AS RoomsPerPeriod,
	|	RoomSalesTurnovers.BedsPerPeriod AS BedsPerPeriod,
	|	RoomSalesTurnovers.RoomsBlockedPerPeriod AS RoomsBlockedPerPeriod,
	|	RoomSalesTurnovers.BedsBlockedPerPeriod AS BedsBlockedPerPeriod,
	|	RoomSalesTurnovers.RoomsPerRoomTypePerDay AS RoomsPerRoomTypePerDay,
	|	RoomSalesTurnovers.BedsPerRoomTypePerDay AS BedsPerRoomTypePerDay,
	|	RoomSalesTurnovers.RoomsBlockedPerRoomTypePerDay AS RoomsBlockedPerRoomTypePerDay,
	|	RoomSalesTurnovers.BedsBlockedPerRoomTypePerDay AS BedsBlockedPerRoomTypePerDay,
	|	RoomSalesTurnovers.RoomsPerRoomTypePerMonth AS RoomsPerRoomTypePerMonth,
	|	RoomSalesTurnovers.BedsPerRoomTypePerMonth AS BedsPerRoomTypePerMonth,
	|	RoomSalesTurnovers.RoomsBlockedPerRoomTypePerMonth AS RoomsBlockedPerRoomTypePerMonth,
	|	RoomSalesTurnovers.BedsBlockedPerRoomTypePerMonth AS BedsBlockedPerRoomTypePerMonth,
	|	RoomSalesTurnovers.RoomsPerRoomTypePerPeriod AS RoomsPerRoomTypePerPeriod,
	|	RoomSalesTurnovers.BedsPerRoomTypePerPeriod AS BedsPerRoomTypePerPeriod,
	|	RoomSalesTurnovers.RoomsBlockedPerRoomTypePerPeriod AS RoomsBlockedPerRoomTypePerPeriod,
	|	RoomSalesTurnovers.BedsBlockedPerRoomTypePerPeriod AS BedsBlockedPerRoomTypePerPeriod,
	|	RoomSalesTurnovers.RoomsPerRoomTypeAndCalendarDayTypePerDay AS RoomsPerRoomTypeAndCalendarDayTypePerDay,
	|	RoomSalesTurnovers.BedsPerRoomTypeAndCalendarDayTypePerDay AS BedsPerRoomTypeAndCalendarDayTypePerDay,
	|	RoomSalesTurnovers.RoomsBlockedPerRoomTypeAndCalendarDayTypePerDay AS RoomsBlockedPerRoomTypeAndCalendarDayTypePerDay,
	|	RoomSalesTurnovers.BedsBlockedPerRoomTypeAndCalendarDayTypePerDay AS BedsBlockedPerRoomTypeAndCalendarDayTypePerDay,
	|	RoomSalesTurnovers.RoomsPerRoomTypeAndChoosenCalendarDayTypePerDay AS RoomsPerRoomTypeAndChoosenCalendarDayTypePerDay,
	|	RoomSalesTurnovers.BedsPerRoomTypeAndChoosenCalendarDayTypePerDay AS BedsPerRoomTypeAndChoosenCalendarDayTypePerDay,
	|	RoomSalesTurnovers.RoomsBlockedPerRoomTypeAndChoosenCalendarDayTypePerDay AS RoomsBlockedPerRoomTypeAndChoosenCalendarDayTypePerDay,
	|	RoomSalesTurnovers.BedsBlockedPerRoomTypeAndChoosenCalendarDayTypePerDay AS BedsBlockedPerRoomTypeAndChoosenCalendarDayTypePerDay,
	|	CASE
	|		WHEN RoomSalesTurnovers.RoomsRented = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.RoomRevenue / RoomSalesTurnovers.RoomsRented
	|	END AS AverageRoomPrice,
	|	CASE
	|		WHEN RoomSalesTurnovers.BedsRented = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.RoomRevenue / RoomSalesTurnovers.BedsRented
	|	END AS AverageBedPrice,
	|	CASE
	|		WHEN RoomSalesTurnovers.RoomsRented = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.RoomRevenueWithoutVAT / RoomSalesTurnovers.RoomsRented
	|	END AS AverageRoomPriceWithoutVAT,
	|	CASE
	|		WHEN RoomSalesTurnovers.BedsRented = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.RoomRevenueWithoutVAT / RoomSalesTurnovers.BedsRented
	|	END AS AverageBedPriceWithoutVAT,
	|	CASE
	|		WHEN RoomSalesTurnovers.RoomsPerPeriod = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.RoomRevenue / RoomSalesTurnovers.RoomsPerPeriod
	|	END AS RevPAR,
	|	CASE
	|		WHEN RoomSalesTurnovers.BedsPerPeriod = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.RoomRevenue / RoomSalesTurnovers.BedsPerPeriod
	|	END AS RevPAB,
	|	CASE
	|		WHEN RoomSalesTurnovers.RoomsPerPeriod = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.RoomRevenueWithoutVAT / RoomSalesTurnovers.RoomsPerPeriod
	|	END AS RevPARWithoutVAT,
	|	CASE
	|		WHEN RoomSalesTurnovers.BedsPerPeriod = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.RoomRevenueWithoutVAT / RoomSalesTurnovers.BedsPerPeriod
	|	END AS RevPABWithoutVAT,
	|	CASE
	|		WHEN RoomSalesTurnovers.RoomsPerRoomTypePerDay = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.RoomRevenue / RoomSalesTurnovers.RoomsPerRoomTypePerDay
	|	END AS RevPARPerRoomTypePerDay,
	|	CASE
	|		WHEN RoomSalesTurnovers.BedsPerRoomTypePerDay = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.RoomRevenue / RoomSalesTurnovers.BedsPerRoomTypePerDay
	|	END AS RevPABPerRoomTypePerDay,
	|	CASE
	|		WHEN RoomSalesTurnovers.RoomsPerRoomTypePerDay = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.RoomRevenueWithoutVAT / RoomSalesTurnovers.RoomsPerRoomTypePerDay
	|	END AS RevPARWithoutVATPerRoomTypePerDay,
	|	CASE
	|		WHEN RoomSalesTurnovers.BedsPerRoomTypePerDay = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.RoomRevenueWithoutVAT / RoomSalesTurnovers.BedsPerRoomTypePerDay
	|	END AS RevPABWithoutVATPerRoomTypePerDay,
	|	CASE
	|		WHEN RoomSalesTurnovers.RoomsPerRoomTypePerMonth = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.RoomRevenue / RoomSalesTurnovers.RoomsPerRoomTypePerMonth
	|	END AS RevPARPerRoomTypePerMonth,
	|	CASE
	|		WHEN RoomSalesTurnovers.BedsPerRoomTypePerMonth = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.RoomRevenue / RoomSalesTurnovers.BedsPerRoomTypePerMonth
	|	END AS RevPABPerRoomTypePerMonth,
	|	CASE
	|		WHEN RoomSalesTurnovers.RoomsPerRoomTypePerMonth = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.RoomRevenueWithoutVAT / RoomSalesTurnovers.RoomsPerRoomTypePerMonth
	|	END AS RevPARWithoutVATPerRoomTypePerMonth,
	|	CASE
	|		WHEN RoomSalesTurnovers.BedsPerRoomTypePerMonth = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.RoomRevenueWithoutVAT / RoomSalesTurnovers.BedsPerRoomTypePerMonth
	|	END AS RevPABWithoutVATPerRoomTypePerMonth,
	|	CASE
	|		WHEN RoomSalesTurnovers.RoomsPerRoomTypePerPeriod = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.RoomRevenue / RoomSalesTurnovers.RoomsPerRoomTypePerPeriod
	|	END AS RevPARPerRoomTypePerPeriod,
	|	CASE
	|		WHEN RoomSalesTurnovers.BedsPerRoomTypePerPeriod = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.RoomRevenue / RoomSalesTurnovers.BedsPerRoomTypePerPeriod
	|	END AS RevPABPerRoomTypePerPeriod,
	|	CASE
	|		WHEN RoomSalesTurnovers.RoomsPerRoomTypePerPeriod = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.RoomRevenueWithoutVAT / RoomSalesTurnovers.RoomsPerRoomTypePerPeriod
	|	END AS RevPARWithoutVATPerRoomTypePerPeriod,
	|	CASE
	|		WHEN RoomSalesTurnovers.BedsPerRoomTypePerPeriod = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.RoomRevenueWithoutVAT / RoomSalesTurnovers.BedsPerRoomTypePerPeriod
	|	END AS RevPABWithoutVATPerRoomTypePerPeriod,
	|	CASE
	|		WHEN RoomSalesTurnovers.RoomsPerPeriod = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.RoomsRented * 100 / RoomSalesTurnovers.RoomsPerPeriod
	|	END AS RoomsRentedPercent,
	|	CASE
	|		WHEN RoomSalesTurnovers.BedsPerPeriod = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.BedsRented * 100 / RoomSalesTurnovers.BedsPerPeriod
	|	END AS BedsRentedPercent,
	|	CASE
	|		WHEN RoomSalesTurnovers.RoomsPerPeriod - RoomSalesTurnovers.RoomsBlockedPerPeriod = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.RoomsRented * 100 / (RoomSalesTurnovers.RoomsPerPeriod - RoomSalesTurnovers.RoomsBlockedPerPeriod)
	|	END AS RoomsRentedPercentWithRoomBlocks,
	|	CASE
	|		WHEN RoomSalesTurnovers.BedsPerPeriod - RoomSalesTurnovers.BedsBlockedPerPeriod = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.BedsRented * 100 / (RoomSalesTurnovers.BedsPerPeriod - RoomSalesTurnovers.BedsBlockedPerPeriod)
	|	END AS BedsRentedPercentWithRoomBlocks,
	|	CASE
	|		WHEN RoomSalesTurnovers.RoomsPerRoomTypePerDay = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.RoomsRented * 100 / RoomSalesTurnovers.RoomsPerRoomTypePerDay
	|	END AS RoomsRentedPercentPerRoomTypePerDay,
	|	CASE
	|		WHEN RoomSalesTurnovers.BedsPerRoomTypePerDay = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.BedsRented * 100 / RoomSalesTurnovers.BedsPerRoomTypePerDay
	|	END AS BedsRentedPercentPerRoomTypePerDay,
	|	CASE
	|		WHEN RoomSalesTurnovers.RoomsPerRoomTypePerDay - RoomSalesTurnovers.RoomsBlockedPerRoomTypePerDay = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.RoomsRented * 100 / (RoomSalesTurnovers.RoomsPerRoomTypePerDay - RoomSalesTurnovers.RoomsBlockedPerRoomTypePerDay)
	|	END AS RoomsRentedPercentWithRoomBlocksPerRoomTypePerDay,
	|	CASE
	|		WHEN RoomSalesTurnovers.BedsPerRoomTypePerDay - RoomSalesTurnovers.BedsBlockedPerRoomTypePerDay = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.BedsRented * 100 / (RoomSalesTurnovers.BedsPerRoomTypePerDay - RoomSalesTurnovers.BedsBlockedPerRoomTypePerDay)
	|	END AS BedsRentedPercentWithRoomBlocksPerRoomTypePerDay,
	|	CASE
	|		WHEN RoomSalesTurnovers.RoomsPerRoomTypePerMonth = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.RoomsRented * 100 / RoomSalesTurnovers.RoomsPerRoomTypePerMonth
	|	END AS RoomsRentedPercentPerRoomTypePerMonth,
	|	CASE
	|		WHEN RoomSalesTurnovers.BedsPerRoomTypePerMonth = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.BedsRented * 100 / RoomSalesTurnovers.BedsPerRoomTypePerMonth
	|	END AS BedsRentedPercentPerRoomTypePerMonth,
	|	CASE
	|		WHEN RoomSalesTurnovers.RoomsPerRoomTypePerMonth - RoomSalesTurnovers.RoomsBlockedPerRoomTypePerMonth = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.RoomsRented * 100 / (RoomSalesTurnovers.RoomsPerRoomTypePerMonth - RoomSalesTurnovers.RoomsBlockedPerRoomTypePerMonth)
	|	END AS RoomsRentedPercentWithRoomBlocksPerRoomTypePerMonth,
	|	CASE
	|		WHEN RoomSalesTurnovers.BedsPerRoomTypePerMonth - RoomSalesTurnovers.BedsBlockedPerRoomTypePerMonth = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.BedsRented * 100 / (RoomSalesTurnovers.BedsPerRoomTypePerMonth - RoomSalesTurnovers.BedsBlockedPerRoomTypePerMonth)
	|	END AS BedsRentedPercentWithRoomBlocksPerRoomTypePerMonth,
	|	CASE
	|		WHEN RoomSalesTurnovers.RoomsPerRoomTypePerPeriod = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.RoomsRented * 100 / RoomSalesTurnovers.RoomsPerRoomTypePerPeriod
	|	END AS RoomsRentedPercentPerRoomTypePerPeriod,
	|	CASE
	|		WHEN RoomSalesTurnovers.BedsPerRoomTypePerPeriod = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.BedsRented * 100 / RoomSalesTurnovers.BedsPerRoomTypePerPeriod
	|	END AS BedsRentedPercentPerRoomTypePerPeriod,
	|	CASE
	|		WHEN RoomSalesTurnovers.RoomsPerRoomTypePerPeriod - RoomSalesTurnovers.RoomsBlockedPerRoomTypePerPeriod = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.RoomsRented * 100 / (RoomSalesTurnovers.RoomsPerRoomTypePerPeriod - RoomSalesTurnovers.RoomsBlockedPerRoomTypePerPeriod)
	|	END AS RoomsRentedPercentWithRoomBlocksPerRoomTypePerPeriod,
	|	CASE
	|		WHEN RoomSalesTurnovers.BedsPerRoomTypePerPeriod - RoomSalesTurnovers.BedsBlockedPerRoomTypePerPeriod = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.BedsRented * 100 / (RoomSalesTurnovers.BedsPerRoomTypePerPeriod - RoomSalesTurnovers.BedsBlockedPerRoomTypePerPeriod)
	|	END AS BedsRentedPercentWithRoomBlocksPerRoomTypePerPeriod,
	|	CASE
	|		WHEN RoomSalesTurnovers.RoomsPerRoomTypeAndCalendarDayTypePerDay = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.RoomsRented * 100 / RoomSalesTurnovers.RoomsPerRoomTypeAndCalendarDayTypePerDay
	|	END AS RoomsRentedPercentPerRoomTypeAndCalendarDayTypePerDay,
	|	CASE
	|		WHEN RoomSalesTurnovers.BedsPerRoomTypeAndCalendarDayTypePerDay = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.BedsRented * 100 / RoomSalesTurnovers.BedsPerRoomTypeAndCalendarDayTypePerDay
	|	END AS BedsRentedPercentPerRoomTypeAndCalendarDayTypePerDay,
	|	CASE
	|		WHEN RoomSalesTurnovers.RoomsPerRoomTypeAndCalendarDayTypePerDay - RoomSalesTurnovers.RoomsBlockedPerRoomTypeAndCalendarDayTypePerDay = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.RoomsRented * 100 / (RoomSalesTurnovers.RoomsPerRoomTypeAndCalendarDayTypePerDay - RoomSalesTurnovers.RoomsBlockedPerRoomTypeAndCalendarDayTypePerDay)
	|	END AS RoomsRentedPercentWithRoomBlocksPerRoomTypeAndCalendarDayTypePerDay,
	|	CASE
	|		WHEN RoomSalesTurnovers.BedsPerRoomTypeAndCalendarDayTypePerDay - RoomSalesTurnovers.BedsBlockedPerRoomTypeAndCalendarDayTypePerDay = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.BedsRented * 100 / (RoomSalesTurnovers.BedsPerRoomTypeAndCalendarDayTypePerDay - RoomSalesTurnovers.BedsBlockedPerRoomTypeAndCalendarDayTypePerDay)
	|	END AS BedsRentedPercentWithRoomBlocksPerRoomTypeAndCalendarDayTypePerDay,
	|	CASE
	|		WHEN RoomSalesTurnovers.RoomsPerRoomTypeAndChoosenCalendarDayTypePerDay = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.RoomsRented * 100 / RoomSalesTurnovers.RoomsPerRoomTypeAndChoosenCalendarDayTypePerDay
	|	END AS RoomsRentedPercentPerRoomTypeAndChoosenCalendarDayTypePerDay,
	|	CASE
	|		WHEN RoomSalesTurnovers.BedsPerRoomTypeAndChoosenCalendarDayTypePerDay = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.BedsRented * 100 / RoomSalesTurnovers.BedsPerRoomTypeAndChoosenCalendarDayTypePerDay
	|	END AS BedsRentedPercentPerRoomTypeAndChoosenCalendarDayTypePerDay,
	|	CASE
	|		WHEN RoomSalesTurnovers.RoomsPerRoomTypeAndChoosenCalendarDayTypePerDay - RoomSalesTurnovers.RoomsBlockedPerRoomTypeAndChoosenCalendarDayTypePerDay = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.RoomsRented * 100 / (RoomSalesTurnovers.RoomsPerRoomTypeAndChoosenCalendarDayTypePerDay - RoomSalesTurnovers.RoomsBlockedPerRoomTypeAndChoosenCalendarDayTypePerDay)
	|	END AS RoomsRentedPercentWithRoomBlocksPerRoomTypeAndChoosenCalendarDayTypePerDay,
	|	CASE
	|		WHEN RoomSalesTurnovers.BedsPerRoomTypeAndChoosenCalendarDayTypePerDay - RoomSalesTurnovers.BedsBlockedPerRoomTypeAndChoosenCalendarDayTypePerDay = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.BedsRented * 100 / (RoomSalesTurnovers.BedsPerRoomTypeAndChoosenCalendarDayTypePerDay - RoomSalesTurnovers.BedsBlockedPerRoomTypeAndChoosenCalendarDayTypePerDay)
	|	END AS BedsRentedPercentWithRoomBlocksPerRoomTypeAndChoosenCalendarDayTypePerDay,
	|	RoomSalesTurnovers.TotalSalesAmount AS TotalSalesAmount,
	|	RoomSalesTurnovers.TotalRoomsRented AS TotalRoomsRented,
	|	RoomSalesTurnovers.TotalBedsRented AS TotalBedsRented,
	|	CASE
	|		WHEN RoomSalesTurnovers.TotalSalesAmount = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.Sales * 100 / RoomSalesTurnovers.TotalSalesAmount
	|	END AS TotalSalesPercent,
	|	CASE
	|		WHEN RoomSalesTurnovers.TotalBedsRented = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.BedsRented * 100 / RoomSalesTurnovers.TotalBedsRented
	|	END AS TotalBedsRentedPercent,
	|	CASE
	|		WHEN RoomSalesTurnovers.TotalRoomsRented = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.RoomsRented * 100 / RoomSalesTurnovers.TotalRoomsRented
	|	END AS TotalRoomsRentedPercent,
	|	RoomSalesTurnovers.RoomsPerRoomPerPeriod AS RoomsPerRoomPerPeriod,
	|	RoomSalesTurnovers.BedsPerRoomPerPeriod AS BedsPerRoomPerPeriod,
	|	RoomSalesTurnovers.RoomsBlockedPerRoomPerPeriod AS RoomsBlockedPerRoomPerPeriod,
	|	RoomSalesTurnovers.BedsBlockedPerRoomPerPeriod AS BedsBlockedPerRoomPerPeriod,
	|	CASE
	|		WHEN RoomSalesTurnovers.RoomsPerRoomPerPeriod - RoomSalesTurnovers.RoomsBlockedPerRoomPerPeriod = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.RoomsRented * 100 / (RoomSalesTurnovers.RoomsPerRoomPerPeriod - RoomSalesTurnovers.RoomsBlockedPerRoomPerPeriod)
	|	END AS RoomsRentedPercentPerRoom,
	|	CASE
	|		WHEN RoomSalesTurnovers.BedsPerRoomPerPeriod - RoomSalesTurnovers.BedsBlockedPerRoomPerPeriod = 0
	|			THEN 0
	|		ELSE RoomSalesTurnovers.BedsRented * 100 / (RoomSalesTurnovers.BedsPerRoomPerPeriod - RoomSalesTurnovers.BedsBlockedPerRoomPerPeriod)
	|	END AS BedsRentedPercentPerRoom,
	|	RoomSalesTurnovers.GuaranteedSales AS GuaranteedSales,
	|	RoomSalesTurnovers.GuaranteedRoomRevenue AS GuaranteedRoomRevenue,
	|	RoomSalesTurnovers.GuaranteedSalesWithoutVAT AS GuaranteedSalesWithoutVAT,
	|	RoomSalesTurnovers.GuaranteedRoomRevenueWithoutVAT AS GuaranteedRoomRevenueWithoutVAT,
	|	RoomSalesTurnovers.GuaranteedRoomsRented AS GuaranteedRoomsRented,
	|	RoomSalesTurnovers.NonGuaranteedSales AS NonGuaranteedSales,
	|	RoomSalesTurnovers.NonGuaranteedRoomRevenue AS NonGuaranteedRoomRevenue,
	|	RoomSalesTurnovers.NonGuaranteedSalesWithoutVAT AS NonGuaranteedSalesWithoutVAT,
	|	RoomSalesTurnovers.NonGuaranteedRoomRevenueWithoutVAT AS NonGuaranteedRoomRevenueWithoutVAT,
	|	RoomSalesTurnovers.NonGuaranteedRoomsRented AS NonGuaranteedRoomsRented,
	|	RoomSalesTurnovers.ServiceDate AS ServiceDate
	|{SELECT
	|	Company.*,
	|	Hotel.*,
	|	ReportingCurrency.*,
	|	Room.*,
	|	RoomType.*,
	|	RoomRate.*,
	|	CalendarDayType.*,
	|	PriceTag.*,
	|	RoomSalesTurnovers.ExtCalendarDayType.* AS ExtCalendarDayType,
	|	AccommodationType.*,
	|	ClientType.*,
	|	MarketingCode.*,
	|	SourceOfBusiness.*,
	|	Service.*,
	|	ParentDoc.*,
	|	RoomSalesTurnovers.Reservation.* AS Reservation,
	|	RoomSalesTurnovers.ReservationDate AS ReservationDate,
	|	RoomSalesTurnovers.ReservationWeek AS ReservationWeek,
	|	RoomSalesTurnovers.ReservationMonth AS ReservationMonth,
	|	RoomSalesTurnovers.ReservationYear AS ReservationYear,
	|	RoomSalesTurnovers.DaysBeforeCheckIn AS DaysBeforeCheckIn,
	|	RoomSalesTurnovers.WeeksBeforeCheckIn AS WeeksBeforeCheckIn,
	|	RoomSalesTurnovers.MonthsBeforeCheckIn AS MonthsBeforeCheckIn,
	|	RoomQuota.*,
	|	RoomSalesTurnovers.GuestGroup.* AS GuestGroup,
	|	RoomSalesTurnovers.Customer.* AS Customer,
	|	RoomSalesTurnovers.Contract.* AS Contract,
	|	RoomSalesTurnovers.Agent.* AS Agent,
	|	RoomSalesTurnovers.Client.* AS Client,
	|	RoomSalesTurnovers.Resource.* AS Resource,
	|	RoomSalesTurnovers.Folio.* AS Folio,
	|	RoomSalesTurnovers.Price AS Price,
	|	RoomSalesTurnovers.ResourceType.* AS ResourceType,
	|	RoomSalesTurnovers.TripPurpose.* AS TripPurpose,
	|	RoomSalesTurnovers.HotelProduct.* AS HotelProduct,
	|	RoomSalesTurnovers.Author.* AS Author,
	|	RoomSalesTurnovers.Discount AS Discount,
	|	RoomSalesTurnovers.DiscountType.* AS DiscountType,
	|	RoomSalesTurnovers.DiscountCard.* AS DiscountCard,
	|	RoomSalesTurnovers.AgentCommission AS AgentCommission,
	|	RoomSalesTurnovers.AgentCommissionType.* AS AgentCommissionType,
	|	RoomSalesTurnovers.PaymentMethod.* AS PaymentMethod,
	|	RoomSalesTurnovers.VATRate.* AS VATRate,
	|	RoomPrice,
	|	Sales,
	|	SalesWithoutCommission,
	|	RoomRevenue,
	|	RoomRevenueWithoutCommission,
	|	InPriceRevenue,
	|	InPriceRevenueWithoutCommission,
	|	ExtraBedRevenue,
	|	RoomRevenueWithoutExtraBed,
	|	SalesWithoutVAT,
	|	SalesWithoutVATWithoutCommission,
	|	RoomRevenueWithoutVAT,
	|	RoomRevenueWithoutVATWithoutCommission,
	|	InPriceRevenueWithoutVAT,
	|	InPriceRevenueWithoutVATWithoutCommission,
	|	ExtraBedRevenueWithoutVAT,
	|	RoomRevenueWithoutExtraBedWithoutVAT,
	|	ExtraServicesRevenue,
	|	ExtraServicesRevenueWithoutVAT,
	|	CommissionSum,
	|	CommissionSumWithoutVAT,
	|	DiscountSum,
	|	DiscountSumWithoutVAT,
	|	ExtraBedDiscountSum,
	|	DiscountSumWithoutExtraBed,
	|	RevenueSegmentRoomSales,
	|	RevenueSegmentRoomSalesWithoutVAT,
	|	RevenueSegmentFaBSales,
	|	RevenueSegmentFaBSalesWithoutVAT,
	|	RevenueSegmentSPASales,
	|	RevenueSegmentSPASalesWithoutVAT,
	|	RevenueSegmentConferenceSales,
	|	RevenueSegmentConferenceSalesWithoutVAT,
	|	RevenueSegmentOtherSales,
	|	RevenueSegmentOtherSalesWithoutVAT,
	|	RoomsRented,
	|	BedsRented,
	|	AdditionalBedsRented,
	|	GuestDays,
	|	GuestDaysWithoutExtraBed,
	|	ExtraBedGuestDays,
	|	GuestsCheckedIn,
	|	RoomsCheckedIn,
	|	BedsCheckedIn,
	|	AdditionalBedsCheckedIn,
	|	BookingWindow,
	|	BookingWindowDimension,
	|	ALS,
	|	Quantity,
	|	RoomsPerPeriod,
	|	BedsPerPeriod,
	|	RoomsBlockedPerPeriod,
	|	BedsBlockedPerPeriod,
	|	RoomsPerRoomTypePerDay,
	|	BedsPerRoomTypePerDay,
	|	RoomsBlockedPerRoomTypePerDay,
	|	BedsBlockedPerRoomTypePerDay,
	|	RoomsPerRoomTypePerMonth,
	|	BedsPerRoomTypePerMonth,
	|	RoomsBlockedPerRoomTypePerMonth,
	|	BedsBlockedPerRoomTypePerMonth,
	|	RoomsPerRoomTypePerPeriod,
	|	BedsPerRoomTypePerPeriod,
	|	RoomsBlockedPerRoomTypePerPeriod,
	|	BedsBlockedPerRoomTypePerPeriod,
	|	AverageRoomPrice,
	|	AverageBedPrice,
	|	AverageRoomPriceWithoutVAT,
	|	AverageBedPriceWithoutVAT,
	|	RevPAR,
	|	RevPAB,
	|	RevPARWithoutVAT,
	|	RevPABWithoutVAT,
	|	RevPARPerRoomTypePerDay,
	|	RevPABPerRoomTypePerDay,
	|	RevPARWithoutVATPerRoomTypePerDay,
	|	RevPABWithoutVATPerRoomTypePerDay,
	|	RevPARPerRoomTypePerMonth,
	|	RevPABPerRoomTypePerMonth,
	|	RevPARWithoutVATPerRoomTypePerMonth,
	|	RevPABWithoutVATPerRoomTypePerMonth,
	|	RevPARPerRoomTypePerPeriod,
	|	RevPABPerRoomTypePerPeriod,
	|	RevPARWithoutVATPerRoomTypePerPeriod,
	|	RevPABWithoutVATPerRoomTypePerPeriod,
	|	RoomsRentedPercent,
	|	BedsRentedPercent,
	|	RoomsRentedPercentWithRoomBlocks,
	|	BedsRentedPercentWithRoomBlocks,
	|	RoomsRentedPercentPerRoomTypePerDay,
	|	BedsRentedPercentPerRoomTypePerDay,
	|	RoomsRentedPercentWithRoomBlocksPerRoomTypePerDay,
	|	BedsRentedPercentWithRoomBlocksPerRoomTypePerDay,
	|	RoomsRentedPercentPerRoomTypePerMonth,
	|	BedsRentedPercentPerRoomTypePerMonth,
	|	RoomsRentedPercentWithRoomBlocksPerRoomTypePerMonth,
	|	BedsRentedPercentWithRoomBlocksPerRoomTypePerMonth,
	|	RoomsRentedPercentPerRoomTypePerPeriod,
	|	BedsRentedPercentPerRoomTypePerPeriod,
	|	RoomsRentedPercentWithRoomBlocksPerRoomTypePerPeriod,
	|	BedsRentedPercentWithRoomBlocksPerRoomTypePerPeriod,
	|	RoomsRentedPercentWithRoomBlocksPerRoomTypeAndCalendarDayTypePerDay,
	|	BedsRentedPercentWithRoomBlocksPerRoomTypeAndCalendarDayTypePerDay,
	|	RoomsRentedPercentWithRoomBlocksPerRoomTypeAndChoosenCalendarDayTypePerDay,
	|	BedsRentedPercentWithRoomBlocksPerRoomTypeAndChoosenCalendarDayTypePerDay,
	|	TotalSalesAmount,
	|	TotalBedsRented,
	|	TotalRoomsRented,
	|	TotalSalesPercent,
	|	TotalBedsRentedPercent,
	|	TotalRoomsRentedPercent,
	|	AccountingDate,
	|	ServiceDate,
	|	(DAY(RoomSalesTurnovers.AccountingDate)) AS AccountingDay,
	|	(WEEKDAY(RoomSalesTurnovers.AccountingDate)) AS AccountingWeekday,
	|	(CASE
	|			WHEN WEEKDAY(RoomSalesTurnovers.AccountingDate) = 1
	|				THEN &qMonday
	|			WHEN WEEKDAY(RoomSalesTurnovers.AccountingDate) = 2
	|				THEN &qTuesday
	|			WHEN WEEKDAY(RoomSalesTurnovers.AccountingDate) = 3
	|				THEN &qWednesday
	|			WHEN WEEKDAY(RoomSalesTurnovers.AccountingDate) = 4
	|				THEN &qThursday
	|			WHEN WEEKDAY(RoomSalesTurnovers.AccountingDate) = 5
	|				THEN &qFriday
	|			WHEN WEEKDAY(RoomSalesTurnovers.AccountingDate) = 6
	|				THEN &qSaturday
	|			WHEN WEEKDAY(RoomSalesTurnovers.AccountingDate) = 7
	|				THEN &qSunday
	|			ELSE NULL
	|		END) AS AccountingWeekdayName,
	|	(BEGINOFPERIOD(RoomSalesTurnovers.AccountingDate, WEEK)) AS AccountingWeek,
	|	(BEGINOFPERIOD(RoomSalesTurnovers.AccountingDate, MONTH)) AS AccountingMonth,
	|	(BEGINOFPERIOD(RoomSalesTurnovers.AccountingDate, QUARTER)) AS AccountingQuarter,
	|	(YEAR(RoomSalesTurnovers.AccountingDate)) AS AccountingYear,
	|	(CASE
	|			WHEN NOT RoomSalesTurnovers.GuestGroup.GroupType.Code IS NULL
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS IsGroupReservation,
	|	(BEGINOFPERIOD(DATEADD(RoomSalesTurnovers.AccountingDate, YEAR, -(YEAR(RoomSalesTurnovers.AccountingDate) - 2)), DAY)) AS AccountingDateNoYear,
	|	(BEGINOFPERIOD(DATEADD(RoomSalesTurnovers.AccountingDate, YEAR, -(YEAR(RoomSalesTurnovers.AccountingDate) - 2)), WEEK)) AS AccountingWeekNoYear,
	|	(BEGINOFPERIOD(DATEADD(RoomSalesTurnovers.AccountingDate, YEAR, -(YEAR(RoomSalesTurnovers.AccountingDate) - 2)), MONTH)) AS AccountingMonthNoYear,
	|	(BEGINOFPERIOD(DATEADD(RoomSalesTurnovers.AccountingDate, YEAR, -(YEAR(RoomSalesTurnovers.AccountingDate) - 2)), QUARTER)) AS AccountingQuarterNoYear,
	|	(BEGINOFPERIOD(DATEADD(RoomSalesTurnovers.ReservationDate, YEAR, -(YEAR(RoomSalesTurnovers.ReservationDate) - 2)), DAY)) AS ReservationDateNoYear,
	|	(BEGINOFPERIOD(DATEADD(RoomSalesTurnovers.ReservationWeek, YEAR, -(YEAR(RoomSalesTurnovers.ReservationWeek) - 2)), DAY)) AS ReservationWeekNoYear,
	|	(BEGINOFPERIOD(DATEADD(RoomSalesTurnovers.ReservationMonth, YEAR, -(YEAR(RoomSalesTurnovers.ReservationMonth) - 2)), DAY)) AS ReservationMonthNoYear,
	|	RoomSalesTurnovers.CustomAttribute1.* AS CustomAttribute1,
	|	RoomSalesTurnovers.CustomAttribute2.* AS CustomAttribute2,
	|	RoomSalesTurnovers.CustomAttribute3.* AS CustomAttribute3,
	|	RoomsPerRoomPerPeriod,
	|	BedsPerRoomPerPeriod,
	|	RoomsBlockedPerRoomPerPeriod,
	|	BedsBlockedPerRoomPerPeriod,
	|	RoomsRentedPercentPerRoom,
	|	BedsRentedPercentPerRoom,
	|	GuaranteedSales AS GuaranteedSales,
	|	GuaranteedRoomRevenue AS GuaranteedRoomRevenue,
	|	GuaranteedSalesWithoutVAT AS GuaranteedSalesWithoutVAT,
	|	GuaranteedRoomRevenueWithoutVAT AS GuaranteedRoomRevenueWithoutVAT,
	|	GuaranteedRoomsRented AS GuaranteedRoomsRented,
	|	NonGuaranteedSales AS NonGuaranteedSales,
	|	NonGuaranteedRoomRevenue AS NonGuaranteedRoomRevenue,
	|	NonGuaranteedSalesWithoutVAT AS NonGuaranteedSalesWithoutVAT,
	|	NonGuaranteedRoomRevenueWithoutVAT AS NonGuaranteedRoomRevenueWithoutVAT,
	|	NonGuaranteedRoomsRented AS NonGuaranteedRoomsRented}
	|FROM
	|	(SELECT
	|		RoomSales.Period AS Period,
	|		RoomSales.Company AS Company,
	|		RoomSales.Hotel AS Hotel,
	|		RoomSales.ReportingCurrency AS ReportingCurrency,
	|		RoomSales.Room AS Room,
	|		RoomSales.RoomType AS RoomType,
	|		RoomSales.RoomRate AS RoomRate,
	|		RoomSales.AccommodationType AS AccommodationType,
	|		RoomSales.ClientType AS ClientType,
	|		RoomSales.MarketingCode AS MarketingCode,
	|		RoomSales.SourceOfBusiness AS SourceOfBusiness,
	|		RoomSales.Service AS Service,
	|		RoomSales.AccountingDate AS AccountingDate,
	|		RoomSales.ParentDoc AS ParentDoc,
	|		ISNULL(RoomSales.ParentDoc.Reservation, RoomSales.ParentDoc) AS Reservation,
	|		CASE
	|			WHEN &qByGroupCreationDate
	|				THEN BEGINOFPERIOD(ISNULL(RoomSales.GuestGroup.CreateDate, &qEmptyDate), DAY)
	|			ELSE BEGINOFPERIOD(ISNULL(ISNULL(RoomSales.ParentDoc.Reservation.Date, RoomSales.ParentDoc.Date), &qEmptyDate), DAY)
	|		END AS ReservationDate,
	|		CASE
	|			WHEN &qByGroupCreationDate
	|				THEN BEGINOFPERIOD(ISNULL(RoomSales.GuestGroup.CreateDate, &qEmptyDate), WEEK)
	|			ELSE BEGINOFPERIOD(ISNULL(RoomSales.ParentDoc.Reservation.Date, RoomSales.ParentDoc.Date), WEEK)
	|		END AS ReservationWeek,
	|		CASE
	|			WHEN &qByGroupCreationDate
	|				THEN BEGINOFPERIOD(ISNULL(RoomSales.GuestGroup.CreateDate, &qEmptyDate), MONTH)
	|			ELSE BEGINOFPERIOD(ISNULL(RoomSales.ParentDoc.Reservation.Date, RoomSales.ParentDoc.Date), MONTH)
	|		END AS ReservationMonth,
	|		CASE
	|			WHEN &qByGroupCreationDate
	|				THEN YEAR(ISNULL(RoomSales.GuestGroup.CreateDate, &qEmptyDate))
	|			ELSE YEAR(ISNULL(RoomSales.ParentDoc.Reservation.Date, RoomSales.ParentDoc.Date))
	|		END AS ReservationYear,
	|		ISNULL(DATEDIFF(RoomSales.ParentDoc.Reservation.Date, RoomSales.ParentDoc.CheckInDate, DAY), 0) AS DaysBeforeCheckIn,
	|		CAST(ISNULL(DATEDIFF(RoomSales.ParentDoc.Reservation.Date, RoomSales.ParentDoc.CheckInDate, DAY), 0) / 7 AS NUMBER(10, 0)) AS WeeksBeforeCheckIn,
	|		ISNULL(DATEDIFF(RoomSales.ParentDoc.Reservation.Date, RoomSales.ParentDoc.CheckInDate, MONTH), 0) AS MonthsBeforeCheckIn,
	|		RoomSales.RoomQuota AS RoomQuota,
	|		RoomSales.CalendarDayType AS CalendarDayType,
	|		RoomSales.PriceTag AS PriceTag,
	|		CalendarDayTypes.CalendarDayType AS ExtCalendarDayType,
	|		CASE
	|			WHEN ISNULL(RoomSales.RoomsRentedTurnover, 0) = 0
	|				THEN 0
	|			ELSE ISNULL(RoomSales.RoomRevenueTurnover, 0) / ISNULL(RoomSales.RoomsRentedTurnover, 0)
	|		END AS RoomPrice,
	|		RoomSales.GuestGroup AS GuestGroup,
	|		RoomSales.Customer AS Customer,
	|		RoomSales.Contract AS Contract,
	|		RoomSales.Agent AS Agent,
	|		RoomSales.Client AS Client,
	|		RoomSales.Resource AS Resource,
	|		RoomSales.Folio AS Folio,
	|		RoomSales.Price AS Price,
	|		RoomSales.ResourceType AS ResourceType,
	|		RoomSales.TripPurpose AS TripPurpose,
	|		RoomSales.HotelProduct AS HotelProduct,
	|		RoomSales.Author AS Author,
	|		RoomSales.Discount AS Discount,
	|		RoomSales.DiscountType AS DiscountType,
	|		RoomSales.DiscountCard AS DiscountCard,
	|		RoomSales.AgentCommission AS AgentCommission,
	|		RoomSales.AgentCommissionType AS AgentCommissionType,
	|		RoomSales.PaymentMethod AS PaymentMethod,
	|		RoomSales.VATRate AS VATRate,
	|		ISNULL(RoomSales.SalesTurnover, 0) AS Sales,
	|		ISNULL(RoomSales.SalesTurnover, 0) - ISNULL(RoomSales.CommissionSumTurnover, 0) AS SalesWithoutCommission,
	|		ISNULL(RoomSales.RoomRevenueTurnover, 0) AS RoomRevenue,
	|		ISNULL(RoomSales.RoomRevenueTurnover, 0) - ISNULL(RoomSales.CommissionSumTurnover, 0) AS RoomRevenueWithoutCommission,
	|		CASE
	|			WHEN ISNULL(RoomSales.Service.IsInPrice, FALSE)
	|				THEN ISNULL(RoomSales.SalesTurnover, 0)
	|			ELSE 0
	|		END AS InPriceRevenue,
	|		CASE
	|			WHEN ISNULL(RoomSales.Service.IsInPrice, FALSE)
	|				THEN ISNULL(RoomSales.SalesTurnover, 0) - ISNULL(RoomSales.CommissionSumTurnover, 0)
	|			ELSE 0
	|		END AS InPriceRevenueWithoutCommission,
	|		ISNULL(RoomSales.RoomRevenueTurnover, 0) - ISNULL(RoomSales.ExtraBedRevenueTurnover, 0) AS RoomRevenueWithoutExtraBed,
	|		ISNULL(RoomSales.ExtraBedRevenueTurnover, 0) AS ExtraBedRevenue,
	|		ISNULL(RoomSales.SalesWithoutVATTurnover, 0) AS SalesWithoutVAT,
	|		ISNULL(RoomSales.SalesWithoutVATTurnover, 0) - ISNULL(RoomSales.CommissionSumWithoutVATTurnover, 0) AS SalesWithoutVATWithoutCommission,
	|		ISNULL(RoomSales.RoomRevenueWithoutVATTurnover, 0) AS RoomRevenueWithoutVAT,
	|		ISNULL(RoomSales.RoomRevenueWithoutVATTurnover, 0) - ISNULL(RoomSales.CommissionSumWithoutVATTurnover, 0) AS RoomRevenueWithoutVATWithoutCommission,
	|		CASE
	|			WHEN ISNULL(RoomSales.Service.IsInPrice, FALSE)
	|				THEN ISNULL(RoomSales.SalesWithoutVATTurnover, 0)
	|			ELSE 0
	|		END AS InPriceRevenueWithoutVAT,
	|		CASE
	|			WHEN ISNULL(RoomSales.Service.IsInPrice, FALSE)
	|				THEN ISNULL(RoomSales.SalesWithoutVATTurnover, 0) - ISNULL(RoomSales.CommissionSumWithoutVATTurnover, 0)
	|			ELSE 0
	|		END AS InPriceRevenueWithoutVATWithoutCommission,
	|		ISNULL(RoomSales.RoomRevenueWithoutVATTurnover, 0) - ISNULL(RoomSales.ExtraBedRevenueWithoutVATTurnover, 0) AS RoomRevenueWithoutExtraBedWithoutVAT,
	|		ISNULL(RoomSales.ExtraBedRevenueWithoutVATTurnover, 0) AS ExtraBedRevenueWithoutVAT,
	|		ISNULL(RoomSales.CommissionSumTurnover, 0) AS CommissionSum,
	|		ISNULL(RoomSales.CommissionSumWithoutVATTurnover, 0) AS CommissionSumWithoutVAT,
	|		ISNULL(RoomSales.DiscountSumTurnover, 0) AS DiscountSum,
	|		ISNULL(RoomSales.DiscountSumWithoutVATTurnover, 0) AS DiscountSumWithoutVAT,
	|		CASE
	|			WHEN ISNULL(RoomSales.ExtraBedRevenueTurnover, 0) = 0
	|				THEN 0
	|			ELSE ISNULL(RoomSales.DiscountSumTurnover, 0)
	|		END AS ExtraBedDiscountSum,
	|		CASE
	|			WHEN ISNULL(RoomSales.ExtraBedRevenueTurnover, 0) = 0
	|				THEN ISNULL(RoomSales.DiscountSumTurnover, 0)
	|			ELSE 0
	|		END AS DiscountSumWithoutExtraBed,
	|		ISNULL(RoomSales.RoomsRentedTurnover, 0) AS RoomsRented,
	|		ISNULL(RoomSales.BedsRentedTurnover, 0) AS BedsRented,
	|		ISNULL(RoomSales.AdditionalBedsRentedTurnover, 0) AS AdditionalBedsRented,
	|		ISNULL(RoomSales.GuestDaysTurnover, 0) AS GuestDays,
	|		ISNULL(RoomSales.GuestDaysTurnover, 0) - ISNULL(RoomSales.AdditionalGuestDaysTurnover, 0) AS GuestDaysWithoutExtraBed,
	|		ISNULL(RoomSales.AdditionalGuestDaysTurnover, 0) AS ExtraBedGuestDays,
	|		ISNULL(RoomSales.GuestsCheckedInTurnover, 0) AS GuestsCheckedIn,
	|		ISNULL(RoomSales.RoomsCheckedInTurnover, 0) AS RoomsCheckedIn,
	|		ISNULL(RoomSales.BedsCheckedInTurnover, 0) AS BedsCheckedIn,
	|		ISNULL(RoomSales.AdditionalBedsCheckedInTurnover, 0) AS AdditionalBedsCheckedIn,
	|		ISNULL(RoomSales.BookingWindowTurnover, 0) AS BookingWindow,
	|		ISNULL(RoomSales.QuantityTurnover, 0) AS Quantity,
	|		ISNULL(RoomTypeInventoryTotalsPerDay.TotalRooms, 0) / ISNULL(RoomSalesPerRoomTypePerDay.NumberOfDetailedRows, 1) AS RoomsPerRoomTypePerDay,
	|		ISNULL(RoomTypeInventoryTotalsPerDay.TotalBeds, 0) / ISNULL(RoomSalesPerRoomTypePerDay.NumberOfDetailedRows, 1) AS BedsPerRoomTypePerDay,
	|		ISNULL(RoomTypeInventoryTotalsPerDay.TotalRoomsBlocked, 0) / ISNULL(RoomSalesPerRoomTypePerDay.NumberOfDetailedRows, 1) AS RoomsBlockedPerRoomTypePerDay,
	|		ISNULL(RoomTypeInventoryTotalsPerDay.TotalBedsBlocked, 0) / ISNULL(RoomSalesPerRoomTypePerDay.NumberOfDetailedRows, 1) AS BedsBlockedPerRoomTypePerDay,
	|		ISNULL(RoomTypeInventoryTotalsPerMonth.TotalRooms, 0) / ISNULL(RoomSalesPerRoomTypePerMonth.NumberOfDetailedRows, 1) AS RoomsPerRoomTypePerMonth,
	|		ISNULL(RoomTypeInventoryTotalsPerMonth.TotalBeds, 0) / ISNULL(RoomSalesPerRoomTypePerMonth.NumberOfDetailedRows, 1) AS BedsPerRoomTypePerMonth,
	|		ISNULL(RoomTypeInventoryTotalsPerMonth.TotalRoomsBlocked, 0) / ISNULL(RoomSalesPerRoomTypePerMonth.NumberOfDetailedRows, 1) AS RoomsBlockedPerRoomTypePerMonth,
	|		ISNULL(RoomTypeInventoryTotalsPerMonth.TotalBedsBlocked, 0) / ISNULL(RoomSalesPerRoomTypePerMonth.NumberOfDetailedRows, 1) AS BedsBlockedPerRoomTypePerMonth,
	|		ISNULL(RoomTypeInventoryTotalsPerPeriod.TotalRooms, 0) / ISNULL(RoomSalesPerRoomTypePerPeriod.NumberOfDetailedRows, 1) AS RoomsPerRoomTypePerPeriod,
	|		ISNULL(RoomTypeInventoryTotalsPerPeriod.TotalBeds, 0) / ISNULL(RoomSalesPerRoomTypePerPeriod.NumberOfDetailedRows, 1) AS BedsPerRoomTypePerPeriod,
	|		ISNULL(RoomTypeInventoryTotalsPerPeriod.TotalRoomsBlocked, 0) / ISNULL(RoomSalesPerRoomTypePerPeriod.NumberOfDetailedRows, 1) AS RoomsBlockedPerRoomTypePerPeriod,
	|		ISNULL(RoomTypeInventoryTotalsPerPeriod.TotalBedsBlocked, 0) / ISNULL(RoomSalesPerRoomTypePerPeriod.NumberOfDetailedRows, 1) AS BedsBlockedPerRoomTypePerPeriod,
	|		ISNULL(RoomTypeInventoryTotalsPerDay.TotalRooms, 0) / ISNULL(RoomSalesPerRoomTypeAndCalendarDayTypePerDay.NumberOfDetailedRows, 1) AS RoomsPerRoomTypeAndCalendarDayTypePerDay,
	|		ISNULL(RoomTypeInventoryTotalsPerDay.TotalBeds, 0) / ISNULL(RoomSalesPerRoomTypeAndCalendarDayTypePerDay.NumberOfDetailedRows, 1) AS BedsPerRoomTypeAndCalendarDayTypePerDay,
	|		ISNULL(RoomTypeInventoryTotalsPerDay.TotalRoomsBlocked, 0) / ISNULL(RoomSalesPerRoomTypeAndCalendarDayTypePerDay.NumberOfDetailedRows, 1) AS RoomsBlockedPerRoomTypeAndCalendarDayTypePerDay,
	|		ISNULL(RoomTypeInventoryTotalsPerDay.TotalBedsBlocked, 0) / ISNULL(RoomSalesPerRoomTypeAndCalendarDayTypePerDay.NumberOfDetailedRows, 1) AS BedsBlockedPerRoomTypeAndCalendarDayTypePerDay,
	|		ISNULL(RoomTypeInventoryTotalsPerDay.TotalRooms, 0) / ISNULL(RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.NumberOfDetailedRows, 1) AS RoomsPerRoomTypeAndChoosenCalendarDayTypePerDay,
	|		ISNULL(RoomTypeInventoryTotalsPerDay.TotalBeds, 0) / ISNULL(RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.NumberOfDetailedRows, 1) AS BedsPerRoomTypeAndChoosenCalendarDayTypePerDay,
	|		ISNULL(RoomTypeInventoryTotalsPerDay.TotalRoomsBlocked, 0) / ISNULL(RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.NumberOfDetailedRows, 1) AS RoomsBlockedPerRoomTypeAndChoosenCalendarDayTypePerDay,
	|		ISNULL(RoomTypeInventoryTotalsPerDay.TotalBedsBlocked, 0) / ISNULL(RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.NumberOfDetailedRows, 1) AS BedsBlockedPerRoomTypeAndChoosenCalendarDayTypePerDay,
	|		ISNULL(InventoryTotals.TotalRooms, 0) AS RoomsPerPeriod,
	|		ISNULL(InventoryTotals.TotalBeds, 0) AS BedsPerPeriod,
	|		ISNULL(InventoryTotals.TotalRoomsBlocked, 0) AS RoomsBlockedPerPeriod,
	|		ISNULL(InventoryTotals.TotalBedsBlocked, 0) AS BedsBlockedPerPeriod,
	|		ISNULL(TotalSales.TotalSalesAmount, 0) AS TotalSalesAmount,
	|		ISNULL(TotalSales.TotalBedsRented, 0) AS TotalBedsRented,
	|		ISNULL(TotalSales.TotalRoomsRented, 0) AS TotalRoomsRented,
	|		ISNULL(RoomInventoryTotals.TotalRooms, 0) AS RoomsPerRoomPerPeriod,
	|		ISNULL(RoomInventoryTotals.TotalBeds, 0) AS BedsPerRoomPerPeriod,
	|		ISNULL(RoomInventoryTotals.TotalRoomsBlocked, 0) AS RoomsBlockedPerRoomPerPeriod,
	|		ISNULL(RoomInventoryTotals.TotalBedsBlocked, 0) AS BedsBlockedPerRoomPerPeriod,
	|		CASE
	|			WHEN RoomSales.Service.ServiceType.RevenueSegment = VALUE(Enum.RevenueSegments.Room)
	|				THEN ISNULL(RoomSales.SalesTurnover, 0)
	|			ELSE 0
	|		END AS RevenueSegmentRoomSales,
	|		CASE
	|			WHEN RoomSales.Service.ServiceType.RevenueSegment = VALUE(Enum.RevenueSegments.Room)
	|				THEN ISNULL(RoomSales.SalesWithoutVATTurnover, 0)
	|			ELSE 0
	|		END AS RevenueSegmentRoomSalesWithoutVAT,
	|		CASE
	|			WHEN RoomSales.Service.ServiceType.RevenueSegment = VALUE(Enum.RevenueSegments.FaB)
	|				THEN ISNULL(RoomSales.SalesTurnover, 0)
	|			ELSE 0
	|		END AS RevenueSegmentFaBSales,
	|		CASE
	|			WHEN RoomSales.Service.ServiceType.RevenueSegment = VALUE(Enum.RevenueSegments.FaB)
	|				THEN ISNULL(RoomSales.SalesWithoutVATTurnover, 0)
	|			ELSE 0
	|		END AS RevenueSegmentFaBSalesWithoutVAT,
	|		CASE
	|			WHEN RoomSales.Service.ServiceType.RevenueSegment = VALUE(Enum.RevenueSegments.SPA)
	|				THEN ISNULL(RoomSales.SalesTurnover, 0)
	|			ELSE 0
	|		END AS RevenueSegmentSPASales,
	|		CASE
	|			WHEN RoomSales.Service.ServiceType.RevenueSegment = VALUE(Enum.RevenueSegments.SPA)
	|				THEN ISNULL(RoomSales.SalesWithoutVATTurnover, 0)
	|			ELSE 0
	|		END AS RevenueSegmentSPASalesWithoutVAT,
	|		CASE
	|			WHEN RoomSales.Service.ServiceType.RevenueSegment = VALUE(Enum.RevenueSegments.Conference)
	|				THEN ISNULL(RoomSales.SalesTurnover, 0)
	|			ELSE 0
	|		END AS RevenueSegmentConferenceSales,
	|		CASE
	|			WHEN RoomSales.Service.ServiceType.RevenueSegment = VALUE(Enum.RevenueSegments.Conference)
	|				THEN ISNULL(RoomSales.SalesWithoutVATTurnover, 0)
	|			ELSE 0
	|		END AS RevenueSegmentConferenceSalesWithoutVAT,
	|		CASE
	|			WHEN RoomSales.Service.ServiceType.RevenueSegment <> VALUE(Enum.RevenueSegments.Room)
	|					AND RoomSales.Service.ServiceType.RevenueSegment <> VALUE(Enum.RevenueSegments.FaB)
	|					AND RoomSales.Service.ServiceType.RevenueSegment <> VALUE(Enum.RevenueSegments.SPA)
	|					AND RoomSales.Service.ServiceType.RevenueSegment <> VALUE(Enum.RevenueSegments.Conference)
	|				THEN ISNULL(RoomSales.SalesTurnover, 0)
	|			ELSE 0
	|		END AS RevenueSegmentOtherSales,
	|		CASE
	|			WHEN RoomSales.Service.ServiceType.RevenueSegment <> VALUE(Enum.RevenueSegments.Room)
	|					AND RoomSales.Service.ServiceType.RevenueSegment <> VALUE(Enum.RevenueSegments.FaB)
	|					AND RoomSales.Service.ServiceType.RevenueSegment <> VALUE(Enum.RevenueSegments.SPA)
	|					AND RoomSales.Service.ServiceType.RevenueSegment <> VALUE(Enum.RevenueSegments.Conference)
	|				THEN ISNULL(RoomSales.SalesWithoutVATTurnover, 0)
	|			ELSE 0
	|		END AS RevenueSegmentOtherSalesWithoutVAT,
	|		ReservationCustomAttributeValues1.CharacteristicValue AS CustomAttribute1,
	|		ReservationCustomAttributeValues2.CharacteristicValue AS CustomAttribute2,
	|		ReservationCustomAttributeValues3.CharacteristicValue AS CustomAttribute3,
	|		ISNULL(RoomSales.GuaranteedSalesTurnover, 0) AS GuaranteedSales,
	|		ISNULL(RoomSales.GuaranteedRoomRevenueTurnover, 0) AS GuaranteedRoomRevenue,
	|		ISNULL(RoomSales.GuaranteedSalesWithoutVATTurnover, 0) AS GuaranteedSalesWithoutVAT,
	|		ISNULL(RoomSales.GuaranteedRoomRevenueWithoutVATTurnover, 0) AS GuaranteedRoomRevenueWithoutVAT,
	|		ISNULL(RoomSales.GuaranteedRoomsRentedTurnover, 0) AS GuaranteedRoomsRented,
	|		ISNULL(RoomSales.SalesTurnover, 0) - ISNULL(RoomSales.GuaranteedSalesTurnover, 0) AS NonGuaranteedSales,
	|		ISNULL(RoomSales.RoomRevenueTurnover, 0) - ISNULL(RoomSales.GuaranteedRoomRevenueTurnover, 0) AS NonGuaranteedRoomRevenue,
	|		ISNULL(RoomSales.SalesWithoutVATTurnover, 0) - ISNULL(RoomSales.GuaranteedSalesWithoutVATTurnover, 0) AS NonGuaranteedSalesWithoutVAT,
	|		ISNULL(RoomSales.RoomRevenueWithoutVATTurnover, 0) - ISNULL(RoomSales.GuaranteedRoomRevenueWithoutVATTurnover, 0) AS NonGuaranteedRoomRevenueWithoutVAT,
	|		ISNULL(RoomSales.RoomsRentedTurnover, 0) - ISNULL(RoomSales.GuaranteedRoomsRentedTurnover, 0) AS NonGuaranteedRoomsRented,
	|		RoomSales.ServiceDate AS ServiceDate
	|	FROM
	|		(SELECT
	|			BEGINOFPERIOD(RoomSalesTotals.Period, DAY) AS Period,
	|			RoomSalesTotals.Company AS Company,
	|			RoomSalesTotals.Hotel AS Hotel,
	|			RoomSalesTotals.ReportingCurrency AS ReportingCurrency,
	|			RoomSalesTotals.Room AS Room,
	|			RoomSalesTotals.RoomType AS RoomType,
	|			RoomSalesTotals.RoomRate AS RoomRate,
	|			RoomSalesTotals.AccommodationType AS AccommodationType,
	|			RoomSalesTotals.ClientType AS ClientType,
	|			RoomSalesTotals.MarketingCode AS MarketingCode,
	|			RoomSalesTotals.SourceOfBusiness AS SourceOfBusiness,
	|			RoomSalesTotals.Service AS Service,
	|			RoomSalesTotals.CalendarDayType AS CalendarDayType,
	|			RoomSalesTotals.PriceTag AS PriceTag,
	|			RoomSalesTotals.AccountingDate AS AccountingDate,
	|			RoomSalesTotals.ParentDoc AS ParentDoc,
	|			RoomSalesTotals.ParentDoc.RoomQuota AS RoomQuota,
	|			RoomSalesTotals.GuestGroup AS GuestGroup,
	|			RoomSalesTotals.Customer AS Customer,
	|			RoomSalesTotals.Contract AS Contract,
	|			RoomSalesTotals.Agent AS Agent,
	|			RoomSalesTotals.Client AS Client,
	|			RoomSalesTotals.Resource AS Resource,
	|			RoomSalesTotals.Folio AS Folio,
	|			RoomSalesTotals.Price AS Price,
	|			RoomSalesTotals.ResourceType AS ResourceType,
	|			RoomSalesTotals.TripPurpose AS TripPurpose,
	|			RoomSalesTotals.HotelProduct AS HotelProduct,
	|			RoomSalesTotals.Author AS Author,
	|			RoomSalesTotals.Discount AS Discount,
	|			RoomSalesTotals.DiscountType AS DiscountType,
	|			RoomSalesTotals.DiscountCard AS DiscountCard,
	|			RoomSalesTotals.AgentCommission AS AgentCommission,
	|			RoomSalesTotals.AgentCommissionType AS AgentCommissionType,
	|			RoomSalesTotals.PaymentMethod AS PaymentMethod,
	|			RoomSalesTotals.VATRate AS VATRate,
	|			RoomSalesTotals.Sales AS SalesTurnover,
	|			RoomSalesTotals.RoomRevenue AS RoomRevenueTurnover,
	|			RoomSalesTotals.ExtraBedRevenue AS ExtraBedRevenueTurnover,
	|			RoomSalesTotals.SalesWithoutVAT AS SalesWithoutVATTurnover,
	|			RoomSalesTotals.RoomRevenueWithoutVAT AS RoomRevenueWithoutVATTurnover,
	|			RoomSalesTotals.ExtraBedRevenueWithoutVAT AS ExtraBedRevenueWithoutVATTurnover,
	|			RoomSalesTotals.CommissionSum AS CommissionSumTurnover,
	|			RoomSalesTotals.CommissionSumWithoutVAT AS CommissionSumWithoutVATTurnover,
	|			RoomSalesTotals.DiscountSum AS DiscountSumTurnover,
	|			RoomSalesTotals.DiscountSumWithoutVAT AS DiscountSumWithoutVATTurnover,
	|			RoomSalesTotals.RoomsRented AS RoomsRentedTurnover,
	|			RoomSalesTotals.BedsRented AS BedsRentedTurnover,
	|			RoomSalesTotals.AdditionalBedsRented AS AdditionalBedsRentedTurnover,
	|			RoomSalesTotals.GuestDays AS GuestDaysTurnover,
	|			CASE
	|				WHEN ISNULL(RoomSalesTotals.AccommodationType.NumberOfAdditionalBeds, 0) <> 0
	|					THEN RoomSalesTotals.GuestDays
	|				ELSE 0
	|			END AS AdditionalGuestDaysTurnover,
	|			RoomSalesTotals.GuestsCheckedIn AS GuestsCheckedInTurnover,
	|			RoomSalesTotals.RoomsCheckedIn AS RoomsCheckedInTurnover,
	|			RoomSalesTotals.BedsCheckedIn AS BedsCheckedInTurnover,
	|			RoomSalesTotals.AdditionalBedsCheckedIn AS AdditionalBedsCheckedInTurnover,
	|			RoomSalesTotals.BookingWindow AS BookingWindowTurnover,
	|			0 AS Counter,
	|			RoomSalesTotals.Quantity AS QuantityTurnover,
	|			RoomSalesTotals.Sales AS GuaranteedSalesTurnover,
	|			RoomSalesTotals.RoomRevenue AS GuaranteedRoomRevenueTurnover,
	|			RoomSalesTotals.SalesWithoutVAT AS GuaranteedSalesWithoutVATTurnover,
	|			RoomSalesTotals.RoomRevenueWithoutVAT AS GuaranteedRoomRevenueWithoutVATTurnover,
	|			RoomSalesTotals.RoomsRented AS GuaranteedRoomsRentedTurnover,
	|			RoomSalesTotals.ServiceDate AS ServiceDate
	|		FROM
	|			AccumulationRegister.Sales AS RoomSalesTotals
	|		WHERE
	|			RoomSalesTotals.Period >= &qPeriodFrom
	|			AND RoomSalesTotals.Period <= &qPeriodTo
	|			AND RoomSalesTotals.Hotel IN HIERARCHY(&qHotel)
	|			AND (&qHideCorrections
	|					OR NOT &qHideCorrections
	|						AND NOT RoomSalesTotals.IsCorrection)
	|			AND (RoomSalesTotals.Room IN HIERARCHY (&qRoom)
	|					OR &qIsEmptyRoom)
	|			AND (NOT RoomSalesTotals.Room IN (&qRooms2IgnoreList)
	|					OR &qRooms2IgnoreListIsEmpty)
	|			AND (RoomSalesTotals.RoomType IN HIERARCHY (&qRoomType)
	|					OR &qIsEmptyRoomType)
	|			AND (RoomSalesTotals.Service IN HIERARCHY (&qService)
	|					OR &qIsEmptyService)
	|			AND (RoomSalesTotals.Service IN (&qServicesList)
	|					OR NOT &qUseServicesList)
	|			AND (NOT &qWithAllotments
	|					OR &qWithAllotments
	|						AND NOT ISNULL(RoomSalesTotals.ParentDoc.RoomQuota.IsCommitment, FALSE))
	|			AND (NOT &qFilterByReservationCreationDate
	|						AND NOT &qLimitByTodaysDate
	|					OR NOT &qFilterByReservationCreationDate
	|						AND &qLimitByTodaysDate
	|						AND NOT &qByGroupCreationDate
	|						AND (RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesTotals.ParentDoc.Date <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(RoomSalesTotals.AccountingDate, YEAR), DAY, &qTodaysDay), DAY)
	|							OR NOT RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesTotals.ParentDoc.Reservation.Date <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(RoomSalesTotals.AccountingDate, YEAR), DAY, &qTodaysDay), DAY))
	|					OR NOT &qFilterByReservationCreationDate
	|						AND &qLimitByTodaysDate
	|						AND &qByGroupCreationDate
	|						AND NOT RoomSalesTotals.GuestGroup.CreateDate IS NULL
	|						AND RoomSalesTotals.GuestGroup.CreateDate <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(RoomSalesTotals.AccountingDate, YEAR), DAY, &qTodaysDay), DAY)
	|					OR &qFilterByReservationCreationDate
	|						AND NOT &qNoYear
	|						AND NOT &qByGroupCreationDate
	|						AND (RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesTotals.ParentDoc.Date >= &qDateFrom
	|							OR NOT RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesTotals.ParentDoc.Reservation.Date >= &qDateFrom)
	|						AND (&qDateToIsEmpty
	|							OR RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesTotals.ParentDoc.Date <= &qDateTo
	|							OR NOT RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesTotals.ParentDoc.Reservation.Date <= &qDateTo)
	|					OR &qFilterByReservationCreationDate
	|						AND NOT &qNoYear
	|						AND &qByGroupCreationDate
	|						AND NOT RoomSalesTotals.GuestGroup.CreateDate IS NULL
	|						AND RoomSalesTotals.GuestGroup.CreateDate >= &qDateFrom
	|						AND (&qDateToIsEmpty
	|							OR RoomSalesTotals.GuestGroup.CreateDate <= &qDateTo)
	|					OR &qFilterByReservationCreationDate
	|						AND &qNoYear
	|						AND NOT &qByGroupCreationDate
	|						AND CASE
	|							WHEN &qShiftFrom = 1
	|									AND RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Date, YEAR, 2 - YEAR(RoomSalesTotals.ParentDoc.Date)) <= &qDateTo
	|								THEN TRUE
	|							WHEN &qShiftFrom = 1
	|									AND RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Date, YEAR, 1 - YEAR(RoomSalesTotals.ParentDoc.Date)) >= &qDateFrom
	|								THEN TRUE
	|							WHEN &qShiftFrom = 2
	|									AND RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Date, YEAR, 2 - YEAR(RoomSalesTotals.ParentDoc.Date)) >= &qDateFrom
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Date, YEAR, 2 - YEAR(RoomSalesTotals.ParentDoc.Date)) <= &qDateTo
	|								THEN TRUE
	|							WHEN &qShiftFrom = 1
	|									AND NOT RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Reservation.Date, YEAR, 2 - YEAR(RoomSalesTotals.ParentDoc.Reservation.Date)) <= &qDateTo
	|								THEN TRUE
	|							WHEN &qShiftFrom = 1
	|									AND NOT RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Reservation.Date, YEAR, 1 - YEAR(RoomSalesTotals.ParentDoc.Reservation.Date)) >= &qDateFrom
	|								THEN TRUE
	|							WHEN &qShiftFrom = 2
	|									AND NOT RoomSalesTotals.ParentDoc.Reservation.Date IS NULL
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Reservation.Date, YEAR, 2 - YEAR(RoomSalesTotals.ParentDoc.Reservation.Date)) >= &qDateFrom
	|									AND DATEADD(RoomSalesTotals.ParentDoc.Reservation.Date, YEAR, 2 - YEAR(RoomSalesTotals.ParentDoc.Reservation.Date)) <= &qDateTo
	|								THEN TRUE
	|							ELSE FALSE
	|						END
	|					OR &qFilterByReservationCreationDate
	|						AND &qNoYear
	|						AND &qByGroupCreationDate
	|						AND NOT RoomSalesTotals.GuestGroup.CreateDate IS NULL
	|						AND CASE
	|							WHEN &qShiftFrom = 1
	|									AND DATEADD(RoomSalesTotals.GuestGroup.CreateDate, YEAR, 2 - YEAR(RoomSalesTotals.GuestGroup.CreateDate)) <= &qDateTo
	|								THEN TRUE
	|							WHEN &qShiftFrom = 1
	|									AND DATEADD(RoomSalesTotals.GuestGroup.CreateDate, YEAR, 1 - YEAR(RoomSalesTotals.GuestGroup.CreateDate)) >= &qDateFrom
	|								THEN TRUE
	|							WHEN &qShiftFrom = 2
	|									AND DATEADD(RoomSalesTotals.GuestGroup.CreateDate, YEAR, 2 - YEAR(RoomSalesTotals.GuestGroup.CreateDate)) >= &qDateFrom
	|									AND DATEADD(RoomSalesTotals.GuestGroup.CreateDate, YEAR, 2 - YEAR(RoomSalesTotals.GuestGroup.CreateDate)) <= &qDateTo
	|								THEN TRUE
	|							ELSE FALSE
	|						END)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			BEGINOFPERIOD(RoomSalesForecastTotals.Period, DAY),
	|			RoomSalesForecastTotals.Company,
	|			RoomSalesForecastTotals.Hotel,
	|			RoomSalesForecastTotals.ReportingCurrency,
	|			RoomSalesForecastTotals.Room,
	|			RoomSalesForecastTotals.RoomType,
	|			RoomSalesForecastTotals.RoomRate,
	|			RoomSalesForecastTotals.AccommodationType,
	|			RoomSalesForecastTotals.ClientType,
	|			RoomSalesForecastTotals.MarketingCode,
	|			RoomSalesForecastTotals.SourceOfBusiness,
	|			RoomSalesForecastTotals.Service,
	|			RoomSalesForecastTotals.CalendarDayType,
	|			RoomSalesForecastTotals.PriceTag,
	|			RoomSalesForecastTotals.AccountingDate,
	|			RoomSalesForecastTotals.ParentDoc,
	|			RoomSalesForecastTotals.ParentDoc.RoomQuota,
	|			RoomSalesForecastTotals.GuestGroup,
	|			RoomSalesForecastTotals.Customer,
	|			RoomSalesForecastTotals.Contract,
	|			RoomSalesForecastTotals.Agent,
	|			RoomSalesForecastTotals.Client,
	|			RoomSalesForecastTotals.Resource,
	|			RoomSalesForecastTotals.Folio,
	|			RoomSalesForecastTotals.Price,
	|			RoomSalesForecastTotals.ResourceType,
	|			RoomSalesForecastTotals.TripPurpose,
	|			RoomSalesForecastTotals.HotelProduct,
	|			RoomSalesForecastTotals.Author,
	|			RoomSalesForecastTotals.Discount,
	|			RoomSalesForecastTotals.DiscountType,
	|			RoomSalesForecastTotals.DiscountCard,
	|			RoomSalesForecastTotals.AgentCommission,
	|			RoomSalesForecastTotals.AgentCommissionType,
	|			RoomSalesForecastTotals.PaymentMethod,
	|			RoomSalesForecastTotals.VATRate,
	|			RoomSalesForecastTotals.Sales,
	|			RoomSalesForecastTotals.RoomRevenue,
	|			RoomSalesForecastTotals.ExtraBedRevenue,
	|			RoomSalesForecastTotals.SalesWithoutVAT,
	|			RoomSalesForecastTotals.RoomRevenueWithoutVAT,
	|			RoomSalesForecastTotals.ExtraBedRevenueWithoutVAT,
	|			RoomSalesForecastTotals.CommissionSum,
	|			RoomSalesForecastTotals.CommissionSumWithoutVAT,
	|			RoomSalesForecastTotals.DiscountSum,
	|			RoomSalesForecastTotals.DiscountSumWithoutVAT,
	|			RoomSalesForecastTotals.RoomsRented,
	|			RoomSalesForecastTotals.BedsRented,
	|			RoomSalesForecastTotals.AdditionalBedsRented,
	|			RoomSalesForecastTotals.GuestDays,
	|			CASE
	|				WHEN ISNULL(RoomSalesForecastTotals.AccommodationType.NumberOfAdditionalBeds, 0) <> 0
	|					THEN RoomSalesForecastTotals.GuestDays
	|				ELSE 0
	|			END,
	|			RoomSalesForecastTotals.GuestsCheckedIn,
	|			RoomSalesForecastTotals.RoomsCheckedIn,
	|			RoomSalesForecastTotals.BedsCheckedIn,
	|			RoomSalesForecastTotals.AdditionalBedsCheckedIn,
	|			RoomSalesForecastTotals.BookingWindow,
	|			0,
	|			RoomSalesForecastTotals.Quantity,
	|			CASE
	|				WHEN RoomSalesForecastTotals.Recorder REFS Document.SetRoomQuota
	|						AND RoomSalesForecastTotals.RoomQuota.AllotmentType = VALUE(Enum.AllotmentTypes.Definite)
	|					THEN RoomSalesForecastTotals.Sales
	|				WHEN RoomSalesForecastTotals.Recorder REFS Document.Reservation
	|						AND ISNULL(RoomSalesForecastTotals.Recorder.ReservationStatus.IsGuaranteed, FALSE)
	|					THEN RoomSalesForecastTotals.Sales
	|				WHEN RoomSalesForecastTotals.Recorder REFS Document.ResourceReservation
	|						AND ISNULL(RoomSalesForecastTotals.Recorder.ResourceReservationStatus.IsGuaranteed, FALSE)
	|					THEN RoomSalesForecastTotals.Sales
	|				WHEN RoomSalesForecastTotals.Recorder REFS Document.Accommodation
	|					THEN RoomSalesForecastTotals.Sales
	|				ELSE 0
	|			END,
	|			CASE
	|				WHEN RoomSalesForecastTotals.Recorder REFS Document.SetRoomQuota
	|						AND RoomSalesForecastTotals.RoomQuota.AllotmentType = VALUE(Enum.AllotmentTypes.Definite)
	|					THEN RoomSalesForecastTotals.RoomRevenue
	|				WHEN RoomSalesForecastTotals.Recorder REFS Document.Reservation
	|						AND ISNULL(RoomSalesForecastTotals.Recorder.ReservationStatus.IsGuaranteed, FALSE)
	|					THEN RoomSalesForecastTotals.RoomRevenue
	|				WHEN RoomSalesForecastTotals.Recorder REFS Document.ResourceReservation
	|						AND ISNULL(RoomSalesForecastTotals.Recorder.ResourceReservationStatus.IsGuaranteed, FALSE)
	|					THEN RoomSalesForecastTotals.RoomRevenue
	|				WHEN RoomSalesForecastTotals.Recorder REFS Document.Accommodation
	|					THEN RoomSalesForecastTotals.RoomRevenue
	|				ELSE 0
	|			END,
	|			CASE
	|				WHEN RoomSalesForecastTotals.Recorder REFS Document.SetRoomQuota
	|						AND RoomSalesForecastTotals.RoomQuota.AllotmentType = VALUE(Enum.AllotmentTypes.Definite)
	|					THEN RoomSalesForecastTotals.SalesWithoutVAT
	|				WHEN RoomSalesForecastTotals.Recorder REFS Document.Reservation
	|						AND ISNULL(RoomSalesForecastTotals.Recorder.ReservationStatus.IsGuaranteed, FALSE)
	|					THEN RoomSalesForecastTotals.SalesWithoutVAT
	|				WHEN RoomSalesForecastTotals.Recorder REFS Document.ResourceReservation
	|						AND ISNULL(RoomSalesForecastTotals.Recorder.ResourceReservationStatus.IsGuaranteed, FALSE)
	|					THEN RoomSalesForecastTotals.SalesWithoutVAT
	|				WHEN RoomSalesForecastTotals.Recorder REFS Document.Accommodation
	|					THEN RoomSalesForecastTotals.SalesWithoutVAT
	|				ELSE 0
	|			END,
	|			CASE
	|				WHEN RoomSalesForecastTotals.Recorder REFS Document.SetRoomQuota
	|						AND RoomSalesForecastTotals.RoomQuota.AllotmentType = VALUE(Enum.AllotmentTypes.Definite)
	|					THEN RoomSalesForecastTotals.RoomRevenueWithoutVAT
	|				WHEN RoomSalesForecastTotals.Recorder REFS Document.Reservation
	|						AND ISNULL(RoomSalesForecastTotals.Recorder.ReservationStatus.IsGuaranteed, FALSE)
	|					THEN RoomSalesForecastTotals.RoomRevenueWithoutVAT
	|				WHEN RoomSalesForecastTotals.Recorder REFS Document.ResourceReservation
	|						AND ISNULL(RoomSalesForecastTotals.Recorder.ResourceReservationStatus.IsGuaranteed, FALSE)
	|					THEN RoomSalesForecastTotals.RoomRevenueWithoutVAT
	|				WHEN RoomSalesForecastTotals.Recorder REFS Document.Accommodation
	|					THEN RoomSalesForecastTotals.RoomRevenueWithoutVAT
	|				ELSE 0
	|			END,
	|			CASE
	|				WHEN RoomSalesForecastTotals.Recorder REFS Document.SetRoomQuota
	|						AND RoomSalesForecastTotals.RoomQuota.AllotmentType = VALUE(Enum.AllotmentTypes.Definite)
	|					THEN RoomSalesForecastTotals.RoomsRented
	|				WHEN RoomSalesForecastTotals.Recorder REFS Document.Reservation
	|						AND ISNULL(RoomSalesForecastTotals.Recorder.ReservationStatus.IsGuaranteed, FALSE)
	|					THEN RoomSalesForecastTotals.RoomsRented
	|				WHEN RoomSalesForecastTotals.Recorder REFS Document.ResourceReservation
	|						AND ISNULL(RoomSalesForecastTotals.Recorder.ResourceReservationStatus.IsGuaranteed, FALSE)
	|					THEN RoomSalesForecastTotals.RoomsRented
	|				WHEN RoomSalesForecastTotals.Recorder REFS Document.Accommodation
	|					THEN RoomSalesForecastTotals.RoomsRented
	|				ELSE 0
	|			END,
	|			RoomSalesForecastTotals.ServiceDate
	|		FROM
	|			AccumulationRegister.SalesForecast AS RoomSalesForecastTotals
	|		WHERE
	|			RoomSalesForecastTotals.Period >= &qForecastPeriodFrom
	|			AND RoomSalesForecastTotals.Period <= &qForecastPeriodTo
	|			AND RoomSalesForecastTotals.Hotel IN HIERARCHY(&qHotel)
	|			AND &qUseForecast
	|			AND (RoomSalesForecastTotals.Room IN HIERARCHY (&qRoom)
	|					OR &qIsEmptyRoom)
	|			AND (NOT RoomSalesForecastTotals.Room IN (&qRooms2IgnoreList)
	|					OR &qRooms2IgnoreListIsEmpty)
	|			AND (RoomSalesForecastTotals.RoomType IN HIERARCHY (&qRoomType)
	|					OR &qIsEmptyRoomType)
	|			AND (RoomSalesForecastTotals.Service IN HIERARCHY (&qService)
	|					OR &qIsEmptyService)
	|			AND (RoomSalesForecastTotals.Service IN (&qServicesList)
	|					OR NOT &qUseServicesList)
	|			AND (NOT &qWithAllotments
	|					OR &qWithAllotments
	|						AND NOT ISNULL(RoomSalesForecastTotals.ParentDoc.RoomQuota.IsCommitment, FALSE))
	|			AND (NOT &qFilterByReservationCreationDate
	|						AND NOT &qLimitByTodaysDate
	|					OR NOT &qFilterByReservationCreationDate
	|						AND &qLimitByTodaysDate
	|						AND NOT &qByGroupCreationDate
	|						AND (RoomSalesForecastTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesForecastTotals.ParentDoc.Date <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(RoomSalesForecastTotals.AccountingDate, YEAR), DAY, &qTodaysDay), DAY)
	|							OR NOT RoomSalesForecastTotals.ParentDoc.Reservation.Date IS NULL
	|								AND RoomSalesForecastTotals.ParentDoc.Reservation.Date <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(RoomSalesForecastTotals.AccountingDate, YEAR), DAY, &qTodaysDay), DAY))
	|					OR NOT &qFilterByReservationCreationDate
	|						AND &qLimitByTodaysDate
	|						AND &qByGroupCreationDate
	|						AND NOT RoomSalesForecastTotals.GuestGroup.CreateDate IS NULL
	|						AND RoomSalesForecastTotals.GuestGroup.CreateDate <= ENDOFPERIOD(DATEADD(BEGINOFPERIOD(RoomSalesForecastTotals.AccountingDate, YEAR), DAY, &qTodaysDay), DAY)
	|					OR &qFilterByReservationCreationDate
	|						AND NOT &qNoYear
	|						AND NOT &qByGroupCreationDate
	|						AND NOT RoomSalesForecastTotals.ParentDoc.Date IS NULL
	|						AND RoomSalesForecastTotals.ParentDoc.Date >= &qDateFrom
	|						AND (&qDateToIsEmpty
	|							OR RoomSalesForecastTotals.ParentDoc.Date <= &qDateTo)
	|					OR &qFilterByReservationCreationDate
	|						AND NOT &qNoYear
	|						AND &qByGroupCreationDate
	|						AND NOT RoomSalesForecastTotals.GuestGroup.CreateDate IS NULL
	|						AND RoomSalesForecastTotals.GuestGroup.CreateDate >= &qDateFrom
	|						AND (&qDateToIsEmpty
	|							OR RoomSalesForecastTotals.GuestGroup.CreateDate <= &qDateTo)
	|					OR &qFilterByReservationCreationDate
	|						AND &qNoYear
	|						AND NOT &qByGroupCreationDate
	|						AND NOT RoomSalesForecastTotals.ParentDoc.Date IS NULL
	|						AND CASE
	|							WHEN &qShiftFrom = 1
	|									AND DATEADD(RoomSalesForecastTotals.ParentDoc.Date, YEAR, 2 - YEAR(RoomSalesForecastTotals.ParentDoc.Date)) <= &qDateTo
	|								THEN TRUE
	|							WHEN &qShiftFrom = 1
	|									AND DATEADD(RoomSalesForecastTotals.ParentDoc.Date, YEAR, 1 - YEAR(RoomSalesForecastTotals.ParentDoc.Date)) >= &qDateFrom
	|								THEN TRUE
	|							WHEN &qShiftFrom = 2
	|									AND DATEADD(RoomSalesForecastTotals.ParentDoc.Date, YEAR, 2 - YEAR(RoomSalesForecastTotals.ParentDoc.Date)) >= &qDateFrom
	|									AND DATEADD(RoomSalesForecastTotals.ParentDoc.Date, YEAR, 2 - YEAR(RoomSalesForecastTotals.ParentDoc.Date)) <= &qDateTo
	|								THEN TRUE
	|							ELSE FALSE
	|						END
	|					OR &qFilterByReservationCreationDate
	|						AND &qNoYear
	|						AND &qByGroupCreationDate
	|						AND NOT RoomSalesForecastTotals.GuestGroup.CreateDate IS NULL
	|						AND CASE
	|							WHEN &qShiftFrom = 1
	|									AND DATEADD(RoomSalesForecastTotals.GuestGroup.CreateDate, YEAR, 2 - YEAR(RoomSalesForecastTotals.GuestGroup.CreateDate)) <= &qDateTo
	|								THEN TRUE
	|							WHEN &qShiftFrom = 1
	|									AND DATEADD(RoomSalesForecastTotals.GuestGroup.CreateDate, YEAR, 1 - YEAR(RoomSalesForecastTotals.GuestGroup.CreateDate)) >= &qDateFrom
	|								THEN TRUE
	|							WHEN &qShiftFrom = 2
	|									AND DATEADD(RoomSalesForecastTotals.GuestGroup.CreateDate, YEAR, 2 - YEAR(RoomSalesForecastTotals.GuestGroup.CreateDate)) >= &qDateFrom
	|									AND DATEADD(RoomSalesForecastTotals.GuestGroup.CreateDate, YEAR, 2 - YEAR(RoomSalesForecastTotals.GuestGroup.CreateDate)) <= &qDateTo
	|								THEN TRUE
	|							ELSE FALSE
	|						END)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			RoomTypesListPerDay.Period,
	|			NULL,
	|			RoomTypesListPerDay.Hotel,
	|			RoomTypesListPerDay.Hotel.ReportingCurrency,
	|			NULL,
	|			RoomTypesListPerDay.RoomType,
	|			NULL,
	|			NULL,
	|			NULL,
	|			VALUE(Catalog.MarketingCodes.EmptyRef),
	|			VALUE(Catalog.SourcesOfBusiness.EmptyRef),
	|			NULL,
	|			NULL,
	|			NULL,
	|			RoomTypesListPerDay.Period,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
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
	|			NULL
	|		FROM
	|			HotelInventoryTotalsPerDay AS RoomTypesListPerDay
	|		WHERE
	|			&qUsePerDayStats
	|			AND &qUsePerRoomTypeStats
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			RoomTypesListPerMonth.Period,
	|			NULL,
	|			RoomTypesListPerMonth.Hotel,
	|			RoomTypesListPerMonth.Hotel.ReportingCurrency,
	|			NULL,
	|			RoomTypesListPerMonth.RoomType,
	|			NULL,
	|			NULL,
	|			NULL,
	|			VALUE(Catalog.MarketingCodes.EmptyRef),
	|			VALUE(Catalog.SourcesOfBusiness.EmptyRef),
	|			NULL,
	|			NULL,
	|			NULL,
	|			RoomTypesListPerMonth.Period,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
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
	|			NULL
	|		FROM
	|			HotelInventoryTotalsPerMonth AS RoomTypesListPerMonth
	|		WHERE
	|			&qUsePerMonthStats
	|			AND &qUsePerRoomTypeStats
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			SourcesOfBusinessPerDayPerHotel.Period,
	|			NULL,
	|			SourcesOfBusinessPerDayPerHotel.Hotel,
	|			SourcesOfBusinessPerDayPerHotel.Hotel.ReportingCurrency,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			VALUE(Catalog.MarketingCodes.EmptyRef),
	|			SourcesOfBusinessPerDayPerHotel.SourceOfBusiness,
	|			NULL,
	|			NULL,
	|			NULL,
	|			SourcesOfBusinessPerDayPerHotel.Period,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
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
	|			NULL
	|		FROM
	|			SourcesOfBusinessPerDayPerHotel AS SourcesOfBusinessPerDayPerHotel
	|		WHERE
	|			&qUsePerDayStats
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			MarketingCodesPerDayPerHotel.Period,
	|			NULL,
	|			MarketingCodesPerDayPerHotel.Hotel,
	|			MarketingCodesPerDayPerHotel.Hotel.ReportingCurrency,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			MarketingCodesPerDayPerHotel.MarketingCode,
	|			VALUE(Catalog.SourcesOfBusiness.EmptyRef),
	|			NULL,
	|			NULL,
	|			NULL,
	|			MarketingCodesPerDayPerHotel.Period,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
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
	|			NULL
	|		FROM
	|			MarketingCodesPerDayPerHotel AS MarketingCodesPerDayPerHotel
	|		WHERE
	|			&qUsePerDayStats
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			RoomQuotaSales.Period,
	|			RoomQuotaSales.Hotel.Company,
	|			RoomQuotaSales.Hotel,
	|			RoomQuotaSales.Hotel.ReportingCurrency,
	|			NULL,
	|			RoomQuotaSales.RoomType,
	|			RoomQuotaSales.RoomQuota.RoomRate,
	|			&qBedAccommodationType,
	|			RoomQuotaSales.RoomQuota.ClientType,
	|			RoomQuotaSales.RoomQuota.MarketingCode,
	|			RoomQuotaSales.RoomQuota.SourceOfBusiness,
	|			RoomQuotaSales.Service,
	|			RoomQuotaSales.CalendarDayType,
	|			NULL,
	|			RoomQuotaSales.Period,
	|			NULL,
	|			RoomQuotaSales.RoomQuota,
	|			NULL,
	|			RoomQuotaSales.RoomQuota.Customer,
	|			RoomQuotaSales.RoomQuota.Contract,
	|			RoomQuotaSales.RoomQuota.Agent,
	|			NULL,
	|			NULL,
	|			NULL,
	|			RoomQuotaSales.AllotmentPrice,
	|			NULL,
	|			NULL,
	|			NULL,
	|			NULL,
	|			RoomQuotaSales.RoomQuota.RoomRate.Discount,
	|			RoomQuotaSales.RoomQuota.RoomRate.DiscountType,
	|			NULL,
	|			RoomQuotaSales.RoomQuota.Agent.AgentCommission,
	|			RoomQuotaSales.RoomQuota.Agent.AgentCommissionType,
	|			RoomQuotaSales.RoomQuota.Customer.PlannedPaymentMethod,
	|			RoomQuotaSales.VATRate,
	|			RoomQuotaSales.AllotmentAmount,
	|			RoomQuotaSales.AllotmentAmount,
	|			0,
	|			CASE
	|				WHEN 100 + ISNULL(RoomQuotaSales.VATRate.TaxRate, 0) <> 0
	|					THEN RoomQuotaSales.AllotmentAmount * 100 / (100 + ISNULL(RoomQuotaSales.VATRate.TaxRate, 0))
	|				ELSE RoomQuotaSales.AllotmentAmount
	|			END,
	|			CASE
	|				WHEN 100 + ISNULL(RoomQuotaSales.VATRate.TaxRate, 0) <> 0
	|					THEN RoomQuotaSales.AllotmentAmount * 100 / (100 + ISNULL(RoomQuotaSales.VATRate.TaxRate, 0))
	|				ELSE RoomQuotaSales.AllotmentAmount
	|			END,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			RoomQuotaSales.RoomsInQuotaClosingBalance,
	|			RoomQuotaSales.BedsInQuotaClosingBalance,
	|			0,
	|			RoomQuotaSales.BedsInQuotaClosingBalance,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			RoomQuotaSales.Counter,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			NULL
	|		FROM
	|			RoomQuotaSales AS RoomQuotaSales
	|		WHERE
	|			&qWithAllotments) AS RoomSales
	|			LEFT JOIN (SELECT
	|				HotelInventoryTotalsPerDay.Hotel AS Hotel,
	|				HotelInventoryTotalsPerDay.RoomType AS RoomType,
	|				HotelInventoryTotalsPerDay.Period AS Period,
	|				HotelInventoryTotalsPerDay.CounterClosingBalance AS CounterClosingBalance,
	|				HotelInventoryTotalsPerDay.TotalRooms AS TotalRooms,
	|				HotelInventoryTotalsPerDay.TotalBeds AS TotalBeds,
	|				HotelInventoryTotalsPerDay.TotalRoomsBlocked AS TotalRoomsBlocked,
	|				HotelInventoryTotalsPerDay.TotalBedsBlocked AS TotalBedsBlocked,
	|				HotelInventoryTotalsPerDay.TotalGuestsReservedReceipt AS TotalGuestsReservedReceipt,
	|				HotelInventoryTotalsPerDay.TotalGuestsReservedExpense AS TotalGuestsReservedExpense,
	|				HotelInventoryTotalsPerDay.TotalInHouseGuestsReceipt AS TotalInHouseGuestsReceipt,
	|				HotelInventoryTotalsPerDay.TotalInHouseGuestsExpense AS TotalInHouseGuestsExpense
	|			FROM
	|				HotelInventoryTotalsPerDay AS HotelInventoryTotalsPerDay) AS RoomTypeInventoryTotalsPerDay
	|			ON RoomSales.Period = RoomTypeInventoryTotalsPerDay.Period
	|				AND RoomSales.Hotel = RoomTypeInventoryTotalsPerDay.Hotel
	|				AND RoomSales.RoomType = RoomTypeInventoryTotalsPerDay.RoomType
	|			LEFT JOIN (SELECT
	|				RoomSalesPerRoomTypePerDay.Hotel AS Hotel,
	|				RoomSalesPerRoomTypePerDay.RoomType AS RoomType,
	|				RoomSalesPerRoomTypePerDay.Period AS Period,
	|				RoomSalesPerRoomTypePerDay.NumberOfDetailedRows AS NumberOfDetailedRows
	|			FROM
	|				RoomSalesPerRoomTypePerDay AS RoomSalesPerRoomTypePerDay) AS RoomSalesPerRoomTypePerDay
	|			ON RoomSales.Period = RoomSalesPerRoomTypePerDay.Period
	|				AND RoomSales.Hotel = RoomSalesPerRoomTypePerDay.Hotel
	|				AND RoomSales.RoomType = RoomSalesPerRoomTypePerDay.RoomType
	|			LEFT JOIN (SELECT
	|				HotelInventoryTotalsPerMonth.Hotel AS Hotel,
	|				HotelInventoryTotalsPerMonth.RoomType AS RoomType,
	|				HotelInventoryTotalsPerMonth.Period AS Period,
	|				HotelInventoryTotalsPerMonth.CounterClosingBalance AS CounterClosingBalance,
	|				HotelInventoryTotalsPerMonth.TotalRooms AS TotalRooms,
	|				HotelInventoryTotalsPerMonth.TotalBeds AS TotalBeds,
	|				HotelInventoryTotalsPerMonth.TotalRoomsBlocked AS TotalRoomsBlocked,
	|				HotelInventoryTotalsPerMonth.TotalBedsBlocked AS TotalBedsBlocked,
	|				HotelInventoryTotalsPerMonth.TotalGuestsReservedReceipt AS TotalGuestsReservedReceipt,
	|				HotelInventoryTotalsPerMonth.TotalGuestsReservedExpense AS TotalGuestsReservedExpense,
	|				HotelInventoryTotalsPerMonth.TotalInHouseGuestsReceipt AS TotalInHouseGuestsReceipt,
	|				HotelInventoryTotalsPerMonth.TotalInHouseGuestsExpense AS TotalInHouseGuestsExpense
	|			FROM
	|				HotelInventoryTotalsPerMonth AS HotelInventoryTotalsPerMonth) AS RoomTypeInventoryTotalsPerMonth
	|			ON (BEGINOFPERIOD(RoomSales.Period, MONTH) = RoomTypeInventoryTotalsPerMonth.Period)
	|				AND RoomSales.Hotel = RoomTypeInventoryTotalsPerMonth.Hotel
	|				AND RoomSales.RoomType = RoomTypeInventoryTotalsPerMonth.RoomType
	|			LEFT JOIN (SELECT
	|				RoomSalesPerRoomTypePerMonth.Hotel AS Hotel,
	|				RoomSalesPerRoomTypePerMonth.RoomType AS RoomType,
	|				RoomSalesPerRoomTypePerMonth.Period AS Period,
	|				RoomSalesPerRoomTypePerMonth.NumberOfDetailedRows AS NumberOfDetailedRows
	|			FROM
	|				RoomSalesPerRoomTypePerMonth AS RoomSalesPerRoomTypePerMonth) AS RoomSalesPerRoomTypePerMonth
	|			ON (BEGINOFPERIOD(RoomSales.Period, MONTH) = RoomSalesPerRoomTypePerMonth.Period)
	|				AND RoomSales.Hotel = RoomSalesPerRoomTypePerMonth.Hotel
	|				AND RoomSales.RoomType = RoomSalesPerRoomTypePerMonth.RoomType
	|			LEFT JOIN (SELECT
	|				HotelInventoryTotalsPerPeriod.Hotel AS Hotel,
	|				HotelInventoryTotalsPerPeriod.RoomType AS RoomType,
	|				HotelInventoryTotalsPerPeriod.CounterClosingBalance AS CounterClosingBalance,
	|				HotelInventoryTotalsPerPeriod.TotalRooms AS TotalRooms,
	|				HotelInventoryTotalsPerPeriod.TotalBeds AS TotalBeds,
	|				HotelInventoryTotalsPerPeriod.TotalRoomsBlocked AS TotalRoomsBlocked,
	|				HotelInventoryTotalsPerPeriod.TotalBedsBlocked AS TotalBedsBlocked,
	|				HotelInventoryTotalsPerPeriod.TotalGuestsReservedReceipt AS TotalGuestsReservedReceipt,
	|				HotelInventoryTotalsPerPeriod.TotalGuestsReservedExpense AS TotalGuestsReservedExpense,
	|				HotelInventoryTotalsPerPeriod.TotalInHouseGuestsReceipt AS TotalInHouseGuestsReceipt,
	|				HotelInventoryTotalsPerPeriod.TotalInHouseGuestsExpense AS TotalInHouseGuestsExpense
	|			FROM
	|				HotelInventoryTotalsPerPeriod AS HotelInventoryTotalsPerPeriod) AS RoomTypeInventoryTotalsPerPeriod
	|			ON RoomSales.Hotel = RoomTypeInventoryTotalsPerPeriod.Hotel
	|				AND RoomSales.RoomType = RoomTypeInventoryTotalsPerPeriod.RoomType
	|			LEFT JOIN (SELECT
	|				RoomSalesPerRoomTypePerPeriod.Hotel AS Hotel,
	|				RoomSalesPerRoomTypePerPeriod.RoomType AS RoomType,
	|				RoomSalesPerRoomTypePerPeriod.NumberOfDetailedRows AS NumberOfDetailedRows
	|			FROM
	|				RoomSalesPerRoomTypePerPeriod AS RoomSalesPerRoomTypePerPeriod) AS RoomSalesPerRoomTypePerPeriod
	|			ON RoomSales.Hotel = RoomSalesPerRoomTypePerPeriod.Hotel
	|				AND RoomSales.RoomType = RoomSalesPerRoomTypePerPeriod.RoomType
	|			LEFT JOIN (SELECT
	|				HotelInventoryTotals.Hotel AS Hotel,
	|				HotelInventoryTotals.CounterClosingBalance AS CounterClosingBalance,
	|				HotelInventoryTotals.TotalRooms AS TotalRooms,
	|				HotelInventoryTotals.TotalBeds AS TotalBeds,
	|				HotelInventoryTotals.TotalRoomsBlocked AS TotalRoomsBlocked,
	|				HotelInventoryTotals.TotalBedsBlocked AS TotalBedsBlocked,
	|				HotelInventoryTotals.TotalGuestsReservedReceipt AS TotalGuestsReservedReceipt,
	|				HotelInventoryTotals.TotalGuestsReservedExpense AS TotalGuestsReservedExpense,
	|				HotelInventoryTotals.TotalInHouseGuestsReceipt AS TotalInHouseGuestsReceipt,
	|				HotelInventoryTotals.TotalInHouseGuestsExpense AS TotalInHouseGuestsExpense
	|			FROM
	|				HotelInventoryTotals AS HotelInventoryTotals) AS InventoryTotals
	|			ON RoomSales.Hotel = InventoryTotals.Hotel
	|			LEFT JOIN (SELECT
	|				RoomInventoryTotals.Hotel AS Hotel,
	|				RoomInventoryTotals.Room AS Room,
	|				RoomInventoryTotals.TotalRooms AS TotalRooms,
	|				RoomInventoryTotals.TotalBeds AS TotalBeds,
	|				RoomInventoryTotals.TotalRoomsBlocked AS TotalRoomsBlocked,
	|				RoomInventoryTotals.TotalBedsBlocked AS TotalBedsBlocked
	|			FROM
	|				RoomInventoryTotals AS RoomInventoryTotals) AS RoomInventoryTotals
	|			ON RoomSales.Hotel = RoomInventoryTotals.Hotel
	|				AND RoomSales.Room = RoomInventoryTotals.Room
	|			LEFT JOIN (SELECT
	|				RoomTotalSales.Hotel AS Hotel,
	|				RoomTotalSales.TotalBedsRented AS TotalBedsRented,
	|				RoomTotalSales.TotalRoomsRented AS TotalRoomsRented,
	|				RoomTotalSales.TotalSalesAmount AS TotalSalesAmount
	|			FROM
	|				RoomTotalSales AS RoomTotalSales) AS TotalSales
	|			ON RoomSales.Hotel = TotalSales.Hotel
	|			LEFT JOIN (SELECT
	|				CalendarDays.CalendarDayType AS CalendarDayType,
	|				CalendarDays.AccountingDate AS AccountingDate
	|			FROM
	|				InformationRegister.CalendarDays.SliceLast(&qPriceCalculationDate, Calendar = &qCalendar) AS CalendarDays) AS CalendarDayTypes
	|			ON RoomSales.AccountingDate = CalendarDayTypes.AccountingDate
	|			LEFT JOIN (SELECT
	|				RoomSalesPerRoomTypeAndCalendarDayTypePerDay.Hotel AS Hotel,
	|				RoomSalesPerRoomTypeAndCalendarDayTypePerDay.RoomType AS RoomType,
	|				RoomSalesPerRoomTypeAndCalendarDayTypePerDay.CalendarDayType AS CalendarDayType,
	|				RoomSalesPerRoomTypeAndCalendarDayTypePerDay.Period AS Period,
	|				RoomSalesPerRoomTypeAndCalendarDayTypePerDay.NumberOfDetailedRows AS NumberOfDetailedRows
	|			FROM
	|				RoomSalesPerRoomTypeAndCalendarDayTypePerDay AS RoomSalesPerRoomTypeAndCalendarDayTypePerDay) AS RoomSalesPerRoomTypeAndCalendarDayTypePerDay
	|			ON RoomSales.Period = RoomSalesPerRoomTypeAndCalendarDayTypePerDay.Period
	|				AND RoomSales.Hotel = RoomSalesPerRoomTypeAndCalendarDayTypePerDay.Hotel
	|				AND RoomSales.RoomType = RoomSalesPerRoomTypeAndCalendarDayTypePerDay.RoomType
	|				AND RoomSales.CalendarDayType = RoomSalesPerRoomTypeAndCalendarDayTypePerDay.CalendarDayType
	|			LEFT JOIN (SELECT
	|				RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.Hotel AS Hotel,
	|				RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.RoomType AS RoomType,
	|				RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.CalendarDayType AS CalendarDayType,
	|				RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.Period AS Period,
	|				RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.NumberOfDetailedRows AS NumberOfDetailedRows
	|			FROM
	|				RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay AS RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay) AS RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay
	|			ON RoomSales.Period = RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.Period
	|				AND RoomSales.Hotel = RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.Hotel
	|				AND RoomSales.RoomType = RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.RoomType
	|				AND (CalendarDayTypes.CalendarDayType = RoomSalesPerRoomTypeAndChoosenCalendarDayTypePerDay.CalendarDayType)
	|			LEFT JOIN InformationRegister.ReservationCustomAttributeValues AS ReservationCustomAttributeValues1
	|			ON (RoomSales.ParentDoc.Reservation = ReservationCustomAttributeValues1.Owner
	|					OR RoomSales.ParentDoc = ReservationCustomAttributeValues1.Owner
	|						AND RoomSales.ParentDoc.Reservation.Number IS NULL)
	|				AND (ReservationCustomAttributeValues1.Characteristic = &qCustomAttribute1)
	|			LEFT JOIN InformationRegister.ReservationCustomAttributeValues AS ReservationCustomAttributeValues2
	|			ON (RoomSales.ParentDoc.Reservation = ReservationCustomAttributeValues2.Owner
	|					OR RoomSales.ParentDoc = ReservationCustomAttributeValues2.Owner
	|						AND RoomSales.ParentDoc.Reservation.Number IS NULL)
	|				AND (ReservationCustomAttributeValues2.Characteristic = &qCustomAttribute2)
	|			LEFT JOIN InformationRegister.ReservationCustomAttributeValues AS ReservationCustomAttributeValues3
	|			ON (RoomSales.ParentDoc.Reservation = ReservationCustomAttributeValues3.Owner
	|					OR RoomSales.ParentDoc = ReservationCustomAttributeValues3.Owner
	|						AND RoomSales.ParentDoc.Reservation.Number IS NULL)
	|				AND (ReservationCustomAttributeValues3.Characteristic = &qCustomAttribute3)) AS RoomSalesTurnovers
	|{WHERE
	|	RoomSalesTurnovers.Company.*,
	|	RoomSalesTurnovers.Hotel.*,
	|	RoomSalesTurnovers.ReportingCurrency.*,
	|	RoomSalesTurnovers.Room.*,
	|	RoomSalesTurnovers.RoomType.*,
	|	RoomSalesTurnovers.RoomRate.*,
	|	RoomSalesTurnovers.CalendarDayType.*,
	|	RoomSalesTurnovers.PriceTag.*,
	|	RoomSalesTurnovers.ExtCalendarDayType.*,
	|	RoomSalesTurnovers.AccommodationType.*,
	|	RoomSalesTurnovers.ClientType.*,
	|	RoomSalesTurnovers.MarketingCode.*,
	|	RoomSalesTurnovers.SourceOfBusiness.*,
	|	RoomSalesTurnovers.ParentDoc.*,
	|	RoomSalesTurnovers.Reservation.* AS Reservation,
	|	RoomSalesTurnovers.ReservationDate AS ReservationDate,
	|	RoomSalesTurnovers.ReservationWeek AS ReservationWeek,
	|	RoomSalesTurnovers.ReservationMonth AS ReservationMonth,
	|	RoomSalesTurnovers.ReservationYear AS ReservationYear,
	|	RoomSalesTurnovers.DaysBeforeCheckIn AS DaysBeforeCheckIn,
	|	RoomSalesTurnovers.WeeksBeforeCheckIn AS WeeksBeforeCheckIn,
	|	RoomSalesTurnovers.MonthsBeforeCheckIn AS MonthsBeforeCheckIn,
	|	RoomSalesTurnovers.RoomQuota.*,
	|	RoomSalesTurnovers.Service.*,
	|	RoomSalesTurnovers.RoomPrice AS RoomPrice,
	|	RoomSalesTurnovers.GuestGroup.* AS GuestGroup,
	|	RoomSalesTurnovers.Customer.* AS Customer,
	|	RoomSalesTurnovers.Contract.* AS Contract,
	|	RoomSalesTurnovers.Agent.* AS Agent,
	|	RoomSalesTurnovers.Client.* AS Client,
	|	RoomSalesTurnovers.Resource.* AS Resource,
	|	RoomSalesTurnovers.Folio.* AS Folio,
	|	RoomSalesTurnovers.Price AS Price,
	|	RoomSalesTurnovers.ResourceType.* AS ResourceType,
	|	RoomSalesTurnovers.TripPurpose.* AS TripPurpose,
	|	RoomSalesTurnovers.HotelProduct.* AS HotelProduct,
	|	RoomSalesTurnovers.Author.* AS Author,
	|	RoomSalesTurnovers.Discount AS Discount,
	|	RoomSalesTurnovers.DiscountType.* AS DiscountType,
	|	RoomSalesTurnovers.DiscountCard.* AS DiscountCard,
	|	RoomSalesTurnovers.AgentCommission AS AgentCommission,
	|	RoomSalesTurnovers.AgentCommissionType.* AS AgentCommissionType,
	|	RoomSalesTurnovers.PaymentMethod.* AS PaymentMethod,
	|	RoomSalesTurnovers.VATRate.* AS VATRate,
	|	RoomSalesTurnovers.Sales AS Sales,
	|	RoomSalesTurnovers.SalesWithoutCommission AS SalesWithoutCommission,
	|	RoomSalesTurnovers.RoomRevenue AS RoomRevenue,
	|	RoomSalesTurnovers.RoomRevenueWithoutCommission AS RoomRevenueWithoutCommission,
	|	RoomSalesTurnovers.InPriceRevenue AS InPriceRevenue,
	|	RoomSalesTurnovers.InPriceRevenueWithoutCommission AS InPriceRevenueWithoutCommission,
	|	RoomSalesTurnovers.ExtraBedRevenue AS ExtraBedRevenue,
	|	RoomSalesTurnovers.RoomRevenueWithoutExtraBed AS RoomRevenueWithoutExtraBed,
	|	RoomSalesTurnovers.SalesWithoutVAT AS SalesWithoutVAT,
	|	RoomSalesTurnovers.SalesWithoutVATWithoutCommission AS SalesWithoutVATWithoutCommission,
	|	RoomSalesTurnovers.RoomRevenueWithoutVAT AS RoomRevenueWithoutVAT,
	|	RoomSalesTurnovers.RoomRevenueWithoutVATWithoutCommission AS RoomRevenueWithoutVATWithoutCommission,
	|	RoomSalesTurnovers.InPriceRevenueWithoutVAT AS InPriceRevenueWithoutVAT,
	|	RoomSalesTurnovers.InPriceRevenueWithoutVATWithoutCommission AS InPriceRevenueWithoutVATWithoutCommission,
	|	RoomSalesTurnovers.ExtraBedRevenueWithoutVAT AS ExtraBedRevenueWithoutVAT,
	|	RoomSalesTurnovers.RoomRevenueWithoutExtraBedWithoutVAT AS RoomRevenueWithoutExtraBedWithoutVAT,
	|	(RoomSalesTurnovers.Sales - RoomSalesTurnovers.RoomRevenue) AS ExtraServicesRevenue,
	|	(RoomSalesTurnovers.SalesWithoutVAT - RoomSalesTurnovers.RoomRevenueWithoutVAT) AS ExtraServicesRevenueWithoutVAT,
	|	RoomSalesTurnovers.CommissionSum AS CommissionSum,
	|	RoomSalesTurnovers.CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|	RoomSalesTurnovers.DiscountSum AS DiscountSum,
	|	RoomSalesTurnovers.DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|	RoomSalesTurnovers.ExtraBedDiscountSum AS ExtraBedDiscountSum,
	|	RoomSalesTurnovers.DiscountSumWithoutExtraBed AS DiscountSumWithoutExtraBed,
	|	RoomSalesTurnovers.RevenueSegmentRoomSales AS RevenueSegmentRoomSales,
	|	RoomSalesTurnovers.RevenueSegmentRoomSalesWithoutVAT AS RevenueSegmentRoomSalesWithoutVAT,
	|	RoomSalesTurnovers.RevenueSegmentFaBSales AS RevenueSegmentFaBSales,
	|	RoomSalesTurnovers.RevenueSegmentFaBSalesWithoutVAT AS RevenueSegmentFaBSalesWithoutVAT,
	|	RoomSalesTurnovers.RevenueSegmentSPASales AS RevenueSegmentSPASales,
	|	RoomSalesTurnovers.RevenueSegmentSPASalesWithoutVAT AS RevenueSegmentSPASalesWithoutVAT,
	|	RoomSalesTurnovers.RevenueSegmentConferenceSales AS RevenueSegmentConferenceSales,
	|	RoomSalesTurnovers.RevenueSegmentConferenceSalesWithoutVAT AS RevenueSegmentConferenceSalesWithoutVAT,
	|	RoomSalesTurnovers.RevenueSegmentOtherSales AS RevenueSegmentOtherSales,
	|	RoomSalesTurnovers.RevenueSegmentOtherSalesWithoutVAT AS RevenueSegmentOtherSalesWithoutVAT,
	|	RoomSalesTurnovers.RoomsRented AS RoomsRented,
	|	RoomSalesTurnovers.BedsRented AS BedsRented,
	|	RoomSalesTurnovers.AdditionalBedsRented AS AdditionalBedsRented,
	|	RoomSalesTurnovers.GuestDays AS GuestDays,
	|	RoomSalesTurnovers.GuestDaysWithoutExtraBed AS GuestDaysWithoutExtraBed,
	|	RoomSalesTurnovers.ExtraBedGuestDays AS ExtraBedGuestDays,
	|	RoomSalesTurnovers.GuestsCheckedIn AS GuestsCheckedIn,
	|	RoomSalesTurnovers.RoomsCheckedIn AS RoomsCheckedIn,
	|	RoomSalesTurnovers.BedsCheckedIn AS BedsCheckedIn,
	|	RoomSalesTurnovers.AdditionalBedsCheckedIn AS AdditionalBedsCheckedIn,
	|	(CASE
	|			WHEN RoomSalesTurnovers.RoomsCheckedIn <> 0
	|				THEN CAST(RoomSalesTurnovers.BookingWindow / RoomSalesTurnovers.RoomsCheckedIn AS NUMBER(10, 0))
	|			ELSE 0
	|		END) AS BookingWindow,
	|	(CASE
	|			WHEN RoomSalesTurnovers.RoomsCheckedIn <> 0
	|				THEN CAST(RoomSalesTurnovers.BookingWindow / RoomSalesTurnovers.RoomsCheckedIn AS NUMBER(10, 0))
	|			ELSE 0
	|		END) AS BookingWindowDimension,
	|	(CASE
	|			WHEN ISNULL(RoomSalesTurnovers.GuestsCheckedIn, 0) <> 0
	|				THEN ISNULL(RoomSalesTurnovers.GuestDays, 0) / ISNULL(RoomSalesTurnovers.GuestsCheckedIn, 0)
	|			ELSE 0
	|		END) AS ALS,
	|	RoomSalesTurnovers.Quantity AS Quantity,
	|	RoomSalesTurnovers.AccountingDate,
	|	(DAY(RoomSalesTurnovers.AccountingDate)) AS AccountingDay,
	|	(WEEKDAY(RoomSalesTurnovers.AccountingDate)) AS AccountingWeekday,
	|	(BEGINOFPERIOD(RoomSalesTurnovers.AccountingDate, WEEK)) AS AccountingWeek,
	|	(BEGINOFPERIOD(RoomSalesTurnovers.AccountingDate, MONTH)) AS AccountingMonth,
	|	(BEGINOFPERIOD(RoomSalesTurnovers.AccountingDate, QUARTER)) AS AccountingQuarter,
	|	(YEAR(RoomSalesTurnovers.AccountingDate)) AS AccountingYear,
	|	(BEGINOFPERIOD(DATEADD(RoomSalesTurnovers.AccountingDate, YEAR, -(YEAR(RoomSalesTurnovers.AccountingDate) - 2)), DAY)) AS AccountingDateNoYear,
	|	(BEGINOFPERIOD(DATEADD(RoomSalesTurnovers.AccountingDate, YEAR, -(YEAR(RoomSalesTurnovers.AccountingDate) - 2)), WEEK)) AS AccountingWeekNoYear,
	|	(BEGINOFPERIOD(DATEADD(RoomSalesTurnovers.AccountingDate, YEAR, -(YEAR(RoomSalesTurnovers.AccountingDate) - 2)), MONTH)) AS AccountingMonthNoYear,
	|	(BEGINOFPERIOD(DATEADD(RoomSalesTurnovers.AccountingDate, YEAR, -(YEAR(RoomSalesTurnovers.AccountingDate) - 2)), QUARTER)) AS AccountingQuarterNoYear,
	|	(BEGINOFPERIOD(DATEADD(RoomSalesTurnovers.ReservationDate, YEAR, -(YEAR(RoomSalesTurnovers.ReservationDate) - 2)), DAY)) AS ReservationDateNoYear,
	|	(BEGINOFPERIOD(DATEADD(RoomSalesTurnovers.ReservationWeek, YEAR, -(YEAR(RoomSalesTurnovers.ReservationWeek) - 2)), DAY)) AS ReservationWeekNoYear,
	|	(BEGINOFPERIOD(DATEADD(RoomSalesTurnovers.ReservationMonth, YEAR, -(YEAR(RoomSalesTurnovers.ReservationMonth) - 2)), DAY)) AS ReservationMonthNoYear,
	|	RoomSalesTurnovers.CustomAttribute1.* AS CustomAttribute1,
	|	RoomSalesTurnovers.CustomAttribute2.* AS CustomAttribute2,
	|	RoomSalesTurnovers.CustomAttribute3.* AS CustomAttribute3,
	|	(CASE
	|			WHEN NOT RoomSalesTurnovers.GuestGroup.GroupType.Code IS NULL
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS IsGroupReservation,
	|	RoomSalesTurnovers.GuaranteedSales AS GuaranteedSales,
	|	RoomSalesTurnovers.GuaranteedRoomRevenue AS GuaranteedRoomRevenue,
	|	RoomSalesTurnovers.GuaranteedSalesWithoutVAT AS GuaranteedSalesWithoutVAT,
	|	RoomSalesTurnovers.GuaranteedRoomRevenueWithoutVAT AS GuaranteedRoomRevenueWithoutVAT,
	|	RoomSalesTurnovers.GuaranteedRoomsRented AS GuaranteedRoomsRented,
	|	RoomSalesTurnovers.NonGuaranteedSales AS NonGuaranteedSales,
	|	RoomSalesTurnovers.NonGuaranteedRoomRevenue AS NonGuaranteedRoomRevenue,
	|	RoomSalesTurnovers.NonGuaranteedSalesWithoutVAT AS NonGuaranteedSalesWithoutVAT,
	|	RoomSalesTurnovers.NonGuaranteedRoomRevenueWithoutVAT AS NonGuaranteedRoomRevenueWithoutVAT,
	|	RoomSalesTurnovers.NonGuaranteedRoomsRented AS NonGuaranteedRoomsRented,
	|	RoomSalesTurnovers.ServiceDate}
	|
	|ORDER BY
	|	ReportingCurrency,
	|	Room
	|{ORDER BY
	|	Company.*,
	|	Hotel.*,
	|	ReportingCurrency.*,
	|	Room.*,
	|	RoomType.*,
	|	RoomRate.*,
	|	CalendarDayType.*,
	|	PriceTag.*,
	|	RoomSalesTurnovers.ExtCalendarDayType.*,
	|	AccommodationType.*,
	|	ClientType.*,
	|	MarketingCode.*,
	|	SourceOfBusiness.*,
	|	Service.*,
	|	ParentDoc.*,
	|	RoomSalesTurnovers.Reservation.* AS Reservation,
	|	RoomSalesTurnovers.ReservationDate AS ReservationDate,
	|	RoomSalesTurnovers.ReservationWeek AS ReservationWeek,
	|	RoomSalesTurnovers.ReservationMonth AS ReservationMonth,
	|	RoomSalesTurnovers.ReservationYear AS ReservationYear,
	|	RoomSalesTurnovers.DaysBeforeCheckIn AS DaysBeforeCheckIn,
	|	RoomSalesTurnovers.WeeksBeforeCheckIn AS WeeksBeforeCheckIn,
	|	RoomSalesTurnovers.MonthsBeforeCheckIn AS MonthsBeforeCheckIn,
	|	RoomQuota.*,
	|	RoomPrice,
	|	RoomSalesTurnovers.GuestGroup.* AS GuestGroup,
	|	RoomSalesTurnovers.Customer.* AS Customer,
	|	RoomSalesTurnovers.Contract.* AS Contract,
	|	RoomSalesTurnovers.Agent.* AS Agent,
	|	RoomSalesTurnovers.Client.* AS Client,
	|	RoomSalesTurnovers.Resource.* AS Resource,
	|	RoomSalesTurnovers.Folio.* AS Folio,
	|	RoomSalesTurnovers.Price AS Price,
	|	RoomSalesTurnovers.ResourceType.* AS ResourceType,
	|	RoomSalesTurnovers.TripPurpose.* AS TripPurpose,
	|	RoomSalesTurnovers.HotelProduct.* AS HotelProduct,
	|	RoomSalesTurnovers.Author.* AS Author,
	|	RoomSalesTurnovers.Discount AS Discount,
	|	RoomSalesTurnovers.DiscountType.* AS DiscountType,
	|	RoomSalesTurnovers.DiscountCard.* AS DiscountCard,
	|	RoomSalesTurnovers.AgentCommission AS AgentCommission,
	|	RoomSalesTurnovers.AgentCommissionType.* AS AgentCommissionType,
	|	RoomSalesTurnovers.PaymentMethod.* AS PaymentMethod,
	|	RoomSalesTurnovers.VATRate.* AS VATRate,
	|	Sales,
	|	SalesWithoutCommission,
	|	RoomRevenue,
	|	RoomRevenueWithoutCommission,
	|	InPriceRevenue,
	|	InPriceRevenueWithoutCommission,
	|	ExtraBedRevenue,
	|	RoomRevenueWithoutExtraBed,
	|	SalesWithoutVAT,
	|	SalesWithoutVATWithoutCommission,
	|	RoomRevenueWithoutVAT,
	|	RoomRevenueWithoutVATWithoutCommission,
	|	InPriceRevenueWithoutVAT,
	|	InPriceRevenueWithoutVATWithoutCommission,
	|	ExtraBedRevenueWithoutVAT,
	|	RoomRevenueWithoutExtraBedWithoutVAT,
	|	ExtraServicesRevenue,
	|	ExtraServicesRevenueWithoutVAT,
	|	CommissionSum,
	|	CommissionSumWithoutVAT,
	|	DiscountSum,
	|	DiscountSumWithoutVAT,
	|	ExtraBedDiscountSum,
	|	DiscountSumWithoutExtraBed,
	|	RevenueSegmentRoomSales,
	|	RevenueSegmentRoomSalesWithoutVAT,
	|	RevenueSegmentFaBSales,
	|	RevenueSegmentFaBSalesWithoutVAT,
	|	RevenueSegmentSPASales,
	|	RevenueSegmentSPASalesWithoutVAT,
	|	RevenueSegmentConferenceSales,
	|	RevenueSegmentConferenceSalesWithoutVAT,
	|	RevenueSegmentOtherSales,
	|	RevenueSegmentOtherSalesWithoutVAT,
	|	RoomsRented,
	|	BedsRented,
	|	AdditionalBedsRented,
	|	GuestDays,
	|	ExtraBedGuestDays,
	|	GuestDaysWithoutExtraBed,
	|	GuestsCheckedIn,
	|	RoomsCheckedIn,
	|	BedsCheckedIn,
	|	AdditionalBedsCheckedIn,
	|	BookingWindow,
	|	BookingWindowDimension,
	|	ALS,
	|	Quantity,
	|	TotalSalesAmount,
	|	TotalSalesPercent,
	|	TotalBedsRentedPercent,
	|	TotalRoomsRentedPercent,
	|	AccountingDate,
	|	(DAY(RoomSalesTurnovers.AccountingDate)) AS AccountingDay,
	|	(WEEKDAY(RoomSalesTurnovers.AccountingDate)) AS AccountingWeekday,
	|	(CASE
	|			WHEN WEEKDAY(RoomSalesTurnovers.AccountingDate) = 1
	|				THEN &qMonday
	|			WHEN WEEKDAY(RoomSalesTurnovers.AccountingDate) = 2
	|				THEN &qTuesday
	|			WHEN WEEKDAY(RoomSalesTurnovers.AccountingDate) = 3
	|				THEN &qWednesday
	|			WHEN WEEKDAY(RoomSalesTurnovers.AccountingDate) = 4
	|				THEN &qThursday
	|			WHEN WEEKDAY(RoomSalesTurnovers.AccountingDate) = 5
	|				THEN &qFriday
	|			WHEN WEEKDAY(RoomSalesTurnovers.AccountingDate) = 6
	|				THEN &qSaturday
	|			WHEN WEEKDAY(RoomSalesTurnovers.AccountingDate) = 7
	|				THEN &qSunday
	|			ELSE NULL
	|		END) AS AccountingWeekdayName,
	|	(BEGINOFPERIOD(RoomSalesTurnovers.AccountingDate, WEEK)) AS AccountingWeek,
	|	(BEGINOFPERIOD(RoomSalesTurnovers.AccountingDate, MONTH)) AS AccountingMonth,
	|	(BEGINOFPERIOD(RoomSalesTurnovers.AccountingDate, QUARTER)) AS AccountingQuarter,
	|	(YEAR(RoomSalesTurnovers.AccountingDate)) AS AccountingYear,
	|	(BEGINOFPERIOD(DATEADD(RoomSalesTurnovers.AccountingDate, YEAR, -(YEAR(RoomSalesTurnovers.AccountingDate) - 2)), DAY)) AS AccountingDateNoYear,
	|	(BEGINOFPERIOD(DATEADD(RoomSalesTurnovers.AccountingDate, YEAR, -(YEAR(RoomSalesTurnovers.AccountingDate) - 2)), WEEK)) AS AccountingWeekNoYear,
	|	(BEGINOFPERIOD(DATEADD(RoomSalesTurnovers.AccountingDate, YEAR, -(YEAR(RoomSalesTurnovers.AccountingDate) - 2)), MONTH)) AS AccountingMonthNoYear,
	|	(BEGINOFPERIOD(DATEADD(RoomSalesTurnovers.AccountingDate, YEAR, -(YEAR(RoomSalesTurnovers.AccountingDate) - 2)), QUARTER)) AS AccountingQuarterNoYear,
	|	(BEGINOFPERIOD(DATEADD(RoomSalesTurnovers.ReservationDate, YEAR, -(YEAR(RoomSalesTurnovers.ReservationDate) - 2)), DAY)) AS ReservationDateNoYear,
	|	(BEGINOFPERIOD(DATEADD(RoomSalesTurnovers.ReservationWeek, YEAR, -(YEAR(RoomSalesTurnovers.ReservationWeek) - 2)), DAY)) AS ReservationWeekNoYear,
	|	(BEGINOFPERIOD(DATEADD(RoomSalesTurnovers.ReservationMonth, YEAR, -(YEAR(RoomSalesTurnovers.ReservationMonth) - 2)), DAY)) AS ReservationMonthNoYear,
	|	RoomSalesTurnovers.CustomAttribute1.* AS CustomAttribute1,
	|	RoomSalesTurnovers.CustomAttribute2.* AS CustomAttribute2,
	|	RoomSalesTurnovers.CustomAttribute3.* AS CustomAttribute3,
	|	(CASE
	|			WHEN NOT RoomSalesTurnovers.GuestGroup.GroupType.Code IS NULL
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS IsGroupReservation,
	|	GuaranteedSales AS GuaranteedSales,
	|	GuaranteedRoomRevenue AS GuaranteedRoomRevenue,
	|	GuaranteedSalesWithoutVAT AS GuaranteedSalesWithoutVAT,
	|	GuaranteedRoomRevenueWithoutVAT AS GuaranteedRoomRevenueWithoutVAT,
	|	GuaranteedRoomsRented AS GuaranteedRoomsRented,
	|	NonGuaranteedSales AS NonGuaranteedSales,
	|	NonGuaranteedRoomRevenue AS NonGuaranteedRoomRevenue,
	|	NonGuaranteedSalesWithoutVAT AS NonGuaranteedSalesWithoutVAT,
	|	NonGuaranteedRoomRevenueWithoutVAT AS NonGuaranteedRoomRevenueWithoutVAT,
	|	NonGuaranteedRoomsRented AS NonGuaranteedRoomsRented,
	|	ServiceDate}
	|TOTALS
	|	SUM(Sales),
	|	SUM(SalesWithoutCommission),
	|	SUM(RoomRevenue),
	|	SUM(RoomRevenueWithoutCommission),
	|	SUM(InPriceRevenue),
	|	SUM(InPriceRevenueWithoutCommission),
	|	SUM(ExtraBedRevenue),
	|	SUM(RoomRevenueWithoutExtraBed),
	|	SUM(SalesWithoutVAT),
	|	SUM(SalesWithoutVATWithoutCommission),
	|	SUM(RoomRevenueWithoutVAT),
	|	SUM(RoomRevenueWithoutVATWithoutCommission),
	|	SUM(RoomSalesTurnovers.Sales) - SUM(RoomSalesTurnovers.RoomRevenue) AS ExtraServicesRevenue,
	|	SUM(RoomSalesTurnovers.SalesWithoutVAT) - SUM(RoomSalesTurnovers.RoomRevenueWithoutVAT) AS ExtraServicesRevenueWithoutVAT,
	|	SUM(InPriceRevenueWithoutVAT),
	|	SUM(InPriceRevenueWithoutVATWithoutCommission),
	|	SUM(ExtraBedRevenueWithoutVAT),
	|	SUM(RoomRevenueWithoutExtraBedWithoutVAT),
	|	SUM(CommissionSum),
	|	SUM(CommissionSumWithoutVAT),
	|	SUM(DiscountSum),
	|	SUM(DiscountSumWithoutVAT),
	|	SUM(ExtraBedDiscountSum),
	|	SUM(DiscountSumWithoutExtraBed),
	|	SUM(RevenueSegmentRoomSales),
	|	SUM(RevenueSegmentRoomSalesWithoutVAT),
	|	SUM(RevenueSegmentFaBSales),
	|	SUM(RevenueSegmentFaBSalesWithoutVAT),
	|	SUM(RevenueSegmentSPASales),
	|	SUM(RevenueSegmentSPASalesWithoutVAT),
	|	SUM(RevenueSegmentConferenceSales),
	|	SUM(RevenueSegmentConferenceSalesWithoutVAT),
	|	SUM(RevenueSegmentOtherSales),
	|	SUM(RevenueSegmentOtherSalesWithoutVAT),
	|	CAST(SUM(RoomsRented) AS NUMBER(17, 3)) AS RoomsRented,
	|	CAST(SUM(BedsRented) AS NUMBER(17, 3)) AS BedsRented,
	|	CAST(SUM(AdditionalBedsRented) AS NUMBER(17, 3)) AS AdditionalBedsRented,
	|	CAST(SUM(GuestDays) AS NUMBER(17, 3)) AS GuestDays,
	|	CAST(SUM(GuestDaysWithoutExtraBed) AS NUMBER(17, 3)) AS GuestDaysWithoutExtraBed,
	|	CAST(SUM(ExtraBedGuestDays) AS NUMBER(17, 3)) AS ExtraBedGuestDays,
	|	CAST(SUM(GuestsCheckedIn) AS NUMBER(17, 3)) AS GuestsCheckedIn,
	|	CAST(SUM(RoomsCheckedIn) AS NUMBER(17, 3)) AS RoomsCheckedIn,
	|	CAST(SUM(BedsCheckedIn) AS NUMBER(17, 3)) AS BedsCheckedIn,
	|	CAST(SUM(AdditionalBedsCheckedIn) AS NUMBER(17, 3)) AS AdditionalBedsCheckedIn,
	|	CASE
	|		WHEN SUM(RoomsCheckedIn) <> 0
	|			THEN CAST(SUM(BookingWindow) / SUM(RoomsCheckedIn) AS NUMBER(10, 0))
	|		ELSE 0
	|	END AS BookingWindow,
	|	CASE
	|		WHEN SUM(GuestsCheckedIn) <> 0
	|			THEN SUM(GuestDays) / SUM(GuestsCheckedIn)
	|		ELSE 0
	|	END AS ALS,
	|	CAST(SUM(Quantity) AS NUMBER(17, 3)) AS Quantity,
	|	CAST(MAX(RoomsPerPeriod) AS NUMBER(17, 0)) AS RoomsPerPeriod,
	|	CAST(MAX(BedsPerPeriod) AS NUMBER(17, 0)) AS BedsPerPeriod,
	|	CAST(MAX(RoomsBlockedPerPeriod) AS NUMBER(17, 3)) AS RoomsBlockedPerPeriod,
	|	CAST(MAX(BedsBlockedPerPeriod) AS NUMBER(17, 3)) AS BedsBlockedPerPeriod,
	|	CAST(SUM(RoomsPerRoomTypePerDay) AS NUMBER(17, 0)) AS RoomsPerRoomTypePerDay,
	|	CAST(SUM(BedsPerRoomTypePerDay) AS NUMBER(17, 0)) AS BedsPerRoomTypePerDay,
	|	CAST(SUM(RoomsBlockedPerRoomTypePerDay) AS NUMBER(17, 3)) AS RoomsBlockedPerRoomTypePerDay,
	|	CAST(SUM(BedsBlockedPerRoomTypePerDay) AS NUMBER(17, 3)) AS BedsBlockedPerRoomTypePerDay,
	|	CAST(SUM(RoomsPerRoomTypePerMonth) AS NUMBER(17, 0)) AS RoomsPerRoomTypePerMonth,
	|	CAST(SUM(BedsPerRoomTypePerMonth) AS NUMBER(17, 0)) AS BedsPerRoomTypePerMonth,
	|	CAST(SUM(RoomsBlockedPerRoomTypePerMonth) AS NUMBER(17, 3)) AS RoomsBlockedPerRoomTypePerMonth,
	|	CAST(SUM(BedsBlockedPerRoomTypePerMonth) AS NUMBER(17, 3)) AS BedsBlockedPerRoomTypePerMonth,
	|	CAST(SUM(RoomsPerRoomTypePerPeriod) AS NUMBER(17, 0)) AS RoomsPerRoomTypePerPeriod,
	|	CAST(SUM(BedsPerRoomTypePerPeriod) AS NUMBER(17, 0)) AS BedsPerRoomTypePerPeriod,
	|	CAST(SUM(RoomsBlockedPerRoomTypePerPeriod) AS NUMBER(17, 3)) AS RoomsBlockedPerRoomTypePerPeriod,
	|	CAST(SUM(BedsBlockedPerRoomTypePerPeriod) AS NUMBER(17, 3)) AS BedsBlockedPerRoomTypePerPeriod,
	|	CAST(SUM(RoomsPerRoomTypeAndCalendarDayTypePerDay) AS NUMBER(17, 0)) AS RoomsPerRoomTypeAndCalendarDayTypePerDay,
	|	CAST(SUM(BedsPerRoomTypeAndCalendarDayTypePerDay) AS NUMBER(17, 0)) AS BedsPerRoomTypeAndCalendarDayTypePerDay,
	|	CAST(SUM(RoomsBlockedPerRoomTypeAndCalendarDayTypePerDay) AS NUMBER(17, 3)) AS RoomsBlockedPerRoomTypeAndCalendarDayTypePerDay,
	|	CAST(SUM(BedsBlockedPerRoomTypeAndCalendarDayTypePerDay) AS NUMBER(17, 3)) AS BedsBlockedPerRoomTypeAndCalendarDayTypePerDay,
	|	CAST(SUM(RoomsPerRoomTypeAndChoosenCalendarDayTypePerDay) AS NUMBER(17, 0)) AS RoomsPerRoomTypeAndChoosenCalendarDayTypePerDay,
	|	CAST(SUM(BedsPerRoomTypeAndChoosenCalendarDayTypePerDay) AS NUMBER(17, 0)) AS BedsPerRoomTypeAndChoosenCalendarDayTypePerDay,
	|	CAST(SUM(RoomsBlockedPerRoomTypeAndChoosenCalendarDayTypePerDay) AS NUMBER(17, 3)) AS RoomsBlockedPerRoomTypeAndChoosenCalendarDayTypePerDay,
	|	CAST(SUM(BedsBlockedPerRoomTypeAndChoosenCalendarDayTypePerDay) AS NUMBER(17, 3)) AS BedsBlockedPerRoomTypeAndChoosenCalendarDayTypePerDay,
	|	CASE
	|		WHEN SUM(RoomsRented) = 0
	|			THEN 0
	|		ELSE CAST(SUM(RoomRevenue) / SUM(RoomsRented) AS NUMBER(17, 2))
	|	END AS AverageRoomPrice,
	|	CASE
	|		WHEN SUM(BedsRented) = 0
	|			THEN 0
	|		ELSE CAST(SUM(RoomRevenue) / SUM(BedsRented) AS NUMBER(17, 2))
	|	END AS AverageBedPrice,
	|	CASE
	|		WHEN SUM(RoomsRented) = 0
	|			THEN 0
	|		ELSE CAST(SUM(RoomRevenueWithoutVAT) / SUM(RoomsRented) AS NUMBER(17, 2))
	|	END AS AverageRoomPriceWithoutVAT,
	|	CASE
	|		WHEN SUM(BedsRented) = 0
	|			THEN 0
	|		ELSE CAST(SUM(RoomRevenueWithoutVAT) / SUM(BedsRented) AS NUMBER(17, 2))
	|	END AS AverageBedPriceWithoutVAT,
	|	CASE
	|		WHEN MAX(RoomsPerPeriod) = 0
	|			THEN 0
	|		ELSE CAST(SUM(RoomRevenue) / MAX(RoomsPerPeriod) AS NUMBER(17, 2))
	|	END AS RevPAR,
	|	CASE
	|		WHEN MAX(BedsPerPeriod) = 0
	|			THEN 0
	|		ELSE CAST(SUM(RoomRevenue) / MAX(BedsPerPeriod) AS NUMBER(17, 2))
	|	END AS RevPAB,
	|	CASE
	|		WHEN MAX(RoomsPerPeriod) = 0
	|			THEN 0
	|		ELSE CAST(SUM(RoomRevenueWithoutVAT) / MAX(RoomsPerPeriod) AS NUMBER(17, 2))
	|	END AS RevPARWithoutVAT,
	|	CASE
	|		WHEN MAX(BedsPerPeriod) = 0
	|			THEN 0
	|		ELSE CAST(SUM(RoomRevenueWithoutVAT) / MAX(BedsPerPeriod) AS NUMBER(17, 2))
	|	END AS RevPABWithoutVAT,
	|	CASE
	|		WHEN SUM(RoomsPerRoomTypePerDay) = 0
	|			THEN 0
	|		ELSE CAST(SUM(RoomRevenue) / SUM(RoomsPerRoomTypePerDay) AS NUMBER(17, 2))
	|	END AS RevPARPerRoomTypePerDay,
	|	CASE
	|		WHEN SUM(BedsPerRoomTypePerDay) = 0
	|			THEN 0
	|		ELSE CAST(SUM(RoomRevenue) / SUM(BedsPerRoomTypePerDay) AS NUMBER(17, 2))
	|	END AS RevPABPerRoomTypePerDay,
	|	CASE
	|		WHEN SUM(RoomsPerRoomTypePerDay) = 0
	|			THEN 0
	|		ELSE CAST(SUM(RoomRevenueWithoutVAT) / SUM(RoomsPerRoomTypePerDay) AS NUMBER(17, 2))
	|	END AS RevPARWithoutVATPerRoomTypePerDay,
	|	CASE
	|		WHEN SUM(BedsPerRoomTypePerDay) = 0
	|			THEN 0
	|		ELSE CAST(SUM(RoomRevenueWithoutVAT) / SUM(BedsPerRoomTypePerDay) AS NUMBER(17, 2))
	|	END AS RevPABWithoutVATPerRoomTypePerDay,
	|	CASE
	|		WHEN SUM(RoomsPerRoomTypePerMonth) = 0
	|			THEN 0
	|		ELSE CAST(SUM(RoomRevenue) / SUM(RoomsPerRoomTypePerMonth) AS NUMBER(17, 2))
	|	END AS RevPARPerRoomTypePerMonth,
	|	CASE
	|		WHEN SUM(BedsPerRoomTypePerMonth) = 0
	|			THEN 0
	|		ELSE CAST(SUM(RoomRevenue) / SUM(BedsPerRoomTypePerMonth) AS NUMBER(17, 2))
	|	END AS RevPABPerRoomTypePerMonth,
	|	CASE
	|		WHEN SUM(RoomsPerRoomTypePerMonth) = 0
	|			THEN 0
	|		ELSE CAST(SUM(RoomRevenueWithoutVAT) / SUM(RoomsPerRoomTypePerMonth) AS NUMBER(17, 2))
	|	END AS RevPARWithoutVATPerRoomTypePerMonth,
	|	CASE
	|		WHEN SUM(BedsPerRoomTypePerMonth) = 0
	|			THEN 0
	|		ELSE CAST(SUM(RoomRevenueWithoutVAT) / SUM(BedsPerRoomTypePerMonth) AS NUMBER(17, 2))
	|	END AS RevPABWithoutVATPerRoomTypePerMonth,
	|	CASE
	|		WHEN SUM(RoomsPerRoomTypePerPeriod) = 0
	|			THEN 0
	|		ELSE CAST(SUM(RoomRevenue) / SUM(RoomsPerRoomTypePerPeriod) AS NUMBER(17, 2))
	|	END AS RevPARPerRoomTypePerPeriod,
	|	CASE
	|		WHEN SUM(BedsPerRoomTypePerPeriod) = 0
	|			THEN 0
	|		ELSE CAST(SUM(RoomRevenue) / SUM(BedsPerRoomTypePerPeriod) AS NUMBER(17, 2))
	|	END AS RevPABPerRoomTypePerPeriod,
	|	CASE
	|		WHEN SUM(RoomsPerRoomTypePerPeriod) = 0
	|			THEN 0
	|		ELSE CAST(SUM(RoomRevenueWithoutVAT) / SUM(RoomsPerRoomTypePerPeriod) AS NUMBER(17, 2))
	|	END AS RevPARWithoutVATPerRoomTypePerPeriod,
	|	CASE
	|		WHEN SUM(BedsPerRoomTypePerPeriod) = 0
	|			THEN 0
	|		ELSE CAST(SUM(RoomRevenueWithoutVAT) / SUM(BedsPerRoomTypePerPeriod) AS NUMBER(17, 2))
	|	END AS RevPABWithoutVATPerRoomTypePerPeriod,
	|	CASE
	|		WHEN MAX(RoomsPerPeriod) = 0
	|			THEN 0
	|		ELSE CAST(SUM(RoomsRented) * 100 / MAX(RoomsPerPeriod) AS NUMBER(17, 3))
	|	END AS RoomsRentedPercent,
	|	CASE
	|		WHEN MAX(BedsPerPeriod) = 0
	|			THEN 0
	|		ELSE CAST(SUM(BedsRented) * 100 / MAX(BedsPerPeriod) AS NUMBER(17, 3))
	|	END AS BedsRentedPercent,
	|	CASE
	|		WHEN MAX(RoomsPerPeriod) - MAX(RoomsBlockedPerPeriod) = 0
	|			THEN 0
	|		ELSE CAST(SUM(RoomsRented) * 100 / (MAX(RoomsPerPeriod) - MAX(RoomsBlockedPerPeriod)) AS NUMBER(17, 3))
	|	END AS RoomsRentedPercentWithRoomBlocks,
	|	CASE
	|		WHEN MAX(BedsPerPeriod) - MAX(BedsBlockedPerPeriod) = 0
	|			THEN 0
	|		ELSE CAST(SUM(BedsRented) * 100 / (MAX(BedsPerPeriod) - MAX(BedsBlockedPerPeriod)) AS NUMBER(17, 3))
	|	END AS BedsRentedPercentWithRoomBlocks,
	|	CASE
	|		WHEN SUM(RoomsPerRoomTypePerDay) = 0
	|			THEN 0
	|		ELSE CAST(SUM(RoomsRented) * 100 / SUM(RoomsPerRoomTypePerDay) AS NUMBER(17, 3))
	|	END AS RoomsRentedPercentPerRoomTypePerDay,
	|	CASE
	|		WHEN SUM(BedsPerRoomTypePerDay) = 0
	|			THEN 0
	|		ELSE CAST(SUM(BedsRented) * 100 / SUM(BedsPerRoomTypePerDay) AS NUMBER(17, 3))
	|	END AS BedsRentedPercentPerRoomTypePerDay,
	|	CASE
	|		WHEN SUM(RoomsPerRoomTypePerDay) - SUM(RoomsBlockedPerRoomTypePerDay) = 0
	|			THEN 0
	|		ELSE CAST(SUM(RoomsRented) * 100 / (SUM(RoomsPerRoomTypePerDay) - SUM(RoomsBlockedPerRoomTypePerDay)) AS NUMBER(17, 3))
	|	END AS RoomsRentedPercentWithRoomBlocksPerRoomTypePerDay,
	|	CASE
	|		WHEN SUM(BedsPerRoomTypePerDay) - SUM(BedsBlockedPerRoomTypePerDay) = 0
	|			THEN 0
	|		ELSE CAST(SUM(BedsRented) * 100 / (SUM(BedsPerRoomTypePerDay) - SUM(BedsBlockedPerRoomTypePerDay)) AS NUMBER(17, 3))
	|	END AS BedsRentedPercentWithRoomBlocksPerRoomTypePerDay,
	|	CASE
	|		WHEN SUM(RoomsPerRoomTypePerMonth) = 0
	|			THEN 0
	|		ELSE CAST(SUM(RoomsRented) * 100 / SUM(RoomsPerRoomTypePerMonth) AS NUMBER(17, 3))
	|	END AS RoomsRentedPercentPerRoomTypePerMonth,
	|	CASE
	|		WHEN SUM(BedsPerRoomTypePerMonth) = 0
	|			THEN 0
	|		ELSE CAST(SUM(BedsRented) * 100 / SUM(BedsPerRoomTypePerMonth) AS NUMBER(17, 2))
	|	END AS BedsRentedPercentPerRoomTypePerMonth,
	|	CASE
	|		WHEN SUM(RoomsPerRoomTypePerMonth) - SUM(RoomsBlockedPerRoomTypePerMonth) = 0
	|			THEN 0
	|		ELSE CAST(SUM(RoomsRented) * 100 / (SUM(RoomsPerRoomTypePerMonth) - SUM(RoomsBlockedPerRoomTypePerMonth)) AS NUMBER(17, 3))
	|	END AS RoomsRentedPercentWithRoomBlocksPerRoomTypePerMonth,
	|	CASE
	|		WHEN SUM(BedsPerRoomTypePerMonth) - SUM(BedsBlockedPerRoomTypePerMonth) = 0
	|			THEN 0
	|		ELSE CAST(SUM(BedsRented) * 100 / (SUM(BedsPerRoomTypePerMonth) - SUM(BedsBlockedPerRoomTypePerMonth)) AS NUMBER(17, 3))
	|	END AS BedsRentedPercentWithRoomBlocksPerRoomTypePerMonth,
	|	CASE
	|		WHEN SUM(RoomsPerRoomTypePerPeriod) = 0
	|			THEN 0
	|		ELSE CAST(SUM(RoomsRented) * 100 / SUM(RoomsPerRoomTypePerPeriod) AS NUMBER(17, 3))
	|	END AS RoomsRentedPercentPerRoomTypePerPeriod,
	|	CASE
	|		WHEN SUM(BedsPerRoomTypePerPeriod) = 0
	|			THEN 0
	|		ELSE CAST(SUM(BedsRented) * 100 / SUM(BedsPerRoomTypePerPeriod) AS NUMBER(17, 3))
	|	END AS BedsRentedPercentPerRoomTypePerPeriod,
	|	CASE
	|		WHEN SUM(RoomsPerRoomTypePerPeriod) - SUM(RoomsBlockedPerRoomTypePerPeriod) = 0
	|			THEN 0
	|		ELSE CAST(SUM(RoomsRented) * 100 / (SUM(RoomsPerRoomTypePerPeriod) - SUM(RoomsBlockedPerRoomTypePerPeriod)) AS NUMBER(17, 3))
	|	END AS RoomsRentedPercentWithRoomBlocksPerRoomTypePerPeriod,
	|	CASE
	|		WHEN SUM(BedsPerRoomTypePerPeriod) - SUM(BedsBlockedPerRoomTypePerPeriod) = 0
	|			THEN 0
	|		ELSE CAST(SUM(BedsRented) * 100 / (SUM(BedsPerRoomTypePerPeriod) - SUM(BedsBlockedPerRoomTypePerPeriod)) AS NUMBER(17, 3))
	|	END AS BedsRentedPercentWithRoomBlocksPerRoomTypePerPeriod,
	|	CASE
	|		WHEN SUM(RoomsPerRoomTypeAndCalendarDayTypePerDay) = 0
	|			THEN 0
	|		ELSE CAST(SUM(RoomsRented) * 100 / SUM(RoomsPerRoomTypeAndCalendarDayTypePerDay) AS NUMBER(17, 3))
	|	END AS RoomsRentedPercentPerRoomTypeAndCalendarDayTypePerDay,
	|	CASE
	|		WHEN SUM(BedsPerRoomTypeAndCalendarDayTypePerDay) = 0
	|			THEN 0
	|		ELSE CAST(SUM(BedsRented) * 100 / SUM(BedsPerRoomTypeAndCalendarDayTypePerDay) AS NUMBER(17, 3))
	|	END AS BedsRentedPercentPerRoomTypeAndCalendarDayTypePerDay,
	|	CASE
	|		WHEN SUM(RoomsPerRoomTypeAndCalendarDayTypePerDay) - SUM(RoomsBlockedPerRoomTypeAndCalendarDayTypePerDay) = 0
	|			THEN 0
	|		ELSE CAST(SUM(RoomsRented) * 100 / (SUM(RoomsPerRoomTypeAndCalendarDayTypePerDay) - SUM(RoomsBlockedPerRoomTypeAndCalendarDayTypePerDay)) AS NUMBER(17, 3))
	|	END AS RoomsRentedPercentWithRoomBlocksPerRoomTypeAndCalendarDayTypePerDay,
	|	CASE
	|		WHEN SUM(BedsPerRoomTypeAndCalendarDayTypePerDay) - SUM(BedsBlockedPerRoomTypeAndCalendarDayTypePerDay) = 0
	|			THEN 0
	|		ELSE CAST(SUM(BedsRented) * 100 / (SUM(BedsPerRoomTypeAndCalendarDayTypePerDay) - SUM(BedsBlockedPerRoomTypeAndCalendarDayTypePerDay)) AS NUMBER(17, 3))
	|	END AS BedsRentedPercentWithRoomBlocksPerRoomTypeAndCalendarDayTypePerDay,
	|	CASE
	|		WHEN SUM(RoomsPerRoomTypeAndChoosenCalendarDayTypePerDay) = 0
	|			THEN 0
	|		ELSE CAST(SUM(RoomsRented) * 100 / SUM(RoomsPerRoomTypeAndChoosenCalendarDayTypePerDay) AS NUMBER(17, 3))
	|	END AS RoomsRentedPercentPerRoomTypeAndChoosenCalendarDayTypePerDay,
	|	CASE
	|		WHEN SUM(BedsPerRoomTypeAndChoosenCalendarDayTypePerDay) = 0
	|			THEN 0
	|		ELSE CAST(SUM(BedsRented) * 100 / SUM(BedsPerRoomTypeAndChoosenCalendarDayTypePerDay) AS NUMBER(17, 3))
	|	END AS BedsRentedPercentPerRoomTypeAndChoosenCalendarDayTypePerDay,
	|	CASE
	|		WHEN SUM(RoomsPerRoomTypeAndChoosenCalendarDayTypePerDay) - SUM(RoomsBlockedPerRoomTypeAndChoosenCalendarDayTypePerDay) = 0
	|			THEN 0
	|		ELSE CAST(SUM(RoomsRented) * 100 / (SUM(RoomsPerRoomTypeAndChoosenCalendarDayTypePerDay) - SUM(RoomsBlockedPerRoomTypeAndChoosenCalendarDayTypePerDay)) AS NUMBER(17, 3))
	|	END AS RoomsRentedPercentWithRoomBlocksPerRoomTypeAndChoosenCalendarDayTypePerDay,
	|	CASE
	|		WHEN SUM(BedsPerRoomTypeAndChoosenCalendarDayTypePerDay) - SUM(BedsBlockedPerRoomTypeAndChoosenCalendarDayTypePerDay) = 0
	|			THEN 0
	|		ELSE CAST(SUM(BedsRented) * 100 / (SUM(BedsPerRoomTypeAndChoosenCalendarDayTypePerDay) - SUM(BedsBlockedPerRoomTypeAndChoosenCalendarDayTypePerDay)) AS NUMBER(17, 3))
	|	END AS BedsRentedPercentWithRoomBlocksPerRoomTypeAndChoosenCalendarDayTypePerDay,
	|	MAX(TotalSalesAmount),
	|	MAX(TotalRoomsRented),
	|	MAX(TotalBedsRented),
	|	CASE
	|		WHEN MAX(TotalSalesAmount) = 0
	|			THEN 0
	|		ELSE CAST(SUM(Sales) * 100 / MAX(TotalSalesAmount) AS NUMBER(17, 3))
	|	END AS TotalSalesPercent,
	|	CASE
	|		WHEN MAX(TotalBedsRented) = 0
	|			THEN 0
	|		ELSE CAST(SUM(BedsRented) * 100 / MAX(TotalBedsRented) AS NUMBER(17, 3))
	|	END AS TotalBedsRentedPercent,
	|	CASE
	|		WHEN MAX(TotalRoomsRented) = 0
	|			THEN 0
	|		ELSE CAST(SUM(RoomsRented) * 100 / MAX(TotalRoomsRented) AS NUMBER(17, 3))
	|	END AS TotalRoomsRentedPercent,
	|	CASE
	|		WHEN Room IS NULL
	|				AND RoomType IS NULL
	|			THEN CAST(MAX(RoomsPerPeriod) AS NUMBER(17, 0))
	|		WHEN Room IS NULL
	|				AND NOT RoomType IS NULL
	|			THEN CAST(MAX(RoomsPerRoomTypePerPeriod) AS NUMBER(17, 0))
	|		ELSE MAX(RoomsPerRoomPerPeriod)
	|	END AS RoomsPerRoomPerPeriod,
	|	CASE
	|		WHEN Room IS NULL
	|				AND RoomType IS NULL
	|			THEN CAST(MAX(BedsPerPeriod) AS NUMBER(17, 0))
	|		WHEN Room IS NULL
	|				AND NOT RoomType IS NULL
	|			THEN CAST(MAX(BedsPerRoomTypePerPeriod) AS NUMBER(17, 0))
	|		ELSE MAX(BedsPerRoomPerPeriod)
	|	END AS BedsPerRoomPerPeriod,
	|	CASE
	|		WHEN Room IS NULL
	|				AND RoomType IS NULL
	|			THEN CAST(MAX(RoomsBlockedPerPeriod) AS NUMBER(17, 0))
	|		WHEN Room IS NULL
	|				AND NOT RoomType IS NULL
	|			THEN CAST(MAX(RoomsBlockedPerRoomTypePerPeriod) AS NUMBER(17, 0))
	|		ELSE MAX(RoomsBlockedPerRoomPerPeriod)
	|	END AS RoomsBlockedPerRoomPerPeriod,
	|	CASE
	|		WHEN Room IS NULL
	|				AND RoomType IS NULL
	|			THEN CAST(MAX(BedsBlockedPerPeriod) AS NUMBER(17, 0))
	|		WHEN Room IS NULL
	|				AND NOT RoomType IS NULL
	|			THEN CAST(MAX(BedsBlockedPerRoomTypePerPeriod) AS NUMBER(17, 0))
	|		ELSE MAX(BedsBlockedPerRoomPerPeriod)
	|	END AS BedsBlockedPerRoomPerPeriod,
	|	CASE
	|		WHEN Room IS NULL
	|				AND RoomType IS NULL
	|				AND (CAST(MAX(RoomsPerPeriod) AS NUMBER(17, 0))) - (CAST(MAX(RoomsBlockedPerPeriod) AS NUMBER(17, 0))) = 0
	|			THEN 0
	|		WHEN Room IS NULL
	|				AND RoomType IS NULL
	|				AND (CAST(MAX(RoomsPerPeriod) AS NUMBER(17, 0))) - (CAST(MAX(RoomsBlockedPerPeriod) AS NUMBER(17, 0))) <> 0
	|			THEN CAST(SUM(RoomsRented) * 100 / (MAX(RoomsPerPeriod) - MAX(RoomsBlockedPerPeriod)) AS NUMBER(17, 3))
	|		WHEN Room IS NULL
	|				AND NOT RoomType IS NULL
	|				AND (CAST(MAX(RoomsPerRoomTypePerPeriod) AS NUMBER(17, 0))) - (CAST(MAX(RoomsBlockedPerRoomTypePerPeriod) AS NUMBER(17, 0))) = 0
	|			THEN 0
	|		WHEN Room IS NULL
	|				AND NOT RoomType IS NULL
	|				AND (CAST(MAX(RoomsPerRoomTypePerPeriod) AS NUMBER(17, 0))) - (CAST(MAX(RoomsBlockedPerRoomTypePerPeriod) AS NUMBER(17, 0))) <> 0
	|			THEN CAST(SUM(RoomsRented) * 100 / (MAX(RoomsPerRoomTypePerPeriod) - MAX(RoomsBlockedPerRoomTypePerPeriod)) AS NUMBER(17, 3))
	|		WHEN NOT Room IS NULL
	|				AND MAX(RoomsPerRoomPerPeriod) - MAX(RoomsBlockedPerRoomPerPeriod) = 0
	|			THEN 0
	|		ELSE CAST(SUM(RoomsRented) * 100 / (MAX(RoomsPerRoomPerPeriod) - MAX(RoomsBlockedPerRoomPerPeriod)) AS NUMBER(17, 3))
	|	END AS RoomsRentedPercentPerRoom,
	|	CASE
	|		WHEN Room IS NULL
	|				AND RoomType IS NULL
	|				AND MAX(BedsPerPeriod) - MAX(BedsBlockedPerPeriod) = 0
	|			THEN 0
	|		WHEN Room IS NULL
	|				AND RoomType IS NULL
	|				AND MAX(BedsPerPeriod) - MAX(BedsBlockedPerPeriod) <> 0
	|			THEN CAST(SUM(BedsRented) * 100 / (MAX(BedsPerPeriod) - MAX(BedsBlockedPerPeriod)) AS NUMBER(17, 3))
	|		WHEN Room IS NULL
	|				AND NOT RoomType IS NULL
	|				AND MAX(BedsPerRoomTypePerPeriod) - MAX(BedsBlockedPerRoomTypePerPeriod) = 0
	|			THEN 0
	|		WHEN Room IS NULL
	|				AND NOT RoomType IS NULL
	|				AND MAX(BedsPerRoomTypePerPeriod) - MAX(BedsBlockedPerRoomTypePerPeriod) <> 0
	|			THEN CAST(SUM(BedsRented) * 100 / (MAX(BedsPerRoomTypePerPeriod) - MAX(BedsBlockedPerRoomTypePerPeriod)) AS NUMBER(17, 0))
	|		WHEN NOT Room IS NULL
	|				AND MAX(BedsPerRoomPerPeriod) - MAX(BedsBlockedPerRoomPerPeriod) = 0
	|			THEN 0
	|		ELSE CAST(SUM(BedsRented) * 100 / (MAX(BedsPerRoomPerPeriod) - MAX(BedsBlockedPerRoomPerPeriod)) AS NUMBER(17, 3))
	|	END AS BedsRentedPercentPerRoom,
	|	SUM(GuaranteedSales),
	|	SUM(GuaranteedRoomRevenue),
	|	SUM(GuaranteedSalesWithoutVAT),
	|	SUM(GuaranteedRoomRevenueWithoutVAT),
	|	SUM(GuaranteedRoomsRented),
	|	SUM(NonGuaranteedSales),
	|	SUM(NonGuaranteedRoomRevenue),
	|	SUM(NonGuaranteedSalesWithoutVAT),
	|	SUM(NonGuaranteedRoomRevenueWithoutVAT),
	|	SUM(NonGuaranteedRoomsRented)
	|BY
	|	OVERALL,
	|	ReportingCurrency,
	|	RoomType HIERARCHY,
	|	Room HIERARCHY
	|{TOTALS BY
	|	Company.*,
	|	Hotel.*,
	|	ReportingCurrency.*,
	|	Room.*,
	|	RoomType.*,
	|	RoomRate.*,
	|	CalendarDayType.*,
	|	PriceTag.*,
	|	RoomSalesTurnovers.ExtCalendarDayType.*,
	|	AccommodationType.*,
	|	ClientType.*,
	|	MarketingCode.*,
	|	SourceOfBusiness.*,
	|	ParentDoc.*,
	|	RoomSalesTurnovers.Reservation.* AS Reservation,
	|	RoomSalesTurnovers.ReservationDate AS ReservationDate,
	|	RoomSalesTurnovers.ReservationWeek AS ReservationWeek,
	|	RoomSalesTurnovers.ReservationMonth AS ReservationMonth,
	|	RoomSalesTurnovers.ReservationYear AS ReservationYear,
	|	RoomSalesTurnovers.DaysBeforeCheckIn AS DaysBeforeCheckIn,
	|	RoomSalesTurnovers.WeeksBeforeCheckIn AS WeeksBeforeCheckIn,
	|	RoomSalesTurnovers.MonthsBeforeCheckIn AS MonthsBeforeCheckIn,
	|	RoomSalesTurnovers.RoomQuota.* AS RoomQuota,
	|	Service.*,
	|	RoomPrice,
	|	RoomSalesTurnovers.GuestGroup.* AS GuestGroup,
	|	RoomSalesTurnovers.Customer.* AS Customer,
	|	RoomSalesTurnovers.Contract.* AS Contract,
	|	RoomSalesTurnovers.Agent.* AS Agent,
	|	RoomSalesTurnovers.Client.* AS Client,
	|	RoomSalesTurnovers.Resource.* AS Resource,
	|	RoomSalesTurnovers.Folio.* AS Folio,
	|	RoomSalesTurnovers.Price AS Price,
	|	RoomSalesTurnovers.ResourceType.* AS ResourceType,
	|	RoomSalesTurnovers.TripPurpose.* AS TripPurpose,
	|	RoomSalesTurnovers.HotelProduct.* AS HotelProduct,
	|	RoomSalesTurnovers.Author.* AS Author,
	|	RoomSalesTurnovers.Discount AS Discount,
	|	RoomSalesTurnovers.DiscountType.* AS DiscountType,
	|	RoomSalesTurnovers.DiscountCard.* AS DiscountCard,
	|	RoomSalesTurnovers.AgentCommission AS AgentCommission,
	|	RoomSalesTurnovers.AgentCommissionType.* AS AgentCommissionType,
	|	RoomSalesTurnovers.PaymentMethod.* AS PaymentMethod,
	|	RoomSalesTurnovers.VATRate.* AS VATRate,
	|	AccountingDate,
	|	(DAY(RoomSalesTurnovers.AccountingDate)) AS AccountingDay,
	|	(WEEKDAY(RoomSalesTurnovers.AccountingDate)) AS AccountingWeekday,
	|	(CASE
	|			WHEN WEEKDAY(RoomSalesTurnovers.AccountingDate) = 1
	|				THEN &qMonday
	|			WHEN WEEKDAY(RoomSalesTurnovers.AccountingDate) = 2
	|				THEN &qTuesday
	|			WHEN WEEKDAY(RoomSalesTurnovers.AccountingDate) = 3
	|				THEN &qWednesday
	|			WHEN WEEKDAY(RoomSalesTurnovers.AccountingDate) = 4
	|				THEN &qThursday
	|			WHEN WEEKDAY(RoomSalesTurnovers.AccountingDate) = 5
	|				THEN &qFriday
	|			WHEN WEEKDAY(RoomSalesTurnovers.AccountingDate) = 6
	|				THEN &qSaturday
	|			WHEN WEEKDAY(RoomSalesTurnovers.AccountingDate) = 7
	|				THEN &qSunday
	|			ELSE NULL
	|		END) AS AccountingWeekdayName,
	|	(BEGINOFPERIOD(RoomSalesTurnovers.AccountingDate, WEEK)) AS AccountingWeek,
	|	(BEGINOFPERIOD(RoomSalesTurnovers.AccountingDate, MONTH)) AS AccountingMonth,
	|	(BEGINOFPERIOD(RoomSalesTurnovers.AccountingDate, QUARTER)) AS AccountingQuarter,
	|	(YEAR(RoomSalesTurnovers.AccountingDate)) AS AccountingYear,
	|	(BEGINOFPERIOD(DATEADD(RoomSalesTurnovers.AccountingDate, YEAR, -(YEAR(RoomSalesTurnovers.AccountingDate) - 2)), DAY)) AS AccountingDateNoYear,
	|	(BEGINOFPERIOD(DATEADD(RoomSalesTurnovers.AccountingDate, YEAR, -(YEAR(RoomSalesTurnovers.AccountingDate) - 2)), WEEK)) AS AccountingWeekNoYear,
	|	(BEGINOFPERIOD(DATEADD(RoomSalesTurnovers.AccountingDate, YEAR, -(YEAR(RoomSalesTurnovers.AccountingDate) - 2)), MONTH)) AS AccountingMonthNoYear,
	|	(BEGINOFPERIOD(DATEADD(RoomSalesTurnovers.AccountingDate, YEAR, -(YEAR(RoomSalesTurnovers.AccountingDate) - 2)), QUARTER)) AS AccountingQuarterNoYear,
	|	(BEGINOFPERIOD(DATEADD(RoomSalesTurnovers.ReservationDate, YEAR, -(YEAR(RoomSalesTurnovers.ReservationDate) - 2)), DAY)) AS ReservationDateNoYear,
	|	(BEGINOFPERIOD(DATEADD(RoomSalesTurnovers.ReservationWeek, YEAR, -(YEAR(RoomSalesTurnovers.ReservationWeek) - 2)), DAY)) AS ReservationWeekNoYear,
	|	(BEGINOFPERIOD(DATEADD(RoomSalesTurnovers.ReservationMonth, YEAR, -(YEAR(RoomSalesTurnovers.ReservationMonth) - 2)), DAY)) AS ReservationMonthNoYear,
	|	BookingWindowDimension AS BookingWindowDimension,
	|	RoomSalesTurnovers.CustomAttribute1.* AS CustomAttribute1,
	|	RoomSalesTurnovers.CustomAttribute2.* AS CustomAttribute2,
	|	RoomSalesTurnovers.CustomAttribute3.* AS CustomAttribute3,
	|	(CASE
	|			WHEN NOT RoomSalesTurnovers.GuestGroup.GroupType.Code IS NULL
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS IsGroupReservation,
	|	ServiceDate}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Room sales turnovers';RU='Обороты по продажам номеров';de='Umsätze aus Zimmerverkäufen'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
Function pmIsResource(pName) Export
	If pName = "Sales" 
	   Or pName = "SalesWithoutCommission" 
	   Or pName = "RoomRevenue" 
	   Or pName = "RoomRevenueWithoutCommission" 
	   Or pName = "InPriceRevenue" 
	   Or pName = "InPriceRevenueWithoutCommission" 
	   Or pName = "ExtraBedRevenue" 
	   Or pName = "RoomRevenueWithoutExtraBed" 
	   Or pName = "SalesWithoutVAT" 
	   Or pName = "SalesWithoutVATWithoutCommission" 
	   Or pName = "RoomRevenueWithoutVAT" 
	   Or pName = "RoomRevenueWithoutVATWithoutCommission" 
	   Or pName = "InPriceRevenueWithoutVAT" 
	   Or pName = "InPriceRevenueWithoutVATWithoutCommission" 
	   Or pName = "ExtraBedRevenueWithoutVAT" 
	   Or pName = "RoomRevenueWithoutExtraBedWithoutVAT" 
	   Or pName = "ExtraServicesRevenue" 
	   Or pName = "ExtraServicesRevenueWithoutVAT" 
	   Or pName = "CommissionSum" 
	   Or pName = "CommissionSumWithoutVAT" 
	   Or pName = "DiscountSum" 
	   Or pName = "DiscountSumWithoutVAT" 
	   Or pName = "ExtraBedDiscountSum" 
	   Or pName = "DiscountSumWithoutExtraBed" 
	   Or pName = "RoomsRented" 
	   Or pName = "BedsRented" 
	   Or pName = "AdditionalBedsRented" 
	   Or pName = "GuestDays" 
	   Or pName = "ExtraBedGuestDays" 
	   Or pName = "GuestDaysWithoutExtraBed" 
	   Or pName = "GuestsCheckedIn"
	   Or pName = "RoomsCheckedIn" 
	   Or pName = "BedsCheckedIn" 
	   Or pName = "AdditionalBedsCheckedIn" 
	   Or pName = "Quantity" 
	   Or pName = "RoomsPerPeriod"
	   Or pName = "BedsPerPeriod"
	   Or pName = "RoomsBlockedPerPeriod"
	   Or pName = "BedsBlockedPerPeriod"
	   Or pName = "RoomsPerRoomTypePerDay"
	   Or pName = "BedsPerRoomTypePerDay"
	   Or pName = "RoomsBlockedPerRoomTypePerDay"
	   Or pName = "BedsBlockedPerRoomTypePerDay"
	   Or pName = "RoomsPerRoomTypePerMonth"
	   Or pName = "BedsPerRoomTypePerMonth"
	   Or pName = "RoomsBlockedPerRoomTypePerMonth"
	   Or pName = "BedsBlockedPerRoomTypePerMonth"
	   Or pName = "RoomsPerRoomTypePerPeriod"
	   Or pName = "BedsPerRoomTypePerPeriod"
	   Or pName = "RoomsBlockedPerRoomTypePerPeriod"
	   Or pName = "BedsBlockedPerRoomTypePerPeriod"
	   Or pName = "AverageRoomPrice"
	   Or pName = "AverageBedPrice"
	   Or pName = "AverageRoomPriceWithoutVAT"
	   Or pName = "AverageBedPriceWithoutVAT"
	   Or pName = "ALS"
	   Or pName = "RevPAR"
	   Or pName = "RevPAB"
	   Or pName = "RevPARWithoutVAT"
	   Or pName = "RevPABWithoutVAT"
	   Or pName = "RevPARPerRoomTypePerDay"
	   Or pName = "RevPABPerRoomTypePerDay"
	   Or pName = "RevPARWithoutVATPerRoomTypePerDay"
	   Or pName = "RevPABWithoutVATPerRoomTypePerDay"
	   Or pName = "RevPARPerRoomTypePerMonth"
	   Or pName = "RevPABPerRoomTypePerMonth"
	   Or pName = "RevPARWithoutVATPerRoomTypePerMonth"
	   Or pName = "RevPABWithoutVATPerRoomTypePerMonth"
	   Or pName = "RevPARPerRoomTypePerPeriod"
	   Or pName = "RevPABPerRoomTypePerPeriod"
	   Or pName = "RevPARWithoutVATPerRoomTypePerPeriod"
	   Or pName = "RevPABWithoutVATPerRoomTypePerPeriod"
	   Or pName = "RoomsRentedPercent"
	   Or pName = "BedsRentedPercent"
	   Or pName = "RoomsRentedPercentWithRoomBlocks"
	   Or pName = "BedsRentedPercentWithRoomBlocks"
	   Or pName = "RoomsRentedPercentPerRoomTypePerDay"
	   Or pName = "BedsRentedPercentPerRoomTypePerDay"
	   Or pName = "RoomsRentedPercentWithRoomBlocksPerRoomTypePerDay"
	   Or pName = "BedsRentedPercentWithRoomBlocksPerRoomTypePerDay"
	   Or pName = "RoomsRentedPercentPerRoomTypePerMonth"
	   Or pName = "BedsRentedPercentPerRoomTypePerMonth"
	   Or pName = "RoomsRentedPercentWithRoomBlocksPerRoomTypePerMonth"
	   Or pName = "BedsRentedPercentWithRoomBlocksPerRoomTypePerMonth"
	   Or pName = "RoomsRentedPercentPerRoomTypePerPeriod"
	   Or pName = "BedsRentedPercentPerRoomTypePerPeriod"
	   Or pName = "RoomsRentedPercentWithRoomBlocksPerRoomTypePerPeriod"
	   Or pName = "BedsRentedPercentWithRoomBlocksPerRoomTypePerPeriod"
	   Or pName = "TotalSalesAmount"
	   Or pName = "TotalBedsRented"
	   Or pName = "TotalRoomsRented"
	   Or pName = "TotalBedsRentedPercent"
	   Or pName = "TotalRoomsRentedPercent"
	   Or pName = "TotalSalesPercent" 
	   Or pName = "RoomsPerRoomPerPeriod" 
	   Or pName = "BedsPerRoomPerPeriod" 
	   Or pName = "RoomsBlockedPerRoomPerPeriod" 
	   Or pName = "BedsBlockedPerRoomPerPeriod" 
	   Or pName = "RoomsRentedPercentPerRoom" 
	   Or pName = "BedsRentedPercentPerRoom" 
	   Or pName = "BookingWindow" 
	   Or pName = "GuaranteedSales"
	   Or pName = "GuaranteedRoomRevenue"
	   Or pName = "GuaranteedSalesWithoutVAT"
	   Or pName = "GuaranteedRoomRevenueWithoutVAT"
	   Or pName = "GuaranteedRoomsRented"
	   Or pName = "NonGuaranteedSales"
	   Or pName = "NonGuaranteedRoomRevenue"
	   Or pName = "NonGuaranteedSalesWithoutVAT"
	   Or pName = "NonGuaranteedRoomRevenueWithoutVAT"
	   Or pName = "NonGuaranteedRoomsRented" Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // pmIsResource
  
#EndRegion
