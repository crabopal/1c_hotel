
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	SystemSettingsStorage.Save("Document.Accommodation.Form.tcAccommodationListForm", "FirstDocInInHouseBatch", Undefined);
	SystemSettingsStorage.Save("Document.Accommodation.Form.tcAccommodationListForm", "LastDocInInHouseBatch", Undefined);
	SystemSettingsStorage.Save("Document.Accommodation.Form.tcAccommodationListForm", "FirstDocInArchiveBatch", Undefined);
	SystemSettingsStorage.Save("Document.Accommodation.Form.tcAccommodationListForm", "LastDocInArchiveBatch", Undefined);
	SystemSettingsStorage.Save("Document.Accommodation.Form.tcAccommodationListForm", "FirstDocInReservationBatch", Undefined);
	SystemSettingsStorage.Save("Document.Accommodation.Form.tcAccommodationListForm", "LastDocInReservationBatch", Undefined);
	// Check if this form is opened by hotel agent 
	If ValueIsFilled(SessionParameters.CurrentUser) Then
		vCurUser = SessionParameters.CurrentUser;
		If ValueIsFilled(vCurUser.Customer) Then
			SelCustomer = vCurUser.Customer;
			If SelCustomer.IsFolder Then
				AttributeChangeAtServer("Customer", SelCustomer, DataCompositionComparisonType.InHierarchy);
			Else
				AttributeChangeAtServer("Customer", SelCustomer);
			EndIf;
			Items.SelCustomer.ReadOnly = True;
			Items.SelCustomer.ChoiceButton = False;
			Items.SelCustomer.ClearButton = False;
			Items.SelCustomer.OpenButton = False;
		EndIf;
		If ValueIsFilled(vCurUser.RoomType) Then
			SelRoomType = vCurUser.RoomType;
			If SelRoomType.IsFolder Then
				AttributeChangeAtServer("RoomType", SelRoomType, DataCompositionComparisonType.InHierarchy);
			Else
				AttributeChangeAtServer("RoomType", SelRoomType);
			EndIf;
		EndIf;
	EndIf;
	// Current hotel
	SelHotel = SessionParameters.CurrentHotel;
	// Register foreigners action availability
	vRegForeignerObjectFormAction = Catalogs.ObjectFormActions.AccommodationOpenForeignerRegistryRecord;
	If vRegForeignerObjectFormAction.DeletionMark Or Not vRegForeignerObjectFormAction.IsActive Then
		Items.OpenForeignerRegistryRecord.Visible = False;
		Items.DocumentListIsInHouseFormOpenForeignerRegistryRecord.Visible = False;
		Items.DocumentListAllFormOpenForeignerRegistryRecord.Visible = False;
	EndIf;
	// Scan documents action availability
	vScansObjectFormAction = Catalogs.ObjectFormActions.AccommodationScanClientData;
	If vScansObjectFormAction.DeletionMark Or Not vScansObjectFormAction.IsActive Then
		Items.ScanDocuments.Visible = False;
		Items.DocumentListAllFormOpenScanDocuments.Visible = False;
		Items.DocumentListIsInHouseFormOpenScanDocuments.Visible = False;
		Items.ListReservationScanDocuments.Visible = False;
	EndIf;
	// Other parameters
	If Parameters.Property("Room") Then
		If ValueIsFilled(Parameters.Room) Then
			SelRoom = Parameters.Room;
			If SelRoom.Owner <> SelHotel Then
				SelHotel = SelRoom.Owner;
			EndIf;
			If SelRoom.IsFolder Then
				AttributeChangeAtServer("Room", SelRoom, DataCompositionComparisonType.InHierarchy);   
			Else
				AttributeChangeAtServer("Room", SelRoom);   
			EndIf;
		EndIf;
	EndIf;
	If Parameters.Property("Client") Then
		If ValueIsFilled(Parameters.Client) Then
			SelClient = Parameters.Client;
			AttributeChangeAtServer("Guest", SelClient);  
		EndIf;
	EndIf;
	If Parameters.Property("Customer") Then
		If ValueIsFilled(Parameters.Customer) Then
			SelCustomer = Parameters.Customer;
			If SelCustomer.IsFolder Then
				AttributeChangeAtServer("Customer", SelCustomer, DataCompositionComparisonType.InHierarchy); 
			Else
				AttributeChangeAtServer("Customer", SelCustomer);  
			EndIf;
		EndIf;
	EndIf;
	If Parameters.Property("Contract") Then
		If ValueIsFilled(Parameters.Contract) Then
			SelContract = Parameters.Contract;
			AttributeChangeAtServer("Contract", SelContract);  
		EndIf;
	EndIf;
	If Parameters.Property("RoomType") Then
		If ValueIsFilled(Parameters.RoomType) Then
			SelRoomType = Parameters.RoomType;
			If SelRoomType.Owner <> SelHotel Then
				SelHotel = SelRoomType.Owner;
			EndIf;
			If SelRoomType.IsFolder Then
				AttributeChangeAtServer("RoomType", SelRoomType, DataCompositionComparisonType.InHierarchy);   
			Else
				AttributeChangeAtServer("RoomType", SelRoomType);   
			EndIf;
		EndIf;
	EndIf;
	If Parameters.Property("Allotment") Then
		If ValueIsFilled(Parameters.Allotment) Then
			SelAllotment = Parameters.Allotment;
			If SelAllotment.IsFolder Then
				AttributeChangeAtServer("RoomQuota", SelAllotment, DataCompositionComparisonType.InHierarchy);   
			Else
				AttributeChangeAtServer("RoomQuota", SelAllotment);   
			EndIf;
		EndIf;
	EndIf;
	If Parameters.Property("BedsSetup") Then
		If ValueIsFilled(Parameters.BedsSetup) Then
			SelBedsSetup = Parameters.BedsSetup;
			AttributeChangeAtServer("BedsSetup", SelBedsSetup);   
		EndIf;
	EndIf;
	If Parameters.Property("SelGuestGroup") Then
		If ValueIsFilled(Parameters.SelGuestGroup) Then
			SelGuestGroup = Parameters.SelGuestGroup;
			If SelGuestGroup.Owner <> SelHotel Then
				SelHotel = SelGuestGroup.Owner;
			EndIf;
			AttributeChangeAtServer("GuestGroup", SelGuestGroup);
		EndIf;
	EndIf;
	If Parameters.Property("ChoiceMode") And Parameters.ChoiceMode Then
		Items.DocumentListAll.ChoiceMode = True;
		Items.DocumentListIsInHouse.ChoiceMode = True;
		Items.DocumentListReservation.ChoiceMode = True;
	EndIf;
	// Fill list types
	If Parameters.Property("SelFilterStatus") Then
		SelFilterStatus = Parameters.SelFilterStatus;
	Else
		SelFilterStatus = 2; // Reservation list is default
	EndIf;
	If Parameters.Property("SelShowAllGuests") Then
		SelShowAllGuests = Parameters.SelShowAllGuests;
	ElsIf SelFilterStatus = 2 Then
		vShowExpectedCheckInListByGuestsByDefault = cmCheckUserPermissions("ShowExpectedCheckInListByGuestsByDefault");
		If vShowExpectedCheckInListByGuestsByDefault Then
			SelShowAllGuests = 1;
		EndIf;
	EndIf;
	// Set some columns visibility
	vShowPassportData = cmCheckUserPermissions("ShowGuestPassportNumberInExpectedArrivalAndInHouseLists");
	Items.DocumentListIsInHouseGroupGuestPassportData.Visible = vShowPassportData;
	Items.DocumentListReservationGroupGuestPassportData.Visible = vShowPassportData;
	// Show only main room guests by default
	AllGuestsOnChangeAtServer();
	// Set filter collapsed title
	SetFilterCollapsedTitle();	
	// Fill functions
	FillFunctionsButtonReservation();
	FillFunctionsButtonAccommodation();
	// Fill printing forms
	FillPrintingButtonReservation();
	FillPrintingButtonAccommodation();
	// Check if we need to run guests auto extend of period of stay
	If ValueIsFilled(SessionParameters.CurrentWorkstation) Then
		RunInHouseGuestsPeriodOfStayAutoExtension = SessionParameters.CurrentWorkstation.RunInHouseGuestsPeriodOfStayAutoExtension;
		InHouseGuestsPeriodOfStayAutoExtensionFrequency = SessionParameters.CurrentWorkstation.InHouseGuestsPeriodOfStayAutoExtensionFrequency;
	Else
		RunInHouseGuestsPeriodOfStayAutoExtension = False;
		InHouseGuestsPeriodOfStayAutoExtensionFrequency = 0;
	EndIf;
	FillFilterStatuses();
	If ValueIsFilled(SelHotel) Then
		Items.DocumentListAllVaucher.Visible = SelHotel.Vauchers; 
		Items.DocumentListIsInHouseVaucher.Visible = SelHotel.Vauchers;
		Items.DocumentListReservationVaucher.Visible = SelHotel.Vauchers;
		Items.FillVauchersForSelectedDocuments.Visible = SelHotel.Vauchers;
		Items.FillVauchersForSelectedDocuments1.Visible = SelHotel.Vauchers;
		Items.DocumentListReservationContextMenuFillVauchersForSelectedDocuments.Visible = SelHotel.Vauchers;
		Items.DocumentListIsInHouseContextMenuFillVauchersForSelectedDocuments.Visible = SelHotel.Vauchers;
		Items.DocumentListAllContextMenuFillVauchersForSelectedDocuments.Visible = SelHotel.Vauchers;

		Items.DocumentListAllBedsSetup.Visible = SelHotel.BedsSetups; 
		Items.DocumentListIsInHouseBedsSetup.Visible = SelHotel.BedsSetups;
		Items.DocumentListReservationBedsSetup.Visible = SelHotel.BedsSetups;
		Items.SelBedsSetup.Visible = SelHotel.BedsSetups;
	EndIf;
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
	// Show or hide export guest data procedure
	vExportDPRef = GetDataProcessorForExportGuestDataToUFMS();
	If Not ValueIsFilled(vExportDPRef) Then
		Items.ExportGuestDataToUFMSRu.Visible = False;
		Items.DocumentListIsInHouseContextMenuExportGuestDataToUFMSRu.Visible = False;
		Items.DocumentListAllContextMenuExportGuestDataToUFMSRu.Visible = False;
	EndIf;
	// Apply filter by status
	FilterStatusOnChangeAtServer(SelCheckOutDate);
	SkipOnRowActivateEvent = True; 
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	// Run automatic in-house guests period of stay extension procedure
	If RunInHouseGuestsPeriodOfStayAutoExtension Then
		vFrequency = 300;
		If InHouseGuestsPeriodOfStayAutoExtensionFrequency <> 0 Then
			vFrequency = Round(60 * InHouseGuestsPeriodOfStayAutoExtensionFrequency, 0);
		EndIf;
		AttachIdleHandler("ExtendInHouseGuestsPeriodOfStay", vFrequency);
	EndIf;
EndProcedure // OnOpen

// -----------------------------------------------------------------------------
&AtClient
Procedure OnReopen()
	OnReopenAtServer();
EndProcedure // OnReopen

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "System.Hotel.Changed" And pParameter <> SelHotel Then
		SelHotel = tcOnServer.cmGetCurrentHotelAttribute();
		SelRoom = Undefined;
		SelRoomClearing(Items.SelRoom, True);
		SelRoomType = Undefined;
		SelRoomTypeClearing(Items.SelRoomType, True);
		SetParametersDynamicList();
		ClearTotalsByGroupAtClient();
		ClearTotalsAtClient();
	ElsIf pEventName = "Document.Accommodation.Write" Or 
	      pEventName = "Document.Accommodation.WriteNew" Or 
	      pEventName = "Document.Reservation.Write" Or 
	      pEventName = "Document.Reservation.WriteNew" Or 
		  pEventName = "Document.Charge.Write" Or 
		  pEventName = "Document.Storno.Write" Or 
		  pEventName = "Document.Payment.Write" Or 
		  pEventName = "Document.Return.Write" Or 
		  pEventName = "Document.DepositTransfer.Write" Or 
		  pEventName = "Document.ChargeTransfer.Write" Or 
		  pEventName = "Subsystem.Accounts.Changed" Or
		  pEventName = "Catalog.GuestGroups.Changed" Then
		AttachIdleHandler("RefreshList", 1, True);
	ElsIf pEventName = "Document.Accommodation.ListForm.ExpectedArrival" Then
		If SelFilterStatus <> 2 Then
			SelFilterStatus = 2;
			FilterStatusOnChange(Items.FilterStatus);
		EndIf;
	ElsIf pEventName = "Document.Accommodation.ListForm.ExpectedDeparture" Then
		If SelFilterStatus <> 3 Then
			SelFilterStatus = 3;
			FilterStatusOnChange(Items.FilterStatus);
		EndIf;
	ElsIf pEventName = "Document.Accommodation.ListForm.InHouseGuests" Then
		If SelFilterStatus <> 0 Then
			SelFilterStatus = 0;
			FilterStatusOnChange(Items.FilterStatus);
		EndIf;
	ElsIf pEventName = "Document.Accommodation.ListForm.Archive" Then
		If SelFilterStatus <> 1 Then
			SelFilterStatus = 1;
			FilterStatusOnChange(Items.FilterStatus);
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
			vRoom = GetRoom(vCard);
			vClient = GetClient(vCard);
			If ValueIsFilled(vRoom) Then
				Items.GroupSearchMode.Show();
				SelRoom = vRoom;
				SelRoomOnChange(Items.SelRoom);
			ElsIf ValueIsFilled(vClient) Then
				Items.GroupSearchMode.Show();
				SelClient = vClient;
				SelClientOnChange(Items.SelClient);
			Else
				ShowMessageBox(, NStr("en = 'Card do not have room or client specified!'; 
									  |de = 'Bei der Karte sind weder Zimmernummer noch Kunde angegeben!';
									  |ru = 'У карты не указан ни номер комнаты ни клиент!'"), 3);
			EndIf;
		Else
			// Try to find discount card with such Id
			vDiscountCard = GetDiscountCardById(vEventData.DeviceData);
			If ValueIsFilled(vDiscountCard) Then
				vClient = GetClient(vCard);
				If ValueIsFilled(vClient) Then
					Items.GroupSearchMode.Show();
					SelClient = vClient;
					SelClientOnChange(Items.SelClient);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ExternalEvent

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SelHotelStartChoice(pItem, pChoiceData, pChoiceByAdding, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelHotelStartListChoice(pItem, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelHotelClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelHotelOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AllGuestsOnChange(pItem)
	AllGuestsOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckInDateOnChange(pItem)
	CheckInDateOnChangeAtServer();
EndProcedure // CheckInDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckOutDateOnChange(pItem)
	CheckOutDateOnChangeAtServer();
EndProcedure // CheckOutDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure FilterStatusOnChange(pItem)
	FilterStatusOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomOnChange(pItem)
	If ValueIsFilled(SelRoom) Then
		If tcOnServer.cmGetAttributeByRef(SelRoom, "IsFolder") Then
			AttributeChangeAtServer("Room", SelRoom, DataCompositionComparisonType.InHierarchy);
		Else
			AttributeChangeAtServer("Room", SelRoom);
		EndIf;
	Else
		ClearingAttributeAtServer("Room");
	EndIf;
	ClearTotalsByGroupAtClient();
	ClearTotalsAtClient();
EndProcedure // SelRoomOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomTypeOnChange(pItem)
	If ValueIsFilled(SelRoomType) Then
		If tcOnServer.cmGetAttributeByRef(SelRoomType, "IsFolder") Then
			AttributeChangeAtServer("RoomType", SelRoomType, DataCompositionComparisonType.InHierarchy);
		Else
			AttributeChangeAtServer("RoomType", SelRoomType);
		EndIf;
	Else
		ClearingAttributeAtServer("RoomType");
	EndIf;
	ClearTotalsByGroupAtClient();
	ClearTotalsAtClient();
EndProcedure // SelRoomTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomRateOnChange(pItem)
	If ValueIsFilled(SelRoomRate) Then
		If tcOnServer.cmGetAttributeByRef(SelRoomRate, "IsFolder") Then
			AttributeChangeAtServer("RoomRate", SelRoomRate, DataCompositionComparisonType.InHierarchy);
		Else
			AttributeChangeAtServer("RoomRate", SelRoomRate);
		EndIf;
	Else
		ClearingAttributeAtServer("RoomRate");
	EndIf;
	ClearTotalsByGroupAtClient();
	ClearTotalsAtClient();
EndProcedure // SelRoomRateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelGuestGroupOnChange(pItem)
	CurGuestGroup = SelGuestGroup;
	If ValueIsFilled(SelGuestGroup) Then
		If ValueIsFilled(SelCustomer) Then
			SelCustomer = Undefined;
			ClearingAttributeAtServer("Customer");
		EndIf;
		If ValueIsFilled(SelContract) Then
			SelContract = Undefined;
			ClearingAttributeAtServer("Contract");
		EndIf;
		If ValueIsFilled(SelRoom) Then
			SelRoom = Undefined;
			ClearingAttributeAtServer("Room");
		EndIf;
		If ValueIsFilled(SelRoomType) Then
			SelRoomType = Undefined;
			ClearingAttributeAtServer("RoomType");
		EndIf;
		If ValueIsFilled(SelCheckOutDate) Then
			SelCheckOutDate = '00010101';
			ClearingAttributeAtServer("CheckOutDate");
		EndIf;
		AttributeChangeAtServer("GuestGroup", SelGuestGroup);
		RefreshGroupTotals();
	Else
		ClearTotalsByGroupAtClient();
		ClearingAttributeAtServer("GuestGroup");
	EndIf;
	ClearTotalsAtClient();
EndProcedure // SelGuestGroupOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelGuestGroupClearing(pItem, pStandardProcessing)
	ClearingAttributeAtServer("GuestGroup");
	ClearTotalsByGroupAtClient();
	ClearTotalsAtClient();
EndProcedure // SelGuestGroupClearing

// -----------------------------------------------------------------------------
&AtClient
Procedure SelCustomerOnChange(pItem)
	If ValueIsFilled(SelCustomer) And ValueIsFilled(SelContract) Then
		vContractOwner = tcOnServer.cmGetAttributeByRef(SelContract, "Owner");
		If vContractOwner <> SelCustomer Then
			SelContract = PredefinedValue("Catalog.Contracts.EmptyRef");
			ClearingAttributeAtServer("Contract");
		EndIf;
	EndIf;
	If ValueIsFilled(SelCustomer) Then
		If tcOnServer.cmGetAttributeByRef(SelCustomer, "IsFolder") Then
			AttributeChangeAtServer("Customer", SelCustomer, DataCompositionComparisonType.InHierarchy);
		Else
			AttributeChangeAtServer("Customer", SelCustomer);
		EndIf;
	Else
		ClearingAttributeAtServer("Customer");
	EndIf;
	ClearTotalsByGroupAtClient();
	ClearTotalsAtClient();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelContractOnChange(pItem)
	If ValueIsFilled(SelCustomer) And ValueIsFilled(SelContract) Then
		vContractOwner = tcOnServer.cmGetAttributeByRef(SelContract, "Owner");
		If vContractOwner <> SelCustomer Then
			SelCustomer = vContractOwner;
			AttributeChangeAtServer("Customer", SelCustomer);
		EndIf;
	EndIf;
	If ValueIsFilled(SelContract) Then
		AttributeChangeAtServer("Contract", SelContract);
	Else
		ClearingAttributeAtServer("Contract");
	EndIf;
	ClearTotalsByGroupAtClient();
	ClearTotalsAtClient();
EndProcedure // SelContractOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelAgentOnChange(pItem)
	If ValueIsFilled(SelAgent) Then
		If tcOnServer.cmGetAttributeByRef(SelAgent, "IsFolder") Then
			AttributeChangeAtServer("Agent", SelAgent, DataCompositionComparisonType.InHierarchy);
		Else
			AttributeChangeAtServer("Agent", SelAgent);
		EndIf;
	Else
		ClearingAttributeAtServer("Agent");
	EndIf;
	ClearTotalsAtClient();
	ClearTotalsByGroupAtClient();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelAllotmentOnChange(pItem)
	If ValueIsFilled(SelAllotment) Then
		If tcOnServer.cmGetAttributeByRef(SelAllotment, "IsFolder") Then
			AttributeChangeAtServer("RoomQuota", SelAllotment, DataCompositionComparisonType.InHierarchy);
		Else
			AttributeChangeAtServer("RoomQuota", SelAllotment);
		EndIf;
	Else
		ClearingAttributeAtServer("RoomQuota");
	EndIf;
	ClearTotalsAtClient();
	ClearTotalsByGroupAtClient();
EndProcedure // SelAllotmentOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelBedsSetupOnChange(pItem)
	If ValueIsFilled(SelBedsSetup) Then
		AttributeChangeAtServer("BedsSetup", SelBedsSetup);
	Else
		ClearingAttributeAtServer("BedsSetup");
	EndIf;
	ClearTotalsAtClient();
	ClearTotalsByGroupAtClient();
EndProcedure // SelBedsSetupOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelBedsSetupClearing(pItem, pStandardProcessing)
	ClearingAttributeAtServer("BedsSetup");
	ClearTotalsAtClient();
	ClearTotalsByGroupAtClient();
EndProcedure // SelBedsSetupClearing

// -----------------------------------------------------------------------------
&AtClient
Procedure SelClientOnChange(pItem)
	If ValueIsFilled(SelClient) Then
		AttributeChangeAtServer("Guest", SelClient);
	Else
		ClearingAttributeAtServer("Guest");
	EndIf;
	ClearTotalsAtClient();
	ClearTotalsByGroupAtClient();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomClearing(pItem, pStandardProcessing)
	ClearingAttributeAtServer("Room");
	ClearTotalsAtClient();
	ClearTotalsByGroupAtClient();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomTypeClearing(pItem, pStandardProcessing)
	ClearingAttributeAtServer("RoomType");
	ClearTotalsAtClient();
	ClearTotalsByGroupAtClient();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomRateClearing(pItem, pStandardProcessing)
	ClearingAttributeAtServer("RoomRate");
	ClearTotalsAtClient();
	ClearTotalsByGroupAtClient();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelCustomerClearing(pItem, pStandardProcessing)
	ClearingAttributeAtServer("Customer");
	ClearTotalsAtClient();
	ClearTotalsByGroupAtClient();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelAgentClearing(pItem, pStandardProcessing)
	ClearingAttributeAtServer("Agent");
	ClearTotalsAtClient();
	ClearTotalsByGroupAtClient();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelAllotmentClearing(pItem, pStandardProcessing)
	ClearingAttributeAtServer("RoomQuota");
	ClearTotalsAtClient();
	ClearTotalsByGroupAtClient();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelClientClearing(pItem, pStandardProcessing)
	ClearingAttributeAtServer("Guest");
	ClearTotalsAtClient();
	ClearTotalsByGroupAtClient();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DocumentListIsInHouseSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	vRowData = pItem.CurrentData;
	If vRowData <> Undefined Then
		pStandardProcessing = False;
		If Items.DocumentListIsInHouse.ChoiceMode Then
			NotifyChoice(vRowData.Ref);
		Else
			If pField.Name = "DocumentListIsInHouseGuestGroup" And ValueIsFilled(vRowData.GuestGroup) Then
				OpenForm("Catalog.GuestGroups.Form.tcItemForm", New Structure("Key", vRowData.GuestGroup));
			Else
				// APDEX
				vKeyOperation = "Document.Accommodation.Form.tcDocumentForm.OpenForm";  
				vApdexRemarks = GetRemarksForAPDEX(vRowData.Ref);
				APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, , vApdexRemarks);

				OpenForm("Document.Accommodation.ObjectForm", New Structure("Key", vRowData.Ref));
			EndIf;
		EndIf;
	EndIf;
EndProcedure // DocumentListIsInHouseSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure DocumentListAllSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	vRowData = pItem.CurrentData;
	If vRowData <> Undefined Then
		pStandardProcessing = False;
		If Items.DocumentListAll.ChoiceMode Then
			NotifyChoice(vRowData.Ref);
		Else
			If pField.Name = "DocumentListAllGuestGroup" And ValueIsFilled(vRowData.GuestGroup) Then
				OpenForm("Catalog.GuestGroups.Form.tcItemForm", New Structure("Key", vRowData.GuestGroup));
			Else
				// APDEX
				vKeyOperation = "Document.Accommodation.Form.tcDocumentForm.OpenForm";    
				vApdexRemarks = GetRemarksForAPDEX(vRowData.Ref);
				APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, , vApdexRemarks);

				OpenForm("Document.Accommodation.ObjectForm", New Structure("Key", vRowData.Ref));
			EndIf;
		EndIf;
	EndIf;	
EndProcedure // DocumentListAllSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure DocumentListReservationSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	vRowData = pItem.CurrentData;
	If vRowData <> Undefined Then
		pStandardProcessing = False;
		If Items.DocumentListReservation.ChoiceMode Then
			NotifyChoice(vRowData.Ref);
		Else
			If pField.Name = "DocumentListReservationGuestGroup" And ValueIsFilled(vRowData.GuestGroup) Then
				OpenForm("Catalog.GuestGroups.Form.tcItemForm", New Structure("Key", vRowData.GuestGroup));
			Else
				vDocRef = GetRefToBeOpened(vRowData.Ref);
				If TypeOf(vDocRef) = Type("DocumentRef.Accommodation") Then
					// APDEX
					vKeyOperation = "Document.Accommodation.Form.tcDocumentForm.OpenForm";  
					vApdexRemarks = GetRemarksForAPDEX(vDocRef);
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
	EndIf;
EndProcedure // DocumentListReservationSelection

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
&AtClient
Procedure PrintInvoiceAfterInvoiceSelection(pItem, pExtraParams) Export
	If pItem <> Undefined Then
		vInvoice = pItem.Value;
		PrintInvoice(vInvoice);
	EndIf;
EndProcedure // PrintInvoiceAfterInvoiceSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure DocumentListIsInHouseOnActivateRow(pItem)
	If SkipOnRowActivateEvent Then
		SkipOnRowActivateEvent = False
	Else
		AttachIdleHandler("IsInHouseListOnActivateRowIdleHandler", 0.5, True);
	EndIf;
EndProcedure // DocumentListIsInHouseOnActivateRow

// -----------------------------------------------------------------------------
&AtClient
Procedure DocumentListAllOnActivateRow(pItem)
	If SkipOnRowActivateEvent Then
		SkipOnRowActivateEvent = False;
	Else
		AttachIdleHandler("ListAllOnActivateRowIdleHandler", 0.5, True);
	EndIf;
EndProcedure // DocumentListAllOnActivateRow

// -----------------------------------------------------------------------------
&AtClient
Procedure DocumentListReservationOnActivateRow(pItem)
	If SkipOnRowActivateEvent Then
		SkipOnRowActivateEvent = False;
	Else
		AttachIdleHandler("ReservationListOnActivateRowIdleHandler", 0.5, True);
	EndIf;
EndProcedure // DocumentListReservationOnActivateRow

// -----------------------------------------------------------------------------
&AtClient
Procedure DocumentListIsInHouseBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder, pParameter)
	If Not ValueIsFilled(SelHotel) Then
		ShowMessageBox(, NStr("en='Please, choose hotel first!'; ru='Пожалуйста сначала выберите отель!'; de='Bitte wählen Sie zuerst ein Hotel aus!'"));
		pCancel = True;
		Return;
	EndIf;
	If pClone Then
		pCancel = True;
		CopyAccommodation(Commands.CopyAccommodation);
	EndIf;
EndProcedure // DocumentListIsInHouseBeforeAddRow

// -----------------------------------------------------------------------------
&AtClient
Procedure DocumentListAllBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder, pParameter)
	If Not ValueIsFilled(SelHotel) Then
		ShowMessageBox(, NStr("en='Please, choose hotel first!'; ru='Пожалуйста сначала выберите отель!'; de='Bitte wählen Sie zuerst ein Hotel aus!'"));
		pCancel = True;
		Return;
	EndIf;
	If pClone Then
		pCancel = True;
		CopyAccommodation(Commands.CopyAccommodation);
	EndIf;
EndProcedure // DocumentListAllBeforeAddRow

// -----------------------------------------------------------------------------
&AtClient
Procedure DocumentListReservationBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder, pParameter)
	If Not ValueIsFilled(SelHotel) Then
		ShowMessageBox(, NStr("en='Please, choose hotel first!'; ru='Пожалуйста сначала выберите отель!'; de='Bitte wählen Sie zuerst ein Hotel aus!'"));
		pCancel = True;
		Return;
	EndIf;
EndProcedure // DocumentListReservationBeforeAddRow

// -----------------------------------------------------------------------------
&AtClient
Procedure TDocumentCustomerClick(pItem, pStandardProcessing)
	pStandardProcessing = False;
	vUCList = New ValueList();
	vUCList.Add(0, NStr("en='Filter list by customer...'; ru='Отфильтровать список по контрагенту...'; de='Liste nach Firma filtern...'"));
	vUCList.Add(1, NStr("en='Open customer details form...'; ru='Открыть форму сведений о контрагенте...'; de='Firmendatenformular öffnen...'"));
	ShowChooseFromMenu(New NotifyDescription("AfterTDocumentCustomerClickAnswer", ThisObject, TDocumentCustomer), vUCList, pItem);
EndProcedure // TDocumentCustomerClick

// -----------------------------------------------------------------------------
&AtClient
Procedure TDocumentAgentClick(pItem, pStandardProcessing)
	pStandardProcessing = False;
	vUCList = New ValueList();
	vUCList.Add(0, NStr("en='Filter list by agent...'; ru='Отфильтровать список по агенту...'; de='Liste nach Vertreter filtern...'"));
	vUCList.Add(1, NStr("en='Open agent details form...'; ru='Открыть форму сведений о агенте...'; de='Vertreterendatenformular öffnen...'"));
	ShowChooseFromMenu(New NotifyDescription("AfterTDocumentAgentClickAnswer", ThisObject, TDocumentAgent), vUCList, pItem);
EndProcedure // TDocumentAgentClick

// -----------------------------------------------------------------------------
&AtClient
Procedure CurGuestGroupClick(pItem, pStandardProcessing)
	pStandardProcessing = False;
	vUCList = New ValueList();
	vUCList.Add(0, NStr("en='Filter list by guest group...'; ru='Отфильтровать список по группе...'; de='Liste nach Gruppe filtern...'"));
	vUCList.Add(1, NStr("en='Open guest group details form...'; ru='Открыть карточку группы...'; de='Gruppeformular öffnen...'"));
	ShowChooseFromMenu(New NotifyDescription("AfterCurGuestGroupClickAnswer", ThisObject, CurGuestGroup), vUCList, pItem);
EndProcedure // CurGuestGroupClick

// -----------------------------------------------------------------------------
&AtClient
Procedure TDocumentPeriodClick(pItem, pStandardProcessing)
	pStandardProcessing = False;
	If ValueIsFilled(TDocument) Then
		ShowValue(, TDocument);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure TDocumentRoomPresentationClick(pItem, pStandardProcessing)
	pStandardProcessing = False;
	If ValueIsFilled(TDocumentRoom) Then
		ShowValue(, TDocumentRoom);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DocumentListAllBeforeRowChange(pItem, pCancel)
	// APDEX
	vKeyOperation = "Document.Accommodation.Form.tcDocumentForm.OpenForm";
	APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DocumentListIsInHouseBeforeRowChange(pItem, pCancel)
	// APDEX
	vKeyOperation = "Document.Accommodation.Form.tcDocumentForm.OpenForm";
	APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DocumentListReservationBeforeRowChange(pItem, pCancel)
	// APDEX
	vKeyOperation = "Document.Reservation.Form.tcDocumentForm.OpenForm";
	APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure FuncButtonClickReservation(pCommand)
	vRowData = Items.DocumentListReservation.CurrentData;
	If vRowData <> Undefined Then
		vActionsNumber = StrReplace(pCommand.Name, "FuncReservation", "");
		vAction = GetActionForNumberReservation(vActionsNumber);
		
		If ValueIsFilled(vAction.ExternalProcessing) Then
		Else
			If vAction.PredefinedDataName = "ReservationFillSettlement" Then
				// ReservationFillSettlement(vAction, pIsInAutomaticMode, pDocObj);
			ElsIf vAction.PredefinedDataName = "ReservationGuestGroupFillSettlement" Then
				// ReservationGuestGroupFillSettlement(vAction, pIsInAutomaticMode);
			ElsIf vAction.PredefinedDataName = "ReservationFillInvoice" Then
				vParam = New Structure;
				vParam.Insert("ParentDoc", vRowData.Ref);
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
				SendWelcomeSMSReservation(vRowData.Ref);
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
EndProcedure // FuncButtonClickReservation

// -----------------------------------------------------------------------------
&AtClient
Procedure FuncButtonClickAccommodation(pCommand)
	vPage = "DocumentListIsInHouse";
	If SelFilterStatus = 1 Then
		vPage = "DocumentListAll";
	EndIf;
	vRowData = Items[vPage].CurrentData;
	If vRowData <> Undefined Then
		vActionsNumber = StrReplace(pCommand.Name, "FuncAccommodation", "");
		vAction = GetActionForNumberAccommodation(vActionsNumber);
		
		If ValueIsFilled(vAction.ExternalProcessing) Then
		Else
			If vAction.PredefinedDataName = "AccommodationSendWelcomeSMS" Then
				SendWelcomeSMSAccommodation(vRowData.Ref);
			ElsIf vAction.PredefinedDataName = "AccommodationFillClientFeedback" Then
				AccommodationFillClientFeedback(vRowData.Ref);
			ElsIf vAction.PredefinedDataName = "AccommodationFillAccommodation" Then
				// APDEX                                                                
				vApdexRemarks = GetRemarksForAPDEX(vRowData.Ref);
				vKeyOperation = "Document.Accommodation.Form.tcDocumentForm.OpenForm";
				APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, , vApdexRemarks);

				vParam = New Structure;
				vParam.Insert("ParentAccommodation", vRowData.Ref);
				OpenForm("Document.Accommodation.Form.tcDocumentForm", vParam, , New UUID);
			ElsIf vAction.PredefinedDataName = "AccommodationGuestGroupFillInvoice" Then
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
			ElsIf vAction.PredefinedDataName = "AccommodationFillInvoice" Then
				vParam = New Structure;
				vParam.Insert("basis", vRowData.Ref);
				OpenForm("Document.ProformaInvoice.Form.tcDocumentForm", vParam, ThisObject, True);	
			ElsIf vAction.PredefinedDataName = "AccommodationGuestGroupFillSettlement" Then
				vParam = New Structure;
				vParam.Insert("basis", vRowData.GuestGroup);
				OpenForm("Document.Settlement.Form.tcDocumentForm", vParam, ThisObject, True);	
			ElsIf vAction.PredefinedDataName = "AccommodationFillSettlement" Then
				vParam = New Structure;
				vParam.Insert("basis", vRowData.Ref);
				OpenForm("Document.Settlement.Form.tcDocumentForm", vParam, ThisObject, True);	
			ElsIf vAction.PredefinedDataName = "AccommodationFillOrder" Then
				vParam = New Structure;
				vParam.Insert("basis", vRowData.Ref);
				OpenForm("Document.Order.Form.DocumentForm", vParam, ThisObject,True);
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
EndProcedure // FuncButtonClickAccommodation

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintButtonClickReservation(pCommand)
	vRowData = Items.DocumentListReservation.CurrentData;
	If vRowData <> Undefined Then
		vPrintNumber = StrReplace(pCommand.Name, "PrintReservation", "");
		vPrintForm = GetPrintFormForNumberReservation(vPrintNumber);
		
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
			PrintHotelProduct(vPrintForm.Language, vPrintForm.Ref, vRowData.Ref);
		ElsIf vPrintForm.PredefinedDataName = "ReservationPrintConfirmationRu" Or
		      vPrintForm.PredefinedDataName = "ReservationPrintConfirmationEn" Or
			  vPrintForm.PredefinedDataName = "ReservationPrintConfirmationDe" Then
			vParams = new Structure("SelReservation, SelReservationObj, SelLanguage, SelObjectPrintForm, CloseOnOwnerClose", 
			                        vRowData.Ref,
			                        , 
			                        tcOnServer.cmGetAttributeByRef(vPrintForm.Ref, "Language"),
			                        vPrintForm.Ref,
			                        False);
			OpenForm("Document.Reservation.Form.tcReservationConfirmationForm", vParams, ThisObject, New UUID());
		ElsIf vPrintForm.PredefinedDataName = "ReservationPrintCurrentDocConfirmationRu" Or
		      vPrintForm.PredefinedDataName = "ReservationPrintCurrentDocConfirmationEn" Or
			  vPrintForm.PredefinedDataName = "ReservationPrintCurrentDocConfirmationDe" Then
			vParams = new Structure("SelReservation, SelReservationObj, SelLanguage, SelObjectPrintForm, CloseOnOwnerClose, SelShowConfirmationForCurrentReservationOnly", 
			                        vRowData.Ref,
			                        , 
			                        tcOnServer.cmGetAttributeByRef(vPrintForm.Ref, "Language"),
			                        vPrintForm.Ref,
			                        False,
			                        True);
			OpenForm("Document.Reservation.Form.tcReservationConfirmationForm", vParams, ThisObject, New UUID());
		ElsIf vPrintForm.PredefinedDataName = "ReservationPrintConfirmationWithServicesRu" Or
		      vPrintForm.PredefinedDataName = "ReservationPrintConfirmationWithServicesEn" Or
		      vPrintForm.PredefinedDataName = "ReservationPrintConfirmationWithServicesDe" Then
			vParams = new Structure("SelReservation, SelReservationObj, SelLanguage, SelObjectPrintForm, CloseOnOwnerClose", 
			                        vRowData.Ref,
			                        , 
			                        tcOnServer.cmGetAttributeByRef(vPrintForm.Ref, "Language"),
			                        vPrintForm.Ref,
			                        False);
			OpenForm("Document.Reservation.Form.tcReservationConfirmationWithServicesForm", vParams, ThisObject, New UUID());
		ElsIf vPrintForm.PredefinedDataName = "ReservationPrintCurrentDocConfirmationWithServicesRu" Or
		      vPrintForm.PredefinedDataName = "ReservationPrintCurrentDocConfirmationWithServicesEn" Or
		      vPrintForm.PredefinedDataName = "ReservationPrintCurrentDocConfirmationWithServicesDe" Then
			vParams = new Structure("SelReservation, SelReservationObj, SelLanguage, SelObjectPrintForm, CloseOnOwnerClose, SelShowConfirmationForCurrentReservationOnly", 
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
EndProcedure // PrintButtonClickReservation

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintButtonClickAccommodation(pCommand)
	vPage = "DocumentListIsInHouse";
	If SelFilterStatus = 1 Then
		vPage = "DocumentListAll";
	EndIf;
	vRowData = Items[vPage].CurrentData;
	If vRowData <> Undefined Then
		vPrintNumber = StrReplace(pCommand.Name, "PrintAccommodation", "");
		vPrintForm = GetPrintFormForNumberAccommodation(vPrintNumber);
		
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
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'")+Chars.LF+BriefErrorDescription(ErrorInfo()), MessageStatus.Attention);
			EndTry;
		ElsIf vPrintForm.PredefinedDataName = "AccommodationPrintHotelProduct" Or
		      vPrintForm.PredefinedDataName = "AccommodationPrintGuestGroupHotelProducts" Then
			PrintHotelProduct(vPrintForm.Language, vPrintForm.Ref, vRowData.Ref);
		ElsIf vPrintForm.PredefinedDataName = "AccommodationPrintGuestForm2Forms5" Or 
		      vPrintForm.PredefinedDataName = "AccommodationPrintGuestFormFreeForm" Or
		      vPrintForm.PredefinedDataName = "AccommodationPrintGuestRegistrationForm" Then
			PrintGuestForm(vPrintForm.PredefinedDataName, vRowData.Ref);
		ElsIf vPrintForm.PredefinedDataName = "AccommodationPrintGuestsForms2Forms5" Or 
		      vPrintForm.PredefinedDataName = "AccommodationPrintGuestsFormsFreeForm" Or
		      vPrintForm.PredefinedDataName = "AccommodationPrintGuestRegistrationForms" Then
			PrintGuestsForms(vPrintForm.PredefinedDataName, vRowData.Ref);
		ElsIf vPrintForm.PredefinedDataName = "AccommodationPrintGuestPersonalDataProcessingConsent" Then
			PrintGuestPersonalDataProcessingConsent(vRowData.Ref);
		ElsIf vPrintForm.PredefinedDataName = "AccommodationPrintGuestRefusalToPayResortFee" Then
			PrintGuestRefusalToPayResortFee(vRowData.Ref);
		EndIf;
	EndIf;
EndProcedure // PrintButtonClickAccommodation

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeStatus(pCommand)
	If Items.DocumentListReservation.SelectedRows.Count()= 0 Then
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
Procedure CheckOut(pCommand)
	vPage = "";
	If SelFilterStatus = 0 Or SelFilterStatus = 3 Then
		vPage = "DocumentListIsInHouse";
	ElsIf SelFilterStatus = 1 Then
		vPage = "DocumentListAll";
	Else
		Return;
	EndIf;
	vCurDocRef = Items[vPage].CurrentRow;
	If vCurDocRef <> Undefined Then
		vCurDocNumber = "";
		vGuestsFromOneRoomSelected = True;
		vSelectedDocs = New Array();
		For Each vSelDocRef In Items[vPage].SelectedRows Do
			vSelectedDocs.Add(New Structure("Ref, GuestRef, AccommodationType", vSelDocRef, tcOnServer.cmGetAttributeByRef(vSelDocRef, "Guest"), tcOnServer.cmGetAttributeByRef(vSelDocRef, "AccommodationType")));
			vDocNumber = tcOnServer.cmGetAttributeByRef(vSelDocRef, "Number");
			If IsBlankString(vCurDocNumber) Then
				vCurDocNumber = vDocNumber;
			EndIf;
			If vDocNumber <> vCurDocNumber Then
				vGuestsFromOneRoomSelected = False;
				Break;
			EndIf;
		EndDo;
		If SelShowAllGuests = 1 And vGuestsFromOneRoomSelected Then
			// Add other room guests to the array
			If vSelectedDocs.Count() = 1 Then
				vSelectedDocs.Clear();
				AddOneRoomAccommodations(vSelectedDocs, vSelDocRef, True);
				If vSelectedDocs.Count() > 0 Then
					vCurDocRef = vSelectedDocs[0].Ref;
				EndIf;
			EndIf;
			OpenForm("CommonForm.tcChangeRoomWizard", New Structure("DocRef, OperationType, GuestTable", vCurDocRef, 2, vSelectedDocs), ThisObject);
			Return;
		Else
			MainRoomDoc = GetMainDocRef(vCurDocRef);
		EndIf;
		// Give warning if current date is less then expected check-out date
		vCheckInDate = tcOnServer.cmGetAttributeByRef(MainRoomDoc, "CheckInDate");
		vExpectedCheckOutDate = tcOnServer.cmGetAttributeByRef(MainRoomDoc, "CheckOutDate");
		If BegOfDay(vExpectedCheckOutDate) > BegOfDay(CurrentDate()) Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Expected check-out date " + Format(vExpectedCheckOutDate, "DF=dd.MM.yyyy") + " is in the future!'; 
			                                                |de='Voraussichtliches Abreisedatum " + Format(vExpectedCheckOutDate, "DF=dd.MM.yyyy") + " liegt in der Zukunft!'; 
			                                                |ru='Дата планируемого выезда " + Format(vExpectedCheckOutDate, "DF=dd.MM.yyyy") + " в будущем!'"), MessageStatus.Important);
		EndIf;
		// Get check-out date
		CheckOutDateTime = '00010101';
		If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToCheckOutOnExpectedCheckOutTime") Then
			GetCheckOutDate(vCheckInDate, vExpectedCheckOutDate);
			AttachIdleHandler("CheckIfCheckOutDateTimeIsFilled", 1, False);
		Else
			CheckOutDateTime = vExpectedCheckOutDate;
			AttachIdleHandler("CheckIfCheckOutDateTimeIsFilled", 0.1, True);
		EndIf;
	EndIf;
EndProcedure // CheckOut

// -----------------------------------------------------------------------------
&AtClient
Procedure NewReservation(pCommand)
	If Not ValueIsFilled(SelHotel) Then
		ShowMessageBox(, NStr("en='Please, choose hotel first!'; ru='Пожалуйста сначала выберите отель!'; de='Bitte wählen Sie zuerst ein Hotel aus!'"));
		Return;
	EndIf;
	vParams = New Structure("Document", tcOnServer.cmGetDocumentItemRefByDocNumber("Reservation", "", True));
	OpenForm("Document.Reservation.ObjectForm", vParams, ThisObject);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure EditDocument(pCommand)
	If SelFilterStatus = 2 Then
		vCurData = Items.DocumentListReservation.CurrentData;
		If vCurData <> Undefined Then
			vDocRef = GetRefToBeOpened(vCurData.Ref);
			If TypeOf(vDocRef) = Type("DocumentRef.Accommodation") Then
				// APDEX
				vKeyOperation = "Document.Accommodation.Form.tcDocumentForm.OpenForm";  
				vApdexRemarks = GetRemarksForAPDEX(vDocRef);
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
	ElsIf SelFilterStatus = 0 Or SelFilterStatus = 3 Then
		vCurData = Items.DocumentListIsInHouse.CurrentData;
		If vCurData <> Undefined Then
			// APDEX
			vKeyOperation = "Document.Accommodation.Form.tcDocumentForm.OpenForm";  
			vApdexRemarks = GetRemarksForAPDEX(vCurData.Ref);
			APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, , vApdexRemarks);

			OpenForm("Document.Accommodation.ObjectForm", New Structure("Key", vCurData.Ref));
		EndIf;
	Else
		vCurData = Items.DocumentListAll.CurrentData;
		If vCurData <> Undefined Then
			// APDEX
			vKeyOperation = "Document.Accommodation.Form.tcDocumentForm.OpenForm";  
			vApdexRemarks = GetRemarksForAPDEX(vCurData.Ref);
			APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, , vApdexRemarks);

			OpenForm("Document.Accommodation.ObjectForm", New Structure("Key", vCurData.Ref));
		EndIf;
	EndIf;
EndProcedure // EditDocument

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckIn(pCommand)
	If Not ValueIsFilled(SelHotel) Then
		ShowMessageBox(, NStr("en='Please, choose hotel first!'; ru='Пожалуйста сначала выберите отель!'; de='Bitte wählen Sie zuerst ein Hotel aus!'"));
		Return;
	EndIf;
	vSelList = Items.DocumentListReservation.SelectedRows;
	If vSelList.Count() > 1 Then
		If Items.BackgroundOperationProgress.Visible Then
			ShowMessageBox(, NStr("en='Please wait while previous background job ends or select one room for check-in!'; 
			                      |ru='Пожалуйста подождите завершения работы активного фонового задания или выберите для поселения один номер!'; 
								  |de='Bitte warten Sie, bis der aktive Hintergrundjob abgeschlossen ist, oder wählen Sie eine Zimmer für die Anreise aus!'"));
			Return;
		Endif;
		PackageCheckIn();
	ElsIf vSelList.Count() = 1 Then
		vSelResRow = vSelList[0];
		CheckInByDoc(vSelResRow);
	Else	
		Return;
	EndIf;	
EndProcedure // CheckIn

// -----------------------------------------------------------------------------
&AtClient
Procedure Refresh(pCommand)
	// APDEX
	vKeyOperation = "Document.Accommodation.Form.tcAccommodationListForm.Refresh";
	APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

	RefreshAtServer();
EndProcedure // Refesh

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure CreateGroupProformaInvoice(pCommand)
	vRef = GetCurrentRowRef();
	If ValueIsFilled(vRef) Then
		vGuestGroup = tcOnServer.cmGetAttributeByRef(vRef, "GuestGroup");
		vLastProformaForTheGroup = GetLastProformaForTheGroup(vGuestGroup);
		If ValueIsFilled(vLastProformaForTheGroup) Then
			ShowQueryBox(New NotifyDescription("DuplicateProformaInvoiceForTheGroupAnswer", ThisObject, New Structure("LastProforma, GuestGroup", vLastProformaForTheGroup, vGuestGroup)), 
			             NStr("en='The booking already has the '; ru='По брони уже есть '; de='Die Buchung hat bereits eine '") + TrimAll(vLastProformaForTheGroup) + "!" + Chars.LF + 
						 NStr("en='Answer <Yes> to open this proforma invoice. You can recalculate proforma if reservation amount has changed later in the form.';
						      |ru='Ответьте <Да>, чтобы открыть существующий счет. Если сумма бронирования изменилась, то можете пересчитать счет.'; 
							  |de='Antworten Sie mit <Ja>, um diese Proforma-Rechnung zu öffnen. Sie können die Proforma neu berechnen, wenn sich der Reservierungsbetrag später im Formular geändert hat.'") + Chars.LF +
						 NStr("en='Answer <No> to create new proforma invoice for this reservation.'; 
						      |ru='Ответьте <Нет>, чтобы создать новый счет на оплату для этого бронирования.'; 
							  |de='Antworten Sie mit <Nein>, um eine neue Proforma-Rechnung für diese Reservierung zu erstellen.'"), 
						 QuestionDialogMode.YesNoCancel, , DialogReturnCode.Yes);
		Else
			OpenNewProformaInvoiceForm(vGuestGroup);
		EndIf;
	EndIf;
EndProcedure // CreateGroupProformaInvoice

// -----------------------------------------------------------------------------
&AtClient
Procedure ScanDocuments(pCommand)
	vRef = GetCurrentRowRef();
	If ValueIsFilled(vRef) And (TypeOf(vRef) = Type("DocumentRef.Accommodation") Or TypeOf(vRef) = Type("DocumentRef.Reservation")) Then
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
EndProcedure // ScanDocuments

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenProformaInvoiceList(pCommand)
	If SelFilterStatus = 0 Or SelFilterStatus = 3 Then
		vPage = "DocumentListIsInHouse";
	ElsIf SelFilterStatus = 1 Then
		vPage = "DocumentListAll";
	Else 
		vPage = "DocumentListReservation";	
	EndIf;	
		
	vRef = Items[vPage].CurrentRow;

	OpenForm("Document.ProformaInvoice.ListForm", New Structure("SelGuestGroup", tcOnServer.cmGetAttributeByRef(vRef,"GuestGroup")), ThisObject);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenInHouseGuests(pCommand)
	vRef = GetCurrentRowRef();
	OpenForm("Document.Accommodation.ListForm", New Structure("SelGuestGroup,SelFilterStatus, AllGuests", tcOnServer.cmGetAttributeByRef(vRef,"GuestGroup"), 0, 1), ThisObject);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenReservations(pCommand)
	vRef = GetCurrentRowRef();
	OpenForm("Document.Reservation.ListForm", New Structure("SelGuestGroup,SelFilterStatus", tcOnServer.cmGetAttributeByRef(vRef,"GuestGroup"), 0), ThisObject);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenChangeHistoryReservation(pCommand)
	vRef = GetCurrentRowRef();
	vFrm = OpenForm("InformationRegister.ReservationChangeHistory.ListForm", New Structure("Filter", New Structure("Reservation", vRef)), ThisObject);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenChangeHistoryAccommodation(pCommand)
	vRef = GetCurrentRowRef();
	vFrm = OpenForm("InformationRegister.AccommodationChangeHistory.ListForm", New Structure("Accommodation", vRef), ThisObject);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenFoliosIsInHouse(pCommand)
	vRef = GetCurrentRowRef();
	If Not vRef = Undefined Then
		// APDEX
		vKeyOperation = "CommonForm.tcFoliosForm.OpenForm";   
		vApdexRemarks = GetRemarksForAPDEX(vRef);
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, , vApdexRemarks);

		vParametersStructure = New Structure("DocRef", vRef);
		OpenForm("CommonForm.tcFoliosForm", New Structure("ParametersStructure",vParametersStructure), , vRef);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure Task(pCommand)
	vRef = GetCurrentRowRef();
	stParam = New Structure("SetParamObject", vRef); 
	OpenForm("DataProcessor.Messages.Form.tcForm", stParam, ThisObject);
	Notify("DataProcessor.Messages.Form.Open", stParam);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure Pay(pCommand)
	vRef = GetCurrentRowRef();
	// Get payment folio
	vFolio = GetPaymentFolio(vRef);
	If ValueIsFilled(vFolio) Then
		// Open payment form
		OpenForm("Document.Payment.ObjectForm", New Structure("Basis", vFolio), ThisObject);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenForeignerRegistryRecord(pCommand)
	vRef = GetCurrentRowRef();
	OpenForeignerRegistryRecordForm(vRef);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeRoomWizard(pCommand)
	vRef = GetCurrentRowRef();
	// Add other one room accommodations
	vAccList = New ValueList;
	AddOneRoomAccommodations(vAccList, vRef);
	vOtherRoomGuests = New Array;
	For Each vAccListItem In vAccList Do
		vAccRef = vAccListItem.Value;
		vGuestRef = tcOnServer.cmGetAttributeByRef(vAccRef, "Guest");
		vAccTypeRef = tcOnServer.cmGetAttributeByRef(vAccRef, "AccommodationType");
		vOtherRoomGuests.Add(New Structure("Ref, GuestRef, AccommodationType", vAccRef, vGuestRef, vAccTypeRef));
	EndDo;
	OpenForm("CommonForm.tcChangeRoomWizard", New Structure("DocRef, GuestTable", vRef, vOtherRoomGuests), ThisObject);
EndProcedure // ChangeRoomWizard

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenInvoicesList(pCommand)
	vRef = GetCurrentRowRef();
	OpenForm("Document.Settlement.ListForm", New Structure("SelGuestGroup", tcOnServer.cmGetAttributeByRef(vRef,"GuestGroup")), ThisObject);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintGroupSettlement(pCommand)
	vRef = GetCurrentRowRef();
	vGuestGroup = tcOnServer.cmGetAttributeByRef(vRef,"GuestGroup");
	vMessage = "";
	vInvoice = Undefined;
	// Try to  search for unposted invoice
	vUnpostedInvoices = GetUnpostedGroupInvoices(vGuestGroup);
	If vUnpostedInvoices.Count() > 0 Then
		vInvoice = vUnpostedInvoices.Get(0).Value;
	EndIf;
	// Fill new or refill existing unposted invoice
	vResult = GuestGroupFillSettlement(vGuestGroup, vMessage, vInvoice);
	If vResult = -1 Then
		ShowMessageBox(, vMessage);
	Else
		If vResult = 0 Then
			vInvList = GetListOfGroupInvoices(vGuestGroup);
			If vInvList.Count() = 0 Then
				ShowMessageBox(, vMessage);
			ElsIf vInvList.Count() = 1 Then
				vInvoice = vInvList.Get(0).Value;
			Else
				If SelFilterStatus = 0 Or SelFilterStatus = 3 Then
					vPage = "DocumentListIsInHouse";
				ElsIf SelFilterStatus = 1 Then
					vPage = "DocumentListAll";
				Else 
					vPage = "DocumentListReservation";	
				EndIf;	
				vRow = Items[vPage].CurrentRow;
				ShowChooseFromMenu(New NotifyDescription("PrintInvoiceAfterInvoiceSelection", ThisObject), vInvList, vRow);
			EndIf;
		EndIf;
		If ValueIsFilled(vInvoice) Then
			PrintInvoice(vInvoice);
		EndIf;
	EndIf;
EndProcedure // PrintGroupSettlement

// -----------------------------------------------------------------------------
&AtClient
Procedure MakeKey(pCommand)
	vPage = "DocumentListIsInHouse";
	If SelFilterStatus = 1 Then
		vPage = "DocumentListAll";
	ElsIf SelFilterStatus = 2 Then
		vPage = "DocumentListReservation";
		// Check user rights
		If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToIssueKeyCardsBasedOnReservations") Then
			ShowMessageBox(, NStr("en = 'You do not have rights to issue key cards based on reservation!'; de = 'Sie sind nicht berechtigt, Schlüssel für Reservierung auszugeben!'; ru = 'Нет прав на выдачу ключей по брони!'"));
			Return;
		EndIf;
	EndIf;
	vRowData = Items[vPage].CurrentData;
	If vRowData <> Undefined Then
		vParametersKeyCard = tcOnServer.cmFillParametersKeyCard(vRowData.Ref);
		vParams = New Structure();
		vParams.Insert("ParametersKeyCard", vParametersKeyCard);
		vParams.Insert("ParametersOneGuestMode", ?(SelShowAllGuests = 0, False, True));
		vCurWorkstation = tcOnServer.cmGetSessionParametersAttribute("CurrentWorkstation");
		OpenForm("CommonForm.tcIssueKeyCard", vParams, ThisObject, vCurWorkstation, , , , FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure // MakeKey

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomAssignment(pCommand)
	If Not ValueIsFilled(SelHotel) Then
		ShowMessageBox(, NStr("en='Hotel should be selected!'; ru='Гостиница должна быть выбрана!'; de='Hotel sollte ausgewählt werden!'"));
		Return;
	EndIf;
	
	vCheckInDate = SelCheckInDate;
	If Not ValueIsFilled(vCheckInDate) Then
		vCheckInDate = BegOfDay(CurrentDate());
	EndIf;
	
	If Items.DocumentListReservation.SelectedRows.Count() > 1 Then
		vReservations = New ValueList();
		For Each vRowIndex In Items.DocumentListReservation.SelectedRows Do
			vRowData = Items.DocumentListReservation.RowData(vRowIndex);
			If ValueIsFilled(vRowData.AccommodationTemplate) Then
				If IsActiveReservation(vRowData.Ref) Then
					vReservations.Add(vRowData.Ref);
				EndIf;
			EndIf;
		EndDo;
		OpenForm("Document.Reservation.Form.tcRoomAssignmentForm", New Structure("SelHotel, SelReservations", SelHotel, vReservations), ThisObject);
	ElsIf ValueIsFilled(vCheckInDate) Then
		OpenForm("Document.Reservation.Form.tcRoomAssignmentForm", New Structure("SelHotel, SelCheckInDate", SelHotel, BegOfDay(vCheckInDate)), ThisObject);
	Else
		ShowMessageBox(, NStr("en='Please specify either check-in date filter or select more then one reservation in the list!'; 
		                      |ru='Пожалуйста либо укажите отбор по дате заезда либо выделите в списке более одной брони!'; 
							  |de='Bitte wählen Sie Anreisedatum-Filter oder wählen Sie mehr als eine Reservierung in der Liste aus!'"));
	EndIf;
EndProcedure // RoomAssignment

// -----------------------------------------------------------------------------
&AtClient
Procedure CopyAccommodation(pCommand)
	If Not ValueIsFilled(SelHotel) Then
		ShowMessageBox(, NStr("en='Please, choose hotel first!'; ru='Пожалуйста сначала выберите отель!'; de='Bitte wählen Sie zuerst ein Hotel aus!'"));
		Return;
	EndIf;
	vCurData = Undefined;
	If SelFilterStatus = 1 Then
		vCurData = Items.DocumentListAll.CurrentData;
	ElsIf SelFilterStatus = 0 Or SelFilterStatus = 3 Then
		vCurData = Items.DocumentListIsInHouse.CurrentData;
	ElsIf SelFilterStatus = 2 Then
		vCurData = Items.DocumentListReservation.CurrentData;
	EndIf;
	// Ask if to clear guests from reservation
	If vCurData <> Undefined And ValueIsFilled(vCurData.Ref) Then
		OpenForm("Catalog.GuestGroups.Form.tcReservationCopyOptions", New Structure("ClearGuestNames, UseSameFoliosAndBillingInstructions, TemplateDocument, CopyToTheNewGuestGroup, GuestGroup", True, False, vCurData.Ref, True, vCurData.GuestGroup), ThisObject);
	EndIf;
EndProcedure // CopyAccommodation

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowDirectPostings(pCommand)
	If SelFilterStatus = 0 Or SelFilterStatus = 3 Then
		vCurDocRef = Items.DocumentListIsInHouse.CurrentRow;
		If vCurDocRef <> Undefined Then
			vRoom = tcOnServer.cmGetAttributeByRef(vCurDocRef, "Room");
			vClient = tcOnServer.cmGetAttributeByRef(vCurDocRef, "Guest");
			#If Not MobileClient Then 
				OpenForm("CommonForm.tcDirectPostingsForm", New Structure("Room, Client", vRoom, vClient), , vRoom);
			#Else
				OpenForm("CommonForm.mcDirectPostingsForm", New Structure("Room, Client", vRoom, vClient), , vRoom);	
			#EndIf
		EndIf;
	EndIf;
EndProcedure // ShowDirectPostings

// -----------------------------------------------------------------------------
&AtClient
Procedure RefreshTotals(pCommand)
	UpdateTotalsAtServer();
	AttachIdleHandler("GetFOTotalsJobResults", 1, True);
EndProcedure // RefreshTotals

// -----------------------------------------------------------------------------
&AtClient
Procedure ExportGuestDataToUFMSRu(pCommand)
	vList = Undefined;
	If SelFilterStatus = 0 Or SelFilterStatus = 3 Then
		vList = Items.DocumentListIsInHouse;
	ElsIf SelFilterStatus = 1 Then
		vList = Items.DocumentListAll;
	EndIf;
	If vList <> Undefined And vList.SelectedRows.Count() > 0 Then
		vDPRef = GetDataProcessorForExportGuestDataToUFMS();
		If Not ValueIsFilled(vDPRef) Then
			ShowMessageBox(, NStr("en='Data processor for export is not configured!'; ru='Не настроена обработка экспорта!'; de='Exportverarbeitung nicht konfiguriert!'"));
		Else
			vAccommodationsList = New ValueList();
			For Each vSelDocRef In vList.SelectedRows Do
				vAccommodationsList.Add(vSelDocRef);
			EndDo;
			OpenForm("DataProcessor.ExportGuestsToUFMSTerritoryApp.Form.tcDPForm", New Structure("DataProcessor, Accommodations, GenerateOnOpen", vDPRef, vAccommodationsList, True), , vSelDocRef);
		EndIf;
	EndIf;
EndProcedure // ExportGuestDataToUFMSRu

// -----------------------------------------------------------------------------
&AtClient
Procedure IssueIdentityCard(pCommand)
	If SelFilterStatus = 0 Then
		vPage = "DocumentListIsInHouse";
	ElsIf SelFilterStatus = 1 Then
		vPage = "DocumentListAll";
	ElsIf SelFilterStatus = 2 Then
		vPage = "DocumentListReservation";	
	Else
		Return;
	EndIf;
	vRowData = Items[vPage].CurrentData;
	If vRowData <> Undefined Then
		vParameters = FillParametersCard(vRowData.Ref);
		If ValueIsFilled(vParameters.IdentityCardSystemParameters) Then
			vArrIdentityCardSystemParameters = tcOnServer.cmGetAtributeAsArray(vParameters.IdentityCardSystemParameters);
			If ValueIsFilled(vArrIdentityCardSystemParameters.ExternalInteraction) And 
				tcOnServer.cmGetAttributeByRef(vArrIdentityCardSystemParameters.ExternalInteraction, "IntegrationType") = PredefinedValue("Enum.Integrations.ISD") Then
				OpenForm("CommonForm.tcRoomIdentityCardsRegistrationISD", vParameters, ThisObject, , , , , FormWindowOpeningMode.LockWholeInterface);	
			ElsIf vArrIdentityCardSystemParameters.IssueCardsForAllGuestsInTheRoom And ValueIsFilled(vParameters.Room) Then
				OpenForm("CommonForm.tcRoomIdentityCardsRegistration", vParameters, ThisObject, , , , , FormWindowOpeningMode.LockWholeInterface);
			Else
				OpenForm("CommonForm.tcClientIdentityCardsRegistration", vParameters, ThisObject, , , , , FormWindowOpeningMode.LockWholeInterface);
			EndIf;
		Else
			ShowMessageBox(, NStr("en = 'Client identity cards system is not configurated properly for the current workstation!'; 
								  |de = 'Das System für Kundenausweise ist auf diesem Arbeitsplatz nicht eingestellt!'; 
								  |ru = 'Система карт идентификации клиентов на данном рабочем месте не настроена!'"));
		EndIf;
	EndIf;
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure FillVauchersForSelectedDocuments(pCommand)
	vDocsList = New ValueList();
	vList = Undefined;
	If SelFilterStatus = 0 Or SelFilterStatus = 3 Then
		vList = Items.DocumentListIsInHouse;
	ElsIf SelFilterStatus = 1 Then
		vList = Items.DocumentListAll;
	Else
		vList = Items.DocumentListReservation;
	EndIf;
	If vList <> Undefined And vList.SelectedRows.Count() > 0 Then
		For Each vSelDocRef In vList.SelectedRows Do
			vDocsList.Add(vSelDocRef);
		EndDo;
	EndIf;
	OpenForm("CommonForm.tcFillVauchersInReservations", New Structure("DocumentsList", vDocsList), ThisObject);
EndProcedure // FillVauchersForSelectedDocuments

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure OnReopenAtServer()
	// Filter by parameters
	If Parameters.Property("Room") And ValueIsFilled(Parameters.Room) Then
		SelRoom = Parameters.Room;
		If SelRoom.IsFolder Then
			AttributeChangeAtServer("Room", SelRoom, DataCompositionComparisonType.InHierarchy);   
		Else
			AttributeChangeAtServer("Room", SelRoom);   
		EndIf;
	EndIf;
	If Parameters.Property("RoomType") And ValueIsFilled(Parameters.RoomType) Then
		SelRoomType = Parameters.RoomType;
		If SelRoomType.IsFolder Then
			AttributeChangeAtServer("RoomType", SelRoomType, DataCompositionComparisonType.InHierarchy);   
		Else
			AttributeChangeAtServer("RoomType", SelRoomType);   
		EndIf;
	EndIf;
	If Parameters.Property("Allotment") And ValueIsFilled(Parameters.Allotment) Then
		SelAllotment = Parameters.Allotment;
		If SelAllotment.IsFolder Then
			AttributeChangeAtServer("RoomQuota", SelAllotment, DataCompositionComparisonType.InHierarchy);   
		Else
			AttributeChangeAtServer("RoomQuota", SelAllotment);   
		EndIf;
	EndIf;
	If Parameters.Property("BedsSetup") And ValueIsFilled(Parameters.BedsSetup) Then
		SelBedsSetup = Parameters.BedsSetup;
		AttributeChangeAtServer("BedsSetup", SelBedsSetup);   
	EndIf;
	If Parameters.Property("SelGuestGroup") And ValueIsFilled(Parameters.SelGuestGroup) Then
		SelGuestGroup = Parameters.SelGuestGroup;
		AttributeChangeAtServer("GuestGroup", SelGuestGroup);
	EndIf;
	ClearTotalsAtServer();
	ClearTotalsByGroupAtServer();
EndProcedure // OnReopenAtServer

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
				vPicture = PictureLib.AccumulationRegister;
			Else
				vPicture = PictureLib.IsActive;
			EndIf;
		ElsIf pReservationStatus.IsCheckIn Then
			vPicture = PictureLib.IsCheckIn;
		ElsIf pReservationStatus.IsNoShow Then
			vPicture = PictureLib.Attention;
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
Procedure FillFilterStatuses()
	// Clear change status menu
	For Each vInd In SelSetStatusListButton Do
		vButton = Items.Find(vInd.Presentation);
		If TypeOf(vButton) = Type("FormButton") Then
			Items.Delete(vButton);
		EndIf;	
	EndDo;	

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
	|	AND (NOT &qHotelIsFilled
	|			OR &qHotelIsFilled
	|				AND ReservationStatuses.Hotel = VALUE(Catalog.Hotels.EmptyRef)
	|			OR &qHotelIsFilled
	|				AND ReservationStatuses.Hotel = &qHotel)
	|
	|ORDER BY
	|	SortCode,
	|	Description";
	vQry.SetParameter("qHotel", SelHotel);
	vQry.SetParameter("qHotelIsFilled", ValueIsFilled(SelHotel));
	vElements = vQry.Execute();
	
	// Fill list of filter elements
	vTrans = vElements.Select();
	While vTrans.Next() Do
		If vTrans.ReservationStatus.IsCheckIn Then
			Continue;
		EndIf;

		vResStatusIcon = pmGetReservationStatusIcon(vTrans.ReservationStatus);
		
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
EndProcedure // FillFilterStatuses

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
Procedure ChangeStatusAtServer(pAnnulationReason, pGuaranteeType)
	vStatusRef = SelResStatus;
	vAnnulationReason = pAnnulationReason;
	vGuaranteeType = pGuaranteeType;

	vResList = New ValueList();
	vSelRows = Items.DocumentListReservation.SelectedRows;
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
	Items.DocumentListReservation.Refresh();
EndProcedure // ChangeStatusAtServer

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
&AtServer
Procedure AllGuestsOnChangeAtServer()
	SetParametersDynamicList();
	If SelShowAllGuests = 1  Then
		// Reservation
		Items.DocumentListReservationAccommodationType.Visible = True;
		Items.DocumentListReservationAccommodationTemplate.Visible = True;
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(DocumentListReservation,"AccommodationTemplate",,,,False);
		// DocumentListArhive
		Items.DocumentListAllAccommodationType.Visible = True;
		Items.DocumentListAllAccommodationTemplate.Visible = True;
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(DocumentListALL,"AccommodationTemplate",,,,False);
		// DocumentListIsInHouse
		Items.DocumentListIsInHouseAccommodationType.Visible = True;
		Items.DocumentListIsInHouseAccommodationTemplate.Visible = True;
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(DocumentListIsInHouse,"AccommodationTemplate",,,,False);
	Else
		// Reservation
		Items.DocumentListReservationAccommodationType.Visible = False;
		Items.DocumentListReservationAccommodationTemplate.Visible = True;
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(DocumentListReservation,"AccommodationTemplate",Catalogs.AccommodationTemplates.EmptyRef(),DataCompositionComparisonType.NotEqual,,True);
		// DocumentListArhive
		Items.DocumentListAllAccommodationType.Visible = False;
		Items.DocumentListAllAccommodationTemplate.Visible = True;
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(DocumentListALL,"AccommodationTemplate",Catalogs.AccommodationTemplates.EmptyRef(),DataCompositionComparisonType.NotEqual,,True);
		// DocumentListIsInHouse
		Items.DocumentListIsInHouseAccommodationType.Visible = False;
		Items.DocumentListIsInHouseAccommodationTemplate.Visible = True;
	    tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(DocumentListIsInHouse,"AccommodationTemplate",Catalogs.AccommodationTemplates.EmptyRef(),DataCompositionComparisonType.NotEqual,,True);
	EndIf; 
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure UpdateTotalsAtServer()
	vTempStorageAdress = PutToTempStorage(Undefined, UUID);
	
	vProcedureParameters = new Array;
	vProcedureParameters.Add(SelHotel);
	vProcedureParameters.Add(SelRoom);
	vProcedureParameters.Add(SelRoomType);
	vProcedureParameters.Add(SelCustomer);
	vProcedureParameters.Add(SelContract);
	vProcedureParameters.Add(SelAgent);
	vProcedureParameters.Add(SelAllotment);
	vProcedureParameters.Add(SelRoomRate);
	vProcedureParameters.Add(SelClient);
	vProcedureParameters.Add(SelGuestGroup);
	vProcedureParameters.Add(SelCheckInDate);
	vProcedureParameters.Add(SelCheckOutDate);
	vProcedureParameters.Add(SelBedsSetup);
	vProcedureParameters.Add(vTempStorageAdress);

	vBackgroundJob = AsyncCalls.StartBackgroundJob("ProlongedOperations.FrontOffice_GetTotalsRooms", vProcedureParameters, , "Get front-office totals", vTempStorageAdress);

	GetFOTotalsJobUUID = vBackgroundJob.UUID;
	GetFOTotalsJobAddress = vTempStorageAdress;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckInDateOnChangeAtServer(pClearTotals = True)
	If SelFilterStatus = 0 Then
		vPage = "DocumentListIsInHouse";
	ElsIf SelFilterStatus = 3 Then
		vPage = "DocumentListIsInHouse";
	ElsIf SelFilterStatus = 1 Then
		vPage = "DocumentListAll";
	Else 
		vPage = "DocumentListReservation";	
	EndIf;	
	If Not ValueIsFilled(SelCheckInDate) Then
		If SelFilterStatus = 2 Then
			vAccountingDate = BegOfDay(?(ValueIsFilled(SelHotel) And ValueIsFilled(SelHotel.AccountingDate), SelHotel.AccountingDate, CurrentSessionDate()));
			DocumentListReservation.Parameters.SetParameterValue("qDateTo", EndOfDay(vAccountingDate));
			tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(ThisObject[vPage], "BegOfCheckInDate", vAccountingDate, DataCompositionComparisonType.LessOrEqual, , True);
		Else															
			tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(ThisObject[vPage], "BegOfCheckInDate", , , , False);
		EndIf;
	Else
		If SelCheckInDate > '20991231' Or SelCheckInDate < '20091231' Then
			SelCheckInDate = CurrentSessionDate();
		EndIf;
		If SelFilterStatus = 2 Then
			DocumentListReservation.Parameters.SetParameterValue("qDateTo", EndOfDay(SelCheckInDate));
		EndIf;
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(ThisObject[vPage], "BegOfCheckInDate", BegOfDay(SelCheckInDate), DataCompositionComparisonType.Equal, , True);
	EndIf;
	If pClearTotals Then
		ClearTotalsAtServer();
		ClearTotalsByGroupAtServer();
	EndIf;
EndProcedure // CheckInDateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckOutDateOnChangeAtServer(pClearTotals = True)
	If SelFilterStatus = 0 Or SelFilterStatus = 3 Then
		vPage = "DocumentListIsInHouse";
	ElsIf SelFilterStatus = 1 Then
		vPage = "DocumentListAll";
	Else 
		vPage = "DocumentListReservation";	
	EndIf;
	If Not ValueIsFilled(SelCheckOutDate) Then
		If SelFilterStatus = 3 Then
			tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(ThisObject[vPage], "BegOfCheckOutDate", BegOfDay(?(ValueIsFilled(SelHotel) And ValueIsFilled(SelHotel.AccountingDate), SelHotel.AccountingDate, CurrentSessionDate())), DataCompositionComparisonType.LessOrEqual, , True);
		Else	
			tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(ThisObject[vPage], "BegOfCheckOutDate", , , , False);
		EndIf;
	Else	
		If SelCheckOutDate > '20991231' Or SelCheckOutDate < '20091231' Then
			SelCheckOutDate = CurrentSessionDate();
		EndIf;
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(ThisObject[vPage], "BegOfCheckOutDate", BegOfDay(SelCheckOutDate), DataCompositionComparisonType.Equal, , True);
	EndIf;
	If pClearTotals Then
		ClearTotalsAtServer();
		ClearTotalsByGroupAtServer();
	EndIf;
EndProcedure // CheckOutDateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FilterStatusOnChangeAtServer(pCheckOutDate = Undefined)
	If SelFilterStatus = 1 Then
		// Accommodations archive
		Items.GroupPages.CurrentPage = Items.GroupArchive;
		// Printing forms and actions
		Items.PrintingAndActionsAccommodation.Visible 			= True;
		Items.PrintingAndActionsReservation.Visible 			= False;
		Items.ShowExpectedRoomMovesOnly.Visible					= False;
		Items.ShowWaitingListOnly.Visible						= False;
		Items.DocumentListReservationSetReservationStatusDate.Visible = False;
		ShowExpectedRoomMovesOnly = False;
		ShowWaitingListOnly = False;
		// Settings
		Items.DocumentListInHouseSettings.Visible 				= False;
		Items.DocumentListInHouseOutputList.Visible		 		= False;
		Items.DynamicListAllListSettings.Visible 				= True;
		Items.DynamicListAllOutputList.Visible 					= True;
		Items.DynamicListReservationListSettings.Visible 		= False;
		Items.DynamicListReservationOutputList.Visible 			= False;
		// Search string source
		Items.GroupSearchStringInHouse.Visible 					= False;
		Items.GroupSearchStringAll.Visible 						= True;
		Items.GroupSearchStringReservation.Visible 				= False;
		// Commands
		If Items.Find("DocumentListCreate") <> Undefined Then
			Items.DocumentListCreate.Visible 					= True;
			Items.DocumentListCreate.DefaultButton 				= True;
		EndIf;
		If ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Customer) Then
			Items.CheckOut.Visible								= False;
		Else
			Items.CheckOut.Visible 								= True;
		EndIf;
		Items.NewReservation.Visible 							= False;
		Items.NewReservation.DefaultButton 						= False;
		Items.CopyAccommodation.Visible                         = True;
		Items.CheckIn.Visible									= False;
		Items.OpenForeignerRegistryRecord.Visible				= True;
		// Do not rebuild inactive lists
		DocumentListReservation.Parameters.SetParameterValue("qGenerateList", False);
		DocumentListIsInHouse.Parameters.SetParameterValue("qGenerateList", False);
		DocumentListALL.Parameters.SetParameterValue("qGenerateList", True);
		// Focus
		ThisObject.CurrentItem = Items.DocumentListAll;
	ElsIf SelFilterStatus = 2 Then
		// Expected arrivals
		Items.GroupPages.CurrentPage = Items.GroupReservation;
		// Printing forms and actions
		Items.PrintingAndActionsAccommodation.Visible 			= False;
		Items.PrintingAndActionsReservation.Visible 			= True;
		// Settings
		Items.DocumentListInHouseSettings.Visible 				= False;
		Items.DocumentListInHouseOutputList.Visible		 		= False;
		Items.DynamicListAllListSettings.Visible 				= False;
		Items.DynamicListAllOutputList.Visible 					= False;
		Items.DynamicListReservationListSettings.Visible 		= True;
		Items.DynamicListReservationOutputList.Visible 			= True;
		ShowExpectedRoomMovesOnly = False;
		Items.ShowExpectedRoomMovesOnly.Visible					= False;
		Items.ShowWaitingListOnly.Visible						= True;
		Items.DocumentListReservationSetReservationStatusDate.Visible = ShowWaitingListOnly;
		DocumentListReservation.Parameters.SetParameterValue("qShowWaitingListOnly", ShowWaitingListOnly);
		// Search string source
		Items.GroupSearchStringInHouse.Visible 					= False;
		Items.GroupSearchStringAll.Visible 						= False;
		Items.GroupSearchStringReservation.Visible 				= True;
		// Commands
		If ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Customer) Then
			Items.CheckIn.Visible								= False;
		Else
			Items.CheckIn.Visible								= True;
			Items.CheckIn.DefaultButton							= True;
		EndIf;
		If Items.Find("DocumentListCreate") <> Undefined Then
			Items.DocumentListCreate.Visible 					= False;
			Items.DocumentListCreate.DefaultButton 				= False;
		EndIf;
		Items.CheckOut.Visible 									= False;
		Items.NewReservation.Visible 							= True;
		Items.CopyAccommodation.Visible                         = True;
		Items.OpenForeignerRegistryRecord.Visible				= False;
		// Do not rebuild inactive lists
		DocumentListReservation.Parameters.SetParameterValue("qGenerateList", True);
		DocumentListIsInHouse.Parameters.SetParameterValue("qGenerateList", False);
		DocumentListALL.Parameters.SetParameterValue("qGenerateList", False);
		// Focus
		ThisObject.CurrentItem = Items.DocumentListReservation;
	Else 
		// 0 - In house guests or 3 - Expected Departure 
		Items.GroupPages.CurrentPage = Items.GroupInHouse;
		Items.CheckOut.Visible 									= True;
		If Items.Find("DocumentListCreate") <> Undefined Then
			Items.DocumentListCreate.Visible 					= True;
		EndIf;
		// Printing forms and actions
		Items.PrintingAndActionsAccommodation.Visible 			= True;
		Items.PrintingAndActionsReservation.Visible 			= False;
		// Settings
		Items.DocumentListInHouseSettings.Visible 				= True;
		Items.DocumentListInHouseOutputList.Visible		 		= True;
		Items.DynamicListAllListSettings.Visible 				= False;
		Items.DynamicListAllOutputList.Visible 					= False;
		Items.DynamicListReservationListSettings.Visible 		= False;
		Items.DynamicListReservationOutputList.Visible 			= False;
		If SelFilterStatus = 3 Then
			ShowExpectedRoomMovesOnly = False;
			Items.ShowExpectedRoomMovesOnly.Visible				= False;
		Else
			Items.ShowExpectedRoomMovesOnly.Visible				= True;
			DocumentListIsInHouse.Parameters.SetParameterValue("qShowExpectedRoomMovesOnly", ShowExpectedRoomMovesOnly);
		EndIf;
		// Do not rebuild inactive lists
		DocumentListReservation.Parameters.SetParameterValue("qGenerateList", False);
		DocumentListIsInHouse.Parameters.SetParameterValue("qGenerateList", True);
		DocumentListALL.Parameters.SetParameterValue("qGenerateList", False);

		ShowWaitingListOnly = False;
		Items.ShowWaitingListOnly.Visible						= False;
		Items.DocumentListReservationSetReservationStatusDate.Visible = False;
		// Search string source
		Items.GroupSearchStringInHouse.Visible 					= True;
		Items.GroupSearchStringAll.Visible 						= False;
		Items.GroupSearchStringReservation.Visible 				= False;
		// Commands
		If ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Customer) Then
			Items.CheckOut.Visible 								= False;
		Else
			Items.CheckOut.Visible 								= True;
		EndIf;
		Items.NewReservation.Visible 							= False;
		Items.CopyAccommodation.Visible                         = True;
		Items.CheckIn.Visible									= False;
		Items.OpenForeignerRegistryRecord.Visible				= True;
		If SelFilterStatus = 3 Then
			Items.CheckOut.Visible 								= True;
			Items.CheckOut.DefaultButton                        = True;
			If Items.Find("DocumentListCreate") <> Undefined Then
				Items.DocumentListCreate.Visible 				= False;
			EndIf;
			Items.CheckIn.Visible 								= False;
		Else	
			If Items.Find("DocumentListCreate") <> Undefined Then
				Items.DocumentListCreate.Visible 				= True;
				Items.DocumentListCreate.DefaultButton 			= True;
			EndIf;
		EndIf;
		// Focus
		ThisObject.CurrentItem = Items.DocumentListIsInHouse;
	EndIf;
	CheckInDateOnChangeAtServer(False);
	CheckOutDateOnChangeAtServer(False);
	If ValueIsFilled(SelRoom) Then
		If SelRoom.IsFolder Then
			AttributeChangeAtServer("Room", SelRoom, DataCompositionComparisonType.InHierarchy);
		Else
			AttributeChangeAtServer("Room", SelRoom);
		EndIf;
	Else
		ClearingAttributeAtServer("Room");
	EndIf;
	If ValueIsFilled(SelRoomType) Then
		If SelRoomType.IsFolder Then
			AttributeChangeAtServer("RoomType", SelRoomType, DataCompositionComparisonType.InHierarchy);
		Else
			AttributeChangeAtServer("RoomType", SelRoomType);
		EndIf;
	Else
		ClearingAttributeAtServer("RoomType");
	EndIf;
	If ValueIsFilled(SelCustomer) Then
		If SelCustomer.IsFolder Then
			AttributeChangeAtServer("Customer", SelCustomer, DataCompositionComparisonType.InHierarchy);
		Else
			AttributeChangeAtServer("Customer", SelCustomer);
		EndIf;
	Else
		ClearingAttributeAtServer("Customer");
	EndIf;
	If ValueIsFilled(SelContract) Then
		AttributeChangeAtServer("Contract", SelContract);
	Else
		ClearingAttributeAtServer("Contract");
	EndIf;
	If ValueIsFilled(SelAgent) Then
		If SelAgent.IsFolder Then
			AttributeChangeAtServer("Agent", SelAgent, DataCompositionComparisonType.InHierarchy);
		Else
			AttributeChangeAtServer("Agent", SelAgent);
		EndIf;
	Else
		ClearingAttributeAtServer("Agent");
	EndIf;
	If ValueIsFilled(SelAllotment) Then
		If SelAllotment.IsFolder Then
			AttributeChangeAtServer("RoomQuota", SelAllotment, DataCompositionComparisonType.InHierarchy);
		Else
			AttributeChangeAtServer("RoomQuota", SelAllotment);
		EndIf;
	Else
		ClearingAttributeAtServer("RoomQuota");
	EndIf;
	If ValueIsFilled(SelBedsSetup) Then
		AttributeChangeAtServer("BedsSetup", SelBedsSetup);
	Else
		ClearingAttributeAtServer("BedsSetup");
	EndIf;
	If ValueIsFilled(SelClient) Then
		AttributeChangeAtServer("Guest", SelClient);
	Else
		ClearingAttributeAtServer("Guest");
	EndIf;
	If ValueIsFilled(SelGuestGroup) Then
		AttributeChangeAtServer("GuestGroup", SelGuestGroup);
	Else
		ClearingAttributeAtServer("GuestGroup");
	EndIf;
	If pCheckOutDate <> Undefined Then
		SelCheckOutDate = pCheckOutDate;
		If ValueIsFilled(SelCheckOutDate) And (SelFilterStatus = 0  Or SelFilterStatus = 3) Then
			AttributeChangeAtServer("CheckOutDate", SelCheckOutDate, DataCompositionComparisonType.LessOrEqual);
		EndIf;
	EndIf;
EndProcedure // FilterStatusOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetMainDocRef(pRef)
	// Fill one room guests
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref AS Ref,
	|	Accommodation.Guest AS GuestRef
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.GuestGroup = &qGroup
	|	AND Accommodation.Number = &qNumber
	|	AND Accommodation.Posted
	|	AND NOT Accommodation.DeletionMark
	|	AND ((Accommodation.AccommodationStatus.IsActive
	|			OR Accommodation.AccommodationStatus.IsCheckIn)
	|		OR	(Accommodation.AccommodationStatus = &qAccStatus))
	|ORDER BY
	|	Accommodation.AccommodationType.SortCode";
	vQry.SetParameter("qGroup", pRef.GuestGroup);
	vQry.SetParameter("qRoom", pRef.Room);
	vQry.SetParameter("qAccStatus", pRef.AccommodationStatus);
	vQry.SetParameter("qRoomIsFilled", ValueIsFilled(pRef.Room));
	vQry.SetParameter("qNumber", pRef.Number);
	vQryResult = vQry.Execute().Unload();
	If vQryResult.Count() > 0 Then
		Return vQryResult.Get(0).Ref;
	EndIf;
	Return pRef;
EndFunction // GetMainDocRef

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure AddOneRoomAccommodations(pAccList, pDocRef, pInhouseOnly = False, pReversed = False)
	vOneRoomDocs = cmGetOneRoomAccommodations(pDocRef.Room, pDocRef.GuestGroup, pDocRef.CheckInDate, pDocRef.CheckOutDate);
	i = ?(pReversed, vOneRoomDocs.Count() - 1, 0);
	While True Do
		If i < 0 Or i >= vOneRoomDocs.Count() Then
			Break;
		EndIf;
		vOneRoomDocsRow = vOneRoomDocs.Get(i);
		vDocRef = vOneRoomDocsRow.Ref;
		If ValueIsFilled(vDocRef) And TypeOf(vDocRef) = Type("DocumentRef.Accommodation") Then
			If pInhouseOnly Then
				If ValueIsFilled(vDocRef.AccommodationStatus) And 
				   Not vDocRef.AccommodationStatus.IsInHouse Then
					i = i + ?(pReversed, -1, 1);
					Continue;
				EndIf;
			EndIf;
			If TypeOf(pAccList) = Type("ValueList") Then
				If pAccList.FindByValue(vDocRef) = Undefined Then
					If pReversed Then
						pAccList.Add(vDocRef);
					Else
						pAccList.Insert(i, vDocRef);
					EndIf;
				EndIf;
			ElsIf TypeOf(pAccList) = Type("Array") Then
				pAccList.Add(New Structure("Ref, GuestRef, AccommodationType", vDocRef, vDocRef.Guest, vDocRef.AccommodationType));
			EndIf;
		EndIf;
		i = i + ?(pReversed, -1, 1);
	EndDo;
EndProcedure // AddOneRoomAccommodations

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure AddOneRoomReservations(pDocsList, pDocRef, pGetInactive = False, pPosted = True)
	vOneRoomDocs = cmGetOneRoomReservations(pDocRef.Number, pDocRef.GuestGroup, pDocRef.CheckInDate, pDocRef.CheckOutDate, pGetInactive, pPosted);
	For Each vOneRoomDocsRow In vOneRoomDocs Do
		If pDocsList.FindByValue(vOneRoomDocsRow.Ref) = Undefined Then
			pDocsList.Add(vOneRoomDocsRow.Ref);
		EndIf;
	EndDo;
EndProcedure // AddOneRoomReservations

// -----------------------------------------------------------------------------
&AtClient
Function ExtractTime(pDateTime)
	vTime = Date(1, 1, 1, Hour(pDateTime), Minute(pDateTime), 0);
	Return vTime;
EndFunction // ExtractTime

// -----------------------------------------------------------------------------
&AtClient
Procedure GetCheckOutDate(pCheckInDate, pCheckOutDate)
	vCheckOutDateTime = CurrentDate();
	If vCheckOutDateTime < pCheckInDate Then
		vCheckOutDateTime = pCheckInDate;
	EndIf;
	vDate = BegOfDay(CurrentDate());
	vTime = ExtractTime(CurrentDate());
	If tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToUseReferenceHourAsDefaultCheckOutTime") Then
		vDate = BegOfDay(CurrentDate());
		If BegOfDay(pCheckOutDate) = BegOfDay(CurrentDate()) Then
			If CurrentDate() < pCheckOutDate Then
				vTime = ExtractTime(CurrentDate());
			Else
				vTime = ExtractTime(pCheckOutDate);
			EndIf;
		Else
			vTime = ExtractTime(pCheckOutDate);
		EndIf;
	EndIf;
	vDescription = NStr("en = 'Check-out time:'; de = 'Abreisezeit:'; ru = 'Время выселения:'");
	vIsProtected = False;
	vDateIsProtected = False;
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToEditCheckOutDateTime") Then
		vIsProtected = True;
	Else
		If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToSetCheckOutDateInThePast") Then
			vDateIsProtected = True;
		EndIf;
	EndIf;
	vParams = New Structure("FillingValues", New Structure("Date, Time, Description, IsProtected, DateIsProtected", vDate, vTime, vDescription, vIsProtected, vDateIsProtected));
	OpenForm("CommonForm.tcInputDateTime", vParams, ThisObject, , , , New NotifyDescription("GetCheckOutDateAfterUserInput", ThisObject, New Structure("CheckInDate, CheckOutDate", pCheckInDate, pCheckOutDate)), FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // GetCheckOutDate

// -----------------------------------------------------------------------------
&AtClient
Procedure GetCheckOutDateAfterUserInput(pCheckOutDateTime, pExtraParameters) Export
	CheckOutDateTime = '00010101';
	// Check check out date and time entered
	If Not ValueIsFilled(pCheckOutDateTime) Then
		ShowMessageBox(, NStr("ru='Процедура выселения отменена!';
		                      |de='Das Ausweisungsverfahren wurde abgebrochen'; 
						      |en='Check-out procedure is canceled!'"));
		Return;
	EndIf;
	If pCheckOutDateTime < pExtraParameters.CheckInDate Then
		ShowMessageBox(, NStr("ru='Ввели дату и время выселения, которые раньше чем дата и время заезда!';
		                      |de='Sie haben ein Abreisedatum und eine Abreisezeit eingegeben, die vor dem Anreisedatum und der Anreisezeit liegen!'; 
						      |en='You have entered check-out date and time that are earlier then check-in date and time!'"));
		Return;
	EndIf;
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToSetCheckOutDateInThePast") Then
		vAllowedCheckOutDelayTime = 1;
		If ValueIsFilled(tcOnServer.cmGetCurrentUserAttribute()) Then
			vPermissionGroup = tcOnServer.cmGetEmployeePermissionGroupAtServer(tcOnServer.cmGetCurrentUserAttribute());
			If ValueIsFilled(vPermissionGroup) Then
				If tcOnServer.cmGetAttributeByRef(vPermissionGroup, "AllowedCheckOutDelayTime") > 0 Then
					vAllowedCheckOutDelayTime = tcOnServer.cmGetAttributeByRef(vPermissionGroup, "AllowedCheckOutDelayTime");
				EndIf;
			EndIf;
		EndIf;
		vTimeDiff = Round((CurrentDate() - pCheckOutDateTime)/3600, 3);
		If vTimeDiff > vAllowedCheckOutDelayTime Then
			ShowMessageBox(, NStr("ru='Ввели дату выселения в прошлом. Есть права на выселение только текущей или будущей датой!';
			                      |de='Sie haben ein Räumungsdatum angegeben, das in der Vergangenheit liegt. Sie sind berechtigt, eine Räumung nur am aktuellen oder künftigen Datum vorzunehmen!'; 
			                      |en='You have entered check-out date in the past. You have rights to do check-out by current or future dates only!'"));
			Return;
		EndIf;
	EndIf;
	CheckOutDateTime = pCheckOutDateTime;
EndProcedure // GetCheckOutDateAfterUserInput

// -----------------------------------------------------------------------------
// Check if there are future reservations in chain
// -----------------------------------------------------------------------------
&AtServer
Function CheckFutureReservationsAtServer(pCurDoc, pCheckOutDate)
	vMessage = "";
	If ValueIsFilled(pCurDoc.AccommodationType) And 
	  (pCurDoc.AccommodationType.Type = Enums.AccomodationTypes.Room Or pCurDoc.AccommodationType.Type = Enums.AccomodationTypes.Beds) Then
		vParentReservation = pCurDoc.GetObject().pmGetParentReservation();
		If ValueIsFilled(vParentReservation) Then
			vParentReservationObj = vParentReservation.GetObject();
			vNextReservationInChain = vParentReservationObj.pmGetNextReservationInChain();
			While ValueIsFilled(vNextReservationInChain) Do
				If ValueIsFilled(vNextReservationInChain.ReservationStatus) And vNextReservationInChain.ReservationStatus.IsActive Then
					If BegOfDay(vNextReservationInChain.CheckInDate) >= BegOfDay(pCheckOutDate) Then
						vMessage = NStr("en='Guest &Guest has active reservation period from &CheckInDate to &CheckOutDate!';
						                |ru='У гостя &Guest есть действующая бронь на период с &CheckInDate по &CheckOutDate!';
								        |de='Gast &Guest hat aktive Reservierungszeit von & CheckInDate zu &CheckOutDate!'");
						vMessage = StrReplace(vMessage, "&Guest", TrimAll(vNextReservationInChain.GuestFullName));
						vMessage = StrReplace(vMessage, "&CheckInDate", Format(vNextReservationInChain.CheckInDate, "DF=dd.MM.yyyy"));
						vMessage = StrReplace(vMessage, "&CheckOutDate", Format(vNextReservationInChain.CheckOutDate, "DF=dd.MM.yyyy"));
						Break;
					EndIf;
				Else
					Break;
				EndIf;
				vNextReservationInChain = vNextReservationInChain.GetObject().pmGetNextReservationInChain();
			EndDo;
		EndIf;
	EndIf;
	Return vMessage;
EndFunction // CheckFutureReservationsAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckIfCheckOutDateTimeIsFilled()
	If ValueIsFilled(CheckOutDateTime) And ValueIsFilled(MainRoomDoc) Then
		DetachIdleHandler("CheckIfCheckOutDateTimeIsFilled");
		
		// Get current documents list name
		vPage = "";
		If SelFilterStatus = 0 Or SelFilterStatus = 3 Then
			vPage = "DocumentListIsInHouse";
		ElsIf SelFilterStatus = 1 Then
			vPage = "DocumentListAll";
		Else
			Return;
		EndIf;
		
		// Add other selected documents
		AccList.Clear();
		For Each vSelDocRef In Items[vPage].SelectedRows Do
			// Check future reservations
			vMessage = CheckFutureReservationsAtServer(vSelDocRef, CheckOutDateTime);
			If Not IsBlankString(vMessage) Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
			EndIf;
			
			// Add document to the list of documents to be checked out
			If SelShowAllGuests = 0 Then
				AddOneRoomAccommodations(AccList, vSelDocRef, True, True);
			Else
				AccList.Add(vSelDocRef);
			EndIf;
		EndDo;
		
		// Do check-out in a background job
		vOperationName = NStr("en='Checking-out guests'; ru='Выселение гостей'; de='Gästen abreise'");
		
		ListOfMessages.Clear();
		
		vParameters = New Array;
		vParameters.Add(SelHotel);
		vParameters.Add(AccList);
		vParameters.Add(CheckOutDateTime);
		vParameters.Add(False);
		vParameters.Add(tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToCheckOutOnExpectedCheckOutTime"));
		vParameters.Add(tcOnServer.cmGetCurrentUserAttribute());
		
		vBackgroundJob = AsyncCalls.StartBackgroundJobWithRecordInRegister(SelHotel, vOperationName, "ProlongedOperations.AccommodationsList_CheckOut", vParameters);
		CurrentBackgroundJobUUID = vBackgroundJob.UUID;
		
		AttachIdleHandler("Attachable_CheckBackgroundJobs", 1, False);
	
		CheckInOut_ShowProgressBar(vOperationName);
	Else
		Return;
	EndIf;
EndProcedure // CheckIfCheckOutDateTimeIsFilled

// -----------------------------------------------------------------------------
&AtClient
Procedure Attachable_CheckBackgroundJobs()
	vBackgroundJob = CheckBackgroundJobStatus(CurrentBackgroundJobUUID);
	BackgroundOperationProgress = vBackgroundJob.Progress; 
	
	For Each vMsg in vBackgroundJob.Messages Do
		If ListOfMessages.FindByValue(vMsg) = Undefined Then
			ListOfMessages.Add(vMsg);
			tcCommonFunctionOnClientServer.TextMessage(vMsg);
		EndIf;
	EndDo;
	
	If vBackgroundJob.Status = "Error" Then 
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Error in background job: '; ru = 'Ошибка выполнения фонового задания: '; de = 'Fehler beim Ausführen des Hintergrundjobs: '") + vBackgroundJob.Error);
		DetachIdleHandler("Attachable_CheckBackgroundJobs");
		CheckInOut_HideProgressBar();
	ElsIf vBackgroundJob.Status = "Canceled" Then 
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Background job - canceled'; ru = 'Фоновое задание - отменено'; de = 'Hintergrundjob - abgebrochen'"));
		DetachIdleHandler("Attachable_CheckBackgroundJobs");
		CheckInOut_HideProgressBar();
	ElsIf vBackgroundJob.Status = "Completed" Then
		DetachIdleHandler("Attachable_CheckBackgroundJobs");
		CheckInOut_Completed();
	EndIf;
EndProcedure // Attachable_CheckBackgroundJobs

// -----------------------------------------------------------------------------
&AtServer
Function CheckBackgroundJobStatus(pBackgroundJobId)
	Return AsyncCalls.CheckBackgroundJob(pBackgroundJobId); 
EndFunction // CheckBackgroundJobStatus

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckInOut_ShowProgressBar(pOperationName)
	BackgroundOperationProgress = 0;
	Items.BackgroundOperationProgress.Title	= NStr("en = 'Background operation in progress, you can continue to work in other forms  - '; ru = 'Выполняется фоновая операция, можете продолжать работать в других формах  - '; de = 'Die Hintergrundoperation läuft, Sie können weiterhin in anderen Formen arbeiten - '") + pOperationName;
	Items.BackgroundOperationProgress.Visible = True;
	Items.CheckOut.Enabled = False;
	Items.DocumentListIsInHouseCheckOut.Enabled = False;
	Items.DocumentListAllCheckOut.Enabled = False;
EndProcedure // CheckInOut_ShowProgressBar

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckInOut_HideProgressBar()
	BackgroundOperationProgress = 0;
	Items.BackgroundOperationProgress.Visible = False;
	Items.CheckOut.Enabled = True;
	Items.DocumentListIsInHouseCheckOut.Enabled = True;
	Items.DocumentListAllCheckOut.Enabled = True;
EndProcedure // CheckInOut_HideProgressBar

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckInOut_Completed()
	CheckInOut_HideProgressBar();
	// Send notification to all open forms
	Notify("Subsystem.Accounts.Changed", MainRoomDoc, ThisObject);
	Notify("Document.ResourceReservation.Write", , ThisObject);
	// Notify that accommodation is changed
	Notify("Document.Accommodation.Write", MainRoomDoc, ThisObject);
	// Refresh lists
	vPage = "";
	If SelFilterStatus = 0 Or SelFilterStatus = 3 Then
		vPage = "DocumentListIsInHouse";
	ElsIf SelFilterStatus = 1 Then
		vPage = "DocumentListAll";
	Else
		Return;
	EndIf;
	Items[vPage].Refresh();
	// Print folios for each checked out accommodation
	If AccList.Count() > 0 And tcOnServer.cmGetAttributeByRef(SelHotel, "PrintCustomerFolioAfterCheckout") Then
		PrintCustomerFolios();
	EndIf;
EndProcedure // CheckInOut_Completed

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintCustomerFolios()
	vLang = tcOnServer.cmGetSessionParametersAttribute("CurrentLanguage");
	If ValueIsFilled(vLang) Then
		vLangCode = tcOnServer.cmGetAttributeByRef(vLang, "Code");
		vPrintFormName = "AfterCheckoutFolioPrintForm" + Title(TrimAll(vLangCode));
		vPrintFormTypeRef = tcOnServer.cmGetAttributeByRef(SelHotel, vPrintFormName);
		If ValueIsFilled(vPrintFormTypeRef) Then
			vCurNumber = "";
			vCurGuestGroup = Undefined;
			For Each vAccListItem In AccList Do
				vCurAccRef = vAccListItem.Value;
				vStatusIsInHouse = CheckIfCheckOutSuccessfull(vCurAccRef);
				If Not vStatusIsInHouse Then
					vNumber = tcOnServer.cmGetAttributeByRef(vCurAccRef, "Number");
					vGuestGroup = tcOnServer.cmGetAttributeByRef(vCurAccRef, "GuestGroup");
					If vNumber <> vCurNumber Or vGuestGroup <> vCurGuestGroup Then
						vCurNumber = vNumber;
						vCurGuestGroup = vGuestGroup;
						// Get list of customer folios for this room
						vFoliosList = GetListOfCustomerFolios(vNumber, vGuestGroup);
						If vFoliosList.Count() > 0 Then
							vParams = New Structure("InputParameter, ObjectPrintingForm, Folios", vFoliosList.Get(0).Value, vPrintFormTypeRef, vFoliosList);
							OpenForm("Document.Folio.Form.tcFolioPrintForm", vParams, ThisObject, New UUID);
						EndIf;
					EndIf;
				EndIf;
			EndDo;
		Else
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Print form is not specified for language '; ru='Не указана печатная форма для языка '; de='Druckformular ist nicht für die Sprache angegeben '") + Upper(vLangCode) + "!");
		EndIf;
	EndIf;
EndProcedure // PrintCustomerFolios

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetListOfCustomerFolios(pNumber, pGuestGroup)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Folio.Ref AS Ref
	|FROM
	|	Document.Folio AS Folio
	|WHERE
	|	Folio.GuestGroup = &qGuestGroup
	|	AND Folio.ParentDoc.Number = &qNumber
	|	AND NOT Folio.DeletionMark
	|	AND NOT ISNULL(Folio.Customer.IsIndividual, TRUE)
	|
	|ORDER BY
	|	Folio.PointInTime";
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	vQry.SetParameter("qNumber", TrimR(pNumber));
	vFolios = vQry.Execute().Unload();
	vFoliosList = New ValueList();
	vFoliosList.LoadValues(vFolios.UnloadColumn("Ref"));
	Return vFoliosList;
EndFunction // GetListOfCustomerFolios

// -----------------------------------------------------------------------------
&AtServer
Function CheckIfCheckOutSuccessfull(pAccRef)
	vAccObj = pAccRef.GetObject();
	vAccObj.Read();
	Return vAccObj.AccommodationStatus.IsInHouse;
EndFunction // CheckIfCheckOutSuccessfull

// -----------------------------------------------------------------------------
&AtClient
Procedure ExtendInHouseGuestsPeriodOfStay() 
	vStructureMessage = tcOnClient.ExtendInHouseGuestsPeriodOfStay(SelHotel);
	If Not IsBlankString(vStructureMessage.Message) Then
		tcCommonFunctionOnClientServer.TextMessage(vStructureMessage.Message);
	EndIf;
	Notify("Subsystem.Accounts.Changed");
EndProcedure // ExtendInHouseGuestsPeriodOfStay

// -----------------------------------------------------------------------------
&AtServer
Procedure SetParametersDynamicList()
	vBalancesAreVisible = Not cmCheckUserPermissions("DoNotShowBalancesInLists");

	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
	
	// Set columns appearance
	Items.DocumentListAllSumBalance.Visible = vBalancesAreVisible;
	Items.DocumentListAllSumBalanceCustomer.Visible = vBalancesAreVisible;
	Items.DocumentListIsInHouseSumBalance.Visible = vBalancesAreVisible;
	Items.DocumentListIsInHouseSumBalanceCustomer.Visible = vBalancesAreVisible;
	Items.DocumentListReservationClientSumBalance.Visible = vBalancesAreVisible;
	Items.DocumentListReservationCustomerSumBalance.Visible = vBalancesAreVisible;
	
	// Set parameters
	DocumentListALL.Parameters.SetParameterValue("qHotel",SelHotel);
	DocumentListALL.Parameters.SetParameterValue("qShowAllGuests", SelShowAllGuests);
	DocumentListALL.Parameters.SetParameterValue("qBalancesAreVisible", vBalancesAreVisible);
	
	DocumentListIsInHouse.Parameters.SetParameterValue("qHotel",SelHotel);
	DocumentListIsInHouse.Parameters.SetParameterValue("qShowAllGuests", SelShowAllGuests);
	DocumentListIsInHouse.Parameters.SetParameterValue("qBalancesAreVisible", vBalancesAreVisible);
	DocumentListIsInHouse.Parameters.SetParameterValue("qAccountingDate", BegOfDay(CurrentSessionDate()));
	DocumentListIsInHouse.Parameters.SetParameterValue("qShowExpectedRoomMovesOnly", ShowExpectedRoomMovesOnly);
	
	DocumentListReservation.Parameters.SetParameterValue("qHotel",SelHotel);
	DocumentListReservation.Parameters.SetParameterValue("qShowAllGuests", SelShowAllGuests);
	DocumentListReservation.Parameters.SetParameterValue("qBalancesAreVisible", vBalancesAreVisible);
	DocumentListReservation.Parameters.SetParameterValue("qShowWaitingListOnly", ShowWaitingListOnly);
	                                                                                                                         
	Title = NStr("en='Front office console: '; ru='Фронт-офис: '; de='Front-Office-Konsole: '") + ?(ValueIsFilled(SelHotel), Catalogs.Hotels.pmGetHotelPrintName(SelHotel, SessionParameters.CurrentLanguage), "");
EndProcedure //  SetParametersDynamicList()

// -----------------------------------------------------------------------------
&AtClient
Procedure RefreshListAndTotals() Export
	If IsInputAvailable() Then
		SetParametersDynamicList();
		ClearTotalsByGroupAtClient();
		ClearTotalsAtClient();
	Else
		AttachIdleHandler("RefreshListAndTotals", 1, True);
	EndIf;
EndProcedure // RefreshListAndTotals

// -----------------------------------------------------------------------------
&AtClient
Procedure RefreshList() Export
	If IsInputAvailable() Then
		SetParametersDynamicList();
	Else
		AttachIdleHandler("RefreshList", 1, True);
	EndIf;
EndProcedure // RefreshListAndTotals

// -----------------------------------------------------------------------------
&AtServer
Procedure SetFilterCollapsedTitle()
	vAddColon = True;
	vAddSemiColon = False;
	vGroupSearchModeTitle = Items.GroupSearchMode.Title;
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
	If ValueIsFilled(SelAllotment) Then
		vGroupSearchModeTitle = vGroupSearchModeTitle + ?(vAddColon, ": ", "") + ?(vAddSemiColon, "; ", "") + Items.SelAllotment.Title + ": " + TrimAll(SelAllotment);
		vAddSemiColon = True;
		vAddColon = False;
	EndIf;
	If ValueIsFilled(SelBedsSetup) Then
		vGroupSearchModeTitle = vGroupSearchModeTitle + ?(vAddColon, ": ", "") + ?(vAddSemiColon, "; ", "") + Items.SelBedsSetup.Title + ": " + TrimAll(SelBedsSetup);
		vAddSemiColon = True;
		vAddColon = False;
	EndIf;
	If ValueIsFilled(SelClient) Then
		vGroupSearchModeTitle = vGroupSearchModeTitle + ?(vAddColon, ": ", "") + ?(vAddSemiColon, "; ", "") + Items.SelClient.Title + ": " + TrimAll(SelClient.FullName);
		vAddSemiColon = True;
		vAddColon = False;
	EndIf;
	Items.GroupSearchMode.CollapsedRepresentationTitle = vGroupSearchModeTitle;
EndProcedure // SetFilterCollapsedTitle

// -----------------------------------------------------------------------------
// Procedure - Attribute change at server
//
// Parameters:
//  pAttribute	 - as string name DataCompositionField 
//  pValue		 - ref item 
//  pComparisonType - Data Composition Comparison Type 
// -----------------------------------------------------------------------------
&AtServer
Procedure AttributeChangeAtServer(pAttribute, pValue, pComparisonType = Undefined)
	If ValueIsFilled(pValue) Then
		If SelFilterStatus = 0 Or SelFilterStatus = 3 Then
			vPage = "DocumentListIsInHouse";
			vComparisonType = ?(pComparisonType = Undefined, DataCompositionComparisonType.Equal, pComparisonType);
		ElsIf SelFilterStatus = 1 Then
			vPage = "DocumentListAll";
			vComparisonType = ?(pComparisonType = Undefined, DataCompositionComparisonType.Equal, pComparisonType);
		Else 
			vPage = "DocumentListReservation";	
			vComparisonType = ?(pComparisonType = Undefined, DataCompositionComparisonType.Equal, pComparisonType);
		EndIf;	
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(ThisObject[vPage], pAttribute, pValue, vComparisonType, , True);
	EndIf;
	SetFilterCollapsedTitle();
EndProcedure // AttributeChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ClearingAttributeAtServer(pAttribute)
	If SelFilterStatus = 0 Or SelFilterStatus = 3 Then
		vPage = "DocumentListIsInHouse";
	ElsIf SelFilterStatus = 1 Then
		vPage = "DocumentListAll";
	Else 
		vPage = "DocumentListReservation";	
	EndIf;	
	tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(ThisObject[vPage], pAttribute, , , , False);
	SetFilterCollapsedTitle();
EndProcedure // ClearingAttributeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetDocumentsListToCheckIn()
	vDocsList = New ValueList();
	For Each vSelDocRef In Items.DocumentListReservation.SelectedRows Do
		If TypeOf(vSelDocRef) = Type("DocumentRef.Reservation") Then
			If vSelDocRef.Posted And (vSelDocRef.ReservationStatus.IsActive Or vSelDocRef.ReservationStatus.IsPreliminary) Then
				If ValueIsFilled(vSelDocRef.Room) And BegOfDay(vSelDocRef.CheckInDate) <= BegOfDay(CurrentSessionDate()) Then
					If SelShowAllGuests = 0 Then
						vOneRoomReservations = cmGetOneRoomReservations(vSelDocRef.Number, vSelDocRef.GuestGroup, vSelDocRef.CheckInDate, vSelDocRef.CheckOutDate, False);
						For Each vOneRoomReservationsRow In vOneRoomReservations Do
							If vDocsList.FindByValue(vOneRoomReservationsRow.Ref) = Undefined Then
								vDocsList.Add(vOneRoomReservationsRow.Ref);
							EndIf;
						EndDo;
					Else
						vDocsList.Add(vSelDocRef);
					EndIf;
				EndIf;
			EndIf;
		Endif;
	EndDo;
	Return vDocsList;
EndFunction // GetDocumentsListToCheckIn

// -----------------------------------------------------------------------------
&AtClient
Procedure PackageCheckIn()
	vDocsList = GetDocumentsListToCheckIn();
	If vDocsList.Count() > 0 Then
		// Do check-in in a background job
		vOperationName = NStr("en='Checking-in selected guests'; ru='Заселение выделенных гостей'; de='Gästen anreise'");
		
		ListOfMessages.Clear();
		
		vParameters = New Array;
		vParameters.Add(SelHotel);
		vParameters.Add(vDocsList);
		vParameters.Add(CurrentDate());
		vParameters.Add(False);
		vParameters.Add(tcOnServer.cmGetCurrentUserAttribute());
		
		vBackgroundJob = AsyncCalls.StartBackgroundJobWithRecordInRegister(SelHotel, vOperationName, "ProlongedOperations.AccommodationsList_CheckIn", vParameters);
		CurrentBackgroundJobUUID = vBackgroundJob.UUID;
		
		AttachIdleHandler("Attachable_CheckBackgroundJobs", 1, False);
	
		CheckInOut_ShowProgressBar(vOperationName);
	EndIf;
EndProcedure // PackageCheckIn

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckInByDoc(pReservation)
	vMessageText = "";
	vAccForm = Undefined;
	vSelResRow = pReservation;     
	vApdexRemarks = GetRemarksForAPDEX(vSelResRow);
	vMainRoomRef = GetMainDocRefReservation(vSelResRow);
	vThereAreDifferentCheckInDates = False;
	If vSelResRow <> Undefined Then
		vResult = CheckInAtServer(vMainRoomRef, false);
		If ValueIsFilled(vResult) Then
			If vResult = "DoQueryBox" Then
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='You are checking-in by inactive or by already checked-in reservation!';ru='Селите по не активной или уже заселенной брони!';de='Sie bringen nicht nach einer aktiven Reservierung unter!'"), MessageStatus.Important);
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
					vSkip = False;
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
								                    |ru='В выбранном списке брони есть документы с датой заезда " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " отличающейся от текущей даты " + Format(vHotelAccountingDate, "DF=dd.MM.yyyy") + "!'");
								vQuestionWasAsked = True;
							EndIf;
						EndIf;
						vSelResList.Add(vItem.Value);
					EndDo; 
					// Check current reservation list deposits
					CheckReservationsDeposits(vSelResList);
					vResult = CheckInAtServer(vMainRoomRef, true, vSelResList);
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
				vSkip = False;
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
							                    |ru='В выбранном списке брони есть документы с датой заезда " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " отличающейся от текущей даты " + Format(vHotelAccountingDate, "DF=dd.MM.yyyy") + "!'");
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
EndProcedure // CheckInByDoc 

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
EndFunction // CheckInAction

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
&AtServerNoContext
Function GetMainDocRefReservation(pRef)
	// Fill one room guests
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	Reservations.Ref AS Ref,
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
	If vQryResult.Count() > 0 Then
		Return vQryResult.Get(0).Ref;
	EndIf;
	Return pRef;
EndFunction // GetMainDocRefReservation

// -----------------------------------------------------------------------------
&AtServer
Function GetClientIdentificationCardById(pIdentifier, pUseDeleted = False) 
    Return cmGetClientIdentificationCardById(pIdentifier, pUseDeleted);
EndFunction // cmGetClientIdentificationCardById

// -----------------------------------------------------------------------------
&AtServer
Function GetDiscountCardById(pIdentifier, pSearchMarkedForDeletion = False) 
	Return cmGetDiscountCardById(pIdentifier);
EndFunction // cmGetDiscountCardById

// -----------------------------------------------------------------------------
&AtServer
Function GetRoom(pCard) 
	Return pCard.Room;
EndFunction // cmGetDiscountCardById

// -----------------------------------------------------------------------------
&AtServer
Function GetClient(pCard) 
	Return pCard.Client;
EndFunction // cmGetDiscountCardById

// -----------------------------------------------------------------------------
&AtServer
Procedure RefreshAtServer()
	SetParametersDynamicList();
	If SelFilterStatus = 0 Or SelFilterStatus = 3 Then
		vPage = "DocumentListIsInHouse";
	ElsIf SelFilterStatus = 1 Then
		vPage = "DocumentListAll";
	Else 
		vPage = "DocumentListReservation";	
	EndIf;	
	Items[vPage].Refresh();
	ClearTotalsAtServer();
	ClearTotalsByGroupAtServer();
EndProcedure // RefreshAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetPaymentFolio(pAcc)
	If NOT ValueIsFilled(pAcc) Then
		Return Undefined;
	EndIf;
	vQ = New Query("SELECT
	               |	AccommodationChargingRules.ChargingFolio AS Folio,
	               |	AccommodationChargingRules.LineNumber AS LineNumber
	               |FROM
	               |	Document.Accommodation.ChargingRules AS AccommodationChargingRules
	               |WHERE
	               |	AccommodationChargingRules.Ref = &qAcc
	               |
	               |UNION ALL
	               |
	               |SELECT
	               |	GuestGroupsChargingRules.ChargingFolio,
	               |	GuestGroupsChargingRules.LineNumber
	               |FROM
	               |	Catalog.GuestGroups.ChargingRules AS GuestGroupsChargingRules
	               |WHERE
	               |	GuestGroupsChargingRules.Ref = &qGuestGroup
	               |
	               |ORDER BY
	               |	LineNumber");
	vQ.SetParameter("qAcc",pAcc);
	vQ.SetParameter("qGuestGroup",pAcc.GuestGroup);
	qResRows = vQ.Execute().Unload();
	vFolio = Undefined;
	For Each qRes In qResRows Do
		vFolio = qRes.Folio;
		F = vFolio.GetObject();
		vBalance = F.pmGetBalance();
		If vBalance > 0 Then
			Break;
		EndIf;
	EndDo;
	If vBalance > 0 Then
		Return vFolio;
	EndIf;
	For Each qRes In qResRows Do
		vFolio = qRes.Folio;
		Return vFolio;
	EndDo;
	Return Undefined;
EndFunction // GetPaymentFolio

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetForeignerRegistryRecordsList(pAccRef, rMessage)
	rMessage = "";
	vRecordsList = New ValueList();
	vRecords = pAccRef.GetObject().pmGetForeignerRegistryRecords();
	If vRecords = Undefined Then
		rMessage = NStr("ru='Гость " + String(pAccRef.Guest) + " не иностранец!'; 
		                |de='Gast " + String(pAccRef.Guest) + " sind nicht fremd ist!'; 
		                |en='" + String(pAccRef.Guest) + " guest is not a foreigner!'");
	ElsIf vRecords.Count() > 0 Then
		vRecordsList.LoadValues(vRecords.UnloadColumn("ForeignerRegistryRecord"));
	EndIf;
	Return vRecordsList;
EndFunction // GetForeignerRegistryRecordsList

// -----------------------------------------------------------------------------
&AtClient
Function GetCurrentRowRef()
	vRef = Undefined;
	If SelFilterStatus = 0 Or SelFilterStatus = 3 Then
		vPage = "DocumentListIsInHouse";
	ElsIf SelFilterStatus = 1 Then
		vPage = "DocumentListAll";
	Else 
		vPage = "DocumentListReservation";	
	EndIf;	
	vSelList = Items[vPage].SelectedRows;
	If vSelList.Count() > 0 Then
		vRef = vSelList[0];
	EndIf;	
	
	Return vRef
EndFunction //  GetCurrentRowRef()

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

// ------------------------------------------------------------------------------------------------
&AtServerNoContext
Function GetClientDataScanDocument(pDocRef)
	vDoc = Undefined;
	// Run query to check whether client data scans were already created
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	ClientDataScans.Ref AS Ref
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
		|	ClientDataScans.Ref AS Ref
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
Procedure OpenForeignerRegistryRecordForm(pAccRef)
	If Not ValueIsFilled(pAccRef) Then
		Return;
	EndIf;
	// Check if current guest record exists. If yes then open it
	vMessage = "";
	vRecords = GetForeignerRegistryRecordsList(pAccRef, vMessage);
	If Not IsBlankString(vMessage) Then
		tcCommonFunctionOnClientServer.TextMessage(vMessage);
	EndIf;
	// Get last one from the list
	vDocRef = Undefined;
	If vRecords <> Undefined And vRecords.Count() > 0 Then
		vDocRef = vRecords.Get(vRecords.Count()-1).Value;
	EndIf;
	vFrm = Undefined;
	If ValueIsFilled(vDocRef) Then
		vFrm = OpenForm("Document.ForeignerRegistryRecord.ObjectForm", New Structure("Key", vDocRef), ThisObject, vDocRef);
	Else
		vFrm = OpenForm("Document.ForeignerRegistryRecord.ObjectForm", New Structure("Основание", pAccRef), ThisObject, pAccRef);
	EndIf;
EndProcedure // OpenForeignerRegistryRecordForm

// -----------------------------------------------------------------------------
&AtServer
Function GetUnpostedGroupInvoices(pGuestGroup)
	vDocs = pGuestGroup.GetObject().pmGetUnpostedSettlements();
	vUnpostedInvoicesList = New ValueList();
	vUnpostedInvoicesList.LoadValues(vDocs.UnloadColumn("Invoice"));
	For Each vUnpostedInvoicesListItem In vUnpostedInvoicesList Do
		vInv = vUnpostedInvoicesListItem.Value;
		vUnpostedInvoicesListItem.Presentation = TrimAll(vInv) + " - " + cmFormatSum(vInv.SumDue, vInv.AccountingCurrency);
	EndDo;
	Return vUnpostedInvoicesList;
EndFunction // GetUnpostedGroupInvoices

// -----------------------------------------------------------------------------
&AtServer
Function GuestGroupFillSettlement(pGuestGroup, rMessage = "", rInvoice = Undefined)
	vResult = -1;
	rMessage = "";
	If ValueIsFilled(pGuestGroup) Then
		If rInvoice = Undefined Then
			WriteLogEvent(NStr("en='Document.Create';ru='Документ.СозданиеНового';de='Document.Create'"), EventLogLevel.Information, Metadata.Documents.Settlement, Documents.Settlement.EmptyRef(), NStr("en='Create new';ru='Создание нового';de='Erstellung eines neuen'"));
			vDoc = Documents.Settlement.CreateDocument();
		Else
			vDoc = rInvoice.GetObject();
		EndIf;
		If ValueIsFilled(pGuestGroup.ClientDoc) Then
			vDoc.Fill(pGuestGroup.ClientDoc);
		EndIf;
		vDoc.Fill(pGuestGroup);
		If vDoc.Services.Count() > 0 Then
			vDoc.Write(DocumentWriteMode.Posting);
			rInvoice = vDoc.Ref;
			vResult = 1;
		Else
			rMessage = NStr("en='Nothing to fill invoice for!';ru='Нет начислений для акта!';de='Nichts, um die Rechnung zu füllen!'");
			vResult = 0;
		EndIf;
	Else
		rMessage = NStr("en='No group is selected!';ru='Не выбрана группа!';de='Kein Gruppe ist gewählt!'");
	EndIf;
	Return vResult;
EndFunction // GuestGroupFillSettlement

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintInvoice(pInvoice)
	vLang = Undefined;
	vCustomer = tcOnServer.cmGetAttributeByRef(pInvoice, "AccountingCustomer");
	If ValueIsFilled(vCustomer) Then
		vLang = tcOnServer.cmGetAttributeByRef(vCustomer, "Language");
	EndIf;
	OpenForm("Document.Settlement.Form.tcInvoicePrintForm", New Structure("Invoice, Language", pInvoice, vLang), ThisObject, pInvoice);
EndProcedure // PrintInvoice

// -----------------------------------------------------------------------------
&AtServer
Function GetListOfGroupInvoices(pGuestGroup)
	vSettlements = pGuestGroup.GetObject().pmGetSettlements();
	vList = New ValueList();
	vList.LoadValues(vSettlements.UnloadColumn("Invoice"));
	For Each vListItem In vList Do
		vInv = vListItem.Value;
		vListItem.Presentation = TrimAll(vInv) + " - " + cmFormatSum(vInv.SumDue, vInv.AccountingCurrency);
	EndDo;
	Return vList;
EndFunction // GetListOfGroupInvoices

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure DocumentListIsInHouseOnGetDataAtServer(pItemName, pSettings, pRows)
	// Balances
	vSelShowAllGuests = pSettings.DataParameters.FindParameterValue(New DataCompositionParameter("qShowAllGuests"));
	vSelShowAllGuests = ?(vSelShowAllGuests = Undefined, 0, vSelShowAllGuests.Value);
	vBalancesAreVisible = pSettings.DataParameters.FindParameterValue(New DataCompositionParameter("qBalancesAreVisible"));
	vBalancesAreVisible = ?(vBalancesAreVisible = Undefined, False, vBalancesAreVisible.Value);
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
		vDocumentsToShow.Columns.Add("Ref", cmGetDocumentTypeDescription("Accommodation"));
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
			vFRowStruct = SystemSettingsStorage.Load("Document.Accommodation.Form.tcAccommodationListForm", "FirstDocInInHouseBatch");
			If vFRowStruct <> Undefined Then
				vFRow = vDocumentsToShow.Find(vFRowStruct.Ref, "Ref");
				If vFRow = Undefined Then
					vFRow = vDocumentsToShow.Add();
					vFRowWasAdded = True;
				EndIf;
				FillPropertyValues(vFRow, vFRowStruct);
			EndIf;

			vLRowStruct = SystemSettingsStorage.Load("Document.Accommodation.Form.tcAccommodationListForm", "LastDocInInHouseBatch");
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
			SystemSettingsStorage.Save("Document.Accommodation.Form.tcAccommodationListForm", "FirstDocInInHouseBatch", vFRowStruct);

			vLRow = vDocumentsToShow.Get(vDocumentsToShow.Count() - 1);
			vLRowStruct = New Structure(vListColumns);
			FillPropertyValues(vLRowStruct, vLRow);
			SystemSettingsStorage.Save("Document.Accommodation.Form.tcAccommodationListForm", "LastDocInInHouseBatch", vLRowStruct);
		EndIf;
	EndIf;
	
	// Colors and other appearances
	For Each vRow In pRows Do
		vRowValue = vRow.Value;
		vDocRef = vRowValue.Data.Ref;
		
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
			If vSelShowAllGuests = 0 Then
				vDocNumber = vRowValue.Data.RefNumber;
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
				ElsIf TypeOf(vDocRef) = Type("DocumentRef.Accommodation") And ValueIsFilled(vDocRef.Reservation) Then
					vBalances.Reset();
					If vBalances.FindNext(New Structure("DocRef", vDocRef.Reservation)) Then
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
		// Add room move
		vRoomAppearance = vRowValue.Appearance.Get("Room");
		If vRoomAppearance <> Undefined Then
			vRoom = vRowValue.Data["Room"];
			vRoomTo = vRowValue.Data["RoomTo"];
			If ValueIsFilled(vRoomTo) And vRoom <> vRoomTo Then
				vRoomText = TrimAll(vRoom) + " -> " + TrimAll(vRoomTo);
				vRoomAppearance.SetParameterValue("Text", vRoomText);
				vRoomAppearance.SetParameterValue("BackColor", WebColors.Yellow);
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
EndProcedure // DocumentListIsInHouseOnGetDataAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure DocumentListAllOnGetDataAtServer(pItemName, pSettings, pRows)
	// Balances
	vSelShowAllGuests = pSettings.DataParameters.FindParameterValue(New DataCompositionParameter("qShowAllGuests"));
	vSelShowAllGuests = ?(vSelShowAllGuests = Undefined, 0, vSelShowAllGuests.Value);
	vBalancesAreVisible = pSettings.DataParameters.FindParameterValue(New DataCompositionParameter("qBalancesAreVisible"));
	vBalancesAreVisible = ?(vBalancesAreVisible = Undefined, False, vBalancesAreVisible.Value);
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
		vDocumentsToShow.Columns.Add("Ref", cmGetDocumentTypeDescription("Accommodation"));
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
			vFRowStruct = SystemSettingsStorage.Load("Document.Accommodation.Form.tcAccommodationListForm", "FirstDocInArchiveBatch");
			If vFRowStruct <> Undefined Then
				vFRow = vDocumentsToShow.Find(vFRowStruct.Ref, "Ref");
				If vFRow = Undefined Then
					vFRow = vDocumentsToShow.Add();
					vFRowWasAdded = True;
				EndIf;
				FillPropertyValues(vFRow, vFRowStruct);
			EndIf;

			vLRowStruct = SystemSettingsStorage.Load("Document.Accommodation.Form.tcAccommodationListForm", "LastDocInArchiveBatch");
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
			SystemSettingsStorage.Save("Document.Accommodation.Form.tcAccommodationListForm", "FirstDocInArchiveBatch", vFRowStruct);

			vLRow = vDocumentsToShow.Get(vDocumentsToShow.Count() - 1);
			vLRowStruct = New Structure(vListColumns);
			FillPropertyValues(vLRowStruct, vLRow);
			SystemSettingsStorage.Save("Document.Accommodation.Form.tcAccommodationListForm", "LastDocInArchiveBatch", vLRowStruct);
		EndIf;
	EndIf;

	// Colors and other appearances
	For Each vRow In pRows Do
		vRowValue = vRow.Value;
		vDocRef = vRowValue.Data.Ref;
		
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
			If vSelShowAllGuests = 0 Then
				vDocNumber = vRowValue.Data.RefNumber;
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
				ElsIf TypeOf(vDocRef) = Type("DocumentRef.Accommodation") And ValueIsFilled(vDocRef.Reservation) Then
					vBalances.Reset();
					If vBalances.FindNext(New Structure("DocRef", vDocRef.Reservation)) Then
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
EndProcedure // DocumentListAllOnGetDataAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetBalancesByRooms(pList, pIsReservation = False)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodations.Number AS Number,
	|	Accommodations.Hotel AS Hotel
	|INTO AccommodationList
	|FROM
	|	Document.Accommodation AS Accommodations
	|WHERE
	|	Accommodations.Ref IN(&qList)
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
	|		INNER JOIN AccommodationList AS AccommodationList
	|		ON Accommodations.Number = AccommodationList.Number
	|			AND Accommodations.Hotel = AccommodationList.Hotel
	|
	|UNION ALL
	|
	|SELECT
	|	Reservations.Ref,
	|	Reservations.Hotel,
	|	Reservations.Number
	|FROM
	|	Document.Reservation AS Reservations
	|		INNER JOIN AccommodationList AS AccommodationList
	|		ON Reservations.Number = AccommodationList.Number
	|			AND Reservations.Hotel = AccommodationList.Hotel
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
	|	AND Folio.ParentDoc IN(&qList)
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
Function GetReservationBalancesByRooms(pList)
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
EndFunction // GetReservationBalancesByRooms

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure DocumentListReservationOnGetDataAtServer(pItemName, pSettings, pRows)
	// Balances
	vSelShowAllGuests = pSettings.DataParameters.FindParameterValue(New DataCompositionParameter("qShowAllGuests"));
	vSelShowAllGuests = ?(vSelShowAllGuests = Undefined, 0, vSelShowAllGuests.Value);
	vBalancesAreVisible = pSettings.DataParameters.FindParameterValue(New DataCompositionParameter("qBalancesAreVisible"));
	vBalancesAreVisible = ?(vBalancesAreVisible = Undefined, False, vBalancesAreVisible.Value);
	vBalances = Undefined;
	If vBalancesAreVisible Then
		vList = pRows.GetKeys();
		If vSelShowAllGuests = 0 Then
			vBalances = GetReservationBalancesByRooms(vList);
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
			vFRowStruct = SystemSettingsStorage.Load("Document.Accommodation.Form.tcAccommodationListForm", "FirstDocInReservationBatch");
			If vFRowStruct <> Undefined Then
				vFRow = vDocumentsToShow.Find(vFRowStruct.Ref, "Ref");
				If vFRow = Undefined Then
					vFRow = vDocumentsToShow.Add();
					vFRowWasAdded = True;
				EndIf;
				FillPropertyValues(vFRow, vFRowStruct);
			EndIf;

			vLRowStruct = SystemSettingsStorage.Load("Document.Accommodation.Form.tcAccommodationListForm", "LastDocInReservationBatch");
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
			SystemSettingsStorage.Save("Document.Accommodation.Form.tcAccommodationListForm", "FirstDocInReservationBatch", vFRowStruct);

			vLRow = vDocumentsToShow.Get(vDocumentsToShow.Count() - 1);
			vLRowStruct = New Structure(vListColumns);
			FillPropertyValues(vLRowStruct, vLRow);
			SystemSettingsStorage.Save("Document.Accommodation.Form.tcAccommodationListForm", "LastDocInReservationBatch", vLRowStruct);
		EndIf;
	EndIf;

	// Colors and other appearances
	For Each vRow In pRows Do
		vRowValue = vRow.Value;
		vDocRef = vRowValue.Data.Ref;
		
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
					vDocNumber = vRowValue.Data.RefNumber;
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
EndProcedure // DocumentListReservationOnGetDataAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure IsInHouseListOnActivateRowIdleHandler() 
	vGuestGroup = Undefined;
	vCurData = Items.DocumentListIsInHouse.CurrentData;
	If vCurData <> Undefined Then
		If Not Items.SelectedDocumentsActions.Enabled Then
			Items.SelectedDocumentsActions.Enabled = True;
		EndIf;
		If Not Items.DocumentListIsInHouseSelectedDocumentActions.Enabled Then
			Items.DocumentListIsInHouseSelectedDocumentActions.Enabled = True;
		EndIf;
		TDocument = vCurData.Ref;
		TDocumentRoom = vCurData.Room;
		TDocumentRoomType = vCurData.RoomType;
		TDocumentRoomPresentation = TrimAll(TrimAll(vCurData.Room) + " " + TrimAll(vCurData.RoomTypeCode) + " " + TrimAll(vCurData.RoomRoomStatus));
		TDocumentPeriod = Format(vCurData.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(vCurData.CheckOutDate, "DF='dd.MM HH:mm'") + ", " + Format(vCurData.Duration, "NFD=0; NZ=; NG=") + ", " + TrimAll(vCurData.DocNumber);
		TDocumentPrice = TrimAll(vCurData.PricePresentation);
		TDocumentCustomer = vCurData.Customer;
		TDocumentAgent = vCurData.Agent;
		TDocumentRemarks = TrimAll(vCurData.Remarks) + " " + TrimAll(vCurData.HousekeepingRemarks) + " " + TrimAll(vCurData.Car);
		vGuestGroup = vCurData.GuestGroup;
	Else
		If Items.SelectedDocumentsActions.Enabled Then
			Items.SelectedDocumentsActions.Enabled = False;
		EndIf;
		If Items.DocumentListIsInHouseSelectedDocumentActions.Enabled Then
			Items.DocumentListIsInHouseSelectedDocumentActions.Enabled = False;
		EndIf;
		TDocument = Undefined;
		TDocumentRoom = Undefined;
		TDocumentRoomType = Undefined;
		TDocumentRoomPresentation = "";
		TDocumentPeriod = "";
		TDocumentPrice = "";
		TDocumentCustomer = Undefined;
		TDocumentAgent = Undefined;
		TDocumentRemarks = "";
	EndIf;
	If vGuestGroup <> CurGuestGroup Then
		CurGuestGroup = vGuestGroup;
		ClearTotalsByGroupAtClient();
	EndIf;
EndProcedure // IsInHouseListOnActivateRowIdleHandler

// -----------------------------------------------------------------------------
&AtClient
Procedure RefreshGroupTotals()
	UpdateTotalsByGroupAtServer();
	AttachIdleHandler("GetRefreshGroupTotalsJobResult", 0.5, True);
EndProcedure // RefreshGroupTotals

// -----------------------------------------------------------------------------
&AtServer
Function GetRefreshGroupTotalsJobResultAtServer()
	Items.GroupData.Visible = False;
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
						Items.GroupData.Visible = True;
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
Procedure ClearTotalsByGroupAtServer()
	TotalGroupSales = "";
	TotalGroupPayments = "";
	TotalGroupBalance = "";
	TotalGuestsByGroup = "";
	TotalRoomsByGroup = "";
	Items.GroupData.Visible = False;
EndProcedure // ClearTotalsByGroupAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearTotalsByGroupAtClient()
	TotalGroupSales = "";
	TotalGroupPayments = "";
	TotalGroupBalance = "";
	TotalGuestsByGroup = "";
	TotalRoomsByGroup = "";
	Items.GroupData.Visible = False;
EndProcedure // ClearTotalsByGroupAtClient

// -----------------------------------------------------------------------------
&AtServer
Procedure UpdateTotalsByGroupAtServer()
	TotalGroupSales = "";
	TotalGroupPayments = "";
	TotalGroupBalance = "";
	TotalGuestsByGroup = "";
	TotalRoomsByGroup = "";
	
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
EndProcedure // UpdateTotalsByGroupAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ListAllOnActivateRowIdleHandler() 
	vGuestGroup = Undefined;
	vCurData = Items.DocumentListAll.CurrentData;
	If vCurData <> Undefined Then
		If Not Items.SelectedDocumentsActions.Enabled Then
			Items.SelectedDocumentsActions.Enabled = True;
		EndIf;
		If Not Items.DocumentListAllSelectedDocumentActions.Enabled Then
			Items.DocumentListAllSelectedDocumentActions.Enabled = True;
		EndIf;
		TDocument = vCurData.Ref;
		TDocumentRoom = vCurData.Room;
		TDocumentRoomType = vCurData.RoomType;
		TDocumentRoomPresentation = TrimAll(TrimAll(vCurData.Room) + " " + TrimAll(vCurData.RoomTypeCode));
		TDocumentPeriod = Format(vCurData.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(vCurData.CheckOutDate, "DF='dd.MM HH:mm'") + ", " + Format(vCurData.Duration, "NFD=0; NZ=; NG=") + ", " + TrimAll(vCurData.DocNumber);
		TDocumentPrice = TrimAll(vCurData.PricePresentation);
		TDocumentCustomer = vCurData.Customer;
		TDocumentAgent = vCurData.Agent;
		TDocumentRemarks = TrimAll(vCurData.Remarks) + " " + TrimAll(vCurData.HousekeepingRemarks) + " " + TrimAll(vCurData.Car);
		vGuestGroup = vCurData.GuestGroup;
	Else
		If Items.SelectedDocumentsActions.Enabled Then
			Items.SelectedDocumentsActions.Enabled = False;
		EndIf;
		If Items.DocumentListAllSelectedDocumentActions.Enabled Then
			Items.DocumentListAllSelectedDocumentActions.Enabled = False;
		EndIf;
		TDocument = Undefined;
		TDocumentRoom = Undefined;
		TDocumentRoomType = Undefined;
		TDocumentRoomPresentation = "";
		TDocumentPeriod = "";
		TDocumentPrice = "";
		TDocumentCustomer = Undefined;
		TDocumentAgent = Undefined;
		TDocumentRemarks = "";
	EndIf;
	If vGuestGroup <> CurGuestGroup Then
		CurGuestGroup = vGuestGroup;
		ClearTotalsByGroupAtClient();
	EndIf;
EndProcedure // ListAllOnActivateRowIdleHandler

// -----------------------------------------------------------------------------
&AtServer
Procedure FillFunctionsButtonReservation()
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
	ActionsReservation.Clear();
	While vSelectionRecords.Next() Do
		If vSelectionRecords.PredefinedDataName = "" 
			Or vSelectionRecords.PredefinedDataName = "ReservationSendMyFolioSMS"
			Or vSelectionRecords.PredefinedDataName = "ReservationFillOrder"
			Or vSelectionRecords.PredefinedDataName = "ReservationGuestGroupFillInvoice" 
			Or vSelectionRecords.PredefinedDataName = "ReservationFillInvoice" Then
			vNewRow = ActionsReservation.Add();
			vNewRow.Action = vSelectionRecords.Ref;
			vNewRow.IsDefault = vSelectionRecords.IsDefault;
			
			vID = vNewRow.GetID();
			
			vCommand = Commands.Add("FuncReservation"+vID);
			vCommand.Action = "FuncButtonClickReservation";
			If vSelectionRecords.IsDefault Then
				vStructure = New Structure("Title,CommandName",
				TrimAll(vSelectionRecords.Code) + " " + cmNStr(vSelectionRecords.ref), "FuncReservation"+vID);
			Else
				vStructure = New Structure("Title,CommandName",
				TrimAll(vSelectionRecords.Code) + " " + cmNStr(vSelectionRecords.ref), "FuncReservation"+vID);
			EndIf;
			
			tcOnServer.cmCreateItem(ThisObject, ?(vSelectionRecords.IsDefault, Items.FormGroupFunctionsDefaultReservation, Items.FormGroupFunctionsNotDefaultReservation), "Func_Reservation_" + vID, "FormButton", vStructure);
			tcOnServer.cmCreateItem(ThisObject, ?(vSelectionRecords.IsDefault, Items.FormGroupFunctionsDefaultReservation1, Items.FormGroupFunctionsNotDefaultReservation1), "Func_Reservation_1_" + vID, "FormButton", vStructure);
		EndIf;
	EndDo;
EndProcedure // FillFunctionsButtonReservation

// -----------------------------------------------------------------------------
&AtClient
Procedure ReservationListOnActivateRowIdleHandler()
	vGuestGroup = Undefined;
	vCurData = Items.DocumentListReservation.CurrentData;
	If vCurData <> Undefined Then
		If Not Items.SelectedDocumentsActions.Enabled Then
			Items.SelectedDocumentsActions.Enabled = True;
		EndIf;
		If Not Items.DocumentListReservationSelectedDocumentActions.Enabled Then
			Items.DocumentListReservationSelectedDocumentActions.Enabled = True;
		EndIf;
		TDocument = vCurData.Ref;
		TDocumentRoom = vCurData.Room;
		TDocumentRoomType = vCurData.RoomType;
		TDocumentRoomPresentation = TrimAll(TrimAll(vCurData.Room) + " " + TrimAll(vCurData.RoomTypeCode) + " " + TrimAll(vCurData.RoomRoomStatus));
		TDocumentPeriod = Format(vCurData.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(vCurData.CheckOutDate, "DF='dd.MM HH:mm'") + ", " + Format(vCurData.Duration, "NFD=0; NZ=; NG=") + ", " + TrimAll(vCurData.DocNumber);
		TDocumentPrice = TrimAll(vCurData.PricePresentation);
		TDocumentCustomer = vCurData.Customer;
		TDocumentAgent = vCurData.Agent;
		TDocumentRemarks = TrimAll(vCurData.Remarks) + " " + TrimAll(vCurData.HousekeepingRemarks) + " " + TrimAll(vCurData.Car);
		vGuestGroup = vCurData.GuestGroup;
	Else
		If Items.SelectedDocumentsActions.Enabled Then
			Items.SelectedDocumentsActions.Enabled = False;
		EndIf;
		If Items.DocumentListReservationSelectedDocumentActions.Enabled Then
			Items.DocumentListReservationSelectedDocumentActions.Enabled = False;
		EndIf;
		TDocument = Undefined;
		TDocumentRoom = Undefined;
		TDocumentRoomType = Undefined;
		TDocumentRoomPresentation = "";
		TDocumentPeriod = "";
		TDocumentPrice = "";
		TDocumentCustomer = Undefined;
		TDocumentAgent = Undefined;
		TDocumentRemarks = "";
	EndIf;
	If vGuestGroup <> CurGuestGroup Then
		CurGuestGroup = vGuestGroup;
		ClearTotalsByGroupAtClient();
	EndIf;
EndProcedure // ReservationListOnActivateRowIdleHandler

// -----------------------------------------------------------------------------
&AtServer
Procedure FillFunctionsButtonAccommodation()
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	ObjectFormActions.Ref AS Ref,
	|	ObjectFormActions.Code AS Code,
	|	ObjectFormActions.PredefinedDataName AS PredefinedDataName,
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
	vQuery.SetParameter("ObjectType", Documents.Accommodation.EmptyRef());	
	vQueryResult = vQuery.Execute();	
	vSelectionRecords = vQueryResult.Select();
	ActionsAccommodation.Clear();
	While vSelectionRecords.Next() Do
		If vSelectionRecords.PredefinedDataName = "" 
			Or vSelectionRecords.PredefinedDataName = "AccommodationFillOrder"
			Or vSelectionRecords.PredefinedDataName = "AccommodationSendWelcomeSMS" 
			Or vSelectionRecords.PredefinedDataName = "AccommodationFillClientFeedback" 
			Or vSelectionRecords.PredefinedDataName = "AccommodationFillAccommodation" 
			Or vSelectionRecords.PredefinedDataName = "AccommodationGuestGroupFillSettlement"
			Or vSelectionRecords.PredefinedDataName = "AccommodationGuestGroupFillInvoice" 
			Or vSelectionRecords.PredefinedDataName = "AccommodationFillInvoice" Then
			vNewRow = ActionsAccommodation.Add();
			vNewRow.Action = vSelectionRecords.Ref;
			vNewRow.IsDefault = vSelectionRecords.IsDefault;
			
			vID = vNewRow.GetID();
			
			vCommand = Commands.Add("FuncAccommodation"+vID);
			vCommand.Action = "FuncButtonClickAccommodation";
			If vSelectionRecords.IsDefault Then
				vStructure = New Structure("Title, CommandName",
				TrimAll(vSelectionRecords.Code) + " " + cmNStr(vSelectionRecords.ref), "FuncAccommodation"+vID);
			Else
				vStructure = New Structure("Title, CommandName",
				TrimAll(vSelectionRecords.Code) + " " + cmNStr(vSelectionRecords.ref), "FuncAccommodation"+vID);
			EndIf;
			
			tcOnServer.cmCreateItem(ThisObject, ?(vSelectionRecords.IsDefault, Items.FormGroupFunctionsDefaultAccommodation, Items.FormGroupFunctionsNotDefaultAccommodation), "Func_Accommodation_" + vID, "FormButton", vStructure);
			tcOnServer.cmCreateItem(ThisObject, ?(vSelectionRecords.IsDefault, Items.FormGroupFunctionsDefaultAccommodation1, Items.FormGroupFunctionsNotDefaultAccommodation1), "Func_Accommodation_1_" + vID, "FormButton", vStructure);
			tcOnServer.cmCreateItem(ThisObject, ?(vSelectionRecords.IsDefault, Items.FormGroupFunctionsDefaultAccommodation2, Items.FormGroupFunctionsNotDefaultAccommodation2), "Func_Accommodation_2_" + vID, "FormButton", vStructure);
		EndIf;
	EndDo;
EndProcedure // FillFunctionsButtonAccommodation

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetClientFeedback(pDoc)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ClientFeedback.Ref AS Ref
	|FROM
	|	Document.ClientFeedback AS ClientFeedback
	|WHERE
	|	ClientFeedback.ParentDoc = &qParentDoc
	|	AND NOT ClientFeedback.DeletionMark
	|
	|ORDER BY
	|	ClientFeedback.PointInTime";
	vQry.SetParameter("qParentDoc", pDoc);
	vReviewDocs = vQry.Execute().Unload();
	If vReviewDocs.Count() > 0 Then
		Return vReviewDocs.Get(0).Ref;
	EndIf;
	Return Undefined;
EndFunction // GetClientFeedback

// -----------------------------------------------------------------------------
&AtClient
Procedure AccommodationFillClientFeedback(pDocRef)  
	vGuest = tcOnServer.cmGetAttributeByRef(pDocRef, "Guest"); 
	If ValueIsFilled(vGuest) Then
		// Try to find existing client feedback
		vFeedbackDoc = GetClientFeedback(pDocRef);
		If ValueIsFilled(vFeedbackDoc) Then
			OpenForm("Document.ClientFeedback.ObjectForm", New Structure("Key", vFeedbackDoc), ThisObject);
		Else
			OpenForm("Document.ClientFeedback.ObjectForm", New Structure("Basis", pDocRef), ThisObject);
		EndIf;
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Guest is not filled!'; ru='В размещении не указан гость!'; de='Gast ist nicht gefüllt!'"));
	EndIf;
EndProcedure // AccommodationFillClientFeedback

// -----------------------------------------------------------------------------
&AtServer
Function GetActionForNumberReservation(pActionsNumber)
	vActions = ActionsReservation.FindByID(Number(pActionsNumber)).Action;
	
	vStruct = New Structure();
	vStruct.Insert("Ref",vActions);
	vStruct.Insert("PredefinedDataName",vActions.PredefinedDataName);	
	vStruct.Insert("ExternalProcessing",vActions.ExternalProcessing);
	vStruct.Insert("DataProcessor",vActions.DataProcessor);
	
	Return vStruct;
EndFunction // GetActionForNumberReservation

// -----------------------------------------------------------------------------
&AtServer
Function GetActionForNumberAccommodation(pActionsNumber)
	vActions = ActionsAccommodation.FindByID(Number(pActionsNumber)).Action;
	
	vStruct = New Structure();
	vStruct.Insert("Ref",vActions);
	vStruct.Insert("PredefinedDataName",vActions.PredefinedDataName);	
	vStruct.Insert("ExternalProcessing",vActions.ExternalProcessing);
	vStruct.Insert("DataProcessor",vActions.DataProcessor);
	
	Return vStruct;
EndFunction // GetActionForNumberAccommodation

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
Procedure FillPrintingButtonReservation()
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
	PrintFormsReservation.Clear();
	vLang = Catalogs.Languages.EN;
	If ValueIsFilled(SelHotel) Then
		vLang = SelHotel.Language;
	EndIf;
	While vSelectionRecords.Next() Do
		vSelectionDetailRecords = vSelectionRecords.Select(QueryResultIteration.ByGroups);
		
		If vLang = vSelectionRecords.Language Or Not ValueIsFilled(vSelectionRecords.Language) Then
			vParentLang = Items.FormGroupPrintingNotDefaultMainReservation;
			vParentLang1 = Items.FormGroupPrintingNotDefaultMainReservation1;
		ElsIf Not vLang = vSelectionRecords.Language Then
			vParentLang = tcOnServer.cmCreateItem(ThisObject, Items.FormGroupPrintingNotDefaultExtraReservation, "PrintReservation" + vSelectionRecords.Language, "FormGroup", New Structure("Type,Title", FormGroupType.Popup, vSelectionRecords.Language));
			vParentLang1 = tcOnServer.cmCreateItem(ThisObject, Items.FormGroupPrintingNotDefaultExtraReservation1, "PrintReservation" + vSelectionRecords.Language + "1", "FormGroup", New Structure("Type,Title", FormGroupType.Popup, vSelectionRecords.Language));
		EndIf;
		
		While vSelectionDetailRecords.Next() Do
			If vSelectionDetailRecords.PredefinedDataName = "" 
				Or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintHotelProduct" 
				Or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintGuestGroupHotelProducts"  
				Or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintGuestFormForm5" 
				Or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintGuestForm2Forms5" 
				Or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintGuestFormFreeForm"
				Or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintGuestRegistrationForm"
				Or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintGuestsFormsForm5"
				Or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintGuestsForms2Forms5"
				Or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintGuestsFormsFreeForm"
				Or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintGuestRegistrationForms"
			    Or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintGuestPersonalDataProcessingConsent"
				Or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationRu"  
				Or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationEn"  
				Or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationDe"  
				Or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationWithServicesRu"  
				Or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationWithServicesEn"  		
				Or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationWithServicesDe"  
				Or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintCurrentDocConfirmationRu"  
				Or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintCurrentDocConfirmationEn"  
				Or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintCurrentDocConfirmationDe"  
				Or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintCurrentDocConfirmationWithServicesRu"  
				Or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintCurrentDocConfirmationWithServicesEn"  		
				Or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintCurrentDocConfirmationWithServicesDe" 
				Or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationRichTextRu"  
				Or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationRichTextEn"  		
				Or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationRichTextDe" Then 
				vNewRow = PrintFormsReservation.Add();
				vNewRow.PrintForm = vSelectionDetailRecords.Ref;
				vNewRow.IsDefault = vSelectionDetailRecords.IsDefault;
				
				vID = vNewRow.GetID();
				
				vCommand = Commands.Add("PrintReservation" + vID);
				vCommand.Action = "PrintButtonClickReservation";
				If vSelectionDetailRecords.IsDefault Then
					vParent = Items.FormGroupPrintingDefaultReservation;
					vParent1 = Items.FormGroupPrintingDefaultReservation1;
				Else
					vParent = vParentLang;
					vParent1 = vParentLang1;
				EndIf;
				vStructure = New Structure("Title,CommandName", TrimAll(vSelectionDetailRecords.Code) + " " + cmNStr(vSelectionDetailRecords.ref), "PrintReservation" + vID);
				
				tcOnServer.cmCreateItem(ThisObject, vParent, "Print_Reservation_" + vID, "FormButton", vStructure);
				tcOnServer.cmCreateItem(ThisObject, vParent1, "Print_Reservation_1_" + vID, "FormButton", vStructure);
			EndIf;
		EndDo;
	EndDo;
EndProcedure // FillPrintingButtonReservation

// -----------------------------------------------------------------------------
&AtServer
Procedure FillPrintingButtonAccommodation()
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	ObjectPrintingForms.Ref AS Ref,
	|	ObjectPrintingForms.Code AS Code,
	|	ObjectPrintingForms.PredefinedDataName AS PredefinedDataName,
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
	vQuery.SetParameter("ObjectType", Documents.Accommodation.EmptyRef());	
	vQueryResult = vQuery.Execute();	
	vSelectionRecords = vQueryResult.Select(QueryResultIteration.ByGroups);
	PrintFormsAccommodation.Clear();
	vLang = Catalogs.Languages.EN;
	If ValueIsFilled(SelHotel) Then
		vLang = SelHotel.Language;
	EndIf;
	While vSelectionRecords.Next() Do
		vSelectionDetailRecords = vSelectionRecords.Select(QueryResultIteration.ByGroups);
		
		If vLang = vSelectionRecords.Language Or Not ValueIsFilled(vSelectionRecords.Language) Then
			vParentLang = Items.FormGroupPrintingNotDefaultMainAccommodation;
			vParentLang1 = Items.FormGroupPrintingNotDefaultMainAccommodation1;
			vParentLang2 = Items.FormGroupPrintingNotDefaultMainAccommodation2;
		ElsIf Not vLang = vSelectionRecords.Language Then
			vParentLang = tcOnServer.cmCreateItem(ThisObject, Items.FormGroupPrintingNotDefaultExtraAccommodation, "PrintAccommodation"+vSelectionRecords.Language, "FormGroup", New Structure("Type, Title", FormGroupType.Popup, vSelectionRecords.Language));
			vParentLang1 = tcOnServer.cmCreateItem(ThisObject, Items.FormGroupPrintingNotDefaultExtraAccommodation1, "PrintAccommodation"+vSelectionRecords.Language + "1", "FormGroup", New Structure("Type, Title", FormGroupType.Popup, vSelectionRecords.Language));
			vParentLang2 = tcOnServer.cmCreateItem(ThisObject, Items.FormGroupPrintingNotDefaultExtraAccommodation2, "PrintAccommodation"+vSelectionRecords.Language + "2", "FormGroup", New Structure("Type, Title", FormGroupType.Popup, vSelectionRecords.Language));
		EndIf;
		
		While vSelectionDetailRecords.Next() Do
			If vSelectionDetailRecords.PredefinedDataName = "" Or
			   vSelectionDetailRecords.PredefinedDataName = "AccommodationPrintHotelProduct" Or
			   vSelectionDetailRecords.PredefinedDataName = "AccommodationPrintGuestGroupHotelProducts" Or 
			   vSelectionDetailRecords.PredefinedDataName = "AccommodationPrintGuestForm2Forms5" Or
			   vSelectionDetailRecords.PredefinedDataName = "AccommodationPrintGuestFormFreeForm" Or
			   vSelectionDetailRecords.PredefinedDataName = "AccommodationPrintGuestRegistrationForm" Or
			   vSelectionDetailRecords.PredefinedDataName = "AccommodationPrintGuestRegistrationForms" Or
			   vSelectionDetailRecords.PredefinedDataName = "AccommodationPrintGuestsForms2Forms5" Or
			   vSelectionDetailRecords.PredefinedDataName = "AccommodationPrintGuestsFormsFreeForm" Or 
			   vSelectionDetailRecords.PredefinedDataName = "AccommodationPrintGuestPersonalDataProcessingConsent" Or 
			   vSelectionDetailRecords.PredefinedDataName = "AccommodationPrintGuestRefusalToPayResortFee" Then
				vNewRow = PrintFormsAccommodation.Add();
				vNewRow.PrintForm = vSelectionDetailRecords.Ref;
				vNewRow.IsDefault = vSelectionDetailRecords.IsDefault;
				
				vID = vNewRow.GetID();
				
				vCommand = Commands.Add("PrintAccommodation"+vID);
				vCommand.Action = "PrintButtonClickAccommodation";
				If vSelectionDetailRecords.IsDefault Then
					vParent = Items.FormGroupPrintingDefaultAccommodation;
					vParent1 = Items.FormGroupPrintingDefaultAccommodation1;
					vParent2 = Items.FormGroupPrintingDefaultAccommodation2;
				Else
					vParent = vParentLang;
					vParent1 = vParentLang1;
					vParent2 = vParentLang2;
				EndIf;
				vStructure = New Structure("Title, CommandName", TrimAll(vSelectionDetailRecords.Code) + " " + cmNStr(vSelectionDetailRecords.ref), "PrintAccommodation" + vID);
				
				tcOnServer.cmCreateItem(ThisObject, vParent, "Print_Accommodation_" + vID, "FormButton", vStructure);
				tcOnServer.cmCreateItem(ThisObject, vParent1, "Print_Accommodation_1_" + vID, "FormButton", vStructure);
				tcOnServer.cmCreateItem(ThisObject, vParent2, "Print_Accommodation_2_" + vID, "FormButton", vStructure);
			EndIf;
		EndDo;
	EndDo;
EndProcedure // FillPrintingButtonAccommodation

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
		vList = Undefined;
		If TypeOf(pDocRef) = Type("DocumentRef.Reservation") Then
			vList = Items.DocumentListReservation;
		Else
			vPage = "DocumentListIsInHouse";
			If SelFilterStatus = 1 Then
				vPage = "DocumentListAll";
			EndIf;
			vList = Items[vPage];
		EndIf;
		If vList.SelectedRows.Count() > 1 Then
			For Each vRow In vList.SelectedRows Do
				vRowDoc = vList.RowData(vRow).Ref;
				If vInputParameter.FindByValue(vRowDoc) = Undefined Then
					vInputParameter.Add(vRowDoc);
				EndIf;
			EndDo;
		EndIf;
	Else
		If TypeOf(pDocRef) = Type("DocumentRef.Reservation") Then
			AddOneRoomReservations(vInputParameter, pDocRef);
		Else
			AddOneRoomAccommodations(vInputParameter, pDocRef);
		EndIf;
	EndIf;
	If TypeOf(pDocRef) = Type("DocumentRef.Reservation") Then
		vPrtForm = PredefinedValue("Catalog.ObjectPrintingForms.ReservationPrintGuestPersonalDataProcessingConsent");
	Else
		vPrtForm = PredefinedValue("Catalog.ObjectPrintingForms.AccommodationPrintGuestPersonalDataProcessingConsent");
	EndIf;
	vParams = New Structure("InputParameter, ObjectPrintingForm, Lang", vInputParameter, vPrtForm, vLang);
	OpenForm("Document.Accommodation.Form.tcAccommodationPrintForm", vParams, ThisObject, New UUID);
EndProcedure // PrintGuestPersonalDataProcessingConsent

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintGuestRefusalToPayResortFee(pDocRef)
	vLang = Undefined;
	If ValueIsFilled(pDocRef.Guest) Then
		vLang = tcOnServer.cmGetAttributeByRef(pDocRef.Guest, "Language");
	EndIf;
	vInputParameter = New ValueList();
	vInputParameter.Add(pDocRef);
	vPrtForm = PredefinedValue("Catalog.ObjectPrintingForms.AccommodationPrintGuestRefusalToPayResortFee");
	vParams = New Structure("InputParameter, ObjectPrintingForm, Lang", vInputParameter, vPrtForm, vLang);
	OpenForm("Document.Accommodation.Form.tcAccommodationPrintForm", vParams, ThisObject, New UUID);
EndProcedure // PrintGuestRefusalToPayResortFee

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
	vFrm = OpenForm("Document.Accommodation.Form.tcPrintGuestForm", New Structure("Document, GuestGroup, ObjectPrintingForm", pDocRef, tcOnServer.cmGetAttributeByRef(pDocRef, "GuestGroup"), vObjPrtForm), ThisObject, pDocRef);
EndProcedure // PrintGuestsForms

// -----------------------------------------------------------------------------
&AtServer
Function GetPrintFormForNumberReservation(pActionsNumber)
	vPrintForms = PrintFormsReservation.FindByID(Number(pActionsNumber)).PrintForm;
	
	vStruct = New Structure();
	vStruct.Insert("Ref",vPrintForms);
	vStruct.Insert("PredefinedDataName",vPrintForms.PredefinedDataName);	
	vStruct.Insert("ExternalProcessing",vPrintForms.ExternalProcessing);
	vStruct.Insert("Report",vPrintForms.Report);
	vStruct.Insert("Language",vPrintForms.Language);
	
	Return vStruct;
EndFunction // GetPrintFormForNumberReservation

// -----------------------------------------------------------------------------
&AtServer
Function GetPrintFormForNumberAccommodation(pActionsNumber)
	vPrintForms = PrintFormsAccommodation.FindByID(Number(pActionsNumber)).PrintForm;
	
	vStruct = New Structure();
	vStruct.Insert("Ref", vPrintForms);
	vStruct.Insert("PredefinedDataName", vPrintForms.PredefinedDataName);	
	vStruct.Insert("ExternalProcessing", vPrintForms.ExternalProcessing);
	vStruct.Insert("Report", vPrintForms.Report);
	vStruct.Insert("Language", vPrintForms.Language);
	
	Return vStruct;
EndFunction // GetPrintFormForNumberAccommodation

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
	vParams = New Structure("InputParameter, ObjectPrintingForm", pDocRef, pPrintFormTypeRef);
	vFrm = GetForm("ExternalDataProcessor." + vName + ".Form", vParams);
	vFrm.Open();
EndProcedure // OpenExternalProcedureForm

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenExternalReportForm(pExtRepRef, pPrintFormTypeRef, pDocRef)
	vURL = GetURL(tcOnServer.cmGetAttributeByRef(pExtRepRef, "Report"), "ExternalProcessingStorage"); 
	vName = ConnectExternalReport(vURL, "ExternalReportForm");
	vParams = New Structure("Document, ObjectPrintingForm", pDocRef, pPrintFormTypeRef);
	OpenForm("ExternalReport." + vName + ".Form", vParams);
EndProcedure // OpenExternalReportForm

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintHotelProduct(pLang, pForm, pDocRef)
	If pForm = PredefinedValue("Catalog.ObjectPrintingForms.ReservationPrintHotelProduct") Then
		vParams = New Structure("SelDocument, SelRoom, SelGuestGroup, SelCheckInDate, SelObjectPrintForm", 
		                         pDocRef,
								 tcOnServer.cmGetAttributeByRef(pDocRef, "Room"),
								 tcOnServer.cmGetAttributeByRef(pDocRef, "GuestGroup"),
								 tcOnServer.cmGetAttributeByRef(pDocRef, "CheckInDate"),
								 pForm);	
	ElsIf pForm = PredefinedValue("Catalog.ObjectPrintingForms.ReservationPrintGuestGroupHotelProducts") Then
		vParams = New Structure("SelGuestGroup, SelCheckInDate, SelObjectPrintForm", 
		                         tcOnServer.cmGetAttributeByRef(pDocRef, "GuestGroup"),
								 tcOnServer.cmGetAttributeByRef(pDocRef, "CheckInDate"),
								 pForm);
	EndIf;
	OpenForm("Report.PrintHotelProducts.Form.tcReportForm", vParams, ThisObject, pDocRef);
EndProcedure // PrintHotelProduct

// -----------------------------------------------------------------------------
&AtServer
Function SendWelcomeSMSAtServerReservation(pDocRef)
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
EndFunction // SendWelcomeSMSAtServerReservation

// -----------------------------------------------------------------------------
&AtClient
Procedure SendWelcomeSMSReservation(pDocRef)
	vMessage = SendWelcomeSMSAtServerReservation(pDocRef);
	If Not IsBlankString(vMessage) Then
		tcCommonFunctionOnClientServer.TextMessage(vMessage);
	EndIf;
EndProcedure // SendWelcomeSMSReservation

// -----------------------------------------------------------------------------
&AtServer
Function SendWelcomeSMSAtServerAccommodation(pDocRef)
	vMessage = "";
	If ValueIsFilled(pDocRef.AccommodationStatus) And pDocRef.AccommodationStatus.IsActive And pDocRef.AccommodationStatus.IsInHouse Then
		vExtSys = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsHotel365(pDocRef.Hotel);
		If Not ValueIsFilled(vExtSys) Then
			// The integration with hotel365 is not set
			Return NStr("en = 'Integration with the hotel365 service is not configured'; de = 'Die Integration mit hotel365 ist nicht konfiguriert'; ru = 'Не настроена интеграция с сервисом hotel365'");
		EndIf;
		If Not vExtSys.IsActive Then
			// The integration with hotel365 is switched off
			Return NStr("en = 'The Integration with hotel365 is switched off'; de = 'Die Integration mit hotel365 ist ausgeschaltet'; ru = 'Интеграция с hotel365 отключена'");
		EndIf;

		// Get list of accommodations to send message to
		vDocsList = New ValueList();
		If ValueIsFilled(pDocRef.Guest) And pDocRef.Guest.NoSMSDelivery Then
			vMessage = vMessage + StrTemplate(NStr("en='Guest %1 refused SMS notifications!'; ru='Гость %1 отказался от СМС оповещений!'; de='Gast %1 hat SMS-Benachrichtigungen abgelehnt'"), TrimAll(pDocRef.Guest));
		Else
			vDocsList.Add(pDocRef.Ref);
		EndIf;
		vOneRoomGuests = cmGetOneRoomAccommodations(pDocRef.Room, pDocRef.GuestGroup, pDocRef.CheckInDate, pDocRef.CheckOutDate, pDocRef.Number);
		For Each vOneRoomGuestsRow In vOneRoomGuests Do
			vOneRoomDocRef = vOneRoomGuestsRow.Ref;
			If vOneRoomDocRef <> pDocRef And ValueIsFilled(vOneRoomDocRef.Guest) And vOneRoomDocRef.Guest <> pDocRef.Guest And vOneRoomDocRef.AccommodationStatus.IsActive And vOneRoomDocRef.AccommodationStatus.IsInHouse Then
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
			EndIf;
		EndDo;
	EndIf;
	Return vMessage;
EndFunction // SendWelcomeSMSAtServerAccommodation

// -----------------------------------------------------------------------------
&AtClient
Procedure SendWelcomeSMSAccommodation(pDocRef)
	vMessage = SendWelcomeSMSAtServerAccommodation(pDocRef);
	If Not IsBlankString(vMessage) Then
		tcCommonFunctionOnClientServer.TextMessage(vMessage);
	EndIf;
EndProcedure // SendWelcomeSMSAccommodation

// -----------------------------------------------------------------------------
&AtServerNoContext
Function FillParametersCard(pDocRef)
	vParameters = New Structure("Folio, Hotel, Client, AccommodationType, CheckInDate, CheckOutDate, ParentDoc, Room, IdentityCardSystemParameters");
	
	vCurDoc = pDocRef;
	
	If ValueIsFilled(vCurDoc.Room) Then
		vParameters.Room = vCurDoc.Room;
	EndIf;
	vParameters.CheckInDate = cmGetKeyCardCheckInTime(vCurDoc.CheckInDate, ?(TypeOf(vCurDoc) = Type("DocumentRef.Reservation"), True, False));
	vParameters.CheckOutDate = cmGetLastCheckOutDateInChain(vCurDoc);
	vParameters.Client = vCurDoc.Guest;
	vParameters.AccommodationType = vCurDoc.AccommodationType;
	vParameters.ParentDoc = vCurDoc;
	vParameters.Hotel = vCurDoc.Hotel;
	vCurWstn = SessionParameters.CurrentWorkstation;
	If ValueIsFilled(vCurWstn) Then
		If vCurWstn.HasConnectionToIdentityCardsProcessingSystem Then
			vParameters.IdentityCardSystemParameters = vCurWstn.IdentityCardsProcessingSystemParameters;
		EndIf;
	EndIf;
	// Fill folio from the last charging rule
	vParameters.Folio = Documents.Folio.EmptyRef();
	If vCurDoc.ChargingRules.Count() > 0 Then
		vParameters.Folio = vCurDoc.ChargingRules.Get(vCurDoc.ChargingRules.Count()-1).ChargingFolio;
	EndIf;
	Return vParameters;
EndFunction // FillParametersCard

// -----------------------------------------------------------------------------
&AtServer
Function GetFOTotalsJobResultsAtServer()
	If GetFOTotalsJobUUID <> EmptyUUID Then
		vBackgroundJob = AsyncCalls.CheckBackgroundJob(GetFOTotalsJobUUID);
		If vBackgroundJob <> Undefined Then 
			If vBackgroundJob.Status = "Processing" Then 
				Return "Processing";
			ElsIf vBackgroundJob.Status = "Completed" Then
				vJobResult = GetFromTempStorage(GetFOTotalsJobAddress);
				If vJobResult <> Undefined Then
					TArrivalTotals = "" + vJobResult.CheckInRooms + NStr("en = ' rms./'; ru = ' ном./'; de = ' Zim./'") + vJobResult.CheckInGuests + NStr("en = ' prs.'; ru = ' чел.'; de = ' Prs.'");
					TDepartureTotals = "" + vJobResult.CheckOutRooms + NStr("en = ' rms./'; ru = ' ном./'; de = ' Zim./'") + vJobResult.CheckOutGuests + NStr("en = ' prs.'; ru = ' чел.'; de = ' Prs.'");
					TInhouseTotals = "" + vJobResult.InHouseRooms + NStr("en = ' rms./'; ru = ' ном./'; de = ' Zim./'") + vJobResult.InHouseGuests + NStr("en = ' prs.'; ru = ' чел.'; de = ' Prs.'");
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	Return "Completed";
EndFunction // GetFOTotalsJobResultsAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure GetFOTotalsJobResults()
	vStatus = GetFOTotalsJobResultsAtServer();
	If vStatus = "Processing" Then
		AttachIdleHandler("GetFOTotalsJobResults", 0.5, True);
	EndIf;
EndProcedure // GetFOTotalsJobResults

// -----------------------------------------------------------------------------
&AtServerNoContext
Function IsActiveReservation(pReservation)
	If pReservation.Posted And (pReservation.ReservationStatus.IsActive Or pReservation.ReservationStatus.IsPreliminary) Then
		If BegOfDay(pReservation.CheckOutDate) >= BegOfDay(CurrentSessionDate()) Then
			If pReservation.RoomQuantity = 1 Then
				Return True;
			EndIf;
		EndIf;
	EndIf;
	Return False;
EndFunction // IsActiveReservation

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
&AtServer
Procedure ClearTotalsAtServer()
	TArrivalTotals = "";
	TDepartureTotals = "";
	TInhouseTotals = "";
EndProcedure // ClearTotalsAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearTotalsAtClient()
	TArrivalTotals = "";
	TDepartureTotals = "";
	TInhouseTotals = "";
EndProcedure // ClearTotalsAtClient

// -----------------------------------------------------------------------------
&AtServer
Function GetDataProcessorForExportGuestDataToUFMS()
	If ValueIsFilled(SelHotel) Then
		Return cmGetDataProcessorForExportGuestDataToUFMS(SelHotel);
	Else
		Return Undefined;
	EndIf;
EndFunction // GetDataProcessorForExportGuestDataToUFMS

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterTDocumentCustomerClickAnswer(pUC, pCustomer) Export
	If pUC <> Undefined Then
		If pUC.Value = 0 Then
			SelCustomer = pCustomer;
			SelCustomerOnChange(Items.SelCustomer);
		Else
			ShowValue(,pCustomer);
		EndIf;
	EndIf;
EndProcedure // AfterTDocumentCustomerClickAnswer

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterTDocumentAgentClickAnswer(pUC, pAgent) Export
	If pUC <> Undefined Then
		If pUC.Value = 0 Then
			SelAgent = pAgent;
			SelAgentOnChange(Items.SelAgent);
		Else
			ShowValue(,pAgent);
		EndIf;
	EndIf;
EndProcedure // AfterTDocumentAgentClickAnswer

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterCurGuestGroupClickAnswer(pUC, pGuestGroup) Export
	If pUC <> Undefined Then
		If pUC.Value = 0 Then
			SelGuestGroup = pGuestGroup;
			SelGuestGroupOnChange(Items.SelGuestGroup);
		Else
			ShowValue(, pGuestGroup);
		EndIf;
	EndIf;
EndProcedure // AfterCurGuestGroupClickAnswer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetRemarksForAPDEX(pObject)
	
	vAPDEXParams = New Structure;         
	vAPDEXParams.Insert("Number", pObject.Number); 
	If TypeOf(pObject) = Type("DocumentRef.Accommodation") Then
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

#EndRegion    
