
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	// Initialize hotel
	tcOnServer.cmInitHotel(Object);
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(Object.Hotel, "BackgroundColorImportant");
	
	// Initialize new room rate attributes
	If Not ValueIsFilled(Object.Ref) And Object.PeriodInHours = 0 Then
		vHotel = SessionParameters.CurrentHotel;
		Object.Author = SessionParameters.CurrentUser;
		Object.CreateDate = CurrentSessionDate();
		If ValueIsFilled(Object.Hotel) Then
			vHotel = Object.Hotel;
		Else
			Object.Hotel = vHotel;
		EndIf;
		vCopyRoomRate = vHotel.RoomRate;
		If ValueIsFilled(vCopyRoomRate) Then
			Object.AccommodationService = vCopyRoomRate.AccommodationService;
			If Not ValueIsFilled(Object.Calendar) Then
				Object.Calendar = vCopyRoomRate.Calendar;
			EndIf;
			Object.CloseOfPeriodDoChargeServices = vCopyRoomRate.CloseOfPeriodDoChargeServices;
			Object.DefaultCheckInTime = vCopyRoomRate.DefaultCheckInTime;
			Object.DefaultCheckOutTime = vCopyRoomRate.DefaultCheckOutTime;
			Object.DefaultDuration = vCopyRoomRate.DefaultDuration;
			Object.DoNotRefillOccupationPercentsAfterInHouseRoomChange = vCopyRoomRate.DoNotRefillOccupationPercentsAfterInHouseRoomChange;
			Object.DurationCalculationRuleType = vCopyRoomRate.DurationCalculationRuleType;
			Object.EarlyCheckInService = vCopyRoomRate.EarlyCheckInService;
			Object.FeeTerms = vCopyRoomRate.FeeTerms;
			Object.FirstDayEndsAtReferenceHourTime = vCopyRoomRate.FirstDayEndsAtReferenceHourTime;
			Object.LateCheckOutService = vCopyRoomRate.LateCheckOutService;
			Object.MLOSIsBlocking = vCopyRoomRate.MLOSIsBlocking;
			Object.PeriodInHours = vCopyRoomRate.PeriodInHours;
			Object.QuantityCalculationRule = vCopyRoomRate.QuantityCalculationRule;
			Object.RateChargeDirection = vCopyRoomRate.RateChargeDirection;
			Object.ReferenceHour = vCopyRoomRate.ReferenceHour;
			Object.ReservationConditions = vCopyRoomRate.ReservationConditions;
			Object.ReservationConditionsShort = vCopyRoomRate.ReservationConditionsShort;
			Object.RoomRateType = vCopyRoomRate.RoomRateType;
			Object.RoomRateServiceGroup = vCopyRoomRate.RoomRateServiceGroup;
			Object.RoundPrice = vCopyRoomRate.RoundPrice;
			Object.RoundPriceDigits = vCopyRoomRate.RoundPriceDigits;
			Object.RoundPriceServiceGroup = vCopyRoomRate.RoundPriceServiceGroup;
			Object.ServicePackage = vCopyRoomRate.ServicePackage;
			Object.UseNewFolioIfCheckOutDateChanged = vCopyRoomRate.UseNewFolioIfCheckOutDateChanged;
		EndIf;
	EndIf;
	
	If ValueIsFilled(tcOnServer.cmGetCurrentUserAttribute("Customer")) Then
		ReadOnly = True;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		ReadOnly = True;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToApproveRoomRates") Then
		Items.RoomRatesApproved.Enabled = False;
	Else
		Items.RoomRatesApproved.Enabled = True;
	EndIf;
	RoomRatesApprovedAppearance();
	PricesRepostIsNeeded = False;
	FillRoomRateDailyPricesIsNeeded = False;
	BasedOnRoomRateOnOpen = Object.BasedOnRoomRate;
	PriceSettingMethod = 0;
	PriceSettingMode = 0;
	If ValueIsFilled(Object.BasedOnRoomRate) Then
		PriceSettingMethod = 1;
		If ValueIsFilled(Object.BasedOnRoomRate.PriceTagType) Then
			If ValueIsFilled(Object.PriceTagType) Then
				Items.BasedOnPriceTag.Visible = False;
			Else
				Items.BasedOnPriceTag.Visible = True;
			EndIf;
			Items.GroupPriceTags.Visible = True;
		Else
			Items.BasedOnPriceTag.Visible = False;
			Items.GroupPriceTags.Visible = False;
		EndIf;

		Items.PriceSettingMode.Visible = False;
		Items.RateServicesGroup.Visible = False;
		Items.DefaultCurrency.Visible = False;
		Items.DependenciesGroup.Visible = True;
		Items.GroupDiscount.Visible = False;
	Else
		Items.PriceSettingMode.Visible = True;
		If ValueIsFilled(Object.PriceTagType) Then
			PriceSettingMethod = 2;
			Items.RateServicesGroup.Visible = True;
			Items.DefaultCurrency.Visible = False;
			Items.GroupPriceTags.Visible = True;
			Items.GroupDiscount.Visible = Not Object.UsePricesFromCalendar;
		Else
			Items.RateServicesGroup.Visible = True;
			Items.DefaultCurrency.Visible = Object.UsePricesFromCalendar;
			Items.GroupDiscount.Visible = Not Object.UsePricesFromCalendar;
			Items.GroupPriceTags.Visible = False;
		EndIf;
		If Object.UsePricesFromCalendar Then
			PriceSettingMode = 1;
		EndIf;
		
		Items.DependenciesGroup.Visible = false;
	EndIf;
	
	// Tourist tax (RU)
	If ValueIsFilled(Object.Hotel) Then
		If Object.Hotel.TouristTaxIsUsed Then
			Items.GroupTouristTax.Visible = True;
		Else
			Items.GroupTouristTax.Visible = False;
		EndIf;
	Else
		Items.GroupTouristTax.Visible = True;
	EndIf;
	If Object.RateChargeDirection = Enums.RateChargeDirections.MergeToTheMainRoomGuest Then
		Items.DoNotMergeTouristTaxBaseToTheMainRoomGuest.Enabled = False;
		If Object.DoNotMergeTouristTaxBaseToTheMainRoomGuest Then
			Object.DoNotMergeTouristTaxBaseToTheMainRoomGuest = False;
		EndIf;
	Else
		Items.DoNotMergeTouristTaxBaseToTheMainRoomGuest.Enabled = True;
	EndIf;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	// Store room rate state
	WasModified = Modified;
	// Check rate attributes
	If pCurrentObject.UsePricesFromCalendar Then
		If Not ValueIsFilled(pCurrentObject.AccommodationService) Then
			vUM = New UserMessage();
			vUM.Field = "AccommodationService";
			vUM.SetData(pCurrentObject);
			vUM.Text = NStr("en='Accommodation service should be filled in the rate!'; ru='В тарифе должна быть указана услуга проживания!'; de='Im Tarif muss ein Übernachtungsservice angegeben sein!'");
			vUM.Message();
			pCancel = True;
		Else
			If Not ValueIsFilled(pCurrentObject.QuantityCalculationRule) Then
				vUM = New UserMessage();
				vUM.Field = "QuantityCalculationRule";
				vUM.SetData(pCurrentObject);
				vUM.Text = NStr("en='Quantity calculation rule should be filled in the rate!'; ru='В тарифе должно быть указано правило выичления количества!'; de='Im Tarif muss eine Regel zur Berechnung der Menge angegeben werden!'");
				vUM.Message();
				pCancel = True;
			EndIf;
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure AfterWriteAtServer(pCurrentObject, pWriteParameters)
	// Save changes to the client change history
	If WasModified Then
		pCurrentObject.pmWriteToRoomRateChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
	EndIf;
	// Repost price orders
	If PricesRepostIsNeeded Then
		PricesRepostIsNeeded = False;
		// Repost price orders at server in background
		RepostRoomRatePriceOrders(Undefined, Object.Ref);
	EndIf;
	// Refill room rate daily prices
	If Not ValueIsFilled(Object.BasedOnRoomRate) And (Not ValueIsFilled(Object.Hotel) Or ValueIsFilled(Object.Hotel) And Object.Hotel.UseRoomRateDailyPrices) Then
		If FillRoomRateDailyPricesIsNeeded Then
			FillRoomRateDailyPricesIsNeeded = False;
			// Run fill room rate daily prices cache in background
			RefillRoomRateDailyPrices(Object.Ref);
		EndIf;
	EndIf;
EndProcedure // AfterWriteAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure PriceSettingMethodOnChange(pItem)
	If PriceSettingMethod = 1 Then // Formulas
		If ValueIsFilled(Object.AccommodationService) Then
			Object.AccommodationService = Undefined;
		EndIf;
		If ValueIsFilled(Object.EarlyCheckInService) Then
			Object.EarlyCheckInService = Undefined;
		EndIf;
		If ValueIsFilled(Object.LateCheckOutService) Then
			Object.LateCheckOutService = Undefined;
		EndIf;
		If ValueIsFilled(Object.BasedOnRoomRate) And ValueIsFilled(tcOnServer.cmGetAttributeByRef(Object.BasedOnRoomRate, "PriceTagType")) Then
			If ValueIsFilled(Object.PriceTagType) Then
				Items.BasedOnPriceTag.Visible = False;
			Else
				Items.BasedOnPriceTag.Visible = True;
			EndIf;
			Items.GroupPriceTags.Visible = True;
		Else
			Items.BasedOnPriceTag.Visible = False;
			Items.GroupPriceTags.Visible = False;
		EndIf;
		If Object.Discount <> 0 Then
			Object.Discount = 0;
		EndIf;
		If Object.UsePricesFromCalendar Then
			Object.UsePricesFromCalendar = False;
			PriceSettingMode = 0;
		EndIf;

		Items.PriceSettingMode.Visible = False;
		Items.RateServicesGroup.Visible = False;
		Items.DependenciesGroup.Visible = True;

		Items.DefaultCurrency.Visible = False;
		Items.GroupDiscount.Visible = False;
	ElsIf PriceSettingMethod = 2 Then // dynamic pricing
		Items.PriceSettingMode.Visible = True;
		Items.RateServicesGroup.Visible = True;
		Items.DependenciesGroup.Visible = False;
		Items.GroupPriceTags.Visible = True;

		Items.DefaultCurrency.Visible = Object.UsePricesFromCalendar;
		Items.GroupDiscount.Visible = Not Object.UsePricesFromCalendar;
	Else // independent
		If ValueIsFilled(Object.BasedOnRoomRate) Then
			Object.BasedOnRoomRate = Undefined;
		EndIf;
		If ValueIsFilled(Object.BasedOnPriceTag) Then
			Object.BasedOnPriceTag = Undefined;
		EndIf;
		If ValueIsFilled(Object.PriceTagType) Then
			Object.PriceTagType = Undefined;
		EndIf;
		
		Items.PriceSettingMode.Visible = True;
		Items.RateServicesGroup.Visible = True;
		Items.DependenciesGroup.Visible = False;
		Items.GroupPriceTags.Visible = False;

		Items.DefaultCurrency.Visible = Object.UsePricesFromCalendar;
		Items.GroupDiscount.Visible = Not Object.UsePricesFromCalendar;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PriceTagTypeOnChange(pItem)
	If ValueIsFilled(Object.BasedOnRoomRate) And ValueIsFilled(tcOnServer.cmGetAttributeByRef(Object.BasedOnRoomRate, "PriceTagType")) Then
		If ValueIsFilled(Object.PriceTagType) Then
			Items.BasedOnPriceTag.Visible = False;
		Else
			Items.BasedOnPriceTag.Visible = True;
		EndIf;
	Else
		Items.BasedOnPriceTag.Visible = False;
	EndIf;
EndProcedure // PriceTagTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure BasedOnRoomRateOnChange(pItem)
	If ValueIsFilled(Object.BasedOnRoomRate) Then
		If Object.BasedOnRoomRate = Object.Ref Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You can not set base room rate to itself!'; ru='В качестве основания указывать тот же самый тариф нельзя!'; de='Sie können Basis-Zimmerpreis beinhaltet nicht um sich festgelegt!'"), MessageStatus.Attention);
			Object.BasedOnRoomRate = PredefinedValue("Catalog.RoomRates.EmptyRef");
			Return;
		EndIf;
		vBasedRateCalendar = tcOnServer.cmGetAttributeByRef(Object.BasedOnRoomRate, "Calendar");
		If vBasedRateCalendar <> Object.Calendar Then
			Object.Calendar = vBasedRateCalendar;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Calendar for the derived rate should be the same like base rate has. Calendar was changed automatically!'; ru='У подчиненного тарифа календарь должен совпадать с календарем у основного тарифа. Календарь был изменен автоматически!'; de='Der Kalender des Untertarifs muss mit dem Kalender des Haupttarifs übereinstimmen. Der Kalender wurde automatisch geändert!'"));
		EndIf;
		vBasedRatePriceTagType = tcOnServer.cmGetAttributeByRef(Object.BasedOnRoomRate, "PriceTagType");
		Object.PriceTagType = vBasedRatePriceTagType;
		// Dynamic pricing
		If ValueIsFilled(vBasedRatePriceTagType) Then
			Items.BasedOnPriceTag.Visible = True;
		Else
			Items.BasedOnPriceTag.Visible = False;
		EndIf;
		// Use prices from calendar
		Object.UsePricesFromCalendar = tcOnServer.cmGetAttributeByRef(Object.BasedOnRoomRate, "UsePricesFromCalendar");
		Object.DefaultCurrency = tcOnServer.cmGetAttributeByRef(Object.BasedOnRoomRate, "DefaultCurrency");
		Object.AccommodationService = tcOnServer.cmGetAttributeByRef(Object.BasedOnRoomRate, "AccommodationService");
		Object.QuantityCalculationRule = tcOnServer.cmGetAttributeByRef(Object.BasedOnRoomRate, "QuantityCalculationRule");
		Object.EarlyCheckInService = tcOnServer.cmGetAttributeByRef(Object.BasedOnRoomRate, "EarlyCheckInService");
		Object.LateCheckOutService = tcOnServer.cmGetAttributeByRef(Object.BasedOnRoomRate, "LateCheckOutService");
	EndIf;
EndProcedure // BasedOnRoomRateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure BasedOnPriceTagOnChange(pItem)
	If ValueIsFilled(Object.BasedOnPriceTag) Then
		If ValueIsFilled(Object.PriceTagType) Then
			Object.PriceTagType = Undefined;
		EndIf;
	EndIf;
EndProcedure // BasedOnPriceTagOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountOnChange(pItem)
	PricesRepostIsNeeded = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountServiceGroupOnChange(pItem)
	PricesRepostIsNeeded = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure IsRackRateOnChange(pItem)
	If Object.IsRackRate Then
		If Object.IsComplimentary Then
			Object.IsComplimentary = False;
			Modified = True;
		EndIf;
		If Object.IsHouseUse Then
			Object.IsHouseUse = False;
			Modified = True;
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure IsComplimentaryOnChange(pItem)
	If Object.IsComplimentary Then
		If Object.IsRackRate Then
			Object.IsRackRate = False;
			Modified = True;
		EndIf;
		If Object.IsHouseUse Then
			Object.IsHouseUse = False;
			Modified = True;
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure IsHouseUseOnChange(pItem)
	If Object.IsHouseUse Then
		If Object.IsRackRate Then
			Object.IsRackRate = False;
			Modified = True;
		EndIf;
		If Object.IsComplimentary Then
			Object.IsComplimentary = False;
			Modified = True;
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ClientTypeOnChange(Item)
	ClientTypeOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DescriptionTranslationsOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", Object.DescriptionTranslations), pItem);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ReservationConditionsOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", Object.ReservationConditions), pItem);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesIncludedDescriptionOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", Object.ServicesIncludedDescription), pItem);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AccommodationServiceOnChange(pItem)
	PricesRepostIsNeeded = True;
	If ValueIsFilled(Object.AccommodationService) Then
		vQuantityCalculationRule = tcOnServer.cmGetAttributeByRef(Object.AccommodationService, "QuantityCalculationRule");
		If ValueIsFilled(vQuantityCalculationRule) Then
			Object.QuantityCalculationRule = vQuantityCalculationRule;
		EndIf;
	EndIf;
EndProcedure // AccommodationServiceOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure EarlyCheckInServiceOnChange(pItem)
	PricesRepostIsNeeded = True;
EndProcedure // EarlyCheckInServiceOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure LateCheckOutServiceOnChange(pItem)
	PricesRepostIsNeeded = True;
EndProcedure // LateCheckOutServiceOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure FormulasRoomClassOnChange(pItem)
	vCurRow = Items.Formulas.CurrentData;
	If ValueIsFilled(vCurRow.RoomClass) Then
		vCurRow.RoomType = Undefined;
	EndIf;
EndProcedure // FormulasRoomClassOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure FormulasRoomTypeOnChange(pItem)
	vCurRow = Items.Formulas.CurrentData;
	If ValueIsFilled(vCurRow.RoomType) Then
		vCurRow.RoomClass = Undefined;
	EndIf;
EndProcedure // FormulasRoomTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelOnChange(Item)
	HotelOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicePackagesOnChange(pItem)
	FillRoomRateDailyPricesIsNeeded = True;
EndProcedure // ServicePackagesOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicePackageOnChange(pItem)
	FillRoomRateDailyPricesIsNeeded = True;
EndProcedure // ServicePackageOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RateChargeDirectionOnChange(pItem)
	RateChargeDirectionOnChangeAtServer();
EndProcedure // RateChargeDirectionOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure TouristTaxAddToRateOnChange(pItem)
	If Object.TouristTaxAddToRate Then
		If Object.TouristTaxSubtractFromRateIfExemption Then
			Object.TouristTaxSubtractFromRateIfExemption = False;
		EndIf;
		If ValueIsFilled(Object.TouristTaxService) Then
			Object.TouristTaxService = PredefinedValue("Catalog.Services.EmptyRef");
		EndIf;
	EndIf;
EndProcedure // TouristTaxAddToRateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure TouristTaxSubtractFromRateIfExemptionOnChange(pItem)
	If Object.TouristTaxSubtractFromRateIfExemption Then
		If Object.TouristTaxAddToRate Then
			Object.TouristTaxAddToRate = False;
		EndIf;
		If ValueIsFilled(Object.TouristTaxService) Then
			Object.TouristTaxService = PredefinedValue("Catalog.Services.EmptyRef");
		EndIf;
	EndIf;
EndProcedure // TouristTaxSubtractFromRateIfExemptionOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure TouristTaxServiceOnChange(pItem)
	If ValueIsFilled(Object.TouristTaxService) Then
		If Object.TouristTaxAddToRate Then
			Object.TouristTaxAddToRate = False;
		EndIf;
		If Object.TouristTaxSubtractFromRateIfExemption Then
			Object.TouristTaxSubtractFromRateIfExemption = False;
		EndIf;
	EndIf;
EndProcedure // TouristTaxServiceOnChange

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure CommandCopy(Command)
	vParams = New Structure("BaseRate",Object.Ref);
	OpenForm("Catalog.RoomRates.Form.CopyAssistant",vParams);
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure RoomRatesApprovedAppearance()
	If Object.RoomRatesApproved Then
		Items.Calendar.ReadOnly = True;
		Items.DateValidFrom.ReadOnly = True;
		Items.DateValidTo.ReadOnly = True;
		Items.IsRackRate.Enabled = False;
		Items.IsComplimentary.Enabled = False;
		Items.RoomRateServiceGroup.ReadOnly = True;
		Items.PeriodInHours.ReadOnly = True;
		Items.DurationCalculationRuleType.ReadOnly = True;
		Items.ReferenceHour.ReadOnly = True;
		Items.FirstDayEndsAtReferenceHourTime.Enabled = False;
		Items.Discount.ReadOnly = True;
		Items.DiscountServiceGroup.ReadOnly = True;
		Items.DiscountType.ReadOnly = True;
		Items.NoDiscounts.Enabled = False;
		Items.RoundPrice.Enabled = False;
		Items.RoundPriceDigits.ReadOnly = True;
		Items.RoundPriceServiceGroup.ReadOnly = True;
		Items.NoAgentCommission.Enabled = False;
		Items.ServicePackage.ReadOnly = True;
		Items.FeeTerms.ReadOnly = True;
	Else
		Items.Calendar.ReadOnly = False;
		Items.DateValidFrom.ReadOnly = False;
		Items.DateValidTo.ReadOnly = False;
		Items.IsRackRate.Enabled = True;
		Items.IsComplimentary.Enabled = True;
		Items.RoomRateServiceGroup.ReadOnly = False;
		Items.PeriodInHours.ReadOnly = False;
		Items.DurationCalculationRuleType.ReadOnly = False;
		Items.ReferenceHour.ReadOnly = False;
		Items.FirstDayEndsAtReferenceHourTime.Enabled = True;
		Items.Discount.ReadOnly = False;
		Items.DiscountServiceGroup.ReadOnly = False;
		Items.DiscountType.ReadOnly = False;
		Items.NoDiscounts.Enabled = True;
		Items.RoundPrice.Enabled = True;
		Items.RoundPriceDigits.ReadOnly = False;
		Items.RoundPriceServiceGroup.ReadOnly = False;
		Items.NoAgentCommission.Enabled = True;
		Items.ServicePackage.ReadOnly = False;
		Items.FeeTerms.ReadOnly = False;
	EndIf;
EndProcedure // RoomRatesApprovedAppearance

// -----------------------------------------------------------------------------
&AtServer
Procedure RepostRoomRatePriceOrders(pOldRoomRate, pRoomRate)
	vOperationParameters = New Array;
	vOperationParameters.Add(pOldRoomRate);
	vOperationParameters.Add(pRoomRate);
	vOperationName = NStr("en = 'Repost room rate price orders'; ru = 'Перепроведение приказов по тарифу'; de = 'Tarifbestellungen speichern'");
	AsyncCalls.StartBackgroundJobWithRecordInRegister(Object.Ref, vOperationName, "ProlongedOperations.RoomRate_RepostPriceOrders", vOperationParameters, "RoomRate_RepostPriceOrders_" + ?(ValueIsFilled(pOldRoomRate), TrimAll(pOldRoomRate.Code), "") + "_" + ?(ValueIsFilled(pRoomRate), TrimAll(pRoomRate.Code), ""));
EndProcedure // RepostRoomRatePriceOrders

// -----------------------------------------------------------------------------
&AtServer
Procedure RefillRoomRateDailyPrices(pRoomRate)
	vHotel = pRoomRate.Hotel;
	If Not ValueIsFilled(vHotel) Then
		vHotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(vHotel) Then
		vRoomRatesList = New ValueList();
		vRoomRatesList.Add(pRoomRate);
		vPeriodFrom = BegOfDay(CurrentSessionDate());
		vPeriodTo = GetLastCalendarDate(pRoomRate.Calendar);
		vParams = New Array();
		vParams.Add(vHotel);
		vParams.Add(vRoomRatesList);
		vParams.Add(vPeriodFrom);
		vParams.Add(vPeriodTo);
		vBJ = BackgroundJobs.Execute("JobsScheduled.cmFillRoomRatePricesCache", vParams, , NStr("en='Fill room rate prices cache: '; ru='Заполнение кэша цен тарифов: '; de='Zimmerpreis Preise Cache füllen: '") + TrimAll(vHotel) + ", " + GetListPresentation(vRoomRatesList) + ", " + Format(vPeriodFrom, "DF=dd.MM.yyyy") + " - " + Format(vPeriodTo, "DF=dd.MM.yyyy")); 
	EndIf;
EndProcedure // RefillRoomRateDailyPrices

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
&AtServer
Procedure ClientTypeOnChangeAtServer()
	If ValueIsFilled(Object.ClientType) Then
		If Object.ClientType.IsComplimentary Then
			Object.IsComplimentary = True;
			Object.IsHouseUse = False;
			Object.IsRackRate = False;
		EndIf;
		If Object.ClientType.IsHouseUse Then
			Object.IsHouseUse = True;
			Object.IsComplimentary = False;
			Object.IsRackRate = False;
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure HotelOnChangeAtServer()
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(Object.Hotel, "BackgroundColorImportant");
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PriceSettingModeOnChange(pItem)
	If PriceSettingMode = 1 Then
		Object.UsePricesFromCalendar = True;
	Else
		Object.UsePricesFromCalendar = False;
	EndIf;
	PriceSettingMethodOnChange(pItem);
EndProcedure // PriceSettingModeOnChange

// -----------------------------------------------------------------------------
&AtServer
Function GetLastCalendarDate(pCalendar)
	vLastCalendarDate = BegOfDay(CurrentSessionDate());
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	CalendarDays.AccountingDate AS AccountingDate
	|FROM
	|	InformationRegister.CalendarDays.SliceLast(
	|			&qPriceCalculationDate,
	|			Calendar = &qCalendar) AS CalendarDays
	|ORDER BY
	|	CalendarDays.AccountingDate DESC";
	vQry.SetParameter("qCalendar", pCalendar);
	vQry.SetParameter("qPriceCalculationDate", CurrentSessionDate());
	vDates = vQry.Execute().Unload();
	If vDates.Count() > 0 Then
		vDatesRow = vDates.Get(0);
		If ValueIsFilled(vDatesRow.AccountingDate) And vDatesRow.AccountingDate > vLastCalendarDate Then
			vLastCalendarDate = vDatesRow.AccountingDate;
		EndIf;
	EndIf;
	Return vLastCalendarDate;
EndFunction // GetLastCalendarDate

// -----------------------------------------------------------------------------
&AtServer
Procedure RateChargeDirectionOnChangeAtServer()
	If Object.RateChargeDirection = Enums.RateChargeDirections.MergeToTheMainRoomGuest Then
		Items.GroupTouristTax.Enabled = False;
		If Object.DoNotMergeTouristTaxBaseToTheMainRoomGuest Then
			Object.DoNotMergeTouristTaxBaseToTheMainRoomGuest = False;
		EndIf;
	Else
		Items.GroupTouristTax.Enabled = True;
	EndIf;
EndProcedure // RateChargeDirectionOnChangeAtServer

#EndRegion
