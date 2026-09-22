
#Region Variables

&AtClient	
Var LeftAreaSelected;	

&AtClient	
Var RightAreaSelected;

#EndRegion

#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	// Process form parameters
	NumberOfAdults = 2;
	If Parameters.Property("Hotel") And ValueIsFilled(Parameters.Hotel) Then
		SelHotel = Parameters.Hotel;
		HotelFromParams = Parameters.Hotel;
	EndIf;
	If Not ValueIsFilled(SelHotel) Then
		SelHotel = SessionParameters.CurrentHotel;
	EndIf;
	If Parameters.Property("Allotment") And ValueIsFilled(Parameters.Allotment) Then
		SelRoomQuotas.Clear();
		SelRoomQuotas.Add(Parameters.Allotment);
		
		RoomQuotaFromParams = Parameters.Allotment;
		PriceNumberOfAdults = Parameters.Allotment.PriceNumberOfAdults;
	EndIf;

	vCurrentDate = BegOfDay(CurrentSessionDate());
	If ValueIsFilled(SelHotel) And ValueIsFilled(SelHotel.AccountingDate) Then
		vCurrentDate = SelHotel.AccountingDate;
	EndIf;
	
	PeriodFromFromParams = '00010101';
	NumberOfDaysFromParams = 0;
	If Parameters.Property("PeriodFrom") And 
	   Parameters.Property("NumberOfDays") And 
	   ValueIsFilled(Parameters.PeriodFrom) And 
	   Parameters.NumberOfDays > 0 Then
		SelPeriodFrom = Max(vCurrentDate, Parameters.PeriodFrom);
		vShiftInSeconds = 0;
		If Parameters.PeriodFrom < vCurrentDate Then
			vShiftInSeconds = vCurrentDate - Parameters.PeriodFrom;
		EndIf;
		
		PeriodFromFromParams = SelPeriodFrom;
		NumberOfDaysFromParams = Parameters.NumberOfDays;
		If vShiftInSeconds <> 0 Then
			NumberOfDaysFromParams = NumberOfDaysFromParams - vShiftInSeconds/(24*3600);
			If NumberOfDaysFromParams < 0 Then
				NumberOfDaysFromParams = 0;
			EndIf;
		EndIf;
		If NumberOfDaysFromParams = 0 Then
			PeriodFromFromParams = '00010101';
		EndIf;
	EndIf;
	If SelNumberOfDays = 0 And NumberOfDaysFromParams = 0 And Not ValueIsFilled(PeriodFromFromParams) Then
		SelPeriodFrom = BegOfDay(CurrentSessionDate());
		vNumberOfDays = 40;
		
		SelNumberOfDays = vNumberOfDays;
		SelPeriodTo = EndOfDay(SelPeriodFrom) + 24*3600*(SelNumberOfDays-1);
	EndIf;
	If Not ValueIsFilled(SelPeriodFrom) Then
		SelPeriodFrom = BegOfDay(CurrentSessionDate());
	ElsIf SelPeriodFrom < BegOfDay(CurrentSessionDate()) And NumberOfDaysFromParams = 0 And Not ValueIsFilled(PeriodFromFromParams) Then
		SelPeriodFrom = BegOfDay(CurrentSessionDate());
	EndIf;
	If Not ValueIsFilled(SelPeriodTo) Or SelPeriodTo <= SelPeriodFrom Then
		SelPeriodTo = EndOfDay(SelPeriodFrom) + 24*3600*39;
		SelNumberOfDays = 40;
	EndIf;
	SelNumberOfDays = (EndOfDay(SelPeriodTo) - BegOfDay(SelPeriodFrom))/(24*3600);
	SelShowFreeSaleOnly = False;
	SelShowVacantOnly = False;
	
	// Set hotel color          
	Items.GroupMainFilters.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
	If Not IsInRole("RightsToChooseHotel") Then
		Items.SelHotel.ReadOnly = True;
		Items.SelHotel.ChoiceButton = False;
	EndIf;
	
	// Restore mode from the previous run
	SelShowVacants = False;
	SelMode = 0;
	vSelMode = 0;
	If Parameters.Property("Mode") Then
		vSelMode = Parameters.Mode;
	Else
		vSelMode = SystemSettingsStorage.Load("tcAllotmentVacantRoomsMode", SessionParameters.CurrentUser);
	EndIf;
	If vSelMode <> Undefined And TypeOf(vSelMode) = Type("Number") And vSelMode < 3 Then
		SelMode = vSelMode;
	EndIf;
	If SelMode > 0 Then
		Items.GroupPickupShowSelector.Visible = False;
		Items.MakePeriodSplittable.Enabled = False;
		Items.JoinPeriods.Enabled = False;
	Else
		Items.GroupPickupShowSelector.Visible = True;
		Items.MakePeriodSplittable.Enabled = True;
		Items.JoinPeriods.Enabled = True;
	EndIf;
	SelShowSelector = 0;
	If SelMode = 1 Then
		Items.GroupTotalsShowSelector.Visible = True;
	Else
		Items.GroupTotalsShowSelector.Visible = False;
	EndIf;
	If SelMode = 0 Then
		Items.GroupPages.CurrentPage = Items.GroupPickup;
	Else
		Items.GroupPages.CurrentPage = Items.GroupAllotmentEdit;
	EndIf;
	
	FillAllRoomTypes();
	
	// Weekdays
	AllDays = True;
	For i = 1 To 7 Do
		ThisObject["Day" + i] = AllDays;		
	EndDo;
	SetWeekdaysTitle();
	
	// State of actions panel
	PeriodFromChangeMode = False;
	FillDateSwitch();
	GuestGroupAppearance();	
	FillDurationPriceTagRoomRatesList();
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	If ValueIsFilled(HotelFromParams) Then
		SelHotel = HotelFromParams;
	EndIf;
	If ValueIsFilled(RoomQuotaFromParams) Then
		SelRoomQuotas.Clear();
		SelRoomQuotas.Add(RoomQuotaFromParams);
	EndIf;
	If ValueIsFilled(PeriodFromFromParams) Then
		SelPeriodFrom = PeriodFromFromParams;
	EndIf;
	If NumberOfDaysFromParams > 0 Then
		SelNumberOfDays = NumberOfDaysFromParams;
		SelShowReservations = True;
	EndIf;
	If SelNumberOfDays > 62 And NumberOfDaysFromParams = 0 Then
		SelNumberOfDays = 62;
	EndIf;
	SelPeriodTo = EndOfDay(SelPeriodFrom) + 24*3600*(SelNumberOfDays - 1);
	// Check hotel and fill currency
	If ValueIsFilled(SelHotel) Then
		SelCurrency = tcOnServer.cmGetAttributeByRef(SelHotel, "BaseCurrency");
		If SelRoomQuotas.Count() > 0 And ValueIsFilled(SelRoomQuotas.Get(0).Value) Then
			If Not tcOnServer.cmGetAttributeByRef(SelRoomQuotas.Get(0).Value, "IsFolder") Then
				vAllotmentHotel = tcOnServer.cmGetAttributeByRef(SelRoomQuotas.Get(0).Value, "Hotel");
				If ValueIsFilled(vAllotmentHotel) And vAllotmentHotel <> SelHotel Then
					SelRoomQuotas.Clear();
				EndIf;
			EndIf;
		EndIf;
	EndIf;		
	If SelRoomTypes.Count() > 0 Then
		Items.SelRoomTypes.InputHint = "";
	Else
		Items.SelRoomTypes.InputHint = NStr("en='<All if empty>'; ru='<По всем, если пусто>'; de='<Alle, falls leer>'");
	EndIf;
	If SelRoomQuotas.Count() > 0 Then
		Items.SelRoomQuotas.InputHint = "";
	Else
		Items.SelRoomQuotas.InputHint = NStr("en='<All if empty>'; ru='<По всем, если пусто>'; de='<Alle, falls leer>'");
	EndIf;
	// Generate report
	GenerateReport();
EndProcedure // OnOpen

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "Document.Accommodation.Write" Or 
	   pEventName = "Document.Reservation.Write" Or
	   pEventName = "Catalog.GuestGroups.Changed" Then
		SetGuestGroup(pParameter);
		AttachIdleHandler("AutoRefreshForm", 1, True);
	ElsIf pEventName = "Subsystem.Rooms.RoomQuotaSales.Changed" Then
		AttachIdleHandler("AutoRefreshForm", 1, True);
	EndIf;
EndProcedure // NotificationProcessing

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SelPeriodFromOnChange(pItem)
	SelPeriodFromOnChangeAtServer();
	DateSwitch = Month(SelPeriodFrom);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelNumberOfDaysOnChange(pItem)
	SelNumberOfDaysOnChangeAtServer();
	If BegOfDay(SelPeriodFrom) = BegOfDay(CurrentDate()) Then
		DateSwitch = 0;
	Else
		DateSwitch = Month(SelPeriodFrom);
	EndIf;
EndProcedure // SelNumberOfDaysOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelPeriodToOnChange(pItem)
	SelPeriodToOnChangeAtServer();
	DateSwitch = Month(SelPeriodFrom);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelShowOccupationPercentOnChange(pItem)
	SelShowOccupationPercentOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelCustomerOnChange(pItem)
	SelCustomerOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelStatusOnChange(pItem)
	// Generate report
	GenerateReport();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelAllotmentBusinessTypeOnChange(pItem)
	// Generate report
	GenerateReport();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelAgentOnChange(pItem)
	SelAgentOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelContractOnChange(pItem)
	// Generate report
	GenerateReport();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomQuotasOnChange(pItem)
	SelRoomQuotasOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelShowFreeSaleOnlyOnChange(pItem)
	SelShowFreeSaleOnlyOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomRateOnChange(pItem)
	If ValueIsFilled(SelRoomRate) Then
		RoomRate = SelRoomRate;
		SetPriceTagAppearance();
	EndIf;
	// Generate report
	GenerateReport();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelHotelOnChange(pItem)
	SelHotelOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelHotelClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DateSwitchOnChange(pItem)
	DateSwitchOnChangeAtServer();
EndProcedure // DateSwitchOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelShowVacantOnlyOnChange(pItem)
	GenerateReport();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ReportSpreadsheetSelection(pItem, pArea, pStandardProcessing)
	vDetails = pArea.Details;
	If TypeOf(vDetails) = Type("Structure") Then
		If vDetails.ReportName = "RoomInventory" Then
			pStandardProcessing = False;
			vParam = New Structure();
			vParam.Insert("Hotel", ?(vDetails.Hotel = Undefined, SelHotel, vDetails.Hotel));
			vParam.Insert("RoomType", ?(vDetails.RoomType = Undefined, ?(SelRoomTypes.Count() > 0, SelRoomTypes.Get(0).Value, Undefined), vDetails.RoomType));
			If ValueIsFilled(vDetails.CheckInDate) And ValueIsFilled(vDetails.CheckOutDate) Then
				vParam.Insert("PeriodTo", TryToGetPeriodWithVacantRoomsMinimum(vDetails));   
			Else
				If vDetails.IsLeft Then					
					vParam.Insert("PeriodTo", vDetails.PeriodDate - 24 * 3600);
				Else
					vParam.Insert("PeriodTo",vDetails.PeriodDate);
				EndIf;
			EndIf;
			vParam.Insert("GenerateOnOpen", True);
			OpenForm("Report.RoomInventory.Form.tcReportForm", vParam, , New UUID());			
		ElsIf vDetails.ReportName = "RoomQuotaSales" Then
			pStandardProcessing = False;
			vParam = New Structure();
			vParam.Insert("Hotel", ?(vDetails.Hotel = Undefined, SelHotel, vDetails.Hotel));
			vParam.Insert("RoomType", ?(vDetails.RoomType = Undefined, ?(SelRoomTypes.Count() > 0, SelRoomTypes.Get(0).Value, Undefined), vDetails.RoomType));
			vParam.Insert("RoomQuota", ?(vDetails.RoomQuota = Undefined, ?(SelRoomQuotas.Count() > 0, SelRoomQuotas.Get(0).Value, Undefined), vDetails.RoomQuota));
			vParam.Insert("Agent", SelAgent);
			vParam.Insert("Customer", SelCustomer);
			vParam.Insert("Contract", SelContract);
			If ValueIsFilled(vDetails.CheckInDate) And ValueIsFilled(vDetails.CheckOutDate) Then
				vParam.Insert("PeriodFrom", BegOfDay(vDetails.CheckInDate));
				vParam.Insert("PeriodTo", BegOfDay(vDetails.CheckOutDate) - 24*3600);
			Else
				If vDetails.IsLeft Then
					vParam.Insert("PeriodFrom", BegOfDay(vDetails.PeriodDate - 24*3600));
					vParam.Insert("PeriodTo", BegOfDay(vDetails.PeriodDate - 24*3600));					
				Else
					vParam.Insert("PeriodFrom", BegOfDay(vDetails.PeriodDate));
					vParam.Insert("PeriodTo", BegOfDay(vDetails.PeriodDate));
				EndIf;
			EndIf;
			vParam.Insert("Status", SelStatus);
			vParam.Insert("AllotmentBusinessType", SelAllotmentBusinessType);
			vParam.Insert("GenerateOnOpen", True);
			OpenForm("Report.RoomQuotaSales.Form.tcReportForm", vParam, , New UUID());
		EndIf;
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelShowReservationsOnChange(pItem)
	GenerateReport();
EndProcedure // SelShowReservationsOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelShowVacantsOnChange(pItem)
	GenerateReport();
EndProcedure // SelShowVacantsOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelShowPreliminaryOnChange(pItem)
	GenerateReport();
EndProcedure // SelShowPreliminaryOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure UseSameGuestGroupOnChange(pItem)
	GuestGroupAppearance();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DurationsOnChange(pItem)
	DurationsOnChangeAtServer();
EndProcedure // DurationsOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PeriodToOnChange(pItem)
	PeriodToOnChangeAtServer();
EndProcedure // PeriodToOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PeriodFromOnChange(pItem)
	PeriodFromOnChangeAtServer();
EndProcedure // PeriodFromOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AccommodationTemplatesOnEditEnd(pItem, pNewRow, pCancelEdit)
	vCurData = Items.AccommodationTemplates.CurrentData;
	If vCurData <> Undefined Then
		vQuantity = vCurData.Quantity;
		
		vNewQuantity = vCurData.Quantity;
		vNewQuantity = ?(vNewQuantity = 0, 1, vNewQuantity);
	
		vCurParent = vCurData.GetParent();
		If vCurParent <> Undefined Then
			vOldQuantity = vCurParent.Quantity;
			vOldQuantity = ?(vOldQuantity = 0, 1, vOldQuantity);
			
			vCurParent.Quantity = vQuantity;
			vCurParent.Amount = Round(vCurParent.Amount / vOldQuantity * vNewQuantity, 2);
			vCurParent.AvgPrice = Round(vCurParent.AvgPrice / vOldQuantity * vNewQuantity, 2);
			
			vChildRows = vCurParent.GetItems();
			For Each vChildRow In vChildRows Do
				vChildRow.Quantity = vQuantity;
				vChildRow.Amount = Round(vChildRow.Amount / vOldQuantity * vNewQuantity, 2);
				vChildRow.AvgPrice = Round(vChildRow.AvgPrice / vOldQuantity * vNewQuantity, 2);
			EndDo;
		Else
			vChildRows = vCurData.GetItems();
			For Each vChildRow In vChildRows Do
				vOldQuantity = vChildRow.Quantity;
				vOldQuantity = ?(vOldQuantity = 0, 1, vOldQuantity);
				Break;
			EndDo;
			
			vCurData.Amount = Round(vCurData.Amount / vOldQuantity * vNewQuantity, 2);
			vCurData.AvgPrice = Round(vCurData.AvgPrice / vOldQuantity * vNewQuantity, 2);
			
			For Each vChildRow In vChildRows Do
				vChildRow.Quantity = vQuantity;
				vChildRow.Amount = Round(vChildRow.Amount / vOldQuantity * vNewQuantity, 2);
				vChildRow.AvgPrice = Round(vChildRow.AvgPrice / vOldQuantity * vNewQuantity, 2);
			EndDo;
		EndIf;
	EndIf;
	
	// Calculate totals
	vShowTotals = False;
	TotalAmount = 0;
	TotalAvgPrice = 0;
	vAccommodationTemplates = AccommodationTemplates.GetItems();
	For Each vAccommodationTemplateRow In vAccommodationTemplates Do
		If vAccommodationTemplateRow.Quantity <> 0 Then
			If TotalAmount <> 0 Then
				vShowTotals = True;
			EndIf;
			
			TotalAmount = TotalAmount + vAccommodationTemplateRow.Amount;
			TotalAvgPrice = TotalAvgPrice + vAccommodationTemplateRow.AvgPrice;
		EndIf;		
	EndDo;
	Items.AccommodationTemplates.Footer = vShowTotals;
EndProcedure // AccommodationTemplatesOnEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRateOnChange(pItem)
	SetPriceTagAppearance();
	// Recalculate templates
	CalculateAtServer();
EndProcedure // RoomRateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelModeOnChange(pItem)
	If SelMode = 0 Then
		Items.GroupPages.CurrentPage = Items.GroupPickup;
	Else
		Items.GroupPages.CurrentPage = Items.GroupAllotmentEdit;
	EndIf;
	GenerateReport();
EndProcedure // SelModeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelPriceOnChange(pItem)
	SetPriceGroupTitleAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelNumberOfAdultsOnChange(pItem)
	SetPriceGroupTitleAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelNumberOfTeenagersOnChange(pItem)
	SetPriceGroupTitleAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelNumberOfChildrenOnChange(pItem)
	SetPriceGroupTitleAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelNumberOfInfantsOnChange(pItem)
	SetPriceGroupTitleAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AllDaysOnChange(pItem)
	For i = 1 To 7 Do
		ThisObject["Day" + i] = AllDays;		
	EndDo;
	SetWeekdaysTitle();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AllDaysOff(pItem)
	AllDays = False;
	If Day1 And Day2 And Day3 And Day4 And Day5 And Day6 And Day7 Then
		AllDays = True;
	EndIf;
	SetWeekdaysTitle();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure EditInventoryOnChange(pItem)
	Items.NumberOfRooms.Enabled = False;
	Items.InventoryEditMode.Enabled = False;
	Items.GroupManualPrice.Enabled = False;
	Items.SetRoomQuotaByPeriod.Enabled = False;
	If EditInventory Then
		Items.NumberOfRooms.Enabled = True;
		Items.InventoryEditMode.Enabled = True;
		Items.SetRoomQuotaByPeriod.Enabled = True;
	EndIf;
	If EditPrice Then
		Items.GroupManualPrice.Enabled = True;
		Items.SetRoomQuotaByPeriod.Enabled = True;
	EndIf;
EndProcedure // EditInventoryOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure EditPriceOnChange(pItem)
	EditInventoryOnChange(pItem);
EndProcedure // EditPriceOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure InventoryEditModeOnChange(pItem)
	If SelMode = 1 And SelShowSelector = 1 Then
		If InventoryEditMode = 0 Then
			InventoryEditMode = 1;
		EndIf;
	EndIf;
EndProcedure // InventoryEditModeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelShowSelectorOnChange(pItem)
	GenerateReport();
EndProcedure // SelShowSelectorOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PriceNumberOfAdultsOnChange(pItem)
	GenerateReport();
EndProcedure // PriceNumberOfAdultsOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomTypesStartChoice(pItem, ChoiceData, pChoiceByAdding, pStandardProcessing)
	pStandardProcessing = False;
	For Each vAllRoomTypesItem In AllRoomTypes Do
		vAllRoomTypesItem.Check = False;
		If SelRoomTypes.FindByValue(vAllRoomTypesItem.Value) <> Undefined Then
			vAllRoomTypesItem.Check = True;
		EndIf;
	EndDo;
	AllRoomTypes.ShowCheckItems(New NotifyDescription("SelRoomTypesChoiceCompleted", ThisObject));
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomTypesChoiceCompleted(pList, pExtraParams) Export
	If pList <> Undefined Then
		SelRoomTypes.Clear();
		For Each vListItem In pList Do
			If vListItem.Check Then
				SelRoomTypes.Add(vListItem.value);
			EndIf;
		EndDo;
		SelRoomTypesOnChangeAtServer();
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomTypesOnChange(pItem)
	SelRoomTypesOnChangeAtServer();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ResetSearchFilter(pCommand)
	ResetSearchFilterAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PrevDate(pCommand)
	PrevDateAtServer();
	DateSwitch = Month(SelPeriodFrom);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure NextDate(pCommand)
	NextDateAtServer();
	DateSwitch = Month(SelPeriodFrom);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AddRooms()
	AddRoomsAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure JoinPeriods(pCommand)
	JoinPeriodsAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure MakePeriodSplittable(pCommand)
	MakePeriodSplittableAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure WriteOffRoomQuota(pCommand)
	vAnswer = NStr("en='Confirm that you want to write off allotment choosen completely!
					|Reply <Yes> to proceed with operation
					|Reply <No> to cancel action';
					|ru='Подтвердите свое намерение полностью обнулить выбранную квоту!
					|Ответ <Да> - означает, что квота будет обнулена
					|Ответ <Нет> - действие будет отменено';
					|de='Bestätigen Sie Ihre Absicht, die gewählte Quote komplett zu nullen! 
					|Antwort <Ja> bedeutet, dass die Quote genullt wird. 
					|Antwort <Nein> bedeuten, dass die Aktion abgebrochen wird.'");
	ShowQueryBox(New NotifyDescription("WriteOffRoomQuotaAnswer", ThisObject), vAnswer, QuestionDialogMode.YesNo, , DialogReturnCode.No);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure WriteOffRoomQuotaByPeriod(pCommand)
	ChangeRoomQuotaByPeriodAtServer(True);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure MoveRoomQuotaRooms(pCommand)
	vList = CheckMoveRoomQuota();
	If vList.Count() > 0 then	
		OpenForm("Catalog.RoomQuotas.Form.tcChoiceForm", New Structure("ChoiceMode, Filter", True, New Structure("Ref", vList)), ThisObject, , , , New NotifyDescription("MoveRoomQuotaRoomsGetQuota", ThisObject));
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RemoveRooms()
	RemoveRoomsAtServer();
EndProcedure // RemoveRooms

// -----------------------------------------------------------------------------
&AtClient
Procedure Refresh(pCommand)
	GenerateReport();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure Calculate(pCommand)
	CalculateAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure NewReservation(pCommand)     
	vKeyOperation = "Document.Reservation.Form.tcDocumentForm.OpenForm";
	vPeriodFrom = GetTime(PeriodFrom, True);
	vPeriodTo = GetTime(PeriodTo, False, True);
	If Items.AccommodationTemplates.CurrentData <> Undefined Then
		vRoomsCount = CheckRoomsNumber();
		If vRoomsCount > 1 Then
			vAddRoomsToAllotment = False;
			vAllotmentBalances = Undefined;
			GuestGroup = CreateGroupRes(vAddRoomsToAllotment, vAllotmentBalances);
			If ValueIsFilled(GuestGroup) Then
				OpenForm("Catalog.GuestGroups.Form.tcItemForm", New Structure("Key", GuestGroup));
			EndIf;
		 	If vAddRoomsToAllotment Then
				ShowQueryBox(New NotifyDescription("AddRoomsToAllotment", ThisObject, New Structure("AllotmentBalances", vAllotmentBalances)), 
							 NStr("en='Add missing rooms to the allotment?'; ru='Добавить недостающие номера в квоту?'; de='Fehlende Zimmer zum Allotment hinzufügen?'"), 
							 QuestionDialogMode.YesNo, , DialogReturnCode.No);
			EndIf;
		ElsIf vRoomsCount > 0 Then
			vAccommodationTemplates = AccommodationTemplates.GetItems();
			For Each vAccommodationTemplateRow In vAccommodationTemplates Do
				If vAccommodationTemplateRow.Quantity > 0 Then
					// APDEX
					APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

					vAccommodationTemplate = vAccommodationTemplateRow.AccommodationTemplate;
					OpenForm("Document.Reservation.Form.tcDocumentForm", New Structure("Hotel, CheckInDate, CheckOutDate, RoomQuota, RoomType, RoomRate, ClientType, Event, GuestGroup, Template, SourceOfBusiness, MarketingCode, ClientType, TripPurpose", 
					                                                                   SelHotel, vPeriodFrom, vPeriodTo, RoomQuota, RoomType, RoomRate, ClientType, Event, ?(UseSameGuestGroup, GuestGroup, Undefined), vAccommodationTemplate, 
																					   ?(ValueIsFilled(RoomQuota), tcOnServer.cmGetAttributeByRef(RoomQuota, "SourceOfBusiness"), Undefined), 
																					   ?(ValueIsFilled(RoomQuota), tcOnServer.cmGetAttributeByRef(RoomQuota, "MarketingCode"), Undefined), 
																					   ?(ValueIsFilled(RoomQuota), tcOnServer.cmGetAttributeByRef(RoomQuota, "ClientType"), Undefined), 
																					   ?(ValueIsFilled(RoomQuota), tcOnServer.cmGetAttributeByRef(RoomQuota, "TripPurpose"), Undefined), 
					                                                                  ), 
					         ThisObject);
					Break;
				EndIf;
			EndDo; 
		Else
			// APDEX
			APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

			vAccommodationTemplate = Items.AccommodationTemplates.CurrentData.AccommodationTemplate;
			OpenForm("Document.Reservation.Form.tcDocumentForm", New Structure("Hotel, CheckInDate, CheckOutDate, RoomQuota, RoomType, RoomRate, ClientType, Event, GuestGroup, Template, SourceOfBusiness, MarketingCode, ClientType, TripPurpose", 
			                                                                   SelHotel, vPeriodFrom, vPeriodTo, RoomQuota, RoomType, RoomRate, ClientType, Event, ?(UseSameGuestGroup, GuestGroup, Undefined), vAccommodationTemplate, 
			                                                                   ?(ValueIsFilled(RoomQuota), tcOnServer.cmGetAttributeByRef(RoomQuota, "SourceOfBusiness"), Undefined), 
			                                                                   ?(ValueIsFilled(RoomQuota), tcOnServer.cmGetAttributeByRef(RoomQuota, "MarketingCode"), Undefined), 
			                                                                   ?(ValueIsFilled(RoomQuota), tcOnServer.cmGetAttributeByRef(RoomQuota, "ClientType"), Undefined), 
			                                                                   ?(ValueIsFilled(RoomQuota), tcOnServer.cmGetAttributeByRef(RoomQuota, "TripPurpose"), Undefined), 
			                                                                  ), 
			         ThisObject);
		EndIf;
	Else
		// APDEX
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

		OpenForm("Document.Reservation.Form.tcDocumentForm", New Structure("Hotel, CheckInDate, CheckOutDate, RoomQuota, RoomType, RoomRate, ClientType, Event, GuestGroup, SourceOfBusiness, MarketingCode, ClientType, TripPurpose", 
		                                                                   SelHotel, vPeriodFrom, vPeriodTo, RoomQuota, RoomType, RoomRate, ClientType, Event, ?(UseSameGuestGroup, GuestGroup, Undefined), 
			                                                               ?(ValueIsFilled(RoomQuota), tcOnServer.cmGetAttributeByRef(RoomQuota, "SourceOfBusiness"), Undefined), 
			                                                               ?(ValueIsFilled(RoomQuota), tcOnServer.cmGetAttributeByRef(RoomQuota, "MarketingCode"), Undefined), 
			                                                               ?(ValueIsFilled(RoomQuota), tcOnServer.cmGetAttributeByRef(RoomQuota, "ClientType"), Undefined), 
			                                                               ?(ValueIsFilled(RoomQuota), tcOnServer.cmGetAttributeByRef(RoomQuota, "TripPurpose"), Undefined), 
		                                                                  ), 
		         ThisObject);
	EndIf;
EndProcedure // NewReservation

// -----------------------------------------------------------------------------
&AtClient
Procedure SetRoomQuotaByPeriod(pCommand)
	If EditPrice And SelNumberOfAdults = 0 And SelNumberOfTeenagers = 0 And SelNumberOfChildren = 0 And SelNumberOfInfants = 0 Then
		ShowMessageBox(, NStr("en='Fill the number of persons in the room for the price!'; ru='Укажите кол-во гостей в номере для цены!'; de='Zur Preisberechnung bitte die Anzahl der Gäste im Zimmer angeben!'"));
		Return;
	EndIf;
	If EditInventory And InventoryEditMode = 0 Or 
	   EditPrice And Not EditInventory Then
		ChangeRoomQuotaByPeriodAtServer(False);
	ElsIf EditInventory And InventoryEditMode = 1 Then
		AddRooms();
	ElsIf EditInventory And InventoryEditMode = 2 Then
		RemoveRooms();
	EndIf;
	If ValueIsFilled(RoomQuota) Then
		Notify("Catalog.RoomQuotas.Changed", RoomQuota, ThisObject);
	EndIf;
	ShowMessageBox(, NStr("en='Done!'; ru='Выполнено!'; de='Fertig!'"), 1);
EndProcedure

#EndRegion

#Region Private

// ----------------------------------------------------------------------------
&AtClient
Procedure AddRoomsToAllotment(pUA, pExtraParams) Export
	If pUA = DialogReturnCode.Yes Then
		vMessage = "";
		If AddRoomsToAllotmentAtServer(pExtraParams.AllotmentBalances, vMessage) Then
			ShowMessageBox(, NStr("en='Success!'; ru='Успешно!'; de='Erfolgreich!'"));
		Else
			ShowMessageBox(, NStr("en='Failed to add rooms to the allotment! Error is: '; ru='Не удалось добавить номера в квоту! Ошибка: '; de='Zimmer konnten dem Kontingent nicht hinzugefügt werden! Fehler ist: '") + vMessage, , NStr("en='Error!'; ru='Ошибка!'; de='Fehler!'"));
		EndIf;
	EndIf;
EndProcedure // AddRoomsToAllotment

// ----------------------------------------------------------------------------
&AtServer
Function AddRoomsToAllotmentAtServer(pAllotmentBalancesArray, rMessage)
	vSuccess = True;
	rMessage = "";
	Try
		BeginTransaction(DataLockControlMode.Managed);
		For Each vAllotmentBalancesStruct In pAllotmentBalancesArray Do
			If vAllotmentBalancesStruct.RoomsRemains < 0 Then
				cmAddRoomsToAllotment(vAllotmentBalancesStruct.RoomQuota, vAllotmentBalancesStruct.RoomRate, vAllotmentBalancesStruct.RoomType, vAllotmentBalancesStruct.PeriodFrom, vAllotmentBalancesStruct.PeriodTo, -vAllotmentBalancesStruct.RoomsRemains);
			EndIf;
		EndDo;
		CommitTransaction();
	Except
		rMessage = cmGetRootErrorDescription(ErrorInfo());
		vSuccess = False;
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
	EndTry;
	Return vSuccess;
EndFunction // AddRoomsToAllotmentAtServer

// -----------------------------------------------------------------------------
&AtServer  
Procedure GenerateReport(pGroupingStr = Undefined) Export
	If SelMode > 0 Then
		Items.SelShowReservations.Enabled = False;
		Items.SelShowReservations.Visible = False;
		Items.SelShowFreeSaleOnly.Enabled = False;
		Items.SelShowVacantOnly.Enabled = False;
		Items.MakePeriodSplittable.Enabled = False;
		Items.JoinPeriods.Enabled = False;
		Items.GroupPickup.Visible = False;
	Else
		Items.SelShowReservations.Enabled = True;
		Items.SelShowReservations.Visible = True;
		Items.SelShowFreeSaleOnly.Enabled = True;
		Items.SelShowVacantOnly.Enabled = True;
		Items.MakePeriodSplittable.Enabled = True;
		Items.JoinPeriods.Enabled = True;
		Items.GroupPickup.Visible = True;
	EndIf;
	If SelMode = 1 Then
		FillShowSelectorGroupTitle();
		Items.GroupTotalsShowSelector.Visible = True;
	Else
		Items.GroupTotalsShowSelector.Visible = False;
	EndIf;
	If SelMode > 0 Then
		Items.GroupPickupShowSelector.Visible = False;
		Items.MakePeriodSplittable.Enabled = False;
		Items.JoinPeriods.Enabled = False;
	Else
		Items.GroupPickupShowSelector.Visible = True;
		Items.MakePeriodSplittable.Enabled = True;
		Items.JoinPeriods.Enabled = True;
	EndIf;
	// Save current mode
	SystemSettingsStorage.Save("tcAllotmentVacantRoomsMode", SessionParameters.CurrentUser, SelMode);
	// Some initialisation
	StopNotificationProcessing = False;
	WeekendsPatternColor = WebColors.Gainsboro;
	EventBackColor = tcCommonFunctionOnClientServer.ColorConstructor(240, 240, 240);	
	// Check parameters
	If Not ValueIsFilled(SelHotel) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Hotel should be set!'; de = 'Das Hotel ist nicht angegeben!'; ru = 'Не указана гостиница!'"));
		Return;
	EndIf;
	If Not ValueIsFilled(SelPeriodFrom) Or Not ValueIsFilled(SelPeriodTo) Or 
		ValueIsFilled(SelPeriodTo) And ValueIsFilled(SelPeriodFrom) And BegOfDay(SelPeriodTo) < BegOfDay(SelPeriodFrom) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Period is wrong!'; de = 'Der Zeitraum ist falsch angegeben!'; ru = 'Период указан не верно!'"));
		Return;
	EndIf;
	
	// Reservation color
	ReservationColor = tcCommonFunctionOnClientServer.ColorConstructor(200, 220, 255);
	If ValueIsFilled(SelHotel) Then
		vReservationColor = SelHotel.ReservationColor.Get();
		If vReservationColor <> Undefined Then
			ReservationColor = vReservationColor;
		EndIf;
	EndIf;
	
	// Accommodation color
	AccommodationColor = tcCommonFunctionOnClientServer.ColorConstructor(144, 238, 144);
	If ValueIsFilled(SelHotel) Then
		vAccommodationColor = SelHotel.CheckInColor.Get();
		If vAccommodationColor <> Undefined Then
			AccommodationColor = vAccommodationColor;
		EndIf;
	EndIf;
	
	// In rooms or in beds?
	InRooms = True;
	If ValueIsFilled(SessionParameters.CurrentHotel) Then
		If SessionParameters.CurrentHotel.ShowReportsInBeds Then
			InRooms = False;
		EndIf;
	EndIf;
	
	// Clear spreadsheet
	vSpreadsheet = ReportSpreadsheet;
	vSpreadsheet.Clear();
	
	LastSelectedRange = Undefined;
	LastSelectedRangeText.Clear();
	
	// Build filter description
	BuildFilterDescription();
	
	// Check form mode
	If SelMode = 0 Then
		GeneratePickup(vSpreadsheet, pGroupingStr);
	Else
		GenerateTotals(vSpreadsheet, pGroupingStr);
	EndIf;
	
	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Landscape);
	
	// Set report protection
	cmSetSpreadsheetProtection(vSpreadsheet);
	
	// Set report header and footer
	cmApplyReportHeader(vSpreadsheet);
	cmApplyReportFooter(vSpreadsheet);
	
	// Set is collapsed
	IsCollapsed = True;
EndProcedure // GenerateReport

// -----------------------------------------------------------------------------
&AtServer  
Procedure GeneratePickup(vSpreadsheet, pGroupingStr = Undefined)
	// Retrieve room types with balances
	vTempTablesManager = New TempTablesManager();
	
	vRoomTypeQryTbl = GetRoomTypePeriodsBalances(vTempTablesManager);
	
	vRoomTypeQryTblByDates = vRoomTypeQryTbl.Copy();
	vRoomTypeQryTblByDates.GroupBy("PeriodDate");
	vRoomTypeQryTblByDates.Sort("PeriodDate");
	
	vRoomTypeQryTblByHotels = vRoomTypeQryTbl.Copy();
	vRoomTypeQryTblByHotels.GroupBy("Hotel, HotelSortCode, HotelDescription");
	vRoomTypeQryTblByHotels.Sort("HotelSortCode, HotelDescription");
	
	vRoomTypeQryTblByHotelsAndDates = vRoomTypeQryTbl.Copy();
	vRoomTypeQryTblByHotelsAndDates.GroupBy("Hotel, HotelSortCode, HotelDescription, PeriodDate", "RoomsVacant, BedsVacant, SpecialRoomsVacant, SpecialBedsVacant, RoomsInQuota, BedsInQuota, RoomsRemains, BedsRemains, TotalRooms, TotalBeds, TotalSpecialRooms, TotalSpecialBeds, RoomsBlocked, BedsBlocked");
	vRoomTypeQryTblByHotelsAndDates.Sort("HotelSortCode, HotelDescription, PeriodDate");
	
	vRoomTypeQryTblByHotelsAndRoomTypes = vRoomTypeQryTbl.Copy();
	vRoomTypeQryTblByHotelsAndRoomTypes.GroupBy("Hotel, HotelSortCode, HotelDescription, RoomType, RoomTypeSortCode, RoomTypeDescription", "RoomsVacant, BedsVacant, SpecialRoomsVacant, SpecialBedsVacant, RoomsInQuota, BedsInQuota, RoomsRemains, BedsRemains");
	vRoomTypeQryTblByHotelsAndRoomTypes.Sort("HotelSortCode, HotelDescription, RoomTypeSortCode, RoomTypeDescription");
	
	vRoomTypeQryTblByRoomTypesAndDates = vRoomTypeQryTbl.Copy();
	vRoomTypeQryTblByRoomTypesAndDates.GroupBy("Hotel, HotelSortCode, HotelDescription, RoomType, RoomTypeSortCode, RoomTypeDescription, PeriodDate", "RoomsVacant, BedsVacant, SpecialRoomsVacant, SpecialBedsVacant, RoomsInQuota, BedsInQuota, RoomsRemains, BedsRemains, TotalRooms, TotalBeds, TotalSpecialRooms, TotalSpecialBeds, RoomsBlocked, BedsBlocked");
	vRoomTypeQryTblByRoomTypesAndDates.Sort("HotelSortCode, HotelDescription, RoomTypeSortCode, RoomTypeDescription, PeriodDate");
	
	// Retrieve vacant combinations only
	If SelShowVacantOnly Then
		vVacantCombinations = GetVacantCombinations(vTempTablesManager);
	EndIf;
	
	// Retrieve check-in periods with balances
	vQryResTbl = GetCheckInPeriodsBalances(vTempTablesManager);

	vTempTablesManager.Close();
	
	vQryResTblByRoomTypesAndAllotments = vQryResTbl.Copy();
	vQryResTblByRoomTypesAndAllotments.GroupBy("Hotel, HotelSortCode, HotelDescription, RoomType, RoomTypeSortCode, RoomTypeDescription, RoomQuota, RoomQuotaSortCode, RoomQuotaDescription", );
	vQryResTblByRoomTypesAndAllotments.Sort("HotelSortCode, HotelDescription, RoomTypeSortCode, RoomTypeDescription, RoomQuotaSortCode, RoomQuotaDescription");
	
	vQryResTblByAllotmentsAndDurations = vQryResTbl.Copy();
	vQryResTblByAllotmentsAndDurations.GroupBy("Hotel, HotelSortCode, HotelDescription, RoomType, RoomTypeSortCode, RoomTypeDescription, RoomQuota, RoomQuotaSortCode, RoomQuotaDescription, Duration", );
	vQryResTblByAllotmentsAndDurations.Sort("HotelSortCode, HotelDescription, RoomTypeSortCode, RoomTypeDescription, RoomQuotaSortCode, RoomQuotaDescription, Duration");
	
	vQryResTblByAllotmentsAndDates = vQryResTbl.Copy();
	vQryResTblByAllotmentsAndDates.GroupBy("Hotel, HotelSortCode, HotelDescription, RoomType, RoomTypeSortCode, RoomTypeDescription, RoomQuota, RoomQuotaSortCode, RoomQuotaDescription, PeriodDate", "RoomsVacant, BedsVacant, SpecialRoomsVacant, SpecialBedsVacant, RoomsRemains, BedsRemains, RoomsInQuota, BedsInQuota");
	vQryResTblByAllotmentsAndDates.Sort("HotelSortCode, HotelDescription, RoomTypeSortCode, RoomTypeDescription, RoomQuotaSortCode, RoomQuotaDescription, PeriodDate");
	
	vQryResTblByCheckInPeriods = vQryResTbl.Copy();
	vQryResTblByCheckInPeriods.GroupBy("Hotel, HotelSortCode, HotelDescription, RoomType, RoomTypeSortCode, RoomTypeDescription, RoomQuota, RoomQuotaSortCode, RoomQuotaDescription, CheckInDate, Duration, CheckOutDate, PeriodDate", "RoomsVacant, BedsVacant, SpecialRoomsVacant, SpecialBedsVacant, RoomsRemains, BedsRemains");
	vQryResTblByCheckInPeriods.Sort("HotelSortCode, HotelDescription, RoomTypeSortCode, RoomTypeDescription, RoomQuotaSortCode, RoomQuotaDescription, CheckInDate, CheckOutDate, PeriodDate");
	
	// Read reservations
	If SelShowReservations Then
		vReservations = GetReservations();
		vMappedDocs = MapReservations(vReservations, vRoomTypeQryTblByDates);
	EndIf;
	
	// Initialize working storage value lists
	vCheckInPeriodLineNumbers = New ValueList();
	
	// Get report template
	vTemplate = Catalogs.RoomQuotas.GetTemplate("AllotmentVacantRooms");
	
	// Print report name
	vArea = vTemplate.GetArea("Report");
	If InRooms Then
		vArea.Parameters.mReportName = NStr("en='Vacant rooms by allotment'; ru='Свободные номера по квотам'; de='Freie Zimmer nach Allotment'");
	Else
		vArea.Parameters.mReportName = NStr("en='Vacant beds by allotment'; ru='Свободные места по квотам'; de='Freie Betten nach Allotment'");
	EndIf;
	vSpreadsheet.Put(vArea);
	
	// Filter
	vArea = vTemplate.GetArea("Filter");
	vArea.Parameters.mFilter = NStr("en = 'Filter: '; de = 'Auswahl: '; ru = 'Отбор: '") + GetReportParametersPresentation();
	vSpreadsheet.Put(vArea);
	
	// Draw report table header
	vHPArea = vTemplate.GetArea("Header|Duration");
	vSpreadsheet.Put(vHPArea);
	vHDArea = vTemplate.GetArea("Header|Date");
	For Each vQryByDates In vRoomTypeQryTblByDates Do
		If vQryByDates.PeriodDate < SelPeriodFrom Or vQryByDates.PeriodDate > SelPeriodTo Then
			Continue;
		EndIf;
		vHDArea.Parameters.mPeriodDate = Format(vQryByDates.PeriodDate, "DF='dd.MM'") + " " + cmGetDayOfWeekName(WeekDay(vQryByDates.PeriodDate), True);
		vSpreadsheet.Join(vHDArea);
	EndDo;		
	
	// Get template areas
	vHTPArea = vTemplate.GetArea("Hotel|Duration");
	vHTDArea = vTemplate.GetArea("Hotel|Date");
	vRTPArea = vTemplate.GetArea("RoomType|Duration");
	vRTDArea = vTemplate.GetArea("RoomType|Date");
	vPRPArea = vTemplate.GetArea("CheckInPeriod|Duration");
	vPRDArea = vTemplate.GetArea("CheckInPeriod|Date");
	vPRLRArea = vTemplate.GetArea("CheckInPeriod|LeftRight");
	vPRLArea = vTemplate.GetArea("CheckInPeriod|Left");
	vPRRArea = vTemplate.GetArea("CheckInPeriod|Right");
	vPRMArea = vTemplate.GetArea("CheckInPeriod|Middle");
	vATLArea = vTemplate.GetArea("AllotmentTotal|Duration");
	vATDArea = vTemplate.GetArea("AllotmentTotal|Date");
	vRCOArea = vTemplate.GetArea("RoomCounter|Duration");
	vRCLRArea = vTemplate.GetArea("RoomCounter|LeftRight");
	vRCLArea = vTemplate.GetArea("RoomCounter|Left");
	vRCRArea = vTemplate.GetArea("RoomCounter|Right");
	vRCMArea = vTemplate.GetArea("RoomCounter|Middle");
	vRCDArea = vTemplate.GetArea("RoomCounter|Date");
	vEVTArea = vTemplate.GetArea("Events|Duration");
	vEVDArea = vTemplate.GetArea("Events|Date");
	vOPTArea = vTemplate.GetArea("OccupancyPercent|Duration");
	vOPDArea = vTemplate.GetArea("OccupancyPercent|Date");
	
	// Create working table
	vPeriodResources = New ValueTable();
	vPeriodResources.Columns.Add("CheckInDate", cmGetDateTimeTypeDescription());
	vPeriodResources.Columns.Add("Duration", cmGetNumberTypeDescription(17, 0));
	vPeriodResources.Columns.Add("CheckOutDate", cmGetDateTimeTypeDescription());
	vPeriodResources.Columns.Add("PeriodDate", cmGetDateTimeTypeDescription());
	vPeriodResources.Columns.Add("PeriodVacant", cmGetNumberTypeDescription(17, 0));
	vPeriodResources.Columns.Add("PeriodRemains", cmGetNumberTypeDescription(17, 0));
	
	// By hotels
	HeaderHeight = 6;
	For Each vQryHotels In vRoomTypeQryTblByHotels Do
		vCurHotel = vQryHotels.Hotel;
		If Not ValueIsFilled(vCurHotel) Then
			Continue;
		EndIf;
		
		// In beds or in rooms
		vInBeds = vCurHotel.ShowReportsInBeds;
		// Show zeroes
		vShowZeroes = vCurHotel.ShowZeroesInAvailability;
		
		// Get number of rooms/beds per hotel for first period date
		vTotalRoomsBeds = 0;
		vHotelFirstDateRows = vRoomTypeQryTblByHotelsAndDates.FindRows(New Structure("Hotel, PeriodDate", vCurHotel, BegOfDay(SelPeriodFrom)));
		If vHotelFirstDateRows.Count() > 0 Then
			vHotelFirstDateRow = vHotelFirstDateRows.Get(0);
			vTotalRoomsBeds = ?(vInBeds, vHotelFirstDateRow.TotalBeds, vHotelFirstDateRow.TotalRooms);
		EndIf;
		
		// Fill hotel name
		vHTPArea.Parameters.mHotelStr = "" + vCurHotel + ?(vTotalRoomsBeds > 0, Chars.LF + Chars.Tab + Chars.Tab + Chars.Tab + Chars.Tab + Chars.Tab + Chars.Tab + Chars.Tab + "(" + vTotalRoomsBeds + ")", "");
		vHTPArea.Parameters.mHotel = vCurHotel;
		vSpreadsheet.StartRowGroup(NStr("en='Hotel';ru='Гостиница';de='Hotel'"), False);
		vSpreadsheet.Put(vHTPArea);
		vSpreadsheet.EndRowGroup();
		// Iterate thru dates
		vQryHotelByDatesArray = vRoomTypeQryTblByHotelsAndDates.FindRows(New Structure("Hotel", vCurHotel));
		For Each vRoomTypeQryHotelByDates In vQryHotelByDatesArray Do
			If vRoomTypeQryHotelByDates.PeriodDate < SelPeriodFrom Or vRoomTypeQryHotelByDates.PeriodDate > SelPeriodTo Then
				Continue;
			EndIf;
			vOverbooking = False;
			If vInBeds Then
				vHTDArea.Parameters.mDateRemains = Format(vRoomTypeQryHotelByDates.BedsRemains, "NFD=0; NG=" + ?(vShowZeroes, "; NZ=", ""));
				vHTDArea.Parameters.mDateVacant = Format(vRoomTypeQryHotelByDates.BedsVacant - vRoomTypeQryHotelByDates.SpecialBedsVacant, "NFD=0; NG=" + ?(vShowZeroes, "; NZ=", ""));
				If (vRoomTypeQryHotelByDates.BedsVacant - vRoomTypeQryHotelByDates.SpecialBedsVacant) < 0 Then
					vOverbooking = True;
				EndIf;
			Else
				vHTDArea.Parameters.mDateRemains = Format(vRoomTypeQryHotelByDates.RoomsRemains, "NFD=0; NG=" + ?(vShowZeroes, "; NZ=", ""));
				vHTDArea.Parameters.mDateVacant = Format(vRoomTypeQryHotelByDates.RoomsVacant - vRoomTypeQryHotelByDates.SpecialRoomsVacant, "NFD=0; NG=" + ?(vShowZeroes, "; NZ=", ""));
				If (vRoomTypeQryHotelByDates.RoomsVacant - vRoomTypeQryHotelByDates.SpecialRoomsVacant) < 0 Then
					vOverbooking = True;
				EndIf;
			EndIf;
			FillDateDetails(vHTDArea, vRoomTypeQryHotelByDates.Hotel, Undefined, Undefined, EndOfDay(vRoomTypeQryHotelByDates.PeriodDate));
			vHotelDateArea = vSpreadsheet.Join(vHTDArea);
			If vOverbooking Then
				vColorArea = vSpreadsheet.Area(vHotelDateArea.Bottom, vHotelDateArea.Left, vHotelDateArea.Bottom, vHotelDateArea.Right);
				vColorArea.TextColor = WebColors.Red;
			EndIf;
		EndDo;
		
		// Print events
		vEvents = cmGetEvents(SelPeriodFrom, SelPeriodTo, vCurHotel);
		If vEvents.Count() > 0 Then
			HeaderHeight = 7;
			vCommentIsPlaced = False;
			vEventsRow = Undefined;
			vSpreadsheet.Put(vEVTArea);
			For Each vRoomTypeQryHotelByDates In vQryHotelByDatesArray Do
				If vRoomTypeQryHotelByDates.PeriodDate < SelPeriodFrom Or vRoomTypeQryHotelByDates.PeriodDate > SelPeriodTo Then
					Continue;
				EndIf;
				
				// Try to find event starting from this date
				vThisIsFirstPeriodOfEvent = False;
				vProbeEventsRow = vEvents.Find(vRoomTypeQryHotelByDates.PeriodDate, "DateFrom");
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
				
				vEventArea = vSpreadsheet.Join(vEVDArea);
				
				vIsEventDate = False;
				If vEventsRow <> Undefined Then
					If vRoomTypeQryHotelByDates.PeriodDate > vEventsRow.DateTo Or vRoomTypeQryHotelByDates.PeriodDate < vEventsRow.DateFrom Then
						vEventsRow = Undefined;
					Else
						vIsEventDate = True;
					EndIf;
				EndIf;
				If vEventsRow <> Undefined And vIsEventDate Then
					If vThisIsFirstPeriodOfEvent Then
						vSpreadsheet.Area(vEventArea.Top, vEventArea.Left).Text = TrimAll(vEventsRow.Description);
					EndIf;
					If vEventsRow.DateTo = vRoomTypeQryHotelByDates.PeriodDate And Not vCommentIsPlaced Then
						vCommentIsPlaced = True;
						vSpreadsheet.Area(vEventArea.Top, vEventArea.Right).Comment.Text = Chars.LF + Chars.LF + TrimAll(Format(vEventsRow.DateFrom, "DF=dd.MM.yyyy") + " - " + Format(vEventsRow.DateTo, "DF=dd.MM.yyyy") + Chars.LF +
						TrimAll(vEventsRow.Remarks));
					EndIf;
					vEventArea.Details = vEventsRow.Ref;
					vEventArea.TextPlacement = SpreadsheetDocumentTextPlacementType.Auto;
					vEventArea.BySelectedColumns = True;
					vEventArea.HorizontalAlign = HorizontalAlign.Left;
					vEventArea.VerticalAlign = VerticalAlign.Center;
					vEventColor = Undefined;
					If vEventsRow.Color <> Undefined Then
						vEventColor = vEventsRow.Color.Get();
					EndIf;
					vEventBackColor = EventBackColor;
					If vEventColor <> Undefined Then
						vEventBackColor = vEventColor;
					EndIf;
					vEventArea.BackColor = vEventBackColor;
					vEventArea.LeftBorder = New Line(SpreadsheetDocumentCellLineType.None, 1);
					If vEventsRow.DateTo > vRoomTypeQryHotelByDates.PeriodDate Then
						vEventArea.RightBorder = New Line(SpreadsheetDocumentCellLineType.None, 1);
					EndIf;
					If Not vThisIsFirstPeriodOfEvent Then
						vEventArea.Clear(True);
					EndIf;
				ElsIf Not vIsEventDate Then
					vEventArea.Text = " ";
					vEventArea.Details = Catalogs.Events.EmptyRef();
				EndIf;
			EndDo;
		EndIf;
		
		// By room types
		vQryRoomTypesArray = vRoomTypeQryTblByHotelsAndRoomTypes.FindRows(New Structure("Hotel", vCurHotel));
		For Each vQryRoomTypes In vQryRoomTypesArray Do
			If Not ValueIsFilled(vQryRoomTypes.RoomType) Then
				Continue;
			EndIf;
			
			// By room rates and allotments
			vQryAllotmentsArray = vQryResTblByRoomTypesAndAllotments.FindRows(New Structure("RoomType", vQryRoomTypes.RoomType));
			If vQryAllotmentsArray.Count() = 0 Then
				Continue;
			EndIf;
			If SelShowVacantOnly Then
				vVacantCombinationRows = vVacantCombinations.FindRows(New Structure("RoomType", vQryRoomTypes.RoomType));
				If vVacantCombinationRows.Count() = 0 Then
					Continue;
				EndIf;
			EndIf;
			// Get number of rooms/beds per room type for first period date
			vTotalRoomsBeds = 0;
			vRoomTypeFirstDateRows = vRoomTypeQryTblByRoomTypesAndDates.FindRows(New Structure("RoomType, PeriodDate", vQryRoomTypes.RoomType, BegOfDay(SelPeriodFrom)));
			If vRoomTypeFirstDateRows.Count() > 0 Then
				vRoomTypeFirstDateRow = vRoomTypeFirstDateRows.Get(0);
				vRoomTypeFirstDateRowRoomType = vRoomTypeFirstDateRow.RoomType;
				If ValueIsFilled(vRoomTypeFirstDateRowRoomType) And Not vRoomTypeFirstDateRowRoomType.IsFolder And vRoomTypeFirstDateRowRoomType.DoesNotAffectRoomRevenueStatistics Then
					vTotalRoomsBeds = ?(vInBeds, vRoomTypeFirstDateRow.TotalSpecialBeds, vRoomTypeFirstDateRow.TotalSpecialRooms);
				Else
					vTotalRoomsBeds = ?(vInBeds, vRoomTypeFirstDateRow.TotalBeds, vRoomTypeFirstDateRow.TotalRooms);
				EndIf;
			EndIf;
			// Fill paramters and put room type header
			vRTPArea.Parameters.mRoomTypeStr = "" + vQryRoomTypes.RoomType + ?(vTotalRoomsBeds > 0, Chars.LF + Chars.Tab + Chars.Tab + Chars.Tab + Chars.Tab + Chars.Tab + Chars.Tab + Chars.Tab + "(" + vTotalRoomsBeds + ")", "");
			vRTPArea.Parameters.mRoomType = vQryRoomTypes.RoomType;
			vSpreadsheet.Put(vRTPArea);
			vSpreadsheet.StartRowGroup(NStr("en='Room type';ru='Тип номера';de='Zimmertyp'"), GetInitialOpenState(False, pGroupingStr, vQryRoomTypes.Hotel, vQryRoomTypes.RoomType));
			vRowRoomType = vQryRoomTypes.RoomType;
			vRoomTypeIsFolder = vRowRoomType.IsFolder;
			// Iterate thru dates
			vQryRoomTypeByDatesArray = vRoomTypeQryTblByRoomTypesAndDates.FindRows(New Structure("RoomType", vQryRoomTypes.RoomType));
			For Each vQryRoomTypeByDates In vQryRoomTypeByDatesArray Do
				If vQryRoomTypeByDates.PeriodDate < SelPeriodFrom Or vQryRoomTypeByDates.PeriodDate > SelPeriodTo Then
					Continue;
				EndIf;
				vOverbooking = False;
				If vInBeds Then
					vRTDArea.Parameters.mDateRemains = Format(vQryRoomTypeByDates.BedsRemains, "NFD=0; NG=" + ?(vShowZeroes, "; NZ=", ""));
					vRTDArea.Parameters.mDateVacant = Format(vQryRoomTypeByDates.BedsVacant, "NFD=0; NG=" + ?(vShowZeroes, "; NZ=", ""));
					If vQryRoomTypeByDates.BedsVacant < 0 Then
						vOverbooking = True;
					EndIf;
				Else
					vRTDArea.Parameters.mDateRemains = Format(vQryRoomTypeByDates.RoomsRemains, "NFD=0; NG=" + ?(vShowZeroes, "; NZ=", ""));
					vRTDArea.Parameters.mDateVacant = Format(vQryRoomTypeByDates.RoomsVacant, "NFD=0; NG=" + ?(vShowZeroes, "; NZ=", ""));
					If vQryRoomTypeByDates.RoomsVacant < 0 Then
						vOverbooking = True;
					EndIf;
				EndIf;
				FillDateDetails(vRTDArea, vCurHotel, vQryRoomTypeByDates.RoomType, Undefined, EndOfDay(vQryRoomTypeByDates.PeriodDate));
				
				vRowRoomTypeArea = vSpreadsheet.Join(vRTDArea);
				If vOverbooking Then
					vColorArea = vSpreadsheet.Area(vRowRoomTypeArea.Bottom, vRowRoomTypeArea.Left, vRowRoomTypeArea.Bottom, vRowRoomTypeArea.Right);
					vColorArea.TextColor = WebColors.Red;
				EndIf;
				
				// Check room type stop sale
				vStopSaleRemarks = "";
				If Not vRoomTypeIsFolder Then
					If vRowRoomType.StopSale Then
						If cmIsStopSalePeriod(vRowRoomType, EndOfDay(vQryRoomTypeByDates.PeriodDate), EndOfDay(vQryRoomTypeByDates.PeriodDate), vStopSaleRemarks) Then
							vColorArea = vSpreadsheet.Area(vRowRoomTypeArea.Bottom, vRowRoomTypeArea.Left, vRowRoomTypeArea.Bottom, vRowRoomTypeArea.Right);
							vColorArea.TextColor = WebColors.Red;
							vCommentsArea = vSpreadsheet.Area(vRowRoomTypeArea.Bottom, vRowRoomTypeArea.Right, vRowRoomTypeArea.Bottom, vRowRoomTypeArea.Right);
							vCommentsArea.Comment.Text = vStopSaleRemarks;
						EndIf;
					EndIf;
				EndIf;
			EndDo;
			
			// Iterate through allotments
			For Each vQryAllotments In vQryAllotmentsArray Do
				If SelRoomQuotas.Count() > 0 And ValueIsFilled(SelRoomQuotas.Get(0).Value) And Not ValueIsFilled(vQryAllotments.RoomQuota) Then
					Continue;
				EndIf;
				If SelShowVacantOnly Then
					vVacantCombinationRows = vVacantCombinations.FindRows(New Structure("RoomType, RoomQuota", vQryAllotments.RoomType, vQryAllotments.RoomQuota));
					If vVacantCombinationRows.Count() = 0 Then
						Continue;
					EndIf;
				EndIf;
				If ValueIsFilled(vQryAllotments.RoomQuota) Then
					If SelShowFreeSaleOnly Then
						Continue;
					EndIf;
				EndIf;
				
				// By durations
				vDurations = "";
				vQryDurationsArray = vQryResTblByAllotmentsAndDurations.FindRows(New Structure("RoomType, RoomQuota", vQryAllotments.RoomType, vQryAllotments.RoomQuota));
				For Each vQryDurations In vQryDurationsArray Do
					If IsBlankString(vDurations) Then
						vDurations = Format(vQryDurations.Duration, "ND=6; NFD=0; NG=");
					Else
						vDurations = vDurations + "," + Format(vQryDurations.Duration, "ND=6; NFD=0; NG=");
					EndIf;
				EndDo;
				vPRPArea.Parameters.mDuration = vDurations;
				vPRPArea.Parameters.mRoomQuota = vQryAllotments.RoomQuota;
				If ValueIsFilled(vQryAllotments.RoomQuota) Then
					vPRPArea.Parameters.mRoomQuotaObj = vQryAllotments.RoomQuota.Ref;
				EndIf;
				vArea = vSpreadsheet.Put(vPRPArea);
				If ValueIsFilled(vQryAllotments.RoomQuota) And Not vQryAllotments.RoomQuota.IsForCheckInPeriods Then
					vAllotmentNameArea = vSpreadsheet.Area(vArea.Top, vArea.Left + 1, vArea.Bottom, vArea.Right);
					vAllotmentNameArea.Merge();
					vAllotmentNameArea.BottomBorder = New Line(SpreadsheetDocumentCellLineType.None);
				EndIf;
				vCheckInPeriodLineNumbers.Add(vSpreadsheet.TableHeight - 1);
				// Period start and end areas
				vPeriodStartArea = Undefined;
				vPeriodEndArea = Undefined;
				
				// By dates
				vPeriodRow = Undefined;
				vFirstPeriodRowIndex = 0;
				vPeriodResources.Clear();
				vQryPeriodDatesArray = vQryResTblByCheckInPeriods.FindRows(New Structure("RoomType, RoomQuota", vQryAllotments.RoomType, vQryAllotments.RoomQuota)); 
				For Each vQryPeriodDates In vQryPeriodDatesArray Do
					// Try to calculate resources
					If vQryPeriodDates.PeriodDate = BegOfDay(vQryPeriodDates.CheckInDate) Or vPeriodRow = Undefined Then
						vPeriodRow = vPeriodResources.Add();
						vPeriodRow.CheckInDate = vQryPeriodDates.CheckInDate;
						vPeriodRow.Duration = vQryPeriodDates.Duration;
						vPeriodRow.CheckOutDate = vQryPeriodDates.CheckOutDate;
						vPeriodRow.PeriodDate = vQryPeriodDates.PeriodDate;
						If vInBeds Then
							vPeriodRow.PeriodVacant = vQryPeriodDates.BedsVacant;
							vPeriodRow.PeriodRemains = vQryPeriodDates.BedsRemains;
						Else
							vPeriodRow.PeriodVacant = vQryPeriodDates.RoomsVacant;
							vPeriodRow.PeriodRemains = vQryPeriodDates.RoomsRemains;
						EndIf;
						vFirstPeriodRowIndex = vPeriodResources.IndexOf(vPeriodRow);
					Else
						// Update previous periods
						vCurPeriodRow = Undefined;
						i = vFirstPeriodRowIndex;
						While i < vPeriodResources.Count() Do
							vCurPeriodRow = vPeriodResources.Get(i);
							If vQryPeriodDates.PeriodDate < BegOfDay(vQryPeriodDates.CheckOutDate) Then
								If vInBeds Then
									vCurPeriodRow.PeriodVacant = Min(vCurPeriodRow.PeriodVacant, vQryPeriodDates.BedsVacant);
									vCurPeriodRow.PeriodRemains = Min(vCurPeriodRow.PeriodRemains, vQryPeriodDates.BedsRemains);
								Else
									vCurPeriodRow.PeriodVacant = Min(vCurPeriodRow.PeriodVacant, vQryPeriodDates.RoomsVacant);
									vCurPeriodRow.PeriodRemains = Min(vCurPeriodRow.PeriodRemains, vQryPeriodDates.RoomsRemains);
								EndIf;
								i = i + 1;
							Else
								Break;
							EndIf;
						EndDo;
						// Add new period
						vPeriodRow = vPeriodResources.Add();
						vPeriodRow.CheckInDate = vQryPeriodDates.CheckInDate;
						vPeriodRow.Duration = vQryPeriodDates.Duration;
						vPeriodRow.CheckOutDate = vQryPeriodDates.CheckOutDate;
						vPeriodRow.PeriodDate = vQryPeriodDates.PeriodDate;
						If vCurPeriodRow <> Undefined Then
							vPeriodRow.PeriodVacant = vCurPeriodRow.PeriodVacant;
							vPeriodRow.PeriodRemains = vCurPeriodRow.PeriodRemains;
						Else
							If vInBeds Then
								vPeriodRow.PeriodVacant = vQryPeriodDates.BedsVacant;
								vPeriodRow.PeriodRemains = vQryPeriodDates.BedsRemains;
							Else
								vPeriodRow.PeriodVacant = vQryPeriodDates.RoomsVacant;
								vPeriodRow.PeriodRemains = vQryPeriodDates.RoomsRemains;
							EndIf;
						EndIf;
					EndIf;
				EndDo;
				
				// Draw allotment periods
				vCurRemains = 0;
				vPrevRemains = 0;
				vCurDate = Undefined;
				vCurPeriodCheckInDate = Undefined;
				vCurPeriodCheckOutDate = Undefined;
				vCurPeriodCheckOutDay = Undefined;
				For Each vQryDates In vRoomTypeQryTblByDates Do
					vDate = vQryDates.PeriodDate;
					vCurDate = vDate;
					vPeriodVacant = 0;
					vPeriodRemains = 0;
					vPeriodCheckInDate = Undefined;
					vPeriodCheckOutDate = Undefined;
					// How to draw 
					vIsLeft = False;
					If vCurPeriodCheckOutDay = vDate Then
						vIsLeft = True;
					EndIf;
					vIsRight = False;
					vIsMiddle = False;
					// Find current check-in period
					vPeriodRows = vPeriodResources.FindRows(New Structure("PeriodDate", vDate));
					For Each vPeriodRow In vPeriodRows Do
						vCheckInDate = BegOfDay(vPeriodRow.CheckInDate);
						vCheckOutDate = BegOfDay(vPeriodRow.CheckOutDate);
						vCurPeriodCheckOutDay = vCheckOutDate;
						vPeriodCheckInDate = vPeriodRow.CheckInDate;
						vPeriodCheckOutDate = vPeriodRow.CheckOutDate;
						vCurPeriodCheckInDate = vPeriodCheckInDate;
						vCurPeriodCheckOutDate = vPeriodCheckOutDate;
						If vCheckInDate = vDate Then
							vIsRight = True;
						ElsIf vCheckInDate < vDate And vCheckOutDate > vDate Then 
							vIsMiddle = True;
						ElsIf vCheckOutDate = vDate Then
							vIsLeft = True;
						EndIf;
						vPeriodVacant = vPeriodRow.PeriodVacant;
						vPeriodRemains = vPeriodRow.PeriodRemains;
					EndDo;
					vPrevRemains = vCurRemains;
					If ValueIsFilled(vQryAllotments.RoomQuota) Then
						vCurRemains = vPeriodRemains;
					Else
						vCurRemains = vPeriodVacant;
					EndIf;
					If vIsRight And vIsLeft Then
						If vDate >= SelPeriodFrom And vDate <= SelPeriodTo Then
							If ValueIsFilled(vQryAllotments.RoomQuota) Then
								vPRLRArea.Parameters.mDateRemains = Format(vPeriodRemains, "NFD=0; NG=" + ?(vShowZeroes, "; NZ=", ""));
							Else
								vPRLRArea.Parameters.mDateRemains = Format(vPeriodVacant, "NFD=0; NG=" + ?(vShowZeroes, "; NZ=", ""));
							EndIf;
							FillCheckInPeriodDetails(vPRLRArea, vCurHotel, vQryAllotments.RoomType, vQryAllotments.RoomQuota, EndOfDay(vQryDates.PeriodDate), vPeriodCheckInDate, vPeriodCheckOutDate, ?((BegOfDay(vPeriodCheckOutDate) - BegOfDay(vPeriodCheckInDate)) > 86400, True, False));
							vArea = vSpreadsheet.Join(vPRLRArea);
							If vPrevRemains = 0 Then
								vSpreadsheet.Area(vArea.Top + 1, vArea.Left).BackColor = vSpreadsheet.Area(vArea.Top + 1, vArea.Left + 1).BackColor;
							EndIf;
							If vCurRemains = 0 Then
								vSpreadsheet.Area(vArea.Top + 1, vArea.Left + 3).BackColor = vSpreadsheet.Area(vArea.Top + 1, vArea.Left + 2).BackColor;
							EndIf;
							vPeriodEndArea = vArea;
							If vPeriodStartArea <> Undefined And vPeriodEndArea <> Undefined And 
								vPeriodStartArea.Left < vPeriodEndArea.Left And vPeriodStartArea.Top = vPeriodEndArea.Top Then
								vMergedArea = vSpreadsheet.Area(vPeriodStartArea.Top + 1, vPeriodStartArea.Left + 3, vPeriodEndArea.Top + 1, vPeriodEndArea.Left);
								vMergedArea.Merge();
							Else
								If vDate > SelPeriodFrom Then
									vMergedArea = vSpreadsheet.Area(vArea.Top + 1, vArea.Left - 1, vArea.Top + 1, vArea.Left);
									vMergedArea.Merge();
								EndIf;
							EndIf;
							vPeriodStartArea = vArea;
						EndIf;
						vPeriodEndArea = Undefined;
					ElsIf vIsRight Then
						If vDate >= SelPeriodFrom And vDate <= SelPeriodTo Then
							If ValueIsFilled(vQryAllotments.RoomQuota) Then
								vPRRArea.Parameters.mDateRemains = Format(vPeriodRemains, "NFD=0; NG=" + ?(vShowZeroes, "; NZ=", ""));
							Else
								vPRRArea.Parameters.mDateRemains = Format(vPeriodVacant, "NFD=0; NG=" + ?(vShowZeroes, "; NZ=", ""));
							EndIf;
							FillCheckInPeriodDetails(vPRRArea, vCurHotel, vQryAllotments.RoomType, vQryAllotments.RoomQuota, EndOfDay(vQryDates.PeriodDate), vPeriodCheckInDate, vPeriodCheckOutDate, ?((BegOfDay(vPeriodCheckOutDate) - BegOfDay(vPeriodCheckInDate)) > 86400, True, False));
							vArea = vSpreadsheet.Join(vPRRArea);
							If vCurRemains = 0 Then
								vSpreadsheet.Area(vArea.Top + 1, vArea.Left + 3).BackColor = vSpreadsheet.Area(vArea.Top + 1, vArea.Left + 2).BackColor;
							EndIf;
							If vDate > SelPeriodFrom Then
								vMergedArea = vSpreadsheet.Area(vArea.Top + 1, vArea.Left - 1, vArea.Top + 1, vArea.Left);
								vMergedArea.Merge();
							EndIf;
							vPeriodStartArea = vArea;
						EndIf;
						vPeriodEndArea = Undefined;
					ElsIf vIsLeft Then
						If vDate >= SelPeriodFrom And vDate <= SelPeriodTo Then
							FillCheckInPeriodDetails(vPRLArea, vCurHotel, vQryAllotments.RoomType, vQryAllotments.RoomQuota, EndOfDay(vQryDates.PeriodDate), ?(ValueIsFilled(vPeriodCheckInDate), vPeriodCheckInDate, BegOfDay(vQryDates.PeriodDate) + 12*3600), ?(ValueIsFilled(vPeriodCheckOutDate), vPeriodCheckOutDate, BegOfDay(vQryDates.PeriodDate) + 36*3600));
							vArea = vSpreadsheet.Join(vPRLArea);
							If vCurRemains = 0 Then
								vSpreadsheet.Area(vArea.Top + 1, vArea.Left).BackColor = vSpreadsheet.Area(vArea.Top + 1, vArea.Left + 1).BackColor;
							EndIf;
							vPeriodEndArea = vArea;
							If vPeriodStartArea <> Undefined And vPeriodEndArea <> Undefined And 
								vPeriodStartArea.Left < vPeriodEndArea.Left And vPeriodStartArea.Top = vPeriodEndArea.Top Then
								vMergedArea = vSpreadsheet.Area(vPeriodStartArea.Top + 1, vPeriodStartArea.Left + 3, vPeriodEndArea.Top + 1, vPeriodEndArea.Left);
								vMergedArea.Merge();
							Else
								If vDate > SelPeriodFrom Then
									vMergedArea = vSpreadsheet.Area(vArea.Top + 1, vArea.Left - 1, vArea.Top + 1, vArea.Left);
									vMergedArea.Merge();
								EndIf;
							EndIf;
						EndIf;
						vPeriodStartArea = Undefined;
						vPeriodEndArea = Undefined;
					ElsIf vIsMiddle Then
						If vDate >= SelPeriodFrom And vDate <= SelPeriodTo Then
							FillCheckInPeriodDetails(vPRMArea, vCurHotel, vQryAllotments.RoomType, vQryAllotments.RoomQuota, EndOfDay(vQryDates.PeriodDate), vPeriodCheckInDate, vPeriodCheckOutDate);
							vArea = vSpreadsheet.Join(vPRMArea);
							If vCurRemains = 0 Then
								vSpreadsheet.Area(vArea.Top + 1, vArea.Left, vArea.Top + 1, vArea.Left + 3).BackColor = vSpreadsheet.Area(vArea.Top, vArea.Left).BackColor;
							EndIf;
							If vDate > SelPeriodFrom Then
								vMergedArea = vSpreadsheet.Area(vArea.Top + 1, vArea.Left - 1, vArea.Top + 1, vArea.Left);
								vMergedArea.Merge();
							EndIf;
						EndIf;
					Else
						If vDate >= SelPeriodFrom And vDate <= SelPeriodTo Then
							FillCheckInPeriodDetails(vPRDArea, vCurHotel, vQryAllotments.RoomType, vQryAllotments.RoomQuota, EndOfDay(vQryDates.PeriodDate), BegOfDay(vQryDates.PeriodDate) + 12*3600, BegOfDay(vQryDates.PeriodDate) + 36*3600);
							vArea = vSpreadsheet.Join(vPRDArea);
							If vDate > SelPeriodFrom Then
								vMergedArea = vSpreadsheet.Area(vArea.Top + 1, vArea.Left - 1, vArea.Top + 1, vArea.Left);
								vMergedArea.Merge();
							EndIf;
						EndIf;
					EndIf;
				EndDo;
				If vCurDate <> Undefined And vCurPeriodCheckOutDate <> Undefined Then
					While vCurDate < BegOfDay(SelPeriodTo) Do
						If vCurDate < vCurPeriodCheckOutDay Then
							FillCheckInPeriodDetails(vPRMArea, vCurHotel, vQryAllotments.RoomType, vQryAllotments.RoomQuota, EndOfDay(vCurDate), vCurPeriodCheckInDate, vCurPeriodCheckOutDate, ?((BegOfDay(vCurPeriodCheckOutDate) - BegOfDay(vCurPeriodCheckInDate)) > 86400, True, False));
							vArea = vSpreadsheet.Join(vPRMArea);
							If vCurRemains = 0 Then
								vSpreadsheet.Area(vArea.Top + 1, vArea.Left, vArea.Top + 1, vArea.Left + 3).BackColor = vSpreadsheet.Area(vArea.Top, vArea.Left).BackColor;
							EndIf;
							If vCurDate > SelPeriodFrom Then
								vMergedArea = vSpreadsheet.Area(vArea.Top + 1, vArea.Left - 1, vArea.Top + 1, vArea.Left);
								vMergedArea.Merge();
							EndIf;
						ElsIf vCurDate = vCurPeriodCheckOutDay Then
							FillCheckInPeriodDetails(vPRLArea, vCurHotel, vQryAllotments.RoomType, vQryAllotments.RoomQuota, EndOfDay(vCurDate), ?(ValueIsFilled(vCurPeriodCheckInDate), vCurPeriodCheckInDate, BegOfDay(vCurDate) + 12*3600), ?(ValueIsFilled(vCurPeriodCheckOutDate), vCurPeriodCheckOutDate, BegOfDay(vCurDate) + 36*3600));
							vArea = vSpreadsheet.Join(vPRLArea);
							If vCurRemains = 0 Then
								vSpreadsheet.Area(vArea.Top + 1, vArea.Left).BackColor = vSpreadsheet.Area(vArea.Top + 1, vArea.Left + 1).BackColor;
							EndIf;
							If vCurDate > SelPeriodFrom Then
								vMergedArea = vSpreadsheet.Area(vArea.Top + 1, vArea.Left - 1, vArea.Top + 1, vArea.Left);
								vMergedArea.Merge();
							EndIf;
						Else
							FillCheckInPeriodDetails(vPRDArea, vCurHotel, vQryAllotments.RoomType, vQryAllotments.RoomQuota, EndOfDay(vCurDate), BegOfDay(vCurDate) + 12*3600, BegOfDay(vCurDate) + 36*3600);
							vArea = vSpreadsheet.Join(vPRDArea);
							If vCurDate > SelPeriodFrom Then
								vMergedArea = vSpreadsheet.Area(vArea.Top + 1, vArea.Left - 1, vArea.Top + 1, vArea.Left);
								vMergedArea.Merge();
							EndIf;
						EndIf;
						vCurDate = vCurDate + 24 * 3600;
					EndDo;
				EndIf;
				
				// Draw allotment totals, reservations and accommodations
				If SelShowReservations Then
					// Draw allotment totals
					vSpreadsheet.StartRowGroup(NStr("en='Allotment';ru='Квота';de='Quote'"), True);
					vATLArea.Parameters.mRoomQuota = vQryAllotments.RoomQuota;
					vSpreadsheet.Put(vATLArea);
					For Each vQryByDates In vRoomTypeQryTblByDates Do
						If vQryByDates.PeriodDate < SelPeriodFrom Or vQryByDates.PeriodDate > SelPeriodTo Then
							Continue;
						EndIf;
						vQryPeriodDatesArray = vQryResTblByAllotmentsAndDates.FindRows(New Structure("PeriodDate, RoomType, RoomQuota", vQryByDates.PeriodDate, vQryAllotments.RoomType, vQryAllotments.RoomQuota));
						If vQryPeriodDatesArray.Count() > 0 Then
							vQryPeriodDates = vQryPeriodDatesArray.Get(0); 
							If vInBeds Then
								vATDArea.Parameters.mTotal = Format(vQryPeriodDates.BedsInQuota, "NFD=0; NG=" + ?(vShowZeroes, "; NZ=", ""));
							Else
								vATDArea.Parameters.mTotal = Format(vQryPeriodDates.RoomsInQuota, "NFD=0; NG=" + ?(vShowZeroes, "; NZ=", ""));
							EndIf;
							FillCheckInPeriodDetails(vATDArea, vCurHotel, vQryPeriodDates.RoomType, vQryPeriodDates.RoomQuota, EndOfDay(vQryPeriodDates.PeriodDate), BegOfDay(vQryPeriodDates.PeriodDate) + 12*3600, BegOfDay(vQryPeriodDates.PeriodDate) + 36*3600);
							vArea = vSpreadsheet.Join(vATDArea);
							If vQryPeriodDates.PeriodDate > SelPeriodFrom Then
								vSpreadsheet.Area(vArea.Top, vArea.Left).Details = vSpreadsheet.Area(vArea.Top, vArea.Left - 1).Details;
							EndIf;
						Else
							vATDArea.Parameters.mTotal = 0;
							FillCheckInPeriodDetails(vATDArea, vCurHotel, vQryAllotments.RoomType, vQryAllotments.RoomQuota, EndOfDay(vQryByDates.PeriodDate), BegOfDay(vQryByDates.PeriodDate) + 12*3600, BegOfDay(vQryByDates.PeriodDate) + 36*3600);
							vArea = vSpreadsheet.Join(vATDArea);
							If vQryByDates.PeriodDate > SelPeriodFrom Then
								vSpreadsheet.Area(vArea.Top, vArea.Left).Details = vSpreadsheet.Area(vArea.Top, vArea.Left - 1).Details;
							EndIf;
						EndIf;
					EndDo;
					
					// Draw reservations
					vCurRoomCounter = 1;
					While True Do
						vMappedDocsRows = vMappedDocs.FindRows(New Structure("RoomType, RoomQuota, RoomCounter", vQryAllotments.RoomType, vQryAllotments.RoomQuota, vCurRoomCounter));
						If vMappedDocsRows.Count() = 0 Then
							Break;
						EndIf;
						// Put counter line
						vRCOArea.Parameters.mRoomQuota = vQryAllotments.RoomQuota;
						vRCOArea.Parameters.mRoomCounter = Format(vCurRoomCounter, "ND=10; NFD=0; NZ=; NG=");
						vSpreadsheet.Put(vRCOArea);
						// Draw documents for this counter line
						vCurDocumentStartArea = Undefined;
						For Each vQryByDates In vRoomTypeQryTblByDates Do
							If vQryByDates.PeriodDate < SelPeriodFrom Or vQryByDates.PeriodDate > SelPeriodTo Then
								Continue;
							EndIf;
							vMappedDocsRowsPerDate = vMappedDocs.FindRows(New Structure("RoomType, RoomQuota, PeriodDate, RoomCounter", vQryAllotments.RoomType, vQryAllotments.RoomQuota, vQryByDates.PeriodDate, vCurRoomCounter));
							If vMappedDocsRowsPerDate.Count() > 0 Then
								vMappedDocsRowsPerDateRow = vMappedDocsRowsPerDate.Get(0);
								vDocPresentation = "";
								vBoldFont = False;
								If vMappedDocsRowsPerDateRow.IsRight Then
									If vMappedDocsRowsPerDateRow.OccupiedRooms > 1 Then
										vBoldFont = True;
										vDocPresentation = Format(vMappedDocsRowsPerDateRow.OccupiedRooms, "ND=10; NFD=0; NZ=; NG=") + ", " + Format(vMappedDocsRowsPerDateRow.GuestGroupCode, "ND=12; NFD=0; NG=") + NStr("en=' on ';ru=' от ';de=' vom '") + Format(vMappedDocsRowsPerDateRow.CreateDate, "DF=dd.MM") + ", " + Format(vMappedDocsRowsPerDateRow.CheckInDate, "DF=dd.MM") + " - " + Format(vMappedDocsRowsPerDateRow.CheckOutDate, "DF=dd.MM") + ", " + TrimR(vMappedDocsRowsPerDateRow.GuestDescription);
									Else
										vDocPresentation = Format(vMappedDocsRowsPerDateRow.GuestGroupCode, "ND=12; NFD=0; NG=") + NStr("en=' on ';ru=' от ';de=' vom '") + Format(vMappedDocsRowsPerDateRow.CreateDate, "DF=dd.MM") + ", " + Format(vMappedDocsRowsPerDateRow.CheckInDate, "DF=dd.MM") + " - " + Format(vMappedDocsRowsPerDateRow.CheckOutDate, "DF=dd.MM") + ", " + TrimR(vMappedDocsRowsPerDateRow.GuestDescription);
									EndIf;
								EndIf;
								vDocColor = GetDocumentColor(vMappedDocsRowsPerDateRow);
								If vMappedDocsRowsPerDateRow.IsLeft And vMappedDocsRowsPerDateRow.IsRight Then
									vRCLRArea.Parameters.mDocPresentation = vDocPresentation;
									vRCLRArea.Parameters.mDoc = vMappedDocsRowsPerDateRow.Doc;
									vArea = vSpreadsheet.Join(vRCLRArea);
									If vMappedDocsRowsPerDateRow.BegOfCheckOutDate > SelPeriodFrom Then
										vSpreadsheet.Area(vArea.Top + 1, vArea.Left).Details = vSpreadsheet.Area(vArea.Top + 1, vArea.Left - 1).Details;
										vSpreadsheet.Area(vArea.Top + 1, vArea.Left).BackColor = vSpreadsheet.Area(vArea.Top + 1, vArea.Left - 1).BackColor;
									EndIf;
									If vDocColor <> Undefined Then
										If vMappedDocsRowsPerDateRow.BegOfCheckInDate = vQryByDates.PeriodDate Then
											vSpreadsheet.Area(vArea.Top + 1, vArea.Left + 3).BackColor = vDocColor;
										EndIf;
									EndIf;
									If vCurDocumentStartArea <> Undefined Then
										vSpreadsheet.Area(vArea.Top + 1, vCurDocumentStartArea.Right, vArea.Top + 1, vArea.Left).Merge();
									EndIf;
									vCurDocumentStartArea = vArea;
								ElsIf vMappedDocsRowsPerDateRow.IsRight Then
									vRCRArea.Parameters.mDocPresentation = vDocPresentation;
									vRCRArea.Parameters.mDoc = vMappedDocsRowsPerDateRow.Doc;
									FillCheckInPeriodDetails(vRCRArea, vMappedDocsRowsPerDateRow.Hotel, vMappedDocsRowsPerDateRow.RoomType, vMappedDocsRowsPerDateRow.RoomQuota, EndOfDay(vQryByDates.PeriodDate), BegOfDay(vQryByDates.PeriodDate) + 12*3600, BegOfDay(vQryByDates.PeriodDate) + 12*3600);
									vArea = vSpreadsheet.Join(vRCRArea);
									If vDocColor <> Undefined Then
										vSpreadsheet.Area(vArea.Top + 1, vArea.Left + 3).BackColor = vDocColor;
									EndIf;
									vCurDocumentStartArea = vArea;
								ElsIf vMappedDocsRowsPerDateRow.IsLeft Then
									FillCheckInPeriodDetails(vRCLArea, vMappedDocsRowsPerDateRow.Hotel, vMappedDocsRowsPerDateRow.RoomType, vMappedDocsRowsPerDateRow.RoomQuota, EndOfDay(vQryByDates.PeriodDate), BegOfDay(vQryByDates.PeriodDate) + 12*3600, BegOfDay(vQryByDates.PeriodDate) + 12*3600);
									vArea = vSpreadsheet.Join(vRCLArea);
									If vMappedDocsRowsPerDateRow.BegOfCheckOutDate > SelPeriodFrom Then
										vSpreadsheet.Area(vArea.Top + 1, vArea.Left).Details = vSpreadsheet.Area(vArea.Top + 1, vArea.Left - 1).Details;
									EndIf;
									If vDocColor <> Undefined Then
										vSpreadsheet.Area(vArea.Top + 1, vArea.Left).BackColor = vDocColor;
									EndIf;
									If vCurDocumentStartArea <> Undefined Then
										vSpreadsheet.Area(vArea.Top + 1, vCurDocumentStartArea.Right, vArea.Top + 1, vArea.Left).Merge();
									EndIf;
								ElsIf vMappedDocsRowsPerDateRow.IsMiddle Then
									vRCMArea.Parameters.mDoc = vMappedDocsRowsPerDateRow.Doc;
									vArea = vSpreadsheet.Join(vRCMArea);
									If vDocColor <> Undefined Then
										vSpreadsheet.Area(vArea.Top + 1, vArea.Left, vArea.Top + 1, vArea.Left + 3).BackColor = vDocColor;
									EndIf;
								Else
									FillCheckInPeriodDetails(vRCDArea, vMappedDocsRowsPerDateRow.Hotel, vMappedDocsRowsPerDateRow.RoomType, vMappedDocsRowsPerDateRow.RoomQuota, EndOfDay(vQryByDates.PeriodDate), BegOfDay(vQryByDates.PeriodDate) + 12*3600, BegOfDay(vQryByDates.PeriodDate) + 12*3600);
									vArea = vSpreadsheet.Join(vRCDArea);
								EndIf;
								If vMappedDocsRowsPerDateRow.IsRight Then
									If vBoldFont Then
										vSpreadsheet.Area(vArea.Top + 1, vArea.Left + 3).Font = tcCommonFunctionOnClientServer.FontConstructor(vSpreadsheet.Area(vArea.Top + 1, vArea.Left + 3).Font, , , True);
									EndIf;
								EndIf;
							Else
								FillCheckInPeriodDetails(vRCDArea, vCurHotel, vQryAllotments.RoomType, vQryAllotments.RoomQuota, EndOfDay(vQryByDates.PeriodDate), BegOfDay(vQryByDates.PeriodDate) + 12*3600, BegOfDay(vQryByDates.PeriodDate) + 12*3600);
								vSpreadsheet.Join(vRCDArea);
							EndIf;
						EndDo;
						vCurRoomCounter = vCurRoomCounter + 1;
					EndDo;
					vSpreadsheet.EndRowGroup();
				EndIf;
			EndDo;
			vSpreadsheet.EndRowGroup();
		EndDo;
		
		// Show hotel occupation pecent
		If SelShowOccupationPercent Then
			vHotelSales = GetHotelSales(vCurHotel);
			vSpreadsheet.Put(vOPTArea);
			
			// Iterate thru dates
			vDateOccupancyPercentDetails = Undefined;
			vQryHotelByDatesArray = vRoomTypeQryTblByHotelsAndDates.FindRows(New Structure("Hotel", vCurHotel));
			For Each vRoomTypeQryHotelByDates In vQryHotelByDatesArray Do
				If vRoomTypeQryHotelByDates.PeriodDate < SelPeriodFrom Or vRoomTypeQryHotelByDates.PeriodDate > SelPeriodTo Then
					Continue;
				EndIf;
				
				// Find sales by date
				vHotelSalesRows = vHotelSales.FindRows(New Structure("Hotel, PeriodDate", vCurHotel, vRoomTypeQryHotelByDates.PeriodDate));
				If vHotelSalesRows.Count() > 0 Then
					vHotelSalesRow = vHotelSalesRows.Get(0);
					If vInBeds Then
						vOccPrc = ?((vRoomTypeQryHotelByDates.TotalBeds - vRoomTypeQryHotelByDates.BedsBlocked) <= 0, 0, ?(SelShowPreliminary, vHotelSalesRow.BedsRented, vHotelSalesRow.DefiniteBedsRented) / (vRoomTypeQryHotelByDates.TotalBeds - vRoomTypeQryHotelByDates.BedsBlocked) * 100);
						vOPDArea.Parameters.mDateOccupancyPercentDetails = NStr("en='Beds: '; ru='Мест: '; de='Betten: '") + vRoomTypeQryHotelByDates.TotalBeds + NStr("en=', Blocked: '; ru=', Заблокировано: '; de=', Verstopft: '") + vRoomTypeQryHotelByDates.BedsBlocked + NStr("en=', Sold: '; ru=', Продано: '; de=', Verkauft: '") + vHotelSalesRow.BedsRented + NStr("en=', Occ. %: '; ru=', % продаж: '; de=', Occ. %: '") + Round(vOccPrc, 2);
					Else
						vOccPrc = ?((vRoomTypeQryHotelByDates.TotalRooms - vRoomTypeQryHotelByDates.RoomsBlocked) <= 0, 0, ?(SelShowPreliminary, vHotelSalesRow.RoomsRented, vHotelSalesRow.DefiniteRoomsRented) / (vRoomTypeQryHotelByDates.TotalRooms - vRoomTypeQryHotelByDates.RoomsBlocked) * 100);
						vOPDArea.Parameters.mDateOccupancyPercentDetails = NStr("en='Rooms: '; ru='Номеров: '; de='Zimmern: '") + vRoomTypeQryHotelByDates.TotalRooms + NStr("en=', Blocked: '; ru=', Заблокировано: '; de=', Verstopft: '") + vRoomTypeQryHotelByDates.RoomsBlocked + NStr("en=', Sold: '; ru=', Продано: '; de=', Verkauft: '") + vHotelSalesRow.RoomsRented + NStr("en=', Occ. %: '; ru=', % продаж: '; de=', Occ. %: '") + Round(vOccPrc, 2);
					EndIf;
					vOPDArea.Parameters.mDateOccupancyPercent = Format(Round(vOccPrc, 0), "NFD=0; NZ=; NG=") + "%";
				Else
					vOPDArea.Parameters.mDateOccupancyPercent = "0%";
					vOPDArea.Parameters.mDateOccupancyPercentDetails = Undefined;
				EndIf;
				vOPDArea.Parameters.mDateOccupancyPercentDetailsLeft = vDateOccupancyPercentDetails;
				vDateOccupancyPercentDetails = vOPDArea.Parameters.mDateOccupancyPercentDetails;
				vSpreadsheet.Join(vOPDArea);
			EndDo;
		EndIf;
	EndDo;
	
	// Draw report table footer
	vFPArea = vTemplate.GetArea("Footer|Duration");
	vSpreadsheet.Put(vFPArea);
	vFDArea = vTemplate.GetArea("Footer|Date");
	For Each vQryByDates In vRoomTypeQryTblByDates Do
		If vQryByDates.PeriodDate < SelPeriodFrom Or vQryByDates.PeriodDate > SelPeriodTo Then
			Continue;
		EndIf;
		vSpreadsheet.Join(vFDArea);
	EndDo;
	
	// Mark weekends
	i = 0;
	For Each vQryByDates In vRoomTypeQryTblByDates Do
		If vQryByDates.PeriodDate < SelPeriodFrom Or vQryByDates.PeriodDate > SelPeriodTo Then
			Continue;
		EndIf;
		If WeekDay(vQryByDates.PeriodDate) > 5 Then
			For j = 3 To vSpreadsheet.TableHeight Do
				If vCheckInPeriodLineNumbers.FindByValue(j) = Undefined Then
					vWeekendArea = vSpreadsheet.Area(j, 6 + i * 4, j, 9 + i * 4);
					vWeekendArea.Pattern = SpreadsheetDocumentPatternType.Pattern3;
					
					vWeekendArea.PatternColor = WeekendsPatternColor;
				EndIf;
			EndDo;
		EndIf;
		i = i + 1;
	EndDo;		
	
	// Fix top N rows and 5 left columns
	If vEvents <> Undefined And vEvents.Count() > 0 Then
		vSpreadsheet.FixedTop = 7;
		vSpreadsheet.RepeatOnRowPrint = vSpreadsheet.Area(1, , 7);
	Else
		vSpreadsheet.FixedTop = 4;
		vSpreadsheet.RepeatOnRowPrint = vSpreadsheet.Area(1, , 4);
	EndIf;
	vSpreadsheet.FixedLeft = 5;
	vSpreadsheet.RepeatOnColumnPrint = vSpreadsheet.Area(, 1, , 5);
EndProcedure // GeneratePickup

// -----------------------------------------------------------------------------
&AtServer  
Procedure GenerateTotals(vSpreadsheet, pGroupingStr = Undefined)
	// Read allotment data
	vAllotmentQryTbl = GetAllotmentPeriodsBalances();
	
	vQryTblByDates = vAllotmentQryTbl.Copy();
	vQryTblByDates.GroupBy("PeriodDate");
	vQryTblByDates.Sort("PeriodDate");
	
	vQryTblByHotels = vAllotmentQryTbl.Copy();
	vQryTblByHotels.GroupBy("Hotel, HotelSortCode, HotelDescription");
	vQryTblByHotels.Sort("HotelSortCode, HotelDescription");
	
	vQryTblByHotelsAndDates = vAllotmentQryTbl.Copy();
	vQryTblByHotelsAndDates.GroupBy("Hotel, HotelSortCode, HotelDescription, PeriodDate", "RoomsVacant, BedsVacant, TentativeRooms, TentativeBeds, SpecialRoomsVacant, SpecialBedsVacant, RoomsInQuota, BedsInQuota, InitialRoomsInQuota, InitialBedsInQuota, RoomsRemains, BedsRemains, TotalRooms, TotalBeds, TotalSpecialRooms, TotalSpecialBeds, RoomsBlocked, BedsBlocked, RoomsForecast, BedsForecast");
	vQryTblByHotelsAndDates.Sort("HotelSortCode, HotelDescription, PeriodDate");
	vQryTblByHotelsAndDates.Indexes.Add("Hotel, PeriodDate");
	
	vQryTblByHotelsAndAllotments = vAllotmentQryTbl.Copy();
	vQryTblByHotelsAndAllotments.GroupBy("Hotel, HotelSortCode, HotelDescription, RoomQuota, RoomQuotaSortCode, RoomQuotaDescription", "RoomsVacant, BedsVacant, TentativeRooms, TentativeBeds, SpecialRoomsVacant, SpecialBedsVacant, RoomsInQuota, BedsInQuota, InitialRoomsInQuota, InitialBedsInQuota, RoomsRemains, BedsRemains, RoomsForecast, BedsForecast");
	vQryTblByHotelsAndAllotments.Sort("HotelSortCode, HotelDescription, RoomQuotaSortCode, RoomQuotaDescription");
	vQryTblByHotelsAndAllotments.Indexes.Add("Hotel");
	
	vQryTblByAllotmentsAndDates = vAllotmentQryTbl.Copy();
	vQryTblByAllotmentsAndDates.GroupBy("Hotel, HotelSortCode, HotelDescription, RoomQuota, RoomQuotaSortCode, RoomQuotaDescription, PeriodDate", "RoomsVacant, BedsVacant, TentativeRooms, TentativeBeds, SpecialRoomsVacant, RoomsInQuota, BedsInQuota, InitialRoomsInQuota, InitialBedsInQuota, SpecialBedsVacant, InitialRoomsInQuota, InitialBedsInQuota, RoomsRemains, BedsRemains, TotalRooms, TotalBeds, TotalSpecialRooms, TotalSpecialBeds, RoomsBlocked, BedsBlocked, RoomsForecast, BedsForecast");
	vQryTblByAllotmentsAndDates.Sort("HotelSortCode, HotelDescription, RoomQuotaSortCode, RoomQuotaDescription, PeriodDate");
	vQryTblByAllotmentsAndDates.Indexes.Add("Hotel, RoomQuota, PeriodDate");
	
	vQryResTblByAllotmentsAndRoomTypes = vAllotmentQryTbl.Copy();
	vQryResTblByAllotmentsAndRoomTypes.GroupBy("Hotel, HotelSortCode, HotelDescription, RoomQuota, RoomQuotaSortCode, RoomQuotaDescription, RoomType, RoomTypeSortCode, RoomTypeDescription", );
	vQryResTblByAllotmentsAndRoomTypes.Sort("HotelSortCode, HotelDescription, RoomQuotaSortCode, RoomQuotaDescription, RoomTypeSortCode, RoomTypeDescription");
	vQryResTblByAllotmentsAndRoomTypes.Indexes.Add("Hotel, RoomQuota");	
	
	vQryResTblByAllotmentsRoomTypesAndDates = vAllotmentQryTbl.Copy();
	vQryResTblByAllotmentsRoomTypesAndDates.GroupBy("Hotel, HotelSortCode, HotelDescription, RoomQuota, RoomQuotaSortCode, RoomQuotaDescription, RoomType, RoomTypeSortCode, RoomTypeDescription, PeriodDate", "TotalRooms, TotalBeds, TotalSpecialRooms, TotalSpecialBeds, RoomsVacant, BedsVacant, TentativeRooms, TentativeBeds, SpecialRoomsVacant, SpecialBedsVacant, RoomsRemains, BedsRemains, RoomsInQuota, BedsInQuota, InitialRoomsInQuota, InitialBedsInQuota, RoomsForecast, BedsForecast");
	vQryResTblByAllotmentsRoomTypesAndDates.Sort("HotelSortCode, HotelDescription, RoomQuotaSortCode, RoomQuotaDescription, RoomTypeSortCode, RoomTypeDescription, PeriodDate");
	vQryResTblByAllotmentsRoomTypesAndDates.Indexes.Add("Hotel, RoomQuota, RoomType, PeriodDate");	

	// Calculate an average daily rate for the allotments
	vAllotmentsTable = vQryTblByHotelsAndAllotments.Copy(, "RoomQuota");
	vAllotmentsTable.GroupBy("RoomQuota", );
	vAllotmentsList = New ValueList();
	vAllotmentsList.LoadValues(vAllotmentsTable.UnloadColumn("RoomQuota"));
	n = 0;
	While n < vAllotmentsList.Count() Do
		vAllotmentRef = vAllotmentsList.Get(n).Value;
		If Not ValueIsFilled(vAllotmentRef) Or 
		   ValueIsFilled(vAllotmentRef) And TypeOf(vAllotmentRef) <> Type("CatalogRef.RoomQuotas") Or
		   ValueIsFilled(vAllotmentRef) And TypeOf(vAllotmentRef) = Type("CatalogRef.RoomQuotas") And 
		  (vAllotmentRef.IsFolder Or Not vAllotmentRef.IsFolder And vAllotmentRef.BudgetADR > 0) Then
			vAllotmentsList.Delete(n);
		Else
			n = n + 1;
		EndIf;
	EndDo;
	vAllotmentADRs = Undefined;
	vAllotmentPlannedADRs = Undefined;
	If vAllotmentsList.Count() > 0 Then
		vAllotmentADRs = GetAllotmentADRs(vAllotmentsList);
		vAllotmentPlannedADRs = GetAllotmentPlannedADRs(vAllotmentsList);
	EndIf;
	
	// Get report template
	vTemplate = Catalogs.RoomQuotas.GetTemplate("AllotmentVacantRooms");
	
	// Print report name
	vArea = vTemplate.GetArea("Report");
	If InRooms Then
		If SelMode = 0 Or SelMode = 1 And SelShowSelector = 3 Then
			vArea.Parameters.mReportName = NStr("en='Vacant rooms by allotment'; ru='Свободные номера по квотам'; de='Freie Zimmer nach Allotment'");
		ElsIf SelMode = 2 Then
			vArea.Parameters.mReportName = NStr("en='Forecast rooms by allotment'; ru='Прогноз номеров по квотам'; de='Zimmerprognose nach Allotment'");
		ElsIf SelMode = 1 And SelShowSelector = 1 Then
			vArea.Parameters.mReportName = NStr("en='Initial rooms by allotment'; ru='Начальное кол-во номеров по квотам'; de='Anfängliche Anzahl der Zimmer nach Allotment'");
		ElsIf SelMode = 1 And SelShowSelector = 0 Then
			vArea.Parameters.mReportName = NStr("en='Rooms by allotment'; ru='Выделено номеров в квоты'; de='Zimmer nach Allotment'");
		ElsIf SelMode = 1 And SelShowSelector = 2 Then
			vArea.Parameters.mReportName = NStr("en='Difference in rooms to initial'; ru='Разница в номерах по квотам'; de='Unterschied im Zimmer zu initial'");
		ElsIf SelMode = 1 And SelShowSelector = 4 Then
			vArea.Parameters.mReportName = NStr("en='Prices by days'; ru='Цены по дням'; de='Preise pro Tag'");
		ElsIf SelMode = 1 And SelShowSelector = 5 Then
			vArea.Parameters.mReportName = NStr("en='Pickup rooms by days'; ru='Выбрано номеров по дням'; de='Zimmer Pickup pro Tag'");
		EndIf;
	Else
		If SelMode = 0 Or SelMode = 1 And SelShowSelector = 3 Then
			vArea.Parameters.mReportName = NStr("en='Vacant beds by allotment'; ru='Свободные места по квотам'; de='Freie Betten nach Allotment'");
		ElsIf SelMode = 2 Then
			vArea.Parameters.mReportName = NStr("en='Forecast beds by allotment'; ru='Прогноз мест по квотам'; de='Bettenprognose nach Allotment'");
		ElsIf SelMode = 1 And SelShowSelector = 1 Then
			vArea.Parameters.mReportName = NStr("en='Initial beds by allotment'; ru='Начальное кол-во мест по квотам'; de='Anfängliche Anzahl der Betten nach Allotment'");
		ElsIf SelMode = 1 And SelShowSelector = 0 Then
			vArea.Parameters.mReportName = NStr("en='Beds by allotment'; ru='Выделено мест в квоты'; de='Betten nach Allotment'");
		ElsIf SelMode = 1 And SelShowSelector = 2 Then
			vArea.Parameters.mReportName = NStr("en='Difference in beds to initial'; ru='Разница в местах по квотам'; de='Unterschied im Betten zu initial'");
		ElsIf SelMode = 1 And SelShowSelector = 4 Then
			vArea.Parameters.mReportName = NStr("en='Prices by days'; ru='Цены по дням'; de='Preise pro Tag'");
		ElsIf SelMode = 1 And SelShowSelector = 5 Then
			vArea.Parameters.mReportName = NStr("en='Pickup beds by days'; ru='Выбрано мест по дням'; de='Betten Pickup pro Tag'");
		EndIf;
	EndIf;
	vSpreadsheet.Put(vArea);
	
	// Filter
	vArea = vTemplate.GetArea("Filter");
	vArea.Parameters.mFilter = NStr("en = 'Filter: '; de = 'Auswahl: '; ru = 'Отбор: '") + GetReportParametersPresentation();
	vSpreadsheet.Put(vArea);
	
	// Draw report table header
	vHPArea = vTemplate.GetArea("HeaderRow|Duration");
	vSpreadsheet.Put(vHPArea);
	vHDArea = vTemplate.GetArea("HeaderRow|Date");
	For Each vQryByDates In vQryTblByDates Do
		If vQryByDates.PeriodDate < SelPeriodFrom Or vQryByDates.PeriodDate > (SelPeriodTo - 24*3600)Then
			Continue;
		EndIf;
		vHDArea.Parameters.mPeriodDate = Format(vQryByDates.PeriodDate, "DF='dd.MM'") + " " + cmGetDayOfWeekName(WeekDay(vQryByDates.PeriodDate), True);
		vSpreadsheet.Join(vHDArea);
	EndDo;		
	
	// Get template areas
	vHTPArea = vTemplate.GetArea("HotelRow|Duration");
	vHTDArea = vTemplate.GetArea("HotelRow|Date");
	vHTPVArea = vTemplate.GetArea("HotelVacantsRow|Duration");
	vHTDVArea = vTemplate.GetArea("HotelVacantsRow|Date");
	vRQPArea = vTemplate.GetArea("AllotmentRow|Duration");
	vRQDArea = vTemplate.GetArea("AllotmentRow|Date");
	vRTPArea = vTemplate.GetArea("RoomTypeRow|Duration");
	vRTDArea = vTemplate.GetArea("RoomTypeRow|Date");
	vRTPVArea = vTemplate.GetArea("RoomTypeVacantsRow|Duration");
	vRTDVArea = vTemplate.GetArea("RoomTypeVacantsRow|Date");
	vEVTArea = vTemplate.GetArea("Events|Duration");
	vEVDArea = vTemplate.GetArea("Events|Date");
	vOPTArea = vTemplate.GetArea("OccupancyPercentRow|Duration");
	vOPDArea = vTemplate.GetArea("OccupancyPercentRow|Date");
	
	// By hotels
	HeaderHeight = 6;
	For Each vQryHotels In vQryTblByHotels Do
		vCurHotel = vQryHotels.Hotel;
		If Not ValueIsFilled(vCurHotel) Then
			Continue;
		EndIf;

		// In beds or in rooms
		vInBeds = vCurHotel.ShowReportsInBeds;
		// Show zeroes
		vShowZeroes = vCurHotel.ShowZeroesInAvailability;
		
		// Get number of rooms/beds per hotel for first period date
		vTotalRoomsBeds = 0;
		vHotelFirstDateRows = vQryTblByHotelsAndDates.FindRows(New Structure("Hotel, PeriodDate", vCurHotel, BegOfDay(SelPeriodFrom)));
		If vHotelFirstDateRows.Count() > 0 Then
			vHotelFirstDateRow = vHotelFirstDateRows.Get(0);
			vTotalRoomsBeds = ?(vInBeds, vHotelFirstDateRow.TotalBeds, vHotelFirstDateRow.TotalRooms);
		EndIf;
		
		// Fill hotel name
		vHTPArea.Parameters.mHotelStr = "" + vCurHotel + ?(vTotalRoomsBeds > 0, Chars.LF + Chars.Tab + Chars.Tab + Chars.Tab + Chars.Tab + Chars.Tab + Chars.Tab + Chars.Tab + "(" + vTotalRoomsBeds + ")", "");
		vHTPArea.Parameters.mHotel = vCurHotel;
		vSpreadsheet.StartRowGroup(NStr("en='Hotel';ru='Гостиница';de='Hotel'"), SelShowVacants);
		vSpreadsheet.Put(vHTPArea);
		
		// Iterate thru dates
		vQryHotelByDatesArray = vQryTblByHotelsAndDates.FindRows(New Structure("Hotel", vCurHotel));
		For Each vQryHotelByDates In vQryHotelByDatesArray Do
			If vQryHotelByDates.PeriodDate < SelPeriodFrom Or vQryHotelByDates.PeriodDate > (SelPeriodTo - 24*3600) Then
				Continue;
			EndIf;
			vDate = vQryHotelByDates.PeriodDate;
			
			vDateHotel = 0;
			If vInBeds Then
				If SelMode = 2 Then
					vDateHotel = vQryHotelByDates.BedsForecast;
				Else
					If SelShowSelector = 0 Then
						vDateHotel = vQryHotelByDates.BedsInQuota;
					ElsIf SelShowSelector = 1 Then
						vDateHotel = vQryHotelByDates.InitialBedsInQuota;
					ElsIf SelShowSelector = 2 Then
						vDateHotel = vQryHotelByDates.BedsInQuota - vQryHotelByDates.InitialBedsInQuota;
					ElsIf SelShowSelector = 3 Then
						vDateHotel = vQryHotelByDates.BedsRemains;
					ElsIf SelShowSelector = 5 Then
						vDateHotel = vQryHotelByDates.BedsInQuota - vQryHotelByDates.BedsRemains;
					ElsIf SelShowSelector = 4 Then
						vDateHotel = 0;
					EndIf;
				EndIf;
			Else
				If SelMode = 2 Then
					vDateHotel = vQryHotelByDates.RoomsForecast;
				Else
					If SelShowSelector = 0 Then
						vDateHotel = vQryHotelByDates.RoomsInQuota;
					ElsIf SelShowSelector = 1 Then
						vDateHotel = vQryHotelByDates.InitialRoomsInQuota;
					ElsIf SelShowSelector = 2 Then
						vDateHotel = vQryHotelByDates.RoomsInQuota - vQryHotelByDates.InitialRoomsInQuota;
					ElsIf SelShowSelector = 3 Then
						vDateHotel = vQryHotelByDates.RoomsRemains;
					ElsIf SelShowSelector = 5 Then
						vDateHotel = vQryHotelByDates.RoomsInQuota - vQryHotelByDates.RoomsRemains;
					ElsIf SelShowSelector = 4 Then
						vDateHotel = 0;
					EndIf;
				EndIf;
			EndIf;
			
			vHTDArea.Parameters.mDateTotal = Format(vDateHotel, "NFD=0; NG=" + ?(vShowZeroes, "; NZ=", ""));
			FillTotalsDateDetails(vHTDArea, vQryHotelByDates.Hotel, Undefined, Undefined, EndOfDay(vDate));
			vSpreadsheet.Join(vHTDArea);
		EndDo;
		// Fill hotel vacants
		If SelMode = 1 And SelShowVacants Then
			vSpreadsheet.Put(vHTPVArea);
			// Iterate thru dates
			For Each vQryHotelByDates In vQryHotelByDatesArray Do
				If vQryHotelByDates.PeriodDate < SelPeriodFrom Or vQryHotelByDates.PeriodDate > (SelPeriodTo - 24*3600) Then
					Continue;
				EndIf;
				vDate = vQryHotelByDates.PeriodDate;
				
				vDateHotelVacant = "";
				If vInBeds Then
					vDateHotelVacant = Format(vQryHotelByDates.BedsVacant, "NFD=0; NG=" + ?(vShowZeroes, "; NZ=", ""));
					If SelShowPreliminary And vQryHotelByDates.TentativeBeds <> 0 Then
						vDateHotelVacant = vDateHotelVacant + Chars.LF + Format(vQryHotelByDates.TentativeBeds, "NFD=0; NG=" + ?(vShowZeroes, "; NZ=", ""));
					EndIf;
				Else
					vDateHotelVacant = Format(vQryHotelByDates.RoomsVacant, "NFD=0; NG=" + ?(vShowZeroes, "; NZ=", ""));
					If SelShowPreliminary And vQryHotelByDates.TentativeRooms <> 0 Then
						vDateHotelVacant = vDateHotelVacant + Chars.LF + Format(vQryHotelByDates.TentativeRooms, "NFD=0; NG=" + ?(vShowZeroes, "; NZ=", ""));
					EndIf;
				EndIf;
				
				vHTDVArea.Parameters.mDateVacant = vDateHotelVacant;
				FillVacantDateDetails(vHTDVArea, vQryHotelByDates.Hotel, Undefined, Undefined, EndOfDay(vDate));
				vSpreadsheet.Join(vHTDVArea);
			EndDo;
		EndIf;
		vSpreadsheet.EndRowGroup();
		
		// Print events
		vEvents = cmGetEvents(SelPeriodFrom, SelPeriodTo, vCurHotel);
		If vEvents.Count() > 0 Then
			HeaderHeight = 7;
			vCommentIsPlaced = False;
			vEventsRow = Undefined;
			vSpreadsheet.Put(vEVTArea);
			For Each vQryHotelByDates In vQryHotelByDatesArray Do
				If vQryHotelByDates.PeriodDate < SelPeriodFrom Or vQryHotelByDates.PeriodDate > (SelPeriodTo - 24*3600) Then
					Continue;
				EndIf;
				vDate = vQryHotelByDates.PeriodDate;
				
				// Try to find event starting from this date
				vThisIsFirstPeriodOfEvent = False;
				vProbeEventsRow = vEvents.Find(vDate, "DateFrom");
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
				
				vEventArea = vSpreadsheet.Join(vEVDArea);
				
				vIsEventDate = False;
				If vEventsRow <> Undefined Then
					If vQryHotelByDates.PeriodDate > vEventsRow.DateTo Or vQryHotelByDates.PeriodDate < vEventsRow.DateFrom Then
						vEventsRow = Undefined;
					Else
						vIsEventDate = True;
					EndIf;
				EndIf;
				If vEventsRow <> Undefined And vIsEventDate Then
					If vThisIsFirstPeriodOfEvent Then
						vSpreadsheet.Area(vEventArea.Top, vEventArea.Left).Text = TrimAll(vEventsRow.Description);
					EndIf;
					If vEventsRow.DateTo = vDate And Not vCommentIsPlaced Then
						vCommentIsPlaced = True;
						vSpreadsheet.Area(vEventArea.Top, vEventArea.Right).Comment.Text = Chars.LF + Chars.LF + TrimAll(Format(vEventsRow.DateFrom, "DF=dd.MM.yyyy") + " - " + Format(vEventsRow.DateTo, "DF=dd.MM.yyyy") + Chars.LF +
						TrimAll(vEventsRow.Remarks));
					EndIf;
					vEventArea.Details = vEventsRow.Ref;
					vEventArea.TextPlacement = SpreadsheetDocumentTextPlacementType.Auto;
					vEventArea.BySelectedColumns = True;
					vEventArea.HorizontalAlign = HorizontalAlign.Left;
					vEventArea.VerticalAlign = VerticalAlign.Center;
					vEventColor = Undefined;
					If vEventsRow.Color <> Undefined Then
						vEventColor = vEventsRow.Color.Get();
					EndIf;
					vEventBackColor = EventBackColor;
					If vEventColor <> Undefined Then
						vEventBackColor = vEventColor;
					EndIf;
					vEventArea.BackColor = vEventBackColor;
					vEventArea.LeftBorder = New Line(SpreadsheetDocumentCellLineType.None, 1);
					If vEventsRow.DateTo > vQryHotelByDates.PeriodDate Then
						vEventArea.RightBorder = New Line(SpreadsheetDocumentCellLineType.None, 1);
					EndIf;
					If Not vThisIsFirstPeriodOfEvent Then
						vEventArea.Clear(True);
					EndIf;
				ElsIf Not vIsEventDate Then
					vEventArea.Text = " ";
					vEventArea.Details = Catalogs.Events.EmptyRef();
				EndIf;
			EndDo;
		EndIf;
		
		// By allotments
		vQryAllotmentsArray = vQryTblByHotelsAndAllotments.FindRows(New Structure("Hotel", vCurHotel));
		For Each vQryAllotments In vQryAllotmentsArray Do
			vCurRoomQuota = vQryAllotments.RoomQuota;
			If Not ValueIsFilled(vCurRoomQuota) Then
				Continue;
			EndIf;
			
			// By allotments and room types
			vQryRoomTypesArray = vQryResTblByAllotmentsAndRoomTypes.FindRows(New Structure("Hotel, RoomQuota", vCurHotel, vCurRoomQuota));
			If vQryRoomTypesArray.Count() = 0 Then
				Continue;
			EndIf;

			// Get number of rooms/beds per room type for first period date
			vTotalRoomsBeds = 0;
			vAllotmentFirstDateRows = vQryTblByAllotmentsAndDates.FindRows(New Structure("Hotel, RoomQuota, PeriodDate", vCurHotel, vCurRoomQuota, BegOfDay(SelPeriodFrom)));
			If vAllotmentFirstDateRows.Count() > 0 Then
				vAllotmentFirstDateRow = vAllotmentFirstDateRows.Get(0);
				vAllotmentFirstDateRowRoomQuota = vAllotmentFirstDateRow.RoomQuota;
				vTotalRoomsBeds = ?(vInBeds, vAllotmentFirstDateRow.TotalBeds, vAllotmentFirstDateRow.TotalRooms);
			EndIf;

			// Fill paramters and put allotment header
			vRQPArea.Parameters.mRoomQuotaStr = TrimAll(vCurRoomQuota);
			vRQPArea.Parameters.mRoomQuota = vCurRoomQuota;
			// Try to get data to calculate ADR for this allotment
			vADR = 0;
			vADRCurrency = vCurHotel.ReportingCurrency;
			If vCurRoomQuota.BudgetADR > 0 Then
				vADR = vCurRoomQuota.BudgetADR;
				If ValueIsFilled(vCurRoomQuota.BudgetCurrency) Then
					vADRCurrency = vCurRoomQuota.BudgetCurrency;
				EndIf;
			Else
				If vAllotmentADRs <> Undefined Then 
					vSalesRows = vAllotmentADRs.FindRows(New Structure("Hotel, RoomQuota", vCurHotel, vCurRoomQuota));
					If vSalesRows.Count() = 1 Then
						vSalesRow = vSalesRows.Get(0);
						If vSalesRow.RoomsRented <> 0 And vSalesRow.Sales <> 0 Then
							vADR = Round(vSalesRow.Sales/vSalesRow.RoomsRented, 2);
						EndIf;
					EndIf;
				EndIf;
				If vADR = 0 Then
					// Get planned ADR
					If vAllotmentPlannedADRs <> Undefined Then 
						vPlannedSalesRows = vAllotmentPlannedADRs.FindRows(New Structure("Hotel, RoomQuota", vCurHotel, vCurRoomQuota));
						If vPlannedSalesRows.Count() = 1 Then
							vPlannedSalesRow = vPlannedSalesRows.Get(0);
							If vPlannedSalesRow.RoomsRented <> 0 And vPlannedSalesRow.Sales <> 0 Then
								vADR = Round(vPlannedSalesRow.Sales/vPlannedSalesRow.RoomsRented, 2);
								vADRCurrency = vPlannedSalesRow.Currency;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			If vADR <> 0 Then
				vRQPArea.Parameters.mRoomQuotaStr = vRQPArea.Parameters.mRoomQuotaStr + " (ADR = " + cmFormatSum(vADR, vADRCurrency) + ")";
			EndIf;
			// Put allotment row
			vSpreadsheet.Put(vRQPArea);
			vSpreadsheet.StartRowGroup(NStr("en='Allotment';ru='Квота';de='Allotment'"), GetTotalsInitialOpenState(False, pGroupingStr, vCurHotel, vCurRoomQuota));
			// Iterate thru dates of allotment
			For Each vQryHotelByDates In vQryHotelByDatesArray Do
				If vQryHotelByDates.PeriodDate < SelPeriodFrom Or vQryHotelByDates.PeriodDate > (SelPeriodTo - 24*3600) Then
					Continue;
				EndIf;
				vDate = vQryHotelByDates.PeriodDate;

				vDateTotal = 0;
				
				vQryAllotmentByDatesArray = vQryTblByAllotmentsAndDates.FindRows(New Structure("Hotel, RoomQuota, PeriodDate", vCurHotel, vCurRoomQuota, vDate));
				If vQryAllotmentByDatesArray.Count() > 0 Then
					vQryAllotmentByDates = vQryAllotmentByDatesArray.Get(0);
					If vInBeds Then
						If SelMode = 2 Then
							vDateTotal = vQryAllotmentByDates.BedsForecast;
						Else
							If SelShowSelector = 0 Then
								vDateTotal = vQryAllotmentByDates.BedsInQuota;
							ElsIf SelShowSelector = 1 Then
								vDateTotal = vQryAllotmentByDates.InitialBedsInQuota;
							ElsIf SelShowSelector = 2 Then
								vDateTotal = vQryAllotmentByDates.BedsInQuota - vQryAllotmentByDates.InitialBedsInQuota;
							ElsIf SelShowSelector = 3 Then
								vDateTotal = vQryAllotmentByDates.BedsRemains;
							ElsIf SelShowSelector = 5 Then
								vDateTotal = vQryAllotmentByDates.BedsInQuota - vQryAllotmentByDates.BedsRemains;
							ElsIf SelShowSelector = 4 Then
								vDateTotal = 0;
							EndIf;
						EndIf;
					Else
						If SelMode = 2 Then
							vDateTotal = vQryAllotmentByDates.RoomsForecast;
						Else
							If SelShowSelector = 0 Then
								vDateTotal = vQryAllotmentByDates.RoomsInQuota;
							ElsIf SelShowSelector = 1 Then
								vDateTotal = vQryAllotmentByDates.InitialRoomsInQuota;
							ElsIf SelShowSelector = 2 Then
								vDateTotal = vQryAllotmentByDates.RoomsInQuota - vQryAllotmentByDates.InitialRoomsInQuota;
							ElsIf SelShowSelector = 3 Then
								vDateTotal = vQryAllotmentByDates.RoomsRemains;
							ElsIf SelShowSelector = 5 Then
								vDateTotal = vQryAllotmentByDates.RoomsInQuota - vQryAllotmentByDates.RoomsRemains;
							ElsIf SelShowSelector = 4 Then
								vDateTotal = 0;
							EndIf;
						EndIf;
					EndIf;
				EndIf;

				vRQDArea.Parameters.mDateTotal = Format(vDateTotal, "NFD=0; NG=" + ?(vShowZeroes, "; NZ=", ""));
				FillTotalsDateDetails(vRQDArea, vCurHotel, Undefined, vCurRoomQuota, EndOfDay(vDate));
				
				vSpreadsheet.Join(vRQDArea);
			EndDo;
			
			// Iterate through room types
			For Each vQryRoomTypes In vQryRoomTypesArray Do
				vCurRoomType = vQryRoomTypes.RoomType;
				vRTPArea.Parameters.mRoomTypeStr = TrimAll(vCurRoomType);
				If ValueIsFilled(vCurRoomType) Then
					vRTPArea.Parameters.mRoomType = vCurRoomType;
				EndIf;
				vArea = vSpreadsheet.Put(vRTPArea);
				
				// Iterate thru dates
				For Each vQryHotelByDates In vQryHotelByDatesArray Do
					If vQryHotelByDates.PeriodDate < SelPeriodFrom Or vQryHotelByDates.PeriodDate > (SelPeriodTo - 24*3600) Then
						Continue;
					EndIf;
					vDate = vQryHotelByDates.PeriodDate;
				
					vDateTotal = 0;

					vQryPeriodDatesArray = vQryResTblByAllotmentsRoomTypesAndDates.FindRows(New Structure("Hotel, RoomQuota, RoomType, PeriodDate", vCurHotel, vCurRoomQuota, vCurRoomType, vDate)); 
					If vQryPeriodDatesArray.Count() > 0 Then
						vQryPeriodDates = vQryPeriodDatesArray.Get(0);

						If vInBeds Then
							If SelMode = 2 Then
								vDateTotal = vQryPeriodDates.BedsForecast;
							Else
								If SelShowSelector = 0 Then
									vDateTotal = vQryPeriodDates.BedsInQuota;
								ElsIf SelShowSelector = 1 Then
									vDateTotal = vQryPeriodDates.InitialBedsInQuota;
								ElsIf SelShowSelector = 2 Then
									vDateTotal = vQryPeriodDates.BedsInQuota - vQryPeriodDates.InitialBedsInQuota;
								ElsIf SelShowSelector = 3 Then
									vDateTotal = vQryPeriodDates.BedsRemains;
								ElsIf SelShowSelector = 5 Then
									vDateTotal = vQryPeriodDates.BedsInQuota - vQryPeriodDates.BedsRemains;
								ElsIf SelShowSelector = 4 Then
									If vQryPeriodDates.BedsInQuota >  0 Then
										vDateTotal = GetAllotmentDatePrice(vCurRoomQuota, vCurRoomType, vDate, PriceNumberOfAdults);
									EndIf;
								EndIf;
							EndIf;
						Else
							If SelMode = 2 Then
								vDateTotal = vQryPeriodDates.RoomsForecast;
							Else
								If SelShowSelector = 0 Then
									vDateTotal = vQryPeriodDates.RoomsInQuota;
								ElsIf SelShowSelector = 1 Then
									vDateTotal = vQryPeriodDates.InitialRoomsInQuota;
								ElsIf SelShowSelector = 2 Then
									vDateTotal = vQryPeriodDates.RoomsInQuota - vQryPeriodDates.InitialRoomsInQuota;
								ElsIf SelShowSelector = 3 Then
									vDateTotal = vQryPeriodDates.RoomsRemains;
								ElsIf SelShowSelector = 5 Then
									vDateTotal = vQryPeriodDates.RoomsInQuota - vQryPeriodDates.RoomsRemains;
								ElsIf SelShowSelector = 4 Then
									If vQryPeriodDates.RoomsInQuota >  0 Then
										vDateTotal = GetAllotmentDatePrice(vCurRoomQuota, vCurRoomType, vDate, PriceNumberOfAdults);
									EndIf;
								EndIf;
							EndIf;
						EndIf;
					EndIf;

					// Just output total quantity
					If SelMode = 1 And SelShowSelector = 4 Then 
						vRTDArea.Parameters.mDateTotal = vDateTotal;
					Else
						vRTDArea.Parameters.mDateTotal = Format(vDateTotal, "NFD=0; NG=" + ?(vShowZeroes, "; NZ=", ""));
					EndIf;
					FillTotalsDateDetails(vRTDArea, vCurHotel, vCurRoomType, vCurRoomQuota, EndOfDay(vDate));
					vSpreadsheet.Join(vRTDArea);
				EndDo; // By dates

				If SelMode = 1 And SelShowVacants And SelRoomQuotas.Count() > 0 And ValueIsFilled(SelRoomQuotas.Get(0).Value) And Not SelRoomQuotas.Get(0).Value.IsFolder Then
					// Get number of rooms/beds per room type for first period date
					vTotalRoomsBeds = 0;
					vRoomTypeFirstDateRows = vQryResTblByAllotmentsRoomTypesAndDates.FindRows(New Structure("Hotel, RoomQuota, RoomType, PeriodDate", vCurHotel, Catalogs.RoomQuotas.EmptyRef(), vCurRoomType, BegOfDay(SelPeriodFrom)));
					If vRoomTypeFirstDateRows.Count() > 0 Then
						vRoomTypeFirstDateRow = vRoomTypeFirstDateRows.Get(0);
						If ValueIsFilled(vCurRoomType) And Not vCurRoomType.IsFolder Then
							If vCurRoomType.DoesNotAffectRoomRevenueStatistics Then
								vTotalRoomsBeds = ?(vInBeds, vRoomTypeFirstDateRow.TotalSpecialBeds, vRoomTypeFirstDateRow.TotalSpecialRooms);
							Else
								vTotalRoomsBeds = ?(vInBeds, vRoomTypeFirstDateRow.TotalBeds, vRoomTypeFirstDateRow.TotalRooms);
							EndIf;
						EndIf;
					EndIf;
					vRTPVArea.Parameters.mTotalRooms = "(" + Format(vTotalRoomsBeds, "NFD=0; NZ=; NG=") + ")";
					vArea = vSpreadsheet.Put(vRTPVArea);

					// Iterate thru dates
					For Each vQryHotelByDates In vQryHotelByDatesArray Do
						If vQryHotelByDates.PeriodDate < SelPeriodFrom Or vQryHotelByDates.PeriodDate > (SelPeriodTo - 24*3600) Then
							Continue;
						EndIf;
						vDate = vQryHotelByDates.PeriodDate;
					
						vDateVacant = "";
						vQryPeriodDatesArray = vQryResTblByAllotmentsRoomTypesAndDates.FindRows(New Structure("Hotel, RoomQuota, RoomType, PeriodDate", vCurHotel, Catalogs.RoomQuotas.EmptyRef(), vCurRoomType, vDate)); 
						If vQryPeriodDatesArray.Count() > 0 Then
							vQryPeriodDates = vQryPeriodDatesArray.Get(0);

							If vInBeds Then
								vDateVacant = Format(vQryPeriodDates.BedsVacant, "NFD=0; NG=" + ?(vShowZeroes, "; NZ=", ""));
								If SelShowPreliminary And vQryPeriodDates.TentativeBeds <> 0 Then
									vDateVacant = vDateVacant + Chars.LF + Format(vQryPeriodDates.TentativeBeds, "NFD=0; NG=" + ?(vShowZeroes, "; NZ=", ""));
								EndIf;
							Else
								vDateVacant = Format(vQryPeriodDates.RoomsVacant, "NFD=0; NG=" + ?(vShowZeroes, "; NZ=", ""));
								If SelShowPreliminary And vQryPeriodDates.TentativeRooms <> 0 Then
									vDateVacant = vDateVacant + Chars.LF + Format(vQryPeriodDates.TentativeRooms, "NFD=0; NG=" + ?(vShowZeroes, "; NZ=", ""));
								EndIf;
							EndIf;
						EndIf;

						// Just output total quantity
						vRTDVArea.Parameters.mDateVacant = vDateVacant;
						FillVacantDateDetails(vRTDVArea, vCurHotel, vCurRoomType, Undefined, EndOfDay(vDate));
						vSpreadsheet.Join(vRTDVArea);
					EndDo; // By dates
				EndIf;
			EndDo; // By room types
			
			vSpreadsheet.EndRowGroup();
		EndDo; // By allotment
		
		// Show hotel occupation pecent
		If SelShowOccupationPercent Then
			vHotelSales = GetHotelSales(vCurHotel);
			vSpreadsheet.Put(vOPTArea);
			
			// Iterate thru dates
			vQryHotelByDatesArray = vQryTblByHotelsAndDates.FindRows(New Structure("Hotel", vCurHotel));
			For Each vQryHotelByDates In vQryHotelByDatesArray Do
				If vQryHotelByDates.PeriodDate < SelPeriodFrom Or vQryHotelByDates.PeriodDate > (SelPeriodTo - 24*3600) Then
					Continue;
				EndIf;
				vDate = vQryHotelByDates.PeriodDate;
				
				// Find sales by date
				vHotelSalesRows = vHotelSales.FindRows(New Structure("Hotel, PeriodDate", vCurHotel, vDate));
				If vHotelSalesRows.Count() > 0 Then
					vHotelSalesRow = vHotelSalesRows.Get(0);
					If vInBeds Then
						vOccPrc = ?((vQryHotelByDates.TotalBeds - vQryHotelByDates.BedsBlocked) <= 0, 0, ?(SelShowPreliminary, vHotelSalesRow.BedsRented, vHotelSalesRow.DefiniteBedsRented) / (vQryHotelByDates.TotalBeds - vQryHotelByDates.BedsBlocked) * 100);
						vOPDArea.Parameters.mDateOccupancyPercentDetails = NStr("en='Beds: '; ru='Мест: '; de='Betten: '") + vQryHotelByDates.TotalBeds + NStr("en=', Blocked: '; ru=', Заблокировано: '; de=', Verstopft: '") + vQryHotelByDates.BedsBlocked + NStr("en=', Sold: '; ru=', Продано: '; de=', Verkauft: '") + vHotelSalesRow.BedsRented + NStr("en=', Occ. %: '; ru=', % продаж: '; de=', Occ. %: '") + Round(vOccPrc, 2);
					Else
						vOccPrc = ?((vQryHotelByDates.TotalRooms - vQryHotelByDates.RoomsBlocked) <= 0, 0, ?(SelShowPreliminary, vHotelSalesRow.RoomsRented, vHotelSalesRow.DefiniteRoomsRented) / (vQryHotelByDates.TotalRooms - vQryHotelByDates.RoomsBlocked) * 100);
						vOPDArea.Parameters.mDateOccupancyPercentDetails = NStr("en='Rooms: '; ru='Номеров: '; de='Zimmern: '") + vQryHotelByDates.TotalRooms + NStr("en=', Blocked: '; ru=', Заблокировано: '; de=', Verstopft: '") + vQryHotelByDates.RoomsBlocked + NStr("en=', Sold: '; ru=', Продано: '; de=', Verkauft: '") + vHotelSalesRow.RoomsRented + NStr("en=', Occ. %: '; ru=', % продаж: '; de=', Occ. %: '") + Round(vOccPrc, 2);
					EndIf;
					vOPDArea.Parameters.mDateOccupancyPercent = Format(Round(vOccPrc, 0), "NFD=0; NZ=; NG=") + "%";
				Else
					vOPDArea.Parameters.mDateOccupancyPercent = "0%";
					vOPDArea.Parameters.mDateOccupancyPercentDetails = Undefined;
				EndIf;
				vSpreadsheet.Join(vOPDArea);
			EndDo;
		EndIf;
	EndDo;
	
	// Draw report table footer
	vFPArea = vTemplate.GetArea("Footer|Duration");
	vSpreadsheet.Put(vFPArea);
	vFDArea = vTemplate.GetArea("Footer|Date");
	For Each vQryByDates In vQryTblByDates Do
		If vQryByDates.PeriodDate < SelPeriodFrom Or vQryByDates.PeriodDate > (SelPeriodTo - 24*3600) Then
			Continue;
		EndIf;
		vSpreadsheet.Join(vFDArea);
	EndDo;
	
	// Mark weekends
	i = 0;
	For Each vQryByDates In vQryTblByDates Do
		If vQryByDates.PeriodDate < SelPeriodFrom Or vQryByDates.PeriodDate > (SelPeriodTo - 24*3600) Then
			Continue;
		EndIf;
		If WeekDay(vQryByDates.PeriodDate) > 5 Then
			For j = 3 To vSpreadsheet.TableHeight Do
				vWeekendArea = vSpreadsheet.Area(j, 6 + i * 4, j, 9 + i * 4);
				vWeekendArea.Pattern = SpreadsheetDocumentPatternType.Pattern3;
				
				vWeekendArea.PatternColor = WeekendsPatternColor;
			EndDo;
		EndIf;
		i = i + 1;
	EndDo;		
	
	// Fix top N rows and 5 left columns
	If vEvents <> Undefined And vEvents.Count() > 0 Then
		vSpreadsheet.FixedTop = 7;
		vSpreadsheet.RepeatOnRowPrint = vSpreadsheet.Area(1, , 7);
	Else
		vSpreadsheet.FixedTop = 4;
		vSpreadsheet.RepeatOnRowPrint = vSpreadsheet.Area(1, , 4);
	EndIf;
	vSpreadsheet.FixedLeft = 5;
	vSpreadsheet.RepeatOnColumnPrint = vSpreadsheet.Area(, 1, , 5);
EndProcedure // GenerateTotals

// -----------------------------------------------------------------------------
Procedure FillCheckInPeriodDetails(pArea, pHotel, pRoomType, pRoomQuota, pPeriod, pCheckInDate = Undefined, pCheckOutDate = Undefined, pIsCheckInPeriod = False)
	If ValueIsFilled(pRoomQuota) Then
		pArea.Parameters.mDetails = New Structure("ReportName, Hotel, RoomQuota, RoomType, PeriodDate, CheckInDate, CheckOutDate, IsCheckInPeriod, RoomRate, RoomRateQ", 
		"RoomQuotaSales",
		pHotel, 
		pRoomQuota, 
		pRoomType, 
		pPeriod,
		pCheckInDate,
		pCheckOutDate, 
		pIsCheckInPeriod,
		pHotel.RoomRate,
		pRoomQuota.RoomRate);
	Else
		pArea.Parameters.mDetails = New Structure("ReportName, Hotel, RoomQuota, RoomType, PeriodDate, CheckInDate, CheckOutDate, IsCheckInPeriod, RoomRate, RoomRateQ", 
		"RoomInventory",
		pHotel, 
		pRoomQuota, 
		pRoomType,
		pPeriod,
		pCheckInDate,
		pCheckOutDate, 
		pIsCheckInPeriod,
		pHotel.RoomRate,
		pRoomQuota.RoomRate);
	EndIf;
EndProcedure // FillCheckInPeriodDetails

// -----------------------------------------------------------------------------
Function GetInitialOpenState(pDefault = True, pGroupingStr = Undefined, pHotel = Undefined, pRoomType = Undefined)
	If SelRoomQuotas.Count() > 0 Then
		Return True;
	ElsIf SelRoomTypes.Count() > 0 Then
		Return True;
	EndIf;
	If pGroupingStr = Undefined Then
		If ValueIsFilled(RoomType) And ValueIsFilled(pRoomType) And RoomType = pRoomType Then
			Return True;
		Else
			Return pDefault;
		EndIf;
	EndIf;
	vState = pDefault;
	If ValueIsFilled(pHotel) And ValueIsFilled(pGroupingStr.Hotel) Then
		If pGroupingStr.Hotel = pHotel Then
			If ValueIsFilled(pRoomType) And ValueIsFilled(pGroupingStr.RoomType) Then
				If pGroupingStr.RoomType = pRoomType Then
					vState = True;
				EndIf;
			Else
				vState = True;
			EndIf;
		EndIf;
	EndIf;
	Return vState;
EndFunction // GetInitialOpenState

// -----------------------------------------------------------------------------
Function GetTotalsInitialOpenState(pDefault = True, pGroupingStr = Undefined, pHotel = Undefined, pRoomQuota = Undefined)
	If SelRoomQuotas.Count() > 0 Then
		Return True;
	ElsIf SelRoomTypes.Count() > 0 Then
		Return True;
	EndIf;
	If pGroupingStr = Undefined Then
		If ValueIsFilled(RoomQuota) And ValueIsFilled(pRoomQuota) And RoomQuota = pRoomQuota Then
			Return True;
		Else
			Return pDefault;
		EndIf;
	EndIf;
	vState = pDefault;
	If ValueIsFilled(pHotel) And ValueIsFilled(pGroupingStr.Hotel) Then
		If pGroupingStr.Hotel = pHotel Then
			If ValueIsFilled(pRoomQuota) And ValueIsFilled(pGroupingStr.RoomQuota) Then
				If pGroupingStr.RoomQuota = pRoomQuota Then
					vState = True;
				EndIf;
			Else
				vState = True;
			EndIf;
		EndIf;
	EndIf;
	Return vState;
EndFunction // GetTotalsInitialOpenState

// -----------------------------------------------------------------------------
Function GetHotelSales(pHotel)
	// Build sales balances
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomSalesForecast.Hotel AS Hotel,
	|	RoomSalesForecast.Period AS Period,
	|	SUM(RoomSalesForecast.RoomsRentedTurnover) AS RoomsRentedTurnover,
	|	SUM(RoomSalesForecast.BedsRentedTurnover) AS BedsRentedTurnover,
	|	SUM(RoomSalesForecast.DefiniteRoomsRentedTurnover) AS DefiniteRoomsRentedTurnover,
	|	SUM(RoomSalesForecast.DefiniteBedsRentedTurnover) AS DefiniteBedsRentedTurnover
	|INTO RoomSalesForecastTurnovers
	|FROM
	|	(SELECT
	|		RoomSalesForecastTurnovers.Hotel AS Hotel,
	|		BEGINOFPERIOD(RoomSalesForecastTurnovers.Period, DAY) AS Period,
	|		RoomSalesForecastTurnovers.RoomQuota AS RoomQuota,
	|		RoomSalesForecastTurnovers.ParentDoc AS ParentDoc,
	|		RoomSalesForecastTurnovers.RoomsRentedTurnover AS RoomsRentedTurnover,
	|		RoomSalesForecastTurnovers.BedsRentedTurnover AS BedsRentedTurnover,
	|		CASE
	|			WHEN RoomSalesForecastTurnovers.ParentDoc = UNDEFINED
	|					AND RoomSalesForecastTurnovers.RoomQuota.AllotmentType <> VALUE(Enum.AllotmentTypes.Definite)
	|					AND RoomSalesForecastTurnovers.RoomQuota.AllotmentType <> VALUE(Enum.AllotmentTypes.DefiniteNotGuaranteed)
	|				THEN 0
	|			WHEN RoomSalesForecastTurnovers.ParentDoc <> UNDEFINED
	|					AND ISNULL(RoomSalesForecastTurnovers.ParentDoc.ReservationStatus.IsPreliminary, FALSE)
	|				THEN 0
	|			ELSE RoomSalesForecastTurnovers.RoomsRentedTurnover
	|		END AS DefiniteRoomsRentedTurnover,
	|		CASE
	|			WHEN RoomSalesForecastTurnovers.ParentDoc = UNDEFINED
	|					AND RoomSalesForecastTurnovers.RoomQuota.AllotmentType <> VALUE(Enum.AllotmentTypes.Definite)
	|					AND RoomSalesForecastTurnovers.RoomQuota.AllotmentType <> VALUE(Enum.AllotmentTypes.DefiniteNotGuaranteed)
	|				THEN 0
	|			WHEN RoomSalesForecastTurnovers.ParentDoc <> UNDEFINED
	|					AND ISNULL(RoomSalesForecastTurnovers.ParentDoc.ReservationStatus.IsPreliminary, FALSE)
	|				THEN 0
	|			ELSE RoomSalesForecastTurnovers.BedsRentedTurnover
	|		END AS DefiniteBedsRentedTurnover
	|	FROM
	|		AccumulationRegister.SalesForecast.Turnovers(
	|				&qForecastPeriodFrom,
	|				&qForecastPeriodTo,
	|				DAY,
	|				&qUseDataFromSales
	|					AND &qUseForecast
	|					AND Hotel IN HIERARCHY (&qHotel)
	|					AND (RoomType IN HIERARCHY (&qRoomTypes)
	|						OR &qRoomTypesAreEmpty)) AS RoomSalesForecastTurnovers) AS RoomSalesForecast
	|
	|GROUP BY
	|	RoomSalesForecast.Hotel,
	|	RoomSalesForecast.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventoryBalance.Hotel AS Hotel,
	|	BEGINOFPERIOD(RoomInventoryBalance.Period, DAY) AS PeriodDate,
	|	CASE
	|		WHEN &qUseDataFromSales
	|			THEN ISNULL(RoomSales.RoomsRented, 0) + ISNULL(RoomSalesForecast.RoomsRented, 0) + ISNULL(CommitmentAllotments.RoomsRemains, 0)
	|		ELSE -RoomInventoryBalance.RoomsReservedClosingBalance - RoomInventoryBalance.InHouseRoomsClosingBalance + ISNULL(BusinessBlocks.RoomsRemains, 0) + ISNULL(CommitmentAllotments.RoomsRemains, 0)
	|	END AS RoomsRented,
	|	CASE
	|		WHEN &qUseDataFromSales
	|			THEN ISNULL(RoomSales.BedsRented, 0) + ISNULL(RoomSalesForecast.BedsRented, 0) + ISNULL(CommitmentAllotments.BedsRemains, 0)
	|		ELSE -RoomInventoryBalance.BedsReservedClosingBalance - RoomInventoryBalance.InHouseBedsClosingBalance + ISNULL(BusinessBlocks.BedsRemains, 0) + ISNULL(CommitmentAllotments.BedsRemains, 0)
	|	END AS BedsRented,
	|	CASE
	|		WHEN &qUseDataFromSales
	|			THEN ISNULL(RoomSales.RoomsRented, 0) + ISNULL(RoomSalesForecast.DefiniteRoomsRented, 0) + ISNULL(CommitmentAllotments.RoomsRemains, 0)
	|		ELSE -RoomInventoryBalance.RoomsReservedClosingBalance - RoomInventoryBalance.InHouseRoomsClosingBalance + ISNULL(DefiniteBusinessBlocks.RoomsRemains, 0) + ISNULL(CommitmentAllotments.RoomsRemains, 0)
	|	END AS DefiniteRoomsRented,
	|	CASE
	|		WHEN &qUseDataFromSales
	|			THEN ISNULL(RoomSales.BedsRented, 0) + ISNULL(RoomSalesForecast.DefiniteBedsRented, 0) + ISNULL(CommitmentAllotments.BedsRemains, 0)
	|		ELSE -RoomInventoryBalance.BedsReservedClosingBalance - RoomInventoryBalance.InHouseBedsClosingBalance + ISNULL(DefiniteBusinessBlocks.BedsRemains, 0) + ISNULL(CommitmentAllotments.BedsRemains, 0)
	|	END AS DefiniteBedsRented,
	|	RoomInventoryBalance.TotalRoomsClosingBalance AS TotalRooms,
	|	RoomInventoryBalance.TotalBedsClosingBalance AS TotalBeds,
	|	-RoomInventoryBalance.RoomsBlockedClosingBalance AS RoomsBlocked,
	|	-RoomInventoryBalance.BedsBlockedClosingBalance AS BedsBlocked,
	|	-RoomInventoryBalance.RoomsReservedClosingBalance AS RoomsReserved,
	|	-RoomInventoryBalance.BedsReservedClosingBalance AS BedsReserved,
	|	-RoomInventoryBalance.InHouseRoomsClosingBalance AS InHouseRooms,
	|	-RoomInventoryBalance.InHouseBedsClosingBalance AS InHouseBeds,
	|	RoomInventoryBalance.CounterClosingBalance AS Counter
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			DAY,
	|			RegisterRecordsAndPeriodBoundaries,
	|			Hotel IN HIERARCHY (&qHotel)
	|				AND (RoomType IN HIERARCHY (&qRoomTypes)
	|					OR &qRoomTypesAreEmpty)) AS RoomInventoryBalance
	|		LEFT JOIN (SELECT
	|			RoomSalesTurnovers.Hotel AS Hotel,
	|			BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY) AS Period,
	|			RoomSalesTurnovers.RoomsRentedTurnover AS RoomsRented,
	|			RoomSalesTurnovers.BedsRentedTurnover AS BedsRented
	|		FROM
	|			AccumulationRegister.Sales.Turnovers(
	|					&qSalesPeriodFrom,
	|					&qSalesPeriodTo,
	|					DAY,
	|					&qUseDataFromSales
	|						AND Hotel IN HIERARCHY (&qHotel)
	|						AND (RoomType IN HIERARCHY (&qRoomTypes)
	|							OR &qRoomTypesAreEmpty)) AS RoomSalesTurnovers) AS RoomSales
	|		ON (BEGINOFPERIOD(RoomInventoryBalance.Period, DAY) = RoomSales.Period)
	|			AND RoomInventoryBalance.Hotel = RoomSales.Hotel
	|		LEFT JOIN (SELECT
	|			RoomSalesForecastTurnovers.Hotel AS Hotel,
	|			RoomSalesForecastTurnovers.Period AS Period,
	|			RoomSalesForecastTurnovers.RoomsRentedTurnover AS RoomsRented,
	|			RoomSalesForecastTurnovers.BedsRentedTurnover AS BedsRented,
	|			RoomSalesForecastTurnovers.DefiniteRoomsRentedTurnover AS DefiniteRoomsRented,
	|			RoomSalesForecastTurnovers.DefiniteBedsRentedTurnover AS DefiniteBedsRented
	|		FROM
	|			RoomSalesForecastTurnovers AS RoomSalesForecastTurnovers) AS RoomSalesForecast
	|		ON (BEGINOFPERIOD(RoomInventoryBalance.Period, DAY) = RoomSalesForecast.Period)
	|			AND RoomInventoryBalance.Hotel = RoomSalesForecast.Hotel
	|		LEFT JOIN (SELECT
	|			CommitmentAllotmentsBalanceAndTurnovers.Hotel AS Hotel,
	|			BEGINOFPERIOD(CommitmentAllotmentsBalanceAndTurnovers.Period, DAY) AS Period,
	|			CommitmentAllotmentsBalanceAndTurnovers.RoomsRemainsClosingBalance AS RoomsRemains,
	|			CommitmentAllotmentsBalanceAndTurnovers.BedsRemainsClosingBalance AS BedsRemains,
	|			CommitmentAllotmentsBalanceAndTurnovers.CounterClosingBalance AS Counter
	|		FROM
	|			AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
	|					&qPeriodFrom,
	|					&qPeriodTo,
	|					DAY,
	|					RegisterRecordsAndPeriodBoundaries,
	|					&qTakeCommitmentIntoAccount
	|						AND Hotel IN HIERARCHY (&qHotel)
	|						AND (RoomType IN HIERARCHY (&qRoomTypes)
	|							OR &qRoomTypesAreEmpty)
	|						AND RoomQuota.IsCommitment
	|						AND RoomQuota.AllotmentBusinessType <> VALUE(Enum.AllotmentBusinessTypes.BusinessBlock)
	|						AND (&qUseDataFromSales
	|							OR NOT &qUseDataFromSales
	|								AND NOT RoomQuota.DoWriteOff)) AS CommitmentAllotmentsBalanceAndTurnovers) AS CommitmentAllotments
	|		ON (BEGINOFPERIOD(RoomInventoryBalance.Period, DAY) = CommitmentAllotments.Period)
	|			AND RoomInventoryBalance.Hotel = CommitmentAllotments.Hotel
	|		LEFT JOIN (SELECT
	|			BusinessBlocksBalanceAndTurnovers.Hotel AS Hotel,
	|			BEGINOFPERIOD(BusinessBlocksBalanceAndTurnovers.Period, DAY) AS Period,
	|			BusinessBlocksBalanceAndTurnovers.RoomsRemainsClosingBalance AS RoomsRemains,
	|			BusinessBlocksBalanceAndTurnovers.BedsRemainsClosingBalance AS BedsRemains,
	|			BusinessBlocksBalanceAndTurnovers.CounterClosingBalance AS Counter
	|		FROM
	|			AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
	|					&qPeriodFrom,
	|					&qPeriodTo,
	|					DAY,
	|					RegisterRecordsAndPeriodBoundaries,
	|					NOT &qUseDataFromSales
	|						AND Hotel IN HIERARCHY (&qHotel)
	|						AND (RoomType IN HIERARCHY (&qRoomTypes)
	|							OR &qRoomTypesAreEmpty)
	|						AND RoomQuota.AllotmentBusinessType = VALUE(Enum.AllotmentBusinessTypes.BusinessBlock)
	|						AND RoomQuota.AllotmentType <> VALUE(Enum.AllotmentTypes.DoNotChangeAvailability)
	|						AND RoomQuota.AllotmentType <> VALUE(Enum.AllotmentTypes.Cancelled)
	|						AND NOT &qUseDataFromSales) AS BusinessBlocksBalanceAndTurnovers) AS BusinessBlocks
	|		ON (BEGINOFPERIOD(RoomInventoryBalance.Period, DAY) = BusinessBlocks.Period)
	|			AND RoomInventoryBalance.Hotel = BusinessBlocks.Hotel
	|		LEFT JOIN (SELECT
	|			BusinessBlocksBalanceAndTurnovers.Hotel AS Hotel,
	|			BEGINOFPERIOD(BusinessBlocksBalanceAndTurnovers.Period, DAY) AS Period,
	|			BusinessBlocksBalanceAndTurnovers.RoomsRemainsClosingBalance AS RoomsRemains,
	|			BusinessBlocksBalanceAndTurnovers.BedsRemainsClosingBalance AS BedsRemains,
	|			BusinessBlocksBalanceAndTurnovers.CounterClosingBalance AS Counter
	|		FROM
	|			AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
	|					&qPeriodFrom,
	|					&qPeriodTo,
	|					DAY,
	|					RegisterRecordsAndPeriodBoundaries,
	|					NOT &qUseDataFromSales
	|						AND Hotel IN HIERARCHY (&qHotel)
	|						AND (RoomType IN HIERARCHY (&qRoomTypes)
	|							OR &qRoomTypesAreEmpty)
	|						AND RoomQuota.AllotmentBusinessType = VALUE(Enum.AllotmentBusinessTypes.BusinessBlock)
	|						AND (RoomQuota.AllotmentType = VALUE(Enum.AllotmentTypes.Definite)
	|							OR RoomQuota.AllotmentType = VALUE(Enum.AllotmentTypes.DefiniteNotGuaranteed))
	|						AND NOT &qUseDataFromSales) AS BusinessBlocksBalanceAndTurnovers) AS DefiniteBusinessBlocks
	|		ON (BEGINOFPERIOD(RoomInventoryBalance.Period, DAY) = DefiniteBusinessBlocks.Period)
	|			AND RoomInventoryBalance.Hotel = DefiniteBusinessBlocks.Hotel
	|
	|ORDER BY
	|	RoomInventoryBalance.Hotel.Code,
	|	PeriodDate";
	vQry.SetParameter("qUseDataFromSales", True);
	vQry.SetParameter("qTakeCommitmentIntoAccount", True);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qRoomTypes", SelRoomTypes);
	vQry.SetParameter("qRoomTypesAreEmpty", ?(SelRoomTypes.Count() = 0, True, False));
	vPeriodFrom = BegOfDay(SelPeriodFrom) - 24*3600;
	vPeriodTo = EndOfDay(SelPeriodTo) + 24*3600;
	vQry.SetParameter("qPeriodFrom", vPeriodFrom);
	vQry.SetParameter("qPeriodTo", vPeriodTo);
	vQry.SetParameter("qSalesPeriodFrom", BegOfDay(vPeriodFrom));
	vQry.SetParameter("qSalesPeriodTo", EndOfDay(vPeriodTo));
	vForecastPeriodFrom = Max(tcOnServer.GetForecastStartDate(pHotel), vPeriodFrom);
	vForecastPeriodTo = vPeriodTo;
	If BegOfDay(vForecastPeriodFrom) > BegOfDay(vForecastPeriodTo) Then
		vForecastPeriodTo = EndOfDay(vForecastPeriodFrom);
		vQry.SetParameter("qUseForecast", False);
	Else
		vQry.SetParameter("qUseForecast", True);
	EndIf;
	vQry.SetParameter("qForecastPeriodFrom", vForecastPeriodFrom);
	vQry.SetParameter("qForecastPeriodTo", vForecastPeriodTo);
	Return vQry.Execute().Unload();
EndFunction // GetHotelSales

// -----------------------------------------------------------------------------
Procedure FillDateDetails(pArea, pHotel, pRoomType, pRoomQuota, pPeriod, pCheckInDate = Undefined, pCheckOutDate = Undefined)
	pArea.Parameters.mDetails = New Structure("ReportName, Hotel, RoomQuota, RoomType, IsLeft, PeriodDate, CheckInDate, CheckOutDate, IsCheckInPeriod", 
												"RoomQuotaSales",
												pHotel, 
												pRoomQuota, 
												pRoomType, 
												False,
												pPeriod,
												pCheckInDate,
												pCheckOutDate, 
												False);
	pArea.Parameters.mDetailsLeft = New Structure("ReportName, Hotel, RoomQuota, RoomType, IsLeft, PeriodDate, CheckInDate, CheckOutDate, IsCheckInPeriod", 
													"RoomQuotaSales",
													pHotel, 
													pRoomQuota, 
													pRoomType, 
													True,
													pPeriod,
													pCheckInDate,
													pCheckOutDate, 
													False);
	pArea.Parameters.mVacantDetails = New Structure("ReportName, Hotel, RoomQuota, RoomType, IsLeft, PeriodDate, CheckInDate, CheckOutDate, IsCheckInPeriod", 
													"RoomInventory",
													pHotel, 
													pRoomQuota, 
													pRoomType,
													False,
													pPeriod,
													pCheckInDate,
													pCheckOutDate, 
													False);
	pArea.Parameters.mVacantDetailsLeft = New Structure("ReportName, Hotel, RoomQuota, RoomType, IsLeft, PeriodDate, CheckInDate, CheckOutDate, IsCheckInPeriod", 
														"RoomInventory",
														pHotel, 
														pRoomQuota, 
														pRoomType,
														True,
														pPeriod,
														pCheckInDate,
														pCheckOutDate, 
														False);
EndProcedure // FillDateDetails

// -----------------------------------------------------------------------------
Procedure FillTotalsDateDetails(pArea, pHotel, pRoomType, pRoomQuota, pPeriod, pCheckInDate = Undefined, pCheckOutDate = Undefined)
	pArea.Parameters.mDetails = New Structure("ReportName, Hotel, RoomQuota, RoomType, IsLeft, PeriodDate, CheckInDate, CheckOutDate, IsCheckInPeriod", 
												"RoomQuotaSales",
												pHotel, 
												pRoomQuota, 
												pRoomType, 
												False,
												pPeriod,
												pCheckInDate,
												pCheckOutDate, 
												False);
EndProcedure // FillTotalsDateDetails

// -----------------------------------------------------------------------------
Procedure FillVacantDateDetails(pArea, pHotel, pRoomType, pRoomQuota, pPeriod, pCheckInDate = Undefined, pCheckOutDate = Undefined)
	pArea.Parameters.mVacantDetails = New Structure("ReportName, Hotel, RoomQuota, RoomType, IsLeft, PeriodDate, CheckInDate, CheckOutDate, IsCheckInPeriod", 
												"RoomInventory",
												pHotel, 
												pRoomQuota, 
												pRoomType, 
												False,
												pPeriod,
												pCheckInDate,
												pCheckOutDate, 
												False);
EndProcedure // FillVacantDateDetails

// -----------------------------------------------------------------------------
Function GetDocumentColor(pMappedDocsRow)
	If pMappedDocsRow.GuestGroupColor <> Null And pMappedDocsRow.GuestGroupColor <> Undefined Then
		vDocColor = pMappedDocsRow.GuestGroupColor.Get();
	EndIf;
	If vDocColor = Undefined Then 
		If pMappedDocsRow.RoomQuotaColor <> Null And pMappedDocsRow.RoomQuotaColor <> Undefined Then
			vDocColor = pMappedDocsRow.RoomQuotaColor.Get();
		EndIf;
	EndIf;
	If vDocColor = Undefined Then 
		If pMappedDocsRow.ContractColor <> Null And pMappedDocsRow.ContractColor <> Undefined Then
			vDocColor = pMappedDocsRow.ContractColor.Get();
		EndIf;
	EndIf;
	If vDocColor = Undefined Then 
		If pMappedDocsRow.AgentColor <> Null And pMappedDocsRow.AgentColor <> Undefined Then
			vDocColor = pMappedDocsRow.AgentColor.Get();
		EndIf;
	EndIf;
	If vDocColor = Undefined Then 
		If pMappedDocsRow.CustomerColor <> Null And pMappedDocsRow.CustomerColor <> Undefined Then
			vDocColor = pMappedDocsRow.CustomerColor.Get();
		EndIf;
	EndIf;
	If vDocColor = Undefined Then 
		If pMappedDocsRow.StatusColor <> Null And pMappedDocsRow.StatusColor <> Undefined Then
			vDocColor = pMappedDocsRow.StatusColor.Get();
		EndIf;
	EndIf;
	If vDocColor = Undefined Then 
		If pMappedDocsRow.ClientTypeColor <> Null And pMappedDocsRow.ClientTypeColor <> Undefined Then
			vDocColor = pMappedDocsRow.ClientTypeColor.Get();
		EndIf;
	EndIf;
	If vDocColor = Undefined Then
		If TypeOf(pMappedDocsRow.Doc) = Type("DocumentRef.Accommodation") Then
			vDocColor = AccommodationColor;
		Else
			vDocColor = ReservationColor;
		EndIf;
	EndIf;
	Return vDocColor;
EndFunction // GetDocumentColor

// -----------------------------------------------------------------------------
Function MapReservations(pDocs, pDates)
	// Initialize mapping value table
	vMappedDocs = New ValueTable();
	vMappedDocs.Columns.Add("PeriodDate", cmGetDateTypeDescription());
	vMappedDocs.Columns.Add("Hotel", cmGetCatalogTypeDescription("Hotels"));
	vMappedDocs.Columns.Add("HotelSortCode", cmGetNumberTypeDescription(12, 0));
	vMappedDocs.Columns.Add("HotelDescription", cmGetStringTypeDescription());
	vMappedDocs.Columns.Add("RoomType", cmGetCatalogTypeDescription("RoomTypes"));
	vMappedDocs.Columns.Add("RoomTypeSortCode", cmGetNumberTypeDescription(12, 0));
	vMappedDocs.Columns.Add("RoomTypeDescription", cmGetStringTypeDescription());
	vMappedDocs.Columns.Add("RoomQuota", cmGetCatalogTypeDescription("RoomQuotas"));
	vMappedDocs.Columns.Add("RoomQuotaSortCode", cmGetNumberTypeDescription(12, 0));
	vMappedDocs.Columns.Add("RoomQuotaDescription", cmGetStringTypeDescription());
	vMappedDocs.Columns.Add("RoomQuotaColor");
	vMappedDocs.Columns.Add("RoomCounter", cmGetNumberTypeDescription(12, 0));
	vMappedDocs.Columns.Add("Doc");
	vMappedDocs.Columns.Add("GuestGroup", cmGetCatalogTypeDescription("GuestGroups"));
	vMappedDocs.Columns.Add("GuestGroupCode", cmGetNumberTypeDescription(12, 0));
	vMappedDocs.Columns.Add("GuestGroupDescription", cmGetStringTypeDescription());
	vMappedDocs.Columns.Add("GuestGroupColor");
	vMappedDocs.Columns.Add("StatusColor");
	vMappedDocs.Columns.Add("CustomerColor");
	vMappedDocs.Columns.Add("ContractColor");
	vMappedDocs.Columns.Add("AgentColor");
	vMappedDocs.Columns.Add("ClientTypeColor");
	vMappedDocs.Columns.Add("Customer", cmGetCatalogTypeDescription("Customers"));
	vMappedDocs.Columns.Add("CustomerDescription", cmGetStringTypeDescription());
	vMappedDocs.Columns.Add("Guest", cmGetCatalogTypeDescription("Clients"));
	vMappedDocs.Columns.Add("GuestDescription", cmGetStringTypeDescription());
	vMappedDocs.Columns.Add("GuestFullName", cmGetStringTypeDescription());
	vMappedDocs.Columns.Add("CreateDate", cmGetDateTimeTypeDescription());
	vMappedDocs.Columns.Add("CheckInDate", cmGetDateTimeTypeDescription());
	vMappedDocs.Columns.Add("Duration", cmGetNumberTypeDescription(12, 0));
	vMappedDocs.Columns.Add("CheckOutDate", cmGetDateTimeTypeDescription());
	vMappedDocs.Columns.Add("BegOfCheckInDate", cmGetDateTypeDescription());
	vMappedDocs.Columns.Add("BegOfCheckOutDate", cmGetDateTypeDescription());
	vMappedDocs.Columns.Add("LastCheckOutDate", cmGetDateTimeTypeDescription());
	vMappedDocs.Columns.Add("OccupiedRooms", cmGetNumberTypeDescription(12, 0));
	vMappedDocs.Columns.Add("OccupiedBeds", cmGetNumberTypeDescription(12, 0));
	vMappedDocs.Columns.Add("IsLeft", cmGetBooleanTypeDescription());
	vMappedDocs.Columns.Add("IsRight", cmGetBooleanTypeDescription());
	vMappedDocs.Columns.Add("IsMiddle", cmGetBooleanTypeDescription());
	vDocIndex1 = vMappedDocs.Indexes.Add("Doc");
	vDocIndex2 = vMappedDocs.Indexes.Add("RoomType, RoomQuota, RoomCounter");
	vDocIndex3 = vMappedDocs.Indexes.Add("RoomType, RoomQuota, PeriodDate, RoomCounter");
	// Fill mapping value table
	For Each vDatesRow In pDates Do
		vCurDate = vDatesRow.PeriodDate;
		For Each vDocsRow In pDocs Do
			If vCurDate < vDocsRow.BegOfCheckInDate Or vCurDate > vDocsRow.BegOfCheckOutDate Then
				Continue;
			EndIf;
			// Try to find previous mapping row for this document
			vDocRows = vMappedDocs.FindRows(New Structure("Doc", vDocsRow.Doc));
			If vDocRows.Count() > 0 Then
				vLastMappedRow = vDocRows.Get(vDocRows.Count() - 1);
				vLastMappedRowIndex = vMappedDocs.IndexOf(vLastMappedRow);
				vMappedRow = vMappedDocs.Insert(vLastMappedRowIndex + 1);
				vMappedRow.PeriodDate = vCurDate;
				FillPropertyValues(vMappedRow, vDocsRow);
				vMappedRow.RoomCounter = vLastMappedRow.RoomCounter;
				If vCurDate = vDocsRow.BegOfCheckinDate Then
					vMappedRow.IsRight = True;
				ElsIf vCurDate < vDocsRow.BegOfCheckOutDate Then
					vMappedRow.IsMiddle = True;
				ElsIf vCurDate = vDocsRow.BegOfCheckOutDate And vDocsRow.BegOfCheckinDate < vDocsRow.BegOfCheckOutDate Then
					vMappedRow.IsLeft = True;
				EndIf;
			Else
				// Get array of mapped rows for the given day, room type and allotment
				vMappedRows = vMappedDocs.FindRows(New Structure("RoomType, RoomQuota, PeriodDate", vDocsRow.RoomType, vDocsRow.RoomQuota, vCurDate));
				If vMappedRows.Count() = 0 Then
					vPrevDayMappedRows = vMappedDocs.FindRows(New Structure("RoomType, RoomQuota, RoomCounter", vDocsRow.RoomType, vDocsRow.RoomQuota, 1));
					If vPrevDayMappedRows.Count() > 0 Then
						vLastMappedRowIndex = vMappedDocs.IndexOf(vPrevDayMappedRows.Get(vPrevDayMappedRows.Count() - 1));
						vMappedRow = vMappedDocs.Insert(vLastMappedRowIndex + 1);
					Else
						vMappedRow = vMappedDocs.Add();
					EndIf;
					vMappedRow.PeriodDate = vCurDate;
					FillPropertyValues(vMappedRow, vDocsRow);
					vMappedRow.RoomCounter = 1;
					If vCurDate = vDocsRow.BegOfCheckinDate Then
						vMappedRow.IsRight = True;
					ElsIf vCurDate < vDocsRow.BegOfCheckOutDate Then
						vMappedRow.IsMiddle = True;
					ElsIf vCurDate = vDocsRow.BegOfCheckOutDate And vDocsRow.BegOfCheckinDate < vDocsRow.BegOfCheckOutDate Then
						vMappedRow.IsLeft = True;
					EndIf;
				Else
					vLastUsedRoom = 0;
					vAddNew = True;
					For Each vMappedRow In vMappedRows Do
						If (vMappedRow.RoomCounter - vLastUsedRoom) > 1 Then
							Break;
						EndIf;
						vLastUsedRoom = vMappedRow.RoomCounter;
						If vMappedRow.LastCheckOutDate < vDocsRow.CheckInDate And vCurDate = vDocsRow.BegOfCheckInDate  Then
							FillPropertyValues(vMappedRow, vDocsRow, , "IsLeft, IsRight, IsMiddle");
							vMappedRow.IsRight = True;
							vAddNew = False;
							Break;
						EndIf;
					EndDo;
					If vAddNew Then
						vPrevDayMappedRows = vMappedDocs.FindRows(New Structure("RoomType, RoomQuota, RoomCounter", vDocsRow.RoomType, vDocsRow.RoomQuota, vLastUsedRoom + 1));
						If vPrevDayMappedRows.Count() > 0 Then
							vLastMappedRowIndex = vMappedDocs.IndexOf(vPrevDayMappedRows.Get(vPrevDayMappedRows.Count() - 1));
							vMappedRow = vMappedDocs.Insert(vLastMappedRowIndex + 1);
						Else
							vPrevCounterMappedRows = vMappedDocs.FindRows(New Structure("RoomType, RoomQuota, RoomCounter", vDocsRow.RoomType, vDocsRow.RoomQuota, vLastUsedRoom));
							If vPrevCounterMappedRows.Count() > 0 Then
								vLastMappedRowIndex = vMappedDocs.IndexOf(vPrevCounterMappedRows.Get(vPrevCounterMappedRows.Count() - 1));
								vMappedRow = vMappedDocs.Insert(vLastMappedRowIndex + 1);
							Else
								vMappedRow = vMappedDocs.Add();
							EndIf;
						EndIf;
						vMappedRow.PeriodDate = vCurDate;
						FillPropertyValues(vMappedRow, vDocsRow);
						vMappedRow.RoomCounter = vLastUsedRoom + 1;
						If vCurDate = vDocsRow.BegOfCheckinDate Then
							vMappedRow.IsRight = True;
						ElsIf vCurDate < vDocsRow.BegOfCheckOutDate Then
							vMappedRow.IsMiddle = True;
						ElsIf vCurDate = vDocsRow.BegOfCheckOutDate And vDocsRow.BegOfCheckinDate < vDocsRow.BegOfCheckOutDate Then
							vMappedRow.IsLeft = True;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	// Return
	Return vMappedDocs;
EndFunction // MapReservations

// -----------------------------------------------------------------------------
Function GetReportParametersPresentation()
	vParamPresentation = "";
	If ValueIsFilled(SelRoomRate) Then
		If Not SelRoomRate.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Room rate ';ru='Тариф ';de='Tarif '") + 
			TrimAll(SelRoomRate.Description) + 
			"; ";
		Else
			vParamPresentation = vParamPresentation + NStr("en='Room rates folder ';ru='Группа тарифов ';de='Gruppe Tarife '") + 
			TrimAll(SelRoomRate.Description) + 
			"; ";
		EndIf;
	EndIf;					 
	If ValueIsFilled(SelAgent) Then
		If Not SelAgent.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Agent ';ru='Агент ';de='Vertreter '") + 
			TrimAll(SelAgent.Description) + 
			"; ";
		Else
			vParamPresentation = vParamPresentation + NStr("en='Agents folder ';ru='Группа агентов ';de='Gruppe Vertreter '") + 
			TrimAll(SelAgent.Description) + 
			"; ";
		EndIf;
	EndIf;							 
	If ValueIsFilled(SelCustomer) Then
		If Not SelCustomer.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("de='Firma';en='Customer ';ru='Контрагент '") + 
			TrimAll(SelCustomer.Description) + 
			"; ";
		Else
			vParamPresentation = vParamPresentation + NStr("de='Gruppe Firmen';en='Customers folder ';ru='Группа контрагентов '") + 
			TrimAll(SelCustomer.Description) + 
			"; ";
		EndIf;
	EndIf;							 
	If ValueIsFilled(SelContract) Then
		vParamPresentation = vParamPresentation + NStr("en='Contract ';ru='Договор ';de='Vertrag '") + 
		TrimAll(SelContract.Description) + 
		"; ";
	EndIf;							 
	If SelRoomQuotas.Count() = 1 And ValueIsFilled(SelRoomQuotas.Get(0).Value) Then
		vSelRoomQuota = SelRoomQuotas.Get(0).Value;
		If Not vSelRoomQuota.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Allotment ';ru='Квота ';de='Quote '") + 
			TrimAll(vSelRoomQuota.Description) + 
			"; ";
		Else
			vParamPresentation = vParamPresentation + NStr("en='Allotments folder ';ru='Группа квот ';de='Gruppe Quoten '") + 
			TrimAll(vSelRoomQuota.Description) + 
			"; ";
		EndIf;
	ElsIf SelRoomQuotas.Count() > 0 Then
		vParamPresentation = vParamPresentation + NStr("en='Allotment ';ru='Квота ';de='Quote '") + 
		TrimAll(SelRoomQuotas) + 
		"; ";
	EndIf;					 
	If SelRoomTypes.Count() = 1 And ValueIsFilled(SelRoomTypes.Get(0).Value) Then
		vSelRoomType = SelRoomTypes.Get(0).Value;
		If Not vSelRoomType.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Room type ';ru='Тип номера ';de='Zimmertyp '") + 
			TrimAll(vSelRoomType.Description) + 
			"; ";
		Else
			vParamPresentation = vParamPresentation + NStr("en='Room types folder ';ru='Группа типов номеров ';de='Gruppe Zimmertypen '") + 
			TrimAll(vSelRoomType.Description) + 
			"; ";
		EndIf;
	ElsIf SelRoomTypes.Count() > 0 Then
		vParamPresentation = vParamPresentation + NStr("en='Room type ';ru='Тип номера ';de='Zimmertyp '") + 
		TrimAll(SelRoomTypes) + 
		"; ";
	EndIf;					 
	If ValueIsFilled(SelStatus) Then
		vParamPresentation = vParamPresentation + NStr("en='Status ';ru='Статус ';de='Status '") + 
		TrimAll(SelStatus) + 
		"; ";
	EndIf;							 
	If ValueIsFilled(SelAllotmentBusinessType) Then
		vParamPresentation = vParamPresentation + NStr("en='Allotment type ';ru='Тип квоты ';de='Allotmenttyp '") + 
		TrimAll(SelAllotmentBusinessType) + 
		"; ";
	EndIf;							 
	Return TrimAll(vParamPresentation);
EndFunction // GetReportParametersPresentation

// -----------------------------------------------------------------------------
Function GetReservations()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	InventoryRecords.Recorder AS Doc,
	|	InventoryRecords.GuestGroup AS GuestGroup,
	|	InventoryRecords.GuestGroup.Code AS GuestGroupCode,
	|	InventoryRecords.GuestGroup.Description AS GuestGroupDescription,
	|	InventoryRecords.GuestGroup.CreateDate AS CreateDate,
	|	InventoryRecords.GuestGroup.Color AS GuestGroupColor,
	|	InventoryRecords.ReservationStatus.Color AS StatusColor,
	|	InventoryRecords.Customer.Color AS CustomerColor,
	|	InventoryRecords.Contract.Color AS ContractColor,
	|	InventoryRecords.Agent.Color AS AgentColor,
	|	InventoryRecords.ClientType.Color AS ClientTypeColor,
	|	InventoryRecords.Customer AS Customer,
	|	InventoryRecords.Customer.Description AS CustomerDescription,
	|	InventoryRecords.Guest AS Guest,
	|	InventoryRecords.Guest.Description AS GuestDescription,
	|	InventoryRecords.Guest.FullName AS GuestFullName,
	|	InventoryRecords.Hotel AS Hotel,
	|	InventoryRecords.Hotel.Description AS HotelDescription,
	|	InventoryRecords.Hotel.SortCode AS HotelSortCode,
	|	CASE
	|		WHEN InventoryRecords.RoomTypeUpgrade.BaseRoomType = InventoryRecords.RoomType
	|			THEN InventoryRecords.RoomTypeUpgrade
	|		ELSE InventoryRecords.RoomType
	|	END AS RoomType,
	|	CASE
	|		WHEN InventoryRecords.RoomTypeUpgrade.BaseRoomType = InventoryRecords.RoomType
	|			THEN InventoryRecords.RoomTypeUpgrade.Description
	|		ELSE InventoryRecords.RoomType.Description
	|	END AS RoomTypeDescription,
	|	CASE
	|		WHEN InventoryRecords.RoomTypeUpgrade.BaseRoomType = InventoryRecords.RoomType
	|			THEN InventoryRecords.RoomTypeUpgrade.SortCode
	|		ELSE InventoryRecords.RoomType.SortCode
	|	END AS RoomTypeSortCode,
	|	InventoryRecords.RoomQuota AS RoomQuota,
	|	InventoryRecords.RoomQuota.Description AS RoomQuotaDescription,
	|	InventoryRecords.RoomQuota.SortCode AS RoomQuotaSortCode,
	|	InventoryRecords.RoomQuota.Color AS RoomQuotaColor,
	|	InventoryRecords.PeriodFrom AS CheckInDate,
	|	InventoryRecords.PeriodDuration AS Duration,
	|	InventoryRecords.PeriodTo AS CheckOutDate,
	|	InventoryRecords.RoomRate AS RoomRate,
	|	InventoryRecords.CheckInAccountingDate AS BegOfCheckInDate,
	|	InventoryRecords.CheckOutAccountingDate AS BegOfCheckOutDate,
	|	InventoryRecords.RoomsVacant AS OccupiedRooms,
	|	InventoryRecords.BedsVacant AS OccupiedBeds,
	|	InventoryRecords.PeriodTo AS LastCheckOutDate,
	|	FALSE AS IsLeft,
	|	FALSE AS IsRight,
	|	FALSE AS IsMiddle
	|FROM
	|	AccumulationRegister.RoomInventory AS InventoryRecords
	|WHERE
	|	InventoryRecords.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND (InventoryRecords.IsReservation
	|			OR InventoryRecords.IsAccommodation)
	|	AND InventoryRecords.PeriodFrom = InventoryRecords.Period
	|	AND InventoryRecords.PeriodFrom < &qPeriodTo
	|	AND InventoryRecords.PeriodTo > &qPeriodFrom
	|	AND (InventoryRecords.Hotel IN HIERARCHY (&qHotel)
	|			OR &qHotelIsEmpty)
	|	AND (InventoryRecords.RoomType IN HIERARCHY (&qRoomTypes)
	|			OR &qRoomTypesAreEmpty)
	|	AND (InventoryRecords.RoomQuota IN HIERARCHY (&qRoomQuotas)
	|			OR &qRoomQuotasAreEmpty
	|			OR InventoryRecords.RoomQuota = &qBaseRoomQuota
	|				AND &qBaseRoomQuotaIsFilled)
	|	AND (InventoryRecords.RoomQuota.AllotmentType = &qStatus
	|			OR &qStatusIsEmpty)
	|	AND (InventoryRecords.RoomQuota.AllotmentBusinessType = &qAllotmentBusinessType
	|			OR &qAllotmentBusinessTypeIsEmpty)
	|	AND (InventoryRecords.RoomRate IN HIERARCHY (&qRoomRate)
	|			OR &qRoomRateIsEmpty)
	|	AND (InventoryRecords.Customer IN HIERARCHY (&qCustomer)
	|			OR &qCustomerIsEmpty)
	|	AND (InventoryRecords.Agent IN HIERARCHY (&qAgent)
	|			OR &qAgentIsEmpty)
	|	AND (InventoryRecords.Contract = &qContract
	|			OR &qContractIsEmpty)
	|	AND InventoryRecords.RoomsVacant <> 0
	|
	|ORDER BY
	|	HotelSortCode,
	|	HotelDescription,
	|	RoomTypeSortCode,
	|	RoomTypeDescription,
	|	RoomQuotaSortCode,
	|	RoomQuotaDescription,
	|	CheckInDate,
	|	CheckOutDate";
	vQry.SetParameter("qHotel", SelHotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(SelHotel));
	vQry.SetParameter("qRoomRate", SelRoomRate);
	vQry.SetParameter("qRoomRateIsEmpty", Not ValueIsFilled(SelRoomRate));
	vQry.SetParameter("qRoomTypes", SelRoomTypes);
	vQry.SetParameter("qRoomTypesAreEmpty", ?(SelRoomTypes.Count() = 0, True, False));
	vQry.SetParameter("qCustomer", SelCustomer);
	vQry.SetParameter("qCustomerIsEmpty", Not ValueIsFilled(SelCustomer));
	vQry.SetParameter("qContract", SelContract);
	vQry.SetParameter("qContractIsEmpty", Not ValueIsFilled(SelContract));
	vQry.SetParameter("qAgent", SelAgent);
	vQry.SetParameter("qAgentIsEmpty", Not ValueIsFilled(SelAgent));
	vQry.SetParameter("qRoomQuotas", SelRoomQuotas);
	vQry.SetParameter("qRoomQuotasAreEmpty", ?(SelRoomQuotas.Count() = 0, True, False));
	If SelRoomQuotas.Count() = 1 And ValueIsFilled(SelRoomQuotas.Get(0).Value) And Not SelRoomQuotas.Get(0).Value.IsFolder Then
		vSelRoomQuota = SelRoomQuotas.Get(0).Value;
		If ValueIsFilled(vSelRoomQuota.BaseRoomQuota) And Not vSelRoomQuota.BaseRoomQuota.IsFolder Then
			vQry.SetParameter("qBaseRoomQuota", vSelRoomQuota.BaseRoomQuota);
			vQry.SetParameter("qBaseRoomQuotaIsFilled", True);
		Else
			vQry.SetParameter("qBaseRoomQuota", Catalogs.RoomQuotas.EmptyRef());
			vQry.SetParameter("qBaseRoomQuotaIsFilled", False);
		EndIf;
	Else
		vQry.SetParameter("qBaseRoomQuota", Catalogs.RoomQuotas.EmptyRef());
		vQry.SetParameter("qBaseRoomQuotaIsFilled", False);
	EndIf;
	vQry.SetParameter("qPeriodFrom", BegOfDay(SelPeriodFrom) - 24 * 3600);
	vQry.SetParameter("qPeriodTo", EndOfDay(SelPeriodTo) + 24 * 3600);
	vQry.SetParameter("qStatus", SelStatus);
	vQry.SetParameter("qStatusIsEmpty", Not ValueIsFilled(SelStatus));
	vQry.SetParameter("qAllotmentBusinessType", SelAllotmentBusinessType);
	vQry.SetParameter("qAllotmentBusinessTypeIsEmpty", Not ValueIsFilled(SelAllotmentBusinessType));
	Return vQry.Execute().Unload();
EndFunction // GetReservations

// -----------------------------------------------------------------------------
Function GetCheckInPeriodsBalances(pTempTablesManager)
	vQry = New Query();
	vQry.TempTablesManager = pTempTablesManager;
	vQry.Text = 
	"SELECT
	|	BalancesByDates.PeriodDate AS PeriodDate,
	|	BalancesByDates.Hotel AS Hotel,
	|	BalancesByDates.HotelDescription AS HotelDescription,
	|	BalancesByDates.HotelSortCode AS HotelSortCode,
	|	BalancesByDates.RoomType AS RoomType,
	|	BalancesByDates.RoomTypeDescription AS RoomTypeDescription,
	|	BalancesByDates.RoomTypeSortCode AS RoomTypeSortCode,
	|	BalancesByDates.RoomQuota AS RoomQuota,
	|	BalancesByDates.RoomQuotaDescription AS RoomQuotaDescription,
	|	BalancesByDates.RoomQuotaSortCode AS RoomQuotaSortCode,
	|	ISNULL(CheckInPeriods.Duration, 1) AS Duration,
	|	ISNULL(CheckInPeriods.CheckInDate, DATEADD(BalancesByDates.PeriodDate, SECOND, &qCheckInHourSeconds)) AS CheckInDate,
	|	ISNULL(CheckInPeriods.CheckOutDate, DATEADD(BalancesByDates.PeriodDate, SECOND, &qNextDayCheckInHourSeconds)) AS CheckOutDate,
	|	BalancesByDates.RoomsVacant AS RoomsVacant,
	|	BalancesByDates.BedsVacant AS BedsVacant,
	|	BalancesByDates.SpecialRoomsVacant AS SpecialRoomsVacant,
	|	BalancesByDates.SpecialBedsVacant AS SpecialBedsVacant,
	|	BalancesByDates.RoomsInQuota AS RoomsInQuota,
	|	BalancesByDates.BedsInQuota AS BedsInQuota,
	|	BalancesByDates.RoomsRemains AS RoomsRemains,
	|	BalancesByDates.BedsRemains AS BedsRemains
	|FROM
	|	BalancesByDates AS BalancesByDates
	|		LEFT JOIN CheckInPeriods AS CheckInPeriods
	|		ON BalancesByDates.Hotel = CheckInPeriods.Hotel
	|			AND BalancesByDates.RoomQuota = CheckInPeriods.RoomQuota
	|			AND BalancesByDates.PeriodDate >= CheckInPeriods.BegOfCheckInDate
	|			AND BalancesByDates.PeriodDate < CheckInPeriods.BegOfCheckOutDate
	|WHERE
	|	(BalancesByDates.Hotel IN HIERARCHY (&qHotel)
	|			OR &qHotelIsEmpty)
	|	AND (BalancesByDates.RoomType IN HIERARCHY (&qRoomTypes)
	|			OR &qRoomTypesAreEmpty)
	|	AND (BalancesByDates.RoomQuota IN HIERARCHY (&qRoomQuotas)
	|			OR &qRoomQuotasAreEmpty
	|			OR BalancesByDates.RoomQuota = &qBaseRoomQuota
	|				AND &qBaseRoomQuotaIsFilled)
	|	AND (BalancesByDates.RoomQuota.AllotmentBusinessType = &qAllotmentBusinessType
	|			OR &qAllotmentBusinessTypeIsEmpty)
	|	AND (BalancesByDates.RoomQuota.AllotmentType = &qStatus
	|			OR &qStatusIsEmpty)
	|
	|ORDER BY
	|	HotelSortCode,
	|	HotelDescription,
	|	RoomTypeSortCode,
	|	RoomTypeDescription,
	|	RoomQuotaSortCode,
	|	RoomQuotaDescription,
	|	CheckInDate,
	|	CheckOutDate,
	|	PeriodDate";
	vQry.SetParameter("qHotel", SelHotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(SelHotel));
	vQry.SetParameter("qRoomTypes", SelRoomTypes);
	vQry.SetParameter("qRoomTypesAreEmpty", ?(SelRoomTypes.Count() = 0, True, False));
	vQry.SetParameter("qCustomer", SelCustomer);
	vQry.SetParameter("qCustomerIsEmpty", Not ValueIsFilled(SelCustomer));
	vQry.SetParameter("qContract", SelContract);
	vQry.SetParameter("qContractIsEmpty", Not ValueIsFilled(SelContract));
	vQry.SetParameter("qAgent", SelAgent);
	vQry.SetParameter("qAgentIsEmpty", Not ValueIsFilled(SelAgent));
	vQry.SetParameter("qRoomQuotas", SelRoomQuotas);
	vQry.SetParameter("qRoomQuotasAreEmpty", ?(SelRoomQuotas.Count() = 0, True, False));
	If SelRoomQuotas.Count() = 1 And ValueIsFilled(SelRoomQuotas.Get(0).Value) And Not SelRoomQuotas.Get(0).Value.IsFolder Then
		vSelRoomQuota = SelRoomQuotas.Get(0).Value;
		If ValueIsFilled(vSelRoomQuota.BaseRoomQuota) And Not vSelRoomQuota.BaseRoomQuota.IsFolder Then
			vQry.SetParameter("qBaseRoomQuota", vSelRoomQuota.BaseRoomQuota);
			vQry.SetParameter("qBaseRoomQuotaIsFilled", True);
		Else
			vQry.SetParameter("qBaseRoomQuota", Catalogs.RoomQuotas.EmptyRef());
			vQry.SetParameter("qBaseRoomQuotaIsFilled", False);
		EndIf;
	Else
		vQry.SetParameter("qBaseRoomQuota", Catalogs.RoomQuotas.EmptyRef());
		vQry.SetParameter("qBaseRoomQuotaIsFilled", False);
	EndIf;
	vQry.SetParameter("qPeriodFrom", BegOfDay(SelPeriodFrom) - 24 * 3600);
	vQry.SetParameter("qPeriodTo", EndOfDay(SelPeriodTo) + 24 * 3600);
	vRefHour = cmGetReferenceHour(SelHotel.RoomRate);
	vCheckInHourSeconds = vRefHour - BegOfDay(vRefHour);
	vQry.SetParameter("qCheckInHourSeconds", vCheckInHourSeconds + 1);
	vQry.SetParameter("qNextDayCheckInHourSeconds", vCheckInHourSeconds + (24 * 3600));
	vQry.SetParameter("qStatus", SelStatus);
	vQry.SetParameter("qStatusIsEmpty", Not ValueIsFilled(SelStatus));
	vQry.SetParameter("qAllotmentBusinessType", SelAllotmentBusinessType);
	vQry.SetParameter("qAllotmentBusinessTypeIsEmpty", Not ValueIsFilled(SelAllotmentBusinessType));
	Return vQry.Execute().Unload();
EndFunction // GetCheckInPeriodsBalances

// -----------------------------------------------------------------------------
Function GetVacantCombinations(pTempTablesManager)
	// Build value table of vacant combinations
	vQry = New Query();
	vQry.TempTablesManager = pTempTablesManager;
	vQry.Text = 
	"SELECT
	|	BalancesByDates.Hotel AS Hotel,
	|	BalancesByDates.RoomType AS RoomType,
	|	BalancesByDates.RoomQuota AS RoomQuota,
	|	MAX(BalancesByDates.BedsVacant) AS MaxBedsVacant,
	|	MAX(BalancesByDates.BedsRemains) AS MaxBedsRemains
	|FROM
	|	BalancesByDates AS BalancesByDates
	|WHERE
	|	BalancesByDates.PeriodDate >= &qPeriodFrom
	|	AND BalancesByDates.PeriodDate <= &qPeriodTo
	|
	|GROUP BY
	|	BalancesByDates.Hotel,
	|	BalancesByDates.RoomType,
	|	BalancesByDates.RoomQuota
	|
	|HAVING
	|	(MAX(BalancesByDates.BedsVacant) > 0
	|			AND BalancesByDates.RoomQuota = &qEmptyRoomQuota
	|		OR MAX(BalancesByDates.BedsRemains) > 0
	|			AND BalancesByDates.RoomQuota <> &qEmptyRoomQuota)";
	vQry.SetParameter("qEmptyRoomQuota", Catalogs.RoomQuotas.EmptyRef());
	vQry.SetParameter("qPeriodFrom", BegOfDay(SelPeriodFrom));
	vQry.SetParameter("qPeriodTo", BegOfDay(SelPeriodTo));
	Return vQry.Execute().Unload();
EndFunction // GetVacantCombinations

// -----------------------------------------------------------------------------
Function GetRoomTypePeriodsBalances(pTempTablesManager)
	// Build room inventory and allotment balances
	vQry = New Query();
	vQry.TempTablesManager = pTempTablesManager;
	vQry.Text = 
	"SELECT
	|	BEGINOFPERIOD(RoomInventoryBalances.Period, DAY) AS PeriodDate,
	|	RoomInventoryBalances.Hotel AS Hotel,
	|	RoomInventoryBalances.RoomType AS RoomType,
	|	MAX(ISNULL(RoomInventoryBalances.CounterClosingBalance, 0)) AS CounterClosingBalance,
	|	MIN(ISNULL(RoomInventoryBalances.RoomsVacantClosingBalance, 0)) AS RoomsVacant,
	|	MIN(ISNULL(RoomInventoryBalances.BedsVacantClosingBalance, 0)) AS BedsVacant,
	|	MIN(CASE
	|			WHEN ISNULL(RoomInventoryBalances.RoomType.DoesNotAffectRoomRevenueStatistics, FALSE)
	|				THEN ISNULL(RoomInventoryBalances.RoomsVacantClosingBalance, 0)
	|			ELSE 0
	|		END) AS SpecialRoomsVacant,
	|	MIN(CASE
	|			WHEN ISNULL(RoomInventoryBalances.RoomType.DoesNotAffectRoomRevenueStatistics, FALSE)
	|				THEN ISNULL(RoomInventoryBalances.BedsVacantClosingBalance, 0)
	|			ELSE 0
	|		END) AS SpecialBedsVacant,
	|	MIN(ISNULL(RoomInventoryBalances.TotalRoomsClosingBalance, 0)) AS TotalRooms,
	|	MIN(ISNULL(RoomInventoryBalances.TotalBedsClosingBalance, 0)) AS TotalBeds,
	|	MIN(ISNULL(RoomInventoryBalances.TotalSpecialRoomsClosingBalance, 0)) AS TotalSpecialRooms,
	|	MIN(ISNULL(RoomInventoryBalances.TotalSpecialBedsClosingBalance, 0)) AS TotalSpecialBeds,
	|	MAX(-ISNULL(RoomInventoryBalances.RoomsBlockedClosingBalance, 0)) AS RoomsBlocked,
	|	MAX(-ISNULL(RoomInventoryBalances.BedsBlockedClosingBalance, 0)) AS BedsBlocked
	|INTO RoomInventoryForThePast
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|			&qPeriodFromForThePast,
	|			&qPeriodToForThePast,
	|			DAY,
	|			RegisterRecordsAndPeriodBoundaries,
	|			&qUsePast
	|				AND (Hotel IN HIERARCHY (&qHotel)
	|					OR &qHotelIsEmpty)
	|				AND (RoomType IN HIERARCHY (&qRoomTypes)
	|					OR &qRoomTypesAreEmpty)
	|				AND NOT RoomType.IsVirtual
	|				AND NOT RoomType.DeletionMark) AS RoomInventoryBalances
	|WHERE
	|	BEGINOFPERIOD(RoomInventoryBalances.Period, DAY) < &qCurrentDate
	|
	|GROUP BY
	|	BEGINOFPERIOD(RoomInventoryBalances.Period, DAY),
	|	RoomInventoryBalances.Hotel,
	|	RoomInventoryBalances.RoomType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BEGINOFPERIOD(DATEADD(RoomInventoryBalances.Period, SECOND, &qShiftInSeconds), DAY) AS PeriodDate,
	|	RoomInventoryBalances.Hotel AS Hotel,
	|	RoomInventoryBalances.RoomType AS RoomType,
	|	MAX(ISNULL(RoomInventoryBalances.CounterClosingBalance, 0)) AS CounterClosingBalance,
	|	MIN(ISNULL(RoomInventoryBalances.RoomsVacantClosingBalance, 0)) AS RoomsVacant,
	|	MIN(ISNULL(RoomInventoryBalances.BedsVacantClosingBalance, 0)) AS BedsVacant,
	|	MIN(CASE
	|			WHEN ISNULL(RoomInventoryBalances.RoomType.DoesNotAffectRoomRevenueStatistics, FALSE)
	|				THEN ISNULL(RoomInventoryBalances.RoomsVacantClosingBalance, 0)
	|			ELSE 0
	|		END) AS SpecialRoomsVacant,
	|	MIN(CASE
	|			WHEN ISNULL(RoomInventoryBalances.RoomType.DoesNotAffectRoomRevenueStatistics, FALSE)
	|				THEN ISNULL(RoomInventoryBalances.BedsVacantClosingBalance, 0)
	|			ELSE 0
	|		END) AS SpecialBedsVacant,
	|	MIN(ISNULL(RoomInventoryBalances.TotalRoomsClosingBalance, 0)) AS TotalRooms,
	|	MIN(ISNULL(RoomInventoryBalances.TotalBedsClosingBalance, 0)) AS TotalBeds,
	|	MIN(ISNULL(RoomInventoryBalances.TotalSpecialRoomsClosingBalance, 0)) AS TotalSpecialRooms,
	|	MIN(ISNULL(RoomInventoryBalances.TotalSpecialBedsClosingBalance, 0)) AS TotalSpecialBeds,
	|	MAX(-ISNULL(RoomInventoryBalances.RoomsBlockedClosingBalance, 0)) AS RoomsBlocked,
	|	MAX(-ISNULL(RoomInventoryBalances.BedsBlockedClosingBalance, 0)) AS BedsBlocked
	|INTO RoomInventoryForToday
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|			&qPeriodFromForToday,
	|			&qPeriodToForToday,
	|			Minute,
	|			RegisterRecordsAndPeriodBoundaries,
	|			&qUseToday
	|				AND (Hotel IN HIERARCHY (&qHotel)
	|					OR &qHotelIsEmpty)
	|				AND (RoomType IN HIERARCHY (&qRoomTypes)
	|					OR &qRoomTypesAreEmpty)
	|				AND NOT RoomType.IsVirtual
	|				AND NOT RoomType.DeletionMark) AS RoomInventoryBalances
	|WHERE
	|	BEGINOFPERIOD(DATEADD(RoomInventoryBalances.Period, SECOND, &qShiftInSeconds), DAY) = &qCurrentDate
	|
	|GROUP BY
	|	BEGINOFPERIOD(DATEADD(RoomInventoryBalances.Period, SECOND, &qShiftInSeconds), DAY),
	|	RoomInventoryBalances.Hotel,
	|	RoomInventoryBalances.RoomType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BEGINOFPERIOD(DATEADD(RoomInventoryBalances.Period, SECOND, &qShiftInSeconds), DAY) AS PeriodDate,
	|	RoomInventoryBalances.Hotel AS Hotel,
	|	RoomInventoryBalances.RoomType AS RoomType,
	|	MAX(ISNULL(RoomInventoryBalances.CounterClosingBalance, 0)) AS CounterClosingBalance,
	|	MIN(ISNULL(RoomInventoryBalances.RoomsVacantClosingBalance, 0)) AS RoomsVacant,
	|	MIN(ISNULL(RoomInventoryBalances.BedsVacantClosingBalance, 0)) AS BedsVacant,
	|	MIN(CASE
	|			WHEN ISNULL(RoomInventoryBalances.RoomType.DoesNotAffectRoomRevenueStatistics, FALSE)
	|				THEN ISNULL(RoomInventoryBalances.RoomsVacantClosingBalance, 0)
	|			ELSE 0
	|		END) AS SpecialRoomsVacant,
	|	MIN(CASE
	|			WHEN ISNULL(RoomInventoryBalances.RoomType.DoesNotAffectRoomRevenueStatistics, FALSE)
	|				THEN ISNULL(RoomInventoryBalances.BedsVacantClosingBalance, 0)
	|			ELSE 0
	|		END) AS SpecialBedsVacant,
	|	MIN(ISNULL(RoomInventoryBalances.TotalRoomsClosingBalance, 0)) AS TotalRooms,
	|	MIN(ISNULL(RoomInventoryBalances.TotalBedsClosingBalance, 0)) AS TotalBeds,
	|	MIN(ISNULL(RoomInventoryBalances.TotalSpecialRoomsClosingBalance, 0)) AS TotalSpecialRooms,
	|	MIN(ISNULL(RoomInventoryBalances.TotalSpecialBedsClosingBalance, 0)) AS TotalSpecialBeds,
	|	MAX(-ISNULL(RoomInventoryBalances.RoomsBlockedClosingBalance, 0)) AS RoomsBlocked,
	|	MAX(-ISNULL(RoomInventoryBalances.BedsBlockedClosingBalance, 0)) AS BedsBlocked
	|INTO RoomInventoryForTheFuture
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|			&qPeriodFromForTheFuture,
	|			&qPeriodToForTheFuture,
	|			Minute,
	|			RegisterRecordsAndPeriodBoundaries,
	|			&qUseFuture
	|				AND (Hotel IN HIERARCHY (&qHotel)
	|					OR &qHotelIsEmpty)
	|				AND (RoomType IN HIERARCHY (&qRoomTypes)
	|					OR &qRoomTypesAreEmpty)
	|				AND NOT RoomType.IsVirtual
	|				AND NOT RoomType.DeletionMark) AS RoomInventoryBalances
	|WHERE
	|	BEGINOFPERIOD(DATEADD(RoomInventoryBalances.Period, SECOND, &qShiftInSeconds), DAY) > &qCurrentDate
	|
	|GROUP BY
	|	BEGINOFPERIOD(DATEADD(RoomInventoryBalances.Period, SECOND, &qShiftInSeconds), DAY),
	|	RoomInventoryBalances.Hotel,
	|	RoomInventoryBalances.RoomType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventoryBalances.PeriodDate AS PeriodDate,
	|	RoomInventoryBalances.Hotel AS Hotel,
	|	RoomInventoryBalances.Hotel.Description AS HotelDescription,
	|	RoomInventoryBalances.Hotel.SortCode AS HotelSortCode,
	|	RoomInventoryBalances.RoomType AS RoomType,
	|	RoomInventoryBalances.RoomType.Description AS RoomTypeDescription,
	|	RoomInventoryBalances.RoomType.SortCode AS RoomTypeSortCode,
	|	&qEmptyRoomQuota AS RoomQuota,
	|	&qEmptyString AS RoomQuotaDescription,
	|	0 AS RoomQuotaSortCode,
	|	RoomInventoryBalances.CounterClosingBalance AS CounterClosingBalance,
	|	RoomInventoryBalances.RoomsVacant AS RoomsVacant,
	|	RoomInventoryBalances.BedsVacant AS BedsVacant,
	|	RoomInventoryBalances.SpecialRoomsVacant AS SpecialRoomsVacant,
	|	RoomInventoryBalances.SpecialBedsVacant AS SpecialBedsVacant,
	|	RoomInventoryBalances.TotalRooms AS TotalRooms,
	|	RoomInventoryBalances.TotalBeds AS TotalBeds,
	|	RoomInventoryBalances.TotalSpecialRooms AS TotalSpecialRooms,
	|	RoomInventoryBalances.TotalSpecialBeds AS TotalSpecialBeds,
	|	RoomInventoryBalances.RoomsBlocked AS RoomsBlocked,
	|	RoomInventoryBalances.BedsBlocked AS BedsBlocked
	|INTO RoomInventoryBalances
	|FROM
	|	(SELECT
	|		RoomInventoryForThePast.PeriodDate AS PeriodDate,
	|		RoomInventoryForThePast.Hotel AS Hotel,
	|		RoomInventoryForThePast.RoomType AS RoomType,
	|		RoomInventoryForThePast.CounterClosingBalance AS CounterClosingBalance,
	|		RoomInventoryForThePast.RoomsVacant AS RoomsVacant,
	|		RoomInventoryForThePast.BedsVacant AS BedsVacant,
	|		RoomInventoryForThePast.SpecialRoomsVacant AS SpecialRoomsVacant,
	|		RoomInventoryForThePast.SpecialBedsVacant AS SpecialBedsVacant,
	|		RoomInventoryForThePast.TotalRooms AS TotalRooms,
	|		RoomInventoryForThePast.TotalBeds AS TotalBeds,
	|		RoomInventoryForThePast.TotalSpecialRooms AS TotalSpecialRooms,
	|		RoomInventoryForThePast.TotalSpecialBeds AS TotalSpecialBeds,
	|		RoomInventoryForThePast.RoomsBlocked AS RoomsBlocked,
	|		RoomInventoryForThePast.BedsBlocked AS BedsBlocked
	|	FROM
	|		RoomInventoryForThePast AS RoomInventoryForThePast
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RoomInventoryForToday.PeriodDate,
	|		RoomInventoryForToday.Hotel,
	|		RoomInventoryForToday.RoomType,
	|		RoomInventoryForToday.CounterClosingBalance,
	|		RoomInventoryForToday.RoomsVacant,
	|		RoomInventoryForToday.BedsVacant,
	|		RoomInventoryForToday.SpecialRoomsVacant,
	|		RoomInventoryForToday.SpecialBedsVacant,
	|		RoomInventoryForToday.TotalRooms,
	|		RoomInventoryForToday.TotalBeds,
	|		RoomInventoryForToday.TotalSpecialRooms,
	|		RoomInventoryForToday.TotalSpecialBeds,
	|		RoomInventoryForToday.RoomsBlocked,
	|		RoomInventoryForToday.BedsBlocked
	|	FROM
	|		RoomInventoryForToday AS RoomInventoryForToday
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RoomInventoryForTheFuture.PeriodDate,
	|		RoomInventoryForTheFuture.Hotel,
	|		RoomInventoryForTheFuture.RoomType,
	|		RoomInventoryForTheFuture.CounterClosingBalance,
	|		RoomInventoryForTheFuture.RoomsVacant,
	|		RoomInventoryForTheFuture.BedsVacant,
	|		RoomInventoryForTheFuture.SpecialRoomsVacant,
	|		RoomInventoryForTheFuture.SpecialBedsVacant,
	|		RoomInventoryForTheFuture.TotalRooms,
	|		RoomInventoryForTheFuture.TotalBeds,
	|		RoomInventoryForTheFuture.TotalSpecialRooms,
	|		RoomInventoryForTheFuture.TotalSpecialBeds,
	|		RoomInventoryForTheFuture.RoomsBlocked,
	|		RoomInventoryForTheFuture.BedsBlocked
	|	FROM
	|		RoomInventoryForTheFuture AS RoomInventoryForTheFuture) AS RoomInventoryBalances
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllotmentBalances.Period AS PeriodDate,
	|	AllotmentBalances.Hotel AS Hotel,
	|	AllotmentBalances.Hotel.Description AS HotelDescription,
	|	AllotmentBalances.Hotel.SortCode AS HotelSortCode,
	|	AllotmentBalances.RoomType AS RoomType,
	|	AllotmentBalances.RoomType.Description AS RoomTypeDescription,
	|	AllotmentBalances.RoomType.SortCode AS RoomTypeSortCode,
	|	AllotmentBalances.RoomQuota AS RoomQuota,
	|	AllotmentBalances.RoomQuota.Description AS RoomQuotaDescription,
	|	AllotmentBalances.RoomQuota.SortCode AS RoomQuotaSortCode,
	|	AllotmentBalances.CounterClosingBalance AS CounterClosingBalance,
	|	AllotmentBalances.RoomsInQuotaClosingBalance AS RoomsInQuota,
	|	AllotmentBalances.BedsInQuotaClosingBalance AS BedsInQuota,
	|	AllotmentBalances.RoomsRemainsClosingBalance AS RoomsRemains,
	|	AllotmentBalances.BedsRemainsClosingBalance AS BedsRemains
	|INTO AllotmentBalances
	|FROM
	|	AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			DAY,
	|			RegisterRecordsAndPeriodBoundaries,
	|			RoomQuota <> &qEmptyRoomQuota
	|				AND (Hotel IN HIERARCHY (&qHotel)
	|					OR &qHotelIsEmpty)
	|				AND (RoomType IN HIERARCHY (&qRoomTypes)
	|					OR &qRoomTypesAreEmpty)
	|				AND NOT RoomType.IsVirtual
	|				AND NOT RoomType.DeletionMark
	|				AND (RoomQuota IN HIERARCHY (&qRoomQuotas)
	|					OR &qRoomQuotasAreEmpty
	|					OR RoomQuota = &qBaseRoomQuota
	|						AND &qBaseRoomQuotaIsFilled)
	|				AND (RoomQuota.RoomRate IN HIERARCHY (&qRoomRate)
	|					OR &qRoomRateIsEmpty)
	|				AND (RoomQuota.Agent IN HIERARCHY (&qAgent)
	|					OR &qAgentIsEmpty)
	|				AND (RoomQuota.Customer IN HIERARCHY (&qCustomer)
	|					OR &qCustomerIsEmpty)
	|				AND (RoomQuota.Contract = &qContract
	|					OR &qContractIsEmpty)
	|				AND (RoomQuota.AllotmentBusinessType = &qAllotmentBusinessType
	|					OR &qAllotmentBusinessTypeIsEmpty)
	|				AND (RoomQuota.AllotmentType = &qStatus
	|					OR &qStatusIsEmpty)) AS AllotmentBalances";
	vQry.SetParameter("qHotel", SelHotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(SelHotel));
	vQry.SetParameter("qRoomTypes", SelRoomTypes);
	vQry.SetParameter("qRoomTypesAreEmpty", ?(SelRoomTypes.Count() = 0, True, False));
	vQry.SetParameter("qRoomRate", SelRoomRate);
	vQry.SetParameter("qRoomRateIsEmpty", Not ValueIsFilled(SelRoomRate));
	vQry.SetParameter("qCustomer", SelCustomer);
	vQry.SetParameter("qCustomerIsEmpty", Not ValueIsFilled(SelCustomer));
	vQry.SetParameter("qContract", SelContract);
	vQry.SetParameter("qContractIsEmpty", Not ValueIsFilled(SelContract));
	vQry.SetParameter("qAgent", SelAgent);
	vQry.SetParameter("qAgentIsEmpty", Not ValueIsFilled(SelAgent));
	vQry.SetParameter("qRoomQuotas", SelRoomQuotas);
	vQry.SetParameter("qRoomQuotasAreEmpty", ?(SelRoomQuotas.Count() = 0, True, False));
	If SelRoomQuotas.Count() = 1 And ValueIsFilled(SelRoomQuotas.Get(0).Value) And Not SelRoomQuotas.Get(0).Value.IsFolder Then
		vSelRoomQuota = SelRoomQuotas.Get(0).Value;
		If ValueIsFilled(vSelRoomQuota.BaseRoomQuota) And Not vSelRoomQuota.BaseRoomQuota.IsFolder Then
			vQry.SetParameter("qBaseRoomQuota", vSelRoomQuota.BaseRoomQuota);
			vQry.SetParameter("qBaseRoomQuotaIsFilled", True);
		Else
			vQry.SetParameter("qBaseRoomQuota", Catalogs.RoomQuotas.EmptyRef());
			vQry.SetParameter("qBaseRoomQuotaIsFilled", False);
		EndIf;
	Else
		vQry.SetParameter("qBaseRoomQuota", Catalogs.RoomQuotas.EmptyRef());
		vQry.SetParameter("qBaseRoomQuotaIsFilled", False);
	EndIf;
	vQry.SetParameter("qEmptyRoomQuota", Catalogs.RoomQuotas.EmptyRef());
	vQry.SetParameter("qEmptyRoomRate", Catalogs.RoomRates.EmptyRef());
	vQry.SetParameter("qEmptyString", "");
	vCurrentDateTime = CurrentSessionDate();
	vCurrentDate = BegOfDay(vCurrentDateTime);
	vQry.SetParameter("qCurrentDate", vCurrentDate);
	If BegOfDay(SelPeriodFrom) < vCurrentDate Then
		vQry.SetParameter("qUsePast", True);
		vQry.SetParameter("qPeriodFromForThePast", BegOfDay(SelPeriodFrom) - 24*3600);
		vQry.SetParameter("qPeriodToForThePast", EndOfDay(vCurrentDateTime));
	Else
		vQry.SetParameter("qUsePast", False);
		vQry.SetParameter("qPeriodFromForThePast", BegOfDay(SelPeriodFrom) - 24*3600);
		vQry.SetParameter("qPeriodToForThePast", EndOfDay(SelPeriodTo) + 24*3600);
	EndIf;
	If BegOfDay(SelPeriodFrom) <= vCurrentDate And BegOfDay(SelPeriodTo) >= vCurrentDate Then
		vQry.SetParameter("qUseToday", True);
		vCT = '00010101' + (vCurrentDateTime - BegOfDay(vCurrentDateTime));
		vDateTimeFromToday = vCurrentDate;
		If ValueIsFilled(SelHotel) And ValueIsFilled(SelHotel.RoomRate) And SelHotel.RoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour Then
			vRH = '00010101120000';
			vCI = '00010101120000';
			If ValueIsFilled(SelHotel) And ValueIsFilled(SelHotel.RoomRate) And ValueIsFilled(SelHotel.RoomRate.ReferenceHour) Then
				vRH = '00010101' + (SelHotel.RoomRate.ReferenceHour - BegOfDay(SelHotel.RoomRate.ReferenceHour));
				vCI = vRH;
			EndIf;
			If ValueIsFilled(SelHotel) And ValueIsFilled(SelHotel.RoomRate) And ValueIsFilled(SelHotel.RoomRate.DefaultCheckInTime) Then
				vCI = '00010101' + (SelHotel.RoomRate.DefaultCheckInTime - BegOfDay(SelHotel.RoomRate.DefaultCheckInTime));
			EndIf;
			If vCT < vCI Then
				vDateTimeFromToday = cm1SecondShift(vCurrentDate + (vCI - BegOfDay(vCI)));
			Else
				vDateTimeFromToday = cm1SecondShift(vCurrentDate + (vCT - BegOfDay(vCT)));
			EndIf;
		Else
			vDateTimeFromToday = vCurrentDateTime;
		EndIf;
		vQry.SetParameter("qPeriodFromForToday", vDateTimeFromToday);
		vQry.SetParameter("qPeriodToForToday", EndOfDay(vCurrentDateTime) + 24*3600);
	Else
		vQry.SetParameter("qUseToday", False);
		vQry.SetParameter("qPeriodFromForToday", BegOfDay(SelPeriodFrom) - 24*3600);
		vQry.SetParameter("qPeriodToForToday", EndOfDay(SelPeriodTo) + 24*3600);
	EndIf;
	If BegOfDay(SelPeriodTo) > vCurrentDate Then
		vQry.SetParameter("qUseFuture", True);
		vQry.SetParameter("qPeriodFromForTheFuture", vCurrentDate);
		vQry.SetParameter("qPeriodToForTheFuture", EndOfDay(SelPeriodTo) + 24*3600);
	Else
		vQry.SetParameter("qUseFuture", False);
		vQry.SetParameter("qPeriodFromForTheFuture", BegOfDay(SelPeriodFrom) - 24*3600);
		vQry.SetParameter("qPeriodToForTheFuture", EndOfDay(SelPeriodTo) + 24*3600);
	EndIf;
	vQry.SetParameter("qPeriodFrom", BegOfDay(SelPeriodFrom) - 24*3600);
	vQry.SetParameter("qPeriodTo", EndOfDay(SelPeriodTo) + 24*3600);
	vQry.SetParameter("qShiftInSeconds", ?(ValueIsFilled(SelHotel) And ValueIsFilled(SelHotel.RoomRate) And ValueIsFilled(SelHotel.RoomRate.ReferenceHour), -(SelHotel.RoomRate.ReferenceHour - BegOfDay(SelHotel.RoomRate.ReferenceHour)), -43200));
	vQry.SetParameter("qStatus", SelStatus);
	vQry.SetParameter("qStatusIsEmpty", Not ValueIsFilled(SelStatus));
	vQry.SetParameter("qAllotmentBusinessType", SelAllotmentBusinessType);
	vQry.SetParameter("qAllotmentBusinessTypeIsEmpty", Not ValueIsFilled(SelAllotmentBusinessType));
	vQry.Execute();
	
	// Build list of check-in periods
	vQry = New Query();
	vQry.TempTablesManager = pTempTablesManager;
	vQry.Text = 
	"SELECT
	|	RoomQuotaCheckInPeriods.Hotel AS Hotel,
	|	RoomQuotaCheckInPeriods.Hotel.Description AS HotelDescription,
	|	RoomQuotaCheckInPeriods.Hotel.SortCode AS HotelSortCode,
	|	RoomQuotaCheckInPeriods.RoomQuota AS RoomQuota,
	|	RoomQuotaCheckInPeriods.RoomQuota.Description AS RoomQuotaDescription,
	|	RoomQuotaCheckInPeriods.RoomQuota.SortCode AS RoomQuotaSortCode,
	|	RoomQuotaCheckInPeriods.CheckInDate AS CheckInDate,
	|	RoomQuotaCheckInPeriods.Duration AS Duration,
	|	RoomQuotaCheckInPeriods.CheckOutDate AS CheckOutDate,
	|	BEGINOFPERIOD(RoomQuotaCheckInPeriods.CheckInDate, DAY) AS BegOfCheckInDate,
	|	BEGINOFPERIOD(RoomQuotaCheckInPeriods.CheckOutDate, DAY) AS BegOfCheckOutDate
	|INTO CheckInPeriods
	|FROM
	|	InformationRegister.RoomQuotaCheckInPeriods AS RoomQuotaCheckInPeriods
	|WHERE
	|	NOT RoomQuotaCheckInPeriods.IsNotActive
	|	AND (RoomQuotaCheckInPeriods.Hotel IN HIERARCHY (&qHotel)
	|			OR &qHotelIsEmpty)
	|	AND (RoomQuotaCheckInPeriods.RoomQuota IN HIERARCHY (&qRoomQuotas)
	|			OR &qRoomQuotasAreEmpty
	|			OR RoomQuotaCheckInPeriods.RoomQuota = &qBaseRoomQuota
	|				AND &qBaseRoomQuotaIsFilled)
	|	AND (RoomQuotaCheckInPeriods.RoomQuota.Agent IN HIERARCHY (&qAgent)
	|			OR &qAgentIsEmpty)
	|	AND (RoomQuotaCheckInPeriods.RoomQuota.Customer IN HIERARCHY (&qCustomer)
	|			OR &qCustomerIsEmpty)
	|	AND (RoomQuotaCheckInPeriods.RoomQuota.Contract = &qContract
	|			OR &qContractIsEmpty)
	|	AND (RoomQuotaCheckInPeriods.RoomQuota.AllotmentBusinessType = &qAllotmentBusinessType
	|			OR &qAllotmentBusinessTypeIsEmpty)
	|	AND (RoomQuotaCheckInPeriods.RoomQuota.AllotmentType = &qStatus
	|			OR &qStatusIsEmpty)
	|	AND RoomQuotaCheckInPeriods.CheckInDate < &qPeriodTo
	|	AND RoomQuotaCheckInPeriods.CheckOutDate > &qPeriodFrom";
	vQry.SetParameter("qHotel", SelHotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(SelHotel));
	vQry.SetParameter("qCustomer", SelCustomer);
	vQry.SetParameter("qCustomerIsEmpty", Not ValueIsFilled(SelCustomer));
	vQry.SetParameter("qContract", SelContract);
	vQry.SetParameter("qContractIsEmpty", Not ValueIsFilled(SelContract));
	vQry.SetParameter("qAgent", SelAgent);
	vQry.SetParameter("qAgentIsEmpty", Not ValueIsFilled(SelAgent));
	vQry.SetParameter("qRoomQuotas", SelRoomQuotas);
	vQry.SetParameter("qRoomQuotasAreEmpty", ?(SelRoomQuotas.Count() = 0, True, False));
	If SelRoomQuotas.Count() = 1 And ValueIsFilled(SelRoomQuotas.Get(0).Value) And Not SelRoomQuotas.Get(0).Value.IsFolder Then
		vSelRoomQuota = SelRoomQuotas.Get(0).Value;
		If ValueIsFilled(vSelRoomQuota.BaseRoomQuota) And Not vSelRoomQuota.BaseRoomQuota.IsFolder Then
			vQry.SetParameter("qBaseRoomQuota", vSelRoomQuota.BaseRoomQuota);
			vQry.SetParameter("qBaseRoomQuotaIsFilled", True);
		Else
			vQry.SetParameter("qBaseRoomQuota", Catalogs.RoomQuotas.EmptyRef());
			vQry.SetParameter("qBaseRoomQuotaIsFilled", False);
		EndIf;
	Else
		vQry.SetParameter("qBaseRoomQuota", Catalogs.RoomQuotas.EmptyRef());
		vQry.SetParameter("qBaseRoomQuotaIsFilled", False);
	EndIf;
	vQry.SetParameter("qPeriodFrom", BegOfDay(SelPeriodFrom) - 24*3600);
	vQry.SetParameter("qPeriodTo", EndOfDay(SelPeriodTo) + 24*3600);
	vQry.SetParameter("qStatus", SelStatus);
	vQry.SetParameter("qStatusIsEmpty", Not ValueIsFilled(SelStatus));
	vQry.SetParameter("qAllotmentBusinessType", SelAllotmentBusinessType);
	vQry.SetParameter("qAllotmentBusinessTypeIsEmpty", Not ValueIsFilled(SelAllotmentBusinessType));
	vQry.Execute();
	
	// Merge balances to the one value table
	vQry = New Query();
	vQry.TempTablesManager = pTempTablesManager;
	vQry.Text = 
	"SELECT
	|	BalancesByDates.PeriodDate AS PeriodDate,
	|	BalancesByDates.Hotel AS Hotel,
	|	BalancesByDates.HotelDescription AS HotelDescription,
	|	BalancesByDates.HotelSortCode AS HotelSortCode,
	|	BalancesByDates.RoomType AS RoomType,
	|	BalancesByDates.RoomTypeDescription AS RoomTypeDescription,
	|	BalancesByDates.RoomTypeSortCode AS RoomTypeSortCode,
	|	BalancesByDates.RoomQuota AS RoomQuota,
	|	BalancesByDates.RoomQuotaDescription AS RoomQuotaDescription,
	|	BalancesByDates.RoomQuotaSortCode AS RoomQuotaSortCode,
	|	SUM(BalancesByDates.TotalRooms) AS TotalRooms,
	|	SUM(BalancesByDates.TotalBeds) AS TotalBeds,
	|	SUM(BalancesByDates.TotalSpecialRooms) AS TotalSpecialRooms,
	|	SUM(BalancesByDates.TotalSpecialBeds) AS TotalSpecialBeds,
	|	SUM(BalancesByDates.RoomsBlocked) AS RoomsBlocked,
	|	SUM(BalancesByDates.BedsBlocked) AS BedsBlocked,
	|	SUM(BalancesByDates.RoomsVacant) AS RoomsVacant,
	|	SUM(BalancesByDates.BedsVacant) AS BedsVacant,
	|	SUM(BalancesByDates.SpecialRoomsVacant) AS SpecialRoomsVacant,
	|	SUM(BalancesByDates.SpecialBedsVacant) AS SpecialBedsVacant,
	|	SUM(BalancesByDates.RoomsInQuota) AS RoomsInQuota,
	|	SUM(BalancesByDates.BedsInQuota) AS BedsInQuota,
	|	SUM(BalancesByDates.RoomsRemains) AS RoomsRemains,
	|	SUM(BalancesByDates.BedsRemains) AS BedsRemains
	|INTO BalancesByDates
	|FROM
	|	(SELECT
	|		InventoryBalances.PeriodDate AS PeriodDate,
	|		InventoryBalances.Hotel AS Hotel,
	|		InventoryBalances.HotelDescription AS HotelDescription,
	|		InventoryBalances.HotelSortCode AS HotelSortCode,
	|		InventoryBalances.RoomType AS RoomType,
	|		InventoryBalances.RoomTypeDescription AS RoomTypeDescription,
	|		InventoryBalances.RoomTypeSortCode AS RoomTypeSortCode,
	|		InventoryBalances.RoomQuota AS RoomQuota,
	|		InventoryBalances.RoomQuotaDescription AS RoomQuotaDescription,
	|		InventoryBalances.RoomQuotaSortCode AS RoomQuotaSortCode,
	|		InventoryBalances.TotalRooms AS TotalRooms,
	|		InventoryBalances.TotalBeds AS TotalBeds,
	|		InventoryBalances.TotalSpecialRooms AS TotalSpecialRooms,
	|		InventoryBalances.TotalSpecialBeds AS TotalSpecialBeds,
	|		InventoryBalances.RoomsBlocked AS RoomsBlocked,
	|		InventoryBalances.BedsBlocked AS BedsBlocked,
	|		InventoryBalances.RoomsVacant AS RoomsVacant,
	|		InventoryBalances.BedsVacant AS BedsVacant,
	|		InventoryBalances.SpecialRoomsVacant AS SpecialRoomsVacant,
	|		InventoryBalances.SpecialBedsVacant AS SpecialBedsVacant,
	|		0 AS RoomsInQuota,
	|		0 AS BedsInQuota,
	|		0 AS RoomsRemains,
	|		0 AS BedsRemains
	|	FROM
	|		RoomInventoryBalances AS InventoryBalances
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AllotmentBalances.PeriodDate,
	|		AllotmentBalances.Hotel,
	|		AllotmentBalances.HotelDescription,
	|		AllotmentBalances.HotelSortCode,
	|		AllotmentBalances.RoomType,
	|		AllotmentBalances.RoomTypeDescription,
	|		AllotmentBalances.RoomTypeSortCode,
	|		AllotmentBalances.RoomQuota,
	|		AllotmentBalances.RoomQuotaDescription,
	|		AllotmentBalances.RoomQuotaSortCode,
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
	|		AllotmentBalances.RoomsInQuota,
	|		AllotmentBalances.BedsInQuota,
	|		AllotmentBalances.RoomsRemains,
	|		AllotmentBalances.BedsRemains
	|	FROM
	|		AllotmentBalances AS AllotmentBalances) AS BalancesByDates
	|
	|GROUP BY
	|	BalancesByDates.PeriodDate,
	|	BalancesByDates.Hotel,
	|	BalancesByDates.HotelDescription,
	|	BalancesByDates.HotelSortCode,
	|	BalancesByDates.RoomType,
	|	BalancesByDates.RoomTypeDescription,
	|	BalancesByDates.RoomTypeSortCode,
	|	BalancesByDates.RoomQuota,
	|	BalancesByDates.RoomQuotaDescription,
	|	BalancesByDates.RoomQuotaSortCode";
	vQry.SetParameter("qHotel", SelHotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(SelHotel));
	vQry.SetParameter("qRoomTypes", SelRoomTypes);
	vQry.SetParameter("qRoomTypesAreEmpty", ?(SelRoomTypes.Count() > 0, True, False));
	vQry.SetParameter("qRoomRate", SelRoomRate);
	vQry.SetParameter("qRoomRateIsEmpty", Not ValueIsFilled(SelRoomRate));
	vQry.SetParameter("qCustomer", SelCustomer);
	vQry.SetParameter("qCustomerIsEmpty", Not ValueIsFilled(SelCustomer));
	vQry.SetParameter("qContract", SelContract);
	vQry.SetParameter("qContractIsEmpty", Not ValueIsFilled(SelContract));
	vQry.SetParameter("qAgent", SelAgent);
	vQry.SetParameter("qAgentIsEmpty", Not ValueIsFilled(SelAgent));
	vQry.SetParameter("qRoomQuotas", SelRoomQuotas);
	vQry.SetParameter("qRoomQuotasAreEmpty", ?(SelRoomQuotas.Count() = 0, True, False));
	vQry.SetParameter("qEmptyRoomQuota", Catalogs.RoomQuotas.EmptyRef());
	vQry.SetParameter("qEmptyRoomRate", Catalogs.RoomRates.EmptyRef());
	vQry.SetParameter("qEmptyString", "");
	vQry.SetParameter("qPeriodFrom", BegOfDay(SelPeriodFrom) - 24 * 3600);
	vQry.SetParameter("qPeriodTo", EndOfDay(SelPeriodTo) + 24 * 3600);
	vQry.Execute();
	
	// Retrieve room types totals
	vQry = New Query();
	vQry.TempTablesManager = pTempTablesManager;
	vQry.Text = 
	"SELECT
	|	BalancesByDates.PeriodDate AS PeriodDate,
	|	BalancesByDates.Hotel AS Hotel,
	|	BalancesByDates.HotelDescription AS HotelDescription,
	|	BalancesByDates.HotelSortCode AS HotelSortCode,
	|	BalancesByDates.RoomType AS RoomType,
	|	BalancesByDates.RoomTypeDescription AS RoomTypeDescription,
	|	BalancesByDates.RoomTypeSortCode AS RoomTypeSortCode,
	|	SUM(BalancesByDates.TotalRooms) AS TotalRooms,
	|	SUM(BalancesByDates.TotalBeds) AS TotalBeds,
	|	SUM(BalancesByDates.TotalSpecialRooms) AS TotalSpecialRooms,
	|	SUM(BalancesByDates.TotalSpecialBeds) AS TotalSpecialBeds,
	|	SUM(BalancesByDates.RoomsBlocked) AS RoomsBlocked,
	|	SUM(BalancesByDates.BedsBlocked) AS BedsBlocked,
	|	SUM(BalancesByDates.RoomsVacant) AS RoomsVacant,
	|	SUM(BalancesByDates.BedsVacant) AS BedsVacant,
	|	SUM(BalancesByDates.SpecialRoomsVacant) AS SpecialRoomsVacant,
	|	SUM(BalancesByDates.SpecialBedsVacant) AS SpecialBedsVacant,
	|	SUM(BalancesByDates.RoomsInQuota) AS RoomsInQuota,
	|	SUM(BalancesByDates.BedsInQuota) AS BedsInQuota,
	|	SUM(BalancesByDates.RoomsRemains) AS RoomsRemains,
	|	SUM(BalancesByDates.BedsRemains) AS BedsRemains
	|FROM
	|	BalancesByDates AS BalancesByDates
	|
	|GROUP BY
	|	BalancesByDates.PeriodDate,
	|	BalancesByDates.Hotel,
	|	BalancesByDates.HotelDescription,
	|	BalancesByDates.HotelSortCode,
	|	BalancesByDates.RoomType,
	|	BalancesByDates.RoomTypeDescription,
	|	BalancesByDates.RoomTypeSortCode
	|
	|ORDER BY
	|	HotelSortCode,
	|	HotelDescription,
	|	RoomTypeSortCode,
	|	RoomTypeDescription,
	|	PeriodDate";
	Return vQry.Execute().Unload();
EndFunction // GetRoomTypePeriodsBalances

// -----------------------------------------------------------------------------
Function GetAllotmentPeriodsBalances()
	vTempTablesManager = New TempTablesManager();
	
	// Build room inventory and allotment balances
	vQry = New Query();
	vQry.TempTablesManager = vTempTablesManager;
	vQry.Text = 
	"SELECT
	|	BEGINOFPERIOD(RoomInventoryBalancesDetailed.Period, DAY) AS PeriodDate,
	|	RoomInventoryBalancesDetailed.Hotel AS Hotel,
	|	RoomInventoryBalancesDetailed.RoomType AS RoomType,
	|	MAX(ISNULL(RoomInventoryBalancesDetailed.CounterClosingBalance, 0)) AS CounterClosingBalance,
	|	MIN(ISNULL(RoomInventoryBalancesDetailed.RoomsVacantClosingBalance, 0)) AS RoomsVacant,
	|	MIN(ISNULL(RoomInventoryBalancesDetailed.BedsVacantClosingBalance, 0)) AS BedsVacant,
	|	MIN(CASE
	|			WHEN ISNULL(RoomInventoryBalancesDetailed.RoomType.DoesNotAffectRoomRevenueStatistics, FALSE)
	|				THEN ISNULL(RoomInventoryBalancesDetailed.RoomsVacantClosingBalance, 0)
	|			ELSE 0
	|		END) AS SpecialRoomsVacant,
	|	MIN(CASE
	|			WHEN ISNULL(RoomInventoryBalancesDetailed.RoomType.DoesNotAffectRoomRevenueStatistics, FALSE)
	|				THEN ISNULL(RoomInventoryBalancesDetailed.BedsVacantClosingBalance, 0)
	|			ELSE 0
	|		END) AS SpecialBedsVacant,
	|	MIN(ISNULL(RoomInventoryBalancesDetailed.TotalRoomsClosingBalance, 0)) AS TotalRooms,
	|	MIN(ISNULL(RoomInventoryBalancesDetailed.TotalBedsClosingBalance, 0)) AS TotalBeds,
	|	MIN(ISNULL(RoomInventoryBalancesDetailed.TotalSpecialRoomsClosingBalance, 0)) AS TotalSpecialRooms,
	|	MIN(ISNULL(RoomInventoryBalancesDetailed.TotalSpecialBedsClosingBalance, 0)) AS TotalSpecialBeds,
	|	MAX(-ISNULL(RoomInventoryBalancesDetailed.RoomsBlockedClosingBalance, 0)) AS RoomsBlocked,
	|	MAX(-ISNULL(RoomInventoryBalancesDetailed.BedsBlockedClosingBalance, 0)) AS BedsBlocked
	|INTO RoomInventoryForThePast
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|			&qPeriodFromForThePast,
	|			&qPeriodToForThePast,
	|			DAY,
	|			RegisterRecordsAndPeriodBoundaries,
	|			&qUsePast
	|				AND (Hotel IN HIERARCHY (&qHotel)
	|					OR &qHotelIsEmpty)
	|				AND (RoomType IN HIERARCHY (&qRoomTypes)
	|					OR &qRoomTypesAreEmpty)
	|				AND NOT RoomType.IsVirtual
	|				AND NOT RoomType.DeletionMark) AS RoomInventoryBalancesDetailed
	|WHERE
	|	BEGINOFPERIOD(RoomInventoryBalancesDetailed.Period, DAY) < &qCurrentDate
	|
	|GROUP BY
	|	BEGINOFPERIOD(RoomInventoryBalancesDetailed.Period, DAY),
	|	RoomInventoryBalancesDetailed.Hotel,
	|	RoomInventoryBalancesDetailed.RoomType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BEGINOFPERIOD(DATEADD(RoomInventoryBalancesDetailed.Period, SECOND, &qShiftInSeconds), DAY) AS PeriodDate,
	|	RoomInventoryBalancesDetailed.Hotel AS Hotel,
	|	RoomInventoryBalancesDetailed.RoomType AS RoomType,
	|	MAX(ISNULL(RoomInventoryBalancesDetailed.CounterClosingBalance, 0)) AS CounterClosingBalance,
	|	MIN(ISNULL(RoomInventoryBalancesDetailed.RoomsVacantClosingBalance, 0)) AS RoomsVacant,
	|	MIN(ISNULL(RoomInventoryBalancesDetailed.BedsVacantClosingBalance, 0)) AS BedsVacant,
	|	MIN(CASE
	|			WHEN ISNULL(RoomInventoryBalancesDetailed.RoomType.DoesNotAffectRoomRevenueStatistics, FALSE)
	|				THEN ISNULL(RoomInventoryBalancesDetailed.RoomsVacantClosingBalance, 0)
	|			ELSE 0
	|		END) AS SpecialRoomsVacant,
	|	MIN(CASE
	|			WHEN ISNULL(RoomInventoryBalancesDetailed.RoomType.DoesNotAffectRoomRevenueStatistics, FALSE)
	|				THEN ISNULL(RoomInventoryBalancesDetailed.BedsVacantClosingBalance, 0)
	|			ELSE 0
	|		END) AS SpecialBedsVacant,
	|	MIN(ISNULL(RoomInventoryBalancesDetailed.TotalRoomsClosingBalance, 0)) AS TotalRooms,
	|	MIN(ISNULL(RoomInventoryBalancesDetailed.TotalBedsClosingBalance, 0)) AS TotalBeds,
	|	MIN(ISNULL(RoomInventoryBalancesDetailed.TotalSpecialRoomsClosingBalance, 0)) AS TotalSpecialRooms,
	|	MIN(ISNULL(RoomInventoryBalancesDetailed.TotalSpecialBedsClosingBalance, 0)) AS TotalSpecialBeds,
	|	MAX(-ISNULL(RoomInventoryBalancesDetailed.RoomsBlockedClosingBalance, 0)) AS RoomsBlocked,
	|	MAX(-ISNULL(RoomInventoryBalancesDetailed.BedsBlockedClosingBalance, 0)) AS BedsBlocked
	|INTO RoomInventoryForToday
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|			&qPeriodFromForToday,
	|			&qPeriodToForToday,
	|			MINUTE,
	|			RegisterRecordsAndPeriodBoundaries,
	|			&qUseToday
	|				AND (Hotel IN HIERARCHY (&qHotel)
	|					OR &qHotelIsEmpty)
	|				AND (RoomType IN HIERARCHY (&qRoomTypes)
	|					OR &qRoomTypesAreEmpty)
	|				AND NOT RoomType.IsVirtual
	|				AND NOT RoomType.DeletionMark) AS RoomInventoryBalancesDetailed
	|WHERE
	|	BEGINOFPERIOD(DATEADD(RoomInventoryBalancesDetailed.Period, SECOND, &qShiftInSeconds), DAY) = &qCurrentDate
	|
	|GROUP BY
	|	BEGINOFPERIOD(DATEADD(RoomInventoryBalancesDetailed.Period, SECOND, &qShiftInSeconds), DAY),
	|	RoomInventoryBalancesDetailed.Hotel,
	|	RoomInventoryBalancesDetailed.RoomType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BEGINOFPERIOD(DATEADD(RoomInventoryBalancesDetailed.Period, SECOND, &qShiftInSeconds), DAY) AS PeriodDate,
	|	RoomInventoryBalancesDetailed.Hotel AS Hotel,
	|	RoomInventoryBalancesDetailed.RoomType AS RoomType,
	|	MAX(ISNULL(RoomInventoryBalancesDetailed.CounterClosingBalance, 0)) AS CounterClosingBalance,
	|	MIN(ISNULL(RoomInventoryBalancesDetailed.RoomsVacantClosingBalance, 0)) AS RoomsVacant,
	|	MIN(ISNULL(RoomInventoryBalancesDetailed.BedsVacantClosingBalance, 0)) AS BedsVacant,
	|	MIN(CASE
	|			WHEN ISNULL(RoomInventoryBalancesDetailed.RoomType.DoesNotAffectRoomRevenueStatistics, FALSE)
	|				THEN ISNULL(RoomInventoryBalancesDetailed.RoomsVacantClosingBalance, 0)
	|			ELSE 0
	|		END) AS SpecialRoomsVacant,
	|	MIN(CASE
	|			WHEN ISNULL(RoomInventoryBalancesDetailed.RoomType.DoesNotAffectRoomRevenueStatistics, FALSE)
	|				THEN ISNULL(RoomInventoryBalancesDetailed.BedsVacantClosingBalance, 0)
	|			ELSE 0
	|		END) AS SpecialBedsVacant,
	|	MIN(ISNULL(RoomInventoryBalancesDetailed.TotalRoomsClosingBalance, 0)) AS TotalRooms,
	|	MIN(ISNULL(RoomInventoryBalancesDetailed.TotalBedsClosingBalance, 0)) AS TotalBeds,
	|	MIN(ISNULL(RoomInventoryBalancesDetailed.TotalSpecialRoomsClosingBalance, 0)) AS TotalSpecialRooms,
	|	MIN(ISNULL(RoomInventoryBalancesDetailed.TotalSpecialBedsClosingBalance, 0)) AS TotalSpecialBeds,
	|	MAX(-ISNULL(RoomInventoryBalancesDetailed.RoomsBlockedClosingBalance, 0)) AS RoomsBlocked,
	|	MAX(-ISNULL(RoomInventoryBalancesDetailed.BedsBlockedClosingBalance, 0)) AS BedsBlocked
	|INTO RoomInventoryForTheFuture
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|			&qPeriodFromForTheFuture,
	|			&qPeriodToForTheFuture,
	|			MINUTE,
	|			RegisterRecordsAndPeriodBoundaries,
	|			&qUseFuture
	|				AND (Hotel IN HIERARCHY (&qHotel)
	|					OR &qHotelIsEmpty)
	|				AND (RoomType IN HIERARCHY (&qRoomTypes)
	|					OR &qRoomTypesAreEmpty)
	|				AND NOT RoomType.IsVirtual
	|				AND NOT RoomType.DeletionMark) AS RoomInventoryBalancesDetailed
	|WHERE
	|	BEGINOFPERIOD(DATEADD(RoomInventoryBalancesDetailed.Period, SECOND, &qShiftInSeconds), DAY) > &qCurrentDate
	|
	|GROUP BY
	|	BEGINOFPERIOD(DATEADD(RoomInventoryBalancesDetailed.Period, SECOND, &qShiftInSeconds), DAY),
	|	RoomInventoryBalancesDetailed.Hotel,
	|	RoomInventoryBalancesDetailed.RoomType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllTentativeRooms.Period AS PeriodDate,
	|	AllTentativeRooms.Hotel AS Hotel,
	|	AllTentativeRooms.Hotel.Description AS HotelDescription,
	|	AllTentativeRooms.Hotel.SortCode AS HotelSortCode,
	|	AllTentativeRooms.RoomType AS RoomType,
	|	AllTentativeRooms.RoomType.Description AS RoomTypeDescription,
	|	AllTentativeRooms.RoomType.SortCode AS RoomTypeSortCode,
	|	AllTentativeRooms.RoomsReservedTurnover AS TentativeRooms,
	|	AllTentativeRooms.BedsReservedTurnover AS TentativeBeds
	|INTO TentativeTotals
	|FROM
	|	AccumulationRegister.ExpectedGuestGroups.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			(Hotel IN HIERARCHY (&qHotel)
	|				OR &qHotelIsEmpty)
	|				AND (RoomType IN HIERARCHY (&qRoomTypes)
	|					OR &qRoomTypesAreEmpty)
	|				AND NOT RoomType.IsVirtual
	|				AND NOT RoomType.DeletionMark) AS AllTentativeRooms
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExpectedGuestGroupsTurnovers.Period AS PeriodDate,
	|	ExpectedGuestGroupsTurnovers.Hotel AS Hotel,
	|	ExpectedGuestGroupsTurnovers.Hotel.Description AS HotelDescription,
	|	ExpectedGuestGroupsTurnovers.Hotel.SortCode AS HotelSortCode,
	|	ExpectedGuestGroupsTurnovers.RoomQuota AS RoomQuota,
	|	ExpectedGuestGroupsTurnovers.RoomQuota.Description AS RoomQuotaDescription,
	|	ExpectedGuestGroupsTurnovers.RoomQuota.SortCode AS RoomQuotaSortCode,
	|	ExpectedGuestGroupsTurnovers.RoomType AS RoomType,
	|	ExpectedGuestGroupsTurnovers.RoomType.Description AS RoomTypeDescription,
	|	ExpectedGuestGroupsTurnovers.RoomType.SortCode AS RoomTypeSortCode,
	|	ExpectedGuestGroupsTurnovers.RoomsReservedTurnover AS RoomsForecast,
	|	ExpectedGuestGroupsTurnovers.BedsReservedTurnover AS BedsForecast
	|INTO ForecastData
	|FROM
	|	AccumulationRegister.ExpectedGuestGroups.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			&qShowForecast
	|				AND RoomQuota <> &qEmptyRoomQuota
	|				AND (Hotel IN HIERARCHY (&qHotel)
	|					OR &qHotelIsEmpty)
	|				AND (RoomType IN HIERARCHY (&qRoomTypes)
	|					OR &qRoomTypesAreEmpty)
	|				AND NOT RoomType.IsVirtual
	|				AND NOT RoomType.DeletionMark
	|				AND (RoomQuota IN HIERARCHY (&qRoomQuotas)
	|					OR &qRoomQuotasAreEmpty
	|					OR RoomQuota = &qBaseRoomQuota
	|						AND &qBaseRoomQuotaIsFilled)
	|				AND (RoomQuota.RoomRate IN HIERARCHY (&qRoomRate)
	|					OR &qRoomRateIsEmpty)
	|				AND (RoomQuota.Agent IN HIERARCHY (&qAgent)
	|					OR &qAgentIsEmpty)
	|				AND (RoomQuota.Customer IN HIERARCHY (&qCustomer)
	|					OR &qCustomerIsEmpty)
	|				AND (RoomQuota.Contract = &qContract
	|					OR &qContractIsEmpty)
	|				AND (RoomQuota.AllotmentBusinessType = &qAllotmentBusinessType
	|					OR &qAllotmentBusinessTypeIsEmpty)
	|				AND (RoomQuota.AllotmentType = &qStatus
	|					OR &qStatusIsEmpty)) AS ExpectedGuestGroupsTurnovers
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventoryBalances.PeriodDate AS PeriodDate,
	|	RoomInventoryBalances.Hotel AS Hotel,
	|	RoomInventoryBalances.Hotel.Description AS HotelDescription,
	|	RoomInventoryBalances.Hotel.SortCode AS HotelSortCode,
	|	RoomInventoryBalances.RoomType AS RoomType,
	|	RoomInventoryBalances.RoomType.Description AS RoomTypeDescription,
	|	RoomInventoryBalances.RoomType.SortCode AS RoomTypeSortCode,
	|	&qEmptyRoomQuota AS RoomQuota,
	|	&qEmptyString AS RoomQuotaDescription,
	|	0 AS RoomQuotaSortCode,
	|	RoomInventoryBalances.CounterClosingBalance AS CounterClosingBalance,
	|	RoomInventoryBalances.RoomsVacant AS RoomsVacant,
	|	RoomInventoryBalances.BedsVacant AS BedsVacant,
	|	RoomInventoryBalances.SpecialRoomsVacant AS SpecialRoomsVacant,
	|	RoomInventoryBalances.SpecialBedsVacant AS SpecialBedsVacant,
	|	RoomInventoryBalances.TotalRooms AS TotalRooms,
	|	RoomInventoryBalances.TotalBeds AS TotalBeds,
	|	RoomInventoryBalances.TotalSpecialRooms AS TotalSpecialRooms,
	|	RoomInventoryBalances.TotalSpecialBeds AS TotalSpecialBeds,
	|	RoomInventoryBalances.RoomsBlocked AS RoomsBlocked,
	|	RoomInventoryBalances.BedsBlocked AS BedsBlocked,
	|	ISNULL(TentativeTotals.TentativeRooms, 0) AS TentativeRooms,
	|	ISNULL(TentativeTotals.TentativeBeds, 0) AS TentativeBeds
	|INTO RoomInventoryBalances
	|FROM
	|	(SELECT
	|		RoomInventoryForThePast.PeriodDate AS PeriodDate,
	|		RoomInventoryForThePast.Hotel AS Hotel,
	|		RoomInventoryForThePast.RoomType AS RoomType,
	|		RoomInventoryForThePast.CounterClosingBalance AS CounterClosingBalance,
	|		RoomInventoryForThePast.RoomsVacant AS RoomsVacant,
	|		RoomInventoryForThePast.BedsVacant AS BedsVacant,
	|		RoomInventoryForThePast.SpecialRoomsVacant AS SpecialRoomsVacant,
	|		RoomInventoryForThePast.SpecialBedsVacant AS SpecialBedsVacant,
	|		RoomInventoryForThePast.TotalRooms AS TotalRooms,
	|		RoomInventoryForThePast.TotalBeds AS TotalBeds,
	|		RoomInventoryForThePast.TotalSpecialRooms AS TotalSpecialRooms,
	|		RoomInventoryForThePast.TotalSpecialBeds AS TotalSpecialBeds,
	|		RoomInventoryForThePast.RoomsBlocked AS RoomsBlocked,
	|		RoomInventoryForThePast.BedsBlocked AS BedsBlocked
	|	FROM
	|		RoomInventoryForThePast AS RoomInventoryForThePast
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RoomInventoryForToday.PeriodDate,
	|		RoomInventoryForToday.Hotel,
	|		RoomInventoryForToday.RoomType,
	|		RoomInventoryForToday.CounterClosingBalance,
	|		RoomInventoryForToday.RoomsVacant,
	|		RoomInventoryForToday.BedsVacant,
	|		RoomInventoryForToday.SpecialRoomsVacant,
	|		RoomInventoryForToday.SpecialBedsVacant,
	|		RoomInventoryForToday.TotalRooms,
	|		RoomInventoryForToday.TotalBeds,
	|		RoomInventoryForToday.TotalSpecialRooms,
	|		RoomInventoryForToday.TotalSpecialBeds,
	|		RoomInventoryForToday.RoomsBlocked,
	|		RoomInventoryForToday.BedsBlocked
	|	FROM
	|		RoomInventoryForToday AS RoomInventoryForToday
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RoomInventoryForTheFuture.PeriodDate,
	|		RoomInventoryForTheFuture.Hotel,
	|		RoomInventoryForTheFuture.RoomType,
	|		RoomInventoryForTheFuture.CounterClosingBalance,
	|		RoomInventoryForTheFuture.RoomsVacant,
	|		RoomInventoryForTheFuture.BedsVacant,
	|		RoomInventoryForTheFuture.SpecialRoomsVacant,
	|		RoomInventoryForTheFuture.SpecialBedsVacant,
	|		RoomInventoryForTheFuture.TotalRooms,
	|		RoomInventoryForTheFuture.TotalBeds,
	|		RoomInventoryForTheFuture.TotalSpecialRooms,
	|		RoomInventoryForTheFuture.TotalSpecialBeds,
	|		RoomInventoryForTheFuture.RoomsBlocked,
	|		RoomInventoryForTheFuture.BedsBlocked
	|	FROM
	|		RoomInventoryForTheFuture AS RoomInventoryForTheFuture) AS RoomInventoryBalances
	|		LEFT JOIN TentativeTotals AS TentativeTotals
	|		ON RoomInventoryBalances.PeriodDate = TentativeTotals.PeriodDate
	|			AND RoomInventoryBalances.Hotel = TentativeTotals.Hotel
	|			AND RoomInventoryBalances.RoomType = TentativeTotals.RoomType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllotmentRawBalances.Period AS PeriodDate,
	|	AllotmentRawBalances.Hotel AS Hotel,
	|	AllotmentRawBalances.Hotel.Description AS HotelDescription,
	|	AllotmentRawBalances.Hotel.SortCode AS HotelSortCode,
	|	AllotmentRawBalances.RoomQuota AS RoomQuota,
	|	AllotmentRawBalances.RoomQuota.Description AS RoomQuotaDescription,
	|	AllotmentRawBalances.RoomQuota.SortCode AS RoomQuotaSortCode,
	|	AllotmentRawBalances.RoomType AS RoomType,
	|	AllotmentRawBalances.RoomType.Description AS RoomTypeDescription,
	|	AllotmentRawBalances.RoomType.SortCode AS RoomTypeSortCode,
	|	AllotmentRawBalances.CounterClosingBalance AS CounterClosingBalance,
	|	AllotmentRawBalances.InitialRoomsInQuotaClosingBalance AS InitialRoomsInQuota,
	|	AllotmentRawBalances.InitialBedsInQuotaClosingBalance AS InitialBedsInQuota,
	|	AllotmentRawBalances.RoomsInQuotaClosingBalance AS RoomsInQuota,
	|	AllotmentRawBalances.BedsInQuotaClosingBalance AS BedsInQuota,
	|	AllotmentRawBalances.RoomsRemainsClosingBalance AS RoomsRemains,
	|	AllotmentRawBalances.BedsRemainsClosingBalance AS BedsRemains
	|INTO AllotmentRawBalances
	|FROM
	|	AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			DAY,
	|			RegisterRecordsAndPeriodBoundaries,
	|			RoomQuota <> &qEmptyRoomQuota
	|				AND (Hotel IN HIERARCHY (&qHotel)
	|					OR &qHotelIsEmpty)
	|				AND (RoomType IN HIERARCHY (&qRoomTypes)
	|					OR &qRoomTypesAreEmpty)
	|				AND NOT RoomType.IsVirtual
	|				AND NOT RoomType.DeletionMark
	|				AND (RoomQuota IN HIERARCHY (&qRoomQuotas)
	|					OR &qRoomQuotasAreEmpty
	|					OR RoomQuota = &qBaseRoomQuota
	|						AND &qBaseRoomQuotaIsFilled)
	|				AND (RoomQuota.RoomRate IN HIERARCHY (&qRoomRate)
	|					OR &qRoomRateIsEmpty)
	|				AND (RoomQuota.Agent IN HIERARCHY (&qAgent)
	|					OR &qAgentIsEmpty)
	|				AND (RoomQuota.Customer IN HIERARCHY (&qCustomer)
	|					OR &qCustomerIsEmpty)
	|				AND (RoomQuota.Contract = &qContract
	|					OR &qContractIsEmpty)
	|				AND (RoomQuota.AllotmentBusinessType = &qAllotmentBusinessType
	|					OR &qAllotmentBusinessTypeIsEmpty)
	|				AND (RoomQuota.AllotmentType = &qStatus
	|					OR &qStatusIsEmpty)) AS AllotmentRawBalances
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ActiveAllotments.Hotel AS Hotel,
	|	ActiveAllotments.RoomQuota AS RoomQuota
	|INTO ActiveAllotments
	|FROM
	|	(SELECT
	|		AllotmentRawBalances.Hotel AS Hotel,
	|		AllotmentRawBalances.RoomQuota AS RoomQuota,
	|		SUM(AllotmentRawBalances.RoomsInQuota) AS RoomsInQuota,
	|		SUM(AllotmentRawBalances.BedsInQuota) AS BedsInQuota
	|	FROM
	|		AllotmentRawBalances AS AllotmentRawBalances
	|	
	|	GROUP BY
	|		AllotmentRawBalances.Hotel,
	|		AllotmentRawBalances.RoomQuota
	|	
	|	HAVING
	|		(SUM(AllotmentRawBalances.RoomsInQuota) <> 0
	|			OR SUM(AllotmentRawBalances.BedsInQuota) <> 0
	|			OR AllotmentRawBalances.RoomQuota IN (&qRoomQuotas))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		&qHotel,
	|		Allotments.Ref,
	|		0,
	|		0
	|	FROM
	|		Catalog.RoomQuotas AS Allotments
	|	WHERE
	|		Allotments.Ref IN(&qRoomQuotas)) AS ActiveAllotments
	|
	|GROUP BY
	|	ActiveAllotments.Hotel,
	|	ActiveAllotments.RoomQuota
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllotmentBalances.PeriodDate AS PeriodDate,
	|	AllotmentBalances.Hotel AS Hotel,
	|	AllotmentBalances.HotelDescription AS HotelDescription,
	|	AllotmentBalances.HotelSortCode AS HotelSortCode,
	|	AllotmentBalances.RoomQuota AS RoomQuota,
	|	AllotmentBalances.RoomQuotaDescription AS RoomQuotaDescription,
	|	AllotmentBalances.RoomQuotaSortCode AS RoomQuotaSortCode,
	|	AllotmentBalances.RoomType AS RoomType,
	|	AllotmentBalances.RoomTypeDescription AS RoomTypeDescription,
	|	AllotmentBalances.RoomTypeSortCode AS RoomTypeSortCode,
	|	AllotmentBalances.CounterClosingBalance AS CounterClosingBalance,
	|	AllotmentBalances.RoomsInQuota AS RoomsInQuota,
	|	AllotmentBalances.BedsInQuota AS BedsInQuota,
	|	AllotmentBalances.InitialRoomsInQuota AS InitialRoomsInQuota,
	|	AllotmentBalances.InitialBedsInQuota AS InitialBedsInQuota,
	|	AllotmentBalances.RoomsRemains AS RoomsRemains,
	|	AllotmentBalances.BedsRemains AS BedsRemains
	|INTO AllotmentBalances
	|FROM
	|	AllotmentRawBalances AS AllotmentBalances
	|		INNER JOIN ActiveAllotments AS ActiveAllotments
	|		ON AllotmentBalances.Hotel = ActiveAllotments.Hotel
	|			AND AllotmentBalances.RoomQuota = ActiveAllotments.RoomQuota
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventoryBalances.PeriodDate AS PeriodDate,
	|	RoomInventoryBalances.Hotel AS Hotel,
	|	RoomInventoryBalances.HotelDescription AS HotelDescription,
	|	RoomInventoryBalances.HotelSortCode AS HotelSortCode,
	|	CASE
	|		WHEN AllotmentBalances.RoomQuota IS NULL
	|				AND &qRoomQuota <> &qEmptyRoomQuota
	|				AND &qRoomQuotaIsElement
	|			THEN &qRoomQuota
	|		ELSE AllotmentBalances.RoomQuota
	|	END AS RoomQuota,
	|	CASE
	|		WHEN AllotmentBalances.RoomQuota IS NULL
	|				AND &qRoomQuota <> &qEmptyRoomQuota
	|				AND &qRoomQuotaIsElement
	|			THEN &qRoomQuotaDescription
	|		ELSE AllotmentBalances.RoomQuotaDescription
	|	END AS RoomQuotaDescription,
	|	CASE
	|		WHEN AllotmentBalances.RoomQuota IS NULL
	|				AND &qRoomQuota <> &qEmptyRoomQuota
	|				AND &qRoomQuotaIsElement
	|			THEN &qRoomQuotaSortCode
	|		ELSE AllotmentBalances.RoomQuotaSortCode
	|	END AS RoomQuotaSortCode,
	|	RoomInventoryBalances.RoomType AS RoomType,
	|	RoomInventoryBalances.RoomTypeDescription AS RoomTypeDescription,
	|	RoomInventoryBalances.RoomTypeSortCode AS RoomTypeSortCode,
	|	CASE
	|		WHEN AllotmentBalances.RoomType = RoomInventoryBalances.RoomType
	|			THEN AllotmentBalances.CounterClosingBalance
	|		ELSE 0
	|	END AS CounterClosingBalance,
	|	CASE
	|		WHEN AllotmentBalances.RoomType = RoomInventoryBalances.RoomType
	|			THEN AllotmentBalances.RoomsInQuota
	|		ELSE 0
	|	END AS RoomsInQuota,
	|	CASE
	|		WHEN AllotmentBalances.RoomType = RoomInventoryBalances.RoomType
	|			THEN AllotmentBalances.BedsInQuota
	|		ELSE 0
	|	END AS BedsInQuota,
	|	CASE
	|		WHEN AllotmentBalances.RoomType = RoomInventoryBalances.RoomType
	|			THEN AllotmentBalances.InitialRoomsInQuota
	|		ELSE 0
	|	END AS InitialRoomsInQuota,
	|	CASE
	|		WHEN AllotmentBalances.RoomType = RoomInventoryBalances.RoomType
	|			THEN AllotmentBalances.InitialBedsInQuota
	|		ELSE 0
	|	END AS InitialBedsInQuota,
	|	CASE
	|		WHEN AllotmentBalances.RoomType = RoomInventoryBalances.RoomType
	|			THEN AllotmentBalances.RoomsRemains
	|		ELSE 0
	|	END AS RoomsRemains,
	|	CASE
	|		WHEN AllotmentBalances.RoomType = RoomInventoryBalances.RoomType
	|			THEN AllotmentBalances.BedsRemains
	|		ELSE 0
	|	END AS BedsRemains
	|INTO AllotmentBalancesAllRoomTypes
	|FROM
	|	RoomInventoryBalances AS RoomInventoryBalances
	|		LEFT JOIN AllotmentBalances AS AllotmentBalances
	|		ON RoomInventoryBalances.PeriodDate = AllotmentBalances.PeriodDate
	|			AND RoomInventoryBalances.Hotel = AllotmentBalances.Hotel";
	vQry.SetParameter("qHotel", SelHotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(SelHotel));
	vQry.SetParameter("qRoomTypes", SelRoomTypes);
	vQry.SetParameter("qRoomTypesAreEmpty", ?(SelRoomTypes.Count() = 0, True, False));
	vQry.SetParameter("qRoomRate", SelRoomRate);
	vQry.SetParameter("qRoomRateIsEmpty", Not ValueIsFilled(SelRoomRate));
	vQry.SetParameter("qCustomer", SelCustomer);
	vQry.SetParameter("qCustomerIsEmpty", Not ValueIsFilled(SelCustomer));
	vQry.SetParameter("qContract", SelContract);
	vQry.SetParameter("qContractIsEmpty", Not ValueIsFilled(SelContract));
	vQry.SetParameter("qAgent", SelAgent);
	vQry.SetParameter("qAgentIsEmpty", Not ValueIsFilled(SelAgent));
	vQry.SetParameter("qRoomQuotas", SelRoomQuotas);
	vQry.SetParameter("qRoomQuotasAreEmpty", ?(SelRoomQuotas.Count() = 0, True, False));
	vQry.SetParameter("qRoomQuota", ?(SelRoomQuotas.Count() = 1 And ValueIsFilled(SelRoomQuotas.Get(0).Value), SelRoomQuotas.Get(0).Value, Catalogs.RoomQuotas.EmptyRef()));
	vQry.SetParameter("qRoomQuotaIsElement", ?(SelRoomQuotas.Count() = 1 And ValueIsFilled(SelRoomQuotas.Get(0).Value), Not SelRoomQuotas.Get(0).Value.IsFolder, False));
	vQry.SetParameter("qRoomQuotaDescription", ?(SelRoomQuotas.Count() = 1 And ValueIsFilled(SelRoomQuotas.Get(0).Value), SelRoomQuotas.Get(0).Value.Description, ""));
	vQry.SetParameter("qRoomQuotaSortCode", ?(SelRoomQuotas.Count() = 1 And ValueIsFilled(SelRoomQuotas.Get(0).Value), SelRoomQuotas.Get(0).Value.SortCode, 0));
	If SelRoomQuotas.Count() = 1 And ValueIsFilled(SelRoomQuotas.Get(0).Value) And Not SelRoomQuotas.Get(0).Value.IsFolder Then
		vSelRoomQuota = SelRoomQuotas.Get(0).Value;
		If ValueIsFilled(vSelRoomQuota.BaseRoomQuota) And Not vSelRoomQuota.BaseRoomQuota.IsFolder Then
			vQry.SetParameter("qBaseRoomQuota", vSelRoomQuota.BaseRoomQuota);
			vQry.SetParameter("qBaseRoomQuotaIsFilled", True);
		Else
			vQry.SetParameter("qBaseRoomQuota", Catalogs.RoomQuotas.EmptyRef());
			vQry.SetParameter("qBaseRoomQuotaIsFilled", False);
		EndIf;
	Else
		vQry.SetParameter("qBaseRoomQuota", Catalogs.RoomQuotas.EmptyRef());
		vQry.SetParameter("qBaseRoomQuotaIsFilled", False);
	EndIf;
	vQry.SetParameter("qEmptyRoomQuota", Catalogs.RoomQuotas.EmptyRef());
	vQry.SetParameter("qEmptyRoomRate", Catalogs.RoomRates.EmptyRef());
	vQry.SetParameter("qEmptyString", "");
	vCurrentDateTime = CurrentSessionDate();
	vCurrentDate = BegOfDay(vCurrentDateTime);
	vQry.SetParameter("qCurrentDate", vCurrentDate);
	If BegOfDay(SelPeriodFrom) < vCurrentDate Then
		vQry.SetParameter("qUsePast", True);
		vQry.SetParameter("qPeriodFromForThePast", BegOfDay(SelPeriodFrom) - 24*3600);
		vQry.SetParameter("qPeriodToForThePast", EndOfDay(vCurrentDateTime));
	Else
		vQry.SetParameter("qUsePast", False);
		vQry.SetParameter("qPeriodFromForThePast", BegOfDay(SelPeriodFrom) - 24*3600);
		vQry.SetParameter("qPeriodToForThePast", EndOfDay(SelPeriodTo) + 24*3600);
	EndIf;
	If BegOfDay(SelPeriodFrom) <= vCurrentDate And BegOfDay(SelPeriodTo) >= vCurrentDate Then
		vQry.SetParameter("qUseToday", True);
		vCT = '00010101' + (vCurrentDateTime - BegOfDay(vCurrentDateTime));
		vDateTimeFromToday = vCurrentDate;
		If ValueIsFilled(SelHotel) And ValueIsFilled(SelHotel.RoomRate) And SelHotel.RoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour Then
			vRH = '00010101120000';
			vCI = '00010101120000';
			If ValueIsFilled(SelHotel) And ValueIsFilled(SelHotel.RoomRate) And ValueIsFilled(SelHotel.RoomRate.ReferenceHour) Then
				vRH = '00010101' + (SelHotel.RoomRate.ReferenceHour - BegOfDay(SelHotel.RoomRate.ReferenceHour));
				vCI = vRH;
			EndIf;
			If ValueIsFilled(SelHotel) And ValueIsFilled(SelHotel.RoomRate) And ValueIsFilled(SelHotel.RoomRate.DefaultCheckInTime) Then
				vCI = '00010101' + (SelHotel.RoomRate.DefaultCheckInTime - BegOfDay(SelHotel.RoomRate.DefaultCheckInTime));
			EndIf;
			If vCT < vCI Then
				vDateTimeFromToday = cm1SecondShift(vCurrentDate + (vCI - BegOfDay(vCI)));
			Else
				vDateTimeFromToday = cm1SecondShift(vCurrentDate + (vCT - BegOfDay(vCT)));
			EndIf;
		Else
			vDateTimeFromToday = vCurrentDateTime;
		EndIf;
		vQry.SetParameter("qPeriodFromForToday", vDateTimeFromToday);
		vQry.SetParameter("qPeriodToForToday", EndOfDay(vCurrentDateTime) + 24*3600);
	Else
		vQry.SetParameter("qUseToday", False);
		vQry.SetParameter("qPeriodFromForToday", BegOfDay(SelPeriodFrom) - 24*3600);
		vQry.SetParameter("qPeriodToForToday", EndOfDay(SelPeriodTo) + 24*3600);
	EndIf;
	If BegOfDay(SelPeriodTo) > vCurrentDate Then
		vQry.SetParameter("qUseFuture", True);
		vQry.SetParameter("qPeriodFromForTheFuture", vCurrentDate);
		vQry.SetParameter("qPeriodToForTheFuture", EndOfDay(SelPeriodTo) + 24*3600);
	Else
		vQry.SetParameter("qUseFuture", False);
		vQry.SetParameter("qPeriodFromForTheFuture", BegOfDay(SelPeriodFrom) - 24*3600);
		vQry.SetParameter("qPeriodToForTheFuture", EndOfDay(SelPeriodTo) + 24*3600);
	EndIf;
	vQry.SetParameter("qPeriodFrom", BegOfDay(SelPeriodFrom) - 24*3600);
	vQry.SetParameter("qPeriodTo", EndOfDay(SelPeriodTo) + 24*3600);
	vQry.SetParameter("qShiftInSeconds", ?(ValueIsFilled(SelHotel) And ValueIsFilled(SelHotel.RoomRate) And ValueIsFilled(SelHotel.RoomRate.ReferenceHour), -(SelHotel.RoomRate.ReferenceHour - BegOfDay(SelHotel.RoomRate.ReferenceHour)), -43200));
	vQry.SetParameter("qShowForecast", ?(SelMode = 2, True, False));
	vQry.SetParameter("qStatus", SelStatus);
	vQry.SetParameter("qStatusIsEmpty", Not ValueIsFilled(SelStatus));
	vQry.SetParameter("qAllotmentBusinessType", SelAllotmentBusinessType);
	vQry.SetParameter("qAllotmentBusinessTypeIsEmpty", Not ValueIsFilled(SelAllotmentBusinessType));
	vQry.Execute();
	
	// Merge balances to the one value table
	vQry = New Query();
	vQry.TempTablesManager = vTempTablesManager;
	vQry.Text = 
	"SELECT
	|	BalancesByDates.Hotel AS Hotel,
	|	BalancesByDates.HotelDescription AS HotelDescription,
	|	BalancesByDates.HotelSortCode AS HotelSortCode,
	|	BalancesByDates.RoomQuota AS RoomQuota,
	|	BalancesByDates.RoomQuotaDescription AS RoomQuotaDescription,
	|	BalancesByDates.RoomQuotaSortCode AS RoomQuotaSortCode,
	|	BalancesByDates.RoomType AS RoomType,
	|	BalancesByDates.RoomTypeDescription AS RoomTypeDescription,
	|	BalancesByDates.RoomTypeSortCode AS RoomTypeSortCode,
	|	BalancesByDates.PeriodDate AS PeriodDate,
	|	SUM(BalancesByDates.TotalRooms) AS TotalRooms,
	|	SUM(BalancesByDates.TotalBeds) AS TotalBeds,
	|	SUM(BalancesByDates.TotalSpecialRooms) AS TotalSpecialRooms,
	|	SUM(BalancesByDates.TotalSpecialBeds) AS TotalSpecialBeds,
	|	SUM(BalancesByDates.RoomsBlocked) AS RoomsBlocked,
	|	SUM(BalancesByDates.BedsBlocked) AS BedsBlocked,
	|	SUM(BalancesByDates.RoomsVacant) AS RoomsVacant,
	|	SUM(BalancesByDates.BedsVacant) AS BedsVacant,
	|	SUM(BalancesByDates.SpecialRoomsVacant) AS SpecialRoomsVacant,
	|	SUM(BalancesByDates.SpecialBedsVacant) AS SpecialBedsVacant,
	|	SUM(BalancesByDates.TentativeRooms) AS TentativeRooms,
	|	SUM(BalancesByDates.TentativeBeds) AS TentativeBeds,
	|	SUM(BalancesByDates.RoomsInQuota) AS RoomsInQuota,
	|	SUM(BalancesByDates.BedsInQuota) AS BedsInQuota,
	|	SUM(BalancesByDates.InitialRoomsInQuota) AS InitialRoomsInQuota,
	|	SUM(BalancesByDates.InitialBedsInQuota) AS InitialBedsInQuota,
	|	SUM(BalancesByDates.RoomsRemains) AS RoomsRemains,
	|	SUM(BalancesByDates.BedsRemains) AS BedsRemains,
	|	SUM(BalancesByDates.RoomsForecast) AS RoomsForecast,
	|	SUM(BalancesByDates.BedsForecast) AS BedsForecast
	|FROM
	|	(SELECT
	|		InventoryBalances.PeriodDate AS PeriodDate,
	|		InventoryBalances.Hotel AS Hotel,
	|		InventoryBalances.HotelDescription AS HotelDescription,
	|		InventoryBalances.HotelSortCode AS HotelSortCode,
	|		InventoryBalances.RoomQuota AS RoomQuota,
	|		InventoryBalances.RoomQuotaDescription AS RoomQuotaDescription,
	|		InventoryBalances.RoomQuotaSortCode AS RoomQuotaSortCode,
	|		InventoryBalances.RoomType AS RoomType,
	|		InventoryBalances.RoomTypeDescription AS RoomTypeDescription,
	|		InventoryBalances.RoomTypeSortCode AS RoomTypeSortCode,
	|		InventoryBalances.TotalRooms AS TotalRooms,
	|		InventoryBalances.TotalBeds AS TotalBeds,
	|		InventoryBalances.TotalSpecialRooms AS TotalSpecialRooms,
	|		InventoryBalances.TotalSpecialBeds AS TotalSpecialBeds,
	|		InventoryBalances.RoomsBlocked AS RoomsBlocked,
	|		InventoryBalances.BedsBlocked AS BedsBlocked,
	|		InventoryBalances.RoomsVacant AS RoomsVacant,
	|		InventoryBalances.BedsVacant AS BedsVacant,
	|		InventoryBalances.SpecialRoomsVacant AS SpecialRoomsVacant,
	|		InventoryBalances.SpecialBedsVacant AS SpecialBedsVacant,
	|		InventoryBalances.TentativeRooms AS TentativeRooms,
	|		InventoryBalances.TentativeBeds AS TentativeBeds,
	|		0 AS RoomsInQuota,
	|		0 AS BedsInQuota,
	|		0 AS InitialRoomsInQuota,
	|		0 AS InitialBedsInQuota,
	|		0 AS RoomsRemains,
	|		0 AS BedsRemains,
	|		0 AS RoomsForecast,
	|		0 AS BedsForecast
	|	FROM
	|		RoomInventoryBalances AS InventoryBalances
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AllotmentBalancesAllRoomTypes.PeriodDate,
	|		AllotmentBalancesAllRoomTypes.Hotel,
	|		AllotmentBalancesAllRoomTypes.HotelDescription,
	|		AllotmentBalancesAllRoomTypes.HotelSortCode,
	|		AllotmentBalancesAllRoomTypes.RoomQuota,
	|		AllotmentBalancesAllRoomTypes.RoomQuotaDescription,
	|		AllotmentBalancesAllRoomTypes.RoomQuotaSortCode,
	|		AllotmentBalancesAllRoomTypes.RoomType,
	|		AllotmentBalancesAllRoomTypes.RoomTypeDescription,
	|		AllotmentBalancesAllRoomTypes.RoomTypeSortCode,
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
	|		AllotmentBalancesAllRoomTypes.RoomsInQuota,
	|		AllotmentBalancesAllRoomTypes.BedsInQuota,
	|		AllotmentBalancesAllRoomTypes.InitialRoomsInQuota,
	|		AllotmentBalancesAllRoomTypes.InitialBedsInQuota,
	|		AllotmentBalancesAllRoomTypes.RoomsRemains,
	|		AllotmentBalancesAllRoomTypes.BedsRemains,
	|		0,
	|		0
	|	FROM
	|		AllotmentBalancesAllRoomTypes AS AllotmentBalancesAllRoomTypes
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ForecastData.PeriodDate,
	|		ForecastData.Hotel,
	|		ForecastData.HotelDescription,
	|		ForecastData.HotelSortCode,
	|		ForecastData.RoomQuota,
	|		ForecastData.RoomQuotaDescription,
	|		ForecastData.RoomQuotaSortCode,
	|		ForecastData.RoomType,
	|		ForecastData.RoomTypeDescription,
	|		ForecastData.RoomTypeSortCode,
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
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		ForecastData.RoomsForecast,
	|		ForecastData.BedsForecast
	|	FROM
	|		ForecastData AS ForecastData) AS BalancesByDates
	|
	|GROUP BY
	|	BalancesByDates.Hotel,
	|	BalancesByDates.HotelDescription,
	|	BalancesByDates.HotelSortCode,
	|	BalancesByDates.RoomQuota,
	|	BalancesByDates.RoomQuotaDescription,
	|	BalancesByDates.RoomQuotaSortCode,
	|	BalancesByDates.RoomType,
	|	BalancesByDates.RoomTypeDescription,
	|	BalancesByDates.RoomTypeSortCode,
	|	BalancesByDates.PeriodDate
	|
	|ORDER BY
	|	HotelSortCode,
	|	HotelDescription,
	|	RoomQuotaSortCode,
	|	RoomQuotaDescription,
	|	RoomTypeSortCode,
	|	RoomTypeDescription,
	|	PeriodDate";
	vQry.SetParameter("qHotel", SelHotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(SelHotel));
	vQry.SetParameter("qRoomTypes", SelRoomTypes);
	vQry.SetParameter("qRoomTypesAreEmpty", ?(SelRoomTypes.Count() = 0, True, False));
	vQry.SetParameter("qRoomRate", SelRoomRate);
	vQry.SetParameter("qRoomRateIsEmpty", Not ValueIsFilled(SelRoomRate));
	vQry.SetParameter("qCustomer", SelCustomer);
	vQry.SetParameter("qCustomerIsEmpty", Not ValueIsFilled(SelCustomer));
	vQry.SetParameter("qContract", SelContract);
	vQry.SetParameter("qContractIsEmpty", Not ValueIsFilled(SelContract));
	vQry.SetParameter("qAgent", SelAgent);
	vQry.SetParameter("qAgentIsEmpty", Not ValueIsFilled(SelAgent));
	vQry.SetParameter("qRoomQuotas", SelRoomQuotas);
	vQry.SetParameter("qRoomQuotasAreEmpty", ?(SelRoomQuotas.Count() = 0, True, False));
	vQry.SetParameter("qEmptyRoomQuota", Catalogs.RoomQuotas.EmptyRef());
	vQry.SetParameter("qEmptyRoomRate", Catalogs.RoomRates.EmptyRef());
	vQry.SetParameter("qEmptyString", "");
	vQry.SetParameter("qPeriodFrom", BegOfDay(SelPeriodFrom) - 24 * 3600);
	vQry.SetParameter("qPeriodTo", EndOfDay(SelPeriodTo) + 24 * 3600);
	vResult = vQry.Execute().Unload();
	
	vTempTablesManager.Close();
	
	Return vResult;
EndFunction // GetAllotmentPeriodsBalances

// -----------------------------------------------------------------------------
Function GetAllotmentADRs(pAllotmentsList)
	// Build room inventory and allotment balances
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomQuotaSales.Recorder AS ParentDoc
	|INTO ParentDocsForADR
	|FROM
	|	AccumulationRegister.RoomQuotaSales AS RoomQuotaSales
	|WHERE
	|	RoomQuotaSales.RoomQuota IN(&qAllotmentsList)
	|	AND (RoomQuotaSales.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND CASE
	|			WHEN RoomQuotaSales.Recorder REFS Document.Reservation
	|					AND CAST(RoomQuotaSales.Recorder AS Document.Reservation).CheckInDate < &qPeriodTo
	|					AND CAST(RoomQuotaSales.Recorder AS Document.Reservation).CheckOutDate > &qPeriodFrom
	|				THEN TRUE
	|			WHEN RoomQuotaSales.Recorder REFS Document.Accommodation
	|					AND CAST(RoomQuotaSales.Recorder AS Document.Accommodation).CheckInDate < &qPeriodTo
	|					AND CAST(RoomQuotaSales.Recorder AS Document.Accommodation).CheckOutDate > &qPeriodFrom
	|				THEN TRUE
	|			ELSE FALSE
	|		END
	|
	|GROUP BY
	|	RoomQuotaSales.Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SalesForecast.Hotel AS Hotel,
	|	SalesForecast.RoomQuota AS RoomQuota,
	|	SUM(SalesForecast.Sales) AS Sales,
	|	SUM(SalesForecast.RoomsRented) AS RoomsRented
	|FROM
	|	(SELECT
	|		SalesTurnovers.Hotel AS Hotel,
	|		SalesTurnovers.ParentDoc.RoomQuota AS RoomQuota,
	|		SalesTurnovers.SalesTurnover AS Sales,
	|		SalesTurnovers.RoomsRentedTurnover AS RoomsRented
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				,
	|				,
	|				PERIOD,
	|				ParentDoc IN
	|					(SELECT
	|						ParentDocsForADR.ParentDoc
	|					FROM
	|						ParentDocsForADR AS ParentDocsForADR)) AS SalesTurnovers
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		SalesForecastTurnovers.Hotel,
	|		SalesForecastTurnovers.ParentDoc.RoomQuota,
	|		SalesForecastTurnovers.SalesTurnover,
	|		SalesForecastTurnovers.RoomsRentedTurnover
	|	FROM
	|		AccumulationRegister.SalesForecast.Turnovers(
	|				&qCurrentDate,
	|				,
	|				PERIOD,
	|				ParentDoc IN
	|					(SELECT
	|						ParentDocsForADR.ParentDoc
	|					FROM
	|						ParentDocsForADR AS ParentDocsForADR)) AS SalesForecastTurnovers) AS SalesForecast
	|
	|GROUP BY
	|	SalesForecast.Hotel,
	|	SalesForecast.RoomQuota";
	vQry.SetParameter("qHotel", SelHotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(SelHotel));
	vQry.SetParameter("qAllotmentsList", pAllotmentsList);
	vQry.SetParameter("qPeriodFrom", BegOfDay(SelPeriodFrom) - 24 * 3600);
	vQry.SetParameter("qPeriodTo", EndOfDay(SelPeriodTo) + 24 * 3600);
	vQry.SetParameter("qCurrentDate", ?(ValueIsFilled(SelHotel), ?(ValueIsFilled(SelHotel.AccountingDate), SelHotel.AccountingDate, BegOfDay(CurrentSessionDate())), BegOfDay(CurrentSessionDate())));
	Return vQry.Execute().Unload();
EndFunction // GetAllotmentADRs

// -----------------------------------------------------------------------------
Function GetAllotmentPlannedADRs(pAllotmentsList)
	// Build room inventory and allotment balances
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	AllotmentRoomTypes.RoomType.Owner AS Hotel,
	|	AllotmentRoomTypes.Ref AS RoomQuota,
	|	AllotmentRoomTypes.Currency AS Currency,
	|	SUM(AllotmentRoomTypes.Price * DATEDIFF(AllotmentRoomTypes.PeriodTo, AllotmentRoomTypes.PeriodFrom, DAY)) AS Sales,
	|	SUM(DATEDIFF(AllotmentRoomTypes.PeriodTo, AllotmentRoomTypes.PeriodFrom, DAY)) AS RoomsRented
	|FROM
	|	Catalog.RoomQuotas.RoomTypes AS AllotmentRoomTypes
	|WHERE
	|	AllotmentRoomTypes.Ref IN(&qAllotmentsList)
	|	AND (AllotmentRoomTypes.RoomType.Owner IN HIERARCHY (&qHotel)
	|			OR &qHotelIsEmpty)
	|	AND AllotmentRoomTypes.IsPriceSetting
	|
	|GROUP BY
	|	AllotmentRoomTypes.RoomType.Owner,
	|	AllotmentRoomTypes.Ref,
	|	AllotmentRoomTypes.Currency";
	vQry.SetParameter("qHotel", SelHotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(SelHotel));
	vQry.SetParameter("qAllotmentsList", pAllotmentsList);
	Return vQry.Execute().Unload();
EndFunction // GetAllotmentPlannedADRs

// -----------------------------------------------------------------------------
Procedure BuildFilterDescription()
	TSearchResult = NStr("en='Quotas by: ';ru='Квоты по: ';de='Quote nach: '");
	If ValueIsFilled(SelRoomRate) Then
		TSearchResult = TSearchResult + NStr("en='room rate; ';ru='тарифу; ';de='dem Tarif; '");
	EndIf;
	If ValueIsFilled(SelCustomer) Then
		TSearchResult = TSearchResult + NStr("de='Firma; ';en='customer; ';ru='контрагенту; '");
	EndIf;
	If ValueIsFilled(SelContract) Then
		TSearchResult = TSearchResult + NStr("en='contract; ';ru='договору; ';de='Verträge; '");
	EndIf;
	If ValueIsFilled(SelAgent) Then
		TSearchResult = TSearchResult + NStr("en='agent; ';ru='агенту; ';de='dem Vertreter; '");
	EndIf;
	If SelRoomQuotas.Count() > 0 Then
		TSearchResult = TSearchResult + NStr("en='quota; ';ru='квоте; ';de='der Quote; '");
	EndIf;
	If ValueIsFilled(SelPeriodFrom) Or ValueIsFilled(SelPeriodTo) Then
		TSearchResult = TSearchResult + NStr("en='period; ';ru='периоду; ';de='Zeitraum; '");
	EndIf;
	If SelRoomTypes.Count() > 0 Then
		TSearchResult = TSearchResult + NStr("en='room type; ';ru='типу номера; ';de='Zimmertypen; '");
	EndIf;
	If ValueIsFilled(SelHotel) Then
		TSearchResult = TSearchResult + NStr("en='hotel;';ru='гостинице;';de='Hotel;'");
	EndIf;
	TSearchResult = Upper(TSearchResult);
EndProcedure // BuildFilterDescription

// -----------------------------------------------------------------------------
&AtServer
Procedure SelPeriodFromOnChangeAtServer()
	SelPeriodFrom = BegOfDay(SelPeriodFrom);
	If SelPeriodFrom >= SelPeriodTo Then
		SelPeriodTo = EndOfDay(SelPeriodFrom) + 24 * 3600 *(SelNumberOfDays-1);
	Else
		SelNumberOfDays = (EndOfDay(SelPeriodTo) - BegOfDay(SelPeriodFrom))/(24 * 3600);
	EndIf;
	// Generate report
	GenerateReport();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SelNumberOfDaysOnChangeAtServer()
	SelPeriodTo = EndOfDay(SelPeriodFrom) + 24 * 3600 *(SelNumberOfDays - 1);
	// Generate report
	GenerateReport();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SelPeriodToOnChangeAtServer()
	SelPeriodTo = EndOfDay(SelPeriodTo);
	SelNumberOfDays = (EndOfDay(SelPeriodTo) - BegOfDay(SelPeriodFrom)) / (24 * 3600);
	// Generate report
	GenerateReport();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SelShowOccupationPercentOnChangeAtServer()
	// Generate report
	GenerateReport();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SelCustomerOnChangeAtServer()
	// Generate report
	GenerateReport();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SelAgentOnChangeAtServer()
	// Generate report
	GenerateReport();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SelRoomQuotasOnChangeAtServer()
	If SelRoomQuotas.Count() > 0 Then
		Items.SelRoomQuotas.InputHint = "";
	Else
		Items.SelRoomQuotas.InputHint = NStr("en='<All if empty>'; ru='<По всем, если пусто>'; de='<Alle, falls leer>'");
	EndIf;
	If SelRoomQuotas.Count() = 1 And ValueIsFilled(SelRoomQuotas.Get(0).Value) And Not SelRoomQuotas.Get(0).Value.IsFolder Then
		RoomQuota = SelRoomQuotas.Get(0).Value;
		// Initialize period
		vRoomRate = Undefined;
		If ValueIsFilled(SelRoomRate) And Not SelRoomRate.IsFolder Then
			vRoomRate = SelRoomRate;
		EndIf;
		If Not ValueIsFilled(vRoomRate) Then
			If ValueIsFilled(RoomQuota.Hotel) Then
				vRoomRate = RoomQuota.Hotel.RoomRate;
			ElsIf ValueIsFilled(SelHotel) And Not SelHotel.IsFolder Then
				vRoomRate = SelHotel.RoomRate;
			EndIf;
		EndIf;
		PeriodFrom = cm0SecondShift(cmInitializeDateTime(PeriodFrom, vRoomRate));
		PeriodFromTime = cmExtractTime(PeriodFrom);
		PeriodTo = cm0SecondShift(cmInitializeDateTime(PeriodTo, vRoomRate));
		PeriodToTime = cmExtractTime(PeriodTo);
		Duration = cmCalculateDuration(vRoomRate, PeriodFrom, PeriodTo);
		PriceNumberOfAdults = RoomQuota.PriceNumberOfAdults;
	EndIf;
	If SelRoomQuotas.Count() > 0 Then
		If SelShowFreeSaleOnly Then
			SelShowFreeSaleOnly = False;
		EndIf;
	EndIf;
	If SelRoomQuotas.Count() = 0 Or SelRoomQuotas.Count() > 0 And ValueIsFilled(SelRoomQuotas.Get(0).Value) And SelRoomQuotas.Get(0).Value.IsFolder Then
		SelShowReservations = False;
	EndIf;
	// Generate report
	GenerateReport();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SelShowFreeSaleOnlyOnChangeAtServer()
	If SelShowFreeSaleOnly Then
		If SelRoomQuotas.Count() > 0 Then
			SelRoomQuotas.Clear();
		EndIf;
		SelShowReservations = True;
	EndIf;
	// Generate report
	GenerateReport();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SelRoomTypesOnChangeAtServer()
	If SelRoomTypes.Count() > 0 Then
		Items.SelRoomTypes.InputHint = "";
	Else
		Items.SelRoomTypes.InputHint = NStr("en='<All if empty>'; ru='<По всем, если пусто>'; de='<Alle, falls leer>'");
	EndIf;
	If SelRoomTypes.Count() = 1 And ValueIsFilled(SelRoomTypes.Get(0).Value) And Not SelRoomTypes.Get(0).Value.IsFolder Then
		RoomType = SelRoomTypes.Get(0).Value;
	EndIf;
	// Generate report
	GenerateReport();
	// Recalculate templates
	CalculateAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure ResetSearchFilterAtServer()
	// Reset filter to default values
	SelRoomRate = Catalogs.RoomRates.EmptyRef();
	SelCustomer = Catalogs.Customers.EmptyRef();
	SelContract = Catalogs.Contracts.EmptyRef();
	SelAgent = Catalogs.Customers.EmptyRef();
	SelHotel = SessionParameters.CurrentHotel;
	SelRoomTypes.Clear();
	SelRoomQuotas.Clear();
	SelStatus = Undefined;
	SelAllotmentBusinessType = Undefined;
	SelShowReservations = False;
	SelShowFreeSaleOnly = False;
	// Generate report
	GenerateReport();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SelHotelOnChangeAtServer()
	FillAllRoomTypes();
	// Change current hotel in the session parameters
	If ValueIsFilled(SelHotel) Then
		// Reset bound filters
		SelRoomRate = Catalogs.RoomRates.EmptyRef();
		SelCurrency = SelHotel.BaseCurrency;
	EndIf;
	// Set hotel color          
	Items.GroupMainFilters.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
	// Clear templates
	AccommodationTemplates.GetItems().Clear();
	// Clear quantities being saved
	PrevTemplateRowQuantities.Clear();
	// Generate report
	GenerateReport();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure PrevDateAtServer()
	SelPeriodTo = EndOfDay(SelPeriodFrom);
	SelPeriodFrom = BegOfDay(SelPeriodTo) - 24 * 3600*(SelNumberOfDays - 1);
	// Generate report
	GenerateReport();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ReportSpreadsheetOnActivateArea(pControl)
	RulerColor = WebColors.Red;
	RulerBorder = New Line(SpreadsheetDocumentCellLineType.LargeDashed, 1, False);
	NoBorder = New Line(SpreadsheetDocumentCellLineType.None);
	NoBorderColor = ReportSpreadsheet.Area(1,1,1,1).BorderColor;	
	SkipOnActivateArea = False;
	pControl = ReportSpreadsheet; 
	vSelAreas = items.ReportSpreadsheet.GetSelectedAreas();	
	If SkipOnActivateArea Then
		Return;
	EndIf;	
	Try
		If pControl.SelectedAreas.Count() > 1 Then
			SkipOnActivateArea = True;
			pControl.SelectedAreas.Delete(pControl.SelectedAreas.Get(0));
			SkipOnActivateArea = False;
		EndIf;
		If LeftAreaSelected <> Undefined Then
			LeftAreaSelected.LeftBorder = NoBorder;
			LeftAreaSelected.BorderColor = NoBorderColor;
		EndIf;
		If RightAreaSelected <> Undefined Then
			RightAreaSelected.RightBorder = NoBorder;
			RightAreaSelected.BorderColor = NoBorderColor;
		EndIf;
		vLeftColumn = 999999999;
		vRightColumn = 0;
		vCheckInPeriodIsSelected = False;
		vSelAreas = pControl.SelectedAreas;		
		For Each vSelArea In vSelAreas Do
			// Currently only one row could be selected
			If SelMode = 0 Then
				If vSelArea.Left > 5 Then
					If (vSelArea.Bottom - vSelArea.Top) > 0 Then
						SkipOnActivateArea = True;
						
						If SelectionTopRow <> 0 Then
							vNewSelArea = pControl.Area(SelectionTopRow, vSelArea.Left, SelectionTopRow, vSelArea.Right);
						Else
							vNewSelArea = pControl.Area(vSelArea.Top, vSelArea.Left, vSelArea.Top, vSelArea.Right);
						EndIf;
						vSelAreaIndex = vSelAreas.IndexOf(vSelArea);
						vSelArea = vNewSelArea;
						vArray = New Array;
						vArray.Add(vSelArea);
						Items.ReportSpreadsheet.SetSelectedAreas(vArray);
						
						SkipOnActivateArea = False;
					Else
						SelectionTopRow = vSelArea.Top;
					EndIf;
				EndIf;
				// Fix selection left and right borders
				If vSelArea.Left > 6 Then
					vLeftDelta = (vSelArea.Left - 9) / 4 - Int((vSelArea.Left - 9) / 4);
					vRightDelta = (vSelArea.Right - 10) / 4 - Int((vSelArea.Right - 10) / 4);
					If vLeftDelta <> 0 Or vRightDelta <> 0 Then
						SkipOnActivateArea = True;
						vNewLeft = vSelArea.Left;
						If vLeftDelta <> 0 Then
							vNewLeft = vSelArea.Left - Round(vLeftDelta * 4, 0);
						EndIf;
						vNewRight = vSelArea.Right;
						If vRightDelta <> 0 Then
							vNewRight = vSelArea.Right - Round(vRightDelta * 4, 0) + 4;
						EndIf;
						vNewSelArea = pControl.Area(vSelArea.Top, vNewLeft, vSelArea.Top, vNewRight);
						vSelAreaIndex = vSelAreas.IndexOf(vSelArea);
						vSelArea = vNewSelArea;
						vArray = New Array;
						vArray.Add(vSelArea);
						Items.ReportSpreadsheet.SetSelectedAreas(vArray);	
						
						SkipOnActivateArea = False;
					EndIf;
				EndIf;
				// Clear previously selected areas
				If LastSelectedRange <> Undefined Then
					r = 0;
					While r < LastSelectedRangeText.Count() Do
						vLastSelectedRangeTextRow = LastSelectedRangeText.Get(r);
						If vLastSelectedRangeTextRow.Left <> vSelArea.Left Or vLastSelectedRangeTextRow.Top <> vSelArea.Top Then
							vCell = pControl.Area(vLastSelectedRangeTextRow.Top, vLastSelectedRangeTextRow.Left);
							vCell.Text = vLastSelectedRangeTextRow.Text;
							LastSelectedRangeText.Delete(r);
						Else
							r = r + 1;
						EndIf;
					EndDo;
				EndIf;
			EndIf;
			// Check selection details
			vLeftColumn = Min(vLeftColumn, vSelArea.Left);
			vRightColumn = Max(vRightColumn, vSelArea.Right);
			vDetailsLeft = pControl.Area(vSelArea.Top, vSelArea.Left).Details;
			vDetailsRight = pControl.Area(vSelArea.Top, vSelArea.Right).Details;
			If vDetailsLeft <> Undefined And 
				vDetailsRight <> Undefined And 
				(TypeOf(vDetailsLeft) = Type("Structure") And
				TypeOf(vDetailsRight) = Type("Structure")) Or
				((TypeOf(vDetailsLeft) = Type("DocumentRef.Accommodation") Or TypeOf(vDetailsLeft) = Type("DocumentRef.Reservation")) And
				(TypeOf(vDetailsRight) = Type("DocumentRef.Accommodation") Or TypeOf(vDetailsRight) = Type("DocumentRef.Reservation"))) Then
				vHotel = PredefinedValue("Catalog.Hotels.EmptyRef");
				vRoomType = PredefinedValue("Catalog.RoomTypes.EmptyRef");
				vRoomQuota = PredefinedValue("Catalog.RoomQuotas.EmptyRef");
				vRoomRate = PredefinedValue("Catalog.RoomRates.EmptyRef");
				vRoomRateQ = PredefinedValue("Catalog.RoomRates.EmptyRef");
				If TypeOf(vDetailsLeft) = Type("DocumentRef.Accommodation") Or TypeOf(vDetailsLeft) = Type("DocumentRef.Reservation") Then
					vHotel = tcOnServer.cmGetAttributeByRef(vDetailsLeft, "Hotel");
					vRoomType = tcOnServer.cmGetAttributeByRef(vDetailsLeft, "RoomType");
					vRoomQuota = tcOnServer.cmGetAttributeByRef(vDetailsLeft, "RoomQuota");
					If ValueIsFilled(vRoomQuota) Then
						vRoomRateQ = tcOnServer.cmGetAttributeByRef(vRoomQuota, "RoomRate");
						If ValueIsFilled(vRoomRateQ) Then
							vRoomRate = vRoomRateQ;
						EndIf;
					EndIf;
				Else
					vHotel = ?(vDetailsLeft.Property("Hotel"), vDetailsLeft.Hotel, Undefined);
					vRoomType = ?(vDetailsLeft.Property("RoomType"), vDetailsLeft.RoomType, Undefined);
					vRoomQuota = ?(vDetailsLeft.Property("RoomQuota"), vDetailsLeft.RoomQuota, Undefined);
					If vDetailsLeft.Property("RoomRateQ") And ValueIsFilled(vDetailsLeft.RoomRateQ) Then
						vRoomRate = vDetailsLeft.RoomRateQ;
					ElsIf ValueIsFilled(vRoomQuota) Then
						vRoomRateQ = tcOnServer.cmGetAttributeByRef(vRoomQuota, "RoomRate");
						If ValueIsFilled(vRoomRateQ) Then
							vRoomRate = vRoomRateQ;
						EndIf;
					EndIf;
				EndIf;
				If Not ValueIsFilled(vRoomQuota) Then
					If SelRoomQuotas.Count() > 0 Then
						vRoomQuota = SelRoomQuotas.Get(0).Value;
					EndIf;
				EndIf;
				If Not ValueIsFilled(vRoomRate) Then
					If TypeOf(vDetailsLeft) = Type("Structure") And vDetailsLeft.Property("RoomRate") And ValueIsFilled(vDetailsLeft.RoomRate) Then
						vRoomRate = vDetailsLeft.RoomRate;
					ElsIf ValueIsFilled(RoomRate) Then
						vRoomRate = RoomRate;
					ElsIf ValueIsFilled(vHotel) Then
						vRoomRate = tcOnServer.cmGetAttributeByRef(vHotel, "RoomRate");
					ElsIf ValueIsFilled(SelHotel) Then
						vRoomRate = tcOnServer.cmGetAttributeByRef(SelHotel, "RoomRate");
					EndIf;
				EndIf;
				vCheckInPeriodIsSelected = True;
				If TypeOf(vDetailsLeft) = Type("DocumentRef.Accommodation") Or TypeOf(vDetailsLeft) = Type("DocumentRef.Reservation") Then
					vPeriodLeft = BegOfDay(tcOnServer.cmGetAttributeByRef(vDetailsLeft, "CheckInDate"));
					vPeriodRight = BegOfDay(tcOnServer.cmGetAttributeByRef(vDetailsLeft, "CheckOutDate"));
				Else
					If Not ValueIsFilled(vDetailsLeft.CheckInDate) Then
						vPeriodLeft = BegOfDay(vDetailsLeft.PeriodDate);
						vPeriodRight = BegOfDay(vDetailsRight.PeriodDate);
					Else
						vPeriodLeft = BegOfDay(vDetailsLeft.CheckInDate);
						vPeriodRight = BegOfDay(vDetailsRight.CheckOutDate);
					EndIf;
				EndIf;
				// Set actions panel attributes
				PeriodFrom = vPeriodLeft;
				PeriodFromTime = PeriodFrom;
				If SelMode > 0 Then
					vPeriodRight = vPeriodRight + 24*3600;
				EndIf;
				PeriodTo = vPeriodRight;
				PeriodToTime = PeriodTo;
				Duration = (vPeriodRight - vPeriodLeft) / 24 / 60 / 60;
				If ValueIsFilled(vRoomQuota) Then
					RoomQuota = vRoomQuota;
				ElsIf SelRoomQuotas.Count() = 1 And ValueIsFilled(SelRoomQuotas.Get(0).Value) And Not SelRoomQuotas.Get(0).Value.IsFolder Then
					RoomQuota = SelRoomQuotas.Get(0).Value;
				Else
					RoomQuota = PredefinedValue("Catalog.RoomQuotas.EmptyRef");
				EndIf;
				If ValueIsFilled(vRoomType) Then
					RoomType = vRoomType;
				ElsIf SelRoomTypes.Count() = 1 And ValueIsFilled(SelRoomTypes.Get(0).Value) And Not SelRoomTypes.Get(0).Value.IsFolder Then
					RoomType = SelRoomTypes.Get(0).Value;
				EndIf;
				If ValueIsFilled(vRoomRate) Then
					RoomRate = vRoomRate;
				ElsIf ValueIsFilled(SelRoomRate) Then
					RoomRate = SelRoomRate;
				EndIf;
				SetPriceTagAppearance();
				If TypeOf(vDetailsLeft) = Type("Structure") And vDetailsLeft.IsCheckInPeriod And 
					Duration > 4 And vSelArea <> LastSelectedRange Then
					LastSelectedRange = vSelArea;
					For n = vSelArea.Left To vSelArea.Right Do
						vCell = pControl.Area(vSelArea.Top, n);
						If Not IsBlankString(vCell.Text) Then
							If LastSelectedRangeText.FindRows(New Structure("Top, Left", vCell.Top, vCell.Left)).Count() = 0 Then
								vLastSelectedRangeTextRow = LastSelectedRangeText.Add();
								vLastSelectedRangeTextRow.Top = vCell.Top;
								vLastSelectedRangeTextRow.Left = vCell.Left;
								vLastSelectedRangeTextRow.Text = TrimR(vCell.Text);
								vCell.Text = vCell.Text + " (" + Duration + NStr("en=' d.';ru=' сут.';de=' Tage'") + ", " + Format(PeriodFrom, "DF=dd.MM") + " - " + Format(PeriodTo, "DF=dd.MM") + ")";
							EndIf;
						EndIf;
					EndDo;
				EndIf;
			EndIf;
			Break; // No multiple selection
		EndDo;
		// Choose vertical range
		If SelMode = 0 Then
			If vCheckInPeriodIsSelected And vLeftColumn < vRightColumn Then
				If Int((vLeftColumn - 5) / 4) = (vLeftColumn - 5) / 4 And Int((vRightColumn - 6) / 4) = (vRightColumn - 6) / 4 Then
					LeftAreaSelected = pControl.Area(, vLeftColumn - 1, , vLeftColumn - 1);
					LeftAreaSelected.LeftBorder = RulerBorder;
					LeftAreaSelected.BorderColor = RulerColor;
					RightAreaSelected = pControl.Area(, vRightColumn + 1, , vRightColumn + 1);
					RightAreaSelected.RightBorder = RulerBorder;
					RightAreaSelected.BorderColor = RulerColor;
				EndIf;
			EndIf;
		EndIf;
	Except
	EndTry;
EndProcedure // ReportSpreadsheetOnActivateArea

// -----------------------------------------------------------------------------
&AtClient
Procedure SetPriceTagAppearance()
	If ValueIsFilled(RoomRate) And DurationTagRoomRates.FindByValue(RoomRate) <> Undefined Then
		Items.PriceTag.Visible = True;
	Else
		PriceTag = PredefinedValue("Catalog.PriceTags.EmptyRef");
		Items.PriceTag.Visible = False;
	EndIf;
EndProcedure // SetPriceTagAppearance

// -----------------------------------------------------------------------------
&AtServer
Procedure FillDurationPriceTagRoomRatesList()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomRates.Ref AS Ref
	|FROM
	|	Catalog.RoomRates AS RoomRates
	|WHERE
	|	NOT RoomRates.DeletionMark
	|	AND NOT RoomRates.IsFolder
	|	AND (RoomRates.Hotel = &qHotel
	|			OR RoomRates.Hotel = &qEmptyHotel)
	|	AND (RoomRates.PriceTagType = &qByDays
	|			OR RoomRates.PriceTagType = &qByPeriod)";
	vQry.SetParameter("qHotel", SelHotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qByDays", Enums.PriceTagTypes.ByDurationOfStayByDays);
	vQry.SetParameter("qByPeriod", Enums.PriceTagTypes.ByDurationOfStayByPeriod);
	vRates = vQry.Execute().Unload();
	DurationTagRoomRates.Clear();
	DurationTagRoomRates.LoadValues(vRates.UnloadColumn("Ref"));
EndProcedure // FillDurationPriceTagRoomRatesList

// -----------------------------------------------------------------------------
&AtServer
Procedure AddRoomsAtServer()   
	vCancel = False;
	// Check attributes
	If Not ValueIsFilled(PeriodFrom) Or Not ValueIsFilled(PeriodTo) Or PeriodTo <= PeriodFrom Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Period is wrong!'; de = 'Der Zeitraum ist falsch angegeben!'; ru = 'Период указан не верно!'"));
		vCancel = True;
	EndIf;
	If Not ValueIsFilled(RoomQuota) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Allotment is not set!'; de = 'Keine Quote ist gewählt!'; ru = 'Не выбрана квота!'"));
		vCancel = True;
	EndIf;
	If Not ValueIsFilled(RoomType) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Room type is not set!'; de = 'Kein Zimmertyp ist gewählt!'; ru = 'Не выбран тип номера!'"));
		vCancel = True;
	EndIf;   
	// Check permissions
	If Not vCancel Then
		If RoomQuota.AllotmentBusinessType = Enums.AllotmentBusinessTypes.BusinessBlock And Not cmCheckUserPermissions("HavePermissionToManageBusinessBlocks") Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to manage business blocks!';ru='Нет прав на управление бизнес-блоками!';de='Sie haben keine Rechte, Geschäftsblocken zu verwalten!'"));
			vCancel = True;
		ElsIf RoomQuota.AllotmentBusinessType <> Enums.AllotmentBusinessTypes.BusinessBlock And Not cmCheckUserPermissions("HavePermissionToManageAllotments") Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to manage allotments!';ru='Нет прав на управление квотами!';de='Sie haben keine Rechte, Allotmenten zu verwalten!'"));
			vCancel = True;
		EndIf;
	EndIf;
	
	If vCancel = True Then
		Return;
	EndIf;
	
	If NumberOfRooms = 0 Then
		If InRooms Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Number of rooms is not set!';ru='Не указано количество номеров!';de='Die Zimmeranzahl ist nicht angegeben!'"));	
			Return;
		Else
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Number of beds is not set!';ru='Не указано количество мест!';de='Die Bettenanzahl ist nicht angegeben!'"));
			Return;
		EndIf;
	EndIf;
	// Try to check that period is equal to the check-in period of allotment to add rooms to
	If RoomQuota.IsForCheckInPeriods Then
		If Not AllDays Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='All weekdays should be marked!'; ru='Все дни недели должны быть отмечены!'; de='Alle Wochentage müssen markiert sein!'"), MessageStatus.Important);
			Return;
		EndIf;
		rMessage = "";
		If Not CheckAllotmentPeriod(rMessage) Then
			tcCommonFunctionOnClientServer.TextMessage(rMessage);
			Return;
		EndIf;
	EndIf;
	
	// Process each selected period
	vPeriods = FillPeriodsToProcess();
	If vPeriods.Count() > 0 Then
		// Update allotment if manual price is specified
		If EditPrice Then
			vAllotmentObj = RoomQuota.GetObject();
			For Each vPeriodsRow In vPeriods Do
				If SelPrice >= 0 And ValueIsFilled(SelCurrency) And (SelNumberOfAdults <> 0 Or SelNumberOfTeenagers <> 0 Or SelNumberOfChildren <> 0 Or SelNumberOfInfants <> 0) Then
					vAllotmentObj.Read();
					vRQRTRows = vAllotmentObj.RoomTypes.FindRows(New Structure("RoomType, PeriodFrom, PeriodTo, IsPriceSetting, NumberOfAdults, NumberOfTeenagers, NumberOfChildren, NumberOfInfants", 
					                                                            RoomType, BegOfDay(vPeriodsRow.PeriodFrom), BegOfDay(vPeriodsRow.PeriodTo),
					                                                            True, SelNumberOfAdults, SelNumberOfTeenagers, SelNumberOfChildren, SelNumberOfInfants));
					If vRQRTRows.Count() > 0 Then
						vRQRTRow = vRQRTRows.Get(vRQRTRows.Count() - 1);
					Else
						vRQRTRow = vAllotmentObj.RoomTypes.Add();
						vRQRTRow.Hotel = RoomType.Owner;
						vRQRTRow.RoomType = RoomType;
						vRQRTRow.PeriodFrom = BegOfDay(vPeriodsRow.PeriodFrom);
						vRQRTRow.PeriodTo = BegOfDay(vPeriodsRow.PeriodTo);
					EndIf;
					vRQRTRow.NumberOfAdults = SelNumberOfAdults;
					vRQRTRow.NumberOfTeenagers = SelNumberOfTeenagers;
					vRQRTRow.NumberOfChildren = SelNumberOfChildren;
					vRQRTRow.NumberOfInfants = SelNumberOfInfants;
					vRQRTRow.NumberOfPersons = SelNumberOfAdults + SelNumberOfTeenagers + SelNumberOfChildren + SelNumberOfInfants;
					vRQRTRow.Price = SelPrice;
					vRQRTRow.Currency = SelCurrency;
					vRQRTRow.IsPriceSetting = True;
				EndIf;
			EndDo;
			If vAllotmentObj.Modified() Then
				vAllotmentObj.Write();
				// Repost set room quota documents intersecting with prices changed
				vRecalculateBusinessBlockBudget = False;
				For Each vPeriodsRow In vPeriods Do
					vSetRoomQuotas = GetIntersectingSetRoomQuotas(RoomQuota, RoomType, vPeriodsRow.PeriodFrom, vPeriodsRow.PeriodTo);
					If vSetRoomQuotas.Count() > 0 Then
						vRecalculateBusinessBlockBudget = True;
						For Each vSetRoomQuotasRow In vSetRoomQuotas Do
							vDocObj = vSetRoomQuotasRow.Ref.GetObject();
							vDocObj.Write(DocumentWriteMode.Posting);
						EndDo;
					EndIf;
				EndDo;
				If vRecalculateBusinessBlockBudget Then
					Catalogs.RoomQuotas.CalculateBusinessBlockBudget(vAllotmentObj.Ref, False);
				EndIf;
			EndIf;
		EndIf;

		// Create new "Set room quota" document and fill it's parameters from the filter page
		If EditInventory Then
			For Each vPeriodsRow In vPeriods Do
				vDocObj = Documents.SetRoomQuota.CreateDocument();
				vDocObj.RoomQuota = RoomQuota;
				vDocObj.BaseRoomQuota = RoomQuota.BaseRoomQuota;
				If ValueIsFilled(vDocObj.RoomQuota.Hotel) Then
					vDocObj.Hotel = vDocObj.RoomQuota.Hotel;
				EndIf;
				vDocObj.RoomType = RoomType;
				If Not ValueIsFilled(vDocObj.Hotel) Then
					vDocObj.Hotel = vDocObj.RoomType.Owner;
				EndIf;
				vDocObj.DateFrom = cm0SecondShift(GetTime(vPeriodsRow.PeriodFrom));
				vDocObj.pmFillAttributesWithDefaultValues();
				vDocObj.NumberOfBedsPerRoom = vDocObj.RoomType.NumberOfBedsPerRoom;
				vDocObj.NumberOfPersonsPerRoom = vDocObj.RoomType.NumberOfPersonsPerRoom;
				vDocObj.DateTo = cm0SecondShift(GetTime(vPeriodsRow.PeriodTo));
				vDocObj.Duration = vDocObj.pmCalculateDuration();
				FillDocumentNumberOfRoomsAndBeds(vDocObj);
				vDocObj.IsForecast = ?(SelMode = 2, True, False);
				vDocObj.IsInitial = ?(SelMode = 1 And SelShowSelector = 1, True, False);
				vDocObj.Write(DocumentWriteMode.Posting);
			EndDo;
		EndIf;
		
		// Build structure with parameters to open report hierarchy
		vStr = New Structure("Hotel, RoomType, RoomQuota", vDocObj.Hotel, vDocObj.RoomType, vDocObj.RoomQuota);
		// Refresh report
		GenerateReport(vStr);
	ElsIf Not AllDays Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Mark at least one day of the week!'; ru='Отметьте хотя бы один день недели!'; de='Markieren Sie mindestens einen Wochentag!'"), MessageStatus.Important);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure NextDateAtServer()
	SelPeriodFrom = BegOfDay(SelPeriodTo);
	SelPeriodTo = EndOfDay(SelPeriodTo) + 24 * 3600*(SelNumberOfDays - 1);
	// Generate report
	GenerateReport();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure DateSwitchOnChangeAtServer()
	x = 1;
	If DateSwitch = 0 Then
		SelPeriodFrom = CurrentSessionDate();
	Else   
		If Month(CurrentSessionDate()) > DateSwitch Then
			SelPeriodFrom = BegOfMonth(AddMonth(CurrentSessionDate(), 12 - Month(CurrentSessionDate()) + DateSwitch));    
		Else
			SelPeriodFrom = BegOfMonth(AddMonth(BegOfYear(CurrentSessionDate()), DateSwitch - 1));    
		EndIf; 
	EndIf;
	SelPeriodTo = EndOfDay(SelPeriodFrom) + 24 * 3600 * (SelNumberOfDays - 1);
	// Generate report
	GenerateReport();
EndProcedure // DateSwitchOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure JoinPeriodsAtServer()
	// Check permissions
	If RoomQuota.AllotmentBusinessType = Enums.AllotmentBusinessTypes.BusinessBlock And Not cmCheckUserPermissions("HavePermissionToManageBusinessBlocks") Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to manage business blocks!';ru='Нет прав на управление бизнес-блоками!';de='Sie haben keine Rechte, Geschäftsblocken zu verwalten!'"));
		Return;
	ElsIf RoomQuota.AllotmentBusinessType <> Enums.AllotmentBusinessTypes.BusinessBlock And Not cmCheckUserPermissions("HavePermissionToManageAllotments") Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to manage allotments!';ru='Нет прав на управление квотами!';de='Sie haben keine Rechte, Allotmenten zu verwalten!'"));
		Return;
	EndIf;
		// Check permissions
	If not RoomQuota.IsForCheckInPeriods Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Joining is possible for allotments that are by check-in periods only!';ru='Объединение дат в период возможно только в квотах по заездам!';de='Die Zusammenfassung von Daten zu einem Zeitraum ist nur innerhalb der Ankunftsallotmenten möglich!'"));
		Return;
	EndIf;
	// Try to find check-in periods selected
	If ValueIsFilled(PeriodFrom) And ValueIsFilled(PeriodTo) Then
		If PeriodFrom < PeriodTo Then
			vMgrObj = InformationRegisters.RoomQuotaCheckInPeriods.CreateRecordManager();
			// Try to find periods that should be deleted
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	RoomRateCheckInPeriods.Hotel AS Hotel,
			|	RoomRateCheckInPeriods.RoomQuota AS RoomQuota,
			|	RoomRateCheckInPeriods.CheckInDate AS CheckInDate,
			|	RoomRateCheckInPeriods.Duration AS Duration,
			|	RoomRateCheckInPeriods.CheckOutDate AS CheckOutDate
			|FROM
			|	InformationRegister.RoomQuotaCheckInPeriods AS RoomRateCheckInPeriods
			|WHERE
			|	RoomRateCheckInPeriods.Hotel = &qHotel
			|	AND RoomRateCheckInPeriods.RoomQuota = &qRoomQuota
			|	AND RoomRateCheckInPeriods.CheckInDate >= &qCheckInDate
			|	AND RoomRateCheckInPeriods.CheckOutDate <= &qCheckOutDate
			|	AND NOT RoomRateCheckInPeriods.IsNotActive
			|
			|ORDER BY
			|	CheckInDate,
			|	Duration";
			vQry.SetParameter("qHotel", SelHotel);
			vQry.SetParameter("qRoomQuota", RoomQuota);
			vQry.SetParameter("qCheckInDate", BegOfDay(PeriodFrom));
			vQry.SetParameter("qCheckOutDate", EndOfDay(PeriodTo));
			vPeriods = vQry.Execute().Unload();     

			BeginTransaction(DataLockControlMode.Managed);
			Try
				For Each vPeriodsRow In vPeriods Do
					vMgrObj.Hotel = vPeriodsRow.Hotel;
					vMgrObj.RoomQuota = vPeriodsRow.RoomQuota;
					vMgrObj.CheckInDate = vPeriodsRow.CheckInDate;
					vMgrObj.Duration = vPeriodsRow.Duration;
					vMgrObj.CheckOutDate = vPeriodsRow.CheckOutDate;
					vMgrObj.Read();
					If vMgrObj.Selected() Then
						vMgrObj.Delete();
					EndIf;
				EndDo;
				// Create one check-in period
				vMgrSet = InformationRegisters.RoomQuotaCheckInPeriods.CreateRecordSet();
				vMgrRec = vMgrSet.Add();
				vMgrRec.Hotel = SelHotel;
				vMgrRec.RoomQuota = RoomQuota;
				vMgrRec.CheckInDate = GetTime(PeriodFrom);
				vMgrRec.Duration = Duration;
				vMgrRec.CheckOutDate = GetTime(PeriodTo);
				vMgrRec.IsManual = True;
				vMgrSet.Write(False);
				// Check if there are intersections with some other periods
				vCheckQry = New Query();
				vCheckQry.Text = 
				"SELECT
				|	RoomQuotaCheckInPeriods.RoomQuota AS RoomQuota,
				|	RoomQuotaCheckInPeriods.CheckInDate AS CheckInDate,
				|	RoomQuotaCheckInPeriods.Duration AS Duration,
				|	RoomQuotaCheckInPeriods.CheckOutDate AS CheckOutDate,
				|	RoomQuotaCheckInPeriods1.CheckInDate AS CheckInDate1,
				|	RoomQuotaCheckInPeriods1.Duration AS Duration1,
				|	RoomQuotaCheckInPeriods1.CheckOutDate AS CheckOutDate1,
				|	RoomQuotaCheckInPeriods.IsManual AS IsManual,
				|	RoomQuotaCheckInPeriods.IsNotActive AS IsNotActive
				|FROM
				|	InformationRegister.RoomQuotaCheckInPeriods AS RoomQuotaCheckInPeriods
				|		INNER JOIN InformationRegister.RoomQuotaCheckInPeriods AS RoomQuotaCheckInPeriods1
				|		ON RoomQuotaCheckInPeriods.Hotel = RoomQuotaCheckInPeriods1.Hotel
				|			AND (NOT RoomQuotaCheckInPeriods.IsNotActive)
				|			AND (NOT RoomQuotaCheckInPeriods1.IsNotActive)
				|			AND (RoomQuotaCheckInPeriods.Hotel = &qHotel)
				|			AND (RoomQuotaCheckInPeriods.RoomQuota = &qRoomQuota)
				|			AND RoomQuotaCheckInPeriods.RoomQuota = RoomQuotaCheckInPeriods1.RoomQuota
				|			AND RoomQuotaCheckInPeriods.CheckOutDate > RoomQuotaCheckInPeriods1.CheckInDate
				|			AND RoomQuotaCheckInPeriods.CheckInDate < RoomQuotaCheckInPeriods1.CheckOutDate
				|			AND (RoomQuotaCheckInPeriods.CheckOutDate <> RoomQuotaCheckInPeriods1.CheckOutDate
				|				OR RoomQuotaCheckInPeriods.CheckInDate <> RoomQuotaCheckInPeriods1.CheckInDate)
				|			AND (RoomQuotaCheckInPeriods.CheckInDate < &qEndOfPeriod)
				|			AND (RoomQuotaCheckInPeriods.CheckOutDate > &qStartOfPeriod)
				|
				|ORDER BY
				|	RoomQuotaCheckInPeriods.RoomQuota.SortCode,
				|	RoomQuotaCheckInPeriods.CheckInDate";
				vCheckQry.SetParameter("qHotel", SelHotel);
				vCheckQry.SetParameter("qRoomQuota", RoomQuota);
				vCheckQry.SetParameter("qStartOfPeriod", GetTime(PeriodFrom));
				vCheckQry.SetParameter("qEndOfPeriod", GetTime(PeriodTo));
				vCheckResults = vCheckQry.Execute().Unload();
				If vCheckResults.Count() > 0 Then
					Raise NStr("en='Other intersecting check-in periods were found! Merge could not be completed.';ru='Найдены периоды пересекающиеся с выбранным! Объединение не может быть выполнено.';de='Es wurden Zeiträume gefunden, die sich mit dem gewählten überschneiden! Es kann keine Vereinigung erfolgen.'");
				EndIf;
				// Write zero rooms initialization document
				vDocObj = Documents.SetRoomQuota.CreateDocument();
				vDocObj.RoomQuota = RoomQuota;
				vDocObj.BaseRoomQuota = RoomQuota.BaseRoomQuota;
				If ValueIsFilled(vDocObj.RoomQuota.Hotel) Then
					vDocObj.Hotel = vDocObj.RoomQuota.Hotel;
				EndIf;
				vDocObj.RoomType = RoomType;
				If Not ValueIsFilled(vDocObj.Hotel) Then
					vDocObj.Hotel = vDocObj.RoomType.Owner;
				EndIf;
				vDocObj.DateFrom = cm0SecondShift(GetTime(PeriodFrom));
				vDocObj.pmFillAttributesWithDefaultValues();
				vDocObj.NumberOfBedsPerRoom = vDocObj.RoomType.NumberOfBedsPerRoom;
				vDocObj.NumberOfPersonsPerRoom = vDocObj.RoomType.NumberOfPersonsPerRoom;
				vDocObj.DateTo = cm0SecondShift(GetTime(PeriodTo));
				vDocObj.Duration = vDocObj.pmCalculateDuration();
				vDocObj.NumberOfRooms = 0;
				vDocObj.NumberOfBeds = 0;
				vDocObj.Write(DocumentWriteMode.Posting);
				// Commit transaction
				CommitTransaction();
			Except          
				RollbackTransaction();
				vErrorDescription = ErrorDescription();

				tcCommonFunctionOnClientServer.TextMessage(vErrorDescription);
			EndTry;
			// Generate report
			GenerateReport();
		Else
			tcCommonFunctionOnClientServer.TextMessage(Nstr("en='Check-in date is later then check-out date!';ru='Дата выезда раньше даты заезда!';de='Das Abreisedatum liegt vor dem Anreisedatum!'"));
		EndIf;
	Else
		tcCommonFunctionOnClientServer.TextMessage(Nstr("en='Check-in period is not specified!';ru='Не выбран заезд!';de='Keine Anreise ist gewählt!'"));
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillDateSwitch()
	Items.DateSwitch.ChoiceList.Clear();	
	vCurDate = CurrentSessionDate();
	Items.DateSwitch.ChoiceList.Add(0,NStr("en = 'Today'; ru = 'Сегодня'; de = 'Heute'"));
	x = 1;
	vCurDate = BegOfMonth(vCurDate);
	While x <= 12 Do
		Items.DateSwitch.ChoiceList.Add(Month(vCurDate), String(Format(vCurDate, NStr("en = 'L=en; DF=MMMM'; ru = 'L=ru; DF=MMMM'; de = 'L=de; DF=MMMM'"))));
		x =  x + 1;
		vCurDate = BegOfMonth(AddMonth(vCurDate,1));
	EndDo;
EndProcedure // FillDateSwitch

// -----------------------------------------------------------------------------
&AtServer
Function CheckAllotmentPeriod(pMessage)
	vOK = True;
	pMessage = "";
	// Try to find intersecting periods 
	vPeriods = RoomQuota.GetObject().pmGetIntersectingCheckInPeriods(PeriodFrom, GetTime(PeriodTo), SelHotel);
	If vPeriods.Count() = 0 Then
		vOK = False;
		pMessage = NStr("en='There is no such check-in period found for the allotment to move rooms from!';ru='Указанный период не совпадает ни с одним заездом выбранной квоты!';de='Der genannte Zeitraum stimmt mit keiner Anreise des ausgewählten Kontingents überein!'");
	Else
		vPeriodFromOK = False;
		vPeriodToOK = False;
		For Each vPeriodsRow In vPeriods Do
			If vPeriodsRow.CheckInDate = cm0SecondShift(GetTime(PeriodFrom)) Then
				vPeriodFromOK = True;
			EndIf;
			If vPeriodsRow.CheckOutDate = cm0SecondShift(GetTime(PeriodTo)) Then
				vPeriodToOK = True;
			EndIf;
		EndDo;
		If Not vPeriodFromOK Or Not vPeriodToOK Then
			vOK = False;
			pMessage = NStr("en='There is no such check-in period found for the allotment to move rooms from!';ru='Указанный период не совпадает ни с одним заездом выбранной квоты!';de='Der genannte Zeitraum stimmt mit keiner Anreise des ausgewählten Kontingents überein!'");
		EndIf;
	EndIf;
	Return vOK;
EndFunction // CheckAllotmentPeriod

// -----------------------------------------------------------------------------
Procedure FillDocumentNumberOfRoomsAndBeds(pDocObj)
	If InRooms Then
		pDocObj.NumberOfRooms = NumberOfRooms;
		pDocObj.NumberOfBeds = pDocObj.NumberOfRooms * pDocObj.NumberOfBedsPerRoom;
	Else
		If pDocObj.NumberOfBedsPerRoom = 0 Then
			Raise NStr("en='Number of beds per room is zero!'; ru='У типа номера не указано кол-во основных мест!'; de='Bei Zimmertyp nicht angegeben ist Zahl der wichtigsten Betten!'");
		EndIf;
		If Int(NumberOfRooms / pDocObj.NumberOfBedsPerRoom) <> (NumberOfRooms / pDocObj.NumberOfBedsPerRoom) Then
			Raise NStr("en='Number of beds specified should be recalculated to the int number of rooms!'; ru='Кол-во мест должно соответствовать целому числу номеров!'; de='Anzahl von Betten müssen eine Reihe von Zimmer entsprechen!'");
		EndIf;
		pDocObj.NumberOfRooms = Int(NumberOfRooms / pDocObj.NumberOfBedsPerRoom);
		pDocObj.NumberOfBeds = NumberOfRooms;
	EndIf;
EndProcedure // FillDocumentNumberOfRoomsAndBeds

// -----------------------------------------------------------------------------
&AtServer
Procedure MakePeriodSplittableAtServer()
	// Check attributes
	If Not ValueIsFilled(RoomQuota) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Allotment is not set!'; de = 'Keine Quote ist gewählt!'; ru = 'Не выбрана квота!'"));
		Return;
	EndIf;
	// Check permissions
	If RoomQuota.AllotmentBusinessType = Enums.AllotmentBusinessTypes.BusinessBlock And Not cmCheckUserPermissions("HavePermissionToManageBusinessBlocks") Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to manage business blocks!';ru='Нет прав на управление бизнес-блоками!';de='Sie haben keine Rechte, Geschäftsblocken zu verwalten!'"));
		Return;
	ElsIf RoomQuota.AllotmentBusinessType <> Enums.AllotmentBusinessTypes.BusinessBlock And Not cmCheckUserPermissions("HavePermissionToManageAllotments") Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to manage allotments!';ru='Нет прав на управление квотами!';de='Sie haben keine Rechte, Kontingente zu verwalten!'"));
		Return;
	EndIf;
	// Try to find check-in period selected
	If ValueIsFilled(PeriodFrom) And ValueIsFilled(PeriodTo) Then
		If PeriodFrom < PeriodTo Then
			vMgrObj = InformationRegisters.RoomQuotaCheckInPeriods.CreateRecordManager();
			vMgrObj.Hotel = SelHotel;
			vMgrObj.RoomQuota = RoomQuota;
			vMgrObj.CheckInDate = GetTime(PeriodFrom);
			vMgrObj.Duration = Duration;
			vMgrObj.CheckOutDate = GetTime(PeriodTo);
			vMgrObj.Read();
			If Not vMgrObj.Selected() Then
				tcCommonFunctionOnClientServer.TextMessage(Nstr("en='Check-in period specified is not found!';ru='Заезд с указанными параметрами не найден!';de='Anreise mit angegebenen Parametern wurde nicht gefunden!'"));
			Else
				BeginTransaction(DataLockControlMode.Managed);
				Try
					vMgrObj.Delete();
					// Create 1 day check-in periods
					vMgrSet = InformationRegisters.RoomQuotaCheckInPeriods.CreateRecordSet();
					vCurDate = PeriodFrom;
					While BegOfDay(vCurDate) < BegOfDay(PeriodTo) Do
						vMgrRec = vMgrSet.Add();
						vMgrRec.Hotel = SelHotel;
						vMgrRec.RoomQuota = RoomQuota;
						vMgrRec.CheckInDate = GetTime(vCurDate);
						vMgrRec.Duration = 1;
						vMgrRec.CheckOutDate = GetTime(BegOfDay(vCurDate) + 24 * 3600 + (PeriodTo - BegOfDay(PeriodTo)));
						vMgrRec.IsManual = True;
						// Go to next date
						vCurDate = vCurDate + 24 * 3600;
					EndDo;
					vMgrSet.Write(False);
					CommitTransaction();
				Except                 
					RollbackTransaction();
					vErrorDescription = ErrorDescription();

					tcCommonFunctionOnClientServer.TextMessage(vErrorDescription);
				EndTry;
				// Generate report
				GenerateReport();
			EndIf;
		Else
			tcCommonFunctionOnClientServer.TextMessage(Nstr("en='Check-in date is later then check-out date!';ru='Дата выезда раньше даты заезда!';de='Das Abreisedatum liegt vor dem Anreisedatum!'"));
		EndIf;
	Else
		tcCommonFunctionOnClientServer.TextMessage(Nstr("en='Check-in period is not specified!';ru='Не выбран заезд!';de='Keine Anreise ist gewählt!'"));
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure WriteOffRoomQuotaAnswer(pResult, pParameters) Export 
	If pResult = DialogReturnCode.Yes Then
		WriteOffRoomQuotaAtServer();
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure WriteOffRoomQuotaAtServer()
	// Check attributes
	If Not ValueIsFilled(RoomQuota) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Allotment is not set!'; de = 'Keine Quote ist gewählt!'; ru = 'Не выбрана квота!'"));
		Return;
	EndIf;
	// Check permissions
	If RoomQuota.AllotmentBusinessType = Enums.AllotmentBusinessTypes.BusinessBlock And Not cmCheckUserPermissions("HavePermissionToManageBusinessBlocks") Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to manage business blocks!';ru='Нет прав на управление бизнес-блоками!';de='Sie haben keine Rechte, Geschäftsblocken zu verwalten!'"));
		Return;
	ElsIf RoomQuota.AllotmentBusinessType <> Enums.AllotmentBusinessTypes.BusinessBlock And Not cmCheckUserPermissions("HavePermissionToManageAllotments") Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'You do not have rights to manage allotments!'; de = 'Sie haben keine Rechte, Allotmenten zu verwalten!'; ru = 'Нет прав на управление квотами!'"));
		Return;
	EndIf;
	// Initialization
	vWereChanges = False;
	// Try to define allotment period
	vQry = New Query();
	If SelMode = 2 Then
		vQry.Text = 
		"SELECT
		|	AllotmentForecast.RoomType AS RoomType,
		|	MIN(AllotmentForecast.Period) AS PeriodFrom,
		|	MAX(AllotmentForecast.Period) AS PeriodTo
		|FROM
		|	AccumulationRegister.ExpectedGuestGroups AS AllotmentForecast
		|WHERE
		|	AllotmentForecast.RoomQuota = &qRoomQuota
		|
		|GROUP BY
		|	AllotmentForecast.RoomType
		|
		|ORDER BY
		|	AllotmentForecast.RoomType.SortCode";
	Else
		vQry.Text = 
		"SELECT
		|	RoomQuotaSales.RoomType AS RoomType,
		|	MIN(RoomQuotaSales.Period) AS PeriodFrom,
		|	MAX(RoomQuotaSales.Period) AS PeriodTo
		|FROM
		|	AccumulationRegister.RoomQuotaSales AS RoomQuotaSales
		|WHERE
		|	RoomQuotaSales.RoomQuota = &qRoomQuota
		|	AND (RoomQuotaSales.IsRoomQuota
		|			OR RoomQuotaSales.IsReservation
		|			OR RoomQuotaSales.IsAccommodation)
		|
		|GROUP BY
		|	RoomQuotaSales.RoomType
		|
		|ORDER BY
		|	RoomQuotaSales.RoomType.SortCode";
	EndIf;
	vQry.SetParameter("qRoomQuota", RoomQuota);
	vRoomTypes = vQry.Execute().Unload();
	// Do action
	If vRoomTypes.Count() > 0 Then
		For Each vRoomTypesRow In vRoomTypes Do
			If ValueIsFilled(vRoomTypesRow.PeriodFrom) And ValueIsFilled(vRoomTypesRow.PeriodTo) Then
				vRoomTypeWereChanges = ChangeAllotment(vRoomTypesRow.PeriodFrom - 24*3600, vRoomTypesRow.PeriodTo + 24*3600, vRoomTypesRow.RoomType, True);
				If vRoomTypeWereChanges Then
					vWereChanges = True;
				EndIf;
			EndIf;
		EndDo;
		// Refresh report
		If vWereChanges Then
			// Refresh form
			GenerateReport();
		EndIf;
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'No rooms were added to the allotment choosen!'; de = 'In die gewählte Quote wurde kein Zimmer übertragen!'; ru = 'В выбранную квоту не выводились номера!'"));
	EndIf;
EndProcedure // WriteOffRoomQuotaAtServer

// -----------------------------------------------------------------------------
&AtServer
Function ChangeAllotment(pPeriodFrom, pPeriodTo, pRoomType, pDoWriteOff)
	// Build list of days in the period choosen
	vDays = New ValueTable();
	vDays.Columns.Add("PeriodFrom", cmGetDateTimeTypeDescription());
	vDays.Columns.Add("PeriodTo", cmGetDateTimeTypeDescription());
	vCurDay = pPeriodFrom;
	While vCurDay < pPeriodTo Do
		vDay = vDays.Add();
		vDay.PeriodFrom = cm0SecondShift(vCurDay);
		vDay.PeriodTo = cm0SecondShift(vCurDay + 24 * 3600);
		vCurDay = vCurDay + 24 * 3600;
	EndDo;
	If pDoWriteOff Then
		NumberOfRooms = 0;
	EndIf;
	
	// Update allotment if manual price is specified
	If Not pDoWriteOff Then
		If EditPrice Then
			vAllotmentObj = RoomQuota.GetObject();
			If SelPrice >= 0 And ValueIsFilled(SelCurrency) And (SelNumberOfAdults <> 0 Or SelNumberOfTeenagers <> 0 Or SelNumberOfChildren <> 0 Or SelNumberOfInfants <> 0) Then
				vRQRTRows = vAllotmentObj.RoomTypes.FindRows(New Structure("RoomType, PeriodFrom, PeriodTo, IsPriceSetting, NumberOfAdults, NumberOfTeenagers, NumberOfChildren, NumberOfInfants", 
				                                                            pRoomType, BegOfDay(pPeriodFrom), BegOfDay(pPeriodTo), 
				                                                            True, SelNumberOfAdults, SelNumberOfTeenagers, SelNumberOfChildren, SelNumberOfInfants));
				If vRQRTRows.Count() > 0 Then
					vRQRTRow = vRQRTRows.Get(vRQRTRows.Count() - 1);
				Else
					vRQRTRow = vAllotmentObj.RoomTypes.Add();
					vRQRTRow.Hotel = pRoomType.Owner;
					vRQRTRow.RoomType = pRoomType;
					vRQRTRow.PeriodFrom = BegOfDay(pPeriodFrom);
					vRQRTRow.PeriodTo = BegOfDay(pPeriodTo);
				EndIf;
				vRQRTRow.NumberOfAdults = SelNumberOfAdults;
				vRQRTRow.NumberOfTeenagers = SelNumberOfTeenagers;
				vRQRTRow.NumberOfChildren = SelNumberOfChildren;
				vRQRTRow.NumberOfInfants = SelNumberOfInfants;
				vRQRTRow.NumberOfPersons = SelNumberOfAdults + SelNumberOfTeenagers + SelNumberOfChildren + SelNumberOfInfants;
				vRQRTRow.Price = SelPrice;
				vRQRTRow.Currency = SelCurrency;
				vRQRTRow.IsPriceSetting = True;
			EndIf;
			If vAllotmentObj.Modified() Then
				vAllotmentObj.Write();
				// Repost set room quota documents intersecting with prices changed
				vRecalculateBusinessBlockBudget = False;
				vSetRoomQuotas = GetIntersectingSetRoomQuotas(RoomQuota, pRoomType, pPeriodFrom, pPeriodTo);
				If vSetRoomQuotas.Count() > 0 Then
					vRecalculateBusinessBlockBudget = True;
					For Each vSetRoomQuotasRow In vSetRoomQuotas Do
						vDocObj = vSetRoomQuotasRow.Ref.GetObject();
						vDocObj.Write(DocumentWriteMode.Posting);
					EndDo;
				EndIf;
				If vRecalculateBusinessBlockBudget Then
					Catalogs.RoomQuotas.CalculateBusinessBlockBudget(vAllotmentObj.Ref, False);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	// Build chain of periods with the same number of rooms to write off
	vCurNumberOfRooms = ?(pDoWriteOff, 0, NumberOfRooms);
	vPeriod = Undefined;
	vPeriodsChain = New ValueTable();
	vPeriodsChain.Columns.Add("PeriodFrom", cmGetDateTimeTypeDescription());
	vPeriodsChain.Columns.Add("PeriodTo", cmGetDateTimeTypeDescription());
	vPeriodsChain.Columns.Add("NumberOfRooms", cmGetNumberTypeDescription(6, 0));
	For Each vDay In vDays Do
		If SelMode = 2 Then
			vRemains = cmCalculateRoomQuotaForecastResources(RoomQuota, pRoomType.Owner, pRoomType, vDay.PeriodFrom, vDay.PeriodTo);
		Else
			vRemains = cmCalculateRoomQuotaResources(RoomQuota, pRoomType.Owner, pRoomType, Undefined, vDay.PeriodFrom, vDay.PeriodTo);
		EndIf;
		vNumberOfRooms = 0;
		If vRemains.Count() > 0 Then
			If SelMode = 0 Or pDoWriteOff Then
				vNumberOfRooms = vRemains.Get(0).RoomsRemains;
			ElsIf SelMode = 1 Then
				vNumberOfRooms = vRemains.Get(0).RoomsInQuota;
			ElsIf SelMode = 2 Then
				vNumberOfRooms = vRemains.Get(0).RoomsRemains;
			EndIf;
		EndIf;
		If vCurNumberOfRooms <> vNumberOfRooms Then
			If vPeriod <> Undefined Then
				vPeriod.PeriodTo = cm0SecondShift(vDay.PeriodFrom);
			EndIf;
			vPeriod = vPeriodsChain.Add();
			vPeriod.PeriodFrom = vDay.PeriodFrom;
			vPeriod.NumberOfRooms = vNumberOfRooms;
			vCurNumberOfRooms = vNumberOfRooms;
		EndIf;
	EndDo;
	If vPeriod <> Undefined Then
		vPeriod.PeriodTo = cm0SecondShift(vDay.PeriodTo);
	EndIf;
	
	// Create new "Set room quota" document and fill it's parameters for each period in chain
	vWereChanges = False;
	If EditInventory Or pDoWriteOff Then
		For Each vPeriod In vPeriodsChain Do
			If vPeriod.NumberOfRooms = ?(pDoWriteOff, 0, NumberOfRooms) Then
				Continue;
			EndIf;
			vDocObj = Documents.SetRoomQuota.CreateDocument();
			vDocObj.RoomQuota = RoomQuota;
			vDocObj.BaseRoomQuota = RoomQuota.BaseRoomQuota;
			If ValueIsFilled(vDocObj.RoomQuota.Hotel) Then
				vDocObj.Hotel = vDocObj.RoomQuota.Hotel;
			EndIf;
			vDocObj.RoomType = pRoomType;
			If Not ValueIsFilled(vDocObj.Hotel) Then
				vDocObj.Hotel = vDocObj.RoomType.Owner;
			EndIf;
			vDocObj.SetRoomQuotaType = ?(vPeriod.NumberOfRooms > NumberOfRooms, Enums.SetRoomQuotaTypes.Remove, Enums.SetRoomQuotaTypes.Add);
			vDocObj.DateFrom = cm0SecondShift(vPeriod.PeriodFrom);
			vDocObj.pmFillAttributesWithDefaultValues();
			vDocObj.NumberOfBedsPerRoom = vDocObj.RoomType.NumberOfBedsPerRoom;
			vDocObj.NumberOfPersonsPerRoom = vDocObj.RoomType.NumberOfPersonsPerRoom;
			vDocObj.DateTo = cm0SecondShift(vPeriod.PeriodTo);
			vDocObj.Duration = vDocObj.pmCalculateDuration();
			vDocObj.NumberOfRooms = ?(vPeriod.NumberOfRooms > NumberOfRooms, vPeriod.NumberOfRooms - NumberOfRooms, NumberOfRooms - vPeriod.NumberOfRooms);
			vDocObj.NumberOfBeds = vDocObj.NumberOfRooms * vDocObj.NumberOfBedsPerRoom;
			vDocObj.IsForecast = ?(SelMode = 2, True, False);
			vDocObj.IsInitial = ?(SelMode = 1 And SelShowSelector = 1, True, False);
			
			If pDoWriteOff Then
				vDocObj.AdditionalProperties.Insert("DoNotCheckBalances", True);
			EndIf;
			
			// Show document form or post it
			vDocObj.Write(DocumentWriteMode.Posting);
			vWereChanges = True;
		EndDo;
	EndIf;

	Return vWereChanges;
EndFunction // ChangeAllotment

// -----------------------------------------------------------------------------
&AtServer
Procedure ChangeRoomQuotaByPeriodAtServer(pDoWriteOff)
	// Check attributes
	If Not ValueIsFilled(PeriodFrom) Or Not ValueIsFilled(PeriodTo) Or PeriodTo <= PeriodFrom Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Period is wrong!';ru='Период указан не верно!';de='Der Zeitraum ist falsch angegeben!'"));
		Return;
	EndIf;
	If Not ValueIsFilled(RoomQuota) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Allotment is not set!';ru='Не выбрана квота!';de='Keine Quote ist gewählt!'"));
		Return;
	EndIf;
	If Not ValueIsFilled(RoomType) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Room type is not set!';ru='Не выбран тип номера!';de='Kein Zimmertyp ist gewählt!'"));
		Return;
	EndIf;
	// Check permissions
	If RoomQuota.AllotmentBusinessType = Enums.AllotmentBusinessTypes.BusinessBlock And Not cmCheckUserPermissions("HavePermissionToManageBusinessBlocks") Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to manage business blocks!';ru='Нет прав на управление бизнес-блоками!';de='Sie haben keine Rechte, Geschäftsblocken zu verwalten!'"));
		Return;
	ElsIf RoomQuota.AllotmentBusinessType <> Enums.AllotmentBusinessTypes.BusinessBlock And Not cmCheckUserPermissions("HavePermissionToManageAllotments") Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to manage allotments!';ru='Нет прав на управление квотами!';de='Sie haben keine Rechte, Allotmenten zu verwalten!'"));
		Return;
	EndIf;
	// Try to check that period is equal to the check-in period of allotment to write off rooms from
	If RoomQuota.IsForCheckInPeriods Then
		If Not AllDays Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='All weekdays should be marked!'; ru='Все дни недели должны быть отмечены!'; de='Alle Wochentage müssen markiert sein!'"), MessageStatus.Important);
			Return;
		EndIf;
		rMessage = "";
		If Not CheckAllotmentPeriod(rMessage) Then
			tcCommonFunctionOnClientServer.TextMessage(rMessage);
			Return;
		EndIf;
	EndIf;
	// Do action on period selected
	vWereChanges = False;
	vPeriods = FillPeriodsToProcess();
	If vPeriods.Count() > 0 Then
		For Each vPeriodsRow In vPeriods Do
			wWereChanges = ChangeAllotment(GetTime(vPeriodsRow.PeriodFrom), GetTime(vPeriodsRow.PeriodTo), RoomType, pDoWriteOff);
			If wWereChanges Then
				vWereChanges = True;
			EndIf;
		EndDo;
		
		// Refresh report
		If vWereChanges Then
			// Build structure with parameters to open report hierarchy
			vStr = New Structure("Hotel, RoomType, RoomQuota", SelHotel, RoomType, RoomQuota);
			GenerateReport(vStr);
		EndIf;
	ElsIf Not AllDays Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Mark at least one day of the week!'; ru='Отметьте хотя бы один день недели!'; de='Markieren Sie mindestens einen Wochentag!'"), MessageStatus.Important);
	EndIf;
EndProcedure // ChangeRoomQuotaByPeriodAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure AddCommonAllotments(pAllotmentsList, pCheckInDate, pCheckOutDate)
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomQuotas.Ref AS Ref
	|FROM
	|	Catalog.RoomQuotas AS RoomQuotas
	|WHERE
	|	NOT RoomQuotas.DeletionMark
	|	AND NOT RoomQuotas.IsFolder
	|	AND NOT RoomQuotas.IsForCheckInPeriods
	|	AND RoomQuotas.PeriodFrom < &qPeriodTo
	|	AND (RoomQuotas.PeriodTo > &qPeriodFrom
	|			OR RoomQuotas.PeriodTo = &qEmptyPeriod)
	|
	|ORDER BY
	|	RoomQuotas.SortCode,
	|	RoomQuotas.Description";
	vQry.SetParameter("qPeriodFrom", cm0SecondShift(pCheckInDate));
	vQry.SetParameter("qPeriodTo", cm0SecondShift(pCheckOutDate));
	vQry.SetParameter("qEmptyPeriod", '00010101');
	vAllotments = vQry.Execute().Unload();
	For Each vAllotmentsRow In vAllotments Do
		If pAllotmentsList.FindByValue(vAllotmentsRow.Ref) = Undefined Then
			pAllotmentsList.Add(vAllotmentsRow.Ref);
		EndIf;
	EndDo;
EndProcedure // AddCommonAllotments

// -----------------------------------------------------------------------------
&AtServer
Function GetSuitableAllotments(pCheckInPeriods, pCheckInDate, pCheckOutDate)
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Allotments.Hotel AS Hotel,
	|	Allotments.RoomQuota AS RoomQuota,
	|	Allotments.CheckInDate AS CheckInDate,
	|	Allotments.CheckOutDate AS CheckOutDate
	|INTO SuitableAllotments
	|FROM
	|	&qSuitableAllotments AS Allotments
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SuitableAllotments.Hotel AS Hotel,
	|	SuitableAllotments.RoomQuota AS RoomQuota,
	|	MIN(SuitableAllotments.CheckInDate) AS CheckInDate,
	|	MAX(SuitableAllotments.CheckOutDate) AS CheckOutDate
	|FROM
	|	SuitableAllotments AS SuitableAllotments
	|
	|GROUP BY
	|	SuitableAllotments.Hotel,
	|	SuitableAllotments.RoomQuota
	|
	|HAVING
	|	BEGINOFPERIOD(MIN(SuitableAllotments.CheckInDate), DAY) = BEGINOFPERIOD(&qPeriodFrom, DAY) AND
	|	BEGINOFPERIOD(MAX(SuitableAllotments.CheckOutDate), DAY) = BEGINOFPERIOD(&qPeriodTo, DAY)";
	vQry.SetParameter("qSuitableAllotments", pCheckInPeriods);
	vQry.SetParameter("qPeriodFrom", pCheckInDate);
	vQry.SetParameter("qPeriodTo", pCheckOutDate);
	Return vQry.Execute().Unload();
EndFunction // GetSuitableAllotments

// -----------------------------------------------------------------------------
&AtServer
Function GetCheckInPeriods(pHotel, pPeriodFrom, pPeriodTo)
	// Try to find intersecting periods 
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	AllotmentCheckInPeriods.Hotel AS Hotel,
	|	AllotmentCheckInPeriods.RoomQuota AS RoomQuota,
	|	AllotmentCheckInPeriods.CheckInDate AS CheckInDate,
	|	AllotmentCheckInPeriods.Duration AS Duration,
	|	AllotmentCheckInPeriods.CheckOutDate AS CheckOutDate
	|FROM
	|	InformationRegister.RoomQuotaCheckInPeriods AS AllotmentCheckInPeriods
	|WHERE
	|	AllotmentCheckInPeriods.Hotel = &qHotel
	|	AND AllotmentCheckInPeriods.CheckInDate < &qCheckOutDate
	|	AND AllotmentCheckInPeriods.CheckOutDate > &qCheckInDate
	|	AND NOT AllotmentCheckInPeriods.IsNotActive
	|
	|ORDER BY
	|	AllotmentCheckInPeriods.CheckInDate,
	|	AllotmentCheckInPeriods.Duration";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qCheckInDate", cm0SecondShift(pPeriodFrom));
	vQry.SetParameter("qCheckOutDate", cm0SecondShift(pPeriodTo));
	vPeriods = vQry.Execute().Unload();
	Return vPeriods;
EndFunction // GetCheckInPeriods

// -----------------------------------------------------------------------------
&AtServer
Procedure MoveRoomQuotaRoomsAtServer(pTargetRoomQuota)
	If pTargetRoomQuota = Undefined Then
		Return;
	EndIf;
	If pTargetRoomQuota = RoomQuota Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You have choosen the same allotment!';ru='Указали одну и ту же квоту в качестве источника и получателя!';de='Sie haben ein und dieselbe Quote als Quelle und Empfänger angegeben!'"));
		Return;
	EndIf;
	
	// Check target room quota check-in periods
	If pTargetRoomQuota.IsForCheckInPeriods Then
		If AllDays Then
			vTargetCheckInPeriods = pTargetRoomQuota.GetObject().pmGetIntersectingCheckInPeriods(GetTime(PeriodFrom), GetTime(PeriodTo), SelHotel);
			If vTargetCheckInPeriods.Count() > 0 Then
				// Check that exisiting periods are starting and ending at right dates
				vPeriodFromOK = False;
				vPeriodToOK = False;
				For Each vPeriodsRow In vTargetCheckInPeriods Do
					If vPeriodsRow.CheckInDate = cm0SecondShift(GetTime(PeriodFrom)) Then
						vPeriodFromOK = True;
					EndIf;
					If vPeriodsRow.CheckOutDate = cm0SecondShift(GetTime(PeriodTo)) Then
						vPeriodToOK = True;
					EndIf;
				EndDo;
				If Not vPeriodFromOK Or Not vPeriodToOK Then
					tcCommonFunctionOnClientServer.TextMessage(NStr("en='There are check-in periods intersecting with period specified!';ru='Указанный период пересекается с уже существующими заездами выбранной квоты!';de='Der genannte Zeitraum überschneidet sich mit schon existierenden Anreisen des gewählten Kontingents!'"));
					Return;
				EndIf;
			EndIf;
		Else
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='All weekdays should be marked!'; ru='Все дни недели должны быть отмечены!'; de='Alle Wochentage müssen markiert sein!'"), MessageStatus.Important);
			Return;
		EndIf;
	EndIf;
	
	// Begin transaction
	vPeriods = FillPeriodsToProcess();
	If vPeriods.Count() > 0 Then
		Try
			BeginTransaction(DataLockControlMode.Managed);
			For Each vPeriodsRow In vPeriods Do
				// Try to create check in period if target room quota is for check-in periods
				If pTargetRoomQuota.IsForCheckInPeriods Then
					If vTargetCheckInPeriods.Count() = 0 Then
						vMgrSet = InformationRegisters.RoomQuotaCheckInPeriods.CreateRecordSet();
						vMgrRec = vMgrSet.Add();
						vMgrRec.Hotel = SelHotel;
						vMgrRec.RoomQuota = pTargetRoomQuota;
						vMgrRec.CheckInDate = cm0SecondShift(GetTime(vPeriodsRow.PeriodFrom));
						vMgrRec.Duration = Duration;
						vMgrRec.CheckOutDate = cm0SecondShift(GetTime(vPeriodsRow.PeriodTo));
						vMgrRec.IsManual = True;
						vMgrSet.Write(False);
					EndIf;
				EndIf;
				// Create new "Set room quota" document and fill it's parameters from the filter page
				If RoomQuota <> pTargetRoomQuota.BaseRoomQuota Then
					vMinusDocObj = Documents.SetRoomQuota.CreateDocument();
					vMinusDocObj.RoomQuota = RoomQuota;
					vMinusDocObj.BaseRoomQuota = pTargetRoomQuota.BaseRoomQuota;
					If ValueIsFilled(vMinusDocObj.RoomQuota.Hotel) Then
						vMinusDocObj.Hotel = vMinusDocObj.RoomQuota.Hotel;
					EndIf;
					vMinusDocObj.RoomType = RoomType;
					If Not ValueIsFilled(vMinusDocObj.Hotel) Then
						vMinusDocObj.Hotel = vMinusDocObj.RoomType.Owner;
					EndIf;
					vMinusDocObj.SetRoomQuotaType = Enums.SetRoomQuotaTypes.Remove;
					vMinusDocObj.DateFrom = cm0SecondShift(GetTime(vPeriodsRow.PeriodFrom));
					vMinusDocObj.pmFillAttributesWithDefaultValues();
					vMinusDocObj.NumberOfBedsPerRoom = vMinusDocObj.RoomType.NumberOfBedsPerRoom;
					vMinusDocObj.NumberOfPersonsPerRoom = vMinusDocObj.RoomType.NumberOfPersonsPerRoom;
					vMinusDocObj.DateTo = cm0SecondShift(GetTime(vPeriodsRow.PeriodTo));
					vMinusDocObj.Duration = vMinusDocObj.pmCalculateDuration();
					FillDocumentNumberOfRoomsAndBeds(vMinusDocObj);
					vMinusDocObj.IsForecast = ?(SelMode = 2, True, False);
					vMinusDocObj.IsInitial = ?(SelMode = 1 And SelShowSelector = 1, True, False);
					// Post document
					vMinusDocObj.Write(DocumentWriteMode.Posting);
				EndIf;
				// Create new "Set room quota" document and fill it's parameters from the filter page
				If pTargetRoomQuota.BaseRoomQuota <> pTargetRoomQuota Then
					vPlusDocObj = Documents.SetRoomQuota.CreateDocument();
					vPlusDocObj.RoomQuota = pTargetRoomQuota;
					vPlusDocObj.BaseRoomQuota = pTargetRoomQuota.BaseRoomQuota;
					If ValueIsFilled(vPlusDocObj.RoomQuota.Hotel) Then
						vPlusDocObj.Hotel = vPlusDocObj.RoomQuota.Hotel;
					EndIf;
					vPlusDocObj.RoomType = RoomType;
					If Not ValueIsFilled(vPlusDocObj.Hotel) Then
						vPlusDocObj.Hotel = vPlusDocObj.RoomType.Owner;
					EndIf;
					vPlusDocObj.SetRoomQuotaType = Enums.SetRoomQuotaTypes.Add;
					vPlusDocObj.DateFrom = cm0SecondShift(GetTime(vPeriodsRow.PeriodFrom));
					vPlusDocObj.pmFillAttributesWithDefaultValues();
					vPlusDocObj.NumberOfBedsPerRoom = vPlusDocObj.RoomType.NumberOfBedsPerRoom;
					vPlusDocObj.NumberOfPersonsPerRoom = vPlusDocObj.RoomType.NumberOfPersonsPerRoom;
					vPlusDocObj.DateTo = cm0SecondShift(GetTime(vPeriodsRow.PeriodTo));
					vPlusDocObj.Duration = vPlusDocObj.pmCalculateDuration();
					FillDocumentNumberOfRoomsAndBeds(vPlusDocObj);
					vPlusDocObj.IsForecast = ?(SelMode = 2, True, False);
					vPlusDocObj.IsInitial = ?(SelMode = 1 And SelShowSelector = 1, True, False);
					// Post it
					vPlusDocObj.Write(DocumentWriteMode.Posting);
				EndIf;
			EndDo;
			
			// Commit transaction
			CommitTransaction();
		Except         
			vErrorDescription = cmGetRootErrorDescription(ErrorInfo());

			// Rollback transaction
			If TransactionActive() Then
				RollbackTransaction();
			EndIf;
			
			tcCommonFunctionOnClientServer.TextMessage(vErrorDescription, MessageStatus.Attention);
		EndTry;
		
		// Build structure with parameters to open report hierarchy
		vParam = New Structure("Hotel, RoomType, RoomQuota", SelHotel, RoomType, RoomQuota);
		// Refresh report
		GenerateReport(vParam);
	ElsIf Not AllDays Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Mark at least one day of the week!'; ru='Отметьте хотя бы один день недели!'; de='Markieren Sie mindestens einen Wochentag!'"), MessageStatus.Important);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function CheckMoveRoomQuota()
	vValueList = New ValueList;

	// Check attributes
	If Not ValueIsFilled(PeriodFrom) Or Not ValueIsFilled(PeriodTo) Or PeriodTo <= PeriodFrom Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Period is wrong!';ru='Период указан не верно!';de='Der Zeitraum ist falsch angegeben!'"));
		Return vValueList;
	EndIf;
	If Not ValueIsFilled(RoomQuota) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Allotment is not set!';ru='Не выбрана квота!';de='Keine Quote ist gewählt!'"));
		Return vValueList;
	EndIf;
	If Not ValueIsFilled(RoomType) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Room type is not set!';ru='Не выбран тип номера!';de='Kein Zimmertyp ist gewählt!'"));
		Return vValueList;
	EndIf;
	If NumberOfRooms = 0 Then
		If InRooms Then
			If NumberOfRooms = 0 Then
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='Number of rooms is not set!';ru='Не указано количество номеров!';de='Die Zimmeranzahl ist nicht angegeben!'"));
				Return vValueList;
			EndIf;
		Else
			If NumberOfRooms = 0 Then
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='Number of beds is not set!';ru='Не указано количество мест!';de='Die Bettenanzahl ist nicht angegeben!'"));
				Return vValueList;
			EndIf;
		EndIf;
	EndIf;
	// Check permissions
	If RoomQuota.AllotmentBusinessType = Enums.AllotmentBusinessTypes.BusinessBlock And Not cmCheckUserPermissions("HavePermissionToManageBusinessBlocks") Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to manage business blocks!';ru='Нет прав на управление бизнес-блоками!';de='Sie haben keine Rechte, Geschäftsblocken zu verwalten!'"));
		Return vValueList;
	ElsIf RoomQuota.AllotmentBusinessType <> Enums.AllotmentBusinessTypes.BusinessBlock And Not cmCheckUserPermissions("HavePermissionToManageAllotments") Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to manage allotments!';ru='Нет прав на управление квотами!';de='Sie haben keine Rechte, Kontingente zu verwalten!'"));
		Return vValueList;
	EndIf;
	// Try to check that period is equal to the check-in period of allotment to move rooms from
	If RoomQuota.IsForCheckInPeriods Then
		If Not AllDays Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='All weekdays should be marked!'; ru='Все дни недели должны быть отмечены!'; de='Alle Wochentage müssen markiert sein!'"), MessageStatus.Important);
			Return vValueList;
		EndIf;
		rMessage = "";
		If Not CheckAllotmentPeriod(rMessage) Then
			tcCommonFunctionOnClientServer.TextMessage(rMessage);
			Return vValueList;
		EndIf;
	EndIf;
	// Build list of allotment to move to
	vCheckInPeriods = GetCheckInPeriods(SelHotel, GetTime(PeriodFrom), GetTime(PeriodTo));
	If vCheckInPeriods.Count() > 0 Then
		vAllotments = GetSuitableAllotments(vCheckInPeriods, GetTime(PeriodFrom), GetTime(PeriodTo));
		vValueList.LoadValues(vAllotments.UnloadColumn("RoomQuota"));
	EndIf;
	AddCommonAllotments(vValueList, GetTime(PeriodFrom), GetTime(PeriodTo));
	Return vValueList;
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Procedure RemoveRoomsAtServer()  
	vCancel = False;
	// Check attributes
	If Not ValueIsFilled(PeriodFrom) Or Not ValueIsFilled(PeriodTo) Or PeriodTo <= PeriodFrom Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Period is wrong!';ru='Период указан не верно!';de='Der Zeitraum ist falsch angegeben!'"));
		vCancel = True;
	EndIf;
	If Not ValueIsFilled(RoomQuota) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Allotment is not set!';ru='Не выбрана квота!';de='Keine Quote ist gewählt!'"));
		vCancel = True;
	EndIf;
	If Not ValueIsFilled(RoomType) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Room type is not set!';ru='Не выбран тип номера!';de='Kein Zimmertyp ist gewählt!'"));
		vCancel = True;
	EndIf;  
	// Check permissions
	If vCancel = False Then
		If RoomQuota.AllotmentBusinessType = Enums.AllotmentBusinessTypes.BusinessBlock And Not cmCheckUserPermissions("HavePermissionToManageBusinessBlocks") Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to manage business blocks!';ru='Нет прав на управление бизнес-блоками!';de='Sie haben keine Rechte, Geschäftsblocken zu verwalten!'"));
			vCancel = True;
		ElsIf RoomQuota.AllotmentBusinessType <> Enums.AllotmentBusinessTypes.BusinessBlock And Not cmCheckUserPermissions("HavePermissionToManageAllotments") Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to manage allotments!';ru='Нет прав на управление квотами!';de='Sie haben keine Rechte, Allotmenten zu verwalten!'"));
			vCancel = True;
		EndIf;
	EndIf;
	If vCancel = True Then
		Return;
	EndIf;	
	If NumberOfRooms = 0 Then
		If InRooms Then
			If NumberOfRooms = 0 Then
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='Number of rooms is not set!';ru='Не указано количество номеров!';de='Die Zimmeranzahl ist nicht angegeben!'"));
				Return;
			EndIf;
		Else
			If NumberOfRooms = 0 Then
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='Number of beds is not set!';ru='Не указано количество мест!';de='Die Bettenanzahl ist nicht angegeben!'"));
				Return;
			EndIf;
		EndIf;
	EndIf;
	// Try to check that period is equal to the check-in period of allotment to remove rooms from
	If RoomQuota.IsForCheckInPeriods Then
		If Not AllDays Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='All weekdays should be marked!'; ru='Все дни недели должны быть отмечены!'; de='Alle Wochentage müssen markiert sein!'"), MessageStatus.Important);
			Return;
		EndIf;
		rMessage = "";
		If Not CheckAllotmentPeriod(rMessage) Then
			tcCommonFunctionOnClientServer.TextMessage(rMessage);
			Return;
		EndIf;
	EndIf;
	
	// Process each selected period
	vPeriods = FillPeriodsToProcess();
	If vPeriods.Count() > 0 Then
		// Update allotment if manual price is specified
		If EditPrice Then
			vAllotmentObj = RoomQuota.GetObject();
			For Each vPeriodsRow In vPeriods Do
				If SelPrice >= 0 And ValueIsFilled(SelCurrency) And (SelNumberOfAdults <> 0 Or SelNumberOfTeenagers <> 0 Or SelNumberOfChildren <> 0 Or SelNumberOfInfants <> 0) Then
					vRQRTRows = vAllotmentObj.RoomTypes.FindRows(New Structure("RoomType, PeriodFrom, PeriodTo, IsPriceSetting, NumberOfAdults, NumberOfTeenagers, NumberOfChildren, NumberOfInfants", 
					                                                            RoomType, BegOfDay(vPeriodsRow.PeriodFrom), BegOfDay(vPeriodsRow.PeriodTo),
					                                                            True, SelNumberOfAdults, SelNumberOfTeenagers, SelNumberOfChildren, SelNumberOfInfants));
					If vRQRTRows.Count() > 0 Then
						vRQRTRow = vRQRTRows.Get(vRQRTRows.Count() - 1);
					Else
						vRQRTRow = vAllotmentObj.RoomTypes.Add();
						vRQRTRow.Hotel = RoomType.Owner;
						vRQRTRow.RoomType = RoomType;
						vRQRTRow.PeriodFrom = BegOfDay(vPeriodsRow.PeriodFrom);
						vRQRTRow.PeriodTo = BegOfDay(vPeriodsRow.PeriodTo);
					EndIf;
					vRQRTRow.NumberOfAdults = SelNumberOfAdults;
					vRQRTRow.NumberOfTeenagers = SelNumberOfTeenagers;
					vRQRTRow.NumberOfChildren = SelNumberOfChildren;
					vRQRTRow.NumberOfInfants = SelNumberOfInfants;
					vRQRTRow.NumberOfPersons = SelNumberOfAdults + SelNumberOfTeenagers + SelNumberOfChildren + SelNumberOfInfants;
					vRQRTRow.Price = SelPrice;
					vRQRTRow.Currency = SelCurrency;
					vRQRTRow.IsPriceSetting = True;
				EndIf;
			EndDo;
			If vAllotmentObj.Modified() Then
				vAllotmentObj.Write();
				// Repost set room quota documents intersecting with prices changed
				vRecalculateBusinessBlockBudget = False;
				For Each vPeriodsRow In vPeriods Do
					vSetRoomQuotas = GetIntersectingSetRoomQuotas(RoomQuota, RoomType, vPeriodsRow.PeriodFrom, vPeriodsRow.PeriodTo);
					If vSetRoomQuotas.Count() > 0 Then
						vRecalculateBusinessBlockBudget = True;
						For Each vSetRoomQuotasRow In vSetRoomQuotas Do
							vDocObj = vSetRoomQuotasRow.Ref.GetObject();
							vDocObj.Write(DocumentWriteMode.Posting);
						EndDo;
					EndIf;
				EndDo;
				If vRecalculateBusinessBlockBudget Then
					Catalogs.RoomQuotas.CalculateBusinessBlockBudget(vAllotmentObj.Ref, False);
				EndIf;
			EndIf;
		EndIf;
		
		// Create new "Set room quota" document and fill it's parameters from the filter page
		If EditInventory Then
			For Each vPeriodsRow In vPeriods Do
				vDocObj = Documents.SetRoomQuota.CreateDocument();
				vDocObj.RoomQuota = RoomQuota;
				vDocObj.BaseRoomQuota = RoomQuota.BaseRoomQuota;
				If ValueIsFilled(vDocObj.RoomQuota.Hotel) Then
					vDocObj.Hotel = vDocObj.RoomQuota.Hotel;
				EndIf;
				vDocObj.RoomType = RoomType;
				If Not ValueIsFilled(vDocObj.Hotel) Then
					vDocObj.Hotel = vDocObj.RoomType.Owner;
				EndIf;
				vDocObj.SetRoomQuotaType = Enums.SetRoomQuotaTypes.Remove;
				vDocObj.DateFrom = cm0SecondShift(GetTime(vPeriodsRow.PeriodFrom));
				vDocObj.pmFillAttributesWithDefaultValues();
				vDocObj.NumberOfBedsPerRoom = vDocObj.RoomType.NumberOfBedsPerRoom;
				vDocObj.NumberOfPersonsPerRoom = vDocObj.RoomType.NumberOfPersonsPerRoom;
				vDocObj.DateTo = cm0SecondShift(GetTime(vPeriodsRow.PeriodTo));
				vDocObj.Duration = vDocObj.pmCalculateDuration();
				FillDocumentNumberOfRoomsAndBeds(vDocObj);
				vDocObj.IsForecast = ?(SelMode = 2, True, False);
				vDocObj.IsInitial = ?(SelMode = 1 And SelShowSelector = 1, True, False);
				vDocObj.Write(DocumentWriteMode.Posting);
			EndDo;
		EndIf; 

		// Build structure with parameters to open report hierarchy
		vStr = New Structure("Hotel, RoomType, RoomQuota", vDocObj.Hotel, vDocObj.RoomType, vDocObj.RoomQuota);
		// Refresh report
		GenerateReport(vStr);
	ElsIf Not AllDays Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Mark at least one day of the week!'; ru='Отметьте хотя бы один день недели!'; de='Markieren Sie mindestens einen Wochentag!'"), MessageStatus.Important);
	EndIf;
EndProcedure // RemoveRoomsAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure MoveRoomQuotaRoomsGetQuota(pValue, pParam) Export 
	MoveRoomQuotaRoomsAtServer(pValue);	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure RecalculateTemplates()
	// Clear templates
	AccommodationTemplates.GetItems().Clear();
	// Clear quantities being saved
	PrevTemplateRowQuantities.Clear();
	// Create precalculated cash
	vCalculationCash = New ValueTable();
	vCalculationCash.Columns.Add("RoomType", cmGetCatalogTypeDescription("RoomTypes"));
	vCalculationCash.Columns.Add("AccommodationType", cmGetCatalogTypeDescription("AccommodationTypes"));
	vCalculationCash.Columns.Add("Amount", cmGetSumTypeDescription());
	vCalculationCash.Columns.Add("AvgPrice", cmGetSumTypeDescription());
	vCalculationCash.Columns.Add("Currency", cmGetCatalogTypeDescription("Currencies"));
	// Use cache or not
	vUseCalculationCash = True;
	If ValueIsFilled(RoomQuota) Then
		For Each vAllotmentRTRow In RoomQuota.RoomTypes Do
			If vAllotmentRTRow.Price <> 0 Then
				vUseCalculationCash = False;
				Break;
			EndIf;
		EndDo;
	EndIf;
	// Recalculate templates
	If ValueIsFilled(PeriodFrom) And
		ValueIsFilled(PeriodTo) And
		ValueIsFilled(RoomRate) Then
		// Get room types
		vRoomTypes = cmGetAllRoomTypes(SelHotel);
		If ValueIsFilled(RoomType) And Not RoomType.IsFolder Then
			vRoomTypes.Clear();
			vRoomTypesRow = vRoomTypes.Add();
			vRoomTypesRow.RoomType = RoomType;
		EndIf;
		// Run query to retrieve prices for room types
		vRoomTypePrices = GetRoomTypePrices(ClientType, RoomType, Duration);
		If ValueIsFilled(ClientType) And vRoomTypePrices.Count() = 0 Then
			vRoomTypePrices = GetRoomTypePrices(Catalogs.ClientTypes.EmptyRef(), RoomType, Duration);
		EndIf;
		// Run query to retrieve list of day types that are into the search period
		vCalendarDayTypes = GetEffectiveCalendarDayTypes(RoomType);
		// Run query to retrieve value table of price tags valid for the each date from the period selected
		vPriceTagsList = New ValueList();
		vPriceTags = GetEffectivePriceTags(vPriceTagsList);
		// Remove price tags not into the search period from the list of prices
		RemovePriceTags(vRoomTypePrices, vPriceTagsList);
		// Get list of valid templates
		vTemplates = cmGetAccommodationTemplatesValidForRoomType(RoomType);
		For Each vTemplatesItem In vTemplates Do
			vAccTemplate = vTemplatesItem.Value;
			If NumberOfAdults > 0 Or NumberOfTeenagers > 0 Or NumberOfChildren > 0 Or NumberOfInfants > 0 Then
				If vAccTemplate.NumberOfAdults <> NumberOfAdults Or 
				   vAccTemplate.NumberOfTeenagers <> NumberOfTeenagers Or
				   vAccTemplate.NumberOfChildren <> NumberOfChildren Or
				   vAccTemplate.NumberOfInfants <> NumberOfInfants Then
					Continue;
				EndIf;
			EndIf;
			For Each vRoomTypesRow In vRoomTypes Do
				vRoomType = vRoomTypesRow.RoomType;
				// Add row to the templates
				vAccTemplatesRow = AccommodationTemplates.GetItems().Add();
				vAccTemplatesRow.AccommodationTemplate = vAccTemplate;
				vAccTemplatesRow.RoomType = vRoomType;
				If ValueIsFilled(vRoomType) And ValueIsFilled(vRoomType.BaseRoomType) Then
					vAccTemplatesRow.RoomType = vRoomType.BaseRoomType;
				EndIf;
				vAccTemplatesRow.AccommodationType = Catalogs.AccommodationTypes.EmptyRef();
				vAccTemplatesRow.Quantity = 0;
				// Get room rate accommodation type overrides
				vOverrides = cmGetRoomRateOverrides(RoomRate, SelHotel, vAccTemplate, vRoomType);
				// Calculate amounts for each accommodation type from the template
				vAvgPrice = 0;
				vAmount = 0;
				vCurrency = Catalogs.Currencies.EmptyRef();
				For Each vAccommodationTypesRow In vAccTemplate.AccommodationTypes Do
					vAccTypeIndex = vAccTemplate.AccommodationTypes.IndexOf(vAccommodationTypesRow);
					vAccommodationType = vAccommodationTypesRow.AccommodationType;
					vOverrideRows = vOverrides.FindRows(New Structure("AccommodationType, TemplateLineNumber", vAccommodationType, vAccTypeIndex + 1));
					If vOverrideRows.Count() > 0 And ValueIsFilled(vOverrideRows.Get(0).ToAccommodationType) Then
						vAccommodationType = vOverrideRows.Get(0).ToAccommodationType;
					EndIf;
					// Calculate amount or take it from cash
					vCashRows = vCalculationCash.FindRows(New Structure("RoomType, AccommodationType", vRoomType, vAccommodationType));
					If vCashRows.Count() = 1 Then
						vCashRow = vCashRows.Get(0);
						vAmount = vCashRow.Amount;
						vAvgPrice = vCashRow.AvgPrice;
						vCurrency = vCashRow.Currency;
					Else
						CalculateAccommodationTypeAmountAndAveragePrice(vRoomTypePrices, vCalendarDayTypes, vPriceTags, vAccommodationType, vRoomType, 1, vAmount, vAvgPrice, vCurrency, vAccTemplate, ?(vAccTemplate.AccommodationTypes.IndexOf(vAccommodationTypesRow) = 0, True, False));
						// save values to the cash
						If vUseCalculationCash Then
							vCashRow = vCalculationCash.Add();
							vCashRow.RoomType = vRoomType;
							vCashRow.AccommodationType = vAccommodationType;
							vCashRow.Amount = vAmount;
							vCashRow.AvgPrice = vAvgPrice;
							vCashRow.Currency = vCurrency;
						EndIf;
					EndIf;
					// Fill accommodation type totals
					vAccTypeRow = vAccTemplatesRow.GetItems().Add();
					vAccTypeRow.AccommodationTemplate = vAccTemplate;
					vAccTypeRow.RoomType = vRoomType;
					If ValueIsFilled(vRoomType) And ValueIsFilled(vRoomType.BaseRoomType) Then
						vAccTypeRow.RoomType = vRoomType.BaseRoomType;
					EndIf;
					vAccTypeRow.AccommodationType = vAccommodationType;
					vAccTypeRow.Quantity = 0;
					vAccTypeRow.Amount = vAmount;
					vAccTypeRow.AvgPrice = vAvgPrice;
					vAccTypeRow.Currency = vCurrency;
					// Fill template totals
					vAccTemplatesRow.Amount = vAccTemplatesRow.Amount + vAmount;
					vAccTemplatesRow.AvgPrice = vAccTemplatesRow.AvgPrice + vAvgPrice;
					vAccTemplatesRow.Currency = vCurrency;
				EndDo;
			EndDo;
		EndDo;
	EndIf;
	// Totals
	TotalAmount = 0;
	TotalAvgPrice = 0;
	Items.AccommodationTemplates.Footer = False;
EndProcedure // RecalculateTemplates

// -----------------------------------------------------------------------------
&AtServer
Procedure CalculateAccommodationTypeAmountAndAveragePrice(pRoomTypes, pCalendarDayTypes, pPriceTags, pAccommodationType, pRoomType, pQuantity, rAmount, rAvgPrice, rCurrency, pAccommodationTemplate, pIsFirstAccTemplateRow = True)
	rAmount = 0;
	rAvgPrice = 0;
	rCurrency = Catalogs.Currencies.EmptyRef();
	vAllotmentRoomTypes = Undefined;
	If ValueIsFilled(RoomQuota) And RoomQuota.RoomTypes.Count() > 0 Then
		vAllotmentRoomTypes = RoomQuota.RoomTypes;
	EndIf;
	If ValueIsFilled(pAccommodationType) Then
		// Check room rate
		If ValueIsFilled(RoomRate) Then
			If RoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByHours Then
				Return;
			EndIf;
			vNumDays = 0;
			vDate = BegOfDay(PeriodFrom);
			vEndDate = BegOfDay(PeriodTo);
			If RoomRate.DurationCalculationRuleType <> Enums.DurationCalculationRuleTypes.ByDays Then
				vEndDate = vEndDate - 24 * 3600;
			EndIf;
			While vDate <= vEndDate Do
				vNumDays = vNumDays + 1;
				vCalendarDayType = Undefined;
				vCalendarDayTypeRows = pCalendarDayTypes.FindRows(New Structure("Period, RoomType", vDate, pRoomType));
				If vCalendarDayTypeRows.Count() > 0 Then
					vCalendarDayType = vCalendarDayTypeRows.Get(0).CalendarDayTypeByRoomType;
				Else
					vCalendarDayTypeRows = pCalendarDayTypes.FindRows(New Structure("Period", vDate));
					If vCalendarDayTypeRows.Count() > 0 Then
						vCalendarDayType = vCalendarDayTypeRows.Get(0).CalendarDayType;
					EndIf;
				EndIf;
				
				vPriceOverride = 0;
				vPriceIsOverriden = False;
				If vAllotmentRoomTypes <> Undefined And ValueIsFilled(pAccommodationTemplate) Then
					vRMPRows = vAllotmentRoomTypes.FindRows(New Structure("NumberOfAdults, NumberOfTeenagers, NumberOfChildren, NumberOfInfants", pAccommodationTemplate.NumberOfAdults, pAccommodationTemplate.NumberOfTeenagers, pAccommodationTemplate.NumberOfChildren, pAccommodationTemplate.NumberOfInfants));
					For Each vRMPRow In vRMPRows Do
						If vRMPRow.Price <> 0 And vRMPRow.RoomType = pRoomType Then
							If BegOfDay(vRMPRow.PeriodFrom) <= vDate And BegOfDay(vRMPRow.PeriodTo) > vDate Then
								vPriceOverride = vRMPRow.Price;
								If Not ValueIsFilled(rCurrency) Then
									rCurrency = vRMPRow.Currency;
								EndIf;
								vPriceIsOverriden = True;
								Break;
							EndIf;
						EndIf;
					EndDo;
					If vPriceIsOverriden And Not pIsFirstAccTemplateRow Then
						vPriceOverride = 0;
					EndIf;
					If vPriceIsOverriden Then
						rAmount = rAmount + vPriceOverride;
					EndIf;
				EndIf;
					
				If Not vPriceIsOverriden Then
					If vCalendarDayType <> Undefined Or ValueIsFilled(RoomRate) And RoomRate.UsePricesFromCalendar Then
						vPriceTagRow = pPriceTags.Find(vDate, "Period");
						If vPriceTagRow <> Undefined Then
							vPriceTag = vPriceTagRow.PriceTag;
							If ValueIsFilled(RoomRate) And RoomRate.UsePricesFromCalendar Then
								vRows = pRoomTypes.FindRows(New Structure("RoomType, AccommodationType, AccountingDate, PriceTag", pRoomType, pAccommodationType, vDate, vPriceTag));
							Else
								vRows = pRoomTypes.FindRows(New Structure("RoomType, AccommodationType, CalendarDayType, PriceTag", pRoomType, pAccommodationType, vCalendarDayType, vPriceTag));
							EndIf;
							If vRows.Count() = 1 Then
								vRow = vRows.Get(0);
								If Not ValueIsFilled(rCurrency) Then
									rCurrency = vRow.Currency;
								EndIf;
								If rCurrency <> vRow.Currency Then
									Return;
								EndIf;
								rAmount = rAmount + vRow.Price;
							Else
								Return;
							EndIf;
						Else
							Return;
						EndIf;
					Else
						Return;
					EndIf;
				EndIf;
				vDate = vDate + 24 * 3600;
			EndDo;
			rAmount = rAmount * pQuantity;
			If vNumDays > 0 Then 
				rAvgPrice = Round(rAmount / vNumDays, 2);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // CalculateAccommodationTypeAmountAndAveragePrice

// -----------------------------------------------------------------------------
&AtServer
Procedure RemovePriceTags(pRoomTypes, pPriceTagsList)
	vID = 0;
	While vID < pRoomTypes.Count() Do
		vRow = pRoomTypes.Get(vID);
		If pPriceTagsList.FindByValue(vRow.PriceTag) = Undefined Then
			pRoomTypes.Delete(vRow);
			Continue;
		EndIf;
		vID = vID + 1;
	EndDo;
EndProcedure // RemovePriceTags

// -----------------------------------------------------------------------------
&AtServer
Function GetEffectivePriceTags(rPriceTagsList)
	rPriceTagsList = New ValueList();
	vTable = cmGetEffectivePriceTags(SelHotel, RoomRate, RoomType, GetTime(PeriodFrom), GetTime(PeriodTo), rPriceTagsList, Duration);
	If ValueIsFilled(PriceTag) Then
		rPriceTagsList.Clear();
		rPriceTagsList.Add(PriceTag);
		For Each vTableRow In vTable Do
			If ValueIsFilled(vTableRow.PriceTag) Then
				vTableRow.PriceTag = PriceTag;
			EndIf;
		EndDo;
	EndIf;
	Return vTable;
EndFunction // GetEffectivePriceTags

// -----------------------------------------------------------------------------
&AtServer
Function GetEffectiveCalendarDayTypes(pRoomType = Undefined)
	If ValueIsFilled(RoomRate) And ValueIsFilled(RoomRate.Calendar) Then
		vList = RoomRate.Calendar.GetObject().pmGetDays(PeriodFrom, PeriodTo, PeriodFrom, PeriodTo, pRoomType);
	Else
		vList = New ValueTable();
		vList.Columns.Add("CalendarDayType", cmGetCatalogTypeDescription("CalendarDayTypes"));
		vList.Columns.Add("RoomType", cmGetCatalogTypeDescription("RoomTypes"));
		vList.Columns.Add("Period", cmGetDateTypeDescription());
	EndIf;
	Return vList;
EndFunction // GetEffectiveCalendarDayTypes

// -----------------------------------------------------------------------------
&AtServer
Function GetRoomTypePrices(pClientType, pRoomType, pDuration = 1)
	// First get active for check in date set room rate prices documents
	vOrders = cmGetActiveSetRoomRatePrices(RoomRate, CurrentSessionDate(), PeriodFrom, PeriodTo, , SelHotel);
	// Retrieve set room rate prices documents rows
	vQry = New Query();
	// Check room rate type
	If ValueIsFilled(RoomRate) And RoomRate.UsePricesFromCalendar Then
		vQry.Text = 
		"SELECT
		|	Orders.CalendarDayType AS CalendarDayType,
		|	Orders.PriceTag AS PriceTag,
		|	Orders.SetRoomRatePrices AS SetRoomRatePrices
		|INTO Orders
		|FROM
		|	&qOrders AS Orders
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AccommodationTypeFormulas.Ref.RoomRate AS RoomRate,
		|	AccommodationTypeFormulas.Ref.Hotel AS Hotel,
		|	AccommodationTypeFormulas.Ref AS SetRoomRatePrices,
		|	Orders.CalendarDayType AS CalendarDayType,
		|	Orders.PriceTag AS PriceTag,
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
		|		INNER JOIN Orders AS Orders
		|		ON AccommodationTypeFormulas.Ref = Orders.SetRoomRatePrices
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
		|		INNER JOIN Orders AS Orders
		|		ON FormulasForPriceTags.Ref = Orders.SetRoomRatePrices
		|			AND FormulasForPriceTags.PriceTag = Orders.PriceTag
		|			AND FormulasForPriceTags.CalendarDayType = Orders.CalendarDayType
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RateServices.Ref AS Service,
		|	RateServices.QuantityCalculationRule AS QuantityCalculationRule,
		|	RateServices.QuantityCalculationRule.QuantityCalculationRuleType AS QuantityCalculationRuleType,
		|	RateServices.IsRoomRevenue AS IsRoomRevenue,
		|	RateServices.IsInPrice AS IsInPrice,
		|	RateServices.ChargePerPerson AS ChargePerPerson,
		|	RateServices.ChargeToEachGuestSeparately AS ChargeToEachGuestSeparately,
		|	RateServices.Unit AS Unit,
		|	RateServices.RoomRevenueAmountsOnly AS RoomRevenueAmountsOnly
		|INTO RateServices
		|FROM
		|	Catalog.Services AS RateServices
		|WHERE
		|	RateServices.Ref = &qAccommodationService
		|	AND NOT RateServices.IsFolder
		|	AND NOT RateServices.DeletionMark
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
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
		|	(SELECT DISTINCT
		|		DaysByRoomTypes.RoomType AS RoomType,
		|		DaysByRoomTypes.AccountingDate AS AccountingDate,
		|		DaysByRoomTypes.CalendarDayType AS CalendarDayType,
		|		DaysByRoomTypes.PriceTag AS PriceTag,
		|		DaysByRoomTypes.RoomPrice AS RoomPrice,
		|		DaysByRoomTypes.RoomPriceCurrency AS RoomPriceCurrency
		|	FROM
		|		(SELECT
		|			RoomTypes.Ref AS RoomType,
		|			CalendarDays.AccountingDate AS AccountingDate,
		|			CASE
		|				WHEN CalendarDaysByRoomTypes.CalendarDayType IS NULL
		|					THEN CalendarDays.CalendarDayType
		|				WHEN CalendarDaysByRoomTypes.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef)
		|					THEN CalendarDays.CalendarDayType
		|				ELSE CalendarDaysByRoomTypes.CalendarDayType
		|			END AS CalendarDayType,
		|			CASE
		|				WHEN CalendarDaysByRoomTypes.PriceTag IS NULL
		|					THEN CalendarDays.PriceTag
		|				WHEN CalendarDaysByRoomTypes.PriceTag = VALUE(Catalog.PriceTags.EmptyRef)
		|					THEN CalendarDays.PriceTag
		|				ELSE CalendarDaysByRoomTypes.PriceTag
		|			END AS PriceTag,
		|			CASE
		|				WHEN CalendarDaysByRoomTypes.RoomPrice IS NULL
		|					THEN CalendarDays.RoomPrice
		|				WHEN CalendarDaysByRoomTypes.RoomPrice = 0
		|					THEN CalendarDays.RoomPrice
		|				ELSE CalendarDaysByRoomTypes.RoomPrice
		|			END AS RoomPrice,
		|			CASE
		|				WHEN CalendarDaysByRoomTypes.RoomPriceCurrency IS NULL
		|					THEN CalendarDays.RoomPriceCurrency
		|				WHEN CalendarDaysByRoomTypes.RoomPriceCurrency = VALUE(Catalog.Currencies.EmptyRef)
		|					THEN CalendarDays.RoomPriceCurrency
		|				ELSE CalendarDaysByRoomTypes.RoomPriceCurrency
		|			END AS RoomPriceCurrency
		|		FROM
		|			InformationRegister.CalendarDays.SliceLast(
		|					&qPriceCalculationDate,
		|					AccountingDate BETWEEN &qPeriodFrom AND &qPeriodTo
		|						AND Calendar = &qCalendar) AS CalendarDays
		|				LEFT JOIN Catalog.RoomTypes AS RoomTypes
		|				ON (RoomTypes.Owner = &qHotel)
		|					AND (RoomTypes.Ref = &qRoomType)
		|					AND (NOT RoomTypes.IsFolder)
		|					AND (NOT RoomTypes.DeletionMark)
		|				LEFT JOIN InformationRegister.CalendarDaysByRoomTypes.SliceLast(
		|						&qPriceCalculationDate,
		|						AccountingDate BETWEEN &qPeriodFrom AND &qPeriodTo
		|							AND Calendar = &qCalendar
		|							AND RoomType = &qRoomType) AS CalendarDaysByRoomTypes
		|				ON CalendarDays.AccountingDate = CalendarDaysByRoomTypes.AccountingDate
		|					AND (RoomTypes.Ref = CalendarDaysByRoomTypes.RoomType)) AS DaysByRoomTypes) AS RoomTypePricesByDates
		|		LEFT JOIN RateServices AS RateServices
		|		ON (TRUE)
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
		|	RawRoomRatePrices.RoomType.RoomClass AS RoomClass,
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
		|	RawRoomRatePrices.ChargePerPerson AS IsPricePerPerson,
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
		|			AND (RateAccommodationTypeFormulas.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef)
		|				OR RateAccommodationTypeFormulas.CalendarDayType <> VALUE(Catalog.CalendarDayTypes.EmptyRef)
		|					AND RateAccommodationTypeFormulas.CalendarDayType = RawRoomRatePrices.CalendarDayType)
		|		LEFT JOIN InformationRegister.ServicePrices.SliceLast(
		|				&qPriceCalculationDate,
		|				Service = &qAccommodationService
		|					AND Hotel = &qHotel) AS ServicePrices
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
		|	RoomRatePrices.IsPricePerPerson AS IsPricePerPerson,
		|	RoomRatePrices.ChargeToEachGuestSeparately AS ChargeToEachGuestSeparately,
		|	RoomRatePrices.Unit AS Unit,
		|	RoomRatePrices.RoomRevenueAmountsOnly AS RoomRevenueAmountsOnly
		|INTO RoomRatePrices
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
		|	RoomRatesSliceLast.SetRoomRateFormulas AS Recorder,
		|	RoomRatesSliceLast.RoomRate AS RoomRate
		|INTO ActiveSetRoomRateFormulas
		|FROM
		|	InformationRegister.RoomRates.SliceLast(
		|			&qPriceCalculationDate,
		|			RoomRate = &qRoomRate
		|				AND Hotel = &qHotel
		|				AND IsFormula) AS RoomRatesSliceLast
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
		|		ON RoomRateFormulas.Recorder = ActiveSetRoomRateFormulas.Recorder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RoomRatePrices.AccountingDate AS AccountingDate,
		|	RoomRatePrices.RoomType AS RoomType,
		|	RoomRatePrices.RoomType.SortCode AS RoomTypeSortCode,
		|	RoomRatePrices.AccommodationType AS AccommodationType,
		|	RoomRatePrices.AccommodationType.SortCode AS AccommodationTypeSortCode,
		|	RoomRatePrices.CalendarDayType AS CalendarDayType,
		|	RoomRatePrices.CalendarDayType.SortCode AS CalendarDayTypeSortCode,
		|	RoomRatePrices.PriceTag AS PriceTag,
		|	RoomRatePrices.PriceTag.SortCode AS PriceTagSortCode,
		|	RoomRatePrices.Currency AS Currency,
		|	RoomRatePrices.Currency.SortCode AS CurrencySortCode,
		|	RoomRateFormulas.BracketsConstant AS BracketsConstant,
		|	RoomRateFormulas.Constant AS Constant,
		|	RoomRateFormulas.Multiplier AS Multiplier,
		|	SUM(CASE
		|			WHEN RoomRatePrices.IsPricePerPerson
		|					AND RoomRatePrices.AccommodationType.NumberOfPersons4Reservation > 1
		|				THEN ((RoomRatePrices.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0)) * RoomRatePrices.AccommodationType.NumberOfPersons4Reservation
		|			WHEN RoomRatePrices.IsPricePerPerson
		|					AND RoomRatePrices.AccommodationType.NumberOfPersons > 1
		|				THEN ((RoomRatePrices.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0)) * RoomRatePrices.AccommodationType.NumberOfPersons
		|			ELSE (RoomRatePrices.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0)
		|		END) AS Price
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
		|WHERE
		|	RoomRatePrices.Hotel = &qHotel
		|	AND RoomRatePrices.RoomRate = &qPricesRoomRate
		|	AND RoomRatePrices.ClientType = &qClientType
		|	AND RoomRatePrices.RoomType = &qRoomType
		|	AND RoomRatePrices.IsInPrice = TRUE
		|
		|GROUP BY
		|	RoomRatePrices.AccountingDate,
		|	RoomRatePrices.RoomType,
		|	RoomRatePrices.RoomType.SortCode,
		|	RoomRatePrices.AccommodationType,
		|	RoomRatePrices.AccommodationType.SortCode,
		|	RoomRatePrices.CalendarDayType,
		|	RoomRatePrices.CalendarDayType.SortCode,
		|	RoomRatePrices.PriceTag,
		|	RoomRatePrices.PriceTag.SortCode,
		|	RoomRatePrices.Currency,
		|	RoomRatePrices.Currency.SortCode,
		|	RoomRateFormulas.BracketsConstant,
		|	RoomRateFormulas.Constant,
		|	RoomRateFormulas.Multiplier
		|
		|ORDER BY
		|	AccountingDate,
		|	RoomTypeSortCode,
		|	AccommodationTypeSortCode,
		|	CalendarDayTypeSortCode,
		|	PriceTagSortCode,
		|	CurrencySortCode";
		vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
		vQry.SetParameter("qPeriodTo", BegOfDay(PeriodTo));
		vQry.SetParameter("qPriceCalculationDate", CurrentSessionDate());
		vQry.SetParameter("qClientType", pClientType);
		vQry.SetParameter("qRoomRate", RoomRate);
		vQry.SetParameter("qCalendar", RoomRate.Calendar);
		vQry.SetParameter("qAccommodationService", RoomRate.AccommodationService);
		vQry.SetParameter("qPricesRoomRate", ?(ValueIsFilled(RoomRate.BasedOnRoomRate), RoomRate.BasedOnRoomRate, RoomRate));
		vQry.SetParameter("qHotel", SelHotel);
		vQry.SetParameter("qRoomType", pRoomType);
		vQry.SetParameter("qOrders", vOrders);
	Else
		vQry.Text = 
		"SELECT
		|	Orders.CalendarDayType AS CalendarDayType,
		|	Orders.PriceTag AS PriceTag,
		|	Orders.SetRoomRatePrices AS SetRoomRatePrices
		|INTO Orders
		|FROM
		|	&qOrders AS Orders
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
		|			RoomRate = &qRoomRate
		|				AND Hotel = &qHotel
		|				AND IsFormula) AS RoomRatesSliceLast
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
		|		ON RoomRateFormulas.Recorder = ActiveSetRoomRateFormulas.Recorder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RoomRatePrices.RoomType AS RoomType,
		|	RoomRatePrices.RoomType.SortCode AS RoomTypeSortCode,
		|	RoomRatePrices.AccommodationType AS AccommodationType,
		|	RoomRatePrices.AccommodationType.SortCode AS AccommodationTypeSortCode,
		|	RoomRatePrices.CalendarDayType AS CalendarDayType,
		|	RoomRatePrices.CalendarDayType.SortCode AS CalendarDayTypeSortCode,
		|	RoomRatePrices.PriceTag AS PriceTag,
		|	RoomRatePrices.PriceTag.SortCode AS PriceTagSortCode,
		|	RoomRatePrices.Currency AS Currency,
		|	RoomRatePrices.Currency.SortCode AS CurrencySortCode,
		|	RoomRateFormulas.BracketsConstant AS BracketsConstant,
		|	RoomRateFormulas.Constant AS Constant,
		|	RoomRateFormulas.Multiplier AS Multiplier,
		|	SUM(CASE
		|			WHEN RoomRatePrices.IsPricePerPerson
		|					AND RoomRatePrices.AccommodationType.NumberOfPersons4Reservation > 1
		|				THEN ((RoomRatePrices.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0)) * RoomRatePrices.AccommodationType.NumberOfPersons4Reservation
		|			WHEN RoomRatePrices.IsPricePerPerson
		|					AND RoomRatePrices.AccommodationType.NumberOfPersons > 1
		|				THEN ((RoomRatePrices.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0)) * RoomRatePrices.AccommodationType.NumberOfPersons
		|			ELSE (RoomRatePrices.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0)
		|		END) AS Price
		|FROM
		|	InformationRegister.RoomRatePrices AS RoomRatePrices
		|		INNER JOIN Orders AS Orders
		|		ON RoomRatePrices.CalendarDayType = Orders.CalendarDayType
		|			AND RoomRatePrices.PriceTag = Orders.PriceTag
		|			AND RoomRatePrices.SetRoomRatePrices = Orders.SetRoomRatePrices
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
		|WHERE
		|	RoomRatePrices.Hotel = &qHotel
		|	AND RoomRatePrices.RoomRate = &qPricesRoomRate
		|	AND RoomRatePrices.ClientType = &qClientType
		|	AND RoomRatePrices.RoomType = &qRoomType
		|	AND RoomRatePrices.IsInPrice = TRUE
		|
		|GROUP BY
		|	RoomRatePrices.RoomType,
		|	RoomRatePrices.RoomType.SortCode,
		|	RoomRatePrices.AccommodationType,
		|	RoomRatePrices.AccommodationType.SortCode,
		|	RoomRatePrices.CalendarDayType,
		|	RoomRatePrices.CalendarDayType.SortCode,
		|	RoomRatePrices.PriceTag,
		|	RoomRatePrices.PriceTag.SortCode,
		|	RoomRatePrices.Currency,
		|	RoomRatePrices.Currency.SortCode,
		|	RoomRateFormulas.BracketsConstant,
		|	RoomRateFormulas.Constant,
		|	RoomRateFormulas.Multiplier
		|
		|ORDER BY
		|	RoomTypeSortCode,
		|	AccommodationTypeSortCode,
		|	CalendarDayTypeSortCode,
		|	PriceTagSortCode,
		|	CurrencySortCode";
		vQry.SetParameter("qPriceCalculationDate", CurrentSessionDate());
		vQry.SetParameter("qClientType", pClientType);
		vQry.SetParameter("qRoomRate", RoomRate);
		vQry.SetParameter("qPricesRoomRate", ?(ValueIsFilled(RoomRate.BasedOnRoomRate), RoomRate.BasedOnRoomRate, RoomRate));
		vQry.SetParameter("qHotel", SelHotel);
		vQry.SetParameter("qRoomType", pRoomType);
		vQry.SetParameter("qOrders", vOrders);
	EndIf;
	vList = vQry.Execute().Unload();
	// Add prices from room rate service packages
	If ValueIsFilled(RoomRate) Then
		vPackagesList = RoomRate.GetObject().pmGetRoomRateServicePackagesList(, True);
		For Each vPackagesListItem In vPackagesList Do
			vServicePackage = vPackagesListItem.Value;
			If ValueIsFilled(vServicePackage) Then
				If vServicePackage.DateValidFrom <= BegOfDay(PeriodFrom) And 
					(vServicePackage.DateValidTo >= BegOfDay(PeriodFrom) Or Not ValueIsFilled(vServicePackage.DateValidTo)) Then
					If ValueIsFilled(RoomRate) And RoomRate.UsePricesFromCalendar Then
						vCurDate = BegOfDay(PeriodFrom);
						While vCurDate <= BegOfDay(PeriodTo) Do
							vListDayPrices = vList.FindRows(New Structure("AccountingDate", vCurDate));
							If vListDayPrices.Count() > 0 Then
								vServices = Catalogs.ServicePackages.GetServices(vServicePackage, vCurDate);
								For Each vServicePackageRow In vServices Do
									If vServicePackageRow.IsInPrice Then
										For Each vListRow In vListDayPrices Do
											// Filter by calendar day type
											If ValueIsFilled(vServicePackageRow.CalendarDayType) And vServicePackageRow.CalendarDayType <> vListRow.CalendarDayType Then
												Continue;
											EndIf;
											// Filter by other settings
											If vListRow.Currency = vServicePackageRow.Currency And 
												(pClientType = vServicePackageRow.ClientType Or ValueIsFilled(pClientType) And Not ValueIsFilled(vServicePackageRow.ClientType)) And
												(vListRow.RoomType = vServicePackageRow.RoomType Or Not ValueIsFilled(vServicePackageRow.RoomType)) And
												(vListRow.AccommodationType = vServicePackageRow.AccommodationType Or Not ValueIsFilled(vServicePackageRow.AccommodationType)) Then
												If ValueIsFilled(vServicePackageRow.AccountingDate) Or vServicePackageRow.AccountingDayNumber > 0 Or
												  (Not ValueIsFilled(vServicePackageRow.AccountingDate) And vServicePackageRow.AccountingDayNumber = 0 And Not ValueIsFilled(vServicePackageRow.QuantityCalculationRule)) Then
													// Check accounting date time for service package
													vDuration = pDuration;
													If ValueIsFilled(vServicePackageRow.AccountingDate) And vServicePackageRow.AccountingDate <> BegOfDay(vServicePackageRow.AccountingDate) Then
														If BegOfDay(PeriodFrom) = BegOfDay(vServicePackageRow.AccountingDate) And vServicePackageRow.AccountingDate <= PeriodFrom Then
															If vDuration > 0 Then
																vDuration = vDuration - 1;
															EndIf;
														EndIf;
														If BegOfDay(PeriodTo) = BegOfDay(vServicePackageRow.AccountingDate) And vServicePackageRow.AccountingDate >= PeriodTo Then
															If vDuration > 0 Then
																vDuration = vDuration - 1;
															EndIf;
														EndIf;
													EndIf;
													vListRow.Price = vListRow.Price + vServicePackageRow.Quantity * vServicePackageRow.Price / ?(vDuration = 0, 1, vDuration);
												Else
													vListRow.Price = vListRow.Price + vServicePackageRow.Quantity * vServicePackageRow.Price;
												EndIf;
											EndIf;
										EndDo;
									EndIf;
								EndDo;
							EndIf;
							vCurDate = vCurDate + 24*3600;
						EndDo;
					Else
						vServices = Catalogs.ServicePackages.GetServices(vServicePackage, PeriodFrom);
						For Each vServicePackageRow In vServices Do
							If vServicePackageRow.IsInPrice Then
								For Each vListRow In vList Do
									// Filter by calendar day type
									If ValueIsFilled(vServicePackageRow.CalendarDayType) And vServicePackageRow.CalendarDayType <> vListRow.CalendarDayType Then
										Continue;
									EndIf;
									// Filter by other settings
									If vListRow.Currency = vServicePackageRow.Currency And 
										(pClientType = vServicePackageRow.ClientType Or ValueIsFilled(pClientType) And Not ValueIsFilled(vServicePackageRow.ClientType)) And
										(vListRow.RoomType = vServicePackageRow.RoomType Or Not ValueIsFilled(vServicePackageRow.RoomType)) And
										(vListRow.AccommodationType = vServicePackageRow.AccommodationType Or Not ValueIsFilled(vServicePackageRow.AccommodationType)) Then
										If ValueIsFilled(vServicePackageRow.AccountingDate) Or vServicePackageRow.AccountingDayNumber > 0 Or
										  (Not ValueIsFilled(vServicePackageRow.AccountingDate) And vServicePackageRow.AccountingDayNumber = 0 And Not ValueIsFilled(vServicePackageRow.QuantityCalculationRule)) Then
											// Check accounting date time for service package
											vDuration = pDuration;
											If ValueIsFilled(vServicePackageRow.AccountingDate) And vServicePackageRow.AccountingDate <> BegOfDay(vServicePackageRow.AccountingDate) Then
												If BegOfDay(PeriodFrom) = BegOfDay(vServicePackageRow.AccountingDate) And vServicePackageRow.AccountingDate <= PeriodFrom Then
													If vDuration > 0 Then
														vDuration = vDuration - 1;
													EndIf;
												EndIf;
												If BegOfDay(PeriodTo) = BegOfDay(vServicePackageRow.AccountingDate) And vServicePackageRow.AccountingDate >= PeriodTo Then
													If vDuration > 0 Then
														vDuration = vDuration - 1;
													EndIf;
												EndIf;
											EndIf;
											vListRow.Price = vListRow.Price + vServicePackageRow.Quantity * vServicePackageRow.Price / ?(vDuration = 0, 1, vDuration);
										Else
											vListRow.Price = vListRow.Price + vServicePackageRow.Quantity * vServicePackageRow.Price;
										EndIf;
									EndIf;
								EndDo;
							EndIf;
						EndDo;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	// Add discounts from room rate discount type
	If ValueIsFilled(RoomRate) And ValueIsFilled(RoomRate.DiscountType) Then
		vDiscountTypeObj = RoomRate.DiscountType.GetObject();
		vDiscount = vDiscountTypeObj.pmGetDiscount(PeriodFrom, , SelHotel);
		For Each vListRow In vList Do
			vListRow.Price = vListRow.Price - Round(vListRow.Price*vDiscount/100, 2);
		EndDo;
	EndIf;
	// Return
	Return vList;
EndFunction // GetRoomTypePrices

// -----------------------------------------------------------------------------
&AtServer
Procedure CalculateAtServer()
	// Recalculate templates
	RecalculateTemplates();	
EndProcedure

// -----------------------------------------------------------------------------        
&AtServer
Procedure GuestGroupAppearance()
	If UseSameGuestGroup Then
		Items.GuestGroup.Enabled = True;
		Items.GuestGroup.Visible = True;
	Else
		Items.GuestGroup.Enabled = False;
		Items.GuestGroup.Visible = False;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function GetTime(vDate, pIsCheckIn = False, pIsCheckOut = False)
	vRH = 43200;
	
	vRoomRate = RoomRate;
	If Not ValueIsFilled(vRoomRate) Then
		If ValueIsFilled(SelRoomRate) Then
			vRoomRate = SelRoomRate;
		Else
			If ValueIsFilled(SelHotel) Then
				vRoomRate = SelHotel.RoomRate;
			EndIf;
		EndIf;
	EndIf;
	
	If pIsCheckIn And ValueIsFilled(vRoomRate) And ValueIsFilled(vRoomRate.DefaultCheckInTime) Then
		vRH = vRoomRate.DefaultCheckInTime - BegOfDay(vRoomRate.DefaultCheckInTime);
	ElsIf pIsCheckOut And ValueIsFilled(vRoomRate) And ValueIsFilled(vRoomRate.DefaultCheckOutTime) Then
		vRH = vRoomRate.DefaultCheckOutTime - BegOfDay(vRoomRate.DefaultCheckOutTime);
	ElsIf ValueIsFilled(vRoomRate) And ValueIsFilled(vRoomRate.ReferenceHour) Then
		vRH = vRoomRate.ReferenceHour - BegOfDay(vRoomRate.ReferenceHour);
	EndIf;
	
	Return cm0SecondShift(vDate + vRH);	
EndFunction

// -----------------------------------------------------------------------------  
&AtServer
Function TryToGetPeriodWithVacantRoomsMinimum(pDetails)
	If pDetails.CheckOutDate > pDetails.CheckInDate Then
		// Try to get period with vacant rooms minimum 
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	MAX(RoomInventoryMinBalances.CounterClosingBalance) AS CounterClosingBalance,
		|	MIN(RoomInventoryMinBalances.RoomsVacantClosingBalance) AS RoomsVacant,
		|	MIN(RoomInventoryMinBalances.BedsVacantClosingBalance) AS BedsVacant
		|INTO RoomInventoryMinBalances
		|FROM
		|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(
		|			&qPeriodFrom,
		|			&qPeriodTo,
		|			Minute,
		|			RegisterRecordsAndPeriodBoundaries,
		|			(Hotel IN HIERARCHY (&qHotel)
		|				OR &qHotelIsEmpty)
		|				AND (RoomType IN HIERARCHY (&qRoomTypes)
		|					OR &qRoomTypesAreEmpty)
		|				AND NOT RoomType.IsVirtual
		|				AND NOT RoomType.DeletionMark) AS RoomInventoryMinBalances
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 1
		|	RoomInventoryBalances.Period AS PeriodDate,
		|	RoomInventoryBalances.CounterClosingBalance AS CounterClosingBalance,
		|	RoomInventoryBalances.RoomsVacantClosingBalance AS RoomsVacant,
		|	RoomInventoryBalances.BedsVacantClosingBalance AS BedsVacant
		|FROM
		|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(
		|			&qPeriodFrom,
		|			&qPeriodTo,
		|			Minute,
		|			RegisterRecordsAndPeriodBoundaries,
		|			(Hotel IN HIERARCHY (&qHotel)
		|				OR &qHotelIsEmpty)
		|				AND (RoomType IN HIERARCHY (&qRoomTypes)
		|					OR &qRoomTypesAreEmpty)
		|				AND NOT RoomType.IsVirtual
		|				AND NOT RoomType.DeletionMark) AS RoomInventoryBalances
		|		INNER JOIN RoomInventoryMinBalances AS RoomInventoryMinBalances
		|		ON RoomInventoryBalances.BedsVacantClosingBalance = RoomInventoryMinBalances.BedsVacant
		|
		|ORDER BY
		|	PeriodDate";
		vRoomTypes = New ValueList();
		If pDetails.RoomType <> Undefined Then
			vRoomTypes.Add(pDetails.RoomType);
		Else
			vRoomTypes = SelRoomTypes;
		EndIf;
		vQry.SetParameter("qHotel", ?(pDetails.Hotel = Undefined, SelHotel, pDetails.Hotel));
		vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(?(pDetails.Hotel = Undefined, SelHotel, pDetails.Hotel)));
		vQry.SetParameter("qRoomTypes", vRoomTypes);
		vQry.SetParameter("qRoomTypesAreEmpty", ?(vRoomTypes.Count() = 0, True, False));
		vQry.SetParameter("qPeriodFrom", cm1SecondShift(pDetails.CheckInDate));
		vQry.SetParameter("qPeriodTo", cm0SecondShift(pDetails.CheckOutDate));
		vQryRes = vQry.Execute().Unload();
		vMinVacantRoomsPeriod = Undefined;
		If vQryRes.Count() > 0 Then
			vQryResRow = vQryRes.Get(0);
			If TypeOf(vQryResRow.PeriodDate) = Type("Date") And ValueIsFilled(vQryResRow.PeriodDate) Then
				vMinVacantRoomsPeriod = vQryResRow.PeriodDate;
			EndIf;
		EndIf;
		If vMinVacantRoomsPeriod <> Undefined Then
			Return vMinVacantRoomsPeriod;
		Else
			Return pDetails.PeriodDate;
		EndIf;
	Else
		Return pDetails.PeriodDate;
	EndIf;
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Function CreateGroupRes(rAddRoomsToAllotment = False, rAllotmentBalances = Undefined)
	vWarnings = "";
	If Not cmCheckUserPermissions("HavePermissionToCreateReservationsInThePast") Then
		vCurrentDate = BegOfDay(CurrentSessionDate());
		If ValueIsFilled(SelHotel) And ValueIsFilled(SelHotel.AccountingDate) Then
			vCurrentDate = SelHotel.AccountingDate;
		EndIf;
		If BegOfDay(PeriodFrom) < vCurrentDate Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'You do not have rights to create reservation in the past!'; 
															|de = 'Sie haben keine Berechtigung, in der Vergangenheit Reservierungen vorzunehmen!'; 
															|ru = 'Нет прав создавать бронь в прошлом!'"));
			Return Undefined;
		EndIf;
	EndIf;
	If UseSameGuestGroup Then
		vGuestGroup = GuestGroup;
	EndIf;
	vAccommodationTemplates = AccommodationTemplates.GetItems();
	vSetClientType = True; 
	BeginTransaction();
	Try
		For Each vAccommodationTemplateRow In vAccommodationTemplates Do
			If vAccommodationTemplateRow.Quantity > 0 Then
				vNumber = 1;
				While vNumber <= vAccommodationTemplateRow.Quantity Do
					vFirstDoc = True;
					vOverrides = New ValueTable();
					vAccommodationType = vAccommodationTemplateRow.GetItems();				
					For Each vAccommodationTypeRow In vAccommodationType Do
						If vFirstDoc Then
							FirstRes = Documents.Reservation.CreateDocument();
							FirstRes.CheckInDate  = GetTime(PeriodFrom, True);
							FirstRes.CheckOutDate = GetTime(PeriodTo, False, True);
							FirstRes.RoomType = RoomType;
							If ValueIsFilled(FirstRes.RoomType) Then
								FirstRes.Hotel = FirstRes.RoomType.Owner;
								If ValueIsFilled(FirstRes.RoomType.BaseRoomType) Then
									FirstRes.RoomTypeUpgrade = FirstRes.RoomType;
									FirstRes.RoomType = FirstRes.RoomType.BaseRoomType;
								EndIf;
							Else
								FirstRes.Hotel = SelHotel;
							EndIf;
							FirstRes.RoomQuota = RoomQuota;
							If ValueIsFilled(RoomQuota) Then
								// Reservation status
								If RoomQuota.AllotmentBusinessType = Enums.AllotmentBusinessTypes.BusinessBlock Then
									If RoomQuota.AllotmentType = Enums.AllotmentTypes.Definite And (Not ValueIsFilled(FirstRes.ReservationStatus) Or ValueIsFilled(FirstRes.ReservationStatus) And Not FirstRes.ReservationStatus.IsGuaranteed) Then
										vGuaranteedReservationStatus = cmGetDefaultGuaranteedReservationStatus(FirstRes.Hotel);
										If ValueIsFilled(vGuaranteedReservationStatus) Then
											FirstRes.ReservationStatus = vGuaranteedReservationStatus;
											If ValueIsFilled(vGuaranteedReservationStatus.GuaranteeType) Then
												FirstRes.GuaranteeType = vGuaranteedReservationStatus.GuaranteeType;
											EndIf;
											If vGuaranteedReservationStatus.DoCharging And 
							  				   (Not vGuaranteedReservationStatus.DoChargingIfRoomIsFilled Or vGuaranteedReservationStatus.DoChargingIfRoomIsFilled And ValueIsFilled(FirstRes.Room)) Then
												FirstRes.DoCharging = True;
											Else
												FirstRes.DoCharging = False;
											EndIf;
										EndIf;
									ElsIf (RoomQuota.AllotmentType = Enums.AllotmentTypes.Tentative Or RoomQuota.AllotmentType = Enums.AllotmentTypes.DefiniteNotGuaranteed) And 
									      (Not ValueIsFilled(FirstRes.ReservationStatus) Or ValueIsFilled(FirstRes.ReservationStatus) And FirstRes.ReservationStatus.IsGuaranteed) Then
										vNotGuaranteedReservationStatus = cmGetDefaultNotGuaranteedReservationStatus(FirstRes.Hotel);
										If ValueIsFilled(vNotGuaranteedReservationStatus) Then
											FirstRes.ReservationStatus = vNotGuaranteedReservationStatus;
											If vNotGuaranteedReservationStatus.DoCharging And 
							  				  (Not vNotGuaranteedReservationStatus.DoChargingIfRoomIsFilled Or vNotGuaranteedReservationStatus.DoChargingIfRoomIsFilled And ValueIsFilled(FirstRes.Room)) Then
												FirstRes.DoCharging = True;
											Else
												FirstRes.DoCharging = False;
											EndIf;
										EndIf;
									EndIf;
								EndIf;
								// Agent
								FirstRes.Agent = RoomQuota.Agent;
								If ValueIsFilled(FirstRes.Agent) Then
									FirstRes.AgentCommission = FirstRes.Agent.AgentCommission;
									FirstRes.AgentCommissionType = FirstRes.Agent.AgentCommissionType;
									FirstRes.AgentCommissionServiceGroup = FirstRes.Agent.AgentCommissionServiceGroup;
								EndIf;
								If ValueIsFilled(RoomQuota.Contract) Then
									FirstRes.Customer = RoomQuota.Contract.Owner;
									FirstRes.Contract = RoomQuota.Contract;
									// Planned payment method
									If ValueIsFilled(FirstRes.Contract.PlannedPaymentMethod) Then
										FirstRes.PlannedPaymentMethod = FirstRes.Contract.PlannedPaymentMethod;
									EndIf;
									// Agent commission
									If Not FirstRes.Contract.IsSubagent And Not ValueIsFilled(FirstRes.Agent) Then
										FirstRes.Agent = FirstRes.Contract.Agent;
										If ValueIsFilled(FirstRes.Contract.AgentCommissionType) Then
											FirstRes.Agent = FirstRes.Customer;
											FirstRes.AgentCommission = FirstRes.Contract.AgentCommission;
											FirstRes.AgentCommissionType = FirstRes.Contract.AgentCommissionType;
											FirstRes.AgentCommissionServiceGroup = FirstRes.Contract.AgentCommissionServiceGroup;
										EndIf;
									EndIf;
									If Not ValueIsFilled(FirstRes.Agent) Then
										FirstRes.AgentCommission = 0;
										FirstRes.AgentCommissionType = Undefined;
										FirstRes.AgentCommissionServiceGroup = Catalogs.ServiceGroups.EmptyRef();
									EndIf;
									// Contract company
									If ValueIsFilled(FirstRes.Contract.Company) Then
										FirstRes.Company = FirstRes.Contract.Company;
									EndIf;
									// Marketing code
									If ValueIsFilled(FirstRes.Contract.MarketingCode) Then
										FirstRes.MarketingCode = FirstRes.Contract.MarketingCode;
										FirstRes.MarketingCodeConfirmationText = "";
									EndIf;
									// Source of business
									If ValueIsFilled(FirstRes.Contract.SourceOfBusiness) Then
										FirstRes.SourceOfBusiness = FirstRes.Contract.SourceOfBusiness;
									EndIf;
									// Client type
									If ValueIsFilled(FirstRes.Contract.ClientType) Then
										FirstRes.ClientType = FirstRes.Contract.ClientType;
										FirstRes.ClientTypeConfirmationText = FirstRes.Contract.ClientTypeConfirmationText;
									EndIf;
									// Do not print rate
									If FirstRes.Contract.DoNotPrintRate Then
										FirstRes.DoNotPrintRate = True;
									EndIf;
									// Meal board term
									If ValueIsFilled(FirstRes.Contract.MealBoardTerm) Then
										FirstRes.ServicePackage = FirstRes.Contract.MealBoardTerm;
									EndIf;
								ElsIf ValueIsFilled(RoomQuota.Customer) Then
									FirstRes.Customer = RoomQuota.Customer;
									FirstRes.Contract = Catalogs.Contracts.EmptyRef();
									FirstRes.CustomerType = FirstRes.Customer.CustomerType;
									// Room rate type
									If ValueIsFilled(FirstRes.CustomerType) Then
										If Not ValueIsFilled(FirstRes.RoomRateType) Then
											FirstRes.RoomRateType = FirstRes.CustomerType.RoomRateType;
										EndIf;
									EndIf;
									// Contact person
									If Not IsBlankString(FirstRes.Customer.ContactPerson) Then
										FirstRes.ContactPerson = TrimR(FirstRes.Customer.ContactPerson);
									EndIf;
									// Planned payment method
									If ValueIsFilled(FirstRes.Customer.PlannedPaymentMethod) Then
										FirstRes.PlannedPaymentMethod = FirstRes.Customer.PlannedPaymentMethod;
									EndIf;
									// Agent
									If Not ValueIsFilled(FirstRes.Agent) Then
										If ValueIsFilled(FirstRes.Customer.AgentCommissionType) Then
											FirstRes.Agent = FirstRes.Customer;
											FirstRes.AgentCommission = FirstRes.Agent.AgentCommission;
											FirstRes.AgentCommissionType = FirstRes.Agent.AgentCommissionType;
											FirstRes.AgentCommissionServiceGroup = FirstRes.Agent.AgentCommissionServiceGroup;
										EndIf;
									EndIf;
									If Not ValueIsFilled(FirstRes.Agent) Then
										FirstRes.AgentCommission = 0;
										FirstRes.AgentCommissionType = Undefined;
										FirstRes.AgentCommissionServiceGroup = Catalogs.ServiceGroups.EmptyRef();
									EndIf;
									// Marketing code
									If ValueIsFilled(FirstRes.Customer.MarketingCode) Then
										FirstRes.MarketingCode = FirstRes.Customer.MarketingCode;
										FirstRes.MarketingCodeConfirmationText = "";
									EndIf;
									// Source of business
									If ValueIsFilled(FirstRes.Customer.SourceOfBusiness) Then
										FirstRes.SourceOfBusiness = FirstRes.Customer.SourceOfBusiness;
									EndIf;
									// Client type
									If ValueIsFilled(FirstRes.Customer.ClientType) Then
										FirstRes.ClientType = FirstRes.Customer.ClientType;
										FirstRes.ClientTypeConfirmationText = FirstRes.Customer.ClientTypeConfirmationText;
									EndIf;
									// Customer remarks
									If Not IsBlankString(FirstRes.Customer.Remarks) And FirstRes.Customer.CopyRemarksToDocuments Then
										rIsHousekeepingRemarks = False;
										vCustRemarks = TrimAll(FirstRes.Customer.Remarks);
										vRemarks = cmGetRemarks(vCustRemarks, FirstRes.RoomType, rIsHousekeepingRemarks);
										If rIsHousekeepingRemarks Then
											FirstRes.HousekeepingRemarks = TrimAll(vRemarks + Chars.LF + TrimAll(FirstRes.HousekeepingRemarks));
										Else
											FirstRes.Remarks = TrimAll(vRemarks + Chars.LF + TrimAll(FirstRes.Remarks));
										EndIf;
									EndIf;
									// Do not print rate
									If FirstRes.Customer.DoNotPrintRate Then
										FirstRes.DoNotPrintRate = True;
									EndIf;
								EndIf;
							EndIf;
							If ValueIsFilled(RoomRate) Then
								FirstRes.RoomRate = RoomRate;
							EndIf;
							If ValueIsFilled(RoomQuota) Then
								If ValueIsFilled(RoomQuota.SourceOfBusiness) Then
									FirstRes.SourceOfBusiness = RoomQuota.SourceOfBusiness;
								EndIf;
								If ValueIsFilled(RoomQuota.MarketingCode) Then
									FirstRes.MarketingCode = RoomQuota.MarketingCode;
								EndIf;
								If ValueIsFilled(RoomQuota.ClientType) Then
									FirstRes.ClientType = RoomQuota.ClientType;
								EndIf;
								If ValueIsFilled(RoomQuota.TripPurpose) Then
									FirstRes.TripPurpose = RoomQuota.TripPurpose;
								EndIf;
							EndIf;
							If vSetClientType Then
								FirstRes.ClientType = ClientType;
								If ClientType.Mode = Enums.ClientTypeModes.PerClient Then 
									vSetClientType = False;
								EndIf;
							EndIf;					
							FirstRes.AccommodationType = vAccommodationTypeRow.AccommodationType;
							FirstRes.AccommodationTemplate = vAccommodationTypeRow.AccommodationTemplate;
							vOverrides = cmGetRoomRateOverrides(FirstRes.RoomRate, FirstRes.Hotel, FirstRes.AccommodationTemplate, ?(ValueIsFilled(FirstRes.RoomTypeUpgrade), FirstRes.RoomTypeUpgrade, FirstRes.RoomType));
							If vOverrides.Count() > 0 Then
								vOverrideRows = vOverrides.FindRows(New Structure("AccommodationType, TemplateLineNumber", FirstRes.AccommodationType, 1));
								If vOverrideRows.Count() > 0 And ValueIsFilled(vOverrides.Get(0).ToAccommodationType) Then
									FirstRes.AccommodationType = vOverrides.Get(0).ToAccommodationType;
								EndIf;
							EndIf;
							FirstRes.pmCalculateResources(); 
							If ValueIsFilled(vGuestGroup) then
								FirstRes.GuestGroup = vGuestGroup;
								FirstRes.pmFillAttributesWithDefaultValues();		
							Else
								FirstRes.pmFillAttributesWithDefaultValues();	
								vGuestGroup = FirstRes.GuestGroup;
								If ValueIsFilled(vGuestGroup) Then
									If ValueIsFilled(RoomQuota) Then
										vGuestGroupObj = vGuestGroup.GetObject();
										If vGuestGroupObj.Allotment <> RoomQuota Then
											vGuestGroupObj.Allotment = RoomQuota;
										EndIf;
										If ValueIsFilled(RoomQuota.SourceOfBusiness) And vGuestGroupObj.SourceOfBusiness <> RoomQuota.SourceOfBusiness Then
											vGuestGroupObj.SourceOfBusiness = RoomQuota.SourceOfBusiness;
										EndIf;
										If ValueIsFilled(RoomQuota.MarketingCode) And vGuestGroupObj.MarketingCode <> RoomQuota.MarketingCode Then
											vGuestGroupObj.MarketingCode = RoomQuota.MarketingCode;
										EndIf;
										If ValueIsFilled(RoomQuota.ClientType) And vGuestGroupObj.ClientType <> RoomQuota.ClientType Then
											vGuestGroupObj.ClientType = RoomQuota.ClientType;
										EndIf;
										If ValueIsFilled(RoomQuota.TripPurpose) And vGuestGroupObj.TripPurpose <> RoomQuota.TripPurpose Then
											vGuestGroupObj.TripPurpose = RoomQuota.TripPurpose;
										EndIf;
										If vGuestGroupObj.Modified() Then
											vGuestGroupObj.Write();
										EndIf;
									EndIf;
								EndIf;
							EndIf;
							If ValueIsFilled(FirstRes.Contract) Then
								FirstRes.pmLoadChargingRules(FirstRes.Contract);
							ElsIf ValueIsFilled(FirstRes.Customer) Then 
								FirstRes.pmLoadChargingRules(FirstRes.Customer);
							EndIf;
							FirstRes.Duration = FirstRes.pmCalculateDuration();
							If FirstRes.pmCalculateServices(vWarnings , , , , , FirstRes.IsForFolioSplit) Then
								tcCommonFunctionOnClientServer.TextMessage(tcOnServer.cmNStrAtServer(vWarnings));
							EndIf;
							
							FirstRes.AdditionalProperties.Insert("AddRoomsToAllotment", rAddRoomsToAllotment);
							FirstRes.AdditionalProperties.Insert("AllotmentBalances", rAllotmentBalances);
							
							FirstRes.Write(DocumentWriteMode.Posting);
							FirstRes.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
							vFirstDoc = False;
							
							// Fill flag to modify allotment
							If FirstRes.AdditionalProperties.Property("AddRoomsToAllotment") And FirstRes.AdditionalProperties.AddRoomsToAllotment Then
								rAddRoomsToAllotment = True;
							EndIf;
							If FirstRes.AdditionalProperties.Property("AllotmentBalances") And TypeOf(FirstRes.AdditionalProperties.AllotmentBalances) = Type("Array") Then
								If rAllotmentBalances = Undefined Then
									rAllotmentBalances = FirstRes.AdditionalProperties.AllotmentBalances;
								Else
									For Each vAllotmentBalancesStruct In FirstRes.AdditionalProperties.AllotmentBalances Do
										rAllotmentBalances.Add(vAllotmentBalancesStruct);
									EndDo;
								EndIf;
							EndIf;
						Else
							CurrDoc = 1;
							vNewDoc = FirstRes.Copy();
							vNewDoc.Number = FirstRes.Number;
							vNewDoc.Date   = FirstRes.Date;
							vNewDoc.CheckInDate  = GetTime(PeriodFrom, True);
							vNewDoc.CheckOutDate = GetTime(PeriodTo, False, True);
							vNewDoc.RoomQuota    = RoomQuota;
							vNewDoc.RoomType     = RoomType;
							vNewDoc.RoomRate     = RoomRate;
							If vSetClientType Then
								vNewDoc.ClientType = ClientType;
							EndIf;	
							vNewDoc.GuestGroup   = vGuestGroup;
							vNewDoc.AccommodationType = vAccommodationTypeRow.AccommodationType;
							vNewDoc.AccommodationTemplate = Undefined;
							If vOverrides.Count() > 0 Then
								vOverrideRows = vOverrides.FindRows(New Structure("AccommodationType, TemplateLineNumber", vNewDoc.AccommodationType, CurrDoc + 1));
								If vOverrideRows.Count() > 0 And ValueIsFilled(vOverrideRows.Get(0).ToAccommodationType) Then
									vNewDoc.AccommodationType = vOverrideRows.Get(0).ToAccommodationType;
								EndIf;
							EndIf;
							vNewDoc.pmCalculateResources(); 
							vNewDoc.Duration = vNewDoc.pmCalculateDuration();
							If vNewDoc.pmCalculateServices(vWarnings , , , , , vNewDoc.IsForFolioSplit) Then
								tcCommonFunctionOnClientServer.TextMessage(tcOnServer.cmNStrAtServer(vWarnings));
							EndIf;	
							
							vNewDoc.AdditionalProperties.Insert("AddRoomsToAllotment", rAddRoomsToAllotment);
							vNewDoc.AdditionalProperties.Insert("AllotmentBalances", rAllotmentBalances);
							
							vNewDoc.Write(DocumentWriteMode.Posting);
							vNewDoc.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);

							CurrDoc = CurrDoc + 1;	
							
							// Fill flag to modify allotment
							If vNewDoc.AdditionalProperties.Property("AddRoomsToAllotment") And vNewDoc.AdditionalProperties.AddRoomsToAllotment Then
								rAddRoomsToAllotment = True;
							EndIf;
							If vNewDoc.AdditionalProperties.Property("AllotmentBalances") And TypeOf(vNewDoc.AdditionalProperties.AllotmentBalances) = Type("Array") Then
								rAllotmentBalances = vNewDoc.AdditionalProperties.AllotmentBalances;
							EndIf;
						EndIf;
					EndDo;
					vNumber = vNumber + 1;
				EndDo; 
			EndIf;
		EndDo; 
		vFirstDoc = True;	
		If ClientType.Mode = Enums.ClientTypeModes.PerRoom Then 
			vSetClientType = False;
		EndIf;
		If ValueIsFilled(Event) Then
			If FirstRes.GuestGroup.Event <> Event Then
				vGuestGroupObj = FirstRes.GuestGroup.GetObject();
				vGuestGroupObj.Event = Event;			
				vGuestGroupObj.Write();
			EndIf;
		EndIf;
		vGuestGroupRes = FirstRes.GuestGroup;  
		CommitTransaction();
	Except      
		RollbackTransaction();  
		
		tcCommonFunctionOnClientServer.TextMessage(ErrorDescription()); 
		vGuestGroupRes = Undefined;
	EndTry;   
	Return vGuestGroupRes;
EndFunction

// ----------------------------------------------------------------------------- 
&AtServer
Function CheckRoomsNumber()
	vAccommodationTemplates = AccommodationTemplates.GetItems();
	vCount = 0;
	For Each vAccommodationTemplateRow In vAccommodationTemplates Do
		vCount = vCount + vAccommodationTemplateRow.Quantity;	
	EndDo; 
	Return vCount;
EndFunction

// ----------------------------------------------------------------------------- 
&AtServer
Procedure SetGuestGroup(pParentDoc) 
	If ValueIsFilled(pParentDoc) Then
		If TypeOf(pParentDoc) = Type("CatalogRef.GuestGroups") Then
			GuestGroup = pParentDoc;
		Else
			GuestGroup = pParentDoc.GuestGroup;
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AutoRefreshForm() 
	If IsInputAvailable() Then
		GenerateReport();
	Else
		AttachIdleHandler("AutoRefreshForm", 1, True);
	EndIf;
EndProcedure // RefreshListAndTotals

// -----------------------------------------------------------------------------
&AtServer
Procedure DurationsOnChangeAtServer()
	PeriodTo = cmCalculateCheckOutDate(RoomRate, PeriodFrom, Duration);	
EndProcedure // DurationsOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure PeriodToOnChangeAtServer()
	If PeriodTo <= PeriodFrom Then
		PeriodTo = PeriodFrom + 24*3600;
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='The end of the period must be later than the beginning of the period!'; ru='Окончание периода должно быть позже начала периода!'; de='Das Ende der Periode sollte später als der Beginn der Periode liegen!'"), MessageStatus.Attention);
	EndIf;
	Duration = cmCalculateDuration(RoomRate, PeriodFrom, PeriodTo);	
EndProcedure // PeriodToOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure PeriodFromOnChangeAtServer()
	PeriodTo = cmCalculateCheckOutDate(RoomRate, PeriodFrom, Duration);	
EndProcedure // PeriodFromOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetSetRoomQuotaParams()
	vParams = New Structure();
	// Apply filters
	vParams.Insert("RoomQuota", RoomQuota);
	vParams.Insert("SelEmployee", SessionParameters.CurrentUser);
	vParams.Insert("SelHistoryFrom", BegOfDay(CurrentSessionDate()));
	vParams.Insert("SelHistoryTo", EndOfDay(CurrentSessionDate()));
	vParams.Insert("SelHotel", SelHotel);
	Return vParams;
EndFunction

// -----------------------------------------------------------------------------
&AtClient
Procedure GoToHistoryAction(Command)
	OpenForm("Document.SetRoomQuota.Form.tcListForm", GetSetRoomQuotaParams()); 
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SetPriceGroupTitleAtServer()
	If SelPrice <> 0 And ValueIsFilled(SelCurrency) And 
	  (SelNumberOfAdults <> 0 Or SelNumberOfTeenagers <> 0 Or SelNumberOfChildren <> 0 Or SelNumberOfInfants <> 0) Then
		Items.GroupPrice.Title = NStr("en='Manual price: '; ru='Своб. цена: '; de='Manueller Preis: '") + 
		                              cmFormatSum(SelPrice, SelCurrency) + " " + 
		                              SelNumberOfAdults + "/" + SelNumberOfTeenagers + "/" + SelNumberOfChildren + "/" + SelNumberOfInfants;
	Else
		Items.GroupPrice.Title = NStr("en='Manual price'; ru='Своб. цена'; de='Manueller Preis'");
	EndIf;
EndProcedure // SetPriceGroupTitleAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SetWeekdaysTitle()
	vTitle = NStr("en='Weekdays'; ru='Дни недели'; de='Wochentage'");
	If Not AllDays Then
		wTitle = "";
		For i = 1 To 7 Do
			If ThisObject["Day" + i] Then
				wTitle = wTitle + ?(IsBlankString(wTitle), "", ", ") + Items["Day" + i].Title;
			EndIf;
		EndDo;
		If Not IsBlankString(wTitle) Then
			vTitle = NStr("en='Only: '; ru='Только: '; de='Nur: '") + wTitle;
		Else	
			vTitle = NStr("en='Select weekdays!'; ru='Отметьте дни недели!'; de='Wochentage markieren!'");
		EndIf;
	EndIf;
	Items.GroupWeekdays.Title = vTitle;
EndProcedure // SetWeekdaysTitle

// -----------------------------------------------------------------------------
&AtServer
Procedure FillShowSelectorGroupTitle()
	If SelMode = 1 Then
		Items.GroupTotalsShowSelector.Title = NStr("en='Show: '; ru='Показать: '; de='Anzeigen: '");
		If SelShowSelector = 0 Then
			Items.GroupTotalsShowSelector.Title = Items.GroupTotalsShowSelector.Title + NStr("en='Total'; ru='Выделено'; de='Gesamt'");
		ElsIf SelShowSelector = 1 Then
			Items.GroupTotalsShowSelector.Title = Items.GroupTotalsShowSelector.Title + NStr("en='Initial'; ru='Начально'; de='Начально'");
			InventoryEditMode = 1;
		ElsIf SelShowSelector = 2 Then
			Items.GroupTotalsShowSelector.Title = Items.GroupTotalsShowSelector.Title + NStr("en='Difference'; ru='Разница'; de='Differenz'");
		ElsIf SelShowSelector = 3 Then
			Items.GroupTotalsShowSelector.Title = Items.GroupTotalsShowSelector.Title + NStr("en='Remains'; ru='Остатки'; de='Reste'");
		ElsIf SelShowSelector = 5 Then
			Items.GroupTotalsShowSelector.Title = Items.GroupTotalsShowSelector.Title + NStr("en='Pickup'; ru='Выбрано'; de='Pickup'");
		ElsIf SelShowSelector = 4 Then
			Items.GroupTotalsShowSelector.Title = Items.GroupTotalsShowSelector.Title + NStr("en='Price'; ru='Цену'; de='Preis'");
			If PriceNumberOfAdults > 0 Then
				Items.GroupTotalsShowSelector.Title = Items.GroupTotalsShowSelector.Title + NStr("en=' for '; ru=' за '; de=' für '") + Format(PriceNumberOfAdults, "NFD=0; NG=") + NStr("en=' adults'; ru=' взрослых'; de=' Erwachsene'");
			EndIf;
		EndIf;
	EndIf;
EndProcedure // FillShowSelectorGroupTitle

// -----------------------------------------------------------------------------
&AtServer
Function FillPeriodsToProcess()
	vPeriods = New ValueTable();
	vPeriods.Columns.Add("PeriodFrom", cmGetDateTypeDescription());
	vPeriods.Columns.Add("PeriodTo", cmGetDateTypeDescription());

	If AllDays Then
		vPeriodsRow = vPeriods.Add();
		vPeriodsRow.PeriodFrom = PeriodFrom;
		vPeriodsRow.PeriodTo = PeriodTo;
	Else
		vCurDate = PeriodFrom;
		vCurPeriodsRow = Undefined;
		While vCurDate <= PeriodTo Do
			If ThisObject["Day" + WeekDay(vCurDate)] Then
				If vCurPeriodsRow = Undefined Then
					vCurPeriodsRow = vPeriods.Add();
					vCurPeriodsRow.PeriodFrom = vCurDate;
					vCurPeriodsRow.PeriodTo = vCurDate + 24*3600;
				Else
					vCurPeriodsRow.PeriodTo = vCurDate + 24*3600;
				EndIf;
			Else
				vCurPeriodsRow = Undefined;
			EndIf;
				
			vCurDate = vCurDate + 24*3600;
		EndDo;
	EndIf;
	
	Return vPeriods;
EndFunction // FillPeriodsToProcess

// -----------------------------------------------------------------------------
&AtServer
Function GetAllotmentDatePrice(pAlotment, pRoomType, pDate, pAdults)
	Return pAlotment.GetObject().pmCalculateBusinessBlockPricePerRoomTypeAndDate(pRoomType, pDate, pAdults, 0, 0, 0);
EndFunction // GetAllotmentDatePrice

// -----------------------------------------------------------------------------
&AtServer
Function GetIntersectingSetRoomQuotas(pRoomQuota, pRoomType, pPeriodFrom, pPeriodTo)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SetRoomQuota.Ref AS Ref
	|FROM
	|	Document.SetRoomQuota AS SetRoomQuota
	|WHERE
	|	SetRoomQuota.RoomQuota = &qRoomQuota
	|	AND SetRoomQuota.RoomQuota.AllotmentBusinessType = VALUE(Enum.AllotmentBusinessTypes.BusinessBlock)
	|	AND SetRoomQuota.RoomType = &qRoomType
	|	AND SetRoomQuota.DateFrom < &qPeriodTo
	|	AND SetRoomQuota.DateTo > &qPeriodFrom
	|	AND SetRoomQuota.Posted
	|
	|ORDER BY
	|	SetRoomQuota.PointInTime";
	vQry.SetParameter("qRoomQuota", pRoomQuota);
	vQry.SetParameter("qRoomType", pRoomType);
	vQry.SetParameter("qPeriodFrom", pPeriodFrom);
	vQry.SetParameter("qPeriodTo", pPeriodTo);
	Return vQry.Execute().Unload();
EndFunction // GetIntersectingSetRoomQuotas

// -----------------------------------------------------------------------------
&AtServer
Procedure FillAllRoomTypes()
	AllRoomTypes.Clear();
	If ValueIsFilled(SelHotel) Then
		i = 0;
		While i < SelRoomTypes.Count() Do
			vRoomType = SelRoomTypes.Get(i).Value;
			If ValueIsFilled(vRoomType) And vRoomType.Owner <> SelHotel Then
				SelRoomTypes.Delete(i);
			ElsIf Not ValueIsFilled(vRoomType) Then
				SelRoomTypes.Delete(i);
			Else
				i = i + 1;
			EndIf;
		EndDo;
		i = 0;
		While i < SelRoomQuotas.Count() Do
			vAllotment = SelRoomQuotas.Get(i).Value;
			If ValueIsFilled(vAllotment) And ValueIsFilled(vAllotment.Hotel) And vAllotment.Hotel <> SelHotel Then
				vAllotment = GetAllotmentByDescriptionAndHotel(vAllotment.Description, SelHotel);
				If ValueIsFilled(vAllotment) Then
					SelRoomQuotas.Get(i).Value = vAllotment;
					i = i + 1;
				Else
					SelRoomQuotas.Delete(i);
				EndIf;
			ElsIf Not ValueIsFilled(vAllotment) Then
				SelRoomQuotas.Delete(i);
			Else
				i = i + 1;
			EndIf;
		EndDo;
		// Fill all room types
		vAllRoomTypes = cmGetAllRoomTypes(SelHotel);
		For Each vAllRoomTypesRow In vAllRoomTypes Do
			If Not vAllRoomTypesRow.IsVirtual Then
				AllRoomTypes.Add(vAllRoomTypesRow.RoomType);
			EndIf;
		EndDo;
	EndIf;
EndProcedure // FillAllRoomTypes

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetAllotmentByDescriptionAndHotel(pDescription, pHotel)
	vAllotment = Catalogs.RoomQuotas.EmptyRef();
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomQuotas.Ref AS Ref
	|FROM
	|	Catalog.RoomQuotas AS RoomQuotas
	|WHERE
	|	RoomQuotas.Description = &qDescription
	|	AND (RoomQuotas.Hotel = &qHotel
	|			OR RoomQuotas.Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|	AND NOT RoomQuotas.DeletionMark
	|	AND NOT RoomQuotas.IsFolder
	|
	|ORDER BY
	|	RoomQuotas.Code";
	vQry.SetParameter("qDescription", TrimR(pDescription));
	vQry.SetParameter("qHotel", pHotel);
	vAllotments = vQry.Execute().Unload();
	For Each vAllotmentsRow In vAllotments Do
		vAllotment = vAllotmentsRow.Ref;
		Break;
	EndDo;
	Return vAllotment;
EndFunction // GetAllotmentByDescriptionAndHotel

#EndRegion    
