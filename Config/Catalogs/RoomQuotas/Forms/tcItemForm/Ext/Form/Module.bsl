// -----------------------------------------------------------------------------
&AtServer
Procedure FillGuestGroups()
	If Not ValueIsFilled(Object.Ref) Then
		// it's new allotment 
		Return;
	EndIf;
	If Object.AllotmentBusinessType <> Enums.AllotmentBusinessTypes.BusinessBlock Then
		// list of guest group is used only for this type of allotment
		Return;
	EndIf;
	
	vQ = New Query("SELECT DISTINCT
	               |	RoomInventoryGroups.GuestGroup AS GuestGroup
	               |INTO RoomInventoryGroups
	               |FROM
	               |	(SELECT DISTINCT
	               |		RoomInventory.GuestGroup AS GuestGroup
	               |	FROM
	               |		AccumulationRegister.RoomInventory AS RoomInventory
	               |	WHERE
	               |		RoomInventory.GuestGroup.Allotment = &qAllotment
	               |		AND (RoomInventory.IsCheckIn
	               |				OR RoomInventory.IsReservation)
	               |	
	               |	UNION ALL
	               |	
	               |	SELECT DISTINCT
	               |		RoomInventory.GuestGroup
	               |	FROM
	               |		AccumulationRegister.RoomInventory AS RoomInventory
	               |	WHERE
	               |		RoomInventory.RoomQuota = &qAllotment
	               |		AND (RoomInventory.IsCheckIn
	               |				OR RoomInventory.IsReservation)) AS RoomInventoryGroups
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	GroupTotals.GuestGroup.Status AS Status,
	               |	GroupTotals.GuestGroup AS GuestGroup,
	               |	GroupTotals.GuestGroup.Description AS GuestGroupDescription,
	               |	GroupTotals.GuestGroup.Code AS GuestGroupCode,
	               |	GroupTotals.GuestGroup.CheckInDate AS DateFrom,
	               |	GroupTotals.GuestGroup.CheckOutDate AS DateTo,
	               |	GroupTotals.GuestGroup.Allotment AS Allotment,
	               |	GroupTotals.GuestGroup.Customer AS Customer,
	               |	CASE
	               |		WHEN GroupTotals.RoomsCheckedIn <> 0
	               |			THEN TRUE
	               |		WHEN GroupTotals.ExpectedRoomsCheckedIn <> 0
	               |			THEN TRUE
	               |		WHEN GroupTotals.GroupType = VALUE(Catalog.GroupTypes.RoomsAndResources)
	               |			THEN TRUE
	               |		WHEN GroupTotals.GroupType = VALUE(Catalog.GroupTypes.Rooms)
	               |			THEN TRUE
	               |		ELSE ISNULL(GroupTotals.GroupType.IsForRooms, TRUE)
	               |	END AS IsForRooms,
	               |	SUM(GroupTotals.ExpectedRoomsCheckedIn + GroupTotals.RoomsCheckedIn) AS RoomsReserved,
	               |	SUM(GroupTotals.RoomsCheckedIn) AS RoomsCheckedIn,
	               |	SUM(GroupTotals.ExpectedRoomsCheckedIn) AS RoomsExpected
	               |FROM
	               |	(SELECT
	               |		RoomInventory.GuestGroup AS GuestGroup,
	               |		RoomInventory.GuestGroup.GroupType AS GroupType,
	               |		SUM(RoomInventory.ExpectedRoomsCheckedIn) AS ExpectedRoomsCheckedIn,
	               |		SUM(RoomInventory.RoomsCheckedIn) AS RoomsCheckedIn
	               |	FROM
	               |		AccumulationRegister.RoomInventory AS RoomInventory
	               |			INNER JOIN RoomInventoryGroups AS RoomInventoryGroups
	               |			ON RoomInventory.GuestGroup = RoomInventoryGroups.GuestGroup
	               |	WHERE
	               |		(RoomInventory.IsCheckIn
	               |				OR RoomInventory.IsReservation)
	               |	
	               |	GROUP BY
	               |		RoomInventory.GuestGroup,
	               |		RoomInventory.GuestGroup.GroupType
	               |	
	               |	UNION ALL
	               |	
	               |	SELECT
	               |		GuestGroups.Ref,
	               |		GuestGroups.GroupType,
	               |		0,
	               |		0
	               |	FROM
	               |		Catalog.GuestGroups AS GuestGroups
	               |	WHERE
	               |		GuestGroups.Allotment = &qAllotment
	               |		AND NOT GuestGroups.DeletionMark
	               |		AND NOT GuestGroups.IsFolder) AS GroupTotals
	               |WHERE
	               |	CASE
	               |			WHEN GroupTotals.RoomsCheckedIn <> 0
	               |				THEN TRUE
	               |			WHEN GroupTotals.ExpectedRoomsCheckedIn <> 0
	               |				THEN TRUE
	               |			WHEN GroupTotals.GroupType = VALUE(Catalog.GroupTypes.RoomsAndResources)
	               |				THEN TRUE
	               |			WHEN GroupTotals.GroupType = VALUE(Catalog.GroupTypes.Rooms)
	               |				THEN TRUE
	               |			ELSE ISNULL(GroupTotals.GroupType.IsForRooms, TRUE)
	               |		END
	               |
	               |GROUP BY
	               |	GroupTotals.GuestGroup.Status,
	               |	GroupTotals.GuestGroup,
	               |	GroupTotals.GuestGroup.Description,
	               |	GroupTotals.GuestGroup.Code,
	               |	GroupTotals.GuestGroup.CheckInDate,
	               |	GroupTotals.GuestGroup.CheckOutDate,
	               |	GroupTotals.GuestGroup.Allotment,
	               |	GroupTotals.GuestGroup.Customer,
	               |	CASE
	               |		WHEN GroupTotals.RoomsCheckedIn <> 0
	               |			THEN TRUE
	               |		WHEN GroupTotals.ExpectedRoomsCheckedIn <> 0
	               |			THEN TRUE
	               |		WHEN GroupTotals.GroupType = VALUE(Catalog.GroupTypes.RoomsAndResources)
	               |			THEN TRUE
	               |		WHEN GroupTotals.GroupType = VALUE(Catalog.GroupTypes.Rooms)
	               |			THEN TRUE
	               |		ELSE ISNULL(GroupTotals.GroupType.IsForRooms, TRUE)
	               |	END
	               |
	               |ORDER BY
	               |	DateFrom,
	               |	GuestGroupCode");
	vQ.SetParameter("qAllotment", Object.Ref);
	qRes = vQ.Execute().Select();
	
	GuestGroups.Clear();
	While qRes.Next() Do
		row = GuestGroups.Add();
		row.Status = qRes.Status;
		row.Payer = qRes.Customer;
		row.GuestGroup = qRes.GuestGroup;
		row.GuestGroupDescription = qRes.GuestGroupDescription;
		row.DateFrom = qRes.DateFrom; 
		row.DateTo = qRes.DateTo; 
		row.Rooms = qRes.RoomsReserved;
	EndDo;
	
	TotalRoomsPickup = GuestGroups.Total("Rooms");
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillEvents()
	If Not ValueIsFilled(Object.Ref) Then
		Return;
	EndIf;
	If Object.AllotmentBusinessType <> Enums.AllotmentBusinessTypes.BusinessBlock Then
		// list of guest group is used only for this type of allotment
		Return;
	EndIf;
	
	vQ = New Query("SELECT
	               |	EventGroups.GuestGroup.Status AS Status,
	               |	EventGroups.GuestGroup AS GuestGroup,
	               |	EventGroups.GuestGroup.Description AS GuestGroupDescription,
	               |	EventGroups.GuestGroup.Code AS GuestGroupCode,
	               |	EventGroups.GuestGroup.Customer AS Customer,
	               |	MIN(EventGroups.DateTimeFrom) AS DateTimeFrom,
	               |	MAX(EventGroups.DateTimeTo) AS DateTimeTo,
	               |	MAX(EventGroups.NumberOfPersons) AS NumberOfPersons
	               |FROM
	               |	(SELECT
	               |		ResourceReservations.GuestGroup AS GuestGroup,
	               |		MIN(ResourceReservations.DateTimeFrom) AS DateTimeFrom,
	               |		MAX(ResourceReservations.DateTimeTo) AS DateTimeTo,
	               |		MAX(ResourceReservations.NumberOfPersons) AS NumberOfPersons
	               |	FROM
	               |		Document.ResourceReservation AS ResourceReservations
	               |	WHERE
	               |		ResourceReservations.GuestGroup.Allotment = &qAllotment
	               |		AND ResourceReservations.Posted
	               |		AND NOT ResourceReservations.GuestGroup.DeletionMark
	               |	
	               |	GROUP BY
	               |		ResourceReservations.GuestGroup
	               |	
	               |	UNION ALL
	               |	
	               |	SELECT
	               |		GuestGroups.Ref,
	               |		GuestGroups.CheckInDate,
	               |		GuestGroups.CheckOutDate,
	               |		0
	               |	FROM
	               |		Catalog.GuestGroups AS GuestGroups
	               |	WHERE
	               |		GuestGroups.Allotment = &qAllotment
	               |		AND NOT GuestGroups.DeletionMark
	               |		AND NOT GuestGroups.IsFolder
	               |		AND CASE
	               |				WHEN ISNULL(GuestGroups.GroupType.IsForEvents, FALSE)
	               |					THEN TRUE
	               |				WHEN GuestGroups.Ref = VALUE(Catalog.GroupTypes.RoomsAndResources)
	               |					THEN TRUE
	               |				WHEN GuestGroups.Ref = VALUE(Catalog.GroupTypes.Resources)
	               |					THEN TRUE
	               |				ELSE FALSE
	               |			END) AS EventGroups
	               |
	               |GROUP BY
	               |	EventGroups.GuestGroup.Status,
	               |	EventGroups.GuestGroup,
	               |	EventGroups.GuestGroup.Description,
	               |	EventGroups.GuestGroup.Code,
	               |	EventGroups.GuestGroup.Customer
	               |
	               |ORDER BY
	               |	DateTimeFrom,
	               |	GuestGroupCode");
	vQ.SetParameter("qAllotment",Object.Ref);
	qRes = vQ.Execute().Select();
	
	Events.Clear();
	While qRes.Next() Do
		row  = Events.Add();
		row.Status = qRes.Status;
		row.Payer = qRes.Customer;
		row.GuestGroup = qRes.GuestGroup; 
		row.GuestGroupDescription = qRes.GuestGroupDescription;
		row.Persons = qRes.NumberOfPersons;
		row.DateFrom = qRes.DateTimeFrom;
		row.DateTo = qRes.DateTimeTo;
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	// Initialize hotel
	tcOnServer.cmInitHotel(Object);

	OldPeriodFrom = '00010101';
	OldPeriodTo = '00010101';

	PeriodFromOnOpen = '00010101';
	PeriodToOnOpen = '00010101';
	
	DoBudgetRecalculation = False;
	
	// Check user rights to use item
	vObject = FormAttributeToValue("Object");
	If Not ValueIsFilled(vObject.Ref) Then  
		If Parameters.Property("SelHotel") Then
			vObject.Hotel = Parameters.SelHotel; 	
		EndIf;
		If Parameters.Property("AllotmentBusinessType") And ValueIsFilled(Parameters.AllotmentBusinessType) Then
			vObject.AllotmentBusinessType = Parameters.AllotmentBusinessType;
		EndIf;
		If Parameters.Property("Parent") And ValueIsFilled(Parameters.Parent) Then
			vObject.Parent = Parameters.Parent; 	
		EndIf;
		If vObject.AllotmentBusinessType = Enums.AllotmentBusinessTypes.BusinessBlock And Not cmCheckUserPermissions("HavePermissionToManageBusinessBlocks") Then
			pCancel = True;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to manage business blocks!';ru='Нет прав на управление бизнес-блоками!';de='Sie haben keine Rechte, Geschäftsblocken zu verwalten!'"));
			Return;
		ElsIf vObject.AllotmentBusinessType <> Enums.AllotmentBusinessTypes.BusinessBlock And Not cmCheckUserPermissions("HavePermissionToManageAllotments") Then
			pCancel = True;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to manage allotments!';ru='Нет прав на управление квотами!';de='Sie haben keine Rechte, Allotmenten zu verwalten!'"));
			Return;
		Else
			vObject.pmFillAttributesWithDefaultValues();
			If ValueIsFilled(vObject.Parent) Then
				vObject.AllotmentType = vObject.Parent.AllotmentType;
				vObject.DoWriteOff = vObject.Parent.DoWriteOff;
				vObject.TreatAsTentativeBooking = vObject.Parent.TreatAsTentativeBooking;
			EndIf;
		EndIf;
	Else
		j = 0;
		While j < vObject.RoomTypes.Count() Do
			vCurData = vObject.RoomTypes.Get(j);
			If vCurData.RoomQuantity <> 0 And Not vCurData.RoomQuantityIsNotZero Then
				vCurData.RoomQuantityIsNotZero = True;
				ThisObject.Modified = True;
			ElsIf vCurData.RoomQuantity = 0 And vCurData.RoomQuantityIsNotZero Then
				vCurData.RoomQuantityIsNotZero = False;
				ThisObject.Modified = True;
			EndIf;
			If vCurData.Price <> 0 And Not vCurData.IsPriceSetting Then
				j = j + 1;

				vNewCurData = vObject.RoomTypes.Insert(j);
				FillPropertyValues(vNewCurData, vCurData);
				vNewCurData.RoomQuantity = 0;
				vNewCurData.ReleaseTime = 0;
				vNewCurData.SetRoomQuota = Undefined;
				vNewCurData.RoomQuantityIsNotZero = False;
				vNewCurData.IsPriceSetting = True;

				vCurData.Price = 0;
				vCurData.Currency = Undefined;
				vCurData.IsPriceSetting = False;

				ThisObject.Modified = True;
			EndIf;

			j = j + 1;
		EndDo;
		
		If Not ValueIsFilled(vObject.AllotmentBusinessType) Then
			// Default value is Allotment for TO/TA
			vObject.AllotmentBusinessType = Enums.AllotmentBusinessTypes.Allotment;
			
			If vObject.IsCommitment Then
				vObject.AllotmentBusinessType = Enums.AllotmentBusinessTypes.Commitment;
			EndIf;
			
			If vObject.IsForCheckInPeriods Then
				vObject.AllotmentBusinessType = Enums.AllotmentBusinessTypes.CheckInPeriods;
			Endif;
			
			If vObject.IsQuotaForRooms Then
				vObject.AllotmentBusinessType = Enums.AllotmentBusinessTypes.Rooms;
			EndIf;
		EndIf; 		
		
		Items.GroupPages.CurrentPage = Items.PageRoomInventory;
		
		OldPeriodFrom = vObject.PeriodFrom;
		OldPeriodTo = vObject.PeriodTo;
		PeriodFromOnOpen = vObject.PeriodFrom;
		PeriodToOnOpen = vObject.PeriodTo;
	EndIf;
	If vObject.AllotmentBusinessType = Enums.AllotmentBusinessTypes.BusinessBlock And Not cmCheckUserPermissions("HavePermissionToManageBusinessBlocks") Or 
	   vObject.AllotmentBusinessType <> Enums.AllotmentBusinessTypes.BusinessBlock And Not cmCheckUserPermissions("HavePermissionToManageAllotments") Then
		ReadOnly = True;
	Else
		If Not ValueIsFilled(vObject.AllotmentType) Then
			If Not ValueIsFilled(vObject.AllotmentBusinessType) Then
				If Not vObject.IsForCheckInPeriods Then
					vObject.AllotmentBusinessType = Enums.AllotmentBusinessTypes.Allotment;
				Else
					vObject.AllotmentBusinessType = Enums.AllotmentBusinessTypes.CheckInPeriods;
				EndIf;
			EndIf;
			If vObject.DoWriteOff Then
				vObject.AllotmentType = Enums.AllotmentTypes.Definite;
				vObject.TreatAsTentativeBooking = False;
			ElsIf vObject.TreatAsTentativeBooking Then
				vObject.AllotmentType = Enums.AllotmentTypes.Tentative;
				vObject.DoWriteOff = False;
			Else
				If vObject.AllotmentBusinessType = Enums.AllotmentBusinessTypes.BusinessBlock Then
					vObject.AllotmentType = Enums.AllotmentTypes.Definite;
					vObject.DoWriteOff = True;
				Else
					vObject.AllotmentType = Enums.AllotmentTypes.DoNotChangeAvailability;
				EndIf;
			EndIf;
		EndIf;				
	EndIf;

	Items.FormCancelBusinessBlock.Enabled = False;
	Items.FormCancelBusinessBlock.Visible = False;
	If vObject.DeletionMark Or vObject.AllotmentType = Enums.AllotmentTypes.Cancelled Then
		Items.AnnulationReason.ReadOnly = False;
	Else
		Items.AnnulationReason.ReadOnly = True;
		If ValueIsFilled(vObject.Ref) Then
			If vObject.AllotmentBusinessType = Enums.AllotmentBusinessTypes.BusinessBlock Then
				Items.FormCancelBusinessBlock.Enabled = True;
				Items.FormCancelBusinessBlock.Visible = True;
			EndIf;
		EndIf;
	EndIf;
		
	// Check form parameters
	If Not ValueIsFilled(vObject.Ref) Then
		If IsBlankString(vObject.Description) Then
			If Parameters.Property("Description") And 
			   Not IsBlankString(Parameters.Description) Then
			   vObject.Description = Parameters.Description;
			   vObject.AllotmentType = Enums.AllotmentTypes.DoNotChangeAvailability;
			   vObject.DoWriteOff = False;
			   vObject.TreatAsTentativeBooking = False;
			EndIf;
		EndIf;
		If Parameters.Property("PeriodFrom") And 
		   Parameters.Property("PeriodTo") And 
		   ValueIsFilled(Parameters.PeriodFrom) And 
		   ValueIsFilled(Parameters.PeriodTo) And
		   Parameters.PeriodFrom <= Parameters.PeriodTo Then
			vObject.PeriodFrom = Parameters.PeriodFrom;
			vObject.PeriodTo = Parameters.PeriodTo;
		EndIf;
		vObject.OverbookingIsNotAllowed = True;
	EndIf;
	
	// Check user rights to edit manager
	If Not cmCheckUserPermissions("HavePermissionToEditCustomerAndGuestGroupManagers") Then
		Items.ReservationManager.ReadOnly = True;
		Items.MICEManager.ReadOnly = True;
		Items.RevenueManager.ReadOnly = True;
	EndIf;
	
	// Color
	vColor = Undefined;
	If Not IsBlankString(vObject.ColorHexString) Then
		vColor = tcOnServer.HexToColor(vObject.ColorHexString);
	EndIf;
	If vColor <> Undefined And TypeOf(vColor) = Type("Color") Then
		Color = vColor;
		SetColor(Color);
	EndIf;
	ValueToFormAttribute(vObject, "Object");
	
	// Form attributes appearance
	VisibleItems(False);
	FlatRateIsUsedForUnderallotmentPenaltyCalculationOnChangeAtServer();
	FillAnalyticsTitleAtServer();
	FillAutoReleaseTitleAtServer();
	FillManagersTitleAtServer();
	If Object.AllotmentBusinessType = Enums.AllotmentBusinessTypes.BusinessBlock Then
		ThisObject.AutoTitle = False;
		ThisObject.Title = NStr("en='Business block'; ru='Бизнес-блок'; de='Geschäftsblöck'");
		If ValueIsFilled(Object.Ref) Then
			ThisObject.Title = TrimAll(Object.Description) + " (" + ThisObject.Title + ")";
		Else
			ThisObject.Title = ThisObject.Title + " (" + NStr("en='create'; ru='создание'; de='erstellen'") + ")";
		EndIf;
	EndIf;
	
	// Fill analytics
	Items.ClientType.ChoiceList.LoadValues(GetArrayOfAllClientTypes());
	Items.SourceOfBusiness.ChoiceList.LoadValues(GetArrayOfAllSourceOfBusiness());
	Items.TripPurpose.ChoiceList.LoadValues(GetArrayOfAllTripPurposes());
	
	// Fill available rooms
	For Each vRTRow In Object.RoomTypes Do
		If Not vRTRow.IsPriceSetting Then
			FillAvailableRoomsAtServer(vRTRow);
		EndIf;
	EndDo;
	
	FillGuestGroups();
	FillEvents();

	DoRefreshGuestGroups = False;
	DoRefreshEvents = False;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	// Status
	If Object.AllotmentBusinessType = Enums.AllotmentBusinessTypes.BusinessBlock Then
		vVirtualItem = Items.AllotmentType.ChoiceList.FindByValue(Enums.AllotmentTypes.DoNotChangeAvailability);
		If vVirtualItem <> Undefined Then
			Items.AllotmentType.ChoiceList.Delete(vVirtualItem);
		EndIf;
		// Check hotel list of allowed busines-block statuses
		If ValueIsFilled(Object.Hotel) And Object.Hotel.BusinessBlockStatusesAllowed.Count() > 0 Then
			s = 0;
			While s < Items.AllotmentType.ChoiceList.Count() Do
				vStatus = Items.AllotmentType.ChoiceList.Get(s).Value;
				If Object.Hotel.BusinessBlockStatusesAllowed.Find(vStatus, "Status") = Undefined Then
					Items.AllotmentType.ChoiceList.Delete(s);
				Else
					s = s + 1;
				EndIf;
			EndDo;
		EndIf;
		// Help
		Items.AllotmentType.ToolTip = NStr("en='Guaranteed - deducts rooms from the inventory. Writes to the sales forecast same way as guaranteed reservation
		                                       |Not guaranteed - deducts rooms from the inventory. Writes to the sales forecast same way as not guaranteed reservation
		                                       |Tentative - does not deducts rooms from inventory. Writes to the sales forecast and inventory same way as not tentative reservation
		                                       |Reserved - deducts rooms from inventory. Does not write to the sales forecast
											   |
											   |Only the statuses allowed in the hotel settings on the ""Booking"" tab are displayed here!';
		                                   |ru='Гарантированный - списывает номера из остатка свободных номеров. Учитывается в прогнозе продаж так же, как бронь в гарантированном статусе
		                                       |Негарантированный - списывает номера из остатка свободных номеров. Учитывается в прогнозе продаж так же, как бронь в не гарантированном статусе
		                                       |Предварительный - не списывает номера из остатка свободных номеров. Учитывается в прогнозе продаж и остатках свободных номеров так же, как ""предварительная"" бронь (номера списываются отдельным ресурсом)
		                                       |Зарезервированный - списывает номера из остатка свободных номеров. Не влияет на прогноз продаж
											   |
											   |Здесь отображаются только статусы разрешенные в настройках отеля на вкладке ""Бронирование""!';
										   |de='Garantiert - Zimmern vom Inventar abziehen. Schreibt in die Umsatzprognose auf die gleiche Weise wie eine garantierte Reservierung
										       |Nicht garantiert - Zimmern vom Inventar abziehen. Schreibt in die Umsatzprognose auf die gleiche Weise wie eine nicht garantierte Reservierung
		                                       |Tentative - Zimmern vom Inventar nicht abziehen. Behandelt wie eine ""vorläufige"" Reservierung
		                                       |Reserviert - Zimmern vom Inventar abziehen. Hat keinen Einfluss auf die Umsatzprognose
											   |
											   |Hier werden nur die in den Hoteleinstellungen erlaubten Status auf der Registerkarte ""Buchung"" angezeigt!'");
	Else
		vNotGuaranteedItem = Items.AllotmentType.ChoiceList.FindByValue(Enums.AllotmentTypes.DefiniteNotGuaranteed);
		If vNotGuaranteedItem <> Undefined Then
			Items.AllotmentType.ChoiceList.Delete(vNotGuaranteedItem);
		EndIf;
		vReservedItem = Items.AllotmentType.ChoiceList.FindByValue(Enums.AllotmentTypes.Reserved);
		If vReservedItem <> Undefined Then
			Items.AllotmentType.ChoiceList.Delete(vReservedItem);
		EndIf;
		// Help
		Items.AllotmentType.ToolTip = NStr("en='Guaranteed - deducts rooms from the inventory.
		                                       |Tentative - treated the same way as a ""tentative"" reservation.
		                                       |Virtual - does not affect the inventory.';
		                                   |ru='Гарантированный - списывает номера из остатка свободных номеров.
		                                       |Предварительный - учитывается также как ""предварительная"" бронь - номера списываются отдельным ресурсом.
		                                       |Виртуальный - не влияет на остаток свободных номеров в гостинице.';
										   |de='Definitive - Zimmern vom Inventar abziehen.
		                                       |Tentative - behandelt wie eine ""vorläufige"" Reservierung.
		                                       |Virtuell - hat keinen Einfluss auf das Inventar.'");
	EndIf;
	If Items.AllotmentType.ChoiceList.FindByValue(Object.AllotmentType) = Undefined Then
		Items.AllotmentType.ChoiceList.Add(Object.AllotmentType);
	EndIf;
	
	// Other titles
	FillGroupBudgetTitleAtServer();
	FillGroupPermissionsTitleAtServer();
	FillGroupBasisTitleAtServer();
	
	// Save initial object state
	OldAllotmentType = Object.AllotmentType;
	OldDoWriteOff = Object.DoWriteOff;
	OldTreatAsTentativeBooking = Object.TreatAsTentativeBooking;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	If ValueIsFilled(Object.Ref) Then
		SetFilter();
	Else
		DoShowPrices();
	EndIf;
EndProcedure // OnOpen

// --------------------------------------------------------------------------------
&AtClient
Procedure SetFilter()
	DoHideZeroes();
	DoShowPrices();
EndProcedure // SetFilter

// -----------------------------------------------------------------------------
&AtServer
Procedure CustomerOnChangeAtServer()
	If ValueIsFilled(Object.Customer) Then
		If ValueIsFilled(Object.Customer.Contract) Then
			Object.Contract = Object.Customer.Contract;
		EndIf;
		If Not ValueIsFilled(Object.Agent) Then
			If ValueIsFilled(Object.Customer.Agent) Then
				Object.Agent = Object.Customer.Agent;
			ElsIf ValueIsFilled(Object.Customer.AgentCommissionType) Then
				Object.Agent = Object.Customer;
			EndIf;
		EndIf;
		If ValueIsFilled(Object.Customer.ReservationManager) Then
			Object.ReservationManager = Object.Customer.ReservationManager;
		EndIf;
		If ValueIsFilled(Object.Customer.MICEManager) Then
			Object.MICEManager = Object.Customer.MICEManager;
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure BudgetAmountOnChange(pItem)
	If Object.BudgetAmount <> 0 Then
		If Not ValueIsFilled(Object.BudgetCurrency) Then
			vHotel = Object.Hotel;
			If Not ValueIsFilled(vHotel) Then
				vHotel = tcOnServer.cmGetSessionParametersAttribute("CurrentHotel");
			EndIf;
			If ValueIsFilled(vHotel) Then
				Object.BudgetCurrency = tcOnServer.cmGetAttributeByRef(vHotel, "BaseCurrency");
			EndIf;
		EndIf;
		Object.BudgetMICEAmount = Object.BudgetAmount - Object.BudgetReservationAmount;
		If Object.BudgetMICEAmount < 0 Then
			Object.BudgetMICEAmount = 0;
		EndIf;
	EndIf;
	// Budget title
	FillGroupBudgetTitleAtServer();
EndProcedure // BudgetAmountOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomNightsOnChange(pItem)
	// Budget title
	FillGroupBudgetTitleAtServer();
EndProcedure // RoomNightsOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure BudgetCurrencyOnChange(pItem)
	// Budget title
	FillGroupBudgetTitleAtServer();
EndProcedure // BudgetCurrencyOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure OverbookingIsNotAllowedOnChange(pItem)
	// Permissions title
	FillGroupPermissionsTitleAtServer();
EndProcedure // OverbookingIsNotAllowedOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CustomerOrContractChangeIsNotAllowedOnChange(pItem)
	// Permissions title
	FillGroupPermissionsTitleAtServer();
EndProcedure // CustomerOrContractChangeIsNotAllowedOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CustomerOnChange(pItem)
	CustomerOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoiceColor(pCommand)
	vDialog = New ColorChooseDialog();
	vDialog.Color = Color;
	vDialog.Show(New NotifyDescription("ColorPick", ThisObject));	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ColorPick(pColor,pParametr) Export
	If pColor <> Undefined Then
		ClearColor = False;
		PickColor = True;
		SetColor(pColor);
		Modified = True;
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SetColor(pColor)	
	Color = pColor;
	Items.ChoiceColor.BackColor = Color;
	Items.ChoiceColor.TextColor = GetButtonTextColor(cmGetAbsoluteColor(Color));	
EndProcedure

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetButtonTextColor(pColor)	
	If (1 - (0.299 * pColor.R + 0.587 * pColor.G + 0.114 * pColor.B) / 255 < 0.5) Then
		Return New Color(0,0,0);
	else
		Return New Color(255,255,255);
	EndIf;	
EndFunction

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearColor(pCommand)
	ClearColor = True;
	PickColor = False;
	Items.ChoiceColor.BackColor = tcCommonFunctionOnClientServer.ColorConstructor(255, 255, 255);
	Items.ChoiceColor.TextColor = tcCommonFunctionOnClientServer.ColorConstructor(0, 0, 0); 
	Modified = True;	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure IsQuotaForRoomsOnChange()
	vObject = FormAttributeToValue("Object");
	If vObject.pmGetAllotmentDocuments().Count() > 0 Then
		vObject.IsQuotaForRooms = Not vObject.IsQuotaForRooms;
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Attention: You can change allotment type if there are no posted change allotment rooms documents!';ru='Предупреждение: Изменение типа квоты возможно только при отсутствии проведенных документов изменения состава квоты!';de='Warnung: Eine Änderung des Allotmenttyps ist nur bei gehenden bearbeiteten Dokumenten über die Änderung der Allotmentzusammensetzung!'"));
	EndIf;
	If vObject.IsQuotaForRooms Then
		Items.RoomTypes.ReadOnly = True;
		Items.RoomTypesFillRoomTypes.Enabled = FAlse;	
	else
		Items.RoomTypes.ReadOnly = False;
		Items.RoomTypesFillRoomTypes.Enabled = True;
	EndIf;
	ValueToFormAttribute(vObject, "Object");	
EndProcedure // IsQuotaForRoomsOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure IsQuotaForRoomsOnChange1(pItem)
	IsQuotaForRoomsOnChange();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure AllotmentTypeOnChangeAtServer()
	Items.DateOfDef.Enabled = False;
	If Not ValueIsFilled(Object.AllotmentType) Then
		Object.AllotmentType = Enums.AllotmentTypes.DoNotChangeAvailability;
	EndIf;
	If Object.AllotmentType = Enums.AllotmentTypes.Definite Then
		Object.DoWriteOff = True;
		Object.TreatAsTentativeBooking = False;
	ElsIf Object.AllotmentType = Enums.AllotmentTypes.DefiniteNotGuaranteed Then
		Object.DoWriteOff = True;
		Object.TreatAsTentativeBooking = False;
		Items.DateOfDef.Enabled = True;
	ElsIf Object.AllotmentType = Enums.AllotmentTypes.Reserved Then
		Object.DoWriteOff = True;
		Object.TreatAsTentativeBooking = False;
		Items.DateOfDef.Enabled = True;
	ElsIf Object.AllotmentType = Enums.AllotmentTypes.Tentative Then
		Object.DoWriteOff = False;
		Object.TreatAsTentativeBooking = True;
		Items.DateOfDef.Enabled = True;
	Else
		Object.DoWriteOff = False;
		Object.TreatAsTentativeBooking = False;
	EndIf;
EndProcedure // AllotmentTypeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AllotmentTypeOnChange(pItem)
	AllotmentTypeOnChangeAtServer();
EndProcedure // AllotmentTypeOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure FillRoomTypesAtServer()
	If ValueIsFilled(Object.Hotel) Then
		vRoomTypes = cmGetAllRoomTypes(Object.Hotel);
		For Each vRoomTypesRow In vRoomTypes Do
			vObjRTRows = Object.RoomTypes.FindRows(New Structure("RoomType, PeriodFrom, PeriodTo, IsPriceSetting", vRoomTypesRow.RoomType, Object.PeriodFrom, Object.PeriodTo, False));
			If vObjRTRows.Count() = 0 Then
				vRTRow = Object.RoomTypes.Add();
				vRTRow.PeriodFrom = Object.PeriodFrom;
				vRTRow.PeriodTo = Object.PeriodTo;
				vRTRow.RoomType = vRoomTypesRow.RoomType;
				vRTRow.Hotel = vRTRow.RoomType.Owner;
			EndIf;
		EndDo;
		For Each vRTRow In Object.RoomTypes Do
			If Not vRTRow.IsPriceSetting Then
				FillAvailableRoomsAtServer(vRTRow);
			EndIf;
		EndDo;
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Fill hotel attribute first!'; ru='Укажите гостиницу!'; de='Geben Sie ein Hotel!'"));
	EndIf;
EndProcedure // FillRoomTypesAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure FillRoomTypes(pCommand)
	FillRoomTypesAtServer();
EndProcedure // FillRoomTypes

// -----------------------------------------------------------------------------
&AtServer
Procedure FillAvailableRoomsAtServer(pRTRow = Undefined)
	vRTRowData = Undefined;
	If pRTRow <> Undefined Then
		If TypeOf(pRTRow) = Type("Number") Then
			vRTRowData = Object.RoomTypes.FindByID(pRTRow);
		Else
			vRTRowData = pRTRow;
		EndIf;
	EndIf;
	If vRTRowData <> Undefined Then
		If vRTRowData.PeriodFrom > vRTRowData.PeriodTo Then
			vRTRowData.PeriodTo = vRTRowData.PeriodFrom;
		EndIf;
	EndIf;
		
	// Get reference hour
	vRH = '00010101120000';
	If ValueIsFilled(Object.RoomRate) And ValueIsFilled(Object.RoomRate.ReferenceHour) Then
		vRH = Object.RoomRate.ReferenceHour;
	ElsIf ValueIsFilled(Object.Hotel) And ValueIsFilled(Object.Hotel.RoomRate) And ValueIsFilled(Object.Hotel.RoomRate.ReferenceHour) Then
		vRH = Object.Hotel.RoomRate.ReferenceHour;
	ElsIf ValueIsFilled(SessionParameters.CurrentHotel) And ValueIsFilled(SessionParameters.CurrentHotel.RoomRate) And ValueIsFilled(SessionParameters.CurrentHotel.RoomRate.ReferenceHour) Then
		vRH = SessionParameters.CurrentHotel.RoomRate.ReferenceHour;
	EndIf;
	vShiftInSeconds = vRH - BegOfDay(vRH);
	// Get available rooms
	vQry = New Query();
	vQry.Text =	
	"SELECT
	|	BEGINOFPERIOD(RoomInventoryBalance.Period, DAY) AS Period,
	|	RoomInventoryBalance.Hotel AS Hotel,
	|	RoomInventoryBalance.RoomType AS RoomType,
	|	MAX(ISNULL(RoomInventoryBalance.TotalRoomsClosingBalance, 0)) AS TotalRooms,
	|	MAX(ISNULL(RoomInventoryBalance.TotalBedsClosingBalance, 0)) AS TotalBeds,
	|	MIN(ISNULL(RoomInventoryBalance.RoomsVacantClosingBalance, 0)) AS RoomsVacant,
	|	MIN(ISNULL(RoomInventoryBalance.BedsVacantClosingBalance, 0)) AS BedsVacant
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
	|		AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|				&qDateTimeFrom,
	|				&qDateTimeTo,
	|				Minute,
	|				RegisterRecordsAndPeriodBoundaries,
	|				Hotel = &qHotel
	|					AND (NOT &qFilterByRoomType
	|						OR &qFilterByRoomType
	|							AND RoomType = &qRoomType)) AS RoomInventoryBalanceAndTurnovers
	|	
	|	GROUP BY
	|		BEGINOFPERIOD(DATEADD(RoomInventoryBalanceAndTurnovers.Period, SECOND, &qShiftInSeconds), DAY),
	|		RoomInventoryBalanceAndTurnovers.Hotel,
	|		RoomInventoryBalanceAndTurnovers.RoomType) AS RoomInventoryBalance
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
	|				AND (NOT &qFilterByRoomType
	|					OR &qFilterByRoomType
	|						AND RoomType = &qRoomType)) AS ExpectedGuestGroupsTurnovers
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
	vQry.SetParameter("qHotel", Object.Hotel);
	vQry.SetParameter("qShiftInSeconds", -vShiftInSeconds);
	vQry.SetParameter("qShowPreliminary", True);
	If vRTRowData <> Undefined Then
		If ValueIsFilled(vRTRowData.RoomType) And ValueIsFilled(vRTRowData.PeriodFrom) And ValueIsFilled(vRTRowData.PeriodTo) And vRTRowData.PeriodTo > vRTRowData.PeriodFrom Then
			vQry.SetParameter("qFilterByRoomType", True);
			vQry.SetParameter("qRoomType", vRTRowData.RoomType);
			vQry.SetParameter("qDateTimeFrom", cm1SecondShift(BegOfDay(vRTRowData.PeriodFrom) + vShiftInSeconds));
			vQry.SetParameter("qDateTimeTo", cm0SecondShift(BegOfDay(vRTRowData.PeriodTo) + vShiftInSeconds));
			vQry.SetParameter("qDateFrom", BegOfDay(vRTRowData.PeriodFrom));
			vQry.SetParameter("qDateTo", EndOfDay(vRTRowData.PeriodTo));
		Else
			Return;
		EndIf;
	Else
		If ValueIsFilled(Object.PeriodFrom) And ValueIsFilled(Object.PeriodTo) And Object.PeriodTo > Object.PeriodFrom Then
			vQry.SetParameter("qFilterByRoomType", False);
			vQry.SetParameter("qRoomType", Undefined);
			vQry.SetParameter("qDateTimeFrom", cm1SecondShift(BegOfDay(Object.PeriodFrom) + vShiftInSeconds));
			vQry.SetParameter("qDateTimeTo", cm0SecondShift(BegOfDay(Object.PeriodTo) + vShiftInSeconds));
			vQry.SetParameter("qDateFrom", BegOfDay(Object.PeriodFrom));
			vQry.SetParameter("qDateTo", EndOfDay(Object.PeriodTo));
		Else
			Return;
		EndIf;
	EndIf;
	vBalances = vQry.Execute().Unload();
	If vRTRowData <> Undefined Then
		If ValueIsFilled(vRTRowData.RoomType) Then
			vBalancesRow = vBalances.Find(vRTRowData.RoomType);
			If vBalancesRow <> Undefined Then
				If vBalancesRow.RoomsVacant <> vBalancesRow.VacantWithPreliminaryRooms Then
					vRTRowData.RoomsAvailable = Format(vBalancesRow.RoomsVacant, "NFD=0; NZ=; NG=") + " / " + Format(vBalancesRow.VacantWithPreliminaryRooms, "NFD=0; NZ=; NG=");
				Else
					vRTRowData.RoomsAvailable = Format(vBalancesRow.RoomsVacant, "NFD=0; NZ=; NG=");
				EndIf;
			Else
				vRTRowData.RoomsAvailable = "";
			EndIf;
		Else
			vRTRowData.RoomsAvailable = "";
		EndIf;
	Else
		For Each vRTRow In Object.RoomTypes Do
			If ValueIsFilled(vRTRow.RoomType) Then
				vBalancesRow = vBalances.Find(vRTRow.RoomType);
				If vBalancesRow <> Undefined Then
					If vBalancesRow.RoomsVacant <> vBalancesRow.VacantWithPreliminaryRooms Then
						vRTRow.RoomsAvailable = Format(vBalancesRow.RoomsVacant, "NFD=0; NZ=; NG=") + " / " + Format(vBalancesRow.VacantWithPreliminaryRooms, "NFD=0; NZ=; NG=");
					Else
						vRTRow.RoomsAvailable = Format(vBalancesRow.RoomsVacant, "NFD=0; NZ=; NG=");
					EndIf;
				Else
					vRTRow.RoomsAvailable = "";
				EndIf;
			Else
				vRTRow.RoomsAvailable = "";
			EndIf;
		EndDo;
	EndIf;
EndProcedure // FillAvailableRoomsAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure IsForCheckInPeriodsOnChangeAtServer()
	If Object.IsForCheckInPeriods And ValueIsFilled(Object.Hotel) And Object.RoomTypes.Count() = 0 Then
		vRoomTypes = cmGetAllRoomTypes(Object.Hotel);
		For Each vRoomTypesRow In vRoomTypes Do
			vRTRow = Object.RoomTypes.Add();
			vRTRow.PeriodFrom = Object.PeriodFrom;
			vRTRow.PeriodTo = Object.PeriodTo;
			vRTRow.RoomType = vRoomTypesRow.RoomType;
			vRTRow.Hotel = vRTRow.RoomType.Owner;
		EndDo;
	EndIf;
	VisibleItems();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure VisibleItems(pUpdateAttributes = True)
	Items.PageCommitment.Visible = False;
	Items.PageRoomInventory.Visible = False;
	Items.PageParameters.Visible = IsInRole("Administrator");
	Items.PageReservations.Visible = False;
	Items.PageEvents.Visible = False;
	Items.GroupBudget.Visible = False;
	
	If Object.AllotmentBusinessType = Enums.AllotmentBusinessTypes.BusinessBlock Then
		Items.AllotmentBusinessType.Visible = False;
		Items.PageReservations.Visible = True;
		Items.PageEvents.Visible = True;
		Items.AllotmentBusinessType.Visible = False;
		Items.GroupBudget.Visible = True;
		Items.IsCommitment.Visible = False;
		Items.ContactPerson.Visible = True;
		
		If pUpdateAttributes Then
			Object.IsCommitment = False;
			
			Object.IsForCheckInPeriods = False;
			Object.IsQuotaForRooms = False;
			
			Modified = True;
		EndIf;
	ElsIf Object.AllotmentBusinessType = Enums.AllotmentBusinessTypes.Allotment Then
		Items.PageRoomInventory.Visible = True;
		Items.IsCommitment.Visible = True;
		Items.ContactPerson.Visible = False;
		
		If pUpdateAttributes Then
			Object.IsCommitment = False;
			
			Object.IsForCheckInPeriods = False;
			Object.IsQuotaForRooms = False;
			
			Modified = True;
		EndIf;
	ElsIf Object.AllotmentBusinessType = Enums.AllotmentBusinessTypes.Commitment Then
		Items.PageRoomInventory.Visible = True;
		Items.PageCommitment.Visible = True;	
		Items.IsCommitment.Visible = True;
		Items.ContactPerson.Visible = False;
		
		If pUpdateAttributes Then
			Object.IsCommitment = True;
			
			Modified = True;
		EndIf;
	ElsIf Object.AllotmentBusinessType = Enums.AllotmentBusinessTypes.CheckInPeriods Then
		Items.PageRoomInventory.Visible = True;
		Items.IsCommitment.Visible = True;
		Items.ContactPerson.Visible = False;
		
		If pUpdateAttributes Then
			Object.IsCommitment = False;
			
			Object.IsForCheckInPeriods = True;
			Object.IsQuotaForRooms = False;
			
			Modified = True;
		EndIf;
	ElsIf Object.AllotmentBusinessType = Enums.AllotmentBusinessTypes.Rooms Then
		Items.IsCommitment.Visible = True;
		Items.ContactPerson.Visible = False;
		If pUpdateAttributes Then
			Object.IsCommitment = False;
			
			Object.IsQuotaForRooms = True;
			
			Modified = True;
		EndIf;
	EndIf;
	
	If Not Object.IsForCheckInPeriods Then
		Items.CheckInPeriods.Visible = False;
	Else
		Items.CheckInPeriods.Visible = True;
	EndIf;
	
	If Object.RoomTypes.Count() > 0 Then
		If Object.IsQuotaForRooms Then
			If pUpdateAttributes Then
				Object.IsQuotaForRooms = False;
				
				Modified = True;
			EndIf;
		EndIf;
	Else
		Items.DoCharge.Enabled = True;
	EndIf;
	
	If Object.IsQuotaForRooms Then
		Items.RoomTypes.Enabled = False;
		Items.RoomTypes.ReadOnly = True;
		Items.RoomTypesFillRoomTypes.Enabled = False;
	Else
		Items.RoomTypes.Enabled = True;  
		Items.RoomTypes.ReadOnly = False;
		Items.RoomTypesFillRoomTypes.Enabled = True;	
	EndIf;
	If Object.IsCommitment Then
		Items.IsCommitment.Visible = True;
		Items.DoCharge.Enabled = True;
	Else
		If Object.DoCharge Then
			If pUpdateAttributes Then
				DoCharge = False;
				
				Modified = True;
			EndIf;
		EndIf;
		Items.DoCharge.Enabled = False;
	EndIf;
	If Object.DoCharge Then
		Items.GroupCommitmentAllotment.Visible = True;
		If pUpdateAttributes Then
			If Object.ReleaseTime > 0 Then
				Object.ReleaseTime = 0;
				
				Modified = True;
			EndIf;
			For Each vRTRow In Object.RoomTypes Do
				If vRTRow.ReleaseTime > 0 Then
					vRTRow.ReleaseTime = 0;
				
					Modified = True;
				EndIf;
			EndDo;
		EndIf;
	Else
		Items.GroupCommitmentAllotment.Visible = False;
	EndIf;		
	Items.DateOfDef.Enabled = False;
	If Object.AllotmentType = Enums.AllotmentTypes.DefiniteNotGuaranteed Or 
	   Object.AllotmentType = Enums.AllotmentTypes.Tentative Or
	   Object.AllotmentType = Enums.AllotmentTypes.Reserved Then
		Items.DateOfDef.Enabled = True;
	EndIf;   
	If Object.IsCommitment Then
		Items.Company2.Enabled = Object.IsCommitment;	
	EndIf;	
EndProcedure // VisibleItems

// -----------------------------------------------------------------------------
&AtClient
Procedure IsForCheckInPeriodsOnChange(pItem)
	IsForCheckInPeriodsOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DoChargeOnChange(pItem)
	 VisibleItems();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure ProcessPeriodChange()
	If ValueIsFilled(Object.PeriodFrom) And ValueIsFilled(Object.PeriodTo) And Object.PeriodTo > Object.PeriodFrom Then
		For Each vRow In Object.RoomTypes Do
			If Not vRow.IsPriceSetting Then
				If ValueIsFilled(OldPeriodFrom) And ValueIsFilled(OldPeriodTo) And OldPeriodTo > OldPeriodFrom And vRow.PeriodFrom = OldPeriodFrom Or Not ValueIsFilled(vRow.PeriodFrom) Then
					vRow.PeriodFrom = Object.PeriodFrom;
				EndIf;
				If ValueIsFilled(OldPeriodFrom) And ValueIsFilled(OldPeriodTo) And OldPeriodTo > OldPeriodFrom And vRow.PeriodTo = OldPeriodTo Or Not ValueIsFilled(vRow.PeriodTo) Then
					vRow.PeriodTo = Object.PeriodTo;
				EndIf;
				FillAvailableRoomsAtServer(vRow);
			EndIf;
		EndDo;
		For Each vRow In Object.CheckInPeriods Do
			If ValueIsFilled(OldPeriodFrom) And ValueIsFilled(OldPeriodTo) And OldPeriodTo > OldPeriodFrom And vRow.PeriodFrom = OldPeriodFrom Or Not ValueIsFilled(vRow.PeriodFrom) Then
				vRow.PeriodFrom = Object.PeriodFrom;
			EndIf;
			If ValueIsFilled(OldPeriodFrom) And ValueIsFilled(OldPeriodTo) And OldPeriodTo > OldPeriodFrom And vRow.PeriodTo = OldPeriodTo Or Not ValueIsFilled(vRow.PeriodTo) Then
				vRow.PeriodTo = Object.PeriodTo;
			EndIf;
		EndDo;
		OldPeriodFrom = Object.PeriodFrom;
		OldPeriodTo = Object.PeriodTo;
	EndIf;
EndProcedure // ProcessPeriodChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PeriodFromOnChange(pItem)
	ProcessPeriodChange();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PeriodToOnChange(pItem)
	ProcessPeriodChange();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriod(pCommand)
	vChoosePeriodDialog = New StandardPeriodEditDialog();
	vChoosePeriodDialog.Show(New NotifyDescription("ChoosePeriodEnd", ThisObject, New Structure("vChoosePeriodDialog", vChoosePeriodDialog)));
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriodEnd(Period, AdditionalParameters) Export
	vChoosePeriodDialog = AdditionalParameters.vChoosePeriodDialog;
	If Not Period = Undefined Then
		Object.PeriodFrom = vChoosePeriodDialog.Period.StartDate;
		Object.PeriodTo = vChoosePeriodDialog.Period.EndDate;
		ProcessPeriodChange();
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ReleaseTimeOnChange(pItem)
	FillAutoReleaseTitleAtServer();
EndProcedure // ReleaseTimeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ReleaseDateOnChange(pItem)
	FillAutoReleaseTitleAtServer();
EndProcedure // ReleaseDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure BaseRoomQuotaOnChange(pItem)
	If ValueIsFilled(Object.Ref) And Object.BaseRoomQuota = Object.Ref Then
		Object.BaseRoomQuota = Undefined;
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You can not use this allotment as base allotment!'; ru='В качестве базовой квоты нельзя использовать эту же самую квоту!'; de='Sie können dieses Allotment nicht als Basisallotment verwenden!'"), MessageStatus.Attention);
	EndIf;
	FillGroupBasisTitleAtServer();
EndProcedure // BaseRoomQuotaOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ReservationManagerOnChange(pItem)
	FillManagersTitleAtServer();
EndProcedure // ReservationManagerOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure MICEManagerOnChange(pItem)
	FillManagersTitleAtServer();
EndProcedure // MICEManagerOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RevenueManagerOnChange(pItem)
	FillManagersTitleAtServer();
EndProcedure // RevenueManagerOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckInPeriodsOnStartEdit(Item, pNewRow, pClone)
	vCurRow = Item.CurrentData;
	If vCurRow <> Undefined Then
		If pNewRow And Not pClone Then
			vCurRow.PeriodFrom = Object.PeriodFrom;
			vCurRow.PeriodTo = Object.PeriodTo;
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypesOnStartEdit(pItem, pNewRow, pClone)
	vCurData = pItem.CurrentData;
	If vCurData <> Undefined Then
		If pNewRow Then
			If pClone Then
				vCurData.SetRoomQuota = Undefined;
			Else
				vCurData.PeriodFrom = Object.PeriodFrom;
				vCurData.PeriodTo = Object.PeriodTo;
				vCurData.Hotel = Object.Hotel;
			EndIf;
			vCurData.RoomsAvailable = "";
			vCurData.RoomQuantityIsNotZero = True;
			vCurData.IsPriceSetting = False;
		EndIf;
	EndIf;
EndProcedure // RoomTypesOnStartEdit

// -----------------------------------------------------------------------------
&AtClient
Procedure PricesOnStartEdit(pItem, pNewRow, pClone)
	vCurData = pItem.CurrentData;
	If vCurData <> Undefined Then
		If pNewRow Then
			If pClone Then
				vCurData.SetRoomQuota = Undefined;
			Else
				vCurData.PeriodFrom = Object.PeriodFrom;
				vCurData.PeriodTo = Object.PeriodTo;
				vCurData.Hotel = Object.Hotel;
			EndIf;
			If Not ValueIsFilled(vCurData.Currency) And ValueIsFilled(Object.Hotel) Then
				vCurData.Currency = tcOnServer.cmGetAttributeByRef(Object.Hotel, "BaseCurrency");
			EndIf;
			vCurData.IsPriceSetting = True;
		EndIf;
	EndIf;
EndProcedure // PricesOnStartEdit

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypesOnEditEnd(pItem, pNewRow, pCancelEdit)
	vCurData = pItem.CurrentData;
	If vCurData <> Undefined Then
		DoHideZeroes();
	EndIf;
EndProcedure // RoomTypesOnEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure PricesOnEditEnd(pItem, pNewRow, pCancelEdit)
	vCurData = pItem.CurrentData;
	If vCurData <> Undefined Then
		vCurData.NumberOfPersons = (vCurData.NumberOfAdults + vCurData.NumberOfTeenagers + vCurData.NumberOfChildren + vCurData.NumberOfInfants);
		DoShowPrices();
	EndIf;
EndProcedure // PricesOnEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypesRoomTypeOnChange(pItem)
	vCurRow = Items.RoomTypes.CurrentRow;
	If vCurRow <> Undefined Then
		FillAvailableRoomsAtServer(vCurRow);
	EndIf;
EndProcedure // RoomTypesRoomTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypesPeriodToOnChange(pItem)
	vCurRow = Items.RoomTypes.CurrentRow;
	If vCurRow <> Undefined Then
		FillAvailableRoomsAtServer(vCurRow);
	EndIf;
EndProcedure // RoomTypesPeriodToOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypesPeriodFromOnChange(pItem)
	vCurRow = Items.RoomTypes.CurrentRow;
	If vCurRow <> Undefined Then
		FillAvailableRoomsAtServer(vCurRow);
	EndIf;
EndProcedure // RoomTypesPeriodFromOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckInPeriodsBeforeEditEnd(pItem, pNewRow, pCancelEdit, pCancel)
		vCurRow =  pItem.CurrentData;
	If vCurRow <> Undefined Then
		If ValueIsFilled(vCurRow.PeriodFrom) And ValueIsFilled(vCurRow.PeriodTo) Then
			If vCurRow.Duration = 0 And vCurRow.SecondDuration <> 0 Then
				vCurRow.Duration = vCurRow.SecondDuration;
			EndIf;
			If vCurRow.PeriodFrom < vCurRow.PeriodTo Then
				vNumDays = (BegOfDay(vCurRow.PeriodTo) - BegOfDay(vCurRow.PeriodFrom)) / (24 * 3600);
				vPeriodLength = vCurRow.Duration + vCurRow.SecondDuration;
				If vPeriodLength > 0 Then
					vIntPeriods = Int(vNumDays / vPeriodLength);
					If vIntPeriods <> vNumDays / vPeriodLength Then
						vCurRowPeriodTo = BegOfDay(vCurRow.PeriodFrom) + (vIntPeriods + 1) * vPeriodLength * 24 * 3600;
						If vCurRow.SecondDuration <> 0 Then
							vCurRowPeriodTo2 = vCurRowPeriodTo - vCurRow.SecondDuration * 24 * 3600;
							If vCurRow.PeriodTo = vCurRowPeriodTo2 Then
								Return;
							EndIf;
						EndIf;							
						vCurRow.PeriodTo = vCurRowPeriodTo;
						If vCurRow.PeriodTo > Object.PeriodTo Then
							Object.PeriodTo = vCurRow.PeriodTo;
							ProcessPeriodChange();
						EndIf;
					EndIf;
				EndIf;
			Else
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='Period is wrong!';ru='Период указан не верно!';de='Der Zeitraum ist falsch angegeben!'"));
				pCancel = True;
			EndIf;
		EndIf;
	EndIf;

EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure DeleteCheckInPeriods(pMgrObj)
	vRcdSetObj = InformationRegisters.RoomQuotaCheckInPeriods.CreateRecordSet();
	
	If ValueIsFilled(Object.Hotel) Then
		vHotelFlt = vRcdSetObj.Filter.Hotel;
		vHotelFlt.ComparisonType = ComparisonType.Equal;
		vHotelFlt.Value = Object.Hotel;
		vHotelFlt.Use = True;
	EndIf;
	
	vRoomQuotaFlt = vRcdSetObj.Filter.RoomQuota;
	vRoomQuotaFlt.ComparisonType = ComparisonType.Equal;
	vRoomQuotaFlt.Value = Object.Ref;
	vRoomQuotaFlt.Use = True;
	
	vRcdSetObj.Read();
	For Each vRcdSetObjRow In vRcdSetObj Do
		If Not vRcdSetObjRow.IsManual  
		   And vRcdSetObjRow.CheckOutDate > Object.PeriodFrom  
		   And vRcdSetObjRow.CheckInDate < Object.PeriodTo Then
			pMgrObj.Hotel = vRcdSetObjRow.Hotel;
			pMgrObj.RoomQuota = vRcdSetObjRow.RoomQuota;
			pMgrObj.CheckInDate = vRcdSetObjRow.CheckInDate;
			pMgrObj.Duration = vRcdSetObjRow.Duration;
			pMgrObj.CheckOutDate = vRcdSetObjRow.CheckOutDate;
			pMgrObj.Read();
			If pMgrObj.Selected() Then
				pMgrObj.Delete();
			EndIf;
		EndIf;
	EndDo;
EndProcedure // DeleteCheckInPeriods

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveRoomTypes(pObject)
	// Get working period
	vRH = cmGetReferenceHour(pObject.RoomRate);
	
	// Process room types
	For Each vRoomTypesRow In pObject.RoomTypes Do 
		vPeriodFrom = BegOfDay(vRoomTypesRow.PeriodFrom) + Hour(vRH) * 3600 + Minute(vRH) * 60;
		vPeriodTo = BegOfDay(vRoomTypesRow.PeriodTo) + Hour(vRH) * 3600 + Minute(vRH) * 60;
	
		// Add rooms to the room quota
		If vRoomTypesRow.RoomQuantity > 0 Or vRoomTypesRow.RoomQuantity = 0 And ValueIsFilled(vRoomTypesRow.SetRoomQuota) Then
			AddRoomsToRoomQuota(vRoomTypesRow, vPeriodFrom, vPeriodTo);
		EndIf;
	EndDo;
	
	// Process deleted rows
	For Each vDeletedDocumentsItem In DeletedDocuments Do
		vSetRoomQuotaDoc = vDeletedDocumentsItem.Value;
		If ValueIsFilled(vSetRoomQuotaDoc) And vSetRoomQuotaDoc.Posted Then
			vSetRoomQuotaDoc.GetObject().SetDeletionMark(True);
		EndIf;
	EndDo;
EndProcedure // SaveRoomTypes

// -----------------------------------------------------------------------------
&AtServer
Procedure AddRoomsToRoomQuota(pRoomTypesRow, pPeriodFrom, pPeriodTo)
	If ValueIsFilled(pRoomTypesRow.RoomType) And Not ValueIsFilled(pRoomTypesRow.Hotel) Then
		pRoomTypesRow.Hotel = pRoomTypesRow.RoomType.Owner;
	EndIf;
	If ValueIsFilled(pRoomTypesRow.SetRoomQuota) Then
		vDocObj = pRoomTypesRow.SetRoomQuota.GetObject();
		If vDocObj.DeletionMark Then
			vDocObj.SetDeletionMark(False);
		ElsIf vDocObj.Posted Then
			If vDocObj.Hotel = pRoomTypesRow.Hotel And 
			   vDocObj.RoomQuota = Object.Ref And
			   vDocObj.BaseRoomQuota = Object.BaseRoomQuota And
			   vDocObj.RoomType = pRoomTypesRow.RoomType And 
			   vDocObj.DateFrom = cm0SecondShift(pPeriodFrom) And
			   vDocObj.DateTo = cm0SecondShift(pPeriodTo) And
			   vDocObj.NumberOfRooms = pRoomTypesRow.RoomQuantity Then
				// Nothing has to be done
				Return;
			EndIf;
		EndIf;
	Else
		vDocObj = Documents.SetRoomQuota.CreateDocument();
	EndIf;
	vDocObj.Hotel = pRoomTypesRow.Hotel;
	vDocObj.RoomQuota = Object.Ref;
	vDocObj.BaseRoomQuota = Object.BaseRoomQuota;
	vDocObj.RoomType = pRoomTypesRow.RoomType;
	vDocObj.DateFrom = cm0SecondShift(pPeriodFrom);
	If Not ValueIsFilled(pRoomTypesRow.SetRoomQuota) Then
		vDocObj.pmFillAttributesWithDefaultValues();
	EndIf;
	vDocObj.NumberOfBedsPerRoom = vDocObj.RoomType.NumberOfBedsPerRoom;
	vDocObj.NumberOfPersonsPerRoom = vDocObj.RoomType.NumberOfPersonsPerRoom;
	vDocObj.DateTo = cm0SecondShift(pPeriodTo);
	vDocObj.Duration = vDocObj.pmCalculateDuration();
	vDocObj.NumberOfRooms = pRoomTypesRow.RoomQuantity;
	vDocObj.NumberOfBeds = vDocObj.NumberOfRooms * vDocObj.NumberOfBedsPerRoom;
	vDocObj.IsInitial = True;
	vDocObj.Write(DocumentWriteMode.Posting);
	pRoomTypesRow.SetRoomQuota = vDocObj.Ref;
EndProcedure // AddRoomsToRoomQuota

// -----------------------------------------------------------------------------
&AtServer
Function CheckRoomTypes(pMessage, pAttributeInErr)
	pMessage = "";
	pAttributeInErr = "";
	vHasErrors = False; 
	vMsgTextRu = "";
	vMsgTextEn = "";
	For Each vRow In Object.RoomTypes Do
		If Not ValueIsFilled(vRow.PeriodFrom) Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Ошибка в строке " + vRow.LineNumber + " таблицы типов номеров! " + "Реквизит <Период с> должен быть заполнен!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "<Period from> attribute should be filled!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "RoomTypes.[" + Format(vRow.LineNumber - 1, "NFD=0; NG=") + "].PeriodFrom", pAttributeInErr);
		EndIf;
		If Not ValueIsFilled(vRow.PeriodTo) Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Ошибка в строке " + vRow.LineNumber + " таблицы типов номеров! " + "Реквизит <Период по> должен быть заполнен!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "<Period to> attribute should be filled!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "RoomTypes.[" + Format(vRow.LineNumber - 1, "NFD=0; NG=") + "].PeriodTo", pAttributeInErr);
		EndIf;
		If ValueIsFilled(vRow.PeriodFrom) And ValueIsFilled(vRow.PeriodTo) And vRow.PeriodTo <= vRow.PeriodFrom Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Ошибка в строке " + vRow.LineNumber + " таблицы типов номеров! " + "Период указан неверно!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "Period is wrong!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "RoomTypes.[" + Format(vRow.LineNumber - 1, "NFD=0; NG=") + "].PeriodFrom", pAttributeInErr);
		EndIf;
		If Not ValueIsFilled(vRow.RoomType) Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Ошибка в строке " + vRow.LineNumber + " таблицы типов номеров! " + "Реквизит <Тип номера> должен быть заполнен!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "<Room type> attribute should be filled!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "RoomTypes.[" + Format(vRow.LineNumber - 1, "NFD=0; NG=") + "].RoomType", pAttributeInErr);
		Else
			If Not ValueIsFilled(vRow.Hotel) Then
				vRow.Hotel = vRow.RoomType.Owner;
			EndIf;
		EndIf;
		If vHasErrors Then
			Break;
		EndIf;
	EndDo;
	If vHasErrors Then
		pMessage = "ru = '" + TrimAll(vMsgTextRu) + "';" + "en = '" + TrimAll(vMsgTextEn) + "';" + "de = '" + TrimAll(vMsgTextEn) + "'";
	EndIf;
	Return vHasErrors;
EndFunction // CheckRoomTypes

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveCheckInPeriods(pObject)
	vHotelsList = New ValueList();
	If ValueIsFilled(pObject.Hotel) Then
		vHotelsList.Add(pObject.Hotel);
	Else
		vHotelsTable = cmGetAllHotels();
		For Each vHotelsTableRow In vHotelsTable Do
			vHotelsList.Add(vHotelsTableRow.Hotel);
		EndDo;
	EndIf;
	
	// Get working period
	vRH = cmGetReferenceHour(pObject.RoomRate);
	
	// Delete previously added periods
	vMgrObj = InformationRegisters.RoomQuotaCheckInPeriods.CreateRecordManager();
	DeleteCheckInPeriods(vMgrObj);
	
	// Add periods
	For Each vHotelItem In vHotelsList Do
		vHotel = vHotelItem.Value;
		For Each vPeriodRow In pObject.CheckInPeriods Do
			vPeriodFrom = BegOfDay(vPeriodRow.PeriodFrom) + Hour(vRH) * 3600 + Minute(vRH) * 60;
			vPeriodTo = BegOfDay(vPeriodRow.PeriodTo) + Hour(vRH) * 3600 + Minute(vRH) * 60;
		
			vCheckInDate = BegOfDay(vPeriodFrom) + Hour(vRH) * 3600 + Minute(vRH) * 60;
			vCheckOutDate = BegOfDay(vPeriodFrom + vPeriodRow.Duration * 24 * 3600) + Hour(vRH) * 3600 + Minute(vRH) * 60;
			While vCheckOutDate <= vPeriodTo Do
				AddCheckInPeriod(vMgrObj, vCheckInDate, vPeriodRow.Duration, vCheckOutDate, vHotel);
				
				// Calculate next check in and check out date
				If vPeriodRow.SecondDuration <> 0 Then
					vCheckInDate = BegOfDay(vCheckOutDate) + Hour(vRH)*3600 + Minute(vRH) * 60;
					vCheckOutDate = BegOfDay(vCheckInDate + vPeriodRow.SecondDuration * 24 * 3600) + Hour(vRH) * 3600 + Minute(vRH) * 60;
					If vCheckOutDate > vPeriodTo Then
						Break;
					EndIf;
					
					// Write record
					AddCheckInPeriod(vMgrObj, vCheckInDate, vPeriodRow.SecondDuration, vCheckOutDate, vHotel);
				EndIf;
				
				// Go to next period
				vCheckInDate = BegOfDay(vCheckOutDate) + Hour(vRH) * 3600 + Minute(vRH) * 60;
				vCheckOutDate = BegOfDay(vCheckInDate + vPeriodRow.Duration * 24 * 3600) + Hour(vRH) * 3600 + Minute(vRH) * 60;
			EndDo;
		EndDo;
	EndDo;
EndProcedure // SaveCheckInPeriods

// -----------------------------------------------------------------------------
&AtServer
Function CheckPeriods(pMessage, pAttributeInErr)
	pMessage = "";
	pAttributeInErr = "";
	vHasErrors = False; 
	vMsgTextRu = "";
	vMsgTextEn = "";
	If Object.RoomTypes.Count() > 0 Or Object.CheckInPeriods.Count() > 0 Then
		If Not ValueIsFilled(Object.PeriodFrom) Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Реквизит <Период с> должен быть заполнен!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "<Period from> attribute should be filled!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "PeriodFrom", pAttributeInErr);
		EndIf;
		If Not ValueIsFilled(Object.PeriodTo) Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Реквизит <Период по> должен быть заполнен!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "<Period to> attribute should be filled!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "PeriodTo", pAttributeInErr);
		EndIf;
		If ValueIsFilled(Object.PeriodFrom) And ValueIsFilled(Object.PeriodTo) And Object.PeriodTo <= Object.PeriodFrom Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Период указан неверно!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "Period is wrong!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "PeriodFrom", pAttributeInErr);
		EndIf;
	EndIf;
	For Each vRow In Object.CheckInPeriods Do
		If Not ValueIsFilled(vRow.PeriodFrom) Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Ошибка в строке " + vRow.LineNumber + " таблицы заездов! " + "Реквизит <Период с> должен быть заполнен!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "Error in check-in periods table line " + vRow.LineNumber + "! " + "<Period from> attribute should be filled!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "CheckInPeriods.[" + Format(vRow.LineNumber-1, "NFD=0; NG=") + "].PeriodFrom", pAttributeInErr);
		EndIf;
		If Not ValueIsFilled(vRow.PeriodTo) Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Ошибка в строке " + vRow.LineNumber + " таблицы заездов! " + "Реквизит <Период по> должен быть заполнен!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "Error in check-in periods table line " + vRow.LineNumber + "! " + "<Period to> attribute should be filled!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "CheckInPeriods.[" + Format(vRow.LineNumber - 1, "NFD=0; NG=") + "].PeriodTo", pAttributeInErr);
		EndIf;
		If ValueIsFilled(vRow.PeriodFrom) And ValueIsFilled(vRow.PeriodTo) And vRow.PeriodTo <= vRow.PeriodFrom Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Ошибка в строке " + vRow.LineNumber + " таблицы заездов! " + "Период указан неверно!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "Error in check-in periods table line " + vRow.LineNumber + "! " + "Period is wrong!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "CheckInPeriods.[" + Format(vRow.LineNumber-1, "NFD=0; NG=") + "].PeriodFrom", pAttributeInErr);
		EndIf;
		If vRow.Duration = 0 Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Ошибка в строке " + vRow.LineNumber + " таблицы заездов! " + "Реквизит <Продолжительность заезда> должен быть заполнен!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "Error in check-in periods table line " + vRow.LineNumber + "! " + "<Check-in period duration> attribute should be filled!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "CheckInPeriods.[" + Format(vRow.LineNumber - 1, "NFD=0; NG=") + "].Duration", pAttributeInErr);
		EndIf;
		If vHasErrors Then
			Break;
		EndIf;
	EndDo;
	// Check for period intersection
	vPeriods = Object.CheckInPeriods.Unload();
	vPeriods.Sort("PeriodFrom, PeriodTo");
	vCurPeriodTo = '00010101';
	For Each vPeriodsRow In vPeriods Do
		If ValueIsFilled(vCurPeriodTo) Then
			If BegOfDay(vPeriodsRow.PeriodFrom) < vCurPeriodTo Then
				vHasErrors = True; 
				vMsgTextRu = vMsgTextRu + "Ошибка в строке таблицы заездов, которая начинается с даты " + Format(vPeriodsRow.PeriodFrom, "DF=dd.MM.yyyy") + ". Период пересекается с предыдущим!" + Chars.LF;
				vMsgTextEn = vMsgTextEn + "Error in check-in periods table line starting with date " + Format(vPeriodsRow.PeriodFrom, "DF=dd.MM.yyyy") + ". Period is intersecting with previous one!" + Chars.LF;
				pAttributeInErr = ?(pAttributeInErr = "", "CheckInPeriods", pAttributeInErr);
				Break;
			EndIf;
		Else
			vCurPeriodTo = BegOfDay(vPeriodsRow.PeriodTo);
		EndIf;
	EndDo;
	// Check errors
	If vHasErrors Then
		pMessage = "ru = '" + TrimAll(vMsgTextRu) + "';" + "en = '" + TrimAll(vMsgTextEn) + "';" + "de = '" + TrimAll(vMsgTextEn) + "'";
	EndIf;
	Return vHasErrors;
EndFunction // CheckPeriods

// -----------------------------------------------------------------------------
&AtServer
Procedure AddCheckInPeriod(pMgrObj, pCheckInDate, pDuration, pCheckOutDate, pHotel)
	pMgrObj.Hotel = pHotel;
	pMgrObj.RoomQuota = Object.Ref;
	pMgrObj.CheckInDate = pCheckInDate;
	pMgrObj.Duration = pDuration;
	pMgrObj.CheckOutDate = pCheckOutDate;
	pMgrObj.Read();
	If Not pMgrObj.Selected() Then
		// Check intersection with manual periods
		If CheckIntersectionWithManualPeriods(pCheckInDate, pCheckOutDate) Then
			Return;
		EndIf;
		
		// Write period
		pMgrObj.Hotel = pHotel;
		pMgrObj.RoomQuota = Object.Ref;
		pMgrObj.CheckInDate = pCheckInDate;
		pMgrObj.Duration = pDuration;
		pMgrObj.CheckOutDate = pCheckOutDate;
		pMgrObj.IsManual = False;
		pMgrObj.Write(True);
			EndIf;
EndProcedure // AddCheckInPeriod

// -----------------------------------------------------------------------------
&AtServer
Function CheckIntersectionWithManualPeriods(pCheckInDate, pCheckOutDate)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomRateCheckInPeriods.Hotel AS Hotel,
	|	RoomRateCheckInPeriods.RoomQuota AS RoomQuota,
	|	RoomRateCheckInPeriods.CheckInDate AS CheckInDate,
	|	RoomRateCheckInPeriods.Duration AS Duration,
	|	RoomRateCheckInPeriods.CheckOutDate AS CheckOutDate,
	|	RoomRateCheckInPeriods.IsManual AS IsManual,
	|	RoomRateCheckInPeriods.IsNotActive AS IsNotActive
	|FROM
	|	InformationRegister.RoomQuotaCheckInPeriods AS RoomRateCheckInPeriods
	|WHERE
	|	RoomRateCheckInPeriods.Hotel IN HIERARCHY(&qHotel)
	|	AND RoomRateCheckInPeriods.RoomQuota = &qRoomQuota
	|	AND RoomRateCheckInPeriods.IsManual
	|	AND NOT RoomRateCheckInPeriods.IsNotActive
	|	AND RoomRateCheckInPeriods.CheckInDate < &qCheckOutDate
	|	AND RoomRateCheckInPeriods.CheckOutDate > &qCheckInDate
	|
	|ORDER BY
	|	CheckInDate";
	vQry.SetParameter("qHotel", Object.Hotel);
	vQry.SetParameter("qRoomQuota", Object.Ref);
	vQry.SetParameter("qCheckInDate", pCheckInDate);
	vQry.SetParameter("qCheckOutDate", pCheckOutDate);
	vPeriods = vQry.Execute().Unload();
	If vPeriods.Count() > 0 Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // CheckIntersectionWithManualPeriods 

// -----------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	SetObjectAndFormAttributeConformity(pCurrentObject, "Object");
	// Check room quota attributes
	If ValueIsFilled(pCurrentObject.BaseRoomQuota) Then
		If pCurrentObject.BaseRoomQuota.DeletionMark Then
			vUM = New UserMessage();
			vUM.SetData(pCurrentObject);
			vUM.Field = "BaseRoomQuota";
			vUM.Text = NStr("en='Allotment to write rooms off is marked for deletion!';ru='Квота, из которой должны списываться номера, помечена на удаление!';de='Allotment, aus der die Zimmer abgeschrieben werden müssen, ist zum Löschen markiert!'");
			vUM.Message();
			pCancel = True;
		EndIf;
		If pCurrentObject.BaseRoomQuota.IsFolder Then
			vUM = New UserMessage();
			vUM.SetData(pCurrentObject);
			vUM.Field = "BaseRoomQuota";
			vUM.Text = NStr("en='Allotment to write rooms off could not be folder!';ru='Квота, из которой должны списываться номера, не должна быть группой!';de='Allotment, aus der die Zimmer abgeschrieben werden müssen, darf keine Gruppe sein!'");
			vUM.Message();
			pCancel = True;
		EndIf;
	EndIf;
	If pCurrentObject.AllotmentBusinessType = Enums.AllotmentBusinessTypes.BusinessBlock Then
		If Not ValueIsFilled(pCurrentObject.ClientType) Then
			If Not cmCheckUserPermissions("HavePermissionToSkipInputOfClientType") Then
				vUM = New UserMessage();
				vUM.SetData(pCurrentObject);
				vUM.Field = "ClientType";
				vUM.Text = NStr("en='Client type should be filled in the analytics panel!';ru='Тип клиента должен быть заполнен в панели аналитики!';de='Der Kundentyp sollte im Analytics-Panel ausgefüllt werden!'");
				vUM.Message();
				pCancel = True;
			EndIf;
		EndIf;
		If Not ValueIsFilled(pCurrentObject.SourceOfBusiness) Then
			If Not cmCheckUserPermissions("HavePermissionToSkipInputOfReservationSourceOfBusiness") Then
				vUM = New UserMessage();
				vUM.SetData(pCurrentObject);
				vUM.Field = "SourceOfBusiness";
				vUM.Text = NStr("en='Source of business should be filled in the analytics panel!';ru='Источник должен быть заполнен в панели аналитики!';de='Die Geschäftsquelle sollte im Analysepanel ausgefüllt werden!'");
				vUM.Message();
				pCancel = True;
			EndIf;
		EndIf;
		If Not ValueIsFilled(pCurrentObject.MarketingCode) Then
			If Not cmCheckUserPermissions("HavePermissionToSkipInputOfReservationMarketingCode") Then
				vUM = New UserMessage();
				vUM.SetData(pCurrentObject);
				vUM.Field = "MarketingCode";
				vUM.Text = NStr("en='Marketing code should be filled in the analytics panel!';ru='Направление маркетинга должно быть заполнено в панели аналитики!';de='Das Marketing-Code sollte im Analytics-Panel ausgefüllt werden!'");
				vUM.Message();
				pCancel = True;
			EndIf;
		EndIf;
		If Not ValueIsFilled(pCurrentObject.TripPurpose) Then
			If Not cmCheckUserPermissions("HavePermissionToSkipInputOfReservationTripPurpose") Then
				vUM = New UserMessage();
				vUM.SetData(pCurrentObject);
				vUM.Field = "TripPurpose";
				vUM.Text = NStr("en='Trip purpose should be filled in the analytics panel!';ru='Цель визита должна быть заполнена в панели аналитики!';de='Der Reisezweck sollte im Analytics-Panel ausgefüllt werden!'");
				vUM.Message();
				pCancel = True;
			EndIf;
		EndIf;
	EndIf;
	If pCurrentObject.DoCharge Then
		If Not ValueIsFilled(pCurrentObject.Company) Then
			vUM = New UserMessage();
			vUM.SetData(pCurrentObject);
			vUM.Field = "Company";
			vUM.Text = NStr("en='Company has to be specified for the commitment allotment!';ru='У <жесткого> блока необходимо указать фирму!';de='Die Kompanie muss für die Commitment Allotment angegeben werden!'");
			vUM.Message();
			pCancel = True;
		EndIf;
	EndIf;
	If pCurrentObject.IsForCheckInPeriods Then
		If pCurrentObject.CheckInPeriods.Count() > 0 Then
			vMessage = "";
			vAttributeInErr = "";
			vCancel = CheckPeriods(vMessage, vAttributeInErr);
			If vCancel Then
				pCancel = True;
				vUM = New UserMessage();
				vUM.SetData(pCurrentObject);
				vUM.Field = ?(IsBlankString(vAttributeInErr), "CheckInPeriods", vAttributeInErr);
				vUM.Text = NStr(vMessage);
				vUM.Message();
			EndIf;
		EndIf;
	EndIf;
	If pCurrentObject.RoomTypes.Count() > 0 Then
		vMessage = "";
		vAttributeInErr = "";
		vCancel = CheckRoomTypes(vMessage, vAttributeInErr);
		If vCancel Then
			pCancel = True;
			vUM = New UserMessage();
			vUM.SetData(pCurrentObject);
			vUM.Field = ?(IsBlankString(vAttributeInErr), "RoomTypes", vAttributeInErr);
			vUM.Text = NStr(vMessage);
			vUM.Message();
		EndIf;
	EndIf;
	If pCancel Then
		Return;
	EndIf;
	If pCurrentObject.IsNew() Then
		If pCurrentObject.AllotmentBusinessType = Enums.AllotmentBusinessTypes.BusinessBlock Then
			If pCurrentObject.BudgetNumberOfAdults = 0 And pCurrentObject.BudgetNumberOfTeenagers = 0 And pCurrentObject.BudgetNumberOfChildren = 0 And pCurrentObject.BudgetNumberOfInfants = 0 Then
				pCurrentObject.BudgetNumberOfAdults = 1;
			EndIf;
			If Not ValueIsFilled(pCurrentObject.BudgetCurrency) And ValueIsFilled(pCurrentObject.Hotel) Then
				pCurrentObject.BudgetCurrency = pCurrentObject.Hotel.BaseCurrency;
			EndIf;
		EndIf;
	Else
		vRef = Object.Ref;
		If pCurrentObject.SourceOfBusiness <> vRef.SourceOfBusiness Or
		   pCurrentObject.MarketingCode <> vRef.MarketingCode Or
		   pCurrentObject.ClientType <> vRef.ClientType Or
		   pCurrentObject.TripPurpose <> vRef.TripPurpose Or
		   pCurrentObject.RoomRate <> vRef.RoomRate Then
			DoBudgetRecalculation = True;
		EndIf;
	EndIf;
	// Process color change
	If ClearColor Then
		pCurrentObject.ColorHexString = "";
		pCurrentObject.Color = New ValueStorage(Undefined);
	Else
		If PickColor Then
			pCurrentObject.ColorHexString = tcOnServer.ColorToHex(Color);
			pCurrentObject.Color = New ValueStorage(tcOnServer.HexToColor(pCurrentObject.ColorHexString));	
		EndIf;
	EndIf;
	// Fill list of deleted objects
	DeletedDocuments.Clear();
	vRef = Object.Ref;
	If ValueIsFilled(vRef) Then
		For Each vRoomTypesRow In vRef.RoomTypes Do
			If ValueIsFilled(vRoomTypesRow.SetRoomQuota) Then
				If Object.RoomTypes.Unload().Find(vRoomTypesRow.SetRoomQuota, "SetRoomQuota") = Undefined Then
					DeletedDocuments.Add(vRoomTypesRow.SetRoomQuota);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // BeforeWriteAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure AfterWriteAtServer(pCurrentObject, pWriteParameters)
	DoNotClose = False;
	// Process periods and room types
	If Not pCurrentObject.DeletionMark Then
		Try
			If pCurrentObject.IsForCheckInPeriods Then
				If pCurrentObject.CheckInPeriods.Count() > 0 Then
					SaveCheckInPeriods(pCurrentObject);
				Else
					// Delete previously added periods
					vMgrObj = InformationRegisters.RoomQuotaCheckInPeriods.CreateRecordManager();
					DeleteCheckInPeriods(vMgrObj);
				EndIf;
			EndIf;
		Except
			vError = cmGetRootErrorDescription(ErrorInfo());
			DoNotClose = True;
			vUM = New UserMessage();
			vUM.SetData(pCurrentObject);
			vUM.Field = "CheckInPeriods";
			vUM.Text = vError;
			vUM.Message();
		EndTry;
		If Not DoNotClose Then
			Try
				SaveRoomTypes(pCurrentObject);
			Except
				vError = cmGetRootErrorDescription(ErrorInfo());
				DoNotClose = True;
				vUM = New UserMessage();
				vUM.SetData(pCurrentObject);
				vUM.Field = "RoomTypes";
				vUM.Text = vError;
				vUM.Message();
				WriteLogEvent(NStr("en='Wizard.FillAllowedHotelAccommodationPeriodsList';ru='Мастер.ЗаполнитьСписокРазрешенныхПериодовПроживания';de='Wizard.FillAllowedHotelAccommodationPeriodsList'"), EventLogLevel.Warning, , , vError);
			EndTry;
		EndIf;
		// Clear bad references
		For Each vRoomTypesRow In pCurrentObject.RoomTypes Do
			If ValueIsFilled(vRoomTypesRow.SetRoomQuota) Then
				If cmIsBrokenRef("Document.SetRoomQuota", vRoomTypesRow.SetRoomQuota) Then
					vRoomTypesRow.SetRoomQuota = Documents.SetRoomQuota.EmptyRef();
				EndIf;
			EndIf;
		EndDo;
		// Process change of the allotment type
		If Not DoNotClose Then
			If DoBudgetRecalculation Or 
			   ValueIsFilled(OldAllotmentType) And 
			  (OldDoWriteOff <> pCurrentObject.DoWriteOff Or OldTreatAsTentativeBooking <> pCurrentObject.TreatAsTentativeBooking) Then
				Try
					vAllotmentDocs = pCurrentObject.pmGetAllotmentDocuments();
					For Each vAllotmentDocsRow In vAllotmentDocs Do
						vDocObj = vAllotmentDocsRow.Ref.GetObject();
						vDocObjWasChanged = False;
						If DoBudgetRecalculation Then
							If TypeOf(vDocObj) = Type("DocumentObject.Reservation") And (vDocObj.ReservationStatus.IsActive Or vDocObj.ReservationStatus.IsPreliminary) Then
								If ValueIsFilled(pCurrentObject.ClientType) And pCurrentObject.ClientType <> vDocObj.ClientType Then
									vDocObj.ClientType = pCurrentObject.ClientType;
									vDocObjWasChanged = True;
								EndIf;
								If ValueIsFilled(pCurrentObject.SourceOfBusiness) And pCurrentObject.SourceOfBusiness <> vDocObj.SourceOfBusiness Then
									vDocObj.SourceOfBusiness = pCurrentObject.SourceOfBusiness;
									vDocObjWasChanged = True;
								EndIf;
								If ValueIsFilled(pCurrentObject.MarketingCode) And pCurrentObject.MarketingCode <> vDocObj.MarketingCode Then
									vDocObj.MarketingCode = pCurrentObject.MarketingCode;
									vDocObjWasChanged = True;
								EndIf;
								If ValueIsFilled(pCurrentObject.TripPurpose) And pCurrentObject.TripPurpose <> vDocObj.TripPurpose Then
									vDocObj.TripPurpose = pCurrentObject.TripPurpose;
									vDocObjWasChanged = True;
								EndIf;
							EndIf;
						EndIf;
						vDocObj.Write(DocumentWriteMode.Posting);
						If vDocObjWasChanged Then
							If TypeOf(vDocObj) = Type("DocumentObject.Reservation") Then
								vDocObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
							EndIf;
						EndIf;
					EndDo;
					DoBudgetRecalculation = False;
				Except
					vError = cmGetRootErrorDescription(ErrorInfo());
					DoNotClose = True;
					vUM = New UserMessage();
					vUM.SetData(pCurrentObject);
					vUM.Field = "AllotmentType";
					vUM.Text = vError;
					vUM.Message();
					// Restore old allotment type
					pCurrentObject.AllotmentType = OldAllotmentType;
					pCurrentObject.DoWriteOff = OldDoWriteOff;
					pCurrentObject.TreatAsTentativeBooking = OldTreatAsTentativeBooking;
				EndTry;
			EndIf;
		EndIf;
		// Recalculate business block forecast
		If Not DoNotClose Then
			If NeedForecastRecalculation Then
				vError = CalculateBudgetAtServer(True);
				If Not IsBlankString(vError) Then
					DoNotClose = True;
					vUM = New UserMessage();
					vUM.SetData(pCurrentObject);
					vUM.Field = "BudgetNumberOfAdults";
					vUM.Text = vError;
					vUM.Message();
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	// Save object if it was modified
	If pCurrentObject.Modified() Then
		pCurrentObject.Write();
	EndIf;
	// Refresh form
	ThisObject.Read();
	// Form caption
	If Not pCurrentObject.IsNew() Then
		If pCurrentObject.AllotmentBusinessType = Enums.AllotmentBusinessTypes.BusinessBlock Then
			ThisObject.Title = NStr("en='Business block'; ru='Бизнес-блок'; de='Geschäftsblöck'");
			ThisObject.Title = TrimAll(pCurrentObject.Description) + " (" + ThisObject.Title + ")";
		EndIf;
	EndIf;
	// Save initial object state
	OldAllotmentType = pCurrentObject.AllotmentType;
	OldDoWriteOff = pCurrentObject.DoWriteOff;
	OldTreatAsTentativeBooking = pCurrentObject.TreatAsTentativeBooking;
EndProcedure // AfterWriteAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	If ValueIsFilled(Object.Ref) Then
		Notify("Allotment.Write", Object.Ref, FormOwner);
		If Not Object.DeletionMark And Object.AllotmentBusinessType = PredefinedValue("Enum.AllotmentBusinessTypes.BusinessBlock") Then
			Items.FormCancelBusinessBlock.Enabled = True;
			Items.FormCancelBusinessBlock.Visible = True;
		EndIf;
		// Check if period was changed
		If ValueIsFilled(PeriodFromOnOpen) And ValueIsFilled(PeriodToOnOpen) And 
		   ValueIsFilled(Object.PeriodFrom) And ValueIsFilled(Object.PeriodTo) Then
			vPeriodFromIsChanged = False;   
			vPeriodToIsChanged = False;   
			If BegOfDay(Object.PeriodFrom) < BegOfDay(PeriodFromOnOpen) Then
				vPeriodFromIsChanged = True;
			EndIf;
			If BegOfDay(Object.PeriodTo) > BegOfDay(PeriodToOnOpen) Then
				vPeriodToIsChanged = True;
			EndIf;
			If vPeriodFromIsChanged Or vPeriodToIsChanged Then
				If ThereAreRoomsInAllotmentAtServer(Object.Ref) Then
					ShowQueryBox(New NotifyDescription("AddRoomsToTheNewDatesAfterAnswer", ThisObject, New Structure("PeriodFromIsChanged, PeriodToIsChanged, OldPeriodFrom, OldPeriodTo", vPeriodFromIsChanged, vPeriodToIsChanged, PeriodFromOnOpen, PeriodToOnOpen)), NStr("en='Add rooms to the allotment new days?'; ru='Добавить номера в новые даты квоты?'; de='Zimmern zu neuen Tagen hinzufügen?'"), QuestionDialogMode.YesNo, 15, DialogReturnCode.No, , DialogReturnCode.No);
				EndIf;
			EndIf;
		EndIf;
		PeriodFromOnOpen = Object.PeriodFrom;
		PeriodToOnOpen = Object.PeriodTo;
	EndIf;
EndProcedure // AfterWrite

// -----------------------------------------------------------------------------
&AtServerNoContext
Function ThereAreRoomsInAllotmentAtServer(pAllotment)
	vResult = False;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	COUNT(Operations.Ref) AS Counter
	|FROM
	|	Document.SetRoomQuota AS Operations
	|WHERE
	|	Operations.RoomQuota = &qAllotment
	|	AND Operations.Posted";
	vQry.SetParameter("qAllotment", pAllotment);
	vRes = vQry.Execute().Unload();
	If vRes.Count() > 0 Then
		If vRes.Get(0).Counter > 0 Then
			vResult = True;
		EndIf;
	EndIf;
	Return vResult;
EndFunction // ThereAreRoomsInAllotmentAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AddRoomsToTheNewDatesAfterAnswer(pUA, pExtraParams) Export
	If pUA = DialogReturnCode.Yes Then
		vMessage = "";
		If Not AddRoomsToTheNewDatesAtServer(pExtraParams, vMessage) Then
			ShowMessageBox(, TrimAll(NStr("en='Failed to add rooms to the allotment due to the error: '; 
			                              |ru='Не удалось добавить номера в квоту из-за ошибки: '; 
										  |de='Fehler beim Hinzufügen von Zimmern zum Allotment aufgrund des Fehlers: '") + Chars.LF + Chars.LF + 
			                         vMessage), , NStr("en='Error!'; ru='Ошибка!'; de='Fehler!'"));
		Else
			ShowMessageBox(, NStr("en='Done!'; ru='Готово!'; de='Fertig!'"), 2);
		EndIf;
		Notify("Allotment.Write", Object.Ref, FormOwner);
	EndIf;
EndProcedure // AddRoomsToTheNewDatesAfterAnswer

// -----------------------------------------------------------------------------
&AtServer
Function AddRoomsToTheNewDatesAtServer(pExtraParams, rMessage)
	vSuccess = True;
	rMessage = "";
	Try
		BeginTransaction(DataLockControlMode.Managed);
		If pExtraParams.PeriodFromIsChanged Then
			AddRoomsToAllotmentAtServer(pExtraParams.OldPeriodFrom, Object.PeriodFrom, pExtraParams.OldPeriodFrom);
		EndIf;
		If pExtraParams.PeriodToIsChanged Then
			AddRoomsToAllotmentAtServer(pExtraParams.OldPeriodTo - (24*3600), pExtraParams.OldPeriodTo, Object.PeriodTo);
		EndIf;
		CommitTransaction();
	Except
		rMessage = cmGetRootErrorDescription(ErrorInfo());
		vSuccess = False;
	EndTry;
	Return vSuccess;
EndFunction // AddRoomsToTheNewDatesAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure AddRoomsToAllotmentAtServer(pSourceDate, pDateFrom, pDateTo) Export
	vHotel = Object.Hotel;
	If Not ValueIsFilled(vHotel) Then
		vHotel = SessionParameters.CurrentHotel;
	EndIf;
	
	vSourceDateFrom = cm0SecondShift(cmMovePeriodFromToReferenceHour(pSourceDate, ?(ValueIsFilled(Object.RoomRate), Object.RoomRate, vHotel.RoomRate)));
	vSourceDateTo = vSourceDateFrom + 24*3600;

	vDateFrom = cm0SecondShift(cmMovePeriodFromToReferenceHour(pDateFrom, ?(ValueIsFilled(Object.RoomRate), Object.RoomRate, vHotel.RoomRate)));
	vDateTo = vDateFrom + (pDateTo - pDateFrom);

	vRemains = Undefined;
	If Object.AllotmentType = Enums.AllotmentTypes.Tentative Then
		vRemains = cmCalculateRoomQuotaForecastResources(Object.Ref, vHotel, , vSourceDateFrom, vSourceDateTo);
	Else
		vRemains = cmCalculateRoomQuotaResources(Object.Ref, vHotel, , , vSourceDateFrom, vSourceDateTo);
	EndIf;
	
	// Add rooms
	For Each vRemainsRow In vRemains Do
		If vRemainsRow.RoomsRemains > 0 And ValueIsFilled(vRemainsRow.RoomType) Then
			cmAddRoomsToAllotment(Object.Ref, Object.RoomRate, vRemainsRow.RoomType, vDateFrom, vDateTo, vRemainsRow.RoomsRemains);
		EndIf;
	EndDo;
EndProcedure // AddRoomsToAllotmentAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypesSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	If pField.Name = "RoomTypesSetRoomQuota" Then
		pStandardProcessing = False;
		vRowData = Items.RoomTypes.RowData(pSelectedRow);
		If vRowData <> Undefined And ValueIsFilled(vRowData.SetRoomQuota) Then
			OpenForm("Document.SetRoomQuota.ObjectForm", New Structure("Key", vRowData.SetRoomQuota), ThisObject, vRowData.SetRoomQuota);
		EndIf;
	EndIf;
EndProcedure // RoomTypesSelection

// -----------------------------------------------------------------------------
&AtServer
Procedure FlatRateIsUsedForUnderallotmentPenaltyCalculationOnChangeAtServer()
	If Object.FlatRateIsUsedForUnderallotmentPenaltyCalculation Then
		Items.FlatRateRoomType.Enabled = True;
	Else
		Items.FlatRateRoomType.Enabled = False;
	EndIf;
EndProcedure // FlatRateIsUsedForUnderallotmentPenaltyCalculationOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure FlatRateIsUsedForUnderallotmentPenaltyCalculationOnChange(pItem)
	FlatRateIsUsedForUnderallotmentPenaltyCalculationOnChangeAtServer();
EndProcedure // FlatRateIsUsedForUnderallotmentPenaltyCalculationOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowAvailability(pCommand)
	If Not ValueIsFilled(Object.Ref) Or Modified Then
		If Not Write() Then
			Return;
		EndIf;
	EndIf;

	// APDEX
	vKeyOperation = "Catalog.RoomQuotas.Form.tcAllotmentVacantRooms.OpenForm";
	APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

	If ValueIsFilled(Object.PeriodFrom) And ValueIsFilled(Object.PeriodTo) And Object.PeriodTo >= Object.PeriodFrom Then
		OpenForm("Catalog.RoomQuotas.Form.tcAllotmentVacantRooms", New Structure("Hotel, Allotment, PeriodFrom, NumberOfDays, Mode", Object.Hotel, Object.Ref, Object.PeriodFrom, (Object.PeriodTo - Object.PeriodFrom) / (24 * 3600) + 1, 1), ThisObject, Object.Ref);
	Else
		OpenForm("Catalog.RoomQuotas.Form.tcAllotmentVacantRooms", New Structure("Hotel, Allotment, Mode", Object.Hotel, Object.Ref, 1), ThisObject, Object.Ref);
	EndIf;
EndProcedure // ShowAvailability

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowInHouse(pCommand)
	If ValueIsFilled(Object.Ref) Then
		// APDEX
		vKeyOperation = "Document.Accommodation.Form.tcAccommodationListForm.InHouseGuests.OpenForm";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

		OpenForm("Document.Accommodation.Form.tcAccommodationListForm", New Structure("Allotment, SelFilterStatus, SelShowAllGuests", Object.Ref, 0, 0), ThisObject, Object.Ref);
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Write allotment first!'; ru='Сначала сохраните квоту!'; de='Sparen Sie zuerst die Allotment!'"));
	EndIf;
EndProcedure // ShowInHouse

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowReservations(pCommand)
	If ValueIsFilled(Object.Ref) Then
		// APDEX
		vKeyOperation = "Document.Reservation.Form.tcReservationListForm.OpenForm";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

		OpenForm("Document.Reservation.ListForm", New Structure("SelAllotment, SelDocPeriod, SelFilterStatus, SelShowAllGuests", Object.Ref, '00010101', "&ACTIVE", 0), ThisObject);
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Write allotment first!'; ru='Сначала сохраните квоту!'; de='Sparen Sie zuerst die Allotment!'"));
	EndIf;
EndProcedure // ShowReservations

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowResourceReservations(pCommand)
	If ValueIsFilled(Object.Ref) Then
		OpenForm("Document.ResourceReservation.ListForm", New Structure("SelAllotment, SelDocPeriod, SelFilterStatus", Object.Ref, '00010101', "&ACTIVE"), ThisObject);
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Write allotment first!'; ru='Сначала сохраните квоту!'; de='Sparen Sie zuerst die Allotment!'"));
	EndIf;
EndProcedure // ShowResourceReservations

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeClose(pCancel, pExit, pMessageText, pStandardProcessing)
	If Not pExit Then
		If DoNotClose Then
			DoNotClose = False;
			pCancel = True;
		EndIf;
	EndIf;
EndProcedure // BeforeClose

// -----------------------------------------------------------------------------
&AtServer
Procedure RefreshAvailabilityAtServer()
	For Each vRTRow In Object.RoomTypes Do
		If Not vRTRow.IsPriceSetting Then
			FillAvailableRoomsAtServer(vRTRow);
		EndIf;
	EndDo;
EndProcedure // RefreshAvailabilityAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure RefreshAvailability(pCommand)
	RefreshAvailabilityAtServer();
EndProcedure // RefreshAvailability

// -----------------------------------------------------------------------------
&AtServer
Procedure RoomRateOnChangeAtServer()
	If ValueIsFilled(Object.RoomRate) Then
		If Not ValueIsFilled(Object.Service) Then
			vAccService = Object.RoomRate.AccommodationService;
			If ValueIsFilled(vAccService) Then
				Object.Service = vAccService;
			EndIf;
		EndIf;
		If ValueIsFilled(Object.RoomRate.ClientType) Then
			Object.ClientType = Object.RoomRate.ClientType;
		EndIf;
		If ValueIsFilled(Object.RoomRate.SourceOfBusiness) Then
			Object.SourceOfBusiness = Object.RoomRate.SourceOfBusiness;
		EndIf;
		If ValueIsFilled(Object.RoomRate.MarketingCode) Then
			Object.MarketingCode = Object.RoomRate.MarketingCode;
		EndIf;
		FillAnalyticsTitleAtServer();
	EndIf;
	PriceNumberOfPersonsOnChangeAtServer();
EndProcedure // RoomRateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRateOnChange(pItem)
	RoomRateOnChangeAtServer();
EndProcedure // RoomRateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PricesPriceOnChange(pItem)
	vCurData = pItem.Parent.CurrentData;
	If vCurData <> Undefined And vCurData.Price > 0 Then
		vHotel = Object.Hotel;
		If Not ValueIsFilled(vHotel) Then
			vHotel = tcOnServer.cmGetSessionParametersAttribute("CurrentHotel");
		EndIf;
		If Not ValueIsFilled(vCurData.Currency) Then
			vCurData.Currency = tcOnServer.cmGetAttributeByRef(vHotel, "BaseCurrency");
		EndIf;
		If vCurData.NumberOfPersons = 0 And vCurData.NumberOfAdults = 0 And 
		   vCurData.NumberOfTeenagers = 0 And vCurData.NumberOfChildren = 0 And vCurData.NumberOfInfants = 0 Then
			vDefaultNumberOfPersons = 1;
			If ValueIsFilled(vHotel) Then
				vWrkDefaultNumberOfPersons = tcOnServer.cmGetAttributeByRef(vHotel, "DefaultNumberOfReservationGuests");
				If vWrkDefaultNumberOfPersons > 0 Then
					vDefaultNumberOfPersons = vWrkDefaultNumberOfPersons;
				EndIf;
			EndIf;
			vCurData.NumberOfAdults = vDefaultNumberOfPersons;
			vCurData.NumberOfPersons = (vCurData.NumberOfAdults + vCurData.NumberOfTeenagers + vCurData.NumberOfChildren + vCurData.NumberOfInfants);
		EndIf;
	EndIf;
EndProcedure // PricesPriceOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure HideZeros(pCommand)
	Items.RoomTypesHideZeros.Check = Not Items.RoomTypesHideZeros.Check;
	DoHideZeroes();
EndProcedure // HideZeros

// -----------------------------------------------------------------------------
&AtClient
Procedure DoHideZeroes()
	If Items.RoomTypesHideZeros.Check Then
		vFilter = New Structure();	
		vFilter.Insert("RoomQuantityIsNotZero", True);	
		vFilter.Insert("IsPriceSetting", False);	
		vFilterStruct = New FixedStructure(vFilter);
		Items.RoomTypes.RowFilter = vFilterStruct;
	Else
		vFilter = New Structure();	
		vFilter.Insert("IsPriceSetting", False);	
		vFilterStruct = New FixedStructure(vFilter);
		Items.RoomTypes.RowFilter = vFilterStruct;
	EndIf;
EndProcedure // DoHideZeros
	
// --------------------------------------------------------------------------------
&AtClient
Procedure DoShowPrices()
	vFilter = New Structure();
	vFilter.Insert("IsPriceSetting", True);	
	vFilterStruct = New FixedStructure(vFilter);
	Items.Prices.RowFilter = vFilterStruct;
EndProcedure // DoShowPrices

// -----------------------------------------------------------------------------
&AtServer
Procedure AllotmentBusinessTypeOnChangeAtServer()
	VisibleItems();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AllotmentBusinessTypeOnChange(Item)
	AllotmentBusinessTypeOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure EventsBeforeDeleteRow(pItem, pCancel)
	pCancel = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure EventsBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder, pParameter)
	OpenForm("Catalog.GuestGroups.ObjectForm", New Structure("Allotment, Basis, CheckInDate, CheckOutDate, Customer, Contract, Agent, RoomRate, Company, Hotel, Focus, SourceOfBusiness, MarketingCode, ClientType, TripPurpose", Object.Ref, Object.Ref, Object.PeriodFrom, Object.PeriodTo, Object.Customer, Object.Contract, Object.Agent, Object.RoomRate, Object.Company, Object.Hotel, "Events", Object.SourceOfBusiness, Object.MarketingCode, Object.ClientType, Object.TripPurpose), ThisObject);
	pCancel = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure EventsRefreshRequestProcessing()
	FillEvents();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure EventsSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	vCurData = Items.Events.CurrentData;
	If vCurData <> Undefined Then
		OpenForm("Catalog.GuestGroups.ObjectForm", New Structure("Key, Focus", vCurData.GuestGroup, "Events"), ThisObject, vCurData.GuestGroup);
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure EventsBeforeRowChange(pItem, pCancel)
	pCancel = True;
	vCurData = Items.Events.CurrentData;
	If vCurData <> Undefined Then
		OpenForm("Catalog.GuestGroups.ObjectForm", New Structure("Key, Focus", vCurData.GuestGroup, "Events"), ThisObject, vCurData.GuestGroup);
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupsSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	vCurData = Items.GuestGroups.CurrentData;
	If vCurData <> Undefined Then
		OpenForm("Catalog.GuestGroups.ObjectForm", New Structure("Key, Focus", vCurData.GuestGroup, "Rooms"), ThisObject, vCurData.GuestGroup);
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupsBeforeRowChange(pItem, pCancel)
	pCancel = True;
	vCurData = Items.GuestGroups.CurrentData;
	If vCurData <> Undefined Then
		OpenForm("Catalog.GuestGroups.ObjectForm", New Structure("Key, Focus", vCurData.GuestGroup, "Rooms"), ThisObject, vCurData.GuestGroup);
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupsBeforeDeleteRow(pItem, pCancel)
	pCancel = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupsBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder, pParameter)
	pCancel = True;
	OpenForm("Catalog.GuestGroups.ObjectForm", New Structure("Allotment, Basis, CheckInDate, CheckOutDate, Customer, Contract, Agent, RoomRate, Company, Hotel, Focus, SourceOfBusiness, MarketingCode, ClientType, TripPurpose", Object.Ref, Object.Ref, Object.PeriodFrom, Object.PeriodTo, Object.Customer, Object.Contract, Object.Agent, Object.RoomRate, Object.Company, Object.Hotel, "Rooms", Object.SourceOfBusiness, Object.MarketingCode, Object.ClientType, Object.TripPurpose), ThisObject);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenFolios(pCommand)
	If ValueIsFilled(Object.Ref) Then
		// APDEX
		vKeyOperation = "CommonForm.tcFoliosForm.OpenForm";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

		vParametersStructure = New Structure("IsNew, WasPosted, IsFormModified, ObjectRef", False, False, Modified, Object.Ref);
		OpenForm("CommonForm.tcFoliosForm", New Structure("ParametersStructure", vParametersStructure), ThisObject, UUID);
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Save allotment first!'; ru='Сначала сохраните квоту!'; de='Speichern Sie die Allotment zuerst!'"));
	EndIf;
EndProcedure // OpenFolios

// -----------------------------------------------------------------------------
&AtClient
Procedure RefreshGuestGroups(pCommand)
	FillGuestGroups();
EndProcedure // RefreshGuestGroups

// -----------------------------------------------------------------------------
&AtClient
Procedure RefreshEvents(pCommand)
	FillEvents();
EndProcedure // RefreshEvents

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "Catalog.RoomQuotas.Changed" Or pEventName = "Allotment.Write" Then
		If ValueIsFilled(pParameter) And pParameter = Object.Ref Then
			ThisObject.Read();
			// Budget title
			FillGroupBudgetTitleAtServer();
		EndIf;
	ElsIf pEventName = "Catalog.GuestGroups.Changed" Then
		If ValueIsFilled(pParameter) And TypeOf(pParameter) = Type("CatalogRef.GuestGroups") And 
		   tcOnServer.cmGetAttributeByRef(pParameter, "Allotment") = Object.Ref Then
			DoRefreshGuestGroups = True;
			DoRefreshEvents = True;
			AttachIdleHandler("RefreshLists", 1, True);
		EndIf;
	ElsIf pEventName = "Document.Reservation.Write" Or pEventName = "Document.Reservation.WriteNew" Or 
	      pEventName = "Document.Accommodation.Write" Or pEventName = "Document.Accommodation.WriteNew" Then
		If ValueIsFilled(pParameter) And 
		  (TypeOf(pParameter) = Type("DocumentRef.Reservation") Or TypeOf(pParameter) = Type("DocumentRef.Accommodation")) And 
		   tcOnServer.cmGetAttributeByRef(pParameter, "RoomQuota") = Object.Ref Then
			DoRefreshGuestGroups = True;
			AttachIdleHandler("RefreshLists", 1, True);
		EndIf;
	ElsIf pEventName = "Document.ResourceReservation.Write" Or pEventName = "Document.ResourceReservation.WriteNew" Then
		If ValueIsFilled(pParameter) And 
		   TypeOf(pParameter) = Type("DocumentRef.ResourceReservation") Then
			vGuestGroup = tcOnServer.cmGetAttributeByRef(pParameter, "GuestGroup");
			If ValueIsFilled(vGuestGroup) And tcOnServer.cmGetAttributeByRef(vGuestGroup, "Allotment") = Object.Ref Then
				DoRefreshEvents = True;
				AttachIdleHandler("RefreshLists", 1, True);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // NotificationProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure RefreshLists() Export
	If IsInputAvailable() Then
		RefreshListsAtServer();
	Else
		AttachIdleHandler("RefreshLists", 1, True);
	EndIf;
EndProcedure // RefreshLists

// -----------------------------------------------------------------------------
&AtServer
Procedure RefreshListsAtServer()
	If DoRefreshGuestGroups Then
		FillGuestGroups();
		RefreshAvailabilityAtServer();
		DoRefreshGuestGroups = False;
	EndIf;
	If DoRefreshEvents Then
		FillEvents();
		DoRefreshEvents = False;
	EndIf;
EndProcedure // RefreshListsAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure IsCommitmentOnChange(pItem)
	If Object.IsCommitment And Object.AllotmentBusinessType = PredefinedValue("Enum.AllotmentBusinessTypes.Allotment") Then
		Object.AllotmentBusinessType = PredefinedValue("Enum.AllotmentBusinessTypes.Commitment");
	ElsIf Not Object.IsCommitment And Object.AllotmentBusinessType = PredefinedValue("Enum.AllotmentBusinessTypes.Commitment") Then
		Object.AllotmentBusinessType = PredefinedValue("Enum.AllotmentBusinessTypes.Allotment");
	EndIf;
	AllotmentBusinessTypeOnChangeAtServer();
EndProcedure // IsCommitmentOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SourceOfBusinessOnChange(pItem)
	FillAnalyticsTitleAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure MarketingCodeOnChange(pItem)
	FillAnalyticsTitleAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ClientTypeOnChange(pItem)
	PriceNumberOfPersonsOnChangeAtServer();
	FillAnalyticsTitleAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure TripPurposeOnChange(pItem)
	FillAnalyticsTitleAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillAnalyticsTitleAtServer()
	vTitle = NStr("en='Analytics'; ru='Аналитика'; de='Analytik'");
	If ValueIsFilled(Object.SourceOfBusiness) Or ValueIsFilled(Object.MarketingCode) Or ValueIsFilled(Object.ClientType) Or ValueIsFilled(Object.TripPurpose) Then
		vTitle = vTitle + ":";
	EndIf;
	vAddColon = False;
	If ValueIsFilled(Object.SourceOfBusiness) Then
		vTitle = vTitle + ?(vAddColon, ",", "") + " " + TrimAll(Object.SourceOfBusiness);
		vAddColon = True;
	EndIf;
	If ValueIsFilled(Object.MarketingCode) Then
		vTitle = vTitle + ?(vAddColon, ",", "") + " " + TrimAll(Object.MarketingCode);
		vAddColon = True;
	EndIf;
	If ValueIsFilled(Object.ClientType) Then
		vTitle = vTitle + ?(vAddColon, ",", "") + " " + TrimAll(Object.ClientType);
		vAddColon = True;
	EndIf;
	If ValueIsFilled(Object.TripPurpose) Then
		vTitle = vTitle + ?(vAddColon, ",", "") + " " + TrimAll(Object.TripPurpose);
		vAddColon = True;
	EndIf;
	Items.GroupAnalytics.Title = vTitle;
EndProcedure // FillAnalyticsTitleAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillAutoReleaseTitleAtServer()
	vTitle = NStr("en='Auto release'; ru='Авт. освобождение'; de='Auto Freigabe'");
	If Object.ReleaseTime > 0 Or ValueIsFilled(Object.ReleaseDate) Then
		vTitle = vTitle + ":";
	EndIf;
	vAddColon = False;
	If Object.ReleaseTime > 0 Then
		vTitle = vTitle + ?(vAddColon, ",", "") + " " + NStr("en='in'; ru='за'; de='in'") + " " + Format(Object.ReleaseTime, "NFD=0; NG=") + " " + NStr("en='days'; ru='дня'; de='Tagen'");
		vAddColon = True;
	EndIf;
	If ValueIsFilled(Object.ReleaseDate) Then
		vTitle = vTitle + ?(vAddColon, ",", "") + " " + NStr("en='on '; ru=''; de='am '") + Format(Object.ReleaseDate, "DF='dd MMMM yyyy'");
		vAddColon = True;
	EndIf;
	Items.GroupRelease.Title = vTitle;
EndProcedure // FillAutoReleaseTitleAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillManagersTitleAtServer()
	vTitle = NStr("en='Managers'; ru='Менеджеры'; de='Manager'");
	If ValueIsFilled(Object.ReservationManager) Or ValueIsFilled(Object.MICEManager) Or ValueIsFilled(Object.RevenueManager) Then
		vTitle = vTitle + ":";
	EndIf;
	vAddColon = False;
	If ValueIsFilled(Object.ReservationManager) Then
		vTitle = vTitle + ?(vAddColon, ",", "") + " " + TrimAll(Object.ReservationManager);
		vAddColon = True;
	EndIf;
	If ValueIsFilled(Object.MICEManager) Then
		vTitle = vTitle + ?(vAddColon, ",", "") + " " + TrimAll(Object.MICEManager);
		vAddColon = True;
	EndIf;
	If ValueIsFilled(Object.RevenueManager) Then
		vTitle = vTitle + ?(vAddColon, ",", "") + " " + TrimAll(Object.RevenueManager);
		vAddColon = True;
	EndIf;
	Items.GroupManagers.Title = vTitle;
EndProcedure // FillManagersTitleAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure CreateProformaInvoice(pCommand)
	// Save group changes if any
	If Modified Then
		If Not Write() Then
			Return;
		EndIf;
	EndIf;
	OpenForm("Document.ProformaInvoice.ObjectForm", New Structure("Basis", Object.Ref));
EndProcedure // CreateProformaInvoice

// -----------------------------------------------------------------------------
&AtClient
Procedure CancelBusinessBlock(pCommand)
	If Modified Then
		ShowMessageBox(, NStr("en='Save changes first!'; ru='Сначала сохраните изменения!'; de='Speichern Änderungen zuerst!'"));
	Else
		If ThereAreActiveReservationsForBusinessBlock(Object.Ref) Then
			ShowQueryBox(New NotifyDescription("CancelBusinessBlockAfterConfirmation", ThisObject), 
			             NStr("en='Cancel business block? There are active bookings for this business block. The bookings will not be cancelled, but their association with the block will be cleared!'; 
						      |ru='Отменить бизнес-блок? Существуют действующие брони по этому бизнес-блоку. Брони не отменятся, но их привязка к блоку будет очищена!'; 
							  |de='Business-Block aufheben? Für diesen Business-Block liegen aktive Reservierungen vor. Die Reservierungen werden dadurch nicht storniert, die Business-Block bindung wird jedoch aufgehoben!'"), 
						 QuestionDialogMode.YesNo, , DialogReturnCode.No);
		Else
			ShowQueryBox(New NotifyDescription("CancelBusinessBlockAfterConfirmation", ThisObject), 
			             NStr("en='Cancel the business block and all associated room availability changes?'; 
						      |ru='Отменить бизнес-блок и все связанные с ним изменения доступности номеров?'; 
							  |de='Business-Block und alle damit verbundenen Zimmerverfügbarkeitsänderungen stornieren?'"), 
						 QuestionDialogMode.YesNo, , DialogReturnCode.No);
		EndIf;
	EndIf;
EndProcedure // CancelBusinessBlock

// -----------------------------------------------------------------------------
&AtClient
Procedure CancelBusinessBlockAfterConfirmation(pUserAnswer, pExtraParams) Export
	If pUserAnswer = DialogReturnCode.Yes Then
		vReasonsList = GetAllBusinessBlockCancellationReasonsList();
		If vReasonsList.Count() > 0 Then
			OpenForm("Catalog.BusinessBlockCancellationReasons.ChoiceForm", New Structure("ChoiceMode", True), ThisObject, , , , New NotifyDescription("CancelBusinessBlockAfterReasonChoice", ThisObject), FormWindowOpeningMode.LockOwnerWindow); 
		Else
			vErrorMessage = "";
			If CancelBusinessBlockAtServer(, vErrorMessage) Then
				Notify("Allotment.Write", Object.Ref, FormOwner);
				ThisObject.Close();
			EndIf;
		EndIf;
	EndIf;
EndProcedure // CancelBusinessBlockAfterConfirmation

// -----------------------------------------------------------------------------
&AtClient
Procedure CancelBusinessBlockAfterReasonChoice(pReason, pExtraParams) Export 
	If ValueIsFilled(pReason) And TypeOf(pReason) = Type("CatalogRef.BusinessBlockCancellationReasons") Then
		vErrorMessage = "";
		If CancelBusinessBlockAtServer(pReason, vErrorMessage) Then
			Notify("Allotment.Write", Object.Ref, FormOwner);
			ThisObject.Close();
		Else
			ShowMessageBox(, NStr("en='Failed to cancel business block with error: '; ru='Не удалось отменить бизнес-блок из-за ошибки: '; de='Der Geschäftsblock konnte wegen folgendem Fehler nicht gelöscht werden: '") + vErrorMessage);
		EndIf;
	EndIf;
EndProcedure // CancelBusinessBlockAfterConfirmation

// -----------------------------------------------------------------------------
&AtServer
Function CancelBusinessBlockAtServer(pReason = Undefined, rErrorMessage = "")
	vSuccess = True;
	Try
		vObj = Object.Ref.GetObject();
		vObj.AllotmentType = Enums.AllotmentTypes.Cancelled;
		vObj.AuthorOfAnnulation = SessionParameters.CurrentUser;
		vObj.DateOfAnnulation = CurrentSessionDate();
		vObj.AnnulationReason = pReason;
		vObj.DeletionMark = False;
		vObj.Write();
	Except
		rErrorMessage = cmGetRootErrorDescription(ErrorInfo());
		vSuccess = False;
	EndTry;
	Return vSuccess;
EndFunction // CancelBusinessBlockAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetAllBusinessBlockCancellationReasonsList()
	vReasons = cmGetAllBusinessBlockCancellationReasons();
	vReasonsList = New ValueList();
	vReasonsList.LoadValues(vReasons.UnloadColumn("CancellationReason"));
	Return vReasonsList;
EndFunction // GetAllBusinessBlockCancellationReasonsList

// -----------------------------------------------------------------------------
&AtServerNoContext
Function ThereAreActiveReservationsForBusinessBlock(pBusinessBlock)
	vFound = False;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reservation.Ref AS Ref
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	Reservation.RoomQuota = &qRoomQuota
	|	AND Reservation.Posted
	|	AND (Reservation.ReservationStatus.IsActive
	|			OR Reservation.ReservationStatus.IsPreliminary)
	|
	|UNION ALL
	|
	|SELECT
	|	Accommodation.Ref
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.RoomQuota = &qRoomQuota
	|	AND Accommodation.Posted
	|	AND Accommodation.AccommodationStatus.IsActive";
	vQry.SetParameter("qRoomQuota", pBusinessBlock);
	vDocs = vQry.Execute().Unload();
	If vDocs.Count() > 0 Then
		vFound = True;
	EndIf;
	Return vFound;
EndFunction // ThereAreActiveReservationsForBusinessBlock

// -----------------------------------------------------------------------------
&AtServer
Procedure FillGroupBudgetTitleAtServer()
	vTitle = NStr("en='Estimated budget'; ru='Предполагаемый бюджет'; de='Geschätztes Budget'");
	If Object.RoomNights <> 0 Or Object.BudgetAmount <> 0 Then
		vTitle = NStr("en='Budget:'; ru='Бюджет:'; de='Budget:'");
		If Object.RoomNights <> 0 Then
			vTitle = vTitle + " " + Format(Object.RoomNights, "NFD=0; NZ=; NG=") + " " + NStr("en='room nights'; ru='номероночей'; de='Zimmer Nächte'");
		EndIf;
		If Object.BudgetAmount <> 0 Then
			If Object.RoomNights <> 0 Then
				vTitle = vTitle + ",";
			EndIf;
			vTitle = vTitle + " " + cmFormatSum(Object.BudgetAmount, Object.BudgetCurrency);
		EndIf;
	EndIf;
	Items.GroupBudget.Title = vTitle;
EndProcedure // FillGroupBudgetTitleAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillGroupPermissionsTitleAtServer()
	vTitle = NStr("en='Permissions'; ru='Разрешения'; de='Berechtigungen'");
	If Object.OverbookingIsNotAllowed Or Object.CustomerOrContractChangeIsNotAllowed Then
		vTitle = vTitle + ": ";
		If Object.OverbookingIsNotAllowed Then
			vTitle = vTitle + NStr("en='overbooking is forbiden'; ru='перебронирование запрещено'; de='überbuchung ist verboten'");
		EndIf;
		If Object.CustomerOrContractChangeIsNotAllowed Then
			If Object.OverbookingIsNotAllowed Then
				vTitle = vTitle + "; ";
			EndIf;
			vTitle = vTitle + NStr("en='customer is fixed'; ru='контрагент фиксирован'; de='Firma ist fixiert'");
		EndIf;
	EndIf;
	Items.GroupPermissions.Title = vTitle;
EndProcedure // FillGroupPermissionsTitleAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillGroupBasisTitleAtServer();
	vTitle = NStr("en='Take rooms from '; ru='Брать номера из '; de='Zimmeren entnehmen aus '");
	If ValueIsFilled(Object.BaseRoomQuota) Then
		vTitle = vTitle + TrimAll(Object.BaseRoomQuota);
	Else
		vTitle = vTitle + NStr("en='room inventory'; ru='номерного фонда'; de='dem Zimmerbestand'");
	EndIf;
	Items.GroupBasis.Title = vTitle;
EndProcedure // FillGroupBasisTitleAtServer

// -----------------------------------------------------------------------------
&AtServer
Function CalculateBudgetAtServer(pRecalculateForecast = False)
	If Object.AllotmentBusinessType <> Enums.AllotmentBusinessTypes.BusinessBlock Then
		Return "";
	EndIf;
	// Calculation
	vMessage = Catalogs.RoomQuotas.CalculateBusinessBlockBudget(Object.Ref, pRecalculateForecast);
	ThisObject.Read();
	// Budget title
	FillGroupBudgetTitleAtServer();
	// Reset flag that forecast need to be recalculated
	If IsBlankString(vMessage) Then
		NeedForecastRecalculation = False;
		If Items.DecorationRecalculationWarning.Visible <> NeedForecastRecalculation Then
			Items.DecorationRecalculationWarning.Visible = NeedForecastRecalculation;
		EndIf;
	EndIf;
	// Return error message
	Return vMessage;
EndFunction // CalculateBudgetAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure FillBudget(pCommand)
	If Modified Or Not ValueIsFilled(Object.Ref) Then
		If Not ThisObject.Write() Then
			Return;
		EndIf;
	EndIf;
	vMessage = CalculateBudgetAtServer(False);
	If Not IsBlankString(vMessage) Then
		ShowMessageBox(, vMessage);
	Else
		ShowMessageBox(, NStr("en='Done!'; ru='Готово!'; de='Fertig!'"), 1);
	EndIf;
EndProcedure // FillBudget

// -----------------------------------------------------------------------------
&AtClient
Procedure CalculateBudget(pCommand)
	If Modified Or Not ValueIsFilled(Object.Ref) Then
		If ValueIsFilled(Object.Ref) Then
			NeedForecastRecalculation = True;
		EndIf;
		If Not ThisObject.Write() Then
			Return;
		Else
			ShowMessageBox(, NStr("en='Done!'; ru='Готово!'; de='Fertig!'"), 1);
		EndIf;
	Else
		vMessage = CalculateBudgetAtServer(True);
		If Not IsBlankString(vMessage) Then
			ShowMessageBox(, vMessage);
		Else
			ShowMessageBox(, NStr("en='Done!'; ru='Готово!'; de='Fertig!'"), 1);
		EndIf;
	EndIf;
EndProcedure // CalculateBudget

// -----------------------------------------------------------------------------
&AtClient
Procedure BudgetADROnChange(pItem)
	Object.BudgetReservationAmount = Object.BudgetADR * Object.RoomNights;
	Object.BudgetAmount = Object.BudgetMICEAmount + Object.BudgetReservationAmount;
	If Object.BudgetAmount < 0 Then
		Object.BudgetAmount = 0;
	EndIf;
	// Budget title
	FillGroupBudgetTitleAtServer();
EndProcedure // BudgetADROnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure BudgetReservationAmountOnChange(pItem)
	Object.BudgetAmount = Object.BudgetMICEAmount + Object.BudgetReservationAmount;
	If Object.BudgetAmount < 0 Then
		Object.BudgetAmount = 0;
	EndIf;
	If Object.RoomNights <> 0 And Object.BudgetAmount <> 0 Then
		Object.BudgetADR = Round(Object.BudgetAmount / Object.RoomNights, 2);
	EndIf;
	// Budget title
	FillGroupBudgetTitleAtServer();
EndProcedure // BudgetReservationAmountOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure BudgetMICEAmountOnChange(pItem)
	Object.BudgetAmount = Object.BudgetMICEAmount + Object.BudgetReservationAmount;
	If Object.BudgetAmount < 0 Then
		Object.BudgetAmount = 0;
	EndIf;
	// Budget title
	FillGroupBudgetTitleAtServer();
EndProcedure // BudgetMICEAmountOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowAvailableRooms(pCommand)
	If Not ValueIsFilled(Object.Ref) Or Modified Then
		If Not Write() Then
			Return;
		EndIf;
	EndIf;

	// APDEX
	vKeyOperation = "CommonForm.tcAvailableRoomsReport.OpenForm";
	APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);
	
	// Open availability form
	OpenForm("CommonForm.tcAvailableRoomsReport", New Structure("Allotment", Object.Ref), ThisObject, Object.Ref);
EndProcedure // ShowAvailableRooms

// ----------------------------------------------------------------------------
&AtServer
Function GetArrayOfAllClientTypes()
	vCTTable = cmGetAllClientTypes(?(ValueIsFilled(Object.Hotel), Object.Hotel, SessionParameters.CurrentHotel));
	vCTArray = vCTTable.UnloadColumn("ClientType");
	Return vCTArray;
EndFunction // GetArrayOfAllClientTypes

// ----------------------------------------------------------------------------
&AtServer
Function GetArrayOfAllSourceOfBusiness()
	vSOBTable = cmGetAllSourcesOfBusiness();
	vSOBArray = vSOBTable.UnloadColumn("SourceOfBusiness");
	Return vSOBArray;
EndFunction // GetListOfAllSourceOfBusiness

// ----------------------------------------------------------------------------
&AtServer
Function GetArrayOfAllTripPurposes()
	vTPTable = cmGetAllTripPurposes();
	vTPArray = vTPTable.UnloadColumn("TripPurpose");
	Return vTPArray;
EndFunction // GetArrayOfAllTripPurposes

// ----------------------------------------------------------------------------
&AtServer
Procedure PriceNumberOfPersonsOnChangeAtServer()
	If ValueIsFilled(Object.Ref) Then
		vObjectRef = Object.Ref;
		If vObjectRef.RoomRate <> Object.RoomRate Or
		   vObjectRef.ClientType <> Object.ClientType Or
		   vObjectRef.BudgetNumberOfAdults <> Object.BudgetNumberOfAdults Or 
		   vObjectRef.BudgetNumberOfTeenagers <> Object.BudgetNumberOfTeenagers Or
		   vObjectRef.BudgetNumberOfChildren <> Object.BudgetNumberOfChildren Or
		   vObjectRef.BudgetNumberOfInfants <> Object.BudgetNumberOfInfants Then
			NeedForecastRecalculation = True;
		Else
			NeedForecastRecalculation = False;
		EndIf;
	Else
		NeedForecastRecalculation = False;
	EndIf;
	If Items.DecorationRecalculationWarning.Visible <> NeedForecastRecalculation Then
		Items.DecorationRecalculationWarning.Visible = NeedForecastRecalculation;
	EndIf;
EndProcedure // PriceNumberOfPersonsOnChangeAtServer

// ----------------------------------------------------------------------------
&AtClient
Procedure PriceNumberOfPersonsOnChange(pItem)
	PriceNumberOfPersonsOnChangeAtServer();
EndProcedure // PriceNumberOfPersonsOnChange
