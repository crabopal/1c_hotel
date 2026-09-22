
#Region Public

// -----------------------------------------------------------------------------
Procedure pmFillAuthorAndDate() Export
	Date = CurrentSessionDate();
	Author = SessionParameters.CurrentUser;
EndProcedure // pmFillAuthorAndDate

// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// Fill author and document date
	pmFillAuthorAndDate();
	// Fill from session parameters
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(Hotel) Then
		Currency = Hotel.BaseCurrency;
	EndIf;
	// Set Order Type. If ther is no choice then just use it. Otherwise one have to select manually
	vQ = New Query("SELECT
	|	OrderTypes.Ref,
	|	OrderTypes.Department
	|FROM
	|	Catalog.OrderTypes AS OrderTypes
	|WHERE
	|	NOT OrderTypes.DeletionMark");
	qRes = vQ.Execute().Select();
	If qRes.Count() = 1 Then
		If qRes.Next() Then
			Type = qRes.Ref;
			Department = qRes.Department; 
		EndIf;
	EndIf;	
	GuestsQuantity = 1;
	OrderPaymentType = Enums.OrderPaymentType.Cash;
	RouteType        = Enums.RouteType.Arrive;	
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Procedure pmGetTransferPrice() Export
    vDateTo = Date;
	If Type.FillPricesByOrderTime Then
		vDateTo = OrderTime;
	EndIf;	
    If Not ValueIsFilled(vDateTo) Then
       vDateTo = CurrentSessionDate();
    EndIf;
	If RouteType = Enums.RouteType.Route Then
		vQueryResult = GetTransferPrices(vDateTo, ClientType, "");
		vRes = vQueryResult.Select();	
		If vRes.Next() Then
			Service = vRes.Service;
			If ValueIsFilled(Service) Then
				Unit = Service.Unit;
			Else
				Unit = "";
			EndIf;
			Price = vRes.Price;	
		Else
			Service = Undefined;
			Unit = "";
			Price = 0;	
		EndIf;	
		Sum = 0;	
	Else	
		vQueryResult = GetTransferPrices(vDateTo, ClientType, ?(RouteType = Enums.RouteType.Arrive,PickupFrom, Destination));
		vRes = vQueryResult.Select();	
		If vRes.Next() Then
			Service = vRes.Service;		
			If ValueIsFilled(Service) Then
				Unit = Service.Unit;
			Else
				Unit = "";
			EndIf;
			Price = vRes.Price;
		Else
			vQueryResult = GetTransferPrices(vDateTo, ClientType, "");
			vRes = vQueryResult.Select();	
			If vRes.Next() Then
				Service = vRes.Service;		
				If ValueIsFilled(Service) Then
					Unit = Service.Unit;
				Else
					Unit = "";
				EndIf;
				Price = vRes.Price;	
			Else
				Service = Undefined;
				Unit = "";
				Price = 0;	
			EndIf;
		EndIf;
		Sum = 0;	
	EndIf;
	// Set discounts and recalculate sum
	pmSetDiscounts();
EndProcedure

// -----------------------------------------------------------------------------
Function pmIfModificationIsAllowed() Export
	vAllowed = True;
	If AdditionalProperties.Property("SkipIfModificationIsAllowedCheck") And AdditionalProperties.SkipIfModificationIsAllowedCheck Then
		Return vAllowed;
	EndIf;
	If ValueIsFilled(Folio) And Folio.IsClosed Then
		vAllowed = False;
	ElsIf ValueIsFilled(ParentDoc) And TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") And 
	      ValueIsFilled(ParentDoc.AccommodationStatus) And 
		 (Not ParentDoc.AccommodationStatus.IsInHouse And ParentDoc.AccommodationStatus.IsActive Or 
		  Not ParentDoc.AccommodationStatus.IsActive) Then
		If Not ValueIsFilled(Status) Or 
		   ValueIsFilled(Status) And (Status.isOrderComplete Or Status.isOrderCancel) Then
			vAllowed = False;
		EndIf;
	ElsIf Hotel.DoNotEditClosedDateDocs And 
	      ValueIsFilled(Hotel.AccountingDate) And 
	      ?(ValueIsFilled(OrderTime), OrderTime, Date) < Hotel.AccountingDate And
	     (Not ValueIsFilled(Status) Or ValueIsFilled(Status) And (Status.isOrderComplete Or Status.isOrderCancel Or Status = Catalogs.OrderStatuses.Cancel)) Then
		vAllowed = False;
	EndIf;
	Return vAllowed;
EndFunction // pmIfModificationIsAllowed

// -----------------------------------------------------------------------------
Procedure pmSetDiscounts() Export
	// Check price
	If Price = 0 Then
		If Sum <> 0 And Quantity <> 0 Then
			Price = Round(Sum/Quantity, 2);
		EndIf;
	EndIf;
	If NoDiscounts Then
		DiscountType = Catalogs.DiscountTypes.EmptyRef();
		DiscountConfirmationText = "";
		DiscountServiceGroup = Catalogs.ServiceGroups.EmptyRef();
		Discount = 0;
		Return;
	EndIf;
	// Check if manual discount is choosen
	If ValueIsFilled(DiscountType) And DiscountType.IsManualDiscount And ValueIsFilled(Service) And ValueIsFilled(Hotel) Then
		vDiscount = DiscountType.GetObject().pmGetDiscount(Date, Service, Hotel);
		If vDiscount > Discount Then 
			Discount = vDiscount;
			// Update amount
			Sum = Round(Price * Quantity, 2);
			vDiscountSum = Round(Sum*Discount/100, 2);
			Sum = Sum - vDiscountSum;
		EndIf;
		Return;
	ElsIf Not ValueIsFilled(DiscountType) And Discount <> 0 Then
		// Update amount
		Sum = Round(Price * Quantity, 2);
		vDiscountSum = Round(Sum*Discount/100, 2);
		Sum = Sum - vDiscountSum;
		Return;
	EndIf;
	If ValueIsFilled(Service) And ValueIsFilled(Hotel) Then
		// Get number of persons
		vNumberOfPersons = 1;
		If ValueIsFilled(ParentDoc) And 
		   (TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Or 
			TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") Or 
			TypeOf(ParentDoc) = Type("DocumentRef.ResourceReservation")) Then
			vNumberOfPersons = ParentDoc.NumberOfPersons;
		EndIf;
		// Initialize discounts
		DiscountType = Catalogs.DiscountTypes.EmptyRef();
		DiscountConfirmationText = "";
		DiscountServiceGroup = Catalogs.ServiceGroups.EmptyRef();
		Discount = 0;
		If ValueIsFilled(DiscountCard) Then
			If ValueIsFilled(DiscountCard.DiscountType) Then
				vDiscountType = DiscountCard.DiscountType;
				If Not vDiscountType.IsAccumulatingDiscount Then
					vDiscount = vDiscountType.GetObject().pmGetDiscount(Date, Service, Hotel);
					If vDiscount > Discount Then
						If Not ValueIsFilled(vDiscountType.DiscountServiceGroup) Or ValueIsFilled(vDiscountType.DiscountServiceGroup) And cmIsServiceInServiceGroup(Service, vDiscountType.DiscountServiceGroup) Then
							DiscountType = vDiscountType;
							Discount = vDiscount;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(ClientType) Then
			If ValueIsFilled(ClientType.DiscountType) Then
				vDiscountType = ClientType.DiscountType;
				If Not vDiscountType.IsAccumulatingDiscount Then
					vDiscount = ClientType.DiscountType.GetObject().pmGetDiscount(Date, Service, Hotel);
					If vDiscount > Discount Then 
						If Not ValueIsFilled(vDiscountType.DiscountServiceGroup) Or ValueIsFilled(vDiscountType.DiscountServiceGroup) And cmIsServiceInServiceGroup(Service, vDiscountType.DiscountServiceGroup) Then
							DiscountType = ClientType.DiscountType;
							Discount = vDiscount;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(ParentDoc) Then
			If ValueIsFilled(ParentDoc.DiscountType) Then
				vDiscountType = ParentDoc.DiscountType;
				If Not vDiscountType.IsAccumulatingDiscount Then
					vDiscount = vDiscountType.GetObject().pmGetDiscount(Date, Service, Hotel);
					If vDiscount > Discount Then
						If Not ValueIsFilled(vDiscountType.DiscountServiceGroup) Or ValueIsFilled(vDiscountType.DiscountServiceGroup) And cmIsServiceInServiceGroup(Service, vDiscountType.DiscountServiceGroup) Then
							DiscountType = vDiscountType;
							Discount = vDiscount;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(Client) Then
			If ValueIsFilled(Client.DiscountType) Then
				vDiscountType = Client.DiscountType;
				If Not vDiscountType.IsAccumulatingDiscount Then
					vDiscount = vDiscountType.GetObject().pmGetDiscount(Date, Service, Hotel);
					If vDiscount > Discount Then 
						If Not ValueIsFilled(vDiscountType.DiscountServiceGroup) Or ValueIsFilled(vDiscountType.DiscountServiceGroup) And cmIsServiceInServiceGroup(Service, vDiscountType.DiscountServiceGroup) Then
							DiscountType = vDiscountType;
							Discount = vDiscount;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	// Update amount
	Sum = Round(Price * Quantity, 2);
	vDiscountSum = Round(Sum*Discount/100, 2);
	Sum = Sum - vDiscountSum;
EndProcedure // pmSetDiscounts

// -----------------------------------------------------------------------------
Function pmFillFolio() Export
	vChargingFolio = Folio;
	If OrderPaymentType = Enums.OrderPaymentType.Room Then
		If ValueIsFilled(ParentDoc) Then
			If TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Then
				vCRs = ParentDoc.ChargingRules.Unload();
				If Not ParentDoc.IgnoreGroupChargingRules Then
					cmAddGuestGroupChargingRules(vCRs, ParentDoc.GuestGroup);
				EndIf;
				For Each vCRRow In vCRs Do
					If cmIsServiceFitToTheChargingRule(vCRRow, Service, BegOfDay(OrderTime), False, False) Then
						vChargingFolio = vCRRow.ChargingFolio;
						Break;
					EndIf;
				EndDo;
			ElsIf TypeOf(ParentDoc) = Type("DocumentRef.ResourceReservation") Then
				vChargingFolio = ParentDoc.ChargingFolio;
			ElsIf TypeOf(ParentDoc) = Type("DocumentRef.Folio") Then
				vChargingFolio = ParentDoc;
			EndIf;
		EndIf;
	ElsIf OrderPaymentType = Enums.OrderPaymentType.Cash Then
		If ValueIsFilled(ParentDoc) Then
			If TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Then
				vCRs = ParentDoc.ChargingRules.Unload();
				If Not ParentDoc.IgnoreGroupChargingRules Then
					cmAddGuestGroupChargingRules(vCRs, ParentDoc.GuestGroup);
				EndIf;
				For Each vCRRow In vCRs Do
					If cmIsServiceFitToTheChargingRule(vCRRow, Service, BegOfDay(OrderTime), False, False) Then
						vChargingFolio = vCRRow.ChargingFolio;
						Break;
					EndIf;
				EndDo;
			ElsIf TypeOf(ParentDoc) = Type("DocumentRef.ResourceReservation") Then
				vChargingFolio = ParentDoc.ChargingFolio;
			ElsIf TypeOf(ParentDoc) = Type("DocumentRef.Folio") Then
				vChargingFolio = ParentDoc;
			EndIf;
		Else
			If Not ValueIsFilled(vChargingFolio) Then
				vNewChargingFolio = Documents.Folio.CreateDocument();
				vNewChargingFolio.pmFillAttributesWithDefaultValues();
				vNewChargingFolio.GuestGroup = GuestGroup;
				vNewChargingFolio.Client = Client;
				vNewChargingFolio.Write();
				vChargingFolio = vNewChargingFolio.Ref;
			EndIf;
		EndIf;
	ElsIf OrderPaymentType = Enums.OrderPaymentType.Employee Then
		If ValueIsFilled(Employee) Then
			vEmployeeObject = Employee.GetObject();
			vClient = vEmployeeObject.pmGetClient();
			vCRs = vClient.ChargingRules.Unload();
			If Not ParentDoc.IgnoreGroupChargingRules Then
				cmAddGuestGroupChargingRules(vCRs, ParentDoc.GuestGroup);
			EndIf;
			For Each vCRRow In vCRs Do
				If cmIsServiceFitToTheChargingRule(vCRRow, Service, BegOfDay(OrderTime), False, False) Then
					vChargingFolio = vCRRow.ChargingFolio;
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	Return vChargingFolio;
EndFunction // pmFillFolio

#EndRegion

#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure Filling(pBase)
	If IsNew() Then
		pmFillAttributesWithDefaultValues();
	EndIf;
	If pBase <> Undefined Then
		If TypeOf(pBase) = Type("DocumentRef.Reservation") Then
			pmFillByReservation(pBase);
			RouteType = Enums.RouteType.Arrive;
		ElsIf TypeOf(pBase) = Type("DocumentRef.Accommodation")  Then
			pmFillByReservation(pBase);
			RouteType = Enums.RouteType.Departure;			
		ElsIf TypeOf(pBase) = Type("DocumentRef.ResourceReservation") Then
			pmFillByResourceReservation(pBase);
			RouteType = Enums.RouteType.Arrive;
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
Procedure BeforeDelete(pCancel) 
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not pmIfModificationIsAllowed() Then
		pCancel = True;
		Return;
	EndIf;
	If ValueIsFilled(Charge) Then
		Try
			vChargeObj = Charge.GetObject();
			vChargeObj.SetDeletionMark(True);
		Except
			pCancel = True;
		EndTry;
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel, pWriteMode, pPostingMode)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If DeletionMark Then
		If Not pmIfModificationIsAllowed() Then
			pCancel = True;
			Return;
		EndIf;
		If ValueIsFilled(Charge) Then
			Try
				vChargeObj = Charge.GetObject();
				vChargeObj.SetDeletionMark(True);
			Except
				pCancel = True;
			EndTry;
		EndIf;	
	Else
		If IsNew() Then
			vRef = Documents.Order.GetRef(new UUID);
			SetNewObjectRef(vRef);
		Else
			If Not pmIfModificationIsAllowed() Then
				pCancel = True;
				Return;
			EndIf;
			vRef = Ref;
		EndIf;
		// Fill order items total
		ItemsSum = Items.Total("Sum");
		// Write to order status history
		vQuery = New Query;
		vQuery.Text = 
		"SELECT
		|	OrderStatusHistorySliceLast.Order AS Order,
		|	OrderStatusHistorySliceLast.Status AS Status
		|FROM
		|	InformationRegister.OrderStatusHistory AS OrderStatusHistorySliceLast
		|WHERE
		|	OrderStatusHistorySliceLast.Order = &Order
		|
		|ORDER BY
		|	OrderStatusHistorySliceLast.Date DESC";
		vQuery.SetParameter("Order", vRef);
		vQueryResult = vQuery.Execute();
		SelectionDetailRecords = vQueryResult.Select();
		If SelectionDetailRecords.Next() Then
			If SelectionDetailRecords.Status <> Status Then
				vRM = InformationRegisters.OrderStatusHistory.CreateRecordManager();
				vRM.Date = CurrentSessionDate();
				vRM.Status = Status;
				vRM.Order = vRef;
				vRM.User = SessionParameters.CurrentUser;
				vRM.Write();
			EndIf;
		Else
			vRM = InformationRegisters.OrderStatusHistory.CreateRecordManager();
			vRM.Date = CurrentSessionDate();
			vRM.Status = Status;
			vRM.Order = vRef;
			vRM.User = SessionParameters.CurrentUser;
			vRM.Write();
		EndIf;
		// Charge time
		vChargeTime = Date;
		If ValueIsFilled(OrderTime) And ValueIsFilled(Type) And Type.Type <> Enums.TypesOfOrder.RoomService Then
			vChargeTime = OrderTime;
		EndIf;
		If ValueIsFilled(Hotel.AccountingDate) Then
			If vChargeTime > EndOfDay(Hotel.AccountingDate) Then
				// Take sale date from order date and time, charge date has to be in the future
				vChargeTime = BegOfDay(vChargeTime); 
			ElsIf BegOfDay(vChargeTime) < BegOfDay(Hotel.AccountingDate) And Hotel.DoNotEditClosedDateDocs Then	
				vChargeTime = BegOfDay(Hotel.AccountingDate);
			EndIf;
		EndIf;
		// Create or update charge document for this order
		If ValueIsFilled(Status) Then
			If ValueIsFilled(Charge) And ValueIsFilled(Service) And Status.CreateCharge And Not (Status.isOrderCancel Or Status = Catalogs.OrderStatuses.Cancel) Then
				vChargeIsInClosedDay = cmIfChargeIsInClosedDay(Charge);
				If Not vChargeIsInClosedDay Then
					// Check if folio is filled
					If Not ValueIsFilled(Folio) Then
						Folio = pmFillFolio();
					EndIf;
					
					// Update charge
					vChargeObject = Charge.GetObject();
					vIsEdit = False;
					If vChargeObject.DeletionMark Or Not vChargeObject.Posted Then
						vIsEdit = True;
					EndIf;
					If vChargeObject.Folio <> Folio And Not ValueIsFilled(vChargeObject.ChargeTransfer) Then
						vChargeObject.Folio = Folio;
						vIsEdit = True;	
					EndIf;
					If vChargeObject.Room <> Room Then
						vChargeObject.Room = Room;
						If ValueIsFilled(Room) Then
							vChargeObject.RoomType = Room.RoomType;
						EndIf;
						vIsEdit = True;	
					EndIf;
					If vChargeObject.ServiceDate <> BegOfDay(OrderTime) Then
						vChargeObject.ServiceDate = BegOfDay(OrderTime);
						vIsEdit = True;	
					EndIf;
					vParentDoc = Undefined;
					If ValueIsFilled(ParentDoc) Then
						vParentDoc = ParentDoc;
					EndIf;
					If Not ValueIsFilled(vParentDoc) And ValueIsFilled(Folio) And ValueIsFilled(Folio.ParentDoc) Then
						vParentDoc = Folio.ParentDoc;
					EndIf;
					If ValueIsFilled(vParentDoc) And vParentDoc <> vChargeObject.ParentDoc Then
						vChargeObject.ParentDoc = vParentDoc;
						vIsEdit = True;	
					EndIf;
					If ValueIsFilled(vParentDoc) Then
						If TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(vParentDoc) = Type("DocumentRef.ResourceReservation") Then
							If vChargeObject.SourceOfBusiness <> vParentDoc.SourceOfBusiness Then
								vChargeObject.SourceOfBusiness = vParentDoc.SourceOfBusiness;
								vIsEdit = True;	
							EndIf;
							If vChargeObject.MarketingCode <> vParentDoc.MarketingCode Then
								vChargeObject.MarketingCode = vParentDoc.MarketingCode;
								vChargeObject.MarketingCodeConfirmationText = vParentDoc.MarketingCodeConfirmationText;
								vIsEdit = True;	
							EndIf;
							If vChargeObject.ClientType <> vParentDoc.ClientType Then
								vChargeObject.ClientType = vParentDoc.ClientType;
								vChargeObject.ClientTypeConfirmationText = vParentDoc.ClientTypeConfirmationText;
								vIsEdit = True;	
							EndIf;
						EndIf;
					EndIf;
					If Charge.Service <> Service Then
						vChargingFolio = vChargeObject.Folio;
						vChargeObject.Service = Service;
						vChargeObject.PaymentSection = Service.PaymentSection;
						vChargeObject.Unit = Service.Unit;
						vPrices = cmGetServicePrice(Service, Hotel, OrderTime, ClientType);
						If vPrices.Count() > 0 Then
							vChargeObject.VATRate = vPrices[0].VATRate;
						EndIf;
						If ValueIsFilled(vChargingFolio.Company) And vChargingFolio.Company.IsUsingSimpleTaxSystem Then
							vChargeObject.VATRate = vChargingFolio.Company.VATRate;
						EndIf;
						vIsEdit = True;	
					EndIf;
					Quantity = ?(Quantity = 0, 1, Quantity); 
					vQty = Quantity;
					If Sum < 0 And vQty > 0 Then
						vQty = - vQty;
					EndIf;
					If Charge.Quantity <> vQty Then
						vChargeObject.Quantity = vQty;
						vChargeObject.Price = ?(Price <> 0, Price, Round(Sum / vQty, 2));
						vIsEdit = True;
					EndIf;
					If Charge.Sum <> Sum Then
						vChargeObject.Price = ?(Price <> 0, Price, Round(Sum / vQty, 2));
						vChargeObject.Sum = Sum;
						vChargeObject.Quantity = vQty;
						vIsEdit = True;	
					EndIf;  
					If vChargeObject.Price < 0 And Sum < 0 Then
						vChargeObject.Price = -vChargeObject.Price;	
						If vChargeObject.Quantity > 0 Then
							vChargeObject.Quantity = - vChargeObject.Quantity;	
						EndIf;	    
						vIsEdit = True;
					EndIf;
					If vIsEdit Then
						If vChargeObject.Date <> vChargeTime Then
							vChargeObject.Date = vChargeTime;
						EndIf;
						vChargeObject.DeletionMark = False;
						If Not NoDiscounts Then
							vChargeObject.pmSetDiscounts();
						Else
							vChargeObject.Discount = 0;
							vChargeObject.DiscountCard = Undefined;
							vChargeObject.DiscountType = Undefined;
							vChargeObject.DiscountServiceGroup = Undefined;
							vChargeObject.DiscountConfirmationText = "";
							vChargeObject.DiscountSum = 0;
						EndIf;
						vChargeObject.pmRecalculateAmounts();
						vChargeObject.AdditionalProperties.Insert("OrderItems", Items.Unload());
						vChargeObject.AdditionalProperties.Insert("OrderCurrency", Currency);
						vChargeObject.AdditionalProperties.Insert("OrderRemarks", TrimAll(Remarks));
						vChargeObject.AdditionalProperties.Insert("OrderAmount", Sum);
						vChargeObject.AdditionalProperties.Insert("OrderItemsAmount", Items.Total("Sum"));
						vChargeObject.Write(DocumentWriteMode.Posting);
					EndIf;
				EndIf;
			Else
				If Not ValueIsFilled(Charge) And ValueIsFilled(Service) And ValueIsFilled(Status) And Status.CreateCharge And Not (Status.isOrderCancel Or Status = Catalogs.OrderStatuses.Cancel) Then
					vChargeStruct = New Structure("Date, Hotel", vChargeTime, Hotel);
					vChargeIsInClosedDay = cmIfChargeIsInClosedDay(vChargeStruct);
					If Not vChargeIsInClosedDay Then
						vChargingFolio = pmFillFolio();
						If ValueIsFilled(vChargingFolio) Then
							If Folio <> vChargingFolio Then 
								Folio = vChargingFolio;
							EndIf;
							If Currency <> Folio.FolioCurrency Then
								Currency = Folio.FolioCurrency;
							EndIf;
							Quantity = ?(Quantity = 0, 1, Quantity);
							vQty = Quantity;
							If Sum < 0 And vQty > 0 Then
								vQty = - vQty;
							EndIf;	
							vChargeObject = Documents.Charge.CreateDocument();
							vChargeObject.Hotel = vChargingFolio.Hotel;
							vChargeObject.Service = Service;
							vChargeObject.Fill(vChargingFolio);
							vChargeObject.SetTime(AutoTimeMode.DontUse);
							vChargeObject.Date = vChargeTime;
							vChargeObject.ServiceDate = BegOfDay(OrderTime);
							vChargeObject.ClientType = ?(ValueIsFilled(vChargeObject.ParentDoc), vChargeObject.ParentDoc.ClientType, Undefined);
							vChargeObject.PaymentSection = Service.PaymentSection;
							vChargeObject.Unit = Service.Unit;
							If ValueIsFilled(vChargingFolio.Company) Then
								vChargeObject.VATRate = vChargingFolio.Company.VATRate;
							EndIf;
							vPrices = cmGetServicePrice(Service, Hotel, OrderTime, vChargeObject.ClientType);
							If vPrices.Count() > 0 Then
								vChargeObject.VATRate = vPrices[0].VATRate;
							EndIf;
							If ValueIsFilled(vChargingFolio.Company) And vChargingFolio.Company.IsUsingSimpleTaxSystem Then
								vChargeObject.VATRate = vChargingFolio.Company.VATRate;
							EndIf;
							vChargeObject.Price = ?(Price <> 0, Price, Round(Sum / vQty, 2));  
							vChargeObject.Unit = Unit;
							vChargeObject.Quantity = vQty;
							vChargeObject.Sum = Sum;
							vChargeObject.Remarks = Remarks;
							vChargeObject.PaymentSection = vChargeObject.Service.PaymentSection;
							vChargeObject.IsRoomRevenue = vChargeObject.Service.IsRoomRevenue;
							vChargeObject.Company = vChargingFolio.Company;
							vChargeObject.Room = Room;   
							If vChargeObject.Price < 0 And Sum < 0 Then
								vChargeObject.Price = -vChargeObject.Price;	
								If vChargeObject.Quantity > 0 Then
									vChargeObject.Quantity = - vChargeObject.Quantity;	
								EndIf;	
							EndIf;
							If ValueIsFilled(Room) Then
								vChargeObject.RoomType = Room.RoomType;
							EndIf;
							vParentDoc = ParentDoc;
							If Not ValueIsFilled(vParentDoc) And ValueIsFilled(vChargingFolio) And ValueIsFilled(vChargingFolio.ParentDoc) Then
								vParentDoc = vChargingFolio.ParentDoc;
							EndIf;
							If ValueIsFilled(vParentDoc) Then
								If TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(vParentDoc) = Type("DocumentRef.ResourceReservation") Then
									vChargeObject.SourceOfBusiness = vParentDoc.SourceOfBusiness;
									vChargeObject.MarketingCode = vParentDoc.MarketingCode;
									vChargeObject.MarketingCodeConfirmationText = vParentDoc.MarketingCodeConfirmationText;
									vChargeObject.ClientType = vParentDoc.ClientType;
									vChargeObject.ClientTypeConfirmationText = vParentDoc.ClientTypeConfirmationText;
								EndIf;
							EndIf;
							vChargeObject.IsAdditional = True;
							If Not NoDiscounts Then
								vChargeObject.pmSetDiscounts();
							Else
								vChargeObject.Discount = 0;
								vChargeObject.DiscountCard = Undefined;
								vChargeObject.DiscountType = Undefined;
								vChargeObject.DiscountServiceGroup = Undefined;
								vChargeObject.DiscountConfirmationText = "";
								vChargeObject.DiscountSum = 0;
							EndIf;
							vChargeObject.pmRecalculateAmounts();
							vChargeObject.AdditionalProperties.Insert("OrderItems", Items.Unload());
							vChargeObject.AdditionalProperties.Insert("OrderCurrency", Currency);
							vChargeObject.AdditionalProperties.Insert("OrderRemarks", TrimAll(Remarks));
							vChargeObject.AdditionalProperties.Insert("OrderAmount", Sum);
							vChargeObject.AdditionalProperties.Insert("OrderItemsAmount", Items.Total("Sum"));
							vChargeObject.Write(DocumentWriteMode.Write);
							If cm0SecondShift(vChargeObject.Date) <> cm0SecondShift(vChargeTime) Then
								vChargeObject.Date = vChargeTime;
								vChargeObject.ServiceDate = BegOfDay(vChargeTime);
							EndIf;      
							vChargeObject.StatisticsOnly = Type.StatisticsOnly;
							vChargeObject.Write(DocumentWriteMode.Posting);
							
							Charge = vChargeObject.Ref;
						EndIf;
					EndIf;
				Else
					If ValueIsFilled(Charge) And Charge.Posted And (Not Status.CreateCharge Or Status.isOrderCancel Or Status = Catalogs.OrderStatuses.Cancel) Then
						vChargeIsInClosedDay = cmIfChargeIsInClosedDay(Charge);
						If Not vChargeIsInClosedDay Then
							If Charge.Posted Then
								vChargeObject = Charge.GetObject();
								vChargeObject.SetDeletionMark(True);
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
Procedure OnCopy(pCopiedObject)
	// Fill author and document date
	pmFillAuthorAndDate();
	// Clear some attributes
	Charge = Undefined;
EndProcedure // OnCopy

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)  
	If DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // OnWrite

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure pmFillByReservation(pBase)
	If pBase = Undefined Or Not ValueIsFilled(pBase) Then
		Return;
	EndIf;
	ParentDoc = pBase;
	Client = ParentDoc.Guest;
	ClientType = ParentDoc.ClientType;
	Phone = ParentDoc.Phone;
	Room = ParentDoc.Room;
	If IsBlankString(Phone) And ValueIsFilled(Client) Then
		Phone = Client.Phone;
	EndIf;
	GuestGroup = ParentDoc.GuestGroup;
	OrderPaymentType = Enums.OrderPaymentType.Room; 
	Hotel = pBase.Hotel;
EndProcedure

// -----------------------------------------------------------------------------
Procedure pmFillByResourceReservation(pBase)
	If pBase = Undefined Or Not ValueIsFilled(pBase) Then
		Return;
	EndIf;
	ParentDoc = pBase;
	Client = ParentDoc.Client;
	ClientType = ParentDoc.ClientType;
	Phone = ParentDoc.Phone;
	If IsBlankString(Phone) And ValueIsFilled(Client) Then
		Phone = Client.Phone;
	EndIf;
	GuestGroup = ParentDoc.GuestGroup;
	OrderPaymentType = Enums.OrderPaymentType.Room; 
	Hotel = pBase.Hotel;
EndProcedure

// -----------------------------------------------------------------------------
Function GetTransferPrices(pDate, pClientType, pDestination, pSecondQuery = False)
	vHotels = New Array;
	vHotels.Add(Hotel);
	vHotels.Add(Catalogs.Hotels.EmptyRef());
	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	TransferPricesSliceLast.Price AS Price,
	|	TransferPricesSliceLast.Service AS Service
	|FROM
	|	InformationRegister.TransferPrices.SliceLast(
	|			&qDate,
	|			TransferType = &qTransferType
	|				AND Destination = &qDestination
	|				AND Hotel IN (&qHotel)
	|				AND ClientType = &qClientType) AS TransferPricesSliceLast";
	vQuery.SetParameter("qTransferType", TransferType);
	vQuery.SetParameter("qDestination", pDestination);
	vQuery.SetParameter("qHotel",vHotels);
	vQuery.SetParameter("qDate", pDate);
	vQuery.SetParameter("qClientType", pClientType);
	vQueryResult = vQuery.Execute();
	
	// Try find by empty client type
	If pSecondQuery = False Then
		If ValueIsFilled(pClientType) And vQueryResult.IsEmpty() Then
			vQueryResult = GetTransferPrices(pDate, Catalogs.ClientTypes.EmptyRef(), pDestination, True)
		EndIf;
	EndIf;
	Return vQueryResult;

EndFunction

#EndRegion
