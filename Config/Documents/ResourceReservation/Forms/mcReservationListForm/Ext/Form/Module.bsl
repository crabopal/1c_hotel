
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
		If pReservationStatus.IsActive Then
			If pReservationStatus.ServicesAreDelivered Then
				vPicture = PictureLib.Pin;
			ElsIf pReservationStatus.IsGuaranteed Then
				vPicture = PictureLib.AccumulationRegister;
			Else
				vPicture = PictureLib.IsActive;
			EndIf;
		Else
			vPicture = PictureLib.IsNotActive;
		EndIf;
	EndIf;
	Return vPicture;
EndFunction // pmGetReservationStatusIcon

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	SelDate = '00010101';	
	If Parameters.Property("SelDocPeriod") Then
		SelDate = Parameters.SelDocPeriod;
	EndIf;
	If Parameters.Property("SelDate") Then
		SelDate = Parameters.SelDate;
	EndIf;
	If Parameters.Property("SelResourceType") Then
		SelResourceType = Parameters.SelResourceType;
	EndIf;
	If Parameters.Property("SelResource") Then
		SelResource = Parameters.SelResource;
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
	If Parameters.Property("SelHotel") Then
		SelHotel = Parameters.SelHotel;
	Else
		SelHotel = SessionParameters.CurrentHotel;
	EndIf;
	// Fill filter attributes by form parameters
	SelListMode = 0;
	SelShowAllGuests = 0;
	SelFilterStatus = "&ACTIVE";
	If Parameters.Property("SelFilterStatus") Then
		SelFilterStatus = Parameters.SelFilterStatus;
	EndIf;
	ListModes.Clear();
	ListModes.Add(0, NStr("en='Start date'; ru='Дата начала'; de='Startdatum'") + "...", , GetListModeIconAtServer(0));
	ListModes.Add(1, NStr("en='Stay date'; ru='Дата пребывания'; de='Aufenthalt Datum'") + "...", , GetListModeIconAtServer(1));
	ListModes.Add(2, NStr("en='End date'; ru='Дата окончания'; de='Enddatum'") + "...", , GetListModeIconAtServer(2));
	ListModes.Add(3, NStr("en='Create date'; ru='Дата создания'; de='Erstellen Datum'") + "...", , GetListModeIconAtServer(3));
	ListModes.Add(4, NStr("en='Edit date'; ru='Дата изменения'; de='Ändern Datum'") + "...", , GetListModeIconAtServer(4));
	ListModes.Add(5, NStr("en='Change status date'; ru='Дата изменения статуса'; de='Datum der Statusänderung'") + "...", , GetListModeIconAtServer(5));
	// Fill list of reservation statuses
	FillFilterStatuses();
	// Agent user
	If ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Customer) Then
		SelCustomer = SessionParameters.CurrentUser.Customer;
		Items.SelCustomer.ReadOnly = True;
		Items.SelCustomer.ChoiceButton = False;
		Items.SelCustomer.ClearButton = False;
		Items.SelCustomer.OpenButton = False;
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
	// Add dynamic conditional appearance
	AddListDynamicConditionalAppearance();
	// Apply filter parameters
	SetDynamicListParametersAtServer();
	// Atems visibility
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
Procedure AddListDynamicConditionalAppearance()
	// Add client types color
	vRefs = cmGetAllClientTypes(SelHotel);
	For Each vRefsRow In vRefs Do
		vColor = tcCommonFunctionOnClientServer.cmGetColorFromValueStorage(vRefsRow.ClientType);
		If vColor <> Undefined Then
			tcCommonFunctionOnClientServer.cmAddBackColorToTheListCell(ReservList, "ClientType", vRefsRow.ClientType, "ClientTypeCode", vColor);
		EndIf;
	EndDo;
	
	// Add reservation statuses
	vRefs = cmGetAllResourceReservationStatuses();
	For Each vRefsRow In vRefs Do
		vColor = tcCommonFunctionOnClientServer.cmGetColorFromValueStorage(vRefsRow.ResourceReservationStatus);
		If vColor <> Undefined Then
			tcCommonFunctionOnClientServer.cmAddBackColorToTheListCell(ReservList, "ReservationStatus", vRefsRow.ResourceReservationStatus, "ReservationStatus", vColor);
		EndIf;
	EndDo;
EndProcedure // AddListDynamicConditionalAppearance

// -----------------------------------------------------------------------------
&AtServer
Procedure SetDynamicListParametersAtServer()
	// Manage list columns
	Items.SelDate.Title = ListModes.Get(SelListMode).Presentation;
	Items.ChangeListMode.Title = ListModes.Get(SelListMode).Presentation;
	Items.ChangeListMode.Picture = ListModes.Get(SelListMode).Picture;
	
	
	vBalancesAreVisible = Not cmCheckUserPermissions("DoNotShowBalancesInLists");
	
	// Balances columns appearance
	Items.ClientSumBalance.Visible = vBalancesAreVisible;
	Items.CustomerSumBalance.Visible = vBalancesAreVisible;
	
	// Reservation list parameters
	ReservList.Parameters.SetParameterValue("qInPeriod", SelInPeriod);
	ReservList.Parameters.SetParameterValue("qDate", SelDate);
	ReservList.Parameters.SetParameterValue("qDateTo", EndOfDay(SelDateTo));
	ReservList.Parameters.SetParameterValue("qDateIsFilled", ValueIsFilled(SelDate));
	ReservList.Parameters.SetParameterValue("qEndOfDate", ?(ValueIsFilled(SelDate), EndOfDay(SelDate), '00010101'));
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
	ReservList.Parameters.SetParameterValue("qClient", SelClient);
	ReservList.Parameters.SetParameterValue("qClientIsFilled", ValueIsFilled(SelClient));
	ReservList.Parameters.SetParameterValue("qResource", SelResource);
	ReservList.Parameters.SetParameterValue("qResourceIsFilled", ValueIsFilled(SelResource));
	ReservList.Parameters.SetParameterValue("qResourceType", SelResourceType);
	ReservList.Parameters.SetParameterValue("qResourceTypeIsFilled", ValueIsFilled(SelResourceType));
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
	ReservList.Parameters.SetParameterValue("qResourceReservationStatus", Catalogs.ResourceReservationStatuses.FindByCode(TrimAll(SelFilterStatus), False));
	ReservList.Parameters.SetParameterValue("qSearchByDateFrom", SelListMode = 0);
	ReservList.Parameters.SetParameterValue("qSearchByStayDate", SelListMode = 1);
	ReservList.Parameters.SetParameterValue("qSearchByDateTo", SelListMode = 2);
	ReservList.Parameters.SetParameterValue("qSearchByCreateDate", SelListMode = 3);
	ReservList.Parameters.SetParameterValue("qSearchByChangeDate", SelListMode = 4);
	ReservList.Parameters.SetParameterValue("qSearchByStatusChangeDate", SelListMode = 5);
	ReservList.Parameters.SetParameterValue("qBalancesAreVisible", vBalancesAreVisible);
	
	// Fill group invoices list parameters
	SetGroupProformaInvoicesDynamicListParametersAtServer();

	// Set form title
	Title = NStr("en='Resource reservation list: '; ru='Журнал брони ресурсов: '; de='Ressource Reservierungsliste: '") + ?(ValueIsFilled(SelHotel), Catalogs.Hotels.pmGetHotelPrintName(SelHotel, SessionParameters.CurrentLanguage), "");
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
	|	ReservationStatuses.ServicesAreDelivered AS ServicesAreDelivered,
	|	ReservationStatuses.SortCode AS SortCode
	|FROM
	|	Catalog.ResourceReservationStatuses AS ReservationStatuses
	|WHERE
	|	NOT ReservationStatuses.DeletionMark
	|	AND NOT ReservationStatuses.IsFolder
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
	ListFilterStatus.Clear();
	ListFilterStatus.Add("&ALL", NStr("en = 'All'; ru = 'Все'; de = 'All'"));
	ListFilterStatus.Add("&ACTIVE", NStr("en = 'Active'; ru = 'Действующие'; de = 'Aktiv'"));
	vTrans = vElements.Select();
	While vTrans.Next() Do
		vResStatusIcon = pmGetReservationStatusIcon(vTrans.ReservationStatus);
		
		ListFilterStatus.Add(vTrans.Code, vTrans.Description, , vResStatusIcon);
		
		// Add change reservation status command
		vCommandName = StrReplace("C" + String(vTrans.ReservationStatus.UUID()), "-", "_");
		If Commands.Find(vCommandName) = Undefined Then
			vCmd = Commands.Add(vCommandName);
			vCmd.Action = "ChangeStatus"; 
			vCmd.Title = TrimAll(vTrans.Description);
			vCmd.Picture = vResStatusIcon;
		EndIf;
				
		vItem = Items.Add(vCommandName + "_CM", Type("FormButton"), Items.ChangeStatuses1);
		vItem.Type = FormButtonType.CommandBarButton;
		vItem.CommandName = vCommandName; 	
		
		SelSetStatusListButton.Add(vTrans.ReservationStatus, vCommandName);
	EndDo;
	
	ListFilterStatus.Add("&NOTPOSTED", NStr("en = 'Not posted'; ru = 'Не проведенные'; de = 'Nicht posted'"));
EndProcedure // FillFilterStatuses

// -----------------------------------------------------------------------------
&AtServer
Procedure FilterStatusOnChangeAtServer()
	// Apply filter parameters
	SetDynamicListParametersAtServer();
EndProcedure // FilterStatusOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ReservListOnActivateRow(pItem)
	vGuestGroup = Undefined;
	vCurData = pItem.CurrentData;
	If vCurData <> Undefined Then
		vGuestGroup = vCurData.GuestGroup;
		If Not Items.SelectedDocumentActions.Enabled Then
			Items.SelectedDocumentActions.Enabled = True;
		EndIf;
		TReservation = vCurData.Ref;
	Else
		If Items.SelectedDocumentActions.Enabled Then
			Items.SelectedDocumentActions.Enabled = False;
		EndIf;
		TReservation = Undefined;
	EndIf;
	If vGuestGroup <> CurGuestGroup Then
		CurGuestGroup = vGuestGroup;
		AttachIdleHandler("RefreshGroupTotals", 0.7, True);
	EndIf;
EndProcedure // ReservListOnActivateRow

// -----------------------------------------------------------------------------
&AtClient
Procedure RefreshGroupTotals()
	UpdateTotalsByGroupAtServer();
	AttachIdleHandler("GetRefreshGroupTotalsJobResult", 1, True);
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
Procedure SelResourceOnChangeAtServer()
	// Apply filter parameters
	SetDynamicListParametersAtServer();
EndProcedure // SelResourceOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SelResourceOnChange(Item)
	SelResourceOnChangeAtServer();
EndProcedure // SelResourceOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure SelResourceTypeOnChangeAtServer()
	If ValueIsFilled(SelResourceType) Then
		vLink = New ChoiceParameterLink("Filter.Owner", "SelResourceType");
		vLinkArray = New Array();
		vLinkArray.Add(vLink);
		vLinks = New FixedArray(vLinkArray);
		Items.SelResource.ChoiceParameterLinks = vLinks;
	Else
		vLinkArray = New Array();
		vLinks = New FixedArray(vLinkArray);
		Items.SelResource.ChoiceParameterLinks = vLinks;
	EndIf;
	// Apply filter parameters
	SetDynamicListParametersAtServer();
EndProcedure // SelResourceTypeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SelResourceTypeOnChange(pItem)
	SelResourceTypeOnChangeAtServer();
EndProcedure // SelResourceTypeOnChange

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
&AtClient
Procedure NewReservation(pCommand)
	If ValueIsFilled(SelHotel) Then
		OpenForm("Document.ResourceReservation.ObjectForm", , ThisObject);
	Else
		ShowMessageBox(, NStr("en='Please, choose hotel first!'; ru='Пожалуйста выберите сначала отель!'; de='Bitte wählen Sie zuerst ein Hotel aus!'"));
	EndIf;
EndProcedure // NewReservation

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
		SelResourceType = Undefined;
		SelResource = Undefined;
		SetDynamicListParametersAtServer();
		SetGroupProformaInvoicesDynamicListParametersAtServer();
		UpdateTotalsByGroupAtServer();
		AttachIdleHandler("GetRefreshGroupTotalsJobResult", 1, True);
	ElsIf pEventName = "Document.ResourceReservation.Write" Or 
	      pEventName = "Document.ResourceReservation.WriteNew" Or 
		  pEventName = "Document.Charge.Write" Or 
		  pEventName = "Document.Storno.Write" Or 
		  pEventName = "Document.Payment.Write" Or 
		  pEventName = "Document.Return.Write" Or 
		  pEventName = "Document.DepositTransfer.Write" Or 
		  pEventName = "Document.ChargeTransfer.Write" Or 
		  pEventName = "Subsystem.Accounts.Changed" Then
		AttachIdleHandler("RefreshListAndTotals", 1, True);
	EndIf;
EndProcedure // NotificationProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure RefreshListAndTotals() Export
	If IsInputAvailable() Then
		Items.ReservList.Refresh();
		Items.GroupProformaInvoices.Refresh();
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
			vResList.Add(vSelRow.Ref);
		EndIf;
	EndDo;
	// Iterate thru selected documents
	vResObj = Undefined;
	i = 0;
	For Each vResListItem In vResList Do
		If ValueIsFilled(vResListItem.Value) Then
			// Get reservation reference
			vResRef = vResListItem.Value;
			If vResRef.ResourceReservationStatus <> vStatusRef Then
				// Check user rights
				If Not cmCheckUserPermissions("HavePermissionToEditClosedForEditDocuments") Then
					If vResRef.IsClosedForEdit Then
						tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to change closed for edit document!';ru='Нет прав на изменение документа с включенным запретом редактирования!';de='Sie haben keine Rechte, das Dokument zu bearbeiten mit eingeschlossenem Bearbeitungsverbot!'"));
						i = i + 1;
						Continue;
					EndIf;
				EndIf;
				If Not cmCheckUserPermissions("HavePermissionToEditResourceReservations") Then
					If (Not ValueIsFilled(vResRef.Author.Department) And vResRef.Author <> SessionParameters.CurrentUser Or 
						ValueIsFilled(vResRef.Author.Department) And vResRef.Author <> SessionParameters.CurrentUser And 
						ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Department) And 
						vResRef.Author.Department <> SessionParameters.CurrentUser.Department) Then
						tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to edit resource reservations!';ru='Нет прав на изменение брони ресурсов!';de='Sie haben keine Rechte, die Ressourcenreservierung zu bearbeiten!'"));
						i = i + 1;
						Continue;
					EndIf;
				EndIf;
				If Not cmCheckUserPermissions("HavePermissionToEditCompletedResourceReservations") Then
					If ValueIsFilled(vResRef.ResourceReservationStatus) And vResRef.ResourceReservationStatus.ServicesAreDelivered Then
						tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to edit completed resource reservations where services are delivered!'; ru='Нет прав на редактирование завершенной брони ресурсов по которой все услуги оказаны!'; de='Es gibt keine Rechte, die geschlossen Ressourcenbuchungen zu editieren!'"));
						i = i + 1;
						Continue;
					EndIf;
				EndIf;
				// Get reservation object
				vResObj = vResRef.GetObject();
				// Update document
				vOldReservationStatus = vResObj.ResourceReservationStatus;
				vResObj.ResourceReservationStatus = vStatusRef;
				vResObj.GuaranteeType = vGuaranteeType;
				vResObj.DoCharging = vResObj.ResourceReservationStatus.DoCharging;
				vResObj.AnnulationReason = vAnnulationReason;
				If Not vResObj.Posted Then
					If vResObj.DeletionMark Then
						vResObj.DeletionMark = False;
					EndIf;
				EndIf;
				vResObj.pmCalculateServices();
				vResObj.Write(DocumentWriteMode.Posting);
				// Save data to the document change history
				vResObj.pmWriteToResourceReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
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
		If Not vStatusArr.IsActive Then
			OpenForm("Catalog.UsualActionReasons.ChoiceForm", New Structure("ChoiceMode", True), ThisObject, , , , New NotifyDescription("UsualActionReasonAfterUserChoice", ThisObject, New Structure("StatusArr", vStatusArr)), FormWindowOpeningMode.LockOwnerWindow);
			Return;
		EndIf;
		// Ask user to choose guarantee type
		vGuaranteeType = Undefined;
		If ValueIsFilled(vStatusArr.GuaranteeType) Then
			vGuaranteeType = vStatusArr.GuaranteeType;
		Else
			If vStatusArr.IsGuaranteed And vStatusArr.GuaranteeTypesCount > 0 Then
				OpenForm("Catalog.GuaranteeTypes.ChoiceForm", New Structure("ChoiceMode", True), ThisObject, , , , New NotifyDescription("GuaranteeTypeAfterUserChoice", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
				Return;
			EndIf;
		EndIf;
		// Do change status
		ChangeStatusAtServer(vAnnulationReason, vGuaranteeType);
	EndIf;
EndProcedure // ChangeStatus

// -----------------------------------------------------------------------------
&AtClient
Procedure UsualActionReasonAfterUserChoice(pAnnulationReason, pExtraParams) Export
	// Ask user to choose guarantee type
	vGuaranteeType = Undefined;
	If pExtraParams <> Undefined And pExtraParams.StatusArr.IsGuaranteed And pExtraParams.StatusArr.GuaranteeTypesCount > 0 Then
		If ValueIsFilled(pExtraParams.StatusArr.GuaranteeType) Then
			vGuaranteeType = pExtraParams.StatusArr.GuaranteeType;
		Else
			OpenForm("Catalog.GuaranteeTypes.ChoiceForm", New Structure("ChoiceMode", True), ThisObject, , , , New NotifyDescription("GuaranteeTypeAfterUserChoice", ThisObject, New Structure("AnnulationReason", pAnnulationReason)), FormWindowOpeningMode.LockOwnerWindow);
			Return;
		EndIf;
	EndIf;
	// Do change status
	ChangeStatusAtServer(pAnnulationReason, vGuaranteeType);
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
	SelResStatus 	= Catalogs.ResourceReservationStatuses.GetRef(vUUID);
	vStatusArr      = tcOnServer.cmGetAtributeAsArray(SelResStatus);
	vStatusArr.Insert("GuaranteeTypesCount", cmGetGuaranteeTypesCount());
	Return vStatusArr;
EndFunction // GetCurrentStatus

// -----------------------------------------------------------------------------
&AtClient
Procedure ReservListSelection(pItem, pSelectedRow, pField, pStandardProcessing)
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
					OpenForm("Document.ResourceReservation.ObjectForm", New Structure("Key", vRowData.Ref));
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
			SelClient = GetClient(vCard);
			If ValueIsFilled(SelClient) Then
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

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeListMode(pCommand)
	vNotifyDescription = New NotifyDescription("ListModesAfterChoice", ThisObject);
	vParams = New Structure("ValueList, MultipleChoice, Title", ListModes, False);
	OpenForm("CommonForm.mcChoiceValueList", vParams, ThisObject, UUID, , , vNotifyDescription);
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
Function GetBalancesByDocuments(pList)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ParentDocs.Ref AS Ref
	|INTO TabDocs
	|FROM
	|	(SELECT
	|		ResourceReservations.Ref AS Ref
	|	FROM
	|		Document.ResourceReservation AS ResourceReservations
	|	WHERE
	|		ResourceReservations.Ref IN(&qList)
	|		AND ResourceReservations.Posted = TRUE) AS ParentDocs
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Folio.Ref AS Ref
	|INTO TabCustomerFolios
	|FROM
	|	Document.Folio AS Folio
	|WHERE
	|	Folio.DeletionMark = FALSE
	|	AND Folio.ParentDoc IN
	|			(SELECT
	|				TabDocs.Ref AS Ref
	|			FROM
	|				TabDocs AS TabDocs)
	|	AND NOT Folio.Customer = VALUE(Catalog.Customers.EmptyRef)
	|	AND NOT ISNULL(Folio.Customer.IsIndividual, FALSE)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Folio.Ref AS Ref
	|INTO TabClientFolios
	|FROM
	|	Document.Folio AS Folio
	|WHERE
	|	Folio.DeletionMark = FALSE
	|	AND Folio.ParentDoc IN
	|			(SELECT
	|				TabDocs.Ref AS Ref
	|			FROM
	|				TabDocs AS TabDocs)
	|	AND (Folio.Customer = VALUE(Catalog.Customers.EmptyRef)
	|			OR ISNULL(Folio.Customer.IsIndividual, FALSE))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccountsBalance.FolioParentDoc AS DocRef,
	|	SUM(AccountsBalance.ClientSumBalance) AS ClientSumBalance,
	|	SUM(AccountsBalance.ClientLimitBalance) AS ClientLimitBalance,
	|	SUM(AccountsBalance.ClientCreditLimit) AS ClientCreditLimit,
	|	SUM(AccountsBalance.CustomerSumBalance) AS CustomerSumBalance
	|FROM
	|	(SELECT
	|		ClientAccountsBalance.Folio.ParentDoc AS FolioParentDoc,
	|		SUM(ClientAccountsBalance.SumBalance) AS ClientSumBalance,
	|		-SUM(ClientAccountsBalance.LimitBalance) AS ClientLimitBalance,
	|		0 AS CustomerSumBalance,
	|		SUM(ClientAccountsBalance.Folio.CreditLimit) AS ClientCreditLimit
	|	FROM
	|		AccumulationRegister.Accounts.Balance(
	|				,
	|				FolioCurrency = Hotel.ReportingCurrency
	|					AND Folio IN
	|						(SELECT
	|							TabClientFolios.Ref AS Ref
	|						FROM
	|							TabClientFolios AS TabClientFolios)) AS ClientAccountsBalance
	|	
	|	GROUP BY
	|		ClientAccountsBalance.Folio.ParentDoc
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CustomerAccountsBalance.Folio.ParentDoc,
	|		0,
	|		0,
	|		SUM(CustomerAccountsBalance.SumBalance),
	|		0
	|	FROM
	|		AccumulationRegister.Accounts.Balance(
	|				,
	|				FolioCurrency = Hotel.ReportingCurrency
	|					AND Folio IN
	|						(SELECT
	|							TabCustomerFolios.Ref AS Ref
	|						FROM
	|							TabCustomerFolios AS TabCustomerFolios)) AS CustomerAccountsBalance
	|	
	|	GROUP BY
	|		CustomerAccountsBalance.Folio.ParentDoc) AS AccountsBalance
	|
	|GROUP BY
	|	AccountsBalance.FolioParentDoc";
	vQry.SetParameter("qList", pList);
	vBalances = vQry.Execute().Select();
	vBalances.Reset();
	Return vBalances;
EndFunction // GetBalancesByDocuments

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure ReservListOnGetDataAtServer(pItemName, pSettings, pRows)
	// Balances
	vBalancesAreVisible = Undefined;
	vList = New ValueList();
	For Each vRow In pRows Do
		vRowValue = vRow.Value;
		If vBalancesAreVisible = Undefined Then
			vBalancesAreVisible = vRowValue.Data.BalancesAreVisible;
			If Not vBalancesAreVisible Then
				Break;
			EndIf;
		EndIf;
		vDocRef = vRowValue.Data.Ref;
		If vList.FindByValue(vDocRef) = Undefined Then
			vList.Add(vDocRef);
		EndIf;
	EndDo;
	If vBalancesAreVisible Then
		vBalances = GetBalancesByDocuments(vList);
	EndIf;
	// Colors and other appearances
	For Each vRow In pRows Do
		vRowValue = vRow.Value;
		// Balances
		If vBalancesAreVisible Then
			vDocRef = vRowValue.Data.Ref;
			vBalances.Reset();
			If vBalances.FindNext(New Structure("DocRef", vDocRef)) Then
				vRowValue.Data["ClientSumBalance"] = vBalances.ClientSumBalance;
				vRowValue.Data["CustomerSumBalance"] = vBalances.CustomerSumBalance;
				vRowValue.Data["ClientLimitBalance"] = vBalances.ClientLimitBalance;
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
		// Add description
		vClientFullNameAppearance = vRowValue.Appearance.Get("ClientFullName");
		If vClientFullNameAppearance <> Undefined Then
			vClientFullNameText = TrimAll(vRowValue.Data["ClientFullName"]);
			vClientDateOfBirth = vRowValue.Data["ClientDateOfBirth"];
			If ValueIsFilled(vClientDateOfBirth) Then
				vClientFullNameText = vClientFullNameText + ?(IsBlankString(vClientFullNameText), "", ", ") + NStr("en='b.d. '; ru='д.р. '; de='g.d. '") + Format(vClientDateOfBirth, "DF=dd.MM.yy");
				vClientFullNameAppearance.SetParameterValue("Text", vClientFullNameText);
			EndIf;
		EndIf;
		// Set row back color for the reservations according to the customer colors
		vCustomer = vRowValue.Data["Customer"];
		If ValueIsFilled(vCustomer) Then
			vCustomerAppearance = vRowValue.Appearance.Get("Customer");
			If vCustomerAppearance <> Undefined Then
				vColor = tcCommonFunctionOnClientServer.cmGetColorFromValueStorage(vCustomer);
				If vColor <> Undefined Then
					vCustomerAppearance.SetParameterValue("BackColor", vColor);
				EndIf;
			EndIf;
		EndIf;
		// Set row back color for the reservations according to the contract colors
		vContract = vRowValue.Data["Contract"];
		If ValueIsFilled(vContract) Then
			vContractAppearance = vRowValue.Appearance.Get("Contract");
			If vContractAppearance <> Undefined Then
				vColor = tcCommonFunctionOnClientServer.cmGetColorFromValueStorage(vContract);
				If vColor <> Undefined Then
					vContractAppearance.SetParameterValue("BackColor", vColor);
				EndIf;
			EndIf;
		EndIf;
		// Set row back color for the reservations according to the guest group colors
		vGuestGroup = vRowValue.Data["GuestGroup"];
		If ValueIsFilled(vGuestGroup) Then
			vGuestGroupAppearance = vRowValue.Appearance.Get("GuestGroup");
			If vGuestGroupAppearance <> Undefined Then
				vColor = tcCommonFunctionOnClientServer.cmGetColorFromValueStorage(vGuestGroup);
				If vColor <> Undefined Then
					vGuestGroupAppearance.SetParameterValue("BackColor", vColor);
				EndIf;
			EndIf;
		EndIf;
		// Set row back color for the reservations according to the guest group colors
		vResourceReservationStatus = vRowValue.Data["ReservationStatus"];
		If ValueIsFilled(vResourceReservationStatus) Then
			vResourceReservationStatusAppearance = vRowValue.Appearance.Get("ReservationStatus");
			vGuaranteeTypeCodeAppearance = vRowValue.Appearance.Get("GuaranteeTypeCode");
			If vGuestGroupAppearance <> Undefined Or vGuaranteeTypeCodeAppearance <> Undefined Then
				vColor = tcCommonFunctionOnClientServer.cmGetColorFromValueStorage(vResourceReservationStatus);
				If vColor <> Undefined Then
					If vGuestGroupAppearance <> Undefined Then
						vGuestGroupAppearance.SetParameterValue("BackColor", vColor);
					EndIf;
					If vGuaranteeTypeCodeAppearance <> Undefined Then
						vGuaranteeTypeCodeAppearance.SetParameterValue("BackColor", vColor);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
EndProcedure // ReservListOnGetDataAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenChangeHistory(pCommand)
	vRowData = Items.ReservList.CurrentData;
	If vRowData <> Undefined Then
		vFrm = OpenForm("InformationRegister.ResourceReservationChangeHistory.ListForm", New Structure("Filter", New Structure("ResourceReservation", vRowData.Ref)), ThisObject, vRowData.Ref);
		vFrm.ReadOnly = ReadOnly;
	EndIf;
EndProcedure // OpenChangeHistory

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenReservedRooms(pCommand)
	vRowData = Items.ReservList.CurrentData;
	If vRowData <> Undefined Then
		#IF NOT MobileClient THEN 
			OpenForm("Document.Reservation.Form.tcReservationListForm", New Structure("SelGuestGroup, SelFilterStatus, SelShowAllGuests", vRowData.GuestGroup, 0, True), ThisObject, vRowData.GuestGroup);
		#ELSE
			OpenForm("Document.Reservation.Form.mcReservationListForm",New Structure("SelGuestGroup, SelFilterStatus, SelShowAllGuests", vRowData.GuestGroup, 0, True), ThisObject, vRowData.GuestGroup);	
		#ENDIF	
	EndIf;
EndProcedure // OpenInHouseGuests

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenInHouseRooms(pCommand)
	vRowData = Items.ReservList.CurrentData;
	If vRowData <> Undefined Then
		OpenForm("Document.Accommodation.Form.tcAccommodationListForm", New Structure("SelGuestGroup, SelFilterStatus, SelShowAllGuests", vRowData.GuestGroup, 0, True), ThisObject, vRowData.GuestGroup);
	EndIf;
EndProcedure // OpenInHouseRooms

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
	vQuery.SetParameter("ObjectType", Documents.ResourceReservation.EmptyRef());	
	vQueryResult = vQuery.Execute();	
	vSelectionRecords = vQueryResult.Select();
	Actions.Clear();
	While vSelectionRecords.Next() Do
		If vSelectionRecords.PredefinedDataName = "" 
			or vSelectionRecords.PredefinedDataName = "ResourceReservationFillSettlement" 
			or vSelectionRecords.PredefinedDataName = "ResourceReservationGuestGroupFillSettlement" 
			or vSelectionRecords.PredefinedDataName = "ResourceReservationFillInvoice" 
			or vSelectionRecords.PredefinedDataName = "ResourceReservationGuestGroupFillInvoice" 
			or vSelectionRecords.PredefinedDataName = "ResourceReservationEventFillInvoice" Then
			vNewRow = Actions.Add();
			vNewRow.Action = vSelectionRecords.Ref;
			vNewRow.IsDefault = vSelectionRecords.IsDefault;
			
			vID = vNewRow.GetID();
			
			vCommand = Commands.Add("Func"+vID);
			vCommand.Action = "FuncButtonClick";
			If vSelectionRecords.IsDefault Then
				vStructure = New Structure("Title, CommandName",
				TrimAll(vSelectionRecords.Code) + " " + cmNStr(vSelectionRecords.ref), "Func" + vID);
			Else
				vStructure = New Structure("Title, CommandName",
				TrimAll(vSelectionRecords.Code) + " " + cmNStr(vSelectionRecords.ref), "Func" + vID);
			EndIf;
			
			tcOnServer.cmCreateItem(ThisObject, ?(vSelectionRecords.IsDefault, Items.FormGroupFunctionsDefault1, Items.FormGroupFunctionsNotDefault1), "Func_1_" + vID, "FormButton", vStructure);
		EndIf;
	EndDo;
	
	vItem = ListFilterStatus.FindByValue(SelFilterStatus);
	If vItem <> Undefined Then
		Items.FormChangeFilterStatus.Title = vItem.Presentation;
		Items.FormChangeFilterStatus.Picture = vItem.Picture;
	EndIf;
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
			If vAction.PredefinedDataName = "ResourceReservationFillSettlement" Then
				vParam = New Structure;
				vParam.Insert("basis", vRowData.Ref);
				OpenForm("Document.Settlement.ObjectForm", vParam, ThisObject, vRowData.Ref);
			ElsIf vAction.PredefinedDataName = "ResourceReservationGuestGroupFillSettlement" Then
				vParam = New Structure;
				vParam.Insert("basis", vRowData.GuestGroup);
				OpenForm("Document.Settlement.ObjectForm", vParam, ThisObject, vRowData.GuestGroup);
			ElsIf vAction.PredefinedDataName = "ResourceReservationFillInvoice" Then
				vParam = New Structure;
				vParam.Insert("basis", vRowData.Ref);
				OpenForm("Document.ProformaInvoice.ObjectForm", vParam, ThisObject, vRowData.Ref);
			ElsIf vAction.PredefinedDataName = "ResourceReservationGuestGroupFillInvoice" Then
				vForm = GetForm("Document.ProformaInvoice.ObjectForm");
				vFormData = vForm.Object;
				NewGroupInvoice(vFormData, vRowData.Ref);
				CopyFormData(vFormData, vForm.Object);
				vForm.Open();
			ElsIf vAction.PredefinedDataName = "ResourceReservationEventFillInvoice" Then
				vEvent = tcOnServer.cmGetAttributeByRef(vRowData.GuestGroup, "Event");
				If ValueIsFilled(vEvent) Then
					vParam = New Structure;
					vParam.Insert("basis", vEvent);
					OpenForm("Document.ProformaInvoice.ObjectForm", vParam, ThisObject, vEvent);
				Else
					ShowMessageBox(, NStr("en='No event for this group!'; ru='Мероприятие у группы не указано!'; de='Die Veranstaltung bei der Gruppe ist nicht angegeben!'"));
				EndIf;
			ElsIf vAction.PredefinedDataName = "ResourceReservationSendMyFolioSMS" Then
				SendWelcomeSMS(Commands.SendWelcomeToMyFolioSystemSMS, vRowData.Ref);
			ElsIf vAction.PredefinedDataName = "ResourceReservationFillOrder" Then
				vParam = New Structure;
				vParam.Insert("basis", vRowData.Ref);
				OpenForm("Document.Order.Form.DocumentForm", vParam, ThisObject, vRowData.Ref);
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

// ------------------------------------------------------------------------------------------------
&AtServer
Function NewGroupInvoice(pFormData, pDocRef)
	vInvObj = FormDataToValue(pFormData, Type("DocumentObject.ProformaInvoice"));
	vInvObj.Fill(pDocRef);
	vInvObj.ParentDoc = Documents.ResourceReservation.EmptyRef();
	vInvObj.Fill(pDocRef.GuestGroup);
	ValueToFormData(vInvObj, pFormData);
EndFunction // NewGroupInvoice

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
	vQuery.SetParameter("ObjectType", Documents.ResourceReservation.EmptyRef());	
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
			vParentLang1 = tcOnServer.cmCreateItem(ThisObject, Items.FormGroupPrintingNotDefaultExtra1, "Print"+vSelectionRecords.Language+"1", "FormGroup", New Structure("Type,Title",	FormGroupType.Popup, vSelectionRecords.Language));
		EndIf;
		
		While vSelectionDetailRecords.Next() Do
			If vSelectionDetailRecords.PredefinedDataName = "" 
				or vSelectionDetailRecords.PredefinedDataName = "ResourceReservationPrintConfirmationRu"  
				or vSelectionDetailRecords.PredefinedDataName = "ResourceReservationPrintConfirmationEn"  
				or vSelectionDetailRecords.PredefinedDataName = "ResourceReservationPrintConfirmationDe"  
				or vSelectionDetailRecords.PredefinedDataName = "ResourceReservationPrintConfirmationByDaysRu"  
				or vSelectionDetailRecords.PredefinedDataName = "ResourceReservationPrintConfirmationByDaysEn"  		
				or vSelectionDetailRecords.PredefinedDataName = "ResourceReservationPrintConfirmationByDaysDe" Then 
				vNewRow = PrintForms.Add();
				vNewRow.PrintForm = vSelectionDetailRecords.Ref;
				vNewRow.IsDefault = vSelectionDetailRecords.IsDefault;
				
				vID = vNewRow.GetID();
				
				vCommand = Commands.Add("Print" + vID);
				vCommand.Action = "PrintButtonClick";
				If vSelectionDetailRecords.IsDefault Then
					vParent1 = Items.FormGroupPrintingDefault1;
				Else
					vParent1 = vParentLang1;
				EndIf;
				vStructure = New Structure("Title,CommandName", TrimAll(vSelectionDetailRecords.Code) + " " + cmNStr(vSelectionDetailRecords.ref), "Print" + vID);
				
				tcOnServer.cmCreateItem(ThisObject, vParent1, "Print_1_" + vID, "FormButton", vStructure);
			EndIf;
		EndDo;
	EndDo;
EndProcedure // FillPrintingButton

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintButtonClick(Command)
	vRowDataArray = Items.ReservList.SelectedRows;
	If vRowDataArray.Count() > 0 Then
		vPrintNumber = StrReplace(Command.Name, "Print", "");
		vPrintForm = GetPrintFormForNumber(vPrintNumber);
		vGroupsList = New ValueList();
		vListData = New ValueList();
		For Each vRowId In vRowDataArray Do
			vRowData = Items.ReservList.RowData(vRowId);
			If vRowData <> Undefined And vGroupsList.FindByValue(vRowData.GuestGroup) = Undefined Then
				vGroupsList.Add(vRowData.GuestGroup);
				vListData.Add(vRowData.Ref);
			EndIf;
		EndDo;
		// Load external print form
		If ValueIsFilled(vPrintForm.ExternalProcessing) Then 
			Try
				OpenExternalProcedureForm(vPrintForm.ExternalProcessing, vPrintForm.Ref, vRowDataArray[0]);
			Except
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'"), MessageStatus.Attention);
				vExternalProcessing = Undefined;
			EndTry;
		ElsIf ValueIsFilled(vPrintForm.Report) Then
			Try
				OpenExternalReportForm(vPrintForm.Report, vPrintForm.Ref, vRowDataArray[0]);
			Except
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'"), MessageStatus.Attention);
			EndTry;
		ElsIf vPrintForm.PredefinedDataName = "ResourceReservationPrintConfirmationRu" Or
		      vPrintForm.PredefinedDataName = "ResourceReservationPrintConfirmationEn" Or
			  vPrintForm.PredefinedDataName = "ResourceReservationPrintConfirmationDe" Then
			If vListData.Count() > 1 Then
				OpenForm("Document.ResourceReservation.Form.tcReservationConfirmationForm", New Structure("SelListReservation, SelLanguage, SelObjectPrintForm, SelByDays, CloseOnOwnerClose", vListData, tcOnServer.cmGetAttributeByRef(vPrintForm.Ref, "Language"), vPrintForm.Ref, False, False), ThisObject, UUID);
			ElsIf vListData.Count() = 1 Then
				OpenForm("Document.ResourceReservation.Form.tcReservationConfirmationForm", New Structure("SelReservation, SelLanguage, SelObjectPrintForm, SelByDays, CloseOnOwnerClose", vListData.Get(0).Value, tcOnServer.cmGetAttributeByRef(vPrintForm.Ref, "Language"), vPrintForm.Ref, False, False), ThisObject, UUID);	
			EndIf;
		ElsIf vPrintForm.PredefinedDataName = "ResourceReservationPrintConfirmationByDaysRu" Or
		      vPrintForm.PredefinedDataName = "ResourceReservationPrintConfirmationByDaysEn" Or
			  vPrintForm.PredefinedDataName = "ResourceReservationPrintConfirmationByDaysDe" Then
			If vListData.Count() > 1 Then  
				OpenForm("Document.ResourceReservation.Form.tcReservationConfirmationForm", New Structure("SelListReservation, SelLanguage, SelObjectPrintForm, SelByDays, CloseOnOwnerClose", vListData, tcOnServer.cmGetAttributeByRef(vPrintForm.Ref, "Language"), vPrintForm.Ref, True, False), ThisObject, UUID);
			ElsIf vListData.Count() = 1 Then
				OpenForm("Document.ResourceReservation.Form.tcReservationConfirmationForm", New Structure("SelReservation, SelLanguage, SelObjectPrintForm, SelByDays, CloseOnOwnerClose", vListData.Get(0).Value, tcOnServer.cmGetAttributeByRef(vPrintForm.Ref, "Language"), vPrintForm.Ref, True, False), ThisObject, UUID);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // PrintButtonClick

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
	vName = ConnectExternalDataProcessor(vURL, "ExternalProcessingForm");
	vParams = New Structure("InputParameter, ObjectPrintingForm", pDocRef, pPrintFormTypeRef);
	OpenForm("ExternalDataProcessor." + vName + ".Form", vParams);
EndProcedure // OpenExternalProcedureForm

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenExternalReportForm(pExtRepRef, pPrintFormTypeRef, pDocRef)
	vURL = GetURL(tcOnServer.cmGetAttributeByRef(pExtRepRef,"Report"), "ExternalProcessingStorage"); 
	vName = ConnectExternalReport(vURL, "ExternalReportForm");
	vParams = New Structure("Document, ObjectPrintingForm", pDocRef, pPrintFormTypeRef);
	OpenForm("ExternalReport." + vName + ".Form", vParams);
EndProcedure // OpenExternalReportForm

// -----------------------------------------------------------------------------
&AtServer
Function SendWelcomeSMSAtServer(pDocRef)
	vMessage = "";
	If ValueIsFilled(pDocRef.ResourceReservationStatus) And pDocRef.ResourceReservationStatus.IsActive Then
		
		vExtSys = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsHotel365(pDocRef.Hotel);
		If NOT ValueIsFilled(vExtSys) Then
			// The integration with hotel365 is not set
			Return NStr("en = 'Integration with the hotel365 service is not configured'; de = 'Die Integration mit hotel365 ist nicht konfiguriert'; ru = 'Не настроена интеграция с сервисом hotel365'");
		EndIf;
		If NOT vExtSys.IsActive Then
			// The integration with hotel365 is switched off
			Return NStr("en = 'The Integration with hotel365 is switched off'; de = 'Die Integration mit hotel365 ist ausgeschaltet'; ru = 'Интеграция с hotel365 отключена'");
		EndIf;
		
		// Get list of reservations to send message to
		vDocsList = New ValueList();
		vDocsList.Add(pDocRef.Ref);
		// Send SMS to every client in the list
		For Each vDocItem In vDocsList Do
			vDoc = vDocItem.Value;
			vHotel = vDoc.Hotel;
			vGuest = vDoc.Client;
			vPhone = ?(Not IsBlankString(vDoc.Phone), TrimAll(vDoc.Phone), TrimAll(vGuest.Phone));
			If Not IsBlankString(vPhone) Then
				vResult = SMS.Hotel365_SendSMS(vHotel, vDoc, vPhone, vGuest);
				If Not vResult.Success Then
					For Each vErrorText In vResult.Errors Do
						vMessage = vMessage + ?(IsBlankString(vMessage), "", Chars.LF) + vErrorText;
					EndDo;
				EndIf;
			Else
				vMessage = vMessage + ?(IsBlankString(vMessage), "", Chars.LF) + NStr("en='Client phone is not filled!'; ru='В брони не указан телефон клиента!'; de='Kunde-Telefon ist nicht gefüllt!'");
			EndIf;
		EndDo;
	EndIf;
	Return vMessage;
EndFunction // SendWelcomeSMSAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SendWelcomeSMS(pCommand, pDocRef = Undefined)
	vDocRef = pDocRef;
	If pDocRef = Undefined Then
		vDocRef = Items.ReservList.CurrentRow;
	EndIf;
	If ValueIsFilled(vDocRef) Then
		vMessage = SendWelcomeSMSAtServer(vDocRef);
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
Procedure ShowDetails(pCommand)
	Items.Pages.Visible = False;
	Items.FormChangeFilterStatus.Visible = False;
	Items.BackFromDetails.DefaultButton = True;
	Items.PagesDetails.Visible = True;
	Items.BackFromDetails.Visible = True;
	Items.PagesDetails.CurrentPage = Items.PagesDetailsMain;
EndProcedure // ShowDetails

// -----------------------------------------------------------------------------
&AtClient
Procedure BackFromDetails(Command)
	Items.Pages.Visible = True;
	Items.FormChangeFilterStatus.Visible = True;
	Items.FormChangeFilterStatus.DefaultButton = True;
	Items.PagesDetails.Visible = False;
	Items.BackFromDetails.Visible = False;
	Items.Pages.CurrentPage = Items.PageMain;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeFilterStatus(pCommand)
	vNotifyDescription = New NotifyDescription("AfterChoiceFilterStatus", ThisObject);
	vParams = New Structure("ValueList, MultipleChoice, Title", ListFilterStatus, False, NStr("en = 'Statuses'; de = 'Status'; ru = 'Статусы'"));
	OpenForm("CommonForm.mcChoiceValueList", vParams, ThisObject, UUID, , , vNotifyDescription);
EndProcedure // ChangeFilterStatus

// -------------------------------------------------------------------------------------
&AtClient
Procedure AfterChoiceFilterStatus(pItem, pExtraParams) Export 
	If pItem <> Undefined Then
		Items.FormChangeFilterStatus.Title = pItem.Presentation;
		Items.FormChangeFilterStatus.Picture = pItem.Picture;
		SelFilterStatus = pItem.Value; 
		FilterStatusOnChangeAtServer();	
	EndIf;
EndProcedure // AfterChoiceFilterStatus

