#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	SystemSettingsStorage.Save("Document.Reservation.Form.tcReservationListForm", "FirstDocInBatch", Undefined);
	SystemSettingsStorage.Save("Document.Reservation.Form.tcReservationListForm", "LastDocInBatch", Undefined);
	// Load parameters
	SelDate = '00010101';	
	If Parameters.Property("SelDocPeriod") Then
		SelDate = Parameters.SelDocPeriod;
	EndIf;
	If Parameters.Property("SelAuthor") Then
		SelAuthor = Parameters.SelAuthor;
	EndIf;
	If Parameters.Property("SelClient") Then
		SelClient = Parameters.SelClient;
	EndIf;
	If Parameters.Property("SelCustomer") Then
		SelCustomer = Parameters.SelCustomer;
	EndIf;
	If Parameters.Property("SelContract") Then
		SelContract = Parameters.SelContract;
	EndIf;
	If Parameters.Property("SelRoomType") Then
		SelRoomType = Parameters.SelRoomType;
	EndIf;
	If Parameters.Property("SelAllotment") Then
		SelAllotment = Parameters.SelAllotment;
	EndIf;
	If Parameters.Property("SelRoomRate") Then
		SelRoomRate = Parameters.SelRoomRate;
	EndIf;
	If Parameters.Property("SelBedsSetup") Then
		SelBedsSetup = Parameters.SelBedsSetup;
	EndIf;
	SelHotel = SessionParameters.CurrentHotel;
	// Fill filter attributes by form parameters
	SelListMode = 0;
	SelShowAllGuests = 0;
	vShowExpectedCheckInListByGuestsByDefault = cmCheckUserPermissions("ShowExpectedCheckInListByGuestsByDefault");
	If vShowExpectedCheckInListByGuestsByDefault Then
		SelShowAllGuests = 1;
	EndIf;
	SelFilterStatus = "&ACTIVE";
	SelReservationStatus = "&ACTIVE";
	If Parameters.Property("SelFilterStatus") Then
		SelFilterStatus = Parameters.SelFilterStatus;
		SelReservationStatus = Parameters.SelFilterStatus;
	EndIf;   
	If Parameters.Property("SelRoom") Then
		SelRoom = Parameters.SelRoom;
	EndIf;
	ListModes.Clear();
	ListModes.Add(0, NStr("en='Check-in date'; ru='Дата заезда'; de='Anreise Datum'") + "...", , GetListModeIconAtServer(0));
	ListModes.Add(1, NStr("en='Stay date'; ru='Дата пребывания'; de='Aufenthalt Datum'") + "...", , GetListModeIconAtServer(1));
	ListModes.Add(2, NStr("en='Check-out date'; ru='Дата выезда'; de='Abreise Datum'") + "...", , GetListModeIconAtServer(2));
	ListModes.Add(3, NStr("en='Create date'; ru='Дата создания'; de='Erstellen Datum'") + "...", , GetListModeIconAtServer(3));
	ListModes.Add(4, NStr("en='Edit date'; ru='Дата изменения'; de='Ändern Datum'") + "...", , GetListModeIconAtServer(4));
	If ValueIsFilled(SelHotel) And SelHotel.ShowReservationStatusLastChangeDate Then
		ListModes.Add(5, NStr("en='Change status date'; ru='Дата изменения статуса'; de='Datum der Statusänderung'") + "...", , GetListModeIconAtServer(5));
	Else
		Items.DocumentListReservationStatusSetTime.Visible = False;
	EndIf;
	// Fill list of reservation statuses
	FillFilterStatuses();
	// Check user settings
	If ValueIsFilled(SessionParameters.CurrentUser) Then
		vCurUser = SessionParameters.CurrentUser;
		If ValueIsFilled(vCurUser.Customer) Then
			SelCustomer = vCurUser.Customer;
			Items.SelCustomer.ReadOnly = True;
			Items.SelCustomer.ChoiceButton = False;
			Items.SelCustomer.ClearButton = False;
			Items.SelCustomer.OpenButton = False;
		EndIf;
		If ValueIsFilled(vCurUser.RoomType) Then
			SelRoomType = vCurUser.RoomType;
		EndIf;
	EndIf;
	// Filter by guest group
	If Parameters.Property("SelGuestGroup") Then
		SelGuestGroup = Parameters.SelGuestGroup;
		If ValueIsFilled(SelGuestGroup) Then
			If SelGuestGroup.Owner <> SelHotel Then
				SelHotel = SelGuestGroup.Owner;
			EndIf;
			SelDate = '00010101';
		EndIf;
	EndIf;
	// Set choice mode
	If Parameters.Property("ChoiceMode") Then
		If Parameters.ChoiceMode Then
			Items.ReservList.ChoiceMode = True;
		EndIf;
	EndIf;
	// Apply filter parameters
	SetDynamicListParametersAtServer();
	// Scans availability
	vScansObjectFormAction = Catalogs.ObjectFormActions.AccommodationScanClientData;
	If vScansObjectFormAction.DeletionMark Or Not vScansObjectFormAction.IsActive Then
		Items.ScanDocuments.Visible = False;
		Items.ScanDocuments1.Visible = False;
	EndIf;
	Items.SelDateTo.Visible = False;
	SelInPeriod = False;
	// Fill functions
	FillFunctionsButton();
	// Fill printing forms
	FillPrintingButton();
	// Check vauchers functional option
	CheckVauchersFunctionalOption();
	// Check beds setups functional option
	CheckBedsSetupsFunctionalOption();
	// Check if hotel can be changed
	If Not IsInRole("RightsToChooseHotel") Then
		Items.SelHotel.ReadOnly = True;
		Items.SelHotel.ChoiceButton = False;
		Items.SelHotel.ClearButton = False;
	Else
		vUser = SessionParameters.CurrentUser;
		If ValueIsFilled(vUser) And ValueIsFilled(vUser.PermissionGroup) And vUser.PermissionGroup.HotelAllowed.Count() > 0 Then
			Items.SelHotel.ChoiceFoldersAndItems = FoldersAndItems.Items;
		EndIf;
	EndIf;
	If Not ValueIsFilled(SelHotel) Or ValueIsFilled(SelHotel) And SelHotel.IsFolder Then
		Items.DocumentListHotel.Visible = True;
		Items.GroupHotel.BackColor = Items.GroupSearchMode.BackColor;
	Else
		Items.DocumentListHotel.Visible = False;
		// Set hotel color          
		Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
	EndIf;
	SkipOnRowActivateEvent = True;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	AttachIdleHandler("ReservListOnActivateRowIdleHandler", 0.5, True);
EndProcedure // OnOpen

// -----------------------------------------------------------------------------
&AtClient
Procedure OnReopen()
	OnReopenAtServer();
EndProcedure // OnReopen

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	vGuestGroup = ?(Items.ReservList.CurrentData = Undefined, Undefined, Items.ReservList.CurrentData.GuestGroup);
	If vGuestGroup <> CurGuestGroup Then
		CurGuestGroup = vGuestGroup;
	EndIf;
	If pEventName = "System.Hotel.Changed" And pParameter <> SelHotel Then
		SelHotel = pParameter;
		SelGuestGroup = Undefined;
		SelRoomType = Undefined;
		SelAllotment = Undefined;
		SelRoomRate = Undefined;
		SelRoom = Undefined;
		SetDynamicListParametersAtServer();
		SetGroupProformaInvoicesDynamicListParametersAtServer();
		UpdateTotalsByGroupAtServer();
		AttachIdleHandler("GetRefreshGroupTotalsJobResult", 1, True);
	ElsIf pEventName = "Document.Reservation.Write" Or 
	      pEventName = "Document.Reservation.WriteNew" Or 
		  pEventName = "Document.Accommodation.Write" Or 
		  pEventName = "Document.Accommodation.WriteNew" Or 
		  pEventName = "Document.Charge.Write" Or 
		  pEventName = "Document.Storno.Write" Or 
		  pEventName = "Document.Payment.Write" Or 
		  pEventName = "Document.Return.Write" Or 
		  pEventName = "Document.DepositTransfer.Write" Or 
		  pEventName = "Document.ChargeTransfer.Write" Or 
		  pEventName = "Subsystem.Accounts.Changed" Or
		  pEventName = "Catalog.GuestGroups.Changed" Then
		AttachIdleHandler("RefreshListAndTotals", 1, True);
	ElsIf pEventName = "GroupForMergeIsChoosen" Then
		If DocsToProcess.Count() > 0 Then
			If ValueIsFilled(pParameter) And TypeOf(pParameter) = Type("CatalogRef.GuestGroups") Then
				AfterGuestGroupToMergeSelection(pParameter);
			EndIf;
		EndIf;
	ElsIf pEventName = "CopyReservation.OptionsChoice" And pSource = ThisObject Then
		CopyReservationOptionsAfterChoice(pParameter);
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
	
	If vEventData.DeviceType = "MagneticStripeCardReader" Then
		// Try to find client identification card with such Id
		vCard = GetClientIdentificationCardById(vEventData.DeviceData);
		If ValueIsFilled(vCard) Then
			SelRoom = GetRoom(vCard);
			SelClient = GetClient(vCard);
			If ValueIsFilled(SelRoom) Then
				SelRoomOnChange(Items.SelRoom);
			ElsIf ValueIsFilled(SelClient) Then
				SelClientOnChange(Items.SelClient); 
			Else
				ShowMessageBox(, NStr("en='Card do not have room or client specified!';ru='У карты не указан ни номер комнаты ни клиент!';de='Bei der Karte sind weder Zimmernummer noch Kunde angegeben!'"), 3);
			EndIf;
		Else
			// Try to find discount card with such Id
			vDiscountCard = GetDiscountCardById(vEventData.DeviceData);
			If ValueIsFilled(vDiscountCard) Then
				SelClient = GetClient(vCard);					
				If ValueIsFilled(SelClient) Then
					SelClientOnChange(Items.SelClient);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ExternalEvent

#EndRegion

// -----------------------------------------------------------------------------
&AtServer
Function GetListModeIconAtServer(pListMode)
	vPicture = PictureLib.Empty;
	If pListMode = 0 Then
		vPicture = PictureLib.CheckIn;
	ElsIf pListMode = 1 Then
		vPicture = PictureLib.PeriodDay;
	ElsIf pListMode = 2 Then
		vPicture = PictureLib.CheckOut;
	ElsIf pListMode = 3 Then
		vPicture = PictureLib.Today;
	ElsIf pListMode = 4 Then
		vPicture = PictureLib.User;
	ElsIf pListMode = 5 Then
		vPicture = PictureLib.EditInDialog;
	EndIf;
	Return vPicture;
EndFunction // GetListModeIconAtServer

// -----------------------------------------------------------------------------
&AtServer
Function pmGetReservationStatusIcon(pReservationStatus, pParentDoc = Undefined) Export
	vPicture = PictureLib.Empty;
	If ValueIsFilled(pReservationStatus) Then
		If pReservationStatus.IsInWaitingList Then
			vPicture = PictureLib.Waiting;
		ElsIf pReservationStatus.IsActive Then
			If ValueIsFilled(pParentDoc) Then
				vPicture = PictureLib.MoveRightAll;
			ElsIf pReservationStatus.IsGuaranteed Then
				vPicture = PictureLib.IsGuaranteed;
			Else
				vPicture = PictureLib.IsActive;
			EndIf;
		ElsIf pReservationStatus.IsCheckIn Then
			vPicture = PictureLib.IsCheckIn;
		ElsIf pReservationStatus.IsNoShow Then
			vPicture = PictureLib.IsNoShow;
		ElsIf pReservationStatus.IsPreliminary Then
			vPicture = PictureLib.IsPreliminary;
		Else
			vPicture = PictureLib.IsNotActive;
		EndIf;
	EndIf;
	Return vPicture;
EndFunction // cmGetReservationStatusIcon

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckVauchersFunctionalOption()
	vUseVauchers = False;
	If ValueIsFilled(SelHotel) And Not SelHotel.IsFolder Then
		vUseVauchers = GetFunctionalOption("Vauchers", New Structure("Hotel", SelHotel));
	ElsIf ValueIsFilled(SessionParameters.CurrentHotel) Then
		vUseVauchers = GetFunctionalOption("Vauchers", New Structure("Hotel", SessionParameters.CurrentHotel));
	EndIf;
	Items.DocumentListVaucherType.Visible = vUseVauchers;
	Items.DocumentListVaucher.Visible = vUseVauchers;
	Items.FillVauchersForSelectedDocuments.Visible = vUseVauchers;
	Items.ReservListContextMenuFillVauchersForSelectedDocuments.Visible = vUseVauchers;
EndProcedure // CheckVauchersFunctionalOption

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckBedsSetupsFunctionalOption()
	vUseBedsSetups = False;
	If ValueIsFilled(SelHotel) And Not SelHotel.IsFolder Then
		vUseBedsSetups = GetFunctionalOption("BedsSetups", New Structure("Hotel", SelHotel));
	ElsIf ValueIsFilled(SessionParameters.CurrentHotel) Then
		vUseBedsSetups = GetFunctionalOption("BedsSetups", New Structure("Hotel", SessionParameters.CurrentHotel));
	EndIf;
	Items.DocumentListBedsSetup.Visible = vUseBedsSetups;
	Items.SelBedsSetup.Visible = vUseBedsSetups;
EndProcedure // CheckBedsSetupsFunctionalOption

// -----------------------------------------------------------------------------
&AtServer
Procedure OnReopenAtServer()
	// Filter by guest group
	If Parameters.Property("SelGuestGroup") And ValueIsFilled(Parameters.SelGuestGroup) Then
		SelGuestGroup = Parameters.SelGuestGroup;
		SelDate = '00010101';
	EndIf;
	// Apply filter parameters
	SetDynamicListParametersAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function GetListOfDocumentsByClient()
	vList = New ValueList();
	If ValueIsFilled(SelClient) Then
		vClientsTab = cmGetOneRoomResClientsList(TrimAll(SelClient.FullName), "", "", "", "", "", False);
		vList.LoadValues(vClientsTab.UnloadColumn("Reservation"));
	EndIf;
	Return vList;
EndFunction // GetListOfDocumentsByClient

// -----------------------------------------------------------------------------
&AtServer
Procedure SetDynamicListParametersAtServer()
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");

	// Manage list columns
	Items.DocumentListAccommodationTemplate.Visible = True;
	Items.DocumentListAccommodationType.Visible = (SelShowAllGuests = 1);
	
	Items.SelDate.Title = ListModes.Get(SelListMode).Presentation;
	Items.ChangeListMode.Title = ListModes.Get(SelListMode).Presentation;
	Items.ChangeListMode.Picture = ListModes.Get(SelListMode).Picture;
	
	// Fill filter group caption
	vAddColon = True;
	vAddSemiColon = False;
	vGroupSearchModeTitle = Items.GroupSearchMode.Title;
	If ValueIsFilled(SelAuthor) Then
		vGroupSearchModeTitle = vGroupSearchModeTitle + ?(vAddColon, ": ", "") + ?(vAddSemiColon, "; ", "") + Items.SelAuthor.Title + ": " + TrimAll(SelAuthor);
		vAddSemiColon = True;
		vAddColon = False;
	EndIf;
	If ValueIsFilled(SelRoom) Then
		vGroupSearchModeTitle = vGroupSearchModeTitle + ?(vAddColon, ": ", "") + ?(vAddSemiColon, "; ", "") + Items.SelRoom.Title + ": " + TrimAll(SelRoom);
		vAddSemiColon = True;
		vAddColon = False;
	EndIf;
	If ValueIsFilled(SelRoomType) Then
		vGroupSearchModeTitle = vGroupSearchModeTitle + ?(vAddColon, ": ", "") + ?(vAddSemiColon, "; ", "") + Items.SelRoomType.Title + ": " + TrimAll(SelRoomType);
		vAddSemiColon = True;
		vAddColon = False;
	EndIf;
	If ValueIsFilled(SelAllotment) Then
		vGroupSearchModeTitle = vGroupSearchModeTitle + ?(vAddColon, ": ", "") + ?(vAddSemiColon, "; ", "") + Items.SelAllotment.Title + ": " + TrimAll(SelAllotment);
		vAddSemiColon = True;
		vAddColon = False;
	EndIf;
	If ValueIsFilled(SelRoomRate) Then
		vGroupSearchModeTitle = vGroupSearchModeTitle + ?(vAddColon, ": ", "") + ?(vAddSemiColon, "; ", "") + Items.SelRoomRate.Title + ": " + TrimAll(SelRoomRate);
		vAddSemiColon = True;
		vAddColon = False;
	EndIf;
	If ValueIsFilled(SelBedsSetup) Then
		vGroupSearchModeTitle = vGroupSearchModeTitle + ?(vAddColon, ": ", "") + ?(vAddSemiColon, "; ", "") + Items.SelBedsSetup.Title + ": " + TrimAll(SelBedsSetup);
		vAddSemiColon = True;
		vAddColon = False;
	EndIf;
	If ValueIsFilled(SelCustomer) Then
		vGroupSearchModeTitle = vGroupSearchModeTitle + ?(vAddColon, ": ", "") + ?(vAddSemiColon, "; ", "") + Items.SelCustomer.Title + ": " + TrimAll(SelCustomer);
		vAddSemiColon = True;
		vAddColon = False;
	EndIf;
	If ValueIsFilled(SelContract) Then
		vGroupSearchModeTitle = vGroupSearchModeTitle + ?(vAddColon, ": ", "") + ?(vAddSemiColon, "; ", "") + Items.SelContract.Title + ": " + TrimAll(SelContract);
		vAddSemiColon = True;
		vAddColon = False;
	EndIf;
	If ValueIsFilled(SelAgent) Then
		vGroupSearchModeTitle = vGroupSearchModeTitle + ?(vAddColon, ": ", "") + ?(vAddSemiColon, "; ", "") + Items.SelAgent.Title + ": " + TrimAll(SelAgent);
		vAddSemiColon = True;
		vAddColon = False;
	EndIf;
	If ValueIsFilled(SelClient) Then
		vGroupSearchModeTitle = vGroupSearchModeTitle + ?(vAddColon, ": ", "") + ?(vAddSemiColon, "; ", "") + Items.SelClient.Title + ": " + TrimAll(SelClient.FullName);
		vAddSemiColon = True;
		vAddColon = False;
	EndIf;
	Items.GroupSearchMode.CollapsedRepresentationTitle = vGroupSearchModeTitle;
	
	vBalancesAreVisible = Not cmCheckUserPermissions("DoNotShowBalancesInLists");
	
	// Balances columns appearance
	Items.ClientSumBalance.Visible = vBalancesAreVisible;
	Items.CustomerSumBalance.Visible = vBalancesAreVisible;
	
	// Reservation list parameters
	ReservList.Parameters.SetParameterValue("qDate", BegOfDay(SelDate));
	ReservList.Parameters.SetParameterValue("qDateTo", ?(SelInPeriod, EndOfDay(SelDateTo), EndOfDay(SelDate)));
	ReservList.Parameters.SetParameterValue("qDateIsFilled", ValueIsFilled(SelDate));
	ReservList.Parameters.SetParameterValue("qEndOfDate", ?(SelInPeriod, ?(ValueIsFilled(SelDateTo), EndOfDay(SelDateTo), Undefined), ?(ValueIsFilled(SelDate), EndOfDay(SelDate), Undefined)));
	ReservList.Parameters.SetParameterValue("qAuthor", SelAuthor);
	ReservList.Parameters.SetParameterValue("qAuthorIsFilled", ValueIsFilled(SelAuthor));
	ReservList.Parameters.SetParameterValue("qHotel", SelHotel);
	ReservList.Parameters.SetParameterValue("qHotelIsFilled", ValueIsFilled(SelHotel));
	ReservList.Parameters.SetParameterValue("qGuestGroup", SelGuestGroup);
	ReservList.Parameters.SetParameterValue("qGuestGroupIsFilled", ValueIsFilled(SelGuestGroup));
	ReservList.Parameters.SetParameterValue("qCustomer", SelCustomer);
	ReservList.Parameters.SetParameterValue("qCustomerIsFilled", ValueIsFilled(SelCustomer));
	ReservList.Parameters.SetParameterValue("qContract", SelContract);
	ReservList.Parameters.SetParameterValue("qContractIsFilled", ValueIsFilled(SelContract));
	ReservList.Parameters.SetParameterValue("qAgent", SelAgent);
	ReservList.Parameters.SetParameterValue("qAgentIsFilled", ValueIsFilled(SelAgent));
	ReservList.Parameters.SetParameterValue("qGuestsList", GetListOfDocumentsByClient());
	ReservList.Parameters.SetParameterValue("qClientIsFilled", ValueIsFilled(SelClient));
	ReservList.Parameters.SetParameterValue("qRoom", SelRoom);
	ReservList.Parameters.SetParameterValue("qRoomIsFilled", ValueIsFilled(SelRoom));
	ReservList.Parameters.SetParameterValue("qRoomType", SelRoomType);
	ReservList.Parameters.SetParameterValue("qRoomTypeIsFilled", ValueIsFilled(SelRoomType));
	ReservList.Parameters.SetParameterValue("qAllotment", SelAllotment);
	ReservList.Parameters.SetParameterValue("qAllotmentIsFilled", ValueIsFilled(SelAllotment));
	ReservList.Parameters.SetParameterValue("qRoomRate", SelRoomRate);
	ReservList.Parameters.SetParameterValue("qRoomRateIsFilled", ValueIsFilled(SelRoomRate));
	ReservList.Parameters.SetParameterValue("qBedsSetup", SelBedsSetup);
	ReservList.Parameters.SetParameterValue("qBedsSetupIsFilled", ValueIsFilled(SelBedsSetup));
	ReservList.Parameters.SetParameterValue("qShowAllGuests", SelShowAllGuests);
	If TrimAll(SelFilterStatus) = "&ALL" Then
		ReservList.Parameters.SetParameterValue("qShowAll", True);
	Else
		ReservList.Parameters.SetParameterValue("qShowAll", False);
	EndIf;
	If TrimAll(SelFilterStatus) = "&ACTIVE" Then
		ReservList.Parameters.SetParameterValue("qShowActiveOnly", True);
	Else
		ReservList.Parameters.SetParameterValue("qShowActiveOnly", False);
	EndIf;
	If TrimAll(SelFilterStatus) = "&NOTPOSTED" Then
		ReservList.Parameters.SetParameterValue("qShowNotPostedOnly", True);
	Else
		ReservList.Parameters.SetParameterValue("qShowNotPostedOnly", False);
	EndIf;
	ReservList.Parameters.SetParameterValue("qReservationStatus", Catalogs.ReservationStatuses.FindByCode(TrimAll(SelFilterStatus), False));
	ReservList.Parameters.SetParameterValue("qSearchByCheckInDate", SelListMode = 0);
	ReservList.Parameters.SetParameterValue("qSearchByStayDate", SelListMode = 1);
	ReservList.Parameters.SetParameterValue("qSearchByCheckOutDate", SelListMode = 2);
	ReservList.Parameters.SetParameterValue("qSearchByCreateDate", SelListMode = 3);
	ReservList.Parameters.SetParameterValue("qSearchByChangeDate", SelListMode = 4);
	ReservList.Parameters.SetParameterValue("qSearchByStatusChangeDate", SelListMode = 5);
	ReservList.Parameters.SetParameterValue("qShowAllGuests", SelShowAllGuests);
	ReservList.Parameters.SetParameterValue("qBalancesAreVisible", vBalancesAreVisible);
	ReservList.Parameters.SetParameterValue("qShowStatusLastChangeTime", Items.DocumentListReservationStatusSetTime.Visible);
	
	// Fill group invoices list parameters
	SetGroupProformaInvoicesDynamicListParametersAtServer();

	// Set form title
	Title = NStr("en='Reservation list: '; ru='Журнал брони: '; de='Reservierungsliste: '") 
			+ ?(ValueIsFilled(SelHotel) And Not SelHotel.IsFolder, Catalogs.Hotels.pmGetHotelPrintName(SelHotel, SessionParameters.CurrentLanguage), TrimAll(SelHotel));
EndProcedure // SetDynamicListParametersAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SetGroupProformaInvoicesDynamicListParametersAtServer()
	// Current guest group proforma invoices list parameters
	GroupProformaInvoices.Parameters.SetParameterValue("qGuestGroup", CurGuestGroup);
	GroupProformaInvoices.Parameters.SetParameterValue("BeginOfPeriod", '00010101');
	GroupProformaInvoices.Parameters.SetParameterValue("EndOfPeriod", '39991231235959');
EndProcedure // SetGroupProformaInvoicesDynamicListParametersAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillFilterStatuses()
	// Clear change status menu
	If SelSetStatusListButton.Count()>0 Then
		For Each vInd In SelSetStatusListButton Do
			vButton = Items.Find(vInd.Presentation);
			If TypeOf(vButton) = Type("FormButton") Then
				Items.Delete(vButton);
			EndIf;	
		EndDo;
	EndIf;	

	// Read reservation statuses
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ReservationStatuses.Ref AS ReservationStatus,
	|	ReservationStatuses.Code AS Code,
	|	ReservationStatuses.Description AS Description,
	|	ReservationStatuses.IsActive AS IsActive,
	|	ReservationStatuses.IsPreliminary AS IsPreliminary,
	|	ReservationStatuses.SortCode AS SortCode
	|FROM
	|	Catalog.ReservationStatuses AS ReservationStatuses
	|WHERE
	|	NOT ReservationStatuses.DeletionMark
	|	AND NOT ReservationStatuses.IsFolder
	|	AND NOT ReservationStatuses.DoNotCreateReservationsInBlock
	|	AND (ReservationStatuses.Hotel = VALUE(Catalog.Hotels.EmptyRef)
	|			OR ReservationStatuses.Hotel IN HIERARCHY (&qHotel))
	|
	|ORDER BY
	|	SortCode,
	|	Description";
	vQry.SetParameter("qHotel", SelHotel);
	vElements = vQry.Execute();
	
	// Fill list of filter elements
	Items.SelFilterStatus.ChoiceList.Clear();
	Items.SelFilterStatus.ChoiceList.Add("&ALL", NStr("en = 'All'; ru = 'Все'; de = 'All'"), , PictureLib.ListViewModeList);
	Items.SelFilterStatus.ChoiceList.Add("&ACTIVE", NStr("en = 'Active'; ru = 'Действующие'; de = 'Aktiv'"), , PictureLib.DocumentJournal);

	Items.SelReservationStatus.ChoiceList.Clear();
	Items.SelReservationStatus.ChoiceList.Add("&ALL", NStr("en = 'All'; ru = 'Все'; de = 'All'"), , PictureLib.ListViewModeList);
	Items.SelReservationStatus.ChoiceList.Add("&ACTIVE", NStr("en = 'Active'; ru = 'Действующие'; de = 'Aktiv'"), , PictureLib.DocumentJournal);
	
	vTrans = vElements.Select();
	While vTrans.Next() Do
		vResStatusIcon = pmGetReservationStatusIcon(vTrans.ReservationStatus);
		
		Items.SelFilterStatus.ChoiceList.Add(vTrans.Code, vTrans.Description, , vResStatusIcon);
		Items.SelReservationStatus.ChoiceList.Add(vTrans.Code, vTrans.Description, , vResStatusIcon);
		
		If vTrans.ReservationStatus.IsCheckIn Then
			Continue;
		EndIf;
		
		// Add change reservation status command
		vCommandName = StrReplace("C" + String(vTrans.ReservationStatus.UUID()), "-", "_");
		If Commands.Find(vCommandName) = Undefined Then
			vCmd = Commands.Add(vCommandName);
			vCmd.Action = "ChangeStatus"; 
			vCmd.Title = TrimAll(vTrans.Description);
			vCmd.Picture = vResStatusIcon;
		EndIf;
		
		// Add button
		vItem = Items.Add(vCommandName, Type("FormButton"), Items.ChangeStatuses);
		vItem.Type = FormButtonType.UsualButton;
		vItem.CommandName = vCommandName; 	
		
		vItem = Items.Add(vCommandName + "_CM", Type("FormButton"), Items.ChangeStatuses1);
		vItem.Type = FormButtonType.CommandBarButton;
		vItem.CommandName = vCommandName; 	
		
		SelSetStatusListButton.Add(vTrans.ReservationStatus, vCommandName);
	EndDo;
	
	Items.SelFilterStatus.ChoiceList.Add("&NOTPOSTED", NStr("en = 'Not posted'; ru = 'Не проведенные'; de = 'Nicht posted'"), , PictureLib.UndoPosting);
	Items.SelReservationStatus.ChoiceList.Add("&NOTPOSTED", NStr("en = 'Not posted'; ru = 'Не проведенные'; de = 'Nicht posted'"), , PictureLib.UndoPosting);

	Items.SelFilterStatus.ColumnsCount = Items.SelFilterStatus.ChoiceList.Count();

	If Items.SelFilterStatus.ChoiceList.Count() > 8 Then
		Items.SelFilterStatus.Visible = False;
		Items.SelReservationStatus.Visible = True;
	Else
		Items.SelFilterStatus.Visible = True;
		Items.SelReservationStatus.Visible = False;
	EndIf;
EndProcedure // FillFilterStatuses

// -----------------------------------------------------------------------------
&AtClient
Procedure FilterStatusOnChange(Item)
	SelReservationStatus = SelFilterStatus;
	FilterStatusOnChangeAtServer();
EndProcedure // FilterStatusOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelReservationStatusOnChange(pItem)
	SelFilterStatus = SelReservationStatus;
	FilterStatusOnChangeAtServer();
EndProcedure // SelReservationStatusOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure FilterStatusOnChangeAtServer()
	// Apply filter parameters
	SetDynamicListParametersAtServer();
EndProcedure // FilterStatusOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ReservListOnActivateRow(pItem)
	If SkipOnRowActivateEvent Then
		SkipOnRowActivateEvent = False;
	Else
		AttachIdleHandler("ReservListOnActivateRowIdleHandler", 0.5, True);
	EndIf;
EndProcedure // ReservListOnActivateRow

// -----------------------------------------------------------------------------
&AtClient
Procedure ReservListOnActivateRowIdleHandler()
	vNewReservTitle = NStr("en='Create'; ru='Создать'; de='Erstellen'");
	vGuestGroup = Undefined;
	vCurData = Items.ReservList.CurrentData;
	If vCurData <> Undefined Then
		vGuestGroup = vCurData.GuestGroup;
		If Not Items.SelectedDocumentsActions.Enabled Then
			Items.SelectedDocumentsActions.Enabled = True;
		EndIf;
		If Not Items.SelectedDocumentActions.Enabled Then
			Items.SelectedDocumentActions.Enabled = True;
		EndIf;
		If Not Items.GroupDetails.Enabled Then
			Items.GroupDetails.Enabled = True;
		EndIf;
		If TypeOf(vCurData.ReservationStatusIsArrivalSchedule) = Type("Boolean") And 
		   vCurData.ReservationStatusIsArrivalSchedule Then
			vNewReservTitle = NStr("en='Create by schedule'; ru='Создать по графику'; de='Erstellen bei Zeitplan'");
		EndIf;
		TReservation = vCurData.Ref;
		TReservationPresentation = ?(ValueIsFilled(vCurData.Room), TrimAll(vCurData.Room) + " ", "") + TrimAll(vCurData.RoomTypeCode) + ", " + Format(vCurData.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(vCurData.CheckOutDate, "DF='dd.MM HH:mm'") + ", " + Format(vCurData.Duration, "NFD=0; NZ=; NG=") + ", " + TrimAll(vCurData.RefNumber);
	Else
		If Items.SelectedDocumentsActions.Enabled Then
			Items.SelectedDocumentsActions.Enabled = False;
		EndIf;
		If Items.SelectedDocumentActions.Enabled Then
			Items.SelectedDocumentActions.Enabled = False;
		EndIf;
		If Items.GroupDetails.Enabled Then
			Items.GroupDetails.Enabled = False;
		EndIf;
		TReservation = Undefined;
		TReservationPresentation = NStr("en='Res. data and number'; ru='Данные и номер брони'; de='Res. Data und Nummer'");
	EndIf;
	If vNewReservTitle <> Items.NewReserv.Title Then
		Items.NewReserv.Title = vNewReservTitle;
	EndIf;
	If vGuestGroup <> CurGuestGroup Then
		CurGuestGroup = vGuestGroup;
		RefreshGroupTotals();
	EndIf;
EndProcedure // ReservListOnActivateRowIdleHandler

// -----------------------------------------------------------------------------
&AtClient
Procedure RefreshGroupTotals()
	UpdateTotalsByGroupAtServer();
	AttachIdleHandler("GetRefreshGroupTotalsJobResult", 0.5, True);
EndProcedure // RefreshGroupTotals

// -----------------------------------------------------------------------------
&AtServer
Function GetRefreshGroupTotalsJobResultAtServer()
	If GetGroupTotalsJobUUID <> EmptyUUID Then
		vBackgroundJob = AsyncCalls.CheckBackgroundJob(GetGroupTotalsJobUUID);
		If vBackgroundJob <> Undefined Then 
			If vBackgroundJob.Status = "Processing" Then 
				Return "Processing";
			ElsIf vBackgroundJob.Status = "Completed" Then
				vJobResult = GetFromTempStorage(GetGroupTotalsJobAddress);
				If vJobResult <> Undefined Then
					If CurGuestGroup = vJobResult.GuestGroup Then
						FillPropertyValues(ThisObject, vJobResult);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	Return "Completed";
EndFunction // GetRefreshGroupTotalsJobResultAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure GetRefreshGroupTotalsJobResult()
	vStatus = GetRefreshGroupTotalsJobResultAtServer();
	If vStatus = "Processing" Then
		AttachIdleHandler("GetRefreshGroupTotalsJobResult", 0.5, True);
	EndIf;
EndProcedure // GetRefreshGroupTotalsJobResult

// -----------------------------------------------------------------------------
&AtServer
Procedure UpdateTotalsByGroupAtServer()
	TotalGroupSales = "";
	TotalGroupPayments = "";
	TotalGroupBalance = "";
	TotalGuestsReservedByGroup = "";
	TotalRoomReservedByGroup = "";
	TotalGuestsCheckInByGroup = "";
	TotalRoomCheckInByGroup = "";
	TGroupResources = "";
		
	If ValueIsFilled(CurGuestGroup) Then
		vTempStorageAdress = PutToTempStorage(Undefined, UUID);
		
		vProcedureParameters = new Array;
		vProcedureParameters.Add(CurGuestGroup);
		vProcedureParameters.Add(vTempStorageAdress);
	
		vBackgroundJob = AsyncCalls.StartBackgroundJob("ProlongedOperations.GuestGroups_GetGroupTotals", vProcedureParameters, , "Get guest group totals", vTempStorageAdress);

		GetGroupTotalsJobUUID = vBackgroundJob.UUID;
		GetGroupTotalsJobAddress = vTempStorageAdress;
	Else 
		GetGroupTotalsJobUUID = EmptyUUID;
		GetGroupTotalsJobAddress = "";
	EndIf;
	
	// Refresh list of group invoices
	SetGroupProformaInvoicesDynamicListParametersAtServer();
EndProcedure // UpdateTotalsByGroupAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SelListModesOnChangeAtServer()
	// Apply filter parameters
	SetDynamicListParametersAtServer();
EndProcedure // SelListModesOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SelListModesOnChange()
	SelListModesOnChangeAtServer();
EndProcedure // SelListModesOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure DateOnChangeAtServer()
	If ValueIsFilled(SelDate) Then
		If SelDate > '20991231' Or SelDate < '20091231' Then
			SelDate = CurrentSessionDate();
		EndIf;
	EndIf;
	If ValueIsFilled(SelDateTo) Then
		If SelDateTo > '20991231' Or SelDateTo < '20091231' Then
			SelDateTo = CurrentSessionDate();
		EndIf;
	EndIf;
	// Apply filter parameters
	SetDynamicListParametersAtServer();
EndProcedure // DateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure DateOnChange(pItem)
	DateOnChangeAtServer();
EndProcedure // DateOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure SelAuthorOnChangeAtServer()
	// Apply filter parameters
	SetDynamicListParametersAtServer();
EndProcedure // SelAuthorOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SelAuthorOnChange(pItem)
	SelAuthorOnChangeAtServer();
EndProcedure // SelAuthorOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure SelGuestGroupOnChangeAtServer()
	CurGuestGroup = SelGuestGroup;
	UpdateTotalsByGroupAtServer();
	// Apply filter parameters
	SetDynamicListParametersAtServer();
EndProcedure // SelGuestGroupOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SelGuestGroupOnChange(pItem)
	SelGuestGroupOnChangeAtServer();
	AttachIdleHandler("GetRefreshGroupTotalsJobResult", 1, True);
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SelCustomerOnChangeAtServer()
	If ValueIsFilled(SelCustomer) And ValueIsFilled(SelContract) And 
	   SelContract.Owner <> SelCustomer Then
		SelContract = Catalogs.Contracts.EmptyRef();
	EndIf;
	// Apply filter parameters
	SetDynamicListParametersAtServer();
EndProcedure // SelCustomerOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SelCustomerOnChange(pItem)
	SelCustomerOnChangeAtServer();
EndProcedure // SelCustomerOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure SelContractOnChangeAtServer()
	If ValueIsFilled(SelCustomer) And ValueIsFilled(SelContract) And 
	   SelContract.Owner <> SelCustomer Then
		SelCustomer = SelContract.Owner;
	EndIf;
	// Apply filter parameters
	SetDynamicListParametersAtServer();
EndProcedure // SelContractOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SelContractOnChange(pItem)
	SelContractOnChangeAtServer();
EndProcedure // SelContractOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure SelAgentOnChangeAtServer()
	// Apply filter parameters
	SetDynamicListParametersAtServer();
EndProcedure // SelAgentOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SelAgentOnChange(pItem)
	SelAgentOnChangeAtServer();
EndProcedure // SelAgentOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure SelRoomOnChangeAtServer()
	// Apply filter parameters
	SetDynamicListParametersAtServer();
EndProcedure // SelRoomOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomOnChange(Item)
	SelRoomOnChangeAtServer();
EndProcedure // SelRoomOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure SelRoomTypeOnChangeAtServer()
	// Apply filter parameters
	SetDynamicListParametersAtServer();
EndProcedure // SelRoomTypeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomTypeOnChange(pItem)
	SelRoomTypeOnChangeAtServer();
EndProcedure // SelRoomTypeOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure SelAllotmentOnChangeAtServer()
	// Apply filter parameters
	SetDynamicListParametersAtServer();
EndProcedure // SelAllotmentOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SelAllotmentOnChange(Item)
	SelAllotmentOnChangeAtServer();
EndProcedure // SelAllotmentOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure SelRoomRateOnChangeAtServer()
	// Apply filter parameters
	SetDynamicListParametersAtServer();
EndProcedure // SelRoomRateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomRateOnChange(pItem)
	SelRoomRateOnChangeAtServer();
EndProcedure // SelRoomRateOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure SelBedsSetupOnChangeAtServer()
	// Apply filter parameters
	SetDynamicListParametersAtServer();
EndProcedure // SelBedsSetupOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SelBedsSetupOnChange(pItem)
	SelBedsSetupOnChangeAtServer();
EndProcedure // SelBedsSetupOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure SelClientOnChangeAtServer()
	// Apply filter parameters
	SetDynamicListParametersAtServer();
EndProcedure // SelClientOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SelClientOnChange(Item)
	SelClientOnChangeAtServer();
EndProcedure // SelClientOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure SelShowAllGuestsOnChangeAtServer()
	// Apply filter parameters
	SetDynamicListParametersAtServer();
EndProcedure // SelShowAllGuestsOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SelShowAllGuestsOnChange(pItem)
	SelShowAllGuestsOnChangeAtServer();
EndProcedure // SelShowAllGuestsOnChange

// -----------------------------------------------------------------------------
&AtServer
Function GetMainDocRef(pRef, rDifferentCheckInDates = False)
	vMainDoc = pRef;
	rDifferentCheckInDates = False;
	// Fill one room guests
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	Reservations.Ref AS Ref,
	|	BEGINOFPERIOD(Reservations.CheckInDate, DAY) AS CheckInDate,
	|	Reservations.Guest AS GuestRef
	|FROM
	|	Document.Reservation AS Reservations
	|WHERE
	|	Reservations.GuestGroup = &qGroup
	|	AND Reservations.Number = &qNumber
	|	AND Reservations.Posted
	|	AND NOT Reservations.DeletionMark
	|	AND (Reservations.ReservationStatus.IsActive
	|			OR Reservations.ReservationStatus.IsCheckIn
	|			OR Reservations.ReservationStatus.IsPreliminary
	|			OR Reservations.ReservationStatus.IsInWaitingList
	|			OR Reservations.ReservationStatus = &qReservStatus)
	|
	|ORDER BY
	|	Reservations.CheckInDate,
	|	Reservations.AccommodationType.SortCode";
	vQry.SetParameter("qGroup", pRef.GuestGroup);
	vQry.SetParameter("qReservStatus", pRef.ReservationStatus);
	vQry.SetParameter("qNumber", pRef.Number);
	vQryResult = vQry.Execute().Unload();
	vMainDocCheckInDate = '00010101';
	For Each vQryResultRow In vQryResult Do
		If vQryResult.IndexOf(vQryResultRow) = 0 Then
			vMainDoc = vQryResultRow.Ref;
			vMainDocCheckInDate = vQryResultRow.CheckInDate;
		EndIf;
		If ValueIsFilled(vMainDocCheckInDate) And vMainDocCheckInDate <> vQryResultRow.CheckInDate Then
			rDifferentCheckInDates = True;
			Break;
		EndIf;
	EndDo;
	Return vMainDoc;
EndFunction // GetMainDocRef

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckIn(pCommand)
	vSelList = Items.ReservList.SelectedRows;
	If vSelList.Count() >= 1 Then
		vSelResRow = vSelList[0];
		CheckInByReservation(vSelResRow);
	Else	
		Return;
	EndIf;	
EndProcedure // CheckIn

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckInByReservation(pReservation)
	vMessageText = "";
	vAccForm = Undefined;
	vSelResRow = pReservation;            
	vApdexRemarks = GetRemarksForAPDEX(vSelResRow);
	vMainRoomRef = GetMainDocRef(vSelResRow);
	vThereAreDifferentCheckInDates = False;
	If vSelResRow <> Undefined Then
		vResult = CheckInAtServer(vMainRoomRef, false);
		If ValueIsFilled(vResult) Then
			If vResult = "DoQueryBox" Then
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='You are checking in by inactive reservation!';ru='Селите по не активной брони!';de='Sie bringen nicht nach einer aktiven Reservierung unter!'"), MessageStatus.Information);
			EndIf;
			vHotel = tcOnServer.cmGetAttributeByRef(vMainRoomRef, "Hotel");
			vHotelAccountingDate = '00010101';
			If ValueIsFilled(vHotel) Then
				vHotelAccountingDate = tcOnServer.cmGetAttributeByRef(vHotel, "AccountingDate");
			EndIf;
			If Not ValueIsFilled(vHotelAccountingDate) Then
				vHotelAccountingDate = BegOfDay(CurrentDate());
			EndIf;
			vResult = CheckInAtServer(vMainRoomRef, True);
			If ValueIsFilled(vResult) Then
				If TypeOf(vResult) = Type("ValueList") Then
					vQuestionWasAsked = False;
					vSelResList = New ValueList;
					vFirstGuestCheckInDate = '00010101';
					For Each vItem In vResult Do
						vCheckInDate = tcOnServer.cmGetAttributeByRef(vItem.Value, "CheckInDate");
						If Not ValueIsFilled(vFirstGuestCheckInDate) Then
							vFirstGuestCheckInDate = vCheckInDate;
						EndIf;
						If BegOfDay(vFirstGuestCheckInDate) <> BegOfDay(vCheckInDate) Then
							vThereAreDifferentCheckInDates = True;
						EndIf;
						If vHotelAccountingDate <> BegOfDay(vCheckInDate) Then
							If Not vQuestionWasAsked Then
								vMessageText = NStr("en='There are reservations with check-in date " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " in the list of reservations selected. This date differs from todays date " + Format(vHotelAccountingDate, "DF=dd.MM.yyyy") + "!';
								                    |de='Es gibt Reservierungen mit Check-in-Datum " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " in der Liste der ausgewählten Reservierungen. Dieses Datum unterscheidet sich vom heutigen Datum " + Format(vHotelAccountingDate, "DF=dd.MM.yyyy") + "!';
								                    |ru='В выбранной брони есть гости с датой заезда " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " отличающейся от текущей даты " + Format(vHotelAccountingDate, "DF=dd.MM.yyyy") + "!'");
								vQuestionWasAsked = True;
							EndIf;
						EndIf;
						vSelResList.Add(vItem.Value);
					EndDo; 
					// Check current reservation list deposits
					CheckReservationsDeposits(vSelResList);
					vResult = CheckInAtServer(vMainRoomRef, true, vSelResList);
					If ValueIsFilled(vResult) Then
						If TypeOf(vResult) = Type("Structure") Then
							// APDEX
							vKeyOperation = "Document.Accommodation.Form.tcDocumentForm.OpenForm";   
							APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, , vApdexRemarks);

							// Do check-in
							vAccForm = CheckInAtClient(vResult.ValueList.Copy());
						Else
							ShowMessageBox(, vResult);
						EndIf;
					EndIf;
				ElsIf TypeOf(vResult) = Type("Structure") Then
					// APDEX
					vKeyOperation = "Document.Accommodation.Form.tcDocumentForm.OpenForm";   
					APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, , vApdexRemarks);

					// Do check-in
					vAccForm = CheckInAtClient(vResult.ValueList.Copy());
				ElsIf vResult <> "DoQueryBox" Then
					ShowMessageBox(, vResult);
				EndIf;
			ElsIf TypeOf(vResult) = Type("ValueList") Then
				vQuestionWasAsked = False;
				vSelResList = New ValueList;
				vFirstGuestCheckInDate = '00010101';
				For Each vItem In vResult Do
					vCheckInDate = tcOnServer.cmGetAttributeByRef(vItem.Value, "CheckInDate");
					If Not ValueIsFilled(vFirstGuestCheckInDate) Then
						vFirstGuestCheckInDate = vCheckInDate;
					EndIf;
					If BegOfDay(vFirstGuestCheckInDate) <> BegOfDay(vCheckInDate) Then
						vThereAreDifferentCheckInDates = True;
					EndIf;
					If vHotelAccountingDate <> BegOfDay(vCheckInDate) Then
						If Not vQuestionWasAsked Then
							vMessageText = NStr("en='There are reservations with check-in date " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " in the list of reservations selected. This date differs from today date " + Format(vHotelAccountingDate, "DF=dd.MM.yyyy") + "!';
							                    |de='Es gibt Reservierungen mit Check-in-Datum " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " in der Liste der ausgewählten Reservierungen. Dieses Datum unterscheidet sich vom heutigen Datum " + Format(vHotelAccountingDate, "DF=dd.MM.yyyy") + "!';
							                    |ru='В выбранной брони есть гости с датой заезда " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " отличающейся от текущей даты " + Format(vHotelAccountingDate, "DF=dd.MM.yyyy") + "!'");
							vQuestionWasAsked = True;
						EndIf;
					EndIf;
					vSelResList.Add(vItem.Value);
				EndDo;
				// Check current reservation list deposits
				CheckReservationsDeposits(vSelResList);
				vResult = CheckInAtServer(vMainRoomRef, false, vSelResList);
				If ValueIsFilled(vResult) Then
					If TypeOf(vResult)=Type("Structure") Then
						// APDEX
						vKeyOperation = "Document.Accommodation.Form.tcDocumentForm.OpenForm";
						APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, , vApdexRemarks);

						// Do check-in
						vAccForm = CheckInAtClient(vResult.ValueList.Copy());
					ElsIf vResult <> "DoQueryBox" Then
						ShowMessageBox(, vResult);
					EndIf;
				EndIf;
			ElsIf TypeOf(vResult)=Type("Structure") Then
				// APDEX
				vKeyOperation = "Document.Accommodation.Form.tcDocumentForm.OpenForm";
				APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, , vApdexRemarks);

				// Open new accommodation and fill group table from the given list
				vAccForm = OpenForm("Document.Accommodation.Form.tcDocumentForm", New Structure("GuestsToCheckInList", vResult.ValueList.Copy()), ThisObject);

				// Do check-in
				vAccForm = CheckInAtClient(vResult.ValueList.Copy());
			ElsIf vResult <> "DoQueryBox" Then
				ShowMessageBox(, vResult);
			EndIf;
		EndIf;
	EndIf;
	If Not IsBlankString(vMessageText) Then
		If vAccForm <> Undefined And Not vThereAreDifferentCheckInDates Then
			vUM = New UserMessage();
			vUM.Text = vMessageText;
			vUM.TargetID = vAccForm.UUID;
			vUM.Message();
		Else
			ShowMessageBox(, vMessageText);
		EndIf;
	EndIf;
EndProcedure // CheckInByReservation

// -----------------------------------------------------------------------------
&AtClient
Function CheckInAtClient(pGuestsToCheckInList)
	vAccForm = Undefined;
	If SelShowAllGuests = 1 And pGuestsToCheckInList.Count() > 1 Then
		vReservation = pGuestsToCheckInList.Get(0).Value;
		OpenForm("CommonForm.tcSelectGuestsToCheckIn", New Structure("DocRef, GuestsToCheckInList", vReservation, pGuestsToCheckInList));
	Else
		vAccForm = OpenForm("Document.Accommodation.Form.tcDocumentForm", New Structure("GuestsToCheckInList", pGuestsToCheckInList), ThisObject);
	EndIf;
	Return vAccForm;
EndFunction // CheckInAtClient

// -----------------------------------------------------------------------------
&AtServerNoContext
Function CheckReservationsDeposits(pResRef)
	vFolios = cmGetDocumentFoliosWithDebts(pResRef, True); // Deposits only
	If vFolios.Count() > 0 Then
		vDebtsMessage = NStr("en='Folios: ';ru='По лицевым счетам: ';de='Nach Personenkonten: '") + Chars.LF;
		For Each vFoliosRow In vFolios Do
			If ValueIsFilled(vFoliosRow.Folio) Then
				vDebtsMessage = vDebtsMessage + Chars.LF + "#" + TrimAll(vFoliosRow.Folio.Number) + " " + 
				TrimAll(vFoliosRow.Folio.Client) + NStr("ru=', номер ';en=', room ';de=', Zimmer '") + 
				TrimAll(vFoliosRow.Folio.Room) + NStr("ru=', период ';en=', period ';de=', Period '") + 
				Format(vFoliosRow.Folio.DateTimeFrom, "DF='dd.MM.yy HH:mm'") + " - " + 
				Format(vFoliosRow.Folio.DateTimeTo, "DF='dd.MM.yy HH:mm'") + " = " + 
				cmFormatSum(vFoliosRow.SumBalance, vFoliosRow.Folio.FolioCurrency, "NZ=");
			Else
				vDebtsMessage = vDebtsMessage + Chars.LF + NStr("en='<Empty folio>';ru='<Пустое фолио>';de='<Leeres Konto>'") + " = " + cmFormatSum(vFoliosRow.SumBalance, "NZ=", , True);
			EndIf;
		EndDo;
		vDebtsMessage = vDebtsMessage + Chars.LF + Chars.LF + NStr("en='There are DEPOSITS!';ru='ЕСТЬ ПРЕДОПЛАТА!';de='ES LIEGT EINE ANZAHLUNG VOR!'");
		tcCommonFunctionOnClientServer.TextMessage(vDebtsMessage);
		WriteLogEvent(NStr("en='Reservation.CheckDeposits';ru='Резервирование.ПроверкаДепозита';de='Reservation.CheckDeposits'"), EventLogLevel.Information, Metadata.Documents.Folio, , vDebtsMessage);
	EndIf;
	Return True;
EndFunction // CheckReservationsDeposits

// -----------------------------------------------------------------------------
&AtServerNoContext
Function CheckInAtServer(pRef, pQueryBoxInactive = false, pSelResList = Undefined)
	// Build list of selected reservations. We will process reservations from the
	// one room only (or empty one)
	vSelRes = pRef;
	vStopCheckIn = False;
	If Not vSelRes.Posted Then
		vStopCheckIn = True;
	ElsIf Not ValueIsFilled(vSelRes.ReservationStatus) Then
		vStopCheckIn = True;
	ElsIf Not vSelRes.ReservationStatus.IsActive And vSelRes.ReservationStatus <> vSelRes.Hotel.NoShowReservationStatus Then
		vStopCheckIn = True;
	EndIf;
	If vStopCheckIn Then
		If Not cmCheckUserPermissions("HavePermissionToCheckInBasedOnInactiveReservations") And ValueIsFilled(vSelRes.Hotel) Then
			Return NStr("en='You do not have rights to check-in guests based on inactive reservation!';ru='Нет прав на размещение гостей по не активной брони!';de='Sie haben keine Rechte, Gäste nach nicht aktiven Reservierungen zu platzieren! '");
		ElsIf Not pQueryBoxInactive Then
			Return "DoQueryBox"
		EndIf;
	EndIf;
	If vSelRes.Posted Then
		vSelResList = New ValueList();
		vSelRows = GetOneRoomGuests(vSelRes);
		vQuestionWasAsked = False;
		vSkip = False;
		If pSelResList = Undefined Then
			For Each vRow In vSelRows Do
				If Not vRow.Ref.ReservationStatus.IsCheckIn Then
					vSelResList.Add(vRow.Ref, cmBuildAccommodationSortingPresentation(vRow.Ref));
				EndIf;
			EndDo;
		Else
			vSelResList = pSelResList;
		EndIf;
		If pSelResList = Undefined Then
			Return vSelResList;
		EndIf;
		If vSelResList.Count() = 0 Then
			Return NStr("en='Not found documents to check-in';ru='Не найдены документы для размещения';de='Dokumente für Unterbringungen wurde nicht gefunden'");
		Else
			vSelResList.SortByPresentation();
			vSelRes = vSelResList.Get(0).Value;
		EndIf;
		Return New Structure("ValueList", vSelResList);
	Else
		return NStr("en='Check-in is allowed for posted reservation only!';ru='Поселять можно только по проведенной брони!';de='Ein Check-In ist nur nach einer bearbeiteten Reservierung möglich!'");
	EndIf;
EndFunction // CheckInAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetOneRoomGuests(pRef)
	// Fill one room guests
	vQry = New Query;
	vQry.Text = "SELECT
	|	Reservations.Ref AS Ref,
	|	Reservations.CheckInDate AS CheckInDate,
	|	Reservations.CheckOutDate AS CheckOutDate,
	|	Reservations.Guest AS GuestRef,
	|	Reservations.Guest.FullName AS Guest,
	|	Reservations.AccommodationType AS AccommodationType,
	|	0 AS AnnulReserv,
	|	FALSE AS IsStatusChanged,
	|	FALSE AS IsAnnulation,
	|	TRUE AS IsGuest,
	|	&qEmptyReservationStatusRef AS ReservationStatus
	|FROM
	|	Document.Reservation AS Reservations
	|WHERE
	|	Reservations.GuestGroup = &qGroup
	|	AND Reservations.Number = &qNumber
	|	AND Reservations.Posted
	|	AND NOT Reservations.DeletionMark
	|	AND ((Reservations.ReservationStatus.IsActive
	|			OR Reservations.ReservationStatus.IsCheckIn
	|			OR Reservations.ReservationStatus.IsPreliminary
	|			OR Reservations.ReservationStatus.IsInWaitingList)
	|		OR	(Reservations.ReservationStatus = &qReservStatus))
	|ORDER BY
	|	Reservations.CheckInDate,
	|	Reservations.AccommodationType.SortCode";
	vQry.SetParameter("qGroup", pRef.GuestGroup);
	vQry.SetParameter("qGuest", pRef.Guest);
	vQry.SetParameter("qEmptyGuest", Catalogs.Clients.EmptyRef());
	vQry.SetParameter("qReservStatus", pRef.ReservationStatus);
	vQry.SetParameter("qAccType", pRef.AccommodationType);
	vQry.SetParameter("qNumber", pRef.Number);
	vQry.SetParameter("qEmptyReservationStatusRef", Catalogs.ReservationStatuses.EmptyRef());
	vQryResult = vQry.Execute().Unload();
	Return vQryResult;
EndFunction // GetOneRoomGuests

// -----------------------------------------------------------------------------
&AtClient
Procedure NewReservation(pCommand)
	If ValueIsFilled(SelHotel) And Not tcOnServer.cmGetAttributeByRef(SelHotel, "IsFolder") Then
		vBasis = Undefined;
		vCurData = Items.ReservList.CurrentData;
		If vCurData <> Undefined Then
			If TypeOf(vCurData.ReservationStatusIsArrivalSchedule) = Type("Boolean") And 
			   vCurData.ReservationStatusIsArrivalSchedule Then
				vBasis = vCurData.Ref;
			EndIf;
		EndIf;
		If ValueIsFilled(vBasis) Then
			OpenForm("Document.Reservation.ObjectForm", New Structure("Basis", vBasis), ThisObject);
		Else
			OpenForm("Document.Reservation.ObjectForm", New Structure("Hotel", SelHotel), ThisObject, SelHotel);
		EndIf;
	Else
		ShowMessageBox(, NStr("en='Please, choose hotel first!'; ru='Пожалуйста сначала выберите отель!'; de='Bitte wählen Sie zuerst ein Hotel aus!'"));
	EndIf;
EndProcedure // NewReservation

// -----------------------------------------------------------------------------
&AtClient
Procedure EditReservation(pCommand)
	vRowData = Items.ReservList.CurrentData;
	If vRowData <> Undefined Then
		vDocRef = GetRefToBeOpened(vRowData.Ref);
		If TypeOf(vDocRef) = Type("DocumentRef.Accommodation") Then
			// APDEX
			vKeyOperation = "Document.Accommodation.Form.tcDocumentForm.OpenForm";  
			vApdexRemarks = GetRemarksForAPDEX(vDocRef, True);
			APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, , vApdexRemarks);

			OpenForm("Document.Accommodation.ObjectForm", New Structure("Key", vDocRef));
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='The reservation has checked-in! Accommodation was opened...'; ru='Бронь заехала. Было открыто размещение...'; de='Die Reservierung ist angekommen. Unterkunft wurde eröffnet...'"));
		Else
			// APDEX
			vKeyOperation = "Document.Reservation.Form.tcDocumentForm.OpenForm";     
			vApdexRemarks = GetRemarksForAPDEX(vDocRef);
			APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, , vApdexRemarks);

			OpenForm("Document.Reservation.ObjectForm", New Structure("Key", vDocRef));
		EndIf;
	EndIf;
EndProcedure // EditReservation

// -----------------------------------------------------------------------------
&AtClient
Procedure CopyReservation(pCommand)
	// Ask if to clear guests from reservation
	If ValueIsFilled(SelHotel) And Not tcOnServer.cmGetAttributeByRef(SelHotel, "IsFolder") Then
		vCurData = Items.ReservList.CurrentData;
		If vCurData <> Undefined And ValueIsFilled(vCurData.Ref) Then
			OpenForm("Catalog.GuestGroups.Form.tcReservationCopyOptions", New Structure("ClearGuestNames, UseSameFoliosAndBillingInstructions, TemplateDocument, CopyToTheNewGuestGroup, GuestGroup", True, False, vCurData.Ref, True, vCurData.GuestGroup), ThisObject);
		EndIf;
	Else
		ShowMessageBox(, NStr("en='Please, choose hotel first!'; ru='Пожалуйста сначала выберите отель!'; de='Bitte wählen Sie zuerst ein Hotel aus!'"));
	EndIf;
EndProcedure // CopyReservation

// -----------------------------------------------------------------------------
&AtClient
Procedure CopyReservationOptionsAfterChoice(pOptions) Export
	If Not ValueIsFilled(pOptions.TemplateDocument) Then
		Return;
	EndIf;
	vDocFormParameters = New Structure;
	vDocFormParameters.Insert("CopiedDocument", pOptions.TemplateDocument);
	vDocFormParameters.Insert("ClearGuestsOnOpen", pOptions.ClearGuestNames);
	vDocFormParameters.Insert("UseSameFoliosAndBillingInstructions", pOptions.UseSameFoliosAndBillingInstructions);
	If pOptions.Property("CopyToTheNewGuestGroup") And Not pOptions.CopyToTheNewGuestGroup And 
	   pOptions.Property("GuestGroup") And ValueIsFilled(pOptions.GuestGroup) Then
		vDocFormParameters.Insert("GuestGroup", pOptions.GuestGroup);
	EndIf;
	OpenForm("Document.Reservation.ObjectForm", vDocFormParameters, ThisObject);
EndProcedure // CopyReservationOptionsAfterChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenFolios(Command)
	vRef = Items.ReservList.CurrentRow;
	If Not vRef = Undefined Then
		// APDEX
		vKeyOperation = "CommonForm.tcFoliosForm.OpenForm";           
		vApdexRemarks = GetRemarksForAPDEX(vRef);
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, , vApdexRemarks);
		
		vParametersStructure = New Structure("DocRef", vRef);
		OpenForm("CommonForm.tcFoliosForm", New Structure("ParametersStructure", vParametersStructure), , vRef);
	EndIf;
EndProcedure // OpenFolios

// -----------------------------------------------------------------------------
&AtClient
Procedure RefreshListAndTotals() Export
	If IsInputAvailable() Then
		Items.ReservList.Refresh();
		If Items.GroupProformaInvoices.Visible Then
			Items.GroupProformaInvoices.Refresh();
		EndIf;
		UpdateTotalsByGroupAtServer();
		AttachIdleHandler("GetRefreshGroupTotalsJobResult", 1, True);
	Else
		AttachIdleHandler("RefreshListAndTotals", 1, True);
	EndIf;
EndProcedure // RefreshListAndTotals

// -----------------------------------------------------------------------------
&AtServer
Procedure ChangeStatusAtServer(pAnnulationReason, pGuaranteeType)
	vStatusRef = SelResStatus;
	vAnnulationReason = pAnnulationReason;
	vGuaranteeType = pGuaranteeType;

	vResList = New ValueList();
	vSelRows = Items.ReservList.SelectedRows;
	For Each vSelRow In vSelRows Do
		If ValueIsFilled(vSelRow.Ref) Then
			vResRef = vSelRow.Ref;
			If SelShowAllGuests = 0 Then
				vOneRoomGuests = cmGetOneRoomReservations(vResRef.Number, vResRef.GuestGroup, vResRef.CheckInDate, vResRef.CheckOutDate, Not (vResRef.ReservationStatus.IsActive Or vResRef.ReservationStatus.IsPreliminary));
				For Each vOneRoomGuestsRow In vOneRoomGuests Do
					vResList.Add(vOneRoomGuestsRow.Ref);
				EndDo;
				If vResList.FindByValue(vResRef) = Undefined Then
					vResList.Add(vResRef);
				EndIf;
			Else
				vResList.Add(vResRef);
			EndIf;
		EndIf;
	EndDo;
	// Iterate thru selected documents
	vResObj = Undefined;
	i = 0;
	For Each vResListItem In vResList Do
		If ValueIsFilled(vResListItem.Value) Then
			// Get reservation reference
			vResRef = vResListItem.Value;
			If vResRef.ReservationStatus <> vStatusRef Or vResRef.GuaranteeType <> vGuaranteeType Then
				// Check user rights
				If Not cmCheckUserPermissions("HavePermissionToEditClosedForEditDocuments") Then
					If vResRef.IsClosedForEdit Then
						tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to change closed for edit document!';ru='Нет прав на изменение документа с включенным запретом редактирования!';de='Sie haben keine Rechte, das Dokument zu bearbeiten mit eingeschlossenem Bearbeitungsverbot!'"));
						i = i + 1;
						Continue;
					EndIf;
				EndIf;
				If Not cmCheckUserPermissions("HavePermissionToEditReservations") Then
					If (Not ValueIsFilled(vResRef.Author.Department) And vResRef.Author <> SessionParameters.CurrentUser Or 
						ValueIsFilled(vResRef.Author.Department) And vResRef.Author <> SessionParameters.CurrentUser And 
						ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Department) And 
						vResRef.Author.Department <> SessionParameters.CurrentUser.Department) Then
						tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to change posted reservations created by other users!';ru='Нет прав на изменение чужой проведенной брони!';de='Sie haben keine Rechte, eine von einer anderen Person ausgeführte Reservierung zu bearbeiten!'"));
						i = i + 1;
						Continue;
					EndIf;
				EndIf;
				If Not cmCheckUserPermissions("HavePermissionToEditInactiveReservations") Then
					If ValueIsFilled(vResRef.ReservationStatus) And Not vResRef.ReservationStatus.IsActive And Not vResRef.ReservationStatus.IsPreliminary And Not vResRef.ReservationStatus.IsInWaitingList Then
						tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to edit inactive reservations!';ru='Нет прав на изменение не активной брони!';de='Sie haben keine Rechte, nicht aktive Reservierungen zu bearbeiten!'"));
						i = i + 1;
						Continue;
					EndIf;
				EndIf;
				If Not cmCheckUserPermissions("HavePermissionToEditAccommodations") Then
					If ValueIsFilled(vResRef.ReservationStatus) And vResRef.ReservationStatus.IsCheckIn Then
						tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to change checked-in reservations!';ru='Нет прав на изменение брони в статусе заезд!';de='Sie haben keine Rechte, die Reservierung im Status der Anreise zu bearbeiten!'"));
						i = i + 1;
						Continue;
					EndIf;
				EndIf;
				// Get reservation object
				vResObj = vResRef.GetObject();
				// Update document
				vOldReservationStatus = vResObj.ReservationStatus;
				vResObj.ReservationStatus = vStatusRef;
				vResObj.GuaranteeType = vGuaranteeType;
				vResObj.pmSetDoCharging();
				vResObj.AnnulationReason = vAnnulationReason;
				If Not vResObj.Posted Then
					If vResObj.DeletionMark Then
						vResObj.DeletionMark = False;
					EndIf;
				EndIf;
				vResObj.pmCalculateServices( , , , , , vResObj.IsForFolioSplit);
				vResObj.Write(DocumentWriteMode.Posting);
				// Save data to the document change history
				vResObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				// Check if only main room guests are shown
				vOneRoomReservations = cmGetOneRoomReservations(TrimAll(vResObj.Number), vResObj.GuestGroup, vResObj.CheckInDate, vResObj.CheckOutDate, True);
				For Each vResRow In vOneRoomReservations Do
					vExtraResRef = vResRow.Ref;
					If vExtraResRef <> vResObj.Ref Then
						If ValueIsFilled(vExtraResRef.ReservationStatus) And vExtraResRef.ReservationStatus.IsActive Or 
							vExtraResRef.ReservationStatus = vOldReservationStatus Then
							vExtraResObj = vExtraResRef.GetObject();
							// Update document
							vExtraResObj.ReservationStatus = vStatusRef;
							vExtraResObj.GuaranteeType = vGuaranteeType;
							vExtraResObj.pmSetDoCharging();
							vExtraResObj.AnnulationReason = vAnnulationReason;
							If Not vExtraResObj.Posted Then
								If vExtraResObj.DeletionMark Then
									vExtraResObj.DeletionMark = False;
								EndIf;
							EndIf;
							vExtraResObj.pmCalculateServices( , , , , , vExtraResObj.IsForFolioSplit);
							vExtraResObj.Write(DocumentWriteMode.Posting);
							// Save data to the document change history
							vExtraResObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
						EndIf;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		i = i + 1;
	EndDo;
	Items.ReservList.Refresh();
EndProcedure // ChangeStatusAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeStatus(pCommand)
	If Items.ReservList.SelectedRows.Count()= 0 Then
		Return;
	EndIf;	
	// Get status
	vStatusArr = GetCurrentStatus(pCommand.Name);	
	If ValueIsFilled(SelResStatus) Then
		// Ask for annulation reason
		vAnnulationReason = Undefined;
		If vStatusArr.IsAnnulation Then
			OpenForm("Catalog.UsualActionReasons.ChoiceForm", New Structure("ChoiceMode", True), ThisObject, , , , New NotifyDescription("UsualActionReasonAfterUserChoice", ThisObject, New Structure("StatusArr", vStatusArr)), FormWindowOpeningMode.LockOwnerWindow);
			Return;
		EndIf;
		// Ask user to choose guarantee type
		vGuaranteeType = vStatusArr.GuaranteeType;
		If Not ValueIsFilled(vGuaranteeType) And vStatusArr.IsGuaranteed And vStatusArr.GuaranteeTypesCount > 0 Then
			OpenForm("Catalog.GuaranteeTypes.ChoiceForm", New Structure("ChoiceMode", True), ThisObject, , , , New NotifyDescription("GuaranteeTypeAfterUserChoice", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
			Return;
		EndIf;
		// Do change status
		ChangeStatusAtServer(vAnnulationReason, vGuaranteeType);
	EndIf;
EndProcedure // ChangeStatus

// -----------------------------------------------------------------------------
&AtClient
Procedure UsualActionReasonAfterUserChoice(pAnnulationReason, pExtraParams) Export
	If Not ValueIsFilled(pAnnulationReason) Then
		ShowMessageBox(,NStr("en='Annulation reason should be filled!'; ru='Причина аннуляции должна быть указана!'; de='Stornogrund gefüllt werden sollten!'"));
		Return;
	Else
		// Ask user to choose guarantee type
		vGuaranteeType = Undefined;
		If pExtraParams <> Undefined And pExtraParams.StatusArr.IsGuaranteed And pExtraParams.StatusArr.GuaranteeTypesCount > 0 Then
			OpenForm("Catalog.GuaranteeTypes.ChoiceForm", New Structure("ChoiceMode", True), ThisObject, , , , New NotifyDescription("GuaranteeTypeAfterUserChoice", ThisObject, New Structure("AnnulationReason", pAnnulationReason)), FormWindowOpeningMode.LockOwnerWindow);
			Return;
		EndIf;
		// Do change status
		ChangeStatusAtServer(pAnnulationReason, vGuaranteeType);
	EndIf;	
EndProcedure // UsualActionReasonAfterUserChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure GuaranteeTypeAfterUserChoice(pGuaranteeType, pExtraParams) Export
	If pGuaranteeType = Undefined Then
		ShowMessageBox(,NStr("ru='Вид гарантии должен быть выбран!';en='Guarantee type should be filled!';de='Art der Garantie sollte ausgefüllt werden!'"));
		Return;
	Else
		vAnnulationReason = Undefined;
		If pExtraParams <> Undefined Then
			vAnnulationReason = pExtraParams.AnnulationReason;
		EndIf;
		// Do change status
		ChangeStatusAtServer(vAnnulationReason, pGuaranteeType);
	EndIf;
EndProcedure // GuaranteeTypeAfterUserChoice	

// -----------------------------------------------------------------------------
&AtServer
Function GetCurrentStatus(pCommandName)
	vCommandName = pCommandName;
	If Right(vCommandName, 3) = "_CM" Then
		vCommandName = Left(vCommandName, StrLen(vCommandName) - 3);
	EndIf;
	vUUIDStr 		= Right(vCommandName, 36);
	vUUID 			= New UUID(StrReplace(vUUIDStr, "_", "-"));
	SelResStatus 	= Catalogs.ReservationStatuses.GetRef(vUUID);
	vStatusArr      = tcOnServer.cmGetAtributeAsArray(SelResStatus);
	vStatusArr.Insert("GuaranteeTypesCount",cmGetGuaranteeTypesCount());
	Return vStatusArr;
EndFunction // GetCurrentStatus

// -----------------------------------------------------------------------------
&AtClient
Procedure ReservListSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	vRowData = pItem.CurrentData;
	If vRowData <> Undefined And Not Items.ReservList.ChoiceMode Then
		pStandardProcessing = False;
		If pField.Name = "DocumentListGroupCode" And ValueIsFilled(vRowData.GuestGroup) Then
			OpenForm("Catalog.GuestGroups.Form.tcItemForm", New Structure("Key", vRowData.GuestGroup));
		Else
			vDocRef = GetRefToBeOpened(vRowData.Ref);
			If TypeOf(vDocRef) = Type("DocumentRef.Accommodation") Then
				// APDEX
				vKeyOperation = "Document.Accommodation.Form.tcDocumentForm.OpenForm";  
				vApdexRemarks = GetRemarksForAPDEX(vDocRef, True);
				APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, , vApdexRemarks);

				OpenForm("Document.Accommodation.ObjectForm", New Structure("Key", vDocRef));
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='The reservation has checked-in! Accommodation was opened...'; ru='Бронь заехала. Было открыто размещение...'; de='Die Reservierung ist angekommen. Unterkunft wurde eröffnet...'"));
			Else
				// APDEX
				vKeyOperation = "Document.Reservation.Form.tcDocumentForm.OpenForm";     
				vApdexRemarks = GetRemarksForAPDEX(vDocRef);
				APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, , vApdexRemarks);

				OpenForm("Document.Reservation.ObjectForm", New Structure("Key", vDocRef));
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ReservListSelection

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetRefToBeOpened(pResRef)
	vRef = pResRef;
	If ValueIsFilled(pResRef) Then
		vHotel = pResRef.Hotel;
		If pResRef.ReservationStatus = vHotel.CheckInReservationStatus Then
			vAccRef = cmGetAccommodationByReservation(pResRef);
			If ValueIsFilled(vAccRef) Then
				vRef = vAccRef;
			EndIf;
		EndIf;
	EndIf;
	Return vRef;
EndFunction // GetRefToBeOpened

// -----------------------------------------------------------------------------
&AtServer
Function GetClientIdentificationCardById(pIdentifier, pUseDeleted = False) 
    Return cmGetClientIdentificationCardById(pIdentifier, pUseDeleted);
EndFunction // GetClientIdentificationCardById

// -----------------------------------------------------------------------------
&AtServer
Function GetDiscountCardById(pIdentifier, pSearchMarkedForDeletion = False) 
	Return cmGetDiscountCardById(pIdentifier);
EndFunction // GetDiscountCardById

// -----------------------------------------------------------------------------
&AtServer
Function GetRoom(pCard) 
	Return pCard.Room;
EndFunction // GetRoom

// -----------------------------------------------------------------------------
&AtServer
Function GetClient(pCard) 
	Return pCard.Client;
EndFunction // GetClient

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintGuestRegistrationFormsForExpectedCheckIn(pCommand)
	vDocument = PredefinedValue("Document.Reservation.EmptyRef");
	vGuestGroup = PredefinedValue("Catalog.GuestGroups.EmptyRef");
	vObjPrtForm = tcOnServer.cmGetCatalogItemRefByName("ObjectPrintingForms", "ReservationPrintGuestRegistrationForm");
	vFrm = OpenForm("Document.Accommodation.Form.tcPrintGuestForm", New Structure("CheckInDate, Document, GuestGroup, ObjectPrintingForm", BegOfDay(CurrentDate()), vDocument, vGuestGroup, vObjPrtForm), ThisObject);
EndProcedure // PrintGuestRegistrationFormsForExpectedCheckIn

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeListMode(pCommand)
	ShowChooseFromMenu(New NotifyDescription("ListModesAfterChoice", ThisObject), ListModes, Items.ChangeListMode);
EndProcedure // ChangeListMode

// -----------------------------------------------------------------------------
&AtClient
Procedure ListModesAfterChoice(pItem, pExtraParameters) Export
	If pItem <> Undefined Then
		SelListMode = pItem.Value;
		SelListModesOnChange();
	EndIf;
EndProcedure // ChangeListMode

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetBalancesByRooms(pList)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reservations.Number AS Number,
	|	Reservations.Hotel AS Hotel
	|INTO ReservationList
	|FROM
	|	Document.Reservation AS Reservations
	|WHERE
	|	Reservations.Ref IN(&qList)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Accommodations.Ref AS Ref,
	|	Accommodations.Hotel AS Hotel,
	|	Accommodations.Number AS Number
	|INTO TabDocs
	|FROM
	|	Document.Accommodation AS Accommodations
	|		INNER JOIN ReservationList AS ReservationList
	|		ON Accommodations.Number = ReservationList.Number
	|			AND Accommodations.Hotel = ReservationList.Hotel
	|
	|UNION ALL
	|
	|SELECT
	|	Reservations.Ref,
	|	Reservations.Hotel,
	|	Reservations.Number
	|FROM
	|	Document.Reservation AS Reservations
	|		INNER JOIN ReservationList AS ReservationList
	|		ON Reservations.Number = ReservationList.Number
	|			AND Reservations.Hotel = ReservationList.Hotel
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Folio.Ref AS Ref,
	|	TabDocs.Number AS ParentDocNumber,
	|	ISNULL(Customers.IsIndividual, TRUE) AS IsIndividual
	|INTO FolioListByMainGuests
	|FROM
	|	Document.Folio AS Folio
	|		INNER JOIN TabDocs AS TabDocs
	|		ON Folio.ParentDoc = TabDocs.Ref
	|		LEFT JOIN Catalog.Customers AS Customers
	|		ON Folio.Customer = Customers.Ref
	|WHERE
	|	NOT Folio.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccountsBalance.FolioParentDocNumber AS DocNumber,
	|	SUM(AccountsBalance.ClientSumBalance) AS ClientSumBalance,
	|	SUM(AccountsBalance.ClientLimitBalance) AS ClientLimitBalance,
	|	SUM(AccountsBalance.CustomerSumBalance) AS CustomerSumBalance
	|FROM
	|	(SELECT
	|		FolioListByMainGuests.ParentDocNumber AS FolioParentDocNumber,
	|		CASE
	|			WHEN FolioListByMainGuests.IsIndividual
	|				THEN ClientAccountsBalance.SumBalance
	|			ELSE 0
	|		END AS ClientSumBalance,
	|		CASE
	|			WHEN FolioListByMainGuests.IsIndividual
	|				THEN -ClientAccountsBalance.LimitBalance
	|			ELSE 0
	|		END AS ClientLimitBalance,
	|		CASE
	|			WHEN FolioListByMainGuests.IsIndividual
	|				THEN 0
	|			ELSE ClientAccountsBalance.SumBalance
	|		END AS CustomerSumBalance
	|	FROM
	|		AccumulationRegister.Accounts.Balance(
	|				,
	|				FolioCurrency = Hotel.FolioCurrency
	|					AND Folio IN
	|						(SELECT
	|							FolioListByMainGuests.Ref AS Ref
	|						FROM
	|							FolioListByMainGuests AS FolioListByMainGuests)) AS ClientAccountsBalance
	|			INNER JOIN FolioListByMainGuests AS FolioListByMainGuests
	|			ON ClientAccountsBalance.Folio = FolioListByMainGuests.Ref) AS AccountsBalance
	|
	|GROUP BY
	|	AccountsBalance.FolioParentDocNumber";
	vQry.SetParameter("qList", pList);
	vBalances = vQry.Execute().Select();
	Return vBalances;
EndFunction // GetBalancesByRooms

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetBalancesByGuests(pList)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Folio.Ref AS Ref,
	|	Folio.ParentDoc AS ParentDoc,
	|	ISNULL(Customers.IsIndividual, TRUE) AS IsIndividual
	|INTO FolioListByAllGuests
	|FROM
	|	Document.Folio AS Folio
	|		LEFT JOIN Catalog.Customers AS Customers
	|		ON Folio.Customer = Customers.Ref
	|WHERE
	|	NOT Folio.DeletionMark
	|	AND Folio.ParentDoc IN (&qList)
	|
	|UNION
	|
	|SELECT
	|	Folio.Ref,
	|	Folio.ParentDoc,
	|	ISNULL(Customers.IsIndividual, TRUE)
	|FROM
	|	Document.Folio AS Folio
	|		LEFT JOIN Catalog.Customers AS Customers
	|		ON Folio.Customer = Customers.Ref
	|WHERE
	|	NOT Folio.DeletionMark
	|	AND CAST(Folio.ParentDoc AS Document.Accommodation).ParentDoc IN (&qList)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccountsBalance.FolioParentDoc AS DocRef,
	|	SUM(AccountsBalance.ClientSumBalance) AS ClientSumBalance,
	|	SUM(AccountsBalance.ClientLimitBalance) AS ClientLimitBalance,
	|	SUM(AccountsBalance.CustomerSumBalance) AS CustomerSumBalance
	|FROM
	|	(SELECT
	|		FolioListByAllGuests.ParentDoc AS FolioParentDoc,
	|		CASE
	|			WHEN FolioListByAllGuests.IsIndividual
	|				THEN ClientAccountsBalance.SumBalance
	|			ELSE 0
	|		END AS ClientSumBalance,
	|		CASE
	|			WHEN FolioListByAllGuests.IsIndividual
	|				THEN -ClientAccountsBalance.LimitBalance
	|			ELSE 0
	|		END AS ClientLimitBalance,
	|		CASE
	|			WHEN FolioListByAllGuests.IsIndividual
	|				THEN 0
	|			ELSE ClientAccountsBalance.SumBalance
	|		END AS CustomerSumBalance
	|	FROM
	|		AccumulationRegister.Accounts.Balance(
	|				,
	|				FolioCurrency = Hotel.FolioCurrency
	|					AND Folio IN
	|						(SELECT
	|							FolioListByAllGuests.Ref AS Ref
	|						FROM
	|							FolioListByAllGuests AS FolioListByAllGuests)) AS ClientAccountsBalance
	|			INNER JOIN FolioListByAllGuests AS FolioListByAllGuests
	|			ON ClientAccountsBalance.Folio = FolioListByAllGuests.Ref) AS AccountsBalance
	|
	|GROUP BY
	|	AccountsBalance.FolioParentDoc";
	vQry.SetParameter("qList", pList);
	vBalances = vQry.Execute().Select();
	vBalances.Reset();
	Return vBalances;
EndFunction // GetBalancesByGuests

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure ReservListOnGetDataAtServer(pItemName, pSettings, pRows)
	// Balances
	vSelShowAllGuests = pSettings.DataParameters.FindParameterValue(New DataCompositionParameter("qShowAllGuests"));
	vSelShowAllGuests = ?(vSelShowAllGuests = Undefined, 0, vSelShowAllGuests.Value);
	vBalancesAreVisible = pSettings.DataParameters.FindParameterValue(New DataCompositionParameter("qBalancesAreVisible"));
	vBalancesAreVisible = ?(vBalancesAreVisible = Undefined, False, vBalancesAreVisible.Value);
	vBalances = Undefined;
	If vBalancesAreVisible Then
		vList = pRows.GetKeys();
		If vSelShowAllGuests = 0 Then
			vBalances = GetBalancesByRooms(vList);
		Else
			vBalances = GetBalancesByGuests(vList);
		EndIf;
	EndIf;
	
	// Color to merge one room guests
	vMergeColor = New Color(233, 240, 255);
	
	// Rows color of one room guests should be the same
	If vSelShowAllGuests Then
		// Build table of documents to be shown
		vSortBy = "";
		vDocumentsToShow = New ValueTable();
		vDocumentsToShow.Columns.Add("Ref", cmGetDocumentTypeDescription("Reservation"));
		vDocumentsToShow.Columns.Add("RefNumber", cmGetStringTypeDescription(12));
		For Each vOrderItem In pSettings.Order.Items Do
			If vOrderItem.Use Then
				vSortField = String(vOrderItem.Field);
				If vSortField <> "Ref" And vSortField <> "RefNumber" Then
					vDocumentsToShow.Columns.Add(vSortField);
					vSortBy = vSortBy + ?(IsBlankString(vSortBy), "", ", ") + vSortField + ?(vOrderItem.OrderType = DataCompositionSortDirection.Desc, " Desc", "");
				EndIf;
			EndIf;
		EndDo;
		vSortBy = vSortBy + ?(IsBlankString(vSortBy), "", ", ") + "Ref";
		For Each vRow In pRows Do
			vRowValue = vRow.Value;
			vDocumentsToShowRow = vDocumentsToShow.Add();
			For Each vDocumentsToShowColumn In vDocumentsToShow.Columns Do
				vDocumentsToShowRow[vDocumentsToShowColumn.Name] = vRowValue.Data[vDocumentsToShowColumn.Name];
			EndDo;
		EndDo;
		vDocumentsToShow.Indexes.Add("Ref");
		vDocumentsToShow.Columns.Add("RowColorIndex", cmGetNumberTypeDescription(1, 0));

		// Restore first and last documents and color indexes
		vFRow = Undefined;
		vLRow = Undefined;
		vFRowWasAdded = False;
		vLRowWasAdded = False;
		If vDocumentsToShow.Count() > 0 Then
			vFRowStruct = SystemSettingsStorage.Load("Document.Reservation.Form.tcReservationListForm", "FirstDocInBatch");
			If vFRowStruct <> Undefined Then
				vFRow = vDocumentsToShow.Find(vFRowStruct.Ref, "Ref");
				If vFRow = Undefined Then
					vFRow = vDocumentsToShow.Add();
					vFRowWasAdded = True;
				EndIf;
				FillPropertyValues(vFRow, vFRowStruct);
			EndIf;

			vLRowStruct = SystemSettingsStorage.Load("Document.Reservation.Form.tcReservationListForm", "LastDocInBatch");
			If vLRowStruct <> Undefined Then
				vLRow = vDocumentsToShow.Find(vLRowStruct.Ref, "Ref");
				If vLRow = Undefined Then
					vLRow = vDocumentsToShow.Add();
					vLRowWasAdded = True;
				EndIf;
				FillPropertyValues(vLRow, vLRowStruct);
			EndIf;
		EndIf;

		// Sort documents list		
		vDocumentsToShow.Sort(vSortBy);
		
		// Fill row color index
		vCurRowColorIndex = 0;
		vCurRefNumber = "";
		If vFRow <> Undefined And vDocumentsToShow.IndexOf(vFRow) > 0 And vDocumentsToShow.IndexOf(vFRow) < (vDocumentsToShow.Count() - 1) Then
			i = vDocumentsToShow.IndexOf(vFRow);
			While i >= 0 Do
				vDocumentsToShowRow = vDocumentsToShow.Get(i);
				If vCurRefNumber <> vDocumentsToShowRow.RefNumber Then
					vCurRefNumber = vDocumentsToShowRow.RefNumber;
					If vCurRowColorIndex = 0 And vDocumentsToShowRow.RowColorIndex <> 0 Then
						vCurRowColorIndex = vDocumentsToShowRow.RowColorIndex;
					Else
						vCurRowColorIndex = ?(vCurRowColorIndex < 2, 2, 1);
					EndIf;
				EndIf;
				vDocumentsToShowRow.RowColorIndex = vCurRowColorIndex;
				i = i - 1;
			EndDo;
			If vDocumentsToShow.IndexOf(vFRow) < (vDocumentsToShow.Count() - 1) Then
				vCurRowColorIndex = 0;
				vCurRefNumber = "";
				i = vDocumentsToShow.IndexOf(vFRow);
				While i < vDocumentsToShow.Count() Do
					vDocumentsToShowRow = vDocumentsToShow.Get(i);
					If vCurRefNumber <> vDocumentsToShowRow.RefNumber Then
						vCurRefNumber = vDocumentsToShowRow.RefNumber;
						If vCurRowColorIndex = 0 And vDocumentsToShowRow.RowColorIndex <> 0 Then
							vCurRowColorIndex = vDocumentsToShowRow.RowColorIndex;
						Else
							vCurRowColorIndex = ?(vCurRowColorIndex < 2, 2, 1);
						EndIf;
					EndIf;
					vDocumentsToShowRow.RowColorIndex = vCurRowColorIndex;
					i = i + 1;
				EndDo;
			EndIf;
		ElsIf vLRow <> Undefined And vDocumentsToShow.IndexOf(vLRow) > 0 And vDocumentsToShow.IndexOf(vLRow) <= (vDocumentsToShow.Count() - 1) Then
			i = vDocumentsToShow.IndexOf(vLRow);
			While i >= 0 Do
				vDocumentsToShowRow = vDocumentsToShow.Get(i);
				If vCurRefNumber <> vDocumentsToShowRow.RefNumber Then
					vCurRefNumber = vDocumentsToShowRow.RefNumber;
					If vCurRowColorIndex = 0 And vDocumentsToShowRow.RowColorIndex <> 0 Then
						vCurRowColorIndex = vDocumentsToShowRow.RowColorIndex;
					Else
						vCurRowColorIndex = ?(vCurRowColorIndex < 2, 2, 1);
					EndIf;
				EndIf;
				vDocumentsToShowRow.RowColorIndex = vCurRowColorIndex;
				i = i - 1;
			EndDo;
			If vDocumentsToShow.IndexOf(vLRow) < (vDocumentsToShow.Count() - 1) Then
				vCurRowColorIndex = 0;
				vCurRefNumber = "";
				i = vDocumentsToShow.IndexOf(vLRow);
				While i < vDocumentsToShow.Count() Do
					vDocumentsToShowRow = vDocumentsToShow.Get(i);
					If vCurRefNumber <> vDocumentsToShowRow.RefNumber Then
						vCurRefNumber = vDocumentsToShowRow.RefNumber;
						If vCurRowColorIndex = 0 And vDocumentsToShowRow.RowColorIndex <> 0 Then
							vCurRowColorIndex = vDocumentsToShowRow.RowColorIndex;
						Else
							vCurRowColorIndex = ?(vCurRowColorIndex < 2, 2, 1);
						EndIf;
					EndIf;
					vDocumentsToShowRow.RowColorIndex = vCurRowColorIndex;
					i = i + 1;
				EndDo;
			EndIf;
		Else
			i = 0;
			While i < vDocumentsToShow.Count() Do
				vDocumentsToShowRow = vDocumentsToShow.Get(i);
				If vCurRefNumber <> vDocumentsToShowRow.RefNumber Then
					vCurRefNumber = vDocumentsToShowRow.RefNumber;
					If vCurRowColorIndex = 0 And vDocumentsToShowRow.RowColorIndex <> 0 Then
						vCurRowColorIndex = vDocumentsToShowRow.RowColorIndex;
					Else
						vCurRowColorIndex = ?(vCurRowColorIndex < 2, 2, 1);
					EndIf;
				EndIf;
				vDocumentsToShowRow.RowColorIndex = vCurRowColorIndex;
				i = i + 1;
			EndDo;
		EndIf;

		// Save first and last documents and color indexes
		If vDocumentsToShow.Count() > 0 Then
			If vFRowWasAdded Then
				vDocumentsToShow.Delete(vFRow);
			EndIf;
			If vLRowWasAdded Then
				vDocumentsToShow.Delete(vLRow);
			EndIf;
			
			vListColumns = StrReplace(vSortBy, " Desc", "") + ", RefNumber, RowColorIndex";
			
			vFRow = vDocumentsToShow.Get(0);
			vFRowStruct = New Structure(vListColumns);
			FillPropertyValues(vFRowStruct, vFRow);
			SystemSettingsStorage.Save("Document.Reservation.Form.tcReservationListForm", "FirstDocInBatch", vFRowStruct);

			vLRow = vDocumentsToShow.Get(vDocumentsToShow.Count() - 1);
			vLRowStruct = New Structure(vListColumns);
			FillPropertyValues(vLRowStruct, vLRow);
			SystemSettingsStorage.Save("Document.Reservation.Form.tcReservationListForm", "LastDocInBatch", vLRowStruct);
		EndIf;
	EndIf;
	
	// Cell colors and other appearances
	For Each vRow In pRows Do
		vRowValue = vRow.Value;
		vDocRef = vRowValue.Data.Ref;
		vDocNumber = vRowValue.Data.RefNumber;
		// Make color of one room guests to be the same
		vRowColorIndex = 0;
		If vSelShowAllGuests Then
			vDocumentsToShowRow = vDocumentsToShow.Find(vDocRef, "Ref");
			If vDocumentsToShowRow <> Undefined Then
				vRowColorIndex = vDocumentsToShowRow.RowColorIndex;
			EndIf;
		Else
			vRowColorIndex = 0;
		EndIf;
		vRowValue.Data["RowColorIndex"] = vRowColorIndex;
		// Row backgound
		If vSelShowAllGuests Then
			If vRowValue.Data["RowColorIndex"] = 1 Then
				For Each vAppearanceItem In vRowValue.Appearance Do
					vAppearanceItem.Value.SetParameterValue("BackColor", WebColors.White);
				EndDo;
			ElsIf vRowValue.Data["RowColorIndex"] = 2 Then
				For Each vAppearanceItem In vRowValue.Appearance Do
					vAppearanceItem.Value.SetParameterValue("BackColor", vMergeColor);
				EndDo;
			EndIf;
		EndIf;
		// Balances
		If vBalancesAreVisible Then
			If vBalances <> Undefined Then
				If vSelShowAllGuests = 0 Then
					vBalances.Reset();
					If vBalances.FindNext(New Structure("DocNumber", vDocNumber)) Then
						vRowValue.Data["ClientSumBalance"] = vBalances.ClientSumBalance;
						vRowValue.Data["CustomerSumBalance"] = vBalances.CustomerSumBalance;
						vRowValue.Data["ClientLimitBalance"] = vBalances.ClientLimitBalance;
					EndIf;
				Else
					vBalances.Reset();
					If vBalances.FindNext(New Structure("DocRef", vDocRef)) Then
						vRowValue.Data["ClientSumBalance"] = vBalances.ClientSumBalance;
						vRowValue.Data["CustomerSumBalance"] = vBalances.CustomerSumBalance;
						vRowValue.Data["ClientLimitBalance"] = vBalances.ClientLimitBalance;
					EndIf;
				EndIf;
			EndIf;
			If vRowValue.Data["ClientLimitBalance"] <> 0 Then
				vClientSumBalanceAppearance = vRowValue.Appearance.Get("ClientSumBalance");
				If vClientSumBalanceAppearance <> Undefined Then
					vBalanceText = Format(vRowValue.Data["ClientSumBalance"], "NFD=2") + Chars.LF + Format(-vRowValue.Data["ClientLimitBalance"], "NFD=2");
					vClientSumBalanceAppearance.SetParameterValue("Text", vBalanceText);
					If (vRowValue.Data["ClientSumBalance"] - vRowValue.Data["ClientLimitBalance"]) <= 0 Then
						vClientSumBalanceAppearance.SetParameterValue("TextColor", WebColors.Green);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		// Add block description
		vGuestFullNameAppearance = vRowValue.Appearance.Get("GuestFullName");
		If vGuestFullNameAppearance <> Undefined Then
			vGuestFullNameText = TrimAll(vRowValue.Data["GuestFullName"]);
			vRoomQuantity = vRowValue.Data["RoomQuantity"];
			If vRoomQuantity > 1 Then
				vAccommodationTemplate = vRowValue.Data["AccommodationTemplate"];
				If ValueIsFilled(vAccommodationTemplate) Then
					vBlockText = NStr("en='Q-ty: '; ru='Кол-во: '; de='Q-ti: '") + Format(vRoomQuantity, "NFD=0; NG=");
					vGuestFullNameText = vBlockText + ?(IsBlankString(vGuestFullNameText), "", ", " + vGuestFullNameText);
					vGuestFullNameAppearance.SetParameterValue("Text", vGuestFullNameText);
					vFontParam = vGuestFullNameAppearance.FindParameterValue(New DataCompositionParameter("Font"));
					If vFontParam <> Undefined Then
						vGuestGroupAppearance = vRowValue.Appearance.Get("GuestGroup");
						If vGuestGroupAppearance <> Undefined Then
							vGuestGroupAppearance.SetParameterValue("Font", vFontParam.Value);
						EndIf;
						vReservationStatusAppearance = vRowValue.Appearance.Get("ReservationStatus");
						If vReservationStatusAppearance <> Undefined Then
							vReservationStatusAppearance.SetParameterValue("Font", vFontParam.Value);
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		// Set cell back color for the reservations according to the customer colors
		vCustomerColorHexString = TrimAll(vRowValue.Data["CustomerColorHexString"]);
		If Not IsBlankString(vCustomerColorHexString) Then
			vCustomerAppearance = vRowValue.Appearance.Get("Customer");
			If vCustomerAppearance <> Undefined Then
				vColor = tcOnServer.HexToColor(vCustomerColorHexString);
				vCustomerAppearance.SetParameterValue("BackColor", vColor);
			EndIf;
		EndIf;
		// Set cell back color for the reservations according to the contract colors
		vContractColorHexString = TrimAll(vRowValue.Data["ContractColorHexString"]);
		If Not IsBlankString(vContractColorHexString) Then
			vContractAppearance = vRowValue.Appearance.Get("Contract");
			If vContractAppearance <> Undefined Then
				vColor = tcOnServer.HexToColor(vContractColorHexString);
				vContractAppearance.SetParameterValue("BackColor", vColor);
			EndIf;
		EndIf;
		// Set cell back color for the reservations according to the agent colors
		vAgentColorHexString = TrimAll(vRowValue.Data["AgentColorHexString"]);
		If Not IsBlankString(vAgentColorHexString) Then
			vAgentAppearance = vRowValue.Appearance.Get("Agent");
			If vAgentAppearance <> Undefined Then
				vColor = tcOnServer.HexToColor(vAgentColorHexString);
				vAgentAppearance.SetParameterValue("BackColor", vColor);
			EndIf;
		EndIf;
		// Set cell back color for the reservations according to the room quota colors
		vRoomQuotaColorHexString = TrimAll(vRowValue.Data["RoomQuotaColorHexString"]);
		If Not IsBlankString(vRoomQuotaColorHexString) Then			
			vRoomQuotaAppearance = vRowValue.Appearance.Get("RoomQuota");
			If vRoomQuotaAppearance <> Undefined Then
				vColor = tcOnServer.HexToColor(vRoomQuotaColorHexString);
				vRoomQuotaAppearance.SetParameterValue("BackColor", vColor);
			EndIf;
		EndIf;
		// Set cell back color for the reservations according to the guest group colors
		vGuestGroupColorHexString = TrimAll(vRowValue.Data["GuestGroupColorHexString"]);
		If Not IsBlankString(vGuestGroupColorHexString) Then
			vGuestGroupAppearance = vRowValue.Appearance.Get("GuestGroup");
			If vGuestGroupAppearance <> Undefined Then
				vColor = tcOnServer.HexToColor(vGuestGroupColorHexString);
				vGuestGroupAppearance.SetParameterValue("BackColor", vColor);
			EndIf;
		EndIf;
		// Set cell back color for the reservations according to the reservation status
		vReservationStatusColorHexString = TrimAll(vRowValue.Data["ReservationStatusColorHexString"]);
		If Not IsBlankString(vReservationStatusColorHexString) Then
			vReservationStatusAppearance = vRowValue.Appearance.Get("ReservationStatus");
			vGuaranteeTypeCodeAppearance = vRowValue.Appearance.Get("GuaranteeTypeCode");
			If vReservationStatusAppearance <> Undefined Or vGuaranteeTypeCodeAppearance <> Undefined Then
				vColor = tcOnServer.HexToColor(vReservationStatusColorHexString);
				If vReservationStatusAppearance <> Undefined Then
					vReservationStatusAppearance.SetParameterValue("BackColor", vColor);
				EndIf;
				If vGuaranteeTypeCodeAppearance <> Undefined Then
					vGuaranteeTypeCodeAppearance.SetParameterValue("BackColor", vColor);
				EndIf;
			EndIf;
		EndIf;
		// Set cell back color for the reservations according to the discount card discount type colors
		vDCDTColorHexString = TrimAll(vRowValue.Data["DiscountCardDiscountTypeColorHexString"]);
		If Not IsBlankString(vDCDTColorHexString) Then			
			vDCDTAppearance = vRowValue.Appearance.Get("DiscountCardDiscountType");
			If vDCDTAppearance <> Undefined Then
				vColor = tcOnServer.HexToColor(vDCDTColorHexString);
				vDCDTAppearance.SetParameterValue("BackColor", vColor);
			EndIf;
		EndIf;
		// Set cell back color for the reservations according to the discount card discount type colors
		vClientTypeColorHexString = TrimAll(vRowValue.Data["ClientTypeColorHexString"]);
		If Not IsBlankString(vClientTypeColorHexString) Then
			vClientTypeAppearance = vRowValue.Appearance.Get("ClientTypeCode");
			If vClientTypeAppearance <> Undefined Then
				vColor = tcOnServer.HexToColor(vClientTypeColorHexString);
				vClientTypeAppearance.SetParameterValue("BackColor", vColor);
			EndIf;
		EndIf;
	EndDo;
EndProcedure // ReservListOnGetDataAtServer

// ------------------------------------------------------------------------------------------------
&AtServerNoContext
Function GetClientDataScanDocument(pDocRef)
	vDoc = Undefined;
	// Run query to check whether client data scans were already created
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	ClientDataScans.Ref
	|FROM
	|	Document.ClientDataScans AS ClientDataScans
	|WHERE
	|	ClientDataScans.ParentDoc = &qParentDoc
	|	AND (ClientDataScans.Guest = &qClient
	|			OR &qClientIsEmpty)
	|	AND NOT ClientDataScans.DeletionMark
	|
	|ORDER BY
	|	ClientDataScans.Posted DESC,
	|	ClientDataScans.PointInTime DESC";
	vQry.SetParameter("qParentDoc", pDocRef);
	vQry.SetParameter("qClient", pDocRef.Guest);
	vQry.SetParameter("qClientIsEmpty", Not ValueIsFilled(pDocRef.Guest));
	vDocs = vQry.Execute().Unload();
	If vDocs.Count() > 0 Then
		vDoc = vDocs.Get(0).Ref;
	ElsIf ValueIsFilled(pDocRef.Guest) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT TOP 1
		|	ClientDataScans.Ref
		|FROM
		|	Document.ClientDataScans AS ClientDataScans
		|WHERE
		|	ClientDataScans.Guest = &qClient
		|	AND ClientDataScans.Hotel = &qHotel
		|	AND NOT ClientDataScans.DeletionMark
		|
		|ORDER BY
		|	ClientDataScans.Posted DESC,
		|	ClientDataScans.PointInTime DESC";
		vQry.SetParameter("qClient", pDocRef.Guest);
		vQry.SetParameter("qHotel", pDocRef.Hotel);
		vDocs = vQry.Execute().Unload();
		If vDocs.Count() > 0 Then
			vDoc = vDocs.Get(0).Ref;
		EndIf;
	EndIf;
	Return vDoc;
EndFunction // GetClientDataScanDocument

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetAccommodationByReservation(pRef)
	Return cmGetAccommodationByReservation(pRef);
EndFunction // GetAccommodationByReservation 

// -----------------------------------------------------------------------------
&AtClient
Procedure ScanDocuments(pCommand)
	vCurData = Items.ReservList.CurrentData;
	If vCurData <> Undefined Then
		vRef = vCurData.Ref;
		If ValueIsFilled(vRef) Then
			// Check if there is accommodation for this reservation
			If TypeOf(vRef) = Type("DocumentRef.Reservation") Then
				vAccRef = GetAccommodationByReservation(vRef);
				If ValueIsFilled(vAccRef) Then
					vRef = vAccRef;
				EndIf;
			EndIf;
			// Try to find existing client data scan document
			vScanRef = GetClientDataScanDocument(vRef);
			If ValueIsFilled(vScanRef) Then
				vRefArr = tcOnServer.cmGetAtributeAsArray(vRef);
				OpenForm("Document.ClientDataScans.ObjectForm", New Structure("Key, Guest, ParentDoc, GuestGroup, Room", vScanRef, vRefArr.Guest, vRef, vRefArr.GuestGroup, vRefArr.Room), ThisObject, vRef);
			Else
				OpenForm("Document.ClientDataScans.ObjectForm", New Structure("basis", vRef), ThisObject, vRef);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ScanDocuments

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenChangeHistory(pCommand)
	vRowData = Items.ReservList.CurrentData;
	If vRowData <> Undefined Then
		vFrm = OpenForm("InformationRegister.ReservationChangeHistory.ListForm", New Structure("Filter", New Structure("Reservation", vRowData.Ref)), ThisObject, vRowData.Ref);
		vFrm.ReadOnly = ReadOnly;
	EndIf;
EndProcedure // OpenChangeHistory

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenInHouseGuests(pCommand)
	vRowData = Items.ReservList.CurrentData;
	If vRowData <> Undefined Then
		// APDEX
		vKeyOperation = "Document.Accommodation.Form.tcAccommodationListForm.InHouseGuests.OpenForm";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

		OpenForm("Document.Accommodation.Form.tcAccommodationListForm", New Structure("SelGuestGroup, SelFilterStatus, SelShowAllGuests", vRowData.GuestGroup, 0, SelShowAllGuests), ThisObject, vRowData.GuestGroup);
	EndIf;
EndProcedure // OpenInHouseGuests

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenProformaInvoiceList(pCommand)
	vRowData = Items.ReservList.CurrentData;
	If vRowData <> Undefined Then
		OpenForm("Document.ProformaInvoice.Form.tcListForm", New Structure("SelGuestGroup", vRowData.GuestGroup), ThisObject, vRowData.GuestGroup);
	EndIf;
EndProcedure // OpenProformaInvoiceList

// -----------------------------------------------------------------------------
&AtServer
Procedure FillFunctionsButton()
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	ObjectFormActions.Ref,
	|	ObjectFormActions.Code AS Code,
	|	ObjectFormActions.PredefinedDataName,
	|	ObjectFormActions.IsDefault AS IsDefault
	|FROM
	|	Catalog.ObjectFormActions AS ObjectFormActions
	|WHERE
	|	NOT ObjectFormActions.DeletionMark
	|	AND ObjectFormActions.ObjectType = &ObjectType
	|	AND ObjectFormActions.IsActive = TRUE
	|
	|ORDER BY
	|	IsDefault DESC,
	|	Code";
	vQuery.SetParameter("ObjectType", Documents.Reservation.EmptyRef());	
	vQueryResult = vQuery.Execute();	
	vSelectionRecords = vQueryResult.Select();
	Actions.Clear();
	While vSelectionRecords.Next() Do
		If vSelectionRecords.PredefinedDataName = "" 
			or vSelectionRecords.PredefinedDataName = "ReservationSendMyFolioSMS"
			or vSelectionRecords.PredefinedDataName = "ReservationFillOrder"
			or vSelectionRecords.PredefinedDataName = "ReservationGuestGroupFillInvoice" 
			or vSelectionRecords.PredefinedDataName = "ReservationFillInvoice" Then
			vNewRow = Actions.Add();
			vNewRow.Action = vSelectionRecords.Ref;
			vNewRow.IsDefault = vSelectionRecords.IsDefault;
			
			vID = vNewRow.GetID();
			
			vCommand = Commands.Add("Func"+vID);
			vCommand.Action = "FuncButtonClick";
			If vSelectionRecords.IsDefault Then
				vStructure = New Structure("Title,CommandName",
				TrimAll(vSelectionRecords.Code) + " " + cmNStr(vSelectionRecords.ref), "Func"+vID);
			Else
				vStructure = New Structure("Title,CommandName",
				TrimAll(vSelectionRecords.Code) + " " + cmNStr(vSelectionRecords.ref), "Func"+vID);
			EndIf;
			
			tcOnServer.cmCreateItem(ThisObject, ?(vSelectionRecords.IsDefault, Items.FormGroupFunctionsDefault, Items.FormGroupFunctionsNotDefault), "Func"+vID, "FormButton", vStructure);
			tcOnServer.cmCreateItem(ThisObject, ?(vSelectionRecords.IsDefault, Items.FormGroupFunctionsDefault1, Items.FormGroupFunctionsNotDefault1), "Func_1_"+vID, "FormButton", vStructure);
		EndIf;
	EndDo;
EndProcedure // FillFunctionsButton

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure DuplicateProformaInvoiceForTheGroupAnswer(pAnswer, pExtraParams) Export
	If pAnswer = DialogReturnCode.Yes And ValueIsFilled(pExtraParams.LastProforma) Then
		OpenForm("Document.ProformaInvoice.ObjectForm", New Structure("Key", pExtraParams.LastProforma), , pExtraParams.LastProforma);
	ElsIf pAnswer = DialogReturnCode.No Then
		OpenNewProformaInvoiceForm(pExtraParams.GuestGroup);
	EndIf;
EndProcedure // DuplicateProformaInvoiceForTheGroupAnswer

// ------------------------------------------------------------------------------------------------
&AtServerNoContext
Function GetLastProformaForTheGroup(pGuestGroup)
	Return cmGetLastProformaForTheGroup(pGuestGroup);
EndFunction // GetLastProformaForTheGroup

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure OpenNewProformaInvoiceForm(pGuestGroup)
	vParam = New Structure;
	vParam.Insert("basis", pGuestGroup);
	OpenForm("Document.ProformaInvoice.Form.tcDocumentForm", vParam, ThisObject, True);
EndProcedure // OpenNewProformaInvoiceForm

// -----------------------------------------------------------------------------
&AtClient
Procedure FuncButtonClick(Command)
	vRowData = Items.ReservList.CurrentData;
	If vRowData <> Undefined Then
		vActionsNumber = StrReplace(Command.Name, "Func", "");
		vAction = GetActionForNumber(vActionsNumber);
		
		If ValueIsFilled(vAction.ExternalProcessing) Then
		Else
			If vAction.PredefinedDataName = "ReservationFillSettlement" Then
				// ReservationFillSettlement(vAction, pIsInAutomaticMode, pDocObj);
			ElsIf vAction.PredefinedDataName = "ReservationGuestGroupFillSettlement" Then
				// ReservationGuestGroupFillSettlement(vAction, pIsInAutomaticMode);
			ElsIf vAction.PredefinedDataName = "ReservationFillInvoice" Then
				vParam = New Structure;
				vParam.Insert("basis", vRowData.Ref);
				OpenForm("Document.ProformaInvoice.Form.tcDocumentForm", vParam, ThisObject, True);	
			ElsIf vAction.PredefinedDataName = "ReservationGuestGroupFillInvoice" Then
				vLastProformaForTheGroup = GetLastProformaForTheGroup(vRowData.GuestGroup);
				If ValueIsFilled(vLastProformaForTheGroup) Then
					ShowQueryBox(New NotifyDescription("DuplicateProformaInvoiceForTheGroupAnswer", ThisObject, New Structure("LastProforma, GuestGroup", vLastProformaForTheGroup, vRowData.GuestGroup)), 
					             NStr("en='The booking already has the '; ru='По брони уже есть '; de='Die Buchung hat bereits eine '") + TrimAll(vLastProformaForTheGroup) + "!" + Chars.LF + 
								 NStr("en='Answer <Yes> to open this proforma invoice. You can recalculate proforma if reservation amount has changed later in the form.';
								      |ru='Ответьте <Да>, чтобы открыть существующий счет. Если сумма бронирования изменилась, то можете пересчитать счет.'; 
									  |de='Antworten Sie mit <Ja>, um diese Proforma-Rechnung zu öffnen. Sie können die Proforma neu berechnen, wenn sich der Reservierungsbetrag später im Formular geändert hat.'") + Chars.LF +
								 NStr("en='Answer <No> to create new proforma invoice for this reservation.'; 
								      |ru='Ответьте <Нет>, чтобы создать новый счет на оплату для этого бронирования.'; 
									  |de='Antworten Sie mit <Nein>, um eine neue Proforma-Rechnung für diese Reservierung zu erstellen.'"), 
								 QuestionDialogMode.YesNoCancel, , DialogReturnCode.Yes);
				Else
					OpenNewProformaInvoiceForm(vRowData.GuestGroup);
				EndIf;
			ElsIf vAction.PredefinedDataName = "ReservationGuestGroupShowInvoices" Then
				// ReservationGuestGroupShowInvoices(vAction, pIsInAutomaticMode);
			ElsIf vAction.PredefinedDataName = "ReservationFillAccommodation" Then
				// ReservationFillAccommodation(vAction, pIsInAutomaticMode, pDocObj);
			ElsIf vAction.PredefinedDataName = "ReservationCheckInGuestGroup" Then
				// ReservationCheckInGuestGroup(vAction, pIsInAutomaticMode);
			ElsIf vAction.PredefinedDataName = "ReservationChangeGuestGroup" Then
				// ReservationChangeGuestGroup(vAction, pIsInAutomaticMode);
			ElsIf vAction.PredefinedDataName = "ReservationGuestGroupFillIssueHotelProducts "Then
				// ReservationGuestGroupFillIssueHotelProducts(vAction, pIsInAutomaticMode);
			ElsIf vAction.PredefinedDataName = "ReservationFillIssueHotelProducts" Then
				// ReservationFillIssueHotelProducts(vAction, pIsInAutomaticMode, pDocObj);
			ElsIf vAction.PredefinedDataName = "ReservationCopyGuestGroupReservations" Then
				// ReservationCopyGuestGroupReservations(vAction, pIsInAutomaticMode);
			ElsIf vAction.PredefinedDataName = "ReservationPrintCoupons" Then
				// ReservationPrintCoupons(vAction, ?(pDocObj = Undefined, GetCurrentDocument(), pDocObj.Ref), pIsInAutomaticMode);
			ElsIf vAction.PredefinedDataName = "ReservationPrintRoomCoupons" Then
				// ReservationPrintCoupons(vAction, ?(pDocObj = Undefined, Room, pDocObj.Room), pIsInAutomaticMode);
			ElsIf vAction.PredefinedDataName = "ReservationPrintGuestGroupCoupons" Then
				// ReservationPrintCoupons(vAction, ?(pDocObj = Undefined, GuestGroup, pDocObj.GuestGroup), pIsInAutomaticMode);
			ElsIf vAction.PredefinedDataName = "ReservationSendMyFolioSMS" Then
				SendWelcomeSMS(Commands.SendWelcomeToMyFolioSystemSMS);
			ElsIf vAction.PredefinedDataName = "ReservationEventFillInvoice" Then
				// ReservationEventFillInvoice(vAction, pIsInAutomaticMode);
			ElsIf vAction.PredefinedDataName = "ReservationFillOrder" Then
				vParam = New Structure;
				vParam.Insert("basis", vRowData.Ref);
				OpenForm("Document.Order.Form.DocumentForm", vParam, ThisObject, True);
			// Run data processor
			ElsIf ValueIsFilled(vAction.DataProcessor) Then     
				vReturnParameter = New Structure("Action, Data, FileName");
				If Not RunDataProcessor(vAction.DataProcessor, vRowData.Ref, True, vReturnParameter) Then
					ShowMessageBox(, NStr("en='Failed to run data processor!';ru='Не удалось выполнить обработку!';de='Die Bearbeitung ist fehlgeschlagen!'"));
				Else
					If vReturnParameter <> Undefined And TypeOf(vReturnParameter) = Type("Structure") Then
						If vReturnParameter.Property("Action") And vReturnParameter.Action <> Undefined Then
							If vReturnParameter.Action = "ShowFile" Then
								vFileData = vReturnParameter.Data;
								GetFromTempStorage(vFileData).Write(TempFilesDir() + vReturnParameter.FileName);
								BeginRunningApplication(New NotifyDescription, TempFilesDir() + vReturnParameter.FileName);
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			Else
				ShowMessageBox(, NStr("en='No data processor found for action!';ru='У действия не указан обработчик!';de='Bei der Aktion ist kein Bearbeiter angegeben!'"));
			EndIf;
		EndIf;   
	EndIf;   
EndProcedure // FuncButtonClick

// -----------------------------------------------------------------------------
&AtServer
Function GetActionForNumber(pActionsNumber)
	vActions = Actions.FindByID(Number(pActionsNumber)).Action;
	
	vStruct = New Structure();
	vStruct.Insert("Ref",vActions);
	vStruct.Insert("PredefinedDataName",vActions.PredefinedDataName);	
	vStruct.Insert("ExternalProcessing",vActions.ExternalProcessing);
	vStruct.Insert("DataProcessor",vActions.DataProcessor);
	
	Return vStruct;
EndFunction // GetActionForNumber

// -----------------------------------------------------------------------------
&AtServer
Function RunDataProcessor(pDataProcessor, pParameter, pIsInteractive = False, rReturnParameter)
	vPARAM = New Structure("InputParameter, OutputParameter", pParameter, rReturnParameter);
	vResult = cmRunDataProcessor(pDataProcessor, vPARAM, pIsInteractive);
	rReturnPameter = vPARAM.OutputParameter;
	Return vResult;
EndFunction // RunDataProcessor

// -----------------------------------------------------------------------------
&AtServer
Procedure FillPrintingButton()
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	ObjectPrintingForms.Ref,
	|	ObjectPrintingForms.Code AS Code,
	|	ObjectPrintingForms.PredefinedDataName,
	|	ObjectPrintingForms.IsDefault AS IsDefault,
	|	ObjectPrintingForms.Language AS Language
	|FROM
	|	Catalog.ObjectPrintingForms AS ObjectPrintingForms
	|WHERE
	|	NOT ObjectPrintingForms.DeletionMark
	|	AND ObjectPrintingForms.IsActive = TRUE
	|	AND ObjectPrintingForms.ObjectType = &ObjectType
	|
	|ORDER BY
	|	IsDefault DESC,
	|	Code
	|TOTALS BY
	|	Language";
	vQuery.SetParameter("ObjectType", Documents.Reservation.EmptyRef());	
	vQueryResult = vQuery.Execute();	
	vSelectionRecords = vQueryResult.Select(QueryResultIteration.ByGroups);
	PrintForms.Clear();
	vLang = SessionParameters.CurrentLanguage;
	If ValueIsFilled(SelHotel) And Not SelHotel.IsFolder Then
		vLang = SelHotel.Language;
	EndIf;
	While vSelectionRecords.Next() Do
		vSelectionDetailRecords = vSelectionRecords.Select(QueryResultIteration.ByGroups);
		
		If vLang = vSelectionRecords.Language or not ValueIsFilled(vSelectionRecords.Language) Then
			vParentLang = Items.FormGroupPrintingNotDefaultMain;
			vParentLang1 = Items.FormGroupPrintingNotDefaultMain1;
		ElsIf not vLang = vSelectionRecords.Language Then
			vParentLang = tcOnServer.cmCreateItem(ThisObject, Items.FormGroupPrintingNotDefaultExtra, "Print"+vSelectionRecords.Language, "FormGroup", New Structure("Type,Title",	FormGroupType.Popup, vSelectionRecords.Language));
			vParentLang1 = tcOnServer.cmCreateItem(ThisObject, Items.FormGroupPrintingNotDefaultExtra1, "Print"+vSelectionRecords.Language+"1", "FormGroup", New Structure("Type,Title",	FormGroupType.Popup, vSelectionRecords.Language));
		EndIf;
		
		While vSelectionDetailRecords.Next() Do
			If vSelectionDetailRecords.PredefinedDataName = "" 
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintHotelProduct" 
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintGuestGroupHotelProducts"  
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintGuestFormForm5" 
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintGuestForm2Forms5" 
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintGuestFormFreeForm"
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintGuestRegistrationForm"
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintGuestsFormsForm5"
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintGuestsForms2Forms5"
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintGuestsFormsFreeForm"
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintGuestRegistrationForms"
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintGuestPersonalDataProcessingConsent"
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationRu"  
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationEn"  
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationDe"  
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationWithServicesRu"  
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationWithServicesEn"  		
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationWithServicesDe" 
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintCurrentDocConfirmationRu"  
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintCurrentDocConfirmationEn"  
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintCurrentDocConfirmationDe"  
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintCurrentDocConfirmationWithServicesRu"  
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintCurrentDocConfirmationWithServicesEn"  		
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintCurrentDocConfirmationWithServicesDe" 
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationRichTextRu"  
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationRichTextEn"  		
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationRichTextDe" Then 
				
				vNewRow = PrintForms.Add();
				vNewRow.PrintForm = vSelectionDetailRecords.Ref;
				vNewRow.IsDefault = vSelectionDetailRecords.IsDefault;
				
				vID = vNewRow.GetID();
				
				vCommand = Commands.Add("Print"+vID);
				vCommand.Action = "PrintButtonClick";
				If vSelectionDetailRecords.IsDefault Then
					vParent = Items.FormGroupPrintingDefault;
					vParent1 = Items.FormGroupPrintingDefault1;
				Else
					vParent = vParentLang;
					vParent1 = vParentLang1;
				EndIf;
				vStructure = New Structure("Title, CommandName", TrimAll(vSelectionDetailRecords.Code) + " " + cmNStr(vSelectionDetailRecords.ref), "Print" + vID);
				
				tcOnServer.cmCreateItem(ThisObject, vParent, "Print" + vID, "FormButton", vStructure);
				tcOnServer.cmCreateItem(ThisObject, vParent1, "Print_1_" + vID, "FormButton", vStructure);
			EndIf;
		EndDo;
	EndDo;
EndProcedure // FillPrintingButton

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintButtonClick(Command)
	vRowData = Items.ReservList.CurrentData;
	If vRowData <> Undefined Then
		vPrintNumber = StrReplace(Command.Name, "Print", "");
		vPrintForm = GetPrintFormForNumber(vPrintNumber);
		
		// Load external print form
		If ValueIsFilled(vPrintForm.ExternalProcessing) Then 
			Try
				OpenExternalProcedureForm(vPrintForm.ExternalProcessing, vPrintForm.Ref, vRowData.Ref);
			Except
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'"), MessageStatus.Attention);
				vExternalProcessing = Undefined;
			EndTry;
		ElsIf ValueIsFilled(vPrintForm.Report) Then
			Try
				OpenExternalReportForm(vPrintForm.Report, vPrintForm.Ref, vRowData.Ref);
			Except
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'"), MessageStatus.Attention);
			EndTry;
		ElsIf vPrintForm.PredefinedDataName = "ReservationPrintHotelProduct" Or
			vPrintForm.PredefinedDataName = "ReservationPrintGuestGroupHotelProducts" Then 
			vParams = New Structure("SelDocument, SelGuestGroup, SelLanguage, SelObjectPrintForm, SelRoom, SelCheckInDate", 
							vRowData.Ref,
							vRowData.GuestGroup, 
							tcOnServer.cmGetAttributeByRef(vPrintForm.Ref, "Language"),
							vPrintForm.Ref,
							vRowData.Room,
							BegOfDay(vRowData.CheckInDate));
            OpenForm("Report.PrintHotelProducts.ObjectForm", vParams, ThisObject, New UUID());
		ElsIf vPrintForm.PredefinedDataName = "ReservationPrintConfirmationRu" Or
			vPrintForm.PredefinedDataName = "ReservationPrintConfirmationEn" Or
			vPrintForm.PredefinedDataName = "ReservationPrintConfirmationDe" Then
			vParams = New Structure("SelReservation, SelReservationObj, SelLanguage, SelObjectPrintForm, CloseOnOwnerClose", 
							vRowData.Ref,
							, 
							tcOnServer.cmGetAttributeByRef(vPrintForm.Ref, "Language"),
							vPrintForm.Ref,
							False);
			OpenForm("Document.Reservation.Form.tcReservationConfirmationForm", vParams, ThisObject, New UUID());
		ElsIf vPrintForm.PredefinedDataName = "ReservationPrintCurrentDocConfirmationRu" Or
		      vPrintForm.PredefinedDataName = "ReservationPrintCurrentDocConfirmationEn" Or
			  vPrintForm.PredefinedDataName = "ReservationPrintCurrentDocConfirmationDe" Then
			vParams = New Structure("SelReservation, SelReservationObj, SelLanguage, SelObjectPrintForm, CloseOnOwnerClose, SelShowConfirmationForCurrentReservationOnly", 
			                        vRowData.Ref,
			                        , 
			                        tcOnServer.cmGetAttributeByRef(vPrintForm.Ref, "Language"),
			                        vPrintForm.Ref,
			                        False,
			                        True);
			OpenForm("Document.Reservation.Form.tcReservationConfirmationForm",vParams, ThisObject, New UUID());
		ElsIf vPrintForm.PredefinedDataName = "ReservationPrintConfirmationWithServicesRu" Or
		      vPrintForm.PredefinedDataName = "ReservationPrintConfirmationWithServicesEn" Or
		      vPrintForm.PredefinedDataName = "ReservationPrintConfirmationWithServicesDe" Then
			vParams = New Structure("SelReservation, SelReservationObj, SelLanguage, SelObjectPrintForm, CloseOnOwnerClose", 
			                        vRowData.Ref,
			                        , 
			                        tcOnServer.cmGetAttributeByRef(vPrintForm.Ref, "Language"),
			                        vPrintForm.Ref,
			                        False);
			OpenForm("Document.Reservation.Form.tcReservationConfirmationWithServicesForm",vParams, ThisObject, New UUID());
		ElsIf vPrintForm.PredefinedDataName = "ReservationPrintCurrentDocConfirmationWithServicesRu" Or
		      vPrintForm.PredefinedDataName = "ReservationPrintCurrentDocConfirmationWithServicesEn" Or
		      vPrintForm.PredefinedDataName = "ReservationPrintCurrentDocConfirmationWithServicesDe" Then
			vParams = New Structure("SelReservation, SelReservationObj, SelLanguage, SelObjectPrintForm, CloseOnOwnerClose, SelShowConfirmationForCurrentReservationOnly", 
			                        vRowData.Ref,
			                        , 
			                        tcOnServer.cmGetAttributeByRef(vPrintForm.Ref, "Language"),
			                        vPrintForm.Ref,
			                        False,
			                        True);
			OpenForm("Document.Reservation.Form.tcReservationConfirmationWithServicesForm", vParams, ThisObject, New UUID());
		ElsIf vPrintForm.PredefinedDataName = "ReservationPrintGuestFormForm5" Or
		      vPrintForm.PredefinedDataName = "ReservationPrintGuestForm2Forms5" Or
		      vPrintForm.PredefinedDataName = "ReservationPrintGuestFormFreeForm" Or
		      vPrintForm.PredefinedDataName = "ReservationPrintGuestRegistrationForm" Then
			PrintGuestForm(vPrintForm.PredefinedDataName, vRowData.Ref);
		ElsIf vPrintForm.PredefinedDataName = "ReservationPrintGuestsFormsForm5" Or 
		      vPrintForm.PredefinedDataName = "ReservationPrintGuestsForms2Forms5" Or 
			  vPrintForm.PredefinedDataName = "ReservationPrintGuestsFormsFreeForm" Or 
			  vPrintForm.PredefinedDataName = "ReservationPrintGuestRegistrationForms" Then
			PrintGuestsForms(vPrintForm.PredefinedDataName, vRowData.Ref);
		ElsIf vPrintForm.PredefinedDataName = "ReservationPrintConfirmationRichTextRu" Or
		      vPrintForm.PredefinedDataName = "ReservationPrintConfirmationRichTextEn" Or
			  vPrintForm.PredefinedDataName = "ReservationPrintConfirmationRichTextDe" Then
			vParams = New Structure("InputParameter, ObjectPrintingForm", vRowData.Ref, vPrintForm.Ref);
			OpenForm("DataProcessor.ReservationConfirmationRichTextFormat.Form", vParams, ThisObject, New UUID());
		ElsIf vPrintForm.PredefinedDataName = "ReservationPrintGuestPersonalDataProcessingConsent" Then
			PrintGuestPersonalDataProcessingConsent(vRowData.Ref);
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintGuestForm(pTypeOfPrintForm, pDocRef)
	vObjPrtForm = tcOnServer.cmGetCatalogItemRefByName("ObjectPrintingForms", pTypeOfPrintForm);
	vFrm = OpenForm("Document.Accommodation.Form.tcPrintGuestForm", New Structure("Document, GuestGroup, ObjectPrintingForm", pDocRef, Undefined, vObjPrtForm), ThisObject, pDocRef);
EndProcedure // PrintGuestForm

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintGuestsForms(pTypeOfPrintForm, pDocRef)
	vObjPrtForm = tcOnServer.cmGetCatalogItemRefByName("ObjectPrintingForms", pTypeOfPrintForm);   
	vGuestGroup = tcOnServer.cmGetAttributeByRef(pDocRef, "GuestGroup");  
	
	vParamForm = New Structure("Document, GuestGroup, ObjectPrintingForm", pDocRef, vGuestGroup, vObjPrtForm);
	
	OpenForm("Document.Accommodation.Form.tcPrintGuestForm", vParamForm, ThisObject, pDocRef);
EndProcedure // PrintGuestsForms

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintGuestPersonalDataProcessingConsent(pDocRef)
	vLang = Undefined;
	vGuest = tcOnServer.cmGetAttributeByRef(pDocRef, "Guest");
	If ValueIsFilled(vGuest) Then
		vLang = tcOnServer.cmGetAttributeByRef(vGuest, "Language");
	EndIf;
	vInputParameter = New ValueList();
	vInputParameter.Add(pDocRef);
	If SelShowAllGuests = 1 Then
		If Items.ReservList.SelectedRows.Count() > 1 Then
			For Each vRow In Items.ReservList.SelectedRows Do
				vRowDoc = Items.ReservList.RowData(vRow).Ref;
				If vInputParameter.FindByValue(vRowDoc) = Undefined Then
					vInputParameter.Add(vRowDoc);
				EndIf;
			EndDo;
		EndIf;
	Else
		AddOneRoomGuestsAtServer(vInputParameter);
	EndIf;
	vPrtForm = PredefinedValue("Catalog.ObjectPrintingForms.ReservationPrintGuestPersonalDataProcessingConsent");
	vParams = New Structure("InputParameter, ObjectPrintingForm, Lang", vInputParameter, vPrtForm, vLang);
	OpenForm("Document.Accommodation.Form.tcAccommodationPrintForm", vParams, ThisObject, new UUID);
EndProcedure // PrintGuestPersonalDataProcessingConsent

// -----------------------------------------------------------------------------
&AtServer
Function GetPrintFormForNumber(pActionsNumber)
	vPrintForms = PrintForms.FindByID(Number(pActionsNumber)).PrintForm;
	
	vStruct = New Structure();
	vStruct.Insert("Ref",vPrintForms);
	vStruct.Insert("PredefinedDataName",vPrintForms.PredefinedDataName);	
	vStruct.Insert("ExternalProcessing",vPrintForms.ExternalProcessing);
	vStruct.Insert("Report",vPrintForms.Report);
	vStruct.Insert("Language",vPrintForms.Language);
	
	Return vStruct;
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Function ConnectExternalDataProcessor(pPath, pName = "", pUseSafeMode = False)
	Return ExternalDataProcessors.Connect(pPath, pName, pUseSafeMode);
EndFunction // ConnectExternalDataProcessor

// -----------------------------------------------------------------------------
&AtServer
Function ConnectExternalReport(pPath, pName = "", pUseSafeMode = False)
	Return ExternalReports.Connect(pPath, pName, pUseSafeMode);
EndFunction // ConnectExternalDataProcessor

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenExternalProcedureForm(pExtProcRef, pPrintFormTypeRef, pDocRef)
	vURL = GetURL(pExtProcRef, "ExternalProcessingStorage"); 
	vName = ConnectExternalDataProcessor(vURL, "ExternalReservationConfirmationForm");
	vParams = New Structure("InputParameter, ObjectPrintingForm, OneGuestMode", pDocRef, pPrintFormTypeRef, ?(SelShowAllGuests = 1, True, False));
	OpenForm("ExternalDataProcessor." + vName + ".Form", vParams);
EndProcedure // OpenExternalProcedureForm

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenExternalReportForm(pExtRepRef, pPrintFormTypeRef, pDocRef)
	#If ThickClientOrdinaryApplication Then
		vExtRepData = pExtRepRef.ExternalProcessingStorage.Get();
		vExtRepPath = GetTempFileName(".erf");
		vExtRepData.Write(vExtRepPath);
		vExtRepObj = ExternalReports.Create(vExtRepPath, False);
		vStruct = New Structure("Document, ObjectPrintingForm", pDocRef, pPrintFormTypeRef);
		FillPropertyValues(vExtRepObj, vStruct);
		// Fill reference to the report catalog item
		vExtRepObj.Report = pPrintFormTypeRef.Report;
		// Load report catalog item attributes
		vExtRepObj.pmLoadReportAttributes(pDocRef);
		// Open report's default form
		vExtRepFrm = vExtRepObj.GetForm();
		vExtRepFrm.GenerateOnFormOpen = True;
		vExtRepFrm.Open();
		BeginDeletingFiles(New NotifyDescription, vExtRepPath);
	#Else
		vURL = GetURL(tcOnServer.cmGetAttributeByRef(pExtRepRef,"Report"), "ExternalProcessingStorage"); 
		vName = ConnectExternalReport(vURL, "ExternalReportForm");
		vParams = New Structure("Document, ObjectPrintingForm, OneGuestMode", pDocRef, pPrintFormTypeRef, ?(SelShowAllGuests = 1, True, False));
		OpenForm("ExternalReport." + vName + ".Form", vParams);
	#EndIf
EndProcedure // OpenExternalReportForm

// -----------------------------------------------------------------------------
&AtServer
Function SendWelcomeSMSAtServer(pDocRef)
	vMessage = "";
	
	vExtSys = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsHotel365(pDocRef.Hotel);
	If Not ValueIsFilled(vExtSys) Then
		// The integration with hotel365 is not set
		Return NStr("en = 'Integration with the hotel365 service is not configured'; de = 'Die Integration mit hotel365 ist nicht konfiguriert'; ru = 'Не настроена интеграция с сервисом hotel365'");
	EndIf;
	If Not vExtSys.IsActive Then
		// The integration with hotel365 is switched off
		Return NStr("en = 'The Integration with hotel365 is switched off'; de = 'Die Integration mit hotel365 ist ausgeschaltet'; ru = 'Интеграция с hotel365 отключена'");
	EndIf;

	If ValueIsFilled(pDocRef.ReservationStatus) And (pDocRef.ReservationStatus.IsActive Or pDocRef.ReservationStatus.IsPreliminary) Then
		// Get list of reservations to send message to
		vDocsList = New ValueList();
		If ValueIsFilled(pDocRef.Guest) And pDocRef.Guest.NoSMSDelivery Then
			vMessage = vMessage + StrTemplate(NStr("en='Guest %1 refused SMS notifications!'; ru='Гость %1 отказался от СМС оповещений!'; de='Gast %1 hat SMS-Benachrichtigungen abgelehnt'"), TrimAll(pDocRef.Guest));
		Else
			vDocsList.Add(pDocRef.Ref);
		EndIf;
		vOneRoomGuests = cmGetOneRoomReservations(pDocRef.Number, pDocRef.GuestGroup, pDocRef.CheckInDate, pDocRef.CheckOutDate);
		For Each vOneRoomGuestsRow In vOneRoomGuests Do
			vOneRoomDocRef = vOneRoomGuestsRow.Ref;
			If vOneRoomDocRef <> pDocRef And ValueIsFilled(vOneRoomDocRef.Guest) And vOneRoomDocRef.Guest <> pDocRef.Guest Then
				If vOneRoomDocRef.Guest.NoSMSDelivery Then
					vMessage = vMessage + StrTemplate(NStr("en='Guest %1 refused SMS notifications!'; ru='Гость %1 отказался от СМС оповещений!'; de='Gast %1 hat SMS-Benachrichtigungen abgelehnt'"), TrimAll(vOneRoomDocRef.Guest));
				Else
					vDocsList.Add(vOneRoomDocRef);
				EndIf;
			EndIf;
		EndDo;
		// Send SMS to every guest in the list
		For Each vDocItem In vDocsList Do
			vDoc = vDocItem.Value;
			vHotel = vDoc.Hotel;
			vGuest = vDoc.Guest;
			vPhone = ?(Not IsBlankString(vDoc.Phone), TrimAll(vDoc.Phone), TrimAll(vGuest.Phone));
			If Not IsBlankString(vPhone) Then
				vResult = SMS.Hotel365_SendSMS(vHotel, vDoc, vPhone, vGuest);
				If Not vResult.Success Then
					For Each vErrorText In vResult.Errors Do
						vMessage = vMessage + ?(IsBlankString(vMessage), "", Chars.LF) + vErrorText;
					EndDo;
				EndIf;
			Else
				vMessage = vMessage + ?(IsBlankString(vMessage), "", Chars.LF) + NStr("en='Guest phone is not filled!'; ru='В брони не указан телефон гостя!'; de='Gast-Telefon ist nicht gefüllt!'");
			EndIf;
		EndDo;
	EndIf;
	Return vMessage;
EndFunction // SendWelcomeSMSAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SendWelcomeSMS(pCommand)
	vRowData = Items.ReservList.CurrentData;
	If vRowData <> Undefined Then
		vMessage = SendWelcomeSMSAtServer(vRowData.Ref);
		If Not IsBlankString(vMessage) Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage);
		EndIf;
	EndIf;
EndProcedure // SendWelcomeSMS

// -----------------------------------------------------------------------------
&AtClient
Procedure SelInPeriodOnChange(pItem)
	Items.SelDateTo.Visible = SelInPeriod;
	SetDynamicListParametersAtServer();
EndProcedure // SelInPeriodOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure SelHotelOnChangeAtServer()
	// Status last change time
	If ValueIsFilled(SelHotel) And Not SelHotel.IsFolder And SelHotel.ShowReservationStatusLastChangeDate Then
		Items.DocumentListReservationStatusSetTime.Visible = True;
		If ListModes.FindByValue(5) = Undefined Then
			ListModes.Add(5, NStr("en='Change status date'; ru='Дата изменения статуса'; de='Datum der Statusänderung'") + "...", , GetListModeIconAtServer(5));
		EndIf;
	Else
		Items.DocumentListReservationStatusSetTime.Visible = False;
		vListMode5 = ListModes.FindByValue(5);
		If vListMode5 <> Undefined Then
			ListModes.Delete(vListMode5);
		EndIf;
		If SelListMode = 5 Then
			SelListMode = 0;
		EndIf;
	EndIf;
	// Apply hotel selected
	SetDynamicListParametersAtServer();
	// Check vauchers functional option
	CheckVauchersFunctionalOption();
	// Check beds setups functional option
	CheckBedsSetupsFunctionalOption();
	// Hotel column appearance
	If Not ValueIsFilled(SelHotel) Or ValueIsFilled(SelHotel) And SelHotel.IsFolder Then
		Items.DocumentListHotel.Visible = True;
		Items.GroupHotel.BackColor = Items.GroupSearchMode.BackColor;
	Else
		Items.DocumentListHotel.Visible = False;
		// Set hotel color          
		Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
	EndIf;
EndProcedure // SelHotelOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SelHotelOnChange(pItem)
	SelHotelOnChangeAtServer();
EndProcedure // SelHotelOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RecalculateActiveReservationsPrices(pCommand)
	If ValueIsFilled(SelHotel) And Not tcOnServer.cmGetAttributeByRef(SelHotel, "IsFolder") Then
		OpenForm("CommonForm.tcRecalculateReservationPrices", New Structure("Hotel", SelHotel), , SelHotel);
	EndIf;
EndProcedure // RecalculateActiveReservationsPrices

// -----------------------------------------------------------------------------
&AtServerNoContext
Function IsActiveReservation(pReservation)
	If pReservation.Posted And (pReservation.ReservationStatus.IsActive Or pReservation.ReservationStatus.IsPreliminary) Then
		If BegOfDay(pReservation.CheckOutDate) >= BegOfDay(CurrentSessionDate()) Then
			Return True;
		EndIf;
	EndIf;
	Return False;
EndFunction // IsActiveReservation

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomAssignment(pCommand)
	If Not ValueIsFilled(SelHotel) Or ValueIsFilled(SelHotel) And tcOnServer.cmGetAttributeByRef(SelHotel, "IsFolder") Then
		ShowMessageBox(, NStr("en='Hotel should be selected!'; ru='Гостиница должна быть выбрана!'; de='Hotel sollte ausgewählt werden!'"));
		Return;
	EndIf;
	
	If Items.ReservList.SelectedRows.Count() > 1 Then
		vReservations = New ValueList();
		For Each vRowIndex In Items.ReservList.SelectedRows Do
			vRowData = Items.ReservList.RowData(vRowIndex);
			If ValueIsFilled(vRowData.AccommodationTemplate) Then
				If IsActiveReservation(vRowData.Ref) Then
					vReservations.Add(vRowData.Ref);
				EndIf;
			EndIf;
		EndDo;
		OpenForm("Document.Reservation.Form.tcRoomAssignmentForm", New Structure("SelHotel, SelReservations", SelHotel, vReservations), ThisObject);
	ElsIf ValueIsFilled(SelDate) Then
		OpenForm("Document.Reservation.Form.tcRoomAssignmentForm", New Structure("SelHotel, SelCheckInDate", SelHotel, BegOfDay(SelDate)), ThisObject);
	Else
		ShowMessageBox(, NStr("en='Please specify either check-in date filter or select more then one reservation in the list!'; 
		                      |ru='Пожалуйста либо укажите отбор по дате заезда либо выделите в списке более одной брони!'; 
							  |de='Bitte wählen Sie Anreisedatum-Filter oder wählen Sie mehr als eine Reservierung in der Liste aus!'"));
	EndIf;
EndProcedure // RoomAssignment

// -----------------------------------------------------------------------------
&AtClient
Procedure CurGuestGroupRefClick(pItem, pStandardProcessing)
	pStandardProcessing = False;
	vUCList = New ValueList();
	vUCList.Add(0, NStr("en='Filter list by guest group...'; ru='Отфильтровать список по группе...'; de='Liste nach Gruppe filtern...'"));
	vUCList.Add(1, NStr("en='Open guest group details form...'; ru='Открыть карточку группы...'; de='Gruppeformular öffnen...'"));
	ShowChooseFromMenu(New NotifyDescription("AfterCurGuestGroupClickAnswer", ThisObject, CurGuestGroup), vUCList, pItem);
EndProcedure // CurGuestGroupRefClick

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterCurGuestGroupClickAnswer(pUC, pGuestGroup) Export
	If pUC <> Undefined Then
		If pUC.Value = 0 Then
			SelGuestGroup = pGuestGroup;
			SelGuestGroupOnChange(Items.SelGuestGroup);
		Else
			ShowValue(,pGuestGroup);
		EndIf;
	EndIf;
EndProcedure // AfterCurGuestGroupClickAnswer

// -----------------------------------------------------------------------------
&AtClient
Procedure CurGuestGroupCustomerClick(pItem, pStandardProcessing)
	pStandardProcessing = False;
	vUCList = New ValueList();
	vUCList.Add(0, NStr("en='Filter list by customer...'; ru='Отфильтровать список по контрагенту...'; de='Liste nach Firma filtern...'"));
	vUCList.Add(1, NStr("en='Open customer details form...'; ru='Открыть форму сведений о контрагенте...'; de='Firmendatenformular öffnen...'"));
	ShowChooseFromMenu(New NotifyDescription("AfterCurCustomerClickAnswer", ThisObject, tcOnServer.cmGetAttributeByRef(CurGuestGroup, "Customer")), vUCList, pItem);
EndProcedure // CurGuestGroupCustomerClick

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterCurCustomerClickAnswer(pUC, pCustomer) Export
	If pUC <> Undefined Then
		If pUC.Value = 0 Then
			SelCustomer = pCustomer;
			SelCustomerOnChange(Items.SelCustomer);
		Else
			ShowValue(,pCustomer);
		EndIf;
	EndIf;
EndProcedure // AfterCurCustomerClickAnswer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillEventAndAllotment(pDocRef, rEvent, rAllotment)
	vGuestGroup = pDocRef.GuestGroup;
	If ValueIsFilled(vGuestGroup) Then
		If Not ValueIsFilled(rEvent) And ValueIsFilled(vGuestGroup.Event) Then
			rEvent = vGuestGroup.Event;
		EndIf;
		If Not ValueIsFilled(rAllotment) And ValueIsFilled(vGuestGroup.Allotment) Then
			rAllotment = vGuestGroup.Allotment;
		EndIf;
	EndIf;
EndProcedure // FillEventAndAllotment

// -----------------------------------------------------------------------------
&AtServer
Procedure GetSelectedDocumentsToMergeAtServer(rEvent, rAllotment)
	rEvent = Undefined; 
	rAllotment = Undefined;
	DocsToProcess.Clear();
	vSelRows = Items.ReservList.SelectedRows;
	For Each vSelRow In vSelRows Do
		If ValueIsFilled(vSelRow.Ref) Then
			vResRef = vSelRow.Ref;
			If vResRef.Posted Then
				If DocsToProcess.FindByValue(vResRef) = Undefined Then
					DocsToProcess.Add(vResRef);
					
					// Fill group event and allotment attributes
					FillEventAndAllotment(vResRef, rEvent, rAllotment);
					
					// Check if this reservation is in check-in status
					If vResRef.ReservationStatus.IsCheckIn Then
						vAccRef = cmGetAccommodationByReservation(vResRef);
						If ValueIsFilled(vAccRef) Then
							DocsToProcess.Add(vAccRef);
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			
			// Add one room reservations if necessary
			vGetInactive = False;
			If Not vResRef.ReservationStatus.IsActive And Not vResRef.ReservationStatus.IsPreliminary Then
				vGetInactive = True;
			EndIf;
			If Not SelShowAllGuests Then
				vOneRoomDocs = cmGetOneRoomReservations(vResRef.Number, vResRef.GuestGroup, vResRef.CheckInDate, vResRef.CheckOutDate, vGetInactive);
				For Each vOneRoomDocsRow In vOneRoomDocs Do
					vDocRef = vOneRoomDocsRow.Ref;
					If Not vDocRef.Posted Then
						Continue;
					EndIf;
					If vGetInactive Then
						If vResRef.ReservationStatus <> vDocRef.ReservationStatus Then
							Continue;
						EndIf;
					EndIf;
					If DocsToProcess.FindByValue(vDocRef) = Undefined Then
						DocsToProcess.Add(vDocRef);
						
						// Check if this reservation is in check-in status
						If vDocRef.ReservationStatus.IsCheckIn Then
							vAccRef = cmGetAccommodationByReservation(vDocRef);
							If ValueIsFilled(vAccRef) Then
								DocsToProcess.Add(vAccRef);
							EndIf;
						EndIf;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndDo;
EndProcedure // GetSelectedDocumentsToMergeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure CombineSelectedIntoOneGroupAtServer(pGuestGroup)
	Try
		BeginTransaction(DataLockControlMode.Managed);
		
		// Merge documents
		If ValueIsFilled(pGuestGroup) Then
			For Each vDocsToProcessItem In DocsToProcess Do
				vDocObj = vDocsToProcessItem.Value.GetObject();
				vDocObj.GuestGroup = pGuestGroup;
				vDocObj.pmCalculateServices( , , , , , vDocObj.IsForFolioSplit);
				vDocObj.Write(DocumentWriteMode.Posting);
				If TypeOf(vDocObj) = Type("DocumentObject.Accommodation") Then
					vDocObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				Else
					vDocObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				EndIf;
			EndDo;
		EndIf;
		
		CommitTransaction();
	Except
		vErrorInfo = ErrorInfo();
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		Raise cmGetRootErrorDescription(vErrorInfo);
	EndTry;
EndProcedure // CombineSelectedIntoOneGroupAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure CombineSelectedIntoOneGroup(pCommand)
	Var vEvent; Var vAllotment;
	
	// Get documents to process
	GetSelectedDocumentsToMergeAtServer(vEvent, vAllotment);
	If DocsToProcess.Count() = 0 Then
		Return;
	EndIf;
	// Ask for guest group
	vGuestGroup = PredefinedValue("Catalog.GuestGroups.EmptyRef");
	OpenForm("Document.Reservation.Form.tcGuestGroupSelectionForm", New Structure("GuestGroup, Hotel, Event, Allotment", vGuestGroup, ?(ValueIsFilled(SelHotel) And Not tcOnServer.cmGetAttributeByRef(SelHotel, "IsFolder"), SelHotel, tcOnServer.cmGetSessionParametersAttribute("CurrentHotel")), vEvent, vAllotment));
EndProcedure // CombineSelectedIntoOneGroup

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterGuestGroupToMergeSelection(pGuestGroup)
	If pGuestGroup <> Undefined Then
		CombineSelectedIntoOneGroupAtServer(pGuestGroup);
		OpenForm("Catalog.GuestGroups.ObjectForm", New Structure("Key", pGuestGroup), , pGuestGroup);
	EndIf;
	DocsToProcess.Clear();
	CurGuestGroup = pGuestGroup;
EndProcedure // AfterGuestGroupToMergeSelection

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure FillVauchersForSelectedDocuments(pCommand)
	vDocsList = New ValueList();
	If Items.ReservList.SelectedRows.Count() > 0 Then
		For Each vRowIndex In Items.ReservList.SelectedRows Do
			vRowData = Items.ReservList.RowData(vRowIndex);
			vDocsList.Add(vRowData.Ref, , True);
		EndDo;
	EndIf;
	OpenForm("CommonForm.tcFillVauchersInReservations", New Structure("DocumentsList", vDocsList), ThisObject);
EndProcedure // FillVauchersForSelectedDocuments

// -----------------------------------------------------------------------------
&AtClient
Procedure SelHotelClearing(pItem, pStandardProcessing)
	If Not IsInRoleAtServer("RightsToChooseHotel") Then
		pStandardProcessing = False;
	EndIf;
	If Not ValueIsFilled(SelHotel) Or ValueIsFilled(SelHotel) And tcOnServer.cmGetAttributeByRef(SelHotel, "IsFolder") Then
		Items.DocumentListHotel.Visible = True;
		Items.GroupHotel.BackColor = Items.GroupSearchMode.BackColor;
	Else
		Items.DocumentListHotel.Visible = False;
	EndIf;
EndProcedure // SelHotelClearing

// -----------------------------------------------------------------------------
&AtServer
Function IsInRoleAtServer(pRoleName)
	Return IsInRole(pRoleName);
EndFunction // IsInRoleAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetRemarksForAPDEX(pObject, pIsAccommodation = False)
	
	vAPDEXParams = New Structure;         
	vAPDEXParams.Insert("Number", pObject.Number); 
	If pIsAccommodation Then
		vAPDEXParams.Insert("Status", String(pObject.AccommodationStatus));
	Else	
		vAPDEXParams.Insert("Status", String(pObject.ReservationStatus));
	EndIf;
	vAPDEXParams.Insert("CheckInDate", String(pObject.CheckInDate));
	vAPDEXParams.Insert("CheckOutDate", String(pObject.CheckOutDate));
	vAPDEXParams.Insert("RoomType", String(pObject.RoomType));
	vAPDEXParams.Insert("RoomRate", String(pObject.RoomRate)); 
	vAPDEXParams.Insert("GuestGroup", String(pObject.GuestGroup));
	vAPDEXParams.Insert("Guest", String(pObject.Guest));  
	vAPDEXParams.Insert("RoomQuota", String(pObject.RoomQuota));
	
	Return vAPDEXParams;
EndFunction // GetRemarksForAPDEX

// -----------------------------------------------------------------------------
&AtClient
Procedure TReservationPresentationClick(pItem, pStandardProcessing)
	pStandardProcessing = False;
	If ValueIsFilled(TReservation) Then
		ShowValue(, TReservation);
	EndIf;
EndProcedure // TReservationPresentationClick

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure AddOneRoomGuestsAtServer(pList)
	vDoc = pList.Get(0).Value;
	vOneRoomGuests = cmGetOneRoomReservations(vDoc.Number, vDoc.GuestGroup, vDoc.CheckInDate, vDoc.CheckOutDate, False, True);
	For Each vOneRoomGuestsRow In vOneRoomGuests Do
		If pList.FindByValue(vOneRoomGuestsRow.Ref) = Undefined Then
			pList.Add(vOneRoomGuestsRow.Ref);
		EndIf;
	EndDo;
EndProcedure // AddOneRoomGuestsAtServer
