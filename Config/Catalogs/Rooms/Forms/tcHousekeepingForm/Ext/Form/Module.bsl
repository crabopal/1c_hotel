
#Region FormEventHandlers

// -------------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Hotel
	SelHotel = SessionParameters.CurrentHotel;
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
	// Add room statuses
	vRoomStatuses = cmGetAllRoomStatuses();
	For Each vRoomStatusesRow In vRoomStatuses Do
		TableBoxStatuses.Add(vRoomStatusesRow.RoomStatus, TrimAll(vRoomStatusesRow.Description), True, cmGetRoomStatusIcon(vRoomStatusesRow.RoomStatus));
	EndDo;
	// Check user permission to change room statuses
	If Not cmCheckUserPermissions("HavePermissionToChangeRoomStatuses") Then
		Items.CatalogListRoomsRoomStatus.ReadOnly = True;
		Items.FormCopyValue.Enabled = False;
		Items.FormCopyValue1.Enabled = False;
	EndIf;
	// Show all rooms by default
	SelShowAllRooms = True;
	SelShowCheckedIn = False;
	SelShowCheckedOut = False;
	SelShowPlannedCheckIn = False;
	SelShowPlannedCheckOut = False;
	SelShowDirtyRooms = False;
	SelShowCleanRooms = False;
	SelShowOccupiedRooms = False;
	SelShowVacantRooms = False;
	SelShowRoomsWithTasks = False;
	SelShowRoomsWithDiscrepancies = False;
	SelShowRoomsWithBedsSetupDiscrepancies = False;
	SelShowRoomsBlock = False;
	SelShowRoomsStopSale = False;
	SelShowRegularOperations = False;
	CheckAllStatuses();
	If Parameters.Property("FilterStatus") Then
		If Parameters.FilterStatus = "<DirtyRooms>" Then
			SelShowAllRooms = False;
			SelShowDirtyRooms = True;
			CheckDirtyStatuses();
		ElsIf Parameters.FilterStatus = "<CleanRooms>" Then
			SelShowAllRooms = False;
			SelShowCleanRooms = True;
			CheckCleanStatuses();
		ElsIf Parameters.FilterStatus = "<RoomsWithTasks>" Then
			SelShowAllRooms = False;
			SelShowRoomsWithTasks = True;
		ElsIf Parameters.FilterStatus = "<Discrepancies>" Then
			SelShowAllRooms = False;
			SelShowRoomsWithDiscrepancies = True;
		ElsIf Parameters.FilterStatus = "<VacantRooms>" Then
			SelShowAllRooms = False;
			SelShowVacantRooms = True;
		ElsIf Parameters.FilterStatus = "<OccupiedRooms>" Then
			SelShowAllRooms = False;
			SelShowOccupiedRooms = True;
		ElsIf Parameters.FilterStatus <> "<AllRooms>" Then  
			If Left(Parameters.FilterStatus, 1) = "N" And StrLen(Parameters.FilterStatus) > 1 Then  
				vRoomStatusCode = Mid(Parameters.FilterStatus, 2); 
			Else       
				vRoomStatusCode = Parameters.FilterStatus;
			EndIf;
			vRoomStatusSelected = Catalogs.RoomStatuses.FindByCode(vRoomStatusCode, False);
			UncheckAllStatuses();
			For Each vStatusItem In TableBoxStatuses Do
				If vStatusItem.Value = vRoomStatusSelected Then
					vStatusItem.Check = True;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	If Parameters.Property("FilterRoomType") Then
		SelRoomType = Parameters.FilterRoomType; 	
	EndIf;         
	// Employee default parameters
	If ValueIsFilled(SelHotel) Then
		If ValueIsFilled(SessionParameters.CurrentUser) Then
			vCurUser = SessionParameters.CurrentUser;
			If Not ValueIsFilled(SelRoomsFolder) And ValueIsFilled(vCurUser.Room) Then
				SelRoomsFolder = vCurUser.Room;
			ElsIf Not ValueIsFilled(SelRoomType) And ValueIsFilled(vCurUser.RoomType) Then
				SelRoomType = vCurUser.RoomType;
			EndIf;  
			SelRoomSection = vCurUser.RoomSection;
		EndIf;
	EndIf;

	SelRoomTypes.Clear();
	If ValueIsFilled(SelRoomType) Then
		If SelRoomType.IsFolder Then
			vRoomTypes = cmGetAllRoomTypes(SelHotel, SelRoomType);
			For Each vRoomTypesRow In vRoomTypes Do
				SelRoomTypes.Add(vRoomTypesRow.RoomType);
			EndDo;
		Else
			SelRoomTypes.Add(SelRoomType);
		EndIf;
	EndIf;
	
	// Form conditional appearance for client types
	vAllClientTypes = cmGetAllClientTypes(SelHotel);
	For Each vClientTypeRow In vAllClientTypes Do
		If vClientTypeRow.Color <> Undefined Then
			// Color for client types
			vNewConditionalAppearance = ConditionalAppearance.Items.Add();
			vNewConditionalAppearance.Appearance.Items[0].Value = vClientTypeRow.Color;
			vNewConditionalAppearance.Appearance.Items[0].Use = True;
			// Filter
			vNewFilterForAppearance = vNewConditionalAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
			vNewFilterForAppearance.LeftValue = New DataCompositionField("TableBoxRooms.ClientType");
			vNewFilterForAppearance.ComparisonType = DataCompositionComparisonType.Equal;
			vNewFilterForAppearance.RightValue = vClientTypeRow.ClientType;
			vNewFilterForAppearance.Use = True;
			// Fields
			vNewFieldsForApperance = vNewConditionalAppearance.Fields.Items.Add();
			vNewFieldsForApperance.Field = New DataCompositionField("CatalogListRoomsRemarks");
			vNewFieldsForApperance.Use = True;
		EndIf;
	EndDo;
	// Form conditional appearance for room statuses
	vAllRoomStatuses = cmGetAllRoomStatuses();
	For Each vRoomStatusRow In vAllRoomStatuses Do
		If vRoomStatusRow.Color <> Undefined Then
			// Color for client types
			vNewConditionalAppearance = ConditionalAppearance.Items.Add();
			vNewConditionalAppearance.Appearance.Items[0].Value = vRoomStatusRow.Color;
			vNewConditionalAppearance.Appearance.Items[0].Use = True;
			// Filter
			vNewFilterForAppearance = vNewConditionalAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
			vNewFilterForAppearance.LeftValue = New DataCompositionField("TableBoxRooms.RoomStatus");
			vNewFilterForAppearance.ComparisonType = DataCompositionComparisonType.Equal;
			vNewFilterForAppearance.RightValue = vRoomStatusRow.RoomStatus;
			vNewFilterForAppearance.Use = True;
			// Fields
			vNewFieldsForApperance = vNewConditionalAppearance.Fields.Items.Add();
			vNewFieldsForApperance.Field = New DataCompositionField("CatalogListRoomsRoomStatus");
			vNewFieldsForApperance.Use = True;
		EndIf;
	EndDo;
	
	// Price presentation
	If ValueIsFilled(SelHotel) Then
		Items.CurPrice.Visible = SelHotel.UseMaximumPriceInPricePresentation;
	EndIf;
	
	// Beds setup presentation
	SetBedsSetupAvailability();
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	// Fill rooms list
	FillRoomsListAtServer();
EndProcedure // OnCreateAtServer

// -------------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	// Expand items
	For Each vItem In TableBoxRooms.GetItems() Do
		Items.TableBoxRooms.Expand(vItem.GetID(), True);
	EndDo;
	If tcOnClient.IsHomePageWindow(ThisObject) Then
		vPrefix = NStr("en = 'Rooms: '; de = 'Zimmerbestand: '; ru = 'Номерной фонд: '");
		tcCommonFunctionOnClientServer.cmSetFormTitleHotelName(ThisObject, vPrefix);
	EndIf;
	// Columns visibility
	#If MobileClient Then
		Items.FormOpenRoom.Visible = False;
		Items.CatalogListRoomsOpenStateOfRoom.Visible = False;
		Items.CatalogListRoomsOpenRoomStatusChangeHistory.Visible = False;
		Items.FormCopyValue.Visible = False;
		Items.FormPasteValue.Visible = False;
	#Else 
		Items.CatalogListRoomsRoomStatusLastChangeTime.Visible = True;
		Items.CatalogListRoomsFloor.Visible = True;
		Items.CatalogListRoomsCustomer.Visible = True;
		Items.CatalogListRoomsHasRoomBlocks.Visible = True;
		Items.CatalogListRoomsIsVirtual.Visible = True;
		Items.CatalogListRoomsStopSale.Visible = True;
	#EndIf		
EndProcedure // OnOpen

// -------------------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If ValueIsFilled(pParameter) Then
		If pEventName = "Document.SetRoomBlock.Write" Then 
			RefreshRoomInListAtServer(tcOnServer.cmGetAttributeByRef(pParameter, "Room"), tcOnServer.cmGetAttributeByRef(pParameter, "RoomBlockType"));	
		ElsIf pEventName = "Catalog.Rooms.Write" Or pEventName = "Subsystem.Rooms.Changed" Then
			RefreshRoomInListAtServer(pParameter);
		ElsIf pEventName = "tcEditHousekeepingRemarks.Write" And TypeOf(pParameter) = Type("Structure") Then
			CurRemarks = TrimAll(TrimAll(pParameter.HousekeepingRemarks) + Chars.LF + TrimAll(tcOnServer.cmGetAttributeByRef(pParameter.Document, "Remarks")));
			CurHousekeepingRemarks = TrimAll(pParameter.HousekeepingRemarks);
			RefreshRoomInListAtServer(pParameter.Room);
		ElsIf pEventName = "MessageWrite" Then
			vRoom = tcOnServer.cmGetAttributeByRef(pParameter, "ByObject");
			If TypeOf(vRoom) = Type("CatalogRef.Rooms") Then
				FillRoomsList();
			EndIf;
		ElsIf pEventName = "System.Hotel.Changed" And pParameter <> SelHotel Then
			SelHotel = pParameter;
			FillRoomsList();
			If tcOnClient.IsHomePageWindow(ThisObject) Then
				vPrefix = NStr("en = 'Rooms: '; de = 'Zimmerbestand: '; ru = 'Номерной фонд: '");
				tcCommonFunctionOnClientServer.cmSetFormTitleHotelName(ThisObject, vPrefix);
			EndIf;
		EndIf;
	Else
		If pEventName = "Document.SetRoomBlock.Write" 
			Or pEventName = "Document.SetRoomBlock.Unblock" 
			Or pEventName = "Document.SetRoomBlock.WriteListRoom" 
			Or pEventName = "tcStopSaleMultipleRooms.Execute" Then
			FillRoomsList();
		EndIf;	
	EndIf;
EndProcedure // NotificationProcessing

#EndRegion

#Region FormHeaderItemsEventHandlers

// -------------------------------------------------------------------------------------
&AtClient
Procedure SelHotelOnChange(pItem)
	// Beds setup availability
	SetBedsSetupAvailability();
	// Fill rooms list
	FillRoomsList();
EndProcedure // SelHotelOnChange

// -------------------------------------------------------------------------------------
&AtClient
Procedure SelRoomsFolderOnChange(pItem)
	// Fill rooms list
	FillRoomsList();
EndProcedure // SelRoomsFolderOnChange

// -------------------------------------------------------------------------------------
&AtClient
Procedure SelRoomSectionOnChange(Item)
	// Fill rooms list
	FillRoomsList();
EndProcedure // SelRoomSectionOnChange

// -------------------------------------------------------------------------------------
&AtClient
Procedure SelFloorOnChange(Item)
	// Fill rooms list
	FillRoomsList();
EndProcedure // SelFloorOnChange

// -------------------------------------------------------------------------------------
&AtClient
Procedure SelBedsSetupOnChange(pItem)
	// Fill rooms list
	FillRoomsList();
EndProcedure

// -------------------------------------------------------------------------------------
&AtClient
Procedure SelBedsSetupInReservationOnChange(pItem)
	// Fill rooms list
	FillRoomsList();
EndProcedure // SelBedsSetupInReservationOnChange

// -------------------------------------------------------------------------------------
&AtClient
Procedure SelRoomOnChange(Item)
	// Fill rooms list
	FillRoomsList();
EndProcedure // SelRoomOnChange

// -------------------------------------------------------------------------------------
&AtClient
Procedure TableBoxRoomsSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	vCurData = Items.TableBoxRooms.CurrentData;
	If vCurData <> Undefined And Not vCurData.IsFolder Then
		If pField.Name <> "CatalogListRoomsRoomStatus" And pField.Name <> "TableBoxRoomsBedsSetup" Then
			pStandardProcessing = False;
			OpenForm("Catalog.Rooms.Form.tcHousekeepingItemForm", New Structure("Key", vCurData.Ref));
		EndIf;
	EndIf;
EndProcedure // TableBoxRoomsSelection 

// -------------------------------------------------------------------------------------
&AtClient
Procedure TableBoxRoomsOnActivateCell(pItem)
	If Items.TableBoxRooms.CurrentItem <> Undefined Then
		If Items.TableBoxRooms.CurrentItem.Name = "CatalogListRoomsRoomStatus" Then
			vCurData = Items.TableBoxRooms.CurrentData;
			If vCurData <> Undefined And Not vCurData.IsFolder Then
				vList = GetAllowedRoomStatusesList(vCurData.RoomStatus);
				If vList.FindByValue(vCurData.RoomStatus) = Undefined Then
					vList.Insert(0, vCurData.RoomStatus);
				EndIf;
				Items.CatalogListRoomsRoomStatus.ChoiceList.LoadValues(vList.UnloadValues());
			EndIf;
		ElsIf Items.TableBoxRooms.CurrentItem.Name = "TableBoxRoomsBedsSetup" Then
			vCurData = Items.TableBoxRooms.CurrentData;
			If vCurData <> Undefined And Not vCurData.IsFolder Then
				Items.TableBoxRoomsBedsSetup.ChoiceList.Clear();
				vList = GetBedsSetupList(vCurData.BedsSetup, vCurData.RoomType);
				For Each vListItem In vList Do
					Items.TableBoxRoomsBedsSetup.ChoiceList.Add(vListItem.Value, vListItem.Presentation);
				EndDo;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // TableBoxRoomsOnActivateCell

// -------------------------------------------------------------------------------------
&AtClient
Procedure CatalogListRoomsRoomStatusOnChange(pItem)
	vCurRowId = Items.TableBoxRooms.CurrentRow;
	If vCurRowId <> Undefined Then
		vRowData = TableBoxRooms.FindByID(vCurRowId);
		If Not vRowData.IsFolder Then
			vRowData.RoomStatusIcon = GetRoomStatusIconIndex(vRowData.RoomStatus);
			
			vOldRoomStatus = Undefined;
			vRoomStatusLastChangeTime = UpdateRoomStatus(vRowData.Ref, vRowData.RoomStatus, vOldRoomStatus);
			If vRoomStatusLastChangeTime <> Undefined Then
				vRowData.RoomStatusLastChangeTime = vRoomStatusLastChangeTime;
			EndIf;
			
			// Update room statuses statistics
			For Each vRoomStatusItem In TableBoxStatuses Do
				vRoomStatus = vRoomStatusItem.Value;
				If vRoomStatus = vOldRoomStatus Then
					vRoomStatusItem.Presentation = UpdateRoomStatusPresentation(vRoomStatusItem.Presentation, -1);
				ElsIf vRoomStatus = vRowData.RoomStatus Then
					vRoomStatusItem.Presentation = UpdateRoomStatusPresentation(vRoomStatusItem.Presentation, 1);
				EndIf;
			EndDo;

			// Fill new list of allowed room statuses
			vList = GetAllowedRoomStatusesList(vRowData.RoomStatus);
			If vList.FindByValue(vRowData.RoomStatus) = Undefined Then
				vList.Insert(0, vRowData.RoomStatus);
			EndIf;
			Items.CatalogListRoomsRoomStatus.ChoiceList.LoadValues(vList.UnloadValues());
		EndIf;
	EndIf;
EndProcedure // CatalogListRoomsRoomStatusOnChange

// -------------------------------------------------------------------------------------
&AtClient
Procedure TableBoxRoomsBedsSetupOnChange(pItem)
	vCurRowId = Items.TableBoxRooms.CurrentRow;
	If vCurRowId <> Undefined Then
		vRowData = TableBoxRooms.FindByID(vCurRowId);
		If Not vRowData.IsFolder Then
			UpdateRoomBedsSetup(vRowData.Ref, vRowData.BedsSetup);
			AttachIdleHandler("FillBedsSetupTotals", 0.5, True);
		EndIf;
	EndIf;
EndProcedure // TableBoxRoomsBedsSetupOnChange

// -------------------------------------------------------------------------------------
&AtClient
Procedure FillBedsSetupTotals() Export
	FillBedsSetupTotalsAtServer();
	For Each vRow In BedsSetupTotals.GetItems() Do
		Items.BedsSetupTotals.Collapse(vRow.GetID());
	EndDo;
EndProcedure // FillBedsSetupTotals

// -------------------------------------------------------------------------------------
&AtClient
Procedure TableBoxRoomsBeforeRowChange(pItem, pCancel)
	vCurData = Items.TableBoxRooms.CurrentData;
	If vCurData <> Undefined And vCurData.IsFolder Then
		pCancel = True;
	EndIf;
EndProcedure // TableBoxRoomsBeforeRowChange

// -----------------------------------------------------------------------------
&AtClient
Procedure TableBoxRoomsOnActivateRow(pItem)
	vCurData = Items.TableBoxRooms.CurrentData;
	If vCurData <> Undefined Then
		CurRowRoom = vCurData.Ref;
	Else
		CurRowRoom = Undefined;
	EndIf;
	CurCondition = "";
	CurGuest = Undefined;
	CurGuestFullName = Undefined;
	CurCheckInDate = Undefined;
	CurCheckOutDate = Undefined;
	CurTemplate = Undefined;
	CurDocument = Undefined;
	CurRemarks = "";
	CurHousekeepingRemarks = "";
	CurPrice = "";
	AttachIdleHandler("ShowRoomGuestsData", 0.7, True);
EndProcedure // TableBoxRoomsOnActivateRow

// -----------------------------------------------------------------------------
&AtClient
Procedure TableBoxStatusesOnChange(pItem)
	// Fill rooms list
	FillRoomsList();
EndProcedure // TableBoxStatusesOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure TableBoxStatusesSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	// Fill rooms list
	vRowData = TableBoxStatuses.FindByID(pSelectedRow);
	If vRowData <> Undefined Then
		vRowId = TableBoxStatusesSelectionAtServer(vRowData.Value);
		If vRowId <> Undefined Then
			Items.TableBoxRooms.CurrentRow = vRowId;
		EndIf;
	EndIf;
EndProcedure // TableBoxStatusesSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure SelShowAllRoomsOnChange(pItem)
	If Not SelShowAllRooms Then
		SelShowAllRooms = True;
	EndIf;
	
	CheckAllStatuses();
	
	SelShowCheckedIn = False;
	SelShowCheckedOut = False;
	SelShowPlannedCheckIn = False;
	SelShowPlannedCheckOut = False;
	SelShowDirtyRooms = False;
	SelShowCleanRooms = False;
	SelShowOccupiedRooms = False;
	SelShowVacantRooms = False;
	SelShowRoomsWithTasks = False;
	SelShowRoomsWithDiscrepancies = False;
	SelShowRoomsWithBedsSetupDiscrepancies = False;
	SelShowRoomsBlock = False;
	SelShowRoomsStopSale = False;
	SelShowRegularOperations = False;
	
	// Fill rooms list
	FillRoomsList();
EndProcedure // SelShowAllRoomsOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelShowDirtyRoomsOnChange(pItem)
	If SelShowDirtyRooms Then
		SelShowAllRooms = False;
		
		CheckDirtyStatuses();
		
		SelShowCleanRooms = False;
	Else
		SelShowAllRooms = True;
	
		CheckAllStatuses();
		
		SelShowCleanRooms = False;
	EndIf;		
	
	SelShowRoomsWithTasks = False;
	SelShowRoomsWithDiscrepancies = False;
	SelShowRoomsWithBedsSetupDiscrepancies = False;
	
	// Fill rooms list
	FillRoomsList();
EndProcedure // SelShowDirtyRoomsOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelShowCleanRoomsOnChange(pItem)
	If SelShowCleanRooms Then
		SelShowAllRooms = False;
		
		CheckCleanStatuses();
		
		SelShowDirtyRooms = False;
	Else
		SelShowAllRooms = True;
	
		CheckAllStatuses();
		
		SelShowDirtyRooms = False;
	EndIf;		
	
	SelShowRoomsWithTasks = False;
	SelShowRoomsWithDiscrepancies = False;
	SelShowRoomsWithBedsSetupDiscrepancies = False;
	
	// Fill rooms list
	FillRoomsList();
EndProcedure // SelShowCleanRoomsOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelShowVacantRoomsOnChange(pItem)
	If SelShowVacantRooms Then
		SelShowAllRooms = False;
	EndIf;		
	SelShowOccupiedRooms = False;
	SelShowDirtyRooms = False;
	SelShowCleanRooms = False;
	SelShowRoomsWithTasks = False;
	SelShowRoomsWithDiscrepancies = False;
	SelShowRoomsWithBedsSetupDiscrepancies = False;
	SelShowRegularOperations = False;
	
	CheckAllStatuses();
	
	// Fill rooms list
	FillRoomsList();
EndProcedure // SelShowVacantRoomsOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelShowOccupiedRoomsOnChange(pItem)
	If SelShowOccupiedRooms Then
		SelShowAllRooms = False;
	EndIf;		
	SelShowVacantRooms = False;
	SelShowDirtyRooms = False;
	SelShowCleanRooms = False;
	SelShowRoomsWithTasks = False;
	SelShowRoomsWithDiscrepancies = False;
	SelShowRoomsWithBedsSetupDiscrepancies = False;
	
	CheckAllStatuses();
	
	// Fill rooms list
	FillRoomsList();
EndProcedure // SelShowOccupiedRoomsOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelShowPlannedCheckInOnChange(pItem)
	If SelShowPlannedCheckIn Then
		SelShowAllRooms = False;
	EndIf;		
	SelShowDirtyRooms = False;
	SelShowCleanRooms = False;
	
	CheckAllStatuses();
	
	// Fill rooms list
	FillRoomsList();
EndProcedure // SelShowPlannedCheckInOnChange

// -------------------------------------------------------------------------------------
&AtClient
Procedure SelShowPlannedCheckOutOnChange(pItem)
	If SelShowPlannedCheckOut Then
		SelShowAllRooms = False;
	EndIf;		
	SelShowDirtyRooms = False;
	SelShowCleanRooms = False;

	CheckAllStatuses();
	
	// Fill rooms list
	FillRoomsList();
EndProcedure // SelShowPlannedCheckOutOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelShowCheckedInOnChange(pItem)
	If SelShowCheckedIn Then
		SelShowAllRooms = False;
	EndIf;		
	SelShowCheckedOut = False;
	SelShowDirtyRooms = False;
	SelShowCleanRooms = False;
	
	CheckAllStatuses();
	
	// Fill rooms list
	FillRoomsList();
EndProcedure // SelShowCheckedInOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelShowCheckedOutOnChange(pItem)
	If SelShowCheckedOut Then
		SelShowAllRooms = False;
	EndIf;		
	SelShowCheckedIn = False;
	SelShowDirtyRooms = False;
	SelShowCleanRooms = False;
	
	CheckAllStatuses();
	
	// Fill rooms list
	FillRoomsList();
EndProcedure // SelShowCheckedOutOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelShowRoomsWithTasksOnChange(pItem)
	If SelShowRoomsWithTasks Then
		SelShowAllRooms = False;
	EndIf;		
	SelShowDirtyRooms = False;
	SelShowCleanRooms = False;
	SelShowVacantRooms = False;
	SelShowOccupiedRooms = False;
	
	CheckAllStatuses();
	
	// Fill rooms list
	FillRoomsList();
EndProcedure // SelShowRoomsWithTasksOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelShowRoomsWithDiscrepanciesOnChange(pItem)
	If SelShowRoomsWithDiscrepancies Then
		SelShowAllRooms = False;
	EndIf;		
	SelShowDirtyRooms = False;
	SelShowCleanRooms = False;
	SelShowVacantRooms = False;
	SelShowOccupiedRooms = False;
	
	CheckAllStatuses();
	
	// Fill rooms list
	FillRoomsList();
EndProcedure // SelShowRoomsWithDiscrepanciesOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelShowRoomsWithBedsSetupDiscrepanciesOnChange(pItem)
	If SelShowRoomsWithBedsSetupDiscrepancies Then
		SelShowAllRooms = False;
	EndIf;		
	SelShowDirtyRooms = False;
	SelShowCleanRooms = False;
	SelShowVacantRooms = False;
	SelShowOccupiedRooms = False;
	
	CheckAllStatuses();
	
	// Fill rooms list
	FillRoomsList();
EndProcedure // SelShowRoomsWithBedsSetupDiscrepanciesOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelShowRoomsBlockOnChange(pItem)
	 If SelShowRoomsBlock Then
		SelShowAllRooms = False;
	EndIf;
	CheckAllStatuses();
	
	// Fill rooms list
	FillRoomsList();
 EndProcedure // SelShowRoomsBlockOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelShowRoomsStopSaleOnChange(pItem)
	If SelShowRoomsStopSale Then
		SelShowAllRooms = False;
	EndIf; 
	CheckAllStatuses();
	
	// Fill rooms list
	FillRoomsList();
EndProcedure // SelShowRoomsStopSaleOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelShowRegularOperationsOnChange(pItem)
	If SelShowRegularOperations Then
		SelShowAllRooms = False;
	EndIf; 
	CheckAllStatuses();
	
	// Fill rooms list
	FillRoomsList();
EndProcedure // SelShowRegularOperationsOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CurGuestFullNameClick(pItem, pStandardProcessing)
	pStandardProcessing = False;
	If ValueIsFilled(CurGuest) Then
		OpenForm("Catalog.Clients.ObjectForm", New Structure("Key", CurGuest), , CurGuest);
	EndIf;
EndProcedure // CurGuestFullNameClick

// -----------------------------------------------------------------------------
&AtClient
Procedure CurRemarksStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Rooms.Form.tcEditHousekeepingRemarksForm", New Structure("Document, Room, HousekeepingRemarks", CurDocument, CurRowRoom, CurHousekeepingRemarks), ThisObject);
EndProcedure // CurRemarksStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure CurRemarksClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure // CurRemarksClearing

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomPropertiesStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vList = GetRoomProperties(SelHotel);
	// Ask user to check what he needs
	vList.ShowCheckItems(New NotifyDescription("SelRoomPropertiesStartChoice_AfterInput", ThisObject, New Structure()), NStr("en = 'Check the properties of the rooms ...'; de = 'Überprüfen Sie die Eigenschaften der Zahlen ...'; ru = 'Отметьте свойства номеров...'"));
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomPropertiesClearing(Item, StandardProcessing)
	SelRoomProperties.Clear();
	// Fill rooms list
	FillRoomsList();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomTypesStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vList = GetRoomTypes(SelHotel, SelRoomTypes);
	// Ask user to check what he needs
	vList.ShowCheckItems(New NotifyDescription("SelRoomTypesStartChoice_AfterInput", ThisObject, New Structure()), NStr("en = 'Check room types ...'; de = 'Überprüfen Sie die Zimmertypen ...'; ru = 'Отметьте типы номеров...'"));
EndProcedure // SelRoomTypesStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomTypesClearing(pItem, pStandardProcessing)
	SelRoomTypes.Clear();
	// Fill rooms list
	FillRoomsList();
EndProcedure // SelRoomTypesClearing

// -----------------------------------------------------------------------------
&AtClient
Procedure SelHotelClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure // SelHotelClearing

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomPropertiesOnChange(pItem)
	If SelRoomProperties.Count() = 0 Then
		Items.SelRoomProperties.InputHint = NStr("en='Filter by properties'; ru='Отбор по свойствам'; de='Auswahl nach Eigenschaften'"); 
	Else
		Items.SelRoomProperties.InputHint = "";
	EndIf;
EndProcedure // SelRoomPropertiesOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomTypesOnChange(pItem)
	If SelRoomTypes.Count() = 0 Then
		Items.SelRoomTypes.InputHint = NStr("en='Filter by room types'; ru='Отбор по типам номеров'; de='Filter nach Zimmertypen'"); 
	Else
		Items.SelRoomTypes.InputHint = "";
	EndIf;
EndProcedure // SelRoomTypesOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure BedsSetupTotalsDateOnChange(pItem)
	FillBedsSetupTotalsAtServer();
	For Each vRow In BedsSetupTotals.GetItems() Do
		Items.BedsSetupTotals.Collapse(vRow.GetID());
	EndDo;
EndProcedure // BedsSetupTotalsDateOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure BedsSetupTotalsSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	vRowData = BedsSetupTotals.FindByID(pSelectedRow);
	If vRowData <> Undefined Then
		If pField.Name = "BedsSetupTotalsRoomsAvailable" Then
			vCurBedsSetup = vRowData.GetParent().BedsSetup;
			vCurRoomType = vRowData.RoomType;
			
			// Apply filter
			SelShowAllRooms = True;
			SelBedsSetup = vCurBedsSetup;
			SelBedsSetupInReservation = Undefined;
			SelRoomType = Undefined;
			SelRoomTypes.Clear();
			SelRoomTypes.Add(vCurRoomType);
			SelRoomsFolder = Undefined;
			SelFloor = "";
			SelRoomSection = Undefined;
			SelRoom = Undefined;
			SelRoomProperties.Clear();
			
			SkipBedsSetupTotalsUpdate = True;
			
			SelShowAllRoomsOnChange(Items.SelShowAllRooms);
			SelRoomTypesOnChange(Items.SelRoomTypes);
		ElsIf pField.Name = "BedsSetupTotalsRoomsNeeded" Then
			vCurBedsSetup = vRowData.GetParent().BedsSetup;
			vCurRoomType = vRowData.RoomType;
			
			// Apply filter
			SelShowAllRooms = True;
			SelBedsSetup = Undefined;
			SelBedsSetupInReservation = vCurBedsSetup;
			SelRoomType = Undefined;
			SelRoomTypes.Clear();
			SelRoomTypes.Add(vCurRoomType);
			SelRoomsFolder = Undefined;
			SelFloor = "";
			SelRoomSection = Undefined;
			SelRoom = Undefined;
			SelRoomProperties.Clear();
			
			SkipBedsSetupTotalsUpdate = True;
			
			SelShowAllRoomsOnChange(Items.SelShowAllRooms);
			SelRoomTypesOnChange(Items.SelRoomTypes);
		EndIf;
	EndIf;
EndProcedure // BedsSetupTotalsSelection

#EndRegion

#Region FormCommandsEventHandlers

// -------------------------------------------------------------------------------------
&AtClient
Procedure OpenStateOfRoom(pCommand)
	vCurData = Items.TableBoxRooms.CurrentData;
	If vCurData <> Undefined Then
		If Not CheckUserPermissionToOpenRooms() Then
			Raise NStr("en='You do not have rights to this function!';ru='Нет прав на эту функцию!';de='Sie haben keine Rechte für diese Funktion!'");
		EndIf;
		If vCurData.NumberOfGuestsOnArrival > 0 Then
			// APDEX
			vKeyOperation = "Document.Accommodation.Form.tcAccommodationListForm.Arrival.OpenForm";
			APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

			OpenForm("Document.Accommodation.Form.tcAccommodationListForm", New Structure("Room, SelFilterStatus", vCurData.Ref, 2), ThisObject, vCurData.Ref);
		Else
			// APDEX
			vKeyOperation = "Document.Accommodation.Form.tcAccommodationListForm.InHouseGuests.OpenForm";
			APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

			OpenForm("Document.Accommodation.Form.tcAccommodationListForm", New Structure("Room, SelFilterStatus", vCurData.Ref, 0), ThisObject, vCurData.Ref);
		EndIf;
	EndIf;
EndProcedure // OpenStateOfRoom

// -------------------------------------------------------------------------------------
&AtClient
Procedure OpenRoomStatusChangeHistory(pCommand)
	vCurData = Items.TableBoxRooms.CurrentData;
	If vCurData <> Undefined Then
		OpenForm("InformationRegister.RoomStatusChangeHistory.ListForm", New Structure("Filter", New Structure("Room", vCurData.Ref)), ThisObject);
	EndIf;
EndProcedure // OpenRoomStatusChangeHistory

// -------------------------------------------------------------------------------------
&AtClient
Procedure RefreshRooms(pCommand)
	// APDEX
	vKeyOperation = "Catalog.Rooms.Form.tcHousekeepingForm.Refresh";
	APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

	// Fill rooms list
	FillRoomsList();
EndProcedure // RefreshRooms

// -------------------------------------------------------------------------------------
&AtClient
Procedure OpenRoom(pCommand)
	vCurData = Items.TableBoxRooms.CurrentData;
	If vCurData <> Undefined And Not vCurData.IsFolder Then
		OpenForm("Catalog.Rooms.ObjectForm", New Structure("Key", vCurData.Ref));
	EndIf;
EndProcedure // OpenRoom

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeRoomType(pCommand)
	vCurData = Items.TableBoxRooms.CurrentData;
	If vCurData <> Undefined And Not vCurData.IsFolder Then
		OpenForm("Document.ChangeRoom.ObjectForm", New Structure("Basis", vCurData.Ref));
	EndIf;
EndProcedure // ChangeRoomType

// -----------------------------------------------------------------------------
&AtClient
Procedure CopyValue(pCommand)
	If Items.TableBoxRooms.CurrentRow <> Undefined Then
		vRoomData = TableBoxRooms.FindByID(Items.TableBoxRooms.CurrentRow);
		If Items.TableBoxRooms.CurrentItem <> Undefined Then
			If Not Items.FormCopyValue.Check Then
				If Items.TableBoxRooms.CurrentItem.Name = "CatalogListRoomsRoomStatus" Then
					CopyColumn = "RoomStatus";
					CopyValue = vRoomData[CopyColumn];
					Items.FormCopyValue.Check = True;
					Items.FormCopyValue1.Check = True;
					Items.FormPasteValue.Enabled = True;
					Items.FormPasteValue1.Enabled = True;
					Items.FormPasteValue.Title = NStr("en='Paste '; ru='Вставить '; de='Paste '") + TrimAll(CopyValue);
					Items.FormPasteValue1.Title = NStr("en='Paste '; ru='Вставить '; de='Paste '") + TrimAll(CopyValue);
				ElsIf Items.TableBoxRooms.CurrentItem.Name = "TableBoxRoomsBedsSetup" Then
					CopyColumn = "BedsSetup";
					CopyValue = vRoomData[CopyColumn];
					Items.FormCopyValue.Check = True;
					Items.FormCopyValue1.Check = True;
					Items.FormPasteValue.Enabled = True;
					Items.FormPasteValue1.Enabled = True;
					Items.FormPasteValue.Title = NStr("en='Paste '; ru='Вставить '; de='Paste '") + TrimAll(CopyValue);
					Items.FormPasteValue1.Title = NStr("en='Paste '; ru='Вставить '; de='Paste '") + TrimAll(CopyValue);
				EndIf;
			Else
				Items.FormCopyValue.Check = False;
				Items.FormCopyValue1.Check = False;
				Items.FormPasteValue.Enabled = False;
				Items.FormPasteValue1.Enabled = False;
				Items.FormPasteValue.Title = NStr("en='Paste'; ru='Вставить'; de='Paste'");
				Items.FormPasteValue1.Title = NStr("en='Paste'; ru='Вставить'; de='Paste'");

				CopyColumn = "";
				CopyValue = Undefined;
			EndIf;
		Else
			Items.FormCopyValue.Check = False;
			Items.FormCopyValue1.Check = False;
			Items.FormPasteValue.Enabled = False;
			Items.FormPasteValue1.Enabled = False;
			Items.FormPasteValue.Title = NStr("en='Paste'; ru='Вставить'; de='Paste'");
			Items.FormPasteValue1.Title = NStr("en='Paste'; ru='Вставить'; de='Paste'");

			CopyColumn = "";
			CopyValue = Undefined;
		EndIf;
	Else
		Items.FormCopyValue.Check = False;
		Items.FormCopyValue1.Check = False;
		Items.FormPasteValue.Enabled = False;
		Items.FormPasteValue1.Enabled = False;
		Items.FormPasteValue.Title = NStr("en='Paste'; ru='Вставить'; de='Paste'");
		Items.FormPasteValue1.Title = NStr("en='Paste'; ru='Вставить'; de='Paste'");

		CopyColumn = "";
		CopyValue = Undefined;
	EndIf;
EndProcedure // CopyValue

// -----------------------------------------------------------------------------
&AtClient
Procedure PasteValue(pCommand)
	If Not IsBlankString(CopyColumn) Then
		vSelectedRows = Items.TableBoxRooms.SelectedRows;
		For Each vSelectedRow In vSelectedRows Do
			vRowData = TableBoxRooms.FindByID(vSelectedRow);
			If Not vRowData.IsFolder Then
				If CopyColumn = "RoomStatus" Then
					vRowData.RoomStatus = CopyValue;
					vRowData.RoomStatusIcon = GetRoomStatusIconIndex(vRowData.RoomStatus);
					
					vOldRoomStatus = Undefined;
					vRoomStatusLastChangeTime = UpdateRoomStatus(vRowData.Ref, vRowData.RoomStatus, vOldRoomStatus);
					If vRoomStatusLastChangeTime <> Undefined Then
						vRowData.RoomStatusLastChangeTime = vRoomStatusLastChangeTime;
					EndIf;
					
					// Update room statuses statistics
					For Each vRoomStatusItem In TableBoxStatuses Do
						vRoomStatus = vRoomStatusItem.Value;
						If vRoomStatus = vOldRoomStatus Then
							vRoomStatusItem.Presentation = UpdateRoomStatusPresentation(vRoomStatusItem.Presentation, -1);
						ElsIf vRoomStatus = CopyValue Then
							vRoomStatusItem.Presentation = UpdateRoomStatusPresentation(vRoomStatusItem.Presentation, 1);
						EndIf;
					EndDo;
				ElsIf CopyColumn = "BedsSetup" Then
					If UpdateRoomBedsSetup(vRowData.Ref, CopyValue) Then
						vRowData.BedsSetup = CopyValue;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
		If CopyColumn = "BedsSetup" Then
			FillBedsSetupTotalsAtServer();
		EndIf;
		Items.FormCopyValue.Check = False;
		Items.FormCopyValue1.Check = False;
		Items.FormPasteValue.Enabled = False;
		Items.FormPasteValue1.Enabled = False;
		Items.FormPasteValue.Title = NStr("en='Paste'; ru='Вставить'; de='Paste'");
		Items.FormPasteValue1.Title = NStr("en='Paste'; ru='Вставить'; de='Paste'");
	EndIf;
	CopyColumn = "";
	CopyValue = Undefined;
EndProcedure // PasteValue

// -----------------------------------------------------------------------------
&AtClient
Procedure BlockRooms(pCommand)
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToSetRoomBlocks") Then
		ShowMessageBox(,NStr("en = 'You do not have rights to set room blocks!'; de = 'Sie haben keine Rechte, Zimmerblockierungen einzurichten!'; ru = 'Нет прав на установку блокировок номеров!'"));
		Return;	
	EndIf;
	vSelectedRows = Items.TableBoxRooms.SelectedRows;
	If vSelectedRows.Count() > 1 Then
		vAllListRooms = GetAllListRooms(SelHotel);
		If vAllListRooms.Count() > 0 Then
			For Each vSelectedRow In vSelectedRows Do
				vRoomInTree = Items.TableBoxRooms.RowData(vSelectedRow);
				If vRoomInTree <> Undefined And Not vRoomInTree.IsFolder Then
					vRoomInList = vAllListRooms.FindByValue(vRoomInTree.Ref);
					If vRoomInList <> Undefined Then
						vRoomInList.Check = True;
					Else
						vRoomInList.Check = False;
					EndIf;
				EndIf;
			EndDo;
			OpenForm("Document.SetRoomBlock.Form.tcDocumentForm", New Structure("SelListRoom", vAllListRooms), ThisObject, UUID, , , New NotifyDescription("CloseFormSetRoomBlock", ThisObject));
		EndIf;
	ElsIf vSelectedRows.Count() = 1 Then
		vRoomInTree = Items.TableBoxRooms.RowData(vSelectedRows[0]);
		If vRoomInTree <> Undefined And Not vRoomInTree.IsFolder Then
			OpenForm("Document.SetRoomBlock.Form.tcDocumentForm", New Structure("Room", vRoomInTree.Ref), ThisObject, UUID, , , New NotifyDescription("CloseFormSetRoomBlock", ThisObject));
		EndIf;
	EndIf;
EndProcedure // BlockRooms

 // -----------------------------------------------------------------------------
&AtClient
Procedure UnblockRooms(pCommand)
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToSetRoomBlocks") Then
		ShowMessageBox(, NStr("en = 'You do not have rights to remove room blocks!'; 
							  |de = 'Sie haben keine Rechte, Zimmerblockierungen Abhebung!'; 
							  |ru = 'Нет прав на снятие блокировок номеров!'"));
		Return;	
	EndIf; 
	vParams = New Structure();
	vParams.Insert("SelHotel", SelHotel);
	vCurRowArr = Items.TableBoxRooms.SelectedRows;
	If vCurRowArr.Count() > 0 Then
		vCurRowList = New ValueList();
		For Each vCurRow In vCurRowArr Do
			vRoom = TableBoxRooms.FindByID(vCurRow);
			If Not vRoom.IsFolder Then
				vCurRowList.Add(vRoom.Ref);
			EndIf;
		EndDo;
		vParams.Insert("SelCurRoomList", vCurRowList);
	EndIf;
	OpenForm("Catalog.Rooms.Form.tcUnblockRoomsForm", vParams, ThisObject, UUID);
 EndProcedure // UnblockRooms

 // -----------------------------------------------------------------------------
&AtClient
 Procedure ActionStopSale(pCommand)
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToStopSaleRooms") Then
		ShowMessageBox(, NStr("en = 'You do not have rights to stop sale rooms!'; 
							  |de = 'Sie haben keine Rechte, Zimmer aus dem Verkauf zu nehmen!'; 
							  |ru = 'Нет прав на снятие номеров с продажи!'"));
		Return;
	EndIf;
	vSelRooms = New ValueList();
	For Each vSelRowID In Items.TableBoxRooms.SelectedRows Do
		vSelRow = TableBoxRooms.FindByID(vSelRowID);
		If vSelRow <> Undefined Then
			vSelRooms.Add(vSelRow.Ref);
		EndIf;
	EndDo;
	If vSelRooms.Count() > 0 Then
		OpenForm("CommonForm.tcStopSaleMultipleRooms", New Structure("SelListRef", vSelRooms), ThisObject, UUID);
	EndIf;
 EndProcedure // ActionStopSale

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintRoomsList(pCommand)
	vParam =  New Structure();
	vParam.Insert("TableBoxRooms", TableBoxRooms);
	vParam.Insert("SelFilter1", GetFilter1Presentation());
	vParam.Insert("SelFilter2", GetFilter2Presentation());
	vParam.Insert("SelFilter3", GetFilter3Presentation());
	vParam.Insert("UseBedsSetup", ?(ValueIsFilled(SelHotel), tcOnServer.cmGetAttributeByRef(SelHotel, "BedsSetups"), False));
	OpenForm("Catalog.Rooms.Form.tcPrintRoomsListForm", vParam , ThisObject, UUID);
 EndProcedure // PrintRoomsList

// --------------------------------------------------------------------------------
&AtClient
Procedure RefreshBedsSetupTotals(pCommand)
	FillBedsSetupTotalsAtServer();
	For Each vRow In BedsSetupTotals.GetItems() Do
		Items.BedsSetupTotals.Collapse(vRow.GetID());
	EndDo;
EndProcedure // RefreshBedsSetupTotals

// --------------------------------------------------------------------------------
&AtClient
Procedure CreateTask(pCommand)
	// Build list of rooms to process
	vRoomSelected = Undefined;
	vRoomsList = New ValueList();
	For Each vRowID In Items.TableBoxRooms.SelectedRows Do
		vRowData = TableBoxRooms.FindByID(vRowID);
		If vRowData <> Undefined Then
			If ValueIsFilled(vRowData.Ref) And Not vRowData.IsFolder Then
				If Not ValueIsFilled(vRoomSelected) Then
					vRoomSelected = vRowData.Ref;
				Else
					vRoomsList.Add(vRowData.Ref);
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	If ValueIsFilled(vRoomSelected) Then
		// Open task form
		vParams = New Structure("Type, SetParamObject, SetDepartment, RoomsList", PredefinedValue("Enum.MessageTypes.Task"), vRoomSelected, GetHousekeepingDepartment(), vRoomsList);
		OpenForm("Document.Message.ObjectForm", vParams, ThisObject, vRoomSelected);
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='No rooms selected!'; ru='Не выбраны номера!'; de='Keine Zimmer ausgewählt!'"), MessageStatus.Information);
	EndIf;
EndProcedure // CreateTask

#EndRegion  

#Region Private

// -----------------------------------------------------------------------------
&AtClient
Procedure FillRoomsList()
	// Fill rooms list
	vRowId = FillRoomsListAtServer();
	If vRowId <> Undefined Then
		Items.TableBoxRooms.CurrentRow = vRowId;
	EndIf;
EndProcedure // FillRoomsList

// -----------------------------------------------------------------------------
// Description: Returns value table with accommodations intersecting by period with
//              input parameter period and for the given hotel, room type,
//              room or rooms list
// Parameters: Hotel, Room type, Room, Start of period, End of period,
//             Rooms value list
// Return value: Value table with accommodations found
// -----------------------------------------------------------------------------
&AtServer
Function GetRoomGuests(pRooms, pDate)
	// Build and run query to get room guests
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	RoomInventory.Room AS Room,
	|	RoomInventory.Customer AS Customer,
	|	RoomInventory.GuestGroup.Description AS GuestGroupDescription,
	|	CAST(ISNULL(RoomInventory.Guest.Remarks, """") AS STRING(512)) AS GuestRemarks,
	|	CAST(ISNULL(RoomInventory.Recorder.HousekeepingRemarks, """") AS STRING(512)) AS HousekeepingRemarks,
	|	CASE
	|		WHEN RoomInventory.CheckOutDate >= &qDateFrom
	|				AND RoomInventory.CheckOutDate <= &qDateTo
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS CheckOutToday,
	|	RoomInventory.IsInHouse AS IsInHouse,
	|	SUM(RoomInventory.NumberOfPersons) AS NumberOfPersons
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventory
	|WHERE
	|	RoomInventory.IsAccommodation
	|	AND RoomInventory.IsInHouse
	|	AND RoomInventory.Room IN(&qRooms)
	|	AND RoomInventory.RecordType = &qExpense
	|	AND RoomInventory.PeriodFrom < &qDateTo
	|	AND RoomInventory.PeriodTo > &qDateFrom
	|	AND RoomInventory.Period = RoomInventory.PeriodFrom
	|
	|GROUP BY
	|	RoomInventory.Room,
	|	RoomInventory.Customer,
	|	RoomInventory.GuestGroup.Description,
	|	CAST(ISNULL(RoomInventory.Guest.Remarks, """") AS STRING(512)),
	|	CAST(ISNULL(RoomInventory.Recorder.HousekeepingRemarks, """") AS STRING(512)),
	|	CASE
	|		WHEN RoomInventory.CheckOutDate >= &qDateFrom
	|				AND RoomInventory.CheckOutDate <= &qDateTo
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	RoomInventory.IsInHouse
	|
	|ORDER BY
	|	RoomInventory.Room.SortCode";
	
	vQry.SetParameter("qRooms", pRooms);
	vQry.SetParameter("qExpense", AccumulationRecordType.Expense);
	vQry.SetParameter("qDateFrom", BegOfDay(pDate));
	vQry.SetParameter("qDateTo", EndOfDay(pDate));
	
	vQryTab = vQry.Execute().Unload();
	
	// Return
	Return vQryTab;
EndFunction // GetRoomGuests

// -------------------------------------------------------------------------------------
&AtServerNoContext
Function GetHotelsList(pHotel)
	vHotelsList = New ValueList();
	If ValueIsFilled(pHotel) Then
		vHotelsList.Add(pHotel);
	Else
		vHotels = cmGetAllHotels();
		For Each vHotelsRow In vHotels Do
			vHotelsList.Add(vHotelsRow.Hotel);
		EndDo;
	EndIf;
	Return vHotelsList;
EndFunction // GetHotelsList

// -------------------------------------------------------------------------------------
&AtServer
Function FillRoomsListAtServer()
	vRowId = Undefined;

	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
	
	// Check if all shortcuts are off
	If Not SelShowCheckedIn And Not SelShowCheckedOut 
		And Not SelShowPlannedCheckIn And Not SelShowPlannedCheckOut 
		And Not SelShowDirtyRooms And Not SelShowCleanRooms 
		And Not SelShowVacantRooms And Not SelShowOccupiedRooms 
		And Not SelShowRoomsWithTasks And Not SelShowRoomsWithDiscrepancies And Not SelShowRoomsWithBedsSetupDiscrepancies
		And Not SelShowRoomsBlock And Not SelShowRoomsStopSale And Not SelShowRegularOperations Then
		SelShowAllRooms = True;
	EndIf;
	// Check if all statuses are selected
	For Each vItem In TableBoxStatuses Do
		If Not vItem.Check Then
			SelShowAllRooms = False;
			Break;
		EndIf;
	EndDo;
	If SelShowAllRooms Then
		If SelShowCheckedIn Or SelShowCheckedOut 
			Or SelShowPlannedCheckIn Or SelShowPlannedCheckOut 
			Or SelShowDirtyRooms Or SelShowCleanRooms 
			Or SelShowVacantRooms Or SelShowOccupiedRooms 
			Or SelShowRoomsWithTasks Or SelShowRoomsWithDiscrepancies Or SelShowRoomsWithBedsSetupDiscrepancies
			Or SelShowRoomsBlock Or SelShowRoomsStopSale Or SelShowRegularOperations Then
			SelShowAllRooms = False;
		EndIf;
	EndIf;
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
	
	// List of hotels
	vHotelsList = GetHotelsList(SelHotel);
	
	// Fill list of statuses
	vStatusesList = New ValueList();
	For Each vRoomStatusesItem In TableBoxStatuses Do
		If vRoomStatusesItem.Check Then
			vStatusesList.Add(vRoomStatusesItem.Value);
		EndIf;
	EndDo;
	
	// Build lists of room statuses and rooms used to filter rooms
	vRoomsList = New ValueList();
	If SelShowRoomsWithTasks Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	Messages.ByObject AS Room,
		|	Messages.Ref AS Recorder
		|FROM
		|	Document.Message AS Messages
		|WHERE
		|	Messages.Posted
		|	AND NOT Messages.IsClosed
		|	AND Messages.ByObject REFS Catalog.Rooms
		|	AND Messages.ByObject <> &qEmptyRoom
		|	AND Messages.ValidFromDate <= &qPeriod
		|	AND (Messages.ValidToDate > &qPeriod
		|			OR Messages.ValidToDate = &qEmptyDate)
		|
		|ORDER BY
		|	Messages.PointInTime DESC";
		vQry.SetParameter("qHotel", SelHotel);
		vQry.SetParameter("qEmptyRoom", Catalogs.Rooms.EmptyRef());
		vQry.SetParameter("qPeriod", CurrentSessionDate());
		vQry.SetParameter("qEmptyDate", '00010101');
		vRooms = vQry.Execute().Unload();
		vRoomsList.LoadValues(vRooms.UnloadColumn("Room"));
	ElsIf SelShowRoomsWithDiscrepancies Then
		vRoomsList = cmGetActiveRoomsList(SelHotel);
		vHotelGuests = GetRoomGuests(vRoomsList, CurrentSessionDate());
		vInd = 0;
		While vInd < vRoomsList.Count() Do
			vRoom = vRoomsList.Get(vInd).Value;
			vHotel = vRoom.Owner;
			vRoomGuests = vHotelGuests.FindRows(New Structure("Room", vRoom));
			vDiscrepancy = False;
			If vRoomGuests.Count() > 0 Then
				// There are in-house guests
				If vRoom.RoomStatus = vHotel.VacantRoomStatus And ValueIsFilled(vHotel.VacantRoomStatus) 
					Or ValueIsFilled(vRoom.RoomStatus) And vRoom.RoomStatus.RoomIsVacantClear 
					Or vRoom.RoomStatus = vHotel.OutOfOrderRoomStatus And ValueIsFilled(vHotel.OutOfOrderRoomStatus) 
					Or vRoom.RoomStatus = vHotel.RoomStatusAfterCheckOut And ValueIsFilled(vHotel.RoomStatusAfterCheckOut) 
					Or vRoom.RoomStatus = vHotel.RoomStatusAfterRoomBlock And ValueIsFilled(vHotel.RoomStatusAfterRoomBlock) 
					Or vRoom.RoomStatus = vHotel.RoomStatusInspection And ValueIsFilled(vHotel.RoomStatusInspection) 
					Or ValueIsFilled(vRoom.RoomStatus) And vRoom.RoomStatus.InspectionIsInProgress Then
					vDiscrepancy = True;
				EndIf;
			Else
				// Nobody at home :-)
				If vRoom.RoomStatus = vHotel.OccupiedRoomStatus And ValueIsFilled(vHotel.OccupiedRoomStatus) 
					Or vRoom.RoomStatus = vHotel.OccupiedDirtyRoomStatus And ValueIsFilled(vHotel.OccupiedDirtyRoomStatus) 
					Or vRoom.RoomStatus = vHotel.RoomStatusAfterEarlyCheckIn And ValueIsFilled(vHotel.RoomStatusAfterEarlyCheckIn) 
					Or vRoom.RoomStatus = vHotel.RoomStatusDueOut And ValueIsFilled(vHotel.RoomStatusDueOut) Then
					vDiscrepancy = True;
				EndIf;
			EndIf;
			If Not vDiscrepancy Then
				If vRoom.RoomStatus = vHotel.OutOfOrderRoomStatus And ValueIsFilled(vHotel.OutOfOrderRoomStatus) Then
					If Not vRoom.HasRoomBlocks Then
						vDiscrepancy = True;
					EndIf;
				EndIf;
			EndIf;
			If Not vDiscrepancy Then
				vRoomsList.Delete(vInd);
			Else
				vInd = vInd + 1;
			EndIf;
		EndDo;
	ElsIf SelShowVacantRooms Then
		vRoomsList = cmGetActiveRoomsList(SelHotel);
		vHotelGuests = GetRoomGuests(vRoomsList, CurrentSessionDate());
		vInd = 0;
		While vInd < vRoomsList.Count() Do
			vRoomGuests = vHotelGuests.FindRows(New Structure("Room", vRoomsList.Get(vInd).Value));
			If vRoomGuests.Count() > 0 Then
				vRoomsList.Delete(vInd);
			Else
				vInd = vInd + 1;
			EndIf;
		EndDo;
	ElsIf SelShowOccupiedRooms Then
		vRoomsList = cmGetActiveRoomsList(SelHotel);
		vHotelGuests = GetRoomGuests(vRoomsList, CurrentSessionDate());
		vInd = 0;
		While vInd < vRoomsList.Count() Do
			vRoomGuests = vHotelGuests.FindRows(New Structure("Room", vRoomsList.Get(vInd).Value));
			If vRoomGuests.Count() = 0 Then
				vRoomsList.Delete(vInd);
			Else
				vInd = vInd + 1;
			EndIf;
		EndDo;
	EndIf;
	
	// Build query to get all rooms
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomsStopSalePeriods.Ref AS Room
	|INTO StopSales
	|FROM
	|	Catalog.Rooms.StopSalePeriods AS RoomsStopSalePeriods
	|WHERE
	|	RoomsStopSalePeriods.StopSale
	|	AND RoomsStopSalePeriods.PeriodFrom < &qToday
	|	AND RoomsStopSalePeriods.PeriodTo > &qToday
	|	AND NOT RoomsStopSalePeriods.Ref.DeletionMark
	|	AND NOT RoomsStopSalePeriods.Ref.IsFolder
	|	AND (&qHotelsListIsEmpty
	|			OR NOT &qHotelsListIsEmpty
	|				AND RoomsStopSalePeriods.Ref.Owner IN (&qHotelsList))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Accommodations.Room AS Room,
	|	Accommodations.Customer AS Customer,
	|	Accommodations.ClientType AS ClientType,
	|	Accommodations.AccommodationTemplate AS AccommodationTemplate,
	|	Accommodations.BedsSetup AS BedsSetup,
	|	Accommodations.Number AS DocumentNumber,
	|	&qInHouseClause AS Clause,
	|	Accommodations.NumberOfAdults + Accommodations.NumberOfTeenagers + Accommodations.NumberOfChildren + Accommodations.NumberOfInfants AS NumberOfGuests
	|INTO InHouseGuests
	|FROM
	|	Document.Accommodation AS Accommodations
	|WHERE
	|	Accommodations.Posted
	|	AND Accommodations.AccommodationStatus.IsActive
	|	AND Accommodations.AccommodationStatus.IsInHouse
	|	AND (&qHotelsListIsEmpty
	|			OR NOT &qHotelsListIsEmpty
	|				AND Accommodations.Hotel IN (&qHotelsList))
	|	AND (&qParentIsEmpty
	|			OR NOT &qParentIsEmpty
	|				AND Accommodations.Room IN HIERARCHY (&qParent))
	|	AND (&qRoomTypesIsEmpty
	|			OR NOT &qRoomTypesIsEmpty
	|				AND Accommodations.RoomType IN (&qRoomTypesList))
	|	AND (&qRoomSectionIsEmpty
	|			OR NOT &qRoomSectionIsEmpty
	|				AND Accommodations.Room.RoomSection IN HIERARCHY (&qRoomSection))
	|	AND (&qRoomFloorIsEmpty
	|			OR NOT &qRoomFloorIsEmpty
	|				AND Accommodations.Room.Floor = &qRoomFloor)
	|	AND (&qRoomIsEmpty
	|			OR NOT &qRoomIsEmpty
	|				AND Accommodations.Room = &qRoom)
	|	AND Accommodations.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|
	|GROUP BY
	|	Accommodations.Room,
	|	Accommodations.Number,
	|	Accommodations.Customer,
	|	Accommodations.ClientType,
	|	Accommodations.AccommodationTemplate,
	|	Accommodations.BedsSetup,
	|	Accommodations.NumberOfAdults + Accommodations.NumberOfTeenagers + Accommodations.NumberOfChildren + Accommodations.NumberOfInfants
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Reservations.Room AS Room,
	|	Reservations.Number AS DocumentNumber,
	|	Reservations.Customer AS Customer,
	|	Reservations.ClientType AS ClientType,
	|	Reservations.AccommodationTemplate AS AccommodationTemplate,
	|	Reservations.BedsSetup AS BedsSetup,
	|	CAST(Reservations.Remarks AS STRING(999)) AS Remarks,
	|	CAST(Reservations.HousekeepingRemarks AS STRING(999)) AS HousekeepingRemarks,
	|	&qExpectedCheckInClause AS Clause,
	|	Reservations.NumberOfAdults + Reservations.NumberOfTeenagers + Reservations.NumberOfChildren + Reservations.NumberOfInfants AS NumberOfGuestsOnArrival
	|INTO ExpectedCheckInGuests
	|FROM
	|	Document.Reservation AS Reservations
	|WHERE
	|	Reservations.Posted
	|	AND (Reservations.ReservationStatus.IsActive
	|			OR Reservations.ReservationStatus.IsPreliminary)
	|	AND Reservations.CheckInDate >= &qBegOfToday
	|	AND Reservations.CheckInDate <= &qEndOfToday
	|	AND Reservations.Room <> VALUE(Catalog.Rooms.EmptyRef)
	|	AND (&qHotelsListIsEmpty
	|			OR NOT &qHotelsListIsEmpty
	|				AND Reservations.Hotel IN (&qHotelsList))
	|	AND (&qParentIsEmpty
	|			OR NOT &qParentIsEmpty
	|				AND Reservations.Room IN HIERARCHY (&qParent))
	|	AND (&qRoomTypesIsEmpty
	|			OR NOT &qRoomTypesIsEmpty
	|				AND Reservations.RoomType IN (&qRoomTypesList))
	|	AND (&qRoomSectionIsEmpty
	|			OR NOT &qRoomSectionIsEmpty
	|				AND Reservations.Room.RoomSection IN HIERARCHY (&qRoomSection))
	|	AND (&qRoomFloorIsEmpty
	|			OR NOT &qRoomFloorIsEmpty
	|				AND Reservations.Room.Floor = &qRoomFloor)
	|	AND (&qRoomIsEmpty
	|			OR NOT &qRoomIsEmpty
	|				AND Reservations.Room = &qRoom)
	|	AND Reservations.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|
	|GROUP BY
	|	Reservations.Room,
	|	Reservations.Number,
	|	Reservations.Customer,
	|	Reservations.ClientType,
	|	Reservations.AccommodationTemplate,
	|	Reservations.BedsSetup,
	|	CAST(Reservations.Remarks AS STRING(999)),
	|	CAST(Reservations.HousekeepingRemarks AS STRING(999)),
	|	Reservations.NumberOfAdults + Reservations.NumberOfTeenagers + Reservations.NumberOfChildren + Reservations.NumberOfInfants
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExpectedRoomMove.Room AS ToRoom,
	|	ExpectedRoomMove.Ref.Room AS FromRoom,
	|	ExpectedRoomMove.Ref.Number AS DocumentNumber,
	|	ExpectedRoomMove.Ref.Customer AS Customer,
	|	ExpectedRoomMove.Ref.ClientType AS ClientType,
	|	ExpectedRoomMove.Ref.AccommodationTemplate AS AccommodationTemplate,
	|	ExpectedRoomMove.Ref.BedsSetup AS BedsSetup,
	|	CAST(ExpectedRoomMove.Ref.Remarks AS STRING(999)) AS Remarks,
	|	CAST(ExpectedRoomMove.Ref.HousekeepingRemarks AS STRING(999)) AS HousekeepingRemarks,
	|	&qExpectedRoomMoveClause AS Clause,
	|	ExpectedRoomMove.Ref.NumberOfAdults + ExpectedRoomMove.Ref.NumberOfTeenagers + ExpectedRoomMove.Ref.NumberOfChildren + ExpectedRoomMove.Ref.NumberOfInfants AS NumberOfGuests
	|INTO ExpectedRoomMoveGuests
	|FROM
	|	Document.Accommodation.RoomRates AS ExpectedRoomMove
	|WHERE
	|	ExpectedRoomMove.Ref.Posted
	|	AND ExpectedRoomMove.Ref.AccommodationStatus.IsActive
	|	AND ExpectedRoomMove.Ref.AccommodationStatus.IsInHouse
	|	AND ExpectedRoomMove.Room <> VALUE(Catalog.Rooms.EmptyRef)
	|	AND ExpectedRoomMove.Room <> ExpectedRoomMove.Ref.Room
	|	AND ExpectedRoomMove.AccountingDate = &qBegOfToday
	|	AND (&qHotelsListIsEmpty
	|			OR NOT &qHotelsListIsEmpty
	|				AND ExpectedRoomMove.Ref.Hotel IN (&qHotelsList))
	|	AND (&qParentIsEmpty
	|			OR NOT &qParentIsEmpty
	|				AND ExpectedRoomMove.Ref.Room IN HIERARCHY (&qParent))
	|	AND (&qRoomTypesIsEmpty
	|			OR NOT &qRoomTypesIsEmpty
	|				AND ExpectedRoomMove.Ref.RoomType IN (&qRoomTypesList))
	|	AND (&qRoomSectionIsEmpty
	|			OR NOT &qRoomSectionIsEmpty
	|				AND ExpectedRoomMove.Ref.Room.RoomSection IN HIERARCHY (&qRoomSection))
	|	AND (&qRoomFloorIsEmpty
	|			OR NOT &qRoomFloorIsEmpty
	|				AND ExpectedRoomMove.Ref.Room.Floor = &qRoomFloor)
	|	AND (&qRoomIsEmpty
	|			OR NOT &qRoomIsEmpty
	|				AND ExpectedRoomMove.Ref.Room = &qRoom)
	|	AND ExpectedRoomMove.Ref.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|
	|GROUP BY
	|	ExpectedRoomMove.Room,
	|	ExpectedRoomMove.Ref.Room,
	|	ExpectedRoomMove.Ref.Number,
	|	ExpectedRoomMove.Ref.Customer,
	|	ExpectedRoomMove.Ref.ClientType,
	|	ExpectedRoomMove.Ref.AccommodationTemplate,
	|	ExpectedRoomMove.Ref.BedsSetup,
	|	CAST(ExpectedRoomMove.Ref.Remarks AS STRING(999)),
	|	CAST(ExpectedRoomMove.Ref.HousekeepingRemarks AS STRING(999)),
	|	ExpectedRoomMove.Ref.NumberOfAdults + ExpectedRoomMove.Ref.NumberOfTeenagers + ExpectedRoomMove.Ref.NumberOfChildren + ExpectedRoomMove.Ref.NumberOfInfants
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Accommodations.Room AS Room,
	|	Accommodations.Customer AS Customer,
	|	Accommodations.AccommodationTemplate AS AccommodationTemplate,
	|	&qExpectedCheckOutClause AS Clause,
	|	Accommodations.NumberOfAdults + Accommodations.NumberOfTeenagers + Accommodations.NumberOfChildren + Accommodations.NumberOfInfants AS NumberOfCheckOutGuests
	|INTO ExpectedCheckOutGuests
	|FROM
	|	Document.Accommodation AS Accommodations
	|WHERE
	|	Accommodations.Posted
	|	AND Accommodations.AccommodationStatus.IsActive
	|	AND Accommodations.AccommodationStatus.IsInHouse
	|	AND Accommodations.AccommodationStatus.IsCheckOut
	|	AND Accommodations.CheckOutDate >= &qBegOfToday
	|	AND Accommodations.CheckOutDate <= &qEndOfToday
	|	AND (&qHotelsListIsEmpty
	|			OR NOT &qHotelsListIsEmpty
	|				AND Accommodations.Hotel IN (&qHotelsList))
	|	AND (&qParentIsEmpty
	|			OR NOT &qParentIsEmpty
	|				AND Accommodations.Room IN HIERARCHY (&qParent))
	|	AND (&qRoomTypesIsEmpty
	|			OR NOT &qRoomTypesIsEmpty
	|				AND Accommodations.RoomType IN (&qRoomTypesList))
	|	AND (&qRoomSectionIsEmpty
	|			OR NOT &qRoomSectionIsEmpty
	|				AND Accommodations.Room.RoomSection IN HIERARCHY (&qRoomSection))
	|	AND (&qRoomFloorIsEmpty
	|			OR NOT &qRoomFloorIsEmpty
	|				AND Accommodations.Room.Floor = &qRoomFloor)
	|	AND (&qRoomIsEmpty
	|			OR NOT &qRoomIsEmpty
	|				AND Accommodations.Room = &qRoom)
	|	AND Accommodations.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|
	|GROUP BY
	|	Accommodations.Room,
	|	Accommodations.Customer,
	|	Accommodations.AccommodationTemplate,
	|	Accommodations.NumberOfAdults + Accommodations.NumberOfTeenagers + Accommodations.NumberOfChildren + Accommodations.NumberOfInfants
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Accommodations.Room AS Room,
	|	Accommodations.AccommodationTemplate AS AccommodationTemplate,
	|	&qCheckedOutClause AS Clause,
	|	Accommodations.NumberOfAdults + Accommodations.NumberOfTeenagers + Accommodations.NumberOfChildren + Accommodations.NumberOfInfants AS NumberOfCheckedOutGuests
	|INTO CheckedOutGuests
	|FROM
	|	Document.Accommodation AS Accommodations
	|WHERE
	|	Accommodations.Posted
	|	AND Accommodations.AccommodationStatus.IsActive
	|	AND NOT Accommodations.AccommodationStatus.IsInHouse
	|	AND Accommodations.AccommodationStatus.IsCheckOut
	|	AND Accommodations.CheckOutDate >= &qBegOfToday
	|	AND Accommodations.CheckOutDate <= &qEndOfToday
	|	AND (&qHotelsListIsEmpty
	|			OR NOT &qHotelsListIsEmpty
	|				AND Accommodations.Hotel IN (&qHotelsList))
	|	AND (&qParentIsEmpty
	|			OR NOT &qParentIsEmpty
	|				AND Accommodations.Room IN HIERARCHY (&qParent))
	|	AND (&qRoomTypesIsEmpty
	|			OR NOT &qRoomTypesIsEmpty
	|				AND Accommodations.RoomType IN (&qRoomTypesList))
	|	AND (&qRoomSectionIsEmpty
	|			OR NOT &qRoomSectionIsEmpty
	|				AND Accommodations.Room.RoomSection IN HIERARCHY (&qRoomSection))
	|	AND (&qRoomFloorIsEmpty
	|			OR NOT &qRoomFloorIsEmpty
	|				AND Accommodations.Room.Floor = &qRoomFloor)
	|	AND (&qRoomIsEmpty
	|			OR NOT &qRoomIsEmpty
	|				AND Accommodations.Room = &qRoom)
	|	AND Accommodations.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|
	|GROUP BY
	|	Accommodations.Room,
	|	Accommodations.AccommodationTemplate,
	|	Accommodations.NumberOfAdults + Accommodations.NumberOfTeenagers + Accommodations.NumberOfChildren + Accommodations.NumberOfInfants
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Accommodations.Room AS Room,
	|	Accommodations.Customer AS Customer,
	|	Accommodations.AccommodationTemplate AS AccommodationTemplate,
	|	CAST(Accommodations.Remarks AS STRING(999)) AS Remarks,
	|	CAST(Accommodations.HousekeepingRemarks AS STRING(999)) AS HousekeepingRemarks,
	|	&qCheckedInClause AS Clause,
	|	Accommodations.NumberOfAdults + Accommodations.NumberOfTeenagers + Accommodations.NumberOfChildren + Accommodations.NumberOfInfants AS NumberOfCheckedInGuests
	|INTO CheckedInGuests
	|FROM
	|	Document.Accommodation AS Accommodations
	|WHERE
	|	Accommodations.Posted
	|	AND Accommodations.AccommodationStatus.IsActive
	|	AND Accommodations.AccommodationStatus.IsInHouse
	|	AND Accommodations.AccommodationStatus.IsCheckIn
	|	AND Accommodations.CheckInDate >= &qBegOfToday
	|	AND Accommodations.CheckInDate <= &qEndOfToday
	|	AND (&qHotelsListIsEmpty
	|			OR NOT &qHotelsListIsEmpty
	|				AND Accommodations.Hotel IN (&qHotelsList))
	|	AND (&qParentIsEmpty
	|			OR NOT &qParentIsEmpty
	|				AND Accommodations.Room IN HIERARCHY (&qParent))
	|	AND (&qRoomTypesIsEmpty
	|			OR NOT &qRoomTypesIsEmpty
	|				AND Accommodations.RoomType IN (&qRoomTypesList))
	|	AND (&qRoomSectionIsEmpty
	|			OR NOT &qRoomSectionIsEmpty
	|				AND Accommodations.Room.RoomSection IN HIERARCHY (&qRoomSection))
	|	AND (&qRoomFloorIsEmpty
	|			OR NOT &qRoomFloorIsEmpty
	|				AND Accommodations.Room.Floor = &qRoomFloor)
	|	AND (&qRoomIsEmpty
	|			OR NOT &qRoomIsEmpty
	|				AND Accommodations.Room = &qRoom)
	|	AND Accommodations.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|
	|GROUP BY
	|	Accommodations.Room,
	|	Accommodations.Customer,
	|	Accommodations.AccommodationTemplate,
	|	CAST(Accommodations.Remarks AS STRING(999)),
	|	CAST(Accommodations.HousekeepingRemarks AS STRING(999)),
	|	Accommodations.NumberOfAdults + Accommodations.NumberOfTeenagers + Accommodations.NumberOfChildren + Accommodations.NumberOfInfants
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Messages.ByObject AS Room,
	|	CAST(Messages.Remarks AS STRING(999)) AS TaskRemarks
	|INTO RoomTasks
	|FROM
	|	Document.Message AS Messages
	|WHERE
	|	Messages.Posted
	|	AND NOT Messages.IsClosed
	|	AND Messages.ByObject REFS Catalog.Rooms
	|	AND (&qHotelsListIsEmpty
	|			OR NOT &qHotelsListIsEmpty
	|				AND Messages.ByObject.Owner IN (&qHotelsList))
	|	AND (Messages.ValidFromDate = &qEmptyDate
	|			OR Messages.ValidFromDate <> &qEmptyDate
	|				AND Messages.ValidFromDate <= &qToday)
	|	AND (Messages.ValidToDate = &qEmptyDate
	|			OR Messages.ValidToDate <> &qEmptyDate
	|				AND Messages.ValidToDate > &qToday)
	|
	|GROUP BY
	|	Messages.ByObject,
	|	CAST(Messages.Remarks AS STRING(999))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomBlocks.Room AS Room,
	|	RoomBlocks.RoomBlockType AS RoomBlockType,
	|	RoomBlocks.Number AS BlockNumber,
	|	CAST(RoomBlocks.Remarks AS STRING(999)) AS RoomBlockRemarks
	|INTO RoomBlocks
	|FROM
	|	Document.SetRoomBlock AS RoomBlocks
	|WHERE
	|	RoomBlocks.Posted
	|	AND (&qHotelsListIsEmpty
	|			OR NOT &qHotelsListIsEmpty
	|				AND RoomBlocks.Hotel IN (&qHotelsList))
	|	AND RoomBlocks.DateFrom <= &qToday
	|	AND (RoomBlocks.DateTo = &qEmptyDate
	|			OR RoomBlocks.DateTo <> &qEmptyDate
	|				AND RoomBlocks.DateTo > &qToday)
	|	AND (&qParentIsEmpty
	|			OR NOT &qParentIsEmpty
	|				AND RoomBlocks.Room IN HIERARCHY (&qParent))
	|	AND (&qRoomTypesIsEmpty
	|			OR NOT &qRoomTypesIsEmpty
	|				AND RoomBlocks.Room.RoomType IN (&qRoomTypesList))
	|	AND (&qRoomSectionIsEmpty
	|			OR NOT &qRoomSectionIsEmpty
	|				AND RoomBlocks.Room.RoomSection IN HIERARCHY (&qRoomSection))
	|	AND (&qRoomFloorIsEmpty
	|			OR NOT &qRoomFloorIsEmpty
	|				AND RoomBlocks.Room.Floor = &qRoomFloor)
	|	AND (&qRoomIsEmpty
	|			OR NOT &qRoomIsEmpty
	|				AND RoomBlocks.Room = &qRoom)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomProperties.Room AS Room,
	|	COUNT(RoomProperties.RoomProperty) AS RoomPropertyCount
	|INTO RoomPropertiesCounter
	|FROM
	|	InformationRegister.RoomProperties AS RoomProperties
	|WHERE
	|	(&qRoomPropertiesIsEmpty
	|			OR RoomProperties.RoomProperty IN (&qRoomProperty))
	|	AND (&qRoomIsEmpty
	|			OR NOT &qRoomIsEmpty
	|				AND RoomProperties.Room = &qRoom)
	|	AND (&qRoomsListIsEmpty
	|			OR NOT &qRoomsListIsEmpty
	|				AND RoomProperties.Room IN (&qRoomsList))
	|	AND (&qHotelsListIsEmpty
	|			OR NOT &qHotelsListIsEmpty
	|				AND RoomProperties.Room.Owner IN (&qHotelsList))
	|
	|GROUP BY
	|	RoomProperties.Room
	|
	|HAVING
	|	COUNT(RoomProperties.RoomProperty) = &qRoomPropertyCount
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	CASE
	|		WHEN Rooms.IsFolder
	|			THEN 6
	|		ELSE 7
	|	END AS Icon,
	|	Rooms.Description AS Description,
	|	Rooms.RoomType AS RoomType,
	|	Rooms.Floor AS Floor,
	|	Rooms.RoomStatus AS RoomStatus,
	|	CASE
	|		WHEN Rooms.Ref = ExpectedRoomMoveGuests.ToRoom
	|			THEN ISNULL(ExpectedCheckInGuests.NumberOfGuestsOnArrival, 0) + ISNULL(ExpectedRoomMoveGuests.NumberOfGuests, 0)
	|		ELSE ISNULL(ExpectedCheckInGuests.NumberOfGuestsOnArrival, 0)
	|	END AS NumberOfGuestsOnArrival,
	|	ISNULL(InHouseGuests.NumberOfGuests, 0) AS NumberOfGuests,
	|	RoomStatusChangeHistory.Period AS RoomStatusLastChangeTime,
	|	CAST(Rooms.Remarks AS STRING(999)) AS Remarks,
	|	RoomTasks.TaskRemarks AS TaskRemarks,
	|	CASE
	|		WHEN ISNULL(ExpectedCheckInGuests.Remarks, """") <> """"
	|			THEN ExpectedCheckInGuests.Remarks
	|		WHEN ISNULL(CheckedInGuests.Remarks, """") <> """"
	|			THEN CheckedInGuests.Remarks
	|		WHEN Rooms.Ref = ExpectedRoomMoveGuests.ToRoom
	|				AND ISNULL(ExpectedRoomMoveGuests.Remarks, """") <> """"
	|			THEN ExpectedRoomMoveGuests.Remarks
	|		ELSE """"
	|	END AS ReceptionRemarks,
	|	CASE
	|		WHEN ISNULL(ExpectedCheckInGuests.HousekeepingRemarks, """") <> """"
	|			THEN ExpectedCheckInGuests.HousekeepingRemarks
	|		WHEN ISNULL(CheckedInGuests.HousekeepingRemarks, """") <> """"
	|			THEN CheckedInGuests.HousekeepingRemarks
	|		WHEN Rooms.Ref = ExpectedRoomMoveGuests.ToRoom
	|				AND ISNULL(ExpectedRoomMoveGuests.HousekeepingRemarks, """") <> """"
	|			THEN ExpectedRoomMoveGuests.HousekeepingRemarks
	|		ELSE """"
	|	END AS HousekeepingRemarks,
	|	CASE
	|		WHEN ISNULL(ExpectedCheckInGuests.Customer, VALUE(Catalog.Customers.EmptyRef)) <> VALUE(Catalog.Customers.EmptyRef)
	|			THEN ExpectedCheckInGuests.Customer
	|		WHEN Rooms.Ref = ExpectedRoomMoveGuests.ToRoom
	|				AND ISNULL(ExpectedRoomMoveGuests.Customer, VALUE(Catalog.Customers.EmptyRef)) <> VALUE(Catalog.Customers.EmptyRef)
	|			THEN ExpectedRoomMoveGuests.Customer
	|		WHEN ISNULL(InHouseGuests.Customer, VALUE(Catalog.Customers.EmptyRef)) <> VALUE(Catalog.Customers.EmptyRef)
	|			THEN InHouseGuests.Customer
	|		ELSE NULL
	|	END AS Customer,
	|	CASE
	|		WHEN ISNULL(ExpectedCheckInGuests.ClientType, VALUE(Catalog.ClientTypes.EmptyRef)) <> VALUE(Catalog.ClientTypes.EmptyRef)
	|			THEN ExpectedCheckInGuests.ClientType
	|		WHEN Rooms.Ref = ExpectedRoomMoveGuests.ToRoom
	|				AND ISNULL(ExpectedRoomMoveGuests.ClientType, VALUE(Catalog.ClientTypes.EmptyRef)) <> VALUE(Catalog.ClientTypes.EmptyRef)
	|			THEN ExpectedRoomMoveGuests.ClientType
	|		WHEN ISNULL(InHouseGuests.ClientType, VALUE(Catalog.ClientTypes.EmptyRef)) <> VALUE(Catalog.ClientTypes.EmptyRef)
	|			THEN InHouseGuests.ClientType
	|		ELSE NULL
	|	END AS ClientType,
	|	CASE
	|		WHEN ISNULL(ExpectedCheckInGuests.ClientType, VALUE(Catalog.ClientTypes.EmptyRef)) <> VALUE(Catalog.ClientTypes.EmptyRef)
	|			THEN ExpectedCheckInGuests.ClientType.Description
	|		WHEN Rooms.Ref = ExpectedRoomMoveGuests.ToRoom
	|				AND ISNULL(ExpectedRoomMoveGuests.ClientType, VALUE(Catalog.ClientTypes.EmptyRef)) <> VALUE(Catalog.ClientTypes.EmptyRef)
	|			THEN ExpectedRoomMoveGuests.ClientType.Description
	|		WHEN ISNULL(InHouseGuests.ClientType, VALUE(Catalog.ClientTypes.EmptyRef)) <> VALUE(Catalog.ClientTypes.EmptyRef)
	|			THEN InHouseGuests.ClientType.Description
	|		ELSE """"
	|	END AS ClientTypeDescription,
	|	CASE
	|		WHEN ISNULL(ExpectedCheckInGuests.AccommodationTemplate, VALUE(Catalog.AccommodationTemplates.EmptyRef)) <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|			THEN ExpectedCheckInGuests.AccommodationTemplate
	|		WHEN Rooms.Ref = ExpectedRoomMoveGuests.ToRoom
	|				AND ISNULL(ExpectedRoomMoveGuests.AccommodationTemplate, VALUE(Catalog.AccommodationTemplates.EmptyRef)) <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|			THEN ExpectedRoomMoveGuests.AccommodationTemplate
	|		ELSE NULL
	|	END AS AccommodationTemplate,
	|	CASE
	|		WHEN ISNULL(ExpectedCheckInGuests.AccommodationTemplate, VALUE(Catalog.AccommodationTemplates.EmptyRef)) <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|			THEN ExpectedCheckInGuests.AccommodationTemplate.Description
	|		WHEN Rooms.Ref = ExpectedRoomMoveGuests.ToRoom
	|				AND ISNULL(ExpectedRoomMoveGuests.AccommodationTemplate, VALUE(Catalog.AccommodationTemplates.EmptyRef)) <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|			THEN ExpectedRoomMoveGuests.AccommodationTemplate.Description
	|		ELSE """"
	|	END AS AccommodationTemplateDescription,
	|	CASE
	|		WHEN ISNULL(ExpectedCheckInGuests.DocumentNumber, """") <> """"
	|			THEN ExpectedCheckInGuests.DocumentNumber
	|		WHEN Rooms.Ref = ExpectedRoomMoveGuests.ToRoom
	|				AND ISNULL(ExpectedRoomMoveGuests.DocumentNumber, """") <> """"
	|			THEN ExpectedRoomMoveGuests.DocumentNumber
	|		WHEN ISNULL(InHouseGuests.DocumentNumber, """") <> """"
	|			THEN InHouseGuests.DocumentNumber
	|		ELSE NULL
	|	END AS DocumentNumber,
	|	CASE
	|		WHEN ISNULL(ExpectedCheckInGuests.DocumentNumber, """") <> """"
	|			THEN ExpectedCheckInGuests.Clause
	|		WHEN Rooms.Ref = ExpectedRoomMoveGuests.ToRoom
	|				AND ISNULL(ExpectedRoomMoveGuests.DocumentNumber, """") <> """"
	|			THEN ExpectedRoomMoveGuests.Clause
	|		WHEN ISNULL(InHouseGuests.DocumentNumber, """") <> """"
	|			THEN InHouseGuests.Clause
	|		ELSE NULL
	|	END AS DocumentClause,
	|	Rooms.HasRoomBlocks AS HasRoomBlocks,
	|	RoomBlocks.RoomBlockType AS RoomBlockType,
	|	RoomBlocks.RoomBlockRemarks AS RoomBlockRemarks,
	|	Rooms.StopSale AS StopSale,
	|	Rooms.IsVirtual AS IsVirtual,
	|	Rooms.BedsSetup AS BedsSetup,
	|	CASE
	|		WHEN NOT ExpectedCheckInGuests.BedsSetup IS NULL
	|			THEN ExpectedCheckInGuests.BedsSetup
	|		WHEN Rooms.Ref = ExpectedRoomMoveGuests.ToRoom
	|				AND NOT ExpectedRoomMoveGuests.BedsSetup IS NULL
	|			THEN ExpectedRoomMoveGuests.BedsSetup
	|		WHEN NOT InHouseGuests.BedsSetup IS NULL
	|			THEN InHouseGuests.BedsSetup
	|		ELSE VALUE(Catalog.BedsSetups.EmptyRef)
	|	END AS BedsSetupInReservation,
	|	CAST(Rooms.RoomPropertiesCodes AS STRING(999)) AS RoomPropertiesCodes,
	|	"""" AS Condition,
	|	ExpectedCheckInGuests.Clause AS ExpectedCheckInClause,
	|	CheckedInGuests.Clause AS CheckedInClause,
	|	ExpectedRoomMoveGuests.Clause AS ExpectedRoomMoveClause,
	|	InHouseGuests.Clause AS InHouseClause,
	|	ExpectedCheckOutGuests.Clause AS ExpectedCheckOutClause,
	|	CheckedOutGuests.Clause AS CheckedOutClause,
	|	Rooms.SortCode AS SortCode,
	|	Rooms.IsFolder AS IsFolder,
	|	ExpectedRoomMoveGuests.FromRoom AS FromRoom,
	|	ExpectedRoomMoveGuests.ToRoom AS ToRoom,
	|	Rooms.Ref AS Ref,
	|	Rooms.Parent AS RoomParent
	|FROM
	|	Catalog.Rooms AS Rooms
	|		LEFT JOIN InformationRegister.RoomStatusChangeHistory.SliceLast(
	|				&qToday,
	|				&qHotelsListIsEmpty
	|					OR NOT &qHotelsListIsEmpty
	|						AND Room.Owner IN (&qHotelsList)) AS RoomStatusChangeHistory
	|		ON (RoomStatusChangeHistory.Room = Rooms.Ref)
	|		LEFT JOIN ExpectedCheckInGuests AS ExpectedCheckInGuests
	|		ON (ExpectedCheckInGuests.Room = Rooms.Ref)
	|		LEFT JOIN CheckedInGuests AS CheckedInGuests
	|		ON (CheckedInGuests.Room = Rooms.Ref)
	|		LEFT JOIN ExpectedRoomMoveGuests AS ExpectedRoomMoveGuests
	|		ON (ExpectedRoomMoveGuests.FromRoom = Rooms.Ref
	|				OR ExpectedRoomMoveGuests.ToRoom = Rooms.Ref)
	|		LEFT JOIN InHouseGuests AS InHouseGuests
	|		ON (InHouseGuests.Room = Rooms.Ref)
	|		LEFT JOIN ExpectedCheckOutGuests AS ExpectedCheckOutGuests
	|		ON (ExpectedCheckOutGuests.Room = Rooms.Ref)
	|		LEFT JOIN CheckedOutGuests AS CheckedOutGuests
	|		ON (CheckedOutGuests.Room = Rooms.Ref)
	|		LEFT JOIN RoomTasks AS RoomTasks
	|		ON (RoomTasks.Room = Rooms.Ref)
	|		LEFT JOIN RoomBlocks AS RoomBlocks
	|		ON (RoomBlocks.Room = Rooms.Ref)
	|		LEFT JOIN StopSales AS StopSales
	|		ON (StopSales.Room = Rooms.Ref)
	|WHERE
	|	NOT Rooms.DeletionMark
	|	AND Rooms.OperationStartDate < &qEndOfToday
	|	AND (Rooms.OperationEndDate = DATETIME(1, 1, 1)
	|			OR Rooms.OperationEndDate > &qBegOfToday)
	|	AND (&qHotelsListIsEmpty
	|			OR NOT &qHotelsListIsEmpty
	|				AND Rooms.Owner IN (&qHotelsList))
	|	AND (&qParentIsEmpty
	|			OR NOT &qParentIsEmpty
	|				AND Rooms.Ref IN HIERARCHY (&qParent))
	|	AND (&qRoomTypesIsEmpty
	|			OR NOT &qRoomTypesIsEmpty
	|				AND Rooms.RoomType IN (&qRoomTypesList))
	|	AND (&qRoomSectionIsEmpty
	|			OR NOT &qRoomSectionIsEmpty
	|				AND Rooms.RoomSection IN HIERARCHY (&qRoomSection))
	|	AND (&qRoomFloorIsEmpty
	|			OR NOT &qRoomFloorIsEmpty
	|				AND Rooms.Floor = &qRoomFloor)
	|	AND (&qBedsSetupIsEmpty
	|			OR NOT &qBedsSetupIsEmpty
	|				AND Rooms.BedsSetup = &qBedsSetup)
	|	AND (&qBedsSetupInReservationIsEmpty
	|			OR NOT &qBedsSetupInReservationIsEmpty
	|				AND CASE
	|					WHEN NOT ExpectedCheckInGuests.BedsSetup IS NULL
	|						THEN ExpectedCheckInGuests.BedsSetup
	|					WHEN Rooms.Ref = ExpectedRoomMoveGuests.ToRoom
	|							AND NOT ExpectedRoomMoveGuests.BedsSetup IS NULL
	|						THEN ExpectedRoomMoveGuests.BedsSetup
	|					WHEN NOT InHouseGuests.BedsSetup IS NULL
	|						THEN InHouseGuests.BedsSetup
	|					ELSE VALUE(Catalog.BedsSetups.EmptyRef)
	|				END = &qBedsSetupInReservation)
	|	AND (&qRoomIsEmpty
	|			OR NOT &qRoomIsEmpty
	|				AND Rooms.Ref = &qRoom)
	|	AND (&qRoomsListIsEmpty
	|			OR NOT &qRoomsListIsEmpty
	|				AND Rooms.Ref IN (&qRoomsList))
	|	AND Rooms.RoomStatus IN(&qRoomStatusesList)
	|	AND (NOT &qExpectedCheckInOnly
	|			OR &qExpectedCheckInOnly
	|				AND ExpectedCheckInGuests.NumberOfGuestsOnArrival > 0)
	|	AND (NOT &qCheckedInOnly
	|			OR &qCheckedInOnly
	|				AND CheckedInGuests.NumberOfCheckedInGuests > 0)
	|	AND (NOT &qExpectedCheckOutOnly
	|			OR &qExpectedCheckOutOnly
	|				AND ExpectedCheckOutGuests.NumberOfCheckOutGuests > 0)
	|	AND (NOT &qCheckedOutOnly
	|			OR &qCheckedOutOnly
	|				AND CheckedOutGuests.NumberOfCheckedOutGuests > 0)
	|	AND (NOT &qCheckedRoomBlock
	|			OR &qCheckedRoomBlock
	|				AND RoomBlocks.Room <> VALUE(Document.SetRoomBlock.EmptyRef))
	|	AND (NOT &qCheckedStopSales
	|			OR &qCheckedStopSales
	|				AND StopSales.Room <> VALUE(Catalog.Rooms.EmptyRef))
	|	AND (&qRoomPropertiesIsEmpty
	|			OR Rooms.Ref IN
	|				(SELECT
	|					RoomPropertiesCounter.Room
	|				FROM
	|					RoomPropertiesCounter AS RoomPropertiesCounter))
	|	AND (NOT &qShowRoomsWithBedsSetupDiscrepancies
	|			OR &qShowRoomsWithBedsSetupDiscrepancies
	|				AND Rooms.BedsSetup <> CASE
	|					WHEN NOT ExpectedCheckInGuests.BedsSetup IS NULL
	|						THEN ExpectedCheckInGuests.BedsSetup
	|					WHEN Rooms.Ref = ExpectedRoomMoveGuests.ToRoom
	|							AND NOT ExpectedRoomMoveGuests.BedsSetup IS NULL
	|						THEN ExpectedRoomMoveGuests.BedsSetup
	|					WHEN NOT InHouseGuests.BedsSetup IS NULL
	|						THEN InHouseGuests.BedsSetup
	|					ELSE VALUE(Catalog.BedsSetups.EmptyRef)
	|				END
	|				AND CASE
	|					WHEN NOT ExpectedCheckInGuests.BedsSetup IS NULL
	|						THEN ExpectedCheckInGuests.BedsSetup
	|					WHEN Rooms.Ref = ExpectedRoomMoveGuests.ToRoom
	|							AND NOT ExpectedRoomMoveGuests.BedsSetup IS NULL
	|						THEN ExpectedRoomMoveGuests.BedsSetup
	|					WHEN NOT InHouseGuests.BedsSetup IS NULL
	|						THEN InHouseGuests.BedsSetup
	|					ELSE VALUE(Catalog.BedsSetups.EmptyRef)
	|				END <> VALUE(Catalog.BedsSetups.EmptyRef))
	|
	|ORDER BY
	|	Rooms.Owner.SortCode,
	|	Rooms.Owner.Code,
	|	Rooms.SortCode,
	|	HousekeepingRemarks DESC,
	|	ClientTypeDescription DESC,
	|	NumberOfGuestsOnArrival DESC,
	|	NumberOfGuests DESC";
	vQry.SetParameter("qHotelsListIsEmpty", ?(vHotelsList.Count() > 0, False, True));
	vQry.SetParameter("qHotelsList", vHotelsList);
	vQry.SetParameter("qToday", CurrentSessionDate());
	vQry.SetParameter("qBegOfToday", BegOfDay(CurrentSessionDate()));
	vQry.SetParameter("qEndOfToday", EndOfDay(CurrentSessionDate()));
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qParentIsEmpty", Not ValueIsFilled(SelRoomsFolder));
	vQry.SetParameter("qParent", SelRoomsFolder);
	vQry.SetParameter("qRoomTypesIsEmpty", ?(SelRoomTypes.Count() <> 0, False, True));
	vQry.SetParameter("qRoomTypesList", SelRoomTypes);
	vQry.SetParameter("qRoomSectionIsEmpty", Not ValueIsFilled(SelRoomSection));
	vQry.SetParameter("qRoomSection", SelRoomSection);
	vQry.SetParameter("qRoomIsEmpty", Not ValueIsFilled(SelRoom));
	vQry.SetParameter("qRoom", SelRoom);
	vQry.SetParameter("qRoomFloorIsEmpty", IsBlankString(SelFloor));
	vQry.SetParameter("qRoomFloor", TrimAll(SelFloor));
	vQry.SetParameter("qRoomStatusesList", vStatusesList);
	vQry.SetParameter("qExpectedCheckInOnly", SelShowPlannedCheckIn);
	vQry.SetParameter("qCheckedInOnly", SelShowCheckedIn);
	vQry.SetParameter("qCheckedOutOnly", SelShowCheckedOut);
	vQry.SetParameter("qExpectedCheckOutOnly", SelShowPlannedCheckOut);
	vQry.SetParameter("qCheckedRoomBlock", SelShowRoomsBlock);
	vQry.SetParameter("qCheckedStopSales", SelShowRoomsStopSale);
	vQry.SetParameter("qRoomPropertiesIsEmpty", SelRoomProperties.Count() = 0);
	vQry.SetParameter("qRoomProperty", SelRoomProperties);
	vQry.SetParameter("qRoomPropertyCount", SelRoomProperties.Count());
	vQry.SetParameter("qBedsSetupIsEmpty", Not ValueIsFilled(SelBedsSetup));
	vQry.SetParameter("qBedsSetup", SelBedsSetup);
	vQry.SetParameter("qBedsSetupInReservationIsEmpty", Not ValueIsFilled(SelBedsSetupInReservation));
	vQry.SetParameter("qBedsSetupInReservation", SelBedsSetupInReservation);

	If SelShowRoomsWithTasks Or SelShowRoomsWithDiscrepancies Then
		vQry.SetParameter("qRoomsListIsEmpty", False);
	Else
		vQry.SetParameter("qRoomsListIsEmpty", ?(vRoomsList.Count() > 0, False, True));
	EndIf;
	vQry.SetParameter("qRoomsList", vRoomsList);
	vQry.SetParameter("qExpectedCheckInClause", NStr("en = 'Arrival today'; de = 'Anreise heute'; ru = 'На заезде'"));
	vQry.SetParameter("qCheckedInClause", NStr("en = 'Checked-in'; de = 'Checked-in'; ru = 'Заехал'"));
	vQry.SetParameter("qInHouseClause", NStr("en = 'In house'; de = 'In house'; ru = 'Занят'"));
	vQry.SetParameter("qExpectedCheckOutClause", NStr("en = 'Departure today'; de = 'Abreise heute'; ru = 'На выезде'"));
	vQry.SetParameter("qCheckedOutClause", NStr("en = 'Checked-out'; de = 'Checked-out'; ru = 'Выехал'"));
	vQry.SetParameter("qExpectedRoomMoveClause", NStr("en = 'Moving'; de = 'Umzug'; ru = 'Переселение'"));
	vQry.SetParameter("qShowRoomsWithBedsSetupDiscrepancies", SelShowRoomsWithBedsSetupDiscrepancies);
	
	vRooms = vQry.Execute().Unload();
	
	vVacantClause = NStr("en = 'Vacant'; de = 'Leer'; ru = 'Свободен'");
	
	// Initialize table of total rooms by room statuses
	vRoomStatusesTotals = New ValueTable();
	vRoomStatusesTotals.Columns.Add("RoomStatus", cmGetCatalogTypeDescription("RoomStatuses"));
	vRoomStatusesTotals.Columns.Add("Quantity", cmGetNumberTypeDescription(6, 0));
	
	// Fill form table
	vParents = New ValueTable();
	vParents.Columns.Add("Item");
	vParents.Columns.Add("Ref");
	
	// Get regular operations
	vRegOprQry = New Query();
	vRegOprQry.Text = 
	"SELECT
	|	Hotels.Ref AS Hotel,
	|	Hotels.RegularOperationGroup AS RegularOperationGroup
	|INTO HotelsWithRegularOperations
	|FROM
	|	Catalog.Hotels AS Hotels
	|WHERE
	|	CASE
	|			WHEN &qHotelsListIsEmpty
	|				THEN TRUE
	|			ELSE Hotels.Ref IN (&qHotelsList)
	|		END
	|	AND NOT Hotels.DeletionMark
	|	AND NOT Hotels.IsFolder
	|	AND Hotels.RegularOperationGroup <> VALUE(Catalog.RegularOperationGroups.EmptyRef)
	|
	|INDEX BY
	|	Hotel
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomTypes.Ref AS RoomType,
	|	RoomTypes.Parent AS RoomTypeParent
	|INTO RoomTypesList
	|FROM
	|	Catalog.RoomTypes AS RoomTypes
	|		INNER JOIN HotelsWithRegularOperations AS HotelsWithRegularOperations
	|		ON (HotelsWithRegularOperations.Hotel = RoomTypes.Owner)
	|WHERE
	|	NOT RoomTypes.IsFolder
	|	AND NOT RoomTypes.DeletionMark
	|	AND CASE
	|			WHEN &qRoomTypesIsEmpty
	|				THEN TRUE
	|			ELSE RoomTypes.Ref IN (&qRoomTypesList)
	|		END
	|
	|INDEX BY
	|	RoomType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Rooms.Ref AS Room,
	|	RoomTypesList.RoomTypeParent AS RoomTypeParent
	|INTO RoomsList
	|FROM
	|	Catalog.Rooms AS Rooms
	|		INNER JOIN HotelsWithRegularOperations AS HotelsWithRegularOperations
	|		ON (HotelsWithRegularOperations.Hotel = Rooms.Owner)
	|		INNER JOIN RoomTypesList AS RoomTypesList
	|		ON Rooms.RoomType = RoomTypesList.RoomType
	|WHERE
	|	NOT Rooms.IsFolder
	|	AND NOT Rooms.DeletionMark
	|	AND CASE
	|			WHEN &qParentIsEmpty
	|				THEN TRUE
	|			ELSE Rooms.Ref IN HIERARCHY (&qParent)
	|		END
	|	AND CASE
	|			WHEN &qRoomSectionIsEmpty
	|				THEN TRUE
	|			ELSE Rooms.RoomSection IN HIERARCHY (&qRoomSection)
	|		END
	|	AND CASE
	|			WHEN &qRoomIsEmpty
	|				THEN TRUE
	|			ELSE Rooms.Ref = &qRoom
	|		END
	|	AND CASE
	|			WHEN &qRoomFloorIsEmpty
	|				THEN TRUE
	|			ELSE Rooms.Floor = &qRoomFloor
	|		END
	|	AND CASE
	|			WHEN &qBedsSetupIsEmpty
	|				THEN TRUE
	|			ELSE Rooms.BedsSetup = &qBedsSetup
	|		END
	|	AND CASE
	|			WHEN &qBedsSetupIsEmpty
	|				THEN TRUE
	|			ELSE Rooms.BedsSetup = &qBedsSetup
	|		END
	|	AND Rooms.RoomStatus IN(&qRoomStatusesList)
	|	AND CASE
	|			WHEN &qRoomsListIsEmpty
	|				THEN TRUE
	|			ELSE Rooms.Ref IN (&qRoomsList)
	|		END
	|
	|INDEX BY
	|	Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventoryBalance.Hotel AS Hotel,
	|	RoomInventoryBalance.Room AS Room,
	|	RoomInventoryBalance.RoomType AS RoomType,
	|	RoomsList.RoomTypeParent AS RoomTypeParent,
	|	RoomInventoryBalance.TotalBedsBalance AS TotalBedsBalance
	|INTO RoomInventoryBalance
	|FROM
	|	AccumulationRegister.RoomInventory.Balance(
	|			&qEndOfToday,
	|			Room IN
	|				(SELECT
	|					RoomsList.Room
	|				FROM
	|					RoomsList AS RoomsList)) AS RoomInventoryBalance
	|		INNER JOIN RoomsList AS RoomsList
	|		ON RoomInventoryBalance.Room = RoomsList.Room
	|WHERE
	|	RoomInventoryBalance.TotalBedsBalance > 0
	|
	|INDEX BY
	|	Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InHousePersons.Room AS Room,
	|	InHousePersons.PeriodFrom AS InHousePersonsPeriodFrom,
	|	InHousePersons.PeriodTo AS InHousePersonsPeriodTo,
	|	InHousePersons.Recorder AS InHousePersonsRecorder,
	|	RoomRates.Ref AS InHousePersonsRecorderRoomRate,
	|	RoomRates.Parent AS InHousePersonsRecorderRoomRateParent,
	|	RoomRates.Parent.Parent AS InHousePersonsRecorderRoomRateParentParent
	|INTO InHousePersons
	|FROM
	|	AccumulationRegister.RoomInventory AS InHousePersons
	|		INNER JOIN RoomsList AS RoomsList
	|		ON InHousePersons.Room = RoomsList.Room
	|		LEFT JOIN Catalog.RoomRates AS RoomRates
	|		ON (CAST(InHousePersons.Recorder AS Document.Accommodation).RoomRate = RoomRates.Ref)
	|WHERE
	|	InHousePersons.RecordType = &qExpense
	|	AND InHousePersons.Recorder REFS Document.Accommodation
	|	AND InHousePersons.IsInHouse
	|	AND InHousePersons.CheckInDate < &qBegOfToday
	|	AND InHousePersons.CheckOutDate > &qEndOfToday
	|	AND InHousePersons.PeriodFrom < &qBegOfToday
	|	AND InHousePersons.PeriodTo > &qEndOfToday
	|	AND InHousePersons.Period = InHousePersons.PeriodFrom
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CheckedOutGuests.Room AS Room,
	|	CheckedOutGuests.Recorder AS CheckedOutGuestsRecorder
	|INTO CheckedOutGuests
	|FROM
	|	AccumulationRegister.RoomInventory AS CheckedOutGuests
	|		INNER JOIN RoomsList AS RoomsList
	|		ON CheckedOutGuests.Room = RoomsList.Room
	|WHERE
	|	CheckedOutGuests.RecordType = &qReceipt
	|	AND CheckedOutGuests.Recorder REFS Document.Accommodation
	|	AND CheckedOutGuests.IsCheckOut
	|	AND CheckedOutGuests.Period = CheckedOutGuests.PeriodTo
	|	AND CheckedOutGuests.PeriodTo = CheckedOutGuests.CheckOutDate
	|	AND CheckedOutGuests.PeriodTo BETWEEN &qBegOfToday AND &qEndOfToday
	|
	|INDEX BY
	|	Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CheckedInPersons.Room AS Room,
	|	CheckedInPersons.Recorder AS CheckedInPersonsRecorder
	|INTO CheckedInPersons
	|FROM
	|	AccumulationRegister.RoomInventory AS CheckedInPersons
	|		INNER JOIN RoomsList AS RoomsList
	|		ON CheckedInPersons.Room = RoomsList.Room
	|WHERE
	|	CheckedInPersons.RecordType = &qExpense
	|	AND CheckedInPersons.Recorder REFS Document.Accommodation
	|	AND CheckedInPersons.IsInHouse
	|	AND CheckedInPersons.Period = CheckedInPersons.PeriodFrom
	|	AND CheckedInPersons.PeriodFrom = CheckedInPersons.CheckInDate
	|	AND CheckedInPersons.PeriodFrom BETWEEN &qBegOfToday AND &qEndOfToday
	|
	|INDEX BY
	|	Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventoryLastCheckedOutGuests.Room AS Room,
	|	MAX(RoomInventoryLastCheckedOutGuests.PeriodTo) AS LastCheckOutDate
	|INTO LastCheckedOutGuests
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventoryLastCheckedOutGuests
	|		INNER JOIN RoomsList AS RoomsList
	|		ON RoomInventoryLastCheckedOutGuests.Room = RoomsList.Room
	|WHERE
	|	RoomInventoryLastCheckedOutGuests.RecordType = &qReceipt
	|	AND RoomInventoryLastCheckedOutGuests.Recorder REFS Document.Accommodation
	|	AND RoomInventoryLastCheckedOutGuests.IsCheckOut
	|	AND RoomInventoryLastCheckedOutGuests.CheckOutDate BETWEEN &qMaxCheckOutDate AND &qBegOfToday
	|
	|GROUP BY
	|	RoomInventoryLastCheckedOutGuests.Room
	|
	|INDEX BY
	|	Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventoryBalance.Hotel AS Hotel,
	|	RoomInventoryBalance.Room AS Room,
	|	RoomInventoryBalance.RoomType AS RoomType,
	|	RoomInventoryBalance.RoomTypeParent AS RoomTypeParent,
	|	RoomInventoryBalance.TotalBedsBalance AS TotalBedsBalance,
	|	InHousePersons.InHousePersonsPeriodFrom AS InHousePersonsPeriodFrom,
	|	InHousePersons.InHousePersonsPeriodTo AS InHousePersonsPeriodTo,
	|	InHousePersons.InHousePersonsRecorder AS InHousePersonsRecorder,
	|	InHousePersons.InHousePersonsRecorderRoomRate AS InHousePersonsRecorderRoomRate,
	|	InHousePersons.InHousePersonsRecorderRoomRateParent AS InHousePersonsRecorderRoomRateParent,
	|	InHousePersons.InHousePersonsRecorderRoomRateParentParent AS InHousePersonsRecorderRoomRateParentParent,
	|	CheckedOutGuests.CheckedOutGuestsRecorder AS CheckedOutGuestsRecorder,
	|	CheckedInPersons.CheckedInPersonsRecorder AS CheckedInPersonsRecorder,
	|	LastCheckedOutGuests.LastCheckOutDate AS LastCheckedOutGuestsLastCheckOutDate
	|INTO DraftRoomsList
	|FROM
	|	RoomInventoryBalance AS RoomInventoryBalance
	|		LEFT JOIN InHousePersons AS InHousePersons
	|		ON RoomInventoryBalance.Room = InHousePersons.Room
	|		LEFT JOIN CheckedOutGuests AS CheckedOutGuests
	|		ON RoomInventoryBalance.Room = CheckedOutGuests.Room
	|		LEFT JOIN CheckedInPersons AS CheckedInPersons
	|		ON RoomInventoryBalance.Room = CheckedInPersons.Room
	|		LEFT JOIN LastCheckedOutGuests AS LastCheckedOutGuests
	|		ON RoomInventoryBalance.Room = LastCheckedOutGuests.Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DraftRoomsList.Hotel AS Hotel,
	|	DraftRoomsList.Room AS Room,
	|	DraftRoomsList.TotalBedsBalance AS TotalBedsBalance,
	|	HotelsWithRegularOperations.RegularOperationGroup AS RegularOperationGroup,
	|	RegularOperations.RegularOperation AS RegularOperation,
	|	RegularOperations.RegularOperation.Code AS RegularOperationCode,
	|	CASE
	|		WHEN RegularOperations.RegularOperation IS NOT NULL 
	|			THEN RegularOperations.RegularOperation.SortCode
	|		ELSE 999999
	|	END AS RegularOperationSortCode
	|FROM
	|	DraftRoomsList AS DraftRoomsList
	|		INNER JOIN HotelsWithRegularOperations AS HotelsWithRegularOperations
	|		ON DraftRoomsList.Hotel = HotelsWithRegularOperations.Hotel
	|		LEFT JOIN Catalog.RegularOperationGroups.RegularOperations AS RegularOperations
	|		ON (RegularOperations.Ref = HotelsWithRegularOperations.RegularOperationGroup)
	|			AND (RegularOperations.PerformWhenRoomIsBusy
	|					AND DATEDIFF(&qBegOfToday, BEGINOFPERIOD(DraftRoomsList.InHousePersonsPeriodFrom, DAY), DAY) / RegularOperations.RegularOperationFrequency = (CAST(DATEDIFF(&qBegOfToday, BEGINOFPERIOD(DraftRoomsList.InHousePersonsPeriodFrom, DAY), DAY) / RegularOperations.RegularOperationFrequency AS NUMBER(17, 0)))
	|					AND DATEDIFF(&qBegOfToday, BEGINOFPERIOD(DraftRoomsList.InHousePersonsPeriodFrom, DAY), DAY) <> 0
	|				OR RegularOperations.PerformWhenRoomIsBusy
	|					AND RegularOperations.PerformOnCheckInDay
	|					AND DraftRoomsList.CheckedInPersonsRecorder IS NOT NULL 
	|				OR RegularOperations.PerformWhenRoomIsBusy
	|					AND RegularOperations.PerformOnCheckOutDay
	|					AND DraftRoomsList.CheckedOutGuestsRecorder IS NOT NULL 
	|				OR RegularOperations.PerformWhenRoomIsFree
	|					AND DraftRoomsList.InHousePersonsRecorder IS NULL
	|					AND DraftRoomsList.CheckedInPersonsRecorder IS NULL
	|					AND DraftRoomsList.CheckedOutGuestsRecorder IS NULL
	|					AND (RegularOperations.RegularOperationFrequency = 0
	|						OR RegularOperations.RegularOperationFrequency = 1
	|						OR RegularOperations.RegularOperationFrequency > 1
	|							AND DATEDIFF(&qBegOfToday, BEGINOFPERIOD(DraftRoomsList.LastCheckedOutGuestsLastCheckOutDate, DAY), DAY) / RegularOperations.RegularOperationFrequency = (CAST(DATEDIFF(&qBegOfToday, BEGINOFPERIOD(DraftRoomsList.LastCheckedOutGuestsLastCheckOutDate, DAY), DAY) / RegularOperations.RegularOperationFrequency AS NUMBER(17, 0)))
	|							AND DATEDIFF(&qBegOfToday, BEGINOFPERIOD(DraftRoomsList.LastCheckedOutGuestsLastCheckOutDate, DAY), DAY) <> 0))
	|			AND (NOT RegularOperations.DoNotPerformOnWeekends
	|				OR RegularOperations.DoNotPerformOnWeekends
	|					AND WEEKDAY(&qBegOfToday) < 6)
	|			AND (RegularOperations.RoomType = &qEmptyRoomType
	|				OR RegularOperations.RoomType <> &qEmptyRoomType
	|					AND DraftRoomsList.RoomType = RegularOperations.RoomType
	|				OR RegularOperations.RoomType <> &qEmptyRoomType
	|					AND DraftRoomsList.RoomTypeParent <> &qEmptyRoomType
	|					AND DraftRoomsList.RoomTypeParent = RegularOperations.RoomType)
	|			AND (RegularOperations.RoomRate = &qEmptyRoomRate
	|				OR RegularOperations.RoomRate <> &qEmptyRoomRate
	|					AND NOT DraftRoomsList.InHousePersonsRecorderRoomRate IS NULL
	|					AND DraftRoomsList.InHousePersonsRecorderRoomRate <> &qEmptyRoomRate
	|					AND (DraftRoomsList.InHousePersonsRecorderRoomRate = RegularOperations.RoomRate
	|						OR DraftRoomsList.InHousePersonsRecorderRoomRateParent = RegularOperations.RoomRate
	|						OR DraftRoomsList.InHousePersonsRecorderRoomRateParentParent = RegularOperations.RoomRate))
	|WHERE
	|	RegularOperations.RegularOperation <> VALUE(Catalog.Operations.EmptyRef)
	|
	|ORDER BY
	|	RegularOperationSortCode";
	vCurDate = CurrentSessionDate();
	vRegOprQry.SetParameter("qMaxCheckOutDate", BegOfDay(vCurDate) - (10 * 24 * 3600));
	vRegOprQry.SetParameter("qBegOfToday", BegOfDay(vCurDate));
	vRegOprQry.SetParameter("qEndOfToday", EndOfDay(vCurDate));
	vRegOprQry.SetParameter("qHotelsListIsEmpty", ?(vHotelsList.Count() > 0, False, True));
	vRegOprQry.SetParameter("qHotelsList", vHotelsList);
	vRegOprQry.SetParameter("qParentIsEmpty", Not ValueIsFilled(SelRoomsFolder));
	vRegOprQry.SetParameter("qParent", SelRoomsFolder);
	vRegOprQry.SetParameter("qRoomTypesIsEmpty", ?(SelRoomTypes.Count() <> 0, False, True));
	vRegOprQry.SetParameter("qRoomTypesList", SelRoomTypes);
	vRegOprQry.SetParameter("qEmptyRoomType", Catalogs.RoomTypes.EmptyRef());
	vRegOprQry.SetParameter("qEmptyRoomRate", Catalogs.RoomRates.EmptyRef());
	vRegOprQry.SetParameter("qRoomSectionIsEmpty", Not ValueIsFilled(SelRoomSection));
	vRegOprQry.SetParameter("qRoomSection", SelRoomSection);
	vRegOprQry.SetParameter("qRoomIsEmpty", Not ValueIsFilled(SelRoom));
	vRegOprQry.SetParameter("qRoom", SelRoom);
	vRegOprQry.SetParameter("qRoomFloorIsEmpty", IsBlankString(SelFloor));
	vRegOprQry.SetParameter("qRoomFloor", TrimAll(SelFloor));
	vRegOprQry.SetParameter("qRoomStatusesList", vStatusesList);
	If SelShowRoomsWithTasks Or SelShowRoomsWithDiscrepancies Then
		vRegOprQry.SetParameter("qRoomsListIsEmpty", False);
	Else
		vRegOprQry.SetParameter("qRoomsListIsEmpty", ?(vRoomsList.Count() > 0, False, True));
	EndIf;
	vRegOprQry.SetParameter("qRoomsList", vRoomsList);
	vRegOprQry.SetParameter("qExpense", AccumulationRecordType.Expense);
	vRegOprQry.SetParameter("qReceipt", AccumulationRecordType.Receipt);
	vRegOprQry.SetParameter("qBedsSetupIsEmpty", Not ValueIsFilled(SelBedsSetup));
	vRegOprQry.SetParameter("qBedsSetup", SelBedsSetup);

	vRegularOperations = vRegOprQry.Execute().Unload();
		
	TableBoxRooms.GetItems().Clear();
	TotalRoomsInList = 0;
	
	vCurParent = Undefined;
	vCurRoom = Undefined;
	For Each vRoomsRow In vRooms Do
		If Not vRoomsRow.IsFolder Then
			vRegularOperationsRows = vRegularOperations.FindRows(New Structure("Room", vRoomsRow.Ref));
			If SelShowRegularOperations And vRegularOperationsRows.Count() = 0 Then
				Continue;
			EndIf;
		EndIf;
		
		vDoAddRoom = True;
		If vCurRoom = vRoomsRow.Ref Then
			vDoAddRoom = False;
			If vRoomsRow.IsFolder Then
				Continue;
			EndIf;
		EndIf;
		
		vCurRoom = vRoomsRow.Ref;
		vRoomParent = vRoomsRow.RoomParent;
		If ValueIsFilled(vRoomParent) Then
			vParentsRow = vParents.Find(vRoomParent, "Ref");
			If vParentsRow = Undefined Then
				vCurFolderItem = TableBoxRooms;
			Else
				vCurFolderItem = vParentsRow.Item;
			EndIf;
		Else
			vCurFolderItem = TableBoxRooms;
		EndIf;
		
		If vCurParent <> vRoomParent Then
			vCurParent = vRoomParent;
			If ValueIsFilled(vCurParent) Then
	 			vCurFolderItem = vCurFolderItem.GetItems().Add();
				FillPropertyValues(vCurFolderItem, vCurParent, "Description, IsFolder, Ref");
				vCurFolderItem.Icon = 6;
				vCurFolderItem.RoomStatusIcon = 5;
				
				vParentsRow = vParents.Add();
				vParentsRow.Ref = vCurParent;
				vParentsRow.Item = vCurFolderItem;
			EndIf;
		EndIf;
		
		If vDoAddRoom Then
			vCurRoomItem = vCurFolderItem.GetItems().Add();
			TotalRoomsInList = TotalRoomsInList + 1;
			FillPropertyValues(vCurRoomItem, vRoomsRow, , "NumberOfGuests, NumberOfGuestsOnArrival, Remarks");
			vCurRoomItem.RoomStatusIcon = GetRoomStatusIconIndex(vCurRoomItem.RoomStatus);
			vCurRoomItem.NumberOfGuests = vCurRoomItem.NumberOfGuests + vRoomsRow.NumberOfGuests;
			vCurRoomItem.NumberOfGuestsOnArrival = vCurRoomItem.NumberOfGuestsOnArrival + vRoomsRow.NumberOfGuestsOnArrival;
		EndIf;
		
		If Not IsBlankString(vRoomsRow.AccommodationTemplateDescription) Then
			If StrFind(vCurRoomItem.Remarks, vRoomsRow.AccommodationTemplateDescription) = 0 Then
				vCurRoomItem.Remarks = vCurRoomItem.Remarks + ?(IsBlankString(vCurRoomItem.Remarks), "", Chars.LF) + vRoomsRow.AccommodationTemplateDescription;
			EndIf;
		EndIf;
		If Not IsBlankString(vRoomsRow.ClientTypeDescription) Then
			If StrFind(vCurRoomItem.Remarks, vRoomsRow.ClientTypeDescription) = 0 Then
				vCurRoomItem.Remarks = vCurRoomItem.Remarks + ?(IsBlankString(vCurRoomItem.Remarks), "", Chars.LF) + vRoomsRow.ClientTypeDescription;
			EndIf;
		EndIf;
		If Not IsBlankString(vRoomsRow.HousekeepingRemarks) Then
			If StrFind(vCurRoomItem.Remarks, vRoomsRow.HousekeepingRemarks) = 0 Then
				vCurRoomItem.Remarks = vCurRoomItem.Remarks + ?(IsBlankString(vCurRoomItem.Remarks), "", Chars.LF) + vRoomsRow.HousekeepingRemarks;
			EndIf;
		EndIf;
		If Not IsBlankString(vRoomsRow.ReceptionRemarks) Then
			If StrFind(vCurRoomItem.Remarks, vRoomsRow.ReceptionRemarks) = 0 Then
				vCurRoomItem.Remarks = vCurRoomItem.Remarks + ?(IsBlankString(vCurRoomItem.Remarks), "", Chars.LF) + vRoomsRow.ReceptionRemarks;
			EndIf;
		EndIf;
		If Not IsBlankString(vRoomsRow.RoomBlockRemarks) Then
			If StrFind(vCurRoomItem.Remarks, vRoomsRow.RoomBlockRemarks) = 0 Then
				vCurRoomItem.Remarks = vCurRoomItem.Remarks + ?(IsBlankString(vCurRoomItem.Remarks), "", Chars.LF) + vRoomsRow.RoomBlockRemarks;
			EndIf;
		EndIf;
		If Not IsBlankString(vRoomsRow.Remarks) Then
			If StrFind(vCurRoomItem.Remarks, vRoomsRow.Remarks) = 0 Then
				vCurRoomItem.Remarks = vCurRoomItem.Remarks + ?(IsBlankString(vCurRoomItem.Remarks), "", Chars.LF) + vRoomsRow.Remarks;
			EndIf;
		EndIf;
		vIsVacant = True;
		If Not IsBlankString(vRoomsRow.ExpectedCheckOutClause) Then
			If StrFind(vCurRoomItem.Condition, vRoomsRow.ExpectedCheckOutClause) = 0 Then
				vCurRoomItem.Condition = vCurRoomItem.Condition + ?(IsBlankString(vCurRoomItem.Condition), "", ", ") + vRoomsRow.ExpectedCheckOutClause;
			EndIf;
			vIsVacant = False;
		EndIf;
		If Not IsBlankString(vRoomsRow.ExpectedCheckInClause) Then
			If StrFind(vCurRoomItem.Condition, vRoomsRow.ExpectedCheckInClause) = 0 Then
				vCurRoomItem.Condition = vCurRoomItem.Condition + ?(IsBlankString(vCurRoomItem.Condition), "", ", ") + vRoomsRow.ExpectedCheckInClause;
			EndIf;
			vIsVacant = False;
		EndIf;
		If Not IsBlankString(vRoomsRow.CheckedInClause) Then
			If StrFind(vCurRoomItem.Condition, vRoomsRow.CheckedInClause) = 0 Then
				vCurRoomItem.Condition = vCurRoomItem.Condition + ?(IsBlankString(vCurRoomItem.Condition), "", ", ") + vRoomsRow.CheckedInClause;
			EndIf;
			vIsVacant = False;
		EndIf;
		If Not IsBlankString(vRoomsRow.ExpectedRoomMoveClause) Then
			If StrFind(vCurRoomItem.Condition, vRoomsRow.ExpectedRoomMoveClause) = 0 Then
				If vRoomsRow.Ref = vRoomsRow.ToRoom Then
					vCurRoomItem.Condition = vCurRoomItem.Condition + ?(IsBlankString(vCurRoomItem.Condition), "", ", ") + vRoomsRow.ExpectedRoomMoveClause + NStr("en = ' in from room '; de = ' vom Zimmer '; ru = ' из номера '") + TrimAll(vRoomsRow.FromRoom);
				ElsIf vRoomsRow.Ref = vRoomsRow.FromRoom Then
					vCurRoomItem.Condition = vCurRoomItem.Condition + ?(IsBlankString(vCurRoomItem.Condition), "", ", ") + vRoomsRow.ExpectedRoomMoveClause + NStr("en = ' out to room '; de = ' ins Zimmer '; ru = ' в номер '") + TrimAll(vRoomsRow.ToRoom);
				EndIf;
			EndIf;
			vIsVacant = False;
		EndIf;
		If Not IsBlankString(vRoomsRow.InHouseClause) And IsBlankString(vRoomsRow.CheckedInClause) And IsBlankString(vRoomsRow.ExpectedCheckOutClause) Then
			If StrFind(vCurRoomItem.Condition, vRoomsRow.InHouseClause) = 0 Then
				vCurRoomItem.Condition = vCurRoomItem.Condition + ?(IsBlankString(vCurRoomItem.Condition), "", ", ") + vRoomsRow.InHouseClause;
			EndIf;
			vIsVacant = False;
		ElsIf Not IsBlankString(vRoomsRow.CheckedOutClause) Then
			If StrFind(vCurRoomItem.Condition, vRoomsRow.CheckedOutClause) = 0 Then
				vCurRoomItem.Condition = vCurRoomItem.Condition + ?(IsBlankString(vCurRoomItem.Condition), "", ", ") + vRoomsRow.CheckedOutClause;
			EndIf;
			vIsVacant = False;
		EndIf;
		If ValueIsFilled(vRoomsRow.RoomBlockType) Then
			If StrFind(vCurRoomItem.Condition, TrimAll(vRoomsRow.RoomBlockType)) = 0 Then
				vCurRoomItem.Condition = vCurRoomItem.Condition + ?(IsBlankString(vCurRoomItem.Condition), "", ", ") + TrimAll(vRoomsRow.RoomBlockType);
			EndIf;
			vIsVacant = False;
		EndIf;
		If vIsVacant Then
			If StrFind(vCurRoomItem.Condition, vVacantClause) = 0 Then
				vCurRoomItem.Condition = vCurRoomItem.Condition + ?(IsBlankString(vCurRoomItem.Condition), "", ", ") + vVacantClause;
			EndIf;
		EndIf;
		
		// Fill regular operations
		If vDoAddRoom Then
			For Each vRegularOperationsRow In vRegularOperationsRows Do
				vCurRoomItem.RegularOperations = vCurRoomItem.RegularOperations + ?(IsBlankString(vCurRoomItem.RegularOperations), "", ", ") + TrimAll(vRegularOperationsRow.RegularOperationCode);
			EndDo;
		EndIf;
		
		// Calculate room status totals
		If vDoAddRoom Then
			vRoomStatusesTotalsRow = vRoomStatusesTotals.Find(vRoomsRow.RoomStatus, "RoomStatus");
			If vRoomStatusesTotalsRow = Undefined Then
				vRoomStatusesTotalsRow = vRoomStatusesTotals.Add();
				vRoomStatusesTotalsRow.RoomStatus = vRoomsRow.RoomStatus;
				vRoomStatusesTotalsRow.Quantity = 0;
			EndIf;
			vRoomStatusesTotalsRow.Quantity = vRoomStatusesTotalsRow.Quantity + 1;
		EndIf;
		
		If vCurRoom = CurRowRoom Then
			vRowId = vCurRoomItem.GetID();
		EndIf;			
	EndDo;
	
	// Update number of rooms by statuses
	For Each vStatusItem In TableBoxStatuses Do
		vRoomStatus = vStatusItem.Value;
		vRoomStatusesTotalsRow = vRoomStatusesTotals.Find(vRoomStatus, "RoomStatus");
		If vRoomStatusesTotalsRow <> Undefined Then
			vStatusItem.Presentation = TrimAll(vRoomStatus.Description) + " (" + Format(vRoomStatusesTotalsRow.Quantity, "NFD=0; NZ=; NG=") + ")";
		Else
			vStatusItem.Presentation = TrimAll(vRoomStatus.Description);
		EndIf;
	EndDo;
	
	vUseBedsSetupTotals = GetFunctionalOption("BedsSetups", New Structure("Hotel", SelHotel));
	// Fill beds setup totals   
	If vUseBedsSetupTotals Then
		FillBedsSetupTotalsAtServer();
	EndIf;
	
	Return vRowId;
EndFunction // FillRoomsListAtServer

// -----------------------------------------------------------------------------
&AtServer
Function CheckUserPermissionToOpenRooms()
	If ValueIsFilled(SessionParameters.CurrentUser) Then
		If Not ValueIsFilled(SessionParameters.CurrentUser.Customer) Then
			Return True;
		EndIf;
	EndIf;
	Return False;
EndFunction // CheckUserPermissionToOpenRooms

// -------------------------------------------------------------------------------------
&AtServer
Procedure UncheckAllStatuses()
	For Each vStatusItem In TableBoxStatuses Do
		vStatusItem.Check = False;
	EndDo;
EndProcedure // UncheckAllStatuses

// -------------------------------------------------------------------------------------
&AtServer
Procedure CheckAllStatuses()
	For Each vStatusItem In TableBoxStatuses Do
		vStatusItem.Check = True;
	EndDo;
EndProcedure // CheckAllStatuses

// -------------------------------------------------------------------------------------
&AtServer
Procedure CheckDirtyStatuses()
	UncheckAllStatuses();
	vHotelsList = GetHotelsList(SelHotel);
	For Each vStatusItem In TableBoxStatuses Do
		vCurStatus = vStatusItem.Value;
		If vCurStatus.OperationIsInProgress Or vCurStatus.InspectionIsInProgress Then
			vStatusItem.Check = True;
		Else
			For Each vHotelsListItem In vHotelsList Do
				vCurHotel = vHotelsListItem.Value;
				If ValueIsFilled(vCurHotel.RoomStatusDueOut) And vCurHotel.RoomStatusDueOut = vCurStatus Then
					vStatusItem.Check = True;
				EndIf;
				If ValueIsFilled(vCurHotel.RoomStatusAfterCheckOut) And vCurHotel.RoomStatusAfterCheckOut = vCurStatus Then
					vStatusItem.Check = True;
				EndIf;
				If ValueIsFilled(vCurHotel.RoomStatusAfterRoomBlock) And vCurHotel.RoomStatusAfterRoomBlock = vCurStatus Then
					vStatusItem.Check = True;
				EndIf;
				If ValueIsFilled(vCurHotel.RoomStatusAfterEarlyCheckIn) And vCurHotel.RoomStatusAfterEarlyCheckIn = vCurStatus Then
					vStatusItem.Check = True;
				EndIf;
				If ValueIsFilled(vCurHotel.OccupiedDirtyRoomStatus) And vCurHotel.OccupiedDirtyRoomStatus = vCurStatus Then
					vStatusItem.Check = True;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
EndProcedure // CheckDirtyStatuses

// -------------------------------------------------------------------------------------
&AtServer
Procedure CheckCleanStatuses()
	UncheckAllStatuses();
	vHotelsList = GetHotelsList(SelHotel);
	For Each vStatusItem In TableBoxStatuses Do
		vCurStatus = vStatusItem.Value;
		If vCurStatus.RoomIsVacantClear Then
			vStatusItem.Check = True;
		Else
			For Each vHotelsListItem In vHotelsList Do
				vCurHotel = vHotelsListItem.Value;
				If vCurHotel.VacantRoomStatus = vCurStatus Then
					vStatusItem.Check = True;
				EndIf;
				If ValueIsFilled(vCurHotel.ReservedRoomStatus) And vCurHotel.ReservedRoomStatus = vCurStatus Then
					vStatusItem.Check = True;
				EndIf;
				If ValueIsFilled(vCurHotel.RoomStatusInspection) And vCurHotel.RoomStatusInspection = vCurStatus Then
					vStatusItem.Check = True;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
EndProcedure // CheckCleanStatuses

// -------------------------------------------------------------------------------------
&AtServerNoContext
Function GetAllowedRoomStatusesList(pRoomStatus)
	vRoomStatuses = cmGetAllowedRoomStatuses(SessionParameters.CurrentUser, pRoomStatus);
	vRoomStatusesList = New ValueList();
	vRoomStatusesList.LoadValues(vRoomStatuses.UnloadColumn("RoomStatus"));
	Return vRoomStatusesList;
EndFunction // GetAllowedRoomStatusesList

// -------------------------------------------------------------------------------------
&AtClient
Function UpdateRoomStatusPresentation(Val pPresentation, pNum)
	vPresentation = TrimAll(pPresentation);
	vNumStr = "";
	vInd = StrLen(vPresentation);
	While vInd > 0 Do
		vChar = Mid(vPresentation, vInd, 1);
		If vInd = StrLen(vPresentation) And vChar <> ")" Then
			Break;
		ElsIf vChar = "(" Then
			vInd = vInd - 1;
			Break;
		ElsIf vChar <> ")" Then
			If vChar >= "0" And vChar <= "9" Then
				vNumStr = vChar + vNumStr;
			Else
				Break;
			EndIf;
		EndIf;
		vInd = vInd - 1;
	EndDo;
	If vNumStr = "" Then
		vNumStr = "0";
	EndIf;
	vNum = Number(vNumStr) + pNum;
	If vNum <= 0 Then
		Return TrimAll(Left(vPresentation, vInd));
	Else
		Return TrimAll(Left(vPresentation, vInd)) + " (" + Format(vNum, "NFD=0; NZ=; NG=") + ")";
	EndIf;
EndFunction // UpdateRoomStatusPresentation

// -------------------------------------------------------------------------------------
&AtServerNoContext
Function UpdateRoomStatus(pRoom, pRoomStatus, rOldRoomStatus)
	If ValueIsFilled(pRoom) Then
		If pRoom.RoomStatus <> pRoomStatus Then
			// Save old room status
			rOldRoomStatus = pRoom.RoomStatus;
			// Update room status
			vRoomObj = pRoom.GetObject();
			vRoomObj.RoomStatus = pRoomStatus;
			vRoomObj.Write();
			// Add record to the room status change history
			vCurrentDate = CurrentSessionDate();
			vRoomObj.pmWriteToRoomStatusChangeHistory(vCurrentDate, SessionParameters.CurrentUser, "");
			Return vCurrentDate;
		EndIf;
	EndIf;
	Return Undefined;
EndFunction // UpdateRoomStatus

// -------------------------------------------------------------------------------------
&AtServerNoContext
Function UpdateRoomBedsSetup(pRoom, pBedsSetup)
	vOk = False;
	If ValueIsFilled(pRoom) Then
		If pRoom.BedsSetup <> pBedsSetup And Not pRoom.BedsSetupIsFixed Then
			vAllowedBedsSetupList = GetBedsSetupList(Undefined, pRoom.RoomType);
			If vAllowedBedsSetupList.FindByValue(pBedsSetup) <> Undefined Then
				// Update room beds setup
				vRoomObj = pRoom.GetObject();
				vRoomObj.BedsSetup = pBedsSetup;
				vRoomObj.Write();
				// Add record to the room change history
				vRoomObj.pmWriteToRoomChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				// Success
				vOk = True;
			EndIf;
		EndIf;
	EndIf;
	Return vOk;
EndFunction // UpdateRoomBedsSetup

// -------------------------------------------------------------------------------------
&AtServer
Function RefreshRoomInListAtServer(pRoom, pRoomBlockType = Undefined, pItem = Undefined)
	vItem = TableBoxRooms;
	If pItem <> Undefined Then
		vItem = pItem;
	EndIf;
	For Each vSubItem In vItem.GetItems() Do
		If vSubItem.IsFolder Then
			If RefreshRoomInListAtServer(pRoom, pRoomBlockType, vSubItem) Then
				Return True;
			EndIf;
		Else
			If vSubItem.Ref = pRoom Then
				vOldRoomBlockType = vSubItem.RoomBlockType;
				FillPropertyValues(vSubItem, pRoom);
				vSubItem.RoomStatusIcon = GetRoomStatusIconIndex(vSubItem.RoomStatus);
				vHstRows = pRoom.GetObject().pmGetRoomStatusHistoryState(CurrentSessionDate());
				If vHstRows.Count() > 0 Then
					vHstRow = vHstRows.Get(0);
					vSubItem.RoomStatusLastChangeTime = vHstRow.Period;
				EndIf;
				If vSubItem.HasRoomBlocks Then
					If ValueIsFilled(pRoomBlockType) Then
						vSubItem.RoomBlockType = pRoomBlockType;
						If ValueIsFilled(vOldRoomBlockType) Then
							If StrFind(vSubItem.Condition, ", " + TrimAll(vOldRoomBlockType)) > 0 Then
								vSubItem.Condition = StrReplace(vSubItem.Condition, ", " + TrimAll(vOldRoomBlockType), "");
							ElsIf StrFind(vSubItem.Condition, TrimAll(vOldRoomBlockType)) > 0 Then
								vSubItem.Condition = StrReplace(vSubItem.Condition, TrimAll(vOldRoomBlockType), "");
							EndIf;
						EndIf;
						If StrFind(vSubItem.Condition, TrimAll(pRoomBlockType)) = 0 Then
							vSubItem.Condition = vSubItem.Condition + ?(IsBlankString(vSubItem.Condition), "", ", ") + TrimAll(pRoomBlockType);
						EndIf;
					EndIf;
				Else
					vSubItem.RoomBlockType = Undefined;
					If ValueIsFilled(vOldRoomBlockType) Then
						If StrFind(vSubItem.Condition, ", " + TrimAll(vOldRoomBlockType)) > 0 Then
							vSubItem.Condition = StrReplace(vSubItem.Condition, ", " + TrimAll(vOldRoomBlockType), "");
						ElsIf StrFind(vSubItem.Condition, TrimAll(vOldRoomBlockType)) > 0 Then
							vSubItem.Condition = StrReplace(vSubItem.Condition, TrimAll(vOldRoomBlockType), "");
						EndIf;
					EndIf;
				EndIf;
				Return True;
			EndIf;
		EndIf;
	EndDo;
	vUseBedsSetupTotals = GetFunctionalOption("BedsSetups", New Structure("Hotel", SelHotel));
	// Fill beds setup totals   
	If vUseBedsSetupTotals Then
		FillBedsSetupTotalsAtServer();
	EndIf;

	Return False;
EndFunction // RefreshRoomInListAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetRoomStatusIconIndex(pRoomStatus) Export
	vPictureIndex = 5;
	If ValueIsFilled(pRoomStatus) Then
		If ValueIsFilled(pRoomStatus.RoomStatusIcon) Then
			If pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.None Then
				vPictureIndex = 5;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Reserved Then
				vPictureIndex = 6;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Occupied Then
				vPictureIndex = 2;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.OccupiedDirty Then
				vPictureIndex = 7;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Repair Then
				vPictureIndex = 8;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Luggage Then
				vPictureIndex = 9;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Malfunction Then
				vPictureIndex = 10;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Waiting Then
				vPictureIndex = 1;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.TidyingUp Then
				vPictureIndex = 0;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.CheckOut Then
				vPictureIndex = 3;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Vacant Then
				vPictureIndex = 4;
			EndIf;
		EndIf;
	EndIf;
	Return vPictureIndex;
EndFunction // GetRoomStatusIconIndex

// -----------------------------------------------------------------------------
&AtServer
Procedure ShowRoomGuestsDataAtServer(pRoom, pDocumentNumber, pDocumentClause, pGuestsOnArrival)
	If ValueIsFilled(pRoom) Then
		CurRoom = pRoom;
		If Not IsBlankString(pDocumentNumber) Then
			vDocument = Undefined;
			vDocRow = Undefined;
			
			CurCondition = pDocumentClause;
			
			If pGuestsOnArrival > 0 Then
				vQry = New Query();
				vQry.Text = 
				"SELECT
				|	Reservations.Ref AS Ref,
				|	Reservations.Guest AS Guest,
				|	Reservations.GuestFullName AS GuestFullName,
				|	Reservations.CheckInDate AS CheckInDate,
				|	Reservations.CheckOutDate AS CheckOutDate,
				|	Reservations.AccommodationTemplate AS AccommodationTemplate,
				|	Reservations.PricePresentation AS PricePresentation,
				|	Reservations.HousekeepingRemarks AS HousekeepingRemarks,
				|	Reservations.Remarks AS Remarks
				|FROM
				|	Document.Reservation AS Reservations
				|WHERE
				|	Reservations.Room = &qRoom
				|	AND Reservations.Number = &qNumber
				|	AND Reservations.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
				|	AND Reservations.Posted";
				vQry.SetParameter("qRoom", pRoom);
				vQry.SetParameter("qNumber", pDocumentNumber);
				vDocs = vQry.Execute().Unload();
				For Each vDocsRow In vDocs Do
					vDocument = vDocsRow.Ref;
					vDocRow = vDocsRow;
					Break;
				EndDo;
			EndIf;
			
			If vDocument = Undefined Then
				vQry = New Query();
				vQry.Text = 
				"SELECT
				|	Accommodations.Ref AS Ref,
				|	Accommodations.Guest AS Guest,
				|	Accommodations.GuestFullName AS GuestFullName,
				|	Accommodations.CheckInDate AS CheckInDate,
				|	Accommodations.CheckOutDate AS CheckOutDate,
				|	Accommodations.AccommodationTemplate AS AccommodationTemplate,
				|	Accommodations.PricePresentation AS PricePresentation,
				|	Accommodations.HousekeepingRemarks AS HousekeepingRemarks,
				|	Accommodations.Remarks AS Remarks
				|FROM
				|	Document.Accommodation AS Accommodations
				|WHERE
				|	Accommodations.Room = &qRoom
				|	AND Accommodations.Number = &qNumber
				|	AND Accommodations.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
				|	AND Accommodations.Posted";
				vQry.SetParameter("qRoom", pRoom);
				vQry.SetParameter("qNumber", pDocumentNumber);
				vDocs = vQry.Execute().Unload();
				For Each vDocsRow In vDocs Do
					vDocument = vDocsRow.Ref;
					vDocRow = vDocsRow;
					Break;
				EndDo;
			EndIf;
			
			If vDocument = Undefined Then
				vQry = New Query();
				vQry.Text = 
				"SELECT
				|	SetRoomBlocks.Ref AS Ref,
				|	SetRoomBlocks.RoomBlockType AS RoomBlockType,
				|	PRESENTATION(SetRoomBlocks.RoomBlockType) AS RoomBlockTypeDescription,
				|	SetRoomBlocks.DateFrom AS DateFrom,
				|	SetRoomBlocks.DateTo AS DateTo,
				|	SetRoomBlocks.Remarks AS Remarks
				|FROM
				|	Document.SetRoomBlock AS SetRoomBlocks
				|WHERE
				|	SetRoomBlocks.Room = &qRoom
				|	AND SetRoomBlocks.Number = &qNumber
				|	AND SetRoomBlocks.Posted";
				vQry.SetParameter("qRoom", pRoom);
				vQry.SetParameter("qNumber", pDocumentNumber);
				vDocs = vQry.Execute().Unload();
				For Each vDocsRow In vDocs Do
					vDocument = vDocsRow.Ref;
					vDocRow = vDocsRow;
					Break;
				EndDo;
			EndIf;
			
			If ValueIsFilled(vDocument) And vDocRow <> Undefined Then
				CurDocument = vDocument;
				If TypeOf(vDocument) <> Type("DocumentRef.SetRoomBlock") Then
					CurGuest = vDocRow.Guest;
					CurGuestFullName = vDocRow.GuestFullName;
					CurCheckInDate = vDocRow.CheckInDate;
					CurCheckOutDate = vDocRow.CheckOutDate;
					CurTemplate = vDocRow.AccommodationTemplate;
					CurRemarks = TrimAll(TrimAll(vDocRow.HousekeepingRemarks) + Chars.LF + TrimAll(vDocRow.Remarks));
					CurHousekeepingRemarks = TrimAll(vDocRow.HousekeepingRemarks);
					CurPrice = TrimAll(vDocRow.PricePresentation);
				Else
					CurGuest = Undefined;
					CurGuestFullName = TrimAll(vDocRow.RoomBlockTypeDescription);
					CurCheckInDate = vDocRow.DateFrom;
					CurCheckOutDate = vDocRow.DateTo;
					CurTemplate = Undefined;
					CurRemarks = TrimAll(vDocRow.Remarks);
					CurHousekeepingRemarks = "";
					CurPrice = "";
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ShowRoomGuestsDataAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowRoomGuestsData()
	vCurData = Items.TableBoxRooms.CurrentData;
	If vCurData <> Undefined Then
		ShowRoomGuestsDataAtServer(vCurData.Ref, vCurData.DocumentNumber, vCurData.DocumentClause, vCurData.NumberOfGuestsOnArrival);
	EndIf;
EndProcedure // ShowRoomGuestsData

// -----------------------------------------------------------------------------
&AtServer
Function TableBoxStatusesSelectionAtServer(pRoomStatus)
	// Check selected one only
	For Each vItem In TableBoxStatuses Do
		If vItem.Value = pRoomStatus Then
			vItem.Check = True;
		Else
			vItem.Check = False;
		EndIf;
	EndDo;
	// Fill rooms list
	vRowId = FillRoomsListAtServer();  
	Return vRowId;
EndFunction // TableBoxStatusesSelectionAtServer

// -------------------------------------------------------------------------------------
&AtServerNoContext
Function GetAllListRooms(pHotel)
	vQuery = New Query();
	vQuery.Text =
	"SELECT
	|	Rooms.Ref AS Ref
	|FROM
	|	Catalog.Rooms AS Rooms
	|WHERE
	|	NOT Rooms.DeletionMark
	|	AND NOT Rooms.IsFolder
	|	AND (Rooms.Owner = &qHotel OR NOT &qHotelIsFilled)
	|
	|ORDER BY
	|	Rooms.SortCode";
	vQuery.SetParameter("qHotel", pHotel);
	vQuery.SetParameter("qHotelIsFilled", ValueIsFilled(pHotel));
	vResult = vQuery.Execute().Unload();
	vRoomsList = New ValueList();
	For Each vRoom In vResult Do
		vRoomsList.Add(vRoom.Ref);	
	EndDo;
	Return vRoomsList;
EndFunction // GetAllListRooms

// -----------------------------------------------------------------------------
&AtClient
Procedure CloseFormSetRoomBlock(pResult, pExtraParams) Export 
	 FillRoomsList();	
EndProcedure // CloseFormSetRoomBlock

// -----------------------------------------------------------------------------
&AtClient
Function GetFilter1Presentation()
	vFilter = "";
	If SelShowAllRooms Then
		vFilter = NStr("en = 'All rooms'; de = 'Alle Zimmern'; ru = 'Все номера'");		
	ElsIf SelShowDirtyRooms Then
		vFilter = NStr("en = 'Dirty rooms'; de = 'Schmutzige Zimmern'; ru = 'Грязные номера'");	
	ElsIf SelShowCleanRooms Then
		vFilter = NStr("en = 'Clean rooms'; de = 'Rein Zimmern'; ru = 'Чистые номера'");	
	ElsIf SelShowVacantRooms Then
		vFilter = NStr("en = 'Vacant rooms'; de = 'Frei Zimmern'; ru = 'Свободные номера'");	
	ElsIf SelShowOccupiedRooms Then
		vFilter = NStr("en = 'In-house rooms'; de = 'In-house Zimmern'; ru = 'Занятые номера'");		
	ElsIf SelShowPlannedCheckIn Then
		vFilter = NStr("en = 'Expected arrival'; de = 'Erwartete Ankunft'; ru = 'Ожидаемый заезд'");
	ElsIf SelShowPlannedCheckOut Then
		vFilter = NStr("en = 'Expected departure'; de = 'Erwartete Abreise'; ru = 'Ожидаемый выезд'");
	ElsIf SelShowCheckedIn Then
		vFilter = NStr("en = 'All checked-in'; de = 'Tatsächliche Anreise'; ru = 'Фактический заезд'");
	ElsIf SelShowCheckedOut Then
		vFilter = NStr("en = 'All checked-out'; de = 'Tatsächliche Abreise'; ru = 'Фактический выезд'");
	ElsIf SelShowRoomsWithTasks Then
		vFilter = NStr("en = 'Rooms with tasks'; de = 'Zimmern mit Aufgaben'; ru = 'Номера с задачами'");
	ElsIf SelShowRoomsWithDiscrepancies Then
		vFilter = NStr("en = 'Discrepancies in statuses'; de = 'Statusen Diskrepanzen'; ru = 'Расхождения в статусах'");
	ElsIf SelShowRoomsWithBedsSetupDiscrepancies Then
		vFilter = NStr("en = 'Discrepancies in beds setup'; de = 'Betten-Setup Diskrepanzen'; ru = 'Расхождения в конф. кроватей'");
	ElsIf SelShowRoomsBlock Then
		vFilter = NStr("en = 'Blocked rooms'; de = 'Blockierte Zimmern'; ru = 'Номера с блокировкой'");
	ElsIf SelShowRoomsStopSale Then
		vFilter = NStr("en = 'Stop sale rooms'; de = 'Stop Verkaufszimmern'; ru = 'Номера снятые с продажи'");
	ElsIf SelShowRegularOperations Then
		vFilter = NStr("en = 'Regular operations'; de = 'Routinearbeiten'; ru = 'Регламентные работы'");
	EndIf;
	Return vFilter;
EndFunction // GetFilter1Presentation

// -----------------------------------------------------------------------------
&AtClient
Function GetFilter2Presentation()
	vFilter = "";
	If ValueIsFilled(SelHotel) Then
		vFilter = ?(ValueIsFilled(vFilter), vFilter + ", ", vFilter) + NStr("en = 'Hotel: '; de = 'Hotel: '; ru = 'Гостиница: '") + SelHotel; 	
	EndIf;
	If ValueIsFilled(SelRoomsFolder) Then
		vFilter = ?(ValueIsFilled(vFilter), vFilter + ", ", vFilter) + NStr("en = 'Folder: '; de = 'Ordner: '; ru = 'Группа: '") + SelRoomsFolder; 	
	EndIf;
	If ValueIsFilled(SelRoomSection) Then
		vFilter = ?(ValueIsFilled(vFilter), vFilter + ", ", vFilter) + NStr("en = 'Section: '; de = 'Abschnitt: '; ru = 'Секция: '") + SelRoomSection; 	
	EndIf;
	If ValueIsFilled(SelFloor) Then
		vFilter = ?(ValueIsFilled(vFilter), vFilter + ", ", vFilter) + NStr("en = 'Floor: '; de = 'Boden: '; ru = 'Этаж: '") + SelFloor; 	
	EndIf;
	If SelRoomTypes.Count() <> 0 Then
		vFilter = ?(ValueIsFilled(vFilter), vFilter + ", ", vFilter) + NStr("en = 'Room types: '; de = 'Zimmertypen: '; ru = 'Типы номеров: '") + String(SelRoomTypes);
	EndIf;
	If ValueIsFilled(SelRoom) Then
		vFilter = ?(ValueIsFilled(vFilter), vFilter + ", ", vFilter) + NStr("en = 'Room: '; de = 'Zimmer: '; ru = 'Номер: '") + SelRoom; 	
	EndIf;
	If ValueIsFilled(SelBedsSetup) Then
		vFilter = ?(ValueIsFilled(vFilter), vFilter + ", ", vFilter) + NStr("en = 'Beds in rooms: '; de = 'Betten in Zimmern: '; ru = 'Кровати в номерах: '") + SelBedsSetup; 	
	EndIf;
	If ValueIsFilled(SelBedsSetupInReservation) Then
		vFilter = ?(ValueIsFilled(vFilter), vFilter + ", ", vFilter) + NStr("en = 'Beds in reservations: '; de = 'Betten in Reservierungen: '; ru = 'Кровати в брони: '") + SelBedsSetupInReservation; 	
	EndIf;
	Return vFilter;
EndFunction // GetFilter2Presentation

// -----------------------------------------------------------------------------
&AtClient
Function GetFilter3Presentation()
	vFilter = "";
	vStatuses = "";
	For Each vRow In TableBoxStatuses Do
		If vRow.Check Then
			vStatuses = vStatuses + ?(ValueIsFilled(vStatuses), ", " + vRow.Value, vRow.Value);	
		EndIf;
	EndDo;
	If ValueIsFilled(vStatuses) Then
		vFilter = NStr("en = 'Statuses: '; de = 'Status: '; ru = 'Статусы: '") +  vStatuses; 	
	EndIf;
	Return vFilter;
EndFunction // GetFilter3Presentation

// -------------------------------------------------------------------------------------
&AtServerNoContext
Function GetRoomProperties(pHotel)
	vQuery = New Query();
	vQuery.Text = "SELECT
	              |	RoomProperties.RoomProperty AS RoomProperty
	              |FROM
	              |	InformationRegister.RoomProperties AS RoomProperties
	              |WHERE
	              |	CASE
	              |			WHEN &qHotelIsFilled
	              |				THEN RoomProperties.Room.Owner = &qHotel
	              |			ELSE TRUE
	              |		END
	              |
	              |GROUP BY
	              |	RoomProperties.RoomProperty
	              |
	              |ORDER BY
	              |	RoomProperties.RoomProperty.SortCode";
	vQuery.SetParameter("qHotel", pHotel);
	vQuery.SetParameter("qHotelIsFilled", ValueIsFilled(pHotel));
	vResult = vQuery.Execute().Unload();
	vRoomsPropertyList = New ValueList();
	For Each vRoom In vResult Do
		vRoomsPropertyList.Add(vRoom.RoomProperty);	
	EndDo;
	Return vRoomsPropertyList;
EndFunction // GetRoomProperties

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomPropertiesStartChoice_AfterInput(pResult, pExtraParams) Export 
	If TypeOf(pResult) = Type("ValueList") Then
		SelRoomProperties.Clear();
		For Each vPR In pResult Do
			If vPR.Check Then
			     SelRoomProperties.Add(vPR.Value);
			EndIf;
		EndDo;
		SelRoomPropertiesOnChange(Items.SelRoomProperties);
		// Fill rooms list
		FillRoomsList();
	EndIf;	
EndProcedure

// -------------------------------------------------------------------------------------
&AtServerNoContext
Function GetRoomTypes(pHotel, pRoomTypesList)
	vRoomTypesList = New ValueList();
	vAllRoomTypes = cmGetAllRoomTypes(pHotel);
	For Each vAllRoomTypesRow In vAllRoomTypes Do
		vRoomTypesList.Add(vAllRoomTypesRow.RoomType, , ?(pRoomTypesList.FindByValue(vAllRoomTypesRow.RoomType) = Undefined, False, True));	
	EndDo;
	Return vRoomTypesList;
EndFunction // GetRoomTypes

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomTypesStartChoice_AfterInput(pResult, pExtraParams) Export 
	If TypeOf(pResult) = Type("ValueList") Then
		SelRoomTypes.Clear();
		For Each vRT In pResult Do
			If vRT.Check Then
			     SelRoomTypes.Add(vRT.Value);
			EndIf;
		EndDo;
		SelRoomTypesOnChange(Items.SelRoomTypes);
		// Fill rooms list
		FillRoomsList();
	EndIf;	
EndProcedure // SelRoomTypesStartChoice_AfterInput

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetBedsSetupList(pBedsSetup, pRoomType)
	vBedsSetupList = New ValueList();
	If ValueIsFilled(pRoomType) Then
		If pRoomType.AllowedBedsSetups.Count() > 0 Then
			For Each vRow In pRoomType.AllowedBedsSetups Do
				If vBedsSetupList.FindByValue(vRow.BedsSetup) = Undefined Then
					If ValueIsFilled(vRow.BedsSetup) Then
						vBedsSetupList.Add(vRow.BedsSetup);
					Else
						vBedsSetupList.Insert(0, vRow.BedsSetup, NStr("en='<Empty>'; ru='<Пустая>'; de='<Leer>'"));
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	If vBedsSetupList.FindByValue(pBedsSetup) = Undefined Then
		vBedsSetupList.Insert(0, pBedsSetup, ?(ValueIsFilled(pBedsSetup), pBedsSetup, NStr("en='<Empty>'; ru='<Пустая>'; de='<Leer>'")));
	EndIf;
	Return vBedsSetupList;
EndFunction // GetBedsSetupList

// --------------------------------------------------------------------------------
&AtServer
Procedure FillBedsSetupTotalsAtServer()
	If SkipBedsSetupTotalsUpdate Then
		SkipBedsSetupTotalsUpdate = False;
		Return;
	EndIf;
	// Checks
	If Not ValueIsFilled(BedsSetupTotalsDate) Then
		BedsSetupTotalsDate = CurrentSessionDate();
	EndIf;
	// Clear current state
	BedsSetupTotals.GetItems().Clear();
	// List of hotels
	vHotelsList = GetHotelsList(SelHotel);
	// Run query to get data
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	BedsSetups.Ref AS BedsSetup,
	|	RoomTypes.RoomType AS RoomType,
	|	ISNULL(TotalsByRooms.RoomsAvailable, 0) AS RoomsAvailable,
	|	ISNULL(TotalsByReservations.RoomsNeeded, 0) AS RoomsNeeded,
	|	ISNULL(TotalsByReservations.RoomsNeeded, 0) - ISNULL(TotalsByRooms.RoomsAvailable, 0) AS Difference
	|FROM
	|	Catalog.BedsSetups AS BedsSetups
	|		LEFT JOIN (SELECT
	|			RoomTypes.Ref AS RoomType,
	|			RoomTypes.SortCode AS SortCode
	|		FROM
	|			Catalog.RoomTypes AS RoomTypes
	|		WHERE
	|			NOT RoomTypes.DeletionMark
	|			AND NOT RoomTypes.IsFolder
	|			AND (&qHotelsListIsEmpty
	|					OR NOT &qHotelsListIsEmpty
	|						AND RoomTypes.Owner IN (&qHotelsList))) AS RoomTypes
	|		ON (TRUE)
	|		LEFT JOIN (SELECT
	|			Rooms.BedsSetup AS BedsSetup,
	|			Rooms.RoomType AS RoomType,
	|			COUNT(Rooms.Ref) AS RoomsAvailable
	|		FROM
	|			Catalog.Rooms AS Rooms
	|		WHERE
	|			NOT Rooms.DeletionMark
	|			AND NOT Rooms.IsFolder
	|			AND (&qHotelsListIsEmpty
	|					OR NOT &qHotelsListIsEmpty
	|						AND Rooms.Owner IN (&qHotelsList))
	|			AND (Rooms.OperationEndDate = &qEmptyDate
	|					OR Rooms.OperationEndDate > &qDate)
	|			AND Rooms.OperationStartDate <= &qDate
	|			AND Rooms.BedsSetup <> VALUE(Catalog.BedsSetups.EmptyRef)
	|		
	|		GROUP BY
	|			Rooms.BedsSetup,
	|			Rooms.RoomType) AS TotalsByRooms
	|		ON BedsSetups.Ref = TotalsByRooms.BedsSetup
	|			AND (RoomTypes.RoomType = TotalsByRooms.RoomType)
	|		LEFT JOIN (SELECT
	|			AllReservations.BedsSetup AS BedsSetup,
	|			AllReservations.RoomType AS RoomType,
	|			SUM(AllReservations.RoomsNeeded) AS RoomsNeeded
	|		FROM
	|			(SELECT
	|				Reservations.BedsSetup AS BedsSetup,
	|				Reservations.RoomType AS RoomType,
	|				SUM(CASE
	|						WHEN Reservations.NumberOfRooms <> 0
	|							THEN Reservations.NumberOfRooms
	|						WHEN Reservations.NumberOfBeds <> 0
	|								AND Reservations.NumberOfBedsPerRoom <> 0
	|							THEN Reservations.NumberOfBeds / Reservations.NumberOfBedsPerRoom
	|						ELSE 0
	|					END) AS RoomsNeeded
	|			FROM
	|				Document.Reservation AS Reservations
	|			WHERE
	|				Reservations.Posted
	|				AND (&qHotelsListIsEmpty
	|						OR NOT &qHotelsListIsEmpty
	|							AND Reservations.Hotel IN (&qHotelsList))
	|				AND BEGINOFPERIOD(Reservations.CheckInDate, DAY) <= &qDate
	|				AND (BEGINOFPERIOD(Reservations.CheckOutDate, DAY) > &qDate
	|						OR BEGINOFPERIOD(Reservations.CheckInDate, DAY) = BEGINOFPERIOD(Reservations.CheckOutDate, DAY))
	|				AND Reservations.ReservationStatus.IsActive
	|				AND NOT Reservations.ReservationStatus.IsCheckIn
	|				AND Reservations.BedsSetup <> VALUE(Catalog.BedsSetups.EmptyRef)
	|			
	|			GROUP BY
	|				Reservations.BedsSetup,
	|				Reservations.RoomType
	|			
	|			UNION ALL
	|			
	|			SELECT
	|				Accommodations.BedsSetup,
	|				Accommodations.RoomType,
	|				SUM(CASE
	|						WHEN Accommodations.NumberOfRooms <> 0
	|							THEN Accommodations.NumberOfRooms
	|						WHEN Accommodations.NumberOfBeds <> 0
	|								AND Accommodations.NumberOfBedsPerRoom <> 0
	|							THEN Accommodations.NumberOfBeds / Accommodations.NumberOfBedsPerRoom
	|						ELSE 0
	|					END)
	|			FROM
	|				Document.Accommodation AS Accommodations
	|			WHERE
	|				Accommodations.Posted
	|				AND (&qHotelsListIsEmpty
	|						OR NOT &qHotelsListIsEmpty
	|							AND Accommodations.Hotel IN (&qHotelsList))
	|				AND BEGINOFPERIOD(Accommodations.CheckInDate, DAY) <= &qDate
	|				AND (BEGINOFPERIOD(Accommodations.CheckOutDate, DAY) > &qDate
	|						OR BEGINOFPERIOD(Accommodations.CheckInDate, DAY) = BEGINOFPERIOD(Accommodations.CheckOutDate, DAY))
	|				AND Accommodations.AccommodationStatus.IsActive
	|				AND Accommodations.BedsSetup <> VALUE(Catalog.BedsSetups.EmptyRef)
	|			
	|			GROUP BY
	|				Accommodations.BedsSetup,
	|				Accommodations.RoomType) AS AllReservations
	|		
	|		GROUP BY
	|			AllReservations.BedsSetup,
	|			AllReservations.RoomType) AS TotalsByReservations
	|		ON BedsSetups.Ref = TotalsByReservations.BedsSetup
	|			AND (RoomTypes.RoomType = TotalsByReservations.RoomType)
	|WHERE
	|	(ISNULL(TotalsByRooms.RoomsAvailable, 0) <> 0
	|			OR ISNULL(TotalsByReservations.RoomsNeeded, 0) <> 0)
	|
	|ORDER BY
	|	BedsSetups.SortCode,
	|	BedsSetups.Code,
	|	RoomTypes.SortCode";
	vQry.SetParameter("qHotelsListIsEmpty", ?(vHotelsList.Count() > 0, False, True));
	vQry.SetParameter("qHotelsList", vHotelsList);
	vQry.SetParameter("qDate", BedsSetupTotalsDate);
	vQry.SetParameter("qEmptyDate", '00010101');
	vBedsSetupTotals = vQry.Execute().Unload();
	// Fill beds setup totals
	vCurBedsSetup = Undefined;
	vCurTreeRow = Undefined;
	vCurDifference = 0;
	For Each vRow In vBedsSetupTotals Do
		If vCurBedsSetup <> vRow.BedsSetup Then
			vCurBedsSetup = vRow.BedsSetup;
			vCurDifference = 0;
			
			vCurTreeRow = BedsSetupTotals.GetItems().Add();
			vCurTreeRow.BedsSetup = vRow.BedsSetup;
		EndIf;
		If vCurTreeRow <> Undefined Then
			If vRow.Difference > 0 Then
				vCurDifference = vCurDifference + vRow.Difference;
				vCurTreeRow.Difference = vCurDifference;
			EndIf;
			
			vCurRow = vCurTreeRow.GetItems().Add();
			FillPropertyValues(vCurRow, vRow, , "BedsSetup, Difference");
			If vRow.Difference > 0 Then
				vCurRow.Difference = vRow.Difference;
			EndIf;
		EndIf;
	EndDo;
EndProcedure // FillBedsSetupTotalsAtServer

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetHousekeepingDepartment()
	If ValueIsFilled(SessionParameters.CurrentHotel) Then
		Return SessionParameters.CurrentHotel.HousekeepingDepartment;
	Else
		Return Catalogs.Departments.EmptyRef();
	EndIf;
EndFunction // GetHousekeepingDepartment

// --------------------------------------------------------------------------------
&AtServer
Procedure SetBedsSetupAvailability()
	vUseBedsSetup = False;
	If ValueIsFilled(SelHotel) And Not SelHotel.IsFolder Then
		vUseBedsSetup = SelHotel.BedsSetups;
	EndIf;
	Items.SelBedsSetup.Visible = vUseBedsSetup;
	Items.SelBedsSetupInReservation.Visible = vUseBedsSetup;
	Items.SelShowRoomsWithBedsSetupDiscrepancies.Visible = vUseBedsSetup;
	Items.GroupBedsSetupTotals.Visible = vUseBedsSetup;
	Items.TableBoxRoomsBedsSetup.Visible = vUseBedsSetup;
	Items.TableBoxRoomsBedsSetupInReservation.Visible = vUseBedsSetup;
EndProcedure

#EndRegion
