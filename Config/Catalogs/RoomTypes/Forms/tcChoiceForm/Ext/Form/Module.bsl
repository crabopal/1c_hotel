
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	NumberOfKidAgeFields = 8;
	RoomQuantity = 1;
	IsFromObject = False;
	vRoomRate = Undefined;
	If Parameters.Property("RoomRate", vRoomRate) Then
		SelRoomRate = vRoomRate;
	EndIf;
	vFilter = Undefined;
	vHotel = Undefined;
	If Parameters.Property("Filter", vFilter) Then
		If vFilter.Property("Owner", vHotel) Then
			SelHotel = vHotel;
		EndIf;
	EndIf;
	If Parameters.Property("Hotel", vHotel) Then
		SelHotel = vHotel;
	EndIf;
	NumberOfRatesToShowInRoomRatesSearchForm = 10;
	If ValueIsFilled(SelHotel) And Not SelHotel.IsFolder Then
		NumberOfRatesToShowInRoomRatesSearchForm = SelHotel.NumberOfRatesToShowInRoomRatesSearchForm;
	EndIf;
	vCheckInDate = Undefined;
	If Parameters.Property("CheckInDate", vCheckInDate) Then
		SelCheckInDate = vCheckInDate;
		SelCheckInTime = vCheckInDate;
	EndIf;
	vCheckOutDate = Undefined;
	If Parameters.Property("CheckOutDate", vCheckOutDate) Then
		SelCheckOutDate = vCheckOutDate;
		SelCheckOutTime = vCheckOutDate;
	EndIf;
	vRoomQuota = Undefined;
	If Parameters.Property("RoomQuota", vRoomQuota) Then
		SelRoomQuota = vRoomQuota;
	EndIf;
	vClientType = Undefined;
	If Parameters.Property("ClientType", vClientType) Then
		SelClientType = vClientType;
	EndIf;
	vNumberOfAdults = Undefined;
	If Parameters.Property("NumberOfAdults", vNumberOfAdults) Then
		NumberOfAdults = vNumberOfAdults;
	EndIf;
	AgeList.Clear();
	vNumberOfKids = Undefined;
	If Parameters.Property("NumberOfKids", vNumberOfKids) Then
		NumberOfKids = vNumberOfKids;
		vAgeArray = Undefined;
		If Parameters.Property("AgeArray", vAgeArray) Then
			For Each vItem In vAgeArray Do
				AgeList.Add(vItem);
			EndDo;
			If AgeList.Count() > 0 Then
				vIndex = 1;
				For Each vItem In AgeList Do
					Try
						ThisObject["KidAge"+String(vIndex)] = vItem.Value;
					Except
					EndTry;
					vIndex = vIndex + 1;
					If vIndex > NumberOfKidAgeFields Then
						Break;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	SelNumberOfRatesToShow = -1;
	If Parameters.Property("NumberOfRatesToShow") Then
		SelNumberOfRatesToShow = Parameters.NumberOfRatesToShow;
		NumberOfRatesToShowInRoomRatesSearchForm = SelNumberOfRatesToShow;
	EndIf;
	vCustomer = Undefined;
	If Parameters.Property("Customer", vCustomer) Then
		SelCustomer = vCustomer;
	EndIf;
	vContract = Undefined;
	If Parameters.Property("Contract", vContract) Then
		SelContract = vContract;
	EndIf;
	vRoomType = Undefined;
	If Parameters.Property("RoomType", vRoomType) Then
		If ValueIsFilled(vRoomType) Then
			SelChoiceInitialValue = vRoomType;
		EndIf;
	EndIf;  
	If Parameters.Property("GuestGroup") Then
		SelGuestGroup = Parameters.GuestGroup;
	EndIf; 
	If Parameters.Property("Guest") Then
		SelClient = Parameters.Guest;
	EndIf;
	If Parameters.Property("SourceOfBusiness") Then
		SelSourceOfBusiness = Parameters.SourceOfBusiness;
	EndIf;
	If Parameters.Property("MarketingCode") Then
		SelMarketingCode = Parameters.MarketingCode;
	EndIf;
	vWindowView = Undefined;
	SelWindowView = Undefined;
	If Parameters.Property("WindowView", vWindowView) Then
		Items.WindowView.Visible = True;
		If ValueIsFilled(vWindowView) Then
			SelWindowView = vWindowView;
		EndIf;
	Else
		Items.WindowView.Visible = False;
	EndIf;
	SelectRoomRateMode = False;
	If Parameters.Property("SelectRoomRateMode") Then
		SelectRoomRateMode = Parameters.SelectRoomRateMode;
		IsFromObject = True;
	EndIf;
	vRoomQuantity = Undefined;
	If Parameters.Property("RoomQuantity", vRoomQuantity) Then
		If cmIsNumber(vRoomQuantity) And vRoomQuantity > 1 Then
			RoomQuantity = vRoomQuantity;
		EndIf;
	EndIf;
	If (NumberOfAdults <> 0 Or NumberOfKids <> 0) And 
	   ValueIsFilled(SelRoomRate) And (SelRoomRate.PeriodInHours = 24 Or SelRoomRate.PeriodInHours = 0)  
	   And (SelRoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour 
	   Or SelRoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByDays) Then
		vRoomRates = New ValueList();
		vRoomRates.Add(SelRoomRate);
		If ValueIsFilled(SelHotel) And SelHotel.UseRoomRateDailyPrices And cmRoomRatePricesCacheIsFilled(SelHotel, vRoomRates, SelClientType, SelCheckInDate, SelCheckOutDate) Then
			IsFromObject = True;
		EndIf;
	EndIf;
	If ValueIsFilled(SelHotel) And SelHotel.ShowReportsInBeds Then
		ShowReportInBeds = True;
	Else
		ShowReportInBeds = False;
	EndIf;
	
	// Set hotel color          
	Items.HotelGroup.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
	
	If Not IsFromObject And Not SelectRoomRateMode Then
		Items.NumberOfPersons.Visible = False;
	EndIf;
	If IsFromObject And Not SelectRoomRateMode Then
		Items.RoomRate.ReadOnly = True;
	EndIf;
	If SelectRoomRateMode Then
		Items.ReservationAttributes.Visible = True;
	Else
		Items.ReservationAttributes.Visible = False;
	EndIf;
	If IsFromObject And Not SelectRoomRateMode Then
		Items.Hotel.ReadOnly = True;
		Items.Hotel.ChoiceButton = False;
		Items.NumberOfPersons.ReadOnly = True;
		Items.NumberOfAdults.SpinButton = False;
		Items.NumberOfKids.SpinButton = False;
		Items.RoomQuantity.SpinButton = False;
	EndIf;
	If IsFromObject And Not SelectRoomRateMode Then
		Items.GuestsInRoomGroup.Visible = False;
	EndIf;
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToAddManualDiscounts") Then
		Items.GuestsInRoomDiscount.ReadOnly = True;
		Items.GuestsInRoomDiscount.Visible = False;
	EndIf;
	
	// Board place
	Items.GuestsInRoomBoardPlace.Visible = True;
	If ValueIsFilled(SelHotel) Then
		vBoardPlaces = cmGetBoardPlaces(SelHotel);
		If vBoardPlaces.Count() = 0 Then
			Items.GuestsInRoomBoardPlace.Visible = False;
		EndIf;
	Else
		Items.GuestsInRoomBoardPlace.Visible = False;
	EndIf;
	
	OnOpenForm();
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	If ValueIsFilled(NumberOfKids) Then
		NumberOfKidsOnChange(Items.NumberOfKids);
		If AgeList.Count() > 0 Then
			vIndex = 1;
			For Each vItem In AgeList Do
				Try
					Items["KidAge"+String(vIndex)].Visible = True;
					ThisObject["KidAge"+String(vIndex)] = vItem.Value;
				Except
				EndTry;
				vIndex = vIndex + 1;
				If vIndex > NumberOfKidAgeFields Then
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	AttachIdleHandler("GetDailyTotalsJobResult", 1, True);
	#IF MobileClient Then
		Items.GuestsInRoomGroup.Visible = False;
	#ENDIF
EndProcedure // OnOpen

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If SelectRoomRateMode Then
		If pEventName = "Document.Reservation.Write" Or pEventName = "Document.Reservation.WriteNew" Then
			AttachIdleHandler("RefreshFormData", 1, True);
		ElsIf pEventName = "Document.Accommodation.Write" Or pEventName = "Document.Accommodation.WriteNew" Then
			AttachIdleHandler("RefreshFormData", 1, True);
		ElsIf pEventName = "Catalog.GuestGroups.Changed" Then
			AttachIdleHandler("RefreshFormData", 1, True);
		ElsIf pEventName = "System.Hotel.Changed" And pParameter <> Hotel Then
			Hotel = pParameter;
			SelHotel = Hotel;
			HotelOnChangeAtServer();
			RefreshList(Commands.RefreshList);
		EndIf;
	Else
		If pEventName = "System.Hotel.Changed" And pParameter <> Hotel Then
			Close();
		EndIf;
	EndIf;
EndProcedure // NotificationProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoiceProcessing(pSelectedValue, pChoiceSource)
	If TypeOf(pSelectedValue) = Type("CatalogRef.Rooms") And ValueIsFilled(pSelectedValue) Then
		If FormOwner <> Undefined Then
			NotifyChoice(pSelectedValue);
		Else
			Room = pSelectedValue;
			RowSelectionAction(Commands.RowSelectionAction);
		EndIf;
	EndIf;
EndProcedure // ChoiceProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure NewReservation(pCommand)
	RoomType = CurRoomType;
	CreateNewReservation(True);
EndProcedure // CreateReservation

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypesListSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	If ValueIsFilled(RoomQuota) Then
		vIsFolder = tcOnServer.cmGetAttributeByRef(RoomQuota, "IsFolder");
		If vIsFolder Then
			vMessage = New UserMessage;
			vMessage.Field = "RoomQuota";
			vMessage.Text = NStr("en='You should choose allotment item not group to select room type!';ru='Нельзя выбирать тип номера при указанной группе квот!';de='Der Zimmertyp bei angegebener Quotengruppe darf nicht gewählt werden!'");
			vMessage.Message();
			Return;
		EndIf;
	EndIf;
	If pItem.CurrentData <> Undefined Then
		If TypeOf(pItem.CurrentData.RoomType) = Type("CatalogRef.Hotels") And ValueIsFilled(pItem.CurrentData.RoomType) And pItem.CurrentData.RoomType <> Hotel Then
			vHotel = pItem.CurrentData.RoomType;
			// Check if this hotel is allowed for the employee
			If tcOnServer.IsHotelAllowedForEmployee(vHotel) Then
				// Do change hotel
				tcOnServer.ChangeCurrentHotel(vHotel);
				// Change application caption
				tcOnClient.ChangeApplicationCaption(vHotel);
				// Set functional options hotel parameter
				SetInterfaceFunctionalOptionParameters(New Structure("Hotel", vHotel));
				// Notify hotel was changed
			 	Notify("System.Hotel.Changed", vHotel, ThisForm);
			EndIf;
		Else
			If ValueIsFilled(pItem.CurrentData.Ref) Then
				If FormOwner = Undefined Then
					If pSelectedRow <> Undefined Then
						RoomType = pItem.CurrentData.Ref;
						vInd = 0;
						If Left(pField.Name, 28) = "RoomTypesListSumPresentation" And pField.Name <> "RoomTypesListSumPresentation" Then
							vInd = Number(Right(pField.Name, 1));
							Try
								RoomRate = pItem.CurrentData["RoomRate"+vInd];
							Except
							EndTry;
						EndIf;
						If SelectRoomRateMode Then
							If ValueIsFilled(Hotel) And tcOnServer.cmGetAttributeByRef(Hotel, "DefaultActionAfterRoomTypeAndRoomRateSelection") = PredefinedValue("Enum.DefaultActionsAfterRoomTypeAndRoomRateSelection.OpenRoomGuestsTable") Then
								// Open room guests table
								Items.GuestsInRoomGroup.Show();
								// Recalculate table
								AttachIdleHandler("RecalculateOfferAtClient", 0.1, True);
							Else
								// Create new reservation
								CreateNewReservation();
							EndIf;
						Else
							NotifyChoice(pItem.CurrentData.Ref);
						EndIf;
					EndIf;
				Else
					vInd = 0;
					If Left(pField.Name, 28) = "RoomTypesListSumPresentation" And pField.Name <> "RoomTypesListSumPresentation" Then
						vInd = Number(Right(pField.Name, 1));
						Try
							RoomRate = pItem.CurrentData["RoomRate"+vInd];
						Except
						EndTry;
					EndIf;
					vFormOwner = FormOwner;
					vType = Undefined;
					#If ThickClientOrdinaryApplication Then
						vType = Type("TextBox");
					#EndIf
					If TypeOf(vFormOwner) <> vType Then
						While (TypeOf(vFormOwner) <> Type("ClientApplicationForm")) Or vFormOwner = Undefined Do
							vFormOwner = vFormOwner.Parent;
						EndDo;
					Else
						vFormOwner = Undefined;
					EndIf;
					vChoiceParams = Undefined;
					If vFormOwner <> Undefined Then
						If vFormOwner.FormName = "Document.Reservation.Form.tcDocumentForm" Or 
						   vFormOwner.FormName = "Document.Reservation.Form.mcDocumentForm" Or 
						   vFormOwner.FormName = "Document.Accommodation.Form.tcDocumentForm" Or 
						   vFormOwner.FormName = "Document.Accommodation.Form.mcDocumentForm" Or 
						   vFormOwner.FormName = "Catalog.GuestGroups.Form.tcItemForm" Or 
						   vFormOwner.FormName = "Catalog.GuestGroups.Form.mcItemForm" Or 
						   vFormOwner.FormName = "CommonForm.tcAvailableRoomsReport" Then
							vChoiceParams = New Structure("RoomQuota, RoomType, AccommodationType, RoomRate, ClientType, CheckInDate, CheckOutDate, Duration", RoomQuota, pItem.CurrentData.Ref, Undefined, RoomRate, ClientType, CheckInDate, CheckOutDate, Duration);
						Else
							vChoiceParams = pItem.CurrentData.Ref;
						EndIf;
					Else
						vChoiceParams = pItem.CurrentData.Ref;
					EndIf;
					If vChoiceParams <> Undefined Then
						If Not pItem.CurrentData.StopSale Then 
							NotifyChoice(vChoiceParams);
						Else
							vMsg = GetMessageQueryBox(pItem.CurrentData.Ref, CheckInDate, CheckOutDate);
							ShowQueryBox(New NotifyDescription("AfterShowWarningMessage", ThisObject, vChoiceParams), vMsg, QuestionDialogMode.YesNo, , , NStr("en = 'Warning!'; de = 'Warnung!'; ru = 'Предупреждение!'"));	
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // RoomTypesListSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypeOnChange(pItem)
	// Refresh list
	RefreshList(Commands.RefreshList);
EndProcedure // RoomTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRateOnChange(pItem)
	// Reset table of guests in room
	If ValueIsFilled(RoomRate) Then
		Items.FormAvailableRoomsAction.Enabled = True;
		
		IsInChangeRoomRateMode = True;
		Items.RoomTypesList.CurrentItem = Items.RoomTypesListSumPresentation;
		
		// Refresh list
		RefreshList(Commands.RefreshList);
	Else
		ResetGuestsInRoom();
		Items.FormAvailableRoomsAction.Enabled = False;
		IsInChangeRoomRateMode = False;
	EndIf;
EndProcedure // RoomRateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomQuotaOnChange(pItem)
	// Refresh list
	RefreshList(Commands.RefreshList);
EndProcedure // RoomQuotaOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypesFolderOnChange(pItem)
	// Refresh list
	RefreshList(Commands.RefreshList);
EndProcedure // RoomTypesFolderOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ResetIsInChangeRoomRateModeFlag()
	IsInChangeRoomRateMode = False;
EndProcedure // ResetIsInChangeRoomRateModeFlag

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckInDateOnChange(pItem)
	CheckInDateChange();
	// Reset table of guests in room
	ResetGuestsInRoom(True);
EndProcedure // CheckInDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckOutDateOnChange(pItem)
	CheckOutDateChange();
	// Reset table of guests in room
	ResetGuestsInRoom(True);
EndProcedure // CheckOutDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DurationOnChange(pItem)
	DurationChange();
	// Reset table of guests in room
	ResetGuestsInRoom(True);
EndProcedure // DurationOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckInTimeOnChange(pItem)
	CheckInTimeChange();
	// Reset table of guests in room
	ResetGuestsInRoom(True);
EndProcedure // CheckInTimeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckOutTimeOnChange(pItem)
	CheckOutTimeChange();
	// Reset table of guests in room
	ResetGuestsInRoom(True);
EndProcedure // CheckOutTimeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure NumberOfKidsOnChange(pItem)
	If NumberOfKids = 0 Then
		Items.AgeDecoration.Visible = False;
		For vInd = 1 To NumberOfKidAgeFields Do
			Try
				Items["KidAge"+String(vInd)].Visible = False;
				ThisObject["KidAge"+String(vInd)] = 0;
			Except
			EndTry;
		EndDo;
	Else
		Items.AgeDecoration.Visible = True;
		If NumberOfKids < NumberOfKidAgeFields Then
			For vInd = NumberOfKids + 1 To NumberOfKidAgeFields Do
				Try
					Items["KidAge"+String(vInd)].Visible = False;
					ThisObject["KidAge"+String(vInd)] = 0;
				Except
				EndTry;
			EndDo;
		EndIf;
		For vInd = 1 To Min(NumberOfKidAgeFields, NumberOfKids) Do
			Try
				Items["KidAge"+String(vInd)].Visible = True;
				ThisObject["KidAge"+String(vInd)] = 0;
			Except
			EndTry;
		EndDo;
	EndIf;
	// Reset table of guests in room
	ResetGuestsInRoom();
EndProcedure // NumberOfKidsOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypesListOnActivateCell(pItem)
	If IsInBuildListMode Or IsInChangeRoomRateMode Then
		Return;
	EndIf;
	DailyDetails.Clear();
	vCurItem = pItem.CurrentItem;
	If pItem.CurrentData <> Undefined Then
		If TypeOf(pItem.CurrentData.RoomType) = Type("CatalogRef.Hotels") Then
			// Reset totals
			CurAmount = "N/A";
			CurRoomType = Undefined;
			// Reset template
			AccommodationTemplate = Undefined;
			// Reset guests in room
			ClearGuestsInRoom();
			Return;
		EndIf;
	EndIf;
	If IsFromObject And pItem <> Undefined And vCurItem <> Undefined Then
		vInd = 0;
		If Left(vCurItem.Name, 28) = "RoomTypesListSumPresentation" Then
			If vCurItem.Name <> "RoomTypesListSumPresentation" Then
				vInd = Number(Right(vCurItem.Name, 1));
				If pItem.CurrentData <> Undefined Then
					CurRoomType = pItem.CurrentData.RoomType;
					RoomRate = pItem.CurrentData["RoomRate" + vInd];
					AccommodationTemplate = pItem.CurrentData["AccommodationTemplate" + vInd];
					vAmountsByGuests = pItem.CurrentData["AmountsByGuests" + vInd];
					CurAmount = pItem.CurrentData["SumPresentation" + vInd];
					
					If Items.GuestsInRoomGroup.Visible Then
						UpdateGuestsInRoom(CurRoomType, RoomRate, ClientType, AccommodationTemplate, vAmountsByGuests);
					EndIf;
					UpdateDailyDetails(CurRoomType, RoomRate);
				EndIf;
			Else
				If pItem.CurrentData <> Undefined Then
					CurRoomType = pItem.CurrentData.RoomType;
					RoomRate = pItem.CurrentData["RoomRate"];
					AccommodationTemplate = pItem.CurrentData["AccommodationTemplate"];
					vAmountsByGuests = pItem.CurrentData["AmountsByGuests"];
					CurAmount = pItem.CurrentData["SumPresentation"];
					
					If Items.GuestsInRoomGroup.Visible Then
						UpdateGuestsInRoom(CurRoomType, RoomRate, ClientType, AccommodationTemplate, vAmountsByGuests);
					EndIf;
					UpdateDailyDetails(CurRoomType, RoomRate);
				EndIf;
			EndIf;
		Else
			If pItem.CurrentData <> Undefined Then
				// Reset totals
				If CurRoomType <> pItem.CurrentData.RoomType Then
					CurRoomType = pItem.CurrentData.RoomType;
					CurAmount = "N/A";
					// Reset template
					AccommodationTemplate = Undefined;
					// Reset guests in room
					ClearGuestsInRoom();
				EndIf;
			EndIf;
			If Not ValueIsFilled(RoomRate) Then
				RoomRate = SelRoomRate;
				// Reset table of guests in room
				CurAmount = "N/A";
				ClearGuestsInRoom();
				// Reset template
				AccommodationTemplate = Undefined;
			EndIf;
		EndIf;
	Else
		If pItem.CurrentData <> Undefined And ValueIsFilled(pItem.CurrentData.RoomType) And ValueIsFilled(RoomRate) Then
			If Not Items.RoomTypesListSumPresentation.Visible Then 
				// Reset totals
				If CurRoomType <> pItem.CurrentData.RoomType Then
					CurRoomType = pItem.CurrentData.RoomType;
					CurAmount = "N/A";
					// Reset template
					AccommodationTemplate = Undefined;
					// Reset guests in room
					ClearGuestsInRoom();
				EndIf;
			Else
				// Reset totals
				If CurRoomType <> pItem.CurrentData.RoomType Then
					CurRoomType = pItem.CurrentData.RoomType;
					If vCurItem.Name = "RoomTypesListRoomType" Or 
					   vCurItem.Name = "RoomTypesListRoomsAvailableWithTentativePresentation" Then
						CurAmount = "N/A";
						// Reset template
						AccommodationTemplate = Undefined;
						// Reset guests in room
						ClearGuestsInRoom();
					EndIf;
				EndIf;
			EndIf;
		Else
			// Reset totals
			CurAmount = "N/A";
			CurRoomType = Undefined;
			// Reset template
			AccommodationTemplate = Undefined;
			// Reset guests in room
			ClearGuestsInRoom();
		EndIf;
	EndIf;
	If ValueIsFilled(RoomRate) And ValueIsFilled(CurRoomType) Then
		Items.RecalculateOffer.Enabled = True;
	Else
		Items.RecalculateOffer.Enabled = False;
	EndIf;
EndProcedure // RoomTypesListOnActivateCell

// -----------------------------------------------------------------------------
Procedure ClearGuestsInRoom()
	GuestsInRoom.Clear();
	// Hide columns with packages data
	Items.GuestsInRoomGroupRoomRevenue.Visible = False;
	Items.GuestsInRoomGroupMealsPackages.Visible = False;
	Items.GuestsInRoomGroupMedicalPackages.Visible = False;
	Items.GuestsInRoomGroupOtherPackages.Visible = False;
	Items.GuestsInRoomGroupOtherExtras.Visible = False;
EndProcedure // ClearGuestsInRoom

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowAveragePriceOnChange(pItem)
	RefreshList(Commands.RefreshList);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure // HotelClearing

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelOnChange(pItem)
	HotelOnChangeAtServer();
	RefreshList(Commands.RefreshList);
EndProcedure // HotelOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelClientOnChange(pItem)   
	If ValueIsFilled(SelClient) Then
		vClClientType = tcOnServer.cmGetAttributeByRef(SelClient, "ClientType");
		If ValueIsFilled(vClClientType) And Not ValueIsFilled(SelClientType) Then
			SelClientType = vClClientType;
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure IsForFolioSplitOnChange(pItem)
	Items.GuestsInRoomAccommodationType.ReadOnly = Not IsForFolioSplit;
	If IsForFolioSplit Then
		Items.GuestsInRoomAccommodationType.BackColor = Items.GuestsInRoomRoomRate.BackColor;
	Else
		Items.GuestsInRoomAccommodationType.BackColor = WebColors.WhiteSmoke;
	EndIf;
	// Reset table of guests in room
	ResetGuestsInRoom();
EndProcedure // IsForFolioSplitOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestsInRoomOnChange(pItem)
	CurAmount = "N/A";
	For Each vGuestsInRoomRow In GuestsInRoom Do
		vGuestsInRoomRow.Amount = 0;
		vGuestsInRoomRow.AmountStr = "N/A";
	EndDo;
	Items.RecalculateOffer.Enabled = True;
EndProcedure // GuestsInRoomOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure NumberOfAdultsOnChange(pItem)
	// Reset table of guests in room
	ResetGuestsInRoom();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomQuantityOnChange(pItem)
	// Reset table of guests in room
	ResetGuestsInRoom();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure KidAgeOnChange(pItem)
	// Reset table of guests in room
	ResetGuestsInRoom();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ClientTypeOnChange(pItem)
	// Reset table of guests in room
	ResetGuestsInRoom();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestsInRoomRoomTypeStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	
	vKidsAgeArray = New Array;
	For i = 1 To NumberOfKids Do
		vKidsAgeArray.Add(ThisObject["KidAge"+i]);
	EndDo;
	
	vRoomType = CurRoomType;
	vCurData = Items.GuestsInRoom.CurrentData;
	If vCurData <> Undefined Then
		If ValueIsFilled(vCurData.RoomType) Then
			vRoomType = vCurData.RoomType;
		EndIf;
	EndIf;
	
	// APDEX
	vKeyOperation = "Catalog.RoomTypes.Form.tcChoiceForm.OpenForm";
	APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);
	
	vParams = New Structure("Hotel, RoomType, CheckInDate, CheckOutDate, Duration, RoomRate, ClientType, RoomQuota, NumberOfAdults, NumberOfKids, AgeArray, NumberOfRatesToShow", 
	                        Hotel, vRoomType, CheckInDate, CheckOutDate, Duration, RoomRate, ClientType, RoomQuota, NumberOfAdults, NumberOfKids, vKidsAgeArray, 0);
	vFrm = OpenForm("Catalog.RoomTypes.Form.tcChoiceForm", vParams, pItem, ThisObject.UUID, , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // GuestsInRoomRoomTypeStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestsInRoomRoomTypeOnChange(pItem)
	vRoomType = Undefined;
	vCurData = Items.GuestsInRoom.CurrentData;
	If vCurData <> Undefined Then
		If ValueIsFilled(vCurData.RoomType) Then
			vRoomType = vCurData.RoomType;
		EndIf;
	EndIf;
	If ValueIsFilled(vRoomType) And vRoomType <> CurRoomType Then
		CurRoomType = vRoomType;
		// Get new accommodation template and update list accommodation types
		vRoomTypesListRows = RoomTypesList.FindRows(New Structure("RoomType", CurRoomType));
		If vRoomTypesListRows.Count() > 0 Then
			vRoomTypesListRow = vRoomTypesListRows.Get(0);
			If ValueIsFilled(vRoomTypesListRow.AccommodationTemplate) Then
				AccommodationTemplate = vRoomTypesListRow.AccommodationTemplate;
			EndIf;
		EndIf;
		// Update guests in room rows
		If ValueIsFilled(AccommodationTemplate) Then
			vAccommodationTypesList = GetAccommodationTypesListFromTemplate(AccommodationTemplate);
			For Each vGuestsInRoomRow In GuestsInRoom Do
				j = GuestsInRoom.IndexOf(vGuestsInRoomRow);
				If vGuestsInRoomRow.RoomType <> CurRoomType Then
					vGuestsInRoomRow.RoomType = CurRoomType;
				EndIf;
				If j < vAccommodationTypesList.Count() Then
					vGuestsInRoomRow.AccommodationType = vAccommodationTypesList.Get(j).Value;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
EndProcedure // GuestsInRoomRoomTypeOnChange

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure AvailableRoomsAction(pCommand)
	OpenAvailableRoomsForm();
EndProcedure // AvailableRoomsAction

// -----------------------------------------------------------------------------
&AtClient
Procedure RowSelectionAction(pCommand)
	If ValueIsFilled(RoomQuota) Then
		vIsFolder = tcOnServer.cmGetAttributeByRef(RoomQuota, "IsFolder");
		If vIsFolder Then
			vMessage = New UserMessage;
			vMessage.Field = "RoomQuota";
			vMessage.Text = NStr("en='You should choose allotment item not group to select room type!';ru='Нельзя выбирать тип номера при указанной группе квот!';de='Der Zimmertyp bei angegebener Quotengruppe darf nicht gewählt werden!'");
			vMessage.Message();
			Return;
		EndIf;
	EndIf;
	vItem = Items.RoomTypesList;
	vSelectedRow = Items.RoomTypesList.CurrentRow;
	If vItem.CurrentData <> Undefined Then
		If TypeOf(vItem.CurrentData.RoomType) = Type("CatalogRef.Hotels") Then
			Return;
		EndIf;
		If ValueIsFilled(vItem.CurrentData.Ref) Then
			If FormOwner = Undefined Then
				If vSelectedRow <> Undefined Then
					RoomType = vItem.CurrentData.Ref;
					If SelectRoomRateMode Then
						// Create new reservation
						CreateNewReservation();
					Else
						NotifyChoice(vItem.CurrentData.Ref);
					EndIf;
				EndIf;
			Else
				vFormOwner = FormOwner;
				While TypeOf(vFormOwner) <> Type("ClientApplicationForm") And vFormOwner <> Undefined Do
					vFormOwner = vFormOwner.Parent;
				EndDo;
				If vFormOwner <> Undefined Then
					If vFormOwner.FormName = "Document.Reservation.Form.tcDocumentForm" Or 
					   vFormOwner.FormName = "Document.Accommodation.Form.tcDocumentForm" Or 
					   vFormOwner.FormName = "CommonForm.tcAvailableRoomsReport" Then
						NotifyChoice(New Structure("RoomQuota, RoomType, AccommodationType, RoomRate, ClientType, CheckInDate, CheckOutDate, Duration", RoomQuota, vItem.CurrentData.Ref, Undefined, RoomRate, ClientType, CheckInDate, CheckOutDate, Duration));
					Else
						NotifyChoice(vItem.CurrentData.Ref);
					EndIf;
				Else
					NotifyChoice(vItem.CurrentData.Ref);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // RowSelectionAction

// -----------------------------------------------------------------------------
&AtClient
Procedure RefreshList(pCommand)
	// APDEX
	vKeyOperation = "Catalog.RoomTypes.Form.tcChoiceForm.Refresh";
	APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);
	
	BuildList();

	AttachIdleHandler("ResetIsInChangeRoomRateModeFlag", 0.1, True);
	AttachIdleHandler("GetDailyTotalsJobResult", 1, True);
EndProcedure // RefreshList

// -----------------------------------------------------------------------------
&AtClient
Procedure RecalculateOffer(pCommand)
	RecalculateOfferAtClient();
EndProcedure // RecalculateOffer

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtClient
Procedure RecalculateOfferAtClient()
	IsInBuildListMode = True;
	RecalculateOfferAtServer();
	AttachIdleHandler("ResetIsInBuildListMode", 0.1, True);
EndProcedure // RecalculateOfferAtClient

// -----------------------------------------------------------------------------
&AtClient
Procedure ResetIsInBuildListMode() Export
	IsInBuildListMode = False;
EndProcedure //ResetIsInBuildListMode

// -----------------------------------------------------------------------------
&AtServer
Procedure OnOpenForm()
	// Check permission to edit client type
	If Not cmCheckUserPermissions("HavePermissionToChooseClientTypeManually") Then
		Items.ClientType.Enabled = False;
	EndIf;
	// Fill choice lists
	Items.ClientType.ChoiceList.LoadValues(GetArrayOfAllClientTypes());
	Items.SelSourceOfBusiness.ChoiceList.LoadValues(GetArrayOfAllSourceOfBusiness());
	// Check that parameters are filled
	FillParametersByDefaultValues();
	ResetParameters();
	// Check permission to edit allotment
	If ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.RoomQuota) Then
		Items.RoomQuota.ClearButton = False;
		Items.RoomQuota.ChoiceButton = False;
		Items.RoomQuota.OpenButton = False;
		Items.RoomQuota.ReadOnly = True;
	EndIf;
	// Build list
	BuildList();
	// Try to position list on choice initial value
	DoInitialListPositioning();
	// Check hotel
	If Not ValueIsFilled(Hotel) Or Hotel.IsFolder Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Hotel should be choosen!';ru='Должна быть выбрана гостиница!';de='Das Hotel muss gewählt sein!'"));
		Return;
	EndIf;
EndProcedure // OnOpenForm

// -----------------------------------------------------------------------------
&AtServer
Procedure FillParametersByDefaultValues()
	If Not ValueIsFilled(SelRoomRate) Then
		If ValueIsFilled(SelHotel) Then
			SelRoomRate = SelHotel.RoomRate;
		EndIf;
	EndIf;
	If Not ValueIsFilled(SelCheckInDate) Then
		SelCheckInDate = Date(Year(CurrentSessionDate()), Month(CurrentSessionDate()), Day(CurrentSessionDate()), 
	                 Hour(CurrentSessionDate()), Minute(CurrentSessionDate()), 0);
	EndIf;
	If Not ValueIsFilled(SelCheckOutDate) Then
		vPeriodInHours = 24;
		SelDuration = 1;
		SelCheckOutDate = SelCheckInDate + SelDuration * vPeriodInHours * 3600;
	Else
		SelDuration = cmCalculateDuration(SelRoomRate, SelCheckInDate, SelCheckOutDate);
	EndIf;
	If Not ValueIsFilled(SelHotel) Then
		SelHotel = SessionParameters.CurrentHotel;
		If ValueIsFilled(SelHotel) Then
			SelDuration = SelHotel.Duration;
			SelRoomRate = SelHotel.RoomRate;
			SelCheckOutDate = cmCalculateCheckOutDate(SelRoomRate, SelCheckInDate, SelDuration);
			If SelNumberOfRatesToShow >= 0 Then
				NumberOfRatesToShowInRoomRatesSearchForm = SelNumberOfRatesToShow;
			Else
				NumberOfRatesToShowInRoomRatesSearchForm = SelHotel.NumberOfRatesToShowInRoomRatesSearchForm;
			EndIf;
		EndIf;
	EndIf;
	If Not ValueIsFilled(SelRoomQuota) Then
		If ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.RoomQuota) Then
			SelRoomQuota = SessionParameters.CurrentUser.RoomQuota;
		EndIf;
	EndIf;
EndProcedure // FillParametersByDefaultValues

// -----------------------------------------------------------------------------
&AtServer
Procedure ResetParameters()
	CheckInDate = SelCheckInDate;
	CheckInTime = SelCheckInDate;
	Duration = SelDuration;
	CheckOutDate = SelCheckOutDate;
	CheckOutTime = SelCheckOutDate;
	ClientType = SelClientType;
	RoomRate = SelRoomRate;
	Hotel = SelHotel;
	If SelNumberOfRatesToShow >= 0 Then
		NumberOfRatesToShowInRoomRatesSearchForm = SelNumberOfRatesToShow;
	Else
		If ValueIsFilled(Hotel) And Not Hotel.IsFolder Then
			NumberOfRatesToShowInRoomRatesSearchForm = Hotel.NumberOfRatesToShowInRoomRatesSearchForm;
		EndIf;
	EndIf;
	RoomType = SelRoomType;
	RoomQuota = SelRoomQuota;
	WindowView = SelWindowView;
	If Not ValueIsFilled(NumberOfAdults) Then
		NumberOfAdults = 1;
	EndIf;
EndProcedure // ResetParameters

// -----------------------------------------------------------------------------
&AtServer
Procedure DoInitialListPositioning()
	vPosRow = Undefined;
	If ValueIsFilled(SelChoiceInitialValue) Then
		For Each vRow In RoomTypesList Do
			If SelChoiceInitialValue = vRow.RoomType Then
				vPosRow = vRow.GetID();
				Break;
			EndIf;
		EndDo;
	EndIf;
	If vPosRow <> Undefined Then
		Items.RoomTypesList.CurrentRow = vPosRow;
	EndIf;
EndProcedure // DoInitialListPositioning

// -----------------------------------------------------------------------------
&AtClient
Procedure CreateNewReservation(pByGuests = False)
	vError = "";
	vWarning = "";
	If ValueIsFilled(RoomType) And Not tcOnServer.cmGetAttributeByRef(RoomType, "IsFolder") Then
		If ValueIsFilled(RoomRate) And Not tcOnServer.cmGetAttributeByRef(RoomRate, "IsFolder") Then
			vParams = GetNewReservationFormParameters(vError, vWarning);
			If Not IsBlankString(vError) Then
				tcCommonFunctionOnClientServer.TextMessage(vError);
			Else
				#IF MobileClient Then
					vFrm = OpenForm("Document.Reservation.Form.mcDocumentForm", vParams, ThisObject);
				#ELSE
					// APDEX
					vKeyOperation = "Document.Reservation.Form.tcDocumentForm.OpenForm";
					APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

					If pByGuests And GuestsInRoom.Count() > 0 Then
						// Add documents list parameter
						vDocsList = New ValueList();
						For Each vGuestsInRoomRow In GuestsInRoom Do
							If Items.GuestsInRoomBoardPlace.Visible Then
								vStructure = New Structure("AccommodationType, Amount, GuestName, GuestRef, DateOfBirth, Phone, Email, HotelProduct, LegalRepresentative, RelationType, RoomRate, ClientType, ServicePackage, DiscountType, Discount, BoardPlace", 
								                            vGuestsInRoomRow.AccommodationType, Undefined, Undefined, Undefined, Undefined, Undefined, Undefined, Undefined, Undefined, Undefined, vGuestsInRoomRow.RoomRate, vGuestsInRoomRow.ClientType, vGuestsInRoomRow.ServicePackage, vGuestsInRoomRow.DiscountType, vGuestsInRoomRow.Discount, vGuestsInRoomRow.BoardPlace);
							Else
								vStructure = New Structure("AccommodationType, Amount, GuestName, GuestRef, DateOfBirth, Phone, Email, HotelProduct, LegalRepresentative, RelationType, RoomRate, ClientType, ServicePackage, DiscountType, Discount", 
								                            vGuestsInRoomRow.AccommodationType, Undefined, Undefined, Undefined, Undefined, Undefined, Undefined, Undefined, Undefined, Undefined, vGuestsInRoomRow.RoomRate, vGuestsInRoomRow.ClientType, vGuestsInRoomRow.ServicePackage, vGuestsInRoomRow.DiscountType, vGuestsInRoomRow.Discount);
							EndIf;
							vDocsList.Add(vStructure, Format(vGuestsInRoomRow.LineNumber, "ND=6; NLZ="));
							// Override main parameters
							If GuestsInRoom.IndexOf(vGuestsInRoomRow) = 0 Then
								If ValueIsFilled(vGuestsInRoomRow.AccommodationType) Then
									vParams.Insert("AccommodationType", vGuestsInRoomRow.AccommodationType);
								EndIf;
								If vGuestsInRoomRow.ClientType <> ClientType Then
									vParams.Insert("ClientType", vGuestsInRoomRow.ClientType);
								EndIf;
								If ValueIsFilled(vGuestsInRoomRow.RoomRate) Then
									vParams.Insert("RoomRate", vGuestsInRoomRow.RoomRate);
									vParams.Insert("ServicePackage", vGuestsInRoomRow.ServicePackage);
									vParams.Insert("DiscountType", vGuestsInRoomRow.DiscountType);
									vParams.Insert("Discount", vGuestsInRoomRow.Discount);
									If Items.GuestsInRoomBoardPlace.Visible Then
										vParams.Insert("BoardPlace", vGuestsInRoomRow.BoardPlace);
									EndIf;
								EndIf;
							EndIf;
						EndDo;
						vParams.Insert("DocsList", vDocsList);
					EndIf;
					OpenForm("Document.Reservation.Form.tcDocumentForm", vParams, ThisObject);
				#ENDIF
			EndIf;
		EndIf;
	EndIf;						
	Room = Undefined;
EndProcedure // CreateNewReservation

// -----------------------------------------------------------------------------
&AtServer
Function GetNewReservationFormParameters(rError = "", rWarning = "")
	vRowStruct = GetParameters();
	// Check rights to use allotment
	If ValueIsFilled(RoomQuota) And ValueIsFilled(RoomQuota.Company) And ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Company) And 
	   RoomQuota.Company <> SessionParameters.CurrentUser.Company Then
		rError = NStr("en='You do not have rights to use " + TrimAll(RoomQuota.Company) + " company allotment!'; ru='Нет прав использовать квоту компании " + TrimAll(RoomQuota.Company) + "!'; de='Sie sind nicht berechtigt, die Zimmerquote der Firma " + TrimAll(RoomQuota.Company) + " verwenden!'");
		Return vRowStruct;
	EndIf;
	// Check conditions
	If ValueIsFilled(RoomType) And RoomType.StopSale Then
		vRemarks = "";
		If cmIsStopSalePeriod(RoomType, cm1SecondShift(CheckInDate), cm0SecondShift(CheckOutDate), vRemarks) Then
			If Not cmCheckUserPermissions("HavePermissionToIgnoreStopSaleLimitations") Then
				rError = NStr("en='You have chosen room type with stop sale flag turned on! Rechoose room type!';ru='Выбрали тип номера снятый с продажи! Перевыберите тип номера!';de='Sie haben einen Zimmertyp gewählt, der aus dem Angebot genommen wurde! Wählen Sie einen anderen Zimmertyp!'") + Chars.LF + vRemarks;
			Else
				rWarning = NStr("en='You have chosen room type with stop sale flag turned on!';ru='Выбрали тип номера снятый с продажи!';de='Sie haben einen Zimmertyp gewählt, der aus dem Angebot genommen wurde!'") + Chars.LF + vRemarks;
			EndIf;
		EndIf;
	EndIf;
	Return vRowStruct;
EndFunction // GetNewReservationFormParameters

// -----------------------------------------------------------------------------
&AtServer
Function GetParameters(pOrderBasketRow = Undefined, pAccommodationType = Undefined, pGuestGroup = Undefined)
	vRowStruct = Undefined;
	vGuestGroup = pGuestGroup;
	vCompany = Catalogs.Companies.EmptyRef();
	vCurHotel = SessionParameters.CurrentHotel;
	If ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Company) Then
		vCompany = SessionParameters.CurrentUser.Company;
	ElsIf ValueIsFilled(vCurHotel.RoomRate) And ValueIsFilled(vCurHotel.RoomRate.Company) Then
		vCompany = vCurHotel.RoomRate.Company;
	ElsIf ValueIsFilled(SelRoomType) And ValueIsFilled(SelRoomType.Company) Then
		vCompany = SelRoomType.Company;
	ElsIf ValueIsFilled(vCurHotel.Company) Then
		vCompany = vCurHotel.Company;
	EndIf;
	vCheckInDate = cm1SecondShift(CheckInDate);
	vCheckOutDate = cm0SecondShift(CheckOutDate);
	vDuration = cmCalculateDuration(RoomRate, vCheckInDate, vCheckOutDate);
	
	// Calculate number of adults, teenagers, children and infants
	vKidsAgeArray = New Array();
	Try
		For vInd = 1 To NumberOfKids Do
			vKidAge = ThisObject["KidAge"+String(vInd)];
			vKidsAgeArray.Add(vKidAge);
		EndDo;
	Except
	EndTry;
	
	// Build structure with children ages
	vChildrenAgesStruct = Undefined;
	If ValueIsFilled(RoomQuota) And ValueIsFilled(RoomQuota.Contract) Then
		vAllotmentContract = RoomQuota.Contract;
		If vAllotmentContract.TeenagersMaxAge <> 0 Or vAllotmentContract.ChildrenMaxAge <> 0 Or vAllotmentContract.InfantsMaxAge <> 0 Then
			vChildrenAgesStruct = vAllotmentContract;
		EndIf;
	EndIf;
	// Get active special offers
	If ValueIsFilled(Hotel) And (Hotel.TeenagersMaxAge <> 0 Or Hotel.ChildrenMaxAge <> 0 Or Hotel.InfantsMaxAge <> 0) Then
		If ValueIsFilled(RoomRate) Then
			vOffers = cmGetConfirmedSpecialOffersForReservation(Undefined, Hotel, RoomRate, RoomRate.RoomRateType, Undefined, ClientType, SelCustomer, ?(ValueIsFilled(SelCustomer), SelCustomer.CustomerType, Undefined), Undefined, Undefined, Undefined, Undefined, vCheckInDate, vDuration, vCheckOutDate, CurrentSessionDate(), RoomType);
			For Each vOffersRow In vOffers Do
				vOffer = vOffersRow.SpecialOffer;
				If vOffer.TeenagersMaxAge <> 0 Or vOffer.ChildrenMaxAge <> 0 Or vOffer.InfantsMaxAge <> 0 Then
					vChildrenAgesStruct = vOffer;
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	// Get accommodation template
	vGuestsQuantityStruct = cmGetGuestQuantitiesPerAgeGroups(NumberOfAdults, NumberOfKids, vKidsAgeArray, vChildrenAgesStruct, Hotel);
	vAdultsQuantity = vGuestsQuantityStruct.AdultsQuantity;
	vTeenagersQuantity = vGuestsQuantityStruct.TeenagersQuantity;
	vChildrenQuantity = vGuestsQuantityStruct.ChildrenQuantity;
	vInfantsQuantity = vGuestsQuantityStruct.InfantsQuantity;
	vAccommodationTemplate = cmGetAccommodationTemplate(RoomType, vAdultsQuantity, vTeenagersQuantity, vChildrenQuantity, vInfantsQuantity);
	vAccommodationType = Undefined;
	If IsForFolioSplit And GuestsInRoom.Count() > 0 Then
		vAccommodationType = GuestsInRoom.Get(0).AccommodationType;
	EndIf;
	
	// Build structure with reservation parameters
	vRowStruct = New Structure("Hotel, SourceOfBusiness, MarketingCode, Customer, Contract, Guest, GuestGroup, RoomQuota, RoomType, RoomQuantity, AccommodationTemplate, AccommodationType, NumberOfPersons, CheckInDate, Duration, CheckOutDate, RoomRate, ClientType, Company, Posted, DeletionMark, ServicePackage, TripPurpose, GuaranteeType, IsForFolioSplit, PriceCalculationDate, NumberOfAdults, NumberOfKids, KidsAges", 
	                           vCurHotel, SelSourceOfBusiness, SelMarketingCode, SelCustomer, SelContract, SelClient, SelGuestGroup, RoomQuota, RoomType, RoomQuantity, vAccommodationTemplate, vAccommodationType, (NumberOfAdults + NumberOfKids), vCheckInDate, vDuration, vCheckOutDate, RoomRate, ClientType, vCompany, False, False, Undefined, Undefined, Undefined, IsForFolioSplit, '00010101', NumberOfAdults, NumberOfKids, vKidsAgeArray);
	If ValueIsFilled(Room) Then
		vRowStruct.Insert("Room", Room);
	EndIf;
	
	Return vRowStruct;
EndFunction // GetParameters

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetMessageQueryBox(pRef, pCheckInDate, pCheckOutDate)
	vMsg = NStr("en = 'Sales of the selected room type are stopped for the period from %1 to %2.
                |
                |Continue?'; 
				|de = 'Der Verkauf des ausgewählten Zimmertyps wird für den Zeitraum von %1 bis %2 gestoppt.
                |
                |Fortsetzen?'; 
				|ru = 'Продажи выбранного типа номера остановлены на периоде с %1 по %2.
                |
                |Продолжить?'");
	vCurDate = CurrentSessionDate();
	For Each vItem In pRef.StopSalePeriods Do
		If vItem.StopSale Then
			If vItem.PeriodFrom < pCheckOutDate And vItem.PeriodTo > pCheckInDate Then
				vMsg = StrTemplate(vMsg, Format(vItem.PeriodFrom, "DF='dd.MM.yyyy HH.mm'"), Format(vItem.PeriodTo, "DF='dd.MM.yyyy HH.mm'"));
				Break;
			EndIf;
		EndIf;
	EndDo;
	Return vMsg;
EndFunction // GetMessageQueryBox

// -------------------------------------------------------------------------------------
&AtClient
Procedure AfterShowWarningMessage(pResult, pChoiceParams) Export 
	If pResult = DialogReturnCode.Yes Then
		NotifyChoice(pChoiceParams);	
	EndIf;
EndProcedure // AfterShowWarningMessage

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckInDateChange()
	CheckInTime = CheckInDate;
	If ValueIsFilled(CheckInDate) Then
		vReferenceHour = CheckInDate - BegOfDay(CheckInDate);
		vDefaultCheckInTime = Undefined;
		vPeriodInHours = 24;
		If ValueIsFilled(RoomRate) Then
			vPeriodInHours = ?(RoomRate.PeriodInHours = 0, vPeriodInHours, RoomRate.PeriodInHours);
			If RoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour Then
				vReferenceHour = RoomRate.ReferenceHour - BegOfDay(RoomRate.ReferenceHour);
			EndIf;
			If ValueIsFilled(RoomRate.DefaultCheckInTime) Or ValueIsFilled(RoomRate.DefaultCheckOutTime) Then
				vDefaultCheckInTime = RoomRate.DefaultCheckInTime - BegOfDay(RoomRate.DefaultCheckInTime);
			EndIf;
		EndIf;
		If BegOfDay(CheckInDate) <> BegOfDay(CurrentSessionDate()) Then
			If ValueIsFilled(vDefaultCheckInTime) Then
				CheckInDate = BegOfDay(CheckInDate) + vDefaultCheckInTime;
			Else
				CheckInDate = BegOfDay(CheckInDate) + vReferenceHour;
			EndIf;
			CheckInTime = CheckInDate;
		EndIf;
		CheckOutDate = cmCalculateCheckOutDate(RoomRate, CheckInDate, Duration);
		CheckOutTime = CheckOutDate;
	EndIf;
EndProcedure // CheckInDateChange

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckOutDateChange()
	Duration = 0;
	CheckOutTime = CheckOutDate;
	If ValueIsFilled(RoomRate) And
		ValueIsFilled(CheckInDate) And
		ValueIsFilled(CheckOutDate) Then
		Duration = cmCalculateDuration(RoomRate, CheckInDate, CheckOutDate);
	EndIf;
EndProcedure // CheckOutDateChange

// -----------------------------------------------------------------------------
&AtServer
Procedure DurationChange()
	If ValueIsFilled(CheckInDate) Then
		CheckOutDate = cmCalculateCheckOutDate(RoomRate, CheckInDate, Duration);
		CheckOutTime = CheckOutDate;
	EndIf;	
EndProcedure // DurationChange

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckInTimeChange()
	CheckInDate = BegOfDay(CheckInDate) + (CheckInTime - BegOfDay(CheckInTime));
	CheckInTime = CheckInDate;
	If ValueIsFilled(CheckInDate) Then
		CheckOutDate = cmCalculateCheckOutDate(RoomRate, CheckInDate, Duration);
		CheckOutTime = CheckOutDate;
	EndIf;	
EndProcedure // CheckInTimeChange

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckOutTimeChange()
	CheckOutDate = BegOfDay(CheckOutDate) + (CheckOutTime - BegOfDay(CheckOutTime));
	CheckOutTime = CheckOutDate;
	CheckOutDateChange();
EndProcedure // CheckOutTimeChange

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenAvailableRoomsForm()
	// Open choice form
	vCurRow = Items.RoomTypesList.CurrentData;
	If vCurRow <> Undefined Then 
		If TypeOf(vCurRow.RoomType) = Type("CatalogRef.Hotels") Then
			Return;
		EndIf;
		vNotChoiceMode = Not ((ValueIsFilled(vCurRow.RoomRate) Or ValueIsFilled(RoomRate)) And ValueIsFilled(vCurRow.RoomType));
		OpenForm("Catalog.Rooms.Form.tcChoiceForm", New Structure("DateFrom, DateTo, Hotel, RoomQuota, RoomType, Room, NumberOfBeds, NumberOfRooms, NotChoiceMode", 
		                                                           CheckInDate, CheckOutDate, Hotel, RoomQuota, vCurRow.RoomType, Undefined, 0, 1, vNotChoiceMode), 
		         ThisObject, ThisObject.UUID, , , , FormWindowOpeningMode.LockWholeInterface);
	EndIf;
EndProcedure // OpenAvailableRoomsForm

// -----------------------------------------------------------------------------
&AtServer
Procedure BuildList()
	InChangeRoomRateModeFlag = True;
	Items.RoomTypesList.CurrentItem = Items.RoomTypesListSumPresentation;

	If ShowReportInBeds Then
		Items.RoomTypesListRoomsAvailableWithTentativePresentation.Visible = False;
		Items.RoomTypesListBedsAvailableWithTentativePresentation.Visible = True;
		Items.RoomTypesListRoomsRemainsPresentation.Visible = False;
		If ValueIsFilled(RoomQuota) Then
			Items.RoomTypesListBedsRemainsPresentation.Visible = True;
		Else
			Items.RoomTypesListBedsRemainsPresentation.Visible = False;
		EndIf;
	Else
		Items.RoomTypesListRoomsAvailableWithTentativePresentation.Visible = True;
		Items.RoomTypesListBedsAvailableWithTentativePresentation.Visible = False;
		Items.RoomTypesListBedsRemainsPresentation.Visible = False;
		If ValueIsFilled(RoomQuota) Then
			Items.RoomTypesListRoomsRemainsPresentation.Visible = True;
		Else
			Items.RoomTypesListRoomsRemainsPresentation.Visible = False;
		EndIf;
	EndIf;

	// Clear guests in room
	ClearGuestsInRoom();
	AccommodationTemplate = Undefined;
	CurRoomType = Undefined;
	CurAmount = "";
	
	RefreshListToolTip = "";
	Items.RefreshListToolTip.Visible = False;
	
	// Save current position in the list
	vSelRoomType = Undefined;
	vSelRoomTypesListRow = Items.RoomTypesList.CurrentRow;
	If vSelRoomTypesListRow <> Undefined Then
		vSelRoomType = RoomTypesList.FindByID(vSelRoomTypesListRow).RoomType;
	EndIf;
	IsInBuildListMode = True;
	
	RoomTypesList.Clear();
	RoomTypesListDaily.Clear();
	
	Items.RoomTypesListSumPresentation.Visible = False;
	Items.RoomTypesListAvgPricePresentation.Visible = False;
	For i = 1 To 9 Do
		Items["RoomTypesListSumPresentation" + i].Visible = False;
		Items["RoomTypesListAvgPricePresentation" + i].Visible = False;
	EndDo;
	
	// Check periods
	If CheckInDate >= CheckOutDate Then
		CheckOutDate = CheckInDate + 86400;	
		Duration = 1;
	EndIf;
	
	// Build array of kid ages
	vAgeValueTable = New ValueTable();
	vAgeValueTable.Columns.Add("Age", cmGetNumberTypeDescription(3, 0));
	vAgeValueTable.Columns.Add("IsUsed", cmGetBooleanTypeDescription());
	vAgeArray = New Array;
	For vInd = 1 To NumberOfKids Do
		Try
			vAge = ThisObject["KidAge"+String(vInd)];
			
			vAgeRow = vAgeValueTable.Add();
			vAgeRow.Age = vAge;
			vAgeRow.IsUsed = False;
			
			vAgeArray.Add(vAge);
		Except
		EndTry;
	EndDo;
	
	// Build structure with children ages
	vChildrenAgesStruct = Undefined;
	If ValueIsFilled(RoomQuota) And ValueIsFilled(RoomQuota.Contract) Then
		vAllotmentContract = RoomQuota.Contract;
		If vAllotmentContract.TeenagersMaxAge <> 0 Or vAllotmentContract.ChildrenMaxAge <> 0 Or vAllotmentContract.InfantsMaxAge <> 0 Then
			vChildrenAgesStruct = vAllotmentContract;
		EndIf;
	EndIf;
	
	// Get available room types
	vGuestsQuantity = NumberOfAdults + NumberOfKids;
	vRoomTypes = cmGetRoomTypesByGuestQuantity(vGuestsQuantity, RoomTypesFolder, Hotel);

	// Get allowed room rates to be shown
	vRoomRatesList = New ValueList();
	If IsFromObject Then
		vCustomerRoomRatesAreUsed = False; 
		If ValueIsFilled(SelContract) And SelContract.RoomRates.Count() > 0 Then
			vRoomRatesList.LoadValues(SelContract.RoomRates.UnloadColumn("RoomRate"));
		ElsIf ValueIsFilled(SelCustomer) And SelCustomer.RoomRates.Count() > 0 Then
			vRoomRatesList.LoadValues(SelCustomer.RoomRates.UnloadColumn("RoomRate"));
		EndIf;
		r = 0;
		While r < vRoomRatesList.Count() Do
			If Not ValueIsFilled(vRoomRatesList.Get(r).Value) Then
				vRoomRatesList.Delete(r);
			Else
				r = r + 1;
			EndIf;
		EndDo;
		vRoomRatesAllowed = cmGetAllowedRoomRates(CheckInDate, CheckOutDate, CurrentSessionDate(), , Hotel);
		If vRoomRatesAllowed.Count() > 0 Then
			If vRoomRatesList.Count() > 0 Then
				vCustomerRoomRatesAreUsed = True; 
				If vRoomRatesAllowed.Count() > 0 Then
					i = 0;
					While i < vRoomRatesList.Count() Do
						vRoomRateItem = vRoomRatesList.Get(i);
						If vRoomRatesAllowed.FindByValue(vRoomRateItem.Value) = Undefined Then
							If RoomRate <> vRoomRateItem.Value Then
								vRoomRatesList.Delete(i);
								Continue;
							EndIf;
						EndIf;
						i = i + 1;
					EndDo;
				EndIf;
			Else
				vRoomRatesList.LoadValues(vRoomRatesAllowed.UnloadValues());
			EndIf;
		EndIf;
		If Not vCustomerRoomRatesAreUsed Then
			i = 0;
			While i < vRoomRatesList.Count() Do
				vRoomRateRef = vRoomRatesList.Get(i).Value;
				If RoomRate <> vRoomRateRef And 
				   Not vRoomRateRef.IsRackRate And 
				   Not vRoomRateRef.IsOnlineRate And 
				   Not vRoomRateRef.IsHiddenRateForAuthorizedClients And  
				   Not vRoomRateRef.IsRateForCRS Then
					vRoomRatesList.Delete(i);
					Continue;
				EndIf;
				i = i + 1;
			EndDo;
		EndIf;
		// Force current room rate be the first in the list
		If ValueIsFilled(RoomRate) Then
			vRoomRateItem = vRoomRatesList.FindByValue(RoomRate);
			If vRoomRateItem <> Undefined Then
				vRoomRatesList.Delete(vRoomRateItem);
			EndIf;
			vRoomRatesList.Insert(0, RoomRate);
		EndIf;
		// Leave only first room rates according to the number of room rates to show
		While NumberOfRatesToShowInRoomRatesSearchForm < vRoomRatesList.Count() Do
			vRoomRatesList.Delete(NumberOfRatesToShowInRoomRatesSearchForm);
		EndDo;
	Else
		If ValueIsFilled(RoomRate) Then
			vRoomRatesList.Add(RoomRate);
		EndIf;
	EndIf;
	
	// Submit background job to retrieve daily balances
	If ValueIsFilled(RoomRate) Then
		vTempStorageAdress = PutToTempStorage(Undefined, UUID);
		
		vProcedureParameters = new Array;
		vProcedureParameters.Add(vTempStorageAdress);
		vProcedureParameters.Add(Hotel);
		vProcedureParameters.Add(RoomQuota);
		vProcedureParameters.Add(CheckInDate);
		vProcedureParameters.Add(CheckOutDate);
		vProcedureParameters.Add(RoomRate);
		vProcedureParameters.Add(vRoomRatesList);
		vProcedureParameters.Add(ClientType);
		vProcedureParameters.Add(WindowView);
		vProcedureParameters.Add(SelCustomer);
		vProcedureParameters.Add(SelContract);
		vProcedureParameters.Add(?(ValueIsFilled(SessionParameters.CurrentUser), SessionParameters.CurrentUser.Customer, Undefined));
		vProcedureParameters.Add(NumberOfAdults);
		vProcedureParameters.Add(NumberOfKids);
		vProcedureParameters.Add(vAgeArray);
		
		vBackgroundJob = AsyncCalls.StartBackgroundJob("ProlongedOperations.FindRoomRates_BuildRoomTypesListDaily", vProcedureParameters, , "Get daily totals by room types and room rates", vTempStorageAdress);

		GetDailyTotalsJobUUID = vBackgroundJob.UUID;
		GetDailyTotalsJobAddress = vTempStorageAdress;
	EndIf;
	
	// Build and run query with room inventory balances
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ExpectedGuestGroupsTurnovers.Hotel AS Hotel,
	|	ExpectedGuestGroupsTurnovers.RoomType AS RoomType,
	|	MAX(ISNULL(ExpectedGuestGroupsTurnovers.RoomsReservedTurnover, 0)) AS PreliminaryRooms,
	|	MAX(ISNULL(ExpectedGuestGroupsTurnovers.BedsReservedTurnover, 0)) AS PreliminaryBeds
	|INTO PreliminaryTotals
	|FROM
	|	AccumulationRegister.ExpectedGuestGroups.Turnovers(
	|			&qTentativeDateTimeFrom,
	|			&qTentativeDateTimeTo,
	|			DAY,
	|			Hotel = &qHotel
	|				AND CASE
	|					WHEN RoomQuota = VALUE(Catalog.RoomQuotas.EmptyRef)
	|						THEN TRUE
	|					WHEN GuestGroup <> VALUE(Catalog.GuestGroups.EmptyRef)
	|						THEN TRUE
	|					WHEN NOT ISNULL(RoomQuota.DoWriteOff, FALSE)
	|						THEN TRUE
	|					ELSE FALSE
	|				END
	|				AND (&qRoomQuotaIsSet
	|						AND RoomQuota = &qRoomQuota
	|					OR NOT &qRoomQuotaIsSet)) AS ExpectedGuestGroupsTurnovers
	|
	|GROUP BY
	|	ExpectedGuestGroupsTurnovers.Hotel,
	|	ExpectedGuestGroupsTurnovers.RoomType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OtherHotelsPreliminaryTotals.Hotel AS Hotel,
	|	SUM(OtherHotelsPreliminaryTotals.PreliminaryRooms) AS PreliminaryRooms,
	|	SUM(OtherHotelsPreliminaryTotals.PreliminaryBeds) AS PreliminaryBeds
	|INTO OtherHotelsPreliminaryTotals
	|FROM
	|	(SELECT
	|		ExpectedGuestGroupsTurnovers.Hotel AS Hotel,
	|		ExpectedGuestGroupsTurnovers.RoomType AS RoomType,
	|		MAX(ISNULL(ExpectedGuestGroupsTurnovers.RoomsReservedTurnover, 0)) AS PreliminaryRooms,
	|		MAX(ISNULL(ExpectedGuestGroupsTurnovers.BedsReservedTurnover, 0)) AS PreliminaryBeds
	|	FROM
	|		AccumulationRegister.ExpectedGuestGroups.Turnovers(
	|				&qTentativeDateTimeFrom,
	|				&qTentativeDateTimeTo,
	|				DAY,
	|				Hotel <> &qHotel
	|					AND Hotel IN HIERARCHY (&qHotelParent)
	|					AND &qHotelParent <> UNDEFINED
	|					AND NOT Hotel.DeletionMark
	|					AND CASE
	|						WHEN RoomQuota = VALUE(Catalog.RoomQuotas.EmptyRef)
	|							THEN TRUE
	|						WHEN GuestGroup <> VALUE(Catalog.GuestGroups.EmptyRef)
	|							THEN TRUE
	|						WHEN NOT ISNULL(RoomQuota.DoWriteOff, FALSE)
	|							THEN TRUE
	|						ELSE FALSE
	|					END
	|					AND (&qRoomQuotaIsSet
	|							AND RoomQuota = &qRoomQuota
	|						OR NOT &qRoomQuotaIsSet)) AS ExpectedGuestGroupsTurnovers
	|	
	|	GROUP BY
	|		ExpectedGuestGroupsTurnovers.Hotel,
	|		ExpectedGuestGroupsTurnovers.RoomType) AS OtherHotelsPreliminaryTotals
	|
	|GROUP BY
	|	OtherHotelsPreliminaryTotals.Hotel
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BEGINOFPERIOD(RoomInventoryBalance.Period, DAY) AS Period,
	|	RoomInventoryBalance.Hotel AS Hotel,
	|	RoomInventoryBalance.RoomType AS RoomType,
	|	RoomInventoryBalance.CounterClosingBalance AS CounterClosingBalance,
	|	ISNULL(RoomInventoryBalance.RoomsVacantClosingBalance, 0) AS RoomsVacant,
	|	ISNULL(RoomInventoryBalance.BedsVacantClosingBalance, 0) AS BedsVacant,
	|	ISNULL(RoomQuotaBalances.RoomsRemains, 0) AS RoomsRemains,
	|	ISNULL(RoomQuotaBalances.BedsRemains, 0) AS BedsRemains,
	|	RoomInventoryBalance.Hotel.SortCode AS HotelSortCode,
	|	RoomInventoryBalance.RoomType.SortCode AS RoomTypeSortCode
	|INTO RoomInventoryBalanceByDays
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qDateTimeFrom, &qPeriodTo, Minute, RegisterRecordsAndPeriodBoundaries, Hotel = &qHotel) AS RoomInventoryBalance
	|		LEFT JOIN (SELECT
	|			BEGINOFPERIOD(RoomQuotaSalesBalanceAndTurnovers.Period, DAY) AS Period,
	|			RoomQuotaSalesBalanceAndTurnovers.Hotel AS Hotel,
	|			RoomQuotaSalesBalanceAndTurnovers.RoomType AS RoomType,
	|			RoomQuotaSalesBalanceAndTurnovers.CounterClosingBalance AS CounterClosingBalance,
	|			RoomQuotaSalesBalanceAndTurnovers.RoomsInQuotaClosingBalance AS RoomsInQuota,
	|			RoomQuotaSalesBalanceAndTurnovers.BedsInQuotaClosingBalance AS BedsInQuota,
	|			RoomQuotaSalesBalanceAndTurnovers.RoomsRemainsClosingBalance AS RoomsRemains,
	|			RoomQuotaSalesBalanceAndTurnovers.BedsRemainsClosingBalance AS BedsRemains
	|		FROM
	|			AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
	|					&qDateTimeFrom,
	|					&qPeriodTo,
	|					Day,
	|					RegisterRecordsAndPeriodBoundaries,
	|					Hotel = &qHotel
	|						AND &qRoomQuotaIsSet
	|						AND RoomQuota = &qRoomQuota) AS RoomQuotaSalesBalanceAndTurnovers) AS RoomQuotaBalances
	|		ON RoomInventoryBalance.Hotel = RoomQuotaBalances.Hotel
	|			AND RoomInventoryBalance.RoomType = RoomQuotaBalances.RoomType
	|			AND (BEGINOFPERIOD(RoomInventoryBalance.Period, DAY) = BEGINOFPERIOD(RoomQuotaBalances.Period, DAY))
	|WHERE
	|	RoomInventoryBalance.RoomType IN(&qRoomTypesList)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventoryBalanceByDays.Hotel AS Hotel,
	|	RoomInventoryBalanceByDays.RoomType AS RoomType,
	|	MIN(RoomInventoryBalanceByDays.RoomsVacant) AS RoomsAvailable,
	|	MIN(RoomInventoryBalanceByDays.BedsVacant) AS BedsAvailable,
	|	MIN(RoomInventoryBalanceByDays.RoomsRemains) AS RoomsRemains,
	|	MIN(RoomInventoryBalanceByDays.BedsRemains) AS BedsRemains
	|INTO RoomInventoryBalance
	|FROM
	|	RoomInventoryBalanceByDays AS RoomInventoryBalanceByDays
	|
	|GROUP BY
	|	RoomInventoryBalanceByDays.Hotel,
	|	RoomInventoryBalanceByDays.RoomType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventoryBalance.Hotel AS Hotel,
	|	RoomInventoryBalance.RoomType AS RoomType,
	|	RoomInventoryBalance.RoomsAvailable AS RoomsAvailable,
	|	RoomInventoryBalance.BedsAvailable AS BedsAvailable,
	|	RoomInventoryBalance.RoomsAvailable - ISNULL(PreliminaryTotals.PreliminaryRooms, 0) AS RoomsAvailableWithTentative,
	|	RoomInventoryBalance.BedsAvailable - ISNULL(PreliminaryTotals.PreliminaryBeds, 0) AS BedsAvailableWithTentative,
	|	RoomInventoryBalance.RoomsRemains AS RoomsRemains,
	|	RoomInventoryBalance.BedsRemains AS BedsRemains
	|INTO RoomInventoryBalanceWithTentative
	|FROM
	|	RoomInventoryBalance AS RoomInventoryBalance
	|		LEFT JOIN PreliminaryTotals AS PreliminaryTotals
	|		ON RoomInventoryBalance.Hotel = PreliminaryTotals.Hotel
	|			AND RoomInventoryBalance.RoomType = PreliminaryTotals.RoomType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OtherHotelsBalance.Hotel AS Hotel,
	|	SUM(OtherHotelsBalance.RoomsAvailable) AS RoomsAvailable,
	|	SUM(OtherHotelsBalance.BedsAvailable) AS BedsAvailable,
	|	SUM(OtherHotelsBalance.RoomsRemains) AS RoomsRemains,
	|	SUM(OtherHotelsBalance.BedsRemains) AS BedsRemains
	|INTO OtherHotelsRoomInventoryBalance
	|FROM
	|	(SELECT
	|		OtherHotelsRoomTypesBalance.Hotel AS Hotel,
	|		OtherHotelsRoomTypesBalance.RoomType AS RoomType,
	|		MIN(OtherHotelsRoomTypesBalance.RoomsVacant) AS RoomsAvailable,
	|		MIN(OtherHotelsRoomTypesBalance.BedsVacant) AS BedsAvailable,
	|		MIN(OtherHotelsRoomTypesBalance.RoomsRemains) AS RoomsRemains,
	|		MIN(OtherHotelsRoomTypesBalance.BedsRemains) AS BedsRemains
	|	FROM
	|		(SELECT
	|			BEGINOFPERIOD(RoomInventoryBalance.Period, DAY) AS Period,
	|			RoomInventoryBalance.Hotel AS Hotel,
	|			RoomInventoryBalance.RoomType AS RoomType,
	|			RoomInventoryBalance.CounterClosingBalance AS CounterClosingBalance,
	|			ISNULL(RoomInventoryBalance.RoomsVacantClosingBalance, 0) AS RoomsVacant,
	|			ISNULL(RoomInventoryBalance.BedsVacantClosingBalance, 0) AS BedsVacant,
	|			ISNULL(RoomQuotaBalances.RoomsRemains, 0) AS RoomsRemains,
	|			ISNULL(RoomQuotaBalances.BedsRemains, 0) AS BedsRemains
	|		FROM
	|			AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|					&qDateTimeFrom,
	|					&qPeriodTo,
	|					Minute,
	|					RegisterRecordsAndPeriodBoundaries,
	|					Hotel <> &qHotel
	|						AND Hotel IN HIERARCHY (&qHotelParent)
	|						AND &qHotelParent <> UNDEFINED
	|						AND NOT Hotel.DeletionMark
	|						AND NOT RoomType.DoesNotAffectRoomRevenueStatistics) AS RoomInventoryBalance
	|				LEFT JOIN (SELECT
	|					BEGINOFPERIOD(RoomQuotaSalesBalanceAndTurnovers.Period, DAY) AS Period,
	|					RoomQuotaSalesBalanceAndTurnovers.Hotel AS Hotel,
	|					RoomQuotaSalesBalanceAndTurnovers.RoomType AS RoomType,
	|					RoomQuotaSalesBalanceAndTurnovers.CounterClosingBalance AS CounterClosingBalance,
	|					RoomQuotaSalesBalanceAndTurnovers.RoomsInQuotaClosingBalance AS RoomsInQuota,
	|					RoomQuotaSalesBalanceAndTurnovers.BedsInQuotaClosingBalance AS BedsInQuota,
	|					RoomQuotaSalesBalanceAndTurnovers.RoomsRemainsClosingBalance AS RoomsRemains,
	|					RoomQuotaSalesBalanceAndTurnovers.BedsRemainsClosingBalance AS BedsRemains
	|				FROM
	|					AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
	|							&qDateTimeFrom,
	|							&qPeriodTo,
	|							Day,
	|							RegisterRecordsAndPeriodBoundaries,
	|							Hotel <> &qHotel
	|								AND Hotel IN HIERARCHY (&qHotelParent)
	|								AND &qHotelParent <> UNDEFINED
	|								AND NOT Hotel.DeletionMark
	|								AND &qRoomQuotaIsSet
	|								AND RoomQuota = &qRoomQuota
	|								AND NOT RoomType.DoesNotAffectRoomRevenueStatistics) AS RoomQuotaSalesBalanceAndTurnovers) AS RoomQuotaBalances
	|				ON RoomInventoryBalance.Hotel = RoomQuotaBalances.Hotel
	|					AND RoomInventoryBalance.RoomType = RoomQuotaBalances.RoomType
	|					AND (BEGINOFPERIOD(RoomInventoryBalance.Period, DAY) = BEGINOFPERIOD(RoomQuotaBalances.Period, DAY))) AS OtherHotelsRoomTypesBalance
	|	WHERE
	|		NOT OtherHotelsRoomTypesBalance.RoomType IN
	|					(SELECT
	|						OtherHotelsConnectedRoomTypes.Ref
	|					FROM
	|						Catalog.RoomTypes.ConnectedRoomTypes AS OtherHotelsConnectedRoomTypes
	|					WHERE
	|						OtherHotelsConnectedRoomTypes.Ref.Owner <> &qHotel
	|						AND OtherHotelsConnectedRoomTypes.Ref.Owner IN HIERARCHY (&qHotelParent)
	|						AND &qHotelParent <> UNDEFINED
	|						AND NOT OtherHotelsConnectedRoomTypes.Ref.Owner.DeletionMark
	|					GROUP BY
	|						OtherHotelsConnectedRoomTypes.Ref)
	|	
	|	GROUP BY
	|		OtherHotelsRoomTypesBalance.Hotel,
	|		OtherHotelsRoomTypesBalance.RoomType) AS OtherHotelsBalance
	|
	|GROUP BY
	|	OtherHotelsBalance.Hotel
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OtherHotelsBalance.Hotel AS Hotel,
	|	OtherHotelsBalance.RoomsAvailable AS RoomsAvailable,
	|	OtherHotelsBalance.BedsAvailable AS BedsAvailable,
	|	OtherHotelsBalance.RoomsAvailable - ISNULL(OtherHotelsPreliminaryTotals.PreliminaryRooms, 0) AS RoomsAvailableWithTentative,
	|	OtherHotelsBalance.BedsAvailable - ISNULL(OtherHotelsPreliminaryTotals.PreliminaryBeds, 0) AS BedsAvailableWithTentative,
	|	OtherHotelsBalance.RoomsRemains AS RoomsRemains,
	|	OtherHotelsBalance.BedsRemains AS BedsRemains
	|INTO OtherHotelsBalanceWithTentative
	|FROM
	|	OtherHotelsRoomInventoryBalance AS OtherHotelsBalance
	|		LEFT JOIN OtherHotelsPreliminaryTotals AS OtherHotelsPreliminaryTotals
	|		ON OtherHotelsBalance.Hotel = OtherHotelsPreliminaryTotals.Hotel
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventory.RoomType AS RoomType,
	|	RoomInventory.RoomType AS Ref,
	|	SUM(RoomInventory.RoomsAvailable) AS RoomsAvailable,
	|	SUM(RoomInventory.BedsAvailable) AS BedsAvailable,
	|	SUM(RoomInventory.RoomsRemains) AS RoomsRemains,
	|	SUM(RoomInventory.BedsRemains) AS BedsRemains,
	|	SUM(RoomInventory.RoomsAvailableWithTentative) AS RoomsAvailableWithTentative,
	|	SUM(RoomInventory.BedsAvailableWithTentative) AS BedsAvailableWithTentative,
	|	&qEmptyCurrency AS Currency,
	|	&qEmptyNumber AS Sum,
	|	&qEmptyString AS SumPresentation,
	|	&qEmptyNumber AS AvgPrice,
	|	&qEmptyString AS AvgPricePresentation,
	|	&qRoomRate AS RoomRate,
	|	&qEmptyCurrency AS Currency1,
	|	&qEmptyNumber AS Sum1,
	|	&qEmptyString AS SumPresentation1,
	|	&qEmptyNumber AS AvgPrice1,
	|	&qEmptyString AS AvgPricePresentation1,
	|	&qEmptyRoomRate AS RoomRate1,
	|	&qEmptyCurrency AS Currency2,
	|	&qEmptyNumber AS Sum2,
	|	&qEmptyString AS SumPresentation2,
	|	&qEmptyNumber AS AvgPrice2,
	|	&qEmptyString AS AvgPricePresentation2,
	|	&qEmptyRoomRate AS RoomRate2,
	|	&qEmptyCurrency AS Currency3,
	|	&qEmptyNumber AS Sum3,
	|	&qEmptyString AS SumPresentation3,
	|	&qEmptyNumber AS AvgPrice3,
	|	&qEmptyString AS AvgPricePresentation3,
	|	&qEmptyRoomRate AS RoomRate3,
	|	&qEmptyCurrency AS Currency4,
	|	&qEmptyNumber AS Sum4,
	|	&qEmptyString AS SumPresentation4,
	|	&qEmptyNumber AS AvgPrice4,
	|	&qEmptyString AS AvgPricePresentation4,
	|	&qEmptyRoomRate AS RoomRate4,
	|	&qEmptyCurrency AS Currency5,
	|	&qEmptyNumber AS Sum5,
	|	&qEmptyString AS SumPresentation5,
	|	&qEmptyNumber AS AvgPrice5,
	|	&qEmptyString AS AvgPricePresentation5,
	|	&qEmptyRoomRate AS RoomRate5,
	|	&qEmptyCurrency AS Currency6,
	|	&qEmptyNumber AS Sum6,
	|	&qEmptyString AS SumPresentation6,
	|	&qEmptyNumber AS AvgPrice6,
	|	&qEmptyString AS AvgPricePresentation6,
	|	&qEmptyRoomRate AS RoomRate6,
	|	&qEmptyCurrency AS Currency7,
	|	&qEmptyNumber AS Sum7,
	|	&qEmptyString AS SumPresentation7,
	|	&qEmptyNumber AS AvgPrice7,
	|	&qEmptyString AS AvgPricePresentation7,
	|	&qEmptyRoomRate AS RoomRate7,
	|	&qEmptyCurrency AS Currency8,
	|	&qEmptyNumber AS Sum8,
	|	&qEmptyString AS SumPresentation8,
	|	&qEmptyNumber AS AvgPrice8,
	|	&qEmptyString AS AvgPricePresentation8,
	|	&qEmptyRoomRate AS RoomRate8,
	|	&qEmptyCurrency AS Currency9,
	|	&qEmptyNumber AS Sum9,
	|	&qEmptyString AS SumPresentation9,
	|	&qEmptyNumber AS AvgPrice9,
	|	&qEmptyString AS AvgPricePresentation9,
	|	&qEmptyRoomRate AS RoomRate9,
	|	RoomInventory.IsVirtual AS IsVirtual,
	|	&qEmptyString AS RoomsAvailableWithTentativePresentation,
	|	&qEmptyString AS BedsAvailableWithTentativePresentation,
	|	&qEmptyString AS RoomsRemainsPresentation,
	|	&qEmptyString AS BedsRemainsPresentation,
	|	CASE
	|		WHEN StopSales.StopSale IS NULL
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS StopSale,
	|	&qEmptyAccommodationTemplate AS AccommodationTemplate,
	|	&qEmptyAccommodationTemplate AS AccommodationTemplate1,
	|	&qEmptyAccommodationTemplate AS AccommodationTemplate2,
	|	&qEmptyAccommodationTemplate AS AccommodationTemplate3,
	|	&qEmptyAccommodationTemplate AS AccommodationTemplate4,
	|	&qEmptyAccommodationTemplate AS AccommodationTemplate5,
	|	&qEmptyAccommodationTemplate AS AccommodationTemplate6,
	|	&qEmptyAccommodationTemplate AS AccommodationTemplate7,
	|	&qEmptyAccommodationTemplate AS AccommodationTemplate8,
	|	&qEmptyAccommodationTemplate AS AccommodationTemplate9,
	|	CASE
	|		WHEN RoomInventory.RoomType REFS Catalog.Hotels
	|			THEN 1
	|		ELSE 0
	|	END AS Priority,
	|	RoomInventory.RoomType.SortCode AS SortCode
	|FROM
	|	(SELECT
	|		RoomInventoryBalanceWithTentative.Hotel AS Hotel,
	|		RoomInventoryBalanceWithTentative.RoomType AS RoomType,
	|		RoomInventoryBalanceWithTentative.RoomType.IsVirtual AS IsVirtual,
	|		RoomInventoryBalanceWithTentative.RoomsAvailable AS RoomsAvailable,
	|		RoomInventoryBalanceWithTentative.BedsAvailable AS BedsAvailable,
	|		RoomInventoryBalanceWithTentative.RoomsAvailableWithTentative AS RoomsAvailableWithTentative,
	|		RoomInventoryBalanceWithTentative.BedsAvailableWithTentative AS BedsAvailableWithTentative,
	|		RoomInventoryBalanceWithTentative.RoomsRemains AS RoomsRemains,
	|		RoomInventoryBalanceWithTentative.BedsRemains AS BedsRemains
	|	FROM
	|		RoomInventoryBalanceWithTentative AS RoomInventoryBalanceWithTentative
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RoomInventoryBalanceWithTentative.Hotel,
	|		ChildRoomTypes.Ref,
	|		ChildRoomTypes.Ref.IsVirtual,
	|		RoomInventoryBalanceWithTentative.RoomsAvailable,
	|		RoomInventoryBalanceWithTentative.BedsAvailable,
	|		RoomInventoryBalanceWithTentative.RoomsAvailableWithTentative,
	|		RoomInventoryBalanceWithTentative.BedsAvailableWithTentative,
	|		RoomInventoryBalanceWithTentative.RoomsRemains,
	|		RoomInventoryBalanceWithTentative.BedsRemains
	|	FROM
	|		RoomInventoryBalanceWithTentative AS RoomInventoryBalanceWithTentative
	|			INNER JOIN Catalog.RoomTypes AS ChildRoomTypes
	|			ON (ChildRoomTypes.BaseRoomType = RoomInventoryBalanceWithTentative.RoomType)
	|				AND (NOT ChildRoomTypes.DeletionMark)
	|				AND (NOT ChildRoomTypes.IsFolder)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		VirtualRoomTypes.Owner,
	|		VirtualRoomTypes.Ref,
	|		TRUE,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0
	|	FROM
	|		Catalog.RoomTypes AS VirtualRoomTypes
	|	WHERE
	|		VirtualRoomTypes.IsVirtual
	|		AND NOT VirtualRoomTypes.IsFolder
	|		AND VirtualRoomTypes.Owner = &qHotel
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		OtherHotelsBalanceWithTentative.Hotel,
	|		OtherHotelsBalanceWithTentative.Hotel,
	|		FALSE,
	|		OtherHotelsBalanceWithTentative.RoomsAvailable,
	|		OtherHotelsBalanceWithTentative.BedsAvailable,
	|		OtherHotelsBalanceWithTentative.RoomsAvailableWithTentative,
	|		OtherHotelsBalanceWithTentative.BedsAvailableWithTentative,
	|		OtherHotelsBalanceWithTentative.RoomsRemains,
	|		OtherHotelsBalanceWithTentative.BedsRemains
	|	FROM
	|		OtherHotelsBalanceWithTentative AS OtherHotelsBalanceWithTentative) AS RoomInventory
	|		LEFT JOIN (SELECT
	|			RoomTypesStopSalePeriods.Ref AS StopSale
	|		FROM
	|			Catalog.RoomTypes.StopSalePeriods AS RoomTypesStopSalePeriods
	|		WHERE
	|			RoomTypesStopSalePeriods.StopSale
	|			AND RoomTypesStopSalePeriods.PeriodFrom < &qDateTimeTo
	|			AND RoomTypesStopSalePeriods.PeriodTo > &qDateTimeFrom
	|			AND NOT RoomTypesStopSalePeriods.Ref.DeletionMark
	|			AND NOT RoomTypesStopSalePeriods.Ref.IsFolder
	|		
	|		GROUP BY
	|			RoomTypesStopSalePeriods.Ref) AS StopSales
	|		ON RoomInventory.RoomType = StopSales.StopSale
	|WHERE
	|	NOT RoomInventory.RoomType.DeletionMark
	|	AND (NOT &qWindowViewIsFilled
	|			OR &qWindowViewIsFilled
	|				AND ISNULL(RoomInventory.RoomType.WindowView, VALUE(Catalog.RoomProperties.EmptyRef)) = &qWindowView)
	|	AND CASE
	|			WHEN &qCUCustomer <> VALUE(Catalog.Customers.EmptyRef)
	|				THEN RoomInventory.RoomsAvailable <> 0
	|						AND RoomInventory.BedsAvailable <> 0
	|			ELSE TRUE
	|		END
	|
	|GROUP BY
	|	RoomInventory.RoomType,
	|	RoomInventory.IsVirtual,
	|	CASE
	|		WHEN StopSales.StopSale IS NULL
	|			THEN FALSE
	|		ELSE TRUE
	|	END,
	|	CASE
	|		WHEN RoomInventory.RoomType REFS Catalog.Hotels
	|			THEN 1
	|		ELSE 0
	|	END,
	|	RoomInventory.RoomType,
	|	RoomInventory.RoomType.SortCode
	|
	|ORDER BY
	|	Priority,
	|	SortCode"; 
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelParent", ?(ValueIsFilled(Hotel) And ValueIsFilled(Hotel.Parent) And SelectRoomRateMode And IsInRole("RightsToChooseHotel"), Hotel.Parent, Undefined));
	vQry.SetParameter("qRoomQuota", RoomQuota);
	vQry.SetParameter("qRoomQuotaIsSet", ValueIsFilled(RoomQuota));
	vQry.SetParameter("qDateTimeFrom", cm1SecondShift(CheckInDate));
	vQry.SetParameter("qDateTimeTo", cm0SecondShift(CheckOutDate));
	vQry.SetParameter("qPeriodTo", New Boundary(cm0SecondShift(CheckOutDate), BoundaryType.Excluding));
	vQry.SetParameter("qTentativeDateTimeFrom", BegOfDay(CheckInDate));
	vQry.SetParameter("qTentativeDateTimeTo", EndOfDay(CheckOutDate) - 24*3600);
	vQry.SetParameter("qRoomTypesList", vRoomTypes.UnloadColumn("RoomType"));
	vQry.SetParameter("qEmptyNumber", 0);
	vQry.SetParameter("qEmptyString", "");
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qEmptyCurrency", Catalogs.Currencies.EmptyRef());
	vQry.SetParameter("qRoomRate", RoomRate);
	vQry.SetParameter("qEmptyRoomRate", Catalogs.RoomRates.EmptyRef());
	vQry.SetParameter("qEmptyAccommodationTemplate", Catalogs.AccommodationTemplates.EmptyRef());
	vQry.SetParameter("qWindowViewIsFilled", ValueIsFilled(WindowView));
	vQry.SetParameter("qWindowView", WindowView);
	vQry.SetParameter("qCUCustomer", SessionParameters.CurrentUser.Customer);
	vRoomTypes = vQry.Execute().Unload();
	
	vRoomTypes.Columns.Add("AmountsByGuests");
	vRoomTypes.Columns.Add("AmountsByGuests1");
	vRoomTypes.Columns.Add("AmountsByGuests2");
	vRoomTypes.Columns.Add("AmountsByGuests3");
	vRoomTypes.Columns.Add("AmountsByGuests4");
	vRoomTypes.Columns.Add("AmountsByGuests5");
	vRoomTypes.Columns.Add("AmountsByGuests6");
	vRoomTypes.Columns.Add("AmountsByGuests7");
	vRoomTypes.Columns.Add("AmountsByGuests8");
	vRoomTypes.Columns.Add("AmountsByGuests9");
	
	ValueToFormAttribute(vRoomTypes, "RoomTypesList");
	
	For Each vItem In RoomTypesList Do
		vItem.RoomsAvailableWithTentativePresentation = Format(vItem.RoomsAvailable, "NFD=0; NZ=; NG=") + ?(vItem.RoomsAvailable <> vItem.RoomsAvailableWithTentative, " / " + Format(vItem.RoomsAvailableWithTentative, "NFD=0; NZ=; NG="), "");	
		vItem.BedsAvailableWithTentativePresentation = Format(vItem.BedsAvailable, "NFD=0; NZ=; NG=") + ?(vItem.BedsAvailable <> vItem.BedsAvailableWithTentative, " / " + Format(vItem.BedsAvailableWithTentative, "NFD=0; NZ=; NG="), "");
		vItem.RoomsRemainsPresentation = Format(vItem.RoomsRemains, "NFD=0; NZ=; NG=");	
		vItem.BedsRemainsPresentation = Format(vItem.BedsRemains, "NFD=0; NZ=; NG=");	
	EndDo;
	
	// Fill totals
	vRoomsAvailableTotal = 0;
	vBedsAvailableTotal = 0;
	vRoomsAvailableWithTentativeTotal = 0;
	vBedsAvailableWithTentativeTotal = 0;
	vRoomsRemainsTotal = 0;
	vBedsRemainsTotal = 0;
	For Each vRoomTypesRow In vRoomTypes Do
		vRoomType = vRoomTypesRow.RoomType;
		If TypeOf(vRoomType) = Type("CatalogRef.RoomTypes") Then
			If ValueIsFilled(vRoomType) And Not vRoomType.IsFolder And Not vRoomType.IsVirtual And Not vRoomType.DoesNotAffectRoomRevenueStatistics And Not ValueIsFilled(vRoomType.BaseRoomType) Then
				vRoomsAvailableTotal = vRoomsAvailableTotal + vRoomTypesRow.RoomsAvailable;
				vBedsAvailableTotal = vBedsAvailableTotal + vRoomTypesRow.BedsAvailable;
				vRoomsAvailableWithTentativeTotal = vRoomsAvailableWithTentativeTotal + vRoomTypesRow.RoomsAvailableWithTentative;
				vBedsAvailableWithTentativeTotal = vBedsAvailableWithTentativeTotal + vRoomTypesRow.BedsAvailableWithTentative;
				vRoomsRemainsTotal = vRoomsRemainsTotal + vRoomTypesRow.RoomsRemains;
				vBedsRemainsTotal = vBedsRemainsTotal + vRoomTypesRow.BedsRemains;
			EndIf;
		EndIf;
	EndDo;
	Items.RoomTypesListRoomsAvailableWithTentativePresentation.FooterText = Format(vRoomsAvailableTotal, "NFD=0; NZ=; NG=") + ?(vRoomsAvailableTotal <> vRoomsAvailableWithTentativeTotal, " / " + Format(vRoomsAvailableWithTentativeTotal, "NFD=0; NZ=; NG="), "");
	Items.RoomTypesListBedsAvailableWithTentativePresentation.FooterText = Format(vBedsAvailableTotal, "NFD=0; NZ=; NG=") + ?(vBedsAvailableTotal <> vBedsAvailableWithTentativeTotal, " / " + Format(vBedsAvailableWithTentativeTotal, "NFD=0; NZ=; NG="), "");
	Items.RoomTypesListRoomsRemainsPresentation.FooterText = Format(vRoomsRemainsTotal, "NFD=0; NZ=; NG=");
	Items.RoomTypesListBedsRemainsPresentation.FooterText = Format(vBedsRemainsTotal, "NFD=0; NZ=; NG=");
	
	// Get default customer
	vCustomer = Undefined;
	vCurUser = SessionParameters.CurrentUser;
	If ValueIsFilled(vCurUser.Customer) Then
		vCustomer = vCurUser.Customer;
	EndIf;

	// Build list of room rates to show
	If IsFromObject Then
		If ValueIsFilled(RoomRate) Then
			// Process room rates with price cache filled only 
			If cmRoomRatePricesCacheIsFilled(Hotel, vRoomRatesList, ClientType, CheckInDate, CheckOutDate) Then
				// Get accommodation templates suitable for each room rate / room type
				vAccTemplates = cmGetAccommodationTemplateDetailsByGuestsQuantity(NumberOfAdults, NumberOfKids, vAgeArray, Hotel, Not IsForFolioSplit, vChildrenAgesStruct);
				vAccTemplatesList = New ValueList();
				If Not IsForFolioSplit Then
					vAccTemplatesList.LoadValues(vAccTemplates.UnloadColumn("AccommodationTemplate"));
				Else
					// Try to search folio split templates
					For Each vAccTemplatesRow In vAccTemplates Do
						If ValueIsFilled(vAccTemplatesRow.AccommodationTemplate) And vAccTemplatesRow.AccommodationTemplate.IsForFolioSplit Then
							vAccTemplatesList.Add(vAccTemplatesRow.AccommodationTemplate);
						EndIf;
					EndDo;
					// If nothing special was found then use normal templates
					If vAccTemplatesList.Count() = 0 Then
						vAccTemplatesList.LoadValues(vAccTemplates.UnloadColumn("AccommodationTemplate"));
					EndIf;
				EndIf;
				
				// Get prices for each suitable template
				vPrices = cmGetCachedPricesForPriceTags(Hotel, ClientType, BegOfDay(CheckInDate), BegOfDay(CheckOutDate), vRoomRatesList, , vAccTemplatesList);
				
				// Process room rates
				i = 0;
				vRatesCount = vRoomRatesList.Count();
				While i < vRatesCount Do
					vRoomRate = vRoomRatesList.Get(i).Value;
					vRoomRatePresentation = TrimAll(vRoomRate);
				
					// Check room rate is valid period
					If ValueIsFilled(vRoomRate.DateValidFrom) Or ValueIsFilled(vRoomRate.DateValidTo) Then
						If ValueIsFilled(vRoomRate.DateValidFrom) And CheckInDate < vRoomRate.DateValidFrom Then
							i = i + 1;
							Continue;
						EndIf;
						If ValueIsFilled(vRoomRate.DateValidTo) And CheckOutDate > EndOfDay(vRoomRate.DateValidTo) Then
							i = i + 1;
							Continue;
						EndIf;
					EndIf;
					
					vCurAccommodationTemplate = Undefined;
				
					For Each vRoomTypesRow In RoomTypesList Do
						vCurRoomType = vRoomTypesRow.RoomType;
						
						// Get prices for current room rate, room type
						j = 0;
						vGoToOutput = False;
						
						// Get prices for current room rate and room type
						vRoomRateRoomTypePrices = vPrices.FindRows(New Structure("RoomRate, RoomType", vRoomRate, vCurRoomType));
						If vRoomRateRoomTypePrices <> Undefined And vRoomRateRoomTypePrices.Count() > 0 Then
							vAgeValueTable.FillValues(False, "IsUsed");
							
							vCurAccommodationTemplate = Undefined;
							vCurrency = Catalogs.Currencies.EmptyRef();
							vSum = 0;
							vAmountsByGuests = New ValueList();
							
							For Each vRoomRateRoomTypePricesRow In vRoomRateRoomTypePrices Do
								j = j + 1;
								vWrkAccommodationTemplate = vRoomRateRoomTypePricesRow.AccommodationTemplate;
								If ValueIsFilled(vWrkAccommodationTemplate) Then
									If vWrkAccommodationTemplate.RoomTypes.Count() <> 0 And vWrkAccommodationTemplate.RoomTypes.Find(vCurRoomType, "RoomType") = Undefined Then
										vDoContinue = True;
										If ValueIsFilled(vCurRoomType) And Not vCurRoomType.IsFolder And ValueIsFilled(vCurRoomType.RoomClass) And vWrkAccommodationTemplate.RoomTypes.Find(vCurRoomType.RoomClass, "RoomClass") <> Undefined Then
											vDoContinue = False;
										EndIf;
										If vDoContinue Then
											Continue;
										EndIf;
									EndIf;
								EndIf;
								If ValueIsFilled(vCurAccommodationTemplate) And vCurAccommodationTemplate <> vRoomRateRoomTypePricesRow.AccommodationTemplate Then
									vGoToOutput = True;
								EndIf;
								If Not vGoToOutput Then
									vCurAccommodationTemplate = vRoomRateRoomTypePricesRow.AccommodationTemplate;
									vCurAccommodationType = vRoomRateRoomTypePricesRow.AccommodationType;
									
									For Each vAgeRow In vAgeValueTable Do
										If Not vAgeRow.IsUsed And vAgeRow.Age > vCurAccommodationType.AllowedClientAgeFrom And vAgeRow.Age < vCurAccommodationType.AllowedClientAgeTo Then
											vAgeRow.IsUsed = True;
											Break;
										EndIf;
									EndDo;
									
									If Not ValueIsFilled(vCurrency) Then
										vCurrency = vRoomRateRoomTypePricesRow.Currency;
									EndIf;
									vSum = vSum + vRoomRateRoomTypePricesRow.Amount;
									
									vAmountsByGuests.Add(New Structure("AccommodationType, Amount, Currency, AmountStr", vCurAccommodationType, vRoomRateRoomTypePricesRow.Amount, vRoomRateRoomTypePricesRow.Currency, cmFormatSum(vRoomRateRoomTypePricesRow.Amount, vRoomRateRoomTypePricesRow.Currency))); 
								EndIf;
							EndDo; // By prices
							
							If vGoToOutput Or j = vRoomRateRoomTypePrices.Count() Or j < vRoomRateRoomTypePrices.Count() And vRoomRateRoomTypePrices.Get(j).AccommodationTemplate <> vCurAccommodationTemplate Then 
								vSum = vSum * RoomQuantity;
								
								If i = 0  Then
									Items["RoomTypesListSumPresentation"].TextColor = StyleColors.FormTextColor;
									vRoomTypesRow.Currency = vCurrency;
									vRoomTypesRow.Sum = vSum;
									vRoomTypesRow.SumPresentation = cmFormatSum(vSum, vCurrency);
									vRoomTypesRow.AvgPrice = ?(Duration <> 0, Round(vSum/Duration, 2), 0);
									vRoomTypesRow.AvgPricePresentation = cmFormatSum(vRoomTypesRow.AvgPrice, vCurrency);
									vRoomTypesRow.AccommodationTemplate = vCurAccommodationTemplate;
									vRoomTypesRow.AmountsByGuests = vAmountsByGuests;
									Items.RoomTypesListSumPresentation.Title = vRoomRatePresentation;
									Items.RoomTypesListSumPresentation.Visible = True;
									If ShowAveragePrice Then
										Items.RoomTypesListAvgPricePresentation.Visible = True;
									EndIf;
								Else
									Items["RoomTypesListSumPresentation" + i].TextColor = StyleColors.FormTextColor;
									vRoomTypesRow["RoomRate" + i] = vRoomRate;
									vRoomTypesRow["Currency" + i] = vCurrency;
									vRoomTypesRow["Sum" + i] = vSum;
									vRoomTypesRow["SumPresentation" + i] = cmFormatSum(vSum, vCurrency);
									vRoomTypesRow["AvgPrice" + i] = ?(Duration <> 0, Round(vSum/Duration, 2), 0);
									vRoomTypesRow["AvgPricePresentation" + i] = cmFormatSum(vRoomTypesRow["AvgPrice" + i], vCurrency);
									vRoomTypesRow["AccommodationTemplate" + i] = vCurAccommodationTemplate;
									vRoomTypesRow["AmountsByGuests" + i] = vAmountsByGuests;
									Items["RoomTypesListSumPresentation" + i].Title = vRoomRatePresentation;
									Items["RoomTypesListSumPresentation" + i].Visible = True;
									If ShowAveragePrice Then
										Items["RoomTypesListAvgPricePresentation" + i].Visible = True;
									EndIf;
								EndIf;
								
								vSum = 0;
								vCurrency = Undefined;
							EndIf;
						EndIf; // Room rate/Room type prices found
					EndDo; // By room types
					i = i + 1;
				EndDo; // By room rates	
			EndIf; // Prices cache is filled
		EndIf; // Room rate is filled 
	EndIf; // Is from object

	If Items.RoomTypesListRoomsAvailableWithTentativePresentation.Visible Then
		Items.RoomTypesListRoomsAvailableWithTentativePresentation.TextColor = StyleColors.FormTextColor;
	EndIf;
	If Items.RoomTypesListBedsAvailableWithTentativePresentation.Visible Then
		Items.RoomTypesListBedsAvailableWithTentativePresentation.TextColor = StyleColors.FormTextColor;
	EndIf;
	If Items.RoomTypesListRoomsRemainsPresentation.Visible Then
		Items.RoomTypesListRoomsRemainsPresentation.TextColor = StyleColors.FormTextColor;
	EndIf;
	If Items.RoomTypesListBedsRemainsPresentation.Visible Then
		Items.RoomTypesListBedsRemainsPresentation.TextColor = StyleColors.FormTextColor;
	EndIf;
	
	// Restore current row
	If ValueIsFilled(vSelRoomType) Then
		vRoomTypesListRows = RoomTypesList.FindRows(New Structure("RoomType", vSelRoomType));
		If vRoomTypesListRows.Count() > 0 Then
			vRoomTypesListRow = vRoomTypesListRows.Get(0);
			Items.RoomTypesList.CurrentRow = vRoomTypesListRow.GetID();
		EndIf;
	EndIf;
	
	If NumberOfRatesToShowInRoomRatesSearchForm > 0 And ValueIsFilled(RoomRate) Then
		Items.DailyDetailsGroup.Visible = True;
	Else
		Items.DailyDetailsGroup.Visible = False;
	EndIf;

	IsInBuildListMode = False;
	NeedToRefresh = False;
EndProcedure // BuildList

// -----------------------------------------------------------------------------
&AtServer
Function GetDailyTotalsJobResultAtServer()
	RoomTypesListDaily.Clear();
	DailyDetails.Clear();
	
	If GetDailyTotalsJobUUID <> EmptyUUID Then
		vBackgroundJob = AsyncCalls.CheckBackgroundJob(GetDailyTotalsJobUUID);
		If vBackgroundJob <> Undefined Then 
			If vBackgroundJob.Status = "Processing" Then 
				Return "Processing";
			ElsIf vBackgroundJob.Status = "Completed" Then
				vJobResult = GetFromTempStorage(GetDailyTotalsJobAddress);
				If vJobResult <> Undefined And TypeOf(vJobResult) = Type("Structure") Then
					vRoomTypesDailyBalances = vJobResult.RoomTypesBalancesDaily;
					vRoomTypesDailyPrices = vJobResult.RoomTypesPricesDaily;
					
					For Each vRoomTypesDailyPricesRow In vRoomTypesDailyPrices Do
						vRoomTypesListDailyRow = RoomTypesListDaily.Add();
						vRoomTypesListDailyRow.AccountingDate = vRoomTypesDailyPricesRow.AccountingDate;
						vRoomTypesListDailyRow.RoomRate = vRoomTypesDailyPricesRow.RoomRate;
						vRoomTypesListDailyRow.RoomType = vRoomTypesDailyPricesRow.RoomType;
						vRoomTypesListDailyRow.Currency = vRoomTypesDailyPricesRow.Currency;
						vRoomTypesListDailyRow.RoomPrice = vRoomTypesDailyPricesRow.RoomPrice;
						vRoomTypesListDailyRow.RoomPriceStr = cmFormatSum(vRoomTypesListDailyRow.RoomPrice, vRoomTypesListDailyRow.Currency);
					EndDo;
						
					For Each vRoomTypesDailyBalancesRow In vRoomTypesDailyBalances Do
						vRoomTypesListDailyRows = RoomTypesListDaily.FindRows(New Structure("AccountingDate, RoomType", vRoomTypesDailyBalancesRow.AccountingDate, vRoomTypesDailyBalancesRow.RoomType));
						If vRoomTypesListDailyRows.Count() = 0 Then
							vRoomTypesListDailyRow = RoomTypesListDaily.Add();
							vRoomTypesListDailyRow.AccountingDate = vRoomTypesDailyBalancesRow.AccountingDate;
							vRoomTypesListDailyRow.RoomType = vRoomTypesDailyBalancesRow.RoomType;
							vRoomTypesListDailyRows.Add(vRoomTypesListDailyRow);
						EndIf;
						For Each vRoomTypesListDailyRow In vRoomTypesListDailyRows Do
							vRoomTypesListDailyRow.VacantRooms = vRoomTypesDailyBalancesRow.RoomsVacant;
							vRoomTypesListDailyRow.VacantBeds = vRoomTypesDailyBalancesRow.BedsVacant;
							vRoomTypesListDailyRow.TentativeRooms = vRoomTypesDailyBalancesRow.TentativeRooms;
							vRoomTypesListDailyRow.TentativeBeds = vRoomTypesDailyBalancesRow.TentativeBeds;
							vRoomTypesListDailyRow.RoomsAvailableWithTentative = vRoomTypesDailyBalancesRow.RoomsAvailableWithTentative;
							vRoomTypesListDailyRow.BedsAvailableWithTentative = vRoomTypesDailyBalancesRow.BedsAvailableWithTentative;
						EndDo;
					EndDo;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	Return "Completed";
EndFunction // GetDailyTotalsJobResultAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure GetDailyTotalsJobResult()
	vStatus = GetDailyTotalsJobResultAtServer();
	If vStatus = "Processing" Then
		AttachIdleHandler("GetDailyTotalsJobResult", 1, True);
	Else
		RoomTypesListOnActivateCell(Items.RoomTypesList);
	EndIf;
EndProcedure // GetDailyTotalsJobResult

// -----------------------------------------------------------------------------
&AtClient
Procedure RefreshFormData()
	If IsInputAvailable() Then
		RefreshList(Commands.RefreshList);
	Else
		AttachIdleHandler("RefreshFormData", 1, True);
	EndIf;
EndProcedure // RefreshFormData

// -----------------------------------------------------------------------------
&AtServer
Procedure HotelOnChangeAtServer()
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(Hotel) And Hotel.IsFolder Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(Hotel) And Not Hotel.IsFolder Then
		If SelNumberOfRatesToShow >= 0 Then
			NumberOfRatesToShowInRoomRatesSearchForm = SelNumberOfRatesToShow;
		Else
			NumberOfRatesToShowInRoomRatesSearchForm = Hotel.NumberOfRatesToShowInRoomRatesSearchForm;
		EndIf;
	EndIf;
	SelHotel = Hotel;
	// Set hotel color          
	Items.HotelGroup.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
	// Check parameters
	SelRoomQuota = Undefined;
	If ValueIsFilled(RoomQuota) And ValueIsFilled(RoomQuota.Hotel) And RoomQuota.Hotel <> Hotel Then
		RoomQuota = Undefined;
	EndIf;
	SelRoomQuota = RoomQuota;
	SelRoomRate = Undefined;
	If ValueIsFilled(RoomRate) And ValueIsFilled(Hotel) And ValueIsFilled(RoomRate.Hotel) And RoomRate.Hotel <> Hotel Then
		RoomRate = Hotel.RoomRate;
	EndIf;
	SelRoomRate = RoomRate;
	Items.GuestsInRoomBoardPlace.Visible = True;
	If ValueIsFilled(SelHotel) Then
		vBoardPlaces = cmGetBoardPlaces(SelHotel);
		If vBoardPlaces.Count() = 0 Then
			Items.GuestsInRoomBoardPlace.Visible = False;
		EndIf;
	Else
		Items.GuestsInRoomBoardPlace.Visible = False;
	EndIf;
EndProcedure // HotelOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function CalculateDuration(pRoomRate, pCheckInDate, pCheckOutDate)
	Return cmCalculateDuration(pRoomRate, pCheckInDate, pCheckOutDate);
EndFunction // CalculateDuration

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetTemplateAccommodationTypes(pRoomRate, pHotel, pAccommodationTemplate, pRoomType)
	vAccTypesList = New ValueList();
	
	// Room rate overrides
	vOverrides = cmGetRoomRateOverrides(pRoomRate, pHotel, pAccommodationTemplate, pRoomType);
	
	For Each vAccTypesRow In pAccommodationTemplate.AccommodationTypes Do
		vAccTypeRef = vAccTypesRow.AccommodationType;
		
		// Check overrides
		If vOverrides.Count() > 0 Then
			vOverrideRows = vOverrides.FindRows(New Structure("AccommodationType, TemplateLineNumber", vAccTypeRef, vAccTypesRow.LineNumber));
			If vOverrideRows.Count() > 0 And ValueIsFilled(vOverrideRows.Get(0).ToAccommodationType) Then
				vAccTypeRef = vOverrideRows.Get(0).ToAccommodationType;
			EndIf;
		EndIf;
		
		vAccTypesList.Add(vAccTypeRef);
	EndDo;
		
	Return vAccTypesList;
EndFunction // GetTemplateAccommodationTypes

// -----------------------------------------------------------------------------
&AtClient
Procedure UpdateGuestsInRoom(pRoomType, pRoomRate, pClientType, pAccommodationTemplate, pAmountsByGuests)
	If ValueIsFilled(pAccommodationTemplate) And Not NeedToRefresh Then
		// Hide columns with packages data
		Items.GuestsInRoomGroupRoomRevenue.Visible = False;
		Items.GuestsInRoomGroupMealsPackages.Visible = False;
		Items.GuestsInRoomGroupMedicalPackages.Visible = False;
		Items.GuestsInRoomGroupOtherPackages.Visible = False;
		Items.GuestsInRoomGroupOtherExtras.Visible = False;
		
		// Calculate duration for the given room rate and accommodation period	
		vDuration = CalculateDuration(pRoomRate, CheckInDate, CheckOutDate);
		
		// Add rows for each accommodation type from template
		vTemplateAccommodationTypes = GetTemplateAccommodationTypes(pRoomRate, Hotel, pAccommodationTemplate, pRoomType);
		i = 0;
		While i < vTemplateAccommodationTypes.Count() Do
			vAccTypeRef = vTemplateAccommodationTypes.Get(i).Value;

			vGuestInRoomRow = ?(i < GuestsInRoom.Count(), GuestsInRoom.Get(i), GuestsInRoom.Add());
			vGuestInRoomRow.LineNumber = i + 1;
			vGuestInRoomRow.AccommodationType = vAccTypeRef;
			vGuestInRoomRow.RoomRate = pRoomRate;
			vGuestInRoomRow.ClientType = pClientType;
			vGuestInRoomRow.ServicePackage = Undefined;
			vGuestInRoomRow.DiscountType = Undefined;
			vGuestInRoomRow.Discount = 0;
			vGuestInRoomRow.BoardPlace = Undefined;
			vGuestInRoomRow.Duration = vDuration;
			If pAmountsByGuests <> Undefined And TypeOf(pAmountsByGuests) = Type("ValueList") Then
				If i < pAmountsByGuests.Count() Then
					vAmountsByGuests = pAmountsByGuests.Get(i).Value;
					
					If TypeOf(vAmountsByGuests) = Type("Structure") Then
						If tcOnServer.cmGetAttributeByRef(pRoomRate, "RateChargeDirection") = PredefinedValue("Enum.RateChargeDirections.MergeToTheMainRoomGuest") And i > 0 Then
							vGuestInRoomRow.Amount = 0;
							vGuestInRoomRow.Currency = vAmountsByGuests.Currency;
							vGuestInRoomRow.AmountStr = "";
							
							vGuestInRoomRow = GuestsInRoom.Get(0);
							vGuestInRoomRow.Amount = vGuestInRoomRow.Amount + vAmountsByGuests.Amount;
							vGuestInRoomRow.Currency = vAmountsByGuests.Currency;
							vGuestInRoomRow.AmountStr = tcOnServer.FormatSum(vGuestInRoomRow.Amount, vAmountsByGuests.Currency);
						Else
							vGuestInRoomRow.Amount = vAmountsByGuests.Amount;
							vGuestInRoomRow.Currency = vAmountsByGuests.Currency;
							vGuestInRoomRow.AmountStr = vAmountsByGuests.AmountStr;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			i = i + 1;
		EndDo;
		While i < GuestsInRoom.Count() Do
			GuestsInRoom.Delete(i);
		EndDo;
	Else
		ClearGuestsInRoom();
	EndIf;
	If ValueIsFilled(pRoomType) And ValueIsFilled(pRoomRate) Then
		Items.RecalculateOffer.Enabled = True;
	Else
		Items.RecalculateOffer.Enabled = False;
	EndIf;
	If GuestsInRoom.Count() = 0 Then
		Items.NewReservation.Enabled = False;
	Else
		Items.NewReservation.Enabled = True;
	EndIf;
EndProcedure // UpdateDailyDetails

// -----------------------------------------------------------------------------
&AtClient
Procedure UpdateDailyDetails(pRoomType, pRoomRate)
	vDailyDetailsRow = DailyDetails.Add();
	
	vDailyDetailsRow.DateName = NStr("en='Date'; de='Datum'; ru='Дата'") + Chars.LF + NStr("en='week day'; de='Wochentag'; ru='день недели'");
	vDailyDetailsRow.RoomPriceName = NStr("en='Price'; de='Preis'; ru='Цена'");
	vDailyDetailsRow.RoomsAvailableName = NStr("en='Vacant/with tentative'; de='Frei/mit Tentative'; ru='Свободно/с предв.'");
	
	i = 0;
	vRoomTypesListDailyRows = RoomTypesListDaily.FindRows(New Structure("RoomRate, RoomType", pRoomRate, pRoomType));
	For Each vRoomTypesListDailyRow In vRoomTypesListDailyRows Do
		i = i + 1;
		If i > 31 Then
			Break;
		EndIf;
		vDailyDetailsRow["Date" + i] = vRoomTypesListDailyRow.AccountingDate;
		vDailyDetailsRow["RoomPrice" + i] = vRoomTypesListDailyRow.RoomPrice;
		vDailyDetailsRow["RoomPriceCurrency" + i] = vRoomTypesListDailyRow.Currency;
		vDailyDetailsRow["RoomPriceStr" + i] = vRoomTypesListDailyRow.RoomPriceStr;
		vDailyDetailsRow["VacantRooms" + i] = vRoomTypesListDailyRow.VacantRooms;
		vDailyDetailsRow["VacantBeds" + i] = vRoomTypesListDailyRow.VacantBeds;
		vDailyDetailsRow["PreliminaryRooms" + i] = vRoomTypesListDailyRow.TentativeRooms;
		vDailyDetailsRow["PreliminaryBeds" + i] = vRoomTypesListDailyRow.TentativeBeds;
		If vRoomTypesListDailyRow.TentativeRooms = NULL Or vRoomTypesListDailyRow.TentativeRooms = 0 Then
			vDailyDetailsRow["RoomsAvailableStr" + i] = Format(vRoomTypesListDailyRow.VacantRooms, "NFD=0; NZ=; NG=");
		Else
			If vRoomTypesListDailyRow.VacantRooms = NULL Then
				vDailyDetailsRow["RoomsAvailableStr" + i] = "";
			Else
				vDailyDetailsRow["RoomsAvailableStr" + i] = Format(vRoomTypesListDailyRow.VacantRooms, "NFD=0; NZ=; NG=") + "/" + Format(vRoomTypesListDailyRow.RoomsAvailableWithTentative, "NFD=0; NZ=; NG=");
			EndIf;
		EndIf;
		
		Items["DailyDetailsDate" + i].Visible = True;
		Items["DailyDetailsRoomPriceStr" + i].Visible = True;
		Items["DailyDetailsRoomsAvailableStr" + i].Visible = True;
	EndDo;
	While i < 31 Do
		i = i + 1;
		Items["DailyDetailsDate" + i].Visible = False;
		Items["DailyDetailsRoomPriceStr" + i].Visible = False;
		Items["DailyDetailsRoomsAvailableStr" + i].Visible = False;
	EndDo;
EndProcedure // UpdateDailyDetails

// -----------------------------------------------------------------------------
&AtServer
Procedure RecalculateOfferAtServer()
	If Not ValueIsFilled(CurRoomType) Or Not ValueIsFilled(RoomRate) Then
		Return;
	EndIf;
	
	// Hide columns with packages data
	Items.GuestsInRoomGroupRoomRevenue.Visible = False;
	Items.GuestsInRoomGroupMealsPackages.Visible = False;
	Items.GuestsInRoomGroupMedicalPackages.Visible = False;
	Items.GuestsInRoomGroupOtherPackages.Visible = False;
	Items.GuestsInRoomGroupOtherExtras.Visible = False;
	
	vHotel = CurRoomType.Owner;
	vRoomTypes = New ValueTable();
	vRoomTypes.Columns.Add("RoomType", cmGetCatalogTypeDescription("RoomTypes"));
	vRoomTypesRow = vRoomTypes.Add();
	vRoomTypesRow.RoomType = CurRoomType;

	vMealBoardTerm = ?(ValueIsFilled(SelContract), SelContract.MealBoardTerm, Undefined);
	
	// Build array of kid ages
	vAgeArray = New Array;
	For vInd = 1 To NumberOfKids Do
		Try
			vAge = ThisObject["KidAge"+String(vInd)];
			vAgeArray.Add(vAge);
		Except
		EndTry;
	EndDo;

	vAccommodationTemplate = Undefined;
	If ValueIsFilled(AccommodationTemplate) Then
		vAccommodationTemplate = AccommodationTemplate;
	EndIf;
	
	vAccommodationTypes = Undefined;
	If vAccommodationTemplate <> Undefined Then
		vAccommodationTypes = New ValueTable();
		vAccommodationTypes.Columns.Add("AccommodationType", cmGetCatalogTypeDescription("AccommodationTypes"));
		vAccommodationTypes.Columns.Add("RoomRate", cmGetCatalogTypeDescription("RoomRates"));
		vAccommodationTypes.Columns.Add("ClientType", cmGetCatalogTypeDescription("ClientTypes"));
		vAccommodationTypes.Columns.Add("ServicePackage", cmGetCatalogTypeDescription("ServicePackages"));
		vAccommodationTypes.Columns.Add("DiscountType", cmGetCatalogTypeDescription("DiscountTypes"));
		vAccommodationTypes.Columns.Add("Discount", cmGetDiscountTypeDescription());
		vAccommodationTypes.Columns.Add("BoardPlace", cmGetCatalogTypeDescription("Resources"));
		For Each vGuestsInRoomRow In GuestsInRoom Do
			vAccommodationTypesRow = vAccommodationTypes.Add();
			vAccommodationTypesRow.AccommodationType = vGuestsInRoomRow.AccommodationType;
			vAccommodationTypesRow.RoomRate = vGuestsInRoomRow.RoomRate;
			vAccommodationTypesRow.ClientType = vGuestsInRoomRow.ClientType;
			vAccommodationTypesRow.ServicePackage = vGuestsInRoomRow.ServicePackage;
			vAccommodationTypesRow.Discount = vGuestsInRoomRow.Discount;
			vAccommodationTypesRow.DiscountType = vGuestsInRoomRow.DiscountType;
			vAccommodationTypesRow.BoardPlace = vGuestsInRoomRow.BoardPlace;
		EndDo;
	EndIf;
	
	// Probe document object to calculate prices
	vProbeResObj = Documents.Reservation.CreateDocument();
	vProbeResObj.Hotel = vHotel;
	vProbeResObj.pmFillAttributesWithDefaultValues(True);
	vProbeResObj.RoomQuota = RoomQuota;
	vProbeResObj.Guest = SelClient;
	vProbeResObj.ClientType = ClientType;
	vProbeResObj.ServicePackage = vMealBoardTerm;
	
	vCurRoomTypeAccTypes = Undefined;
	
	vServicePackageAttributesCache = New ValueTable();
	vServicePackageAttributesCache.Columns.Add("ServicePackage", cmGetCatalogTypeDescription("ServicePackages"));
	vServicePackageAttributesCache.Columns.Add("Code", cmGetStringTypeDescription(5));
	vServicePackageAttributesCache.Columns.Add("Description", cmGetStringTypeDescription());
	vServicePackageAttributesCache.Columns.Add("IsMealBoardTerm", cmGetBooleanTypeDescription());
	vServicePackageAttributesCache.Columns.Add("IsMedicine", cmGetBooleanTypeDescription());
	vServicePackageAttributesCache.Columns.Add("RoomRevenueService", cmGetCatalogTypeDescription("Services"));
	
	vServicesTable = New ValueTable();
	vServicesTable.Columns.Add("AccTypeIndex", cmGetNumberTypeDescription(6, 0));
	vServicesTable.Columns.Add("AccountingDate", cmGetDateTypeDescription());
	vServicesTable.Columns.Add("Service", cmGetCatalogTypeDescription("Services"));
	vServicesTable.Columns.Add("ServicePackage", cmGetCatalogTypeDescription("ServicePackages"));
	vServicesTable.Columns.Add("IsRoomRevenue", cmGetBooleanTypeDescription());
	vServicesTable.Columns.Add("IsInPrice", cmGetBooleanTypeDescription());
	vServicesTable.Columns.Add("FolioCurrency", cmGetCatalogTypeDescription("Currencies"));
	vServicesTable.Columns.Add("Sum", cmGetSumTypeDescription());
	vServicesTable.Columns.Add("DiscountSum", cmGetSumTypeDescription());
	vServicesTable.Columns.Add("CommissionSum", cmGetSumTypeDescription());
	
	vRoomTypeBalances = cmGetRoomTypeBalancesTable(vRoomTypes, False, vHotel, CheckInDate, CheckOutDate, ClientType, SelCustomer, SelContract, Undefined, , , , CurRoomType, RoomRate, vAccommodationTypes, NumberOfAdults, NumberOfKids, vAgeArray, vProbeResObj, IsForFolioSplit, vMealBoardTerm, vAccommodationTemplate, , vServicesTable);
	If vRoomTypeBalances <> Undefined Then
		vCurRoomTypeAccTypes = vRoomTypeBalances.FindRows(New Structure("RoomType", CurRoomType));
		If vCurRoomTypeAccTypes.Count() = 0 Then
			vCurRoomTypeAccTypes = vRoomTypeBalances.FindRows(New Structure("RoomType", Catalogs.RoomTypes.EmptyRef()));
		EndIf;
	EndIf;
	
	vAmount = 0;
	vRoomRevenueAmount = 0;
	vMealsAmount = 0;
	vMedicalAmount = 0;
	vOtherAmount = 0;
	vExtrasAmount = 0;
	
	vCurrency = Catalogs.Currencies.EmptyRef();
	vRU = Catalogs.Currencies.FindByCode(643);
	
	vDuration = cmCalculateDuration(RoomRate, CheckInDate, CheckOutDate);
	
	vRoomRevenueAmounts = New ValueTable();
	vRoomRevenueAmounts.Columns.Add("AccTypeIndex", cmGetNumberTypeDescription(6, 0));
	vRoomRevenueAmounts.Columns.Add("FolioCurrency", cmGetCatalogTypeDescription("Currencies"));
	vRoomRevenueAmounts.Columns.Add("Amount", cmGetSumTypeDescription());
	
	vServicePackageTypeAmounts = New ValueTable();
	vServicePackageTypeAmounts.Columns.Add("AccTypeIndex", cmGetNumberTypeDescription(6, 0));
	vServicePackageTypeAmounts.Columns.Add("ServicePackageType", cmGetStringTypeDescription());
	vServicePackageTypeAmounts.Columns.Add("FolioCurrency", cmGetCatalogTypeDescription("Currencies"));
	vServicePackageTypeAmounts.Columns.Add("Amount", cmGetSumTypeDescription());
	
	vServicePackagesByAccTypeIndex = New ValueTable();
	vServicePackagesByAccTypeIndex.Columns.Add("AccTypeIndex", cmGetNumberTypeDescription(6, 0));
	vServicePackagesByAccTypeIndex.Columns.Add("ServicePackageType", cmGetStringTypeDescription());
	vServicePackagesByAccTypeIndex.Columns.Add("ServicePackages", cmGetStringTypeDescription());
	
	vServicePackageTypesList = New ValueList();
	vServicePackageTypesList.Add("Meals");
	vServicePackageTypesList.Add("Medical");
	vServicePackageTypesList.Add("Other");
	
	vOtherExtras = New ValueTable();
	vOtherExtras.Columns.Add("AccTypeIndex", cmGetNumberTypeDescription(6, 0));
	vOtherExtras.Columns.Add("OtherExtras", cmGetStringTypeDescription());
	
	For Each vServicesTableRow In vServicesTable Do
		vService = vServicesTableRow.Service;
		vServicePackage = vServicesTableRow.ServicePackage;
		vServicePackageAttributesCacheRow = Undefined;
		
		vServicePackageType = "";
		If ValueIsFilled(vServicePackage) Then
			vServicePackageAttributesCacheRow = vServicePackageAttributesCache.Find(vServicePackage, "ServicePackage");
			If vServicePackageAttributesCacheRow = Undefined Then
				vServicePackageAttributesCacheRow = vServicePackageAttributesCache.Add();
				vServicePackageAttributesCacheRow.ServicePackage = vServicePackage;
				vServicePackageAttributesCacheRow.Code = TrimR(vServicePackage.Code);
				vServicePackageAttributesCacheRow.Description = TrimAll(vServicePackage.Description);
				vServicePackageAttributesCacheRow.IsMealBoardTerm = vServicePackage.IsMealBoardTerm;
				vServicePackageAttributesCacheRow.IsMedicine = vServicePackage.IsMedicine;
				vServicePackageAttributesCacheRow.RoomRevenueService = vServicePackage.RoomRevenueService;
			EndIf;
			If vServicePackageAttributesCacheRow.IsMealBoardTerm And Not ValueIsFilled(vServicePackageAttributesCacheRow.RoomRevenueService) Then
				vServicePackageType = "Meals";
			ElsIf vServicePackageAttributesCacheRow.IsMedicine Then
				vServicePackageType = "Medical";
			Else
				vServicePackageType = "Other";
			EndIf;
		EndIf;
			
		If Not IsBlankString(vServicePackageType) And vServicePackageAttributesCacheRow <> Undefined Then
			vServicePackageTypeAmountsRow = Undefined;
			vServicePackageTypeAmountsRows = vServicePackageTypeAmounts.FindRows(New Structure("AccTypeIndex, ServicePackageType, FolioCurrency", vServicesTableRow.AccTypeIndex, vServicePackageType, vServicesTableRow.FolioCurrency));
			If vServicePackageTypeAmountsRows.Count() > 0 Then
				vServicePackageTypeAmountsRow = vServicePackageTypeAmountsRows.Get(0);
			Else
				vServicePackageTypeAmountsRow = vServicePackageTypeAmounts.Add();
				vServicePackageTypeAmountsRow.AccTypeIndex = vServicesTableRow.AccTypeIndex;
				vServicePackageTypeAmountsRow.ServicePackageType = vServicePackageType;
				vServicePackageTypeAmountsRow.FolioCurrency = vServicesTableRow.FolioCurrency;
			EndIf;
			If vServicePackageTypeAmountsRow <> Undefined Then
				vServicePackageTypeAmountsRow.Amount = vServicePackageTypeAmountsRow.Amount + vServicesTableRow.Sum - vServicesTableRow.DiscountSum;
			EndIf;
			
			vServicePackagesByAccTypeIndexRow = Undefined;
			vServicePackagesByAccTypeIndexRows = vServicePackagesByAccTypeIndex.FindRows(New Structure("AccTypeIndex, ServicePackageType", vServicesTableRow.AccTypeIndex, vServicePackageType));
			If vServicePackagesByAccTypeIndexRows.Count() > 0 Then
				vServicePackagesByAccTypeIndexRow = vServicePackagesByAccTypeIndexRows.Get(0);
			Else
				vServicePackagesByAccTypeIndexRow = vServicePackagesByAccTypeIndex.Add();
				vServicePackagesByAccTypeIndexRow.AccTypeIndex = vServicesTableRow.AccTypeIndex;
				vServicePackagesByAccTypeIndexRow.ServicePackageType = vServicePackageType;
			EndIf;
			If StrFind(vServicePackagesByAccTypeIndexRow.ServicePackages, vServicePackageAttributesCacheRow.Description) = 0 Then
				If Not IsBlankString(vServicePackagesByAccTypeIndexRow.ServicePackages) Then
					vServicePackagesByAccTypeIndexRow.ServicePackages = vServicePackagesByAccTypeIndexRow.ServicePackages + ", ";
				EndIf;
				vServicePackagesByAccTypeIndexRow.ServicePackages = vServicePackagesByAccTypeIndexRow.ServicePackages + vServicePackageAttributesCacheRow.Description;
			EndIf;
		EndIf;
			
		If vServicesTableRow.IsRoomRevenue And vServicesTableRow.IsInPrice Then
			vRoomRevenueAmountsRow = Undefined;
			vRoomRevenueAmountsRows = vRoomRevenueAmounts.FindRows(New Structure("AccTypeIndex, FolioCurrency", vServicesTableRow.AccTypeIndex, vServicesTableRow.FolioCurrency));
			If vRoomRevenueAmountsRows.Count() > 0 Then
				vRoomRevenueAmountsRow = vRoomRevenueAmountsRows.Get(0);
			Else
				vRoomRevenueAmountsRow = vRoomRevenueAmounts.Add();
				vRoomRevenueAmountsRow.AccTypeIndex = vServicesTableRow.AccTypeIndex;
				vRoomRevenueAmountsRow.FolioCurrency = vServicesTableRow.FolioCurrency;
			EndIf;
			If vRoomRevenueAmountsRow <> Undefined Then
				vRoomRevenueAmountsRow.Amount = vRoomRevenueAmountsRow.Amount + vServicesTableRow.Sum - vServicesTableRow.DiscountSum;
			EndIf;
		EndIf;
		
		If Not ValueIsFilled(vServicePackage) And Not (vServicesTableRow.IsRoomRevenue And vServicesTableRow.IsInPrice) Then
			vOtherExtrasRow = Undefined;
			vOtherExtrasRows = vOtherExtras.FindRows(New Structure("AccTypeIndex", vServicesTableRow.AccTypeIndex));
			If vOtherExtrasRows.Count() > 0 Then
				vOtherExtrasRow = vOtherExtrasRows.Get(0);
			Else
				vOtherExtrasRow = vOtherExtras.Add();
				vOtherExtrasRow.AccTypeIndex = vServicesTableRow.AccTypeIndex;
			EndIf;
			If vOtherExtrasRow <> Undefined Then
				If StrFind(vOtherExtrasRow.OtherExtras, TrimAll(vService)) = 0 Then
					vOtherExtrasRow.OtherExtras = vOtherExtrasRow.OtherExtras + ?(IsBlankString(vOtherExtrasRow.OtherExtras), "", ", ") + TrimAll(vService);
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
	vIndex = 0;
	If vCurRoomTypeAccTypes <> Undefined Then
		i = 0;
		While i < vCurRoomTypeAccTypes.Count() Do
			vCurRoomTypeAccTypesRow = vCurRoomTypeAccTypes.Get(i);
			If i < GuestsInRoom.Count() Then
				vGuestsInRoomRow = GuestsInRoom.Get(i);
			Else
				vGuestsInRoomRow = GuestsInRoom.Add();
				vGuestsInRoomRow.LineNumber = i + 1;
				vGuestsInRoomRow.RoomRate = RoomRate;
				vGuestsInRoomRow.ClientType = ClientType;
			EndIf;
			vGuestsInRoomRow.RoomType = vCurRoomTypeAccTypesRow.RoomType;
			vGuestsInRoomRow.AccommodationType = vCurRoomTypeAccTypesRow.AccommodationType;
			vGuestsInRoomRow.Amount = vCurRoomTypeAccTypesRow.Amount * ?(RoomQuantity <> 0, RoomQuantity, 1);
			vGuestsInRoomRow.Currency = ?(ValueIsFilled(vCurRoomTypeAccTypesRow.Currency), vCurRoomTypeAccTypesRow.Currency, vRU);
			vGuestsInRoomRow.AmountStr = cmFormatSum(vCurRoomTypeAccTypesRow.Amount * ?(RoomQuantity <> 0, RoomQuantity, 1), vGuestsInRoomRow.Currency);

			vAmount = vAmount + vCurRoomTypeAccTypesRow.Amount * ?(RoomQuantity <> 0, RoomQuantity, 1);
			vCurrency = vGuestsInRoomRow.Currency;

			vGuestsInRoomRow.Duration = vDuration;
			
			// Fill data by service package types
			For Each vServicePackageTypesListItem In vServicePackageTypesList Do
				vServicePackageType = vServicePackageTypesListItem.Value;
				
				vSPAmount = 0;
				vServicePackageTypesAmountsRows = vServicePackageTypeAmounts.FindRows(New Structure("AccTypeIndex, ServicePackageType", i, vServicePackageType));
				For Each vServicePackageTypesAmountsRow In vServicePackageTypesAmountsRows Do
					vSPAmount = vSPAmount + cmConvertCurrencies(vServicePackageTypesAmountsRow.Amount, vServicePackageTypesAmountsRow.FolioCurrency, , vCurrency, , CurrentSessionDate(), vHotel);
				EndDo;
				
				vServicePackages = "";
				vServicePackagesByAccTypeIndexRows = vServicePackagesByAccTypeIndex.FindRows(New Structure("AccTypeIndex, ServicePackageType", i, vServicePackageType));
				For Each vServicePackagesByAccTypeIndexRow In vServicePackagesByAccTypeIndexRows Do
					If Not IsBlankString(vServicePackages) Then
						vServicePackages = vServicePackages + ", ";
					EndIf;
					vServicePackages = vServicePackages + vServicePackagesByAccTypeIndexRow.ServicePackages;
				EndDo;
				
				vGuestsInRoomRow[vServicePackageType + "Packages"] = vServicePackages;
				vGuestsInRoomRow[vServicePackageType + "PackagesAmount"] = vSPAmount;
				vGuestsInRoomRow[vServicePackageType + "PackagesPrice"] = Round(vSPAmount/?(vDuration = 0, 1, vDuration), 2);
				
				If Not IsBlankString(vServicePackages) Then
					Items["GuestsInRoomGroup" + vServicePackageType + "Packages"].Visible = True;
				EndIf;
				
				If vServicePackageType = "Meals" Then
					vMealsAmount = vMealsAmount + vSPAmount;
				ElsIf vServicePackageType = "Medical" Then
					vMedicalAmount = vMedicalAmount + vSPAmount;
				Else
					vOtherAmount = vOtherAmount + vSPAmount;
				EndIf;
			EndDo;
				
			// Room revenue amount
			vRowRoomRevenueAmount = 0;
			vRoomRevenueAmountsRows = vRoomRevenueAmounts.FindRows(New Structure("AccTypeIndex", i));
			For Each vRoomRevenueAmountsRow In vRoomRevenueAmountsRows Do
				vRowRoomRevenueAmount = vRowRoomRevenueAmount + cmConvertCurrencies(vRoomRevenueAmountsRow.Amount, vRoomRevenueAmountsRow.FolioCurrency, , vCurrency, , CurrentSessionDate(), vHotel);
			EndDo;
			vGuestsInRoomRow.RoomRevenueAmount = vRowRoomRevenueAmount;
			vGuestsInRoomRow.RoomRevenuePrice = Round(vRowRoomRevenueAmount/?(vDuration = 0, 1, vDuration), 2);
			vRoomRevenueAmount = vRoomRevenueAmount + vRowRoomRevenueAmount;
			
			// Room revenue group visibility
			Items.GuestsInRoomGroupRoomRevenue.Visible = True;
			
			// Other extras
			vGuestsInRoomRow.OtherExtrasAmount = vGuestsInRoomRow.Amount - vGuestsInRoomRow.RoomRevenueAmount - vGuestsInRoomRow.MealsPackagesAmount - vGuestsInRoomRow.MedicalPackagesAmount - vGuestsInRoomRow.OtherPackagesAmount;
			If vGuestsInRoomRow.OtherExtrasAmount <> 0 Then
				vOtherExtrasRows = vOtherExtras.FindRows(New Structure("AccTypeIndex", i));
				For Each vOtherExtrasRow In vOtherExtrasRows Do
					vGuestsInRoomRow.OtherExtras = vOtherExtrasRow.OtherExtras;
					Break;
				EndDo;
			EndIf;
			vExtrasAmount = vExtrasAmount + vGuestsInRoomRow.OtherExtrasAmount;
			
			// Other extras visibility
			If vGuestsInRoomRow.OtherExtrasAmount <> 0 Then
				Items.GuestsInRoomGroupOtherExtras.Visible = True;
			EndIf;
			
			// Template
			AccommodationTemplate = vCurRoomTypeAccTypesRow.AccommodationTemplate;
			
			i = i + 1;
		EndDo;
	EndIf;

	If vCurRoomTypeAccTypes <> Undefined And vCurRoomTypeAccTypes.Count() > 0 Then
		CurAmount = cmFormatSum(vAmount, vCurrency);
		CurRoomRevenueAmount = cmFormatSum(vRoomRevenueAmount, vCurrency);
		CurMealsAmount = cmFormatSum(vMealsAmount, vCurrency);
		CurMedicalAmount = cmFormatSum(vMedicalAmount, vCurrency);
		CurOtherAmount = cmFormatSum(vOtherAmount, vCurrency);
		CurExtrasAmount = cmFormatSum(vExtrasAmount, vCurrency);
		// Enable new reservation button
		Items.NewReservation.Enabled = True;
	Else
		CurAmount = "N/A";
		CurRoomRevenueAmount = "";
		CurMealsAmount = "";
		CurMedicalAmount = "";
		CurOtherAmount = "";
		CurExtrasAmount = "";
		// Disable new reservation button
		Items.NewReservation.Enabled = False;
	EndIf;
	
	// Remove folios created by documents
	If vProbeResObj <> Undefined Then
		For Each vCRRow In vProbeResObj.ChargingRules Do
			vFolioObj = vCRRow.ChargingFolio.GetObject();
			vFolioObj.Delete();
		EndDo;
		vProbeResObj = Undefined;
	EndIf;
EndProcedure // RecalculateOfferAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ResetGuestsInRoom(pResetVacantRooms = False)
	AccommodationTemplate = Undefined;
	CurAmount = "N/A";
	If Not NeedToRefresh Then
		// Mark vacant rooms/beds as not valid
		If pResetVacantRooms Then
			Items.RefreshListToolTip.Visible = True;
			RefreshListToolTip = NStr("en='Prices and vacant rooms are not relevant. Refresh the list please'; 
			                          |ru='Цены и свободные номера не актуальны. Обновите список';
			                          |de='Preise und freie Zimmer sind nicht relevant. Aktualisieren Sie die Liste'");
			If Items.RoomTypesListRoomsAvailableWithTentativePresentation.Visible Then
				Items.RoomTypesListRoomsAvailableWithTentativePresentation.TextColor = WebColors.Gainsboro;
			EndIf;
			If Items.RoomTypesListBedsAvailableWithTentativePresentation.Visible Then
				Items.RoomTypesListBedsAvailableWithTentativePresentation.TextColor = WebColors.Gainsboro;
			EndIf;
			If Items.RoomTypesListRoomsRemainsPresentation.Visible Then
				Items.RoomTypesListRoomsRemainsPresentation.TextColor = WebColors.Gainsboro;
			EndIf;
			If Items.RoomTypesListBedsRemainsPresentation.Visible Then
				Items.RoomTypesListBedsRemainsPresentation.TextColor = WebColors.Gainsboro;
			EndIf;
		ElsIf Items.RoomTypesListSumPresentation.Visible Then
			Items.RefreshListToolTip.Visible = True;
			RefreshListToolTip = NStr("en='Prices are not relevant. Refresh the list please'; 
			                          |ru='Цены не актуальны. Обновите список';
			                          |de='Preise sind nicht relevant. Aktualisieren Sie die Liste'");
		EndIf;
		// Mark room rate prices columns as not valid
		If Items.RoomTypesListSumPresentation.Visible Then
			i = 0;
			While i < NumberOfRatesToShowInRoomRatesSearchForm Do
				If i = 0 Then
					If Items.RoomTypesListGroupAmounts.Visible Then
						Items["RoomTypesListSumPresentation"].TextColor = WebColors.Gainsboro;
					EndIf;
				Else
					If Items["RoomTypesListGroupAmounts" + i].Visible Then
						Items["RoomTypesListSumPresentation" + i].TextColor = WebColors.Gainsboro;
					Else
						Break;
					EndIf;
				EndIf;
				i = i + 1;
			EndDo;
		EndIf;
	EndIf;
	// Clear guests in room
	ClearGuestsInRoom();
	// Need to refresh
	If Items.RoomTypesListSumPresentation.Visible Then
		NeedToRefresh = True;
	EndIf;
EndProcedure // ResetGuestsInRoom

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetAccommodationTypesListFromTemplate(pAccommodationTemplate)
	vAccommodationTypesList = New ValueList();
	If ValueIsFilled(pAccommodationTemplate) Then
		For Each vAccommodationTypesRow In pAccommodationTemplate.AccommodationTypes Do
			vAccommodationTypesList.Add(vAccommodationTypesRow.AccommodationType);
		EndDo;
	EndIf;
	Return vAccommodationTypesList;
EndFunction // GetAccommodationTypesListFromTemplate

// ----------------------------------------------------------------------------
&AtServer
Function GetArrayOfAllClientTypes()
	vCTTable = cmGetAllClientTypes();
	vCTArray = vCTTable.UnloadColumn("ClientType");
	Return vCTArray;
EndFunction //  GetArrayOfAllClientTypes

// ----------------------------------------------------------------------------
&AtServer
Function GetArrayOfAllSourceOfBusiness()
	vSOBTable = cmGetAllSourcesOfBusiness();
	vSOBArray = vSOBTable.UnloadColumn("SourceOfBusiness");
	Return vSOBArray;
EndFunction //  GetListOfAllSourceOfBusiness

#EndRegion
