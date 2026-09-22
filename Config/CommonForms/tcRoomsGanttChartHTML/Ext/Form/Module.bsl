#Region Variables

// ----------------------------------------------------------------------------
&AtClient
Var HTMLGantt;

#EndRegion

#Region FormEventHandlers

// ----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	SelHotel = SessionParameters.CurrentHotel;
	
	SetDefaultBasketParametrs();
	
	SelShowRoomsByRoomTypes = False;
	vShowRoomsByRoomTypes = SystemSettingsStorage.Load("tcRoomsGanttChartHTMLShowRoomsByRoomTypes", SessionParameters.CurrentUser);
	If vShowRoomsByRoomTypes <> Undefined Then
		SelShowRoomsByRoomTypes = vShowRoomsByRoomTypes;
	EndIf;
	
	SelPeriodFrom = BegOfDay(CurrentSessionDate()) - 1 * 3600 * 24;
	If Parameters.Property("SelPeriodFrom") And ValueIsFilled(Parameters.SelPeriodFrom) Then
		SelPeriodFrom = Parameters.SelPeriodFrom;
	EndIf;
	
	SelShowBookingsWithoutRooms = False;
	vShowBookingsWithoutRooms = SystemSettingsStorage.Load("tcRoomsGanttChartHTMLShowBookingsWithoutRooms", SessionParameters.CurrentUser);
	If vShowBookingsWithoutRooms <> Undefined Then
		SelShowBookingsWithoutRooms = vShowBookingsWithoutRooms;
	EndIf;
	If Parameters.Property("SelShowBookingsWithoutRooms") And TypeOf(Parameters.SelShowBookingsWithoutRooms) = Type("Boolean") Then
		SelShowBookingsWithoutRooms = Parameters.SelShowBookingsWithoutRooms;
	EndIf;
	
	SelShowPreliminary = False;
	vShowPreliminary = SystemSettingsStorage.Load("tcRoomsGanttChartHTMLShowPreliminary", SessionParameters.CurrentUser);
	If vShowPreliminary <> Undefined Then
		SelShowPreliminary = vShowPreliminary;
	EndIf;
	If Parameters.Property("SelShowPreliminary") And TypeOf(Parameters.SelShowPreliminary) = Type("Boolean") Then
		SelShowPreliminary = Parameters.SelShowPreliminary;
	EndIf;
	
	SelShowWaitingList = False;
	vShowWaitingList = SystemSettingsStorage.Load("tcRoomsGanttChartHTMLShowWaitingList", SessionParameters.CurrentUser);
	If vShowWaitingList <> Undefined Then
		SelShowWaitingList = vShowWaitingList;
	EndIf;
	If Parameters.Property("SelShowWaitingList") And TypeOf(Parameters.SelShowWaitingList) = Type("Boolean") Then
		SelShowWaitingList = Parameters.SelShowWaitingList;
	EndIf;

	DoNotAutoHide = False;
	vDoNotAutoHide = SystemSettingsStorage.Load("tcRoomsGanttChartHTMLDoNotAutoHide", SessionParameters.CurrentUser);
	If vDoNotAutoHide <> Undefined Then
		DoNotAutoHide = vDoNotAutoHide;
	EndIf;
	If Parameters.Property("DoNotAutoHide") And TypeOf(Parameters.DoNotAutoHide) = Type("Boolean") Then
		DoNotAutoHide = Parameters.DoNotAutoHide;
	EndIf;
	
	SelRoom = Catalogs.Rooms.EmptyRef();
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
	
	SelRoomClass = Catalogs.RoomTypeClasses.EmptyRef();
	If Parameters.Property("SelRoomClass") And ValueIsFilled(Parameters.SelRoomClass) Then
		SelRoomClass = Parameters.SelRoomClass;
	EndIf;
	
	SelRoomSection = Catalogs.RoomSections.EmptyRef();
	If Parameters.Property("SelRoomSection") And ValueIsFilled(Parameters.SelRoomSection) Then
		SelRoomSection = Parameters.SelRoomSection;
	EndIf;
	
	SelScale = "month";
	vSelScale = SystemSettingsStorage.Load("tcRoomsGanttChartHTMLScale", SessionParameters.CurrentUser);
	If vSelScale <> Undefined Then
		SelScale = vSelScale;
	EndIf;
	
	SelShowRoomPropertiesCodes = False;
	vShowRoomPropertiesCodes = SystemSettingsStorage.Load("tcRoomsGanttChartHTMLShowRoomPropertiesCodes", SessionParameters.CurrentUser);
	If vShowRoomPropertiesCodes <> Undefined Then
		SelShowRoomPropertiesCodes = vShowRoomPropertiesCodes;
	EndIf;
	If Parameters.Property("SelShowRoomPropertiesCodes") And TypeOf(Parameters.SelShowRoomPropertiesCodes) = Type("Boolean") Then
		SelShowRoomPropertiesCodes = Parameters.SelShowRoomPropertiesCodes;
	EndIf;
	
	HeightDocument = 22;
	vHeightDocument = SystemSettingsStorage.Load("tcRoomsGanttChartHTMLHeightDocument", SessionParameters.CurrentUser);
	If vHeightDocument <> Undefined Then
		HeightDocument = vHeightDocument;
	EndIf;
	
	SelShowAllGuests = False;
	vShowAllGuests = SystemSettingsStorage.Load("tcRoomsGanttChartHTMLShowAllGuests", SessionParameters.CurrentUser);
	If vShowAllGuests <> Undefined Then
		SelShowAllGuests = vShowAllGuests;
	EndIf;
	
	FillMonthes();
	FillAllRoomProperties();
	
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
	Items.GroupHeader.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
	
	HTML = GetCommonTemplate("RoomsGanttChartHTML").GetText();
EndProcedure // OnCreateAtServer

// ----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	If tcOnClient.IsHomePageWindow(ThisObject) Then
		vPrefix = NStr("en = 'Rooms gantt chart: ';de = 'Karte des Zimmerbestandes: ';ru = 'Карта номерного фонда: '");
		tcCommonFunctionOnClientServer.cmSetFormTitleHotelName(ThisObject, vPrefix);
	EndIf;
EndProcedure // OnOpen

// -----------------------------------------------------------------------------
&AtClient
Procedure OnClose(pExit)
	If Not pExit Then
		SaveSettingsAtServer(SelScale, SelShowRoomsByRoomTypes, SelShowBookingsWithoutRooms, SelShowPreliminary, HeightDocument, SelShowRoomPropertiesCodes, SelShowAllGuests, DoNotAutoHide, SelShowWaitingList);
	EndIf;
EndProcedure // OnClose

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If Not ValueIsFilled(pParameter) Then
		Return;
	EndIf;
	
	vUpdate = False;
	
	If pEventName = "Document.Reservation.Write" Or
		pEventName = "Document.Reservation.WriteNew" Or
		pEventName = "Document.Accommodation.Write" Or
		pEventName = "Document.Accommodation.WriteNew" Or
		pEventName = "Subsystem.Accounts.Changed" Or
		pEventName = "Document.SetRoomBlock.Write" Or
		pEventName = "Document.SetRoomBlock.WriteListRoom" Or
		pEventName = "Catalog.GuestGroups.Changed" Then
		If TypeOf(pParameter) = Type("DocumentRef.Accommodation") Or TypeOf(pParameter) = Type("DocumentRef.SetRoomBlock") Or TypeOf(pParameter) = Type("DocumentRef.Reservation") Or TypeOf(pParameter) = Type("CatalogRef.GuestGroups") Then
			vUpdate = True;
		EndIf;
	ElsIf pEventName = "Document.Payment.Write" Or
		pEventName = "Document.Return.Write" Or
		pEventName = "Document.DepositTransfer.Write" Or
		pEventName = "Document.Preauthorisation.Write" Or
		pEventName = "Document.Charge.Write" Or
		pEventName = "Document.ChargeTransfer.Write" Or
		pEventName = "Document.Storno.Write" Then
		vParentDoc = tcOnServer.cmGetAttributeByRef(pParameter, "ParentDoc");
		If TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vParentDoc) = Type("DocumentRef.SetRoomBlock") Or TypeOf(vParentDoc) = Type("DocumentRef.Reservation") Then
			vUpdate = True;
		EndIf;
	ElsIf pEventName = "Subsystem.Events.Changed" Then
		vUpdate = True;
	EndIf;
	
	If vUpdate Then
		CurrentItem = Items.Refresh;
		UpdateGanttHandler();
	EndIf;
EndProcedure // NotificationProcessing

#EndRegion

#Region FormHeaderItemsEventHandlers

// ----------------------------------------------------------------------------
&AtClient
Procedure HTMLDocumentComplete(pItem)
	HTMLGantt = GetHTMLDocument(Items.HTML.Document).gantt;
	HTMLGantt.setLanguage(GetLanguage());
	HTMLGantt.fillCartNum(0);
	HTMLGantt.closeCart();
	vColors = GetColorByHotel(SelHotel);
	For Each vColor In vColors Do
		HTMLGantt.setColor(vColor.Name, vColor.Color);
	EndDo;
	HTMLGantt.setHeightEvent(HeightDocument);
	FillRoomPlannerAtClient();
EndProcedure // HTMLDocumentComplete

// ----------------------------------------------------------------------------
&AtClient
Procedure HeightDocumentOnChange(pItem)
	HTMLGantt.setHeightEvent(HeightDocument);
EndProcedure // HeightDocumentOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure CartChoiceProcessing(pValue, pExtrParams) Export
	If pValue = Undefined Then
		Return;
	EndIf;
	
	If pExtrParams = "group" Then
		GuestGroupBasket = pValue;
	EndIf;
	
	If pExtrParams = "roomRate" Then
		RoomRateBasket = pValue;
	EndIf;
	
	If pExtrParams = "term" Then
		TermBasket = pValue;
	EndIf;
	
	If pExtrParams = "clientTypes" Then
		ClientTypesBasket = pValue;
	EndIf;
	
	If pExtrParams = "discount" Then
		DiscountBasket = pValue;
	EndIf;
	
	vCartData = GetCartData();
	HTMLGantt.fillCart(GetHTMLObj(vCartData));
EndProcedure // CartChoiceProcessing

// ----------------------------------------------------------------------------
&AtServer
Procedure SetDefaultBasketParametrs(pFul = True)
	GuestGroupBasket = Catalogs.GuestGroups.EmptyRef();
	ClientTypesBasket = Catalogs.ClientTypes.EmptyRef();
	DiscountBasket = Catalogs.DiscountTypes.EmptyRef();
	
	If pFul Then
		TermBasket = Catalogs.ServicePackages.EmptyRef();
		If ValueIsFilled(SelHotel) Then
			RoomRateBasket = SelHotel.RoomRate;
		EndIf;
	EndIf;
	
	AdultsBasket = 1;
	KidsBasket = 0;
	KidAge1Basket = 1;
	KidAge2Basket = 1;
	KidAge3Basket = 1;
	KidAge4Basket = 1;
	KidAge5Basket = 1;
	KidAge6Basket = 1;
	KidAge7Basket = 1;
	KidAge8Basket = 1;
	KidAge9Basket = 1;
	KidAge10Basket = 1;
	KidAge11Basket = 1;
	KidAge12Basket = 1;
EndProcedure // SetDefaultBasketParametrs

// ----------------------------------------------------------------------------
&AtClient
Procedure HTMLOnClick(pItem, pEventData, pStandardProcessing)
	pStandardProcessing = False;
	vElement = pEventData.Element;
	
	If vElement = Undefined Then
		vElement = pEventData.Document.activeElement;
	EndIf;
	
	HTMLGantt.hideContextmenu();
	
	If vElement.id <> "interactionButton" Then
		Return;
	Endif;
	
	vData = HTMLGantt.interactionData;
	
	If StrFind(vData.event, "cart_") > 0 Then
		vEvent = StrReplace(vData.event, "cart_", "");
		
		If vEvent = "group" Then
			OpenForm("Catalog.GuestGroups.ChoiceForm",, ThisObject, UUID,,, New NotifyDescription("CartChoiceProcessing", ThisObject, vEvent), FormWindowOpeningMode.LockOwnerWindow);
			Return;
		EndIf;
		
		If vEvent = "group_delete" Then
			GuestGroupBasket = PredefinedValue("Catalog.GuestGroups.EmptyRef");
		EndIf;
		
		If vEvent = "roomRate" Then
			OpenForm("Catalog.RoomRates.ChoiceForm",, ThisObject, UUID,,, New NotifyDescription("CartChoiceProcessing", ThisObject, vEvent), FormWindowOpeningMode.LockOwnerWindow);
			Return;
		EndIf;
		
		If vEvent = "term" Then
			vParams = New Structure("Filter", New Structure("IsMealBoardTerm", True));
			OpenForm("Catalog.ServicePackages.ChoiceForm", vParams, ThisObject, UUID, , , New NotifyDescription("CartChoiceProcessing", ThisObject, vEvent), FormWindowOpeningMode.LockOwnerWindow);
			Return;
		EndIf;
		
		If vEvent = "term_delete" Then
			TermBasket = PredefinedValue("Catalog.ServicePackages.EmptyRef");
		EndIf;
		
		If vEvent = "clientTypes" Then
			OpenForm("Catalog.ClientTypes.ChoiceForm",, ThisObject, UUID,,, New NotifyDescription("CartChoiceProcessing", ThisObject, vEvent), FormWindowOpeningMode.LockOwnerWindow);
			Return;
		EndIf;
		
		If vEvent = "clientTypes_delete" Then
			ClientTypesBasket = PredefinedValue("Catalog.ClientTypes.EmptyRef");
		EndIf;
		
		If vEvent = "discount" Then
			OpenForm("Catalog.DiscountTypes.ChoiceForm",, ThisObject, UUID,,, New NotifyDescription("CartChoiceProcessing", ThisObject, vEvent), FormWindowOpeningMode.LockOwnerWindow);
			Return;
		EndIf;
		
		If vEvent = "discount_delete" Then
			DiscountBasket = PredefinedValue("Catalog.DiscountTypes.EmptyRef");
		EndIf;
		
		If vEvent = "doFolioSplit" Then
			IsForFolioSplit = Boolean(Number(vData.data));
		EndIf;
		
		If vEvent = "adults" Then
			AdultsBasket = Number(vData.data);
		EndIf;
		
		If vEvent = "kids" Then
			KidsBasket = Number(vData.data);
		EndIf;
		
		If StrFind(vEvent, "kidAge") > 0 Then
			ThisObject[vEvent + "Basket"] = Number(vData.data);
		EndIf;
		
		If vEvent = "deleteNewZone" Then
			vDelectDocArr = New Array;
			vDelectDocArr.Add(vData.data);
			vOrderBasketRows = OrderBasket.FindRows(New Structure("UUID", vData.data));
			For Each vOrderBasketRow In vOrderBasketRows Do
				OrderBasket.Delete(vOrderBasketRow);
			EndDo;
			HTMLGantt.deleteZones(GetHTMLObj(vDelectDocArr));
		EndIf;
		
		If vEvent = "reservation" And OrderBasket.Count() > 0 Then
			vResult = False;
			If OrderBasket.Count() > 1 Then
				vResult = NewGroup();
			Else
				vResult = NewReserv();
			EndIf;
			
			If vResult Then
				OrderBasket.Clear();
				FillRoomPlannerAtClient(True);
				SetDefaultBasketParametrs(False);
			EndIf;
		EndIf;
		
		If vEvent = "сlear" Then
			vDelectDocArr = New Array;
			
			For Each vOrderBasketRow In OrderBasket Do
				vDelectDocArr.Add(vOrderBasketRow.UUID);
			EndDo;
			
			OrderBasket.Clear();
			HTMLGantt.deleteZones(GetHTMLObj(vDelectDocArr));
		EndIf;
		
		vCartData = GetCartData();
		HTMLGantt.fillCart(GetHTMLObj(vCartData));
		HTMLGantt.fillCartNum(OrderBasket.Count());
		Return;
	EndIf;
	
	If vData.event = "cart" Then
		vCartData = GetCartData();
		
		HTMLGantt.openCart();
		HTMLGantt.fillCart(GetHTMLObj(vCartData));
		HTMLGantt.closeModal();
		IsOpenOrderBasket = True;
		Return;
	EndIf;
	
	If vData.event = "closeCart" Then
		HTMLGantt.closeCart();
		IsOpenOrderBasket = False;
		Return;
	EndIf;
	
	If (vData.event = "event" Or vData.event = "event_dblclick") And StrFind(vData.data, "NZ") > 0 Then
		vCartData = GetCartData();
		
		HTMLGantt.openCart();
		HTMLGantt.fillCart(GetHTMLObj(vCartData));
		HTMLGantt.closeModal();
		IsOpenOrderBasket = True;
		Return;
	EndIf;
	
	If vData.event = "closeModal" Then
		HTMLGantt.closeModal();
		Return;
	EndIf;
	
	If vData.event = "roomInfo" Then
		vRoomStatusData = GetRoomStatus(vData.data.room);
		HTMLGantt.showContextmenu(GetHTMLObj(vRoomStatusData), vData.data.x, vData.data.y);
		Return;
	EndIf;
	
	If vData.event = "roomInfo_dblclick" Then
		vRoom = GetRoomByUUID(vData.data);
		If ValueIsFilled(vRoom) Then
			OpenForm("Catalog.Rooms.Form.tcHousekeepingItemForm", New Structure("Key", vRoom), ThisObject, UUID);
		EndIf;
		Return;
	EndIf;
	
	If vData.event = "roomStatus" Then
		ChangeRoomStatusAtServer(vData.data.room, vData.data.status);
		FillRoomPlannerAtClient(True);
		Return;
	EndIf;
	
	If vData.event = "createNewDocument" Then
		vCreateData = GetCreateData(vData.data.room, vData.data.start, vData.data.end);
		HTMLGantt.deleteNewZone();
		
		vBasketUUID = FillNewRowOrderBasket(vCreateData);
		
		If IsOpenOrderBasket Then
			vCartData = GetCartData();
			HTMLGantt.fillCart(GetHTMLObj(vCartData));
		EndIf;
		
		HTMLGantt.fillCartNum(OrderBasket.Count());
		
		If vBasketUUID <> Undefined Then
			vDelectDocArr = New Array;
			vDelectDocArr.Add(vBasketUUID);
			HTMLGantt.deleteZones(GetHTMLObj(vDelectDocArr));
			
			
			vResult = FillRoomsByBasket(vBasketUUID);
			If vResult <> Undefined Then
				HTMLGantt.updateGantt(GetHTMLObj(vResult));
			EndIf;
		EndIf;
		
		If OrderBasket.Count() > 0 And Not IsOpenOrderBasket Then
			HTMLGantt.animationBascket(OrderBasket[OrderBasket.Count() - 1].UUID);
		EndIf;
		Return;
	EndIf;
	
	If vData.event = "dragend" Then
		vChangedData = GetChangedData(vData.data.document, vData.data.start, vData.data.end, vData.data.oldRoom, vData.data.newRoom);
		
		// Check if we have to swap rooms for reservations
		vSwapRoundReservation = Undefined;
		If vChangedData.NewRoom <> vChangedData.OldRoom And 
			TypeOf(vChangedData.NewRoom) = Type("CatalogRef.Rooms") And ValueIsFilled(vChangedData.NewRoom) And 
			TypeOf(vChangedData.OldRoom) = Type("CatalogRef.Rooms") And ValueIsFilled(vChangedData.OldRoom) And 
			ValueIsFilled(vChangedData.Document) And 
			TypeOf(vChangedData.Document) = Type("DocumentRef.Reservation") Then
			vSwapRoundReservation = GetIntersectedReservation(vChangedData.NewRoom, vChangedData.OldStart, vChangedData.OldEnd);
			vExtraParams = New Structure("Doc, OldRoom, OldRoomType, OldStart, OldEnd, NewStart, NewEnd, NewRoom, NewRoomType, SwapRoundReservation", vChangedData.Document, vChangedData.OldRoom, vChangedData.OldRoomType, vChangedData.OldStart, vChangedData.OldEnd, vChangedData.NewStart, vChangedData.NewEnd, vChangedData.NewRoom, vChangedData.NewRoomType, vSwapRoundReservation);
			If ValueIsFilled(vSwapRoundReservation) Then
				vQuestion = NStr("en='Swap around room with ';
				|ru='Поменять местами номера с ';
				|de='Tauschen Zimmeren mit '") +
				TrimAll(vSwapRoundReservation) + "?";
				ShowQueryBox(New NotifyDescription("AfterReservationIntersectionCheck", ThisObject, vExtraParams), vQuestion, QuestionDialogMode.YesNoCancel, , DialogReturnCode.No);
				Return;
			ElsIf vChangedData.NewRoomType <> vChangedData.OldRoomType And Not ValueIsFilled(tcOnServer.cmGetAttributeByRef(vChangedData.Document, "RoomTypeUpgrade")) Then
				vQuestion = NStr("en='Recalculate reservation room prices according to the new room type?';
				|ru='Пересчитать цены брони согласно новому типу номера?';
				|de='Buchungspreise nach neuen Zimmertyp neu berechnen?'");
				ShowQueryBox(New NotifyDescription("AfterRoomTypeChangeBehaviourAnswer", ThisObject, vExtraParams), vQuestion, QuestionDialogMode.YesNo, , DialogReturnCode.No);
				Return;
			EndIf;
		EndIf;
		
		vMessage = "";
		vDocArr = New Array;
		vCancelEdit = ProcessItemChangeAtServer(vChangedData.Document, vChangedData.OldStart, vChangedData.OldEnd, vChangedData.OldRoom, vChangedData.OldRoomType, vChangedData.NewStart, vChangedData.NewEnd, vChangedData.NewRoom, vChangedData.NewRoomType, vDocArr, vMessage);
		If vCancelEdit Then
			HTMLGantt.cancelDrag();
		Else
			HTMLGantt.acceptDrag();
			
			CurrentItem = Items.Refresh;
			UpdateGanttHandler();
		EndIf;
		
		If Not IsBlankString(vMessage) Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage);
		EndIf;
		
		Return;
	EndIf;
	
	SelDocumentRef = GetDocumentsByUUID(New UUID(vData.data));
	
	If Not ValueIsFilled(SelDocumentRef) Then
		Return;
	EndIf;
	
	If vData.event = "group" Then
		OpenForm("Catalog.GuestGroups.ObjectForm", New Structure("Key", tcOnServer.cmGetAttributeByRef(SelDocumentRef, "GuestGroup")), ThisObject, UUID);
		Return;
	EndIf;
	
	If vData.event = "event" Then
		HTMLGantt.closeModal();
		vPeriodFrom = BegOfDay(SelPeriodFrom);
		vDays = GetDaysCount();
		If SelScale <> "day" Then
			vPeriodTo = EndOfDay(SelPeriodFrom) + (vDays - 1) * 24 * 3600;
		Else
			vPeriodTo = EndOfDay(SelPeriodFrom) + vDays * 3600;
		EndIf;
		
		If TypeOf(SelDocumentRef) = Type("DocumentRef.SetRoomBlock") Then
			OpenForm("Document.SetRoomBlock.ObjectForm", New Structure("Key", SelDocumentRef), ThisObject, UUID);
		ElsIf TypeOf(SelDocumentRef) = Type("CatalogRef.Events") Then
			OpenForm("Catalog.Events.ObjectForm", New Structure("Key", SelDocumentRef), ThisObject, UUID);
		Else
			vRecorderData = GetDataByDocument(SelDocumentRef, SelHotel, vPeriodFrom, vPeriodTo, SelShowAllGuests);
			HTMLGantt.fillModal(GetHTMLObj(vRecorderData));
			HTMLGantt.openModal(vData.element);
			HTMLGantt.closeCart();
		EndIf;
		
		Return;
	EndIf;
	
	If vData.event = "change" Or vData.event = "event_dblclick" Then
		If TypeOf(SelDocumentRef) = Type("DocumentRef.SetRoomBlock") Then
			OpenForm("Document.SetRoomBlock.ObjectForm", New Structure("Key", SelDocumentRef), ThisObject, UUID);
		ElsIf TypeOf(SelDocumentRef) = Type("DocumentRef.Accommodation") Then
			OpenForm("Document.Accommodation.ObjectForm", New Structure("Key", GetMainRoomAccommodation(SelDocumentRef)), ThisObject, UUID);
		ElsIf TypeOf(SelDocumentRef) = Type("DocumentRef.Reservation") Then
			OpenForm("Document.Reservation.ObjectForm", New Structure("Key", GetMainRoomReservation(SelDocumentRef)), ThisObject, UUID);
		EndIf;
		Return;
	EndIf;
	
	If vData.event = "folio" Then
		OpenForm("CommonForm.tcFoliosForm", New Structure("ParametersStructure", New Structure("DocRef", SelDocumentRef)), , SelDocumentRef);
		Return;
	EndIf;
	
	If vData.event = "action" Then
		If TypeOf(SelDocumentRef) = Type("DocumentRef.Reservation") Then
			CheckIn();
		ElsIf TypeOf(SelDocumentRef) = Type("DocumentRef.Accommodation") Then
			CheckOut();
		EndIf;
		Return;
	EndIf;
EndProcedure // HTMLOnClick

// -----------------------------------------------------------------------------
&AtClient
Procedure HTMLBeforeWrite(pItem, pClone, pCancel)
	pCancel = True;
EndProcedure // HTMLBeforeWrite

// -----------------------------------------------------------------------------
&AtClient
Procedure HTMLBeforePrint(pItem, pPrintDialog, pCancel)
	pCancel = True;
EndProcedure // HTMLBeforePrint

// ----------------------------------------------------------------------------
&AtClient
Procedure SpreadsheetScaleOnChange(pItem)
	FillRoomPlannerAtClient();
EndProcedure // SpreadsheetScaleOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure SelPeriodFromOnChange(pItem)
	FillRoomPlannerAtClient();
EndProcedure // SelPeriodFromOnChange

// ----------------------------------------------------------------------------
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
	SelPeriodFromOnChange(Undefined);
EndProcedure // SelMonthOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure SelShowRoomsByRoomTypesOnChange(pItem)
	FillRoomPlannerAtClient();
EndProcedure // SelShowRoomsByRoomTypesOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure SelShowAllGuestsOnChange(pItem)
	FillRoomPlannerAtClient();
EndProcedure // SelShowAllGuestsOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure SelShowPreliminaryOnChange(pItem)
	FillRoomPlannerAtClient();
EndProcedure // SelShowPreliminaryOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure SelShowWaitingListOnChange(pItem)
	FillRoomPlannerAtClient();
EndProcedure // SelShowWaitingListOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure SelRoomSectionOnChange(pItem)
	FillRoomPlannerAtClient();
EndProcedure // SelRoomSectionOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure SelRoomOnChange(pItem)
	FillRoomPlannerAtClient();
EndProcedure // SelRoomOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure SelRoomClassOnChange(pItem)
	FillRoomPlannerAtClient();
EndProcedure // SelRoomClassOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure SelRoomTypeOnChange(pItem)
	FillRoomPlannerAtClient();
EndProcedure // SelRoomTypeOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure SelShowBookingsWithoutRoomsOnChange(pItem)
	FillRoomPlannerAtClient();
EndProcedure // SelShowBookingsWithoutRoomsOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure SelShowRoomPropertiesCodesOnChange(pItem)
	FillRoomPlannerAtClient();
EndProcedure // SelShowRoomPropertiesCodesOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure SelRoomTypesStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vRoomTypesList = GetRoomTypesForSelection(SelRoomType, SelRoomClass, SelHotel, SelRoomTypes);
	vNotifyDescription = New NotifyDescription("SelRoomTypesEndChoice", ThisObject);
	vParams = New Structure("ValueList, MultipleChoice, Title", vRoomTypesList, True, NStr("en='Select room types';ru='Отметьте типы номеров';de='Zimmertypen auswählen'"));
	OpenForm("CommonForm.mcChoiceValueList", vParams, ThisObject, UUID, , , vNotifyDescription);
EndProcedure // SelRoomTypesStartChoice

// ----------------------------------------------------------------------------
&AtClient
Procedure SelRoomTypesClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
	SelRoomTypes.Clear();
	Items.SelRoomTypes.InputHint = NStr("en='Show rooms of checked room types'; ru='Показать номера отмеченных типов номеров'; de='Zimmer von der markierten Zimmertypen anzeigen'");
	FillRoomPlannerAtClient();
EndProcedure // SelRoomTypesClearing

// -----------------------------------------------------------------------------
&AtServer
Procedure SelHotelOnChangeAtServer()
	// Set hotel color          
	If Not ValueIsFilled(SelHotel) Or ValueIsFilled(SelHotel) And SelHotel.IsFolder Then
		Items.GroupHotel.BackColor = Items.FiltersGroup.BackColor;
		Items.GroupHeader.BackColor = Items.FiltersGroup.BackColor;
	Else
		Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
		Items.GroupHeader.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
	EndIf;
EndProcedure // SelHotelOnChangeAtServer

// ----------------------------------------------------------------------------
&AtClient
Procedure SelHotelOnChange(pItem)
	SelHotelOnChangeAtServer();
	FillRoomPlannerAtClient();
EndProcedure // SelHotelOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure SelHotelClearing(pItem, pStandardProcessing)
	If Not IsInRoleAtServer("RightsToChooseHotel") Then
		pStandardProcessing = False;
	EndIf;
	If Not ValueIsFilled(SelHotel) Or ValueIsFilled(SelHotel) And tcOnServer.cmGetAttributeByRef(SelHotel, "IsFolder") Then
		Items.GroupHotel.BackColor = Items.FiltersGroup.BackColor;
		Items.GroupHeader.BackColor = Items.FiltersGroup.BackColor;
	EndIf;
	FillRoomPlannerAtClient();
EndProcedure // SelHotelClearing

// -----------------------------------------------------------------------------
&AtServerNoContext
Function IsInRoleAtServer(pRoleName)
	Return IsInRole(pRoleName);
EndFunction // IsInRoleAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SelGuestStrOnChange(pItem)
	FillRoomPlannerAtClient();
EndProcedure // SelGuestStrOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CustomerOnChange(pItem)
	FillRoomPlannerAtClient();
EndProcedure // CustomerOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelCarOnChange(pItem)
	FillRoomPlannerAtClient();
EndProcedure // SelCarOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelBedsSetupOnChange(pItem)
	FillRoomPlannerAtClient();
EndProcedure // SelBedsSetupOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelGuestGroupOnChange(pItem)
	FillRoomPlannerAtClient();
EndProcedure // SelGuestGroupOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomPropertiesStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	// Mark all selected room properties
	For Each vAllRoomPropertiesItem In AllRoomProperties Do
		If SelRoomProperties.FindByValue(vAllRoomPropertiesItem.Value) = Undefined Then
			vAllRoomPropertiesItem.Check = False;
		Else
			vAllRoomPropertiesItem.Check = True;
		EndIf;
	EndDo;
	vNotifyDescription = New NotifyDescription("AfterRoomPropertiesSelection", ThisObject);
	vParams = New Structure("ValueList, MultipleChoice, Title", AllRoomProperties, True, NStr("en='Mark properties';ru='Отметьте свойства';de='Eigenschaften markieren'"));
	OpenForm("CommonForm.mcChoiceValueList", vParams, ThisObject, UUID, , , vNotifyDescription);
EndProcedure // SelRoomPropertiesStartChoice 

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomPropertiesClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
	SelRoomProperties.Clear();
	Items.SelRoomProperties.InputHint = NStr("en='Show rooms with checked properties'; ru='Показать номера с отмеченными свойствами'; de='Zimmer mit angegebenen Eigenschaften anzeigen'");
	FillRoomPlannerAtClient();
EndProcedure // SelRoomPropertiesClearing

#EndRegion

#Region FormCommandsEventHandlers

// ----------------------------------------------------------------------------
&AtClient
Procedure Refresh(pCommand)
	// APDEX
	vKeyOperation = "CommonForm.tcRoomsGanttChart.RefreshForm";
	APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);
	
	FillRoomPlannerAtClient(True);
EndProcedure // Refresh

#EndRegion

#Region Private

// ----------------------------------------------------------------------------
&AtServer
Function GetCartData()
	vCartData = New Structure;
	
	vGroup = NStr("en = 'New group'; de = 'Neue Gruppe'; ru = 'Новая группа'");
	If ValueIsFilled(GuestGroupBasket) Then
		vGroup = TrimAll(GuestGroupBasket);
	EndIf;
	vCartData.Insert("group", vGroup);
	
	vRoomRate = NStr("en = 'No tariff'; de = 'Kein Tarif'; ru = 'Без тарифа'");
	If ValueIsFilled(RoomRateBasket) Then
		vRoomRate = TrimAll(RoomRateBasket);
	EndIf;
	vCartData.Insert("roomRate", vRoomRate);
	
	vTerm = NStr("en = 'No meal board'; de = 'Keine Essensverpflegung'; ru = 'Без питания'");
	If ValueIsFilled(TermBasket) Then
		vTerm = TrimAll(TermBasket);
	EndIf;
	vCartData.Insert("term", vTerm);
	
	vClientTypes = NStr("en = 'No client type'; de = 'Ohne Clienttyp'; ru = 'Без типа клиента'");
	If ValueIsFilled(ClientTypesBasket) Then
		vClientTypes = TrimAll(ClientTypesBasket);
	EndIf;
	vCartData.Insert("clientTypes", vClientTypes);
	
	vDiscount = NStr("en = 'No discount'; de = 'Kein Rabatt'; ru = 'Без скидки'");
	If ValueIsFilled(DiscountBasket) Then
		vDiscount = TrimAll(DiscountBasket);
	EndIf;
	vCartData.Insert("discount", vDiscount);
	
	vCartData.Insert("isForFolioSplit", IsForFolioSplit);
	
	vCartData.Insert("adults", AdultsBasket);
	vCartData.Insert("kids", KidsBasket);
	
	vCartData.Insert("KidAge1", ?(KidAge1Basket <= 0, 1, KidAge1Basket));
	vCartData.Insert("KidAge2", ?(KidAge2Basket <= 0, 1, KidAge2Basket));
	vCartData.Insert("KidAge3", ?(KidAge3Basket <= 0, 1, KidAge3Basket));
	vCartData.Insert("KidAge4", ?(KidAge4Basket <= 0, 1, KidAge4Basket));
	vCartData.Insert("KidAge5", ?(KidAge5Basket <= 0, 1, KidAge5Basket));
	vCartData.Insert("KidAge6", ?(KidAge6Basket <= 0, 1, KidAge6Basket));
	vCartData.Insert("KidAge7", ?(KidAge7Basket <= 0, 1, KidAge7Basket));
	vCartData.Insert("KidAge8", ?(KidAge8Basket <= 0, 1, KidAge8Basket));
	vCartData.Insert("KidAge9", ?(KidAge9Basket <= 0, 1, KidAge9Basket));
	vCartData.Insert("KidAge10", ?(KidAge10Basket <= 0, 1, KidAge10Basket));
	vCartData.Insert("KidAge11", ?(KidAge11Basket <= 0, 1, KidAge11Basket));
	vCartData.Insert("KidAge12", ?(KidAge12Basket <= 0, 1, KidAge12Basket));
	
	vReservations = New Array;
	For Each vReservationRow In OrderBasket Do
		vReservation = New Structure;
		
		vRowDescription = "";
		If Year(vReservationRow.CheckInDate) <> Year(vReservationRow.CheckOutDate) Then
			vRowDescription = TrimAll(vReservationRow.Room) + " " + TrimAll(vReservationRow.RoomType. Code) + ", " + Format(vReservationRow.CheckInDate, "DF='dd MMM yyyy'") + " - " + Format(vReservationRow.CheckOutDate, "DF='dd MMM yyyy'") + ", " + Format(vReservationRow.Adults, "NFD=0; NZ=; NG=") + "/" + Format(vReservationRow.Kids, "NFD=0; NZ=; NG=");
		ElsIf Month(vReservationRow.CheckInDate) <> Month(vReservationRow.CheckOutDate) Then
			vRowDescription = TrimAll(vReservationRow.Room) + " " + TrimAll(vReservationRow.RoomType. Code) + ", " + Format(vReservationRow.CheckInDate, "DF='dd MMM'") + " - " + Format(vReservationRow.CheckOutDate, "DF='dd MMM yyyy'") + ", " + Format(vReservationRow.Adults, "NFD=0; NZ=; NG=") + "/" + Format(vReservationRow.Kids, "NFD=0; NZ=; NG=");
		Else
			vRowDescription = TrimAll(vReservationRow.Room) + " " + TrimAll(vReservationRow.RoomType. Code) + ", " + Format(vReservationRow.CheckInDate, "DF='dd'") + " - " + Format(vReservationRow.CheckOutDate, "DF='dd MMM yyyy'") + ", " + Format(vReservationRow.Adults, "NFD=0; NZ=; NG=") + "/" + Format(vReservationRow.Kids, "NFD=0; NZ=; NG=");
		EndIf;
		
		vReservation.Insert("reservation", vRowDescription);
		vReservation.Insert("total", cmFormatSum(vReservationRow.Amount, vReservationRow.Currency, "NZ=0"));
		vReservation.Insert("id", vReservationRow.UUID);
		vReservations.Add(vReservation);
	EndDo;
	
	vCartData.Insert("reservations", vReservations);
	
	vCartData.Insert("roomsTotal", vReservations.Count());
	vCartData.Insert("adultsTotal", OrderBasket.Total("Adults"));
	vCartData.Insert("childrenTotal", OrderBasket.Total("Kids"));
	vCartData.Insert("sumTotal", cmFormatSum(OrderBasket.Total("Amount"), SelHotel.FolioCurrency, "NZ=0"));
	
	Return vCartData;
EndFunction // GetCartData

// ----------------------------------------------------------------------------
&AtClient
Function GetHTMLDocument(pDocument)
	vDoc = pDocument.parentWindow;
	If vDoc = Undefined Then
		vDoc = pDocument.defaultView;
	EndIf;
	Return vDoc;
EndFunction // GetHTMLDocument

// ----------------------------------------------------------------------------
&AtClient
Procedure FillRoomPlannerAtClient(pUpdate = False)
	NumberRoomEmpty = 1;
	RecordersNumber = 1;
	
	If Not ValueIsFilled(SelHotel) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Hotel is not selected!';ru='Не выбрана гостиница!';de='Hotel wird nicht gewählt!'"));
		Return;
	EndIf;
	
	vPeriodFrom = BegOfDay(SelPeriodFrom);
	
	vDays = GetDaysCount();
	If SelScale <> "day" Then
		vPeriodTo = EndOfDay(SelPeriodFrom) + (vDays - 1) * 24 * 3600;
	Else
		vPeriodTo = EndOfDay(SelPeriodFrom) + vDays * 3600;
	EndIf;
	
	HTMLGantt.closeModal();
	
	vOrderBasket = GetOrderBasket();
	
	vJson = FillRooms(vPeriodFrom, vPeriodTo, vDays, SelHotel, SelGuestGroup, SelRoom, SelRoomClass, SelRoomSection, SelRoomTypes, SelRoomType, SelGuestStr, SelScale, SelShowRoomsByRoomTypes, SelShowAllGuests, SelShowPreliminary, SelShowBookingsWithoutRooms, SelCustomer, SelCar, SelBedsSetup, SelRoomProperties, SelShowRoomPropertiesCodes, NumberRoomEmpty, RecordersNumber, vOrderBasket, SelShowWaitingList);
	
	#If Not WebClient Then
		vResult = JsonToMap(vJson);
	#Else
		vResult = JsonToMapAtServer(vJson);
	#EndIf
	
	vObj = GetHTMLObj(vResult);
	
	If pUpdate Then
		HTMLGantt.deleteAllZones();
		HTMLGantt.updateGantt(vObj);
	Else
		HTMLGantt.clearGantt();
		HTMLGantt.useGantt(vObj);
	EndIf;
	
	BuildSettingsCollapsedTitle();
	
	If Not DoNotAutoHide Then
		If Not Items.SettingsGroup.Hidden() Then
			Items.SettingsGroup.Hide();
		EndIf;
	EndIf;
EndProcedure // FillRoomPlannerAtClient

// ----------------------------------------------------------------------------
&AtServer
Function GetOrderBasket()
	vOrderBasketMap = New Map;
	
	vOrderBasketCopy = OrderBasket.Unload(, "Room");
	vOrderBasketCopy.GroupBy("Room");
	
	For Each vRoomRow In vOrderBasketCopy Do
		vOrderBasketArr = New Array;
		vOrderBasketRows = OrderBasket.FindRows(New Structure("Room", vRoomRow.Room));
		For Each vOrderBasketRow In vOrderBasketRows Do
			vOrderBasket = New Map;
			
			vOrderBasket.Insert("RoomRate", vOrderBasketRow.RoomRate);
			vOrderBasket.Insert("Term", vOrderBasketRow.Term);
			vOrderBasket.Insert("ClientTypes", vOrderBasketRow.ClientTypes);
			vOrderBasket.Insert("Discount", vOrderBasketRow.Discount);
			vOrderBasket.Insert("Adults", vOrderBasketRow.Adults);
			vOrderBasket.Insert("Kids", vOrderBasketRow.Kids);
			vOrderBasket.Insert("KidAge1", vOrderBasketRow.KidAge1);
			vOrderBasket.Insert("KidAge2", vOrderBasketRow.KidAge2);
			vOrderBasket.Insert("KidAge3", vOrderBasketRow.KidAge3);
			vOrderBasket.Insert("KidAge4", vOrderBasketRow.KidAge4);
			vOrderBasket.Insert("KidAge5", vOrderBasketRow.KidAge5);
			vOrderBasket.Insert("KidAge6", vOrderBasketRow.KidAge6);
			vOrderBasket.Insert("KidAge7", vOrderBasketRow.KidAge7);
			vOrderBasket.Insert("KidAge8", vOrderBasketRow.KidAge8);
			vOrderBasket.Insert("KidAge9", vOrderBasketRow.KidAge9);
			vOrderBasket.Insert("KidAge10", vOrderBasketRow.KidAge10);
			vOrderBasket.Insert("KidAge11", vOrderBasketRow.KidAge11);
			vOrderBasket.Insert("KidAge12", vOrderBasketRow.KidAge12);
			vOrderBasket.Insert("CheckInDate", vOrderBasketRow.CheckInDate);
			vOrderBasket.Insert("CheckOutDate", vOrderBasketRow.CheckOutDate);
			vOrderBasket.Insert("Duration", vOrderBasketRow.Duration);
			vOrderBasket.Insert("Room", vOrderBasketRow.Room);
			vOrderBasket.Insert("RoomType", vOrderBasketRow.RoomType);
			vOrderBasket.Insert("Amount", vOrderBasketRow.Amount);
			vOrderBasket.Insert("AccommodationTemplate", vOrderBasketRow.AccommodationTemplate);
			vOrderBasket.Insert("Currency", vOrderBasketRow.Currency);
			vOrderBasket.Insert("UUID", vOrderBasketRow.UUID);
			
			vOrderBasketArr.Add(vOrderBasket);
		EndDo;
		
		vOrderBasketMap.Insert(TrimAll(vRoomRow.Room.UUID()), vOrderBasketArr);
	EndDo;
	
	Return vOrderBasketMap;
EndFunction // GetOrderBasket

// ----------------------------------------------------------------------------
&AtClient
Function GetHTMLObj(pData)
	vObj = Undefined;
	If TypeOf(pData) = Type("Structure") Then
		vObj = HTMLGantt.createObj();
		For Each vItem In pData Do
			If TypeOf(vItem.Value) = Type("Structure") Or TypeOf(vItem.Value) = Type("Array") Then
				HTMLGantt.setToObj(vObj, vItem.Key, GetHTMLObj(vItem.Value));
			Else
				HTMLGantt.setToObj(vObj, vItem.Key, vItem.Value);
			EndIf;
		EndDo;
	ElsIf TypeOf(pData) = Type("Array") Then
		vObj = HTMLGantt.createArr();
		For Each vItem In pData Do
			If TypeOf(vItem) = Type("Structure") Or TypeOf(vItem) = Type("Array") Then
				HTMLGantt.setToArr(vObj, GetHTMLObj(vItem));
			Else
				HTMLGantt.setToArr(vObj, vItem);
			EndIf;
		EndDo;
	EndIf;
	Return vObj;
EndFunction // getHTMLObj

// -----------------------------------------------------------------------------
&AtClient
Procedure UpdateGanttHandler() Export 
	If IsInputAvailable() Then
		FillRoomPlannerAtClient(True);
	Else
		AttachIdleHandler("UpdateGanttHandler", 1, True);
	EndIf;
EndProcedure // UpdateGanttHandler

// ----------------------------------------------------------------------------
&AtClient
Procedure BuildSettingsCollapsedTitle()
	vTitle = NStr("en='From ';ru='С ';de='Von '") + Format(SelPeriodFrom, "DF=dd.MM.yyyy") +
	NStr("en=' for ';ru=' на ';de=' für '") + GetPeriodDurationPresentation(SelScale) +
	?(ValueIsFilled(SelRoom), NStr("en=' by ';ru=' по ';de=' auf dem '") + TrimAll(tcOnServer.cmGetAttributeByRef(SelRoom, "Description")), "") +
	?(ValueIsFilled(SelRoomType), NStr("en=' by ';ru=' по ';de=' auf dem '") + TrimAll(tcOnServer.cmGetAttributeByRef(SelRoomType, "Description")), "") +
	?(SelRoomTypes.Count() > 0, NStr("en=' by ';ru=' по ';de=' auf dem '") + TrimAll(SelRoomTypes), "") +
	?(ValueIsFilled(SelRoomClass), NStr("en=' by ';ru=' по ';de=' auf dem '") + TrimAll(tcOnServer.cmGetAttributeByRef(SelRoomClass, "Description")), "") +
	?(ValueIsFilled(SelRoomSection), NStr("en=' by ';ru=' по ';de=' auf dem '") + TrimAll(tcOnServer.cmGetAttributeByRef(SelRoomSection, "Description")), "");
	Items.SettingsGroup.Title = vTitle;
EndProcedure // BuildSettingsCollapsedTitle

// ----------------------------------------------------------------------------
&AtClient
Function GetPeriodDurationPresentation(pScale)
	If pScale = "day" Then
		Return NStr("en='1 day';ru='1 день';de='1 Tag'");
	ElsIf pScale = "2weeks" Then
		Return NStr("en='2 weeks';ru='2 недели';de='2 Wochen'");
	ElsIf pScale = "month" Then
		Return NStr("en='1 month';ru='1 месяц';de='1 Monat'");
	ElsIf pScale = "2month" Then
		Return NStr("en='2 month';ru='2 месяц';de='2 Monate'");
	EndIf;
	Return "";
EndFunction // GetPeriodDurationPresentation

// ----------------------------------------------------------------------------
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

// ----------------------------------------------------------------------------
&AtClient
Function GetDaysCount()
	If SelScale = "2month" Then
		Return 63;
	ElsIf SelScale = "month" Then
		Return 32;
	ElsIf SelScale = "2weeks" Then
		Return 15;
	ElsIf SelScale = "day" Then
		Return 24;
	EndIf;
EndFunction // GetDaysCount

// ----------------------------------------------------------------------------
&AtClient
Procedure CheckIn()
	If Not ValueIsFilled(SelDocumentRef) Then
		Return;
	EndIf;
	vHotel = tcOnServer.cmGetAttributeByRef(SelDocumentRef, "Hotel");
	vHotelAccountingDate = '00010101';
	If ValueIsFilled(vHotel) Then
		vHotelAccountingDate = tcOnServer.cmGetAttributeByRef(vHotel, "AccountingDate");
	EndIf;
	If Not ValueIsFilled(vHotelAccountingDate) Then
		vHotelAccountingDate = BegOfDay(CurrentDate());
	EndIf;
	vResult = CheckInAtServer(SelDocumentRef);
	If ValueIsFilled(vResult) Then
		If vResult = "DoQueryBox" Then
			ShowQueryBox(New NotifyDescription("CheckInEnd", ThisObject), NStr("en='You are checking in by inactive reservation! Continue?';ru='Селите по не активной брони! Продолжить?';de='Sie bringen nicht nach einer aktiven Reservierung unter! Fortfahren?'"), QuestionDialogMode.YesNo, , DialogReturnCode.No);
		ElsIf TypeOf(vResult) = Type("ValueList") Then
			vQuestionWasAsked = False;
			vSelResList = New ValueList;
			vErrList = New ValueList;
			vSkip = False;
			For Each vItem In vResult Do
				vCheckInDate = tcOnServer.cmGetAttributeByRef(vItem.Value, "CheckInDate");
				If vResult.IndexOf(vItem) = 0 Or vErrList.Count() > 0 Then
					If vHotelAccountingDate <> BegOfDay(vCheckInDate) Then
						vErrList.Add(vItem.Value);
						Continue;
					EndIf;
				EndIf;
				vSelResList.Add(vItem.Value);
			EndDo;
			If vErrList.Count() > 0 Then
				vQueryText = NStr("en='There are reservations with check-in date " + Format(vCheckInDate, "DF=dd.MM.yyyy") + ". This date differs from todays date " + Format(vHotelAccountingDate, "DF=dd.MM.yyyy") + "! Skip such reservations?';
				                  |de='Sie haben Reservierungen mit Check-in-Datum " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " ausgewählt. Dieses Datum weicht vom heutigen Datum ab " + Format(vHotelAccountingDate, "DF=dd.MM.yyyy") + "! Solche Reservierungen überspringen?';
				                  |ru='Выбрали документы с датой заезда " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " отличающейся от текущей даты " + Format(vHotelAccountingDate, "DF=dd.MM.yyyy") + "! Отменить поселение по такой брони?'");
				ShowQueryBox(New NotifyDescription("AfterAnswer", ThisObject, New Structure("vSelResList, vErrList", vSelResList, vErrList)), vQueryText, QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
			Else 
				CheckInEndPart(vSelResList, vErrList);
			EndIf;
		ElsIf TypeOf(vResult)=Type("Structure") Then
			// APDEX
			vKeyOperation = "Document.Accommodation.Form.tcDocumentForm.OpenForm";
			APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);
			
			// Open new accommodation and fill group table from the given list
			OpenForm("Document.Accommodation.Form.tcDocumentForm", New Structure("GuestsToCheckInList, OneGuestMode", vResult.ValueList.Copy(), False), ThisObject);
		Else
			ShowMessageBox(Undefined,vResult);
		EndIf;
	EndIf;
EndProcedure // CheckIn

// ----------------------------------------------------------------------------
&AtClient
Procedure CheckInEnd(pQuestionResult, pAdditionalParameters) Export
	If pQuestionResult = DialogReturnCode.No Then
		Return;
	Else
		vResult = CheckInAtServer(SelDocumentRef, True);
		If ValueIsFilled(vResult) Then
			If TypeOf(vResult) = Type("ValueList") Then
				vHotel = tcOnServer.cmGetAttributeByRef(SelDocumentRef, "Hotel");
				vHotelAccountingDate = '00010101';
				If ValueIsFilled(vHotel) Then
					vHotelAccountingDate =  tcOnServer.cmGetAttributeByRef(vHotel, "AccountingDate");
				EndIf;
				If Not ValueIsFilled(vHotelAccountingDate) Then
					vHotelAccountingDate = BegOfDay(CurrentDate());
				EndIf;
				vQuestionWasAsked = False;
				vSelResList = New ValueList;
				vErrList = New ValueList;
				vSkip = False;
				For Each vItem In vResult Do
					vCheckInDate = tcOnServer.cmGetAttributeByRef(vItem.Value, "CheckInDate");
					If vResult.IndexOf(vItem) = 0 Or vErrList.Count() > 0 Then
						If vHotelAccountingDate <> BegOfDay(vCheckInDate) Then
							vErrList.Add(vItem.Value);
							Continue;
						EndIf;
					EndIf;
					vSelResList.Add(vItem.Value);
				EndDo;
				If vErrList.Count()>0 Then
					vQueryText = NStr("en='There are reservations with check-in date " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " in the list of reservations selected. This date differs from todays date " + Format(vHotelAccountingDate, "DF=dd.MM.yyyy") + "! Skip such reservations?';
					|de='Sie haben Reservierungen mit Check-in-Datum " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " ausgewählt. Dieses Datum weicht vom heutigen Datum ab " + Format(vHotelAccountingDate, "DF=dd.MM.yyyy") + "! Solche Reservierungen überspringen?';
					|ru='В выбранном списке брони есть документы с датой заезда " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " отличающейся от текущей даты " + Format(vHotelAccountingDate, "DF=dd.MM.yyyy") + "! Отменить поселение по такой брони?'");
					ShowQueryBox(New NotifyDescription("AfterAnswer", ThisObject, New Structure("vSelResList,vErrList",vSelResList,vErrList)), vQueryText, QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
				Else 
					CheckInEndPart(vSelResList,vErrList);
				EndIf;
			ElsIf TypeOf(vResult)=Type("Structure") Then
				// APDEX
				vKeyOperation = "Document.Accommodation.Form.tcDocumentForm.OpenForm";
				APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);
				
				// Open new accommodation and fill group table from the given list
				OpenForm("Document.Accommodation.Form.tcDocumentForm", New Structure("GuestsToCheckInList, OneGuestMode", vResult.ValueList.Copy(), False), ThisObject);
			Else
				ShowMessageBox(Undefined, vResult);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // CheckInEnd

// ----------------------------------------------------------------------------
&AtClient
Procedure AfterAnswer(pQuestionResult, pAdditionalParameters) Export
	vSelResList = pAdditionalParameters.vSelResList;
	vErrList = pAdditionalParameters.vErrList;
	If pQuestionResult = DialogReturnCode.No Then
		For Each int In vErrList Do
			vSelResList.Add(int.value)
		EndDo;
	EndIf;
	CheckInEndPart(vSelResList);
EndProcedure // AfterAnswer

// ----------------------------------------------------------------------------
&AtClient
Procedure CheckInEndPart(vSelResList, vErrList = Undefined)
	If Not vErrList = Undefined Then
		For Each Int In vErrList Do
			vSelResList.Add(Int.value)	
		EndDo;
	EndIf;
	
	// Check current reservation list deposits
	CheckReservationsDeposits(vSelResList);
	vResult = CheckInAtServer(SelDocumentRef, true, vSelResList);
	If ValueIsFilled(vResult) Then
		If TypeOf(vResult)=Type("Structure") Then
			// APDEX
			vKeyOperation = "Document.Accommodation.Form.tcDocumentForm.OpenForm";
			APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);
			
			// Open new accommodation and fill group table from the given list
			OpenForm("Document.Accommodation.Form.tcDocumentForm", New Structure("GuestsToCheckInList, OneGuestMode", vResult.ValueList.Copy(), False), ThisObject);
		Else
			ShowMessageBox(Undefined, vResult);
		EndIf;
	EndIf;
EndProcedure // CheckInEndPart

// ----------------------------------------------------------------------------
&AtClient
Procedure CheckOut()
	// Check document form mode
	If SelShowAllGuests Then
		OpenForm("CommonForm.tcChangeRoomWizard", New Structure("DocRef, OperationType", SelDocumentRef, 2), ThisObject);
		Return;
	EndIf;
	
	// Build list of documents to be checked out
	AccList = New ValueList;
	AccList.Add(SelDocumentRef);
	If Not SelShowAllGuests Then
		AddOneRoomAccommodations(AccList, SelDocumentRef, True);
	EndIf;
	
	vCheckOutDate = tcOnServer.cmGetAttributeByRef(SelDocumentRef, "CheckOutDate");
	vCheckInDate = tcOnServer.cmGetAttributeByRef(SelDocumentRef, "CheckInDate");
	
	// Give warning if current date is less then expected check-out date
	If BegOfDay(vCheckOutDate) > BegOfDay(CurrentDate()) Then
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='Expected check-out date " + Format(vCheckOutDate, "DF=dd.MM.yyyy") + " is in the future!';
		|de='Expected check-out date " + Format(vCheckOutDate, "DF=dd.MM.yyyy") + " is in the future!';
		|ru='Дата планируемого выезда " + Format(vCheckOutDate, "DF=dd.MM.yyyy") + " в будущем!'"));
	EndIf;
	
	// Get check-out date
	CheckOutDateTime = '00010101';
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToCheckOutOnExpectedCheckOutTime") Then
		GetCheckOutDate(vCheckInDate, vCheckOutDate);
	Else
		CheckOutDateTime = tcOnServer.cmGetAttributeByRef(SelDocumentRef, "CheckOutDate");
	EndIf;
	AttachIdleHandler("CheckIfCheckOutDateTimeIsFilled", 1, False);
EndProcedure // CheckOut

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
	vDescription = NStr("en = 'Check-out time:';de = 'Abreisezeit:';ru = 'Время выселения:'");
	vIsProtected = False;
	vDateIsProtected = False;
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToEditCheckOutDateTime") Then
		vIsProtected = True;
	Else
		If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToSetCheckOutDateInThePast") Then
			vDateIsProtected = True;
		EndIf;
	EndIf;
	vOnCloseNotifyDescription = New NotifyDescription("GetCheckOutDateAfterUserInput", ThisObject, New Structure("CheckInDate, CheckOutDate", pCheckInDate, pCheckOutDate));
	vParams = New Structure("FillingValues", New Structure("Date, Time, Description, IsProtected, DateIsProtected", vDate, vTime, vDescription, vIsProtected, vDateIsProtected));
	OpenForm("CommonForm.tcInputDateTime", vParams, ThisObject, , , , vOnCloseNotifyDescription, FormWindowOpeningMode.LockOwnerWindow);
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
			ShowMessageBox(, NStr("ru='Нет прав выселения в прошлом!';
			|de='Sie haben ein abreise Datum und Zeit angegeben, das in der Vergangenheit liegt. Sie sind berechtigt, eine Räumung nur am aktuellen oder künftigen Datum vorzunehmen!';
			|en='You have entered check-out date in the past. You have rights to do check-out by current or future dates only!'"));
			Return;
		EndIf;
	EndIf;
	CheckOutDateTime = pCheckOutDateTime;
EndProcedure // GetCheckOutDateAfterUserInput

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckIfCheckOutDateTimeIsFilled()
	If ValueIsFilled(CheckOutDateTime) Then
		DetachIdleHandler("CheckIfCheckOutDateTimeIsFilled");
		// Check balances for selected accommodations
		vResultMessage = "";
		vResult = CheckAccommodationsBalances(AccList, vResultMessage);
		If Not IsBlankString(vResultMessage) Then
			tcCommonFunctionOnClientServer.UserMessage(vResultMessage);
			tcOnServer.cmWriteLogEventAtServer(NStr("en='Accommodation.CheckBalances';ru='Размещение.ПроверкаБаланса';de='Accommodation.CheckBalances'"), Undefined, "Documents.Folio", , vResultMessage);
			If Not vResult Then
				Return;
			EndIf;
		EndIf;
		// Check if advances were cleared
		vResultMessage = "";
		vResult = CheckIfAdvancesWereCleared(AccList, vResultMessage);
		If Not IsBlankString(vResultMessage) Then
			tcCommonFunctionOnClientServer.UserMessage(vResultMessage);
			tcOnServer.cmWriteLogEventAtServer(NStr("en='Accommodation.CheckIfAdvancesWereCleared';ru='Размещение.ПроверкаЗачетаАванса';de='Accommodation.CheckIfAdvancesWereCleared'"), Undefined, "Documents.Folio", , vResultMessage);
			If Not vResult Then
				Return;
			EndIf;
		EndIf;
		// Check future reservations
		vMessage = CheckFutureReservationsAtServer(SelDocumentRef, CheckOutDateTime);
		If Not IsBlankString(vMessage) Then
			tcCommonFunctionOnClientServer.UserMessage(vMessage);
		EndIf;
		// Do check-out
		vResult = CheckOutAtServer(SelDocumentRef, AccList, CheckOutDateTime, False);
		If ValueIsFilled(vResult) Then
			If vResult = "SendNotifications" Then
				// Send notification to all open forms
				Notify("Subsystem.Accounts.Changed", SelDocumentRef, ThisObject);
				Notify("Document.ResourceReservation.Write", , ThisObject);
				// Notify that accommodation is changed
				Notify("Document.Accommodation.Write", SelDocumentRef, ThisObject);
			Else
				ShowMessageBox(, vResult);
			EndIf;
		Else
			// Notify that accommodation is changed
			Notify("Document.Accommodation.Write", SelDocumentRef, ThisObject);
			// Check if we have to print customer folios automatically
			If tcOnServer.cmGetAttributeByRef(SelHotel, "PrintCustomerFolioAfterCheckout") Then
				PrintCustomerFolios();
			EndIf;
		EndIf;
	Else
		Return;
	EndIf;
EndProcedure // CheckIfCheckOutDateTimeIsFilled

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
		vDocArr = New Array;
		vCancelEdit = ProcessItemChangeAtServer(pExtraParams.Doc, pExtraParams.OldStart, pExtraParams.OldEnd, pExtraParams.OldRoom, pExtraParams.OldRoomType, pExtraParams.NewStart, pExtraParams.NewEnd, pExtraParams.NewRoom, pExtraParams.NewRoomType, vDocArr, vMessage, pExtraParams.SwapRoundReservation);
		If vCancelEdit Then
			HTMLGantt.cancelDrag();
		Else
			HTMLGantt.acceptDrag();
			
			CurrentItem = Items.Refresh;
			UpdateGanttHandler();
		EndIf;
		
		If Not IsBlankString(vMessage) Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage);
		EndIf;
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
	vDocArr = New Array;
	vCancelEdit = ProcessItemChangeAtServer(pExtraParams.Doc, pExtraParams.OldStart, pExtraParams.OldEnd, pExtraParams.OldRoom, pExtraParams.OldRoomType, pExtraParams.NewStart, pExtraParams.NewEnd, pExtraParams.NewRoom, pExtraParams.NewRoomType, vDocArr, vMessage, pExtraParams.SwapRoundReservation, vRecalculatePrices);
	If vCancelEdit Then
		HTMLGantt.cancelDrag();
	Else
		HTMLGantt.acceptDrag();
		
		CurrentItem = Items.Refresh;
		UpdateGanttHandler();
	EndIf;
	
	If Not IsBlankString(vMessage) Then
		tcCommonFunctionOnClientServer.TextMessage(vMessage);
	EndIf;
EndProcedure // AfterReservationIntersectionCheck

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterRoomPropertiesSelection(pList, pExtraParams) Export
	If pList <> Undefined Then
		SelRoomProperties.Clear();
		For Each vListItem In pList Do
			If vListItem.Check Then
				SelRoomProperties.Add(vListItem.Value);
			EndIf;
		EndDo;
		If SelRoomProperties.Count() = 0 Then
			Items.SelRoomProperties.InputHint = NStr("en='Show rooms with checked properties'; ru='Показать номера с отмеченными свойствами'; de='Zimmer mit angegebenen Eigenschaften anzeigen'");
		Else
			Items.SelRoomProperties.InputHint = "";
		EndIf;
		FillRoomPlannerAtClient();
	EndIf;
EndProcedure // AfterRoomPropertiesSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintCustomerFolios()
	vLang = tcOnServer.cmGetSessionParametersAttribute("CurrentLanguage");
	If ValueIsFilled(vLang) Then
		vLangCode = tcOnServer.cmGetAttributeByRef(vLang, "Code");
		vPrintFormName = "AfterCheckoutFolioPrintForm" + Title(TrimAll(vLangCode));
		vPrintFormTypeRef = tcOnServer.cmGetAttributeByRef(SelHotel, vPrintFormName);
		If ValueIsFilled(vPrintFormTypeRef) Then
			// Get list of customer folios for this room
			vFoliosList = GetListOfCustomerFolios(SelDocumentRef);
			If vFoliosList.Count() > 0 Then
				vParams = New Structure("InputParameter, ObjectPrintingForm, Folios", vFoliosList.Get(0).Value, vPrintFormTypeRef, vFoliosList);
				OpenForm("Document.Folio.Form.tcFolioPrintForm", vParams, ThisObject, new UUID);
			EndIf;
		Else
			tcCommonFunctionOnClientServer.UserMessage(NStr("en='Print form is not specified for language ';ru='Не указана печатная форма для языка ';de='Druckformular ist nicht für die Sprache angegeben '") + Upper(vLangCode) + "!");
		EndIf;
	EndIf;
EndProcedure // PrintCustomerFolios

// ----------------------------------------------------------------------------
&AtServer
Procedure FillMonthes()
	vCurMonth = Month(CurrentSessionDate());
	vCurYear = Year(CurrentSessionDate());
	vNextYearStr = Format(vCurYear + 1, "ND=4;NFD=;NG=");
	Items.SelMonth.ChoiceList.Clear();
	Items.SelMonth.ChoiceList.Add(0, NStr("en='Today';de='Heute';ru='Сегодня'"));
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
EndProcedure // FillMonthes

// -----------------------------------------------------------------------------
&AtServer
Procedure AddOneRoomAccommodations(pAccList, pDocRef, pInhouseOnly = False)
	vOneRoomDocs = cmGetOneRoomAccommodations(pDocRef.Room, pDocRef.GuestGroup, pDocRef.CheckInDate, pDocRef.CheckOutDate);
	For Each vOneRoomDocsRow In vOneRoomDocs Do
		vDocRef = vOneRoomDocsRow.Ref;
		If ValueIsFilled(vDocRef) And TypeOf(vDocRef) = Type("DocumentRef.Accommodation") Then
			If pInhouseOnly Then
				If ValueIsFilled(vDocRef.AccommodationStatus) And 
					Not vDocRef.AccommodationStatus.IsInHouse Then
					Continue;
				EndIf;
			EndIf;
			If pAccList.FindByValue(vDocRef) = Undefined Then
				pAccList.Add(vDocRef);
			EndIf;
		EndIf;
	EndDo;
EndProcedure // AddOneRoomAccommodations

// -----------------------------------------------------------------------------
&AtServer
Function CheckAccommodationsBalances(pAccList, rResultMessage)
	vResult = True;
	rResultMessage = "";
	vFolios = cmGetDocumentFoliosWithDebts(pAccList);
	If vFolios.Count() > 0 Then
		vThereAreDebts = False;
		vThereAreDeposits = False;
		vDebtsMessage = NStr("en='Folios: ';ru='По лицевым счетам: ';de='Nach Personenkonten: '") + Chars.LF;
		For Each vFoliosRow In vFolios Do
			vFolioRef = vFoliosRow.Folio;
			If vFoliosRow.SumBalance < 0 Then
				vThereAreDeposits = True;
			ElsIf vFoliosRow.SumBalance > 0 Then
				vThereAreDebts = True;
			EndIf;
			If ValueIsFilled(vFolioRef) Then
				vIsCustomerDebt = False;
				If ValueIsFilled(vFolioRef.Customer) And Not vFolioRef.Customer.IsIndividual Then
					vIsCustomerDebt = True;
				EndIf;
				If vIsCustomerDebt Then
					If Not cmCheckUserPermissions("HavePermissionToCheckOutAccommodationsWithCustomerDebts") Then
						vResult = False;
					EndIf;
				Else
					If Not cmCheckUserPermissions("HavePermissionToCheckOutAccommodationsWithClientDebts") Then
						vResult = False;
					EndIf;
				EndIf;
				vDebtsMessage = vDebtsMessage + Chars.LF + "#" + TrimAll(vFolioRef.Number) + " " + 
				TrimAll(vFolioRef.Client) + NStr("ru = ', номер ';en = ', room ';de = ', zimmer '") + 
				TrimAll(vFolioRef.Room) + NStr("ru = ', период ';en = ', period ';de = ', period '") + 
				Format(vFolioRef.DateTimeFrom, "DF='dd.MM.yy HH:mm'") + " - " + 
				Format(vFolioRef.DateTimeTo, "DF='dd.MM.yy HH:mm'") + " = " + 
				cmFormatSum(vFoliosRow.SumBalance, vFolioRef.FolioCurrency, "NZ=");
			EndIf;
		EndDo;
		If Not vResult Then
			If vThereAreDebts And Not vThereAreDeposits Then
				vDebtsMessage = vDebtsMessage + Chars.LF + Chars.LF + NStr("en='There are DEBTS!';ru='ЕСТЬ ЗАДОЛЖЕННОСТЬ!';de='ES LIEGT EINE SCHULD VOR!'");
			ElsIf Not vThereAreDebts And vThereAreDeposits Then
				vDebtsMessage = vDebtsMessage + Chars.LF + Chars.LF + NStr("en='There are DEPOSITS!';ru='ЕСТЬ ПЕРЕПЛАТА!';de='ES LIEGT EINE ÜBERZAHLUNG VOR!'");
			Else
				vDebtsMessage = vDebtsMessage + Chars.LF + Chars.LF + NStr("en='There are DEBTS AND DEPOSITS!';ru='ЕСТЬ ЗАДОЛЖЕННОСТЬ И ПЕРЕПЛАТА!';de='ES LIEGT EINE SCHULD oder ÜBERZAHLUNG vor!'");
			EndIf;
		Else
			vDebtsMessage = "";
		EndIf;
		rResultMessage = vDebtsMessage;
	EndIf;
	Return vResult;
EndFunction // CheckAccommodationsBalances

// -----------------------------------------------------------------------------
&AtServer
Function CheckIfAdvancesWereCleared(pAccList, rResultMessage)
	vResult = True;
	rResultMessage = "";
	vDebtsMessage = "";
	If cmCheckUserPermissions("HavePermissionToCheckIfAdvancesClearingIsDone") Then
		vFolios = cmGetDocumentFoliosWithNotClearedAdvances(pAccList);
		If vFolios.Count() > 0 Then
			For Each vFoliosRow In vFolios Do
				vFolioRef = vFoliosRow.Folio;
				If ValueIsFilled(vFolioRef) Then
					vFolioPaymentMethod = vFolioRef.PaymentMethod;
					If ValueIsFilled(vFolioPaymentMethod) And vFolioPaymentMethod.PrintCheque And Not vFolioPaymentMethod.PrintNonFiscalCheque Then
						vResult = False;
						vDebtsMessage = ?(IsBlankString(vDebtsMessage), NStr("en='Folios: ';ru='По лицевым счетам: ';de='Nach Personenkonten: '") + Chars.LF, "");
						vDebtsMessage = vDebtsMessage + Chars.LF + "#" + TrimAll(vFolioRef.Number) + " " + 
						TrimAll(vFolioRef.Client) + NStr("ru = ', номер ';en = ', room ';de = ', zimmer '") + 
						TrimAll(vFolioRef.Room) + NStr("ru = ', период ';en = ', period ';de = ', period '") + 
						Format(vFolioRef.DateTimeFrom, "DF='dd.MM.yy HH:mm'") + " - " + 
						Format(vFolioRef.DateTimeTo, "DF='dd.MM.yy HH:mm'");
					EndIf;
				EndIf;
			EndDo;
			If Not vResult Then
				vDebtsMessage = vDebtsMessage + Chars.LF + Chars.LF + NStr("en='Advance is not cleared!';ru='Не выполнен зачет аванса!';de='Vorauszahlung wurde nicht verrechnet!'");
			EndIf;
			rResultMessage = vDebtsMessage;
		EndIf;
	EndIf;
	Return vResult;
EndFunction // CheckIfAdvancesWereCleared

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
		If (Find(vErrorDescription, "CHECKOUT_WITH_DEBT") > 0 Or Find(vErrorDescription, "ADVANCES_NOT_CLEARED")) And 
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

// ----------------------------------------------------------------------------
&AtServer
Function GetCreateData(pRoom, pStart, pEnd)
	vResult = New Structure;
	
	vRooms = StrSplit(pRoom, "_", False);
	vRoomType = Catalogs.RoomTypes.GetRef(New UUID(TrimAll(Right(vRooms[0], StrLen(vRooms[0]) - 1))));
	If IsBlankString(vRoomType.DataVersion) Then
		vRoomType = Catalogs.RoomTypes.EmptyRef();
	EndIf;
	vRoom = Catalogs.Rooms.GetRef(New UUID(TrimAll(vRooms[1])));
	If IsBlankString(vRoom.DataVersion) Then
		vRoom = Catalogs.Rooms.EmptyRef();
	EndIf;
	
	vStart = '19700101' + (pStart / 1000);
	vEnd = '19700101' + (pEnd / 1000);
	
	vResult.Insert("Room", vRoom);
	vResult.Insert("RoomType", vRoomType);
	vResult.Insert("Start", vStart);
	vResult.Insert("End", vEnd);
	
	Return vResult;
EndFunction // GetCreateData

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure ChangeRoomStatusAtServer(pRoom, pRoomStatus)
	vRoom = Catalogs.Rooms.GetRef(New UUID(TrimAll(pRoom)));
	If IsBlankString(vRoom.DataVersion) Then
		Return;
	EndIf;
	
	vRoomStatus = Catalogs.RoomStatuses.GetRef(New UUID(TrimAll(pRoomStatus)));
	If IsBlankString(vRoomStatus.DataVersion) Then
		Return;
	EndIf;
	
	// Update room status
	vRoomObj = vRoom.GetObject();
	vRoomObj.RoomStatus = vRoomStatus;
	vRoomObj.Write();
	// Add record to the room status change history
	vRoomObj.pmWriteToRoomStatusChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser, "");
EndProcedure // ChangeRoomStatusAtServer

// ----------------------------------------------------------------------------
&AtServer
Function GetRoomStatus(pRoom)	
	vRooms = StrSplit(pRoom, "_", False);
	vRoom = Catalogs.Rooms.GetRef(New UUID(TrimAll(vRooms[1])));
	If IsBlankString(vRoom.DataVersion) Then
		Return Undefined;
	EndIf;
	
	If Not cmCheckUserPermissions("HavePermissionToChangeRoomStatuses") Then
		Return Undefined;
	EndIf;
	
	vRoomStatusesList = GetRoomStatusesListAtServer(vRoom.RoomStatus, vRoom);
	
	vQ = New Query;
	vQ.Text =
	"SELECT
	|	RoomStatuses.Ref AS Ref,
	|	RoomStatuses.Description AS Description,
	|	RoomStatuses.RoomStatusIcon AS RoomStatusIcon
	|FROM
	|	Catalog.RoomStatuses AS RoomStatuses
	|WHERE
	|	RoomStatuses.Ref IN(&qRoomStatuses)";
	vQ.SetParameter("qRoomStatuses", vRoomStatusesList);
	vRoomStatuses = vQ.Execute().Unload();
	
	vRoomStatusDate = New Structure;
	
	vRoomStatusDate.Insert("room", NStr("en = 'Select status for room: ';de = 'Wählen Sie den Status für Zimmer: ';ru = 'Выберите статус для номера: '") + "<b>" + TrimAll(vRoom.Description) + "</b>");
	vRoomStatusDate.Insert("id", TrimAll(vRoom.UUID()));
	
	vRoomStatusDates = New Array;
	
	For Each vStatus In vRoomStatuses Do
		vStatusDate = New Structure;
		vStatusDate.Insert("id", TrimAll(vStatus.Ref.UUID()));
		vStatusDate.Insert("statusText", TrimAll(vStatus.Description));
		
		If vStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Vacant Then
			vStatusDate.Insert("statusIcon", "availableCleanIcon");
		ElsIf vStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Occupied Then
			vStatusDate.Insert("statusIcon", "occupiedCleanIcon");
		ElsIf vStatus.RoomStatusIcon = Enums.RoomStatusesIcons.OccupiedDirty Then
			vStatusDate.Insert("statusIcon", "occupiedDirtyIcon");
		ElsIf vStatus.RoomStatusIcon = Enums.RoomStatusesIcons.CheckOut Or vStatus.RoomStatusIcon = Enums.RoomStatusesIcons.TidyingUp Then
			vStatusDate.Insert("statusIcon", "availableDirtyIcon");
		ElsIf vStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Malfunction Or vStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Repair Then
			vStatusDate.Insert("statusIcon", "malfunctionIcon");
		ElsIf vStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Waiting Then
			vStatusDate.Insert("statusIcon", "waiting");
		Else
			vStatusDate.Insert("statusIcon", Undefined);
		EndIf;
		
		vRoomStatusDates.Add(vStatusDate);
	EndDo;
	
	// Get hotel
	vHotel = Undefined;
	If ValueIsFilled(vRoom) Then
		vHotel = vRoom.Owner;
	EndIf;
	If Not ValueIsFilled(vHotel) Then
		vHotel = SelHotel;
	EndIf;
	
	If ValueIsFilled(vHotel) And Not ValueIsFilled(vHotel.VacantRoomStatus) Then
		vStatusDate = New Structure;
		vStatusDate.Insert("id", TrimAll(Catalogs.RoomStatuses.EmptyRef().UUID()));
		vStatusDate.Insert("statusText", NStr("en='<Empty status>';ru='<Пустой статус>';de='<Leer Status>'"));
		vStatusDate.Insert("color", "");
		vStatusDate.Insert("statusIcon", Undefined);
		vRoomStatusDates.Add(vStatusDate);
	EndIf;
	
	If vRoomStatusesList.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	vRoomStatusDate.Insert("roomStatus", vRoomStatusDates);
	
	Return vRoomStatusDate;
EndFunction // GetRoomStatus

// ----------------------------------------------------------------------------
&AtServer
Function GetRoomByUUID(pRoom)
	vRooms = StrSplit(pRoom, "_", False);
	vRoom = Catalogs.Rooms.GetRef(New UUID(TrimAll(vRooms[1])));
	If IsBlankString(vRoom.DataVersion) Then
		Return Undefined;
	EndIf;
	Return vRoom;
EndFunction // GetRoomByUUID

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetRoomStatusesListAtServer(pRoomStatus, pRoom)
	// Run query to get list of room statuses
	vRoomStatuses = cmGetAllowedRoomStatuses(SessionParameters.CurrentUser, pRoomStatus);
	// Return list
	Return vRoomStatuses.UnloadColumn("RoomStatus");
EndFunction // GetRoomStatusesListAtServer

// ----------------------------------------------------------------------------
&AtServer
Function GetChangedData(pDocument, pStart, pEnd, pOldRoom, pNewRoom)
	vResult = New Structure;
	vDocument = GetDocumentsByUUID(New UUID(pDocument));
	
	vOldRooms = StrSplit(pOldRoom, "_", False);
	vOldRoomType = Catalogs.RoomTypes.GetRef(New UUID(TrimAll(Right(vOldRooms[0], StrLen(vOldRooms[0]) - 1))));
	If IsBlankString(vOldRoomType.DataVersion) Then
		vOldRoomType = Catalogs.RoomTypes.EmptyRef();
	EndIf;
	vOldRoom = Catalogs.Rooms.GetRef(New UUID(TrimAll(vOldRooms[1])));
	If IsBlankString(vOldRoom.DataVersion) Then
		vOldRoom = Catalogs.Rooms.EmptyRef();
	EndIf;
	
	vNewRooms = StrSplit(pNewRoom, "_", False);
	vNewRoomType = Catalogs.RoomTypes.GetRef(New UUID(TrimAll(Right(vNewRooms[0], StrLen(vNewRooms[0]) - 1))));
	If IsBlankString(vNewRoomType.DataVersion) Then
		vNewRoomType = Catalogs.RoomTypes.EmptyRef();
	EndIf;
	vNewRoom = Catalogs.Rooms.GetRef(New UUID(TrimAll(vNewRooms[1])));
	If IsBlankString(vNewRoom.DataVersion) Then
		vNewRoom = Catalogs.Rooms.EmptyRef();
	EndIf;
	
	vStart = '19700101' + pStart;
	vEnd = '19700101' + pEnd;
	
	vResult.Insert("Document", vDocument);
	vResult.Insert("OldRoom", vOldRoom);
	vResult.Insert("OldRoomType", vOldRoomType);
	vResult.Insert("OldStart", vStart);
	vResult.Insert("OldEnd", vEnd);
	vResult.Insert("NewRoom", vNewRoom);
	vResult.Insert("NewRoomType", vNewRoomType);
	vResult.Insert("NewStart", vStart);
	vResult.Insert("NewEnd", vEnd);
	
	Return vResult;
EndFunction // GetChangedData

// -----------------------------------------------------------------------------
&AtServer
Function ProcessItemChangeAtServer(pDoc, pOldStart, pOldEnd, pOldRoom, pOldRoomType, pNewStart, pNewEnd, pNewRoom, pNewRoomType, rDocArr, rMessage = "", pSwapRoundReservation = Undefined, pRecalculatePrices = True)
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
	ElsIf SelScale <> "day" Then
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
					rDocArr.Add(pSwapRoundReservation);
					AddChangeRoomReservations(pDoc, vDocsListToPreProcess, rDocArr, pNewRoom);
					
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
					rDocArr.Add(pDoc);
				Else
					vDocsListToProcess.Add(pDoc);
					rDocArr.Add(pDoc);
					If pOldRoom <> pNewRoom Or 
						ValueIsFilled(pNewRoomType) And ValueIsFilled(pOldRoomType) And pNewRoomType <> pOldRoomType Then
						If TypeOf(pDoc) = Type("DocumentRef.Accommodation") Then
							AddChangeRoomAccommodations(pDoc, vDocsListToProcess, rDocArr, pOldRoom);
						ElsIf TypeOf(pDoc) = Type("DocumentRef.Reservation") Then
							AddChangeRoomReservations(pDoc, vDocsListToProcess, rDocArr, pOldRoom);
						EndIf;
					Else
						If TypeOf(pDoc) = Type("DocumentRef.Accommodation") Then
							AddOneRoomAccommodationsList(pDoc, vDocsListToProcess, rDocArr, pOldRoom);
						ElsIf TypeOf(pDoc) = Type("DocumentRef.Reservation") Then
							AddOneRoomReservations(pDoc, vDocsListToProcess, rDocArr, pOldRoom);
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
				
				If ValueIsFilled(pSwapRoundReservation) Then
					vDocsListToPreProcess.Add(pSwapRoundReservation);
					rDocArr.Add(pSwapRoundReservation);
					AddChangeRoomReservations(pDoc, vDocsListToPreProcess, rDocArr, pNewRoom);
					
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
&AtServer
Procedure AddOneRoomAccommodationsList(pDoc, pAccList, rDocArr, pRoom = Undefined)
	vDocsTable = GetOneRoomAccommodations(pDoc, pRoom);
	For Each vDocsTableRow In vDocsTable Do
		If vDocsTableRow.Ref <> pDoc Then
			pAccList.Add(vDocsTableRow.Ref);
			rDocArr.Add(vDocsTableRow.Ref);
		EndIf;
	EndDo;
EndProcedure // AddOneRoomAccommodationsList

// -----------------------------------------------------------------------------
&AtServer
Procedure AddChangeRoomAccommodations(pDoc, pAccList, rDocArr, pRoom = Undefined)
	vQryRes = GetOtherAccommodationsToChangeRoom(pDoc, pRoom);
	For Each vQryResRow In vQryRes Do
		If vQryResRow.Ref <> pDoc Then
			pAccList.Add(vQryResRow.Ref);
			rDocArr.Add(vQryResRow.Ref);
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
Procedure AddOneRoomReservations(pDoc, pDocsList, rDocArr, pRoom = Undefined)
	vQryRes = GetOneRoomReservations(pDoc, pRoom);
	For Each vQryResRow In vQryRes Do
		If vQryResRow.Ref <> pDoc Then
			pDocsList.Add(vQryResRow.Ref);
			rDocArr.Add(vQryResRow.Ref);
		EndIf;
	EndDo;
EndProcedure // AddOneRoomReservations 

// -----------------------------------------------------------------------------
&AtServer
Procedure AddChangeRoomReservations(pDoc, pDocsList, rDocArr, pRoom)
	vQryRes = GetOtherReservationsToChangeRoom(pDoc, pRoom);
	For Each vQryResRow In vQryRes Do
		If vQryResRow.Ref <> pDoc Then
			pDocsList.Add(vQryResRow.Ref);
			rDocArr.Add(vQryResRow.Ref);
		EndIf;
	EndDo;
EndProcedure // AddChangeRoomReservations 

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
Procedure FillAllRoomProperties()
	AllRoomProperties.Clear();
	AllRoomProperties = cmGetAllRoomProperties(, SelHotel, True);
EndProcedure // FillAllRoomProperties

// ----------------------------------------------------------------------------
&AtServerNoContext
Function GetLanguage()
	If SessionParameters.CurrentLanguage = Catalogs.Languages.EN Then
		Return "EN";
	ElsIf SessionParameters.CurrentLanguage = Catalogs.Languages.DE Then
		Return "DE";
	Else
		Return "RU";
	EndIf;
EndFunction // GetLanguage

// ----------------------------------------------------------------------------
&AtServerNoContext
Function FillRooms(pPeriodFrom, pPeriodTo, pDays, pHotel, pGuestGroup, pRoom, pRoomClass, pRoomSection, pRoomTypes, pRoomType, pGuestStr, pScale, pShowByRoomType, pShowAllGuests, pShowPreliminary, pShowBookingsWithoutRooms, pSelCustomer, pSelCar, pBedsSetup, pRoomProperties, pShowRoomPropertiesCodes, pNumberRoomEmpty, pRecordersNumber, pOrderBasket, pShowWaitingList)
	vResult = New Structure("startDate, type, cells, RoomTypesData, RoomsAvailableData, RoomsOccupancyData, hotelName", (pPeriodFrom - '19700101') * 1000, pScale, pDays, New Array, New Array, New Array, New Array);
	
	vHotel = pHotel;
	vResult.hotelName = TrimAll(vHotel.Description);
	
	vQ = New Query;
	vQ.Text =
	"SELECT
	|	AccommodationStatuses.Ref AS Ref,
	|	FALSE AS IsPreliminary,
	|	FALSE AS IsInWaitingList,
	|	AccommodationStatuses.Description AS Description,
	|	FALSE AS IsGuaranteed,
	|	"""" AS StatusColor
	|INTO StatusList
	|FROM
	|	Catalog.AccommodationStatuses AS AccommodationStatuses
	|WHERE
	|	NOT AccommodationStatuses.DeletionMark
	|	AND NOT AccommodationStatuses.IsFolder
	|	AND AccommodationStatuses.IsActive
	|
	|UNION
	|
	|SELECT
	|	ReservationStatuses.Ref,
	|	ReservationStatuses.IsPreliminary
	|		AND NOT ReservationStatuses.IsActive,
	|	ReservationStatuses.IsInWaitingList,
	|	ReservationStatuses.Description,
	|	ReservationStatuses.IsGuaranteed,
	|	ReservationStatuses.ColorHexString
	|FROM
	|	Catalog.ReservationStatuses AS ReservationStatuses
	|WHERE
	|	NOT ReservationStatuses.DeletionMark
	|	AND NOT ReservationStatuses.IsFolder
	|	AND (ReservationStatuses.IsActive
	|			OR &qShowPreliminary
	|				AND ReservationStatuses.IsPreliminary
	|			OR &qShowWaitingList
	|				AND ReservationStatuses.IsInWaitingList)
	|	AND NOT ReservationStatuses.IsCheckIn
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomPropertiesList.Room AS Room
	|INTO RoomPropertiesList
	|FROM
	|	(SELECT
	|		RoomProperties.Room AS Room,
	|		COUNT(DISTINCT RoomProperties.RoomProperty) AS RoomPropertysCount
	|	FROM
	|		InformationRegister.RoomProperties AS RoomProperties
	|	WHERE
	|		RoomProperties.RoomProperty IN(&qRoomProperties)
	|		AND NOT &qRoomPropertiesIsEmpty
	|	
	|	GROUP BY
	|		RoomProperties.Room) AS RoomPropertiesList
	|WHERE
	|	RoomPropertiesList.RoomPropertysCount = &qRoomPropertysCount
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomChangeHistory.Room AS Room,
	|	Rooms.Description AS RoomDescription,
	|	ISNULL(RoomStatusesList.Description, """") AS RoomStatusDescription,
	|	RoomStatusesList.RoomStatusIcon AS RoomStatusIcon,
	|	Rooms.SortCode AS SortCode,
	|	RoomChangeHistory.RoomType AS RoomType,
	|	ISNULL(RoomParents.Ref, VALUE(Catalog.Rooms.EmptyRef)) AS Parent,
	|	ISNULL(RoomParents.Description, """") AS RoomParentDescription,
	|	ISNULL(RoomParents.SortCode, 999999999) AS RoomParentSortCode,
	|	CAST(Rooms.RoomPropertiesDescriptions AS STRING(128)) AS RoomPropertiesDescriptions,
	|	CAST(Rooms.RoomPropertiesCodes AS STRING(128)) AS RoomPropertiesCodes,
	|	RoomStatusesList.ColorHexString AS RoomColor,
	|	RoomChangeHistory.Room.BedsSetup AS BedsSetup
	|INTO RoomsList
	|FROM
	|	(SELECT
	|		RoomChangeHistory.Room AS Room,
	|		RoomChangeHistory.RoomType AS RoomType
	|	FROM
	|		(SELECT
	|			RoomChangeHistory.Room AS Room,
	|			RoomChangeHistory.RoomType AS RoomType
	|		FROM
	|			InformationRegister.RoomChangeHistory AS RoomChangeHistory
	|		WHERE
	|			RoomChangeHistory.Period BETWEEN &qDateTimeFrom AND &qDateTimeTo
	|			AND RoomChangeHistory.Hotel = &qHotel
	|			AND NOT RoomChangeHistory.IsVirtual
	|		
	|		UNION
	|		
	|		SELECT
	|			RoomChangeHistorySliceLast.Room,
	|			RoomChangeHistorySliceLast.RoomType
	|		FROM
	|			InformationRegister.RoomChangeHistory.SliceLast(
	|					&qDateTimeFrom,
	|					Hotel = &qHotel
	|						AND NOT IsVirtual) AS RoomChangeHistorySliceLast) AS RoomChangeHistory
	|	
	|	GROUP BY
	|		RoomChangeHistory.Room,
	|		RoomChangeHistory.RoomType) AS RoomChangeHistory
	|		INNER JOIN Catalog.Rooms AS Rooms
	|		ON RoomChangeHistory.Room = Rooms.Ref
	|		LEFT JOIN RoomPropertiesList AS RoomPropertiesList
	|		ON RoomChangeHistory.Room = RoomPropertiesList.Room
	|		LEFT JOIN Catalog.RoomStatuses AS RoomStatusesList
	|		ON (Rooms.RoomStatus = RoomStatusesList.Ref)
	|		LEFT JOIN Catalog.Rooms AS RoomParents
	|		ON (RoomParents.Ref = Rooms.Parent)
	|WHERE
	|	Rooms.Owner = &qHotel
	|	AND NOT Rooms.DeletionMark
	|	AND NOT Rooms.IsFolder
	|	AND NOT Rooms.IsVirtual
	|	AND CASE
	|			WHEN &qRoomSectionIsEmpty
	|				THEN TRUE
	|			ELSE Rooms.RoomSection IN HIERARCHY (&qRoomSection)
	|		END
	|	AND CASE
	|			WHEN &qRoomEmpty
	|				THEN TRUE
	|			ELSE Rooms.Ref IN HIERARCHY (&qRoom)
	|		END
	|	AND Rooms.OperationStartDate <= &qDateTimeTo
	|	AND (Rooms.OperationEndDate >= &qDateTimeFrom
	|			OR Rooms.OperationEndDate = DATETIME(1, 1, 1))
	|	AND CASE
	|			WHEN &qRoomPropertiesIsEmpty
	|				THEN TRUE
	|			ELSE RoomPropertiesList.Room IS NOT NULL 
	|		END
	|	AND CASE
	|			WHEN &qBedsSetupIsEmpty
	|				THEN TRUE
	|			ELSE RoomChangeHistory.Room.BedsSetup = &qBedsSetup
	|		END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomTypes.Ref AS RoomType,
	|	RoomTypes.Code AS Code,
	|	RoomTypes.Description AS Description,
	|	RoomTypes.SortCode AS SortCode
	|INTO RoomsTypesList
	|FROM
	|	Catalog.RoomTypes AS RoomTypes
	|		INNER JOIN (SELECT
	|			RoomsList.RoomType AS RoomType,
	|			COUNT(DISTINCT RoomsList.Room) AS Count
	|		FROM
	|			RoomsList AS RoomsList
	|		
	|		GROUP BY
	|			RoomsList.RoomType) AS RoomsCountByRoomType
	|		ON RoomTypes.Ref = RoomsCountByRoomType.RoomType
	|			AND (RoomsCountByRoomType.Count > 0)
	|WHERE
	|	RoomTypes.Owner = &qHotel
	|	AND RoomTypes.IsVirtual = FALSE
	|	AND RoomTypes.IsFolder = FALSE
	|	AND RoomTypes.DeletionMark = FALSE
	|	AND CASE
	|			WHEN &qRoomTypesIsEmpty
	|				THEN TRUE
	|			ELSE RoomTypes.Ref IN (&qRoomTypes)
	|		END
	|	AND CASE
	|			WHEN &qRoomTypeIsEmpty
	|				THEN TRUE
	|			ELSE RoomTypes.Ref IN HIERARCHY (&qRoomType)
	|		END
	|	AND CASE
	|			WHEN &qRoomClassIsEmpty
	|				THEN TRUE
	|			ELSE RoomTypes.RoomClass = &qRoomClass
	|		END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomsList.Room AS Room,
	|	RoomsList.RoomDescription AS RoomDescription,
	|	RoomsList.RoomStatusDescription AS RoomStatusDescription,
	|	RoomsList.RoomStatusIcon AS RoomStatusIcon,
	|	RoomsList.SortCode AS SortCode,
	|	RoomsList.RoomType AS RoomType,
	|	RoomsTypesList.Code AS RoomTypeCode,
	|	RoomsTypesList.Description AS RoomTypeDescription,
	|	RoomsTypesList.SortCode AS RoomTypeSortCode,
	|	RoomsList.Parent AS Parent,
	|	RoomsList.RoomParentDescription AS RoomParentDescription,
	|	RoomsList.RoomParentSortCode AS RoomParentSortCode,
	|	RoomsList.RoomPropertiesDescriptions AS RoomPropertiesDescriptions,
	|	RoomsList.RoomPropertiesCodes AS RoomPropertiesCodes,
	|	RoomsList.RoomColor AS RoomColor,
	|	RoomsList.BedsSetup AS BedsSetup
	|INTO RoomsListByRoomType
	|FROM
	|	RoomsList AS RoomsList
	|		INNER JOIN RoomsTypesList AS RoomsTypesList
	|		ON RoomsList.RoomType = RoomsTypesList.RoomType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccommodationAndReservationList.Ref AS Ref,
	|	AccommodationAndReservationList.IsPreliminary AS IsPreliminary,
	|	AccommodationAndReservationList.IsInWaitingList AS IsInWaitingList,
	|	AccommodationAndReservationList.IsGuaranteed AS IsGuaranteed,
	|	AccommodationAndReservationList.StatusDescription AS StatusDescription,
	|	AccommodationAndReservationList.StatusColor AS StatusColor,
	|	AccommodationAndReservationList.DocumentNumber AS DocumentNumber,
	|	AccommodationTypesList.Type AS AccommodationType,
	|	ISNULL(AccommodationTemplates.Description, """") AS AccommodationTemplate,
	|	AccommodationAndReservationList.DocumentGuestGroupDescription AS DocumentGuestGroupDescription,
	|	AccommodationAndReservationList.DocumentGuestGroupCode AS DocumentGuestGroupCode,
	|	AccommodationAndReservationList.DocumentGuestGroupColor AS DocumentGuestGroupColor,
	|	AccommodationAndReservationList.ContractsColor AS ContractsColor,
	|	AccommodationAndReservationList.IsClosedForEdit AS IsClosedForEdit,
	|	AccommodationAndReservationList.IsComplimentary AS IsComplimentary,
	|	AccommodationAndReservationList.DocumentSortCode AS DocumentSortCode,
	|	AccommodationAndReservationList.BedsSetup AS BedsSetup
	|INTO DocumentsList
	|FROM
	|	(SELECT
	|		Accommodation.Ref AS Ref,
	|		Accommodation.AccommodationTemplate AS AccommodationTemplate,
	|		Accommodation.AccommodationType AS AccommodationType,
	|		StatusList.IsPreliminary AS IsPreliminary,
	|		StatusList.IsInWaitingList AS IsInWaitingList,
	|		StatusList.IsGuaranteed AS IsGuaranteed,
	|		StatusList.Description AS StatusDescription,
	|		StatusList.StatusColor AS StatusColor,
	|		Accommodation.Number AS DocumentNumber,
	|		DocumentsLisByFilter.DocumentGuestGroupDescription AS DocumentGuestGroupDescription,
	|		DocumentsLisByFilter.DocumentGuestGroupCode AS DocumentGuestGroupCode,
	|		DocumentsLisByFilter.DocumentGuestGroupColor AS DocumentGuestGroupColor,
	|		Contracts.ColorHexString AS ContractsColor,
	|		Accommodation.IsClosedForEdit AS IsClosedForEdit,
	|		Accommodation.IsComplimentary AS IsComplimentary,
	|		Accommodation.SortCode AS DocumentSortCode,
	|		Accommodation.BedsSetup AS BedsSetup
	|	FROM
	|		Document.Accommodation AS Accommodation
	|			INNER JOIN (SELECT
	|				Accommodation.Number AS DocumentNumber,
	|				GuestGroups.Ref AS DocumentGuestGroup,
	|				GuestGroups.Description AS DocumentGuestGroupDescription,
	|				GuestGroups.Code AS DocumentGuestGroupCode,
	|				GuestGroups.ColorHexString AS DocumentGuestGroupColor
	|			FROM
	|				Document.Accommodation AS Accommodation
	|					LEFT JOIN Catalog.Clients AS Clients
	|					ON Accommodation.Guest = Clients.Ref
	|					INNER JOIN StatusList AS StatusList
	|					ON Accommodation.AccommodationStatus = StatusList.Ref
	|					LEFT JOIN Catalog.GuestGroups AS GuestGroups
	|					ON Accommodation.GuestGroup = GuestGroups.Ref
	|			WHERE
	|				CASE
	|						WHEN &qGuestStrIsEmpty
	|							THEN TRUE
	|						ELSE ISNULL(Clients.FullName, """") LIKE ""%"" + &qGuestStr + ""%""
	|								OR Accommodation.Remarks LIKE ""%"" + &qGuestStr + ""%""
	|					END
	|				AND CASE
	|						WHEN &qCustomerIsEmpty
	|							THEN TRUE
	|						ELSE Accommodation.Customer = &qCustomer
	|					END
	|				AND CASE
	|						WHEN &qCarIsEmpty
	|							THEN TRUE
	|						ELSE Accommodation.Car LIKE ""%"" + &qCar + ""%""
	|					END
	|				AND CASE
	|						WHEN &qGuestGroupEmpty
	|							THEN TRUE
	|						ELSE Accommodation.GuestGroup = &qGuestGroup
	|					END
	|				AND Accommodation.Posted
	|				AND Accommodation.Hotel = &qHotel
	|				AND Accommodation.CheckInDate <= &qDateTimeTo
	|				AND Accommodation.CheckOutDate >= &qDateTimeFrom) AS DocumentsLisByFilter
	|			ON Accommodation.Number = DocumentsLisByFilter.DocumentNumber
	|				AND Accommodation.GuestGroup = DocumentsLisByFilter.DocumentGuestGroup
	|			INNER JOIN StatusList AS StatusList
	|			ON Accommodation.AccommodationStatus = StatusList.Ref
	|			LEFT JOIN Catalog.Contracts AS Contracts
	|			ON Accommodation.Contract = Contracts.Ref
	|	WHERE
	|		Accommodation.Posted
	|		AND CASE
	|				WHEN &qShowAllGuests
	|					THEN TRUE
	|				ELSE Accommodation.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|			END
	|		AND Accommodation.Hotel = &qHotel
	|		AND Accommodation.CheckInDate <= &qDateTimeTo
	|		AND Accommodation.CheckOutDate >= &qDateTimeFrom
	|	
	|	UNION
	|	
	|	SELECT
	|		Reservation.Ref,
	|		Reservation.AccommodationTemplate,
	|		Reservation.AccommodationType,
	|		StatusList.IsPreliminary,
	|		StatusList.IsInWaitingList,
	|		StatusList.IsGuaranteed,
	|		StatusList.Description,
	|		StatusList.StatusColor,
	|		Reservation.Number,
	|		DocumentsLisByFilter.DocumentGuestGroupDescription,
	|		DocumentsLisByFilter.DocumentGuestGroupCode,
	|		DocumentsLisByFilter.DocumentGuestGroupColor,
	|		Contracts.ColorHexString,
	|		Reservation.IsClosedForEdit,
	|		Reservation.IsComplimentary,
	|		Reservation.SortCode,
	|		Reservation.BedsSetup
	|	FROM
	|		Document.Reservation AS Reservation
	|			INNER JOIN (SELECT
	|				Reservation.Number AS DocumentNumber,
	|				GuestGroups.Ref AS DocumentGuestGroup,
	|				GuestGroups.Description AS DocumentGuestGroupDescription,
	|				GuestGroups.Code AS DocumentGuestGroupCode,
	|				GuestGroups.ColorHexString AS DocumentGuestGroupColor
	|			FROM
	|				Document.Reservation AS Reservation
	|					LEFT JOIN Catalog.Clients AS Clients
	|					ON Reservation.Guest = Clients.Ref
	|					INNER JOIN StatusList AS StatusList
	|					ON Reservation.ReservationStatus = StatusList.Ref
	|					LEFT JOIN Catalog.GuestGroups AS GuestGroups
	|					ON Reservation.GuestGroup = GuestGroups.Ref
	|			WHERE
	|				CASE
	|						WHEN &qGuestStrIsEmpty
	|							THEN TRUE
	|						ELSE ISNULL(Clients.FullName, """") LIKE ""%"" + &qGuestStr + ""%""
	|								OR Reservation.Remarks LIKE ""%"" + &qGuestStr + ""%""
	|					END
	|				AND CASE
	|						WHEN &qCustomerIsEmpty
	|							THEN TRUE
	|						ELSE Reservation.Customer = &qCustomer
	|					END
	|				AND CASE
	|						WHEN &qCarIsEmpty
	|							THEN TRUE
	|						ELSE Reservation.Car LIKE ""%"" + &qCar + ""%""
	|					END
	|				AND CASE
	|						WHEN &qGuestGroupEmpty
	|							THEN TRUE
	|						ELSE Reservation.GuestGroup = &qGuestGroup
	|					END
	|				AND Reservation.Posted
	|				AND Reservation.Hotel = &qHotel
	|				AND Reservation.CheckInDate <= &qDateTimeTo
	|				AND Reservation.CheckOutDate >= &qDateTimeFrom) AS DocumentsLisByFilter
	|			ON Reservation.Number = DocumentsLisByFilter.DocumentNumber
	|				AND Reservation.GuestGroup = DocumentsLisByFilter.DocumentGuestGroup
	|			INNER JOIN StatusList AS StatusList
	|			ON Reservation.ReservationStatus = StatusList.Ref
	|			LEFT JOIN Catalog.Contracts AS Contracts
	|			ON Reservation.Contract = Contracts.Ref
	|	WHERE
	|		Reservation.Posted
	|		AND CASE
	|				WHEN &qShowAllGuests
	|					THEN TRUE
	|				ELSE Reservation.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|			END
	|		AND Reservation.Hotel = &qHotel
	|		AND Reservation.CheckInDate <= &qDateTimeTo
	|		AND Reservation.CheckOutDate >= &qDateTimeFrom) AS AccommodationAndReservationList
	|		INNER JOIN Catalog.AccommodationTypes AS AccommodationTypesList
	|		ON AccommodationAndReservationList.AccommodationType = AccommodationTypesList.Ref
	|		LEFT JOIN Catalog.AccommodationTemplates AS AccommodationTemplates
	|		ON AccommodationAndReservationList.AccommodationTemplate = AccommodationTemplates.Ref
	|
	|UNION
	|
	|SELECT
	|	SetRoomBlock.Ref,
	|	FALSE,
	|	FALSE,
	|	FALSE,
	|	"""",
	|	"""",
	|	SetRoomBlock.Number,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	"""",
	|	"""",
	|	FALSE,
	|	FALSE,
	|	"""",
	|	NULL
	|FROM
	|	Document.SetRoomBlock AS SetRoomBlock
	|WHERE
	|	SetRoomBlock.Posted
	|	AND SetRoomBlock.Hotel = &qHotel
	|	AND SetRoomBlock.DateFrom <= &qDateTimeTo
	|	AND (SetRoomBlock.DateTo >= &qDateTimeFrom
	|			OR SetRoomBlock.DateTo = DATETIME(1, 1, 1))
	|	AND &qGuestStrIsEmpty
	|	AND &qCustomerIsEmpty
	|	AND &qCarIsEmpty
	|	AND &qGuestGroupEmpty
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Folio.Ref AS Ref,
	|	DocumentsList.Ref AS ParentDoc
	|INTO ClientFoliosList
	|FROM
	|	Document.Folio AS Folio
	|		LEFT JOIN Catalog.Customers AS Customers
	|		ON Folio.Customer = Customers.Ref
	|		INNER JOIN DocumentsList AS DocumentsList
	|		ON (CAST(Folio.ParentDoc AS Document.Accommodation).Number = DocumentsList.DocumentNumber)
	|WHERE
	|	NOT &qShowAllGuests
	|	AND Folio.FolioCurrency = &qCurrency
	|	AND &qShowBalances
	|	AND ISNULL(Customers.IsIndividual, TRUE)
	|	AND Folio.Hotel = &qHotel
	|
	|UNION
	|
	|SELECT
	|	Folio.Ref,
	|	DocumentsList.Ref
	|FROM
	|	Document.Folio AS Folio
	|		LEFT JOIN Catalog.Customers AS Customers
	|		ON Folio.Customer = Customers.Ref
	|		INNER JOIN DocumentsList AS DocumentsList
	|		ON (CAST(Folio.ParentDoc AS Document.Reservation).Number = DocumentsList.DocumentNumber)
	|WHERE
	|	NOT &qShowAllGuests
	|	AND Folio.FolioCurrency = &qCurrency
	|	AND &qShowBalances
	|	AND ISNULL(Customers.IsIndividual, TRUE)
	|	AND Folio.Hotel = &qHotel
	|
	|UNION
	|
	|SELECT
	|	Folio.Ref,
	|	DocumentsList.Ref
	|FROM
	|	Document.Folio AS Folio
	|		LEFT JOIN Catalog.Customers AS Customers
	|		ON Folio.Customer = Customers.Ref
	|		INNER JOIN DocumentsList AS DocumentsList
	|		ON Folio.ParentDoc = DocumentsList.Ref
	|WHERE
	|	&qShowAllGuests
	|	AND Folio.FolioCurrency = &qCurrency
	|	AND &qShowBalances
	|	AND ISNULL(Customers.IsIndividual, TRUE)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Folio.Ref AS Ref,
	|	DocumentsList.Ref AS ParentDoc
	|INTO CustomerFoliosList
	|FROM
	|	Document.Folio AS Folio
	|		LEFT JOIN Catalog.Customers AS Customers
	|		ON Folio.Customer = Customers.Ref
	|		INNER JOIN DocumentsList AS DocumentsList
	|		ON (CAST(Folio.ParentDoc AS Document.Accommodation).Number = DocumentsList.DocumentNumber)
	|WHERE
	|	NOT &qShowAllGuests
	|	AND Folio.FolioCurrency = &qCurrency
	|	AND &qShowBalances
	|	AND NOT ISNULL(Customers.IsIndividual, TRUE)
	|	AND Folio.Hotel = &qHotel
	|
	|UNION
	|
	|SELECT
	|	Folio.Ref,
	|	DocumentsList.Ref
	|FROM
	|	Document.Folio AS Folio
	|		LEFT JOIN Catalog.Customers AS Customers
	|		ON Folio.Customer = Customers.Ref
	|		INNER JOIN DocumentsList AS DocumentsList
	|		ON (CAST(Folio.ParentDoc AS Document.Reservation).Number = DocumentsList.DocumentNumber)
	|WHERE
	|	NOT &qShowAllGuests
	|	AND Folio.FolioCurrency = &qCurrency
	|	AND &qShowBalances
	|	AND NOT ISNULL(Customers.IsIndividual, TRUE)
	|	AND Folio.Hotel = &qHotel
	|
	|UNION
	|
	|SELECT
	|	Folio.Ref,
	|	DocumentsList.Ref
	|FROM
	|	Document.Folio AS Folio
	|		LEFT JOIN Catalog.Customers AS Customers
	|		ON Folio.Customer = Customers.Ref
	|		INNER JOIN DocumentsList AS DocumentsList
	|		ON Folio.ParentDoc = DocumentsList.Ref
	|WHERE
	|	&qShowAllGuests
	|	AND Folio.FolioCurrency = &qCurrency
	|	AND &qShowBalances
	|	AND NOT ISNULL(Customers.IsIndividual, TRUE)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccountsBalance.ParentDoc AS ParentDoc,
	|	SUM(AccountsBalance.ClientSumBalance) AS ClientSumBalance,
	|	SUM(-AccountsBalance.ClientLimitBalance) AS ClientLimitBalance,
	|	SUM(AccountsBalance.CustomerSumBalance) AS CustomerSumBalance,
	|	SUM(-AccountsBalance.CustomerLimitBalance) AS CustomerLimitBalance
	|INTO DocumentListBalances
	|FROM
	|	(SELECT
	|		ClientFoliosList.ParentDoc AS ParentDoc,
	|		ClientAccountsBalance.SumBalance AS ClientSumBalance,
	|		-ClientAccountsBalance.LimitBalance AS ClientLimitBalance,
	|		0 AS CustomerSumBalance,
	|		0 AS CustomerLimitBalance
	|	FROM
	|		AccumulationRegister.Accounts.Balance(
	|				&qBalancesPeriod,
	|				&qShowBalances
	|					AND Hotel = &qHotel
	|					AND FolioCurrency = &qCurrency
	|					AND Folio IN
	|						(SELECT
	|							ClientFoliosList.Ref AS Ref
	|						FROM
	|							ClientFoliosList AS ClientFoliosList)) AS ClientAccountsBalance
	|			INNER JOIN ClientFoliosList AS ClientFoliosList
	|			ON ClientAccountsBalance.Folio = ClientFoliosList.Ref
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CustomerFoliosList.ParentDoc,
	|		0,
	|		0,
	|		CustomerAccountsBalance.SumBalance,
	|		-CustomerAccountsBalance.LimitBalance
	|	FROM
	|		AccumulationRegister.Accounts.Balance(
	|				&qBalancesPeriod,
	|				&qShowBalances
	|					AND Hotel = &qHotel
	|					AND FolioCurrency = &qCurrency
	|					AND Folio IN
	|						(SELECT
	|							CustomerFoliosList.Ref AS Ref
	|						FROM
	|							CustomerFoliosList AS CustomerFoliosList)) AS CustomerAccountsBalance
	|			INNER JOIN CustomerFoliosList AS CustomerFoliosList
	|			ON CustomerAccountsBalance.Folio = CustomerFoliosList.Ref) AS AccountsBalance
	|
	|GROUP BY
	|	AccountsBalance.ParentDoc
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventoryList.Recorder AS Recorder,
	|	RoomInventoryList.Room AS Room,
	|	RoomInventoryList.RoomParent AS RoomParent,
	|	RoomInventoryList.RoomParentDescription AS RoomParentDescription,
	|	CASE
	|		WHEN RoomInventoryList.RoomParent = VALUE(Catalog.Rooms.EmptyRef)
	|			THEN -1
	|		ELSE RoomInventoryList.RoomParentSortCode
	|	END AS RoomParentSortCode,
	|	RoomInventoryList.RoomType AS RoomType,
	|	RoomInventoryList.RoomTypeCode AS RoomTypeCode,
	|	RoomInventoryList.RoomTypeDescription AS RoomTypeDescription,
	|	RoomInventoryList.RoomTypeSortCode AS RoomTypeSortCode,
	|	RoomInventoryList.IsBlocking AS IsBlocking,
	|	RoomInventoryList.IsReservation AS IsReservation,
	|	RoomInventoryList.IsAccommodation AS IsAccommodation,
	|	CASE
	|		WHEN RoomInventoryList.Room = VALUE(Catalog.Rooms.EmptyRef)
	|			THEN ""* "" + ISNULL(Clients.FullName, """")
	|		ELSE ISNULL(Clients.FullName, """")
	|	END AS Guest,
	|	ISNULL(Clients.DateOfBirth, DATETIME(1, 1, 1)) AS GuestDateOfBirth,
	|	RoomInventoryList.DocumentStatus AS DocumentStatus,
	|	RoomInventoryList.PeriodFrom AS PeriodFrom,
	|	RoomInventoryList.PeriodTo AS PeriodTo,
	|	RoomInventoryList.IsRoomChange AS IsRoomChange,
	|	RoomInventoryList.Customer AS Customer,
	|	RoomInventoryList.GuestGroup AS GuestGroup,
	|	RoomInventoryList.IsInHouse AS IsInHouse,
	|	RoomInventoryList.IsCheckIn AS IsCheckIn,
	|	RoomInventoryList.Remarks AS Remarks,
	|	RoomInventoryList.HousekeepingRemarks AS HousekeepingRemarks,
	|	RoomInventoryList.AccommodationTemplate AS AccommodationTemplate,
	|	RoomInventoryList.StatusDescription AS StatusDescription,
	|	RoomInventoryList.IsGuaranteed AS IsGuaranteed,
	|	RoomInventoryList.RoomTypeBefore AS RoomTypeBefore,
	|	RoomInventoryList.RoomBefore AS RoomBefore,
	|	RoomInventoryList.RoomTypeAfter AS RoomTypeAfter,
	|	RoomInventoryList.RoomAfter AS RoomAfter,
	|	RoomInventoryList.RoomBlockType AS RoomBlockType,
	|	RoomInventoryList.DocumentNumber AS DocumentNumber,
	|	RoomInventoryList.DocumentGuestGroupCode AS GuestGroupsCode,
	|	RoomInventoryList.DocumentGuestGroupDescription AS GuestGroupsDescription,
	|	RoomInventoryList.BedsReserved AS BedsReserved,
	|	RoomInventoryList.RoomsReserved AS RoomsReserved,
	|	RoomInventoryList.AccommodationType AS AccommodationType,
	|	ISNULL(DocumentListBalances.ClientSumBalance, 0) AS ClientSumBalance,
	|	ISNULL(DocumentListBalances.ClientLimitBalance, 0) AS ClientLimitBalance,
	|	ISNULL(DocumentListBalances.CustomerSumBalance, 0) AS CustomerSumBalance,
	|	ISNULL(DocumentListBalances.CustomerLimitBalance, 0) AS CustomerLimitBalance,
	|	CASE
	|		WHEN PaymentMethods.Ref IS NULL
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS IsByBankTransfer,
	|	RoomInventoryList.StatusColor AS StatusColor,
	|	RoomInventoryList.DocumentGuestGroupColor AS DocumentGuestGroupColor,
	|	RoomInventoryList.RoomBlockTypesColor AS RoomBlockTypesColor,
	|	RoomInventoryList.ContractsColor AS ContractsColor,
	|	RoomInventoryList.IsClosedForEdit AS IsClosedForEdit,
	|	RoomInventoryList.RoomBeforeDescription AS RoomBeforeDescription,
	|	RoomInventoryList.RoomAfterDescription AS RoomAfterDescription,
	|	RoomInventoryList.IsComplimentary AS IsComplimentary,
	|	RoomInventoryList.DocumentSortCode AS DocumentSortCode,
	|	RoomInventoryList.BedsSetup AS BedsSetup,
	|	RoomInventoryList.BedsSetup.Code AS BedsSetupCode
	|INTO RoomInventoryRecordsList
	|FROM
	|	(SELECT
	|		RoomInventory.Recorder AS Recorder,
	|		RoomInventory.Room AS Room,
	|		RoomsListByRoomType.Parent AS RoomParent,
	|		ISNULL(RoomsListByRoomType.RoomParentDescription, """") AS RoomParentDescription,
	|		ISNULL(RoomsListByRoomType.RoomParentSortCode, 999999999) AS RoomParentSortCode,
	|		RoomInventory.RoomType AS RoomType,
	|		RoomsTypesList.Code AS RoomTypeCode,
	|		RoomsTypesList.Description AS RoomTypeDescription,
	|		RoomsTypesList.SortCode AS RoomTypeSortCode,
	|		RoomInventory.IsBlocking AS IsBlocking,
	|		RoomInventory.IsReservation AS IsReservation,
	|		RoomInventory.IsAccommodation AS IsAccommodation,
	|		RoomInventory.Guest AS Guest,
	|		CASE
	|			WHEN RoomInventory.IsReservation
	|				THEN RoomInventory.ReservationStatus
	|			WHEN RoomInventory.IsAccommodation
	|				THEN RoomInventory.AccommodationStatus
	|			ELSE NULL
	|		END AS DocumentStatus,
	|		RoomInventory.PeriodFrom AS PeriodFrom,
	|		RoomInventory.PeriodTo AS PeriodTo,
	|		RoomInventory.IsRoomChange AS IsRoomChange,
	|		RoomInventory.Customer AS Customer,
	|		RoomInventory.GuestGroup AS GuestGroup,
	|		RoomInventory.IsInHouse AS IsInHouse,
	|		CASE
	|			WHEN RoomInventory.IsAccommodation
	|				THEN TRUE
	|			ELSE RoomInventory.IsCheckIn
	|		END AS IsCheckIn,
	|		CAST(RoomInventory.Remarks AS STRING(128)) AS Remarks,
	|		CAST(RoomInventory.HousekeepingRemarks AS STRING(128)) AS HousekeepingRemarks,
	|		DocumentsList.AccommodationTemplate AS AccommodationTemplate,
	|		DocumentsList.StatusDescription AS StatusDescription,
	|		DocumentsList.IsGuaranteed AS IsGuaranteed,
	|		RoomInventory.RoomTypeBefore AS RoomTypeBefore,
	|		RoomInventory.RoomBefore AS RoomBefore,
	|		RoomInventory.RoomTypeAfter AS RoomTypeAfter,
	|		RoomInventory.RoomAfter AS RoomAfter,
	|		ISNULL(RoomBlockTypes.Description, """") AS RoomBlockType,
	|		DocumentsList.DocumentNumber AS DocumentNumber,
	|		MAX(RoomInventory.BedsReserved) AS BedsReserved,
	|		MAX(RoomInventory.RoomsReserved) AS RoomsReserved,
	|		DocumentsList.AccommodationType AS AccommodationType,
	|		RoomInventory.PlannedPaymentMethod AS PlannedPaymentMethod,
	|		DocumentsList.DocumentGuestGroupDescription AS DocumentGuestGroupDescription,
	|		DocumentsList.DocumentGuestGroupCode AS DocumentGuestGroupCode,
	|		DocumentsList.StatusColor AS StatusColor,
	|		DocumentsList.DocumentGuestGroupColor AS DocumentGuestGroupColor,
	|		ISNULL(RoomBlockTypes.ColorHexString, """") AS RoomBlockTypesColor,
	|		DocumentsList.ContractsColor AS ContractsColor,
	|		DocumentsList.IsClosedForEdit AS IsClosedForEdit,
	|		RoomInventory.RoomBefore.Description AS RoomBeforeDescription,
	|		RoomInventory.RoomAfter.Description AS RoomAfterDescription,
	|		DocumentsList.IsComplimentary AS IsComplimentary,
	|		DocumentsList.DocumentSortCode AS DocumentSortCode,
	|		DocumentsList.BedsSetup AS BedsSetup
	|	FROM
	|		AccumulationRegister.RoomInventory AS RoomInventory
	|			INNER JOIN DocumentsList AS DocumentsList
	|			ON RoomInventory.Recorder = DocumentsList.Ref
	|				AND (RoomInventory.RecordType = VALUE(AccumulationRecordType.Expense))
	|			INNER JOIN RoomsTypesList AS RoomsTypesList
	|			ON RoomInventory.RoomType = RoomsTypesList.RoomType
	|			LEFT JOIN RoomsListByRoomType AS RoomsListByRoomType
	|			ON RoomInventory.Room = RoomsListByRoomType.Room
	|			LEFT JOIN Catalog.RoomBlockTypes AS RoomBlockTypes
	|			ON RoomInventory.RoomBlockType = RoomBlockTypes.Ref
	|	WHERE
	|		CASE
	|				WHEN &qRoomSectionIsEmpty
	|						AND &qRoomEmpty
	|						AND &qRoomPropertiesIsEmpty
	|					THEN TRUE
	|				ELSE RoomsListByRoomType.Room IS NOT NULL 
	|			END
	|		AND (RoomInventory.PeriodTo >= &qDateTimeFrom
	|				OR RoomInventory.PeriodTo = DATETIME(1, 1, 1))
	|		AND RoomInventory.PeriodFrom <= &qDateTimeTo
	|		AND (RoomInventory.IsAccommodation
	|				OR RoomInventory.IsReservation
	|				OR RoomInventory.IsBlocking)
	|	
	|	GROUP BY
	|		RoomInventory.Recorder,
	|		RoomInventory.Room,
	|		RoomsListByRoomType.Parent,
	|		ISNULL(RoomsListByRoomType.RoomParentDescription, """"),
	|		ISNULL(RoomsListByRoomType.RoomParentSortCode, 999999999),
	|		RoomInventory.RoomType,
	|		RoomsTypesList.Code,
	|		RoomsTypesList.Description,
	|		RoomsTypesList.SortCode,
	|		RoomInventory.IsBlocking,
	|		RoomInventory.IsReservation,
	|		RoomInventory.IsAccommodation,
	|		RoomInventory.Guest,
	|		CASE
	|			WHEN RoomInventory.IsReservation
	|				THEN RoomInventory.ReservationStatus
	|			WHEN RoomInventory.IsAccommodation
	|				THEN RoomInventory.AccommodationStatus
	|			ELSE NULL
	|		END,
	|		RoomInventory.PeriodFrom,
	|		RoomInventory.PeriodTo,
	|		RoomInventory.IsRoomChange,
	|		RoomInventory.Customer,
	|		RoomInventory.GuestGroup,
	|		RoomInventory.IsInHouse,
	|		CAST(RoomInventory.Remarks AS STRING(128)),
	|		CAST(RoomInventory.HousekeepingRemarks AS STRING(128)),
	|		DocumentsList.AccommodationTemplate,
	|		DocumentsList.StatusDescription,
	|		DocumentsList.IsGuaranteed,
	|		ISNULL(RoomBlockTypes.Description, """"),
	|		DocumentsList.DocumentNumber,
	|		DocumentsList.AccommodationType,
	|		RoomInventory.PlannedPaymentMethod,
	|		DocumentsList.DocumentGuestGroupDescription,
	|		DocumentsList.DocumentGuestGroupCode,
	|		RoomInventory.RoomTypeBefore,
	|		RoomInventory.RoomBefore,
	|		RoomInventory.RoomTypeAfter,
	|		RoomInventory.RoomAfter,
	|		DocumentsList.StatusColor,
	|		DocumentsList.DocumentGuestGroupColor,
	|		ISNULL(RoomBlockTypes.ColorHexString, """"),
	|		DocumentsList.ContractsColor,
	|		DocumentsList.IsClosedForEdit,
	|		RoomInventory.RoomBefore.Description,
	|		RoomInventory.RoomAfter.Description,
	|		DocumentsList.IsComplimentary,
	|		CASE
	|			WHEN RoomInventory.IsAccommodation
	|				THEN TRUE
	|			ELSE RoomInventory.IsCheckIn
	|		END,
	|		DocumentsList.DocumentSortCode,
	|		DocumentsList.BedsSetup
	|	
	|	UNION
	|	
	|	SELECT
	|		Reservation.Ref,
	|		Reservation.Room,
	|		RoomsListByRoomType.Parent,
	|		ISNULL(RoomsListByRoomType.RoomParentDescription, """"),
	|		ISNULL(RoomsListByRoomType.RoomParentSortCode, 999999999),
	|		Reservation.RoomType,
	|		RoomsTypesList.Code,
	|		RoomsTypesList.Description,
	|		RoomsTypesList.SortCode,
	|		FALSE,
	|		TRUE,
	|		FALSE,
	|		Reservation.Guest,
	|		Reservation.ReservationStatus,
	|		Reservation.CheckInDate,
	|		Reservation.CheckOutDate,
	|		FALSE,
	|		Reservation.Customer,
	|		Reservation.GuestGroup,
	|		FALSE,
	|		FALSE,
	|		CAST(Reservation.Remarks AS STRING(128)),
	|		CAST(Reservation.HousekeepingRemarks AS STRING(128)),
	|		DocumentsList.AccommodationTemplate,
	|		DocumentsList.StatusDescription,
	|		DocumentsList.IsGuaranteed,
	|		VALUE(Catalog.RoomTypes.EmptyRef),
	|		VALUE(Catalog.Rooms.EmptyRef),
	|		VALUE(Catalog.RoomTypes.EmptyRef),
	|		VALUE(Catalog.Rooms.EmptyRef),
	|		"""",
	|		DocumentsList.DocumentNumber,
	|		MAX(Reservation.NumberOfBeds),
	|		MAX(Reservation.NumberOfRooms),
	|		DocumentsList.AccommodationType,
	|		Reservation.PlannedPaymentMethod,
	|		DocumentsList.DocumentGuestGroupDescription,
	|		DocumentsList.DocumentGuestGroupCode,
	|		DocumentsList.StatusColor,
	|		DocumentsList.DocumentGuestGroupColor,
	|		"""",
	|		NULL,
	|		DocumentsList.IsClosedForEdit,
	|		"""",
	|		"""",
	|		Reservation.IsComplimentary,
	|		DocumentsList.DocumentSortCode,
	|		DocumentsList.BedsSetup
	|	FROM
	|		DocumentsList AS DocumentsList
	|			INNER JOIN Document.Reservation AS Reservation
	|			ON (Reservation.Ref = DocumentsList.Ref)
	|				AND (&qShowPreliminary
	|						AND DocumentsList.IsPreliminary
	|					OR &qShowWaitingList
	|						AND DocumentsList.IsInWaitingList)
	|			INNER JOIN RoomsTypesList AS RoomsTypesList
	|			ON (Reservation.RoomType = RoomsTypesList.RoomType)
	|			LEFT JOIN RoomsListByRoomType AS RoomsListByRoomType
	|			ON (Reservation.Room = RoomsListByRoomType.Room)
	|	WHERE
	|		CASE
	|				WHEN &qRoomSectionIsEmpty
	|						AND &qRoomEmpty
	|						AND &qRoomPropertiesIsEmpty
	|					THEN TRUE
	|				ELSE RoomsListByRoomType.Room IS NOT NULL 
	|			END
	|	
	|	GROUP BY
	|		Reservation.Ref,
	|		Reservation.Room,
	|		RoomsListByRoomType.Parent,
	|		ISNULL(RoomsListByRoomType.RoomParentDescription, """"),
	|		ISNULL(RoomsListByRoomType.RoomParentSortCode, 999999999),
	|		Reservation.RoomType,
	|		RoomsTypesList.Code,
	|		RoomsTypesList.Description,
	|		RoomsTypesList.SortCode,
	|		Reservation.Guest,
	|		Reservation.ReservationStatus,
	|		Reservation.CheckInDate,
	|		Reservation.CheckOutDate,
	|		Reservation.Customer,
	|		Reservation.GuestGroup,
	|		CAST(Reservation.Remarks AS STRING(128)),
	|		CAST(Reservation.HousekeepingRemarks AS STRING(128)),
	|		DocumentsList.AccommodationTemplate,
	|		DocumentsList.StatusDescription,
	|		DocumentsList.IsGuaranteed,
	|		DocumentsList.DocumentNumber,
	|		DocumentsList.AccommodationType,
	|		Reservation.PlannedPaymentMethod,
	|		DocumentsList.DocumentGuestGroupDescription,
	|		DocumentsList.DocumentGuestGroupCode,
	|		DocumentsList.StatusColor,
	|		DocumentsList.DocumentGuestGroupColor,
	|		DocumentsList.IsClosedForEdit,
	|		Reservation.IsComplimentary,
	|		DocumentsList.DocumentSortCode,
	|		DocumentsList.BedsSetup) AS RoomInventoryList
	|		LEFT JOIN Catalog.Clients AS Clients
	|		ON RoomInventoryList.Guest = Clients.Ref
	|		LEFT JOIN DocumentListBalances AS DocumentListBalances
	|		ON RoomInventoryList.Recorder = DocumentListBalances.ParentDoc
	|			AND (&qShowBalances)
	|		LEFT JOIN Catalog.PaymentMethods AS PaymentMethods
	|		ON RoomInventoryList.PlannedPaymentMethod = PaymentMethods.Ref
	|			AND (PaymentMethods.IsByBankTransfer)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN RoomTypesAndRooms.RoomType IS NULL
	|			THEN RoomInventoryRecordsList.RoomType
	|		ELSE RoomTypesAndRooms.RoomType
	|	END AS RoomType,
	|	CASE
	|		WHEN RoomTypesAndRooms.GrupByField IS NULL
	|			THEN CASE
	|					WHEN &qShowByRoomType
	|						THEN ISNULL(RoomInventoryRecordsList.RoomTypeCode, """")
	|					ELSE ISNULL(RoomInventoryRecordsList.RoomParentDescription, """")
	|				END
	|		ELSE ISNULL(RoomTypesAndRooms.Code, """")
	|	END AS GrupByFieldCode,
	|	CASE
	|		WHEN RoomTypesAndRooms.GrupByField IS NULL
	|			THEN CASE
	|					WHEN &qShowByRoomType
	|						THEN ISNULL(RoomInventoryRecordsList.RoomTypeDescription, """")
	|					ELSE ISNULL(RoomInventoryRecordsList.RoomParentDescription, """")
	|				END
	|		ELSE ISNULL(RoomTypesAndRooms.Description, """")
	|	END AS GrupByFieldDescription,
	|	CASE
	|		WHEN RoomTypesAndRooms.GrupByField IS NULL
	|			THEN CASE
	|					WHEN &qShowByRoomType
	|						THEN ISNULL(RoomInventoryRecordsList.RoomTypeSortCode, 999999999)
	|					ELSE ISNULL(RoomInventoryRecordsList.RoomParentSortCode, 999999999)
	|				END
	|		ELSE ISNULL(RoomTypesAndRooms.SortCode, 999999999)
	|	END AS GrupByFieldSortCode,
	|	CASE
	|		WHEN RoomTypesAndRooms.GrupByField IS NULL
	|			THEN CASE
	|					WHEN &qShowByRoomType
	|						THEN RoomInventoryRecordsList.RoomType
	|					ELSE RoomInventoryRecordsList.RoomParent
	|				END
	|		ELSE RoomTypesAndRooms.GrupByField
	|	END AS GrupByField,
	|	ISNULL(RoomTypesAndRooms.Room, VALUE(Catalog.Rooms.EmptyRef)) AS Room,
	|	ISNULL(RoomTypesAndRooms.RoomDescription, """") AS RoomDescription,
	|	ISNULL(RoomTypesAndRooms.RoomStatusDescription, """") AS RoomStatusDescription,
	|	RoomTypesAndRooms.RoomStatusIcon AS RoomStatusIcon,
	|	ISNULL(RoomTypesAndRooms.RoomSortCode, 999999999) AS RoomSortCode,
	|	RoomInventoryRecordsList.Recorder AS Recorder,
	|	RoomInventoryRecordsList.IsBlocking AS IsBlocking,
	|	RoomInventoryRecordsList.IsReservation AS IsReservation,
	|	RoomInventoryRecordsList.IsAccommodation AS IsAccommodation,
	|	RoomInventoryRecordsList.Guest AS Guest,
	|	RoomInventoryRecordsList.GuestDateOfBirth AS GuestDateOfBirth,
	|	RoomInventoryRecordsList.DocumentStatus AS DocumentStatus,
	|	RoomInventoryRecordsList.PeriodFrom AS PeriodFrom,
	|	RoomInventoryRecordsList.PeriodTo AS PeriodTo,
	|	RoomInventoryRecordsList.IsRoomChange AS IsRoomChange,
	|	ISNULL(Customers.Description, """") AS Customer,
	|	ISNULL(RoomInventoryRecordsList.GuestGroup, VALUE(Catalog.GuestGroups.EmptyRef)) AS GuestGroup,
	|	ISNULL(RoomInventoryRecordsList.IsInHouse, FALSE) AS IsInHouse,
	|	ISNULL(RoomInventoryRecordsList.IsCheckIn, FALSE) AS IsCheckIn,
	|	CASE
	|		WHEN RoomTypesAndRooms.Room IS NULL
	|			THEN ISNULL(RoomInventoryRecordsList.RoomTypeDescription, """")
	|		ELSE ISNULL(RoomTypesAndRooms.RoomTypeDescription, """")
	|	END AS RoomTypeDescription,
	|	CASE
	|		WHEN RoomTypesAndRooms.Room IS NULL
	|			THEN ISNULL(RoomInventoryRecordsList.RoomTypeCode, """")
	|		ELSE ISNULL(RoomTypesAndRooms.RoomTypeCode, """")
	|	END AS RoomTypeCode,
	|	0 AS NumberRoomEmpty,
	|	ISNULL(RoomInventoryRecordsList.Remarks, """") AS Remarks,
	|	RoomInventoryRecordsList.PeriodFrom AS PeriodFromPresentation,
	|	RoomInventoryRecordsList.PeriodTo AS PeriodToPresentation,
	|	ISNULL(RoomInventoryRecordsList.AccommodationTemplate, """") AS AccommodationTemplate,
	|	CASE
	|		WHEN ISNULL(RoomInventoryRecordsList.BedsSetupCode, """") = """"
	|			THEN ISNULL(RoomInventoryRecordsList.HousekeepingRemarks, """")
	|		WHEN ISNULL(RoomInventoryRecordsList.HousekeepingRemarks, """") = """"
	|			THEN &qBedsSetupTitle + ISNULL(RoomInventoryRecordsList.BedsSetupCode, """")
	|		ELSE &qBedsSetupTitle + ISNULL(RoomInventoryRecordsList.BedsSetupCode, """") + "", "" + ISNULL(RoomInventoryRecordsList.HousekeepingRemarks, """")
	|	END AS HousekeepingRemarks,
	|	ISNULL(RoomInventoryRecordsList.StatusDescription, """") AS StatusDescription,
	|	ISNULL(RoomInventoryRecordsList.IsGuaranteed, FALSE) AS IsGuaranteed,
	|	CASE
	|		WHEN RoomTypesAndRooms.Room IS NULL
	|			THEN ISNULL(RoomInventoryRecordsList.RoomTypeSortCode, 999999999)
	|		ELSE ISNULL(RoomTypesAndRooms.RoomTypeSortCode, 999999999)
	|	END AS RoomTypeSortCode,
	|	ISNULL(RoomTypesAndRooms.RoomParent, VALUE(Catalog.Rooms.EmptyRef)) AS RoomParent,
	|	RoomInventoryRecordsList.RoomTypeBefore AS RoomTypeBefore,
	|	RoomInventoryRecordsList.RoomBefore AS RoomBefore,
	|	RoomInventoryRecordsList.RoomTypeAfter AS RoomTypeAfter,
	|	RoomInventoryRecordsList.RoomAfter AS RoomAfter,
	|	RoomInventoryRecordsList.RoomBlockType AS RoomBlockType,
	|	RoomInventoryRecordsList.DocumentNumber AS DocumentNumber,
	|	RoomInventoryRecordsList.GuestGroupsCode AS GuestGroupsCode,
	|	RoomInventoryRecordsList.GuestGroupsDescription AS GuestGroupsDescription,
	|	RoomInventoryRecordsList.BedsReserved AS BedsReserved,
	|	RoomInventoryRecordsList.RoomsReserved AS RoomsReserved,
	|	RoomInventoryRecordsList.BedsReserved > 0 AS IsMainRecorder,
	|	RoomInventoryRecordsList.AccommodationType AS AccommodationType,
	|	CASE
	|		WHEN RoomTypesAndRooms.BedsSetupCodeAvailable = """"
	|			THEN RoomTypesAndRooms.RoomPropertiesDescriptions
	|		WHEN RoomTypesAndRooms.RoomPropertiesDescriptions = """"
	|			THEN RoomTypesAndRooms.BedsSetupCodeAvailable
	|		ELSE RoomTypesAndRooms.BedsSetupCodeAvailable + &qCharsLF + RoomTypesAndRooms.RoomPropertiesDescriptions
	|	END AS RoomPropertiesDescriptions,
	|	CASE
	|		WHEN RoomTypesAndRooms.BedsSetupCodeAvailable = """"
	|			THEN RoomTypesAndRooms.RoomPropertiesCodes
	|		WHEN RoomTypesAndRooms.RoomPropertiesCodes = """"
	|			THEN RoomTypesAndRooms.BedsSetupCodeAvailable
	|		ELSE RoomTypesAndRooms.BedsSetupCodeAvailable + "", "" + RoomTypesAndRooms.RoomPropertiesCodes
	|	END AS RoomPropertiesCodes,
	|	RoomInventoryRecordsList.ClientSumBalance AS ClientSumBalance,
	|	RoomInventoryRecordsList.ClientLimitBalance AS ClientLimitBalance,
	|	RoomInventoryRecordsList.CustomerSumBalance AS CustomerSumBalance,
	|	RoomInventoryRecordsList.CustomerLimitBalance AS CustomerLimitBalance,
	|	RoomInventoryRecordsList.IsByBankTransfer AS IsByBankTransfer,
	|	ISNULL(Customers.IsIndividual, TRUE) AS IsIndividual,
	|	RoomInventoryRecordsList.RoomType AS RoomTypeByRecord,
	|	ISNULL(RoomTypesAndRooms.Room, VALUE(Catalog.Rooms.EmptyRef)) = VALUE(Catalog.Rooms.EmptyRef) AS RoomIsEmpty,
	|	ISNULL(RoomInventoryRecordsList.StatusColor, """") AS StatusColor,
	|	ISNULL(RoomInventoryRecordsList.DocumentGuestGroupColor, """") AS DocumentGuestGroupColor,
	|	ISNULL(Customers.ColorHexString, """") AS CustomerColor,
	|	ISNULL(RoomInventoryRecordsList.RoomBlockTypesColor, """") AS RoomBlockTypesColor,
	|	ISNULL(RoomInventoryRecordsList.ContractsColor, """") AS ContractsColor,
	|	ISNULL(RoomTypesAndRooms.RoomColor, """") AS RoomColor,
	|	ISNULL(RoomInventoryRecordsList.IsClosedForEdit, FALSE) AS IsClosedForEdit,
	|	ISNULL(RoomInventoryRecordsList.RoomBeforeDescription, """") AS RoomBeforeDescription,
	|	ISNULL(RoomInventoryRecordsList.RoomAfterDescription, """") AS RoomAfterDescription,
	|	ISNULL(RoomInventoryRecordsList.IsComplimentary, FALSE) AS IsComplimentary,
	|	RoomInventoryRecordsList.DocumentSortCode AS DocumentSortCode,
	|	RoomTypesAndRooms.BedsSetupAvailable AS BedsSetupAvailable,
	|	RoomTypesAndRooms.BedsSetupCodeAvailable AS BedsSetupCodeAvailable,
	|	ISNULL(RoomInventoryRecordsList.BedsSetup, VALUE(Catalog.BedsSetups.EmptyRef)) AS BedsSetupNeeded,
	|	ISNULL(RoomInventoryRecordsList.BedsSetupCode, """") AS BedsSetupCodeNeeded
	|FROM
	|	(SELECT
	|		RoomsTypesList.RoomType AS RoomType,
	|		CASE
	|			WHEN &qShowByRoomType
	|				THEN RoomsTypesList.RoomType
	|			ELSE RoomsListByRoomType.Parent
	|		END AS GrupByField,
	|		CASE
	|			WHEN &qShowByRoomType
	|				THEN RoomsTypesList.Code
	|			ELSE RoomsListByRoomType.RoomParentDescription
	|		END AS Code,
	|		CASE
	|			WHEN &qShowByRoomType
	|				THEN RoomsTypesList.Description
	|			ELSE RoomsListByRoomType.RoomParentDescription
	|		END AS Description,
	|		CASE
	|			WHEN &qShowByRoomType
	|				THEN RoomsTypesList.SortCode
	|			ELSE CASE
	|					WHEN RoomsListByRoomType.Parent = VALUE(Catalog.Rooms.EmptyRef)
	|						THEN 0
	|					ELSE RoomsListByRoomType.RoomParentSortCode
	|				END
	|		END AS SortCode,
	|		RoomsListByRoomType.Room AS Room,
	|		ISNULL(RoomsListByRoomType.RoomDescription, """") AS RoomDescription,
	|		ISNULL(RoomsListByRoomType.RoomStatusDescription, """") AS RoomStatusDescription,
	|		RoomsListByRoomType.RoomStatusIcon AS RoomStatusIcon,
	|		ISNULL(RoomsListByRoomType.SortCode, 999999999) AS RoomSortCode,
	|		RoomsTypesList.Description AS RoomTypeDescription,
	|		RoomsTypesList.Code AS RoomTypeCode,
	|		RoomsTypesList.SortCode AS RoomTypeSortCode,
	|		ISNULL(RoomsListByRoomType.Parent, VALUE(Catalog.Rooms.EmptyRef)) AS RoomParent,
	|		RoomsListByRoomType.RoomPropertiesDescriptions AS RoomPropertiesDescriptions,
	|		RoomsListByRoomType.RoomPropertiesCodes AS RoomPropertiesCodes,
	|		RoomsListByRoomType.RoomColor AS RoomColor,
	|		ISNULL(RoomsListByRoomType.BedsSetup, VALUE(Catalog.BedsSetups.EmptyRef)) AS BedsSetupAvailable,
	|		ISNULL(RoomsListByRoomType.BedsSetup.Code, """") AS BedsSetupCodeAvailable
	|	FROM
	|		RoomsTypesList AS RoomsTypesList
	|			LEFT JOIN RoomsListByRoomType AS RoomsListByRoomType
	|			ON RoomsTypesList.RoomType = RoomsListByRoomType.RoomType) AS RoomTypesAndRooms
	|		FULL JOIN RoomInventoryRecordsList AS RoomInventoryRecordsList
	|			LEFT JOIN Catalog.Customers AS Customers
	|			ON RoomInventoryRecordsList.Customer = Customers.Ref
	|		ON RoomTypesAndRooms.RoomType = RoomInventoryRecordsList.RoomType
	|			AND RoomTypesAndRooms.Room = RoomInventoryRecordsList.Room
	|WHERE
	|	CASE
	|			WHEN &qGuestStrIsEmpty
	|				THEN TRUE
	|			ELSE RoomInventoryRecordsList.Recorder IS NOT NULL 
	|		END
	|	AND CASE
	|			WHEN &qCustomerIsEmpty
	|				THEN TRUE
	|			ELSE RoomInventoryRecordsList.Recorder IS NOT NULL 
	|		END
	|	AND CASE
	|			WHEN &qCarIsEmpty
	|				THEN TRUE
	|			ELSE RoomInventoryRecordsList.Recorder IS NOT NULL 
	|		END
	|	AND CASE
	|			WHEN &qGuestGroupEmpty
	|				THEN TRUE
	|			ELSE RoomInventoryRecordsList.Recorder IS NOT NULL 
	|		END
	|
	|ORDER BY
	|	GrupByFieldSortCode,
	|	GrupByFieldDescription,
	|	RoomSortCode,
	|	RoomDescription,
	|	PeriodFrom";
	vQ.SetParameter("qHotel", pHotel);
	vQ.SetParameter("qRoomClass", pRoomClass);
	vQ.SetParameter("qRoomClassIsEmpty", Not ValueIsFilled(pRoomClass));
	vQ.SetParameter("qRoomSection", pRoomSection);
	vQ.SetParameter("qRoomSectionIsEmpty", Not ValueIsFilled(pRoomSection));
	vQ.SetParameter("qRoomTypes", pRoomTypes);
	vQ.SetParameter("qRoomTypesIsEmpty", pRoomTypes.Count() = 0);
	vQ.SetParameter("qRoomType", pRoomType);
	vQ.SetParameter("qRoomTypeIsEmpty", Not ValueIsFilled(pRoomType));
	vQ.SetParameter("qRoom", pRoom);
	vQ.SetParameter("qRoomEmpty", Not ValueIsFilled(pRoom));
	vQ.SetParameter("qGuestGroup", pGuestGroup);
	vQ.SetParameter("qGuestGroupEmpty", Not ValueIsFilled(pGuestGroup));
	vQ.SetParameter("qDateTimeTo", pPeriodTo);
	vQ.SetParameter("qDateTimeFrom", pPeriodFrom);
	vQ.SetParameter("qExpense", AccumulationRecordType.Expense);
	vQ.SetParameter("qShowByRoomType", pShowByRoomType);
	vQ.SetParameter("qShowAllGuests", pShowAllGuests);
	vQ.SetParameter("qShowPreliminary", pShowPreliminary);
	vQ.SetParameter("qShowWaitingList", pShowWaitingList);
	vQ.SetParameter("qCurDate", BegOfDay(CurrentSessionDate()));
	vQ.SetParameter("qGuestStr", pGuestStr);
	vQ.SetParameter("qGuestStrIsEmpty", IsBlankString(pGuestStr));
	vQ.SetParameter("qCustomer", pSelCustomer);
	vQ.SetParameter("qCustomerIsEmpty", Not ValueIsFilled(pSelCustomer));
	vQ.SetParameter("qCar", pSelCar);
	vQ.SetParameter("qCarIsEmpty", IsBlankString(pSelCar));
	vQ.SetParameter("qBalancesPeriod", ?(vHotel.ShowDebtsOnCurrentDate, CurrentSessionDate(), Undefined));
	vQ.SetParameter("qCurrency", vHotel.FolioCurrency);
	vQ.SetParameter("qShowBalances", cmShowBalancesInLists());
	vQ.SetParameter("qRoomProperties", pRoomProperties);
	vQ.SetParameter("qRoomPropertiesIsEmpty", pRoomProperties.Count() = 0);
	vQ.SetParameter("qRoomPropertysCount", pRoomProperties.Count());
	vQ.SetParameter("qBedsSetup", pBedsSetup);
	vQ.SetParameter("qBedsSetupIsEmpty", Not ValueIsFilled(pBedsSetup));
	vQ.SetParameter("qCharsLF", Chars.LF);
	vQ.SetParameter("qBedsSetupTitle", NStr("en='Beds: '; ru='Кровати: '; de='Betten: '"));
	vRoomsAllList = vQ.Execute().Unload();
	
	vRoomTypesList = vRoomsAllList.Copy(, "RoomType");
	vRoomTypesList.GroupBy("RoomType");
	vRoomTypes = vRoomTypesList.UnloadColumn("RoomType");
	
	// Initialize "Show reports in beds" flag
	vShowReportsInBeds = False;
	vRoomTypeBalances = New ValueTable;
	If pScale <> "day" Then
		vShowReportsInBeds = vHotel.ShowReportsInBeds;
		
		vRoomTypeBalances.Columns.Add("GrupByField");
		vRoomTypeBalances.Columns.Add("Period", cmGetDateTimeTypeDescription());
		vRoomTypeBalances.Columns.Add("RoomsVacant", cmGetNumberTypeDescription(6, 0, True));
		vRoomTypeBalances.Columns.Add("BedsVacant", cmGetNumberTypeDescription(6, 0, True));
		vRoomTypeBalances.Columns.Add("TotalBeds", cmGetNumberTypeDescription(6, 0, True));
		vRoomTypeBalances.Columns.Add("TotalRooms", cmGetNumberTypeDescription(6, 0, True));
		vRoomTypeBalances.Columns.Add("RoomsBlocked", cmGetNumberTypeDescription(6, 0, True));
		vRoomTypeBalances.Columns.Add("BedsBlocked", cmGetNumberTypeDescription(6, 0, True));
		vRoomTypeBalances.Columns.Add("RoomsRented", cmGetNumberTypeDescription(15, 3));
		vRoomTypeBalances.Columns.Add("BedsRented", cmGetNumberTypeDescription(15, 3));
		
		vQry = New Query;
		vQry.Text =
		"SELECT
		|	RoomTypes.Ref AS Ref
		|INTO RoomTypeList
		|FROM
		|	Catalog.RoomTypes AS RoomTypes
		|WHERE
		|	RoomTypes.DoesNotAffectRoomRevenueStatistics
		|	AND NOT RoomTypes.DeletionMark
		|	AND NOT RoomTypes.IsFolder
		|
		|UNION ALL
		|
		|SELECT
		|	RoomTypes.Ref
		|FROM
		|	Catalog.RoomTypes AS RoomTypes
		|WHERE
		|	NOT RoomTypes.Ref IN (&qRoomTypes)
		|	AND NOT RoomTypes.DeletionMark
		|	AND NOT RoomTypes.IsFolder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TotalSales.Period AS Period,
		|	TotalSales.RoomType AS RoomType,
		|	SUM(TotalSales.RoomsRented) AS RoomsRented,
		|	SUM(TotalSales.BedsRented) AS BedsRented
		|INTO SalesPerRoomTypesAndDates
		|FROM
		|	(SELECT
		|		SalesTurnovers.Period AS Period,
		|		SalesTurnovers.RoomType AS RoomType,
		|		SalesTurnovers.RoomsRentedTurnover AS RoomsRented,
		|		SalesTurnovers.BedsRentedTurnover AS BedsRented,
		|		0 AS DummyField
		|	FROM
		|		AccumulationRegister.Sales.Turnovers(
		|				&qSalesDateTimeFrom,
		|				&qSalesDateTimeTo,
		|				DAY,
		|				Hotel = &qHotel
		|					AND NOT RoomType IN
		|							(SELECT
		|								RoomTypeList.Ref
		|							FROM
		|								RoomTypeList AS RoomTypeList)) AS SalesTurnovers
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		SalesForecastTurnovers.Period,
		|		SalesForecastTurnovers.RoomType,
		|		SalesForecastTurnovers.RoomsRentedTurnover,
		|		SalesForecastTurnovers.BedsRentedTurnover,
		|		0
		|	FROM
		|		AccumulationRegister.SalesForecast.Turnovers(
		|				&qForecastDateTimeFrom,
		|				&qForecastDateTimeTo,
		|				DAY,
		|				Hotel = &qHotel
		|					AND NOT RoomType IN
		|							(SELECT
		|								RoomTypeList.Ref
		|							FROM
		|								RoomTypeList AS RoomTypeList)) AS SalesForecastTurnovers
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		RoomQuotaSalesBalanceAndTurnovers.Period,
		|		RoomQuotaSalesBalanceAndTurnovers.RoomType,
		|		RoomQuotaSalesBalanceAndTurnovers.RoomsRemainsClosingBalance,
		|		RoomQuotaSalesBalanceAndTurnovers.BedsRemainsClosingBalance,
		|		RoomQuotaSalesBalanceAndTurnovers.CounterClosingBalance
		|	FROM
		|		AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
		|				&qDateTimeFrom,
		|				&qDateTimeTo,
		|				DAY,
		|				RegisterRecordsAndPeriodBoundaries,
		|				Hotel = &qHotel
		|					AND RoomQuota.IsCommitment
		|					AND RoomQuota.AllotmentBusinessType <> VALUE(Enum.AllotmentBusinessTypes.BusinessBlock)
		|					AND NOT RoomType IN
		|							(SELECT
		|								RoomTypeList.Ref
		|							FROM
		|								RoomTypeList AS RoomTypeList)) AS RoomQuotaSalesBalanceAndTurnovers) AS TotalSales
		|
		|GROUP BY
		|	TotalSales.Period,
		|	TotalSales.RoomType
		|
		|INDEX BY
		|	TotalSales.Period,
		|	TotalSales.RoomType
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RoomInventoryBalance.Period AS Period,
		|	RoomInventoryBalance.RoomType AS GrupByField,
		|	RoomInventoryBalance.CounterClosingBalance AS Counter,
		|	RoomInventoryBalance.RoomsVacantClosingBalance AS RoomsVacant,
		|	RoomInventoryBalance.BedsVacantClosingBalance AS BedsVacant,
		|	RoomInventoryBalance.TotalBedsClosingBalance AS TotalBeds,
		|	RoomInventoryBalance.TotalRoomsClosingBalance AS TotalRooms,
		|	RoomInventoryBalance.RoomsBlockedClosingBalance AS RoomsBlocked,
		|	RoomInventoryBalance.BedsBlockedClosingBalance AS BedsBlocked,
		|	ISNULL(SalesPerDays.RoomsRented, 0) AS RoomsRented,
		|	ISNULL(SalesPerDays.BedsRented, 0) AS BedsRented
		|FROM
		|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(
		|			&qDateTimeFrom,
		|			&qDateTimeTo,
		|			DAY,
		|			RegisterRecordsAndPeriodBoundaries,
		|			Hotel = &qHotel
		|				AND NOT RoomType IN
		|						(SELECT
		|							RoomTypeList.Ref
		|						FROM
		|							RoomTypeList AS RoomTypeList)) AS RoomInventoryBalance
		|		LEFT JOIN SalesPerRoomTypesAndDates AS SalesPerDays
		|		ON RoomInventoryBalance.Period = SalesPerDays.Period
		|			AND RoomInventoryBalance.RoomType = SalesPerDays.RoomType
		|
		|ORDER BY
		|	Period
		|TOTALS
		|	SUM(Counter),
		|	SUM(RoomsVacant),
		|	SUM(BedsVacant),
		|	SUM(TotalBeds),
		|	SUM(TotalRooms),
		|	SUM(RoomsBlocked),
		|	SUM(BedsBlocked),
		|	SUM(RoomsRented),
		|	SUM(BedsRented)
		|BY
		|	Period PERIODS(DAY, &qDateTimeFrom, &qDateTimeTo),
		|	GrupByField AS GrupByField";
		vQry.SetParameter("qHotel", pHotel);
		vQry.SetParameter("qRoomTypes", vRoomTypes);
		vQry.SetParameter("qDateTimeFrom", pPeriodFrom);
		vQry.SetParameter("qDateTimeTo", pPeriodTo);
		vQry.SetParameter("qSalesDateTimeFrom", BegOfDay(pPeriodFrom));
		vQry.SetParameter("qSalesDateTimeTo", EndOfDay(pPeriodTo));
		vForecastStartDate = tcOnServer.GetForecastStartDate(vHotel);
		vQry.SetParameter("qForecastDateTimeFrom", Max(BegOfDay(pPeriodFrom), vForecastStartDate));
		vQry.SetParameter("qForecastDateTimeTo", ?(ValueIsFilled(pPeriodTo), Max(EndOfDay(pPeriodTo), EndOfDay(vForecastStartDate-24*3600)), '00010101'));

		vRoomInventoryBalances = vQry.Execute();
		
		vLastVacant = Undefined;
		vLastReserved = Undefined;
		vRoomInventoryBalancesDays = vRoomInventoryBalances.Select(QueryResultIteration.ByGroups, "Period", "ALL");
		While vRoomInventoryBalancesDays.Next() Do
			SetQueryResource(vRoomInventoryBalancesDays, vShowReportsInBeds, vLastVacant, vLastReserved);
			vResult.RoomsAvailableData.Add(?(vLastVacant = Undefined, 0, vLastVacant));
			vResult.RoomsOccupancyData.Add(?(vLastReserved = Undefined, 0, vLastReserved));
			
			If Not pShowByRoomType Then
				Continue;
			EndIf;
			
			vRoomInventoryBalancesGrupByField = vRoomInventoryBalancesDays.Select(QueryResultIteration.ByGroups, "GrupByField", "ALL");
			While vRoomInventoryBalancesGrupByField.Next() Do
				vRoomTypeBalancesRow = vRoomTypeBalances.Add();
				FillPropertyValues(vRoomTypeBalancesRow, vRoomInventoryBalancesGrupByField);
			EndDo;
		EndDo;
	EndIf;
	
	If pShowBookingsWithoutRooms And Not ValueIsFilled(pGuestGroup) And IsBlankString(pGuestStr) And Not ValueIsFilled(pSelCustomer) And IsBlankString(pSelCar) And Not ValueIsFilled(pRoom) And Not ValueIsFilled(pRoomSection) Then
		vRoomsAllList.Indexes.Add("Room");
		vRoomsAllList.Indexes.Add("Room, Recorder");
		
		vRecordersWithRoomEmptyArr = vRoomsAllList.FindRows(New Structure("Room", Catalogs.Rooms.EmptyRef()));
		vRecordersWithRoomEmpty = vRoomsAllList.Copy();
		vRecordersWithRoomEmpty.Clear();
		
		vNewRecordersWithRoom = vRecordersWithRoomEmpty.Copy();
		
		vPeriodFromEmpty = pPeriodFrom;
		vPeriodToEmpty = pPeriodTo;
		For Each vRoomRow In vRecordersWithRoomEmptyArr Do
			If ValueIsFilled(vRoomRow.PeriodFrom) Then
				vPeriodFromEmpty = Min(vPeriodFromEmpty, vRoomRow.PeriodFrom);
			EndIf;
			If ValueIsFilled(vRoomRow.PeriodTo) Then
				vPeriodToEmpty = Max(vPeriodToEmpty, vRoomRow.PeriodTo);
			EndIf;
			FillPropertyValues(vRecordersWithRoomEmpty.Add(), vRoomRow);
			vRoomsAllList.Delete(vRoomRow);
		EndDo;
		
		If vRecordersWithRoomEmpty.Count() > 0 Then
			vRecordersWithRoomEmpty.Indexes.Add("RoomType, IsMainRecorder");
			vRecordersWithRoomEmpty.Indexes.Add("RoomType, GuestGroup, DocumentNumber");
			
			vRoomTypesList = vRoomsAllList.Copy(, "Room");
			vRoomTypesList.GroupBy("Room");
			vRoomListArr = vRoomTypesList.UnloadColumn("Room");
			vDeleteRooms = New ValueList;
			
			vVacantPeriods = GetRoomsVacantPeriods(vRoomListArr, vPeriodFromEmpty, vPeriodToEmpty, pHotel);
			If vVacantPeriods.Count() > 0 Then
				vVacantPeriods.Indexes.Add("RoomType");
				
				For Each vRoomTypeRow In vRoomTypes Do
					vVacantPeriodsByRoomType = vVacantPeriods.FindRows(New Structure("RoomType", vRoomTypeRow));
					If vVacantPeriodsByRoomType.Count() <= 0 Then
						Continue;
					EndIf;
					
					vRecordersWithRoomEmptyArr = vRecordersWithRoomEmpty.FindRows(New Structure("RoomType, IsMainRecorder", vRoomTypeRow, True));
					If vRecordersWithRoomEmptyArr.Count() <= 0 Then
						Continue;
					EndIf;
					
					For Each vRecorderWithRoomEmptyRow In vRecordersWithRoomEmptyArr Do
						If vRecordersWithRoomEmpty.IndexOf(vRecorderWithRoomEmptyRow) = -1 Then
							Continue;
						EndIf;
						
						vCheckRoomsVacant = ValueIsFilled(vRecorderWithRoomEmptyRow.AccommodationType) And vRecorderWithRoomEmptyRow.AccommodationType = Enums.AccomodationTypes.Room;
						vRecordersByGuestGroup = vRecordersWithRoomEmpty.FindRows(New Structure("RoomType, GuestGroup, DocumentNumber", vRoomTypeRow, vRecorderWithRoomEmptyRow.GuestGroup, vRecorderWithRoomEmptyRow.DocumentNumber));
						
						vRecorderWithRoomEmptyPeriodFrom = vRecorderWithRoomEmptyRow.PeriodFrom;
						vRecorderWithRoomEmptyPeriodTo = vRecorderWithRoomEmptyRow.PeriodTo;
						For Each vRecorderByGuestGroupRow In vRecordersByGuestGroup Do
							vRecorderWithRoomEmptyPeriodFrom = Min(vRecorderWithRoomEmptyPeriodFrom, vRecorderByGuestGroupRow.PeriodFrom);
							vRecorderWithRoomEmptyPeriodTo = Max(vRecorderWithRoomEmptyPeriodTo, vRecorderByGuestGroupRow.PeriodTo);
						EndDo;
						
						While vRecorderWithRoomEmptyRow.BedsReserved > 0 Do
							vVacantPeriodRow = Undefined;
							
							For Each vVacantPeriodsRow In vVacantPeriodsByRoomType Do
								If vVacantPeriodsRow.VacantFromDate > vRecorderWithRoomEmptyPeriodFrom Or vVacantPeriodsRow.VacantToDate < vRecorderWithRoomEmptyPeriodTo Or
									vVacantPeriodsRow.RoomsVacant = 0 And vCheckRoomsVacant Then
									Continue;
								EndIf;
								
								vVacantPeriodRow = vVacantPeriodsRow;
								Break;
							EndDo;
							
							If vVacantPeriodRow = Undefined Then
								Break;
							EndIf;
							
							vRecordersWithRoom = vRoomsAllList.FindRows(New Structure("Room", vVacantPeriodRow.Room));
							If vRecordersWithRoom.Count() <= 0 Then
								Break;
							EndIf;
							
							vVacantPeriodIndex = vVacantPeriodsByRoomType.Find(vVacantPeriodRow);
							
							For Each vRecorderByGuestGroupRow In vRecordersByGuestGroup Do
								vNewRecordersWithRoomRow = vNewRecordersWithRoom.Add();
								FillPropertyValues(vNewRecordersWithRoomRow, vRecorderByGuestGroupRow);
								FillPropertyValues(vNewRecordersWithRoomRow, vRecordersWithRoom[0], "RoomType, GrupByFieldCode, GrupByFieldDescription, GrupByFieldSortCode, GrupByField, Room, RoomDescription, RoomPropertiesDescriptions, RoomPropertiesCodes, RoomStatusDescription, RoomColor, RoomStatusIcon, RoomSortCode, RoomTypeDescription, RoomTypeCode, RoomTypeSortCode, RoomParent");
							EndDo;
							
							If Not ValueIsFilled(vRecordersWithRoom[0].Recorder) And vDeleteRooms.FindByValue(vRecordersWithRoom[0].Room) = Undefined Then
								vDeleteRooms.Add(vRecordersWithRoom[0].Room);
							EndIf;
							
							vRoomsReserved = vRecorderWithRoomEmptyRow.RoomsReserved;
							vBedsReserved = vRecorderWithRoomEmptyRow.BedsReserved;
							If vBedsReserved > vVacantPeriodRow.BedsVacant Then
								vRoomsReserved = vVacantPeriodRow.RoomsVacant;
								vBedsReserved = vVacantPeriodRow.BedsVacant;
							EndIf;
							vRecorderWithRoomEmptyRow.RoomsReserved = vRecorderWithRoomEmptyRow.RoomsReserved - vRoomsReserved;
							vRecorderWithRoomEmptyRow.BedsReserved = vRecorderWithRoomEmptyRow.BedsReserved - vBedsReserved;
							If vVacantPeriodRow.VacantToDate > vRecorderWithRoomEmptyPeriodTo Then
								vRightVacantPeriodRow = vVacantPeriods.Add();
								FillPropertyValues(vRightVacantPeriodRow, vVacantPeriodRow);
								vRightVacantPeriodRow.VacantFromDate = vRecorderWithRoomEmptyPeriodTo;
								vVacantPeriodRow.VacantToDate = vRecorderWithRoomEmptyPeriodTo;
								vVacantPeriodsByRoomType.Insert(vVacantPeriodIndex + 1, vRightVacantPeriodRow);
							EndIf;
							
							vVacantPeriodRow.RoomsVacant = vVacantPeriodRow.RoomsVacant - vRoomsReserved;
							vVacantPeriodRow.BedsVacant = vVacantPeriodRow.BedsVacant - vBedsReserved;
							If vVacantPeriodRow.BedsVacant <= 0 Then
								vVacantPeriods.Delete(vVacantPeriodRow);
								vVacantPeriodsByRoomType.Delete(vVacantPeriodIndex);
							EndIf;
						EndDo;
						
						If vRecorderWithRoomEmptyRow.BedsReserved <= 0 Then
							For Each vRecorderByGuestGroupRow In vRecordersByGuestGroup Do
								vRecordersWithRoomEmpty.Delete(vRecorderByGuestGroupRow);
							EndDo;
						EndIf;
					EndDo;
				EndDo;
			EndIf;
			
			For Each vDeleteRoom In vDeleteRooms Do
				vRoomsWithRecordersEmpty = vRoomsAllList.FindRows(New Structure("Room, Recorder", vDeleteRoom.Value, NULL));
				For Each vRoomWithRecordersEmpty In vRoomsWithRecordersEmpty Do
					vRoomsAllList.Delete(vRoomWithRecordersEmpty);
				EndDo;
			EndDo;
		EndIf;
		
		For Each vNewRecorderWithRoomRow In vNewRecordersWithRoom Do
			FillPropertyValues(vRoomsAllList.Add(), vNewRecorderWithRoomRow);
		EndDo;
		
		For Each vRecorderWithRoomEmptyRow In vRecordersWithRoomEmpty Do
			FillPropertyValues(vRoomsAllList.Add(), vRecorderWithRoomEmptyRow);
		EndDo;
	EndIf;
	
	For Each vRecorderRow In vRoomsAllList Do
		If ValueIsFilled(vRecorderRow.Recorder) Then
			vRecorderRow.PeriodFrom = Max(vRecorderRow.PeriodFrom, pPeriodFrom);
			vRecorderRow.PeriodTo = ?(ValueIsFilled(vRecorderRow.PeriodTo), Min(vRecorderRow.PeriodTo, pPeriodTo), pPeriodTo);
		EndIf;
	EndDo;
	
	vRoomsAllList.Indexes.Clear();
	vRoomsAllList.Indexes.Add("RoomType, RoomDescription");
	vRoomsAllList.Indexes.Add("RoomType, GuestGroup, DocumentNumber, RoomDescription");
	For Each vRoomTypeRow In vRoomTypes Do
		vRecordersWithRoomEmpty = vRoomsAllList.FindRows(New Structure("RoomType, RoomDescription", vRoomTypeRow, ""));
		While vRecordersWithRoomEmpty.Count() > 0 Do
			vMaxDate = '00010101';
			For Each vRecorderWithRoomEmptyRow In vRecordersWithRoomEmpty Do
				If vMaxDate > vRecorderWithRoomEmptyRow.PeriodFrom Or Not IsBlankString(vRecorderWithRoomEmptyRow.RoomDescription) Then
					Continue;
				EndIf;
				vMaxDate = vRecorderWithRoomEmptyRow.PeriodTo;
				vRecorderWithRoomEmptyRow.NumberRoomEmpty = pNumberRoomEmpty;
				vRecorderWithRoomEmptyRow.RoomDescription = "#" + Format(pNumberRoomEmpty, "NFD=0;NZ=0;NG=");
				vRecordersByGuestGroup = vRoomsAllList.FindRows(New Structure("RoomType, GuestGroup, DocumentNumber, RoomDescription", vRoomTypeRow, vRecorderWithRoomEmptyRow.GuestGroup, vRecorderWithRoomEmptyRow.DocumentNumber, ""));
				For Each vRecorderByGuestGroupRow In vRecordersByGuestGroup Do
					vRecorderByGuestGroupRow.NumberRoomEmpty = vRecorderWithRoomEmptyRow.NumberRoomEmpty;
					vRecorderByGuestGroupRow.RoomDescription = vRecorderWithRoomEmptyRow.RoomDescription;
				EndDo;
				If vMaxDate = pPeriodFrom Then
					Break;
				EndIf;
			EndDo;
			pNumberRoomEmpty = pNumberRoomEmpty + 1;
			vRecordersWithRoomEmpty = vRoomsAllList.FindRows(New Structure("RoomType, RoomDescription", vRoomTypeRow, ""));
		EndDo;
	EndDo;
	
	vRoomsAllList.Sort("GrupByFieldSortCode, GrupByFieldDescription, RoomSortCode, NumberRoomEmpty, RoomDescription, PeriodFrom, PeriodTo, DocumentSortCode");
	
	vDoNotShowTooltipsInRoomsGanttChart = pHotel.DoNotShowTooltipsInRoomsGanttChart;
	
	If Not ValueIsFilled(pGuestGroup) And IsBlankString(pGuestStr) And Not ValueIsFilled(pSelCustomer) And IsBlankString(pSelCar) And Not ValueIsFilled(pRoom) And Not ValueIsFilled(pRoomSection) Then
		vGrupByFieldData = New Structure;
		vGrupByFieldData.Insert("id", "EVENTS");
		vGrupByFieldData.Insert("name", NStr("en = 'EVENTS';de = 'EREIGNISSE';ru = 'СОБЫТИЯ'"));
		vGrupByFieldData.Insert("roomsOccupancy", New Array);
		vGrupByFieldData.Insert("rooms", New Array);
		
		vQ = New Query;
		vQ.Text =
		"SELECT
		|	Events.Ref AS Event,
		|	Events.Description AS Description,
		|	Events.DateFrom AS DateFrom,
		|	Events.DateTo AS DateTo,
		|	Events.Remarks AS Remarks,
		|	Events.ColorHexString AS ColorHexString
		|FROM
		|	Catalog.Events AS Events
		|WHERE
		|	NOT Events.DeletionMark
		|	AND NOT Events.IsFolder
		|	AND NOT Events.DoNotShowInRoomsGanttChart
		|	AND Events.Hotel = &qHotel
		|	AND Events.DateFrom <= &qDateTimeTo
		|	AND Events.DateTo >= &qDateTimeFrom
		|
		|UNION ALL
		|
		|SELECT
		|	Events.Ref,
		|	Events.Description,
		|	Events.DateFrom,
		|	Events.DateTo,
		|	Events.Remarks,
		|	Events.ColorHexString
		|FROM
		|	Catalog.Events AS Events
		|WHERE
		|	NOT Events.DeletionMark
		|	AND NOT Events.IsFolder
		|	AND NOT Events.DoNotShowInRoomsGanttChart
		|	AND Events.Hotel = VALUE(Catalog.Hotels.EmptyRef)
		|	AND Events.DateFrom <= &qDateTimeTo
		|	AND Events.DateTo >= &qDateTimeFrom";
		vQ.SetParameter("qHotel", pHotel);
		vQ.SetParameter("qDateTimeTo", pPeriodTo);
		vQ.SetParameter("qDateTimeFrom", pPeriodFrom);
		vEvents = vQ.Execute().Unload();
		
		If vEvents.Count() > 0 Then
			vRooms = New Array;
			
			vRoomData = New Structure;
			vRoomData.Insert("id", "REVENTS");
			vRoomData.Insert("isVirtual", True);
			vRoomData.Insert("room", "");
			vRoomData.Insert("color", "");
			vRoomData.Insert("roomType", "");
			vRoomData.Insert("RoomProperties", "");
			vRoomData.Insert("RoomPropertiesCodes", "");
			vRoomData.Insert("statusText", "");
			vRoomData.Insert("statusIcon", Undefined);
			
			vZones = New Array;
			For Each vEventRow In vEvents Do
				vEvent = New Structure;
				vEvent.Insert("id", "Z" + Format(pRecordersNumber, "NZ=0;NG="));
				vEvent.Insert("UUID", TrimAll(vEventRow.Event.UUID()));
				vEvent.Insert("startDate", (BegOfDay(Max(vEventRow.DateFrom, pPeriodFrom)) - '19700101') * 1000);
				vEvent.Insert("endDate", (EndOfDay(Min(vEventRow.DateTo, pPeriodTo)) - '19700101') * 1000);
				vEvent.Insert("start", (BegOfDay(vEventRow.DateFrom) - '19700101'));
				vEvent.Insert("end", (EndOfDay(vEventRow.DateTo) - '19700101'));
				vEvent.Insert("debtText", "");
				vEvent.Insert("isByBankTransfer", False);
				vEvent.Insert("isDraggable", False);
				vEvent.Insert("IsReservation", False);
				vEvent.Insert("type", "event-zone");
				vEvent.Insert("color", TrimAll(vEventRow.ColorHexString));
				vEvent.Insert("name", TrimAll(vEventRow.Description));
				vEvent.Insert("isBirthday", False);
				vEvent.Insert("customer", "");
				vEvent.Insert("relocateFrom", "");
				vEvent.Insert("relocateTo", "");
				
				If Not vDoNotShowTooltipsInRoomsGanttChart Then
					vEvent.Insert("toolTip", GetToolTipByEvent(vEventRow));
				EndIf;
				
				vZones.Add(vEvent);
				pRecordersNumber = pRecordersNumber + 1;
			EndDo;
			
			vRoomData.Insert("zones", vZones);
			vRooms.Add(vRoomData);
			vGrupByFieldData.Insert("rooms", vRooms);
		EndIf;
		
		vResult.RoomTypesData.Add(vGrupByFieldData);
	EndIf;
	
	vCreateWithourRoom = False;
	
	vPhoneNumbers = cmGetPhoneNumbers(pHotel);
	
	If pShowByRoomType Then
		FillRoomTypesDataByRoomType(vRoomsAllList, vRoomTypeBalances, vResult.RoomTypesData, pHotel, vShowReportsInBeds, pScale, pShowRoomPropertiesCodes, pRecordersNumber, vDoNotShowTooltipsInRoomsGanttChart, vPhoneNumbers, pOrderBasket);
	Else
		FillRoomTypesDataByParent(vRoomsAllList, vRoomTypeBalances, vResult.RoomTypesData, pHotel, vShowReportsInBeds, pScale, pShowRoomPropertiesCodes, pRecordersNumber, vDoNotShowTooltipsInRoomsGanttChart, vCreateWithourRoom, vPhoneNumbers, pOrderBasket);
	EndIf;
	
	If Not pShowByRoomType And Not vCreateWithourRoom And Not ValueIsFilled(pGuestGroup) And IsBlankString(pGuestStr) And Not ValueIsFilled(pSelCustomer) And IsBlankString(pSelCar) And Not ValueIsFilled(pRoom) And Not ValueIsFilled(pRoomSection) Then
		vGrupByFieldData = New Structure;
		vGrupByFieldData.Insert("id", "RTWRT");
		vGrupByFieldData.Insert("name", NStr("en = 'BOOKINGS WITHOUT ROOM';de = 'BUCHUNGEN OHNE ZIMMERNUMMER';ru = 'БРОНИ БЕЗ НОМЕРА КОМНАТЫ'"));
		vGrupByFieldData.Insert("roomsOccupancy", New Array);
		vGrupByFieldData.Insert("rooms", New Array);
		vResult.RoomTypesData.Add(vGrupByFieldData);
	EndIf;
	
	Return MapToJson(vResult);
EndFunction // FillRooms

// ----------------------------------------------------------------------------
&AtServerNoContext
Function MapToJson(pMap)
	vJSONWriter = New JSONWriter;
	vJSONWriter.SetString();
	WriteJSON(vJSONWriter, pMap);
	Return vJSONWriter.Close();
EndFunction // MapToJson

// -----------------------------------------------------------------------------
&AtClient
Function JsonToMap(pJson)
	vResult = New Structure;
	#If Not WebClient Then
		vJSONReader = New JSONReader;
		vJSONReader.SetString(pJson);
		vMap = ReadJSON(vJSONReader);
		vJSONReader.Close();
		Return vMap;
	#EndIf
	Return vResult;
EndFunction // JsonToMap

// -----------------------------------------------------------------------------
&AtServerNoContext
Function JsonToMapAtServer(pJson)
	vJSONReader = New JSONReader;
	vJSONReader.SetString(pJson);
	vMap = ReadJSON(vJSONReader);
	vJSONReader.Close();
	Return vMap;
EndFunction // JsonToMap

// ----------------------------------------------------------------------------
&AtServerNoContext
Procedure FillRoomTypesDataByRoomType(pRoomsAllList, pRoomTypeBalances, pRoomTypesData, pHotel, pShowReportsInBeds, pScale, pShowRoomPropertiesCodes, pRecordersNumber, pDoNotShowTooltipsInRoomsGanttChart, pPhoneNumbers, pOrderBasket)
	vGrupByField = Undefined;
	vGrupByFieldData = Undefined;
	vRoom = Undefined;
	vRoomDescription = Undefined;
	vRoomData = Undefined;
	vIsFirstRow = True;
	For Each vRoomRow In pRoomsAllList Do
		If vRoom <> vRoomRow.Room Or vRoomDescription <> vRoomRow.RoomDescription Then
			If vRoomData <> Undefined Then
				vGrupByFieldData.rooms.Add(vRoomData);
			EndIf;
			vRoom = vRoomRow.Room;
			vRoomDescription = vRoomRow.RoomDescription;
			
			vRoomData = FillRoomData(vRoomRow, pShowRoomPropertiesCodes, pPhoneNumbers);
			vIsFirstRow = True;
		EndIf;
		
		If vRoomRow.GrupByField <> vGrupByField Then
			If vGrupByFieldData <> Undefined Then
				pRoomTypesData.Add(vGrupByFieldData);
			EndIf;
			vGrupByField = vRoomRow.GrupByField;
			
			vGrupByFieldData = FillGrupByFieldData(vRoomRow, vGrupByField, pHotel, pRoomTypeBalances, pScale, pShowReportsInBeds);
		EndIf;
		
		If ValueIsFilled(vRoom) And vIsFirstRow Then
			vOrderBasketRows = pOrderBasket[TrimAll(vRoom.UUID())];
			If vOrderBasketRows <> Undefined Then
				For Each vOrderBasketRow In vOrderBasketRows Do
					vRoomData.zones.Add(FillOrderBasketData(vOrderBasketRow, pRecordersNumber));
				EndDo;
			EndIf;
			vIsFirstRow = False;
		EndIf;
		
		If Not ValueIsFilled(vRoomRow.Recorder) Then
			Continue;
		EndIf;
		
		vRoomData.zones.Add(FillRecorderData(vRoomRow, pRecordersNumber, pDoNotShowTooltipsInRoomsGanttChart));
	EndDo;
	
	If vRoomData <> Undefined Then
		vGrupByFieldData.rooms.Add(vRoomData);
	EndIf;
	
	If vGrupByFieldData <> Undefined Then
		pRoomTypesData.Add(vGrupByFieldData);
	EndIf;
EndProcedure // FillRoomTypesDataByRoomType

// ----------------------------------------------------------------------------
&AtServerNoContext
Procedure FillRoomTypesDataByParent(pRoomsAllList, pRoomTypeBalances, pRoomTypesData, pHotel, pShowReportsInBeds, pScale, pShowRoomPropertiesCodes, pRecordersNumber, pDoNotShowTooltipsInRoomsGanttChart, pCreateWithourRoom, pPhoneNumbers, pOrderBasket)
	vRoomParents = GetRoomParentsByOwner(pHotel);
	
	vRecordersWithGrupByFieldsEmptyRows = pRoomsAllList.FindRows(New Structure("GrupByField", Catalogs.Rooms.EmptyRef()));
	If vRecordersWithGrupByFieldsEmptyRows.Count() > 0 Then
		vGrupByFieldData = Undefined;
		vRoom = Undefined;
		vRoomDescription = Undefined;
		vRoomData = Undefined;
		vIsFirstRow = True;
		
		vGrupByFieldData = FillGrupByFieldData(vRecordersWithGrupByFieldsEmptyRows[0], Catalogs.Rooms.EmptyRef(), pHotel, pRoomTypeBalances, pScale, pShowReportsInBeds, pCreateWithourRoom);
		For Each vRecordersWithGrupByFieldEmptyRow In vRecordersWithGrupByFieldsEmptyRows Do
			If vRoom <> vRecordersWithGrupByFieldEmptyRow.Room Or vRoomDescription <> vRecordersWithGrupByFieldEmptyRow.RoomDescription Then
				If vRoomData <> Undefined Then
					vGrupByFieldData.rooms.Add(vRoomData);
				EndIf;
				vRoom = vRecordersWithGrupByFieldEmptyRow.Room;
				vRoomDescription = vRecordersWithGrupByFieldEmptyRow.RoomDescription;
				
				vRoomData = FillRoomData(vRecordersWithGrupByFieldEmptyRow, pShowRoomPropertiesCodes, pPhoneNumbers);
				vIsFirstRow = True
			EndIf;
			
			If ValueIsFilled(vRoom) And vIsFirstRow Then
				vOrderBasketRows = pOrderBasket[TrimAll(vRoom.UUID())];
				If vOrderBasketRows <> Undefined Then
					For Each vOrderBasketRow In vOrderBasketRows Do
						vRoomData.zones.Add(FillOrderBasketData(vOrderBasketRow, pRecordersNumber));
					EndDo;
				EndIf;
				vIsFirstRow = False;
			EndIf;
			
			If Not ValueIsFilled(vRecordersWithGrupByFieldEmptyRow.Recorder) Then
				Continue;
			EndIf;
			
			vRoomData.zones.Add(FillRecorderData(vRecordersWithGrupByFieldEmptyRow, pRecordersNumber, pDoNotShowTooltipsInRoomsGanttChart));
		EndDo;
		If vRoomData <> Undefined Then
			vGrupByFieldData.rooms.Add(vRoomData);
		EndIf;
		
		pRoomTypesData.Add(vGrupByFieldData);
	EndIf;
	
	vParentsLevel = -1;
	vMainRoomParentsRows = vRoomParents.FindRows(New Structure("level", 0));
	For Each vMainRoomParentRow In vMainRoomParentsRows Do
		vGrupByFieldData = FillGrupByFieldDataByPatent(vRoomParents, vMainRoomParentRow, pRoomsAllList, pRoomTypeBalances, pHotel, pShowReportsInBeds, pScale, pShowRoomPropertiesCodes, pRecordersNumber, pDoNotShowTooltipsInRoomsGanttChart, pCreateWithourRoom, vParentsLevel, pPhoneNumbers, pOrderBasket);
		If vGrupByFieldData <> Undefined Then
			pRoomTypesData.Add(vGrupByFieldData);
		EndIf;
	EndDo;
	
	vRecordersWithGrupByRoomEmptyRows = pRoomsAllList.FindRows(New Structure("GrupByField", NULL));
	If vRecordersWithGrupByRoomEmptyRows.Count() > 0 Then
		vGrupByFieldData = Undefined;
		vRoom = Undefined;
		vRoomDescription = Undefined;
		vRoomData = Undefined;
		vIsFirstRow = True;
		
		vGrupByFieldData = FillGrupByFieldData(vRecordersWithGrupByRoomEmptyRows[0], NULL, pHotel, pRoomTypeBalances, pScale, pShowReportsInBeds, pCreateWithourRoom);
		For Each vRecordersWithGrupByRoomEmptyRow In vRecordersWithGrupByRoomEmptyRows Do
			If vRoom <> vRecordersWithGrupByRoomEmptyRow.Room Or vRoomDescription <> vRecordersWithGrupByRoomEmptyRow.RoomDescription Then
				If vRoomData <> Undefined Then
					vGrupByFieldData.rooms.Add(vRoomData);
				EndIf;
				vRoom = vRecordersWithGrupByRoomEmptyRow.Room;
				vRoomDescription = vRecordersWithGrupByRoomEmptyRow.RoomDescription;
				
				vRoomData = FillRoomData(vRecordersWithGrupByRoomEmptyRow, pShowRoomPropertiesCodes, pPhoneNumbers);
				vIsFirstRow = True;
			EndIf;
			
			If ValueIsFilled(vRoom) And vIsFirstRow Then
				vOrderBasketRows = pOrderBasket[TrimAll(vRoom.UUID())];
				If vOrderBasketRows <> Undefined Then
					For Each vOrderBasketRow In vOrderBasketRows Do
						vRoomData.zones.Add(FillOrderBasketData(vOrderBasketRow, pRecordersNumber));
					EndDo;
				EndIf;
				vIsFirstRow = False;
			EndIf;
			
			If Not ValueIsFilled(vRecordersWithGrupByRoomEmptyRow.Recorder) Then
				Continue;
			EndIf;
			
			vRoomData.zones.Add(FillRecorderData(vRecordersWithGrupByRoomEmptyRow, pRecordersNumber, pDoNotShowTooltipsInRoomsGanttChart));
		EndDo;
		If vRoomData <> Undefined Then
			vGrupByFieldData.rooms.Add(vRoomData);
		EndIf;
		
		pRoomTypesData.Add(vGrupByFieldData);
	EndIf;
EndProcedure // FillRoomTypesDataByOwner

// ----------------------------------------------------------------------------
&AtServerNoContext
Function GetRoomParentsByOwner(pHotel)
	vQ = New Query;
	vQ.Text =
	"SELECT
	|	Rooms.Ref AS Ref,
	|	Rooms.Parent AS Parent,
	|	Rooms.SortCode AS SortCode,
	|	CASE
	|		WHEN Rooms.Parent = VALUE(Catalog.Rooms.EmptyRef)
	|			THEN 0
	|		ELSE 1
	|	END AS level,
	|	Rooms.Description AS GrupByFieldDescription
	|FROM
	|	Catalog.Rooms AS Rooms
	|WHERE
	|	NOT Rooms.DeletionMark
	|	AND Rooms.IsFolder
	|	AND Rooms.Owner = &qHotel
	|
	|ORDER BY
	|	level,
	|	SortCode";
	vQ.SetParameter("qHotel", pHotel);
	Return vQ.Execute().Unload();
EndFunction // GetRoomParentsByOwner

// ----------------------------------------------------------------------------
&AtServerNoContext
Function FillGrupByFieldDataByPatent(pRoomParents, pMainRoomParentRow, pRoomsAllList, pRoomTypeBalances, pHotel, pShowReportsInBeds, pScale, pShowRoomPropertiesCodes, pRecordersNumber, pDoNotShowTooltipsInRoomsGanttChart, pCreateWithourRoom, pParentsLevel, pPhoneNumbers, pOrderBasket)
	vRoomParentsRows = pRoomParents.FindRows(New Structure("Parent", pMainRoomParentRow.Ref));
	vRoomParentsRowIndex = 0;
	vRoomParentsRowsCount = vRoomParentsRows.Count();
	vParentsLevel = pParentsLevel + 1;
	
	vRecordersWithGrupByRoomEmptyRows = pRoomsAllList.FindRows(New Structure("GrupByField", pMainRoomParentRow.Ref));
	If vRecordersWithGrupByRoomEmptyRows.Count() > 0 Then
		vGrupByFieldData = Undefined;
		vRoom = Undefined;
		vRoomDescription = Undefined;
		vRoomData = Undefined;
		vIsFirstRow = True;
		
		vGrupByFieldData = FillGrupByFieldData(pMainRoomParentRow, pMainRoomParentRow.Ref, pHotel, pRoomTypeBalances, pScale, pShowReportsInBeds, pCreateWithourRoom, vParentsLevel);
		For Each vRecordersWithGrupByRoomEmptyRow In vRecordersWithGrupByRoomEmptyRows Do
			While vRoomParentsRowIndex <= vRoomParentsRowsCount -1 Do
				If vRoomParentsRows[vRoomParentsRowIndex].SortCode > vRecordersWithGrupByRoomEmptyRow.RoomSortCode Then
					Break;
				EndIf;
				
				vRoomParentsData = FillGrupByFieldDataByPatent(pRoomParents, vRoomParentsRows[vRoomParentsRowIndex], pRoomsAllList, pRoomTypeBalances, pHotel, pShowReportsInBeds, pScale, pShowRoomPropertiesCodes, pRecordersNumber, pDoNotShowTooltipsInRoomsGanttChart, pCreateWithourRoom, vParentsLevel, pPhoneNumbers, pOrderBasket);
				If vRoomParentsData <> Undefined Then
					vGrupByFieldData.rooms.Add(vRoomParentsData);
				EndIf;
				vRoomParentsRowIndex = vRoomParentsRowIndex + 1;
			EndDo;
			
			If vRoom <> vRecordersWithGrupByRoomEmptyRow.Room Or vRoomDescription <> vRecordersWithGrupByRoomEmptyRow.RoomDescription Then
				If vRoomData <> Undefined Then
					vGrupByFieldData.rooms.Add(vRoomData);
				EndIf;
				vRoom = vRecordersWithGrupByRoomEmptyRow.Room;
				vRoomDescription = vRecordersWithGrupByRoomEmptyRow.RoomDescription;
				
				vRoomData = FillRoomData(vRecordersWithGrupByRoomEmptyRow, pShowRoomPropertiesCodes, pPhoneNumbers);
				vIsFirstRow = True;
			EndIf;
			
			If ValueIsFilled(vRoom) And vIsFirstRow Then
				vOrderBasketRows = pOrderBasket[TrimAll(vRoom.UUID())];
				If vOrderBasketRows <> Undefined Then
					For Each vOrderBasketRow In vOrderBasketRows Do
						vRoomData.zones.Add(FillOrderBasketData(vOrderBasketRow, pRecordersNumber));
					EndDo;
				EndIf;
				vIsFirstRow = False;
			EndIf;
			
			If Not ValueIsFilled(vRecordersWithGrupByRoomEmptyRow.Recorder) Then
				Continue;
			EndIf;
			
			vRoomData.zones.Add(FillRecorderData(vRecordersWithGrupByRoomEmptyRow, pRecordersNumber, pDoNotShowTooltipsInRoomsGanttChart));
		EndDo;
		
		If vRoomData <> Undefined Then
			vGrupByFieldData.rooms.Add(vRoomData);
		EndIf;
	EndIf;
	
	If vGrupByFieldData = Undefined Then
		vGrupByFieldData = FillGrupByFieldData(pMainRoomParentRow, pMainRoomParentRow.Ref, pHotel, pRoomTypeBalances, pScale, pShowReportsInBeds, pCreateWithourRoom, vParentsLevel);
	EndIf;
	
	For vNumber = vRoomParentsRowIndex To vRoomParentsRowsCount - 1 Do
		vRoomParentsData = FillGrupByFieldDataByPatent(pRoomParents, vRoomParentsRows[vNumber], pRoomsAllList, pRoomTypeBalances, pHotel, pShowReportsInBeds, pScale, pShowRoomPropertiesCodes, pRecordersNumber, pDoNotShowTooltipsInRoomsGanttChart, pCreateWithourRoom, vParentsLevel, pPhoneNumbers, pOrderBasket);
		If vRoomParentsData <> Undefined Then
			vGrupByFieldData.rooms.Add(vRoomParentsData);
		EndIf;
	EndDo;
	
	If vGrupByFieldData = Undefined Or vGrupByFieldData.rooms.Count() <= 0 Then
		Return Undefined;
	EndIf;
	
	Return vGrupByFieldData;
EndFunction // FillGrupByFieldDataByMainPatent

// ----------------------------------------------------------------------------
&AtServerNoContext
Function FillGrupByFieldData(pRoomRow, pGrupByField, pHotel, pRoomTypeBalances, pScale, pShowReportsInBeds, pCreateWithourRoom = False, pParentsLevel = 0)
	vGrupByFieldData = New Structure;
	vGrupByFieldData.Insert("isRoomType", True);
	vGrupByFieldData.Insert("level", pParentsLevel);
	
	If ValueIsFilled(pGrupByField) Then
		vGrupByFieldData.Insert("id", "RT" + TrimAll(pGrupByField.UUID()));
	ElsIf pGrupByField <> NULL Then
		vGrupByFieldData.Insert("id", "RTEMPTY");
	Else
		vGrupByFieldData.Insert("id", "RTWRT");
	EndIf;
	If ValueIsFilled(pGrupByField) Then
		vGrupByFieldData.Insert("name", TrimAll(pRoomRow.GrupByFieldDescription));
	ElsIf pGrupByField <> NULL Then
		vGrupByFieldData.Insert("name", TrimAll(pHotel));
	Else
		vGrupByFieldData.Insert("name", NStr("en = 'BOOKINGS WITHOUT ROOM';de = 'BUCHUNGEN OHNE ZIMMERNUMMER';ru = 'БРОНИ БЕЗ НОМЕРА КОМНАТЫ'"));
		pCreateWithourRoom = True;
	EndIf;
	vRoomTypeAvailableData = New Array;
	If pScale <> "day" And pGrupByField <> NULL Then
		vRoomTypeBalancesArr = pRoomTypeBalances.FindRows(New Structure("GrupByField", pGrupByField));
		vLastVacant = Undefined;
		For Each vRoomTypeBalancesRow In vRoomTypeBalancesArr Do
			SetQueryResource(vRoomTypeBalancesRow, pShowReportsInBeds, vLastVacant, Undefined);
			vRoomTypeAvailableData.Add(?(vLastVacant = Undefined, 0, vLastVacant));
		EndDo;
	EndIf;
	vGrupByFieldData.Insert("roomsOccupancy", vRoomTypeAvailableData);
	vGrupByFieldData.Insert("rooms", New Array);
	Return vGrupByFieldData;
EndFunction // FillGrupByFieldData

// ----------------------------------------------------------------------------
&AtServerNoContext
Function FillRoomData(pRoomRow, pShowRoomPropertiesCodes, pPhoneNumbers)
	vRoomData = New Structure;
	
	If ValueIsFilled(pRoomRow.Room) Then
		vRoomData.Insert("id", "R" + TrimAll(pRoomRow.RoomType.UUID()) + "_" + TrimAll(pRoomRow.Room.UUID()));
	Else
		vRoomData.Insert("id", "R" + TrimAll(pRoomRow.RoomType.UUID()) + "_" + TrimAll(New UUID()));
	EndIf;
	
	vPhonesDescr = "";
	vRoomPhones = pPhoneNumbers.FindRows(New Structure("Room", pRoomRow.Room));
	For Each vRoomPhonesRow In vRoomPhones Do
		If Upper(TrimAll(vRoomPhonesRow.PhoneNumber)) <> Upper(TrimAll(pRoomRow.RoomDescription)) Then
			If IsBlankString(vPhonesDescr) Then
				If Not IsBlankString(pRoomRow.RoomPropertiesDescriptions) Then
					vPhonesDescr = Chars.LF + NStr("en='Ph.'; ru='Тел.'; de='Tel.'") + " " + TrimAll(vRoomPhonesRow.PhoneNumber);
				Else
					vPhonesDescr = NStr("en='Ph.'; ru='Тел.'; de='Tel.'") + " " + TrimAll(vRoomPhonesRow.PhoneNumber);
				EndIf;
			Else
				vPhonesDescr = vPhonesDescr + ", " + TrimAll(vRoomPhonesRow.PhoneNumber);
			EndIf;
		EndIf;
	EndDo;
	
	vRoomData.Insert("isVirtual", Not ValueIsFilled(pRoomRow.Room));
	vRoomData.Insert("room", TrimAll(pRoomRow.RoomDescription));
	vRoomData.Insert("color", TrimAll(pRoomRow.RoomColor));
	vRoomData.Insert("roomType", TrimAll(pRoomRow.RoomTypeCode));
	If pShowRoomPropertiesCodes Then
		If Not IsBlankString(pRoomRow.RoomPropertiesCodes) Then
			vRoomData.Insert("RoomPropertiesCodes", "("+ StrReplace(TrimAll(pRoomRow.RoomPropertiesCodes), Chars.LF, ", ") + ")" + vPhonesDescr);
		Else
			vRoomData.Insert("RoomPropertiesCodes", vPhonesDescr);
		EndIf;
	EndIf;
	vRoomData.Insert("RoomProperties", TrimAll(pRoomRow.RoomPropertiesDescriptions) + vPhonesDescr);
	
	vRoomData.Insert("statusText", TrimAll(pRoomRow.RoomStatusDescription));
	If pRoomRow.RoomStatusIcon = Enums.RoomStatusesIcons.Vacant Then
		vRoomData.Insert("statusIcon", "availableCleanIcon");
	ElsIf pRoomRow.RoomStatusIcon = Enums.RoomStatusesIcons.Occupied Then
		vRoomData.Insert("statusIcon", "occupiedCleanIcon");
	ElsIf pRoomRow.RoomStatusIcon = Enums.RoomStatusesIcons.OccupiedDirty Then
		vRoomData.Insert("statusIcon", "occupiedDirtyIcon");
	ElsIf pRoomRow.RoomStatusIcon = Enums.RoomStatusesIcons.CheckOut Or pRoomRow.RoomStatusIcon = Enums.RoomStatusesIcons.TidyingUp Then
		vRoomData.Insert("statusIcon", "availableDirtyIcon");
	ElsIf pRoomRow.RoomStatusIcon = Enums.RoomStatusesIcons.Malfunction Or pRoomRow.RoomStatusIcon = Enums.RoomStatusesIcons.Repair Then
		vRoomData.Insert("statusIcon", "malfunctionIcon");
	ElsIf pRoomRow.RoomStatusIcon = Enums.RoomStatusesIcons.Waiting Then
		vRoomData.Insert("statusIcon", "waiting");
	Else
		vRoomData.Insert("statusIcon", Undefined);
	EndIf;
	vRoomData.Insert("zones", New Array);
	Return vRoomData;
EndFunction // FillRoomData

// ----------------------------------------------------------------------------
&AtServerNoContext
Function FillOrderBasketData(pRoomRow, pRecordersNumber)
	vRecorder = New Structure;
	vRecorder.Insert("id", "Z" + Format(pRecordersNumber, "NZ=0;NG="));
	vRecorder.Insert("UUID", TrimAll(pRoomRow["UUID"]));
	vRecorder.Insert("startDate", (pRoomRow["CheckInDate"] - '19700101') * 1000);
	vRecorder.Insert("endDate", (pRoomRow["CheckOutDate"] - '19700101') * 1000);
	vRecorder.Insert("start", (pRoomRow["CheckInDate"] - '19700101'));
	vRecorder.Insert("end", (pRoomRow["CheckOutDate"] - '19700101'));
	
	pRecordersNumber = pRecordersNumber + 1;
	
	vBalanceIsZero = True;
	
	vDebtText = cmFormatSum(pRoomRow["Amount"], pRoomRow["Currency"]);
	vRecorder.Insert("debtText", vDebtText);
	
	vRecorder.Insert("isByBankTransfer", False);
	vRecorder.Insert("isDraggable", False);
	vRecorder.Insert("IsClosedForEdit", False);
	vRecorder.Insert("IsReservation", False);
	vRecorder.Insert("type", "newZone");
	vRecorder.Insert("color", "");
	vRecorder.Insert("isBirthday", False);
	vRecorder.Insert("name", Format(pRoomRow["Adults"], "NFD=0; NZ=; NG=") + "/" + Format(pRoomRow["Kids"], "NFD=0; NZ=; NG="));
	
	vRecorder.Insert("customer", "");
	
	vRelocateFrom = "";
	vRecorder.Insert("relocateFrom", vRelocateFrom);
	
	vRelocateTo = "";
	vRecorder.Insert("relocateTo", vRelocateTo);
	Return vRecorder;
EndFunction // FillOrderBasketData

// ----------------------------------------------------------------------------
&AtServerNoContext
Function FillRecorderData(pRoomRow, pRecordersNumber, pDoNotShowTooltipsInRoomsGanttChart)
	vRecorder = New Structure;
	vRecorder.Insert("id", "Z" + Format(pRecordersNumber, "NZ=0;NG="));
	vRecorder.Insert("UUID", TrimAll(pRoomRow.Recorder.UUID()));
	vRecorder.Insert("startDate", (pRoomRow.PeriodFrom - '19700101') * 1000);
	vRecorder.Insert("endDate", (pRoomRow.PeriodTo - '19700101') * 1000);
	vRecorder.Insert("start", (pRoomRow.PeriodFromPresentation - '19700101'));
	vRecorder.Insert("end", (pRoomRow.PeriodToPresentation - '19700101'));
	
	pRecordersNumber = pRecordersNumber + 1;
	
	vBalanceIsZero = True;
	
	vDebtText = "";
	vDebtToolTip = "";
	If Not pRoomRow.IsBlocking Then
		If pRoomRow.ClientSumBalance > 0 Then
			vDebtText = vDebtText + " - " + NStr("en='Debt: ';ru='Долг: ';de='Schuld: '") + Format(pRoomRow.ClientSumBalance, "NFD=2;NZ=");
			If Not pDoNotShowTooltipsInRoomsGanttChart Then
				vDebtToolTip = vDebtToolTip + Chars.LF + NStr("en='Debt: ';ru='Долг: ';de='Schuld: '") + Format(pRoomRow.ClientSumBalance, "NFD=2;NZ=");
			EndIf;
			If pRoomRow.ClientLimitBalance < pRoomRow.ClientSumBalance Then
				vBalanceIsZero = False;
			EndIf;
		ElsIf pRoomRow.ClientSumBalance < 0 Then
			vDebtText = vDebtText + " - " + NStr("en='Advance: ';ru='Предоплата: ';de='Vorauszahlung: '") + Format(-pRoomRow.ClientSumBalance, "NFD=2;NZ=");
			If Not pDoNotShowTooltipsInRoomsGanttChart Then
				vDebtToolTip = vDebtToolTip + Chars.LF + NStr("en='Advance: ';ru='Предоплата: ';de='Vorauszahlung: '") + Format(-pRoomRow.ClientSumBalance, "NFD=2;NZ=");
			EndIf;
		ElsIf pRoomRow.CustomerSumBalance < 0 Then
			vDebtText = vDebtText + " - " + NStr("en='Customer advance: ';ru='Предоплата контрагентом: ';de='Vorauszahlung vom Firma: '") + Format(-pRoomRow.CustomerSumBalance, "NFD=2;NZ=");
			If Not pDoNotShowTooltipsInRoomsGanttChart Then
				vDebtToolTip = vDebtToolTip + Chars.LF + NStr("en='Customer advance: ';ru='Предоплата контрагентом: ';de='Vorauszahlung vom Firma: '") + Format(-pRoomRow.CustomerSumBalance, "NFD=2;NZ=");
			EndIf;
		EndIf;
		If pRoomRow.ClientLimitBalance <> 0 Then
			vDebtText = vDebtText + ", " + NStr("en='Preauth.: ';ru='Преавт.: ';de='Voraut.: '") + Format(pRoomRow.ClientLimitBalance, "NFD=2;NZ=");
			If Not pDoNotShowTooltipsInRoomsGanttChart Then
				vDebtToolTip = vDebtToolTip + Chars.LF + NStr("en='Preauthorized: ';ru='Преавторизовано: ';de='Vorautorisiert: '") + Format(pRoomRow.ClientLimitBalance, "NFD=2;NZ=");
			EndIf;
		ElsIf pRoomRow.CustomerLimitBalance <> 0 Then
			vDebtText = vDebtText + ", " + NStr("en='Customer preauth.: ';ru='Преавт. контрагентом: ';de='Voraut. vom Firma: '") + Format(pRoomRow.CustomerLimitBalance, "NFD=2;NZ=");
			If Not pDoNotShowTooltipsInRoomsGanttChart Then
				vDebtToolTip = vDebtToolTip + Chars.LF + NStr("en='Preauthorized by customer: ';ru='Преавторизовано контрагентом: ';de='Vorautorisiert vom Firma: '") + Format(pRoomRow.CustomerLimitBalance, "NFD=2;NZ=");
			EndIf;
		EndIf;
	EndIf;
	vRecorder.Insert("debtText", vDebtText);
	
	vRecorder.Insert("isByBankTransfer", False);
	If Not pRoomRow.IsIndividual And pRoomRow.IsByBankTransfer Then
		vRecorder.Insert("isByBankTransfer", True)
	EndIf;
	
	vRecorder.Insert("isDraggable", False);
	vRecorder.Insert("IsClosedForEdit", False);
	vRecorder.Insert("IsReservation", False);
	If pRoomRow.IsBlocking Then
		vRecorder.Insert("type", "repair");
	ElsIf pRoomRow.IsReservation Then
		vRecorder.Insert("isDraggable", Not pRoomRow.IsClosedForEdit);
		vRecorder.Insert("IsClosedForEdit", pRoomRow.IsClosedForEdit);
		vRecorder.Insert("IsReservation", True);
		//If Not vBalanceIsZero Then
		//	vRecorder.Insert("type", "booked-debt");
		//ElsIf pRoomRow.IsGuaranteed Then
		If pRoomRow.IsGuaranteed Then
			vRecorder.Insert("type", "booked-guaranteed");
		Else
			vRecorder.Insert("type", "booked");
		EndIf;
	ElsIf pRoomRow.IsAccommodation And pRoomRow.IsInHouse Then
		vRecorder.Insert("isDraggable", Not pRoomRow.IsClosedForEdit);
		vRecorder.Insert("IsClosedForEdit", pRoomRow.IsClosedForEdit);
		If Not vBalanceIsZero Then
			vRecorder.Insert("type", "living-debt");
		Else
			vRecorder.Insert("type", "living");
		EndIf;
	ElsIf pRoomRow.IsAccommodation And Not pRoomRow.IsInHouse Then
		vRecorder.Insert("type", "leave");
	EndIf;
	
	If pRoomRow.IsBlocking Then
		vRecorder.Insert("color", TrimAll(pRoomRow.RoomBlockTypesColor));
	ElsIf pRoomRow.IsReservation Or (pRoomRow.IsAccommodation And pRoomRow.IsInHouse) Then
		If pRoomRow.IsComplimentary Then
			vRecorder.Insert("color", "#FFFF00");
		ElsIf vBalanceIsZero Or pRoomRow.IsReservation Then
			If Not IsBlankString(pRoomRow.DocumentGuestGroupColor) Then
				vRecorder.Insert("color", TrimAll(pRoomRow.DocumentGuestGroupColor));
			ElsIf Not IsBlankString(pRoomRow.ContractsColor) Then
				vRecorder.Insert("color", TrimAll(pRoomRow.ContractsColor));
			ElsIf Not IsBlankString(pRoomRow.CustomerColor) Then
				vRecorder.Insert("color", TrimAll(pRoomRow.CustomerColor));
			ElsIf Not IsBlankString(pRoomRow.StatusColor) Then
				vRecorder.Insert("color", TrimAll(pRoomRow.StatusColor));
			Else
				vRecorder.Insert("color", "");
			EndIf;
		Else
			vRecorder.Insert("color", "");
		EndIf;
	Else
		vRecorder.Insert("color", "");
	EndIf;
	
	vRecorder.Insert("isBirthday", False);
	If ValueIsFilled(pRoomRow.GuestDateOfBirth) Then
		Try
			vGuestDateOfBirth = Date(Year(pRoomRow.PeriodFromPresentation), Month(pRoomRow.GuestDateOfBirth), Day(pRoomRow.GuestDateOfBirth));
			If BegOfDay(pRoomRow.PeriodFromPresentation) <= vGuestDateOfBirth And EndOfDay(pRoomRow.PeriodToPresentation) >= vGuestDateOfBirth Then
				vRecorder.Insert("isBirthday", True);
			EndIf;
		Except
			vRecorder.Insert("isBirthday", False);
		EndTry;
	EndIf;
	
	If Not IsBlankString(pRoomRow.Guest) Then
		vRecorder.Insert("name", TrimAll(pRoomRow.Guest));
	ElsIf Not IsBlankString(pRoomRow.RoomBlockType) Then
		vRecorder.Insert("name", TrimAll(pRoomRow.RoomBlockType));
	Else
		vRecorder.Insert("name", "");
	EndIf;
	vRecorder.Insert("customer", TrimAll(pRoomRow.Customer));
	
	If Not pDoNotShowTooltipsInRoomsGanttChart Then
		vRecorder.Insert("toolTip", GetToolTipByZone(pRoomRow, vDebtToolTip));
	EndIf;
	
	vRelocateFrom = "";
	If ValueIsFilled(pRoomRow.RoomTypeBefore) Then
		vRelocateFrom = TrimAll(pRoomRow.RoomTypeBefore.UUID()) + "_";
	EndIf;
	If ValueIsFilled(pRoomRow.RoomBefore) Then
		vRelocateFrom = vRelocateFrom + TrimAll(pRoomRow.RoomBefore.UUID());
	EndIf;
	vRecorder.Insert("relocateFrom", vRelocateFrom);
	
	vRelocateTo = "";
	If ValueIsFilled(pRoomRow.RoomTypeAfter) Then
		vRelocateTo = TrimAll(pRoomRow.RoomTypeAfter.UUID()) + "_";
	EndIf;
	If ValueIsFilled(pRoomRow.RoomAfter) Then
		vRelocateTo = vRelocateTo + TrimAll(pRoomRow.RoomAfter.UUID());
	EndIf;
	vRecorder.Insert("relocateTo", vRelocateTo);
	Return vRecorder;
EndFunction // FillRecorderData

// ----------------------------------------------------------------------------
&AtServerNoContext
Function GetToolTipByZone(pRecorder, pDebtToolTip)
	vRemarksLen = ?(Not IsBlankString(pRecorder.HousekeepingRemarks), 86, 172);
	vHousekeepingRemarksLen = ?(Not IsBlankString(pRecorder.Remarks), 86, 172);
	
	vToolTip =
	"<div>" +
	"<b>" + ?(ValueIsFilled(pRecorder.Room) And Not pRecorder.RoomIsEmpty, ?(pRecorder.IsClosedForEdit And (pRecorder.IsReservation Or (pRecorder.IsAccommodation And pRecorder.IsInHouse)),"<div style=""display: inline-block; vertical-align: middle;"" class=""IsClosedForEdit""></div>", "") + TrimAll(pRecorder.RoomDescription), NStr("en = 'BOOKING WITHOUT ROOM';de = 'BUCHUNG OHNE ZIMMERNUMMER';ru = 'БРОНЬ БЕЗ НОМЕРА КОМНАТЫ'")) + "</b>" +
	?(Not IsBlankString(pRecorder.RoomTypeCode), " " + pRecorder.RoomTypeCode, "") +
	?(Not IsBlankString(pRecorder.StatusDescription), " " + TrimAll(pRecorder.StatusDescription), "") +
	?(Not IsBlankString(pRecorder.AccommodationTemplate), " " + TrimAll(pRecorder.AccommodationTemplate), "") +
	"</div>" +
	?(Not IsBlankString(pRecorder.RoomBeforeDescription) Or Not IsBlankString(pRecorder.RoomAfterDescription),
	"<div style=""display:flex;"">" +
	?(Not IsBlankString(pRecorder.RoomBeforeDescription), "<b>" +pRecorder.RoomBeforeDescription + "</b>" + "<span style=""display:inline-block;--height-event: 20px;"" class=""relocateIcon""></span>", "") +
	"<b>" + ?(ValueIsFilled(pRecorder.Room) And Not pRecorder.RoomIsEmpty, TrimAll(pRecorder.RoomDescription), NStr("en = 'BOOKING WITHOUT ROOM';de = 'BUCHUNG OHNE ZIMMERNUMMER';ru = 'БРОНЬ БЕЗ НОМЕРА КОМНАТЫ'")) + "</b>" +
	?(Not IsBlankString(pRecorder.RoomAfterDescription), "<span style=""display: inline-block;--height-event: 20px;"" class=""relocateIcon""></span>" + "<b>" + pRecorder.RoomAfterDescription + "</b>", "") +
	"</div>",
	"")+
	"<div>" +
	?(Not pRecorder.IsBlocking, TrimAll(pRecorder.Guest), TrimAll(pRecorder.RoomBlockType)) +
	"</div>" +
	"<div>" +
	NStr("en = 'from ';de = 'vom ';ru = 'с '") + Format(pRecorder.PeriodFromPresentation, "DF='dd.MM.yyyy HH:mm'") + ?(ValueIsFilled(pRecorder.PeriodToPresentation), NStr("en = ' to ';de = ' bis ';ru = ' по '") + Format(pRecorder.PeriodToPresentation, "DF='dd.MM.yyyy HH:mm'"), "") +
	"</div>" +
	"<div>" + 
	TrimAll(pRecorder.Customer) +
	"</div>" +
	"<div>" +
	?(Not pRecorder.IsBlocking, NStr("en = 'Group: ';de = 'Gruppe: ';ru = 'Группа: '") + Format(pRecorder.GuestGroupsCode, "NFD=0;NZ=0;NG=") + " " + TrimAll(pRecorder.GuestGroupsDescription), "") +
	"</div>" +
	"<div>" +
	pDebtToolTip +
	"</div>" +
	?(Not IsBlankString(pRecorder.Remarks),
	"<div>" + 
	"<b>" + ?(Not pRecorder.IsBlocking, NStr("en = 'Reception:';de = 'Reception:';ru = 'Сл. приема и разм.:'"), NStr("en = 'Remarks:';de = 'Anmerkungen:';ru = 'Примечания:'")) + "</b></br>" +
	Left(pRecorder.Remarks, vRemarksLen) + ?(StrLen(pRecorder.Remarks) > vRemarksLen, "...", "") +
	"</div>",
	"") +
	?(Not IsBlankString(pRecorder.HousekeepingRemarks),
	"<div>" +
	"<b>" + NStr("en = 'Housekeeping:';de = 'Hausdame:';ru = 'Для горничных:'") + "</b></br>" +
	Left(pRecorder.HousekeepingRemarks, vHousekeepingRemarksLen) + ?(StrLen(pRecorder.HousekeepingRemarks) > vHousekeepingRemarksLen, "...", "") +
	"</div>",
	"");
	Return vToolTip;
EndFunction // GetToolTipByZone

// ----------------------------------------------------------------------------
&AtServerNoContext
Function GetToolTipByEvent(pEvent)
	vToolTip =
	"<div>" + 
	NStr("en = 'from ';de = 'vom ';ru = 'с '") + Format(pEvent.DateFrom, "DF='dd.MM.yyyy'") + NStr("en = ' to ';de = ' bis ';ru = ' по '") + Format(pEvent.DateTo, "DF='dd.MM.yyyy'") +
	"</div>" +
	?(Not IsBlankString(pEvent.Remarks),	
	"<div>" + 
	"<b>" + NStr("en = 'Remarks:';de = 'Anmerkungen:';ru = 'Примечания:'") + "</b></br>" +
	Left(pEvent.Remarks, 172) + ?(StrLen(pEvent.Remarks) > 172, "...", "") +
	"</div>",
	"");
	Return vToolTip;
EndFunction // GetToolTipByEvent

// ----------------------------------------------------------------------------
&AtServer
Function FillRoomsByBasket(pBasketUUID)
	vOrderBasketArr = OrderBasket.FindRows(New Structure("UUID", pBasketUUID));
	If vOrderBasketArr.Count() <= 0 Then
		Return Undefined;
	EndIf;
	
	vOrderBasket = vOrderBasketArr[0];
	
	vResult = New Structure("RoomTypesData", New Array);
	
	vGrupByField = vOrderBasket.RoomType;
	If Not SelShowRoomsByRoomTypes Then
		vGrupByField = vOrderBasket.Room.Parent;
	EndIf;
	
	vRoomTypesData = New Structure;
	If ValueIsFilled(vGrupByField) Then
		vRoomTypesData.Insert("id", "RT" + TrimAll(vGrupByField.UUID()));
	Else
		vRoomTypesData.Insert("id", "RTEMPTY");
	EndIf;
	
	vRoomTypesData.Insert("rooms", New Array);
	
	vRoom = New Structure;
	vRoom.Insert("id", "R" + TrimAll(vOrderBasket.RoomType.UUID()) + "_" + TrimAll(vOrderBasket.Room.UUID()));
	vRoom.Insert("zones", New Array);
	
	vRoom.zones.Add(FillOrderBasketData(vOrderBasket, RecordersNumber));
	vRoomTypesData.rooms.Add(vRoom);
	vResult.RoomTypesData.Add(vRoomTypesData);
	
	Return vResult;
EndFunction // FillRoomsByBasket

// ----------------------------------------------------------------------------
&AtServerNoContext
Procedure SetQueryResource(pQryRow, pShowReportsInBeds, rLastVacant, rLastReserved, pUseDataFromSales = True)		
	If pQryRow.TotalBeds = 0 Or pQryRow.TotalBeds = NULL Then
		rLastVacant = 0;
		rLastReserved = 0;
		Return;
	EndIf;
	
	vVacant = 0;
	vReserved = 0;
	If pShowReportsInBeds Then
		If pQryRow.BedsVacant = NULL Then
			vVacant = rLastVacant;
			vReserved = rLastReserved;
		Else
			vVacant = pQryRow.BedsVacant;
			vTotalBeds = (pQryRow.TotalRooms + pQryRow.RoomsBlocked);
			If vTotalBeds > 0 Then
				If pUseDataFromSales Then
					vReserved = Round(?(pQryRow.BedsRented = Null, 0, pQryRow.BedsRented) * 100 / vTotalBeds, 0, RoundMode.Round15as20);
				Else
					vReserved = Round((vTotalBeds - pQryRow.BedsVacant) * 100 / vTotalBeds, 0, RoundMode.Round15as20);
				EndIf;
			Else
				vReserved = 0;
			EndIf;
		EndIf;
	Else
		If pQryRow.RoomsVacant = NULL Then
			vVacant = rLastVacant;
			vReserved = rLastReserved;
		Else
			vVacant = pQryRow.RoomsVacant;
			vTotalRooms = (pQryRow.TotalRooms + pQryRow.RoomsBlocked);
			If vTotalRooms > 0 Then
				If pUseDataFromSales Then
					vReserved = Round(?(pQryRow.RoomsRented = Null, 0, pQryRow.RoomsRented) * 100 / vTotalRooms, 0, RoundMode.Round15as20);
				Else
					vReserved = Round((vTotalRooms - pQryRow.RoomsVacant) * 100 / vTotalRooms, 0, RoundMode.Round15as20);
				EndIf;
			Else
				vReserved = 0;
			EndIf;
		EndIf;
	EndIf;
	If rLastVacant = Undefined Or 
		rLastVacant <> vVacant Then
		rLastVacant = vVacant;
	EndIf;
	If rLastReserved = Undefined Or 
		rLastReserved <> vReserved Then
		rLastReserved = vReserved;
	EndIf;
EndProcedure // SetQueryVacantResource

// ----------------------------------------------------------------------------
&AtServerNoContext
Function GetRoomsVacantPeriods(pRoomList, pPeriodFrom, pPeriodTo, pHotel)
	// Build and run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Rooms.Ref AS Room,
	|	Rooms.SortCode AS RoomSortCode
	|INTO RoomList
	|FROM
	|	Catalog.Rooms AS Rooms
	|WHERE
	|	Rooms.Owner = &qHotel
	|	AND Rooms.Ref IN(&qRooms)
	|	AND NOT Rooms.DeletionMark
	|	AND NOT Rooms.IsFolder
	|	AND NOT Rooms.IsVirtual
	|	AND Rooms.OperationStartDate <= &qPeriodTo
	|	AND (Rooms.OperationEndDate >= &qPeriodFrom
	|			OR Rooms.OperationEndDate = DATETIME(1, 1, 1))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventoryBalanceAndTurnovers.Room AS Room,
	|	RoomList.RoomSortCode AS RoomSortCode,
	|	RoomInventoryBalanceAndTurnovers.CounterClosingBalance AS Counter,
	|	RoomInventoryBalanceAndTurnovers.RoomsVacantClosingBalance AS RoomsVacant,
	|	RoomInventoryBalanceAndTurnovers.BedsVacantClosingBalance AS BedsVacant,
	|	RoomInventoryBalanceAndTurnovers.TotalRoomsClosingBalance AS TotalRooms,
	|	BEGINOFPERIOD(RoomInventoryBalanceAndTurnovers.Period, DAY) AS Period,
	|	RoomInventoryBalanceAndTurnovers.Period AS VacantFromDate,
	|	RoomInventoryBalanceAndTurnovers.Period AS VacantToDate,
	|	RoomInventoryBalanceAndTurnovers.RoomType AS RoomType
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Second,
	|			RegisterRecordsAndPeriodBoundaries,
	|			Hotel = &qHotel
	|				AND Room IN
	|					(SELECT
	|						RoomList.Room
	|					FROM
	|						RoomList AS RoomList)) AS RoomInventoryBalanceAndTurnovers
	|		INNER JOIN RoomList AS RoomList
	|		ON RoomInventoryBalanceAndTurnovers.Room = RoomList.Room
	|WHERE
	|	RoomInventoryBalanceAndTurnovers.TotalRoomsClosingBalance > 0
	|
	|ORDER BY
	|	RoomSortCode,
	|	VacantFromDate";
	vQry.SetParameter("qRooms", pRoomList);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qPeriodFrom", pPeriodFrom);
	vQry.SetParameter("qPeriodTo", pPeriodTo);
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
	vQryRes.Sort("RoomSortCode, VacantFromDate");
	// Return vacant periods
	Return vQryRes;
EndFunction // GetRoomsVacantPeriods

// ----------------------------------------------------------------------------
&AtServerNoContext
Function GetRoomTypesForSelection(pRoomType, pRoomClass, pHotel, pRoomTypesList)
	vRoomTypesList = New ValueList;
	vRoomTypes = cmGetAllRoomTypes(pHotel, pRoomType, pRoomClass);
	For Each vRoomTypesRow In vRoomTypes Do
		vRoomTypesList.Add(vRoomTypesRow.RoomType, , ?(pRoomTypesList.FindByValue(vRoomTypesRow.RoomType) = Undefined, False, True));
	EndDo;
	Return vRoomTypesList;
EndFunction // GetRoomTypesForSelection

// ----------------------------------------------------------------------------
&AtServerNoContext
Function GetDocumentsByUUID(pUUID)
	vDocument = Documents.SetRoomBlock.GetRef(pUUID);
	If Not IsBlankString(vDocument.DataVersion) Then
		Return vDocument;
	EndIf;
	
	vDocument = Documents.Reservation.GetRef(pUUID);
	If Not IsBlankString(vDocument.DataVersion) Then
		Return vDocument;
	EndIf;
	
	vDocument = Documents.Accommodation.GetRef(pUUID);
	If Not IsBlankString(vDocument.DataVersion) Then
		Return vDocument;
	EndIf;
	
	vDocument = Catalogs.Events.GetRef(pUUID);
	If Not IsBlankString(vDocument.DataVersion) Then
		Return vDocument;
	EndIf;
	
	Return Undefined;
EndFunction // GetDocumentsByUUID

// ----------------------------------------------------------------------------
&AtServerNoContext
Function GetDataByDocument(pDocumentRef, pHotel, pDateTimeFrom, pDateTimeTo, pShowAllGuests)
	vMainDocument = Undefined;
	
	vQ = New Query;
	vQ.Text =
	"SELECT
	|	AccommodationStatuses.Ref AS Ref
	|INTO StatusList
	|FROM
	|	Catalog.AccommodationStatuses AS AccommodationStatuses
	|WHERE
	|	NOT AccommodationStatuses.DeletionMark
	|	AND NOT AccommodationStatuses.IsFolder
	|	AND AccommodationStatuses.IsActive
	|
	|UNION
	|
	|SELECT
	|	ReservationStatuses.Ref
	|FROM
	|	Catalog.ReservationStatuses AS ReservationStatuses
	|WHERE
	|	NOT ReservationStatuses.DeletionMark
	|	AND NOT ReservationStatuses.IsFolder
	|	AND ReservationStatuses.IsActive
	|	AND NOT ReservationStatuses.IsCheckIn
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Accommodation.Ref AS Ref,
	|	Accommodation.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef) AS IsMainDocument,
	|	Accommodation.Guest AS Guest
	|FROM
	|	Document.Accommodation AS Accommodation
	|		INNER JOIN StatusList AS StatusList
	|		ON Accommodation.AccommodationStatus = StatusList.Ref
	|WHERE
	|	Accommodation.Number = &qNumber
	|	AND Accommodation.GuestGroup = &qGuestGroup
	|
	|UNION
	|
	|SELECT
	|	Reservation.Ref,
	|	Reservation.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef),
	|	Reservation.Guest
	|FROM
	|	Document.Reservation AS Reservation
	|		INNER JOIN StatusList AS StatusList
	|		ON Reservation.ReservationStatus = StatusList.Ref
	|WHERE
	|	Reservation.Number = &qNumber
	|	AND Reservation.GuestGroup = &qGuestGroup
	|
	|ORDER BY
	|	IsMainDocument DESC";
	vQ.SetParameter("qNumber", pDocumentRef.Number);
	vQ.SetParameter("qGuestGroup", pDocumentRef.GuestGroup);
	vDocuments = vQ.Execute().Unload();
	
	If Not pShowAllGuests Then
		vMainDocuments = vDocuments.FindRows(New Structure("IsMainDocument", True));
		For Each vMainDocumentRow In vMainDocuments Do
			vMainDocument = vMainDocumentRow.Ref;
			Break;
		EndDo;
	EndIf;
	
	If Not ValueIsFilled(vMainDocument) Then
		vMainDocument = pDocumentRef;
	EndIf;
	
	vIsReservation = TypeOf(vMainDocument) = Type("DocumentRef.Reservation");
	
	vResult = New Structure;
	
	vResult.Insert("id", TrimAll(vMainDocument.UUID()));
	
	vResult.Insert("IsReservation", vIsReservation);
	
	If vIsReservation Then
		vResult.Insert("type", TrimAll(vMainDocument.ReservationStatus));
	Else
		vResult.Insert("type", TrimAll(vMainDocument.AccommodationStatus));
	EndIf;
	
	vResult.Insert("number", TrimAll(vMainDocument.Number));
	
	vAction = New Structure;
	If vIsReservation Then
		vAction.Insert("action", NStr("en = 'Check-in';de = 'Check-in';ru = 'Поселить'"));
		vAction.Insert("actionEnable", True);
	Else 
		vAccommodationStatus = vMainDocument.AccommodationStatus;
		vAction.Insert("actionEnable", Not (vAccommodationStatus.IsActive And Not vAccommodationStatus.IsInHouse));
		vAction.Insert("action", NStr("en = 'Check-out';de = 'Check-out';ru = 'Выселить'"));
	EndIf;
	vAction.Insert("change", NStr("en = 'Change';de = 'Ändern';ru = 'Изменить'"));
	vAction.Insert("folio", NStr("en = 'Folios list';de = 'Personenkonten';ru = 'Лиц. счета'"));
	vResult.Insert("action", vAction);
	
	vGroup = New Structure;
	vGroup.Insert("name", NStr("en = 'Guest group';de = 'Gästegrupp';ru = 'Группа гостей'"));
	vGroup.Insert("description", Format(vMainDocument.GuestGroup.Code, "NFD=0;NGS=;NZ=0") + ?(Not IsBlankString(vMainDocument.GuestGroup.Description), " - " + TrimAll(vMainDocument.GuestGroup.Description), ""));
	vResult.Insert("group", vGroup);
	
	If ValueIsFilled(vMainDocument.Customer) Then
		vCustomer = New Structure;
		vCustomer.Insert("name", NStr("en = 'Customer';de = 'Firm';ru = 'Контрагент'"));
		vCustomer.Insert("description", TrimAll(vMainDocument.Customer.Description));
		vResult.Insert("customer", vCustomer);
	EndIf;
	
	vRoomInfo = New Structure;
	
	vRoomType = New Structure;
	vRoomType.Insert("name", NStr("en = 'Room type';de = 'Zimmertyp';ru = 'Тип номера'"));
	vRoomType.Insert("description", TrimAll(vMainDocument.RoomType.Description));
	vRoomInfo.Insert("roomType", vRoomType);
	
	vRoom = New Structure;
	vRoom.Insert("name", NStr("en = 'Room';de = 'Zimmer';ru = 'Номер'"));
	If ValueIsFilled(vMainDocument.Room) Then
		vRoom.Insert("description", TrimAll(vMainDocument.Room.Description));
	Else
		vRoom.Insert("description", "N/A");
	EndIf;
	vRoom.Insert("IsClosedForEdit", vMainDocument.IsClosedForEdit And (vIsReservation Or (vAccommodationStatus.IsActive And vAccommodationStatus.IsInHouse)));
	vRoomInfo.Insert("room", vRoom);
	
	vResult.Insert("roomInfo", vRoomInfo);
	
	vPeriod = New Structure;
	vPeriod.Insert("name", NStr("en = 'Length of stay';de = 'Dauer des Aufenthalts';ru = 'Сроки проживания'"));
	vPeriod.Insert("period", Format(vMainDocument.CheckInDate, "DF='dd/MM/yyyy HH:mm'") + " - " + Format(vMainDocument.CheckOutDate, "DF='dd/MM/yyyy HH:mm'"));
	If SessionParameters.CurrentLanguage = Catalogs.Languages.RU Then
		vPeriod.Insert("day", GetStringDeclensionsByNumber("ночь", vMainDocument.Duration, , "L=ru_RU")[0]);
	Else
		vPeriod.Insert("day", Format(vMainDocument.Duration, "NFD=0;NZ=0;NG=") + NStr("en = ' nights';de = ' Nachten';ru = ' ночь'"));
	EndIf;
	vResult.Insert("period", vPeriod);
	
	vGuestInfo = New Structure;
	vGuestInfo.Insert("name", NStr("en = 'Guests';de = 'Gäste';ru = 'Состав гостей'"));
	vGuestInfo.Insert("accommodationTemplate", TrimAll(vMainDocument.AccommodationTemplate));
	
	vGuests = New Array;
	If Not pShowAllGuests Then
		For Each vDocumentRow In vDocuments Do
			If Not ValueIsFilled(vDocumentRow.Guest) Then
				Continue;
			EndIf;
			vGuestRef = vDocumentRow.Guest;
			
			If IsBlankString(vGuestRef.FullName) Then
				Continue;
			EndIf;
			
			vGuest = New Structure;
			vGuest.Insert("fullName", TrimAll(vGuestRef.FullName));
			If ValueIsFilled(vGuestRef.ClientType) Then
				vGuest.Insert("type", "(" + TrimAll(vGuestRef.ClientType) + ")");
			Else
				vGuest.Insert("type", "");
			EndIf;
			
			vGuest.Insert("Countrie", "");
			vGuest.Insert("CountrieShort", "");
			vGuest.Insert("CountrieImg", "");
			vCitizenship = vGuestRef.Citizenship;
			If ValueIsFilled(vCitizenship) Then
				vGuest.Insert("CountrieShort", TrimAll(vCitizenship.ISOCode));
				vGuest.Insert("Countrie", vCitizenship.GetObject().pmGetCountryDescription(SessionParameters.CurrentLanguage));
				
				vFlag = vCitizenship.Flag.Get();
				If vFlag <> Undefined Then
					vGuest.Insert("CountrieImg", GetPictureIsBase64HTMLString(vFlag));
				EndIf;
			EndIf;
			
			vGuests.Add(vGuest);
		EndDo;
	ElsIf ValueIsFilled(vMainDocument.Guest) Then
		vGuestRef = vMainDocument.Guest;
		If Not IsBlankString(vGuestRef.FullName) Then
			vGuest = New Structure;
			vGuest.Insert("fullName", TrimAll(vGuestRef.FullName));
			If ValueIsFilled(vGuestRef.ClientType) Then
				vGuest.Insert("type", "(" + TrimAll(vGuestRef.ClientType) + ")");
			Else
				vGuest.Insert("type", "");
			EndIf;
			
			vGuest.Insert("Countrie", "");
			vGuest.Insert("CountrieShort", "");
			vGuest.Insert("CountrieImg", "");
			vCitizenship = vGuestRef.Citizenship;
			If ValueIsFilled(vCitizenship) Then
				vGuest.Insert("CountrieShort", TrimAll(vCitizenship.ISOCode));
				vGuest.Insert("Countrie", vCitizenship.GetObject().pmGetCountryDescription(SessionParameters.CurrentLanguage));
				
				vFlag = vCitizenship.Flag.Get();
				If vFlag <> Undefined Then
					vGuest.Insert("CountrieImg", GetPictureIsBase64HTMLString(vFlag));
				EndIf;
			EndIf;
			
			vGuests.Add(vGuest);
		EndIf;
	EndIf;
	
	vGuestInfo.Insert("guests", vGuests);
	vResult.Insert("guestInfo", vGuestInfo);
	
	vTotalSum = 0;
	vPaidSum = 0;
	
	vDocList = New Array;
	If Not pShowAllGuests Then 
		vDocList = vDocuments.UnloadColumn("Ref");
		vDocListCount = vDocList.Count();
		For i = 0 To vDocListCount - 1 Do
			If TypeOf(vDocList[i]) = Type("DocumentRef.Accommodation") And ValueIsFilled(vDocList[i].Reservation) Then
				vDocList.Add(vDocList[i].Reservation);
			EndIf;
			If ValueIsFilled(vDocList[i].ParentDoc) Then
				vDocList.Add(vDocList[i].ParentDoc);
			EndIf;
		EndDo;
	EndIf;
	If vDocList.Count() <= 0 Then
		vDocList.Add(vMainDocument);
		If TypeOf(vMainDocument) = Type("DocumentRef.Accommodation") And ValueIsFilled(vMainDocument.Reservation) Then
			vDocList.Add(vMainDocument.Reservation);
		EndIf;
		If ValueIsFilled(vMainDocument.ParentDoc) Then
			vDocList.Add(vMainDocument.ParentDoc);
		EndIf;
	EndIf;
	
	vGuestGroupObj = vMainDocument.GuestGroup.GetObject();
	vIsPreliminary = vGuestGroupObj.pmIsPreliminary();
	
	vSalesTotals = vGuestGroupObj.pmGetSalesTotals(, vDocList);
	vSumCells = "Sales";
	If vSalesTotals.Columns.Find(vSumCells) = Undefined Then
		vSumCells = "Sum";
	EndIf;
	For Each vTotalsRow In vSalesTotals Do
		If Not vIsPreliminary Then
			vTotalSum = vTotalSum + cmConvertCurrencies(?(vTotalsRow[vSumCells] = NULL, 0, vTotalsRow[vSumCells]) + ?(vTotalsRow.SalesForecast = NULL, 0, vTotalsRow.SalesForecast), vTotalsRow.Currency,, pHotel.BaseCurrency);
		EndIf;
	EndDo;
	
	vPaymentsTotals = vGuestGroupObj.pmGetPaymentsTotals(vDocList);
	vSumCells = "Sales";
	If vPaymentsTotals.Columns.Find(vSumCells) = Undefined Then
		vSumCells = "Sum";
	EndIf;
	
	For Each vTotalsRow In vPaymentsTotals Do
		vPaidSum = vPaidSum + cmConvertCurrencies(vTotalsRow[vSumCells], vTotalsRow.Currency,, pHotel.BaseCurrency);
	EndDo;
	
	vSumInfo = New Structure;
	
	vTotal = New Structure;
	vTotal.Insert("name", NStr("en = 'Total';de = 'Total';ru = 'Итого'"));
	vTotal.Insert("sum", Format(vTotalSum, "ND=17;NFD=2;NZ=0;NG="));
	vSumInfo.Insert("total", vTotal);
	
	vPaid = New Structure;
	vPaid.Insert("name", NStr("en = 'Paid';de = 'Bezahlt';ru = 'Оплачено'"));
	vPaid.Insert("sum", Format(vPaidSum, "ND=17; NFD=2; NZ=; NG="));
	vSumInfo.Insert("paid", vPaid);
	
	vDebtOrAdvance = New Structure;
	vPreauth = New Structure;
	
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Folio.Ref AS Ref
	|INTO ClientFoliosList
	|FROM
	|	Document.Folio AS Folio
	|		INNER JOIN Catalog.Customers AS Customers
	|		ON Folio.Customer = Customers.Ref
	|			AND (Customers.IsIndividual)
	|WHERE
	|	Folio.FolioCurrency = &qCurrency
	|	AND Folio.Hotel = &qHotel
	|	AND Folio.ParentDoc IN(&qParentDoc)
	|
	|UNION
	|
	|SELECT
	|	Folio.Ref
	|FROM
	|	Document.Folio AS Folio
	|WHERE
	|	Folio.FolioCurrency = &qCurrency
	|	AND Folio.Hotel = &qHotel
	|	AND Folio.ParentDoc IN(&qParentDoc)
	|	AND Folio.Customer = VALUE(Catalog.Customers.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Folio.Ref AS Ref
	|INTO CustomerFoliosList
	|FROM
	|	Document.Folio AS Folio
	|		INNER JOIN Catalog.Customers AS Customers
	|		ON Folio.Customer = Customers.Ref
	|			AND (NOT Customers.IsIndividual)
	|WHERE
	|	Folio.FolioCurrency = &qCurrency
	|	AND Folio.Hotel = &qHotel
	|	AND Folio.ParentDoc IN(&qParentDoc)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(AccountsBalance.ClientSumBalance) + SUM(AccountsBalance.CustomerSumBalance) AS SumBalance,
	|	SUM(AccountsBalance.ClientLimitBalance) + SUM(AccountsBalance.CustomerLimitBalance) AS LimitBalance
	|FROM
	|	(SELECT
	|		ClientAccountsBalance.SumBalance AS ClientSumBalance,
	|		-ClientAccountsBalance.LimitBalance AS ClientLimitBalance,
	|		0 AS CustomerSumBalance,
	|		0 AS CustomerLimitBalance
	|	FROM
	|		AccumulationRegister.Accounts.Balance(
	|				&qBalancesPeriod,
	|				Hotel = &qHotel
	|					AND FolioCurrency = &qCurrency
	|					AND Folio IN
	|						(SELECT
	|							ClientFoliosList.Ref
	|						FROM
	|							ClientFoliosList AS ClientFoliosList)) AS ClientAccountsBalance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		0,
	|		0,
	|		CustomerAccountsBalance.SumBalance,
	|		-CustomerAccountsBalance.LimitBalance
	|	FROM
	|		AccumulationRegister.Accounts.Balance(
	|				&qBalancesPeriod,
	|				Hotel = &qHotel
	|					AND FolioCurrency = &qCurrency
	|					AND Folio IN
	|						(SELECT
	|							CustomerFoliosList.Ref
	|						FROM
	|							CustomerFoliosList AS CustomerFoliosList)) AS CustomerAccountsBalance) AS AccountsBalance";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qCurrency", pHotel.FolioCurrency);
	vQry.SetParameter("qParentDoc", vDocList);
	vQry.SetParameter("qBalancesPeriod", ?(pHotel.ShowDebtsOnCurrentDate, CurrentSessionDate(), '39991231235959'));
	
	vBalances = vQry.Execute().Unload();
	
	vDebtOrAdvanceText = "";
	For Each vBalancesRow In vBalances Do
		If vBalancesRow.SumBalance > 0 Then
			vDebtOrAdvance.Insert("name", NStr("en='Debt: ';ru='Долг: ';de='Schuld: '"));
			vDebtOrAdvance.Insert("sum", Format(vBalancesRow.SumBalance, "ND=17; NFD=2; NZ=; NG="));
		ElsIf vBalancesRow.SumBalance < 0 Then
			vDebtOrAdvance.Insert("name", NStr("en='Advance: ';ru='Предоплата: ';de='Vorauszahlung: '"));
			vDebtOrAdvance.Insert("sum", Format(-vBalancesRow.SumBalance, "ND=17; NFD=2; NZ=; NG="));
		EndIf;
		If vBalancesRow.LimitBalance <> 0 Then
			vPreauth.Insert("name", NStr("en='Preauth.: ';ru='Преавт.: ';de='Voraut.: '"));
			vPreauth.Insert("sum", Format(vBalancesRow.LimitBalance, "ND=17; NFD=2; NZ=; NG="));
		EndIf;
	EndDo;
	vSumInfo.Insert("debtOrAdvance", vDebtOrAdvance);
	vSumInfo.Insert("preauth", vPreauth);
	
	vResult.Insert("sumInfo", vSumInfo);
	
	vRate = New Structure;
	vRate.Insert("name", NStr("en = 'Room rate';de = 'Tarif';ru = 'Тариф'"));
	vRate.Insert("description", TrimAll(vMainDocument.RoomRate));
	vResult.Insert("rate", vRate);
	
	If Not IsBlankString(vMainDocument.Remarks) Then
		vRemarks = New Structure;
		vRemarks.Insert("name", NStr("en = 'Remarks';de = 'Anmerkungen';ru = 'Примечания'"));
		vRemarks.Insert("description", TrimAll(vMainDocument.Remarks));
		vResult.Insert("remarks", vRemarks);
	EndIf;
	
	If Not IsBlankString(vMainDocument.HousekeepingRemarks) Or ValueIsFilled(vMainDocument.BedsSetup) Then
		vHousekeepingRemarks = New Structure;
		vHousekeepingRemarks.Insert("name", NStr("en = 'Housekeeping remarks';de = 'Hausdame bemerkungen';ru = 'Примечания для горничных'"));
		vHousekeepingRemarksStr = ?(ValueIsFilled(vMainDocument.BedsSetup), NStr("en='Beds: '; ru='Кровати: '; de='Betten: '") + TrimAll(vMainDocument.BedsSetup), "");
		vHousekeepingRemarksStr = vHousekeepingRemarksStr + ?(IsBlankString(vHousekeepingRemarksStr), "", ", ") + TrimAll(vMainDocument.HousekeepingRemarks);
		vHousekeepingRemarks.Insert("description", vHousekeepingRemarksStr);
		vResult.Insert("housekeepingRemarks", vHousekeepingRemarks);
	EndIf;
	
	vTasks = cmGetMessagesForObject(vMainDocument.Ref, True);
	If ValueIsFilled(vMainDocument.GuestGroup) Then
		vGroupTasks = cmGetMessagesForObject(vMainDocument.GuestGroup);
		For Each vGroupTasksRow In vGroupTasks Do
			vTasksRow = vTasks.Add();
			FillPropertyValues(vTasksRow, vGroupTasksRow);
		EndDo;
	EndIf;
	If ValueIsFilled(vMainDocument.Customer) Then
		vCustomerTasks = cmGetMessagesForObject(vMainDocument.Customer);
		For Each vCustomerTasksRow In vCustomerTasks Do
			vTasksRow = vTasks.Add();
			FillPropertyValues(vTasksRow, vCustomerTasksRow);
		EndDo;
	EndIf;
	
	If vTasks.Count() > 0 Then
		vTask = New Structure;
		vTask.Insert("name", NStr("en = 'Tasks';de = 'Aufgaben';ru = 'Задачи'"));
		vTasksArr = New Array;
		
		For Each vTasksRow In vTasks Do
			vTasksArr.Add(TrimAll(vTasksRow.Remarks));
		EndDo;
		
		vTask.Insert("tasks", vTasksArr);
		vResult.Insert("task", vTask);
	EndIf;
	
	Return vResult;
EndFunction // GetDataByUUID

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetPictureIsBase64HTMLString(pPicture)
	Return StrTemplate("data:image/%1;base64,%2", GetImageType(pPicture.Format()), StrReplace(Base64String(pPicture.GetBinaryData()), Chars.CR + Chars.LF, ""));
EndFunction // GetPictureIsBase64HTMLString

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetImageType(pFormat)
	If pFormat = PictureFormat.PNG Then
		Return "png";
	ElsIf pFormat = PictureFormat.JPEG Then
		Return "jpeg";
	ElsIf pFormat = PictureFormat.SVG Then
		Return "svg+xml";
	ElsIf pFormat = PictureFormat.GIF Then
		Return "gif";
	ElsIf pFormat = PictureFormat.BMP Then
		Return "bmp";
	Else
		Return "png";
	EndIf;
EndFunction // GetImageType

// ----------------------------------------------------------------------------
&AtServerNoContext
Function CheckInAtServer(pRef, pQueryBoxInactive = false, pSelResList = Undefined, pOneGuestMode = False)
	// Build list of selected reservations. We will process reservations from the one room only (or empty one)
	vSelRes = pRef;
	vStopCheckIn = False;
	If Not vSelRes.Posted Then
		vStopCheckIn = True;
	ElsIf Not ValueIsFilled(vSelRes.ReservationStatus) Then
		vStopCheckIn = True;
	ElsIf Not vSelRes.ReservationStatus.IsActive And vSelRes.ReservationStatus <> vSelRes.Hotel.NoShowReservationStatus Then
		vStopCheckIn = True;
		If Not cmCheckUserPermissions("HavePermissionToCheckInBasedOnInactiveReservations") And ValueIsFilled(vSelRes.Hotel) Then
			Return NStr("en='You do not have rights to check-in guests based on inactive reservation!';ru='Нет прав на размещение гостей по не активной брони!';de='Sie haben keine Rechte, Gäste nach nicht aktiven Reservierungen zu platzieren! '");
		EndIf;
	ElsIf vSelRes.ReservationStatus.IsCheckIn Then
		vStopCheckIn = True;
		Return NStr("en='Reservation was already checked-in!';ru='Бронь уже заселена!';de='Reservierung bereits checked-in!'");
	EndIf;
	If vStopCheckIn Then
		If Not pQueryBoxInactive Then
			Return "DoQueryBox"
		EndIf;
	EndIf;
	If vSelRes.Posted Then
		vQuestionWasAsked = False;
		vSelResList = New ValueList();
		If pOneGuestMode Then
			vSelResList.Add(vSelRes);
		Else
			vSelRows = GetOneRoomGuests(vSelRes);
			vSkip = False;
			If pSelResList = Undefined Then
				For Each vRowItem In vSelRows Do
					If Not vRowItem.Value.ReservationStatus.IsCheckIn Then
						vSelResList.Add(vRowItem.Value, cmBuildAccommodationSortingPresentation(vRowItem.Value));
					EndIf;
				EndDo;
			Else
				vSelResList = pSelResList;
			EndIf;
			If pSelResList = Undefined Then
				Return vSelResList;
			EndIf;
		EndIf;
		If vSelResList.Count() = 0 Then
			Return "";
		Else
			vSelResList.SortByPresentation();
			vSelRes = vSelResList.Get(0).Value;
		EndIf;
		Return New Structure("ValueList", vSelResList);
	Else
		Return NStr("en='Check-in is allowed for posted reservation only!';ru='Поселять можно только по проведенной брони!';de='Ein Check-In ist nur nach einer bearbeiteten Reservierung möglich!'");
	EndIf;
EndFunction // CheckInAtServer

// ----------------------------------------------------------------------------
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
	            |	FALSE AS IsStatusChanged,
	            |	FALSE AS IsAnnulation,
	            |	TRUE AS IsGuest,
	            |	FALSE AS IsNoResortFee,
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
	            |	ISNULL(Reservations.AccommodationTemplate.Code, """") DESC,
	            |	Reservations.AccommodationType.SortCode";
	vQry.SetParameter("qGroup", pRef.GuestGroup);
	vQry.SetParameter("qReservStatus", pRef.ReservationStatus);
	vQry.SetParameter("qNumber", pRef.Number);
	vQry.SetParameter("qEmptyReservationStatusRef", Catalogs.ReservationStatuses.EmptyRef());
	vQryResult = vQry.Execute().Unload();
	vSelResList = New ValueList;
	For Each vRow In vQryResult Do
		vSelResList.Add(vRow.Ref);
	EndDo;
	Return vSelResList;
EndFunction // GetOneRoomGuests

// ----------------------------------------------------------------------------
&AtServerNoContext
Function CheckReservationsDeposits(pResRef)
	vFolios = cmGetDocumentFoliosWithDebts(pResRef, True);// Deposits only
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
		tcCommonFunctionOnClientServer.UserMessage(vDebtsMessage);
		WriteLogEvent(NStr("en='Reservation.CheckDeposits';ru='Резервирование.ПроверкаДепозита';de='Reservation.CheckDeposits'"), EventLogLevel.Information, Metadata.Documents.Folio, , vDebtsMessage);
	EndIf;
	Return True;
EndFunction // CheckReservationsDeposits

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetListOfCustomerFolios(pDocument)
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
	vQry.SetParameter("qGuestGroup", pDocument.GuestGroup);
	vQry.SetParameter("qNumber", TrimR(pDocument.Number));
	vFolios = vQry.Execute().Unload();
	vFoliosList = New ValueList();
	vFoliosList.LoadValues(vFolios.UnloadColumn("Ref"));
	Return vFoliosList;
EndFunction // GetListOfCustomerFolios

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

// ---------------------------------------------------------------------------- 
&AtServerNoContext
Function GetMainRoomAccommodation(pRef) 
	Return cmGetMainRoomAccommodation(pRef.Number, pRef.GuestGroup, pRef.Room);
EndFunction // GetMainRoomAccommodation

// ---------------------------------------------------------------------------- 
&AtServerNoContext
Function GetMainRoomReservation(pRef) 
	Return cmGetMainRoomReservation(pRef.Number, pRef.GuestGroup, pRef.Room);
EndFunction // GetMainRoomReservation

// ---------------------------------------------------------------------------- 
&AtServerNoContext
Function GetColorByHotel(pHotel)
	vResult = New Array;
	If ValueIsFilled(pHotel) Then
		vCheckInColor = pHotel.CheckInColor.Get();
		If vCheckInColor <> Undefined And TypeOf(vCheckInColor) = Type("Color") Then
			vResult.Add(New Structure("Name, Color", "living", tcOnServer.ColorToHex(vCheckInColor)));
		EndIf;
		vCheckOutColor = pHotel.CheckOutColor.Get();
		If vCheckOutColor <> Undefined And TypeOf(vCheckOutColor) = Type("Color") Then
			vResult.Add(New Structure("Name, Color", "leave", tcOnServer.ColorToHex(vCheckOutColor)));
		EndIf;
		vAccommodationWithDebtColor = pHotel.AccommodationWithDebtColor.Get();
		If vAccommodationWithDebtColor <> Undefined And TypeOf(vAccommodationWithDebtColor) = Type("Color") Then
			vResult.Add(New Structure("Name, Color", "living-debt", tcOnServer.ColorToHex(vAccommodationWithDebtColor)));
		EndIf;
		vReservationColor = pHotel.ReservationColor.Get();
		If vReservationColor <> Undefined And TypeOf(vReservationColor) = Type("Color") Then
			vResult.Add(New Structure("Name, Color", "booked", tcOnServer.ColorToHex(vReservationColor)));
		EndIf;
		vReservationWithDebtColor = pHotel.ReservationWithDebtColor.Get();
		If vReservationWithDebtColor <> Undefined And TypeOf(vReservationWithDebtColor) = Type("Color") Then
			vResult.Add(New Structure("Name, Color", "booked-debt", tcOnServer.ColorToHex(vReservationWithDebtColor)));
		EndIf;
		vGuaranteedReservationColor = pHotel.GuaranteedReservationColor.Get();
		If vGuaranteedReservationColor <> Undefined And TypeOf(vGuaranteedReservationColor) = Type("Color") Then
			vResult.Add(New Structure("Name, Color", "booked-guaranteed", tcOnServer.ColorToHex(vGuaranteedReservationColor)));
		EndIf;
	EndIf;
	Return vResult;
EndFunction // GetColorByHotel

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure SaveSettingsAtServer(pScale, pShowRoomsByRoomTypes, pShowBookingsWithoutRooms, pShowPreliminary, pHeightDocument, pShowRoomPropertiesCodes, pSelShowAllGuests, pDoNotAutoHide, pShowWaitingList)
	SystemSettingsStorage.Save("tcRoomsGanttChartHTMLScale", SessionParameters.CurrentUser, pScale);
	SystemSettingsStorage.Save("tcRoomsGanttChartHTMLShowRoomsByRoomTypes", SessionParameters.CurrentUser, pShowRoomsByRoomTypes);
	SystemSettingsStorage.Save("tcRoomsGanttChartHTMLShowBookingsWithoutRooms", SessionParameters.CurrentUser, pShowBookingsWithoutRooms);
	SystemSettingsStorage.Save("tcRoomsGanttChartHTMLShowPreliminary", SessionParameters.CurrentUser, pShowPreliminary);
	SystemSettingsStorage.Save("tcRoomsGanttChartHTMLShowWaitingList", SessionParameters.CurrentUser, pShowWaitingList);
	SystemSettingsStorage.Save("tcRoomsGanttChartHTMLHeightDocument", SessionParameters.CurrentUser, pHeightDocument);
	SystemSettingsStorage.Save("tcRoomsGanttChartHTMLShowRoomPropertiesCodes", SessionParameters.CurrentUser, pShowRoomPropertiesCodes);
	SystemSettingsStorage.Save("tcRoomsGanttChartHTMLShowAllGuests", SessionParameters.CurrentUser, pSelShowAllGuests);
	SystemSettingsStorage.Save("tcRoomsGanttChartHTMLDoNotAutoHide", SessionParameters.CurrentUser, pDoNotAutoHide);
EndProcedure // SaveSettingsAtServer

// -----------------------------------------------------------------------------
&AtServer
Function FillNewRowOrderBasket(pCreateData)
	vCheckInDate = pCreateData.Start;
	vCheckOutDate = pCreateData.End;
	
	If SelScale <> "day" Then
		vCheckInTime = 9 * 3600;
		vCheckOutTime = 22 * 3600;
		If ValueIsFilled(RoomRateBasket) And RoomRateBasket.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour Then
			If ValueIsFilled(RoomRateBasket.DefaultCheckInTime) Or ValueIsFilled(RoomRateBasket.DefaultCheckOutTime) Then
				vCheckInTime = RoomRateBasket.DefaultCheckInTime - BegOfDay(RoomRateBasket.DefaultCheckInTime);
			Else
				vCheckInTime = RoomRateBasket.ReferenceHour - BegOfDay(RoomRateBasket.ReferenceHour);
			EndIf;
			vCheckOutTime = RoomRateBasket.ReferenceHour - BegOfDay(RoomRateBasket.ReferenceHour);
			If ValueIsFilled(RoomRateBasket.DefaultCheckOutTime) Then
				vCheckOutTime = RoomRateBasket.DefaultCheckOutTime - BegOfDay(RoomRateBasket.DefaultCheckOutTime);
			EndIf;
		EndIf;
		vCheckInDate = cm1SecondShift(vCheckInDate + vCheckInTime);
		vCheckOutDate = cm0SecondShift(vCheckOutDate + vCheckOutTime);
		If BegOfDay(vCheckOutDate) <= BegOfDay(vCheckInDate) Then
			vCheckOutDate = vCheckOutDate + 24 * 3600;
		EndIf;
	Else
		vCheckInDate = BegOfHour(vCheckInDate);
		vCheckOutDate = EndOfHour(vCheckOutDate);
	EndIf;
	
	vDuration = cmCalculateDuration(RoomRateBasket, vCheckInDate, vCheckOutDate);
	
	vPrice = GetOrderBasketPrice(vCheckInDate, vCheckOutDate, pCreateData.RoomType);
	
	If vPrice = Undefined Then
		Return Undefined;
	EndIf;
	
	vNewRowOrderBasket = OrderBasket.Add();
	vNewRowOrderBasket.RoomRate = RoomRateBasket;
	vNewRowOrderBasket.Term = TermBasket;
	vNewRowOrderBasket.ClientTypes = ClientTypesBasket;
	vNewRowOrderBasket.Discount = DiscountBasket;
	vNewRowOrderBasket.Adults = AdultsBasket;
	vNewRowOrderBasket.Kids = KidsBasket;
	vNewRowOrderBasket.KidAge1 = KidAge1Basket;
	vNewRowOrderBasket.KidAge2 = KidAge2Basket;
	vNewRowOrderBasket.KidAge3 = KidAge3Basket;
	vNewRowOrderBasket.KidAge4 = KidAge4Basket;
	vNewRowOrderBasket.KidAge5 = KidAge5Basket;
	vNewRowOrderBasket.KidAge6 = KidAge6Basket;
	vNewRowOrderBasket.KidAge7 = KidAge7Basket;
	vNewRowOrderBasket.KidAge8 = KidAge8Basket;
	vNewRowOrderBasket.KidAge9 = KidAge9Basket;
	vNewRowOrderBasket.KidAge10 = KidAge10Basket;
	vNewRowOrderBasket.KidAge11 = KidAge11Basket;
	vNewRowOrderBasket.KidAge12 = KidAge12Basket;
	vNewRowOrderBasket.CheckInDate = vCheckInDate;
	vNewRowOrderBasket.CheckOutDate = vCheckOutDate;
	vNewRowOrderBasket.Duration = vDuration;
	vNewRowOrderBasket.Room = pCreateData.Room;
	vNewRowOrderBasket.RoomType = pCreateData.RoomType;
	vNewRowOrderBasket.Amount = vPrice.Amount;
	vNewRowOrderBasket.AccommodationTemplate = vPrice.AccommodationTemplate;
	vNewRowOrderBasket.Currency = vPrice.Currency;
	vNewRowOrderBasket.UUID = "NZ" + TrimAll(New UUID());
	
	Return vNewRowOrderBasket.UUID;
EndFunction // FillNewRowOrderBasket

// -----------------------------------------------------------------------------
&AtServer
Function GetOrderBasketPrice(pCheckInDate, pCheckOutDate, pRoomType)
	vResult = New Structure;
	
	vAgeArray = New Array;
	For vInd = 1 To KidsBasket Do
		Try
			vAge = ThisObject["KidAge" + String(vInd) + "Basket"];
			vAgeArray.Add(vAge);
		Except
		EndTry;
	EndDo;
	
	vGuestsQuantity = AdultsBasket + KidsBasket;
	
	vRoomTypes = cmGetRoomTypesByGuestQuantity(vGuestsQuantity, Catalogs.RoomTypes.EmptyRef(), SelHotel);
	
	vCustomer = Undefined;
	vContract = Undefined;
	If ValueIsFilled(GuestGroupBasket) Then
		vCustomer = GuestGroupBasket.Customer;
		vContract = GuestGroupBasket.Contract;
	EndIf;
	
	vCurRoomTypeAccTypes = Undefined;
	
	vProbeResObj = Documents.Reservation.CreateDocument();
	vProbeResObj.Hotel = SelHotel;
	vProbeResObj.pmFillAttributesWithDefaultValues(True);
	vProbeResObj.ClientType = ClientTypesBasket;
	vProbeResObj.ServicePackage = TermBasket;
	
	vAccommodationTemplate = Undefined;
	
	vRoomTypeBalances = cmGetRoomTypeBalancesTable(vRoomTypes, False, SelHotel, pCheckInDate, pCheckOutDate, ClientTypesBasket, vCustomer, vContract, DiscountBasket, , , , pRoomType, RoomRateBasket, , AdultsBasket, KidsBasket, vAgeArray, vProbeResObj, IsForFolioSplit, TermBasket, vAccommodationTemplate);
	If vRoomTypeBalances = Undefined Then
		Return Undefined;
	EndIf;
	
	vCurRoomTypeAccTypes = vRoomTypeBalances.FindRows(New Structure("RoomType", pRoomType));
	If vCurRoomTypeAccTypes.Count() = 0 Then
		vCurRoomTypeAccTypes = vRoomTypeBalances.FindRows(New Structure("RoomType", Catalogs.RoomTypes.EmptyRef()));
	EndIf;
	
	vAmount = 0;
	vCurrency = Catalogs.Currencies.EmptyRef();
	vDefCurrency = SelHotel.FolioCurrency;
	
	If vCurRoomTypeAccTypes <> Undefined Then
		For Each vCurRoomTypeAccTypesRow In vCurRoomTypeAccTypes Do
			vAmount = vAmount + vCurRoomTypeAccTypesRow.Amount;
			vCurrency = vCurRoomTypeAccTypesRow.Currency;
		EndDo;
	EndIf;
	
	If vProbeResObj <> Undefined Then
		For Each vCRRow In vProbeResObj.ChargingRules Do
			vFolioObj = vCRRow.ChargingFolio.GetObject();
			vFolioObj.Delete();
		EndDo;
		vProbeResObj = Undefined;
	EndIf;
	
	vResult.Insert("AccommodationTemplate", vAccommodationTemplate);
	vResult.Insert("Amount", vAmount);
	vResult.Insert("Currency", vCurrency);
	
	Return vResult;
EndFunction // GetPrice

// -----------------------------------------------------------------------------
&AtClient
Function NewGroup()
	vError = "";
	If CreateGuestGroupAtServer(vError) Then
		OpenForm("Catalog.GuestGroups.Form.tcItemForm", New Structure("Key", GuestGroupBasket), ThisObject);
		
		If Not IsBlankString(vError) Then
			tcCommonFunctionOnClientServer.TextMessage(vError, MessageStatus.Attention);
		EndIf;
		
		// Notify that group has changed
		Notify("Catalog.GuestGroups.Changed", GuestGroupBasket);
	Else
		tcCommonFunctionOnClientServer.TextMessage(vError, MessageStatus.Attention);
		Return False;
	EndIf;
	Return True;
EndFunction // NewGroup

// -----------------------------------------------------------------------------
&AtServer
Function CreateGuestGroupAtServer(rError = "") 
	rError = "";
	
	BeginTransaction(DataLockControlMode.Managed);
	Try
		If Not ValueIsFilled(SelHotel) Then
			Raise NStr("en='Hotel is not choosen!'; ru='Не выбрана гостиница'; de='Hotel ist nicht ausgewählt!'");
		EndIf;
		
		If Not ValueIsFilled(GuestGroupBasket) Then
			vGuestGroupObj = Catalogs.GuestGroups.CreateItem();
			vGuestGroupObj.Owner = SelHotel;
			vGuestGroupFolder = SelHotel.GetObject().pmGetGuestGroupFolder();
			If ValueIsFilled(vGuestGroupFolder) Then
				vGuestGroupObj.Parent = vGuestGroupFolder;
				vGuestGroupObj.SetNewCode();
			EndIf;
			vGuestGroupObj.OneCustomerPerGuestGroup = SelHotel.OneCustomerPerGuestGroup;
			vGuestGroupObj.Write();
			GuestGroupBasket = vGuestGroupObj.Ref;
		EndIf;
		
		// Process order basket rows
		For Each vOrderBasketRow In OrderBasket Do
			If ValueIsFilled(vOrderBasketRow.AccommodationTemplate) Then
				CreateOrderReservation(GuestGroupBasket, vOrderBasketRow, rError);
			EndIf;
		EndDo;
		
		CommitTransaction();
	Except
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		
		rError = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		Return False;
	EndTry;
	
	Return True;
EndFunction // CreateGuestGroupAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure CreateOrderReservation(pGuestGroup, pOrderBasketRow, rWarning = "")
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
			If vUpdateCR And ValueIsFilled(vDocObj.Customer) Then
				vDocObj.pmLoadDefaultChargingRules();
			EndIf;
		EndIf;
		vDocObj.RoomQuantity = 1;
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
		vDocObj.Write(DocumentWriteMode.Posting);
		vDocObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
		
		vResNumber = vDocObj.Number;
	EndDo;
EndProcedure // CreateOrderReservation

// -----------------------------------------------------------------------------
&AtServer
Function GetParameters(pOrderBasketRow, pAccommodationType = Undefined, pGuestGroup = Undefined)
	vRowStruct = Undefined;
	vGuestGroup = pGuestGroup;
	If pGuestGroup = Undefined Then
		vGuestGroup = GuestGroupBasket;
	EndIf;
	vCompany = Catalogs.Companies.EmptyRef();
	vCurHotel = SelHotel;
	If ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Company) Then
		vCompany = SessionParameters.CurrentUser.Company;
	ElsIf ValueIsFilled(vCurHotel.RoomRate) And ValueIsFilled(vCurHotel.RoomRate.Company) Then
		vCompany = vCurHotel.RoomRate.Company;
	ElsIf ValueIsFilled(pOrderBasketRow.RoomType) And ValueIsFilled(pOrderBasketRow.RoomType.Company) Then
		vCompany = pOrderBasketRow.RoomType.Company;
	ElsIf ValueIsFilled(vCurHotel.Company) Then
		vCompany = vCurHotel.Company;
	EndIf;
	vCheckInDate = pOrderBasketRow.CheckInDate;
	vCheckOutDate = pOrderBasketRow.CheckOutDate;
	
	If SelScale <> "day" Then
		If ValueIsFilled(pOrderBasketRow.CheckInDate) Then
			vCheckInDate = BegOfDay(pOrderBasketRow.CheckInDate);
		Else
			vCheckInDate = BegOfDay(CurrentSessionDate());
		EndIf;
		If ValueIsFilled(pOrderBasketRow.CheckOutDate) And BegOfDay(pOrderBasketRow.CheckOutDate) > vCheckInDate Then
			vCheckOutDate = BegOfDay(pOrderBasketRow.CheckOutDate);
		Else
			vCheckOutDate = vCheckInDate + 24*3600;
		EndIf;
		vCheckInTime = 9 * 3600;
		vCheckOutTime = 22 * 3600;
		If ValueIsFilled(RoomRateBasket) And RoomRateBasket.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour Then
			If ValueIsFilled(RoomRateBasket.DefaultCheckInTime) Or ValueIsFilled(RoomRateBasket.DefaultCheckOutTime) Then
				vCheckInTime = RoomRateBasket.DefaultCheckInTime - BegOfDay(RoomRateBasket.DefaultCheckInTime);
			Else
				vCheckInTime = RoomRateBasket.ReferenceHour - BegOfDay(RoomRateBasket.ReferenceHour);
			EndIf;
			vCheckOutTime = RoomRateBasket.ReferenceHour - BegOfDay(RoomRateBasket.ReferenceHour);
			If ValueIsFilled(RoomRateBasket.DefaultCheckOutTime) Then
				vCheckOutTime = RoomRateBasket.DefaultCheckOutTime - BegOfDay(RoomRateBasket.DefaultCheckOutTime);
			EndIf;
		EndIf;
		vCheckInDate = cm1SecondShift(vCheckInDate + vCheckInTime);
		vCheckOutDate = cm0SecondShift(vCheckOutDate + vCheckOutTime);
		If BegOfDay(vCheckOutDate) <= BegOfDay(vCheckInDate) Then
			vCheckOutDate = vCheckOutDate + 24 * 3600;
		EndIf;
	Else
		vCheckInDate = BegOfHour(vCheckInDate);
		vCheckOutDate = EndOfHour(vCheckOutDate);
	EndIf;
	vDuration = cmCalculateDuration(RoomRateBasket, vCheckInDate, vCheckOutDate);
	vKidsAges = New Array();
	For i = 1 To KidsBasket Do
		vKidsAges.Add(ThisObject["KidAge" + i + "Basket"]);
	EndDo;
	vRowStruct = New Structure("Hotel, RoomQuota, RoomType, Room, RoomQuantity, AccommodationType, CheckInDate, Duration, CheckOutDate, RoomRate, ClientType, Company, ServicePackage, SourceOfBusiness, MarketingCode, TripPurpose, GuaranteeType, DiscountType, IsForFolioSplit, NumberOfAdults, NumberOfKids, KidsAges", 
					vCurHotel, Undefined, pOrderBasketRow.RoomType, pOrderBasketRow.Room, 1, pAccommodationType, vCheckInDate, vDuration, vCheckOutDate, pOrderBasketRow.RoomRate,  pOrderBasketRow.ClientTypes, vCompany, pOrderBasketRow.Term, vGuestGroup.SourceOfBusiness, vGuestGroup.MarketingCode, vGuestGroup.TripPurpose, vGuestGroup.GuaranteeType, pOrderBasketRow.Discount, IsForFolioSplit, AdultsBasket, KidsBasket, vKidsAges);
	Return vRowStruct;
EndFunction // GetParameters

// -----------------------------------------------------------------------------
&AtClient
Function NewReserv()
	vError = "";
	vWarning = "";
	
	vOrderBasketRow = OrderBasket[0];
	
	vParams = GetNewReservationFormParameters(vError, vWarning);
	If Not IsBlankString(vError) Then
		tcCommonFunctionOnClientServer.TextMessage(vError, MessageStatus.Attention);
		Return False;
	EndIf;
	
	vParams.Insert("Template", vOrderBasketRow.AccommodationTemplate);
	If ValueIsFilled(GuestGroupBasket) Then
		vParams.Insert("GuestGroup", GuestGroupBasket);
	EndIf;
	OpenForm("Document.Reservation.Form.tcDocumentForm", vParams, ThisObject);
	
	If Not IsBlankString(vWarning) Then
		tcCommonFunctionOnClientServer.TextMessage(vWarning, MessageStatus.Attention);
	EndIf;
	
	Return True;
EndFunction // NewReserv

// -----------------------------------------------------------------------------
&AtServer
Function GetNewReservationFormParameters( rError = "", rWarning = "")
	rError = "";
	rWarning = "";
	vOrderBasketRow = OrderBasket[0];
	
	vRowStruct = GetParameters(vOrderBasketRow);
	// Check conditions
	If vOrderBasketRow.RoomType.StopSale Then
		vRemarks = "";
		If cmIsStopSalePeriod(vOrderBasketRow.RoomType, cm1SecondShift(vOrderBasketRow.CheckInDate), cm0SecondShift(vOrderBasketRow.CheckOutDate), vRemarks) Then
			If Not cmCheckUserPermissions("HavePermissionToIgnoreStopSaleLimitations") Then
				rError = NStr("en='You have chosen room type with stop sale flag turned on! Rechoose room type!';ru='Выбрали тип номера снятый с продажи! Перевыберите тип номера!';de='Sie haben einen Zimmertyp gewählt, der aus dem Angebot genommen wurde! Wählen Sie einen anderen Zimmertyp!'") + Chars.LF + vRemarks;
			Else
				rWarning = NStr("en='You have chosen room type with stop sale flag turned on!';ru='Выбрали тип номера снятый с продажи!';de='Sie haben einen Zimmertyp gewählt, der aus dem Angebot genommen wurde! Wählen Sie einen anderen Zimmertyp!'") + Chars.LF + vRemarks;
			EndIf;
		EndIf;
	EndIf;
	Return vRowStruct;
EndFunction // GetNewReservationFormParameters

#EndRegion