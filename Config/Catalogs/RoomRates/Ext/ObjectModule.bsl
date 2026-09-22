
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure OnCopy(pCopiedObject)
	If Not IsFolder Then
		Author = Catalogs.Employees.EmptyRef();
		CreateDate = '00010101';
		IsOnlineRate = False;
		IsHiddenRateForAuthorizedClients = False;
	EndIf;
EndProcedure // OnCopy

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;

	If Not IsFolder Then
		If Formulas.Count() > 0 Then
			Formulas.Sort("DateValidFrom, ClientType, Hotel Desc, RoomType Desc, Service Desc, AccommodationType Desc");
		EndIf;
		If ValueIsFilled(BasedOnRoomRate) Then
			// Dynamic rate type
			If Not ValueIsFilled(BasedOnPriceTag) Then
				PriceTagType = BasedOnRoomRate.PriceTagType;
			EndIf;
			// Calendar
			If Calendar <> BasedOnRoomRate.Calendar Then
				Calendar = BasedOnRoomRate.Calendar;
			EndIf;
			// Use prices from calendar
			If UsePricesFromCalendar <> BasedOnRoomRate.UsePricesFromCalendar Then
				UsePricesFromCalendar = BasedOnRoomRate.UsePricesFromCalendar;
			EndIf;
			If DefaultCurrency <> BasedOnRoomRate.DefaultCurrency Then
				DefaultCurrency = BasedOnRoomRate.DefaultCurrency;
			EndIf;
			// Room rate accommodation services
			If AccommodationService <> BasedOnRoomRate.AccommodationService Then
				AccommodationService = BasedOnRoomRate.AccommodationService;
			EndIf;
			If QuantityCalculationRule <> BasedOnRoomRate.QuantityCalculationRule Then
				QuantityCalculationRule = BasedOnRoomRate.QuantityCalculationRule;
			EndIf;
			If EarlyCheckInService <> BasedOnRoomRate.EarlyCheckInService Then
				EarlyCheckInService = BasedOnRoomRate.EarlyCheckInService;
			EndIf;
			If LateCheckOutService <> BasedOnRoomRate.LateCheckOutService Then
				LateCheckOutService = BasedOnRoomRate.LateCheckOutService;
			EndIf;
		EndIf;

		// Log deletion mark		
		If DeletionMark <> Ref.DeletionMark Then
            vEventDescription = "";
			If DeletionMark Then
				vEventDescription = StrTemplate(NStr("en = 'Deletion mark was set for rate: %1'; de = 'Löschmarke wurde für Tarif gesetzt: %1'; ru = 'Пометили на удаление тариф: %1'"), TrimAll(Ref));
			Else
				vEventDescription = StrTemplate(NStr("en = 'Deletion mark was removed for rate: %1'; de = 'Löschmarke wurde für Tarif entfernt: %1'; ru = 'Сняли пометку на удаление у тарифа: %1'"), TrimAll(Ref));
			EndIf;
			InformationRegisters.UserActionsHistory.WriteUserActivityRecord(Ref, vEventDescription);
			pmWriteToRoomRateChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// Update child room rates
	If Not IsFolder Then
		vChildRoomRates = pmGetChildRoomRates();
		For Each vChildRoomRatesRow In vChildRoomRates Do
			If ValueIsFilled(vChildRoomRatesRow.RoomRate) Then
				vChildRoomRateObj = vChildRoomRatesRow.RoomRate.GetObject();
				// Calendar
				If Calendar <> vChildRoomRateObj.Calendar Then
					vChildRoomRateObj.Calendar = Calendar;
				EndIf;
				// Use prices from calendar
				If UsePricesFromCalendar <> vChildRoomRateObj.UsePricesFromCalendar Then
					vChildRoomRateObj.UsePricesFromCalendar = UsePricesFromCalendar;
				EndIf;
				If DefaultCurrency <> vChildRoomRateObj.DefaultCurrency Then
					vChildRoomRateObj.DefaultCurrency = DefaultCurrency;
				EndIf;
				// Room rate accommodation services
				If AccommodationService <> vChildRoomRateObj.AccommodationService Then
					vChildRoomRateObj.AccommodationService = AccommodationService;
				EndIf;
				If QuantityCalculationRule <> vChildRoomRateObj.QuantityCalculationRule Then
					vChildRoomRateObj.QuantityCalculationRule = QuantityCalculationRule;
				EndIf;
				If EarlyCheckInService <> vChildRoomRateObj.EarlyCheckInService Then
					vChildRoomRateObj.EarlyCheckInService = EarlyCheckInService;
				EndIf;
				If LateCheckOutService <> vChildRoomRateObj.LateCheckOutService Then
					vChildRoomRateObj.LateCheckOutService = LateCheckOutService;
				EndIf;
				If vChildRoomRateObj.Modified() Then
					vChildRoomRateObj.Write();
				EndIf;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // OnWrite

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
// Get list of prices for given room rate and parameters
// - pDate is optional. If is not specified, then function gets current prices
// - pClientType is optional. If is not specified then it is being set to empty ref.
// - pRoomType is optional. If is specified, then prices for this given room type 
//   are returned.
// - pAccommodationType is optional. If is specified, then prices for this given 
//   accommodation type are returned.
// -----------------------------------------------------------------------------
Function pmGetRoomRatePrices(Val pDate = Undefined, rPriceCalculationDate = Undefined, Val pClientType = Undefined, 
                             pRoomType = Undefined, pAccommodationType = Undefined, 
                             pServicePackagesList = Undefined, pPriceTag = Undefined, 
							 pCheckInDate = Undefined, pCheckOutDate = Undefined, pMinimizeOutput = False, pSortByPointInTime = False, 
							 pCalendarDayTypesList = Undefined, pHotel = Undefined, pAccommodationTemplate = Undefined, 
							 pIsForFolioSplit = False, pSplitPackagesByGuests = Undefined, pSharePercentIsSet = False) Export
	// Service packages
	vServicePackages = Undefined;
	If TypeOf(pServicePackagesList) = Type("ValueList") Then
		i = 1;
		vServicePackagesStruct = New Structure();
		For Each vServicePackagesItem In pServicePackagesList Do
			vServicePackagesStruct.Insert("ServicePackage" + Format(i, "ND=10; NFD=; NG="), vServicePackagesItem.Value);
			i = i + 1;
		EndDo;
		vServicePackages = vServicePackagesStruct;
	EndIf;
	
	// Calendar day types
	vCalendarDayTypes = Undefined;
	If TypeOf(pCalendarDayTypesList) = Type("ValueList") Then
		i = 1;
		vCalendarDayTypesStruct = New Structure();
		For Each vCalendarDayTypesItem In pCalendarDayTypesList Do
			vCalendarDayTypesStruct.Insert("CalendarDayType" + Format(i, "ND=10; NFD=; NG="), vCalendarDayTypesItem.Value);
			i = i + 1;
		EndDo;
		vCalendarDayTypes = vCalendarDayTypesStruct;
	EndIf;
	
	// Call cached function
	vPriceCalculationDate = rPriceCalculationDate;
	vStruct = CachedAccounts.GetRoomRatePrices(Ref, pDate, vPriceCalculationDate, pClientType, 
                                               pRoomType, pAccommodationType, 
                                               vServicePackages, pPriceTag, 
							                   pCheckInDate, pCheckOutDate, pMinimizeOutput, pSortByPointInTime, 
							                   vCalendarDayTypes, pHotel, pAccommodationTemplate, 
											   pIsForFolioSplit, pSplitPackagesByGuests, pSharePercentIsSet);
	If rPriceCalculationDate <> vStruct.PriceCalculationDate Then
		rPriceCalculationDate = vStruct.PriceCalculationDate;
	EndIf;
	Return vStruct.Prices;
EndFunction // pmGetRoomRatePrices

// -----------------------------------------------------------------------------
Function pmGetRoomRateServicePackagesList(pServicePackagesList = Undefined, pMinimizeOutput = False) Export
	// Service packages
	vServicePackages = Undefined;
	If TypeOf(pServicePackagesList) = Type("ValueList") Then
		i = 1;
		vServicePackagesStruct = New Structure();
		For Each vServicePackagesItem In pServicePackagesList Do
			vServicePackagesStruct.Insert("ServicePackage" + Format(i, "ND=10; NFD=; NG="), vServicePackagesItem.Value);
			i = i + 1;
		EndDo;
		vServicePackages = vServicePackagesStruct;
	EndIf;
	
	// Call cached function
	vReturnServicePackagesStruct = CachedAccounts.GetRoomRateServicePackagesList(Ref, vServicePackages, pMinimizeOutput);
	
	// Convert structure back to the list
	vReturnServicePackagesList = New ValueList();
	For Each vReturnServicePackagesKeyAndValue In vReturnServicePackagesStruct Do
		vReturnServicePackagesList.Add(vReturnServicePackagesKeyAndValue.Value);
	EndDo;
	
	Return vReturnServicePackagesList;
EndFunction // pmGetRoomRateServicePackagesList

// -----------------------------------------------------------------------------
Function pmGetRoomRateDescription(pLang) Export
	vDescr = "";
	If Not ValueIsFilled(pLang) Then
		vDescr = TrimAll(Description);
	Else
		If IsBlankString(DescriptionTranslations) Then
			vDescr = TrimAll(Description);
		Else
			vDescr = TrimAll(cmNStr(DescriptionTranslations, pLang));
		EndIf;
	EndIf;
	Return vDescr;
EndFunction // pmGetRoomRateDescription

// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	Author = SessionParameters.CurrentUser;
	CreateDate = CurrentSessionDate();
	Hotel = SessionParameters.CurrentHotel;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Returns MLOS and CTA for the given check-in date and room type
// -----------------------------------------------------------------------------
Function pmGetRoomRateRestrictions(pCheckInDate, pCheckOutDate, pRoomType, pWithoutOnline = False, pPriceCalculationDate = '00010101') Export
	vRestrStruct = New Structure("StopSale, MLOS, MaxLOS, MinDaysBeforeCheckIn, MaxDaysBeforeCheckIn, CTA, CTD", False, 0, 0, 0, 0, False, False);
	If Not ValueIsFilled(pCheckInDate) Or Not ValueIsFilled(pCheckOutDate) Then
		Return vRestrStruct;
	EndIf;
	// Get week days
	vDayOfWeek = WeekDay(pCheckInDate);
	vCheckOutDayOfWeek = WeekDay(pCheckOutDate);
	vWeekDays = New ValueList();
	If ValueIsFilled(pCheckInDate) And ValueIsFilled(pCheckOutDate) And BegOfDay(pCheckOutDate) > BegOfDay(pCheckInDate) Then
		vCurDay = BegOfDay(pCheckInDate);
		While vCurDay < pCheckOutDate Do
			vWeekDay = WeekDay(vCurDay);
			If vWeekDays.FindByValue(vWeekDay) = Undefined Then
				vWeekDays.Add(vWeekDay);
			EndIf;
			If vWeekDays.Count() = 7 Then
				Break;
			EndIf;
			vCurDay = vCurDay + 24*3600;
		EndDo;
	EndIf;
	// Get accounting dates
	vAccountingDate = BegOfDay(pCheckInDate);
	vCheckOutAccountingDate = BegOfDay(pCheckOutDate);
	// Try to get calendar day type for the check-in date
	vCalendarDayType = cmGetCalendarDayType(Ref, vAccountingDate, pCheckInDate, pCheckOutDate, , pRoomType, pPriceCalculationDate);
	// Run query to search for restriction records
	vQry = New Query();
	vQry.Text = "SELECT
	            |	RoomRateRestrictions.Hotel AS Hotel,
	            |	RoomRateRestrictions.RoomRate AS RoomRate,
	            |	RoomRateRestrictions.RoomType AS RoomType,
	            |	RoomRateRestrictions.CalendarDayType AS CalendarDayType,
	            |	RoomRateRestrictions.DayOfWeek AS DayOfWeek,
	            |	RoomRateRestrictions.AccountingDate AS AccountingDate,
	            |	RoomRateRestrictions.StopSale AS StopSale,
	            |	RoomRateRestrictions.MLOS AS MLOS,
	            |	RoomRateRestrictions.MaxLOS AS MaxLOS,
	            |	RoomRateRestrictions.CTA AS CTA,
	            |	RoomRateRestrictions.CTD AS CTD,
	            |	RoomRateRestrictions.MinDaysBeforeCheckIn AS MinDaysBeforeCheckIn,
	            |	RoomRateRestrictions.MaxDaysBeforeCheckIn AS MaxDaysBeforeCheckIn,
	            |	RoomRateRestrictions.IsForOnlineOnly AS IsForOnlineOnly
	            |FROM
	            |	InformationRegister.RoomRateRestrictions AS RoomRateRestrictions
	            |WHERE
	            |	(RoomRateRestrictions.RoomRate = &qRoomRate
	            |			OR RoomRateRestrictions.RoomRate = VALUE(Catalog.RoomRates.EmptyRef))
	            |	AND (RoomRateRestrictions.Hotel = &qEmptyHotel
	            |			OR &qHotelIsFilled
	            |				AND RoomRateRestrictions.Hotel = &qHotel
	            |			OR NOT &qHotelIsFilled)
	            |	AND (RoomRateRestrictions.RoomType = &qEmptyRoomType
	            |			OR &qRoomTypeIsFilled
	            |				AND RoomRateRestrictions.RoomType = &qRoomType)
	            |	AND (RoomRateRestrictions.CalendarDayType = &qEmptyCalendarDayType
	            |			OR &qCalendarDayTypeIsFilled
	            |				AND RoomRateRestrictions.CalendarDayType = &qCalendarDayType
	            |				AND RoomRateRestrictions.DayOfWeek = 0)
	            |	AND (RoomRateRestrictions.DayOfWeek = 0
	            |			OR RoomRateRestrictions.DayOfWeek = &qDayOfWeek
	            |				AND RoomRateRestrictions.AccountingDate = &qEmptyDate
	            |				AND (RoomRateRestrictions.CTA
	            |					OR RoomRateRestrictions.MinDaysBeforeCheckIn > 0
	            |					OR RoomRateRestrictions.MaxDaysBeforeCheckIn > 0
	            |					OR RoomRateRestrictions.MLOS > 0
	            |					OR RoomRateRestrictions.MaxLOS > 0)
	            |				AND RoomRateRestrictions.DayOfWeek <> 0
	            |				AND RoomRateRestrictions.CalendarDayType = &qEmptyCalendarDayType
	            |			OR RoomRateRestrictions.DayOfWeek = &qDayOfWeek
	            |				AND (RoomRateRestrictions.CTA
	            |					OR RoomRateRestrictions.MinDaysBeforeCheckIn > 0
	            |					OR RoomRateRestrictions.MaxDaysBeforeCheckIn > 0
	            |					OR RoomRateRestrictions.MLOS > 0
	            |					OR RoomRateRestrictions.MaxLOS > 0)
	            |				AND RoomRateRestrictions.AccountingDate = &qEmptyDate
	            |				AND RoomRateRestrictions.DayOfWeek <> 0
	            |				AND RoomRateRestrictions.CalendarDayType <> &qEmptyCalendarDayType
	            |				AND RoomRateRestrictions.CalendarDayType = &qCalendarDayType
	            |				AND &qCalendarDayTypeIsFilled
	            |			OR RoomRateRestrictions.DayOfWeek = &qCheckOutDayOfWeek
	            |				AND RoomRateRestrictions.AccountingDate = &qEmptyDate
	            |				AND RoomRateRestrictions.CTD
	            |				AND RoomRateRestrictions.DayOfWeek <> 0
	            |				AND RoomRateRestrictions.CalendarDayType = &qEmptyCalendarDayType
	            |			OR RoomRateRestrictions.DayOfWeek = &qCheckOutDayOfWeek
	            |				AND RoomRateRestrictions.AccountingDate = &qEmptyDate
	            |				AND RoomRateRestrictions.CTD
	            |				AND RoomRateRestrictions.DayOfWeek <> 0
	            |				AND RoomRateRestrictions.CalendarDayType <> &qEmptyCalendarDayType
	            |				AND RoomRateRestrictions.CalendarDayType = &qCalendarDayType
	            |				AND &qCalendarDayTypeIsFilled
	            |			OR RoomRateRestrictions.DayOfWeek IN (&qDaysOfWeek)
	            |				AND RoomRateRestrictions.AccountingDate = &qEmptyDate
	            |				AND RoomRateRestrictions.StopSale
	            |				AND RoomRateRestrictions.DayOfWeek <> 0
	            |				AND RoomRateRestrictions.CalendarDayType = &qEmptyCalendarDayType
	            |			OR RoomRateRestrictions.DayOfWeek IN (&qDaysOfWeek)
	            |				AND RoomRateRestrictions.StopSale
	            |				AND RoomRateRestrictions.AccountingDate = &qEmptyDate
	            |				AND RoomRateRestrictions.DayOfWeek <> 0
	            |				AND RoomRateRestrictions.CalendarDayType <> &qEmptyCalendarDayType
	            |				AND RoomRateRestrictions.CalendarDayType = &qCalendarDayType
	            |				AND &qCalendarDayTypeIsFilled)
	            |	AND (RoomRateRestrictions.AccountingDate = &qEmptyDate
	            |			OR &qAccountingDateIsFilled
	            |				AND RoomRateRestrictions.AccountingDate = &qAccountingDate
	            |				AND (RoomRateRestrictions.CTA
	            |					OR RoomRateRestrictions.MinDaysBeforeCheckIn > 0
	            |					OR RoomRateRestrictions.MaxDaysBeforeCheckIn > 0
	            |					OR RoomRateRestrictions.MLOS > 0
	            |					OR RoomRateRestrictions.MaxLOS > 0)
	            |			OR &qAccountingDateIsFilled
	            |				AND &qCheckOutAccountingDateIsFilled
	            |				AND RoomRateRestrictions.AccountingDate = &qCheckOutAccountingDate
	            |				AND RoomRateRestrictions.CTD
	            |			OR &qAccountingDateIsFilled
	            |				AND &qCheckOutAccountingDateIsFilled
	            |				AND RoomRateRestrictions.AccountingDate >= &qAccountingDate
	            |				AND (RoomRateRestrictions.AccountingDate < &qCheckOutAccountingDate
	            |					OR RoomRateRestrictions.AccountingDate = &qAccountingDate
	            |						AND &qAccountingDate = &qCheckOutAccountingDate)
	            |				AND RoomRateRestrictions.StopSale)
	            |	AND (NOT &qWithoutOnline
	            |			OR &qWithoutOnline
	            |				AND NOT RoomRateRestrictions.IsForOnlineOnly)";
	vQry.SetParameter("qRoomRate", Ref);
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsFilled", ValueIsFilled(Hotel));
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qRoomType", pRoomType);
	vQry.SetParameter("qRoomTypeIsFilled", ValueIsFilled(pRoomType));
	vQry.SetParameter("qEmptyRoomType", Catalogs.RoomTypes.EmptyRef());
	vQry.SetParameter("qCalendarDayType", vCalendarDayType);
	vQry.SetParameter("qCalendarDayTypeIsFilled", ValueIsFilled(vCalendarDayType));
	vQry.SetParameter("qEmptyCalendarDayType", Catalogs.CalendarDayTypes.EmptyRef());
	vQry.SetParameter("qDayOfWeek", vDayOfWeek);
	vQry.SetParameter("qCheckOutDayOfWeek", vCheckOutDayOfWeek);
	vQry.SetParameter("qDaysOfWeek", vWeekDays);
	vQry.SetParameter("qAccountingDate", vAccountingDate);
	vQry.SetParameter("qAccountingDateIsFilled", ValueIsFilled(vAccountingDate));
	vQry.SetParameter("qCheckOutAccountingDate", vCheckOutAccountingDate);
	vQry.SetParameter("qCheckOutAccountingDateIsFilled", ValueIsFilled(vCheckOutAccountingDate));
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qWithoutOnline", pWithoutOnline);
	vRestrictions = vQry.Execute().Unload();
	For Each vRestrictionsRow In vRestrictions Do
		If vRestrictionsRow.StopSale Then
			vRestrStruct.StopSale = True;
		EndIf;
		If vRestrictionsRow.CTA Then
			vRestrStruct.CTA = True;
		EndIf;
		If vRestrictionsRow.CTD Then
			vRestrStruct.CTD = True;
		EndIf;
		If vRestrictionsRow.MLOS > vRestrStruct.MLOS Then
			vRestrStruct.MLOS = vRestrictionsRow.MLOS;
		EndIf;
		If vRestrictionsRow.MaxLOS <> 0 And (vRestrStruct.MaxLOS = 0 Or vRestrictionsRow.MaxLOS < vRestrStruct.MaxLOS) Then
			vRestrStruct.MaxLOS = vRestrictionsRow.MaxLOS;
		EndIf;
		If vRestrictionsRow.MinDaysBeforeCheckIn > vRestrStruct.MinDaysBeforeCheckIn Then
			vRestrStruct.MinDaysBeforeCheckIn = vRestrictionsRow.MinDaysBeforeCheckIn;
		EndIf;
		If vRestrictionsRow.MaxDaysBeforeCheckIn <> 0 And (vRestrStruct.MaxDaysBeforeCheckIn = 0 Or vRestrictionsRow.MaxDaysBeforeCheckIn < vRestrStruct.MaxDaysBeforeCheckIn) Then
			vRestrStruct.MaxDaysBeforeCheckIn = vRestrictionsRow.MaxDaysBeforeCheckIn;
		EndIf;
	EndDo;
	Return vRestrStruct;
EndFunction // pmGetRoomRateRestrictions

// -----------------------------------------------------------------------------
// Returns value table with room rates based on the current one
// -----------------------------------------------------------------------------
Function pmGetChildRoomRates() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomRates.Ref AS RoomRate
	|FROM
	|	Catalog.RoomRates AS RoomRates
	|WHERE
	|	NOT RoomRates.DeletionMark
	|	AND NOT RoomRates.IsFolder
	|	AND RoomRates.BasedOnRoomRate = &qRoomRate
	|
	|ORDER BY
	|	RoomRates.SortCode,
	|	RoomRates.Description";
	vQry.SetParameter("qRoomRate", Ref);
	vChildRoomRates = vQry.Execute().Unload();
	Return vChildRoomRates;
EndFunction // pmGetChildRoomRates

// -----------------------------------------------------------------------------
Procedure pmWriteToRoomRateChangeHistory(pPeriod, pUser) Export
	// Get channges description
	vChanges = cmGetObjectChanges(ThisObject);
	If Not IsBlankString(vChanges) Then
		vCChgRec = InformationRegisters.RoomRateChangeHistory.CreateRecordManager();
		
		FillCChgAttributes(vCChgRec, pPeriod, pUser);
		vCChgRec.Changes = vChanges;
		
		// Write record
		vCChgRec.Write(True);    
		
		// User activity history
		InformationRegisters.UserActionsHistory.WriteUserActivityRecord(Ref, vChanges, Hotel, pUser, pPeriod);
	EndIf;
EndProcedure // pmWriteToRoomRateChangeHistory

// -----------------------------------------------------------------------------
Function pmGetPreviousObjectState(pPeriod) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	*
	|FROM
	|	InformationRegister.RoomRateChangeHistory.SliceLast(&qPeriod, RoomRate = &qRef) AS RoomRateChangeHistory";
	vQry.SetParameter("qPeriod", pPeriod);
	vQry.SetParameter("qRef", Ref);
	vStates = vQry.Execute().Unload();
	If vStates.Count() > 0 Then
		Return vStates.Get(0);
	Else
		Return Undefined;
	EndIf;
EndFunction // pmGetPreviousObjectState

// -----------------------------------------------------------------------------
Procedure pmRestoreAttributesFromHistory(pChgRec) Export
	FillPropertyValues(ThisObject, pChgRec, , "Code, Description");
	If Not IsBlankString(pChgRec.Code) Then
		Code = pChgRec.Code;
	EndIf;
	If Not IsBlankString(pChgRec.Description) Then
		Description = pChgRec.Description;
	EndIf;
	// Restore tabular parts
	vServicePackages = pChgRec.ServicePackages.Get();
	If vServicePackages <> Undefined Then
		ServicePackages.Load(vServicePackages);
	Else
		ServicePackages.Clear();
	EndIf;
	vFormulas = pChgRec.Formulas.Get();
	If vFormulas <> Undefined Then
		Formulas.Load(vFormulas);
	Else
		Formulas.Clear();
	EndIf;
EndProcedure // pmRestoreAttributesFromHistory

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure FillCChgAttributes(pCChgRec, pPeriod, pUser)
	FillPropertyValues(pCChgRec, ThisObject);
	
	pCChgRec.Period = pPeriod;
	pCChgRec.RoomRate = Ref;
	pCChgRec.User = pUser;
	
	// Store tabular parts
	vServicePackages = New ValueStorage(ServicePackages.Unload());
	pCChgRec.ServicePackages = vServicePackages;
	vFormulas = New ValueStorage(Formulas.Unload());
	pCChgRec.Formulas = vFormulas;
EndProcedure // FillCChgAttributes

#EndRegion
