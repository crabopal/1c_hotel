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
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	SelDate = CurrentSessionDate();	
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
	SelHotel = SessionParameters.CurrentHotel;
	// Fill filter attributes by form parameters
	SelListMode = 0;
	SelShowAllGuests = 0;
	SelFilterStatus = "&ACTIVE";
	If Parameters.Property("SelFilterStatus") Then
		SelFilterStatus = Parameters.SelFilterStatus;
	EndIf;                                                       
	ListModes.Clear();
	ListModes.Add(0, NStr("en='Check-in date'; ru='Дата заезда'; de='Anreise Datum'") + "...", , GetListModeIconAtServer(0));
	ListModes.Add(1, NStr("en='Stay date'; ru='Дата пребывания'; de='Aufenthalt Datum'") + "...", , GetListModeIconAtServer(1));
	ListModes.Add(2, NStr("en='Check-out date'; ru='Дата выезда'; de='Abreise Datum'") + "...", , GetListModeIconAtServer(2));
	ListModes.Add(3, NStr("en='Create date'; ru='Дата создания'; de='Erstellen Datum'") + "...", , GetListModeIconAtServer(3));
	ListModes.Add(4, NStr("en='Edit date'; ru='Дата изменения'; de='Ändern Datum'") + "...", , GetListModeIconAtServer(4));
	ListModes.Add(5, NStr("en='Change status date'; ru='Дата изменения статуса'; de='Datum der Statusänderung'") + "...", , GetListModeIconAtServer(5));
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
		Items.ScanDocuments1.Visible = False;
	EndIf;
	Items.SelDateTo.Visible = False;
	SelInPeriod = False;
	// Fill functions
	FillFunctionsButton();
	// Fill printing forms
	FillPrintingButton();
	// Check if hotel can be changed
	If Not IsInRole("RightsToChooseHotel") Then
		Items.SelHotel.Enabled = False;
	EndIf;
EndProcedure // OnCreateAtServer

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
&AtClient
Procedure OnReopen()
	OnReopenAtServer();
EndProcedure // OnReopen

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
	// Manage list columns
	Items.DocumentListAccommodationTemplate.Visible = True;
	Items.DocumentListAccommodationType.Visible = (SelShowAllGuests = 1);
	
	Items.SelDate.Title = ListModes.Get(SelListMode).Presentation;
	Items.ChangeListMode.Title = ListModes.Get(SelListMode).Presentation;
	Items.ChangeListMode.Picture = ListModes.Get(SelListMode).Picture;
	
	vFilterStatusList = SelFilterStatusList.FindByValue(SelFilterStatus);
	If vFilterStatusList <> Undefined Then
		Items.ChangeFilterStatus.Title = vFilterStatusList.Presentation;
		Items.ChangeFilterStatus.Picture = vFilterStatusList.Picture;
	EndIf;
	
	vBalancesAreVisible = Not cmCheckUserPermissions("DoNotShowBalancesInLists");
	
	// Balances columns appearance
	Items.ClientSumBalance.Visible = vBalancesAreVisible;
	Items.CustomerSumBalance.Visible = vBalancesAreVisible;
	
	// Reservation list parameters
	ReservList.Parameters.SetParameterValue("qDate", SelDate);
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
	ReservList.Parameters.SetParameterValue("qAgent", SelAgent);
	ReservList.Parameters.SetParameterValue("qAgentIsFilled", ValueIsFilled(SelAgent));
	ReservList.Parameters.SetParameterValue("qGuestsList", GetListOfDocumentsByClient());
	ReservList.Parameters.SetParameterValue("qClientIsFilled", ValueIsFilled(SelClient));
	ReservList.Parameters.SetParameterValue("qRoom", SelRoom);
	ReservList.Parameters.SetParameterValue("qRoomIsFilled", ValueIsFilled(SelRoom));
	ReservList.Parameters.SetParameterValue("qRoomType", SelRoomType);
	ReservList.Parameters.SetParameterValue("qRoomTypeIsFilled", ValueIsFilled(SelRoomType));
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
	
	// Set form title
	Title = NStr("en='Reservation list: '; ru='Журнал брони: '; de='Reservierungsliste: '") + ?(ValueIsFilled(SelHotel), Catalogs.Hotels.pmGetHotelPrintName(SelHotel, SessionParameters.CurrentLanguage), "");
EndProcedure // SetDynamicListParametersAtServer

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
	SelFilterStatusList.Clear();
	SelFilterStatusList.Add("&ALL", NStr("en = 'All'; ru = 'Все'; de = 'All'"));
	SelFilterStatusList.Add("&ACTIVE", NStr("en = 'Active'; ru = 'Действующие'; de = 'Aktiv'"));
	vTrans = vElements.Select();
	While vTrans.Next() Do
		vResStatusIcon = pmGetReservationStatusIcon(vTrans.ReservationStatus);
				
		SelFilterStatusList.Add(vTrans.Code, vTrans.Description, , vResStatusIcon);
		
		If vTrans.ReservationStatus.IsCheckIn Then
			Continue;
		EndIf;
		
		// Add change reservation status command
		vCommandName = StrReplace("C" + String(vTrans.ReservationStatus.UUID()), "-", "_");
		If ThisForm.Commands.Find(vCommandName) = Undefined Then
			vCmd = ThisForm.Commands.Add(vCommandName);
			vCmd.Action = "ChangeStatus"; 
			vCmd.Title = TrimAll(vTrans.Description);
			vCmd.Picture = vResStatusIcon;
		EndIf;
				
		vItem = ThisForm.Items.Add(vCommandName + "_CM", Type("FormButton"), Items.ChangeStatuses1);
		vItem.Type = FormButtonType.CommandBarButton;
		vItem.CommandName = vCommandName; 	
		
		SelSetStatusListButton.Add(vTrans.ReservationStatus, vCommandName);
	EndDo;
	
	SelFilterStatusList.Add("&NOTPOSTED", NStr("en = 'Not posted'; ru = 'Не проведенные'; de = 'Nicht posted'"));
EndProcedure // FillFilterStatuses

// -----------------------------------------------------------------------------
&AtClient
Procedure ReservListOnActivateRow(pItem)
	AttachIdleHandler("ReservListOnActivateRowIdleHandler", 1, True);
EndProcedure // ReservListOnActivateRow

// -----------------------------------------------------------------------------
&AtClient
Procedure ReservListOnActivateRowIdleHandler()
	vNewReservTitle = NStr("en='New reservation'; ru='Новая бронь'; de='Neue Reservierung'");
	vGuestGroup = Undefined;
	vCurData = Items.ReservList.CurrentData;
	If vCurData <> Undefined Then
		vGuestGroup = vCurData.GuestGroup;
		If Not Items.SelectedDocumentActions.Enabled Then
			Items.SelectedDocumentActions.Enabled = True;
		EndIf;
		If TypeOf(vCurData.ReservationStatusIsArrivalSchedule) = Type("Boolean") And 
		   vCurData.ReservationStatusIsArrivalSchedule Then
			vNewReservTitle = NStr("en='New reserv. based on schedule'; ru='Новая бронь на основ. графика'; de='Neu basierend auf dem Zeitplan'");
		EndIf;
	Else
		If Items.SelectedDocumentActions.Enabled Then
			Items.SelectedDocumentActions.Enabled = False;
		EndIf;
	EndIf;
	If vNewReservTitle <> Items.NewReserv.Title Then
		Items.NewReserv.Title = vNewReservTitle;
	EndIf;
	If vGuestGroup <> CurGuestGroup Then
		CurGuestGroup = vGuestGroup;
	EndIf;
EndProcedure // ReservListOnActivateRowIdleHandler

// -----------------------------------------------------------------------------
&AtServer
Procedure SelListModesOnChangeAtServer()
	// Apply filter parameters
	SetDynamicListParametersAtServer();
EndProcedure // SelListModesOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SelListModesOnChange(pItem)
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
EndProcedure // SelListModesOnChangeAtServer

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
	// Apply filter parameters
	SetDynamicListParametersAtServer();
EndProcedure // SelGuestGroupOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SelGuestGroupOnChange(pItem)
	SelGuestGroupOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SelCustomerOnChangeAtServer()
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
Function GetMainDocRef(pRef)
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
	vSelResRow = pReservation;
	vMainRoomRef = GetMainDocRef(vSelResRow);
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
						If TypeOf(vResult) = Type("Structure") Then
							// Open new accommodation and fill group table from the given list
							OpenForm("Document.Accommodation.Form.mcDocumentForm", New Structure("GuestsToCheckInList", vResult.ValueList.Copy()), ThisForm);
						Else
							tcCommonFunctionOnClientServer.TextMessage(vResult);
						EndIf;
					EndIf;
				ElsIf TypeOf(vResult)=Type("Structure") Then
					// Open new accommodation and fill group table from the given list
					OpenForm("Document.Accommodation.Form.mcDocumentForm", New Structure("GuestsToCheckInList", vResult.ValueList.Copy()), ThisForm);
				ElsIf vResult <> "DoQueryBox" Then
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
				// Check current reservation list deposits
				CheckReservationsDeposits(vSelResList);
				vResult = CheckInAtServer(vMainRoomRef, false, vSelResList);
				If ValueIsFilled(vResult) Then
					If TypeOf(vResult)=Type("Structure") Then
						// Open new accommodation and fill group table from the given list
						OpenForm("Document.Accommodation.Form.mcDocumentForm", New Structure("GuestsToCheckInList", vResult.ValueList.Copy()), ThisForm);
					ElsIf vResult <> "DoQueryBox" Then
						tcCommonFunctionOnClientServer.TextMessage(vResult);
					EndIf;
				EndIf;
			ElsIf TypeOf(vResult)=Type("Structure") Then
				// Open new accommodation and fill group table from the given list
				OpenForm("Document.Accommodation.Form.mcDocumentForm", New Structure("GuestsToCheckInList", vResult.ValueList.Copy()), ThisForm);
			ElsIf vResult <> "DoQueryBox" Then
				tcCommonFunctionOnClientServer.TextMessage(vResult);
			EndIf;
		EndIf;
	EndIf;
EndProcedure //  CheckInByDoc() 

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
&AtClient
Procedure NewReservation(pCommand)
	If ValueIsFilled(SelHotel) Then
		vBasis = Undefined;
		vCurData = Items.ReservList.CurrentData;
		If vCurData <> Undefined Then
			If TypeOf(vCurData.ReservationStatusIsArrivalSchedule) = Type("Boolean") And 
			   vCurData.ReservationStatusIsArrivalSchedule Then
				vBasis = vCurData.Ref;
			EndIf;
		EndIf;
		If ValueIsFilled(vBasis) Then
			OpenForm("Document.Reservation.ObjectForm", New Structure("Basis", vBasis), ThisForm);
		Else
			OpenForm("Document.Reservation.ObjectForm", New Structure("Hotel", SelHotel), ThisForm, SelHotel);
		EndIf;
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Please, choose hotel first!'; ru='Пожалуйста выберите сначала отель!'; de='Bitte wählen Sie zuerst ein Hotel aus!'"));
	EndIf;
EndProcedure // NewReservation

// -----------------------------------------------------------------------------
&AtClient
Procedure CopyReservation(pCommand)
	// Ask if to clear guests from reservation
	vCurData = Items.ReservList.CurrentData;
	If vCurData <> Undefined And ValueIsFilled(vCurData.Ref) Then
		ShowQueryBox(New NotifyDescription("ShouldProgramClearGuestsOnReservationCopyAnswer", ThisForm, vCurData.Ref), 
		             NStr("en='Do you whant to clear guest names?'; ru='Очистить гостей в скопированной брони?'; de='Gäste in der kopierten Buchung löschen?'"), 
					 QuestionDialogMode.YesNoCancel, , DialogReturnCode.Yes);
	EndIf;
EndProcedure // CopyReservation

// -----------------------------------------------------------------------------
&AtClient
Procedure ShouldProgramClearGuestsOnReservationCopyAnswer(pAnswer, pDocRef) Export
	If pAnswer = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	If Not ValueIsFilled(pDocRef) Then
		Return;
	EndIf;
	vDocFormParameters = New Structure;
	vDocFormParameters.Insert("CopiedDocument", pDocRef);
	vDocFormParameters.Insert("ClearGuestsOnOpen", ?(pAnswer = DialogReturnCode.Yes, True, False));
	OpenForm("Document.Reservation.ObjectForm", vDocFormParameters, ThisForm);
EndProcedure // CopyReservation

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenFolios(Command)
	vRef = Items.ReservList.CurrentRow;
	If Not vRef = Undefined Then
		vParametersStructure = New Structure("DocRef", vRef);
		OpenForm("CommonForm.tcFoliosForm", New Structure("ParametersStructure", vParametersStructure), , vRef);
	EndIf;
EndProcedure // OpenFolios

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
		SelRoom = Undefined;
		SetDynamicListParametersAtServer();
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
	EndIf;
EndProcedure // NotificationProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure RefreshListAndTotals() Export
	If IsInputAvailable() Then
		Items.ReservList.Refresh();
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
	vNum = 0;
	For Each vResListItem In vResList Do
		If ValueIsFilled(vResListItem.Value) Then
			// Get reservation reference
			vResRef = vResListItem.Value;
			If vResRef.ReservationStatus <> vStatusRef Or vResRef.GuaranteeType <> vGuaranteeType Then
				// Check user rights
				If Not cmCheckUserPermissions("HavePermissionToEditClosedForEditDocuments") Then
					If vResRef.IsClosedForEdit Then
						tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to change closed for edit document!';ru='Нет прав на изменение документа с включенным запретом редактирования!';de='Sie haben keine Rechte, das Dokument zu bearbeiten mit eingeschlossenem Bearbeitungsverbot!'"));
						vNum = vNum + 1;
						Continue;
					EndIf;
				EndIf;
				If Not cmCheckUserPermissions("HavePermissionToEditReservations") Then
					If (Not ValueIsFilled(vResRef.Author.Department) And vResRef.Author <> SessionParameters.CurrentUser Or 
						ValueIsFilled(vResRef.Author.Department) And vResRef.Author <> SessionParameters.CurrentUser And 
						ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Department) And 
						vResRef.Author.Department <> SessionParameters.CurrentUser.Department) Then
						tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to change posted reservations created by other users!';ru='Нет прав на изменение чужой проведенной брони!';de='Sie haben keine Rechte, eine von einer anderen Person ausgeführte Reservierung zu bearbeiten!'"));
						vNum = vNum + 1;
						Continue;
					EndIf;
				EndIf;
				If Not cmCheckUserPermissions("HavePermissionToEditInactiveReservations") Then
					If ValueIsFilled(vResRef.ReservationStatus) And Not vResRef.ReservationStatus.IsActive And Not vResRef.ReservationStatus.IsPreliminary And Not vResRef.ReservationStatus.IsInWaitingList Then
						tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to edit inactive reservations!';ru='Нет прав на изменение не активной брони!';de='Sie haben keine Rechte, nicht aktive Reservierungen zu bearbeiten!'"));
						vNum = vNum + 1;
						Continue;
					EndIf;
				EndIf;
				If Not cmCheckUserPermissions("HavePermissionToEditAccommodations") Then
					If ValueIsFilled(vResRef.ReservationStatus) And vResRef.ReservationStatus.IsCheckIn Then
						tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to change checked-in reservations!';ru='Нет прав на изменение брони в статусе заезд!';de='Sie haben keine Rechte, die Reservierung im Status der Anreise zu bearbeiten!'"));
						vNum = vNum + 1;
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
		vNum = vNum + 1;
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
			OpenForm("Catalog.UsualActionReasons.ChoiceForm", New Structure("ChoiceMode", True), ThisForm, , , , New NotifyDescription("UsualActionReasonAfterUserChoice", ThisForm, New Structure("StatusArr", vStatusArr)), FormWindowOpeningMode.LockOwnerWindow);
			Return;
		EndIf;
		// Ask user to choose guarantee type
		vGuaranteeType = vStatusArr.GuaranteeType;
		If Not ValueIsFilled(vGuaranteeType) And vStatusArr.IsGuaranteed And vStatusArr.GuaranteeTypesCount > 0 Then
			OpenForm("Catalog.GuaranteeTypes.ChoiceForm", New Structure("ChoiceMode", True), ThisForm, , , , New NotifyDescription("GuaranteeTypeAfterUserChoice", ThisForm), FormWindowOpeningMode.LockOwnerWindow);
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
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Annulation reason should be filled!'; ru='Причина аннуляции должна быть указана!'; de='Stornogrund gefüllt werden sollten!'"));
		Return;
	Else
		// Ask user to choose guarantee type
		vGuaranteeType = Undefined;
		If pExtraParams <> Undefined And pExtraParams.StatusArr.IsGuaranteed And pExtraParams.StatusArr.GuaranteeTypesCount > 0 Then
			OpenForm("Catalog.GuaranteeTypes.ChoiceForm", New Structure("ChoiceMode", True), ThisForm, , , , New NotifyDescription("GuaranteeTypeAfterUserChoice", ThisForm, New Structure("AnnulationReason", pAnnulationReason)), FormWindowOpeningMode.LockOwnerWindow);
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
		tcCommonFunctionOnClientServer.TextMessage(NStr("ru='Вид гарантии должен быть выбран!';en='Guarantee type should be filled!';de='Art der Garantie sollte ausgefüllt werden!'"));
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
	If Items.ShowGroupDetails.Check Then
		pStandardProcessing = False;
	Else
		vRowID = Undefined;
		If TypeOf(pSelectedRow) = Type("Array") Then
			If pSelectedRow.Count() = 1 Then
				vRowID = pSelectedRow.Get(0);
			EndIf;
		Else
			vRowID = pSelectedRow;
		EndIf;
		If vRowID <> Undefined Then
			vRowData = Items.ReservList.RowData(vRowID);
			If vRowData <> Undefined Then
				If Not Items.ReservList.ChoiceMode Then
					pStandardProcessing = False;
					If pField.Name = "DocumentListGroupCode" And ValueIsFilled(vRowData.GuestGroup) Then
						OpenForm("Catalog.GuestGroups.Form.tcItemForm", New Structure("Key", vRowData.GuestGroup));
					Else
						If SelShowAllGuests And Not ValueIsFilled(vRowData.AccommodationTemplate) Then
							OpenForm("Document.Reservation.ObjectForm", New Structure("Key", vRowData.Ref));
						Else
							OpenForm("Document.Reservation.ObjectForm", New Structure("Key, OneGuestMode", vRowData.Ref, False));
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ReservListSelection

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
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='Card do not have room or client specified!';ru='У карты не указан ни номер комнаты ни клиент!';de='Bei der Karte sind weder Zimmernummer noch Kunde angegeben!'"), 3);
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

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintGuestRegistrationFormsForExpectedCheckIn(pCommand)
	vDocument = PredefinedValue("Document.Reservation.EmptyRef");
	vGuestGroup = PredefinedValue("Catalog.GuestGroups.EmptyRef");
	vObjPrtForm = tcOnServer.cmGetCatalogItemRefByName("ObjectPrintingForms", "ReservationPrintGuestRegistrationForm");
	vFrm = OpenForm("Document.Accommodation.Form.tcPrintGuestForm", New Structure("CheckInDate, Document, GuestGroup, ObjectPrintingForm", BegOfDay(CurrentDate()), vDocument, vGuestGroup, vObjPrtForm), ThisForm);
EndProcedure // PrintGuestRegistrationFormsForExpectedCheckIn

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeListMode(pCommand)
	vNotifyDescription = New NotifyDescription("ListModesAfterChoice", ThisForm);
	vParams = New Structure("ValueList, MultipleChoice, Title", ListModes, False);
	OpenForm("CommonForm.mcChoiceValueList", vParams, ThisForm, UUID,,,vNotifyDescription);
EndProcedure // ChangeListMode

// -----------------------------------------------------------------------------
&AtClient
Procedure ListModesAfterChoice(pItem, pExtraParameters) Export
	If pItem <> Undefined Then
		SelListMode = pItem.Value;
		SelListModesOnChange(Items.SelListModes);
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
	For Each vRow In pRows Do
		vRowValue = vRow.Value;
		If vBalancesAreVisible = Undefined Then
			vBalancesAreVisible = vRowValue.Data.BalancesAreVisible;
			If Not vBalancesAreVisible Then
				Break;
			EndIf;
		EndIf;
	EndDo;
	vBalances = Undefined;
	If vBalancesAreVisible Then
		vList = pRows.GetKeys();
		If vSelShowAllGuests = 0 Then
			vBalances = GetBalancesByRooms(vList);
		Else
			vBalances = GetBalancesByGuests(vList);
		EndIf;
	EndIf;
	// Colors and other appearances
	For Each vRow In pRows Do
		vRowValue = vRow.Value;
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
					vDocRef = vRowValue.Data.Ref;
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
		// Set cell back color for the reservations according to the customer colors
		vCustomerColorHexString = TrimAll(vRowValue.Data["CustomerColorHexString"]);
		If Not IsBlankString(vCustomerColorHexString) Then
			vCustomerAppearance = vRowValue.Appearance.Get("Customer");
			If vCustomerAppearance <> Undefined Then
				vColor = tcOnServer.HexToColor(vCustomerColorHexString);
				vCustomerAppearance.SetParameterValue("BackColor", vColor);
			EndIf;
		EndIf;
		// Set cell back color for the reservations according to the agent colors
		// Set cell back color for the reservations according to the agent colors
		vAgentColorHexString = TrimAll(vRowValue.Data["AgentColorHexString"]);
		If Not IsBlankString(vAgentColorHexString) Then
			vAgentAppearance = vRowValue.Appearance.Get("Agent");
			If vAgentAppearance <> Undefined Then
				vColor = tcOnServer.HexToColor(vAgentColorHexString);
				vAgentAppearance.SetParameterValue("BackColor", vColor);
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
	"SELECT
	|	ClientDataScans.Ref
	|FROM
	|	Document.ClientDataScans AS ClientDataScans
	|WHERE
	|	ClientDataScans.ParentDoc = &qParentDoc
	|	AND (ClientDataScans.Guest = &qClient
	|			OR &qClientIsEmpty)
	|	AND NOT ClientDataScans.DeletionMark";
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
		|	ClientDataScans.Date DESC";
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
				OpenForm("Document.ClientDataScans.ObjectForm", New Structure("Key, Guest, ParentDoc, GuestGroup, Room", vScanRef, vRefArr.Guest, vRef, vRefArr.GuestGroup, vRefArr.Room), ThisForm, vRef);
			Else
				OpenForm("Document.ClientDataScans.ObjectForm", New Structure("basis", vRef), ThisForm, vRef);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ScanDocuments

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenChangeHistory(pCommand)
	vRowData = Items.ReservList.CurrentData;
	If vRowData <> Undefined Then
		vFrm = OpenForm("InformationRegister.ReservationChangeHistory.ListForm", New Structure("Filter", New Structure("Reservation", vRowData.Ref)), ThisForm, vRowData.Ref);
		vFrm.ReadOnly = ThisForm.ReadOnly;
	EndIf;
EndProcedure // OpenChangeHistory

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenInHouseGuests(pCommand)
	vRowData = Items.ReservList.CurrentData;
	If vRowData <> Undefined Then
		OpenForm("Document.Accommodation.Form.mcAccommodationListForm", New Structure("SelGuestGroup, SelFilterStatus, SelShowAllGuests", vRowData.GuestGroup, 0, SelShowAllGuests), ThisForm, vRowData.GuestGroup);
	EndIf;
EndProcedure // OpenInHouseGuests

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenProformaInvoiceList(pCommand)
	vRowData = Items.ReservList.CurrentData;
	If vRowData <> Undefined Then
		OpenForm("Document.ProformaInvoice.Form.tcListForm", New Structure("SelGuestGroup", vRowData.GuestGroup), ThisForm, vRowData.GuestGroup);
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
			
			tcOnServer.cmCreateItem(ThisForm, ?(vSelectionRecords.IsDefault, Items.FormGroupFunctionsDefault1, Items.FormGroupFunctionsNotDefault1), "Func_1_"+vID, "FormButton", vStructure);
		EndIf;
	EndDo;
EndProcedure // FillFunctionsButton

// -----------------------------------------------------------------------------
&AtClient
Procedure FuncButtonClick(Command)
	vRowData = Items.ReservList.CurrentData;
	If vRowData <> Undefined Then
		vActionsNumber = StrReplace(Command.Name, "Func", "");
		vAction = GetActionForNumber(vActionsNumber);
		
		If ValueIsFilled(vAction.ExternalProcessing) Then
		Else
			If vAction.PredefinedDataName = "ReservationFillInvoice" Then
				vParam = New Structure;
				vParam.Insert("ParentDoc", vRowData.Ref);
				OpenForm("Document.ProformaInvoice.Form.tcDocumentForm", vParam, ThisForm, True);	
			ElsIf vAction.PredefinedDataName = "ReservationGuestGroupFillInvoice" Then
				vParam = New Structure;
				vParam.Insert("basis", vRowData.GuestGroup);
				OpenForm("Document.ProformaInvoice.Form.tcDocumentForm", vParam, ThisForm, True);
			ElsIf vAction.PredefinedDataName = "ReservationSendMyFolioSMS" Then
				SendWelcomeSMS(Commands.SendWelcomeToMyFolioSystemSMS);
			ElsIf vAction.PredefinedDataName = "ReservationFillOrder" Then
				vParam = New Structure;
				vParam.Insert("basis", vRowData.Ref);
				OpenForm("Document.Order.Form.DocumentForm", vParam, ThisForm, True);
			// Run data processor
			ElsIf ValueIsFilled(vAction.DataProcessor) Then     
				vReturnParameter = New Structure("Action, Data, FileName");
				If Not RunDataProcessor(vAction.DataProcessor, vRowData.Ref, True, vReturnParameter) Then
					tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to run data processor!';ru='Не удалось выполнить обработку!';de='Die Bearbeitung ist fehlgeschlagen!'"));
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
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='No data processor found for action!';ru='У действия не указан обработчик!';de='Bei der Aktion ist kein Bearbeiter angegeben!'"));
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
	vLang = Catalogs.Languages.EN;
	If ValueIsFilled(SelHotel) Then
		vLang = SelHotel.Language;
	EndIf;
	While vSelectionRecords.Next() Do
		vSelectionDetailRecords = vSelectionRecords.Select(QueryResultIteration.ByGroups);
		
		If vLang = vSelectionRecords.Language or not ValueIsFilled(vSelectionRecords.Language) Then
			vParentLang1 = Items.FormGroupPrintingNotDefaultMain1;
		ElsIf not vLang = vSelectionRecords.Language Then
			vParentLang1 = tcOnServer.cmCreateItem(ThisForm, Items.FormGroupPrintingNotDefaultExtra1, "Print"+vSelectionRecords.Language+"1", "FormGroup", New Structure("Type,Title",	FormGroupType.Popup, vSelectionRecords.Language));
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
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationRu"  
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationEn"  
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationDe"  
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationWithServicesRu"  
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationWithServicesEn"  		
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationWithServicesDe" 
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
					vParent1 = Items.FormGroupPrintingDefault1;
				Else
					vParent1 = vParentLang1;
				EndIf;
				vStructure = New Structure("Title,CommandName", TrimAll(vSelectionDetailRecords.Code) + " " + cmNStr(vSelectionDetailRecords.ref), "Print"+vID);
				
				tcOnServer.cmCreateItem(ThisForm, vParent1, "Print_1_"+vID, "FormButton", vStructure);
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
			PrintHotelProduct(vPrintForm.Language, vPrintForm.Ref, vRowData.Ref);
		ElsIf vPrintForm.PredefinedDataName = "ReservationPrintConfirmationRu" Or
		      vPrintForm.PredefinedDataName = "ReservationPrintConfirmationEn" Or
			  vPrintForm.PredefinedDataName = "ReservationPrintConfirmationDe" Then
			vFrm = GetForm("Document.Reservation.Form.tcReservationConfirmationForm", , New UUID());
			vFrm.FormOwner = ThisForm;
			vFrm.CloseOnOwnerClose = False;
			vFrm.SelReservation = vRowData.Ref;
			vFrm.SelLanguage = tcOnServer.cmGetAttributeByRef(vPrintForm.Ref, "Language");
			vFrm.SelObjectPrintForm = vPrintForm.Ref;
			vFrm.Open();
		ElsIf vPrintForm.PredefinedDataName = "ReservationPrintConfirmationWithServicesRu" Or
		      vPrintForm.PredefinedDataName = "ReservationPrintConfirmationWithServicesEn" Or
			  vPrintForm.PredefinedDataName = "ReservationPrintConfirmationWithServicesDe" Then
			vFrm = GetForm("Document.Reservation.Form.tcReservationConfirmationWithServicesForm", , New UUID());
			vFrm.FormOwner = ThisForm;
			vFrm.CloseOnOwnerClose = False;
			vFrm.SelReservation = vRowData.Ref;
			vFrm.SelLanguage = tcOnServer.cmGetAttributeByRef(vPrintForm.Ref, "Language");
			vFrm.SelObjectPrintForm = vPrintForm.Ref;
			vFrm.Open();
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
			OpenForm("DataProcessor.ReservationConfirmationRichTextFormat.Form", vParams, ThisForm, New UUID());
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintGuestForm(pTypeOfPrintForm, pDocRef)
	vObjPrtForm = tcOnServer.cmGetCatalogItemRefByName("ObjectPrintingForms", pTypeOfPrintForm);
	vFrm = OpenForm("Document.Accommodation.Form.tcPrintGuestForm", New Structure("Document, GuestGroup, ObjectPrintingForm", pDocRef, Undefined, vObjPrtForm), ThisForm, pDocRef);
EndProcedure // PrintGuestForm

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintGuestsForms(pTypeOfPrintForm, pDocRef)
	vObjPrtForm = tcOnServer.cmGetCatalogItemRefByName("ObjectPrintingForms", pTypeOfPrintForm);
	vFrm = OpenForm("Document.Accommodation.Form.tcPrintGuestForm", New Structure("Document, GuestGroup, ObjectPrintingForm", pDocRef, pDocRef.GuestGroup, vObjPrtForm), ThisForm, pDocRef);
EndProcedure // PrintGuestsForms

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
	OpenForm("ExternalDataProcessor." + vName + ".Form.tcReservationConfirmationForm", vParams);
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
Procedure PrintHotelProduct(pLang, pForm, pDocRef)
	#If Not ThickClientOrdinaryApplication or not webclient Then
		vReport = Undefined;
		If ValueIsFilled(pForm.Report) Then
			vReport = cmBuildReportObject(pForm.Report);
		ElsIf ValueIsFilled(pForm.ExternalProcessing) Then
			vReport = cmGetExternalDataProcessorObject(pForm.ExternalProcessing);
		Else
			vReport = Reports.PrintHotelProducts.Create();
		EndIf;
		If pForm = Catalogs.ObjectPrintingForms.ReservationPrintHotelProduct Then
			vReport.Document = pDocRef;
		EndIf;
		vReport.GuestGroup = pDocRef.GuestGroup;
		Try
			vReport.Room = pDocRef.Room;
			vReport.CheckInDate = BegOfDay(pDocRef.CheckInDate);
		Except
		EndTry;
		vFrm = vReport.GetForm();
		vFrm.SelObjectPrintForm = pForm;
		vFrm.Open();
	#EndIf
EndProcedure

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
		vDocsList.Add(pDocRef.Ref);
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
	// Apply hotel selected
	SetDynamicListParametersAtServer();
EndProcedure // SelHotelOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SelHotelOnChange(pItem)
	SelHotelOnChangeAtServer();
EndProcedure // SelHotelOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure SelHotelClearingAtServer()
	SessionParameters.CurrentHotel = Catalogs.Hotels.EmptyRef();
EndProcedure // SelHotelClearingAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SelHotelClearing(pItem, pStandardProcessing)
	SelHotelClearingAtServer();
	Notify("System.Hotel.Changed", PredefinedValue("Catalog.Hotels.EmptyRef"));
EndProcedure // SelHotelClearing

// -----------------------------------------------------------------------------
&AtClient
Procedure RecalculateActiveReservationsPrices(pCommand)
	OpenForm("CommonForm.tcRecalculateReservationPrices", New Structure("Hotel", SelHotel), , SelHotel);
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
	If Not ValueIsFilled(SelHotel) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Hotel should be selected!'; ru='Гостиница должна быть выбрана!'; de='Hotel sollte ausgewählt werden!'"));
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
		OpenForm("Document.Reservation.Form.tcRoomAssignmentForm", New Structure("SelHotel, SelReservations", SelHotel, vReservations), ThisForm);
	ElsIf ValueIsFilled(SelDate) Then
		OpenForm("Document.Reservation.Form.tcRoomAssignmentForm", New Structure("SelHotel, SelCheckInDate", SelHotel, BegOfDay(SelDate)), ThisForm);
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Please specify either check-in date filter or select more then one reservation in the list!'; 
		                      |ru='Пожалуйста либо укажите отбор по дате заезда либо выделите в списке более одной брони!'; 
							  |de='Bitte wählen Sie Anreisedatum-Filter oder wählen Sie mehr als eine Reservierung in der Liste aus!'"));
	EndIf;
EndProcedure // RoomAssignment

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowFiletGroup(pCommand)
	Items.FilterGroup.Visible = Not Items.FilterGroup.Visible; 
	Items.ShowFiletGroup.Check = Items.FilterGroup.Visible;
EndProcedure // ShowFiletGroup

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowGroupDetails(pCommand)
	vCurrentData = Items.ReservList.CurrentRow;
	If ValueIsFilled(CurGuestGroup) Then
		OpenForm("Document.Reservation.Form.mcGroupDetailsForm", New Structure("SelGuestGroup", CurGuestGroup), ThisForm, ThisForm.UUID);
	EndIf;
EndProcedure // ShowGroupDetails

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeFilterStatus(pCommand)
	vNotifyDescription = New NotifyDescription("FilterStatusListAfterChoice", ThisForm);
	vParams = New Structure("ValueList, MultipleChoice, Title", SelFilterStatusList, False);
	OpenForm("CommonForm.mcChoiceValueList", vParams, ThisForm, UUID,,,vNotifyDescription);
EndProcedure // ChangeFilterStatus

// -----------------------------------------------------------------------------
&AtClient
Procedure FilterStatusListAfterChoice(pItem, pExtraParameters) Export
	If pItem <> Undefined Then
		SelFilterStatus = pItem.Value;
		SetDynamicListParametersAtServer();
	EndIf;
EndProcedure // FilterStatusListAfterChoice
