
#Region FormEventHandlers

// -------------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Hotel
	SelHotel = SessionParameters.CurrentHotel;
	// Add room statuses
	vRoomStatuses = cmGetAllRoomStatuses();
	SelChangeStatusList.Clear();
	For Each vRoomStatusesRow In vRoomStatuses Do
		TableBoxStatuses.Add(vRoomStatusesRow.RoomStatus, TrimAll(vRoomStatusesRow.Description), True, cmGetRoomStatusIcon(vRoomStatusesRow.RoomStatus));
		SelChangeStatusList.Add(vRoomStatusesRow.RoomStatus, TrimAll(vRoomStatusesRow.Description), True, cmGetRoomStatusIcon(vRoomStatusesRow.RoomStatus));  
	EndDo;
	// Check user permission to change room statuses
	If Not cmCheckUserPermissions("HavePermissionToChangeRoomStatuses") Then
		Items.CatalogListRoomsRoomStatus.ReadOnly = True;
		Items.FormCopyValue.Enabled = False;
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
			vRoomStatusSelected = Catalogs.RoomStatuses.FindByCode(Mid(Parameters.FilterStatus, 2), False);
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
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	For Each vItemRow In SelChangeStatusList Do
		vCommand = Commands.Add("ChangeStatus" + vItemRow.GetID());
		vCommand.Action = "ChangeStatusRoom";                                           
		vStructure = New Structure("Title, CommandName, Representation, Picture", vItemRow.Presentation, "ChangeStatus" + vItemRow.GetID(), ButtonRepresentation.PictureAndText, vItemRow.Picture);		
		tcOnServer.cmCreateItem(ThisObject, Items.TableBoxRoomsContextMenuGroupChangeStatus, "ChangeStatus_" + vItemRow.GetID(), "FormButton", vStructure);	
	EndDo;
EndProcedure // OnCreateAtServer

// -------------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	// Fill rooms list
	FillRoomsList();
	// Expand items
	For Each vItem In TableBoxRooms.GetItems() Do
		Items.TableBoxRooms.Expand(vItem.GetID(), True);
	EndDo;
	If tcOnClient.IsHomePageWindow(ThisObject) Then
		vPrefix = NStr("en = 'Rooms: '; de = 'Zimmerbestand: '; ru = 'Номерной фонд: '");
		tcCommonFunctionOnClientServer.cmSetFormTitleHotelName(ThisObject, vPrefix);
	EndIf;		
EndProcedure // OnOpen

// -------------------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If ValueIsFilled(pParameter) Then
		If pEventName = "Document.SetRoomBlock.Write" Then 
			RefreshRoomInListAtServer(tcOnServer.cmGetAttributeByRef(pParameter, "Room"), tcOnServer.cmGetAttributeByRef(pParameter, "RoomBlockType"));	
		ElsIf pEventName = "Catalog.Rooms.Write" Then
			RefreshRoomInListAtServer(pParameter);
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
		If pEventName = "Document.SetRoomBlock.Write" Or 
		   pEventName = "Document.SetRoomBlock.Unblock" Or 
		   pEventName = "Document.SetRoomBlock.WriteListRoom" Then
			FillRoomsList();
		EndIf;	
	EndIf;
EndProcedure // NotificationProcessing

#EndRegion

#Region FormHeaderItemsEventHandlers

// -------------------------------------------------------------------------------------
&AtClient
Procedure SelRoomsFolderOnChange(pItem)
	// Fill rooms list
	FillRoomsList();
EndProcedure // SelRoomsFolderOnChange

// -------------------------------------------------------------------------------------
&AtClient
Procedure SelRoomTypeOnChange(pItem)
	// Fill rooms list
	FillRoomsList();
EndProcedure // SelRoomTypeOnChange

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
Procedure SelRoomOnChange(Item)
	// Fill rooms list
	FillRoomsList();
EndProcedure // SelRoomOnChange

// -------------------------------------------------------------------------------------
&AtClient
Procedure TableBoxRoomsSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	vCurData = Items.TableBoxRooms.CurrentData;
	If vCurData <> Undefined And Not vCurData.IsFolder Then
		pStandardProcessing = False;
		OpenForm("Catalog.Rooms.Form.mcHousekeepingItemForm", New Structure("key", vCurData.Ref));
	EndIf;
EndProcedure // TableBoxRoomsSelection 

// -----------------------------------------------------------------------------
&AtClient
Procedure TableBoxRoomsOnActivateRow(pItem)
	vRowData = Items.TableBoxRooms.CurrentData;
	If vRowData <> Undefined Then
		CurRowRoom = vRowData.Ref;
		FillStatuslist(CurRowRoom, SelChangeStatusList);
		For Each vItemRow In SelChangeStatusList Do
			Items["FormButtonChangeStatus_" + vItemRow.GetID()].Visible = vItemRow.Check; 	
		EndDo;
	Else
		CurRowRoom = Undefined;
	EndIf;
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

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure CopyValue(pCommand)
	If Items.TableBoxRooms.CurrentRow <> Undefined Then
		vRoomData = TableBoxRooms.FindByID(Items.TableBoxRooms.CurrentRow);
		If Items.TableBoxRooms.CurrentItem <> Undefined Then
			CopyColumn = "RoomStatus";
			CopyValue = vRoomData[CopyColumn];
			Items.FormPasteValue.Enabled = True;
		EndIf;
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
			EndIf;
		EndDo;
		Items.FormPasteValue.Enabled = False;
	EndIf;
EndProcedure // PasteValue

 // -----------------------------------------------------------------------------
&AtClient
Procedure ShowFiletGroup(pCommand)
	Items.FilterGroup.Visible = Not Items.FilterGroup.Visible; 
	Items.ShowFiletGroup.Check = Items.FilterGroup.Visible;
 EndProcedure // ShowFiletGroup

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeStatusRoom(pCommand) 
	vCurRowId = Items.TableBoxRooms.CurrentRow;
	If vCurRowId <> Undefined Then
		vCurData = TableBoxRooms.FindByID(vCurRowId);
		If vCurData <> Undefined Then
			Id = Number(StrReplace(pCommand.Name, "ChangeStatus", ""));
			vItem = SelChangeStatusList.FindByID(Id);
			If vItem <> Undefined Then
				vCurData.RoomStatus = vItem.Value;
				
				vCurData.RoomStatusIcon = GetRoomStatusIconIndex(vCurData.RoomStatus);
				
				vOldRoomStatus = Undefined;
				vRoomStatusLastChangeTime = UpdateRoomStatus(vCurData.Ref, vCurData.RoomStatus, vOldRoomStatus);
				If vRoomStatusLastChangeTime <> Undefined Then
					vCurData.RoomStatusLastChangeTime = vRoomStatusLastChangeTime;
				EndIf;
				
				// Update room statuses statistics
				For Each vRoomStatusItem In TableBoxStatuses Do
					vRoomStatus = vRoomStatusItem.Value;
					If vRoomStatus = vOldRoomStatus Then
						vRoomStatusItem.Presentation = UpdateRoomStatusPresentation(vRoomStatusItem.Presentation, -1);
					ElsIf vRoomStatus = vCurData.RoomStatus Then
						vRoomStatusItem.Presentation = UpdateRoomStatusPresentation(vRoomStatusItem.Presentation, 1);
					EndIf;
				EndDo;
				FillStatuslist(vCurData.Ref, SelChangeStatusList);
				For Each vItemRow In SelChangeStatusList Do
					Items["FormButtonChangeStatus_" + vItemRow.GetID()].Visible = vItemRow.Check; 	
				EndDo;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ChangeStatusRoom

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
	
	// Check if all shortcuts are off
	If Not SelShowCheckedIn And Not SelShowCheckedOut 
		And Not SelShowPlannedCheckIn And Not SelShowPlannedCheckOut 
		And Not SelShowDirtyRooms And Not SelShowCleanRooms 
		And Not SelShowVacantRooms And Not SelShowOccupiedRooms 
		And Not SelShowRoomsWithTasks And Not SelShowRoomsWithDiscrepancies Then
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
			Or SelShowRoomsWithTasks Or SelShowRoomsWithDiscrepancies Then
			SelShowAllRooms = False;
		EndIf;
	EndIf;
	
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
		vNum = 0;
		While vNum < vRoomsList.Count() Do
			vRoom = vRoomsList.Get(vNum).Value;
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
				vRoomsList.Delete(vNum);
			Else
				vNum = vNum + 1;
			EndIf;
		EndDo;
	ElsIf SelShowVacantRooms Then
		vRoomsList = cmGetActiveRoomsList(SelHotel);
		vHotelGuests = GetRoomGuests(vRoomsList, CurrentSessionDate());
		vNum = 0;
		While vNum < vRoomsList.Count() Do
			vRoomGuests = vHotelGuests.FindRows(New Structure("Room", vRoomsList.Get(vNum).Value));
			If vRoomGuests.Count() > 0 Then
				vRoomsList.Delete(vNum);
			Else
				vNum = vNum + 1;
			EndIf;
		EndDo;
	ElsIf SelShowOccupiedRooms Then
		vRoomsList = cmGetActiveRoomsList(SelHotel);
		vHotelGuests = GetRoomGuests(vRoomsList, CurrentSessionDate());
		vNum = 0;
		While vNum < vRoomsList.Count() Do
			vRoomGuests = vHotelGuests.FindRows(New Structure("Room", vRoomsList.Get(vNum).Value));
			If vRoomGuests.Count() = 0 Then
				vRoomsList.Delete(vNum);
			Else
				vNum = vNum + 1;
			EndIf;
		EndDo;
	EndIf;
	
	// Build query to get all rooms
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodations.Room AS Room,
	|	Accommodations.Customer AS Customer,
	|	Accommodations.ClientType AS ClientType,
	|	Accommodations.AccommodationTemplate AS AccommodationTemplate,
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
	|	AND (&qRoomTypeIsEmpty
	|			OR NOT &qRoomTypeIsEmpty
	|				AND Accommodations.RoomType IN HIERARCHY (&qRoomType))
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
	|	AND (&qRoomTypeIsEmpty
	|			OR NOT &qRoomTypeIsEmpty
	|				AND Reservations.RoomType IN HIERARCHY (&qRoomType))
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
	|	AND (&qRoomTypeIsEmpty
	|			OR NOT &qRoomTypeIsEmpty
	|				AND ExpectedRoomMove.Ref.RoomType IN HIERARCHY (&qRoomType))
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
	|	AND (&qRoomTypeIsEmpty
	|			OR NOT &qRoomTypeIsEmpty
	|				AND Accommodations.RoomType IN HIERARCHY (&qRoomType))
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
	|	AND (&qRoomTypeIsEmpty
	|			OR NOT &qRoomTypeIsEmpty
	|				AND Accommodations.RoomType IN HIERARCHY (&qRoomType))
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
	|	AND (&qRoomTypeIsEmpty
	|			OR NOT &qRoomTypeIsEmpty
	|				AND Accommodations.RoomType IN HIERARCHY (&qRoomType))
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
	|	AND (&qRoomTypeIsEmpty
	|			OR NOT &qRoomTypeIsEmpty
	|				AND RoomBlocks.Room.RoomType IN HIERARCHY (&qRoomType))
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
	|	Rooms.Ref AS Ref
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
	|	AND (&qRoomTypeIsEmpty
	|			OR NOT &qRoomTypeIsEmpty
	|				AND Rooms.RoomType IN HIERARCHY (&qRoomType))
	|	AND (&qRoomSectionIsEmpty
	|			OR NOT &qRoomSectionIsEmpty
	|				AND Rooms.RoomSection IN HIERARCHY (&qRoomSection))
	|	AND (&qRoomFloorIsEmpty
	|			OR NOT &qRoomFloorIsEmpty
	|				AND Rooms.Floor = &qRoomFloor)
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
	vQry.SetParameter("qRoomTypeIsEmpty", Not ValueIsFilled(SelRoomType));
	vQry.SetParameter("qRoomType", SelRoomType);
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
	
	TableBoxRooms.GetItems().Clear();

	vCurParent = Undefined;
	vCurRoom = Undefined;
	For Each vRoomsRow In vRooms Do
		vDoAddRoom = True;
		If vCurRoom = vRoomsRow.Ref Then
			vDoAddRoom = False;
			If vRoomsRow.IsFolder Then
				Continue;
			EndIf;
		EndIf;
		vCurRoom = vRoomsRow.Ref;
		
		If ValueIsFilled(vCurRoom.Parent) Then
			vParentsRow = vParents.Find(vCurRoom.Parent, "Ref");
			If vParentsRow = Undefined Then
				vCurFolderItem = TableBoxRooms;
			Else
				vCurFolderItem = vParentsRow.Item;
			EndIf;
		Else
			vCurFolderItem = TableBoxRooms;
		EndIf;
		
		If vDoAddRoom Then
			vCurRoomItem = vCurFolderItem.GetItems().Add();
			FillPropertyValues(vCurRoomItem, vRoomsRow, , "NumberOfGuests, NumberOfGuestsOnArrival, Remarks");
			vCurRoomItem.Description = TrimAll(vRoomsRow.Description) + ?(ValueIsFilled(vRoomsRow.RoomType), " " + TrimAll(vRoomsRow.RoomType.Code), "");
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
					vCurRoomItem.Condition = vCurRoomItem.Condition + ?(IsBlankString(vCurRoomItem.Condition), "", ", ") + vRoomsRow.ExpectedRoomMoveClause + NStr("en=' in from room '; ru=' из номера '; de=' vom Zimmer '") + TrimAll(vRoomsRow.FromRoom);
				ElsIf vRoomsRow.Ref = vRoomsRow.FromRoom Then
					vCurRoomItem.Condition = vCurRoomItem.Condition + ?(IsBlankString(vCurRoomItem.Condition), "", ", ") + vRoomsRow.ExpectedRoomMoveClause + NStr("en=' out to room '; ru=' в номер '; de=' ins Zimmer '") + TrimAll(vRoomsRow.ToRoom);
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
	
	Return vRowId;
EndFunction // FillRoomsListAtServer

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
	vNum = StrLen(vPresentation);
	While vNum > 0 Do
		vChar = Mid(vPresentation, vNum, 1);
		If vNum = StrLen(vPresentation) And vChar <> ")" Then
			Break;
		ElsIf vChar = "(" Then
			vNum = vNum - 1;
			Break;
		ElsIf vChar <> ")" Then
			If vChar >= "0" And vChar <= "9" Then
				vNumStr = vChar + vNumStr;
			Else
				Break;
			EndIf;
		EndIf;
		vNum = vNum - 1;
	EndDo;
	If vNumStr = "" Then
		vNumStr = "0";
	EndIf;
	vNum = Number(vNumStr) + pNum;
	If vNum <= 0 Then
		Return TrimAll(Left(vPresentation, vNum));
	Else
		Return TrimAll(Left(vPresentation, vNum)) + " (" + Format(vNum, "NFD=0; NZ=; NG=") + ")";
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
	Return False;
EndFunction // RefreshRoomInListAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure FillStatuslist(pRoom, pStatusList)
	vRoomStatuses = cmGetAllowedRoomStatuses(SessionParameters.CurrentUser, pRoom.RoomStatus);
	pStatusList.FillChecks(False);
	For Each vItemRow In vRoomStatuses Do
		vItemsList = pStatusList.FindByValue(vItemRow.RoomStatus);	
		If vItemsList <> Undefined And vItemsList.Value <> pRoom.RoomStatus Then
			vItemsList.Check = True	
		EndIf;
	EndDo; 
EndProcedure // FillStatuslist

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

// -----------------------------------------------------------------------------
&AtClient
Procedure TableBoxRoomsRefreshRequestProcessing()
	FillRoomsList();
EndProcedure // TableBoxRoomsRefreshRequestProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure CloseFormSetRoomBlock(pResult, pExtraParams) Export 
	 FillRoomsList();	
EndProcedure // CloseFormSetRoomBlock

// -----------------------------------------------------------------------------
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
EndProcedure

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
		EndIf;
	EndIf;
EndProcedure // TableBoxRoomsOnActivateCell

#EndRegion
