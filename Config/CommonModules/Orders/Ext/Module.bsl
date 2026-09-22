
#Region Public

// -----------------------------------------------------------------------------
Procedure CreateOrderFromObjects(pExternalSystemCode = Undefined, pHotel, pExternalOrderCode = Undefined, pType, pDepartment, pOrderTime, pClient, pRoom = Undefined, pPhone = Undefined, pRemarks, pSum, // Main parametr 
                                pPickupFrom = Undefined, pDestination = Undefined, pPassengersNumber = Undefined, pChildSeatsNumber = Undefined, pTransferType = Undefined,  // Transfer parametr 
                                pRentTime = Undefined, pRentResources = Undefined, // Rent parameters 
                                pItems = Undefined, pParentDoc = Undefined, pGuestGroup = Undefined, pService = Undefined) Export // Room service parameters
	If ValueIsFilled(pGuestGroup) And TypeOf(pGuestGroup) = Type("Number") Then
		vQuery = New Query;
		vQuery.Text = 
		"SELECT
		|	GuestGroups.Ref AS Ref,
		|	GuestGroups.Presentation AS Presentation
		|FROM
		|	Catalog.GuestGroups AS GuestGroups
		|WHERE
		|	GuestGroups.Owner = &Owner
		|	AND GuestGroups.Code = &Code";
		vQuery.SetParameter("Code", pGuestGroup);
		vQuery.SetParameter("Owner", pHotel);
		
		vQueryResult = vQuery.Execute();
		
		vSelectionDetailRecords = vQueryResult.Select();
		
		If vSelectionDetailRecords.Next() Then
			vGuestGroup =  vSelectionDetailRecords.Ref;
		Else
			vGuestGroup = Undefined;
		EndIf;
	ElsIf TypeOf(pGuestGroup) = Type("CatalogRef.GuestGroups") Then
		vGuestGroup = pGuestGroup;
	EndIf;
	If ValueIsFilled(pOrderTime) Then
		vOrderTime = pOrderTime;
	Else 
		If ValueIsFilled(pParentDoc) And (TypeOf(pParentDoc) = Type("DocumentRef.Accommodation") 
			Or TypeOf(pParentDoc) = Type("DocumentRef.Reservation")) Then
			
			vOrderTime = pParentDoc.CheckInDate;
		Else
			vOrderTime = CurrentSessionDate();
		EndIf;
	EndIf;	
	vNewOrder = Documents.Order.CreateDocument();
	vNewOrder.Type        = pType;
	vNewOrder.Date        = CurrentSessionDate();
	Documents.Order.GetNextStatus(vNewOrder, pType, , True, False);
	vNewOrder.Department  = pDepartment;
	vNewOrder.OrderTime   = vOrderTime;
	vNewOrder.Client      = pClient;
	vNewOrder.ParentDoc   = pParentDoc;
	vNewOrder.Phone       = pPhone;
	vNewOrder.Hotel       = pHotel;
	vNewOrder.Remarks     = pRemarks;
	vNewOrder.Room        = pRoom;
	vNewOrder.Price       = pSum;
	vNewOrder.Quantity    = 1;
	vNewOrder.Sum         = pSum;
	vNewOrder.GuestGroup  = vGuestGroup;
	
	vNewOrder.RentTime       = pRentTime;
	vNewOrder.RentResources  = pRentResources;
	If pItems <> Undefined Then
		For Each ItemRow In pItems Do
			vNewRow = vNewOrder.Items.Add();
			vNewRow.Item  = ItemRow.Item;
			vNewRow.Quantity = ItemRow.Quantity; 
			vNewRow.Price = ItemRow.Price;				
			vNewRow.Sum   = ItemRow.Quantity * ItemRow.Price;
		EndDo;
	EndIf;
	vNewOrder.OrderPaymentType = Enums.OrderPaymentType.Room;
	If TypeOf(vNewOrder.ParentDoc) = Type("DocumentRef.Reservation") Then
		vNewOrder.RouteType = Enums.RouteType.Arrive;
	ElsIf TypeOf(vNewOrder.ParentDoc) = Type("DocumentRef.Accommodation") Then
		vNewOrder.RouteType = Enums.RouteType.Departure;
	Else
		vNewOrder.RouteType = Enums.RouteType.Route;
	EndIf;
	vNewOrder.PickupFrom       = pPickupFrom;
	vNewOrder.Destination      = pDestination;
	vNewOrder.GuestsQuantity   = pPassengersNumber;
	vNewOrder.ChildSeatsNumber = pChildSeatsNumber;
	vNewOrder.TransferType     = pTransferType;
	If pService <> Undefined And ValueIsFilled(pService) Then
		vNewOrder.Service = pService;
		vNewOrder.Unit = TrimAll(pService.Unit);
	EndIf;
	If pPassengersNumber <> Undefined And pPassengersNumber > 0 Then
		vNewOrder.pmGetTransferPrice();
	EndIf;
	If pSum > 0 Then
		vNewOrder.Sum = pSum; 
		vNewOrder.Quantity = ?(vNewOrder.Quantity = 0, 1, vNewOrder.Quantity);
		vNewOrder.Price = Round(vNewOrder.Sum / vNewOrder.Quantity, 2);
	EndIf;
	vNewOrder.NoDiscounts = True;
	vNewOrder.pmSetDiscounts();
	vNewOrder.Write();	
	
	SaveCodeMapping(pExternalSystemCode, pExternalOrderCode, vNewOrder.Ref);
	
	// Create message for department
	If ValueIsFilled(vNewOrder.Department) Then
		cmSendMessageToDepartment(vNewOrder.Department, TrimAll(String(vNewOrder.Type) + Chars.LF + String(vNewOrder.Ref) + Chars.LF + pRemarks), Undefined, True, vNewOrder.ParentDoc, True, vNewOrder.Ref);
	EndIf;
EndProcedure // CreateOrderFromObjects

// -----------------------------------------------------------------------------
//
// Parameters:
//  pExternalSystemCode	 - String	 - External system code
//  pHotel				 - CatalogRef.Hotels - Ref
//  pGuestUUID			 - String			 - GuestUUID
// 
// Returns:
//  Structure - GuestInfo
//
Function GetGuestInfo(pExternalSystemCode, pHotel, pGuestUUID) Export 
	WriteLogEvent(NStr("en='Get guest folios with transactions'; de='Get guest folios with transactions'; ru='Получить список лицевых счетов гостя с транзакциями'"), EventLogLevel.Information, , , 
				  NStr("en='External system code: '; de='External system code: '; ru='Код внешней системы: '") + pExternalSystemCode + Chars.LF 
				  + NStr("en='Hotel: '; de='Hotel: '; ru='Гостиница: '") + pHotel + Chars.LF 
				  + NStr("en='Guest UUID: '; de='Gast UUID: '; ru='UUID гостя: '") + pGuestUUID);
	// Try to find guest accommodation by accommodation uuid
	vGuestItem = New Structure;
	
	vAccRef = SMS.GetClientDocumentByMyFolioId(pGuestUUID);
	If Not ValueIsFilled(vAccRef) Then
		Raise NStr("en = 'Guest ID is wrong!'; de = 'Guest-ID ist falsch'; ru = 'ID гостя указано неверно!'");
	EndIf;
	// Check that accommodation is in-house or check-out was today
	If TypeOf(vAccRef) = Type("DocumentRef.Accommodation") Then
		If Not vAccRef.Posted Or Not vAccRef.AccommodationStatus.IsActive Or Not vAccRef.AccommodationStatus.IsInHouse And BegOfDay(vAccRef.CheckOutDate) < BegOfDay(CurrentSessionDate()) Then
			Raise NStr("en = 'Guest is not in-house!'; de = 'Gast nicht in-house!'; ru = 'Гость не проживает!'");
		EndIf;
		vGuest = vAccRef.Guest;
		vParentDoc = vAccRef;
	ElsIf TypeOf(vAccRef) = Type("DocumentRef.Reservation") Then
		If Not vAccRef.Posted Or Not vAccRef.ReservationStatus.IsActive Then
			Raise NStr("en = 'Reservation is canceled!'; de = 'Die Reservierung ist storniert!'; ru = 'Бронь не активна!'");
		EndIf;
		vGuest = vAccRef.Guest;
		vParentDoc = vAccRef;
	ElsIf TypeOf(vAccRef) = Type("DocumentRef.ResourceReservation") Then
		If Not vAccRef.Posted Or Not vAccRef.ResourceReservationStatus.IsActive Or vAccRef.ResourceReservationStatus.ServicesAreDelivered And BegOfDay(vAccRef.DateTimeTo) < BegOfDay(CurrentSessionDate()) Then
			Raise NStr("en = 'Clinet is not in-house!'; de = 'Kunde nicht in-house!'; ru = 'Мероприятие уже закончено!'");
		EndIf;
		vGuest = vAccRef.Client;
		vParentDoc = vAccRef;
	EndIf;
	If Not ValueIsFilled(vGuest) Then
		Raise NStr("en = 'Guest info is not in the system yet! Please wait a bit and try again...'; 
				   |de = 'Gäste-Info ist nicht im System noch nicht! Bitte warten Sie ein wenig und versuchen Sie es erneut...'; 
				   |ru = 'Даные гостя еще не занесены в систему! Пожалуйста подождите немного и попробуйте еще раз...'");
	EndIf;
	If TypeOf(vAccRef) = Type("DocumentRef.Accommodation") Then
		If ValueIsFilled(vAccRef.Room) Then
			Room = vAccRef.Room;
		EndIf;
	ElsIf TypeOf(vAccRef) = Type("DocumentRef.Reservation") Then
		If ValueIsFilled(vAccRef.Room) Then
			Room = vAccRef.Room;
		EndIf;
	ElsIf TypeOf(vAccRef) = Type("DocumentRef.ResourceReservation") Then     
		// Not use
	EndIf;
	If Not IsBlankString(vGuest.Phone) Then
		GuestPhone = TrimAll(vGuest.Phone);
	ElsIf Not IsBlankString(vAccRef.Phone) Then
		GuestPhone = TrimAll(vGuest.Phone);
	Else
		GuestPhone = "";
	EndIf;
	
	vGuestItem.Insert("Guest", vGuest);
	vGuestItem.Insert("Phone", GuestPhone);
	vGuestItem.Insert("Room", Room);
	vGuestItem.Insert("ParentDoc", vParentDoc);
	
	Return vGuestItem;
EndFunction // GetGuestInfo

// -----------------------------------------------------------------------------
//
// Parameters:
//  pHotel				 - CatalogRef.Hotels - Ref
//  pGuestGroupNumber	 - String	 - GuestGroupNumber
//  pParentDocNumber	 - String	 - ParentDocNumber
// 
// Returns:
//  DocumentRef.Reservation - Ref 
//
Function GetParentDoc(pHotel, pGuestGroupNumber, pParentDocNumber) Export 	
	If ValueIsFilled(pGuestGroupNumber) Then
		vGuestGroup = Catalogs.GuestGroups.FindByCode(pGuestGroupNumber);
	EndIf;
			
	If ValueIsFilled(pParentDocNumber) Then		
		vQuery = New Query;
		vQuery.Text = 
		"SELECT
		|	Reservation.Ref AS Ref,
		|	Reservation.Guest AS Guest
		|FROM
		|	Document.Reservation AS Reservation
		|WHERE
		|	Reservation.Posted
		|	AND Reservation.ReservationStatus.IsActive
		|	AND Reservation.Number = &qNumber
		|	AND Reservation.Hotel = &qHotel
		|	AND CASE
		|			WHEN &qUseGuestGroup
		|				THEN Reservation.GuestGroup = &qGuestGroup
		|			ELSE TRUE
		|		END
		|
		|ORDER BY
		|	Reservation.Date DESC";		
		vQuery.SetParameter("qHotel", pHotel);
		vQuery.SetParameter("qNumber", pParentDocNumber);	
		
		If ValueIsFilled(vGuestGroup) Then
			vQuery.SetParameter("qUseGuestGroup", True);
			vQuery.SetParameter("qGuestGroup", vGuestGroup);	
		Else
			vQuery.SetParameter("qUseGuestGroup", False);
			vQuery.SetParameter("qGuestGroup", vGuestGroup);
		EndIf;
		
		vQueryResult = vQuery.Execute();		
		vSelectionDetailRecords = vQueryResult.Select();
		If vSelectionDetailRecords.Next() Then			
			Return vSelectionDetailRecords.Ref;			
		EndIf;
	EndIf;
	
	If ValueIsFilled(vGuestGroup) Then
		If ValueIsFilled(vGuestGroup.ClientDoc) Then				
			Return vGuestGroup.ClientDoc;				
		EndIf;
	EndIf;
	Return Undefined;
EndFunction // GetParentDoc

// -----------------------------------------------------------------------------
//
// Parameters:
//  pCharge	 - DocumentRef.Charge - Ref
// 
// Returns:
//  DocumentRef.Order - Ref 
//
Function GetChargeOrder(pCharge) Export
	vOrder = Undefined;
	If ValueIsFilled(pCharge) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	Order.Ref AS Ref
		|FROM
		|	Document.Order AS Order
		|WHERE
		|	Order.Posted
		|	AND Order.Charge = &qCharge
		|
		|ORDER BY
		|	Order.PointInTime DESC";
		vQry.SetParameter("qCharge", pCharge);
		vOrders = vQry.Execute().Unload();
		For Each vOrdersRow In vOrders Do
			vOrder = vOrdersRow.Ref;
			Break;
		EndDo;
	EndIf;
	Return vOrder;
EndFunction // GetChargeOrder

// -----------------------------------------------------------------------------
//  Save mapping of object external code for the external system to allow future
//  updates of the document
//
// Parameters:
//  pExternalSystemCode	 - String	 - External system code
//  pExternalOrderCode	 - String	 - External order code
//  pOrderRef			 - DocumentRef.Order - Ref
//
Procedure SaveCodeMapping(pExternalSystemCode, Val pExternalOrderCode, pOrderRef) Export
	If Not ValueIsFilled(pExternalOrderCode) And ValueIsFilled(pOrderRef) Then
		pExternalOrderCode = String(pOrderRef.UUID());
	EndIf;
	If ValueIsFilled(pExternalSystemCode) And ValueIsFilled(pExternalOrderCode) Then
		vIR = InformationRegisters.ExternalOrderCodes.CreateRecordManager();
		VIR.Order = pOrderRef;
		vIR.ExternalSystemCode = pExternalSystemCode;
		vIR.ExternalOrderCode = pExternalOrderCode;
		vIR.Write();
	EndIf;
EndProcedure // SaveCodeMapping

// -----------------------------------------------------------------------------
//
// Parameters:
//  pParentDoc	 - DocumentRef.Accomodation	 - Ref Reservation or Accomodation
// 
// Returns:
//  ValueTable - list orders
//
Function cmGetOrdersByParentDoc(pParentDoc) Export 
	vObject	= pParentDoc;
	vDocs = New ValueTable;
	vDocs.Columns.Add("Doc");
	vDocRow = vDocs.Add();
	vDocRow.Doc = vObject.Ref;
	While ValueIsFilled(vObject.ParentDoc) Do
		vFindDoc = vDocs.Find(vObject.ParentDoc, "Doc");
		If ValueIsFilled(vFindDoc) Then 
			Break;
		Else
			vDocRow = vDocs.Add();
			vDocRow.Doc = vObject.ParentDoc;
			vObject = vObject.ParentDoc; 
		EndIf;
	EndDo;	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	Orders.Ref AS Ref,
	|	Orders.Type AS Type,
	|	Orders.Charge AS Charge,
	|	Orders.PointInTime AS PointInTime,
	|	SUM(Orders.Sum) AS Sum
	|FROM
	|	Document.Order AS Orders
	|WHERE
	|	Orders.ParentDoc IN(&qParentDoc)
	|	AND NOT Orders.Status.isOrderCancel
	|	AND NOT Orders.DeletionMark
	|
	|GROUP BY
	|	Orders.PointInTime,
	|	Orders.Ref,
	|	Orders.Type,
	|	Orders.Charge
	|
	|ORDER BY
	|	PointInTime";
	vQuery.SetParameter("qParentDoc", vDocs.UnloadColumn("Doc"));	
	vQueryResult = vQuery.Execute();	
	Return vQueryResult.Unload();
EndFunction //  cmGetOrdersByParentDoc()

// -----------------------------------------------------------------------------
//  Subscription to the posting event of the Order document
//
// Parameters:
//  pOrder		 - DocumentRef.Order - Ref
//  pCancel		 - Boolean			 - Do cancel
//  pPostingMode - Structure		 - PostingMode
//
Procedure OrderStatusPosting(pOrder, pCancel, pPostingMode) Export
	
	vJobParams = New Array;
	vJobParams.Add(pOrder.Ref);
	AsyncCalls.StartBackgroundJob("Orders.NotifyStatus", vJobParams);
	
EndProcedure

// -----------------------------------------------------------------------------
//  Composes and sends notification message about the order status
//
// Parameters:
//  pOrder	 - DocumentRef.Order - Ref
//
Procedure NotifyStatus(pOrder) Export
	If Not ValueIsFilled(pOrder.Type) Then
		Return;
	EndIf;
	// Get emloyees to notify
	vQ = New Query("SELECT
	               |	OrderTypesNotifications.Ref AS OrderType,
	               |	OrderTypesNotifications.Status AS Status,
	               |	OrderTypesNotifications.Employee AS Employee,
	               |	OrderTypesNotifications.Employee.Phones AS EmployeePhones,
	               |	OrderTypesNotifications.Employee.EMail AS EmployeeEMail,
	               |	OrderNotifications.DateSent AS DateSent
	               |FROM
	               |	Catalog.OrderTypes.Notifications AS OrderTypesNotifications
	               |		LEFT JOIN InformationRegister.OrderNotifications AS OrderNotifications
	               |		ON (OrderNotifications.Order = &qOrder)
	               |			AND (OrderNotifications.OrderType = &qOrderType)
	               |			AND (OrderNotifications.OrderStatus = OrderTypesNotifications.Status)
	               |			AND (OrderNotifications.Employee = OrderTypesNotifications.Employee)
	               |WHERE
	               |	OrderTypesNotifications.Status = &qOrderStatus
	               |	AND OrderTypesNotifications.Ref = &qOrderType");
	vQ.SetParameter("qOrderStatus", pOrder.Status);
	vQ.SetParameter("qOrderType", pOrder.Type);
	vQ.SetParameter("qOrder", pOrder);
	
	vRes = vQ.Execute().Select();
	vOrderTextDescription = GetOrderTextDescription(pOrder);
	vErrorDescription = "";
	vMessageId = "";
	While vRes.Next() Do
		If vRes.DateSent = Null Then  
			vTGMethod = "sent";
			If ValueIsFilled(vRes.EmployeePhones) Then
				// Send SMS
				vPhones = TrimAll(vRes.EmployeePhones);
				SMS.SendMessage(vOrderTextDescription, vPhones, , , , , , , vErrorDescription, vMessageId);
				SaveOrderStatusMessage(pOrder, pOrder.Type, pOrder.Status, vRes.Employee, vOrderTextDescription, vRes.EmployeePhones, vTGMethod, vMessageId, CurrentSessionDate(), CurrentSessionDate());
			EndIf;     
			vEmail = vRes.EmployeeEMail; 
			If Not ValueIsFilled(vEmail) And ValueIsFilled(vRes.Employee) And ValueIsFilled(vRes.Employee.EmailAccount) Then
				vEmail = vRes.Employee.EmailAccount.EMail;	
			EndIf;	
			If ValueIsFilled(vEmail) Then
				// Send e-mail
				vSubject = TrimAll(pOrder.Status) + ": " + TrimAll(pOrder);
				vErrorMessage = "";
				JobsScheduled.cmSendTextByEMail(vSubject, vOrderTextDescription, vEMail, , vErrorMessage);
				SaveOrderStatusMessage(pOrder, pOrder.Type, pOrder.Status, vRes.Employee, vOrderTextDescription, vEmail, vTGMethod, "", CurrentSessionDate(), CurrentSessionDate());
			EndIf;
			If ValueIsFilled(vRes.Employee) Then
				// Send telegram
				Catalogs.ChatBots.BotNotify(pOrder.Hotel, vRes.Employee, vOrderTextDescription);
				SaveOrderStatusMessage(pOrder, pOrder.Type, pOrder.Status, vRes.Employee, vOrderTextDescription, vRes.Employee, vTGMethod, "", CurrentSessionDate(), CurrentSessionDate());
			EndIf;
		EndIf;
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
// Input: Order ref
// Output: Order text description. used for status notification messages
Function GetOrderTextDescription(pOrder) Export

	vOrderText = "";
	If pOrder = Undefined Then
		Return vOrderText;
	EndIf;
	vOrderText = TrimAll(pOrder.Status) + ":" + TrimAll(pOrder) + " = " + pOrder.Sum + " " + pOrder.Currency.Description + Chars.LF;
	vOrderText = vOrderText + pOrder.Hotel + Chars.LF;
	vOrderText = vOrderText + ?(ValueIsFilled(pOrder.Type), TrimAll(pOrder.Type.Type) + Chars.LF, "");
	vOrderText = vOrderText + NStr("en = 'Client: '; de = 'Kunde: '; ru = 'Клиент: '") + ?(ValueIsFilled(pOrder.Client), pOrder.Client.FullName + " (" + pOrder.ClientType + ")", "") + Chars.LF;
	vOrderText = vOrderText + NStr("en = 'Room: '; de = 'Zimmer: '; ru = 'Номер: '") + pOrder.Room + Chars.LF;
	vOrderText = vOrderText + NStr("en = 'Phone: '; de = 'Tel: '; ru = 'Телефон: '") + pOrder.Phone + Chars.LF;
	vOrderText = vOrderText + NStr("en = 'Guest group: '; de = 'Gästegruppen: '; ru = 'Группа: '") + pOrder.GuestGroup + Chars.LF;
	If ValueIsFilled(pOrder.Type) And pOrder.Type.Type = Enums.TypesOfOrder.Transfer Then
		vOrderText = vOrderText + pOrder.RouteType + Chars.LF;
		vOrderText = vOrderText + NStr("en = 'pickup from '; de = 'abholung von '; ru = 'забрать из: '") + pOrder.PickupFrom
					+ NStr("en = ' at '; de = ' um '; ru = ' в '") + pOrder.OrderTime + Chars.LF;
		vOrderText = vOrderText + NStr("en = 'destination '; de = 'Bestimmungsort '; ru = 'место назначения '") + pOrder.Destination
					+ ?(Not IsBlankString(pOrder.Address), NStr("en = ' Address: '; de = ' Anschrift: '; ru = ' Адрес: '") + pOrder.Address, "") + Chars.LF;
		
		vOrderText = vOrderText + NStr("en = 'Number of passengers: '; de = 'Fahrgästen anzahl: '; ru = 'Пассажиров: '") + pOrder.GuestsQuantity + Chars.LF;
		vOrderText = vOrderText + NStr("en = 'child seats: '; de = 'kindersitze: '; ru = 'детских сидений: '") + pOrder.ChildSeatsNumber + Chars.LF;
		
		vOrderText = vOrderText + NStr("en = 'vehicle '; de = 'Fahrzeug '; ru = 'Автомобиль: '") + pOrder.TransferType + " " + pOrder.Carrier + " " + pOrder.Vehicle + Chars.LF;
		
	ElsIf ValueIsFilled(pOrder.Type) And pOrder.Type.Type = Enums.TypesOfOrder.RoomService Then    
		// Not use
	Else
		vOrderText = vOrderText + pOrder.Service + " " + pOrder.Quantity + Chars.LF;
	EndIf;
	If pOrder.Items.Count() > 0 Then
		// Add menu items
		vOrderText = vOrderText + NStr("en = 'Items:'; de = 'Artikelen:'; ru = 'Заказ:'") + Chars.LF;
		For Each item In pOrder.Items Do
			vOrderText = vOrderText + item.Quantity + " " + item.Item + Chars.LF;
		EndDo;
	EndIf;

	vOrderText = vOrderText + nStr("en = 'Total: '; de = 'Insgesamt: '; ru = 'Итого: '") + pORder.Sum + " " + pOrder.Currency + Chars.LF;	
	Return vOrderText;
EndFunction
 
#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure SaveOrderStatusMessage(pOrder, pOrderType, pOrderStatus, pEmployee, pText, pTo, pMessageStatus, pMessageId, pDateSent, pDateStatus)
		vIR = InformationRegisters.OrderNotifications.CreateRecordManager();
		VIR.Order = pOrder;
		vIR.OrderType = pOrderType;
		vIR.OrderStatus = pOrderStatus;
		vIR.Employee = pEmployee;
		vIR.Text = pText;
		vIR.MessageID = pMessageId;
		vIR.MessageStatus = pMessageStatus;
		vIR.to = pTo;
		vIR.DateSent = pDateSent;
		vIR.DateStatus = pDateStatus;		
		vIR.Write();
EndProcedure

#EndRegion
