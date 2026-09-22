
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	FunctionsAndPrintFormsWereLoaded = False;
	
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);

	// User rights to open item
	If Not IsInRole("RightsToChooseHotel") Then
		If ValueIsFilled(Object.Owner) And SessionParameters.CurrentHotel <> Object.Owner Then
			pCancel = True;
		EndIf;
	EndIf;
	
	// Fill defaut hotel
	If Not ValueIsFilled(Object.Owner) Then
		Object.Owner = SessionParameters.CurrentHotel;
		pCancel = Not Write();
	EndIf;
	If Not ValueIsFilled(Object.Ref) Then
		If ValueIsFilled(Object.Owner) Then
			Object.Parent = Object.Owner.GetObject().pmGetGuestGroupFolder();
		EndIf;
	EndIf;
	
	// Check if this is new block mode
	If Not ValueIsFilled(Object.Ref) Or ValueIsFilled(Object.GroupType) And Object.InitialBlock.Count() = 0 Then
		Object.IsNewBlock = True;
	EndIf;
	
	// Fill default status
	If ValueIsFilled(Object.Owner) Then
		If Not ValueIsFilled(Object.GroupType) And Not ValueIsFilled(Object.Ref) Then
			Object.GroupType = Catalogs.GroupTypes.RoomsAndResources;
		EndIf;
		If Not ValueIsFilled(Object.ClientDoc) Then
			If Not ValueIsFilled(Object.Status) Then
				If ValueIsFilled(Object.Owner.NewRoomsGroupStatus) And Object.GroupType <> Catalogs.GroupTypes.Resources Then
					Object.Status = Object.Owner.NewRoomsGroupStatus;
				ElsIf ValueIsFilled(Object.Owner.NewResourcesGroupStatus) And Object.GroupType = Catalogs.GroupTypes.Resources Then
					Object.Status = Object.Owner.NewResourcesGroupStatus;
				Else
					Object.Status = Object.Owner.NewReservationStatus;
				EndIf;
			EndIf;
			Items.Status.ReadOnly = False;
			Items.Status.ChoiceButton = True;
			Items.Status.ChooseType = False;
		Else
			Items.Status.ReadOnly = True;
			Items.Status.ChoiceButton = False;
		EndIf;
		If Not ValueIsFilled(Object.Ref) Then
			Object.OneCustomerPerGuestGroup = Object.Owner.OneCustomerPerGuestGroup;
		EndIf;
	Else
		pCancel = True;
	EndIf;
	SetGuaranteeTypeAppearance();
	
	// Change form appearance in the new block mode
	SetNewBlockModeAppearance();
	If ValueIsFilled(Object.Ref) And Not Object.IsNewBlock Then
		Items.IsNewBlock.Enabled = False;
	EndIf;
	
	// Default attributes
	If Parameters.Property("CheckInDate") And ValueIsFilled(Parameters.CheckInDate) Then
		Object.CheckInDate = Parameters.CheckInDate;
	EndIf;
	If Parameters.Property("CheckOutDate") And ValueIsFilled(Parameters.CheckOutDate) Then
		Object.CheckOutDate = Parameters.CheckOutDate;
	EndIf;
	If Parameters.Property("Duration") And Parameters.Duration <> 0 Then
		Object.Duration = Parameters.Duration;
	EndIf;
	If Not ValueIsFilled(Object.Ref) Then
		If Parameters.Property("Hotel") And ValueIsFilled(Parameters.Hotel) Then
			Object.Owner = Parameters.Hotel;
		EndIf;
		If Parameters.Property("Customer") And ValueIsFilled(Parameters.Customer) Then
			Object.Customer = Parameters.Customer;
			If ValueIsFilled(Object.Customer.ClientType) Then
				Object.ClientType = Object.Customer.ClientType;
			EndIf;
			If ValueIsFilled(Object.Customer.SourceOfBusiness) Then
				Object.SourceOfBusiness = Object.Customer.SourceOfBusiness;
			EndIf;
			If ValueIsFilled(Object.Customer.MarketingCode) Then
				Object.MarketingCode = Object.Customer.MarketingCode;
			EndIf;
			If ValueIsFilled(Object.Customer.RoomRate) Then
				Object.RoomRate = Object.Customer.RoomRate;
			EndIf;
		EndIf;
		If Parameters.Property("Contract") And ValueIsFilled(Parameters.Contract) Then
			Object.Contract = Parameters.Contract;
			If ValueIsFilled(Object.Contract.ClientType) Then
				Object.ClientType = Object.Contract.ClientType;
			EndIf;
			If ValueIsFilled(Object.Contract.SourceOfBusiness) Then
				Object.SourceOfBusiness = Object.Contract.SourceOfBusiness;
			EndIf;
			If ValueIsFilled(Object.Contract.MarketingCode) Then
				Object.MarketingCode = Object.Contract.MarketingCode;
			EndIf;
			If ValueIsFilled(Object.Contract.RoomRate) Then
				Object.RoomRate = Object.Contract.RoomRate;
			EndIf;
		EndIf;
		If Parameters.Property("Agent") And ValueIsFilled(Parameters.Agent) Then
			Object.Agent = Parameters.Agent;
		EndIf;
		If Parameters.Property("Allotment") And ValueIsFilled(Parameters.Allotment) Then
			Object.Allotment = Parameters.Allotment;
			If ValueIsFilled(Object.Allotment.ReservationManager) Then
				Object.ReservationManager = Object.Allotment.ReservationManager;
			EndIf;
			If ValueIsFilled(Object.Allotment.MICEManager) Then
				Object.MICEManager = Object.Allotment.MICEManager;
			EndIf;
			If ValueIsFilled(Object.Allotment.RevenueManager) Then
				Object.RevenueManager = Object.Allotment.RevenueManager;
			EndIf;
			If ValueIsFilled(Object.Allotment.ClientType) Then
				Object.ClientType = Object.Allotment.ClientType;
			EndIf;
			If ValueIsFilled(Object.Allotment.SourceOfBusiness) Then
				Object.SourceOfBusiness = Object.Allotment.SourceOfBusiness;
			EndIf;
			If ValueIsFilled(Object.Allotment.MarketingCode) Then
				Object.MarketingCode = Object.Allotment.MarketingCode;
			EndIf;
			If ValueIsFilled(Object.Allotment.TripPurpose) Then
				Object.TripPurpose = Object.Allotment.TripPurpose;
			EndIf;
			If ValueIsFilled(Object.Allotment.RoomRate) Then
				Object.RoomRate = Object.Allotment.RoomRate;
			EndIf;
		EndIf;
		If Parameters.Property("SourceOfBusiness") And ValueIsFilled(Parameters.SourceOfBusiness) Then
			Object.SourceOfBusiness = Parameters.SourceOfBusiness;
		EndIf;
		If Parameters.Property("MarketingCode") And ValueIsFilled(Parameters.MarketingCode) Then
			Object.MarketingCode = Parameters.MarketingCode;
		EndIf;
		If Parameters.Property("ClientType") And ValueIsFilled(Parameters.ClientType) Then
			Object.ClientType = Parameters.ClientType;
		EndIf;
		If Parameters.Property("TripPurpose") And ValueIsFilled(Parameters.TripPurpose) Then
			Object.TripPurpose = Parameters.TripPurpose;
		EndIf;
		If Parameters.Property("RoomRate") And ValueIsFilled(Parameters.RoomRate) Then
			Object.RoomRate = Parameters.RoomRate;
		EndIf;
		If ValueIsFilled(Object.CheckInDate) And ValueIsFilled(Object.CheckOutDate) And 
		   Object.CheckInDate < Object.CheckOutDate And Not Parameters.Property("Duration") Then
			vRoomRate = Object.RoomRate;
			If Not ValueIsFilled(vRoomRate) And ValueIsFilled(Object.Owner) And ValueIsFilled(Object.Owner.RoomRate) Then
				vRoomRate = Object.Owner.RoomRate;
			EndIf;
			If (Object.CheckInDate - BegOfDay(Object.CheckInDate)) = 0 Then
				If ValueIsFilled(vRoomRate) Then
					If ValueIsFilled(vRoomRate.DefaultCheckInTime) Then
						Object.CheckInDate = Object.CheckInDate + (vRoomRate.DefaultCheckInTime - BegOfDay(vRoomRate.DefaultCheckInTime));
					ElsIf ValueIsFilled(vRoomRate.ReferenceHour) Then
						Object.CheckInDate = Object.CheckInDate + (vRoomRate.ReferenceHour - BegOfDay(vRoomRate.ReferenceHour));
					EndIf;
				EndIf;
			EndIf;
			Object.CheckInDate = cm1SecondShift(Object.CheckInDate);
			If (Object.CheckOutDate - BegOfDay(Object.CheckOutDate)) = 0 Then
				If ValueIsFilled(vRoomRate) Then
					If ValueIsFilled(vRoomRate.DefaultCheckOutTime) Then
						Object.CheckOutDate = Object.CheckOutDate + (vRoomRate.DefaultCheckOutTime - BegOfDay(vRoomRate.DefaultCheckOutTime));
					ElsIf ValueIsFilled(vRoomRate.ReferenceHour) Then
						Object.CheckOutDate = Object.CheckOutDate + (vRoomRate.ReferenceHour - BegOfDay(vRoomRate.ReferenceHour));
					EndIf;
				EndIf;
			EndIf;
			If ValueIsFilled(vRoomRate) Then
				Object.Duration = cmCalculateDuration(vRoomRate, Object.CheckInDate, Object.CheckOutDate);
			EndIf;
		EndIf;
	EndIf;
	
	// Fill list of possible statuses
	If Not Items.Status.ReadOnly Then
		FillReservationStatusListChoice();
	Else
		Items.Status.ListChoiceMode = False;
	EndIf;
	
	// Save current group period
	SaveCurrentGroupPeriod();
	
	// Agent conditions
	Items.Agent.ToolTip = GetAgentConditionsAtServer(Object.Agent, Object.Contract);
	If ValueIsFilled(Object.Ref) Then
		FillPrintingButton();
		FillFunctionsButton();
		FunctionsAndPrintFormsWereLoaded = True;
	EndIf;
	
	// Fill item tasks presentation
	FillTasksPresentation();
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	OnOpenForm();
	FillGroupFolioAttribute();
	If Not ValueIsFilled(Object.Ref) Then
		Modified = True;
	Else
		RepresentDataChange(Object.Customer, DataChangeType.Update);
	EndIf;
	Deleted = False;
	vExistingBackgroundJobs = CheckForExistingBackgroundJobs();
	If vExistingBackgroundJobs.Count() > 0 Then
		CurrentBackgroundJobUUID = vExistingBackgroundJobs[0];
		BlockForm_ShowProgressBar();
		AttachIdleHandler("Attachable_CheckBackgroundJobs",1,False);
	EndIf;
	
	// Show pop-up tasks
	vTasksStructure = GetTasksStructure();
	For Each vTasks In vTasksStructure Do
		If vTasks.Value.PopUp Then
			ShowMessageBox(, vTasks.Value.Remarks, , NStr("en = 'Task'; de = 'Aufgabe'; ru = 'Задача'"));
		EndIf;
	EndDo;
EndProcedure // OnOpen

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeClose(pCancel, pExit, pMessageText, pStandardProcessing)
	If pExit Then
	   Return;
	EndIf;
	If Object.IsNewBlock And HasErrors Then
		pCancel = True;
		HasErrors = False;
	EndIf;
	BeforeCloseAtServer();
EndProcedure // BeforeClose

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If (pEventName = "Document.Reservation.Write" Or pEventName = "Document.Reservation.WriteNew" Or 
		pEventName = "Document.Accommodation.Write" Or pEventName = "Document.Accommodation.WriteNew" Or 
		pEventName = "Document.ResourceReservation.Write" Or pEventName = "Document.ResourceReservation.WriteNew" Or 
		pEventName = "Catalog.GuestGroups.Changed") And 
		ValueIsFilled(pParameter) And 
	   (TypeOf(pParameter) = Type("CatalogRef.GuestGroups") And pParameter = Object.Ref Or
		TypeOf(pParameter) <> Type("CatalogRef.GuestGroups") And tcOnServer.cmGetAttributeByRef(pParameter, "GuestGroup") = Object.Ref) Then
		// Reread form data
		Read();
		// Fill group document list
		FillGroupList();
		// Fill payer data
		FillPayerAtServer();
		// Fill guest group totals
		FillTotals();
		FillTotalColumn();
		// Protect status from changes
		If ValueIsFilled(Object.ClientDoc) And Not Items.Status.ReadOnly Then
			Items.Status.ReadOnly = True;
			Items.Status.ChoiceButton = False;
		EndIf;
		// Change form appearance
		SetNewBlockModeAppearance();
		// Fill block totals
		FillAvailableRoomsAtServer();
		// Save current group period
		SaveCurrentGroupPeriod();
	ElsIf pEventName = "Client.Change" Then
		If TypeOf(pSource) = Type("FormField") And tcOnClient.GetParentForm(pSource) = ThisObject Then
			vFieldName = pSource.Name;
			If vFieldName = "GuestGroupTableBoxGuestFullName" Then
				vCurData = Items.GuestGroupTableBox.CurrentData;
				If vCurData = Undefined Then
					Return;
				EndIf;
				vCurData.Guest = pParameter;
				vCurData.GuestFullName = tcOnServer.cmGetAttributeByRef(pParameter, "FullName");
				GuestsWereChanged = True;
				Modified = True;
			EndIf;
		EndIf;
	ElsIf pEventName = "Allotment.Write" Then
		If ValueIsFilled(pParameter) And TypeOf(pParameter) = Type("CatalogRef.RoomQuotas") Then
			If pSource = Items.Allotment Then
				Object.Allotment = pParameter;
			EndIf;
		EndIf;
	ElsIf pEventName = "MessageWrite" Then
		FillTasksPresentation();
	EndIf;
EndProcedure // NotificationProcessing

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure AfterWriteAtServer(pCurrentObject, pWriteParameters)
	If Not FunctionsAndPrintFormsWereLoaded Then
		FillPrintingButton();
		FillFunctionsButton();
		FunctionsAndPrintFormsWereLoaded = True;
	EndIf;

	// Recalculate all group documents
	vError = RecalculateGroupDocumentsAtServer(ChargingRulesWereChanged, CustomerWasChanged, GuestsWereChanged, RemarksWereChanged);
	If Not IsBlankString(vError) Then
		tcCommonFunctionOnClientServer.TextMessage(vError);
	EndIf;
EndProcedure // AfterWriteAtServer


// ------------------------------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	If Object.IsNewBlock Then
		CreateInitialBlockReservations(Commands.CreateInitialBlockReservations, True);
	Else
		Notify("Catalog.GuestGroups.Changed", Object.Ref);
	EndIf;
EndProcedure // AfterWrite

#EndRegion

// -----------------------------------------------------------------------------
&AtServer
Procedure BeforeCloseAtServer()
	cmUpdateChargingRulesFoliosLineNumbers(Object.ChargingRules);
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveCurrentGroupPeriod()
	OldCheckInDate = Object.CheckInDate;
	OldCheckOutDate = Object.CheckOutDate;
	OldDuration = Object.Duration;
EndProcedure // SaveCurrentGroupPeriod

// -----------------------------------------------------------------------------
&AtServer
Procedure UpdateInitialBlockPeriod()
	If ValueIsFilled(Object.CheckInDate) And ValueIsFilled(Object.CheckOutDate) Then
		For Each vBlockRow In Object.InitialBlock Do
			If ValueIsFilled(OldCheckInDate) And ValueIsFilled(OldCheckOutDate) And 
			   cm1SecondShift(vBlockRow.CheckInDate) = cm1SecondShift(OldCheckInDate) And 
			   cm0SecondShift(vBlockRow.CheckOutDate) = cm0SecondShift(OldCheckOutDate) Then
				vBlockRow.CheckInDate = cm1SecondShift(Object.CheckInDate);
				vBlockRow.CheckOutDate = cm0SecondShift(Object.CheckOutDate);
			EndIf;
		EndDo;
	EndIf;
EndProcedure // UpdateInitialBlockPeriod

// -----------------------------------------------------------------------------
&AtServer
Procedure SetGuaranteeTypeAppearance()
	Items.GuaranteeType.Visible = Not Items.Status.ReadOnly;
	If Items.GuaranteeType.Visible Then
		If TypeOf(Object.Status) = Type("CatalogRef.AccommodationStatuses") Then
			Items.GuaranteeType.Visible = False;
		Else
			If Not ValueIsFilled(Object.Status) Then
				Items.GuaranteeType.Visible = False;
			Else
				Items.GuaranteeType.Visible = Object.Status.IsGuaranteed;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // SetGuaranteeTypeAppearance

// -----------------------------------------------------------------------------
&AtServer
Procedure SetNewBlockModeAppearance()
	Items.BlockPage.Visible = ValueIsFilled(Object.GroupType);
	Items.BlockPage1.Visible = ValueIsFilled(Object.GroupType);
	If Object.IsNewBlock Then
		If TypeOf(Object.Status) = Type("CatalogRef.ResourceReservationStatuses") And Object.GroupType = Catalogs.GroupTypes.Resources Then
			Items.GroupGuests.Visible = False;
		Else
			Items.GroupGuests.Visible = True;
		EndIf;
	Else
		If Object.GroupType = Catalogs.GroupTypes.Resources Then
			Items.GroupGuests.Visible = False;
		Else
			Items.GroupGuests.Visible = True;
		EndIf;
	EndIf;
	If Object.GroupType = Catalogs.GroupTypes.Rooms Then
		Items.GroupResources.Visible = Not Object.IsNewBlock;
	Else
		Items.GroupResources.Visible = True;
	EndIf;
	Items.RightColumn.Visible = Not Object.IsNewBlock;
	Items.CreateInitialBlockReservations.Visible = Items.IsNewBlock.Visible;
	Items.CreateInitialBlockReservations.Enabled = Object.IsNewBlock;
	Items.InitialBlockRoomType.ReadOnly = Not Object.IsNewBlock;
	Items.InitialBlockCheckInDate.ReadOnly = Not Object.IsNewBlock;
	Items.InitialBlockCheckOutDate.ReadOnly = Not Object.IsNewBlock;
	Items.InitialBlockIsForFolioSplit.ReadOnly = Not Object.IsNewBlock;
	Items.InitialBlockNumberOfRooms.ReadOnly = Not Object.IsNewBlock;
	Items.InitialBlockRoomsAvailable.Visible = Object.IsNewBlock;
	Items.InitialBlockActualRooms.Visible = Not Object.IsNewBlock;
	Items.InitialBlockPickedUpRooms.Visible = Not Object.IsNewBlock;
	Items.InitialBlockNotPickedUpRooms.Visible = Not Object.IsNewBlock;
	Items.ReleaseTime.ReadOnly = Not Object.IsNewBlock;
	Items.ReleaseDate.ReadOnly = Not Object.IsNewBlock;
EndProcedure // SetNewBlockModeAppearance

// -----------------------------------------------------------------------------
&AtServer
Function GetTasksStructure()
	vTasksStructure = New Structure();
	If ValueIsFilled(Object.Ref) Then
		vTasks = cmGetMessagesForObject(Object.Ref);
		vNumber = 0;
		For Each vTasksRow In vTasks Do
			vTasksStructure.Insert(TrimAll("Tasks" + vNumber), New Structure("PopUp, Remarks", vTasksRow.PopUp, vTasksRow.Remarks));
			vNumber = vNumber + 1;
		EndDo;
	EndIf;
	Return vTasksStructure;
EndFunction // GetTasksStructure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillPayerAtServer(pObj = Undefined)
	vObj = pObj;
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	If Not ValueIsFilled(vObj.Payer) Or 
	   Not ValueIsFilled(vObj.PlannedPaymentMethod) Or 
	   GuestGroupTableBox.GetItems().Count() <> 0 Or 
	   GuestGroupResources.Count() <> 0 Then
		// Fill payer data
		vPayer = Enums.WhoPays.Guest;
		vPlannedPaymentMethod = vObj.Owner.PlannedPaymentMethod;
		// Update planned payment method if necessary
		vPayer = vObj.pmSetPlannedPaymentMethod(vPlannedPaymentMethod);
		// Fill object values
		If vPayer <> vObj.Payer Then
			vObj.Payer = vPayer;
		EndIf;
		If vPlannedPaymentMethod <> vObj.PlannedPaymentMethod Then
			vObj.PlannedPaymentMethod = vPlannedPaymentMethod;
		EndIf;
		If pObj = Undefined Then
			ValueToFormAttribute(vObj, "Object");
		EndIf;
	EndIf;
EndProcedure // FillPayerAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure OnOpenForm(pObj = Undefined)
	CustomerWasChanged = False;
	ChargingRulesWereChanged = False;
	// Check background jobs for this group
	AsyncCalls.CleanCompletedBackgroundOperationsInProgress();
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		Items.Code.ReadOnly = True;
		Items.Code.TextEdit = False;
		Items.Parent.ReadOnly = True;
		Items.Parent.TextEdit = False;
	EndIf;
	// Check parameters
	vUseParameterObject = True;
	vObj = pObj;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParameterObject = False;
	EndIf;
	// Save current date of definite
	OldDateOfDef = vObj.DateOfDef;
	// Fill payer data
	FillPayerAtServer(vObj);
	// Fill occupation column
	vNewStr = TableBoxTotal.Add();
	vNewStr.Occupation = NStr("en='Guests:'; de='Gäste:'; ru='Гостей:'");
	vNewStr = TableBoxTotal.Add();
	vNewStr.Occupation = NStr("en='Rooms:'; de='Zimmern:'; ru='Номеров:'");
	If Not vObj.IsNew() Then
		FillGroupList(vObj);
		// Fill guest group totals
		FillTotals(vObj);
		FillTotalColumn();
	EndIf;
	DisableFieldsByCustomer();
	vColor = GetGroupColor();
	If TypeOf(vColor) = Type("Color") Then
		Items.SetColor.BackColor = vColor;
	EndIf;
	If vUseParameterObject = False Then
		// Set object value
		ValueToFormAttribute(vObj, "Object");
		// Fill group block usage statistics
		FillAvailableRoomsAtServer();
	EndIf;
EndProcedure // OnOpenForm

#Region Main

// -----------------------------------------------------------------------------
&AtServer
Procedure DisableFieldsByCustomer()
	// Disabled fields if customer is filled
	If ValueIsFilled(SessionParameters.CurrentUser.Customer) Then
		Items.PeriodGroup.Enabled = False;
		Items.Parent.Enabled = False;
		Items.Parent.OpenButton = False;
		Items.Parent.ClearButton = False;
		Items.Parent.ChoiceButton = False;
		Items.Author.Enabled = False;
		Items.Author.OpenButton = False;
		Items.Author.ClearButton = False;
		Items.Author.ChoiceButton = False;
		Items.Client.Enabled = False;
		Items.Client.OpenButton = False;
		Items.Client.ClearButton = False;
		Items.Client.ChoiceButton = False;
		Items.FixedClient.Enabled = False;
		Items.Customer.Enabled = False;
		Items.Customer.OpenButton = False;
		Items.Customer.ClearButton = False;
		Items.Customer.ChoiceButton = False;
		Items.OneCustomerPerGuestGroup.Enabled = False;
		Items.HeaderRow.Enabled = False;
		Items.ExternalCode.Enabled = False;
		Items.GroupManagers.Enabled = False;
	EndIf;
EndProcedure // DisableFieldsByCustomer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillTotals(pObj = Undefined)
	// Check parameters
	vUseParameterObject = True;
	vObj = pObj;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParameterObject = False;
	EndIf;
	// Check if this is preliminary guest group
	vIsPreliminary = vObj.pmIsPreliminary();
	// Fill guest group room inventory totals
	vRITotals = vObj.pmGetRoomInventoryTotals();
	If vRITotals.Count() > 0 Then
		vRITotalsRow = vRITotals.Get(0);
		If Not vIsPreliminary Then
			TableBoxTotal.Get(0).Total = vRITotalsRow.GuestsReserved;
			TableBoxTotal.Get(0).Waiting = vRITotalsRow.GuestsExpected;
			TableBoxTotal.Get(1).Total = vRITotalsRow.RoomsReserved;
			TableBoxTotal.Get(1).Waiting = vRITotalsRow.RoomsExpected;
		Else
			TableBoxTotal.Get(0).Total = 0;
			TableBoxTotal.Get(0).Waiting = vRITotalsRow.GuestsExpected;
			TableBoxTotal.Get(1).Total = 0;
			TableBoxTotal.Get(1).Waiting = vRITotalsRow.RoomsExpected;
		EndIf;
		TableBoxTotal.Get(0).InHouse = vRITotalsRow.GuestsCheckedIn;
		TableBoxTotal.Get(1).InHouse = vRITotalsRow.RoomsCheckedIn;
	Else
		TableBoxTotal.Get(0).Total = 0;
		TableBoxTotal.Get(0).Waiting = 0;
		TableBoxTotal.Get(0).InHouse = 0;
		TableBoxTotal.Get(1).Total = 0;
		TableBoxTotal.Get(1).Waiting = 0;
		TableBoxTotal.Get(1).InHouse = 0;
	EndIf;
	// Fill guest group resource reservations list
	TResources = " " + vObj.pmGetResourceDescriptions();
	// Fill guest group sales
	TableBoxSales.Clear();
	vSalesTotals = vObj.pmGetSalesTotals();
	For Each vTotalsRow In vSalesTotals Do
		vSalesRow = TableBoxSales.Add();
		vSalesRow.Service = vTotalsRow.Service;
		vSalesRow.Currency = vTotalsRow.Currency;
		If Not vIsPreliminary Then
			If True Then
				vSalesRow.TotalSales = vTotalsRow.Sales + vTotalsRow.SalesForecast;
				vSalesRow.ForecastSales = vTotalsRow.SalesForecast;
				vSalesRow.Sales = vTotalsRow.Sales;
			Else
				vSalesRow.TotalSales = vTotalsRow.SalesWithoutVAT + vTotalsRow.SalesWithoutVATForecast;
				vSalesRow.ForecastSales = vTotalsRow.SalesWithoutVATForecast;
				vSalesRow.Sales = vTotalsRow.SalesWithoutVAT;
			EndIf;
		Else
			If True Then
				vSalesRow.TotalSales = 0;
				vSalesRow.ForecastSales = vTotalsRow.ExpectedSales;
				vSalesRow.Sales = vTotalsRow.Sales;
			Else
				vSalesRow.TotalSales = 0;
				vSalesRow.ForecastSales = vTotalsRow.ExpectedSalesWithoutVAT;
				vSalesRow.Sales = vTotalsRow.SalesWithoutVAT;
			EndIf;
		EndIf;
	EndDo;
	vSalesTotals.GroupBy("Currency", "Sales, SalesForecast, ExpectedSales, SalesWithoutVAT, SalesWithoutVATForecast, ExpectedSalesWithoutVAT");
	If vSalesTotals.Count() > 0 Then
		Items.TableBoxSales.FooterHeight = vSalesTotals.Count();
		For Each vTotalsRow In vSalesTotals Do
			If Not vIsPreliminary Then
				If True Then
					Items.TableBoxSales.ChildItems.TableBoxSalesTotalSales.FooterText = cmFormatSum(vTotalsRow.Sales + vTotalsRow.SalesForecast, vTotalsRow.Currency);
					Items.TableBoxSales.ChildItems.TableBoxSalesForecastSales.FooterText = cmFormatSum(vTotalsRow.SalesForecast, vTotalsRow.Currency);
					Items.TableBoxSales.ChildItems.TableBoxSalesSales.FooterText = cmFormatSum(vTotalsRow.Sales, vTotalsRow.Currency);
				Else
					Items.TableBoxSales.ChildItems.TableBoxSalesTotalSales.FooterText = cmFormatSum(vTotalsRow.SalesWithoutVAT + vTotalsRow.SalesWithoutVATForecast, vTotalsRow.Currency);
					Items.TableBoxSales.ChildItems.TableBoxSalesForecastSales.FooterText = cmFormatSum(vTotalsRow.SalesWithoutVATForecast, vTotalsRow.Currency);
					Items.TableBoxSales.ChildItems.TableBoxSalesSales.FooterText = cmFormatSum(vTotalsRow.SalesWithoutVAT, vTotalsRow.Currency);
				EndIf;
			Else
				If True Then
					Items.TableBoxSales.ChildItems.TableBoxSalesTotalSales.FooterText = "";
					Items.TableBoxSales.ChildItems.TableBoxSalesForecastSales.FooterText = cmFormatSum(vTotalsRow.ExpectedSales, vTotalsRow.Currency);
					Items.TableBoxSales.ChildItems.TableBoxSalesSales.FooterText = cmFormatSum(vTotalsRow.Sales, vTotalsRow.Currency);
				Else
					Items.TableBoxSales.ChildItems.TableBoxSalesTotalSales.FooterText = "";
					Items.TableBoxSales.ChildItems.TableBoxSalesForecastSales.FooterText = cmFormatSum(vTotalsRow.ExpectedSalesWithoutVAT, vTotalsRow.Currency);
					Items.TableBoxSales.ChildItems.TableBoxSalesSales.FooterText = cmFormatSum(vTotalsRow.SalesWithoutVAT, vTotalsRow.Currency);
				EndIf;
			EndIf;
			Items.TableBoxSales.ChildItems.TableBoxSalesTotalSales.FooterText = Items.TableBoxSales.ChildItems.TableBoxSalesTotalSales.FooterText + Chars.LF;
			Items.TableBoxSales.ChildItems.TableBoxSalesForecastSales.FooterText = Items.TableBoxSales.ChildItems.TableBoxSalesForecastSales.FooterText + Chars.LF;
			Items.TableBoxSales.ChildItems.TableBoxSalesSales.FooterText = Items.TableBoxSales.ChildItems.TableBoxSalesSales.FooterText + Chars.LF;
		EndDo;
	EndIf;
	// Fill guest group payments
	TableBoxPayments.Clear();
	vPaymentsTotals = vObj.pmGetPaymentsTotals();
	For Each vTotalsRow In vPaymentsTotals Do
		vPaymentsRow = TableBoxPayments.Add();
		vPaymentsRow.AccountingDate = vTotalsRow.AccountingDate;
		vPaymentsRow.Currency = vTotalsRow.Currency;
		If True Then
			vPaymentsRow.Sum = vTotalsRow.Sum;
		Else
			vPaymentsRow.Sum = vTotalsRow.Sum;
		EndIf;
	EndDo;
	vPaymentsTotals.GroupBy("Currency", "Sum, VATSum");
	If vPaymentsTotals.Count() > 0 Then
		Items.TableBoxPayments.FooterHeight = vPaymentsTotals.Count();
		For Each vTotalsRow In vPaymentsTotals Do
			If True Then
				Items.TableBoxPayments.ChildItems.TableBoxPaymentsSum.FooterText = cmFormatSum(vTotalsRow.Sum, vTotalsRow.Currency);
			Else
				Items.TableBoxPayments.ChildItems.TableBoxPaymentsSum.FooterText = cmFormatSum(vTotalsRow.Sum, vTotalsRow.Currency);
			EndIf;
			Items.TableBoxPayments.ChildItems.TableBoxPaymentsSum.FooterText = Items.TableBoxPayments.ChildItems.TableBoxPaymentsSum.FooterText + Chars.LF;
			// Update sales totals to calculate guest group balance
			vSalesTotalsRow = vSalesTotals.Find(vTotalsRow.Currency, "Currency");
			If vSalesTotalsRow = Undefined Then
				vSalesTotalsRow = vSalesTotals.Add();
				vSalesTotalsRow.Currency = vTotalsRow.Currency;
				vSalesTotalsRow.Sales = 0;
				vSalesTotalsRow.SalesForecast = 0;
				vSalesTotalsRow.SalesWithoutVAT = 0;
				vSalesTotalsRow.SalesWithoutVATForecast = 0;
			EndIf;
			vSalesTotalsRow.Sales = vSalesTotalsRow.Sales - vTotalsRow.Sum;
			vSalesTotalsRow.SalesWithoutVAT = vSalesTotalsRow.SalesWithoutVAT - (vTotalsRow.Sum - vTotalsRow.VATSum);
		EndDo;
	EndIf;
	// Fill guest group balance
	TGuestGroupBalance = "";
	If vSalesTotals.Count() > 0 Then
		For Each vSalesTotalsRow In vSalesTotals Do
			If Not IsBlankString(TGuestGroupBalance) Then
				TGuestGroupBalance = TGuestGroupBalance + "; ";
			EndIf;
			If Not vIsPreliminary Then
				TGuestGroupBalance = TGuestGroupBalance + cmFormatSum(vSalesTotalsRow.Sales + vSalesTotalsRow.SalesForecast, vSalesTotalsRow.Currency);
			Else
				TGuestGroupBalance = TGuestGroupBalance + cmFormatSum(vSalesTotalsRow.Sales + vSalesTotalsRow.ExpectedSales, vSalesTotalsRow.Currency);
			EndIf;
		EndDo;		
	EndIf;
	If vUseParameterObject = False Then
		// Set object value
		ValueToFormAttribute(vObj, "Object");
		// Fill block totals
		FillAvailableRoomsAtServer();
	EndIf;
EndProcedure // FillTotals

// -----------------------------------------------------------------------------
&AtServer
Procedure FillPrintingButton()
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ObjectPrintingForms.Ref AS Ref,
	|	ObjectPrintingForms.Code AS Code,
	|	ObjectPrintingForms.PredefinedDataName AS PredefinedDataName,
	|	ObjectPrintingForms.IsDefault AS IsDefault,
	|	ObjectPrintingForms.Language AS Language,
	|	ObjectPrintingForms.ObjectType AS ObjectType
	|FROM
	|	Catalog.ObjectPrintingForms AS ObjectPrintingForms
	|WHERE
	|	NOT ObjectPrintingForms.DeletionMark
	|	AND ObjectPrintingForms.IsActive = TRUE
	|	AND (ObjectPrintingForms.ObjectType = &qObjectAccommodation
	|			OR ObjectPrintingForms.ObjectType = &qObjectReservation
	|			OR ObjectPrintingForms.ObjectType = &qObjectResourceReservation
	|			OR ObjectPrintingForms.ObjectType = &qObjectGuestGroups)
	|
	|ORDER BY
	|	IsDefault DESC,
	|	Code
	|TOTALS BY
	|	Language";
	
	Query.SetParameter("qObjectAccommodation", Documents.Accommodation.EmptyRef());
	Query.SetParameter("qObjectReservation", Documents.Reservation.EmptyRef());
	Query.SetParameter("qObjectResourceReservation", Documents.ResourceReservation.EmptyRef());
	Query.SetParameter("qObjectGuestGroups", Catalogs.GuestGroups.EmptyRef());
	QueryResult = Query.Execute();
	QueryListResult = Query.Execute().Unload();
	vPrintGuestGroupHotelProducts = "";
	vPrintGuestRegistrationForms = "";
	vPrintGuestsCardsForm4G = "";
	vPrintGuestsForms2Forms5 = "";
	vPrintGuestsFormsForm5 = "";
	vPrintGuestsCardsFreeForm = "";
	If QueryListResult.FindRows(New Structure("PredefinedDataName","AccommodationPrintGuestGroupHotelProducts")).Count() > 0 Then
		vPrintGuestGroupHotelProducts = "AccommodationPrintGuestGroupHotelProducts";
	ElsIf QueryListResult.FindRows(New Structure("PredefinedDataName","ReservationPrintPrintGuestGroupHotelProducts")).Count() > 0 Then
		vPrintGuestGroupHotelProducts = "ReservationPrintGuestGroupHotelProducts";	
	EndIf;
	If QueryListResult.FindRows(New Structure("PredefinedDataName","AccommodationPrintGuestRegistrationForms")).Count() > 0 Then
		vPrintGuestRegistrationForms = "AccommodationPrintGuestRegistrationForms";
	ElsIf QueryListResult.FindRows(New Structure("PredefinedDataName","ReservationPrintGuestRegistrationForms")).Count() > 0 Then
		vPrintGuestRegistrationForms = "ReservationPrintGuestRegistrationForms";	
	EndIf;
	If QueryListResult.FindRows(New Structure("PredefinedDataName","AccommodationPrintGuestsCardsForm4G")).Count() > 0 Then
		vPrintGuestsCardsForm4G = "AccommodationPrintGuestsCardsForm4G";
	ElsIf QueryListResult.FindRows(New Structure("PredefinedDataName","ReservationPrintGuestsCardsForm4G")).Count() > 0 Then
		vPrintGuestsCardsForm4G = "ReservationPrintGuestsCardsForm4G";	
	EndIf;
	If QueryListResult.FindRows(New Structure("PredefinedDataName","AccommodationPrintGuestsForms2Forms5")).Count() > 0 Then
		vPrintGuestsForms2Forms5 = "AccommodationPrintGuestsForms2Forms5";
	ElsIf QueryListResult.FindRows(New Structure("PredefinedDataName","ReservationPrintGuestsForms2Forms5")).Count() > 0 Then
		vPrintGuestsForms2Forms5 = "ReservationPrintGuestsForms2Forms5";	
	EndIf;
	If QueryListResult.FindRows(New Structure("PredefinedDataName","AccommodationPrintGuestsFormsForm5")).Count() > 0 Then
		vPrintGuestsFormsForm5 = "AccommodationPrintGuestsFormsForm5";
	ElsIf QueryListResult.FindRows(New Structure("PredefinedDataName","ReservationPrintGuestsFormsForm5")).Count() > 0 Then
		vPrintGuestsFormsForm5 = "ReservationPrintGuestsFormsForm5";	
	EndIf;
	If QueryListResult.FindRows(New Structure("PredefinedDataName","AccommodationPrintGuestsCardsFreeForm")).Count() > 0 Then
		vPrintGuestsCardsFreeForm = "AccommodationPrintGuestsCardsFreeForm";
	ElsIf QueryListResult.FindRows(New Structure("PredefinedDataName","ReservationPrintGuestsCardsFreeForm")).Count() > 0 Then
		vPrintGuestsCardsFreeForm = "ReservationPrintGuestsCardsFreeForm";	
	EndIf;
	SelectionRecords = QueryResult.Select(QueryResultIteration.ByGroups);
	PrintForms.Clear();
	If Object.Client <> Catalogs.Clients.EmptyRef() And ValueIsFilled(Object.Client.Language) Then
		vLang = Object.Client.Language;
	ElsIf Object.Customer <> Catalogs.Customers.EmptyRef() And ValueIsFilled(Object.Customer.Language) Then 
		vLang = Object.Customer.Language;	
	Else
		vLang = CurrentLanguage();	
	EndIf;
	While SelectionRecords.Next() Do
		SelectionDetailRecords = SelectionRecords.Select(QueryResultIteration.ByGroups);
		
		If vLang = SelectionRecords.Language or not ValueIsFilled(SelectionRecords.Language) Then
			vParentLang = Items.FormGroupPrintingNotDefaultMain;
		ElsIf not vLang = SelectionRecords.Language Then
			vParentLang = tcOnServer.cmCreateItem(ThisObject,Items.FormGroupPrintingNotDefaultExtra, "Print" + SelectionRecords.Language, "FormGroup",
			New Structure("Type, Title", FormGroupType.Popup,SelectionRecords.Language));
		EndIf;
		While SelectionDetailRecords.Next() Do
			If (SelectionDetailRecords.PredefinedDataName = "" And SelectionDetailRecords.ObjectType = Catalogs.GuestGroups.EmptyRef()) Or
			   (SelectionDetailRecords.PredefinedDataName = vPrintGuestGroupHotelProducts And vPrintGuestGroupHotelProducts <> "") Or
			   (SelectionDetailRecords.PredefinedDataName = vPrintGuestRegistrationForms And vPrintGuestRegistrationForms <> "") Or 
			   (SelectionDetailRecords.PredefinedDataName = vPrintGuestsCardsForm4G And vPrintGuestsCardsForm4G <> "") Or
			   (SelectionDetailRecords.PredefinedDataName = vPrintGuestsCardsFreeForm And vPrintGuestsCardsFreeForm <> "") Or
			   (SelectionDetailRecords.PredefinedDataName = vPrintGuestsForms2Forms5 And vPrintGuestsForms2Forms5 <> "") Or
			   (SelectionDetailRecords.PredefinedDataName = vPrintGuestsFormsForm5 And vPrintGuestsFormsForm5 <> "") Or 
			   SelectionDetailRecords.PredefinedDataName = "AccommodationPrintGuestsFormsForm1G" Or
			   SelectionDetailRecords.PredefinedDataName = "AccommodationPrintGuestsFormsFreeForm" Or 
			   SelectionDetailRecords.PredefinedDataName = "ReservationPrintCancellationDe" Or 
			   SelectionDetailRecords.PredefinedDataName = "ReservationPrintCancellationEn" Or 
			   SelectionDetailRecords.PredefinedDataName = "ReservationPrintCancellationRu" Or
			   SelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationDe" Or
			   SelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationEn" Or
			   SelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationRu" Or
			   SelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationWithServicesDe" Or
			   SelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationWithServicesEn" Or
			   SelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationWithServicesRu" Or 
			   SelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationRichTextDe" Or
			   SelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationRichTextEn" Or
			   SelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationRichTextRu" Or 
			   SelectionDetailRecords.PredefinedDataName = "ResourceReservationPrintConfirmationRu" Or 
			   SelectionDetailRecords.PredefinedDataName = "ResourceReservationPrintConfirmationEn" Or 
			   SelectionDetailRecords.PredefinedDataName = "ResourceReservationPrintConfirmationDe" Or
			   SelectionDetailRecords.PredefinedDataName = "ResourceReservationPrintConfirmationByDaysRu" Or 
			   SelectionDetailRecords.PredefinedDataName = "ResourceReservationPrintConfirmationByDaysEn" Or 
			   SelectionDetailRecords.PredefinedDataName = "ResourceReservationPrintConfirmationByDaysDe" Then 
			   
			   	vNewRow = PrintForms.Add();
				vNewRow.PrintForm = SelectionDetailRecords.Ref;
				vNewRow.IsDefault = SelectionDetailRecords.IsDefault;
				
				vID = vNewRow.GetID();
				
				vCommand = Commands.Add("Print"+vID);
				vCommand.Action = "PrintButtonClick";
				If SelectionDetailRecords.IsDefault Then
					vParent = Items.FormGroupPrintingDefault;
				Else
					vParent = vParentLang;
				EndIf;
				vStructure = New Structure("Title, CommandName", TrimAll(SelectionDetailRecords.Code) + " " + cmNStr(SelectionDetailRecords.Ref), "Print" + vID);
				
				tcOnServer.cmCreateItem(ThisObject, vParent, "Print" + vID, "FormButton", vStructure);
			EndIf;
		EndDo;
	EndDo;
EndProcedure // FillPrintingButton

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
&AtClient
Procedure OpenExternalProcedureForm(pExtProcRef, pPrintFormTypeRef)
	vURL = GetURL(pExtProcRef, "ExternalProcessingStorage"); 
	vName = ConnectExternalDataProcessor(vURL, GetExternalProcessingValidName(tcOnServer.cmGetAttributeByRef(pExtProcRef, "FileName")));
	vParams = New Structure("InputParameter, ObjectPrintingForm, OneGuestMode", Object.Ref, pPrintFormTypeRef, False);
    OpenForm("ExternalDataProcessor." + vName + ".Form", vParams);
EndProcedure // OpenExternalProcedureForm

// -----------------------------------------------------------------------------
&AtServer
Function GetExternalProcessingValidName(Val pStr)
	Return cmGetValidName(pStr); 	
EndFunction // GetExternalProcessingValidName

// -----------------------------------------------------------------------------
&AtServer
Function ConnectExternalReport(pPath, pName = "", pUseSafeMode = False)
	Return ExternalReports.Connect(pPath, pName, pUseSafeMode);
EndFunction // ConnectExternalDataProcessor

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenExternalReportForm(pExtRepRef, pPrintFormTypeRef)
	vURL = GetURL(tcOnServer.cmGetAttributeByRef(pExtRepRef,"Report"), "ExternalProcessingStorage"); 
	vName = ConnectExternalReport(vURL, "ExternalReportForm");
	vParams = New Structure("Document, ObjectPrintingForm, OneGuestMode", Object.Ref, pPrintFormTypeRef, False);
	OpenForm("ExternalReport." + vName + ".Form", vParams);
EndProcedure // OpenExternalReportForm

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintButtonClick(pCommand)
	vPrintNumber = StrReplace(pCommand.Name,"Print","");
	vPrintForm = GetPrintFormForNumber(vPrintNumber);
	
	// Load external print form
	If ValueIsFilled(vPrintForm.ExternalProcessing) Then 
		Try
			OpenExternalProcedureForm(vPrintForm.ExternalProcessing, vPrintForm.Ref);
		Except
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'"), MessageStatus.Attention);
		EndTry;
	ElsIf ValueIsFilled(vPrintForm.Report) Then
		Try
			OpenExternalReportForm(vPrintForm.Report, vPrintForm.Ref);
		Except
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'"), MessageStatus.Attention);
		EndTry;
	ElsIf vPrintForm.PredefinedDataName = "AccommodationPrintGuestGroupHotelProducts" Or
		  vPrintForm.PredefinedDataName = "ReservationPrintGuestGroupHotelProducts" Then
		  vParams = New Structure("SelGuestGroup, SelCheckInDate, SelObjectPrintForm", Object.Ref, Object.CheckInDate, vPrintForm.Ref);
		  OpenForm("Report.PrintHotelProducts.Form.tcReportForm", vParams, ThisObject, UUID);
	ElsIf vPrintForm.PredefinedDataName = "AccommodationPrintGuestsForms2Forms5" Or 
	      vPrintForm.PredefinedDataName = "AccommodationPrintGuestsFormsFreeForm" Or
	      vPrintForm.PredefinedDataName = "AccommodationPrintGuestRegistrationForms" Or 
		  vPrintForm.PredefinedDataName = "AccommodationPrintGuestsCardsForm4G" Or
		  vPrintForm.PredefinedDataName = "AccommodationPrintGuestsFormsForm5" Or
		  vPrintForm.PredefinedDataName = "AccommodationPrintGuestsCardsFreeForm" Or
		  vPrintForm.PredefinedDataName = "AccommodationPrintGuestsFormsForm1G" Or
		  vPrintForm.PredefinedDataName = "ReservationPrintGuestsForms2Forms5" Or 
	      vPrintForm.PredefinedDataName = "ReservationPrintGuestsFormsFreeForm" Or
	      vPrintForm.PredefinedDataName = "ReservationPrintGuestRegistrationForms" Or 
		  vPrintForm.PredefinedDataName = "ReservationPrintGuestsCardsForm4G" Or
		  vPrintForm.PredefinedDataName = "ReservationPrintGuestsFormsForm5" Or
		  vPrintForm.PredefinedDataName = "ReservationPrintGuestsCardsFreeForm" Or
		  vPrintForm.PredefinedDataName = "ReservationPrintGuestsFormsForm1G" Then
		PrintGuestsForms(vPrintForm.PredefinedDataName);
	ElsIf vPrintForm.PredefinedDataName = "ReservationPrintConfirmationRu" Or
	      vPrintForm.PredefinedDataName = "ReservationPrintConfirmationEn" Or
	      vPrintForm.PredefinedDataName = "ReservationPrintConfirmationDe" Then
		vSelReservation = GetDocumentReservations();
		vParams = new Structure("SelReservation, SelReservationObj, SelLanguage, SelObjectPrintForm", 
		                        vSelReservation,
								Undefined, 
								tcOnServer.cmGetAttributeByRef(vPrintForm.Ref, "Language"),
								vPrintForm.Ref);
		OpenForm("Document.Reservation.Form.tcReservationConfirmationForm", vParams, ThisObject, UUID);
	ElsIf vPrintForm.PredefinedDataName = "ReservationPrintConfirmationWithServicesRu" Or
	      vPrintForm.PredefinedDataName = "ReservationPrintConfirmationWithServicesEn" Or
	      vPrintForm.PredefinedDataName = "ReservationPrintConfirmationWithServicesDe" Then
		vSelReservation = GetDocumentReservations();
		vParams = new Structure("SelReservation, SelReservationObj, SelLanguage, SelObjectPrintForm", 
		                        vSelReservation,
								Undefined, 
								tcOnServer.cmGetAttributeByRef(vPrintForm.Ref, "Language"),
								vPrintForm.Ref);
		OpenForm("Document.Reservation.Form.tcReservationConfirmationWithServicesForm", vParams, ThisObject, UUID);
	ElsIf vPrintForm.PredefinedDataName = "ReservationPrintConfirmationRichTextRu" Or
	      vPrintForm.PredefinedDataName = "ReservationPrintConfirmationRichTextEn" Or
		  vPrintForm.PredefinedDataName = "ReservationPrintConfirmationRichTextDe" Then
		vParams = New Structure("InputParameter, ObjectPrintingForm", Object.Ref, vPrintForm.Ref);
		OpenForm("DataProcessor.ReservationConfirmationRichTextFormat.Form", vParams, ThisObject, UUID);
	ElsIf vPrintForm.PredefinedDataName = "ReservationPrintCancellationRu" Or
	      vPrintForm.PredefinedDataName = "ReservationPrintCancellationEn" Or
	      vPrintForm.PredefinedDataName = "ReservationPrintCancellationDe" Then
		vSelReservation = GetDocumentReservations();
		vParams = new Structure("SelReservation, SelReservationObj, SelLanguage, SelObjectPrintForm", 
		                        vSelReservation,
								Undefined, 
								tcOnServer.cmGetAttributeByRef(vPrintForm.Ref, "Language"),
								vPrintForm.Ref);
		OpenForm("Document.Reservation.Form.tcReservationCancellationForm", vParams, ThisObject, UUID);
	ElsIf vPrintForm.PredefinedDataName = "ResourceReservationPrintConfirmationRu" Or
	      vPrintForm.PredefinedDataName = "ResourceReservationPrintConfirmationEn" Or
	      vPrintForm.PredefinedDataName = "ResourceReservationPrintConfirmationDe" Then
		vSelReservation = GetDocumentResourceReservations();
		OpenForm("Document.ResourceReservation.Form.tcReservationConfirmationForm", New Structure("SelReservation, SelLanguage, SelObjectPrintForm, SelByDays, CloseOnOwnerClose",vSelReservation, tcOnServer.cmGetAttributeByRef(vPrintForm.Ref, "Language"), vPrintForm.Ref, False, False), ThisObject, UUID);
	ElsIf vPrintForm.PredefinedDataName = "ResourceReservationPrintConfirmationByDaysRu" Or
	      vPrintForm.PredefinedDataName = "ResourceReservationPrintConfirmationByDaysEn" Or
	      vPrintForm.PredefinedDataName = "ResourceReservationPrintConfirmationByDaysDe" Then
		vSelReservation = GetDocumentResourceReservations(); 
		OpenForm("Document.ResourceReservation.Form.tcReservationConfirmationForm", New Structure("SelReservation, SelLanguage, SelObjectPrintForm, SelByDays, CloseOnOwnerClose", vSelReservation, tcOnServer.cmGetAttributeByRef(vPrintForm.Ref, "Language"), vPrintForm.Ref, True, False), ThisObject, UUID);
	ElsIf vPrintForm.PredefinedDataName = "ResourceReservationPrintConfirmationByDaysRu" Or
	      vPrintForm.PredefinedDataName = "ResourceReservationPrintConfirmationByDaysEn" Or
	      vPrintForm.PredefinedDataName = "ResourceReservationPrintConfirmationByDaysDe" Then
		vSelReservation = GetDocumentReservations(); 
		OpenForm("Document.ResourceReservation.Form.tcReservationConfirmationForm", New Structure("SelReservation, SelLanguage, SelObjectPrintForm, SelByDays, CloseOnOwnerClose", vSelReservation, tcOnServer.cmGetAttributeByRef(vPrintForm.Ref, "Language"), vPrintForm.Ref, True, False), ThisObject, UUID);
	EndIf;    
EndProcedure // PrintButtonClick

// -----------------------------------------------------------------------------
&AtServer
Function GetDocumentResourceReservations() 
	vDocument = Documents.ResourceReservation.EmptyRef();
	vObj = FormAttributeToValue("Object");
	vDocuments = vObj.pmGetResourceReservations(True);
	If vDocuments.Count() > 0 Then
		vDocument = vDocuments.Get(0).Reservation; 	
	EndIf;
	Return vDocument;
EndFunction // GetDocumentResourceReservations

// -----------------------------------------------------------------------------
&AtServer
Function GetDocumentReservations() 
	vDocument = Documents.Reservation.EmptyRef();
	vObj = FormAttributeToValue("Object");
	vDocuments = vObj.pmGetReservations(True, True);
	If vDocuments.Count() > 0 Then
		vDocument = vDocuments.Get(0).Reservation; 	
	EndIf;
	Return vDocument;
EndFunction // GetDocumentReservations

// -----------------------------------------------------------------------------
&AtServer
Function GetDocumentAccommodations() 
	vDocument = Documents.Accommodation.EmptyRef();
	vObj = FormAttributeToValue("Object");
	vDocuments = vObj.pmGetAccommodations(True);
	If vDocuments.Count() > 0 Then
		vDocument = vDocuments.Get(0).Accommodation; 	
	EndIf;
	Return vDocument;
EndFunction // GetDocumentResourceReservations

// -----------------------------------------------------------------------------
&AtServer
Procedure FillFunctionsButton()
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ObjectFormActions.Ref AS Ref,
	|	ObjectFormActions.Code AS Code,
	|	ObjectFormActions.PredefinedDataName AS PredefinedDataName,
	|	ObjectFormActions.IsDefault AS IsDefault
	|FROM
	|	Catalog.ObjectFormActions AS ObjectFormActions
	|WHERE
	|	NOT ObjectFormActions.DeletionMark
	|	AND ObjectFormActions.IsActive = TRUE
	|	AND (ObjectFormActions.ObjectType = &ObjectAccommodation
	|			OR ObjectFormActions.ObjectType = &ObjectReservation)
	|
	|ORDER BY
	|	IsDefault DESC,
	|	Code";
	
	Query.SetParameter("ObjectAccommodation", Documents.Accommodation.EmptyRef());
	Query.SetParameter("ObjectReservation", Documents.Reservation.EmptyRef());	
	QueryResult = Query.Execute();
	QueryListResult = Query.Execute().Unload();
	SelectionRecords = QueryResult.Select();
	Actions.Clear();
	
	While SelectionRecords.Next() Do
		If SelectionRecords.PredefinedDataName = ""
			or SelectionRecords.PredefinedDataName = "ReservationCopyGuestGroupReservations" Then
	
			vNewRow = Actions.Add();
			vNewRow.Action = SelectionRecords.Ref;
			vNewRow.IsDefault = SelectionRecords.IsDefault;
			
			vID = vNewRow.GetID();
			
			vCommand = Commands.Add("Func" + vID);
			vCommand.Action = "FuncButtonClick";
			If SelectionRecords.IsDefault Then
				vStructure = New Structure("Title,CommandName",
				TrimAll(SelectionRecords.Code) + " " + cmNStr(SelectionRecords.ref), "Func" + vID);
			Else
				vStructure = New Structure("Title,CommandName",
				TrimAll(SelectionRecords.Code) + " " + cmNStr(SelectionRecords.ref), "Func" + vID);
			EndIf;
			
			tcOnServer.cmCreateItem(ThisObject, ?(SelectionRecords.IsDefault, Items.FormGroupFunctionsDefault, Items.FormGroupFunctionsNotDefault), "Func" + vID, "FormButton", vStructure);
		EndIf;
	EndDo;
EndProcedure

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
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Function RunDataProcessor(pDataProcessor, pParameter, pIsInteractive = False, rReturnParameter)
	vPARAM = New Structure("InputParameter, OutputParameter", pParameter, rReturnParameter);
	vResult = cmRunDataProcessor(pDataProcessor, vPARAM, pIsInteractive);
	rReturnPameter = vPARAM.OutputParameter;
	Return vResult;
EndFunction

// -----------------------------------------------------------------------------
&AtClient
Procedure FuncButtonClick(pCommand)
	vActionsNumber = StrReplace(pCommand.Name,"Func","");
	vAction = GetActionForNumber(vActionsNumber);
	
	If Not ValueIsFilled(vAction.ExternalProcessing) Then
		If vAction.PredefinedDataName = "ReservationCopyGuestGroupReservations" Then 
			ARReservationCopyGuestGroupReservations(vAction, False);
		// Run data processor
		ElsIf ValueIsFilled(vAction.DataProcessor) Then     
			vReturnParameter = New Structure("Action, Data, FileName");
			If Not RunDataProcessor(vAction.DataProcessor, Object.Ref, True, vReturnParameter) Then
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
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ARReservationCopyGuestGroupReservations(pAction, pIsInAutomaticMode = False)
	OpenForm("DataProcessor.CopyGuestGroupReservations.Form.tcFPForm", New Structure("GuestGroupFrom, CheckInDateFrom", Object.Ref, BegOfDay(Object.CheckInDate)), ThisObject, UUID);
	If Not Modified Then
		If IsOpen() Then
			Close();
		EndIf;
	EndIf;
EndProcedure // ARReservationCopyGuestGroupReservations

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintGuestsForms(pTypeOfPrintForm)
	vDocument = GetDocumentReservations();
	If Not ValueIsFilled(vDocument) Then
		vDocument = GetDocumentAccommodations();	
	EndIf;
	If Not ValueIsFilled(vDocument) And ValueIsFilled(Object.ClientDoc) Then
		vDocument = Object.ClientDoc;	
	EndIf;
	vObjPrtForm = tcOnServer.cmGetCatalogItemRefByName("ObjectPrintingForms", pTypeOfPrintForm);
	vCheckInDate = Date(1,1,1);
	If pTypeOfPrintForm = "ReservationPrintGuestsCardsForm4G" Or  pTypeOfPrintForm = "AccommodationPrintGuestsCardsForm4G" Or  pTypeOfPrintForm = "AccommodationPrintGuestsCardsFreeForm" Or pTypeOfPrintForm = "ReservationPrintGuestsCardsFreeForm" Then
		vCheckInDate = Object.CheckInDate;	
	EndIf;
	vFrm = OpenForm("Document.Accommodation.Form.tcPrintGuestForm", New Structure("Document, GuestGroup, ObjectPrintingForm, CheckInDate", vDocument, Object.Ref, vObjPrtForm, vCheckInDate), ThisObject, UUID);
EndProcedure // PrintGuestsForms

// -----------------------------------------------------------------------------
&AtClient
Procedure Refresh(pCommand)
	// Fill guest group totals
	FillTotals();
EndProcedure // Refresh

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupResourcesRefreshRequestProcessing()
	// Fill guest group totals
	FillTotals()
EndProcedure // GuestGroupResourcesRefreshRequestProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure ClientOnChange(pItem)
	ClientOnChangeAtServer();
EndProcedure // ClientOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure ClientOnChangeAtServer(pObj = Undefined)
	// Check parameters
	vObj = pObj;
	If pObj = Undefined Then
		vObj = Object;
	EndIf;
	If ValueIsFilled(vObj.Client) Then
		vObj.FixedClient = True;
	Else
		vObj.FixedClient = False;
	EndIf;
EndProcedure // ClientOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetGroupDocuments(pGuestGroup)
	Return cmGetGuestGroupDocuments(pGuestGroup);
EndFunction // GetGroupDocuments

// -----------------------------------------------------------------------------
&AtServer
Function GetGroupResources()
	vQry = New Query;  
	vQry.Text =
	"SELECT
	|	ResourceReservations.Ref AS Document,
	|	ResourceReservations.ResourceReservationStatus AS ReservationStatus,
	|	ResourceReservations.DateTimeFrom AS DateTimeFrom,
	|	ResourceReservations.DateTimeTo AS DateTimeTo,
	|	ResourceReservations.Duration AS Duration,
	|	ResourceReservations.ResourceType AS ResourceType,
	|	ResourceReservations.ResourceType.Code AS ResourceTypeCode,
	|	ResourceReservations.ResourceType.SortCode AS ResourceTypeSortCode,
	|	ResourceReservations.Resource AS Resource,
	|	ResourceReservations.Resource.SortCode AS ResourceSortCode,
	|	ResourceReservations.NumberOfPersons AS NumberOfPersons,
	|	ResourceReservations.Client AS Guest,
	|	ResourceReservations.Client.FullName AS ClientFullName,
	|	ResourceReservations.Number AS Number,
	|	ResourceReservations.Remarks AS Remarks,
	|	ResourceReservations.ParentDoc AS ParentDoc,
	|	ResourceReservations.ChargingFolio AS ChargingFolio,
	|	0 AS LineNumber,
	|	13 AS Picture,
	|	"""" AS RowTotals,
	|	ResourceReservations.GuestGroup AS GuestGroup,
	|	ResourceReservations.Customer AS Customer,
	|	ResourceReservations.Hotel AS Hotel,
	|	ResourceReservations.Posted AS Posted,
	|	ResourceReservations.DeletionMark AS DeletionMark
	|FROM
	|	Document.ResourceReservation AS ResourceReservations
	|WHERE
	|	ResourceReservations.GuestGroup = &qGuestGroup
	|	AND ResourceReservations.ResourceReservationStatus.IsActive
	|	AND ResourceReservations.Posted" 
	+ ?(ValueIsFilled(SessionParameters.CurrentUser.Customer), " AND ResourceReservations.Customer = &qCustomer ", " ") + "
	|ORDER BY
	|	DateTimeFrom,
	|	ResourceSortCode";
	vQry.SetParameter("qGuestGroup", Object.Ref);
	If ValueIsFilled(SessionParameters.CurrentUser.Customer) Then
		vQry.SetParameter("qCustomer", SessionParameters.CurrentUser.Customer);
	EndIf;
	Return vQry.Execute().Unload();
EndFunction // GetGroupResources

// -----------------------------------------------------------------------------
&AtServer
Function GetGroupDocumentsList(pAllDocs = False)
	vRefList = New ValueList();
	If Not pAllDocs And Items.GuestGroupTableBox.SelectedRows.Count() > 0 Then
		For Each vSelRowIndex In Items.GuestGroupTableBox.SelectedRows Do
			vRowData = GuestGroupTableBox.FindById(vSelRowIndex);
			If vRefList.FindByValue(vRowData.Document) = Undefined Then
				vRefList.Add(vRowData.Document);
			EndIf;
			vChildItems = vRowData.GetItems();
			For Each vChildItem In vChildItems Do
				If vRefList.FindByValue(vChildItem.Document) = Undefined Then
					vRefList.Add(vChildItem.Document);
				EndIf;
			EndDo;
		EndDo;
	Else
		vQryResult = GetGroupDocuments(Object.Ref);
		For Each vQryResultRow In vQryResult Do
			vRefList.Add(vQryResultRow.Reservation);
		EndDo;
	EndIf;
	Return vRefList;
EndFunction // GetGroupDocumentsList

// -----------------------------------------------------------------------------
&AtServer
Procedure FillGroupList(pObj = Undefined)
	// Check paramters
	vObj = pObj;
	If pObj = Undefined then
		vObj = Object;
	EndIf;
	// Fill group rooms
	GuestGroupTableBox.GetItems().Clear();
	vQryResult = GetGroupDocuments(vObj.Ref);
	vTypesArray = New Array;
	vTypesArray.Add(Type("DocumentRef.Accommodation"));
	vTypesArray.Add(Type("DocumentRef.Reservation"));
	vQryResult.Columns.Add("Document", New TypeDescription(vTypesArray));
	vLN = 1;
	vMainRef = Documents.Reservation.EmptyRef();
	For each vRow in vQryResult Do
		vRow.Document = vRow.Reservation;
		// Fill picture attribute
		If vRow.DeletionMark Then
			If vRow.Posted Then
				If Modified Then
					vRow.Picture = 17;
				Else
					vRow.Picture = 16;
				EndIf;
			Else
				vRow.Picture = 15;
			EndIf;
		Else
			If vRow.Posted Then
				If Modified Then
					vRow.Picture = 14;
				Else
					vRow.Picture = 13;
				EndIf;
			Else
				vRow.Picture = 12;
			EndIf;
		EndIf;
		If vLN = 1 Then
			vRow.LineNumber = vLN;
			vLN = vLN + 1;
			vRoomMainRow = GuestGroupTableBox.GetItems().Add();
			FillPropertyValues(vRoomMainRow, vRow);
			vRoomMainRow.IsMain = True;
			vRoomMainRow.MainRef = vRow.Document;
			vMainRef = vRow.Document;
			// Blocks
			If vRow.RoomQuantity <> Null And vRow.RoomQuantity > 1 And vRow.CheckInRoomQuantity > 0 Then
				vRoomMainRow.GuestFullName = NStr("en='Q-ty: '; ru='Кол-во: '; de='Q-ti: '") + Format(vRow.CheckInRoomQuantity, "NFD=0; NG=") + ?(IsBlankString(vRoomMainRow.GuestFullName), "", ", " + TrimAll(vRoomMainRow.GuestFullName));
			EndIf;
		Else
			vLastRoomMainRow = GuestGroupTableBox.GetItems().Get(GuestGroupTableBox.GetItems().Count()-1);
			If vLastRoomMainRow.Room = vRow.Room Then
				vRoomChildRow = vLastRoomMainRow.GetItems().Add();
				FillPropertyValues(vRoomChildRow, vRow);
				vRoomChildRow.IsMain = False;
				vRoomChildRow.MainRef = vMainRef;
				vLastRoomMainRow.NumberOfPersons = vLastRoomMainRow.NumberOfPersons + vRoomChildRow.NumberOfPersons;
				vRoomChildRow.NumberOfPersons = 0;
			Else
				vRow.LineNumber = vLN;
				vLN = vLN + 1;
				vRoomMainRow = GuestGroupTableBox.GetItems().Add();
				FillPropertyValues(vRoomMainRow, vRow);
				vRoomMainRow.IsMain = True;
				vRoomMainRow.MainRef = vRow.Document;
				vMainRef = vRow.Document;
				// Blocks
				If vRow.RoomQuantity <> Null And vRow.RoomQuantity > 1 And vRow.CheckInRoomQuantity > 0 Then
					vRoomMainRow.GuestFullName = NStr("en='Q-ty: '; ru='Кол-во: '; de='Q-ti: '") + Format(vRow.CheckInRoomQuantity, "NFD=0; NG=") + ?(IsBlankString(vRoomMainRow.GuestFullName), "", ", " + TrimAll(vRoomMainRow.GuestFullName));
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	// Fill group resources
	GuestGroupResources.Clear();
	vQryResult = GetGroupResources();
	vLN = 1;
	For each vRow in vQryResult Do
		// Fill picture attribute
		If vRow.DeletionMark Then
			If vRow.Posted Then
				If Modified Then
					vRow.Picture = 17;
				Else
					vRow.Picture = 16;
				EndIf;
			Else
				vRow.Picture = 15;
			EndIf;
		Else
			If vRow.Posted Then
				If Modified Then
					vRow.Picture = 14;
				Else
					vRow.Picture = 13;
				EndIf;
			Else
				vRow.Picture = 12;
			EndIf;
		EndIf;
		vRow.LineNumber = vLN;
		vResourceRow = GuestGroupResources.Add();
		FillPropertyValues(vResourceRow, vRow);
		vLN = vLN + 1;
	EndDo;
	If GuestGroupTableBox.GetItems().Count() > 0 And vObj.IsNewBlock Then
		vObj.IsNewBlock = False;
		Object.IsNewBlock = False;
		SetNewBlockModeAppearance();
	EndIf;
EndProcedure // FillGroupList

// -----------------------------------------------------------------------------
&AtServer
Function CalculateGuestGroupTableBoxRowServices(pRef, pRow = Undefined)
	// Calculate services per room
	vSrv = New ValueTable();
	If Not pRef.IsEmpty() Then
		vSrv = pRef.Services.Unload(, "Sum, DiscountSum, CommissionSum, FolioCurrency");
		vObj = pRef;
		If pRow <> Undefined Then
			For Each vRowChild In pRow.GetItems() Do
				If ValueIsFilled(vRowChild.Document) Then
					vChildSrv = vRowChild.Document.Services.Unload(, "Sum, DiscountSum, CommissionSum, FolioCurrency");
					For Each vChildSrvRow In vChildSrv Do
						vSrvRow = vSrv.Add();
						FillPropertyValues(vSrvRow, vChildSrvRow);
					EndDo;
				EndIf;
			EndDo;
		EndIf;
	EndIf;	
	vTotalStr = "";
	// We have to group all amounts by currencies
	If vSrv.Count() > 0 Then
		vSrv.GroupBy("FolioCurrency", "Sum, DiscountSum, CommissionSum");
		If ValueIsFilled(vObj.Agent) And vObj.Agent = vObj.Customer And ValueIsFilled(vObj.AgentCommissionType) And 
			cmCustomerIsPayer(vObj.ChargingRules.Unload(), vObj.Customer, vObj.Contract, vObj.GuestGroup, vObj.IgnoreGroupChargingRules) Then
			For Each vTotal In vSrv Do
				If IsBlankString(vTotalStr) Then
					vTotalStr = cmFormatSum(vTotal.Sum - vTotal.DiscountSum - vTotal.CommissionSum, vTotal.FolioCurrency, "NZ=---");
				Else
					vTotalStr = vTotalStr + "; " + cmFormatSum(vTotal.Sum - vTotal.DiscountSum - vTotal.CommissionSum, vTotal.FolioCurrency, "NZ=---");
				EndIf;
			EndDo;
		Else
			For Each vTotal In vSrv Do
				If IsBlankString(vTotalStr) Then
					vTotalStr = cmFormatSum(vTotal.Sum - vTotal.DiscountSum, vTotal.FolioCurrency, "NZ=---");
				Else
					vTotalStr = vTotalStr + "; " + cmFormatSum(vTotal.Sum - vTotal.DiscountSum, vTotal.FolioCurrency, "NZ=---");
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	Return vTotalStr;
EndFunction // CalculateGuestGroupTableBoxRowServices

// -----------------------------------------------------------------------------
&AtServer
Function CalculateGuestGroupResourcesRowServices(pRef)
	// Calculate services per room
	vSrv = New ValueTable();
	If Not pRef.IsEmpty() Then
		vSrv = pRef.Services.Unload(, "Sum, DiscountSum, CommissionSum");
	EndIf;	
	vTotalStr = "";
	// We have to group all amounts by currencies
	If vSrv.Count() > 0 Then
		vSrv.GroupBy(, "Sum, DiscountSum, CommissionSum");
		If ValueIsFilled(pRef.Agent) And pRef.Agent = pRef.Customer And ValueIsFilled(pRef.AgentCommissionType) And 
			(pRef.Customer = pRef.Owner Or pRef.Contract = pRef.Owner) Then
			For Each vTotal In vSrv Do
				If IsBlankString(vTotalStr) Then
					vTotalStr = cmFormatSum(vTotal.Sum - vTotal.DiscountSum - vTotal.CommissionSum, pRef.FolioCurrency, "NZ=---");
				Else
					vTotalStr = vTotalStr + "; " + cmFormatSum(vTotal.Sum - vTotal.DiscountSum - vTotal.CommissionSum, pRef.FolioCurrency, "NZ=---");
				EndIf;
			EndDo;
		Else
			For Each vTotal In vSrv Do
				If IsBlankString(vTotalStr) Then
					vTotalStr = cmFormatSum(vTotal.Sum - vTotal.DiscountSum, pRef.FolioCurrency, "NZ=---");
				Else
					vTotalStr = vTotalStr + "; " + cmFormatSum(vTotal.Sum - vTotal.DiscountSum, pRef.FolioCurrency, "NZ=---");
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	Return vTotalStr;
EndFunction // CalculateGuestGroupResourcesRowServices

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupTableBoxRefreshRequestProcessing()
	// Save group changes if any
	Totals(Commands.Totals);
EndProcedure // GuestGroupTableBoxRefreshRequestProcessing

// -----------------------------------------------------------------------------
&AtServer
Procedure FillTotalColumn()
	For Each vRow In GuestGroupTableBox.GetItems() Do
		vRow.RowTotals = CalculateGuestGroupTableBoxRowServices(?(vRow.Document.IsEmpty(), GuestGroupTableBox.GetItems().Get(0).Document, vRow.Document), ?(vRow.Document.IsEmpty(), Undefined, vRow));
	EndDo;
	For Each vRow In GuestGroupResources Do
		vRow.RowTotals = CalculateGuestGroupResourcesRowServices(vRow.Document);
	EndDo;
EndProcedure // FillTotalColumn

// -----------------------------------------------------------------------------
&AtServer
Function GetCustomerRoomRate()
	vRR = SessionParameters.CurrentHotel.RoomRate;
	If ValueIsFilled(Object.Customer) Then
		If ValueIsFilled(Object.Customer.RoomRate) Then
			vRR = Object.Customer.RoomRate;
		EndIf;
	EndIf;
	Return vRR;
EndFunction // GetCustomerRoomRate

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupTableBoxOnChange(pItem)
	If Deleted = False Then
		If pItem.CurrentData <> Undefined Then
			If pItem.CurrentData.LineNumber = 0 Then
				GGTableCount = GuestGroupTableBox.GetItems().Count();
				pItem.CurrentData.IsChanged = True;
				pItem.CurrentData.Picture = 12;
				pItem.CurrentData.Hotel = Object.Owner;
				If GGTableCount>1 Then
					vFirstInGroup = GuestGroupTableBox.GetItems().Get(0);
					pItem.CurrentData.LineNumber = GuestGroupTableBox.GetItems().Get(GGTableCount-2).LineNumber + 1;
					pItem.CurrentData.RoomType = vFirstInGroup.RoomType;
					pItem.CurrentData.RoomRate = vFirstInGroup.RoomRate;
					pItem.CurrentData.RoomRateServiceGroup = ?(ValueIsFilled(pItem.CurrentData.RoomRate), tcOnServer.cmGetAttributeByRef(pItem.CurrentData.RoomRate, "RoomRateServiceGroup"), tcOnServer.cmGetCatalogItemRefByCode("ServiceGroups",,True));
				Else
					pItem.CurrentData.RoomRate = GetCustomerRoomRate();
					pItem.CurrentData.RoomRateServiceGroup = ?(ValueIsFilled(pItem.CurrentData.RoomRate), tcOnServer.cmGetAttributeByRef(pItem.CurrentData.RoomRate, "RoomRateServiceGroup"), tcOnServer.cmGetCatalogItemRefByCode("ServiceGroups",,True));
					pItem.CurrentData.LineNumber = 1;
				EndIf;
				pItem.CurrentData.GuestGroup = Object.Ref;
				pItem.CurrentData.Customer = Object.Customer;
				pItem.CurrentData.CheckInDate = ?(ValueIsFilled(Object.CheckInDate), Object.CheckInDate, CurrentDate()+86400);
				pItem.CurrentData.Duration = ?(ValueIsFilled(Object.Duration), Object.Duration, tcOnServer.cmGetCurrentHotelAttribute("Duration"));
				pItem.CurrentData.CheckOutDate = ?(ValueIsFilled(Object.CheckOutDate), Object.CheckOutDate, pItem.CurrentData.CheckInDate + 86400*pItem.CurrentData.Duration);
				pItem.CurrentData.AccommodationType = tcOnServer.cmGetCurrentHotelAttribute("AccommodationType");
				pItem.CurrentData.NumberOfPersons = 1;
				pItem.CurrentData.RoomQuantity = 1;
				pItem.CurrentData.ReservationStatus = ?(ValueIsFilled(Object.Status) And TypeOf(Object.Status) = Type("CatalogRef.ReservationStatuses"), Object.Status, tcOnServer.cmGetCurrentHotelAttribute("NewReservationStatus"));
				GuestGroupTableBoxCheckInDateOnChange(Items.GuestGroupTableBoxCheckInDate);
				GuestGroupTableBoxCheckOutDateOnChange(Items.GuestGroupTableBoxCheckOutDate);
			Else
				pItem.CurrentData.IsChanged = True;
				If ValueIsFilled(pItem.CurrentData.Document) Then
					// Fill picture attribute
					pItem.CurrentData.Picture = GetPictureNumber(pItem.CurrentData.Document);
				EndIf;
			EndIf;
		EndIf;
	Else
		Deleted = False;
	EndIf;
EndProcedure // GuestGroupTableBoxOnChange

// -----------------------------------------------------------------------------
&AtServer
Function GetPictureNumber(pReservation)
	If pReservation.DeletionMark Then
		If pReservation.Posted Then
			Return 17;
		Else
			Return 15;
		EndIf;
	Else
		If pReservation.Posted Then
			Return 14;
		Else
			Return 12;
		EndIf;
	EndIf;
EndFunction // GetPictureNumber

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupTableBoxCheckInDateOnChange(pItem)
	If ValueIsFilled(pItem.Parent.CurrentData.CheckOutDate) Then
		If pItem.Parent.CurrentData.CheckOutDate < pItem.Parent.CurrentData.CheckInDate Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("ru='Ошибка выбора даты'; en='Failed to choose the date'"));
			pItem.Parent.CurrentData.CheckInDate = pItem.Parent.CurrentData.CheckOutDate - 86400;
			pItem.Parent.CurrentData.CheckInTime = pItem.Parent.CurrentData.CheckInDate;
			pItem.Parent.CurrentData.Duration = 1;
		Else
			pItem.Parent.CurrentData.CheckInTime = pItem.Parent.CurrentData.CheckInDate;
			pItem.Parent.CurrentData.CheckInDate = pItem.Parent.CurrentData.CheckOutDate - 86400;
			pItem.Parent.CurrentData.Duration = Round((pItem.Parent.CurrentData.CheckOutDate - pItem.Parent.CurrentData.CheckInDate)/86400);
		EndIf;
	ElsIf ValueIsFilled(pItem.Parent.CurrentData.Duration) Then
		pItem.Parent.CurrentData.CheckInTime = pItem.Parent.CurrentData.CheckInDate;
		pItem.Parent.CurrentData.CheckOutDate = pItem.Parent.CurrentData.CheckInDate + 86400*pItem.Parent.CurrentData.Duration;
		pItem.Parent.CurrentData.CheckOutTime = pItem.Parent.CurrentData.CheckInTime + 86400*pItem.Parent.CurrentData.Duration;
	EndIf;
EndProcedure // GuestGroupTableBoxCheckInDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupTableBoxCheckOutDateOnChange(pItem)
	If ValueIsFilled(pItem.Parent.CurrentData.CheckInDate) Then
		If pItem.Parent.CurrentData.CheckOutDate < pItem.Parent.CurrentData.CheckInDate Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("ru='Ошибка выбора даты'; en='Failed to choose the date'"));
			pItem.Parent.CurrentData.CheckOutTime = pItem.Parent.CurrentData.CheckOutDate;
			pItem.Parent.CurrentData.CheckOutDate = pItem.Parent.CurrentData.CheckInDate + 86400;
			pItem.Parent.CurrentData.Duration = 1;
		Else
			pItem.Parent.CurrentData.CheckOutTime = pItem.Parent.CurrentData.CheckOutDate;
			pItem.Parent.CurrentData.CheckOutDate = pItem.Parent.CurrentData.CheckInDate + 86400;
			pItem.Parent.CurrentData.Duration = Round((pItem.Parent.CurrentData.CheckOutDate - pItem.Parent.CurrentData.CheckInDate) / 86400);
		EndIf;
	ElsIf ValueIsFilled(pItem.Parent.CurrentData.Duration) Then
		pItem.Parent.CurrentData.CheckOutTime = pItem.Parent.CurrentData.CheckOutDate;
		pItem.Parent.CurrentData.CheckInDate = pItem.Parent.CurrentData.CheckOutDate - 86400 * pItem.Parent.CurrentData.Duration;
		pItem.Parent.CurrentData.CheckInTime = pItem.Parent.CurrentData.CheckOutTime - 86400 * pItem.Parent.CurrentData.Duration;
	EndIf;
EndProcedure // GuestGroupTableBoxCheckOutDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupTableBoxBeforeDeleteRow(pItem, pCancel)
	If ValueIsFilled(pItem.CurrentData.Document) Then
		pCancel = True;
	Else
		Deleted = True;
	EndIf;
EndProcedure // GuestGroupTableBoxBeforeDeleteRow

// -----------------------------------------------------------------------------
&AtServer
Function GetRoomRatesTable(pCustomer)
	vRRs = pCustomer.RoomRates.UnloadColumn("RoomRate");
	return vRRs;
EndFunction // GetRoomRatesTable

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupTableBoxRoomRateStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vFrm = GetForm("Catalog.RoomRates.ChoiceForm", , pItem);
	// Set up filters
	vFrm.SelHotel = tcOnServer.cmGetCurrentHotelAttribute();
	If ValueIsFilled(pItem.Parent.CurrentData.Customer) Then
		vFrm.SelRoomRates.LoadValues(GetRoomRatesTable(pItem.Parent.CurrentData.Customer));
	EndIf; 
	// Open form
	vFrm.Open();
EndProcedure // GuestGroupTableBoxRoomRateStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupTableBoxSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	If ValueIsFilled(pItem.CurrentData.MainRef) Then
		// Save group changes if any
		If Modified Then
			Write();
		EndIf;
		// Open group document
		vCurData = Items.GuestGroupTableBox.CurrentData;
		If vCurData <> Undefined Then
			vMainAccommodationRef = vCurData.MainRef;
			If TypeOf(vMainAccommodationRef) = Type("DocumentRef.Accommodation") Then
				OpenForm("Document.Accommodation.Form.tcDocumentForm", New Structure("Key", vMainAccommodationRef));
			ElsIf TypeOf(vMainAccommodationRef) = Type("DocumentRef.Reservation") Then
				OpenForm("Document.Reservation.Form.tcDocumentForm", New Structure("Key", vMainAccommodationRef));
			EndIf;
		EndIf;
	EndIf;
EndProcedure // GuestGroupTableBoxSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure EditReservation(pCommand)
	vItem = Items.GuestGroupTableBox;
	If ValueIsFilled(vItem.CurrentData.MainRef) Then
		// Save group changes if any
		If Modified Then
			If Not Write() Then
				Return;
			EndIf;
		EndIf;
		// Open group document
		vMainAccommodationRef = vItem.CurrentData.MainRef;
		If TypeOf(vMainAccommodationRef) = Type("DocumentRef.Accommodation") Then
			OpenForm("Document.Accommodation.Form.tcDocumentForm", New Structure("Key", vMainAccommodationRef));
		ElsIf TypeOf(vMainAccommodationRef) = Type("DocumentRef.Reservation") Then
			OpenForm("Document.Reservation.Form.tcDocumentForm", New Structure("Key", vMainAccommodationRef));
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupTableBoxRoomChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	If TypeOf(pSelectedValue) = Type("CatalogRef.Rooms") Then
		pItem.Parent.CurrentData.RoomType = tcOnServer.cmGetAttributeByRef(pSelectedValue, "RoomType");
	EndIf;
EndProcedure // GuestGroupTableBoxRoomChoiceProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupTableBoxRoomStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vFrm = OpenForm("Catalog.Rooms.ChoiceForm", , pItem);
	vFrm.Open();
EndProcedure // GuestGroupTableBoxRoomStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure GroupAnnulation(pCommand)
	// Save group changes if any
	If Modified Then
		If Not Write() Then
			Return;
		EndIf;
	EndIf;
	vRefList = GetGroupDocumentsList(True);
	If vRefList.Count() = 0 Then
		Return;
	EndIf;
	vStepRate = Round(80/vRefList.Count());
	vStep = 0;
	For Each vRefListRow In vRefList Do
		vDocNumber = tcOnServer.cmGetAttributeByRef(vRefListRow.Value, "Number");
		vResult = SetAnnulationStatus(vRefListRow.Value);
		If ValueIsFilled(vResult) Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Document: ';ru='Документ: ';de='Dokument: '") + vDocNumber + NStr("en=' - Cancelation error!';ru=' - Ошибка аннулирования';de=' - Stornierungsfehler'")+Chars.LF+vResult);
		EndIf;
		vStep = vStep + vStepRate;
	EndDo;
	FillGroupList();
	Read();
	Notify("Document.Reservation.Write", vRefListRow.Value);
EndProcedure // GroupAnnulation

// -----------------------------------------------------------------------------
&AtServer
Function SetAnnulationStatus(pRef)
	Try
		If TypeOf(pRef) = Type("DocumentRef.Reservation") Then
			vObject = pRef.GetObject();
			vObject.ReservationStatus = cmGetReservationAnnulationStatus(pRef);
			vObject.pmSetDoCharging();
			vObject.Write(DocumentWriteMode.Posting);
			vObject.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
		EndIf;
	Except
		Return ErrorDescription();
	EndTry;
	Return "";
EndFunction // SetAnnulationStatus

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure CreateGroupProformaInvoice(pCommand)
	// Save group changes if any
	If Modified Then
		If Not Write() Then
			Return;
		EndIf;
	EndIf;
	vForm = GetForm("Document.ProformaInvoice.ObjectForm");
	vFormData = vForm.Object;
	NewGroupProformaInvoice(vFormData, True);
	CopyFormData(vFormData, vForm.Object);
	vForm.Open();
EndProcedure // CreateGroupProformaInvoice

// ------------------------------------------------------------------------------------------------
&AtServer
Function NewGroupProformaInvoice(pFormData,pThinClient)
	If pThinClient Then
		vInvObj = FormDataToValue(pFormData, Type("DocumentObject.ProformaInvoice"));
		vInvObj.Fill(Object.ClientDoc);
		vInvObj.ParentDoc = Undefined;
		vInvObj.Fill(Object.Ref);
		ValueToFormData(vInvObj, pFormData);
	Else
		vObj = FormAttributeToValue("Object");
		vInvObj = Documents.ProformaInvoice.CreateDocument();
		vInvObj.Fill(Object.ClientDoc);
		vInvObj.ParentDoc = Undefined;
		vInvObj.Fill(vObj.Ref);
		Return vInvObj;
	EndIf
EndFunction // NewGroupProformaInvoice

// ------------------------------------------------------------------------------------------------
&AtServerNoContext
Function DoCreateInitialBlockReservations(pStatus)
	If (pStatus.IsActive Or pStatus.IsPreliminary) And 
	   (TypeOf(pStatus) <> Type("CatalogRef.ReservationStatuses") Or TypeOf(pStatus) = Type("CatalogRef.ReservationStatuses") And Not pStatus.DoNotCreateReservationsInBlock) Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // DoCreateInitialBlockReservations

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure WhoPaysOnChange(pItem)
	vIsNeedToOpenForm = PayerOnChangeAtServer();
	If vIsNeedToOpenForm Then
		If Object.Payer = PredefinedValue("Enum.WhoPays.Agent") Then 
			vFrm = GetForm("Catalog.Customers.ChoiceForm", New Structure("CurrentRow, ChoiceMode", Object.Agent, True), Items.Agent);
		Else
			vFrm = GetForm("Catalog.Customers.ChoiceForm", New Structure("CurrentRow, ChoiceMode", Object.Customer, True), Items.Customer);
		EndIf;
		vFrm.CloseOnOwnerClose = True;
		vFrm.CloseOnChoice = True;
		vFrm.Open();
		Modified = True;
	EndIf;
	CustomerWasChanged = True;
	Modified = True;
EndProcedure // WhoPaysOnChange

// ------------------------------------------------------------------------------------------------
&AtServer
Function PayerOnChangeAtServer()
	vReturn = False;
	If Object.Payer = Enums.WhoPays.Guest Then
		Object.PlannedPaymentMethod = Object.Owner.PlannedPaymentMethod;
		PlannedPaymentMethodOnChangeAtServer();
	ElsIf Object.Payer = Enums.WhoPays.Customer Then
		If Not ValueIsFilled(Object.Customer) Then
			vReturn = True;
		Else
			CustomerOnChangeAtServer(, True, Object.Payer);
			// Fill customer for group folios
			FillCustomerForGroupFolios();
		EndIf;
	ElsIf Object.Payer = Enums.WhoPays.Agent Then
		If Not ValueIsFilled(Object.Agent) Then
			vReturn = True;
		Else
			AgentOnChangeAtServer(, Object.Payer);
			// Fill customer for group folios
			FillCustomerForGroupFolios();
		EndIf;
	EndIf;
	Return vReturn;
EndFunction // PayerOnChangeAtServer

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure RemoveChargingRules(pObj = Undefined)
	If pObj <> Undefined Then
		vObj = pObj;
	Else
		vObj = FormAttributeToValue("Object");
	EndIf;
	vObj.ChargingRules.Clear();
	// Set planned payment method from the first charging rule
	vObj.Payer = vObj.pmSetPlannedPaymentMethod(vObj.PlannedPaymentMethod);
	If pObj = Undefined Then
		ValueToFormAttribute(vObj, "Object");
		// Fill block totals
		FillAvailableRoomsAtServer();
	EndIf;
EndProcedure // RemoveChargingRules

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure AddBankTransferCR(pAdd = False)
	// Get object value
	vObj = FormAttributeToValue("Object");
	// Add bank transfer charging rule
	vObj.pmAddBankTransferChargingRule(pAdd);
	// Set planned payment method from the first charging rule
	vObj.Payer = vObj.pmSetPlannedPaymentMethod(vObj.PlannedPaymentMethod);
	// Set object value
	ValueToFormAttribute(vObj, "Object");
	// Fill block totals
	FillAvailableRoomsAtServer();
	// Fill group folio label
	FillGroupFolioAttribute();
EndProcedure // AddBankTransferCR

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure PlannedPaymentMethodOnChange(pItem)
	PlannedPaymentMethodOnChangeAtServer();
	CustomerWasChanged = True;
	Modified = True;
	Notify("Subsystem.Accounts.Changed", Object.Ref);
EndProcedure // PlannedPaymentMethodOnChange

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure PlannedPaymentMethodOnChangeAtServer()
	If ValueIsFilled(Object.PlannedPaymentMethod) Then
		vFolioToUpdate = Undefined;
		vChargingRules = Object.ChargingRules.Unload();
		For Each vCRRow In vChargingRules Do
			// Set planned payment method to the folio from the first charging rule
			vFolioToUpdate = Undefined;
			If ValueIsFilled(vCRRow.ChargingFolio) Then
				vFolioToUpdate = vCRRow.ChargingFolio;
				If vFolioToUpdate.PaymentMethod <> Object.PlannedPaymentMethod Then
					vFolioObj = vFolioToUpdate.GetObject();
					vFolioObj.PaymentMethod = Object.PlannedPaymentMethod;
					vFolioObj.Write(DocumentWriteMode.Write);
				Endif;
			EndIf;
		EndDo;
	EndIf;
	FillGroupFolioAttribute();
EndProcedure // PlannedPaymentMethodOnChangeAtServer

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure CustomerOnChange(pItem)
	CustomerOnChangeAtServer();
EndProcedure // CustomerOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ContractOnChange(pItem)
	ContractOnChangeAtServer();
EndProcedure // ContractOnChange

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure CustomerOnChangeAtServer(pObj = Undefined, pDoNotSetDefaultCOntract = False, pPayer = Undefined)
	If pObj <> Undefined Then
		vObj = pObj;
	Else
		vObj = FormAttributeToValue("Object");
	EndIf;
	vCustomer = vObj.Customer;
	vContract = Undefined;
	If ValueIsFilled(vCustomer) Then
		// Default contract
		If Not pDoNotSetDefaultContract Then
			vContract = Undefined;
			If ValueIsFilled(vCustomer.Contract) Then
				vContract = vCustomer.Contract;
			Else
				vValidContracts = cmGetListOfValidContracts(vObj.Customer, vObj.CheckInDate, vObj.CheckOutDate, vObj.CreateDate);
				If vValidContracts.Count() = 1 Then
					vContract = vValidContracts.Get(0).Value;
				EndIf;
			EndIf;
			If ValueIsFilled(vContract) Then
				vObj.Contract = vContract;
			EndIf;
		EndIf;
		// Planned payment method
		If Not ValueIsFilled(pPayer) Then
			If ValueIsFilled(vContract) And ValueIsFilled(vContract.PlannedPaymentMethod) Then
				vObj.PlannedPaymentMethod = vContract.PlannedPaymentMethod;
			ElsIf ValueIsFilled(vCustomer.PlannedPaymentMethod) Then
				vObj.PlannedPaymentMethod = vCustomer.PlannedPaymentMethod;
			EndIf;
		Else
			If pPayer = Enums.WhoPays.Customer Then
				vObj.PlannedPaymentMethod = vObj.Owner.PaymentMethodForCustomerPayments;
			Else
				vObj.PlannedPaymentMethod = vObj.Owner.PlannedPaymentMethod;
			EndIf;
		EndIf;
		// Fill agent
		If ValueIsFilled(vContract) Then
			If ValueIsFilled(vContract.Agent) Then
				vObj.Agent = vContract.Agent;
			ElsIf ValueIsFilled(vContract.AgentCommissionType) Or vContract.AgentCommission <> 0 Then
				vObj.Agent = vCustomer;
			Endif;
		Else
			If ValueIsFilled(vCustomer.Agent) Then
				vObj.Agent = vCustomer.Agent;
			ElsIf ValueIsFilled(vCustomer.AgentCommissionType) Or vCustomer.AgentCommission <> 0 Then
				vObj.Agent = vCustomer;
			EndIf;
		EndIf;
		// Fill source
		If ValueIsFilled(vContract) Then
			If ValueIsFilled(vContract.SourceOfBusiness) Then
				vObj.SourceOfBusiness = vContract.SourceOfBusiness;
			EndIf;
		Else
			If ValueIsFilled(vCustomer.SourceOfBusiness) Then
				vObj.SourceOfBusiness = vCustomer.SourceOfBusiness;
			EndIf;
		EndIf;
		// Fill market code
		If ValueIsFilled(vContract) Then
			If ValueIsFilled(vContract.MarketingCode) Then
				vObj.MarketingCode = vContract.MarketingCode;
			EndIf;
		Else
			If ValueIsFilled(vCustomer.MarketingCode) Then
				vObj.MarketingCode = vCustomer.MarketingCode;
			EndIf;
		EndIf;
		// Fill client type
		If ValueIsFilled(vContract) Then
			If ValueIsFilled(vContract.ClientType) Then
				vObj.ClientType = vContract.ClientType;
			EndIf;
		Else
			If ValueIsFilled(vCustomer.ClientType) Then
				vObj.ClientType = vCustomer.ClientType;
			EndIf;
		EndIf;
		// Fill room rate
		If ValueIsFilled(vContract) Then
			If ValueIsFilled(vContract.RoomRate) Then
				vObj.RoomRate = vContract.RoomRate;
			EndIf;
		Else
			If ValueIsFilled(vCustomer.RoomRate) Then
				vObj.RoomRate = vCustomer.RoomRate;
			EndIf;
		EndIf;
		// Fill discount type
		If ValueIsFilled(vContract) Then
			If ValueIsFilled(vContract.DiscountType) Then
				vObj.DiscountType = vContract.DiscountType;
			EndIf;
		Else
			If ValueIsFilled(vCustomer.DiscountType) Then
				vObj.DiscountType = vCustomer.DiscountType;
			EndIf;
		EndIf;
		// Fill allotment
		If ValueIsFilled(vContract) Then
			If ValueIsFilled(vContract.RoomQuota) Then
				vObj.Allotment = vContract.RoomQuota;
			EndIf;
		EndIf;
	Else
		vObj.PlannedPaymentMethod = vObj.Owner.PlannedPaymentMethod;
	EndIf;
	Items.Agent.ToolTip = GetAgentConditionsAtServer(vObj.Agent, vObj.Contract);
	// Set payer
	If ValueIsFilled(vObj.PlannedPaymentMethod) And Not ValueIsFilled(pPayer) Then
		vObj.Payer = ?(vObj.PlannedPaymentMethod.IsByBankTransfer, Enums.WhoPays.Customer, Enums.WhoPays.Guest);
	EndIf;
	// Fill customer for group folios
	If Not pDoNotSetDefaultCOntract Then
		FillCustomerForGroupFolios(vObj);
	EndIf;
	// Copy data back to the form
	If pObj = Undefined Then
		ValueToFormAttribute(vObj, "Object");
		// Fill block totals
		FillAvailableRoomsAtServer();
		// Fill group folio label
		FillGroupFolioAttribute();
	EndIf;
	CustomerWasChanged = True;
EndProcedure // CustomerOnChangeAtServer

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure AgentOnChangeAtServer(pObj = Undefined, pPayer = Undefined)
	If pObj <> Undefined Then
		vObj = pObj;
	Else
		vObj = FormAttributeToValue("Object");
	EndIf;
	vAgent = vObj.Agent;
	If ValueIsFilled(vAgent) Then
		// Planned payment method
		If pPayer = Enums.WhoPays.Agent Then
			If ValueIsFilled(vAgent.PlannedPaymentMethod) Then
				vObj.PlannedPaymentMethod = vAgent.PlannedPaymentMethod;
			Else
				vObj.PlannedPaymentMethod = vObj.Owner.PaymentMethodForCustomerPayments;
			EndIf;
		EndIf;
		// Fill source
		If Not ValueIsFilled(vObj.SourceOfBusiness) Then
			If ValueIsFilled(vAgent.SourceOfBusiness) Then
				vObj.SourceOfBusiness = vAgent.SourceOfBusiness;
			EndIf;
		EndIf;
		// Fill market code
		If Not ValueIsFilled(vObj.MarketingCode) Then
			If ValueIsFilled(vAgent.MarketingCode) Then
				vObj.MarketingCode = vAgent.MarketingCode;
			EndIf;
		EndIf;
		// Fill client type
		If Not ValueIsFilled(vObj.ClientType) Then
			If ValueIsFilled(vAgent.ClientType) Then
				vObj.ClientType = vAgent.ClientType;
			EndIf;
		EndIf;
		// Fill room rate
		If Not ValueIsFilled(vObj.RoomRate) Then
			If ValueIsFilled(vAgent.RoomRate) Then
				vObj.RoomRate = vAgent.RoomRate;
			EndIf;
		EndIf;
		// Fill discount type
		If Not ValueIsFilled(vObj.DiscountType) Then
			If ValueIsFilled(vAgent.DiscountType) Then
				vObj.DiscountType = vAgent.DiscountType;
			EndIf;
		EndIf;
	Else
		vObj.PlannedPaymentMethod = vObj.Owner.PlannedPaymentMethod;
	EndIf;
	Items.Agent.ToolTip = GetAgentConditionsAtServer(vObj.Agent, vObj.Contract);
	// Set payer
	If ValueIsFilled(vObj.PlannedPaymentMethod) And Not ValueIsFilled(pPayer) Then
		vObj.Payer = ?(vObj.PlannedPaymentMethod.IsByBankTransfer, Enums.WhoPays.Customer, Enums.WhoPays.Guest);
	EndIf;
	// Copy data back to the form
	If pObj = Undefined Then
		ValueToFormAttribute(vObj, "Object");
		// Fill block totals
		FillAvailableRoomsAtServer();
		// Fill group folio label
		FillGroupFolioAttribute();
	EndIf;
	CustomerWasChanged = True;
EndProcedure // AgentOnChangeAtServer

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure FillCustomerForGroupFolios(pObj = Undefined)
	vObj = pObj;
	If pObj = Undefined Or TypeOf(pObj) = Type("FormDataStructure") Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	// Fill customer for group folios
	For Each vCRRow In vObj.ChargingRules Do
		If ValueIsFilled(vCRRow.ChargingFolio) Then
			vFolioToUpdate = vCRRow.ChargingFolio;
			If vFolioToUpdate.GuestGroup <> vObj.Ref Or
			   vFolioToUpdate.Customer <> vObj.Customer Or
			   vFolioToUpdate.Contract <> vObj.Contract Or
			   vFolioToUpdate.Agent <> vObj.Agent Or
			   vFolioToUpdate.PaymentMethod <> vObj.PlannedPaymentMethod Then
				vFolioObj = vFolioToUpdate.GetObject();
				If vFolioToUpdate.GuestGroup <> vObj.Ref Then
					vFolioObj.GuestGroup = vObj.Ref;
				EndIf;
				If vObj.Payer = Enums.WhoPays.Customer Then
					If vFolioToUpdate.Customer <> vObj.Customer And 
					  (vObj.IsNew() Or Not vObj.IsNew() And vObj.Ref.Customer = vFolioToUpdate.Customer) Then
						vFolioObj.Customer = vObj.Customer;
					EndIf;
					If vFolioToUpdate.Contract <> vObj.Contract And
					  (vObj.IsNew() Or Not vObj.IsNew() And vObj.Ref.Contract = vFolioToUpdate.Contract) Then
						vFolioObj.Contract = vObj.Contract;
					EndIf;
				ElsIf vObj.Payer = Enums.WhoPays.Agent Then
					If vFolioToUpdate.Customer <> vObj.Agent And 
					  (vObj.IsNew() Or Not vObj.IsNew() And vObj.Ref.Agent = vFolioToUpdate.Customer) Then
						vFolioObj.Customer = vObj.Agent;
					EndIf;
				EndIf;
				If vFolioToUpdate.Agent <> vObj.Agent And
				  (vObj.IsNew() Or Not vObj.IsNew() And vObj.Ref.Agent = vFolioToUpdate.Agent) Then
					vFolioObj.Agent = vObj.Agent;
				EndIf;
				If vFolioToUpdate.PaymentMethod <> vObj.PlannedPaymentMethod Then
					vFolioObj.PaymentMethod = vObj.PlannedPaymentMethod;
				EndIf;
				vFolioObj.Write(DocumentWriteMode.Write);
			EndIf;
		EndIf;
	EndDo;
EndProcedure //FillCustomerForGroupFolios

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure ContractOnChangeAtServer()
	vUseParameterObject = True;
	vObj = FormAttributeToValue("Object");
	If ValueIsFilled(vObj.Contract) Then
		// Planned payment method
		If ValueIsFilled(vObj.Contract.PlannedPaymentMethod) Then
			vObj.PlannedPaymentMethod = vObj.Contract.PlannedPaymentMethod;
		EndIf;
		// Set payer
		If ValueIsFilled(vObj.PlannedPaymentMethod) Then
			vObj.Payer = ?(vObj.PlannedPaymentMethod.IsByBankTransfer, Enums.WhoPays.Customer, Enums.WhoPays.Guest);
		EndIf;
		// Fill agent
		vContract = vObj.Contract;
		If Not vContract.IsSubagent Then
			If ValueIsFilled(vContract.Agent) Then
				vObj.Agent = vContract.Agent;
			ElsIf ValueIsFilled(vContract.AgentCommissionType) Or vContract.AgentCommission <> 0 Then
				vObj.Agent = vContract.Owner;
			EndIf;
		Else
			vAgent = vContract.Owner;
			vObj.Agent = vAgent;
			If ValueIsFilled(vAgent.Agent) Then
				vObj.Agent = vAgent.Agent;
			EndIf;
		EndIf;
		Items.Agent.ToolTip = GetAgentConditionsAtServer(vObj.Agent, vObj.Contract);
	Else
		CustomerOnChangeAtServer(vObj, True);
	EndIf;
	// Fill customer for group folios
	FillCustomerForGroupFolios(vObj);
	// Copy object back to form
	ValueToFormAttribute(vObj, "Object");
	// Fill block totals
	FillAvailableRoomsAtServer();
	// Fill group folio label
	FillGroupFolioAttribute();
	CustomerWasChanged = True;
EndProcedure // ContractOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AgentOnChange(pItem)
	CustomerWasChanged = True;
	Items.Agent.ToolTip = GetAgentConditionsAtServer(Object.Agent, Object.Contract);
	// Fill customer for group folios
	FillCustomerForGroupFolios();
EndProcedure // AgentOnChange

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetAgentConditionsAtServer(pAgent, pContract)
	vStr = "";
	vCondSource = pAgent;
	If ValueIsFilled(pContract) And pContract.Owner = pAgent And (ValueIsFilled(pContract.AgentCommissionType) Or pContract.AgentCommission <> 0) Then
		vCondSource = pContract;
	EndIf;
	If ValueIsFilled(vCondSource) Then
		If Not ValueIsFilled(vCondSource.AgentCommissionType) Or vCondSource.AgentCommissionType = Enums.AgentCommissionTypes.Percent Then
			vStr = Format(vCondSource.AgentCommission, "NFD=1; NG=") + "%" + " " + ?(ValueIsFilled(vCondSource.AgentCommissionServiceGroup), NStr("en='for '; ru='на '; de='für '") + Lower(TrimAll(vCondSource.AgentCommissionServiceGroup)), NStr("en='for all services'; ru='на все услуги'; de='für alle Dienste'"));
		ElsIf vCondSource.AgentCommissionType = Enums.AgentCommissionTypes.FirstDayPercent Then
			vStr = Format(vCondSource.AgentCommission, "NFD=1; NG=") + NStr("en='% for the first day'; ru='% за первый день'; de='% für den ersten Tag'") + " " + ?(ValueIsFilled(vCondSource.AgentCommissionServiceGroup), NStr("en='for '; ru='на '; de='für '") + Lower(TrimAll(vCondSource.AgentCommissionServiceGroup)), NStr("en='for all services'; ru='на все услуги'; de='für alle Dienste'"));
		Else
			vStr = cmFormatSum(vCondSource.AgentCommission, vCondSource.AccountingCurrency) + " " + lower(TrimAll(vCondSource.AgentCommissionType));
		EndIf;
	EndIf;
	Return vStr;
EndFunction // GetAgentConditionsAtServer

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure FillGroupFolioAttribute()
	vChargingRules = Object.ChargingRules.Unload();
	GroupFolio = Undefined;
	If vChargingRules.Count() > 0 Then
		vCRRow = vChargingRules.Get(0);
		If ValueIsFilled(vCRRow.ChargingFolio) Then
			GroupFolio = vCRRow.ChargingFolio;
		EndIf;
	EndIf;
EndProcedure // FillGroupFolioAttribute

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure OpenProformaInvoiceList(Command)
	OpenForm("Document.ProformaInvoice.ListForm", New Structure("SelGuestGroup, SelHotel", Object.Ref, Object.Owner), ThisObject);
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure OpenInvoiceList(Command)
	OpenForm("Document.Settlement.ListForm", New Structure("SelGuestGroup, SelHotel", Object.Ref, Object.Owner), ThisObject);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenCustomerAccountsList(Command)
	// Save group changes if any
	If Modified Then
		If Not Write() Then
			Return;
		EndIf;
	EndIf;
	OpenForm("DocumentJournal.CustomerAccountsJournal.ListForm", New Structure("Filter", New Structure("GuestGroup, Hotel", Object.Ref, Object.Owner)), ThisObject);
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure OpenInHouseGuests(Command)
	OpenForm("Document.Accommodation.Form.mcAccommodationListForm", New Structure("SelGuestGroup, SelHotel", Object.Ref, Object.Owner), ThisObject);	
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure OpenReservations(Command)
	OpenForm("Document.Reservation.Form.mcReservationListForm", New Structure("SelGuestGroup, SelHotel", Object.Ref, Object.Owner));	
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtServer
Function RecalculateGroupDocumentsAtServer(pRecalculateDocuments = False, pUpdateCustomer = False, pUpdateGuests = False, pUpdateRemarks = False)
	vError = "";
	If Not pUpdateCustomer And Not pRecalculateDocuments And Not pUpdateGuests And Not pUpdateRemarks Then
		Return vError;
	EndIf;
	vRefList = GetGroupDocumentsList(True);
	If vRefList.Count() = 0 Then
		Return vError;
	EndIf;
	For Each vRefListRow In vRefList Do
		Try
			vObj = vRefListRow.Value.GetObject();
			If Not vObj.DeletionMark Then
				vCurDocData = Undefined;
				If pUpdateGuests Or pUpdateRemarks Then
					For Each vMainDocData In GuestGroupTableBox.GetItems() Do
						If vMainDocData.Document = vObj.Ref Then
							vCurDocData = vMainDocData;
							Break;
						EndIf;
						vChildDocs = vMainDocData.GetItems();
						For Each vChildDocData In vChildDocs Do
							If vChildDocData.Document = vObj.Ref Then
								vCurDocData = vChildDocData;
								Break;
							EndIf;
						EndDo;
						If vCurDocData <> Undefined Then
							Break;
						EndIf;
					EndDo;
				EndIf;
				If pUpdateGuests Then
					If vCurDocData <> Undefined And vCurDocData.RoomQuantity = 1 Then
						If vCurDocData.Guest <> vObj.Guest Or lower(TrimAll(vCurDocData.GuestFullName)) <> lower(TrimAll(vObj.GuestFullName)) Then
							If ValueIsFilled(vCurDocData.Guest) Then
								vObj.Guest = vCurDocData.Guest;
							ElsIf Not IsBlankString(vCurDocData.GuestFullName) Then
								vSelGuest = TrimAll(vCurDocData.GuestFullName);
								// Create guest object
								vGuestObj = Catalogs.Clients.CreateItem();
								// Fill attributes with default values
								vGuestObj.pmFillAttributesWithDefaultValues();
								// Get guest last name, first name and second name
								vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
								vLastNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
								vGuestObj.LastName = Title(Left(TrimAll(vSelGuest), vLastNameLastCharNumber));
								If vLastNameLastCharNumber<>StrLen(vSelGuest) Then
									vSelGuest = Mid(TrimAll(vSelGuest), vLastNameLastCharNumber+2, StrLen(vSelGuest));
									vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
									vFirstNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
									vGuestObj.FirstName = Title(Left(TrimAll(vSelGuest), vFirstNameLastCharNumber));
									If vFirstNameLastCharNumber<>StrLen(vSelGuest) Then
										vSelGuest = Mid(TrimAll(vSelGuest), vFirstNameLastCharNumber+2, StrLen(vSelGuest));
										vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
										vSecondNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
										vGuestObj.SecondName = Title(Left(TrimAll(vSelGuest), vSecondNameLastCharNumber));
									EndIf;
								EndIf; 
								vGuestObj.Sex = GetSexByName(vGuestObj);
								vGuestObj.Write();
								vGuestObj.pmBindClientToItsChargingRules();
								vGuestObj.pmWriteToClientChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
								UserWorkHistory.Add(vGuestObj.Ref);
								vObj.Guest = vGuestObj.Ref;
								If vObj.Guest.ChargingRules.Count() > 0 Then
									vObj.pmLoadChargingRules(vObj.Guest);
								EndIf;
								// Fill table box row columns back
								vCurDocData.Guest = vGuestObj.Ref;
								vCurDocData.GuestFullName = vGuestObj.FullName;
							Else
								vObj.Guest = Catalogs.Clients.EmptyRef();
							EndIf;
						EndIf;
					EndIf;
				EndIf;
				If pUpdateRemarks Then
					If vCurDocData <> Undefined Then
						If TrimR(vCurDocData.Remarks) <> TrimR(vObj.Remarks) Then
							vObj.Remarks = TrimR(vCurDocData.Remarks);
						EndIf;
						If TrimR(vCurDocData.HousekeepingRemarks) <> TrimR(vObj.HousekeepingRemarks) Then
							vObj.HousekeepingRemarks = TrimR(vCurDocData.HousekeepingRemarks);
						EndIf;
					EndIf;
				EndIf;
				If pUpdateCustomer And Object.OneCustomerPerGuestGroup Then
					If ValueIsFilled(Object.Contract) Then
						vOldCustomer = vObj.Customer;
						vOldContract = vObj.Contract;
						vOldAgent = vObj.Agent;
						// Set contract and customer
						vObj.Customer = Object.Contract.Owner;
						vObj.Contract = Object.Contract;
						// Agent commission
						If ValueIsFilled(vObj.Customer) And ValueIsFilled(vObj.Contract.AgentCommissionType) Then
							vObjContract = vObj.Contract;
							If vObjContract.IsSubagent Then
								vObjAgent = vObj.Customer;
								vObj.Agent = vObjAgent;
								If ValueIsFilled(vObjAgent.Agent) Then
									vObj.Agent = vObjAgent.Agent;
								EndIf;
								If vObjAgent.AgentCommission <> 0 Then
									vObj.AgentCommission = vObjAgent.AgentCommission;
									vObj.AgentCommissionType = vObjAgent.AgentCommissionType;
									vObj.AgentCommissionServiceGroup = vObjAgent.AgentCommissionServiceGroup;
								EndIf;
							Else
								vObj.Agent = vObjContract.Agent;
								If Not ValueIsFilled(vObj.Agent) Then
									vObj.Agent = vObj.Customer;
								EndIf;
								If vObjContract.AgentCommission <> 0 Then
									vObj.AgentCommission = vObjContract.AgentCommission;
									vObj.AgentCommissionType = vObjContract.AgentCommissionType;
									vObj.AgentCommissionServiceGroup = vObjContract.AgentCommissionServiceGroup;
								EndIf;
							EndIf;
						EndIf;
						If Not ValueIsFilled(vObj.Agent) Then
							vObj.AgentCommission = 0;
							vObj.AgentCommissionType = Undefined;
							vObj.AgentCommissionServiceGroup = Catalogs.ServiceGroups.EmptyRef();
						EndIf;
						// Contract company
						If ValueIsFilled(vObj.Contract.Company) Then
							vObj.Company = vObj.Contract.Company;
						EndIf;
						// Marketing code
						If ValueIsFilled(vObj.Contract.MarketingCode) Then
							vObj.MarketingCode = vObj.Contract.MarketingCode;
							vObj.MarketingCodeConfirmationText = "";
						EndIf;
						// Source of business
						If ValueIsFilled(vObj.Contract.SourceOfBusiness) Then
							vObj.SourceOfBusiness = vObj.Contract.SourceOfBusiness;
						EndIf;
						// Client type
						If ValueIsFilled(vObj.Contract.ClientType) Then
							vObj.ClientType = vObj.Contract.ClientType;
							vObj.ClientTypeConfirmationText = vObj.Contract.ClientTypeConfirmationText;
						EndIf;
						// Customer remarks
						If Not IsBlankString(vObj.Customer.Remarks) And vObj.Customer.CopyRemarksToDocuments Then
							rIsHousekeepingRemarks = False;
							vCustRemarks = TrimAll(vObj.Customer.Remarks);
							vRemarks = cmGetRemarks(vCustRemarks, vObj.RoomType, rIsHousekeepingRemarks);
							If rIsHousekeepingRemarks Then
								vObj.HousekeepingRemarks = TrimAll(vRemarks + Chars.LF + TrimAll(vObj.HousekeepingRemarks));
							Else
								vObj.Remarks = TrimAll(vRemarks + Chars.LF + TrimAll(vObj.Remarks));
							EndIf;
						EndIf;
						// Do not print rate
						If vObj.Contract.DoNotPrintRate Then
							vObj.DoNotPrintRate = True;
						EndIf;
						// Meal board term
						If ValueIsFilled(vObj.Contract.MealBoardTerm) Then
							vObj.ServicePackage = vObj.Contract.MealBoardTerm;
						EndIf;
						// Load charging rules
						If Object.Payer = Enums.WhoPays.Customer Then
							vObj.pmAddBankTransferChargingRule(, ?(ValueIsFilled(Object.PlannedPaymentMethod), Object.PlannedPaymentMethod, Undefined));
						ElsIf Object.Payer = Enums.WhoPays.Guest Then
							vObj.pmRemoveChargingRules(?(ValueIsFilled(vOldContract), vOldContract, vOldCustomer));
						EndIf;
					ElsIf ValueIsFilled(Object.Customer) Then
						vOldCustomer = vObj.Customer;
						vOldContract = vObj.Contract;
						vOldAgent = vObj.Agent;
						// Set customer
						vObj.Customer = Object.Customer;
						vObj.Contract = Object.Contract;
						// Customer type
						vObj.CustomerType = vObj.Customer.CustomerType;
						// Agent
						If ValueIsFilled(vObj.Customer.AgentCommissionType) Then
							vObj.Agent = vObj.Customer.Agent;
							If Not ValueIsFilled(vObj.Agent) Then
								vObj.Agent = vObj.Customer;
							EndIf;
							vObj.AgentCommission = vObj.Agent.AgentCommission;
							vObj.AgentCommissionType = vObj.Agent.AgentCommissionType;
							vObj.AgentCommissionServiceGroup = vObj.Agent.AgentCommissionServiceGroup;
						EndIf;
						If Not ValueIsFilled(vObj.Agent) Then
							vObj.AgentCommission = 0;
							vObj.AgentCommissionType = Undefined;
							vObj.AgentCommissionServiceGroup = Catalogs.ServiceGroups.EmptyRef();
						EndIf;
						// Marketing code
						If ValueIsFilled(vObj.Customer.MarketingCode) Then
							vObj.MarketingCode = vObj.Customer.MarketingCode;
							vObj.MarketingCodeConfirmationText = "";
						EndIf;
						// Source of business
						If ValueIsFilled(vObj.Customer.SourceOfBusiness) Then
							vObj.SourceOfBusiness = vObj.Customer.SourceOfBusiness;
						EndIf;
						// Client type
						If ValueIsFilled(vObj.Customer.ClientType) Then
							vObj.ClientType = vObj.Customer.ClientType;
							vObj.ClientTypeConfirmationText = vObj.Customer.ClientTypeConfirmationText;
						EndIf;
						// Customer remarks
						If Not IsBlankString(vObj.Customer.Remarks) And vObj.Customer.CopyRemarksToDocuments Then
							rIsHousekeepingRemarks = False;
							vCustRemarks = TrimAll(vObj.Customer.Remarks);
							vRemarks = cmGetRemarks(vCustRemarks, vObj.RoomType, rIsHousekeepingRemarks);
							If rIsHousekeepingRemarks Then
								vObj.HousekeepingRemarks = TrimAll(vRemarks + Chars.LF + TrimAll(vObj.HousekeepingRemarks));
							Else
								vObj.Remarks = TrimAll(vRemarks + Chars.LF + TrimAll(vObj.Remarks));
							EndIf;
						EndIf;
						// Do not print rate
						If vObj.Customer.DoNotPrintRate Then
							vObj.DoNotPrintRate = True;
						EndIf;
						// Load charging rules
						If Object.Payer = Enums.WhoPays.Customer Then
							vObj.pmAddBankTransferChargingRule(, ?(ValueIsFilled(Object.PlannedPaymentMethod), Object.PlannedPaymentMethod, Undefined));
						ElsIf Object.Payer = Enums.WhoPays.Guest Then
							vObj.pmRemoveChargingRules(?(ValueIsFilled(vOldContract), vOldContract, vOldCustomer));
						EndIf;
					Else
						vOldCustomer = vObj.Customer;
						vOldContract = vObj.Contract;
						vOldAgent = vObj.Agent;
						// Customer
						vObj.Customer = Catalogs.Customers.EmptyRef();
						// Contract
						vObj.Contract = Catalogs.Contracts.EmptyRef();
						// Clear agent
						vObj.Agent = Catalogs.Customers.EmptyRef();
						vObj.AgentCommission = 0;
						vObj.AgentCommissionType = Undefined;
						vObj.AgentCommissionServiceGroup = Catalogs.ServiceGroups.EmptyRef();
						// Remove customer charging rules
						If vObj.Payer = Enums.WhoPays.Guest Then
							vObj.pmRemoveChargingRules(?(ValueIsFilled(vOldContract), vOldContract, vOldCustomer));
						EndIf;
					EndIf;
					vOldAgent = vObj.Agent;
					If ValueIsFilled(Object.Agent) Then
						vObjAgent = Object.Agent;
						vObj.Agent = vObjAgent;
						// Agent commission
						If vObjAgent.AgentCommission <> 0 Then
							vObj.AgentCommission = vObjAgent.AgentCommission;
							vObj.AgentCommissionType = vObjAgent.AgentCommissionType;
							vObj.AgentCommissionServiceGroup = vObjAgent.AgentCommissionServiceGroup;
						EndIf;
						// Load charging rules
						If Object.Payer = Enums.WhoPays.Agent Then
							vObj.pmAddBankTransferChargingRule(True, ?(ValueIsFilled(Object.PlannedPaymentMethod), Object.PlannedPaymentMethod, Undefined));
						Else
							If ValueIsFilled(vOldAgent) Then
								vObj.pmRemoveChargingRules(vOldAgent, True);
							EndIf;
						EndIf;
					Else
						// Reset agent commission
						vObj.Agent = Catalogs.Customers.EmptyRef();
						vObj.AgentCommission = 0;
						vObj.AgentCommissionType = Undefined;
						vObj.AgentCommissionServiceGroup = Catalogs.ServiceGroups.EmptyRef();
						// Clear commission from accommodation plan
						For Each vRRRow In vObj.RoomRates Do
							vRRRow.AgentCommission = "";
						EndDo;
						If ValueIsFilled(vOldAgent) Then
							vObj.pmRemoveChargingRules(vOldAgent, True);
						EndIf;
					EndIf;
					If ValueIsFilled(Object.PlannedPaymentMethod) And vObj.PlannedPaymentMethod <> Object.PlannedPaymentMethod Then
						vObj.PlannedPaymentMethod = Object.PlannedPaymentMethod;
						vFolioToUpdate = Undefined;
						vChargingRules = vObj.ChargingRules.Unload();
						If Not vObj.IgnoreGroupChargingRules Then
							cmAddGuestGroupChargingRules(vChargingRules, vObj.GuestGroup);
						EndIf;
						If vChargingRules.Count() > 0 Then
							// Set planned payment method to the accommodation service folio
							If vObj.Services.Count() > 0 Then
								i = vObj.Services.Count() - 1;
								While i >= 0 Do
									vSrvRow = vObj.Services.Get(i);
									If ValueIsFilled(vSrvRow.Folio) Then
										If vSrvRow.IsRoomRevenue And vSrvRow.IsInPrice And Not vSrvRow.RoomRevenueAmountsOnly Then
											vFolioToUpdate = vSrvRow.Folio;
											Break;
										EndIf;
									EndIf;
									i = i - 1;
								EndDo;
							EndIf;
							If Not ValueIsFilled(vFolioToUpdate) Then
								// Set planned payment method to the folio from the first charging rule
								vCRRow = vChargingRules.Get(0);
								If ValueIsFilled(vCRRow.ChargingFolio) Then
									vFolioToUpdate = vCRRow.ChargingFolio;
								EndIf;
							EndIf;
						EndIf;
						If ValueIsFilled(vFolioToUpdate) Then
							If vFolioToUpdate.PaymentMethod <> Object.PlannedPaymentMethod Then
								vFolioObj = vFolioToUpdate.GetObject();
								vFolioObj.PaymentMethod = Object.PlannedPaymentMethod;
								vFolioObj.Write(DocumentWriteMode.Write);
							EndIf;
						EndIf;
					EndIf;
				EndIf;
				If TypeOf(vObj) = Type("DocumentObject.Reservation") Then
					If ValueIsFilled(Object.GuaranteeType) And ValueIsFilled(vObj.ReservationStatus) And vObj.ReservationStatus.IsGuaranteed Then
						vObj.GuaranteeType = Object.GuaranteeType;
					EndIf;
				EndIf;
				If vObj.Modified() Or pRecalculateDocuments Then
					vObj.pmSetDiscounts();
					vObj.pmCalculateServices( , , , , , vObj.IsForFolioSplit);
					vObj.pmSetPlannedPaymentMethod();
					vObj.Write(DocumentWriteMode.Posting);
					If TypeOf(vObj) = Type("DocumentObject.Accommodation") Then
						vObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
					ElsIf TypeOf(vObj) = Type("DocumentObject.Reservation") Then
						vObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
					EndIf;
				EndIf;
			EndIf;
		Except
			vError = vError + NStr("en='Document: ';ru='Документ: ';de='Dokument: '") + TrimAll(vObj.Ref) + NStr("en=' - Recalculation error!';ru=' - Ошибка пересчета';de=' - Rekalkulationfehler'") + Chars.LF + ErrorDescription() + Chars.LF;
		EndTry;
	EndDo;
	If IsBlankString(vError) Then
		pRecalculateDocuments = False;
		pUpdateCustomer = False;
		pUpdateGuests = False;
		pUpdateRemarks = False;
	EndIf;
	Return vError;
EndFunction // RecalculateGroupDocumentsAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetSexByName(pGuestObj)
	If ValueIsFilled(pGuestObj.Citizenship) Then
		If Not pGuestObj.Citizenship.IsVisaNecessaryForEntrance Then
			If StrLen(TrimAll(pGuestObj.SecondName)) < 2 Then
				vLastCharLastName = Upper(Right(TrimAll(pGuestObj.LastName), 1));
				vLastCharFirstName = Upper(Right(TrimAll(pGuestObj.FirstName), 1));
				If (vLastCharLastName = "А") Or (vLastCharLastName = "Я") Or
					(vLastCharFirstName = "А") Or (vLastCharFirstName = "Я") Then
					Return Enums.Sex.Female;
				Else
					Return Enums.Sex.Male;
				EndIf;
			Else
				vLastCharSecondName = Upper(Right(TrimAll(pGuestObj.SecondName), 1));
				If vLastCharSecondName = "А" Then
					Return Enums.Sex.Female;
				Else
					Return Enums.Sex.Male;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndFunction // GetSexByName

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure AddGroupFolio(Command)
	// Save group changes if any
	If Modified Then
		If Not Write() Then
			Return;
		EndIf;
	EndIf;
	// Remove old group CR
	RemoveChargingRules();
	// Add new group CR
	AddBankTransferCR();
	ChargingRulesWereChanged = True;
	// Fill group folio label
	FillGroupFolioAttribute();
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure RemoveGroupFolio(Command)
	// Save group changes if any
	If Modified Then
		If Not Write() Then
			Return;
		EndIf;
	EndIf;
	// Remove old group CR
	RemoveChargingRules();
	ChargingRulesWereChanged = True;
	// Fill group folio label
	FillGroupFolioAttribute();
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure OpenGroupAttachments(Command)
	// Save group changes if any
	If Modified Then
		If Not Write() Then
			Return;
		EndIf;
	EndIf;
	vFrm = OpenForm("InformationRegister.GuestGroupAttachments.ListForm", New Structure("Filter", New Structure("GuestGroup", Object.Ref)), ThisObject);
	vFrm.ReadOnly = ReadOnly;
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtServer
Function GetGroupColor()
	If Not IsBlankString(Object.ColorHexString) Then
		Return tcOnServer.HexToColor(Object.ColorHexString);
	Else
		Return Undefined;
	EndIf;
EndFunction // GetGroupColor

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure SetGroupColor(pColor)
	vObject = FormAttributeToValue("Object");
	vObject.Color = New ValueStorage(pColor);
	vObject.Write();
	ValueToFormAttribute(vObject, "Object");
	// Fill block totals
	FillAvailableRoomsAtServer();
EndProcedure // SetGroupColor

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure ClearGroupColor()
	vObject = FormAttributeToValue("Object");
	vObject.Color = Undefined;
	vObject.Write();
	ValueToFormAttribute(vObject, "Object");
	// Fill block totals
	FillAvailableRoomsAtServer();
EndProcedure // ClearGroupColor

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure SetColor(pCommand)
	// Save group changes if any
	If Modified Then
		Write();
	EndIf;
	// Choose color
	vColorDlg =  New ColorChooseDialog;
	vColorDlg.Color = GetGroupColor();
	vColorDlg.Show(New NotifyDescription("SetColorAfterUserChoice", ThisObject));
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure SetColorAfterUserChoice(pColor, pExtraParams) Export
	If pColor <> Undefined Then
		If pColor.Type = ColorType.WebColor Or pColor.Type = ColorType.Absolute Then
			SetGroupColor(pColor);
			Items.SetColor.BackColor = pColor;
			Notify("Subsystem.Accounts.Changed", Object.Ref);
		Else
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You can choose web or absolute colors only! Style and windows colors are not supported.';ru='Можете выбирать только абсолютные цвета (по названию или по RGB)! Выбор цветов из стилей не поддерживается.';de='Sie dürfen nur absolute Farben wählen (nach Bezeichnung oder nach RGB)! Die Farbenauswahl aus Stilen wird nicht unterstützt.'"));
		EndIf;
	EndIf;
EndProcedure // SetColorAfterUserChoice

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure ClearColor(pCommand)
	// Save group changes if any
	If Modified Then
		Write();
	EndIf;
	// Clear color
	ClearGroupColor();
	Items.SetColor.BackColor = Items.ClearColor.BackColor;
	Notify("Subsystem.Accounts.Changed", Object.Ref);
EndProcedure

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetDocumentRoomTypeAtServer(pDoc)
	Return pDoc.RoomType;
EndFunction // GetDocumentRoomTypeAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetAccommodationReservationAtServer(pDoc)
	Return pDoc.Reservation;
EndFunction // GetAccommodationReservationAtServer

// -----------------------------------------------------------------------------
&AtServer
Function ProcessFirstNewRoomAtServer(pTemplateDoc, pAccTemplate = Undefined, pRoomType = Undefined, pRoomQuantity = 0, pCheckInDate = Undefined, pCheckOutDate = Undefined, pAccommodationType = Undefined, pRoomRate = Undefined, pIsForFolioSplit = False)
	vOneRoomDocs = New ValueList();
	vHotel = Object.Owner;
	
	// Build structure with children ages
	vChildrenAgesStruct = Undefined;
	If ValueIsFilled(pTemplateDoc) And ValueIsFilled(pTemplateDoc.Contract) Then
		vAllotmentContract = pTemplateDoc.Contract;
		If vAllotmentContract.TeenagersMaxAge <> 0 Or vAllotmentContract.ChildrenMaxAge <> 0 Or vAllotmentContract.InfantsMaxAge <> 0 Then
			vChildrenAgesStruct = vAllotmentContract;
		EndIf;
	EndIf;
	
	// Get active special offers
	If vHotel.TeenagersMaxAge <> 0 Or vHotel.ChildrenMaxAge <> 0 Or vHotel.InfantsMaxAge <> 0 Then
		If ValueIsFilled(pRoomType) Then
			vOffers = New ValueTable();
			If ValueIsFilled(pTemplateDoc) Then
				vOffers = cmGetConfirmedSpecialOffersForReservation(pTemplateDoc, vHotel, pTemplateDoc.RoomRate, pTemplateDoc.RoomRateType, Undefined, pTemplateDoc.ClientType, pTemplateDoc.Customer, pTemplateDoc.CustomerType, pTemplateDoc.GuestGroup, pTemplateDoc.SourceOfBusiness, pTemplateDoc.MarketingCode, pTemplateDoc.TripPurpose, pTemplateDoc.CheckInDate, pTemplateDoc.Duration, pTemplateDoc.CheckOutDate, ?(ValueIsFilled(pTemplateDoc.GuestGroup), pTemplateDoc.GuestGroup.CreateDate, CurrentSessionDate()), ?(ValueIsFilled(pRoomType), pRoomType, pTemplateDoc.RoomType));
			ElsIf ValueIsFilled(Object.RoomRate) Then
				vCheckInDate = '00010101';
				If ValueIsFilled(pCheckInDate) Then
					vCheckInDate = pCheckInDate;
				ElsIf ValueIsFilled(Object.CheckInDate) Then
					vCheckInDate = Object.CheckInDate;
				EndIf;
				vCheckOutDate = '00010101';
				If ValueIsFilled(pCheckOutDate) Then
					vCheckOutDate = pCheckOutDate;
				ElsIf ValueIsFilled(Object.CheckOutDate) Then
					vCheckOutDate = Object.CheckOutDate;
				EndIf;
				If ValueIsFilled(vCheckInDate) And ValueIsFilled(vCheckOutDate) Then
					vDuration = cmCalculateDuration(Object.RoomRate, vCheckInDate, vCheckOutDate);
					vOffers = cmGetConfirmedSpecialOffersForReservation(Undefined, vHotel, Object.RoomRate, Object.RoomRate.RoomRateType, Undefined, Object.ClientType, Object.Customer, ?(ValueIsFilled(Object.Customer), Object.Customer.CustomerType, Undefined), Object.Ref, Object.SourceOfBusiness, Object.MarketingCode, Object.TripPurpose, vCheckInDate, vDuration, vCheckOutDate, ?(ValueIsFilled(Object.CreateDate), Object.CreateDate, CurrentSessionDate()), pRoomType);
				EndIf;
			EndIf;
			For Each vOffersRow In vOffers Do
				vOffer = vOffersRow.SpecialOffer;
				If vOffer.TeenagersMaxAge <> 0 Or vOffer.ChildrenMaxAge <> 0 Or vOffer.InfantsMaxAge <> 0 Then
					vChildrenAgesStruct = vOffer;
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	// Get accommodation template
	vAccTemplate = Undefined;
	If pAccTemplate <> Undefined Then
		vAccTemplate = pAccTemplate;
	Else
		vAgeArray = New Array();
		For i = 1 To NumberOfKids Do
			vAgeArray.Add(ThisObject["KidAge" + i]);
		EndDo;
		vAccommodationTemplates = cmGetAvailableAccommodationTypesWithKidsAges(NumberOfAdults, vAgeArray.Count(), vAgeArray, "", Object.Owner, ?(pRoomType <> Undefined, pRoomType, AddRoomType), , False, , vChildrenAgesStruct);
		If vAccommodationTemplates <> Undefined Then
			For Each vRow In vAccommodationTemplates Do
				If ValueIsFilled(vRow.AccTemplate) And IsForFolioSplit <> vRow.AccTemplate.IsForFolioSplit Then
					Continue;
				EndIf;
				If vAccTemplate = Undefined Then
					vAccTemplate = vRow.AccTemplate;
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	If vAccTemplate = Undefined Then
		Return Undefined;
	ElsIf vAccTemplate.AccommodationTypes.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	vDocNumber = "";
	For Each vAccTypeRow In vAccTemplate.AccommodationTypes Do
		If ValueIsFilled(pTemplateDoc) Then
			vResObj = pTemplateDoc.Copy();
			vResObj.pmFillAuthorAndDate();
			vResObj.Room = Undefined;
			vResObj.Guest = Undefined;
			vResObj.GuestFullName = "";
			vResObj.GuestAge = 0;
			vResObj.EMail = "";
			vResObj.Phone = "";
			vResObj.Fax = "";
			If Not vResObj.ReservationStatus.IsActive And Not vResObj.ReservationStatus.IsPreliminary Or vResObj.ReservationStatus.IsCheckIn Or vResObj.ReservationStatus.DoNotAllowEditOfMainReservationParameters Then
				vResObj.ReservationStatus = ?(ValueIsFilled(Object.Status) And TypeOf(Object.Status) = Type("CatalogRef.ReservationStatuses"), Object.Status, vResObj.Hotel.NewReservationStatus);
			EndIf;
			If Not vResObj.ReservationStatus.IsActive And Not vResObj.ReservationStatus.IsPreliminary Or vResObj.ReservationStatus.IsCheckIn Or vResObj.ReservationStatus.DoNotAllowEditOfMainReservationParameters Then
				vResObj.ReservationStatus = vResObj.Hotel.NewReservationStatus;
			EndIf;
			vResObj.DoCharging = vResObj.ReservationStatus.DoCharging;
			vResObj.GuaranteeType = vResObj.ReservationStatus.GuaranteeType;
			vResObj.NumberOfBeds = Round(vResObj.NumberOfBeds/?(vResObj.RoomQuantity = 0, 1, vResObj.RoomQuantity), 0);
			vResObj.NumberOfRooms = Round(vResObj.NumberOfRooms/?(vResObj.RoomQuantity = 0, 1, vResObj.RoomQuantity), 0);
			vResObj.NumberOfAdditionalBeds = Round(vResObj.NumberOfAdditionalBeds/?(vResObj.RoomQuantity = 0, 1, vResObj.RoomQuantity), 0);
		Else
			vResObj = Documents.Reservation.CreateDocument();
			vResObj.GuestGroup = Object.Ref;
			vResObj.pmFillAttributesWithDefaultValues();
			vResObj.ReservationStatus = ?(ValueIsFilled(Object.Status) And TypeOf(Object.Status) = Type("CatalogRef.ReservationStatuses"), Object.Status, vResObj.Hotel.NewReservationStatus);
			If Not vResObj.ReservationStatus.IsActive And Not vResObj.ReservationStatus.IsPreliminary Or vResObj.ReservationStatus.IsCheckIn Or vResObj.ReservationStatus.DoNotAllowEditOfMainReservationParameters Then
				vResObj.ReservationStatus = vResObj.Hotel.NewReservationStatus;
			EndIf;
			vResObj.DoCharging = vResObj.ReservationStatus.DoCharging;
			vResObj.GuaranteeType = vResObj.ReservationStatus.GuaranteeType;
			vResObj.Customer = Object.Customer;
			vResObj.Contract = Object.Contract;
			If ValueIsFilled(pCheckInDate) Then
				vResObj.CheckInDate = pCheckInDate;
			ElsIf ValueIsFilled(Object.CheckInDate) Then
				vResObj.CheckInDate = Object.CheckInDate;
			EndIf;
			If ValueIsFilled(pCheckOutDate) Then
				vResObj.CheckOutDate = pCheckOutDate;
			ElsIf ValueIsFilled(Object.CheckOutDate) Then
				vResObj.CheckOutDate = Object.CheckOutDate;
			EndIf;
			vResObj.Duration = vResObj.pmCalculateDuration();
		EndIf;
		If Not IsBlankString(vDocNumber) Then
			vResObj.Number = vDocNumber;
		EndIf;
		vResObj.RoomType = ?(pRoomType <> Undefined, pRoomType, AddRoomType);
		If ValueIsFilled(vResObj.RoomType) And ValueIsFilled(vResObj.RoomType.BaseRoomType) Then
			vResObj.RoomTypeUpgrade = vResObj.RoomType;
			vResObj.RoomType = vResObj.RoomType.BaseRoomType;
		EndIf;
		vResObj.NumberOfPersons = 1;
		vResObj.RoomQuantity = 1;
		// Company
		vRoomType = vResObj.RoomType;
		If ValueIsFilled(vRoomType.Company) Then
			If vResObj.Company <> vRoomType.Company Then
				vResObj.Company = vRoomType.Company;
			EndIf;
		EndIf;
		// Clear occupation percents
		vResObj.pmClearOccupationPercents();
		// Fill accommodation type and calculate resources
		vResObj.AccommodationType = vAccTypeRow.AccommodationType;
		If vAccTemplate.AccommodationTypes.IndexOf(vAccTypeRow) = 0 Then
			vResObj.AccommodationTemplate = vAccTemplate;
			vResObj.NumberOfAdults = vAccTemplate.NumberOfAdults;
			vResObj.NumberOfTeenagers = vAccTemplate.NumberOfTeenagers;
			vResObj.NumberOfChildren = vAccTemplate.NumberOfChildren;
			vResObj.NumberOfInfants = vAccTemplate.NumberOfInfants;
		Else
			vResObj.AccommodationTemplate = Undefined;
			vResObj.NumberOfAdults = 0;
			vResObj.NumberOfTeenagers = 0;
			vResObj.NumberOfChildren = 0;
			vResObj.NumberOfInfants = 0;
		EndIf;
		If ValueIsFilled(pAccommodationType) Then
			vResObj.AccommodationType = pAccommodationType;
		EndIf;
		vResObj.IsForFolioSplit = pIsForFolioSplit;
		// Recalculate resources
		If pRoomQuantity > 0 Then
			vResObj.RoomQuantity = pRoomQuantity;
			vAccommodationTemplate = vResObj.AccommodationTemplate;
			If ValueIsFilled(vAccommodationTemplate) Then
				vResObj.NumberOfAdults = vResObj.RoomQuantity * vAccommodationTemplate.NumberOfAdults;
				vResObj.NumberOfTeenagers = vResObj.RoomQuantity * vAccommodationTemplate.NumberOfTeenagers;
				vResObj.NumberOfChildren = vResObj.RoomQuantity * vAccommodationTemplate.NumberOfChildren;
				vResObj.NumberOfInfants = vResObj.RoomQuantity * vAccommodationTemplate.NumberOfInfants;
				vResObj.NumberOfPersons = vResObj.RoomQuantity;
			EndIf;
		EndIf;
		vResObj.pmCalculateResources();
		// Process contract and customer settings
		If ValueIsFilled(vResObj.Contract) And Not ValueIsFilled(pTemplateDoc) Then
			vContract = vResObj.Contract;
			// Room quota
			If ValueIsFilled(vContract.RoomQuota) Then
				vResObj.RoomQuota = vContract.RoomQuota;
				If ValueIsFilled(vResObj.RoomQuota.Company) And ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Company) And 
					vResObj.RoomQuota.Company <> SessionParameters.CurrentUser.Company Then
					vResObj.RoomQuota = Catalogs.RoomQuotas.EmptyRef();
				EndIf;
			EndIf;
			// Planned payment method
			If Not ValueIsFilled(vResObj.ParentDoc) Then
				If ValueIsFilled(vContract.PlannedPaymentMethod) Then
					vResObj.PlannedPaymentMethod = vContract.PlannedPaymentMethod;
				EndIf;
			EndIf;
			// Agent commission
			If Not vContract.IsSubAgent Then
				vResObj.Agent = vContract.Agent;
				If ValueIsFilled(vResObj.Customer) And ValueIsFilled(vContract.AgentCommissionType) Then
					If Not ValueIsFilled(vResObj.Agent) Then
						vResObj.Agent = vResObj.Customer;
					EndIf;
					If vContract.AgentCommission <> 0 Then
						vResObj.AgentCommission = vContract.AgentCommission;
						vResObj.AgentCommissionType = vContract.AgentCommissionType;
						vResObj.AgentCommissionServiceGroup = vContract.AgentCommissionServiceGroup;
					EndIf;
				EndIf;
			Else
				vAgent = vContract.Owner;
				vResObj.Agent = vAgent;
				If ValueIsFilled(vAgent.Agent) Then
					vResObj.Agent = vAgent.Agent;
				EndIf;
				If vAgent.AgentCommission <> 0 Then
					vResObj.AgentCommission = vAgent.AgentCommission;
					vResObj.AgentCommissionType = vAgent.AgentCommissionType;
					vResObj.AgentCommissionServiceGroup = vAgent.AgentCommissionServiceGroup;
				EndIf;
			EndIf;
			If Not ValueIsFilled(vResObj.Agent) Then
				vResObj.AgentCommission = 0;
				vResObj.AgentCommissionType = Undefined;
				vResObj.AgentCommissionServiceGroup = Catalogs.ServiceGroups.EmptyRef();
			EndIf;
			// Room rate
			If ValueIsFilled(vContract.RoomRate) Then
				If vResObj.RoomRate <> vContract.RoomRate Then
					vResObj.PriceCalculationDate = '00010101';
					vResObj.RoomRate = vContract.RoomRate;
					vRoomRate = vResObj.RoomRate;
					vResObj.RoomRateServiceGroup = vContract.RoomRateServiceGroup;
					vResObj.DoNotPrintRate = vRoomRate.DoNotPrintRate;
					// Source of business
					If ValueIsFilled(vRoomRate.SourceOfBusiness) Then
						vResObj.SourceOfBusiness = vRoomRate.SourceOfBusiness;
					EndIf;
					// Marketing code
					If ValueIsFilled(vRoomRate.MarketingCode) Then
						vResObj.MarketingCode = vRoomRate.MarketingCode;
					EndIf;
					// Client type
					If ValueIsFilled(vRoomRate.ClientType) Then
						vResObj.ClientType = vRoomRate.ClientType;
						vResObj.ClientTypeConfirmationText = vRoomRate.ClientTypeConfirmationText;
					EndIf;
					// Company
					If ValueIsFilled(vRoomRate.Company) Then
						vResObj.Company = vRoomRate.Company;
					EndIf;
				EndIf;
			EndIf;
			// Contract company
			If ValueIsFilled(vContract.Company) Then
				vResObj.Company = vContract.Company;
			EndIf;
			// Marketing code
			If ValueIsFilled(vContract.MarketingCode) Then
				vResObj.MarketingCode = vContract.MarketingCode;
				vResObj.MarketingCodeConfirmationText = "";
			EndIf;
			// Source of business
			If ValueIsFilled(vContract.SourceOfBusiness) Then
				vResObj.SourceOfBusiness = vContract.SourceOfBusiness;
			EndIf;
			// Client type
			If ValueIsFilled(vContract.ClientType) Then
				vResObj.ClientType = vContract.ClientType;
				vResObj.ClientTypeConfirmationText = vContract.ClientTypeConfirmationText;
			EndIf;
			// Discount
			vResObj.pmSetDiscounts();
			// Charging rules
			If Object.Payer = Enums.WhoPays.Customer Then
				If ValueIsFilled(Object.PlannedPaymentMethod) Then
					vResObj.PlannedPaymentMethod = Object.PlannedPaymentMethod;
				EndIf;
				If ValueIsFilled(Object.Customer) And Object.ChargingRules.Count() = 0 Then
					vResObj.pmAddBankTransferChargingRule(, ?(ValueIsFilled(Object.PlannedPaymentMethod), Object.PlannedPaymentMethod, Undefined));
				EndIf;
			EndIf;
		ElsIf ValueIsFilled(vResObj.Customer) And Not ValueIsFilled(pTemplateDoc) Then
			vCustomer = vResObj.Customer;
			// Customer type
			vResObj.CustomerType = vCustomer.CustomerType;
			// Room rate type
			If ValueIsFilled(vResObj.CustomerType) Then
				If Not ValueIsFilled(vResObj.RoomRateType) Then
					vResObj.RoomRateType = vResObj.CustomerType.RoomRateType;
				EndIf;
			EndIf;
			// Contact person
			If Not IsBlankString(vCustomer.ContactPerson) Then
				vResObj.ContactPerson = TrimR(vCustomer.ContactPerson);
			EndIf;
			// Planned payment method
			If Not ValueIsFilled(vResObj.ParentDoc) Then
				If ValueIsFilled(vCustomer.PlannedPaymentMethod) Then
					vResObj.PlannedPaymentMethod = vCustomer.PlannedPaymentMethod;
				EndIf;
			EndIf;
			// Agent
			vResObj.Agent = vCustomer.Agent;
			If ValueIsFilled(vCustomer.AgentCommissionType) Then
				If Not ValueIsFilled(vResObj.Agent) Then
					vResObj.Agent = vCustomer;
				EndIf;
				vResObj.AgentCommission = vResObj.Agent.AgentCommission;
				vResObj.AgentCommissionType = vResObj.Agent.AgentCommissionType;
				vResObj.AgentCommissionServiceGroup = vResObj.Agent.AgentCommissionServiceGroup;
			EndIf;
			If Not ValueIsFilled(vResObj.Agent) Then
				vResObj.AgentCommission = 0;
				vResObj.AgentCommissionType = Undefined;
				vResObj.AgentCommissionServiceGroup = Catalogs.ServiceGroups.EmptyRef();
			EndIf;
			// Room rate
			If ValueIsFilled(vCustomer.RoomRate) Then
				If vResObj.RoomRate <> vCustomer.RoomRate Then
					vResObj.PriceCalculationDate = '00010101';
					vResObj.RoomRate = vCustomer.RoomRate;
					vRoomRate = vResObj.RoomRate;
					vResObj.RoomRateServiceGroup = vCustomer.RoomRateServiceGroup;
					vResObj.DoNotPrintRate = vRoomRate.DoNotPrintRate;
					// Source of business
					If ValueIsFilled(vRoomRate.SourceOfBusiness) Then
						vResObj.SourceOfBusiness = vRoomRate.SourceOfBusiness;
					EndIf;
					// Marketing code
					If ValueIsFilled(vRoomRate.MarketingCode) Then
						vResObj.MarketingCode = vRoomRate.MarketingCode;
					EndIf;
					// Client type
					If ValueIsFilled(vRoomRate.ClientType) Then
						vResObj.ClientType = vRoomRate.ClientType;
						vResObj.ClientTypeConfirmationText = vRoomRate.ClientTypeConfirmationText;
					EndIf;
					// Company
					If ValueIsFilled(vRoomRate.Company) Then
						vResObj.Company = vRoomRate.Company;
					EndIf;
				EndIf;
			ElsIf ValueIsFilled(vCustomer.RoomRateServiceGroup) Then
				vResObj.RoomRateServiceGroup = vCustomer.RoomRateServiceGroup;
			EndIf;
			// Marketing code
			If ValueIsFilled(vCustomer.MarketingCode) Then
				vResObj.MarketingCode = vCustomer.MarketingCode;
				vResObj.MarketingCodeConfirmationText = "";
			EndIf;
			// Source of business
			If ValueIsFilled(vCustomer.SourceOfBusiness) Then
				vResObj.SourceOfBusiness = vCustomer.SourceOfBusiness;
			EndIf;
			// Client type
			If ValueIsFilled(vCustomer.ClientType) Then
				vResObj.ClientType = vCustomer.ClientType;
				vResObj.ClientTypeConfirmationText = vCustomer.ClientTypeConfirmationText;
			EndIf;
			// Customer remarks
			If Not IsBlankString(vCustomer.Remarks) And vCustomer.CopyRemarksToDocuments Then
				vResObj.Remarks = TrimAll(TrimAll(vCustomer.Remarks) + Chars.LF + TrimAll(vResObj.Remarks));
			EndIf;
			// Contract
			If Not ValueIsFilled(vResObj.Contract) And ValueIsFilled(vCustomer.Contract) Then
				vResObj.Contract = vCustomer.Contract;
				vContract = vResObj.Contract;
				// Room quota
				If ValueIsFilled(vContract.RoomQuota) Then
					vResObj.RoomQuota = vContract.RoomQuota;
					If ValueIsFilled(vResObj.RoomQuota.Company) And ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Company) And 
						vResObj.RoomQuota.Company <> SessionParameters.CurrentUser.Company Then
						vResObj.RoomQuota = Catalogs.RoomQuotas.EmptyRef();
					EndIf;
				EndIf;
				// Planned payment method
				If Not ValueIsFilled(vResObj.ParentDoc) Then
					If ValueIsFilled(vContract.PlannedPaymentMethod) Then
						vResObj.PlannedPaymentMethod = vContract.PlannedPaymentMethod;
					EndIf;
				EndIf;
				// Agent commission
				If Not vContract.IsSubAgent Then
					vResObj.Agent = vContract.Agent;
					If ValueIsFilled(vResObj.Customer) And ValueIsFilled(vContract.AgentCommissionType) Then
						If Not ValueIsFilled(vResObj.Agent) Then
							vResObj.Agent = vResObj.Customer;
						EndIf;
						If vContract.AgentCommission <> 0 Then
							vResObj.AgentCommission = vContract.AgentCommission;
							vResObj.AgentCommissionType = vContract.AgentCommissionType;
							vResObj.AgentCommissionServiceGroup = vContract.AgentCommissionServiceGroup;
						EndIf;
					EndIf;
				Else
					vAgent = vContract.Owner;
					vResObj.Agent = vAgent;
					If ValueIsFilled(vAgent.Agent) Then
						vResObj.Agent = vAgent.Agent;
					EndIf;
					If vAgent.AgentCommission <> 0 Then
						vResObj.AgentCommission = vAgent.AgentCommission;
						vResObj.AgentCommissionType = vAgent.AgentCommissionType;
						vResObj.AgentCommissionServiceGroup = vAgent.AgentCommissionServiceGroup;
					EndIf;
				EndIf;
				If Not ValueIsFilled(vResObj.Agent) Then
					vResObj.AgentCommission = 0;
					vResObj.AgentCommissionType = Undefined;
					vResObj.AgentCommissionServiceGroup = Catalogs.ServiceGroups.EmptyRef();
				EndIf;
				// Room rate
				If ValueIsFilled(vContract.RoomRate) Then
					If vResObj.RoomRate <> vContract.RoomRate Then
						vResObj.PriceCalculationDate = '00010101';
						vResObj.RoomRate = vContract.RoomRate;
						vRoomRate = vResObj.RoomRate;
						vResObj.RoomRateServiceGroup = vContract.RoomRateServiceGroup;
						vResObj.DoNotPrintRate = vRoomRate.DoNotPrintRate;
						// Source of business
						If ValueIsFilled(vRoomRate.SourceOfBusiness) Then
							vResObj.SourceOfBusiness = vRoomRate.SourceOfBusiness;
						EndIf;
						// Marketing code
						If ValueIsFilled(vRoomRate.MarketingCode) Then
							vResObj.MarketingCode = vRoomRate.MarketingCode;
						EndIf;
						// Client type
						If ValueIsFilled(vRoomRate.ClientType) Then
							vResObj.ClientType = vRoomRate.ClientType;
							vResObj.ClientTypeConfirmationText = vRoomRate.ClientTypeConfirmationText;
						EndIf;
						// Company
						If ValueIsFilled(vRoomRate.Company) Then
							vResObj.Company = vRoomRate.Company;
						EndIf;
					EndIf;
				EndIf;
				// Contract company
				If ValueIsFilled(vContract.Company) Then
					vResObj.Company = vContract.Company;
				EndIf;
				// Marketing code
				If ValueIsFilled(vContract.MarketingCode) Then
					vResObj.MarketingCode = vContract.MarketingCode;
					vResObj.MarketingCodeConfirmationText = "";
				EndIf;
				// Source of business
				If ValueIsFilled(vContract.SourceOfBusiness) Then
					vResObj.SourceOfBusiness = vContract.SourceOfBusiness;
				EndIf;
				// Client type
				If ValueIsFilled(vContract.ClientType) Then
					vResObj.ClientType = vContract.ClientType;
					vResObj.ClientTypeConfirmationText = vContract.ClientTypeConfirmationText;
				EndIf;
			EndIf;
			// Discount
			vResObj.pmSetDiscounts();
			// Charging rules
			If Object.Payer = Enums.WhoPays.Customer Then
				If ValueIsFilled(Object.PlannedPaymentMethod) Then
					vResObj.PlannedPaymentMethod = Object.PlannedPaymentMethod;
				EndIf;
				If ValueIsFilled(Object.Customer) And Object.ChargingRules.Count() = 0 Then
					vResObj.pmAddBankTransferChargingRule(, ?(ValueIsFilled(Object.PlannedPaymentMethod), Object.PlannedPaymentMethod, Undefined));
				EndIf;
			EndIf;
		EndIf;
		// Agent
		If ValueIsFilled(Object.Agent) And Not ValueIsFilled(pTemplateDoc) Then
			vObjAgent = Object.Agent;
			vResObj.Agent = vObjAgent;
			If ValueIsFilled(vObjAgent.AgentCommissionType) Then
				vResObj.AgentCommission = vObjAgent.AgentCommission;
				vResObj.AgentCommissionType = vObjAgent.AgentCommissionType;
				vResObj.AgentCommissionServiceGroup = vObjAgent.AgentCommissionServiceGroup;
			EndIf;
			// Charging rules
			If Object.Payer = Enums.WhoPays.Agent Then
				If ValueIsFilled(Object.PlannedPaymentMethod) Then
					vResObj.PlannedPaymentMethod = Object.PlannedPaymentMethod;
				EndIf;
				If ValueIsFilled(Object.Agent) And Object.ChargingRules.Count() = 0 Then
					vResObj.pmAddBankTransferChargingRule(True, ?(ValueIsFilled(Object.PlannedPaymentMethod), Object.PlannedPaymentMethod, Undefined));
				EndIf;
			EndIf;
		EndIf;
		If Not ValueIsFilled(pTemplateDoc) Then
			If ValueIsFilled(Object.RoomRate) Then
				vResObj.RoomRate = Object.RoomRate;
			EndIf;
			If ValueIsFilled(pRoomRate) Then
				vResObj.RoomRate = pRoomRate;
			EndIf;
			If ValueIsFilled(Object.ServicePackage) Then
				vResObj.ServicePackage = Object.ServicePackage;
			EndIf;
			If ValueIsFilled(Object.ClientType) Then
				vResObj.ClientType = Object.ClientType;
			EndIf;
			If ValueIsFilled(Object.SourceOfBusiness) Then
				vResObj.SourceOfBusiness = Object.SourceOfBusiness;
			EndIf;
			If ValueIsFilled(Object.MarketingCode) Then
				vResObj.MarketingCode = Object.MarketingCode;
			EndIf;
			If ValueIsFilled(Object.TripPurpose) Then
				vResObj.TripPurpose = Object.TripPurpose;
			EndIf;
			If ValueIsFilled(Object.GuaranteeType) Then
				vResObj.GuaranteeType = Object.GuaranteeType;
			EndIf;
			If ValueIsFilled(Object.DiscountType) Then
				vResObj.DiscountType = Object.DiscountType;
				vResObj.DiscountServiceGroup = Object.DiscountType.DiscountServiceGroup;
			EndIf;
			If ValueIsFilled(Object.Allotment) Then
				vResObj.RoomQuota = Object.Allotment;
			EndIf;
		Else
			If ValueIsFilled(pRoomRate) Then
				vResObj.RoomRate = pRoomRate;
			EndIf;
		EndIf;
		If ValueIsFilled(vResObj.RoomRate) Then
			vResObj.RoomRateType = vResObj.RoomRate.RoomRateType;
		EndIf;
		If vAccTemplate.AccommodationTypes.IndexOf(vAccTypeRow) > 0 Then
			If ValueIsFilled(vResObj.ServicePackage) And Not vResObj.ServicePackage.IsPerPerson Then
				vResObj.ServicePackage = Undefined;
			EndIf;
			s = 0;
			While s < vResObj.ServicePackages.Count() Do
				vResObjSPRow = vResObj.ServicePackages.Get(s);
				If ValueIsFilled(vResObjSPRow.ServicePackage) And Not vResObjSPRow.ServicePackage.IsPerPerson Then
					vResObj.ServicePackages.Delete(s);
				Else
					s = s + 1;
				EndIf;
			EndDo;
		EndIf;
		
		// Cutoff date
		If pRoomQuantity > 1 Then
			If Object.ReleaseTime <> 0 Then
				vResObj.WaitTillDate = cm0SecondShift(vResObj.CheckInDate - 24*3600*Object.ReleaseTime);
			ElsIf ValueIsFilled(Object.ReleaseDate) Then
				vResObj.WaitTillDate = cm0SecondShift(Object.ReleaseDate + (vResObj.CheckInDate - BegOfDay(vResObj.CheckInDate)));
			EndIf;
		EndIf;
		
		// Calculate services
		vResObj.pmCalculateServices( , , , , , vResObj.IsForFolioSplit);
		
		// Write reservation
		vResObj.Write(DocumentWriteMode.Posting);
		vResObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
		
		If IsBlankString(vDocNumber) Then
			vDocNumber = TrimAll(vResObj.Number);
		EndIf;
		
		vOneRoomDocs.Add(vResObj.Ref);
		
		If pAccTemplate <> Undefined Then
			If pTemplateDoc = Undefined Then
				pTemplateDoc = vResObj.Ref;
			EndIf;
		EndIf;
	EndDo;
	
	Return vOneRoomDocs;
EndFunction // ProcessFirstNewRoomAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetNewReservationParametersStruct(pHotel, pClientDoc, pRoomType, pCustomer, pContract, pAgent, pGuestGroup, pCheckInDate, pCheckOutDate, pRoomRate = Undefined, pServicePackage = Undefined, pClientType = Undefined, pStatus = Undefined, pSourceOfBusiness = Undefined, pMarketingCode = Undefined, pTripPurpose = Undefined, pGuaranteeType = Undefined, pDiscountType = Undefined, pRoomQuota = Undefined, pIsForFolioSplit = False, pPayer = Undefined, pPlannedPaymentMethod = Undefined, pNumberOfAdults = 0, pNumberOfKids = 0, pKidsAges = Undefined, pAddNumberOfRooms = 0)
	vStruct = New Structure("Company, RoomRate, ServicePackage, ServicePackages, RoomQuota, MarketingCode, SourceOfBusiness, TripPurpose, Customer, Contract, Agent, AgentCommission, AgentCommissionType, AgentCommissionServiceGroup, GuestGroup, CheckInDate, CheckOutDate, RoomType, ReservationStatus, GuaranteeType, ClientType, DiscountType, IsForFolioSplit, Payer, PlannedPaymentMethod, NumberOfAdults, NumberOfKids, KidsAges, RoomQuantity");
	If ValueIsFilled(pClientDoc) And (TypeOf(pClientDoc) = Type("DocumentRef.Accommodation") Or TypeOf(pClientDoc) = Type("DocumentRef.Reservation")) Then
		vStruct.Company = pClientDoc.Company;
		vStruct.RoomRate = pClientDoc.RoomRate;
		vStruct.ServicePackage = pClientDoc.ServicePackage;
		vStruct.ServicePackages = New Array;
		For Each vClientDocSPRow In pClientDoc.ServicePackages Do
			vClientDocSPRowStruct = New Structure("ServicePackage, Quantity, DateFrom, DateTo", vClientDocSPRow.ServicePackage, vClientDocSPRow.Quantity, vClientDocSPRow.DateFrom, vClientDocSPRow.DateTo);
			vStruct.ServicePackages.Add(vClientDocSPRowStruct);
		EndDo;
		vStruct.RoomQuota = pClientDoc.RoomQuota;
		vStruct.MarketingCode = pClientDoc.MarketingCode;
		vStruct.SourceOfBusiness = pClientDoc.SourceOfBusiness;
		vStruct.TripPurpose = pClientDoc.TripPurpose;
		vStruct.Agent = pClientDoc.Agent;
		vStruct.AgentCommission = pClientDoc.AgentCommission;
		vStruct.AgentCommissionType = pClientDoc.AgentCommissionType;
		vStruct.AgentCommissionServiceGroup = pClientDoc.AgentCommissionServiceGroup;
		vStruct.DiscountType = pClientDoc.DiscountType;
		If TypeOf(pClientDoc) = Type("DocumentRef.Accommodation") Then
			vStruct.ReservationStatus = ?(ValueIsFilled(pStatus) And TypeOf(pStatus) = Type("CatalogRef.ReservationStatuses"), pStatus, pClientDoc.Hotel.NewReservationStatus);
			If Not vStruct.ReservationStatus.IsActive And Not vStruct.ReservationStatus.IsPreliminary Or 
			   vStruct.ReservationStatus.IsCheckIn Or vStruct.ReservationStatus.DoNotAllowEditOfMainReservationParameters Then
				vStruct.ReservationStatus = pClientDoc.Hotel.NewReservationStatus;
			EndIf;
			vStruct.GuaranteeType = ?(ValueIsFilled(pGuaranteeType), pGuaranteeType, vStruct.ReservationStatus.GuaranteeType);
		ElsIf TypeOf(pClientDoc) = Type("DocumentRef.Reservation") Then
			If (pClientDoc.ReservationStatus.IsActive Or pClientDoc.ReservationStatus.IsPreliminary) And 
			   Not pClientDoc.ReservationStatus.IsCheckIn And Not pClientDoc.ReservationStatus.DoNotAllowEditOfMainReservationParameters Then
				vStruct.ReservationStatus = pClientDoc.ReservationStatus;
				vStruct.GuaranteeType = pClientDoc.GuaranteeType;
			Else
				vStruct.ReservationStatus = ?(ValueIsFilled(pStatus) And TypeOf(pStatus) = Type("CatalogRef.ReservationStatuses"), pStatus, pClientDoc.Hotel.NewReservationStatus);
				If Not vStruct.ReservationStatus.IsActive And Not vStruct.ReservationStatus.IsPreliminary Or 
				   vStruct.ReservationStatus.IsCheckIn Or vStruct.ReservationStatus.DoNotAllowEditOfMainReservationParameters Then
					vStruct.ReservationStatus = pClientDoc.Hotel.NewReservationStatus;
				EndIf;
				vStruct.GuaranteeType = ?(ValueIsFilled(pGuaranteeType), pGuaranteeType, vStruct.ReservationStatus.GuaranteeType);
			EndIf;
		Else
			vStruct.ReservationStatus = ?(ValueIsFilled(pStatus) And TypeOf(pStatus) = Type("CatalogRef.ReservationStatuses"), pStatus, pClientDoc.Hotel.NewReservationStatus);
			If Not vStruct.ReservationStatus.IsActive And Not vStruct.ReservationStatus.IsPreliminary Or 
			   vStruct.ReservationStatus.IsCheckIn Or vStruct.ReservationStatus.DoNotAllowEditOfMainReservationParameters Then
				vStruct.ReservationStatus = pClientDoc.Hotel.NewReservationStatus;
			EndIf;
			vStruct.GuaranteeType = ?(ValueIsFilled(pGuaranteeType), pGuaranteeType, vStruct.ReservationStatus.GuaranteeType);
		EndIf;
	Else
		If ValueIsFilled(pStatus) And TypeOf(pStatus) = Type("CatalogRef.ReservationStatuses") Then
			vStruct.ReservationStatus = pStatus;
			If Not vStruct.ReservationStatus.IsActive And Not vStruct.ReservationStatus.IsPreliminary Or 
			   vStruct.ReservationStatus.IsCheckIn Or vStruct.ReservationStatus.DoNotAllowEditOfMainReservationParameters Then
				vStruct.ReservationStatus = pHotel.NewReservationStatus;
			EndIf;
		Else
			vStruct.ReservationStatus = pHotel.NewReservationStatus;
		EndIf;
		vStruct.Company = pHotel.Company;
		vStruct.Agent = pAgent;
		vStruct.RoomRate = pRoomRate;
		vStruct.ServicePackage = pServicePackage;
		vStruct.ClientType = pClientType;
		vStruct.SourceOfBusiness = pSourceOfBusiness;
		vStruct.MarketingCode = pMarketingCode;
		vStruct.TripPurpose = pTripPurpose;
		vStruct.GuaranteeType = pGuaranteeType;
		vStruct.DiscountType = pDiscountType;
		vStruct.RoomQuota = pRoomQuota;
		If ValueIsFilled(pAgent) Then
			vStruct.Agent = pAgent;
		EndIf;
	EndIf;
	vStruct.IsForFolioSplit = pIsForFolioSplit;
	vStruct.Customer = pCustomer;
	vStruct.Contract = pContract;
	vStruct.Payer = pPayer;
	vStruct.PlannedPaymentMethod = pPlannedPaymentMethod;
	vStruct.GuestGroup = pGuestGroup;
	If ValueIsFilled(pCheckInDate) And ValueIsFilled(pCheckOutDate) And pCheckOutDate > pCheckInDate Then
		vStruct.CheckInDate = pCheckInDate;
		vStruct.CheckOutDate = pCheckOutDate;
	EndIf;
	If ValueIsFilled(pRoomType) Then
		vStruct.RoomType = pRoomType;
	EndIf;
	vStruct.NumberOfAdults = pNumberOfAdults;
	vStruct.NumberOfKids = pNumberOfKids;
	vStruct.KidsAges = pKidsAges;
	vStruct.RoomQuantity = pAddNumberOfRooms;
	Return vStruct;
EndFunction // GetNewReservationParametersStruct

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenNewReservationForm()
	vStatus = Object.Status;
	If ValueIsFilled(vStatus) And TypeOf(vStatus) = Type("CatalogRef.ReservationStatuses") Then
		If vStatus = tcOnServer.cmGetAttributeByRef(Object.Owner, "NewRoomsGroupStatus") Then
			vStatus = tcOnServer.cmGetAttributeByRef(Object.Owner, "NewReservationStatus");
		EndIf;
	EndIf;
	vKidsAges = New Array();
	For i = 1 To NumberOfKids Do
		vKidsAges.Add(ThisObject["KidAge" + i]);
	EndDo;
	vParamStruct = GetNewReservationParametersStruct(Object.Owner, Object.ClientDoc, AddRoomType, Object.Customer, Object.Contract, Object.Agent, Object.Ref, Object.CheckInDate, Object.CheckOutDate, Object.RoomRate, Object.ServicePackage, Object.ClientType, vStatus, Object.SourceOfBusiness, Object.MarketingCode, Object.TripPurpose, Object.GuaranteeType, Object.DiscountType, Object.Allotment, IsForFolioSplit, Object.Payer, Object.PlannedPaymentMethod, NumberOfAdults, NumberOfKids, vKidsAges, AddNumberOfRooms);
	OpenForm("Document.Reservation.Form.tcDocumentForm", vParamStruct);
	// Hide add reservation group
	Items.GroupAddReservation.Visible = False;
EndProcedure // OpenNewReservationForm

// -----------------------------------------------------------------------------
&AtClient
Procedure NumberOfKidsOnChange(pItem)
	For vNum = 1 To Items.NumberOfKids.MaxValue Do
		Items.AgeDecoration.Visible = (NumberOfKids > 0);
		Items["KidAge" + vNum].Visible = (NumberOfKids >= vNum);
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AddNumberOfRoomsOnChange(Item)
	Items.NumberOfAdultsKids.Visible = (AddNumberOfRooms > 0);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CloseNewReservations(Command)
	Items.GroupAddReservation.Visible = False;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AddRoomTypeStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vAgeArray = New Array;
	For i = 1 To NumberOfKids Do
		vAgeArray.Add(ThisObject["KidAge" + i]);
	EndDo;
	OpenForm("Catalog.RoomTypes.Form.tcChoiceForm", 
	         New Structure("CheckInDate, CheckOutDate, Hotel, RoomRate, IsForFolioSplit, RoomQuantity, NumberOfAdults, NumberOfKids, AgeArray, RoomQuota, ClientType, DiscountType, SourceOfBusiness, MarketingCode, TripPurpose", 
			               Object.CheckInDate, Object.CheckOutDate, Object.Owner, Object.RoomRate, IsForFolioSplit, AddNumberOfRooms, NumberOfAdults, NumberOfKids, vAgeArray, Object.Allotment, Object.ClientType, Object.DiscountType, Object.SourceOfBusiness, Object.MarketingCode, Object.TripPurpose), 
	         pItem, ThisObject.UUID);
EndProcedure // AddRoomTypeStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure AddRoomTypeChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	If TypeOf(pSelectedValue) = Type("Structure") Then
		pStandardProcessing = False;
		AddRoomType = pSelectedValue.RoomType;
		Object.RoomRate = pSelectedValue.RoomRate;
	EndIf;
EndProcedure // AddRoomTypeChoiceProcessing

#EndRegion

#Region Background_Operations

// -----------------------------------------------------------------------------
&AtClient
Procedure BlockForm_ShowProgressBar()
	BackgroundOperationProgress = 0;
	Items.BackgroundOperationProgress.Visible = True;
	Items.Pages.CurrentPage = Items.GroupGuests;
	ReadOnly = True;
	Items.GroupButtons.Enabled = False;
EndProcedure	

// -----------------------------------------------------------------------------
&AtClient
Procedure UnlockForm_HideProgressBar()
	BackgroundOperationProgress = 0;
	Items.BackgroundOperationProgress.Visible = False;
	ReadOnly = False;
	Items.GroupButtons.Enabled = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function GetSessionParameter(pParametrName)	
	Return SessionParameters[pParametrName];	
EndFunction // GetSessionParameter()

#EndRegion

#Region Buttons

// -----------------------------------------------------------------------------
// Add new reservations
// -----------------------------------------------------------------------------
&AtClient
Procedure NewReservation(pCommand)
	// Save group changes if any
	If Modified Then
		If Not Write() Then
			Return;
		EndIf;
	EndIf;
	If GuestGroupTableBox.GetItems().Count() = 0 Then
		OpenNewReservationForm();
	Else
		// Get template document
		vTemplateDoc = Undefined;
		If Items.GuestGroupTableBox.CurrentData <> Undefined Then
			vTemplateDoc = Items.GuestGroupTableBox.CurrentData.MainRef;
			If ValueIsFilled(vTemplateDoc) Then
				AddRoomType = GetDocumentRoomTypeAtServer(vTemplateDoc);
			EndIf;
		EndIf;
		AddNumberOfRooms = 1;
		If NumberOfAdults = 0 Then
			NumberOfAdults = 2;
			NumberOfKids = 0;
		EndIf;
		Items.GroupAddReservation.Visible = True;
		Items.NumberOfAdultsKids.Visible = True;
	EndIf;
EndProcedure // NewReservation

&AtClient
Procedure AddNewReservations(Command)
	// Save group changes if any
	If Modified Then
		If Not Write() Then
			Return;
		EndIf;
	EndIf;
	
	If AddNumberOfRooms = 0 Then
		Items.GroupAddReservation.Visible = False;
		Return;
	EndIf;
	
	If AddNumberOfRooms <= 1 Or AddAsBlock Then
		OpenNewReservationForm();
		
		Items.GroupAddReservation.Visible = False;
		Return;
	EndIf;
	
	// Get template document
	vTemplateDoc = Undefined;
	If Items.GuestGroupTableBox.CurrentData <> Undefined Then
		vTemplateDoc = Items.GuestGroupTableBox.CurrentData.MainRef;
		If TypeOf(vTemplateDoc) = Type("DocumentRef.Accommodation") Then
			vTemplateDoc = GetAccommodationReservationAtServer(vTemplateDoc);
		EndIf;
	EndIf;
	
	// Get first room reservations list
	vOneRoomReservationsList = ProcessFirstNewRoomAtServer(vTemplateDoc);
	If vOneRoomReservationsList = Undefined Then
		OpenNewReservationForm();
		
		Items.GroupAddReservation.Visible = False;
		Return;
	EndIf;
	
	// Copy them 
	vOperationParametrs = New Array;
	vOperationParametrs.Add(vOneRoomReservationsList);
	vOperationParametrs.Add(GetSessionParameter("CurrentUser"));
	vOperationParametrs.Add(AddNumberOfRooms);
	StartProlongedOperation("ProlongedOperations.GuestGroups_AddPacketReservations","en = 'Adding new reservations...'; ru = 'Создание новой брони...'; de = 'Hinzufügen neue reservierungen...'", vOperationParametrs);
	
	// Hide panel
	Items.GroupAddReservation.Visible = False;
	
	// Send notification
	Notify("Document.Reservation.Write", vOneRoomReservationsList.Get(0).Value, ThisObject);
EndProcedure

#EndRegion

#Region Background_job

// -----------------------------------------------------------------------------
&AtClient
Procedure StartProlongedOperation(pFunctionName, pOperationName, pOperationParametrs = Undefined)	
	BlockForm_ShowProgressBar();
	Items.BackgroundOperationProgress.Title	= NStr("en = 'Background operation in progress, you can continue to work in other forms  - '; ru = 'Выполняется фоновая операция, можете продолжать работать в других формах  - '; de = 'Die Hintergrundoperation läuft, Sie können weiterhin in anderen Formen arbeiten - '") + NStr(pOperationName);
	vBackgroundJob = StartBackgroundJob(pOperationName, pFunctionName, pOperationParametrs);
	CurrentBackgroundJobUUID = vBackgroundJob.UUID;
	AttachIdleHandler("Attachable_CheckBackgroundJobs", 1, False);
EndProcedure

// -----------------------------------------------------------------------------
&AtServer                               
Function StartBackgroundJob(pOperationName, pProcedureName, pProcedureParametrs = Undefined, pTempStorageAddress = Undefined)
	ListOfMessages.Clear();
	Return AsyncCalls.StartBackgroundJobWithRecordInRegister(Object.Ref, pOperationName, pProcedureName, pProcedureParametrs,,,pTempStorageAddress);	
EndFunction

// -----------------------------------------------------------------------------
&AtClient
Procedure Attachable_CheckBackgroundJobs()
	vBackgroundJob 				= CheckBackgroundJobStatus(CurrentBackgroundJobUUID);            
	BackgroundOperationProgress = vBackgroundJob.Progress; 
	
	For each msg in vBackgroundJob.Messages Do
		If ListOfMessages.FindByValue(msg) = Undefined then
			ListOfMessages.Add(msg);
			tcCommonFunctionOnClientServer.TextMessage(msg);
		EndIf;
	EndDo;
	
	If vBackgroundJob.Status = "Error" Then 
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Error in background job: '; ru = 'Ошибка выполнения фонового задания: '; de = 'Fehler beim Ausführen des Hintergrundjobs: '") + vBackgroundJob.Error);
		DetachIdleHandler("Attachable_CheckBackgroundJobs");
		UnlockForm_HideProgressBar();
		AttachIdleHandler("RefreshTotals", 1, True);
	ElsIf vBackgroundJob.Status = "Canceled" Then 
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Background job - canceled.'; ru = 'Фоновое задание - отменено.'; de = 'Hintergrundjob - abgebrochen.'"));
		DetachIdleHandler("Attachable_CheckBackgroundJobs");
		UnlockForm_HideProgressBar();
		AttachIdleHandler("RefreshTotals", 1, True);
	ElsIf vBackgroundJob.Status = "Completed" Then
		DetachIdleHandler("Attachable_CheckBackgroundJobs");
		tcOnServer.Wait(1);
		UnlockForm_HideProgressBar();
		AttachIdleHandler("RefreshTotals", 1, True);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RefreshTotals() Export
	Read();
	Totals(Commands.Totals);
	// Save current group period
	SaveCurrentGroupPeriod();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure Totals(pCommand)
	// Save group changes if any
	If Modified Then
		Write();
	EndIf;
	FillGroupList();
	FillTotalColumn();
	FillTotals();
EndProcedure // Totals

// -----------------------------------------------------------------------------
&AtServer
Function CheckBackgroundJobStatus(pBackgroundJobId)
	Return AsyncCalls.CheckBackgroundJob(pBackgroundJobId); 
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Function CheckForExistingBackgroundJobs()
	vRecordSet	= InformationRegisters.BackgroundOperationsInProgress.CreateRecordSet();
	vRecordSet.Filter.Object.Set(Object.Ref);
	vRecordSet.Read();
	vResult = new Array;
	For each vRecord in vRecordSet Do
		vSetTitle = False;
		If NOT vSetTitle Then
			Items.BackgroundOperationProgress.Title = NStr("en = 'Background operation in progress - '; ru = 'Выполняется фоновая операция - '; de = 'Hintergrundoperation ist in Bearbeitung - '") + vRecord.Description;
			vSetTitle = True;
		EndIf;
		vResult.Add(vRecord.OperationUUID); 
	EndDo;
	Return vResult;
EndFunction

#EndRegion

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenFolios(pCommand)
	// Save group changes if any
	If Modified Then
		If Not Write() Then
			Return;
		EndIf;
	EndIf;
	If ValueIsFilled(Object.Ref) Then
		vParametersStructure = New Structure("IsNew, WasPosted, IsFormModified, ObjectRef", False, False, Modified, Object.Ref);
		OpenForm("CommonForm.tcFoliosForm", New Structure("ParametersStructure", vParametersStructure), ThisObject, UUID);
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Save guest group first!'; ru='Сначала сохраните группу!'; de='Speichern Sie die Gruppe zuerst!'"));
	EndIf;
EndProcedure // OpenFolios

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintGroupSettlement(pCommand)
	If Modified Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Save changes first!'; ru='Сначала сохраните изменения!'; de='Speichern Sie die Änderungen zuerst!'"));
		Return;
	EndIf;
	vMessage = "";
	vInvoice = Undefined;
	// Try to search for unposted invoice
	vUnpostedInvoices = GetUnpostedGroupInvoices(Object.Ref);
	If vUnpostedInvoices.Count() > 0 Then
		vInvoice = vUnpostedInvoices.Get(0).Value;
	EndIf;
	// Fill new or refill existing unposted invoice
	vResult = GuestGroupFillSettlement(Object.Ref, vMessage, vInvoice);
	If vResult = -1 Then
		tcCommonFunctionOnClientServer.TextMessage(vMessage);
	Else
		If vResult = 0 Then
			vInvList = GetListOfGroupInvoices(Object.Ref);
			If vInvList.Count() = 0 Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage);
			ElsIf vInvList.Count() = 1 Then
				vInvoice = vInvList.Get(0).Value;
			Else
				vNotifyDescription = New NotifyDescription("PrintInvoiceAfterInvoiceSelection", ThisObject);
				vParams = New Structure("ValueList, MultipleChoice, Title", vInvList, False);
				OpenForm("CommonForm.mcChoiceValueList", vParams, ThisObject, UUID, , , vNotifyDescription);
			EndIf;
		EndIf;
		If ValueIsFilled(vInvoice) Then
			PrintInvoice(vInvoice);
		EndIf;
	EndIf;
EndProcedure // PrintGroupSettlement

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
&AtClient
Procedure PrintInvoiceAfterInvoiceSelection(pItem, pExtraParams) Export
	If pItem <> Undefined Then
		vInvoice = pItem.Value;
		PrintInvoice(vInvoice);
	EndIf;
EndProcedure // PrintInvoiceAfterInvoiceSelection

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
&AtClient
Procedure SplitRoomsFromBlock(pQty = -1)
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToEditReservations") Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You have no permission to edit reservations!'; ru='Нет прав на редактирование брони!'; de='Sie haben keine Erlaubnis, Reservierungen zu bearbeiten!'"));
		Return;
	EndIf;
	vCurData = Items.GuestGroupTableBox.CurrentData;
	If vCurData <> Undefined And ValueIsFilled(vCurData.MainRef) And TypeOf(vCurData.MainRef) = Type("DocumentRef.Reservation") And tcOnServer.cmGetAttributeByRef(vCurData.MainRef, "RoomQuantity") > 1 Then
		vBlockRef = vCurData.MainRef;
		vRoomQuantity = tcOnServer.cmGetAttributeByRef(vBlockRef, "RoomQuantity");
		vQty = 1;
		If pQty = -1 Then
			vQty = vRoomQuantity - 1;
		ElsIf pQty > 0 And pQty < vRoomQuantity Then
			vQty = pQty;
		EndIf;
		// Run operation in background at server
		vOperationParameters = New Array;
		vOperationParameters.Add(vBlockRef);
		vOperationParameters.Add(vQty);
		StartProlongedOperation("ProlongedOperations.GuestGroups_SplitRoomsFromBlock","en = 'Do block splitting...'; ru = 'Разделение блока...'; de = 'Block spalten...'", vOperationParameters);
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Please select block reservation!'; ru='Пожалуйста выберите резервирование блока!'; de='Bitte wählen Sie die Blockreservierung!'"));
	EndIf;
EndProcedure // SplitRoomsFromBlock

// -----------------------------------------------------------------------------
&AtClient
Procedure SplitNRoomsFromBlock(pCommand)
	// Save group changes if any
	If Modified Then
		Write();
	EndIf;
	vN = 1;
	ShowInputNumber(New NotifyDescription("SplitNRoomsFromBlockAfterInput", ThisObject), vN, NStr("en='Input number of rooms to split'; ru='Укажите кол-во номеров'; de='Geben Sie die Anzahl der Zimmer'"), 10, 0);
EndProcedure // SplitNRoomsFromBlock

// -----------------------------------------------------------------------------
&AtClient
Procedure SplitNRoomsFromBlockAfterInput(pInput, pExtraParams) Export
	If pInput <> Undefined And pInput > 0 Then 
		SplitRoomsFromBlock(pInput);
	EndIf;
EndProcedure // SplitNRoomsFromBlockAfterInput

// -----------------------------------------------------------------------------
&AtClient
Procedure SplitBlock(pCommand)
	// Save group changes if any
	If Modified Then
		Write();
	EndIf;
	SplitRoomsFromBlock(-1);
EndProcedure // SplitBlock

// -----------------------------------------------------------------------------
Procedure ChargingRulesAfterDeleteRowAtServer()
	// Get object value
	vObj = FormAttributeToValue("Object");
	// Set planned payment method from the first charging rule
	vObj.Payer = vObj.pmSetPlannedPaymentMethod(vObj.PlannedPaymentMethod);
	// Set object value
	ValueToFormAttribute(vObj, "Object");
	// Fill block totals
	FillAvailableRoomsAtServer();
	// Fill group folio label
	FillGroupFolioAttribute();
EndProcedure // ChargingRulesAfterDeleteRowAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ChargingRulesAfterDeleteRow(pItem)
	ChargingRulesAfterDeleteRowAtServer();
	ChargingRulesWereChanged = True;
EndProcedure // ChargingRulesAfterDeleteRow

// -----------------------------------------------------------------------------
Procedure ChargingRulesOnEditEndAtServer()
	// Get object value
	vObj = FormAttributeToValue("Object");
	// Set planned payment method from the first charging rule
	vObj.Payer = vObj.pmSetPlannedPaymentMethod(vObj.PlannedPaymentMethod);
	// Set object value
	ValueToFormAttribute(vObj, "Object");
	// Fill block totals
	FillAvailableRoomsAtServer();
	// Fill group folio label
	FillGroupFolioAttribute();
EndProcedure // ChargingRulesOnEditEndAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ChargingRulesOnEditEnd(pItem, pNewRow, pCancelEdit)
	ChargingRulesOnEditEndAtServer();
	ChargingRulesWereChanged = True;
EndProcedure // ChargingRulesOnEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomAssignment(pCommand)
	// Save group changes if any
	If Modified Then
		Write();
	EndIf;
	If Not ValueIsFilled(Object.Ref) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Please save group first!'; ru='Сначала сохраните карточку группы!'; de='Speichern Sie zuerst die Gruppenkarte!'"));
		Return;
	EndIf;
	If Not ValueIsFilled(Object.Owner) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Hotel should be selected!'; ru='Гостиница должна быть выбрана!'; de='Hotel sollte ausgewählt werden!'"));
		Return;
	EndIf;
	OpenForm("Document.Reservation.Form.tcRoomAssignmentForm", New Structure("SelHotel, SelGuestGroup", Object.Owner, Object.Ref), ThisObject);
EndProcedure // RoomAssignment

// -----------------------------------------------------------------------------
&AtClient
Procedure NewResourceReservation(pCommand)
	// Save group changes if any
	If Modified Then
		If Not Write() Then
			Return;
		EndIf;
	EndIf;
	OpenForm("Document.ResourceReservation.ObjectForm", New Structure("GuestGroup", Object.Ref), ThisObject, Object.Ref);
EndProcedure // NewResourceReservation

// -----------------------------------------------------------------------------
&AtClient
Procedure CopyResourceReservation(pCommand)
	// Save group changes if any
	If Modified Then
		If Not Write() Then
			Return;
		EndIf;
	EndIf;
	vCurData = Items.GuestGroupResources.CurrentData;
	If vCurData <> Undefined Then
		OpenForm("Document.ResourceReservation.ObjectForm", New Structure("CopyingValue", vCurData.Document), ThisObject, vCurData.Document);
	EndIf;
EndProcedure // CopyResourceReservation

// -----------------------------------------------------------------------------
&AtClient
Procedure EditResourceReservation(Command)
	vCurData = Items.GuestGroupResources.CurrentData;
	If vCurData <> Undefined Then
		// Save group changes if any
		If Modified Then
			If Not Write() Then
				Return;
			EndIf;
		EndIf;
		OpenForm("Document.ResourceReservation.ObjectForm", New Structure("Key", vCurData.Document), ThisObject, vCurData.Document);
	EndIf;
EndProcedure // EditResourceReservation

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupResourcesSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	vCurData = Items.GuestGroupResources.CurrentData;
	If vCurData <> Undefined Then
		OpenForm("Document.ResourceReservation.ObjectForm", New Structure("Key", vCurData.Document), ThisObject, vCurData.Document);
	EndIf;
EndProcedure // GuestGroupResourcesSelection

// --------------------------------------------------------------------------------
&AtServerNoContext
Function IsFileEditable(pExtension)
	Return cmIsFileEditable(pExtension);
EndFunction // IsFileEditable

// -----------------------------------------------------------------------------
&AtServer
Function CreateGroupResumeAtServer()
	// Try to find group resume document in group attachments
	vFileType = "docx";
	// Group object
	vGroupObj = Object.Ref.GetObject();
	// Get group resume document
	vRow = Undefined;
	vRows = vGroupObj.pmGetGuestGroupResumeRecords();
	If vRows.Count() > 0 Then
		// Get group resume row
		vRow = vRows.Get(0);
	Else
		// Create group resume document and add record for it
		vRcdMgr = InformationRegisters.GuestGroupAttachments.CreateRecordManager();
		vRcdMgr.GuestGroup = Object.Ref;
		vRcdMgr.Period = CurrentSessionDate();
		vRcdMgr.Author = SessionParameters.CurrentUser;
		vRcdMgr.AttachmentStatus = Enums.AttachmentStatuses.Ready;
		vRcdMgr.AttachmentType = Enums.AttachmentTypes.GroupResume;
		vRcdMgr.Remarks = Format(Object.Code, "ND=12; NFD=0; NG=") + " " + TrimAll(Object.Description);
		vRcdMgr.FileLoadTime = CurrentSessionDate();
		vRcdMgr.FileLastChangeTime = CurrentSessionDate();
		vRcdMgr.FileName = "GroupResume" + TrimAll(SessionParameters.CurrentLanguage.Code) + "." + vFileType;
		// Build file object
		vResumeFilePath = TempFilesDir() + vRcdMgr.FileName;
		// Get file template
		vFileBinData = Catalogs.GuestGroups.GetTemplate("GroupResume" + TrimAll(SessionParameters.CurrentLanguage.Code) + vFileType);
		vFileBinData.Write(vResumeFilePath);
		// Fill document fields
		vGroupObj.pmGenerateGuestGroupResume(vResumeFilePath, vFileType);
		// Read file data back
		vFileBinData = New BinaryData(vResumeFilePath);
		vRcdMgr.ExtFile = New ValueStorage(vFileBinData);
		// Save row
		vRcdMgr.Write(True);
		// Get row back 
		vRows = vGroupObj.pmGetGuestGroupResumeRecord(vRcdMgr.Period);
		// Get selected row
		If vRows.Count() > 0 Then
			vRow = vRows.Get(0);
		EndIf;
	EndIf;
	If vRow <> Undefined Then
		// Read file binary data from the register
		vReader = InformationRegisters.GuestGroupAttachments.CreateRecordManager();
		vReader.GuestGroup = vRow.GuestGroup;
		vReader.Period = vRow.Period;
		vReader.Read();
		If vReader.Selected() Then
			vFileName = TrimAll(vReader.FileName);
			vBinary = vReader.ExtFile.Get();
			vTempAddr = PutToTempStorage(vBinary);
			Return New Structure("FileName, FileTempStorageAddress", vFileName, vTempAddr);
		EndIf;
	EndIf;
	Return Undefined;
EndFunction // CreateGroupResumeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure CreateGroupResume(pCommand)
	// Save group changes if any
	If Modified Then
		If Not Write() Then
			Return;
		EndIf;
	EndIf;
	vParam = CreateGroupResumeAtServer();
	If vParam <> Undefined Then
		BeginAttachingFileSystemExtension(New NotifyDescription("OpenFileAttachingFileSystemExtensionResult", ThisObject, vParam));
	EndIf;
Endprocedure // CreateGroupResume

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileAttachingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		// Getting temp files dir
		BeginGettingTempFilesDir(New NotifyDescription("OpenFileGettingTempFilesDirCompleted", ThisObject, pParam));
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension is being installing on your browser...'; ru='В браузер устанавливается расширение по работе с файлами...'; de='Dateisystemerweiterung wird in Ihrem Browser installiert...'"), MessageStatus.Information);
		BeginInstallFileSystemExtension(New NotifyDescription("OpenFileFileSystemExtensionInstallCompleted", ThisObject));
	EndIf;
EndProcedure // OpenFileAttachingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileFileSystemExtensionInstallCompleted(pParam) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("OpenFileInstallingFileSystemExtensionResult", ThisObject));
EndProcedure // OpenFileFileSystemExtensionInstallCompleted

// --------------------------------------------------------------------------------
&AtClient 
Procedure OpenFileRunningApplicationCompleted(pReturnCode, pLocalFullFileName) Export
	// If file is editable then ask user to save it back
	vFile = New File(pLocalFullFileName);
	If IsFileEditable(vFile.Extension) Then
		ShowQueryBox(New NotifyDescription("AfterClosedQueryBox", ThisObject, pLocalFullFileName),
		             NStr("en='Save document changes to the database?';ru='Сохранить измененный документ в базу данных?';de='Das geänderte Dokument in der Datenbank speichern?'"), QuestionDialogMode.YesNo);
	EndIf;
EndProcedure // OpenFileRunningApplicationCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileGettingFilesCompleted(pTransferredFiles, pTempFilesDir) Export
	vLocalFullFileName = pTransferredFiles.Get(0).Name;
	// Open temp file in application
	BeginRunningApplication(New NotifyDescription("OpenFileRunningApplicationCompleted", ThisObject, vLocalFullFileName), vLocalFullFileName, pTempFilesDir, False);
EndProcedure // OpenFileGettingFilesCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileGettingTempFilesDirCompleted(pTempFilesDir, pParam) Export
	// Build local temp file name
	vLocalFullFileName = pTempFilesDir + pParam.FileName;
	// Get temp storage address with file data
	vTemStorageAddress = pParam.FileTempStorageAddress;
	// Create array of files to transfer from server to the client
	vFilesToBeObtained = New Array();
	vFileToBeObtained = New TransferableFileDescription(vLocalFullFileName, vTemStorageAddress);
	vFilesToBeObtained.Add(vFileToBeObtained);
	BeginGettingFiles(New NotifyDescription("OpenFileGettingFilesCompleted", ThisObject, pTempFilesDir), vFilesToBeObtained, , False);
EndProcedure // OpenFileGettingTempFilesDirCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileInstallingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension was successfully installed on your browser!'; ru='В браузер успешно установлено расширение по работе с файлами!'; de='Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'"), MessageStatus.Information);
		// Getting temp files dir
		BeginGettingTempFilesDir(New NotifyDescription("OpenFileGettingTempFilesDirCompleted", ThisObject, pParam));
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Your browser does not support file operations in 1C!'; ru='Браузер не поддерживает работу с файлами в 1С!'; de='Ihr Browser unterstützt keine Dateioperationen in 1C!'"), MessageStatus.Attention);
	EndIf;
EndProcedure // OpenFileInstallingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure AfterClosedQueryBox(pResult, pFullFileName) Export
	If pResult = DialogReturnCode.Yes Then
		vFile = New File(pFullFileName);
		vFilesArray = New Array();
		vFileDescription = New TransferableFileDescription(pFullFileName);
		vFilesArray.Add(vFileDescription);
		BeginPuttingFiles(New NotifyDescription("UpdatedFileDownloadToServerCompleted", ThisObject), vFilesArray, , False);
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure UpdatedFileDownloadToServerCompletedAtServer(pTempStorageFileAddress, pParam)
	vBinaryData = GetFromTempStorage(pTempStorageFileAddress);
	AfterClosedQueryBoxAtServer(vBinaryData);
EndProcedure // UpdatedFileDownloadToServerCompletedAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure AfterClosedQueryBoxAtServer(pBinaryData) 
	// Get group resume document
	vRow = Undefined;
	vGroupObj = Object.Ref.GetObject();
	vRows = vGroupObj.pmGetGuestGroupResumeRecords();
	If vRows.Count() > 0 Then
		// Get group resume row
		vRow = vRows.Get(0);
		If vRow <> Undefined Then
			vRcd = InformationRegisters.GuestGroupAttachments.CreateRecordManager();
			FillPropertyValues(vRcd, vRow);
			vRcd.ExtFile = New ValueStorage(pBinaryData);
			vRcd.FileLastChangeTime = CurrentSessionDate();
			vRcd.Write();
		EndIf;
	EndIf;
EndProcedure // AfterClosedQueryBoxAtServer

// --------------------------------------------------------------------------------
&AtClient 
Procedure UpdatedFileDownloadToServerCompleted(pTransferredFiles, pParam) Export
	vTempStorageFileAddress = pTransferredFiles.Get(0).Location;
	UpdatedFileDownloadToServerCompletedAtServer(vTempStorageFileAddress, pParam);
EndProcedure // UpdatedFileDownloadToServerCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure CopyGuestGroupReservations(pCommand)
	// Save group changes if any
	If Modified Then
		If Not Write() Then
			Return;
		EndIf;
	EndIf;
	OpenForm("DataProcessor.CopyGuestGroupReservations.Form.tcFPForm", New Structure("GuestGroupFrom, CheckInDateFrom", Object.Ref, Object.CheckInDate), ThisObject, , , , , FormWindowOpeningMode.Independent);
EndProcedure // CopyGuestGroupReservations

// --------------------------------------------------------------------------------
&AtClient
Procedure GuestGroupTableBoxGuestFullNameStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vCurData = Items.GuestGroupTableBox.CurrentData;
	If vCurData = Undefined Then
		Return;
	EndIf;
	// Get clients search form
	vFrm = GetForm("Catalog.Clients.ChoiceForm", New Structure("ChoiceMode", True), pItem);
	If ValueIsFilled(vCurData.Guest) Then
		vFrm.SelLastName = tcOnServer.cmGetAttributeByRef(vCurData.Guest, "LastName");
		vFrm.SelFirstName = tcOnServer.cmGetAttributeByRef(vCurData.Guest, "FirstName");
		vFrm.SelSecondName = tcOnServer.cmGetAttributeByRef(vCurData.Guest, "SecondName");
	Else
		// Get guest last name, first name and second name
		vSelGuest = pItem.EditText;
		vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
		vLastNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
		vFrm.SelLastName = Title(Left(TrimAll(vSelGuest), vLastNameLastCharNumber));
		If vLastNameLastCharNumber<>StrLen(vSelGuest) Then
			vSelGuest = Mid(TrimAll(vSelGuest), vLastNameLastCharNumber+2, StrLen(vSelGuest));
			vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
			vFirstNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
			vFrm.SelFirstName = Title(Left(TrimAll(vSelGuest), vFirstNameLastCharNumber));
			If vFirstNameLastCharNumber<>StrLen(vSelGuest) Then
				vSelGuest = Mid(TrimAll(vSelGuest), vFirstNameLastCharNumber+2, StrLen(vSelGuest));
				vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
				vSecondNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
				vFrm.SelSecondName = Title(Left(TrimAll(vSelGuest), vSecondNameLastCharNumber));
			EndIf;
		EndIf; 
	EndIf;
	vFrm.Items.List.MultipleChoice = False;
	vFrm.Open();
EndProcedure // GuestGroupTableBoxGuestFullNameStartChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure GuestGroupTableBoxGuestFullNameClearing(pItem, pStandardProcessing)
	vCurData = Items.GuestGroupTableBox.CurrentData;
	If vCurData = Undefined Then
		Return;
	EndIf;
	pStandardProcessing = False;
	vCurData.Guest = Undefined;
	vCurData.GuestFullName = "";
	pItem.TextEdit = True;
	GuestsWereChanged = True;
	Modified = True;
EndProcedure // GuestGroupTableBoxGuestFullNameClearing

// --------------------------------------------------------------------------------
&AtClient
Procedure GuestGroupTableBoxGuestFullNameOpening(pItem, pStandardProcessing)
	vCurData = Items.GuestGroupTableBox.CurrentData;
	If vCurData = Undefined Then
		Return;
	EndIf;
	pStandardProcessing = False;
	// Get client form
	If ValueIsFilled(vCurData.Guest) And (tcOnServer.cmGetAttributeByRef(vCurData.Guest, "FullName") = pItem.EditText) Then
		OpenForm("Catalog.Clients.ObjectForm", New Structure("Key", vCurData.Guest), pItem);
	Else
		vFrm = GetForm("Catalog.Clients.ObjectForm", , pItem, New UUID());
		vSelGuest = pItem.EditText;
		// Get guest last name, first name and second name
		vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
		vLastNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
		vFrm.Object.LastName = Title(Left(TrimAll(vSelGuest), vLastNameLastCharNumber));
		If vLastNameLastCharNumber<>StrLen(vSelGuest) Then
			vSelGuest = Mid(TrimAll(vSelGuest), vLastNameLastCharNumber+2, StrLen(vSelGuest));
			vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
			vFirstNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
			vFrm.Object.FirstName = Title(Left(TrimAll(vSelGuest), vFirstNameLastCharNumber));
			If vFirstNameLastCharNumber<>StrLen(vSelGuest) Then
				vSelGuest = Mid(TrimAll(vSelGuest), vFirstNameLastCharNumber+2, StrLen(vSelGuest));
				vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
				vSecondNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
				vFrm.Object.SecondName = Title(Left(TrimAll(vSelGuest), vSecondNameLastCharNumber));
			EndIf;
		EndIf;
		vFrm.Open();
	EndIf;
EndProcedure // GuestGroupTableBoxGuestFullNameOpening

// --------------------------------------------------------------------------------
&AtClient
Procedure GuestGroupTableBoxGuestFullNameChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	vCurData = Items.GuestGroupTableBox.CurrentData;
	If vCurData = Undefined Then
		Return;
	EndIf;
	pStandardProcessing = False;
	If ValueIsFilled(pSelectedValue) Then
		If TypeOf(pSelectedValue) = Type("CatalogRef.Clients") Then
			vCurData.Guest = pSelectedValue;
			vCurData.GuestFullName = tcOnServer.cmGetAttributeByRef(pSelectedValue, "FullName");
			pItem.TextEdit = False;
		ElsIf TypeOf(pSelectedValue) = Type("String") Then
			vCurData.GuestFullName = pSelectedValue;
			vCurData.Guest = tcOnServer.cmGetCatalogItemRefByCode("Clients", "", True);
			pItem.TextEdit = True;
		EndIf;
	Else
		vCurData.Guest = tcOnServer.cmGetCatalogItemRefByCode("Clients", , True);
		pItem.TextEdit = True;
	EndIf;
	GuestsWereChanged = True;
	Modified = True;
EndProcedure // GuestGroupTableBoxGuestFullNameChoiceProcessing

// --------------------------------------------------------------------------------
&AtClient
Procedure GuestGroupTableBoxGuestFullNameAutoComplete(pItem, pText, pChoiceData, pDataGetParameters, pWait, pStandardProcessing)
	If pWait = 0 Then
		pStandardProcessing = True;
		pChoiceData = Undefined;
	Else
		vCurData = Items.GuestGroupTableBox.CurrentData;
		If vCurData = Undefined Then
			Return;
		EndIf;
		pStandardProcessing = False;
		If ValueIsFilled(vCurData.Guest) And Not IsBlankString(pText) Then
			vCurData.GuestFullName = "";
			vUM = New UserMessage;
			vUM.Text = NStr("en='The data can be changed in the guest card only! (To open the guest card, click the magnifying glass; To write a new guest, click the delete icon and type guest name in the field)';ru='Данные могут быть изменены только в карточке гостя! (Для того, чтобы открыть карточку гостя, нажмите кнопку с изображением лупы; Для того, чтобы создать нового гостя, нажмите кнопку с крестиком и введите ФИО гостя в поле)';de='Die Daten können nur in der Karte des Gastes geändert werden! (Um die Karte des Gastes zu öffnen, drücken Sie die Taste mit der Lupe; um einen neuen Gast zu erstellen, drücken Sie die Taste mit dem Kreuz und geben Sie den Namen und den Vornamen des Gastes ins Feld ein)'");
			vUM.Message();
		Else
			pStandardProcessing = True;
			pChoiceData = Undefined;
		EndIf;
		If Not IsBlankString(pText) Then
			GuestsWereChanged = True;
			Modified = True;
		EndIf;
	EndIf;
EndProcedure // GuestGroupTableBoxGuestFullNameAutoComplete

// --------------------------------------------------------------------------------
&AtClient
Procedure GuestGroupTableBoxGuestFullNameTextEditEnd(pItem, pText, pChoiceData, pDataGetParameters, pStandardProcessing)
	vCurData = Items.GuestGroupTableBox.CurrentData;
	If vCurData = Undefined Then
		Return;
	EndIf;
	pStandardProcessing = False;
	If ValueIsFilled(vCurData.Guest) Then
		pItem.TextEdit = False;
		If IsBlankString(pText) Then
			vCurData.Guest = Undefined;
		Else
			vCurData.GuestFullName = "";
			vUM = New UserMessage;
			vUM.Text = NStr("en='The data can be changed in the guest card only! (To open the guest card, click the magnifying glass; To write a new guest, click the delete icon and type guest name in the field)';ru='Данные могут быть изменены только в карточке гостя! (Для того, чтобы открыть карточку гостя, нажмите кнопку с изображением лупы; Для того, чтобы создать нового гостя, нажмите кнопку с крестиком и введите ФИО гостя в поле)';de='Die Daten können nur in der Karte des Gastes geändert werden! (Um die Karte des Gastes zu öffnen, drücken Sie die Taste mit der Lupe; um einen neuen Gast zu erstellen, drücken Sie die Taste mit dem Kreuz und geben Sie den Namen und den Vornamen des Gastes ins Feld ein)'");
			vUM.Message();
		EndIf;
	Else
		pItem.TextEdit = True;
		If IsBlankString(pText) Then
			pStandardProcessing = False;
			pChoiceData = Undefined;
		ElsIf StrLen(pText) > 2 Then
			vChoiceDataUID = tcOnServer.cmGetGuestsChoiceDataList(pText);
			pChoiceData = GetFromTempStorage(vChoiceDataUID);
			If pChoiceData.Count() = 0 Then
				pChoiceData.Add(pText, NStr("en='--Guest not found--';ru='--Гость не найден--';de='--Gast nicht gefunden--'"));
			Else
				pChoiceData.Insert(0, TrimR(pText));
			EndIf;
		Else
			pStandardProcessing = True;
			pChoiceData = Undefined;
		EndIf;
	EndIf;
	GuestsWereChanged = True;
	Modified = True;
EndProcedure // GuestGroupTableBoxGuestFullNameTextEditEnd

// --------------------------------------------------------------------------------
&AtClient
Procedure GuestGroupTableBoxOnStartEdit(pItem, pNewRow, pClone)
	vCurData = Items.GuestGroupTableBox.CurrentData;
	If vCurData = Undefined Then
		Return;
	EndIf;
	If ValueIsFilled(vCurData.Guest) Then
		Items.GuestGroupTableBoxGuestFullName.TextEdit = False;
	Else
		Items.GuestGroupTableBoxGuestFullName.TextEdit = True;
	EndIf;
EndProcedure // GuestGroupTableBoxOnStartEdit

// --------------------------------------------------------------------------------
&AtClient
Procedure GuestGroupTableBoxBeforeRowChange(pItem, pCancel)
	vCurData = Items.GuestGroupTableBox.CurrentData;
	If vCurData = Undefined Then
		Return;
	EndIf;
	If vCurData.RoomQuantity > 1 Then
		pCancel = True;
	EndIf;
	If Not ValueIsFilled(vCurData.Document) Then
		pCancel = True;
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Save documents first!'; ru='Сначала сохраните документы!'; de='Speichern Sie zuerst die Dokumente!'"));
	EndIf;
EndProcedure // GuestGroupTableBoxBeforeRowChange

// --------------------------------------------------------------------------------
&AtClient
Procedure InitialBlockOnStartEdit(pItem, pNewRow, pClone)
	If pNewRow Then
		Items.InitialBlockRoomType.ReadOnly = False;
		Items.InitialBlockCheckInDate.ReadOnly = False;
		Items.InitialBlockCheckOutDate.ReadOnly = False;
		vCurData = pItem.CurrentData;
		If vCurData <> Undefined Then
			If Not pClone Then
				vCurData.CheckInDate = Object.CheckInDate;
				vCurData.CheckOutDate = Object.CheckOutDate;
			EndIf;
			If vCurData.NumberOfAdults = 0 Then
				vCurData.NumberOfAdults = 1;
			EndIf;
			If Not ValueIsFilled(vCurData.Currency) Then
				vCurData.Currency = tcOnServer.cmGetAttributeByRef(Object.Owner, "BaseCurrency");
			EndIf;
			vCurData.RoomsAvailable = "";
		EndIf;
	Else
		Items.InitialBlockRoomType.ReadOnly = Not Object.IsNewBlock;
		Items.InitialBlockCheckInDate.ReadOnly = Not Object.IsNewBlock;
		Items.InitialBlockCheckOutDate.ReadOnly = Not Object.IsNewBlock;
		vCurData = pItem.CurrentData;
		If vCurData <> Undefined Then
			If vCurData.NumberOfRooms = 0 Then
				Items.InitialBlockRoomType.ReadOnly = False;
				Items.InitialBlockCheckInDate.ReadOnly = False;
				Items.InitialBlockCheckOutDate.ReadOnly = False;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // InitialBlockOnStartEdit

// --------------------------------------------------------------------------------
&AtClient
Procedure InitialBlockOnEditEnd(pItem, pNewRow, pCancelEdit)
	vCurData = pItem.CurrentData;
	If vCurData <> Undefined Then
		vCurData.NumberOfPersons = vCurData.NumberOfRooms * (vCurData.NumberOfAdults + vCurData.NumberOfTeenagers + vCurData.NumberOfChildren + vCurData.NumberOfInfants);
		If ValueIsFilled(vCurData.CheckInDate) And vCurData.CheckInDate < Object.CheckInDate Then
			Object.CheckInDate = vCurData.CheckInDate;
			OldCheckInDate = Object.CheckInDate;
		EndIf;
		If ValueIsFilled(vCurData.CheckOutDate) And vCurData.CheckOutDate > Object.CheckOutDate Then
			Object.CheckOutDate = vCurData.CheckOutDate;
			OldCheckOutDate = Object.CheckOutDate;
		EndIf;
		If vCurData.NumberOfRooms <> 0 Then
			If Object.GroupType = PredefinedValue("Catalog.GroupTypes.Resources") Then
				Object.GroupType = PredefinedValue("Catalog.GroupTypes.RoomsAndResources");
				GroupTypeOnChange(Items.GroupType);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // InitialBlockOnEditEnd

// --------------------------------------------------------------------------------
&AtServer
Procedure CheckInDateOnChangeAtServer()
	If ValueIsFilled(Object.CheckInDate) Then
		If (Object.CheckInDate - BegOfDay(Object.CheckInDate)) = 0 Then
			vRoomRate = Object.RoomRate;
			If Not ValueIsFilled(vRoomRate) And ValueIsFilled(Object.Owner) And ValueIsFilled(Object.Owner.RoomRate) Then
				vRoomRate = Object.Owner.RoomRate;
			EndIf;
			If ValueIsFilled(vRoomRate) Then
				If ValueIsFilled(vRoomRate.DefaultCheckInTime) Then
					Object.CheckInDate = Object.CheckInDate + (vRoomRate.DefaultCheckInTime - BegOfDay(vRoomRate.DefaultCheckInTime));
				ElsIf ValueIsFilled(vRoomRate.ReferenceHour) Then
					Object.CheckInDate = Object.CheckInDate + (vRoomRate.ReferenceHour - BegOfDay(vRoomRate.ReferenceHour));
				EndIf;
			EndIf;
		EndIf;
		Object.CheckInDate = cm1SecondShift(Object.CheckInDate);
		vCheckOutDate = Object.CheckOutDate;
		If (vCheckOutDate - BegOfDay(vCheckOutDate)) = 0 Then
			vRoomRate = Object.RoomRate;
			If Not ValueIsFilled(vRoomRate) And ValueIsFilled(Object.Owner) And ValueIsFilled(Object.Owner.RoomRate) Then
				vRoomRate = Object.Owner.RoomRate;
			EndIf;
			If ValueIsFilled(vRoomRate) Then
				If ValueIsFilled(vRoomRate.DefaultCheckOutTime) Then
					vCheckOutDate = vCheckOutDate + (vRoomRate.DefaultCheckOutTime - BegOfDay(vRoomRate.DefaultCheckOutTime));
				ElsIf ValueIsFilled(vRoomRate.ReferenceHour) Then
					vCheckOutDate = vCheckOutDate + (vRoomRate.ReferenceHour - BegOfDay(vRoomRate.ReferenceHour));
				EndIf;
			EndIf;
		EndIf;
		If Object.Duration <= 0 Then
			Object.Duration = 1;
		EndIf;
		Object.CheckOutDate = cm0SecondShift(BegOfDay(Object.CheckInDate) + (vCheckOutDate - BegOfDay(vCheckOutDate)) + Object.Duration * 24 * 3600);
	Else
		Object.CheckOutDate = '00010101';
	EndIf;
	// Fill block totals
	FillAvailableRoomsAtServer();
	// Update initial block period
	If Object.IsNewBlock Then
		UpdateInitialBlockPeriod();
	EndIf;
	// Save current group period
	SaveCurrentGroupPeriod();
EndProcedure // CheckInDateOnChangeAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure CheckInDateOnChange(pItem)
	CheckInDateOnChangeAtServer();
EndProcedure // CheckInDateOnChange

// --------------------------------------------------------------------------------
&AtServer
Procedure DurationOnChangeAtServer()
	If Object.Duration <= 0 Then
		Object.Duration = 1;
	EndIf;
	If ValueIsFilled(Object.CheckInDate) Then
		vCheckOutDate = Object.CheckOutDate;
		If (vCheckOutDate - BegOfDay(vCheckOutDate)) = 0 Then
			vRoomRate = Object.RoomRate;
			If Not ValueIsFilled(vRoomRate) And ValueIsFilled(Object.Owner) And ValueIsFilled(Object.Owner.RoomRate) Then
				vRoomRate = Object.Owner.RoomRate;
			EndIf;
			If ValueIsFilled(vRoomRate) Then
				If ValueIsFilled(vRoomRate.DefaultCheckOutTime) Then
					vCheckOutDate = vCheckOutDate + (vRoomRate.DefaultCheckOutTime - BegOfDay(vRoomRate.DefaultCheckOutTime));
				ElsIf ValueIsFilled(vRoomRate.ReferenceHour) Then
					vCheckOutDate = vCheckOutDate + (vRoomRate.ReferenceHour - BegOfDay(vRoomRate.ReferenceHour));
				EndIf;
			EndIf;
		EndIf;
		Object.CheckOutDate = cm0SecondShift(BegOfDay(Object.CheckInDate) + (vCheckOutDate - BegOfDay(vCheckOutDate)) + Object.Duration * 24 * 3600);
	Else
		Object.CheckOutDate = '00010101';
	EndIf;
	// Fill block totals
	FillAvailableRoomsAtServer();
	// Update initial block period
	If Object.IsNewBlock Then
		UpdateInitialBlockPeriod();
	EndIf;
	// Save current group period
	SaveCurrentGroupPeriod();
EndProcedure // DurationOnChangeAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure DurationOnChange(pItem)
	DurationOnChangeAtServer();
EndProcedure // DurationOnChange

// --------------------------------------------------------------------------------
&AtServer
Procedure CheckOutDateOnChangeAtServer()
	If ValueIsFilled(Object.CheckOutDate) Then
		vRoomRate = Object.RoomRate;
		If Not ValueIsFilled(vRoomRate) And ValueIsFilled(Object.Owner) And ValueIsFilled(Object.Owner.RoomRate) Then
			vRoomRate = Object.Owner.RoomRate;
		EndIf;
		If ValueIsFilled(vRoomRate) Then
			vCheckOutDate = Object.CheckOutDate;
			If (vCheckOutDate - BegOfDay(vCheckOutDate)) = 0 Then
				If ValueIsFilled(vRoomRate.DefaultCheckOutTime) Then
					vCheckOutDate = vCheckOutDate + (vRoomRate.DefaultCheckOutTime - BegOfDay(vRoomRate.DefaultCheckOutTime));
				ElsIf ValueIsFilled(vRoomRate.ReferenceHour) Then
					vCheckOutDate = vCheckOutDate + (vRoomRate.ReferenceHour - BegOfDay(vRoomRate.ReferenceHour));
				EndIf;
				Object.CheckOutDate = BegOfDay(vCheckOutDate) + (vCheckOutDate - BegOfDay(vCheckOutDate));
			EndIf;
			Object.CheckOutDate = cm0SecondShift(Object.CheckOutDate);
			If BegOfDay(Object.CheckOutDate) > BegOfDay(Object.CheckInDate) Then
				If vRoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByDays Then
					Object.Duration = Round((Object.CheckOutDate - Object.CheckInDate) / (24 * 3600), 0);
				ElsIf vRoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByHours Then
					Object.Duration = Round((Object.CheckOutDate - Object.CheckInDate) / 3600, 0);
				Else
					Object.Duration = Round((BegOfDay(Object.CheckOutDate) - BegOfDay(Object.CheckInDate)) / (24 * 3600), 0);
				EndIf;
			Else
				Object.CheckInDate = cm1SecondShift(Object.CheckOutDate - Object.Duration * 24 * 3600);
				CheckInDateOnChangeAtServer();
			EndIf;
		EndIf;
	Else
		Object.CheckInDate = '00010101';
	EndIf;
	// Fill block totals
	FillAvailableRoomsAtServer();
	// Update initial block period
	If Object.IsNewBlock Then
		UpdateInitialBlockPeriod();
	EndIf;
	// Save current group period
	SaveCurrentGroupPeriod();
EndProcedure // CheckOutDateOnChangeAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure CheckOutDateOnChange(pItem)
	CheckOutDateOnChangeAtServer();
EndProcedure // CheckOutDateOnChange

// --------------------------------------------------------------------------------
&AtServer
Procedure FillAvailableRoomsAtServer()
	If Not ValueIsFilled(Object.GroupType) Or Object.GroupType = Catalogs.GroupTypes.Resources Then
		Return;
	EndIf;
	vPeriodIsFilled = False;
	If ValueIsFilled(Object.Owner) And 
	   ValueIsFilled(Object.CheckInDate) And 
	   ValueIsFilled(Object.CheckOutDate) And 
	   Object.CheckOutDate > Object.CheckInDate Then
		vPeriodIsFilled = True;
	EndIf;
	vHotel = Object.Owner;
	If vPeriodIsFilled Then
		If Object.IsNewBlock Then
			vBalances = Undefined;
			// Fill room types table
			If Object.InitialBlock.Count() = 0 Then
				vAllRoomTypes = cmGetAllRoomTypes(vHotel);
				For Each vAllRoomTypesRow In vAllRoomTypes Do
					vRoomType = vAllRoomTypesRow.RoomType;
					If Not vRoomType.IsVirtual And Not vRoomType.DoesNotAffectRoomRevenueStatistics Then
						Modified = True;
						vIBRow = Object.InitialBlock.Add();
						vIBRow.RoomType = vAllRoomTypesRow.RoomType;
						vIBRow.CheckInDate = cm1SecondShift(Object.CheckInDate);
						vIBRow.CheckOutDate = cm0SecondShift(Object.CheckOutDate);
						vIBRow.NumberOfAdults = 1;
						vIBRow.Currency = vHotel.BaseCurrency;
					EndIf;
				EndDo;
			EndIf;		
			// Get available rooms
			vQry = New Query();
			vQry.Text =	
			"SELECT
			|	BEGINOFPERIOD(RoomInventoryBalance.Period, DAY) AS Period,
			|	RoomInventoryBalance.Hotel AS Hotel,
			|	RoomInventoryBalance.RoomType AS RoomType,
			|	MAX(CASE
			|			WHEN &qRoomQuotaIsSet
			|					AND &qDoWriteOff
			|				THEN ISNULL(RoomQuotaBalances.RoomsInQuota, 0)
			|			WHEN &qRoomQuotaIsSet
			|					AND NOT &qDoWriteOff
			|				THEN ISNULL(RoomInventoryBalance.TotalRoomsClosingBalance, 0)
			|			ELSE ISNULL(RoomInventoryBalance.TotalRoomsClosingBalance, 0)
			|		END) AS TotalRooms,
			|	MAX(CASE
			|			WHEN &qRoomQuotaIsSet
			|					AND &qDoWriteOff
			|				THEN ISNULL(RoomQuotaBalances.BedsInQuota, 0)
			|			WHEN &qRoomQuotaIsSet
			|					AND NOT &qDoWriteOff
			|				THEN ISNULL(RoomInventoryBalance.TotalBedsClosingBalance, 0)
			|			ELSE ISNULL(RoomInventoryBalance.TotalBedsClosingBalance, 0)
			|		END) AS TotalBeds,
			|	MIN(CASE
			|			WHEN &qRoomQuotaIsSet
			|					AND &qDoWriteOff
			|				THEN ISNULL(RoomQuotaBalances.RoomsRemains, 0)
			|			WHEN &qRoomQuotaIsSet
			|					AND NOT &qDoWriteOff
			|					AND ISNULL(RoomInventoryBalance.RoomsVacantClosingBalance, 0) < ISNULL(RoomQuotaBalances.RoomsRemains, 0)
			|				THEN ISNULL(RoomInventoryBalance.RoomsVacantClosingBalance, 0)
			|			WHEN &qRoomQuotaIsSet
			|					AND NOT &qDoWriteOff
			|					AND ISNULL(RoomInventoryBalance.RoomsVacantClosingBalance, 0) >= ISNULL(RoomQuotaBalances.RoomsRemains, 0)
			|				THEN ISNULL(RoomQuotaBalances.RoomsRemains, 0)
			|			ELSE ISNULL(RoomInventoryBalance.RoomsVacantClosingBalance, 0)
			|		END) AS RoomsVacant,
			|	MIN(CASE
			|			WHEN &qRoomQuotaIsSet
			|					AND &qDoWriteOff
			|				THEN ISNULL(RoomQuotaBalances.BedsRemains, 0)
			|			WHEN &qRoomQuotaIsSet
			|					AND NOT &qDoWriteOff
			|					AND ISNULL(RoomInventoryBalance.BedsVacantClosingBalance, 0) < ISNULL(RoomQuotaBalances.BedsRemains, 0)
			|				THEN ISNULL(RoomInventoryBalance.BedsVacantClosingBalance, 0)
			|			WHEN &qRoomQuotaIsSet
			|					AND NOT &qDoWriteOff
			|					AND ISNULL(RoomInventoryBalance.BedsVacantClosingBalance, 0) >= ISNULL(RoomQuotaBalances.BedsRemains, 0)
			|				THEN ISNULL(RoomQuotaBalances.BedsRemains, 0)
			|			ELSE ISNULL(RoomInventoryBalance.BedsVacantClosingBalance, 0)
			|		END) AS BedsVacant
			|INTO VacantRoomsDetailed
			|FROM
			|	(SELECT
			|		BEGINOFPERIOD(DATEADD(RoomInventoryBalanceAndTurnovers.Period, SECOND, &qShiftInSeconds), DAY) AS Period,
			|		RoomInventoryBalanceAndTurnovers.Hotel AS Hotel,
			|		RoomInventoryBalanceAndTurnovers.RoomType AS RoomType,
			|		MAX(RoomInventoryBalanceAndTurnovers.CounterClosingBalance) AS CounterClosingBalance,
			|		MAX(ISNULL(RoomInventoryBalanceAndTurnovers.TotalRoomsClosingBalance, 0)) AS TotalRoomsClosingBalance,
			|		MAX(ISNULL(RoomInventoryBalanceAndTurnovers.TotalBedsClosingBalance, 0)) AS TotalBedsClosingBalance,
			|		MIN(ISNULL(RoomInventoryBalanceAndTurnovers.RoomsVacantClosingBalance, 0)) AS RoomsVacantClosingBalance,
			|		MIN(ISNULL(RoomInventoryBalanceAndTurnovers.BedsVacantClosingBalance, 0)) AS BedsVacantClosingBalance
			|	FROM
			|		AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qDateTimeFrom, &qDateTimeTo, Minute, RegisterRecordsAndPeriodBoundaries, Hotel = &qHotel) AS RoomInventoryBalanceAndTurnovers
			|	
			|	GROUP BY
			|		BEGINOFPERIOD(DATEADD(RoomInventoryBalanceAndTurnovers.Period, SECOND, &qShiftInSeconds), DAY),
			|		RoomInventoryBalanceAndTurnovers.Hotel,
			|		RoomInventoryBalanceAndTurnovers.RoomType) AS RoomInventoryBalance
			|		LEFT JOIN (SELECT
			|			BEGINOFPERIOD(RoomQuotaSalesBalanceAndTurnovers.Period, DAY) AS Period,
			|			RoomQuotaSalesBalanceAndTurnovers.Hotel AS Hotel,
			|			RoomQuotaSalesBalanceAndTurnovers.RoomType AS RoomType,
			|			RoomQuotaSalesBalanceAndTurnovers.CounterClosingBalance AS CounterClosingBalance,
			|			RoomQuotaSalesBalanceAndTurnovers.RoomsInQuotaClosingBalance AS RoomsInQuota,
			|			RoomQuotaSalesBalanceAndTurnovers.BedsInQuotaClosingBalance AS BedsInQuota,
			|			RoomQuotaSalesBalanceAndTurnovers.RoomsRemainsClosingBalance AS RoomsRemains,
			|			RoomQuotaSalesBalanceAndTurnovers.BedsRemainsClosingBalance AS BedsRemains
			|		FROM
			|			AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
			|					&qDateTimeFrom,
			|					&qDateTimeTo,
			|					Day,
			|					RegisterRecordsAndPeriodBoundaries,
			|					Hotel = &qHotel
			|						AND &qRoomQuotaIsSet
			|						AND RoomQuota = &qRoomQuota) AS RoomQuotaSalesBalanceAndTurnovers) AS RoomQuotaBalances
			|		ON RoomInventoryBalance.Hotel = RoomQuotaBalances.Hotel
			|			AND RoomInventoryBalance.RoomType = RoomQuotaBalances.RoomType
			|			AND (BEGINOFPERIOD(RoomInventoryBalance.Period, DAY) = BEGINOFPERIOD(RoomQuotaBalances.Period, DAY))
			|
			|GROUP BY
			|	BEGINOFPERIOD(RoomInventoryBalance.Period, DAY),
			|	RoomInventoryBalance.Hotel,
			|	RoomInventoryBalance.RoomType
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	ExpectedGuestGroupsTurnovers.Hotel AS Hotel,
			|	ExpectedGuestGroupsTurnovers.RoomType AS RoomType,
			|	ExpectedGuestGroupsTurnovers.Period AS Period,
			|	ExpectedGuestGroupsTurnovers.RoomsReservedTurnover AS PreliminaryRooms,
			|	ExpectedGuestGroupsTurnovers.BedsReservedTurnover AS PreliminaryBeds
			|INTO PreliminaryReservations
			|FROM
			|	AccumulationRegister.ExpectedGuestGroups.Turnovers(
			|			&qDateFrom,
			|			&qDateTo,
			|			Day,
			|			&qShowPreliminary
			|				AND Hotel = &qHotel
			|				AND CASE
			|					WHEN RoomQuota = VALUE(Catalog.RoomQuotas.EmptyRef)
			|						THEN TRUE
			|					WHEN GuestGroup <> VALUE(Catalog.GuestGroups.EmptyRef)
			|						THEN TRUE
			|					WHEN NOT ISNULL(RoomQuota.DoWriteOff, FALSE)
			|						THEN TRUE
			|					ELSE FALSE
			|				END
			|				AND (&qRoomQuotaIsSet
			|						AND RoomQuota = &qRoomQuota
			|					OR NOT &qRoomQuotaIsSet)) AS ExpectedGuestGroupsTurnovers
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	Availability.Hotel AS Hotel,
			|	Availability.Hotel.SortCode AS HotelSortCode,
			|	Availability.RoomType AS RoomType,
			|	Availability.RoomType.SortCode AS RoomTypeSortCode,
			|	MAX(Availability.TotalRooms) AS TotalRooms,
			|	MAX(Availability.TotalBeds) AS TotalBeds,
			|	MIN(Availability.RoomsVacant) AS RoomsVacant,
			|	MIN(Availability.BedsVacant) AS BedsVacant,
			|	MIN(Availability.VacantWithPreliminaryRooms) AS VacantWithPreliminaryRooms,
			|	MIN(Availability.VacantWithPreliminaryBeds) AS VacantWithPreliminaryBeds
			|FROM
			|	(SELECT
			|		RoomInventory.Period AS Period,
			|		RoomInventory.Hotel AS Hotel,
			|		RoomInventory.Hotel.SortCode AS HotelSortCode,
			|		RoomInventory.RoomType AS RoomType,
			|		RoomInventory.RoomType.SortCode AS RoomTypeSortCode,
			|		RoomInventory.TotalRooms AS TotalRooms,
			|		RoomInventory.TotalBeds AS TotalBeds,
			|		RoomInventory.RoomsVacant AS RoomsVacant,
			|		RoomInventory.BedsVacant AS BedsVacant,
			|		RoomInventory.RoomsVacant - ISNULL(PreliminaryReservations.PreliminaryRooms, 0) AS VacantWithPreliminaryRooms,
			|		RoomInventory.BedsVacant - ISNULL(PreliminaryReservations.PreliminaryBeds, 0) AS VacantWithPreliminaryBeds
			|	FROM
			|		VacantRoomsDetailed AS RoomInventory
			|			LEFT JOIN PreliminaryReservations AS PreliminaryReservations
			|			ON RoomInventory.Period = PreliminaryReservations.Period
			|				AND RoomInventory.Hotel = PreliminaryReservations.Hotel
			|				AND RoomInventory.RoomType = PreliminaryReservations.RoomType
			|	WHERE
			|		NOT RoomInventory.RoomType.DeletionMark) AS Availability
			|
			|GROUP BY
			|	Availability.Hotel,
			|	Availability.Hotel.SortCode,
			|	Availability.RoomType,
			|	Availability.RoomType.SortCode
			|
			|ORDER BY
			|	HotelSortCode,
			|	RoomTypeSortCode";
			vQry.SetParameter("qHotel", vHotel);
			vQry.SetParameter("qRoomQuota", Object.Allotment);
			vQry.SetParameter("qRoomQuotaIsSet", ValueIsFilled(Object.Allotment));
			vQry.SetParameter("qDoWriteOff", ?(ValueIsFilled(Object.Allotment), Object.Allotment.DoWriteOff, False));
			vQry.SetParameter("qDateTimeFrom", cm1SecondShift(Object.CheckInDate));
			vQry.SetParameter("qDateTimeTo", cm0SecondShift(Object.CheckOutDate));
			vQry.SetParameter("qDateFrom", BegOfDay(Object.CheckInDate));
			vQry.SetParameter("qDateTo", EndOfDay(Object.CheckOutDate));
			vQry.SetParameter("qShiftInSeconds", ?(ValueIsFilled(Object.RoomRate), -(Object.RoomRate.ReferenceHour - BegOfDay(Object.RoomRate.ReferenceHour)), -43200));
			vQry.SetParameter("qShowPreliminary", True);
			vBalances = vQry.Execute().Unload();
			For Each vIBRow In Object.InitialBlock Do
				If ValueIsFilled(vIBRow.RoomType) Then
					vBalancesRow = vBalances.Find(vIBRow.RoomType);
					If vBalancesRow <> Undefined Then
						If vBalancesRow.RoomsVacant <> vBalancesRow.VacantWithPreliminaryRooms Then
							vIBRow.RoomsAvailable = Format(vBalancesRow.RoomsVacant, "NFD=0; NZ=; NG=") + " / " + Format(vBalancesRow.VacantWithPreliminaryRooms, "NFD=0; NZ=; NG=");
						Else
							vIBRow.RoomsAvailable = Format(vBalancesRow.RoomsVacant, "NFD=0; NZ=; NG=");
						EndIf;
						vIBRow.ActualRooms = "";
						vIBRow.PickedUpRooms = "";
						vIBRow.NotPickedUpRooms = "";
					Else
						vIBRow.RoomsAvailable = "";
						vIBRow.ActualRooms = "";
						vIBRow.PickedUpRooms = "";
						vIBRow.NotPickedUpRooms = "";
					EndIf;
				Else
					vIBRow.RoomsAvailable = "";
					vIBRow.ActualRooms = "";
					vIBRow.PickedUpRooms = "";
					vIBRow.NotPickedUpRooms = "";
				EndIf;
			EndDo;
		Else
			// Get table of actual room type/period combinations
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	GroupData.RoomType AS RoomType,
			|	GroupData.CheckInDate AS CheckInDate,
			|	GroupData.CheckOutDate AS CheckOutDate,
			|	GroupData.NumberOfAdults AS NumberOfAdults,
			|	GroupData.NumberOfTeenagers AS NumberOfTeenagers,
			|	GroupData.NumberOfChildren AS NumberOfChildren,
			|	GroupData.NumberOfInfants AS NumberOfInfants,
			|	SUM(CASE
			|			WHEN GroupData.RoomQuantity > 1
			|				THEN GroupData.ActualRooms
			|			ELSE 0
			|		END) AS NotPickedUpRooms,
			|	SUM(CASE
			|			WHEN GroupData.RoomQuantity <= 1
			|				THEN GroupData.ActualRooms
			|			ELSE 0
			|		END) AS PickedUpRooms,
			|	SUM(GroupData.ActualRooms) AS ActualRooms
			|FROM
			|	(SELECT
			|		GroupTotals.RoomType AS RoomType,
			|		GroupTotals.CheckInDate AS CheckInDate,
			|		GroupTotals.CheckOutDate AS CheckOutDate,
			|		GroupTotals.RoomQuantity AS RoomQuantity,
			|		GroupTotals.NumberOfAdults AS NumberOfAdults,
			|		GroupTotals.NumberOfTeenagers AS NumberOfTeenagers,
			|		GroupTotals.NumberOfChildren AS NumberOfChildren,
			|		GroupTotals.NumberOfInfants AS NumberOfInfants,
			|		SUM(GroupTotals.ActualRooms) AS ActualRooms
			|	FROM
			|		(SELECT
			|			CASE
			|				WHEN Reservations.RoomTypeUpgrade.BaseRoomType = Reservations.RoomType
			|					THEN Reservations.RoomTypeUpgrade
			|				ELSE Reservations.RoomType
			|			END AS RoomType,
			|			BEGINOFPERIOD(Reservations.CheckInDate, DAY) AS CheckInDate,
			|			BEGINOFPERIOD(Reservations.CheckOutDate, DAY) AS CheckOutDate,
			|			Reservations.AccommodationTemplate.NumberOfAdults AS NumberOfAdults,
			|			Reservations.AccommodationTemplate.NumberOfTeenagers AS NumberOfTeenagers,
			|			Reservations.AccommodationTemplate.NumberOfChildren AS NumberOfChildren,
			|			Reservations.AccommodationTemplate.NumberOfInfants AS NumberOfInfants,
			|			Reservations.RoomQuantity AS RoomQuantity,
			|			CASE
			|				WHEN Reservations.NumberOfRooms > 0
			|					THEN Reservations.NumberOfRooms
			|				WHEN Reservations.NumberOfBeds > 0
			|						AND Reservations.NumberOfBedsPerRoom > 0
			|						AND Reservations.NumberOfRooms = 0
			|					THEN Reservations.NumberOfBeds / Reservations.NumberOfBedsPerRoom
			|				ELSE 0
			|			END AS ActualRooms
			|		FROM
			|			Document.Reservation AS Reservations
			|		WHERE
			|			Reservations.Posted
			|			AND (Reservations.ReservationStatus.IsActive
			|					OR Reservations.ReservationStatus.IsPreliminary)
			|			AND NOT Reservations.ReservationStatus.IsCheckIn
			|			AND Reservations.GuestGroup = &qGuestGroup
			|			AND Reservations.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
			|		
			|		UNION ALL
			|		
			|		SELECT
			|			CASE
			|				WHEN Accommodations.RoomTypeUpgrade.BaseRoomType = Accommodations.RoomType
			|					THEN Accommodations.RoomTypeUpgrade
			|				ELSE Accommodations.RoomType
			|			END,
			|			BEGINOFPERIOD(Accommodations.CheckInDate, DAY),
			|			BEGINOFPERIOD(Accommodations.CheckOutDate, DAY),
			|			Accommodations.AccommodationTemplate.NumberOfAdults,
			|			Accommodations.AccommodationTemplate.NumberOfTeenagers,
			|			Accommodations.AccommodationTemplate.NumberOfChildren,
			|			Accommodations.AccommodationTemplate.NumberOfInfants,
			|			1,
			|			CASE
			|				WHEN Accommodations.NumberOfRooms > 0
			|					THEN Accommodations.NumberOfRooms
			|				WHEN Accommodations.NumberOfBeds > 0
			|						AND Accommodations.NumberOfBedsPerRoom > 0
			|						AND Accommodations.NumberOfRooms = 0
			|					THEN Accommodations.NumberOfBeds / Accommodations.NumberOfBedsPerRoom
			|				ELSE 0
			|			END
			|		FROM
			|			Document.Accommodation AS Accommodations
			|		WHERE
			|			Accommodations.Posted
			|			AND Accommodations.AccommodationStatus.IsActive
			|			AND Accommodations.GuestGroup = &qGuestGroup
			|			AND Accommodations.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)) AS GroupTotals
			|	
			|	GROUP BY
			|		GroupTotals.RoomType,
			|		GroupTotals.CheckInDate,
			|		GroupTotals.CheckOutDate,
			|		GroupTotals.RoomQuantity,
			|		GroupTotals.NumberOfAdults,
			|		GroupTotals.NumberOfTeenagers,
			|		GroupTotals.NumberOfChildren,
			|		GroupTotals.NumberOfInfants) AS GroupData
			|
			|GROUP BY
			|	GroupData.RoomType,
			|	GroupData.CheckInDate,
			|	GroupData.CheckOutDate,
			|	GroupData.NumberOfAdults,
			|	GroupData.NumberOfTeenagers,
			|	GroupData.NumberOfChildren,
			|	GroupData.NumberOfInfants";
			vQry.SetParameter("qHotel", vHotel);
			vQry.SetParameter("qGuestGroup", Object.Ref);
			vPeriods = vQry.Execute().Unload();
			// Fill number of actual block rooms, number of picked up and not picked up rooms
			For Each vPeriodsRow In vPeriods Do
				// Try to find row with the same room type and period
				vPeriodIsFound = False;
				For Each vIBRow In Object.InitialBlock Do
					If vIBRow.RoomType = vPeriodsRow.RoomType And 
					   BegOfDay(vIBRow.CheckInDate) = vPeriodsRow.CheckInDate And 
					   BegOfDay(vIBRow.CheckOutDate) = vPeriodsRow.CheckOutDate And 
					   vIBRow.NumberOfAdults = vPeriodsRow.NumberOfAdults And
					   vIBRow.NumberOfTeenagers = vPeriodsRow.NumberOfTeenagers And
					   vIBRow.NumberOfChildren = vPeriodsRow.NumberOfChildren And
					   vIBRow.NumberOfInfants = vPeriodsRow.NumberOfInfants Then
						vPeriodIsFound = True;
						vIBRow.RoomsAvailable = "";
						vIBRow.ActualRooms = Format(vPeriodsRow.ActualRooms, "NFD=0; NG=");
						vIBRow.PickedUpRooms = Format(vPeriodsRow.PickedUpRooms, "NFD=0; NG=");
						vIBRow.NotPickedUpRooms = Format(vPeriodsRow.NotPickedUpRooms, "NFD=0; NG=");
					EndIf;
				EndDo;
				If Not vPeriodIsFound Then
					Modified = True;
					vIBRow = Object.InitialBlock.Add();
					vIBRow.RoomType = vPeriodsRow.RoomType;
					vIBRow.CheckInDate = cm1SecondShift(vPeriodsRow.CheckInDate + (Object.CheckInDate - BegOfDay(Object.CheckInDate)));
					vIBRow.CheckOutDate = cm0SecondShift(vPeriodsRow.CheckOutDate + (Object.CheckOutDate - BegOfDay(Object.CheckOutDate)));
					vIBRow.NumberOfAdults = vPeriodsRow.NumberOfAdults;
					vIBRow.NumberOfTeenagers = vPeriodsRow.NumberOfTeenagers;
					vIBRow.NumberOfChildren = vPeriodsRow.NumberOfChildren;
					vIBRow.NumberOfInfants = vPeriodsRow.NumberOfInfants;
					vIBRow.Currency = vHotel.BaseCurrency;
					vIBRow.RoomsAvailable = "";
					vIBRow.ActualRooms = Format(vPeriodsRow.ActualRooms, "NFD=0; NG=");
					vIBRow.PickedUpRooms = Format(vPeriodsRow.PickedUpRooms, "NFD=0; NG=");
					vIBRow.NotPickedUpRooms = Format(vPeriodsRow.NotPickedUpRooms, "NFD=0; NG=");
				EndIf;
			EndDo;
			// Remove empty not used rows
			vNum = 0;
			While vNum < Object.InitialBlock.Count() Do
				vIBRow = Object.InitialBlock.Get(vNum);
				If vIBRow.NumberOfRooms = 0 And TrimAll(vIBRow.ActualRooms) = "" And vIBRow.Price = 0 Then
					Object.InitialBlock.Delete(vNum);
				Else
					vNum = vNum + 1;
				EndIf;
			EndDo;
		EndIf;
	Else
		For Each vIBRow In Object.InitialBlock Do
			vIBRow.RoomsAvailable = "";
			vIBRow.ActualRooms = "";
			vIBRow.PickedUpRooms = "";
			vIBRow.NotPickedUpRooms = "";
		EndDo;
	EndIf;
EndProcedure // FillAvailableRoomsAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure GroupTypeOnChangeAtServer()
	If ValueIsFilled(Object.Owner) And Not Items.Status.ReadOnly Then
		If Object.GroupType = Catalogs.GroupTypes.Resources Then
			If ValueIsFilled(Object.Owner.NewResourcesGroupStatus) Then
				Object.Status = Object.Owner.NewResourcesGroupStatus;
			EndIf;
		Else
			If ValueIsFilled(Object.Status) And TypeOf(Object.Status) = Type("CatalogRef.ResourceReservationStatuses") Then
				If ValueIsFilled(Object.Owner.NewRoomsGroupStatus) Then
					Object.Status = Object.Owner.NewRoomsGroupStatus;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	SetNewBlockModeAppearance();
EndProcedure // GroupTypeOnChangeAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure GroupTypeOnChange(pItem)
	GroupTypeOnChangeAtServer();
EndProcedure // GroupTypeOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure GuestGroupChange(pCommand)
	If Modified Then
		If Not Write() Then
			Return;
		EndIf;
	EndIf;
	vResult = GetGroupDocumentsListAll();
	OpenForm("Catalog.GuestGroups.Form.tcChangeRequisites",New Structure("Owner, CheckInDate, CheckOutDate, RefList, RefListCount, ObjGroupRef, SelHotel, SelContract", Object.Owner, Object.CheckInDate, Object.CheckOutDate, vResult.RefList, vResult.Count, Object.Ref, Object.Owner, Object.Contract), ThisObject, UUID);
EndProcedure // GuestGroupChange

// -----------------------------------------------------------------------------
&AtServer
Function GetGroupDocumentsListAll()
	vCount = 0;
	vRefList = New ValueList();
	vQryResult = GetGroupDocuments(Object.Ref);
	For Each vQryResultRow In vQryResult Do
		vRefList.Add(vQryResultRow.Reservation,,False);
	EndDo;
	If Items.GuestGroupTableBox.SelectedRows.Count() > 0 Then
		For Each vSelRowIndex In Items.GuestGroupTableBox.SelectedRows Do
			vRowData = GuestGroupTableBox.FindById(vSelRowIndex);
			If vRefList.FindByValue(vRowData.Document) <> Undefined Then
				vRefList.FindByValue(vRowData.Document).Check = True;
				vCount = vCount + 1;
			EndIf;
			vChildItems = vRowData.GetItems();
			For Each vChildItem In vChildItems Do
				If vRefList.FindByValue(vChildItem.Document) <> Undefined Then
					vRefList.FindByValue(vChildItem.Document).Check = True;
					vCount = vCount + 1;
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	vResult = New Structure("RefList, Count", vRefList, vCount);
	Return vResult;
EndFunction // GetGroupDocumentsList

// -----------------------------------------------------------------------------
&AtServer
Function CreateInitialBlockReservationsAtServer(pTemplateDoc)
	HasErrors = False;
	// Do some checks
	vObject = FormAttributeToValue("Object");
	SetObjectAndFormAttributeConformity(vObject, "Object");
	If Not ValueIsFilled(vObject.Owner) Then
		vUM = New UserMessage();
		vUM.SetData(vObject);
		vUM.Field = "Owner";
		vUM.Text = NStr("en='Please choose current hotel at the home page first!';ru='На домашнем экране не выбрана гостиница!';de='Auf dem Startbildschirm ist kein Hotel ausgewählt!'");
		vUM.Message();
		Return False;
	EndIf;
	For Each vBlockRow In Object.InitialBlock Do
		If Not ValueIsFilled(vBlockRow.RoomType) Then
			vUM = New UserMessage();
			vUM.SetData(vObject);
			vUM.Field = "InitialBlock[" + Format(vBlockRow.GetID(), "NFD=0; NG=") + "].RoomType";
			vUM.Text = NStr("en='Room type could not be empty!';ru='Тип номера должен быть указан!';de='Der Zimmertyp muss angegeben werden!'");
			vUM.Message();
			Return False;
		EndIf;
		If Not ValueIsFilled(vBlockRow.CheckInDate) Then
			vUM = New UserMessage();
			vUM.SetData(vObject);
			vUM.Field = "InitialBlock[" + Format(vBlockRow.GetID(), "NFD=0; NG=") + "].CheckInDate";
			vUM.Text = NStr("en='Please fill in the start date of the booking period!';ru='Заполните дату начала периода бронирования пожалуйста!';de='Bitte füllen Sie das Sartdatum des buchungszeitraums aus!'");
			vUM.Message();
			Return False;
		EndIf;
		If Not ValueIsFilled(vBlockRow.CheckOutDate) Then
			vUM = New UserMessage();
			vUM.SetData(vObject);
			vUM.Field = "InitialBlock[" + Format(vBlockRow.GetID(), "NFD=0; NG=") + "].CheckOutDate";
			vUM.Text = NStr("en='Please fill in the end date of the booking period!';ru='Заполните дату окончания периода бронирования пожалуйста!';de='Bitte füllen Sie das Enddatum des buchungszeitraums aus!'");
			vUM.Message();
			Return False;
		EndIf;
		If vBlockRow.CheckOutDate <= vBlockRow.CheckInDate Then
			vUM = New UserMessage();
			vUM.SetData(vObject);
			vUM.Field = "InitialBlock[" + Format(vBlockRow.GetID(), "NFD=0; NG=") + "].CheckOutDate";
			vUM.Text = NStr("en='End date of the booking period should be after the start date!';ru='Дата окончания периода бронирования должна быть позже даты начала!';de='Das Enddatum des buchungszeitraums muss später als das Startdatum sein!'");
			vUM.Message();
			Return False;
		EndIf;
		If vBlockRow.NumberOfRooms > 0 And vBlockRow.NumberOfPersons = 0 Then
			vUM = New UserMessage();
			vUM.SetData(vObject);
			vUM.Field = "InitialBlock[" + Format(vBlockRow.GetID(), "NFD=0; NG=") + "].NumberOfAdults";
			vUM.Text = NStr("en='Specify number of guests per room please!';ru='Укажите количество гостей в номере пожалуйста!';de='Bitte geben Sie die Anzahl der Gäste pro Zimmer an!'");
			vUM.Message();
			Return False;
		EndIf;
		// Get accommodation template for the given number of adults/children
		If vBlockRow.NumberOfRooms > 0 And vBlockRow.NumberOfPersons > 0 Then
			vAccTemplate = cmGetAccommodationTemplate(vBlockRow.RoomType, vBlockRow.NumberOfAdults, vBlockRow.NumberOfTeenagers, vBlockRow.NumberOfChildren, vBlockRow.NumberOfInfants, vBlockRow.IsForFolioSplit);
			If Not ValueIsFilled(vAccTemplate) Then
				vUM = New UserMessage();
				vUM.SetData(vObject);
				vUM.Field = "InitialBlock[" + Format(vBlockRow.GetID(), "NFD=0; NG=") + "].RoomType";
				vUM.Text = NStr("en='Could not find accommodation template for the given room type and number of adults/children!';ru='Не удалось найти шаблон размещения для данного типа номера и количества взрослых/детей!';de='Konnte keine Unterkunfttemplate finden für die angegebene Zimmerkategorie und der Anzahl der Erwachsenen/Kinder!'");
				vUM.Message();
				Return False;
			EndIf;
		EndIf;
	EndDo;
	
	// Create block reservations
	Try
		vReservationsWereCreated = False;
		BeginTransaction(DataLockControlMode.Managed);
		For Each vBlockRow In vObject.InitialBlock Do
			If vBlockRow.NumberOfRooms > 0 And vBlockRow.NumberOfPersons > 0 Then
				// Get accommodation template for the given number of adults/children
				vAccTemplate = cmGetAccommodationTemplate(vBlockRow.RoomType, vBlockRow.NumberOfAdults, vBlockRow.NumberOfTeenagers, vBlockRow.NumberOfChildren, vBlockRow.NumberOfInfants, vBlockRow.IsForFolioSplit);
				
				// Get first room reservations list
				pTemplateDoc = Undefined;
				vOneRoomReservationsList = ProcessFirstNewRoomAtServer(pTemplateDoc, vAccTemplate, vBlockRow.RoomType, vBlockRow.NumberOfRooms, vBlockRow.CheckInDate, vBlockRow.CheckOutDate);
				vReservationsWereCreated = True;
				
				// Hide panel
				Items.GroupAddReservation.Visible = False;
			EndIf;
		EndDo;
		CommitTransaction();
		If vReservationsWereCreated Then
			If ValueIsFilled(vObject.GroupType) And vObject.GroupType = Catalogs.GroupTypes.Resources Then
				vObject.GroupType = Catalogs.GroupTypes.RoomsAndResources;
			EndIf;
		EndIf;
	Except
		vErrorText = cmGetRootErrorDescription(ErrorInfo());
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		vUM = New UserMessage();
		vUM.SetData(vObject);
		vUM.Field = "InitialBlock";
		vUM.Text = vErrorText;
		vUM.Message();
		Return False;
	EndTry;
	
	// Reset is new block flag
	vObject.Read();
	vObject.IsNewBlock = False;
	// Remove empty not used rows
	vNum = 0;
	While vNum < vObject.InitialBlock.Count() Do
		vIBRow = vObject.InitialBlock.Get(vNum);
		If vIBRow.NumberOfRooms = 0 And vIBRow.Price = 0 Then
			vObject.InitialBlock.Delete(vNum);
		Else
			vNum = vNum + 1;
		EndIf;
	EndDo;
	vObject.Write();
	
	ValueToFormAttribute(vObject, "Object");
	Return True;
EndFunction // CreateInitialBlockReservationsAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure CreateInitialBlockReservations(pCommand, pSilentMode = False)
	If ValueIsFilled(Object.Status) And DoCreateInitialBlockReservations(Object.Status) Then
		vTemplateDoc = Undefined;
		If Not CreateInitialBlockReservationsAtServer(vTemplateDoc) Then
			If Object.IsNewBlock Then
				HasErrors = True;
				FillAvailableRoomsAtServer();
			EndIf;
		Else
			// Send notification
			If ValueIsFilled(vTemplateDoc) Then
				Notify("Document.Reservation.Write", vTemplateDoc, ThisObject);
			EndIf;
		EndIf;
	Else
		If Not pSilentMode Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Group status should be definitive or tentative!'; ru='Статус группы должен быть действующий или предварительный!'; de='Gruppenstatus sollte definitive oder tentative sein!'"));
		EndIf;
	EndIf;
EndProcedure // CreateInitialBlockReservations

// -----------------------------------------------------------------------------
&AtClient
Procedure IsNewBlockOnChange(pItem)
	SetNewBlockModeAppearance();
EndProcedure // IsNewBlockOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure InitialBlockBeforeDeleteRow(pItem, pCancel)
	vCurData = pItem.CurrentData;
	If vCurData <> Undefined Then
		If Not Object.IsNewBlock And (vCurData.NumberOfRooms <> 0 Or Not IsBlankString(vCurData.ActualRooms)) Then
			pCancel = True;
		EndIf;
	EndIf;
EndProcedure // InitialBlockBeforeDeleteRow

// -----------------------------------------------------------------------------
&AtClient
Procedure StatusOnChange(pItem)
	SetGuaranteeTypeAppearance();
	If Not Items.Status.ReadOnly Then
		FillReservationStatusListChoice();
	EndIf;
EndProcedure // StatusOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure FillReservationStatusListChoice()
	vTransitionsAllowed = New ValueList();
	If ValueIsFilled(Object.Status) Then
		vTransitionsAllowed.LoadValues(Object.Status.TransitionsAllowed.UnloadColumn("ReservationStatus"));
	EndIf;
	Items.Status.ChoiceList.Clear();
	vUserHasRightsToCloseReservationWithoutSave = cmCheckUserPermissions("HavePermissionToCloseNewReservationWithoutSave");
	vReservationStatusesArray = New Array;
	vReservationStatusesArray = GetAllReservationStatuses();
	vNum = 0;
	While vNum < vReservationStatusesArray.Count() Do
		vReservationStatus = vReservationStatusesArray.Get(vNum);
		If vReservationStatus.IsCheckIn Then
			vReservationStatusesArray.Delete(vNum);
		ElsIf vUserHasRightsToCloseReservationWithoutSave And Not ValueIsFilled(Object.Ref) And Not vReservationStatus.IsActive And Not vReservationStatus.IsPreliminary And Not vReservationStatus.DoNotCreateReservationsInBlock Then
			vReservationStatusesArray.Delete(vNum);
		Else
			vNum = vNum + 1;
		EndIf;
	EndDo;
	If vTransitionsAllowed.Count() > 0 Then
		For Each vReservationStatus In vReservationStatusesArray Do
			If vTransitionsAllowed.FindByValue(vReservationStatus) <> Undefined Then
				Items.Status.ChoiceList.Add(vReservationStatus, , , GetReservationStatusIcon(vReservationStatus));
			EndIf;
		EndDo;
	Else
		For Each vReservationStatus In vReservationStatusesArray Do
			Items.Status.ChoiceList.Add(vReservationStatus, , , GetReservationStatusIcon(vReservationStatus));
		EndDo;
	EndIf;
	If ValueIsFilled(Object.Status) And Items.Status.ChoiceList.FindByValue(Object.Status) = Undefined Then
		Items.Status.ChoiceList.Add(Object.Status, , , GetReservationStatusIcon(Object.Status));
	EndIf;
EndProcedure // FillReservationStatusListChoice

// -----------------------------------------------------------------------------
&AtServer
Function GetReservationStatusIcon(pReservationStatus)
	vPicture = PictureLib.Empty;
	If ValueIsFilled(pReservationStatus) And TypeOf(pReservationStatus) = Type("CatalogRef.ReservationStatuses") Then
		If pReservationStatus.DoNotCreateReservationsInBlock Then
			vPicture = PictureLib.YellowCube;
		ElsIf pReservationStatus.IsActive Then
			If pReservationStatus.IsGuaranteed Then
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
		ElsIf pReservationStatus.IsInWaitingList Then
			vPicture = PictureLib.Waiting;
		Else
			vPicture = PictureLib.IsNotActive;
		EndIf;
	EndIf;
	Return vPicture;
EndFunction // GetReservationStatusIcon

// -----------------------------------------------------------------------------
&AtServer
Function GetAllReservationStatuses()
	vReservationStatusesArray = New Array;
	vResStses = cmGetAllReservationStatuses();
	For Each vResSts In vResStses Do
		// Fill choice array
		vReservationStatusesArray.Add(vResSts.ReservationStatus);
	EndDo;
	Return vReservationStatusesArray;
EndFunction // GetAllReservationStatuses

// -----------------------------------------------------------------------------
&AtClient
Procedure AllotmentCreating(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.RoomQuotas.ObjectForm", New Structure("Description, PeriodFrom, PeriodTo", Object.Description, BegOfDay(Object.CheckInDate), BegOfDay(Object.CheckOutDate)), pItem, Object.Ref);
EndProcedure // AllotmentCreating

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowAvailability(pCommand)
	If ValueIsFilled(Object.Allotment) Then
		If ValueIsFilled(Object.CheckInDate) And ValueIsFilled(Object.CheckOutDate) And Object.CheckOutDate >= Object.CheckInDate Then
			OpenForm("Catalog.RoomQuotas.Form.tcAllotmentVacantRooms", New Structure("Hotel, Allotment, PeriodFrom, NumberOfDays", Object.Owner, Object.Allotment, BegOfDay(Object.CheckInDate), (BegOfDay(Object.CheckOutDate) - BegOfDay(Object.CheckInDate)) / (24 * 3600) + 2), ThisObject, Object.Allotment);
		Else
			OpenForm("Catalog.RoomQuotas.Form.tcAllotmentVacantRooms", New Structure("Hotel, Allotment", Object.Owner, Object.Allotment), ThisObject, Object.Allotment);
		EndIf;
	EndIf;
EndProcedure // ShowAvailability

// -----------------------------------------------------------------------------
&AtClient
Procedure ReleaseTimeOnChange(pItem)
	If Object.ReleaseTime <> 0 Then
		If Not ValueIsFilled(Object.CheckInDate) Then
			Object.ReleaseTime = 0;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Check-in date is not specified!'; ru='Дата заезда не указана!'; de='Kein Anreisedatum!'"));
		ElsIf BegOfDay(Object.CheckInDate - 24*3600*Object.ReleaseTime) < BegOfDay(CurrentDate()) Then
			Object.ReleaseTime = 0;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Cutoff date is in the past!'; ru='Дата освобождения в прошлом!'; de='Cutoff Datum ist Vergangenheit!'"));
		Else
			Object.ReleaseDate = '00010101';
		EndIf;
	EndIf;
EndProcedure // ReleaseTimeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ReleaseDateOnChange(pItem)
	If ValueIsFilled(Object.ReleaseDate) Then
		If Not ValueIsFilled(Object.CheckInDate) Then
			Object.ReleaseDate = '00010101';
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Check-in date is not specified!'; ru='Дата заезда не указана!'; de='Kein Anreisedatum!'"));
		ElsIf Object.ReleaseDate > Object.CheckInDate Then
			Object.ReleaseDate = '00010101';
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Cutoff date is after check-in date!'; ru='Дата освобождения позже даты заезда!'; de='Cutoff Datum nach dem Anreisedatum!'"));
		ElsIf Object.ReleaseDate < BegOfDay(CurrentDate()) Then
			Object.ReleaseDate = '00010101';
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Cutoff date is in the past!'; ru='Дата освобождения в прошлом!'; de='Cutoff Datum ist Vergangenheit!'"));
		Else
			Object.ReleaseTime = 0;
		EndIf;
	EndIf;
EndProcedure // ReleaseDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure InitialBlockCheckInDateOnChange(pItem)
	vCurData = Items.InitialBlock.CurrentData;
	If vCurData <> Undefined Then
		If ValueIsFilled(vCurData.CheckInDate) And ValueIsFilled(Object.CheckInDate) Then
			If (vCurData.CheckInDate - BegOfDay(vCurData.CheckInDate)) = 1 And (Object.CheckInDate - BegOfDay(Object.CheckInDate)) <> 1 Then
				vCurData.CheckInDate = BegOfDay(vCurData.CheckInDate) + (Object.CheckInDate - BegOfDay(Object.CheckInDate));
			EndIf;
		EndIf;
	EndIf;
EndProcedure // InitialBlockCheckInDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure InitialBlockCheckOutDateOnChange(pItem)
	vCurData = Items.InitialBlock.CurrentData;
	If vCurData <> Undefined Then
		If ValueIsFilled(vCurData.CheckOutDate) And ValueIsFilled(Object.CheckOutDate) Then
			If (vCurData.CheckOutDate - BegOfDay(vCurData.CheckOutDate)) = 0 And (Object.CheckOutDate - BegOfDay(Object.CheckOutDate)) <> 0 Then
				vCurData.CheckOutDate = BegOfDay(vCurData.CheckOutDate) + (Object.CheckOutDate - BegOfDay(Object.CheckOutDate));
			EndIf;
		EndIf;
	EndIf;
EndProcedure // InitialBlockCheckOutDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure InitialBlockBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder, pParameter)
	If Not ValueIsFilled(Object.CheckInDate) Or Not ValueIsFilled(Object.CheckOutDate) Then
		pCancel = True;
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Please specify reservation period in the group header!'; ru='Укажите период бронирования в заголовке группы!'; de='Geben Sie den Buchungszeitraum im Gruppenkopf an!'"));
	ElsIf Object.CheckInDate >= Object.CheckOutDate Then
		pCancel = True;
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Group period is wrong!'; ru='Неправильно указан период бронирования группы!'; de='Der Buchungszeitraum der Gruppe ist falsch!'"));
	EndIf;
EndProcedure // InitialBlockBeforeAddRow

// -----------------------------------------------------------------------------
&AtServer
Procedure BuildBlockGridAtServer()
	// Hide all date columns
	For vNum = 1 To 31 Do
		Items["BlockGridDate" + vNum].Visible = False;
	EndDo;
	// Fill grid table
	BlockGrid.Clear();
	For Each vIBRow In Object.InitialBlock Do
		If Not ValueIsFilled(vIBRow.ActualRooms) And Not ValueIsFilled(vIBRow.NumberOfRooms) Then
			Continue;
		EndIf;
		// Find/add room type row
		vGRow = Undefined;
		vGridRows = BlockGrid.FindRows(New Structure("RoomType", vIBRow.RoomType));
		If vGridRows.Count() = 0 Then
			vGRow = BlockGrid.Add();
			vGRow.RoomType = vIBRow.RoomType;
		Else
			vGRow = vGridRows.Get(0);
		EndIf;
		// Fill grid
		If vGRow <> Undefined Then
			vNum = 1;
			vCurDate = BegOfDay(Object.CheckInDate);
			While vCurDate < BegOfDay(Object.CheckOutDate) Do
				If vCurDate < BegOfDay(vIBRow.CheckInDate) Then
					vCurDate = vCurDate + 24*3600;
					vNum = vNum + 1;
					Continue;
				ElsIf vCurDate >= BegOfDay(vIBRow.CheckOutDate) Then
					Break;
				Else
					vRooms = 0;
					If Object.IsNewBlock Then
						vRooms = Number(vIBRow.NumberOfRooms);
					Else
						vRooms = Number(?(IsBlankString(vIBRow.ActualRooms), 0, vIBRow.ActualRooms));
					EndIf;
					vGRow["Date" + vNum] = vGRow["Date" + vNum] + vRooms;
					Items["BlockGridDate" + vNum].Title = Format(vCurDate, "DF=dd.MM");
					Items["BlockGridDate" + vNum].Visible = True;
				EndIf;
				vCurDate = vCurDate + 24*3600;
				vNum = vNum + 1;
			EndDo;
		EndIf;
	EndDo;
	// Fill grid footer
	vLastColIsProcessed = -1;
	For vNum = 1 To 31 Do
		Items["BlockGridDate" + vNum].FooterText = Format(BlockGrid.Total("Date"+vNum), "NFD=0; NG=");
		If Items["BlockGridDate" + vNum].Visible And vLastColIsProcessed = -1 Then
			vLastColIsProcessed = 0;
		ElsIf Not Items["BlockGridDate" + vNum].Visible And vLastColIsProcessed = 0 Then
			vLastColIsProcessed = 1;
			Items["BlockGridDate" + vNum].Title = " ";
			Items["BlockGridDate" + vNum].Width = 0;
			Items["BlockGridDate" + vNum].Visible = True;
		EndIf;
	EndDo;
EndProcedure // BuildBlockGridAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure GroupInitialBlockPagesOnCurrentPageChange(pItem, pCurrentPage)
	If pCurrentPage = Items.GroupGrid Then
		BuildBlockGridAtServer();
	EndIf;
EndProcedure // GroupInitialBlockPagesOnCurrentPageChange

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetKidsAgeArray(pHotel, pRoomRate, pNumberOfTeenagers, pNumberOfChildren, pNumberOfInfants)
	vKidsAgeArray = New Array;
	For vNum = 1 To pNumberOfTeenagers Do
		vKidsAgeArray.Add(pHotel.TeenagersMaxAge);
	EndDo;
	For vNum = 1 To pNumberOfChildren Do
		vKidsAgeArray.Add(pHotel.ChildrenMaxAge);
	EndDo;
	For vNum = 1 To pNumberOfInfants Do
		vKidsAgeArray.Add(pHotel.InfantsMaxAge);
	EndDo;
	Return vKidsAgeArray;
EndFunction // GetKidsAgeArray

// -----------------------------------------------------------------------------
&AtClient
Procedure InitialBlockRoomTypeStartChoice(pItem, pChoiceData, pStandardProcessing)
	vCurData = Items.InitialBlock.CurrentData;
	If vCurData <> Undefined Then
		pStandardProcessing = False;
		vNumberOfKids = vCurData.NumberOfTeenagers + vCurData.NumberOfChildren + vCurData.NumberOfInfants;
		vKidsAgeArray = GetKidsAgeArray(Object.Owner, Object.RoomRate, vCurData.NumberOfTeenagers, vCurData.NumberOfChildren, vCurData.NumberOfInfants);
		vParams = New Structure("Hotel, RoomType, CheckInDate, CheckOutDate, Duration, RoomRate, ClientType, RoomQuota, NumberOfAdults, NumberOfKids, AgeArray", 
		                         Object.Owner, vCurData.RoomType, ?(ValueIsFilled(vCurData.CheckInDate), vCurData.CheckInDate, Object.CheckInDate), ?(ValueIsFilled(vCurData.CheckOutDate), vCurData.CheckOutDate, Object.CheckOutDate), ?(ValueIsFilled(vCurData.CheckInDate) And ValueIsFilled(vCurData.CheckOutDate), (BegOfDay(vCurData.CheckOutDate) - BegOfDay(vCurData.CheckInDate))/(24*3600), Object.Duration), Object.RoomRate, Object.ClientType, Object.Allotment, vCurData.NumberOfAdults, vNumberOfKids, vKidsAgeArray);
		vFrm = OpenForm("Catalog.RoomTypes.Form.tcChoiceForm", vParams, pItem, , WindowOpenVariant.SingleWindow);
	EndIf;
EndProcedure // RoomTypeStartChoice

// -----------------------------------------------------------------------------
&AtServer
Procedure FillAvailableRoomTypesAtServer()
	// Fill block totals
	FillAvailableRoomsAtServer();
	// Update initial block period
	If Object.IsNewBlock Then
		UpdateInitialBlockPeriod();
	EndIf;
	// Save current group period
	SaveCurrentGroupPeriod();
EndProcedure // FillAvailableRoomTypesAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure FillAvailableRoomTypes(pCommand)
	FillAvailableRoomTypesAtServer();
EndProcedure // FillAvailableRoomTypes

// -----------------------------------------------------------------------------
&AtServer
Procedure FillTasksPresentation()
	TTasks = "";
	If ValueIsFilled(Object.Ref) Then
		vTasks = cmGetMessagesForObject(Object.Ref);
		For Each vTasksRow In vTasks Do
			TTasks = TTasks + "• " + TrimAll(vTasksRow.Remarks) + Chars.LF;
			If vTasks.IndexOf(vTasksRow) > 4 Then
				TTasks = TTasks + "• " + "..." + Chars.LF;
				Break;
			EndIf;
		EndDo;
	EndIf;
	TTasks = TrimAll(TTasks);
	Items.DecorationTasks.Title = TTasks;
	If IsBlankString(TTasks) Then
		Items.DecorationTasks.Visible = False;
	Else
		Items.DecorationTasks.Visible = True;
	EndIf;
EndProcedure // FillTasksPresentation

// -----------------------------------------------------------------------------
&AtClient
Procedure NewTask(Command)
	If ValueIsFilled(Object.Ref) Then
		stParam = New Structure("SetParamObject", Object.Ref);
		OpenForm("Document.Message.Form.tcDocumentForm", stParam);
	EndIf;
EndProcedure // NewTask

// -----------------------------------------------------------------------------
&AtClient
Procedure DecorationTasksClick(pItem)
	Task();
EndProcedure // DecorationVerticalSpacingClick

// -----------------------------------------------------------------------------
&AtClient
Procedure Task()
	stParam = New Structure("SetParamObject", Object.Ref);
	OpenForm("DataProcessor.Messages.Form.tcForm", stParam);
	Notify("DataProcessor.Messages.Form.Open", stParam);
EndProcedure // Task

// -----------------------------------------------------------------------------
&AtServer
Procedure RoomRateOnChangeAtServer()
	If Object.IsNewBlock Then
		vRoomRate = Object.RoomRate;
		If ValueIsFilled(vRoomRate) Then
			If ValueIsFilled(vRoomRate.DefaultCheckInTime) Then
				Object.CheckInDate = BegOfDay(Object.CheckInDate) + (vRoomRate.DefaultCheckInTime - BegOfDay(vRoomRate.DefaultCheckInTime));
			ElsIf ValueIsFilled(vRoomRate.ReferenceHour) Then
				Object.CheckInDate = BegOfDay(Object.CheckInDate) + (vRoomRate.ReferenceHour - BegOfDay(vRoomRate.ReferenceHour));
			EndIf;
			Object.CheckInDate = cm1SecondShift(Object.CheckInDate);
			If ValueIsFilled(vRoomRate.DefaultCheckOutTime) Then
				Object.CheckOutDate = BegOfDay(Object.CheckOutDate) + (vRoomRate.DefaultCheckOutTime - BegOfDay(vRoomRate.DefaultCheckOutTime));
			ElsIf ValueIsFilled(vRoomRate.ReferenceHour) Then
				Object.CheckOutDate = BegOfDay(Object.CheckOutDate) + (vRoomRate.ReferenceHour - BegOfDay(vRoomRate.ReferenceHour));
			EndIf;
			Object.CheckOutDate = cm0SecondShift(Object.CheckOutDate);
			If BegOfDay(Object.CheckOutDate) > BegOfDay(Object.CheckInDate) Then
				If vRoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByDays Then
					Object.Duration = Round((Object.CheckOutDate - Object.CheckInDate) / (24 * 3600), 0);
				ElsIf vRoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByHours Then
					Object.Duration = Round((Object.CheckOutDate - Object.CheckInDate) / 3600, 0);
				Else
					Object.Duration = Round((BegOfDay(Object.CheckOutDate) - BegOfDay(Object.CheckInDate)) / (24 * 3600), 0);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // RoomRateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRateOnChange(pItem)
	RoomRateOnChangeAtServer();
EndProcedure // RoomRateOnChange
