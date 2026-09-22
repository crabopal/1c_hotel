
#Region Variables

Var OldCustomer;
Var OldContract;
Var OldAgent;

#EndRegion        

#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel)
	If ThisObject.DataExchange.Load Then
		Return;
	EndIf;
	If IsNew() Then
		If Not IsFolder Then
			// Set guest group description prefix
			If IsBlankString(Description) Then
				If ValueIsFilled(Owner) Then
					If Not IsBlankString(Owner.GuestGroupDescriptionPrefix) Then
						If Code = 0 Then
							SetNewCode();
						EndIf;
						Description = TrimR(Owner.GuestGroupDescriptionPrefix) + Format(Code, "ND=12; NFD=0; NZ=; NG=");
					EndIf;
				EndIf;
			EndIf;
			// Author and date
			If Not ValueIsFilled(Author) Then
				Author = SessionParameters.CurrentUser;
				CreateDate = CurrentSessionDate();
			EndIf;
			// Tourist tax
			If ValueIsFilled(Owner) And Owner.TouristTaxIsChargedToTheMainGroupGuestByDefault Then
				If Not TouristicTaxIsCalculatedForMainGroupDocumentOnly Then
					TouristicTaxIsCalculatedForMainGroupDocumentOnly = True;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If Not IsFolder Then
		If IsChanged() Then
			LastChangeAuthor = SessionParameters.CurrentUser;
			LastChangeDate = CurrentSessionDate();
		EndIf;
	EndIf;
	If ValueIsFilled(ClientDoc) And ValueIsFilled(Owner) And Owner.FillGroupIDs And ValueIsFilled(Customer) And Not IsBlankString(Customer.GroupCode) Then
		If TypeOf(ClientDoc) = Type("DocumentRef.Accommodation") And ClientDoc.AccommodationStatus.IsActive And ClientDoc.AccommodationStatus.IsInHouse Or 
		   TypeOf(ClientDoc) = Type("DocumentRef.ResourceReservation") And ClientDoc.ResourceReservationStatus.ServicesAreDelivered Then
			If IsBlankString(ID) Or Not IsBlankString(ID) And Upper(Left(ID, StrLen(TrimAll(Customer.GroupCode)))) <> Upper(TrimAll(Customer.GroupCode)) Then
				FillGroupID();
			EndIf;
		EndIf;
	EndIf;
	OldCustomer = Undefined;
	OldContract = Undefined;
	OldAgent = Undefined;
	If Not IsFolder Then
		If Not IsNew() Then
			OldCustomer = Ref.Customer;
			OldContract = Ref.Contract;
			OldAgent = Ref.Agent;
		EndIf;
	EndIf;
	If DeletionMark Then
		WriteLogEvent(NStr("en='SuspiciousEvents.GuestGroupSetDeletionMark'; de='SuspiciousEvents.GuestGroupSetDeletionMark'; ru='SuspiciousEvents.GuestGroupSetDeletionMark'"), EventLogLevel.Warning, Metadata(), Ref, NStr("en='Set guest group deletion mark';ru='Установка отметки удаления';de='Erstellung der Löschmarkierung'") + Chars.LF + TrimAll(Customer) + ", " + TrimAll(Client) + ", " + TrimAll(GuestsCheckedIn) + ", " + Format(CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(CheckOutDate, "DF='dd.MM.yyyy HH:mm'"));
	EndIf;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
Procedure OnCopy(pCopiedObject)
	// Author and date
	If Not IsFolder Then
		Author = SessionParameters.CurrentUser;
		CreateDate = CurrentSessionDate();
	EndIf;
EndProcedure // OnCopy

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If ThisObject.DataExchange.Load Then
		Return;
	EndIf;
	// Update charging rule folio parameters
	For Each vCRRow In ChargingRules Do
		If ValueIsFilled(vCRRow.ChargingFolio) And vCRRow.ChargingFolio.GuestGroup = Ref Then
			vDoFolioUpdate = False;
			vFolioObj = vCRRow.ChargingFolio.GetObject();
			If vFolioObj.Hotel <> Owner Then
				vFolioObj.Hotel = Owner;
				vDoFolioUpdate = True;
			EndIf;
			If vFolioObj.GuestGroup <> Ref Then
				vFolioObj.GuestGroup = Ref;
				vDoFolioUpdate = True;
			EndIf;
			If vFolioObj.DateTimeFrom <> CheckInDate Then
				vFolioObj.DateTimeFrom = CheckInDate;
				vDoFolioUpdate = True;
			EndIf;
			If vFolioObj.DateTimeTo <> CheckOutDate Then
				vFolioObj.DateTimeTo = CheckOutDate;
				vDoFolioUpdate = True;
			EndIf;
			If vFolioObj.Client <> Client Then
				If Not ValueIsFilled(vFolioObj.Customer) Or ValueIsFilled(vFolioObj.Hotel) And vFolioObj.Customer = vFolioObj.Hotel.IndividualsCustomer Then
					vFolioObj.Client = Client;
					vDoFolioUpdate = True;
				EndIf;
			EndIf;
			If vFolioObj.Contract <> Contract And ValueIsFilled(vFolioObj.PaymentMethod) And vFolioObj.PaymentMethod.IsByBankTransfer Then
				If OldContract = Undefined Or OldContract = vFolioObj.Contract Then
					vFolioObj.Customer = Contract.Owner;
					vFolioObj.Contract = Contract;
					vDoFolioUpdate = True;
				EndIf;
			EndIf;
			If vFolioObj.Customer <> Customer And ValueIsFilled(vFolioObj.PaymentMethod) And vFolioObj.PaymentMethod.IsByBankTransfer Then
				If OldCustomer = Undefined Or OldCustomer = vFolioObj.Customer Then
					vFolioObj.Customer = Customer;
					vFolioObj.Contract = Catalogs.Contracts.EmptyRef();
					vDoFolioUpdate = True;
				EndIf;
			EndIf;
			If vFolioObj.Agent <> Agent Then
				If OldAgent = Undefined Or OldAgent = vFolioObj.Agent Then
					vFolioObj.Agent = Agent;
					vDoFolioUpdate = True;
				EndIf;
			EndIf;
			If ValueIsFilled(vFolioObj.Contract) Then
				If ValueIsFilled(vFolioObj.Contract.Company) Then
					If vFolioObj.Company <> vFolioObj.Contract.Company Then
						vFolioObj.Company = vFolioObj.Contract.Company;
						vDoFolioUpdate = True;
					EndIf;
				EndIf;
			EndIf;
			If vFolioObj.LineNumber <> (ChargingRules.IndexOf(vCRRow) + 1) Then
				vFolioObj.LineNumber = ChargingRules.IndexOf(vCRRow) + 1;
				vDoFolioUpdate = True;
			EndIf;
			If vDoFolioUpdate Then
				vFolioObj.Write(DocumentWriteMode.Write);
			EndIf;
		EndIf;
	EndDo;    
EndProcedure // OnWrite

// -----------------------------------------------------------------------------
Procedure Filling(pBase, pFillingText, pStandardProcessing)
	If ValueIsFilled(pBase) Then
		If TypeOf(pBase) = Type("CatalogRef.RoomQuotas") Then
			Owner = pBase.Hotel;
			Allotment = pBase;
			Customer = pBase.Customer;
			Agent = pBase.Agent;
			Contract = pBase.Contract;
			RoomRate = pBase.RoomRate;
			vCheckInTime = cmGetDefaultCheckInTime(?(ValueIsFilled(RoomRate), RoomRate, ?(ValueIsFilled(Owner), Owner.RoomRate, Undefined)));
			CheckInDate = cm1SecondShift(pBase.PeriodFrom + (vCheckInTime - BegOfDay(vCheckInTime)));
			vCheckOutTime = cmGetDefaultCheckOutTime(?(ValueIsFilled(RoomRate), RoomRate, ?(ValueIsFilled(Owner), Owner.RoomRate, Undefined)));
			CheckOutDate = cm0SecondShift(pBase.PeriodTo + (vCheckOutTime - BegOfDay(vCheckOutTime)));
			If BegOfDay(CheckOutDate) > BegOfDay(CheckInDate) Then
				Duration = Round((BegOfDay(CheckOutDate) - BegOfDay(CheckInDate)) / (24 * 3600), 0);
			EndIf;
			GroupType = Catalogs.GroupTypes.RoomsAndResources;
			If ValueIsFilled(Allotment.ReservationManager) Then
				ReservationManager = Allotment.ReservationManager;
			EndIf;
			If ValueIsFilled(Allotment.MICEManager) Then
				MICEManager = Allotment.MICEManager;
			EndIf;
			If ValueIsFilled(Allotment.RevenueManager) Then
				MICEManager = Allotment.RevenueManager;
			EndIf;
		EndIf;		
	EndIf;
EndProcedure // Filling

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
// Gets list of reservations for this group
// Returns ValueTable
// -----------------------------------------------------------------------------
Function pmGetReservations(pPostedOnly = True, pActiveOnly = False, pCancelledOnly = False, pInWaitingListOnly = False, pDocRef = Undefined, pDocsList = Undefined) Export 
	If pPostedOnly = Undefined Then
		pPostedOnly = True;
	EndIf;
	vUseDocsList = False;
	If pDocsList <> Undefined Then
		vUseDocsList = True;
	EndIf;
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	Reservation.Ref AS Reservation,
	|	Reservation.Date AS Date,
	|	Reservation.Number AS Number,
	|	Reservation.Posted AS Posted,
	|	Reservation.DeletionMark AS DeletionMark,
	|	Reservation.IsMaster AS IsMaster,
	|	Reservation.ReservationStatus AS Status,
	|	Reservation.CheckInDate AS CheckInDate,
	|	Reservation.Duration AS Duration,
	|	Reservation.CheckOutDate AS CheckOutDate,
	|	Reservation.Guest AS Guest,
	|	Reservation.Room AS Room,
	|	Reservation.RoomType AS RoomType,
	|	Reservation.RoomQuantity AS RoomQuantity,
	|	Reservation.NumberOfPersons AS NumberOfPersons,
	|	Reservation.AccommodationType AS AccommodationType,
	|	Reservation.AccommodationType.SortCode AS AccommodationTypeSortCode,
	|	Reservation.RoomRate AS RoomRate,
	|	Reservation.RoomRateServiceGroup AS RoomRateServiceGroup,
	|	Reservation.ServicePackage AS ServicePackage,
	|	Reservation.HotelProduct AS HotelProduct,
	|	Reservation.Company AS Company,
	|	Reservation.NumberOfRooms AS NumberOfRooms,
	|	Reservation.NumberOfBeds AS NumberOfBeds,
	|	Reservation.NumberOfAdditionalBeds AS NumberOfAdditionalBeds,
	|	Reservation.NumberOfBedsPerRoom AS NumberOfBedsPerRoom,
	|	Reservation.NumberOfPersonsPerRoom AS NumberOfPersonsPerRoom,
	|	Reservation.ParentDoc AS ParentDoc,
	|	Reservation.Remarks AS Remarks,
	|	ISNULL(Reservation.Room.SortCode, 0) AS RoomSortCode,
	|	ISNULL(Reservation.RoomType.SortCode, 0) AS RoomTypeSortCode,
	|	Reservation.ExternalCode AS ExternalCode,
	|	Reservation.PointInTime AS PointInTime
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	Reservation.GuestGroup = &qGuestGroup
	|	AND (Reservation.Posted
	|			OR &qAll)" + 
		?(ValueIsFilled(pDocRef), " AND Reservation.Ref = &qDocRef ", "") + 
		?(vUseDocsList, " AND Reservation.Ref IN (&qDocsList) ", "") + 
		?(pActiveOnly, " AND Reservation.Posted AND (Reservation.ReservationStatus.IsActive OR Reservation.ReservationStatus.IsCheckIn OR Reservation.ReservationStatus.IsPreliminary) ", "") + 
		?(pCancelledOnly, " AND Reservation.Posted AND NOT Reservation.ReservationStatus.IsActive AND NOT Reservation.ReservationStatus.IsCheckIn AND NOT Reservation.ReservationStatus.IsPreliminary ", "") + 
		?(pInWaitingListOnly, " AND Reservation.Posted AND Reservation.ReservationStatus.IsInWaitingList AND NOT Reservation.ReservationStatus.IsCheckIn AND NOT Reservation.ReservationStatus.IsPreliminary ", "") + "
	|
	|ORDER BY
	|	RoomSortCode,
	|	RoomTypeSortCode,
	|	Number,
	|	CheckInDate,
	|	AccommodationTypeSortCode,
	|	Date,
	|	PointInTime";
	vQry.SetParameter("qGuestGroup", Ref);
	vQry.SetParameter("qAll", ?(ValueIsFilled(pDocRef), True, (Not pPostedOnly)));
	vQry.SetParameter("qDocRef", pDocRef);
	vQry.SetParameter("qDocsList", pDocsList);
	vDocs = vQry.Execute().Unload();
	Return vDocs;
EndFunction // pmGetReservations

// -----------------------------------------------------------------------------
// Gets list of accommodations for this group
// Returns ValueTable
// -----------------------------------------------------------------------------
Function pmGetAccommodations(pPostedOnly = True, pDocsList = Undefined) Export 
	If pPostedOnly = Undefined Then
		pPostedOnly = True;
	EndIf;
	vUseDocsList = False;
	If pDocsList <> Undefined Then
		vUseDocsList = True;
	EndIf;
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref AS Accommodation,
	|	Accommodation.Date AS Date,
	|	Accommodation.Number AS Number,
	|	Accommodation.Posted AS Posted,
	|	Accommodation.DeletionMark AS DeletionMark,
	|	Accommodation.IsMaster AS IsMaster,
	|	Accommodation.PayerAccommodation AS PayerAccommodation,
	|	Accommodation.AccommodationStatus AS Status,
	|	Accommodation.CheckInDate AS CheckInDate,
	|	Accommodation.Duration AS Duration,
	|	Accommodation.CheckOutDate AS CheckOutDate,
	|	Accommodation.Guest AS Guest,
	|	Accommodation.Room AS Room,
	|	Accommodation.RoomType AS RoomType,
	|	Accommodation.NumberOfPersons AS NumberOfPersons,
	|	Accommodation.AccommodationType AS AccommodationType,
	|	Accommodation.AccommodationType.SortCode AS AccommodationTypeSortCode,
	|	Accommodation.RoomRate AS RoomRate,
	|	Accommodation.RoomRateServiceGroup AS RoomRateServiceGroup,
	|	Accommodation.ServicePackage AS ServicePackage,
	|	Accommodation.HotelProduct AS HotelProduct,
	|	Accommodation.Company AS Company,
	|	Accommodation.NumberOfRooms AS NumberOfRooms,
	|	Accommodation.NumberOfBeds AS NumberOfBeds,
	|	Accommodation.NumberOfAdditionalBeds AS NumberOfAdditionalBeds,
	|	Accommodation.NumberOfBedsPerRoom AS NumberOfBedsPerRoom,
	|	Accommodation.NumberOfPersonsPerRoom AS NumberOfPersonsPerRoom,
	|	Accommodation.ParentDoc AS ParentDoc,
	|	Accommodation.Remarks AS Remarks,
	|	ISNULL(Accommodation.Room.SortCode, 0) AS RoomSortCode,
	|	Accommodation.ExternalCode AS ExternalCode,
	|	Accommodation.PointInTime AS PointInTime
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.GuestGroup = &qGuestGroup
	|	AND (Accommodation.Posted
	|			OR &qAll)
	|	AND (ISNULL(Accommodation.AccommodationStatus.IsActive, FALSE)
	|			OR &qAll)" + 
		?(vUseDocsList, " AND Accommodation.Ref IN (&qDocsList) ", "") + "
	|ORDER BY
	|	RoomSortCode,
	|	CheckInDate,
	|	AccommodationTypeSortCode,
	|	Number,
	|	Date,
	|	PointInTime";
	vQry.SetParameter("qGuestGroup", Ref);
	vQry.SetParameter("qAll", (Not pPostedOnly));
	vQry.SetParameter("qDocsList", pDocsList);
	vDocs = vQry.Execute().Unload();
	Return vDocs;
EndFunction // pmGetAccommodations

// -----------------------------------------------------------------------------
// Gets list of invoices with balances for this group
// Returns ValueTable
// -----------------------------------------------------------------------------
Function pmGetInvoices(pCustomer = Undefined, pContract = Undefined, pShowSettlements = False) Export 
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	Invoices.Ref AS Invoice,
	|	Invoices.Posted AS Posted,
	|	Invoices.Number AS InvoiceNumber,
	|	Invoices.Date AS InvoiceDate,
	|	Invoices.Company AS Company,
	|	Invoices.AccountingCustomer AS Customer,
	|	Invoices.AccountingContract AS Contract,
	|	Invoices.GuestGroup AS GuestGroup,
	|	Invoices.Sum AS Sum,
	|	Invoices.VATSum AS VATSum,
	|	Invoices.AccountingCurrency AS Currency,
	|	Invoices.Remarks AS Remarks,
	|	Invoices.Author AS Author,
	|	ISNULL(InvoiceAccountsBalance.SumBalance, 0) AS Balance,
	|	Invoices.CheckDate AS CheckDate,
	|	Invoices.PointInTime AS PointInTime,
	|	Invoices.Presentation AS Presentation
	|FROM
	|	Document.ProformaInvoice AS Invoices
	|		LEFT JOIN (SELECT
	|			InvoiceAccounts.Invoice AS Invoice,
	|			InvoiceAccounts.SumBalance AS SumBalance
	|		FROM
	|			AccumulationRegister.InvoiceAccounts.Balance(&qPeriod, GuestGroup = &qGuestGroup) AS InvoiceAccounts) AS InvoiceAccountsBalance
	|		ON Invoices.Ref = InvoiceAccountsBalance.Invoice
	|WHERE
	|	Invoices.GuestGroup = &qGuestGroup
	|	AND (Invoices.AccountingCustomer = &qCustomer
	|			OR &qCustomerIsEmpty)
	|	AND (Invoices.AccountingContract = &qContract
	|			OR &qContractIsEmpty)
	|	AND Invoices.Posted
	|
	|UNION ALL
	|
	|SELECT
	|	Settlements.Ref,
	|	Settlements.Posted,
	|	Settlements.Number,
	|	Settlements.Date,
	|	Settlements.Company,
	|	Settlements.AccountingCustomer,
	|	Settlements.AccountingContract,
	|	Settlements.GuestGroup,
	|	Settlements.Sum,
	|	Settlements.VATSum,
	|	Settlements.AccountingCurrency,
	|	Settlements.Remarks,
	|	Settlements.Author,
	|	ISNULL(InvoiceAccountsBalance.SumBalance, 0),
	|	Settlements.CheckDate,
	|	Settlements.PointInTime,
	|	Settlements.Presentation
	|FROM
	|	Document.Settlement AS Settlements
	|		LEFT JOIN (SELECT
	|			InvoiceAccounts.Invoice AS Invoice,
	|			InvoiceAccounts.SumBalance AS SumBalance
	|		FROM
	|			AccumulationRegister.InvoiceAccounts.Balance(&qPeriod, GuestGroup = &qGuestGroup) AS InvoiceAccounts) AS InvoiceAccountsBalance
	|		ON Settlements.Ref = InvoiceAccountsBalance.Invoice
	|WHERE
	|	&qShowSettlements
	|	AND Settlements.GuestGroup = &qGuestGroup
	|	AND (Settlements.AccountingCustomer = &qCustomer
	|			OR &qCustomerIsEmpty)
	|	AND (Settlements.AccountingContract = &qContract
	|			OR &qContractIsEmpty)
	|	AND Settlements.Posted
	|
	|ORDER BY
	|	Invoices.PointInTime " + ?(pShowSettlements, "DESC", "");
	vQry.SetParameter("qShowSettlements", pShowSettlements);
	vQry.SetParameter("qPeriod", '39991231235959');
	vQry.SetParameter("qGuestGroup", Ref);
	vQry.SetParameter("qCustomer", ?(ValueIsFilled(pCustomer), pCustomer, Owner.IndividualsCustomer));
	vQry.SetParameter("qCustomerIsEmpty", ?(pCustomer = Undefined, True, False));
	vQry.SetParameter("qContract", ?(ValueIsFilled(pCustomer), pContract, Owner.IndividualsContract));
	vQry.SetParameter("qContractIsEmpty", ?(pContract = Undefined, True, False));
	vDocs = vQry.Execute().Unload();
	Return vDocs;
EndFunction // pmGetInvoices

// -----------------------------------------------------------------------------
// Gets list of settlemets for this group
// Returns ValueTable
// -----------------------------------------------------------------------------
Function pmGetSettlements() Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	Settlements.Ref AS Invoice,
	|	Settlements.Posted AS Posted,
	|	Settlements.Number AS InvoiceNumber,
	|	Settlements.Date AS InvoiceDate,
	|	Settlements.Company AS Company,
	|	Settlements.AccountingCustomer AS Customer,
	|	Settlements.AccountingContract AS Contract,
	|	Settlements.GuestGroup AS GuestGroup,
	|	Settlements.Sum AS Sum,
	|	Settlements.VATSum AS VATSum,
	|	Settlements.AccountingCurrency AS Currency,
	|	Settlements.Remarks AS Remarks,
	|	Settlements.Author AS Author,
	|	0 AS Balance,
	|	Settlements.PointInTime AS PointInTime,
	|	Settlements.Presentation AS Presentation
	|FROM
	|	Document.Settlement AS Settlements
	|WHERE
	|	Settlements.GuestGroup = &qGuestGroup
	|	AND Settlements.Posted
	|ORDER BY
	|	Settlements.PointInTime";
	vQry.SetParameter("qPeriod", '39991231235959');
	vQry.SetParameter("qGuestGroup", Ref);
	vSettlements = vQry.Execute().Unload();
	Return vSettlements;
EndFunction // pmGetSettlements

// -----------------------------------------------------------------------------
Function pmGetUnpostedSettlements() Export
	vQry = New Query;
	vQry.Text =
	"SELECT
	|	Settlements.Ref AS Invoice,
	|	Settlements.Posted AS Posted,
	|	Settlements.Number AS InvoiceNumber,
	|	Settlements.Date AS InvoiceDate,
	|	Settlements.Company AS Company,
	|	Settlements.AccountingCustomer AS Customer,
	|	Settlements.AccountingContract AS Contract,
	|	Settlements.GuestGroup AS GuestGroup,
	|	Settlements.Sum AS Sum,
	|	Settlements.VATSum AS VATSum,
	|	Settlements.AccountingCurrency AS Currency,
	|	Settlements.Remarks AS Remarks,
	|	Settlements.Author AS Author,
	|	0 AS Balance,
	|	Settlements.PointInTime AS PointInTime,
	|	Settlements.Presentation AS Presentation
	|FROM
	|	Document.Settlement AS Settlements
	|WHERE
	|	Settlements.GuestGroup = &qGuestGroup
	|	AND NOT Settlements.DeletionMark
	|	AND NOT Settlements.Posted
	|
	|ORDER BY
	|	Settlements.PointInTime";
	vQry.SetParameter("qGuestGroup", Ref);
	Return vQry.Execute().Unload();
EndFunction // pmGetUnpostedSettlements

// -----------------------------------------------------------------------------
// Gets list of resource reservations for this group
// Returns ValueTable
// -----------------------------------------------------------------------------
Function pmGetResourceReservations(pPostedOnly = True) Export 
	If pPostedOnly = Undefined Then
		pPostedOnly = True;
	EndIf;
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	ResourceReservation.Ref AS Reservation,
	|	ResourceReservation.Posted AS Posted,
	|	ResourceReservation.DeletionMark AS DeletionMark,
	|	ResourceReservation.ResourceReservationStatus AS Status,
	|	ResourceReservation.DateTimeFrom AS DateTimeFrom,
	|	ResourceReservation.Duration AS Duration,
	|	ResourceReservation.DateTimeTo AS DateTimeTo,
	|	ResourceReservation.Client AS Client,
	|	ResourceReservation.Resource AS Resource,
	|	ResourceReservation.ResourceType AS ResourceType,
	|	ResourceReservation.NumberOfPersons AS NumberOfPersons,
	|	ResourceReservation.ParentDoc AS ParentDoc,
	|	ResourceReservation.ChargingFolio AS ChargingFolio
	|FROM
	|	Document.ResourceReservation AS ResourceReservation
	|WHERE
	|	ResourceReservation.GuestGroup = &qGuestGroup
	|	AND (ResourceReservation.Posted
	|			OR &qAll)
	|
	|ORDER BY
	|	ResourceReservation.DateTimeFrom,
	|	ResourceReservation.PointInTime";
	vQry.SetParameter("qGuestGroup", Ref);
	vQry.SetParameter("qAll", (Not pPostedOnly));
	vDocs = vQry.Execute().Unload();
	Return vDocs;
EndFunction // pmGetResourceReservations

// -----------------------------------------------------------------------------
Function pmGetRoomInventoryTotals(pCheckInDate = '00010101') Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	GroupTotals.GuestGroup,
	|	SUM(GroupTotals.ExpectedRoomsCheckedIn + GroupTotals.RoomsCheckedIn) AS RoomsReserved,
	|	SUM(GroupTotals.ExpectedBedsCheckedIn + GroupTotals.BedsCheckedIn) AS BedsReserved,
	|	SUM(GroupTotals.ExpectedAdditionalBedsCheckedIn + GroupTotals.AdditionalBedsCheckedIn) AS AdditionalBedsReserved,
	|	SUM(GroupTotals.ExpectedGuestsCheckedIn + GroupTotals.GuestsCheckedIn) AS GuestsReserved,
	|	SUM(GroupTotals.RoomsCheckedIn) AS RoomsCheckedIn,
	|	SUM(GroupTotals.BedsCheckedIn) AS BedsCheckedIn,
	|	SUM(GroupTotals.AdditionalBedsCheckedIn) AS AdditionalBedsCheckedIn,
	|	SUM(GroupTotals.GuestsCheckedIn) AS GuestsCheckedIn,
	|	SUM(GroupTotals.ExpectedRoomsCheckedIn) AS RoomsExpected,
	|	SUM(GroupTotals.ExpectedBedsCheckedIn) AS BedsExpected,
	|	SUM(GroupTotals.ExpectedAdditionalBedsCheckedIn) AS AdditionalBedsExpected,
	|	SUM(GroupTotals.ExpectedGuestsCheckedIn) AS GuestsExpected
	|FROM
	|	(SELECT
	|		RoomInventory.GuestGroup AS GuestGroup,
	|		RoomInventory.ExpectedRoomsCheckedIn AS ExpectedRoomsCheckedIn,
	|		RoomInventory.ExpectedBedsCheckedIn AS ExpectedBedsCheckedIn,
	|		RoomInventory.ExpectedAdditionalBedsCheckedIn AS ExpectedAdditionalBedsCheckedIn,
	|		RoomInventory.ExpectedGuestsCheckedIn AS ExpectedGuestsCheckedIn,
	|		RoomInventory.RoomsCheckedIn AS RoomsCheckedIn,
	|		RoomInventory.BedsCheckedIn AS BedsCheckedIn,
	|		RoomInventory.AdditionalBedsCheckedIn AS AdditionalBedsCheckedIn,
	|		RoomInventory.GuestsCheckedIn AS GuestsCheckedIn
	|	FROM
	|		AccumulationRegister.RoomInventory AS RoomInventory
	|	WHERE
	|		RoomInventory.GuestGroup = &qGuestGroup
	|		AND (RoomInventory.IsCheckIn
	|				OR RoomInventory.IsReservation)
	|		AND RoomInventory.RecordType = &qRecordType
	|		AND NOT RoomInventory.RoomType.DoesNotAffectRoomRevenueStatistics
	|		AND (NOT &qCheckInDateIsFilled
	|				OR &qCheckInDateIsFilled
	|					AND RoomInventory.CheckInAccountingDate = &qCheckInDate)) AS GroupTotals
	|
	|GROUP BY
	|	GroupTotals.GuestGroup";
	vQry.SetParameter("qGuestGroup", Ref);
	vQry.SetParameter("qRecordType", AccumulationRecordType.Expense);
	vQry.SetParameter("qCheckInDate", BegOfDay(pCheckInDate));
	vQry.SetParameter("qCheckInDateIsFilled", ValueIsFilled(pCheckInDate));
	Return vQry.Execute().Unload();
EndFunction // pmGetRoomInventoryTotals

// -----------------------------------------------------------------------------
Function pmGetSalesTotals(pRoom = Undefined, pDocsList = Undefined) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ChargedAmounts.Service AS Service,
	|	ChargedAmounts.FolioCurrency AS FolioCurrency,
	|	ChargedAmounts.Room AS Room,
	|	SUM(ChargedAmounts.SalesTurnover) AS SalesTurnover,
	|	SUM(ChargedAmounts.SalesWithoutVATTurnover) AS SalesWithoutVATTurnover,
	|	SUM(ChargedAmounts.SalesWithCommissionTurnover) AS SalesWithCommissionTurnover,
	|	SUM(ChargedAmounts.SalesWithCommissionWithoutVATTurnover) AS SalesWithCommissionWithoutVATTurnover,
	|	SUM(ChargedAmounts.DiscountSumTurnover) AS DiscountSumTurnover
	|INTO ChargedAmounts
	|FROM
	|	(SELECT
	|		SalesTurnovers.Service AS Service,
	|		SalesTurnovers.ReportingCurrency AS FolioCurrency,
	|		SalesTurnovers.Room AS Room,
	|		SalesTurnovers.Agent AS Agent,
	|		SalesTurnovers.Customer AS Customer,
	|		CASE
	|			WHEN NOT SalesTurnovers.Agent.Code IS NULL
	|					AND NOT ISNULL(SalesTurnovers.Agent.DoNotPostCommission, TRUE)
	|					AND SalesTurnovers.Agent = SalesTurnovers.Customer
	|					AND NOT SalesTurnovers.Customer.Code IS NULL
	|				THEN ISNULL(SalesTurnovers.SalesTurnover, 0) - ISNULL(SalesTurnovers.CommissionSumTurnover, 0)
	|			ELSE ISNULL(SalesTurnovers.SalesTurnover, 0)
	|		END AS SalesTurnover,
	|		CASE
	|			WHEN NOT SalesTurnovers.Agent.Code IS NULL
	|					AND NOT ISNULL(SalesTurnovers.Agent.DoNotPostCommission, TRUE)
	|					AND SalesTurnovers.Agent = SalesTurnovers.Customer
	|					AND NOT SalesTurnovers.Customer.Code IS NULL
	|				THEN ISNULL(SalesTurnovers.SalesWithoutVATTurnover, 0) - ISNULL(SalesTurnovers.CommissionSumWithoutVATTurnover, 0)
	|			ELSE ISNULL(SalesTurnovers.SalesWithoutVATTurnover, 0)
	|		END AS SalesWithoutVATTurnover,
	|		ISNULL(SalesTurnovers.SalesTurnover, 0) AS SalesWithCommissionTurnover,
	|		ISNULL(SalesTurnovers.SalesWithoutVATTurnover, 0) AS SalesWithCommissionWithoutVATTurnover,
	|		ISNULL(SalesTurnovers.DiscountSumTurnover, 0) AS DiscountSumTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				,
	|				,
	|				PERIOD,
	|				GuestGroup = &qGuestGroup
	|					AND (&qDocsListIsEmpty
	|						OR ParentDoc IN (&qDocsList))) AS SalesTurnovers) AS ChargedAmounts
	|
	|GROUP BY
	|	ChargedAmounts.Service,
	|	ChargedAmounts.FolioCurrency,
	|	ChargedAmounts.Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccountsReceivableForecastTurnovers.Service AS Service,
	|	AccountsReceivableForecastTurnovers.FolioCurrency AS FolioCurrency,
	|	AccountsReceivableForecastTurnovers.Room AS Room,
	|	ISNULL(AccountsReceivableForecastTurnovers.ParentDoc.ReservationStatus.IsActive, FALSE) AS IsActiveReservation,
	|	ISNULL(AccountsReceivableForecastTurnovers.ParentDoc.ReservationStatus.IsPreliminary, FALSE) AS IsPreliminaryReservation,
	|	ISNULL(AccountsReceivableForecastTurnovers.ParentDoc.AccommodationStatus.IsActive, FALSE) AS IsActiveAccommodation,
	|	ISNULL(AccountsReceivableForecastTurnovers.ParentDoc.ResourceReservationStatus.IsActive, FALSE) AS IsActiveResourceReservation,
	|	ISNULL(AccountsReceivableForecastTurnovers.SalesTurnover, 0) - ISNULL(AccountsReceivableForecastTurnovers.CommissionSumTurnover, 0) AS SalesTurnover,
	|	ISNULL(AccountsReceivableForecastTurnovers.SalesWithoutVATTurnover, 0) - ISNULL(AccountsReceivableForecastTurnovers.CommissionSumWithoutVATTurnover, 0) AS SalesWithoutVATTurnover,
	|	ISNULL(AccountsReceivableForecastTurnovers.ExpectedSalesTurnover, 0) - ISNULL(AccountsReceivableForecastTurnovers.ExpectedCommissionSumTurnover, 0) AS ExpectedSalesTurnover,
	|	ISNULL(AccountsReceivableForecastTurnovers.ExpectedSalesWithoutVATTurnover, 0) - ISNULL(AccountsReceivableForecastTurnovers.ExpectedCommissionSumWithoutVATTurnover, 0) AS ExpectedSalesWithoutVATTurnover,
	|	ISNULL(AccountsReceivableForecastTurnovers.SalesTurnover, 0) AS SalesWithCommissionTurnover,
	|	ISNULL(AccountsReceivableForecastTurnovers.SalesWithoutVATTurnover, 0) AS SalesWithCommissionWithoutVATTurnover,
	|	ISNULL(AccountsReceivableForecastTurnovers.ExpectedSalesTurnover, 0) AS ExpectedSalesWithCommissionTurnover,
	|	ISNULL(AccountsReceivableForecastTurnovers.ExpectedSalesWithoutVATTurnover, 0) AS ExpectedSalesWithCommissionWithoutVATTurnover,
	|	ISNULL(AccountsReceivableForecastTurnovers.DiscountSumTurnover, 0) AS DiscountSumTurnover
	|INTO ForecastAmounts
	|FROM
	|	AccumulationRegister.AccountsReceivableForecast.Turnovers(
	|			&qForecastPeriodFrom,
	|			&qForecastPeriodTo,
	|			PERIOD,
	|			GuestGroup = &qGuestGroup
	|				AND (&qDocsListIsEmpty
	|					OR ParentDoc IN (&qDocsList))) AS AccountsReceivableForecastTurnovers
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GuestGroupSales.Service AS Service,
	|	GuestGroupSales.Currency AS Currency,
	|	GuestGroupSales.Service.SortCode AS ServiceSortCode,
	|	GuestGroupSales.Currency.SortCode AS CurrencySortCode,
	|	SUM(GuestGroupSales.SalesTurnover) AS Sales,
	|	SUM(GuestGroupSales.SalesWithoutVATTurnover) AS SalesWithoutVAT,
	|	SUM(GuestGroupSales.SalesForecastTurnover) AS SalesForecast,
	|	SUM(GuestGroupSales.SalesWithoutVATForecastTurnover) AS SalesWithoutVATForecast,
	|	SUM(GuestGroupSales.ExpectedSalesTurnover) AS ExpectedSales,
	|	SUM(GuestGroupSales.ExpectedSalesWithoutVATTurnover) AS ExpectedSalesWithoutVAT,
	|	SUM(GuestGroupSales.SalesWithCommissionTurnover) AS SalesWithCommission,
	|	SUM(GuestGroupSales.SalesWithCommissionWithoutVATTurnover) AS SalesWithCommissionWithoutVAT,
	|	SUM(GuestGroupSales.SalesWithCommissionForecastTurnover) AS SalesWithCommissionForecast,
	|	SUM(GuestGroupSales.SalesWithCommissionWithoutVATForecastTurnover) AS SalesWithCommissionWithoutVATForecast,
	|	SUM(GuestGroupSales.ExpectedSalesWithCommissionTurnover) AS ExpectedSalesWithCommission,
	|	SUM(GuestGroupSales.ExpectedSalesWithCommissionWithoutVATTurnover) AS ExpectedSalesWithCommissionWithoutVAT,
	|	SUM(GuestGroupSales.DiscountSumTurnover) AS DiscountSum
	|FROM
	|	(SELECT
	|		ChargedAmounts.Service AS Service,
	|		ChargedAmounts.FolioCurrency AS Currency,
	|		ChargedAmounts.SalesTurnover AS SalesTurnover,
	|		ChargedAmounts.SalesWithoutVATTurnover AS SalesWithoutVATTurnover,
	|		0 AS SalesForecastTurnover,
	|		0 AS SalesWithoutVATForecastTurnover,
	|		0 AS ExpectedSalesTurnover,
	|		0 AS ExpectedSalesWithoutVATTurnover,
	|		ChargedAmounts.SalesWithCommissionTurnover AS SalesWithCommissionTurnover,
	|		ChargedAmounts.SalesWithCommissionWithoutVATTurnover AS SalesWithCommissionWithoutVATTurnover,
	|		0 AS SalesWithCommissionForecastTurnover,
	|		0 AS SalesWithCommissionWithoutVATForecastTurnover,
	|		0 AS ExpectedSalesWithCommissionTurnover,
	|		0 AS ExpectedSalesWithCommissionWithoutVATTurnover,
	|		ChargedAmounts.DiscountSumTurnover AS DiscountSumTurnover
	|	FROM
	|		ChargedAmounts AS ChargedAmounts
	|	WHERE
	|		(&qRoomIsEmpty
	|				OR NOT &qRoomIsEmpty
	|					AND ChargedAmounts.Room = &qRoom)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ForecastAmounts.Service,
	|		ForecastAmounts.FolioCurrency,
	|		0,
	|		0,
	|		ISNULL(ForecastAmounts.SalesTurnover, 0),
	|		ISNULL(ForecastAmounts.SalesWithoutVATTurnover, 0),
	|		ISNULL(ForecastAmounts.ExpectedSalesTurnover, 0),
	|		ISNULL(ForecastAmounts.ExpectedSalesWithoutVATTurnover, 0),
	|		0,
	|		0,
	|		ISNULL(ForecastAmounts.SalesWithCommissionTurnover, 0),
	|		ISNULL(ForecastAmounts.SalesWithCommissionWithoutVATTurnover, 0),
	|		ISNULL(ForecastAmounts.ExpectedSalesWithCommissionTurnover, 0),
	|		ISNULL(ForecastAmounts.ExpectedSalesWithCommissionWithoutVATTurnover, 0),
	|		ISNULL(ForecastAmounts.DiscountSumTurnover, 0)
	|	FROM
	|		ForecastAmounts AS ForecastAmounts
	|	WHERE
	|		(&qRoomIsEmpty
	|				OR NOT &qRoomIsEmpty
	|					AND ForecastAmounts.Room = &qRoom)
	|		AND (ForecastAmounts.IsActiveReservation = TRUE
	|				OR ForecastAmounts.IsPreliminaryReservation = TRUE
	|				OR ForecastAmounts.IsActiveAccommodation = TRUE
	|				OR ForecastAmounts.IsActiveResourceReservation = TRUE)) AS GuestGroupSales
	|
	|GROUP BY
	|	GuestGroupSales.Service,
	|	GuestGroupSales.Currency,
	|	GuestGroupSales.Service.SortCode,
	|	GuestGroupSales.Currency.SortCode
	|
	|ORDER BY
	|	ServiceSortCode,
	|	CurrencySortCode";
	vQry.SetParameter("qGuestGroup", Ref);
	vQry.SetParameter("qRoom", pRoom);
	vQry.SetParameter("qRoomIsEmpty", pRoom = Undefined);
	vQry.SetParameter("qEmptyRoom", Catalogs.Rooms.EmptyRef());
	vQry.SetParameter("qForecastPeriodFrom", tcOnServer.GetForecastStartDate(Owner));
	vQry.SetParameter("qForecastPeriodTo", '39991231235959');
	vQry.SetParameter("qDocsList", pDocsList);
	vQry.SetParameter("qDocsListIsEmpty", pDocsList = Undefined);
	Return vQry.Execute().Unload();
EndFunction // pmGetSalesTotals

// -----------------------------------------------------------------------------
Function pmGetPaymentsTotals(pDocsList = Undefined) Export
	vQry = New Query();
	If pDocsList = Undefined Then
		vQry.Text = 
		"SELECT
		|	BEGINOFPERIOD(Payments.Period, DAY) AS AccountingDate,
		|	Payments.AccountingCurrency AS Currency,
		|	Payments.AccountingCurrency.SortCode AS CurrencySortCode,
		|	SUM(Payments.SumExpense) AS Sum,
		|	SUM(Payments.SumExpense * &qVATRate / (100 + &qVATRate)) AS VATSum
		|FROM
		|	AccumulationRegister.CustomerAccounts.BalanceAndTurnovers(&qPeriodFrom, &qPeriodTo, Day, RegisterRecordsAndPeriodBoundaries, GuestGroup = &qGuestGroup) AS Payments
		|
		|GROUP BY
		|	BEGINOFPERIOD(Payments.Period, DAY),
		|	Payments.AccountingCurrency,
		|	Payments.AccountingCurrency.SortCode
		|
		|ORDER BY
		|	AccountingDate,
		|	CurrencySortCode";
		vQry.SetParameter("qPeriodTo", '00010101000000');
		vQry.SetParameter("qVATRate", ?(ValueIsFilled(Owner.Company), ?(ValueIsFilled(Owner.Company.VATRate), Owner.Company.VATRate.TaxRate, 0), 0));
	Else
		vQry.Text = 
		"SELECT
		|	AllPayments.AccountingDate AS AccountingDate,
		|	AllPayments.Currency AS Currency,
		|	AllPayments.CurrencySortCode AS CurrencySortCode,
		|	SUM(AllPayments.Sum) AS Sum,
		|	SUM(AllPayments.VATSum) AS VATSum
		|FROM
		|	(SELECT
		|		BEGINOFPERIOD(Payments.Period, DAY) AS AccountingDate,
		|		Payments.AccountingCurrency AS Currency,
		|		Payments.AccountingCurrency.SortCode AS CurrencySortCode,
		|		Payments.Sum AS Sum,
		|		Payments.VATSum AS VATSum
		|	FROM
		|		AccumulationRegister.CustomerAccounts AS Payments
		|	WHERE
		|		Payments.GuestGroup = &qGuestGroup
		|		AND Payments.Period >= &qPeriodFrom
		|		AND Payments.Period <= &qPeriodTo
		|		AND Payments.ParentDoc IN(&qDocsList)
		|		AND Payments.RecordType = VALUE(AccumulationRecordType.Expense)
		|		AND NOT Payments.Recorder REFS Document.DepositTransfer
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		BEGINOFPERIOD(FromDepositTransfers.Date, DAY),
		|		FromDepositTransfers.FolioFromCurrency,
		|		FromDepositTransfers.FolioFromCurrency.SortCode,
		|		-FromDepositTransfers.SumInFolioFromCurrency,
		|		0
		|	FROM
		|		Document.DepositTransfer AS FromDepositTransfers
		|	WHERE
		|		FromDepositTransfers.FolioFrom.GuestGroup = &qGuestGroup
		|		AND FromDepositTransfers.Date >= &qPeriodFrom
		|		AND FromDepositTransfers.Date <= &qPeriodTo
		|		AND FromDepositTransfers.FolioFrom.ParentDoc IN(&qDocsList)
		|		AND FromDepositTransfers.Posted
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		BEGINOFPERIOD(ToDepositTransfers.Date, DAY),
		|		ToDepositTransfers.FolioToCurrency,
		|		ToDepositTransfers.FolioToCurrency.SortCode,
		|		ToDepositTransfers.SumInFolioToCurrency,
		|		0
		|	FROM
		|		Document.DepositTransfer AS ToDepositTransfers
		|	WHERE
		|		ToDepositTransfers.FolioTo.GuestGroup = &qGuestGroup
		|		AND ToDepositTransfers.Date >= &qPeriodFrom
		|		AND ToDepositTransfers.Date <= &qPeriodTo
		|		AND ToDepositTransfers.FolioTo.ParentDoc IN(&qDocsList)
		|		AND ToDepositTransfers.Posted) AS AllPayments
		|
		|GROUP BY
		|	AllPayments.AccountingDate,
		|	AllPayments.Currency,
		|	AllPayments.CurrencySortCode
		|
		|ORDER BY
		|	AccountingDate,
		|	CurrencySortCode";
		vQry.SetParameter("qDocsList", pDocsList);
		vQry.SetParameter("qPeriodTo", '39991231235959');
	EndIf;
	vQry.SetParameter("qGuestGroup", Ref);
	vQry.SetParameter("qPeriodFrom", '00010101000000');
	Return vQry.Execute().Unload();
EndFunction // pmGetPaymentsTotals

// -----------------------------------------------------------------------------
Function pmGetActiveResourceReservations() Export
	// Run query to get all resources reserved
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ResourceReservationHistory.Resource.Code AS ResourceCode,
	|	ResourceReservationHistory.Period,
	|	ResourceReservationHistory.Recorder,
	|	ResourceReservationHistory.Resource,
	|	ResourceReservationHistory.Customer,
	|	ResourceReservationHistory.DateTimeFrom,
	|	ResourceReservationHistory.Duration,
	|	ResourceReservationHistory.DateTimeTo,
	|	ResourceReservationHistory.NumberOfPersons,
	|	ResourceReservationHistory.Client
	|FROM
	|	InformationRegister.ResourceReservationHistory AS ResourceReservationHistory
	|WHERE
	|	ResourceReservationHistory.GuestGroup = &qGuestGroup
	|	AND ResourceReservationHistory.ResourceReservationStatus.IsActive
	|ORDER BY
	|	ResourceReservationHistory.Resource.SortCode,
	|	ResourceReservationHistory.Period";
	vQry.SetParameter("qGuestGroup", Ref);
	Return vQry.Execute().Unload();
EndFunction // pmGetActiveResourceReservations

// -----------------------------------------------------------------------------
Function pmGetResourceCodes() Export
	vResourceCodes = "";
	// Run query to get all resources reserved
	vResources = pmGetActiveResourceReservations();
	vResources.GroupBy("ResourceCode",);
	For Each vResourcesRow In vResources Do
		vResourceCodes = vResourceCodes + Upper(TrimAll(vResourcesRow.ResourceCode)) + " ";
	EndDo;
	Return TrimAll(vResourceCodes);
EndFunction // pmGetResourceCodes

// -----------------------------------------------------------------------------
Function pmGetResourceDescriptions() Export
	vResourceDescr = "";
	// Run query to get all resources reserved
	vResources = pmGetActiveResourceReservations();
	For Each vResourcesRow In vResources Do
		If BegOfDay(vResourcesRow.DateTimeFrom) = BegOfDay(vResourcesRow.DateTimeTo) Then
			vResourceDescr = vResourceDescr + TrimAll(vResourcesRow.Resource) + " " + 
			                 Format(vResourcesRow.DateTimeFrom, "DF='dd.MM.yy HH:mm'") + " - " + 
							 Format(vResourcesRow.DateTimeTo, "DF='HH:mm'") + "; ";
		Else
			vResourceDescr = vResourceDescr + TrimAll(vResourcesRow.Resource) + " " + 
			                 Format(vResourcesRow.DateTimeFrom, "DF='dd.MM.yy HH:mm'") + " - " + 
							 Format(vResourcesRow.DateTimeTo, "DF='dd.MM.yy HH:mm'") + "; ";
		EndIf;
	EndDo;
	Return TrimAll(vResourceDescr);
EndFunction // pmGetResourceDescriptions

// -----------------------------------------------------------------------------
Function pmGetHotelProducts() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Docs.HotelProduct
	|FROM
	|	(SELECT
	|		Accommodations.HotelProduct AS HotelProduct
	|	FROM
	|		Document.Accommodation AS Accommodations
	|	WHERE
	|		Accommodations.Posted
	|		AND Accommodations.HotelProduct <> &qEmptyHotelProduct
	|		AND Accommodations.GuestGroup = &qGuestGroup
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Reservations.HotelProduct
	|	FROM
	|		Document.Reservation AS Reservations
	|	WHERE
	|		Reservations.Posted
	|		AND Reservations.HotelProduct <> &qEmptyHotelProduct
	|		AND Reservations.GuestGroup = &qGuestGroup
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Charges.HotelProduct
	|	FROM
	|		Document.Charge AS Charges
	|	WHERE
	|		Charges.Posted
	|		AND Charges.HotelProduct <> &qEmptyHotelProduct
	|		AND Charges.Folio.GuestGroup = &qGuestGroup) AS Docs
	|
	|GROUP BY
	|	Docs.HotelProduct
	|
	|ORDER BY
	|	Docs.HotelProduct.Code";
	vQry.SetParameter("qGuestGroup", Ref);
	vQry.SetParameter("qEmptyHotelProduct", Catalogs.HotelProducts.EmptyRef());
	Return vQry.Execute().Unload();
EndFunction // pmGetHotelProducts

// -----------------------------------------------------------------------------
Function pmGetGuestGroupParameters() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	GuestGroupTotals.GuestGroup,
	|	GuestGroupTotals.Customer,
	|	GuestGroupTotals.Contract,
	|	GuestGroupTotals.Agent,
	|	GuestGroupTotals.PlannedPaymentMethod,
	|	MIN(GuestGroupTotals.DateTimeFrom) AS DateTimeFrom,
	|	MAX(GuestGroupTotals.DateTimeTo) AS DateTimeTo
	|FROM
	|	(SELECT
	|		Reservation.GuestGroup AS GuestGroup,
	|		Reservation.Customer AS Customer,
	|		Reservation.Contract AS Contract,
	|		Reservation.Agent AS Agent,
	|		Reservation.PlannedPaymentMethod AS PlannedPaymentMethod,
	|		Reservation.CheckInDate AS DateTimeFrom,
	|		Reservation.CheckOutDate AS DateTimeTo
	|	FROM
	|		Document.Reservation AS Reservation
	|	WHERE
	|		Reservation.Posted
	|		AND Reservation.GuestGroup = &qGuestGroup
	|		AND (Reservation.ReservationStatus.IsActive
	|				OR Reservation.ReservationStatus.IsCheckIn)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Accommodation.GuestGroup,
	|		Accommodation.Customer,
	|		Accommodation.Contract,
	|		Accommodation.Agent,
	|		Accommodation.PlannedPaymentMethod,
	|		Accommodation.CheckInDate,
	|		Accommodation.CheckOutDate
	|	FROM
	|		Document.Accommodation AS Accommodation
	|	WHERE
	|		Accommodation.Posted
	|		AND Accommodation.GuestGroup = &qGuestGroup
	|		AND Accommodation.AccommodationStatus.IsActive
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ResourceReservation.GuestGroup,
	|		ResourceReservation.Customer,
	|		ResourceReservation.Contract,
	|		ResourceReservation.Agent,
	|		ResourceReservation.PlannedPaymentMethod,
	|		ResourceReservation.DateTimeFrom,
	|		ResourceReservation.DateTimeTo
	|	FROM
	|		Document.ResourceReservation AS ResourceReservation
	|	WHERE
	|		ResourceReservation.Posted
	|		AND ResourceReservation.GuestGroup = &qGuestGroup
	|		AND ResourceReservation.ResourceReservationStatus.IsActive) AS GuestGroupTotals
	|
	|GROUP BY
	|	GuestGroupTotals.GuestGroup,
	|	GuestGroupTotals.Customer,
	|	GuestGroupTotals.Contract,
	|	GuestGroupTotals.Agent,
	|	GuestGroupTotals.PlannedPaymentMethod";
	vQry.SetParameter("qGuestGroup", Ref);
	Return vQry.Execute().Unload();
EndFunction // pmGetGuestGroupParameters

// -----------------------------------------------------------------------------
// Checks if this is preliminary guest group
// -----------------------------------------------------------------------------
Function pmIsPreliminary() Export
	vIsPreliminary = False;
	// Run query to find reservations in preliminary status
	If Not IsNew() Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	Reservation.Ref
		|FROM
		|	Document.Reservation AS Reservation
		|WHERE
		|	Reservation.Posted
		|	AND (NOT Reservation.ReservationStatus.IsActive)
		|	AND Reservation.ReservationStatus.IsPreliminary
		|	AND Reservation.ReservationStatus.DoNotChargeForecastServices
		|	AND Reservation.GuestGroup = &qGuestGroup
		|
		|ORDER BY
		|	Reservation.Date,
		|	Reservation.PointInTime";
		vQry.SetParameter("qGuestGroup", Ref);
		vQryRes = vQry.Execute().Unload();
		If vQryRes.Count() > 0 Then
			vIsPreliminary = True;
		EndIf;
	EndIf;
	Return vIsPreliminary;
EndFunction // pmIsPreliminary

// -----------------------------------------------------------------------------
Procedure pmCreateFolios(pDate) Export
	vChargingRules = Undefined;
	If ValueIsFilled(Owner) Then
		If Owner.CustomerChargingRules.Count() > 0 Then
			vChargingRules = Owner.CustomerChargingRules.Unload();
		EndIf;
	Else
		Return;
	EndIf;
	// Check list of template rules
	If vChargingRules = Undefined Then
		vCR = ChargingRules.Add();
		
		// Create new folio and take parameters from the hotel
		vOldFolioRef = cmGetChargingRulesRowFolio(Ref, Undefined, ChargingRules.IndexOf(vCR) + 1);
		If ValueIsFilled(vOldFolioRef) Then
			vFolioObj = vOldFolioRef.GetObject();
			vFolioObj.DeletionMark = False;
		Else
			vFolioObj = Documents.Folio.CreateDocument();
		EndIf;
		vFolioObj.Hotel = Owner;
		cmFillFolioFromTemplate(vFolioObj, Undefined, Owner, pDate);
		vFolioObj.GuestGroup = Ref;
		vFolioObj.Contract = Catalogs.Contracts.EmptyRef();
		If ValueIsFilled(Customer) And ValueIsFilled(Customer.PlannedPaymentMethod) Then
			vFolioObj.PaymentMethod = Customer.PlannedPaymentMethod;
			If Customer.PlannedPaymentMethod.IsByBankTransfer Then
				vFolioObj.Customer = Customer;
			EndIf;
			If ValueIsFilled(Customer.AgentCommissionType) Then
				vFolioObj.Agent = ?(ValueIsFilled(Customer.Agent), Customer.Agent, Customer);
			EndIf;
			If ValueIsFilled(Customer.AccountingCurrency) Then
				vFolioObj.FolioCurrency = Customer.AccountingCurrency;
			EndIf;
		ElsIf ValueIsFilled(Owner.PaymentMethodForCustomerPayments) Then
			vFolioObj.PaymentMethod = Owner.PaymentMethodForCustomerPayments;
		EndIf;
		If Not ValueIsFilled(vFolioObj.Customer) Or ValueIsFilled(vFolioObj.Hotel) And vFolioObj.Customer = vFolioObj.Hotel.IndividualsCustomer Then
			vFolioObj.Client = Client;
		EndIf;
		If ValueIsFilled(Agent) Then
			vFolioObj.Agent = Agent;
		EndIf;
		vFolioObj.DateTimeFrom = CheckInDate;
		vFolioObj.DateTimeTo = CheckOutDate;
		vFolioObj.LineNumber = ChargingRules.IndexOf(vCR) + 1;
		vFolioObj.Write();
		
		// Add it to the charging rules
		vCR.ChargingRule = Enums.ChargingRuleTypes.InRate;
		vCR.ChargingFolio = vFolioObj.Ref;
	Else
		For Each vRule In vChargingRules Do
			vIsTemplate = True;
			vTemplateFolio = vRule.ChargingFolio;
			If ValueIsFilled(vTemplateFolio) Then
				vIsTemplate = Not vTemplateFolio.IsMaster;
			EndIf;
			If vIsTemplate Then
				vCR = ChargingRules.Add();
				
				// Create new folio from template
				vOldFolioRef = cmGetChargingRulesRowFolio(Ref, Undefined, ChargingRules.IndexOf(vCR) + 1);
				If ValueIsFilled(vOldFolioRef) Then
					vFolioObj = vOldFolioRef.GetObject();
					vFolioObj.DeletionMark = False;
				Else
					vFolioObj = Documents.Folio.CreateDocument();
				EndIf;
				vFolioObj.Hotel = Owner;
				cmFillFolioFromTemplate(vFolioObj, vTemplateFolio, Owner, pDate);
				vFolioObj.GuestGroup = Ref;
				If ValueIsFilled(Contract) And ValueIsFilled(Contract.PlannedPaymentMethod) Then
					If Contract.PlannedPaymentMethod.IsByBankTransfer Then
						vFolioObj.Customer = Customer;
						vFolioObj.Contract = Contract;
					Else
						vFolioObj.PaymentMethod = Contract.PlannedPaymentMethod;
						vFolioObj.Contract = Catalogs.Contracts.EmptyRef();
					EndIf;
					If ValueIsFilled(Contract.AgentCommissionType) And Not Contract.IsSubagent Then
						vFolioObj.Agent = ?(ValueIsFilled(Contract.Agent), Contract.Agent, Contract.Owner);
					EndIf;
				ElsIf ValueIsFilled(Customer) And ValueIsFilled(Customer.PlannedPaymentMethod) Then
					If Customer.PlannedPaymentMethod.IsByBankTransfer Then
						vFolioObj.Customer = Customer;
					Else
						vFolioObj.PaymentMethod = Customer.PlannedPaymentMethod;
					EndIf;
					If ValueIsFilled(Customer.AgentCommissionType) Then
						vFolioObj.Agent = ?(ValueIsFilled(Customer.Agent), Customer.Agent, Customer);
					EndIf;
					vFolioObj.Contract = Catalogs.Contracts.EmptyRef();
				EndIf;
				If ValueIsFilled(Customer) And ValueIsFilled(Customer.AccountingCurrency) Then
					vFolioObj.FolioCurrency = Customer.AccountingCurrency;
				EndIf;
				If Not ValueIsFilled(vFolioObj.Customer) Or ValueIsFilled(vFolioObj.Hotel) And vFolioObj.Customer = vFolioObj.Hotel.IndividualsCustomer Then
					vFolioObj.Client = Client;
				EndIf;
				If ValueIsFilled(Agent) Then
					vFolioObj.Agent = Agent;
				EndIf;
				vFolioObj.DateTimeFrom = CheckInDate;
				vFolioObj.DateTimeTo = CheckOutDate;
				vFolioObj.LineNumber = ChargingRules.IndexOf(vCR) + 1;
				vFolioObj.Write();
				
				// Add it to the charging rules
				FillPropertyValues(vCR, vRule, , "ChargingFolio");
				vCR.ChargingFolio = vFolioObj.Ref;
			Else
				// Copy charging rule
				vCR = ChargingRules.Add();
				FillPropertyValues(vCR, vRule);
			EndIf;
		EndDo;
	EndIf;
EndProcedure // pmCreateFolios

// -----------------------------------------------------------------------------
Function pmGetGuestGroupResumeRecords() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	GuestGroupAttachments.Period AS Period,
	|	GuestGroupAttachments.GuestGroup,
	|	GuestGroupAttachments.IsIncoming,
	|	GuestGroupAttachments.EMail,
	|	GuestGroupAttachments.Fax,
	|	GuestGroupAttachments.AttachmentType,
	|	GuestGroupAttachments.AttachmentStatus,
	|	GuestGroupAttachments.DocumentText,
	|	GuestGroupAttachments.ExtFile,
	|	GuestGroupAttachments.FileName,
	|	GuestGroupAttachments.FileLoadTime,
	|	GuestGroupAttachments.FileLastChangeTime,
	|	GuestGroupAttachments.Remarks,
	|	GuestGroupAttachments.Author
	|FROM
	|	InformationRegister.GuestGroupAttachments AS GuestGroupAttachments
	|WHERE
	|	GuestGroupAttachments.GuestGroup = &qGuestGroup
	|	AND GuestGroupAttachments.AttachmentType = &qGroupResume
	|
	|ORDER BY
	|	Period";
	vQry.SetParameter("qGuestGroup", Ref);
	vQry.SetParameter("qGroupResume", Enums.AttachmentTypes.GroupResume);
	Return vQry.Execute().Unload();
EndFunction // pmGetGuestGroupResumeRecords

// -----------------------------------------------------------------------------
Function pmGetGuestGroupResumeRecord(pPeriod) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	GuestGroupAttachments.Period AS Period,
	|	GuestGroupAttachments.GuestGroup,
	|	GuestGroupAttachments.IsIncoming,
	|	GuestGroupAttachments.EMail,
	|	GuestGroupAttachments.Fax,
	|	GuestGroupAttachments.AttachmentType,
	|	GuestGroupAttachments.AttachmentStatus,
	|	GuestGroupAttachments.DocumentText,
	|	GuestGroupAttachments.ExtFile,
	|	GuestGroupAttachments.FileName,
	|	GuestGroupAttachments.FileLoadTime,
	|	GuestGroupAttachments.FileLastChangeTime,
	|	GuestGroupAttachments.Remarks,
	|	GuestGroupAttachments.Author
	|FROM
	|	InformationRegister.GuestGroupAttachments AS GuestGroupAttachments
	|WHERE
	|	GuestGroupAttachments.GuestGroup = &qGuestGroup
	|	AND GuestGroupAttachments.Period = &qPeriod
	|
	|ORDER BY
	|	Period";
	vQry.SetParameter("qGuestGroup", Ref);
	vQry.SetParameter("qPeriod", pPeriod);
	Return vQry.Execute().Unload();
EndFunction // pmGetGuestGroupResumeRecord

// -----------------------------------------------------------------------------
Procedure pmAddBankTransferChargingRule(pAdd = False) Export
	vCustomer = Customer;
	If Not ValueIsFilled(vCustomer) Then
		If ValueIsFilled(Owner) Then
			vCustomer = Owner.IndividualsCustomer;
		EndIf;
	EndIf;
	// Get default owners charging rules
	vOwnerCRs = New ValueTable();
	If Not ValueIsFilled(vCustomer) Then
		vOwnerCRs = Owner.ChargingRules.Unload();
	Else
		If pAdd Or ValueIsFilled(vCustomer.PlannedPaymentMethod) And vCustomer.PlannedPaymentMethod.IsByBankTransfer Then
			vOwnerCRs = Owner.CustomerChargingRules.Unload();
			If vCustomer.ChargingRules.Count() > 0 Then
				vOwnerCRs = vCustomer.ChargingRules.Unload();
			Else 
				vCustomerParent = vCustomer.Parent;
				While ValueIsFilled(vCustomerParent) Do
					If vCustomerParent.ChargingRules.Count() > 0  Then
						vOwnerCRs = vCustomerParent.ChargingRules.Unload();
						Break;
					EndIf;
					vCustomerParent = vCustomerParent.Parent; 
				EndDo;
			EndIf;
		Else
			vOwnerCRs = Owner.ChargingRules.Unload();
		EndIf;
	EndIf;
	// Remove personal folios
	i = 0;
	While i < vOwnerCRs.Count() Do
		vCRRow = vOwnerCRs.Get(i);
		If vCRRow.IsPersonal Then
			vOwnerCRs.Delete(i);
		Else
			i = i + 1;
		EndIf;
	EndDo;
	// Remove <any> charging rule
	If vOwnerCRs.Count() > 1 Then
		vLastCRRow = vOwnerCRs.Get(vOwnerCRs.Count() - 1);
		If vLastCRRow.ChargingRule = Enums.ChargingRuleTypes.Any Then
			vOwnerCRs.Delete(vOwnerCRs.Count() - 1);
		EndIf;
	EndIf;
	If vOwnerCRs.Count() = 0 Then
		// Try to update existing charging rules
		vCRIsFound = False;
		vCRRows = ChargingRules.FindRows(New Structure("ChargingRule, ChargingRuleValue, ValidFromDate, ValidToDate", Enums.ChargingRuleTypes.InRate, Undefined, '00010101', '00010101'));
		If vCRRows.Count() = 1 Then
			vCRIsFound = True;
			vCR = vCRRows.Get(0);
		Else
			vCR = ChargingRules.Insert(0);
			cmUpdateChargingRulesFoliosLineNumbers(ChargingRules);
		EndIf;
		
		// Create new folio and use base rules
		If vCRIsFound And ValueIsFilled(vCR.ChargingFolio) Then
			vFolioObj = vCR.ChargingFolio.GetObject();
		Else
			vOldFolioRef = cmGetChargingRulesRowFolio(Ref, Undefined, ChargingRules.IndexOf(vCR) + 1);
			If ValueIsFilled(vOldFolioRef) Then
				vFolioObj = vOldFolioRef.GetObject();
				vFolioObj.DeletionMark = False;
			Else
				vFolioObj = Documents.Folio.CreateDocument();
			EndIf;
		EndIf;
		cmFillFolioFromTemplate(vFolioObj, Undefined, Owner, CreateDate);
		vFolioObj.ParentDoc = Undefined;
		If pAdd Or ValueIsFilled(vCustomer.PlannedPaymentMethod) And vCustomer.PlannedPaymentMethod.IsByBankTransfer Then
			vFolioObj.Customer = vCustomer;
			vFolioObj.Contract = Contract;
		Else
			vFolioObj.Customer = Catalogs.Customers.EmptyRef();
			vFolioObj.Contract = Catalogs.Contracts.EmptyRef();
		EndIf;
		If ValueIsFilled(Agent) Then
			vFolioObj.Agent = Agent;
		Else
			If ValueIsFilled(Contract) And ValueIsFilled(Contract.AgentCommissionType) And Not Contract.IsSubagent Then
				If ValueIsFilled(Contract.Agent) Then
					vFolioObj.Agent = Contract.Agent;
				Else				
					vFolioObj.Agent = vCustomer;
				EndIf;
			ElsIf ValueIsFilled(vCustomer) And ValueIsFilled(vCustomer.AgentCommissionType) Then
				If ValueIsFilled(vCustomer.Agent) Then
					vFolioObj.Agent = vCustomer.Agent;
				Else				
					vFolioObj.Agent = vCustomer;
				EndIf;
			EndIf;
		EndIf;
		vFolioObj.GuestGroup = Ref;
		vFolioObj.PaymentMethod = Owner.PlannedPaymentMethod;
		If ValueIsFilled(vCustomer) Then
			vFolioObj.FolioCurrency = vCustomer.AccountingCurrency;
			If ValueIsFilled(vCustomer.PlannedPaymentMethod) Then
				vFolioObj.PaymentMethod = vCustomer.PlannedPaymentMethod;
			EndIf;
		Else
			vFolioObj.FolioCurrency = Owner.BaseCurrency;
		EndIf;
		If Not ValueIsFilled(vFolioObj.Customer) Or ValueIsFilled(vFolioObj.Hotel) And vFolioObj.Customer = vFolioObj.Hotel.IndividualsCustomer Then
			vFolioObj.Client = Client;
		EndIf;
		vFolioObj.Room = Catalogs.Rooms.EmptyRef();
		vFolioObj.DateTimeFrom = CheckInDate;
		vFolioObj.DateTimeTo = CheckOutDate;
		vFolioObj.LineNumber = ChargingRules.IndexOf(vCR) + 1;
		If vFolioObj.IsNew() And Not IsBlankString(Description) Then
			vFolioObj.Description = TrimAll(Description);
		EndIf;
		vFolioObj.Write(DocumentWriteMode.Write);
		
		// Add new charging rule
		vCR.ChargingFolio = vFolioObj.Ref;
		vCR.ChargingRule = Enums.ChargingRuleTypes.InRate;
	Else
		// Do for each owner charging rule
		For i = 0 To (vOwnerCRs.Count() - 1) Do
			vOwnerCRsRow = vOwnerCRs.Get(i);
			If Not ValueIsFilled(vOwnerCRsRow.ChargingFolio) Then
				Continue;
			EndIf;
			
			// Try to find existing charging rule row with the same type
			vCRIsFound = False;
			vCRRows = ChargingRules.FindRows(New Structure("ChargingRule, ChargingRuleValue, ValidFromDate, ValidToDate", vOwnerCRsRow.ChargingRule, vOwnerCRsRow.ChargingRuleValue, vOwnerCRsRow.ValidFromDate, vOwnerCRsRow.ValidToDate));
			If vCRRows.Count() = 1 Then
				vCRIsFound = True;
				vCR = vCRRows.Get(0);
			Else
				vCR = ChargingRules.Insert(i);
				cmUpdateChargingRulesFoliosLineNumbers(ChargingRules);
			EndIf;
			
			// Get folio object
			vFolioObj = Undefined;
			If vCRIsFound And ValueIsFilled(vCR.ChargingFolio) And Not vOwnerCRsRow.ChargingFolio.IsMaster Then
				vFolioObj = vCR.ChargingFolio.GetObject();
				cmFillFolioFromTemplate(vFolioObj, vOwnerCRsRow.ChargingFolio, Owner, CreateDate);
				vFolioObj.ParentDoc = Undefined;
				vFolioObj.Customer = vCustomer;
				vFolioObj.Contract = Contract;
				If ValueIsFilled(Agent) Then
					vFolioObj.Agent = Agent;
				Else
					If ValueIsFilled(Contract) And ValueIsFilled(Contract.AgentCommissionType) Then
						If ValueIsFilled(Contract.Agent) Then
							vFolioObj.Agent = Contract.Agent;
						Else				
							vFolioObj.Agent = vCustomer;
						EndIf;
					ElsIf ValueIsFilled(vCustomer) And ValueIsFilled(vCustomer.AgentCommissionType) Then
						If ValueIsFilled(vCustomer.Agent) Then
							vFolioObj.Agent = vCustomer.Agent;
						Else				
							vFolioObj.Agent = vCustomer;
						EndIf;
					EndIf;
				EndIf;
				vFolioObj.GuestGroup = Ref;
				vFolioObj.DateTimeFrom = CheckInDate;
				vFolioObj.DateTimeTo = CheckOutDate;
				If Not ValueIsFilled(vFolioObj.Customer) Or ValueIsFilled(vFolioObj.Hotel) And vFolioObj.Customer = vFolioObj.Hotel.IndividualsCustomer Then
					vFolioObj.Client = Client;
				EndIf;
				vFolioObj.Room = Catalogs.Rooms.EmptyRef();
				vFolioObj.LineNumber = ChargingRules.IndexOf(vCR) + 1;
				vFolioObj.Write(DocumentWriteMode.Write);
			Else
				If Not vOwnerCRsRow.ChargingFolio.IsMaster Then
					// Create new folio and take parameters from the template folio
					vOldFolioRef = cmGetChargingRulesRowFolio(Ref, Undefined, ChargingRules.IndexOf(vCR) + 1);
					If ValueIsFilled(vOldFolioRef) Then
						vFolioObj = vOldFolioRef.GetObject();
						vFolioObj.DeletionMark = False;
					Else
						vFolioObj = Documents.Folio.CreateDocument();
					EndIf;
					cmFillFolioFromTemplate(vFolioObj, vOwnerCRsRow.ChargingFolio, Owner, CreateDate);
					vFolioObj.Description = Description;
					vFolioObj.ParentDoc = Undefined;
					vFolioObj.Customer = vCustomer;
					vFolioObj.Contract = Contract;
					If ValueIsFilled(Agent) Then
						vFolioObj.Agent = Agent;
					Else
						If ValueIsFilled(Contract) And ValueIsFilled(Contract.AgentCommissionType) Then
							If ValueIsFilled(Contract.Agent) Then
								vFolioObj.Agent = Contract.Agent;
							Else				
								vFolioObj.Agent = vCustomer;
							EndIf;
						ElsIf ValueIsFilled(vCustomer) And ValueIsFilled(vCustomer.AgentCommissionType) Then
							If ValueIsFilled(vCustomer.Agent) Then
								vFolioObj.Agent = vCustomer.Agent;
							Else				
								vFolioObj.Agent = vCustomer;
							EndIf;
						EndIf;
					EndIf;
					vFolioObj.GuestGroup = Ref;
					vFolioObj.DateTimeFrom = CheckInDate;
					vFolioObj.DateTimeTo = CheckOutDate;
					If Not ValueIsFilled(vFolioObj.Customer) Or ValueIsFilled(vFolioObj.Hotel) And vFolioObj.Customer = vFolioObj.Hotel.IndividualsCustomer Then
						vFolioObj.Client = Client;
					EndIf;
					vFolioObj.Room = Catalogs.Rooms.EmptyRef();
					vFolioObj.LineNumber = ChargingRules.IndexOf(vCR) + 1;
					vFolioObj.Write(DocumentWriteMode.Write);
				Else
					vFolioObj = vOwnerCRsRow.ChargingFolio.GetObject();
				EndIf;
			EndIf;
			
			// Add new charging rule
			vCR.ChargingFolio = vFolioObj.Ref;
			vCR.ChargingRule = vOwnerCRsRow.ChargingRule;
			vCR.ChargingRuleValue = vOwnerCRsRow.ChargingRuleValue;
			vCR.ValidFromDate = vOwnerCRsRow.ValidFromDate;
			vCR.ValidToDate = vOwnerCRsRow.ValidToDate;
		EndDo;
	EndIf;
EndProcedure // pmAddBankTransferChargingRule

// -----------------------------------------------------------------------------
Function pmSetPlannedPaymentMethod(rPlannedPaymentMethod = Undefined) Export
	vPayer = Enums.WhoPays.Guest;
	vAccSrvFolio = Undefined;
	vChargingRules = ChargingRules.Unload();
	If vChargingRules.Count() = 0 Then
		If ValueIsFilled(ClientDoc) Then
			If TypeOf(ClientDoc) = Type("DocumentRef.ResourceReservation") Then
				vAccSrvFolio = ClientDoc.ChargingFolio;
			ElsIf TypeOf(ClientDoc) = Type("DocumentRef.Reservation") Or TypeOf(ClientDoc) = Type("DocumentRef.Accommodation") Then 
				vChargingRules = ClientDoc.ChargingRules.Unload();
			ElsIf TypeOf(ClientDoc) = Type("DocumentRef.Folio") Then
				vAccSrvFolio = ClientDoc;
			EndIf;	
		EndIf;
	EndIf;
	If vChargingRules.Count() > 0 And vAccSrvFolio = Undefined Then
		// Set planned payment method from the first charging rule
		vCRRow = vChargingRules.Get(0);
		If ValueIsFilled(vCRRow.ChargingFolio) Then
			If ValueIsFilled(vCRRow.ChargingFolio.PaymentMethod) Then
				vAccSrvFolio = vCRRow.ChargingFolio;
				If rPlannedPaymentMethod <> vAccSrvFolio.PaymentMethod Then
					rPlannedPaymentMethod = vAccSrvFolio.PaymentMethod;
				EndIf;
			EndIf;
		EndIf;
	ElsIf ValueIsFilled(vAccSrvFolio) Then
		If rPlannedPaymentMethod <> vAccSrvFolio.PaymentMethod Then
			rPlannedPaymentMethod = vAccSrvFolio.PaymentMethod;
		EndIf;
	EndIf;
	If ValueIsFilled(vAccSrvFolio) Then
		vAgent = vAccSrvFolio.Agent;
		vCustomer = Undefined;
		vClient = Undefined;
		If TypeOf(ClientDoc) = Type("DocumentRef.ResourceReservation") Or TypeOf(ClientDoc) = Type("DocumentRef.Folio") Then
			If ValueIsFilled(vAccSrvFolio.Customer) Then
				vCustomer = vAccSrvFolio.Customer;
			Else
				vClient = vAccSrvFolio.Client;
			EndIf;
		Else
			For Each vCRRow In vChargingRules Do
				If vCRRow.ChargingFolio = vAccSrvFolio Then
					If ValueIsFilled(vAccSrvFolio.Customer) Then
						vCustomer = vAccSrvFolio.Customer;
					Else
						vClient = vAccSrvFolio.Client;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		If ValueIsFilled(vAgent) And vAgent = vCustomer Then
			vPayer = Enums.WhoPays.Agent;
		ElsIf ValueIsFilled(vCustomer) Then
			If vCustomer = Customer Then
				vPayer = Enums.WhoPays.Customer;
			Else
				If vCustomer.Client <> Client Then
					vPayer = Enums.WhoPays.ChargingRules;
				Else
					vPayer = Enums.WhoPays.Guest;
				EndIf;
			EndIf;
		ElsIf ValueIsFilled(vClient) Then
			If vClient = Client Then
				vPayer = Enums.WhoPays.Guest;
			EndIf;
		EndIf;
	Else
		If ValueIsFilled(Customer) Then
			If ValueIsFilled(Contract) And ValueIsFilled(Contract.PlannedPaymentMethod) Then
				rPlannedPaymentMethod = Contract.PlannedPaymentMethod;
			ElsIf ValueIsFilled(Customer.PlannedPaymentMethod) Then
				rPlannedPaymentMethod = Customer.PlannedPaymentMethod;
			EndIf;
		EndIf;
		If ValueIsFilled(rPlannedPaymentMethod) Then
			If Not ValueIsFilled(vPayer) Then
				vPayer = ?(rPlannedPaymentMethod.IsByBankTransfer, Enums.WhoPays.Customer, Enums.WhoPays.Guest);
			ElsIf rPlannedPaymentMethod.IsByBankTransfer And vPayer = Enums.WhoPays.Guest Then
				vPayer = Enums.WhoPays.Customer;
			EndIf;
		EndIf;
	EndIf;
	Return vPayer;
EndFunction // pmSetPlannedPaymentMethod

// -----------------------------------------------------------------------------
Procedure pmLoadChargingRules(pOwner) Export
	// Get list of hotel default charging rules owners
	vHotelCROwners = cmGetHotelDefaultChargingRuleOwners(Owner);
	// Remove charging rules for objects of the same type
	i = 0;
	j = 0;
	vCRTo = ChargingRules.Unload();
	While i < vCRTo.Count() Do
		vCRRow = vCRTo.Get(i);
		If ValueIsFilled(vCRRow.ChargingFolio.Customer) Then
			If TypeOf(pOwner) = TypeOf(vCRRow.ChargingFolio.Customer) Or TypeOf(pOwner) = TypeOf(vCRRow.ChargingFolio.Contract) Then
				If vHotelCROwners.FindByValue(vCRRow.ChargingFolio.Customer) = Undefined Then
					// Try to find hotel template rule of the same type
					vHotelCRRows = Owner.ChargingRules.FindRows(New Structure("ChargingRule, ChargingRuleValue, ValidFromDate, ValidToDate", vCRRow.ChargingRule, vCRRow.ChargingRuleValue, vCRRow.ValidFromDate, vCRRow.ValidToDate));
					If vHotelCRRows.Count() <> 1 Then
						// Delete charging rule row
						vCRTo.Delete(i);
						cmUpdateChargingRulesFoliosLineNumbers(vCRTo);
						// Save position of the first deleted charging rule
						If j = 0 Then
							j = i;
						EndIf;
						Continue;
					Else
						vHotelCRRow = vHotelCRRows.Get(0);
						// Update charging folio
						vFolioObj = vCRRow.ChargingFolio.GetObject();
						cmFillFolioFromTemplate(vFolioObj, vHotelCRRow.ChargingFolio, Owner, CreateDate);
						vFolioObj.ParentDoc = Undefined;
						vFolioObj.GuestGroup = Ref;
						vFolioObj.DateTimeFrom = CheckInDate;
						vFolioObj.DateTimeTo = CheckOutDate;
						If TypeOf(pOwner) = Type("CatalogRef.Customers") Then
							vFolioObj.Customer = Catalogs.Customers.EmptyRef();
							vFolioObj.Contract = Catalogs.Contracts.EmptyRef();
						ElsIf TypeOf(pOwner) = Type("CatalogRef.Contracts") Then
							vFolioObj.Customer = Catalogs.Customers.EmptyRef();
							vFolioObj.Contract = Catalogs.Contracts.EmptyRef();
						ElsIf TypeOf(pOwner) = Type("CatalogRef.Clients") Then
							vFolioObj.Client = Catalogs.Clients.EmptyRef();
						Else
							If Not ValueIsFilled(vFolioObj.Customer) Or ValueIsFilled(vFolioObj.Hotel) And vFolioObj.Customer = vFolioObj.Hotel.IndividualsCustomer Then
								vFolioObj.Client = Client;
							EndIf;
						EndIf;
						vFolioObj.Agent = Agent;
						vFolioObj.LineNumber = vCRTo.IndexOf(vCRRow) + 1;
						vFolioObj.Write(DocumentWriteMode.Write);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		i = i + 1;
	EndDo;
	// Load changed charging rules to the tabular part
	ChargingRules.Load(vCRTo);
	// Check owner
	If Not ValueIsFilled(pOwner) Then
		If ChargingRules.Count() = 0 Then
			pmCreateFolios(CreateDate);
		EndIf;
		Return;
	EndIf;
	vCRFrom = pOwner.ChargingRules.Unload();
	If vCRFrom.Count() = 0 Then
		If ChargingRules.Count() = 0 Then
			pmCreateFolios(CreateDate);
		EndIf;
		Return;
	EndIf;
	If ValueIsFilled(Owner) Then
		vCRTo = ChargingRules.Unload();
		For Each vCRRow In vCRFrom Do
			// Check if current folio should be used as template
			vIsTemplate = True;
			If ValueIsFilled(vCRRow.ChargingFolio) Then
				vIsTemplate = Not vCRRow.ChargingFolio.IsMaster;
			EndIf;
			// Try to find existing charging rule of the same type
			vReuseFolio = False;
			vCRToRows = vCRTo.FindRows(New Structure("ChargingRule, ChargingRuleValue, ValidFromDate, ValidToDate", vCRRow.ChargingRule, vCRRow.ChargingRuleValue, vCRRow.ValidFromDate, vCRRow.ValidToDate));
			If vCRToRows.Count() = 1 Then
				// Reuse existing one
				vCRToRow = vCRToRows.Get(0);
				vReuseFolio = True;
			Else
				// New charging rule row
				vCRToRow = vCRTo.Insert(j);
				cmUpdateChargingRulesFoliosLineNumbers(vCRTo);
				j = j + 1;
			EndIf;
			vCRToRow.ChargingRule = vCRRow.ChargingRule;
			vCRToRow.ChargingRuleValue = vCRRow.ChargingRuleValue;
			vCRToRow.ValidFromDate = vCRRow.ValidFromDate;
			vCRToRow.ValidToDate = vCRRow.ValidToDate;
			// If current charging folio is template then create new based on it
			If Not vReuseFolio Then
				If vIsTemplate Then
					// Create new folio from template
					vOldFolioRef = cmGetChargingRulesRowFolio(Ref, Undefined, vCRTo.IndexOf(vCRToRow) + 1);
					If ValueIsFilled(vOldFolioRef) Then
						vFolioObj = vOldFolioRef.GetObject();
						vFolioObj.DeletionMark = False;
					Else
						vFolioObj = Documents.Folio.CreateDocument();
					EndIf;
					cmFillFolioFromTemplate(vFolioObj, vCRRow.ChargingFolio, Owner, CreateDate);
					vFolioObj.ParentDoc = Undefined;
					If TypeOf(pOwner) = Type("CatalogRef.Customers") Then
						vFolioObj.Customer = pOwner;
					ElsIf TypeOf(pOwner) = Type("CatalogRef.Contracts") Then
						vFolioObj.Customer = pOwner.Owner;
						vFolioObj.Contract = pOwner;
					ElsIf TypeOf(pOwner) = Type("CatalogRef.Clients") Then
						vFolioObj.Client = pOwner;
					EndIf;
					If Not ValueIsFilled(vFolioObj.Customer) Or ValueIsFilled(vFolioObj.Hotel) And vFolioObj.Customer = vFolioObj.Hotel.IndividualsCustomer Then
						vFolioObj.Client = Client;
					Else
						vFolioObj.Client = Catalogs.Clients.EmptyRef();
					EndIf;
					vFolioObj.Room = Catalogs.Rooms.EmptyRef();
					vFolioObj.GuestGroup = Ref;
					vFolioObj.DateTimeFrom = CheckInDate;
					vFolioObj.DateTimeTo = CheckOutDate;
				Else
					vCRToRow.ChargingFolio = vCRRow.ChargingFolio;
					vFolioObj = vCRToRow.ChargingFolio.GetObject();
					vFolioObj.ParentDoc = Undefined;
				EndIf;
			Else
				// Update folio from template
				If vIsTemplate Then
					vFolioObj = vCRToRow.ChargingFolio.GetObject();
					cmFillFolioFromTemplate(vFolioObj, vCRRow.ChargingFolio, Owner, CreateDate);
					vFolioObj.ParentDoc = Undefined;
					If TypeOf(pOwner) = Type("CatalogRef.Customers") Then
						vFolioObj.Customer = pOwner;
					ElsIf TypeOf(pOwner) = Type("CatalogRef.Contracts") Then
						vFolioObj.Customer = pOwner.Owner;
						vFolioObj.Contract = pOwner;
					ElsIf TypeOf(pOwner) = Type("CatalogRef.Clients") Then
						vFolioObj.Client = pOwner;
					EndIf;
					If Not ValueIsFilled(vFolioObj.Customer) Or ValueIsFilled(vFolioObj.Hotel) And vFolioObj.Customer = vFolioObj.Hotel.IndividualsCustomer Then
						vFolioObj.Client = Client;
					Else
						vFolioObj.Client = Catalogs.Clients.EmptyRef();
					EndIf;
					vFolioObj.Room = Catalogs.Rooms.EmptyRef();
					vFolioObj.GuestGroup = Ref;
					vFolioObj.DateTimeFrom = CheckInDate;
					vFolioObj.DateTimeTo = CheckOutDate;
				Else
					vCRToRow.ChargingFolio = vCRRow.ChargingFolio;
					vFolioObj = vCRToRow.ChargingFolio.GetObject();
					vFolioObj.ParentDoc = Undefined;
				EndIf;
			EndIf;
			If TypeOf(pOwner) = Type("CatalogRef.Customers") Then
				vFolioObj.Customer = pOwner;
				If ValueIsFilled(vFolioObj.Customer.AgentCommissionType) Then
					vFolioObj.Agent = ?(ValueIsFilled(vFolioObj.Customer.Agent), vFolioObj.Customer.Agent, vFolioObj.Customer);
				EndIf;
			ElsIf TypeOf(pOwner) = Type("CatalogRef.Contracts") Then
				vFolioObj.Customer = pOwner.Owner;
				vFolioObj.Contract = pOwner;
				If Not pOwner.IsSubagent Then
					If ValueIsFilled(pOwner.AgentCommissionType) Then
						vFolioObj.Agent = ?(ValueIsFilled(vFolioObj.Contract.Agent), vFolioObj.Contract.Agent, vFolioObj.Customer);
					EndIf;
				Else
					vAgent = vFolioObj.Customer;
					vAgentRef = vAgent;
					If ValueIsFilled(vAgent.Agent) Then
						vAgentRef = vAgent.Agent;
					EndIf;
					If ValueIsFilled(vAgent.AgentCommissionType) Then
						vFolioObj.Agent = vAgentRef;
					EndIf;
				EndIf;
			ElsIf TypeOf(pOwner) = Type("CatalogRef.Clients") Then
				vFolioObj.Client = pOwner;
			EndIf;
			If ValueIsFilled(Agent) Then
				vFolioObj.Agent = Agent;
			EndIf;
			vFolioObj.LineNumber = vCRTo.IndexOf(vCRToRow) + 1;
			vFolioObj.Write(DocumentWriteMode.Write);
			vCRToRow.ChargingFolio = vFolioObj.Ref;
		EndDo;
		// Load changed charging rules to the tabular part
		ChargingRules.Load(vCRTo);
	EndIf;
	If ChargingRules.Count() = 0 Then
		pmCreateFolios(CreateDate);
	EndIf;
EndProcedure // pmLoadChargingRules

// -----------------------------------------------------------------------------
Procedure OnSetNewCode(pStandardProcessing, pPrefix)
	If Constants.UseSequentionalGroupNumberingForAllHotels.Get() Then
		pStandardProcessing = False;
		// Add exclusive lock to the constant
		BeginTransaction(DataLockControlMode.Managed);
		vDataLock = New DataLock();
		vDLItem = vDataLock.Add("Constant.UseSequentionalGroupNumberingForAllHotels");
		vDLItem.Mode = DataLockMode.Exclusive;
		While True Do
			Try
				vDataLock.Lock();
				Break;
			Except
				tcCommonFunctionOnClientServer.TextMessage(ErrorDescription(), MessageStatus.Attention);
			EndTry;
		EndDo;
		// Get guest groups prefix for current node 
		vGuestGroupsCodesFrom = 0;
		vGuestGroupsCodesTo = 0;
		vCentralOfficeExchangePlan = ExchangePlans.CentralOfficeExchangePlan.ThisNode();
		If ValueIsFilled(vCentralOfficeExchangePlan) And (vCentralOfficeExchangePlan.GuestGroupsCodesFrom > 0 Or vCentralOfficeExchangePlan.GuestGroupsCodesTo > 0) Then
			vGuestGroupsCodesFrom = Max(vGuestGroupsCodesFrom, vCentralOfficeExchangePlan.GuestGroupsCodesFrom);
			vGuestGroupsCodesTo = Max(vGuestGroupsCodesTo, vCentralOfficeExchangePlan.GuestGroupsCodesTo);
		EndIf;
		vReplicationExchangePlan = ExchangePlans.ReplicationExchangePlan.ThisNode();
		If ValueIsFilled(vReplicationExchangePlan) And (vReplicationExchangePlan.GuestGroupsCodesFrom > 0 Or vReplicationExchangePlan.GuestGroupsCodesTo > 0) Then
			vGuestGroupsCodesFrom = Max(vGuestGroupsCodesFrom, vReplicationExchangePlan.GuestGroupsCodesFrom);
			vGuestGroupsCodesTo = Max(vGuestGroupsCodesTo, vReplicationExchangePlan.GuestGroupsCodesTo);
		EndIf;
		// Get last used guest group code
		vLastUsedCode = 0;
		vQry = New Query();
		If vGuestGroupsCodesFrom > 0 Or vGuestGroupsCodesTo > 0 Then
			vLastUsedCode = vGuestGroupsCodesFrom;
			vQry.Text = 
			"SELECT
			|	MAX(GuestGroups.Code) AS Code
			|FROM
			|	Catalog.GuestGroups AS GuestGroups
			|WHERE
			|	GuestGroups.Code > &qGuestGroupsCodesFrom AND GuestGroups.Code < &qGuestGroupsCodesTo";
			vQry.SetParameter("qGuestGroupsCodesFrom", vGuestGroupsCodesFrom); 
			vQry.SetParameter("qGuestGroupsCodesTo", vGuestGroupsCodesTo); 
		Else
			vQry.Text = 
			"SELECT
			|	MAX(GuestGroups.Code) AS Code
			|FROM
			|	Catalog.GuestGroups AS GuestGroups";
		EndIf;
		vQryRes = vQry.Execute().Unload();
		If vQryRes.Count() > 0 Then
			vLastUsedCode = vQryRes.Get(0).Code;
		EndIf;
		// Set new code
		If Not cmIsNumber(vLastUsedCode) Then
			If vGuestGroupsCodesFrom > 0 Then
				Code = vGuestGroupsCodesFrom + 1;
			Else
				Code = 1;
			EndIf;
		Else				
			Code = vLastUsedCode + 1;
		EndIf;
		CommitTransaction();
	EndIf;
EndProcedure // OnSetNewCode
	
// ------------------------------------------------------------------------------------------------
Function pmUpdateGuestGroupDocuments(pPlannedPaymentMethod) Export
	vSomethingChanged = False;
	vAccommodationsRefs = pmGetAccommodations(True);
	vReservationsRefs = pmGetReservations(True, True);
	//ACCOMMODATIONS
	For Each vAccRow In vAccommodationsRefs Do
		vRef = vAccRow.Accommodation;
		If vRef.Customer <> Customer Or vRef.Contract <> Contract Then
			vAccObject = vRef.GetObject();
			vAccObject.Customer = Customer;
			vAccObject.Contract = Contract;
			If ValueIsFilled(Contract) And ValueIsFilled(Contract.Company) Then
				vAccObject.Company = Contract.Company;
			EndIf;
			If ValueIsFilled(Contract) And ValueIsFilled(Contract.AgentCommissionType) Then
				vAccObject.Agent = ?(ValueIsFilled(Contract.Agent), Contract.Agent, Contract.Owner);
				vAccObject.AgentCommissionType = Contract.AgentCommissionType;
				vAccObject.AgentCommission = Contract.AgentCommission;
				vAccObject.AgentCommissionServiceGroup = Contract.AgentCommissionServiceGroup;
			ElsIf ValueIsFilled(Customer) And ValueIsFilled(Customer.AgentCommissionType) Then
				vAccObject.Agent = ?(ValueIsFilled(Customer.Agent), Customer.Agent, Customer);
				vAccObject.AgentCommissionType = Customer.AgentCommissionType;
				vAccObject.AgentCommission = Customer.AgentCommission;
				vAccObject.AgentCommissionServiceGroup = Customer.AgentCommissionServiceGroup;
			EndIf;
			If ValueIsFilled(vAccObject.Contract) And vAccObject.Contract.DoNotPrintRate Then
				vAccObject.DoNotPrintRate = True;
			ElsIf ValueIsFilled(vAccObject.Customer) And vAccObject.Customer.DoNotPrintRate Then
				vAccObject.DoNotPrintRate = True;
			EndIf;
			vAccObject.PlannedPaymentMethod = pPlannedPaymentMethod;
			// Update charging rules
			i = 0;
			While i < vAccObject.ChargingRules.Count() Do
				vCRRow = vAccObject.ChargingRules.Get(i);
				If Not vCRRow.IsTransfer Then
					If ValueIsFilled(Contract) And ValueIsFilled(vCRRow.Owner) And vCRRow.Owner <> Contract Then
						vCRRow.Owner = Contract;
					ElsIf ValueIsFilled(Customer) And ValueIsFilled(vCRRow.Owner) And vCRRow.Owner <> Customer Then
						vCRRow.Owner = Customer;
					ElsIf Not ValueIsFilled(Contract) And Not ValueIsFilled(Customer) And ValueIsFilled(Owner) Then
						vCRRow.Owner = Undefined;
					EndIf;
				EndIf;
				i = i + 1;
			EndDo;
			vAccObject.pmSetPlannedPaymentMethod();
			// Post document
			vAccObject.Write(DocumentWriteMode.Posting);
			vAccObject.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			vSomethingChanged = True;
		EndIf;
	EndDo;
	//RESERVATIONS
	For Each vResRow In vReservationsRefs Do
		vRef = vResRow.Reservation;
		If vRef.Customer <> Customer Or vRef.Contract <> Contract Then
			vResObject = vRef.GetObject();
			vResObject.Customer = Customer;
			vResObject.Contract = Contract;
			If ValueIsFilled(Contract) And ValueIsFilled(Contract.Company) Then
				vResObject.Company = Contract.Company;
			EndIf;
			If ValueIsFilled(Contract) And ValueIsFilled(Contract.AgentCommissionType) Then
				vResObject.Agent = ?(ValueIsFilled(Contract.Agent), Contract.Agent, Contract.Owner);
				vResObject.AgentCommissionType = Contract.AgentCommissionType;
				vResObject.AgentCommission = Contract.AgentCommission;
				vResObject.AgentCommissionServiceGroup = Contract.AgentCommissionServiceGroup;
			ElsIf ValueIsFilled(Customer) And ValueIsFilled(Customer.AgentCommissionType) Then
				vResObject.Agent = ?(ValueIsFilled(Customer.Agent), Customer.Agent, Customer);
				vResObject.AgentCommissionType = Customer.AgentCommissionType;
				vResObject.AgentCommission = Customer.AgentCommission;
				vResObject.AgentCommissionServiceGroup = Customer.AgentCommissionServiceGroup;
			EndIf;
			If ValueIsFilled(vResObject.Contract) And vResObject.Contract.DoNotPrintRate Then
				vResObject.DoNotPrintRate = True;
			ElsIf ValueIsFilled(vResObject.Customer) And vResObject.Customer.DoNotPrintRate Then
				vResObject.DoNotPrintRate = True;
			EndIf;
			vResObject.PlannedPaymentMethod = pPlannedPaymentMethod;
			// Update charging rules
			i = 0;
			While i < vResObject.ChargingRules.Count() Do
				vCRRow = vResObject.ChargingRules.Get(i);
				If Not vCRRow.IsTransfer Then
					If ValueIsFilled(Contract) And ValueIsFilled(vCRRow.Owner) And vCRRow.Owner <> Contract Then
						vCRRow.Owner = Contract;
					ElsIf ValueIsFilled(Customer) And ValueIsFilled(vCRRow.Owner) And vCRRow.Owner <> Customer Then
						vCRRow.Owner = Customer;
					ElsIf Not ValueIsFilled(Contract) And Not ValueIsFilled(Customer) And ValueIsFilled(Owner) Then
						vCRRow.Owner = Undefined;
					EndIf;
				EndIf;
				i = i + 1;
			EndDo;
			vResObject.pmSetPlannedPaymentMethod();
			// Post document
			vResObject.Write(DocumentWriteMode.Posting);
			vResObject.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			vSomethingChanged = True;
		EndIf;
	EndDo;
	Return vSomethingChanged;
EndFunction // pmUpdateGuestGroupDocuments

// -----------------------------------------------------------------------------
Procedure pmGenerateGuestGroupResume(pResumeFilePath, pFileType) Export
	// Generate structure with group description fields
	vGrpMap = New Structure();
	vGrpMap.Insert("AccountingRemarks", "");
	vGrpMap.Insert("ChargingRules", "");
	vGrpMap.Insert("ClientContactPerson", "");
	vGrpMap.Insert("CongressManagerRemarks", "");
	vGrpMap.Insert("FAndBRemarks", "");
	vGrpMap.Insert("GroupCode", "");
	vGrpMap.Insert("GroupCustomer", "");
	vGrpMap.Insert("GroupDescription", "");
	vGrpMap.Insert("GroupMaxCheckOutDate", "");
	vGrpMap.Insert("GroupMinCheckInDate", "");
	vGrpMap.Insert("GroupNumberOfPersons", "");
	vGrpMap.Insert("GroupNumberOfRooms", "");
	vGrpMap.Insert("GroupRemarks", "");
	vGrpMap.Insert("HotelContactPersonEMail", "");
	vGrpMap.Insert("HotelContactPersonName", "");
	vGrpMap.Insert("HotelContactPersonPhone", "");
	vGrpMap.Insert("HousekeepingRemarks", "");
	vGrpMap.Insert("ReceptionRemarks", "");
	vGrpMap.Insert("RoomRates", "");
	vGrpMap.Insert("SecurityRemarks", "");
	// Get group documents
	vClientDoc = ClientDoc;
	vReservations = pmGetReservations(True, True);
	vResourceReservations = pmGetResourceReservations(True);
	If Not ValueIsFilled(vClientDoc) Then
		If vReservations.Count() > 0 Then
			vClientDoc = vReservations.Get(0).Reservation;
		ElsIf vResourceReservations.Count() > 0 Then
			vClientDoc = vResourceReservations.Get(0).Reservation;
		EndIf;
	EndIf;
	// Fill guest group fields
	vGrpMap.GroupCode = Format(Code, "ND=12; NFD=0; NG=");
	If ValueIsFilled(Customer) Then
		If Not IsBlankString(Customer.LegacyName) Then
			vGrpMap.GroupCustomer = TrimAll(Customer.LegacyName);
		Else
			vGrpMap.GroupCustomer = TrimAll(Customer.Description);
		EndIf;
	EndIf;
	vGrpMap.GroupDescription = TrimAll(Description);
	If ValueIsFilled(CheckInDate) Then
		vGrpMap.GroupMinCheckInDate = Format(CheckInDate, "DF=dd.MM.yyyy");
	EndIf;
	If ValueIsFilled(CheckOutDate) Then
		vGrpMap.GroupMaxCheckOutDate = Format(CheckOutDate, "DF=dd.MM.yyyy");
	EndIf;
	vRoomsCheckedIn = vReservations.Total("NumberOfRooms");
	vGrpMap.GroupNumberOfPersons = Format(GuestsCheckedIn, "ND=10; NFD=0; NZ=; NG=");
	vGrpMap.GroupNumberOfRooms = Format(vRoomsCheckedIn, "ND=10; NFD=0; NZ=; NG=");
	vGrpMap.GroupRemarks = TrimAll(Remarks);
	If ValueIsFilled(vClientDoc) Then
		If TypeOf(vClientDoc) = Type("DocumentRef.Accommodation") Or 
		   TypeOf(vClientDoc) = Type("DocumentRef.Reservation") Or 
		   TypeOf(vClientDoc) = Type("DocumentRef.ResourceReservation") Then
			vGrpMap.ClientContactPerson = TrimAll(vClientDoc.ContactPerson);
		EndIf;
	EndIf;
	If ValueIsFilled(Author) Then
		If IsBlankString(Author.EMail) Then
			vGrpMap.HotelContactPersonEMail = TrimAll(Owner.EMail);
		Else
			vGrpMap.HotelContactPersonEMail = TrimAll(Author.EMail);
		EndIf;
		If IsBlankString(Author.Phones) Then
			vGrpMap.HotelContactPersonPhone = TrimAll(Owner.Phones);
		Else
			vGrpMap.HotelContactPersonPhone = TrimAll(Author.Phones);
		EndIf;
		If Not IsBlankString(Author.LastName) Then
			vGrpMap.HotelContactPersonName = TrimAll(TrimAll(Author.LastName) + " " + TrimAll(Author.FirstName) + " " + TrimAll(Author.SecondName));
		Else
			vGrpMap.HotelContactPersonName = TrimAll(Author.Description);
		EndIf;
	EndIf;
	// Accounting remarks
	If ValueIsFilled(CheckDate) Then
		vGrpMap.AccountingRemarks = NStr("en='Payment check date is';de='Payment check date is';ru='Дата проверки поступления оплаты'") + " " + Format(CheckDate, "DF=dd.MM.yyyy");
	EndIf;
	// Get reservation totals
	vRoomInvTotals = New ValueTable();
	vRoomInvTotals.Columns.Add("RoomType", cmGetCatalogTypeDescription("RoomTypes"));
	vRoomInvTotals.Columns.Add("CheckInDate", cmGetDateTypeDescription());
	vRoomInvTotals.Columns.Add("Duration", cmGetNumberTypeDescription(10, 0));
	vRoomInvTotals.Columns.Add("CheckOutDate", cmGetDateTypeDescription());
	vRoomInvTotals.Columns.Add("NumberOfRooms", cmGetNumberTypeDescription(10, 0));
	vRoomInvTotals.Columns.Add("NumberOfBeds", cmGetNumberTypeDescription(10, 0));
	vRoomInvTotals.Columns.Add("NumberOfPersons", cmGetNumberTypeDescription(10, 0));
	For Each vReservationsRow In vReservations Do
		vRoomInvTotalsRow = vRoomInvTotals.Add();
		vRoomInvTotalsRow.RoomType = vReservationsRow.RoomType;
		vRoomInvTotalsRow.CheckInDate = BegOfDay(vReservationsRow.CheckInDate);
		vRoomInvTotalsRow.Duration = vReservationsRow.Duration;
		vRoomInvTotalsRow.CheckOutDate = BegOfDay(vReservationsRow.CheckOutDate);
		If vReservationsRow.NumberOfRooms <> 0 Then
			vRoomInvTotalsRow.NumberOfRooms = vReservationsRow.NumberOfRooms;
		ElsIf vReservationsRow.NumberOfBeds <> 0 Then
			vRoomInvTotalsRow.NumberOfRooms = vReservationsRow.NumberOfBeds/?(vReservationsRow.NumberOfBedsPerRoom = 0, 1, vReservationsRow.NumberOfBedsPerRoom);
		EndIf;
		vRoomInvTotalsRow.NumberOfBeds = vReservationsRow.NumberOfBeds;
		vRoomInvTotalsRow.NumberOfPersons = vReservationsRow.NumberOfPersons;
	EndDo;
	vRoomInvTotals.GroupBy("RoomType, CheckInDate, Duration, CheckOutDate", "NumberOfRooms, NumberOfBeds, NumberOfPersons");
	For Each vRoomInvTotalsRow In vRoomInvTotals Do                                                                                                                                                                 
		vGrpMap.ReceptionRemarks = vGrpMap.ReceptionRemarks + Format(vRoomInvTotalsRow.CheckInDate, "DF=dd.MM.yyyy") + " - " + Format(vRoomInvTotalsRow.CheckOutDate, "DF=dd.MM.yyyy") + ", " + vRoomInvTotalsRow.RoomType + ", " + NStr("en='Rooms: ';ru='Номеров: ';de='Zimmern: '") + Format(Round(vRoomInvTotalsRow.NumberOfRooms, 0), "DF=dd.MM.yyyy") + ", " + NStr("en='Guests: ';ru='Гостей: ';de='Gäste: '") + Format(vRoomInvTotalsRow.NumberOfPersons, "DF=dd.MM.yyyy") + Chars.LF;
	EndDo;
	// Fill from documents
	If ValueIsFilled(vClientDoc) Then
		If TypeOf(vClientDoc) = Type("DocumentRef.Accommodation") Or 
		   TypeOf(vClientDoc) = Type("DocumentRef.Reservation") Then
			vGrpMap.RoomRates = TrimAll(TrimAll(vClientDoc.RoomRate) + " " + TrimAll(vClientDoc.PricePresentation));
			vGrpMap.ReceptionRemarks = vGrpMap.ReceptionRemarks + Chars.LF + TrimAll(vClientDoc.Remarks);
			vCRRow = Undefined;
		   	If ChargingRules.Count() > 0 Then
				vCRRow = ChargingRules.Get(0);
			ElsIf vClientDoc.ChargingRules.Count() > 0 Then
				vCRRow = vClientDoc.ChargingRules.Get(0);
			EndIf;
			If vCRRow <> Undefined Then
				vGrpMap.ChargingRules = TrimAll(TrimAll(vCRRow.ChargingRule) + " " + TrimAll(vCRRow.ChargingRuleValue));
			EndIf;
		EndIf;
		vGrpMap.ChargingRules = TrimAll(vGrpMap.ChargingRules + ": " + TrimAll(vClientDoc.PlannedPaymentMethod));
	EndIf;
	// Extra services
	// Conference
	vExtraServices = New ValueTable();
	vExtraServices.Columns.Add("Folio");
	vExtraServices.Columns.Add("AccountingDate", cmGetDateTypeDescription());
	vExtraServices.Columns.Add("Service", cmGetCatalogTypeDescription("Services"));
	vExtraServices.Columns.Add("ServiceResource");
	vExtraServices.Columns.Add("TimeFrom", cmGetTimeTypeDescription());
	vExtraServices.Columns.Add("TimeTo", cmGetTimeTypeDescription());
	vExtraServices.Columns.Add("Remarks", cmGetStringTypeDescription());
	vExtraServices.Columns.Add("Quantity", cmGetNumberTypeDescription(19, 7));
	vExtraServices.Columns.Add("Unit", cmGetStringTypeDescription());
	vExtraServices.Columns.Add("Price", cmGetNumberTypeDescription(17, 2));
	vExtraServices.Columns.Add("Amount", cmGetNumberTypeDescription(17, 2));
	// F&B
	vFandBServices = vExtraServices.Copy();
	For Each vResourceReservationsRow In vResourceReservations Do
		vGrpMap.CongressManagerRemarks = vGrpMap.CongressManagerRemarks + Format(vResourceReservationsRow.DateTimeFrom, "DF=dd.MM.yyyy") + " " + vResourceReservationsRow.Resource + " " + Format(vResourceReservationsRow.DateTimeFrom, "DF=HH:mm") + " - " + Format(vResourceReservationsRow.DateTimeTo, "DF='dd.MM.yy HH:mm'") + Chars.LF;
		If Not IsBlankString(vResourceReservationsRow.Reservation.Remarks) Then
			vGrpMap.CongressManagerRemarks = vGrpMap.CongressManagerRemarks + Chars.LF + cmNStr(TrimAll(vResourceReservationsRow.Reservation.Remarks));
		EndIf;
		For Each vSrvRow In vResourceReservationsRow.Reservation.Services Do
			If vSrvRow.IsManual Then
				If ValueIsFilled(vSrvRow.Service) And ValueIsFilled(vSrvRow.Service.ServiceType) And vSrvRow.Service.ServiceType.RevenueSegment = Enums.RevenueSegments.FaB Then
					vFandBServicesRow = vFandBServices.Add();
					vFandBServicesRow.Folio = vResourceReservationsRow.Reservation.ChargingFolio;
					vFandBServicesRow.AccountingDate = vSrvRow.AccountingDate;
					vFandBServicesRow.Service = vSrvRow.Service;
					vFandBServicesRow.ServiceResource = vSrvRow.ServiceResource;
					vFandBServicesRow.TimeFrom = vSrvRow.TimeFrom;
					vFandBServicesRow.TimeTo = vSrvRow.TimeTo;
					vFandBServicesRow.Remarks = cmNStr(vSrvRow.Remarks);
					If IsBlankString(vFandBServicesRow.Remarks) Then
						If Not IsBlankString(vSrvRow.ServiceId) Then
							vServiceItems = vResourceReservationsRow.Reservation.ServiceItems.FindRows(New Structure("ServiceId", vSrvRow.ServiceId));
							If vServiceItems.Count() > 0 Then
								For Each vSIRow In vServiceItems Do
									If ValueIsFilled(vSIRow.ServiceItem) Then
										If TypeOf(vSIRow.ServiceItem) = Type("CatalogRef.ServiceItems") Then
											vFandBServicesRow.Remarks = vFandBServicesRow.Remarks + TrimAll(vSIRow.ServiceItem.Description) + ?(IsBlankString(vSIRow.Output), "", " (" + TrimAll(vSIRow.Output) + ")") + " - " + cmFormatSum(vSIRow.Price, vSIRow.Currency) + " x " + Format((vSrvRow.Quantity * vSIRow.Quantity), "ND=10; NFD=1; NG=") + TrimAll(vSIRow.Unit) + " = " + cmFormatSum(Round(vSrvRow.Quantity * vSIRow.Sum, 2), vSIRow.Currency) + Chars.LF;
										Else
											vFandBServicesRow.Remarks = vFandBServicesRow.Remarks + TrimAll(vSIRow.ServiceItem) + ?(IsBlankString(vSIRow.Output), "", " (" + TrimAll(vSIRow.Output) + ")") + " - " + cmFormatSum(vSIRow.Price, vSIRow.Currency) + " x " + Format((vSrvRow.Quantity * vSIRow.Quantity), "ND=10; NFD=1; NG=") + TrimAll(vSIRow.Unit) + " = " + cmFormatSum(Round(vSrvRow.Quantity * vSIRow.Sum, 2), vSIRow.Currency) + Chars.LF;
										EndIf;
									EndIf;
								EndDo;
								vFandBServicesRow.Remarks = TrimAll(vFandBServicesRow.Remarks);
							EndIf;
						EndIf;
					EndIf;
					vFandBServicesRow.Quantity = vSrvRow.Quantity;
					vFandBServicesRow.Unit = vSrvRow.Unit;
					vFandBServicesRow.Amount = vSrvRow.Sum - vSrvRow.DiscountSum;
					vFandBServicesRow.Price = Round(vFandBServicesRow.Amount/?(vSrvRow.Quantity = 1, 1, vSrvRow.Quantity), 2);
				Else
					vExtraServicesRow = vExtraServices.Add();
					vExtraServicesRow.Folio = vResourceReservationsRow.Reservation.ChargingFolio;
					vExtraServicesRow.AccountingDate = vSrvRow.AccountingDate;
					vExtraServicesRow.Service = vSrvRow.Service;
					vExtraServicesRow.ServiceResource = vSrvRow.ServiceResource;
					vExtraServicesRow.TimeFrom = vSrvRow.TimeFrom;
					vExtraServicesRow.TimeTo = vSrvRow.TimeTo;
					vExtraServicesRow.Remarks = cmNStr(vSrvRow.Remarks);
					vExtraServicesRow.Quantity = vSrvRow.Quantity;
					vExtraServicesRow.Unit = vSrvRow.Unit;
					vExtraServicesRow.Amount = vSrvRow.Sum - vSrvRow.DiscountSum;
					vExtraServicesRow.Price = Round(vExtraServicesRow.Amount/?(vSrvRow.Quantity = 1, 1, vSrvRow.Quantity), 2);
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	For Each vReservationsRow In vReservations Do
		For Each vSrvRow In vReservationsRow.Reservation.Services Do
			If vSrvRow.IsManual Or Not vSrvRow.IsRoomRevenue Then
				If ValueIsFilled(vSrvRow.Service) And ValueIsFilled(vSrvRow.Service.ServiceType) And vSrvRow.Service.ServiceType.RevenueSegment = Enums.RevenueSegments.FaB Then
					vFandBServicesRow = vFandBServices.Add();
					vFandBServicesRow.Folio = vSrvRow.Folio;
					vFandBServicesRow.AccountingDate = vSrvRow.AccountingDate;
					vFandBServicesRow.Service = vSrvRow.Service;
					vFandBServicesRow.ServiceResource = vSrvRow.ServiceResource;
					vFandBServicesRow.TimeFrom = vSrvRow.TimeFrom;
					vFandBServicesRow.TimeTo = vSrvRow.TimeTo;
					vFandBServicesRow.Remarks = cmNStr(vSrvRow.Remarks);
					vFandBServicesRow.Quantity = vSrvRow.Quantity;
					vFandBServicesRow.Unit = vSrvRow.Unit;
					vFandBServicesRow.Amount = vSrvRow.Sum - vSrvRow.DiscountSum;
					vFandBServicesRow.Price = Round(vFandBServicesRow.Amount/?(vSrvRow.Quantity = 1, 1, vSrvRow.Quantity), 2);
				Else
					vExtraServicesRow = vExtraServices.Add();
					vExtraServicesRow.Folio = vSrvRow.Folio;
					vExtraServicesRow.AccountingDate = vSrvRow.AccountingDate;
					vExtraServicesRow.Service = vSrvRow.Service;
					vExtraServicesRow.ServiceResource = vSrvRow.ServiceResource;
					vExtraServicesRow.TimeFrom = vSrvRow.TimeFrom;
					vExtraServicesRow.TimeTo = vSrvRow.TimeTo;
					vExtraServicesRow.Remarks = cmNStr(vSrvRow.Remarks);
					vExtraServicesRow.Quantity = vSrvRow.Quantity;
					vExtraServicesRow.Unit = vSrvRow.Unit;
					vExtraServicesRow.Amount = vSrvRow.Sum - vSrvRow.DiscountSum;
					vExtraServicesRow.Price = Round(vExtraServicesRow.Amount/?(vSrvRow.Quantity = 1, 1, vSrvRow.Quantity), 2);
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	vExtraServices.GroupBy("AccountingDate, Service, ServiceResource, TimeFrom, TimeTo, Remarks, Unit", "Quantity");
	If vExtraServices.Count() > 0 Then
		If Not IsBlankString(vGrpMap.CongressManagerRemarks) Then
			vGrpMap.CongressManagerRemarks = vGrpMap.CongressManagerRemarks + Chars.LF + Chars.LF;
		EndIf;
		For Each vSrvRow In vExtraServices Do
			vGrpMap.CongressManagerRemarks = vGrpMap.CongressManagerRemarks + Format(vSrvRow.AccountingDate, "DF=dd.MM.yyyy") + " " + vSrvRow.Service + ", " + vSrvRow.ServiceResource + " " + Format(vSrvRow.TimeFrom, "DF=HH:mm") + " - " + Format(vSrvRow.TimeTo, "DF='HH:mm'") + " - " + NStr("en='Quantity: ';de='Menge: ';ru='Кол-во: '") + Format(vSrvRow.Quantity, "ND=12; NFD=0; NG=") + TrimAll(vSrvRow.Unit) + Chars.LF;
			vGrpMap.CongressManagerRemarks = vGrpMap.CongressManagerRemarks + Chars.Tab + StrReplace(TrimAll(vSrvRow.Remarks), Chars.LF, Chars.LF + Chars.Tab) + Chars.LF;
		EndDo;
	EndIf;
	vFandBServices.GroupBy("Folio, AccountingDate, Service, ServiceResource, TimeFrom, TimeTo, Remarks, Price, Unit", "Quantity, Amount");
	vCurFolio = Undefined;
	For Each vSrvRow In vFandBServices Do
		If IsBlankString(vSrvRow.Remarks) Then
			Continue;
		EndIf;
		If vCurFolio <> vSrvRow.Folio Then
			vCurFolio = vSrvRow.Folio;
			If Not IsBlankString(vGrpMap.FAndBRemarks) Then
				vGrpMap.FAndBRemarks = vGrpMap.FAndBRemarks + Chars.LF + Chars.LF;
			EndIf;
			vGrpMap.FAndBRemarks = vGrpMap.FAndBRemarks + NStr("en='Folio #'; de='Folio Nr.'; ru='Фолио №'") + cmGetDocumentNumberPresentation(vCurFolio.Number) + Chars.LF + Chars.LF;
		EndIf;
		vGrpMap.FAndBRemarks = vGrpMap.FAndBRemarks + Format(vSrvRow.AccountingDate, "DF=dd.MM.yyyy") + " " + vSrvRow.Service + ", " + vSrvRow.ServiceResource + " " + Format(vSrvRow.TimeFrom, "DF=HH:mm") + " - " + Format(vSrvRow.TimeTo, "DF='HH:mm'") + " - " + cmFormatSum(vSrvRow.Price, vCurFolio.FolioCurrency) + " x " + Format(vSrvRow.Quantity, "ND=12; NFD=0; NG=") + TrimAll(vSrvRow.Unit) + " = " + cmFormatSum(vSrvRow.Amount, vCurFolio.FolioCurrency) + Chars.LF;
		vGrpMap.FAndBRemarks = vGrpMap.FAndBRemarks + Chars.Tab + StrReplace(TrimAll(vSrvRow.Remarks), Chars.LF, Chars.LF + Chars.Tab) + Chars.LF;
	EndDo;
	// Fill housekeeping totals from client type remarks and housekeeping remarks
	vGrpMap.HousekeepingRemarks = "";
	For Each vReservationsRow In vReservations Do
		vResDoc = vReservationsRow.Reservation;
		vGuestClientTypeRemarks = "";
		vGuestHousekeepingRemarks = "";
		If ValueIsFilled(vResDoc.ClientType) And Not IsBlankString(vResDoc.ClientType.Remarks) Then
			vGuestClientTypeRemarks = TrimAll(TrimAll(vResDoc.ClientType) + " " + TrimAll(vResDoc.ClientType.Remarks));
		EndIf;
		If Not IsBlankString(vResDoc.HousekeepingRemarks) Then
			vGuestHousekeepingRemarks = TrimAll(vResDoc.HousekeepingRemarks);
		EndIf;
		If Not IsBlankString(vGuestClientTypeRemarks) Or Not IsBlankString(vGuestHousekeepingRemarks) Then
			vGuestIdentification = TrimAll(TrimAll(vResDoc.Room) + " " + TrimAll(vResDoc.RoomType.Code) + " " + TrimAll(vResDoc.GuestFullName));
			vHSRemarks = TrimAll(vGuestIdentification + Chars.LF + vGuestClientTypeRemarks + ?(IsBlankString(vGuestClientTypeRemarks), "", Chars.LF) + vGuestHousekeepingRemarks);
			If Not IsBlankString(vGrpMap.HousekeepingRemarks) Then
				vGrpMap.HousekeepingRemarks = vGrpMap.HousekeepingRemarks + Chars.LF + Chars.LF + vHSRemarks;
			Else
				vGrpMap.HousekeepingRemarks = vHSRemarks;
			EndIf;
		EndIf;
	EndDo;
	// Fill Microsoft Word document
	If pFileType = "docx" Then
		cmProcessDOCXFile(pResumeFilePath, vGrpMap);
	ElsIf pFileType = "odt" Then
		cmProcessODTFile(pResumeFilePath, vGrpMap);
	EndIf;
EndProcedure // pmGenerateGuestGroupResume

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure FillGroupID()
	Try
		vIDNum = 0;
		vPrefix = Upper(TrimAll(Customer.GroupCode));
		vPrefixLen = StrLen(vPrefix);
		// Get last used number
		vMaxId = vPrefix + "9";
		i = vPrefixLen + 1;
		While i < 10 Do
			vMaxId = vMaxId + "9";
			i = i + 1;
		EndDo;
		vQry = New Query();
		vQry.Text = 
		"SELECT TOP 1
		|	GuestGroups.ID AS ID
		|FROM
		|	Catalog.GuestGroups AS GuestGroups
		|WHERE
		|	GuestGroups.ID < &qMaxID
		|	AND GuestGroups.Owner = &qOwner
		|	AND NOT GuestGroups.IsFolder
		|	AND NOT GuestGroups.DeletionMark
		|
		|ORDER BY
		|	GuestGroups.ID DESC";
		vQry.SetParameter("qOwner", Owner);
		vQry.SetParameter("qMaxID", vMaxId);
		vLastUsedIds = vQry.Execute().Unload();
		If vLastUsedIds.Count() > 0 Then
			vLastUsedID = TrimAll(vLastUsedIds.Get(0).ID);
			If Upper(Left(vLastUsedID, vPrefixLen)) = vPrefix Then
				vIDNum = Number(TrimAll(Mid(vLastUsedID, vPrefixLen+1)));
			EndIf;
		EndIf;
		vFormat = "ND=" + String(10 - vPrefixLen) + "; NFD=0; NZ=; NLZ=; NG=";
		vIDNum = vIDNum + 1;
		ID = vPrefix + Format(vIDNum, vFormat);
	Except
	EndTry;
EndProcedure // FillGroupID

// -----------------------------------------------------------------------------
Function IsChanged() 
	If IsNew() Then
		Return True;
	Else
		If Code <> Ref.Code Or 
		   Description <> Ref.Description Or
		   Parent <> Ref.Parent Or
		   DeletionMark <> Ref.DeletionMark Then
			Return True;
		EndIf;
		For Each vMDItem In Metadata.Catalogs.GuestGroups.Attributes Do
			If TypeOf(ThisObject[vMDItem.Name]) = Type("ValueStorage") Then
				If ThisObject[vMDItem.Name].Get() <> Ref[vMDItem.Name].Get() Then
					Return True;
				EndIf;
			Else
				If ThisObject[vMDItem.Name] <> Ref[vMDItem.Name] Then
					Return True;
				EndIf;
			EndIf;
		EndDo;
		For Each vTSItem In Metadata.Catalogs.GuestGroups.TabularSections Do
			If ThisObject[vTSItem.Name].Count() <> Ref[vTSItem.Name].Count() Then
				Return True;
			Else
				For Each vRow In ThisObject[vTSItem.Name] Do
					vOldRow = Ref[vTSItem.Name].Get(ThisObject[vTSItem.Name].IndexOf(vRow));
					For Each vMDItem In vTSItem.Attributes Do
						If TypeOf(vRow[vMDItem.Name]) = Type("ValueStorage") Then
							If vRow[vMDItem.Name].Get() <> vOldRow[vMDItem.Name].Get() Then
								Return True;
							EndIf;
						Else
							If vRow[vMDItem.Name] <> vOldRow[vMDItem.Name] Then
								Return True;
							EndIf;
						EndIf;
					EndDo;
				EndDo;
			EndIf;
		EndDo;
	EndIf;
	Return False;
EndFunction // IsChanged

#EndRegion




	