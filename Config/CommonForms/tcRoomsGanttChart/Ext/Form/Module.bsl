
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
	
	// Initialization
	vRoomsPerPage = SystemSettingsStorage.Load("tcRoomsGanttChartRoomsPerPage", SessionParameters.CurrentUser);
	If vRoomsPerPage <> Undefined Then
		RoomsPerPage = vRoomsPerPage;
	Else
		RoomsPerPage = 30;
	EndIf;
	CurrentPage = 1;
	LastPage = 1;
	OnOpenMode = True;
	FontScale = 100;
	SelHotel = SessionParameters.CurrentHotel;
	SelShowRoomsByRoomTypes = False;
	vShowRoomsByRoomTypes = SystemSettingsStorage.Load("tcRoomsGanttChartShowRoomsByRoomTypes", SessionParameters.CurrentUser);
	If vShowRoomsByRoomTypes <> Undefined Then
		SelShowRoomsByRoomTypes = vShowRoomsByRoomTypes;
	EndIf;
	SelIntersection = False;
	SelShowExpectedChangeRoomOnly = False;
	SelPeriodDateFrom = '00010101';
	SelPeriodDateTo = '00010101';
	SelPeriodFrom = BegOfDay(CurrentSessionDate()) - 1*3600*24;
	If Parameters.Property("SelPeriodFrom") And ValueIsFilled(Parameters.SelPeriodFrom) Then
		SelPeriodFrom = Parameters.SelPeriodFrom;
	EndIf;
	vShowBookingsWithoutRooms = SystemSettingsStorage.Load("tcRoomsGanttChartShowBookingsWithoutRooms", SessionParameters.CurrentUser);
	If vShowBookingsWithoutRooms <> Undefined Then
		SelShowBookingsWithoutRooms = vShowBookingsWithoutRooms;
	Else
		SelShowBookingsWithoutRooms = False;
	EndIf;
	If Parameters.Property("SelShowBookingsWithoutRooms") And TypeOf(Parameters.SelShowBookingsWithoutRooms) = Type("Boolean") Then
		SelShowBookingsWithoutRooms = Parameters.SelShowBookingsWithoutRooms;
	EndIf;
	vShowPreliminary = SystemSettingsStorage.Load("tcRoomsGanttChartShowPreliminary", SessionParameters.CurrentUser);
	If vShowPreliminary <> Undefined Then
		SelShowPreliminary = vShowPreliminary;
	Else
		SelShowPreliminary = False;
	EndIf;
	If Parameters.Property("SelShowPreliminary") And TypeOf(Parameters.SelShowPreliminary) = Type("Boolean") Then
		SelShowPreliminary = Parameters.SelShowPreliminary;
	EndIf;
	If Parameters.Property("SelRoom") And ValueIsFilled(Parameters.SelRoom) Then
		SelRoom = Parameters.SelRoom;
	EndIf;
	SelRoomTypes.Clear();
	If Parameters.Property("SelRoomType") And ValueIsFilled(Parameters.SelRoomType) Then
		If Parameters.SelRoomType.IsFolder Then
			SelRoomType = Parameters.SelRoomType;
		Else
			SelRoomTypes.Add(Parameters.SelRoomType);
		EndIf;
	EndIf;
	If Parameters.Property("SelRoomTypes") And TypeOf(Parameters.SelRoomTypes) = Type("ValueList") Then
		For Each vRoomTypesItem In Parameters.SelRoomTypes Do
			If SelRoomTypes.FindByValue(vRoomTypesItem.Value) = Undefined Then
				SelRoomTypes.Add(vRoomTypesItem.Value);
			EndIf;
		EndDo;
	EndIf;
	If Parameters.Property("SelRoomClass") And ValueIsFilled(Parameters.SelRoomClass) Then
		SelRoomClass = Parameters.SelRoomClass;
	EndIf;
	If Parameters.Property("SelRoomSection") And ValueIsFilled(Parameters.SelRoomSection) Then
		SelRoomSection = Parameters.SelRoomSection;
	EndIf;
	SelShowHotelProduct = True;
	SelShowGuestShortName = True;
	SelShowGuestFullName = True;
	SelShowClientType = True;
	SelShowGuestGroup = True;
	SelShowAgent = True;
	SelShowContract = True;
	SelShowCustomer = True;
	SelShowAccommodationType = True;
	SelShowRoomQuota = True;
	SelShowAllGuests = 0;
	SpreadsheetScale = 1;
	vSpreadsheetScale = SystemSettingsStorage.Load("tcRoomsGanttChartSpreadsheetScale", SessionParameters.CurrentUser);
	If vSpreadsheetScale <> Undefined Then
		SpreadsheetScale = vSpreadsheetScale;
	EndIf;
	MaxRowIndex = 0;
	ColorCellIndexFrom = 0;
	ColorCellIndexTo = 0;
	CurrentDateCellFrom = 0;
	CurrentDateCellTo = 0;
	LastSelectedPeriodIndex = -1;
	FillMonthes();
	
	LoadColorsFromHotel();

	// Set hotel color          
	Items.GroupHeader.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
	
	// Fill parameters
	Items.GuestGroupClientType.ChoiceList.LoadValues(GetArrayOfAllClientTypes());
	Items.GuestGroupSourceOfBusiness.ChoiceList.LoadValues(GetArrayOfAllSourceOfBusiness());
	
	// Check platform version
	Items.Spreadsheet.VerticalStretch = True;
	RoomPlanner.FixDimensionsHeader = True;
	RoomPlanner.FixTimeScaleHeader = True;
	RoomPlanner.ItemsBehaviorWhenSpaceInsufficient = PlannerItemsBehaviorWhenSpaceInsufficient.ShowAllItems;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	If tcOnClient.IsHomePageWindow(ThisObject) Then
		vPrefix = NStr("en = 'Rooms gantt chart: '; de = 'Karte des Zimmerbestandes: '; ru = 'Карта номерного фонда: '");
		tcCommonFunctionOnClientServer.cmSetFormTitleHotelName(ThisObject, vPrefix);
	EndIf;
	AttachIdleHandler("RefreshList", 0.1, True);
EndProcedure // OnOpen

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "Document.Reservation.Write" Or 
	   pEventName = "Document.Reservation.WriteNew" Or 
	   pEventName = "Document.Accommodation.Write" Or 
	   pEventName = "Document.Accommodation.WriteNew" Or
	   pEventName = "Document.SetRoomBlock.Write" Or
	   pEventName = "Document.SetRoomBlock.WriteListRoom" Or
	   pEventName = "Document.Payment.Write" Or
	   pEventName = "Document.Return.Write" Or
	   pEventName = "Document.DepositTransfer.Write" Or
	   pEventName = "Document.Preauthorisation.Write" Or
	   pEventName = "Document.Charge.Write" Or
	   pEventName = "Document.ChargeTransfer.Write" Or
	   pEventName = "Document.Storno.Write" Or 
	   pEventName = "Subsystem.Accounts.Changed" Or
	   pEventName = "Catalog.GuestGroups.Changed" Then
		CurrentItem = Items.SelGuestStr;
		AttachIdleHandler("RefreshFormIdleHandler", 0.5, True);
	ElsIf pEventName = "System.Hotel.Changed" And pParameter <> SelHotel Then	
		SelHotel = pParameter;
		If tcOnClient.IsHomePageWindow(ThisObject) Then
			vPrefix = NStr("en = 'Rooms gantt chart: '; de = 'Karte des Zimmerbestandes: '; ru = 'Карта номерного фонда: '");
			tcCommonFunctionOnClientServer.cmSetFormTitleHotelName(ThisObject, vPrefix);
		EndIf;
		FillRoomPlannerAtClient();
	EndIf;
EndProcedure // NotificationProcessing

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SpreadsheetScaleOnChange(pItem)
	FillRoomPlannerAtClient();
EndProcedure // SpreadsheetScaleOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelShowAllGuestsOnChange(pItem)
	Refresh(Undefined);
EndProcedure // SelShowAllGuestsOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelPeriodFromOnChange(pItem)
	FillRoomPlannerAtClient();
EndProcedure // SelPeriodFromOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomSectionOnChange(Item)
	FillRoomPlannerAtClient();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomOnChange(Item)
	FillRoomPlannerAtClient();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomTypeOnChange(pItem)
	FillRoomPlannerAtClient();
EndProcedure // SelRoomTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomClassOnChange(pItem)
	FillRoomPlannerAtClient();
EndProcedure // SelRoomClassOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelGuestStrOnChange(Item)
	FillRoomPlannerAtClient();
	AttachIdleHandler("SetFocusToGuestStrItem", 0.1, True);
EndProcedure // SelGuestStrOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SetFocusToGuestStrItem() Export
	ThisObject.CurrentItem = Items.SelGuestStr;
EndProcedure // SetFocusToGuestStrItem

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupCreationModeOnChange(pItem)
	If GuestGroupCreationMode Then
		Items.GuestGroup.Visible = True;
		Items.GuestGroupDescription.Visible = True;
		Items.GroupGuestGroupAttributes.Visible = True;
	Else
		Items.GuestGroup.Visible = False;
		Items.GuestGroupDescription.Visible = False;
		Items.GroupGuestGroupAttributes.Visible = False;
		
		// Clear selected periods
		ClearSelectedReservationPeriods();
	EndIf;
	BuildSettingsCollapsedTitle();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearSelectedReservationPeriods()
	// Clear selected periods
	i = 0;
	While i < SelectedReservationPeriods.Count() Do
		vItem = RoomPlanner.Items.Find(i);
		If vItem <> Undefined Then
			RoomPlanner.Items.Delete(vItem);
		EndIf;
		i = i + 1;
	EndDo;
	SelectedReservationPeriods.Clear();
EndProcedure // ClearSelectedReservationPeriods

// -----------------------------------------------------------------------------
&AtClient
Procedure SelShowRoomsByRoomTypesOnChange(pItem)
	FillRoomPlannerAtClient();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelMonthOnChange(pItem)
	vMonthNum = SelMonth;
	If vMonthNum = 0 Then
		SelPeriodFrom = BegOfDay(CurrentDate()) - 1*3600*24;
	Else
		vThisYear = Year(CurrentDate());
		vCurMonth = Month(CurrentDate());
		If vMonthNum < vCurMonth Then
			SelPeriodFrom = Date(vThisYear + 1, vMonthNum, 1, 0, 0, 0);
		Else
			SelPeriodFrom = Date(vThisYear, vMonthNum, 1, 0, 0, 0);
		EndIf;
	EndIf;
	SelPeriodFromOnChange(Items.SelPeriodFrom);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelShowBookingsWithoutRoomsOnChange(pItem)
	FillRoomPlannerAtClient();
EndProcedure // SelShowBookingsWithoutRoomsOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelShowPreliminaryOnChange(pItem)
	FillRoomPlannerAtClient();
EndProcedure // SelShowPreliminaryOnChange

#EndRegion

#Region FormTableItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SpreadsheetOnCurrentRepresentationPeriodChange(pItem, pCurrentRepresentationPeriods, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SpreadsheetOnActivate(pItem, pStandardProcessing)
	pStandardProcessing = False;
	LastSelectedDocument = Undefined;
	LastSelectedPeriodIndex = -1;
	If pItem.SelectedItems.Count()>0 Then
		vItemSelected =  pItem.SelectedItems[0].Value;
		If TypeOf(vItemSelected) = Type("Number") Then
			// Common
			Items.SpreadsheetContextMenuRefresh.Visible	 			= False;
			// Reserv
			Items.SpreadsheetContextMenuCheckIn.Visible	 			= False;
			Items.SpreadsheetContextMenuOpenFolio.Visible			= False;
			Items.SpreadsheetContextMenuOpen.Visible				= False;
			Items.SpreadsheetContextMenuOpenGuestGroup.Visible		= False;
			// Accom
			Items.SpreadsheetContextMenuCheckOut.Visible			= False;
			Items.SpreadsheetContextMenuOpenFolioAcc.Visible		= False;
			Items.SpreadsheetContextMenuOpenAcc.Visible				= False;
			Items.SpreadsheetContextMenuOpenGuestGroupAcc.Visible	= False;
			// Period
			Items.SpreadsheetContextMenuDeletePeriod.Visible 		= True;

			LastSelectedPeriodIndex = vItemSelected;
		ElsIf TypeOf(vItemSelected) = Type("Structure") Then
			If TypeOf(vItemSelected.Document) = Type("DocumentRef.Accommodation") Then
				// Common
				Items.SpreadsheetContextMenuRefresh.Visible	 			= True;
				// Reserv
				Items.SpreadsheetContextMenuCheckIn.Visible	 			= False;
				Items.SpreadsheetContextMenuOpenFolio.Visible			= False;
				Items.SpreadsheetContextMenuOpen.Visible				= False;
				Items.SpreadsheetContextMenuOpenGuestGroup.Visible		= False;
				// Accom
				Items.SpreadsheetContextMenuCheckOut.Visible			= CheckIsCheckOut(vItemSelected.Document);
				Items.SpreadsheetContextMenuOpenFolioAcc.Visible		= True;
				Items.SpreadsheetContextMenuOpenAcc.Visible				= True;
				Items.SpreadsheetContextMenuOpenGuestGroupAcc.Visible	= True;
				// Period
				Items.SpreadsheetContextMenuDeletePeriod.Visible 		= False;
				
				LastSelectedDocument = vItemSelected.Document;
			ElsIf TypeOf(vItemSelected.Document) = Type("DocumentRef.Reservation") Then	
				// Common
				Items.SpreadsheetContextMenuRefresh.Visible	 			= True;
				// Reserv
				Items.SpreadsheetContextMenuCheckIn.Visible	 			= CheckIsCheckIn(vItemSelected.Document);
				Items.SpreadsheetContextMenuOpenFolio.Visible			= True;
				Items.SpreadsheetContextMenuOpen.Visible				= True;
				Items.SpreadsheetContextMenuOpenGuestGroup.Visible		= True;
				// Accom
				Items.SpreadsheetContextMenuCheckOut.Visible			= False;
				Items.SpreadsheetContextMenuOpenFolioAcc.Visible		= False;
				Items.SpreadsheetContextMenuOpenAcc.Visible				= False;
				Items.SpreadsheetContextMenuOpenGuestGroupAcc.Visible	= False;
				// Period
				Items.SpreadsheetContextMenuDeletePeriod.Visible 		= False;
				
				LastSelectedDocument = vItemSelected.Document;
			Else 
				// Common
				Items.SpreadsheetContextMenuRefresh.Visible	 			= True;
				// Reserv
				Items.SpreadsheetContextMenuCheckIn.Visible	 			= False;
				Items.SpreadsheetContextMenuOpenFolio.Visible			= False;
				Items.SpreadsheetContextMenuOpen.Visible				= True;
				Items.SpreadsheetContextMenuOpenGuestGroup.Visible		= False;
				// Accom
				Items.SpreadsheetContextMenuCheckOut.Visible			= False;
				Items.SpreadsheetContextMenuOpenFolioAcc.Visible		= False;
				Items.SpreadsheetContextMenuOpenAcc.Visible				= False;
				Items.SpreadsheetContextMenuOpenGuestGroupAcc.Visible	= False;
				// Period
				Items.SpreadsheetContextMenuDeletePeriod.Visible 		= False;
				
				If TypeOf(vItemSelected.Document) = Type("DocumentRef.SetRoomBlock") Then	
					LastSelectedDocument = vItemSelected.Document;
				EndIf;
			EndIf;	
		Else 
			// Common
			Items.SpreadsheetContextMenuRefresh.Visible	 			= True;
			// Reserv
			Items.SpreadsheetContextMenuCheckIn.Visible	 			= False;
			Items.SpreadsheetContextMenuOpenFolio.Visible			= False;
			Items.SpreadsheetContextMenuOpen.Visible				= False;
			Items.SpreadsheetContextMenuOpenGuestGroup.Visible		= False;
			// Accom
			Items.SpreadsheetContextMenuCheckOut.Visible			= False;
			Items.SpreadsheetContextMenuOpenFolioAcc.Visible		= False;
			Items.SpreadsheetContextMenuOpenAcc.Visible				= False;
			Items.SpreadsheetContextMenuOpenGuestGroupAcc.Visible	= False;
			// Period
			Items.SpreadsheetContextMenuDeletePeriod.Visible 		= False;
		EndIf;	
	Else 
		// Common
		Items.SpreadsheetContextMenuRefresh.Visible		 			= True;
		// Reserv
		Items.SpreadsheetContextMenuCheckIn.Visible		 			= False;
		Items.SpreadsheetContextMenuOpenFolio.Visible				= False;
		Items.SpreadsheetContextMenuOpen.Visible					= False;
		Items.SpreadsheetContextMenuOpenGuestGroup.Visible			= False;
		// Accom
		Items.SpreadsheetContextMenuCheckOut.Visible				= False;
		Items.SpreadsheetContextMenuOpenFolioAcc.Visible			= False;
		Items.SpreadsheetContextMenuOpenAcc.Visible					= False;
		Items.SpreadsheetContextMenuOpenGuestGroupAcc.Visible		= False;
		// Period
		Items.SpreadsheetContextMenuDeletePeriod.Visible 			= False;
	EndIf;	
EndProcedure // SpreadsheetOnActivate

// -----------------------------------------------------------------------------
&AtClient
Procedure SpreadsheetBeforeStartEdit(pItem, pNewItem, pStandardProcessing)
	pStandardProcessing = False;
	For Each vDoc In pItem.SelectedItems Do
		If TypeOf(vDoc.Value) = Type("Structure") And ValueIsFilled(vDoc.Value.Document) Then
			vDocument = GetMainRoomDocument(vDoc.Value.Document);
			If Not ValueIsFilled(vDocument) Then
				vDocument = vDoc.Value.Document;
			EndIf;
			ShowValue(, vDocument);
			LastSelectedDocument = vDocument;
		EndIf;	
	EndDo;
EndProcedure // SpreadsheetBeforeStartEdit

// -----------------------------------------------------------------------------
&AtClient
Procedure SpreadsheetBeforeStartQuickEdit(pItem, pStandardProcessing)
	pStandardProcessing = False;
	If pItem.SelectedItems.Count() > 0 Then
		For Each vDoc In pItem.SelectedItems Do
			If TypeOf(vDoc.Value) <> Type("Structure") And TypeOf(vDoc.Value) <> Type("Number") And ValueIsFilled(vDoc.Value) Then 
				If TypeOf(vDoc.Value) = Type("CatalogRef.RoomStatuses") Then
					vRoomStatus = vDoc.Value;
					vRoom = vDoc.DimensionValues.Get("Room");
					vRoomStatusesList = New ValueList();
					If tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToChangeRoomStatuses") Then
						vRoomStatusesList = GetRoomStatusesListAtServer(vRoomStatus, vRoom);
					EndIf;
					If tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToSetRoomBlocks") Or 
					   tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToStopSaleRooms") Then
						AddRoomItemToListAtServer(vRoomStatusesList, vRoom);
					EndIf;
					If vRoomStatusesList.Count() > 0 Then
						ShowChooseFromMenu(New NotifyDescription("RoomStatusChoiceCompleted", ThisObject, New Structure("Room, PlannerItem", vRoom, vDoc)), vRoomStatusesList, pItem);
					EndIf;
				Else
					vDocument = GetMainRoomDocument(vDoc.Value);
					If Not ValueIsFilled(vDocument) Then
						vDocument = vDoc.Value;
					EndIf;
					ShowValue(, vDocument);
				EndIf;
			ElsIf TypeOf(vDoc.Value) = Type("Structure") And ValueIsFilled(vDoc.Value.Document) Then
				vDocument = GetMainRoomDocument(vDoc.Value.Document);
				If Not ValueIsFilled(vDocument) Then
					vDocument = vDoc.Value.Document;
				EndIf;
				ShowValue(, vDocument);
			EndIf;
		EndDo;
	Else
		If ValueIsFilled(LastSelectedDocument) Then
			ShowValue(, LastSelectedDocument);
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SpreadsheetSelection(pItem, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure // SpreadsheetSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure SpreadsheetOnEditEnd(pItem, pNewItem, pCancelEdit)
	If Not SelAllowDragEdit Then
		pCancelEdit = True;
		ShowQueryBox(New NotifyDescription("DoAllowDragEditQueryAfterAnswer", ThisObject), NStr("en='Do allow edit documents by drag?'; ru='Разрешить редактировать документы путем перетаскивания?'; de='Erlauben Sie das Bearbeiten von Dokumenten per Ziehen?'"), QuestionDialogMode.YesNo, 5, DialogReturnCode.No);
		Return;
	EndIf;
	
	If pItem.SelectedItems.Count() = 0 Then
		pCancelEdit = True;
		Return;
	ElsIf pItem.SelectedItems.Count() > 1 Then
		pCancelEdit = True;
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Please select one item!'; ru='Пожалуйста выделите один элемент!'; de='Bitte wählen Sie einen Artikel aus!'"));
		Return;
	EndIf;
	vChangedItem = pItem.SelectedItems.Get(0);
	If TypeOf(vChangedItem.Value) = Type("Structure") Then
		// Document to process
		vDoc = vChangedItem.Value.Document;
		
		vOldStart = vChangedItem.Value.StartPeriod;
		vOldEnd = vChangedItem.Value.EndPeriod;
		vOldRoom = vChangedItem.Value.Room;
		vOldRoomType = Undefined;
		If Not ValueIsFilled(vOldRoom) And ValueIsFilled(vDoc) Then
			vOldRoomType = tcOnServer.cmGetAttributeByRef(vDoc, "RoomType");
		ElsIf TypeOf(vOldRoom) = Type("CatalogRef.Rooms") And ValueIsFilled(vOldRoom) And Not tcOnServer.cmGetAttributeByRef(vOldRoom, "IsFolder") Then
			vOldRoomType = tcOnServer.cmGetAttributeByRef(vOldRoom, "RoomType");
		EndIf;
		
		vNewStart = vChangedItem.Begin;
		vNewEnd = vChangedItem.End;
		vNewRoom = vChangedItem.DimensionValues.Get("Room");
		vNewRoomType = Undefined;
		If TypeOf(vNewRoom) = Type("Number") And vNewRoom > 0 Then
			For Each vOvbIndxItem In OverbookingIndexesRoomTypes Do
				If vOvbIndxItem.Presentation = Format(vNewRoom, "NFD=0; NG=") Then
					vNewRoomType = vOvbIndxItem.Value;
					Break;
				EndIf;
			EndDo;
			vNewRoom = Undefined;
		ElsIf TypeOf(vNewRoom) = Type("CatalogRef.Rooms") And ValueIsFilled(vNewRoom) And Not tcOnServer.cmGetAttributeByRef(vNewRoom, "IsFolder") Then
			vNewRoomType = tcOnServer.cmGetAttributeByRef(vNewRoom, "RoomType");
		EndIf;
		
		vToolTip = vChangedItem.ToolTip;
		
		// Check if we have to swap rooms for reservations
		vSwapRoundReservation = Undefined;
		If vNewRoom <> vOldRoom And 
		   TypeOf(vNewRoom) = Type("CatalogRef.Rooms") And ValueIsFilled(vNewRoom) And 
		   TypeOf(vOldRoom) = Type("CatalogRef.Rooms") And ValueIsFilled(vOldRoom) And 
		   ValueIsFilled(vDoc) And 
		   TypeOf(vDoc) = Type("DocumentRef.Reservation") Then
			vSwapRoundReservation = GetIntersectedReservation(vNewRoom, vOldStart, vOldEnd);
			vExtraParams = New Structure("ChangedItem, Doc, OldRoom, OldRoomType, OldStart, OldEnd, NewStart, NewEnd, NewRoom, NewRoomType, ToolTip, SwapRoundReservation", vChangedItem, vDoc, vOldRoom, vOldRoomType, vOldStart, vOldEnd, vNewStart, vNewEnd, vNewRoom, vNewRoomType, vToolTip, vSwapRoundReservation);
			If ValueIsFilled(vSwapRoundReservation) Then
				vQuestion = NStr("en='Swap around room with '; 
				                 |ru='Поменять местами номера с '; 
								 |de='Tauschen Zimmeren mit '") +
				            TrimAll(vSwapRoundReservation) + "?";
				ShowQueryBox(New NotifyDescription("AfterReservationIntersectionCheck", ThisObject, vExtraParams), vQuestion, QuestionDialogMode.YesNoCancel, , DialogReturnCode.No);
				pCancelEdit = True;
				Return;
			ElsIf vNewRoomType <> vOldRoomType And Not ValueIsFilled(tcOnServer.cmGetAttributeByRef(vDoc, "RoomTypeUpgrade")) Then
				vQuestion = NStr("en='Recalculate reservation room prices according to the new room type?'; 
				                 |ru='Пересчитать цены брони согласно новому типу номера?'; 
								 |de='Buchungspreise nach neuen Zimmertyp neu berechnen?'");
				ShowQueryBox(New NotifyDescription("AfterRoomTypeChangeBehaviourAnswer", ThisObject, vExtraParams), vQuestion, QuestionDialogMode.YesNo, , DialogReturnCode.No);
				pCancelEdit = True;
				Return;
			EndIf;
		EndIf;
				
		vMessage = "";
		pCancelEdit = ProcessItemChangeAtServer(vDoc, vOldStart, vOldEnd, vOldRoom, vOldRoomType, vNewStart, vNewEnd, vNewRoom, vNewRoomType, vToolTip, vMessage);
		If Not pCancelEdit Then
			vChangedItem.ToolTip = vToolTip;
			If vOldStart = vNewStart And vOldEnd = vNewEnd Then
				vChangedItem.Begin = vOldStart;
				vChangedItem.End = vOldEnd;
			EndIf;
		EndIf;
		
		If Not IsBlankString(vMessage) Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage);
		EndIf;
		
		AttachIdleHandler("FillRoomPlannerIdleHandler", 0.1, True);
	ElsIf TypeOf(vChangedItem.Value) = Type("Number") Then
		vPeriodIdx = vChangedItem.Value;
		vPeriodRow = SelectedReservationPeriods.Get(vPeriodIdx);
		
		vOldStart = vPeriodRow.DateFrom;
		vOldEnd = vPeriodRow.DateTo;
		vOldRoom = vPeriodRow.Room;
		vOldRoomType = vPeriodRow.RoomType;
		vOldOverbookingIndex = vPeriodRow.OverbookingIndex;
		
		vNewStart = vChangedItem.Begin;
		vNewEnd = vChangedItem.End;
		vNewRoom = vChangedItem.DimensionValues.Get("Room");
		vNewRoomType = Undefined;
		vNewOverbookingIndex = 0;
		If TypeOf(vNewRoom) = Type("Number") And vNewRoom > 0 Then
			For Each vOvbIndxItem In OverbookingIndexesRoomTypes Do
				If vOvbIndxItem.Presentation = Format(vNewRoom, "NFD=0; NG=") Then
					vNewOverbookingIndex = vOvbIndxItem.Value;
					Break;
				EndIf;
			EndDo;
			vNewRoom = Undefined;
		ElsIf TypeOf(vNewRoom) = Type("CatalogRef.Rooms") And ValueIsFilled(vNewRoom) Then
			If Not tcOnServer.cmGetAttributeByRef(vNewRoom, "IsFolder") Then
				vNewRoomType = tcOnServer.cmGetAttributeByRef(vNewRoom, "RoomType");
			Else
				pCancelEdit = True;
				Return;
			EndIf;
		EndIf;
		
		If vNewStart <> vOldStart Or vNewEnd <> vOldEnd Then
			vPeriodRow.DateFrom = BegOfDay(vNewStart) + (vPeriodRow.DateFrom - BegOfDay(vPeriodRow.DateFrom));
			vPeriodRow.DateTo = BegOfDay(vNewEnd) + (vPeriodRow.DateTo - BegOfDay(vPeriodRow.DateTo));
			
			vChangedItem.Begin = vPeriodRow.DateFrom;
			vChangedItem.End = vPeriodRow.DateTo;
		EndIf;
		If vOldRoom <> vNewRoom Or vOldOverbookingIndex <> vNewOverbookingIndex Then
			vPeriodRow.Room = vNewRoom;
			vPeriodRow.RoomType = vNewRoomType;
			vPeriodRow.OverbookingIndex = vNewOverbookingIndex;
		EndIf;
	Else
		pCancelEdit = True;
		Return;
	EndIf;
EndProcedure // SpreadsheetOnEditEnd

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetDefaultCheckInDate(pDate, pRoomRate, pHotel)
	vCheckInDate = pDate;
	vRoomRate = pRoomRate;
	If Not ValueIsFilled(vRoomRate) And ValueIsFilled(pHotel) Then
		vRoomRate = pHotel.RoomRate;
	EndIf;
	If ValueIsFilled(vRoomRate) Then
		If ValueIsFilled(vRoomRate.DefaultCheckInTime) Then
			vCheckInDate = cm1SecondShift(BegOfDay(vCheckInDate) + (vRoomRate.DefaultCheckInTime - BegOfDay(vRoomRate.DefaultCheckInTime)));
		ElsIf vRoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour Then
			vCheckInDate = cm1SecondShift(BegOfDay(vCheckInDate) + (vRoomRate.ReferenceHour - BegOfDay(vRoomRate.ReferenceHour)));
		Else
			vCheckInDate = cm1SecondShift(BegOfDay(vCheckInDate) + 8*3600);
		EndIf;
	Else
		vCheckInDate = cm1SecondShift(BegOfDay(vCheckInDate) + 8*3600);
	EndIf;
	Return vCheckInDate;
EndFunction // GetDefaultCheckInDate

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetDefaultCheckOutDate(pDate, pRoomRate, pHotel)
	vCheckOutDate = pDate;
	vRoomRate = pRoomRate;
	If Not ValueIsFilled(vRoomRate) And ValueIsFilled(pHotel) Then
		vRoomRate = pHotel.RoomRate;
	EndIf;
	If ValueIsFilled(vRoomRate) Then
		If ValueIsFilled(vRoomRate.DefaultCheckOutTime) Then
			vCheckOutDate = cm0SecondShift(BegOfDay(vCheckOutDate) + (vRoomRate.DefaultCheckOutTime - BegOfDay(vRoomRate.DefaultCheckOutTime)));
		ElsIf vRoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour Then
			vCheckOutDate = cm0SecondShift(BegOfDay(vCheckOutDate) + (vRoomRate.ReferenceHour - BegOfDay(vRoomRate.ReferenceHour)));
		Else
			vCheckOutDate = cm0SecondShift(BegOfDay(vCheckOutDate) + 20*3600);
		EndIf;
	Else
		vCheckOutDate = cm0SecondShift(BegOfDay(vCheckOutDate) + 20*3600);
	EndIf;
	Return vCheckOutDate;
EndFunction // GetDefaultCheckOutDate

// -----------------------------------------------------------------------------
&AtClient
Procedure SpreadsheetBeforeCreate(pItem, pBegin, pEnd, pValues, pText, pStandardProcessing)
	pStandardProcessing = False;
	If BegOfDay(pBegin) = pBegin And BegOfDay(pEnd) = pEnd Then
		// This is one click over empty period
		vIsClick = False;
		If SpreadsheetScale = 0.1 And (pEnd - pBegin) = (4*3600) Then
			vIsClick = True;
		ElsIf (pEnd - pBegin) = (24*3600) Then
			vIsClick = True;
		EndIf;
		If vIsClick Then
			If pValues.Count() > 0 Then
				vClickRoom = pValues.Get("Room");
				vClickDate = BegOfDay(pBegin);
				HiglightRoomAndDate(vClickRoom, vClickDate);
			EndIf;
			Return;
		EndIf;
	EndIf;
	SelCheckInDate = BegOfDay(pBegin);
	SelCheckOutDate = BegOfDay(pEnd);
	vOverbookingIndex = 0;
	If pValues.Count() > 0 Then
		CurRoomType = Undefined;
		CurRoom = pValues.Get("Room");
		If Not ValueIsFilled(CurRoom) Then
			vOverbookingIndex = pValues.Get("Room");
			If TypeOf(vOverbookingIndex) = Type("Number") And vOverbookingIndex > 0 Then
				For Each vOverbookingIndexesRoomTypesItem In OverbookingIndexesRoomTypes Do
					If vOverbookingIndexesRoomTypesItem.Presentation = Format(vOverbookingIndex, "NFD=0; NG=") Then
						CurRoomType = vOverbookingIndexesRoomTypesItem.Value;
						Break;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		If Not ValueIsFilled(CurRoom) Or ValueIsFilled(CurRoom) And Not tcOnServer.cmGetAttributeByRef(CurRoom, "IsFolder") Then
			If Not GuestGroupCreationMode Then
				If SelCheckInDate > CurrentDate() Then
					Reserv(Undefined);
				Else
					vMenuList = New ValueList();
					vMenuList.Add(1, NStr("en='New reservation...'; ru='Забронировать...'; de='Neue Reservierung...'"), False, PictureLib.Reserved);
					vMenuList.Add(2, NStr("en='Check-in...'; ru='Поселить...'; de='Check-in...'"), False, PictureLib.CheckIn);
					vMenuList.ShowChooseItem(New NotifyDescription("SpreadsheetBeforeCreate_AfterInput", ThisObject, New Structure()), NStr("en = 'Select an action..'; ru = 'Выберите действие..'; de = 'Wählen Sie eine Aktion..'"));
				EndIf;
			Else
				vCheckInDate = GetDefaultCheckInDate(SelCheckInDate, RoomRate, SelHotel);
				vCheckOutDate = GetDefaultCheckOutDate(SelCheckOutDate, RoomRate, SelHotel);
				// Add period to the form table
				vPerRow = SelectedReservationPeriods.Add();
				vPerRow.DateFrom = vCheckInDate;
				vPerRow.DateTo = vCheckOutDate;
				vPerRow.Room = CurRoom;
				vPerRow.RoomType = CurRoomType;
				vPerRow.OverbookingIndex = vOverbookingIndex;
				// Add period to the chart
				vItem = RoomPlanner.Items.Add(Max(vPerRow.DateFrom, BegOfDay(SelPeriodFrom)), vPerRow.DateTo); // max is needed to avoid intersections with room status items
				vDims = New Map;
				vDims.Insert("Room", ?(ValueIsFilled(vPerRow.Room), vPerRow.Room, vPerRow.OverbookingIndex));
				vItem.DimensionValues = New FixedMap(vDims);
				vItem.BackColor = WebColors.Brown;
				vItem.TextColor = WebColors.White;
				If Not tcOnServer.cmGetAttributeByRef(SelHotel, "DoNotShowTooltipsInRoomsGanttChart") Then
					vItem.ToolTip = "" + ?(ValueIsFilled(GuestGroup), Format(tcOnServer.cmGetAttributeByRef(GuestGroup, "Code"), "NFD=0; NG=") + " ", "") + TrimAll(GuestGroupDescription) + Chars.LF + 
					                ?(ValueIsFilled(vPerRow.Room), TrimAll(vPerRow.Room) + ", ", TrimAll(tcOnServer.cmGetAttributeByRef(vPerRow.RoomType, "Code")) + ", ") + Format(vPerRow.DateFrom, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(vPerRow.DateTo, "DF='dd.MM.yyyy HH:mm'");
				Else
					vItem.ToolTip = "";
				EndIf;
				vItem.Text = TrimAll(GuestGroupDescription);
				// Value
				vItem.Value = SelectedReservationPeriods.IndexOf(vPerRow);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // SpreadsheetBeforeCreate

// -----------------------------------------------------------------------------
&AtClient
Procedure SpreadsheetBeforeDelete(pItem, pCancel)
	pCancel = True;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenDoc(Command)
	vItemSelected =  Items.Spreadsheet.SelectedItems;
	If vItemSelected.Count()>0 Then
		If TypeOf(vItemSelected.Get(0).Value) = Type("Structure") Then
			vObj = vItemSelected.Get(0).Value.Document;
			ShowValue(, vObj);
		EndIf;
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenFolio(Command)
	// APDEX
	vKeyOperation = "CommonForm.tcFoliosForm.OpenForm";
	vUUID = New UUID;
	APDEXPerformanceSystemOnClientServer.StartManualTimeIntervalMeasurement(vKeyOperation, vUUID);

	vItemSelected =  Items.Spreadsheet.SelectedItems;
	If vItemSelected.Count() > 0 Then
		If TypeOf(vItemSelected.Get(0).Value) = Type("Structure") Then
			vObj = vItemSelected.Get(0).Value.Document;
			If TypeOf(vObj) = Type("DocumentRef.Accommodation") Or TypeOf(vObj) = Type("DocumentRef.Reservation") Then
				vParametersStructure = New Structure("DocRef", vObj);
				OpenForm("CommonForm.tcFoliosForm", New Structure("ParametersStructure", vParametersStructure), ThisObject, UUID);
			EndIf;
		EndIf;
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenGuestGroup(Command)
	vItemSelected =  Items.Spreadsheet.SelectedItems;
	If vItemSelected.Count()>0 Then
		If TypeOf(vItemSelected.Get(0).Value) = Type("Structure") Then
			vObj = vItemSelected.Get(0).Value.Document;
			If TypeOf(vObj) = Type("DocumentRef.Accommodation") Or TypeOf(vObj) = Type("DocumentRef.Reservation") Then
				vGuestGroup = tcOnServer.cmGetAttributeByRef(vObj,"GuestGroup");
				If ValueIsFilled(vGuestGroup) And Not vGuestGroup.IsEmpty() Then
					ShowValue(, vGuestGroup);
				EndIf;
			EndIf;
		EndIf;
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckInButtonCM(pCommand)
	vItemSelected =  Items.Spreadsheet.SelectedItems;
	If vItemSelected.Count()>0 Then
		If TypeOf(vItemSelected.Get(0).Value) = Type("Structure") Then
			vSelResRow = vItemSelected.Get(0).Value.Document;
			If Not TypeOf(vSelResRow) = Type("DocumentRef.Reservation") Then
				Return;
			EndIf;
		Else
			Return;
		EndIf;
	Else
		Return;
	EndIf;
	If vSelResRow <> Undefined Then
		vMainRoomRef = GetMainDocRef(vSelResRow);
		vHotel = tcOnServer.cmGetAttributeByRef(vMainRoomRef, "Hotel");
		vHotelAccountingDate = '00010101';
		If ValueIsFilled(vHotel) Then
			vHotelAccountingDate =  tcOnServer.cmGetAttributeByRef(vHotel, "AccountingDate");
		EndIf;
		If Not ValueIsFilled(vHotelAccountingDate) Then
			vHotelAccountingDate = BegOfDay(CurrentDate());
		EndIf;
		vResult = CheckInAtServer(vMainRoomRef, false);
		If ValueIsFilled(vResult) Then
			If vResult = "DoQueryBox" Then
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='You are checking in by inactive reservation!';ru='Селите по не активной брони!';de='Sie bringen nicht nach einer aktiven Reservierung unter!'"), MessageStatus.Important);
			EndIf;
			vResult = CheckInAtServer(vMainRoomRef, True);
			If ValueIsFilled(vResult) Then
				If TypeOf(vResult) = Type("ValueList") Then
					vQuestionWasAsked = False;
					vSelResList = New ValueList;
					For Each vItem In vResult Do
						vCheckInDate = tcOnServer.cmGetAttributeByRef(vItem.Value, "CheckInDate");
						If vHotelAccountingDate <> BegOfDay(vCheckInDate) Then
							If Not vQuestionWasAsked Then
								vMessageText = NStr("en='There are reservations with check-in date " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " in the list of reservations selected. This date differs from todays date " + Format(vHotelAccountingDate, "DF=dd.MM.yyyy") + "!';
								                    |de='There are reservations with check-in date " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " in the list of reservations selected. This date differs from todays date " + Format(vHotelAccountingDate, "DF=dd.MM.yyyy") + "!';
								                    |ru='В выбранном списке брони есть документы с датой заезда " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " отличающейся от текущей даты " + Format(vHotelAccountingDate, "DF=dd.MM.yyyy") + "!'");
								tcCommonFunctionOnClientServer.TextMessage(vMessageText, MessageStatus.Information);
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
							APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

							// Open new accommodation and fill group table from the given list
							OpenForm("Document.Accommodation.Form.tcDocumentForm", New Structure("GuestsToCheckInList", vResult.ValueList.Copy()), ThisObject);
						Else
							tcCommonFunctionOnClientServer.TextMessage(vResult);
						EndIf;
					EndIf;
				ElsIf TypeOf(vResult)=Type("Structure") Then
					// APDEX
					vKeyOperation = "Document.Accommodation.Form.tcDocumentForm.OpenForm";
					APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

					// Open new accommodation and fill group table from the given list
					OpenForm("Document.Accommodation.Form.tcDocumentForm", New Structure("GuestsToCheckInList", vResult.ValueList.Copy()), ThisObject);
				Else
					tcCommonFunctionOnClientServer.TextMessage(vResult);
				EndIf;
			ElsIf TypeOf(vResult) = Type("ValueList") Then
				vQuestionWasAsked = False;
				vSelResList = New ValueList;
				For Each vItem In vResult Do
					vCheckInDate = tcOnServer.cmGetAttributeByRef(vItem.Value, "CheckInDate");
					If vHotelAccountingDate <> BegOfDay(vCheckInDate) Then
						If Not vQuestionWasAsked Then
							vMessageText = NStr("en='There are reservations with check-in date " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " in the list of reservations selected. This date differs from todays date " + Format(vHotelAccountingDate, "DF=dd.MM.yyyy") + "!';
							                    |de='There are reservations with check-in date " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " in the list of reservations selected. This date differs from todays date " + Format(vHotelAccountingDate, "DF=dd.MM.yyyy") + "!';
							                    |ru='В выбранном списке брони есть документы с датой заезда " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " отличающейся от текущей даты " + Format(vHotelAccountingDate, "DF=dd.MM.yyyy") + "!'");
							tcCommonFunctionOnClientServer.TextMessage(vMessageText, MessageStatus.Information);
							vQuestionWasAsked = True;
						EndIf;
					EndIf;
					vSelResList.Add(vItem.Value);
				EndDo;
				If vSelResList.Count()=0 Then
					Return;
				EndIf;	
				// Check current reservation list deposits
				CheckReservationsDeposits(vSelResList);
				vResult = CheckInAtServer(vMainRoomRef, false, vSelResList);
				If ValueIsFilled(vResult) Then
					If TypeOf(vResult)=Type("Structure") Then
						// APDEX
						vKeyOperation = "Document.Accommodation.Form.tcDocumentForm.OpenForm";
						APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

						// Open new accommodation and fill group table from the given list
						OpenForm("Document.Accommodation.Form.tcDocumentForm", New Structure("GuestsToCheckInList", vResult.ValueList.Copy()), ThisObject);
					Else
						tcCommonFunctionOnClientServer.TextMessage(vResult);
					EndIf;
				EndIf;
			ElsIf TypeOf(vResult)=Type("Structure") Then
				// APDEX
				vKeyOperation = "Document.Accommodation.Form.tcDocumentForm.OpenForm";
				APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

				// Open new accommodation and fill group table from the given list
				OpenForm("Document.Accommodation.Form.tcDocumentForm", New Structure("GuestsToCheckInList", vResult.ValueList.Copy()), ThisObject);
			ElsIf Not IsBlankString(TrimAll(vResult)) Then
				tcCommonFunctionOnClientServer.TextMessage(vResult);
			EndIf;
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckOut(pCommand)
	vItemSelected =  Items.Spreadsheet.SelectedItems;
	If vItemSelected.Count()>0 Then
		If TypeOf(vItemSelected.Get(0).Value) = Type("Structure") Then
			vSelAccRow = vItemSelected.Get(0).Value.Document;
			If Not TypeOf(vSelAccRow) = Type("DocumentRef.Accommodation") Then
				Return
			EndIf;
		Else
			Return;
		EndIf;
	EndIf;	

	If vSelAccRow <> Undefined Then
		MainRoomDoc = GetMainDocRefAcc(vSelAccRow);
		// Add other one room accommodations
		AccList = New ValueList;
		AccList.Add(MainRoomDoc);
		AddOneRoomAccommodations(MainRoomDoc, AccList);
		// Give warning if current date is less then expected check-out date
		vCheckInDate = tcOnServer.cmGetAttributeByRef(MainRoomDoc, "CheckInDate");
		vExpectedCheckOutDate = tcOnServer.cmGetAttributeByRef(MainRoomDoc, "CheckOutDate");
		If BegOfDay(vExpectedCheckOutDate) > BegOfDay(CurrentDate()) Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Expected check-out date " + Format(vExpectedCheckOutDate, "DF=dd.MM.yyyy") + " is in the future!'; 
				         |de='Expected check-out date " + Format(vExpectedCheckOutDate, "DF=dd.MM.yyyy") + " is in the future!'; 
				         |ru='Дата планируемого выезда " + Format(vExpectedCheckOutDate, "DF=dd.MM.yyyy") + " в будущем!'"), MessageStatus.Information);
		EndIf;
		// Get check-out date
		CheckOutDateTime = '00010101';
		If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToCheckOutOnExpectedCheckOutTime") Then
			GetCheckOutDate(vCheckInDate, vExpectedCheckOutDate);
		Else
			CheckOutDateTime = vExpectedCheckOutDate;
		EndIf;
		AttachIdleHandler("CheckIfCheckOutDateTimeIsFilled", 1, False);
	EndIf;
EndProcedure // CheckOut

// -----------------------------------------------------------------------------
&AtClient
Procedure WriteGuestGroup(pCommand)
	If CreateGuestGroupReservations() Then
		// Clear selected reservation periods
		ClearSelectedReservationPeriods();
		// Open guest group form
		vNewGroupParams = GetParameters();
		vFrm = GetForm("Catalog.GuestGroups.Form.tcItemForm", New Structure("Key", GuestGroup), ThisObject);
		vFrm.CurrentItem = vFrm.Items.GroupGuests;
		vFrm.Object.CheckInDate = vNewGroupParams.CheckInDate;
		vFrm.Object.CheckOutDate = vNewGroupParams.CheckOutDate;
		vFrm.Object.Duration = vNewGroupParams.Duration;
		vFrm.Open();
	EndIf;
	BuildSettingsCollapsedTitle();
EndProcedure // CreateGuestGroupReservations

// -----------------------------------------------------------------------------
&AtClient
Procedure AllowDragEdit(pCommand)
	SelAllowDragEdit = Not SelAllowDragEdit;
	Items.AllowDragEdit.Check = SelAllowDragEdit;
EndProcedure // AllowDragEdit

// -----------------------------------------------------------------------------
&AtClient
Procedure Checkin(pCommand)
	If ValueIsFilled(SelCheckInDate) And ValueIsFilled(SelCheckOutDate) Then
		vWarning = "";
		vError = CheckInOnServer(vWarning);
		If Not IsBlankString(vError) Then
			tcCommonFunctionOnClientServer.TextMessage(vError, MessageStatus.Attention);
		Else
			vFrm = GetForm("Document.Accommodation.ObjectForm", New Structure("GuestGroup", AccObject.GuestGroup), ThisObject);
			CopyFormData(AccObject, vFrm.Object);
			vFrm.Open();
			vFrm.SetRoomAttributesExported();
			vFrm.CheckGuestFieldCount(, False);
			If Not IsBlankString(vWarning) Then
				tcCommonFunctionOnClientServer.TextMessage(vWarning, MessageStatus.Attention);
			EndIf;
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure Reserv(pCommand)
	If ValueIsFilled(SelCheckInDate) And ValueIsFilled(SelCheckOutDate) Then
		vWarning = "";
		vError = ReservOnServer(vWarning);
		If Not IsBlankString(vError) Then
			tcCommonFunctionOnClientServer.TextMessage(vError, MessageStatus.Attention);
		Else
			vFrm = GetForm("Document.Reservation.ObjectForm", New Structure("GuestGroup", ResObject.GuestGroup), ThisObject);
			CopyFormData(ResObject, vFrm.Object);
			vFrm.Open();
			vFrm.SetRoomAttributesExported();
			vFrm.CheckGuestFieldCount(, False);
			If Not IsBlankString(vWarning) Then
				tcCommonFunctionOnClientServer.TextMessage(vWarning, MessageStatus.Attention);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // Reserv

// -----------------------------------------------------------------------------
&AtClient
Procedure Next(pCommand)
	SelPeriodFrom = SelPeriodFrom+SelDays/2*24*3600;
	FillRoomPlannerAtClient();
EndProcedure // Next

// -----------------------------------------------------------------------------
&AtClient
Procedure Prev(pCommand)
	SelPeriodFrom = SelPeriodFrom-SelDays/2*24*3600;
	FillRoomPlannerAtClient();
EndProcedure // Prev

// -----------------------------------------------------------------------------
&AtClient
Procedure Refresh(pCommand)
	// APDEX
	vKeyOperation = "CommonForm.tcRoomsGanttChart.RefreshForm";
	APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

	FillRoomPlannerAtClient();
EndProcedure // Refresh

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure FillRoomPlannerAtServer(pPeriodFrom, pPeriodTo)
	// Set hotel color          
	Items.GroupHeader.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");

	SystemSettingsStorage.Save("tcRoomsGanttChartSpreadsheetScale", SessionParameters.CurrentUser, SpreadsheetScale);
	SystemSettingsStorage.Save("tcRoomsGanttChartShowRoomsByRoomTypes", SessionParameters.CurrentUser, SelShowRoomsByRoomTypes);
	SystemSettingsStorage.Save("tcRoomsGanttChartShowBookingsWithoutRooms", SessionParameters.CurrentUser, SelShowBookingsWithoutRooms);
	SystemSettingsStorage.Save("tcRoomsGanttChartShowPreliminary", SessionParameters.CurrentUser, SelShowPreliminary);
	SystemSettingsStorage.Save("tcRoomsGanttChartRoomsPerPage", SessionParameters.CurrentUser, RoomsPerPage);

	vPeriodFrom = pPeriodFrom;
	vPeriodTo = pPeriodTo;
	
	// Fill settings collapsed title
	BuildSettingsCollapsedTitle();
	
	// Read events, accommodations and reservations, room blocks
	OverbookingIndexesRoomTypes.Clear();
	vVacantPeriods = New ValueTable();

	vEvents = cmGetEvents(vPeriodFrom, vPeriodTo, SelHotel);
	vAllRooms = GetRoomsGanttChartData(vPeriodFrom, vPeriodTo);
	vAllRoomBlocks = GetRoomBlocks(vPeriodFrom, vPeriodTo);
	vBookings = GetBookingsWithoutRooms(vPeriodFrom, vPeriodTo);
	vPhoneNumbers = cmGetPhoneNumbers(SelHotel);
	
	// Add bookings without rooms if necessary
	If SelShowBookingsWithoutRooms Then
		vVacantPeriods = GetRoomsVacantPeriods(vAllRooms, vBookings, vPeriodFrom, vPeriodTo);
		// Draw bookings without rooms at the end of the list of rooms by room type
		MapBookingsToTheVacantPeriods(vAllRooms, vVacantPeriods, vBookings);
	Else
		MapBookingsToTheOverbookingRooms(vAllRooms, vBookings);
	EndIf;
	
	// Get all documents
	ShowBalances = False;
	vDocsList = New ValueList();
	If vAllRooms.Count() > 0 Then
		vDocsList.LoadValues(vAllRooms.UnloadColumn("Accommodation"));
		// Get document list balances
		ShowBalances = cmShowBalancesInLists();
		If ShowBalances Then
			vBalances = cmGetDocumentListBalances(vDocsList, SelHotel); 
			If SelShowAllGuests = 0 Then // By rooms
				vBalances.GroupBy("FolioCurrency, FolioParentDocNumber", "ClientSumBalance, ClientLimitBalance, CustomerSumBalance, ClientCreditLimit");
				vBalances.Columns.Add("FolioParentDoc");
			EndIf;
		EndIf;
	EndIf;
	
	// Fill form data collections based on data returned from database
	Events.Clear();
	For Each vEventsRow In vEvents Do
		EventsRow = Events.Add();
		FillPropertyValues(EventsRow, vEventsRow, , "Color");
		vColor = Undefined;
		If vEventsRow.Color <> Undefined Then
			vColor = vEventsRow.Color.Get();
			If TypeOf(vColor) = Type("Color") Then
				EventsRow.Color = vColor;
			Else
				EventsRow.Color = EventColor;
			EndIf;
		Else
			EventsRow.Color = EventColor;
		EndIf;
	EndDo;
	
	// Fill phone numbers
	RoomPhoneNumbers.Clear();
	For Each vPhoneRow In vPhoneNumbers Do
		RoomPhoneNumbersRow = RoomPhoneNumbers.Add();
		FillPropertyValues(RoomPhoneNumbersRow, vPhoneRow);
	EndDo;
	
	RoomsCount = 0;
	vRoomsList = New ValueList();
	vCurRoomType = Undefined;
	vCurRoom = Undefined;
	vCurOverbookingIndex = 0;
	
	AllRooms.Clear();
	For Each vAllRoomsRow In vAllRooms Do
		AllRoomsRow = AllRooms.Add();
		FillPropertyValues(AllRoomsRow, vAllRoomsRow, , "ClientTypeColor, StatusColor, GuestGroupColor, RoomQuotaColor, CustomerColor, ContractColor, RoomRoomStatusColor");
		
		If vAllRoomsRow.RoomIsFolder = Null And ValueIsFilled(vAllRoomsRow.Room) Then
			vRoom = vAllRoomsRow.Room;
			
			AllRoomsRow.RoomIsFolder = vRoom.IsFolder;
			AllRoomsRow.RoomDescription = TrimAll(vRoom.Description);
		EndIf;
				
		vColor = Undefined;
		If vAllRoomsRow.ClientTypeColor <> Undefined And vAllRoomsRow.ClientTypeColor <> Null Then
			vColor = vAllRoomsRow.ClientTypeColor.Get();
			If TypeOf(vColor) = Type("Color") Then
				AllRoomsRow.ClientTypeColor = vColor;
			EndIf;
		EndIf;
		
		vColor = Undefined;
		If vAllRoomsRow.StatusColor <> Undefined And vAllRoomsRow.StatusColor <> Null Then
			vColor = vAllRoomsRow.StatusColor.Get();
			If TypeOf(vColor) = Type("Color") Then
				AllRoomsRow.StatusColor = vColor;
			EndIf;
		EndIf;
		
		vColor = Undefined;
		If vAllRoomsRow.GuestGroupColor <> Undefined And vAllRoomsRow.GuestGroupColor <> Null Then
			vColor = vAllRoomsRow.GuestGroupColor.Get();
			If TypeOf(vColor) = Type("Color") Then
				AllRoomsRow.GuestGroupColor = vColor;
			EndIf;
		EndIf;
		
		vColor = Undefined;
		If vAllRoomsRow.RoomQuotaColor <> Undefined And vAllRoomsRow.RoomQuotaColor <> Null Then
			vColor = vAllRoomsRow.RoomQuotaColor.Get();
			If TypeOf(vColor) = Type("Color") Then
				AllRoomsRow.RoomQuotaColor = vColor;
			EndIf;
		EndIf;
		
		vColor = Undefined;
		If vAllRoomsRow.CustomerColor <> Undefined And vAllRoomsRow.CustomerColor <> Null Then
			vColor = vAllRoomsRow.CustomerColor.Get();
			If TypeOf(vColor) = Type("Color") Then
				AllRoomsRow.CustomerColor = vColor;
			EndIf;
		EndIf;
		
		vColor = Undefined;
		If vAllRoomsRow.ContractColor <> Undefined And vAllRoomsRow.ContractColor <> Null Then
			vColor = vAllRoomsRow.ContractColor.Get();
			If TypeOf(vColor) = Type("Color") Then
				AllRoomsRow.ContractColor = vColor;
			EndIf;
		EndIf;
		
		vColor = Undefined;
		If vAllRoomsRow.RoomRoomStatusColor <> Undefined And vAllRoomsRow.RoomRoomStatusColor <> Null Then
			vColor = vAllRoomsRow.RoomRoomStatusColor.Get();
			If TypeOf(vColor) = Type("Color") Then
				AllRoomsRow.RoomRoomStatusColor = vColor;
			EndIf;
		EndIf;
		
		// Calculate number of rooms
		If SelShowRoomsByRoomTypes Then
			If ValueIsFilled(vAllRoomsRow.RoomType) And vCurRoomType <> vAllRoomsRow.RoomType Then
				vCurRoomType = vAllRoomsRow.RoomType;
				RoomsCount = RoomsCount + 1;
			ElsIf ValueIsFilled(vAllRoomsRow.Room) And vCurRoom <> vAllRoomsRow.Room Then
				vCurRoom = vAllRoomsRow.Room;
				RoomsCount = RoomsCount + 1;
			ElsIf Not ValueIsFilled(vAllRoomsRow.Room) And vAllRoomsRow.OverbookingIndex <> Null And vAllRoomsRow.OverbookingIndex > 0 And vCurOverbookingIndex <> vAllRoomsRow.OverbookingIndex Then
				vCurOverbookingIndex = vAllRoomsRow.OverbookingIndex;
				RoomsCount = RoomsCount + 1;
			EndIf;
		Else
			If ValueIsFilled(vAllRoomsRow.Room) And vCurRoom <> vAllRoomsRow.Room Then
				vCurRoom = vAllRoomsRow.Room;
				RoomsCount = RoomsCount + 1;
			ElsIf Not ValueIsFilled(vAllRoomsRow.Room) And vAllRoomsRow.OverbookingIndex <> Null And vAllRoomsRow.OverbookingIndex > 0 And vCurOverbookingIndex <> vAllRoomsRow.OverbookingIndex Then
				vCurOverbookingIndex = vAllRoomsRow.OverbookingIndex;
				RoomsCount = RoomsCount + 1;
			EndIf;
		EndIf;
	EndDo;
	
	Balances.Clear();
	If ShowBalances Then
		For Each vBalancesRow In vBalances Do
			BalancesRow = Balances.Add();
			FillPropertyValues(BalancesRow, vBalancesRow);
		EndDo;
	EndIf;
	
	// Fill room blocks
	vRoomBlockTypeColors = New ValueTable();
	vRoomBlockTypeColors.Columns.Add("RoomBlockType", cmGetCatalogTypeDescription("RoomBlockTypes"));
	vRoomBlockTypeColors.Columns.Add("Color");
	
	AllRoomBlocks.Clear();
	For Each vAllRoomBlocksRow In vAllRoomBlocks Do
		If Not ValueIsFilled(vAllRoomBlocksRow.Room) Then
			Continue;
		EndIf;
		
		AllRoomBlocksRow = AllRoomBlocks.Add();
		FillPropertyValues(AllRoomBlocksRow, vAllRoomBlocksRow);
		
		If ValueIsFilled(vAllRoomBlocksRow.RoomBlockType) Then
			vRoomBlockTypeColorsRow = vRoomBlockTypeColors.Find(vAllRoomBlocksRow.RoomBlockType, "RoomBlockType");
			If vRoomBlockTypeColorsRow = Undefined Then
				If vAllRoomBlocksRow.RoomBlockType.Color <> Undefined Then
					vColor = vAllRoomBlocksRow.RoomBlockType.Color.Get();
					If TypeOf(vColor) = Type("Color") Then
						AllRoomBlocksRow.Color = vColor;
						
						vRoomBlockTypeColorsRow = vRoomBlockTypeColors.Add();
						vRoomBlockTypeColorsRow.RoomBlockType = vAllRoomBlocksRow.RoomBlockType; 
						vRoomBlockTypeColorsRow.Color = vColor;
					EndIf;
				EndIf;
			Else
				AllRoomBlocksRow.Color = vRoomBlockTypeColorsRow.Color;
			EndIf;
		EndIf;
	EndDo;
	
	// Next set hight of the control
	vIntPages = Int(RoomsCount/RoomsPerPage);
	vPages = RoomsCount/RoomsPerPage;
	Items.CurrentPage.ChoiceList.Clear();
	LastPage = ?(vIntPages <> vPages, vIntPages + 1, vIntPages);
	LastPage = ?(LastPage <= 0, 1, LastPage);
	For p = 1 To LastPage Do
		Items.CurrentPage.ChoiceList.Add(p, Format(p, "NFD=0; NG="));
	EndDo;
	If CurrentPage > LastPage Then
		CurrentPage = LastPage;
	EndIf;
	
	// Hide filters panel if open
	If Not Items.SettingsGroup.Hidden() Then
		Items.SettingsGroup.Hide();
	EndIf;
EndProcedure // FillRoomPlannerAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowStatus()
	#If Not WebClient Then
		Status(NStr("en='Wait...';ru='Подождите...';de='Bitte warten...'"), ProcessPercentage, NStr("en='Building chart...';ru='Заполнение карты...';de='Ausfüllen des Diagramms…'"), PictureLib.LongOperation);
	#EndIf
EndProcedure // ShowStatus

// -----------------------------------------------------------------------------
&AtClient
Procedure FillRoomPlannerIdleHandler() Export
	FillRoomPlannerAtClient();
EndProcedure // FillRoomPlannerIdleHandler

// -----------------------------------------------------------------------------
&AtClient
Procedure FillRoomPlannerAtClient(pGetData = True)
	If Not ValueIsFilled(SelHotel) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Hotel is not selected!'; ru='Не выбрана гостиница!'; de='Hotel wird nicht gewählt!'"));
		Return;
	EndIf;
	
	If pGetData Then
		ProcessPercentage = 0;
		ShowStatus();
	EndIf;
		
	SelDays = 7;
	RoomPlanner.TimeScale.Location = TimeScalePosition.Top;
	
	// Time scale items
	vTS0 = RoomPlanner.TimeScale.Items.Get(0);	
	If RoomPlanner.TimeScale.Items.Count() = 1 Then
		vTS1 = RoomPlanner.TimeScale.Items.Add();
	Else
		vTS1 = RoomPlanner.TimeScale.Items.Get(1);
	EndIf;
	vTS0.TextColor = WebColors.DarkSlateGray;
	vTS1.TextColor = WebColors.DarkSlateGray;
	
	If SpreadsheetScale = 0.1 Then
		SelTimeScaleUnitType = "Days";
		SelDays = 2;
		vTS0.Unit=TimeScaleUnitType.Day;
		vTS0.Repetition = 1;
		vTS0.Format = "DLF=DD";

		vTS1.Unit=TimeScaleUnitType.Hour;
		vTS1.Repetition = 4;
		vTS1.Format = "DF=HH:mm";
	ElsIf SpreadsheetScale = 0.25 Then
		SelTimeScaleUnitType = "Week";
		SelDays = 7;
		vTS0.Unit=TimeScaleUnitType.Month;
		vTS0.Repetition =1;
		vTS0.Format = "DF='MMMM yyyy'";

		vTS1.Unit=TimeScaleUnitType.Day;
		vTS1.Repetition = 1;
		vTS1.Format = "DF='dd ddd'";
	ElsIf SpreadsheetScale = 0.5 Then
		SelTimeScaleUnitType = "2Weeks";
		SelDays = 14;
		vTS0.Unit=TimeScaleUnitType.Month;
		vTS0.Repetition =1;
		vTS0.Format = "DF='MMMM yyyy'";

		vTS1.Unit=TimeScaleUnitType.Day;
		vTS1.Repetition = 1;
		vTS1.Format = "DF='dd ddd'";
	ElsIf SpreadsheetScale = 1 Then
		SelTimeScaleUnitType = "Month";
		SelDays = 31;
		vTS0.Unit=TimeScaleUnitType.Month;
		vTS0.Repetition = 1;
		vTS0.Format = "DF='MMMM yyyy'";

		vTS1.Unit=TimeScaleUnitType.Day;
		vTS1.Repetition = 1;
		vTS1.Format =  "DF='dd ddd'";
	ElsIf SpreadsheetScale = 2 Then
		SelTimeScaleUnitType = "Month";
		SelDays = 62;
		vTS0.Unit=TimeScaleUnitType.Month;
		vTS0.Repetition = 1;
		vTS0.Format = "DF='MMMM yyyy'";

		vTS1.Unit=TimeScaleUnitType.Day;
		vTS1.Repetition = 1;
		vTS1.Format =  "DF='dd ddd'";
	EndIf;

	vPeriodFrom = BegOfDay(SelPeriodFrom);
	SelPeriodDateTo = EndOfDay(SelPeriodFrom) + SelDays * 24 * 3600;
	vPeriodTo = SelPeriodDateTo;
	
	RoomPlanner.PeriodicVariantUnit = TimeScaleUnitType.Day;
	RoomPlanner.PeriodicVariantRepetition = SelDays+2;
	RoomPlanner.CurrentRepresentationPeriods.Clear();
	If SpreadsheetScale > 0.1 And SpreadsheetScale < 2 Then
		RoomPlanner.CurrentRepresentationPeriods.Add(vPeriodFrom-24*3600, vPeriodTo); //add first day to make space for room status item
	Else
		RoomPlanner.CurrentRepresentationPeriods.Add(vPeriodFrom, vPeriodTo);
	EndIf;
	RoomPlanner.AlignItemBoundariesByTimeScale = False;
	
	RoomPlanner.BackgroundIntervals.Clear();
	vTodayDate = BegOfDay(CurrentDate());
	If vTodayDate >= vPeriodFrom And vTodayDate <= vPeriodTo Then
		vToday = RoomPlanner.BackgroundIntervals.Add(vTodayDate, EndOfDay(vTodayDate));
		vToday.Color = WebColors.Gainsboro;
	EndIf;
	vCurPer = EndOfWeek(vPeriodFrom)-2*24*3600+1; // Beg of saturday
	While vCurPer < vPeriodTo Do
		vWeekEnd = RoomPlanner.BackgroundIntervals.Add(vCurPer,EndOfWeek(vCurPer));
		vWeekEnd.Color = WebColors.SeaShell;
		vCurPer = vCurPer + 7*24*3600;
	EndDo;
	
	// Clear planner
	RoomPlanner.Items.Clear();
	RoomPlanner.ItemsTimeRepresentation = PlannerItemsTimeRepresentation.DontDisplay;
	RoomPlanner.Dimensions.Clear();
	RoomPlanner.Dimensions.Add("Room");
	RoomPlanner.Dimensions.Find("Room").Text = NStr("en='Rooms'; de='Zimmeren'; ru='Номерной фонд'");
	
	// Read events, accommodations and reservations, room blocks
	If pGetData Then
		FillRoomPlannerAtServer(vPeriodFrom, vPeriodTo);
		
		ProcessPercentage = 60;
		ShowStatus();
	EndIf;
	
	DrawRoomPlannerAtServer();
	If pGetData Then
		ProcessPercentage = 90;
		ShowStatus();
	EndIf;
EndProcedure // FillRoomPlannerAtClient

// -----------------------------------------------------------------------------
&AtServer
Procedure DrawRoomPlannerAtServer()
	// Hotel
	itemRoom = RoomPlanner.Dimensions.Find("Room").Items.Find(SelHotel);
	If itemRoom = Undefined Then
		itemRoom = RoomPlanner.Dimensions.Find("Room").Items.Add(SelHotel);
		itemRoom.TextColor = WebColors.Black;
		itemRoom.Value = SelHotel;
		itemRoom.Text = TrimAll(SelHotel) + cmAppendBlanks(Chars.LF, 35, "_");
	EndIf;
	
	// Next fill vacant rooms for the hotel by days
	FillRoomPlannerDailyVacants();
	
	// Next show events
	FillRoomPlannerEvents();
	
	// Next rooms
	FillRoomPlannerRooms();
	
	// Next room blocks
	FillRoomPlannerRoomBlocks();
	
	// Next new reservation periods
	FillRoomPlannerNewGroupReservationPeriods();
EndProcedure // DrawRoomPlannerAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillRoomPlannerDailyVacants() Export
	DVDay = '00010101';
	If SpreadsheetScale > 0.1 And SpreadsheetScale < 2 Then
		// Get number of vacant rooms per each day in the period choosen on time selected
		DailyVacants = GetPeriodDailyVacants(BegOfDay(SelPeriodFrom), SelPeriodDateTo, , SelHotel, SelRoomSection, SelRoomClass, SelRoomTypes, SelRoomType);
		vCount = DailyVacants.Count(); 
		If vCount > 0 Then
			For Each vDV In DailyVacants Do
				DVDay = Date(Number(Mid(vDV.Key, 2, 4)), Number(Mid(vDV.Key, 6, 2)), Number(Right(vDV.Key, 2)));
				
				vItem = RoomPlanner.Items.Add(BegOfDay(DVDay), EndOfDay(DVDay));
				vDims = New Map;
				vDims.Insert("Room", SelHotel);
				vItem.DimensionValues = New FixedMap(vDims);
				vItem.Text = vDV.Value;
				vItem.BackColor = WebColors.White;
				If vDV.Value <= 0 Then
					vItem.TextColor = WebColors.Red;
				Else
					vItem.TextColor = WebColors.Green;
				EndIf;
			EndDo;
		EndIF;
	EndIf;
EndProcedure // FillRoomPlannerDailyVacants

// -----------------------------------------------------------------------------
&AtServer
Procedure FillRoomPlannerEvents() Export
	// Events
	vCount = Events.Count(); 
	If vCount > 0 Then
		itemEvents = RoomPlanner.Dimensions.Find("Room").Items.Find("Events");
		If itemEvents = Undefined Then
			itemEvents = RoomPlanner.Dimensions.Find("Room").Items.Add("Events");
			itemEvents.TextColor = WebColors.Black;
			itemEvents.Value = "Events";
			itemEvents.Text = NStr("en='Events'; ru='События'; de='Ereignisse'");
		EndIf;
		For Each vEventsRow In Events Do
			vEventItem = RoomPlanner.Items.Add(Max(BegOfDay(vEventsRow.DateFrom), BegOfDay(SelPeriodFrom)), Min(EndOfDay(vEventsRow.DateTo), SelPeriodDateTo));
			vDims = New Map;
			vDims.Insert("Room", "Events");
			vEventItem.DimensionValues = New FixedMap(vDims);
			vEventItem.Text = vEventsRow.Description;
			vEventItem.ToolTip = Format(vEventsRow.DateFrom, "DF=dd.MM.yyyy") + " - " + Format(vEventsRow.DateTo, "DF=dd.MM.yyyy") + 
			                     ?(IsBlankString(vEventsRow.Remarks), "", Chars.LF + TrimAll(vEventsRow.Remarks));
			vEventItem.BackColor = vEventsRow.Color;
		EndDo;
	EndIf;
EndProcedure // FillRoomPlannerEvents

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetDateWithoutMinutes(pDate)
	Return Date(Year(pDate), Month(pDate), Day(pDate), Hour(pDate), 0, 0);
EndFunction // GetDateWithoutMinutes

// -----------------------------------------------------------------------------
&AtServer
Procedure AddRoomPhonesToRoomDescription(pRoom, pRoomDescription, rRoomText)
	vPhonesDescr = "";
	vRoomPhones = RoomPhoneNumbers.FindRows(New Structure("Room", pRoom));
	If vRoomPhones.Count() > 0 Then
		For Each vRoomPhonesRow In vRoomPhones Do
			If Upper(TrimAll(vRoomPhonesRow.PhoneNumber)) <> Upper(TrimAll(pRoomDescription)) Then
				If IsBlankString(vPhonesDescr) Then
					vPhonesDescr = NStr("en=' Ph.'; ru=' Тел.'; de=' Tel.'") + " " + TrimAll(vRoomPhonesRow.PhoneNumber);
				Else
					vPhonesDescr = vPhonesDescr + ", " + TrimAll(vRoomPhonesRow.PhoneNumber);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	If Not IsBlankString(vPhonesDescr) Then
		rRoomText = TrimAll(rRoomText) + vPhonesDescr;
	EndIf;
EndProcedure // AddRoomPhonesToRoomDescription

// -----------------------------------------------------------------------------
&AtServer
Procedure FillRoomPlannerRooms() Export
	// Fill rooms
	vRoomsCount = 0;
	vCurRoomType = PredefinedValue("Catalog.RoomTypes.EmptyRef");
	vCurRoom = PredefinedValue("Catalog.Rooms.EmptyRef");
	vCurRoomDescription = "";
	vCurOverbookingIndex = 0;
	If AllRooms.Count() > 0 Then
		// Table used to hide reservations by beds in the by rooms mode. We will show reservations with different periods only
		vRoomBeds = New ValueTable();
		vRoomBeds.Columns.Add("Room", cmGetCatalogTypeDescription("Rooms"));
		vRoomBeds.Columns.Add("OverbookingIndex", cmGetNumberTypeDescription(10, 0));
		vRoomBeds.Columns.Add("MinDate", cmGetDateTimeTypeDescription());
		vRoomBeds.Columns.Add("MaxDate", cmGetDateTimeTypeDescription());
		// Add items to the chart
		If SelShowRoomsByRoomTypes Then
			For Each vDoc In AllRooms Do
				// Room types
				If ValueIsFilled(vDoc.RoomType) And vCurRoomType <> vDoc.RoomType Then
					vCurRoomType = vDoc.RoomType;
					itemRoomType = RoomPlanner.Dimensions.Find("Room").Items.Find(vCurRoomType);
					If itemRoomType = Undefined Then
						vRoomsCount = vRoomsCount + 1;
						If vRoomsCount < (RoomsPerPage * (CurrentPage - 1) + 1) Then
							Continue;
						ElsIf vRoomsCount >= (RoomsPerPage * CurrentPage + 1) Then
							Break;
						EndIf;
						
						itemRoomType = RoomPlanner.Dimensions.Find("Room").Items.Add(vCurRoomType);
						itemRoomType.TextColor = WebColors.Black;
						itemRoomType.Value = vCurRoomType;
						itemRoomType.Text = vDoc.RoomTypeDescription;
						itemRoomType.BackColor = WebColors.Ivory;
						If SpreadsheetScale > 0.1 And SpreadsheetScale < 2 Then
							DailyVacants = GetPeriodDailyVacants(BegOfDay(SelPeriodFrom), SelPeriodDateTo, vCurRoomType, SelHotel, SelRoomSection, SelRoomClass, SelRoomTypes, SelRoomType);
							For Each vDV In DailyVacants Do
								DVDay = Date(Number(Mid(vDV.Key, 2, 4)), Number(Mid(vDV.Key, 6, 2)), Number(Right(vDV.Key, 2)));
								
								vItem = RoomPlanner.Items.Add(BegOfDay(DVDay), EndOfDay(DVDay));
								vDims = New Map;
								vDims.Insert("Room", vCurRoomType);
								vItem.DimensionValues = New FixedMap(vDims);
								vItem.Text = vDV.Value;
								vItem.BackColor = WebColors.Ivory;
								If vDV.Value <= 0 Then
									vItem.TextColor = WebColors.Red;
								Else
									vItem.TextColor = WebColors.Green;
								EndIf;
							EndDo;
						EndIf;
					EndIf;
				EndIf;
				
				// Rooms
				If ValueIsFilled(vDoc.Room) Then
					itemRoom = RoomPlanner.Dimensions.Find("Room").Items.Find(vDoc.Room);
				ElsIf vDoc.OverbookingIndex <> Null And vDoc.OverbookingIndex > 0 Then
					itemRoom = RoomPlanner.Dimensions.Find("Room").Items.Find(vDoc.OverbookingIndex);
				Else
					Continue;
				EndIf;
				If itemRoom = Undefined Then
					If ValueIsFilled(vDoc.Room) And vCurRoom <> vDoc.Room Then
						vCurRoom = vDoc.Room;
						vRoomsCount = vRoomsCount + 1;
					ElsIf Not ValueIsFilled(vDoc.Room) And vDoc.OverbookingIndex <> Null And vDoc.OverbookingIndex <> 0 And vCurOverbookingIndex <> vDoc.OverbookingIndex Then
						vCurOverbookingIndex = vDoc.OverbookingIndex;
						vRoomsCount = vRoomsCount + 1;
					EndIf;
					If vRoomsCount < (RoomsPerPage * (CurrentPage - 1) + 1) Then
						Continue;
					ElsIf vRoomsCount >= (RoomsPerPage * CurrentPage + 1) Then
						Break;
					EndIf;
					
					If ValueIsFilled(vDoc.Room) Then
						itemRoom = RoomPlanner.Dimensions.Find("Room").Items.Add(vDoc.Room);
						itemRoom.Value = vDoc.Room;
						itemRoom.TextColor = WebColors.DarkSlateGray;
						itemRoom.Text = TrimAll(vDoc.RoomDescription) + " " + vDoc.RoomTypeCode + ?(IsBlankString(TrimAll(vDoc.RoomRoomPropertiesCodes)), "", " (" + StrReplace(TrimAll(vDoc.RoomRoomPropertiesCodes), Chars.LF, ",") + ")");
						
						// Add room phones list
						AddRoomPhonesToRoomDescription(vDoc.Room, vDoc.RoomDescription, itemRoom.Text);
					Else
						itemRoom = RoomPlanner.Dimensions.Find("Room").Items.Add(vDoc.OverbookingIndex);
						itemRoom.Value = vDoc.OverbookingIndex;
						itemRoom.TextColor = WebColors.Brown;
						itemRoom.Text = TrimAll(vDoc.RoomDescription);
					EndIf;
					
					// Add room status item into first day
					If ValueIsFilled(vDoc.Room) And SpreadsheetScale > 0.1 And SpreadsheetScale < 2 Then
						vItemStatus = RoomPlanner.Items.Add(BegOfDay(SelPeriodFrom)-24*3600,BegOfDay(SelPeriodFrom)-1*3600);
						vDims = New Map;
						vDims.Insert("Room", vDoc.Room);
						vItemStatus.DimensionValues = New FixedMap(vDims);
						vItemStatus.Text = vDoc.RoomRoomStatusDescription;
						vItemStatus.Value = vDoc.RoomRoomStatus;
						If ValueIsFilled(vDoc.RoomRoomStatus) And vDoc.RoomRoomStatusColor <> Undefined Then
							vColor = vDoc.RoomRoomStatusColor;
						Else
							vItemStatus.BackColor = WebColors.White;
						EndIf;
						vItemStatus.Picture = GetRoomStatusIcon(vDoc.RoomRoomStatus, vDoc.RoomRoomStatusIcon);
					EndIf;
				Else
					If vRoomsCount < (RoomsPerPage * (CurrentPage - 1) + 1) Then
						Continue;
					ElsIf vRoomsCount >= (RoomsPerPage * CurrentPage + 1) Then
						Break;
					EndIf;
				EndIf;

				// Documents
				If Not ValueIsFilled(vDoc.Accommodation) Then
					Continue;
				Endif;
				vDoAdd = True;
				vPrevItem = RoomPlanner.Items.Find(vDoc.Accommodation);
				If vPrevItem <> Undefined Then
					If vPrevItem.Begin = Max(vDoc.CheckInDate, BegOfDay(SelPeriodFrom)) And vPrevItem.End = vDoc.CheckOutDate Then
						vDoAdd = False;
					EndIf;
				EndIf;
				If vDoAdd Then
					If SelShowAllGuests = 0 And vDoc.AccommodationTypeType <> PredefinedValue("Enum.AccomodationTypes.Room") And vDoc.AccommodationTypeType <> PredefinedValue("Enum.AccomodationTypes.Beds") Then
						Continue;
					EndIf;
					If SelShowAllGuests = 0 And vDoc.AccommodationTypeType = PredefinedValue("Enum.AccomodationTypes.Beds") Then
						vSkipDoc = True;
						vRoomBedsRow = Undefined;
						If ValueIsFilled(vDoc.Room) Then
							vRoomBedsRow = vRoomBeds.Find(vDoc.Room, "Room");
						Else
							vRoomBedsRow = vRoomBeds.Find(vDoc.OverbookingIndex, "OverbookingIndex");
						EndIf;
						vNoMinutesCheckInDate = GetDateWithoutMinutes(vDoc.CheckInDate);
						vNoMinutesCheckOutDate = GetDateWithoutMinutes(vDoc.CheckOutDate);
						If vRoomBedsRow = Undefined Then
							vRoomBedsRow = vRoomBeds.Add();
							If ValueIsFilled(vDoc.Room) Then
								vRoomBedsRow.Room = vDoc.Room;
							Else
								vRoomBedsRow.OverbookingIndex = vDoc.OverbookingIndex;
							EndIf;
							vRoomBedsRow.MinDate = '39991231235959';
						EndIf;
						If vRoomBedsRow.MinDate > vNoMinutesCheckInDate Then
							vRoomBedsRow.MinDate = vNoMinutesCheckInDate;
							vSkipDoc = False;
						EndIf;
						If vRoomBedsRow.MaxDate < vNoMinutesCheckOutDate Then
							vRoomBedsRow.MaxDate = vNoMinutesCheckOutDate;
							vSkipDoc = False;
						EndIf;
						If vSkipDoc Then
							Continue;
						EndIf;
					EndIf;
					If SelShowAllGuests = 1 And Not ValueIsFilled(vDoc.RoomInDocument) And vDoc.AccommodationTypeType = PredefinedValue("Enum.AccomodationTypes.Room") Then
						AddOneRoomGuestsForReservationWithoutRoom(vDoc);
					EndIf;
					vItem = RoomPlanner.Items.Add(Max(vDoc.CheckInDate, BegOfDay(SelPeriodFrom)), vDoc.CheckOutDate); // max is needed to avoid intersections with room status items
					vDims = New Map;
					vDims.Insert("Room", ?(ValueIsFilled(vDoc.Room), vDoc.Room, vDoc.OverbookingIndex));
					vItem.DimensionValues = New FixedMap(vDims);
					vItem.BackColor =  New Color(204,227,255);
					vGuestGroupColor = Undefined;
					vRoomInDocument = vDoc.RoomInDocument;
					If Not SelHotel.DoNotShowTooltipsInRoomsGanttChart Then
						vItem.ToolTip = "" + Format(vDoc.GuestGroupCode, "NFD=0; NG=") + Chars.LF + 
						                ?(ValueIsFilled(vDoc.Room), TrimAll(vDoc.RoomDescription) + ", ", "") + Format(vDoc.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(vDoc.CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + Chars.LF + 
						                TrimAll(vDoc.GuestFullName) + ?(ValueIsFilled(vDoc.AccommodationTemplate), " (" + TrimAll(vDoc.AccommodationTemplateDescription) + ")", "") + Chars.LF + 
										TrimAll(TrimAll(vDoc.CustomerDescription) + " (" + TrimAll(vDoc.PlannedPaymentMethodDescription)) + ")" + Chars.LF + 
										?(ValueIsFilled(vRoomInDocument), "", Upper(NStr("en='<Booking without room>';ru='<Бронь без номера комнаты>';de='<Buchung ohne Zimmernummer>'")) + Chars.LF) + 
										TrimAll(TrimAll(vDoc.RoomRateDescription) + " " + TrimAll(vDoc.ServicePackageDescription)) + 
										?(IsBlankString(TrimAll(vDoc.Remarks)), "", Chars.LF + TrimAll(vDoc.Remarks));
					Else
						vItem.ToolTip = "";
					EndIf;
					vItem.Text = ?(ValueIsFilled(vRoomInDocument), "", "* " + ?(vDoc.RoomQuantity > 1, NStr("en='Q-ty: ';ru='Кол-во: '; de='Anzahl: '") + Format(vDoc.RoomQuantity, "NFD=0; NZ=; NG=") + " ", ""));
					If ValueIsFilled(vDoc.Customer) And Upper(vDoc.CustomerDescription) <> Upper(TrimAll(vDoc.GuestFullName)) Then
						vItem.Text = vItem.Text + TrimAll(vDoc.GuestFullName) + " " + TrimAll(vDoc.CustomerDescription);
					Else
						vItem.Text = vItem.Text + TrimAll(vDoc.GuestFullName);
					EndIf;
					If IsBlankString(vItem.Text) Then
						vItem.Text = TrimAll(vDoc.GuestGroupDescription);
					EndIf;
					// Add accommodation and reservation balances
					If ShowBalances Then
						AddItemBalances(vItem, vDoc, vRoomInDocument, Balances, 
						                BlackColor, WhiteColor, AccommodationWithDebtColor, AccommodationWithDebtTextColor, CheckOutColor, CheckInColor, 
						                ReservationColor, GuaranteedReservationColor, ReservationWithDebtColor, NoPriceColor);
					Else
						rBarForeColor = WebColors.Black;
						vItem.BackColor = GetChartBarColor(vDoc, vDoc.Status, vDoc.Accommodation, True, vRoomInDocument, rBarForeColor, 
						                                   BlackColor, WhiteColor, AccommodationWithDebtColor, AccommodationWithDebtTextColor, CheckOutColor, CheckInColor, 
						                                   ReservationColor, GuaranteedReservationColor, ReservationWithDebtColor, NoPriceColor);
						vItem.TextColor = rBarForeColor;
					EndIf;
					// Customer pays
					If ValueIsFilled(vDoc.Customer) And Not vDoc.CustomerIsIndividual And vDoc.IsByBankTransfer Then
						vItem.Picture = PictureLib.Customer;
					EndIf;
					// Value
					vItem.Value = New Structure("Document, Room, StartPeriod, EndPeriod", vDoc.Accommodation, vDoc.Room, Max(vDoc.CheckInDate, BegOfDay(SelPeriodFrom)), vDoc.CheckOutDate);
				EndIf;
			EndDo;
		Else
			For Each vDoc In AllRooms Do
				// Rooms
				If ValueIsFilled(vDoc.Room) Then
					itemRoom = RoomPlanner.Dimensions.Find("Room").Items.Find(vDoc.Room);
				ElsIf vDoc.OverbookingIndex <> Null And vDoc.OverbookingIndex <> 0 Then
					itemRoom = RoomPlanner.Dimensions.Find("Room").Items.Find(vDoc.OverbookingIndex);
				Else
					Continue;
				EndIf;
				If itemRoom = Undefined Then
					If ValueIsFilled(vDoc.Room) And vCurRoom <> vDoc.Room Then
						vCurRoom = vDoc.Room;
						vCurRoomDescription = vDoc.RoomDescription;
						vRoomsCount = vRoomsCount + 1;
					ElsIf Not ValueIsFilled(vDoc.Room) And vDoc.OverbookingIndex <> Null And vDoc.OverbookingIndex <> 0 And vCurOverbookingIndex <> vDoc.OverbookingIndex Then
						vCurOverbookingIndex = vDoc.OverbookingIndex;
						vRoomsCount = vRoomsCount + 1;
					EndIf;
					If vRoomsCount < (RoomsPerPage * (CurrentPage - 1) + 1) Then
						Continue;
					ElsIf vRoomsCount >= (RoomsPerPage * CurrentPage + 1) Then
						Break;
					EndIf;
					
					If ValueIsFilled(vCurRoom) And ValueIsFilled(vDoc.Room) Then
						itemRoom = RoomPlanner.Dimensions.Find("Room").Items.Add(vCurRoom);
						itemRoom.Value = vCurRoom;
						If vDoc.RoomIsFolder Then
							itemRoom.TextColor = WebColors.Black;
							itemRoom.Text = TrimAll(vCurRoomDescription);
							itemRoom.BackColor = WebColors.Ivory;
						Else
							itemRoom.TextColor = WebColors.DarkSlateGray;
							itemRoom.Text = TrimAll(vCurRoomDescription) + " " + vDoc.RoomTypeCode + ?(IsBlankString(TrimAll(vDoc.RoomRoomPropertiesCodes)), "", " (" + StrReplace(TrimAll(vDoc.RoomRoomPropertiesCodes), Chars.LF, ",") + ")");

							// Add room phones list
							AddRoomPhonesToRoomDescription(vCurRoom, vCurRoomDescription, itemRoom.Text);
							
							// Add room status item into first day
							If SpreadsheetScale > 0.1 And SpreadsheetScale < 2 Then
								vItemStatus = RoomPlanner.Items.Add(BegOfDay(SelPeriodFrom)-24*3600,BegOfDay(SelPeriodFrom)-1*3600);
								vDims = New Map;
								vDims.Insert("Room", vCurRoom);
								vItemStatus.DimensionValues = New FixedMap(vDims);
								vItemStatus.Value = vDoc.RoomRoomStatus;
								vItemStatus.Text = vDoc.RoomRoomStatusDescription;
								If ValueIsFilled(vDoc.RoomRoomStatus) And vDoc.RoomRoomStatusColor <> Undefined Then
									vItemStatus.BackColor = vDoc.RoomRoomStatusColor;
								Else
									vItemStatus.BackColor = WebColors.White;
								EndIf;
								vItemStatus.Picture = GetRoomStatusIcon(vDoc.RoomRoomStatus, vDoc.RoomRoomStatusIcon);
							EndIf;
						EndIf;
					Else
						itemRoom = RoomPlanner.Dimensions.Find("Room").Items.Add(vDoc.OverbookingIndex);
						itemRoom.Value = vDoc.OverbookingIndex;
						itemRoom.TextColor = WebColors.Brown;
						itemRoom.Text = TrimAll(vDoc.RoomDescription);
					EndIf;
				Else
					If vRoomsCount < (RoomsPerPage * (CurrentPage - 1) + 1) Then
						Continue;
					ElsIf vRoomsCount >= (RoomsPerPage * CurrentPage + 1) Then
						Break;
					EndIf;
				EndIf;

				// Documents
				If Not ValueIsFilled(vDoc.Accommodation) Then
					Continue;
				EndIf;
				vDoAdd = True;
				vPrevItem = RoomPlanner.Items.Find(vDoc.Accommodation);
				If vPrevItem <> Undefined Then
					If vPrevItem.Begin = Max(vDoc.CheckInDate, BegOfDay(SelPeriodFrom)) And vPrevItem.End = vDoc.CheckOutDate Then
						vDoAdd = False;
					EndIf;
				EndIf;
				If vDoAdd Then
					If SelShowAllGuests = 0 And vDoc.AccommodationTypeType <> PredefinedValue("Enum.AccomodationTypes.Room") And vDoc.AccommodationTypeType <> PredefinedValue("Enum.AccomodationTypes.Beds") Then
						Continue;
					EndIf;
					If SelShowAllGuests = 0 And vDoc.AccommodationTypeType = PredefinedValue("Enum.AccomodationTypes.Beds") Then
						vSkipDoc = True;
						vRoomBedsRow = Undefined;
						If ValueIsFilled(vDoc.Room) Then
							vRoomBedsRow = vRoomBeds.Find(vDoc.Room, "Room");
						Else
							vRoomBedsRow = vRoomBeds.Find(vDoc.OverbookingIndex, "OverbookingIndex");
						EndIf;
						vNoMinutesCheckInDate = GetDateWithoutMinutes(vDoc.CheckInDate);
						vNoMinutesCheckOutDate = GetDateWithoutMinutes(vDoc.CheckOutDate);
						If vRoomBedsRow = Undefined Then
							vRoomBedsRow = vRoomBeds.Add();
							If ValueIsFilled(vDoc.Room) Then
								vRoomBedsRow.Room = vDoc.Room;
							Else
								vRoomBedsRow.OverbookingIndex = vDoc.OverbookingIndex;
							EndIf;
							vRoomBedsRow.MinDate = '39991231235959';
						EndIf;
						If vRoomBedsRow.MinDate > vNoMinutesCheckInDate Then
							vRoomBedsRow.MinDate = vNoMinutesCheckInDate;
							vSkipDoc = False;
						EndIf;
						If vRoomBedsRow.MaxDate < vNoMinutesCheckOutDate Then
							vRoomBedsRow.MaxDate = vNoMinutesCheckOutDate;
							vSkipDoc = False;
						EndIf;
						If vSkipDoc Then
							Continue;
						EndIf;
					EndIf;
					If SelShowAllGuests = 1 And Not ValueIsFilled(vDoc.RoomInDocument) And vDoc.AccommodationTypeType = PredefinedValue("Enum.AccomodationTypes.Room") Then
						AddOneRoomGuestsForReservationWithoutRoom(vDoc);
					EndIf;
					vItem = RoomPlanner.Items.Add(Max(vDoc.CheckInDate, BegOfDay(SelPeriodFrom)), vDoc.CheckOutDate); //max is needed to avoid intersections with room status items
					vDims = New Map;
					vDims.Insert("Room", ?(ValueIsFilled(vDoc.Room), vDoc.Room, vDoc.OverbookingIndex));
					vItem.DimensionValues = New FixedMap(vDims);
					vItem.BackColor =  New Color(204,227,255);
					rBarForeColor = WebColors.Black;
					vGuestGroupColor = Undefined;
					vRoomInDocument = vDoc.RoomInDocument;
					vItem.BackColor = GetChartBarColor(vDoc, vDoc.Status, vDoc.Accommodation, True, vRoomInDocument, rBarForeColor, 
					                                   BlackColor, WhiteColor, AccommodationWithDebtColor, AccommodationWithDebtTextColor, CheckOutColor, CheckInColor, 
					                                   ReservationColor, GuaranteedReservationColor, ReservationWithDebtColor, NoPriceColor);
					If Not SelHotel.DoNotShowTooltipsInRoomsGanttChart Then
						vItem.ToolTip = "" + TrimAll(vDoc.GuestGroupCode) + Chars.LF + 
						                ?(Not IsBlankString(TrimAll(vDoc.RoomDescription)), TrimAll(vDoc.RoomDescription) + ", ", "") + Format(vDoc.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(vDoc.CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + Chars.LF + 
						                TrimAll(vDoc.GuestFullName) + ?(ValueIsFilled(vDoc.AccommodationTemplate), " (" + TrimAll(vDoc.AccommodationTemplateDescription) + ")", "") + Chars.LF + 
										TrimAll(TrimAll(vDoc.CustomerDescription) + " " + TrimAll(vDoc.PlannedPaymentMethodDescription)) + Chars.LF + 
										?(ValueIsFilled(vRoomInDocument), "", Upper(NStr("en='<Booking without room>';ru='<Бронь без номера комнаты>';de='<Buchung ohne Zimmernummer>'")) + Chars.LF) + 
										TrimAll(TrimAll(vDoc.RoomRateDescription) + " " + TrimAll(vDoc.ServicePackageDescription)) + 
										?(IsBlankString(TrimAll(vDoc.Remarks)), "", Chars.LF + TrimAll(vDoc.Remarks));
					Else
						vItem.ToolTip = "";
					EndIf;
					vItem.Text = ?(ValueIsFilled(vRoomInDocument), "", "* " + ?(vDoc.RoomQuantity > 1, NStr("en='Q-ty: ';ru='Кол-во: '; de='Anzahl: '") + Format(vDoc.RoomQuantity, "NFD=0; NZ=; NG=") + " ", ""));
					If ValueIsFilled(vDoc.Customer) And Upper(vDoc.CustomerDescription) <> Upper(TrimAll(vDoc.GuestFullName)) Then
						vItem.Text = vItem.Text + TrimAll(vDoc.GuestFullName) + " " + TrimAll(vDoc.CustomerDescription);
					Else
						vItem.Text = vItem.Text + TrimAll(vDoc.GuestFullName);
					EndIf;
					If IsBlankString(vItem.Text) Then
						vItem.Text = TrimAll(vDoc.GuestGroupDescription);
					EndIf;
					// Add accommodation and reservation balances
					If ShowBalances Then
						AddItemBalances(vItem, vDoc, vRoomInDocument, Balances, 
						                BlackColor, WhiteColor, AccommodationWithDebtColor, AccommodationWithDebtTextColor, CheckOutColor, CheckInColor, 
						                ReservationColor, GuaranteedReservationColor, ReservationWithDebtColor, NoPriceColor);
					Else
						rBarForeColor = WebColors.Black;
						vItem.BackColor = GetChartBarColor(vDoc, vDoc.Status, vDoc.Accommodation, True, vRoomInDocument, rBarForeColor, 
						                                   BlackColor, WhiteColor, AccommodationWithDebtColor, AccommodationWithDebtTextColor, CheckOutColor, CheckInColor, 
						                                   ReservationColor, GuaranteedReservationColor, ReservationWithDebtColor, NoPriceColor);
						vItem.TextColor = rBarForeColor;
					EndIf;
					// Customer pays
					If ValueIsFilled(vDoc.Customer) And Not vDoc.CustomerIsIndividual And vDoc.IsByBankTransfer Then
						vItem.Picture = PictureLib.Customer;
					EndIf;
					// Value
					vItem.Value = New Structure("Document, Room, StartPeriod, EndPeriod", vDoc.Accommodation, vDoc.Room, Max(vDoc.CheckInDate, BegOfDay(SelPeriodFrom)), vDoc.CheckOutDate);
				EndIf;
			EndDo;
		EndIf;
	EndIf;
EndProcedure // FillRoomPlannerRooms

// -----------------------------------------------------------------------------
&AtServer
Procedure FillRoomPlannerRoomBlocks() Export
	If AllRoomBlocks.Count() > 0 Then 
		// Fill room blocks
		For Each vBlock In AllRoomBlocks Do
			If RoomPlanner.Dimensions.Find("Room").Items.Find(vBlock.Room) <> Undefined Then
				If RoomPlanner.Items.Find(vBlock.SetRoomBlock) = Undefined Then
					vItem = RoomPlanner.Items.Add(Max(vBlock.BlockPeriodFrom, BegOfDay(SelPeriodFrom)), Min(SelPeriodDateTo, ?(ValueIsFilled(vBlock.BlockPeriodTo), vBlock.BlockPeriodTo, SelPeriodDateTo)));
					vDims = New Map;
					vDims.Insert("Room", vBlock.Room);
					vItem.DimensionValues = New FixedMap(vDims);
					vItem.BackColor = RoomBlockColor;
					vItem.TextColor = WebColors.White;
					If vBlock.Color <> Undefined Then
						vItem.BackColor = vBlock.Color;
					EndIf;
					If Not SelHotel.DoNotShowTooltipsInRoomsGanttChart Then
						vItem.ToolTip = "" + TrimAll(vBlock.RoomBlockTypeDescription) + Chars.LF + 
						                ?(ValueIsFilled(vBlock.Room), TrimAll(vBlock.RoomDescription) + ", ", "") + Format(vBlock.BlockPeriodFrom, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(vBlock.BlockPeriodTo, "DF='dd.MM.yyyy HH:mm'") + Chars.LF + 
										TrimAll(vBlock.Remarks);
					Else
						vItem.ToolTip = "";
					EndIf;
					vItem.Text = TrimAll(vBlock.Remarks);
					vItem.Value = New Structure("Document, Room, StartPeriod, EndPeriod", vBlock.SetRoomBlock, vBlock.Room, Max(vBlock.BlockPeriodFrom, BegOfDay(SelPeriodFrom)), Min(SelPeriodDateTo, ?(ValueIsFilled(vBlock.BlockPeriodTo), vBlock.BlockPeriodTo, SelPeriodDateTo)));
				EndIf;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // FillRoomPlannerRoomBlocks

// -----------------------------------------------------------------------------
&AtServer 
Procedure FillRoomPlannerNewGroupReservationPeriods() Export
	If SelectedReservationPeriods.Count() > 0 Then 
		// Fill periods
		For Each vPeriodRow In SelectedReservationPeriods Do
			If RoomPlanner.Dimensions.Find("Room").Items.Find(?(ValueIsFilled(vPeriodRow.Room), vPeriodRow.Room, vPeriodRow.OverbookingIndex)) <> Undefined Then
				If RoomPlanner.Items.Find(SelectedReservationPeriods.IndexOf(vPeriodRow)) = Undefined Then
					vItem = RoomPlanner.Items.Add(Max(vPeriodRow.DateFrom, BegOfDay(SelPeriodFrom)), Min(SelPeriodDateTo, ?(ValueIsFilled(vPeriodRow.DateTo), vPeriodRow.DateTo, SelPeriodDateTo)));
					vDims = New Map;
					vDims.Insert("Room", ?(ValueIsFilled(vPeriodRow.Room), vPeriodRow.Room, vPeriodRow.OverbookingIndex));
					vItem.DimensionValues = New FixedMap(vDims);
					vItem.BackColor = WebColors.Brown;
					vItem.TextColor = WebColors.White;
					vItem.Text = TrimAll(GuestGroupDescription);
					vItem.ToolTip = "" + ?(ValueIsFilled(GuestGroup), Format(GuestGroup.Code, "NFD=0; NG=") + " ", "") + TrimAll(GuestGroupDescription) + Chars.LF + 
					                ?(ValueIsFilled(vPeriodRow.Room), TrimAll(vPeriodRow.Room) + ", ", TrimAll(vPeriodRow.RoomType.Code) + ", ") + Format(vPeriodRow.DateFrom, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(vPeriodRow.DateTo, "DF='dd.MM.yyyy HH:mm'");
					vItem.Value = SelectedReservationPeriods.IndexOf(vPeriodRow);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // FillRoomPlannerNewGroupReservationPeriods

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetRoomStatusIcon(pRoomStatus, pRoomStatusIcon)
	vPicture = PictureLib.Empty;
	If ValueIsFilled(pRoomStatus) Then
		If ValueIsFilled(pRoomStatusIcon) Then
			If pRoomStatusIcon = PredefinedValue("Enum.RoomStatusesIcons.None") Then
				vPicture = PictureLib.Empty;
			ElsIf pRoomStatusIcon = PredefinedValue("Enum.RoomStatusesIcons.Reserved") Then
				vPicture = PictureLib.RoomStatusReserved;
			ElsIf pRoomStatusIcon = PredefinedValue("Enum.RoomStatusesIcons.Occupied") Then
				vPicture = PictureLib.Occupied;
			ElsIf pRoomStatusIcon = PredefinedValue("Enum.RoomStatusesIcons.OccupiedDirty") Then
				vPicture = PictureLib.OccupiedDirty;
			ElsIf pRoomStatusIcon = PredefinedValue("Enum.RoomStatusesIcons.Waiting") Then
				vPicture = PictureLib.Waiting;
			ElsIf pRoomStatusIcon = PredefinedValue("Enum.RoomStatusesIcons.TidyingUp") Then
				vPicture = PictureLib.RoomStatusCleaning;
			ElsIf pRoomStatusIcon = PredefinedValue("Enum.RoomStatusesIcons.CheckOut") Then
				vPicture = PictureLib.TidyingUp;
			ElsIf pRoomStatusIcon = PredefinedValue("Enum.RoomStatusesIcons.Vacant") Then
				vPicture = PictureLib.Vacant;
			ElsIf pRoomStatusIcon = PredefinedValue("Enum.RoomStatusesIcons.Repair") Then
				vPicture = PictureLib.RoomStatusRepair;
			ElsIf pRoomStatusIcon = PredefinedValue("Enum.RoomStatusesIcons.Luggage") Then
				vPicture = PictureLib.RoomStatusLuggage;
			ElsIf pRoomStatusIcon = PredefinedValue("Enum.RoomStatusesIcons.Malfunction") Then
				vPicture = PictureLib.RoomStatusMalfunction;
			EndIf;
		EndIf;
	EndIf;
	Return vPicture;
EndFunction // GetRoomStatusIcon

// -----------------------------------------------------------------------------
&AtServer
Procedure FillMonthes()
	vCurMonth = Month(CurrentSessionDate());
	vCurYear = Year(CurrentSessionDate());
	vNextYearStr = Format(vCurYear + 1, "ND=4; NFD=; NG=");
	Items.SelMonth.ChoiceList.Clear();
	Items.SelMonth.ChoiceList.Add(0, NStr("en='Today'; de='Heute'; ru='Сегодня'"));
	For i = 1 To 12 Do
		vMonthNum = vCurMonth + i - 1;
		If vMonthNum > 12 Then
			vMonthNum = vMonthNum - 12;
			If vMonthNum = 1 Then
				Items.SelMonth.ChoiceList.Add(vMonthNum, cmGetMonthName(vMonthNum) + " " + Right(vNextYearStr, 2));
			Else
				Items.SelMonth.ChoiceList.Add(vMonthNum, cmGetMonthName(vMonthNum));
			EndIf;
		Else
			Items.SelMonth.ChoiceList.Add(vMonthNum, cmGetMonthName(vMonthNum));
		EndIf;
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
// Colors used in form
// -----------------------------------------------------------------------------
&AtServer
Procedure LoadColorsFromHotel()
	// Default colors
	WhiteColor = New Color(255, 255, 255);
	BlackColor = New Color(0, 0, 0);
	AccommodationWithDebtColor = New Color(0, 150, 0);
	AccommodationWithDebtTextColor = WhiteColor;
	CheckInColor = New Color(144, 238, 144);
	CheckOutColor = New Color(200, 200, 200);
	ReservationWithDebtColor = New Color(65, 105, 225);
	ReservationColor = New Color(166, 202, 240);
	GuaranteedReservationColor = New Color(254, 228, 181);
	RoomBlockColor = New Color(1, 1, 1);
	RoomQuotaColor = New Color(255, 200, 0);
	EventColor = New Color(240, 240, 240);
	NoPriceColor = WebColors.Yellow;
	
	// Load colors from hotel
	If ValueIsFilled(SelHotel) Then
		vCheckInColor = SelHotel.CheckInColor.Get();
		If vCheckInColor <> Undefined And TypeOf(vCheckInColor) = Type("Color") Then
			CheckInColor = vCheckInColor;
		EndIf;
		vCheckOutColor = SelHotel.CheckOutColor.Get();
		If vCheckOutColor <> Undefined And TypeOf(vCheckOutColor) = Type("Color") Then
			CheckOutColor = vCheckOutColor;
		EndIf;
		vAccommodationWithDebtColor = SelHotel.AccommodationWithDebtColor.Get();
		If vAccommodationWithDebtColor <> Undefined And TypeOf(vAccommodationWithDebtColor) = Type("Color") Then
			AccommodationWithDebtColor = vAccommodationWithDebtColor;
		EndIf;
		vReservationColor = SelHotel.ReservationColor.Get();
		If vReservationColor <> Undefined And TypeOf(vReservationColor) = Type("Color") Then
			ReservationColor = vReservationColor;
		EndIf;
		vReservationWithDebtColor = SelHotel.ReservationWithDebtColor.Get();
		If vReservationWithDebtColor <> Undefined And TypeOf(vReservationWithDebtColor) = Type("Color") Then
			ReservationWithDebtColor = vReservationWithDebtColor;
		EndIf;
		vGuaranteedReservationColor = SelHotel.GuaranteedReservationColor.Get();
		If vGuaranteedReservationColor <> Undefined And TypeOf(vGuaranteedReservationColor) = Type("Color") Then
			GuaranteedReservationColor = vGuaranteedReservationColor;
		EndIf;
	EndIf;
EndProcedure // LoadColorsFromHotel

// -----------------------------------------------------------------------------
Procedure BuildSettingsCollapsedTitle()
	vTitle = NStr("en='From '; ru='С '; de='Von '") + Format(SelPeriodFrom, "DF=dd.MM.yyyy") + 
	         NStr("en=' for '; ru=' на '; de=' für '") + GetPeriodDurationPresentation(SpreadsheetScale) + 
			 ?(ValueIsFilled(SelRoom), NStr("en=' by '; ru=' по '; de=' auf dem '") + TrimAll(tcOnServer.cmGetAttributeByRef(SelRoom, "Description")), "") + 
			 ?(ValueIsFilled(SelRoomType), NStr("en=' by '; ru=' по '; de=' auf dem '") + TrimAll(tcOnServer.cmGetAttributeByRef(SelRoomType, "Description")), "") + 
			 ?(SelRoomTypes.Count() > 0, NStr("en=' by '; ru=' по '; de=' auf dem '") + TrimAll(SelRoomTypes), "") + 
			 ?(ValueIsFilled(SelRoomClass), NStr("en=' by '; ru=' по '; de=' auf dem '") + TrimAll(tcOnServer.cmGetAttributeByRef(SelRoomClass, "Description")), "") + 
			 ?(ValueIsFilled(SelRoomSection), NStr("en=' by '; ru=' по '; de=' auf dem '") + TrimAll(tcOnServer.cmGetAttributeByRef(SelRoomSection, "Description")), "");
	Items.SettingsGroup.Title = vTitle;
	
	vGroupTitle = NStr("en='Group'; ru='Группа'; de='Gruppe'");
	If GuestGroupCreationMode And ValueIsFilled(GuestGroup) Then
		vGroupTitle = NStr("en='Current group is '; ru='Текущая группа '; de='Aktuelle Gruppe ist '") + Format(tcOnServer.cmGetAttributeByRef(GuestGroup, "Code"), "NFD=0; NG=");
	EndIf;
	Items.GroupOperations.Title = vGroupTitle;
EndProcedure // BuildSettingsCollapsedTitle

// -----------------------------------------------------------------------------
Function GetPeriodDurationPresentation(pScale)
	If pScale = 0.1 Then
		Return NStr("en='1 day'; ru='1 день'; de='1 Tag'");
	ElsIf pScale = 0.25 Then
		Return NStr("en='1 week'; ru='1 неделю'; de='1 Woche'");
	ElsIf pScale = 0.5 Then
		Return NStr("en='2 weeks'; ru='2 недели'; de='2 Wochen'");
	ElsIf pScale = 1 Then
		Return NStr("en='1 month'; ru='1 месяц'; de='1 Monat'");
	ElsIf pScale = 2 Then
		Return NStr("en='2 monthes'; ru='2 месяца'; de='2 Monate'");
	EndIf;
	Return "";
EndFunction // GetPeriodDurationPresentation

// -----------------------------------------------------------------------------
&AtServer
Procedure AddItemBalances(pItem, pDoc, pRoomInDocument, pBalances, 
	                      BlackColor, WhiteColor, AccommodationWithDebtColor, AccommodationWithDebtTextColor, CheckOutColor, CheckInColor, 
	                      ReservationColor, GuaranteedReservationColor, ReservationWithDebtColor, NoPriceColor)
	vBalanceIsZero = True;
	If SelShowAllGuests = 0 Then
		vBalancesRows = pBalances.FindRows(New Structure("FolioParentDocNumber", pDoc.Accommodation.Number));
	Else
		vBalancesRows = pBalances.FindRows(New Structure("FolioParentDoc", pDoc.Accommodation));
	EndIf;
	If vBalancesRows.Count() > 0 Then
		For Each vBalancesRow In vBalancesRows Do
			If vBalancesRow.ClientSumBalance > 0 Then
				pItem.Text = pItem.Text + " - " + NStr("en='Debt: ';ru='Долг: ';de='Schuld: '") + Format(vBalancesRow.ClientSumBalance, "NFD=2; NZ=");
				If Not SelHotel.DoNotShowTooltipsInRoomsGanttChart Then
					pItem.ToolTip = pItem.ToolTip + Chars.LF + NStr("en='Debt: ';ru='Долг: ';de='Schuld: '") + Format(vBalancesRow.ClientSumBalance, "NFD=2; NZ=");
				EndIf;
				If TypeOf(pDoc.Accommodation) = Type("DocumentRef.Accommodation") Then
					If vBalancesRow.ClientLimitBalance < vBalancesRow.ClientSumBalance Then
						vBalanceIsZero = False;
					EndIf;
				EndIf;
			ElsIf vBalancesRow.ClientSumBalance < 0 Then
				pItem.Text = pItem.Text + " - " + NStr("en='Advance: ';ru='Предоплата: ';de='Kundenschuld: '") + Format(-vBalancesRow.ClientSumBalance, "NFD=2; NZ=");
				If Not SelHotel.DoNotShowTooltipsInRoomsGanttChart Then
					pItem.ToolTip = pItem.ToolTip + Chars.LF + NStr("en='Advance: ';ru='Предоплата: ';de='Kundenschuld: '") + Format(-vBalancesRow.ClientSumBalance, "NFD=2; NZ=");
				EndIf;
			EndIf;
			If vBalancesRow.ClientLimitBalance <> 0 Then
				pItem.Text = pItem.Text + ", " + NStr("en='Preauth.: ';ru='Преавт.: ';de='Voraut.: '") + Format(vBalancesRow.ClientLimitBalance, "NFD=2; NZ=");
				If Not SelHotel.DoNotShowTooltipsInRoomsGanttChart Then
					pItem.ToolTip = pItem.ToolTip + Chars.LF + NStr("en='Preauthorized: ';ru='Преавторизовано: ';de='Vorautorisiert: '") + Format(vBalancesRow.ClientLimitBalance, "NFD=2; NZ=");
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	rBarForeColor = WebColors.Black;
	pItem.BackColor = GetChartBarColor(pDoc, pDoc.Status, pDoc.Accommodation, vBalanceIsZero, pRoomInDocument, rBarForeColor, 
	                                   BlackColor, WhiteColor, AccommodationWithDebtColor, AccommodationWithDebtTextColor, CheckOutColor, CheckInColor, 
	                                   ReservationColor, GuaranteedReservationColor, ReservationWithDebtColor, NoPriceColor);
	pItem.TextColor = rBarForeColor;
EndProcedure // AddItemBalances

// -----------------------------------------------------------------------------
&AtServer
Function GetChartBarColor(vRow, vStatus, vCurDoc, vBalanceIsZero, vRoomInTheDocument, rBarForeColor, 
	                      pBlackColor, pWhiteColor, pAccommodationWithDebtColor, pAccommodationWithDebtTextColor, pCheckOutColor, pCheckInColor, 
						  pReservationColor, pGuaranteedReservationColor, pReservationWithDebtColor, pNoPriceColor)
	vBarColor = Undefined;
	rBarForeColor = pBlackColor;
	// Set period color
	vLockRoomColor = WebColors.Red;
	vClientTypeColor = Undefined;
	If ValueIsFilled(vRow.ClientType) Then
		If vRow.ClientTypeColor <> Undefined Then
			vClientTypeColor = vRow.ClientTypeColor;
		EndIf;
	EndIf;
	vCustomerColor = Undefined;
	If ValueIsFilled(vRow.Customer) Then
		If vRow.CustomerColor <> Undefined Then
			vCustomerColor = vRow.CustomerColor;
		EndIf;
	EndIf;
	vContractColor = Undefined;
	If ValueIsFilled(vRow.Contract) Then
		If vRow.ContractColor <> Undefined Then
			vContractColor = vRow.ContractColor;
		EndIf;
	EndIf;
	vRoomQuotaColor = Undefined;
	If ValueIsFilled(vRow.RoomQuota) Then
		If vRow.RoomQuotaColor <> Undefined Then
			vRoomQuotaColor = vRow.RoomQuotaColor;
		EndIf;
	EndIf;
	vGuestGroupColor = Undefined;
	If ValueIsFilled(vRow.GuestGroup) Then
		If vRow.GuestGroupColor <> Undefined Then
			vGuestGroupColor = vRow.GuestGroupColor;
		EndIf;
	EndIf;
	If TypeOf(vCurDoc) = Type("DocumentRef.Accommodation") Then
		If vRow.IsClosedForEdit And ValueIsFilled(vStatus) And vRow.StatusIsInHouse Then
			vBarColor = vLockRoomColor;
		ElsIf Not vBalanceIsZero Then
			vBarColor = pAccommodationWithDebtColor;
			rBarForeColor = pWhiteColor;
		Else
			If ValueIsFilled(vStatus) Then
				If Not vRow.StatusIsInHouse Then
					vBarColor = pCheckOutColor;
				Else
					If vGuestGroupColor <> Undefined Then
						vBarColor = vGuestGroupColor;
					ElsIf vRoomQuotaColor <> Undefined Then
						vBarColor = vRoomQuotaColor;
					ElsIf vContractColor <> Undefined Then
						vBarColor = vContractColor;
					ElsIf vCustomerColor <> Undefined Then
						vBarColor = vCustomerColor;
					ElsIf vClientTypeColor <> Undefined Then
						vBarColor = vClientTypeColor;
					Else
						vBarColor = pCheckInColor;
					EndIf;
				EndIf;
			Else
				vBarColor = pAccommodationWithDebtTextColor;
				rBarForeColor = pWhiteColor;
			EndIf;
		EndIf;
	Else
		If TypeOf(vCurDoc) = Type("DocumentRef.Reservation") And vRow.IsClosedForEdit Then
			vBarColor = vLockRoomColor;
		ElsIf vGuestGroupColor <> Undefined Then
			vBarColor = vGuestGroupColor;
		ElsIf vRoomQuotaColor <> Undefined Then
			vBarColor = vRoomQuotaColor;
		ElsIf vContractColor <> Undefined Then
			vBarColor = vContractColor;
		ElsIf vCustomerColor <> Undefined Then
			vBarColor = vCustomerColor;
		ElsIf vClientTypeColor <> Undefined Then
			vBarColor = vClientTypeColor;
		Else
			If ValueIsFilled(vStatus) Then
				vReservationStatusColor = Undefined;
				If vRow.StatusColor <> Undefined Then
					vReservationStatusColor = vRow.StatusColor;
				EndIf;
				If vReservationStatusColor <> Undefined Then
					vBarColor = vReservationStatusColor;
				Else
					//If Not vBalanceIsZero Then
					//	vBarColor = pReservationWithDebtColor;
					//	rBarForeColor = pWhiteColor;
					//Else
						If vRow.StatusIsGuaranteed Then
							vBarColor = pGuaranteedReservationColor;
						Else
							vBarColor = pReservationColor;
						EndIf;
					//EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If SelShowAllGuests = 0 Then
		If StrFind(vRow.PricePresentation, "N/A") > 0 Or StrFind(vRow.PricePresentation, "---") > 0 Then
			vBarColor = pNoPriceColor;
			rBarForeColor = pBlackColor;
		EndIf;
	EndIf;
	Return vBarColor;
EndFunction // GetChartBarColor

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetOneRoomReservationsList(pAccommodationNumber, pGuestGroup, pCheckInDate, pCheckOutDate)
	vOneRoomDocsList = New ValueList();
	
	vOneRoomDocs = cmGetOneRoomReservations(pAccommodationNumber, pGuestGroup, pCheckInDate, pCheckOutDate);
	For Each vOneRoomDocsRow In vOneRoomDocs Do
		vOneRoomDoc = vOneRoomDocsRow.Ref;
		
		vOneRoomDocStruct = New Structure();
		
		vOneRoomDocStruct.Insert("Accommodation", vOneRoomDoc);
		vOneRoomDocStruct.Insert("AccommodationNumber", vOneRoomDoc.Number);
		vOneRoomDocStruct.Insert("ParentDoc", vOneRoomDoc.ParentDoc);
		If ValueIsFilled(vOneRoomDoc.ParentDoc) Then
			vOneRoomDocStruct.Insert("ParentDocRoom", vOneRoomDoc.ParentDoc.Room);
		Else
			vOneRoomDocStruct.Insert("ParentDocRoom", Undefined);
		EndIf;
		
		vOneRoomGuest = vOneRoomDoc.Guest;
		vOneRoomDocStruct.Insert("Guest", vOneRoomGuest);
		If ValueIsFilled(vOneRoomGuest) Then
			vOneRoomDocStruct.Insert("GuestDescription", TrimR(vOneRoomGuest.Description));
			vOneRoomDocStruct.Insert("GuestFullName", TrimR(vOneRoomGuest.FullName));
			vOneRoomDocStruct.Insert("GuestCitizenship", vOneRoomGuest.Citizenship);
			If ValueIsFilled(vOneRoomGuest.Citizenship) Then
				vOneRoomDocStruct.Insert("GuestCitizenshipISOCode", vOneRoomGuest.Citizenship.ISOCode);
			Else
				vOneRoomDocStruct.Insert("GuestCitizenshipISOCode", "");
			EndIf;
			vOneRoomDocStruct.Insert("GuestSex", vOneRoomGuest.Sex);
			vOneRoomDocStruct.Insert("GuestDateOfBirth", vOneRoomGuest.DateOfBirth);
		Else
			vOneRoomDocStruct.Insert("GuestDescription", "");
			vOneRoomDocStruct.Insert("GuestFullName", "");
			vOneRoomDocStruct.Insert("GuestCitizenship", Undefined);
			vOneRoomDocStruct.Insert("GuestCitizenshipISOCode", "");
			vOneRoomDocStruct.Insert("GuestSex", Undefined);
			vOneRoomDocStruct.Insert("GuestDateOfBirth", '00010101');
		EndIf;
		
		vOneRoomDocStruct.Insert("CheckInDate", vOneRoomDoc.CheckInDate);
		vOneRoomDocStruct.Insert("CheckOutDate", vOneRoomDoc.CheckOutDate);
		vOneRoomDocStruct.Insert("AccommodationType", vOneRoomDoc.AccommodationType);
		vOneRoomDocStruct.Insert("AccommodationTypeType", vOneRoomDoc.AccommodationType.Type);
		vOneRoomDocStruct.Insert("RoomRate", vOneRoomDoc.RoomRate);
		vOneRoomDocStruct.Insert("RoomRateDescription", TrimAll(vOneRoomDoc.RoomRate));
		vOneRoomDocStruct.Insert("AccommodationTemplate", vOneRoomDoc.AccommodationTemplate);
		vOneRoomDocStruct.Insert("AccommodationTemplateDescription", TrimAll(vOneRoomDoc.AccommodationTemplate));
		
		vOneRoomDocClientType = vOneRoomDoc.ClientType;
		vOneRoomDocStruct.Insert("ClientType", vOneRoomDocClientType);
		If ValueIsFilled(vOneRoomDocClientType) Then
			vOneRoomDocStruct.Insert("ClientTypeDescription", TrimAll(vOneRoomDocClientType));
			vOneRoomDocStruct.Insert("ClientTypeColor", ?(vOneRoomDocClientType.Color <> Undefined, vOneRoomDocClientType.Color.Get(), Undefined));
		Else
			vOneRoomDocStruct.Insert("ClientTypeDescription", "");
			vOneRoomDocStruct.Insert("ClientTypeColor", Undefined);
		EndIf;
		
		vOneRoomDocStatus = vOneRoomDoc.ReservationStatus;
		vOneRoomDocStruct.Insert("Status", vOneRoomDocStatus);
		If ValueIsFilled(vOneRoomDocStatus) Then
			vOneRoomDocStruct.Insert("StatusColor", ?(vOneRoomDocStatus.Color <> Undefined, vOneRoomDocStatus.Color.Get(), Undefined));
		Else
			vOneRoomDocStruct.Insert("StatusColor", Undefined);
		EndIf;
		
		vOneRoomDocHotelProduct = vOneRoomDoc.HotelProduct;
		vOneRoomDocStruct.Insert("HotelProduct", vOneRoomDocHotelProduct);
		If ValueIsFilled(vOneRoomDocHotelProduct) Then
			vOneRoomDocStruct.Insert("HotelProductDescription", TrimR(vOneRoomDocHotelProduct.Description));
			vOneRoomDocStruct.Insert("HotelProductParent", vOneRoomDocHotelProduct.Parent);
			vOneRoomDocStruct.Insert("HotelProductParentDescription", TrimAll(vOneRoomDocHotelProduct.Parent));
		Else
			vOneRoomDocStruct.Insert("HotelProductDescription", "");
			vOneRoomDocStruct.Insert("HotelProductParent", Undefined);
			vOneRoomDocStruct.Insert("HotelProductParentDescription", "");
		EndIf;
		
		vOneRoomDocStruct.Insert("ContactPerson", vOneRoomDoc.ContactPerson);
		
		vOneRoomDocCustomer = vOneRoomDoc.Customer;
		vOneRoomDocStruct.Insert("Customer", vOneRoomDocCustomer);
		If ValueIsFilled(vOneRoomDocCustomer) Then
			vOneRoomDocStruct.Insert("CustomerCode", TrimR(vOneRoomDocCustomer.Code));
			vOneRoomDocStruct.Insert("CustomerDescription", TrimR(vOneRoomDocCustomer.Description));
			vOneRoomDocStruct.Insert("CustomerColor", ?(vOneRoomDocCustomer.Color <> Undefined, vOneRoomDocCustomer.Color.Get(), Undefined));
		Else
			vOneRoomDocStruct.Insert("CustomerCode", "");
			vOneRoomDocStruct.Insert("CustomerDescription", "");
			vOneRoomDocStruct.Insert("CustomerColor", Undefined);
		EndIf;
		
		vOneRoomDocContract = vOneRoomDoc.Contract;
		vOneRoomDocStruct.Insert("Contract", vOneRoomDocContract);
		If ValueIsFilled(vOneRoomDocContract) Then
			vOneRoomDocStruct.Insert("ContractCode", TrimR(vOneRoomDocContract.Code));
			vOneRoomDocStruct.Insert("ContractDescription", TrimR(vOneRoomDocContract.Description));
			vOneRoomDocStruct.Insert("ContractColor", ?(vOneRoomDocContract.Color <> Undefined, vOneRoomDocContract.Color.Get(), vOneRoomDocContract.Color));
		Else
			vOneRoomDocStruct.Insert("ContractCode", "");
			vOneRoomDocStruct.Insert("ContractDescription", "");
			vOneRoomDocStruct.Insert("ContractColor", Undefined);
		EndIf;
		
		vOneRoomDocStruct.Insert("Agent", vOneRoomDoc.Agent);
		vOneRoomDocStruct.Insert("Remarks", vOneRoomDoc.Remarks);
		vOneRoomDocStruct.Insert("Car", vOneRoomDoc.Car);
		vOneRoomDocStruct.Insert("IsMaster", vOneRoomDoc.IsMaster);
		
		vOneRoomDocPlannedPaymentMethod = vOneRoomDoc.PlannedPaymentMethod;
		vOneRoomDocStruct.Insert("PlannedPaymentMethod", vOneRoomDocPlannedPaymentMethod);
		If ValueIsFilled(vOneRoomDocPlannedPaymentMethod) Then
			vOneRoomDocStruct.Insert("PlannedPaymentMethodCode", TrimR(vOneRoomDocPlannedPaymentMethod.Code));
			vOneRoomDocStruct.Insert("PlannedPaymentMethodDescription", TrimR(vOneRoomDocPlannedPaymentMethod.Description));
			vOneRoomDocStruct.Insert("IsByBankTransfer", vOneRoomDocPlannedPaymentMethod.IsByBankTransfer);
		Else
			vOneRoomDocStruct.Insert("PlannedPaymentMethodCode", "");
			vOneRoomDocStruct.Insert("PlannedPaymentMethodDescription", "");
			vOneRoomDocStruct.Insert("IsByBankTransfer", False);
		EndIf;
		
		vOneRoomDocStruct.Insert("NumberOfPersons", vOneRoomDoc.NumberOfPersons);
		vOneRoomDocStruct.Insert("ServicePackage", vOneRoomDoc.ServicePackage);
		vOneRoomDocStruct.Insert("ServicePackageDescription", TrimAll(vOneRoomDoc.ServicePackage));
		
		vOneRoomDocsList.Add(vOneRoomDocStruct);
	EndDo;
	
	Return vOneRoomDocsList;
EndFunction // GetOneRoomReservationsList

// -----------------------------------------------------------------------------
&AtServer
Procedure AddOneRoomGuestsForReservationWithoutRoom(pDoc)
	l = 0;
	vOneRoomDocsList = GetOneRoomReservationsList(pDoc.AccommodationNumber, pDoc.GuestGroup, pDoc.CheckInDate, pDoc.CheckOutDate);
	For Each vOneRoomDocsListItem In vOneRoomDocsList Do
		vOneRoomDocStruct = vOneRoomDocsListItem.Value;
		If vOneRoomDocStruct.Accommodation <> pDoc.Accommodation Then
			l = l + 1;
			vNewDoc = AllRooms.Insert(AllRooms.IndexOf(pDoc) + l);
			FillPropertyValues(vNewDoc, pDoc);
			FillPropertyValues(vNewDoc, vOneRoomDocStruct);
			vNewDoc.NumberOfBeds = 0;
		EndIf;
	EndDo;
EndProcedure // AddOneRoomGuestsForReservationWithoutRoom

// -----------------------------------------------------------------------------
&AtServer
Function GetRoomsGanttChartData(pPeriodFrom, pPeriodTo)
	// Check should we show only vacant rooms
	vShowVacantRoomsOnly = False;
	// Reset some variables
	SelCheckInDate = '00010101';
	SelCheckOutDate = '00010101';
	// Build and run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInventoryBalance.Hotel,
	|	RoomInventoryBalance.Room,
	|	RoomInventoryBalance.RoomType,
	|	ISNULL(RoomInventoryBalance.TotalRoomsBalance, 0) AS TotalRoomsBalance,
	|	ISNULL(RoomInventoryBalance.RoomsVacantBalance, 0) AS RoomsVacantBalance
	|INTO RoomInventoryBalance
	|FROM
	|	AccumulationRegister.RoomInventory.Balance(&qDate, NOT Room.DeletionMark AND NOT RoomType.DeletionMark AND NOT Hotel.DeletionMark AND NOT RoomType.DoesNotAffectRoomRevenueStatistics AND NOT RoomType.IsVirtual " + 
	?(SelRoomTypes.Count() > 0, " AND RoomType IN (&qRoomTypes)", 
		?(ValueIsFilled(SelRoomType), ?(SelRoomType.IsFolder, " AND RoomType IN HIERARCHY(&qRoomType)", " AND RoomType = &qRoomType"), "")) + 
	?(ValueIsFilled(SelRoom), ?(SelRoom.IsFolder, " AND Room IN HIERARCHY(&qRoom)", " AND Room = &qRoom"), "") + 
	?(ValueIsFilled(SelRoomClass), " AND RoomType.RoomClass = &qRoomClass", "") + 
	?(ValueIsFilled(SelRoomSection), ?(SelRoomSection.IsFolder, " AND Room.RoomSection IN HIERARCHY(&qRoomSection)", " AND Room.RoomSection = &qRoomSection"), "") + 
	?(ValueIsFilled(SelHotel), ?(SelHotel.IsFolder, " AND Hotel IN HIERARCHY(&qHotel)", " AND Hotel = &qHotel"), "") + "
	|) AS RoomInventoryBalance
	|;
	|
	|SELECT
	|	RoomsToShow.Hotel,
	|	RoomsToShow.Room,
	|	RoomsToShow.RoomType,
	|	RoomsToShow.TotalRoomsBalance AS TotalRoomsBalance,
	|	RoomsToShow.RoomsVacantBalance AS RoomsVacantBalance
	|INTO RoomsToShow
	|FROM (
	|	SELECT
	|		NormalRooms.Hotel,
	|		NormalRooms.Room,
	|		NormalRooms.RoomType,
	|		NormalRooms.TotalRoomsBalance AS TotalRoomsBalance,
	|		NormalRooms.RoomsVacantBalance AS RoomsVacantBalance
	|	FROM
	|		RoomInventoryBalance AS NormalRooms 
	|	WHERE
	|		NormalRooms.TotalRoomsBalance <> 0
	|		AND (NOT &qShowVacantRoomsOnly 
	|				OR &qShowVacantRoomsOnly AND NormalRooms.RoomsVacantBalance > 0) 
	|	UNION ALL 
	|	SELECT
	|		VirtualRooms.Owner,
	|		VirtualRooms.Ref,
	|		VirtualRooms.RoomType,
	|		0,
	|		0
	|	FROM
	|		Catalog.Rooms AS VirtualRooms
	|	WHERE
	|		NOT &qShowVacantRoomsOnly 
	|		AND ISNULL(VirtualRooms.RoomType.DoesNotAffectRoomRevenueStatistics, FALSE)
	|		AND NOT VirtualRooms.DeletionMark 
	|		AND NOT ISNULL(VirtualRooms.RoomType.DeletionMark, FALSE) 
	|		AND NOT VirtualRooms.Owner.DeletionMark " + 
	?(SelRoomTypes.Count() > 0, " AND VirtualRooms.RoomType IN (&qRoomTypes)", 
		?(ValueIsFilled(SelRoomType), ?(SelRoomType.IsFolder, " AND VirtualRooms.RoomType IN HIERARCHY(&qRoomType)", " AND VirtualRooms.RoomType = &qRoomType"), "")) + 
	?(ValueIsFilled(SelRoom), ?(SelRoom.IsFolder, " AND VirtualRooms.Ref IN HIERARCHY(&qRoom)", " AND VirtualRooms.Ref = &qRoom"), "") + 
	?(ValueIsFilled(SelRoomClass), " AND VirtualRooms.RoomType.RoomClass = &qRoomClass", "") + 
	?(ValueIsFilled(SelRoomSection), ?(SelRoomSection.IsFolder, " AND VirtualRooms.RoomSection IN HIERARCHY(&qRoomSection)", " AND VirtualRooms.RoomSection = &qRoomSection"), "") + 
	?(ValueIsFilled(SelHotel), ?(SelHotel.IsFolder, " AND VirtualRooms.Owner IN HIERARCHY(&qHotel)", " AND VirtualRooms.Owner = &qHotel"), "") + "
	|) AS RoomsToShow 
	|;
	|
	|SELECT 
	|	ResDocuments.Accommodation AS Accommodation,
	|	ResDocuments.Room AS Room,
	|	ResDocuments.RoomType AS RoomType,
	|	ResDocuments.Status AS Status,
	|	ResDocuments.CheckInDate AS CheckInDate,
	|	ResDocuments.CheckOutDate AS CheckOutDate,
	|	ResDocuments.AccommodationType AS AccommodationType,
	|	ResDocuments.RoomRate AS RoomRate
	|INTO ResDocuments
	|FROM (
	|SELECT
	|	ActiveDocuments.Recorder AS Accommodation,
	|	ActiveDocuments.Room AS Room,
	|	ActiveDocuments.RoomType AS RoomType,
	|	CASE
	|		WHEN ActiveDocuments.IsAccommodation THEN
	|			ActiveDocuments.AccommodationStatus 
	|		ELSE
	|			ActiveDocuments.ReservationStatus
	|	END AS Status,
	|	ActiveDocuments.PeriodFrom AS CheckInDate,
	|	ActiveDocuments.PeriodTo AS CheckOutDate,
	|	ActiveDocuments.AccommodationType AS AccommodationType,
	|	ActiveDocuments.RoomRate AS RoomRate
	|FROM
	|	AccumulationRegister.RoomInventory AS ActiveDocuments
	|WHERE
	|	ActiveDocuments.PeriodFrom < &qPeriodTo
	|	AND ActiveDocuments.PeriodTo > &qPeriodFrom " +  
	?(ValueIsFilled(SelHotel), ?(SelHotel.IsFolder, " AND ActiveDocuments.Hotel IN HIERARCHY(&qHotel)", " AND ActiveDocuments.Hotel = &qHotel"), "") + "
	|	AND ActiveDocuments.RecordType = &qExpense
	|	AND (ActiveDocuments.IsAccommodation OR ActiveDocuments.IsReservation) " + 
	?(Not IsBlankString(SelDocNumber), " AND ActiveDocuments.Recorder.Number = &qDocNumber", "") + 
	?(ValueIsFilled(SelCustomer), ?(SelCustomer.IsFolder, " AND ActiveDocuments.Customer IN HIERARCHY(&qCustomer)", " AND ActiveDocuments.Customer = &qCustomer"), "") + 
	?(ValueIsFilled(SelContract), " AND ActiveDocuments.Contract = &qContract", "") + 
	?(ValueIsFilled(SelGuestGroup), " AND ActiveDocuments.GuestGroup = &qGuestGroup", "") + 
	?(SelShowExpectedChangeRoomOnly, " AND (ActiveDocuments.PeriodTo < ActiveDocuments.CheckOutDate AND ActiveDocuments.CheckOutAccountingDate = &qBegOfCurrentDate OR ActiveDocuments.PeriodFrom > ActiveDocuments.CheckInDate AND ActiveDocuments.CheckInAccountingDate = &qBegOfCurrentDate)", "") + 
	?(SelIntersection,
	?(ValueIsFilled(SelCheckInDate), " AND ActiveDocuments.PeriodTo > &qCheckInDate", "") + 
	?(ValueIsFilled(SelCheckOutDate), " AND ActiveDocuments.PeriodFrom < &qCheckOutDate", ""), 
	?(ValueIsFilled(SelCheckInDate), " AND ActiveDocuments.PeriodFrom >= &qBegOfCheckInDate AND ActiveDocuments.PeriodFrom < &qEndOfCheckInDate", "") + 
	?(ValueIsFilled(SelCheckOutDate), " AND ActiveDocuments.PeriodTo >= &qBegOfCheckOutDate AND ActiveDocuments.PeriodTo < &qEndOfCheckOutDate", "")) + "
	|GROUP BY
	|	ActiveDocuments.Recorder,
	|	ActiveDocuments.Room,
	|	ActiveDocuments.RoomType,
	|	CASE
	|		WHEN ActiveDocuments.IsAccommodation THEN
	|			ActiveDocuments.AccommodationStatus 
	|		ELSE
	|			ActiveDocuments.ReservationStatus
	|	END,
	|	ActiveDocuments.PeriodFrom,
	|	ActiveDocuments.PeriodTo,
	|	ActiveDocuments.AccommodationType,
	|	ActiveDocuments.RoomRate
	|
	|UNION ALL
	|
	|SELECT
	|	PreliminaryDocuments.Ref,
	|	PreliminaryDocuments.Room,
	|	PreliminaryDocuments.RoomType,
	|	PreliminaryDocuments.ReservationStatus,
	|	PreliminaryDocuments.CheckInDate AS CheckInDate,
	|	PreliminaryDocuments.CheckOutDate AS CheckOutDate,
	|	PreliminaryDocuments.AccommodationType AS AccommodationType,
	|	PreliminaryDocuments.RoomRate AS RoomRate
	|FROM
	|	Document.Reservation AS PreliminaryDocuments
	|WHERE
	|	&qShowPreliminary
	|	AND PreliminaryDocuments.Room <> VALUE(Catalog.Rooms.EmptyRef)
	|	AND PreliminaryDocuments.CheckInDate < &qPeriodTo
	|	AND PreliminaryDocuments.CheckOutDate > &qPeriodFrom " +  
	?(ValueIsFilled(SelHotel), ?(SelHotel.IsFolder, " AND PreliminaryDocuments.Hotel IN HIERARCHY(&qHotel)", " AND PreliminaryDocuments.Hotel = &qHotel"), "") + "
	|	AND PreliminaryDocuments.Posted
	|	AND NOT PreliminaryDocuments.ReservationStatus.IsActive
	|	AND PreliminaryDocuments.ReservationStatus.IsPreliminary " +
	?(Not IsBlankString(SelDocNumber), " AND PreliminaryDocuments.Number = &qDocNumber", "") + 
	?(ValueIsFilled(SelCustomer), ?(SelCustomer.IsFolder, " AND PreliminaryDocuments.Customer IN HIERARCHY(&qCustomer)", " AND PreliminaryDocuments.Customer = &qCustomer"), "") + 
	?(ValueIsFilled(SelContract), " AND PreliminaryDocuments.Contract = &qContract", "") + 
	?(ValueIsFilled(SelGuestGroup), " AND PreliminaryDocuments.GuestGroup = &qGuestGroup", "") + 
	?(SelShowExpectedChangeRoomOnly, " AND FALSE", "") + 
	?(SelIntersection,
	?(ValueIsFilled(SelCheckInDate), " AND PreliminaryDocuments.CheckOutDate > &qCheckInDate", "") + 
	?(ValueIsFilled(SelCheckOutDate), " AND PreliminaryDocuments.CheckInDate < &qCheckOutDate", ""), 
	?(ValueIsFilled(SelCheckInDate), " AND PreliminaryDocuments.CheckInDate >= &qBegOfCheckInDate AND PreliminaryDocuments.CheckInDate < &qEndOfCheckInDate", "") + 
	?(ValueIsFilled(SelCheckOutDate), " AND PreliminaryDocuments.CheckOutDate >= &qBegOfCheckOutDate AND PreliminaryDocuments.CheckOutDate < &qEndOfCheckOutDate", "")) + "
	|) AS ResDocuments
	|;
	|
	|SELECT
	|	RoomsToShow.Hotel,
	|	RoomsToShow.Room,
	|	RoomsToShow.RoomType,
	|	Documents.Status AS Status,
	|	Documents.Accommodation AS Accommodation,
	|	ISNULL(Documents.Accommodation.NumberOfBedsPerRoom, 0) AS AccommodationNumberOfBedsPerRoom,
	|	Documents.Accommodation.Number AS AccommodationNumber,
	|	Documents.Accommodation.Date AS AccommodationDate,
	|	Documents.Accommodation.AccommodationTemplate AS AccommodationTemplate,
	|	Documents.Accommodation.ParentDoc AS ParentDoc,
	|	Documents.Accommodation.ClientType AS ClientType,
	|	Documents.Accommodation.Guest AS Guest,
	|	Documents.CheckInDate AS CheckInDate,
	|	Documents.CheckOutDate AS CheckOutDate,
	|	Documents.AccommodationType AS AccommodationType,
	|	Documents.RoomRate AS RoomRate,
	|	Documents.Accommodation.GuestGroup AS GuestGroup,
	|	Documents.Accommodation.HotelProduct AS HotelProduct,
	|	Documents.Accommodation.RoomQuota AS RoomQuota,
	|	Documents.Accommodation.Customer AS Customer,
	|	Documents.Accommodation.Contract AS Contract, 
	|	Documents.Accommodation.ContactPerson AS ContactPerson,
	|	Documents.Accommodation.Agent AS Agent, 
	|	Documents.Accommodation.PlannedPaymentMethod AS PlannedPaymentMethod, 
	|	Documents.Accommodation.NumberOfPersons AS NumberOfPersons, 
	|	MIN(RoomsToShow.RoomsVacantBalance) AS RoomsVacantBalance
	|INTO Accommodations
	|FROM
	|	RoomsToShow AS RoomsToShow
	|		" + ?(IsBlankString(SelGuestStr), "LEFT", "INNER") + " JOIN ResDocuments AS Documents
	|		ON RoomsToShow.Room = Documents.Room" + 
	?(SelShowExpectedChangeRoomOnly, "WHERE NOT (Documents.Accommodation IS NULL)", "") + " 
	|
	|GROUP BY
	|	RoomsToShow.Hotel,
	|	RoomsToShow.Room,
	|	RoomsToShow.RoomType,
	|	Documents.Status,
	|	Documents.Accommodation,
	|	ISNULL(Documents.Accommodation.NumberOfBedsPerRoom, 0),
	|	Documents.CheckInDate,
	|	Documents.CheckOutDate,
	|	Documents.AccommodationType,
	|	Documents.RoomRate
	|;
	|
	|SELECT DISTINCT
	|	FilterAccommodations.AccommodationNumber
	|INTO FilterAccommodations
	|FROM
	|	Accommodations AS FilterAccommodations
	|WHERE TRUE " +
	?(IsBlankString(SelRemarks), " AND TRUE", " AND (FilterAccommodations.Accommodation.Remarks LIKE &qRemarks OR FilterAccommodations.Accommodation.Car LIKE &qRemarks)") +  
	?(ValueIsFilled(SelGuest), " AND FilterAccommodations.Guest = &qGuest", 
	?(IsBlankString(SelGuestStr), " AND TRUE", " AND (FilterAccommodations.Guest.FullName LIKE &qGuestStr OR 
	|                                                 FilterAccommodations.Customer.Description LIKE &qGuestStr OR 
	|                                                 FilterAccommodations.Accommodation.Remarks LIKE &qGuestStr OR 
	|                                                 FilterAccommodations.Accommodation.Car LIKE &qGuestStr)")) + "
	|;
	|
	|SELECT
	|	Accommodations.Hotel AS Hotel,
	|	Accommodations.Hotel.SortCode AS HotelSortCode,
	|	Accommodations.Room AS Room,
	|	Accommodations.Room.SortCode AS RoomSortCode,
	|	Accommodations.Room AS RoomInDocument,
	|	ISNULL(Accommodations.Room.Description, """") AS RoomDescription,
	|	ISNULL(Accommodations.Room.IsFolder, FALSE) AS RoomIsFolder,
	|	Accommodations.Room.Parent AS RoomParent,
	|	Accommodations.Room.Parent.Description AS RoomParentDescription,
	|	Accommodations.Room.RoomStatus AS RoomRoomStatus,
	|	Accommodations.Room.RoomStatus.Description AS RoomRoomStatusDescription,
	|	ISNULL(Accommodations.Room.RoomStatus.Color, UNDEFINED) AS RoomRoomStatusColor,
	|	Accommodations.Room.RoomStatus.RoomStatusIcon AS RoomRoomStatusIcon,
	|	ISNULL(Accommodations.Room.StopSale, FALSE) AS RoomStopSale,
	|	ISNULL(Accommodations.Room.RoomPropertiesCodes, """") AS RoomRoomPropertiesCodes,
	|	Accommodations.RoomType AS RoomType,
	|	Accommodations.RoomType.SortCode AS RoomTypeSortCode,
	|	Accommodations.RoomType.Code AS RoomTypeCode,
	|	Accommodations.RoomType.Description AS RoomTypeDescription,
	|	ISNULL(Accommodations.RoomType.IsFolder, FALSE) AS RoomTypeIsFolder,
	|	ISNULL(Accommodations.RoomType.StopSale, FALSE) AS RoomTypeStopSale,
	|	Accommodations.RoomType.Parent AS RoomTypeParent,
	|	Accommodations.Accommodation AS Accommodation,
	|	Accommodations.AccommodationNumberOfBedsPerRoom AS AccommodationNumberOfBedsPerRoom,
	|	Accommodations.AccommodationNumber AS AccommodationNumber,
	|	Accommodations.AccommodationDate AS AccommodationDate,
	|	Accommodations.ParentDoc AS ParentDoc,
	|	Accommodations.ParentDoc.Room AS ParentDocRoom,
	|	ISNULL(Accommodations.ParentDoc.ReservationStatus.IsCheckIn, FALSE) AS ParentDocReservationStatusIsCheckIn,
	|	Accommodations.Guest AS Guest,
	|	Accommodations.Guest.Description AS GuestDescription,
	|	Accommodations.Guest.FullName AS GuestFullName,
	|	Accommodations.Guest.Citizenship AS GuestCitizenship,
	|	Accommodations.Guest.Citizenship.ISOCode AS GuestCitizenshipISOCode,
	|	Accommodations.Guest.Sex AS GuestSex,
	|	Accommodations.Guest.DateOfBirth AS GuestDateOfBirth,
	|	ISNULL(Accommodations.CheckInDate, &qEmptyDate) AS CheckInDate,
	|	ISNULL(Accommodations.CheckOutDate, &qEmptyDate) AS CheckOutDate,
	|	Accommodations.AccommodationType AS AccommodationType,
	|	Accommodations.AccommodationType.Type AS AccommodationTypeType,
	|	Accommodations.RoomRate AS RoomRate,
	|	Accommodations.RoomRate.Description AS RoomRateDescription,
	|	Accommodations.ClientType AS ClientType,
	|	Accommodations.ClientType.Description AS ClientTypeDescription,
	|	Accommodations.ClientType.Code AS ClientTypeCode,
	|	Accommodations.ClientType.Color AS ClientTypeColor,
	|	Accommodations.AccommodationTemplate AS AccommodationTemplate,
	|	Accommodations.AccommodationTemplate.Description AS AccommodationTemplateDescription,
	|	Accommodations.Status AS Status,
	|	Accommodations.Status.Description AS StatusDescription,
	|	Accommodations.Status.Color AS StatusColor,
	|	ISNULL(Accommodations.Status.IsInHouse, FALSE) AS StatusIsInHouse,
	|	ISNULL(Accommodations.Status.IsGuaranteed, FALSE) AS StatusIsGuaranteed,
	|	Accommodations.GuestGroup AS GuestGroup,
	|	Accommodations.GuestGroup.Code AS GuestGroupCode,
	|	Accommodations.GuestGroup.Description AS GuestGroupDescription,
	|	Accommodations.GuestGroup.Color AS GuestGroupColor,
	|	Accommodations.HotelProduct AS HotelProduct,
	|	Accommodations.HotelProduct.Description AS HotelProductDescription,
	|	Accommodations.HotelProduct.Parent AS HotelProductParent,
	|	Accommodations.HotelProduct.Parent.Description AS HotelProductParentDescription,
	|	Accommodations.RoomQuota AS RoomQuota,
	|	Accommodations.RoomQuota.Code AS RoomQuotaCode,
	|	Accommodations.RoomQuota.Description AS RoomQuotaDescription,
	|	Accommodations.RoomQuota.Color AS RoomQuotaColor,
	|	Accommodations.Customer AS Customer,
	|	Accommodations.Customer.Code AS CustomerCode,
	|	Accommodations.Customer.Description AS CustomerDescription,
	|	Accommodations.Customer.Color AS CustomerColor,
	|	ISNULL(Accommodations.Customer.IsIndividual, TRUE) AS CustomerIsIndividual,
	|	Accommodations.Contract AS Contract,
	|	Accommodations.Contract.Code AS ContractCode,
	|	Accommodations.Contract.Description AS ContractDescription,
	|	Accommodations.Contract.Color AS ContractColor,
	|	Accommodations.ContactPerson AS ContactPerson,
	|	Accommodations.Agent AS Agent,
	|	Accommodations.Accommodation.Remarks AS Remarks,
	|	Accommodations.Accommodation.Car AS Car,
	|	Accommodations.Accommodation.IsMaster AS IsMaster,
	|	Accommodations.Accommodation.IsClosedForEdit AS IsClosedForEdit,
	|	Accommodations.PlannedPaymentMethod AS PlannedPaymentMethod,
	|	Accommodations.PlannedPaymentMethod.Code AS PlannedPaymentMethodCode,
	|	Accommodations.PlannedPaymentMethod.Description AS PlannedPaymentMethodDescription,
	|	Accommodations.PlannedPaymentMethod.IsByBankTransfer AS IsByBankTransfer,
	|	Accommodations.NumberOfPersons AS NumberOfPersons,
	|	Accommodations.Accommodation.ServicePackage AS ServicePackage,
	|	Accommodations.Accommodation.ServicePackage.Description AS ServicePackageDescription,
	|	CAST(Accommodations.Accommodation.PricePresentation AS STRING(17)) AS PricePresentation,
	|	0 AS DurationInSeconds,
	|	0 AS OverbookingIndex,
	|	CASE
	|		WHEN Accommodations.Accommodation.AccommodationType.Type = &qAccomodationTypesRoom THEN 0
	|		WHEN Accommodations.Accommodation.AccommodationType.Type = &qAccomodationTypesBeds THEN 0
	|		WHEN Accommodations.Accommodation.AccommodationType.Type = &qAccomodationTypesAdditionalBed THEN 1
	|		ELSE 2
	|	END AS AccommodationTypeSortCode,
	|	CASE
	|		WHEN NOT Accommodations.Accommodation.NumberOfBeds IS NULL THEN Accommodations.Accommodation.NumberOfBeds
	|		WHEN NOT Accommodations.Accommodation.RoomBlockType IS NULL THEN Accommodations.Room.NumberOfBedsPerRoom
	|		ELSE 0
	|	END AS NumberOfBeds,
	|	Accommodations.RoomsVacantBalance AS RoomsVacantBalance,
	|	ISNULL(Accommodations.Accommodation.RoomQuantity, 1) AS RoomQuantity
	|
	|FROM 
	|	Accommodations AS Accommodations
	|WHERE " + 
	?(Not IsBlankString(SelRemarks) OR ValueIsFilled(SelGuest) OR NOT IsBlankString(SelGuestStr), " Accommodations.AccommodationNumber IN (SELECT FilterAccommodations.AccommodationNumber FROM FilterAccommodations AS FilterAccommodations)", " TRUE") + " 
	|
	|ORDER BY
	|	HotelSortCode, " +
	?(SelShowRoomsByRoomTypes, "RoomTypeSortCode, RoomTypeDescription, ", "") + "
	|	RoomSortCode,
	|	CheckInDate,
	|	RoomQuotaCode,
	|	CustomerCode,
	|	ContractCode,
	|	GuestGroupCode,
	|	AccommodationTypeSortCode,
	|	AccommodationDate
	|
	|TOTALS
	|BY
	|	Hotel ONLY HIERARCHY, " + 
	?(SelShowRoomsByRoomTypes, "RoomType HIERARCHY", "Room ONLY HIERARCHY");
	If ValueIsFilled(SelPeriodDateFrom) Then
		vQry.SetParameter("qDate", EndOfDay(SelPeriodDateFrom));
	Else
		vQry.SetParameter("qDate", ?(BegOfDay(SelPeriodFrom) = BegOfDay(CurrentSessionDate() - 1*24*3600), EndOfDay(SelPeriodFrom) + 1*24*3600, EndOfDay(SelPeriodFrom)));
	EndIf;
	vQry.SetParameter("qShowVacantRoomsOnly", vShowVacantRoomsOnly);
	vQry.SetParameter("qHotel", SessionParameters.CurrentHotel);
	vQry.SetParameter("qRoomType", SelRoomType);
	vQry.SetParameter("qRoomClass", SelRoomClass);
	vQry.SetParameter("qRoomTypes", SelRoomTypes);
	vQry.SetParameter("qRoom", SelRoom);
	vQry.SetParameter("qRoomSection", SelRoomSection);
	vQry.SetParameter("qDocNumber", "");
	vQry.SetParameter("qCustomer", Catalogs.Customers.EmptyRef());
	vQry.SetParameter("qContract", Catalogs.Contracts.EmptyRef());
	vQry.SetParameter("qRemarks", "");
	vQry.SetParameter("qGuest", Catalogs.Clients.EmptyRef());
	vQry.SetParameter("qGuestStr", "%"+TrimR(SelGuestStr)+"%");
	vQry.SetParameter("qGuestGroup", Catalogs.GuestGroups.EmptyRef());
	vQry.SetParameter("qPeriodFrom", pPeriodFrom);
	vQry.SetParameter("qPeriodTo", pPeriodTo);
	vQry.SetParameter("qCheckInDate", SelCheckInDate);
	vQry.SetParameter("qBegOfCheckInDate", ?(ValueIsFilled(SelCheckInDate), BegOfDay(SelCheckInDate), '00010101'));
	vQry.SetParameter("qEndOfCheckInDate", ?(ValueIsFilled(SelCheckInDate), BegOfDay(SelCheckInDate) + 3600 * 24, '00010101'));
	vQry.SetParameter("qCheckOutDate", SelCheckOutDate);
	vQry.SetParameter("qBegOfCheckOutDate", ?(ValueIsFilled(SelCheckOutDate), BegOfDay(SelCheckOutDate), '00010101'));
	vQry.SetParameter("qEndOfCheckOutDate", ?(ValueIsFilled(SelCheckOutDate), BegOfDay(SelCheckOutDate) + 3600 * 24, '00010101'));
	vQry.SetParameter("qExpense", AccumulationRecordType.Expense);
	vQry.SetParameter("qAccomodationTypesRoom", Enums.AccomodationTypes.Room);
	vQry.SetParameter("qAccomodationTypesBeds", Enums.AccomodationTypes.Beds);
	vQry.SetParameter("qAccomodationTypesAdditionalBed", Enums.AccomodationTypes.AdditionalBed);
	vQry.SetParameter("qBegOfCurrentDate", BegOfDay(CurrentSessionDate()));
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qShowPreliminary", SelShowPreliminary);
	vQryRes = vQry.Execute().Unload();
	For Each vQryResRow In vQryRes Do
		If Not ValueIsFilled(vQryResRow.Hotel) And ValueIsFilled(vQryResRow.RoomType) Then
			vRoomType = vQryResRow.RoomType;
			vHotel = vRoomType.Owner;
			vQryResRow.Hotel = vHotel;
			vQryResRow.HotelSortCode = vHotel.SortCode;
		EndIf;
	EndDo;
	Return vQryRes;
EndFunction // GetRoomsGanttChartData

// -----------------------------------------------------------------------------
&AtServer
Function GetRoomBlocks(pPeriodFrom, pPeriodTo)
	// Get table of room blocks
	vQryBlocks = New Query();
	vQryBlocks.Text = 
	"SELECT
	|	RoomInventory.Room AS Room,
	|	RoomInventory.Room AS RoomInDocument,
	|	RoomInventory.Room.SortCode AS SortCode,
	|	RoomInventory.Room.Description AS RoomDescription,
	|	ISNULL(RoomInventory.Room.IsFolder, FALSE) AS RoomIsFolder,
	|	RoomInventory.Room.Parent AS RoomParent,
	|	RoomInventory.Room.Parent.Description AS RoomParentDescription,
	|	RoomInventory.Room.RoomStatus AS RoomRoomStatus,
	|	RoomInventory.Room.StopSale AS RoomStopSale,
	|	RoomInventory.RoomType AS RoomType,
	|	RoomInventory.RoomType.SortCode AS RoomTypeSortCode,
	|	RoomInventory.RoomType.Code AS RoomTypeCode,
	|	RoomInventory.RoomType.Description AS RoomTypeDescription,
	|	RoomInventory.RoomType.IsFolder AS RoomTypeIsFolder,
	|	RoomInventory.RoomType.StopSale AS RoomTypeStopSale,
	|	RoomInventory.RoomType.Parent AS RoomTypeParent,
	|	RoomInventory.RoomBlockType AS RoomBlockType,
	|	RoomInventory.RoomBlockType.Description AS RoomBlockTypeDescription,
	|	RoomInventory.Room.NumberOfBedsPerRoom AS NumberOfBeds,
	|	RoomInventory.CheckInDate AS BlockPeriodFrom,
	|	RoomInventory.CheckOutDate AS BlockPeriodTo,
	|	RoomInventory.Recorder AS SetRoomBlock,
	|	CAST(RoomInventory.Recorder.Remarks AS STRING(999)) AS Remarks
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventory
	|WHERE " +
	?(ValueIsFilled(SelHotel), ?(SelHotel.IsFolder, "Hotel IN HIERARCHY(&qHotel)", "Hotel = &qHotel"), "TRUE") + 
	?(SelRoomTypes.Count() > 0, " AND RoomType IN (&qRoomTypes)", 
	?(ValueIsFilled(SelRoomType), ?(SelRoomType.IsFolder, " AND RoomType IN HIERARCHY(&qRoomType)", " AND RoomType = &qRoomType"), "")) + 
	?(ValueIsFilled(SelRoomClass), " AND RoomType.RoomClass = &qRoomClass", "") + 
	?(ValueIsFilled(SelRoomSection), ?(SelRoomSection.IsFolder, " AND Room.RoomSection IN HIERARCHY(&qRoomSection)", " AND Room.RoomSection = &qRoomSection"), "") + 
	?(ValueIsFilled(SelRoom), ?(SelRoom.IsFolder, " AND Room IN HIERARCHY(&qRoom)", " AND Room = &qRoom"), "") + " 
	|	AND RoomInventory.RecordType = &qExpense
	|	AND RoomInventory.IsBlocking  
	|	AND RoomInventory.CheckInDate <= &qPeriodTo
	|	AND (RoomInventory.CheckOutDate > &qPeriodFrom OR RoomInventory.CheckOutDate = &qEmptyDate) " + 
	?(SelShowExpectedChangeRoomOnly, " AND FALSE", "") +  
	?(SelIntersection,
	?(ValueIsFilled(SelCheckInDate), " AND (RoomInventory.CheckOutDate > &qCheckInDate OR RoomInventory.CheckOutDate = &qEmptyDate)", "") + 
	?(ValueIsFilled(SelCheckOutDate), " AND RoomInventory.CheckInDate < &qCheckOutDate", ""),
	"") + "
	|GROUP BY
	|	RoomInventory.Room,
	|	RoomInventory.RoomType,
	|	RoomInventory.RoomBlockType,
	|	RoomInventory.CheckInDate,
	|	RoomInventory.CheckOutDate,
	|	RoomInventory.Recorder,
	|	CAST(RoomInventory.Recorder.Remarks AS STRING(999))
	|ORDER BY
	|	SortCode";
	vQryBlocks.SetParameter("qHotel", SelHotel);
	vQryBlocks.SetParameter("qRoomType", SelRoomType);
	vQryBlocks.SetParameter("qRoomTypes", SelRoomTypes);
	vQryBlocks.SetParameter("qRoom", SelRoom);
	vQryBlocks.SetParameter("qRoomSection", SelRoomSection);
	vQryBlocks.SetParameter("qRoomClass", SelRoomClass);
	vQryBlocks.SetParameter("qExpense", AccumulationRecordType.Expense);
	vQryBlocks.SetParameter("qPeriodFrom", pPeriodFrom);
	vQryBlocks.SetParameter("qPeriodTo", pPeriodTo);
	vQryBlocks.SetParameter("qCheckInDate", SelCheckInDate);
	vQryBlocks.SetParameter("qCheckOutDate", SelCheckOutDate);
	vQryBlocks.SetParameter("qEmptyDate", Date(1,1,1));
	Return vQryBlocks.Execute().Unload();
EndFunction // GetRoomBlocks

// -----------------------------------------------------------------------------
&AtServer
Function GetBookingsWithoutRooms(pPeriodFrom, pPeriodTo, pShowTodaysBookingsOnly = False)
	// Build and run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	AllReservations.Hotel AS Hotel,
	|	AllReservations.Room AS Room,
	|	AllReservations.RoomType AS RoomType,
	|	AllReservations.Recorder AS Recorder,
	|	AllReservations.Recorder.Number AS RecorderNumber,
	|	AllReservations.ParentDoc AS ParentDoc,
	|	AllReservations.Guest AS Guest,
	|	AllReservations.CheckInDate AS CheckInDate,
	|	AllReservations.CheckOutDate AS CheckOutDate,
	|	AllReservations.AccommodationType AS AccommodationType,
	|	AllReservations.RoomRate AS RoomRate,
	|	AllReservations.ClientType AS ClientType,
	|	AllReservations.ReservationStatus AS ReservationStatus,
	|	AllReservations.GuestGroup AS GuestGroup,
	|	AllReservations.HotelProduct AS HotelProduct,
	|	AllReservations.RoomQuota AS RoomQuota,
	|	AllReservations.Customer AS Customer,
	|	AllReservations.Contract AS Contract,
	|	AllReservations.ContactPerson AS ContactPerson,
	|	AllReservations.IsMaster AS IsMaster,
	|	AllReservations.IsClosedForEdit AS IsClosedForEdit,
	|	AllReservations.PlannedPaymentMethod AS PlannedPaymentMethod,
	|	AllReservations.NumberOfPersons AS NumberOfPersons,
	|	AllReservations.CheckInDate AS DocCheckInDate,
	|	AllReservations.CheckOutDate AS DocCheckOutDate,
	|	AllReservations.RoomsReserved AS RoomsReserved,
	|	AllReservations.BedsReserved AS BedsReserved,
	|	AllReservations.GuestsReserved AS GuestsReserved,
	|	AllReservations.BedsReserved AS NumberOfBeds
	|INTO DocumentPeriods
	|FROM
	|	(SELECT
	|		Reservations.Hotel AS Hotel,
	|		Reservations.Room AS Room,
	|		Reservations.RoomType AS RoomType,
	|		Reservations.Recorder AS Recorder,
	|		Reservations.ParentDoc AS ParentDoc,
	|		Reservations.Guest AS Guest,
	|		Reservations.PeriodFrom AS CheckInDate,
	|		Reservations.PeriodTo AS CheckOutDate,
	|		Reservations.AccommodationType AS AccommodationType,
	|		Reservations.RoomRate AS RoomRate,
	|		Reservations.ClientType AS ClientType,
	|		Reservations.ReservationStatus AS ReservationStatus,
	|		Reservations.GuestGroup AS GuestGroup,
	|		Reservations.HotelProduct AS HotelProduct,
	|		Reservations.RoomQuota AS RoomQuota,
	|		Reservations.Customer AS Customer,
	|		Reservations.Contract AS Contract,
	|		Reservations.ContactPerson AS ContactPerson,
	|		Reservations.IsMaster AS IsMaster,
	|		ISNULL(Reservations.Recorder.IsClosedForEdit, FALSE) AS IsClosedForEdit,
	|		Reservations.PlannedPaymentMethod AS PlannedPaymentMethod,
	|		Reservations.NumberOfPersons AS NumberOfPersons,
	|		Reservations.CheckInDate AS DocCheckInDate,
	|		Reservations.CheckOutDate AS DocCheckOutDate,
	|		MAX(Reservations.RoomsReserved) AS RoomsReserved,
	|		MAX(Reservations.BedsReserved) AS BedsReserved,
	|		MAX(Reservations.GuestsReserved) AS GuestsReserved,
	|		MAX(Reservations.BedsReserved) AS NumberOfBeds
	|	FROM
	|		AccumulationRegister.RoomInventory AS Reservations
	|	WHERE
	|		Reservations.RecordType = &qExpense
	|		AND Reservations.IsReservation
	|		AND (Reservations.PeriodFrom < &qPeriodTo
	|					AND Reservations.PeriodTo > &qPeriodFrom
	|					AND NOT &qShowTodaysBookingsOnly
	|				OR Reservations.PeriodFrom < &qPeriodTo
	|					AND Reservations.PeriodFrom >= &qPeriodFrom
	|					AND &qShowTodaysBookingsOnly)
	|		AND Reservations.Room = &qEmptyRoom " +  
	?(ValueIsFilled(SelHotel), ?(SelHotel.IsFolder, " AND Reservations.Hotel IN HIERARCHY(&qHotel)", " AND Reservations.Hotel = &qHotel"), "") + 
	?(SelRoomTypes.Count() > 0, " AND Reservations.RoomType IN (&qRoomTypes)", 
	?(ValueIsFilled(SelRoomType), ?(SelRoomType.IsFolder, " AND Reservations.RoomType IN HIERARCHY(&qRoomType)", " AND Reservations.RoomType = &qRoomType"), "")) + 
	?(Not IsBlankString(SelDocNumber), " AND Reservations.Recorder.Number = &qDocNumber", "") + 
	?(ValueIsFilled(SelRoomClass), " AND Reservations.RoomType.RoomClass = &qRoomClass", "") +
	?(ValueIsFilled(SelCustomer), ?(SelCustomer.IsFolder, " AND Reservations.Customer IN HIERARCHY(&qCustomer)", " AND Reservations.Customer = &qCustomer"), "") + 
	?(ValueIsFilled(SelContract), " AND Reservations.Contract = &qContract", "") + 
	?(ValueIsFilled(SelGuestGroup), " AND Reservations.GuestGroup = &qGuestGroup", "") + 
	?(SelShowExpectedChangeRoomOnly, " AND FALSE", "") + 
	?(SelIntersection, 
	?(ValueIsFilled(SelCheckInDate), " AND Reservations.PeriodTo > &qCheckInDate", "") + 
	?(ValueIsFilled(SelCheckOutDate), " AND Reservations.PeriodFrom < &qCheckOutDate", ""), 
	?(ValueIsFilled(SelCheckInDate), " AND Reservations.PeriodFrom >= &qBegOfCheckInDate AND Reservations.PeriodFrom < &qEndOfCheckInDate", "") + 
	?(ValueIsFilled(SelCheckOutDate), " AND Reservations.PeriodTo >= &qBegOfCheckOutDate AND Reservations.PeriodTo < &qEndOfCheckOutDate", "")) + "
	|	
	|	GROUP BY
	|		Reservations.Hotel,
	|		Reservations.Room,
	|		Reservations.RoomType,
	|		Reservations.Recorder,
	|		Reservations.ParentDoc,
	|		Reservations.Guest,
	|		Reservations.PeriodFrom,
	|		Reservations.PeriodTo,
	|		Reservations.AccommodationType,
	|		Reservations.RoomRate,
	|		Reservations.ClientType,
	|		Reservations.ReservationStatus,
	|		Reservations.GuestGroup,
	|		Reservations.HotelProduct,
	|		Reservations.RoomQuota,
	|		Reservations.Customer,
	|		Reservations.Contract,
	|		Reservations.ContactPerson,
	|		Reservations.Car,
	|		Reservations.IsMaster,
	|		ISNULL(Reservations.Recorder.IsClosedForEdit, FALSE),
	|		Reservations.PlannedPaymentMethod,
	|		Reservations.NumberOfPersons,
	|		Reservations.CheckInDate,
	|		Reservations.CheckOutDate
	|
	|UNION ALL
	|
	|	SELECT
	|		PreliminaryReservations.Hotel,
	|		PreliminaryReservations.Room,
	|		PreliminaryReservations.RoomType,
	|		PreliminaryReservations.Ref,
	|		PreliminaryReservations.ParentDoc,
	|		PreliminaryReservations.Guest AS Guest,
	|		PreliminaryReservations.CheckInDate,
	|		PreliminaryReservations.CheckOutDate,
	|		PreliminaryReservations.AccommodationType,
	|		PreliminaryReservations.RoomRate,
	|		PreliminaryReservations.ClientType,
	|		PreliminaryReservations.ReservationStatus,
	|		PreliminaryReservations.GuestGroup,
	|		PreliminaryReservations.HotelProduct,
	|		PreliminaryReservations.RoomQuota,
	|		PreliminaryReservations.Customer,
	|		PreliminaryReservations.Contract,
	|		PreliminaryReservations.ContactPerson,
	|		PreliminaryReservations.IsMaster,
	|		PreliminaryReservations.IsClosedForEdit,
	|		PreliminaryReservations.PlannedPaymentMethod,
	|		PreliminaryReservations.NumberOfPersons,
	|		PreliminaryReservations.CheckInDate,
	|		PreliminaryReservations.CheckOutDate,
	|		PreliminaryReservations.NumberOfRooms,
	|		PreliminaryReservations.NumberOfBeds,
	|		PreliminaryReservations.NumberOfPersons,
	|		PreliminaryReservations.NumberOfBeds AS NumberOfBeds
	|	FROM
	|		Document.Reservation AS PreliminaryReservations
	|	WHERE
	|		&qShowPreliminary
	|		AND PreliminaryReservations.Room = VALUE(Catalog.Rooms.EmptyRef)
	|		AND PreliminaryReservations.Posted
	|		AND PreliminaryReservations.ReservationStatus.IsPreliminary
	|		AND NOT PreliminaryReservations.ReservationStatus.IsActive
	|		AND (PreliminaryReservations.CheckInDate < &qPeriodTo
	|					AND PreliminaryReservations.CheckOutDate > &qPeriodFrom
	|					AND NOT &qShowTodaysBookingsOnly
	|				OR PreliminaryReservations.CheckInDate < &qPeriodTo
	|					AND PreliminaryReservations.CheckInDate >= &qPeriodFrom
	|					AND &qShowTodaysBookingsOnly)
	|		AND PreliminaryReservations.Room = &qEmptyRoom " +  
	?(ValueIsFilled(SelHotel), ?(SelHotel.IsFolder, " AND PreliminaryReservations.Hotel IN HIERARCHY(&qHotel)", " AND PreliminaryReservations.Hotel = &qHotel"), "") + 
	?(SelRoomTypes.Count() > 0, " AND PreliminaryReservations.RoomType IN (&qRoomTypes)", 
	?(ValueIsFilled(SelRoomType), ?(SelRoomType.IsFolder, " AND PreliminaryReservations.RoomType IN HIERARCHY(&qRoomType)", " AND PreliminaryReservations.RoomType = &qRoomType"), "")) + 
	?(Not IsBlankString(SelDocNumber), " AND PreliminaryReservations.Number = &qDocNumber", "") + 
	?(ValueIsFilled(SelRoomClass), " AND PreliminaryReservations.RoomType.RoomClass = &qRoomClass", "") +
	?(ValueIsFilled(SelCustomer), ?(SelCustomer.IsFolder, " AND PreliminaryReservations.Customer IN HIERARCHY(&qCustomer)", " AND PreliminaryReservations.Customer = &qCustomer"), "") + 
	?(ValueIsFilled(SelContract), " AND PreliminaryReservations.Contract = &qContract", "") + 
	?(ValueIsFilled(SelGuestGroup), " AND PreliminaryReservations.GuestGroup = &qGuestGroup", "") + 
	?(SelShowExpectedChangeRoomOnly, " AND FALSE", "") + 
	?(SelIntersection, 
	?(ValueIsFilled(SelCheckInDate), " AND PreliminaryReservations.CheckOutDate > &qCheckInDate", "") + 
	?(ValueIsFilled(SelCheckOutDate), " AND PreliminaryReservations.CheckInDate < &qCheckOutDate", ""), 
	?(ValueIsFilled(SelCheckInDate), " AND PreliminaryReservations.CheckInDate >= &qBegOfCheckInDate AND PreliminaryReservations.CheckInDate < &qEndOfCheckInDate", "") + 
	?(ValueIsFilled(SelCheckOutDate), " AND PreliminaryReservations.CheckOutDate >= &qBegOfCheckOutDate AND PreliminaryReservations.CheckOutDate < &qEndOfCheckOutDate", "")) + "
	|) AS AllReservations
	|;
	|
	|SELECT DISTINCT
	|	FilteredDocumentPeriods.RecorderNumber
	|INTO FilteredDocumentPeriods
	|FROM
	|	DocumentPeriods AS FilteredDocumentPeriods
	|WHERE TRUE " + 
	?(IsBlankString(SelRemarks), " AND TRUE", " AND (FilteredDocumentPeriods.Recorder.Remarks LIKE &qRemarks OR FilteredDocumentPeriods.Recorder.Car LIKE &qRemarks)") +  
	?(ValueIsFilled(SelGuest), " AND FilteredDocumentPeriods.Guest = &qGuest", 
	?(IsBlankString(SelGuestStr), " AND TRUE", " AND (FilteredDocumentPeriods.Guest.FullName LIKE &qGuestStr OR 
	|                                                 FilteredDocumentPeriods.Customer.Description LIKE &qGuestStr OR
	|                                                 FilteredDocumentPeriods.Recorder.Remarks LIKE &qGuestStr OR 
	|                                                 FilteredDocumentPeriods.Recorder.Car LIKE &qGuestStr)")) + " 
	|;
	|
	|SELECT
	|	DocumentPeriods.Hotel AS Hotel,
	|	DocumentPeriods.Hotel.SortCode AS HotelSortCode,
	|	DocumentPeriods.Room AS Room,
	|	DocumentPeriods.Room.SortCode AS RoomSortCode,
	|	DocumentPeriods.Recorder.Room AS RoomInDocument,
	|	ISNULL(DocumentPeriods.Room.Description, """") AS RoomDescription,
	|	ISNULL(DocumentPeriods.Room.IsFolder, FALSE) AS RoomIsFolder,
	|	DocumentPeriods.Room.Parent AS RoomParent,
	|	DocumentPeriods.Room.Parent.Description AS RoomParentDescription,
	|	DocumentPeriods.Room.RoomStatus AS RoomRoomStatus,
	|	DocumentPeriods.Room.RoomStatus.Description AS RoomRoomStatusDescription,
	|	ISNULL(DocumentPeriods.Room.RoomStatus.Color, UNDEFINED) AS RoomRoomStatusColor,
	|	DocumentPeriods.Room.RoomStatus.RoomStatusIcon AS RoomRoomStatusIcon,
	|	ISNULL(DocumentPeriods.Room.StopSale, FALSE) AS RoomStopSale,
	|	ISNULL(DocumentPeriods.Room.RoomPropertiesCodes, """") AS RoomRoomPropertiesCodes,
	|	DocumentPeriods.RoomType AS RoomType,
	|	DocumentPeriods.RoomType.SortCode AS RoomTypeSortCode,
	|	DocumentPeriods.RoomType.Code AS RoomTypeCode,
	|	DocumentPeriods.RoomType.Description AS RoomTypeDescription,
	|	ISNULL(DocumentPeriods.RoomType.IsFolder, FALSE) AS RoomTypeIsFolder,
	|	ISNULL(DocumentPeriods.RoomType.StopSale, FALSE) AS RoomTypeStopSale,
	|	DocumentPeriods.RoomType.Parent AS RoomTypeParent,
	|	DocumentPeriods.Recorder AS Accommodation,
	|	ISNULL(DocumentPeriods.Recorder.NumberOfBedsPerRoom, 0) AS AccommodationNumberOfBedsPerRoom,
	|	DocumentPeriods.RecorderNumber AS AccommodationNumber,
	|	DocumentPeriods.Recorder.Date AS AccommodationDate,
	|	DocumentPeriods.ParentDoc AS ParentDoc,
	|	DocumentPeriods.ParentDoc.Room AS ParentDocRoom,
	|	ISNULL(DocumentPeriods.ParentDoc.ReservationStatus.IsCheckIn, FALSE) AS ParentDocReservationStatusIsCheckIn,
	|	DocumentPeriods.Guest AS Guest,
	|	DocumentPeriods.Guest.Description AS GuestDescription,
	|	DocumentPeriods.Guest.FullName AS GuestFullName,
	|	DocumentPeriods.Guest.Citizenship AS GuestCitizenship,
	|	DocumentPeriods.Guest.Citizenship.ISOCode AS GuestCitizenshipISOCode,
	|	DocumentPeriods.Guest.Sex AS GuestSex,
	|	DocumentPeriods.Guest.DateOfBirth AS GuestDateOfBirth,
	|	DocumentPeriods.CheckInDate AS CheckInDate,
	|	DocumentPeriods.CheckOutDate AS CheckOutDate,
	|	DocumentPeriods.AccommodationType AS AccommodationType,
	|	DocumentPeriods.AccommodationType.Type AS AccommodationTypeType,
	|	DocumentPeriods.RoomRate AS RoomRate,
	|	DocumentPeriods.RoomRate.Description AS RoomRateDescription,
	|	DocumentPeriods.ClientType AS ClientType,
	|	DocumentPeriods.ClientType.Description AS ClientTypeDescription,
	|	DocumentPeriods.ClientType.Code AS ClientTypeCode,
	|	DocumentPeriods.ClientType.Color AS ClientTypeColor,
	|	DocumentPeriods.Recorder.AccommodationTemplate AS AccommodationTemplate,
	|	DocumentPeriods.Recorder.AccommodationTemplate.Description AS AccommodationTemplateDescription,
	|	DocumentPeriods.ReservationStatus AS Status,
	|	DocumentPeriods.ReservationStatus.Description AS StatusDescription,
	|	DocumentPeriods.ReservationStatus.Color AS StatusColor,
	|	FALSE AS StatusIsInHouse,
	|	DocumentPeriods.ReservationStatus.IsGuaranteed AS StatusIsGuaranteed,
	|	DocumentPeriods.GuestGroup AS GuestGroup,
	|	DocumentPeriods.GuestGroup.Code AS GuestGroupCode,
	|	DocumentPeriods.GuestGroup.Description AS GuestGroupDescription,
	|	DocumentPeriods.GuestGroup.Color AS GuestGroupColor,
	|	DocumentPeriods.HotelProduct AS HotelProduct,
	|	DocumentPeriods.HotelProduct.Description AS HotelProductDescription,
	|	DocumentPeriods.HotelProduct.Parent AS HotelProductParent,
	|	DocumentPeriods.HotelProduct.Parent.Description AS HotelProductParentDescription,
	|	DocumentPeriods.RoomQuota AS RoomQuota,
	|	DocumentPeriods.RoomQuota.Code AS RoomQuotaCode,
	|	DocumentPeriods.RoomQuota.Description AS RoomQuotaDescription,
	|	DocumentPeriods.RoomQuota.Color AS RoomQuotaColor,
	|	DocumentPeriods.Customer AS Customer,
	|	DocumentPeriods.Customer.Code AS CustomerCode,
	|	DocumentPeriods.Customer.Description AS CustomerDescription,
	|	DocumentPeriods.Customer.Color AS CustomerColor,
	|	ISNULL(DocumentPeriods.Customer.IsIndividual, TRUE) AS CustomerIsIndividual,
	|	DocumentPeriods.Contract AS Contract,
	|	DocumentPeriods.Contract.Code AS ContractCode,
	|	DocumentPeriods.Contract.Description AS ContractDescription,
	|	DocumentPeriods.Contract.Color AS ContractColor,
	|	DocumentPeriods.ContactPerson AS ContactPerson,
	|	DocumentPeriods.Recorder.Agent AS Agent,
	|	DocumentPeriods.Recorder.Remarks AS Remarks,
	|	DocumentPeriods.Recorder.Car AS Car,
	|	DocumentPeriods.IsMaster AS IsMaster,
	|	DocumentPeriods.IsClosedForEdit AS IsClosedForEdit,
	|	DocumentPeriods.PlannedPaymentMethod AS PlannedPaymentMethod,
	|	DocumentPeriods.PlannedPaymentMethod.Code AS PlannedPaymentMethodCode,
	|	DocumentPeriods.PlannedPaymentMethod.Description AS PlannedPaymentMethodDescription,
	|	DocumentPeriods.PlannedPaymentMethod.IsByBankTransfer AS IsByBankTransfer,
	|	DocumentPeriods.NumberOfPersons AS NumberOfPersons,
	|	DocumentPeriods.Recorder.ServicePackage AS ServicePackage,
	|	DocumentPeriods.Recorder.ServicePackage.Description AS ServicePackageDescription,
	|	CAST(DocumentPeriods.Recorder.PricePresentation AS STRING(17)) AS PricePresentation,
	|	DATEDIFF(DocumentPeriods.DocCheckInDate, DocumentPeriods.DocCheckOutDate, SECOND) AS DurationInSeconds,
	|	CASE
	|		WHEN DocumentPeriods.AccommodationType.Type = &qAccomodationTypesRoom
	|			THEN 0
	|		WHEN DocumentPeriods.AccommodationType.Type = &qAccomodationTypesBeds
	|			THEN 0
	|		WHEN DocumentPeriods.AccommodationType.Type = &qAccomodationTypesAdditionalBed
	|			THEN 1
	|		ELSE 2
	|	END AS AccommodationTypeSortCode,
	|	DocumentPeriods.BedsReserved AS NumberOfBeds,
	|	DocumentPeriods.RoomsReserved AS RoomsReserved,
	|	DocumentPeriods.BedsReserved AS BedsReserved,
	|	DocumentPeriods.GuestsReserved AS GuestsReserved,
	|	ISNULL(DocumentPeriods.Recorder.RoomQuantity, 1) AS RoomQuantity,
	|	0 AS OverbookingIndex
	|FROM
	|	DocumentPeriods AS DocumentPeriods
	|WHERE " +
	?(Not IsBlankString(SelRemarks) OR ValueIsFilled(SelGuest) OR NOT IsBlankString(SelGuestStr), " DocumentPeriods.RecorderNumber IN (SELECT FilteredDocumentPeriods.RecorderNumber FROM FilteredDocumentPeriods AS FilteredDocumentPeriods)", " TRUE") + " 
	|
	|ORDER BY
	|	HotelSortCode,
	|	RoomTypeSortCode,
	|	RoomTypeDescription,
	|	CheckInDate,
	|	DurationInSeconds DESC,
	|	RoomQuotaCode,
	|	CustomerCode,
	|	ContractCode,
	|	GuestGroupCode,
	|	AccommodationTypeSortCode,
	|	AccommodationDate";
	vQry.SetParameter("qHotel", SelHotel);
	vQry.SetParameter("qRoomType", SelRoomType);
	vQry.SetParameter("qRoomClass", SelRoomClass);
	vQry.SetParameter("qRoomTypes", SelRoomTypes);
	vQry.SetParameter("qEmptyRoom", Catalogs.Rooms.EmptyRef());
	vQry.SetParameter("qDocNumber", TrimAll(SelDocNumber));
	vQry.SetParameter("qCustomer", SelCustomer);
	vQry.SetParameter("qContract", SelContract);
	vQry.SetParameter("qRemarks", "%"+TrimR(SelRemarks)+"%");
	vQry.SetParameter("qGuest", SelGuest);
	vQry.SetParameter("qGuestStr", "%"+TrimR(SelGuestStr)+"%");
	vQry.SetParameter("qGuestGroup", SelGuestGroup);
	If pShowTodaysBookingsOnly Then
		vQry.SetParameter("qPeriodFrom", BegOfDay(CurrentSessionDate()));
		vQry.SetParameter("qPeriodTo", EndOfDay(CurrentSessionDate()));
	Else
		vQry.SetParameter("qPeriodFrom", pPeriodFrom);
		vQry.SetParameter("qPeriodTo", pPeriodTo);
	EndIf;
	vQry.SetParameter("qShowTodaysBookingsOnly", pShowTodaysBookingsOnly);
	vQry.SetParameter("qCheckInDate", SelCheckInDate);
	vQry.SetParameter("qBegOfCheckInDate", ?(ValueIsFilled(SelCheckInDate), BegOfDay(SelCheckInDate), '00010101'));
	vQry.SetParameter("qEndOfCheckInDate", ?(ValueIsFilled(SelCheckInDate), BegOfDay(SelCheckInDate) + 3600 * 24, '00010101'));
	vQry.SetParameter("qCheckOutDate", SelCheckOutDate);
	vQry.SetParameter("qBegOfCheckOutDate", ?(ValueIsFilled(SelCheckOutDate), BegOfDay(SelCheckOutDate), '00010101'));
	vQry.SetParameter("qEndOfCheckOutDate", ?(ValueIsFilled(SelCheckOutDate), BegOfDay(SelCheckOutDate) + 3600 * 24, '00010101'));
	vQry.SetParameter("qExpense", AccumulationRecordType.Expense);
	vQry.SetParameter("qAccomodationTypesRoom", Enums.AccomodationTypes.Room);
	vQry.SetParameter("qAccomodationTypesBeds", Enums.AccomodationTypes.Beds);
	vQry.SetParameter("qAccomodationTypesAdditionalBed", Enums.AccomodationTypes.AdditionalBed);
	vQry.SetParameter("qShowPreliminary", SelShowPreliminary);
	vQryRes = vQry.Execute().Unload();
	Return vQryRes;
EndFunction // GetBookingsWithoutRooms

// -----------------------------------------------------------------------------
&AtServer
Procedure MapBookingsToTheVacantPeriods(pAllRooms, pVacantPeriods, pBookings)
	vOverbookingIndex = 1;
	vMaxGap = '39991231235959' - '00010101';
	// Processing bookings
	For Each vBookingRow In pBookings Do
		// Trying to find appropriate vacant period
		While vBookingRow.BedsReserved > 0 Do
			vMinGap = vMaxGap;
			vVacantPeriodRow = Undefined;
			For Each vVacantRow In pVacantPeriods Do
				If vVacantRow.BedsVacant > 0 And 
					vVacantRow.RoomType = vBookingRow.RoomType And
					vVacantRow.VacantFromDate <= vBookingRow.CheckInDate And 
					vVacantRow.VacantToDate >= vBookingRow.CheckOutDate Then
					// Check reservation accommodation type
					If vVacantRow.RoomsVacant = 0 And 
						ValueIsFilled(vBookingRow.AccommodationType) And 
						vBookingRow.AccommodationType.Type = Enums.AccomodationTypes.Room Then
						// Skip this partially vacant room
						Continue;
					EndIf;
					vCheckGap = vBookingRow.CheckInDate - vVacantRow.VacantFromDate;
					If vMinGap > vCheckGap Then
						vMinGap = vCheckGap;
						vVacantPeriodRow = vVacantRow;
					EndIf;
				EndIf;
			EndDo;
			If vVacantPeriodRow <> Undefined Then
				// Calculate resources to be used
				vRoomsReserved = vBookingRow.RoomsReserved;
				vBedsReserved = vBookingRow.BedsReserved;
				If vBedsReserved > vVacantPeriodRow.BedsVacant Then
					vRoomsReserved = vVacantPeriodRow.RoomsVacant;
					vBedsReserved = vVacantPeriodRow.BedsVacant;
				EndIf;
				// Add row to the all rooms
				vRoomRow = pAllRooms.Add();
				FillPropertyValues(vRoomRow, vBookingRow);
				FillPropertyValues(vRoomRow, vVacantPeriodRow);
				// Correct reserved beds and rooms period
				vBookingRow.RoomsReserved = vBookingRow.RoomsReserved - vRoomsReserved;
				vBookingRow.BedsReserved = vBookingRow.BedsReserved - vBedsReserved;
				// Correct vacant beds and rooms period
				If vVacantPeriodRow.VacantFromDate < vBookingRow.CheckInDate Then
					vLeftVacantPeriodRow = pVacantPeriods.Insert(pVacantPeriods.IndexOf(vVacantPeriodRow));
					FillPropertyValues(vLeftVacantPeriodRow, vVacantPeriodRow);
					vLeftVacantPeriodRow.VacantToDate = vBookingRow.CheckInDate;
					vVacantPeriodRow.VacantFromDate = vBookingRow.CheckInDate;
				EndIf;
				If vVacantPeriodRow.VacantToDate > vBookingRow.CheckOutDate Then
					vRightVacantPeriodRow = pVacantPeriods.Insert(pVacantPeriods.IndexOf(vVacantPeriodRow) + 1);
					FillPropertyValues(vRightVacantPeriodRow, vVacantPeriodRow);
					vRightVacantPeriodRow.VacantFromDate = vBookingRow.CheckOutDate;
					vVacantPeriodRow.VacantToDate = vBookingRow.CheckOutDate;
				EndIf;
				vVacantPeriodRow.RoomsVacant = vVacantPeriodRow.RoomsVacant - vRoomsReserved;
				vVacantPeriodRow.BedsVacant = vVacantPeriodRow.BedsVacant - vBedsReserved;
			Else
				Break;
			EndIf;
		EndDo;
		// Add overbooking rows if necessary
		If vBookingRow.BedsReserved > 0 Then
			vNumberOfBedsPerRoomType = vBookingRow.AccommodationNumberOfBedsPerRoom;
			While vBookingRow.BedsReserved > 0 Do
				vRoomsReserved = 1;
				vBedsReserved = vBookingRow.BedsReserved;
				If vBedsReserved > vNumberOfBedsPerRoomType Then
					vBedsReserved = vNumberOfBedsPerRoomType;
				ElsIf vBedsReserved < vNumberOfBedsPerRoomType Then
					vRoomsReserved = 0;
				EndIf;
				// Try to decide if we have to increase overbooking index
				vVirtRoomRows = pAllRooms.FindRows(New Structure("Hotel, RoomType, Room, OverbookingIndex", vBookingRow.Hotel, vBookingRow.RoomType, Catalogs.Rooms.EmptyRef(), vOverbookingIndex));
				For Each vVirtRoomRow In vVirtRoomRows Do
					If vVirtRoomRow.CheckInDate < vBookingRow.CheckOutDate And 
					   vVirtRoomRow.CheckOutDate > vBookingRow.CheckInDate Then
						vOverbookingIndex = vOverbookingIndex + 1;
						OverbookingIndexesRoomTypes.Add(vBookingRow.RoomType, Format(vOverbookingIndex, "NFD=0; NG="));
						Break;
					EndIf;
				EndDo;
				// Add row to the all rooms
				vRoomRow = pAllRooms.Add();
				FillPropertyValues(vRoomRow, vBookingRow);
				vRoomRow.RoomSortCode = 99999999;
				// Fill room overbooking index
				vRoomRow.OverbookingIndex = vOverbookingIndex;
				vRoomRow.RoomDescription = "#" + Format(vOverbookingIndex, "NFD=0; NG=") + " " + TrimAll(vBookingRow.RoomTypeCode);
				// Correct reserved beds and rooms
				vBookingRow.RoomsReserved = vBookingRow.RoomsReserved - vRoomsReserved;
				vBookingRow.BedsReserved = vBookingRow.BedsReserved - vBedsReserved;
			EndDo;
		EndIf;
	EndDo;
	If SelShowRoomsByRoomTypes Then
		pAllRooms.Sort("RoomTypeSortCode, RoomTypeDescription, RoomSortCode, OverbookingIndex, CheckInDate, RoomQuotaCode, CustomerCode, ContractCode, GuestGroupCode, AccommodationTypeSortCode, AccommodationDate");
	Else
		pAllRooms.Sort("RoomSortCode, RoomTypeSortCode, RoomTypeDescription, OverbookingIndex, CheckInDate, RoomQuotaCode, CustomerCode, ContractCode, GuestGroupCode, AccommodationTypeSortCode, AccommodationDate");
	EndIf;
	// Filter bookings by room selected
	If ValueIsFilled(SelRoom) Then
		i = 0;
		While i < pAllRooms.Count() Do
			vRow = pAllRooms.Get(i);
			If ValueIsFilled(vRow.Room) Then
				If SelRoom.IsFolder Then
					If Not vRow.Room.BelongsToItem(SelRoom) And SelRoom <> vRow.Room Then
						pAllRooms.Delete(i);
						Continue;
					EndIf;
				Else
					If vRow.Room <> SelRoom Then
						pAllRooms.Delete(i);
						Continue;
					EndIf;
				EndIf;
			Else
				pAllRooms.Delete(i);
				Continue;
			EndIf;
			i = i + 1;
		EndDo;
	EndIf;
EndProcedure // MapBookingsToTheVacantPeriods

// -----------------------------------------------------------------------------
&AtServer
Procedure MapBookingsToTheOverbookingRooms(pAllRooms, pBookings)
	vOverbookingIndex = 0;
	If ValueIsFilled(SelRoom) Then
		Return;
	EndIf;
	// Processing bookings
	For Each vBookingRow In pBookings Do
		If vBookingRow.BedsReserved = 0 Then
			Continue;
		EndIf;
		// Try to find virtual room row for the current room type
		vVirtRoomRows = pAllRooms.FindRows(New Structure("Hotel, RoomType, Room", vBookingRow.Hotel, vBookingRow.RoomType, Catalogs.Rooms.EmptyRef()));
		If vVirtRoomRows.Count() = 0 Then
			vVirtRoomRow = pAllRooms.Add();
			vOverbookingIndex = vOverbookingIndex + 1;
			InitializeVirtRoomRow(vVirtRoomRow, vBookingRow, vOverbookingIndex);
			vVirtRoomRows.Add(vVirtRoomRow);
			OverbookingIndexesRoomTypes.Add(vBookingRow.RoomType, Format(vOverbookingIndex, "NFD=0; NG="));
		EndIf;
		// Try to map reservation to some virtual room indexed by overbooking index
		vOverbookingIndexesToBeMapped = New ValueList();
		vOverbookingIndexesNotToBeMapped = New ValueList();
		For Each vVirtRoomRow In vVirtRoomRows Do
			// Check reservation period
			If vVirtRoomRow.CheckInDate < vBookingRow.CheckOutDate And 
			   vVirtRoomRow.CheckOutDate > vBookingRow.CheckInDate Then
				If vOverbookingIndexesNotToBeMapped.FindByValue(vVirtRoomRow.OverbookingIndex) = Undefined Then
					vOverbookingIndexesNotToBeMapped.Add(vVirtRoomRow.OverbookingIndex);
				EndIf;
			Else
				vGap = Format(vBookingRow.CheckInDate - vVirtRoomRow.CheckOutDate, "ND=12; NFD=0; NZ=; NLZ=; NG=");
				vOverbookingIndexesToBeMappedItem = vOverbookingIndexesToBeMapped.FindByValue(vVirtRoomRow.OverbookingIndex);
				If vOverbookingIndexesToBeMappedItem = Undefined Then
					vOverbookingIndexesToBeMapped.Add(vVirtRoomRow.OverbookingIndex, vGap);
				Else
					If vOverbookingIndexesToBeMappedItem.Presentation > vGap Then
						vOverbookingIndexesToBeMappedItem.Presentation = vGap;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
		For Each vOverbookingIndexesNotToBeMappedItem In vOverbookingIndexesNotToBeMapped Do
			vIndexItemToDelete = vOverbookingIndexesToBeMapped.FindByValue(vOverbookingIndexesNotToBeMappedItem.Value);
			If vIndexItemToDelete <> Undefined Then
				vOverbookingIndexesToBeMapped.Delete(vIndexItemToDelete);
			EndIf;
		EndDo;
		// Try to select virtual room with minimum gap between previous check-out and current check-in
		vOverbookingIndexToBeMapped = 0;
		vCouldBeMapped = False;
		If vOverbookingIndexesToBeMapped.Count() > 0 Then
			vCouldBeMapped = True;
			// Calculate minimum gap between check-ins
			vMinGap = "999999999999";
			For Each vOverbookingIndexesToBeMappedItem In vOverbookingIndexesToBeMapped Do
				If vOverbookingIndexesToBeMappedItem.Presentation < vMinGap Then
					vOverbookingIndexToBeMapped = vOverbookingIndexesToBeMappedItem.Value;
					vMinGap = vOverbookingIndexesToBeMappedItem.Presentation;
				EndIf;
			EndDo;
		EndIf;
		// Add reservation mapping to the virtual room
		vVirtRoomRow = pAllRooms.Add();
		If vCouldBeMapped And vOverbookingIndexToBeMapped <> 0 Then
			InitializeVirtRoomRow(vVirtRoomRow, vBookingRow, vOverbookingIndexToBeMapped);
		Else
			vOverbookingIndex = vOverbookingIndex + 1;
			InitializeVirtRoomRow(vVirtRoomRow, vBookingRow, vOverbookingIndex);
			OverbookingIndexesRoomTypes.Add(vBookingRow.RoomType, Format(vOverbookingIndex, "NFD=0; NG="));
		EndIf;
		vVirtRoomRows.Add(vVirtRoomRow);
		// Fill reservation parameters
		FillPropertyValues(vVirtRoomRow, vBookingRow, , "RoomSortCode, RoomDescription, OverbookingIndex");
	EndDo;
	If SelShowRoomsByRoomTypes Then
		pAllRooms.Sort("RoomTypeSortCode, RoomTypeDescription, RoomSortCode, OverbookingIndex, CheckInDate, RoomQuotaCode, CustomerCode, ContractCode, GuestGroupCode, AccommodationTypeSortCode, AccommodationDate");
	Else
		pAllRooms.Sort("RoomSortCode, RoomTypeSortCode, RoomTypeDescription, OverbookingIndex, CheckInDate, RoomQuotaCode, CustomerCode, ContractCode, GuestGroupCode, AccommodationTypeSortCode, AccommodationDate");
	EndIf;
EndProcedure // MapBookingsToTheOverbookingRooms

// -----------------------------------------------------------------------------
&AtServer
Procedure InitializeVirtRoomRow(pVirtRoomRow, pBookingRow, pOverbookingIndex) 
	pVirtRoomRow.Hotel = pBookingRow.Hotel;
	pVirtRoomRow.HotelSortCode = pBookingRow.HotelSortCode;
	pVirtRoomRow.Room = Undefined;
	pVirtRoomRow.RoomSortCode = 99999999;
	pVirtRoomRow.RoomInDocument = Undefined;
	pVirtRoomRow.RoomDescription = "#" + Format(pOverbookingIndex, "NFD=0; NG=") + " " + TrimAll(pBookingRow.RoomTypeCode);
	pVirtRoomRow.RoomIsFolder = False;
	pVirtRoomRow.RoomParent = Undefined;
	pVirtRoomRow.RoomParentDescription = "";
	pVirtRoomRow.RoomRoomStatus = Undefined;
	pVirtRoomRow.RoomRoomStatusDescription = "";
	pVirtRoomRow.RoomRoomStatusColor = Undefined;
	pVirtRoomRow.RoomRoomStatusIcon = Undefined;
	pVirtRoomRow.RoomStopSale = False;
	pVirtRoomRow.RoomRoomPropertiesCodes = "";
	pVirtRoomRow.RoomType = pBookingRow.RoomType;
	pVirtRoomRow.RoomTypeSortCode = pBookingRow.RoomTypeSortCode;
	pVirtRoomRow.RoomTypeCode = pBookingRow.RoomTypeCode;
	pVirtRoomRow.RoomTypeDescription = TrimAll(pBookingRow.RoomTypeDescription);
	pVirtRoomRow.RoomTypeIsFolder = False;
	pVirtRoomRow.RoomTypeStopSale = False;
	pVirtRoomRow.RoomTypeParent = pBookingRow.RoomTypeParent;
	pVirtRoomRow.Accommodation = Undefined;
	pVirtRoomRow.AccommodationNumber = "";
	pVirtRoomRow.AccommodationDate = '00010101';
	pVirtRoomRow.ParentDoc = Undefined;
	pVirtRoomRow.ParentDocRoom = Undefined;
	pVirtRoomRow.ParentDocReservationStatusIsCheckIn = False;
	pVirtRoomRow.Guest = Undefined;
	pVirtRoomRow.GuestDescription = "";
	pVirtRoomRow.GuestFullName = "";
	pVirtRoomRow.GuestCitizenship = Undefined;
	pVirtRoomRow.GuestCitizenshipISOCode = "";
	pVirtRoomRow.GuestSex = Undefined;
	pVirtRoomRow.GuestDateOfBirth = '00010101';
	pVirtRoomRow.CheckInDate = '00010101';
	pVirtRoomRow.CheckOutDate = '00010101';
	pVirtRoomRow.AccommodationType = Undefined;
	pVirtRoomRow.AccommodationTypeType = Undefined;
	pVirtRoomRow.RoomRate = Undefined;
	pVirtRoomRow.RoomRateDescription = "";
	pVirtRoomRow.ClientType = Undefined;
	pVirtRoomRow.ClientTypeDescription = "";
	pVirtRoomRow.ClientTypeColor = Undefined;
	pVirtRoomRow.AccommodationTemplate = Undefined;
	pVirtRoomRow.AccommodationTemplateDescription = "";
	pVirtRoomRow.Status = Undefined;
	pVirtRoomRow.StatusDescription = "";
	pVirtRoomRow.StatusColor = Undefined;
	pVirtRoomRow.StatusIsInHouse = False;
	pVirtRoomRow.StatusIsGuaranteed = False;
	pVirtRoomRow.GuestGroup = Undefined;
	pVirtRoomRow.GuestGroupCode = 0;
	pVirtRoomRow.GuestGroupDescription = "";
	pVirtRoomRow.GuestGroupColor = Undefined;
	pVirtRoomRow.HotelProduct = Undefined;
	pVirtRoomRow.HotelProductDescription = "";
	pVirtRoomRow.HotelProductParent = Undefined;
	pVirtRoomRow.HotelProductParentDescription = "";
	pVirtRoomRow.RoomQuota = Undefined;
	pVirtRoomRow.RoomQuotaCode = "";
	pVirtRoomRow.RoomQuotaDescription = "";
	pVirtRoomRow.RoomQuotaColor = Undefined;
	pVirtRoomRow.Customer = Undefined;
	pVirtRoomRow.CustomerCode = "";
	pVirtRoomRow.CustomerDescription = "";
	pVirtRoomRow.CustomerColor = Undefined;
	pVirtRoomRow.CustomerIsIndividual = False;
	pVirtRoomRow.Contract = Undefined;
	pVirtRoomRow.ContractCode = "";
	pVirtRoomRow.ContractDescription = "";
	pVirtRoomRow.ContractColor = Undefined;
	pVirtRoomRow.ContactPerson = "";
	pVirtRoomRow.Agent = Undefined;
	pVirtRoomRow.Remarks = "";
	pVirtRoomRow.Car = "";
	pVirtRoomRow.IsMaster = False;
	pVirtRoomRow.IsClosedForEdit = False;
	pVirtRoomRow.PlannedPaymentMethod = Undefined;
	pVirtRoomRow.PlannedPaymentMethodCode = "";
	pVirtRoomRow.PlannedPaymentMethodDescription = "";
	pVirtRoomRow.IsByBankTransfer = False;
	pVirtRoomRow.NumberOfPersons = 0;
	pVirtRoomRow.ServicePackage = Undefined;
	pVirtRoomRow.ServicePackageDescription = "";
	pVirtRoomRow.PricePresentation = "";
	pVirtRoomRow.DurationInSeconds = 0;
	pVirtRoomRow.OverbookingIndex = pOverbookingIndex;
	pVirtRoomRow.AccommodationTypeSortCode = 0;
	pVirtRoomRow.NumberOfBeds = 0;
	pVirtRoomRow.RoomsVacantBalance = 1;
EndProcedure // InitializeVirtRoomRow

// -----------------------------------------------------------------------------
&AtServer
Function GetRoomsVacantPeriods(pAllRooms, pBookings, pPeriodFrom, pPeriodTo)
	// Get minimum check-in and maximum check-out dates
	vPeriodFrom = pPeriodFrom;
	vPeriodTo = pPeriodTo;
	For Each vRoomRow In pAllRooms Do
		If ValueIsFilled(vRoomRow.Accommodation) And 
			ValueIsFilled(vRoomRow.CheckInDate) And
			ValueIsFilled(vRoomRow.CheckOutDate) Then
			If vPeriodFrom > vRoomRow.CheckInDate Then
				vPeriodFrom = vRoomRow.CheckInDate;
			EndIf;
			If vPeriodTo < vRoomRow.CheckOutDate Then
				vPeriodTo = vRoomRow.CheckOutDate;
			EndIf;
		EndIf;
	EndDo;
	For Each vBookingRow In pBookings Do
		If ValueIsFilled(vBookingRow.Accommodation) And 
			ValueIsFilled(vBookingRow.CheckInDate) And
			ValueIsFilled(vBookingRow.CheckOutDate) Then
			If vPeriodFrom > vBookingRow.CheckInDate Then
				vPeriodFrom = vBookingRow.CheckInDate;
			EndIf;
			If vPeriodTo < vBookingRow.CheckOutDate Then
				vPeriodTo = vBookingRow.CheckOutDate;
			EndIf;
		EndIf;
	EndDo;
	// Build and run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInventoryBalanceAndTurnovers.Hotel,
	|	RoomInventoryBalanceAndTurnovers.Hotel.SortCode AS HotelSortCode,
	|	RoomInventoryBalanceAndTurnovers.Room,
	|	RoomInventoryBalanceAndTurnovers.Room.SortCode AS RoomSortCode,
	|	RoomInventoryBalanceAndTurnovers.Room.Description AS RoomDescription,
	|	ISNULL(RoomInventoryBalanceAndTurnovers.Room.IsFolder, FALSE) AS RoomIsFolder,
	|	ISNULL(RoomInventoryBalanceAndTurnovers.Room.RoomPropertiesCodes, """") AS RoomRoomPropertiesCodes,
	|	RoomInventoryBalanceAndTurnovers.Room.Parent AS RoomParent,
	|	RoomInventoryBalanceAndTurnovers.Room.Parent.Description AS RoomParentDescription,
	|	RoomInventoryBalanceAndTurnovers.Room.RoomStatus AS RoomRoomStatus,
	|	RoomInventoryBalanceAndTurnovers.Room.StopSale AS RoomStopSale,
	|	RoomInventoryBalanceAndTurnovers.RoomType AS RoomType,
	|	RoomInventoryBalanceAndTurnovers.RoomType.SortCode AS RoomTypeSortCode,
	|	RoomInventoryBalanceAndTurnovers.RoomType.Code AS RoomTypeCode,
	|	RoomInventoryBalanceAndTurnovers.RoomType.Description AS RoomTypeDescription,
	|	RoomInventoryBalanceAndTurnovers.RoomType.IsFolder AS RoomTypeIsFolder,
	|	RoomInventoryBalanceAndTurnovers.RoomType.StopSale AS RoomTypeStopSale,
	|	RoomInventoryBalanceAndTurnovers.RoomType.Parent AS RoomTypeParent,
	|	RoomInventoryBalanceAndTurnovers.CounterClosingBalance AS CounterClosingBalance,
	|	RoomInventoryBalanceAndTurnovers.RoomsVacantClosingBalance AS RoomsVacant,
	|	RoomInventoryBalanceAndTurnovers.BedsVacantClosingBalance AS BedsVacant,
	|	RoomInventoryBalanceAndTurnovers.TotalRoomsClosingBalance AS TotalRooms,
	|	RoomInventoryBalanceAndTurnovers.Period AS Period,
	|	RoomInventoryBalanceAndTurnovers.Period AS VacantFromDate,
	|	RoomInventoryBalanceAndTurnovers.Period AS VacantToDate
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qPeriodFrom, &qPeriodTo, 
	|															Second, 
	|															RegisterRecordsAndPeriodBoundaries, 
	|															TRUE " + 
	?(ValueIsFilled(SelHotel), ?(SelHotel.IsFolder, " AND Hotel IN HIERARCHY(&qHotel)", " AND Hotel = &qHotel"), "") + 
	?(SelRoomTypes.Count() > 0, " AND RoomType IN (&qRoomTypes)", "") + 
	?(ValueIsFilled(SelRoomType), ?(SelRoomType.IsFolder, " AND RoomType IN HIERARCHY(&qRoomType)", " AND RoomType = &qRoomType"), "") + 
	?(ValueIsFilled(SelRoomSection), ?(SelRoomSection.IsFolder, " AND Room.RoomSection IN HIERARCHY(&qRoomSection)", " AND Room.RoomSection = &qRoomSection"), "") + 
	?(ValueIsFilled(SelRoomClass), " AND RoomType.RoomClass = &qRoomClass", "") + 
	?(ValueIsFilled(SelRoom), ?(SelRoom.IsFolder, " AND Room IN HIERARCHY(&qRoom)", " AND Room = &qRoom"), "") + " 
	|) AS RoomInventoryBalanceAndTurnovers
	|WHERE
	|	RoomInventoryBalanceAndTurnovers.Room <> &qEmptyRoom
	|	AND RoomInventoryBalanceAndTurnovers.TotalRoomsClosingBalance > 0
	|
	|ORDER BY
	|	HotelSortCode,
	|	RoomSortCode,
	|	VacantFromDate";
	vQry.SetParameter("qHotel", SelHotel);
	vQry.SetParameter("qRoomType", SelRoomType);
	vQry.SetParameter("qRoomClass", SelRoomClass);
	vQry.SetParameter("qRoomTypes", SelRoomTypes);
	vQry.SetParameter("qRoom", SelRoom);
	vQry.SetParameter("qRoomSection", SelRoomSection);
	vQry.SetParameter("qEmptyRoom", Catalogs.Rooms.EmptyRef());
	vQry.SetParameter("qPeriodFrom", vPeriodFrom);
	vQry.SetParameter("qPeriodTo", vPeriodTo);
	vQryRes = vQry.Execute().Unload();
	// Build vacant periods
	i = 0;
	vCurRow = Undefined;
	vNextRow = Undefined;
	While i < (vQryRes.Count() - 1) Do
		vCurRow = vQryRes.Get(i);
		vNextRow = vQryRes.Get(i+1);
		If vCurRow.Room = vNextRow.Room Then
			vCurRow.VacantToDate = vNextRow.VacantFromDate;
		Else
			vCurRow.VacantToDate = '39991231235959';
		EndIf;
		i = i + 1;
	EndDo;
	If vNextRow <> Undefined And 
		vNextRow.VacantFromDate = vNextRow.VacantToDate Then
		vNextRow.VacantToDate = '39991231235959';
	EndIf;
	If vCurRow <> Undefined And 
		vCurRow.VacantFromDate = vCurRow.VacantToDate Then
		vCurRow.VacantToDate = '39991231235959';
	EndIf;
	// Glue chained periods with the same resources
	i = 0;
	While i < (vQryRes.Count() - 1) Do
		vCurRow = vQryRes.Get(i);
		vNextRow = vQryRes.Get(i + 1);
		If vNextRow.Room = vCurRow.Room And
			vNextRow.VacantFromDate = vCurRow.VacantToDate And 
			vNextRow.BedsVacant = vCurRow.BedsVacant And 
			vNextRow.RoomsVacant = vCurRow.RoomsVacant Then
			vCurRow.VacantToDate = vNextRow.VacantToDate;
			vQryRes.Delete(i + 1);
		Else
			i = i + 1;
		EndIf;
	EndDo;
	// Delete periods where vacant beds is less or equal zero
	i = 0;
	While i < vQryRes.Count() Do
		vCurRow = vQryRes.Get(i);
		If vCurRow.BedsVacant <= 0 Then
			vQryRes.Delete(i);
		Else
			i = i + 1;
		EndIf;
	EndDo;
	// Return vacant periods
	Return vQryRes;
EndFunction // GetRoomsVacantPeriods

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetPeriodDailyVacants(pPeriodFrom, pPeriodTo, pRoomType = Undefined, SelHotel, SelRoomSection, SelRoomClass, SelRoomTypes, SelRoomType)
	// Initialize "Show reports in beds" flag
	vShowReportsInBeds = False;
	If valueIsFilled(SelHotel) Then
		vShowReportsInBeds = SelHotel.ShowReportsInBeds;
	EndIf;
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	RoomInventoryBalance.Period AS Period,
	|	RoomInventoryBalance.CounterClosingBalance AS CounterClosingBalance,
	|	RoomInventoryBalance.RoomsVacantClosingBalance AS RoomsVacant,
	|	RoomInventoryBalance.BedsVacantClosingBalance AS BedsVacant
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|			&qDateTimeFrom,
	|			&qDateTimeTo,
	|			DAY,
	|			RegisterRecordsAndPeriodBoundaries,
	|			(Hotel IN HIERARCHY (&qHotel)
	|				OR &qHotelIsEmpty)
	|				AND (Room.RoomSection IN HIERARCHY (&qRoomSection)
	|					OR &qRoomSectionIsEmpty)
	|				AND (RoomType.RoomClass = &qRoomClass
	|					OR &qRoomClassIsEmpty)
	|				AND (RoomType IN (&qRoomTypes)
	|					OR &qRoomTypesIsEmpty)
	|				AND (RoomType IN HIERARCHY (&qRoomType)
	|					OR &qRoomTypeIsEmpty)
	|				AND NOT RoomType.DoesNotAffectRoomRevenueStatistics
	|				AND NOT RoomType.IsVirtual
	|				AND NOT RoomType.DeletionMark) AS RoomInventoryBalance
	|
	|ORDER BY
	|	Period
	|TOTALS
	|	SUM(CounterClosingBalance),
	|	SUM(RoomsVacant),
	|	SUM(BedsVacant)
	|BY
	|	Period PERIODS(DAY, &qDateTimeFrom, &qDateTimeTo)";
	vQry.SetParameter("qHotel", SelHotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(SelHotel));
	vQry.SetParameter("qRoomClass", SelRoomClass);
	vQry.SetParameter("qRoomClassIsEmpty", Not ValueIsFilled(SelRoomClass));
	vQry.SetParameter("qRoomSection", SelRoomSection);
	vQry.SetParameter("qRoomSectionIsEmpty", Not ValueIsFilled(SelRoomSection));
	vQry.SetParameter("qRoomTypes", SelRoomTypes);
	vQry.SetParameter("qRoomTypesIsEmpty", SelRoomTypes.Count() = 0);
	vQry.SetParameter("qRoomType", ?(ValueIsFilled(pRoomType), pRoomType, SelRoomType));
	vQry.SetParameter("qRoomTypeIsEmpty", Not ValueIsFilled(?(ValueIsFilled(pRoomType), pRoomType, SelRoomType)));
	vQry.SetParameter("qDateTimeFrom", BegOfDay(pPeriodFrom));
	vQry.SetParameter("qDateTimeTo", EndOfDay(pPeriodTo));
	vQryRes = vQry.Execute();
	
	// Fill end of day balances and periods
	vDailyVacants = New Structure();
	
	// Save all periods where vacant resource is changed and save periods where last change per day took place
	vLastVacant = Undefined;
	vQryDays = vQryRes.Select(QueryResultIteration.ByGroups, "Period", "ALL");
	While vQryDays.Next() Do
		vPeriod = vQryDays.Period;
		If (vPeriod < pPeriodFrom) Or (vPeriod > pPeriodTo) Then
			Continue;
		EndIf;
		vBegOfDay = BegOfDay(vPeriod);
		SetQueryVacantResource(vQryDays, vShowReportsInBeds, vLastVacant);
		vDailyVacants.Insert("D" + Format(vPeriod, "DF=yyyyMMdd"), ?(vLastVacant = Undefined, 0, vLastVacant));
	EndDo;
	
	Return vDailyVacants;
EndFunction // GetPeriodDailyVacants

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure SetQueryVacantResource(pQryRow, pShowReportsInBeds, pLastVacant)
	vVacant = 0;	
	If pShowReportsInBeds Then
		If pQryRow.BedsVacant = Null Then
			vVacant = pLastVacant;
		Else
			vVacant = pQryRow.BedsVacant;
		EndIf;
	Else
		If pQryRow.RoomsVacant = Null Then
			vVacant = pLastVacant;
		Else
			vVacant = pQryRow.RoomsVacant;
		EndIf;
	EndIf;
	If pLastVacant = Undefined Or 
		pLastVacant <> vVacant Then
		pLastVacant = vVacant;
	EndIf;
EndProcedure // SetQueryVacantResource

// -----------------------------------------------------------------------------
&AtServer
Function ReservOnServer(rWarning = "")
	vGroupDocRef = Documents.Reservation.EmptyRef();
	vHotel = Catalogs.Hotels.EmptyRef();
	vGuestGroup = Catalogs.GuestGroups.EmptyRef();
	If GuestGroupCreationMode And ValueIsFilled(GuestGroup) Then
		vGuestGroup = GuestGroup;
		If GuestGroup.ClientDoc <> Undefined Then
			vGroupDocRef = GuestGroup.ClientDoc;
		Else
			vGroupDocRef = GetFirstGroupReservationDocument(GuestGroup);
		EndIf;
		vHotel = GuestGroup.Owner;
	EndIf;
	If ValueIsFilled(CurRoom) Then
		vDocumentsTable = FormAttributeToValue("DocumentsTable");
		vFindedDocumentsByRoom = vDocumentsTable.FindRows(New Structure("Room, CheckIn", CurRoom, True));
		vDocumentInCurrentDay = Undefined;
		vDocItem = Undefined;
		For Each vItem In vFindedDocumentsByRoom Do
			If (BegOfDay(vItem.CheckInDate) < BegOfDay(SelCheckInDate) And BegOfDay(vItem.CheckOutDate) > BegOfDay(SelCheckInDate))
				Or (BegOfDay(vItem.CheckInDate) < BegOfDay(SelCheckOutDate) And BegOfDay(vItem.CheckOutDate) > BegOfDay(SelCheckOutDate))
				Or (BegOfDay(vItem.CheckInDate) > BegOfDay(SelCheckInDate) And BegOfDay(vItem.CheckOutDate) < BegOfDay(SelCheckOutDate)) Then
				Return NStr("en='Cross';ru='Пересечение';de='Überschneidung'");
			ElsIf (vItem.CheckOutDate < EndOfDay(SelCheckInDate) And vItem.CheckOutDate > BegOfDay(SelCheckInDate)) Then
				If vDocItem = Undefined Or vDocItem.CheckOutDate < vItem.CheckOutDate Then
					vDocItem = vItem;
				EndIf;
			EndIf;
		EndDo;
		vRoomType = CurRoom.RoomType;
	Else
		vRoomType = CurRoomType;
	EndIf;
	// Create reservation document
	vDocObj = Documents.Reservation.CreateDocument();
	If ValueIsFilled(vHotel) Then
		vDocObj.Hotel = vHotel;
	Else
		vDocObj.Hotel = SelHotel;
	EndIf;
	If ValueIsFilled(vGuestGroup) Then
		vDocObj.GuestGroup = vGuestGroup;
	EndIf;
	vDocObj.pmFillAttributesWithDefaultValues();
	If vDocItem <> Undefined And ((vDocItem.CheckOutDate - BegOfDay(vDocItem.CheckOutDate)) >= (vDocObj.CheckInDate - BegOfDay(vDocObj.CheckInDate))) Then
		vDocObj.CheckInDate = SelCheckInDate + (vDocItem.CheckOutDate - BegOfDay(vDocItem.CheckOutDate)) + 1;
	Else
		vDocObj.CheckInDate = SelCheckInDate + (vDocObj.CheckInDate - BegOfDay(vDocObj.CheckInDate));
	EndIf;
	vDocObj.CheckOutDate = SelCheckOutDate + (vDocObj.CheckOutDate - BegOfDay(vDocObj.CheckOutDate));
	If cm0SecondShift(vDocObj.CheckInDate) >= cm0SecondShift(vDocObj.CheckOutDate) Then
		vDocObj.CheckOutDate = vDocObj.CheckOutDate + 86400;
	EndIf;
	vDocObj.Duration = cmCalculateDuration(vDocObj.RoomRate, vDocObj.CheckInDate, vDocObj.CheckOutDate);
	vDocObj.PriceCalculationDate = '00010101';
	If ValueIsFilled(vRoomType) Then
		If vRoomType.StopSale Then
			vRemarks = "";
			If cmIsStopSalePeriod(vRoomType, vDocObj.CheckInDate, vDocObj.CheckOutDate, vRemarks) Then
				If Not cmCheckUserPermissions("HavePermissionToIgnoreStopSaleLimitations") Then
					vError = NStr("en='You have chosen room type with stop sale flag turned on! Rechoose room type!';ru='Выбрали тип номера снятый с продажи! Перевыберите тип номера!';de='Sie haben einen Zimmertyp gewählt, der aus dem Angebot genommen wurde! Wählen Sie einen anderen Zimmertyp!'") + Chars.LF + vRemarks;
					Return vError;
				Else
					rWarning = NStr("en='You have chosen room type with stop sale flag turned on!';ru='Выбрали тип номера снятый с продажи!';de='Sie haben einen Zimmertyp gewählt, der aus dem Angebot genommen wurde!'") + Chars.LF + vRemarks;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	vDocObj.RoomQuantity = 1;
	vDocObj.NumberOfPersons = 1;
	vDocObj.RoomType = vRoomType;
	vDocObj.Room = CurRoom;
	If ValueIsFilled(vDocObj.RoomType) Then
		If ValueIsFilled(vDocObj.RoomType.Company) Then
			vDocObj.Company = vDocObj.RoomType.Company;
		EndIf;
	EndIf;         
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
		If ValueIsFilled(vDocObj.RoomRate.Company) Then
			vDocObj.Company = vDocObj.RoomRate.Company;
		EndIf;
	EndIf;
	If ValueIsFilled(vGroupDocRef) Then
		vDocObj.Customer = vGroupDocRef.Customer;
		vDocObj.Contract = vGroupDocRef.Contract;
		vDocObj.ContactPerson = vGroupDocRef.ContactPerson;
		vDocObj.Agent = vGroupDocRef.Agent;
		vDocObj.AgentCommission = vGroupDocRef.AgentCommission;
		vDocObj.AgentCommissionServiceGroup = vGroupDocRef.AgentCommissionServiceGroup;
		vDocObj.AgentCommissionType = vGroupDocRef.AgentCommissionType;
		vDocObj.Discount = vGroupDocRef.Discount;
		vDocObj.DiscountConfirmationText = vGroupDocRef.DiscountConfirmationText;
		vDocObj.DiscountServiceGroup = vGroupDocRef.DiscountServiceGroup;
		vDocObj.DiscountType = vGroupDocRef.DiscountType;
	EndIf;
	vDocObj.pmCalculateResources();
	vDocObj.pmSetDiscounts();
	If ValueIsFilled(vGroupDocRef) And vGroupDocRef.PlannedPaymentMethod <> vDocObj.PlannedPaymentMethod Then
		If ValueIsFilled(vDocObj.Contract) Then
			vDocObj.pmLoadChargingRules(vDocObj.Contract);
		ElsIf ValueIsFilled(vDocObj.Customer) Then
			vDocObj.pmLoadChargingRules(vDocObj.Customer);
		EndIf;
	EndIf;
	vDocObj.pmSetPlannedPaymentMethod();
	vDocObj.pmCalculateServices( , , , , , vDocObj.IsForFolioSplit);
	ValueToFormAttribute(vDocObj, "ResObject");			
	GuestGroup = vDocObj.GuestGroup;
	Return "";
EndFunction // ReservOnServer

// -----------------------------------------------------------------------------
&AtServer
Function CheckInOnServer(rWarning = "")
	vGroupDocRef = Documents.Accommodation.EmptyRef();
	vHotel = Catalogs.Hotels.EmptyRef();
	vGuestGroup = Catalogs.GuestGroups.EmptyRef();
	If GuestGroupCreationMode And ValueIsFilled(GuestGroup) Then
		vGuestGroup = GuestGroup;
		If GuestGroup.ClientDoc <> Undefined Then
			vGroupDocRef = GuestGroup.ClientDoc;
		EndIf;
		vHotel = GuestGroup.Owner;
	EndIf;
	If ValueIsFilled(CurRoom) Then
		vDocumentsTable = FormAttributeToValue("DocumentsTable");
		vFindedDocumentsByRoom = vDocumentsTable.FindRows(New Structure("Room, CheckIn", CurRoom, True));
		vDocumentInCurrentDay = Undefined;
		vDocItem = Undefined;
		For Each vItem In vFindedDocumentsByRoom Do
			If (BegOfDay(vItem.CheckInDate) < BegOfDay(SelCheckInDate) And BegOfDay(vItem.CheckOutDate) > BegOfDay(SelCheckInDate))
				Or (BegOfDay(vItem.CheckInDate) < BegOfDay(SelCheckOutDate) And BegOfDay(vItem.CheckOutDate) > BegOfDay(SelCheckOutDate))
				Or (BegOfDay(vItem.CheckInDate) > BegOfDay(SelCheckInDate) And BegOfDay(vItem.CheckOutDate) < BegOfDay(SelCheckOutDate)) Then
				Return NStr("en='Cross';ru='Пересечение';de='Überschneidung'");
			ElsIf (vItem.CheckOutDate < EndOfDay(SelCheckInDate) And vItem.CheckOutDate > BegOfDay(SelCheckInDate)) Then
				If vDocItem = Undefined Or vDocItem.CheckOutDate < vItem.CheckOutDate Then
					vDocItem = vItem;
				EndIf;
			EndIf;
		EndDo;
		vRoomType = CurRoom.RoomType;
	Else
		vRoomType = CurRoomType;
	EndIf;
	// Create accommodation document
	vDocObj = Documents.Accommodation.CreateDocument();
	If ValueIsFilled(vHotel) Then
		vDocObj.Hotel = vHotel;
	Else
		vDocObj.Hotel = SelHotel;
	EndIf;
	If ValueIsFilled(vGuestGroup) Then
		vDocObj.GuestGroup = vGuestGroup;
	EndIf;
	vDocObj.pmFillAttributesWithDefaultValues();
	vDocObj.CheckOutDate = SelCheckOutDate + (vDocObj.CheckOutDate - BegOfDay(vDocObj.CheckOutDate));
	If cm0SecondShift(vDocObj.CheckInDate) >= cm0SecondShift(vDocObj.CheckOutDate) Then
		vDocObj.CheckOutDate = vDocObj.CheckOutDate + 86400;
	EndIf;
	vDocObj.Duration = cmCalculateDuration(vDocObj.RoomRate, vDocObj.CheckInDate, vDocObj.CheckOutDate);
	vDocObj.PriceCalculationDate = '00010101';
	If ValueIsFilled(vRoomType) Then
		If vRoomType.StopSale Then
			vRemarks = "";
			If cmIsStopSalePeriod(vRoomType, vDocObj.CheckInDate, vDocObj.CheckOutDate, vRemarks) Then
				If Not cmCheckUserPermissions("HavePermissionToIgnoreStopSaleLimitations") Then
					vError = NStr("en='You have chosen room type with stop sale flag turned on! Rechoose room type!';ru='Выбрали тип номера снятый с продажи! Перевыберите тип номера!';de='Sie haben einen Zimmertyp gewählt, der aus dem Angebot genommen wurde! Wählen Sie einen anderen Zimmertyp!'") + Chars.LF + vRemarks;
					Return vError;
				Else
					rWarning = NStr("en='You have chosen room type with stop sale flag turned on!';ru='Выбрали тип номера снятый с продажи!';de='Sie haben einen Zimmertyp gewählt, der aus dem Angebot genommen wurde!'") + Chars.LF + vRemarks;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	vDocObj.NumberOfPersons = 1;
	vDocObj.RoomType = vRoomType;
	vDocObj.Room = CurRoom;
	If ValueIsFilled(vDocObj.RoomType) Then
		If ValueIsFilled(vDocObj.RoomType.Company) Then
			vDocObj.Company = vDocObj.RoomType.Company;
		EndIf;
	EndIf;         
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
		If ValueIsFilled(vDocObj.RoomRate.Company) Then
			vDocObj.Company = vDocObj.RoomRate.Company;
		EndIf;
	EndIf;
	If ValueIsFilled(vGroupDocRef) Then
		vDocObj.Customer = vGroupDocRef.Customer;
		vDocObj.Contract = vGroupDocRef.Contract;
		vDocObj.ContactPerson = vGroupDocRef.ContactPerson;
		vDocObj.Agent = vGroupDocRef.Agent;
		vDocObj.AgentCommission = vGroupDocRef.AgentCommission;
		vDocObj.AgentCommissionServiceGroup = vGroupDocRef.AgentCommissionServiceGroup;
		vDocObj.AgentCommissionType = vGroupDocRef.AgentCommissionType;
		vDocObj.Discount = vGroupDocRef.Discount;
		vDocObj.DiscountConfirmationText = vGroupDocRef.DiscountConfirmationText;
		vDocObj.DiscountServiceGroup = vGroupDocRef.DiscountServiceGroup;
		vDocObj.DiscountType = vGroupDocRef.DiscountType;
	EndIf;
	vDocObj.pmCalculateResources();
	vDocObj.pmSetDiscounts();
	If ValueIsFilled(vGroupDocRef) And vGroupDocRef.PlannedPaymentMethod <> vDocObj.PlannedPaymentMethod Then
		If ValueIsFilled(vDocObj.Contract) Then
			vDocObj.pmLoadChargingRules(vDocObj.Contract);
		ElsIf ValueIsFilled(vDocObj.Customer) Then
			vDocObj.pmLoadChargingRules(vDocObj.Customer);
		EndIf;
	EndIf;
	vDocObj.pmSetPlannedPaymentMethod();
	vDocObj.pmCalculateServices( , , , , , vDocObj.IsForFolioSplit);
	ValueToFormAttribute(vDocObj, "AccObject");			
	GuestGroup = vDocObj.GuestGroup;
	Return "";
EndFunction // CheckInOnServer

// -----------------------------------------------------------------------------
&AtServer
Function GetFirstGroupReservationDocument(pGuestGroup)
	vQry = New Query;
	vQry.Text =
	"SELECT
	|	Reservation.Ref
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	Reservation.GuestGroup = &qGuestGroup
	|	AND Reservation.Posted
	|	AND NOT Reservation.DeletionMark
	|
	|ORDER BY
	|	Reservation.Date";
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	vQryResult = vQry.Execute().Select();
	While vQryResult.Next() Do
		Return vQryResult.Ref;
	EndDo;
	Return Documents.Reservation.EmptyRef();
EndFunction // GetFirstGroupDocument

// -----------------------------------------------------------------------------
&AtClient
Procedure RefreshFormIdleHandler() Export
	If ThisObject.IsInputAvailable() Then
		Refresh(Undefined);
	Else
		AttachIdleHandler("RefreshFormIdleHandler", 0.5, True);
	EndIf;
EndProcedure // RefreshFormIdleHandler

// -----------------------------------------------------------------------------
&AtClient
Procedure RefreshList() Export
	Refresh(Commands.Refresh);
EndProcedure // RefreshList

// -----------------------------------------------------------------------------
&AtServerNoContext
Function CheckIsCheckOut(pRef)
	Return pRef.AccommodationStatus.IsInHouse;	
EndFunction //  CheckIsCheckOut()

// -----------------------------------------------------------------------------
&AtServerNoContext
Function CheckIsCheckIn(pRef)
	Return Not pRef.ReservationStatus.IsCheckIn;	
EndFunction //  CheckIsCheckOut()

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetMainRoomDocument(pDocument)
	vDocument = pDocument;
	If TypeOf(vDocument) = Type("DocumentRef.Accommodation") Then
		vDocument = cmGetOneRoomAccommodation(vDocument.Room, vDocument.GuestGroup, vDocument.CheckInDate, vDocument.CheckOutDate, vDocument.Number);
	ElsIf TypeOf(vDocument) = Type("DocumentRef.Reservation") Then
		vDocument = cmGetOneRoomReservation(vDocument.Number, vDocument.GuestGroup, vDocument.Room, vDocument.CheckInDate, vDocument.CheckOutDate);
	EndIf;
	Return vDocument;
EndFunction // GetMainRoomDocument

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetRoomStatusesListAtServer(pRoomStatus, pRoom)
	vRoomStatusesList = New ValueList();
	// Get hotel
	vHotel = Undefined;
	If ValueIsFilled(pRoom) Then
		vHotel = pRoom.Owner;
	EndIf;
	If Not ValueIsFilled(vHotel) Then
		vHotel = SessionParameters.CurrentHotel;
	EndIf;
	// Run query to get list of room statuses
	vRoomStatuses = cmGetAllowedRoomStatuses(SessionParameters.CurrentUser, pRoomStatus);
	vRoomStatusesList.LoadValues(vRoomStatuses.UnloadColumn("RoomStatus"));
	For Each vRoomStatusesListItem In vRoomStatusesList Do
		If ValueIsFilled(vRoomStatusesListItem.Value) Then
			vRoomStatusesListItem.Picture = cmGetRoomStatusIcon(vRoomStatusesListItem.Value);
		EndIf;
	EndDo;
	// Add empty room status
	If ValueIsFilled(vHotel) And Not ValueIsFilled(vHotel.VacantRoomStatus) Then
		vRoomStatusesList.Add(Catalogs.RoomStatuses.EmptyRef(), NStr("en='<Empty status>'; ru='<Пустой статус>'; de='<Leer Status>'"));
	EndIf;
	// Return list
	Return vRoomStatusesList;
EndFunction // GetRoomStatusesListAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure AddRoomItemToListAtServer(pRoomStatusesList, pRoom)
	// Add room
	If ValueIsFilled(pRoom) Then
		If pRoomStatusesList.Count() > 0 Then
			pRoomStatusesList.Add(Undefined, "------------------------------");
		EndIf;
		pRoomStatusesList.Add(pRoom, NStr("en='Open room: '; ru='Открыть карточку номера: '; de='Öffnen Zimmer: '") + pRoom);
	EndIf;
EndProcedure // AddRoomItemToListAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure ChangeRoomStatusAtServer(pRoom, pRoomStatus)
	// Update room status
	vRoomObj = pRoom.GetObject();
	vRoomObj.RoomStatus = pRoomStatus;
	vRoomObj.Write();
	// Add record to the room status change history
	vRoomObj.pmWriteToRoomStatusChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser, "");
EndProcedure // ChangeRoomStatusAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure UpdateRoomPlannerItemAtServer(pIndex, pRoomStatus)
	vPlannerItem = RoomPlanner.Items.Get(pIndex);
	vPlannerItem.Value = pRoomStatus;
	vPlannerItem.Text = pRoomStatus;
	If ValueIsFilled(pRoomStatus) Then
		vColor = Undefined;
		If ValueIsFilled(pRoomStatus.Color) Then
			vColor = pRoomStatus.Color.Get();
		EndIf;
		If vColor <> Undefined Then
			vPlannerItem.BackColor = vColor;
		Else
			vPlannerItem.BackColor = WebColors.White;
		EndIf;
		vPlannerItem.Picture = cmGetRoomStatusIcon(pRoomStatus);
	EndIf;
EndProcedure // UpdateRoomPlannerItemAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomStatusChoiceCompleted(pListItem, pExtraParams) Export
	If pListItem <> Undefined Then
		If TypeOf(pListItem.Value) = Type("CatalogRef.RoomStatuses") Then
			// Change room status at server
			vNewRoomStatus = pListItem.Value;
			ChangeRoomStatusAtServer(pExtraParams.Room, vNewRoomStatus);
			// Update rooms planner representation
			UpdateRoomPlannerItemAtServer(RoomPlanner.Items.IndexOf(pExtraParams.PlannerItem), vNewRoomStatus);
		ElsIf TypeOf(pListItem.Value) = Type("CatalogRef.Rooms") And ValueIsFilled(pListItem.Value) Then
			ShowValue(, pListItem.Value);
		EndIf;
	EndIf;
EndProcedure // RoomStatusChoiceCompleted

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetIntersectedReservation(pRoom, pCheckInDate, pCheckOutDate)
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	Reservation.Ref AS Ref
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	Reservation.ReservationStatus.IsActive
	|	AND Reservation.Posted
	|	AND Reservation.Room = &qRoom
	|	AND Reservation.CheckInDate < &qCheckOutDate
	|	AND Reservation.CheckOutDate > &qCheckInDate
	|
	|ORDER BY
	|	Reservation.SortCode";
	vQry.SetParameter("qRoom", pRoom);
	vQry.SetParameter("qCheckInDate", pCheckInDate);
	vQry.SetParameter("qCheckOutDate", pCheckOutDate);
	vDocs = vQry.Execute().Unload();
	If vDocs.Count() > 0 Then
		Return vDocs.Get(0).Ref;
	Else
		Return Undefined;
	EndIf;
EndFunction // GetIntersectedReservation

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterReservationIntersectionCheck(pUC, pExtraParams) Export
	If pUC = Undefined Or pUC = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	If pUC = DialogReturnCode.No Then
		pExtraParams.SwapRoundReservation = Undefined;
	EndIf;
	
	If pUC = DialogReturnCode.No Or pUC = DialogReturnCode.Yes And pExtraParams.OldRoomType = pExtraParams.NewRoomType Or 
	   pUC = DialogReturnCode.Yes And ValueIsFilled(tcOnServer.cmGetAttributeByRef(pExtraParams.Doc, "RoomTypeUpgrade")) And 
	                                  ValueIsFilled(pExtraParams.SwapRoundReservation) And ValueIsFilled(tcOnServer.cmGetAttributeByRef(pExtraParams.SwapRoundReservation, "RoomTypeUpgrade")) Then
		vMessage = "";
		vCancelEdit = ProcessItemChangeAtServer(pExtraParams.Doc, pExtraParams.OldStart, pExtraParams.OldEnd, pExtraParams.OldRoom, pExtraParams.OldRoomType, pExtraParams.NewStart, pExtraParams.NewEnd, pExtraParams.NewRoom, pExtraParams.NewRoomType, pExtraParams.ToolTip, vMessage, pExtraParams.SwapRoundReservation);
		If Not vCancelEdit Then
			pExtraParams.ChangedItem.ToolTip = pExtraParams.ToolTip;
			If pExtraParams.OldStart = pExtraParams.NewStart And pExtraParams.OldEnd = pExtraParams.NewEnd Then
				pExtraParams.ChangedItem.Begin = pExtraParams.OldStart;
				pExtraParams.ChangedItem.End = pExtraParams.OldEnd;
			EndIf;
		EndIf;
		
		If Not IsBlankString(vMessage) Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage);
		EndIf;
		
		AttachIdleHandler("FillRoomPlannerIdleHandler", 0.1, True);
	Else
		vQuestion = NStr("en='Recalculate reservation room prices according to the new room types?'; 
		                 |ru='Пересчитать цены брони согласно новым типам номеров?'; 
						 |de='Buchungspreise nach neuen Zimmertypen neu berechnen?'");
		ShowQueryBox(New NotifyDescription("AfterRoomTypeChangeBehaviourAnswer", ThisObject, pExtraParams), vQuestion, QuestionDialogMode.YesNo, , DialogReturnCode.No);
	EndIf;
EndProcedure // AfterReservationIntersectionCheck

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterRoomTypeChangeBehaviourAnswer(pUC, pExtraParams) Export
	vRecalculatePrices = True;
	If pUC = Undefined Then
		Return;
	ElsIf pUC = DialogReturnCode.No Then
		vRecalculatePrices = False;
	EndIf;
	
	vMessage = "";
	vCancelEdit = ProcessItemChangeAtServer(pExtraParams.Doc, pExtraParams.OldStart, pExtraParams.OldEnd, pExtraParams.OldRoom, pExtraParams.OldRoomType, pExtraParams.NewStart, pExtraParams.NewEnd, pExtraParams.NewRoom, pExtraParams.NewRoomType, pExtraParams.ToolTip, vMessage, pExtraParams.SwapRoundReservation, vRecalculatePrices);
	If Not vCancelEdit Then
		pExtraParams.ChangedItem.ToolTip = pExtraParams.ToolTip;
		If pExtraParams.OldStart = pExtraParams.NewStart And pExtraParams.OldEnd = pExtraParams.NewEnd Then
			pExtraParams.ChangedItem.Begin = pExtraParams.OldStart;
			pExtraParams.ChangedItem.End = pExtraParams.OldEnd;
		EndIf;
	EndIf;
	
	If Not IsBlankString(vMessage) Then
		tcCommonFunctionOnClientServer.TextMessage(vMessage);
	EndIf;
	
	AttachIdleHandler("FillRoomPlannerIdleHandler", 0.1, True);
EndProcedure // AfterReservationIntersectionCheck

// -----------------------------------------------------------------------------
&AtServer
Function ProcessItemChangeAtServer(pDoc, pOldStart, pOldEnd, pOldRoom, pOldRoomType, pNewStart, pNewEnd, pNewRoom, pNewRoomType, rToolTip, rMessage = "", pSwapRoundReservation = Undefined, pRecalculatePrices = True)
	rMessage = "";
	vCancelEdit = True;
	
	If ValueIsFilled(pNewRoom) And pNewRoom.IsFolder Then
		rMessage = NStr("en='Wrong room choosen! Action will be canceled! Please click period and edit document data manually.';ru='Выбран недопустимый номер комнаты! Действие будет отменено! Пожалуйста откройте документ щелчком мыши и отредактируйте его данные вручную.';de='Es wurde eine nicht zulässige Zimmernummer gewählt! Die Aktion wird abgebrochen! Öffnen Sie das Dokument per Mausklick und bearbeiten Sie die Daten manuell.'");
		Return vCancelEdit;
	EndIf;
	
	If ValueIsFilled(pNewRoom) And ValueIsFilled(pOldRoom) And pNewRoom <> pOldRoom Or 
	   ValueIsFilled(pNewRoomType) And ValueIsFilled(pOldRoomType) And pNewRoomType <> pOldRoomType Then
		// If room is changed then reset period change
		pNewStart = pOldStart;
		pNewEnd = pOldEnd;
	ElsIf pNewStart <> pOldStart And TypeOf(pDoc) <> Type("DocumentRef.Reservation") Then
		// We do not allow accommodation move to a different check-in date
		pNewStart = pOldStart;
		pNewEnd = pOldEnd;
	ElsIf SpreadsheetScale > 0.1 Then
		// Process day change only
		If BegOfDay(pNewStart) <> BegOfDay(pOldStart) Then
			pNewStart = BegOfDay(pNewStart) + (pOldStart - BegOfDay(pOldStart));
		EndIf;
		If BegOfDay(pNewEnd) <> BegOfDay(pOldEnd) Then
			pNewEnd = BegOfDay(pNewEnd) + (pOldEnd - BegOfDay(pOldEnd));
		EndIf;
	EndIf;
	If pNewEnd <= pNewStart Then
		rMessage = NStr("en='Wrong reservation period! Action will be canceled! Please click reservation and edit document data manually.';ru='Период брони указан не правильно! Действие будет отменено! Пожалуйста откройте документ щелчком мыши и отредактируйте его данные вручную.';de='Der Buchungszeitraum ist nicht korrekt! Die Aktion wird abgebrochen! Öffnen Sie das Dokument per Mausklick und bearbeiten Sie die Daten manuell.'");
		Return vCancelEdit;
	EndIf;
	
	// Get query period
	vPeriodFrom = BegOfDay(SelPeriodFrom);
	vPeriodTo = EndOfDay(SelPeriodFrom) + (SelDays - 1) * 24 * 3600;
	
	// Check current document type
	BeginTransaction(DataLockControlMode.Managed);
	
	Try
		If TypeOf(pDoc) = Type("DocumentRef.SetRoomBlock") Then
			// Check edit prohibited date
			If ValueIsFilled(pDoc.Hotel) Then
				If ValueIsFilled(pDoc.Hotel.EditProhibitedDate) And ValueIsFilled(pDoc.DateTo) And BegOfDay(pDoc.Hotel.EditProhibitedDate) >= BegOfDay(pDoc.DateTo) Then
					rMessage = NStr("en='Document could not be edited! Document period is closed!';ru='Редактирование документа запрещено, т.к. период документа закрыт от изменения!';de='Bearbeitung des Dokuments ist verboten, weil der Dokumentzeitraum für Bearbeitungen geschlossen ist!'");
					Return vCancelEdit;
				EndIf;
			EndIf;
			// Check user permission rights to edit document
			If Not cmCheckUserPermissions("HavePermissionToSetRoomBlocks") Then
				rMessage = NStr("en='You do not have rights to change room blocks!';ru='Нет прав на изменение блокировок номеров!';de='Sie haben keine Rechte, die Blockierung von Zimmern zu bearbeiten!'");
				Return vCancelEdit;
			EndIf;
			// Check if document attributes are changed
			If pNewRoom <> pOldRoom Or
				cm1SecondShift(pDoc.DateFrom) <> cm1SecondShift(pNewStart) Or 
				cm0SecondShift(pDoc.DateTo) <> cm0SecondShift(pNewEnd) Then
				
				// Update document attributes and post document
				vCurDocumentObj = pDoc.GetObject();
				vCurDocumentObj.Room = pNewRoom;
				vCurDocumentObj.Hotel = vCurDocumentObj.Room.Owner;
				vCurDocumentObj.DateFrom = cm1SecondShift(pNewStart);
				vCurDocumentObj.DateTo = cm0SecondShift(pNewEnd);
				// Calculate duration
				vCurDocumentObj.Duration = vCurDocumentObj.pmCalculateDuration();
				// Set is finished
				If Not ValueIsFilled(vCurDocumentObj.DateTo) Or 
					ValueIsFilled(vCurDocumentObj.DateTo) And vCurDocumentObj.DateTo > cm0SecondShift(CurrentSessionDate()) Then
					vCurDocumentObj.IsFinished = False;
				ElsIf ValueIsFilled(vCurDocumentObj.DateTo) And vCurDocumentObj.DateTo <= cm0SecondShift(CurrentSessionDate()) Then
					vCurDocumentObj.IsFinished = True;
				EndIf;
				// Post document
				vCurDocumentObj.Write(DocumentWriteMode.Posting);
				pDoc = vCurDocumentObj.Ref;
				
				// Update item tooltip
				rToolTip = "" + TrimAll(pDoc.RoomBlockType) + Chars.LF + 
				           ?(ValueIsFilled(pDoc.Room), TrimAll(pDoc.Room) + ", ", "") + Format(pDoc.DateFrom, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(pDoc.DateTo, "DF='dd.MM.yyyy HH:mm'") + Chars.LF + 
				           TrimAll(pDoc.Remarks);
									 
				vCancelEdit = False;
			EndIf;
		ElsIf TypeOf(pDoc) = Type("DocumentRef.Accommodation") Or TypeOf(pDoc) = Type("DocumentRef.Reservation") Then
			If TypeOf(pDoc) = Type("DocumentRef.Reservation") Then
				If Not ValueIsFilled(pDoc.Room) And pDoc.Rooms.Count() = 0 And pDoc.RoomQuantity > 1 Then
					rMessage = NStr("en='This is automatically mapped to rooms group reservation that could not be changed in the chart! Action will be canceled! Please click period and edit document data manually.';ru='Из диаграммы нельзя изменять не расписанную бронь, которая была автоматически распределена по номерам (бронь без указания номера комнаты)! Действие будет отменено! Пожалуйста откройте документ щелчком мыши и отредактируйте его данные вручную.';de='Im Diagramm kann keine nicht beschriebene Reservierung geändert werden, die automatisch auf Zimmer verteilt wurde (Reservierung ohne Zimmernummerangabe)! Die Aktion wird abgebrochen! Öffnen Sie das Dokument durch Klicken der Maus und bearbeiten Sie die Daten manuell.'");
					Return vCancelEdit;
				EndIf;
			EndIf;
			// Check edit prohibited date
			If ValueIsFilled(pDoc.Hotel) Then
				If ValueIsFilled(pDoc.Hotel.EditProhibitedDate) And ValueIsFilled(pDoc.CheckOutDate) And 
				   BegOfDay(pDoc.Hotel.EditProhibitedDate) >= BegOfDay(pDoc.CheckOutDate) Then
					rMessage = NStr("en='Document could not be edited! Document period is closed!';ru='Редактирование документа запрещено, т.к. период документа закрыт от изменения!';de='Bearbeitung des Dokuments ist verboten, weil der Dokumentzeitraum für Bearbeitungen geschlossen ist!'");
					Return vCancelEdit;
				EndIf;
			EndIf;
			// Check user permission rights to edit document
			If TypeOf(pDoc) = Type("DocumentRef.Reservation") Then
				If Not cmCheckUserPermissions("HavePermissionToEditReservations") Then
					If pDoc.Author <> SessionParameters.CurrentUser Then
						rMessage = NStr("en='You do not have rights to edit reservations!';ru='Нет прав на изменение брони!';de='Sie haben keine Rechte, die Reservierung zu bearbeiten!'");
						Return vCancelEdit;
					EndIf;
				EndIf;
			ElsIf TypeOf(pDoc) = Type("DocumentRef.Accommodation") Then
				If Not cmCheckUserPermissions("HavePermissionToEditAccommodations") Then
					rMessage = NStr("en='You do not have rights to edit accommodations!';ru='Нет прав на изменение размещений!';de='Sie haben keine Rechte, die Unterbringungen zu bearbeiten!'");
					Return vCancelEdit;
				EndIf;
				If Not cmCheckUserPermissions("HavePermissionToEditCheckedOutAccommodations") Then
					If ValueIsFilled(pDoc.AccommodationStatus) Then
						If Not pDoc.AccommodationStatus.IsInHouse Then
							rMessage = NStr("en='You do not have rights to change checked out accommodations! Document will be opened read only.';ru='Нет прав на изменение выселенных размещений! Документ будет открыт на просмотр.';de='Sie haben keine Rechte, die ausgewiesenen Unterbringungen zu bearbeiten! Das Dokument wird zur Ansicht geöffnet!'");
							Return vCancelEdit;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			// Change of check-in date is forbidden in accommodations and when room change occured
			If pOldStart <> pNewStart Then
				If TypeOf(pDoc) = Type("DocumentRef.Accommodation") Then
					pNewStart = pOldStart;
					pNewEnd = pOldEnd;
				EndIf;
			EndIf;
			// Check if document attributes are changed
			If pOldRoom <> pNewRoom Or
				cm1SecondShift(pOldStart) <> cm1SecondShift(pNewStart) Or 
				cm0SecondShift(pOldEnd) <> cm0SecondShift(pNewEnd) Or 
				ValueIsFilled(pNewRoomType) And ValueIsFilled(pOldRoomType) And pNewRoomType <> pOldRoomType Then
				
				vDocsListToPreProcess = New ValueList();
				If ValueIsFilled(pSwapRoundReservation) Then
					vDocsListToPreProcess.Add(pSwapRoundReservation);
					AddChangeRoomReservations(pDoc, vDocsListToPreProcess, pNewRoom);
					
					For Each vDocsListToPreProcessItem In vDocsListToPreProcess Do
						vDoc = vDocsListToPreProcessItem.Value;
						vCurDocumentObj = vDoc.GetObject();
						
						// Update room
						vCurDocumentObj.Room = Catalogs.Rooms.EmptyRef();
						// Price recalculation
						If Not pRecalculatePrices And Not ValueIsFilled(vCurDocumentObj.RoomTypeUpgrade) Then
							vCurDocumentObj.RoomTypeUpgrade = vCurDocumentObj.RoomType;
						EndIf;
						If vCurDocumentObj.RoomType <> pOldRoomType Then
							vCurDocumentObj.RoomType = pOldRoomType;
							// Set room type company
							If ValueIsFilled(pOldRoomType) Then
								If ValueIsFilled(pOldRoomType.Company) Then
									If vCurDocumentObj.Company <> pOldRoomType.Company Then
										vCurDocumentObj.Company = pOldRoomType.Company;
									EndIf;
								EndIf;
							EndIf;
						EndIf;
						
						// Calculate resources
						vCurDocumentObj.pmCalculateResources();
						// Automatic services list calculation
						vCurDocumentObj.pmCalculateServices( , , , , , vCurDocumentObj.IsForFolioSplit);
						// Post document
						vCurDocumentObj.AdditionalProperties.Insert("DoNotCheckRests", True);
						vCurDocumentObj.Write(DocumentWriteMode.Posting);
						vCurDocumentObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
					EndDo;
				EndIf;
				
				vDocsListToProcess = New ValueList();
				If ValueIsFilled(pDoc.AccommodationType) And pDoc.AccommodationType.DoNotCopyMainGuestAccParameters Then
					vDocsListToProcess.Add(pDoc);
				Else
					vDocsListToProcess.Add(pDoc);
					If pOldRoom <> pNewRoom Or 
					   ValueIsFilled(pNewRoomType) And ValueIsFilled(pOldRoomType) And pNewRoomType <> pOldRoomType Then
						If TypeOf(pDoc) = Type("DocumentRef.Accommodation") Then
							AddChangeRoomAccommodations(pDoc, vDocsListToProcess, pOldRoom);
						ElsIf TypeOf(pDoc) = Type("DocumentRef.Reservation") Then
							AddChangeRoomReservations(pDoc, vDocsListToProcess, pOldRoom);
						EndIf;
					Else
						If TypeOf(pDoc) = Type("DocumentRef.Accommodation") Then
							AddOneRoomAccommodations(pDoc, vDocsListToProcess, pOldRoom);
						ElsIf TypeOf(pDoc) = Type("DocumentRef.Reservation") Then
							AddOneRoomReservations(pDoc, vDocsListToProcess, pOldRoom);
						EndIf;
					EndIf;
				EndIf;
				
				For Each vDocsListToProcessItem In vDocsListToProcess Do
					vDoc = vDocsListToProcessItem.Value;
					
					// Update document attributes and post document
					vCurDocumentObj = vDoc.GetObject();
					If pOldRoom = pNewRoom Then
						If pOldStart = vCurDocumentObj.CheckInDate Then
							vCurDocumentObj.CheckInDate = cm1SecondShift(pNewStart);
						EndIf;
						If pOldEnd = vCurDocumentObj.CheckOutDate Then
							vCurDocumentObj.CheckOutDate = cm0SecondShift(pNewEnd);
						EndIf;
						// Calculate duration
						vCurDocumentObj.Duration = vCurDocumentObj.pmCalculateDuration();
					EndIf;
					
					vChangeRoomDateTime = pNewStart;
					vChangeRoomTime = cm1SecondShift(cmExtractTime(vChangeRoomDateTime));
					If TypeOf(pDoc) = Type("DocumentRef.Accommodation") Then
						If BegOfDay(pNewStart) < BegOfDay(CurrentSessionDate()) Then
							vChangeRoomDateTime = CurrentSessionDate();
							vChangeRoomTime = cm1SecondShift(cmExtractTime(vChangeRoomDateTime));
						EndIf;
					EndIf;
					
					// Check should we update document room or not
					If pOldRoom <> pNewRoom Or ValueIsFilled(pNewRoomType) And ValueIsFilled(pOldRoomType) And pNewRoomType <> pOldRoomType Then
						// Update room
						If vChangeRoomDateTime <> Undefined And ValueIsFilled(pNewRoom) Then
							If (BegOfDay(vChangeRoomDateTime) <= BegOfDay(CurrentSessionDate()) And BegOfDay(pNewEnd) >= BegOfDay(CurrentSessionDate()) Or 
								BegOfDay(vChangeRoomDateTime) <= BegOfDay(vCurDocumentObj.CheckInDate) And BegOfDay(vChangeRoomDateTime) >= BegOfDay(CurrentSessionDate())) Then 
								// Price recalculation
								If Not pRecalculatePrices And vCurDocumentObj.RoomType <> pNewRoomType And Not ValueIsFilled(vCurDocumentObj.RoomTypeUpgrade) Then
									vCurDocumentObj.RoomTypeUpgrade = vCurDocumentObj.RoomType;
								EndIf;
								vCurDocumentObj.Room = pNewRoom;
							EndIf;
						ElsIf vChangeRoomDateTime <> Undefined And ValueIsFilled(pNewRoomType) Then
							If (BegOfDay(vChangeRoomDateTime) <= BegOfDay(CurrentSessionDate()) And BegOfDay(pNewEnd) >= BegOfDay(CurrentSessionDate()) Or 
								BegOfDay(vChangeRoomDateTime) <= BegOfDay(vCurDocumentObj.CheckInDate) And BegOfDay(vChangeRoomDateTime) >= BegOfDay(CurrentSessionDate())) Then 
								// Price recalculation
								If Not pRecalculatePrices And vCurDocumentObj.RoomType <> pNewRoomType And Not ValueIsFilled(vCurDocumentObj.RoomTypeUpgrade) Then
									vCurDocumentObj.RoomTypeUpgrade = vCurDocumentObj.RoomType;
								EndIf;
								vCurDocumentObj.RoomType = pNewRoomType;
							EndIf;
						EndIf;
						
						// Update room rates
						If vChangeRoomDateTime <> Undefined Then
							If BegOfDay(vChangeRoomDateTime) > BegOfDay(vCurDocumentObj.CheckInDate) Then
								vRRRow = vCurDocumentObj.RoomRates.Find(BegOfDay(vChangeRoomDateTime), "AccountingDate");
								If vRRRow = Undefined Then
									vRRRow = vCurDocumentObj.RoomRates.Add();
									vRRRow.AccountingDate = BegOfDay(vChangeRoomDateTime);
									vRRRow.ChangeTime = vChangeRoomTime;
								EndIf;
								If ValueIsFilled(pNewRoom) Then
									vRRRow.Room = pNewRoom;
									vRoomAttrs = vRRRow.Room.GetObject().pmGetRoomAttributes(pNewStart);
									For Each vRoomAttrsRow In vRoomAttrs Do
										vRRRow.RoomType = vRoomAttrsRow.RoomType;
										Break;
									EndDo;
								ElsIf ValueIsFilled(pNewRoomType) Then
									vRRRow.RoomType = pNewRoomType;
								EndIf;
								vCurDocumentObj.RoomRates.Sort("AccountingDate, ChangeTime");
								// Get previous room rates row
								vRoomRates = vCurDocumentObj.pmGetAccommodationPeriods();
								vRRRow = vRoomRates.Find(BegOfDay(vChangeRoomDateTime), "AccountingDate");
								If vRRRow <> Undefined And vRoomRates.IndexOf(vRRRow) > 0 Then
									vPrevRRRow = vRoomRates.Get(vRoomRates.IndexOf(vRRRow) - 1);
									// Set old room to the previous row
									vRRRow = vCurDocumentObj.RoomRates.Find(BegOfDay(vPrevRRRow.AccountingDate), "AccountingDate");
									If vRRRow = Undefined And BegOfDay(vPrevRRRow.AccountingDate) < BegOfDay(vChangeRoomDateTime) Then
										vRRRow = vCurDocumentObj.RoomRates.Add();
										vRRRow.AccountingDate = BegOfDay(vPrevRRRow.AccountingDate);
										If ValueIsFilled(pOldRoom) Then
											vRRRow.Room = pOldRoom;
											vRoomAttrs = vRRRow.Room.GetObject().pmGetRoomAttributes(vRRRow.AccountingDate);
											For Each vRoomAttrsRow In vRoomAttrs Do
												vRRRow.RoomType = vRoomAttrsRow.RoomType;
												Break;
											EndDo;
										ElsIf ValueIsFilled(pOldRoomType) Then
											vRRRow.RoomType = pOldRoomType;
										EndIf;
									EndIf;
									vCurDocumentObj.RoomRates.Sort("AccountingDate, ChangeTime");
								EndIf;
							Else
								// Get first room rates row
								vRoomRates = vCurDocumentObj.pmGetAccommodationPeriods();
								If vRoomRates.Count() > 0 Then
									vFirstRRRow = vRoomRates.Get(0);
									// Set new room to the first row
									vRRRow = vCurDocumentObj.RoomRates.Find(BegOfDay(vFirstRRRow.AccountingDate), "AccountingDate");
									If vRRRow = Undefined Then
										vRRRow = vCurDocumentObj.RoomRates.Add();
										vRRRow.AccountingDate = BegOfDay(vFirstRRRow.AccountingDate);
									EndIf;
									If ValueIsFilled(pNewRoom) Then
										vRRRow.Room = pNewRoom;
										vRoomAttrs = vRRRow.Room.GetObject().pmGetRoomAttributes(vRRRow.AccountingDate);
										For Each vRoomAttrsRow In vRoomAttrs Do
											vRRRow.RoomType = vRoomAttrsRow.RoomType;
											Break;
										EndDo;
									ElsIf ValueIsFilled(pNewRoomType) Then
										vRRRow.RoomType = pNewRoomType;
									EndIf;
									vCurDocumentObj.RoomRates.Sort("AccountingDate, ChangeTime");
								EndIf;
							EndIf;
						EndIf;
					Else
						If pOldStart <> pNewStart Then
							If BegOfDay(pOldStart) <> BegOfDay(vCurDocumentObj.CheckInDate) Then
								vRRRow = vCurDocumentObj.RoomRates.Find(BegOfDay(pOldStart), "AccountingDate");
								If vRRRow <> Undefined Then
									vRRRow.AccountingDate = BegOfDay(pNewStart);
									vRRRow.ChangeTime = cm1SecondShift(cmExtractTime(pNewStart));
								EndIf;
								vCurDocumentObj.RoomRates.Sort("AccountingDate, ChangeTime");
							EndIf;
						EndIf;
						If pOldEnd <> pNewEnd Then
							If BegOfDay(pOldEnd) <> BegOfDay(vCurDocumentObj.CheckOutDate) Then
								vRRRow = vCurDocumentObj.RoomRates.Find(BegOfDay(pOldEnd), "AccountingDate");
								If vRRRow <> Undefined Then
									vRRRow.AccountingDate = BegOfDay(pNewEnd);
									vRRRow.ChangeTime = cm1SecondShift(cmExtractTime(pNewEnd));
								EndIf;
								vCurDocumentObj.RoomRates.Sort("AccountingDate, ChangeTime");
							EndIf;
						EndIf;
					EndIf;
					// Check if room type should be changed
					If ValueIsFilled(vCurDocumentObj.Room) Then
						vRoomAttrs = vCurDocumentObj.Room.GetObject().pmGetRoomAttributes(pNewStart);
						For Each vRoomAttrsRow In vRoomAttrs Do
							vCurDocumentObj.RoomType = vRoomAttrsRow.RoomType;
							Break;
						EndDo;
					EndIf;
					// Check if hotel was changed
					If ValueIsFilled(vCurDocumentObj.RoomType) Then
						If vCurDocumentObj.RoomType.Owner <> vCurDocumentObj.Hotel Then
							vCurDocumentObj.Hotel = vCurDocumentObj.RoomType.Owner;
							vCurDocumentObj.pmProcessHotelChange();
						EndIf;
					EndIf;
					// Set room type company
					If ValueIsFilled(vCurDocumentObj.RoomType) Then
						If ValueIsFilled(vCurDocumentObj.RoomType.Company) Then
							If vCurDocumentObj.Company <> vCurDocumentObj.RoomType.Company Then
								vCurDocumentObj.Company = vCurDocumentObj.RoomType.Company;
							EndIf;
						EndIf;
					EndIf;
					// Set room company
					If ValueIsFilled(vCurDocumentObj.Room.Company) Then
						If vCurDocumentObj.Company <> vCurDocumentObj.Room.Company Then
							vCurDocumentObj.Company = vCurDocumentObj.Room.Company;
						EndIf;
					EndIf;
					// Calculate resources
					vCurDocumentObj.pmCalculateResources();
					// Automatic services list calculation
					vCurDocumentObj.pmCalculateServices( , , , , , vCurDocumentObj.IsForFolioSplit);
					// Post document
					vCurDocumentObj.Write(DocumentWriteMode.Posting);
					// Write record to the document change history
					If TypeOf(vCurDocumentObj.Ref) = Type("DocumentRef.Accommodation") Then
						vCurDocumentObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
					ElsIf TypeOf(vCurDocumentObj.Ref) = Type("DocumentRef.Reservation") Then
						vCurDocumentObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
					EndIf;
				EndDo;
				
				rToolTip = "" + TrimAll(pDoc.GuestGroup) + Chars.LF + 
				                ?(ValueIsFilled(pDoc.Room), TrimAll(pDoc.Room) + ", ", "") + Format(pDoc.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(pDoc.CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + Chars.LF + 
				                TrimAll(pDoc.GuestFullName) + ?(ValueIsFilled(pDoc.AccommodationTemplate), " (" + TrimAll(pDoc.AccommodationTemplate) + ")", "") + Chars.LF + 
								TrimAll(TrimAll(pDoc.Customer) + " " + TrimAll(pDoc.PlannedPaymentMethod)) + Chars.LF + 
								?(ValueIsFilled(pNewRoom), "", Upper(NStr("en='<Booking without room>';ru='<Бронь без номера комнаты>';de='<Buchung ohne Zimmernummer>'")) + Chars.LF) + 
								TrimAll(TrimAll(pDoc.RoomRate) + " " + TrimAll(pDoc.ServicePackage));
								
				If ValueIsFilled(pSwapRoundReservation) Then
					vDocsListToPreProcess.Add(pSwapRoundReservation);
					AddChangeRoomReservations(pDoc, vDocsListToPreProcess, pNewRoom);
					
					For Each vDocsListToPreProcessItem In vDocsListToPreProcess Do
						vDoc = vDocsListToPreProcessItem.Value;
						vCurDocumentObj = vDoc.GetObject();
						
						// Update room
						vCurDocumentObj.Room = pOldRoom;
						// Set room company
						If ValueIsFilled(pOldRoom.Company) Then
							If vCurDocumentObj.Company <> pOldRoom.Company Then
								vCurDocumentObj.Company = pOldRoom.Company;
							EndIf;
						EndIf;
						
						// Calculate resources
						vCurDocumentObj.pmCalculateResources();
						// Automatic services list calculation
						vCurDocumentObj.pmCalculateServices( , , , , , vCurDocumentObj.IsForFolioSplit);
						// Post document
						vCurDocumentObj.Write(DocumentWriteMode.Posting);
						vCurDocumentObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
					EndDo;
				EndIf;
			EndIf;
			vCancelEdit = False;
		EndIf;
		
		CommitTransaction();
	Except
		rMessage = cmGetRootErrorDescription(ErrorInfo());
		vCancelEdit = True;
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
	EndTry;
	
	Return vCancelEdit;
EndFunction // ProcessItemChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure HiglightRoomAndDate(Val pRoom, Val pDate)
	// Selection color
	vSelectionColor = WebColors.PowderBlue;
	// Rooms dimension
	dRoom = RoomPlanner.Dimensions.Find("Room");
	If dRoom = Undefined Then
		Return;
	EndIf;
	// Remove old selections
	If ValueIsFilled(ClickRoom) Then
		vRoomItem = dRoom.Items.Find(ClickRoom);
		If vRoomItem <> Undefined Then
			RoomPlanner.Dimensions.Find("Room").Items.Find(ClickRoom).BackColor = New Color;
		EndIf;
	EndIf;
	If ValueIsFilled(ClickDate) Then
		vBG = RoomPlanner.BackgroundIntervals.Find(vSelectionColor);
		If vBG <> Undefined Then
			RoomPlanner.BackgroundIntervals.Delete(vBG);
		EndIf;
	EndIf;
	// Quit if number of rooms to be shown is more then 50 because of performance issues
	If RoomsPerPage > 50 Then
		Return;
	EndIf;
	// Add new selection
	If ValueIsFilled(pRoom) And TypeOf(pRoom) = Type("CatalogRef.Rooms") And Not tcOnServer.cmGetAttributeByRef(pRoom, "IsFolder") Then
		vRoomItem = dRoom.Items.Find(pRoom);
		If vRoomItem <> Undefined Then
			RoomPlanner.Dimensions.Find("Room").Items.Find(pRoom).BackColor = vSelectionColor;
		EndIf;
	EndIf;
	If ValueIsFilled(pDate) And SpreadsheetScale > 0.1 Then
		vBG = RoomPlanner.BackgroundIntervals.Add(BegOfDay(pDate), EndOfDay(pDate));
		vBG.Color = vSelectionColor;
	EndIf;
	// Save current values
	ClickRoom = pRoom;
	ClickDate = pDate;
EndProcedure // HiglightRoomAndDate

// -----------------------------------------------------------------------------
&AtClient
Procedure SpreadsheetBeforeCreate_AfterInput(pValue, pParametrs) Export
	If pValue <> Undefined Then
		If pValue.Value = 1 Then
			Reserv(Undefined);
		ElsIf pValue.Value = 2 Then
			Checkin(Undefined);
		EndIf;
	EndIf; 
EndProcedure // SpreadsheetBeforeCreate_AfterInput

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure CheckIfCheckOutDateTimeIsFilled() 
	If ValueIsFilled(CheckOutDateTime) And ValueIsFilled(MainRoomDoc) Then
		DetachIdleHandler("CheckIfCheckOutDateTimeIsFilled");
		// Check balances for selected accommodations
		vResult = CheckAccommodationsBalances(AccList);
		If ValueIsFilled(vResult) Then
			tcCommonFunctionOnClientServer.TextMessage(vResult, MessageStatus.Important);
			tcOnServer.cmWriteLogEventAtServer(NStr("en='Accommodation.CheckBalances';ru='Размещение.ПроверкаБаланса';de='Accommodation.CheckBalances'"), Undefined, "Documents.Folio", , vResult + NStr("en=' - Yes';ru=' - Да';de=' - Ja'"));
		EndIf;
		// Check future reservations
		vMessage = CheckFutureReservationsAtServer(MainRoomDoc, CheckOutDateTime);
		If Not IsBlankString(vMessage) Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
		EndIf;
		// Do check-out
		vResult = CheckOutAtServer(MainRoomDoc, AccList, CheckOutDateTime, False);
		If ValueIsFilled(vResult) Then
			If vResult = "SendNotifications" Then
				// Send notification to all open forms
				Notify("Subsystem.Accounts.Changed", MainRoomDoc, ThisObject);
				Notify("Document.ResourceReservation.Write", , ThisObject);
				// Notify that accommodation is changed
				Notify("Document.Accommodation.Write", MainRoomDoc, ThisObject);
			Else
				ShowMessageBox(, vResult);
			EndIf;
		Else
			// Notify that accommodation is changed
			Notify("Document.Accommodation.Write", MainRoomDoc, ThisObject);
		EndIf;
	Else
		Return;
	EndIf;
EndProcedure // CheckIfCheckOutDateTimeIsFilled

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
&AtServer
Function GetMainDocRefAcc(pRef)
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
	|	AND (Accommodation.Room = &qRoom
	|				AND &qRoomIsFilled
	|			OR Accommodation.Number = &qNumber
	|				AND NOT &qRoomIsFilled)
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
&AtClient
Procedure GetCheckOutDate(pCheckInDate, pCheckOutDate)
	vCheckOutDateTime = CurrentDate();
	If vCheckOutDateTime < pCheckInDate Then
		vCheckOutDateTime = pCheckInDate;
	EndIf;
	vFrm = GetForm("CommonForm.tcInputDateTime");
	If tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToUseReferenceHourAsDefaultCheckOutTime") Then
		vFrm.Date = BegOfDay(CurrentDate());
		If BegOfDay(pCheckOutDate) = BegOfDay(CurrentDate()) Then
			If CurrentDate() < pCheckOutDate Then
				vFrm.Time = ExtractTime(CurrentDate());
			Else
				vFrm.Time = ExtractTime(pCheckOutDate);
			EndIf;
		Else
			vFrm.Time = ExtractTime(pCheckOutDate);
		EndIf;
	Else
		vFrm.Date = BegOfDay(CurrentDate());
		vFrm.Time = ExtractTime(CurrentDate());
	EndIf;
	vFrm.Description = NStr("en = 'Check-out time:'; de = 'Abreisezeit:'; ru = 'Время выселения:'");
	vFrm.Title = NStr("en = 'Check-out time:'; de = 'Abreisezeit:'; ru = 'Время выселения:'");
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToEditCheckOutDateTime") Then
		vFrm.IsProtected = True;
	EndIf;
	vFrm.OnCloseNotifyDescription = New NotifyDescription("GetCheckOutDateAfterUserInput", ThisObject, New Structure("CheckInDate, CheckOutDate", pCheckInDate, pCheckOutDate));
	vFrm.Open();
EndProcedure // GetCheckOutDate

// ------------------------------------------------------------------------------------------------
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
&AtServer
Procedure AddOneRoomAccommodations(pDoc, pAccList, pRoom = Undefined)
	vDocsTable = GetOneRoomAccommodations(pDoc, pRoom);
	For Each vDocsTableRow In vDocsTable Do
		If vDocsTableRow.Ref <> pDoc Then
			pAccList.Add(vDocsTableRow.Ref);
		EndIf;
	EndDo;
EndProcedure // AddOneRoomAccommodations

// -----------------------------------------------------------------------------
&AtServer
Procedure AddChangeRoomAccommodations(pDoc, pAccList, pRoom = Undefined)
	vQryRes = GetOtherAccommodationsToChangeRoom(pDoc, pRoom);
	For Each vQryResRow In vQryRes Do
		If vQryResRow.Ref <> pDoc Then
			pAccList.Add(vQryResRow.Ref);
		EndIf;
	EndDo;
EndProcedure // AddChangeRoomAccommodations

// -----------------------------------------------------------------------------
&AtServer
Function GetOneRoomAccommodations(pDoc, pRoom = Undefined)
	vRoom = pRoom;
	If vRoom = Undefined Then
		vRoom = pDoc.Room;
	EndIf;
	vQry = New Query();
	vQry.Text = 
	"SELECT DISTINCT
	|	Accommodations.Recorder AS Ref, 
	|	Accommodations.PointInTime
	|FROM
	|	AccumulationRegister.RoomInventory AS Accommodations
	|WHERE
	|	Accommodations.Recorder <> &qDoc
	|	AND Accommodations.Room = &qRoom
	|	AND Accommodations.GuestGroup = &qGuestGroup
	|	AND Accommodations.PeriodTo > &qCheckInDate
	|	AND Accommodations.IsAccommodation
	|	AND Accommodations.RecordType = VALUE(AccumulationRecordType.Expense)
	|
	|ORDER BY
	|	Accommodations.PointInTime";
	vQry.SetParameter("qDoc", pDoc);
	vQry.SetParameter("qRoom", vRoom);
	vQry.SetParameter("qGuestGroup", pDoc.GuestGroup);
	vQry.SetParameter("qCheckInDate", pDoc.CheckInDate);
	vQryRes = vQry.Execute().Unload();
	Return vQryRes;
EndFunction // GetOneRoomAccommodations 

// -----------------------------------------------------------------------------
&AtServer
Function GetOtherAccommodationsToChangeRoom(pDoc, pRoom)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.Ref <> &qDoc
	|	AND Accommodation.Room = &qRoom
	|	AND Accommodation.GuestGroup = &qGuestGroup
	|	AND Accommodation.CheckOutDate >= &qCheckInDate
	|	AND Accommodation.Posted
	|	AND Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.AccommodationStatus.IsCheckOut
	|ORDER BY
	|	Accommodation.PointInTime";
	vQry.SetParameter("qDoc", pDoc);
	vQry.SetParameter("qRoom", pDoc.Room);
	vQry.SetParameter("qGuestGroup", pDoc.GuestGroup);
	vQry.SetParameter("qCheckInDate", pDoc.CheckInDate);
	vQry.SetParameter("qGuest", pDoc.Guest);
	vQryRes = vQry.Execute().Unload();
	Return vQryRes;
EndFunction // GetOtherAccommodationsToChangeRoom 

// -----------------------------------------------------------------------------
&AtServer
Procedure AddOneRoomReservations(pDoc, pDocsList, pRoom = Undefined)
	vQryRes = GetOneRoomReservations(pDoc, pRoom);
	For Each vQryResRow In vQryRes Do
		If vQryResRow.Ref <> pDoc Then
			pDocsList.Add(vQryResRow.Ref);
		EndIf;
	EndDo;
EndProcedure // AddOneRoomReservations 

// -----------------------------------------------------------------------------
&AtServer
Procedure AddChangeRoomReservations(pDoc, pDocsList, pRoom)
	vQryRes = GetOtherReservationsToChangeRoom(pDoc, pRoom);
	For Each vQryResRow In vQryRes Do
		If vQryResRow.Ref <> pDoc Then
			pDocsList.Add(vQryResRow.Ref);
		EndIf;
	EndDo;
EndProcedure // AddChangeRoomReservations 

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetOneRoomReservations(pDoc, pRoom = Undefined)
	vRoom = pRoom;
	If vRoom = Undefined Then
		vRoom = pDoc.Room;
	EndIf;
	vQry = New Query();
	vQry.Text = 
	"SELECT DISTINCT
	|	Reservations.Recorder AS Ref,
	|	Reservations.PointInTime
	|FROM
	|	AccumulationRegister.RoomInventory AS Reservations
	|WHERE
	|	Reservations.Recorder <> &qDoc
	|	AND (Reservations.Room <> &qEmptyRoom AND Reservations.Room = &qRoom OR Reservations.Room = &qEmptyRoom AND Reservations.Recorder.Number = &qNumber)
	|	AND Reservations.GuestGroup = &qGuestGroup
	|	AND Reservations.PeriodTo > &qCheckInDate
	|	AND Reservations.IsReservation
	|	AND Reservations.RecordType = VALUE(AccumulationRecordType.Expense)
	|
	|ORDER BY
	|	Reservations.PointInTime";
	vQry.SetParameter("qDoc", pDoc);
	vQry.SetParameter("qRoom", vRoom);
	vQry.SetParameter("qEmptyRoom", Catalogs.Rooms.EmptyRef());
	vQry.SetParameter("qNumber", TrimAll(pDoc.Number));
	vQry.SetParameter("qGuestGroup", pDoc.GuestGroup);
	vQry.SetParameter("qCheckInDate", pDoc.CheckInDate);
	vQryRes = vQry.Execute().Unload();
	Return vQryRes;
EndFunction // GetOneRoomReservations 

// -----------------------------------------------------------------------------
&AtServer
Function GetOtherReservationsToChangeRoom(pDoc, pRoom)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reservation.Ref
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	Reservation.Ref <> &qDoc
	|	AND (Reservation.Room <> &qEmptyRoom AND Reservation.Room = &qRoom OR Reservation.Room = &qEmptyRoom AND Reservation.Number = &qNumber)
	|	AND Reservation.GuestGroup = &qGuestGroup
	|	AND Reservation.CheckOutDate >= &qCheckInDate
	|	AND Reservation.Posted
	|	AND Reservation.ReservationStatus.IsActive
	|ORDER BY
	|	Reservation.PointInTime";
	vQry.SetParameter("qDoc", pDoc);
	vQry.SetParameter("qRoom", pDoc.Room);
	vQry.SetParameter("qEmptyRoom", Catalogs.Rooms.EmptyRef());
	vQry.SetParameter("qNumber", TrimAll(pDoc.Number));
	vQry.SetParameter("qGuestGroup", pDoc.GuestGroup);
	vQry.SetParameter("qCheckInDate", pDoc.CheckInDate);
	vQry.SetParameter("qGuest", pDoc.Guest);
	vQryRes = vQry.Execute().Unload();
	Return vQryRes;
EndFunction // GetOtherReservationsToChangeRoom 

// -----------------------------------------------------------------------------
&AtServer
Function CheckAccommodationsBalances(pAccList)
	vFolios = cmGetDocumentFoliosWithDebts(pAccList);
	If vFolios.Count() > 0 Then
		vDoQuery = False;
		vThereAreDebts = False;
		vThereAreDeposits = False;
		vDebtsMessage = NStr("en='Folios: ';ru='По лицевым счетам: ';de='Nach Personenkonten: '") + Chars.LF;
		For Each vFoliosRow In vFolios Do
			If vFoliosRow.SumBalance < 0 Then
				vThereAreDeposits = True;
			ElsIf vFoliosRow.SumBalance > 0 Then
				vThereAreDebts = True;
			EndIf;
			If ValueIsFilled(vFoliosRow.Folio) Then
				If ValueIsFilled(vFoliosRow.Folio.PaymentMethod) Then
					If Not vFoliosRow.Folio.PaymentMethod.BookByCashRegister Or
					   (vFoliosRow.Folio.PaymentMethod.IsByBankTransfer And ValueIsFilled(vFoliosRow.Folio.Customer))Then
						Continue;
					EndIf;
				EndIf;
				vDoQuery = True;
				vDebtsMessage = vDebtsMessage + Chars.LF + "#" + TrimAll(vFoliosRow.Folio.Number) + " " + 
				                TrimAll(vFoliosRow.Folio.Client) + NStr("ru = ', номер '; en = ', room '; de = ', zimmer '") + 
				                TrimAll(vFoliosRow.Folio.Room) + NStr("ru = ', период '; en = ', period '; de = ', period '") + 
				                Format(vFoliosRow.Folio.DateTimeFrom, "DF='dd.MM.yy HH:mm'") + " - " + 
				                Format(vFoliosRow.Folio.DateTimeTo, "DF='dd.MM.yy HH:mm'") + " = " + 
				                cmFormatSum(vFoliosRow.SumBalance, vFoliosRow.Folio.FolioCurrency, "NZ=");
			Else
				vDoQuery = True;
				vDebtsMessage = vDebtsMessage + Chars.LF + NStr("en='<Empty folio>';ru='<Пустое фолио>';de='<Leeres Blatt>'") + " = " + cmFormatSum(vFoliosRow.SumBalance, "NZ=", , True);
			EndIf;
		EndDo;
		If vDoQuery Then
			If vThereAreDebts And Not vThereAreDeposits Then
				vDebtsMessage = vDebtsMessage + Chars.LF + Chars.LF + NStr("en='There are DEBTS!';ru='ЕСТЬ ЗАДОЛЖЕННОСТЬ!';de='ES LIEGT EINE SCHULD VOR!'");
			ElsIf Not vThereAreDebts And vThereAreDeposits Then
				vDebtsMessage = vDebtsMessage + Chars.LF + Chars.LF + NStr("en='There are DEPOSITS!';ru='ЕСТЬ ПЕРЕПЛАТА!';de='ES LIEGT EINE ÜBERZAHLUNG VOR!'");
			Else
				vDebtsMessage = vDebtsMessage + Chars.LF + Chars.LF + NStr("en='There are DEBTS AND DEPOSITS!';ru='ЕСТЬ ЗАДОЛЖЕННОСТЬ И ПЕРЕПЛАТА!';de='ES LIEGT EINE SCHULD oder ÜBERZAHLUNG vor!'");
			EndIf;
			vDebtsMessage = vDebtsMessage + Chars.LF + Chars.LF + NStr("de='Check-out Die Gäste?';en='Do check-out?';ru='Выселить гостей?'");
			Return vDebtsMessage;
		EndIf;
	EndIf;
	Return "";
EndFunction // CheckAccommodationsBalances

// -----------------------------------------------------------------------------
&AtClient
Function ExtractTime(pDateTime)
	vTime = Date(1, 1, 1, Hour(pDateTime), Minute(pDateTime), 0);
	Return vTime;
EndFunction // ExtractTime

// -----------------------------------------------------------------------------
&AtServer
Function CheckOutAtServer(pRef, pAccList, pCheckOutDate, pFixReservationConditions)
	vResult = "";
	vCurRoom = Undefined;
	Try
		BeginTransaction(DataLockControlMode.Managed);
		For Each vAccItem In pAccList Do
			vAccDoc = vAccItem.Value;
			// Commit transaction if room has changed
			If vCurRoom <> Undefined And vCurRoom <> vAccDoc.Room Then
				If TransactionActive() Then
					CommitTransaction();
					// Start transaction
					BeginTransaction(DataLockControlMode.Managed);
				EndIf;
			EndIf;
			If vCurRoom <> vAccDoc.Room Then
				vCurRoom = vAccDoc.Room;
			EndIf;
			// Process document
			If vAccDoc.Posted And TypeOf(vAccDoc) = Type("DocumentRef.Accommodation") Then
				vSkipDocument = False;
				If cmCheckUserPermissions("HavePermissionToCheckOutOnExpectedCheckOutTime") Then
					vCheckOutDate = vAccDoc.CheckOutDate;
					If BegOfDay(vCheckOutDate) > BegOfDay(CurrentSessionDate()) Then
						vSkipDocument = True;
					EndIf;
				EndIf;
				If Not vSkipDocument Then
					// Do check-out
					vAccObj = vAccDoc.GetObject();
					If pFixReservationConditions Then
						vAccObj.FixReservationConditions = pFixReservationConditions;
					EndIf;
					vAccObj.pmCheckOut(pCheckOutDate, , vAccObj.IsForFolioSplit);
					vAccObj.Write(DocumentWriteMode.Posting);
					vAccObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
					// Hide client name data if necessary
					If vAccObj.pmHideClientNameAndNameHistory() Then
						vResult = "SendNotifications";
					EndIf;
				EndIf;
			Else
				Raise NStr("ru='Отметили в списке размещений для выселения не проведенное размещение! Процедура выселения возможна только для проведенных размещений. Операция отменена.';
				           |de='Sie haben in der Unterbringungsliste für die Räumung einer nicht erfolgten Unterbringung markiert! Die Räumung ist nur für erfolgte Unterbringungen möglich. Die Operation wurde abgebrochen.'; 
				           |en='You have selected not posted accommodation for check out! Check out procedure is possible for posted accommodations only. Operation is canceled.'");
			EndIf;
			
			// Check if rooms are the same
			If vAccDoc.Room <> vCurRoom Then
				vCurRoom = Undefined;
			EndIf;
		EndDo;
        If TransactionActive() Then
			CommitTransaction();
		EndIf;
	Except
		vErrInfo = ErrorInfo();
		Try
			If TransactionActive() Then
				RollbackTransaction();
			EndIf;
		Except
		EndTry;
		WriteLogEvent(NStr("en='Accommodation.CheckOut';ru='Размещение.Выселение';de='Accommodation.CheckOut'"), EventLogLevel.Warning, pRef.Metadata(), pRef, cmGetRootErrorDescription(vErrInfo));
		// Try to save current accommodation with in-house state
		vErrorDescription = cmGetRootErrorDescription(vErrInfo);
		vResult = vErrorDescription;
		If (Find(vErrorDescription, "CHECKOUT_WITH_DEBT") > 0 Or Find(vErrorDescription, "ADVANCES_NOT_CLEARED") > 0) And 
		   vAccDoc <> Undefined Then
			Try
				BeginTransaction(DataLockControlMode.Managed);
				// Do change check-out date and time
				vCurRoom = vAccDoc.Room;
				For Each vAccItem In pAccList Do
					vAccDoc = vAccItem.Value;
					If vCurRoom = vAccDoc.Room Then
						If vAccDoc.Posted And TypeOf(vAccDoc) = Type("DocumentRef.Accommodation") Then
							vSkipDocument = False;
							If cmCheckUserPermissions("HavePermissionToCheckOutOnExpectedCheckOutTime") Then
								vCheckOutDate = vAccDoc.CheckOutDate;
								If BegOfDay(vCheckOutDate) > BegOfDay(CurrentSessionDate()) Then
									vSkipDocument = True;
								EndIf;
							EndIf;
							If Not vSkipDocument Then
								vAccObj = vAccDoc.GetObject();
								If pFixReservationConditions Then
									vAccObj.FixReservationConditions = pFixReservationConditions;
								EndIf;
								vAccObj.CheckOutDate = pCheckOutDate;
								// Calculate duration
								vAccObj.Duration = vAccObj.pmCalculateDuration();
								// Automatic services list calculation
								vAccObj.pmCalculateServices( , , , , , vAccObj.IsForFolioSplit);
								vAccObj.Write(DocumentWriteMode.Posting);
								vAccObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
							EndIf;
						EndIf;
					EndIf;
				EndDo;
				If TransactionActive() Then
					CommitTransaction();
				EndIf;
				vResult = "";
			Except
				Try
					If TransactionActive() Then
						RollbackTransaction();
					EndIf;
				Except
				EndTry;
			EndTry;
		EndIf;
	EndTry;
	Return vResult;
EndFunction // CheckOutAtServer

// -----------------------------------------------------------------------------
&AtServer
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
&AtServer
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
				vSelResList.Add(vRow.Ref, cmBuildAccommodationSortingPresentation(vRow.Ref));
			EndDo;
		Else
			vSelResList = pSelResList;
		EndIf;
		If pSelResList = Undefined Then
			Return vSelResList;
		EndIf;
		If vSelResList.Count() = 0 Then
			Return "";
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
&AtServer
Function GetMainDocRef(pRef)
	// Fill one room guests
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	Reservation.Ref AS Ref,
	|	Reservation.Guest AS GuestRef
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	Reservation.GuestGroup = &qGroup
	|	AND (Reservation.Room = &qRoom
	|				AND &qRoomIsFilled
	|			OR Reservation.Number = &qNumber
	|				AND NOT &qRoomIsFilled)
	|	AND Reservation.Posted
	|	AND NOT Reservation.DeletionMark
	|	AND ((Reservation.ReservationStatus.IsActive
	|			OR Reservation.ReservationStatus.IsCheckIn
	|			OR Reservation.ReservationStatus.IsPreliminary
	|			OR Reservation.ReservationStatus.IsInWaitingList)
	|		OR	(Reservation.ReservationStatus = &qReservStatus))
	|ORDER BY
	|	Reservation.AccommodationType.SortCode";
	vQry.SetParameter("qGroup", pRef.GuestGroup);
	vQry.SetParameter("qRoom", pRef.Room);
	vQry.SetParameter("qReservStatus", pRef.ReservationStatus);
	vQry.SetParameter("qRoomIsFilled", ValueIsFilled(pRef.Room));
	vQry.SetParameter("qNumber", pRef.Number);
	vQryResult = vQry.Execute().Unload();
	If vQryResult.Count() > 0 Then
		Return vQryResult.Get(0).Ref;
	EndIf;
	Return pRef;
EndFunction // GetMainDocRef

// -----------------------------------------------------------------------------
&AtServer
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
	            |	AND (Reservations.Room = &qRoom
	            |				AND &qRoomIsFilled
	            |			OR Reservations.Number = &qNumber
	            |				AND NOT &qRoomIsFilled)
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
	vQry.SetParameter("qRoom", pRef.Room);
	vQry.SetParameter("qGuest", pRef.Guest);
	vQry.SetParameter("qEmptyGuest", Catalogs.Clients.EmptyRef());
	vQry.SetParameter("qReservStatus", pRef.ReservationStatus);
	vQry.SetParameter("qAccType", pRef.AccommodationType);
	vQry.SetParameter("qRoomIsFilled", ValueIsFilled(pRef.Room));
	vQry.SetParameter("qNumber", pRef.Number);
	vQry.SetParameter("qEmptyReservationStatusRef", Catalogs.ReservationStatuses.EmptyRef());
	vQryResult = vQry.Execute().Unload();
	Return vQryResult;
EndFunction // GetOneRoomGuests

// -----------------------------------------------------------------------------
&AtServer
Function GetParameters()
	vRowStruct = Undefined;
	vCompany = Catalogs.Companies.EmptyRef();
	vCurHotel = ?(ValueIsFilled(SelHotel), SelHotel, SessionParameters.CurrentHotel);
	vRoomRate = Catalogs.RoomRates.EmptyRef();
	If ValueIsFilled(vCurHotel.RoomRate) Then
		vRoomRate = vCurHotel.RoomRate;
		If ValueIsFilled(vRoomRate.Company) Then
			vCompany = vRoomRate.Company;
		EndIf;
	ElsIf ValueIsFilled(SelRoomType) And Not SelRoomType.IsFolder And ValueIsFilled(SelRoomType.Company) Then
		vCompany = SelRoomType.Company;
	ElsIf ValueIsFilled(vCurHotel.Company) Then
		vCompany = vCurHotel.Company;
	EndIf;
	If ValueIsFilled(SelPeriodFrom) Then
		vCheckInDate = BegOfDay(SelPeriodFrom);
	Else
		vCheckInDate = BegOfDay(CurrentSessionDate());
	EndIf;
	vCheckOutDate = vCheckInDate + 24*3600;
	vCheckInTime = 9 * 3600;
	vCheckOutTime = 22 * 3600;
	If ValueIsFilled(vRoomRate) And vRoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour Then
		If ValueIsFilled(vRoomRate.DefaultCheckInTime) Or ValueIsFilled(vRoomRate.DefaultCheckOutTime) Then
			vCheckInTime = vRoomRate.DefaultCheckInTime - BegOfDay(vRoomRate.DefaultCheckInTime);
		Else
			vCheckInTime = vRoomRate.ReferenceHour - BegOfDay(vRoomRate.ReferenceHour);
		EndIf;
		vCheckOutTime = vRoomRate.ReferenceHour - BegOfDay(vRoomRate.ReferenceHour);
		If ValueIsFilled(vRoomRate.DefaultCheckOutTime) Then
			vCheckOutTime = vRoomRate.DefaultCheckOutTime - BegOfDay(vRoomRate.DefaultCheckOutTime);
		EndIf;
	EndIf;
	vCheckInDate = cm1SecondShift(vCheckInDate + vCheckInTime);
	vCheckOutDate = cm0SecondShift(vCheckOutDate + vCheckOutTime);
	If BegOfDay(vCheckOutDate) <= BegOfDay(vCheckInDate) Then
		vCheckOutDate = vCheckOutDate + 24*3600;
	EndIf;
	vDuration = cmCalculateDuration(vRoomRate, vCheckInDate, vCheckOutDate);
	vRowStruct = New Structure("Hotel, RoomQuota, RoomType, CheckInDate, Duration, CheckOutDate, RoomRate, ClientType, Company", 
	                           vCurHotel, Catalogs.RoomQuotas.EmptyRef(), SelRoomType, vCheckInDate, vDuration, vCheckOutDate, vRoomRate, Catalogs.ClientTypes.EmptyRef(), vCompany);
	Return vRowStruct;
EndFunction // GetParameters

// -----------------------------------------------------------------------------
&AtServer
Function CreateGuestGroupReservations()
	vResult = False;
	vCurHotel = ?(ValueIsFilled(SelHotel), SelHotel, SessionParameters.CurrentHotel);
	// Create group if empty
	If ValueIsFilled(vCurHotel) And Not ValueIsFilled(GuestGroup) Then
		vGuestGroupObj = Catalogs.GuestGroups.CreateItem();
		vGuestGroupObj.Owner = vCurHotel;
		vGuestGroupFolder = vCurHotel.GetObject().pmGetGuestGroupFolder();
		If ValueIsFilled(vGuestGroupFolder) Then
			vGuestGroupObj.Parent = vGuestGroupFolder;
			vGuestGroupObj.SetNewCode();
		EndIf;
		vGuestGroupObj.OneCustomerPerGuestGroup = vCurHotel.OneCustomerPerGuestGroup;
		vGuestGroupObj.Description = TrimAll(GuestGroupDescription);
		vGuestGroupObj.GroupType = GuestGroupType;
		vGuestGroupObj.Status = GuestGroupStatus;
		vGuestGroupObj.RoomRate = RoomRate;
		vGuestGroupObj.SourceOfBusiness = GuestGroupSourceOfBusiness;
		vGuestGroupObj.MarketingCode = GuestGroupMarketingCode;
		vGuestGroupObj.ClientType = GuestGroupClientType;
		vGuestGroupObj.Write();
		GuestGroup = vGuestGroupObj.Ref;
		vResult = True;
	ElsIf ValueIsFilled(GuestGroup) Then
		If TrimAll(GuestGroup.Description) <> TrimAll(GuestGroupDescription) Or
		   GuestGroup.GroupType <> GuestGroupType And ValueIsFilled(GuestGroupType) Or
		   GuestGroup.RoomRate <> RoomRate And ValueIsFilled(RoomRate) Or
		   GuestGroup.SourceOfBusiness <> GuestGroupSourceOfBusiness And ValueIsFilled(GuestGroupSourceOfBusiness) Or
		   GuestGroup.MarketingCode <> GuestGroupMarketingCode And ValueIsFilled(GuestGroupMarketingCode) Or
		   GuestGroup.ClientType <> GuestGroupClientType And ValueIsFilled(GuestGroupClientType) Then
			vGuestGroupObj = GuestGroup.GetObject();
			If Not IsBlankString(GuestGroupDescription) Then
				vGuestGroupObj.Description = TrimAll(GuestGroupDescription);
			EndIf;
			If ValueIsFilled(GuestGroupType) Then
				vGuestGroupObj.GroupType = GuestGroupType;
			EndIf;
			If ValueIsFilled(RoomRate) Then
				vGuestGroupObj.RoomRate = RoomRate;
			EndIf;
			If ValueIsFilled(GuestGroupSourceOfBusiness) Then
				vGuestGroupObj.SourceOfBusiness = GuestGroupSourceOfBusiness;
			EndIf;
			If ValueIsFilled(GuestGroupMarketingCode) Then
				vGuestGroupObj.MarketingCode = GuestGroupMarketingCode;
			EndIf;
			If ValueIsFilled(GuestGroupClientType) Then
				vGuestGroupObj.ClientType = GuestGroupClientType;
			EndIf;
			vGuestGroupObj.Write();
		EndIf;
	EndIf;
	// Create group reservations
	If ValueIsFilled(GuestGroup) Then
		If SelectedReservationPeriods.Count() > 0 Then
			For Each vPeriodRow In SelectedReservationPeriods Do
				vResult = CreateReservationsForRoom(GuestGroup.Owner, vPeriodRow.Room, vPeriodRow.RoomType, vPeriodRow.DateFrom, vPeriodRow.DateTo);
				If Not vResult Then
					Break;
				EndIf;
			EndDo; 
		EndIf;
	EndIf;
	Return vResult;
EndFunction // CreateGuestGroupReservations

// -----------------------------------------------------------------------------
&AtServer
Function CreateReservationsForRoom(Val pHotel = Undefined, pRoom = Undefined, pRoomType = Undefined, pCheckInDate = Undefined, pCheckOutDate = Undefined)
	vResult = False;
	vCheckInDate = cm1SecondShift(pCheckInDate);
	vCheckOutDate = cm0SecondShift(pCheckOutDate);
	If ValueIsFilled(pRoomType) Then
		If pRoomType.StopSale Then
			vRemarks = "";
			If cmIsStopSalePeriod(pRoomType, vCheckInDate, vCheckOutDate, vRemarks) Then
				vUM = New UserMessage();
				vUM.Text = TrimAll(pRoomType) + " - " + NStr("en='You have chosen room type with stop sale flag turned on!'; ru='Выбрали тип номера снятый с продажи!'; de='Sie haben einen Zimmertyp gewählt, der aus dem Verkauf genommen wurde!'") + Chars.LF + vRemarks;
				vUM.Message();
				If Not cmCheckUserPermissions("HavePermissionToIgnoreStopSaleLimitations") Then
					Return vResult;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(pRoom) Then
		If pRoom.StopSale Then
			vRemarks = "";
			If cmIsRoomStopSalePeriod(pRoom, vCheckInDate, vCheckOutDate, vRemarks) Then
				vUM = New UserMessage();
				vUM.Text = TrimAll(pRoom) + " - " + NStr("en='You have chosen room with stop sale flag turned on!'; ru='Выбрали номер снятый с продажи!'; de='Sie haben ein Zimmer gewählt, das aus dem Verkauf genommen wurde!'") + Chars.LF + vRemarks;
				vUM.Message();
				If Not cmCheckUserPermissions("HavePermissionToIgnoreStopSaleLimitations") Then
					Return vResult;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	Try
		BeginTransaction(DataLockControlMode.Managed);
		
		vDocObj = Documents.Reservation.CreateDocument();
		vDocObj.Hotel = pHotel;
		If ValueIsFilled(GuestGroup) Then
			vDocObj.GuestGroup = GuestGroup;
			If GuestGroup.ClientDoc <> Undefined Then
				vGroupDocRef = GuestGroup.ClientDoc;
			Else
				vGroupDocRef = GetFirstGroupReservationDocument(GuestGroup);
			EndIf;
			If ValueIsFilled(vGroupDocRef) Then
				vDocObj.Customer = vGroupDocRef.Customer;
				vDocObj.Contract = vGroupDocRef.Contract;
				vDocObj.ContactPerson = vGroupDocRef.ContactPerson;
				vDocObj.Agent = vGroupDocRef.Agent;
				vDocObj.AgentCommission = vGroupDocRef.AgentCommission;
				vDocObj.AgentCommissionServiceGroup = vGroupDocRef.AgentCommissionServiceGroup;
				vDocObj.AgentCommissionType = vGroupDocRef.AgentCommissionType;
				vDocObj.Discount = vGroupDocRef.Discount;
				vDocObj.DiscountConfirmationText = vGroupDocRef.DiscountConfirmationText;
				vDocObj.DiscountServiceGroup = vGroupDocRef.DiscountServiceGroup;
				vDocObj.DiscountType = vGroupDocRef.DiscountType;
			EndIf;
		EndIf;
		vDocObj.pmFillAttributesWithDefaultValues();
		vDocObj.RoomType = pRoomType;
		If ValueIsFilled(pRoom) Then
			vDocObj.Room = pRoom;
		EndIf;
		If Not ValueIsFilled(pRoomType) And ValueIsFilled(pRoom) Then
			vRoomAttrs = pRoom.GetObject().pmGetRoomAttributes(vCheckInDate);
			For Each vRoomAttrsRow In vRoomAttrs Do
				vDocObj.RoomType = vRoomAttrsRow.RoomType;
				Break;
			EndDo;
		EndIf;
		If ValueIsFilled(RoomRate) Then
			vDocObj.RoomRate = RoomRate;
		EndIf;
		If ValueIsFilled(GuestGroupStatus) Then
			vDocObj.ReservationStatus = GuestGroupStatus;
		EndIf;
		If ValueIsFilled(GuestGroupSourceOfBusiness) Then
			vDocObj.SourceOfBusiness = GuestGroupSourceOfBusiness;
		EndIf;
		If ValueIsFilled(GuestGroupMarketingCode) Then
			vDocObj.MarketingCode = GuestGroupMarketingCode;
		EndIf;
		If ValueIsFilled(GuestGroupClientType) Then
			vDocObj.ClientType = GuestGroupClientType;
		EndIf;
		vDocObj.CheckInDate = vCheckInDate;
		vDocObj.CheckOutDate = vCheckOutDate;
		vDocObj.Duration = vDocObj.pmCalculateDuration();
		vDocObj.AccommodationType = cmGetDefaultAccommodationType(vDocObj.Hotel, vDocObj.RoomType);
		If ValueIsFilled(vDocObj.AccommodationType) Then
			If vDocObj.AccommodationType.NumberOfPersons4Reservation <> 0 Then
				vDocObj.NumberOfPersons = vDocObj.AccommodationType.NumberOfPersons4Reservation;
			EndIf;
		EndIf;
		If ValueIsFilled(vDocObj.Room) And ValueIsFilled(vDocObj.Room.BoardPlace) Then
			If vDocObj.BoardPlace <> vDocObj.Room.BoardPlace Then
				vDocObj.BoardPlace = vDocObj.Room.BoardPlace;
			EndIf;
		EndIf;
		If ValueIsFilled(vDocObj.RoomQuota) And ValueIsFilled(vDocObj.RoomQuota.Company) Then
			vDocObj.Company = vDocObj.RoomQuota.Company;
		EndIf;
		If ValueIsFilled(vDocObj.RoomType) And ValueIsFilled(vDocObj.RoomType.Company) Then
			vDocObj.Company = vDocObj.RoomType.Company;
		EndIf;
		If ValueIsFilled(vDocObj.Room) And ValueIsFilled(vDocObj.Room.Company) Then
			vDocObj.Company = vDocObj.Room.Company;
		EndIf;
		If ValueIsFilled(vDocObj.RoomRate) And ValueIsFilled(vDocObj.RoomRate.Company) Then
			vDocObj.Company = vDocObj.RoomRate.Company;
		EndIf;
		If ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Company) Then
			vDocObj.Company = SessionParameters.CurrentUser.Company;
		EndIf;
		
		// Try to find accommodation template
		vAccommodationTemplate = Undefined;
		vNumberOfBeds = vDocObj.RoomType.NumberOfBedsPerRoom;
		If GuestsPerRoom = 0 Then // Single
			vAccommodationTemplates = cmGetAccommodationTemplateDetailsByGuestsQuantity(1, 0, New Array(), vDocObj.Hotel, True);
		ElsIf GuestsPerRoom = 1 Then // Double and e.t.c.
			vAccommodationTemplates = cmGetAccommodationTemplateDetailsByGuestsQuantity(vNumberOfBeds, 0, New Array(), vDocObj.Hotel, True);
		ElsIf GuestsPerRoom = 2 Then // Split
			vAccommodationTemplates = cmGetAccommodationTemplateDetailsByGuestsQuantity(1, 0, New Array(), vDocObj.Hotel, False);
		EndIf;
		For Each vAccommodationTemplatesRow In vAccommodationTemplates Do
			vCurTemplate = vAccommodationTemplatesRow.AccommodationTemplate;
			If Not GuestsPerRoom = 2 And Not vCurTemplate.IsForFolioSplit Or 
			   GuestsPerRoom = 2 And vCurTemplate.IsForFolioSplit Then
				If vCurTemplate.RoomTypes.Count() = 0 Then
					vAccommodationTemplate = vCurTemplate;
					Break;
				Else
					If vCurTemplate.RoomTypes.Find(vDocObj.RoomType) <> Undefined Then
						vAccommodationTemplate = vCurTemplate;
						Break;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
		vDocObj.AccommodationTemplate = vAccommodationTemplate;
		
		If ValueIsFilled(vAccommodationTemplate) Then
			If vAccommodationTemplate.AccommodationTypes.Count() > 0 Then
				vDocObj.AccommodationType = vAccommodationTemplate.AccommodationTypes.Get(0).AccommodationType;
			EndIf;
			vDocObj.NumberOfAdults = vAccommodationTemplate.NumberOfAdults;
			vDocObj.NumberOfTeenagers = vAccommodationTemplate.NumberOfTeenagers;
			vDocObj.NumberOfChildren = vAccommodationTemplate.NumberOfChildren;
			vDocObj.NumberOfInfants = vAccommodationTemplate.NumberOfInfants;
		ElsIf GuestsPerRoom = 2 Then 
			vDocObj.AccommodationType = cmGetAccommodationTypeBed(vDocObj.Hotel);
		EndIf;
		If GuestsPerRoom = 2 Then 
			vDocObj.NumberOfAdults = 1;
			vDocObj.IsForFolioSplit = True;
		EndIf;
		vDocObj.pmCalculateResources();
		vDocObj.pmCalculateServices( , , , , , vDocObj.IsForFolioSplit);
		vDocObj.Write(DocumentWriteMode.Posting);
		vDocObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
		
		vDocNumber = vDocObj.Number;
		
		If GuestsPerRoom <> 2 Then
			If ValueIsFilled(vAccommodationTemplate) Then
				For g = 1 To vAccommodationTemplate.AccommodationTypes.Count() - 1 Do
					vExtraAccommodationType = vAccommodationTemplate.AccommodationTypes.Get(g).AccommodationType;
					
					vExtraDocObj = vDocObj.Ref.Copy();
					vExtraDocObj.Date = vDocObj.Date + 1;
					vExtraDocObj.Number = vDocNumber;
					vExtraDocObj.AccommodationType = vExtraAccommodationType;
					vExtraDocObj.AccommodationTemplate = Undefined;
					vExtraDocObj.pmLoadDefaultChargingRules();
					vExtraDocObj.pmCalculateResources();
					vExtraDocObj.pmCalculateServices( , , , , , vExtraDocObj.IsForFolioSplit);
					vExtraDocObj.Write(DocumentWriteMode.Posting);
					vExtraDocObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				EndDo;
			EndIf;
		Else
			For g = 2 To vNumberOfBeds Do
				vExtraDocObj = vDocObj.Ref.Copy();
				vExtraDocObj.Date = vDocObj.Date;
				vExtraDocObj.SetNewNumber();
				vExtraDocObj.pmLoadDefaultChargingRules();
				vExtraDocObj.pmCalculateResources();
				vExtraDocObj.pmCalculateServices( , , , , , vExtraDocObj.IsForFolioSplit);
				vExtraDocObj.Write(DocumentWriteMode.Posting);
				vExtraDocObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			EndDo;
		EndIf;
		
		CommitTransaction();
		
    	vResult = True;
	Except
		vError = cmGetRootErrorDescription(ErrorInfo());

		If TransactionActive() Then
			RollbackTransaction();
		EndIf;

		vUM = New UserMessage();
		vUM.Text = TrimAll(TrimAll(pRoom) + " " + TrimAll(pRoomType)) + " - " + NStr("en='Error creating a room reservation!'; ru='Ошибка создания брони!'; de='Fehler beim Erstellen einer Zimmerreservierung!'") + Chars.LF + vError;
		vUM.Message();
	EndTry;
	Return vResult;
EndFunction // CreateReservationsForRoom

// -----------------------------------------------------------------------------
&AtClient
Procedure DoAllowDragEditQueryAfterAnswer(pAnswer, pExtraParams) Export
	If pAnswer = DialogReturnCode.Yes Then
		SelAllowDragEdit = Not SelAllowDragEdit;
		Items.AllowDragEdit.Check = SelAllowDragEdit;
	EndIf;
EndProcedure // DoAllowDragEditQueryAfterAnswer

// -----------------------------------------------------------------------------
&AtClient
Procedure NextPage(pCommand)
	CurrentPage = CurrentPage + 1;
	If CurrentPage > LastPage Then
		CurrentPage = 1;
	EndIf;
	FillRoomPlannerAtClient(False);
EndProcedure // NextPage

// -----------------------------------------------------------------------------
&AtClient
Procedure LastPage(pCommand)
	CurrentPage = LastPage;
	FillRoomPlannerAtClient(False);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PreviousPage(pCommand)
	CurrentPage = CurrentPage - 1;
	If CurrentPage < 1 Then
		CurrentPage = LastPage;
	EndIf;
	FillRoomPlannerAtClient(False);
EndProcedure // PreviousPage

// -----------------------------------------------------------------------------
&AtClient
Procedure FirstPage(pCommand)
	CurrentPage = 1;
	FillRoomPlannerAtClient(False);
EndProcedure // FirstPage

// -----------------------------------------------------------------------------
&AtClient
Procedure CurrentPageOnChange(pItem)
	FillRoomPlannerAtClient(False);
EndProcedure // CurrentPageOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomsPerPageOnChange(pItem)
	If RoomsPerPage < 10 Then
		RoomsPerPage = 30;
	EndIf;
	CurrentPage = 1;
	FillRoomPlannerAtClient();
EndProcedure // RoomsPerPageOnChange

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetRoomTypesForSelection(pRoomType, pRoomClass, pHotel, pRoomTypesList)
	vRoomTypesList = New ValueList;
	vRoomTypes = cmGetAllRoomTypes(pHotel, pRoomType, pRoomClass);
	For Each vRoomTypesRow In vRoomTypes Do
		vRoomTypesList.Add(vRoomTypesRow.RoomType, , ?(pRoomTypesList.FindByValue(vRoomTypesRow.RoomType) = Undefined, False, True));
	EndDo;
	Return vRoomTypesList;
EndFunction // GetRoomTypesForSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomTypesStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vRoomTypesList = GetRoomTypesForSelection(SelRoomType, SelRoomClass, SelHotel, SelRoomTypes);
	vRoomTypesList.ShowCheckItems(New NotifyDescription("SelRoomTypesEndChoice", ThisObject), NStr("en='Select room types'; ru='Отметьте типы номеров'; de='Zimmertypen auswählen'"));
EndProcedure // SelRoomTypesStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomTypesEndChoice(pRoomTypesList, pExtraParams) Export
	If pRoomTypesList <> Undefined Then
		SelRoomTypes.Clear();
		For Each vRoomTypesListItem In pRoomTypesList Do
			If vRoomTypesListItem.Check Then
				SelRoomTypes.Add(vRoomTypesListItem.Value);
			EndIf;
		EndDo;
		If SelRoomTypes.Count() = 0 Then
			Items.SelRoomTypes.InputHint = NStr("en='Show rooms of checked room types'; ru='Показать номера отмеченных типов номеров'; de='Zimmer von der markierten Zimmertypen anzeigen'");
		Else
			Items.SelRoomTypes.InputHint = "";
		EndIf;
		FillRoomPlannerAtClient();
	EndIf;
EndProcedure // SelRoomTypesEndChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomTypesClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
	SelRoomTypes.Clear();
	Items.SelRoomTypes.InputHint = NStr("en='Show rooms of checked room types'; ru='Показать номера отмеченных типов номеров'; de='Zimmer von der markierten Zimmertypen anzeigen'");
	FillRoomPlannerAtClient();
EndProcedure // SelRoomTypesClearing

// -----------------------------------------------------------------------------
&AtClient
Procedure DeleteGroupNewPeriod(pCommand)
	If LastSelectedPeriodIndex >= 0 Then
		SelectedReservationPeriods.Delete(LastSelectedPeriodIndex);
		vItem = RoomPlanner.Items.Find(LastSelectedPeriodIndex);
		If vItem <> Undefined Then
			RoomPlanner.Items.Delete(vItem);
		EndIf;
		LastSelectedPeriodIndex = -1;
	EndIf;
EndProcedure // DeleteGroupNewPeriod

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure GuestGroupDescriptionOnChangeAtServer(pGuestGroup, pDescription)
	vGroupObj = pGuestGroup.GetObject();
	vGroupObj.Description = pDescription;
	vGroupObj.Write();
EndProcedure // GuestGroupDescriptionOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupDescriptionOnChange(pItem)
	If ValueIsFilled(GuestGroup) Then
		GuestGroupDescriptionOnChangeAtServer(GuestGroup, GuestGroupDescription);
	EndIf;
EndProcedure // GuestGroupDescriptionOnChange

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure GuestGroupSourceOfBusinessOnChangeAtServer(pGuestGroup, pSourceOfBusiness)
	vGroupObj = pGuestGroup.GetObject();
	vGroupObj.SourceOfBusiness = pSourceOfBusiness;
	vGroupObj.Write();
EndProcedure // GuestGroupSourceOfBusinessOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupSourceOfBusinessOnChange(pItem)
	If ValueIsFilled(GuestGroup) Then
		GuestGroupSourceOfBusinessOnChangeAtServer(GuestGroup, GuestGroupSourceOfBusiness);
	EndIf;
EndProcedure // GuestGroupSourceOfBusinessOnChange

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure GuestGroupMarketingCodeOnChangeAtServer(pGuestGroup, pMarketingCode)
	vGroupObj = pGuestGroup.GetObject();
	vGroupObj.MarketingCode = pMarketingCode;
	vGroupObj.Write();
EndProcedure // GuestGroupMarketingCodeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupMarketingCodeOnChange(pItem)
	If ValueIsFilled(GuestGroup) Then
		GuestGroupMarketingCodeOnChangeAtServer(GuestGroup, GuestGroupMarketingCode);
	EndIf;
EndProcedure // GuestGroupMarketingCodeOnChange

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure GuestGroupClientTypeOnChangeAtServer(pGuestGroup, pClientType)
	vGroupObj = pGuestGroup.GetObject();
	vGroupObj.ClientType = pClientType;
	vGroupObj.Write();
EndProcedure // GuestGroupClientTypeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupClientTypeOnChange(pItem)
	If ValueIsFilled(GuestGroup) Then
		GuestGroupClientTypeOnChangeAtServer(GuestGroup, GuestGroupClientType);
	EndIf;
EndProcedure // GuestGroupClientTypeOnChange

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure GuestGroupTypeOnChangeAtServer(pGuestGroup, pGuestGroupType)
	vGroupObj = pGuestGroup.GetObject();
	vGroupObj.GroupType = pGuestGroupType;
	vGroupObj.Write();
EndProcedure // GuestGroupTypeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupTypeOnChange(pItem)
	If ValueIsFilled(GuestGroup) Then
		GuestGroupTypeOnChangeAtServer(GuestGroup, GuestGroupType);
	EndIf;
EndProcedure // GuestGroupTypeOnChange

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure RoomRateOnChangeAtServer(pGuestGroup, pRoomRate)
	vGroupObj = pGuestGroup.GetObject();
	vGroupObj.RoomRate = pRoomRate;
	vGroupObj.Write();
EndProcedure // RoomRateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRateOnChange(pItem)
	If ValueIsFilled(GuestGroup) Then
		RoomRateOnChangeAtServer(GuestGroup, RoomRate);
	EndIf;
EndProcedure // RoomRateOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure GuestGroupOnChangeAtServer()
	If ValueIsFilled(GuestGroup) Then
		GuestGroupDescription = TrimAll(GuestGroup.Description);
		GuestGroupStatus = GuestGroup.Status;
		GuestGroupType = GuestGroup.GroupType;
		RoomRate = GuestGroup.RoomRate;
		GuestGroupSourceOfBusiness = GuestGroup.SourceOfBusiness;
		GuestGroupMarketingCode = GuestGroup.MarketingCode;
		GuestGroupClientType = GuestGroup.ClientType;
	Else
		GuestGroupDescription = "";
		GuestGroupType = Undefined;
		GuestGroupStatus = Undefined;
		RoomRate = Undefined;
		GuestGroupSourceOfBusiness = Undefined;
		GuestGroupMarketingCode = Undefined;
		GuestGroupClientType = Undefined;
	EndIf;
EndProcedure // GuestGroupOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupOnChange(pItem)
	GuestGroupOnChangeAtServer();
EndProcedure // GuestGroupOnChange

// ---------------------------------------------------------------
&AtServer
Function GetArrayOfAllClientTypes()
	vCTTable = cmGetAllClientTypes();
	vCTArray = vCTTable.UnloadColumn("ClientType");
	Return vCTArray;
EndFunction // GetArrayOfAllClientTypes

// ---------------------------------------------------------------
&AtServer
Function GetArrayOfAllSourceOfBusiness()
	vSOBTable = cmGetAllSourcesOfBusiness();
	vSOBArray = vSOBTable.UnloadColumn("SourceOfBusiness");
	Return vSOBArray;
EndFunction // GetListOfAllSourceOfBusiness

#EndRegion
