
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing) 
	RegisterButtonAvailability = True;
	CurrentCard = Undefined;
	TotalGuestsProcessed = 0;
	TotalGuestsProcessedStr = "";
	ExtraGuestsProcessed = 0;
	ExtraGuestsProcessedStr = "";
	RoomRateGuestsProcessed = 0;
	RoomRateGuestsProcessedStr = "";
	IdleHandlerWasReset = False;
	// If quantity is zero then set it to 1
	If SelQuantity = 0 Then
		SelQuantity = 1;
	EndIf;
	// Check parameters
	If Parameters.Property("SelHotel") And ValueIsFilled(SelHotel) Then
		SelHotel = Parameters.SelHotel;
	EndIf;
	If Not ValueIsFilled(SelHotel) Then
		SelHotel = SessionParameters.CurrentHotel;
	EndIf;
	SelPeriod = CurrentSessionDate();
	If Parameters.Property("SelPeriod") And ValueIsFilled(Parameters.SelPeriod) Then
		SelPeriod = Parameters.SelPeriod;
	EndIf;
	If Parameters.Property("SelBoardPlace") Then
		SelBoardPlace = Parameters.SelBoardPlace;
	EndIf;
	If Parameters.Property("SelService") Then
		SelService = Parameters.SelService;
	EndIf;
	If Parameters.Property("SelServiceGroup") Then
		SelServiceGroup = Parameters.SelServiceGroup;
	EndIf;
	If Parameters.Property("SelRoom") Then
		SelRoom = Parameters.SelRoom;
	EndIf;
	If Parameters.Property("SelResource") Then
		SelResource = Parameters.SelResource;
	EndIf;
	// Check should we show guests list
	ShowGuestList = False;
	If ValueIsFilled(SessionParameters.CurrentWorkstation) And ValueIsFilled(SessionParameters.CurrentWorkstation.IdentityCardsProcessingSystemParameters) And SessionParameters.CurrentWorkstation.HasConnectionToIdentityCardsProcessingSystem Then
		If SessionParameters.CurrentWorkstation.IdentityCardsProcessingSystemParameters.ShowAllClientsInTheRoom Then
			ShowGuestList = True;
		EndIf;
	Else
		ShowGuestList = True;
		Items.SelCard.Visible = False;
		Items.GroupSelQuantity.Visible = False;
		Items.ButtonRoomRateTotalsHeader.Enabled = False;
		Items.ButtonExtraTotalsHeader.Enabled = False;
	EndIf;
	Items.PanelMode.CurrentPage = Items.PageProgress;
	If Not tcOnServer.cmIsInRole("Administrator") Then
		Items.GroupParameters.Visible = False;
	EndIf; 
	Items.ButtonRegister.Enabled = RegisterButtonAvailability;
	
	vClientDisplaysInformation = GetClientDisplaysInformation();
	If vClientDisplaysInformation.Count() > 0 And vClientDisplaysInformation[0].Width > 1024 Then
		Items.RegisteredServices.Visible = True;
		Items.ButtonListService.Visible = False;
	Else
		Items.RegisteredServices.Visible = False;
		Items.ButtonListService.Visible = True;
	EndIf;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	// Check service registration schedule
	CheckServiceRegistrationSchedule();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "Subsystem.Accounts.Changed" Then
		// Fill clients list based on curent form settings
		vResult = FillClientsList(True);
	ElsIf pEventName = "Document.Charge.Write" Then
		vResult = FillClientsList();	
	EndIf;
EndProcedure // NotificationProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure ExternalEvent(pSource, pEvent, pData)
	If Not IsInputAvailable() Then
		Return;
	EndIf;
	
	vEventData = tcConnectionHardwareAtClient.cmGetExternalEventResultInputDevice(pSource, pEvent, pData);
	If IsBlankString(vEventData.DeviceData) Then
		Return;
	EndIf;
	
	// Reset form
	ClearForm();
	
	If vEventData.DeviceType = "MagneticStripeCardReader" Then
		SelCard = vEventData.DeviceData;
		
		// Password mode
		Items.SelCard.PasswordMode = True;
		// Call procedure
		CardOnChange();
	ElsIf vEventData.DeviceType = "BarCodeScaner" Then
		// Parse scan data
		vCouponData = CallcmParseCouponBarCode(vEventData.DeviceData);
		// Fill form parameters
		If ValueIsFilled(vCouponData.AccountingDate) Then
			SelPeriod = vCouponData.AccountingDate;
		EndIf;
		If ValueIsFilled(vCouponData.Service) Then
			SelService = vCouponData.Service;
		EndIf;
		If ValueIsFilled(vCouponData.Quantity) Then
			SelQuantity = vCouponData.Quantity;
		EndIf;
		If ValueIsFilled(vCouponData.GuestGroup) Then
			SelGuestGroup = vCouponData.GuestGroup;
		EndIf;
		If ValueIsFilled(vCouponData.Client) Then
			SelClient = vCouponData.Client;
			SelClientType = tcOnServer.cmGetAttributeByRef(SelClient,"ClientType");
		EndIf;
		If ValueIsFilled(vCouponData.Room) Then
			SelRoom = vCouponData.Room;
		EndIf;
		If ValueIsFilled(vCouponData.Resource) Then
			SelResource = vCouponData.Resource;
		EndIf;
		vSelFolio = SelFolio;
		If ValueIsFilled(vCouponData.Folio) Then
			vSelFolio = vCouponData.Folio;
		EndIf;
		ExternalEventQuery(vSelFolio);
		// Set form appearance
		SetFormAppearance();
		// Reset current card
		CurrentCard = Undefined;
		// Register service
		If TableBoxClients.Count() > 0 Then
			ThisForm.CurrentItem = Items.TableBoxClients;
			vCurRow = TableBoxClients.Get(0);
			vCurRowStru = New Structure("Client, 
			|AvailableQuantity, 
			|AvailableSum, 
			|GuestGroup, 
			|Folio, 
			|FolioCurrency, 
			|Room, 
			|Resource, 
			|Service",
			vCurRow.Client,
			vCurRow.AvailableQuantity,
			vCurRow.AvailableSum,
			vCurRow.GuestGroup,
			vCurRow.Folio,
			vCurRow.FolioCurrency,
			vCurRow.Room,
			vCurRow.Resource,
			vCurRow.Service);
			
			Items.TableBoxClients.CurrentRow = vCurRow;
			Items.SelCard.BackColor = Items.SelService.BackColor;
			Items.SelClient.BackColor = Items.SelService.BackColor;
			Items.SelRoom.BackColor = Items.SelService.BackColor;
			Items.SelResource.BackColor = Items.SelService.BackColor;
			DoServiceRegistration(vCurRowStru);
		Else
			ThisForm.CurrentItem = Items.SelRoom;
			Items.SelClient.BackColor = WebColors.Red;
			Items.SelRoom.BackColor = WebColors.Red;
			Items.SelResource.BackColor = WebColors.Red;
			Items.SelCard.BackColor = WebColors.Red;
			TMessage = NStr("en='Coupon is already used!';ru='Талон уже был использован!';de='Der Coupon ist schon verbraucht!'");
			// Write safety event
			CallcmWriteSafetyEvent("ServiceRegistration","CouponRegistration");
		EndIf;
		// Visibility
		If Not ShowGuestList Then
			If Items.PanelMode.CurrentPage <> Items.PageProgress Then
				Items.PanelMode.CurrentPage = Items.PageProgress;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ExternalEvent


#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SelPeriodOnChange(pItem)
	// Reset form
	ClearForm();
	// Restore totals
	RestoreTotals();
	// Fill clients list based on curent form settings
	vResult = FillClientsList();
EndProcedure // SelPeriodOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelServiceOnChange(pItem)
	// Reset form
	ClearForm();
	// Restore totals
	RestoreTotals();
	// Fill clients list based on curent form settings
	vResult = FillClientsList();
EndProcedure // SelServiceOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelServiceStartChoice(pItem, pChoiceData, pStandardProcessing)
	If ValueIsFilled(SelServiceGroup) Then
		vServicesList = GetServiceGroupServices(SelServiceGroup); 
		If vServicesList.Count() > 0 Then
			pStandardProcessing = False;
			ThisForm.ShowChooseFromList(New NotifyDescription("ChooseServiceFromServiceGroupCompleted", ThisForm), vServicesList, pItem, vServicesList.FindByValue(SelService));
		EndIf;
	EndIf;	
EndProcedure // SelServiceStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure SelServiceGroupOnChange(pItem)
	// Reset form
	ClearForm();
	// Restore totals
	RestoreTotals();
	// Fill clients list based on curent form settings
	vResult = FillClientsList();
EndProcedure // SelServiceGroupOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelExtraServiceStartChoice(pItem, pChoiceData, pStandardProcessing)
	If ValueIsFilled(SelExtraServiceGroup) Then
		vServicesList = GetServiceGroupServices(SelExtraServiceGroup); 
		If vServicesList.Count() > 0 Then
			pStandardProcessing = False;
			ThisForm.ShowChooseFromList(New NotifyDescription("ChooseExtraServiceFromServiceGroupCompleted", ThisForm), vServicesList, pItem, vServicesList.FindByValue(SelExtraService));
		EndIf;
	EndIf;	
EndProcedure // SelExtraServiceStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure SelExtraServiceGroupOnChange(pItem)
	// Reset form
	ClearForm();
	// Restore totals
	RestoreTotals();
	// Fill clients list based on curent form settings
	vResult = FillClientsList();
EndProcedure // SelExtraServiceGroupOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomOnChange(pItem)
	SelRoomOnChangeAtServer();
EndProcedure // SelRoomOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelResourceOnChange(pItem)
	SelResourceOnChangeAtServer();
EndProcedure // SelResourceOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelClientOnChange(pItem)
	SelClientOnChangeAtServer();
EndProcedure // SelClientOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelClientStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure // SelClientStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure SelCardOnChange(pItem)
	// Reset current card
	CurrentCard = Undefined;
	vServiceWasRegistered = CardOnChange();
	If vServiceWasRegistered Then
		// Sent accounts subsystem change notification
		Notify("Subsystem.Accounts.Changed", Undefined, ThisForm);
	EndIf;
	// Set schedule
	If IdleHandlerWasReset Then
		SetServiceRegistrationSchedule();
	EndIf;
EndProcedure // SelCardOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelCardStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.IdentificationCards.ChoiceForm",,pItem, tcOnServer.cmGetSessionParametersAttribute("CurrentUser"));
EndProcedure // SelCardStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure SelCardChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	pStandardProcessing = False;
	If ValueIsFilled(pSelectedValue) Then
		SelCard = TrimAll(pSelectedValue.Identifier);
		SelCardOnChange(pItem);
	EndIf;
EndProcedure // SelCardChoiceProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure TableBoxClientsSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	// Register service
	DoServiceRegistration(pSelectedRow);
	RegisterButtonAvailability = False;
	// Set schedule
	SetServiceRegistrationSchedule();
	// Hide clients list
	If Not ShowGuestList Then
		If Items.PanelMode.CurrentPage <> Items.PageProgress Then
			Items.PanelMode.CurrentPage = Items.PageProgress;
		EndIf;
	ElsIf Items.TableBoxClients.CurrentData <> Undefined Then
		vCurData = Items.TableBoxClients.CurrentData;
		If vCurData <> Undefined Then
			If vCurData.AvailableQuantity <= 0 And Items.TableBoxClients.CurrentRow <> Undefined Then
				vNextRow = TableBoxClients.FindByID(Items.TableBoxClients.CurrentRow + 1);
				If vNextRow <> Undefined Then
					Items.TableBoxClients.CurrentRow = vNextRow.GetID();
				Else
					ThisObject.CurrentItem = Items.ClearForm;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // TableBoxClientsSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure TableBoxClientsOnActivateRow(pItem)
	CurClient = PredefinedValue("Catalog.Clients.EmptyRef");
	CurGuestGroup = PredefinedValue("Catalog.GuestGroups.EmptyRef");
	CurFolio = PredefinedValue("Document.Folio.EmptyRef");
	CurFolioCurrency = PredefinedValue("Catalog.Currencies.EmptyRef");
	CurRoom = PredefinedValue("Catalog.Rooms.EmptyRef");
	CurResource = PredefinedValue("Catalog.Resources.EmptyRef");
	AvailableQuantity = 0;
	AvailableSum = 0;
	// Set current client
	vCurRow = Items.TableBoxClients.RowData(Items.TableBoxClients.CurrentRow);
	If vCurRow <> Undefined Then
		CurClient = vCurRow.Client;
		CurGuestGroup = vCurRow.GuestGroup;
		CurFolio = vCurRow.Folio;
		CurFolioCurrency = vCurRow.FolioCurrency;
		CurRoom = vCurRow.Room;
		CurResource = vCurRow.Resource;
		AvailableQuantity = vCurRow.AvailableQuantity;
		AvailableSum = vCurRow.AvailableSum;
		If SelQuantity > AvailableQuantity Then
			SelQuantity = 1;
		EndIf;
	EndIf;
EndProcedure // TableBoxClientsOnActivateRow

// -----------------------------------------------------------------------------
&AtClient
Procedure SelBoadPlaceOnChange(pItem)
	// Reset form
	ClearForm();
	// Restore totals
	RestoreTotals();
	// Fill clients list based on curent form settings
	vResult = FillClientsList();
EndProcedure // SelBoadPlaceOnChange

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure AddQuantity(pCommand)
	AddQuantityAtServer();
EndProcedure // AddQuantity

// -----------------------------------------------------------------------------
&AtClient
Procedure ReduceQuantity(pCommand)
	ReduceQuantityAtServer();
EndProcedure // ReduceQuantity

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearQuantity(pCommand)
	ClearQuantityAtServer();
EndProcedure // ClearQuantity

// -----------------------------------------------------------------------------
&AtClient
Procedure ButtonRoomRateTotalsHeader(pCommand)
	If ValueIsFilled(SelService) Then
		// Register special service
		DoSpecialServiceRegistration(SelService);
	Else
		ShowMessageBox(,NStr("ru='Не указана услуга!'; en='Service is not specified!'; de='Dienstleistung nicht angegeben!'"));
	EndIf;
EndProcedure // ButtonRoomRateTotalsHeader

// -----------------------------------------------------------------------------
&AtClient
Procedure ButtonExtraTotalsHeader(pCommand)
	If ValueIsFilled(SelExtraService) Then
		// Register special service
		DoSpecialServiceRegistration(SelExtraService);
	Else
		ShowMessageBox(,NStr("ru='Не указана розничная услуга!'; en='Extra service is not specified!'; de='Extradienstleistung nicht angegeben!'"));
	EndIf;
EndProcedure // ButtonExtraTotalsHeader

// -----------------------------------------------------------------------------
&AtClient
Procedure ButtonRegister(pCommand)
	ButtonRegisterAtServer();
EndProcedure // ButtonRegister

// -----------------------------------------------------------------------------
&AtClient
Procedure ButtonChargeAndPay(pCommand)
	// APDEX
	vKeyOperation = "CommonForm.tcFoliosForm.OpenForm";
	vUUID = New UUID;
	APDEXPerformanceSystemOnClientServer.StartManualTimeIntervalMeasurement(vKeyOperation, vUUID);
	
	If ValueIsFilled(SelClient) Or ValueIsFilled(SelRoom) Then
		vDocument = QueryDocument();	
		If vDocument <> Undefined Then  
			vParametersStructure = New Structure("ObjectRef", vDocument);
			OpenForm("CommonForm.tcFoliosForm", New Structure("ParametersStructure", vParametersStructure), ThisForm, ThisForm.UUID);
			// APDEX
			APDEXPerformanceSystemOnClient.FinishManualTimeIntervalMeasurementNotGlobal(vUUID);
		ElsIf ValueIsFilled(SelClient) Then
			vParametersStructure = New Structure("ObjectRef", SelClient);
			OpenForm("CommonForm.tcFoliosForm", New Structure("ParametersStructure", vParametersStructure), ThisForm, ThisForm.UUID);
			// APDEX
			APDEXPerformanceSystemOnClient.FinishManualTimeIntervalMeasurementNotGlobal(vUUID);
		Else
			TMessage = NStr("en='Client was not found!'; ru='Клиент не найден!'; de='Client wurde nicht gefunden!'")
		EndIf;
	Else
		ShowMessageBox(, NStr("en='Please choose client or room!'; ru='Не выбраны ни клиент ни номер!'; de='Weder Kunde, noch Zimmer sind gewählt!'"));
	EndIf;
EndProcedure // ButtonChargeAndPay

// -----------------------------------------------------------------------------
&AtClient
Procedure AllClearForm(pCommand)
	RegisterButtonAvailability = True;
	ClearForm();
	vResult = FillClientsList();
EndProcedure // AllClearForm

// -----------------------------------------------------------------------------
&AtClient
Procedure ButtonListService(pCommand)
	If ValueIsFilled(SelClient) Then 
		FormParameters = New Structure("Filter",New Structure("Client,AccountingDate",SelClient,SelPeriod));				
	ElsIf ValueIsFilled(SelRoom) Then
		FormParameters = New Structure("Filter",New Structure("Room,AccountingDate",SelRoom,SelPeriod));
	Else
		FormParameters = New Structure("Filter",New Structure("AccountingDate",SelPeriod));
	EndIf;
	OpenForm("Document.ServiceRegistration.Form.tcListForm",FormParameters,ThisForm,ThisForm.UUID);
EndProcedure //  ButtonListService

// -----------------------------------------------------------------------------
&AtClient
Procedure CancelServiceRegistration(pCommand)
	vCurrentData = Items.RegisteredServices.CurrentData;
	If vCurrentData = Undefined Then
		Return;
	EndIf;
	For Each vRow In Items.RegisteredServices.SelectedRows Do
		CancelServiceRegistrationAtServer(Items.RegisteredServices.RowData(vRow).Ref);
	EndDo;
	Items.RegisteredServices.Refresh();
EndProcedure // CancelServiceRegistration

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckServiceRegistrationSchedule()
	If (Not ValueIsFilled(SelClient) And Not ValueIsFilled(SelRoom) And Not ValueIsFilled(SelResource)) Or TimeCounterForCleansing = 2 Then
		TimeCounterForCleansing = 0;
		SetServiceRegistrationSchedule();
		// Reset form
		ClearForm();
		// Restore totals
		RestoreTotals();
		// Fill clients list based on curent form settings
		vResult = FillClientsList();
		// Check driver state
		If amReaderMC <> Undefined And amReaderMC.DeviceEnabled = 0 Then
			// Fill error text
			Items.TMessage.BackColor = WebColors.DarkBlue;
			Items.TMessage.TextColor = WebColors.White;
			TMessage = NStr("en='Reader is disconnected! Please restart program...'; ru='Считыватель карт отключен! Пожалуйста перезапустите программу...'; de='Der Kartenleser ist deaktiviert! Bitte restarten Sie das Programm ...'");
		EndIf;
	Else
		TimeCounterForCleansing = TimeCounterForCleansing + 1;
	EndIf;
EndProcedure // CheckServiceRegistrationSchedule

// -----------------------------------------------------------------------------
&AtClient
Procedure SetServiceRegistrationSchedule()
	vCheckIdleHandler = CheckStartIdleHandler();
	If vCheckIdleHandler <> Undefined Then
		If vCheckIdleHandler Then
			AttachIdleHandler("CheckServiceRegistrationSchedule", 60);
		ElsIf Not CheckStartIdleHandler() And vCheckIdleHandler <> Undefined Then
			DetachIdleHandler("CheckServiceRegistrationSchedule");
		EndIf;
	EndIf;
EndProcedure // SetServiceRegistrationSchedule

// -----------------------------------------------------------------------------
&AtServer
Function CheckStartIdleHandler()
	vWstn = SessionParameters.CurrentWorkstation; 
	If ValueIsFilled(vWstn) Then
		// Default board place
		If ValueIsFilled(vWstn.BoardPlace) Then
			SelBoardPlace = vWstn.BoardPlace;
		EndIf;
		// Default kiosk folio
		If ValueIsFilled(vWstn.KioskFolio) Then
			SelFolio = vWstn.KioskFolio;
		EndIf;
		ThisObject.Title = NStr("en='Services control: '; ru='Контроль услуг: '; de='Dienstleistungenkontrol: '");
		vServiceRegistrationScheduleInfo = StrTemplate(NStr("en = 'There are no services to charge for %1'; de = 'Für %1 sind keine kostenpflichtigen Dienste vorhanden.'; ru = 'На %1 нет услуг для начисления'"), Format(CurrentSessionDate(), "DF='dd.MM.yyyy HH:mm'"));
		// Check schedule
		If vWstn.ServiceRegistrationSchedule.Count() > 0 Then
			vCurTime = '00010101' + (CurrentSessionDate() - BegOfDay(CurrentSessionDate()));
			For Each vScheduleRow In vWstn.ServiceRegistrationSchedule Do
				If vScheduleRow.TimeFrom <= vCurTime And vScheduleRow.TimeTo > vCurTime Then
					vCurDate = CurrentSessionDate();
					vServiceRegistrationScheduleInfo = "";
					If ValueIsFilled(vScheduleRow.ServiceGroup) Then
						SelServiceGroup = vScheduleRow.ServiceGroup;
						vServiceRegistrationScheduleInfo = vServiceRegistrationScheduleInfo + StrTemplate(NStr("en = 'Service group: %1; '; de = 'Dienstleistung Set: %1; '; ru = 'Наборы услуг: %1; '"), TrimAll(vScheduleRow.ServiceGroup));
					EndIf;
					If ValueIsFilled(vScheduleRow.Service) Then
						SelService = vScheduleRow.Service;
						vServiceRegistrationScheduleInfo = vServiceRegistrationScheduleInfo + StrTemplate(NStr("en = 'Service: %1; '; de = 'Dienstleistung: %1; '; ru = 'Услуга: %1; '"), TrimAll(vScheduleRow.Service));
					EndIf;
					If ValueIsFilled(vScheduleRow.ExtraServiceGroup) Then
						SelExtraServiceGroup = vScheduleRow.ExtraServiceGroup;
						vServiceRegistrationScheduleInfo = vServiceRegistrationScheduleInfo + StrTemplate(NStr("en = 'Extra service group: %1; '; de = 'Extradienstleistung Gruppe: %1; '; ru = 'Набор услуг в розницу: %1; '"), TrimAll(vScheduleRow.ExtraServiceGroup));
					EndIf;
					If ValueIsFilled(vScheduleRow.ExtraService) Then
						SelExtraService = vScheduleRow.ExtraService;
						vServiceRegistrationScheduleInfo = vServiceRegistrationScheduleInfo + StrTemplate(NStr("en = 'Extra service: %1; '; de = 'Extradienstleistung: %1; '; ru = 'Услуга в розницу: %1; '"), TrimAll(vScheduleRow.ExtraService));
					EndIf;
					vServiceRegistrationScheduleInfo = vServiceRegistrationScheduleInfo + StrTemplate(NStr("en = 'from %1 to %2'; de = 'von %1 bis %2'; ru = 'с %1 до %2'"), Format(Date(Year(vCurDate), Month(vCurDate), Day(vCurDate), Hour(vScheduleRow.TimeFrom), Minute(vScheduleRow.TimeFrom), 0), "DF='dd.MM.yyyy HH:mm'; DE="), Format(Date(Year(vCurDate), Month(vCurDate), Day(vCurDate), Hour(vScheduleRow.TimeTo), Minute(vScheduleRow.TimeTo), 0), "DF='dd.MM.yyyy HH:mm'; DE="));
					Break;
				EndIf;
			EndDo;
			ThisObject.Title = ThisObject.Title + vServiceRegistrationScheduleInfo;
			If Not cmCheckUserPermissions("HavePermissionToEditPostedFolioTransactions") Then
				Items.SelService.Enabled = False;
				Items.SelServiceGroup.Enabled = False;
				Items.SelExtraServiceGroup.Enabled = False;
			Else
				Items.SelService.Enabled = True;
				Items.SelServiceGroup.Enabled = True;
				Items.SelExtraServiceGroup.Enabled = True;
			EndIf;
			Return True;
		EndIf;
		Return Undefined;
	Else
		Items.SelService.Enabled = True;
		Items.SelServiceGroup.Enabled = True;
		Items.SelExtraServiceGroup.Enabled = True;
		Return False;
	EndIf;
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Procedure ClearForm()
	// Check if card was entered
	vCardIsBlank = IsBlankString(SelCard);
	// Clear attributes
	SelRoom = Catalogs.Rooms.EmptyRef();
	SelResource = Catalogs.Resources.EmptyRef();
	SelCard = "";
	SelClient = Catalogs.Clients.EmptyRef();
	SelGuestGroup = Catalogs.GuestGroups.EmptyRef();
	CurRoom = Catalogs.Rooms.EmptyRef();
	CurResource = Catalogs.Resources.EmptyRef();
	CurClient = Catalogs.Clients.EmptyRef();
	CurGuestGroup = Catalogs.GuestGroups.EmptyRef();
	CurFolio = Documents.Folio.EmptyRef();
	CurFolioCurrency = Catalogs.Currencies.EmptyRef();
	AvailableQuantity = 0;
	AvailableSum = 0;
	SelQuantity = 1;
	// Reset colors
	Items.SelCard.BackColor = Items.SelService.BackColor;
	Items.SelClient.BackColor = Items.SelService.BackColor;
	Items.SelRoom.BackColor = Items.SelService.BackColor;
	Items.SelResource.BackColor = Items.SelService.BackColor;
	// Reset password mode
	Items.SelCard.PasswordMode = False;
	// Clear clients list
	TableBoxClients.Clear();
	// Reset message
	TMessage = "";
	Items.TMessage.BackColor = StyleColors.FormBackColor;
	Items.TMessage.TextColor = StyleColors.FormTextColor;
	// Set form appearance
	SetFormAppearance();
	// Set focus back to room
	If vCardIsBlank Then
		ThisForm.CurrentItem = Items.SelRoom;
	Else
		ThisForm.CurrentItem = Items.SelCard;
	EndIf;
	// Hide clients list
	If Items.PanelMode.CurrentPage <> Items.PageProgress Then
		Items.PanelMode.CurrentPage = Items.PageProgress;
	EndIf;
EndProcedure // ClearForm

// -----------------------------------------------------------------------------
&AtServer
Procedure SetFormAppearance()
	vVisible = False;
	If TableBoxClients.Count() > 0 Then
		vVisible = True;
	EndIf;
	Items.TableBoxClients.Visible = vVisible;
	Items.ButtonRegister.Visible = vVisible;
	Items.ButtonRegister.Enabled = RegisterButtonAvailability;
	If Not vVisible Then
		If ValueIsFilled(SelRoom) Or ValueIsFilled(SelResource) Or
			ValueIsFilled(SelClient) Or ValueIsFilled(SelGuestGroup) Then
			vVisible = True;
		EndIf;
	EndIf;
	Items.CounterPlan.Visible = vVisible;
	Items.CounterWaiting.Visible = vVisible;
	If ValueIsFilled(SelHotel) And SelHotel.CloseServiceRegistration And (ValueIsFilled(SelService) Or ValueIsFilled(SelServiceGroup)) Then
		Items.CounterPlan.Visible = True;
		Items.CounterWaiting.Visible = True;
	EndIf;
	Items.ButtonChargeAndPay.Visible = vVisible;
	Items.ButtonChargeAndPay.Enabled = vVisible;
EndProcedure // SetFormAppearance

// -----------------------------------------------------------------------------
&AtServer
Procedure RestoreTotals()
	// Initialize totals
	TotalGuestsProcessed = 0;
	RoomRateGuestsProcessed = 0;
	ExtraGuestsProcessed = 0;
	
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SUM(CASE
	|			WHEN ISNULL(ServiceRegistrations.Service.IsInPrice, FALSE)
	|				THEN ServiceRegistrations.Quantity
	|			ELSE 0
	|		END) AS RoomRateQuantity,
	|	SUM(CASE
	|			WHEN NOT ISNULL(ServiceRegistrations.Service.IsInPrice, FALSE)
	|				THEN ServiceRegistrations.Quantity
	|			ELSE 0
	|		END) AS ExtraQuantity,
	|	SUM(ServiceRegistrations.Quantity) AS TotalQuantity
	|FROM
	|	Document.ServiceRegistration AS ServiceRegistrations
	|WHERE
	|	ServiceRegistrations.Posted
	|	AND ServiceRegistrations.Date >= &qPeriodFrom
	|	AND ServiceRegistrations.Date <= &qPeriodTo
	|	AND ServiceRegistrations.Hotel = &qHotel
	|	AND ServiceRegistrations.BoardPlace = &qBoardPlace
	|	AND ((ServiceRegistrations.Service = &qService
	|			OR &qServiceIsEmpty)
	|		OR (ServiceRegistrations.Service = &qExtraService
	|			OR &qExtraServiceIsEmpty))
	|	AND (&qUseServicesList
	|				AND ServiceRegistrations.Service IN (&qServicesList)
	|			OR NOT &qUseServicesList)";
	vQry.SetParameter("qPeriodFrom", BegOfDay(SelPeriod));
	vQry.SetParameter("qPeriodTo", EndOfDay(SelPeriod));
	vQry.SetParameter("qHotel", SelHotel);
	vQry.SetParameter("qBoardPlace", SelBoardPlace);
	If ValueIsFilled(SelServiceGroup) Then
		vQry.SetParameter("qService", Undefined);
		vQry.SetParameter("qServiceIsEmpty", True);
	Else
		vQry.SetParameter("qService", SelService);
		vQry.SetParameter("qServiceIsEmpty", Not ValueIsFilled(SelService));
	EndIf;
	If ValueIsFilled(SelExtraServiceGroup) Then
		vQry.SetParameter("qExtraService", Undefined);
		vQry.SetParameter("qExtraServiceIsEmpty", True);
	Else
		vQry.SetParameter("qExtraService", SelExtraService);
		vQry.SetParameter("qExtraServiceIsEmpty", Not ValueIsFilled(SelExtraService));
	EndIf;
	vUseServicesList = False;
	vServicesList = New ValueList();
	If ValueIsFilled(SelServiceGroup) Then
		vUseServicesList = True;
		If Not SelServiceGroup.IncludeAll Then
			vServicesList = cmGetServiceGroupServices(SelServiceGroup);
		EndIf;
	EndIf;
	If ValueIsFilled(SelExtraServiceGroup) Then
		vUseServicesList = True;
		If Not SelExtraServiceGroup.IncludeAll Then
			For Each vExtraSrvRow In SelExtraServiceGroup.Services Do
				If vServicesList.FindByValue(vExtraSrvRow.Service) = Undefined Then
					vServicesList.Add(vExtraSrvRow.Service);
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	If ValueIsFilled(SelServiceGroup) And SelServiceGroup.IncludeAll Then
		vUseServicesList = False;
	EndIf;
	If ValueIsFilled(SelExtraServiceGroup) And SelExtraServiceGroup.IncludeAll Then
		vUseServicesList = False;
	EndIf;
	vQry.SetParameter("qUseServicesList", vUseServicesList);
	vQry.SetParameter("qServicesList", vServicesList);
	vTotals = vQry.Execute().Unload();
	If vTotals.Count() > 0 Then
		
		vTotalsRow = vTotals.Get(0);
		
		TotalGuestsProcessed = vTotalsRow.TotalQuantity;
		RoomRateGuestsProcessed = vTotalsRow.RoomRateQuantity;
		ExtraGuestsProcessed = vTotalsRow.ExtraQuantity;
	EndIf;
	
	If TotalGuestsProcessed = Null Then
		TotalGuestsProcessed = 0;
	EndIf;
	If RoomRateGuestsProcessed = Null Then
		RoomRateGuestsProcessed = 0;
	EndIf;
	If ExtraGuestsProcessed = Null Then
		ExtraGuestsProcessed = 0;
	EndIf;
	
	// Format representation
	TotalGuestsProcessedStr = Format(TotalGuestsProcessed, "ND=10; NFD=0; NG=");
	RoomRateGuestsProcessedStr = Format(RoomRateGuestsProcessed, "ND=10; NFD=0; NG=");
	ExtraGuestsProcessedStr = Format(ExtraGuestsProcessed, "ND=10; NFD=0; NG=");
	
	// Calculate and show the number of services left to register
	If ValueIsFilled(SelHotel) And SelHotel.CloseServiceRegistration And (ValueIsFilled(SelService) Or ValueIsFilled(SelServiceGroup)) Then
		vPlannedQuantity = 0;
		
		// Run query
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	SUM(Sales.RoomRateQuantityTurnover) AS RoomRateQuantityTurnover,
		|	SUM(Sales.ExtraQuantityTurnover) AS ExtraQuantityTurnover,
		|	SUM(Sales.QuantityTurnover) AS QuantityTurnover
		|FROM
		|	(SELECT
		|		SalesTurnovers.Service AS Service,
		|		SUM(CASE
		|				WHEN ISNULL(SalesTurnovers.Service.IsInPrice, FALSE)
		|					THEN SalesTurnovers.Quantity
		|				ELSE 0
		|			END) AS RoomRateQuantityTurnover,
		|		SUM(CASE
		|				WHEN NOT ISNULL(SalesTurnovers.Service.IsInPrice, FALSE)
		|					THEN SalesTurnovers.Quantity
		|				ELSE 0
		|			END) AS ExtraQuantityTurnover,
		|		SUM(SalesTurnovers.Quantity) AS QuantityTurnover
		|	FROM
		|		AccumulationRegister.Sales AS SalesTurnovers
		|	WHERE
		|		SalesTurnovers.ServiceDate = &qServiceDate
		|		AND SalesTurnovers.Hotel = &qHotel
		|		AND SalesTurnovers.BoardPlace = &qBoardPlace
		|		AND SalesTurnovers.Service.ServiceRegistrationIsTurnedOn
		|		AND (SalesTurnovers.Service IN HIERARCHY (&qService)
		|				OR &qServiceIsEmpty)
		|		AND (SalesTurnovers.Service IN (&qServicesList)
		|				OR NOT &qUseServicesList)
		|	
		|	GROUP BY
		|		SalesTurnovers.Service
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		SalesForecastTurnovers.Service,
		|		SUM(CASE
		|				WHEN ISNULL(SalesForecastTurnovers.Service.IsInPrice, FALSE)
		|					THEN SalesForecastTurnovers.Quantity
		|				ELSE 0
		|			END),
		|		SUM(CASE
		|				WHEN NOT ISNULL(SalesForecastTurnovers.Service.IsInPrice, FALSE)
		|					THEN SalesForecastTurnovers.Quantity
		|				ELSE 0
		|			END),
		|		SUM(SalesForecastTurnovers.Quantity)
		|	FROM
		|		AccumulationRegister.SalesForecast AS SalesForecastTurnovers
		|	WHERE
		|		SalesForecastTurnovers.ServiceDate = &qServiceDate
		|		AND &qUseForecast
		|		AND SalesForecastTurnovers.Hotel = &qHotel
		|		AND SalesForecastTurnovers.BoardPlace = &qBoardPlace
		|		AND SalesForecastTurnovers.Service.ServiceRegistrationIsTurnedOn
		|		AND (SalesForecastTurnovers.Service IN HIERARCHY (&qService)
		|				OR &qServiceIsEmpty)
		|		AND (SalesForecastTurnovers.Service IN (&qServicesList)
		|				OR NOT &qUseServicesList)
		|	
		|	GROUP BY
		|		SalesForecastTurnovers.Service) AS Sales";
		vForecastStartDate = tcOnServer.GetForecastStartDate(SelHotel);
		vQry.SetParameter("qServiceDate", BegOfDay(SelPeriod));
		vQry.SetParameter("qUseForecast", ?(BegOfDay(SelPeriod) >= BegOfDay(vForecastStartDate), True, False));
		vQry.SetParameter("qHotel", SelHotel);
		vQry.SetParameter("qBoardPlace", SelBoardPlace);
		If ValueIsFilled(SelServiceGroup) Then
			vQry.SetParameter("qService", Undefined);
			vQry.SetParameter("qServiceIsEmpty", True);
		Else
			vQry.SetParameter("qService", SelService);
			vQry.SetParameter("qServiceIsEmpty", Not ValueIsFilled(SelService));
		EndIf;
		vUseServicesList = False;
		vServicesList = New ValueList();
		If ValueIsFilled(SelServiceGroup) Then
			If Not SelServiceGroup.IncludeAll Then
				vUseServicesList = True;
				vServicesList = cmGetServiceGroupServices(SelServiceGroup);
			EndIf;
		EndIf;
		vQry.SetParameter("qUseServicesList", vUseServicesList);
		vQry.SetParameter("qServicesList", vServicesList);
		vPlannedQuantityRows = vQry.Execute().Unload();
		If vPlannedQuantityRows.Count() > 0 Then
			
			vPlannedRow = vPlannedQuantityRows.Get(0);
			vPlannedRoomRateQuantity = vPlannedRow.RoomRateQuantityTurnover;
			If vPlannedRoomRateQuantity = Null Then
				vPlannedRoomRateQuantity = 0;
			EndIf;
			vPlannedExtraQuantity = vPlannedRow.ExtraQuantityTurnover;
			If vPlannedExtraQuantity = Null Then
				vPlannedExtraQuantity = 0;
			EndIf;
			vPlannedQuantity = vPlannedRow.QuantityTurnover;
			If vPlannedQuantity = Null Then
				vPlannedQuantity = 0;
			EndIf;
		EndIf;
		If vPlannedQuantity > 0 Or vPlannedExtraQuantity > 0 Or RoomRateGuestsProcessed > 0 Or ExtraGuestsProcessed > 0 Then
			vWaitingRoomRate = vPlannedRoomRateQuantity - RoomRateGuestsProcessed;
			vWaitingRoomRate = ?(vWaitingRoomRate < 0, 0, vWaitingRoomRate);
			vWaitingExtra = vPlannedExtraQuantity - ExtraGuestsProcessed;
			vWaitingExtra = ?(vWaitingExtra < 0, 0, vWaitingExtra);

			CounterPlan = Format(vPlannedRoomRateQuantity, "ND=10; NFD=0; NZ=; NG=") + "/" + Format(vPlannedExtraQuantity, "ND=10; NFD=0; NZ=; NG=");
			CounterWaiting = Format(vWaitingRoomRate, "ND=10; NFD=; NZ=; NG=") + "/" + Format(vWaitingExtra, "ND=10; NFD=0; NZ=; NG=");
		Else
			CounterPlan = "";
			CounterWaiting = "";
		EndIf;
	EndIf;
EndProcedure // RestoreTotals

// -----------------------------------------------------------------------------
&AtServer
Function FillClientsList(pKeepMessageText = False, pCardRef = Undefined)
	vResult = True;
	// Fill current card
	If ValueIsFilled(pCardRef) Then
		CurrentCard = pCardRef;
	EndIf;
	// Clear clients list
	TableBoxClients.Clear();
	TMessage = "";
	Items.GroupSelRoom.ReadOnly = False;
	Items.GroupSelQuantity.ReadOnly = False;
	Items.PanelMode.ReadOnly = False;
	If Not ValueIsFilled(SelService) And Not ValueIsFilled(SelServiceGroup) And Not ValueIsFilled(SelExtraService) And Not ValueIsFilled(SelExtraServiceGroup) Then
		Items.GroupSelRoom.ReadOnly = True;
		Items.GroupSelQuantity.ReadOnly = True;
		Items.PanelMode.ReadOnly = True;
		TMessage = StrTemplate(NStr("en = 'There are no services to charge for %1'; de = 'Für %1 sind keine kostenpflichtigen Dienste vorhanden.'; ru = 'На %1 нет услуг для начисления'"), Format(CurrentSessionDate(), "DF='dd.MM.yyyy HH:mm'"));
	EndIf;
	// Check what is filled
	If Not ValueIsFilled(SelService) And Not ValueIsFilled(SelServiceGroup) Or
		Not (ValueIsFilled(SelRoom) Or ValueIsFilled(SelResource) Or ValueIsFilled(SelClient) Or Not IsBlankString(SelCard)) Then
		// Set form appearance
		SetFormAppearance();
		Return vResult;
	EndIf;
	// Run query to get balances
	vQry = New Query();
	If ValueIsFilled(SelHotel) And Not SelHotel.CloseServiceRegistration Then
		vQry.Text = 
		"SELECT DISTINCT
		|	ServiceRegistrationBalance.Service AS Service,
		|	ServiceRegistrationBalance.Client AS Client,
		|	CASE
		|		WHEN ISNULL(ServiceRegistrationBalance.Client.Age, 0) > 0
		|				AND ISNULL(ServiceRegistrationBalance.Client.Age, 0) < 18
		|			THEN ISNULL(ServiceRegistrationBalance.Client.Age, 0)
		|		ELSE 0
		|	END AS Age,
		|	CASE
		|		WHEN NOT ServiceRegistrationBalance.Client.DateOfBirth IS NULL
		|				AND ServiceRegistrationBalance.Client.DateOfBirth <> &qEmptyDate
		|				AND DAY(ServiceRegistrationBalance.Client.DateOfBirth) = &qTodayDay
		|				AND MONTH(ServiceRegistrationBalance.Client.DateOfBirth) = &qTodayMonth
		|			THEN 55
		|		ELSE 0
		|	END AS BirthdayToday,
		|	ServiceRegistrationBalance.GuestGroup AS GuestGroup,
		|	ServiceRegistrationBalance.Room AS Room,
		|	ServiceRegistrationBalance.Resource AS Resource,
		|	ServiceRegistrationBalance.Folio AS Folio,
		|	ServiceRegistrationBalance.FolioCurrency AS FolioCurrency,
		|	ServiceRegistrationBalance.SumBalance AS AvailableSum,
		|	ServiceRegistrationBalance.QuantityBalance AS AvailableQuantity
		|FROM
		|	AccumulationRegister.ServiceRegistration.Balance(
		|			&qPeriod,
		|			Hotel = &qHotel
		|				AND BoardPlace = &qBoardPlace
		|				AND (Service = &qService
		|					OR &qServiceIsEmpty)
		|				AND (Service IN (&qServicesList)
		|					OR NOT &qUseServicesList)
		|				AND (Room = &qRoom
		|						AND Room <> &qEmptyRoom
		|					OR Resource = &qResource
		|						AND Resource <> &qEmptyResource
		|					OR Client = &qClient
		|						AND NOT &qClientIsEmpty
		|						AND &qRoomIsEmpty
		|						AND &qResourceIsEmpty)
		|				AND (Client = &qClient
		|					OR &qClientIsEmpty)
		|				AND (GuestGroup = &qGuestGroup
		|					OR &qGuestGroupIsEmpty)
		|				AND (Folio.DateTimeTo > &qBegOfYesterday
		|					OR Folio.DateTimeTo = &qEmptyDate)) AS ServiceRegistrationBalance
		|
		|ORDER BY
		|	AvailableQuantity,
		|	ServiceRegistrationBalance.Client.Description,
		|	ServiceRegistrationBalance.Service.IsInPrice DESC,
		|	ServiceRegistrationBalance.Service.SortCode,
		|	ServiceRegistrationBalance.Service.Description";
		vQry.SetParameter("qPeriod", ?(ValueIsFilled(SelPeriod), EndOfDay(SelPeriod), '00010101'));
		vQry.SetParameter("qBegOfYesterday", BegOfDay(CurrentSessionDate()) - 24*3600);
	Else
		vQry.Text = 
		"SELECT
		|	ServiceRegistrationBalance.Service AS Service,
		|	ServiceRegistrationBalance.Client AS Client,
		|	CASE
		|		WHEN ISNULL(ServiceRegistrationBalance.Client.Age, 0) > 0
		|				AND ISNULL(ServiceRegistrationBalance.Client.Age, 0) < 18
		|			THEN ISNULL(ServiceRegistrationBalance.Client.Age, 0)
		|		ELSE 0
		|	END AS Age,
		|	CASE
		|		WHEN NOT ServiceRegistrationBalance.Client.DateOfBirth IS NULL
		|				AND ServiceRegistrationBalance.Client.DateOfBirth <> &qEmptyDate
		|				AND DAY(ServiceRegistrationBalance.Client.DateOfBirth) = &qTodayDay
		|				AND MONTH(ServiceRegistrationBalance.Client.DateOfBirth) = &qTodayMonth
		|			THEN 55
		|		ELSE 0
		|	END AS BirthdayToday,
		|	ServiceRegistrationBalance.GuestGroup AS GuestGroup,
		|	ServiceRegistrationBalance.Room AS Room,
		|	ServiceRegistrationBalance.Resource AS Resource,
		|	ServiceRegistrationBalance.Folio AS Folio,
		|	ServiceRegistrationBalance.FolioCurrency AS FolioCurrency,
		|	ServiceRegistrationBalance.SumTurnover AS AvailableSum,
		|	ServiceRegistrationBalance.QuantityTurnover AS AvailableQuantity
		|FROM
		|	AccumulationRegister.ServiceRegistration.Turnovers(
		|			&qPeriodFrom,
		|			&qPeriodTo,
		|			PERIOD,
		|			Hotel = &qHotel
		|				AND BoardPlace = &qBoardPlace
		|				AND (Service = &qService
		|					OR &qServiceIsEmpty)
		|				AND (Service IN (&qServicesList)
		|					OR NOT &qUseServicesList)
		|				AND (Room = &qRoom
		|						AND Room <> &qEmptyRoom
		|					OR Resource = &qResource
		|						AND Resource <> &qEmptyResource
		|					OR Client = &qClient
		|						AND NOT &qClientIsEmpty
		|						AND &qRoomIsEmpty
		|						AND &qResourceIsEmpty)
		|				AND (Client = &qClient
		|					OR &qClientIsEmpty)
		|				AND (GuestGroup = &qGuestGroup
		|					OR &qGuestGroupIsEmpty)) AS ServiceRegistrationBalance
		|
		|ORDER BY
		|	AvailableQuantity,
		|	ServiceRegistrationBalance.Client.Description,
		|	ServiceRegistrationBalance.Service.IsInPrice DESC,
		|	ServiceRegistrationBalance.Service.SortCode,
		|	ServiceRegistrationBalance.Service.Description";
		vQry.SetParameter("qPeriodFrom", ?(ValueIsFilled(SelPeriod), BegOfDay(SelPeriod), '00010101'));
		vQry.SetParameter("qPeriodTo", ?(ValueIsFilled(SelPeriod), EndOfDay(SelPeriod), '00010101'));
	EndIf;
	vQry.SetParameter("qHotel", SelHotel);
	vQry.SetParameter("qBoardPlace", SelBoardPlace);
	If ValueIsFilled(SelServiceGroup) Then
		vQry.SetParameter("qService", Undefined);
		vQry.SetParameter("qServiceIsEmpty", True);
	Else
		vQry.SetParameter("qService", SelService);
		vQry.SetParameter("qServiceIsEmpty", Not ValueIsFilled(SelService));
	EndIf;
	vQry.SetParameter("qRoom", SelRoom);
	vQry.SetParameter("qEmptyRoom", Catalogs.Rooms.EmptyRef());
	vQry.SetParameter("qRoomIsEmpty", Not ValueIsFilled(SelRoom));
	vQry.SetParameter("qResource", SelResource);
	vQry.SetParameter("qEmptyResource", Catalogs.Resources.EmptyRef());
	vQry.SetParameter("qResourceIsEmpty", Not ValueIsFilled(SelResource));
	If ValueIsFilled(CurrentCard) And ValueIsFilled(CurrentCard.ParentDoc) Then
		If TypeOf(CurrentCard.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(CurrentCard.ParentDoc) = Type("DocumentRef.Reservation") Then
			vParentDoc = CurrentCard.ParentDoc;
			If ValueIsFilled(vParentDoc.AccommodationType) And vParentDoc.AccommodationType.Type = Enums.AccomodationTypes.Beds Then
				vQry.SetParameter("qClient", SelClient);
				vQry.SetParameter("qClientIsEmpty", Not ValueIsFilled(SelClient));
			Else
				vQry.SetParameter("qClient", Catalogs.Clients.EmptyRef());
				vQry.SetParameter("qClientIsEmpty", True);
			EndIf;
		Else
			vQry.SetParameter("qClient", SelClient);
			vQry.SetParameter("qClientIsEmpty", Not ValueIsFilled(SelClient));
		EndIf;
	Else
		vQry.SetParameter("qClient", SelClient);
		vQry.SetParameter("qClientIsEmpty", Not ValueIsFilled(SelClient));
	EndIf;
	vQry.SetParameter("qGuestGroup", SelGuestGroup);
	vQry.SetParameter("qGuestGroupIsEmpty", Not ValueIsFilled(SelGuestGroup));
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qTodayDay", Day(CurrentSessionDate()));
	vQry.SetParameter("qTodayMonth", Month(CurrentSessionDate()));
	vUseServicesList = False;
	vServicesList = New ValueList();
	If ValueIsFilled(SelServiceGroup) Then
		If Not SelServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(SelServiceGroup);
		EndIf;
	EndIf;
	vQry.SetParameter("qUseServicesList", vUseServicesList);
	vQry.SetParameter("qServicesList", vServicesList);
	vTableBoxClients = vQry.Execute().Unload();
	vTableBoxClients.Columns.Add("AccommodationType", cmGetCatalogTypeDescription("AccommodationTypes"));
	vTableBoxClients.Columns.Add("AccommodationTypeSortCode", cmGetNumberTypeDescription(4, 0));
	vTableBoxClients.Columns.Add("ServicePackage", cmGetCatalogTypeDescription("ServicePackages"));
	vTableBoxClients.Columns.Add("AccommodationTemplate", cmGetCatalogTypeDescription("AccommodationTemplates"));
	vTableBoxClients.Columns.Add("RoomRate", cmGetCatalogTypeDescription("RoomRates"));
	vAccommodationTemplate = Undefined;
	vRoomRate = Undefined;
	For Each vTableBoxClientsRow In vTableBoxClients Do
		vClientExtraParameters = GetClientExtraParameters(vTableBoxClientsRow.Service, vTableBoxClientsRow.Room, vTableBoxClientsRow.Client);
		FillPropertyValues(vTableBoxClientsRow, vClientExtraParameters);
		vCurAccType = vTableBoxClientsRow.AccommodationType;
		If vTableBoxClientsRow.Age = 0 And ValueIsFilled(vCurAccType) And vCurAccType.AllowedClientAgeTo > 0 Then
			vTableBoxClientsRow.Age = vCurAccType.AllowedClientAgeTo - 1;
		EndIf;
		If ValueIsFilled(vCurAccType) Then
			vTableBoxClientsRow.AccommodationTypeSortCode = vCurAccType.SortCode;
		EndIf;
		If Not ValueIsFilled(vAccommodationTemplate) And ValueIsFilled(vClientExtraParameters.AccommodationTemplate) Then
			vAccommodationTemplate = vClientExtraParameters.AccommodationTemplate;
		EndIf;
		If Not ValueIsFilled(vRoomRate) And ValueIsFilled(vClientExtraParameters.RoomRate) Then
			vRoomRate = vClientExtraParameters.RoomRate;
		EndIf;
	EndDo;
	vTableBoxClients.Sort("AccommodationTypeSortCode");
	TableBoxClients.Load(vTableBoxClients);
	// Set message text
	If Not pKeepMessageText Then
		// Reset message
		TMessage = "";
		If ValueIsFilled(vAccommodationTemplate) Then
			TMessage = TMessage + NStr("en='Persons: '; ru='Гостей: '; de='Personen: '") + TrimAll(vAccommodationTemplate) + Chars.LF;
		EndIf;
		If ValueIsFilled(vRoomRate) Then
			TMessage = TMessage + NStr("en='Rate: '; ru='Тариф: '; de='Tarif: '") + TrimAll(vRoomRate) + Chars.LF;
		EndIf;
		If Not IsBlankString(TMessage) Then
			TMessage = TMessage + Chars.LF;
		EndIf;
		
		// Check if there are rows with negative balance. If yes, then remove this row
		i = 0;
		While i < TableBoxClients.Count() Do
			vRow = TableBoxClients.Get(i);
			If vRow.AvailableQuantity = 0 Then
				TableBoxClients.Delete(i);
				Continue;
			ElsIf vRow.AvailableQuantity < 0 Then
				j = i + 1;
				While j < TableBoxClients.Count() Do
					vNextRow = TableBoxClients.Get(j);
					If vNextRow.AvailableQuantity > 0 Then
						vNextRow.AvailableQuantity = vNextRow.AvailableQuantity + vRow.AvailableQuantity;
						vRow.AvailableQuantity = 0;
						Break;
					EndIf;
					j = j + 1;
				EndDo;
				If vRow.AvailableQuantity = 0 Then
					TableBoxClients.Delete(i);
					Continue;
				EndIf;
			EndIf;
			i = i + 1;
		EndDo;
		// Remove negative rows
		i = 0;
		While i < TableBoxClients.Count() Do
			vRow = TableBoxClients.Get(i);
			If vRow.AvailableQuantity = 0 Then
				TableBoxClients.Delete(i);
				Continue;
			EndIf;
			i = i + 1;
		EndDo;
		
		// Check search results
		If TableBoxClients.Count() = 0 Then
			vResult = False;
			If ValueIsFilled(SelRoom) Or ValueIsFilled(SelResource) Then
				If ValueIsFilled(CurrentCard) Then
					// Check if this card was already used today
					vWarningMessage = CheckIfCardWasAlreadyUsed(CurrentCard);
					If Not IsBlankString(vWarningMessage) Then
						// Show warning message
						Items.TMessage.BackColor = WebColors.Yellow;
						Items.TMessage.TextColor = Items.SelService.TextColor;
						TMessage = ?(ValueIsFilled(SelRoom), "" + SelRoom + ", ", "") + ?(ValueIsFilled(CurrentCard.Client), TrimAll(CurrentCard.Client.FullName) + " - ", "") + 
						vWarningMessage;
					Else
						// Show error message
						TMessage = ?(ValueIsFilled(SelRoom), "" + SelRoom + ", ", "") + ?(ValueIsFilled(CurrentCard.Client), TrimAll(CurrentCard.Client.FullName) + " - ", "") + 
						NStr("en='Client does not have services prepaid!';
						|ru='У клиента нет начисленных услуг! Можете начислить услугу, принять за неё оплату и зарегистрировать её.';
						|de='Bei dem Kunden gibt es keine berechneten Dienstleistungen!'");
					EndIf;
				Else
					// Check if this card was already used today
					vWarningMessage = CheckIfRoomWasAlreadyUsed();
					If Not IsBlankString(vWarningMessage) Then
						// Show warning message
						Items.TMessage.BackColor = WebColors.Yellow;
						Items.TMessage.TextColor = Items.SelService.TextColor;
						TMessage = ?(ValueIsFilled(SelRoom), "" + SelRoom + ", ", "") + 
						vWarningMessage;
					Else
						// Show error message
						TMessage = ?(ValueIsFilled(SelRoom), "" + SelRoom + ", ", "") + 
						NStr("en='Client does not have services prepaid!';
						|ru='У клиента нет начисленных услуг! Можете начислить услугу, принять за неё оплату и зарегистрировать её.';
						|de='Bei dem Kunden gibt es keine berechneten Dienstleistungen!'");
						If ValueIsFilled(SelRoom) And Not CheckAccommodationByRoom(SelRoom) Then
							TMessage = StrTemplate(NStr("en = 'Client does not have services prepaid!'; de = 'There are no guests staying in room %1'; ru = 'В номере %1 нет проживающих гостей'"), TrimAll(SelRoom));
						EndIf;
					EndIf;
				EndIf;
				// Write safety event
				cmWriteSafetyEvent(SelHotel, "ServiceRegistration", CurrentSessionDate(), SelRoom, "ClientIdentificationCard", TrimAll(SelCard), , SelClient, TMessage, , , 0);
			Else
				If ValueIsFilled(CurrentCard) And ValueIsFilled(CurrentCard.Folio) Then
					Items.TMessage.BackColor = WebColors.Red;
					Items.TMessage.TextColor = WebColors.White;
					Items.SelClient.BackColor = WebColors.Red;
					Items.SelRoom.BackColor = WebColors.Red;
					Items.SelResource.BackColor = WebColors.Red;
					Items.SelCard.BackColor = WebColors.Red;
					TMessage = NStr("en='There are no services on this card folio!';ru='На лицевом счете карты нет начисленных услуг!';de='Bei dem Kartekonto gibt es keine berechneten Dienstleistungen!'");
				ElsIf ValueIsFilled(CurrentCard) And Not ValueIsFilled(CurrentCard.Folio) Then
					Items.TMessage.BackColor = WebColors.Yellow;
					Items.TMessage.TextColor = Items.SelService.TextColor;
					Items.SelClient.BackColor = WebColors.Yellow;
					Items.SelRoom.BackColor = WebColors.Yellow;
					Items.SelResource.BackColor = WebColors.Yellow;
					Items.SelCard.BackColor = WebColors.Yellow;
					TMessage = NStr("en='Card folio is not specified! Ask client to renew his cards please.';ru='У карты не заполнен лицевой счет! Пожалуйста попросите клиента заново получить карты.';de='Die Kartekonto ist leer! Stellen Sie Client, seine Karten zu erneuern bitte.'");
				ElsIf ValueIsFilled(SelClient) Then
					Items.TMessage.BackColor = WebColors.Red;
					Items.TMessage.TextColor = WebColors.White;
					Items.SelClient.BackColor = WebColors.Red;
					Items.SelRoom.BackColor = WebColors.Red;
					Items.SelResource.BackColor = WebColors.Red;
					Items.SelCard.BackColor = WebColors.Red;
					TMessage = TrimAll(SelClient.FullName) + " - " + NStr("en='Client does not have services prepaid!';ru='У клиента нет начисленных услуг!';de='Bei dem Kunden gibt es keine berechneten Dienstleistungen!'");
				ElsIf Not IsBlankString(SelCard) Then
					Items.TMessage.BackColor = WebColors.Yellow;
					Items.TMessage.TextColor = Items.SelService.TextColor;
					Items.SelClient.BackColor = WebColors.Yellow;
					Items.SelRoom.BackColor = WebColors.Yellow;
					Items.SelResource.BackColor = WebColors.Yellow;
					Items.SelCard.BackColor = WebColors.Yellow;
					TMessage = NStr("en='Card is not in the system! Ask client to renew his cards please.';ru='Карта не зарегистрирована в программе! Пожалуйста попросите клиента заново получить карты.';de='Die Karte ist nicht registriert! Stellen Sie Client, seine Karten zu erneuern bitte.'");
				Else
					Items.TMessage.BackColor = WebColors.DarkBlue;
					Items.TMessage.TextColor = WebColors.White;
					TMessage = NStr("en='Nothing is specified in search conditions!';ru='Ничего не указано в параметрах поиска!';de='Nichts wird in Suchbedingungen angegeben!'");
				EndIf;
				// Write safety event
				cmWriteSafetyEvent(SelHotel, "ServiceRegistration", CurrentSessionDate(), SelRoom, "ClientIdentificationCard", TrimAll(SelCard), , SelClient, TMessage, , , 0);
			EndIf;
		Else
			// Show list if it is necessary
			If ShowGuestList Then
				If Items.PanelMode.CurrentPage <> Items.PageGuests Then
					Items.PanelMode.CurrentPage = Items.PageGuests;
				EndIf;
				Items.TMessage.BackColor = StyleColors.FormBackColor;
				Items.TMessage.TextColor = StyleColors.FormTextColor;
				TMessage = TMessage + NStr("en='Choose client from the list!';ru='Выберите клиента из списка!';de='Wählen Sie den Kunden aus der Liste!'");
			EndIf;
		EndIf;
	EndIf;
	// Set form appearance
	SetFormAppearance();
	CurrentCard = Undefined;
	// Return
	Return vResult;
EndFunction // FillClientsList

// -----------------------------------------------------------------------------
&AtServer
Function GetClientExtraParameters(pService, pRoom, pClient)
	vExtraParams = New Structure("AccommodationType, ServicePackage, AccommodationTemplate, RoomRate", Undefined, Undefined, Undefined, Undefined);
	vQry = New Query();
	vQry.Text = 
	"SELECT DISTINCT
	|	Movements.AccommodationTemplate AS AccommodationTemplate,
	|	Movements.ServicePackage AS ServicePackage,
	|	Movements.AccommodationType AS AccommodationType,
	|	Movements.RoomRate AS RoomRate
	|FROM
	|	(SELECT
	|		SalesMovements.AccommodationTemplate AS AccommodationTemplate,
	|		SalesMovements.ServicePackage AS ServicePackage,
	|		SalesMovements.AccommodationType AS AccommodationType,
	|		SalesMovements.RoomRate AS RoomRate
	|	FROM
	|		AccumulationRegister.Sales AS SalesMovements
	|	WHERE
	|		SalesMovements.Client = &qClient
	|		AND SalesMovements.Service = &qService
	|		AND SalesMovements.Room = &qRoom
	|		AND SalesMovements.ServiceDate = &qServiceDate
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		SalesForecastMovements.AccommodationTemplate,
	|		SalesForecastMovements.ServicePackage,
	|		SalesForecastMovements.AccommodationType,
	|		SalesForecastMovements.RoomRate
	|	FROM
	|		AccumulationRegister.SalesForecast AS SalesForecastMovements
	|	WHERE
	|		SalesForecastMovements.Client = &qClient
	|		AND SalesForecastMovements.Service = &qService
	|		AND SalesForecastMovements.Room = &qRoom
	|		AND SalesForecastMovements.ServiceDate = &qServiceDate) AS Movements
	|
	|ORDER BY
	|	Movements.AccommodationType.SortCode";
	vQry.SetParameter("qClient", pClient);
	vQry.SetParameter("qService", pService);
	vQry.SetParameter("qRoom", pRoom);
	vQry.SetParameter("qServiceDate", BegOfDay(SelPeriod));
	vData = vQry.Execute().Unload();
	For Each vDataRow In vData Do
		If ValueIsFilled(vDataRow.AccommodationType) And Not ValueIsFilled(vExtraParams.AccommodationType) Then
			vExtraParams.AccommodationType = vDataRow.AccommodationType;
		EndIf;
		If ValueIsFilled(vDataRow.AccommodationTemplate) And Not ValueIsFilled(vExtraParams.AccommodationTemplate) Then
			vExtraParams.AccommodationTemplate = vDataRow.AccommodationTemplate;
		EndIf;
		If ValueIsFilled(vDataRow.ServicePackage) And Not ValueIsFilled(vExtraParams.ServicePackage) Then
			vExtraParams.ServicePackage = vDataRow.ServicePackage;
		EndIf;
		If ValueIsFilled(vDataRow.RoomRate) And Not ValueIsFilled(vExtraParams.RoomRate) Then
			vExtraParams.RoomRate = vDataRow.RoomRate;
		EndIf;
	EndDo;
	Return vExtraParams;
EndFunction // GetClientExtraParameters

// -----------------------------------------------------------------------------
&AtServer
Function CheckIfCardWasAlreadyUsed(pCardRef)
	vWarningMessage = "";
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SUM(CASE
	|			WHEN ISNULL(ServiceRegistrations.Service.IsInPrice, FALSE)
	|				THEN ServiceRegistrations.Quantity
	|			ELSE 0
	|		END) AS RoomRateQuantity,
	|	SUM(CASE
	|			WHEN NOT ISNULL(ServiceRegistrations.Service.IsInPrice, FALSE)
	|				THEN ServiceRegistrations.Quantity
	|			ELSE 0
	|		END) AS ExtraQuantity,
	|	SUM(ServiceRegistrations.Quantity) AS TotalQuantity
	|FROM
	|	Document.ServiceRegistration AS ServiceRegistrations
	|WHERE
	|	ServiceRegistrations.Posted
	|	AND ServiceRegistrations.Date >= &qPeriodFrom
	|	AND ServiceRegistrations.Date <= &qPeriodTo
	|	AND ServiceRegistrations.Hotel = &qHotel
	|	AND (ServiceRegistrations.Service = &qService
	|			OR &qServiceIsEmpty)
	|	AND (ServiceRegistrations.Service IN (&qServicesList)
	|			OR NOT &qUseServicesList)
	|	AND (ServiceRegistrations.IdentificationCard = &qIdentificationCard
	|			OR &qCardRoomIsFilled
	|				AND ServiceRegistrations.Room = &qCardRoom)";
	vQry.SetParameter("qIdentificationCard", pCardRef);
	vQry.SetParameter("qCardRoomIsFilled", ValueIsFilled(pCardRef.Room));
	vQry.SetParameter("qCardRoom", pCardRef.Room);
	vQry.SetParameter("qPeriodFrom", BegOfDay(SelPeriod));
	vQry.SetParameter("qPeriodTo", EndOfDay(SelPeriod));
	vQry.SetParameter("qHotel", SelHotel);
	If ValueIsFilled(SelServiceGroup) Then
		vQry.SetParameter("qService", Undefined);
		vQry.SetParameter("qServiceIsEmpty", True);
	Else
		vQry.SetParameter("qService", SelService);
		vQry.SetParameter("qServiceIsEmpty", Not ValueIsFilled(SelService));
	EndIf;
	vUseServicesList = False;
	vServicesList = New ValueList();
	If ValueIsFilled(SelServiceGroup) Then
		If Not SelServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(SelServiceGroup);
		EndIf;
	EndIf;
	vQry.SetParameter("qUseServicesList", vUseServicesList);
	vQry.SetParameter("qServicesList", vServicesList);
	vTotals = vQry.Execute().Unload();
	If vTotals.Count() > 0 Then
		vTotalsRow = vTotals.Get(0);
		If vTotalsRow.TotalQuantity <> Null And vTotalsRow.TotalQuantity > 0 Then
			vWarningMessage = NStr("en = 'Room from this card was already used to register services by quantity: '; 
			|ru = 'По номеру комнаты из карты уже зарегистрированы услуги в кол-ве: '; 
			|de = 'Auf der Karte sind bereits Dienstleistungen innerhalb eines Menge registriert: '") + vTotalsRow.TotalQuantity;
		EndIf;
	EndIf;
	Return vWarningMessage;
EndFunction // CheckIfCardWasAlreadyUsed

// -----------------------------------------------------------------------------
&AtServer
Function CheckIfRoomWasAlreadyUsed()
	vWarningMessage = "";
	If Not ValueIsFilled(SelRoom) Then
		Return vWarningMessage;
	EndIf;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SUM(CASE
	|			WHEN ISNULL(ServiceRegistrations.Service.IsInPrice, FALSE)
	|				THEN ServiceRegistrations.Quantity
	|			ELSE 0
	|		END) AS RoomRateQuantity,
	|	SUM(CASE
	|			WHEN NOT ISNULL(ServiceRegistrations.Service.IsInPrice, FALSE)
	|				THEN ServiceRegistrations.Quantity
	|			ELSE 0
	|		END) AS ExtraQuantity,
	|	SUM(ServiceRegistrations.Quantity) AS TotalQuantity
	|FROM
	|	Document.ServiceRegistration AS ServiceRegistrations
	|WHERE
	|	ServiceRegistrations.Posted
	|	AND ServiceRegistrations.Date >= &qPeriodFrom
	|	AND ServiceRegistrations.Date <= &qPeriodTo
	|	AND ServiceRegistrations.Hotel = &qHotel
	|	AND (ServiceRegistrations.Service = &qService
	|			OR &qServiceIsEmpty)
	|	AND (ServiceRegistrations.Service IN (&qServicesList)
	|			OR NOT &qUseServicesList)
	|	AND ServiceRegistrations.Room = &qRoom";
	vQry.SetParameter("qRoom", SelRoom);
	vQry.SetParameter("qPeriodFrom", BegOfDay(SelPeriod));
	vQry.SetParameter("qPeriodTo", EndOfDay(SelPeriod));
	vQry.SetParameter("qHotel", SelHotel);
	If ValueIsFilled(SelServiceGroup) Then
		vQry.SetParameter("qService", Undefined);
		vQry.SetParameter("qServiceIsEmpty", True);
	Else
		vQry.SetParameter("qService", SelService);
		vQry.SetParameter("qServiceIsEmpty", Not ValueIsFilled(SelService));
	EndIf;
	vUseServicesList = False;
	vServicesList = New ValueList();
	If ValueIsFilled(SelServiceGroup) Then
		If Not SelServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(SelServiceGroup);
		EndIf;
	EndIf;
	vQry.SetParameter("qUseServicesList", vUseServicesList);
	vQry.SetParameter("qServicesList", vServicesList);
	vTotals = vQry.Execute().Unload();
	If vTotals.Count() > 0 Then
		vTotalsRow = vTotals.Get(0);
		If vTotalsRow.TotalQuantity <> Null And vTotalsRow.TotalQuantity > 0 Then
			vWarningMessage = NStr("en = 'This room was already used to register services by quantity: '; 
			|ru = 'По номеру уже зарегистрированы услуги в кол-ве: '; 
			|de = 'Auf die Zimmer sind bereits Dienstleistungen innerhalb eines Menge registriert: '") + vTotalsRow.TotalQuantity;
		EndIf;
	EndIf;
	Return vWarningMessage;
EndFunction // CheckIfRoomWasAlreadyUsed

// -----------------------------------------------------------------------------
&AtClient 
Procedure ChooseServiceFromServiceGroupCompleted(pUC, pExtraParams) Export
	If pUC <> Undefined Then
		SelService = pUC.Value;
	EndIf;
EndProcedure // ChooseServiceFromServiceGroupCompleted

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetServiceGroupServices(pServiceGroup)
	Return pServiceGroup.GetObject().pmGetServicesList();
EndFunction // GetServiceGroupServices

// -----------------------------------------------------------------------------
&AtClient 
Procedure ChooseExtraServiceFromServiceGroupCompleted(pUC, pExtraParams) Export
	If pUC <> Undefined Then
		SelExtraService = pUC.Value;
	EndIf;
EndProcedure // ChooseServiceFromServiceGroupCompleted

// -----------------------------------------------------------------------------
&AtServer
Procedure SelRoomOnChangeAtServer()
	TimeCounterForCleansing = 0;
	// Reset form	
	SelCard = "";
	SelClient = Catalogs.Clients.EmptyRef();
	SelGuestGroup = Catalogs.GuestGroups.EmptyRef();
	CurRoom = Catalogs.Rooms.EmptyRef();
	CurResource = Catalogs.Resources.EmptyRef();
	CurClient = Catalogs.Clients.EmptyRef();
	CurGuestGroup = Catalogs.GuestGroups.EmptyRef();
	CurFolio = Documents.Folio.EmptyRef();
	CurFolioCurrency = Catalogs.Currencies.EmptyRef();
	AvailableQuantity = 0;
	AvailableSum = 0;
	// Reset current card
	CurrentCard = Undefined;
	// Reset colors
	Items.SelCard.BackColor = Items.SelService.BackColor;
	Items.SelClient.BackColor = Items.SelService.BackColor;
	Items.SelRoom.BackColor = Items.SelService.BackColor;
	Items.SelResource.BackColor = Items.SelService.BackColor;
	// Reset message
	Items.TMessage.BackColor = StyleColors.FormBackColor;
	Items.TMessage.TextColor = StyleColors.FormTextColor;
	// Fill clients list based on curent form settings
	If Items.PanelMode.CurrentPage <> Items.PageGuests Then
		Items.PanelMode.CurrentPage = Items.PageGuests;
	EndIf;
	vResult = FillClientsList();
EndProcedure // SelRoomOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SelClientOnChangeAtServer()
	TimeCounterForCleansing = 0;
	// Reset form	
	SelCard = "";
	SelRoom = Catalogs.Rooms.EmptyRef();
	SelResource = Catalogs.Resources.EmptyRef();
	SelGuestGroup = Catalogs.GuestGroups.EmptyRef();
	CurRoom = Catalogs.Rooms.EmptyRef();
	CurResource = Catalogs.Resources.EmptyRef();
	CurClient = Catalogs.Clients.EmptyRef();
	CurGuestGroup = Catalogs.GuestGroups.EmptyRef();
	CurFolio = Documents.Folio.EmptyRef();
	CurFolioCurrency = Catalogs.Currencies.EmptyRef();
	AvailableQuantity = 0;
	AvailableSum = 0;
	// Reset current card
	CurrentCard = Undefined;
	// Reset colors
	Items.SelClient.BackColor = Items.SelService.BackColor;
	Items.SelCard.BackColor = Items.SelService.BackColor;
	Items.SelRoom.BackColor = Items.SelService.BackColor;
	Items.SelResource.BackColor = Items.SelService.BackColor;
	// Reset message
	Items.TMessage.BackColor = StyleColors.FormBackColor;
	Items.TMessage.TextColor = StyleColors.FormTextColor;
	// Fill clients list based on curent form settings
	If Items.PanelMode.CurrentPage <> Items.PageGuests Then
		Items.PanelMode.CurrentPage = Items.PageGuests;
	EndIf;
	vResult = FillClientsList();
EndProcedure // SelClientOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function CardOnChange()
	vServiceWasRegistered = False;
	rCardRef = Undefined;
	rCardType = Undefined;
	If Not IsBlankString(SelCard) Then
		rCardRef = cmGetClientIdentificationCardById(cmGetCardIdentifier(SelCard));
		If ValueIsFilled(rCardRef) Then
			rCardType = rCardRef.IdentificationCardType;
			If Not rCardRef.IsBlocked Then
				If ValueIsFilled(rCardType) And rCardType.DoServiceRegistrationWithoutChargesControl Then
					SelRoom = rCardRef.Room;
					SelResource = Undefined;
					SelClient = rCardRef.Client;
					// Register special service
					vServiceWasRegistered = DoSpecialServiceRegistration(SelExtraService, rCardRef);
				Else
					If ValueIsFilled(rCardRef.Folio) And rCardRef.Folio.IsClosed Then 
						SelRoom = rCardRef.Room;
						Items.TMessage.BackColor = WebColors.Red;
						Items.TMessage.TextColor = WebColors.White;
						Items.SelClient.BackColor = WebColors.Red;
						Items.SelRoom.BackColor = WebColors.Red;
						Items.SelResource.BackColor = WebColors.Red;
						Items.SelCard.BackColor = WebColors.Red;
						TMessage = NStr("en='Client folio is CLOSED!';ru='Лицевой счет клиента ЗАКРЫТ!';de='Das Personenkonto des Kunden ist GESCHLOSSEN!'") + Chars.LF + 
						TrimAll(rCardRef.Room) + ?(ValueIsFilled(rCardRef.Client), ", " + TrimAll(rCardRef.Client.FullName), "") + ", " + 
						Format(rCardRef.DateTimeFrom, "DF='dd.MM.yy HH:mm'") + " - " + Format(rCardRef.DateTimeTo, "DF='dd.MM.yy HH:mm'");
						// Write safety event
						cmWriteSafetyEvent(rCardRef.Hotel, "ServiceRegistration", CurrentSessionDate(), rCardRef.Room, "ClientIdentificationCard", TrimAll(rCardRef.Identifier), rCardRef.ParentDoc, rCardRef.Client, TMessage, rCardRef.DateTimeFrom, rCardRef.DateTimeTo, 0);
					Else
						SelClient = rCardRef.Client;
						SelGuestGroup = rCardRef.GuestGroup;
						SelRoom = rCardRef.Room;
						If ValueIsFilled(rCardRef.Hotel) Then
							SelHotel = rCardRef.Hotel;
						EndIf;
						// Fill clients list based on form on open settings
						vResult = FillClientsList(False, rCardRef);
						// Do service registration
						If vResult Then
							vShowGuestList = ShowGuestList;
							// Check services found
							If Not vShowGuestList And ValueIsFilled(rCardType) Then
								vClientIsFound = False;
								For Each vRow In TableBoxClients Do
									If vRow.Client = rCardRef.Client Then
										If ValueIsFilled(rCardType.ServiceGroup) And cmIsServiceInServiceGroup(vRow.Service, rCardType.ServiceGroup) Then
											vClientIsFound = True;
											Break;
										EndIf;
									EndIf;
								EndDo;
								If Not vClientIsFound Then
									vAllowedServiceWasFound = False;
									For Each vRow In TableBoxClients Do
										If ValueIsFilled(rCardType.ServiceGroup) And cmIsServiceInServiceGroup(vRow.Service, rCardType.ServiceGroup) Then
											vAllowedServiceWasFound = True;
											Break;
										EndIf;
									EndDo;
									If Not vAllowedServiceWasFound Then
										vShowGuestList = True;
									EndIf;
								EndIf;
							EndIf;
							// Process services found
							If Not vShowGuestList Then
								If TableBoxClients.Count() > 0 Then
									If ValueIsFilled(rCardType) And rCardType.IsIndividual Then
										// Try to find guest by name on card
										vRow = Undefined;
										vClientIsFound = False;
										For Each vRow In TableBoxClients Do
											If ValueIsFilled(vRow.Service) And vRow.Service.IsInPrice Then
												If vRow.Client = rCardRef.Client Then
													If ValueIsFilled(rCardType.ServiceGroup) And cmIsServiceInServiceGroup(vRow.Service, rCardType.ServiceGroup) Then
														vClientIsFound = True;
														Break;
													EndIf;
												EndIf;
											EndIf;
										EndDo;
										If Not vClientIsFound Then
											vRow = Undefined;
											For Each vRow In TableBoxClients Do
												If vRow.Client = rCardRef.Client Then
													If ValueIsFilled(rCardType.ServiceGroup) And cmIsServiceInServiceGroup(vRow.Service, rCardType.ServiceGroup) Then
														vClientIsFound = True;
														Break;
													EndIf;
												EndIf;
											EndDo;
										EndIf;
										If Not vClientIsFound Then
											vRow = Undefined;
										EndIf;
									Else
										// Try to find guest by name on card
										vRow = Undefined;
										vClientIsFound = False;
										For Each vRow In TableBoxClients Do
											If ValueIsFilled(vRow.Service) And vRow.Service.IsInPrice Then
												If vRow.Client = rCardRef.Client Then
													If Not ValueIsFilled(rCardType) Or ValueIsFilled(rCardType) And ValueIsFilled(rCardType.ServiceGroup) And cmIsServiceInServiceGroup(vRow.Service, rCardType.ServiceGroup) Then
														vClientIsFound = True;
														Break;
													EndIf;
												EndIf;
											EndIf;
										EndDo;
										If Not vClientIsFound Then
											vRow = Undefined;
											For Each vRow In TableBoxClients Do
												If ValueIsFilled(vRow.Service) And vRow.Service.IsInPrice Then
													If Not ValueIsFilled(rCardType) Or ValueIsFilled(rCardType) And ValueIsFilled(rCardType.ServiceGroup) And cmIsServiceInServiceGroup(vRow.Service, rCardType.ServiceGroup) Then
														vClientIsFound = True;
														Break;
													EndIf;
												EndIf;
											EndDo;
										EndIf;
										If Not vClientIsFound Then
											vRow = Undefined;
											For Each vRow In TableBoxClients Do
												If vRow.Client = rCardRef.Client Then
													If Not ValueIsFilled(rCardType) Or ValueIsFilled(rCardType) And ValueIsFilled(rCardType.ServiceGroup) And cmIsServiceInServiceGroup(vRow.Service, rCardType.ServiceGroup) Then
														vClientIsFound = True;
														Break;
													EndIf;
												EndIf;
											EndDo;
										EndIf;
										If Not vClientIsFound Then
											vRow = Undefined;
											vAllowedServiceWasFound = False;
											For Each vRow In TableBoxClients Do
												If Not ValueIsFilled(rCardType) Or ValueIsFilled(rCardType) And ValueIsFilled(rCardType.ServiceGroup) And cmIsServiceInServiceGroup(vRow.Service, rCardType.ServiceGroup) Then
													vAllowedServiceWasFound = True;
													Break;
												EndIf;
											EndDo;
											If Not vAllowedServiceWasFound Then
												vRow = Undefined;
											EndIf;
										EndIf;
									EndIf;
									If vRow <> Undefined Then
										// Register service
										vServiceWasRegistered = DoServiceRegistration(vRow);
									Else
										// Show error message
										Items.TMessage.BackColor = WebColors.DarkBlue;
										Items.TMessage.TextColor = WebColors.White;
										TMessage = NStr("en='Client does not have services prepaid!';
										|ru='У клиента нет начисленных услуг! Можете начислить услугу, принять за неё оплату и зарегистрировать её.';
										|de='Bei dem Kunden gibt es keine berechneten Dienstleistungen!'") + 
										Chars.LF + 
										TrimAll(rCardRef.Room) + ?(ValueIsFilled(rCardRef.Client), ", " + TrimAll(rCardRef.Client.FullName), "") + ", " + 
										Format(rCardRef.DateTimeFrom, "DF='dd.MM.yy HH:mm'") + " - " + Format(rCardRef.DateTimeTo, "DF='dd.MM.yy HH:mm'");
										// Write safety event
										cmWriteSafetyEvent(rCardRef.Hotel, "ServiceRegistration", CurrentSessionDate(), rCardRef.Room, "ClientIdentificationCard", TrimAll(rCardRef.Identifier), rCardRef.ParentDoc, rCardRef.Client, TMessage, rCardRef.DateTimeFrom, rCardRef.DateTimeTo, 0);
									EndIf;
								Else
									// Show error message
									Items.TMessage.BackColor = WebColors.Yellow;
									Items.TMessage.TextColor = Items.SelService.TextColor;
									TMessage = NStr("en='No guests in room!';ru='В номере нет зарегистрированных гостей!';de='Das Zimmer hat keine registrierte Gäste!'") + Chars.LF + 
									TrimAll(rCardRef.Room) + ?(ValueIsFilled(rCardRef.Client), ", " + TrimAll(rCardRef.Client.FullName), "") + ", " + 
									Format(rCardRef.DateTimeFrom, "DF='dd.MM.yy HH:mm'") + " - " + Format(rCardRef.DateTimeTo, "DF='dd.MM.yy HH:mm'");
									// Write safety event
									cmWriteSafetyEvent(rCardRef.Hotel, "ServiceRegistration", CurrentSessionDate(), rCardRef.Room, "ClientIdentificationCard", TrimAll(rCardRef.Identifier), rCardRef.ParentDoc, rCardRef.Client, TMessage, rCardRef.DateTimeFrom, rCardRef.DateTimeTo, 0);
								EndIf;
							Else
								If Items.PanelMode.CurrentPage <> Items.PageGuests Then
									Items.PanelMode.CurrentPage = Items.PageGuests;
								EndIf;
								Items.TMessage.BackColor = StyleColors.FormBackColor;
								Items.TMessage.TextColor = StyleColors.FormTextColor;
								If TableBoxClients.Count() > 0 Then
									ThisForm.CurrentItem = Items.TableBoxClients;
								EndIf;
								Return vServiceWasRegistered;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			Else
				SelRoom = rCardRef.Room;
				Items.TMessage.BackColor = WebColors.Red;
				Items.TMessage.TextColor = WebColors.White;
				Items.SelClient.BackColor = WebColors.Red;
				Items.SelRoom.BackColor = WebColors.Red;
				Items.SelResource.BackColor = WebColors.Red;
				Items.SelCard.BackColor = WebColors.Red;
				TMessage = NStr("en='Card is BLOCKED! ';ru='Карта ЗАБЛОКИРОВАНА! ';de='Die Karte ist BLOCKIERT! '") + 
				TrimAll(rCardRef.BlockReason) + Chars.LF + 
				TrimAll(rCardRef.Room) + ?(ValueIsFilled(rCardRef.Client), ", " + TrimAll(rCardRef.Client.FullName), "") + ", " + 
				Format(rCardRef.DateTimeFrom, "DF='dd.MM.yy HH:mm'") + " - " + Format(rCardRef.DateTimeTo, "DF='dd.MM.yy HH:mm'");
				// Write safety event
				cmWriteSafetyEvent(rCardRef.Hotel, "ServiceRegistration", CurrentSessionDate(), rCardRef.Room, "ClientIdentificationCard", TrimAll(rCardRef.Identifier), rCardRef.ParentDoc, rCardRef.Client, TMessage, rCardRef.DateTimeFrom, rCardRef.DateTimeTo, 0);
			EndIf;
		Else
			// Fill error text
			Items. TMessage.BackColor = WebColors.Yellow;
			Items.TMessage.TextColor = Items.SelService.TextColor;
			TMessage = NStr("en='Unregistered card!'; ru='Незарегистрированная карта!'; de='Unregistriert Karte!'");
			// Write safety event
			cmWriteSafetyEvent(SelHotel, "ServiceRegistration", CurrentSessionDate(), Undefined, "ClientIdentificationCard", TrimAll(SelCard), Undefined, Undefined, TMessage, , , 0);
		EndIf;
	Else
		// Reset colors
		Items.SelCard.BackColor = Items.SelRoom.BackColor;
		// Reset password mode
		Items.SelCard.PasswordMode = False;
	EndIf;	
	// Hide clients list
	If Not ShowGuestList Then
		If Items.PanelMode.CurrentPage <> Items.PageProgress Then
			Items.PanelMode.CurrentPage = Items.PageProgress;
		EndIf;
	EndIf;
	Return vServiceWasRegistered;
EndFunction // CardOnChange

// -----------------------------------------------------------------------------
&AtServer
Function DoServiceRegistration(pRows, pButtonRegisterCheck = False)
	vServiceWasRegistered = False;
	
	If TypeOf(pRows) <> Type("FormDataCollectionItem") And TypeOf(pRows) <> Type("Structure") Then
		vRow = TableBoxClients.FindByID(pRows);
	Else
		vRow = pRows;
	EndIf;
	CurClient = vRow.Client;
	// Fill available resources
	AvailableQuantity = vRow.AvailableQuantity;
	AvailableSum = vRow.AvailableSum;
	// Check all attributes first
	If Not ValueIsFilled(vRow.Service) Then
		// Fill error text
		Items.TMessage.BackColor = WebColors.DarkBlue;
		Items.TMessage.TextColor = WebColors.White;
		TMessage = NStr("en='Please choose service!';ru='Не выбрана услуга!';de='Keine Dienstleistung ist gewählt!'");
		// Write safety event
		cmWriteSafetyEvent(SelHotel, "ServiceRegistration", CurrentSessionDate(), SelRoom, "ClientIdentificationCard", TrimAll(SelCard), , CurClient, TMessage, , , 0);
		// Activate control in error
		ThisForm.CurrentItem = Items.SelService;
		Return vServiceWasRegistered;
	ElsIf Not ValueIsFilled(SelRoom) And Not ValueIsFilled(SelResource) And Not ValueIsFilled(SelClient) Then
		// Fill error text
		Items.TMessage.BackColor = WebColors.DarkBlue;
		Items.TMessage.TextColor = WebColors.White;
		TMessage = NStr("en='Please choose room, resource, client or card!';ru='Выберите номер, ресурс, клиента или карту!';de='Wählen Sie das Zimmer, die Ressource, die Kunde oder die Card!'");
		// Write safety event
		cmWriteSafetyEvent(SelHotel, "ServiceRegistration", CurrentSessionDate(), SelRoom, "ClientIdentificationCard", TrimAll(SelCard), , CurClient, TMessage, , , 0);
		// Activate control in error
		ThisForm.CurrentItem = Items.SelRoom;
		Return vServiceWasRegistered;
	ElsIf Not ValueIsFilled(CurClient) And IsBlankString(SelCard) Then
		// Fill error text
		Items.TMessage.BackColor = WebColors.DarkBlue;
		Items.TMessage.TextColor = WebColors.White;
		TMessage = NStr("en='Please choose client!';ru='Не выбран клиент!';de='Kein Kunde ist gewählt!'");
		// Write safety event
		cmWriteSafetyEvent(SelHotel, "ServiceRegistration", CurrentSessionDate(), SelRoom, "ClientIdentificationCard", TrimAll(SelCard), , CurClient, TMessage, , , 0);
		// Activate control in error
		ThisForm.CurrentItem = Items.SelClient;
		Return vServiceWasRegistered;
	ElsIf SelQuantity = 0 Then
		// Fill error text
		Items.TMessage.BackColor = WebColors.DarkBlue;
		Items.TMessage.TextColor = WebColors.White;
		TMessage = NStr("en='Please choose quantity!';ru='Не выбрано количество!';de='Keine Anzahl ist gewählt!'");
		// Write safety event
		cmWriteSafetyEvent(SelHotel, "ServiceRegistration", CurrentSessionDate(), SelRoom, "ClientIdentificationCard", TrimAll(SelCard), , CurClient, TMessage, , , 0);
		// Activate control in error
		ThisForm.CurrentItem = Items.SelQuantity;
		Return vServiceWasRegistered;
	ElsIf SelQuantity > AvailableQuantity Then
		// Fill error text
		Items.TMessage.BackColor = WebColors.DarkBlue;
		Items.TMessage.TextColor = WebColors.White;
		TMessage = NStr("en='Quantity choosen is greater then quantity available!';ru='Выбранное количество больше доступного!';de='Die ausgewählte Menge ist größer als die verfügbare!'");
		// Write safety event
		cmWriteSafetyEvent(SelHotel, "ServiceRegistration", CurrentSessionDate(), SelRoom, "ClientIdentificationCard", TrimAll(SelCard), , CurClient, TMessage, , , 0);
		// Activate control in error
		ThisForm.CurrentItem = Items.SelQuantity;
		Return vServiceWasRegistered;
	EndIf;
	// Create and post new document
	vSRObj = Documents.ServiceRegistration.CreateDocument();
	vSRObj.SetTime(AutoTimeMode.CurrentOrLast);
	vSRObj.Hotel = SelHotel;
	vSRObj.pmFillAttributesWithDefaultValues();
	vSRObj.AccountingDate = BegOfDay(SelPeriod);
	vSRObj.BoardPlace = SelBoardPlace;
	vSRObj.IdentificationCard = CurrentCard;
	vSRObj.Service = vRow.Service;
	vSRObj.Client = vRow.Client;
	vSRObj.ClientType = SelClientType;
	vSRObj.GuestGroup = vRow.GuestGroup;
	vSRObj.Folio = vRow.Folio;
	vSRObj.FolioCurrency = vRow.Folio.FolioCurrency;
	vSRObj.ParentDoc = vSRObj.Folio.ParentDoc;
	vSRObj.Quantity = SelQuantity;
	vSRObj.Unit = vSRObj.Service.Unit;
	vSRObj.Room = vRow.Room;
	vSRObj.Resource = vRow.Resource;
	vSRObj.Price = Round(AvailableSum/AvailableQuantity, 2);
	vSRObj.Sum = vSRObj.Price * SelQuantity;
	// Post document
	Try
		vSRObj.Write(DocumentWriteMode.Posting);
		// Fill message text
		Items.TMessage.BackColor = Items.SelService.BackColor;
		Items.TMessage.TextColor = Items.SelService.TextColor;
		TMessage = "" + vSRObj.Service + " " + vSRObj.Quantity + " x " + cmFormatSum(vSRObj.Price, vSRObj.FolioCurrency, "NZ=") + ", " + vSRObj.Room + ?(ValueIsFilled(vSRObj.Client), ", " + vSRObj.Client.FullName, "") + ?(ValueIsFilled(vSRObj.Folio), ?(ValueIsFilled(vSRObj.Folio.Customer), ", " + TrimAll(vSRObj.Folio.Customer), ""), "");
		// Subtract quantity
		vRow.AvailableQuantity = vRow.AvailableQuantity - SelQuantity;
		// Guests processed
		RestoreTotals();
		vServiceWasRegistered = True;
	Except
		vErrorInfo = ErrorInfo();
		// Fill error text
		Items.TMessage.BackColor = WebColors.DarkBlue;
		Items.TMessage.TextColor = WebColors.White;
		TMessage = "" + vRow.Room + ?(ValueIsFilled(vRow.Client), ", " + vRow.Client.FullName, "") + ?(ValueIsFilled(vRow.Folio), ?(ValueIsFilled(vRow.Folio.Customer), ", " + TrimAll(vRow.Folio.Customer), ""), "") + " - " + cmGetRootErrorDescription(vErrorInfo);
		// Write safety event
		cmWriteSafetyEvent(SelHotel, "ServiceRegistration", CurrentSessionDate(), SelRoom, "ClientIdentificationCard", TrimAll(SelCard), , CurClient, TMessage, , , 0);
	EndTry;
	// Set focus to form
	If ShowGuestList Then
		If TableBoxClients.Count() > 0 Then
			ThisForm.CurrentItem = Items.TableBoxClients;
		Else
			ThisForm.CurrentItem = Items.SelRoom;
		EndIf;
	Else
		ThisForm.CurrentItem = Items.SelRoom;
	EndIf;
	If pButtonRegisterCheck Then
		vResult = FillClientsList();
		If vResult Then
			TMessage = "" + vSRObj.Service + " " + vSRObj.Quantity + " x " + cmFormatSum(vSRObj.Price, vSRObj.FolioCurrency, "NZ=") + ", " + vSRObj.Room + ?(ValueIsFilled(vSRObj.Client), ", " + vSRObj.Client.FullName, "") + ?(ValueIsFilled(vSRObj.Folio), ?(ValueIsFilled(vSRObj.Folio.Customer), ", " + TrimAll(vSRObj.Folio.Customer), ""), "");
		EndIf;
	EndIf;
	Return vServiceWasRegistered;
EndFunction // DoServiceRegistration

// -----------------------------------------------------------------------------
&AtServer
Function DoSpecialServiceRegistration(pService, pCardRef = Undefined)
	vServiceWasRegistered = False;
	// Fill current card
	If ValueIsFilled(pCardRef) Then
		CurrentCard = pCardRef;
	EndIf;
	// Fill current client
	CurClient = Catalogs.Clients.EmptyRef();
	If ValueIsFilled(CurrentCard) Then
		CurClient = CurrentCard.Client;
	EndIf;
	// Check all attributes first
	If Not ValueIsFilled(pService) Then
		// Fill error text
		Items.TMessage.BackColor = WebColors.DarkBlue;
		Items.TMessage.TextColor = WebColors.White;
		TMessage = NStr("en='Please choose service!';ru='Не выбрана услуга!';de='Keine Dienstleistung ist gewählt!'");
		// Write safety event
		cmWriteSafetyEvent(SelHotel, "ServiceRegistration", CurrentSessionDate(), SelRoom, "ClientIdentificationCard", TrimAll(SelCard), , CurClient, TMessage, , , 0);
		// Activate control in error
		ThisForm.CurrentItem = Items.SelService;
		Return vServiceWasRegistered;
	ElsIf SelQuantity = 0 Then
		// Fill error text
		Items.TMessage.BackColor = WebColors.DarkBlue;
		Items.TMessage.TextColor = WebColors.White;
		TMessage = NStr("en='Please choose quantity!';ru='Не выбрано количество!';de='Keine Anzahl ist gewählt!'");
		// Write safety event                     
		cmWriteSafetyEvent(SelHotel, "ServiceRegistration", CurrentSessionDate(), SelRoom, "ClientIdentificationCard", TrimAll(SelCard), , CurClient, TMessage, , , 0);
		// Activate control in error
		ThisForm.CurrentItem = Items.SelQuantity;
		Return vServiceWasRegistered;
	EndIf;
	// Create and post new document
	vSRObj = Documents.ServiceRegistration.CreateDocument();
	vSRObj.SetTime(AutoTimeMode.CurrentOrLast);
	vSRObj.Hotel = SelHotel;
	vSRObj.pmFillAttributesWithDefaultValues();
	vSRObj.AccountingDate = BegOfDay(SelPeriod);
	vSRObj.BoardPlace = SelBoardPlace;
	vSRObj.Service = pService;
	If ValueIsFilled(pCardRef) Then
		vSRObj.IdentificationCard = CurrentCard;
		vSRObj.Client = pCardRef.Client;
		vSRObj.ClientType = ?(ValueIsFilled(pCardRef.Client), pCardRef.Client.ClientType, Undefined);
		vSRObj.GuestGroup = pCardRef.GuestGroup;
		vSRObj.Folio = pCardRef.Folio;
		vSRObj.FolioCurrency = ?(ValueIsFilled(pCardRef.Folio), pCardRef.Folio.FolioCurrency, vSRObj.Hotel.BaseCurrency);
		vSRObj.Room = pCardRef.Room;
	Else
		If ValueIsFilled(SelFolio) Then
			vSRObj.IdentificationCard = Undefined;
			vSRObj.Client = SelFolio.Client;
			vSRObj.ClientType = ?(ValueIsFilled(SelFolio.Client), SelFolio.Client.ClientType, Undefined);
			vSRObj.GuestGroup = SelFolio.GuestGroup;
			vSRObj.Folio = SelFolio;
			vSRObj.FolioCurrency = SelFolio.FolioCurrency;
			vSRObj.Room = SelFolio.Room;
		Else
			// Fill error text
			Items.TMessage.BackColor = WebColors.DarkBlue;
			Items.TMessage.TextColor = WebColors.White;
			TMessage = NStr("en='Please specify kiosk folio in the workstation settings!';ru='В настройках рабочего места не указано фолио киоска!';de='Bitte geben Sie Kiosk folio in den Workstation-Einstellungen!'");
			// Write safety event
			cmWriteSafetyEvent(SelHotel, "ServiceRegistration", CurrentSessionDate(), SelRoom, "ClientIdentificationCard", TrimAll(SelCard), , CurClient, TMessage, , , 0);
			// Activate control in error
			ThisForm.CurrentItem = Items.SelService;
			Return vServiceWasRegistered;
		EndIf;
	EndIf;
	vSRObj.ParentDoc = vSRObj.Folio.ParentDoc;
	vSRObj.Unit = vSRObj.Service.Unit;
	vSRObj.Quantity = SelQuantity;
	vSRObj.Resource = Undefined;
	vSRObj.Price = 0;
	vSRObj.Sum = 0;
	// Post document
	Try
		vSRObj.Write(DocumentWriteMode.Posting);
		// Fill message text
		Items.TMessage.BackColor = Items.SelService.BackColor;
		Items.TMessage.TextColor = Items.SelService.TextColor;
		TMessage = "" + pService + " " + SelQuantity + " x " + cmFormatSum(vSRObj.Price, vSRObj.FolioCurrency, "NZ=") + ", " + vSRObj.Room + ?(ValueIsFilled(vSRObj.Client), ", " + vSRObj.Client.FullName, "") + ?(ValueIsFilled(vSRObj.Folio), ?(ValueIsFilled(vSRObj.Folio.Customer), ", " + TrimAll(vSRObj.Folio.Customer), ""), "");
		// Guests processed
		RestoreTotals();
		vServiceWasRegistered = True;
	Except
		vErrorInfo = ErrorInfo();
		// Fill error text
		Items.TMessage.BackColor = WebColors.DarkBlue;
		Items.TMessage.TextColor = WebColors.White;
		TMessage = cmGetRootErrorDescription(vErrorInfo);
		// Write safety event
		cmWriteSafetyEvent(SelHotel, "ServiceRegistration", CurrentSessionDate(), SelRoom, "ClientIdentificationCard", TrimAll(SelCard), , CurClient, TMessage, , , 0);
	EndTry;
	vResult = FillClientsList();
	Return vServiceWasRegistered;
EndFunction // DoSpecialServiceRegistration

// -----------------------------------------------------------------------------
&AtServer
Procedure SelResourceOnChangeAtServer()
	TimeCounterForCleansing = 0;
	// Reset form	
	SelCard = "";
	SelClient = Catalogs.Clients.EmptyRef();
	SelGuestGroup = Catalogs.GuestGroups.EmptyRef();
	CurRoom = Catalogs.Rooms.EmptyRef();
	CurResource = Catalogs.Resources.EmptyRef();
	CurClient = Catalogs.Clients.EmptyRef();
	CurGuestGroup = Catalogs.GuestGroups.EmptyRef();
	CurFolio = Documents.Folio.EmptyRef();
	CurFolioCurrency = Catalogs.Currencies.EmptyRef();
	AvailableQuantity = 0;
	AvailableSum = 0;
	// Reset current card
	CurrentCard = Undefined;
	// Reset colors
	Items.SelCard.BackColor = Items.SelService.BackColor;
	Items.SelClient.BackColor = Items.SelService.BackColor;
	Items.SelRoom.BackColor = Items.SelService.BackColor;
	Items.SelResource.BackColor = Items.SelService.BackColor;
	// Reset message
	Items.TMessage.BackColor = StyleColors.FormBackColor;
	Items.TMessage.TextColor = StyleColors.FormTextColor;
	// Fill clients list based on curent form settings
	If Items.PanelMode.CurrentPage <> Items.PageGuests Then
		Items.PanelMode.CurrentPage = Items.PageGuests;
	EndIf;
	vResult = FillClientsList();
EndProcedure // SelResourceOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure AddQuantityAtServer()
	SelQuantity = SelQuantity + 1;
EndProcedure // AddQuantityAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ReduceQuantityAtServer()
	SelQuantity = SelQuantity - 1;
EndProcedure // ReduceQuantityAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ClearQuantityAtServer()
	SelQuantity = 1;
EndProcedure // ClearQuantityAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ExternalEventQuery(pSelFolio)
	// Check if service was already registered
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ServiceRegistrationBalance.Client AS Client,
	|	ServiceRegistrationBalance.GuestGroup AS GuestGroup,
	|	ServiceRegistrationBalance.Room AS Room,
	|	ServiceRegistrationBalance.Resource AS Resource,
	|	ServiceRegistrationBalance.Folio AS Folio,
	|	ServiceRegistrationBalance.FolioCurrency AS FolioCurrency,
	|	ServiceRegistrationBalance.QuantityBalance AS AvailableQuantity,
	|	ServiceRegistrationBalance.SumBalance AS AvailableSum,
	|	ServiceRegistrationBalance.Service AS Service
	|FROM
	|	AccumulationRegister.ServiceRegistration.Balance(
	|			&qPeriod,
	|			Client = &qClient
	|				AND Folio = &qFolio
	|				AND GuestGroup = &qGuestGroup
	|				AND Hotel = &qHotel
	|				AND BoardPlace = &qBoardPlace
	|				AND Resource = &qResource
	|				AND Room = &qRoom
	|				AND Service = &qService) AS ServiceRegistrationBalance";
	vQry.SetParameter("qPeriod", ?(ValueIsFilled(SelPeriod), EndOfDay(SelPeriod), '00010101'));
	vQry.SetParameter("qClient", SelClient);
	vQry.SetParameter("qFolio", pSelFolio);
	vQry.SetParameter("qGuestGroup", SelGuestGroup);
	vQry.SetParameter("qHotel", SelHotel);
	vQry.SetParameter("qBoardPlace", SelBoardPlace);
	vQry.SetParameter("qResource", SelResource);
	vQry.SetParameter("qRoom", SelRoom);
	vQry.SetParameter("qService", SelService);
	vTableBoxClients = vQry.Execute().Unload();
	vTableBoxClients.Columns.Add("AccommodationType", cmGetCatalogTypeDescription("AccommodationTypes"));
	vTableBoxClients.Columns.Add("AccommodationTypeSortCode", cmGetNumberTypeDescription(4, 0));
	vTableBoxClients.Columns.Add("ServicePackage", cmGetCatalogTypeDescription("ServicePackages"));
	For Each vTableBoxClientsRow In vTableBoxClients Do
		vClientExtraParams = GetClientExtraParameters(vTableBoxClientsRow.Service, vTableBoxClientsRow.Room, vTableBoxClientsRow.Client);
		FillPropertyValues(vTableBoxClientsRow, vClientExtraParams);
		vCurAccType = vTableBoxClientsRow.AccommodationType;
		If vTableBoxClientsRow.Age = 0 And ValueIsFilled(vCurAccType) And vCurAccType.AllowedClientAgeTo > 0 Then
			vTableBoxClientsRow.Age = vCurAccType.AllowedClientAgeTo - 1;
		EndIf;
		If ValueIsFilled(vCurAccType) Then
			vTableBoxClientsRow.AccommodationTypeSortCode = vCurAccType.SortCode;
		EndIf;
	EndDo;
	vTableBoxClients.Sort("AccommodationTypeSortCode");
	TableBoxClients.Load(vTableBoxClients);
EndProcedure // ExternalEventQuery

// -----------------------------------------------------------------------------
&AtServer
Procedure CallcmWriteSafetyEvent(pEventType, pCardType)
	cmWriteSafetyEvent(SelHotel, pEventType,  CurrentSessionDate(), SelRoom, pCardType, TrimAll(SelCard), , SelClient, TMessage, , , 0);
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function CallcmParseCouponBarCode(pScanData)
	Return cmParseCouponBarCode(pScanData, SelHotel);
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Procedure ButtonRegisterAtServer()
	// Register service
	vCurRow = Items.TableBoxClients.CurrentRow;
	If vCurRow <> Undefined Then
		vDoSpecialRegistration = False;
		If Not IsBlankString(SelCard) And ValueIsFilled(SelService) Then
			rCardRef = cmGetClientIdentificationCardById(cmGetCardIdentifier(SelCard));
			If ValueIsFilled(rCardRef) Then
				rCardType = rCardRef.IdentificationCardType;
				If Not rCardRef.IsBlocked Then
					If ValueIsFilled(rCardType) And rCardType.DoServiceRegistrationWithoutChargesControl Then
						SelRoom = rCardRef.Room;
						SelResource = Undefined;
						SelClient = rCardRef.Client;
						vDoSpecialRegistration = True;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		
		If vDoSpecialRegistration Then
			// Register special service
			DoSpecialServiceRegistration(SelExtraService, rCardRef);
		Else
			DoServiceRegistration(vCurRow, True);
		EndIf;
	EndIf;
EndProcedure // ButtonRegisterAtServer

// -----------------------------------------------------------------------------
&AtServer
Function QueryDocument()
	vQry = New Query();
	If ValueIsFilled(SelClient) Then
		vQry.Text = 
		"SELECT
		|	Accommodation.Ref AS Ref
		|FROM
		|	Document.Accommodation AS Accommodation
		|WHERE
		|	NOT Accommodation.DeletionMark
		|	AND Accommodation.Hotel = &qHotel
		|	AND Accommodation.CheckInDate <= &qDate
		|	AND Accommodation.CheckOutDate >= &qDate
		|	AND Accommodation.Guest = &qGuest";
		vQry.SetParameter("qDate", CurrentSessionDate());
		vQry.SetParameter("qGuest", SelClient);
		vQry.SetParameter("qHotel", SelHotel);
	ElsIf ValueIsFilled(SelRoom) Then
		vQry.Text = 
		"SELECT
		|	Accommodation.Ref AS Ref
		|FROM
		|	Document.Accommodation AS Accommodation
		|WHERE
		|	NOT Accommodation.DeletionMark
		|	AND Accommodation.Room = &qRoom
		|	AND Accommodation.Hotel = &qHotel
		|	AND Accommodation.CheckInDate <= &qDate
		|	AND Accommodation.CheckOutDate >= &qDate";
		vQry.SetParameter("qDate", CurrentSessionDate());
		vQry.SetParameter("qRoom", SelRoom);
		vQry.SetParameter("qHotel", SelHotel);
	EndIf;
	vResult = vQry.Execute().Unload();
	If vResult.Count() > 0 Then
		Return vResult[0].Ref;
	Else
		Return Undefined;
	EndIf;
EndFunction // QueryDocument

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure CancelServiceRegistrationAtServer(pServiceRegistration)
	pServiceRegistration.GetObject().SetDeletionMark(True);
EndProcedure // CancelServiceRegistrationAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function CheckAccommodationByRoom(pRoom)
	vQ = New Query;
	vQ.Text =
	"SELECT
	|	Accommodation.Ref AS Ref
	|FROM
	|	Document.Accommodation AS Accommodation
	|		INNER JOIN Catalog.AccommodationStatuses AS AccommodationStatuses
	|		ON Accommodation.AccommodationStatus = AccommodationStatuses.Ref
	|			AND (AccommodationStatuses.IsActive)
	|			AND (AccommodationStatuses.IsInHouse)
	|WHERE
	|	Accommodation.Posted
	|	AND Accommodation.Room = &qRoom";
	vQ.SetParameter("qRoom", pRoom);
	Return Not vQ.Execute().IsEmpty();
EndFunction // CheckAccommodationByRoom

#EndRegion
