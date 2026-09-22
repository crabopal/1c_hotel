
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToChangeRoomStatuses") Then
		Items.ChangeStatus.ReadOnly = True;
	EndIf;
	DescriptionRoom = TrimAll(Object.Description) + " " + TrimAll(Object.RoomType.Code);
	FillRoomStatusChoiceList();
	
	FillTypeWork();
	FiilEmployees();
	FillRoomGuestsData();
	FillTasksPresentation();
	FillBedsSetupChoiceList();

	// Save current room status and beds setup
	SavRoomStatus = Object.RoomStatus;
	SavBedsSetup = Object.BedsSetup;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	If Items.Pages.CurrentPage = Items.PageConsumption Or Items.Pages.CurrentPage = Items.PageChangeArticle Then
		pCancel = True;	
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Finish changing the articles first'; de = 'Beenden Sie das ändern der Artikel zuerst'; ru = 'Сначала закончите изменения номенклатуры'"));
	EndIf;
EndProcedure // BeforeWrite

// --------------------------------------------------------------------------------
&AtServer
Procedure AfterWriteAtServer(pCurrentObject, pWriteParameters)
	If Not pCurrentObject.DeletionMark Then
		If SavRoomStatus <> pCurrentObject.RoomStatus Then
			pCurrentObject.pmWriteToRoomStatusChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser, "");
			SavRoomStatus = pCurrentObject.RoomStatus;
		EndIf;
		If SavBedsSetup <> pCurrentObject.BedsSetup Then
			pCurrentObject.pmWriteToRoomChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			SavBedsSetup = pCurrentObject.BedsSetup;
		EndIf;
	EndIf;
EndProcedure // AfterWriteAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure DecorationTasksClick(pItem)
	stParam = New Structure("SetParamObject", Object.Ref);
	OpenForm("DataProcessor.Messages.Form.tcForm", stParam);
	Notify("DataProcessor.Messages.Form.Open", stParam);
EndProcedure // DecorationTasksClick

// -----------------------------------------------------------------------------
&AtClient
Procedure SelStatusRoomListAfterChoose(pItem, pExtraParams) Export
	If pItem <> Undefined Then
		If Object.RoomStatus <> pItem.Value Then
			Object.RoomStatus = pItem.Value;
			Modified = True;
			FillRoomStatusChoiceList();
		EndIf;
	EndIf;
EndProcedure // SelStatusRoomListAfterChoose

// -----------------------------------------------------------------------------
&AtClient
Procedure ArticlesRefOnChange(pItem)
	ArticlesRefOnChangeAtServer();
EndProcedure // ArticlesRefOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ArticlesSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	ArticlesAction = "Change";
	pStandardProcessing = False;
	vItem = Items.Articles.CurrentData; 
	ArticlesSelectedRow = vItem.GetID();
	ArticlesRef = vItem.Article;
	ArticlesPlannedQuantity = vItem.PlannedQuantity; 
	ArticlesQuantity = vItem.Quantity;
	ArticlesQuantityPerUnit = vItem.QuantityPerUnit;
	ArticlesUnit = vItem.Unit; 
	ArticlesIsPerPerson = vItem.IsPerPerson; 
	ArticlesIsPerRoomSpaceUnit = vItem.IsPerRoomSpaceUnit;
	Items.Pages.CurrentPage = Items.PageChangeArticle;
EndProcedure // ArticlesSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure ArticlesIsPerPersonOnChange(pItem)
	CalculateArticleQuantity();
EndProcedure // ArticlesIsPerPersonOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ArticlesIsPerRoomSpaceUnitOnChange(pItem)
	CalculateArticleQuantity();
EndProcedure // ArticlesIsPerRoomSpaceUnitOnChange

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure NewTask(pCommand)
	OpenForm("Document.Message.ObjectForm", New Structure("Type, SetParamObject", PredefinedValue("Enum.MessageTypes.Task"), Object.Ref), ThisObject, UUID);
EndProcedure // NewTask

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeStatus(pCommand)
	ShowChooseFromMenu(New NotifyDescription("SelStatusRoomListAfterChoose", ThisObject), SelStatusRoomList, Items.ChangeStatus);
EndProcedure // ChangeStatus

// -----------------------------------------------------------------------------
&AtClient
Procedure ArticlesAdd(pCommand)
	ArticlesAction = "Add";
	vItem = Articles.Add();
	ArticlesSelectedRow = vItem.GetID();
	ArticlesRef = vItem.Article;
	ArticlesPlannedQuantity = vItem.PlannedQuantity; 
	ArticlesQuantity = vItem.Quantity;
	ArticlesQuantityPerUnit = vItem.QuantityPerUnit = 0;
	ArticlesUnit = vItem.Unit; 
	ArticlesIsPerPerson = False; 
	ArticlesIsPerRoomSpaceUnit = False;
	Items.Pages.CurrentPage = Items.PageChangeArticle;
EndProcedure // ArticlesAdd

// -----------------------------------------------------------------------------
&AtClient
Procedure ArticlesQuantityPerUnitPlus(pCommand)
	ArticlesQuantityPerUnit = ArticlesQuantityPerUnit + 1;	
	CalculateArticleQuantity();
EndProcedure // ArticlesQuantityPerUnitPlus

// -----------------------------------------------------------------------------
&AtClient
Procedure ArticlesQuantityPerUnitMinus(pCommand)
	ArticlesQuantityPerUnit = ArticlesQuantityPerUnit - 1;
	CalculateArticleQuantity();
EndProcedure // ArticlesQuantityPerUnitMinus 

// -----------------------------------------------------------------------------
&AtClient
Procedure ArticlesCancelChange(pCommand)
	If ArticlesAction = "Add" Then
		If ArticlesSelectedRow <> Undefined Then
			vItemRow = Articles.FindByID(ArticlesSelectedRow);
			Articles.Delete(vItemRow);
		EndIf;
		ArticlesRef = PredefinedValue("Catalog.Articles.EmptyRef");
		ArticlesPlannedQuantity = 0; 
		ArticlesQuantity = 0; 
		ArticlesQuantityPerUnit = 0;
		ArticlesUnit = ""; 
		ArticlesIsPerPerson = False; 
		ArticlesIsPerRoomSpaceUnit = False;
		ArticlesSelectedRow = Undefined;
		Items.Pages.CurrentPage = Items.PageConsumption;
	Else
		ArticlesRef = PredefinedValue("Catalog.Articles.EmptyRef");
		ArticlesPlannedQuantity = 0; 
		ArticlesQuantity = 0; 
		ArticlesQuantityPerUnit = 0;
		ArticlesUnit = ""; 
		ArticlesIsPerPerson = False; 
		ArticlesIsPerRoomSpaceUnit = False;
		ArticlesSelectedRow = Undefined;
		Items.Pages.CurrentPage = Items.PageConsumption;		
	EndIf;
EndProcedure // ArticlesCancel

// -----------------------------------------------------------------------------
&AtClient
Procedure ArticlesSaveChange(pCommand)
	If ValueIsFilled(ArticlesRef) Then
		CalculateArticleQuantity();
		If ArticlesSelectedRow <> Undefined Then
			vItemRow = Articles.FindByID(ArticlesSelectedRow);
			If vItemRow <> Undefined Then 
				vItemRow.Article = ArticlesRef;
				vItemRow.Quantity = ArticlesQuantity;
				vItemRow.QuantityPerUnit = ArticlesQuantityPerUnit;
				vItemRow.Unit = ArticlesRef;
				If ValueIsFilled(ArticlesPlannedQuantity) Then
					vItemRow.PlannedQuantity = ArticlesPlannedQuantity;
				Else
					vItemRow.PlannedQuantity = GetPlanedUnit(Object.Owner, Object.RoomType, Object.Ref, tcOnServer.cmGetAttributeByRef(ConsumptionRef, "Operation"), ArticlesRef);	
				EndIf;
				vItemRow.IsPerPerson = ArticlesIsPerPerson;
				vItemRow.IsPerRoomSpaceUnit = ArticlesIsPerRoomSpaceUnit;
			EndIf;
		EndIf;
		ArticlesRef = PredefinedValue("Catalog.Articles.EmptyRef");
		ArticlesPlannedQuantity = 0; 
		ArticlesQuantity = 0;
		ArticlesQuantityPerUnit = 0;
		ArticlesUnit = ""; 
		ArticlesIsPerPerson = False; 
		ArticlesIsPerRoomSpaceUnit = False;
		ArticlesSelectedRow = Undefined;
		Items.Pages.CurrentPage = Items.PageConsumption;
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'The Article must be filled'; de = 'Der Artikel muss ausgefüllt werden'; ru = 'Номенклатура должна быть заполнена'"));
	EndIf;
EndProcedure // ArticlesSave

// -----------------------------------------------------------------------------
&AtClient
Procedure ArticlesSave(pCommand)
	ArticlesSaveAtServer();	
EndProcedure // ArticlesSave

// -----------------------------------------------------------------------------
&AtClient
Procedure ArticlesCancel(pCommand)
	Articles.Clear();
	Items.Pages.CurrentPage = Items.PageMain;
EndProcedure // ArticlesCancel

// -----------------------------------------------------------------------------
&AtClient
Procedure Consumption(pCommand)
	If ValueIsFilled(ConsumptionRef) Then
		FillArticlesTable();
		Items.Pages.CurrentPage = Items.PageConsumption;
	EndIf;
EndProcedure // Consumption

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure FillRoomStatusChoiceList()                                     
	vPresEmptyStatus = NStr("en = '<Empty status>'; de = '<Leerer Status>'; ru = '<Пустой статус>'");
	Items.ChangeStatus.Picture = cmGetRoomStatusIcon(Object.RoomStatus); 
	Items.ChangeStatus.Title = ?(ValueIsFilled(Object.RoomStatus), TrimAll(Object.RoomStatus), vPresEmptyStatus);
	vRoomStatusesTable = cmGetAllowedRoomStatuses(, Object.RoomStatus);
	SelStatusRoomList.Clear();
	For Each vRow In vRoomStatusesTable Do
		SelStatusRoomList.Add(vRow.RoomStatus, ?(ValueIsFilled(vRow.RoomStatus), TrimAll(vRow.RoomStatus), vPresEmptyStatus), , cmGetRoomStatusIcon(vRow.RoomStatus));
	EndDo; 
	If SelStatusRoomList.FindByValue(Object.RoomStatus) = Undefined Then
		SelStatusRoomList.Insert(0, Object.RoomStatus, ?(ValueIsFilled(Object.RoomStatus), TrimAll(Object.RoomStatus), vPresEmptyStatus), , cmGetRoomStatusIcon(Object.RoomStatus));
	EndIf;
	If (SelStatusRoomList.Count() = 1 And SelStatusRoomList.Get(0).Value = Object.RoomStatus) Or SelStatusRoomList.Count() = 0 Then
		Items.ChangeStatus.Enabled = False;	
	Else
		Items.ChangeStatus.Enabled = True;	
	EndIf;
EndProcedure // FillRoomStatusChoiceList

// -----------------------------------------------------------------------------
&AtServer
Procedure FiilEmployees()
	vObj = FormAttributeToValue("Object");
	vRoomStatusHistory = vObj.pmGetRoomStatusHistoryState(CurrentSessionDate());
	If vRoomStatusHistory.Count() > 0 Then
		Items.GroupEmployees.Visible = True;
		EmployeeWhoChangedRoomStatus = vRoomStatusHistory[0].User;
		DateChangedRoomStatus  = vRoomStatusHistory[0].Period; 
	Else
		Items.GroupEmployees.Visible = False;
		EmployeeWhoChangedRoomStatus = "";
		DateChangedRoomStatus = Date(1, 1, 1, 0, 0, 0);
	EndIf;
EndProcedure // 

// -----------------------------------------------------------------------------
&AtServer
Procedure FillTypeWork()
	vQuery = New Query();
	vQuery.Text = "SELECT
	              |	EmployeeOperation.Operation AS Operation,
	              |	EmployeeOperation.Ref AS Ref
	              |FROM
	              |	Document.EmployeeOperation AS EmployeeOperation
	              |WHERE
	              |	EmployeeOperation.Room = &qRoom
	              |	AND EmployeeOperation.OperationEndConfirmedTime = DATETIME(1, 1, 1, 0, 0, 0)
	              |
	              |ORDER BY
	              |	EmployeeOperation.OperationStartTime DESC";
	vQuery.SetParameter("qRoom", Object.Ref);
	vResult = vQuery.Execute().Unload();
	If vResult.Count() > 0 Then
		SelOperation = vResult[0].Operation;
		ConsumptionRef = vResult[0].Ref;
		Items.SelOperation.Visible = True;
		Items.Consumption.Visible = True;
	Else
		Items.SelOperation.Visible = False;
		Items.Consumption.Visible = False;
		SelOperation = "";
	EndIf;
EndProcedure // FillTypeWork

// -----------------------------------------------------------------------------
&AtServer
Procedure FillRoomGuestsData()	
	SelAccommodationTemplates = ""; 
	SelHousekeepingRemarksAccommodation = "";
	SelReservationTemplates = ""; 
	SelHousekeepingRemarksReservation = "";
	vDate = CurrentSessionDate(); 
	While Items.GroupGuestAccommodation.ChildItems.Count() > 0 Do
		Items.Delete(Items.GroupGuestAccommodation.ChildItems[0]);
	EndDo;
	While Items.GroupGuestReservation.ChildItems.Count() > 0 Do
		Items.Delete(Items.GroupGuestReservation.ChildItems[0]);
	EndDo;
	vQuery = New Query();
	vQuery.Text = "SELECT
	              |	Accommodation.GuestFullName AS GuestFullName,
	              |	Accommodation.CheckOutDate AS CheckOutDate,
	              |	Accommodation.AccommodationTemplate AS AccommodationTemplate,
	              |	Accommodation.HousekeepingRemarks AS HousekeepingRemarks
	              |FROM
	              |	Document.Accommodation AS Accommodation
	              |WHERE
	              |	NOT Accommodation.DeletionMark
	              |	AND Accommodation.Posted
	              |	AND Accommodation.Room = &qRoom
	              |	AND Accommodation.AccommodationStatus.IsActive
	              |	AND Accommodation.AccommodationStatus.IsInHouse";
	vQuery.SetParameter("qRoom", Object.Ref);
	vResult = vQuery.Execute().Unload();
	vNumber = 0;
	If vResult.Count() > 0 Then
		Items.GroupAccommodation.Visible = True;
		For Each vRowItem In vResult Do
			vNumber = vNumber + 1;
			If ValueIsFilled(vRowItem.AccommodationTemplate) Then
				SelAccommodationTemplates = vRowItem.AccommodationTemplate; 	
			EndIf; 
			vText = New FormattedString(New FormattedString(vRowItem.GuestFullName, tcCommonFunctionOnClientServer.FontConstructor(StyleFonts.NormalTextFont, , 11)), ?(BegOfDay(vDate) <= vRowItem.CheckOutDate And EndOfDay(vDate) >= vRowItem.CheckOutDate, New FormattedString(NStr("en = ' check out: '; de = ' Abreise: '; ru = ' выезд: '") + Format(vRowItem.CheckOutDate, "DF=HH:mm"), tcCommonFunctionOnClientServer.FontConstructor(StyleFonts.NormalTextFont, , 11, True)), New FormattedString("")));
			vStructure = New Structure("Type, Title", FormDecorationType.Label, vText);		
			tcOnServer.cmCreateItem(ThisObject, Items.GroupGuestAccommodation, "GuestAccommodation" + vNumber, "FormDecoration", vStructure);
			If ValueIsFilled(vRowItem.HousekeepingRemarks) Then
				SelHousekeepingRemarksAccommodation = SelHousekeepingRemarksAccommodation + vRowItem.HousekeepingRemarks + Chars.LF;
			EndIf;
		EndDo;
	Else
		Items.GroupAccommodation.Visible = False;
		Items.Minibar.Visible = False;
	EndIf;
	If Not ValueIsFilled(SelAccommodationTemplates) Then
		SelAccommodationTemplates = NStr("en = '0 pers.'; de = '0 pers.'; ru = '0 чел.'"); 	
	EndIf;
	vQuery = New Query();
	vQuery.Text = "SELECT
	              |	Reservation.GuestFullName AS GuestFullName,
	              |	Reservation.CheckInDate AS CheckInDate,
	              |	Reservation.AccommodationTemplate AS AccommodationTemplate,
	              |	Reservation.HousekeepingRemarks AS HousekeepingRemarks
	              |FROM
	              |	Document.Reservation AS Reservation
	              |WHERE
	              |	NOT Reservation.DeletionMark
	              |	AND Reservation.Posted
	              |	AND Reservation.Room = &qRoom
	              |	AND BEGINOFPERIOD(&qDate, DAY) <= Reservation.CheckInDate
	              |	AND ENDOFPERIOD(&qDate, DAY) >= Reservation.CheckInDate
	              |	AND Reservation.ReservationStatus.IsActive";
	vQuery.SetParameter("qRoom", Object.Ref);
	vQuery.SetParameter("qDate", vDate);
	vResult = vQuery.Execute().Unload();
	vNumber = 0;
	If vResult.Count() > 0 Then
		Items.GroupReservation.Visible = True;
		For Each vRowItem In vResult Do
			vNumber = vNumber + 1;
			If ValueIsFilled(vRowItem.AccommodationTemplate) Then
				SelReservationTemplates = vRowItem.AccommodationTemplate;
			EndIf; 
			vText = New FormattedString(New FormattedString(vRowItem.GuestFullName, tcCommonFunctionOnClientServer.FontConstructor(StyleFonts.NormalTextFont, , 11)), 
					New FormattedString(NStr("en = ' check in: '; de = ' Anreise: '; ru = ' заезд: '") + Format(vRowItem.CheckInDate, "DF=HH:mm"), tcCommonFunctionOnClientServer.FontConstructor(StyleFonts.NormalTextFont, , 11, True)));
			vStructure = New Structure("Type, Title", FormDecorationType.Label, vText);		
			tcOnServer.cmCreateItem(ThisObject, Items.GroupGuestReservation, "GuestReservation" + vNumber, "FormDecoration", vStructure);
			If ValueIsFilled(vRowItem.HousekeepingRemarks) Then
				SelHousekeepingRemarksReservation = SelHousekeepingRemarksReservation + vRowItem.HousekeepingRemarks + Chars.LF;
			EndIf;
		EndDo;
	Else
		Items.GroupReservation.Visible = False;	
	EndIf;
	If Not ValueIsFilled(SelReservationTemplates) Then
		SelReservationTemplates = NStr("en = '0 pers.'; de = '0 pers.'; ru = '0 чел.'"); 	
	EndIf;
EndProcedure // FillRoomGuestsData

// -----------------------------------------------------------------------------
&AtServer
Procedure FillTasksPresentation()
	TTasks = "";
	If ValueIsFilled(Object.Ref) Then
		vTasks = cmGetMessagesForObject(Object.Ref);
		For Each vTasksRow In vTasks Do
			TTasks = TTasks + "• " + TrimAll(vTasksRow.Remarks) + Chars.LF;
		EndDo;
	EndIf;	
	Items.DecorationTasks.Title = TTasks;
	If IsBlankString(TTasks) Then
		Items.DecorationTasks.Visible = False;
		Items.GroupTasks.ShowTitle = False;
	Else
		Items.DecorationTasks.Visible = True;
		Items.GroupTasks.ShowTitle = True;
	EndIf;
EndProcedure // FillTasksPresentation

// -----------------------------------------------------------------------------
&AtServer
Procedure ArticlesRefOnChangeAtServer()
	ArticlesUnit = ArticlesRef.Unit;
	ArticlesPlannedQuantity = GetPlanedUnit(Object.Owner, Object.RoomType, Object.Ref, ConsumptionRef.Operation, ArticlesRef);  
EndProcedure // ArticlesRefOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetPlanedUnit(pHotel, pRoomType, pRoom, pOperation, pArticle)
	vStds = New ValueTable();
	
	If ValueIsFilled(pOperation) Then
		// Get data from the standards table for the room
		If ValueIsFilled(pRoom) Then
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	ArticleConsumptionStandards.Article AS Article,
			|	ArticleConsumptionStandards.Quantity AS Quantity,
			|	ArticleConsumptionStandards.Unit AS Unit,
			|	ArticleConsumptionStandards.IsPerPerson AS IsPerPerson,
			|	ArticleConsumptionStandards.IsPerRoomSpaceUnit AS IsPerRoomSpaceUnit
			|FROM
			|	InformationRegister.ArticleConsumptionStandards AS ArticleConsumptionStandards
			|WHERE
			|	ArticleConsumptionStandards.Operation = &qOperation
			|	AND ArticleConsumptionStandards.Hotel = &qHotel
			|	AND ArticleConsumptionStandards.Room = &qRoom
			|	AND ArticleConsumptionStandards.Article = &qArticle
			|
			|ORDER BY
			|	ArticleConsumptionStandards.Article.SortCode";
			vQry.SetParameter("qOperation", pOperation);
			vQry.SetParameter("qHotel", pHotel);
			vQry.SetParameter("qRoom", pRoom);
			vQry.SetParameter("qArticle", pArticle);	
			vStds = vQry.Execute().Unload();
		EndIf;
		
		// Get data from the standards table for the room type
		If vStds.Count() = 0 And ValueIsFilled(pRoomType) Then
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	ArticleConsumptionStandards.Article AS Article,
			|	ArticleConsumptionStandards.Quantity AS Quantity,
			|	ArticleConsumptionStandards.Unit AS Unit,
			|	ArticleConsumptionStandards.IsPerPerson AS IsPerPerson,
			|	ArticleConsumptionStandards.IsPerRoomSpaceUnit AS IsPerRoomSpaceUnit
			|FROM
			|	InformationRegister.ArticleConsumptionStandards AS ArticleConsumptionStandards
			|WHERE
			|	ArticleConsumptionStandards.Operation = &qOperation
			|	AND ArticleConsumptionStandards.Hotel = &qHotel
			|	AND ArticleConsumptionStandards.RoomType = &qRoomType
			|	AND ArticleConsumptionStandards.Room = &qRoom
			|	AND ArticleConsumptionStandards.Article = &qArticle
			|
			|ORDER BY
			|	ArticleConsumptionStandards.Article.SortCode";
			vQry.SetParameter("qOperation", pOperation);
			vQry.SetParameter("qHotel", pHotel);
			vQry.SetParameter("qRoomType", pRoomType);
			vQry.SetParameter("qRoom", Catalogs.Rooms.EmptyRef());
			vQry.SetParameter("qArticle", pArticle);
			vStds = vQry.Execute().Unload();
		EndIf;
		
		// Get data from the standards table for the hotel and empty room and room type
		If vStds.Count() = 0 Then
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	ArticleConsumptionStandards.Article AS Article,
			|	ArticleConsumptionStandards.Quantity AS Quantity,
			|	ArticleConsumptionStandards.Unit AS Unit,
			|	ArticleConsumptionStandards.IsPerPerson AS IsPerPerson,
			|	ArticleConsumptionStandards.IsPerRoomSpaceUnit AS IsPerRoomSpaceUnit
			|FROM
			|	InformationRegister.ArticleConsumptionStandards AS ArticleConsumptionStandards
			|WHERE
			|	ArticleConsumptionStandards.Operation = &qOperation
			|	AND ArticleConsumptionStandards.Hotel = &qHotel
			|	AND ArticleConsumptionStandards.RoomType = &qRoomType
			|	AND ArticleConsumptionStandards.Room = &qRoom
			|	AND ArticleConsumptionStandards.Article = &qArticle
			|
			|ORDER BY
			|	ArticleConsumptionStandards.Article.SortCode";
			vQry.SetParameter("qOperation", pOperation);
			vQry.SetParameter("qHotel", pHotel);
			vQry.SetParameter("qRoomType", Catalogs.RoomTypes.EmptyRef());
			vQry.SetParameter("qRoom", Catalogs.Rooms.EmptyRef());
			vQry.SetParameter("qArticle", pArticle);
			vStds = vQry.Execute().Unload();
		EndIf;
		
		// Get data from the standards table for the empty hotel, room and room type
		If vStds.Count() = 0 Then
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	ArticleConsumptionStandards.Article AS Article,
			|	ArticleConsumptionStandards.Quantity AS Quantity,
			|	ArticleConsumptionStandards.Unit AS Unit,
			|	ArticleConsumptionStandards.IsPerPerson AS IsPerPerson,
			|	ArticleConsumptionStandards.IsPerRoomSpaceUnit AS IsPerRoomSpaceUnit
			|FROM
			|	InformationRegister.ArticleConsumptionStandards AS ArticleConsumptionStandards
			|WHERE
			|	ArticleConsumptionStandards.Operation = &qOperation
			|	AND ArticleConsumptionStandards.Hotel = &qHotel
			|	AND ArticleConsumptionStandards.RoomType = &qRoomType
			|	AND ArticleConsumptionStandards.Room = &qRoom
			|	AND ArticleConsumptionStandards.Article = &qArticle
			|
			|ORDER BY
			|	ArticleConsumptionStandards.Article.SortCode";
			vQry.SetParameter("qOperation", pOperation);
			vQry.SetParameter("qHotel", Catalogs.Hotels.EmptyRef());
			vQry.SetParameter("qRoomType", Catalogs.RoomTypes.EmptyRef());
			vQry.SetParameter("qRoom", Catalogs.Rooms.EmptyRef());
			vQry.SetParameter("qArticle", pArticle);
			vStds = vQry.Execute().Unload();
		EndIf;
		
		// Add rows to the articles tabular part
		If vStds.Count() > 0 Then
			Return vStds[0].Quantity;	
		EndIf;
	EndIf;	
EndFunction // GetPlanedUnit

// -----------------------------------------------------------------------------
&AtServer
Procedure CalculateArticleQuantity()
	If ArticlesIsPerRoomSpaceUnit Then
		If ArticlesIsPerPerson Then
			ArticlesQuantity = ConsumptionRef.Quantity * ArticlesQuantityPerUnit * ConsumptionRef.RoomSpace * ConsumptionRef.NumberOfPersons;
		Else
			ArticlesQuantity = ConsumptionRef.Quantity * ArticlesQuantityPerUnit * ConsumptionRef.RoomSpace;
		EndIf;
	Else
		If ArticlesIsPerPerson Then
			ArticlesQuantity = ConsumptionRef.Quantity * ArticlesQuantityPerUnit * ConsumptionRef.NumberOfPersons;
		Else
			ArticlesQuantity = ConsumptionRef.Quantity * ArticlesQuantityPerUnit;
		EndIf;
	EndIf;
EndProcedure // pmCalculateArticleQuantity

// -----------------------------------------------------------------------------
&AtServer
Procedure ArticlesSaveAtServer()
	vObj = ConsumptionRef.GetObject(); 
	vNewTable = vObj.Articles; 
	vNewTable.Clear();
	For Each vItem In Articles Do
		vNewRow = vNewTable.Add();
		vNewRow.Article = vItem.Article;
		vNewRow.QuantityPerUnit = vItem.QuantityPerUnit;
		vNewRow.PlannedQuantity = vItem.PlannedQuantity;
		vNewRow.Unit = vItem.Unit;
		vNewRow.IsPerPerson = vItem.IsPerPerson;
		vNewRow.IsPerRoomSpaceUnit = vItem.IsPerRoomSpaceUnit;
		vNewRow.Quantity = vItem.Quantity;
	EndDo;
	vObj.Write(DocumentWriteMode.Posting);
	Articles.Clear();
	Items.Pages.CurrentPage = Items.PageMain;
EndProcedure // ArticlesSaveAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillArticlesTable()
	Articles.Clear();
	For Each vItem In ConsumptionRef.Articles Do
		vNewItem = Articles.Add();
		vNewItem.Article = vItem.Article; 
		vNewItem.Quantity = vItem.Quantity;
		vNewItem.Unit = vItem.Unit;
		vNewItem.QuantityPerUnit = vItem.QuantityPerUnit;
		vNewItem.PlannedQuantity = vItem.PlannedQuantity;
		vNewItem.IsPerPerson = vItem.IsPerPerson;
		vNewItem.IsPerRoomSpaceUnit = vItem.IsPerRoomSpaceUnit;
	EndDo;
EndProcedure // FillArticlesTable

// --------------------------------------------------------------------------------
&AtServer
Procedure FillBedsSetupChoiceList()
	vUseBedsSetup = False;
	If ValueIsFilled(Object.Owner) Then
		vUseBedsSetup = Object.Owner.BedsSetups;
	EndIf;
	Items.BedsSetup.Visible = vUseBedsSetup;
	Items.BedsSetup.ChoiceList.Clear();
	If vUseBedsSetup Then
		If ValueIsFilled(Object.RoomType) Then
			If Object.RoomType.AllowedBedsSetups.Count() > 0 Then
				For Each vRow In Object.RoomType.AllowedBedsSetups Do
					If Items.BedsSetup.ChoiceList.FindByValue(vRow.BedsSetup) = Undefined Then
						If ValueIsFilled(vRow.BedsSetup) Then
							Items.BedsSetup.ChoiceList.Add(vRow.BedsSetup);
						Else
							Items.BedsSetup.ChoiceList.Insert(0, vRow.BedsSetup, NStr("en='<Empty>'; ru='<Пустая>'; de='<Leer>'"));
						EndIf;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		If Items.BedsSetup.ChoiceList.FindByValue(Object.BedsSetup) = Undefined Then
			Items.BedsSetup.ChoiceList.Insert(0, Object.BedsSetup, ?(ValueIsFilled(Object.BedsSetup), TrimAll(Object.BedsSetup), NStr("en='<Empty>'; ru='<Пустая>'; de='<Leer>'")));
		EndIf;
	EndIf;
EndProcedure // FillBedsSetupChoiceList

#EndRegion
