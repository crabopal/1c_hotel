   
#Region Variables

&AtClient
Var LastKidsNumber;

&AtClient
Var PeriodFromChangeMode;

#EndRegion   
   
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	SkipOnActivateCell = False;
	SkipOnActivateArea = False;
	LastRowIndex = 0;
	RoomQuantity = 1;
	
	// Attach mouse right button context menu
	AttachSelectionContextMenu();
	
	// Process parameters
	DoNotSaveSettings = False;
	vShowPrices = Undefined;
	If Parameters.Property("GuestGroup") And ValueIsFilled(Parameters.GuestGroup) Then
		GuestGroup = Parameters.GuestGroup;
		Hotel = GuestGroup.Owner;
		RoomQuota = GuestGroup.Allotment;
		If ValueIsFilled(RoomQuota) And ValueIsFilled(RoomQuota.PeriodFrom) And ValueIsFilled(RoomQuota.PeriodTo) Then
			DateFrom = RoomQuota.PeriodFrom;
			NumberOfDays = (BegOfDay(RoomQuota.PeriodTo) - BegOfDay(RoomQuota.PeriodFrom))/(24*3600) + 1;
		Else
			DateFrom = GuestGroup.CheckInDate;
			NumberOfDays = GuestGroup.Duration + 1;
		EndIf;
		ClientType = GuestGroup.ClientType;
		RoomRate = GuestGroup.RoomRate;
		MealBoardTerm = GuestGroup.ServicePackage;
		DiscountType = GuestGroup.DiscountType;
		vShowPrices = False;
		DoNotSaveSettings = True;
	ElsIf Parameters.Property("Allotment") And ValueIsFilled(Parameters.Allotment) Then
		RoomQuota = Parameters.Allotment;
		If ValueIsFilled(RoomQuota.Hotel) Then
			Hotel = RoomQuota.Hotel;
		EndIf;
		If ValueIsFilled(RoomQuota) And ValueIsFilled(RoomQuota.PeriodFrom) And ValueIsFilled(RoomQuota.PeriodTo) Then
			vCurrentDate = BegOfDay(CurrentSessionDate());
			If ValueIsFilled(Hotel) And ValueIsFilled(Hotel.AccountingDate) Then
				vCurrentDate = Hotel.AccountingDate;
			EndIf;
			DateFrom = Max(vCurrentDate, RoomQuota.PeriodFrom);

			NumberOfDays = (BegOfDay(RoomQuota.PeriodTo) - BegOfDay(DateFrom))/(24*3600) + 1;
			If NumberOfDays < 0 Then
				NumberOfDays = 0;
			EndIf;
		EndIf;
		ClientType = RoomQuota.ClientType;
		RoomRate = RoomQuota.RoomRate;
		vShowPrices = False;
		DoNotSaveSettings = True;
	EndIf;
	
	// Use current hotel by default
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(Hotel) Then
		ShowInBeds = Hotel.ShowReportsInBeds;
		If Not ValueIsFilled(RoomRate) Then
			RoomRate = Hotel.RoomRate;
		EndIf;
	EndIf;
	If ValueIsFilled(Hotel) And ValueIsFilled(Hotel.AccommodationType) And Hotel.AccommodationType.Type = Enums.AccomodationTypes.Beds Then
		IsForFolioSplit = True;
	EndIf;
	
	// Set hotel color          
	If Not IsInRole("RightsToChooseHotel") Then
		Items.Hotel.ReadOnly = True;
		Items.Hotel.ChoiceButton = False;
	EndIf;
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(Hotel, "BackgroundColorImportant");
	
	// Use current date by default
	If Not ValueIsFilled(DateFrom) Then
		DateFrom = CurrentSessionDate();
	EndIf;
	
	// Restore number of days to show
	If vShowPrices = Undefined Then
		vShowPrices = SystemSettingsStorage.Load("ShowPrices", "tcAvailableRoomsReport");
		If vShowPrices = Undefined Then
			vShowPrices = False;
		EndIf;
	EndIf;
	ShowPrices = vShowPrices;
	
	If NumberOfDays = 0 Then
		If ShowPrices Then
			vNumberOfDays = SystemSettingsStorage.Load("NumberOfDaysShowPrices", "tcAvailableRoomsReport");
		Else
			vNumberOfDays = SystemSettingsStorage.Load("NumberOfDays", "tcAvailableRoomsReport");
		EndIf;
		If vNumberOfDays = Undefined Then
			If ShowPrices Then
				NumberOfDays = 31;
			Else
				NumberOfDays = 62;
			EndIf;
		Else
			NumberOfDays = Number(vNumberOfDays);
		EndIf;
	EndIf;
	If NumberOfDays < 1 Or NumberOfDays > 999 Then
		If ShowPrices Then
			NumberOfDays = 31;
		Else
			NumberOfDays = 62;
		EndIf;
	EndIf;
	
	If NumberOfAdults = 0 And NumberOfKids = 0 Then
		NumberOfAdults = 1;
	EndIf;
	
	// Fill parameters from current user settings
	vCurEmployee = SessionParameters.CurrentUser;
	If ValueIsFilled(vCurEmployee) Then
		If ValueIsFilled(vCurEmployee.Customer) Then
			If ValueIsFilled(vCurEmployee.Customer.RoomRate) Then
				RoomRate = vCurEmployee.Customer.RoomRate;
			Else
				If ValueIsFilled(vCurEmployee.Customer.Contract) Then
					If ValueIsFilled(vCurEmployee.Customer.Contract.RoomRate) Then
						RoomRate = vCurEmployee.Customer.Contract.RoomRate;
					EndIf;
				EndIf;
			EndIf;
			If ValueIsFilled(vCurEmployee.Customer.ClientType) Then
				ClientType = vCurEmployee.Customer.ClientType;
			Else
				If ValueIsFilled(vCurEmployee.Customer.Contract) Then
					If ValueIsFilled(vCurEmployee.Customer.Contract.ClientType) Then
						ClientType = vCurEmployee.Customer.Contract.ClientType;
					EndIf;
				EndIf;
			EndIf;
			Items.RoomQuota.ReadOnly = True;
			Items.RoomQuota.ClearButton = False;
			Items.RoomQuota.ChoiceButton = False;
			Items.RoomQuota.OpenButton = False;
		EndIf;
		If ValueIsFilled(vCurEmployee.RoomQuota) Then
			RoomQuota = SessionParameters.CurrentUser.RoomQuota;
			Items.RoomQuota.ReadOnly = True;
			Items.RoomQuota.ClearButton = False;
			Items.RoomQuota.ChoiceButton = False;
			Items.RoomQuota.OpenButton = False;
			If ValueIsFilled(RoomQuota.RoomRate) Then
				RoomRate = RoomQuota.RoomRate;
				Items.RoomRate.ReadOnly = True;
				Items.RoomRate.ClearButton = False;
				Items.RoomRate.ChoiceButton = False;
				Items.RoomRate.OpenButton = False;
			EndIf;
		EndIf;
	EndIf;
	SelectionTopRow = 0;
	
	// Meal board terms
	vTerms = cmGetAllMealBoardTerms(Hotel);
	If vTerms.Count() > 0 Then
		Items.MealBoardTerm.Visible = True;
	Else
		Items.MealBoardTerm.Visible = False;
	EndIf;
	
	// Beds setup availability
	Items.SelBedsSetup.Visible = GetBedsSetupFunctionalOption();
	
	// Build report spreadsheet
	BuildReport();
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	LastKidsNumber = 0;
	NumberOfKidAgeFields = 12;
	// Add monthes pages
	Items.Monthes.ChoiceList.Add(0, NStr("en='Today'; ru='Сегодня'; de='Heute'"));
	vBegOfCurMonth = BegOfMonth(CurrentDate());
	For i = 1 To 12 Do
		vPageDate = AddMonth(vBegOfCurMonth, i - 1);
		If Year(vPageDate) > Year(CurrentDate()) And Month(vPageDate) = 1 Then
			Items.Monthes.ChoiceList.Add(i, GetMonthNameAtServer(Month(vPageDate)) + " " + Format(vPageDate, "DF=yyyy"));
		Else
			Items.Monthes.ChoiceList.Add(i, GetMonthNameAtServer(Month(vPageDate)));
		EndIf;
	EndDo;
	// Change monthes page
	PeriodFromChangeMode = True;
	If BegOfDay(DateFrom) = BegOfDay(CurrentDate()) Then
		Monthes = 0;
	Else
		vIndex = Month(DateFrom) - Month(CurrentDate());
		If vIndex < 0 Then
			vIndex = vIndex + 12;
		EndIf;
		vIndex = vIndex + 1;
		Monthes = vIndex;
	EndIf;
	PeriodFromChangeMode = False;
	// Build report in web client mode
	#If WebClient Then
		If ShowPrices Then
			ShowPrices = False;
			BuildReport();
		EndIf;
	#EndIf
	If tcOnClient.IsHomePageWindow(ThisObject) Then
		vPrefix = NStr("en = 'Vacant rooms: '; de = 'Nachweis über das Vorhandensein freier Zimmer: '; ru = 'Справка о наличии свободных номеров: '");
		tcCommonFunctionOnClientServer.cmSetFormTitleHotelName(ThisObject, vPrefix);
	EndIf;
	#If MobileClient Then
		ChangeAttributesAtServer();
	#EndIf
EndProcedure // OnOpen

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "Document.Reservation.Write" Or pEventName = "Document.Reservation.WriteNew" Then
		AttachIdleHandler("RefreshFormData", 1, True);
	ElsIf pEventName = "Document.Accommodation.Write" Or pEventName = "Document.Accommodation.WriteNew" Then
		AttachIdleHandler("RefreshFormData", 1, True);
	ElsIf pEventName = "Catalog.GuestGroups.Changed" Then
		If ValueIsFilled(pParameter) And TypeOf(pParameter) = Type("CatalogRef.GuestGroups") Then
			If GuestGroup = pParameter Then
				GuestGroupOnChange(Items.GuestGroup, False);
			EndIf;
		EndIf;
		AttachIdleHandler("RefreshFormData", 1, True);
	ElsIf pEventName = "System.Hotel.Changed" And pParameter <> Hotel Then
		If ValueIsFilled(pParameter) Then
			Hotel = pParameter;
			HotelOnChange(Items.Hotel);
			If tcOnClient.IsHomePageWindow(ThisObject) Then
				vPrefix = NStr("en = 'Vacant rooms: '; de = 'Nachweis über das Vorhandensein freier Zimmer: '; ru = 'Справка о наличии свободных номеров: '");
				tcCommonFunctionOnClientServer.cmSetFormTitleHotelName(ThisObject, vPrefix);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // NotificationProcessing

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ReportOnActivateArea(pItem)
	If SkipOnActivateArea Then
		Return;
	EndIf;
	vClearPreviousPrices = False;
	Try     
		vSelAreas = Report.SelectedAreas;
		If vSelAreas.Count() > 1 Then
			vSelAreasArray = New Array;
			For Each vSelArea In vSelAreas Do
				vSelAreasArray.Add(vSelArea);
				Break;
			EndDo;
			Items.Report.SetSelectedAreas(vSelAreasArray);
			Return;
		EndIf;
		If vSelAreas.Count() > 0 Then
			vSelAreasArray = New Array;
			For Each vSelArea In vSelAreas Do
				// Currently only one row could be selected
				If vSelArea.Left > 2 Then
					If (vSelArea.Bottom - vSelArea.Top) > 0 Then
						If SelectionTopRow <> 0 Then
							vNewSelArea = Report.Area(SelectionTopRow, vSelArea.Left, SelectionTopRow, vSelArea.Right);
						Else
							vNewSelArea = Report.Area(vSelArea.Top, vSelArea.Left, vSelArea.Top, vSelArea.Right);
						EndIf;
						vSelAreasArray.Add(vNewSelArea);
						vSelArea = vNewSelArea;
					Else
						SelectionTopRow = vSelArea.Top;
					EndIf;
				EndIf;
				Break; // No multiple selection
			EndDo;    
			If vSelAreasArray.Count() > 0 Then
				Items.Report.SetSelectedAreas(vSelAreasArray);
				Return;
			EndIf;
			If vSelAreas.Count() > 0 Then
				Try
					vSelArea = vSelAreas.Get(0);
					vDetailsLeftTop = Report.Area(vSelArea.Top, vSelArea.Left).Details;
					vDetailsRightBottom = Report.Area(vSelArea.Bottom, vSelArea.Right).Details;
					If vDetailsLeftTop <> Undefined And 
						vDetailsRightBottom <> Undefined Then
						If TypeOf(vDetailsLeftTop) = Type("Structure") And TypeOf(vDetailsRightBottom) = Type("Structure") Then
							If ValueIsFilled(vDetailsLeftTop.PeriodTo) AND ValueIsFilled(vDetailsRightBottom.PeriodTo) Then
								vPeriodFrom = vDetailsLeftTop.PeriodTo;
								vPeriodTo = vDetailsRightBottom.PeriodTo;
							EndIf;
							If ValueIsFilled(vPeriodFrom) Then
								CurHotel = vDetailsLeftTop.Hotel;
								CurRoomType = vDetailsLeftTop.RoomType;
								CurDate = BegOfDay(vPeriodFrom);
							EndIf;
							vRoomTypeFrom = vDetailsLeftTop.RoomType;
							If ValueIsFilled(vRoomTypeFrom) Then
								If SelRoomType <> vRoomTypeFrom Then
									vClearPreviousPrices = True;
								EndIf;
								SelRoomType = vRoomTypeFrom;
								ClearCalculateButtonTitle();
							EndIf;									
							If ValueIsFilled(vPeriodFrom) And ValueIsFilled(vPeriodTo) Then
								// Set period selected
								vPeriodTo = ?(vPeriodFrom = vPeriodTo, vPeriodTo + 24 * 60 * 60, vPeriodTo);
								If CheckInDate <> BegOfDay(vPeriodFrom) Or CheckOutDate <> BegOfDay(vPeriodTo) Then
									vClearPreviousPrices = True;
								EndIf;
								CheckInDate = BegOfDay(vPeriodFrom);
								CheckOutDate = BegOfDay(vPeriodTo);
								Duration = CalculateDurationAtServer(RoomRate, CheckInDate, CheckOutDate);
								If NumberOfAdults = 0 And NumberOfKids = 0 Then
									NumberOfAdults = 1;
								EndIf;
								ClearCalculateButtonTitle();
								If vClearPreviousPrices Then
									// Clear prices calculated for the previous selection
									If AccommodationTypesTable.Count() > 0 Then
										For Each vATTRow In AccommodationTypesTable Do
											If Not IsBlankString(vATTRow.Price) Then
												vATTRow.Price = "";
											Else
												If AccommodationTypesTable.IndexOf(vATTRow) = 0 Then
													Break;
												EndIf;
											EndIf;
										EndDo;
										// Clear totals
										Items.AccommodationTypesTablePrice.FooterText = "";
									EndIf;
								EndIf;
								// Fill availability by hours
								CurTime = 0;
								AttachIdleHandler("FillAvailabilityBreakdown", 0.3, True);
							EndIf;
						EndIf;
					EndIf;
				Except
				EndTry;
			EndIf;
		EndIf;
	Except
		tcCommonFunctionOnClientServer.TextMessage(ErrorDescription());
	EndTry;
EndProcedure // ReportOnActivateArea

// -----------------------------------------------------------------------------
&AtClient
Procedure NumberOfKidsOnChange(pItem)
	If NumberOfKids = 0 Then
		Items.AgeDecoration.Visible = False;
		If LastKidsNumber > 0 Then
			For vInd = 1 To LastKidsNumber Do
				Try
					Items["KidAge" + String(vInd)].Visible = False;
					ThisObject["KidAge" + String(vInd)] = 0;
				Except
				EndTry;
			EndDo;
		EndIf;
	Else
		If NumberOfKids > NumberOfKidAgeFields Then
			NumberOfKids = NumberOfKidAgeFields;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Maximum number of children allowed is " + NumberOfKidAgeFields + "!'; de='Maximum number of children allowed is " + NumberOfKidAgeFields + "!'; ru='Максимально возможное число детей равно " + NumberOfKidAgeFields + "!'"));
		EndIf;
		Items.AgeDecoration.Visible = True;
		If NumberOfKids < LastKidsNumber Then
			For vInd = NumberOfKids + 1 To LastKidsNumber Do
				Try
					Items["KidAge" + String(vInd)].Visible = False;
					ThisObject["KidAge" + String(vInd)] = 0;
				Except
				EndTry;
			EndDo;
		ElsIf NumberOfKids > LastKidsNumber Then
			vNumberOfFieldsToAdd = 0;
			If NumberOfKids > NumberOfKidAgeFields Then
				Try
					For vInd = LastKidsNumber + 1 To NumberOfKidAgeFields Do
						Items["KidAge" + String(vInd)].Visible = True;
						ThisObject["KidAge" + String(vInd)] = 0;
					EndDo;
				Except
				EndTry;
				vNumberOfFieldsToAdd = NumberOfKids - NumberOfKidAgeFields;
				If LastKidsNumber > NumberOfKidAgeFields Then
					vNumberOfFieldsToAdd = vNumberOfFieldsToAdd - (LastKidsNumber - NumberOfKidAgeFields);
				EndIf;
				AddKidAgeAttributes(vNumberOfFieldsToAdd);
			Else
				Try
					For vInd = LastKidsNumber + 1 To NumberOfKids Do
						Items["KidAge" + String(vInd)].Visible = True;
						ThisObject["KidAge" + String(vInd)] = 0;
					EndDo;
				Except
				EndTry;
			EndIf;
		EndIf;
	EndIf;
	LastKidsNumber = NumberOfKids;
	ClearCalculateButtonTitle();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AccommodationTypesTableAccommodationTypeOnChange(pItem)
	AccommodationTypeOnChangeAtServer();
EndProcedure // AccommodationTypesTableAccommodationTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AccommodationTypesTableGuestNameAutoComplete(pItem, pText, pChoiceData, pWait, pStandardProcessing)
	pStandardProcessing = False;
	vCurData = pItem.Parent.CurrentData;
	If ValueIsFilled(vCurData.GuestRef) And Not IsBlankString(pText) Then
		vCurData.GuestName = TrimR(LastGuestFullName);
		vMessage = New UserMessage;
		vMessage.Field = "AccommodationTypesTable[" + String(vCurData.RowIndex) + "].GuestName";
		vMessage.Text = NStr("en='The data can be changed in the guest card only! (To open the guest card, click the magnifying glass; To write a new guest, click the delete icon and type guest name in the field)';ru='Данные могут быть изменены только в карточке гостя! (Для того, чтобы открыть карточку гостя, нажмите кнопку с изображением лупы; Для того, чтобы создать нового гостя, нажмите кнопку с крестиком и введите ФИО гостя в поле)';de='Die Daten können nur in der Karte des Gastes geändert werden! (Um die Karte des Gastes zu öffnen, drücken Sie die Taste mit der Lupe; um einen neuen Gast zu erstellen, drücken Sie die Taste mit dem Kreuz und geben Sie den Namen und den Vornamen des Gastes ins Feld ein)'");
		vMessage.Message();
	Else
		#If Not WebClient Then
			If StrLen(pText) > 2 Then
				vChoiceDataUID = tcOnServer.cmGetGuestsChoiceDataList(pText);
				pChoiceData = GetFromTempStorage(vChoiceDataUID);
				If pChoiceData.Count() = 0 Then
					pChoiceData.Add(pText, NStr("en='--Guest not found--';ru='--Гость не найден--';de='--Gast nicht gefunden--'"));
				EndIf;
			EndIf;
		#Else
			pStandardProcessing = True;
			pChoiceData = Undefined;
		#EndIf
	EndIf;
EndProcedure // AccommodationTypesTableGuestNameAutoComplete

// -----------------------------------------------------------------------------
&AtClient
Procedure AccommodationTypesTableGuestNameTextEditEnd(pItem, pText, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vCurData = pItem.Parent.CurrentData;
	If ValueIsFilled(vCurData.GuestRef) Then
		If IsBlankString(pText) Then
			vCurData.GuestRef = Undefined;
			LastGuestFullName = "";
		Else
			vCurData.GuestName = LastGuestFullName;
			vMessage = New UserMessage;
			vMessage.Field = "AccommodationTypesTable[" + String(vCurData.RowIndex) + "].GuestName";
			vMessage.Text = NStr("en='The data can be changed in the guest card only! (To open the guest card, click the magnifying glass; To write a new guest, click the delete icon and type guest name in the field)';ru='Данные могут быть изменены только в карточке гостя! (Для того, чтобы открыть карточку гостя, нажмите кнопку с изображением лупы; Для того, чтобы создать нового гостя, нажмите кнопку с крестиком и введите ФИО гостя в поле)';de='Die Daten können nur in der Karte des Gastes geändert werden! (Um die Karte des Gastes zu öffnen, drücken Sie die Taste mit der Lupe; um einen neuen Gast zu erstellen, drücken Sie die Taste mit dem Kreuz und geben Sie den Namen und den Vornamen des Gastes ins Feld ein)'");
			vMessage.Message();
		EndIf;
	Else
		#If WebClient Then
			If StrLen(pText) > 2 Then
				vChoiceDataUID = tcOnServer.cmGetGuestsChoiceDataList(pText);
				pChoiceData = GetFromTempStorage(vChoiceDataUID);
				If pChoiceData.Count() = 0 Then
					pChoiceData.Add(pText, NStr("en='--Guest not found--';ru='--Гость не найден--';de='--Gast nicht gefunden--'"));
				Else
					pChoiceData.Insert(0, TrimR(pText));
				EndIf;
			EndIf;
		#Else
			pChoiceData = New ValueList();
			pChoiceData.Add(TrimR(pText));
		#EndIf
	EndIf;
EndProcedure // AccommodationTypesTableGuestNameTextEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure AccommodationTypesTableGuestNameChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	pStandardProcessing = False;
	vCurData = pItem.Parent.CurrentData;
	If ValueIsFilled(pSelectedValue) Then
		If TypeOf(pSelectedValue) = Type("CatalogRef.Clients") Then
			vCurData.GuestRef = pSelectedValue;
			vCurData.GuestName = tcOnServer.cmGetAttributeByRef(pSelectedValue, "FullName");
			LastGuestFullName = vCurData.GuestName;
			vCurData.DateOfBirth = tcOnServer.cmGetAttributeByRef(pSelectedValue, "DateOfBirth");
		ElsIf TypeOf(pSelectedValue) = Type("String") Then
			vCurData.GuestName = pSelectedValue;
			If ValueIsFilled(vCurData.GuestRef) Then
				vCurData.DateOfBirth = '00010101';
			EndIf;
			vCurData.GuestRef = tcOnServer.cmGetCatalogItemRefByCode("Clients", "", True);
		EndIf;
	Else
		vCurData.GuestRef = tcOnServer.cmGetCatalogItemRefByCode("Clients",, True);
		vCurData.DateOfBirth = '00010101';
	EndIf;
EndProcedure // AccommodationTypesTableGuestNameChoiceProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure AccommodationTypesTableGuestNameOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	vCurData = pItem.Parent.CurrentData;
	// Get client form
	If ValueIsFilled(vCurData.GuestRef) And (tcOnServer.cmGetAttributeByRef(vCurData.GuestRef, "FullName") = pItem.EditText) Then
		#If MobileClient Then
			OpenForm("Catalog.Clients.Form.mcItemForm", New Structure("Key", vCurData.GuestRef), ThisObject);
		#Else 
			OpenForm("Catalog.Clients.Form.tcItemForm", New Structure("Key", vCurData.GuestRef), ThisObject);
		#EndIf
	Else
		#If MobileClient Then
			vFrm = GetForm("Catalog.Clients.Form.mcItemForm", , ThisObject, New UUID());
		#Else 
			vFrm = GetForm("Catalog.Clients.Form.tcItemForm", , ThisObject, New UUID());
		#EndIf
		vSelGuest = pItem.EditText;
		// Get guest last name, first name and second name
		vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
		vLastNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
		vFrm.Object.LastName = Title(Left(TrimAll(vSelGuest), vLastNameLastCharNumber));
		If vLastNameLastCharNumber <> StrLen(vSelGuest) Then
			vSelGuest = Mid(TrimAll(vSelGuest), vLastNameLastCharNumber + 2, StrLen(vSelGuest));
			vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
			vFirstNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
			vFrm.Object.FirstName = Title(Left(TrimAll(vSelGuest), vFirstNameLastCharNumber));
			If vFirstNameLastCharNumber<>StrLen(vSelGuest) Then
				vSelGuest = Mid(TrimAll(vSelGuest), vFirstNameLastCharNumber + 2, StrLen(vSelGuest));
				vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
				vSecondNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
				vFrm.Object.SecondName = Title(Left(TrimAll(vSelGuest), vSecondNameLastCharNumber));
			EndIf;
		EndIf;
		vFrm.Open();
	EndIf;
EndProcedure // AccommodationTypesTableGuestNameOpening

// -----------------------------------------------------------------------------
&AtClient
Procedure AccommodationTypesTableGuestNameClearing(pItem, pStandardProcessing)
	vCurData = pItem.Parent.CurrentData;
	vCurData.GuestRef = "";
	vCurData.DateOfBirth = '00010101';
EndProcedure // AccommodationTypesTableGuestNameClearing

// -----------------------------------------------------------------------------
&AtClient
Procedure AccommodationTypesTableGuestNameStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vCurData = pItem.Parent.CurrentData;
	// Get clients search form
	vFrm = GetForm("Catalog.Clients.Form.tcListForm", New Structure("ChoiceMode", True), pItem);
	If ValueIsFilled(vCurData.GuestRef) Then
		vFrm.SelLastName = tcOnServer.cmGetAttributeByRef(vCurData.GuestRef, "LastName");
		vFrm.SelFirstName = tcOnServer.cmGetAttributeByRef(vCurData.GuestRef, "FirstName");
		vFrm.SelSecondName = tcOnServer.cmGetAttributeByRef(vCurData.GuestRef, "SecondName");
	Else
		// Get guest last name, first name and second name
		vSelGuest = pItem.EditText;
		vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
		vLastNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
		vFrm.SelLastName = Title(Left(TrimAll(vSelGuest), vLastNameLastCharNumber));
		If vLastNameLastCharNumber<>StrLen(vSelGuest) Then
			vSelGuest = Mid(TrimAll(vSelGuest), vLastNameLastCharNumber+2, StrLen(vSelGuest));
			vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
			vFirstNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
			vFrm.SelFirstName = Title(Left(TrimAll(vSelGuest), vFirstNameLastCharNumber));
			If vFirstNameLastCharNumber<>StrLen(vSelGuest) Then
				vSelGuest = Mid(TrimAll(vSelGuest), vFirstNameLastCharNumber+2, StrLen(vSelGuest));
				vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
				vSecondNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
				vFrm.SelSecondName = Title(Left(TrimAll(vSelGuest), vSecondNameLastCharNumber));
			EndIf;
		EndIf; 
	EndIf;
	vFrm.Items.List.MultipleChoice = False;
	vFrm.Open();
EndProcedure // AccommodationTypesTableGuestNameStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure AccommodationTypesTableBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder)
	If Not CheckFields() Then
		pCancel = True;			
	EndIf;
EndProcedure // AccommodationTypesTableBeforeAddRow

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomQuotaOnChange(pItem)
	RoomQuotaOnChangeAtServer();
	ClearCalculateButtonTitle();
EndProcedure // RoomQuotaOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ReportDetailProcessing(pItem, pDetails, pStandardProcessing)
	If TypeOf(pDetails) = Type("Structure") Then
		pStandardProcessing = False;
		If Not ValueIsFilled(pDetails.PeriodTo) And ValueIsFilled(pDetails.RoomType) Then
			vRoomTypePictureLink = tcOnServer.cmGetAttributeByRef(pDetails.RoomType, "RoomTypePictureLink");
			vRoomTypeInfoLink = tcOnServer.cmGetAttributeByRef(pDetails.RoomType, "RoomTypeInfoLink");
			OpenForm("CommonForm.tcHTMLInfoForm", New Structure("InfoLink, PictureLink, RoomType", vRoomTypeInfoLink, vRoomTypePictureLink, pDetails.RoomType));
		Else
			// Open room inventory report
			If Not tcOnServer.CheckUserRightsToOpenReport(PredefinedValue("Catalog.Reports.RoomInventory")) Then
				Raise NStr("en='You do not have rights to run report: ';ru='Нет прав на формирование отчета: ';de='Sie haben keine Rechte, einen Bericht zu erstellen:'") + tcOnServer.cmNStrAtServer(tcOnServer.cmGetAttributeByRef(PredefinedValue("Catalog.Reports.RoomInventory"), "Description")) + "!";
			EndIf;
			#If ThickClientOrdinaryApplication Then 
				vRepObj = cmBuildReportObject(Catalogs.Reports.RoomInventory);
				If vRepObj <> Undefined Then
					// Load report catalog item attributes
					vRepObj.Report = Catalogs.Reports.RoomInventory;
					// Open report's default form
					vRepFrm = vRepObj.GetForm();
					vRepFrm.GenerateOnFormOpen = False;
					vRepFrm.Open();
					// Set report attributes from parameters
					vRepObj.Hotel = pDetails.Hotel;
					vRepObj.RoomType = pDetails.RoomType;
					vRepObj.PeriodTo = EndOfDay(pDetails.PeriodTo);
					// Generate report
					vRepFrm.fmGenerateReport();
				EndIf;
			#Else
			   OpenForm("Report.RoomInventory.Form.tcReportForm", New Structure("FillingValues, GenerateOnOpen, Hotel, RoomType, PeriodTo", New Structure("ReportRef", PredefinedValue("Catalog.Reports.RoomInventory")), True, pDetails.Hotel, pDetails.RoomType, EndOfDay(pDetails.PeriodTo)), , New UUID());
			#EndIf
		EndIf;
	ElsIf TypeOf(pDetails) = Type("CatalogRef.Hotels") Then
		pStandardProcessing = False;
		If ValueIsFilled(pDetails) And Not tcOnServer.cmGetAttributeByRef(pDetails, "IsFolder") Then
			vHotel = pDetails;
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
		EndIf;
	ElsIf TypeOf(pDetails) <> Type("CatalogRef.Events") Then
		pStandardProcessing = False;
	EndIf;
EndProcedure // ReportDetailProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure NumberOfDaysOnChange(pItem)
	NumberOfDaysOnChangeAtServer();
EndProcedure // NumberOfDaysOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DateFromOnChange(pItem)
	NumberOfDaysOnChangeAtServer();
	// Change monthes page
	PeriodFromChangeMode = True;
	vIndex = Month(DateFrom) - Month(CurrentDate());
	If vIndex < 0 Then
		vIndex = vIndex + 12;
	EndIf;
	vIndex = vIndex + 1;
	Monthes = vIndex;
	PeriodFromChangeMode = False;
EndProcedure // DateFromOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AccommodationTypesTableSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	If SkipOnActivateCell Then
		SkipOnActivateCell = False;
		Return;
	EndIf;
	If pField.Name = "AccommodationTypesTableAccommodationType" Or pField.Name = "AccommodationTypesTableIcon" Then
		If pItem.CurrentData <> Undefined Then
			If pItem.CurrentData.RowIndex = 0 Then
				FillAccommodationTypesChoiceList();
				LastRowIndex = 0;
			Else
				If LastRowIndex = 0 Then
					FillAccommodationTypesChoiceList(False);
					LastRowIndex = pItem.CurrentData.RowIndex;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // AccommodationTypesTableSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowPricesOnChange(pItem)
	#If WebClient Then
		If ShowPrices Then
			ShowPrices = False;
		EndIf;
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Not supported in web client mode!'; ru='Не поддерживается в режиме Web-клиента!'; de='Nicht im Web-Client-Modus unterstützt!'"), MessageStatus.Attention);
		Return;
	#EndIf
	
	ShowPricesOnChangeAtServer(ShowPrices);
	BuildReport();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure MonthesOnChange(pItem)
	If PeriodFromChangeMode Then
		Return;
	EndIf;
	If Monthes = 0 Then
		DateFrom = BegOfDay(CurrentDate());
	Else
		DateFrom = AddMonth(BegOfMonth(CurrentDate()), Monthes - 1);
	EndIf;
	// Build report	
	BuildReport();
	// Reset variable
	PeriodFromChangeMode = False;
EndProcedure // MonthesOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckOutDateOnChange(pItem)
	Duration = CalculateDurationAtServer(RoomRate, CheckInDate, CheckOutDate);
EndProcedure // CheckOutDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckInDateOnChange(pItem)
	Duration = CalculateDurationAtServer(RoomRate, CheckInDate, CheckOutDate);
	ClearCalculateButtonTitle();
	If CheckInDate > (DateFrom + 24*3600*NumberOfDays) Or CheckInDate < DateFrom Then
		DateFrom = CheckInDate;
		DateFromOnChange(Items.DateFrom);
	EndIf;
EndProcedure // CheckInDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DurationOnChange(pItem)
	CheckOutDate = CalculateCheckOutDateAtServer(RoomRate, CheckInDate, Duration);
	ClearCalculateButtonTitle();
EndProcedure // DurationOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRateStartChoice(pItem, pChoiceData, pStandardProcessing)
	If ValueIsFilled(CheckInDate) And ValueIsFilled(CheckOutDate) And BegOfDay(CheckOutDate) > BegOfDay(CheckInDate) Then
		pStandardProcessing = False;
		vAllowedRoomRates = GetAllowedRoomRates();
		OpenForm("Catalog.RoomRates.Form.tcChoiceForm", New Structure("ChoiceMode, Hotel, Company, PeriodFrom, PeriodTo, RoomRates, CurrentRow", True, Hotel, PredefinedValue("Catalog.Companies.EmptyRef"), CheckInDate, CheckOutDate, vAllowedRoomRates, RoomRate), pItem);
	EndIf;
EndProcedure // RoomRateStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomTypeStartChoice(pItem, pChoiceData, pStandardProcessing)
	// APDEX
	vKeyOperation = "Catalog.RoomTypes.Form.tcChoiceForm.OpenForm";
	APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

	pStandardProcessing = False;
	
	If ValueIsFilled(CheckInDate) Then
		vCheckInDate = BegOfDay(CheckInDate);
	Else
		vCheckInDate = BegOfDay(CurrentDate());
		CheckInDate = vCheckInDate;
	EndIf;
	If ValueIsFilled(CheckOutDate) And BegOfDay(CheckOutDate) > vCheckInDate Then
		vCheckOutDate = BegOfDay(CheckOutDate);
	Else
		vCheckOutDate = vCheckInDate + 24 * 3600;
		CheckOutDate = vCheckOutDate;
	EndIf;
	vDuration = CalculateDurationAtServer(RoomRate, vCheckInDate, vCheckOutDate);
	If vDuration <> Duration Then
		Duration = vDuration;
	EndIf;
	
	GetDates(vCheckInDate, vCheckOutDate, vDuration, RoomRate);
	
	vKidsAgeArray = New Array;
	For vInt = 1 To NumberOfKids Do
		vKidsAgeArray.Add(ThisObject["KidAge" + vInt]);
	EndDo;
	
	vParams = New Structure("Hotel, RoomType, CheckInDate, CheckOutDate, Duration, RoomRate, ClientType, RoomQuota, NumberOfAdults, NumberOfKids, AgeArray", 
	                         Hotel, SelRoomType, vCheckInDate, vCheckOutDate, vDuration, RoomRate, ClientType, RoomQuota, NumberOfAdults, NumberOfKids, vKidsAgeArray);
	vFrm = OpenForm("Catalog.RoomTypes.Form.tcChoiceForm", vParams, pItem);
EndProcedure // SelRoomTypeStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomTypeChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	If TypeOf(pSelectedValue) = Type("Structure") Then
		pStandardProcessing = False;
		FillPropertyValues(ThisObject, pSelectedValue);
		SelRoomType = pSelectedValue.RoomType;
	EndIf;
EndProcedure // SelRoomTypeChoiceProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure OrderBasketAfterDeleteRow(pItem)
	CalculateOrderBasketTotals();
EndProcedure // OrderBasketAfterDeleteRow

// -----------------------------------------------------------------------------
&AtClient
Procedure OrderBasketOnEditEnd(pItem, pNewRow, pCancelEdit)
	CalculateOrderBasketTotals();
EndProcedure // OrderBasketOnEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure ClientTypeOnChange(pItem)
	ClearCalculateButtonTitle();
	// Ask should we recalculate order basket rows
	If OrderBasket.Count() > 0 Then
		AskForBasketRecalculation();
	EndIf;
	// Rebuild report
	BuildReport();
EndProcedure // ClientTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountTypeOnChange(pItem)
	ClearCalculateButtonTitle();
	// Ask should we recalculate order basket rows
	If OrderBasket.Count() > 0 Then
		AskForBasketRecalculation();
	EndIf;
	// Rebuild report
	BuildReport();
EndProcedure // DiscountTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure MealBoardTermOnChange(pItem)
	ClearCalculateButtonTitle();
	// Ask should we recalculate order basket rows
	If OrderBasket.Count() > 0 Then
		AskForBasketRecalculation();
	EndIf;
	// Rebuild report
	BuildReport();
EndProcedure // MealBoardTermOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomTypeOnChange(pItem)
	ClearCalculateButtonTitle();
EndProcedure // SelRoomTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure NumberOfAdultsOnChange(pItem)
	ClearCalculateButtonTitle();
EndProcedure // NumberOfAdultsOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure KidAgeOnChange(pItem)
	ClearCalculateButtonTitle();
EndProcedure // KidAgeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure IsForFolioSplitOnChange(pItem)
	ClearCalculateButtonTitle();
EndProcedure // IsForFolioSplitOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure OrderBasketSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	vOrderRow = OrderBasket.FindByID(pSelectedRow);
	If vOrderRow <> Undefined And pField.Name = "OrderBasketRowDelete" Then
		pStandardProcessing = False;
		OrderBasket.Delete(OrderBasket.IndexOf(vOrderRow));
		CalculateOrderBasketTotals();
	EndIf;
EndProcedure // OrderBasketSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure AllowedRoomRatesOnActivateRow(pItem)
	vCurItem = Items.AllowedRoomRates.CurrentData;
	If vCurItem <> Undefined Then
		If ValueIsFilled(vCurItem.Value) Then
			RoomRate = vCurItem.Value;
		EndIf;
	EndIf;
EndProcedure // AllowedRoomRatesOnActivateRow

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowPreliminaryOnChange(pItem)
	If ShowPreliminary Then
		If ShowCommitment Then
			ShowCommitment = False;
		EndIf;
	EndIf;
	Refresh(Commands.Refresh);
EndProcedure // ShowPreliminaryOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowCommitmentOnChange(pItem)
	If ShowCommitment Then
		If ShowPreliminary Then
			ShowPreliminary = False;
		EndIf;
	EndIf;
	Refresh(Commands.Refresh);
EndProcedure // ShowCommitmentOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRateOnChange(pItem)
	// Check allotment rate
	If ValueIsFilled(RoomQuota) Then
		vAllotmentRate = tcOnServer.cmGetAttributeByRef(RoomQuota, "RoomRate");
		If ValueIsFilled(vAllotmentRate) AND RoomRate <> vAllotmentRate Then
			vUsrMsg = New UserMessage;
			vUsrMsg.Field = "RoomRate";
			vUsrMsg.Text = NStr("en = 'The selected room rate does not match the room rate from the allotment!'; de = 'Der gewählte Zimmerpreis stimmt nicht mit dem Zimmerpreis aus der Allotment überein!'; ru = 'Выбранный тариф не соответствует тарифу указанному в квоте!'");
			vUsrMsg.Message();
		EndIf;
	EndIf;
	If ValueIsFilled(RoomRate) Then
		vRoomRate = tcOnServer.cmGetAtributeAsArray(RoomRate);
		If vRoomRate.ClientType <> ClientType Then
			ClientType = vRoomRate.ClientType;
		EndIf;
		If ValueIsFilled(vRoomRate.ServicePackage) And tcOnServer.cmGetAttributeByRef(vRoomRate.ServicePackage, "IsMealBoardTerm") Then
			MealBoardTerm = vRoomRate.ServicePackage;
		EndIf;
		If ValueIsFilled(vRoomRate.DiscountType) Then
			DiscountType = vRoomRate.DiscountType;
		EndIf;
	EndIf;
	// Clear calculation button title
	ClearCalculateButtonTitle();
	// Ask should we recalculate order basket rows
	If OrderBasket.Count() > 0 Then
		AskForBasketRecalculation();
	EndIf;
	// Rebuild report
	BuildReport();
EndProcedure // RoomRateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupOnChange(pItem, pRebuildReport = True)
	vCurRoomRate = RoomRate;
	vCurMealBoardTerm = MealBoardTerm;
	vCurClientType = ClientType;
	vCurDiscountType = DiscountType;
	If ValueIsFilled(GuestGroup) Then
		GuestGroupOnChangeAtServer();
	EndIf;
	If vCurRoomRate <> RoomRate Or vCurMealBoardTerm <> MealBoardTerm Or vCurClientType <> ClientType Or vCurDiscountType <> DiscountType Then
		ClearCalculateButtonTitle();
		// Ask should we recalculate order basket rows
		If OrderBasket.Count() > 0 Then
			AskForBasketRecalculation();
		EndIf;
		// Rebuild report
		If pRebuildReport Then
			BuildReport();
		EndIf;
	EndIf;
EndProcedure // GuestGroupOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AvailabilityBreakdownSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	If pSelectedRow <> Undefined Then
		vRow = AvailabilityBreakdown.FindByID(pSelectedRow);
		If vRow <> Undefined And ValueIsFilled(vRow.Ref) Then
			If TypeOf(vRow.Ref) <> Type("CatalogRef.Hotels") Then
				ShowValue(, vRow.Ref);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // AvailabilityBreakdownSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure AvailabilityByHoursOnActivateCell(pItem)
	vCurTime = 0;
	vName = "";
	If pItem <> Undefined Then
		vName = Items.AvailabilityByHours.CurrentItem.Name;
		If Left(vName, 23) = "AvailabilityByHoursHour" Then
			vCurTime = Number(Left(Items.AvailabilityByHours.CurrentItem.Title, 2));
		EndIf;
	EndIf;
	If CurTime <> vCurTime And OldCurTime <> vCurTime Then
		CurTime = vCurTime;
		OldCurTime = CurTime;
		OldCurRoomType = CurRoomType;
		AttachIdleHandler("FillAvailabilityBreakdown", 0.3, True);
	EndIf;
EndProcedure // AvailabilityByHoursOnActivateCell

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure // HotelClearing

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelOnChange(pItem)
	HotelOnChangeAtServer();
	ClearBasket();
EndProcedure // HotelOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelBedsSetupStartChoice(pItem, pChoiceData, pChoiceByAdding, pStandardProcessing)
	Items.SelBedsSetup.ChoiceList.Clear();
	vBedsSetupList = GetBedsSetupList(SelBedsSetup, SelRoomType);
	For Each vBedsSetupListItem In vBedsSetupList Do
		Items.SelBedsSetup.ChoiceList.Add(vBedsSetupListItem.Value);
	EndDo;
EndProcedure // SelBedsSetupStartChoice

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure PrevPeriodButton(pCommand)
	DateFrom = BegOfDay(DateFrom - (NumberOfDays - 1) * 24*3600);
	// Change monthes page
	PeriodFromChangeMode = True;
	vIndex = Month(DateFrom) - Month(CurrentDate());
	If vIndex < 0 Then
		vIndex = vIndex + 12;
	EndIf;
	vIndex = vIndex + 1;
	Monthes = vIndex;
	PeriodFromChangeMode = False;
	// Build report	
	BuildReport();
EndProcedure // PrevPeriodButton

// -----------------------------------------------------------------------------
&AtClient
Procedure NextPeriodButton(pCommand)
	DateFrom = BegOfDay(DateFrom + (NumberOfDays - 1) * 24*3600);
	// Change monthes page
	PeriodFromChangeMode = True;
	vIndex = Month(DateFrom) - Month(CurrentDate());
	If vIndex < 0 Then
		vIndex = vIndex + 12;
	EndIf;
	vIndex = vIndex + 1;
	Monthes = vIndex;
	PeriodFromChangeMode = False;
	// Build report	
	BuildReport();
EndProcedure // NextPeriodButton

// -----------------------------------------------------------------------------
&AtClient
Procedure NewReserv(pCommand)
	If CheckFields() Then
		vError = "";
		vWarning = "";
		If AccommodationTypesTable.Count() = 0 Then
			GetPrice(, True);
		EndIf;
		If AccommodationTypesTable.Count() > 0 Then
			vParams = GetNewReservationFormParameters(vError, vWarning);
			If Not IsBlankString(vError) Then
				tcCommonFunctionOnClientServer.TextMessage(vError, MessageStatus.Attention);
			Else
				vParams.Insert("Template", AccommodationTemplate);
				vParams.Insert("DocsList", DocsList.Copy());
				If ValueIsFilled(GuestGroup) Then
					vParams.Insert("GuestGroup", GuestGroup);
				EndIf;
				#If MobileClient Then
					OpenForm("Document.Reservation.Form.mcDocumentForm", vParams, ThisObject);
				#Else
					// APDEX
					vKeyOperation = "Document.Reservation.Form.tcDocumentForm.OpenForm";
					APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

					OpenForm("Document.Reservation.Form.tcDocumentForm", vParams, ThisObject);
				#EndIf
				If Not IsBlankString(vWarning) Then
					tcCommonFunctionOnClientServer.TextMessage(vWarning, MessageStatus.Attention);
				EndIf;
			EndIf;
		Else
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Accommodation types table is empty';ru='Заполните таблицу видов размещения';de='Tabelle der Unterbringungstypen ausfüllen'"));
		EndIf;
	EndIf;
EndProcedure // NewReserv

// -----------------------------------------------------------------------------
&AtClient
Procedure Calculate(pCommand)
	If CheckFields() Then
		SkipOnActivateArea = True;
		GetPrice();
		AttachIdleHandler("ClearSkipOnActivateArea", 1, True);
	EndIf;
EndProcedure // Calculate

// -----------------------------------------------------------------------------
&AtClient
Procedure Refresh(pCommand)
	BuildReport();
EndProcedure // Refresh

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearBasket()
	AccommodationTypesTable.Clear();
	Items.AccommodationTypesTablePrice.FooterText = "";
	OrderBasket.Clear();
	CalculateOrderBasketTotals();
	Items.GuestsGroup.Hide();
	Items.GroupOrderBasket.Hide();
EndProcedure // ClearBasket

// -----------------------------------------------------------------------------
&AtClient
Procedure Clear(pCommand)
	ClearBasket();
EndProcedure // Clear

// -----------------------------------------------------------------------------
&AtClient
Procedure NewGroup(pCommand)
	vError = "";
	vAddRoomsToAllotment = False;
	vAllotmentBalances = Undefined;
	If CreateGuestGroupAtServer(vError, vAddRoomsToAllotment, vAllotmentBalances) Then
		vNewGroupParams = GetParameters();
		#If MobileClient Then
			OpenForm("Catalog.GuestGroups.Form.mcItemForm", New Structure("Key, CheckInDate, CheckOutDate, Duration, Focus", GuestGroup, vNewGroupParams.CheckInDate, vNewGroupParams.CheckOutDate, vNewGroupParams.Duration, "Rooms"), ThisObject);
		#Else
			OpenForm("Catalog.GuestGroups.Form.tcItemForm", New Structure("Key, CheckInDate, CheckOutDate, Duration, Focus", GuestGroup, vNewGroupParams.CheckInDate, vNewGroupParams.CheckOutDate, vNewGroupParams.Duration, "Rooms"), ThisObject);
		#EndIf
		
		If Not IsBlankString(vError) Then
			tcCommonFunctionOnClientServer.TextMessage(vError, MessageStatus.Attention);
		EndIf;

		// Notify that group has changed
		Notify("Catalog.GuestGroups.Changed", GuestGroup);
		
	 	If vAddRoomsToAllotment Then
			ShowQueryBox(New NotifyDescription("AddRoomsToAllotment", ThisObject, New Structure("AllotmentBalances", vAllotmentBalances)), 
						 NStr("en='Add missing rooms to the allotment?'; ru='Добавить недостающие номера в квоту?'; de='Fehlende Zimmer zum Allotment hinzufügen?'"), 
						 QuestionDialogMode.YesNo, , DialogReturnCode.No);
		EndIf;
	Else
		tcCommonFunctionOnClientServer.TextMessage(vError, MessageStatus.Attention);
	EndIf;
EndProcedure // NewGroup

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
&AtClient
Procedure MakeReservation(pCommand)
	If OrderBasket.Count() > 1 Then
		NewGroup(pCommand);
	Else
		NewReserv(pCommand);
	EndIf;
	Clear(Commands.Clear);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AddToOrderBasket(pCommand)
	If CheckFields() Then
		GetPrice();
	   
		vOrderRow = OrderBasket.Add();
		
		vOrderRow.RoomQuantity = RoomQuantity;
		vOrderRow.RoomType = SelRoomType;
		vOrderRow.CheckInDate = CheckInDate;
		vOrderRow.Duration = Duration;
		vOrderRow.CheckOutDate = CheckOutDate;
		vOrderRow.NumberOfAdults = NumberOfAdults * RoomQuantity;
		vOrderRow.NumberOfKids = NumberOfKids * RoomQuantity;
		vOrderRow.KidAge1 = KidAge1;
		vOrderRow.KidAge2 = KidAge2;
		vOrderRow.KidAge3 = KidAge3;
		vOrderRow.KidAge4 = KidAge4;
		vOrderRow.Amount = Amount * RoomQuantity;
		vOrderRow.AccommodationTemplate = AccommodationTemplate;
		If Year(CheckInDate) <> Year(CheckOutDate) Then
			vOrderRow.RowDescription = TrimAll(tcOnServer.cmGetAttributeByRef(SelRoomType, "Code")) + ", " + Format(CheckInDate, "DF='dd MMM yyyy'") + " - " + Format(CheckOutDate, "DF='dd MMM yyyy'") + ", " + Format(NumberOfAdults, "NFD=0; NZ=; NG=") + "/" + Format(NumberOfKids, "NFD=0; NZ=; NG=");
		ElsIf Month(CheckInDate) <> Month(CheckOutDate) Then
			vOrderRow.RowDescription = TrimAll(tcOnServer.cmGetAttributeByRef(SelRoomType, "Code")) + ", " + Format(CheckInDate, "DF='dd MMM'") + " - " + Format(CheckOutDate, "DF='dd MMM yyyy'") + ", " + Format(NumberOfAdults, "NFD=0; NZ=; NG=") + "/" + Format(NumberOfKids, "NFD=0; NZ=; NG=");
		Else
			vOrderRow.RowDescription = TrimAll(tcOnServer.cmGetAttributeByRef(SelRoomType, "Code")) + ", " + Format(CheckInDate, "DF='dd'") + " - " + Format(CheckOutDate, "DF='dd MMM yyyy'") + ", " + Format(NumberOfAdults, "NFD=0; NZ=; NG=") + "/" + Format(NumberOfKids, "NFD=0; NZ=; NG=");
		EndIf;
		vOrderRow.RowDelete = "X";
		vOrderRow.ClientType = ClientType;
		vOrderRow.RoomRate = RoomRate;
		vOrderRow.MealBoardTerm = MealBoardTerm;
		vOrderRow.DiscountType = DiscountType;
		vOrderRow.BedsSetup = SelBedsSetup;

		// Show basket
		Items.GroupOrderBasket.Show();
		
		CalculateOrderBasketTotals();
		
		AccommodationTypesTable.Clear();
		Items.GuestsGroup.Hide();
	EndIf;
EndProcedure // AddToOrderBasket

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintReport(pCommand)
	
	PrintReport_AtServer();
	
EndProcedure

#EndRegion

#Region MobileForm

// -------------------------------------------------------------------------------------------------
&AtServer
Procedure ChangeAttributesAtServer()
	Items.HeaderDecoration.Visible = False;  
	Items.GroupFormCommands.Visible = False;
	Items.MainHeaderGroup.Visible = False;
	Items.PeriodAndRoomTypeGroup.Visible = False;
	Items.MainGroup.Visible = False;
	Items.FooterGroup.Visible = False;
	Items.TabulationAdultsAndKids.Visible = False;
	Items.ShowPrices.TitleLocation = FormItemTitleLocation.Right;
	Items.ShowPrices.Title = NStr("en = 'Availability/Prices and availability'; de = 'Verfügbarkeit/Preise und Verfügbarkeit'; ru = 'Наличие/Цены и наличие'");
	Items.NumberOfPersons.Group = ChildFormItemsGroup.HorizontalIfPossible;
	Items.AdultsGroup.Group = ChildFormItemsGroup.HorizontalIfPossible;
	Items.KidsCalculateGroup.Group = ChildFormItemsGroup.HorizontalIfPossible;
	Items.GroupOrderTotals.Group = ChildFormItemsGroup.Vertical;
	Items.Move(Items.MakeReservation, Items.OrderBasket.CommandBar, Items.ClearButton);
	
	Items.ClearButton.HorizontalAlignInGroup = ItemHorizontalLocation.Right;
	
	Items.CalculateButton.Type = FormButtonType.UsualButton;	
	Items.CalculateButton.HorizontalStretch = False;
	Items.CalculateButton.Width = 10;
	
	Items.GroupOrderTotalPersons.Group = ChildFormItemsGroup.AlwaysHorizontal;
	Items.GroupOrderAdultsKids.Group = ChildFormItemsGroup.AlwaysHorizontal;
	Items.Move(Items.OrderTotal, Items.GroupOrderTotalPersons);
	Items.MakeReservation.Representation = ButtonRepresentation.Text;
	Items.OrderBasketRowDescription.AutoMaxWidth = False;
	Items.OrderBasketRowDescription.HorizontalStretch = True; 
	Items.OrderBasket.Width = 0;
	Items.OrderBasket.AutoMaxWidth = True;
	
	vStructure = New Structure("Type, Group, Behavior, ShowTitle, Width, HorizontalStretch", FormGroupType.UsualGroup, ChildFormItemsGroup.AlwaysHorizontal, UsualGroupBehavior.Usual, False, 40, False);		
	tcOnServer.cmCreateItem(ThisObject, Items.PeriodGroup, "PeriodGroupDate", "FormGroup", vStructure);
	Items.Move(Items.CheckInDate, Items["FormGroupPeriodGroupDate"]);
	Items.Move(Items.Duration, Items["FormGroupPeriodGroupDate"]);
	Items.Move(Items.CheckOutDate, Items["FormGroupPeriodGroupDate"]);
	Items.Move(Items.SelRoomType, Items.PeriodGroup, Items.NumberOfPersons);
	Items.Move(Items["FormGroupPeriodGroupDate"], Items.PeriodGroup, Items.SelRoomType);
	Items.Move(Items.KidsGroup, Items.AdultsGroup);
	Items.Move(Items.IsForFolioSplit, Items.KidsGroup);
	Items.IsForFolioSplit.TitleLocation = FormItemTitleLocation.Right;
	Items.NumberOfPersons.Group = ChildFormItemsGroup.Vertical;
		
	Items.CheckInDate.HorizontalAlignInGroup = ItemHorizontalLocation.Center;
	Items.CheckInDate.HorizontalStretch = True;
	Items.Duration.HorizontalAlignInGroup = ItemHorizontalLocation.Center;
	Items.Duration.HorizontalStretch = True;
	Items.CheckOutDate.HorizontalAlignInGroup = ItemHorizontalLocation.Center;
	Items.CheckOutDate.HorizontalStretch = True;
	
	CommandBarLocation = FormCommandBarLabelLocation.Top; 
	vCommand = Commands.Add("ShowFilterGroup");
	vCommand.Action = "ShowFilterGroup";                                           
	vStructure = New Structure("CommandName, Representation, Picture", "ShowFilterGroup", ButtonRepresentation.Picture, PictureLib.FilterCriterion);		
	tcOnServer.cmCreateItem(ThisObject, CommandBar, "ShowFilterGroup", "FormButton", vStructure);
	Items.Move(Items.Refresh, CommandBar);
	Items.Move(Items.PrintImmediately, CommandBar);
	Items.Move(Items.Print, CommandBar);
	Items.Refresh.DefaultButton = True;
	Items.Refresh.Representation = ButtonRepresentation.Picture;
		
	vStructure = New Structure("Type, PagesRepresentation", FormGroupType.Pages, FormPagesRepresentation.None);		
	tcOnServer.cmCreateItem(ThisObject, ThisObject, "Pages", "FormGroup", vStructure);
	
	vStructure = New Structure("Type", FormGroupType.Page);		
	tcOnServer.cmCreateItem(ThisObject, Items["FormGroupPages"], "PageReport", "FormGroup", vStructure);
	Items.Move(Items.TabulationGroup, Items["FormGroupPageReport"]);
	Items.TabulationGroup.Behavior = UsualGroupBehavior.Usual;
	Items.TabulationGroup.Group = ChildFormItemsGroup.AlwaysHorizontal;
	Items.Move(Items.GroupReport, Items["FormGroupPageReport"]);
	vStructure = New Structure("Type, Group, Behavior, ShowTitle", FormGroupType.UsualGroup, ChildFormItemsGroup.AlwaysHorizontal, UsualGroupBehavior.Usual, False);		
	tcOnServer.cmCreateItem(ThisObject, Items["FormGroupPageReport"], "PageReportAction", "FormGroup", vStructure);
	vCommand = Commands.Add("AddToOrder");
	vCommand.Action = "ShowAddToOrder";
	vCommand.Title = NStr("en = 'Add to order'; de = 'Zur Bestellung'; ru = 'Добавить в заказ'");
	vStructure = New Structure("CommandName, Representation", "AddToOrder", ButtonRepresentation.Text);		
	tcOnServer.cmCreateItem(ThisObject, Items["FormGroupPageReportAction"], "AddToOrder", "FormButton", vStructure);
	Items["FormButtonAddToOrder"].HorizontalStretch = True;
	Items["FormButtonAddToOrder"].HorizontalAlignInGroup = ItemHorizontalLocation.Center;
	tcOnServer.cmCreateItem(ThisObject, Items.Report.ContextMenu, "AddToOrder1", "FormButton", vStructure);
	vCommand = Commands.Add("OrderBasket");
	vCommand.Action = "ShowOrderBasket";
	vCommand.Title = NStr("en = 'Basket'; de = 'Warenkorb'; ru = 'Корзина'");
	vStructure = New Structure("CommandName, Representation", "OrderBasket", ButtonRepresentation.Text);		
	tcOnServer.cmCreateItem(ThisObject, Items["FormGroupPageReportAction"], "OrderBasket", "FormButton", vStructure);
	Items["FormButtonOrderBasket"].HorizontalStretch = True;
	Items["FormButtonOrderBasket"].HorizontalAlignInGroup = ItemHorizontalLocation.Center;
	
	vStructure = New Structure("Type", FormGroupType.Page);		
	tcOnServer.cmCreateItem(ThisObject, Items["FormGroupPages"], "PageFormSettings", "FormGroup", vStructure);
	Items.OtherParam.Behavior = UsualGroupBehavior.Usual;
	Items.OtherParam.Group = ChildFormItemsGroup.Vertical;
	Items.Move(Items.OtherParam, Items["FormGroupPageFormSettings"]);
	Items.Move(Items.GroupModifiers,  Items["FormGroupPageFormSettings"]);
	Items.ShowPreliminary.CheckBoxType = CheckBoxType.Tumbler;
	Items.ShowCommitment.CheckBoxType = CheckBoxType.Tumbler;
	
	vStructure = New Structure("Type", FormGroupType.Page);		
	tcOnServer.cmCreateItem(ThisObject, Items["FormGroupPages"], "PageAddToOrder", "FormGroup", vStructure);
	Items.PeriodGroup.Behavior = UsualGroupBehavior.Usual;
	Items.PeriodGroup.Group = ChildFormItemsGroup.Vertical;
	Items.Move(Items.PeriodGroup, Items["FormGroupPageAddToOrder"]);
	
	vStructure = New Structure("Type", FormGroupType.Page);		
	tcOnServer.cmCreateItem(ThisObject, Items["FormGroupPages"], "PageOrderBasket", "FormGroup", vStructure);
	Items.GroupOrderBasket.Group = ChildFormItemsGroup.Vertical;
	Items.GroupOrderBasket.Behavior = UsualGroupBehavior.Usual;
	Items.Move(Items.SelectionsGroup, Items["FormGroupPageOrderBasket"]);
	
	vStructure = New Structure("Type, Group, Behavior, ShowTitle", FormGroupType.UsualGroup, ChildFormItemsGroup.AlwaysHorizontal, UsualGroupBehavior.Usual, False);		
	tcOnServer.cmCreateItem(ThisObject, Items["FormGroupPageAddToOrder"], "PageAddToOrderAction", "FormGroup", vStructure);
	tcOnServer.cmCreateItem(ThisObject, Items["FormGroupPageOrderBasket"], "PageOrderBasketAction", "FormGroup", vStructure);
	vCommand = Commands.Add("ShowReport");
	vCommand.Action = "ShowReport";
	vCommand.Title = NStr("en = 'Back'; de = 'Zurück'; ru = 'Назад'");
	vStructure = New Structure("CommandName, Representation", "ShowReport", ButtonRepresentation.Text);		
	tcOnServer.cmCreateItem(ThisObject, Items["FormGroupPageAddToOrderAction"], "ShowReport", "FormButton", vStructure);
	tcOnServer.cmCreateItem(ThisObject, Items["FormGroupPageOrderBasketAction"], "ShowReport1", "FormButton", vStructure);
	Items["FormButtonShowReport"].HorizontalStretch = True;
	Items["FormButtonShowReport"].HorizontalAlignInGroup = ItemHorizontalLocation.Center;
	Items["FormButtonShowReport1"].HorizontalStretch = True;
	Items["FormButtonShowReport1"].HorizontalAlignInGroup = ItemHorizontalLocation.Center;
	Items.Move(Items.AddToOrderBasket, Items["FormGroupPageAddToOrderAction"]);
	Items.AddToOrderBasket.HorizontalStretch = True;
	Items.AddToOrderBasket.HorizontalAlignInGroup = ItemHorizontalLocation.Center;
	Items.AddToOrderBasket.Representation = ButtonRepresentation.Text;
	vStructure = New Structure("CommandName, Representation", "OrderBasket", ButtonRepresentation.Text);		
	tcOnServer.cmCreateItem(ThisObject, Items["FormGroupPageAddToOrderAction"], "OrderBasket1", "FormButton", vStructure);
	Items["FormButtonOrderBasket1"].HorizontalStretch = True;
	Items["FormButtonOrderBasket1"].HorizontalAlignInGroup = ItemHorizontalLocation.Center;
EndProcedure // ChangeAttributesAtServer

// -------------------------------------------------------------------------------------------------
&AtClient
Procedure ShowFilterGroup()
	Items.FormButtonShowFilterGroup.Check = Not Items.FormButtonShowFilterGroup.Check;
	If Items.FormButtonShowFilterGroup.Check Then
		Items.FormGroupPages.CurrentPage = Items.FormGroupPageFormSettings;
	Else
		Items.FormGroupPages.CurrentPage = Items.FormGroupPageReport;	
	Endif;
EndProcedure // ShowFilterGroup

// -------------------------------------------------------------------------------------------------
&AtClient
Procedure ShowAddToOrder()
	Items.FormButtonShowFilterGroup.Check = False;
	CommandBarLocation = FormCommandBarLabelLocation.None;
	Items.FormGroupPages.CurrentPage = Items["FormGroupPageAddToOrder"];
EndProcedure // ShowAddToOrder

// -------------------------------------------------------------------------------------------------
&AtClient
Procedure ShowOrderBasket()
	Items.FormButtonShowFilterGroup.Check = False;
	CommandBarLocation = FormCommandBarLabelLocation.None;
	Items.FormGroupPages.CurrentPage = Items["FormGroupPageOrderBasket"];
EndProcedure // ShowOrderBasket

// -------------------------------------------------------------------------------------------------
&AtClient
Procedure ShowReport()
	Items.FormButtonShowFilterGroup.Check = False;
	CommandBarLocation = FormCommandBarLabelLocation.Top;
	Items.FormGroupPages.CurrentPage = Items["FormGroupPageReport"];
EndProcedure // ShowOrderBasket

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Function GetQueryResource(pQryHours, pShowReportsInBeds, pLastVacant, pResourceName = "")
	vVacant = 0;
	If pResourceName = "" Then
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
	ElsIf pResourceName = "Special" Then
		If pShowReportsInBeds Then
			If pQryHours.BedsVacant = Null Then
				vVacant = pLastVacant;
			ElsIf pQryHours.SpecialBedsVacant = Null Then
				vVacant = pQryHours.BedsVacant;
			Else
				vVacant = pQryHours.SpecialBedsVacant;
			EndIf;
		Else
			If pQryHours.RoomsVacant = Null Then
				vVacant = pLastVacant;
			ElsIf pQryHours.SpecialRoomsVacant = Null Then
				vVacant = pQryHours.RoomsVacant;
			Else
				vVacant = pQryHours.SpecialRoomsVacant;
			EndIf;
		EndIf;
	ElsIf pResourceName = "PreliminarySpecial" Then
		If pShowReportsInBeds Then
			If pQryHours.BedsVacant = Null Then
				vVacant = pLastVacant;
			ElsIf pQryHours.PreliminarySpecialBedsVacant = Null Then
				vVacant = pQryHours.BedsVacant;
			Else
				vVacant = pQryHours.PreliminarySpecialBedsVacant;
			EndIf;
		Else
			If pQryHours.RoomsVacant = Null Then
				vVacant = pLastVacant;
			ElsIf pQryHours.PreliminarySpecialRoomsVacant = Null Then
				vVacant = pQryHours.RoomsVacant;
			Else
				vVacant = pQryHours.PreliminarySpecialRoomsVacant;
			EndIf;
		EndIf;
	ElsIf pResourceName = "Preliminary" Then
		If pShowReportsInBeds Then
			If pQryHours.PreliminaryBeds = Null Then
				vVacant = 0;
			Else
				vVacant = pQryHours.PreliminaryBeds;
			EndIf;
		Else
			If pQryHours.PreliminaryRooms = Null Then
				vVacant = 0;
			Else
				vVacant = pQryHours.PreliminaryRooms;
			EndIf;
		EndIf;
	ElsIf pResourceName = "TotalSpecial" Then
		If pShowReportsInBeds Then
			If pQryHours.TotalSpecialBeds = Null Then
				vVacant = 0;
			Else
				vVacant = pQryHours.TotalSpecialBeds;
			EndIf;
		Else
			If pQryHours.TotalSpecialRooms = Null Then
				vVacant = 0;
			Else
				vVacant = pQryHours.TotalSpecialRooms;
			EndIf;
		EndIf;
	Else
		If pShowReportsInBeds Then
			If pQryHours.TotalBeds = Null Then
				vVacant = 0;
			Else
				vVacant = pQryHours.TotalBeds;
			EndIf;
		Else
			If pQryHours.TotalRooms = Null Then
				vVacant = 0;
			Else
				vVacant = pQryHours.TotalRooms;
			EndIf;
		EndIf;
	EndIf;
	Return vVacant;
EndFunction // GetQueryResource

// -----------------------------------------------------------------------------
&AtServer
Procedure NumberOfDaysOnChangeAtServer()
	If NumberOfDays < 1 Or NumberOfDays > 999 Then
		If ShowPrices Then
			NumberOfDays = 31;
		Else
			NumberOfDays = 62;
		EndIf;
	EndIf;
	If Not DoNotSaveSettings Then
		If ShowPrices Then
			SystemSettingsStorage.Save("NumberOfDaysShowPrices", "tcAvailableRoomsReport", NumberOfDays);
		Else
			SystemSettingsStorage.Save("NumberOfDays", "tcAvailableRoomsReport", NumberOfDays);
		EndIf;
	EndIf;
	BuildReport();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearCalculateButtonTitle()
	Items.CalculateButton.Title = NStr("en='Calculate'; ru='Рассчитать'; de='Berechnen'");
	Items.CalculateButton.ExtendedToolTip.Title = NStr("en = 'Calculate room price'; de = 'Berechnen Sie den Preis eines Zimmers'; ru = 'Рассчитать стоимость номера'");
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SetCalculateButtonTitle(pStrAmount)
	If IsBlankString(pStrAmount) Then
		Items.CalculateButton.Title = NStr("en='Calculate'; ru='Рассчитать'; de='Berechnen'");
		Items.CalculateButton.ExtendedToolTip.Title = NStr("en = 'Calculate room price'; de = 'Berechnen Sie den Preis eines Zimmers'; ru = 'Рассчитать стоимость номера'");
	Else
		Items.CalculateButton.Title = pStrAmount;
		vTooltipStr = NStr("en = 'The price of one room for '; de = 'Der Preis für ein Zimmer für '; ru = 'Цена одного номера за '");
		vTooltipStr = vTooltipStr+Duration+NStr("en = ' nights'; de = ' Nächte'; ru = ' ночей'");
		For Each rowAT In AccommodationTypesTable Do
			vTooltipStr = vTooltipStr+Chars.LF;
			vTooltipStr = vTooltipStr+Chars.Tab+rowAT.AccommodationType+": "+rowAT.Price;
		EndDo;
		Items.CalculateButton.ExtendedToolTip.Title = vTooltipStr;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillAvailabilityBreakdown()
	FillAvailabilityBreakdownAtServer();
EndProcedure // FillAvailabilityBreakdown

// -----------------------------------------------------------------------------
&AtServer
Procedure FillAvailabilityBreakdownAtServer()
	AvailabilityByHours.Clear();
	AvailabilityBreakdown.GetItems().Clear();
	// Do checks
	If Not ValueIsFilled(CurDate) Then
		Items.AvailabilityByHoursGroup.Visible = False;
		Items.AvailabilityBreakdownGroup.Visible = False;
		Return;
	EndIf;
	If Not ValueIsFilled(CurHotel) Or ValueIsFilled(CurHotel) And CurHotel.IsFolder Then
		Items.AvailabilityByHoursGroup.Visible = False;
		Items.AvailabilityBreakdownGroup.Visible = False;
		Return;
	EndIf;
	Items.AvailabilityByHoursGroup.Visible = True;
	Items.AvailabilityBreakdownGroup.Visible = True;
	// Reference hour
	vShiftInSeconds = ?(ValueIsFilled(RoomRate), -(RoomRate.ReferenceHour - BegOfDay(RoomRate.ReferenceHour)), -43200);
	vRoomQuotaIsSet = ValueIsFilled(RoomQuota);
	vDoWriteOff = ?(ValueIsFilled(RoomQuota), RoomQuota.DoWriteOff, False);
	vPeriodFrom = cm1SecondShift(BegOfDay(CurDate) - vShiftInSeconds);
	vPeriodTo = cm0SecondShift(vPeriodFrom + 24*3600);
	// Get data for the breakdown by hours
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	BEGINOFPERIOD(RoomInventoryBalanceAndTurnovers.Period, DAY) AS RealDate,
	|	HOUR(RoomInventoryBalanceAndTurnovers.Period) + 1 AS Hour, " +
		?(ValueIsFilled(CurRoomType), "RoomInventoryBalanceAndTurnovers.RoomType AS RoomType, ", "") + "
	|	RoomInventoryBalanceAndTurnovers.CounterClosingBalance AS Counter,
	|	RoomInventoryBalanceAndTurnovers.TotalRoomsClosingBalance AS TotalRooms,
	|	RoomInventoryBalanceAndTurnovers.TotalBedsClosingBalance AS TotalBeds,
	|	RoomInventoryBalanceAndTurnovers.RoomsVacantClosingBalance AS RoomsVacant,
	|	RoomInventoryBalanceAndTurnovers.BedsVacantClosingBalance AS BedsVacant
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			HOUR,
	|			RegisterRecordsAndPeriodBoundaries,
	|			Hotel = &qHotel " + 
		?(ValueIsFilled(CurRoomType), "AND RoomType IN HIERARCHY (&qRoomType)", "") + "
	|				AND NOT RoomType.IsVirtual
	|				AND NOT RoomType.DoesNotAffectRoomRevenueStatistics) AS RoomInventoryBalanceAndTurnovers
	|
	|ORDER BY
	|	RealDate,
	|	Hour";
	vQry.SetParameter("qHotel", CurHotel);
	vQry.SetParameter("qRoomType", CurRoomType);
	vQry.SetParameter("qShiftInSeconds", vShiftInSeconds);
	vQry.SetParameter("qPeriodFrom", vPeriodFrom);
	vQry.SetParameter("qPeriodTo", New Boundary(vPeriodTo, BoundaryType.Excluding));
	vInventoryAvailability = vQry.Execute().Unload();
	
	vAllotmentAvailability = New ValueTable();
	If vRoomQuotaIsSet Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	BEGINOFPERIOD(RoomQuotaSalesBalanceAndTurnovers.Period, DAY) AS RealDate,
		|	HOUR(RoomQuotaSalesBalanceAndTurnovers.Period) + 1 AS Hour, " + 
			?(ValueIsFilled(CurRoomType), "RoomQuotaSalesBalanceAndTurnovers.RoomType AS RoomType,", "") + "
		|	RoomQuotaSalesBalanceAndTurnovers.CounterClosingBalance AS AllotmentCounter,
		|	RoomQuotaSalesBalanceAndTurnovers.RoomsInQuotaClosingBalance AS RoomsInQuota,
		|	RoomQuotaSalesBalanceAndTurnovers.BedsInQuotaClosingBalance AS BedsInQuota,
		|	RoomQuotaSalesBalanceAndTurnovers.RoomsRemainsClosingBalance AS RoomsRemains,
		|	RoomQuotaSalesBalanceAndTurnovers.BedsRemainsClosingBalance AS BedsRemains
		|FROM
		|	AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
		|			&qPeriodFrom,
		|			&qPeriodTo,
		|			HOUR,
		|			RegisterRecordsAndPeriodBoundaries,
		|			Hotel = &qHotel " + 
						?(ValueIsFilled(CurRoomType), "AND RoomType IN HIERARCHY (&qRoomType)", "") + "
		|				AND NOT RoomType.IsVirtual
		|				AND NOT RoomType.DoesNotAffectRoomRevenueStatistics
		|				AND RoomQuota = &qRoomQuota) AS RoomQuotaSalesBalanceAndTurnovers
		|ORDER BY
		|	RealDate,
		|	Hour";
		vQry.SetParameter("qHotel", CurHotel);
		vQry.SetParameter("qRoomType", CurRoomType);
		vQry.SetParameter("qRoomQuota", RoomQuota);
		vQry.SetParameter("qShiftInSeconds", vShiftInSeconds);
		vQry.SetParameter("qPeriodFrom", vPeriodFrom);
		vQry.SetParameter("qPeriodTo", New Boundary(vPeriodTo, BoundaryType.Excluding));
		vAllotmentAvailability = vQry.Execute().Unload();
	EndIf;
	
	// Fill table with balances
	vRow = AvailabilityByHours.Add();
	If ValueIsFilled(CurRoomType) Then
		vRow.RoomType = CurRoomType;
	ElsIf ValueIsFilled(CurHotel) Then
		vRow.RoomType = CurHotel;
	Else
		vRow.RoomType = Undefined;
	EndIf;
	vRow.AccountingDate = BegOfDay(CurDate);
	
	vCurAvailability = 0;
	vCurHour = Hour(vPeriodFrom) + 1;
	vVacant = 0;
	vRemains = 0;
	For i = 1 To 24 Do
		Items["AvailabilityByHoursHour" + i].Title = Format(vCurHour, "ND=2; NFD=0; NZ=; NLZ=; NG=") + ":00";
		
		vCurAvailability = 0;
		vInventoryAvailabilityRow = vInventoryAvailability.Find(vCurHour, "Hour");
		If vInventoryAvailabilityRow <> Undefined Then
			If ShowInBeds Then
				vVacant = vInventoryAvailabilityRow.BedsVacant;
			Else
				vVacant = vInventoryAvailabilityRow.RoomsVacant;
			EndIf;
		EndIf;
		If vRoomQuotaIsSet Then
			vAllotmentAvailabilityRow = vAllotmentAvailability.Find(vCurHour, "Hour");
			If vAllotmentAvailabilityRow <> Undefined Then
				If ShowInBeds Then
					vRemains = vAllotmentAvailabilityRow.BedsRemains;
				Else
					vRemains = vAllotmentAvailabilityRow.RoomsRemains;
				EndIf;
			EndIf;
			
			If vDoWriteOff Then
				vCurAvailability = vRemains;
			Else
				If vVacant < vRemains Then
					vCurAvailability = vVacant;
				Else
					vCurAvailability = vRemains;
				EndIf;
			EndIf;
		Else
			vCurAvailability = vVacant;
		EndIf;
		vRow["Hour" + i] = vCurAvailability;
		
		vCurHour = vCurHour + 1;
		If vCurHour = 25 Then
			vCurHour = 1;
		EndIf;
	EndDo;
	
	// Get breakdown details
	vPeriodTo = EndOfDay(CurDate);
	If CurTime <> 0 Then
		vFirstTime = Number(Left(Items.AvailabilityByHoursHour1.Title, 2));
		If vFirstTime > CurTime Then
			vPeriodTo = BegOfDay(CurDate) + (CurTime + 24)*3600 - 1;
		Else
			vPeriodTo = BegOfDay(CurDate) + CurTime*3600 - 1;
		EndIf;
	EndIf;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInventoryMovements.Recorder AS Recorder,
	|	MAX(RoomInventoryMovements.Period) AS PeriodFrom
	|INTO EffectivePeriodsByRecorders
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventoryMovements
	|WHERE
	|	RoomInventoryMovements.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND RoomInventoryMovements.Period <= &qPeriodTo
	|	AND RoomInventoryMovements.PeriodFrom <= &qPeriodTo
	|	AND RoomInventoryMovements.PeriodTo > &qPeriodTo
	|	AND (RoomInventoryMovements.IsReservation
	|			OR RoomInventoryMovements.IsAccommodation)
	|	AND RoomInventoryMovements.Hotel = &qHotel
	|	AND (RoomInventoryMovements.RoomQuota IN HIERARCHY (&qRoomQuota)
	|			OR &qIsEmptyRoomQuota) " +
		?(ValueIsFilled(CurRoomType), "AND RoomInventoryMovements.RoomType IN HIERARCHY(&qRoomType)", "") + "
	|
	|GROUP BY
	|	RoomInventoryMovements.Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExpectedGuestGroupsTurnovers.GuestGroup AS GuestGroup,
	|	ExpectedGuestGroupsTurnovers.RoomsReservedTurnover AS PreliminaryRooms,
	|	ExpectedGuestGroupsTurnovers.BedsReservedTurnover AS PreliminaryBeds
	|INTO PreliminaryReservations
	|FROM
	|	AccumulationRegister.ExpectedGuestGroups.Turnovers(
	|			&qTentativePeriodFrom,
	|			&qTentativePeriodTo,
	|			Day,
	|			&qShowPreliminary
	|				AND Hotel = &qHotel " + 
					?(ValueIsFilled(CurRoomType), "AND RoomType IN HIERARCHY (&qRoomType)", "") + "
	|				AND CASE
	|						WHEN RoomQuota = VALUE(Catalog.RoomQuotas.EmptyRef) 
	|							THEN TRUE
	|						WHEN GuestGroup <> VALUE(Catalog.GuestGroups.EmptyRef) 
	|							THEN TRUE
	|						WHEN NOT ISNULL(RoomQuota.DoWriteOff, FALSE)
	|							THEN TRUE
	|						ELSE
	|							FALSE
	|					END 
	|				AND CASE
	|						WHEN &qIsEmptyRoomQuota
	|							THEN TRUE
	|						WHEN RoomQuota IN HIERARCHY (&qRoomQuota)
	|							THEN TRUE
	|						ELSE
	|							FALSE
	|					END) AS ExpectedGuestGroupsTurnovers
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventory.RecordType AS Type,
	|	RoomInventory.Ref AS Ref,
	|	CASE
	|		WHEN RoomInventory.Ref REFS Catalog.Hotels
	|			THEN RoomInventory.Ref.SortCode
	|		WHEN RoomInventory.Ref REFS Catalog.RoomQuotas
	|			THEN RoomInventory.Ref.SortCode
	|		WHEN RoomInventory.Ref REFS Catalog.RoomBlockTypes
	|			THEN RoomInventory.Ref.SortCode
	|		WHEN RoomInventory.Ref REFS Catalog.GuestGroups
	|			THEN RoomInventory.Ref.Code
	|		ELSE """"
	|	END AS RefSortCode,
	|	CASE
	|		WHEN RoomInventory.Ref REFS Catalog.Hotels
	|			THEN RoomInventory.Ref.Description
	|		WHEN RoomInventory.Ref REFS Catalog.RoomQuotas
	|			THEN RoomInventory.Ref.Description
	|		WHEN RoomInventory.Ref REFS Catalog.RoomBlockTypes
	|			THEN RoomInventory.Ref.Description
	|		WHEN RoomInventory.Ref REFS Catalog.GuestGroups
	|			THEN """"
	|		ELSE """"
	|	END AS RefDescription,
	|	RoomInventory.Rooms AS Rooms,
	|	RoomInventory.Beds AS Beds,
	|	RoomInventory.PreliminaryRooms AS PreliminaryRooms,
	|	RoomInventory.PreliminaryBeds AS PreliminaryBeds,
	|	RoomInventory.NotPickedUpRooms AS NotPickedUpRooms,
	|	RoomInventory.NotPickedUpBeds AS NotPickedUpBeds
	|FROM
	|	(SELECT
	|		RoomInventoryMovements.Ref AS Ref,
	|		RoomInventoryMovements.RecordType AS RecordType,
	|		SUM(RoomInventoryMovements.Rooms) AS Rooms,
	|		SUM(RoomInventoryMovements.Beds) AS Beds,
	|		SUM(RoomInventoryMovements.PreliminaryRooms) AS PreliminaryRooms,
	|		SUM(RoomInventoryMovements.PreliminaryBeds) AS PreliminaryBeds,
	|		SUM(RoomInventoryMovements.NotPickedUpRooms) AS NotPickedUpRooms,
	|		SUM(RoomInventoryMovements.NotPickedUpBeds) AS NotPickedUpBeds
	|	FROM
	|		(SELECT
	|			AvailableRooms.Hotel AS Ref,
	|			1 AS RecordType,
	|			ISNULL(AvailableRooms.TotalRoomsBalance, 0) AS Rooms,
	|			ISNULL(AvailableRooms.TotalBedsBalance, 0) AS Beds,
	|			0 AS PreliminaryRooms,
	|			0 AS PreliminaryBeds,
	|			0 AS NotPickedUpRooms,
	|			0 AS NotPickedUpBeds
	|		FROM
	|			AccumulationRegister.RoomInventory.Balance(
	|					&qPeriodTo,
	|					&qIsEmptyRoomQuota " +
						?(ValueIsFilled(CurRoomType), "AND RoomType IN HIERARCHY (&qRoomType)", "") + "
	|						AND Hotel = &qHotel) AS AvailableRooms
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			RoomBlocks.RoomBlockType,
	|			2,
	|			ISNULL(RoomBlocks.RoomsBlockedBalance, 0),
	|			ISNULL(RoomBlocks.BedsBlockedBalance, 0),
	|			0,
	|			0,
	|			0,
	|			0
	|		FROM
	|			AccumulationRegister.RoomBlocks.Balance(
	|					&qPeriodTo,
	|					&qIsEmptyRoomQuota " +
						?(ValueIsFilled(CurRoomType), "AND RoomType IN HIERARCHY (&qRoomType)", "") + "
	|						AND Hotel = &qHotel) AS RoomBlocks
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			RoomQuotas.RoomQuota,
	|			3,
	|			ISNULL(RoomQuotas.RoomsRemainsBalance, 0),
	|			ISNULL(RoomQuotas.BedsRemainsBalance, 0),
	|			0,
	|			0,
	|			0,
	|			0
	|		FROM
	|			AccumulationRegister.RoomQuotaSales.Balance(
	|					&qPeriodTo,
	|					RoomQuota.DoWriteOff " + 
						?(ValueIsFilled(CurRoomType), "AND RoomType IN HIERARCHY (&qRoomType)", "") + "
	|						AND Hotel = &qHotel
	|						AND (RoomQuota IN HIERARCHY (&qRoomQuota)
	|							OR &qIsEmptyRoomQuota)
	|						AND RoomQuota.DoWriteOff
	|						AND NOT RoomQuota.IsCommitment) AS RoomQuotas
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			RoomQuotas.RoomQuota,
	|			4,
	|			ISNULL(RoomQuotas.RoomsRemainsBalance, 0),
	|			ISNULL(RoomQuotas.BedsRemainsBalance, 0),
	|			0,
	|			0,
	|			0,
	|			0
	|		FROM
	|			AccumulationRegister.RoomQuotaSales.Balance(
	|					&qPeriodTo,
	|					RoomQuota.DoWriteOff " + 
						?(ValueIsFilled(CurRoomType), "AND RoomType IN HIERARCHY (&qRoomType)", "") + "
	|						AND Hotel = &qHotel
	|						AND (RoomQuota IN HIERARCHY (&qRoomQuota)
	|							OR &qIsEmptyRoomQuota)
	|						AND RoomQuota.DoWriteOff
	|						AND RoomQuota.IsCommitment) AS RoomQuotas
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			Reservations.GuestGroup,
	|			CASE
	|				WHEN Reservations.GuestGroup.GroupType = VALUE(Catalog.GroupTypes.EmptyRef)
	|					THEN 6
	|				ELSE 5
	|			END,
	|			Reservations.RoomsVacant,
	|			Reservations.BedsVacant,
	|			0,
	|			0,
	|			CASE
	|				WHEN Reservations.Recorder.RoomQuantity > 1
	|					THEN Reservations.RoomsVacant
	|				ELSE 0
	|			END,
	|			CASE
	|				WHEN Reservations.Recorder.RoomQuantity > 1
	|					THEN Reservations.BedsVacant
	|				ELSE 0
	|			END
	|		FROM
	|			AccumulationRegister.RoomInventory AS Reservations
	|				INNER JOIN EffectivePeriodsByRecorders AS EffectivePeriodsByRecorders
	|				ON Reservations.Recorder = EffectivePeriodsByRecorders.Recorder
	|					AND Reservations.Period = EffectivePeriodsByRecorders.PeriodFrom
	|		WHERE
	|			Reservations.RecordType = VALUE(AccumulationRecordType.Expense) " + 
				?(ValueIsFilled(CurRoomType), "AND Reservations.RoomType IN HIERARCHY(&qRoomType)", "") + "
	|			AND Reservations.IsReservation
	|			AND Reservations.Hotel = &qHotel
	|			AND (Reservations.RoomQuota IN HIERARCHY (&qRoomQuota)
	|					OR &qIsEmptyRoomQuota)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			PreliminaryReservations.GuestGroup,
	|			CASE
	|				WHEN PreliminaryReservations.GuestGroup.GroupType = VALUE(Catalog.GroupTypes.EmptyRef)
	|					THEN 6
	|				ELSE 5
	|			END,
	|			0,
	|			0,
	|			PreliminaryReservations.PreliminaryRooms,
	|			PreliminaryReservations.PreliminaryBeds,
	|			0,
	|			0
	|		FROM
	|			PreliminaryReservations AS PreliminaryReservations
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			Accommodations.GuestGroup,
	|			CASE
	|				WHEN Accommodations.GuestGroup.GroupType = VALUE(Catalog.GroupTypes.EmptyRef)
	|					THEN 6
	|				ELSE 5
	|			END,
	|			Accommodations.RoomsVacant,
	|			Accommodations.BedsVacant,
	|			0,
	|			0,
	|			0,
	|			0
	|		FROM
	|			AccumulationRegister.RoomInventory AS Accommodations
	|				INNER JOIN EffectivePeriodsByRecorders AS EffectivePeriodsByRecorders
	|				ON Accommodations.Recorder = EffectivePeriodsByRecorders.Recorder
	|					AND Accommodations.Period = EffectivePeriodsByRecorders.PeriodFrom
	|		WHERE
	|			Accommodations.RecordType = VALUE(AccumulationRecordType.Expense) " + 
				?(ValueIsFilled(CurRoomType), "AND Accommodations.RoomType IN HIERARCHY(&qRoomType)", "") + " 
	|			AND Accommodations.IsAccommodation
	|			AND Accommodations.Hotel = &qHotel
	|			AND (Accommodations.RoomQuota IN HIERARCHY (&qRoomQuota)
	|					OR &qIsEmptyRoomQuota)) AS RoomInventoryMovements
	|	
	|	GROUP BY
	|		RoomInventoryMovements.RecordType,
	|		RoomInventoryMovements.Ref) AS RoomInventory
	|
	|ORDER BY
	|	Type,
	|	RefSortCode,
	|	RefDescription";
	vQry.SetParameter("qHotel", CurHotel);
	vQry.SetParameter("qRoomType", CurRoomType);
	vQry.SetParameter("qRoomQuota", RoomQuota);
	vQry.SetParameter("qIsEmptyRoomQuota", Not ValueIsFilled(RoomQuota));
	vQry.SetParameter("qPeriodTo", vPeriodTo);
	vQry.SetParameter("qTentativePeriodFrom", BegOfDay(vPeriodTo));
	vQry.SetParameter("qTentativePeriodTo", EndOfDay(vPeriodTo));
	vQry.SetParameter("qShowPreliminary", ShowPreliminary);
	vDetails = vQry.Execute().Unload();
	// Fill table with details
	vCurType = 0;
	For Each vDetailsRow In vDetails Do
		If vCurType <> vDetailsRow.Type Then
			vCurType = vDetailsRow.Type;
			vRow = AvailabilityBreakdown.GetItems().Add();
			If vCurType = 1 Then
				vRow.Description = NStr("en='Total rooms for '; ru='Всего номеров на '; de='Total Zimmer für '") + Format(?(CurTime = 0 Or CurTime = 24, vPeriodTo, vPeriodTo + 1), "DF='HH:mm dd.MM.yyyy'");
			ElsIf vCurType = 2 Then
				vRow.Description = NStr("en='Blocked rooms'; ru='Блокировки'; de='Blockierte Zimmer'");
			ElsIf vCurType = 3 Then
				vRow.Description = NStr("en='Allotment'; ru='Квоты'; de='Allotments'");
			ElsIf vCurType = 4 Then
				vRow.Description = NStr("en='Commitment'; ru='Жесткие квоты'; de='Commitment'");
			ElsIf vCurType = 5 Then
				vRow.Description = NStr("en='Groups'; ru='Группы'; de='Gruppen'");
			ElsIf vCurType = 6 Then
				vRow.Description = NStr("en='Reservations'; ru='Брони'; de='Reservierungen'");
			EndIf;
		EndIf;
		vRow.Quantity = vRow.Quantity + ?(ShowInBeds, vDetailsRow.Beds, vDetailsRow.Rooms);
		If vCurType = 5 Or vCurType = 6 Then
			vRow.TentativeQuantity = vRow.TentativeQuantity + ?(ShowInBeds, vDetailsRow.PreliminaryBeds, vDetailsRow.PreliminaryRooms);
		EndIf;
		vSubRow = vRow.GetItems().Add();
		vSubRow.Description = "";
		If vCurType = 1 Then
			vSubRow.Ref = ?(ValueIsFilled(CurRoomType), CurRoomType, ?(ValueIsFilled(CurHotel), CurHotel, vDetailsRow.Ref));
		Else
			vSubRow.Ref = vDetailsRow.Ref;
		EndIf;
		vSubRow.Quantity = vSubRow.Quantity + ?(ShowInBeds, vDetailsRow.Beds, vDetailsRow.Rooms);
		If vCurType = 5 Or vCurType = 6 Then
			vSubRow.GuestGroup = vDetailsRow.Ref;
			vSubRow.NotPickedUpQuantity = vSubRow.NotPickedUpQuantity + ?(ShowInBeds, vDetailsRow.NotPickedUpBeds, vDetailsRow.NotPickedUpRooms);
			vSubRow.TentativeQuantity = vSubRow.TentativeQuantity + ?(ShowInBeds, vDetailsRow.PreliminaryBeds, vDetailsRow.PreliminaryRooms);
		EndIf;
	EndDo;
EndProcedure // FillAvailabilityBreakdownAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure AttachSelectionContextMenu()
	vContextMenu = Items.ReportContextMenu;
	vActionNext = Items.Add("ActionNext", Type("FormButton"), Items.Report.ContextMenu);
	vActionNext.CommandName = "NextPeriodButton";
	ActionPrev = Items.Add("ActionPrev", Type("FormButton"), Items.Report.ContextMenu);
	ActionPrev.CommandName = "PrevPeriodButton";
EndProcedure // AttachSelectionContextMenu

// -----------------------------------------------------------------------------
&AtServer
Function CheckFields()
	vIsError = False;
	If Not ValueIsFilled(SelRoomType) Then
		vMessage = New UserMessage;
		vMessage.Text = NStr("en='Fill the field (Room type)';ru='Заполните поле (Тип номера)';de='Feld ausfüllen (Zimmertyp)'");
		vMessage.TargetID = UUID;
		vMessage.Field = "SelRoomType";
		vMessage.DataKey = DataKey.Ref;
		vMessage.Message();
		vIsError = True;
	ElsIf SelRoomType.IsFolder Then
		vMessage = New UserMessage;
		vMessage.Text = NStr("en='You have selected room types folder! It is not allowed.';ru='Выбрали папку типов номеров! Это запрещено.';de='Sie haben einen Zimmertypgruppe ausgewählt! Es ist verboten.'");
		vMessage.TargetID = UUID;
		vMessage.Field = "SelRoomType";
		vMessage.DataKey = DataKey.Ref;
		vMessage.Message();
		vIsError = True;
	EndIf;
	If Not ValueIsFilled(CheckInDate) Then
		vMessage = New UserMessage;
		vMessage.Field = "CheckInDate";
		vMessage.TargetID = UUID;
		vMessage.Text = NStr("en='Fill the field (Check-in date)';ru='Заполните поле (Дата заезда)';de='Feld ausfüllen (Anreisedatum)'");
		vMessage.DataKey = DataKey.Ref;
		vMessage.Message();
		vIsError = True;
	Else
		If Not cmCheckUserPermissions("HavePermissionToCreateReservationsInThePast") Then
			vCurrentDate = BegOfDay(CurrentSessionDate());
			If ValueIsFilled(Hotel) And ValueIsFilled(Hotel.AccountingDate) Then
				vCurrentDate = Hotel.AccountingDate;
			EndIf;
			If BegOfDay(CheckInDate) < vCurrentDate Then
				vMessage = New UserMessage;
				vMessage.Field = "CheckInDate";
				vMessage.TargetID = UUID;
				vMessage.Text = NStr("en='You do not have rights to create reservation in the past!'; ru='Нет прав создавать бронь в прошлом!'; de='Sie haben keine Berechtigung, in der Vergangenheit Reservierungen vorzunehmen!'");
				vMessage.DataKey = DataKey.Ref;
				vMessage.Message();
				vIsError = True;
			EndIf;
		EndIf;
	EndIf;
	If Not ValueIsFilled(CheckOutDate) Then
		vMessage = New UserMessage;
		vMessage.Field = "CheckOutDate";
		vMessage.TargetID = UUID;
		vMessage.Text = NStr("en='Fill the field (Check-out date)';ru='Заполните поле (Дата выезда)';de='Feld ausfüllen (Abreisedatum)'");
		vMessage.DataKey = DataKey.Ref;
		vMessage.Message();
		vIsError = True;
	EndIf;
	If NumberOfAdults = 0 And NumberOfKids = 0 Then
		NumberOfAdults = 1;
	EndIf;
	If NumberOfKids <> 0 Then
		Try
			For vInd = 1 To NumberOfKids Do
				If Not ValueIsFilled(ThisObject["KidAge" + String(vInd)]) Then
					vMessage = New UserMessage;
					vMessage.Field = "KidAge" + String(vInd);
					vMessage.TargetID = UUID;
					vMessage.Text = NStr("en='Enter age of kid';ru='Введите возраст ребенка';de='Geben Sie das Alter des Kindes ein'");
					vMessage.DataKey = DataKey.Ref;
					vMessage.Message();
					vIsError = True;
				EndIf;
			EndDo;
		Except
		EndTry;
	EndIf;
	// Get list of allowed room rates
	Items.AllowedRoomRates.Visible = False;
	If Not vIsError Then
		vAllowedRoomRates = cmGetAllowedRoomRates(CheckInDate, CheckOutDate, CurrentSessionDate(), SelRoomType, Hotel);
		If vAllowedRoomRates.FindByValue(RoomRate) = Undefined Then
			AllowedRoomRates.Clear();
			AllowedRoomRates.LoadValues(vAllowedRoomRates.UnloadValues());
			AllowedRoomRates.Insert(0, Catalogs.RoomRates.EmptyRef(), NStr("en='<Select valid rate below>'; ru='<Выберите ниже допустимый тариф>'; de='<Wählen Sie unten gültige Tarif aus>'"));
			Items.AllowedRoomRates.Visible = True;
			// Message
			vMessage = New UserMessage;
			vMessage.Field = "RoomRate";
			vMessage.TargetID = UUID;
			vMessage.Text = NStr("en='Room rate could not be used for the current booking paramters! Select room rate from the list of valid rates.';
			                     |ru='Тариф не может быть использован для текущих параметров бронирования! Выберите тариф из списка доступных.';
								 |de='Tarif konnte nicht für die aktuellen buchungsparameter verwendet werden! Wählen Sie einen tarif aus der Liste der verfügbaren.'");
			vMessage.DataKey = DataKey.Ref;
			vMessage.Message();
			vIsError = True;
		EndIf;
	EndIf;
	If vIsError Then
		Return False;
	Else
		Return True;
	EndIf;
EndFunction // CheckFields

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearSkipOnActivateArea()
	SkipOnActivateArea = False;
EndProcedure // ClearSkipOnActivateArea

// -----------------------------------------------------------------------------
&AtServer
Procedure AddKidAgeAttributes(pNumberOfFields)
	vTempArray = New Array;
	For vInd = 1 To pNumberOfFields Do
		vTempArray.Add(New FormAttribute("KidAge" + String(NumberOfKidAgeFields + vInd), New TypeDescription("Number")));
	EndDo;
	ChangeAttributes(vTempArray);	
	For vInd = 1 To pNumberOfFields Do
		vNewField = Items.Add("KidAge" + String(NumberOfKidAgeFields+vInd), Type("FormField"), Items.KidsGroup);
		vNewField.Type = FormFieldType.InputField;
		vNewField.HorizontalAlign = ItemHorizontalLocation.Center;
		vNewField.Width = 2;
		vNewField.TitleLocation = FormItemTitleLocation.None;
		vNewField.DataPath = "KidAge" + String(NumberOfKidAgeFields + vInd);
	EndDo;
	NumberOfKidAgeFields = NumberOfKidAgeFields + pNumberOfFields;
EndProcedure // AddKidAgeAttributes

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetMonthNameAtServer(pMonth)
	Return cmGetMonthName(pMonth, True) + ".";
EndFunction // GetMonthNameAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure GetPrice(pAccommodationTypes = Undefined, pIsReservation = False)
	// Build array of kid ages
	vAgeArray = New Array;
	For vInd = 1 To NumberOfKids Do
		Try
			vAge = ThisObject["KidAge" + String(vInd)];
			vAgeArray.Add(vAge);
		Except
		EndTry;
	EndDo;
	
	vGuestsQuantity = NumberOfAdults + NumberOfKids;
	
	// Get available room types
	vRoomTypes = cmGetRoomTypesByGuestQuantity(vGuestsQuantity, Catalogs.RoomTypes.EmptyRef(), Hotel);
	
	// Get default customer
	vCustomer = Undefined;
	vContract = Undefined;
	vCurUser = SessionParameters.CurrentUser;
	If ValueIsFilled(vCurUser.Customer) Then
		vCustomer = vCurUser.Customer;
	Else
		If ValueIsFilled(DefaultContract) Then
			vCustomer = DefaultContract.Owner;
			vContract = DefaultContract;
		EndIf;
	EndIf;
	
	// Get room type prices
	vCurRoomTypeAccTypes = Undefined;
	
	// Probe document object to calculate prices
	vProbeResObj = Documents.Reservation.CreateDocument();
	vProbeResObj.Hotel = Hotel;
	vProbeResObj.pmFillAttributesWithDefaultValues(True);
	vProbeResObj.RoomQuota = RoomQuota;
	vProbeResObj.ClientType = ClientType;
	vProbeResObj.ServicePackage = MealBoardTerm;
	
	vAccommodationTemplate = Undefined;
	
	vRoomTypeBalances = cmGetRoomTypeBalancesTable(vRoomTypes, False, Hotel, CheckInDate, CheckOutDate, ClientType, vCustomer, vContract, DiscountType, , , , SelRoomType, RoomRate, pAccommodationTypes, NumberOfAdults, NumberOfKids, vAgeArray, vProbeResObj, IsForFolioSplit, MealBoardTerm, vAccommodationTemplate);
	If vRoomTypeBalances <> Undefined Then
		vCurRoomTypeAccTypes = vRoomTypeBalances.FindRows(New Structure("RoomType", SelRoomType));
		If vCurRoomTypeAccTypes.Count() = 0 Then
			vCurRoomTypeAccTypes = vRoomTypeBalances.FindRows(New Structure("RoomType", Catalogs.RoomTypes.EmptyRef()));
		Else           
			If ValueIsFilled(vCurRoomTypeAccTypes[0].AccommodationTemplate) Then
				vAccommodationTemplate = vCurRoomTypeAccTypes[0].AccommodationTemplate;
			EndIf;
		EndIf;
		GuestTable.Clear();
		vInd = 0;
		For Each vRow In AccommodationTypesTable Do
			If ValueIsFilled(vRow.GuestName) Then
				vNewGuest = GuestTable.Add();
				vNewGuest.RowNumber = vInd;
				vNewGuest.GuestName = vRow.GuestName;
				vNewGuest.GuestRef = vRow.GuestRef;
				vNewGuest.DateOfBirth = vRow.DateOfBirth;
			EndIf;
			vInd = vInd + 1;
		EndDo;
	EndIf;
	
	AccommodationTemplate = vAccommodationTemplate;
	
	// Build table with accommodation types received
	AccommodationTypesTable.Clear();
	
	vAmount = 0;
	vCurrency = Catalogs.Currencies.EmptyRef();
	vRU = Catalogs.Currencies.FindByCode(643);
	vIndex = 0;
	If vCurRoomTypeAccTypes <> Undefined Then
		For Each vCurRoomTypeAccTypesRow In vCurRoomTypeAccTypes Do
			vNewStr = AccommodationTypesTable.Add();
			vNewStr.AccommodationType = vCurRoomTypeAccTypesRow.AccommodationType;
			vNewStr.Price = cmFormatSum(vCurRoomTypeAccTypesRow.Amount, ?(ValueIsFilled(vCurRoomTypeAccTypesRow.Currency), vCurRoomTypeAccTypesRow.Currency, vRU));
			vNewStr.Icon = ?(ValueIsFilled(vCurRoomTypeAccTypesRow.AccommodationType.AllowedClientAgeTo), PictureLib.Child, PictureLib.Adult);
			vNewStr.RowIndex = vIndex;
			vIndex = vIndex + 1;
			vAmount = vAmount + vCurRoomTypeAccTypesRow.Amount;
			vCurrency = vCurRoomTypeAccTypesRow.Currency;
		EndDo;
	EndIf;
	
	vAccommodationTypesTableRowsCount = AccommodationTypesTable.Count();
	If vAccommodationTypesTableRowsCount > 0 Then
		For Each vGuestTableRow In GuestTable Do
			If vGuestTableRow.RowNumber < vAccommodationTypesTableRowsCount Then
				vAccTypesTableRow = AccommodationTypesTable.Get(vGuestTableRow.RowNumber);
				vAccTypesTableRow.GuestName = vGuestTableRow.GuestName;
				vAccTypesTableRow.GuestRef = vGuestTableRow.GuestRef;
				vAccTypesTableRow.DateOfBirth = vGuestTableRow.DateOfBirth;
			EndIf;
		EndDo;
	EndIf;
	strCalculatedAmount = cmFormatSum(vAmount, ?(ValueIsFilled(vCurrency), vCurrency, vRU));
	Items.AccommodationTypesTablePrice.FooterText = strCalculatedAmount;
	SetCalculateButtonTitle(strCalculatedAmount);

	Amount = vAmount;
	
	// Fill total amounts
	If Not pIsReservation Then
		vTotalPriceTable = New ValueTable;
		vTotalPriceTable.Columns.Add("RoomType", cmGetCatalogTypeDescription("RoomTypes"));
		vTotalPriceTable.Columns.Add("Total", cmGetNumberTypeDescription(10, 0));
		vTotalPriceTable.Columns.Add("Currency", cmGetCatalogTypeDescription("Currencies"));
		vTotal = 0;
		vLastRT = Undefined;
		If vRoomTypeBalances <> Undefined Then
			For Each vRow In vRoomTypeBalances Do
				// Add total row
				If vLastRT <> vRow.RoomType Then
					vNewTotal = vTotalPriceTable.Add();
					If Not ValueIsFilled(vRow.RoomType) Then
						vNewTotal.RoomType = SelRoomType;
					Else
						vNewTotal.RoomType = vRow.RoomType;
					EndIf;
					vNewTotal.Currency = vRow.Currency;
					vLastRT = vRow.RoomType;
					vTotal = 0;
				EndIf;
				vTotal = vTotal + vRow.Amount;
				vNewTotal.Total = vTotal;
			EndDo;
		EndIf;
		
		vRepRow = 5;
		While True Do
			vRTCell = Report.Area(vRepRow, 1, vRepRow, 1);
			If TrimAll(vRTCell.Text) = "" Then
				Break;
			EndIf;
			vDetailsStruct = vRTCell.Details;
			If TypeOf(vDetailsStruct) = Type("Structure") Then
				If vDetailsStruct.Property("RoomType") And ValueIsFilled(vDetailsStruct.RoomType) And TypeOf(vDetailsStruct.RoomType) = Type("CatalogRef.RoomTypes") Then
					vRTTotalCell = Report.Area(vRepRow, 2, vRepRow, 2);
					vRTTotalCell.Text = "";
					For Each vRT In vTotalPriceTable Do
						If vRT.RoomType = vDetailsStruct.RoomType Then
							vRTTotalCell.Text = cmFormatSum(vRT.Total, vRT.Currency, "NZ =0,00");
							Break;
						EndIf;
					EndDo;
				EndIf;
			EndIf;
			vRepRow = vRepRow + 1;
		EndDo;
	EndIf;
	
	// Remove folios created by documents
	If vProbeResObj <> Undefined Then
		For Each vCRRow In vProbeResObj.ChargingRules Do
			vFolioObj = vCRRow.ChargingFolio.GetObject();
			vFolioObj.Delete();
		EndDo;
		vProbeResObj = Undefined;
	EndIf;
EndProcedure // GetPrice

// -----------------------------------------------------------------------------
&AtServer
Procedure RecalculateOrderRowPriceAtServer(pOrderRow)
	// Build array of kid ages
	vAgeArray = New Array;
	For vInd = 1 To pOrderRow.NumberOfKids Do
		Try
			vAge = pOrderRow["KidAge" + String(vInd)];
			vAgeArray.Add(vAge);
		Except
		EndTry;
	EndDo;
	
	vGuestsQuantity = ?(pOrderRow.RoomQuantity > 0, pOrderRow.NumberOfAdults/pOrderRow.RoomQuantity, pOrderRow.NumberOfAdults) + ?(pOrderRow.RoomQuantity > 0, pOrderRow.NumberOfKids/pOrderRow.RoomQuantity, pOrderRow.NumberOfKids);
	
	// Get available room types
	vRoomTypes = cmGetRoomTypesByGuestQuantity(vGuestsQuantity, pOrderRow.RoomType, Hotel);
	
	// Get default customer
	vCustomer = Undefined;
	vContract = Undefined;
	vCurUser = SessionParameters.CurrentUser;
	If ValueIsFilled(vCurUser.Customer) Then
		vCustomer = vCurUser.Customer;
	Else
		If ValueIsFilled(DefaultContract) Then
			vCustomer = DefaultContract.Owner;
			vContract = DefaultContract;
		EndIf;
	EndIf;
	
	// Get room type prices
	vCurRoomTypeAccTypes = Undefined;
	
	// Probe document object to calculate prices
	vProbeResObj = Documents.Reservation.CreateDocument();
	vProbeResObj.Hotel = Hotel;
	vProbeResObj.pmFillAttributesWithDefaultValues(True);
	vProbeResObj.RoomQuota = RoomQuota;
	vProbeResObj.ClientType = ClientType;
	vProbeResObj.ServicePackage = MealBoardTerm;
	
	vAccommodationTemplate = Undefined;
	
	vRoomTypeBalances = cmGetRoomTypeBalancesTable(vRoomTypes, False, Hotel, pOrderRow.CheckInDate, pOrderRow.CheckOutDate, ClientType, vCustomer, vContract, DiscountType, , , , pOrderRow.RoomType, RoomRate, Undefined, ?(pOrderRow.RoomQuantity > 0, pOrderRow.NumberOfAdults/pOrderRow.RoomQuantity, pOrderRow.NumberOfAdults), ?(pOrderRow.RoomQuantity > 0, pOrderRow.NumberOfKids/pOrderRow.RoomQuantity, pOrderRow.NumberOfKids), vAgeArray, vProbeResObj, IsForFolioSplit, MealBoardTerm, vAccommodationTemplate);
	If vRoomTypeBalances <> Undefined Then
		vCurRoomTypeAccTypes = vRoomTypeBalances.FindRows(New Structure("RoomType", pOrderRow.RoomType));
		If vCurRoomTypeAccTypes.Count() = 0 Then
			vCurRoomTypeAccTypes = vRoomTypeBalances.FindRows(New Structure("RoomType", Catalogs.RoomTypes.EmptyRef()));
		EndIf;
	EndIf;
	pOrderRow.AccommodationTemplate = vAccommodationTemplate;
	
	vAmount = 0;
	vCurrency = Catalogs.Currencies.EmptyRef();
	If vCurRoomTypeAccTypes <> Undefined Then
		For Each vCurRoomTypeAccTypesRow In vCurRoomTypeAccTypes Do
			vAmount = vAmount + vCurRoomTypeAccTypesRow.Amount * ?(pOrderRow.RoomQuantity > 0, pOrderRow.RoomQuantity, 1);
			vCurrency = vCurRoomTypeAccTypesRow.Currency;
		EndDo;
	EndIf;
	pOrderRow.Amount = vAmount;
	
	// Remove folios created by documents
	If vProbeResObj <> Undefined Then
		For Each vCRRow In vProbeResObj.ChargingRules Do
			vFolioObj = vCRRow.ChargingFolio.GetObject();
			vFolioObj.Delete();
		EndDo;
		vProbeResObj = Undefined;
	EndIf;
EndProcedure // RecalculateOrderRowPriceAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetCachedPriceByPeriod(pPeriodFrom = Undefined, pPeriodTo = Undefined, pRoomType = Undefined, pCachedPrices)
	vServicesList = New ValueTable();
	vServicesList.Columns.Add("Period", cmGetDateTypeDescription());
	vServicesList.Columns.Add("Sum", cmGetSumTypeDescription());
	vCacheRows = pCachedPrices.FindRows(New Structure("RoomType", pRoomType));
	For Each vCacheRow In vCacheRows Do
		If pPeriodFrom <= vCacheRow.Period And pPeriodTo >= vCacheRow.Period Then
			vServicesListRow = vServicesList.Find(vCacheRow.Period);
			If vServicesListRow = Undefined Then
				vServicesListRow = vServicesList.Add();
				vServicesListRow.Period = vCacheRow.Period;
				vServicesListRow.Sum = 0;
			EndIf;
			vServicesListRow.Sum = vServicesListRow.Sum + cmConvertCurrencies(vCacheRow.Amount, vCacheRow.Currency, , Hotel.ReportingCurrency, , CurrentSessionDate(), Hotel);
		EndIf;
	EndDo;
	// Check if prices are overriden by allotment
	If ValueIsFilled(RoomQuota) And RoomQuota.RoomTypes.Count() > 0 Then
		vNumberOfAdults = NumberOfAdults;
		vNumberOfTeenagers = 0; vNumberOfChildren = 0; vNumberOfInfants = 0;
		n = 0;
		While n < NumberOfKids Do
			vAge = ThisObject["KidAge" + n];
			If vAge <= Hotel.InfantsMaxAge And Hotel.InfantsMaxAge <> 0 Then
				vNumberOfInfants = vNumberOfInfants + 1;
			ElsIf vAge <= Hotel.ChildrenMaxAge And Hotel.ChildrenMaxAge <> 0 Then
				vNumberOfChildren = vNumberOfChildren + 1;
			ElsIf vAge <= Hotel.TeenagersMaxAge And Hotel.TeenagersMaxAge <> 0 Then
				vNumberOfTeenagers = vNumberOfTeenagers + 1;
			Else
				vNumberOfAdults = vNumberOfAdults + 1;
			EndIf;
			n = n + 1;
		EndDo;
		vAllotmentPrices = RoomQuota.RoomTypes;
		For Each vServicesListRow In vServicesList Do
			vDayPrice = 0;
			vDayCurrency = 0;
			vRMPRows = RoomQuota.RoomTypes.FindRows(New Structure("NumberOfAdults, NumberOfTeenagers, NumberOfChildren, NumberOfInfants", vNumberOfAdults, vNumberOfTeenagers, vNumberOfChildren, vNumberOfInfants));
			p = vRMPRows.Count() - 1;
			While p >= 0 Do
				vRMPRow = vRMPRows.Get(p);
				If vRMPRow.Price <> 0 And vRMPRow.RoomType = pRoomType Then
					If BegOfDay(vRMPRow.PeriodFrom) <= vServicesListRow.Period And BegOfDay(vRMPRow.PeriodTo) > vServicesListRow.Period Then
						vDayPrice = vRMPRow.Price;
						vDayCurrency = vRMPRow.Currency;
						Break;
					EndIf;
				EndIf;
				p = p - 1;
			EndDo;
			If vDayPrice <> 0 Then
				vServicesListRow.Sum = cmConvertCurrencies(vDayPrice, vDayCurrency, , Hotel.ReportingCurrency, , vServicesListRow.Period, Hotel);
			EndIf;
		EndDo;
	EndIf;
	Return vServicesList;
EndFunction // GetCachedPriceByPeriod

// -----------------------------------------------------------------------------
&AtServer
Function GetPriceByPeriod(pPeriodFrom = Undefined, pPeriodTo = Undefined, pRoomType = Undefined)
	pProbeResObj = Undefined;
	// Build array of kid ages
	vAgeArray = New Array;
	For vInd = 1 To NumberOfKids Do
		Try
			vAge = ThisObject["KidAge" + String(vInd)];
			vAgeArray.Add(vAge);
		Except
		EndTry;
	EndDo;
	
	vGuestsQuantity = NumberOfAdults + NumberOfKids;
	
	// Get available room types
	pRoomTypes = cmGetRoomTypesByGuestQuantity(vGuestsQuantity, Catalogs.RoomTypes.EmptyRef(), Hotel);
	
	// Get default customer
	vCustomer = Undefined;
	vCurUser = SessionParameters.CurrentUser;
	If ValueIsFilled(vCurUser.Customer) Then
		vCustomer = vCurUser.Customer;
	EndIf;
	
	// Get room type prices
	vCurRoomTypeAccTypes = Undefined;
	vLanguage = cmGetLanguageByCode("");
	
	// Number of guests
	vAdultsQuantity = NumberOfAdults; 
	vKidsQuantity = NumberOfKids; 
	vGuestsQuantity = vAdultsQuantity + vKidsQuantity;
	
	// Retrieve parameter references based on codes
	vExtHotelCode = "";
	vExternalSystemCode = "";
	
	vClientType = ClientType;
	If vClientType = Undefined Then
		vClientType = Catalogs.ClientTypes.EmptyRef();
	EndIf;
	
	vRoomRate = RoomRate;
	If vRoomRate = Undefined Then
		vRoomRate = Catalogs.RoomRates.EmptyRef();
	EndIf;
	
	vCustomer = Catalogs.Customers.EmptyRef();
	vContract = Catalogs.Contracts.EmptyRef();
	If ValueIsFilled(RoomQuota) Then
		If ValueIsFilled(RoomQuota.Customer) Then
			vCustomer = RoomQuota.Customer;
		EndIf;
		If ValueIsFilled(RoomQuota.Contract) Then
			vContract = RoomQuota.Contract;
		EndIf;
	EndIf;
	
	// Build probe reservation object to calaculate services
	If pProbeResObj <> Undefined Then
		vProbeResObj = pProbeResObj;
		vProbeResObj.OccupationPercents.Clear();
	Else
		vProbeResObj = Documents.Reservation.CreateDocument();
		vProbeResObj.Hotel = Hotel;
		vProbeResObj.pmFillAttributesWithDefaultValues(True);
	EndIf;
	vProbeResObj.PriceCalculationDate = Undefined;
	vProbeResObj.Duration = vProbeResObj.pmCalculateDuration();
	vProbeResObj.ClientType = vClientType;
	vProbeResObj.Customer = vCustomer;
	vProbeResObj.Contract = vContract;
	vProbeResObj.RoomQuota = RoomQuota;
	vProbeResObj.ClientType = ClientType;
	vProbeResObj.ServicePackage = MealBoardTerm;

	If vRoomRate <> Undefined Then
		vProbeResObj.RoomRate = vRoomRate;
	EndIf;
	vDiscountType = DiscountType;

	If ValueIsFilled(vProbeResObj.Contract) And ValueIsFilled(vProbeResObj.Contract.AgentCommissionType) Then
		// Agent commission
		If Not vProbeResObj.Contract.IsSubagent Then
			vProbeResObj.Agent = vProbeResObj.Contract.Agent;
			If ValueIsFilled(vProbeResObj.Customer) And ValueIsFilled(vProbeResObj.Contract.AgentCommissionType) Then
				If Not ValueIsFilled(vProbeResObj.Agent) Then
					vProbeResObj.Agent = vProbeResObj.Customer;
				EndIf;
				vProbeResObj.AgentCommission = vProbeResObj.Contract.AgentCommission;
				vProbeResObj.AgentCommissionType = vProbeResObj.Contract.AgentCommissionType;
				vProbeResObj.AgentCommissionServiceGroup = vProbeResObj.Contract.AgentCommissionServiceGroup;
			EndIf;
		Else
			vAgent = vProbeResObj.Contract.Owner;
			vProbeResObj.Agent = vAgent;
			If ValueIsFilled(vAgent.Agent) Then
				vProbeResObj.Agent = vAgent.Agent;
			EndIf;
			If vAgent.AgentCommission <> 0 Then
				vProbeResObj.AgentCommission = vAgent.AgentCommission;
				vProbeResObj.AgentCommissionType = vAgent.AgentCommissionType;
				vProbeResObj.AgentCommissionServiceGroup = vAgent.AgentCommissionServiceGroup;
			EndIf;
		EndIf;
		If Not ValueIsFilled(vProbeResObj.Agent) Then
			vProbeResObj.AgentCommission = 0;
			vProbeResObj.AgentCommissionType = Undefined;
			vProbeResObj.AgentCommissionServiceGroup = Catalogs.ServiceGroups.EmptyRef();
		EndIf;
		// Room rate
		vChangeRR = False;
		If ValueIsFilled(vProbeResObj.RoomRate) Then
			vFindedRR = vProbeResObj.Contract.RoomRates.Find(vProbeResObj.RoomRate, "RoomRate");
			If vFindedRR = Undefined And vProbeResObj.RoomRate <> vProbeResObj.Contract.RoomRate Then
				vChangeRR = True;
			EndIf;
		Else
			vChangeRR = True;
		EndIf;
		If vChangeRR Then
			If ValueIsFilled(vProbeResObj.Contract.RoomRate) Then
				vProbeResObj.RoomRate = vProbeResObj.Contract.RoomRate;
				vProbeResObj.RoomRateServiceGroup = vProbeResObj.Contract.RoomRateServiceGroup;
			ElsIf ValueIsFilled(vProbeResObj.Customer) And ValueIsFilled(vProbeResObj.Customer.RoomRate) Then
				vProbeResObj.RoomRate = vProbeResObj.Customer.RoomRate;
				vProbeResObj.RoomRateServiceGroup = vProbeResObj.Customer.RoomRateServiceGroup;
			ElsIf ValueIsFilled(vProbeResObj.Hotel) And ValueIsFilled(vProbeResObj.Hotel.RoomRate) Then
				vProbeResObj.RoomRate = vProbeResObj.Hotel.RoomRate;
				vProbeResObj.RoomRateServiceGroup = vProbeResObj.Hotel.RoomRateServiceGroup;
			EndIf;
			// Client type
			If ValueIsFilled(vProbeResObj.RoomRate) And ValueIsFilled(vProbeResObj.RoomRate.ClientType) Then
				vProbeResObj.ClientType = vProbeResObj.RoomRate.ClientType;
				vProbeResObj.ClientTypeConfirmationText = vProbeResObj.RoomRate.ClientTypeConfirmationText;
			EndIf;
		EndIf;
		// Client type
		If ValueIsFilled(vProbeResObj.Contract.ClientType) Then
			vProbeResObj.ClientType = vProbeResObj.Contract.ClientType;
			vProbeResObj.ClientTypeConfirmationText = vProbeResObj.Contract.ClientTypeConfirmationText;
		EndIf;
		// Charging rules
		vProbeResObj.pmLoadChargingRules(vProbeResObj.Contract);
	EndIf;
	vProbeResObj.pmSetDiscounts();
	If ValueIsFilled(vDiscountType) Then
		vProbeResObj.DiscountType = vDiscountType;
		vProbeResObj.DiscountServiceGroup = vDiscountType.DiscountServiceGroup;
		vProbeResObj.Discount = vProbeResObj.DiscountType.GetObject().pmGetDiscount(vProbeResObj.CheckInDate, , vProbeResObj.Hotel);
	EndIf;
	vReferenceHour = cmGetReferenceHour(vProbeResObj.RoomRate);
	vCheckInTime = cmGetDefaultCheckInTime(vProbeResObj.RoomRate);
	vCheckOutTime = cmGetDefaultCheckOutTime(vProbeResObj.RoomRate);
	vPeriodFrom = BegOfDay(pPeriodFrom - 24 * 3600) + (vCheckInTime-BegOfDay(vCheckInTime));
	If ValueIsFilled(vCheckOutTime) Then
		vPeriodTo = BegOfDay(pPeriodTo) + (vCheckOutTime-BegOfDay(vCheckOutTime));
	Else
		vPeriodTo = BegOfDay(pPeriodTo) + (vReferenceHour-BegOfDay(vReferenceHour));
	EndIf;
	If pPeriodFrom = pPeriodTo Then
		vPeriodTo = EndOfDay(pPeriodTo);
	EndIf;
	vProbeResObj.CheckInDate = cm1SecondShift(vPeriodFrom);
	vProbeResObj.CheckOutDate = cm0SecondShift(vPeriodTo);
	vProbeResObj.Duration = vProbeResObj.pmCalculateDuration();
	
	// Build structure with children ages
	vChildrenAgesStruct = Undefined;
	If ValueIsFilled(vProbeResObj.Contract) Then
		vAllotmentContract = vProbeResObj.Contract;
		If vAllotmentContract.TeenagersMaxAge <> 0 Or vAllotmentContract.ChildrenMaxAge <> 0 Or vAllotmentContract.InfantsMaxAge <> 0 Then
			vChildrenAgesStruct = vAllotmentContract;
		EndIf;
	EndIf;
	
	// Do for each room type in balances
	vCurrency = Hotel.ReportingCurrency;
	vFoundRow = pRoomTypes.Find(pRoomType, "RoomType");
	If Not (vFoundRow = Undefined And ValueIsFilled(pRoomType)) Then
		vRoomTypeBalances = New ValueTable;
		vRoomTypeBalances.Columns.Add("RoomType", cmGetCatalogTypeDescription("RoomTypes"));
		vRoomTypeBalances.Columns.Add("AccommodationTemplate", cmGetCatalogTypeDescription("AccommodationTemplates"));
		vRoomTypeBalances.Columns.Add("AccommodationType", cmGetCatalogTypeDescription("AccommodationTypes"));
		vRoomTypeBalances.Columns.Add("Amount", cmGetNumberTypeDescription(17, 2));
		vRoomTypeBalances.Columns.Add("AmountPresentation", cmGetStringTypeDescription());
		vRoomTypeBalances.Columns.Add("Currency", cmGetCatalogTypeDescription("Currencies"));
		vRoomTypesList = New ValueList;
		vRowsToDeleteArray = New Array;
		If ValueIsFilled(pRoomType) Then
			vFoundRowIndex = pRoomTypes.IndexOf(vFoundRow);
			vRoomTypesList.Add(vFoundRow.RoomType);
			If vFoundRowIndex > 0 Then
				vPrevIndex = vFoundRowIndex - 1;
				vRoomTypesList.Add(pRoomTypes.Get(vPrevIndex).RoomType);
			EndIf;
			If vFoundRowIndex < (pRoomTypes.Count() - 1) Then
				vNextIndex = vFoundRowIndex + 1;
				vRoomTypesList.Add(pRoomTypes.Get(vNextIndex).RoomType);
			EndIf;
		Else
			For Each vRow In pRoomTypes Do
				vRoomTypesList.Add(vRow.RoomType);
			EndDo;
		EndIf;
		vLastRoomType = Catalogs.RoomTypes.EmptyRef();
		
		vServicesList = New ValueTable;
		vServicesList.Columns.Add("Period");
		vServicesList.Columns.Add("Sum");
		For Each vRTItem In vRoomTypesList Do
			If vRTItem.Value <> pRoomType Then
				Continue;
			EndIf;	
			// Get active special offers
			If vRTItem.Value <> vLastRoomType Then
				If ValueIsFilled(Hotel) And (Hotel.TeenagersMaxAge <> 0 Or Hotel.ChildrenMaxAge <> 0 Or Hotel.InfantsMaxAge <> 0) Then
					vOffers = cmGetConfirmedSpecialOffersForReservation(Undefined, vProbeResObj.Hotel, vProbeResObj.RoomRate, vProbeResObj.RoomRateType, vProbeResObj.Guest, vProbeResObj.ClientType, vProbeResObj.Customer, vProbeResObj.CustomerType, vProbeResObj.GuestGroup, vProbeResObj.SourceOfBusiness, vProbeResObj.MarketingCode, vProbeResObj.TripPurpose, vProbeResObj.CheckInDate, vProbeResObj.Duration, vProbeResObj.CheckOutDate, CurrentSessionDate(), vRTItem.Value);
					For Each vOffersRow In vOffers Do
						vOffer = vOffersRow.SpecialOffer;
						If vOffer.TeenagersMaxAge <> 0 Or vOffer.ChildrenMaxAge <> 0 Or vOffer.InfantsMaxAge <> 0 Then
							vChildrenAgesStruct = vOffer;
							Break;
						EndIf;
					EndDo;
				EndIf;
			EndIf;
			// Get accommodation types table with ages
			vAccTypesWithAgeList = cmGetAvailableAccommodationTypesWithKidsAges(vAdultsQuantity, vKidsQuantity, vAgeArray, vExternalSystemCode, Hotel, vRTItem.Value, , , , vChildrenAgesStruct);
			// Filter result by is for folio split
			vInt = 0;
			While vInt < vAccTypesWithAgeList.Count() Do
				vAccTypesWithAgeListRow = vAccTypesWithAgeList.Get(vInt);
				
				If ValueIsFilled(vAccTypesWithAgeListRow.AccTemplate) And IsForFolioSplit <> vAccTypesWithAgeListRow.AccTemplate.IsForFolioSplit Then
					vAccTypesWithAgeList.Delete(vInt);
					Continue;
				EndIf;
				
				vInt = vInt + 1;
			EndDo;
			// Check acc types
			If vAccTypesWithAgeList.Count() = 0 Then
				Continue;
			EndIf;
			If vRTItem.Value <> vLastRoomType Then
				vProbeResObj.RoomType = vRTItem.Value;
				vLastRoomType = vRTItem.Value;
			EndIf;
			vLastAT = Undefined;
			vATError = Undefined;
			vFindedAT = Undefined;
			vArrayOfRowsToDelete = New Array;
			For Each vATRow In vAccTypesWithAgeList Do
				If vLastAT <> vATRow.AccTemplate Then
					If vATError<>Undefined And vATError Then
						vFindedRowsToDelete = vRoomTypeBalances.FindRows(New Structure("AccommodationTemplate, RoomType", vLastAT, vRTItem.Value));
						For Each vItem In vFindedRowsToDelete Do
							vArrayOfRowsToDelete.Add(vItem);
						EndDo;
						vLastAT = Undefined;
						vFindedAT = Undefined;
						vATError = False;
					EndIf;
					If (vATError = Undefined Or Not vATError) And vLastAT<>Undefined Then
						vFindedAT = vLastAT;
						break;
					EndIf;
					vLastAT = vATRow.AccTemplate;
				EndIf;
				If vATError<>Undefined And vATError Then
					Continue;
				EndIf;
				vProbeResObj.AccommodationType = vATRow.AccommodationType;
				If vAccTypesWithAgeList.IndexOf(vATRow) = 0 Then
					vProbeResObj.AccommodationTemplate = vATRow.AccTemplate;
				Else
					vProbeResObj.AccommodationTemplate = Catalogs.AccommodationTemplates.EmptyRef();
				EndIf;
				vProbeResObj.IsForFolioSplit = IsForFolioSplit;
				
				// Calculate resources
				vProbeResObj.pmCalculateResources();
				
				// Fill price tag
				If ValueIsFilled(vProbeResObj.RoomRate) And (vProbeResObj.RoomRate.PriceTagType = Enums.PriceTagTypes.ByDurationOfStayByDays Or vProbeResObj.RoomRate.PriceTagType = Enums.PriceTagTypes.ByDurationOfStayByPeriod) Then
					If vProbeResObj.Services.Count() = 0 Then
						vProbeResObj.pmCalculateServices( , , , , , vProbeResObj.IsForFolioSplit);
						For Each vPrSrvRow In vProbeResObj.Services Do
							If ValueIsFilled(vPrSrvRow.PriceTag) Then
								vPrSrvRow.PriceTag = PriceTag;
							EndIf;
						EndDo;
					EndIf;
				EndIf;
				
				// Automatic services list calculation
				vProbeResObj.pmCalculateServices( , , , , , vProbeResObj.IsForFolioSplit);
				
				// Check if there are any services for this accommodation type
				vRoomRevenueServices = vProbeResObj.Services.FindRows(New Structure("IsRoomRevenue", True));
				
				// Calculate accommodation type amount
				vAccTypeAmount = vProbeResObj.Services.Total("Sum") - vProbeResObj.Services.Total("DiscountSum");
				For Each Str In vProbeResObj.Services Do
					
					vnewRow = vServicesList.Add();
					vnewRow.Period = Str.AccountingDate;
					vnewRow.Sum = Str.Sum-Str.DiscountSum;
					
				EndDo; 
				// Get currency
				For Each vSrvRow In vProbeResObj.Services Do
					If vSrvRow.IsRoomRevenue Then
						vCurrency = vSrvRow.FolioCurrency;
						Break;
					EndIf;
				EndDo;
				
				// Save amount to the accommodation types value table
				vNewBalanceRow = vRoomTypeBalances.Add();
				vNewBalanceRow.RoomType = vRTItem.Value;
				vNewBalanceRow.AccommodationTemplate = vATRow.AccTemplate;
				vNewBalanceRow.AccommodationType = vATRow.AccommodationType;
				vNewBalanceRow.Amount = vAccTypeAmount;
				vNewBalanceRow.AmountPresentation = cmFormatSum(vAccTypeAmount, vCurrency, "NZ=");
				vNewBalanceRow.Currency = vCurrency;
			EndDo;
			If (vATError = Undefined Or Not vATError) And vLastAT<>Undefined Then
				vFindedAT = vLastAT;
			EndIf;
			For Each vArrayItem In vArrayOfRowsToDelete Do
				vRoomTypeBalances.Delete(vArrayItem);
			EndDo;
			If Not ValueIsFilled(vFindedAT) And vATError = True Then
				vFindedRowsToDelete = vRoomTypeBalances.FindRows(New Structure("RoomType", vRTItem.Value));
				For Each vItem In vFindedRowsToDelete Do
					vRoomTypeBalances.Delete(vItem);
				EndDo;
				Continue;
			EndIf;
		EndDo;
	EndIf;
	// Remove folios created by documents
	If pProbeResObj = Undefined Then
		For Each vCRRow In vProbeResObj.ChargingRules Do
			vFolioObj = vCRRow.ChargingFolio.GetObject();
			vFolioObj.Delete();
		EndDo;
		vProbeResObj = Undefined;
	EndIf;

	If vServicesList <> Undefined Then
		vServicesList.GroupBy("Period","Sum");
	Else
		vServicesList = New ValueTable();
	EndIf;
	Return vServicesList;
EndFunction //  GetPriceByPeriod

// -----------------------------------------------------------------------------
&AtServer
Function CreateGuestGroupAtServer(rError = "", rAddRoomsToAllotment = False, rAllotmentBalances = Undefined) 
	rError = "";
	Try
		If Not ValueIsFilled(Hotel) Then
			rError = NStr("en='Hotel is not choosen!'; ru='Не выбрана гостиница'; de='Hotel ist nicht ausgewählt!'");
			Return False;
		EndIf;
		
		// Check rights to use allotment
		If ValueIsFilled(RoomQuota) And ValueIsFilled(RoomQuota.Company) And ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Company) And 
		   RoomQuota.Company <> SessionParameters.CurrentUser.Company Then
			rError = NStr("en='You do not have rights to use " + TrimAll(RoomQuota.Company) + " company allotment!'; ru='Нет прав использовать квоту компании " + TrimAll(RoomQuota.Company) + "!'; de='Sie sind nicht berechtigt, die Zimmerquote der Firma " + TrimAll(RoomQuota.Company) + " verwenden!'");
			Return False;
		EndIf;
		
		BeginTransaction(DataLockControlMode.Managed);

		If Not ValueIsFilled(GuestGroup) Then
			vGuestGroupObj = Catalogs.GuestGroups.CreateItem();
			vGuestGroupObj.Owner = Hotel;
			vGuestGroupFolder = Hotel.GetObject().pmGetGuestGroupFolder();
			If ValueIsFilled(vGuestGroupFolder) Then
				vGuestGroupObj.Parent = vGuestGroupFolder;
				vGuestGroupObj.SetNewCode();
			EndIf;
			vGuestGroupObj.OneCustomerPerGuestGroup = Hotel.OneCustomerPerGuestGroup;
			vGuestGroupObj.Write();
			GuestGroup = vGuestGroupObj.Ref;
		EndIf;
		
		// Process order basket rows
		For Each vOrderBasketRow In OrderBasket Do
			If ValueIsFilled(vOrderBasketRow.AccommodationTemplate) Then
				CreateOrderReservation(GuestGroup, vOrderBasketRow, rError, rAddRoomsToAllotment, rAllotmentBalances);
			EndIf;
		EndDo;		
		
		CommitTransaction();

		Return True;
	Except
		rError = cmGetRootErrorDescription(ErrorInfo());
		
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		
		Return False;
	EndTry;
EndFunction // CreateGuestGroupAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure CreateOrderReservation(pGuestGroup, pOrderBasketRow, rWarning = "", rAddRoomsToAllotment = False, rAllotmentBalances = Undefined)
	vResNumber = "";
	vOverrides = New ValueTable();
	For Each vAccTemplateRow In pOrderBasketRow.AccommodationTemplate.AccommodationTypes Do
		vAccTemplateRowIndex = pOrderBasketRow.AccommodationTemplate.AccommodationTypes.IndexOf(vAccTemplateRow);
		
		vRowStruct = GetParameters(pOrderBasketRow, vAccTemplateRow.AccommodationType, pGuestGroup);
		
		// Create reservation document
		vDocObj = Documents.Reservation.CreateDocument();
		vDocObj.GuestGroup = pGuestGroup;
		vDocObj.Hotel = pGuestGroup.Owner;
		vDocObj.pmFillAttributesWithDefaultValues();
		FillPropertyValues(vDocObj, vRowStruct);
		If ValueIsFilled(vDocObj.RoomType) And ValueIsFilled(vDocObj.RoomType.BaseRoomType) Then
			vDocObj.RoomTypeUpgrade = vDocObj.RoomType;
			vDocObj.RoomType = vDocObj.RoomType.BaseRoomType;
		EndIf;
		vDocObj.PriceCalculationDate = '00010101';
		If vDocObj.RoomType.StopSale Then
			vRemarks = "";
			If cmIsStopSalePeriod(vDocObj.RoomType, cm1SecondShift(vDocObj.CheckInDate), cm0SecondShift(vDocObj.CheckOutDate), vRemarks) Then
				If Not cmCheckUserPermissions("HavePermissionToIgnoreStopSaleLimitations") Then
					vMessage = NStr("en='You have chosen room type with stop sale flag turned on! Rechoose room type! ';ru='Выбрали тип номера снятый с продажи! Перевыберите тип номера! ';de='Sie haben einen Zimmertyp gewählt, der aus dem Angebot genommen wurde! Wählen Sie einen anderen Zimmertyp! '") + TrimAll(vDocObj.RoomType) + Chars.LF + vRemarks;
					Raise vMessage;
				Else
					rWarning = NStr("en='You have chosen room type with stop sale flag turned on! ';ru='Выбрали тип номера снятый с продажи! ';de='Sie haben einen Zimmertyp gewählt, der aus dem Angebot genommen wurde! '") + TrimAll(vDocObj.RoomType) + Chars.LF + vRemarks;
				EndIf;
			EndIf;
		EndIf;     
		// Discount type
		If ValueIsFilled(vDocObj.DiscountType) Then
			vDocObj.DiscountServiceGroup = vDocObj.DiscountType.DiscountServiceGroup;
			If vDocObj.DiscountType.IsAccumulatingDiscount Then
				// Fill manual services accumulation discounts
				For Each vCurRow In vDocObj.Services Do
					If vCurRow.IsManual Then
						If cmIsServiceInServiceGroup(vCurRow.Service, vDocObj.DiscountServiceGroup) Then
							vDocObj.pmCalculateAccumulationDiscountForAdditionalService(vCurRow);
							vDocObj.pmCalculateServiceDiscounts(vCurRow);
						Else
							vCurRow.DiscountType = Catalogs.DiscountTypes.EmptyRef();
							vCurRow.DiscountServiceGroup = Catalogs.ServiceGroups.EmptyRef();
							vCurRow.Discount = 0;
							vCurRow.DiscountConfirmationText = "";
						EndIf;
					EndIf;
				EndDo;
			EndIf;
			vDiscountTypeObj = vDocObj.DiscountType.GetObject();
			vDocObj.Discount = vDiscountTypeObj.pmGetDiscount(vDocObj.CheckInDate, , vDocObj.Hotel);     
		EndIf;	
		// Room rate
		If ValueIsFilled(vDocObj.RoomRate) Then
			If ValueIsFilled(vDocObj.RoomRate.SourceOfBusiness) Then
				vDocObj.SourceOfBusiness = vDocObj.RoomRate.SourceOfBusiness;
			EndIf;
			If ValueIsFilled(vDocObj.RoomRate.MarketingCode) Then
				vDocObj.MarketingCode = vDocObj.RoomRate.MarketingCode;
			EndIf;
			If ValueIsFilled(vDocObj.RoomRate.ClientType) Then
				vDocObj.ClientType = vDocObj.RoomRate.ClientType;
				vDocObj.ClientTypeConfirmationText = vDocObj.RoomRate.ClientTypeConfirmationText;
			EndIf;
		EndIf;
		If ValueIsFilled(vDocObj.RoomQuota) Then
			// Company
			If ValueIsFilled(vDocObj.RoomQuota.Company) Then
				vDocObj.Company = vDocObj.RoomQuota.Company;
			EndIf;
			// Set flag of charging rules update
			vUpdateCR = False;
			// Customer
			If ValueIsFilled(vDocObj.RoomQuota.Customer) Then
				vDocObj.Customer = vDocObj.RoomQuota.Customer;
				If ValueIsFilled(vDocObj.Customer.CustomerType) Then
					vDocObj.CustomerType = vDocObj.Customer.CustomerType;
				EndIf;
				// Room rate type
				If ValueIsFilled(vDocObj.CustomerType) Then
					If Not ValueIsFilled(vDocObj.RoomRateType) Then
						vDocObj.RoomRateType = vDocObj.CustomerType.RoomRateType;
					EndIf;
				EndIf;
				// Contact person
				If Not IsBlankString(vDocObj.Customer.ContactPerson) Then
					vDocObj.ContactPerson = TrimR(vDocObj.Customer.ContactPerson);
				EndIf;
				// Planned payment method
				If Not ValueIsFilled(vDocObj.ParentDoc) Then
					If ValueIsFilled(vDocObj.Customer.PlannedPaymentMethod) Then
						vDocObj.PlannedPaymentMethod = vDocObj.Customer.PlannedPaymentMethod;
					EndIf;
				EndIf;
				// Agent
				vDocObj.Agent = vDocObj.Customer.Agent;
				If ValueIsFilled(vDocObj.Customer.AgentCommissionType) Then
					If Not ValueIsFilled(vDocObj.Agent) Then
						vDocObj.Agent = vDocObj.Customer;
					EndIf;
					vDocObj.AgentCommission = vDocObj.Agent.AgentCommission;
					vDocObj.AgentCommissionType = vDocObj.Agent.AgentCommissionType;
					vDocObj.AgentCommissionServiceGroup = vDocObj.Agent.AgentCommissionServiceGroup;
				EndIf;
				vUpdateCR = True;
			EndIf;
			// Agent
			If ValueIsFilled(vDocObj.RoomQuota.Agent) Then
				vDocObj.Agent = vDocObj.RoomQuota.Agent;
				If ValueIsFilled(vDocObj.Agent.AgentCommissionType) Then
					vDocObj.AgentCommission = vDocObj.Agent.AgentCommission;
					vDocObj.AgentCommissionType = vDocObj.Agent.AgentCommissionType;
					vDocObj.AgentCommissionServiceGroup = vDocObj.Agent.AgentCommissionServiceGroup;
				EndIf;
			EndIf;
			If Not ValueIsFilled(vDocObj.Agent) Then
				vDocObj.AgentCommission = 0;
				vDocObj.AgentCommissionType = Undefined;
				vDocObj.AgentCommissionServiceGroup = Catalogs.ServiceGroups.EmptyRef();
			EndIf;
			// Get default contract
			If ValueIsFilled(vDocObj.Customer) Then
				If ValueIsFilled(DefaultContract) Then
					vDocObj.Contract = DefaultContract;
					If ValueIsFilled(DefaultContract.PlannedPaymentMethod) Then
						vDocObj.PlannedPaymentMethod = DefaultContract.PlannedPaymentMethod;
					EndIf;
					// Agent commission
					If ValueIsFilled(DefaultContract.AgentCommissionType) Then
						If Not ValueIsFilled(vDocObj.Agent) Then
							vDocObj.Agent = vDocObj.Customer;
						EndIf;
						vDocObj.AgentCommission = DefaultContract.AgentCommission;
						vDocObj.AgentCommissionType = DefaultContract.AgentCommissionType;
						vDocObj.AgentCommissionServiceGroup = DefaultContract.AgentCommissionServiceGroup;
					EndIf;
					// Contract company
					If ValueIsFilled(DefaultContract.Company) Then
						vDocObj.Company = DefaultContract.Company;
					EndIf;
					// Marketing code
					If ValueIsFilled(DefaultContract.MarketingCode) Then
						vDocObj.MarketingCode = DefaultContract.MarketingCode;
						vDocObj.MarketingCodeConfirmationText = "";
					EndIf;
					// Source of business
					If ValueIsFilled(DefaultContract.SourceOfBusiness) Then
						vDocObj.SourceOfBusiness = DefaultContract.SourceOfBusiness;
					EndIf;
					// Client type
					If ValueIsFilled(DefaultContract.ClientType) Then
						vDocObj.ClientType = DefaultContract.ClientType;
						vDocObj.ClientTypeConfirmationText = DefaultContract.ClientTypeConfirmationText;
					EndIf;
					// Do not print rate
					If DefaultContract.DoNotPrintRate Then
						vDocObj.DoNotPrintRate = True;
					EndIf;
					// Meal board term
					If Not ValueIsFilled(vDocObj.ServicePackage) And ValueIsFilled(DefaultContract.MealBoardTerm) Then
						vDocObj.ServicePackage = DefaultContract.MealBoardTerm;
					EndIf;
					vUpdateCR = True;
				EndIf;
			EndIf;
			If vDocObj.RoomQuota.AllotmentBusinessType = Enums.AllotmentBusinessTypes.BusinessBlock Then
				If vDocObj.RoomQuota.AllotmentType = Enums.AllotmentTypes.Definite And (Not ValueIsFilled(vDocObj.ReservationStatus) Or ValueIsFilled(vDocObj.ReservationStatus) And Not vDocObj.ReservationStatus.IsGuaranteed) Then
					vGuaranteedReservationStatus = cmGetDefaultGuaranteedReservationStatus(vDocObj.Hotel);
					If ValueIsFilled(vGuaranteedReservationStatus) Then
						vDocObj.ReservationStatus = vGuaranteedReservationStatus;
						If ValueIsFilled(vGuaranteedReservationStatus.GuaranteeType) Then
							vDocObj.GuaranteeType = vGuaranteedReservationStatus.GuaranteeType;
						EndIf;
						If vGuaranteedReservationStatus.DoCharging And 
		  				   (Not vGuaranteedReservationStatus.DoChargingIfRoomIsFilled Or vGuaranteedReservationStatus.DoChargingIfRoomIsFilled And ValueIsFilled(vDocObj.Room)) Then
							vDocObj.DoCharging = True;
						Else
							vDocObj.DoCharging = False;
						EndIf;
					EndIf;
				ElsIf (vDocObj.RoomQuota.AllotmentType = Enums.AllotmentTypes.Tentative Or vDocObj.RoomQuota.AllotmentType = Enums.AllotmentTypes.DefiniteNotGuaranteed) And 
				      (Not ValueIsFilled(vDocObj.ReservationStatus) Or ValueIsFilled(vDocObj.ReservationStatus) And vDocObj.ReservationStatus.IsGuaranteed) Then
					vNotGuaranteedReservationStatus = cmGetDefaultNotGuaranteedReservationStatus(vDocObj.Hotel);
					If ValueIsFilled(vNotGuaranteedReservationStatus) Then
						vDocObj.ReservationStatus = vNotGuaranteedReservationStatus;
						If vNotGuaranteedReservationStatus.DoCharging And 
		  				  (Not vNotGuaranteedReservationStatus.DoChargingIfRoomIsFilled Or vNotGuaranteedReservationStatus.DoChargingIfRoomIsFilled And ValueIsFilled(vDocObj.Room)) Then
							vDocObj.DoCharging = True;
						Else
							vDocObj.DoCharging = False;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			If vUpdateCR And ValueIsFilled(vDocObj.Customer) Then
				vDocObj.pmLoadDefaultChargingRules();
			EndIf;
		EndIf;
		vDocObj.RoomQuantity = pOrderBasketRow.RoomQuantity;
		// Get room rate overrides
		If vAccTemplateRowIndex = 0 Then
			vOverrides = cmGetRoomRateOverrides(vDocObj.RoomRate, vDocObj.Hotel, vDocObj.AccommodationTemplate, ?(ValueIsFilled(vDocObj.RoomTypeUpgrade), vDocObj.RoomTypeUpgrade, vDocObj.RoomType));
		EndIf;
		If vOverrides.Count() > 0 Then
			vOverrideRows = vOverrides.FindRows(New Structure("AccommodationType, TemplateLineNumber", vDocObj.AccommodationType, vAccTemplateRowIndex + 1));
			If vOverrideRows.Count() > 0 And ValueIsFilled(vOverrideRows.Get(0).ToAccommodationType) Then
				vDocObj.AccommodationType = vOverrideRows.Get(0).ToAccommodationType;
			EndIf;
		EndIf;
		// Recalculate resources and services
		vDocObj.pmCalculateResources();
		If vAccTemplateRowIndex = 0 Then
			vDocObj.AccommodationTemplate = pOrderBasketRow.AccommodationTemplate;
			vDocObj.NumberOfAdults = vDocObj.AccommodationTemplate.NumberOfAdults * vDocObj.RoomQuantity;
			vDocObj.NumberOfTeenagers = vDocObj.AccommodationTemplate.NumberOfTeenagers * vDocObj.RoomQuantity;
			vDocObj.NumberOfChildren = vDocObj.AccommodationTemplate.NumberOfChildren * vDocObj.RoomQuantity;
			vDocObj.NumberOfInfants = vDocObj.AccommodationTemplate.NumberOfInfants * vDocObj.RoomQuantity;
		Else
			vDocObj.AccommodationTemplate = Undefined;
			vDocObj.NumberOfAdults = 0;
			vDocObj.NumberOfTeenagers = 0;
			vDocObj.NumberOfChildren = 0;
			vDocObj.NumberOfInfants = 0;
		EndIf;
		vDocObj.IsForFolioSplit = IsForFolioSplit;
		vDocObj.pmSetDiscounts();
		vDocObj.pmCalculateServices( , , , , , vDocObj.IsForFolioSplit);
		vDocObj.pmSetPlannedPaymentMethod();
		If Not IsBlankString(vResNumber) Then
			vDocObj.Number = vResNumber;
		EndIf;
		vDocObj.AdditionalProperties.Insert("DoNotCloseMode", True);
		
		vDocObj.AdditionalProperties.Insert("AddRoomsToAllotment", rAddRoomsToAllotment);
		vDocObj.AdditionalProperties.Insert("AllotmentBalances", rAllotmentBalances);
		
		vDocObj.Write(DocumentWriteMode.Posting);
		vDocObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
		
		// Fill flag to modify allotment
		If vDocObj.AdditionalProperties.Property("AddRoomsToAllotment") And vDocObj.AdditionalProperties.AddRoomsToAllotment Then
			rAddRoomsToAllotment = True;
		EndIf;
		If vDocObj.AdditionalProperties.Property("AllotmentBalances") And TypeOf(vDocObj.AdditionalProperties.AllotmentBalances) = Type("Array") Then
			rAllotmentBalances = vDocObj.AdditionalProperties.AllotmentBalances;
		EndIf;
		
		vResNumber = vDocObj.Number;
	EndDo;
EndProcedure // CreateOrderReservation

// -----------------------------------------------------------------------------
&AtServer
Procedure FillAccommodationTypesChoiceList(IsRoom = True)
	vQry = New Query;
	vQry.Text =
	"SELECT
	|	AccommodationTypes.Ref
	|FROM
	|	Catalog.AccommodationTypes AS AccommodationTypes
	|WHERE
	|	NOT AccommodationTypes.DeletionMark
	|	AND NOT AccommodationTypes.IsFolder
	|	" + ?(IsRoom, "", "AND AccommodationTypes.NumberOfRooms = &qNumberOfRooms ") 
	+	" ORDER BY
	|	AccommodationTypes.SortCode";
	If Not IsRoom Then
		vQry.SetParameter("qNumberOfRooms", 0);
	EndIf;
	vResult = vQry.Execute().Select();
	vAccTypesArray = New Array;
	While vResult.Next() Do
		vAccTypesArray.Add(vResult.Ref);
	EndDo;
	SkipOnActivateCell = True;
	Items.AccommodationTypesTableAccommodationType.ChoiceList.LoadValues(vAccTypesArray);
EndProcedure // FillAccommodationTypesChoiceList

// -----------------------------------------------------------------------------
&AtServer
Procedure AccommodationTypeOnChangeAtServer()
	If CheckFields() Then
		vIndex = 0;
		For Each vRow In AccommodationTypesTable Do
			If Not ValueIsFilled(vRow.AccommodationType) Then
				AccommodationTypesTable.Delete(vRow);
			Else
				vRow.RowIndex = vIndex;
				vIndex = vIndex + 1;
			EndIf;
		EndDo;
		If AccommodationTypesTable.Count() > 0 Then
			vAccTypetable = AccommodationTypesTable.Unload(,"AccommodationType");
			GetPrice(vAccTypetable);
		EndIf;
	EndIf;
EndProcedure // AccommodationTypeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetNewReservationFormParameters(rError = "", rWarning = "")
	rError = "";
	rWarning = "";
	vRowStruct = GetParameters();
	// Check rights to use allotment
	If ValueIsFilled(RoomQuota) And ValueIsFilled(RoomQuota.Company) And ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Company) 
		And RoomQuota.Company <> SessionParameters.CurrentUser.Company Then
		rError = NStr("en='You do not have rights to use " + TrimAll(RoomQuota.Company) + " company allotment!'; ru='Нет прав использовать квоту компании " + TrimAll(RoomQuota.Company) + "!'; de='Sie sind nicht berechtigt, die Zimmerquote der Firma " + TrimAll(RoomQuota.Company) + " verwenden!'");
		Return vRowStruct;
	EndIf;
	// Check conditions
	If SelRoomType.StopSale Then
		vRemarks = "";
		If cmIsStopSalePeriod(SelRoomType, cm1SecondShift(CheckInDate), cm0SecondShift(CheckOutDate), vRemarks) Then
			If Not cmCheckUserPermissions("HavePermissionToIgnoreStopSaleLimitations") Then
				rError = NStr("en='You have chosen room type with stop sale flag turned on! Rechoose room type!';ru='Выбрали тип номера снятый с продажи! Перевыберите тип номера!';de='Sie haben einen Zimmertyp gewählt, der aus dem Angebot genommen wurde! Wählen Sie einen anderen Zimmertyp!'") + Chars.LF + vRemarks;
			Else
				rWarning = NStr("en='You have chosen room type with stop sale flag turned on!';ru='Выбрали тип номера снятый с продажи!';de='Sie haben einen Zimmertyp gewählt, der aus dem Angebot genommen wurde! Wählen Sie einen anderen Zimmertyp!'") + Chars.LF + vRemarks;
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
	If pGuestGroup = Undefined Then
		vGuestGroup = GuestGroup;
	EndIf;
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
	If ValueIsFilled(?(pOrderBasketRow = Undefined, CheckInDate, pOrderBasketRow.CheckIndate)) Then
		vCheckInDate = BegOfDay(?(pOrderBasketRow = Undefined, CheckInDate, pOrderBasketRow.CheckInDate));
	Else
		vCheckInDate = BegOfDay(CurrentSessionDate());
	EndIf;
	If ValueIsFilled(?(pOrderBasketRow = Undefined, CheckOutDate, pOrderBasketRow.CheckOutDate)) And BegOfDay(?(pOrderBasketRow = Undefined, CheckOutDate, pOrderBasketRow.CheckOutDate)) > vCheckInDate Then
		vCheckOutDate = BegOfDay(?(pOrderBasketRow = Undefined, CheckOutDate, pOrderBasketRow.CheckOutDate));
	Else
		vCheckOutDate = vCheckInDate + 24*3600;
	EndIf;
	vCheckInTime = 9 * 3600;
	vCheckOutTime = 22 * 3600;
	If ValueIsFilled(RoomRate) And RoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour Then
		If ValueIsFilled(RoomRate.DefaultCheckInTime) Or ValueIsFilled(RoomRate.DefaultCheckOutTime) Then
			vCheckInTime = RoomRate.DefaultCheckInTime - BegOfDay(RoomRate.DefaultCheckInTime);
		Else
			vCheckInTime = RoomRate.ReferenceHour - BegOfDay(RoomRate.ReferenceHour);
		EndIf;
		vCheckOutTime = RoomRate.ReferenceHour - BegOfDay(RoomRate.ReferenceHour);
		If ValueIsFilled(RoomRate.DefaultCheckOutTime) Then
			vCheckOutTime = RoomRate.DefaultCheckOutTime - BegOfDay(RoomRate.DefaultCheckOutTime);
		EndIf;
	EndIf;
	vCheckInDate = cm1SecondShift(vCheckInDate + vCheckInTime);
	vCheckOutDate = cm0SecondShift(vCheckOutDate + vCheckOutTime);
	If BegOfDay(vCheckOutDate) <= BegOfDay(vCheckInDate) Then
		vCheckOutDate = vCheckOutDate + 24 * 3600;
	EndIf;
	vDuration = cmCalculateDuration(RoomRate, vCheckInDate, vCheckOutDate);
	vKidsAges = New Array();
	For i = 1 To NumberOfKids Do
		vKidsAges.Add(ThisObject["KidAge" + i]);
	EndDo;
	vBedsSetup = ?(pOrderBasketRow = Undefined, SelBedsSetup, pOrderBasketRow.BedsSetup);
	If AccommodationTypesTable.Count() > 0 Then
		vNumberOfPersons = 1;
		vRowStruct = New Structure("Hotel, RoomQuota, RoomType, RoomQuantity, AccommodationType, NumberOfPersons, CheckInDate, Duration, CheckOutDate, RoomRate, ClientType, Company, Posted, DeletionMark, ServicePackage, SourceOfBusiness, MarketingCode, TripPurpose, GuaranteeType, DiscountType, IsForFolioSplit, NumberOfAdults, NumberOfKids, KidsAges, BedsSetup", 
		                           vCurHotel, RoomQuota, ?(pOrderBasketRow = Undefined, SelRoomType, pOrderBasketRow.RoomType), ?(pOrderBasketRow = Undefined, RoomQuantity, pOrderBasketRow.RoomQuantity), ?(pAccommodationType = Undefined, AccommodationTypesTable.Get(0).AccommodationType, pAccommodationType), vNumberOfPersons, vCheckInDate, vDuration, vCheckOutDate, ?(pOrderBasketRow = Undefined, RoomRate, pOrderBasketRow.RoomRate), ?(pOrderBasketRow = Undefined, ClientType, pOrderBasketRow.ClientType), vCompany, False, False, ?(pOrderBasketRow = Undefined, MealBoardTerm, pOrderBasketRow.MealBoardTerm), vGuestGroup.SourceOfBusiness, vGuestGroup.MarketingCode, vGuestGroup.TripPurpose, vGuestGroup.GuaranteeType, ?(pOrderBasketRow = Undefined, DiscountType, pOrderBasketRow.DiscountType), IsForFolioSplit, NumberOfAdults, NumberOfKids, vKidsAges, vBedsSetup);
	Else
		vRowStruct = New Structure("Hotel, RoomQuota, RoomType, RoomQuantity, AccommodationType, CheckInDate, Duration, CheckOutDate, RoomRate, ClientType, Company, ServicePackage, SourceOfBusiness, MarketingCode, TripPurpose, GuaranteeType, DiscountType, IsForFolioSplit, NumberOfAdults, NumberOfKids, KidsAges, BedsSetup", 
		                           vCurHotel, RoomQuota, ?(pOrderBasketRow = Undefined, SelRoomType, pOrderBasketRow.RoomType), ?(pOrderBasketRow = Undefined, RoomQuantity, pOrderBasketRow.RoomQuantity), pAccommodationType, vCheckInDate, vDuration, vCheckOutDate, ?(pOrderBasketRow = Undefined, RoomRate, pOrderBasketRow.RoomRate), ?(pOrderBasketRow = Undefined, ClientType, pOrderBasketRow.ClientType), vCompany, ?(pOrderBasketRow = Undefined, MealBoardTerm, pOrderBasketRow.MealBoardTerm), vGuestGroup.SourceOfBusiness, vGuestGroup.MarketingCode, vGuestGroup.TripPurpose, vGuestGroup.GuaranteeType, ?(pOrderBasketRow = Undefined, DiscountType, pOrderBasketRow.DiscountType), IsForFolioSplit, NumberOfAdults, NumberOfKids, vKidsAges, vBedsSetup);
	EndIf;
	Return vRowStruct;
EndFunction // GetParameters

// ------------------------------------------------------------------------------------------------
&AtServerNoContext
Function GetMealBoardTermsList(pHotel, pContract)
	vTermsList = New ValueList();
	vTerms = cmGetAllMealBoardTerms(pHotel);
	If ValueIsFilled(pContract) Then
		For Each vTermsRow In vTerms Do
			If vTermsRow.Ref = pContract.MealBoardTerm Then
				If vTermsList.FindByValue(vTermsRow.Ref) = Undefined Then
					vTermsList.Add(vTermsRow.Ref);
				EndIf;
			ElsIf pContract.MealBoardTerms.Count() > 0 Then
				If pContract.MealBoardTerms.Find(vTermsRow.Ref, "MealBoardTerm") <> Undefined Then
					If vTermsList.FindByValue(vTermsRow.Ref) = Undefined Then
						vTermsList.Add(vTermsRow.Ref);
					EndIf;
				EndIf;
			Else
				If vTermsList.FindByValue(vTermsRow.Ref) = Undefined Then
					vTermsList.Add(vTermsRow.Ref);
				EndIf;
			EndIf;
		EndDo;
	Else
		vTermsList.LoadValues(vTerms.UnloadColumn("Ref"));
	EndIf;
	Return vTermsList;
EndFunction // GetMealBoardTermsList

// -----------------------------------------------------------------------------
&AtServer
Procedure RoomQuotaOnChangeAtServer()
	Items.MealBoardTerm.ListChoiceMode = False;
	vSavRoomRate = RoomRate;
	DefaultContract = Undefined;
	DiscountType = Undefined;
	If ValueIsFilled(RoomQuota) Then
		If ValueIsFilled(RoomQuota.RoomRate) Then
			RoomRate = RoomQuota.RoomRate;
		EndIf;
		If ValueIsFilled(RoomQuota.Customer) Then
			DefaultContract = RoomQuota.Contract;
			If Not ValueIsFilled(DefaultContract) Then
				vValidContracts = cmGetListOfValidContracts(RoomQuota.Customer, ?(ValueIsFilled(CheckInDate), CheckInDate, BegOfDay(CurrentSessionDate())), ?(ValueIsFilled(CheckOutDate), CheckOutDate, EndOfDay(CurrentSessionDate())), CurrentSessionDate());
				If vValidContracts.Count() = 1 Then
					DefaultContract = vValidContracts.Get(0).Value;
				EndIf;
			EndIf;
			If ValueIsFilled(DefaultContract) Then
				// Meal board term
				If ValueIsFilled(DefaultContract.MealBoardTerm) Then
					MealBoardTerm = DefaultContract.MealBoardTerm;
					Items.MealBoardTerm.ListChoiceMode = True;
					Items.MealBoardTerm.ChoiceList.LoadValues(GetMealBoardTermsList(Hotel, DefaultContract).UnloadValues());
				EndIf;
				// Discount
				vDiscountType = Undefined;
				If ValueIsFilled(DefaultContract.DiscountType) Then
					vDiscountType = DefaultContract.DiscountType;
				Else
					For Each vRRRow In DefaultContract.RoomRates Do
						If ValueIsFilled(vRRRow.DiscountType) Then
							If Not ValueIsFilled(vRRRow.CheckInDateFrom) And Not ValueIsFilled(vRRRow.CheckInDateTo) And 
							   Not ValueIsFilled(vRRRow.ReservationDateFrom) And Not ValueIsFilled(vRRRow.ReservationDateTo) Then
								vDiscountType = vRRRow.DiscountType;
								Break;
							ElsIf (Not ValueIsFilled(vRRRow.ReservationDateFrom) Or ValueIsFilled(vRRRow.ReservationDateFrom) And vRRRow.ReservationDateFrom <= CurrentSessionDate()) And 
								  (Not ValueIsFilled(vRRRow.ReservationDateTo) Or ValueIsFilled(vRRRow.ReservationDateTo) And EndOfDay(vRRRow.ReservationDateTo) > CurrentSessionDate()) And 
								  (Not ValueIsFilled(vRRRow.CheckInDateFrom) Or ValueIsFilled(vRRRow.CheckInDateFrom) And vRRRow.CheckInDateFrom <= CheckInDate And ValueIsFilled(CheckInDate)) And 
								  (Not ValueIsFilled(vRRRow.CheckInDateTo) Or ValueIsFilled(vRRRow.CheckInDateTo) And EndOfDay(vRRRow.CheckInDateTo) > CheckInDate And ValueIsFilled(CheckInDate)) Then
								vDiscountType = vRRRow.DiscountType;
								Break;
							EndIf;
						EndIf;
					EndDo;
				EndIf;
				DiscountType = vDiscountType;
			EndIf;
		EndIf;
	Else
		If ValueIsFilled(Hotel) And ValueIsFilled(Hotel.RoomRate) Then
			RoomRate = Hotel.RoomRate;
		EndIf;
	EndIf;
	If vSavRoomRate <> RoomRate And ValueIsFilled(RoomRate) Then
		If RoomRate.ClientType <> ClientType Then
			ClientType = RoomRate.ClientType;
		EndIf;
		If ValueIsFilled(RoomRate.DiscountType) Then
			DiscountType = RoomRate.DiscountType;
		EndIf;
		If ValueIsFilled(RoomRate.ServicePackage) And RoomRate.ServicePackage.IsMealBoardTerm Then
			MealBoardTerm = RoomRate.ServicePackage;
		EndIf;
	EndIf;
	BuildReport();
EndProcedure // RoomQuotaOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetOccupationPercent(pHotel = Undefined, pPeriodFrom = Undefined, pPeriodTo = Undefined)
	vHotel = pHotel; 
	If vHotel = Undefined Then 
		vHotel = SessionParameters.CurrentHotel;
	EndIf;
	
	vForecastStartDate = tcOnServer.GetForecastStartDate(vHotel);
	
	vPeriodFrom = pPeriodFrom; 
	If vPeriodFrom = Undefined Then 
		vPeriodFrom = BegOfDay(CurrentSessionDate());
	EndIf;

	vPeriodTo = pPeriodTo; 
	If vPeriodTo = Undefined Then
		vPeriodTo = EndOfDay(CurrentSessionDate());
	EndIf;
	
	// Run query to get room inventory
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	BEGINOFPERIOD(RoomSalesTurnovers.Period, DAY) AS Period,
	|	RoomSalesTurnovers.RoomsRentedTurnover AS RoomsRentedTurnover,
	|	RoomSalesTurnovers.BedsRentedTurnover AS BedsRentedTurnover
	|INTO RoomSalesTurnovers
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qSalesPeriodFrom,
	|			&qSalesPeriodTo,
	|			DAY,
	|			&qUseDataFromSales
	|				AND Hotel IN HIERARCHY (&qHotel)) AS RoomSalesTurnovers
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomSalesForecast.Period AS Period,
	|	SUM(RoomSalesForecast.RoomsRentedTurnover) AS RoomsRentedTurnover,
	|	SUM(RoomSalesForecast.BedsRentedTurnover) AS BedsRentedTurnover,
	|	SUM(RoomSalesForecast.DefiniteRoomsRentedTurnover) AS DefiniteRoomsRentedTurnover,
	|	SUM(RoomSalesForecast.DefiniteBedsRentedTurnover) AS DefiniteBedsRentedTurnover
	|INTO RoomSalesForecastTurnovers
	|FROM
	|	(SELECT
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
	|					AND Hotel IN HIERARCHY (&qHotel)) AS RoomSalesForecastTurnovers) AS RoomSalesForecast
	|
	|GROUP BY
	|	RoomSalesForecast.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BEGINOFPERIOD(RoomInventoryBalance.Period, DAY) AS Period,
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
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qPeriodFrom, &qPeriodTo, DAY, RegisterRecordsAndPeriodBoundaries, Hotel IN HIERARCHY (&qHotel)) AS RoomInventoryBalance
	|		LEFT JOIN (SELECT
	|			RoomSalesTurnovers.Period AS Period,
	|			RoomSalesTurnovers.RoomsRentedTurnover AS RoomsRented,
	|			RoomSalesTurnovers.BedsRentedTurnover AS BedsRented
	|		FROM
	|			RoomSalesTurnovers AS RoomSalesTurnovers) AS RoomSales
	|		ON (BEGINOFPERIOD(RoomInventoryBalance.Period, DAY) = RoomSales.Period)
	|		LEFT JOIN (SELECT
	|			RoomSalesForecastTurnovers.Period AS Period,
	|			RoomSalesForecastTurnovers.RoomsRentedTurnover AS RoomsRented,
	|			RoomSalesForecastTurnovers.BedsRentedTurnover AS BedsRented,
	|			RoomSalesForecastTurnovers.DefiniteRoomsRentedTurnover AS DefiniteRoomsRented,
	|			RoomSalesForecastTurnovers.DefiniteBedsRentedTurnover AS DefiniteBedsRented
	|		FROM
	|			RoomSalesForecastTurnovers AS RoomSalesForecastTurnovers) AS RoomSalesForecast
	|		ON (BEGINOFPERIOD(RoomInventoryBalance.Period, DAY) = RoomSalesForecast.Period)
	|		LEFT JOIN (SELECT
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
	|						AND RoomQuota.IsCommitment
	|						AND RoomQuota.AllotmentBusinessType <> VALUE(Enum.AllotmentBusinessTypes.BusinessBlock)
	|						AND (&qUseDataFromSales
	|							OR NOT &qUseDataFromSales
	|								AND NOT RoomQuota.DoWriteOff)) AS CommitmentAllotmentsBalanceAndTurnovers) AS CommitmentAllotments
	|		ON (BEGINOFPERIOD(RoomInventoryBalance.Period, DAY) = CommitmentAllotments.Period)
	|		LEFT JOIN (SELECT
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
	|						AND RoomQuota.AllotmentBusinessType = VALUE(Enum.AllotmentBusinessTypes.BusinessBlock)
	|						AND RoomQuota.AllotmentType <> VALUE(Enum.AllotmentTypes.DoNotChangeAvailability)
	|						AND RoomQuota.AllotmentType <> VALUE(Enum.AllotmentTypes.Cancelled)
	|						AND NOT &qUseDataFromSales) AS BusinessBlocksBalanceAndTurnovers) AS BusinessBlocks
	|		ON (BEGINOFPERIOD(RoomInventoryBalance.Period, DAY) = BusinessBlocks.Period)
	|		LEFT JOIN (SELECT
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
	|						AND RoomQuota.AllotmentBusinessType = VALUE(Enum.AllotmentBusinessTypes.BusinessBlock)
	|						AND (RoomQuota.AllotmentType = VALUE(Enum.AllotmentTypes.Definite)
	|							OR RoomQuota.AllotmentType = VALUE(Enum.AllotmentTypes.DefiniteNotGuaranteed))
	|						AND NOT &qUseDataFromSales) AS BusinessBlocksBalanceAndTurnovers) AS DefiniteBusinessBlocks
	|		ON (BEGINOFPERIOD(RoomInventoryBalance.Period, DAY) = BusinessBlocks.Period)
	|
	|ORDER BY
	|	Period";
	vQry.SetParameter("qUseDataFromSales", True);
	vQry.SetParameter("qTakeCommitmentIntoAccount", True);
	vQry.SetParameter("qPeriodFrom", vPeriodFrom);
	vQry.SetParameter("qPeriodTo", vPeriodTo);
	vQry.SetParameter("qSalesPeriodFrom", BegOfDay(vPeriodFrom));
	vQry.SetParameter("qSalesPeriodTo", EndOfDay(vPeriodTo));
	vQry.SetParameter("qForecastPeriodFrom", BegOfDay(Max(vForecastStartDate, vPeriodFrom)));
	vQry.SetParameter("qForecastPeriodTo", EndOfDay(Max(vForecastStartDate, vPeriodTo)));
	vQry.SetParameter("qHotel", vHotel);
	vInvResult = vQry.Execute().Unload();
	
	Return vInvResult;
EndFunction	// GetOccupationPercent

// -----------------------------------------------------------------------------
&AtServer
Procedure ShowPricesOnChangeAtServer(pShowPrices)
	If Not DoNotSaveSettings Then
		SystemSettingsStorage.Save("ShowPrices", "tcAvailableRoomsReport", pShowPrices);
	EndIf;
	
	vNumberOfDays = 0;
	If pShowPrices Then
		vNumberOfDays = SystemSettingsStorage.Load("NumberOfDaysShowPrices", "tcAvailableRoomsReport");
		If vNumberOfDays = Undefined Then
			vNumberOfDays = 31;
		EndIf;
	Else 
		vNumberOfDays = SystemSettingsStorage.Load("NumberOfDays", "tcAvailableRoomsReport");
		If vNumberOfDays = Undefined Then
			vNumberOfDays = 62;
		EndIf;
	EndIf;
	If cmIsNumber(vNumberOfDays) And vNumberOfDays <> 0 Then
		NumberOfDays = vNumberOfDays;
	EndIf;
	If NumberOfDays < 1 Or NumberOfDays > 999 Then
		If ShowPrices Then
			NumberOfDays = 31;
		Else
			NumberOfDays = 62;
		EndIf;
	EndIf;

	If NumberOfAdults = 0 And NumberOfKids = 0 Then
		NumberOfAdults = 1;
	EndIf;	
EndProcedure // ShowPricesOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function CalculateCheckOutDateAtServer(pRoomRate, pCheckInDate, pDuration)
	Return cmCalculateCheckOutDate(pRoomRate, pCheckInDate, pDuration);
EndFunction // CalculateCheckOutDateAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetAllowedRoomRates()
	vRoomRates = New ValueList();
	vCustomer = Undefined;
	If ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Customer) Then
		vCustomer = SessionParameters.CurrentUser.Customer;
	EndIf;
	If ValueIsFilled(vCustomer) And vCustomer.RoomRates.Count() > 0 Then
		vRoomRates.LoadValues(vCustomer.RoomRates.UnloadColumn("RoomRate"));
	EndIf;
	vRoomRatesAllowed = cmGetAllowedRoomRates(CheckInDate, CheckOutDate, CurrentSessionDate(), SelRoomType);
	If vRoomRatesAllowed.Count() > 0 Then
		If vRoomRates.Count() > 0 Then
			vInt = 0;
			While vInt < vRoomRates.Count() Do
				vFrmRoomRate = vRoomRates.Get(vInt);
				If vRoomRatesAllowed.FindByValue(vFrmRoomRate.Value) = Undefined Then
					vRoomRates.Delete(vInt);
				Else
					vInt = vInt + 1;
				EndIf;
			EndDo;
		Else
			vRoomRates.LoadValues(vRoomRatesAllowed.UnloadValues());
		EndIf;
		If vRoomRates.Count() = 0 Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to change room rate!';ru='Нет прав на изменение тарифа!';de='Sie haben keine Rechte, die Tarife zu bearbeiten!'"));
		EndIf;
	EndIf;
	Return vRoomRates;
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Function CalculateDurationAtServer(pRoomRate, pCheckInDate, pCheckOutDate)
	Return cmCalculateDuration(pRoomRate, pCheckInDate, pCheckOutDate);
EndFunction // CalculateDurationAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure GetDates(vCheckInDate, vCheckOutDate, vDuration, pRoomRate)
	vCheckInTime = 9 * 3600;
	vCheckOutTime = 22 * 3600;
	If ValueIsFilled(pRoomRate) And pRoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour Then
		If ValueIsFilled(pRoomRate.DefaultCheckInTime) Or ValueIsFilled(pRoomRate.DefaultCheckOutTime) Then
			vCheckInTime = pRoomRate.DefaultCheckInTime - BegOfDay(pRoomRate.DefaultCheckInTime);
		Else
			vCheckInTime = pRoomRate.ReferenceHour - BegOfDay(pRoomRate.ReferenceHour);
		EndIf;
		vCheckOutTime = pRoomRate.ReferenceHour - BegOfDay(pRoomRate.ReferenceHour);
		If ValueIsFilled(pRoomRate.DefaultCheckOutTime) Then
			vCheckOutTime = pRoomRate.DefaultCheckOutTime - BegOfDay(pRoomRate.DefaultCheckOutTime);
		EndIf;
	EndIf;
	vCheckInDate = cm1SecondShift(vCheckInDate + vCheckInTime);
	vCheckOutDate = cm0SecondShift(vCheckOutDate + vCheckOutTime);
	If BegOfDay(vCheckOutDate) <= BegOfDay(vCheckInDate) Then
		vCheckOutDate = vCheckOutDate + 24 * 3600;
	EndIf;
	vDuration = cmCalculateDuration(pRoomRate, vCheckInDate, vCheckOutDate);
EndProcedure // GetDates

// -----------------------------------------------------------------------------
&AtClient
Procedure CalculateOrderBasketTotals()
	OrderBasketAmount = Format(OrderBasket.Total("Amount"), "NFD=2; NZ=");
	OrderBasketRoomQuantity = OrderBasket.Total("RoomQuantity");
	OrderBasketNumberOfAdults = OrderBasket.Total("NumberOfAdults");
	OrderBasketNumberOfKids = OrderBasket.Total("NumberOfKids");
EndProcedure // CalculateOrderBasketTotals

// -----------------------------------------------------------------------------
&AtClient
Procedure AskForBasketRecalculation()
	// Ask should we recalculate order basket rows
	vQuery = NStr("en='Do you need to recalculate order basket rows?'; ru='Нужно пересчитать цену строк корзины заказа?'; de='Müssen Sie die Bestellkorbzeilen neu berechnen?'");
	vNotifyDescr = New NotifyDescription("OrderBasketRowRecalculationQueryAfterAnswer", ThisObject);
	ShowQueryBox(vNotifyDescr, vQuery, QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
EndProcedure // AskForBasketRecalculation

// -----------------------------------------------------------------------------
&AtClient
Procedure OrderBasketRowRecalculationQueryAfterAnswer(pAnswer, pExtraParams) Export
	If pAnswer = DialogReturnCode.Yes Then
		RecalculateOrderBasketRowsAtServer();
		CalculateOrderBasketTotals();
	EndIf;
EndProcedure // OrderBasketRowRecalculationQueryAfterAnswer

// -----------------------------------------------------------------------------
&AtServer
Procedure RecalculateOrderBasketRowsAtServer()
	For Each vOrderRow In OrderBasket Do
		vOrderRow.RoomRate = RoomRate;
		vOrderRow.ClientType = ClientType;
		vOrderRow.MealBoardTerm = MealBoardTerm;
		vOrderRow.DiscountType = DiscountType;
		RecalculateOrderRowPriceAtServer(vOrderRow);
	EndDo;
EndProcedure // RecalculateOrderBasketRowsAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure GuestGroupOnChangeAtServer()
	If ValueIsFilled(GuestGroup.ClientType) Then
		ClientType = GuestGroup.ClientType;
	EndIf;
	If ValueIsFilled(GuestGroup.RoomRate) Then
		RoomRate = GuestGroup.RoomRate;
	EndIf;
	If ValueIsFilled(GuestGroup.ServicePackage) And GuestGroup.ServicePackage.IsMealBoardTerm Then
		MealBoardTerm = GuestGroup.ServicePackage;
	EndIf;
	If ValueIsFilled(GuestGroup.DiscountType) Then
		DiscountType = GuestGroup.DiscountType;
	EndIf;
EndProcedure // GuestGroupOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure PrintReport_AtServer()
	
	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure HotelOnChangeAtServer()
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(Hotel, "BackgroundColorImportant");
	ShowInBeds = Hotel.ShowReportsInBeds;
	RoomRate = Hotel.RoomRate;
	If ValueIsFilled(Hotel.AccommodationType) And Hotel.AccommodationType.Type = Enums.AccomodationTypes.Beds Then
		IsForFolioSplit = True;
	EndIf;
	SelRoomType = Undefined;
	If ValueIsFilled(RoomQuota) And ValueIsFilled(RoomQuota.Hotel) And RoomQuota.Hotel <> Hotel Then
		RoomQuota = Undefined;
	EndIf;
	Items.CalculateButton.Title = NStr("en='Calculate'; ru='Рассчитать'; de='Berechnen'");
	Items.CalculateButton.ExtendedToolTip.Title = NStr("en = 'Calculate room price'; de = 'Berechnen Sie den Preis eines Zimmers'; ru = 'Рассчитать стоимость номера'");
	AccommodationTypesTable.Clear();
	Items.AccommodationTypesTablePrice.FooterText = "";
	GuestGroup = Undefined;
	vTerms = cmGetAllMealBoardTerms(Hotel);
	If vTerms.Count() > 0 Then
		Items.MealBoardTerm.Visible = True;
	Else
		Items.MealBoardTerm.Visible = False;
	EndIf;
	If ValueIsFilled(Hotel) And Not Hotel.IsFolder Then
		If ValueIsFilled(RoomQuota) And ValueIsFilled(RoomQuota.Hotel) And RoomQuota.Hotel <> Hotel Then
			RoomQuota = Undefined;
		EndIf;
		If ValueIsFilled(ClientType) And ValueIsFilled(ClientType.Hotel) And ClientType.Hotel <> Hotel Then
			ClientType = Undefined;
		EndIf;
		If ValueIsFilled(RoomRate) And ValueIsFilled(RoomRate.Hotel) And RoomRate.Hotel <> Hotel Then
			RoomRate = Hotel.RoomRate;
		EndIf;
		If ValueIsFilled(MealBoardTerm) And ValueIsFilled(MealBoardTerm.Hotel) And MealBoardTerm.Hotel <> Hotel Then
			MealBoardTerm = Undefined;
		EndIf;
		If ValueIsFilled(DiscountType) And ValueIsFilled(DiscountType.Hotel) And DiscountType.Hotel <> Hotel Then
			DiscountType = Undefined;
		EndIf;
	EndIf;	
	// Beds setup availability
	Items.SelBedsSetup.Visible = GetBedsSetupFunctionalOption();
	// Refresh form
	BuildReport();    
EndProcedure // HotelOnChangeAtServer

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetBedsSetupList(pBedsSetup, pRoomType)
	vBedsSetupList = New ValueList();
	If ValueIsFilled(pRoomType) And pRoomType.AllowedBedsSetups.Count() > 0 Then
		For Each vRow In pRoomType.AllowedBedsSetups Do
			If ValueIsFilled(vRow.BedsSetup) And vBedsSetupList.FindByValue(vRow.BedsSetup) = Undefined Then
				vBedsSetupList.Add(vRow.BedsSetup);
			EndIf;
		EndDo;
	EndIf;
	If ValueIsFilled(pBedsSetup) Then
		If vBedsSetupList.FindByValue(pBedsSetup) = Undefined Then
			vBedsSetupList.Insert(0, pBedsSetup);
		EndIf;
	EndIf;
	Return vBedsSetupList;
EndFunction // GetBedsSetupList

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
&AtServer
Procedure BuildReport(pPrintMode = False) Export
	vShowZeroes = False;
	If ValueIsFilled(Hotel) And Hotel.ShowZeroesInAvailability Then
		vShowZeroes = True;
	EndIf;
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(Hotel, "BackgroundColorImportant");
	// Price tag visibility
	If ValueIsFilled(RoomRate) And (RoomRate.PriceTagType = Enums.PriceTagTypes.ByDurationOfStayByDays Or RoomRate.PriceTagType = Enums.PriceTagTypes.ByDurationOfStayByPeriod) Then
		Items.PriceTag.Visible = True;
	Else
		PriceTag = Catalogs.PriceTags.EmptyRef();
		Items.PriceTag.Visible = False;
	EndIf;
	// Initialize number of days to output and period
	If NumberOfDays <= 0 Then
		If ShowPrices Then
			NumberOfDays = 31;
		Else
			NumberOfDays = 62;
		EndIf;
	EndIf;
	vNumberOfDays = NumberOfDays;
	
	vRH = '00010101000000';
	vCurrentDateTime = CurrentSessionDate();
	vCurrentDate = BegOfDay(vCurrentDateTime);
	vCT = '00010101' + (vCurrentDateTime - BegOfDay(vCurrentDateTime));
	vDateFrom = BegOfDay(DateFrom);
	vDateTimeFromToday = vCurrentDate;
	If ValueIsFilled(RoomRate) And RoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour Then
		vRH = '00010101120000';
		vCI = '00010101120000';
		If ValueIsFilled(RoomRate.ReferenceHour) Then
			vRH = '00010101' + (RoomRate.ReferenceHour - BegOfDay(RoomRate.ReferenceHour));
			vCI = vRH;
		EndIf;
		If ValueIsFilled(RoomRate.DefaultCheckInTime) Then
			vCI = '00010101' + (RoomRate.DefaultCheckInTime - BegOfDay(RoomRate.DefaultCheckInTime));
		EndIf;
		If vCT < vCI Then
			vDateTimeFrom = ?(vDateFrom = vCurrentDate, vDateFrom + (vCI - BegOfDay(vCI)), vDateFrom + (vRH - BegOfDay(vRH)));
			vDateTimeFromToday = vCurrentDate + (vCI - BegOfDay(vCI));
		Else
			vDateTimeFrom = ?(vDateFrom = vCurrentDate, vDateFrom + (vCT - BegOfDay(vCT)), vDateFrom + (vRH - BegOfDay(vRH)));
			vDateTimeFromToday = vCurrentDate + (vCT - BegOfDay(vCT));
		EndIf;
	Else
		vDateTimeFrom = ?(vDateFrom = vCurrentDate, vDateFrom + (vCT - BegOfDay(vCT)), vDateFrom);
		vDateTimeFromToday = vCurrentDate + (vCT - BegOfDay(vCT));
	EndIf;
	vDateTimeFrom = cm1SecondShift(vDateTimeFrom);
	vDateTo = vDateFrom + 24 * 3600 * (vNumberOfDays - 1);
	vDateTimeTo = EndOfDay(vDateTo);
	vShiftInSeconds =  ?(ValueIsFilled(RoomRate), -(RoomRate.ReferenceHour - BegOfDay(RoomRate.ReferenceHour)), -43200);
	vShowReportsInBeds = ShowInBeds;
	
	vNextPeriod = DateFrom + (NumberOfDays - 1) * 86400;
	vPrevPeriod = DateFrom - (NumberOfDays - 1) * 86400;
	
	Items.FormPrevPeriodButton.Title = Format(vPrevPeriod, "DF=dd.MM.yyyy");
	Items.FormNextPeriodButton.Title = Format(vNextPeriod, "DF=dd.MM.yyyy");
	
	// Check if room rate daily prices cache could be used
	vUsePricesCache = False;
	vRoomRates = New ValueList();
	If ValueIsFilled(RoomRate) Then
		vRoomRates.Add(RoomRate);
	EndIf;
	vCachedPricesTab = New ValueTable();
	If ShowPrices Then
		If Not ValueIsFilled(MealBoardTerm) And 
		  (Not ValueIsFilled(RoomQuota) Or ValueIsFilled(RoomQuota) And Not ValueIsFilled(RoomQuota.Agent)) Then
			If ValueIsFilled(Hotel) And Hotel.UseRoomRateDailyPrices And cmRoomRatePricesCacheIsFilled(Hotel, vRoomRates, ClientType, vDateFrom, vDateTo) Then
				vUsePricesCache = True;
			EndIf;
		EndIf;
	EndIf;
	If vUsePricesCache Then
		vAccTemplatesList = New ValueList;
		vKidsAgeArray = New Array();
		vInt = 1;
		While vInt <= NumberOfKids Do
			vKidsAgeArray.Add(ThisObject["KidAge" + Format(vInt, "NFD=0; NZ=; NG=")]);
			vInt = vInt + 1;
		EndDo;
		vAccTemplates = cmGetAccommodationTemplateDetailsByGuestsQuantity(NumberOfAdults, NumberOfKids, vKidsAgeArray, Hotel);
		For Each vAccTemplatesRow In vAccTemplates Do
			If vAccTemplatesList.FindByValue(vAccTemplatesRow.AccommodationTemplate) = Undefined Then
				vAccTemplatesList.Add(vAccTemplatesRow.AccommodationTemplate);
			EndIf;
		EndDo;
		If ValueIsFilled(RoomRate) And (RoomRate.PriceTagType = Enums.PriceTagTypes.ByDurationOfStayByDays Or RoomRate.PriceTagType = Enums.PriceTagTypes.ByDurationOfStayByPeriod) Then
			vCachedPricesTab = cmGetCachedPricesByDays(Hotel, ClientType, BegOfDay(vDateFrom), EndOfDay(vDateTo), PriceTag, vRoomRates, vAccTemplatesList, , , DiscountType);
		Else
			vCachedPricesTab = cmGetCachedPricesForPriceTagsByDays(Hotel, ClientType, BegOfDay(vDateFrom), EndOfDay(vDateTo), vRoomRates, vAccTemplatesList, , , DiscountType);
		EndIf;
		vCachedPricesTab.GroupBy("Period, RoomType, Currency", "Amount");
	EndIf;

	// Get active events
	vEvents = cmGetEvents(vDateTimeFrom, vDateTimeTo, Hotel);
	
	// Build and run query with room inventory balances
	vQry = New Query();
	vQry.Text =	
	"SELECT
	|	BEGINOFPERIOD(RoomInventoryBalance.Period, DAY) AS Period,
	|	RoomInventoryBalance.Hotel AS Hotel,
	|	RoomInventoryBalance.RoomType AS RoomType,
	|	MAX(CASE
	|			WHEN &qRoomQuotaIsSet
	|					AND &qDoWriteOff
	|				THEN ISNULL(RoomQuotaBalances.RoomsInQuota, 0)
	|			WHEN &qRoomQuotaIsSet
	|					AND NOT &qDoWriteOff
	|				THEN ISNULL(RoomInventoryBalance.TotalRoomsClosingBalance, 0)
	|			ELSE ISNULL(RoomInventoryBalance.TotalRoomsClosingBalance, 0)
	|		END) AS TotalRooms,
	|	MAX(CASE
	|			WHEN &qRoomQuotaIsSet
	|					AND &qDoWriteOff
	|				THEN ISNULL(RoomQuotaBalances.BedsInQuota, 0)
	|			WHEN &qRoomQuotaIsSet
	|					AND NOT &qDoWriteOff
	|				THEN ISNULL(RoomInventoryBalance.TotalBedsClosingBalance, 0)
	|			ELSE ISNULL(RoomInventoryBalance.TotalBedsClosingBalance, 0)
	|		END) AS TotalBeds,
	|	MAX(CASE
	|			WHEN &qRoomQuotaIsSet
	|					AND &qDoWriteOff
	|				THEN ISNULL(RoomQuotaBalances.RoomsInQuota, 0)
	|			WHEN &qRoomQuotaIsSet
	|					AND NOT &qDoWriteOff
	|				THEN ISNULL(RoomInventoryBalance.TotalSpecialRoomsClosingBalance, 0)
	|			ELSE ISNULL(RoomInventoryBalance.TotalSpecialRoomsClosingBalance, 0)
	|		END) AS TotalSpecialRooms,
	|	MAX(CASE
	|			WHEN &qRoomQuotaIsSet
	|					AND &qDoWriteOff
	|				THEN ISNULL(RoomQuotaBalances.BedsInQuota, 0)
	|			WHEN &qRoomQuotaIsSet
	|					AND NOT &qDoWriteOff
	|				THEN ISNULL(RoomInventoryBalance.TotalSpecialBedsClosingBalance, 0)
	|			ELSE ISNULL(RoomInventoryBalance.TotalSpecialBedsClosingBalance, 0)
	|		END) AS TotalSpecialBeds,
	|	MIN(CASE
	|			WHEN &qRoomQuotaIsSet
	|					AND &qDoWriteOff
	|				THEN ISNULL(RoomQuotaBalances.RoomsRemains, 0)
	|			WHEN &qRoomQuotaIsSet
	|					AND NOT &qDoWriteOff
	|					AND ISNULL(RoomInventoryBalance.RoomsVacantClosingBalance, 0) < ISNULL(RoomQuotaBalances.RoomsRemains, 0)
	|				THEN ISNULL(RoomInventoryBalance.RoomsVacantClosingBalance, 0)
	|			WHEN &qRoomQuotaIsSet
	|					AND NOT &qDoWriteOff
	|					AND ISNULL(RoomInventoryBalance.RoomsVacantClosingBalance, 0) >= ISNULL(RoomQuotaBalances.RoomsRemains, 0)
	|				THEN ISNULL(RoomQuotaBalances.RoomsRemains, 0)
	|			ELSE ISNULL(RoomInventoryBalance.RoomsVacantClosingBalance, 0)
	|		END) AS RoomsVacant,
	|	MIN(CASE
	|			WHEN &qRoomQuotaIsSet
	|					AND &qDoWriteOff
	|				THEN ISNULL(RoomQuotaBalances.BedsRemains, 0)
	|			WHEN &qRoomQuotaIsSet
	|					AND NOT &qDoWriteOff
	|					AND ISNULL(RoomInventoryBalance.BedsVacantClosingBalance, 0) < ISNULL(RoomQuotaBalances.BedsRemains, 0)
	|				THEN ISNULL(RoomInventoryBalance.BedsVacantClosingBalance, 0)
	|			WHEN &qRoomQuotaIsSet
	|					AND NOT &qDoWriteOff
	|					AND ISNULL(RoomInventoryBalance.BedsVacantClosingBalance, 0) >= ISNULL(RoomQuotaBalances.BedsRemains, 0)
	|				THEN ISNULL(RoomQuotaBalances.BedsRemains, 0)
	|			ELSE ISNULL(RoomInventoryBalance.BedsVacantClosingBalance, 0)
	|		END) AS BedsVacant
	|INTO VacantRoomsInThePast
	|FROM
	|	(SELECT
	|		BEGINOFPERIOD(RoomInventoryBalanceAndTurnovers.Period, DAY) AS Period,
	|		RoomInventoryBalanceAndTurnovers.Hotel AS Hotel,
	|		RoomInventoryBalanceAndTurnovers.RoomType AS RoomType,
	|		ISNULL(RoomInventoryBalanceAndTurnovers.CounterClosingBalance, 0) AS CounterClosingBalance,
	|		ISNULL(RoomInventoryBalanceAndTurnovers.TotalRoomsClosingBalance, 0) AS TotalRoomsClosingBalance,
	|		ISNULL(RoomInventoryBalanceAndTurnovers.TotalBedsClosingBalance, 0) AS TotalBedsClosingBalance,
	|		ISNULL(RoomInventoryBalanceAndTurnovers.TotalSpecialRoomsClosingBalance, 0) AS TotalSpecialRoomsClosingBalance,
	|		ISNULL(RoomInventoryBalanceAndTurnovers.TotalSpecialBedsClosingBalance, 0) AS TotalSpecialBedsClosingBalance,
	|		ISNULL(RoomInventoryBalanceAndTurnovers.RoomsVacantClosingBalance, 0) AS RoomsVacantClosingBalance,
	|		ISNULL(RoomInventoryBalanceAndTurnovers.BedsVacantClosingBalance, 0) AS BedsVacantClosingBalance
	|	FROM
	|		AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|				&qDateTimeFromInThePast,
	|				&qDateTimeToInThePast,
	|				DAY,
	|				RegisterRecordsAndPeriodBoundaries,
	|				&qThereIsPast
	|					AND (&qHotelIsEmpty
	|						OR Hotel IN HIERARCHY (&qHotelParent)
	|							AND NOT Hotel.DeletionMark)) AS RoomInventoryBalanceAndTurnovers) AS RoomInventoryBalance
	|		LEFT JOIN (SELECT
	|			BEGINOFPERIOD(RoomQuotaSalesBalanceAndTurnovers.Period, DAY) AS Period,
	|			RoomQuotaSalesBalanceAndTurnovers.Hotel AS Hotel,
	|			RoomQuotaSalesBalanceAndTurnovers.RoomType AS RoomType,
	|			ISNULL(RoomQuotaSalesBalanceAndTurnovers.CounterClosingBalance, 0) AS CounterClosingBalance,
	|			ISNULL(RoomQuotaSalesBalanceAndTurnovers.RoomsInQuotaClosingBalance, 0) AS RoomsInQuota,
	|			ISNULL(RoomQuotaSalesBalanceAndTurnovers.BedsInQuotaClosingBalance, 0) AS BedsInQuota,
	|			ISNULL(RoomQuotaSalesBalanceAndTurnovers.RoomsRemainsClosingBalance, 0) AS RoomsRemains,
	|			ISNULL(RoomQuotaSalesBalanceAndTurnovers.BedsRemainsClosingBalance, 0) AS BedsRemains
	|		FROM
	|			AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
	|					&qDateTimeFromInThePast,
	|					&qDateTimeToInThePast,
	|					DAY,
	|					RegisterRecordsAndPeriodBoundaries,
	|					&qThereIsPast
	|						AND (&qHotelIsEmpty
	|							OR Hotel IN HIERARCHY (&qHotelParent)
	|								AND NOT Hotel.DeletionMark)
	|						AND &qRoomQuotaIsSet
	|						AND RoomQuota = &qRoomQuota) AS RoomQuotaSalesBalanceAndTurnovers) AS RoomQuotaBalances
	|		ON RoomInventoryBalance.Hotel = RoomQuotaBalances.Hotel
	|			AND RoomInventoryBalance.RoomType = RoomQuotaBalances.RoomType
	|			AND (BEGINOFPERIOD(RoomInventoryBalance.Period, DAY) = BEGINOFPERIOD(RoomQuotaBalances.Period, DAY))
	|WHERE
	|	BEGINOFPERIOD(RoomInventoryBalance.Period, DAY) < &qCurrentDate
	|
	|GROUP BY
	|	BEGINOFPERIOD(RoomInventoryBalance.Period, DAY),
	|	RoomInventoryBalance.Hotel,
	|	RoomInventoryBalance.RoomType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BEGINOFPERIOD(RoomInventoryBalance.Period, DAY) AS Period,
	|	RoomInventoryBalance.Hotel AS Hotel,
	|	RoomInventoryBalance.RoomType AS RoomType,
	|	MAX(CASE
	|			WHEN &qRoomQuotaIsSet
	|					AND &qDoWriteOff
	|				THEN ISNULL(RoomQuotaBalances.RoomsInQuota, 0)
	|			WHEN &qRoomQuotaIsSet
	|					AND NOT &qDoWriteOff
	|				THEN ISNULL(RoomInventoryBalance.TotalRoomsClosingBalance, 0)
	|			ELSE ISNULL(RoomInventoryBalance.TotalRoomsClosingBalance, 0)
	|		END) AS TotalRooms,
	|	MAX(CASE
	|			WHEN &qRoomQuotaIsSet
	|					AND &qDoWriteOff
	|				THEN ISNULL(RoomQuotaBalances.BedsInQuota, 0)
	|			WHEN &qRoomQuotaIsSet
	|					AND NOT &qDoWriteOff
	|				THEN ISNULL(RoomInventoryBalance.TotalBedsClosingBalance, 0)
	|			ELSE ISNULL(RoomInventoryBalance.TotalBedsClosingBalance, 0)
	|		END) AS TotalBeds,
	|	MAX(CASE
	|			WHEN &qRoomQuotaIsSet
	|					AND &qDoWriteOff
	|				THEN ISNULL(RoomQuotaBalances.RoomsInQuota, 0)
	|			WHEN &qRoomQuotaIsSet
	|					AND NOT &qDoWriteOff
	|				THEN ISNULL(RoomInventoryBalance.TotalSpecialRoomsClosingBalance, 0)
	|			ELSE ISNULL(RoomInventoryBalance.TotalSpecialRoomsClosingBalance, 0)
	|		END) AS TotalSpecialRooms,
	|	MAX(CASE
	|			WHEN &qRoomQuotaIsSet
	|					AND &qDoWriteOff
	|				THEN ISNULL(RoomQuotaBalances.BedsInQuota, 0)
	|			WHEN &qRoomQuotaIsSet
	|					AND NOT &qDoWriteOff
	|				THEN ISNULL(RoomInventoryBalance.TotalSpecialBedsClosingBalance, 0)
	|			ELSE ISNULL(RoomInventoryBalance.TotalSpecialBedsClosingBalance, 0)
	|		END) AS TotalSpecialBeds,
	|	MIN(CASE
	|			WHEN &qRoomQuotaIsSet
	|					AND &qDoWriteOff
	|				THEN ISNULL(RoomQuotaBalances.RoomsRemains, 0)
	|			WHEN &qRoomQuotaIsSet
	|					AND NOT &qDoWriteOff
	|					AND ISNULL(RoomInventoryBalance.RoomsVacantClosingBalance, 0) < ISNULL(RoomQuotaBalances.RoomsRemains, 0)
	|				THEN ISNULL(RoomInventoryBalance.RoomsVacantClosingBalance, 0)
	|			WHEN &qRoomQuotaIsSet
	|					AND NOT &qDoWriteOff
	|					AND ISNULL(RoomInventoryBalance.RoomsVacantClosingBalance, 0) >= ISNULL(RoomQuotaBalances.RoomsRemains, 0)
	|				THEN ISNULL(RoomQuotaBalances.RoomsRemains, 0)
	|			ELSE ISNULL(RoomInventoryBalance.RoomsVacantClosingBalance, 0)
	|		END) AS RoomsVacant,
	|	MIN(CASE
	|			WHEN &qRoomQuotaIsSet
	|					AND &qDoWriteOff
	|				THEN ISNULL(RoomQuotaBalances.BedsRemains, 0)
	|			WHEN &qRoomQuotaIsSet
	|					AND NOT &qDoWriteOff
	|					AND ISNULL(RoomInventoryBalance.BedsVacantClosingBalance, 0) < ISNULL(RoomQuotaBalances.BedsRemains, 0)
	|				THEN ISNULL(RoomInventoryBalance.BedsVacantClosingBalance, 0)
	|			WHEN &qRoomQuotaIsSet
	|					AND NOT &qDoWriteOff
	|					AND ISNULL(RoomInventoryBalance.BedsVacantClosingBalance, 0) >= ISNULL(RoomQuotaBalances.BedsRemains, 0)
	|				THEN ISNULL(RoomQuotaBalances.BedsRemains, 0)
	|			ELSE ISNULL(RoomInventoryBalance.BedsVacantClosingBalance, 0)
	|		END) AS BedsVacant
	|INTO VacantRoomsForToday
	|FROM
	|	(SELECT
	|		BEGINOFPERIOD(DATEADD(RoomInventoryBalanceAndTurnovers.Period, SECOND, &qShiftInSeconds), DAY) AS Period,
	|		RoomInventoryBalanceAndTurnovers.Hotel AS Hotel,
	|		RoomInventoryBalanceAndTurnovers.RoomType AS RoomType,
	|		MAX(ISNULL(RoomInventoryBalanceAndTurnovers.CounterClosingBalance, 0)) AS CounterClosingBalance,
	|		MAX(ISNULL(RoomInventoryBalanceAndTurnovers.TotalRoomsClosingBalance, 0)) AS TotalRoomsClosingBalance,
	|		MAX(ISNULL(RoomInventoryBalanceAndTurnovers.TotalBedsClosingBalance, 0)) AS TotalBedsClosingBalance,
	|		MAX(ISNULL(RoomInventoryBalanceAndTurnovers.TotalSpecialRoomsClosingBalance, 0)) AS TotalSpecialRoomsClosingBalance,
	|		MAX(ISNULL(RoomInventoryBalanceAndTurnovers.TotalSpecialBedsClosingBalance, 0)) AS TotalSpecialBedsClosingBalance,
	|		MIN(ISNULL(RoomInventoryBalanceAndTurnovers.RoomsVacantClosingBalance, 0)) AS RoomsVacantClosingBalance,
	|		MIN(ISNULL(RoomInventoryBalanceAndTurnovers.BedsVacantClosingBalance, 0)) AS BedsVacantClosingBalance
	|	FROM
	|		AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|				&qDateTimeFromForToday,
	|				&qDateTimeToForToday,
	|				MINUTE,
	|				RegisterRecordsAndPeriodBoundaries,
	|				&qThereIsToday
	|					AND (&qHotelIsEmpty
	|						OR Hotel IN HIERARCHY (&qHotelParent)
	|							AND NOT Hotel.DeletionMark)) AS RoomInventoryBalanceAndTurnovers
	|	
	|	GROUP BY
	|		BEGINOFPERIOD(DATEADD(RoomInventoryBalanceAndTurnovers.Period, SECOND, &qShiftInSeconds), DAY),
	|		RoomInventoryBalanceAndTurnovers.Hotel,
	|		RoomInventoryBalanceAndTurnovers.RoomType) AS RoomInventoryBalance
	|		LEFT JOIN (SELECT
	|			BEGINOFPERIOD(RoomQuotaSalesBalanceAndTurnovers.Period, DAY) AS Period,
	|			RoomQuotaSalesBalanceAndTurnovers.Hotel AS Hotel,
	|			RoomQuotaSalesBalanceAndTurnovers.RoomType AS RoomType,
	|			ISNULL(RoomQuotaSalesBalanceAndTurnovers.CounterClosingBalance, 0) AS CounterClosingBalance,
	|			ISNULL(RoomQuotaSalesBalanceAndTurnovers.RoomsInQuotaClosingBalance, 0) AS RoomsInQuota,
	|			ISNULL(RoomQuotaSalesBalanceAndTurnovers.BedsInQuotaClosingBalance, 0) AS BedsInQuota,
	|			ISNULL(RoomQuotaSalesBalanceAndTurnovers.RoomsRemainsClosingBalance, 0) AS RoomsRemains,
	|			ISNULL(RoomQuotaSalesBalanceAndTurnovers.BedsRemainsClosingBalance, 0) AS BedsRemains
	|		FROM
	|			AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
	|					&qDateTimeFromForToday,
	|					&qDateTimeToForToday,
	|					DAY,
	|					RegisterRecordsAndPeriodBoundaries,
	|					&qThereIsToday
	|						AND (&qHotelIsEmpty
	|							OR Hotel IN HIERARCHY (&qHotelParent)
	|								AND NOT Hotel.DeletionMark)
	|						AND &qRoomQuotaIsSet
	|						AND RoomQuota = &qRoomQuota) AS RoomQuotaSalesBalanceAndTurnovers) AS RoomQuotaBalances
	|		ON RoomInventoryBalance.Hotel = RoomQuotaBalances.Hotel
	|			AND RoomInventoryBalance.RoomType = RoomQuotaBalances.RoomType
	|			AND (BEGINOFPERIOD(RoomInventoryBalance.Period, DAY) = BEGINOFPERIOD(RoomQuotaBalances.Period, DAY))
	|WHERE
	|	BEGINOFPERIOD(RoomInventoryBalance.Period, DAY) = &qCurrentDate
	|
	|GROUP BY
	|	BEGINOFPERIOD(RoomInventoryBalance.Period, DAY),
	|	RoomInventoryBalance.Hotel,
	|	RoomInventoryBalance.RoomType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BEGINOFPERIOD(RoomInventoryBalance.Period, DAY) AS Period,
	|	RoomInventoryBalance.Hotel AS Hotel,
	|	RoomInventoryBalance.RoomType AS RoomType,
	|	MAX(CASE
	|			WHEN &qRoomQuotaIsSet
	|					AND &qDoWriteOff
	|				THEN ISNULL(RoomQuotaBalances.RoomsInQuota, 0)
	|			WHEN &qRoomQuotaIsSet
	|					AND NOT &qDoWriteOff
	|				THEN ISNULL(RoomInventoryBalance.TotalRoomsClosingBalance, 0)
	|			ELSE ISNULL(RoomInventoryBalance.TotalRoomsClosingBalance, 0)
	|		END) AS TotalRooms,
	|	MAX(CASE
	|			WHEN &qRoomQuotaIsSet
	|					AND &qDoWriteOff
	|				THEN ISNULL(RoomQuotaBalances.BedsInQuota, 0)
	|			WHEN &qRoomQuotaIsSet
	|					AND NOT &qDoWriteOff
	|				THEN ISNULL(RoomInventoryBalance.TotalBedsClosingBalance, 0)
	|			ELSE ISNULL(RoomInventoryBalance.TotalBedsClosingBalance, 0)
	|		END) AS TotalBeds,
	|	MAX(CASE
	|			WHEN &qRoomQuotaIsSet
	|					AND &qDoWriteOff
	|				THEN ISNULL(RoomQuotaBalances.RoomsInQuota, 0)
	|			WHEN &qRoomQuotaIsSet
	|					AND NOT &qDoWriteOff
	|				THEN ISNULL(RoomInventoryBalance.TotalSpecialRoomsClosingBalance, 0)
	|			ELSE ISNULL(RoomInventoryBalance.TotalSpecialRoomsClosingBalance, 0)
	|		END) AS TotalSpecialRooms,
	|	MAX(CASE
	|			WHEN &qRoomQuotaIsSet
	|					AND &qDoWriteOff
	|				THEN ISNULL(RoomQuotaBalances.BedsInQuota, 0)
	|			WHEN &qRoomQuotaIsSet
	|					AND NOT &qDoWriteOff
	|				THEN ISNULL(RoomInventoryBalance.TotalSpecialBedsClosingBalance, 0)
	|			ELSE ISNULL(RoomInventoryBalance.TotalSpecialBedsClosingBalance, 0)
	|		END) AS TotalSpecialBeds,
	|	MIN(CASE
	|			WHEN &qRoomQuotaIsSet
	|					AND &qDoWriteOff
	|				THEN ISNULL(RoomQuotaBalances.RoomsRemains, 0)
	|			WHEN &qRoomQuotaIsSet
	|					AND NOT &qDoWriteOff
	|					AND ISNULL(RoomInventoryBalance.RoomsVacantClosingBalance, 0) < ISNULL(RoomQuotaBalances.RoomsRemains, 0)
	|				THEN ISNULL(RoomInventoryBalance.RoomsVacantClosingBalance, 0)
	|			WHEN &qRoomQuotaIsSet
	|					AND NOT &qDoWriteOff
	|					AND ISNULL(RoomInventoryBalance.RoomsVacantClosingBalance, 0) >= ISNULL(RoomQuotaBalances.RoomsRemains, 0)
	|				THEN ISNULL(RoomQuotaBalances.RoomsRemains, 0)
	|			ELSE ISNULL(RoomInventoryBalance.RoomsVacantClosingBalance, 0)
	|		END) AS RoomsVacant,
	|	MIN(CASE
	|			WHEN &qRoomQuotaIsSet
	|					AND &qDoWriteOff
	|				THEN ISNULL(RoomQuotaBalances.BedsRemains, 0)
	|			WHEN &qRoomQuotaIsSet
	|					AND NOT &qDoWriteOff
	|					AND ISNULL(RoomInventoryBalance.BedsVacantClosingBalance, 0) < ISNULL(RoomQuotaBalances.BedsRemains, 0)
	|				THEN ISNULL(RoomInventoryBalance.BedsVacantClosingBalance, 0)
	|			WHEN &qRoomQuotaIsSet
	|					AND NOT &qDoWriteOff
	|					AND ISNULL(RoomInventoryBalance.BedsVacantClosingBalance, 0) >= ISNULL(RoomQuotaBalances.BedsRemains, 0)
	|				THEN ISNULL(RoomQuotaBalances.BedsRemains, 0)
	|			ELSE ISNULL(RoomInventoryBalance.BedsVacantClosingBalance, 0)
	|		END) AS BedsVacant
	|INTO VacantRoomsInTheFuture
	|FROM
	|	(SELECT
	|		BEGINOFPERIOD(DATEADD(RoomInventoryBalanceAndTurnovers.Period, SECOND, &qShiftInSeconds), DAY) AS Period,
	|		RoomInventoryBalanceAndTurnovers.Hotel AS Hotel,
	|		RoomInventoryBalanceAndTurnovers.RoomType AS RoomType,
	|		MAX(ISNULL(RoomInventoryBalanceAndTurnovers.CounterClosingBalance, 0)) AS CounterClosingBalance,
	|		MAX(ISNULL(RoomInventoryBalanceAndTurnovers.TotalRoomsClosingBalance, 0)) AS TotalRoomsClosingBalance,
	|		MAX(ISNULL(RoomInventoryBalanceAndTurnovers.TotalBedsClosingBalance, 0)) AS TotalBedsClosingBalance,
	|		MAX(ISNULL(RoomInventoryBalanceAndTurnovers.TotalSpecialRoomsClosingBalance, 0)) AS TotalSpecialRoomsClosingBalance,
	|		MAX(ISNULL(RoomInventoryBalanceAndTurnovers.TotalSpecialBedsClosingBalance, 0)) AS TotalSpecialBedsClosingBalance,
	|		MIN(ISNULL(RoomInventoryBalanceAndTurnovers.RoomsVacantClosingBalance, 0)) AS RoomsVacantClosingBalance,
	|		MIN(ISNULL(RoomInventoryBalanceAndTurnovers.BedsVacantClosingBalance, 0)) AS BedsVacantClosingBalance
	|	FROM
	|		AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|				&qDateTimeFromInTheFuture,
	|				&qDateTimeToInTheFuture,
	|				MINUTE,
	|				RegisterRecordsAndPeriodBoundaries,
	|				&qThereIsFuture
	|					AND (&qHotelIsEmpty
	|						OR Hotel IN HIERARCHY (&qHotelParent)
	|							AND NOT Hotel.DeletionMark)) AS RoomInventoryBalanceAndTurnovers
	|	
	|	GROUP BY
	|		BEGINOFPERIOD(DATEADD(RoomInventoryBalanceAndTurnovers.Period, SECOND, &qShiftInSeconds), DAY),
	|		RoomInventoryBalanceAndTurnovers.Hotel,
	|		RoomInventoryBalanceAndTurnovers.RoomType) AS RoomInventoryBalance
	|		LEFT JOIN (SELECT
	|			BEGINOFPERIOD(RoomQuotaSalesBalanceAndTurnovers.Period, DAY) AS Period,
	|			RoomQuotaSalesBalanceAndTurnovers.Hotel AS Hotel,
	|			RoomQuotaSalesBalanceAndTurnovers.RoomType AS RoomType,
	|			ISNULL(RoomQuotaSalesBalanceAndTurnovers.CounterClosingBalance, 0) AS CounterClosingBalance,
	|			ISNULL(RoomQuotaSalesBalanceAndTurnovers.RoomsInQuotaClosingBalance, 0) AS RoomsInQuota,
	|			ISNULL(RoomQuotaSalesBalanceAndTurnovers.BedsInQuotaClosingBalance, 0) AS BedsInQuota,
	|			ISNULL(RoomQuotaSalesBalanceAndTurnovers.RoomsRemainsClosingBalance, 0) AS RoomsRemains,
	|			ISNULL(RoomQuotaSalesBalanceAndTurnovers.BedsRemainsClosingBalance, 0) AS BedsRemains
	|		FROM
	|			AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
	|					&qDateTimeFromInTheFuture,
	|					&qDateTimeToInTheFuture,
	|					DAY,
	|					RegisterRecordsAndPeriodBoundaries,
	|					&qThereIsFuture
	|						AND (&qHotelIsEmpty
	|							OR Hotel IN HIERARCHY (&qHotelParent)
	|								AND NOT Hotel.DeletionMark)
	|						AND &qRoomQuotaIsSet
	|						AND RoomQuota = &qRoomQuota) AS RoomQuotaSalesBalanceAndTurnovers) AS RoomQuotaBalances
	|		ON RoomInventoryBalance.Hotel = RoomQuotaBalances.Hotel
	|			AND RoomInventoryBalance.RoomType = RoomQuotaBalances.RoomType
	|			AND (BEGINOFPERIOD(RoomInventoryBalance.Period, DAY) = BEGINOFPERIOD(RoomQuotaBalances.Period, DAY))
	|WHERE
	|	BEGINOFPERIOD(RoomInventoryBalance.Period, DAY) > &qCurrentDate
	|
	|GROUP BY
	|	BEGINOFPERIOD(RoomInventoryBalance.Period, DAY),
	|	RoomInventoryBalance.Hotel,
	|	RoomInventoryBalance.RoomType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VacantRoomsDetailed.Period AS Period,
	|	VacantRoomsDetailed.Hotel AS Hotel,
	|	VacantRoomsDetailed.RoomType AS RoomType,
	|	VacantRoomsDetailed.TotalRooms AS TotalRooms,
	|	VacantRoomsDetailed.TotalBeds AS TotalBeds,
	|	VacantRoomsDetailed.TotalSpecialRooms AS TotalSpecialRooms,
	|	VacantRoomsDetailed.TotalSpecialBeds AS TotalSpecialBeds,
	|	VacantRoomsDetailed.RoomsVacant AS RoomsVacant,
	|	VacantRoomsDetailed.BedsVacant AS BedsVacant
	|INTO VacantRoomsDetailed
	|FROM
	|	(SELECT
	|		VacantRoomsInThePast.Period AS Period,
	|		VacantRoomsInThePast.Hotel AS Hotel,
	|		VacantRoomsInThePast.RoomType AS RoomType,
	|		VacantRoomsInThePast.TotalRooms AS TotalRooms,
	|		VacantRoomsInThePast.TotalBeds AS TotalBeds,
	|		VacantRoomsInThePast.TotalSpecialRooms AS TotalSpecialRooms,
	|		VacantRoomsInThePast.TotalSpecialBeds AS TotalSpecialBeds,
	|		VacantRoomsInThePast.RoomsVacant AS RoomsVacant,
	|		VacantRoomsInThePast.BedsVacant AS BedsVacant
	|	FROM
	|		VacantRoomsInThePast AS VacantRoomsInThePast
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		VacantRoomsForToday.Period,
	|		VacantRoomsForToday.Hotel,
	|		VacantRoomsForToday.RoomType,
	|		VacantRoomsForToday.TotalRooms,
	|		VacantRoomsForToday.TotalBeds,
	|		VacantRoomsForToday.TotalSpecialRooms,
	|		VacantRoomsForToday.TotalSpecialBeds,
	|		VacantRoomsForToday.RoomsVacant,
	|		VacantRoomsForToday.BedsVacant
	|	FROM
	|		VacantRoomsForToday AS VacantRoomsForToday
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		VacantRoomsInTheFuture.Period,
	|		VacantRoomsInTheFuture.Hotel,
	|		VacantRoomsInTheFuture.RoomType,
	|		VacantRoomsInTheFuture.TotalRooms,
	|		VacantRoomsInTheFuture.TotalBeds,
	|		VacantRoomsInTheFuture.TotalSpecialRooms,
	|		VacantRoomsInTheFuture.TotalSpecialBeds,
	|		VacantRoomsInTheFuture.RoomsVacant,
	|		VacantRoomsInTheFuture.BedsVacant
	|	FROM
	|		VacantRoomsInTheFuture AS VacantRoomsInTheFuture) AS VacantRoomsDetailed
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExpectedGuestGroupsTurnovers.Hotel AS Hotel,
	|	ExpectedGuestGroupsTurnovers.RoomType AS RoomType,
	|	ExpectedGuestGroupsTurnovers.Period AS Period,
	|	ExpectedGuestGroupsTurnovers.RoomsReservedTurnover AS PreliminaryRooms,
	|	ExpectedGuestGroupsTurnovers.BedsReservedTurnover AS PreliminaryBeds
	|INTO PreliminaryReservations
	|FROM
	|	AccumulationRegister.ExpectedGuestGroups.Turnovers(
	|			&qDateFrom,
	|			&qDateTo,
	|			Day,
	|			&qShowPreliminary
	|				AND CASE
	|					WHEN Hotel IN HIERARCHY (&qHotelParent)
	|							AND NOT Hotel.DeletionMark
	|						THEN TRUE
	|					WHEN &qHotelIsEmpty
	|						THEN TRUE
	|					ELSE FALSE
	|				END
	|				AND CASE
	|					WHEN RoomQuota = VALUE(Catalog.RoomQuotas.EmptyRef)
	|						THEN TRUE
	|					WHEN GuestGroup <> VALUE(Catalog.GuestGroups.EmptyRef)
	|						THEN TRUE
	|					WHEN NOT ISNULL(RoomQuota.DoWriteOff, FALSE)
	|						THEN TRUE
	|					ELSE FALSE
	|				END
	|				AND CASE
	|					WHEN NOT &qRoomQuotaIsSet
	|						THEN TRUE
	|					WHEN RoomQuota = &qRoomQuota
	|						THEN TRUE
	|					ELSE FALSE
	|				END) AS ExpectedGuestGroupsTurnovers
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Commitments.Hotel AS Hotel,
	|	Commitments.RoomType AS RoomType,
	|	Commitments.Period AS Period,
	|	SUM(Commitments.CommitmentRoomsGuaranteed) AS CommitmentRoomsGuaranteed,
	|	SUM(Commitments.CommitmentBedsGuaranteed) AS CommitmentBedsGuaranteed,
	|	SUM(Commitments.CommitmentRoomsVirtual) AS CommitmentRoomsVirtual,
	|	SUM(Commitments.CommitmentBedsVirtual) AS CommitmentBedsVirtual,
	|	SUM(Commitments.CounterBalance) AS CounterBalance
	|INTO CommitmentSales
	|FROM
	|	(SELECT
	|		CommitmentSales.Hotel AS Hotel,
	|		CommitmentSales.RoomQuota AS RoomQuota,
	|		CommitmentSales.RoomType AS RoomType,
	|		CommitmentSales.Period AS Period,
	|		CASE
	|			WHEN ISNULL(CommitmentSales.RoomQuota.DoWriteOff, FALSE)
	|				THEN CommitmentSales.RoomsRemainsClosingBalance
	|			ELSE 0
	|		END AS CommitmentRoomsGuaranteed,
	|		CASE
	|			WHEN ISNULL(CommitmentSales.RoomQuota.DoWriteOff, FALSE)
	|				THEN CommitmentSales.BedsRemainsClosingBalance
	|			ELSE 0
	|		END AS CommitmentBedsGuaranteed,
	|		CASE
	|			WHEN NOT ISNULL(CommitmentSales.RoomQuota.DoWriteOff, FALSE)
	|				THEN CommitmentSales.RoomsRemainsClosingBalance
	|			ELSE 0
	|		END AS CommitmentRoomsVirtual,
	|		CASE
	|			WHEN NOT ISNULL(CommitmentSales.RoomQuota.DoWriteOff, FALSE)
	|				THEN CommitmentSales.BedsRemainsClosingBalance
	|			ELSE 0
	|		END AS CommitmentBedsVirtual,
	|		CommitmentSales.CounterClosingBalance AS CounterBalance
	|	FROM
	|		AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
	|				&qDateFrom,
	|				&qDateTo,
	|				Day,
	|				RegisterRecordsAndPeriodBoundaries,
	|				&qShowCommitment
	|					AND (Hotel IN HIERARCHY (&qHotelParent)
	|							AND NOT Hotel.DeletionMark
	|						OR &qHotelIsEmpty)
	|					AND (&qRoomQuotaIsSet
	|							AND RoomQuota = &qRoomQuota
	|						OR NOT &qRoomQuotaIsSet)
	|					AND RoomQuota.IsCommitment) AS CommitmentSales) AS Commitments
	|
	|GROUP BY
	|	Commitments.Hotel,
	|	Commitments.RoomType,
	|	Commitments.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventory.Period AS Period,
	|	RoomInventory.Hotel AS Hotel,
	|	RoomInventory.Hotel.SortCode AS HotelSortCode,
	|	RoomInventory.RoomType AS RoomType,
	|	RoomInventory.RoomType.SortCode AS RoomTypeSortCode,
	|	RoomInventory.TotalRooms AS TotalRooms,
	|	RoomInventory.TotalBeds AS TotalBeds,
	|	RoomInventory.TotalSpecialRooms AS TotalSpecialRooms,
	|	RoomInventory.TotalSpecialBeds AS TotalSpecialBeds,
	|	RoomInventory.RoomsVacant AS RoomsVacant,
	|	CASE
	|		WHEN RoomInventory.RoomType.DoesNotAffectRoomRevenueStatistics
	|			THEN 0
	|		ELSE RoomInventory.RoomsVacant
	|	END AS SpecialRoomsVacant,
	|	RoomInventory.BedsVacant AS BedsVacant,
	|	CASE
	|		WHEN RoomInventory.RoomType.DoesNotAffectRoomRevenueStatistics
	|			THEN 0
	|		ELSE RoomInventory.BedsVacant
	|	END AS SpecialBedsVacant,
	|	CASE
	|		WHEN &qShowCommitment
	|			THEN ISNULL(CommitmentSales.CommitmentRoomsVirtual, 0)
	|		ELSE ISNULL(PreliminaryReservations.PreliminaryRooms, 0)
	|	END AS PreliminaryRooms,
	|	CASE
	|		WHEN &qShowCommitment
	|			THEN RoomInventory.BedsVacant + ISNULL(CommitmentSales.CommitmentBedsGuaranteed, 0) - ISNULL(CommitmentSales.CommitmentBedsVirtual, 0)
	|		ELSE ISNULL(PreliminaryReservations.PreliminaryBeds, 0)
	|	END AS PreliminaryBeds,
	|	CASE
	|		WHEN RoomInventory.RoomType.DoesNotAffectRoomRevenueStatistics
	|			THEN 0
	|		ELSE CASE
	|				WHEN &qShowCommitment
	|					THEN ISNULL(CommitmentSales.CommitmentRoomsVirtual, 0)
	|				ELSE ISNULL(PreliminaryReservations.PreliminaryRooms, 0)
	|			END
	|	END AS PreliminarySpecialRoomsVacant,
	|	CASE
	|		WHEN RoomInventory.RoomType.DoesNotAffectRoomRevenueStatistics
	|			THEN 0
	|		ELSE CASE
	|				WHEN &qShowCommitment
	|					THEN RoomInventory.BedsVacant + ISNULL(CommitmentSales.CommitmentBedsGuaranteed, 0) - ISNULL(CommitmentSales.CommitmentBedsVirtual, 0)
	|				ELSE ISNULL(PreliminaryReservations.PreliminaryBeds, 0)
	|			END
	|	END AS PreliminarySpecialBedsVacant,
	|	CASE
	|		WHEN RoomInventory.Hotel = &qHotel
	|			THEN 0
	|		ELSE 1
	|	END AS HotelWeight
	|FROM
	|	VacantRoomsDetailed AS RoomInventory
	|		LEFT JOIN PreliminaryReservations AS PreliminaryReservations
	|		ON RoomInventory.Period = PreliminaryReservations.Period
	|			AND RoomInventory.Hotel = PreliminaryReservations.Hotel
	|			AND RoomInventory.RoomType = PreliminaryReservations.RoomType
	|		LEFT JOIN CommitmentSales AS CommitmentSales
	|		ON RoomInventory.Period = CommitmentSales.Period
	|			AND RoomInventory.Hotel = CommitmentSales.Hotel
	|			AND RoomInventory.RoomType = CommitmentSales.RoomType
	|WHERE
	|	NOT RoomInventory.RoomType.DeletionMark" +
	?(ValueIsFilled(SessionParameters.CurrentUser.Customer)," AND RoomInventory.RoomsVacant <> 0 AND RoomInventory.BedsVacant <> 0 ", "") + "
	|ORDER BY
	|	HotelWeight,
	|	HotelSortCode,
	|	RoomTypeSortCode,
	|	Period
	|TOTALS
	|	SUM(TotalRooms),
	|	SUM(TotalBeds),
	|	SUM(TotalSpecialRooms),
	|	SUM(TotalSpecialBeds),
	|	SUM(RoomsVacant),
	|	SUM(BedsVacant),
	|	SUM(SpecialRoomsVacant),
	|	SUM(SpecialBedsVacant),
	|	SUM(PreliminaryRooms),
	|	SUM(PreliminaryBeds),
	|	SUM(PreliminarySpecialRoomsVacant),
	|	SUM(PreliminarySpecialBedsVacant)
	|BY
	|	Hotel HIERARCHY,
	|	RoomType HIERARCHY,
	|	Period";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelParent", ?(ValueIsFilled(Hotel), ?(ValueIsFilled(Hotel.Parent) And IsInRole("RightsToChooseHotel"), Hotel.Parent, Hotel), Hotel));
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qRoomQuota", RoomQuota);
	vQry.SetParameter("qRoomQuotaIsSet", ValueIsFilled(RoomQuota));
	vQry.SetParameter("qDoWriteOff", ?(ValueIsFilled(RoomQuota), RoomQuota.DoWriteOff, False));
	If vDateFrom < vCurrentDate Then
		vQry.SetParameter("qThereIsPast", True);
		vQry.SetParameter("qDateTimeFromInThePast", vDateTimeFrom);
		vQry.SetParameter("qDateTimeToInThePast", vCurrentDate + (vRH - BegOfDay(vRH)));
	Else
		vQry.SetParameter("qThereIsPast", False);
		vQry.SetParameter("qDateTimeFromInThePast", vDateTimeFrom);
		vQry.SetParameter("qDateTimeToInThePast", vDateTimeTo);
	EndIf;
	If vDateFrom <= vCurrentDate And vDateTo >= vCurrentDate Then
		vQry.SetParameter("qThereIsToday", True);
		vQry.SetParameter("qDateTimeFromForToday", cm1SecondShift(vDateTimeFromToday));
		vQry.SetParameter("qDateTimeToForToday", (BegOfDay(vDateTimeFromToday) + 24*3600 + (vRH - BegOfDay(vRH))));
	Else
		vQry.SetParameter("qThereIsToday", False);
		vQry.SetParameter("qDateTimeFromForToday", vDateTimeFrom);
		vQry.SetParameter("qDateTimeToForToday", vDateTimeTo);
	EndIf;
	If vDateTo > EndOfDay(vCurrentDate) Then
		vQry.SetParameter("qThereIsFuture", True);
		vQry.SetParameter("qDateTimeFromInTheFuture", cm1SecondShift(vCurrentDate + (vRH - BegOfDay(vRH))));
		vQry.SetParameter("qDateTimeToInTheFuture", (BegOfDay(vDateTimeTo) + 24*3600 + (vRH - BegOfDay(vRH))));
	Else
		vQry.SetParameter("qThereIsFuture", False);
		vQry.SetParameter("qDateTimeFromInTheFuture", vDateTimeFrom);
		vQry.SetParameter("qDateTimeToInTheFuture", vDateTimeTo);
	EndIf;
	vQry.SetParameter("qCurrentDate", vCurrentDate);
	vQry.SetParameter("qDateFrom", vDateFrom);
	vQry.SetParameter("qDateTo", EndOfDay(vDateTo));
	vQry.SetParameter("qShiftInSeconds", vShiftInSeconds);
	vQry.SetParameter("qShowPreliminary", ShowPreliminary);
	vQry.SetParameter("qShowCommitment", ShowCommitment);
	vQryRes = vQry.Execute();
	
	// Fill end of day balances and periods
	vPeriods = New ValueList();
	vQryHotels = vQryRes.Select(QueryResultIteration.ByGroups, "Hotel");
	While vQryHotels.Next() Do
		// Save all periods where vacant resource is changed
		vQryHours = vQryHotels.Select(QueryResultIteration.ByGroups, "Period", "ALL");
		While vQryHours.Next() Do
			vPeriod = BegOfDay(vQryHours.Period);
			If (vPeriod < BegOfDay(vDateTimeFrom)) Or (vPeriod > EndOfDay(vDateTimeTo)) Then
				Continue;
			EndIf;
			If vPeriods.FindByValue(vPeriod) = Undefined Then
				vPeriods.Add(vPeriod); 
			EndIf;
		EndDo;
		Break;
	EndDo;
	// Sort periods chronologically
	vPeriods.SortByValue();
	NumberOfPeriods = vPeriods.Count();
	
	// Draw header
	vSpreadsheet = Report;
	vSpreadsheet.Clear();
	vSpreadsheet.ShowGroups = True;
	
	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Landscape, False);
	vSpreadsheet.FixedTop = 5;
	vSpreadsheet.FixedLeft = 2;
	
	If ShowPrices Then 
		vTemplate 	= GetCommonTemplate("AvailableRoomsReportTemplateWithPrices");
		vDaysInPage = 7;
	ElsIf ShowPreliminary Or ShowCommitment Then 
		vTemplate = GetCommonTemplate("AvailableRoomsReportTemplateWithPreliminary");
		vDaysInPage = 21;
	Else
		vTemplate = GetCommonTemplate("AvailableRoomsReportTemplate");
		vDaysInPage = 21;
	EndIf;
	vArea = vTemplate.GetArea("Header|NamesColumn");
	If vShowReportsInBeds Then
		vArea.Parameters.mReportHeaderText = NStr("en='Vacant beds';ru='Свободные места';de='Freie Betten'");
	Else
		vArea.Parameters.mReportHeaderText = NStr("en='Vacant rooms';ru='Свободные номера';de='Freie Zimmer'");
	EndIf;
	
	vAllotmentText = ?(ValueIsFilled(RoomQuota), RoomQuota, NStr("en = 'Empty'; de = 'Leeren'; ru = 'Нет'"));
	vRoomRateText = ?(ValueIsFilled(RoomRate), RoomRate, NStr("en = 'Empty'; de = 'Leeren'; ru = 'Нет'"));
	vMealBoardText = ?(ValueIsFilled(MealBoardTerm), MealBoardTerm, NStr("en = 'Default'; de = 'Standard'; ru = 'По умолчанию'"));	
	vFilterText = NStr("en = 'Filter: '; de = 'Filter: '; ru = 'Отбор: '") + StrTemplate(NStr("en = 'Allotment: %1; Room rate: %2; Terms: %3'; de = 'Allotment: %1; Tarif: %2; Terms: %3'; ru = 'Квота: %1; Тариф: %2; Питание: %3'"), vAllotmentText, vRoomRateText, vMealBoardText);
	vFilterArea = vTemplate.GetArea("Filter|NamesColumn");
	vFilterArea.Parameters.Filter = vFilterText;
	If pPrintMode Then
		vSpreadsheet.Put(vFilterArea);
	EndIf;
	vSpreadsheet.Put(vArea);

	// Draw occupation percent
	vEndOfPrevDay = False;
	vDayGroup = False;
	vLastDate = Undefined;
	
	vOccupationPercentList = GetOccupationPercent(Hotel, vDateTimeFrom, vDateTimeTo);
	vInt = 0;
	For Each vPeriodItem In vPeriods Do
		vPeriod = vPeriodItem.Value;
		vCurDate = BegOfDay(vPeriod);
		If vLastDate = Undefined Or vCurDate <> vLastDate Then
			vLastDate = vCurDate;
			vEndOfPrevDay = True;
		EndIf;
		mDay = Day(vCurDate);
		mDayOfWeek = cmGetDayOfWeekName(WeekDay(vCurDate), True);
		mMonth = Format(vPeriod, "DF=MMMM");		
		
		If vEndOfPrevDay Then
			vEndOfPrevDay = False;
			If vCurDate = BegOfMonth(vCurDate) Or vCurDate = vDateFrom Then
				vArea = vTemplate.GetArea("Header|FirstDayOfMonth");
				vArea.Parameters.mMonth = mMonth;
			ElsIf WeekDay(vCurDate) = 1 Then
				vArea = vTemplate.GetArea("Header|FirstDayOfWeek");
			Else
				vArea = vTemplate.GetArea("Header|FirstHourOfDay");
			EndIf;
			vArea.Parameters.mDay = mDay;
			vArea.Parameters.mDayOfWeek = mDayOfWeek;
			
			vFilter = vOccupationPercentList.FindRows(New Structure("Period", vCurDate));
			If vFilter.Count()>0 Then
				
				vRow = vFilter[0];
				vTotalRooms		= ?(vShowReportsInBeds, vRow.TotalBeds, vRow.TotalRooms);
				vRoomsBlocked 	= ?(vShowReportsInBeds, vRow.BedsBlocked, vRow.RoomsBlocked);
				vRoomsRented 	= ?(ShowPreliminary, ?(vShowReportsInBeds, vRow.BedsRented, vRow.RoomsRented), ?(vShowReportsInBeds, vRow.DefiniteBedsRented, vRow.DefiniteRoomsRented));
				
				vArea.Parameters.mPercent = Format(Round(?((vTotalRooms-vRoomsBlocked) = 0, 0, 100 * vRoomsRented/(vTotalRooms - vRoomsBlocked)), 0), "NFD=0; NZ=; NG=") + "%";
			Else
				vArea.Parameters.mPercent = "0" + "%";
			EndIf;	
		Else
			vArea = vTemplate.GetArea("Header|Day");
		EndIf;
		
		If vInt = vDaysInPage Then
			vInt = 0;
		EndIf;
		
		vInt = vInt + 1;
		vSpreadsheet.Join(vArea);
	EndDo;
		
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
			If vLastDate = Undefined Or vCurDate <> vLastDate Then
				vLastDate = vCurDate;
				vEndOfPrevDay = True;
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
					vArea = vTemplate.GetArea(vAreaRowName + "|FirstDayOfMonth");
				ElsIf WeekDay(vCurDate) = 1 Then
					vArea = vTemplate.GetArea(vAreaRowName + "|FirstDayOfWeek");
				Else
					vArea = vTemplate.GetArea(vAreaRowName + "|FirstHourOfDay");
				EndIf;
			Else
				vArea = vTemplate.GetArea(vAreaRowName + "|Day");
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
	
	// Count maximum value for progress bar
	vNHotels = vQryRes.Select(QueryResultIteration.ByGroups, "Hotel").Count();
	vNRoomTypes = vQryRes.Select(QueryResultIteration.ByGroups, "RoomType").Count();
	vNHours = 1;
	vQryRoomTypes = vQryHotels.Select(QueryResultIteration.ByGroups, "RoomType");
	If vQryRoomTypes <> Undefined Then
		vNHours = vQryRoomTypes.Select(QueryResultIteration.ByGroups, "Period", "ALL").Count();
	EndIf;
	
	// Allowed hotels list
	vAllowedHotels = Catalogs.Hotels.GetHotelAllowedList();
	
	// Build report form
	vQryHotels = vQryRes.Select(QueryResultIteration.ByGroups, "Hotel");
	While vQryHotels.Next() Do
		// Check if hotel is allowed for the user
		If vAllowedHotels.Count() > 0 Then
			If vAllowedHotels.FindByValue(vQryHotels.Hotel) = Undefined Then
				Continue;
			EndIf;
		EndIf;
		
		// Show hotel
		vArea = vTemplate.GetArea("HotelRow|NamesColumn");
		vArea.Parameters.mHotel = TrimAll(vQryHotels.Hotel);
		vArea.Parameters.dHotel = vQryHotels.Hotel;
		vQryHours = vQryHotels.Select(QueryResultIteration.ByGroups, "Period", "ALL");
		While vQryHours.Next() Do
			vPeriod = BegOfDay(vQryHours.Period);
			If (vPeriod < BegOfDay(vDateTimeFrom)) Or (vPeriod > EndOfDay(vDateTimeTo)) Then
				Continue;
			EndIf;
			If vPeriods.FindByValue(vPeriod) = Undefined Then
				Continue;
			EndIf;
			vLastTotal = 0;
			vArea.Parameters.mHotel = vArea.Parameters.mHotel + " (" + Format(GetQueryResource(vQryHours, vShowReportsInBeds, vLastTotal, "Total"), "NFD=0; NZ=; NG=") + ")";
			Break;
		EndDo;
		vSpreadsheet.Put(vArea);
		
		// Show hotel totals by days and hours
		vEndOfPrevDay = False;
		vLastDate = Undefined;
		vLastVacant = 0;
		vCommentHour = 0;
		vQryHours = vQryHotels.Select(QueryResultIteration.ByGroups, "Period", "ALL");
		While vQryHours.Next() Do
			vPeriod = BegOfDay(vQryHours.Period);
			If (vPeriod < BegOfDay(vDateTimeFrom)) Or (vPeriod > EndOfDay(vDateTimeTo)) Then
				Continue;
			EndIf;
			If vPeriods.FindByValue(vPeriod) = Undefined Then
				Continue;
			EndIf;
			
			vCurDate = BegOfDay(vPeriod);
			If vLastDate = Undefined Or vCurDate <> vLastDate Then
				vLastDate = vCurDate;
				vEndOfPrevDay = True;
			EndIf;
			
			// Get necessary report template area
			If vEndOfPrevDay Then
				vEndOfPrevDay = False;
				If vCurDate = BegOfMonth(vCurDate) Or vCurDate = vDateFrom Then
					vArea = vTemplate.GetArea("HotelRow|FirstDayOfMonth");
				ElsIf WeekDay(vCurDate) = 1 Then
					vArea = vTemplate.GetArea("HotelRow|FirstDayOfWeek");
				Else
					vArea = vTemplate.GetArea("HotelRow|FirstHourOfDay");
				EndIf;
			Else
				vArea = vTemplate.GetArea("HotelRow|Day");
			EndIf;
			
			// Fill parameters and join area
			vVacant = GetQueryResource(vQryHours, vShowReportsInBeds, vLastVacant, "Special");
			vArea.Parameters.mVacant = Format(vVacant, "NFD=0; NG=" + ?(vShowZeroes, "; NZ=", ""));
			If ShowPreliminary Or ShowCommitment Then
				vPreliminary = GetQueryResource(vQryHours, vShowReportsInBeds, vLastVacant, "PreliminarySpecial");
				If ShowCommitment Then
					If vPreliminary <> 0 Then
						vArea.Parameters.mVacant = vArea.Parameters.mVacant + Chars.LF + Format(vPreliminary, "NFD=0; NG=" + ?(vShowZeroes, "; NZ=", ""));
					EndIf;
				Else
					If vPreliminary <> 0 Then
						vArea.Parameters.mVacant = vArea.Parameters.mVacant + Chars.LF + Format(vPreliminary, "NFD=0; NG=" + ?(vShowZeroes, "; NZ=", ""));
					EndIf;
				EndIf;
			EndIf;
				
			vArea.Parameters.mDetails = New Structure("Hotel, RoomType, PeriodTo", 
													   vQryHotels.Hotel, 
													   Catalogs.RoomTypes.EmptyRef(), 
													   vPeriod);
			
			If vVacant <= 0 Then
				vCell = vArea.Area(1, 1, 1, 1);
				vCell.TextColor = WebColors.Red;
			EndIf;
			vSpreadsheet.Join(vArea);
			
			vLastVacant = vArea.Parameters.mVacant;
		EndDo;
		
		// Show room types for this hotel
		If vQryHotels.Hotel = Hotel Then
			vBaseRTTotal = 0;
			vQryRoomTypes = vQryHotels.Select(QueryResultIteration.ByGroups, "RoomType");
			While vQryRoomTypes.Next() Do
				vQryRoomTypesRoomType = vQryRoomTypes.RoomType;
				// Show room type
				vAreaCol = "RoomTypeRow";
				If vQryRoomTypesRoomType.IsFolder Then
					vAreaCol = "RoomTypeFolderRow";
				EndIf;
				vArea = vTemplate.GetArea(vAreaCol + "|NamesColumn");
				If vAreaCol = "RoomTypeRow" Then
					If ShowPrices Then
						If vUsePricesCache And vCachedPricesTab.Count() > 0 Then
							vTablePrices = GetCachedPriceByPeriod(vDateFrom, vDateTo, vQryRoomTypesRoomType, vCachedPricesTab);
						Else
							vTablePrices = GetPriceByPeriod(vDateTimeFrom, vDateTimeTo + 24 * 60 * 60, vQryRoomTypesRoomType);
						EndIf;
					EndIf;
					If IsBlankString(vQryRoomTypesRoomType.DescriptionTranslations) Then
						vArea.CurrentArea.Comment.Text = TrimAll(vQryRoomTypesRoomType.Description);
					Else	
						vArea.CurrentArea.Comment.Text = cmNStr(vQryRoomTypesRoomType.DescriptionTranslations, SessionParameters.CurrentLanguage);
					EndIf;
					If Not IsBlankString(vQryRoomTypesRoomType.Remarks) Then
						vArea.CurrentArea.Comment.Text = vArea.CurrentArea.Comment.Text + Chars.LF + cmNStr(vQryRoomTypesRoomType.Remarks, SessionParameters.CurrentLanguage);
					EndIf;
				EndIf;
				If vQryRoomTypesRoomType.IsFolder Then
					vArea.Parameters.mRoomType = cmGetIndent(vQryRoomTypesRoomType, + 1) + TrimR(vQryRoomTypesRoomType.Description);
				Else
					vArea.Parameters.mRoomType = cmGetIndent(vQryRoomTypesRoomType, + 1) + TrimR(vQryRoomTypesRoomType.Description);
					If vAreaCol = "RoomTypeRow" Then
						vArea.Parameters.mDetails = New Structure("Hotel, RoomType, PeriodTo", 
															   vQryRoomTypes.Hotel, 
															   ?(vQryRoomTypesRoomType.IsFolder, Catalogs.RoomTypes.EmptyRef(), vQryRoomTypesRoomType), 
															   "");
															   
					EndIf;
				EndIf;
				vQryHours = vQryRoomTypes.Select(QueryResultIteration.ByGroups, "Period", "ALL");
				While vQryHours.Next() Do
					vPeriod = BegOfDay(vQryHours.Period);
					If (vPeriod < BegOfDay(vDateTimeFrom)) Or (vPeriod > EndOfDay(vDateTimeTo)) Then
						Continue;
					EndIf;
					If vPeriods.FindByValue(vPeriod) = Undefined Then
						Continue;
					EndIf;
					vLastTotal = 0;
					If Not vQryRoomTypesRoomType.IsFolder And vQryRoomTypesRoomType.DoesNotAffectRoomRevenueStatistics Then
						vArea.Parameters.mRoomType = vArea.Parameters.mRoomType + " (" + Format(GetQueryResource(vQryHours, vShowReportsInBeds, vLastTotal, "TotalSpecial"), "NFD=0; NZ=; NG=") + ")";
					Else
						vArea.Parameters.mRoomType = vArea.Parameters.mRoomType + " (" + Format(GetQueryResource(vQryHours, vShowReportsInBeds, vLastTotal, "Total"), "NFD=0; NZ=; NG=") + ")";
					EndIf;
					Break;
				EndDo;
				vSpreadsheet.Put(vArea);
				
				// Show room type totals by days
				vLastVacant = 0;
				vCommentHour = 0;
				vEndOfPrevDay = False;
				vLastDate = Undefined;
				vQryHours = vQryRoomTypes.Select(QueryResultIteration.ByGroups, "Period", "ALL");
				While vQryHours.Next() Do
					vPeriod = BegOfDay(vQryHours.Period);
					If (vPeriod < BegOfDay(vDateTimeFrom)) Or (vPeriod > EndOfDay(vDateTimeTo)) Then
						Continue;
					EndIf;
					If vPeriods.FindByValue(vPeriod) = Undefined Then
						Continue;
					EndIf;
					
					vCurDate = BegOfDay(vPeriod);
					If vLastDate = Undefined Or vCurDate <> vLastDate Then
						vLastDate = vCurDate;
						vEndOfPrevDay = True;
					EndIf;
					
					// Check room type stop sale
					vStopSaleRemarks = "";
					vAreaCol = "RoomTypeRow";
					If vQryRoomTypes.RoomType.IsFolder Then
						vAreaCol = "RoomTypeFolderRow";
					Else
						If vQryRoomTypes.RoomType.StopSale Then
							If cmIsStopSalePeriod(vQryRoomTypes.RoomType, vPeriod, vPeriod, vStopSaleRemarks, True) Then
								vAreaCol = "RoomTypeStopSaleRow";
							EndIf;
						EndIf;
					EndIf;
					
					// Get necessary report template area
					If vEndOfPrevDay Then
						vEndOfPrevDay = False;
						If vCurDate = BegOfMonth(vCurDate) Or vCurDate = vDateFrom Then
							vArea = vTemplate.GetArea(vAreaCol + "|FirstDayOfMonth");
						ElsIf WeekDay(vCurDate) = 1 Then
							vArea = vTemplate.GetArea(vAreaCol + "|FirstDayOfWeek");
						Else
							vArea = vTemplate.GetArea(vAreaCol + "|FirstHourOfDay");
						EndIf;
						// Reset comment on first period of a day
						vCommentHour = 0;
					Else
						vArea = vTemplate.GetArea(vAreaCol + "|Day");
					EndIf;
					
					// Set area parameters
					If vAreaCol = "RoomTypeFolderRow" Then
						vVacant = GetQueryResource(vQryHours, vShowReportsInBeds, vLastVacant, "Special");
					Else
						vVacant = GetQueryResource(vQryHours, vShowReportsInBeds, vLastVacant);
					EndIf;
					vArea.Parameters.mVacant = Format(vVacant, "NFD=0; NG=" + ?(vShowZeroes, "; NZ=", ""));
					If ShowPreliminary Or ShowCommitment Then
						If vAreaCol = "RoomTypeFolderRow" Then
							vPreliminary = GetQueryResource(vQryHours, vShowReportsInBeds, vLastVacant, "PreliminarySpecial");
						Else
							vPreliminary = GetQueryResource(vQryHours, vShowReportsInBeds, vLastVacant, "Preliminary");
						EndIf;
						If ShowCommitment Then
							If vPreliminary <> 0 Then
								vArea.Parameters.mVacant = vArea.Parameters.mVacant + Chars.LF + Format(vPreliminary, "NFD=0; NG=");
							EndIf;
						Else
							If vPreliminary <> 0 Then
								vArea.Parameters.mVacant = vArea.Parameters.mVacant + Chars.LF + Format(vPreliminary, "NFD=0; NG=");
							EndIf;
						EndIf;
					EndIf;
					
					If Not vAreaCol="RoomTypeFolderRow" And ShowPrices Then
						Try
							If vTablePrices.Columns.Count() > 0 Then
								vFilter = vTablePrices.FindRows(New Structure("Period", vCurDate));
								If vFilter.Count()>0 Then
									vArea.Parameters.mPrice	= cmFormatSum(vFilter[0].Sum,Hotel.ReportingCurrency);
								Else	
									vArea.Parameters.mPrice = cmFormatSum(0,Hotel.ReportingCurrency);
								EndIf;
							EndIf;
						Except
						EndTry;
					EndIf;		
					
					vArea.Parameters.mDetails = New Structure("Hotel, RoomType, PeriodTo", 
															   vQryHotels.Hotel, 
															   vQryRoomTypes.RoomType, 
															   vPeriod);

					// Set red color to the overbooking										   
					If vVacant <= 0 Then
						vCell = vArea.Area(1, 1, 1, 1);
						vCell.TextColor = WebColors.Red;
					EndIf;
					
					// Add stop sale comment
					If Not IsBlankString(vStopSaleRemarks) Then
						vArea.Area("T").Comment.Text = TrimAll(vArea.Area("T").Comment.Text) + ?(IsBlankString(vArea.Area("T").Comment.Text), "", Chars.LF + Chars.LF) + vStopSaleRemarks;
					EndIf;
					
					// Join template area to the report
					vSpreadsheet.Join(vArea);
					
					vLastVacant = vVacant;
				EndDo;
			EndDo;
		EndIf;
	EndDo;
	
	vSpreadsheet.RepeatOnColumnPrint = vSpreadsheet.Area("C1:C2");
	vSpreadsheet.RepeatOnRowPrint = vSpreadsheet.Area("R1:R5");

	// Set report protection
	cmSetSpreadsheetProtection(vSpreadsheet);
	
	// Set report header
	cmApplyReportHeader(vSpreadsheet);
	// Add configuration name to the right report header
	vSpreadsheet.Header.LeftText = ?(ValueIsFilled(SessionParameters.CurrentHotel), 
									 Catalogs.Hotels.pmGetHotelPrintName(SessionParameters.CurrentHotel, SessionParameters.CurrentLanguage), "") + " - " + 
									TrimAll(SessionParameters.ConfigurationPresentation);
	vSpreadsheet.Header.RightText = TrimAll(SessionParameters.CurrentUser) + " - " + Format(CurrentSessionDate(), "DF='dd.MM.yyyy HH:mm'");
	// Set footer
	cmApplyReportFooter(vSpreadsheet);
EndProcedure // BuildReport

// -----------------------------------------------------------------------------
&AtClient
Procedure RefreshFormData() Export
	If IsInputAvailable() Then
		BuildReport();
		CurTime = 0;
		AttachIdleHandler("FillAvailabilityBreakdown", 0.3, True);
	Else
		AttachIdleHandler("RefreshFormData", 1, True);
	EndIf;
EndProcedure // RefreshFormData

// -----------------------------------------------------------------------------
&AtServer
Function GetBedsSetupFunctionalOption()
	vUseBedsSetups = False;
	vHotel = Hotel;
	If Not ValueIsFilled(vHotel) Then
		vHotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(vHotel) Then
		vUseBedsSetups = GetFunctionalOption("BedsSetups", New Structure("Hotel", vHotel));
	EndIf;
	Return vUseBedsSetups;
EndFunction // GetBedsSetupFunctionalOption

#EndRegion

